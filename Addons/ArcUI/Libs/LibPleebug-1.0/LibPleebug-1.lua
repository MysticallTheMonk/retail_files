-- === BLOCK: File Header Starts ===
-- File: LibPleebug-1.lua
-- Purpose: Dev-only tracking of events and function call frequency.
-- === BLOCK: File Header Ends ===


-- === BLOCK: MemDebug - Setup Starts ===
local MAJOR, MINOR = "LibPleebug-1", 1
local LibStub = _G.LibStub
if not LibStub then return end

local MemDebug, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not MemDebug then return end

-- SavedVariables root (flat DB, library-owned)
_G.LibPleebugDB = _G.LibPleebugDB or {}


MemDebug._enabled = false
MemDebug._ticker = nil
MemDebug._counts = MemDebug._counts or {}
MemDebug._lastSnapshot = MemDebug._lastSnapshot or {}

-- Used by AceEvent method wrapping
MemDebug._wrapped = MemDebug._wrapped or setmetatable({}, { __mode = "k" })
MemDebug._origNewModule = MemDebug._origNewModule or nil

-- Used by "wrap all functions" per module (tables only)
MemDebug._autoWrappedTables = MemDebug._autoWrappedTables or setmetatable({}, { __mode = "k" })

local function _now()
  if GetTimePreciseSec then
    return GetTimePreciseSec()
  end
  return (GetTime and GetTime()) or 0
end

local function _wipe(t)
  if not t then return end
  for k in pairs(t) do
    t[k] = nil
  end
end

local function _getModuleName(obj)
  if not obj then return "Unknown" end
  local n = (obj.GetName and obj:GetName()) or obj.moduleName or obj.name or "Unknown"
  if n == ADDON_NAME then
    return "Core"
  end
  return tostring(n)
end

-- Tick hooks (optional modules can register; called from SnapshotAndReset)
function MemDebug:RegisterTickHook(id, fn)
  if not id or id == "" then return end
  if type(fn) ~= "function" then return end
  self._tickHooks = self._tickHooks or {}
  self._tickHooks[id] = fn
end

function MemDebug:UnregisterTickHook(id)
  if not self._tickHooks then return end
  self._tickHooks[id] = nil
end


local function _ensureDB()
  local mdb = _G.LibPleebugDB
  if type(mdb) ~= "table" then return nil end


  -- Tracking must never persist across reloads. Only runtime Start() enables tracking.
  mdb.enabled = false
  if type(mdb.interval) ~= "number" then mdb.interval = 10 end
  if mdb.interval < 5 then mdb.interval = 5 end
  if mdb.interval > 60 then mdb.interval = 60 end


  -- Window-only UI readability (dev)
  if type(mdb.fontSize) ~= "number" then mdb.fontSize = 14 end
  if mdb.fontSize < 10 then mdb.fontSize = 10 end
  if mdb.fontSize > 22 then mdb.fontSize = 22 end

  if type(mdb.printToChat) ~= "boolean" then mdb.printToChat = false end
  if type(mdb.trackEvents) ~= "boolean" then mdb.trackEvents = true end
  if type(mdb.trackFuncs) ~= "boolean" then mdb.trackFuncs = true end

  -- Timeline trace (used by LibPleebug-1_Diagram.lua)

  if type(mdb.traceEnabled) ~= "boolean" then mdb.traceEnabled = true end
  if type(mdb.traceStyle) ~= "string" then mdb.traceStyle = "tick" end
  if mdb.traceStyle ~= "tick" and mdb.traceStyle ~= "dot" then
    mdb.traceStyle = "tick"
  end

  -- Timeline window is always synced to Interval
  mdb.traceWindow = mdb.interval



  if type(mdb.traceMax) ~= "number" then mdb.traceMax = 40000 end
  if mdb.traceMax < 2000 then mdb.traceMax = 2000 end
  if mdb.traceMax > 200000 then mdb.traceMax = 200000 end


  -- Known modules (auto-registered by Attach so UI can populate checkboxes)
  mdb.knownModules = mdb.knownModules or {}

  -- Friendly names (custom display names) shown in UI: real module name -> friendly
  mdb.friendly = mdb.friendly or {}

  -- Friendly aliases (aliases) shown in UI: alias -> real module name
  mdb.moduleAliases = mdb.moduleAliases or {}


  -- Module allow-list for ALL tracking (events + funcs)
  mdb.modules = mdb.modules or {}

  -- Module toggle for "wrap all functions"
  mdb.autoWrap = mdb.autoWrap or {}

  -- Optional: bucket metadata per module (registered by DropIn)
  -- moduleName -> { "Bucket1", "Bucket2", ... }
    mdb.buckets = mdb.buckets or {}
  mdb.bucketLists = mdb.bucketLists or {}
  mdb.series = mdb.series or {}





  -- Flush pending known modules (Attach/Ping can run before DB exists)
  if MemDebug._pendingKnownModules then

    for name, v in pairs(MemDebug._pendingKnownModules) do
      if v == true and type(name) == "string" and name ~= "" then
        mdb.knownModules[name] = true
        if mdb.modules[name] == nil then
          mdb.modules[name] = true
        end
      end
    end
    MemDebug._pendingKnownModules = nil
  end

  -- Per-series style settings for timeline (shared with CPU timeline)
  -- mdb.series[key] = { enabled = bool, r = number, g = number, b = number }
  if type(mdb.series) ~= "table" then mdb.series = {} end


  return mdb
end


function MemDebug:GetDB()
  return _ensureDB()
end

-- ---------------------------------------------------------------------------
-- Series style storage (timeline lane colors + enabled/hidden)
-- Stored ONLY when customized:
--   LibPleebugDB.series[key] = { enabled=true/false, r=, g=, b= }
-- Defaults are deterministic and computed on demand (not persisted).
-- ---------------------------------------------------------------------------

-- Compatibility: some clients have ColorUtil but not ColorUtil.HSVToColorRGB.
-- Older code paths may call ColorUtil.HSVToColorRGB and crash if it's missing.
do
  local function _HSVToRGB_Compat(h, s, v)
    h = tonumber(h) or 0
    s = tonumber(s) or 0
    v = tonumber(v) or 0

    if s <= 0 then
      return v, v, v
    end

    h = h % 1
    local i = math.floor(h * 6)
    local f = (h * 6) - i
    local p = v * (1 - s)
    local q = v * (1 - s * f)
    local t2 = v * (1 - s * (1 - f))

    i = i % 6
    if i == 0 then return v, t2, p end
    if i == 1 then return q, v, p end
    if i == 2 then return p, v, t2 end
    if i == 3 then return p, q, v end
    if i == 4 then return t2, p, v end
    return v, p, q
  end

  if type(_G.ColorUtil) == "table" and type(_G.ColorUtil.HSVToColorRGB) ~= "function" then
    _G.ColorUtil.HSVToColorRGB = _HSVToRGB_Compat
  end
end

local function _HSVToRGB(h, s, v)
  h = tonumber(h) or 0
  s = tonumber(s) or 0
  v = tonumber(v) or 0

  if s <= 0 then
    return v, v, v
  end

  h = h % 1
  local i = math.floor(h * 6)
  local f = (h * 6) - i
  local p = v * (1 - s)
  local q = v * (1 - s * f)
  local t = v * (1 - s * (1 - f))

  i = i % 6
  if i == 0 then return v, t, p end
  if i == 1 then return q, v, p end
  if i == 2 then return p, v, t end
  if i == 3 then return p, q, v end
  if i == 4 then return t, p, v end
  return v, p, q
end

local function _SeriesDefaultColor(key)
  -- Deterministic color from key (stable across sessions)
  key = tostring(key or "")
  if key == "" then return 0.20, 0.60, 1.00 end

  local h = 0
  for i = 1, #key do
    h = (h * 33 + key:byte(i)) % 360
  end

  local hue = (h / 360)
  local sat = 0.65
  local val = 0.95

  local r, g, b
  if type(_G.HSVToColorRGB) == "function" then
    r, g, b = _G.HSVToColorRGB(hue, sat, val)
  else
    r, g, b = _HSVToRGB(hue, sat, val)
  end

  return r or 1, g or 1, b or 1
end

local function _NormalizeRGB(r, g, b)
  r = tonumber(r) or 1
  g = tonumber(g) or 1
  b = tonumber(b) or 1

  if r < 0 then r = 0 elseif r > 1 then r = 1 end
  if g < 0 then g = 0 elseif g > 1 then g = 1 end
  if b < 0 then b = 0 elseif b > 1 then b = 1 end

  return r, g, b
end

local function _GetSeriesEntry(db, key)
  if not db or type(db.series) ~= "table" then return nil end
  local s = db.series[key]
  return (type(s) == "table") and s or nil
end

local function _EnsureSeriesEntry(db, key)
  if not db then return nil end
  db.series = db.series or {}
  local s = db.series[key]
  if type(s) ~= "table" then
    s = {}
    db.series[key] = s
  end
  return s
end

function MemDebug:GetSeriesStyle(key)
  if type(key) ~= "string" or key == "" then return nil end
  local db = _ensureDB()
  if not db then return nil end

  local s = _GetSeriesEntry(db, key)
  if s then
    -- Ensure fields are valid (but do not fill defaults into DB beyond what exists).
    if s.enabled == nil then s.enabled = true end
    if type(s.r) ~= "number" or type(s.g) ~= "number" or type(s.b) ~= "number" then
      local r, g, b = _SeriesDefaultColor(key)
      s.r, s.g, s.b = r, g, b
    end
    return s
  end

  -- Not customized: return ephemeral style (not saved)
  local r, g, b = _SeriesDefaultColor(key)
  return { enabled = true, r = r, g = g, b = b }
end

function MemDebug:SetSeriesEnabled(key, enabled)
  if type(key) ~= "string" or key == "" then return end
  local db = _ensureDB()
  if not db then return end

  enabled = (enabled == true)

  -- Only create/persist entry when user actually customizes something.
  local s = _GetSeriesEntry(db, key)
  if not s then
    if enabled == true then
      -- Default is enabled=true, so no need to store anything.
      return
    end
    s = _EnsureSeriesEntry(db, key)
  end

  s.enabled = enabled
end

function MemDebug:SetSeriesColor(key, r, g, b)
  if type(key) ~= "string" or key == "" then return end
  local db = _ensureDB()
  if not db then return end

  r, g, b = _NormalizeRGB(r, g, b)

  -- Persist only when customized.
  local s = _EnsureSeriesEntry(db, key)
  s.r, s.g, s.b = r, g, b

  if s.enabled == nil then
    s.enabled = true
  end
end




function MemDebug:GetAllSeriesKeys(out)
  local db = _ensureDB()
  if not db or type(db.series) ~= "table" then return out or {} end

  if type(out) ~= "table" then out = {} end
  _wipe(out)

  -- Only customized keys are stored in db.series
  for k, v in pairs(db.series) do
    if type(k) == "string" and k ~= "" and type(v) == "table" then
      out[#out + 1] = k
    end
  end

  table.sort(out)
  return out
end

function MemDebug:ResetSeriesKey(key)
  if type(key) ~= "string" or key == "" then return end
  local db = _ensureDB()
  if not db or type(db.series) ~= "table" then return end
  db.series[key] = nil
end

function MemDebug:ResetAllSeriesStyles()
  local db = _ensureDB()
  if not db or type(db.series) ~= "table" then return end
  _wipe(db.series)
end

-- Internal: ensure a series key exists in DB when we actually observe it (trace enabled).
-- This lets the UI show active lanes without requiring manual customization first.
function MemDebug:_TouchSeries(key)
  if type(key) ~= "string" or key == "" then return end

  local db = _ensureDB()
  if not db then return end

  db.series = db.series or {}

  local s = db.series[key]
  if type(s) ~= "table" then
    local r, g, b = _SeriesDefaultColor(key)
    db.series[key] = { enabled = true, r = r, g = g, b = b }
    return
  end

  if s.enabled == nil then s.enabled = true end
  if type(s.r) ~= "number" or type(s.g) ~= "number" or type(s.b) ~= "number" then
    local r, g, b = _SeriesDefaultColor(key)
    s.r, s.g, s.b = r, g, b
  end
end

local function _moduleAllowed(mdb, moduleName)

  if not mdb or not mdb.modules then return true end
  local v = mdb.modules[moduleName]
  if v == nil then
    mdb.modules[moduleName] = true
    return true
  end
  return v ~= false
end

local function _autoWrapAllowed(mdb, moduleName)
  if not mdb or not mdb.autoWrap then return false end
  local v = mdb.autoWrap[moduleName]
  if v == nil then
    mdb.autoWrap[moduleName] = false
    return false
  end
  return v == true
end

local function _inc(key, amount)
  if not key then return end
  amount = amount or 1
  local c = MemDebug._counts
  c[key] = (c[key] or 0) + amount
end

-- Timeline trace ring buffer (rolling window of call timestamps).
function MemDebug:_TracePush(key)
  local mdb = _ensureDB()

  -- Hard gate: never record or persist anything unless Start() is running.
  if not self:IsEnabled() then
    return
  end

  if not mdb or not mdb.traceEnabled then
    return
  end

  -- Only create/persist a series entry when tracing is actually enabled.
  self:_TouchSeries(key)


  local t = _now()
  if not t or t <= 0 then
    return
  end

  self._trace = self._trace or {}
  self._traceStart = self._traceStart or 1
  self._traceEnd = self._traceEnd or 0

  self._traceEnd = self._traceEnd + 1
  self._trace[self._traceEnd] = { t = t, key = key }

  -- Drop entries older than the rolling window (with a small buffer).
  local keep = (mdb.traceWindow or 10) + 2
  local tr = self._trace
  local start = self._traceStart

  while start <= self._traceEnd do
    local e = tr[start]
    if not e or not e.t or (t - e.t) > keep then
      start = start + 1
    else
      break
    end
  end
  self._traceStart = start

  -- Hard cap to avoid unbounded growth during heavy debugging sessions.
  local maxN = mdb.traceMax or 40000
  local n = self._traceEnd - self._traceStart + 1
  if n > maxN then
    self._traceStart = self._traceEnd - maxN + 1
  end

  -- Compact occasionally so the table does not grow forever.
  if self._traceStart > 2000 and (self._traceStart > (self._traceEnd * 0.5)) then
    local new = {}
    local j = 0
    for i = self._traceStart, self._traceEnd do
      j = j + 1
      new[j] = tr[i]
    end
    self._trace = new
    self._traceStart = 1
    self._traceEnd = j
  end
end

function MemDebug:GetTraceWindow()
  return self:GetInterval()
end


function MemDebug:SetTraceWindow(sec)
  -- TraceWindow is synced to Interval
  self:SetInterval(sec)
end


-- Returns (events, now) where events is an array of { t = number, key = string }.
function MemDebug:GetRecentTrace(windowSec, nowOverride, prefix)


  local mdb = _ensureDB()
  windowSec = tonumber(windowSec) or (mdb and mdb.traceWindow) or 10
  if windowSec < 0.1 then windowSec = 0.1 end

  local now = tonumber(nowOverride) or _now()

  local cutoff = now - windowSec

  local out = prefix
  if type(out) ~= "table" then
    out = self._tmpRecentTraceOut
    if not out then
      out = {}
      self._tmpRecentTraceOut = out
    else
      _wipe(out)
    end
  else
    _wipe(out)
  end

  local tr = self._trace
  if not tr then
    return out, now
  end


  local start = self._traceStart or 1
  local finish = self._traceEnd or 0

  for i = start, finish do
    local e = tr[i]
    if e and e.t and e.key and e.t >= cutoff then
      out[#out + 1] = e
    end
  end

  return out, now
end

-- === BLOCK: MemDebug - Setup Ends ===

-- === BLOCK: MemDebug - Public API Starts ===
function MemDebug:IsEnabled()
  return self._enabled == true
end

function MemDebug:SetEnabled(state)
  state = not not state
  self._enabled = state

  if state then
    self:Start()
  else
    self:Stop()
  end
end


function MemDebug:GetInterval()
  local mdb = _ensureDB()
  return (mdb and mdb.interval) or 2
end

function MemDebug:SetInterval(seconds)
  local mdb = _ensureDB()
  seconds = tonumber(seconds) or 10
  seconds = math.floor(seconds + 0.5)
  if seconds < 5 then seconds = 5 end
  if seconds > 60 then seconds = 60 end
  if mdb then
    mdb.interval = seconds
    mdb.traceWindow = seconds -- keep timeline synced
  end


  if self._ticker then
    self:Start()
  end
end

function MemDebug:GetFontSize()
  local mdb = _ensureDB()
  return (mdb and mdb.fontSize) or 14
end

function MemDebug:SetFontSize(size)
  local mdb = _ensureDB()
  size = tonumber(size) or 14
  size = math.floor(size + 0.5)
  if size < 10 then size = 10 end
  if size > 22 then size = 22 end
  if mdb then
    mdb.fontSize = size
  end
end

-- Timeline style (ticks vs dots)
function MemDebug:GetTraceStyle()
  local mdb = _ensureDB()
  return (mdb and mdb.traceStyle) or "tick"
end

function MemDebug:SetTraceStyle(style)
  local mdb = _ensureDB()
  if not mdb then return end
  style = tostring(style or "tick")
  if style ~= "tick" and style ~= "dot" then
    style = "tick"
  end
  mdb.traceStyle = style
end


-- Internal: ensure module exists in DB lists so UI can populate.
function MemDebug:_RegisterKnownModule(moduleName)
  moduleName = tostring(moduleName or "Unknown")
  if moduleName == "" then moduleName = "Unknown" end

  local mdb = _ensureDB()
  if not mdb then
    -- UI can open before DB exists. Buffer modules so the list can populate.
    self._pendingKnownModules = self._pendingKnownModules or {}
    self._pendingKnownModules[moduleName] = true
    return
  end


  mdb.knownModules = mdb.knownModules or {}
  mdb.modules = mdb.modules or {}

  if mdb.knownModules[moduleName] ~= true then
    mdb.knownModules[moduleName] = true
  end

  -- Default: enabled unless explicitly disabled.
  if mdb.modules[moduleName] == nil then
    mdb.modules[moduleName] = true
  end
end


function MemDebug:GetModuleDisplayName(moduleName)
  moduleName = tostring(moduleName or "Unknown")
  local mdb = _ensureDB()
  if not mdb or not mdb.friendly then
    return moduleName
  end
  local v = mdb.friendly[moduleName]
  if type(v) == "string" and v ~= "" then
    return v
  end
  return moduleName
end

function MemDebug:SetModuleFriendlyName(moduleName, friendly)
  moduleName = tostring(moduleName or "Unknown")
  if moduleName == "" then moduleName = "Unknown" end

  -- Ensure module exists in lists so UI can show it
  self:_RegisterKnownModule(moduleName)

  local mdb = _ensureDB()
  if not mdb then return end
  mdb.friendly = mdb.friendly or {}

  if friendly == nil or friendly == "" then
    mdb.friendly[moduleName] = nil
  else
    mdb.friendly[moduleName] = tostring(friendly)
  end
end

function MemDebug:GetKnownModules()
  local mdb = _ensureDB()
  local out = {}

  if not mdb then
    local pending = self._pendingKnownModules
    if pending then
      for name, v in pairs(pending) do
        if v == true and type(name) == "string" and name ~= "" then
          out[#out + 1] = name
        end
      end
      table.sort(out, function(a, b) return a < b end)
    end
    return out
  end

  local km = mdb.knownModules or {}
  for name, v in pairs(km) do
    if v == true and type(name) == "string" and name ~= "" then
      out[#out + 1] = name
    end
  end

  table.sort(out, function(a, b) return a < b end)
  return out
end

function MemDebug:IsModuleEnabled(moduleName)
  local mdb = _ensureDB()
  if not mdb then return true end

  moduleName = tostring(moduleName or "Unknown")
  local v = mdb.modules and mdb.modules[moduleName]
  if v == nil then
    -- If we see an unknown module at runtime, register it and default-enable.
    self:_RegisterKnownModule(moduleName)
    return true
  end
  return v ~= false
end

function MemDebug:EnableAllModules()
  local mdb = _ensureDB()
  if not mdb then return end
  mdb.modules = mdb.modules or {}
  mdb.knownModules = mdb.knownModules or {}

  for name, v in pairs(mdb.knownModules) do
    if v == true then
      mdb.modules[name] = true
    end
  end
end

function MemDebug:DisableAllModules()
  local mdb = _ensureDB()
  if not mdb then return end
  mdb.modules = mdb.modules or {}
  mdb.knownModules = mdb.knownModules or {}

  for name, v in pairs(mdb.knownModules) do
    if v == true then
      mdb.modules[name] = false
    end
  end
end

function MemDebug:GetModuleAlias(moduleName)
  local mdb = _ensureDB()
  if not mdb or not mdb.moduleAliases then return nil end
  moduleName = tostring(moduleName or "Unknown")
  local a = mdb.moduleAliases[moduleName]
  if type(a) ~= "string" or a == "" then
    return nil
  end
  return a
end

function MemDebug:SetModuleAlias(moduleName, alias)
  local mdb = _ensureDB()
  if not mdb then return end
  moduleName = tostring(moduleName or "Unknown")

  self:_RegisterKnownModule(moduleName)

  mdb.moduleAliases = mdb.moduleAliases or {}

  if alias == nil then
    mdb.moduleAliases[moduleName] = nil
    return
  end

  alias = tostring(alias or "")
  alias = alias:gsub("^%s+", ""):gsub("%s+$", "")
  if alias == "" then
    mdb.moduleAliases[moduleName] = nil
  else
    mdb.moduleAliases[moduleName] = alias
  end
end

function MemDebug:GetModuleDisplayName(moduleName)
  moduleName = tostring(moduleName or "Unknown")
  local a = self:GetModuleAlias(moduleName)
  if a and a ~= "" and a ~= moduleName then
    return a .. " (" .. moduleName .. ")"
  end
  return moduleName
end

-- Populate known module list WITHOUT installing any wrappers.
-- Safe to call at UI open so the module checkbox list isn't empty.
function MemDebug:PingModules()
  -- Core
  if Addon then
    self:_RegisterKnownModule(_getModuleName(Addon))
  end

  -- Existing AceAddon modules (if any)
  if Addon and type(Addon.IterateModules) == "function" then
    for _, mod in Addon:IterateModules() do
      self:_RegisterKnownModule(_getModuleName(mod))
    end
  end

  -- Any explicit Attach entries
  if self._attached then
    for moduleName in pairs(self._attached) do
      self:_RegisterKnownModule(moduleName)
    end
  end
end

function MemDebug:SetModuleEnabled(moduleName, enabled)

  local mdb = _ensureDB()
  if not mdb then return end
  moduleName = tostring(moduleName or "Unknown")

  -- Register so it appears in UI.
  self:_RegisterKnownModule(moduleName)

  mdb.modules[moduleName] = not not enabled
end


-- Toggle for "wrap all functions" on a module
function MemDebug:SetModuleAutoWrapEnabled(moduleName, enabled)
  local mdb = _ensureDB()
  if not mdb then return end
  moduleName = tostring(moduleName or "Unknown")
  mdb.autoWrap = mdb.autoWrap or {}
  mdb.autoWrap[moduleName] = not not enabled
end

function MemDebug:IsModuleAutoWrapEnabled(moduleName)
  local mdb = _ensureDB()
  if not mdb then return false end
  moduleName = tostring(moduleName or "Unknown")
  return _autoWrapAllowed(mdb, moduleName)
end

function MemDebug:TrackKey(key, amount)
  if not self:IsEnabled() then return end
  _inc(key, amount or 1)
end

function MemDebug:TrackEvent(moduleName, eventName)
  if not self:IsEnabled() then
    return
  end

  local mdb = _ensureDB()
  if not mdb or not mdb.trackEvents then
    return
  end

  local m = tostring(moduleName or "Unknown")
  self:_RegisterKnownModule(m)
  if not self:IsModuleEnabled(m) then
    return
  end


  local e = tostring(eventName or "UNKNOWN_EVENT")

  _inc("Events.Total", 1)
  _inc(("Events.%s.%s"):format(m, e), 1)

  -- Timeline trace (leaf key)
  self:_TracePush(("Events.%s.%s"):format(m, e))
end


function MemDebug:TrackFunc(moduleName, bucketName, funcName)
  if not self:IsEnabled() then
    return
  end

  local mdb = _ensureDB()
  if not mdb or not mdb.trackFuncs then
    return
  end

  local m = tostring(moduleName or "Unknown")
  self:_RegisterKnownModule(m)
  if not self:IsModuleEnabled(m) then
    return
  end


  local f = tostring(funcName or "UnknownFunc")


  local key
  if bucketName and bucketName ~= "" then
    key = ("Funcs.%s.%s.%s"):format(m, tostring(bucketName), f)
  else
    key = ("Funcs.%s.%s"):format(m, f)
  end

  _inc("Funcs.Total", 1)
  _inc(key, 1)

  -- Timeline trace (leaf key)
  self:_TracePush(key)
end


-- Convenience: returns a tiny tracker function you can keep local in a module file
-- Usage: local Track = MemDebug:MakeTracker("UnitFrames", "player"); Track("UnitHealth")
function MemDebug:MakeTracker(moduleName, defaultBucket)
  moduleName = tostring(moduleName or "Unknown")
  defaultBucket = defaultBucket and tostring(defaultBucket) or nil
  return function(funcName, bucketOverride)
    local b = bucketOverride ~= nil and tostring(bucketOverride) or defaultBucket
    MemDebug:TrackFunc(moduleName, b, funcName)
  end
end

-- ---------------------------------------------------------------------------
-- Private local function helper (least invasive)
--
-- Goal:
--   Make "local function Foo()" trackable WITHOUT turning it into a global,
--   and WITHOUT rewriting it into "function T:Foo()".
--
-- How to use in a module file:
--
--   local MemDebug = ns and ns.MemDebug
--   local Private
--   if MemDebug and MemDebug.NewPrivate then
--     -- ModuleName is your first-tier group (what shows in the module list)
--     Private = MemDebug:NewPrivate("PCM") -- or "UnitFrames", etc
--   else
--     Private = {}
--   end
--
--   local function Foo(a, b)
--     ...
--   end
--   Private:Def("Foo", Foo) -- 1 line: registers it for wrap/track
--
-- IMPORTANT:
--   To actually wrap/track these, include Private in Attach:
--     MemDebug:Attach(Cooldowns, Private, { deep = true })
--   or named:
--     MemDebug:Attach("PCM", Cooldowns, Private, { deep = true })
-- ---------------------------------------------------------------------------

function MemDebug:NewPrivate(moduleName, opt)
  opt = opt or {}
  moduleName = tostring(moduleName or "Unknown")

  local t = {}
  t.____pleebugPrivate = true
  t.__pleebugModuleName = moduleName

  -- Optional default bucket prefix for locals you Def() (you can ignore this)
  if opt.bucket ~= nil then
    t.__pleebugBucket = tostring(opt.bucket)
  end

  -- Optional per-call bucket resolver (shared with Attach/DropIn semantics)
  if type(opt.bucketFunc) == "function" then
    t.__pleebugBucketFunc = opt.bucketFunc
  end


  -- Register so it appears in UI even before Start
  if self._RegisterKnownModule then
    self:_RegisterKnownModule(moduleName)
  end

  function t:Def(name, fn, bucketOverride)
    if type(name) ~= "string" or name == "" or type(fn) ~= "function" then
      return fn
    end

    -- Optional: allow a per-function default bucket
    if bucketOverride ~= nil then
      self.__pleebugFnBuckets = self.__pleebugFnBuckets or {}
      self.__pleebugFnBuckets[name] = tostring(bucketOverride)
    end

    local module = self.__pleebugModuleName or "Unknown"
    local baseBucket = self.__pleebugBucket
    local fnBuckets = rawget(self, "__pleebugFnBuckets")
    local localBucket = (fnBuckets and fnBuckets[name]) or nil

    local wrapped = function(...)
      -- Track only when debugger is running and funcs are enabled (TrackFunc enforces that)
      -- IMPORTANT:
      --   Funcs are NEVER auto-bucketed. Bucketing is opt-in only via:
      --     - P:Def(..., bucketOverride)
      --     - DropIn(..., { bucket = "..." })
      -- This preserves per-function names in the diagram by default.
      local bucket = localBucket or baseBucket

      -- Remember the (explicit) bucket for this function name so TrackThis(child, parent) can inherit it.
      MemDebug._pdefBuckets = MemDebug._pdefBuckets or {}
      MemDebug._pdefBuckets[module] = MemDebug._pdefBuckets[module] or {}
      MemDebug._pdefBuckets[module][name] = bucket or ""

      MemDebug:TrackFunc(module, bucket, name)


      -- Hard gate: if debugger is off, do not touch CPU measuring at all.
      if not (MemDebug and MemDebug.IsEnabled and MemDebug:IsEnabled()) then
        return fn(...)
      end

      -- Optional CPU per-function measure (enabled via UI checkbox in Window)
      local cpu = MemDebug.CPU
      if cpu and cpu.ShouldMeasure and cpu.CallMeasured and cpu:ShouldMeasure(module, bucket, name) then
        return cpu:CallMeasured(module, bucket, name, fn, ...)
      end

      return fn(...)

    end



    -- Store WRAPPED on the table so WrapAllFunctions can see it (and so Attach(Private) works)
    rawset(self, name, wrapped)

    return wrapped
  end


  return t
end

-- ---------------------------------------------------------------------------
-- DropIn: universal per-file wrapper that wires Attach + P + TrackThis together.
--
-- Usage (minimal):
--   local MemDebug = ns and ns.MemDebug
--   local P, TrackThis
--   if MemDebug and MemDebug.DropIn then
--     P, TrackThis = MemDebug:DropIn(MyModuleTableOrFrame)
--   end
--
-- Usage (named + deep scan):
--   P, TrackThis = MemDebug:DropIn(Cooldowns, { name = "PCM", deep = true })
--
-- Parent bucketing:
--   Parent = P:Def("Parent", Parent, "Cooldowns.Utility")  -- bucket path
--   TrackThis("Inner1", "Parent")                          -- inherits Parent bucket
--
-- Unassigned:
--   TrackThis("InnerX") -> bucket "Unassigned"
-- ---------------------------------------------------------------------------
function MemDebug:DropIn(primary, opt, ...)
  opt = opt or {}

  -- Best-effort module name if caller didn't provide one
  local moduleName = tostring(opt.name or _getModuleName(primary) or "Unknown")

-- Infer addon folder name once per module (Interface/AddOns/<AddonName>/)
local inferredAddon
do
  local stack = debugstack and debugstack(2, 1, 0)
  if stack then
    inferredAddon = stack:match("Interface/AddOns/([^/]+)/")
  end
end

local mdb = _ensureDB()
mdb.moduleAddon = mdb.moduleAddon or {}
mdb.moduleAddon[moduleName] =
  opt.addonName
  or opt.addon
  or inferredAddon
  or mdb.moduleAddon[moduleName]


  -- Optional: register bucket list metadata for this module (UI convenience only)
  if type(opt.buckets) == "table" then
    local mdb = _ensureDB()
    if mdb then
      mdb.bucketLists = mdb.bucketLists or {}
      local out = {}
      for i = 1, #opt.buckets do
        local b = opt.buckets[i]
        if type(b) == "string" then
          b = b:gsub("^%s+", ""):gsub("%s+$", "")
          if b ~= "" then
            out[#out + 1] = b
          end
        end
      end
      if #out > 0 then
        mdb.bucketLists[moduleName] = out
      else
        mdb.bucketLists[moduleName] = nil
      end
    end
  end

  -- Create Private helper (P) that tracks locals via P:Def(...)
  -- Pass bucketFunc through so P:Def can resolve per-call buckets the same way Attach() does.
  local P = self:NewPrivate(moduleName, { bucket = opt.bucket, bucketFunc = opt.bucketFunc })



  -- Attach primary + P (and any extras) so Start() can install wrappers later
  if self._AttachInternal then
    local extra = { ... }
    if #extra > 0 then
      self:_AttachInternal(moduleName, primary, P, unpack(extra), opt)
    else
      self:_AttachInternal(moduleName, primary, P, opt)
    end
  end


  -- TrackThis: inner hotspot helper
  -- TrackThis(name) -> Module.Unassigned.name
  -- TrackThis(name, parent) -> Module.(ParentBucketPath.Parent).name
  local function TrackThis(name, parent)
    if type(name) ~= "string" or name == "" then
      return
    end

    local bucket

    if type(parent) == "string" and parent ~= "" then
      -- Try to inherit parent's bucket path from P:Def records
      local pb = self._pdefBuckets and self._pdefBuckets[moduleName] and self._pdefBuckets[moduleName][parent]
      if type(pb) == "string" and pb ~= "" then
        bucket = pb .. "." .. parent
      else
        -- No known bucket for parent: use parent as grouping
        bucket = parent
      end
    else
      bucket = "Unassigned"
    end

    self:TrackFunc(moduleName, bucket, name)
  end

  return P, TrackThis
end


-- Universal module/file wrapper:
-- Drop this into ANY file once.
--
-- Minimal (true drop-in):
--   local MemDebug = ns and ns.MemDebug
--   if MemDebug then MemDebug:Attach(MyModuleTableOrFrame) end

--
-- Optional explicit name + extra tables:
--   MemDebug:Attach("MyModule", MyModule, Private, Internal)
--
-- Optional opts (last argument, or 2nd arg if using drop-in signature):
--   MemDebug:Attach(MyModule, { deep = true })
--   MemDebug:Attach("MyModule", MyModule, { deep = true, bucketFunc = fn })
--
-- opts:
--   name       : string override for module grouping
--   deep       : true to recurse subtables when wrapping functions
--   bucketFunc : function(self, funcKey, ...) -> bucket string (unit/viewer/etc)

-- Public API: Attach is a thin alias for internal registration.
-- Prefer MemDebug:DropIn(...) in new code.
function MemDebug:Attach(...)
  return self:_AttachInternal(...)
end

function MemDebug:_AttachInternal(moduleName, primary, ...)

  self._attached = self._attached or {}

  local opt = nil
  local extra = { ... }

  -- Drop-in signature:
  --   Attach(primary [, opt])
  if type(moduleName) ~= "string" then
    local droppedOpt = primary -- 2nd argument in drop-in form

    primary = moduleName
    moduleName = _getModuleName(primary)

    -- If they provided an opts table as the 2nd arg, capture it (common case).
    if type(droppedOpt) == "table" and (droppedOpt.deep ~= nil or droppedOpt.name ~= nil or droppedOpt.bucketFunc ~= nil or droppedOpt.bucket ~= nil) then
      opt = droppedOpt
    -- Otherwise allow opts as next vararg.
    elseif type(extra[1]) == "table" then
      opt = extra[1]
      extra[1] = nil
    end
  else

    moduleName = tostring(moduleName or "Unknown")

    -- Named signature:
    --   Attach("Name", primary, ... [, opt])
    local last = extra[#extra]
    if type(last) == "table" then
      opt = last
      extra[#extra] = nil
    end
  end

  moduleName = tostring((opt and opt.name) or moduleName or "Unknown")

  -- Register for UI + default enable
  self:_RegisterKnownModule(moduleName)

  -- Also ensure global lists are warm (helps UI before Start)
  if self.PingModules then
    self:PingModules()
  end

  local entry = self._attached[moduleName]


  if not entry or type(entry) ~= "table" or entry.list == nil then
    entry = { list = {}, opt = opt or {} }
    self._attached[moduleName] = entry
  else
    entry.opt = opt or entry.opt or {}
  end

  local function add(obj)
    if not obj then return end
    entry.list[#entry.list + 1] = obj
  end

  add(primary)
  for i = 1, #extra do
    add(extra[i])
  end

  -- If already running, install immediately.
  if self:IsEnabled() then
    self:_InstallUniversalOnAttached(moduleName)
  end

end



local function _defaultBucketFromCall(selfObj, funcKey, ...)
  -- 1) common: first arg is unit token
  local a1 = select(1, ...)
  if type(a1) == "string" then
    local u = a1
    if u == "player" or u == "pet" or u == "target" or u == "focus" or u == "mouseover" or u == "vehicle" then
      return u
    end
    if u:match("^party%d+$") or u:match("^raid%d+$") or u:match("^boss%d+$") or u:match("^arena%d+$") then
      return u
    end
    if u:match("^nameplate%d+$") then
      return u
    end

    -- 2) PCM-style: viewer keys
    if u:match("CooldownViewer") or u:match("^Essential") or u:match("^Utility") or u:match("^Buff") then
      return u
    end
  end

  -- 3) self.unit on frames/objects
  if type(selfObj) == "table" then
    if type(selfObj.unit) == "string" then
      return selfObj.unit
    end
    if type(selfObj.unitToken) == "string" then
      return selfObj.unitToken
    end
    if type(selfObj.viewerKey) == "string" then
      return selfObj.viewerKey
    end
    if type(selfObj._viewerKey) == "string" then
      return selfObj._viewerKey
    end
  end

  -- 4) Frame attribute "unit"
  if selfObj and type(selfObj.GetAttribute) == "function" then
    local unit = selfObj:GetAttribute("unit")
    if type(unit) == "string" and unit ~= "" then
      return unit
    end
  end

  return nil
end

-- Internal: install event/callback wrappers + optional function wrapping on all attached objects.
function MemDebug:_InstallUniversalOnAttached(moduleName)

  local mdb = _ensureDB()
  if mdb and not _moduleAllowed(mdb, moduleName) then
    return
  end

  if not self._attached or not self._attached[moduleName] then
    return
  end

  local entry = self._attached[moduleName]
  local list = entry.list or entry
  local opt  = entry.opt or {}

  local function _deepInstall(t, visited)
    if type(t) ~= "table" then return end
    visited = visited or {}
    if visited[t] then return end
    visited[t] = true

    -- Install on this object if it looks like a frame/object that registers stuff
    if self.InstallAceEventTracking and (type(t.RegisterEvent) == "function" or type(t.RegisterUnitEvent) == "function") then
      self:InstallAceEventTracking(t)
    end
    if self.InstallCallbackTracking and (type(t.RegisterCallback) == "function" or type(t.AddCallback) == "function") then
      self:InstallCallbackTracking(t, moduleName)
    end
    if self.InstallFrameEventTracking and type(t.SetScript) == "function" then
      self:InstallFrameEventTracking(t, moduleName)
    end

    for _, v in pairs(t) do
      if type(v) == "table" then
        _deepInstall(v, visited)
      end
    end
  end

  for i = 1, #list do
    local obj = list[i]
    if obj then
      -- 1) Events (AceEvent-style or any object exposing RegisterEvent/RegisterUnitEvent)
      if self.InstallAceEventTracking then
        self:InstallAceEventTracking(obj)
      end

      -- 2) Callbacks (CallbackHandler/AceCallback-style if present)
      if self.InstallCallbackTracking then
        self:InstallCallbackTracking(obj, moduleName)
      end

      -- 3) Frame OnEvent (RegisterEvent without AceEvent mixin)
      if self.InstallFrameEventTracking then
        self:InstallFrameEventTracking(obj, moduleName)
      end

      -- Deep-scan nested tables for frames/objects that register events/scripts/callbacks
      if opt and opt.deep == true and type(obj) == "table" then
        _deepInstall(obj, nil)
      end

      -- 4) Optional: wrap-all-functions (EXPENSIVE).
      -- Disabled by default. Enable per file by passing opt.wrapAll = true.
      if opt and opt.wrapAll == true and type(obj) == "table" and self.WrapAllFunctions then
        -- Only bucket funcs when the caller explicitly asks for it.
        -- Default: flat per-function keys under the module.
        local bucketFunc = (type(opt.bucketFunc) == "function") and opt.bucketFunc or nil
        self:WrapAllFunctions(moduleName, obj, {
          deep = opt.deep == true,
          bucket = opt.bucket, -- manual bucket prefix if desired
          bucketFunc = bucketFunc, -- optional dynamic bucketing ONLY if explicitly provided
        })
      end


    end
  end
end




-- Wrap a module table (and optionally nested subtables) so every function increments a counter.
-- opt:
--   deep = true -> recurse subtables
--   bucket = "Player" -> prefix for keys
function MemDebug:WrapAllFunctions(moduleName, tbl, opt)
  if not tbl or type(tbl) ~= "table" then return end
  moduleName = tostring(moduleName or "Unknown")
  opt = opt or {}

  local perTable = self._autoWrappedTables[tbl]
  if not perTable then
    perTable = {}
    self._autoWrappedTables[tbl] = perTable
  end

  local deep = opt.deep == true
  local baseBucket = opt.bucket and tostring(opt.bucket) or nil
  local bucketFunc = (type(opt.bucketFunc) == "function") and opt.bucketFunc or nil

  local visited = {}
  local maxDepth = (type(opt.maxDepth) == "number" and opt.maxDepth) or 6

  local function wrapTable(t, bucketPath, depth)
    if type(t) ~= "table" then return end
    if visited[t] then return end
    visited[t] = true

    if depth > maxDepth then
      return
    end

    local wrappedForT = self._autoWrappedTables[t]
    if not wrappedForT then
      wrappedForT = {}
      self._autoWrappedTables[t] = wrappedForT
    end

    for k, v in pairs(t) do
      if type(v) == "function" and not wrappedForT[k] then
        wrappedForT[k] = true
        local orig = v

        local keyStr = (type(k) == "string") and k or nil
        local isEventKey = false
        if keyStr and keyStr ~= "" then
          -- Heuristic: Blizzard event keys are typically ALLCAPS_WITH_UNDERSCORES (and digits).
          -- If this looks like an event key, do NOT treat it as a function name in the Funcs tree.
          if keyStr:match("^[A-Z0-9_]+$") and keyStr:find("_", 1, true) then
            isEventKey = true
          end
        end

        local funcKey = tostring(k)


        t[k] = function(...)
          -- Only count when this module’s auto-wrap is enabled
          if MemDebug:IsModuleAutoWrapEnabled(moduleName) then
            local bucket = bucketPath


            if isEventKey and keyStr then
              -- Track event-keyed handlers as Events, not Funcs (avoids "func renamed to event" UI).
              MemDebug:TrackEvent(moduleName, keyStr)
            else
              MemDebug:TrackFunc(moduleName, bucket, funcKey)

              -- Hard gate: CPU measuring must be impossible unless debugger is running.
              if MemDebug and MemDebug.IsEnabled and MemDebug:IsEnabled() then
                -- Optional CPU per-function measure (enabled via UI checkbox in Window)
                local cpu = MemDebug.CPU
                if cpu and cpu.ShouldMeasure and cpu.CallMeasured and cpu:ShouldMeasure(moduleName, bucket, funcKey) then
                  return cpu:CallMeasured(moduleName, bucket, funcKey, orig, ...)
                end
              end

            end

          end
          return orig(...)
        end

      elseif deep and type(v) == "table" and k ~= "__index" and k ~= "prototype" then
        local keyName = tostring(k)

        -- Prevent runaway traversal on linkage graphs / UI trees
        if keyName ~= "parent"
          and keyName ~= "children"
          and keyName ~= "db"
          and keyName ~= "_G"
        then
          local nextBucket = bucketPath
          if nextBucket and nextBucket ~= "" then
            nextBucket = nextBucket .. "." .. keyName
          else
            nextBucket = keyName
          end
          wrapTable(v, nextBucket, depth + 1)
        end
      end
    end
  end

  wrapTable(tbl, baseBucket, 0)

end


function MemDebug:Clear()
  _wipe(self._counts)
  _wipe(self._lastSnapshot)

  -- Also clear timeline data
  self._trace = nil
  self._traceStart = nil
  self._traceEnd = nil

  -- Clear CPU runtime buffers only when explicitly clearing (or on reload).
  if self.CPU and self.CPU.ResetRuntime then
    self.CPU:ResetRuntime()
  end
end



function MemDebug:GetLastSnapshot()
  return self._lastSnapshot or {}
end
-- === BLOCK: MemDebug - Public API Ends ===


-- === BLOCK: MemDebug - Reporting Starts ===
local function _sortedPairsByCount(t)
  local tmp = {}
  for k, v in pairs(t) do
    if type(v) == "number" and v > 0 then
      tmp[#tmp + 1] = { k = k, v = v }
    end
  end
  table.sort(tmp, function(a, b)
    if a.v == b.v then
      return a.k < b.k
    end
    return a.v > b.v
  end)
  return tmp
end

function MemDebug:SnapshotAndReset()
  local interval = self:GetInterval()
  local snap = {}
  for k, v in pairs(self._counts) do
    snap[k] = v
  end
  snap.__interval = interval
  snap.__time = _now()

  self._lastSnapshot = snap
  _wipe(self._counts)

  -- Optional tick hooks (CPU module etc.)
  local hooks = self._tickHooks
  if hooks then
    -- snapshot list so a hook can add/remove hooks safely without breaking iteration
    local list, n = {}, 0
    for _, fn in pairs(hooks) do
      if type(fn) == "function" then
        n = n + 1
        list[n] = fn
      end
    end

    for i = 1, n do
      list[i](self, snap.__time, interval)
    end
  end


  if MemDebug and MemDebug.Window and MemDebug.Window.OnSnapshot then
    MemDebug.Window:OnSnapshot(snap)
  end



  local mdb = _ensureDB()
  if mdb and mdb.printToChat then
    local lines = {}
    lines[#lines + 1] = string.format("|cff00ffff[Pleebug]|r Interval: %.2fs", interval)

    local sorted = _sortedPairsByCount(snap)
    local maxLines = 20
    local n = 0
    for i = 1, #sorted do
      local entry = sorted[i]
      if entry.k and not entry.k:match("^__") then
        n = n + 1
        if n > maxLines then break end
        local rate = entry.v / interval
        lines[#lines + 1] = string.format("%s = %d (%.1f/s)", entry.k, entry.v, rate)
      end
    end

    for i = 1, #lines do
      print(lines[i])
    end
  end
end

function MemDebug:Start()
  if self._ticker then
    self._ticker:Cancel()
    self._ticker = nil
  end

  self._enabled = true
  if self:IsAutoPollFramesEnabled() then
    self:_StartAutoPollTicker()
  end

  -- Install universal wrappers ONLY when running.

  -- 1) Core + existing AceAddon modules
  if self.InstallAceEventTracking then
    if Addon then
      self:_RegisterKnownModule(_getModuleName(Addon))
      self:InstallAceEventTracking(Addon)
    end

    if Addon and type(Addon.IterateModules) == "function" then
      for _, mod in Addon:IterateModules() do
        self:_RegisterKnownModule(_getModuleName(mod))
        self:InstallAceEventTracking(mod)
      end
    end
  end


  -- 2) Any files/modules that called MemDebug:DropIn(...)
  if self._attached then
    for moduleName in pairs(self._attached) do
      self:_InstallUniversalOnAttached(moduleName)
    end
  end

  -- Discover known modules ONCE at start (never from UI refresh)
  if self.PingModules and not self._didInitialPing then
    self._didInitialPing = true
    self:PingModules()
  end



  -- 3) New modules created while running: instrument them lazily
  if Addon and type(Addon.NewModule) == "function" and not self._origNewModule then
    self._origNewModule = Addon.NewModule
    Addon.NewModule = function(selfAddon, name, ...)
      local mod = MemDebug._origNewModule(selfAddon, name, ...)
      if MemDebug:IsEnabled() then
        MemDebug:InstallAceEventTracking(mod)
      end
      return mod
    end
  end

  -- Self-test: guarantees UI shows something immediately when running.
  self:TrackFunc("MemDebug", nil, "Start")

-- Reset runtime-only tracking buffers on every start (never SavedVariables).
  _wipe(self._counts)
  _wipe(self._lastSnapshot)
  self._trace = nil
  self._traceStart = nil
  self._traceEnd = nil

  -- CPU module keeps its own runtime buffers. Clear them only on Start (and Clear button),
  -- never on Stop and never persist to SavedVariables.
  if self.CPU and self.CPU.ResetRuntime then
    self.CPU:ResetRuntime()
  end


  local interval = self:GetInterval()
  self._ticker = C_Timer.NewTicker(interval, function()
    if not MemDebug:IsEnabled() then return end
    MemDebug:SnapshotAndReset()
  end)
end


function MemDebug:Stop()
  if self._ticker then
    self._ticker:Cancel()
    self._ticker = nil
  end

  self._enabled = false
  self:_StopAutoPollTicker()

  -- Keep runtime buffers for inspection after Stop(), but never persist to SavedVariables.
end

-- === BLOCK: MemDebug - Reporting Ends ===
-- === BLOCK: MemDebug - AceEvent Auto Tracking Starts ===
local function _wrapMethodForEvent(obj, methodName, moduleName)
  if not obj or not methodName then return end

  local perObj = MemDebug._wrapped[obj]
  if not perObj then
    perObj = {}
    MemDebug._wrapped[obj] = perObj
  end

  if perObj[methodName] then
    return
  end

  local orig = obj[methodName]
  if type(orig) ~= "function" then return end

  perObj[methodName] = true

  obj[methodName] = function(self, event, ...)
    MemDebug:TrackEvent(moduleName, event, select(1, ...))
    return orig(self, event, ...)
  end

end

local function _installOnObject(obj)
  if not obj then return end
  obj.__pleebugInstalled = true


  local moduleName = _getModuleName(obj)

  if type(obj.RegisterEvent) == "function" then
    local orig = obj.RegisterEvent
    obj.RegisterEvent = function(self, event, method, ...)
      local mName = _getModuleName(self)

      if method == nil then
        _wrapMethodForEvent(self, tostring(event), mName)
        return orig(self, event, nil, ...)
      end

      if type(method) == "string" then
        _wrapMethodForEvent(self, method, mName)
        return orig(self, event, method, ...)
      end

      if type(method) == "function" then
        local fn = method
        local wrapped = function(s, ev, ...)
          MemDebug:TrackEvent(mName, ev)
          return fn(s, ev, ...)
        end
        return orig(self, event, wrapped, ...)
      end

      return orig(self, event, method, ...)
    end
  end

  if type(obj.RegisterUnitEvent) == "function" then
    local orig = obj.RegisterUnitEvent
    obj.RegisterUnitEvent = function(self, event, method, ...)
      local mName = _getModuleName(self)

      if method == nil then
        _wrapMethodForEvent(self, tostring(event), mName)
        return orig(self, event, nil, ...)
      end

      if type(method) == "string" then
        _wrapMethodForEvent(self, method, mName)
        return orig(self, event, method, ...)
      end

      if type(method) == "function" then
        local fn = method
        local wrapped = function(s, ev, ...)
          MemDebug:TrackEvent(mName, ev)
          return fn(s, ev, ...)
        end
        return orig(self, event, wrapped, ...)
      end

      return orig(self, event, method, ...)
    end
  end

  -- Retro-wrap already registered AceEvent handlers (important when START happens after OnEnable).
  if type(obj.events) == "table" then
    local mName = _getModuleName(obj)

    local perObj = MemDebug._wrapped[obj]
    if not perObj then
      perObj = {}
      MemDebug._wrapped[obj] = perObj
    end

    for ev, method in pairs(obj.events) do
      if type(method) == "string" then
        _wrapMethodForEvent(obj, method, mName)
      elseif type(method) == "function" then
        local key = "__pleebug_evfn:" .. tostring(ev)
        if not perObj[key] then
          perObj[key] = true
          local fn = method
          obj.events[ev] = function(s, ...)
            MemDebug:TrackEvent(mName, tostring(ev))
            return fn(s, ...)
          end
        end
      end
    end
  end
end


-- Public helper so any module file can opt in:
-- MemDebug:InstallAceEventTracking(selfOrObject)
function MemDebug:InstallAceEventTracking(obj)
  _installOnObject(obj)
end

-- Optional: callback tracking (AceCallback/CallbackHandler style)
-- We count callbacks as Events with an "CB:" prefix so the existing UI stays unchanged.
function MemDebug:InstallCallbackTracking(obj, moduleName)
  if not obj or obj.__pleebugCallbackInstalled then return end
  obj.__pleebugCallbackInstalled = true

  moduleName = tostring(moduleName or _getModuleName(obj) or "Unknown")

  local function wrapCallbackRegister(methodKey)
    if type(obj[methodKey]) ~= "function" then return end

    local orig = obj[methodKey]
    obj[methodKey] = function(self, callbackName, method, ...)
      local mName = moduleName

      if type(method) == "string" then
        local origMethod = self[method]
        if type(origMethod) == "function" then
          self[method] = function(s, ...)
            MemDebug:TrackEvent(mName, "CB:" .. tostring(callbackName or "UNKNOWN_CB"))
            return origMethod(s, ...)
          end
        end
        return orig(self, callbackName, method, ...)
      end

      if type(method) == "function" then
        local fn = method
        local wrapped = function(...)
          MemDebug:TrackEvent(mName, "CB:" .. tostring(callbackName or "UNKNOWN_CB"))
          return fn(...)
        end
        return orig(self, callbackName, wrapped, ...)
      end

      -- method == nil or unexpected type
      return orig(self, callbackName, method, ...)
    end
  end

  -- Common names across Ace/CallbackHandler style consumers
  wrapCallbackRegister("RegisterCallback")
  wrapCallbackRegister("AddCallback")
end

function MemDebug:InstallFrameEventTracking(obj, moduleName)
  if not obj or obj.__pleebugFrameEventInstalled then return end

  -- Only frames support SetScript.
  if type(obj.SetScript) ~= "function" then return end
  obj.__pleebugFrameEventInstalled = true

  moduleName = tostring(moduleName or _getModuleName(obj) or "Unknown")

  -- Wrap only OnEvent, leave other scripts untouched.
  local origSetScript = obj.SetScript
  obj.SetScript = function(self, scriptName, handler, ...)
    if scriptName == "OnEvent" and type(handler) == "function" then
      -- Avoid wrapping our own wrapper again
      if handler ~= self.__pleebugOnEventWrapper then
        local fn = handler
        local mName = moduleName

        local wrapped = function(frame, event, ...)
          MemDebug:TrackEvent(mName, event, select(1, ...))
          return fn(frame, event, ...)
        end


        self.__pleebugOnEventOrig = fn
        self.__pleebugOnEventWrapper = wrapped
        handler = wrapped
      end
    end
    return origSetScript(self, scriptName, handler, ...)
  end

  -- Catch-up: if OnEvent is already set, wrap it immediately so we track per-event.
  -- Only event-capable frames support an OnEvent handler (textures/regions can SetScript but cannot receive events).
  if type(obj.GetScript) == "function" and (type(obj.RegisterEvent) == "function" or type(obj.RegisterUnitEvent) == "function") then
    local existing = obj:GetScript("OnEvent")
    if type(existing) == "function" and existing ~= obj.__pleebugOnEventWrapper then
      obj:SetScript("OnEvent", existing) -- routes through our SetScript wrapper above
    end
  end
end

-- === BLOCK: MemDebug - Frame Polling Starts ===

local function _BuildKnownFuncSetForModule(self, moduleName)
  local entry = self._attached and self._attached[moduleName]
  if not entry or type(entry) ~= "table" or type(entry.list) ~= "table" then
    return nil
  end

  local set = {}

  for _, obj in ipairs(entry.list) do
    if type(obj) == "table" then
      for _, v in pairs(obj) do
        if type(v) == "function" then
          set[v] = true
        end
      end
    elseif type(obj) == "function" then
      set[obj] = true
    end
  end

  return set
end

function MemDebug:PollFrames(moduleName)
  if type(EnumerateFrames) ~= "function" then
    return 0
  end

  local mdb = _ensureDB()
  local total = 0

  self._polledFrames = self._polledFrames or {}
  local function _seenFor(mName)
    self._polledFrames[mName] = self._polledFrames[mName] or setmetatable({}, { __mode = "k" })
    return self._polledFrames[mName]
  end

  local function _pollOne(mName)
    if mdb and not _moduleAllowed(mdb, mName) then
      return 0
    end

    local known = _BuildKnownFuncSetForModule(self, mName)
    if not known then
      return 0
    end

    local seen = _seenFor(mName)
    local count = 0

    local f = EnumerateFrames()
    while f do
      if not seen[f] then
        seen[f] = true

        if type(f.GetScript) == "function" then
          local onEvent = f:GetScript("OnEvent")
          if type(onEvent) == "function" and known[onEvent] then
            self:InstallFrameEventTracking(f, mName)
            count = count + 1
          end
        end
      end
      f = EnumerateFrames(f)
    end

    return count
  end

  if type(moduleName) == "string" and moduleName ~= "" then
    total = total + _pollOne(moduleName)
  else
    if self._attached then
      for mName in pairs(self._attached) do
        total = total + _pollOne(mName)
      end
    end
  end

  return total
end

function MemDebug:SetAutoPollFrames(enabled, interval)
  local mdb = _ensureDB()
  if not mdb then return end

  mdb.autoPollFrames = enabled and true or false
  mdb.autoPollFramesInterval = tonumber(interval) or 1

  if self:IsEnabled() and mdb.autoPollFrames then
    self:_StartAutoPollTicker()
  else
    self:_StopAutoPollTicker()
  end
end

function MemDebug:IsAutoPollFramesEnabled()
  local mdb = _ensureDB()
  return (mdb and mdb.autoPollFrames) == true
end

function MemDebug:_StartAutoPollTicker()
  self:_StopAutoPollTicker()

  local mdb = _ensureDB()
  if not mdb then return end

  local interval = tonumber(mdb.autoPollFramesInterval) or 1
  if interval < 0.2 then interval = 0.2 end

  if C_Timer and C_Timer.NewTicker then
    self._autoPollTicker = C_Timer.NewTicker(interval, function()
      MemDebug:PollFrames(nil)
    end)
  end
end

function MemDebug:_StopAutoPollTicker()
  if self._autoPollTicker then
    self._autoPollTicker:Cancel()
    self._autoPollTicker = nil
  end
end

-- === BLOCK: MemDebug - Frame Polling Ends ===

-- IMPORTANT:
-- Do NOT install at file load. MemDebug is dev-only and must stay idle until Start().
-- Installation happens inside MemDebug:Start().

-- === BLOCK: MemDebug - AceEvent Auto Tracking Ends ===

-- === BLOCK: MemDebug - Slash Command Starts ===
local function _ToggleMemDebugWindow()
  if MemDebug and MemDebug.Window and MemDebug.Window.Toggle then
    MemDebug.Window:Toggle()
    return
  end
  print("Pleebug window is not loaded yet.")
end


-- Addon-free slash command
if not SLASH_PLEEBBUG1 then
  SLASH_PLEEBBUG1 = "/pleebug"
  SlashCmdList.PLEEBBUG = function()
    _ToggleMemDebugWindow()
  end
end
-- === BLOCK: MemDebug - Slash Command Ends ===

