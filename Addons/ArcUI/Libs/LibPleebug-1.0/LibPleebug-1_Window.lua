-- === BLOCK: File Header Starts ===
-- File: LibPleebug-1_Window.lua
-- Purpose: Standalone dev window for debugger reports (expandable tree).
-- === BLOCK: File Header Ends ===


-- === BLOCK: MemDebugWindow - Setup Starts ===
local LibStub = _G.LibStub
local MemDebug = LibStub and LibStub("LibPleebug-1", true)
if not MemDebug then return end

local W = MemDebug.Window or {}
MemDebug.Window = W

local _wipe = _G.wipe or (table and table.wipe) or function(t)
  if not t then return end
  for k in pairs(t) do
    t[k] = nil
  end
end



W.frame = W.frame or nil
W.rows = W.rows or {}
W.expanded = W.expanded or {}
-- UI tuning (dev window only)
W.uiScale = W.uiScale or 1.25     -- increase for readability/clicking
W.fontSize = W.fontSize or (MemDebug.GetFontSize and MemDebug:GetFontSize()) or 14
W.titleFontSize = W.titleFontSize or 18
-- Timeline trace (rolling)
W.traceEnabled = (W.traceEnabled ~= false)
W.traceWindow = W.traceWindow or 10   -- seconds shown in diagram (1-30)
W.traceMax = W.traceMax or 40000
W.traceStyle = (MemDebug and MemDebug.GetTraceStyle and MemDebug:GetTraceStyle()) or W.traceStyle or "tick"
W._trace = W._trace or nil
W._traceStart = W._traceStart or nil
W._traceEnd = W._traceEnd or nil

local function _nowPrecise()
  if GetTimePreciseSec then
    return GetTimePreciseSec()
  end
  return (GetTime and GetTime()) or 0
end

function W:_TraceClear()
  self._trace = nil
  self._traceStart = nil
  self._traceEnd = nil
end

function W:_TracePush(key)
  if not self.traceEnabled or not key or key == "" then
    return
  end

  local t = _nowPrecise()
  if not t or t <= 0 then
    return
  end

  self._trace = self._trace or {}
  self._traceStart = self._traceStart or 1
  self._traceEnd = self._traceEnd or 0

  self._traceEnd = self._traceEnd + 1
  self._trace[self._traceEnd] = { t = t, key = key }

  -- Time-based prune (keep a small buffer past window)
  local keep = (tonumber(self.traceWindow) or 10) + 2
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

  -- Hard cap
  local maxN = tonumber(self.traceMax) or 40000
  local n = self._traceEnd - self._traceStart + 1
  if n > maxN then
    self._traceStart = self._traceEnd - maxN + 1
  end

  -- Occasional compact
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

function W:GetRecentTrace(windowSec)
  windowSec = tonumber(windowSec) or (tonumber(self.traceWindow) or 10)
  if windowSec < 0.1 then windowSec = 0.1 end

  local now = _nowPrecise()
  local cutoff = now - windowSec

  local out = {}
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

-- Wrap MemDebug trackers (no need to edit MemDebug.lua)
if not W._traceWrapped then
  W._traceWrapped = true

  local origTrackEvent = MemDebug.TrackEvent
  if type(origTrackEvent) == "function" then
    MemDebug.TrackEvent = function(self, moduleName, eventName, ...)
      origTrackEvent(self, moduleName, eventName, ...)
      -- NOTE: Do not double-trace here. Core MemDebug already traces.
      W._traceSeq = (W._traceSeq or 0) + 1
    end
  end

  local origTrackFunc = MemDebug.TrackFunc
  if type(origTrackFunc) == "function" then
    MemDebug.TrackFunc = function(self, moduleName, bucketName, funcName, ...)
      origTrackFunc(self, moduleName, bucketName, funcName, ...)
      -- NOTE: Do not double-trace here. Core MemDebug already traces.
      W._traceSeq = (W._traceSeq or 0) + 1
    end
  end


end



-- Hard rule for this dev window:
-- No host-theme dependencies. Library provides a small internal palette.
local function _getPalette()
  -- Defaults: square, dark, readable, accent highlight
  local accent = { 0.20, 0.60, 1.00, 1.00 }
  local border = { 0.20, 0.20, 0.20, 1.00 }
  local text   = { 1.00, 1.00, 1.00, 1.00 }
  local bgWin  = { 0.00, 0.00, 0.00, 0.88 }
  local bgPane = { 0.00, 0.00, 0.00, 0.35 }

  if MemDebug and type(MemDebug.GetThemeColors) == "function" then
    local a, b, t, w, p = MemDebug:GetThemeColors()
    if type(a) == "table" then accent = a end
    if type(b) == "table" then border = b end
    if type(t) == "table" then text = t end
    if type(w) == "table" then bgWin = w end
    if type(p) == "table" then bgPane = p end
  end

  return accent, border, text, bgWin, bgPane
end

local function _applyFontSafe(fs, size, flags)
  if not fs or not fs.SetFont then return end
  size = tonumber(size) or 12
  size = math.floor(size * (W.uiScale or 1) + 0.5)
  flags = flags or ""

  local path = fs.GetFont and select(1, fs:GetFont()) or nil
  if not path or path == "" then
    path = (STANDARD_TEXT_FONT and STANDARD_TEXT_FONT ~= "" and STANDARD_TEXT_FONT) or "Fonts\\FRIZQT__.TTF"
  end
  fs:SetFont(path, size, flags)
end

local function _colorText(fs)
  if not fs or not fs.SetTextColor then return end
  local _, _, t = _getPalette()
  fs:SetTextColor(t[1], t[2], t[3], t[4] or 1)
end


local function _buildTreeFromSnapshot(snapshot)
  local root = { name = "root", path = "", count = 0, children = {} }

  local function ensureChild(node, name, path)
    node.children[name] = node.children[name] or { name = name, path = path, count = 0, children = {} }
    return node.children[name]
  end

  for key, v in pairs(snapshot or {}) do
    if type(v) == "number" and v > 0 and type(key) == "string" and not key:match("^__") then
      root.count = root.count + v

      local node = root
      local path = ""
      for part in key:gmatch("[^%.]+") do
        path = (path == "" and part) or (path .. "." .. part)
        node = ensureChild(node, part, path)
        node.count = node.count + v
      end
    end
  end

  return root
end

local function _sortedChildList(node)
  local list = {}
  for _, child in pairs(node.children or {}) do
    list[#list + 1] = child
  end
  table.sort(list, function(a, b)
    if a.count == b.count then
      return a.name < b.name
    end
    return a.count > b.count
  end)
  return list
end

local function _flatten(node, out, depth, expanded)
  depth = depth or 0
  out = out or {}

  if node.path ~= "" then
    out[#out + 1] = { node = node, depth = depth }
  end

  local hasChildren = node.children and next(node.children) ~= nil
  if not hasChildren then
    return out
  end

  if node.path == "" or expanded[node.path] then
    local kids = _sortedChildList(node)
    for i = 1, #kids do
      _flatten(kids[i], out, depth + 1, expanded)
    end
  end

  return out
end

-- ---------------------------------------------------------------------------
-- Deferred tree building (prevents /pleebug freeze on large snapshots)
-- ---------------------------------------------------------------------------
W._buildInProgress = W._buildInProgress or false
W._buildIterKey = W._buildIterKey or nil
W._buildRoot = W._buildRoot or nil
W._pendingSnapshot = W._pendingSnapshot or nil
W._pendingInterval = W._pendingInterval or nil
W._pendingEnabled = W._pendingEnabled or nil
W._pendingLiveMode = W._pendingLiveMode or nil

W._flat = W._flat or {}
W._flatBuiltFor = W._flatBuiltFor or nil
W._lastRenderAt = W._lastRenderAt or 0
W._lastTimelineAt = W._lastTimelineAt or 0

local function _treeEnsureChild(node, name, path)
  node.children[name] = node.children[name] or { name = name, path = path, count = 0, children = {} }
  return node.children[name]
end

-- Safe deferral: never use C_Timer.After(0) (can spinlock WoW)
local function _Defer(fn)
  if not fn then return end
  C_Timer.After(0.01, fn)
end


function W:_StartDeferredBuild(snapshot)
  self._pendingSnapshot = snapshot or {}
  self._buildRoot = { name = "root", path = "", count = 0, children = {} }
  self._buildIterKey = nil
  self._buildInProgress = true

  if self.frame and self.frame._statusText then
    self.frame._statusText:SetText("Status: Building tree...")
  end

  if C_Timer and C_Timer.After then
    _Defer(function()
      if W and W._BuildDeferredStep then
        W:_BuildDeferredStep()
      end
    end)
  else
    self:_BuildDeferredStep()
  end
end

function W:_BuildDeferredStep()
  if not self._buildInProgress then return end
  local snap = self._pendingSnapshot
  if type(snap) ~= "table" then
    self._buildInProgress = false
    return
  end

  local root = self._buildRoot
  if not root then
    self._buildInProgress = false
    return
  end

  local startMs = (debugprofilestop and debugprofilestop()) or nil
  local budgetMs = 6

  while true do
    local k, v = next(snap, self._buildIterKey)
    if not k then
      -- Done
      self._buildInProgress = false
      self._flat = _flatten(root, {}, 0, self.expanded or {})
      self._flatBuiltFor = snap

      -- Render immediately once build finishes
      self:_RenderFlat()
      return
    end

    self._buildIterKey = k

    if type(v) == "number" and v > 0 and type(k) == "string" and not k:match("^__")
      and k ~= "Funcs.Total" and k ~= "Events.Total"
    then
      root.count = root.count + v


      local node = root
      local path = ""
      for part in k:gmatch("[^%.]+") do
        path = (path == "" and part) or (path .. "." .. part)
        node = _treeEnsureChild(node, part, path)
        node.count = node.count + v
      end
    end

    if startMs and (debugprofilestop() - startMs) >= budgetMs then
      break
    end
  end

  if C_Timer and C_Timer.After then
    _Defer(function()
      if W and W._BuildDeferredStep then
        W:_BuildDeferredStep()
      end
    end)
  end
end

local _ensureRow

function W:_RenderFlat()

  local f = self.frame
  if not f or not f:IsShown() then return end

  local flat = self._flat or {}
  local interval = self._pendingInterval or (MemDebug.GetInterval and MemDebug:GetInterval()) or 10

  -- Row cap safety (UI only)
  local MAX_ROWS = 600
  local nRows = #flat
  if nRows > MAX_ROWS then
    nRows = MAX_ROWS
  end

  local parent = f._content
  if parent and parent.SetHeight then
    local rowH = W.rowHeight or 24
    parent:SetHeight((nRows + 1) * rowH)
  end

  local y = -2
  local rowH = W.rowHeight or 24

  for i = 1, nRows do
    local entry = flat[i]
    local row = _ensureRow(i)
    row:Show()

    if row.SetHeight then
      row:SetHeight(rowH)
    end
    if row.label then
      _applyFontSafe(row.label, W.fontSize or 14, nil)
      _colorText(row.label)
    end
    if row.value then
      _applyFontSafe(row.value, W.fontSize or 14, nil)
      _colorText(row.value)
    end
    if row.cpuValue then
      _applyFontSafe(row.cpuValue, W.fontSize or 14, nil)
      _colorText(row.cpuValue)
    end


    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)

    local node = entry.node
    local depth = entry.depth or 0

    local hasChildren = node.children and next(node.children) ~= nil
    local prefix = ""
    if hasChildren then
      prefix = (self.expanded[node.path] and "- " or "+ ")
    else
      prefix = "  "
    end

    local indent = string.rep("   ", math.max(0, depth - 1))
    row.label:SetText(prefix .. indent .. node.name)

    local count = node.count or 0
    local rate = (interval and interval > 0) and (count / interval) or 0

    -- show cpu toggle only on function leaf rows:
    -- "Funcs.<Module>.<Func>" or "Funcs.<Module>.<Bucket>.<Func>"
    local partCount = 0
    if node.path then
      for _ in tostring(node.path):gmatch("[^%.]+") do
        partCount = partCount + 1
      end
    end

    local isFuncLeaf =
      node.path
      and tostring(node.path):match("^Funcs%.")
      and (partCount >= 3)
      and not (node.children and next(node.children))

    local cpu = MemDebug and MemDebug.CPU
    local cpuPath = nil
    if isFuncLeaf and node.path then
      -- Window tree uses "Funcs.<Module>....", CPU uses "<Module>...."
      cpuPath = tostring(node.path):gsub("^Funcs%.", "")
    end

    if row.cpuToggle and isFuncLeaf and cpu and cpu.IsMeasuredPath and cpuPath then
      row.cpuToggle:Show()
      row.cpuToggle:SetChecked(cpu:IsMeasuredPath(cpuPath) and true or false)
    elseif row.cpuToggle then
      row.cpuToggle:Hide()
    end

    local baseText = string.format("%d (%.1f/s)", count, rate)
    row.value:SetText(baseText)

    local cpuText = ""
    if isFuncLeaf and cpu and cpu.GetFuncStat and cpuPath then
      local st = cpu:GetFuncStat(cpuPath)
      if st and st.n and st.n > 0 then
        local avg  = (st.sum or 0) / (st.n or 1)
        local maxv = st.max or st.last or 0
        cpuText = string.format("%.3f ms (%.3f)", avg, maxv)
      end
    end


    if row.cpuValue then
      row.cpuValue:SetText(cpuText)
      row.cpuValue:SetShown(cpuText ~= "")
    end

    -- ensure cpu sampler is alive if CPU exists
    if cpu and cpu.EnsureSampler then
      cpu:EnsureSampler()
    end


    row._data = entry
    y = y - rowH
  end

  for i = nRows + 1, #self.rows do
    if self.rows[i] then
      self.rows[i]:Hide()
      self.rows[i]._data = nil
    end
  end

  if nRows < #flat and f._statusText then

    f._statusText:SetText((f._statusText:GetText() or "") .. string.format("   (Showing first %d rows)", nRows))
  end
end

-- === BLOCK: MemDebugWindow - Setup Ends ===


-- === BLOCK: MemDebugWindow - UI Factory Starts ===

-- === BLOCK: MemDebugWindow - Skin + Native Widgets Starts ===
local function _applyBackdrop(frame, bg, border, inset)
  if not frame or not frame.SetBackdrop then return end
  inset = tonumber(inset) or 1
  frame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = inset, right = inset, top = inset, bottom = inset },
  })
  frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
  frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function _skinFrame(frame, kind)
  if not frame then return end
  local _, border, _, bgWin, bgPane = _getPalette()
  local bg = (kind == "pane") and bgPane or bgWin
  _applyBackdrop(frame, bg, border, 1)
end

local function _hookAccentBorder(frame)
  if not frame or frame.__pleebugAccentHooked then return end
  frame.__pleebugAccentHooked = true

  local accent, border = _getPalette()
  frame:HookScript("OnEnter", function(self)
    if self.SetBackdropBorderColor then
      self:SetBackdropBorderColor(accent[1], accent[2], accent[3], accent[4] or 1)
    end
  end)
  frame:HookScript("OnLeave", function(self)
    if self.SetBackdropBorderColor then
      self:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    end
  end)
end

local function _skinButton(btn)
  if not btn then return end
  if not btn.SetBackdrop then
    -- ensure BackdropTemplate behavior without changing the template used
    local bg = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    bg:SetAllPoints(btn)
    bg:SetFrameLevel((btn:GetFrameLevel() or 0) - 1)
    btn._pleebugBg = bg
    _skinFrame(bg, "pane")
    _hookAccentBorder(bg)
    if bg.EnableMouse then bg:EnableMouse(false) end
  else
    _skinFrame(btn, "pane")
    _hookAccentBorder(btn)
  end
end

local function _makeLabeledSlider(parent, label, minV, maxV, stepV, valueV, onChanged)
  local wrap = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  wrap:SetHeight(46)
  wrap:SetWidth(360)
  _skinFrame(wrap, "pane")
  _hookAccentBorder(wrap)

  local lbl = wrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  lbl:SetPoint("TOPLEFT", wrap, "TOPLEFT", 8, -6)
  lbl:SetText(label or "")
  _applyFontSafe(lbl, math.max(12, (W.fontSize or 14)), "OUTLINE")
  _colorText(lbl)
  wrap._label = lbl

  local valText = wrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  valText:SetPoint("TOPRIGHT", wrap, "TOPRIGHT", -8, -6)
  _applyFontSafe(valText, math.max(12, (W.fontSize or 14)), "OUTLINE")
  _colorText(valText)
  wrap._valText = valText

  local slider = CreateFrame("Slider", nil, wrap)
  slider:SetPoint("BOTTOMLEFT", wrap, "BOTTOMLEFT", 10, 8)
  slider:SetPoint("BOTTOMRIGHT", wrap, "BOTTOMRIGHT", -10, 8)
  slider:SetHeight(14)
  slider:SetOrientation("HORIZONTAL")

  minV = tonumber(minV) or 0
  maxV = tonumber(maxV) or 1
  stepV = tonumber(stepV) or 1
  slider:SetMinMaxValues(minV, maxV)
  slider:SetValueStep(stepV)
  slider:SetObeyStepOnDrag(true)

  local accent = _getPalette()
  local thumb = slider:CreateTexture(nil, "OVERLAY")
  thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
  thumb:SetSize(10, 16)
  thumb:SetVertexColor(accent[1] or 1, accent[2] or 1, accent[3] or 1, 1)
  slider:SetThumbTexture(thumb)


  local track = slider:CreateTexture(nil, "ARTWORK")
  track:SetTexture("Interface\\Buttons\\WHITE8x8")
  track:SetPoint("CENTER", slider, "CENTER", 0, 0)
  track:SetSize(1, 4)
  track:SetVertexColor(1, 1, 1, 0.10)
  track:SetPoint("LEFT", slider, "LEFT", 0, 0)
  track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
  wrap._track = track

  local function setValueText(v)
    if wrap._valText then
      wrap._valText:SetText(tostring(v))
    end
  end

  slider:SetScript("OnValueChanged", function(_, v)
    v = tonumber(v) or 0
    v = math.floor(v + 0.5)
    setValueText(v)
    if type(onChanged) == "function" then
      onChanged(v)
    end
  end)

  valueV = tonumber(valueV) or minV
  if valueV < minV then valueV = minV end
  if valueV > maxV then valueV = maxV end
  slider:SetValue(valueV)
  setValueText(math.floor(valueV + 0.5))

  wrap._slider = slider
  return wrap
end

local function _makeLabeledInput(parent, label, textValue, onChanged)
  local wrap = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  wrap:SetHeight(52)
  wrap:SetWidth(360)
  _skinFrame(wrap, "pane")
  _hookAccentBorder(wrap)

  local lab = wrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  lab:SetPoint("TOPLEFT", wrap, "TOPLEFT", 8, -6)
  lab:SetText(label or "")
  _applyFontSafe(lab, math.max(12, (W.fontSize or 14)), "OUTLINE")
  _colorText(lab)
  wrap._label = lab

  local edit = CreateFrame("EditBox", nil, wrap, "InputBoxTemplate")
  edit:SetAutoFocus(false)
  edit:SetSize(120, 18)
  edit:SetPoint("TOPLEFT", lab, "BOTTOMLEFT", -4, -6)
  edit:SetText(tostring(textValue or ""))
  edit:SetCursorPosition(0)

  edit:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)
  edit:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  edit:SetScript("OnEditFocusLost", function(self)
    if type(onChanged) == "function" then
      onChanged(self:GetText())
    end
  end)

  -- Optional: live update helper (caller can set wrap._onTextChanged)
  edit:SetScript("OnTextChanged", function(self)
    local p = self:GetParent()
    if p and type(p._onTextChanged) == "function" then
      p._onTextChanged(p, self:GetText())
    end
  end)


  wrap._edit = edit
  return wrap
end

local function _makeCheckbox(parent, label, checked, onChanged)

  local wrap = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  wrap:SetHeight(26)
  wrap:SetWidth(360)
  _skinFrame(wrap, "pane")
  _hookAccentBorder(wrap)

  local cb = CreateFrame("CheckButton", nil, wrap, "UICheckButtonTemplate")
  cb:SetPoint("LEFT", wrap, "LEFT", 6, 0)
  cb:SetSize(18, 18)
  cb:SetChecked(checked and true or false)

  local txt = wrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  txt:SetPoint("LEFT", cb, "RIGHT", 6, 0)
  txt:SetText(label or "")
  _applyFontSafe(txt, math.max(12, (W.fontSize or 14)), "OUTLINE")
  _colorText(txt)

  cb:SetScript("OnClick", function()
    local v = cb:GetChecked() and true or false
    if type(onChanged) == "function" then
      onChanged(v)
    end
  end)

  wrap._cb = cb
  wrap._text = txt
  return wrap
end
-- === BLOCK: MemDebugWindow - Skin + Native Widgets Ends ===

local function _ensureFrame()
  if W.frame then return W.frame end


  local f = CreateFrame("Frame", "PleeBUG_MemDebugWindow", UIParent, "BackdropTemplate")
  f:SetSize(720, 520)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:SetResizable(true)

  if f.SetResizeBounds then
    f:SetResizeBounds(520, 360, 1400, 1000)
  else
    if f.SetMinResize then f:SetMinResize(520, 360) end
    if f.SetMaxResize then f:SetMaxResize(1400, 1000) end
  end


  local resize = CreateFrame("Button", nil, f)
  resize:SetSize(18, 18)
  resize:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  resize:EnableMouse(true)
  resize:SetScript("OnMouseDown", function()
    f:StartSizing("BOTTOMRIGHT")
  end)
  resize:SetScript("OnMouseUp", function()
    f:StopMovingOrSizing()
  end)

  resize.tex = resize:CreateTexture(nil, "OVERLAY")
  resize.tex:SetAllPoints()
  resize.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

  if f:GetName() then
    table.insert(UISpecialFrames, f:GetName())
  end

  _skinFrame(f, "window")


  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
  title:SetText("PleeBUG Debug")
  _applyFontSafe(title, W.titleFontSize or 18, "OUTLINE")
  _colorText(title)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

  -- Settings window (separate frame, toggled by "Settings" button)
  local sf = CreateFrame("Frame", "PleeBUG_MemDebugSettingsWindow", UIParent, "BackdropTemplate")
  sf:SetSize(380, 520)
  sf:SetPoint("TOPRIGHT", f, "TOPLEFT", -8, 0)
  sf:SetClampedToScreen(true)
  sf:SetMovable(true)
  sf:EnableMouse(true)
  sf:RegisterForDrag("LeftButton")
  sf:SetScript("OnDragStart", function(self) self:StartMoving() end)
  sf:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

  _skinFrame(sf, "window")

  local sTitle = sf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sTitle:SetPoint("TOPLEFT", sf, "TOPLEFT", 12, -10)
  sTitle:SetText("PleeBUG Settings")
  _applyFontSafe(sTitle, W.titleFontSize or 18, "OUTLINE")
  _colorText(sTitle)

  local sClose = CreateFrame("Button", nil, sf, "UIPanelCloseButton")
  sClose:SetPoint("TOPRIGHT", sf, "TOPRIGHT", -4, -4)
  sClose:SetScript("OnClick", function() sf:Hide() end)

  sf:Hide()
  f._settingsFrame = sf

  -- If the main window closes (close button, ESC, Hide(), etc),
  -- force-close the settings window too.
  f:HookScript("OnHide", function(self)
    local sff = self and self._settingsFrame
    if sff and sff.IsShown and sff:IsShown() then
      sff:Hide()
    end
  end)


  function W:ToggleSettings()
    local ff = _ensureFrame()
    local sff = ff and ff._settingsFrame
    if not sff then return end
    if sff:IsShown() then
      sff:Hide()
    else
      sff:Show()
    end
  end

  -- Controls
  local startBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  startBtn:SetSize(90, 22)
  startBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -38)
  startBtn:SetText("Start")
  startBtn:SetScript("OnClick", function()
    MemDebug:SetEnabled(true)

    -- Timeline behavior: start fill-left-to-right and unfreeze
    W._timelineStartTime = _nowPrecise()
    W._timelineFreezeNow = nil

    W:_TracePush("UI.MemDebug.Start")
    W:Refresh()
  end)



  local stopBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  stopBtn:SetSize(90, 22)
  stopBtn:SetPoint("LEFT", startBtn, "RIGHT", 8, 0)
  stopBtn:SetText("Stop")
  stopBtn:SetScript("OnClick", function()
    MemDebug:SetEnabled(false)

    -- Timeline behavior: freeze the diagram so it stops sliding
    W._timelineFreezeNow = _nowPrecise()

    W:Refresh()
  end)


  local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  clearBtn:SetSize(90, 22)
  clearBtn:SetPoint("LEFT", stopBtn, "RIGHT", 8, 0)
  clearBtn:SetText("Clear")
  clearBtn:SetScript("OnClick", function()
    MemDebug:Clear()
    W.lastSnapshot = {}
    W:_TraceClear()

    -- Timeline behavior: reset start/freeze state
    W._timelineStartTime = nil
    W._timelineFreezeNow = nil

    W:Refresh()
  end)


  -- UI-only reset (does NOT clear counters/trace; just rebuilds window state)
  local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  resetBtn:SetSize(90, 22)
  resetBtn:SetPoint("LEFT", clearBtn, "RIGHT", 8, 0)
  resetBtn:SetText("Reset UI")
  resetBtn:SetScript("OnClick", function()
    -- Force a rebuild of the flattened tree + immediate re-render
    W._flatBuiltFor = nil
    W._flat = {}
    W._buildInProgress = false
    W._buildIterKey = nil
    W._buildRoot = nil

    if W.frame and W.frame._statusText then
      W.frame._statusText:SetText("Status: Resetting UI...")
    end

    W:Refresh()
  end)


  local snapBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  snapBtn:SetSize(110, 22)
  snapBtn:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)
  snapBtn:SetText("Snapshot Now")
  snapBtn:SetScript("OnClick", function()
    MemDebug:SnapshotAndReset()
    W:Refresh()
  end)


  local settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  settingsBtn:SetSize(110, 22)
  settingsBtn:SetPoint("LEFT", snapBtn, "RIGHT", 8, 0)
  settingsBtn:SetText("Settings")
  settingsBtn:SetScript("OnClick", function()
    if W and W.ToggleSettings then
      W:ToggleSettings()
    end
  end)

  -- Built-in skin (square, 1px border, dark bg, accent hover)
  _skinButton(startBtn)
  _skinButton(stopBtn)
  _skinButton(clearBtn)
  _skinButton(resetBtn)
  _skinButton(snapBtn)
  _skinButton(settingsBtn)



  for _, b in ipairs({ startBtn, stopBtn, clearBtn, resetBtn, snapBtn, settingsBtn }) do

    if b then
      b:EnableMouse(true)
      local bg = b._bg or b._backdrop or b._back
      if bg and bg.EnableMouse then
        bg:EnableMouse(false)
      end
    end
  end



  -- Interval slider (native)
  local sf = f._settingsFrame

  local intervalSlider = _makeLabeledSlider(
    sf,
    "Window (sec)",
    5, 60, 1,
    (MemDebug.GetInterval and MemDebug:GetInterval()) or 10,
    function(val)
      if MemDebug and MemDebug.SetInterval then
        MemDebug:SetInterval(val)
      end
      W.traceWindow = (MemDebug.GetInterval and MemDebug:GetInterval()) or val
      W:Refresh()
    end
  )
  intervalSlider:ClearAllPoints()
  intervalSlider:SetPoint("TOPLEFT", sf, "TOPLEFT", 12, -38)
  intervalSlider:SetWidth(356)
  intervalSlider:Show()
  f._intervalSlider = intervalSlider



  -- Font size slider (native)
  local fontSlider = _makeLabeledSlider(
    sf,
    "Font Size",
    10, 22, 1,
    (MemDebug.GetFontSize and MemDebug:GetFontSize()) or (W.fontSize or 14),
    function(val)
      val = tonumber(val) or 14
      val = math.floor(val + 0.5)
      if val < 10 then val = 10 end
      if val > 22 then val = 22 end

      W.fontSize = val
      W.rowHeight = math.max(18, math.floor((val * (W.uiScale or 1)) + 0.5) + 10)

      if MemDebug and MemDebug.SetFontSize then
        MemDebug:SetFontSize(val)
      end

      W:Refresh()
    end
  )
  fontSlider:ClearAllPoints()
  fontSlider:SetPoint("TOPLEFT", intervalSlider, "BOTTOMLEFT", 0, -10)
  fontSlider:SetWidth(356)
  fontSlider:Show()
  f._fontSlider = fontSlider



  -- Timeline window is synced to Interval (no separate slider)
  f._traceWindowSlider = nil

  -- Render style checkbox (native)
  local sf = f._settingsFrame or f

local styleBox = _makeCheckbox(
    sf,
    "Dots (instead of ticks)",
    ((MemDebug and MemDebug.GetTraceStyle and MemDebug:GetTraceStyle()) or (W.traceStyle or "tick")) == "dot",
    function(val)
      local style = (val and "dot") or "tick"
      if MemDebug and MemDebug.SetTraceStyle then
        MemDebug:SetTraceStyle(style)
      end
      W.traceStyle = style
      W:Refresh()
    end
  )

  styleBox:ClearAllPoints()
  if fontSlider then
    styleBox:SetPoint("TOPLEFT", fontSlider, "BOTTOMLEFT", 0, -6)
  elseif intervalSlider then
    styleBox:SetPoint("TOPLEFT", intervalSlider, "BOTTOMLEFT", 0, -6)
  else
    styleBox:SetPoint("TOPLEFT", startBtn, "BOTTOMLEFT", 0, -10)
  end
  styleBox:Show()

  -- CPU controls (global)
  local cpu = MemDebug and MemDebug.CPU

  local cpuEnableBox = _makeCheckbox(
    sf,
    "Enable CPU logging",
    cpu and cpu.Enabled and cpu:Enabled() or false,
    function(val)
      if MemDebug and MemDebug.CPU and MemDebug.CPU.SetEnabled then
        MemDebug.CPU:SetEnabled(val)
      end
    end
  )
  cpuEnableBox:ClearAllPoints()
  cpuEnableBox:SetPoint("TOPLEFT", styleBox, "BOTTOMLEFT", 0, -6)
  cpuEnableBox:Show()
  f._cpuEnableBox = cpuEnableBox


  local cpuRefBox = _makeCheckbox(
    sf,
    "Add reference line",
    cpu and cpu.RefLineEnabled and cpu:RefLineEnabled() or false,
    function(val)
      if MemDebug and MemDebug.CPU and MemDebug.CPU.SetRefLineEnabled then
        MemDebug.CPU:SetRefLineEnabled(val)
      end
      if W and W.Refresh then
        W:Refresh()
      end
    end
  )
  cpuRefBox:ClearAllPoints()
  cpuRefBox:SetPoint("TOPLEFT", cpuEnableBox, "BOTTOMLEFT", 0, -6)
  cpuRefBox:Show()
  f._cpuRefBox = cpuRefBox

  local cpuFpsInput = _makeLabeledInput(
    sf,
    "Input average or target FPS",
    cpu and cpu.GetRefFps and cpu:GetRefFps() or 60,
    function(txt)
      if MemDebug and MemDebug.CPU and MemDebug.CPU.SetRefFps then
        MemDebug.CPU:SetRefFps(tonumber(txt))
      end
      if W and W.Refresh then
        W:Refresh()
      end
    end
  )
  cpuFpsInput:ClearAllPoints()
  cpuFpsInput:SetPoint("TOPLEFT", cpuRefBox, "BOTTOMLEFT", 18, -6) -- indent under checkbox
  cpuFpsInput:Show()
  f._cpuFpsInput = cpuFpsInput

  -- Show the derived frame budget (ms) next to the FPS input
  local cpuBudgetText = cpuFpsInput:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  cpuBudgetText:SetPoint("LEFT", cpuFpsInput._edit, "RIGHT", 10, 0)
  cpuBudgetText:SetJustifyH("LEFT")
  _applyFontSafe(cpuBudgetText, math.max(12, (W.fontSize or 14)), "OUTLINE")
  _colorText(cpuBudgetText)
  f._cpuBudgetText = cpuBudgetText

  local function _UpdateCpuBudgetText(txt)
    local fps = tonumber(txt)

    if not fps then
      if cpuFpsInput and cpuFpsInput._edit and cpuFpsInput._edit.GetText then
        fps = tonumber(cpuFpsInput._edit:GetText())
      end
    end

    if not fps then
      fps = (cpu and cpu.GetRefFps and cpu:GetRefFps()) or 60
    end

    fps = tonumber(fps) or 60
    if fps < 1 then fps = 1 end
    if fps > 1000 then fps = 1000 end

    local ms = 1000 / fps
    cpuBudgetText:SetText(string.format("%.2f ms", ms))
  end

  -- live update while typing
  cpuFpsInput._onTextChanged = function(_, txt)
    _UpdateCpuBudgetText(txt)
  end

  _UpdateCpuBudgetText()


  local cpuRefExplain = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

  cpuRefExplain:SetPoint("TOPLEFT", cpuFpsInput, "BOTTOMLEFT", 18, -6) -- indent under checkbox
  cpuRefExplain:SetWidth(330)
  cpuRefExplain:SetJustifyH("LEFT")
  cpuRefExplain:SetJustifyV("TOP")
  cpuRefExplain:SetText(
    "This calculates the CPU frame budget. This is how much time the CPU has to calculate every frame. " ..
    "Any CPU spikes closing in on this is cause for concern and stutter."
  )
  _applyFontSafe(cpuRefExplain, math.max(11, (W.fontSize or 14) - 2), "OUTLINE")
  _colorText(cpuRefExplain)
  cpuRefExplain:SetHeight(46) -- FIX: reserve space so Modules panel never overlaps
  f._cpuRefExplain = cpuRefExplain


  -- Initial enabled/disabled state
  do
    local enabled = cpu and cpu.RefLineEnabled and cpu:RefLineEnabled() or false
    if cpuFpsInput and cpuFpsInput._edit then
      cpuFpsInput._edit:EnableMouse(enabled)
      cpuFpsInput._edit:SetEnabled(enabled)
    end
    cpuFpsInput:SetAlpha(enabled and 1 or 0.45)
    cpuRefExplain:SetAlpha(enabled and 1 or 0.45)
  end

  -- Keep the input state in sync with the checkbox
  do
    local oldOnClick = cpuRefBox._cb and cpuRefBox._cb:GetScript("OnClick")
    if cpuRefBox._cb then
      cpuRefBox._cb:SetScript("OnClick", function(self)
        if oldOnClick then oldOnClick(self) end
        local enabled = self:GetChecked() and true or false
        if cpuFpsInput and cpuFpsInput._edit then
          cpuFpsInput._edit:EnableMouse(enabled)
          cpuFpsInput._edit:SetEnabled(enabled)
        end
        cpuFpsInput:SetAlpha(enabled and 1 or 0.45)
        cpuRefExplain:SetAlpha(enabled and 1 or 0.45)
        if f and f._cpuBudgetText then
          f._cpuBudgetText:SetAlpha(enabled and 1 or 0.45)
        end
      end)
    end
  end


  f._traceStyleBox = styleBox

  -- Modules panel (auto-populated from MemDebug:Attach registrations)
  do
local panel = CreateFrame("Frame", nil, sf, "BackdropTemplate")
    panel:SetSize(0, 0)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", f._cpuRefExplain or cpuEnableBox, "BOTTOMLEFT", 0, -12)
    panel:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", -12, 12)
    f._modulesPanel = panel


    panel:SetBackdrop({
      bgFile   = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = 1,
      insets   = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    panel:SetBackdropColor(0, 0, 0, 0.25)
    panel:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.9)


    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    title:SetText("Modules")
    _applyFontSafe(title, math.max(12, (W.fontSize or 14)), "OUTLINE")
    _colorText(title)
    panel._title = title

    local enableAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    enableAll:SetSize(80, 18)
    enableAll:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    enableAll:SetText("Enable All")
    enableAll:SetScript("OnClick", function()
      if MemDebug and MemDebug.EnableAllModules then
        MemDebug:EnableAllModules()
      end
      if W and W.Refresh then
        W:Refresh()
      end
    end)

    local disableAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    disableAll:SetSize(80, 18)
    disableAll:SetPoint("LEFT", enableAll, "RIGHT", 6, 0)
    disableAll:SetText("Disable All")
    disableAll:SetScript("OnClick", function()
      if MemDebug and MemDebug.DisableAllModules then
        MemDebug:DisableAllModules()
      end
      if W and W.Refresh then
        W:Refresh()
      end
    end)

    _skinButton(enableAll)
    _skinButton(disableAll)


    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", enableAll, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 0)



    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    panel._scroll = scroll
    panel._content = content
    panel._checks = panel._checks or {}
  end

  local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")

  status:SetPoint("TOPLEFT", startBtn, "BOTTOMLEFT", 0, -10)

  status:SetText("No data yet - press Snapshot Now or Start.")
    f._statusText = status
  _applyFontSafe(status, W.fontSize or 14, nil)
  _colorText(status)
  -- Body: LIST only (timeline is its own window)
  local listHolder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  listHolder:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -10)
  listHolder:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 14)
  f._listHolder = listHolder

  listHolder:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 6, right = 6, top = 6, bottom = 6 },
  })
  listHolder:SetBackdropColor(0, 0, 0, 0.18)
  listHolder:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.9)





  -- Keep top controls above scroll region and any shell art.
  local base = f:GetFrameLevel() or 0
  for _, r in ipairs({ startBtn, stopBtn, clearBtn, resetBtn, snapBtn }) do
    if r and r.SetFrameLevel then
      r:SetFrameLevel(base + 30)
    end
  end

  if intervalSlider and intervalSlider.SetFrameLevel then
    intervalSlider:SetFrameLevel(base + 30)
  end
  if fontSlider and fontSlider.SetFrameLevel then
    fontSlider:SetFrameLevel(base + 30)
  end

  if status and status.SetFrameLevel then
    status:SetFrameLevel(base + 30)
  end


  -- Scroll area (LIST pane)
  local scroll = CreateFrame("ScrollFrame", nil, f._listHolder, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", f._listHolder, "TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", f._listHolder, "BOTTOMRIGHT", -32, 0)


  local content = CreateFrame("Frame", nil, scroll)

  -- IMPORTANT:
  -- If content is left at width 1, your row buttons become ~1px clickable even though text renders wider.
  -- Anchor content to the scroll frame so rows get a real width/hitbox.
  content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
  content:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", -26, 0) -- leave space for the scrollbar
  content:SetSize(1, 1) -- height is driven by Refresh; width is driven by anchors above
  scroll:SetScrollChild(content)

  -- Keep width stable if the window is resized
  scroll:SetScript("OnSizeChanged", function(self, w, h)
    if content and content.SetWidth then
      local sbw = 26
      if self.ScrollBar and self.ScrollBar.GetWidth then
        sbw = math.floor(self.ScrollBar:GetWidth() + 0.5) + 4
      end
      content:SetWidth((w or 1) - sbw)
    end
  end)


  f._scroll = scroll
  f._content = content

  W.frame = f
  f:Hide()
  return f
end

local function _ensureTimelineFrame()

  if W.timelineFrame then return W.timelineFrame end

  local tf = CreateFrame("Frame", "PleeBUG_MemDebugTimeline", UIParent, "BackdropTemplate")
  tf:SetSize(900, 420)
  tf:SetPoint("CENTER", UIParent, "CENTER", 0, -260)
  tf:SetClampedToScreen(true)
  tf:SetMovable(true)
  tf:EnableMouse(true)
  tf:RegisterForDrag("LeftButton")
  tf:SetScript("OnDragStart", function(self) self:StartMoving() end)
  tf:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

  tf:SetResizable(true)
  if tf.SetResizeBounds then
    tf:SetResizeBounds(520, 260, 1800, 1000)
  else
    if tf.SetMinResize then tf:SetMinResize(520, 260) end
    if tf.SetMaxResize then tf:SetMaxResize(1800, 1000) end
  end

  if tf:GetName() then
    table.insert(UISpecialFrames, tf:GetName())
  end

  _skinFrame(tf, "window")

  local title = tf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", tf, "TOPLEFT", 12, -10)
  title:SetText("PleeBUG Timeline")
  _applyFontSafe(title, W.titleFontSize or 18, "OUTLINE")
  _colorText(title)

  local close = CreateFrame("Button", nil, tf, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", tf, "TOPRIGHT", -4, -4)
  close:SetScript("OnClick", function()
    tf:Hide()
  end)

  -- One shared zoom slider for BOTH timelines
  local zoomSlider = _makeLabeledSlider(
    tf,
    "Zoom",
    1, 10, 1,
    tonumber(W.timelineZoom) or 1,
    function(val)
      val = tonumber(val) or 3
      val = math.floor(val + 0.5)
      if val < 1 then val = 1 end
      if val > 10 then val = 10 end
      W.timelineZoom = val
      if tf._updateSizes then
        tf._updateSizes()
      end
      if W and W.Refresh then
        W:Refresh()
      end
    end
  )
  zoomSlider:ClearAllPoints()
  zoomSlider:SetPoint("TOPLEFT", tf, "TOPLEFT", 12, -34)
  zoomSlider:SetWidth(360)
  zoomSlider:Show()
  tf._zoomSlider = zoomSlider

  local resize = CreateFrame("Button", nil, tf)
  resize:SetSize(18, 18)
  resize:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -2, 2)
  resize:EnableMouse(true)
  resize:SetScript("OnMouseDown", function()
    tf:StartSizing("BOTTOMRIGHT")
  end)
  resize:SetScript("OnMouseUp", function()
    tf:StopMovingOrSizing()
  end)
  resize.tex = resize:CreateTexture(nil, "OVERLAY")
  resize.tex:SetAllPoints()
  resize.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

  -- -------------------------------------------------------------------
  -- Series panel (right side): toggle + color per tracked key (shared)
  -- -------------------------------------------------------------------
  local panelW = 232
  local panel = CreateFrame("Frame", nil, tf)
  panel:SetPoint("TOPRIGHT", tf, "TOPRIGHT", -12, -34)
  panel:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -12, 34)
  panel:SetWidth(panelW)
  tf._seriesPanel = panel

  panel.bg = panel:CreateTexture(nil, "BACKGROUND")
  panel.bg:SetAllPoints()
  panel.bg:SetColorTexture(0, 0, 0, 0.35)

  panel.border = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  panel.border:SetAllPoints()
  panel.border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
  })
  panel.border:SetBackdropBorderColor(0.20, 0.20, 0.20, 0.65)

  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
  panel.title:SetText("Tracked Keys")
  _colorText(panel.title)

  panel.resetAllBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.resetAllBtn:SetSize(80, 18)
  panel.resetAllBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -5)
  panel.resetAllBtn:SetText("Reset All")
  panel.resetAllBtn:SetScript("OnClick", function()
    if MemDebug and MemDebug.ResetAllSeriesStyles then
      MemDebug:ResetAllSeriesStyles()
    end
    if W and W.Refresh then W:Refresh() end
  end)
  _skinButton(panel.resetAllBtn)

  panel.scroll = CreateFrame("ScrollFrame", nil, panel, "FauxScrollFrameTemplate")
  panel.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -24)
  panel.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 8)

  panel.rows = panel.rows or {}
  panel.keys = panel.keys or {}

  local function _SeriesPanel_GetKeys(out)
    out = out or {}
    _wipe(out)

    local function _isRelevantKey(k)
      if type(k) ~= "string" or k == "" then return false end
      if k:sub(1, 5) == "CPU." then return true end
      if k:sub(1, 5) == "Funcs" then return true end
      if k:sub(1, 6) == "Events" then return true end
      return false
    end

    -- Build a "wanted" set from:
    -- 1) visible tree lanes (main list)
    -- 2) active CPU events in the current window
    local want = {}

    local flat = W._flat or {}
    for i = 1, #flat do
      local node = flat[i] and flat[i].node
      local k = node and node.path
      local isLeaf = node and (not node.children or not next(node.children))
      if isLeaf and _isRelevantKey(k) then
        want[k] = true
        if MemDebug and MemDebug._TouchSeries then
          MemDebug:_TouchSeries(k)
        end
      end
    end


    local cpu = MemDebug and MemDebug.CPU
    if cpu and cpu.GetRecentEvents and MemDebug and MemDebug.GetInterval then
      local win = tonumber(MemDebug:GetInterval()) or 10
      local nowT = (GetTimePreciseSec and GetTimePreciseSec()) or (GetTime and GetTime()) or 0
      local ev = cpu:GetRecentEvents(win, nowT)
      if type(ev) == "table" then
        for i = 1, #ev do
          local k = ev[i] and ev[i].key
          if _isRelevantKey(k) then
            want[k] = true
            if MemDebug and MemDebug._TouchSeries then
              MemDebug:_TouchSeries(k)
            end
          end
        end
      end
    end

    -- Include keys:
    -- - all wanted (active/relevant)
    -- - plus any DISABLED keys that are relevant (so you can re-enable them)
    local db = MemDebug and MemDebug.GetDB and MemDebug:GetDB()
    local series = db and db.series

    if type(series) == "table" then
      for k, s in pairs(series) do
        if _isRelevantKey(k) then
          if want[k] or (type(s) == "table" and s.enabled == false) then
            out[#out + 1] = k
          end
        end
      end
    end

    -- Ensure all wanted keys are included even if not present in DB yet
    for k in pairs(want) do
      out[#out + 1] = k
    end

    table.sort(out)

    -- de-dupe
    local j = 0
    local last = nil
    for i = 1, #out do
      local v = out[i]
      if v ~= last then
        j = j + 1
        out[j] = v
        last = v
      end
    end
    for i = j + 1, #out do out[i] = nil end
    return out
  end


  local function _SeriesPanel_OnPickColor(key)
    if not (ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow) then return end
    if not (MemDebug and MemDebug.GetSeriesStyle) then return end

    local s = MemDebug:GetSeriesStyle(key)
    if not s then return end

    local function _commit()
      local r, g, b = ColorPickerFrame:GetColorRGB()
      if MemDebug and MemDebug.SetSeriesColor then
        MemDebug:SetSeriesColor(key, r, g, b)
      end
      if W and W.Refresh then W:Refresh() end
    end

    local info = {
      r = s.r or 1,
      g = s.g or 1,
      b = s.b or 1,
      swatchFunc = _commit,
      cancelFunc = _commit,
      hasOpacity = false,
    }

    ColorPickerFrame:SetupColorPickerAndShow(info)
  end

  local function _SeriesPanel_EnsureRow(i)
    local row = panel.rows[i]
    if row then return row end

    row = CreateFrame("Frame", nil, panel)
    panel.rows[i] = row
    row:SetHeight(18)

    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.check:SetSize(18, 18)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.label:SetPoint("LEFT", row.check, "RIGHT", 2, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", -46, 0) -- leave room for reset + color
    row.label:SetJustifyH("LEFT")
    row.label:SetText("")

    row.colorBtn = CreateFrame("Button", nil, row)
    row.colorBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.colorBtn:SetSize(14, 14)
    row.colorTex = row.colorBtn:CreateTexture(nil, "ARTWORK")
    row.colorTex:SetAllPoints()
    row.colorTex:SetColorTexture(1, 1, 1, 1)

    row.colorBorder = row.colorBtn:CreateTexture(nil, "OVERLAY")
    row.colorBorder:SetAllPoints()
    row.colorBorder:SetColorTexture(0, 0, 0, 0.85)

    row.resetBtn = CreateFrame("Button", nil, row)
    row.resetBtn:SetPoint("RIGHT", row.colorBtn, "LEFT", -4, 0)
    row.resetBtn:SetSize(14, 14)
    row.resetTex = row.resetBtn:CreateTexture(nil, "ARTWORK")
    row.resetTex:SetAllPoints()
    row.resetTex:SetColorTexture(1, 0.25, 0.25, 0.85)

    row.resetBorder = row.resetBtn:CreateTexture(nil, "OVERLAY")
    row.resetBorder:SetAllPoints()
    row.resetBorder:SetColorTexture(0, 0, 0, 0.85)

    return row
  end

  local function _SeriesPanel_Update()
    if not (MemDebug and MemDebug.GetSeriesStyle) then return end

    local keys = _SeriesPanel_GetKeys(panel.keys)
    local numKeys = #keys

    local rowH = 18
    local visible = math.floor(((panel.scroll:GetHeight() or 0) / rowH) + 0.5)
    if visible < 1 then visible = 1 end
    if visible > 60 then visible = 60 end

    FauxScrollFrame_Update(panel.scroll, numKeys, visible, rowH)

    local offset = FauxScrollFrame_GetOffset(panel.scroll) or 0
    for i = 1, visible do
      local idx = offset + i
      local row = _SeriesPanel_EnsureRow(i)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", panel.scroll, "TOPLEFT", 0, -((i - 1) * rowH))
      row:SetPoint("TOPRIGHT", panel.scroll, "TOPRIGHT", 0, -((i - 1) * rowH))


      local key = keys[idx]
      if key then
        row:Show()

        local s = MemDebug:GetSeriesStyle(key)
        local enabled = (not s) or (s.enabled ~= false)

        row.check:SetChecked(enabled)
        row.label:SetText(key)

        local r, g, b = (s and s.r) or 1, (s and s.g) or 1, (s and s.b) or 1
        row.colorTex:SetColorTexture(r, g, b, 1)

        row.check:SetScript("OnClick", function(btn)
          if MemDebug and MemDebug.SetSeriesEnabled then
            MemDebug:SetSeriesEnabled(key, btn:GetChecked() == true)
          end
          if W and W.Refresh then W:Refresh() end
        end)

        row.colorBtn:SetScript("OnClick", function()
          _SeriesPanel_OnPickColor(key)
        end)

        if row.resetBtn then
          row.resetBtn:Show()
          row.resetBtn:SetScript("OnClick", function()
            if MemDebug and MemDebug.ResetSeriesKey then
              MemDebug:ResetSeriesKey(key)
            end
            if W and W.Refresh then W:Refresh() end
          end)
        end


      else
        row:Hide()
      end
    end

    -- Hide any leftover rows from previous larger visible counts
    for i = visible + 1, #panel.rows do
      if panel.rows[i] then
        panel.rows[i]:Hide()
      end
    end
  end

  panel.scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, 18, _SeriesPanel_Update)
  end)


  panel.Update = _SeriesPanel_Update
  panel:Show()

  -- -------------------------------------------------------------------
  -- Two stacked scroll+diagram regions (Funcs timeline + CPU timeline)
  -- Shared bottom scrollbar + shared zoom
  -- -------------------------------------------------------------------
  local leftPad = 12
  local rightPad = 12 + panelW + 8 -- 12 outer + panel width + gutter
  local bottomPad = 34
  local topGap = 10
  local splitGap = 8

  local fnWrap = CreateFrame("Frame", nil, tf)
  tf._fnWrap = fnWrap

  local cpuWrap = CreateFrame("Frame", nil, tf)
  tf._cpuWrap = cpuWrap

  -- Small pane titles (always visible, independent of Diagram renderer)
  fnWrap._title = fnWrap._title or fnWrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fnWrap._title:ClearAllPoints()
  fnWrap._title:SetPoint("TOPLEFT", fnWrap, "TOPLEFT", 6, -4)
  fnWrap._title:SetText("Event calls")
  _applyFontSafe(fnWrap._title, math.max(11, (W.fontSize or 14) - 3), "OUTLINE")
  _colorText(fnWrap._title)

  cpuWrap._title = cpuWrap._title or cpuWrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  cpuWrap._title:ClearAllPoints()
  cpuWrap._title:SetPoint("TOPLEFT", cpuWrap, "TOPLEFT", 6, -4)
  cpuWrap._title:SetText("CPU (ms)")
  _applyFontSafe(cpuWrap._title, math.max(11, (W.fontSize or 14) - 3), "OUTLINE")
  _colorText(cpuWrap._title)


  -- Initial anchors; exact heights/positions are set in _updateSizes()
  cpuWrap:ClearAllPoints()
  cpuWrap:SetPoint("BOTTOMLEFT", tf, "BOTTOMLEFT", leftPad, bottomPad)
  cpuWrap:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -rightPad, bottomPad)
  cpuWrap:SetHeight(120)

  fnWrap:ClearAllPoints()
  fnWrap:SetPoint("TOPLEFT", tf._zoomSlider, "BOTTOMLEFT", 0, -topGap)
  fnWrap:SetPoint("TOPRIGHT", tf, "TOPRIGHT", -rightPad, -(34 + topGap))
  fnWrap:SetPoint("BOTTOMLEFT", cpuWrap, "TOPLEFT", 0, splitGap)
  fnWrap:SetPoint("BOTTOMRIGHT", cpuWrap, "TOPRIGHT", 0, splitGap)


  -- Funcs scroll/child/diagram
  local scrollFn = CreateFrame("ScrollFrame", nil, fnWrap)
  scrollFn:SetPoint("TOPLEFT", fnWrap, "TOPLEFT", 0, 0)
  scrollFn:SetPoint("BOTTOMRIGHT", fnWrap, "BOTTOMRIGHT", 0, 0)
  scrollFn:EnableMouseWheel(true)

  local childFn = CreateFrame("Frame", nil, scrollFn)
  childFn:ClearAllPoints()
  childFn:SetPoint("TOPLEFT", scrollFn, "TOPLEFT", 0, 0)
  childFn:SetPoint("BOTTOMLEFT", scrollFn, "BOTTOMLEFT", 0, 0)
  childFn:SetWidth(scrollFn:GetWidth() or 1)
  scrollFn:SetScrollChild(childFn)

  local diagramFn = CreateFrame("Frame", nil, childFn)
  diagramFn:ClearAllPoints()
  diagramFn:SetAllPoints(childFn)

  tf._scrollFn = scrollFn
  tf._childFn = childFn
  tf._diagramFn = diagramFn

  -- CPU scroll/child/diagram
  local scrollCpu = CreateFrame("ScrollFrame", nil, cpuWrap)
  scrollCpu:SetPoint("TOPLEFT", cpuWrap, "TOPLEFT", 0, 0)
  scrollCpu:SetPoint("BOTTOMRIGHT", cpuWrap, "BOTTOMRIGHT", 0, 0)
  scrollCpu:EnableMouseWheel(true)

  local childCpu = CreateFrame("Frame", nil, scrollCpu)
  childCpu:ClearAllPoints()
  childCpu:SetPoint("TOPLEFT", scrollCpu, "TOPLEFT", 0, 0)
  childCpu:SetPoint("BOTTOMLEFT", scrollCpu, "BOTTOMLEFT", 0, 0)
  childCpu:SetWidth(scrollCpu:GetWidth() or 1)
  scrollCpu:SetScrollChild(childCpu)

  local diagramCpu = CreateFrame("Frame", nil, childCpu)
  diagramCpu:ClearAllPoints()
  diagramCpu:SetAllPoints(childCpu)

  tf._scrollCpu = scrollCpu
  tf._childCpu = childCpu
  tf._diagramCpu = diagramCpu

  -- Tell the diagram renderer what each pane represents (titles)
  if tf._diagramFn then
    tf._diagramFn.__pleebugTitleText = "Event calls"
  end
  if tf._diagramCpu then
    tf._diagramCpu.__pleebugTitleText = "CPU (ms)"
  end


  -- Shared bottom horizontal scrollbar (drives BOTH scrollframes)
  local hbar = CreateFrame("Slider", nil, tf)
  hbar:SetOrientation("HORIZONTAL")
  hbar:SetPoint("BOTTOMLEFT", tf, "BOTTOMLEFT", 12, 12)
  hbar:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -12, 12)
  hbar:SetHeight(14)
  hbar:SetMinMaxValues(0, 0)
  hbar:SetValue(0)
  hbar:SetValueStep(1)
  if hbar.SetObeyStepOnDrag then
    hbar:SetObeyStepOnDrag(true)
  end
  hbar:EnableMouse(true)

  local bg = hbar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.25)

  hbar:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  local thumb = hbar:GetThumbTexture()
  if thumb then
    thumb:SetSize(16, 16)
  end

  hbar:SetScript("OnValueChanged", function(self, value)
    value = value or 0
    if scrollFn and scrollFn.SetHorizontalScroll then
      scrollFn:SetHorizontalScroll(value)
    end
    if scrollCpu and scrollCpu.SetHorizontalScroll then
      scrollCpu:SetHorizontalScroll(value)
    end
  end)

  tf._hScroll = hbar

  W.timelineZoom = W.timelineZoom or 1

  local function _syncHScrollBar()
    local max1 = 0
    local max2 = 0
    if childFn and scrollFn then
      max1 = math.max(0, (childFn:GetWidth() or 1) - (scrollFn:GetWidth() or 1))
    end
    if childCpu and scrollCpu then
      max2 = math.max(0, (childCpu:GetWidth() or 1) - (scrollCpu:GetWidth() or 1))
    end
    local maxScroll = math.max(max1, max2)

    if tf._hScroll then
      tf._hScroll:SetMinMaxValues(0, maxScroll)
      local cur = 0
      if scrollFn and scrollFn.GetHorizontalScroll then
        cur = scrollFn:GetHorizontalScroll() or 0
      end
      if cur > maxScroll then cur = maxScroll end
      if cur < 0 then cur = 0 end
      tf._hScroll:SetValue(cur)
      tf._hScroll:SetShown(maxScroll > 0)
    end
  end

  local function _updateSizes()
    if not scrollFn or not childFn or not diagramFn then return end
    if not scrollCpu or not childCpu or not diagramCpu then return end

    -- Ensure wraps have real heights (prevents 0px timelines)
    if tf and tf._fnWrap and tf._cpuWrap and tf._zoomSlider then
      local top = tf._zoomSlider:GetBottom()
      local bottom = (tf:GetBottom() or 0) + bottomPad
      local avail = (top or 0) - bottom
      avail = avail - (splitGap or 8)
      if avail < 140 then avail = 140 end

      -- Give CPU ~40% height, funcs gets the rest
      local cpuH = math.floor(avail * 0.40)
      if cpuH < 60 then cpuH = 60 end
      if cpuH > (avail - 60) then cpuH = avail - 60 end

      tf._cpuWrap:ClearAllPoints()
      tf._cpuWrap:SetPoint("BOTTOMLEFT", tf, "BOTTOMLEFT", leftPad, bottomPad)
      tf._cpuWrap:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -rightPad, bottomPad)
      tf._cpuWrap:SetHeight(cpuH)

      tf._fnWrap:ClearAllPoints()
      tf._fnWrap:SetPoint("TOPLEFT", tf._zoomSlider, "BOTTOMLEFT", 0, -topGap)
      tf._fnWrap:SetPoint("TOPRIGHT", tf, "TOPRIGHT", -rightPad, -(34 + topGap))
      tf._fnWrap:SetPoint("BOTTOMLEFT", tf._cpuWrap, "TOPLEFT", 0, splitGap)
      tf._fnWrap:SetPoint("BOTTOMRIGHT", tf._cpuWrap, "TOPRIGHT", 0, splitGap)
    end

    local zoom = tonumber(W.timelineZoom) or 3
    if zoom < 1 then zoom = 1 end
    if zoom > 10 then zoom = 10 end

    -- Funcs area
    local sw1 = scrollFn:GetWidth() or 1
    local sh1 = scrollFn:GetHeight() or 1
    childFn:SetWidth(math.max(1, sw1 * zoom))
    childFn:SetHeight(math.max(1, sh1))
    diagramFn:SetSize(childFn:GetWidth(), childFn:GetHeight())

    -- CPU area
    local sw2 = scrollCpu:GetWidth() or 1
    local sh2 = scrollCpu:GetHeight() or 1
    childCpu:SetWidth(math.max(1, sw2 * zoom))
    childCpu:SetHeight(math.max(1, sh2))
    diagramCpu:SetSize(childCpu:GetWidth(), childCpu:GetHeight())

    _syncHScrollBar()
  end



  tf:SetScript("OnSizeChanged", function()
    _updateSizes()
    if W and W.Refresh then
      W:Refresh()
    end
  end)

  tf._updateSizes = _updateSizes

  _Defer(function()
    _updateSizes()
  end)

  -- Mouse wheel: horizontal scroll both (Shift = faster)
  local function _OnWheel(self, delta)
    local step = 60
    if IsShiftKeyDown and IsShiftKeyDown() then
      step = 180
    end

    local cur = self:GetHorizontalScroll() or 0
    local maxScroll = math.max(0, (self:GetScrollChild() and self:GetScrollChild():GetWidth() or 1) - (self:GetWidth() or 1))

    cur = cur - (delta * step)
    if cur < 0 then cur = 0 end
    if cur > maxScroll then cur = maxScroll end

    if scrollFn and scrollFn.SetHorizontalScroll then scrollFn:SetHorizontalScroll(cur) end
    if scrollCpu and scrollCpu.SetHorizontalScroll then scrollCpu:SetHorizontalScroll(cur) end
    if tf._hScroll then
      tf._hScroll:SetValue(cur)
    end
  end

  scrollFn:SetScript("OnMouseWheel", _OnWheel)
  scrollCpu:SetScript("OnMouseWheel", _OnWheel)

  W.timelineFrame = tf
  tf:Hide()
  return tf
end

local function _refreshModulePanel(f)
  if not f or not f._modulesPanel or not MemDebug then return end

  local panel = f._modulesPanel
  local content = panel._content
  if not content then return end

  local names = (MemDebug.GetKnownModules and MemDebug:GetKnownModules()) or {}

  panel._rows = panel._rows or {}

  -- StaticPopup for rename
  if not StaticPopupDialogs.PLEEBUG_RENAME then
    StaticPopupDialogs.PLEEBUG_RENAME =

    {
      text = "Friendly name",
      button1 = "Save",
      button2 = "Clear",
      button3 = "Cancel",
      hasEditBox = true,
      timeout = 0,
      whileDead = 1,
      hideOnEscape = 1,
      preferredIndex = 3,

      OnShow = function(self)
        local data = self.data
        local mod = data and data.module
        if not mod then return end
        local cur = (MemDebug.GetModuleAlias and MemDebug:GetModuleAlias(mod)) or ""
        self.editBox:SetText(cur)
        self.editBox:HighlightText()
      end,

      OnAccept = function(self)
        local data = self.data
        local mod = data and data.module
        if not mod then return end
        local txt = self.editBox:GetText()
        if MemDebug and MemDebug.SetModuleAlias then
          MemDebug:SetModuleAlias(mod, txt)
        end
        if W and W.Refresh then
          W:Refresh()
        end
      end,

      OnAlt = function(self)
        local data = self.data
        local mod = data and data.module
        if not mod then return end
        if MemDebug and MemDebug.SetModuleAlias then
          MemDebug:SetModuleAlias(mod, nil)
        end
        if W and W.Refresh then
          W:Refresh()
        end
      end,
    }
  end

  local rowH = 18
  local y = -2

  for i = 1, #names do
    local name = names[i]

    local row = panel._rows[i]
    if not row then
      row = CreateFrame("Frame", nil, content)
      row:SetHeight(rowH)

      local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
      cb:SetPoint("LEFT", row, "LEFT", 0, 0)
      cb:SetSize(18, 18)

      local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
      _applyFontSafe(text, math.max(12, (W.fontSize or 14)), nil)
      _colorText(text)

      local gear = CreateFrame("Button", nil, row)
      gear:SetSize(18, 18)
      gear:SetPoint("RIGHT", row, "RIGHT", 0, 0)

      -- Gear icon (no emoji): Interface/HUD/UIGroupManager2x
      if gear.SetNormalAtlas then
        gear:SetNormalAtlas("GM-icon-settings", true)
      end
      if gear.SetHighlightAtlas then
        gear:SetHighlightAtlas("GM-icon-settings-hover")
      end

      if gear.SetPushedAtlas then
        gear:SetPushedAtlas("GM-icon-settings-pressed", true)
      end

      -- Slightly dim default state so hover reads better
      local nt = gear.GetNormalTexture and gear:GetNormalTexture() or nil
      if nt and nt.SetAlpha then
        nt:SetAlpha(0.9)
      end


      -- AutoWrap toggle (per-module)
      local aw = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
      aw:SetSize(18, 18)
      aw:SetPoint("RIGHT", gear, "LEFT", -4, 0)
      aw:SetScale(0.85)
      if aw.Text then aw.Text:Hide() end
      if aw.text then aw.text:Hide() end

      row._cb = cb
      row._text = text
      row._gear = gear
      row._aw = aw



      local thisName = name

      cb:SetScript("OnClick", function()
        local v = cb:GetChecked() and true or false
        if MemDebug and MemDebug.SetModuleEnabled then
          MemDebug:SetModuleEnabled(thisName, v)
        end
        if W and W.Refresh then
          W:Refresh()
        end
      end)

      if row._aw then
        row._aw:SetScript("OnClick", function()
          local v = row._aw:GetChecked() and true or false
          if MemDebug and MemDebug.SetModuleAutoWrapEnabled then
            MemDebug:SetModuleAutoWrapEnabled(thisName, v)
          end
          if W and W.Refresh then
            W:Refresh()
          end
        end)
      end

      gear:SetScript("OnClick", function()
        local dlg = StaticPopup_Show("PLEEBUG_RENAME")
        if dlg then
          dlg.data = { module = thisName }
        end
      end)

      panel._rows[i] = row


    end

    local label = name
    if MemDebug and MemDebug.GetModuleDisplayName then
      label = MemDebug:GetModuleDisplayName(name)
    end

    row._text:SetText(label)
    row._text:SetAlpha(1)
    row._text:Show()

    local enabled = true
    if MemDebug and MemDebug.IsModuleEnabled then
      enabled = MemDebug:IsModuleEnabled(name)
    end
    row._cb:SetChecked(enabled)

    local awEnabled = false
    if MemDebug and MemDebug.IsModuleAutoWrapEnabled then
      awEnabled = MemDebug:IsModuleAutoWrapEnabled(name)
    end
    if row._aw then
      row._aw:SetChecked(awEnabled)
      row._aw:Show()
    end



    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    row:Show()

    y = y - rowH
  end

  for i = #names + 1, #panel._rows do
    local row = panel._rows[i]
    if row then row:Hide() end
  end

  content:SetHeight(math.max(1, (#names * rowH) + 6))
end



function _ensureRow(i)

  local f = W.frame
  local parent = f._content
  local row = W.rows[i]
  if row then return row end

  row = CreateFrame("Button", nil, parent)
  row:SetHeight(W.rowHeight or 24)
  row:SetPoint("LEFT", parent, "LEFT", 0, 0)
  row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.label:SetPoint("LEFT", row, "LEFT", 6, 0)
  _applyFontSafe(row.label, W.fontSize or 14, nil)

  _colorText(row.label)

  -- CPU measure toggle checkbox (only shown on function leaf rows)
  row.cpuToggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  row.cpuToggle:SetSize(18, 18)
  row.cpuToggle:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  row.cpuToggle:Hide()

  -- CPU avg ms column (separate from calls/sec)
  row.cpuValue = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.cpuValue:SetPoint("RIGHT", row.cpuToggle, "LEFT", -6, 0)
  _applyFontSafe(row.cpuValue, W.fontSize or 14, nil)
  _colorText(row.cpuValue)

  row.value = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  -- leave room for CPU column + checkbox when it is shown
  row.value:SetPoint("RIGHT", row.cpuValue, "LEFT", -10, 0)
  _applyFontSafe(row.value, W.fontSize or 14, nil)
  _colorText(row.value)



  row.cpuToggle:SetScript("OnClick", function(self)
    local data = row._data
    local node = data and data.node
    if not node or not node.path then return end

    local cpu = MemDebug and MemDebug.CPU
    if not (cpu and cpu.SetMeasuredPath) then return end

    -- Window tree uses "Funcs.<Module>....", CPU uses "<Module>...."
    local cpuPath = tostring(node.path):gsub("^Funcs%.", "")

    local enabled = self:GetChecked() and true or false
    cpu:SetMeasuredPath(cpuPath, enabled)

    -- make sure sampler is running if CPU exists
    if cpu.EnsureSampler then cpu:EnsureSampler() end

    W:Refresh()
  end)



  row:SetScript("OnClick", function(self)
    local data = self._data
    if not data or not data.node then return end
    local node = data.node
    if not node.children or not next(node.children) then return end

    local path = node.path
    W.expanded[path] = not W.expanded[path]
    W:Refresh()
  end)

  W.rows[i] = row
  return row
end
-- === BLOCK: MemDebugWindow - UI Factory Ends ===


-- === BLOCK: MemDebugWindow - Render Starts ===
function W:OnSnapshot(snapshot)
  self.lastSnapshot = snapshot or {}
  if self.frame and self.frame:IsShown() then
    self:Refresh()
  end
end

local function _UpdateTimelineTimeLabels(holder, windowSec, fillMode)
  if not holder then return end
  windowSec = tonumber(windowSec) or 10
  if windowSec <= 0 then return end

  local w = holder:GetWidth() or 1


  local padL, padR = 8, 8
  local innerW = math.max(1, w - (padL + padR))

  -- Pixels-per-second controls both tick density and label density.
  local pxPerSec = innerW / windowSec

  -- Minor tick step (ruler "mm"):
  -- zoomed out: 1s ticks
  -- zoom in: 0.1s ticks
  -- deeper: 0.01s ticks
  -- never 0.001s ticks
  local minorStep
  if pxPerSec >= 120 then
    minorStep = 0.01
  elseif pxPerSec >= 60 then
    minorStep = 0.1
  else
    minorStep = 1
  end

  -- If the window is very narrow, avoid insane tick spam
  if pxPerSec < 4 then
    minorStep = 5
  elseif pxPerSec < 10 and minorStep < 1 then
    minorStep = 1
  elseif pxPerSec < 10 then
    minorStep = 2
  end

  -- Hard cap ticks (safety)
  local maxTicks = 700
  while (windowSec / minorStep) > maxTicks do
    minorStep = minorStep * 2
  end

  -- Major tick / label step (ruler "cm"):
  -- Goal: at 60s + zoom=1 => labels every 5s (if there is room).
  -- Otherwise scale density by available width + duration + zoom.
  local desiredLabelPx = 90
  local desiredLabelSec = desiredLabelPx / math.max(1, pxPerSec)

  -- Duration/zoom preference:
  local zoomNow = tonumber(W.timelineZoom) or 1
  local preferred
  if windowSec >= 55 and zoomNow <= 1 then
    preferred = 5
  elseif windowSec >= 45 and zoomNow <= 1 then
    preferred = 5
  elseif windowSec >= 30 and zoomNow <= 1 then
    preferred = 2
  elseif windowSec >= 20 and zoomNow <= 2 then
    preferred = 1
  elseif windowSec >= 10 and zoomNow <= 3 then
    preferred = 0.5
  elseif windowSec >= 10 then
    preferred = 0.2
  else
    preferred = 0.1
  end

  -- Choose the larger of (pixel-safe) and (preferred), then snap to a nice step.
  local target = desiredLabelSec
  if preferred and preferred > target then
    target = preferred
  end

  -- Pick the *smallest* "nice" step that is >= target.
  -- IMPORTANT: candidates must be ascending for this logic.
  local candidates = { 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 30, 60 }
  local labelStep = candidates[#candidates]
  for i = 1, #candidates do
    if candidates[i] >= target then
      labelStep = candidates[i]
      break
    end
  end


  -- Ensure labelStep is >= minorStep and aligned to minorStep
  if labelStep < minorStep then
    labelStep = minorStep
  end
  local majorEvery = math.floor((labelStep / minorStep) + 0.5)
  if majorEvery < 1 then majorEvery = 1 end
  labelStep = majorEvery * minorStep

  -- Final guard: if labels would overlap at current width, back off step (increase it)
  local labelsCount = math.max(1, math.floor((windowSec / labelStep) + 0.5))
  local approxLabelPx = innerW / labelsCount
  while approxLabelPx < 55 and labelStep < 60 do
    labelStep = labelStep * 2
    majorEvery = math.floor((labelStep / minorStep) + 0.5)
    if majorEvery < 1 then majorEvery = 1 end
    labelStep = majorEvery * minorStep
    labelsCount = math.max(1, math.floor((windowSec / labelStep) + 0.5))
    approxLabelPx = innerW / labelsCount
  end


  local decimals
  if labelStep >= 1 then
    decimals = 0
  elseif labelStep >= 0.1 then
    decimals = 1
  else
    decimals = 2
  end

  -- Pools: labels + tick textures
  local labels = holder.__pleebugTimeLabels or {}
  holder.__pleebugTimeLabels = labels

  local ticks = holder.__pleebugTimeTicks or {}
  holder.__pleebugTimeTicks = ticks


  local function ensureLabel(i)
    if labels[i] then return labels[i] end
    local fs = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetJustifyH("CENTER")
    _applyFontSafe(fs, math.max(10, (W.fontSize or 14) - 2), nil)
    _colorText(fs)
    labels[i] = fs
    return fs
  end

  local function ensureTick(i)
    if ticks[i] then return ticks[i] end
    local tx = holder:CreateTexture(nil, "OVERLAY")
    tx:SetColorTexture(1, 1, 1, 0.35)
    ticks[i] = tx
    return tx
  end

  local tStart, tEnd
  if fillMode then
    tStart, tEnd = 0, windowSec
  else
    tStart, tEnd = -windowSec, 0
  end

  -- Tick baseline (a little above the bottom edge so it reads like a ruler)
  local tickBaseY = 18
  local minorH = 6
  local majorH = 10

  local tickIdx = 0
  local labelIdx = 0

  -- Iterate in integer tick steps to avoid float drift
  local nTicks = math.floor((windowSec / minorStep) + 0.5)
  for i = 0, nTicks do
    local t = tStart + (i * minorStep)
    if t > (tEnd + (minorStep * 0.5)) then
      break
    end

    local xNorm
    if fillMode then
      xNorm = t / windowSec
    else
      xNorm = (t + windowSec) / windowSec
    end

    local x = padL + (xNorm * innerW)

    local isMajor = (i % majorEvery) == 0

    tickIdx = tickIdx + 1
    local tx = ensureTick(tickIdx)
    tx:ClearAllPoints()
    tx:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", x, tickBaseY)
    tx:SetSize(1, isMajor and majorH or minorH)
    tx:SetAlpha(isMajor and 0.65 or 0.35)
    tx:Show()

    if isMajor then
      labelIdx = labelIdx + 1
      local fs = ensureLabel(labelIdx)

      fs:ClearAllPoints()
      fs:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", x - 22, 2)
      fs:SetWidth(44)

      fs:SetText(string.format("%." .. decimals .. "f", t) .. "s")
      fs:Show()
    end
  end

  -- Hide unused pool members
  for i = tickIdx + 1, #ticks do
    if ticks[i] then ticks[i]:Hide() end
  end
  for i = labelIdx + 1, #labels do
    if labels[i] then labels[i]:Hide() end
  end
end

local function _UpdateVerticalScale(tf, maxV, unit)
  if not tf or not tf._diagram then return end

  local holder = tf._diagram
  local w = holder:GetWidth() or 0
  local h = holder:GetHeight() or 0
  if w < 80 or h < 80 then return end

  maxV = tonumber(maxV) or 0
  if maxV < 0 then maxV = 0 end

  unit = unit or ""

  -- Keep grid stable even when nearly flat
  if maxV <= 0 then
    maxV = 1
  end

  local padL, padR = 8, 8
  local padTop = 10
  local padBottom = 26 -- leave room for the ruler labels/ticks at the bottom
  local innerH = math.max(1, h - (padTop + padBottom))
  local innerW = math.max(1, w - (padL + padR))

  tf._vGridLines = tf._vGridLines or {}
  tf._vGridLabels = tf._vGridLabels or {}

  local lines = tf._vGridLines
  local labels = tf._vGridLabels

  local function ensureLine(i)
    if lines[i] then return lines[i] end
    local tx = holder:CreateTexture(nil, "OVERLAY")
    tx:SetColorTexture(1, 1, 1, 0.12)
    lines[i] = tx
    return tx
  end

  local function ensureLabel(i)
    if labels[i] then return labels[i] end
    local fs = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetJustifyH("LEFT")
    _applyFontSafe(fs, math.max(10, (W.fontSize or 14) - 3), nil)
    _colorText(fs)
    labels[i] = fs
    return fs
  end

  local decimals
  if maxV >= 100 then
    decimals = 0
  elseif maxV >= 10 then
    decimals = 1
  else
    decimals = 2
  end

  local idx = 0
  for step = 0, 4 do
    local frac = step / 4
    local v = maxV * frac
    local y = padBottom + (frac * innerH)

    idx = idx + 1
    local line = ensureLine(idx)
    line:ClearAllPoints()
    line:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", padL, y)
    line:SetSize(innerW, 1)
    line:SetAlpha((step == 0) and 0.20 or 0.12)
    line:Show()

    local lab = ensureLabel(idx)
    lab:ClearAllPoints()
    lab:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 2, y - 6)
    lab:SetWidth(90)
    lab:SetText(string.format("%." .. decimals .. "f%s", v, (unit ~= "" and (" " .. unit) or "")))
    lab:Show()
  end

  for i = idx + 1, #lines do
    if lines[i] then lines[i]:Hide() end
  end
  for i = idx + 1, #labels do
    if labels[i] then labels[i]:Hide() end
  end
end


function W:Refresh()

  if self._inRefresh then return end
  self._inRefresh = true


  local f = _ensureFrame()

  -- NOTE:
  -- Do NOT ping modules from Refresh().
  -- PingModules is expensive and causes infinite refresh loops on /pleebug.
  -- Module discovery must be triggered explicitly (e.g. on Start).



  -- Keep module list current (new Attach calls populate it)
  _refreshModulePanel(f)

  local enabled = MemDebug:IsEnabled()



  -- Prefer snapshot view, but fall back to live counters so the UI is never "blank".
  local snap = self.lastSnapshot
  if not snap or next(snap) == nil then
    snap = MemDebug:GetLastSnapshot()
  end

  local liveMode = false
  if not snap or next(snap) == nil then
    snap = MemDebug._counts or {}
    liveMode = true
  end

  snap = snap or {}

  -- Rolling view when running: compute counts from trace for the last Interval seconds
  if enabled and MemDebug and MemDebug.GetRecentTrace and MemDebug.GetInterval then
    local winSec = MemDebug:GetInterval()

    self._tmpTraceOut = self._tmpTraceOut or {}
    local tr, now = MemDebug:GetRecentTrace(winSec, nil, self._tmpTraceOut)

    local rolling = self._tmpRolling
    if not rolling then
      rolling = {}
      self._tmpRolling = rolling
    else
      for k in pairs(rolling) do
        rolling[k] = nil
      end
    end
    rolling.__interval = winSec
    rolling.__time = now

    local evTotal, fnTotal = 0, 0


    for i = 1, #tr do
      local k = tr[i] and tr[i].key
      if k then
        rolling[k] = (rolling[k] or 0) + 1
        if k:sub(1, 7) == "Events." then evTotal = evTotal + 1 end
        if k:sub(1, 5) == "Funcs."  then fnTotal = fnTotal + 1 end
      end
    end

    rolling["Events.Total"] = evTotal
    rolling["Funcs.Total"] = fnTotal

    snap = rolling
    liveMode = true
  end

  -- Build tree is deferred over frames to avoid /pleebug freezing on large data.
  self._pendingSnapshot = snap
  self._pendingInterval = snap.__interval or (MemDebug.GetInterval and MemDebug:GetInterval()) or 10
  self._pendingEnabled = enabled
  self._pendingLiveMode = liveMode

  if not self._buildInProgress then
    self:_StartDeferredBuild(snap)
  end

  -- If we already have a built flat list for this snapshot, render it now.
  if self._flatBuiltFor == snap and not self._buildInProgress then
    self:_RenderFlat()
  else
    -- Fast path: show an immediate status so the window appears instantly.
    if f._statusText then
      f._statusText:SetText("Status: Building tree...")
    end
  end


  local interval = snap.__interval or MemDebug:GetInterval()
  local total = 0
  if type(snap["Events.Total"]) == "number" then total = total + snap["Events.Total"] end
  if type(snap["Funcs.Total"]) == "number" then total = total + snap["Funcs.Total"] end

  if f._statusText then
    local statusWord
    if liveMode then
      statusWord = enabled and "Live (Running)" or "Live (Stopped)"
    else
      statusWord = enabled and "Running" or "Stopped"
    end

    f._statusText:SetText(string.format("Status: %s   Interval: %.2fs   Total: %d",
      statusWord, interval, total))

  end
  -- Timeline render (single window): funcs timeline + CPU timeline
  local tf = W.timelineFrame

  local Diagram = (MemDebug and (MemDebug.Diagram or MemDebug.MemDiagram)) or (ns and ns.MemDiagram)
  if tf and tf:IsShown() and Diagram and Diagram.Render then
    local win = MemDebug:GetInterval()
    local enabledNow = MemDebug:IsEnabled()

    -- Timeline behavior (shared for both panes):
    -- 1) Fill left-to-right from 0..win starting at first Start
    -- 2) After win seconds, roll and show only last win seconds
    -- 3) On Stop, freeze time so the plot stops sliding
    if enabledNow and not W._timelineStartTime then
      W._timelineStartTime = _nowPrecise()
    end
    if not enabledNow and not W._timelineFreezeNow then
      W._timelineFreezeNow = _nowPrecise()
    end

    local nowRender = enabledNow and _nowPrecise() or (W._timelineFreezeNow or _nowPrecise())
    local startTime = W._timelineStartTime
    local useStart = nil
    if startTime and nowRender and (nowRender - startTime) < win then
      useStart = startTime
    end

    -- ----------------------------
    -- FUNCS/EVENTS timeline (top)
    -- ----------------------------
    if tf._diagramFn then
      -- PERF: Avoid re-rendering if nothing changed
      local seq = W._traceSeq or 0
      local w = tf._diagramFn.GetWidth and tf._diagramFn:GetWidth() or 0
      local h = tf._diagramFn.GetHeight and tf._diagramFn:GetHeight() or 0

      local freezeNow = W._timelineFreezeNow or 0
      local startNow = W._timelineStartTime or 0
      local zoomNow = tonumber(W.timelineZoom) or 1
      local styleNow = W.traceStyle or "tick"
      local winNow = tonumber(MemDebug:GetInterval()) or 10

      local sig = string.format("%d|%d|%d|%d|%.3f|%.3f|%s|%.3f",
        seq, math.floor(w + 0.5), math.floor(h + 0.5), math.floor(zoomNow + 0.5),
        startNow, freezeNow, styleNow, winNow
      )

      if tf._lastFnSig ~= sig then
        tf._lastFnSig = sig

        local flat = W._flat or {}
        local lanes = {}


      for i = 1, #flat do
        local node = flat[i] and flat[i].node
        if node and node.path then
          lanes[#lanes + 1] = node.path
          if MemDebug and MemDebug._TouchSeries then
            MemDebug:_TouchSeries(node.path)
          end
        end
      end

      -- Apply per-series hide toggles
      if MemDebug and MemDebug.GetSeriesStyle then
        local outN = 0
        for i = 1, #lanes do
          local k = lanes[i]
          local s = MemDebug:GetSeriesStyle(k)
          if not (s and s.enabled == false) then
            outN = outN + 1
            lanes[outN] = k
          end
        end
        for i = outN + 1, #lanes do lanes[i] = nil end
      end

      if tf._seriesPanel and tf._seriesPanel.Update then
        tf._seriesPanel:Update()
      end

      local events = {}
      if MemDebug and MemDebug.GetRecentTrace then
        events = MemDebug:GetRecentTrace(win, nowRender)

        -- Safety: cap draw cost (UI only). Keep the newest events.
        local MAX_EVENTS = 5000
        if type(events) == "table" and #events > MAX_EVENTS then
          local cut = #events - MAX_EVENTS + 1
          local sliced = {}
          local j = 0
          for i = cut, #events do
            j = j + 1
            sliced[j] = events[i]
          end
          events = sliced
        end
      end

      -- Fallback: if the visible tree is empty, derive lanes from the events themselves
      if (#lanes == 0) and type(events) == "table" then
        local seen = {}
        for i = 1, #events do
          local e = events[i]
          local k = e and e.key
          if k and not seen[k] then
            seen[k] = true
            lanes[#lanes + 1] = k
          end
        end
      end

        _UpdateTimelineTimeLabels(tf._diagramFn, win, useStart ~= nil)
        Diagram:Render(tf._diagramFn, lanes, events, nowRender, win, W.traceStyle or "tick", useStart)

      end
    end


    -- ----------------------------
    -- CPU timeline (bottom)
    -- ----------------------------
    if tf._diagramCpu then
      -- PERF: Avoid re-rendering if nothing changed
      local seq = W._traceSeq or 0
      local w = tf._diagramCpu.GetWidth and tf._diagramCpu:GetWidth() or 0
      local h = tf._diagramCpu.GetHeight and tf._diagramCpu:GetHeight() or 0

      local freezeNow = W._timelineFreezeNow or 0
      local startNow = W._timelineStartTime or 0
      local zoomNow = tonumber(W.timelineZoom) or 1
      local winNow = tonumber(MemDebug:GetInterval()) or 10

      local sig = string.format("%d|%d|%d|%d|%.3f|%.3f|cpu|%.3f",
        seq, math.floor(w + 0.5), math.floor(h + 0.5), math.floor(zoomNow + 0.5),
        startNow, freezeNow, winNow
      )

      if tf._lastCpuSig ~= sig then
        tf._lastCpuSig = sig

        local cpu = MemDebug and MemDebug.CPU
        if cpu and cpu.GetRecentEvents then
          local events = cpu:GetRecentEvents(win, nowRender)


        -- Apply Tracked Keys toggles to CPU timeline too (shared series DB)
        local function _seriesEnabled(k)
          if not (MemDebug and MemDebug.GetSeriesStyle) then return true end
          local s = MemDebug:GetSeriesStyle(k)
          return not (s and s.enabled == false)
        end

        -- Filter events by enabled series, but still TouchSeries so they remain in the list
        if type(events) == "table" then
          local filtered = {}
          local j = 0
          for i = 1, #events do
            local e = events[i]
            local k = e and e.key
            if type(k) == "string" and k ~= "" then
              if MemDebug and MemDebug._TouchSeries then
                MemDebug:_TouchSeries(k)
              end
              if _seriesEnabled(k) then
                j = j + 1
                filtered[j] = e
              end
            end
          end
          events = filtered
        end

        local maxMs = 0
        if type(events) == "table" then
          for i = 1, #events do
            local v = events[i] and events[i].v
            v = tonumber(v) or 0
            if v > maxMs then
              maxMs = v
            end
          end
        end

        -- Include reference frame budget in scale if enabled
        if cpu and cpu.RefLineEnabled and cpu:RefLineEnabled() and cpu.GetRefFps then
          local fps = tonumber(cpu:GetRefFps()) or 0
          if fps > 0 then
            local refMs = 1000 / fps
            if refMs > maxMs then
              maxMs = refMs
            end
          end
        end

        -- Build lanes (unique series keys), force CPU.Total to the top if present
        local seen = {}
        local lanes = {}

        local function addLane(k)
          if not k or k == "" then return end
          if seen[k] then return end
          if not _seriesEnabled(k) then return end
          seen[k] = true
          lanes[#lanes + 1] = k
        end

        addLane("CPU.Total")

        local counts = {}
        if type(events) == "table" then
          for i = 1, #events do
            local k = events[i] and events[i].key
            if k then
              counts[k] = (counts[k] or 0) + 1
            end
          end
        end

        local list = {}
        for k, n in pairs(counts) do
          if k ~= "CPU.Total" then
            list[#list + 1] = { k = k, n = n }
          end
        end
        table.sort(list, function(a, b)
          if a.n == b.n then
            return a.k < b.k
          end
          return a.n > b.n
        end)

        local MAX_LANES = 20
        for i = 1, #list do
          addLane(list[i].k)
          if #lanes >= MAX_LANES then
            break
          end
        end

        _UpdateVerticalScale(tf, maxMs, "ms")
        _UpdateTimelineTimeLabels(tf._diagramCpu, win, useStart ~= nil)
          Diagram:Render(tf._diagramCpu, lanes, events, nowRender, win, "cpu", useStart)

        end
      end
    end


  end


  local Diagram = (MemDebug and (MemDebug.Diagram or MemDebug.MemDiagram)) or (ns and ns.MemDiagram)
  if tf and tf:IsShown() and tf._diagram and Diagram and Diagram.Render then
    local flat = W._flat or {}
    local lanes = {}

    for i = 1, #flat do
      local node = flat[i] and flat[i].node
      if node and node.path then
        lanes[#lanes + 1] = node.path
        if MemDebug and MemDebug._TouchSeries then
          MemDebug:_TouchSeries(node.path)
        end
      end
    end

    -- Apply per-series hide toggles
    if MemDebug and MemDebug.GetSeriesStyle then
      local outN = 0
      for i = 1, #lanes do
        local k = lanes[i]
        local s = MemDebug:GetSeriesStyle(k)
        if not (s and s.enabled == false) then
          outN = outN + 1
          lanes[outN] = k
        end
      end
      for i = outN + 1, #lanes do lanes[i] = nil end
    end

    if tf._seriesPanel and tf._seriesPanel.Update then
      tf._seriesPanel:Update()
    end



    local win = MemDebug:GetInterval()

    -- Timeline behavior:
    -- 1) Fill left-to-right from 0..win starting at first Start
    -- 2) After win seconds, roll and show only last win seconds
    -- 3) On Stop, freeze time so the plot stops sliding
    local enabledNow = MemDebug:IsEnabled()

    if enabledNow and not W._timelineStartTime then
      W._timelineStartTime = _nowPrecise()
    end

    if not enabledNow and not W._timelineFreezeNow then
      W._timelineFreezeNow = _nowPrecise()
    end

    local nowRender = enabledNow and _nowPrecise() or (W._timelineFreezeNow or _nowPrecise())
    local startTime = W._timelineStartTime
    local useStart = nil
    if startTime and nowRender and (nowRender - startTime) < win then
      useStart = startTime
    end

    local events = {}
    if MemDebug and MemDebug.GetRecentTrace then
      events = MemDebug:GetRecentTrace(win, nowRender)

      -- Safety: cap draw cost (UI only). Keep the newest events.
      local MAX_EVENTS = 5000
      if type(events) == "table" and #events > MAX_EVENTS then
        local cut = #events - MAX_EVENTS + 1
        local sliced = {}
        local j = 0
        for i = cut, #events do
          j = j + 1
          sliced[j] = events[i]
        end
        events = sliced
      end
    end

    -- Fallback: if the visible tree is empty, derive lanes from the events themselves
    if (#lanes == 0) and type(events) == "table" then
      local seen = {}
      for i = 1, #events do
        local e = events[i]
        local k = e and e.key
        if k and not seen[k] then
          seen[k] = true
          lanes[#lanes + 1] = k
        end
      end
    end

    _UpdateTimelineTimeLabels(tf, win, useStart ~= nil)
    Diagram:Render(tf._diagram, lanes, events, nowRender, win, W.traceStyle or "tick", useStart)

  end


  -- CPU Timeline render (separate window)
  if ctf and ctf:IsShown() and ctf._diagram and Diagram and Diagram.Render then
    local cpu = MemDebug and MemDebug.CPU
    if cpu and cpu.GetRecentEvents then
      local win = MemDebug:GetInterval()

      local enabledNow = MemDebug:IsEnabled()
      local nowRender = enabledNow and _nowPrecise() or (W._timelineFreezeNow or _nowPrecise())
      local startTime = W._timelineStartTime
      local useStart = nil
      if startTime and nowRender and (nowRender - startTime) < win then
        useStart = startTime
      end

      local events = cpu:GetRecentEvents(win, nowRender)

      -- Apply Tracked Keys toggles to CPU timeline too
      if type(events) == "table" and MemDebug and MemDebug.GetSeriesStyle then
        local filtered = {}
        local j = 0
        for i = 1, #events do
          local e = events[i]
          local k = e and e.key
          if type(k) == "string" and k ~= "" then
            -- ensure it exists in the series DB so it stays in the list
            if MemDebug._TouchSeries then
              MemDebug:_TouchSeries(k)
            end

            local s = MemDebug:GetSeriesStyle(k)
            if not (s and s.enabled == false) then
              j = j + 1
              filtered[j] = e
            end
          end
        end
        events = filtered
      end

      local maxMs = 0

      if type(events) == "table" then
        for i = 1, #events do
          local v = events[i] and events[i].v
          v = tonumber(v) or 0
          if v > maxMs then
            maxMs = v
          end
        end
      end

      -- Include reference frame budget in scale if enabled
      if cpu and cpu.RefLineEnabled and cpu:RefLineEnabled() and cpu.GetRefFps then
        local fps = tonumber(cpu:GetRefFps()) or 0
        if fps > 0 then
          local refMs = 1000 / fps
          if refMs > maxMs then
            maxMs = refMs
          end
        end
      end

      -- Build lanes (unique series keys), force CPU.Total to the top if present
      local seen = {}
      local lanes = {}


      local function addLane(k)
        if not k or k == "" then return end
        if seen[k] then return end
        seen[k] = true
        lanes[#lanes+1] = k
      end

      addLane("CPU.Total")

      -- Count activity per lane in-window so we can show the most relevant lanes
      local counts = {}
      if type(events) == "table" then
        for i = 1, #events do
          local k = events[i] and events[i].key
          if k then
            counts[k] = (counts[k] or 0) + 1
          end
        end
      end

      local list = {}
      for k, n in pairs(counts) do
        if k ~= "CPU.Total" then
          list[#list+1] = { k = k, n = n }
        end
      end
      table.sort(list, function(a, b)
        if a.n == b.n then
          return a.k < b.k
        end
        return a.n > b.n
      end)

      local MAX_LANES = 20
      for i = 1, #list do
        addLane(list[i].k)
        if #lanes >= MAX_LANES then
          break
        end
      end

      _UpdateVerticalScale(ctf, maxMs, "ms")
      _UpdateTimelineTimeLabels(ctf, win, useStart ~= nil)
      -- Use a dedicated style so the diagram can use CPU-friendly scaling
      Diagram:Render(ctf._diagram, lanes, events, nowRender, win, "cpu", useStart)


    end
  end




  -- Render list from the last completed deferred build (if any).
  if not self._buildInProgress and self._flatBuiltFor == snap then
    self:_RenderFlat()
  end

  -- keep the UI ticker "no-change" fast-path in sync
  self._lastUiSeq = self._traceSeq or 0

  self._inRefresh = nil
end


function W:Toggle()
  local f = _ensureFrame()
  local tf = _ensureTimelineFrame()
  local ctf = nil



  if f:IsShown() then
    f:Hide()
    if tf then tf:Hide() end



    if self._uiTicker then
      self._uiTicker:Cancel()
      self._uiTicker = nil
    end
  else
    f:Show()
    if tf then tf:Show() end



    self:Refresh()

    if not self._uiTicker then
      self._uiTicker = C_Timer.NewTicker(1.00, function()
        if not (f and f:IsShown()) then return end

        -- PERF: When not recording, avoid continuous redraw + allocations.
        if MemDebug and MemDebug.IsEnabled and (not MemDebug:IsEnabled()) then
          return
        end

        -- PERF: If enabled but nothing new happened, do not rebuild UI/timelines.
        local seq = W._traceSeq or 0
        if W._lastUiSeq == seq then
          return
        end
        W._lastUiSeq = seq

        W:Refresh()
      end)



    end


  end
end

-- === BLOCK: MemDebugWindow - Render Ends ===
