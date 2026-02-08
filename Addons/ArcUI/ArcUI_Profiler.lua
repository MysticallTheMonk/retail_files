-- ===================================================================
-- ArcUI_Profiler.lua
-- Per-Module CPU Profiling with Exportable Analysis
-- v5.0.0: Adds /arcprofile dump for copy-paste analysis
-- ===================================================================

local ADDON, ns = ...
ns.Profiler = ns.Profiler or {}

-- ===================================================================
-- Data Storage
-- ===================================================================
local moduleStats = {}
local functionStats = {}
local isWrapped = false
local originalFunctions = {}
local profilingStartTime = 0

-- ===================================================================
-- Wrap a function to measure it
-- ===================================================================
local function WrapFunction(moduleName, funcName, originalFunc)
  return function(...)
    local results, ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8 = C_AddOnProfiler.MeasureCall(originalFunc, ...)
    
    local mStats = moduleStats[moduleName]
    if not mStats then
      mStats = { calls = 0, totalMs = 0, totalBytes = 0, peakMs = 0 }
      moduleStats[moduleName] = mStats
    end
    mStats.calls = mStats.calls + 1
    mStats.totalMs = mStats.totalMs + (results.elapsedMilliseconds or 0)
    mStats.totalBytes = mStats.totalBytes + (results.allocatedBytes or 0)
    if results.elapsedMilliseconds > mStats.peakMs then
      mStats.peakMs = results.elapsedMilliseconds
    end
    
    local fullName = moduleName .. "." .. funcName
    local fStats = functionStats[fullName]
    if not fStats then
      fStats = { calls = 0, totalMs = 0, totalBytes = 0, peakMs = 0 }
      functionStats[fullName] = fStats
    end
    fStats.calls = fStats.calls + 1
    fStats.totalMs = fStats.totalMs + (results.elapsedMilliseconds or 0)
    fStats.totalBytes = fStats.totalBytes + (results.allocatedBytes or 0)
    if results.elapsedMilliseconds > fStats.peakMs then
      fStats.peakMs = results.elapsedMilliseconds
    end
    
    return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8
  end
end

-- ===================================================================
-- Wrap all functions in a module
-- ===================================================================
local function WrapModule(moduleName, tbl)
  if not tbl then return 0 end
  local count = 0
  for name, func in pairs(tbl) do
    if type(func) == "function" then
      local key = moduleName .. "." .. name
      if not originalFunctions[key] then
        originalFunctions[key] = func
        tbl[name] = WrapFunction(moduleName, name, func)
        count = count + 1
      end
    end
  end
  return count
end

-- ===================================================================
-- Wrap/Unwrap
-- ===================================================================
function ns.Profiler.WrapAll()
  if isWrapped then
    print("|cff00ccffArcUI Profiler|r Already wrapped!")
    return
  end
  
  local total = 0
  total = total + WrapModule("Core", ns.API)
  total = total + WrapModule("Display", ns.Display)
  total = total + WrapModule("CDMEnhance", ns.CDMEnhance)
  total = total + WrapModule("CDMGroups", ns.CDMGroups)
  total = total + WrapModule("Resources", ns.Resources)
  total = total + WrapModule("Catalog", ns.Catalog)
  total = total + WrapModule("CustomTracking", ns.CustomTracking)
  total = total + WrapModule("CooldownBars", ns.CooldownBars)
  
  isWrapped = true
  profilingStartTime = GetTime()
  print("|cff00ccffArcUI Profiler|r Wrapped " .. total .. " functions")
end

function ns.Profiler.UnwrapAll()
  if not isWrapped then return end
  
  local modules = {
    Core = ns.API, Display = ns.Display, CDMEnhance = ns.CDMEnhance,
    CDMGroups = ns.CDMGroups, Resources = ns.Resources, Catalog = ns.Catalog,
    CustomTracking = ns.CustomTracking, CooldownBars = ns.CooldownBars,
  }
  
  for key, origFunc in pairs(originalFunctions) do
    local moduleName, funcName = key:match("^([^.]+)%.(.+)$")
    if moduleName and modules[moduleName] then
      modules[moduleName][funcName] = origFunc
    end
  end
  
  wipe(originalFunctions)
  isWrapped = false
  print("|cff00ccffArcUI Profiler|r Unwrapped")
end

function ns.Profiler.Reset()
  wipe(moduleStats)
  wipe(functionStats)
  profilingStartTime = GetTime()
  print("|cff00ccffArcUI Profiler|r Stats reset")
end

-- ===================================================================
-- DUMP - Create exportable analysis
-- ===================================================================
function ns.Profiler.Dump()
  local duration = GetTime() - profilingStartTime
  if duration < 1 then duration = 1 end
  
  -- Calculate totals
  local totalMs = 0
  local totalCalls = 0
  local totalBytes = 0
  for _, stats in pairs(moduleStats) do
    totalMs = totalMs + stats.totalMs
    totalCalls = totalCalls + stats.calls
    totalBytes = totalBytes + stats.totalBytes
  end
  
  local cpuPct = (totalMs / duration) / 10
  
  -- Build output
  local output = {}
  table.insert(output, "```")
  table.insert(output, "=== ARCUI PROFILER DUMP ===")
  table.insert(output, string.format("Duration: %.1f seconds", duration))
  table.insert(output, string.format("Total CPU: %.2fms (%.2f%% avg)", totalMs, cpuPct))
  table.insert(output, string.format("Total Calls: %d (%.1f/sec)", totalCalls, totalCalls/duration))
  table.insert(output, string.format("Memory Allocated: %.1f KB", totalBytes/1024))
  table.insert(output, "")
  
  -- Module breakdown
  table.insert(output, "=== CPU BY MODULE ===")
  local modSorted = {}
  for name, stats in pairs(moduleStats) do
    table.insert(modSorted, {
      name = name,
      ms = stats.totalMs,
      calls = stats.calls,
      bytes = stats.totalBytes,
      peak = stats.peakMs,
    })
  end
  table.sort(modSorted, function(a, b) return a.ms > b.ms end)
  
  table.insert(output, string.format("%-15s %10s %8s %10s %8s %10s", "Module", "TotalMs", "Pct", "Calls", "AvgMs", "PeakMs"))
  table.insert(output, string.rep("-", 70))
  for _, m in ipairs(modSorted) do
    local pct = totalMs > 0 and (m.ms / totalMs * 100) or 0
    local avg = m.calls > 0 and (m.ms / m.calls) or 0
    table.insert(output, string.format("%-15s %10.2f %7.1f%% %10d %8.4f %10.3f",
      m.name, m.ms, pct, m.calls, avg, m.peak))
  end
  table.insert(output, "")
  
  -- Function breakdown
  table.insert(output, "=== TOP 30 FUNCTIONS ===")
  local funcSorted = {}
  for name, stats in pairs(functionStats) do
    table.insert(funcSorted, {
      name = name,
      ms = stats.totalMs,
      calls = stats.calls,
      bytes = stats.totalBytes,
      peak = stats.peakMs,
    })
  end
  table.sort(funcSorted, function(a, b) return a.ms > b.ms end)
  
  table.insert(output, string.format("%-40s %10s %8s %10s %8s %8s", "Function", "TotalMs", "Pct", "Calls", "AvgMs", "PeakMs"))
  table.insert(output, string.rep("-", 90))
  for i = 1, math.min(30, #funcSorted) do
    local f = funcSorted[i]
    local pct = totalMs > 0 and (f.ms / totalMs * 100) or 0
    local avg = f.calls > 0 and (f.ms / f.calls) or 0
    table.insert(output, string.format("%-40s %10.2f %7.1f%% %10d %8.4f %8.3f",
      f.name, f.ms, pct, f.calls, avg, f.peak))
  end
  table.insert(output, "")
  
  -- High call count analysis
  table.insert(output, "=== HIGH CALL COUNT (potential per-frame) ===")
  local highCallFuncs = {}
  for name, stats in pairs(functionStats) do
    local callsPerSec = stats.calls / duration
    if callsPerSec > 10 then
      table.insert(highCallFuncs, {
        name = name,
        calls = stats.calls,
        cps = callsPerSec,
        ms = stats.totalMs,
        avg = stats.calls > 0 and (stats.totalMs / stats.calls) or 0,
      })
    end
  end
  table.sort(highCallFuncs, function(a, b) return a.cps > b.cps end)
  
  table.insert(output, string.format("%-40s %10s %10s %10s %8s", "Function", "Calls", "Calls/Sec", "TotalMs", "AvgMs"))
  table.insert(output, string.rep("-", 85))
  for _, f in ipairs(highCallFuncs) do
    table.insert(output, string.format("%-40s %10d %10.1f %10.2f %8.4f",
      f.name, f.calls, f.cps, f.ms, f.avg))
  end
  table.insert(output, "")
  
  -- Expensive single calls
  table.insert(output, "=== EXPENSIVE CALLS (high avg time) ===")
  local expensiveFuncs = {}
  for name, stats in pairs(functionStats) do
    local avg = stats.calls > 0 and (stats.totalMs / stats.calls) or 0
    if avg > 0.05 and stats.calls > 5 then
      table.insert(expensiveFuncs, {
        name = name,
        avg = avg,
        peak = stats.peakMs,
        calls = stats.calls,
        ms = stats.totalMs,
      })
    end
  end
  table.sort(expensiveFuncs, function(a, b) return a.avg > b.avg end)
  
  table.insert(output, string.format("%-40s %10s %10s %10s %10s", "Function", "AvgMs", "PeakMs", "Calls", "TotalMs"))
  table.insert(output, string.rep("-", 85))
  for i = 1, math.min(20, #expensiveFuncs) do
    local f = expensiveFuncs[i]
    table.insert(output, string.format("%-40s %10.4f %10.3f %10d %10.2f",
      f.name, f.avg, f.peak, f.calls, f.ms))
  end
  table.insert(output, "")
  
  -- Optimization suggestions
  table.insert(output, "=== OPTIMIZATION SUGGESTIONS ===")
  
  for _, f in ipairs(highCallFuncs) do
    if f.cps > 60 then
      table.insert(output, string.format("! %s called %.0f/sec - likely per-frame, consider caching", f.name, f.cps))
    elseif f.cps > 30 then
      table.insert(output, string.format("? %s called %.0f/sec - may benefit from throttling", f.name, f.cps))
    end
  end
  
  for _, f in ipairs(expensiveFuncs) do
    if f.avg > 0.5 then
      table.insert(output, string.format("! %s takes %.2fms avg - expensive, optimize internals", f.name, f.avg))
    elseif f.avg > 0.1 then
      table.insert(output, string.format("? %s takes %.2fms avg - consider caching results", f.name, f.avg))
    end
  end
  
  table.insert(output, "```")
  
  -- Show in editbox
  local text = table.concat(output, "\n")
  ns.Profiler.ShowExportWindow(text)
end

-- ===================================================================
-- Export Window
-- ===================================================================
local exportFrame = nil

function ns.Profiler.ShowExportWindow(text)
  if not exportFrame then
    exportFrame = CreateFrame("Frame", "ArcUI_ProfilerExport", UIParent, "BackdropTemplate")
    exportFrame:SetSize(700, 500)
    exportFrame:SetPoint("CENTER")
    exportFrame:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = 2,
    })
    exportFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    exportFrame:SetBackdropBorderColor(0, 0.8, 1, 1)
    exportFrame:EnableMouse(true)
    exportFrame:SetMovable(true)
    exportFrame:RegisterForDrag("LeftButton")
    exportFrame:SetScript("OnDragStart", exportFrame.StartMoving)
    exportFrame:SetScript("OnDragStop", exportFrame.StopMovingOrSizing)
    exportFrame:SetFrameStrata("DIALOG")
    
    exportFrame.title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    exportFrame.title:SetPoint("TOP", 0, -10)
    exportFrame.title:SetText("|cff00ccffArcUI Profiler - Copy This Output|r")
    
    exportFrame.scrollFrame = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
    exportFrame.scrollFrame:SetPoint("TOPLEFT", 15, -40)
    exportFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)
    
    exportFrame.editBox = CreateFrame("EditBox", nil, exportFrame.scrollFrame)
    exportFrame.editBox:SetMultiLine(true)
    exportFrame.editBox:SetFontObject(GameFontHighlightSmall)
    exportFrame.editBox:SetWidth(640)
    exportFrame.editBox:SetAutoFocus(false)
    exportFrame.editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    exportFrame.scrollFrame:SetScrollChild(exportFrame.editBox)
    
    exportFrame.closeBtn = CreateFrame("Button", nil, exportFrame, "UIPanelCloseButton")
    exportFrame.closeBtn:SetPoint("TOPRIGHT", 0, 0)
    
    exportFrame.selectBtn = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    exportFrame.selectBtn:SetSize(120, 25)
    exportFrame.selectBtn:SetPoint("BOTTOM", 0, 10)
    exportFrame.selectBtn:SetText("Select All")
    exportFrame.selectBtn:SetScript("OnClick", function()
      exportFrame.editBox:HighlightText()
      exportFrame.editBox:SetFocus()
    end)
  end
  
  exportFrame.editBox:SetText(text)
  exportFrame:Show()
  
  -- Auto-select
  C_Timer.After(0.1, function()
    exportFrame.editBox:HighlightText()
    exportFrame.editBox:SetFocus()
  end)
end

-- ===================================================================
-- LIVE MONITOR (simplified)
-- ===================================================================
local monitorFrame = nil
local isMonitoring = false
local lastModuleStats = {}
local lastUpdateTime = 0

function ns.Profiler.Live(enable)
  if enable == nil then enable = not isMonitoring end
  
  if enable and not isMonitoring then
    if not isWrapped then ns.Profiler.WrapAll() end
    
    if not monitorFrame then
      monitorFrame = CreateFrame("Frame", "ArcUI_ProfilerMonitor", UIParent, "BackdropTemplate")
      monitorFrame:SetSize(320, 380)
      monitorFrame:SetPoint("TOPRIGHT", -20, -100)
      monitorFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
      })
      monitorFrame:SetBackdropColor(0, 0, 0, 0.92)
      monitorFrame:SetBackdropBorderColor(0, 0.8, 1, 0.8)
      monitorFrame:EnableMouse(true)
      monitorFrame:SetMovable(true)
      monitorFrame:RegisterForDrag("LeftButton")
      monitorFrame:SetScript("OnDragStart", monitorFrame.StartMoving)
      monitorFrame:SetScript("OnDragStop", monitorFrame.StopMovingOrSizing)
      monitorFrame:SetFrameStrata("HIGH")
      
      monitorFrame.title = monitorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      monitorFrame.title:SetPoint("TOP", 0, -8)
      monitorFrame.title:SetText("|cff00ccffArcUI Per-Module CPU|r")
      
      monitorFrame.text = monitorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      monitorFrame.text:SetPoint("TOPLEFT", 10, -30)
      monitorFrame.text:SetPoint("BOTTOMRIGHT", -10, 10)
      monitorFrame.text:SetJustifyH("LEFT")
      monitorFrame.text:SetJustifyV("TOP")
      
      monitorFrame.closeBtn = CreateFrame("Button", nil, monitorFrame, "UIPanelCloseButton")
      monitorFrame.closeBtn:SetPoint("TOPRIGHT", 2, 2)
      monitorFrame.closeBtn:SetScript("OnClick", function() ns.Profiler.Live(false) end)
    end
    
    for name, stats in pairs(moduleStats) do
      lastModuleStats[name] = { ms = stats.totalMs, calls = stats.calls }
    end
    lastUpdateTime = GetTime()
    
    monitorFrame:Show()
    isMonitoring = true
    
    local updateInterval = 0
    monitorFrame:SetScript("OnUpdate", function(self, elapsed)
      updateInterval = updateInterval + elapsed
      if updateInterval < 1.0 then return end
      updateInterval = 0
      
      local now = GetTime()
      local duration = now - lastUpdateTime
      if duration < 0.1 then duration = 1 end
      
      local lines = {}
      local deltaStats = {}
      local totalDeltaMs = 0
      local totalDeltaCalls = 0
      
      for name, stats in pairs(moduleStats) do
        local last = lastModuleStats[name] or { ms = 0, calls = 0 }
        local deltaMs = stats.totalMs - last.ms
        local deltaCalls = stats.calls - last.calls
        if deltaMs > 0 then
          deltaStats[name] = { ms = deltaMs, calls = deltaCalls }
          totalDeltaMs = totalDeltaMs + deltaMs
          totalDeltaCalls = totalDeltaCalls + deltaCalls
        end
        lastModuleStats[name] = { ms = stats.totalMs, calls = stats.calls }
      end
      lastUpdateTime = now
      
      local msPerSec = totalDeltaMs / duration
      local cpuPct = msPerSec / 10
      local cpuColor = cpuPct > 2 and "|cffff0000" or (cpuPct > 1 and "|cffff9900" or "|cff00ff00")
      
      table.insert(lines, string.format("|cffFFCC00ArcUI CPU:|r %s%.2f%%|r (%.1fms/sec)", cpuColor, cpuPct, msPerSec))
      table.insert(lines, string.format("|cff888888%d calls in %.1fs|r", totalDeltaCalls, duration))
      table.insert(lines, "")
      
      local sorted = {}
      for name, delta in pairs(deltaStats) do
        table.insert(sorted, { name = name, ms = delta.ms, calls = delta.calls })
      end
      table.sort(sorted, function(a, b) return a.ms > b.ms end)
      
      table.insert(lines, "|cffFFCC00CPU by Module (last 1s):|r")
      for i, entry in ipairs(sorted) do
        local pct = totalDeltaMs > 0 and (entry.ms / totalDeltaMs * 100) or 0
        local color = pct > 30 and "|cffff0000" or (pct > 10 and "|cffff9900" or "|cff00ff00")
        table.insert(lines, string.format("%s%5.1f%%|r %.2fms %s (%d)", color, pct, entry.ms, entry.name, entry.calls))
      end
      
      table.insert(lines, "")
      
      local funcSorted = {}
      for name, stats in pairs(functionStats) do
        if stats.totalMs > 0.01 then
          table.insert(funcSorted, { name = name, ms = stats.totalMs, calls = stats.calls })
        end
      end
      table.sort(funcSorted, function(a, b) return a.ms > b.ms end)
      
      table.insert(lines, "|cffFFCC00Top Functions (total):|r")
      for i = 1, math.min(8, #funcSorted) do
        local f = funcSorted[i]
        local shortName = f.name:gsub("CDMEnhance", "CDM"):gsub("Display", "Disp"):gsub("CustomTracking", "Cust")
        table.insert(lines, string.format("  %.2fms %s (%d)", f.ms, shortName, f.calls))
      end
      
      table.insert(lines, "")
      table.insert(lines, "|cff00ff00/arcprofile dump|r - export for analysis")
      table.insert(lines, "|cff666666/arcprofile stop to close|r")
      
      self.text:SetText(table.concat(lines, "\n"))
    end)
    
    print("|cff00ccffArcUI Profiler|r Live monitor ON")
  elseif not enable and isMonitoring then
    if monitorFrame then
      monitorFrame:Hide()
      monitorFrame:SetScript("OnUpdate", nil)
    end
    isMonitoring = false
    print("|cff00ccffArcUI Profiler|r Live monitor OFF")
  end
end

-- ===================================================================
-- SLASH COMMANDS
-- ===================================================================
SLASH_ARCPROFILE1 = "/arcprofile"
SLASH_ARCPROFILE2 = "/acp"

SlashCmdList["ARCPROFILE"] = function(msg)
  local cmd = (msg or ""):lower():match("^(%S*)")
  
  if cmd == "start" or cmd == "wrap" then
    ns.Profiler.WrapAll()
  elseif cmd == "stop" or cmd == "unwrap" then
    ns.Profiler.Live(false)
    ns.Profiler.UnwrapAll()
  elseif cmd == "live" or cmd == "monitor" then
    ns.Profiler.Live()
  elseif cmd == "dump" or cmd == "export" then
    ns.Profiler.Dump()
  elseif cmd == "reset" then
    ns.Profiler.Reset()
  else
    print("|cff00ccff══════ ArcUI Profiler ══════|r")
    print("  /arcprofile start  - Begin profiling")
    print("  /arcprofile live   - Real-time monitor")
    print("  /arcprofile dump   - |cff00ff00Export for Claude analysis|r")
    print("  /arcprofile reset  - Clear stats")
    print("  /arcprofile stop   - Stop profiling")
  end
end

print("|cff00ccffArcUI Profiler|r Loaded - /arcprofile start, then /arcprofile dump")