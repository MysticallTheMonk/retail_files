-- File: LibPleebug-1_CPU.lua
-- Optional CPU sampling for Pleebug (per AddOn).
-- Drawn as an overlay line in the diagram.

local LibStub = _G.LibStub
local MemDebug = LibStub and LibStub("LibPleebug-1", true)
if not MemDebug then return end

MemDebug.CPU = MemDebug.CPU or {}
local CPU = MemDebug.CPU

-- ---------------------------------------------------------------------
-- Tick hook: sample AddOn CPU once per Pleebug snapshot
-- Controlled by "Enable CPU logging"
-- ---------------------------------------------------------------------
if MemDebug and MemDebug.RegisterTickHook then
  MemDebug:RegisterTickHook("CPU", function(self, now, interval)
    local cpu = self.CPU
    if not cpu or not cpu.Enabled or not cpu:Enabled() then
      return
    end

    local db = self:GetDB()
    local mods = db and db.modules
    if not mods then
      return
    end

    -- If the profiler is off, don't push a fake 0ms line.
    if not (C_AddOnProfiler and C_AddOnProfiler.IsEnabled and C_AddOnProfiler.IsEnabled()) then
      return
    end


    local totalMs = 0

    for moduleName in pairs(mods) do
      local ms = cpu:OnTick(moduleName, now)
      if ms then
        totalMs = totalMs + (tonumber(ms) or 0)
      end
    end

    -- One overall line for "total addon cost" across enabled modules
    cpu:PushSample("CPU.Total", totalMs, now)




  end)
end



local function _now()
  if GetTimePreciseSec then return GetTimePreciseSec() end
  if GetTime then return GetTime() end
  return 0
end

local METRIC = Enum and Enum.AddOnProfilerMetric or nil
local METRIC_LAST_TIME = METRIC and METRIC.LastTime or nil

local function _ProfilerEnabled()
  if C_AddOnProfiler and C_AddOnProfiler.IsEnabled then
    return C_AddOnProfiler.IsEnabled()
  end
  return false
end

local function _GetAddOnLastMs(addonName)
  if not addonName or addonName == "" then return nil end
  if not METRIC_LAST_TIME then return nil end
  if not (C_AddOnProfiler and C_AddOnProfiler.GetAddOnMetric) then return nil end
  return C_AddOnProfiler.GetAddOnMetric(addonName, METRIC_LAST_TIME)
end

local function _Trim(samples, windowSec, nowT)
  if not samples or #samples == 0 then return end
  local cutoff = (nowT or _now()) - (windowSec or 10)
  while #samples > 0 do
    local t = samples[1] and samples[1].t
    if not t or t >= cutoff then break end
    table.remove(samples, 1)
  end
end

local function _EnsureCDB()
  if not MemDebug.GetDB then return nil end
  local db = MemDebug:GetDB()
  if not db then return nil end

  db.cpu = db.cpu or {}
  local cdb = db.cpu

  if type(cdb.enabled) ~= "boolean" then cdb.enabled = false end

  cdb.keepSeconds = tonumber(cdb.keepSeconds) or 120
  if cdb.keepSeconds < 10 then cdb.keepSeconds = 10 end
  if cdb.keepSeconds > 600 then cdb.keepSeconds = 600 end

  if cdb.refLine == nil then cdb.refLine = false end
  cdb.refFps = tonumber(cdb.refFps) or 60
  if cdb.refFps < 1 then cdb.refFps = 1 end
  if cdb.refFps > 1000 then cdb.refFps = 1000 end

  -- Preferences are allowed to persist.
  cdb.measured  = cdb.measured  or {} -- [path] = true

  -- Tracking outputs must NEVER persist to SavedVariables.
  if cdb.funcStats ~= nil then cdb.funcStats = nil end
  if cdb.samples ~= nil then cdb.samples = nil end

  -- Runtime-only buffers (kept after Stop/closing window, cleared on Start/Clear/reload).
  CPU._rtFuncStats = CPU._rtFuncStats or {} -- [path] = { n, sum, min, max, last }
  CPU._rtSamples   = CPU._rtSamples   or {} -- [seriesKey] = { {t=, v=} , ... }

  return cdb
end

local function _WipeTable(t)
  if not t then return end
  for k in pairs(t) do
    t[k] = nil
  end
end

function CPU:ResetRuntime()
  _WipeTable(self._rtFuncStats)
  _WipeTable(self._rtSamples)
end

local function _GetFuncStats()
  CPU._rtFuncStats = CPU._rtFuncStats or {}
  return CPU._rtFuncStats
end

local function _GetSamples()
  CPU._rtSamples = CPU._rtSamples or {}
  return CPU._rtSamples
end


function CPU:SetEnabled(on)
  local cdb = _EnsureCDB()
  if not cdb then return end
  cdb.enabled = (on == true)
end

function CPU:Enabled()
  local cdb = _EnsureCDB()
  return cdb and cdb.enabled == true
end

-- (removed duplicate EnsureSampler; keep the later definition)

function CPU:GetScaleMs()
  local cdb = _EnsureCDB()
  return cdb and (tonumber(cdb.scaleMs) or 16.7) or 16.7
end

function CPU:SetScaleMs(ms)
  local cdb = _EnsureCDB()
  if not cdb then return end
  ms = tonumber(ms) or 16.7
  if ms < 1 then ms = 1 end
  if ms > 100 then ms = 100 end
  cdb.scaleMs = ms
end


function CPU:EnsureSampler()
  local cdb = _EnsureCDB()
  if not cdb then return end

  if cdb.enabled ~= true then
    cdb.enabled = true
  end

  if cdb.overlay == nil then
    cdb.overlay = true
  end
end

-- Called by the core tick (SnapshotAndReset) when CPU logging is enabled.
function CPU:OnTick(moduleName, nowT)

  local cdb = _EnsureCDB()
  if not cdb or cdb.enabled ~= true then return end
  if not _ProfilerEnabled() then return end

  nowT = nowT or _now()

  local db = MemDebug:GetDB()
  local addonName = db and db.moduleAddonName and db.moduleAddonName[moduleName] or nil
  if not addonName then return end

  local ms = _GetAddOnLastMs(addonName)
  if not ms then return end

  local laneKey = "CPU.AddOn." .. tostring(moduleName or "Unknown")

  local all = _GetSamples()
  all[laneKey] = all[laneKey] or {}
  table.insert(all[laneKey], { t = nowT, v = tonumber(ms) or 0 })

  _Trim(all[laneKey], cdb.keepSeconds or 120, nowT)

  return tonumber(ms) or 0
end



function CPU:GetRecentSamples(a, b, c)
  local cdb = _EnsureCDB()
  if not cdb then
    return {}, _now()
  end

  local moduleName, windowSec, nowT

  -- Two supported call styles:
  -- 1) GetRecentSamples("ModuleName", windowSec, nowT)
  -- 2) GetRecentSamples(windowSec, nowT)  -- used by Diagram.lua
  if type(a) == "string" or a == nil then
    moduleName = a
    windowSec  = b
    nowT       = c
  else
    moduleName = nil
    windowSec  = a
    nowT       = b
  end

  windowSec = tonumber(windowSec) or 10
  if windowSec < 0.1 then windowSec = 0.1 end
  if windowSec > 600 then windowSec = 600 end

  nowT = tonumber(nowT) or _now()

  local key
  if moduleName and moduleName ~= "" then
    key = "CPU.AddOn." .. tostring(moduleName)
  else
    key = "CPU"
  end

  local all = _GetSamples()
  local samples = all[key] or {}
  local cutoff = nowT - windowSec

  local out = {}
  for i = 1, #samples do
    local e = samples[i]
    if e and e.t and e.v and e.t >= cutoff then
      out[#out+1] = e
    end
  end

  return out, nowT
end


-- -------------------------------------------------------------------
-- Multi-lane events for CPU timeline window
-- Returns events: { { t=, key=seriesKey, v=ms }, ... }, nowT
-- -------------------------------------------------------------------
function CPU:GetRecentEvents(windowSec, nowT)
  local cdb = _EnsureCDB()
  if not cdb then
    return {}, _now()
  end

  windowSec = tonumber(windowSec) or 10
  if windowSec < 0.1 then windowSec = 0.1 end

  nowT = nowT or _now()
  local cutoff = nowT - windowSec

  local all = _GetSamples()

  local out = {}
  for seriesKey, samples in pairs(all) do
    -- Skip the aggregate CPU.Total in the timeline view so it doesn't flatten the scale
    if seriesKey ~= "CPU.Total" and samples and #samples > 0 then
      for i = 1, #samples do
        local e = samples[i]
        if e and e.t and e.v and e.t >= cutoff then
          out[#out+1] = { t = e.t, key = seriesKey, v = e.v }
        end
      end
    end
  end

  table.sort(out, function(a, b)
    return (a.t or 0) < (b.t or 0)
  end)

  return out, nowT
end



-- Manual injection for MeasureCall (shares same timeline)
function CPU:PushSample(seriesKey, ms, nowT)
  local cdb = _EnsureCDB()
  if not cdb or not cdb.enabled then return end

  seriesKey = seriesKey or "CPU.Unknown"
  ms = tonumber(ms) or 0
  nowT = nowT or _now()

  local all = _GetSamples()
  all[seriesKey] = all[seriesKey] or {}
  local samples = all[seriesKey]

  samples[#samples+1] = { t = nowT, v = ms }

  _Trim(samples, cdb.keepSeconds or 120, nowT)
end



-- -------------------------------------------------------------------
-- Overlay toggle helpers
-- -------------------------------------------------------------------
function CPU:OverlayEnabled()
  local cdb = _EnsureCDB()
  return cdb and cdb.overlay == true
end

function CPU:IsOverlayEnabled()
  return self:OverlayEnabled()
end

function CPU:SetOverlayEnabled(on)
  local cdb = _EnsureCDB()
  if not cdb then return end
  cdb.overlay = (on == true)
end


-- -------------------------------------------------------------------
-- Optional reference line (frame budget derived from target FPS)
-- -------------------------------------------------------------------
function CPU:RefLineEnabled()
  local cdb = _EnsureCDB()
  return cdb and cdb.refLine == true
end

function CPU:SetRefLineEnabled(on)
  local cdb = _EnsureCDB()
  if not cdb then return end
  cdb.refLine = (on == true)
end

function CPU:GetRefFps()
  local cdb = _EnsureCDB()
  return cdb and tonumber(cdb.refFps) or 60
end

function CPU:SetRefFps(fps)
  local cdb = _EnsureCDB()
  if not cdb then return end
  fps = tonumber(fps) or 60
  if fps < 1 then fps = 1 end
  if fps > 1000 then fps = 1000 end
  cdb.refFps = fps
end

function CPU:GetRefBudgetMs()
  local cdb = _EnsureCDB()
  if not (cdb and cdb.refLine == true) then return nil end
  local fps = tonumber(cdb.refFps) or 0
  if fps <= 0 then return nil end
  return 1000 / fps
end



-- -------------------------------------------------------------------
-- Per-function measurement: path helpers + stats
-- -------------------------------------------------------------------
local function _BuildPath(moduleName, bucket, funcName)

  local path = tostring(moduleName or "Unknown")
  if bucket and bucket ~= "" then
    path = path .. "." .. tostring(bucket)
  end
  path = path .. "." .. tostring(funcName or "Unknown")
  return path
end

function CPU:IsMeasuredPath(path)
  if not path or path == "" then return false end
  local cdb = _EnsureCDB()
  local m = cdb and cdb.measured

  -- Default behavior: ON unless explicitly disabled for this path.
  if not m then return true end

  local v = m[path]
  if v == false then return false end
  return true
end


function CPU:SetMeasuredPath(path, state)
  if not path or path == "" then return end
  local cdb = _EnsureCDB()
  if not cdb then return end

  cdb.measured = cdb.measured or {}

  -- We store ONLY explicit disables to keep the table small.
  -- nil means "default (enabled)".
  if state then
    cdb.measured[path] = nil
  else
    cdb.measured[path] = false
  end
end


function CPU:GetFuncStat(path)
  if not path or path == "" then return nil end
  local s = _GetFuncStats()
  return s and s[path]
end


local function _PushFuncStat(path, ms)
  local cdb = _EnsureCDB()
  if not cdb then return end

  local stats = _GetFuncStats()
  local st = stats[path]
  if not st then
    st = { n = 0, sum = 0, min = nil, max = nil, last = nil }
    stats[path] = st
  end

  ms = tonumber(ms) or 0
  st.n   = (st.n or 0) + 1
  st.sum = (st.sum or 0) + ms
  st.last = ms
  if st.min == nil or ms < st.min then st.min = ms end
  if st.max == nil or ms > st.max then st.max = ms end
end


-- -------------------------------------------------------------------
-- API used by LibPleebug-1.lua wrappers (Def / WrapAll)
-- -------------------------------------------------------------------
function CPU:ShouldMeasure(moduleName, bucket, funcName)
  local path = _BuildPath(moduleName, bucket, funcName)
  return self:IsMeasuredPath(path)
end

function CPU:CallMeasured(moduleName, bucket, funcName, fn, ...)
  local path = _BuildPath(moduleName, bucket, funcName)
  local cdb = _EnsureCDB()
  if not cdb or type(fn) ~= "function" then
    return fn(...)
  end

  local mode = cdb.measureMode or "debug"

  -- MeasureCall mode: use Blizzard profiler if available
  if mode == "measurecall"
     and C_AddOnProfiler and C_AddOnProfiler.MeasureCall
     and _ProfilerEnabled()
  then
    local packed = table.pack(...)
    local rets
    local results = C_AddOnProfiler.MeasureCall(function()
      rets = table.pack(fn(table.unpack(packed, 1, packed.n)))
    end)

    if results and results.elapsedMilliseconds then
      local ms = tonumber(results.elapsedMilliseconds) or 0
      _PushFuncStat(path, ms)
      -- Feed into CPU timeline as a separate per-function lane
      self:PushSample("CPU.Func." .. path, ms)

    end

    if rets then
      return table.unpack(rets, 1, rets.n)
    end
    return
  end

  -- Default: debugprofilestop timing
  local t0 = debugprofilestop and debugprofilestop() or 0
  local a,b,c2,d,e,f,g,h,i,j = fn(...)
  local t1 = debugprofilestop and debugprofilestop() or t0
  local ms = t1 - t0

  _PushFuncStat(path, ms)
  self:PushSample("CPU.Func." .. path, ms)


  return a,b,c2,d,e,f,g,h,i,j
end
