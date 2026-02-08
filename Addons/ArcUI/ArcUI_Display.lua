-- ===================================================================
-- ArcUI_Display.lua
-- Display system supporting multiple independent bars
-- v2.9.6: Fixed white bar flash timing
--   - Check aura existence EVERY FRAME (no throttle) for instant response
--   - Only throttle color/value updates, not expiry detection
--   - Use bar:SetAlpha(0) not texture alpha (animation overrides texture)
--   - Restore bar:SetAlpha(1) when new aura starts
-- v2.9.2: Fixed ColorCurve alpha handling for duration bars
--   - GetRGB() → GetRGBA() so color picker opacity applies to bar texture
--   - Threshold settings hash now includes alpha for proper cache invalidation
-- v2.9.1: Fixed ColorCurve threshold for duration bars
--   - Removed SetType() call (ColorCurves don't support it)
--   - Fixed curve point setup for step-like transitions
--   - Added OnUpdate handler for continuous color updates as aura depletes
--   - Properly clears OnUpdate when bar inactive or threshold disabled
-- ===================================================================

local ADDON, ns = ...
ns.Display = ns.Display or {}

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- ===================================================================
-- INITIALIZATION FLAG: Prevent bar flash during reload
-- Bars stay hidden until initialization completes (after PLAYER_ENTERING_WORLD + delay)
-- ===================================================================
local initializationComplete = false

-- Mark initialization as complete (called from Core.lua after setup)
function ns.Display.MarkInitializationComplete()
  initializationComplete = true
end

-- Check if initialization is complete
function ns.Display.IsInitialized()
  return initializationComplete
end

-- ===================================================================
-- LIBPLEEBUG PROFILING SETUP
-- ===================================================================
local MemDebug = LibStub and LibStub("LibPleebug-1", true)
local P, TrackThis
if MemDebug then
  P, TrackThis = MemDebug:DropIn(ns.Display)
end
ns.Display._TrackThis = TrackThis

-- ═══════════════════════════════════════════════════════════════════════════
-- PERFORMANCE: Safe Show/Hide that skip redundant calls
-- Calling Hide() on already-hidden frame still has C++ overhead
-- ═══════════════════════════════════════════════════════════════════════════
local function SafeHide(frame)
    if frame and frame:IsShown() then
        frame:Hide()
    end
end

local function SafeShow(frame)
    if frame and not frame:IsShown() then
        frame:Show()
    end
end

-- Track if delete buttons should be visible (set when options panel opens)
local deleteButtonsVisible = false

-- Forward declaration for delete confirmation (defined later in file)
local ShowDeleteConfirmation

-- ===================================================================
-- COLORCURVE CACHE FOR DURATION BARS (v2.8.2 - Fixed config key mismatch)
-- Curves are created once per bar and rebuilt when settings change
-- ===================================================================
local durationColorCurves = {}  -- [barNumber] = { curve = ColorCurve, settingsHash = string }

-- Default colors matching AppearanceOptions display defaults
local DURATION_THRESHOLD_DEFAULT_COLORS = {
  [2] = {r=0.8, g=0.8, b=0, a=1},   -- Yellow
  [3] = {r=1, g=0.5, b=0, a=1},     -- Orange
  [4] = {r=1, g=0.3, b=0, a=1},     -- Red-Orange
  [5] = {r=1, g=0, b=0, a=1},       -- Red
}
local DURATION_THRESHOLD_DEFAULT_VALUES = {
  [2] = 75,
  [3] = 50,
  [4] = 25,
  [5] = 10,
}

-- Helper to create a simple hash of threshold settings for cache invalidation
local function GetThresholdSettingsHash(cfg, baseColor)
  local parts = {}
  local bc = baseColor or {r=0, g=0.8, b=1, a=1}
  table.insert(parts, string.format("bc:%.2f,%.2f,%.2f,%.2f", bc.r, bc.g, bc.b, bc.a or 1))
  for i = 2, 5 do
    local enabled = cfg["durationThreshold" .. i .. "Enabled"]
    local value = cfg["durationThreshold" .. i .. "Value"] or DURATION_THRESHOLD_DEFAULT_VALUES[i]
    local color = cfg["durationThreshold" .. i .. "Color"] or DURATION_THRESHOLD_DEFAULT_COLORS[i]
    if enabled then
      table.insert(parts, string.format("t%d:%d,%.2f,%.2f,%.2f,%.2f", i, value, color.r, color.g, color.b, color.a or 1))
    end
  end
  table.insert(parts, cfg.durationThresholdAsSeconds and "sec" or "pct")
  table.insert(parts, tostring(cfg.durationThresholdMaxDuration or 0))
  return table.concat(parts, "|")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PERFORMANCE: Bar appearance caching
-- Expensive operations (SetTexture, SetOrientation, etc) only need to run
-- when appearance settings change, not every frame. This hash tracks changes.
-- ═══════════════════════════════════════════════════════════════════════════
local function GetBarAppearanceHash(barConfig)
  if not barConfig or not barConfig.display then return nil end
  local d = barConfig.display
  local bc = d.barColor or {r=0, g=0, b=0}
  -- Include all settings that affect bar setup (not dynamic values like fill %)
  return string.format("%s|%s|%s|%s|%.2f|%.2f|%.2f|%s|%s",
    d.texture or "default",
    d.barOrientation or "horizontal",
    tostring(d.barReverseFill),
    tostring(d.showBackground),
    bc.r, bc.g, bc.b,
    tostring(d.useGradient),
    tostring(d.durationColorCurveEnabled)
  )
end

-- Create or get cached ColorCurve for a duration bar
-- ColorCurves use linear interpolation by default - we create step transitions
-- by placing pairs of points very close together (epsilon apart)
local function GetDurationColorCurve(barNumber, barConfig)
  if not barConfig or not barConfig.display then return nil end
  
  local cfg = barConfig.display
  if not cfg.durationColorCurveEnabled then return nil end
  
  -- Check if ColorCurve API exists (WoW 12.0+)
  if not C_CurveUtil or not C_CurveUtil.CreateColorCurve then
    return nil
  end
  
  -- Get base bar color (used at 100% remaining)
  local baseColor = cfg.barColor or {r=0, g=0.8, b=1, a=1}
  
  -- Check if we need to rebuild the curve (settings changed)
  local currentHash = GetThresholdSettingsHash(cfg, baseColor)
  local cached = durationColorCurves[barNumber]
  
  if cached and cached.settingsHash == currentHash then
    return cached.curve
  end
  
  -- Build threshold points from UI settings
  local thresholds = {}
  
  for i = 2, 5 do
    local enabled = cfg["durationThreshold" .. i .. "Enabled"]
    local value = cfg["durationThreshold" .. i .. "Value"] or DURATION_THRESHOLD_DEFAULT_VALUES[i]
    local color = cfg["durationThreshold" .. i .. "Color"] or DURATION_THRESHOLD_DEFAULT_COLORS[i]
    
    if enabled then
      table.insert(thresholds, { value = value, color = color })
    end
  end
  
  -- If no thresholds enabled, return nil (use base color only)
  if #thresholds == 0 then
    durationColorCurves[barNumber] = nil
    return nil
  end
  
  -- Sort thresholds by value ascending (lowest % first)
  -- e.g., [{value=10%, Red}, {value=25%, Orange}, {value=50%, Yellow}]
  table.sort(thresholds, function(a, b) return a.value < b.value end)
  
  -- Create the ColorCurve (NOTE: ColorCurves don't have SetType - they use linear interpolation)
  -- We simulate step behavior by using pairs of points with tiny epsilon gaps
  local curve = C_CurveUtil.CreateColorCurve()
  
  -- Mode settings
  local asSeconds = cfg.durationThresholdAsSeconds
  local maxDuration = cfg.durationThresholdMaxDuration or 30
  
  -- Epsilon for creating instant color transitions
  local EPSILON = 0.0001
  
  -- Build curve points for step-like transitions
  -- For threshold at 50%, we want:
  --   0% to 49.99% = threshold color
  --   50% to 100% = next higher color (or base)
  --
  -- Example: thresholds = [{10%=Red}, {50%=Yellow}], base=Blue
  -- Points:
  --   0.0 = Red (lowest threshold's color for 0-10%)
  --   0.10 = Red (just before transition)
  --   0.10+ε = Yellow (transition to next threshold)
  --   0.50 = Yellow (just before transition)
  --   0.50+ε = Blue (transition to base)
  --   1.0 = Blue (at full duration)
  
  -- Start with lowest threshold's color at 0%
  local lowestColor = thresholds[1].color
  curve:AddPoint(0.0, CreateColor(lowestColor.r, lowestColor.g, lowestColor.b, lowestColor.a or 1))
  
  -- Add transition points for each threshold
  for i = 1, #thresholds do
    local t = thresholds[i]
    local pct
    if asSeconds then
      pct = t.value / maxDuration
    else
      pct = t.value / 100
    end
    pct = math.max(0, math.min(1, pct))
    
    -- Determine next color (above this threshold)
    local nextColor
    if i == #thresholds then
      -- Last threshold - above this use base color
      nextColor = baseColor
    else
      -- Use next threshold's color
      nextColor = thresholds[i + 1].color
    end
    
    -- Add point just before threshold (current threshold's color)
    local currentColor = t.color
    if pct > EPSILON then
      curve:AddPoint(pct - EPSILON, CreateColor(currentColor.r, currentColor.g, currentColor.b, currentColor.a or 1))
    end
    
    -- Add point at threshold (next color begins)
    curve:AddPoint(pct, CreateColor(nextColor.r, nextColor.g, nextColor.b, nextColor.a or 1))
  end
  
  -- End with base color at 100%
  curve:AddPoint(1.0, CreateColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1))
  
  -- Cache
  durationColorCurves[barNumber] = { curve = curve, settingsHash = currentHash }
  return curve
end

-- Clear cached curve for a bar (called when settings change)
function ns.Display.ClearDurationColorCurve(barNumber)
  durationColorCurves[barNumber] = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER: Rotate StatusBar Texture for Vertical Bars
-- ===================================================================
-- HELPER: APPLY FILL TEXTURE SCALE
-- ===================================================================
local function ApplyFillTextureScale(statusBar, scale, isVertical)
  if not statusBar then return end
  scale = scale or 1.0
  
  -- Get the StatusBar texture and apply scaling
  local texture = statusBar:GetStatusBarTexture()
  if texture then
    -- Reset to defaults first
    texture:SetTexCoord(0, 1, 0, 1)
    texture:SetHorizTile(false)
    texture:SetVertTile(false)
    
    -- For StatusBars, we control tiling through HorizTile/VertTile
    -- Scale < 1 = more repetitions (tiled), Scale > 1 = stretched
    if scale < 1 then
      -- Tiled mode - texture repeats
      if isVertical then
        texture:SetVertTile(true)
      else
        texture:SetHorizTile(true)
      end
    else
      -- Stretched mode - texture stretches
      -- Adjust tex coords to stretch - smaller value = more stretch visible
      local stretchAmount = 1.0 / scale
      if isVertical then
        -- For vertical bars, stretch along the Y axis
        texture:SetTexCoord(0, 1, 0, stretchAmount)
      else
        -- For horizontal bars, stretch along the X axis
        texture:SetTexCoord(0, stretchAmount, 0, 1)
      end
    end
  end
end

-- ===================================================================
-- HELPER: SAFE NUMBER COMPARISON (protects against secret values)
-- Returns true if value is a regular number and > 0
-- ===================================================================
local function IsNumericAndPositive(value)
  if value == nil then return false end
  -- Use pcall to safely check if value can be compared
  local ok, result = pcall(function() return type(value) == "number" and value > 0 end)
  return ok and result
end

-- ===================================================================
-- HELPER: FORMAT DURATION WITH DECIMALS
-- Safely formats duration values, handling both secrets and regular numbers
-- For secret values (from DurationObject), passes through directly
-- For regular numbers (preview, calculated), applies decimal formatting
-- ===================================================================
local function FormatDuration(value, decimals)
  if value == nil then return "" end
  decimals = decimals or 1
  
  -- Try to format as number (will fail for secret values)
  local ok, formatted = pcall(function()
    -- Check if it's a number we can format
    local num = tonumber(value)
    if num then
      return string.format("%." .. decimals .. "f", num)
    end
    -- If tonumber fails but value exists, it's likely a secret - pass through
    return value
  end)
  
  if ok and formatted then
    return formatted
  end
  
  -- Fallback: pass through directly (for secret values)
  return value
end

-- ===================================================================
-- HELPER: APPLY SMOOTHING TO STATUSBAR
-- ===================================================================
local function ApplyBarSmoothing(bar, enableSmooth)
  if not bar then return end
  if bar.SetSmoothing then
    bar:SetSmoothing(enableSmooth)
  end
end

-- ===================================================================
-- HELPER: APPLY GRADIENT TO STATUSBAR
-- Creates a visual gradient effect by blending the bar color with a second color
-- ===================================================================
local function ApplyBarGradient(bar, barConfig)
  if not bar then return end
  
  local cfg = barConfig and barConfig.display
  if not cfg then return end
  
  local texture = bar:GetStatusBarTexture()
  if not texture then return end
  
  local useGradient = cfg.useGradient
  local direction = cfg.gradientDirection or "VERTICAL"
  local intensity = cfg.gradientIntensity or 0.5
  local secondColor = cfg.gradientSecondColor or {r=0, g=0, b=0, a=0.5}
  
  if not useGradient then
    -- Reset gradient (solid color)
    -- Get the current color from the StatusBar
    local r, g, b, a = bar:GetStatusBarColor()
    if texture.SetGradient then
      -- Create solid color by using same color for both ends
      local solidColor = CreateColor(r, g, b, a)
      texture:SetGradient(direction, solidColor, solidColor)
    end
    return
  end
  
  -- Get the base bar color
  local r, g, b, a = bar:GetStatusBarColor()
  
  -- Blend the base color with the second color based on intensity
  local r2 = r + (secondColor.r - r) * intensity
  local g2 = g + (secondColor.g - g) * intensity
  local b2 = b + (secondColor.b - b) * intensity
  local a2 = a  -- Keep alpha from main color for consistency
  
  -- Apply gradient
  if texture.SetGradient then
    local startColor = CreateColor(r, g, b, a)
    local endColor = CreateColor(r2, g2, b2, a2)
    texture:SetGradient(direction, startColor, endColor)
  end
end

-- ===================================================================
-- HELPER: GET FONT OUTLINE FLAG STRING
-- ===================================================================
local function GetOutlineFlag(outlineSetting)
  -- Convert setting to font flag
  if outlineSetting == "NONE" or outlineSetting == "" or not outlineSetting then
    return ""
  elseif outlineSetting == "THICKOUTLINE" then
    return "THICKOUTLINE"
  else
    return "OUTLINE"  -- Default
  end
end

-- ===================================================================
-- HELPER: APPLY TEXT SHADOW
-- ===================================================================
local function ApplyTextShadow(fontString, enableShadow, shadowColor)
  if not fontString then return end
  if enableShadow then
    local sc = shadowColor or {r=0, g=0, b=0, a=1}
    fontString:SetShadowColor(sc.r, sc.g, sc.b, sc.a or 1)
    fontString:SetShadowOffset(1, -1)
  else
    fontString:SetShadowOffset(0, 0)
  end
end

-- ===================================================================
-- FRAME STORAGE (per bar)
-- ===================================================================
local barFrames = {}  -- [barNumber] = {barFrame, textFrame}
ns.Display._barFrames = barFrames  -- Expose for debugger

-- ===================================================================
-- EVENT-DRIVEN AURA POLLING OPTIMIZATION
-- Tracks which bars are actively polling auras, stops polling on expiry
-- ===================================================================
local activeAuraPolling = {}  -- [barNumber] = { unit = string, auraID = number, barFrame = frame }

local auraEventFrame = CreateFrame("Frame")
auraEventFrame:RegisterEvent("UNIT_AURA")
auraEventFrame:SetScript("OnEvent", function(self, event, unit, updateInfo)
  -- Quick exit if no bars are polling
  if not next(activeAuraPolling) then return end
  
  -- Check each polling bar to see if its aura is still valid
  for barNumber, data in pairs(activeAuraPolling) do
    if data.unit == unit then
      -- This unit changed, check if our tracked aura still exists
      local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(data.unit, data.auraID)
      if not auraData then
        -- Aura expired! Stop polling immediately
        if data.barFrame and data.barFrame.bar then
          data.barFrame.bar:SetScript("OnUpdate", nil)
          data.barFrame.bar.colorCurveData = nil
          data.barFrame.bar.manualMaxData = nil
        end
        if data.iconFrame then
          data.iconFrame:SetScript("OnUpdate", nil)
          data.iconFrame.durationActive = false
        end
        if data.durationFrame then
          data.durationFrame:SetScript("OnUpdate", nil)
          data.durationFrame.isActive = false
        end
        activeAuraPolling[barNumber] = nil
      end
    end
  end
end)

-- Helper to register a bar for aura polling tracking
local function RegisterAuraPolling(barNumber, unit, auraID, barFrame, iconFrame, durationFrame)
  if not unit or not auraID then return end
  activeAuraPolling[barNumber] = {
    unit = unit,
    auraID = auraID,
    barFrame = barFrame,
    iconFrame = iconFrame,
    durationFrame = durationFrame,
  }
end

-- Helper to unregister a bar from aura polling
local function UnregisterAuraPolling(barNumber)
  activeAuraPolling[barNumber] = nil
end

-- ===================================================================
-- LIVE PREVIEW MODE (uses actual bars, not separate preview)
-- ===================================================================
local previewMode = false
local previewStacks = 0.5  -- Decimal 0-1 (0.5 = 50%)

function ns.Display.SetPreviewMode(enabled)
  previewMode = enabled
  if enabled then
    -- Update all bars to show preview value (convert decimal to stacks)
    local activeBars = ns.API.GetActiveBars and ns.API.GetActiveBars() or {}
    for _, barNum in ipairs(activeBars) do
      local barConfig = ns.API.GetBarConfig and ns.API.GetBarConfig(barNum)
      if barConfig then
        local maxStacks = barConfig.tracking.maxStacks or 10
        local useDurationBar = barConfig.tracking.useDurationBar
        -- Convert decimal (0-1) to actual stack count
        local stackCount = math.floor(previewStacks * maxStacks + 0.5)
        
        if useDurationBar then
          ns.Display.UpdateDurationBar(barNum, stackCount, maxStacks, true, nil, nil, nil)
        else
          ns.Display.UpdateBar(barNum, stackCount, maxStacks, true)
        end
      end
    end
  else
    -- Refresh all bars to show real values
    if ns.API.RefreshAll then
      ns.API.RefreshAll()
    end
  end
end

function ns.Display.SetPreviewStacks(decimal)
  previewStacks = decimal
  if previewMode then
    -- Update all bars with new preview decimal (convert to stacks per bar)
    local activeBars = ns.API.GetActiveBars and ns.API.GetActiveBars() or {}
    for _, barNum in ipairs(activeBars) do
      local barConfig = ns.API.GetBarConfig and ns.API.GetBarConfig(barNum)
      if barConfig then
        local maxStacks = barConfig.tracking.maxStacks or 10
        local useDurationBar = barConfig.tracking.useDurationBar
        -- Convert decimal (0-1) to actual stack count
        local stackCount = math.floor(decimal * maxStacks + 0.5)
        
        if useDurationBar then
          ns.Display.UpdateDurationBar(barNum, stackCount, maxStacks, true, nil, nil, nil)
        else
          ns.Display.UpdateBar(barNum, stackCount, maxStacks, true)
        end
      end
    end
  end
end

function ns.Display.IsPreviewMode()
  return previewMode
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PERFORMANCE OPTIMIZATION: Cached lookups and state tracking
-- Avoids expensive repeated calls in the ticker loop
-- ═══════════════════════════════════════════════════════════════════════════

-- Cache AceConfigDialog reference (only lookup once per session)
local cachedAceConfigDialog = nil
local function GetAceConfigDialog()
  if not cachedAceConfigDialog then
    cachedAceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
  end
  return cachedAceConfigDialog
end

-- Helper to check if options panel is open (uses cached reference)
local function IsOptionsOpen()
  local AceConfigDialog = GetAceConfigDialog()
  if AceConfigDialog and AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["ArcUI"] then
    return true
  end
  return false
end

-- Cache current spec (updated via event, not API call every frame)
local cachedCurrentSpec = nil
local function GetCachedSpec()
  if cachedCurrentSpec == nil then
    cachedCurrentSpec = GetSpecialization() or 0
  end
  return cachedCurrentSpec
end

-- Invalidate spec cache (call on PLAYER_SPECIALIZATION_CHANGED)
function ns.Display.InvalidateSpecCache()
  cachedCurrentSpec = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BAR VISIBILITY CACHE
-- Track computed visibility per bar to skip recalculation every frame
-- ═══════════════════════════════════════════════════════════════════════════
local barVisibilityCache = {}  -- [barNumber] = { visible = bool, version = number }
local visibilityCacheVersion = 0

-- Invalidate visibility cache (call on combat change, spec change, settings change)
function ns.Display.InvalidateVisibilityCache(barNumber)
  if barNumber then
    barVisibilityCache[barNumber] = nil
  else
    -- Invalidate all
    wipe(barVisibilityCache)
    visibilityCacheVersion = visibilityCacheVersion + 1
  end
end

-- Get cached visibility for a bar (returns nil if not cached)
local function GetCachedVisibility(barNumber)
  local cached = barVisibilityCache[barNumber]
  if cached and cached.version == visibilityCacheVersion then
    return cached.visible
  end
  return nil
end

-- Set cached visibility
local function SetCachedVisibility(barNumber, visible)
  barVisibilityCache[barNumber] = {
    visible = visible,
    version = visibilityCacheVersion
  }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BAR APPEARANCE TRACKING
-- Track when appearance was last applied to skip redundant work
-- Appearance = textures, colors, fonts, positions (changes on settings)
-- Values = bar fill, text content (changes every frame)
-- ═══════════════════════════════════════════════════════════════════════════
local barAppearanceApplied = {}  -- [barNumber] = configVersion

-- Get config version for appearance tracking
local function GetBarConfigVersion(barNumber)
  local db = ns.db and ns.db.char
  local barConfig = db and db.bars and db.bars[barNumber]
  return barConfig and barConfig._configVersion or 0
end

-- Check if appearance needs refresh
local function NeedsAppearanceRefresh(barNumber)
  local currentVersion = GetBarConfigVersion(barNumber)
  local appliedVersion = barAppearanceApplied[barNumber] or -1
  return currentVersion ~= appliedVersion
end

-- Mark appearance as applied
local function MarkAppearanceApplied(barNumber)
  barAppearanceApplied[barNumber] = GetBarConfigVersion(barNumber)
end

-- Force appearance refresh for a bar
function ns.Display.InvalidateBarAppearance(barNumber)
  if barNumber then
    barAppearanceApplied[barNumber] = -1
  else
    -- Invalidate all
    wipe(barAppearanceApplied)
  end
end

-- Increment config version (call when ANY setting changes)
function ns.Display.BumpConfigVersion(barNumber)
  local db = ns.db and ns.db.char
  local barConfig = db and db.bars and db.bars[barNumber]
  if barConfig then
    barConfig._configVersion = (barConfig._configVersion or 0) + 1
    barAppearanceApplied[barNumber] = -1  -- Force refresh
  end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER: Get CENTER-based position for scale-safe anchoring
-- When scaling a frame, it scales from its anchor point. Using CENTER ensures
-- the frame scales uniformly in all directions, preventing position drift.
-- ═══════════════════════════════════════════════════════════════════════════
local function GetCenterBasedPosition(frame)
  if not frame then return nil end
  
  -- Get the frame's center in screen coordinates
  local centerX, centerY = frame:GetCenter()
  if not centerX or not centerY then return nil end
  
  -- Get UIParent center
  local uiCenterX, uiCenterY = UIParent:GetCenter()
  if not uiCenterX or not uiCenterY then return nil end
  
  -- Calculate offset from UIParent center (accounting for effective scale)
  local effectiveScale = frame:GetEffectiveScale()
  local uiScale = UIParent:GetEffectiveScale()
  
  local x = (centerX - uiCenterX) * (effectiveScale / uiScale)
  local y = (centerY - uiCenterY) * (effectiveScale / uiScale)
  
  return {
    point = "CENTER",
    relPoint = "CENTER",
    x = x,
    y = y
  }
end

-- ===================================================================
-- CREATE BAR FRAME FOR SPECIFIC BAR NUMBER
-- ===================================================================
local function CreateBarFrame(barNumber)
  local frame = CreateFrame("Frame", "ArcUIBarFrame" .. barNumber, UIParent)
  frame:SetSize(200, 20)
  frame:SetPoint("CENTER", 0, 200 - ((barNumber - 1) * 30))
  frame:SetMovable(true)
  frame:EnableMouse(false)
  frame:SetClampedToScreen(true)
  frame:Hide()  -- Start hidden, UpdateBar will show if appropriate
  frame.barNumber = barNumber  -- Store for debugging
  
  -- Background
  frame.bg = frame:CreateTexture(nil, "BACKGROUND")
  frame.bg:SetAllPoints()
  frame.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
  frame.bg:SetSnapToPixelGrid(false)
  frame.bg:SetTexelSnappingBias(0)
  
  -- Status bar (fills frame - padding applied by ApplyAppearance if configured)
  frame.bar = CreateFrame("StatusBar", nil, frame)
  frame.bar:SetAllPoints(frame)  -- No padding by default
  frame.bar:SetMinMaxValues(0, 10)
  frame.bar:SetValue(0)
  frame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  frame.bar:SetStatusBarColor(0, 0.5, 1, 1)
  -- Note: SetRotatesTexture is set in ApplyAppearance when orientation is known
  
  -- Prevent pixel snapping on StatusBar texture for crisp rendering
  local barTexture = frame.bar:GetStatusBarTexture()
  if barTexture then
    barTexture:SetSnapToPixelGrid(false)
    barTexture:SetTexelSnappingBias(0)
  end
  
  -- Background (child of statusbar, layer BACKGROUND)
  -- This is hidden because we use frame.bg instead for consistent background across all modes
  frame.bar.bg = frame.bar:CreateTexture(nil, "BACKGROUND")
  frame.bar.bg:SetAllPoints(frame.bar)
  frame.bar.bg:SetColorTexture(0, 0, 0, 0)  -- Transparent
  frame.bar.bg:SetSnapToPixelGrid(false)
  frame.bar.bg:SetTexelSnappingBias(0)
  frame.bar.bg:Hide()
  
  -- TICK OVERLAY FRAME - sits above fill bars (level updated by ApplyAppearance)
  frame.tickOverlay = CreateFrame("Frame", nil, frame)
  frame.tickOverlay:SetAllPoints(frame)
  frame.tickOverlay:SetFrameLevel(frame:GetFrameLevel() + 22)
  
  -- TRACKING FAIL OVERLAY - red background with "Tracking Failed" text
  -- Uses HIGH strata to appear above all bar elements including text frames
  frame.trackingFailOverlay = CreateFrame("Frame", nil, frame)
  frame.trackingFailOverlay:SetAllPoints(frame)
  frame.trackingFailOverlay:SetFrameStrata("HIGH")
  frame.trackingFailOverlay:SetFrameLevel(100)
  frame.trackingFailOverlay:Hide()
  
  frame.trackingFailOverlay.bg = frame.trackingFailOverlay:CreateTexture(nil, "BACKGROUND")
  frame.trackingFailOverlay.bg:SetAllPoints()
  frame.trackingFailOverlay.bg:SetColorTexture(0.6, 0, 0, 0.5)  -- Dark red, semi-transparent
  
  frame.trackingFailOverlay.text = frame.trackingFailOverlay:CreateFontString(nil, "OVERLAY")
  frame.trackingFailOverlay.text:SetPoint("CENTER")
  frame.trackingFailOverlay.text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
  frame.trackingFailOverlay.text:SetText("Tracking Failed")
  frame.trackingFailOverlay.text:SetTextColor(1, 1, 1, 1)
  
  -- MISSING SETUP OVERLAY - yellow background with "Missing Setup" text
  -- Shows when bar is enabled but no tracking configured
  frame.missingSetupOverlay = CreateFrame("Frame", nil, frame)
  frame.missingSetupOverlay:SetAllPoints(frame)
  frame.missingSetupOverlay:SetFrameStrata("HIGH")
  frame.missingSetupOverlay:SetFrameLevel(100)
  frame.missingSetupOverlay:Hide()
  
  frame.missingSetupOverlay.bg = frame.missingSetupOverlay:CreateTexture(nil, "BACKGROUND")
  frame.missingSetupOverlay.bg:SetAllPoints()
  frame.missingSetupOverlay.bg:SetColorTexture(0.6, 0.5, 0, 0.5)  -- Dark yellow, semi-transparent
  
  frame.missingSetupOverlay.text = frame.missingSetupOverlay:CreateFontString(nil, "OVERLAY")
  frame.missingSetupOverlay.text:SetPoint("CENTER")
  frame.missingSetupOverlay.text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
  frame.missingSetupOverlay.text:SetText("Missing Setup")
  frame.missingSetupOverlay.text:SetTextColor(1, 1, 0.2, 1)  -- Yellow text
  
  -- Border textures (4 separate textures for pixel-perfect borders - no centered edge issues)
  -- This approach gives precise control unlike BackdropTemplate which centers edges
  frame.barBorderFrame = CreateFrame("Frame", nil, frame.tickOverlay)
  frame.barBorderFrame:SetAllPoints(frame)
  frame.barBorderFrame:SetFrameLevel(frame:GetFrameLevel() + 23)
  
  frame.barBorderFrame.top = frame.barBorderFrame:CreateTexture(nil, "OVERLAY")
  frame.barBorderFrame.top:SetSnapToPixelGrid(false)
  frame.barBorderFrame.top:SetTexelSnappingBias(0)
  
  frame.barBorderFrame.bottom = frame.barBorderFrame:CreateTexture(nil, "OVERLAY")
  frame.barBorderFrame.bottom:SetSnapToPixelGrid(false)
  frame.barBorderFrame.bottom:SetTexelSnappingBias(0)
  
  frame.barBorderFrame.left = frame.barBorderFrame:CreateTexture(nil, "OVERLAY")
  frame.barBorderFrame.left:SetSnapToPixelGrid(false)
  frame.barBorderFrame.left:SetTexelSnappingBias(0)
  
  frame.barBorderFrame.right = frame.barBorderFrame:CreateTexture(nil, "OVERLAY")
  frame.barBorderFrame.right:SetSnapToPixelGrid(false)
  frame.barBorderFrame.right:SetTexelSnappingBias(0)
  
  frame.barBorderFrame:Hide()  -- Hidden by default
  
  -- Tick marks (on tick overlay frame with OVERLAY layer)
  frame.tickMarks = {}
  for i = 1, 100 do
    local tick = frame.tickOverlay:CreateLine(nil, "OVERLAY")
    tick:SetDrawLayer("OVERLAY", 7)  -- High sublevel
    tick:SetColorTexture(0, 0, 0, 1)
    tick:SetThickness(1)
    tick:Hide()
    frame.tickMarks[i] = tick
  end
  
  -- Drag functionality + bar selection + right-click to edit
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not IsShiftKeyDown() then
      local barConfig = ns.API.GetBarConfig(barNumber)
      if barConfig and barConfig.display.barMovable then
        -- Bar is movable - allow dragging
        self:StartMoving()
      else
        -- Bar not movable - select this bar for configuration
        ns.API.SetSelectedBar(barNumber)
      end
    end
  end)
  
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and not IsShiftKeyDown() then
      self:StopMovingOrSizing()
      local barConfig = ns.API.GetBarConfig(barNumber)
      if barConfig then
        -- Always save CENTER-based position for scale-safe anchoring
        -- This ensures scaling doesn't cause position drift
        local centerPos = GetCenterBasedPosition(self)
        if centerPos then
          barConfig.display.barPosition = centerPos
        else
          -- Fallback if center calculation fails
          local point, _, relPoint, x, y = self:GetPoint()
          barConfig.display.barPosition = {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y
          }
        end
      end
    elseif button == "RightButton" or (button == "LeftButton" and IsShiftKeyDown()) then
      -- Debug: verify barNumber in closure matches frame's stored barNumber
      if ns.devMode then
        print(string.format("|cff00FFFF[ArcUI Debug]|r Bar right-clicked: closure barNumber=%d, frame.barNumber=%s, frame name=%s", 
          barNumber, tostring(self.barNumber), self:GetName() or "unnamed"))
      end
      -- Open options and select this bar
      if ns.Display.OpenOptionsForBar then
        ns.Display.OpenOptionsForBar("buff", barNumber)
      end
    end
  end)
  
  -- Delete button (small red X in corner, only visible when options panel is open)
  frame.deleteButton = CreateFrame("Button", nil, frame)
  frame.deleteButton:SetSize(12, 12)
  frame.deleteButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  -- Must be above tickOverlay (which is at +100) to be visible
  frame.deleteButton:SetFrameLevel(frame:GetFrameLevel() + 150)
  
  frame.deleteButton.text = frame.deleteButton:CreateFontString(nil, "OVERLAY")
  frame.deleteButton.text:SetPoint("CENTER", 0, 0)
  frame.deleteButton.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  frame.deleteButton.text:SetText("x")
  frame.deleteButton.text:SetTextColor(0.8, 0.2, 0.2, 1)
  
  frame.deleteButton:SetScript("OnEnter", function(self)
    self.text:SetTextColor(1, 0.3, 0.3, 1)
  end)
  
  frame.deleteButton:SetScript("OnLeave", function(self)
    self.text:SetTextColor(0.8, 0.2, 0.2, 1)
  end)
  
  frame.deleteButton:SetScript("OnClick", function(self)
    if ShowDeleteConfirmation then
      ShowDeleteConfirmation(barNumber)
    end
  end)
  
  frame.deleteButton:Hide()  -- Hidden by default, shown when options panel opens
  
  -- When frame is shown, check if delete buttons should be visible
  frame:SetScript("OnShow", function(self)
    if deleteButtonsVisible and self.deleteButton then
      self.deleteButton:Show()
    end
  end)
  
  frame:Hide()
  return frame
end

-- ===================================================================
-- CREATE TEXT FRAME FOR SPECIFIC BAR NUMBER
-- ===================================================================
local function CreateTextFrame(barNumber)
  local frame = CreateFrame("Frame", "ArcUITextFrame" .. barNumber, UIParent)
  frame:SetSize(100, 40)
  frame:SetPoint("CENTER", 0, 230 - ((barNumber - 1) * 30))
  frame:SetMovable(true)
  frame:EnableMouse(false)
  frame:SetClampedToScreen(true)
  frame:Hide()  -- Start hidden, UpdateBar will show if appropriate
  
  -- Use MEDIUM strata so we don't overlap Blizzard UI panels (talents, settings, etc.)
  -- Frame level 150 to be above tick overlay (~101) but still in MEDIUM strata
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(250)
  
  frame.text = frame:CreateFontString(nil, "OVERLAY")
  frame.text:SetPoint("CENTER")
  frame.text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
  frame.text:SetText("0")
  frame.text:SetTextColor(1, 1, 1, 1)
  frame.text:SetShadowOffset(2, -2)  -- Add shadow like old addon
  frame.text:SetShadowColor(0, 0, 0, 1)
  
  -- Drag functionality
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      self:StartMoving()
    end
  end)
  
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      self:StopMovingOrSizing()
      local barConfig = ns.API.GetBarConfig(barNumber)
      if barConfig then
        local point, _, relPoint, x, y = self:GetPoint()
        barConfig.display.textPosition = {
          point = point,
          relPoint = relPoint,
          x = x,
          y = y
        }
      end
    elseif button == "RightButton" then
      if ns.Display.OpenOptionsForBar then
        ns.Display.OpenOptionsForBar("buff", barNumber)
      end
    end
  end)
  
  frame:Hide()
  return frame
end

-- ===================================================================
-- CREATE DURATION TEXT FRAME FOR SPECIFIC BAR NUMBER
-- ===================================================================
local function CreateDurationFrame(barNumber)
  local frame = CreateFrame("Frame", "ArcUIDurationFrame" .. barNumber, UIParent)
  frame:SetSize(80, 30)
  frame:SetPoint("CENTER", 0, 200 - ((barNumber - 1) * 30))
  frame:SetMovable(true)
  frame:EnableMouse(false)
  frame:SetClampedToScreen(true)
  frame:Hide()  -- Start hidden, UpdateBar will show if appropriate
  
  -- Use MEDIUM strata so we don't overlap Blizzard UI panels
  -- Frame level 150 to be above tick overlay but still in MEDIUM strata
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(250)
  
  frame.text = frame:CreateFontString(nil, "OVERLAY")
  frame.text:SetPoint("CENTER")
  frame.text:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
  frame.text:SetText("0")  -- Default to "0"
  frame.text:SetTextColor(1, 1, 1, 1)
  frame.text:SetShadowOffset(2, -2)
  frame.text:SetShadowColor(0, 0, 0, 1)
  
  -- Drag functionality
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      self:StartMoving()
    end
  end)
  
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      self:StopMovingOrSizing()
      local barConfig = ns.API.GetBarConfig(barNumber)
      if barConfig then
        local point, _, relPoint, x, y = self:GetPoint()
        barConfig.display.durationPosition = {
          point = point,
          relPoint = relPoint,
          x = x,
          y = y
        }
      end
    elseif button == "RightButton" then
      if ns.Display.OpenOptionsForBar then
        ns.Display.OpenOptionsForBar("buff", barNumber)
      end
    end
  end)
  
  frame:Hide()
  return frame
end

-- ===================================================================
-- CREATE NAME TEXT FRAME FOR SPECIFIC BAR NUMBER (for duration bars)
-- ===================================================================
local function CreateNameFrame(barNumber)
  local frame = CreateFrame("Frame", "ArcUINameFrame" .. barNumber, UIParent)
  frame:SetSize(150, 24)
  frame:SetPoint("CENTER", 0, 220 - ((barNumber - 1) * 30))
  frame:SetMovable(true)
  frame:EnableMouse(false)
  frame:SetClampedToScreen(true)
  frame:Hide()  -- Start hidden, UpdateBar will show if appropriate
  
  -- Use MEDIUM strata so we don't overlap Blizzard UI panels
  -- Frame level 150 to be above tick overlay but still in MEDIUM strata
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(250)
  
  frame.text = frame:CreateFontString(nil, "OVERLAY")
  frame.text:SetPoint("CENTER")
  frame.text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
  frame.text:SetText("")
  frame.text:SetTextColor(1, 1, 1, 1)
  frame.text:SetShadowOffset(1, -1)
  frame.text:SetShadowColor(0, 0, 0, 1)
  
  -- Drag functionality
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      self:StartMoving()
    end
  end)
  
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      self:StopMovingOrSizing()
      local barConfig = ns.API.GetBarConfig(barNumber)
      if barConfig then
        local point, _, relPoint, x, y = self:GetPoint()
        barConfig.display.namePosition = {
          point = point,
          relPoint = relPoint,
          x = x,
          y = y
        }
      end
    elseif button == "RightButton" then
      if ns.Display.OpenOptionsForBar then
        ns.Display.OpenOptionsForBar("buff", barNumber)
      end
    end
  end)
  
  frame:Hide()
  return frame
end

-- ===================================================================
-- CREATE BAR ICON FRAME FOR SPECIFIC BAR NUMBER (icon alongside bar)
-- ===================================================================
local function CreateBarIconFrame(barNumber)
  local frame = CreateFrame("Frame", "ArcUIBarIconFrame" .. barNumber, UIParent)
  frame:SetSize(32, 32)
  frame:SetPoint("CENTER", 0, 200 - ((barNumber - 1) * 30))
  frame:SetMovable(true)
  frame:EnableMouse(false)
  frame:SetClampedToScreen(true)
  frame:Hide()  -- Start hidden, UpdateBar will show if appropriate
  
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(250)
  
  -- Background for border
  frame.background = frame:CreateTexture(nil, "BACKGROUND")
  frame.background:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
  frame.background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
  frame.background:SetColorTexture(0, 0, 0, 1)
  frame.background:SetSnapToPixelGrid(false)
  frame.background:SetTexelSnappingBias(0)
  
  -- Icon texture
  frame.icon = frame:CreateTexture(nil, "ARTWORK")
  frame.icon:SetAllPoints(frame)
  frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  frame.icon:SetSnapToPixelGrid(false)
  frame.icon:SetTexelSnappingBias(0)
  
  -- Drag functionality
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      self:StartMoving()
    end
  end)
  
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      self:StopMovingOrSizing()
      local barConfig = ns.API.GetBarConfig(barNumber)
      if barConfig then
        local point, _, relPoint, x, y = self:GetPoint()
        barConfig.display.barIconPosition = {
          point = point,
          relPoint = relPoint,
          x = x,
          y = y
        }
      end
    elseif button == "RightButton" then
      if ns.Display.OpenOptionsForBar then
        ns.Display.OpenOptionsForBar("buff", barNumber)
      end
    end
  end)
  
  frame:Hide()
  return frame
end

-- ===================================================================
-- CREATE ICON FRAME FOR SPECIFIC BAR NUMBER
-- v2.7.0: Added cooldown swipe frame, fixed frame levels, added text caching
-- ===================================================================
local function CreateIconFrame(barNumber)
  local frame = CreateFrame("Frame", "ArcUIIconFrame" .. barNumber, UIParent)
  frame:SetSize(48, 48)
  frame:SetPoint("CENTER", 0, 260 - ((barNumber - 1) * 60))
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:Hide()  -- Start hidden, UpdateBar will show if appropriate
  
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(250)
  
  -- Background (behind icon for border effect) - sublevel -8 (lowest in BACKGROUND)
  frame.background = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  frame.background:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
  frame.background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
  frame.background:SetColorTexture(0, 0, 0, 1)
  frame.background:SetSnapToPixelGrid(false)
  frame.background:SetTexelSnappingBias(0)
  
  -- Icon texture (on top of background) - sublevel -1 in ARTWORK
  frame.icon = frame:CreateTexture(nil, "ARTWORK", nil, -1)
  frame.icon:SetAllPoints(frame)
  frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- Trim default icon borders
  frame.icon:SetSnapToPixelGrid(false)
  frame.icon:SetTexelSnappingBias(0)
  
  -- ═══════════════════════════════════════════════════════════════════
  -- COOLDOWN SWIPE FRAME (for custom cooldowns)
  -- Frame level = icon level + 1 (above icon, below text overlays)
  -- ═══════════════════════════════════════════════════════════════════
  frame.cooldown = CreateFrame("Cooldown", "ArcUIIconCooldown" .. barNumber, frame, "CooldownFrameTemplate")
  frame.cooldown:SetAllPoints(frame)
  frame.cooldown:SetFrameLevel(frame:GetFrameLevel() + 1)
  frame.cooldown:SetDrawEdge(true)
  frame.cooldown:SetDrawBling(true)
  frame.cooldown:SetDrawSwipe(true)
  frame.cooldown:SetHideCountdownNumbers(true)  -- We handle our own duration text
  frame.cooldown:SetSwipeColor(0, 0, 0, 0.7)
  frame.cooldown:Hide()  -- Hidden by default, shown only for custom cooldowns
  
  -- TRACKING FAIL OVERLAY - red background with "Tracking Failed" text
  -- Frame level +10 to appear above cooldown swipe
  frame.trackingFailOverlay = CreateFrame("Frame", nil, frame)
  frame.trackingFailOverlay:SetAllPoints(frame)
  frame.trackingFailOverlay:SetFrameStrata("HIGH")
  frame.trackingFailOverlay:SetFrameLevel(frame:GetFrameLevel() + 10)
  frame.trackingFailOverlay:Hide()
  
  frame.trackingFailOverlay.bg = frame.trackingFailOverlay:CreateTexture(nil, "BACKGROUND")
  frame.trackingFailOverlay.bg:SetAllPoints()
  frame.trackingFailOverlay.bg:SetColorTexture(0.6, 0, 0, 0.5)  -- Dark red, semi-transparent
  
  frame.trackingFailOverlay.text = frame.trackingFailOverlay:CreateFontString(nil, "OVERLAY")
  frame.trackingFailOverlay.text:SetPoint("CENTER")
  frame.trackingFailOverlay.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  frame.trackingFailOverlay.text:SetText("Tracking\nFailed")
  frame.trackingFailOverlay.text:SetTextColor(1, 1, 1, 1)
  frame.trackingFailOverlay.text:SetJustifyH("CENTER")
  
  -- MISSING SETUP OVERLAY - yellow background with "Missing Setup" text
  -- Shows when bar is enabled but no tracking configured
  frame.missingSetupOverlay = CreateFrame("Frame", nil, frame)
  frame.missingSetupOverlay:SetAllPoints(frame)
  frame.missingSetupOverlay:SetFrameStrata("HIGH")
  frame.missingSetupOverlay:SetFrameLevel(frame:GetFrameLevel() + 10)
  frame.missingSetupOverlay:Hide()
  
  frame.missingSetupOverlay.bg = frame.missingSetupOverlay:CreateTexture(nil, "BACKGROUND")
  frame.missingSetupOverlay.bg:SetAllPoints()
  frame.missingSetupOverlay.bg:SetColorTexture(0.6, 0.5, 0, 0.5)  -- Dark yellow, semi-transparent
  
  frame.missingSetupOverlay.text = frame.missingSetupOverlay:CreateFontString(nil, "OVERLAY")
  frame.missingSetupOverlay.text:SetPoint("CENTER")
  frame.missingSetupOverlay.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  frame.missingSetupOverlay.text:SetText("Missing\nSetup")
  frame.missingSetupOverlay.text:SetTextColor(1, 1, 0.2, 1)  -- Yellow text
  frame.missingSetupOverlay.text:SetJustifyH("CENTER")
  
  -- Stacks text (top right by default) - sublevel 7 (highest in OVERLAY, above cooldown swipe)
  frame.stacks = frame:CreateFontString(nil, "OVERLAY", nil, 7)
  frame.stacks:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
  frame.stacks:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
  frame.stacks:SetText("")
  frame.stacks:SetTextColor(1, 1, 1, 1)
  frame.stacks:SetShadowOffset(1, -1)
  frame.stacks:SetShadowColor(0, 0, 0, 1)
  
  -- Text caching to prevent flickering
  frame.lastStacksText = ""
  frame.lastDurationText = ""
  
  -- Separate movable stacks frame for FREE mode
  -- Frame level +20 to be above everything
  frame.stacksFrame = CreateFrame("Frame", "ArcUIIconStacksFrame" .. barNumber, UIParent)
  frame.stacksFrame:SetSize(40, 24)
  frame.stacksFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)  -- Default: center of icon
  frame.stacksFrame:SetMovable(true)
  frame.stacksFrame:EnableMouse(true)
  frame.stacksFrame:SetClampedToScreen(true)
  frame.stacksFrame:SetFrameStrata("MEDIUM")
  frame.stacksFrame:SetFrameLevel(frame:GetFrameLevel() + 20)
  
  -- Free stacks text on the movable frame
  frame.stacksFrame.text = frame.stacksFrame:CreateFontString(nil, "OVERLAY", nil, 7)
  frame.stacksFrame.text:SetPoint("CENTER")
  frame.stacksFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
  frame.stacksFrame.text:SetText("")
  frame.stacksFrame.text:SetTextColor(1, 1, 1, 1)
  frame.stacksFrame.text:SetShadowOffset(1, -1)
  frame.stacksFrame.text:SetShadowColor(0, 0, 0, 1)
  
  -- Text caching for free stacks frame
  frame.stacksFrame.lastText = ""
  
  -- Drag functionality + right-click to edit (same pattern as bar frames)
  frame.stacksFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      self:StartMoving()
    end
  end)
  
  frame.stacksFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      self:StopMovingOrSizing()
      local barConfig = ns.API.GetBarConfig(barNumber)
      if barConfig then
        -- Always save CENTER-based position for scale-safe anchoring
        local centerPos = GetCenterBasedPosition(self)
        if centerPos then
          barConfig.display.iconStackPosition = centerPos
        else
          local point, _, relPoint, x, y = self:GetPoint()
          barConfig.display.iconStackPosition = {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y
          }
        end
      end
    elseif button == "RightButton" then
      -- Open options and select this bar
      if ns.Display.OpenOptionsForBar then
        ns.Display.OpenOptionsForBar("buff", barNumber)
      end
    end
  end)
  
  frame.stacksFrame:Hide()
  
  -- Duration text (center) - sublevel 7 (highest in OVERLAY)
  frame.duration = frame:CreateFontString(nil, "OVERLAY", nil, 7)
  frame.duration:SetPoint("CENTER", frame, "CENTER", 0, 0)
  frame.duration:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
  frame.duration:SetText("")
  frame.duration:SetTextColor(1, 1, 1, 1)
  frame.duration:SetShadowOffset(1, -1)
  frame.duration:SetShadowColor(0, 0, 0, 1)
  
  -- Delete button (small red X in corner, only visible when options panel is open)
  -- Frame level +50 to be above everything
  frame.deleteButton = CreateFrame("Button", nil, frame)
  frame.deleteButton:SetSize(12, 12)
  frame.deleteButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  frame.deleteButton:SetFrameLevel(frame:GetFrameLevel() + 50)
  
  frame.deleteButton.text = frame.deleteButton:CreateFontString(nil, "OVERLAY")
  frame.deleteButton.text:SetPoint("CENTER", 0, 0)
  frame.deleteButton.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  frame.deleteButton.text:SetText("x")
  frame.deleteButton.text:SetTextColor(0.8, 0.2, 0.2, 1)
  
  frame.deleteButton:SetScript("OnEnter", function(self)
    self.text:SetTextColor(1, 0.3, 0.3, 1)
  end)
  
  frame.deleteButton:SetScript("OnLeave", function(self)
    self.text:SetTextColor(0.8, 0.2, 0.2, 1)
  end)
  
  frame.deleteButton:SetScript("OnClick", function(self)
    if ShowDeleteConfirmation then
      ShowDeleteConfirmation(barNumber)
    end
  end)
  
  frame.deleteButton:Hide()  -- Hidden by default, shown when options panel opens
  
  -- When frame is shown, check if delete buttons should be visible
  frame:SetScript("OnShow", function(self)
    if deleteButtonsVisible and self.deleteButton then
      self.deleteButton:Show()
    end
  end)
  
  -- Drag functionality and click-to-edit
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not IsShiftKeyDown() then
      self:StartMoving()
    end
  end)
  
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and not IsShiftKeyDown() then
      self:StopMovingOrSizing()
      local barConfig = ns.API.GetBarConfig(barNumber)
      if barConfig then
        -- Always save CENTER-based position for scale-safe anchoring
        local centerPos = GetCenterBasedPosition(self)
        if centerPos then
          barConfig.display.iconPosition = centerPos
        else
          local point, _, relPoint, x, y = self:GetPoint()
          barConfig.display.iconPosition = {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y
          }
        end
      end
    elseif button == "RightButton" or (button == "LeftButton" and IsShiftKeyDown()) then
      -- Debug: verify barNumber in closure
      if ns.devMode then
        print(string.format("|cff00FFFF[ArcUI Debug]|r Icon right-clicked: closure barNumber=%d, frame name=%s", 
          barNumber, self:GetName() or "unnamed"))
      end
      -- Open options and select this bar
      if ns.Display.OpenOptionsForBar then
        ns.Display.OpenOptionsForBar("buff", barNumber)
      end
    end
  end)
  
  frame:Hide()
  return frame
end

-- ===================================================================
-- CREATE MULTI-ICON FRAME (StatusBar-based icon for each stack)
-- Each "icon" is a StatusBar where fill texture = buff icon
-- SetMinMaxValues(stackNum-1, stackNum) so it fills when stacks >= stackNum
-- ===================================================================
local function CreateMultiIconFrame(barNumber, stackNum)
  local frameName = "ArcUIMultiIcon" .. barNumber .. "_" .. stackNum
  local frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
  frame:SetSize(48, 48)
  frame:SetPoint("CENTER", UIParent, "CENTER", (stackNum - 1) * 52, 0)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(100 + stackNum)
  frame:Hide()  -- Start hidden, UpdateBar will show if appropriate
  
  -- Solid color background (behind desaturated icon)
  frame.solidBg = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
  frame.solidBg:SetAllPoints()
  frame.solidBg:SetColorTexture(0.05, 0.05, 0.05, 0.9)
  frame.solidBg:SetSnapToPixelGrid(false)
  frame.solidBg:SetTexelSnappingBias(0)
  
  -- Desaturated icon background (shows when stack not filled)
  frame.desatBg = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
  frame.desatBg:SetAllPoints()
  frame.desatBg:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  frame.desatBg:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  frame.desatBg:SetDesaturated(true)
  frame.desatBg:SetVertexColor(0.4, 0.4, 0.4, 1)  -- Darken the desaturated icon
  frame.desatBg:SetSnapToPixelGrid(false)
  frame.desatBg:SetTexelSnappingBias(0)
  
  -- StatusBar that acts as the icon fill
  -- When stacks >= stackNum, this bar will be full (showing the icon)
  -- When stacks < stackNum, this bar will be empty (showing desaturated background)
  frame.iconBar = CreateFrame("StatusBar", frameName .. "Bar", frame)
  frame.iconBar:SetAllPoints()
  frame.iconBar:SetMinMaxValues(stackNum - 1, stackNum)
  frame.iconBar:SetValue(0)
  frame.iconBar:SetOrientation("HORIZONTAL")  -- Changed from VERTICAL - HORIZONTAL works!
  -- Note: SetRotatesTexture not needed for icon bars
  
  -- The icon texture as the fill - DON'T use SetTexCoord on StatusBar texture
  frame.iconBar:SetStatusBarTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  frame.iconBar:SetStatusBarColor(1, 1, 1, 1)  -- Ensure white color
  
  -- Prevent pixel snapping on StatusBar texture
  local iconBarTex = frame.iconBar:GetStatusBarTexture()
  if iconBarTex then
    iconBarTex:SetSnapToPixelGrid(false)
    iconBarTex:SetTexelSnappingBias(0)
  end
  
  -- Track what texture is currently set (to avoid re-setting during combat)
  frame.currentTextureID = nil
  
  -- Border frame (separate so it's on top)
  frame.borderFrame = CreateFrame("Frame", nil, frame)
  frame.borderFrame:SetAllPoints()
  frame.borderFrame:SetFrameLevel(frame:GetFrameLevel() + 5)
  
  frame.border = frame.borderFrame:CreateTexture(nil, "OVERLAY")
  frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
  frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
  frame.border:SetSnapToPixelGrid(false)
  frame.border:SetTexelSnappingBias(0)
  frame.border:SetColorTexture(0, 0, 0, 1)
  frame.border:SetDrawLayer("OVERLAY", -1)
  
  -- Duration text (only shown on one of the icons based on config)
  frame.duration = frame.borderFrame:CreateFontString(nil, "OVERLAY")
  frame.duration:SetPoint("BOTTOM", frame, "BOTTOM", 0, 2)
  frame.duration:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
  frame.duration:SetText("")
  frame.duration:SetTextColor(1, 1, 1, 1)
  frame.duration:Hide()
  
  -- Drag handlers + right-click to edit (same pattern as bar frames)
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      -- Always allow drag for multi-icon frames (same as aura bars)
      self:StartMoving()
    end
  end)
  
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      self:StopMovingOrSizing()
      -- Save position
      local barConfig = ns.API.GetBarConfig(barNumber)
      if barConfig then
        -- Always save CENTER-based position for scale-safe anchoring
        local centerPos = GetCenterBasedPosition(self)
        if not barConfig.display.iconMultiPositions then
          barConfig.display.iconMultiPositions = {}
        end
        if centerPos then
          barConfig.display.iconMultiPositions[stackNum] = centerPos
        else
          local point, _, relPoint, x, y = self:GetPoint()
          barConfig.display.iconMultiPositions[stackNum] = {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y
          }
        end
      end
    elseif button == "RightButton" then
      -- Open options and select this bar
      if ns.Display.OpenOptionsForBar then
        ns.Display.OpenOptionsForBar("buff", barNumber)
      end
    end
  end)
  
  frame.stackNum = stackNum
  frame.barNumber = barNumber
  frame:Hide()
  return frame
end

-- Storage for multi-icon frames: multiIconFrames[barNumber][stackNum] = frame
local multiIconFrames = {}

-- Get or create multi-icon frames for a bar
local function GetMultiIconFrames(barNumber, maxStacks)
  if not multiIconFrames[barNumber] then
    multiIconFrames[barNumber] = {}
  end
  
  -- Create frames for each stack position
  for i = 1, maxStacks do
    if not multiIconFrames[barNumber][i] then
      multiIconFrames[barNumber][i] = CreateMultiIconFrame(barNumber, i)
    end
  end
  
  return multiIconFrames[barNumber]
end

-- Hide all multi-icon frames for a bar
local function HideMultiIconFrames(barNumber)
  if multiIconFrames[barNumber] then
    for i, frame in pairs(multiIconFrames[barNumber]) do
      SafeHide(frame)
    end
  end
end

-- ===================================================================
-- GET OR CREATE FRAMES FOR BAR
-- ===================================================================
local function GetBarFrames(barNumber)
  if not barFrames[barNumber] then
    barFrames[barNumber] = {
      barFrame = CreateBarFrame(barNumber),
      textFrame = CreateTextFrame(barNumber),
      durationFrame = CreateDurationFrame(barNumber),
      iconFrame = CreateIconFrame(barNumber),
      nameFrame = CreateNameFrame(barNumber),
      barIconFrame = CreateBarIconFrame(barNumber)
    }
  end
  -- Create missing frames for existing bars
  if not barFrames[barNumber].durationFrame then
    barFrames[barNumber].durationFrame = CreateDurationFrame(barNumber)
  end
  if not barFrames[barNumber].iconFrame then
    barFrames[barNumber].iconFrame = CreateIconFrame(barNumber)
  end
  if not barFrames[barNumber].nameFrame then
    barFrames[barNumber].nameFrame = CreateNameFrame(barNumber)
  end
  if not barFrames[barNumber].barIconFrame then
    barFrames[barNumber].barIconFrame = CreateBarIconFrame(barNumber)
  end
  return barFrames[barNumber].barFrame, barFrames[barNumber].textFrame, barFrames[barNumber].durationFrame, barFrames[barNumber].iconFrame, barFrames[barNumber].nameFrame, barFrames[barNumber].barIconFrame
end

-- ===================================================================
-- CUSTOM TRACKING SMOOTH UPDATE SYSTEM
-- For custom auras/cooldowns, we can smoothly animate because we have
-- full control over the duration values (not secret values from CDM)
-- ===================================================================
local customTrackingState = {}  -- [barNumber] = { active, expirationTime, maxDuration, stacks, maxStacks, iconTexture, isCustom }

-- Set up smooth custom tracking for a bar
function ns.Display.SetCustomTrackingState(barNumber, state)
  if not state then
    -- Clear custom tracking
    customTrackingState[barNumber] = nil
    return
  end
  
  customTrackingState[barNumber] = {
    active = state.active or false,
    expirationTime = state.expirationTime or 0,
    maxDuration = state.maxDuration or 10,
    stacks = state.stacks or 0,
    maxStacks = state.maxStacks or 10,
    iconTexture = state.iconTexture,
    isCustom = true,
    useDurationBar = state.useDurationBar or false,
    -- For cooldowns
    charges = state.charges,
    maxCharges = state.maxCharges,
    rechargeEnd = state.rechargeEnd,
    rechargeDuration = state.rechargeDuration,  -- For cooldown swipe calculation
  }
end

-- Get custom tracking state for a bar
function ns.Display.GetCustomTrackingState(barNumber)
  return customTrackingState[barNumber]
end

-- Clear custom tracking for a bar
function ns.Display.ClearCustomTrackingState(barNumber)
  customTrackingState[barNumber] = nil
end

-- Smooth update frame - handles all custom tracking bars
local smoothUpdateFrame = CreateFrame("Frame")
local SMOOTH_UPDATE_INTERVAL = 0.03  -- ~30fps for smooth animation
local smoothUpdateElapsed = 0

smoothUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
  smoothUpdateElapsed = smoothUpdateElapsed + elapsed
  if smoothUpdateElapsed < SMOOTH_UPDATE_INTERVAL then return end
  smoothUpdateElapsed = 0
  
  -- Skip updates when preview mode is active (prevents flickering)
  if previewMode and IsOptionsOpen() then return end
  
  local currentTime = GetTime()
  
  for barNumber, state in pairs(customTrackingState) do
    if state and state.isCustom then
      local barConfig = ns.API and ns.API.GetBarConfig(barNumber)
      if barConfig and barConfig.tracking.enabled then
        local frames = barFrames[barNumber]
        if frames then
          local barFrame = frames.barFrame
          local textFrame = frames.textFrame
          local durationFrame = frames.durationFrame
          local iconFrame = frames.iconFrame
          
          -- Calculate current duration
          local duration = 0
          local isActive = state.active
          
          if state.expirationTime and state.expirationTime > 0 then
            duration = state.expirationTime - currentTime
            if duration < 0 then
              duration = 0
              isActive = false
            end
          end
          
          -- For cooldowns, calculate recharge remaining
          local cooldownRemaining = 0
          if state.rechargeEnd and state.rechargeEnd > 0 then
            cooldownRemaining = state.rechargeEnd - currentTime
            if cooldownRemaining < 0 then cooldownRemaining = 0 end
          end
          
          local displayType = barConfig.display.displayType or "bar"
          local cfg = barConfig.display
          local trackType = barConfig.tracking.trackType
          
          if displayType == "icon" then
            -- ═══════════════════════════════════════════════════════════════════
            -- ICON MODE - Update icon stacks, duration text, cooldown swipe
            -- v2.7.0: Added cooldown swipe, desaturation, text caching
            -- ═══════════════════════════════════════════════════════════════════
            if iconFrame then
              -- ─────────────────────────────────────────────────────────────────
              -- COOLDOWN SWIPE (for custom cooldowns only)
              -- ─────────────────────────────────────────────────────────────────
              if trackType == "customCooldown" and iconFrame.cooldown then
                if cfg.iconShowCooldownSwipe and cooldownRemaining > 0 and state.rechargeEnd then
                  -- Calculate start time from recharge end
                  local rechargeDuration = state.rechargeDuration or 10  -- fallback
                  local startTime = state.rechargeEnd - rechargeDuration
                  
                  iconFrame.cooldown:SetReverse(cfg.iconCooldownReverse or false)
                  iconFrame.cooldown:SetDrawEdge(cfg.iconCooldownDrawEdge ~= false)
                  iconFrame.cooldown:SetDrawBling(cfg.iconCooldownDrawBling ~= false)
                  iconFrame.cooldown:SetCooldown(startTime, rechargeDuration)
                  iconFrame.cooldown:Show()
                else
                  iconFrame.cooldown:Hide()
                end
                
                -- Desaturate when on cooldown
                if cfg.iconDesaturateOnCooldown and iconFrame.icon then
                  iconFrame.icon:SetDesaturated(cooldownRemaining > 0)
                end
              elseif trackType == "customAura" then
                -- Hide cooldown swipe for auras
                if iconFrame.cooldown then
                  iconFrame.cooldown:Hide()
                end
                
                -- Optional desaturation when aura inactive
                if cfg.iconDesaturateWhenInactive and iconFrame.icon then
                  iconFrame.icon:SetDesaturated(not isActive)
                end
              end
              
              -- ─────────────────────────────────────────────────────────────────
              -- UPDATE STACKS TEXT (with caching to prevent flickering)
              -- ─────────────────────────────────────────────────────────────────
              if cfg.iconShowStacks then
                local stacks = state.stacks or 0
                if state.charges ~= nil then
                  stacks = state.charges
                end
                
                local stackText = iconFrame.stacks
                local cacheRef = iconFrame
                if cfg.iconStackAnchor == "FREE" and iconFrame.stacksFrame then
                  stackText = iconFrame.stacksFrame.text
                  cacheRef = iconFrame.stacksFrame
                end
                
                -- Calculate new text
                local newText = ""
                if isActive and stacks > 0 then
                  newText = tostring(stacks)
                end
                
                -- Only update if changed (prevents flickering)
                local lastKey = (cacheRef == iconFrame) and "lastStacksText" or "lastText"
                if cacheRef[lastKey] ~= newText then
                  stackText:SetText(newText)
                  cacheRef[lastKey] = newText
                end
              end
              
              -- ─────────────────────────────────────────────────────────────────
              -- UPDATE DURATION TEXT (with caching to prevent flickering)
              -- ─────────────────────────────────────────────────────────────────
              if cfg.iconShowDuration then
                local timeRemaining = duration > 0 and duration or cooldownRemaining
                
                -- Calculate new text
                local newText = ""
                if isActive and timeRemaining > 0 then
                  local decimals = cfg.durationDecimals or 1
                  newText = string.format("%." .. decimals .. "f", timeRemaining)
                elseif cfg.durationShowWhenReady and trackType == "customCooldown" and cooldownRemaining == 0 then
                  newText = "Ready"
                end
                
                -- Only update if changed (prevents flickering)
                if iconFrame.lastDurationText ~= newText then
                  iconFrame.duration:SetText(newText)
                  iconFrame.lastDurationText = newText
                end
              end
            end
            
          elseif displayType == "bar" then
            -- ═══════════════════════════════════════════════════════════════════
            -- BAR MODE - Update bar value and text
            -- ═══════════════════════════════════════════════════════════════════
            if state.useDurationBar then
              -- Duration bar mode - bar represents time remaining
              local maxDuration = state.maxDuration or barConfig.tracking.maxDuration or 10
              
              if barFrame.bar then
                barFrame.bar:SetMinMaxValues(0, maxDuration)
                barFrame.bar:SetValue(duration)
              end
              
              -- Update duration text
              if barConfig.display.showDuration and durationFrame then
                if isActive and duration > 0 then
                  local decimals = barConfig.display.durationDecimals or 1
                  durationFrame.text:SetText(string.format("%." .. decimals .. "f", duration))
                  durationFrame:Show()
                else
                  if barConfig.display.durationShowWhenReady then
                    durationFrame.text:SetText("0")
                    durationFrame:Show()
                  else
                    durationFrame:Hide()
                  end
                end
              end
              
              -- Update stacks text
              if barConfig.display.showText and textFrame then
                if isActive and state.stacks and state.stacks > 0 then
                  textFrame.text:SetText(state.stacks)
                else
                  textFrame.text:SetText("")
                end
              end
            else
              -- Stack bar mode - bar represents stacks
              local maxStacks = state.maxStacks or barConfig.tracking.maxStacks or 10
              local stacks = state.stacks or 0
              
              -- For cooldowns, show charges
              if state.charges ~= nil then
                stacks = state.charges
                maxStacks = state.maxCharges or 1
              end
              
              if barFrame.bar then
                barFrame.bar:SetMinMaxValues(0, maxStacks)
                barFrame.bar:SetValue(stacks)
              end
              
              -- Update stacks text
              if barConfig.display.showText and textFrame then
                textFrame.text:SetText(stacks)
              end
              
              -- Update duration text (shows remaining duration or cooldown)
              if barConfig.display.showDuration and durationFrame then
                local timeRemaining = duration > 0 and duration or cooldownRemaining
                if isActive and timeRemaining > 0 then
                  local decimals = barConfig.display.durationDecimals or 1
                  durationFrame.text:SetText(string.format("%." .. decimals .. "f", timeRemaining))
                  durationFrame:Show()
                else
                  if barConfig.display.durationShowWhenReady then
                    durationFrame.text:SetText("0")
                    durationFrame:Show()
                  else
                    durationFrame:Hide()
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end)

-- ===================================================================
-- SHARED: UPDATE TICK MARKS FOR A BAR
-- Called by UpdateBar and UpdateDurationBar to update tick marks
-- ===================================================================
local function UpdateTickMarks(barFrame, barConfig, maxValue, displayMode)
  if not barFrame or not barConfig then return end
  
  local isVertical = (barConfig.display.barOrientation == "vertical")
  
  if barConfig.display.showTickMarks and maxValue > 1 then
    local width = barFrame:GetWidth()
    local height = barFrame:GetHeight()
    local tickMode = barConfig.display.tickMode or "percent"
    local abilityThresholds = barConfig.abilityThresholds
    local tc = barConfig.display.tickColor or {r=0, g=0, b=0, a=1}
    local thickness = barConfig.display.tickThickness or 2
    
    -- For duration mode, force percent mode if "all" was selected (too many ticks otherwise)
    if displayMode == "duration" and tickMode == "all" then
      tickMode = "percent"
    end
    
    -- For folded mode, ticks are based on midpoint (half max)
    local tickMaxValue = maxValue
    if displayMode == "folded" then
      tickMaxValue = math.ceil(maxValue / 2)
    end
    
    -- Determine tick positions
    local tickPositions = {}
    
    if tickMode == "all" then
      -- All mode: one tick per division (maxValue - 1 ticks)
      for i = 1, tickMaxValue - 1 do
        table.insert(tickPositions, i)
      end
    elseif tickMode == "percent" then
      -- Percent mode: ticks at percentage intervals
      local tickPercent = barConfig.display.tickPercent or 10
      local numTicks = math.floor(100 / tickPercent)
      for i = 1, numTicks - 1 do  -- Don't include 100% tick
        local tickVal = tickMaxValue * (i * tickPercent / 100)
        if tickVal > 0 and tickVal < tickMaxValue then
          table.insert(tickPositions, tickVal)
        end
      end
    elseif tickMode == "custom" and abilityThresholds and #abilityThresholds > 0 then
      -- Custom tick positions from abilityThresholds
      local usePercent = barConfig.display.customTicksAsPercent
      for _, tick in ipairs(abilityThresholds) do
        if tick.enabled and tick.cost and tick.cost > 0 then
          local tickVal = tick.cost
          if usePercent then
            -- Interpret cost as percentage
            tickVal = tickMaxValue * tick.cost / 100
          end
          if tickVal > 0 and tickVal < tickMaxValue then
            table.insert(tickPositions, tickVal)
          end
        end
      end
    end
    
    -- Render ticks
    local tickIndex = 1
    for _, tickValue in ipairs(tickPositions) do
      if barFrame.tickMarks and barFrame.tickMarks[tickIndex] then
        if isVertical then
          -- VERTICAL BAR - Horizontal tick marks
          local yPos = -(height * tickValue / tickMaxValue)
          barFrame.tickMarks[tickIndex]:SetStartPoint("TOPLEFT", barFrame.tickOverlay, 0, yPos)
          barFrame.tickMarks[tickIndex]:SetEndPoint("TOPRIGHT", barFrame.tickOverlay, 0, yPos)
        else
          -- HORIZONTAL BAR - Vertical tick marks
          local xPos = width * tickValue / tickMaxValue
          barFrame.tickMarks[tickIndex]:SetStartPoint("TOPLEFT", barFrame.tickOverlay, xPos, 0)
          barFrame.tickMarks[tickIndex]:SetEndPoint("BOTTOMLEFT", barFrame.tickOverlay, xPos, 0)
        end
        -- Use PixelUtil for crisp, uniform tick width
        local pixelThickness = PixelUtil.GetNearestPixelSize(thickness, barFrame:GetEffectiveScale(), thickness)
        barFrame.tickMarks[tickIndex]:SetThickness(pixelThickness)
        barFrame.tickMarks[tickIndex]:SetColorTexture(tc.r, tc.g, tc.b, tc.a or 1)
        barFrame.tickMarks[tickIndex]:Show()
        tickIndex = tickIndex + 1
      end
    end
    
    -- Hide unused ticks
    if barFrame.tickMarks then
      for i = tickIndex, 100 do
        if barFrame.tickMarks[i] then
          barFrame.tickMarks[i]:Hide()
        end
      end
    end
  else
    -- Hide all ticks
    if barFrame.tickMarks then
      for i = 1, 100 do
        if barFrame.tickMarks[i] then
          barFrame.tickMarks[i]:Hide()
        end
      end
    end
  end
end

-- ===================================================================
-- UPDATE SPECIFIC BAR
-- ===================================================================
function ns.Display.UpdateBar(barNumber, stacks, maxStacks, active, durationFontString, iconTexture)
  -- PROFILER: Track where time is spent
  local PM = ns.ProfilerMark
  if PM then PM("GetBarConfig") end
  
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig or not barConfig.tracking or not barConfig.tracking.enabled then
    -- Bar not configured - hide it (but don't create frames!)
    if barFrames[barNumber] then
      SafeHide(barFrames[barNumber].barFrame)
      SafeHide(barFrames[barNumber].textFrame)
      SafeHide(barFrames[barNumber].durationFrame)
      SafeHide(barFrames[barNumber].iconFrame)
      SafeHide(barFrames[barNumber].nameFrame)
      SafeHide(barFrames[barNumber].barIconFrame)
      -- Also hide multi-icon frames
      HideMultiIconFrames(barNumber)
    end
    return
  end
  
  -- FLICKERING FIX: Skip real tracking updates when preview mode is active
  -- When previewMode is on, only allow updates from SetPreviewStacks (no durationFontString)
  if previewMode and IsOptionsOpen() and durationFontString then
    return  -- Skip real tracking update, let preview control the display
  end
  
  if PM then PM("VisibilityChecks") end
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- PERFORMANCE: Cache expensive lookups ONCE at start of function
  -- ═══════════════════════════════════════════════════════════════════════════
  local optionsOpen = IsOptionsOpen()
  local currentSpec = GetCachedSpec()
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- INITIALIZATION CHECK: Keep bars hidden until init complete (prevents flash on reload)
  -- ═══════════════════════════════════════════════════════════════════════════
  if not initializationComplete and not optionsOpen then
    if barFrames[barNumber] then
      SafeHide(barFrames[barNumber].barFrame)
      SafeHide(barFrames[barNumber].textFrame)
      SafeHide(barFrames[barNumber].durationFrame)
      SafeHide(barFrames[barNumber].iconFrame)
      SafeHide(barFrames[barNumber].nameFrame)
      SafeHide(barFrames[barNumber].barIconFrame)
      HideMultiIconFrames(barNumber)
    end
    return
  end
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- EARLY VISIBILITY CHECK: Skip all work if bar shouldn't be visible
  -- ═══════════════════════════════════════════════════════════════════════════
  local shouldShow = true
  
  -- Spec check
  if barConfig.behavior and barConfig.behavior.showOnSpecs and #barConfig.behavior.showOnSpecs > 0 then
    shouldShow = false
    for _, spec in ipairs(barConfig.behavior.showOnSpecs) do
      if spec == currentSpec then
        shouldShow = true
        break
      end
    end
  end
  
  -- Combat check
  if shouldShow and not optionsOpen and barConfig.behavior and barConfig.behavior.hideOutOfCombat and not InCombatLockdown() then
    shouldShow = false
  end
  
  -- Inactive check
  if shouldShow and not optionsOpen and not active and barConfig.behavior and barConfig.behavior.hideWhenInactive then
    shouldShow = false
  end
  
  -- Talent conditions check
  if shouldShow and ns.TrackingOptions and ns.TrackingOptions.AreTalentConditionsMet then
    if not ns.TrackingOptions.AreTalentConditionsMet(barConfig) then
      shouldShow = false
    end
  end
  
  -- Early exit if bar shouldn't show and options not open
  if not shouldShow and not optionsOpen then
    if barFrames[barNumber] then
      SafeHide(barFrames[barNumber].barFrame)
      SafeHide(barFrames[barNumber].textFrame)
      SafeHide(barFrames[barNumber].durationFrame)
      SafeHide(barFrames[barNumber].iconFrame)
      SafeHide(barFrames[barNumber].nameFrame)
      SafeHide(barFrames[barNumber].barIconFrame)
      HideMultiIconFrames(barNumber)
    end
    return
  end
  
  -- Get values from config if not provided
  maxStacks = tonumber(maxStacks) or tonumber(barConfig.tracking.maxStacks) or 10
  if maxStacks < 1 then maxStacks = 10 end
  stacks = stacks or 0
  
  local barFrame, textFrame, durationFrame, iconFrame, nameFrame, barIconFrame = GetBarFrames(barNumber)
  local displayType = barConfig.display.displayType or "bar"
  
  if PM then PM("GetBarFrames") end
  
  -- Config validation and overlay logic (only matters when options open)
  if optionsOpen then
    -- Check tracking status
    local trackingOK = ns.API.IsTrackingOK and ns.API.IsTrackingOK(barNumber)
    local showFailOverlay = not trackingOK and barConfig.tracking.cooldownID and barConfig.tracking.cooldownID > 0
    
    if showFailOverlay then
      if displayType == "icon" then
        local cfg = barConfig.display
        if cfg.iconMultiMode then
          barFrame:Hide()
          textFrame:Hide()
          durationFrame:Hide()
          iconFrame:Hide()
          if iconFrame.trackingFailOverlay then
            iconFrame.trackingFailOverlay:Hide()
          end
          if iconFrame.stacksFrame then iconFrame.stacksFrame:Hide() end
          if nameFrame then nameFrame:Hide() end
          if barIconFrame then barIconFrame:Hide() end
          
          local multiFrames = GetMultiIconFrames(barNumber, maxStacks)
          for i = 1, maxStacks do
            local mFrame = multiFrames[i]
            if mFrame then
              mFrame:Show()
              mFrame.iconBar:SetValue(0)
            end
          end
          return
        else
          barFrame:Hide()
          textFrame:Hide()
          durationFrame:Hide()
          if nameFrame then nameFrame:Hide() end
          if barIconFrame then barIconFrame:Hide() end
          
          iconFrame:Show()
          if iconFrame.trackingFailOverlay then
            iconFrame.trackingFailOverlay:Show()
          end
          if iconFrame.stacksFrame then iconFrame.stacksFrame:Hide() end
          iconFrame.stacks:Hide()
        end
      else
        iconFrame:Hide()
        if iconFrame.stacksFrame then iconFrame.stacksFrame:Hide() end
        HideMultiIconFrames(barNumber)
        textFrame:Hide()
        durationFrame:Hide()
        if nameFrame then nameFrame:Hide() end
        if barIconFrame then barIconFrame:Hide() end
        
        barFrame:Show()
        if barFrame.trackingFailOverlay then
          barFrame.trackingFailOverlay:Show()
        end
      end
      return
    end
    
    -- Check if properly configured
    local tracking = barConfig.tracking
    local hasSpellIdentification = (tracking.spellID and tracking.spellID > 0) or 
                                    (tracking.cooldownID and tracking.cooldownID > 0) or 
                                    (tracking.buffName and tracking.buffName ~= "")
    local hasTrackType = tracking.trackType and tracking.trackType ~= "" and tracking.trackType ~= "none"
    local isCustomTracking = tracking.trackType == "customAura" or tracking.trackType == "customCooldown"
    local isProperlyConfigured = isCustomTracking or (hasSpellIdentification and hasTrackType)
    
    if not isProperlyConfigured then
      if displayType == "icon" then
        barFrame:Hide()
        textFrame:Hide()
        if durationFrame then durationFrame:Hide() end
        if nameFrame then nameFrame:Hide() end
        if barIconFrame then barIconFrame:Hide() end
        HideMultiIconFrames(barNumber)
        
        iconFrame:Show()
        if iconFrame.missingSetupOverlay then
          iconFrame.missingSetupOverlay:Show()
        end
        if iconFrame.trackingFailOverlay then iconFrame.trackingFailOverlay:Hide() end
        if iconFrame.stacksFrame then iconFrame.stacksFrame:Hide() end
        iconFrame.stacks:Hide()
      else
        iconFrame:Hide()
        if iconFrame.stacksFrame then iconFrame.stacksFrame:Hide() end
        HideMultiIconFrames(barNumber)
        textFrame:Hide()
        if durationFrame then durationFrame:Hide() end
        if nameFrame then nameFrame:Hide() end
        if barIconFrame then barIconFrame:Hide() end
        
        barFrame:Show()
        if barFrame.missingSetupOverlay then
          barFrame.missingSetupOverlay:Show()
        end
        if barFrame.trackingFailOverlay then barFrame.trackingFailOverlay:Hide() end
      end
      return
    end
  end
  
  -- Hide overlays when not needed (use SafeHide to avoid redundant calls)
  SafeHide(barFrame.trackingFailOverlay)
  if iconFrame then SafeHide(iconFrame.trackingFailOverlay) end
  SafeHide(barFrame.missingSetupOverlay)
  if iconFrame then SafeHide(iconFrame.missingSetupOverlay) end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- ICON MODE
  -- ═══════════════════════════════════════════════════════════════════
  if displayType == "icon" then
    local cfg = barConfig.display
    
    -- Always hide single iconFrame when multi-icon mode is enabled
    if cfg.iconMultiMode then
      SafeHide(iconFrame)
      SafeHide(iconFrame.stacksFrame)
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- MULTI-ICON MODE - Show separate icon for each stack
    -- ═══════════════════════════════════════════════════════════════════
    if cfg.iconMultiMode then
      -- Hide regular display elements
      SafeHide(barFrame)
      SafeHide(textFrame)
      SafeHide(durationFrame)
      SafeHide(iconFrame)
      SafeHide(iconFrame.stacksFrame)
      SafeHide(nameFrame)
      SafeHide(barIconFrame)
      
      -- Get the icon texture from CACHED config value only
      -- This was saved out of combat when tracking was set up
      -- Do NOT call GetTexture() or GetSpellTexture() here - they return secret values in combat
      local iconTex = barConfig.tracking.iconTextureID or "Interface\\Icons\\INV_Misc_QuestionMark"
      
      -- Get or create multi-icon frames
      local multiFrames = GetMultiIconFrames(barNumber, maxStacks)
      
      -- Get positioning settings
      local spacing = cfg.iconMultiSpacing or 4
      local direction = cfg.iconMultiDirection or "RIGHT"
      local iconSize = cfg.iconSize or 48
      local showDurationOn = cfg.iconMultiShowDurationOn or 1  -- 0=none, 1=first, 2-10=first N, -1=last
      local durationFontSize = cfg.iconDurationFontSize or 12
      local dc = cfg.iconDurationColor or {r=1, g=1, b=1, a=1}
      local freeMode = cfg.iconMultiFreeMode  -- Free positioning mode
      
      -- ═══════════════════════════════════════════════════════════════════
      -- STACK COUNT DETECTION using CDM FontString secret value trick
      -- If issecretvalue(stackText) returns true, we have 2+ stacks
      -- If it returns false, we have 0-1 stacks
      -- ═══════════════════════════════════════════════════════════════════
      local detectedMultipleStacks = false
      local trackedCooldownID = barConfig.tracking.cooldownID
      
      if trackedCooldownID then
        local cdmIcon = nil
        local viewer = _G["BuffIconCooldownViewer"]
        if viewer then
          local children = {viewer:GetChildren()}
          for _, child in ipairs(children) do
            if child.cooldownID == trackedCooldownID then
              cdmIcon = child
              break
            end
          end
        end
        
        if cdmIcon and cdmIcon.Applications and cdmIcon.Applications.Applications then
          local cdmStackFontString = cdmIcon.Applications.Applications
          local success, stackText = pcall(function() return cdmStackFontString:GetText() end)
          
          if success and stackText then
            -- If stackText is a secret value, we have 2+ stacks
            detectedMultipleStacks = issecretvalue(stackText)
          end
        end
      end
      
      -- Calculate which icons show duration based on showDurationOn setting and detected stacks
      -- showDurationOn values:
      --   0 = none
      --   1 = first icon only
      --   2-10 = first N icons (when filled)
      --   -1 = last icon only
      local function shouldShowDuration(iconIndex)
        if showDurationOn == 0 then
          return false
        elseif showDurationOn == -1 then
          -- Last only - show on maxStacks icon
          return iconIndex == maxStacks
        elseif showDurationOn == 1 then
          -- First only - always show on icon 1
          return iconIndex == 1
        elseif showDurationOn >= 2 then
          -- First N icons - show on icons 1 to showDurationOn
          -- But only if we can detect they're filled:
          --   - Icon 1 is always considered "filled" when active
          --   - Icons 2+ are filled when detectedMultipleStacks is true
          if iconIndex == 1 then
            return true
          elseif iconIndex <= showDurationOn then
            -- For icons 2+, only show if we detected multiple stacks
            -- During combat, if detectedMultipleStacks is true, stacks >= 2
            -- We can't know exact stack count, but we know it's "more than 1"
            return detectedMultipleStacks
          end
          return false
        end
        return false
      end
      
      -- Use cached optionsOpen from function start for preview mode
      local usePreviewValue = optionsOpen and (not active or previewMode)
      local previewStackCount = nil
      if usePreviewValue then
        -- Use global previewStacks (0-1 decimal) to calculate preview
        local pct = previewStacks or 0.5
        previewStackCount = math.floor(maxStacks * pct + 0.5)
        if previewStackCount < 1 then previewStackCount = math.ceil(maxStacks / 2) end
      end
      
      -- Update each multi-icon frame
      for i = 1, maxStacks do
        local mFrame = multiFrames[i]
        if mFrame then
          -- Set size
          mFrame:SetSize(iconSize, iconSize)
          
          -- Set position - use saved position (free mode) or calculate default
          mFrame:ClearAllPoints()
          local savedPos = cfg.iconMultiPositions and cfg.iconMultiPositions[i]
          
          if freeMode and savedPos then
            -- Free mode with saved position
            mFrame:SetPoint(savedPos.point, UIParent, savedPos.relPoint, savedPos.x, savedPos.y)
          elseif not freeMode then
            -- Auto-layout mode - calculate positions based on direction
            local offsetX, offsetY = 0, 0
            if direction == "RIGHT" then
              offsetX = (i - 1) * (iconSize + spacing)
            elseif direction == "LEFT" then
              offsetX = -(i - 1) * (iconSize + spacing)
            elseif direction == "UP" then
              offsetY = (i - 1) * (iconSize + spacing)
            elseif direction == "DOWN" then
              offsetY = -(i - 1) * (iconSize + spacing)
            end
            
            -- Use main icon position as anchor
            local mainPos = cfg.position
            if mainPos then
              mFrame:SetPoint(mainPos.point, UIParent, mainPos.relPoint, mainPos.x + offsetX, mainPos.y + offsetY)
            else
              mFrame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
            end
          else
            -- Free mode but no saved position yet - use default layout
            local offsetX, offsetY = 0, 0
            if direction == "RIGHT" then
              offsetX = (i - 1) * (iconSize + spacing)
            elseif direction == "LEFT" then
              offsetX = -(i - 1) * (iconSize + spacing)
            elseif direction == "UP" then
              offsetY = (i - 1) * (iconSize + spacing)
            elseif direction == "DOWN" then
              offsetY = -(i - 1) * (iconSize + spacing)
            end
            
            local mainPos = cfg.position
            if mainPos then
              mFrame:SetPoint(mainPos.point, UIParent, mainPos.relPoint, mainPos.x + offsetX, mainPos.y + offsetY)
            else
              mFrame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
            end
          end
          
          -- Set icon texture ONLY when out of combat (SetStatusBarTexture doesn't accept secret/tainted values)
          -- Track what texture is set so we don't try to set it again during combat
          if not InCombatLockdown() then
            if mFrame.currentTextureID ~= iconTex then
              mFrame.iconBar:SetStatusBarTexture(iconTex)
              mFrame.iconBar:SetStatusBarColor(1, 1, 1, 1)  -- Ensure white color!
              -- DON'T use SetTexCoord on StatusBar texture - it breaks the display
              
              -- Set desaturated background texture (same icon, but gray)
              mFrame.desatBg:SetTexture(iconTex)
              mFrame.desatBg:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- TexCoord OK on regular Texture
              mFrame.desatBg:SetDesaturated(true)
              mFrame.desatBg:SetVertexColor(0.4, 0.4, 0.4, 1)
              
              mFrame.currentTextureID = iconTex
            end
          end
          
          -- Set min/max values for this stack position (i-1, i)
          -- Stack 1: (0,1), Stack 2: (1,2), etc.
          mFrame.iconBar:SetMinMaxValues(i - 1, i)
          
          -- Pass the stacks value through to SetValue
          -- SetValue accepts secret values - it will show filled when stacks >= i
          if usePreviewValue and previewStackCount then
            -- Preview mode: use calculated preview count
            mFrame.iconBar:SetValue(previewStackCount)
          elseif stacks then
            -- Live mode: pass secret value directly through
            mFrame.iconBar:SetValue(stacks)
          else
            -- No stacks data: show empty
            mFrame.iconBar:SetValue(0)
          end
          
          -- Background visibility (desaturated icon background)
          local showDesatBg = cfg.iconMultiShowDesatBg
          if showDesatBg == nil then showDesatBg = true end  -- Default to showing
          
          if showDesatBg or optionsOpen then
            -- Show desaturated background (always show during editing for visibility)
            SafeShow(mFrame.desatBg)
            SafeShow(mFrame.solidBg)
          else
            -- Hide background - only show filled icons
            SafeHide(mFrame.desatBg)
            SafeHide(mFrame.solidBg)
          end
          
          -- Border
          if cfg.iconShowBorder then
            local bc = cfg.iconBorderColor or {r=0, g=0, b=0, a=1}
            mFrame.border:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
            SafeShow(mFrame.border)
          else
            SafeHide(mFrame.border)
          end
          
          -- Duration text - use new shouldShowDuration logic
          local showDuration = shouldShowDuration(i)
          
          -- In preview mode, use the preview stack count for visibility
          if usePreviewValue and previewStackCount then
            -- Preview: show duration on icons up to previewStackCount, limited by showDurationOn
            if showDurationOn == 0 then
              showDuration = false
            elseif showDurationOn == -1 then
              showDuration = (i == maxStacks)
            elseif showDurationOn == 1 then
              showDuration = (i == 1)
            elseif showDurationOn >= 2 then
              -- In preview, show on first N icons up to the preview stack count
              showDuration = (i <= showDurationOn) and (i <= previewStackCount)
            end
          end
          
          -- Get duration anchor setting
          local durationAnchor = cfg.iconMultiDurationAnchor or "BOTTOM"
          
          -- Update duration position based on anchor
          mFrame.duration:ClearAllPoints()
          if durationAnchor == "CENTER" then
            mFrame.duration:SetPoint("CENTER", mFrame, "CENTER", 0, 0)
          elseif durationAnchor == "TOP" then
            mFrame.duration:SetPoint("TOP", mFrame, "TOP", 0, -2)
          elseif durationAnchor == "BOTTOM" then
            mFrame.duration:SetPoint("BOTTOM", mFrame, "BOTTOM", 0, 2)
          elseif durationAnchor == "LEFT" then
            mFrame.duration:SetPoint("LEFT", mFrame, "LEFT", 2, 0)
          elseif durationAnchor == "RIGHT" then
            mFrame.duration:SetPoint("RIGHT", mFrame, "RIGHT", -2, 0)
          elseif durationAnchor == "TOPLEFT" then
            mFrame.duration:SetPoint("TOPLEFT", mFrame, "TOPLEFT", 2, -2)
          elseif durationAnchor == "TOPRIGHT" then
            mFrame.duration:SetPoint("TOPRIGHT", mFrame, "TOPRIGHT", -2, -2)
          elseif durationAnchor == "BOTTOMLEFT" then
            mFrame.duration:SetPoint("BOTTOMLEFT", mFrame, "BOTTOMLEFT", 2, 2)
          elseif durationAnchor == "BOTTOMRIGHT" then
            mFrame.duration:SetPoint("BOTTOMRIGHT", mFrame, "BOTTOMRIGHT", -2, 2)
          else
            mFrame.duration:SetPoint("BOTTOM", mFrame, "BOTTOM", 0, 2)
          end
          
          if showDuration and cfg.iconShowDuration then
            local durationOutline = GetOutlineFlag(cfg.iconDurationOutline)
            local durationFont = "Fonts\\FRIZQT__.TTF"
            if LSM and cfg.iconDurationFont then
              local font = LSM:Fetch("font", cfg.iconDurationFont)
              if font then
                durationFont = font
              end
            end
            mFrame.duration:SetFont(durationFont, durationFontSize, durationOutline)
            ApplyTextShadow(mFrame.duration, cfg.iconDurationShadow)
            mFrame.duration:SetTextColor(dc.r, dc.g, dc.b, dc.a)
            
            -- Get decimals setting for formatting
            local decimals = cfg.durationDecimals or 1
            
            if active and durationFontString then
              if durationFontString.GetAuraInfo then
                -- Has GetAuraInfo - use C_UnitAuras.GetAuraDurationRemaining for secret-safe text
                local auraID, unit = durationFontString:GetAuraInfo()
                if auraID and unit then
                  local textOK = pcall(function()
                    local remaining = C_UnitAuras.GetAuraDurationRemaining(unit, auraID)
                    mFrame.duration:SetText(FormatDuration(remaining, decimals))
                  end)
                  if not textOK then
                    mFrame.duration:SetText(FormatDuration(durationFontString:GetValue(), decimals))
                  end
                else
                  mFrame.duration:SetText(FormatDuration(durationFontString:GetValue(), decimals))
                end
              elseif durationFontString.GetValue then
                -- StatusBar or wrapper - pass value directly (secret-safe via SetText)
                mFrame.duration:SetText(FormatDuration(durationFontString:GetValue(), decimals))
              elseif durationFontString.GetText then
                -- FontString - use GetText
                mFrame.duration:SetText(durationFontString:GetText())
              end
              mFrame.duration:Show()
            elseif usePreviewValue then
              -- Preview mode - show "0" as placeholder
              mFrame.duration:SetText("0")
              mFrame.duration:Show()
            else
              mFrame.duration:SetText("")
              mFrame.duration:Hide()
            end
          else
            mFrame.duration:Hide()
          end
          
          -- Editing text (show when options open and free mode enabled)
          if not mFrame.editingText then
            mFrame.editingText = mFrame:CreateFontString(nil, "OVERLAY")
            mFrame.editingText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            mFrame.editingText:SetPoint("TOP", mFrame, "BOTTOM", 0, -2)
            mFrame.editingText:SetTextColor(1, 0.8, 0, 1)
          end
          
          if optionsOpen and freeMode then
            mFrame.editingText:SetText("Stack " .. i)
            mFrame.editingText:Show()
          else
            mFrame.editingText:Hide()
          end
          
          -- Show frame visibility logic
          -- Show when: options open, OR active, OR showDesatBg is enabled (always show inactive icons)
          local showDesatBg = cfg.iconMultiShowDesatBg
          if showDesatBg == nil then showDesatBg = true end
          
          if cfg.enabled and (optionsOpen or active or showDesatBg) then
            SafeShow(mFrame)
          else
            SafeHide(mFrame)
          end
        end
      end
      
      -- Hide any extra frames if maxStacks decreased
      if multiIconFrames[barNumber] then
        for i = maxStacks + 1, #multiIconFrames[barNumber] do
          SafeHide(multiIconFrames[barNumber][i])
        end
      end
      
      return  -- Done with multi-icon mode
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- REGULAR ICON MODE
    -- ═══════════════════════════════════════════════════════════════════
    -- Hide multi-icon frames if switching back to regular mode
    HideMultiIconFrames(barNumber)
    
    -- Hide bar elements
    SafeHide(barFrame)
    SafeHide(textFrame)
    SafeHide(durationFrame)
    SafeHide(nameFrame)
    SafeHide(barIconFrame)
    
    -- Set icon texture with multiple fallbacks
    if iconTexture then
      iconFrame.icon:SetTexture(iconTexture)
    elseif barConfig.tracking.iconTextureID then
      iconFrame.icon:SetTexture(barConfig.tracking.iconTextureID)
    elseif barConfig.tracking.spellID then
      local texture = C_Spell.GetSpellTexture(barConfig.tracking.spellID)
      if texture then
        iconFrame.icon:SetTexture(texture)
      end
    end
    
    -- Apply icon zoom (for custom tracking icons)
    local zoom = cfg.iconZoom or 0
    local minCoord = 0.08 + (zoom * 0.42)  -- 0.08 to 0.50
    local maxCoord = 0.92 - (zoom * 0.42)  -- 0.92 to 0.50
    iconFrame.icon:SetTexCoord(minCoord, maxCoord, minCoord, maxCoord)
    
    -- Show/hide icon texture based on iconShowTexture
    -- SAFETY: Also verify bar is enabled (prevents ghost icons from deleted bars)
    if cfg.iconShowTexture == false or not barConfig.tracking.enabled then
      iconFrame.icon:Hide()
      iconFrame.background:Hide()
    else
      iconFrame.icon:Show()
    end
    
    -- Use cached optionsOpen from function start for preview mode
    local showPreview = optionsOpen and (not active or previewMode)
    
    -- Update stacks text (SetText handles secret values)
    if cfg.iconShowStacks then
      local stackAnchor = cfg.iconStackAnchor or "TOPRIGHT"
      local stackText
      local sc = cfg.iconStackColor or {r=1, g=1, b=1, a=1}
      
      -- Determine which text element to use
      if stackAnchor == "FREE" then
        stackText = iconFrame.stacksFrame.text
        iconFrame.stacks:Hide()
        iconFrame.stacksFrame:Show()
      else
        stackText = iconFrame.stacks
        iconFrame.stacksFrame:Hide()
        iconFrame.stacks:Show()
      end
      
      -- Show stacks - preview, active, or inactive
      if showPreview then
        local previewStackCount = math.max(1, math.floor((maxStacks or 3) * (previewStacks or 0.5)))
        stackText:SetText(previewStackCount)
      elseif active and stacks then
        stackText:SetText(stacks)
      else
        stackText:SetText("0")
      end
      stackText:SetTextColor(sc.r, sc.g, sc.b, sc.a)
    else
      iconFrame.stacks:Hide()
      iconFrame.stacksFrame:Hide()
    end
    
    -- Update duration text (pass secret value directly)
    -- durationFontString can be FontString (GetText), StatusBar (GetValue), or wrapper with GetAuraInfo
    if cfg.iconShowDuration then
      local dc = cfg.iconDurationColor or {r=1, g=1, b=1, a=1}
      local decimals = cfg.durationDecimals or 1
      
      -- Store decimals on frame for OnUpdate access
      iconFrame.storedDecimals = decimals
      
      if showPreview then
        -- Preview mode - show sample duration
        local maxDuration = barConfig.tracking.maxDuration or 30
        local pct = previewStacks or 0.5
        local previewValue = maxDuration * pct
        iconFrame.duration:SetText(string.format("%." .. decimals .. "f", previewValue))
        iconFrame:SetScript("OnUpdate", nil)
        iconFrame.durationActive = false
        iconFrame.durationSource = nil
      elseif durationFontString and durationFontString.GetAuraInfo then
        -- Has GetAuraInfo - use DurationObject for auto-updating countdown
        local auraID, unit = durationFontString:GetAuraInfo()
        if auraID and unit and active then
          -- Store source for OnUpdate to get fresh aura info
          iconFrame.durationSource = durationFontString
          iconFrame.durationActive = true
          
          -- Set up OnUpdate to poll GetRemainingDuration() with fresh DurationObject
          if not iconFrame.durationOnUpdate then
            iconFrame.durationOnUpdate = function(self, elapsed)
              self.durationElapsed = (self.durationElapsed or 0) + elapsed
              if self.durationElapsed < 0.03 then return end  -- ~30fps
              self.durationElapsed = 0
              
              if not self.durationActive or not self.durationSource then return end
              
              -- Get current auraID from source (may have changed due to refresh)
              local currentAuraID, currentUnit = self.durationSource:GetAuraInfo()
              if not currentAuraID or not currentUnit then
                self.duration:SetText("")
                return
              end
              
              -- Get fresh DurationObject (handles aura refresh automatically)
              local ok, durObj = pcall(C_UnitAuras.GetAuraDuration, currentUnit, currentAuraID)
              if ok and durObj then
                local okRemaining, remaining = pcall(durObj.GetRemainingDuration, durObj)
                if okRemaining then
                  self.duration:SetText(FormatDuration(remaining, self.storedDecimals))
                else
                  self.duration:SetText("")
                end
              else
                self.duration:SetText("")
              end
            end
          end
          iconFrame:SetScript("OnUpdate", iconFrame.durationOnUpdate)
          
          -- Initial text set
          local ok, durObj = pcall(C_UnitAuras.GetAuraDuration, unit, auraID)
          if ok and durObj then
            local okRemaining, remaining = pcall(durObj.GetRemainingDuration, durObj)
            if okRemaining then
              iconFrame.duration:SetText(FormatDuration(remaining, decimals))
            end
          end
        else
          iconFrame.duration:SetText("")
          iconFrame:SetScript("OnUpdate", nil)
          iconFrame.durationActive = false
          iconFrame.durationSource = nil
        end
      elseif durationFontString and durationFontString.GetValue then
        -- It's a StatusBar or wrapper - pass value directly (secret-safe via SetText)
        iconFrame:SetScript("OnUpdate", nil)
        iconFrame.durationActive = false
        iconFrame.durationSource = nil
        if active then
          iconFrame.duration:SetText(FormatDuration(durationFontString:GetValue(), decimals))
        else
          iconFrame.duration:SetText("")
        end
      elseif durationFontString and durationFontString.GetText then
        -- It's a FontString - use GetText
        iconFrame:SetScript("OnUpdate", nil)
        iconFrame.durationActive = false
        iconFrame.durationSource = nil
        iconFrame.duration:SetText(durationFontString:GetText())
      else
        iconFrame:SetScript("OnUpdate", nil)
        iconFrame.durationActive = false
        iconFrame.durationSource = nil
        iconFrame.duration:SetText("")
      end
      iconFrame.duration:SetTextColor(dc.r, dc.g, dc.b, dc.a)
      iconFrame.duration:Show()
    else
      iconFrame:SetScript("OnUpdate", nil)
      iconFrame.durationActive = false
      iconFrame.durationSource = nil
      iconFrame.duration:Hide()
    end
    
    -- Border
    if cfg.iconShowBorder then
      local bc = cfg.iconBorderColor or {r=0, g=0, b=0, a=1}
      iconFrame.background:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
      iconFrame.background:Show()
    else
      iconFrame.background:Hide()
    end
    
    -- Visibility logic
    local shouldShow = true
    
    -- Hide out of combat (but not if options panel is open)
    if not InCombatLockdown() and barConfig.behavior.hideOutOfCombat and not optionsOpen then
      shouldShow = false
    end
    
    -- Hide when inactive (but not if options panel is open for preview)
    if not active and barConfig.behavior.hideWhenInactive and not optionsOpen then
      shouldShow = false
    end
    
    -- If not active and not preview, clear duration text
    if not active and not showPreview then
      iconFrame.duration:SetText("")
    end
    
    if shouldShow and cfg.enabled then
      SafeShow(iconFrame)
    else
      SafeHide(iconFrame)
    end
    
    return  -- Exit early for icon mode
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- BAR MODE (existing code)
  -- ═══════════════════════════════════════════════════════════════════
  -- Hide icon frame if in bar mode
  SafeHide(iconFrame)
  
  -- Use cached optionsOpen from function start for preview mode
  local showPreview = optionsOpen and (not active or previewMode)
  
  -- For preview mode, calculate a sample stack count from the global preview slider
  -- We can't use 'stacks' parameter for math as it may be a secret value
  local effectiveStacks = stacks
  if showPreview then
    -- Use global previewStacks (0-1 decimal) to calculate preview
    local pct = previewStacks or 0.5
    effectiveStacks = math.floor(maxStacks * pct + 0.5)
    if effectiveStacks < 1 then effectiveStacks = math.ceil(maxStacks / 2) end
  end
  
  local displayMode = barConfig.display.thresholdMode or "simple"
  local thresholds = barConfig.thresholds or {}
  
  -- Helper function to convert threshold values
  -- If thresholdAsPercent is true, convert percentage to actual value
  -- If false (default), use raw values directly
  local function GetThresholdValue(thresholdMinValue, defaultValue)
    local value = thresholdMinValue or defaultValue
    if barConfig.display.thresholdAsPercent then
      -- Convert percentage to actual value
      return math.floor(maxStacks * value / 100)
    end
    return value
  end
  
  -- Hide stacked bars if they exist
  if barFrame.stackedBars then
    for i = 1, #barFrame.stackedBars do
      SafeHide(barFrame.stackedBars[i])
    end
  end
  
  -- Hide granular bars if they exist
  if barFrame.granularBars then
    for i = 1, #barFrame.granularBars do
      SafeHide(barFrame.granularBars[i])
    end
  end
  
  if PM then PM("AppearanceSetup") end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- PERFORMANCE: Cache expensive setup - only recompute when config changes
  -- ═══════════════════════════════════════════════════════════════════
  local appearanceHash = GetBarAppearanceHash(barConfig)
  local needsSetup = barFrame._lastAppearanceHash ~= appearanceHash
  
  -- Get orientation settings for bar (always needed for logic, cheap)
  local isBarVertical = (barConfig.display.barOrientation == "vertical")
  local barOrientation = isBarVertical and "VERTICAL" or "HORIZONTAL"
  local isBarReverseFill = barConfig.display.barReverseFill or false
  
  -- Get texture - cache the path on the frame to avoid LSM:Fetch every frame
  local texturePath = barFrame._cachedTexturePath
  if needsSetup or not texturePath then
    texturePath = "Interface\\TargetingFrame\\UI-StatusBar"
    if LSM and barConfig.display.texture then
      local fetchedTexture = LSM:Fetch("statusbar", barConfig.display.texture)
      if fetchedTexture then texturePath = fetchedTexture end
    end
    barFrame._cachedTexturePath = texturePath
    barFrame._lastAppearanceHash = appearanceHash
  end
  
  -- Get fill texture scale
  local fillTextureScale = barConfig.display.fillTextureScale or 1.0
  
  local baseColor = barConfig.display.barColor or {r=0, g=0.8, b=1, a=1}
  if thresholds[1] and thresholds[1].enabled and thresholds[1].color then
    baseColor = thresholds[1].color
  end
  
  if PM then PM("BarRendering") end
  
  if displayMode == "granular" then
    -- ═══════════════════════════════════════════════════════════════
    -- GRANULAR MODE: 1 bar per stack
    -- ═══════════════════════════════════════════════════════════════
    barFrame.bar:SetAlpha(0)
    
    -- Hide other bar types
    if barFrame.stackedBars then
      for _, bar in ipairs(barFrame.stackedBars) do bar:Hide() end
    end
    if barFrame.maxColorBar then
      barFrame.maxColorBar:Hide()
    end
    
    -- Build color ranges from thresholds
    local colorRanges = {}
    table.insert(colorRanges, { startValue = 0, color = baseColor })
    
    if thresholds[2] and thresholds[2].enabled then
      table.insert(colorRanges, {
        startValue = GetThresholdValue(thresholds[2].minValue, math.floor(maxStacks/2)),
        color = thresholds[2].color
      })
    end
    
    if thresholds[3] and thresholds[3].enabled then
      table.insert(colorRanges, {
        startValue = GetThresholdValue(thresholds[3].minValue, math.floor(maxStacks*0.8)),
        color = thresholds[3].color
      })
    end
    
    if thresholds[4] and thresholds[4].enabled then
      table.insert(colorRanges, {
        startValue = GetThresholdValue(thresholds[4].minValue, math.floor(maxStacks*0.5)),
        color = thresholds[4].color
      })
    end
    
    if thresholds[5] and thresholds[5].enabled then
      table.insert(colorRanges, {
        startValue = GetThresholdValue(thresholds[5].minValue, math.floor(maxStacks*0.7)),
        color = thresholds[5].color
      })
    end
    
    if thresholds[6] and thresholds[6].enabled then
      table.insert(colorRanges, {
        startValue = GetThresholdValue(thresholds[6].minValue, math.floor(maxStacks*0.9)),
        color = thresholds[6].color
      })
    end
    
    table.sort(colorRanges, function(a, b) return a.startValue < b.startValue end)
    
    -- Get max color settings
    local enableMaxColor = barConfig.display.enableMaxColor
    local maxColor = barConfig.display.maxColor or {r=0, g=1, b=0, a=1}
    
    local function GetColorForValue(val)
      -- If at max and enableMaxColor, use max color
      if enableMaxColor and val == maxStacks then
        return maxColor
      end
      local color = colorRanges[1] and colorRanges[1].color or {r=1, g=1, b=1, a=1}
      for _, range in ipairs(colorRanges) do
        if val >= range.startValue then
          color = range.color
        else
          break
        end
      end
      return color
    end
    
    local numBars = maxStacks
    
    -- Get smoothing setting
    local enableSmooth = barConfig.display.enableSmoothing
    
    if not barFrame.granularBars then
      barFrame.granularBars = {}
    end
    
    while #barFrame.granularBars < numBars do
      local bar = CreateFrame("StatusBar", nil, barFrame)
      bar:SetStatusBarTexture(texturePath)
      bar:SetOrientation(barOrientation)
      bar:SetReverseFill(isBarReverseFill)
      bar:SetRotatesTexture(isBarVertical)
      table.insert(barFrame.granularBars, bar)
    end
    
    for i = 1, numBars do
      local bar = barFrame.granularBars[i]
      local barValue = i
      local widthPercent = barValue / maxStacks
      local color = GetColorForValue(barValue)
      
      -- PERFORMANCE: Only apply expensive setup when appearance changes
      if needsSetup or not bar._setupDone then
        bar:SetOrientation(barOrientation)
        bar:SetReverseFill(isBarReverseFill)
        bar:SetRotatesTexture(isBarVertical)
        bar:SetStatusBarTexture(texturePath)
        bar:SetFrameLevel(barFrame:GetFrameLevel() + i)
        ApplyBarSmoothing(bar, enableSmooth)
        bar._setupDone = true
      end
      
      -- Position based on fill direction (must update if size changes, but that's rare)
      bar:ClearAllPoints()
      if isBarVertical then
        local totalHeight = barFrame:GetHeight()
        local barHeight = widthPercent * totalHeight
        bar:SetPoint("BOTTOMLEFT", barFrame, "BOTTOMLEFT", 0, 0)
        bar:SetPoint("RIGHT", barFrame, "RIGHT", 0, 0)
        bar:SetHeight(math.max(2, barHeight))
      else
        local totalWidth = barFrame:GetWidth()
        local barWidth = widthPercent * totalWidth
        bar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOM", barFrame, "BOTTOM", 0, 0)
        bar:SetWidth(math.max(2, barWidth))
      end
      
      bar:SetMinMaxValues(barValue - 1, barValue)
      bar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
      ApplyBarGradient(bar, barConfig)  -- Needs to run after SetStatusBarColor
      bar:SetValue(effectiveStacks)
      bar:Show()
    end
    
  elseif displayMode == "perStack" then
    -- ═══════════════════════════════════════════════════════════════
    -- SEQUENCE MODE: Separate segments with color ranges
    -- ═══════════════════════════════════════════════════════════════
    barFrame.bar:SetAlpha(0)
    
    local numBars = maxStacks
    local stackColors = barConfig.stackColors or {}
    
    -- Get max color settings
    local enableMaxColor = barConfig.display.enableMaxColor
    local maxColor = barConfig.display.maxColor or {r=0, g=1, b=0, a=1}
    
    -- Get smoothing setting
    local enableSmooth = barConfig.display.enableSmoothing
    
    -- Hide maxColorBar (we use segment color override instead)
    if barFrame.maxColorBar then
      barFrame.maxColorBar:Hide()
    end
    
    -- Ensure we have granularBars for segments
    if not barFrame.granularBars then
      barFrame.granularBars = {}
    end
    
    -- Create segment bars as needed
    while #barFrame.granularBars < numBars do
      local bar = CreateFrame("StatusBar", nil, barFrame)
      bar:SetStatusBarTexture(texturePath)
      bar:SetOrientation(barOrientation)
      bar:SetReverseFill(isBarReverseFill)
      bar:SetRotatesTexture(isBarVertical)
      table.insert(barFrame.granularBars, bar)
    end
    
    -- Hide any old threshold overlays if they exist
    if barFrame.thresholdOverlay1 then
      for _, bar in ipairs(barFrame.thresholdOverlay1) do bar:Hide() end
    end
    if barFrame.thresholdOverlay2 then
      for _, bar in ipairs(barFrame.thresholdOverlay2) do bar:Hide() end
    end
    
    -- Calculate segment size based on orientation
    local totalSize = isBarVertical and barFrame:GetHeight() or barFrame:GetWidth()
    local segmentSize = totalSize / numBars
    
    for i = 1, numBars do
      local bar = barFrame.granularBars[i]
      local color = stackColors[i] or baseColor
      
      -- Override last segment with max color if enabled
      if enableMaxColor and i == numBars then
        color = maxColor
      end
      
      -- PERFORMANCE: Only apply expensive setup when appearance changes
      if needsSetup or not bar._setupDone then
        bar:SetOrientation(barOrientation)
        bar:SetReverseFill(isBarReverseFill)
        bar:SetRotatesTexture(isBarVertical)
        bar:SetStatusBarTexture(texturePath)
        bar:SetFrameLevel(barFrame:GetFrameLevel() + i)
        ApplyBarSmoothing(bar, enableSmooth)
        bar._setupDone = true
      end
      
      bar:ClearAllPoints()
      if isBarVertical then
        bar:SetPoint("BOTTOMLEFT", barFrame, "BOTTOMLEFT", 0, (i - 1) * segmentSize)
        bar:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", 0, (i - 1) * segmentSize)
        bar:SetHeight(math.max(2, segmentSize - 1))
      else
        bar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", (i - 1) * segmentSize, 0)
        bar:SetPoint("BOTTOMLEFT", barFrame, "BOTTOMLEFT", (i - 1) * segmentSize, 0)
        bar:SetWidth(math.max(2, segmentSize - 1))
      end
      bar:SetMinMaxValues(i - 1, i)
      bar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
      ApplyBarGradient(bar, barConfig)  -- Needs to run after SetStatusBarColor
      bar:SetValue(effectiveStacks)
      SafeShow(bar)
    end
    
    -- Hide extra bars
    for i = numBars + 1, #barFrame.granularBars do
      SafeHide(barFrame.granularBars[i])
    end
    
  elseif displayMode == "granularTest" then
    -- ═══════════════════════════════════════════════════════════════
    -- THRESHOLD MODE: Stacked bars positioned end-to-end
    -- ═══════════════════════════════════════════════════════════════
    barFrame.bar:SetAlpha(0)
    
    -- Build threshold ranges
    local ranges = {}
    local prevValue = 0
    
    if thresholds[2] and thresholds[2].enabled then
      local thresh2Value = GetThresholdValue(thresholds[2].minValue, math.floor(maxStacks/2))
      table.insert(ranges, {
        minVal = 0,
        maxVal = thresh2Value,
        color = baseColor
      })
      prevValue = thresh2Value
      
      if thresholds[3] and thresholds[3].enabled then
        local thresh3Value = GetThresholdValue(thresholds[3].minValue, math.floor(maxStacks*0.8))
        table.insert(ranges, {
          minVal = prevValue,
          maxVal = thresh3Value,
          color = thresholds[2].color
        })
        prevValue = thresh3Value
        
        table.insert(ranges, {
          minVal = prevValue,
          maxVal = maxStacks,
          color = thresholds[3].color
        })
      else
        table.insert(ranges, {
          minVal = prevValue,
          maxVal = maxStacks,
          color = thresholds[2].color
        })
      end
    else
      table.insert(ranges, {
        minVal = 0,
        maxVal = maxStacks,
        color = baseColor
      })
    end
    
    if not barFrame.stackedBars then
      barFrame.stackedBars = {}
    end
    
    -- Get smoothing setting
    local enableSmooth = barConfig.display.enableSmoothing
    
    while #barFrame.stackedBars < #ranges do
      local bar = CreateFrame("StatusBar", nil, barFrame)
      bar:SetStatusBarTexture(texturePath)
      bar:SetOrientation(barOrientation)
      bar:SetReverseFill(isBarReverseFill)
      bar:SetRotatesTexture(isBarVertical)
      table.insert(barFrame.stackedBars, bar)
    end
    
    for i, range in ipairs(ranges) do
      local bar = barFrame.stackedBars[i]
      
      -- PERFORMANCE: Only apply expensive setup when appearance changes
      if needsSetup or not bar._setupDone then
        bar:SetOrientation(barOrientation)
        bar:SetReverseFill(isBarReverseFill)
        bar:SetRotatesTexture(isBarVertical)
        bar:SetStatusBarTexture(texturePath)
        bar:SetFrameLevel(barFrame:GetFrameLevel() + i)
        ApplyBarSmoothing(bar, enableSmooth)
        bar._setupDone = true
      end
      
      bar:ClearAllPoints()
      if isBarVertical then
        local totalHeight = barFrame:GetHeight()
        local barHeight = totalHeight * (range.maxVal - range.minVal) / maxStacks
        local yOffset = totalHeight * range.minVal / maxStacks
        bar:SetPoint("BOTTOMLEFT", barFrame, "BOTTOMLEFT", 0, yOffset)
        bar:SetPoint("RIGHT", barFrame, "RIGHT", 0, 0)
        bar:SetHeight(math.max(1, barHeight))
      else
        local totalWidth = barFrame:GetWidth()
        local barWidth = totalWidth * (range.maxVal - range.minVal) / maxStacks
        local xOffset = totalWidth * range.minVal / maxStacks
        bar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", xOffset, 0)
        bar:SetPoint("BOTTOM", barFrame, "BOTTOM", 0, 0)
        bar:SetWidth(math.max(1, barWidth))
      end
      bar:SetMinMaxValues(range.minVal, range.maxVal)
      bar:SetStatusBarColor(range.color.r, range.color.g, range.color.b, range.color.a or 1)
      ApplyBarGradient(bar, barConfig)  -- Needs to run after SetStatusBarColor
      bar:SetValue(effectiveStacks)
      SafeShow(bar)
    end
    
    -- Hide unused threshold bars
    for i = #ranges + 1, #barFrame.stackedBars do
      SafeHide(barFrame.stackedBars[i])
    end
    
    -- MAX COLOR OVERLAY for continuous mode
    -- Add an overlay bar that only shows when at max stacks
    local enableMaxColor = barConfig.display.enableMaxColor
    if enableMaxColor and maxStacks > 1 then
      -- Ensure we have a max color overlay bar
      if not barFrame.maxColorBar then
        barFrame.maxColorBar = CreateFrame("StatusBar", nil, barFrame)
      end
      
      local maxBar = barFrame.maxColorBar
      
      -- PERFORMANCE: Only apply expensive setup when appearance changes
      if needsSetup or not maxBar._setupDone then
        maxBar:SetOrientation(barOrientation)
        maxBar:SetReverseFill(isBarReverseFill)
        maxBar:SetRotatesTexture(isBarVertical)
        maxBar:SetStatusBarTexture(texturePath)
        maxBar:SetFrameLevel(barFrame:GetFrameLevel() + 21)  -- On top of all stack bars
        ApplyBarSmoothing(maxBar, enableSmooth)
        maxBar._setupDone = true
      end
      
      local maxColor = barConfig.display.maxColor or {r=0, g=1, b=0, a=1}
      
      maxBar:ClearAllPoints()
      maxBar:SetAllPoints(barFrame)  -- Full width overlay
      maxBar:SetMinMaxValues(maxStacks - 1, maxStacks)  -- Only fills when at max
      maxBar:SetStatusBarColor(maxColor.r, maxColor.g, maxColor.b, maxColor.a or 1)
      ApplyBarGradient(maxBar, barConfig)  -- Apply gradient effect
      maxBar:SetValue(effectiveStacks)
      maxBar:Show()
    elseif barFrame.maxColorBar then
      barFrame.maxColorBar:Hide()
    end
    
  elseif displayMode == "folded" then
    -- ═══════════════════════════════════════════════════════════════
    -- FOLDED MODE: Bar folds at midpoint, second color overlays first
    -- Visual: 10 stacks shown as 5 segments, 2nd color fills over 1st after midpoint
    -- ═══════════════════════════════════════════════════════════════
    barFrame.bar:SetAlpha(0)
    
    local midpoint = math.ceil(maxStacks / 2)
    local color1 = barConfig.display.foldedColor1 or {r=0, g=0.5, b=1, a=1}
    local color2 = barConfig.display.foldedColor2 or {r=0, g=1, b=0, a=1}
    
    -- Get smoothing setting
    local enableSmooth = barConfig.display.enableSmoothing
    
    -- Hide other bar types
    if barFrame.granularBars then
      for _, bar in ipairs(barFrame.granularBars) do bar:Hide() end
    end
    
    -- Hide foldedBgFrame if exists from old code
    if barFrame.foldedBgFrame then
      barFrame.foldedBgFrame:Hide()
    end
    
    if not barFrame.stackedBars then
      barFrame.stackedBars = {}
    end
    
    while #barFrame.stackedBars < 2 do
      local bar = CreateFrame("StatusBar", nil, barFrame)
      table.insert(barFrame.stackedBars, bar)
    end
    
    -- Bar 1: First half color (0 to midpoint)
    local bar1 = barFrame.stackedBars[1]
    
    -- PERFORMANCE: Only apply expensive setup when appearance changes
    if needsSetup or not bar1._setupDone then
      bar1:SetParent(barFrame)
      bar1:SetOrientation(barOrientation)
      bar1:SetReverseFill(isBarReverseFill)
      bar1:SetRotatesTexture(isBarVertical)
      bar1:SetStatusBarTexture(texturePath)
      bar1:SetFrameLevel(barFrame:GetFrameLevel() + 1)
      ApplyBarSmoothing(bar1, enableSmooth)
      bar1._setupDone = true
    end
    
    bar1:ClearAllPoints()
    bar1:SetAllPoints(barFrame)  -- Fill entire frame like MWRB
    bar1:SetMinMaxValues(0, midpoint)
    bar1:SetStatusBarColor(color1.r, color1.g, color1.b, color1.a or 1)
    ApplyBarGradient(bar1, barConfig)  -- Apply gradient effect
    bar1:SetValue(effectiveStacks)  -- Will cap at midpoint naturally
    bar1:Show()
    
    -- Bar 2: Second half color (midpoint to max) - overlays bar1 directly
    local bar2 = barFrame.stackedBars[2]
    
    -- PERFORMANCE: Only apply expensive setup when appearance changes
    if needsSetup or not bar2._setupDone then
      bar2:SetParent(barFrame)
      bar2:SetOrientation(barOrientation)
      bar2:SetReverseFill(isBarReverseFill)
      bar2:SetRotatesTexture(isBarVertical)
      bar2:SetStatusBarTexture(texturePath)
      bar2:SetFrameLevel(barFrame:GetFrameLevel() + 2)
      ApplyBarSmoothing(bar2, enableSmooth)
      bar2._setupDone = true
    end
    
    bar2:ClearAllPoints()
    bar2:SetAllPoints(barFrame)  -- Fill entire frame like MWRB
    bar2:SetMinMaxValues(midpoint, maxStacks)
    bar2:SetStatusBarColor(color2.r, color2.g, color2.b, color2.a or 1)
    ApplyBarGradient(bar2, barConfig)  -- Apply gradient effect
    bar2:SetValue(effectiveStacks)  -- Only fills when stacks > midpoint
    bar2:Show()
    
    -- MAX COLOR OVERLAY for folded mode
    local enableMaxColor = barConfig.display.enableMaxColor
    if enableMaxColor and maxStacks > 1 then
      if not barFrame.maxColorBar then
        barFrame.maxColorBar = CreateFrame("StatusBar", nil, barFrame)
      end
      
      local maxBar = barFrame.maxColorBar
      
      -- PERFORMANCE: Only apply expensive setup when appearance changes
      if needsSetup or not maxBar._setupDone then
        maxBar:SetOrientation(barOrientation)
        maxBar:SetReverseFill(isBarReverseFill)
        maxBar:SetRotatesTexture(isBarVertical)
        maxBar:SetStatusBarTexture(texturePath)
        maxBar:SetFrameLevel(barFrame:GetFrameLevel() + 21)
        ApplyBarSmoothing(maxBar, enableSmooth)
        maxBar._setupDone = true
      end
      
      local maxColor = barConfig.display.maxColor or {r=0, g=1, b=0, a=1}
      
      maxBar:ClearAllPoints()
      maxBar:SetAllPoints(barFrame)
      maxBar:SetMinMaxValues(maxStacks - 1, maxStacks)
      maxBar:SetStatusBarColor(maxColor.r, maxColor.g, maxColor.b, maxColor.a or 1)
      ApplyBarGradient(maxBar, barConfig)  -- Apply gradient effect
      maxBar:SetValue(effectiveStacks)
      maxBar:Show()
    elseif barFrame.maxColorBar then
      barFrame.maxColorBar:Hide()
    end
    
  else
    -- ═══════════════════════════════════════════════════════════════
    -- SIMPLE MODE: 2 bars (base + optional max color overlay)
    -- ═══════════════════════════════════════════════════════════════
    barFrame.bar:SetAlpha(0)
    
    local maxColor = barConfig.display.maxColor or {r=0, g=1, b=0, a=1}
    local enableMaxColor = barConfig.display.enableMaxColor
    
    -- Get smoothing setting
    local enableSmooth = barConfig.display.enableSmoothing
    
    -- Hide maxColorBar from continuous mode (simple mode uses stackedBars[2] instead)
    if barFrame.maxColorBar then
      barFrame.maxColorBar:Hide()
    end
    
    if not barFrame.stackedBars then
      barFrame.stackedBars = {}
    end
    
    while #barFrame.stackedBars < 2 do
      local bar = CreateFrame("StatusBar", nil, barFrame)
      table.insert(barFrame.stackedBars, bar)
    end
    
    if enableMaxColor and maxStacks > 1 then
      -- TWO BARS: base (full width) + max color overlay (full width, on top)
      
      -- Bar 1: Base color (0 to max) - full width
      local bar1 = barFrame.stackedBars[1]
      
      -- PERFORMANCE: Only apply expensive setup when appearance changes
      if needsSetup or not bar1._setupDone then
        bar1:SetOrientation(barOrientation)
        bar1:SetReverseFill(isBarReverseFill)
        bar1:SetRotatesTexture(isBarVertical)
        bar1:SetStatusBarTexture(texturePath)
        bar1:SetFrameLevel(barFrame:GetFrameLevel() + 1)
        ApplyBarSmoothing(bar1, enableSmooth)
        bar1._setupDone = true
      end
      
      bar1:ClearAllPoints()
      bar1:SetAllPoints(barFrame)  -- Fill entire frame like MWRB
      bar1:SetMinMaxValues(0, maxStacks)
      bar1:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
      ApplyBarGradient(bar1, barConfig)  -- Apply gradient effect
      bar1:SetValue(effectiveStacks)
      bar1:Show()
      
      -- Bar 2: Max color overlay (max-1 to max) - full width, on top
      -- Only fills when at max stacks
      local bar2 = barFrame.stackedBars[2]
      
      -- PERFORMANCE: Only apply expensive setup when appearance changes
      if needsSetup or not bar2._setupDone then
        bar2:SetOrientation(barOrientation)
        bar2:SetReverseFill(isBarReverseFill)
        bar2:SetRotatesTexture(isBarVertical)
        bar2:SetStatusBarTexture(texturePath)
        bar2:SetFrameLevel(barFrame:GetFrameLevel() + 2)
        ApplyBarSmoothing(bar2, enableSmooth)
        bar2._setupDone = true
      end
      
      bar2:ClearAllPoints()
      bar2:SetAllPoints(barFrame)  -- Fill entire frame like MWRB
      bar2:SetMinMaxValues(maxStacks - 1, maxStacks)
      bar2:SetStatusBarColor(maxColor.r, maxColor.g, maxColor.b, maxColor.a or 1)
      ApplyBarGradient(bar2, barConfig)  -- Apply gradient effect
      bar2:SetValue(effectiveStacks)
      bar2:Show()
    else
      -- SINGLE BAR: just base color
      local bar1 = barFrame.stackedBars[1]
      
      -- PERFORMANCE: Only apply expensive setup when appearance changes
      if needsSetup or not bar1._setupDone then
        bar1:SetOrientation(barOrientation)
        bar1:SetReverseFill(isBarReverseFill)
        bar1:SetRotatesTexture(isBarVertical)
        bar1:SetStatusBarTexture(texturePath)
        bar1:SetFrameLevel(barFrame:GetFrameLevel() + 1)
        ApplyBarSmoothing(bar1, enableSmooth)
        bar1._setupDone = true
      end
      
      bar1:ClearAllPoints()
      bar1:SetAllPoints(barFrame)  -- Fill entire frame like MWRB
      bar1:SetMinMaxValues(0, maxStacks)
      bar1:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
      ApplyBarGradient(bar1, barConfig)  -- Apply gradient effect
      bar1:SetValue(effectiveStacks)
      bar1:Show()
      
      barFrame.stackedBars[2]:Hide()
    end
  end
  
  -- Update text (SetText handles secret values!)
  if barConfig.display.showText then
    if showPreview then
      textFrame.text:SetText(effectiveStacks)
    else
      textFrame.text:SetText(stacks)
    end
    local tc = barConfig.display.textColor
    textFrame.text:SetTextColor(tc.r, tc.g, tc.b, tc.a)
  end
  
  -- Update duration text (pass secret value directly from GetText/GetValue to SetText)
  if barConfig.display.showDuration and durationFrame then
    -- durationFontString can be either:
    -- 1. A FontString reference (from icon source) - use GetText()
    -- 2. A StatusBar reference (from bar source) - use GetValue()
    -- 3. A wrapper object with GetAuraInfo() for direct API access
    -- 4. A wrapper object with GetText() for cooldownCharge passthrough
    
    local shouldHide = false
    local durationValue = nil
    local decimals = barConfig.display.durationDecimals or 1
    
    -- Store decimals on frame for OnUpdate access
    durationFrame.storedDecimals = decimals
    
    if showPreview then
      -- Preview mode - show sample duration value, clear OnUpdate
      durationFrame:SetScript("OnUpdate", nil)
      durationFrame.isActive = false
      durationFrame.sourceBar = nil
      
      local maxDuration = barConfig.tracking.maxDuration or 30
      local pct = previewStacks or 0.5
      local previewDurationValue = maxDuration * pct
      durationValue = string.format("%." .. decimals .. "f", previewDurationValue)
    elseif durationFontString and durationFontString.GetAuraInfo then
      -- Has GetAuraInfo - use DurationObject for auto-updating countdown text
      local auraID, unit = durationFontString:GetAuraInfo()
      if auraID and unit and active then
        -- Store current aura info for OnUpdate
        durationFrame.sourceBar = durationFontString
        durationFrame.isActive = true
        
        -- Set up OnUpdate to poll GetRemainingDuration() with fresh DurationObject
        if not durationFrame.durationOnUpdate then
          durationFrame.durationOnUpdate = function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < 0.03 then return end  -- ~30fps
            self.elapsed = 0
            
            if not self.isActive or not self.sourceBar then return end
            
            -- Get current auraID from sourceBar (may have changed due to refresh)
            local currentAuraID, currentUnit = self.sourceBar:GetAuraInfo()
            if not currentAuraID or not currentUnit then
              self.text:SetText("")
              return
            end
            
            -- Get fresh DurationObject (handles aura refresh automatically)
            local ok, durObj = pcall(C_UnitAuras.GetAuraDuration, currentUnit, currentAuraID)
            if ok and durObj then
              local okRemaining, remaining = pcall(durObj.GetRemainingDuration, durObj)
              if okRemaining then
                self.text:SetText(FormatDuration(remaining, self.storedDecimals))
              else
                self.text:SetText("")
              end
            else
              self.text:SetText("")
            end
          end
        end
        durationFrame:SetScript("OnUpdate", durationFrame.durationOnUpdate)
        
        -- Initial text set
        local ok, durObj = pcall(C_UnitAuras.GetAuraDuration, unit, auraID)
        if ok and durObj then
          local okRemaining, remaining = pcall(durObj.GetRemainingDuration, durObj)
          if okRemaining then
            durationFrame.text:SetText(FormatDuration(remaining, decimals))
          end
        end
        
        local dc = barConfig.display.durationColor or {r=1, g=1, b=1, a=1}
        durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
        durationFrame:Show()
      elseif not active then
        -- Not active - clear OnUpdate, show for options preview or user preference
        durationFrame:SetScript("OnUpdate", nil)
        durationFrame.isActive = false
        durationFrame.sourceBar = nil
        
        if optionsOpen then
          durationValue = string.format("%." .. decimals .. "f", 0)
        elseif barConfig.display.durationShowWhenReady then
          durationValue = string.format("%." .. decimals .. "f", 0)
        else
          shouldHide = true
        end
      else
        durationFrame:SetScript("OnUpdate", nil)
        durationFrame.isActive = false
        durationFrame.sourceBar = nil
        shouldHide = true
      end
    elseif durationFontString and durationFontString.GetValue then
      -- It's a StatusBar or wrapper - pass value directly to SetText (secret-safe)
      durationFrame:SetScript("OnUpdate", nil)
      durationFrame.isActive = false
      durationFrame.sourceBar = nil
      
      if active then
        durationFrame.text:SetText(durationFontString:GetValue())
        local dc = barConfig.display.durationColor or {r=1, g=1, b=1, a=1}
        durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
        durationFrame:Show()
      else
        -- Not active - show for options preview, otherwise check user preference
        if optionsOpen then
          durationValue = string.format("%." .. decimals .. "f", 0)
        elseif barConfig.display.durationShowWhenReady then
          durationValue = string.format("%." .. decimals .. "f", 0)
        else
          shouldHide = true
        end
      end
    elseif durationFontString and durationFontString.GetText then
      -- It's a FontString or wrapper - use GetText
      durationFrame:SetScript("OnUpdate", nil)
      durationFrame.isActive = false
      durationFrame.sourceBar = nil
      
      -- GetText can return secret values during combat - can't compare them!
      -- But we CAN check IsShown() which is non-secret
      
      -- Check if the source is visible (non-secret check)
      local sourceShown = false  -- Default to false (hidden)
      if durationFontString.IsShown then
        local ok, result = pcall(function() return durationFontString:IsShown() end)
        if ok then sourceShown = result end
      end
      
      if sourceShown then
        -- Source is showing duration - pass directly to SetText (whitelisted)
        durationFrame.text:SetText(durationFontString:GetText())
        local dc = barConfig.display.durationColor or {r=1, g=1, b=1, a=1}
        durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
        durationFrame:Show()
      else
        -- Source is hidden (spell ready/not on cooldown)
        if optionsOpen then
          -- Show for options preview
          durationFrame.text:SetText("0")
          local dc = barConfig.display.durationColor or {r=1, g=1, b=1, a=1}
          durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
          durationFrame:Show()
        elseif barConfig.display.durationShowWhenReady then
          -- User wants to show "0" when ready
          durationFrame.text:SetText("0")
          local dc = barConfig.display.durationColor or {r=1, g=1, b=1, a=1}
          durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
          durationFrame:Show()
        else
          -- Default: hide when ready
          durationFrame:Hide()
        end
      end
    else
      -- No duration source - clear OnUpdate
      durationFrame:SetScript("OnUpdate", nil)
      durationFrame.isActive = false
      durationFrame.sourceBar = nil
      
      if optionsOpen then
        durationValue = "0"
      elseif barConfig.display.durationShowWhenReady then
        durationValue = "0"
      else
        shouldHide = true
      end
    end
    
    -- Apply show/hide and text (only for non-FontString sources)
    if shouldHide then
      durationFrame:Hide()
    elseif durationValue then
      durationFrame.text:SetText(durationValue)
      local dc = barConfig.display.durationColor or {r=1, g=1, b=1, a=1}
      durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
      durationFrame:Show()
    end
  end
  
  -- Check if vertical bar
  local isVertical = (barConfig.display.barOrientation == "vertical")
  
  -- Update tick marks using shared function
  UpdateTickMarks(barFrame, barConfig, maxStacks, displayMode)
  
  -- Bar icon - show tracking icon alongside bar (for all bar types)
  if barConfig.display.showBarIcon and barIconFrame then
    -- Set icon texture
    if iconTexture then
      barIconFrame.icon:SetTexture(iconTexture)
    elseif barConfig.tracking.iconTextureID then
      barIconFrame.icon:SetTexture(barConfig.tracking.iconTextureID)
    elseif barConfig.tracking.spellID then
      local texture = C_Spell.GetSpellTexture(barConfig.tracking.spellID)
      if texture then
        barIconFrame.icon:SetTexture(texture)
      end
    end
    
    -- Border
    if barConfig.display.barIconShowBorder then
      local bc = barConfig.display.barIconBorderColor or {r=0, g=0, b=0, a=1}
      barIconFrame.background:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
      barIconFrame.background:Show()
    else
      barIconFrame.background:Hide()
    end
    
    barIconFrame:Show()
  elseif barIconFrame then
    barIconFrame:Hide()
  end
  
  -- Visibility already determined at function start - just show/hide based on that
  if shouldShow and barConfig.display.enabled then
    barFrame:Show()
    if barConfig.display.showText then
      textFrame:Show()
    else
      textFrame:Hide()
    end
    -- Duration visibility is handled earlier in the function based on IsShown() check
    if barConfig.display.showBarIcon and barIconFrame then
      barIconFrame:Show()
    end
  else
    barFrame:Hide()
    textFrame:Hide()
    if durationFrame then durationFrame:Hide() end
    if barIconFrame then barIconFrame:Hide() end
  end
end

-- ===================================================================
-- HIDE SPECIFIC BAR
-- ===================================================================
function ns.Display.HideBar(barNumber)
  -- Early exit if frames don't exist or are already hidden
  -- This prevents redundant work when called repeatedly by the ticker
  if not barFrames[barNumber] then
    customTrackingState[barNumber] = nil
    return
  end
  
  -- Check if ALL frames are already hidden (icon, bar, text, duration)
  -- FIXED: Must include textFrame and durationFrame in the check to prevent ghost "0" text
  local frames = barFrames[barNumber]
  local iconFrame = frames.iconFrame
  local barFrame = frames.barFrame
  local textFrame = frames.textFrame
  local durationFrame = frames.durationFrame
  
  local iconHidden = not iconFrame or not iconFrame:IsShown()
  local barHidden = not barFrame or not barFrame:IsShown()
  local textHidden = not textFrame or not textFrame:IsShown()
  local durationHidden = not durationFrame or not durationFrame:IsShown()
  
  -- Only skip if ALL frames are hidden
  if iconHidden and barHidden and textHidden and durationHidden then
    return  -- Already hidden, no work needed
  end
  
  -- Clear custom tracking state
  customTrackingState[barNumber] = nil
  
  if barFrames[barNumber] then
    barFrames[barNumber].barFrame:Hide()
    barFrames[barNumber].textFrame:Hide()
    
    -- Clear text values to prevent stale "0" showing
    if barFrames[barNumber].textFrame.text then
      barFrames[barNumber].textFrame.text:SetText("")
    end
    
    if barFrames[barNumber].durationFrame then
      barFrames[barNumber].durationFrame:Hide()
      if barFrames[barNumber].durationFrame.text then
        barFrames[barNumber].durationFrame.text:SetText("")
      end
    end
    if barFrames[barNumber].iconFrame then
      barFrames[barNumber].iconFrame:Hide()
      -- CRITICAL: Also hide child textures explicitly
      -- In some edge cases, child textures can remain visible even when parent is hidden
      if barFrames[barNumber].iconFrame.icon then
        barFrames[barNumber].iconFrame.icon:Hide()
      end
      if barFrames[barNumber].iconFrame.background then
        barFrames[barNumber].iconFrame.background:Hide()
      end
      if barFrames[barNumber].iconFrame.cooldown then
        barFrames[barNumber].iconFrame.cooldown:Hide()
      end
      -- Clear icon frame text elements
      if barFrames[barNumber].iconFrame.stacks then
        barFrames[barNumber].iconFrame.stacks:SetText("")
      end
      if barFrames[barNumber].iconFrame.duration then
        barFrames[barNumber].iconFrame.duration:SetText("")
      end
      if barFrames[barNumber].iconFrame.stacksFrame and barFrames[barNumber].iconFrame.stacksFrame.text then
        barFrames[barNumber].iconFrame.stacksFrame.text:SetText("")
      end
    end
    if barFrames[barNumber].nameFrame then
      barFrames[barNumber].nameFrame:Hide()
      if barFrames[barNumber].nameFrame.text then
        barFrames[barNumber].nameFrame.text:SetText("")
      end
    end
    if barFrames[barNumber].barIconFrame then
      barFrames[barNumber].barIconFrame:Hide()
    end
  end
  -- Also hide multi-icon frames
  HideMultiIconFrames(barNumber)
end

-- ===================================================================
-- DELETE CONFIRMATION DIALOG
-- ===================================================================
local deleteConfirmFrame = nil

ShowDeleteConfirmation = function(barNumber, barType)
  barType = barType or "buff"
  
  if not deleteConfirmFrame then
    deleteConfirmFrame = CreateFrame("Frame", "ArcUIDeleteConfirm", UIParent, "BackdropTemplate")
    deleteConfirmFrame:SetSize(300, 120)
    deleteConfirmFrame:SetFrameStrata("TOOLTIP")
    deleteConfirmFrame:SetToplevel(true)
    deleteConfirmFrame:SetFrameLevel(9999)
    deleteConfirmFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    deleteConfirmFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    deleteConfirmFrame:EnableMouse(true)
    deleteConfirmFrame:SetMovable(true)
    deleteConfirmFrame:RegisterForDrag("LeftButton")
    deleteConfirmFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    deleteConfirmFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    deleteConfirmFrame:SetClampedToScreen(true)
    
    deleteConfirmFrame.title = deleteConfirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    deleteConfirmFrame.title:SetPoint("TOP", 0, -16)
    deleteConfirmFrame.title:SetText("Delete Bar?")
    
    deleteConfirmFrame.text = deleteConfirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deleteConfirmFrame.text:SetPoint("TOP", 0, -40)
    deleteConfirmFrame.text:SetWidth(260)
    
    deleteConfirmFrame.deleteBtn = CreateFrame("Button", nil, deleteConfirmFrame, "UIPanelButtonTemplate")
    deleteConfirmFrame.deleteBtn:SetSize(100, 24)
    deleteConfirmFrame.deleteBtn:SetPoint("BOTTOMLEFT", 30, 16)
    deleteConfirmFrame.deleteBtn:SetText("Delete")
    
    deleteConfirmFrame.cancelBtn = CreateFrame("Button", nil, deleteConfirmFrame, "UIPanelButtonTemplate")
    deleteConfirmFrame.cancelBtn:SetSize(100, 24)
    deleteConfirmFrame.cancelBtn:SetPoint("BOTTOMRIGHT", -30, 16)
    deleteConfirmFrame.cancelBtn:SetText("Cancel")
    deleteConfirmFrame.cancelBtn:SetScript("OnClick", function() deleteConfirmFrame:Hide() end)
  end
  
  -- Get bar name for display
  local barName = "Bar " .. barNumber
  local cfg = ns.API and ns.API.GetBarConfig and ns.API.GetBarConfig(barNumber)
  if cfg and cfg.tracking then
    if cfg.tracking.buffName and cfg.tracking.buffName ~= "" then
      barName = cfg.tracking.buffName
    elseif cfg.tracking.spellName and cfg.tracking.spellName ~= "" then
      barName = cfg.tracking.spellName
    end
  end
  
  deleteConfirmFrame.text:SetText(string.format("Delete %s?", barName))
  deleteConfirmFrame.deleteBtn:SetScript("OnClick", function()
    ns.Display.DeleteBar(barNumber)
    deleteConfirmFrame:Hide()
  end)
  
  deleteConfirmFrame:ClearAllPoints()
  deleteConfirmFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
  deleteConfirmFrame:Raise()
  deleteConfirmFrame:Show()
end

-- Expose for external use
ns.Display.ShowDeleteConfirmation = ShowDeleteConfirmation

-- ===================================================================
-- DELETE BAR (Clear config and hide)
-- ===================================================================
function ns.Display.DeleteBar(barNumber)
  local cfg = ns.API and ns.API.GetBarConfig and ns.API.GetBarConfig(barNumber)
  if cfg then
    -- Get fresh defaults for a complete reset
    local defaults = ns.DB_DEFAULTS and ns.DB_DEFAULTS.char and ns.DB_DEFAULTS.char.bars and ns.DB_DEFAULTS.char.bars[1]
    
    if defaults then
      -- Fully reset tracking config to defaults
      if defaults.tracking then
        for k, v in pairs(defaults.tracking) do
          if type(v) == "table" then
            cfg.tracking[k] = CopyTable(v)
          else
            cfg.tracking[k] = v
          end
        end
      end
      cfg.tracking.enabled = false  -- Make sure it's disabled
      
      -- Fully reset display config to defaults
      if defaults.display then
        for k, v in pairs(defaults.display) do
          if type(v) == "table" then
            cfg.display[k] = CopyTable(v)
          else
            cfg.display[k] = v
          end
        end
      end
      cfg.display.enabled = false  -- Make sure it's disabled
      
      -- Fully reset behavior config to defaults
      if defaults.behavior then
        for k, v in pairs(defaults.behavior) do
          if type(v) == "table" then
            cfg.behavior[k] = CopyTable(v)
          else
            cfg.behavior[k] = v
          end
        end
      end
      
      -- Reset events if present
      if defaults.events then
        cfg.events = CopyTable(defaults.events)
      else
        cfg.events = {}
      end
      
      -- Clear migration flag so settings are re-migrated if needed
      cfg._migrated = nil
    else
      -- Fallback: just clear tracking config (legacy behavior)
      cfg.tracking.enabled = false
      cfg.tracking.trackType = "buff"
      cfg.tracking.cooldownID = 0
      cfg.tracking.spellID = 0
      cfg.tracking.spellName = ""
      cfg.tracking.buffName = ""
      cfg.tracking.maxStacks = 10
      cfg.tracking.customEnabled = false
      cfg.tracking.iconTextureID = 0
      cfg.tracking.auraInstanceID = 0
      cfg.tracking.slotNumber = 0
      cfg.display.enabled = false
    end
    
    -- Hide the bar (this will hide ALL frames including icons)
    ns.Display.HideBar(barNumber)
    
    -- Clear any custom tracking state
    customTrackingState[barNumber] = nil
    
    -- Refresh options panel
    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end
  end
end

-- ===================================================================
-- SHOW/HIDE DELETE BUTTONS ON ALL BARS
-- Only visible when options panel is open
-- ===================================================================

function ns.Display.ShowDeleteButtons()
  deleteButtonsVisible = true
  for barNumber, frames in pairs(barFrames) do
    if frames then
      -- Show on barFrame if visible and has delete button
      local barFrame = frames.barFrame
      if barFrame and barFrame:IsShown() and barFrame.deleteButton then
        barFrame.deleteButton:Show()
      end
      -- Show on iconFrame if visible and has delete button  
      local iconFrame = frames.iconFrame
      if iconFrame and iconFrame:IsShown() and iconFrame.deleteButton then
        iconFrame.deleteButton:Show()
      end
    end
  end
end

function ns.Display.HideDeleteButtons()
  deleteButtonsVisible = false
  for barNumber, frames in pairs(barFrames) do
    if frames then
      local barFrame = frames.barFrame
      if barFrame and barFrame.deleteButton then
        barFrame.deleteButton:Hide()
      end
      local iconFrame = frames.iconFrame
      if iconFrame and iconFrame.deleteButton then
        iconFrame.deleteButton:Hide()
      end
    end
  end
end

function ns.Display.AreDeleteButtonsVisible()
  return deleteButtonsVisible
end

-- ===================================================================
-- UPDATE CUSTOM BAR (Cast-based tracking with duration countdown)
-- ===================================================================
function ns.Display.UpdateCustomBar(barNumber, stacks, maxStacks, active, remainingDuration, iconTexture)
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig or not barConfig.tracking.customEnabled then
    -- Custom bar not configured - hide it
    if barFrames[barNumber] then
      barFrames[barNumber].barFrame:Hide()
      barFrames[barNumber].textFrame:Hide()
      if barFrames[barNumber].durationFrame then
        barFrames[barNumber].durationFrame:Hide()
      end
      if barFrames[barNumber].iconFrame then
        barFrames[barNumber].iconFrame:Hide()
      end
    end
    return
  end
  
  -- PERFORMANCE: Cache expensive lookups
  local optionsOpen = IsOptionsOpen()
  local currentSpec = GetCachedSpec()
  
  -- Get values from config if not provided
  maxStacks = tonumber(maxStacks) or tonumber(barConfig.tracking.customMaxStacks) or 10
  if maxStacks < 1 then maxStacks = 10 end
  stacks = stacks or 0
  remainingDuration = remainingDuration or 0
  
  local barFrame, textFrame, durationFrame, iconFrame = GetBarFrames(barNumber)
  local displayType = barConfig.display.displayType or "bar"
  
  -- Format duration text
  local durationText = ""
  if remainingDuration > 0 then
    if remainingDuration >= 10 then
      durationText = string.format("%.0f", remainingDuration)
    else
      durationText = string.format("%.1f", remainingDuration)
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- ICON MODE (Custom)
  -- ═══════════════════════════════════════════════════════════════════
  if displayType == "icon" then
    -- Hide bar elements
    barFrame:Hide()
    textFrame:Hide()
    durationFrame:Hide()
    
    local cfg = barConfig.display
    
    -- Set icon texture
    if iconTexture then
      iconFrame.icon:SetTexture(iconTexture)
    elseif barConfig.tracking.customSpellID and barConfig.tracking.customSpellID > 0 then
      local texture = C_Spell.GetSpellTexture(barConfig.tracking.customSpellID)
      if texture then
        iconFrame.icon:SetTexture(texture)
      end
    end
    
    -- Apply icon zoom (for custom tracking icons)
    local zoom = cfg.iconZoom or 0
    local minCoord = 0.08 + (zoom * 0.42)
    local maxCoord = 0.92 - (zoom * 0.42)
    iconFrame.icon:SetTexCoord(minCoord, maxCoord, minCoord, maxCoord)
    
    -- Show/hide icon texture based on iconShowTexture
    -- SAFETY: Also verify custom tracking is enabled
    if cfg.iconShowTexture == false or not barConfig.tracking.customEnabled then
      iconFrame.icon:Hide()
      iconFrame.background:Hide()
    else
      iconFrame.icon:Show()
    end
    
    -- Update stacks text
    if cfg.iconShowStacks then
      local stackAnchor = cfg.iconStackAnchor or "TOPRIGHT"
      local stackText
      local sc = cfg.iconStackColor or {r=1, g=1, b=1, a=1}
      
      if stackAnchor == "FREE" then
        stackText = iconFrame.stacksFrame.text
        iconFrame.stacks:Hide()
        iconFrame.stacksFrame:Show()
      else
        stackText = iconFrame.stacks
        iconFrame.stacksFrame:Hide()
        iconFrame.stacks:Show()
      end
      
      if active and stacks then
        stackText:SetText(stacks)
      else
        stackText:SetText("0")
      end
      stackText:SetTextColor(sc.r, sc.g, sc.b, sc.a)
    else
      iconFrame.stacks:Hide()
      iconFrame.stacksFrame:Hide()
    end
    
    -- Update duration text (custom countdown)
    if cfg.iconShowDuration then
      iconFrame.duration:SetText(durationText)
      local dc = cfg.iconDurationColor or {r=1, g=1, b=1, a=1}
      iconFrame.duration:SetTextColor(dc.r, dc.g, dc.b, dc.a)
      iconFrame.duration:Show()
    else
      iconFrame.duration:Hide()
    end
    
    -- Border
    if cfg.iconShowBorder then
      local bc = cfg.iconBorderColor or {r=0, g=0, b=0, a=1}
      iconFrame.background:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
      iconFrame.background:Show()
    else
      iconFrame.background:Hide()
    end
    
    -- Visibility
    local shouldShow = true
    
    if not InCombatLockdown() and barConfig.behavior.hideOutOfCombat then
      shouldShow = false
    end
    
    if not active then
      iconFrame.duration:SetText("")
    end
    
    if shouldShow and cfg.enabled then
      iconFrame:Show()
    else
      iconFrame:Hide()
    end
    
    return  -- Exit early for icon mode
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- BAR MODE (Custom)
  -- ═══════════════════════════════════════════════════════════════════
  if iconFrame then
    iconFrame:Hide()
  end
  
  local displayMode = barConfig.display.thresholdMode or "simple"
  local thresholds = barConfig.thresholds or {}
  
  -- Determine color based on stacks
  local fillColor = barConfig.display.barColor or {r=0, g=0.5, b=1, a=1}
  
  -- Check for max color
  if barConfig.display.enableMaxColor and stacks >= maxStacks then
    fillColor = barConfig.display.maxColor or {r=0, g=1, b=0, a=1}
  end
  
  -- Simple bar display for custom bars
  -- Hide any stacked bars
  if barFrame.stackedBars then
    for i = 1, #barFrame.stackedBars do
      SafeHide(barFrame.stackedBars[i])
    end
  end
  
  -- Use main status bar
  local percent = (stacks / maxStacks)
  if percent > 1 then percent = 1 end
  if percent < 0 then percent = 0 end
  
  barFrame.bar:SetMinMaxValues(0, 1)
  barFrame.bar:SetValue(percent)
  barFrame.bar:SetStatusBarColor(fillColor.r, fillColor.g, fillColor.b, fillColor.a)
  barFrame.bar:Show()
  
  -- Update stacks text
  if barConfig.display.showText then
    textFrame.text:SetText(stacks)
    local tc = barConfig.display.textColor
    textFrame.text:SetTextColor(tc.r, tc.g, tc.b, tc.a)
  end
  
  -- Update duration text (use our countdown value)
  if barConfig.display.showDuration and durationFrame then
    durationFrame.text:SetText(durationText)
    local dc = barConfig.display.durationColor or {r=1, g=1, b=1, a=1}
    durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
  end
  
  -- Visibility logic
  local shouldShow = active
  
  -- Hide when inactive if option enabled (but not if options panel is open)
  if not active and barConfig.behavior.hideWhenInactive and not optionsOpen then
    shouldShow = false
  end
  
  -- Hide if out of combat and configured to do so
  if not InCombatLockdown() and barConfig.behavior.hideOutOfCombat then
    shouldShow = false
  end
  
  -- Hide if at zero and configured to do so
  if barConfig.behavior.hideWhenEmpty and stacks == 0 then
    shouldShow = false
  end
  
  -- Hide if at max and configured to do so
  if barConfig.behavior.hideAtMax and stacks >= maxStacks then
    shouldShow = false
  end
  
  -- Check spec visibility (use cached spec)
  if barConfig.behavior.showOnSpecs and #barConfig.behavior.showOnSpecs > 0 then
    local specAllowed = false
    for _, spec in ipairs(barConfig.behavior.showOnSpecs) do
      if spec == currentSpec then
        specAllowed = true
        break
      end
    end
    if not specAllowed then
      shouldShow = false
    end
  end
  
  -- Check talent conditions
  if shouldShow and ns.TrackingOptions and ns.TrackingOptions.AreTalentConditionsMet then
    if not ns.TrackingOptions.AreTalentConditionsMet(barConfig) then
      shouldShow = false
    end
  end
  
  -- Apply visibility
  if shouldShow and barConfig.display.enabled then
    barFrame:Show()
    if barConfig.display.showText then
      textFrame:Show()
    else
      textFrame:Hide()
    end
    if barConfig.display.showDuration and durationFrame then
      durationFrame:Show()
    elseif durationFrame then
      durationFrame:Hide()
    end
  else
    barFrame:Hide()
    textFrame:Hide()
    if durationFrame then durationFrame:Hide() end
  end
end

-- ===================================================================
-- UPDATE DURATION BAR (Bar-based duration tracking from BuffBarCooldownViewer)
-- This uses secret value passthrough from source bar to our bar
-- ===================================================================
function ns.Display.UpdateDurationBar(barNumber, stacks, maxStacks, active, sourceBar, stacksFontString, iconTexture)
  -- PROFILER: Track where time is spent
  local PM = ns.ProfilerMark
  if PM then PM("GetBarConfig") end
  
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig or not barConfig.tracking.enabled then
    if barFrames[barNumber] then
      barFrames[barNumber].barFrame:Hide()
      barFrames[barNumber].textFrame:Hide()
      if barFrames[barNumber].durationFrame then
        barFrames[barNumber].durationFrame:Hide()
      end
      if barFrames[barNumber].iconFrame then
        barFrames[barNumber].iconFrame:Hide()
      end
      if barFrames[barNumber].nameFrame then
        barFrames[barNumber].nameFrame:Hide()
      end
      if barFrames[barNumber].barIconFrame then
        barFrames[barNumber].barIconFrame:Hide()
      end
    end
    return
  end
  
  -- FLICKERING FIX: Skip real tracking updates when preview mode is active
  -- When previewMode is on, only allow updates from SetPreviewStacks (no sourceBar)
  if previewMode and IsOptionsOpen() and sourceBar then
    return  -- Skip real tracking update, let preview control the display
  end
  
  if PM then PM("VisibilityChecks") end
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- PERFORMANCE: Cache expensive lookups ONCE at start of function
  -- ═══════════════════════════════════════════════════════════════════════════
  local optionsOpen = IsOptionsOpen()
  local currentSpec = GetCachedSpec()
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- EARLY VISIBILITY CHECK: Skip all work if bar shouldn't be visible
  -- This uses cached spec and avoids redundant calculations later
  -- ═══════════════════════════════════════════════════════════════════════════
  local shouldShow = true
  
  -- Spec check (most common reason to hide)
  if barConfig.behavior and barConfig.behavior.showOnSpecs and #barConfig.behavior.showOnSpecs > 0 then
    shouldShow = false
    for _, spec in ipairs(barConfig.behavior.showOnSpecs) do
      if spec == currentSpec then
        shouldShow = true
        break
      end
    end
  end
  
  -- Combat check (only if not in options - we want to show bars for editing)
  if shouldShow and not optionsOpen and barConfig.behavior and barConfig.behavior.hideOutOfCombat and not InCombatLockdown() then
    shouldShow = false
  end
  
  -- Inactive check (if hideWhenInactive and not active, but show in options for editing)
  if shouldShow and not optionsOpen and not active and barConfig.behavior and barConfig.behavior.hideWhenInactive then
    shouldShow = false
  end
  
  -- Talent conditions check
  if shouldShow and ns.TrackingOptions and ns.TrackingOptions.AreTalentConditionsMet then
    if not ns.TrackingOptions.AreTalentConditionsMet(barConfig) then
      shouldShow = false
    end
  end
  
  -- Early exit if bar shouldn't show and options not open
  if not shouldShow and not optionsOpen then
    if barFrames[barNumber] then
      barFrames[barNumber].barFrame:Hide()
      barFrames[barNumber].textFrame:Hide()
      if barFrames[barNumber].durationFrame then
        barFrames[barNumber].durationFrame:Hide()
      end
      if barFrames[barNumber].iconFrame then
        barFrames[barNumber].iconFrame:Hide()
      end
      if barFrames[barNumber].nameFrame then
        barFrames[barNumber].nameFrame:Hide()
      end
      if barFrames[barNumber].barIconFrame then
        barFrames[barNumber].barIconFrame:Hide()
      end
    end
    return
  end
  
  if PM then PM("GetBarFrames") end
  
  local barFrame, textFrame, durationFrame, iconFrame, nameFrame, barIconFrame = GetBarFrames(barNumber)
  local displayType = barConfig.display.displayType or "bar"
  
  if PM then PM("OptionsValidation") end
  
  -- Config validation and overlay logic (only matters when options open)
  if optionsOpen then
    local tracking = barConfig.tracking
    local hasSpellIdentification = (tracking.spellID and tracking.spellID > 0) or 
                                    (tracking.cooldownID and tracking.cooldownID > 0) or 
                                    (tracking.buffName and tracking.buffName ~= "")
    local hasTrackType = tracking.trackType and tracking.trackType ~= "" and tracking.trackType ~= "none"
    local isCustomTracking = tracking.trackType == "customAura" or tracking.trackType == "customCooldown"
    local isProperlyConfigured = isCustomTracking or (hasSpellIdentification and hasTrackType)
    
    if not isProperlyConfigured then
      if displayType == "icon" then
        barFrame:Hide()
        textFrame:Hide()
        if durationFrame then durationFrame:Hide() end
        if nameFrame then nameFrame:Hide() end
        if barIconFrame then barIconFrame:Hide() end
        
        iconFrame:Show()
        if iconFrame.missingSetupOverlay then
          iconFrame.missingSetupOverlay:Show()
        end
        if iconFrame.trackingFailOverlay then iconFrame.trackingFailOverlay:Hide() end
        if iconFrame.stacksFrame then iconFrame.stacksFrame:Hide() end
        iconFrame.stacks:Hide()
      else
        iconFrame:Hide()
        if iconFrame.stacksFrame then iconFrame.stacksFrame:Hide() end
        textFrame:Hide()
        if durationFrame then durationFrame:Hide() end
        if nameFrame then nameFrame:Hide() end
        if barIconFrame then barIconFrame:Hide() end
        
        barFrame:Show()
        if barFrame.missingSetupOverlay then
          barFrame.missingSetupOverlay:Show()
        end
        if barFrame.trackingFailOverlay then barFrame.trackingFailOverlay:Hide() end
      end
      return
    end
    
    -- Tracking fail overlay (only when options open)
    local trackingOK = ns.API.IsTrackingOK and ns.API.IsTrackingOK(barNumber)
    if not trackingOK and barConfig.tracking.cooldownID and barConfig.tracking.cooldownID > 0 then
      if displayType == "icon" then
        barFrame:Hide()
        textFrame:Hide()
        durationFrame:Hide()
        if nameFrame then nameFrame:Hide() end
        if barIconFrame then barIconFrame:Hide() end
        
        iconFrame:Show()
        if iconFrame.trackingFailOverlay then
          iconFrame.trackingFailOverlay:Show()
        end
        if iconFrame.stacksFrame then iconFrame.stacksFrame:Hide() end
        iconFrame.stacks:Hide()
      else
        iconFrame:Hide()
        if iconFrame.stacksFrame then iconFrame.stacksFrame:Hide() end
        textFrame:Hide()
        durationFrame:Hide()
        if nameFrame then nameFrame:Hide() end
        if barIconFrame then barIconFrame:Hide() end
        
        barFrame:Show()
        if barFrame.trackingFailOverlay then
          barFrame.trackingFailOverlay:Show()
        end
      end
      return
    end
  end
  
  -- Hide overlays (they were only shown when options open + error condition)
  if barFrame.missingSetupOverlay then
    barFrame.missingSetupOverlay:Hide()
  end
  if iconFrame and iconFrame.missingSetupOverlay then
    iconFrame.missingSetupOverlay:Hide()
  end
  if barFrame.trackingFailOverlay then
    barFrame.trackingFailOverlay:Hide()
  end
  if iconFrame and iconFrame.trackingFailOverlay then
    iconFrame.trackingFailOverlay:Hide()
  end
  
  maxStacks = tonumber(maxStacks) or 10
  if maxStacks < 1 then maxStacks = 10 end
  stacks = stacks or 0
  
  -- ═══════════════════════════════════════════════════════════════════
  -- ICON MODE (Duration)
  -- ═══════════════════════════════════════════════════════════════════
  if displayType == "icon" then
    barFrame:Hide()
    textFrame:Hide()
    durationFrame:Hide()
    if nameFrame then nameFrame:Hide() end
    if barIconFrame then barIconFrame:Hide() end
    
    local cfg = barConfig.display
    
    -- Set icon texture
    if iconTexture then
      iconFrame.icon:SetTexture(iconTexture)
    elseif barConfig.tracking.iconTextureID then
      iconFrame.icon:SetTexture(barConfig.tracking.iconTextureID)
    elseif barConfig.tracking.spellID then
      local texture = C_Spell.GetSpellTexture(barConfig.tracking.spellID)
      if texture then
        iconFrame.icon:SetTexture(texture)
      end
    end
    
    -- Apply icon zoom (for custom tracking icons)
    local zoom = cfg.iconZoom or 0
    local minCoord = 0.08 + (zoom * 0.42)
    local maxCoord = 0.92 - (zoom * 0.42)
    iconFrame.icon:SetTexCoord(minCoord, maxCoord, minCoord, maxCoord)
    
    -- SAFETY: Also verify bar is enabled (prevents ghost icons from deleted bars)
    if cfg.iconShowTexture == false or not barConfig.tracking.enabled then
      iconFrame.icon:Hide()
      iconFrame.background:Hide()
    else
      iconFrame.icon:Show()
    end
    
    -- Update stacks text (use secret value from stacksFontString if available)
    if cfg.iconShowStacks then
      local stackAnchor = cfg.iconStackAnchor or "TOPRIGHT"
      local stackText
      local sc = cfg.iconStackColor or {r=1, g=1, b=1, a=1}
      
      if stackAnchor == "FREE" then
        stackText = iconFrame.stacksFrame.text
        iconFrame.stacks:Hide()
        iconFrame.stacksFrame:Show()
      else
        stackText = iconFrame.stacks
        iconFrame.stacksFrame:Hide()
        iconFrame.stacks:Show()
      end
      
      -- Use stacks from auraInstanceID (passed as secret value) or stacksFontString
      if active and stacksFontString and stacksFontString.GetText then
        stackText:SetText(stacksFontString:GetText())
      elseif active and stacks then
        stackText:SetText(stacks)
      else
        -- Not active - show empty for duration icons
        stackText:SetText("")
      end
      stackText:SetTextColor(sc.r, sc.g, sc.b, sc.a)
    else
      iconFrame.stacks:Hide()
      iconFrame.stacksFrame:Hide()
    end
    
    -- Update duration (use C_UnitAuras.GetAuraDurationRemaining for secret-safe text)
    -- Use cached optionsOpen from function start
    local showPreview = optionsOpen and (not active or previewMode)
    
    if cfg.iconShowDuration then
      if showPreview then
        -- Preview mode - show sample duration
        local maxDuration = barConfig.tracking.maxDuration or 30
        local pct = previewStacks or 0.5
        local previewValue = maxDuration * pct
        local decimals = cfg.durationDecimals or 1
        iconFrame.duration:SetText(string.format("%." .. decimals .. "f", previewValue))
        iconFrame.duration:Show()
      elseif active and sourceBar and sourceBar.GetAuraInfo then
        -- Has GetAuraInfo - use C_UnitAuras.GetAuraDurationRemaining for secret-safe text
        local auraID, unit = sourceBar:GetAuraInfo()
        if auraID and unit then
          local textOK = pcall(function()
            local remaining = C_UnitAuras.GetAuraDurationRemaining(unit, auraID)
            iconFrame.duration:SetText(remaining)  -- Secret passes directly to SetText
          end)
          if not textOK and sourceBar.GetValue then
            iconFrame.duration:SetText(sourceBar:GetValue())
          end
        elseif sourceBar.GetValue then
          iconFrame.duration:SetText(sourceBar:GetValue())
        end
        iconFrame.duration:Show()
      elseif active and sourceBar and sourceBar.GetValue then
        -- Fallback: pass raw value through (secret-safe via SetText)
        iconFrame.duration:SetText(sourceBar:GetValue())
        iconFrame.duration:Show()
      else
        -- Not active - hide duration
        iconFrame.duration:SetText("")
        iconFrame.duration:Hide()
      end
      local dc = cfg.iconDurationColor or {r=1, g=1, b=1, a=1}
      iconFrame.duration:SetTextColor(dc.r, dc.g, dc.b, dc.a)
    else
      iconFrame.duration:Hide()
    end
    
    -- Border
    if cfg.iconShowBorder then
      local bc = cfg.iconBorderColor or {r=0, g=0, b=0, a=1}
      iconFrame.background:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
      iconFrame.background:Show()
    else
      iconFrame.background:Hide()
    end
    
    -- Visibility already determined at function start - just show if enabled
    if shouldShow and cfg.enabled then
      iconFrame:Show()
      iconFrame:SetAlpha(1)  -- Always full opacity for duration icons
    else
      iconFrame:Hide()
    end
    
    return
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- BAR MODE (Duration) - SECRET VALUE PASSTHROUGH
  -- Mirrors ArcUI_Resources.lua UpdateThresholdLayers EXACTLY
  -- ═══════════════════════════════════════════════════════════════════
  SafeHide(iconFrame)
  
  -- ═══════════════════════════════════════════════════════════════════
  -- HIDE ALL EXISTING BARS FIRST (like resource bar does)
  -- ═══════════════════════════════════════════════════════════════════
  SafeHide(barFrame.bar)
  
  if barFrame.stackedBars then
    for i = 1, #barFrame.stackedBars do SafeHide(barFrame.stackedBars[i]) end
  end
  if barFrame.granularBars then
    for i = 1, #barFrame.granularBars do SafeHide(barFrame.granularBars[i]) end
  end
  if barFrame.durationGranularBars then
    for i = 1, #barFrame.durationGranularBars do SafeHide(barFrame.durationGranularBars[i]) end
  end
  if barFrame.durationLayers then
    for i = 1, #barFrame.durationLayers do SafeHide(barFrame.durationLayers[i]) end
  end
  if barFrame.durationStackedBars then
    for i = 1, #barFrame.durationStackedBars do SafeHide(barFrame.durationStackedBars[i]) end
  end
  if barFrame.durationLayeredBars then
    for i = 1, #barFrame.durationLayeredBars do SafeHide(barFrame.durationLayeredBars[i]) end
  end
  
  -- Get base color from config
  local baseColor = barConfig.display.barColor or {r=0, g=0.5, b=1, a=1}
  
  -- Get orientation settings for duration bar
  local isDurationVertical = (barConfig.display.barOrientation == "vertical")
  local durationOrientation = isDurationVertical and "VERTICAL" or "HORIZONTAL"
  -- Timer direction handles drain/fill behavior:
  -- - Drain: RemainingTime (bar shrinks as time passes)
  -- - Fill: ElapsedTime (bar grows as time passes)
  -- ReverseFill controls anchor direction (left-to-right vs right-to-left)
  local fillMode = barConfig.display.durationBarFillMode or "drain"
  local isDurationReverseFill = barConfig.display.barReverseFill or false
  
  -- Get max duration from user config (always use this for consistency)
  -- Ensure maxValue is at least 1 for preview mode calculations
  local maxValue = barConfig.tracking.maxDuration or 30
  if maxValue <= 0 then maxValue = 30 end  -- Fallback for "auto" or invalid values
  
  -- Use cached optionsOpen from function start
  local showPreview = optionsOpen and (not active or previewMode)
  
  -- ═══════════════════════════════════════════════════════════════════
  -- COLORCURVE SUPPORT (v2.9.0 - Simplified)
  -- When enabled: bar fill color changes based on remaining duration %
  -- No trick needed - just evaluate curve and apply color to bar
  -- ═══════════════════════════════════════════════════════════════════
  local colorCurve = GetDurationColorCurve(barNumber, barConfig)
  local useColorCurve = colorCurve ~= nil and barConfig.display.durationColorCurveEnabled
  
  if PM then PM("AppearanceSetup") end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- PERFORMANCE: Only run expensive bar setup when appearance changes
  -- This avoids SetTexture, SetOrientation, LSM:Fetch every frame
  -- ═══════════════════════════════════════════════════════════════════
  local appearanceHash = GetBarAppearanceHash(barConfig)
  local needsSetup = barFrame._lastAppearanceHash ~= appearanceHash
  
  if needsSetup then
    -- Get texture (use global LSM from top of file) - only when needed
    local texturePath = "Interface\\TargetingFrame\\UI-StatusBar"
    if LSM and barConfig.display.texture then
      local fetchedTexture = LSM:Fetch("statusbar", barConfig.display.texture)
      if fetchedTexture then
        texturePath = fetchedTexture
      end
    end
    
    -- Apply expensive bar setup (padding always 0 - no UI option exposed)
    barFrame.bar:ClearAllPoints()
    barFrame.bar:SetAllPoints(barFrame)
    barFrame.bar:SetStatusBarTexture(texturePath)
    -- Note: Frame level is set by the strata block later, but set baseline here
    -- Fill bar should be 1 level above parent (background is at parent level)
    barFrame.bar:SetFrameLevel(barFrame:GetFrameLevel() + 1)
    
    -- Apply user's fill direction settings
    barFrame.bar:SetOrientation(durationOrientation)
    barFrame.bar:SetReverseFill(isDurationReverseFill)
    -- Rotate texture only when vertical (keeps texture pattern correct for horizontal)
    barFrame.bar:SetRotatesTexture(isDurationVertical)
    
    -- Background visibility - respects showBackground setting
    if barFrame.bg then
      barFrame.bg:SetShown(barConfig.display.showBackground)
    end
    
    -- Cache the hash
    barFrame._lastAppearanceHash = appearanceHash
  end
  
  -- Always set alpha (cheap operation, might change based on state)
  barFrame.bar:SetAlpha(1)
  
  -- Hide legacy colorCurveBg if it exists (no longer used)
  if barFrame.colorCurveBg then
    barFrame.colorCurveBg:Hide()
  end
  
  if PM then PM("BarValueHandling") end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- BAR VALUE AND COLOR HANDLING
  -- ═══════════════════════════════════════════════════════════════════
  if showPreview then
    -- Preview mode - manual value, clear OnUpdate
    barFrame.bar.colorCurveData = nil
    barFrame.bar:SetScript("OnUpdate", nil)
    UnregisterAuraPolling(barNumber)
    
    barFrame.bar:SetMinMaxValues(0, maxValue)
    local pct = previewStacks or 0.5
    local previewValue = maxValue * pct
    barFrame.bar:SetValue(previewValue)
    
    -- Apply bar color (inline - avoids closure creation overhead)
    if useColorCurve and pct then
      local colorOK, r, g, b, a = pcall(colorCurve.EvaluateUnpacked, colorCurve, pct)
      if colorOK and r then
        barFrame.bar:SetStatusBarColor(r, g, b, a)
      else
        barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
      end
    else
      barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
    end
    
    ApplyBarGradient(barFrame.bar, barConfig)
    barFrame.bar:Show()
    
  elseif active and sourceBar and sourceBar.GetTotemInfo then
    -- TOTEM DURATION BAR
    -- WoW 12.0: Use fast polling with SetValue (AllowedWhenTainted - accepts secrets)
    local totemSlot = sourceBar:GetTotemInfo()
    
    if totemSlot then
      -- Restore bar alpha (may have been hidden during previous expiry)
      barFrame.bar:SetAlpha(1)
      local barTextureTotem = barFrame.bar:GetStatusBarTexture()
      if barTextureTotem then barTextureTotem:SetAlpha(1) end
      
      -- WoW 12.0: Get min/max from sourceBar - duration is SECRET but SetMinMaxValues accepts secrets!
      local minVal, maxVal = sourceBar:GetMinMaxValues()
      barFrame.bar:SetMinMaxValues(minVal, maxVal)
      
      -- Get duration display settings
      local showDuration = barConfig.display.showDuration
      local decimals = barConfig.display.durationDecimals or 1
      local dc = barConfig.display.durationColor or {r=1, g=1, b=1, a=1}
      
      -- Store data for OnUpdate handler
      barFrame.bar.totemPollingData = {
        sourceBar = sourceBar,
        durationFrame = durationFrame,
        showDuration = showDuration,
        decimals = decimals,
        baseColor = baseColor,
        elapsed = 0,
      }
      
      -- Fast polling OnUpdate
      local barTexture = barFrame.bar:GetStatusBarTexture()
      barFrame.bar:SetScript("OnUpdate", function(self, elapsed)
        local data = self.totemPollingData
        if not data then return end
        
        -- Check totem every frame for instant response
        local currentSlot = data.sourceBar:GetTotemInfo()
        if not currentSlot then
          -- Totem is gone - hide bar immediately and stop
          self:SetAlpha(0)  -- Hide entire StatusBar
          if data.durationFrame and data.showDuration then
            data.durationFrame.text:SetText("")
          end
          self:SetScript("OnUpdate", nil)
          self.totemPollingData = nil
          return
        end
        
        -- Throttle value updates only
        data.elapsed = data.elapsed + elapsed
        if data.elapsed < 0.02 then return end
        data.elapsed = 0
        
        -- Get time left (may be secret - that's fine!)
        local timeLeft = data.sourceBar:GetValue()
        
        -- SetValue accepts secrets (AllowedWhenTainted)
        self:SetValue(timeLeft)
        
        -- Update duration text (SetText accepts secrets)
        if data.durationFrame and data.showDuration then
          data.durationFrame.text:SetText(FormatDuration(timeLeft, data.decimals))
        end
      end)
      
      -- Initial value
      local initialValue = sourceBar:GetValue()
      barFrame.bar:SetValue(initialValue)
      
      -- Initial duration text
      if durationFrame and showDuration then
        durationFrame.text:SetText(FormatDuration(initialValue, decimals))
        durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
        durationFrame:Show()
      end
      
      barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
    else
      -- No valid totem slot - clear OnUpdate
      barFrame.bar.totemPollingData = nil
      barFrame.bar:SetScript("OnUpdate", nil)
      UnregisterAuraPolling(barNumber)
      barFrame.bar:SetMinMaxValues(0, maxValue)
      barFrame.bar:SetValue(0)
      barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
      if durationFrame then
        durationFrame:Hide()
      end
    end
    
    ApplyBarGradient(barFrame.bar, barConfig)
    barFrame.bar:Show()
    
  elseif active and sourceBar and sourceBar.GetAuraInfo then
    -- AURA DURATION BAR
    local auraID, unit = sourceBar:GetAuraInfo()
    
    if auraID and unit then
      -- Restore bar alpha and fill texture (may have been hidden during previous aura expiry)
      barFrame.bar:SetAlpha(1)
      local barTexture = barFrame.bar:GetStatusBarTexture()
      if barTexture then barTexture:SetAlpha(1) end
      
      -- Determine timer direction based on fillMode setting
      local fillMode = barConfig.display.durationBarFillMode or "drain"
      local timerDirection = (fillMode == "fill") 
        and Enum.StatusBarTimerDirection.ElapsedTime 
        or Enum.StatusBarTimerDirection.RemainingTime
      
      -- Check if user wants dynamic max (Auto) or manual max
      local useDynamicMax = barConfig.tracking.dynamicMaxDuration
      
      if useDynamicMax then
        -- AUTO MODE: Use SetTimerDuration for auto-animation (normalized 0-1)
        local timerOK = pcall(function()
          local durObj = C_UnitAuras.GetAuraDuration(unit, auraID)
          if durObj then
            barFrame.bar:SetMinMaxValues(0, 1)
            barFrame.bar:SetTimerDuration(durObj, Enum.StatusBarInterpolation.ExponentialEaseOut, timerDirection)
          end
        end)
        
        if not timerOK then
          barFrame.bar:SetMinMaxValues(0, maxValue)
          barFrame.bar:SetValue(sourceBar:GetValue())
        end
        
        -- Apply color (with curve if enabled)
        if useColorCurve then
          -- Store data for OnUpdate handler
          barFrame.bar.colorCurveData = {
            unit = unit,
            auraID = auraID,
            colorCurve = colorCurve,
            baseColor = baseColor,
            elapsed = 0,
          }
          
          -- Get StatusBar texture reference for secret-safe color application
          local barTexture = barFrame.bar:GetStatusBarTexture()
          
          -- Set up OnUpdate handler for continuous color updates (throttled)
          barFrame.bar:SetScript("OnUpdate", function(self, elapsed)
            local data = self.colorCurveData
            if not data then return end
            
            -- Check if aura still exists EVERY FRAME (no throttle for responsiveness)
            local durObj = nil
            pcall(function()
              durObj = C_UnitAuras.GetAuraDuration(data.unit, data.auraID)
            end)
            
            -- If durObj is nil (aura gone), hide bar immediately and stop
            if not durObj then
              self:SetAlpha(0)  -- Hide entire StatusBar (texture alpha gets overridden by animation)
              self:SetScript("OnUpdate", nil)
              self.colorCurveData = nil
              return
            end
            
            -- Throttle color updates only (not aura checks)
            data.elapsed = data.elapsed + elapsed
            if data.elapsed < 0.05 then return end  -- 20fps for color updates
            data.elapsed = 0
            
            -- Aura exists - evaluate color from curve
            local colorApplied = false
            pcall(function()
              local colorResult = durObj:EvaluateRemainingPercent(data.colorCurve)
              if colorResult then
                barTexture:SetVertexColor(colorResult:GetRGBA())
                colorApplied = true
              end
            end)
            
            -- Fallback to baseColor if curve evaluation failed
            if not colorApplied then
              barTexture:SetVertexColor(data.baseColor.r, data.baseColor.g, data.baseColor.b, data.baseColor.a or 1)
            end
          end)
          
          -- Register for event-driven cleanup when aura expires
          RegisterAuraPolling(barNumber, unit, auraID, barFrame, nil, nil)
          
          -- Apply initial color
          local colorOK = pcall(function()
            local durObj = C_UnitAuras.GetAuraDuration(unit, auraID)
            if durObj then
              local colorResult = durObj:EvaluateRemainingPercent(colorCurve)
              if colorResult then
                barTexture:SetVertexColor(colorResult:GetRGBA())
              end
            end
          end)
          if not colorOK then
            barTexture:SetVertexColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
          end
        else
          -- No color curve - but still need OnUpdate to detect aura expiry
          -- SetTimerDuration animates automatically but doesn't know when aura is gone
          
          -- Store data for aura monitoring
          barFrame.bar.auraMonitorData = {
            unit = unit,
            auraID = auraID,
            baseColor = baseColor,
            elapsed = 0,
          }
          
          -- Get bar texture reference for color
          local barTexture = barFrame.bar:GetStatusBarTexture()
          
          -- Monitor for aura expiry to prevent white bar flash
          barFrame.bar:SetScript("OnUpdate", function(self, elapsed)
            local data = self.auraMonitorData
            if not data then return end
            
            -- Check if aura still exists EVERY FRAME (no throttle)
            local durObj = nil
            pcall(function()
              durObj = C_UnitAuras.GetAuraDuration(data.unit, data.auraID)
            end)
            
            -- If aura is gone, hide bar immediately and stop
            if not durObj then
              self:SetAlpha(0)  -- Hide entire StatusBar
              self:SetScript("OnUpdate", nil)
              self.auraMonitorData = nil
            end
          end)
          
          -- Apply base color
          barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
          
          -- Register for event-driven cleanup
          RegisterAuraPolling(barNumber, unit, auraID, barFrame, nil, nil)
        end
      else
        -- MANUAL MAX MODE: Poll remaining duration, StatusBar auto-clamps to maxValue
        -- e.g., max=4, remaining=8.9 → shows full; remaining=2.3 → shows 2.3
        barFrame.bar:SetMinMaxValues(0, maxValue)
        
        -- Store data for OnUpdate
        barFrame.bar.manualMaxData = {
          unit = unit,
          auraID = auraID,
          baseColor = baseColor,
          elapsed = 0,
        }
        
        -- OnUpdate polls GetRemainingDuration (secret) → SetValue (accepts secrets, auto-clamps)
        local barTexture = barFrame.bar:GetStatusBarTexture()
        barFrame.bar:SetScript("OnUpdate", function(self, elapsed)
          local data = self.manualMaxData
          if not data then return end
          
          -- Check if aura still exists EVERY FRAME (no throttle for responsiveness)
          local durObj = nil
          pcall(function()
            durObj = C_UnitAuras.GetAuraDuration(data.unit, data.auraID)
          end)
          
          -- If durObj is nil (aura gone), hide bar immediately and stop
          if not durObj then
            self:SetAlpha(0)  -- Hide entire StatusBar
            self:SetScript("OnUpdate", nil)
            self.manualMaxData = nil
            return
          end
          
          -- Throttle value updates only
          data.elapsed = data.elapsed + elapsed
          if data.elapsed < 0.05 then return end  -- 20 updates/sec
          data.elapsed = 0
          
          -- Aura exists - update value
          pcall(function()
            local remaining = durObj:GetRemainingDuration()  -- Secret value
            self:SetValue(remaining)  -- Auto-clamps to maxValue
          end)
        end)
        
        -- Register for event-driven cleanup when aura expires
        RegisterAuraPolling(barNumber, unit, auraID, barFrame, nil, nil)
        
        -- Apply initial value
        pcall(function()
          local durObj = C_UnitAuras.GetAuraDuration(unit, auraID)
          if durObj then
            barFrame.bar:SetValue(durObj:GetRemainingDuration())
          end
        end)
        
        barFrame.bar.colorCurveData = nil
        barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
      end
    else
      -- No valid aura - clear OnUpdate
      barFrame.bar.colorCurveData = nil
      barFrame.bar:SetScript("OnUpdate", nil)
      UnregisterAuraPolling(barNumber)
      barFrame.bar:SetMinMaxValues(0, maxValue)
      barFrame.bar:SetValue(sourceBar:GetValue())
      barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
    end
    
    ApplyBarGradient(barFrame.bar, barConfig)
    barFrame.bar:Show()
    
  elseif active and sourceBar and sourceBar.GetValue then
    -- Generic fallback (no GetAuraInfo) - clear OnUpdate
    barFrame.bar.colorCurveData = nil
    barFrame.bar:SetScript("OnUpdate", nil)
    UnregisterAuraPolling(barNumber)
    
    local useDynamicMax = barConfig.tracking.dynamicMaxDuration and sourceBar.GetMinMaxValues
    
    if useDynamicMax then
      local _, dynamicMax = sourceBar:GetMinMaxValues()
      barFrame.bar:SetMinMaxValues(0, dynamicMax or maxValue)
    else
      barFrame.bar:SetMinMaxValues(0, maxValue)
    end
    
    barFrame.bar:SetValue(sourceBar:GetValue())
    barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
    ApplyBarGradient(barFrame.bar, barConfig)
    barFrame.bar:Show()
    
  elseif active and not sourceBar and IsNumericAndPositive(stacks) then
    -- Preview mode from ApplyPreviewValue - clear OnUpdate
    barFrame.bar.colorCurveData = nil
    barFrame.bar:SetScript("OnUpdate", nil)
    UnregisterAuraPolling(barNumber)
    
    barFrame.bar:SetMinMaxValues(0, maxValue)
    local effectiveMax = (maxStacks and maxStacks > 0) and maxStacks or 10
    local pct = stacks / effectiveMax
    local previewValue = maxValue * pct
    barFrame.bar:SetValue(previewValue)
    
    -- Apply bar color (inline - avoids closure creation overhead)
    if useColorCurve and pct then
      local colorOK, r, g, b, a = pcall(colorCurve.EvaluateUnpacked, colorCurve, pct)
      if colorOK and r then
        barFrame.bar:SetStatusBarColor(r, g, b, a)
      else
        barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
      end
    else
      barFrame.bar:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
    end
    
    ApplyBarGradient(barFrame.bar, barConfig)
    barFrame.bar:Show()
    
  else
    -- Not active - clear OnUpdate and show dimmed empty bar
    barFrame.bar.colorCurveData = nil
    barFrame.bar:SetScript("OnUpdate", nil)
    UnregisterAuraPolling(barNumber)
    
    barFrame.bar:SetMinMaxValues(0, maxValue)
    barFrame.bar:SetValue(0)
    barFrame.bar:SetStatusBarColor(baseColor.r * 0.5, baseColor.g * 0.5, baseColor.b * 0.5, baseColor.a or 0.8)
    ApplyBarGradient(barFrame.bar, barConfig)
    barFrame.bar:Show()
  end
  
  -- Update stacks text (use secret value passthrough)
  if barConfig.display.showText then
    if showPreview then
      -- Preview mode - show sample stacks value
      local previewStackCount = math.max(1, math.floor((maxStacks or 3) * (previewStacks or 0.5)))
      textFrame.text:SetText(previewStackCount)
    elseif active and not sourceBar and IsNumericAndPositive(stacks) then
      -- Preview from ApplyPreviewValue - use passed stacks value
      textFrame.text:SetText(stacks)
    elseif active and stacksFontString and stacksFontString.GetText then
      -- Pass secret stacks value directly
      textFrame.text:SetText(stacksFontString:GetText())
    elseif active and stacks then
      textFrame.text:SetText(stacks)
    else
      -- Not active - show empty for duration bars
      textFrame.text:SetText("")
    end
    local tc = barConfig.display.textColor
    textFrame.text:SetTextColor(tc.r, tc.g, tc.b, tc.a)
  end
  
  -- Duration text - use C_UnitAuras.GetAuraDurationRemaining for secret-safe text
  if barConfig.display.showDuration and durationFrame then
    local decimals = barConfig.display.durationDecimals or 1
    local dc = barConfig.display.durationColor or {r=1, g=1, b=1, a=1}
    
    -- Store decimals on frame for OnUpdate access
    durationFrame.storedDecimals = decimals
    
    if showPreview then
      -- Preview mode - show sample duration value
      local pct = previewStacks or 0.5
      local previewValue = maxValue * pct
      durationFrame.text:SetText(string.format("%." .. decimals .. "f", previewValue))
      durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
      durationFrame:Show()
    elseif active and not sourceBar and IsNumericAndPositive(stacks) then
      -- Preview from ApplyPreviewValue - calculate duration from stacks percentage
      local effectiveMax = (maxStacks and maxStacks > 0) and maxStacks or 10
      local pct = stacks / effectiveMax
      local previewDurationValue = maxValue * pct
      durationFrame.text:SetText(string.format("%." .. decimals .. "f", previewDurationValue))
      durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
      durationFrame:Show()
    elseif active and sourceBar and sourceBar.GetTotemInfo then
      -- TOTEM/PET: Duration text is handled by totem bar's OnUpdate polling
      -- Skip here to avoid conflicts - durationFrame is already set up above
      -- (do nothing - totem polling handles duration text updates)
    elseif active and sourceBar and sourceBar.GetAuraInfo then
      -- Use DurationObject for auto-updating countdown text
      -- Pattern: Get fresh auraID from sourceBar each frame to detect refreshes
      local auraID, unit = sourceBar:GetAuraInfo()
      if auraID and unit then
        -- Store current aura info for OnUpdate
        durationFrame.sourceBar = sourceBar
        durationFrame.isActive = true
        
        -- Set up OnUpdate to poll GetRemainingDuration() with fresh DurationObject
        if not durationFrame.durationOnUpdate then
          durationFrame.durationOnUpdate = function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < 0.03 then return end  -- ~30fps
            self.elapsed = 0
            
            if not self.isActive or not self.sourceBar then return end
            
            -- Get current auraID from sourceBar (may have changed due to refresh)
            local currentAuraID, currentUnit = self.sourceBar:GetAuraInfo()
            if not currentAuraID or not currentUnit then
              self.text:SetText("")
              return
            end
            
            -- Get fresh DurationObject (handles aura refresh automatically)
            local ok, durObj = pcall(C_UnitAuras.GetAuraDuration, currentUnit, currentAuraID)
            if ok and durObj then
              local okRemaining, remaining = pcall(durObj.GetRemainingDuration, durObj)
              if okRemaining then
                self.text:SetText(FormatDuration(remaining, self.storedDecimals))
              else
                self.text:SetText("")
              end
            else
              self.text:SetText("")
            end
          end
        end
        durationFrame:SetScript("OnUpdate", durationFrame.durationOnUpdate)
        
        -- Initial text set
        local ok, durObj = pcall(C_UnitAuras.GetAuraDuration, unit, auraID)
        if ok and durObj then
          local okRemaining, remaining = pcall(durObj.GetRemainingDuration, durObj)
          if okRemaining then
            durationFrame.text:SetText(FormatDuration(remaining, decimals))
          end
        end
      else
        durationFrame.text:SetText(FormatDuration(sourceBar:GetValue(), decimals))
        durationFrame:SetScript("OnUpdate", nil)
        durationFrame.isActive = false
        durationFrame.sourceBar = nil
      end
      durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
      durationFrame:Show()
    elseif active and sourceBar and sourceBar.GetValue then
      -- Fallback: pass raw value through (secret-safe via SetText)
      -- Clear OnUpdate since we don't have aura info
      durationFrame:SetScript("OnUpdate", nil)
      durationFrame.isActive = false
      durationFrame.sourceBar = nil
      durationFrame.text:SetText(FormatDuration(sourceBar:GetValue(), decimals))
      durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
      durationFrame:Show()
    else
      -- Not active (cooldown ready / all charges available)
      -- Clear OnUpdate
      durationFrame:SetScript("OnUpdate", nil)
      durationFrame.isActive = false
      durationFrame.sourceBar = nil
      -- Check if we should show "0" or hide
      if optionsOpen or barConfig.display.durationShowWhenReady then
        -- Show "0" for editing or if user wants to see ready state
        durationFrame.text:SetText(string.format("%." .. decimals .. "f", 0))
        durationFrame.text:SetTextColor(dc.r, dc.g, dc.b, dc.a)
        durationFrame:Show()
      else
        -- Default: hide when ready
        durationFrame:Hide()
      end
    end
  elseif durationFrame then
    -- Clear OnUpdate when duration display is disabled
    durationFrame:SetScript("OnUpdate", nil)
    durationFrame.isActive = false
    durationFrame.sourceBar = nil
    durationFrame:Hide()
  end
  
  -- Name text - show buff name for duration bars
  if barConfig.display.showName and nameFrame then
    local buffName = barConfig.tracking.buffName or barConfig.tracking.spellName or ""
    -- Fallback: get name from spellID if we have it
    if buffName == "" and barConfig.tracking.spellID then
      buffName = C_Spell.GetSpellName(barConfig.tracking.spellID) or ""
    end
    nameFrame.text:SetText(buffName)
    local nc = barConfig.display.nameColor or {r=1, g=1, b=1, a=1}
    nameFrame.text:SetTextColor(nc.r, nc.g, nc.b, nc.a)
    nameFrame:Show()
  elseif nameFrame then
    nameFrame:Hide()
  end
  
  -- Bar icon - show tracking icon alongside bar
  if barConfig.display.showBarIcon and barIconFrame then
    -- Set icon texture
    if iconTexture then
      barIconFrame.icon:SetTexture(iconTexture)
    elseif barConfig.tracking.iconTextureID then
      barIconFrame.icon:SetTexture(barConfig.tracking.iconTextureID)
    elseif barConfig.tracking.spellID then
      local texture = C_Spell.GetSpellTexture(barConfig.tracking.spellID)
      if texture then
        barIconFrame.icon:SetTexture(texture)
      end
    end
    
    -- Border
    if barConfig.display.barIconShowBorder then
      local bc = barConfig.display.barIconBorderColor or {r=0, g=0, b=0, a=1}
      barIconFrame.background:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
      barIconFrame.background:Show()
    else
      barIconFrame.background:Hide()
    end
    
    barIconFrame:Show()
  elseif barIconFrame then
    barIconFrame:Hide()
  end
  
  -- Update tick marks for duration bar (uses maxDuration as maxValue)
  -- Pass "duration" mode so tick marks know to handle seconds appropriately
  local maxDuration = barConfig.tracking.maxDuration or 30
  UpdateTickMarks(barFrame, barConfig, maxDuration, "duration")
  
  -- Visibility already determined at function start - just show/hide based on that
  if shouldShow and barConfig.display.enabled then
    barFrame:Show()
    barFrame:SetAlpha(1)  -- Always full opacity for duration bars
    if barConfig.display.showText then
      textFrame:Show()
    else
      textFrame:Hide()
    end
    -- Note: durationFrame visibility is already handled earlier in the function
    -- based on whether the cooldown is active and durationShowWhenReady setting
    if barConfig.display.showName and nameFrame then
      nameFrame:Show()
    end
    if barConfig.display.showBarIcon and barIconFrame then
      barIconFrame:Show()
    end
  else
    barFrame:Hide()
    textFrame:Hide()
    if durationFrame then durationFrame:Hide() end
    if nameFrame then nameFrame:Hide() end
    if barIconFrame then barIconFrame:Hide() end
  end
end

-- ===================================================================
-- APPLY APPEARANCE TO SPECIFIC BAR
-- ===================================================================
function ns.Display.ApplyAppearance(barNumber)
  barNumber = barNumber or ns.API.GetSelectedBar()
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig then return end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- INITIALIZATION CHECK: Skip appearance until init complete (prevents flash on reload)
  -- ═══════════════════════════════════════════════════════════════════
  if not initializationComplete and not IsOptionsOpen() then
    return
  end
  
  -- If bar is not enabled, hide all frames and return
  -- CRITICAL: Do NOT call GetBarFrames for disabled bars - it would create ghost frames!
  if not barConfig.tracking or not barConfig.tracking.enabled then
    -- Only try to hide if frames already exist
    if barFrames[barNumber] then
      ns.Display.HideBar(barNumber)
    end
    return
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- SPEC CHECK: Hide and return early if current spec doesn't match
  -- CRITICAL: Must check BEFORE GetBarFrames to avoid creating ghost frames
  -- ═══════════════════════════════════════════════════════════════════
  local currentSpec = GetSpecialization() or 0
  local showOnSpecs = barConfig.behavior and barConfig.behavior.showOnSpecs
  local specAllowed = true
  
  if showOnSpecs and #showOnSpecs > 0 then
    -- Multi-spec check: is current spec in the list?
    specAllowed = false
    for _, spec in ipairs(showOnSpecs) do
      if spec == currentSpec then
        specAllowed = true
        break
      end
    end
  elseif barConfig.behavior and barConfig.behavior.showOnSpec and barConfig.behavior.showOnSpec > 0 then
    -- Legacy single spec check
    specAllowed = (currentSpec == barConfig.behavior.showOnSpec)
  end
  
  if not specAllowed then
    -- Only hide if frames already exist - don't create them just to hide
    if barFrames[barNumber] then
      ns.Display.HideBar(barNumber)
    end
    return
  end
  
  local barFrame, textFrame, durationFrame, iconFrame, nameFrame, barIconFrame = GetBarFrames(barNumber)
  local cfg = barConfig.display
  local displayType = cfg.displayType or "bar"
  
  -- ═══════════════════════════════════════════════════════════════════
  -- ICON MODE APPEARANCE
  -- ═══════════════════════════════════════════════════════════════════
  if displayType == "icon" then
    -- Hide bar elements
    barFrame:Hide()
    textFrame:Hide()
    durationFrame:Hide()
    if nameFrame then nameFrame:Hide() end
    if barIconFrame then barIconFrame:Hide() end
    
    -- Size
    local iconSize = cfg.iconSize or 48
    iconFrame:SetSize(iconSize, iconSize)
    
    -- Position
    if cfg.iconPosition then
      iconFrame:ClearAllPoints()
      iconFrame:SetPoint(
        cfg.iconPosition.point,
        UIParent,
        cfg.iconPosition.relPoint,
        cfg.iconPosition.x,
        cfg.iconPosition.y
      )
    end
    
    -- Frame strata and level for icon mode
    local iconStrata = cfg.barFrameStrata or "MEDIUM"
    local iconLevel = cfg.barFrameLevel or 10
    iconFrame:SetFrameStrata(iconStrata)
    iconFrame:SetFrameLevel(iconLevel)
    
    -- Set icon texture from tracking config
    if barConfig.tracking.iconTextureID then
      iconFrame.icon:SetTexture(barConfig.tracking.iconTextureID)
    elseif barConfig.tracking.spellID then
      -- Fallback: get texture from spellID
      local texture = C_Spell.GetSpellTexture(barConfig.tracking.spellID)
      if texture then
        iconFrame.icon:SetTexture(texture)
      end
    end
    
    -- Apply icon zoom (for custom tracking icons)
    local zoom = cfg.iconZoom or 0
    local minCoord = 0.08 + (zoom * 0.42)
    local maxCoord = 0.92 - (zoom * 0.42)
    iconFrame.icon:SetTexCoord(minCoord, maxCoord, minCoord, maxCoord)
    
    -- Show/hide icon texture based on iconShowTexture
    -- SAFETY: Also verify bar is enabled (prevents ghost icons from deleted bars)
    if cfg.iconShowTexture == false or not barConfig.tracking.enabled then
      iconFrame.icon:Hide()
      iconFrame.background:Hide()
    else
      iconFrame.icon:Show()
    end
    
    -- Stacks font - apply to both regular stacks and free stacks frame
    local stackFontSize = cfg.iconStackFontSize or 16
    local stackFont = "Fonts\\FRIZQT__.TTF"
    if LSM and cfg.iconStackFont then
      local fetchedFont = LSM:Fetch("font", cfg.iconStackFont)
      if fetchedFont and fetchedFont ~= "" then
        stackFont = fetchedFont
      end
    end
    local stackOutline = GetOutlineFlag(cfg.iconStackOutline)
    
    -- Apply fonts with pcall protection
    pcall(function()
      iconFrame.stacks:SetFont(stackFont, stackFontSize, stackOutline)
    end)
    pcall(function()
      iconFrame.stacksFrame.text:SetFont(stackFont, stackFontSize, stackOutline)
    end)
    ApplyTextShadow(iconFrame.stacks, cfg.iconStackShadow)
    ApplyTextShadow(iconFrame.stacksFrame.text, cfg.iconStackShadow)
    
    -- Stacks anchor position
    local stackAnchor = cfg.iconStackAnchor or "TOPRIGHT"
    iconFrame.stacks:ClearAllPoints()
    
    if stackAnchor == "FREE" then
      -- FREE mode - use separate movable frame
      iconFrame.stacks:Hide()
      
      -- Position free stacks frame
      iconFrame.stacksFrame:ClearAllPoints()
      if cfg.iconStackPosition then
        iconFrame.stacksFrame:SetPoint(
          cfg.iconStackPosition.point,
          UIParent,
          cfg.iconStackPosition.relPoint,
          cfg.iconStackPosition.x,
          cfg.iconStackPosition.y
        )
      else
        -- Default position: CENTER of icon
        iconFrame.stacksFrame:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
      end
      
      -- Apply strata and level to stacks frame (use icon strata as default)
      local stackStrata = cfg.iconStackStrata or iconStrata
      local stackLevel = cfg.iconStackLevel or (iconLevel + 20)
      iconFrame.stacksFrame:SetFrameStrata(stackStrata)
      iconFrame.stacksFrame:SetFrameLevel(stackLevel)
      
      -- Show stacks frame if stacks enabled
      if cfg.iconShowStacks then
        iconFrame.stacksFrame:Show()
      else
        iconFrame.stacksFrame:Hide()
      end
    else
      -- Anchored modes - use regular stacks text
      iconFrame.stacksFrame:Hide()
      
      if stackAnchor == "TOPRIGHT" then
        iconFrame.stacks:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", -2, -2)
      elseif stackAnchor == "TOPLEFT" then
        iconFrame.stacks:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
      elseif stackAnchor == "BOTTOMRIGHT" then
        iconFrame.stacks:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
      elseif stackAnchor == "BOTTOMLEFT" then
        iconFrame.stacks:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 2, 2)
      elseif stackAnchor == "TOPRIGHT_OUTER" then
        iconFrame.stacks:SetPoint("BOTTOMLEFT", iconFrame, "TOPRIGHT", 2, 2)
      elseif stackAnchor == "TOPLEFT_OUTER" then
        iconFrame.stacks:SetPoint("BOTTOMRIGHT", iconFrame, "TOPLEFT", -2, 2)
      elseif stackAnchor == "BOTTOMRIGHT_OUTER" then
        iconFrame.stacks:SetPoint("TOPLEFT", iconFrame, "BOTTOMRIGHT", 2, -2)
      elseif stackAnchor == "BOTTOMLEFT_OUTER" then
        iconFrame.stacks:SetPoint("TOPRIGHT", iconFrame, "BOTTOMLEFT", -2, -2)
      elseif stackAnchor == "CENTER" then
        iconFrame.stacks:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
      end
      
      if cfg.iconShowStacks then
        iconFrame.stacks:Show()
      else
        iconFrame.stacks:Hide()
      end
    end
    
    -- Duration font
    local durationFontSize = cfg.iconDurationFontSize or 14
    local durationOutline = GetOutlineFlag(cfg.iconDurationOutline)
    local durationFont = "Fonts\\FRIZQT__.TTF"
    if LSM and cfg.iconDurationFont then
      local fetchedFont = LSM:Fetch("font", cfg.iconDurationFont)
      if fetchedFont and fetchedFont ~= "" then
        durationFont = fetchedFont
      end
    end
    
    -- Apply font with pcall protection
    pcall(function()
      iconFrame.duration:SetFont(durationFont, durationFontSize, durationOutline)
    end)
    ApplyTextShadow(iconFrame.duration, cfg.iconDurationShadow)
    
    -- Border
    if cfg.iconShowBorder then
      local bc = cfg.iconBorderColor or {r=0, g=0, b=0, a=1}
      iconFrame.background:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
      iconFrame.background:Show()
    else
      iconFrame.background:Hide()
    end
    
    -- Movability
    iconFrame:EnableMouse(true)
    
    -- Smart delete button positioning
    -- Attach to the most prominent visible element
    if iconFrame.deleteButton then
      iconFrame.deleteButton:ClearAllPoints()
      
      local iconHidden = (cfg.iconShowTexture == false)
      local stacksInFreeMode = (cfg.iconStackAnchor == "FREE")
      local stackFontSize = cfg.iconStackFontSize or 16
      local iconSize = cfg.iconSize or 48
      
      if iconHidden and stacksInFreeMode and cfg.iconShowStacks then
        -- Icon hidden, stacks in free mode - attach x to stacks frame
        iconFrame.deleteButton:SetPoint("TOPRIGHT", iconFrame.stacksFrame, "TOPRIGHT", 6, 6)
      elseif stacksInFreeMode and cfg.iconShowStacks and stackFontSize > iconSize then
        -- Stacks font larger than icon - attach to stacks frame
        iconFrame.deleteButton:SetPoint("TOPRIGHT", iconFrame.stacksFrame, "TOPRIGHT", 6, 6)
      else
        -- Default: attach to icon frame
        iconFrame.deleteButton:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 0, 0)
      end
    end
    
    -- Show icon frame if enabled
    if cfg.enabled then
      iconFrame:Show()
    end
    
    return  -- Exit early for icon mode
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- BAR MODE APPEARANCE (existing code below)
  -- ═══════════════════════════════════════════════════════════════════
  -- Hide icon frame in bar mode
  if iconFrame then
    iconFrame:Hide()
  end
  
  -- Check if this is a duration bar (uses single fill mode, not stacked)
  local useDurationBar = barConfig.tracking and barConfig.tracking.useDurationBar
  
  -- Check if vertical orientation
  local isVertical = (cfg.barOrientation == "vertical")
  
  -- Apply scale to SIZE instead of using SetScale()
  -- SetScale causes anchor-based drift when scale changes
  -- Multiplying size by scale keeps the bar anchored in place
  local scale = cfg.barScale or 1.0
  local scaledWidth = cfg.width * scale
  local scaledHeight = cfg.height * scale
  
  -- Size - SWAP width and height for vertical bars
  if isVertical then
    barFrame:SetSize(scaledHeight, scaledWidth)  -- Swap dimensions!
  else
    barFrame:SetSize(scaledWidth, scaledHeight)  -- Normal horizontal
  end
  
  -- NOTE: We do NOT use SetScale anymore - it causes position drift
  -- barFrame:SetScale(cfg.barScale) -- REMOVED - scale is now applied to size
  barFrame:SetAlpha(cfg.opacity)
  
  -- Bar padding (always 0 - no UI option exposed)
  barFrame.bar:ClearAllPoints()
  barFrame.bar:SetAllPoints(barFrame)
  
  -- Position
  if cfg.barPosition then
    barFrame:ClearAllPoints()
    barFrame:SetPoint(
      cfg.barPosition.point,
      UIParent,
      cfg.barPosition.relPoint,
      cfg.barPosition.x,
      cfg.barPosition.y
    )
  end
  
  -- Frame strata and level
  local barStrata = cfg.barFrameStrata or "MEDIUM"
  local barLevel = cfg.barFrameLevel or 10
  barFrame:SetFrameStrata(barStrata)
  barFrame:SetFrameLevel(barLevel)
  
  -- Apply strata to the fill bar (StatusBar child) - must also have strata set
  -- Fill bar is 1 level above the parent frame (background texture is on parent at barLevel)
  if barFrame.bar then
    barFrame.bar:SetFrameStrata(barStrata)
    barFrame.bar:SetFrameLevel(barLevel + 1)
  end
  
  -- Apply strata/level to stacked bars (perStack/continuous modes)
  -- Levels: +1 to +20 for stack bars, +21 for maxColorBar
  if barFrame.stackedBars then
    for i, bar in ipairs(barFrame.stackedBars) do
      bar:SetFrameStrata(barStrata)
      bar:SetFrameLevel(barLevel + i)
    end
  end
  -- Apply strata/level to granular bars (perThreshold mode)
  if barFrame.granularBars then
    for i, bar in ipairs(barFrame.granularBars) do
      bar:SetFrameStrata(barStrata)
      bar:SetFrameLevel(barLevel + i)
    end
  end
  if barFrame.maxColorBar then
    barFrame.maxColorBar:SetFrameStrata(barStrata)
    barFrame.maxColorBar:SetFrameLevel(barLevel + 21)
  end
  
  -- Apply strata/level to tick overlay and border (above all fill bars)
  -- Tick overlay at +22, border at +23
  if barFrame.tickOverlay then
    barFrame.tickOverlay:SetFrameStrata(barStrata)
    barFrame.tickOverlay:SetFrameLevel(barLevel + 22)
  end
  if barFrame.barBorderFrame then
    barFrame.barBorderFrame:SetFrameStrata(barStrata)
    barFrame.barBorderFrame:SetFrameLevel(barLevel + 23)
  end
  
  -- Apply strata to text frames - use individual settings if specified, fallback to bar strata
  -- Text frames default to +25 (above tick overlay and border)
  if textFrame then
    local stackStrata = cfg.stackTextStrata or barStrata
    local stackLevel = cfg.stackTextLevel or (barLevel + 25)
    textFrame:SetFrameStrata(stackStrata)
    textFrame:SetFrameLevel(stackLevel)
  end
  if durationFrame then
    local durStrata = cfg.durationTextStrata or barStrata
    local durLevel = cfg.durationTextLevel or (barLevel + 25)
    durationFrame:SetFrameStrata(durStrata)
    durationFrame:SetFrameLevel(durLevel)
  end
  if nameFrame then
    local nameStrata = cfg.nameTextStrata or barStrata
    local nameLevel = cfg.nameTextLevel or (barLevel + 25)
    nameFrame:SetFrameStrata(nameStrata)
    nameFrame:SetFrameLevel(nameLevel)
  end
  
  -- Text font and sizing (MUST happen before anchor positioning)
  local fontPath = "Fonts\\FRIZQT__.TTF"
  if LSM and cfg.font then
    local fetchedFont = LSM:Fetch("font", cfg.font)
    if fetchedFont and fetchedFont ~= "" then
      fontPath = fetchedFont
    end
  end
  
  local fontSize = cfg.fontSize or 14
  local outlineFlag = GetOutlineFlag(cfg.textOutline)
  
  -- Apply font with pcall protection
  pcall(function()
    textFrame.text:SetFont(fontPath, fontSize, outlineFlag)
  end)
  ApplyTextShadow(textFrame.text, cfg.textShadow)
  
  -- Size frame based on fontSize (avoid secret value issues with GetStringWidth)
  local estimatedWidth = fontSize * 3  -- Enough for 2-3 digit numbers
  local estimatedHeight = fontSize + 4
  textFrame:SetSize(estimatedWidth, estimatedHeight)
  
  -- Text positioning - either anchored to bar or free-floating
  local textAnchor = cfg.textAnchor or "OUTERTOP"
  if textAnchor ~= "FREE" then
    -- Anchor text to bar edge points
    textFrame:ClearAllPoints()
    local offsetX = cfg.textAnchorOffsetX or 0
    local offsetY = cfg.textAnchorOffsetY or 0
    local padding = 5  -- Small padding from edge for visual clarity
    
    -- Inner anchors (text inside bar)
    if textAnchor == "CENTER" then
      textFrame:SetPoint("CENTER", barFrame, "CENTER", offsetX, offsetY)
    elseif textAnchor == "RIGHT" or textAnchor == "CENTERRIGHT" then
      textFrame:SetPoint("CENTER", barFrame, "RIGHT", -padding + offsetX, offsetY)
    elseif textAnchor == "LEFT" or textAnchor == "CENTERLEFT" then
      textFrame:SetPoint("CENTER", barFrame, "LEFT", padding + offsetX, offsetY)
    elseif textAnchor == "TOP" then
      textFrame:SetPoint("CENTER", barFrame, "TOP", offsetX, -padding + offsetY)
    elseif textAnchor == "BOTTOM" then
      textFrame:SetPoint("CENTER", barFrame, "BOTTOM", offsetX, padding + offsetY)
    elseif textAnchor == "TOPLEFT" then
      textFrame:SetPoint("CENTER", barFrame, "TOPLEFT", padding + offsetX, -padding + offsetY)
    elseif textAnchor == "TOPRIGHT" then
      textFrame:SetPoint("CENTER", barFrame, "TOPRIGHT", -padding + offsetX, -padding + offsetY)
    elseif textAnchor == "BOTTOMLEFT" then
      textFrame:SetPoint("CENTER", barFrame, "BOTTOMLEFT", padding + offsetX, padding + offsetY)
    elseif textAnchor == "BOTTOMRIGHT" then
      textFrame:SetPoint("CENTER", barFrame, "BOTTOMRIGHT", -padding + offsetX, padding + offsetY)
    -- Outer anchors (text outside bar, touching the border)
    -- Use -20 for right-side outers, +20 for left-side outers to compensate for text centering
    elseif textAnchor == "OUTERRIGHT" or textAnchor == "OUTERCENTERRIGHT" then
      textFrame:SetPoint("LEFT", barFrame, "RIGHT", -20 + offsetX, offsetY)
    elseif textAnchor == "OUTERLEFT" or textAnchor == "OUTERCENTERLEFT" then
      textFrame:SetPoint("RIGHT", barFrame, "LEFT", 20 + offsetX, offsetY)
    elseif textAnchor == "OUTERTOP" then
      textFrame:SetPoint("BOTTOM", barFrame, "TOP", offsetX, offsetY)
    elseif textAnchor == "OUTERBOTTOM" then
      textFrame:SetPoint("TOP", barFrame, "BOTTOM", offsetX, offsetY)
    elseif textAnchor == "OUTERTOPLEFT" then
      textFrame:SetPoint("BOTTOMRIGHT", barFrame, "TOPLEFT", 20 + offsetX, offsetY)
    elseif textAnchor == "OUTERTOPRIGHT" then
      textFrame:SetPoint("BOTTOMLEFT", barFrame, "TOPRIGHT", -20 + offsetX, offsetY)
    elseif textAnchor == "OUTERBOTTOMLEFT" then
      textFrame:SetPoint("TOPRIGHT", barFrame, "BOTTOMLEFT", 20 + offsetX, offsetY)
    elseif textAnchor == "OUTERBOTTOMRIGHT" then
      textFrame:SetPoint("TOPLEFT", barFrame, "BOTTOMRIGHT", -20 + offsetX, offsetY)
    else
      -- Fallback
      textFrame:SetPoint("CENTER", barFrame, "CENTER", offsetX, offsetY)
    end
  elseif cfg.textPosition then
    textFrame:ClearAllPoints()
    textFrame:SetPoint(
      cfg.textPosition.point,
      UIParent,
      cfg.textPosition.relPoint,
      cfg.textPosition.x,
      cfg.textPosition.y
    )
  end
  
  -- Duration text font and sizing
  if durationFrame then
    local durationOutline = GetOutlineFlag(cfg.durationOutline)
    local durationFontSize = cfg.durationFontSize or 18
    local fontPath = "Fonts\\FRIZQT__.TTF"
    
    -- Try to get custom font
    if LSM and cfg.durationFont then
      local fetchedFont = LSM:Fetch("font", cfg.durationFont)
      if fetchedFont and fetchedFont ~= "" then
        fontPath = fetchedFont
      end
    elseif LSM and cfg.font then
      -- Fallback to regular font
      local fetchedFont = LSM:Fetch("font", cfg.font)
      if fetchedFont and fetchedFont ~= "" then
        fontPath = fetchedFont
      end
    end
    
    -- Apply font with pcall protection
    pcall(function()
      durationFrame.text:SetFont(fontPath, durationFontSize, durationOutline)
    end)
    
    ApplyTextShadow(durationFrame.text, cfg.durationShadow)
    
    -- Size duration frame
    durationFrame:SetSize(durationFontSize * 4, durationFontSize + 4)
    
    -- Duration positioning - either anchored to bar or free-floating
    local durationAnchor = cfg.durationAnchor or "CENTER"
    if durationAnchor ~= "FREE" then
      durationFrame:ClearAllPoints()
      local offsetX = cfg.durationAnchorOffsetX or 0
      local offsetY = cfg.durationAnchorOffsetY or 0
      local padding = 5
      
      -- New format (matching textAnchor) + backward compatibility for old format
      if durationAnchor == "CENTER" then
        durationFrame:SetPoint("CENTER", barFrame, "CENTER", offsetX, offsetY)
      elseif durationAnchor == "RIGHT" or durationAnchor == "CENTERRIGHT" or durationAnchor == "RIGHT_INNER" then
        durationFrame:SetPoint("CENTER", barFrame, "RIGHT", -padding + offsetX, offsetY)
      elseif durationAnchor == "LEFT" or durationAnchor == "CENTERLEFT" or durationAnchor == "LEFT_INNER" then
        durationFrame:SetPoint("CENTER", barFrame, "LEFT", padding + offsetX, offsetY)
      elseif durationAnchor == "TOP" or durationAnchor == "TOP_INNER" then
        durationFrame:SetPoint("CENTER", barFrame, "TOP", offsetX, -padding + offsetY)
      elseif durationAnchor == "BOTTOM" or durationAnchor == "BOTTOM_INNER" then
        durationFrame:SetPoint("CENTER", barFrame, "BOTTOM", offsetX, padding + offsetY)
      elseif durationAnchor == "TOPLEFT" then
        durationFrame:SetPoint("BOTTOMRIGHT", barFrame, "TOPLEFT", padding + offsetX, -padding + offsetY)
      elseif durationAnchor == "TOPRIGHT" then
        durationFrame:SetPoint("BOTTOMLEFT", barFrame, "TOPRIGHT", -padding + offsetX, -padding + offsetY)
      elseif durationAnchor == "BOTTOMLEFT" then
        durationFrame:SetPoint("TOPRIGHT", barFrame, "BOTTOMLEFT", padding + offsetX, padding + offsetY)
      elseif durationAnchor == "BOTTOMRIGHT" then
        durationFrame:SetPoint("TOPLEFT", barFrame, "BOTTOMRIGHT", -padding + offsetX, padding + offsetY)
      elseif durationAnchor == "OUTERRIGHT" or durationAnchor == "OUTERCENTERRIGHT" or durationAnchor == "RIGHT_OUTER" then
        durationFrame:SetPoint("LEFT", barFrame, "RIGHT", -20 + offsetX, offsetY)
      elseif durationAnchor == "OUTERLEFT" or durationAnchor == "OUTERCENTERLEFT" or durationAnchor == "LEFT_OUTER" then
        durationFrame:SetPoint("RIGHT", barFrame, "LEFT", 20 + offsetX, offsetY)
      elseif durationAnchor == "OUTERTOP" or durationAnchor == "TOP_OUTER" then
        durationFrame:SetPoint("BOTTOM", barFrame, "TOP", offsetX, offsetY)
      elseif durationAnchor == "OUTERBOTTOM" or durationAnchor == "BOTTOM_OUTER" then
        durationFrame:SetPoint("TOP", barFrame, "BOTTOM", offsetX, offsetY)
      elseif durationAnchor == "OUTERTOPLEFT" then
        durationFrame:SetPoint("BOTTOMRIGHT", barFrame, "TOPLEFT", offsetX, offsetY)
      elseif durationAnchor == "OUTERTOPRIGHT" then
        durationFrame:SetPoint("BOTTOMLEFT", barFrame, "TOPRIGHT", offsetX, offsetY)
      elseif durationAnchor == "OUTERBOTTOMLEFT" then
        durationFrame:SetPoint("TOPRIGHT", barFrame, "BOTTOMLEFT", offsetX, offsetY)
      elseif durationAnchor == "OUTERBOTTOMRIGHT" then
        durationFrame:SetPoint("TOPLEFT", barFrame, "BOTTOMRIGHT", offsetX, offsetY)
      else
        durationFrame:SetPoint("CENTER", barFrame, "CENTER", offsetX, offsetY)
      end
    elseif cfg.durationPosition then
      durationFrame:ClearAllPoints()
      durationFrame:SetPoint(
        cfg.durationPosition.point,
        UIParent,
        cfg.durationPosition.relPoint,
        cfg.durationPosition.x,
        cfg.durationPosition.y
      )
    end
  end
  
  -- Texture
  if LSM then
    local texture = LSM:Fetch("statusbar", cfg.texture)
    if texture then
      barFrame.bar:SetStatusBarTexture(texture)
    end
  end
  
  -- Fill direction and orientation
  barFrame.bar:SetOrientation(isVertical and "VERTICAL" or "HORIZONTAL")
  barFrame.bar:SetReverseFill(cfg.barReverseFill or false)
  -- Rotate texture to match fill direction
  barFrame.bar:SetRotatesTexture(isVertical)
  
  -- Background - ONLY on main frame (barFrame.bg)
  -- barFrame.bar.bg is always hidden since barFrame.bar is hidden in non-simple modes
  barFrame.bar.bg:Hide()
  barFrame.bg:SetShown(cfg.showBackground)
  if cfg.showBackground then
    local bg = cfg.backgroundColor
    local bgTextureName = cfg.backgroundTexture or "Solid"
    
    -- Background fills entire frame like MWRB (SetAllPoints)
    barFrame.bg:ClearAllPoints()
    barFrame.bg:SetAllPoints(barFrame)
    
    -- Reset texture state before applying new one
    barFrame.bg:SetVertexColor(1, 1, 1, 1)  -- Reset vertex color
    barFrame.bg:SetTexCoord(0, 1, 0, 1)     -- Reset tex coords
    
    if bgTextureName == "Solid" then
      barFrame.bg:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
    else
      -- Try to fetch from LSM background type
      local bgTexture = LSM and LSM:Fetch("background", bgTextureName)
      if bgTexture then
        barFrame.bg:SetTexture(bgTexture)
        barFrame.bg:SetVertexColor(bg.r, bg.g, bg.b, bg.a)
      else
        barFrame.bg:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
      end
    end
  end
  
  -- Border - uses 4 manual textures for pixel-perfect borders
  if barFrame.barBorderFrame then
    if cfg.showBorder then
      local bt = cfg.drawnBorderThickness or 2
      local bc = cfg.borderColor or {r = 0, g = 0, b = 0, a = 1}
      
      -- Top border (spans full width at top)
      barFrame.barBorderFrame.top:ClearAllPoints()
      barFrame.barBorderFrame.top:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 0, 0)
      barFrame.barBorderFrame.top:SetPoint("TOPRIGHT", barFrame, "TOPRIGHT", 0, 0)
      barFrame.barBorderFrame.top:SetHeight(bt)
      barFrame.barBorderFrame.top:SetColorTexture(bc.r or 0, bc.g or 0, bc.b or 0, bc.a or 1)
      barFrame.barBorderFrame.top:Show()
      
      -- Bottom border (spans full width at bottom)
      barFrame.barBorderFrame.bottom:ClearAllPoints()
      barFrame.barBorderFrame.bottom:SetPoint("BOTTOMLEFT", barFrame, "BOTTOMLEFT", 0, 0)
      barFrame.barBorderFrame.bottom:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", 0, 0)
      barFrame.barBorderFrame.bottom:SetHeight(bt)
      barFrame.barBorderFrame.bottom:SetColorTexture(bc.r or 0, bc.g or 0, bc.b or 0, bc.a or 1)
      barFrame.barBorderFrame.bottom:Show()
      
      -- Left border (between top and bottom borders)
      barFrame.barBorderFrame.left:ClearAllPoints()
      barFrame.barBorderFrame.left:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 0, -bt)
      barFrame.barBorderFrame.left:SetPoint("BOTTOMLEFT", barFrame, "BOTTOMLEFT", 0, bt)
      barFrame.barBorderFrame.left:SetWidth(bt)
      barFrame.barBorderFrame.left:SetColorTexture(bc.r or 0, bc.g or 0, bc.b or 0, bc.a or 1)
      barFrame.barBorderFrame.left:Show()
      
      -- Right border (between top and bottom borders)
      barFrame.barBorderFrame.right:ClearAllPoints()
      barFrame.barBorderFrame.right:SetPoint("TOPRIGHT", barFrame, "TOPRIGHT", 0, -bt)
      barFrame.barBorderFrame.right:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", 0, bt)
      barFrame.barBorderFrame.right:SetWidth(bt)
      barFrame.barBorderFrame.right:SetColorTexture(bc.r or 0, bc.g or 0, bc.b or 0, bc.a or 1)
      barFrame.barBorderFrame.right:Show()
      
      barFrame.barBorderFrame:Show()
    else
      if barFrame.barBorderFrame.top then barFrame.barBorderFrame.top:Hide() end
      if barFrame.barBorderFrame.bottom then barFrame.barBorderFrame.bottom:Hide() end
      if barFrame.barBorderFrame.left then barFrame.barBorderFrame.left:Hide() end
      if barFrame.barBorderFrame.right then barFrame.barBorderFrame.right:Hide() end
      barFrame.barBorderFrame:Hide()
    end
  end
  
  -- Movability
  barFrame:EnableMouse(cfg.barMovable)
  textFrame:EnableMouse(cfg.textMovable)
  if durationFrame then
    durationFrame:EnableMouse(cfg.durationAnchor == "FREE")
  end
  
  -- Show/hide duration frame based on config
  if durationFrame then
    if cfg.showDuration then
      durationFrame:Show()
    else
      durationFrame:Hide()
    end
  end
  
  -- Name frame appearance (for duration bars)
  if nameFrame then
    -- Font
    local nameFont = "Fonts\\FRIZQT__.TTF"
    if LSM and cfg.nameFont then
      local font = LSM:Fetch("font", cfg.nameFont)
      if font then nameFont = font end
    elseif LSM and cfg.font then
      local font = LSM:Fetch("font", cfg.font)
      if font then nameFont = font end
    end
    local nameOutline = GetOutlineFlag(cfg.nameOutline)
    nameFrame.text:SetFont(nameFont, cfg.nameFontSize or 14, nameOutline)
    ApplyTextShadow(nameFrame.text, cfg.nameShadow)
    
    -- Size based on font
    local nameFontSize = cfg.nameFontSize or 14
    nameFrame:SetSize(nameFontSize * 12, nameFontSize + 4)
    
    -- Position
    local nameAnchor = cfg.nameAnchor or "CENTER"
    if nameAnchor ~= "FREE" then
      nameFrame:ClearAllPoints()
      local offsetX = cfg.nameAnchorOffsetX or 0
      local offsetY = cfg.nameAnchorOffsetY or 0
      local padding = 5
      
      -- New format (matching textAnchor) + backward compatibility for old format
      if nameAnchor == "CENTER" then
        nameFrame:SetPoint("CENTER", barFrame, "CENTER", offsetX, offsetY)
      elseif nameAnchor == "RIGHT" or nameAnchor == "CENTERRIGHT" then
        nameFrame:SetPoint("CENTER", barFrame, "RIGHT", -padding + offsetX, offsetY)
      elseif nameAnchor == "LEFT" or nameAnchor == "CENTERLEFT" then
        nameFrame:SetPoint("CENTER", barFrame, "LEFT", padding + offsetX, offsetY)
      elseif nameAnchor == "TOP" then
        nameFrame:SetPoint("CENTER", barFrame, "TOP", offsetX, -padding + offsetY)
      elseif nameAnchor == "BOTTOM" then
        nameFrame:SetPoint("CENTER", barFrame, "BOTTOM", offsetX, padding + offsetY)
      elseif nameAnchor == "TOPLEFT" then
        nameFrame:SetPoint("BOTTOMRIGHT", barFrame, "TOPLEFT", padding + offsetX, -padding + offsetY)
      elseif nameAnchor == "TOPRIGHT" then
        nameFrame:SetPoint("BOTTOMLEFT", barFrame, "TOPRIGHT", -padding + offsetX, -padding + offsetY)
      elseif nameAnchor == "BOTTOMLEFT" then
        nameFrame:SetPoint("TOPRIGHT", barFrame, "BOTTOMLEFT", padding + offsetX, padding + offsetY)
      elseif nameAnchor == "BOTTOMRIGHT" then
        nameFrame:SetPoint("TOPLEFT", barFrame, "BOTTOMRIGHT", -padding + offsetX, padding + offsetY)
      elseif nameAnchor == "OUTERRIGHT" or nameAnchor == "OUTERCENTERRIGHT" or nameAnchor == "RIGHT_OUTER" then
        nameFrame:SetPoint("LEFT", barFrame, "RIGHT", 2 + offsetX, offsetY)
      elseif nameAnchor == "OUTERLEFT" or nameAnchor == "OUTERCENTERLEFT" or nameAnchor == "LEFT_OUTER" then
        nameFrame:SetPoint("RIGHT", barFrame, "LEFT", -2 + offsetX, offsetY)
      elseif nameAnchor == "OUTERTOP" or nameAnchor == "TOP_OUTER" then
        nameFrame:SetPoint("BOTTOM", barFrame, "TOP", offsetX, 2 + offsetY)
      elseif nameAnchor == "OUTERBOTTOM" or nameAnchor == "BOTTOM_OUTER" then
        nameFrame:SetPoint("TOP", barFrame, "BOTTOM", offsetX, -2 + offsetY)
      elseif nameAnchor == "OUTERTOPLEFT" then
        nameFrame:SetPoint("BOTTOMRIGHT", barFrame, "TOPLEFT", offsetX, offsetY)
      elseif nameAnchor == "OUTERTOPRIGHT" then
        nameFrame:SetPoint("BOTTOMLEFT", barFrame, "TOPRIGHT", offsetX, offsetY)
      elseif nameAnchor == "OUTERBOTTOMLEFT" then
        nameFrame:SetPoint("TOPRIGHT", barFrame, "BOTTOMLEFT", offsetX, offsetY)
      elseif nameAnchor == "OUTERBOTTOMRIGHT" then
        nameFrame:SetPoint("TOPLEFT", barFrame, "BOTTOMRIGHT", offsetX, offsetY)
      else
        nameFrame:SetPoint("CENTER", barFrame, "CENTER", offsetX, offsetY)
      end
    elseif cfg.namePosition then
      nameFrame:ClearAllPoints()
      nameFrame:SetPoint(
        cfg.namePosition.point,
        UIParent,
        cfg.namePosition.relPoint,
        cfg.namePosition.x,
        cfg.namePosition.y
      )
    end
    
    -- Movability
    nameFrame:EnableMouse(nameAnchor == "FREE")
    
    if cfg.showName then
      nameFrame:Show()
    else
      nameFrame:Hide()
    end
  end
  
  -- Bar icon frame appearance (icon alongside bar)
  if barIconFrame then
    -- Size
    local iconSize = cfg.barIconSize or 32
    barIconFrame:SetSize(iconSize, iconSize)
    
    -- Position
    local iconAnchor = cfg.barIconAnchor or "LEFT"
    if iconAnchor ~= "FREE" then
      barIconFrame:ClearAllPoints()
      local offsetX = cfg.iconOffsetX or 0
      local offsetY = cfg.iconOffsetY or 0
      local iconBarSpacing = cfg.iconBarSpacing or 4  -- Use the Bar Gap setting
      
      if iconAnchor == "LEFT" then
        barIconFrame:SetPoint("RIGHT", barFrame, "LEFT", -iconBarSpacing + offsetX, offsetY)
      elseif iconAnchor == "RIGHT" then
        barIconFrame:SetPoint("LEFT", barFrame, "RIGHT", iconBarSpacing + offsetX, offsetY)
      elseif iconAnchor == "TOP" then
        barIconFrame:SetPoint("BOTTOM", barFrame, "TOP", offsetX, iconBarSpacing + offsetY)
      elseif iconAnchor == "BOTTOM" then
        barIconFrame:SetPoint("TOP", barFrame, "BOTTOM", offsetX, -iconBarSpacing + offsetY)
      else
        barIconFrame:SetPoint("RIGHT", barFrame, "LEFT", -iconBarSpacing + offsetX, offsetY)
      end
    elseif cfg.barIconPosition then
      barIconFrame:ClearAllPoints()
      barIconFrame:SetPoint(
        cfg.barIconPosition.point,
        UIParent,
        cfg.barIconPosition.relPoint,
        cfg.barIconPosition.x,
        cfg.barIconPosition.y
      )
    end
    
    -- Border
    if cfg.barIconShowBorder then
      local bc = cfg.barIconBorderColor or {r=0, g=0, b=0, a=1}
      barIconFrame.background:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
      barIconFrame.background:Show()
    else
      barIconFrame.background:Hide()
    end
    
    -- Movability
    barIconFrame:EnableMouse(iconAnchor == "FREE")
    
    if cfg.showBarIcon then
      barIconFrame:Show()
    else
      barIconFrame:Hide()
    end
  end
  
  -- CRITICAL FIX: Check preview mode BEFORE refreshing
  if previewMode then
    -- In preview mode - maintain preview value
    local maxStacks = barConfig.tracking.maxStacks or 10
    local stackCount = math.floor(previewStacks * maxStacks + 0.5)
    ns.Display.UpdateBar(barNumber, stackCount, maxStacks, true)
  else
    -- Not in preview - refresh with real values
    if ns.API.RefreshDisplay then
      ns.API.RefreshDisplay(barNumber)
    end
  end
end

-- ===================================================================
-- APPLY ALL BARS
-- ===================================================================
function ns.Display.ApplyAllBars()
  -- Safety check: ensure DB functions are loaded
  if not ns.API.GetActiveBars then
    return
  end
  
  local activeBars = ns.API.GetActiveBars()
  for _, barNumber in ipairs(activeBars) do
    ns.Display.ApplyAppearance(barNumber)
  end
  
  -- Also refresh visibility for all bars (respects spec settings)
  ns.Display.RefreshAllBars()
end

-- ===================================================================
-- REFRESH ALL BARS (for spec changes, etc.)
-- ===================================================================
function ns.Display.RefreshAllBars()
  local currentSpec = GetSpecialization() or 0
  local db = ns.API.GetDB and ns.API.GetDB()
  
  -- CRITICAL: Don't iterate if no database or no bars table
  if not db or not db.bars then return end
  
  -- Refresh visibility for all bars (including ones that might need hiding)
  for barNumber, barConfig in pairs(db.bars) do
    
    if barConfig and barConfig.tracking and barConfig.tracking.enabled then
      -- Check spec visibility first
      local showOnSpecs = barConfig.behavior and barConfig.behavior.showOnSpecs
      local specAllowed = true
      
      if showOnSpecs and #showOnSpecs > 0 then
        -- Multi-spec check: is current spec in the list?
        specAllowed = false
        for _, spec in ipairs(showOnSpecs) do
          if spec == currentSpec then
            specAllowed = true
            break
          end
        end
      elseif barConfig.behavior and barConfig.behavior.showOnSpec and barConfig.behavior.showOnSpec > 0 then
        -- Legacy single spec check
        specAllowed = (currentSpec == barConfig.behavior.showOnSpec)
      end
      
      if specAllowed then
        -- CRITICAL: Call ApplyAppearance FIRST to set up frames properly
        -- This handles anchors, borders, textures, fonts, etc.
        ns.Display.ApplyAppearance(barNumber)
        
        -- Then use Core.lua's RefreshDisplay to do proper tracking update
        -- This goes through full tracking logic instead of just UpdateBar
        if ns.API and ns.API.RefreshDisplay then
          ns.API.RefreshDisplay(barNumber)
        else
          -- Fallback if RefreshDisplay not available
          ns.Display.UpdateBar(barNumber)
        end
      else
        -- Hide bar - wrong spec (hide ALL frames)
        ns.Display.HideBar(barNumber)
      end
    elseif barFrames[barNumber] then
      -- Hide bars that aren't enabled (hide ALL frames)
      -- Only if frames already exist - don't create them!
      ns.Display.HideBar(barNumber)
    end
  end
end

-- ===================================================================
-- GET BAR FRAME (for external access)
-- ===================================================================
function ns.Display.GetBarFrame(barNumber)
  if barFrames[barNumber] then
    return barFrames[barNumber].barFrame
  end
  return nil
end

-- ===================================================================
-- GET ICON FRAME (for external access)
-- ===================================================================
function ns.Display.GetIconFrame(barNumber)
  if barFrames[barNumber] then
    return barFrames[barNumber].iconFrame
  end
  return nil
end

-- ===================================================================
-- GET APPROPRIATE FRAME (bar or icon based on displayType)
-- ===================================================================
function ns.Display.GetDisplayFrame(barNumber)
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig then return nil end
  
  local displayType = barConfig.display.displayType or "bar"
  if displayType == "icon" then
    return ns.Display.GetIconFrame(barNumber)
  else
    return ns.Display.GetBarFrame(barNumber)
  end
end

-- ===================================================================
-- OPEN OPTIONS AND SELECT BAR (for click-to-edit)
-- Opens the options panel if not already open, then selects the Appearance tab
-- ===================================================================
function ns.Display.OpenOptionsForBar(barType, barNumber)
  local AceConfigDialog = LibStub("AceConfigDialog-3.0")
  
  -- Check if options panel is already open - if not, do nothing
  local panelIsOpen = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["ArcUI"]
  if not panelIsOpen then
    return  -- Don't open panel, just ignore the click
  end
  
  -- Set the selected bar in AppearanceOptions
  if ns.AppearanceOptions and ns.AppearanceOptions.SetSelectedBar then
    ns.AppearanceOptions.SetSelectedBar(barType, barNumber)
  end
  
  -- Refresh the options to show updated selection
  local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
  AceConfigRegistry:NotifyChange("ArcUI")
  
  -- Select the appearance tab (now under bars)
  AceConfigDialog:SelectGroup("ArcUI", "bars", "appearance")
end

-- ===================================================================
-- SET PREVIEW VALUE (for live preview in appearance options)
-- ===================================================================
function ns.Display.SetPreviewValue(barNumber, previewValue)
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig then return end
  
  local barFrame, textFrame = GetBarFrames(barNumber)
  if not barFrame then return end
  
  local maxStacks = barConfig.tracking.maxStacks or 10
  local displayMode = barConfig.display.thresholdMode or "simple"
  
  if displayMode == "granular" then
    -- Granular mode: each bar represents one stack unit, set 1 if filled, 0 if not
    if barFrame.granularBars then
      for i, bar in ipairs(barFrame.granularBars) do
        if bar:IsShown() then
          bar:SetValue(i <= previewValue and 1 or 0)
        end
      end
    end
  elseif displayMode == "perStack" then
    -- Sequence mode: use SetValue with previewValue (min/max already set per segment)
    if barFrame.granularBars then
      for i, bar in ipairs(barFrame.granularBars) do
        if bar:IsShown() then
          bar:SetValue(previewValue)
        end
      end
    end
  elseif displayMode == "folded" then
    -- Folded mode: use stackedBars
    if barFrame.stackedBars then
      for _, bar in ipairs(barFrame.stackedBars) do
        if bar:IsShown() then
          bar:SetValue(previewValue)
        end
      end
    end
    -- Also update main bar in case folded mode uses it
    if barFrame.bar then
      barFrame.bar:SetValue(previewValue)
    end
  else
    -- Simple mode: use main bar
    if barFrame.bar then
      barFrame.bar:SetValue(previewValue)
    end
  end
  
  -- Update text
  if barConfig.display.showText and textFrame and textFrame.text then
    textFrame.text:SetText(previewValue)
  end
  
  -- Make sure bar is visible for preview
  barFrame:Show()
  if barConfig.display.showText then
    textFrame:Show()
  end
end

-- ===================================================================
-- INITIALIZATION
-- ===================================================================
C_Timer.After(2.0, function()
  ns.Display.ApplyAllBars()
end)

-- ===================================================================
-- LIBPLEEBUG FUNCTION WRAPPING
-- Wrap heavy functions for CPU profiling
-- ===================================================================
if P then
  -- Main Update Loop (heaviest)
  ns.Display.UpdateBar = P:Def("UpdateBar", ns.Display.UpdateBar, "Updates")
  ns.Display.UpdateDurationBar = P:Def("UpdateDurationBar", ns.Display.UpdateDurationBar, "Updates")
  
  -- Apply Functions
  ns.Display.ApplyAllBars = P:Def("ApplyAllBars", ns.Display.ApplyAllBars, "Apply")
  ns.Display.ApplyBar = P:Def("ApplyBar", ns.Display.ApplyBar, "Apply")
end

-- ===================================================================
-- END OF ArcUI_Display.lua
-- ===================================================================