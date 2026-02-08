-- ===================================================================
-- ArcUI_AppearanceOptions.lua
-- Unified Appearance panel for ALL bar types
-- v2.8.1: Added charge text settings for cooldown duration bars
--   - showMaxText, chargeTextAnchor, offsets now available for duration bars
-- v2.8.0: Added ColorCurve threshold support for duration bars
-- Layout matches MWRB style
-- ===================================================================

local ADDON, ns = ...
ns.AppearanceOptions = ns.AppearanceOptions or {}
ns.selectedPerStack = ns.selectedPerStack or 1  -- For per-stack color editing

-- Collapsible section state (persists during session)
-- true = collapsed/closed, false = expanded/open
-- Default all to true (collapsed) for cleaner initial view
local collapsedSections = {
  iconDisplay = true,
  iconDuration = true,
  barSize = true,
  fill = true,
  colorOptions = true,
  background = true,
  border = true,
  frameStrata = true,
  tickMarks = true,
  stackText = true,
  durationText = true,
  readyText = true,
  nameText = true,
  barIcon = true,
  position = true,
  behavior = true,
}

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- Custom widget ArcUI_EditBox is registered in Core.lua

-- ===================================================================
-- HELPERS
-- ===================================================================
local function GetStatusBarTextures()
  local textures = {["Blizzard"] = "Blizzard", ["Smooth"] = "Smooth"}
  if LSM then
    for _, name in pairs(LSM:List("statusbar")) do
      textures[name] = name
    end
  end
  return textures
end

local function GetBackgroundTextures()
  local textures = {["Solid"] = "Solid"}
  if LSM then
    -- Use background type from LSM for actual background textures
    for _, name in pairs(LSM:List("background")) do
      textures[name] = name
    end
  end
  return textures
end

local function GetFonts()
  local fonts = {["Friz Quadrata TT"] = "Friz Quadrata TT"}
  if LSM then
    for _, name in pairs(LSM:List("font")) do
      fonts[name] = name
    end
  end
  return fonts
end

-- Forward declarations for functions defined later
local IsIconMode
local IsBarMode
local IsDurationBar

local function GetBarOrientations()
  return {
    ["horizontal"] = "Horizontal",
    ["vertical"] = "Vertical"
  }
end

local function GetFillModes()
  return {
    ["drain"] = "Drain",
    ["fill"] = "Fill"
  }
end

-- ===================================================================
-- GET ALL BARS FOR SELECTOR (filtered by current spec)
-- ===================================================================

-- Power types that are spec-specific (Shaman Maelstrom is Elemental only)
local SPEC_RESTRICTED_POWERS = {
  ["SHAMAN"] = {
    [11] = {1},  -- Maelstrom only for Elemental (spec 1)
  }
}

local function IsPowerTypeValidForSpec(powerType)
  local _, playerClass = UnitClass("player")
  local currentSpec = GetSpecialization() or 0
  
  local classRestrictions = SPEC_RESTRICTED_POWERS[playerClass]
  if not classRestrictions then return true end
  
  local powerSpecs = classRestrictions[powerType]
  if not powerSpecs then return true end
  
  for _, allowedSpec in ipairs(powerSpecs) do
    if allowedSpec == currentSpec then
      return true
    end
  end
  
  return false
end

local function GetAllBarsDropdown()
  local values = {}
  local currentSpec = GetSpecialization() or 0
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  
  -- Iterate over existing buff/aura bars in database
  if db and db.bars then
    for i, cfg in pairs(db.bars) do
      if cfg and cfg.tracking and cfg.tracking.enabled then
        -- Check if bar should show on current spec
        local showOnSpecs = cfg.behavior and cfg.behavior.showOnSpecs
        local specAllowed = true
        
        if showOnSpecs and #showOnSpecs > 0 then
          specAllowed = false
          for _, spec in ipairs(showOnSpecs) do
            if spec == currentSpec then
              specAllowed = true
              break
            end
          end
        elseif cfg.behavior and cfg.behavior.showOnSpec and cfg.behavior.showOnSpec > 0 then
          specAllowed = (currentSpec == cfg.behavior.showOnSpec)
        end
        
        if specAllowed then
          -- Show label based on trackType: "Cooldown Bar/Icon" for cooldownCharge, "Buff Bar/Icon" for others
          local displayType = cfg.display.displayType or "bar"
          local trackType = cfg.tracking.trackType or "buff"
          local typeLabel
          if trackType == "cooldownCharge" then
            typeLabel = displayType == "icon" and "|cffff9900Cooldown Icon|r" or "|cffff9900Cooldown Bar|r"
          else
            typeLabel = displayType == "icon" and "|cff00ccffBuff Icon|r" or "|cff00ccffBuff Bar|r"
          end
          values["buff_" .. i] = string.format("%s %d: %s", typeLabel, i, cfg.tracking.buffName or cfg.tracking.spellName or "Unknown")
        end
      end
    end
  end
  
  -- Iterate over existing resource bars in database
  if db and db.resourceBars then
    for i, cfg in pairs(db.resourceBars) do
      if cfg and cfg.tracking and cfg.tracking.enabled then
        -- Check if power type is valid for current spec
        local powerType = cfg.tracking.powerType
        if IsPowerTypeValidForSpec(powerType) then
          -- Check if bar should show on current spec
          local showOnSpecs = cfg.behavior and cfg.behavior.showOnSpecs
          local specAllowed = true
          
          if showOnSpecs and #showOnSpecs > 0 then
            specAllowed = false
            for _, spec in ipairs(showOnSpecs) do
              if spec == currentSpec then
                specAllowed = true
                break
              end
            end
          elseif cfg.behavior and cfg.behavior.showOnSpec and cfg.behavior.showOnSpec > 0 then
            specAllowed = (currentSpec == cfg.behavior.showOnSpec)
          end
          
          if specAllowed then
            values["resource_" .. i] = string.format("|cff00ff00Resource|r %d: %s", i, cfg.tracking.powerName or "Unknown")
          end
        end
      end
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════
  -- LEGACY COOLDOWN BARS (from ns.db.char.cooldownBars)
  -- Format: "cooldown_barIndex" e.g. "cooldown_1"
  -- These are the original charge bars rendered by ArcUI_Display
  -- ═══════════════════════════════════════════════════════════════
  if ns.db and ns.db.char and ns.db.char.cooldownBars then
    for i, cfg in pairs(ns.db.char.cooldownBars) do
      if cfg and cfg.tracking and cfg.tracking.enabled then
        local spellName = cfg.tracking.spellName or cfg.tracking.buffName or "Unknown"
        local spellID = cfg.tracking.spellID or 0
        -- Try to get updated spell name
        if spellID > 0 then
          local updatedName = C_Spell.GetSpellName(spellID)
          if updatedName then spellName = updatedName end
        end
        values["cooldown_" .. i] = string.format("|cffffcc00Legacy Charge|r %d: %s", i, spellName)
      end
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════
  -- COOLDOWN BARS (from CooldownBars system)
  -- Format: "cd_barType_spellID" e.g. "cd_cooldown_12345"
  -- 3 bar types: Duration, Charge, Resource
  -- ═══════════════════════════════════════════════════════════════
  if ns.CooldownBars then
    -- Duration bars
    for spellID, _ in pairs(ns.CooldownBars.activeCooldowns or {}) do
      local name = C_Spell.GetSpellName(spellID) or "Unknown"
      values["cd_cooldown_" .. spellID] = string.format("|cffff8800CD Duration|r: %s", name)
    end
    
    -- Charge bars
    for spellID, _ in pairs(ns.CooldownBars.activeCharges or {}) do
      local name = C_Spell.GetSpellName(spellID) or "Unknown"
      values["cd_charge_" .. spellID] = string.format("|cff00ccffCD Charges|r: %s", name)
    end
    
    -- Resource bars (Coming Soon - grayed out)
    for spellID, _ in pairs(ns.CooldownBars.activeResources or {}) do
      local name = C_Spell.GetSpellName(spellID) or "Unknown"
      values["cd_resource_" .. spellID] = string.format("|cff666666CD Resource|r: %s |cff888888(Coming Soon)|r", name)
    end
  end
  
  if next(values) == nil then
    values["none"] = "No bars configured for this spec"
  end
  
  return values
end

-- Store selected bar
local selectedAppearanceBar = nil

local function GetSelectedBarType()
  if not selectedAppearanceBar then return nil, nil end
  
  -- Handle cooldown bars: "cd_barType_spellID" format
  local cdType, spellID = selectedAppearanceBar:match("cd_(%w+)_(%d+)")
  if cdType and spellID then
    return "cd_" .. cdType, tonumber(spellID)
  end
  
  -- Handle regular bars: "barType_barNum" format
  local barType, barNum = selectedAppearanceBar:match("(%w+)_(%d+)")
  return barType, tonumber(barNum)
end

-- Check if selected bar is a duration bar (tracks duration instead of stacks)
IsDurationBar = function()
  local barType, barNum = GetSelectedBarType()
  if not barType or not barNum then return false end
  
  -- Resource bars are never duration bars
  if barType == "resource" then return false end
  
  -- Cooldown bars from CooldownBars system ARE duration bars
  -- cd_cooldown = duration bar, cd_charge = recharge bar (both show time progression)
  if barType == "cd_cooldown" or barType == "cd_charge" then
    return true
  end
  
  -- Check buff bar config - ONLY useDurationBar flag determines if it's a duration bar
  local cfg = ns.API.GetBarConfig(barNum)
  if not cfg or not cfg.tracking then return false end
  -- Duration bar ONLY if useDurationBar is explicitly true
  return cfg.tracking.useDurationBar == true
end

local function GetSelectedConfig()
  local barType, barNum = GetSelectedBarType()
  if not barType or not barNum then return nil end
  
  if barType == "buff" then
    -- Regular bars (including cooldownCharge bars which now use regular bar config)
    return ns.API.GetBarConfig(barNum), "buff"
  elseif barType == "resource" then
    return ns.API.GetResourceBarConfig(barNum), "resource"
  elseif barType == "cooldown" then
    -- Legacy cooldown bars (from ns.db.char.cooldownBars)
    return ns.API.GetCooldownBarConfig(barNum), "cooldown"
  elseif barType:find("^cd_") then
    -- Cooldown bars: barType is "cd_cooldown", "cd_charge", etc.
    -- barNum is actually a spellID
    local cdBarType = barType:gsub("^cd_", "")  -- Remove "cd_" prefix
    local spellID = barNum
    
    -- CD Resource bars are "Coming Soon" - return nil to hide all options
    if cdBarType == "resource" then
      return nil, barType
    end
    
    if ns.CooldownBars and ns.CooldownBars.GetBarConfig then
      return ns.CooldownBars.GetBarConfig(spellID, cdBarType), barType
    end
  end
  return nil
end

-- Check if current bar is in icon display mode
IsIconMode = function()
  local cfg = GetSelectedConfig()
  return cfg and cfg.display and cfg.display.displayType == "icon"
end

-- Check if current bar is in bar display mode (or no selection)
IsBarMode = function()
  local cfg = GetSelectedConfig()
  return not cfg or not cfg.display or cfg.display.displayType ~= "icon"
end

-- Check if selected bar is a resource bar
local function IsResourceBar()
  local barType, _ = GetSelectedBarType()
  return barType == "resource"
end

-- Check if selected bar is a cooldown bar (from CooldownBars system)
local function IsCooldownBar()
  local barType, _ = GetSelectedBarType()
  return barType and barType:find("^cd_") ~= nil
end

-- Check if selected bar is a legacy cooldown bar (from ns.db.char.cooldownBars)
local function IsLegacyCooldownBar()
  local barType, _ = GetSelectedBarType()
  return barType == "cooldown"
end

-- Get the cooldown bar type (cooldown, charge, resource)
local function GetCooldownBarType()
  local barType, _ = GetSelectedBarType()
  if barType and barType:find("^cd_") then
    return barType:gsub("^cd_", "")
  end
  return nil
end

-- Check if selected bar is a charge bar (from CooldownBars system)
local function IsChargeBar()
  local cdType = GetCooldownBarType()
  return cdType == "charge"
end

-- Check if selected bar is a cooldown duration bar (from CooldownBars system)
local function IsCooldownDurationBar()
  local cdType = GetCooldownBarType()
  return cdType == "cooldown"
end

-- Check if selected bar is a CooldownBars resource bar (from CooldownBars system)
local function IsCooldownResourceBar()
  local cdType = GetCooldownBarType()
  return cdType == "resource"
end

-- Check if selected bar is a cooldown charge bar (by trackType in buff bars)
local function IsCooldownChargeBar()
  local barType, barNum = GetSelectedBarType()
  if barType == "buff" and barNum then
    local cfg = ns.API.GetBarConfig(barNum)
    if cfg and cfg.tracking and cfg.tracking.trackType == "cooldownCharge" then
      return true
    end
  end
  return false
end

-- Check if selected bar is a custom aura (trackType == "customAura")
local function IsCustomAura()
  local barType, barNum = GetSelectedBarType()
  if barType == "buff" and barNum then
    local cfg = ns.API.GetBarConfig(barNum)
    if cfg and cfg.tracking and cfg.tracking.trackType == "customAura" then
      return true
    end
  end
  return false
end

-- Check if selected bar is a custom cooldown (trackType == "customCooldown")
local function IsCustomCooldown()
  local barType, barNum = GetSelectedBarType()
  if barType == "buff" and barNum then
    local cfg = ns.API.GetBarConfig(barNum)
    if cfg and cfg.tracking and cfg.tracking.trackType == "customCooldown" then
      return true
    end
  end
  return false
end

-- Check if selected bar is any custom tracking type
local function IsCustomTracking()
  return IsCustomAura() or IsCustomCooldown()
end

-- Apply color ranges to stackColors array
local function ApplyColorRanges(cfg)
  if not cfg then return end
  local maxStacks = cfg.tracking.maxStacks or 10
  
  -- Initialize stackColors if needed
  if not cfg.stackColors then cfg.stackColors = {} end
  
  -- Clear existing stack colors
  for i = 1, maxStacks do
    cfg.stackColors[i] = nil
  end
  
  -- Apply ranges in order (later ranges override earlier)
  local ranges = cfg.colorRanges or {}
  
  -- Range 1 is always active
  if ranges[1] then
    local r = ranges[1]
    local fromVal = r.from or 1
    local toVal = r.to or maxStacks
    local color = r.color or {r=0, g=0.5, b=1, a=1}
    for i = fromVal, math.min(toVal, maxStacks) do
      cfg.stackColors[i] = {r=color.r, g=color.g, b=color.b, a=color.a or 1}
    end
  end
  
  -- Range 2 if enabled
  if ranges[2] and ranges[2].enabled then
    local r = ranges[2]
    local fromVal = r.from or 5
    local toVal = r.to or 8
    local color = r.color or {r=1, g=1, b=0, a=1}
    for i = fromVal, math.min(toVal, maxStacks) do
      cfg.stackColors[i] = {r=color.r, g=color.g, b=color.b, a=color.a or 1}
    end
  end
  
  -- Range 3 if enabled
  if ranges[3] and ranges[3].enabled then
    local r = ranges[3]
    local fromVal = r.from or 9
    local toVal = r.to or 12
    local color = r.color or {r=0, g=1, b=0, a=1}
    for i = fromVal, math.min(toVal, maxStacks) do
      cfg.stackColors[i] = {r=color.r, g=color.g, b=color.b, a=color.a or 1}
    end
  end
  
  -- Fill any gaps with default color
  local defaultColor = {r=0.3, g=0.3, b=0.3, a=1}
  for i = 1, maxStacks do
    if not cfg.stackColors[i] then
      cfg.stackColors[i] = defaultColor
    end
  end
end

-- ===================================================================
-- LIVE PREVIEW SYSTEM
-- ===================================================================
local livePreviewEnabled = false
local livePreviewStatic = false  -- Static mode vs animated
local staticPreviewValue = 5
local previewTimer = nil
local previewValue = 0
local previewDirection = 1  -- 1 = filling, -1 = emptying
local ANIMATION_DURATION = 6.0  -- Full cycle takes 6 seconds (up and down)
local ANIMATION_TICK = 0.05  -- Update every 50ms for smooth animation

-- Forward declare
local ApplyPreviewValue

-- Helper: Clear color curve cache for the current selected bar
local function ClearSelectedBarColorCurve()
  local barType, barNum = GetSelectedBarType()
  if not barType or not barNum then return end
  
  if barType and barType:find("^cd_") then
    -- Cooldown bar - clear from CooldownBars system
    local cdBarType = barType:gsub("^cd_", "")
    local spellID = barNum
    if ns.CooldownBars and ns.CooldownBars.ClearCooldownColorCurve then
      ns.CooldownBars.ClearCooldownColorCurve(spellID, cdBarType)
    end
  else
    -- Aura bar - clear from Display system
    if ns.Display and ns.Display.ClearDurationColorCurve then
      ns.Display.ClearDurationColorCurve(barNum)
    end
  end
end

local function RefreshBar()
  local barType, barNum = GetSelectedBarType()
  if not barType or not barNum then return end
  
  if barType == "buff" then
    if ns.Display and ns.Display.ApplyAppearance then
      ns.Display.ApplyAppearance(barNum)
    end
    -- Force update to refresh tick marks and other dynamic elements
    if ns.API and ns.API.RefreshDisplay then
      ns.API.RefreshDisplay(barNum)
    end
  elseif barType == "resource" then
    if ns.Resources and ns.Resources.ApplyAppearance then
      ns.Resources.ApplyAppearance(barNum)
    end
    if ns.Resources and ns.Resources.UpdateBar then
      ns.Resources.UpdateBar(barNum)
    end
  elseif barType:find("^cd_") then
    -- Cooldown bars: barType is "cd_cooldown", "cd_charge", etc.
    -- barNum is actually a spellID
    local cdBarType = barType:gsub("^cd_", "")  -- Remove "cd_" prefix
    local spellID = barNum
    if ns.CooldownBars and ns.CooldownBars.ApplyAppearance then
      ns.CooldownBars.ApplyAppearance(spellID, cdBarType)
    end
  end
  
  -- Re-apply preview value if static preview is active (delay to let ApplyAppearance complete)
  if livePreviewEnabled and livePreviewStatic then
    C_Timer.After(0.1, function()
      if livePreviewEnabled and livePreviewStatic then
        ApplyPreviewValue(staticPreviewValue)
      end
    end)
  end
end

local function UpdateBar()
  local barType, barNum = GetSelectedBarType()
  if not barType or not barNum then return end
  
  if barType == "buff" then
    if ns.Display and ns.Display.UpdateBar then
      ns.Display.UpdateBar(barNum)
    end
  elseif barType == "resource" then
    if ns.Resources and ns.Resources.UpdateBar then
      ns.Resources.UpdateBar(barNum)
    end
  elseif barType:find("^cd_") then
    -- Cooldown bars: ApplyAppearance for visual settings, ForceUpdate for behavior/visibility
    local cdBarType = barType:gsub("^cd_", "")
    local spellID = barNum
    if ns.CooldownBars then
      if ns.CooldownBars.ApplyAppearance then
        ns.CooldownBars.ApplyAppearance(spellID, cdBarType)
      end
      -- Also trigger visibility re-evaluation for behavior settings (hideWhenReady, etc.)
      if ns.CooldownBars.ForceUpdate then
        ns.CooldownBars.ForceUpdate(spellID, cdBarType)
      end
    end
  end
  
  -- Re-apply preview value if static preview is active (delay to let UpdateBar complete)
  if livePreviewEnabled and livePreviewStatic then
    C_Timer.After(0.1, function()
      if livePreviewEnabled and livePreviewStatic then
        ApplyPreviewValue(staticPreviewValue)
      end
    end)
  end
end

local function StopPreview()
  livePreviewEnabled = false
  livePreviewStatic = false
  if previewTimer then
    previewTimer:Cancel()
    previewTimer = nil
  end
  previewValue = 0
  previewDirection = 1
  
  -- Disable preview mode in Display module
  if ns.Display and ns.Display.SetPreviewMode then
    ns.Display.SetPreviewMode(false)
  end
  
  -- Reset bar to actual value
  local barType, barNum = GetSelectedBarType()
  if barType and barNum then
    if barType == "buff" then
      -- Trigger a refresh which will use actual tracking data
      if ns.API and ns.API.RefreshDisplay then
        ns.API.RefreshDisplay(barNum)
      elseif ns.Display and ns.Display.UpdateBar then
        ns.Display.UpdateBar(barNum)
      end
    elseif barType == "resource" then
      if ns.Resources and ns.Resources.UpdateBar then
        ns.Resources.UpdateBar(barNum)
      end
    elseif barType == "cooldown" then
      -- Clear preview mode so tracking resumes
      if ns.CooldownBars and ns.CooldownBars.SetPreviewMode then
        ns.CooldownBars.SetPreviewMode(barNum, false)
      end
    end
  end
end

ApplyPreviewValue = function(value)
  local barType, barNum = GetSelectedBarType()
  if not barType or not barNum then return end
  
  -- Call UpdateBar directly with preview value - this handles all display modes correctly
  if barType == "buff" then
    local cfg = ns.API.GetBarConfig(barNum)
    if cfg then
      local useDurationBar = cfg.tracking.useDurationBar
      
      if useDurationBar then
        -- Duration bar - call UpdateDurationBar
        -- For duration bars, maxStacks is used to scale the preview
        -- Use maxDuration if set, otherwise default to 30
        local maxDuration = cfg.tracking.maxDuration or 30
        -- Ensure we have a valid max for the preview calculation
        local maxForPreview = math.max(1, maxDuration)
        if ns.Display and ns.Display.UpdateDurationBar then
          ns.Display.UpdateDurationBar(barNum, value, maxForPreview, true, nil, nil, nil)
        end
      else
        -- Stack bar - call UpdateBar
        local maxStacks = cfg.tracking.maxStacks or 10
        if ns.Display and ns.Display.UpdateBar then
          ns.Display.UpdateBar(barNum, value, maxStacks, true)
        end
      end
    end
  elseif barType == "resource" then
    if ns.Resources and ns.Resources.SetPreviewValue then
      ns.Resources.SetPreviewValue(barNum, value)
    end
  elseif barType == "cooldown" then
    if ns.CooldownBars and ns.CooldownBars.SetPreviewValue then
      ns.CooldownBars.SetPreviewValue(barNum, value)
    elseif ns.CooldownBars and ns.CooldownBars.UpdateBar then
      -- Fallback if SetPreviewValue not available
      local cfg = ns.API.GetBarConfig(barNum)
      local maxStacks = cfg and cfg.tracking and cfg.tracking.maxStacks or 3
      ns.CooldownBars.UpdateBar(barNum, value, maxStacks)
    end
  end
end

local function RunPreview()
  if not livePreviewEnabled then return end
  if livePreviewStatic then return end  -- Don't animate in static mode
  
  local barType, barNum = GetSelectedBarType()
  if not barType or not barNum then return end
  
  local cfg
  if barType == "buff" then
    cfg = ns.API.GetBarConfig(barNum)
  elseif barType == "resource" then
    cfg = ns.API.GetResourceBarConfig(barNum)
  elseif barType == "cooldown" then
    cfg = ns.API.GetBarConfig(barNum)
  end
  if not cfg then return end
  
  -- Get the appropriate max value based on bar type
  local maxVal
  if barType == "buff" and cfg.tracking.useDurationBar then
    -- Duration bar - use maxDuration (default to 30 for preview)
    maxVal = cfg.tracking.maxDuration or 30
  else
    -- Stack bar or resource bar
    maxVal = cfg.tracking.maxValue or cfg.tracking.maxStacks or 10
  end
  
  -- Ensure maxVal is at least 1 to avoid division issues
  maxVal = math.max(1, maxVal)
  
  -- Time-based animation: full cycle takes ANIMATION_DURATION seconds
  local stepSize = (maxVal * 2 * ANIMATION_TICK) / ANIMATION_DURATION
  
  -- Update preview value
  previewValue = previewValue + (previewDirection * stepSize)
  if previewValue >= maxVal then
    previewValue = maxVal
    previewDirection = -1
  elseif previewValue <= 0 then
    previewValue = 0
    previewDirection = 1
  end
  
  -- Update the global previewStacks decimal (0-1) in Display module
  local pct = previewValue / maxVal
  if ns.Display and ns.Display.SetPreviewStacks then
    ns.Display.SetPreviewStacks(pct)
  end
  
  ApplyPreviewValue(math.floor(previewValue + 0.5))
end

local function StartPreview()
  livePreviewEnabled = true
  livePreviewStatic = false
  previewValue = 0
  previewDirection = 1
  
  -- Enable preview mode in Display module for consistent detection
  if ns.Display and ns.Display.SetPreviewMode then
    ns.Display.SetPreviewMode(true)
  end
  
  if previewTimer then
    previewTimer:Cancel()
  end
  
  previewTimer = C_Timer.NewTicker(ANIMATION_TICK, RunPreview)
end

local function StartStaticPreview(value)
  livePreviewEnabled = true
  livePreviewStatic = true
  staticPreviewValue = value or 5
  
  -- Enable preview mode in Display module for consistent detection
  if ns.Display and ns.Display.SetPreviewMode then
    ns.Display.SetPreviewMode(true)
  end
  
  -- Calculate and set previewStacks decimal (0-1) in Display module
  local barType, barNum = GetSelectedBarType()
  if barType and barNum then
    local cfg
    if barType == "buff" then
      cfg = ns.API.GetBarConfig(barNum)
    elseif barType == "resource" then
      cfg = ns.API.GetResourceBarConfig(barNum)
    end
    if cfg then
      local maxVal
      if barType == "buff" and cfg.tracking.useDurationBar then
        maxVal = cfg.tracking.maxDuration or 30
      else
        maxVal = cfg.tracking.maxValue or cfg.tracking.maxStacks or 10
      end
      maxVal = math.max(1, maxVal)
      local pct = staticPreviewValue / maxVal
      if ns.Display and ns.Display.SetPreviewStacks then
        ns.Display.SetPreviewStacks(pct)
      end
    end
  end
  
  if previewTimer then
    previewTimer:Cancel()
    previewTimer = nil
  end
  
  ApplyPreviewValue(staticPreviewValue)
end

-- ===================================================================
-- EDITING INDICATOR
-- ===================================================================
local currentEditingFrame = nil

local function HideEditingIndicator()
  if currentEditingFrame and currentEditingFrame.editingText then
    currentEditingFrame.editingText:Hide()
  end
  currentEditingFrame = nil
end

local function ShowEditingIndicator()
  -- Hide previous indicator
  HideEditingIndicator()
  
  local barType, barNum = GetSelectedBarType()
  if not barType or not barNum then return end
  
  local frame = nil
  if barType == "buff" then
    frame = ns.Display and ns.Display.GetBarFrame and ns.Display.GetBarFrame(barNum)
  elseif barType == "resource" then
    frame = ns.Resources and ns.Resources.GetBarFrame and ns.Resources.GetBarFrame(barNum)
  elseif barType == "cooldown" then
    frame = ns.CooldownBars and ns.CooldownBars.GetBarFrame and ns.CooldownBars.GetBarFrame(barNum)
  end
  
  if not frame then return end
  
  -- Create editing text if it doesn't exist
  if not frame.editingText then
    frame.editingText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.editingText:SetTextColor(1, 1, 0, 1)
    frame.editingText:SetText("Editing")
  end
  
  -- Position above the bar (BOTTOMLEFT of text anchored to TOPLEFT of bar)
  frame.editingText:ClearAllPoints()
  frame.editingText:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
  frame.editingText:Show()
  currentEditingFrame = frame
end

-- Cleanup when options panel closes
local optionsCleanupFrame = CreateFrame("Frame")
optionsCleanupFrame:RegisterEvent("ADDON_LOADED")
optionsCleanupFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Hide when entering combat

local optionsFrameVisible = false

optionsCleanupFrame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" then
    -- Hook into AceConfigDialog to detect panel close
    C_Timer.After(3, function()
      local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
      if AceConfigDialog then
        hooksecurefunc(AceConfigDialog, "Close", function(self, appName)
          if appName == "ArcUI" then
            if livePreviewEnabled then
              StopPreview()
            end
            -- Hide editing indicator
            HideEditingIndicator()
            optionsFrameVisible = false
          end
        end)
        
        -- Also hook Open to track when panel is opened
        hooksecurefunc(AceConfigDialog, "Open", function(self, appName)
          if appName == "ArcUI" then
            optionsFrameVisible = true
          end
        end)
      end
    end)
    
    -- Set up OnUpdate to check for hidden options frame
    self:SetScript("OnUpdate", function(self, elapsed)
      if optionsFrameVisible then
        -- Check if the ArcUI options frame still exists and is visible
        local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        if AceConfigDialog then
          local frame = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["ArcUI"]
          if not frame or not frame:IsShown() then
            HideEditingIndicator()
            optionsFrameVisible = false
          end
        end
      end
    end)
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Hide editing indicator when entering combat
    HideEditingIndicator()
  end
end)

-- ===================================================================
-- SET SELECTED BAR (for external access)
-- ===================================================================
function ns.AppearanceOptions.SetSelectedBar(barType, barNum)
  selectedAppearanceBar = barType .. "_" .. barNum
  if ns.devMode then
    print(string.format("|cff00FFFF[ArcUI Debug]|r AppearanceOptions.SetSelectedBar: set to '%s'", 
      selectedAppearanceBar))
  end
end

-- ===================================================================
-- APPEARANCE OPTIONS TABLE
-- ===================================================================
function ns.AppearanceOptions.GetOptionsTable()
  local appearanceOptions = {
    type = "group",
    name = "Appearance",
    order = 4,
    args = {
      -- ============================================================
      -- ITEM SELECTOR
      -- ============================================================
      selectorHeader = {
        type = "header",
        name = "Select Item to Edit",
        order = 1
      },
      selectorTip = {
        type = "description",
        name = "|cff888888Tip: Right-click on any bar or icon in-game to quickly select it here.|r",
        fontSize = "small",
        order = 1.5,
        width = "full"
      },
      barSelector = {
        type = "select",
        name = " ",
        desc = "Choose which item to customize",
        values = GetAllBarsDropdown,
        get = function()
          local bars = GetAllBarsDropdown()
          
          -- Check if current selection is still valid
          if selectedAppearanceBar and bars[selectedAppearanceBar] then
            -- Show editing indicator if not already showing for this bar
            if not currentEditingFrame then
              C_Timer.After(0.1, ShowEditingIndicator)
            end
            return selectedAppearanceBar
          end
          
          -- Debug: selectedAppearanceBar was set but not found in dropdown
          if ns.devMode and selectedAppearanceBar then
            print(string.format("|cffFF6600[ArcUI Debug]|r selectedAppearanceBar '%s' not found in dropdown!", 
              tostring(selectedAppearanceBar)))
            print("|cffFF6600[ArcUI Debug]|r Available bars:")
            for k, v in pairs(bars) do
              print(string.format("  - %s: %s", k, v))
            end
          end
          
          -- Current selection invalid - find first valid bar using SORTED order
          -- (pairs() order is not guaranteed, so we need to sort for consistency)
          selectedAppearanceBar = nil
          local sortedKeys = {}
          for k, v in pairs(bars) do
            if k ~= "none" then
              table.insert(sortedKeys, k)
            end
          end
          table.sort(sortedKeys)  -- Sort alphabetically for consistent order
          
          if #sortedKeys > 0 then
            selectedAppearanceBar = sortedKeys[1]
          end
          
          -- Show editing indicator for newly selected bar
          if selectedAppearanceBar and not currentEditingFrame then
            C_Timer.After(0.1, ShowEditingIndicator)
          end
          
          return selectedAppearanceBar
        end,
        set = function(info, value)
          if value ~= "none" then
            selectedAppearanceBar = value
            ShowEditingIndicator()
          end
        end,
        order = 2,
        width = 1.4
      },
      presetSpacer = {
        type = "description",
        name = " ",
        order = 2.3,
        width = 0.1,
        hidden = function()
          return not IsCooldownBar()
        end
      },
      presetSelector = {
        type = "select",
        name = "Style",
        desc = "Apply a preset style to this bar. This will reset all appearance settings to the preset defaults.",
        values = function()
          if ns.CooldownBars and ns.CooldownBars.GetPresetNames then
            return ns.CooldownBars.GetPresetNames()
          end
          return { ["arcui"] = "ArcUI", ["simple"] = "Simple" }
        end,
        get = function()
          if not IsCooldownBar() then return "arcui" end
          local barType, spellID = GetSelectedBarType()
          if not barType or not spellID then return "arcui" end
          -- barType is "cd_cooldown" or "cd_charge", extract the cooldown bar type
          local cdBarType = barType:gsub("^cd_", "")
          if ns.CooldownBars and ns.CooldownBars.GetPreset then
            return ns.CooldownBars.GetPreset(spellID, cdBarType) or "arcui"
          end
          return "arcui"
        end,
        set = function(info, value)
          if not IsCooldownBar() then return end
          local barType, spellID = GetSelectedBarType()
          if not barType or not spellID then return end
          -- barType is "cd_cooldown" or "cd_charge", extract the cooldown bar type
          local cdBarType = barType:gsub("^cd_", "")
          if ns.CooldownBars and ns.CooldownBars.ApplyPreset then
            ns.CooldownBars.ApplyPreset(spellID, cdBarType, value)
          end
        end,
        order = 2.5,
        width = 0.6,
        hidden = function()
          return not IsCooldownBar()
        end
      },
      -- Multi-icon mode removed in v2.7.0 - was causing issues
      noBarWarning = {
        type = "description",
        name = "|cffff6b6bNo items configured. Go to Bars Setup or Icon Setup tab to add items.|r",
        fontSize = "medium",
        order = 3,
        hidden = function()
          if IsIconMode() then return true end
          local bars = GetAllBarsDropdown()
          return bars["none"] == nil
        end
      },
      resourceComingSoon = {
        type = "description",
        name = "\n|cff888888CD Resource bars are coming soon!|r\n\n|cffaaaaaa Appearance customization for resource bars is not yet available. The bar will display but cannot be customized at this time.|r\n",
        fontSize = "medium",
        order = 3.1,
        hidden = function()
          return not IsCooldownResourceBar()
        end
      },
      livePreviewSpacer = {
        type = "description",
        name = "  ",
        order = 3.4,
        width = 0.35,
        hidden = function()
          if IsIconMode() then return true end
          return GetSelectedConfig() == nil
        end
      },
      livePreviewLabel = {
        type = "description",
        name = "Live Preview:",
        order = 3.5,
        width = 0.55,
        hidden = function()
          if IsIconMode() then return true end
          return GetSelectedConfig() == nil
        end
      },
      livePreview = {
        type = "toggle",
        name = "Animate",
        desc = "Show animated fill preview cycling 0 to max",
        get = function()
          return livePreviewEnabled and not livePreviewStatic
        end,
        set = function(info, value)
          if value then
            StartPreview()
          else
            StopPreview()
          end
        end,
        order = 4,
        width = 0.55,
        hidden = function()
          if IsIconMode() then return true end
          return GetSelectedConfig() == nil
        end
      },
      staticPreview = {
        type = "toggle",
        name = "Static",
        desc = "Preview at a fixed value",
        get = function()
          return livePreviewEnabled and livePreviewStatic
        end,
        set = function(info, value)
          if value then
            StartStaticPreview(staticPreviewValue)
          else
            StopPreview()
          end
        end,
        order = 4.5,
        width = 0.45,
        hidden = function()
          if IsIconMode() then return true end
          return GetSelectedConfig() == nil
        end
      },
      staticPreviewValue = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Value",
        desc = "Preview value (press Enter to apply)",
        get = function()
          return tostring(staticPreviewValue)
        end,
        set = function(info, value)
          local num = tonumber(value)
          if not num then return end
          
          -- Clamp to actual bar max
          local barType, barNum = GetSelectedBarType()
          local actualMax = 10
          if barType and barNum then
            local cfg
            if barType == "buff" then
              cfg = ns.API.GetBarConfig(barNum)
              -- For duration bars, use maxDuration; otherwise maxStacks
              if cfg and cfg.tracking.useDurationBar then
                actualMax = cfg.tracking.maxDuration or 30
              else
                actualMax = cfg and cfg.tracking.maxStacks or 10
              end
            else
              cfg = ns.API.GetResourceBarConfig(barNum)
              actualMax = cfg and cfg.tracking.maxValue or 100
            end
            num = math.max(0, math.min(actualMax, math.floor(num)))
          end
          staticPreviewValue = num
          if livePreviewEnabled and livePreviewStatic then
            -- Also update previewStacks decimal in Display module
            local pct = num / math.max(1, actualMax)
            if ns.Display and ns.Display.SetPreviewStacks then
              ns.Display.SetPreviewStacks(pct)
            end
            ApplyPreviewValue(num)
          end
        end,
        order = 4.6,
        width = 0.35,
        hidden = function()
          if IsIconMode() then return true end
          return not (livePreviewEnabled and livePreviewStatic)
        end
      },
      
      -- ============================================================
      -- ICON DISPLAY (collapsible sub-section)
      -- ============================================================
      iconDisplayHeader = {
        type = "toggle",
        name = "Icon Display",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.iconDisplay end,
        set = function(info, value) collapsedSections.iconDisplay = not value end,
        order = 9,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsBarMode() end
      },
      iconSize = {
        type = "range",
        name = "Size",
        desc = "Size of the icon frame",
        min = 8, max = 200, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconSize or 48
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconSize = value
            RefreshBar()
          end
        end,
        order = 9.11,
        width = 0.6,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay
        end
      },
      iconShowTexture = {
        type = "toggle",
        name = "Show Icon",
        desc = "Show the icon texture (disable to show only text)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and (cfg.display.iconShowTexture ~= false)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconShowTexture = value
            RefreshBar()
          end
        end,
        order = 9.12,
        width = 0.6,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay
        end
      },
      iconShowBorder = {
        type = "toggle",
        name = "Show Border",
        desc = "Show border around icon",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconShowBorder
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconShowBorder = value
            RefreshBar()
          end
        end,
        order = 9.13,
        width = 0.7,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay
        end
      },
      iconBorderColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.iconBorderColor then
            local c = cfg.display.iconBorderColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 0, 0, 0, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconBorderColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 9.14,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not cfg.display.iconShowBorder
        end
      },
      
      -- Stacks Text subsection
      iconStacksLabel = {
        type = "description",
        name = "\n|cffffd700Stacks Text|r",
        fontSize = "medium",
        order = 9.2,
        width = "full",
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay
        end
      },
      iconShowStacks = {
        type = "toggle",
        name = "Show Stacks",
        desc = "Show stack count on icon",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconShowStacks
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconShowStacks = value
            RefreshBar()
          end
        end,
        order = 9.21,
        width = 0.7,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay
        end
      },
      iconStackAnchor = {
        type = "select",
        name = "Position",
        desc = "Where to show stack count (FREE allows drag positioning)",
        values = {
          ["TOPRIGHT"] = "Top Right (Inner)",
          ["TOPLEFT"] = "Top Left (Inner)",
          ["BOTTOMRIGHT"] = "Bottom Right (Inner)",
          ["BOTTOMLEFT"] = "Bottom Left (Inner)",
          ["TOPRIGHT_OUTER"] = "Top Right (Outer)",
          ["TOPLEFT_OUTER"] = "Top Left (Outer)",
          ["BOTTOMRIGHT_OUTER"] = "Bottom Right (Outer)",
          ["BOTTOMLEFT_OUTER"] = "Bottom Left (Outer)",
          ["CENTER"] = "Center",
          ["FREE"] = "Free (Drag)"
        },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconStackAnchor or "TOPRIGHT"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconStackAnchor = value
            RefreshBar()
          end
        end,
        order = 9.22,
        width = 0.7,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not cfg.display.iconShowStacks
        end
      },
      iconStackFont = {
        type = "select",
        name = "Font",
        values = GetFonts,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconStackFont or "2002 Bold"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconStackFont = value
            RefreshBar()
          end
        end,
        order = 9.225,
        width = 0.8,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not cfg.display.iconShowStacks
        end
      },
      iconStackFontSize = {
        type = "range",
        name = "Font Size",
        min = 4, max = 64, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconStackFontSize or 16
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconStackFontSize = value
            RefreshBar()
          end
        end,
        order = 9.23,
        width = 0.55,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not cfg.display.iconShowStacks
        end
      },
      iconStackColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.iconStackColor then
            local c = cfg.display.iconStackColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 1, 1, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconStackColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 9.24,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not cfg.display.iconShowStacks
        end
      },
      iconStackOutline = {
        type = "select",
        name = "Outline",
        values = { NONE = "None", OUTLINE = "Thin", THICKOUTLINE = "Thick" },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconStackOutline or "THICKOUTLINE"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconStackOutline = value
            RefreshBar()
          end
        end,
        order = 9.241,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not cfg.display.iconShowStacks
        end
      },
      iconStackShadow = {
        type = "toggle",
        name = "Shadow",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconStackShadow
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconStackShadow = value
            RefreshBar()
          end
        end,
        order = 9.242,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not cfg.display.iconShowStacks
        end
      },
      -- Icon stack strata
      iconStackStrata = {
        type = "select",
        name = "Strata",
        desc = "Frame strata for stacks text. Higher strata appears above lower strata.",
        values = {
          ["BACKGROUND"] = "BACKGROUND",
          ["LOW"] = "LOW",
          ["MEDIUM"] = "MEDIUM",
          ["HIGH"] = "HIGH",
          ["DIALOG"] = "DIALOG",
          ["TOOLTIP"] = "TOOLTIP",
        },
        sorting = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP"},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconStackStrata or cfg.display.barFrameStrata or "MEDIUM"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconStackStrata = value
            RefreshBar()
          end
        end,
        order = 9.243,
        width = 0.6,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not cfg.display.iconShowStacks
        end
      },
      -- Icon stack level
      iconStackLevel = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Level",
        desc = "Frame level (1-500). Higher level appears above lower level within same strata.",
        get = function()
          local cfg = GetSelectedConfig()
          local iconLevel = cfg and cfg.display.barFrameLevel or 10
          return tostring(cfg and cfg.display.iconStackLevel or (iconLevel + 20))
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            local num = tonumber(value)
            if num and num >= 1 and num <= 500 then
              cfg.display.iconStackLevel = num
              RefreshBar()
            end
          end
        end,
        order = 9.244,
        width = 0.4,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not cfg.display.iconShowStacks
        end
      },
      
      -- ============================================================
      -- CUSTOM ICON OPTIONS (for customAura and customCooldown only)
      -- ============================================================
      customIconLabel = {
        type = "description",
        name = "\n|cffffd700Custom Icon Options|r",
        fontSize = "medium",
        order = 9.25,
        width = "full",
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not IsCustomTracking()
        end
      },
      
      -- Icon Zoom (crop edges)
      iconZoom = {
        type = "range",
        name = "Icon Zoom",
        desc = "Crop icon edges (0 = none, 0.5 = max zoom)",
        min = 0, max = 0.75, step = 0.01,
        isPercent = true,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconZoom or 0
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconZoom = value
            RefreshBar()
          end
        end,
        order = 9.251,
        width = 0.8,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not IsCustomTracking()
        end
      },
      
      -- Desaturate options (different for auras vs cooldowns)
      iconDesaturateWhenInactive = {
        type = "toggle",
        name = "Gray When Inactive",
        desc = "Desaturate (gray out) the icon when the aura is not active",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconDesaturateWhenInactive
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconDesaturateWhenInactive = value
            RefreshBar()
          end
        end,
        order = 9.252,
        width = 1.0,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not IsCustomAura()
        end
      },
      
      -- Cooldown Swipe section (only for customCooldown)
      cooldownSwipeLabel = {
        type = "description",
        name = "\n|cffffd700Cooldown Swipe|r",
        fontSize = "medium",
        order = 9.26,
        width = "full",
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not IsCustomCooldown()
        end
      },
      iconShowCooldownSwipe = {
        type = "toggle",
        name = "Show Swipe",
        desc = "Show the animated cooldown swipe overlay",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and (cfg.display.iconShowCooldownSwipe ~= false)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconShowCooldownSwipe = value
            RefreshBar()
          end
        end,
        order = 9.261,
        width = 0.6,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not IsCustomCooldown()
        end
      },
      iconCooldownReverse = {
        type = "toggle",
        name = "Reverse",
        desc = "Reverse the swipe direction (fills instead of empties)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconCooldownReverse
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconCooldownReverse = value
            RefreshBar()
          end
        end,
        order = 9.262,
        width = 0.5,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not IsCustomCooldown() or not cfg.display.iconShowCooldownSwipe
        end
      },
      iconCooldownDrawEdge = {
        type = "toggle",
        name = "Edge Glow",
        desc = "Show a glowing edge at the swipe position",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and (cfg.display.iconCooldownDrawEdge ~= false)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconCooldownDrawEdge = value
            RefreshBar()
          end
        end,
        order = 9.263,
        width = 0.6,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not IsCustomCooldown() or not cfg.display.iconShowCooldownSwipe
        end
      },
      iconCooldownDrawBling = {
        type = "toggle",
        name = "Bling",
        desc = "Show a bling effect when cooldown completes",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and (cfg.display.iconCooldownDrawBling ~= false)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconCooldownDrawBling = value
            RefreshBar()
          end
        end,
        order = 9.264,
        width = 0.5,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not IsCustomCooldown() or not cfg.display.iconShowCooldownSwipe
        end
      },
      iconDesaturateOnCooldown = {
        type = "toggle",
        name = "Gray on Cooldown",
        desc = "Desaturate (gray out) the icon while on cooldown",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and (cfg.display.iconDesaturateOnCooldown ~= false)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconDesaturateOnCooldown = value
            RefreshBar()
          end
        end,
        order = 9.265,
        width = 1.0,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDisplay or not IsCustomCooldown()
        end
      },
      
      -- ============================================================
      -- ICON DURATION TEXT (collapsible sub-section)
      -- ============================================================
      iconDurationHeader = {
        type = "toggle",
        name = "Duration Text",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.iconDuration end,
        set = function(info, value) collapsedSections.iconDuration = not value end,
        order = 9.3,
        width = "full",
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon"
        end
      },
      iconShowDuration = {
        type = "toggle",
        name = "Show Duration",
        desc = "Show remaining duration",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconShowDuration
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconShowDuration = value
            RefreshBar()
          end
        end,
        order = 9.31,
        width = 0.8,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDuration
        end
      },
      iconDurationFont = {
        type = "select",
        name = "Font",
        values = GetFonts,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconDurationFont or "2002 Bold"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconDurationFont = value
            RefreshBar()
          end
        end,
        order = 9.315,
        width = 0.8,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDuration or not cfg.display.iconShowDuration
        end
      },
      iconDurationFontSize = {
        type = "range",
        name = "Font Size",
        min = 4, max = 64, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconDurationFontSize or 14
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconDurationFontSize = value
            RefreshBar()
          end
        end,
        order = 9.32,
        width = 0.55,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDuration or not cfg.display.iconShowDuration
        end
      },
      iconDurationDecimals = {
        type = "select",
        name = "Decimals",
        desc = "Round duration to X decimal places",
        values = {
          [0] = "0",
          [1] = "1",
          [2] = "2",
          [3] = "3"
        },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationDecimals or 1
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationDecimals = value
            RefreshBar()
          end
        end,
        order = 9.325,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDuration or not cfg.display.iconShowDuration
        end
      },
      iconDurationColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.iconDurationColor then
            local c = cfg.display.iconDurationColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 1, 1, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconDurationColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 9.33,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDuration or not cfg.display.iconShowDuration
        end
      },
      iconDurationOutline = {
        type = "select",
        name = "Outline",
        values = { NONE = "None", OUTLINE = "Thin", THICKOUTLINE = "Thick" },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconDurationOutline or "THICKOUTLINE"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconDurationOutline = value
            RefreshBar()
          end
        end,
        order = 9.34,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDuration or not cfg.display.iconShowDuration
        end
      },
      iconDurationShadow = {
        type = "toggle",
        name = "Shadow",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconDurationShadow
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconDurationShadow = value
            RefreshBar()
          end
        end,
        order = 9.35,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.displayType ~= "icon" or collapsedSections.iconDuration or not cfg.display.iconShowDuration
        end
      },
      
      -- ============================================================
      -- BAR SIZE (collapsible)
      -- ============================================================
      sizeHeader = {
        type = "toggle",
        name = "Bar Size",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.barSize end,
        set = function(info, value) collapsedSections.barSize = not value end,
        order = 10,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() end
      },
      barScale = {
        type = "range",
        name = "Bar Scale",
        min = 0.25, max = 4, step = 0.05,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.barScale or 1.0
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barScale = value
            RefreshBar()
          end
        end,
        order = 11,
        width = 1.0,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.barSize end
      },
      fineTuningBarSize = {
        type = "toggle",
        name = "Fine Tuning",
        desc = "Switch to direct input boxes for pixel-precise bar width and height values.",
        order = 11.5,
        width = 0.85,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.barSize end,
        get = function()
          return ns._fineTuningBarSize
        end,
        set = function(_, val)
          ns._fineTuningBarSize = val
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
      },
      barWidth = {
        type = "range",
        name = function()
          if IsChargeBar() then
            return "Slots Width"
          end
          return "Bar Width"
        end,
        desc = function()
          if IsChargeBar() then
            return "Width of the recharge fill textures (independent of frame width)"
          end
          return "Width of the bar"
        end,
        min = 10, max = 800, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.width or 100
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.width = value
            RefreshBar()
          end
        end,
        order = 12,
        width = 1.0,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.barSize or ns._fineTuningBarSize end
      },
      barWidthInput = {
        type = "input",
        name = function()
          if IsChargeBar() then
            return "Slots Width"
          end
          return "Bar Width"
        end,
        desc = "Type exact pixel value",
        order = 12,
        width = 0.4,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.barSize or not ns._fineTuningBarSize end,
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.width or 100)
        end,
        set = function(_, val)
          local cfg = GetSelectedConfig()
          local num = tonumber(val)
          if cfg and num then
            cfg.display.width = num
            RefreshBar()
          end
        end,
      },
      barHeight = {
        type = "range",
        name = "Bar Height",
        min = 1, max = 400, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.height or 20
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.height = value
            RefreshBar()
          end
        end,
        order = 13,
        width = 1.0,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or IsChargeBar() or collapsedSections.barSize or ns._fineTuningBarSize end
      },
      barHeightInput = {
        type = "input",
        name = "Bar Height",
        desc = "Type exact pixel value",
        order = 13,
        width = 0.4,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or IsChargeBar() or collapsedSections.barSize or not ns._fineTuningBarSize end,
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.height or 20)
        end,
        set = function(_, val)
          local cfg = GetSelectedConfig()
          local num = tonumber(val)
          if cfg and num then
            cfg.display.height = num
            RefreshBar()
          end
        end,
      },
      barOpacity = {
        type = "range",
        name = "Bar Opacity",
        min = 0, max = 1, step = 0.05,
        isPercent = true,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.opacity or 1.0
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.opacity = value
            RefreshBar()
          end
        end,
        order = 14,
        width = 1.0,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.barSize end
      },
      
      -- Charge bar specific: Slot Height
      slotHeight = {
        type = "range",
        name = "Slot Height",
        desc = "Height of individual charge slots (charge bars only)",
        min = 4, max = 40, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.slotHeight or 14
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.slotHeight = value
            RefreshBar()
          end
        end,
        order = 15,
        width = 1.0,
        hidden = function() return GetSelectedConfig() == nil or not IsChargeBar() or collapsedSections.barSize end
      },
      
      -- Charge bar specific: Slot Spacing
      slotSpacing = {
        type = "range",
        name = "Slot Spacing",
        desc = "Gap between charge slots (charge bars only)",
        min = 0, max = 20, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.slotSpacing or 3
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.slotSpacing = value
            RefreshBar()
          end
        end,
        order = 15.1,
        width = 1.0,
        hidden = function() return GetSelectedConfig() == nil or not IsChargeBar() or collapsedSections.barSize end
      },
      
      -- Charge bar specific: Slot X Offset (position slots within frame)
      slotOffsetX = {
        type = "range",
        name = "Slot X Offset",
        desc = "Horizontal offset for slot positioning (charge bars only)",
        min = -100, max = 100, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.slotOffsetX or 0
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.slotOffsetX = value
            RefreshBar()
          end
        end,
        order = 15.2,
        width = 1.0,
        hidden = function() return GetSelectedConfig() == nil or not IsChargeBar() or collapsedSections.barSize end
      },
      
      -- Charge bar specific: Slot Y Offset (position slots within frame)
      slotOffsetY = {
        type = "range",
        name = "Slot Y Offset",
        desc = "Vertical offset for slot positioning (positive = up, negative = down)",
        min = -50, max = 50, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.slotOffsetY or 0
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.slotOffsetY = value
            RefreshBar()
          end
        end,
        order = 15.3,
        width = 1.0,
        hidden = function() return GetSelectedConfig() == nil or not IsChargeBar() or collapsedSections.barSize end
      },
      
      -- ============================================================
      -- FILL
      -- ============================================================
      fillHeader = {
        type = "toggle",
        name = "Fill",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.fill end,
        set = function(info, value) collapsedSections.fill = not value end,
        order = 20,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() end
      },
      barOrientation = {
        type = "select",
        name = "Orientation",
        desc = "Bar orientation: Horizontal or Vertical",
        values = GetBarOrientations,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.barOrientation or "horizontal"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barOrientation = value
            RefreshBar()
          end
        end,
        order = 21,
        width = 0.65,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.fill end
      },
      barFillMode = {
        type = "select",
        name = "Fill Mode",
        desc = "Drain: bar shrinks as time passes. Fill: bar grows as time passes.",
        values = GetFillModes,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationBarFillMode or "drain"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationBarFillMode = value
            RefreshBar()
          end
        end,
        order = 21.5,
        width = 0.55,
        hidden = function()
          if GetSelectedConfig() == nil or IsIconMode() or collapsedSections.fill then return true end
          if not IsDurationBar() then return true end  -- Only show for duration bars
          return false
        end
      },
      barReverseFill = {
        type = "toggle",
        name = "Reverse",
        desc = "Reverse fill direction (right-to-left for horizontal, top-to-bottom for vertical)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.barReverseFill
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barReverseFill = value
            RefreshBar()
          end
        end,
        order = 21.6,
        width = 0.5,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.fill end
      },
      barTexture = {
        type = "select",
        name = "Bar Texture",
        values = GetStatusBarTextures,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.texture or "Blizzard"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.texture = value
            RefreshBar()
          end
        end,
        order = 22,
        width = 1.2,  -- Fits "Blizzard Raid Bar"
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.fill end
      },
      enableSmoothing = {
        type = "toggle",
        name = "Smooth Fill",
        desc = "Smoothly animate bar fill changes",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.enableSmoothing
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.enableSmoothing = value
            UpdateBar()
          end
        end,
        order = 23,
        width = 0.7,
        hidden = function()
          if IsIconMode() or collapsedSections.fill then return true end
          if IsDurationBar() then return true end  -- Hide for duration bars
          if IsCooldownBar() then return true end  -- Hide for cooldown charge bars
          return GetSelectedConfig() == nil
        end
      },
      -- GRADIENT OPTIONS
      useGradient = {
        type = "toggle",
        name = "Gradient",
        desc = "Apply a gradient effect to bar fill (darker/lighter edges)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.useGradient
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.useGradient = value
            RefreshBar()
          end
        end,
        order = 23.1,
        width = 0.55,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.fill end
      },
      gradientDirection = {
        type = "select",
        name = "Direction",
        desc = "Direction of the gradient effect",
        values = {
          ["VERTICAL"] = "Vertical",
          ["HORIZONTAL"] = "Horizontal"
        },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.gradientDirection or "VERTICAL"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.gradientDirection = value
            RefreshBar()
          end
        end,
        order = 23.2,
        width = 0.55,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or IsIconMode() or collapsedSections.fill or not cfg.display.useGradient
        end
      },
      gradientSecondColor = {
        type = "color",
        name = "Gradient End",
        desc = "Second color for gradient (typically darker or lighter)",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.gradientSecondColor then
            local c = cfg.display.gradientSecondColor
            return c.r, c.g, c.b, c.a or 0.5
          end
          return 0, 0, 0, 0.5
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.gradientSecondColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 23.3,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or IsIconMode() or collapsedSections.fill or not cfg.display.useGradient
        end
      },
      gradientIntensity = {
        type = "range",
        name = "Intensity",
        desc = "How strong the gradient effect is (0 = none, 1 = full blend to second color)",
        min = 0, max = 1, step = 0.05,
        isPercent = true,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.gradientIntensity or 0.5
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.gradientIntensity = value
            RefreshBar()
          end
        end,
        order = 23.4,
        width = 0.55,
        hidden = function()
          local cfg = GetSelectedConfig()
          return not cfg or IsIconMode() or collapsedSections.fill or not cfg.display.useGradient
        end
      },
      barColorPrimary = {
        type = "color",
        name = "Bar Color",
        hasAlpha = true,
        get = function()
          local cfg, barType = GetSelectedConfig()
          if barType == "buff" then
            if cfg and cfg.display.barColor then
              local c = cfg.display.barColor
              return c.r, c.g, c.b, c.a or 1
            end
            return 0, 0.5, 1, 1
          else
            -- Resource bar - use first threshold color
            if cfg and cfg.thresholds and cfg.thresholds[1] then
              local c = cfg.thresholds[1].color
              return c.r, c.g, c.b, c.a or 1
            end
            return 0, 0.8, 1, 1
          end
        end,
        set = function(info, r, g, b, a)
          local cfg, barType = GetSelectedConfig()
          if cfg then
            if barType == "buff" then
              cfg.display.barColor = {r=r, g=g, b=b, a=a}
              -- Also update thresholds[1] for perStack/fragmented modes
              if not cfg.thresholds then cfg.thresholds = {} end
              if not cfg.thresholds[1] then
                local maxVal = cfg.tracking.maxStacks or 10
                cfg.thresholds[1] = { enabled = true, minValue = 0, maxValue = maxVal }
              end
              cfg.thresholds[1].color = {r=r, g=g, b=b, a=a}
            else
              if not cfg.thresholds then cfg.thresholds = {} end
              if not cfg.thresholds[1] then
                cfg.thresholds[1] = { enabled = true, minValue = 0, maxValue = 100 }
              end
              cfg.thresholds[1].color = {r=r, g=g, b=b, a=a}
            end
            RefreshBar()
          end
        end,
        order = 23,
        width = 0.6,
        -- Hide this one - we use the one under Color Options header instead
        hidden = function() return true end
      },
      
      -- ============================================================
      -- COLOR OPTIONS (unified section)
      -- ============================================================
      colorOptionsHeader = {
        type = "toggle",
        name = "Color Options",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.colorOptions end,
        set = function(info, value) collapsedSections.colorOptions = not value end,
        order = 30,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() end
      },
      
      -- Display Style Dropdown
      displayStyle = {
        type = "select",
        name = "Style",
        desc = "How the bar fills and displays",
        values = function()
          local cfg, barType = GetSelectedConfig()
          local vals = {
            ["continuous"] = "Continuous",
            ["segmented"] = "Segmented"
          }
          -- Add Fragmented and Icons options for runes/essence
          if barType == "resource" and cfg and cfg.tracking then
            local secType = cfg.tracking.secondaryType
            if secType == "runes" or secType == "essence" then
              vals["fragmented"] = "Fragmented"
              vals["icons"] = "Icons"
            end
          end
          return vals
        end,
        sorting = {"continuous", "segmented", "fragmented", "icons"},
        get = function()
          local cfg = GetSelectedConfig()
          if cfg then
            if cfg.display.thresholdMode == "perStack" then
              return "segmented"
            elseif cfg.display.thresholdMode == "fragmented" then
              return "fragmented"
            elseif cfg.display.thresholdMode == "icons" then
              return "icons"
            end
          end
          return "continuous"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if value == "segmented" then
              cfg.display.thresholdMode = "perStack"
              local maxStacks = cfg.tracking.maxStacks or 10
              if not cfg.colorRanges then
                cfg.colorRanges = {
                  [1] = { from = 1, to = maxStacks, color = cfg.display.barColor or {r=0, g=0.5, b=1, a=1} },
                  [2] = { enabled = false, from = 5, to = math.min(8, maxStacks), color = {r=1, g=1, b=0, a=1} },
                  [3] = { enabled = false, from = 9, to = maxStacks, color = {r=0, g=1, b=0, a=1} }
                }
              end
              ApplyColorRanges(cfg)
            elseif value == "fragmented" then
              cfg.display.thresholdMode = "fragmented"
              -- Initialize default colors if not set
              if not cfg.display.fragmentedColors then
                cfg.display.fragmentedColors = {}
              end
            elseif value == "icons" then
              cfg.display.thresholdMode = "icons"
              -- Initialize icons settings if not set
              if not cfg.display.fragmentedColors then
                cfg.display.fragmentedColors = {}
              end
              if not cfg.display.iconsPositions then
                cfg.display.iconsPositions = {}
              end
            else
              if cfg.display.thresholdMode == "perStack" or cfg.display.thresholdMode == "fragmented" or cfg.display.thresholdMode == "icons" then
                cfg.display.thresholdMode = "simple"
              end
            end
            UpdateBar()
          end
        end,
        order = 30.1,
        width = 0.65,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() or IsChargeBar() or IsCooldownDurationBar() then return true end  -- Hide for duration bars and charge bars
          local cfg = GetSelectedConfig()
          if not cfg then return true end
          local maxVal = cfg.tracking.maxValue or cfg.tracking.maxStacks or 10
          return maxVal > 30
        end
      },
      
      -- Fragmented Spacing (show after Style when fragmented)
      fragmentedSpacing = {
        type = "range",
        name = "Gap",
        desc = "Space between each segment",
        min = 0, max = 50, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.fragmentedSpacing or 2
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.fragmentedSpacing = value
            RefreshBar()
          end
        end,
        order = 30.15,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      
      -- ============================================================
      -- ICONS MODE SETTINGS (for Runes/Essence as individual icons)
      -- ============================================================
      iconsLayoutMode = {
        type = "select",
        name = "Layout",
        desc = "How icons are arranged",
        values = {
          ["row"] = "Row",
          ["freeform"] = "Freeform"
        },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconsMode or "row"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconsMode = value
            UpdateBar()
          end
        end,
        order = 30.16,
        width = 0.5,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "icons"
        end
      },
      iconsSize = {
        type = "range",
        name = "Icon Size",
        min = 8, max = 128, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconsSize or 32
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconsSize = value
            RefreshBar()
          end
        end,
        order = 30.17,
        width = 0.5,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "icons"
        end
      },
      iconsSpacing = {
        type = "range",
        name = "Spacing",
        desc = "Space between icons (Row mode)",
        min = 0, max = 50, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconsSpacing or 4
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconsSpacing = value
            RefreshBar()
          end
        end,
        order = 30.18,
        width = 0.4,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "icons" or cfg.display.iconsMode == "freeform"
        end
      },
      iconsShowCooldownText = {
        type = "toggle",
        name = "CD Text",
        desc = "Show cooldown time on each icon",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconsShowCooldownText
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconsShowCooldownText = value
            RefreshBar()
          end
        end,
        order = 30.19,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "icons"
        end
      },
      iconsResetPositions = {
        type = "execute",
        name = "Reset Positions",
        desc = "Reset all icons to default positions (Freeform mode)",
        func = function()
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconsPositions = {}
            RefreshBar()
          end
        end,
        order = 30.195,
        width = 0.6,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "icons" or cfg.display.iconsMode ~= "freeform"
        end
      },
      iconsBreak = {
        type = "description",
        name = "",
        order = 30.199,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "icons"
        end
      },
      
      -- Base Color (for non-charge bars) / Recharge Color (for charge bars)
      barColor = {
        type = "color",
        name = function()
          if IsChargeBar() then
            return "Bar Color"
          end
          return "Base Bar Color"
        end,
        desc = function()
          if IsChargeBar() then
            return "Color of the charge bars (both recharging and full unless 'Different Full Color' is enabled)"
          end
          return "Primary bar color"
        end,
        hasAlpha = true,
        get = function()
          local cfg, barType = GetSelectedConfig()
          if barType == "resource" then
            -- Resource bar - use first threshold color
            if cfg and cfg.thresholds and cfg.thresholds[1] then
              local c = cfg.thresholds[1].color
              return c.r, c.g, c.b, c.a or 1
            end
            return 0, 0.8, 1, 1
          else
            -- Buff bar, Cooldown bar, or Charge bar
            if cfg and cfg.display.barColor then
              local c = cfg.display.barColor
              return c.r, c.g, c.b, c.a or 1
            end
            if barType == "charge" then
              return 0.6, 0.5, 0.2, 1  -- Default gold for charge bars
            end
            return 0, 0.5, 1, 1
          end
        end,
        set = function(info, r, g, b, a)
          local cfg, barType = GetSelectedConfig()
          if cfg then
            if barType == "resource" then
              -- Resource bar - update threshold[1] color
              if not cfg.thresholds then cfg.thresholds = {} end
              if not cfg.thresholds[1] then
                cfg.thresholds[1] = { enabled = true, minValue = 0, maxValue = 100 }
              end
              cfg.thresholds[1].color = {r=r, g=g, b=b, a=a}
            else
              -- Buff bar, Cooldown bar, or Charge bar
              cfg.display.barColor = {r=r, g=g, b=b, a=a}
              -- Also update thresholds[1] for perStack/fragmented modes
              if not cfg.thresholds then cfg.thresholds = {} end
              if not cfg.thresholds[1] then
                local maxVal = cfg.tracking.maxStacks or 10
                cfg.thresholds[1] = { enabled = true, minValue = 0, maxValue = maxVal }
              end
              cfg.thresholds[1].color = {r=r, g=g, b=b, a=a}
            end
            if cfg.colorRanges and cfg.colorRanges[1] then
              cfg.colorRanges[1].color = {r=r, g=g, b=b, a=a}
            end
            if cfg.display.thresholdMode == "perStack" then
              ApplyColorRanges(cfg)
            end
            RefreshBar()  -- Use RefreshBar to apply appearance changes including colors
          end
        end,
        order = 30.2,
        width = 0.7,
        hidden = function()
          if GetSelectedConfig() == nil or IsIconMode() or collapsedSections.colorOptions then return true end
          -- Hide for charge bars when per-slot colors is enabled
          if IsChargeBar() then
            local cfg = GetSelectedConfig()
            if cfg and cfg.display and cfg.display.usePerSlotColors then
              return true
            end
          end
          return false
        end
      },
      
      -- Per-Slot Colors toggle (Charge bars only - right of barColor)
      usePerSlotColors = {
        type = "toggle",
        name = "Per-Slot",
        desc = "Use different colors for each charge slot's fill texture",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.usePerSlotColors
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.usePerSlotColors = value
            RefreshBar()
          end
        end,
        order = 30.21,
        width = 0.5,
        hidden = function() return GetSelectedConfig() == nil or not IsChargeBar() or collapsedSections.colorOptions end
      },
      chargeSlot1Color = {
        type = "color",
        name = "1",
        desc = "Fill color for charge slot 1",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.chargeSlot1Color then
            local c = cfg.display.chargeSlot1Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.8, 0.2, 0.2, 1  -- Default red
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.chargeSlot1Color = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.22,
        width = 0.25,
        hidden = function()
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or not cfg.display.usePerSlotColors or collapsedSections.colorOptions
        end
      },
      chargeSlot2Color = {
        type = "color",
        name = "2",
        desc = "Fill color for charge slot 2",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.chargeSlot2Color then
            local c = cfg.display.chargeSlot2Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.8, 0.8, 0.2, 1  -- Default yellow
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.chargeSlot2Color = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.23,
        width = 0.25,
        hidden = function()
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or not cfg.display.usePerSlotColors or collapsedSections.colorOptions
        end
      },
      chargeSlot3Color = {
        type = "color",
        name = "3",
        desc = "Fill color for charge slot 3",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.chargeSlot3Color then
            local c = cfg.display.chargeSlot3Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.2, 0.8, 0.2, 1  -- Default green
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.chargeSlot3Color = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.24,
        width = 0.25,
        hidden = function()
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or not cfg.display.usePerSlotColors or collapsedSections.colorOptions
        end
      },
      chargeSlot4Color = {
        type = "color",
        name = "4",
        desc = "Fill color for charge slot 4",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.chargeSlot4Color then
            local c = cfg.display.chargeSlot4Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.2, 0.6, 0.8, 1  -- Default cyan
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.chargeSlot4Color = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.25,
        width = 0.25,
        hidden = function()
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or not cfg.display.usePerSlotColors or collapsedSections.colorOptions
        end
      },
      chargeSlot5Color = {
        type = "color",
        name = "5",
        desc = "Fill color for charge slot 5",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.chargeSlot5Color then
            local c = cfg.display.chargeSlot5Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.6, 0.2, 0.8, 1  -- Default purple
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.chargeSlot5Color = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.26,
        width = 0.25,
        hidden = function()
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or not cfg.display.usePerSlotColors or collapsedSections.colorOptions
        end
      },
      colorOptionsLineBreak1 = {
        type = "description",
        name = "",
        order = 30.9,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.colorOptions end
      },
      
      -- Toggle for different full charge color (Charge bars only)
      useDifferentFullColor = {
        type = "toggle",
        name = "Different Full Color",
        desc = "Use a different color when a charge is fully available",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.useDifferentFullColor
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.useDifferentFullColor = value
            RefreshBar()
          end
        end,
        order = 30.91,
        width = 0.8,
        hidden = function() return GetSelectedConfig() == nil or not IsChargeBar() or collapsedSections.colorOptions end
      },
      
      -- Full Charge Color (Charge bars only, when toggle enabled)
      fullChargeColor = {
        type = "color",
        name = "Full Charge Color",
        desc = "Color when a charge is fully available",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.fullChargeColor then
            local c = cfg.display.fullChargeColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.8, 0.6, 0.2, 1  -- Default brighter gold
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.fullChargeColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.92,
        width = 0.7,
        hidden = function()
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or not cfg.display.useDifferentFullColor or collapsedSections.colorOptions
        end
      },
      
      -- MAX COLOR
      enableMaxColor = {
        type = "toggle",
        name = "At Max",
        desc = "Use a different color when at maximum value",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.enableMaxColor
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.enableMaxColor = value
            RefreshBar()
          end
        end,
        order = 31,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() or IsChargeBar() or IsCooldownDurationBar() then return true end  -- Hide for duration bars and charge bars
          return GetSelectedConfig() == nil
        end
      },
      maxColor = {
        type = "color",
        name = "Max Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.maxColor then
            local c = cfg.display.maxColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 0, 1, 0, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.maxColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 31.1,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() or IsChargeBar() or IsCooldownDurationBar() then return true end  -- Hide for duration bars and charge bars
          local cfg = GetSelectedConfig()
          if not cfg then return true end
          return not cfg.display.enableMaxColor
        end
      },
      
      -- FOLDED COLORS
      enableFolded = {
        type = "toggle",
        name = "Folded",
        desc = "Bar shows half max value, second color after midpoint",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.thresholdMode == "folded"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if value then
              cfg.display.thresholdMode = "folded"
              cfg.display.colorCurveEnabled = false  -- Folded and Thresholds are mutually exclusive
            else
              cfg.display.thresholdMode = "simple"
            end
            UpdateBar()
          end
        end,
        order = 32,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() or IsChargeBar() or IsCooldownDurationBar() then return true end  -- Hide for duration bars and charge bars
          local cfg = GetSelectedConfig()
          if not cfg then return true end
          return cfg.display.thresholdMode == "perStack"
        end
      },
      foldedColor1 = {
        type = "color",
        name = "Half 1",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.foldedColor1 then
            local c = cfg.display.foldedColor1
            return c.r, c.g, c.b, c.a or 1
          end
          return 0, 0.5, 1, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.foldedColor1 = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 32.1,
        width = 0.35,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          if not cfg then return true end
          return cfg.display.thresholdMode ~= "folded"
        end
      },
      foldedColor2 = {
        type = "color",
        name = "Half 2",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.foldedColor2 then
            local c = cfg.display.foldedColor2
            return c.r, c.g, c.b, c.a or 1
          end
          return 0, 1, 0, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.foldedColor2 = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 32.2,
        width = 0.35,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          if not cfg then return true end
          return cfg.display.thresholdMode ~= "folded"
        end
      },
      
      -- THRESHOLD COLORS (uses ColorCurve API for secret-safe color changes)
      enableThresholds = {
        type = "toggle",
        name = "Thresholds",
        desc = "Change bar color at different value thresholds (uses WoW's ColorCurve API, works with any resource including mana)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.colorCurveEnabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveEnabled = value
            if value then
              cfg.display.thresholdMode = "colorCurve"
            else
              -- Restore to folded if it was folded before, otherwise simple
              if not cfg.display.thresholdMode or cfg.display.thresholdMode == "colorCurve" then
                cfg.display.thresholdMode = "simple"
              end
            end
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33,
        width = 0.6,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end  -- Hide for duration bars
          local cfg = GetSelectedConfig()
          if not cfg then return true end
          if cfg.display.thresholdMode == "perStack" then return true end
          return false
        end
      },
      thresholdAsPercent = {
        type = "toggle",
        name = "As %",
        desc = "Interpret threshold values as percentages of max instead of raw values",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.colorCurveThresholdAsPercent
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThresholdAsPercent = value
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.01,
        width = 0.4,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled
        end
      },
      thresholdLineBreak = {
        type = "description",
        name = "",
        order = 33.06,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled
        end
      },
      threshold2Enable = {
        type = "toggle",
        name = "At",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.colorCurveThreshold2Enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold2Enabled = value
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.1,
        width = 0.25,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled
        end
      },
      threshold2Min = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.colorCurveThreshold2Value or 75)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold2Value = tonumber(value) or 75
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.2,
        width = 0.2,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled or not cfg.display.colorCurveThreshold2Enabled
        end
      },
      threshold2Color = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.colorCurveThreshold2Color then
            local c = cfg.display.colorCurveThreshold2Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 1, 0, 1  -- Yellow default
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold2Color = {r=r, g=g, b=b, a=a}
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.3,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled or not cfg.display.colorCurveThreshold2Enabled
        end
      },
      threshold3Enable = {
        type = "toggle",
        name = "At",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.colorCurveThreshold3Enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold3Enabled = value
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.4,
        width = 0.25,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled
        end
      },
      threshold3Min = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.colorCurveThreshold3Value or 50)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold3Value = tonumber(value) or 50
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.5,
        width = 0.2,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled or not cfg.display.colorCurveThreshold3Enabled
        end
      },
      threshold3Color = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.colorCurveThreshold3Color then
            local c = cfg.display.colorCurveThreshold3Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 0.5, 0, 1  -- Orange default
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold3Color = {r=r, g=g, b=b, a=a}
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.6,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled or not cfg.display.colorCurveThreshold3Enabled
        end
      },
      threshold4Enable = {
        type = "toggle",
        name = "At",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.colorCurveThreshold4Enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold4Enabled = value
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.7,
        width = 0.25,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled
        end
      },
      threshold4Min = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.colorCurveThreshold4Value or 25)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold4Value = tonumber(value) or 25
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.8,
        width = 0.2,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled or not cfg.display.colorCurveThreshold4Enabled
        end
      },
      threshold4Color = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.colorCurveThreshold4Color then
            local c = cfg.display.colorCurveThreshold4Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 0, 0, 1  -- Red default
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold4Color = {r=r, g=g, b=b, a=a}
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 33.9,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled or not cfg.display.colorCurveThreshold4Enabled
        end
      },
      threshold5Enable = {
        type = "toggle",
        name = "At",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.colorCurveThreshold5Enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold5Enabled = value
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 34.0,
        width = 0.25,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled
        end
      },
      threshold5Min = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.colorCurveThreshold5Value or 10)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold5Value = tonumber(value) or 10
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 34.1,
        width = 0.2,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled or not cfg.display.colorCurveThreshold5Enabled
        end
      },
      threshold5Color = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.colorCurveThreshold5Color then
            local c = cfg.display.colorCurveThreshold5Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.5, 0, 0.5, 1  -- Purple default
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.colorCurveThreshold5Color = {r=r, g=g, b=b, a=a}
            ns.Resources.ClearAllResourceColorCurves()
            RefreshBar()
          end
        end,
        order = 34.2,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          if IsDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or not cfg.display.colorCurveEnabled or not cfg.display.colorCurveThreshold5Enabled
        end
      },
      
      -- ============================================================
      -- FRAGMENTED MODE COLORS (inside Color Options, after Style)
      -- ============================================================
      fragmentedColorHeader = {
        type = "description",
        name = "|cff888888Segment Colors (Ready):|r",
        order = 30.31,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      -- Segment 1 color
      fragColor1 = {
        type = "color",
        name = "1",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.fragmentedColors and cfg.display.fragmentedColors[1] then
            local c = cfg.display.fragmentedColors[1]
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.77, 0.12, 0.23, 1  -- Default DK rune red
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.display.fragmentedColors then cfg.display.fragmentedColors = {} end
            cfg.display.fragmentedColors[1] = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.32,
        width = 0.22,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      -- Segment 2 color
      fragColor2 = {
        type = "color",
        name = "2",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.fragmentedColors and cfg.display.fragmentedColors[2] then
            local c = cfg.display.fragmentedColors[2]
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.77, 0.12, 0.23, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.display.fragmentedColors then cfg.display.fragmentedColors = {} end
            cfg.display.fragmentedColors[2] = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.33,
        width = 0.22,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      -- Segment 3 color
      fragColor3 = {
        type = "color",
        name = "3",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.fragmentedColors and cfg.display.fragmentedColors[3] then
            local c = cfg.display.fragmentedColors[3]
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.77, 0.12, 0.23, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.display.fragmentedColors then cfg.display.fragmentedColors = {} end
            cfg.display.fragmentedColors[3] = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.34,
        width = 0.22,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      -- Segment 4 color
      fragColor4 = {
        type = "color",
        name = "4",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.fragmentedColors and cfg.display.fragmentedColors[4] then
            local c = cfg.display.fragmentedColors[4]
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.77, 0.12, 0.23, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.display.fragmentedColors then cfg.display.fragmentedColors = {} end
            cfg.display.fragmentedColors[4] = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.35,
        width = 0.22,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      -- Segment 5 color
      fragColor5 = {
        type = "color",
        name = "5",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.fragmentedColors and cfg.display.fragmentedColors[5] then
            local c = cfg.display.fragmentedColors[5]
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.77, 0.12, 0.23, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.display.fragmentedColors then cfg.display.fragmentedColors = {} end
            cfg.display.fragmentedColors[5] = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.36,
        width = 0.22,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not cfg or cfg.display.thresholdMode ~= "fragmented" then return true end
          -- Only show 5th for DK (6 runes) or Evoker (5 essence)
          local secType = cfg.tracking and cfg.tracking.secondaryType
          return not (secType == "runes" or secType == "essence")
        end
      },
      -- Segment 6 color (DK only)
      fragColor6 = {
        type = "color",
        name = "6",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.fragmentedColors and cfg.display.fragmentedColors[6] then
            local c = cfg.display.fragmentedColors[6]
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.77, 0.12, 0.23, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.display.fragmentedColors then cfg.display.fragmentedColors = {} end
            cfg.display.fragmentedColors[6] = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.37,
        width = 0.22,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not cfg or cfg.display.thresholdMode ~= "fragmented" then return true end
          -- Only show 6th for DK (6 runes)
          local secType = cfg.tracking and cfg.tracking.secondaryType
          return secType ~= "runes"
        end
      },
      fragmentedColorLineBreak = {
        type = "description",
        name = "",
        order = 30.38,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      fragmentedChargingColor = {
        type = "color",
        name = "Charging",
        desc = "Color for segments that are recharging (not yet ready)",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.fragmentedChargingColor then
            local c = cfg.display.fragmentedChargingColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.4, 0.4, 0.4, 1  -- Default gray
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.fragmentedChargingColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 30.39,
        width = 0.5,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      fragmentedShowSegmentText = {
        type = "toggle",
        name = "CD Text",
        desc = "Show cooldown text on each segment",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.fragmentedShowSegmentText
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.fragmentedShowSegmentText = value
            RefreshBar()
          end
        end,
        order = 30.391,
        width = 0.45,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      fragmentedTextSize = {
        type = "range",
        name = "Size",
        min = 4, max = 48, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.fragmentedTextSize or 10
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.fragmentedTextSize = value
            RefreshBar()
          end
        end,
        order = 30.392,
        width = 0.4,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented" or not cfg.display.fragmentedShowSegmentText
        end
      },
      fragmentedEndBreak = {
        type = "description",
        name = "",
        order = 30.393,
        hidden = function()
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      
      -- ============================================================
      -- DURATION BAR THRESHOLDS (only for duration mode bars)
      -- Matches stack threshold UI pattern with "At" toggles
      -- 100% uses Base Bar Color, thresholds 2-5 are optional
      -- ============================================================
      durationThresholdHeader = {
        type = "description",
        name = "\n",
        order = 33.7,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          return false
        end
      },
      
      -- ColorCurve Enable Toggle
      durationColorCurveEnabled = {
        type = "toggle",
        name = "Conditional Color",
        desc = "Change bar color based on remaining time. 100% uses Base Bar Color.",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationColorCurveEnabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationColorCurveEnabled = value
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 33.72,
        width = 0.75,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          return false
        end
      },
      
      -- As % vs Seconds toggle
      durationThresholdAsSeconds = {
        type = "toggle",
        name = "As Sec",
        desc = "Interpret threshold values as seconds instead of percentages",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationThresholdAsSeconds
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThresholdAsSeconds = value
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 33.73,
        width = 0.45,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.durationColorCurveEnabled)
        end
      },
      
      -- Max Duration Input (only shown when As Sec is enabled)
      durationThresholdMaxDuration = {
        type = "input",
        name = "Max",
        desc = "Maximum duration in seconds (required for seconds mode)",
        dialogControl = "ArcUI_EditBox",
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationThresholdMaxDuration and cfg.display.durationThresholdMaxDuration > 0 then
            return tostring(cfg.display.durationThresholdMaxDuration)
          end
          return ""
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            local num = tonumber(value)
            cfg.display.durationThresholdMaxDuration = num and num > 0 and num or nil
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 33.74,
        width = 0.35,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.durationColorCurveEnabled) then return true end
          return not cfg.display.durationThresholdAsSeconds
        end
      },
      
      durationThresholdLineBreak1 = {
        type = "description",
        name = "",
        order = 33.75,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.durationColorCurveEnabled)
        end
      },
      
      -- Threshold 2
      durationThreshold2Enable = {
        type = "toggle",
        name = "At",
        desc = "Enable threshold 2",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationThreshold2Enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold2Enabled = value
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 33.90,
        width = 0.25,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.durationColorCurveEnabled)
        end
      },
      durationThreshold2Value = {
        type = "input",
        name = "",
        desc = "Trigger this color when remaining time falls below this value",
        dialogControl = "ArcUI_EditBox",
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationThreshold2Value then
            return tostring(cfg.display.durationThreshold2Value)
          end
          return "75"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold2Value = tonumber(value) or 75
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 33.91,
        width = 0.2,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.durationColorCurveEnabled) then return true end
          return not cfg.display.durationThreshold2Enabled
        end
      },
      durationThreshold2Color = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationThreshold2Color then
            local c = cfg.display.durationThreshold2Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.8, 0.8, 0, 1  -- Default yellow
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold2Color = {r=r, g=g, b=b, a=a}
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 33.92,
        width = 0.35,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.durationColorCurveEnabled) then return true end
          return not cfg.display.durationThreshold2Enabled
        end
      },
      
      -- Threshold 3
      durationThreshold3Enable = {
        type = "toggle",
        name = "At",
        desc = "Enable threshold 3",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationThreshold3Enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold3Enabled = value
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 34.00,
        width = 0.25,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.durationColorCurveEnabled)
        end
      },
      durationThreshold3Value = {
        type = "input",
        name = "",
        desc = "Trigger this color when remaining time falls below this value",
        dialogControl = "ArcUI_EditBox",
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationThreshold3Value then
            return tostring(cfg.display.durationThreshold3Value)
          end
          return "50"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold3Value = tonumber(value) or 50
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 34.01,
        width = 0.2,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.durationColorCurveEnabled) then return true end
          return not cfg.display.durationThreshold3Enabled
        end
      },
      durationThreshold3Color = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationThreshold3Color then
            local c = cfg.display.durationThreshold3Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 0.5, 0, 1  -- Default orange
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold3Color = {r=r, g=g, b=b, a=a}
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 34.02,
        width = 0.35,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.durationColorCurveEnabled) then return true end
          return not cfg.display.durationThreshold3Enabled
        end
      },
      
      -- Threshold 4
      durationThreshold4Enable = {
        type = "toggle",
        name = "At",
        desc = "Enable threshold 4",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationThreshold4Enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold4Enabled = value
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 34.10,
        width = 0.25,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.durationColorCurveEnabled)
        end
      },
      durationThreshold4Value = {
        type = "input",
        name = "",
        desc = "Trigger this color when remaining time falls below this value",
        dialogControl = "ArcUI_EditBox",
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationThreshold4Value then
            return tostring(cfg.display.durationThreshold4Value)
          end
          return "25"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold4Value = tonumber(value) or 25
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 34.11,
        width = 0.2,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.durationColorCurveEnabled) then return true end
          return not cfg.display.durationThreshold4Enabled
        end
      },
      durationThreshold4Color = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationThreshold4Color then
            local c = cfg.display.durationThreshold4Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 0.3, 0, 1  -- Default red-orange
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold4Color = {r=r, g=g, b=b, a=a}
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 34.12,
        width = 0.35,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.durationColorCurveEnabled) then return true end
          return not cfg.display.durationThreshold4Enabled
        end
      },
      
      -- Threshold 5 (lowest - critical)
      durationThreshold5Enable = {
        type = "toggle",
        name = "At",
        desc = "Enable threshold 5 (critical)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationThreshold5Enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold5Enabled = value
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 34.20,
        width = 0.25,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.durationColorCurveEnabled)
        end
      },
      durationThreshold5Value = {
        type = "input",
        name = "",
        desc = "Trigger this color when remaining time falls below this value (critical)",
        dialogControl = "ArcUI_EditBox",
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationThreshold5Value then
            return tostring(cfg.display.durationThreshold5Value)
          end
          return "10"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold5Value = tonumber(value) or 10
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 34.21,
        width = 0.2,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.durationColorCurveEnabled) then return true end
          return not cfg.display.durationThreshold5Enabled
        end
      },
      durationThreshold5Color = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationThreshold5Color then
            local c = cfg.display.durationThreshold5Color
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 0, 0, 1  -- Default red
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationThreshold5Color = {r=r, g=g, b=b, a=a}
            ClearSelectedBarColorCurve()
            RefreshBar()
          end
        end,
        order = 34.22,
        width = 0.35,
        hidden = function()
          if not IsDurationBar() then return true end
          if IsIconMode() then return true end
          if collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.durationColorCurveEnabled) then return true end
          return not cfg.display.durationThreshold5Enabled
        end
      },
      
      -- OLD DURATION THRESHOLDS (Removed - keeping for reference)
      -- Duration Threshold 2 (DISABLED)
      durThreshold2Enable = {
        type = "toggle",
        name = "When <=",
        desc = "Change color when time remaining is at or below this value",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.thresholds and cfg.thresholds[2] and cfg.thresholds[2].enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.thresholds then cfg.thresholds = {} end
            if not cfg.thresholds[2] then cfg.thresholds[2] = { enabled = false, minValue = 10, color = {r=1, g=1, b=0, a=1} } end
            cfg.thresholds[2].enabled = value
            UpdateBar()
          end
        end,
        order = 33.72,
        width = 0.45,
        hidden = function()
          return true  -- Duration thresholds removed
        end
      },
      durThreshold2Value = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "",
        desc = "Time in seconds",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.thresholds and cfg.thresholds[2] and cfg.thresholds[2].minValue or 10)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and cfg.thresholds and cfg.thresholds[2] then
            cfg.thresholds[2].minValue = tonumber(value) or 10
            UpdateBar()
          end
        end,
        order = 33.74,
        width = 0.2,
        hidden = function() return true end  -- Duration thresholds removed
      },
      durThreshold2Sec = {
        type = "description",
        name = "sec",
        order = 33.75,
        width = 0.15,
        hidden = function() return true end  -- Duration thresholds removed
      },
      durThreshold2Color = {
        type = "color",
        name = "",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.thresholds and cfg.thresholds[2] and cfg.thresholds[2].color then
            local c = cfg.thresholds[2].color
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 1, 0, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg and cfg.thresholds and cfg.thresholds[2] then
            cfg.thresholds[2].color = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 33.76,
        width = 0.25,
        hidden = function() return true end  -- Duration thresholds removed
      },
      
      -- Duration Threshold 3
      durThreshold3Enable = {
        type = "toggle",
        name = "When <=",
        desc = "Change color when time remaining is at or below this value (higher priority)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.thresholds and cfg.thresholds[3] and cfg.thresholds[3].enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.thresholds then cfg.thresholds = {} end
            if not cfg.thresholds[3] then cfg.thresholds[3] = { enabled = false, minValue = 5, color = {r=1, g=0, b=0, a=1} } end
            cfg.thresholds[3].enabled = value
            UpdateBar()
          end
        end,
        order = 33.77,
        width = 0.45,
        hidden = function() return true end  -- Duration thresholds removed
      },
      durThreshold3Value = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "",
        desc = "Time in seconds",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.thresholds and cfg.thresholds[3] and cfg.thresholds[3].minValue or 5)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and cfg.thresholds and cfg.thresholds[3] then
            cfg.thresholds[3].minValue = tonumber(value) or 5
            UpdateBar()
          end
        end,
        order = 33.79,
        width = 0.2,
        hidden = function() return true end  -- Duration thresholds removed
      },
      durThreshold3Sec = {
        type = "description",
        name = "sec",
        order = 33.791,
        width = 0.15,
        hidden = function() return true end  -- Duration thresholds removed
      },
      durThreshold3Color = {
        type = "color",
        name = "",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.thresholds and cfg.thresholds[3] and cfg.thresholds[3].color then
            local c = cfg.thresholds[3].color
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 0, 0, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg and cfg.thresholds and cfg.thresholds[3] then
            cfg.thresholds[3].color = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 33.792,
        width = 0.25,
        hidden = function() return true end  -- Duration thresholds removed
      },
      
      -- COLOR RANGES (segmented)
      colorRangesHeader = {
        type = "description",
        name = "|cffffd700Color Ranges|r |cff888888(color by stack range)|r",
        order = 34,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      range1Label = {
        type = "description",
        name = "Range 1:",
        order = 34.1,
        width = 0.45,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      range1From = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "From",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.colorRanges and cfg.colorRanges[1] and cfg.colorRanges[1].from or 1)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.colorRanges then cfg.colorRanges = {} end
            if not cfg.colorRanges[1] then cfg.colorRanges[1] = { from = 1, to = 4, color = {r=0, g=0.5, b=1, a=1} } end
            cfg.colorRanges[1].from = tonumber(value) or 1
            ApplyColorRanges(cfg)
            UpdateBar()
          end
        end,
        order = 34.11,
        width = 0.25,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      range1To = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "To",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.colorRanges and cfg.colorRanges[1] and cfg.colorRanges[1].to or 4)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.colorRanges then cfg.colorRanges = {} end
            if not cfg.colorRanges[1] then cfg.colorRanges[1] = { from = 1, to = 4, color = {r=0, g=0.5, b=1, a=1} } end
            cfg.colorRanges[1].to = tonumber(value) or 4
            ApplyColorRanges(cfg)
            UpdateBar()
          end
        end,
        order = 34.12,
        width = 0.2,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      range1Color = {
        type = "color",
        name = "",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.colorRanges and cfg.colorRanges[1] and cfg.colorRanges[1].color then
            local c = cfg.colorRanges[1].color
            return c.r, c.g, c.b, c.a or 1
          end
          return 0, 0.5, 1, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.colorRanges then cfg.colorRanges = {} end
            if not cfg.colorRanges[1] then cfg.colorRanges[1] = { from = 1, to = 4, color = {r=0, g=0.5, b=1, a=1} } end
            cfg.colorRanges[1].color = {r=r, g=g, b=b, a=a}
            ApplyColorRanges(cfg)
            RefreshBar()
          end
        end,
        order = 34.13,
        width = 0.25,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      range2Enable = {
        type = "toggle",
        name = "Range 2:",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.colorRanges and cfg.colorRanges[2] and cfg.colorRanges[2].enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.colorRanges then cfg.colorRanges = {} end
            if not cfg.colorRanges[2] then cfg.colorRanges[2] = { enabled = false, from = 5, to = 8, color = {r=1, g=1, b=0, a=1} } end
            cfg.colorRanges[2].enabled = value
            ApplyColorRanges(cfg)
            UpdateBar()
          end
        end,
        order = 34.2,
        width = 0.45,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      range2From = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "From",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.colorRanges and cfg.colorRanges[2] and cfg.colorRanges[2].from or 5)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and cfg.colorRanges and cfg.colorRanges[2] then
            cfg.colorRanges[2].from = tonumber(value) or 5
            ApplyColorRanges(cfg)
            UpdateBar()
          end
        end,
        order = 34.21,
        width = 0.25,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack" or not (cfg.colorRanges and cfg.colorRanges[2] and cfg.colorRanges[2].enabled)
        end
      },
      range2To = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "To",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.colorRanges and cfg.colorRanges[2] and cfg.colorRanges[2].to or 8)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and cfg.colorRanges and cfg.colorRanges[2] then
            cfg.colorRanges[2].to = tonumber(value) or 8
            ApplyColorRanges(cfg)
            UpdateBar()
          end
        end,
        order = 34.22,
        width = 0.2,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack" or not (cfg.colorRanges and cfg.colorRanges[2] and cfg.colorRanges[2].enabled)
        end
      },
      range2Color = {
        type = "color",
        name = "",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.colorRanges and cfg.colorRanges[2] and cfg.colorRanges[2].color then
            local c = cfg.colorRanges[2].color
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 1, 0, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg and cfg.colorRanges and cfg.colorRanges[2] then
            cfg.colorRanges[2].color = {r=r, g=g, b=b, a=a}
            ApplyColorRanges(cfg)
            RefreshBar()
          end
        end,
        order = 34.23,
        width = 0.25,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack" or not (cfg.colorRanges and cfg.colorRanges[2] and cfg.colorRanges[2].enabled)
        end
      },
      range3Enable = {
        type = "toggle",
        name = "Range 3:",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.colorRanges and cfg.colorRanges[3] and cfg.colorRanges[3].enabled
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.colorRanges then cfg.colorRanges = {} end
            if not cfg.colorRanges[3] then cfg.colorRanges[3] = { enabled = false, from = 9, to = 12, color = {r=0, g=1, b=0, a=1} } end
            cfg.colorRanges[3].enabled = value
            ApplyColorRanges(cfg)
            UpdateBar()
          end
        end,
        order = 34.3,
        width = 0.45,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      range3From = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "From",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.colorRanges and cfg.colorRanges[3] and cfg.colorRanges[3].from or 9)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and cfg.colorRanges and cfg.colorRanges[3] then
            cfg.colorRanges[3].from = tonumber(value) or 9
            ApplyColorRanges(cfg)
            UpdateBar()
          end
        end,
        order = 34.31,
        width = 0.25,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack" or not (cfg.colorRanges and cfg.colorRanges[3] and cfg.colorRanges[3].enabled)
        end
      },
      range3To = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "To",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.colorRanges and cfg.colorRanges[3] and cfg.colorRanges[3].to or 12)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and cfg.colorRanges and cfg.colorRanges[3] then
            cfg.colorRanges[3].to = tonumber(value) or 12
            ApplyColorRanges(cfg)
            UpdateBar()
          end
        end,
        order = 34.32,
        width = 0.2,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack" or not (cfg.colorRanges and cfg.colorRanges[3] and cfg.colorRanges[3].enabled)
        end
      },
      range3Color = {
        type = "color",
        name = "",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.colorRanges and cfg.colorRanges[3] and cfg.colorRanges[3].color then
            local c = cfg.colorRanges[3].color
            return c.r, c.g, c.b, c.a or 1
          end
          return 0, 1, 0, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg and cfg.colorRanges and cfg.colorRanges[3] then
            cfg.colorRanges[3].color = {r=r, g=g, b=b, a=a}
            ApplyColorRanges(cfg)
            RefreshBar()
          end
        end,
        order = 34.33,
        width = 0.25,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack" or not (cfg.colorRanges and cfg.colorRanges[3] and cfg.colorRanges[3].enabled)
        end
      },
      
      -- PER STACK OVERRIDE
      perStackHeader = {
        type = "description",
        name = "|cffffd700Per Stack Override|r |cff888888(override individual stack colors)|r",
        order = 35,
        hidden = function()
          if IsIconMode() then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      perStackSelector = {
        type = "select",
        name = "Stack #",
        style = "dropdown",
        values = function()
          local cfg = GetSelectedConfig()
          local maxStacks = cfg and cfg.tracking.maxStacks or 10
          local values = {}
          for i = 1, maxStacks do
            values[i] = tostring(i)
          end
          return values
        end,
        get = function()
          return ns.selectedPerStack or 1
        end,
        set = function(info, value)
          ns.selectedPerStack = value
        end,
        order = 35.1,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      perStackColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          local stackNum = ns.selectedPerStack or 1
          if cfg and cfg.stackColors and cfg.stackColors[stackNum] then
            local c = cfg.stackColors[stackNum]
            return c.r, c.g, c.b, c.a or 1
          end
          return 0, 0.5, 1, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            local stackNum = ns.selectedPerStack or 1
            if not cfg.stackColors then cfg.stackColors = {} end
            cfg.stackColors[stackNum] = {r=r, g=g, b=b, a=a}
            UpdateBar()
          end
        end,
        order = 35.2,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.colorOptions then return true end
          local cfg = GetSelectedConfig()
          return not cfg or cfg.display.thresholdMode ~= "perStack"
        end
      },
      
      -- ============================================================
      -- BACKGROUND (collapsible)
      -- ============================================================
      backgroundHeader = {
        type = "toggle",
        name = "Background",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.background end,
        set = function(info, value) collapsedSections.background = not value end,
        order = 40,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() end
      },
      
      -- FRAME BACKGROUND
      showBackground = {
        type = "toggle",
        name = "Show Frame Background",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showBackground
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showBackground = value
            RefreshBar()
          end
        end,
        order = 41,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.background end
      },
      backgroundTexture = {
        type = "select",
        name = "Texture",
        values = GetBackgroundTextures,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.backgroundTexture or "Solid"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.backgroundTexture = value
            RefreshBar()
          end
        end,
        order = 41.1,
        width = 1.0,
        hidden = function()
          if IsIconMode() or collapsedSections.background then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showBackground)
        end
      },
      backgroundColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.backgroundColor then
            local c = cfg.display.backgroundColor
            return c.r, c.g, c.b, c.a
          end
          return 0, 0, 0, 0.5
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.backgroundColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 41.2,
        width = 0.5,
        hidden = function()
          if IsIconMode() or collapsedSections.background then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showBackground)
        end
      },
      -- Frame Width (only for charge bars when showBackground is enabled)
      frameWidth = {
        type = "range",
        name = "Frame Width",
        desc = "Width of the outer frame/background",
        min = 50, max = 800, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.frameWidth or 200
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.frameWidth = value
            RefreshBar()
          end
        end,
        order = 41.3,
        width = 1.0,
        hidden = function()
          if IsIconMode() or collapsedSections.background then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showBackground) or not IsChargeBar()
        end
      },
      -- Frame Height (only for charge bars when showBackground is enabled)
      frameHeight = {
        type = "range",
        name = "Frame Height",
        desc = "Height of the outer frame/background",
        min = 20, max = 400, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.frameHeight or 38
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.frameHeight = value
            RefreshBar()
          end
        end,
        order = 41.4,
        width = 1.0,
        hidden = function()
          if IsIconMode() or collapsedSections.background then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showBackground) or not IsChargeBar()
        end
      },
      
      -- SLOT BACKGROUND (Charge bars only)
      showSlotBackground = {
        type = "toggle",
        name = "Show Slot Background",
        desc = "Show background on each charge slot (charge bars only)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showSlotBackground ~= false  -- Default true
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showSlotBackground = value
            RefreshBar()
          end
        end,
        order = 42,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or not IsChargeBar() or collapsedSections.background end
      },
      slotBackgroundTexture = {
        type = "select",
        name = "Texture",
        desc = "Texture for charge slot backgrounds",
        values = GetBackgroundTextures,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.slotBackgroundTexture or "Solid"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.slotBackgroundTexture = value
            RefreshBar()
          end
        end,
        order = 42.1,
        width = 1.0,
        hidden = function()
          if collapsedSections.background then return true end
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or cfg.display.showSlotBackground == false
        end
      },
      slotBackgroundColor = {
        type = "color",
        name = "Color",
        desc = "Background color of charge slots",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.slotBackgroundColor then
            local c = cfg.display.slotBackgroundColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.08, 0.08, 0.08, 1  -- Default dark
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.slotBackgroundColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 42.2,
        width = 0.5,
        hidden = function()
          if collapsedSections.background then return true end
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or cfg.display.showSlotBackground == false
        end
      },
      
      -- ============================================================
      -- BORDER
      -- ============================================================
      borderHeader = {
        type = "toggle",
        name = "Border",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.border end,
        set = function(info, value) collapsedSections.border = not value end,
        order = 50,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() end
      },
      
      -- FRAME BORDER
      showBorder = {
        type = "toggle",
        name = "Show Frame Border",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showBorder
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showBorder = value
            RefreshBar()
          end
        end,
        order = 51,
        width = "full",
        hidden = function()
          if IsIconMode() or collapsedSections.border then return true end
          -- Hide for cooldown duration bars (they use bar border instead)
          if IsCooldownDurationBar() then return true end
          return GetSelectedConfig() == nil
        end
      },
      useClassColorBorder = {
        type = "toggle",
        name = "Class Color",
        desc = "Use your class color for the border",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.useClassColorBorder
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.useClassColorBorder = value
            RefreshBar()
          end
        end,
        order = 51.1,
        width = 0.55,
        hidden = function()
          if IsIconMode() or collapsedSections.border then return true end
          if IsCooldownDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showBorder)
        end
      },
      borderColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.borderColor then
            local c = cfg.display.borderColor
            return c.r, c.g, c.b, c.a
          end
          return 0, 0, 0, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.borderColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 51.2,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.border then return true end
          if IsCooldownDurationBar() then return true end
          local cfg = GetSelectedConfig()
          -- Hide if border not shown OR if class color is enabled
          return not (cfg and cfg.display.showBorder) or (cfg and cfg.display.useClassColorBorder)
        end
      },
      borderThickness = {
        type = "range",
        name = "Thickness",
        min = 1, max = 20, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.drawnBorderThickness or 2
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.drawnBorderThickness = value
            RefreshBar()
          end
        end,
        order = 51.3,
        width = 0.7,
        hidden = function()
          if IsIconMode() or collapsedSections.border then return true end
          if IsCooldownDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showBorder)
        end
      },
      
      -- BAR BORDER (border around the actual bar fill, not the frame)
      showBarBorder = {
        type = "toggle",
        name = "Show Bar Border",
        desc = "Draw a border around the actual bar (not the frame)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showBarBorder
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showBarBorder = value
            RefreshBar()
          end
        end,
        order = 52,
        width = "full",
        hidden = function()
          if IsIconMode() or collapsedSections.border then return true end
          -- Only show for cooldown duration bars
          return not IsCooldownDurationBar()
        end
      },
      barBorderColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.barBorderColor then
            local c = cfg.display.barBorderColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 0, 0, 0, 1  -- Default black
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barBorderColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 52.1,
        width = 0.5,
        hidden = function()
          if IsIconMode() or collapsedSections.border then return true end
          if not IsCooldownDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showBarBorder)
        end
      },
      barBorderThickness = {
        type = "range",
        name = "Thickness",
        min = 1, max = 10, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.barBorderThickness or 1
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barBorderThickness = value
            RefreshBar()
          end
        end,
        order = 52.2,
        width = 0.5,
        hidden = function()
          if IsIconMode() or collapsedSections.border then return true end
          if not IsCooldownDurationBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showBarBorder)
        end
      },
      
      -- SLOT BORDER (Charge bars only)
      showSlotBorder = {
        type = "toggle",
        name = "Show Slot Border",
        desc = "Show border on each charge slot (charge bars only)",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showSlotBorder
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showSlotBorder = value
            RefreshBar()
          end
        end,
        order = 52,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or not IsChargeBar() or collapsedSections.border end
      },
      slotBorderColor = {
        type = "color",
        name = "Color",
        desc = "Border color of charge slots",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.slotBorderColor then
            local c = cfg.display.slotBorderColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 0, 0, 0, 1  -- Default black
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.slotBorderColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 52.1,
        width = 0.45,
        hidden = function()
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or not cfg.display.showSlotBorder or collapsedSections.border
        end
      },
      slotBorderThickness = {
        type = "range",
        name = "Thickness",
        desc = "Thickness of charge slot borders",
        min = 1, max = 10, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.slotBorderThickness or 1
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.slotBorderThickness = value
            RefreshBar()
          end
        end,
        order = 52.2,
        width = 0.7,
        hidden = function()
          local cfg = GetSelectedConfig()
          return cfg == nil or not IsChargeBar() or not cfg.display.showSlotBorder or collapsedSections.border
        end
      },
      
      -- ============================================================
      -- FRAME STRATA (controls layering/visibility)
      -- ============================================================
      strataHeader = {
        type = "toggle",
        name = "Frame Strata",
        desc = "Click to expand/collapse. Controls which UI elements appear on top of others.",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.frameStrata end,
        set = function(info, value) collapsedSections.frameStrata = not value end,
        order = 54,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() end
      },
      barFrameStrata = {
        type = "select",
        name = "Bar Strata",
        desc = "Frame strata for the entire bar frame.\n\nBACKGROUND - Lowest layer\nLOW - Above background\nMEDIUM - Default UI level\nHIGH - Above most UI\nDIALOG - Dialog level\nFULLSCREEN - Fullscreen elements\nFULLSCREEN_DIALOG - Above fullscreen\nTOOLTIP - Highest layer",
        values = {
          ["BACKGROUND"] = "BACKGROUND",
          ["LOW"] = "LOW",
          ["MEDIUM"] = "MEDIUM",
          ["HIGH"] = "HIGH",
          ["DIALOG"] = "DIALOG",
          ["FULLSCREEN"] = "FULLSCREEN",
          ["FULLSCREEN_DIALOG"] = "FULLSCREEN_DIALOG",
          ["TOOLTIP"] = "TOOLTIP",
        },
        sorting = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.barFrameStrata or "HIGH"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barFrameStrata = value
            RefreshBar()
          end
        end,
        order = 54.1,
        width = 1.0,
        hidden = function()
          return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.frameStrata
        end
      },
      barFrameLevel = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Bar Level",
        desc = "Frame level within the strata (1-500). Higher = on top.",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.barFrameLevel or 10)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            local num = tonumber(value)
            if num and num >= 1 and num <= 500 then
              cfg.display.barFrameLevel = num
              RefreshBar()
            end
          end
        end,
        order = 54.2,
        width = 0.5,
        hidden = function()
          return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.frameStrata
        end
      },
      
      -- ============================================================
      -- TICK MARKS / DIVIDERS
      -- ============================================================
      tickHeader = {
        type = "toggle",
        name = "Tick Marks / Dividers",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.tickMarks end,
        set = function(info, value) collapsedSections.tickMarks = not value end,
        order = 60,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or IsChargeBar() end  -- Hide for charge bars
      },
      enableTickMarks = {
        type = "toggle",
        name = "Enable Tick Marks",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showTickMarks
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showTickMarks = value
            if value and not cfg.display.tickMode then
              cfg.display.tickMode = "all"
            end
            RefreshBar()
          end
        end,
        order = 61,
        width = 0.9,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or IsChargeBar() or collapsedSections.tickMarks end  -- Hide for charge bars
      },
      maxTicksInput = {
        type = "input",
        name = "Max (Ticks)",
        desc = "Maximum duration for tick mark positioning (seconds). This determines where tick marks are placed on the bar.",
        dialogControl = "ArcUI_EditBox",
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.tracking then
            local val = cfg.tracking.maxDuration
            return val and val > 0 and tostring(val) or ""
          end
          return ""
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and cfg.tracking then
            local numValue = tonumber(value)
            if numValue and numValue > 0 then
              cfg.tracking.maxDuration = numValue
              RefreshBar()
            end
          end
        end,
        order = 61.1,
        width = 0.7,
        hidden = function()
          if IsIconMode() or collapsedSections.tickMarks then return true end
          return not IsDurationBar()
        end
      },
      tickAllMode = {
        type = "toggle",
        name = "All",
        desc = "Show tick marks for every stack division",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.tickMode == "all"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and value then
            cfg.display.tickMode = "all"
            RefreshBar()
          end
        end,
        order = 61.5,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.tickMarks then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showTickMarks)
        end
      },
      tickPercentMode = {
        type = "toggle",
        name = "Per %",
        desc = "Show tick marks at percentage intervals",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.tickMode == "percent"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and value then
            cfg.display.tickMode = "percent"
            if not cfg.display.tickPercent then
              cfg.display.tickPercent = 10
            end
            RefreshBar()
          end
        end,
        order = 62,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.tickMarks then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showTickMarks)
        end
      },
      tickPercentValue = {
        type = "select",
        name = "",
        desc = "Tick interval percentage",
        values = {
          [1] = "1%",
          [2] = "2%",
          [5] = "5%",
          [10] = "10%",
          [20] = "20%",
          [25] = "25%",
          [50] = "50%"
        },
        sorting = {1, 2, 5, 10, 20, 25, 50},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.tickPercent or 10
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.tickPercent = value
            RefreshBar()
          end
        end,
        order = 62.5,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.tickMarks then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showTickMarks and cfg.display.tickMode == "percent")
        end
      },
      enableCustomTicks = {
        type = "toggle",
        name = "Custom",
        desc = "Define specific tick positions for ability costs",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.tickMode == "custom"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg and value then
            cfg.display.tickMode = "custom"
            RefreshBar()
          end
        end,
        order = 63,
        width = 0.55,
        hidden = function()
          if IsIconMode() or collapsedSections.tickMarks then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showTickMarks)
        end
      },
      customTicksAsPercent = {
        type = "toggle",
        name = "As %",
        desc = "Interpret custom tick values as percentages instead of actual values",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.customTicksAsPercent
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.customTicksAsPercent = value
            RefreshBar()
          end
        end,
        order = 63.5,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.tickMarks then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showTickMarks and cfg.display.tickMode == "custom")
        end
      },
      tickColor = {
        type = "color",
        name = "Tick Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.tickColor then
            local c = cfg.display.tickColor
            return c.r, c.g, c.b, c.a
          end
          return 1, 1, 1, 0.8
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.tickColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 64,
        width = 0.6,
        hidden = function()
          if IsIconMode() or collapsedSections.tickMarks then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showTickMarks)
        end
      },
      tickThickness = {
        type = "range",
        name = "Tick Thickness",
        min = 1, max = 20, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.tickThickness or 2
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.tickThickness = value
            RefreshBar()
          end
        end,
        order = 65,
        width = 1.0,
        hidden = function()
          if IsIconMode() or collapsedSections.tickMarks then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showTickMarks)
        end
      },
      customTickValues = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Custom Tick Values",
        desc = "Comma-separated values (e.g., 30, 50, 80)",
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.abilityThresholds then
            local positions = {}
            for _, tick in ipairs(cfg.abilityThresholds) do
              if tick.enabled then
                table.insert(positions, tostring(tick.cost))
              end
            end
            return table.concat(positions, ", ")
          end
          return ""
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.abilityThresholds = {}
            for num in string.gmatch(value, "(%d+)") do
              local cost = tonumber(num)
              if cost and cost > 0 then
                table.insert(cfg.abilityThresholds, { enabled = true, name = "Tick", cost = cost })
              end
            end
            RefreshBar()
          end
        end,
        order = 66,
        width = 1.2,
        hidden = function()
          if IsIconMode() or collapsedSections.tickMarks then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showTickMarks and cfg.display.tickMode == "custom")
        end
      },
      
      -- ============================================================
      -- STACK TEXT
      -- ============================================================
      textHeader = {
        type = "toggle",
        name = function()
          return IsResourceBar() and "Resource Text" or "Stack Text"
        end,
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.stackText end,
        set = function(info, value) collapsedSections.stackText = not value end,
        order = 70,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() end
      },
      showText = {
        type = "toggle",
        name = function()
          return IsResourceBar() and "Show Text" or "Show Stack Text"
        end,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showText
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showText = value
            RefreshBar()
          end
        end,
        order = 71,
        width = 0.9,  -- Fits "Show Stack Text"
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.stackText end
      },
      textFormat = {
        type = "select",
        name = "Display As",
        desc = "Value shows the raw number (e.g. 45000). Percentage shows as percent (e.g. 72%).",
        values = {
          ["value"] = "Value",
          ["percent"] = "Percentage",
        },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.textFormat or "value"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.textFormat = value
            RefreshBar()
          end
        end,
        order = 71.5,
        width = 0.7,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          if not IsResourceBar() then return true end
          local cfg = GetSelectedConfig()
          if not cfg or not cfg.display.showText then return true end
          -- Hide for secondary resources (percentage doesn't make sense for 5 combo points)
          return cfg.tracking and cfg.tracking.resourceCategory == "secondary"
        end
      },
      textColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.textColor then
            local c = cfg.display.textColor
            return c.r, c.g, c.b, c.a
          end
          return 1, 1, 1, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.textColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 72,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showText)
        end
      },
      font = {
        type = "select",
        name = "Font",
        values = GetFonts,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.font or "2002 Bold"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.font = value
            RefreshBar()
          end
        end,
        order = 73,
        width = 1.0,  -- Fits font names like "Friz Quadrata TT"
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showText)
        end
      },
      fontSize = {
        type = "range",
        name = "Size",
        min = 4, max = 128, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.fontSize or 20
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.fontSize = value
            RefreshBar()
          end
        end,
        order = 74,
        width = 1.0,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showText)
        end
      },
      textOutline = {
        type = "select",
        name = "Outline",
        values = { NONE = "None", OUTLINE = "Thin", THICKOUTLINE = "Thick" },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.textOutline or "THICKOUTLINE"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.textOutline = value
            RefreshBar()
          end
        end,
        order = 74.1,
        width = 0.55,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showText)
        end
      },
      textShadow = {
        type = "toggle",
        name = "Shadow",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.textShadow
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.textShadow = value
            RefreshBar()
          end
        end,
        order = 74.2,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showText)
        end
      },
      textAnchor = {
        type = "select",
        name = "Text Anchor",
        desc = "Anchor text to bar position, or FREE for independent placement",
        values = {
          ["FREE"] = "Free (Movable)",
          ["CENTER"] = "Center",
          ["CENTERLEFT"] = "Center Left",
          ["CENTERRIGHT"] = "Center Right",
          ["TOP"] = "Top",
          ["BOTTOM"] = "Bottom",
          ["LEFT"] = "Left",
          ["RIGHT"] = "Right",
          ["TOPLEFT"] = "Top Left",
          ["TOPRIGHT"] = "Top Right",
          ["BOTTOMLEFT"] = "Bottom Left",
          ["BOTTOMRIGHT"] = "Bottom Right",
          ["OUTERTOP"] = "Outer Top",
          ["OUTERBOTTOM"] = "Outer Bottom",
          ["OUTERLEFT"] = "Outer Left",
          ["OUTERRIGHT"] = "Outer Right",
          ["OUTERCENTERLEFT"] = "Outer Center Left",
          ["OUTERCENTERRIGHT"] = "Outer Center Right",
          ["OUTERTOPLEFT"] = "Outer Top Left",
          ["OUTERTOPRIGHT"] = "Outer Top Right",
          ["OUTERBOTTOMLEFT"] = "Outer Bottom Left",
          ["OUTERBOTTOMRIGHT"] = "Outer Bottom Right"
        },
        sorting = {
          "FREE", 
          "CENTER", "CENTERLEFT", "CENTERRIGHT",
          "TOP", "BOTTOM", "LEFT", "RIGHT", 
          "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT",
          "OUTERTOP", "OUTERBOTTOM", "OUTERLEFT", "OUTERRIGHT",
          "OUTERCENTERLEFT", "OUTERCENTERRIGHT",
          "OUTERTOPLEFT", "OUTERTOPRIGHT", "OUTERBOTTOMLEFT", "OUTERBOTTOMRIGHT"
        },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.textAnchor or "OUTERTOP"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.textAnchor = value
            -- When switching to FREE mode, enable text movable
            -- When switching to anchored mode, disable text movable
            if value == "FREE" then
              cfg.display.textMovable = true
            else
              cfg.display.textMovable = false
            end
            -- Reset offsets to 0 when anchor changes
            cfg.display.textAnchorOffsetX = 0
            cfg.display.textAnchorOffsetY = 0
            RefreshBar()
          end
        end,
        order = 74.5,
        width = 0.9,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          if IsChargeBar() or IsCooldownDurationBar() then return true end  -- Hide for charge/duration bars (use Charge Text Anchor)
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showText)
        end
      },
      textAnchorOffsetX = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "X Offset",
        desc = "Horizontal offset from anchor point",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.textAnchorOffsetX or 0)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.textAnchorOffsetX = tonumber(value) or 0
            RefreshBar()
          end
        end,
        order = 74.6,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          if IsChargeBar() or IsCooldownDurationBar() then return true end  -- Hide for charge/duration bars
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showText and cfg.display.textAnchor ~= "FREE")
        end
      },
      textAnchorOffsetY = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Y Offset",
        desc = "Vertical offset from anchor point",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.textAnchorOffsetY or 0)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.textAnchorOffsetY = tonumber(value) or 0
            RefreshBar()
          end
        end,
        order = 74.7,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          if IsChargeBar() or IsCooldownDurationBar() then return true end  -- Hide for charge/duration bars
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showText and cfg.display.textAnchor ~= "FREE")
        end
      },
      textMovable = {
        type = "toggle",
        name = "Text Movable",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.textMovable
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.textMovable = value
            RefreshBar()
          end
        end,
        order = 75,
        width = 0.7,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          if IsChargeBar() or IsCooldownDurationBar() then return true end  -- Hide for charge/duration bars
          local cfg = GetSelectedConfig()
          -- Hide when text anchor is not FREE
          return not (cfg and cfg.display.showText and (cfg.display.textAnchor == "FREE" or cfg.display.textAnchor == nil))
        end
      },
      
      -- Charge bar specific: Show max value (/2)
      showMaxText = {
        type = "toggle",
        name = "Show Max",
        desc = "Show the maximum charges (e.g. '/2' in '2/2')",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showMaxText ~= false  -- Default true
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showMaxText = value
            RefreshBar()
          end
        end,
        order = 75.1,
        width = 0.6,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          return not IsChargeBar() and not IsCooldownDurationBar()
        end
      },
      
      -- Charge bar specific: Charge text anchor
      chargeTextAnchor = {
        type = "select",
        name = "Charge Text Anchor",
        desc = "Position of the charge count text (e.g. 2/2). FREE allows dragging (charge bars only).",
        values = function()
          -- FREE only available for charge bars, not duration bars
          if IsCooldownDurationBar() then
            return {
              ["TOPRIGHT"] = "Top Right",
              ["TOPLEFT"] = "Top Left",
              ["BOTTOMRIGHT"] = "Bottom Right",
              ["BOTTOMLEFT"] = "Bottom Left",
              ["RIGHT"] = "Right",
              ["LEFT"] = "Left",
              ["CENTER"] = "Center",
            }
          else
            return {
              ["FREE"] = "Free (Draggable)",
              ["TOPRIGHT"] = "Top Right",
              ["TOPLEFT"] = "Top Left",
              ["BOTTOMRIGHT"] = "Bottom Right",
              ["BOTTOMLEFT"] = "Bottom Left",
              ["RIGHT"] = "Right",
              ["LEFT"] = "Left",
              ["CENTER"] = "Center",
            }
          end
        end,
        sorting = {"FREE", "TOPRIGHT", "TOPLEFT", "RIGHT", "LEFT", "CENTER", "BOTTOMRIGHT", "BOTTOMLEFT"},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.chargeTextAnchor or "TOPRIGHT"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.chargeTextAnchor = value
            RefreshBar()
          end
        end,
        order = 75.2,
        width = 0.75,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          return (not IsChargeBar() and not IsCooldownDurationBar()) or not (cfg and cfg.display.showText)
        end
      },
      -- Lock toggle for FREE mode charge text
      stackTextLocked = {
        type = "toggle",
        name = "Lock",
        desc = "Lock position to prevent accidental dragging",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.stackTextLocked
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.stackTextLocked = value
            RefreshBar()
          end
        end,
        order = 75.21,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          if IsCooldownDurationBar() then return true end  -- Duration bars don't support FREE mode
          local cfg = GetSelectedConfig()
          if not IsChargeBar() or not (cfg and cfg.display.showText) then return true end
          return cfg.display.chargeTextAnchor ~= "FREE"
        end
      },
      -- Stack text strata
      stackTextStrata = {
        type = "select",
        name = "Strata",
        desc = "Frame strata for charge/stack text. Higher strata appears above lower strata.",
        values = {
          ["BACKGROUND"] = "BACKGROUND",
          ["LOW"] = "LOW",
          ["MEDIUM"] = "MEDIUM",
          ["HIGH"] = "HIGH",
          ["DIALOG"] = "DIALOG",
          ["TOOLTIP"] = "TOOLTIP",
        },
        sorting = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP"},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.stackTextStrata or cfg.display.barFrameStrata or "HIGH"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.stackTextStrata = value
            RefreshBar()
          end
        end,
        order = 75.22,
        width = 0.6,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          -- Show for any bar with text enabled
          return not (cfg and cfg.display.showText)
        end
      },
      -- Stack text level
      stackTextLevel = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Level",
        desc = "Frame level (1-500). Text is 3 levels higher than bar by default.",
        get = function()
          local cfg = GetSelectedConfig()
          local barLevel = cfg and cfg.display.barFrameLevel or 10
          return tostring(cfg and cfg.display.stackTextLevel or (barLevel + 3))
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            local num = tonumber(value)
            if num and num >= 1 and num <= 500 then
              cfg.display.stackTextLevel = num
              RefreshBar()
            end
          end
        end,
        order = 75.23,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          -- Show for any bar with text enabled
          return not (cfg and cfg.display.showText)
        end
      },
      -- Stack text frame width (for FREE mode)
      stackTextFrameWidth = {
        type = "range",
        name = "Frame Width",
        desc = "Width of the draggable text frame (FREE mode only).",
        min = 30, max = 200, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.stackTextFrameWidth or 80
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.stackTextFrameWidth = value
            RefreshBar()
          end
        end,
        order = 75.24,
        width = 0.7,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          if not IsChargeBar() or not (cfg and cfg.display.showText) then return true end
          return cfg.display.chargeTextAnchor ~= "FREE"
        end
      },
      
      -- Charge bar specific: Charge text X offset
      chargeTextOffsetX = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "X Offset",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.chargeTextOffsetX or -4)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.chargeTextOffsetX = tonumber(value) or -4
            RefreshBar()
          end
        end,
        order = 75.3,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          if (not IsChargeBar() and not IsCooldownDurationBar()) or not (cfg and cfg.display.showText) then return true end
          -- Hide when FREE mode (dragging handles position)
          return cfg.display.chargeTextAnchor == "FREE"
        end
      },
      
      -- Charge bar specific: Charge text Y offset
      chargeTextOffsetY = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Y Offset",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.chargeTextOffsetY or -2)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.chargeTextOffsetY = tonumber(value) or -2
            RefreshBar()
          end
        end,
        order = 75.4,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.stackText then return true end
          local cfg = GetSelectedConfig()
          if (not IsChargeBar() and not IsCooldownDurationBar()) or not (cfg and cfg.display.showText) then return true end
          -- Hide when FREE mode (dragging handles position)
          return cfg.display.chargeTextAnchor == "FREE"
        end
      },
      
      -- ============================================================
      -- DURATION TEXT
      -- ============================================================
      durationHeader = {
        type = "toggle",
        name = "Duration Text",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.durationText end,
        set = function(info, value) collapsedSections.durationText = not value end,
        order = 76,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or IsResourceBar() end
      },
      showDuration = {
        type = "toggle",
        name = "Show Duration",
        desc = "Display buff duration from CD Manager",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showDuration
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showDuration = value
            RefreshBar()
          end
        end,
        order = 76.1,
        width = 0.8,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or IsResourceBar() or collapsedSections.durationText end
      },
      showZeroWhenReady = {
        type = "toggle",
        name = "Show 0 When Ready",
        desc = "Show '0' instead of hiding duration text when spell is ready",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showZeroWhenReady
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showZeroWhenReady = value
            RefreshBar()
          end
        end,
        order = 76.15,
        width = 0.8,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() then return true end
          -- Only show for cooldown bars (cd_cooldown and cd_charge), not aura bars
          if not IsCooldownBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration)
        end
      },
      durationColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.durationColor then
            local c = cfg.display.durationColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 1, 1, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationColor = {r=r, g=g, b=b, a=a}
            UpdateBar()
          end
        end,
        order = 76.2,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration)
        end
      },
      durationFont = {
        type = "select",
        name = "Font",
        values = GetFonts,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationFont or "2002 Bold"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationFont = value
            RefreshBar()
          end
        end,
        order = 76.25,
        width = 0.8,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration)
        end
      },
      durationFontSize = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Size",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.durationFontSize or 18)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationFontSize = tonumber(value) or 18
            RefreshBar()
          end
        end,
        order = 76.3,
        width = 0.25,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration)
        end
      },
      durationOutline = {
        type = "select",
        name = "Outline",
        values = { NONE = "None", OUTLINE = "Thin", THICKOUTLINE = "Thick" },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationOutline or "THICKOUTLINE"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationOutline = value
            RefreshBar()
          end
        end,
        order = 76.31,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration)
        end
      },
      durationShadow = {
        type = "toggle",
        name = "Shadow",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationShadow
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationShadow = value
            RefreshBar()
          end
        end,
        order = 76.32,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration)
        end
      },
      durationDecimals = {
        type = "select",
        name = "Decimals",
        desc = "Round duration to X decimal places",
        values = {
          [0] = "0 (27)",
          [1] = "1 (27.4)",
          [2] = "2 (27.44)",
          [3] = "3 (27.448)"
        },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationDecimals or 1
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationDecimals = value
            RefreshBar()
          end
        end,
        order = 76.35,
        width = 0.55,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() then return true end
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration)
        end
      },
      durationAnchor = {
        type = "select",
        name = "Anchor",
        desc = "Where to anchor duration text relative to bar",
        values = {
          ["FREE"] = "Free (Movable)",
          ["CENTER"] = "Center",
          ["CENTERLEFT"] = "Center Left",
          ["CENTERRIGHT"] = "Center Right",
          ["TOP"] = "Top",
          ["BOTTOM"] = "Bottom",
          ["LEFT"] = "Left",
          ["RIGHT"] = "Right",
          ["TOPLEFT"] = "Top Left",
          ["TOPRIGHT"] = "Top Right",
          ["BOTTOMLEFT"] = "Bottom Left",
          ["BOTTOMRIGHT"] = "Bottom Right",
          ["OUTERTOP"] = "Outer Top",
          ["OUTERBOTTOM"] = "Outer Bottom",
          ["OUTERLEFT"] = "Outer Left",
          ["OUTERRIGHT"] = "Outer Right",
          ["OUTERCENTERLEFT"] = "Outer Center Left",
          ["OUTERCENTERRIGHT"] = "Outer Center Right",
          ["OUTERTOPLEFT"] = "Outer Top Left",
          ["OUTERTOPRIGHT"] = "Outer Top Right",
          ["OUTERBOTTOMLEFT"] = "Outer Bottom Left",
          ["OUTERBOTTOMRIGHT"] = "Outer Bottom Right"
        },
        sorting = {
          "FREE", 
          "CENTER", "CENTERLEFT", "CENTERRIGHT",
          "TOP", "BOTTOM", "LEFT", "RIGHT", 
          "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT",
          "OUTERTOP", "OUTERBOTTOM", "OUTERLEFT", "OUTERRIGHT",
          "OUTERCENTERLEFT", "OUTERCENTERRIGHT",
          "OUTERTOPLEFT", "OUTERTOPRIGHT", "OUTERBOTTOMLEFT", "OUTERBOTTOMRIGHT"
        },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationAnchor or "CENTER"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationAnchor = value
            cfg.display.durationAnchorOffsetX = 0
            cfg.display.durationAnchorOffsetY = 0
            RefreshBar()
          end
        end,
        order = 76.4,
        width = 0.9,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() or IsChargeBar() then return true end  -- Hide for resource/charge bars only
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration)
        end
      },
      durationAnchorOffsetX = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "X Offset",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.durationAnchorOffsetX or 0)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationAnchorOffsetX = tonumber(value) or 0
            RefreshBar()
          end
        end,
        order = 76.5,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() or IsChargeBar() then return true end  -- Hide for resource/charge bars only
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration and cfg.display.durationAnchor ~= "FREE")
        end
      },
      durationAnchorOffsetY = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Y Offset",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.durationAnchorOffsetY or 0)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationAnchorOffsetY = tonumber(value) or 0
            RefreshBar()
          end
        end,
        order = 76.6,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          if IsResourceBar() or IsChargeBar() then return true end  -- Hide for resource/charge bars only
          local cfg = GetSelectedConfig()
          return not (cfg and cfg.display.showDuration and cfg.display.durationAnchor ~= "FREE")
        end
      },
      
      -- Charge bar specific: Timer text anchor
      timerTextAnchor = {
        type = "select",
        name = "Timer Anchor",
        desc = "Position of the recharge timer text. FREE allows dragging.",
        values = {
          ["FREE"] = "Free (Draggable)",
          ["BOTTOMRIGHT"] = "Bottom Right",
          ["BOTTOMLEFT"] = "Bottom Left",
          ["TOPRIGHT"] = "Top Right",
          ["TOPLEFT"] = "Top Left",
          ["RIGHT"] = "Right",
          ["LEFT"] = "Left",
          ["CENTER"] = "Center",
        },
        sorting = {"FREE", "BOTTOMRIGHT", "BOTTOMLEFT", "RIGHT", "LEFT", "CENTER", "TOPRIGHT", "TOPLEFT"},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.timerTextAnchor or "BOTTOMRIGHT"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.timerTextAnchor = value
            -- Disable dynamic mode when manually setting anchor
            if value ~= "SLOT" then
              cfg.display.dynamicTextOnSlot = false
            end
            RefreshBar()
          end
        end,
        order = 76.7,
        width = 0.75,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          local cfg = GetSelectedConfig()
          if not IsChargeBar() or not (cfg and cfg.display.showDuration) then return true end
          -- Hide anchor selector if dynamic mode is on
          return cfg.display.dynamicTextOnSlot
        end
      },
      -- Dynamic text positioning: centers on recharging slot
      dynamicTextOnSlot = {
        type = "toggle",
        name = "Dynamic Position",
        desc = "Timer text centers on the currently recharging slot. Hides when all charges are full.",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.dynamicTextOnSlot
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.dynamicTextOnSlot = value
            RefreshBar()
          end
        end,
        order = 76.69,
        width = 0.85,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          local cfg = GetSelectedConfig()
          return not IsChargeBar() or not (cfg and cfg.display.showDuration)
        end
      },
      -- Lock toggle for FREE mode timer text
      durationTextLocked = {
        type = "toggle",
        name = "Lock",
        desc = "Lock position to prevent accidental dragging",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationTextLocked
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationTextLocked = value
            RefreshBar()
          end
        end,
        order = 76.71,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          local cfg = GetSelectedConfig()
          if not (cfg and cfg.display.showDuration) then return true end
          -- Hide if dynamic mode is on
          if IsChargeBar() and cfg.display.dynamicTextOnSlot then return true end
          -- Show for charge bars with timerTextAnchor == FREE, or cooldown duration bars with durationAnchor == FREE
          if IsChargeBar() then
            return cfg.display.timerTextAnchor ~= "FREE"
          elseif IsCooldownDurationBar() then
            return cfg.display.durationAnchor ~= "FREE"
          end
          return true
        end
      },
      -- Duration text strata
      durationTextStrata = {
        type = "select",
        name = "Strata",
        desc = "Frame strata for timer text. Higher strata appears above lower strata.",
        values = {
          ["BACKGROUND"] = "BACKGROUND",
          ["LOW"] = "LOW",
          ["MEDIUM"] = "MEDIUM",
          ["HIGH"] = "HIGH",
          ["DIALOG"] = "DIALOG",
          ["TOOLTIP"] = "TOOLTIP",
        },
        sorting = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP"},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationTextStrata or cfg.display.barFrameStrata or "HIGH"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationTextStrata = value
            RefreshBar()
          end
        end,
        order = 76.72,
        width = 0.6,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          local cfg = GetSelectedConfig()
          -- Show for any bar with duration enabled
          return not (cfg and cfg.display.showDuration)
        end
      },
      -- Duration text level
      durationTextLevel = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Level",
        desc = "Frame level (1-500). Text is 3 levels higher than bar by default.",
        get = function()
          local cfg = GetSelectedConfig()
          local barLevel = cfg and cfg.display.barFrameLevel or 10
          return tostring(cfg and cfg.display.durationTextLevel or (barLevel + 3))
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            local num = tonumber(value)
            if num and num >= 1 and num <= 500 then
              cfg.display.durationTextLevel = num
              RefreshBar()
            end
          end
        end,
        order = 76.73,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          local cfg = GetSelectedConfig()
          -- Show for any bar with duration enabled
          return not (cfg and cfg.display.showDuration)
        end
      },
      -- Duration text frame width (for FREE mode)
      durationTextFrameWidth = {
        type = "range",
        name = "Frame Width",
        desc = "Width of the draggable text frame (FREE mode only).",
        min = 30, max = 200, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.durationTextFrameWidth or 60
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.durationTextFrameWidth = value
            RefreshBar()
          end
        end,
        order = 76.74,
        width = 0.7,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          local cfg = GetSelectedConfig()
          if not IsChargeBar() or not (cfg and cfg.display.showDuration) then return true end
          return cfg.display.timerTextAnchor ~= "FREE"
        end
      },
      
      -- Charge bar specific: Timer text X offset
      timerTextOffsetX = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "X Offset",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.timerTextOffsetX or -4)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.timerTextOffsetX = tonumber(value) or -4
            RefreshBar()
          end
        end,
        order = 76.8,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          local cfg = GetSelectedConfig()
          if not IsChargeBar() or not (cfg and cfg.display.showDuration) then return true end
          -- Hide when FREE mode (dragging handles position) or dynamic mode
          return cfg.display.timerTextAnchor == "FREE" or cfg.display.dynamicTextOnSlot
        end
      },
      
      -- Charge bar specific: Timer text Y offset
      timerTextOffsetY = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Y Offset",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.timerTextOffsetY or 2)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.timerTextOffsetY = tonumber(value) or 2
            RefreshBar()
          end
        end,
        order = 76.9,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.durationText then return true end
          local cfg = GetSelectedConfig()
          if not IsChargeBar() or not (cfg and cfg.display.showDuration) then return true end
          -- Hide when FREE mode (dragging handles position) or dynamic mode
          return cfg.display.timerTextAnchor == "FREE" or cfg.display.dynamicTextOnSlot
        end
      },
      
      -- ============================================================
      -- READY TEXT (for cooldown bars only)
      -- ============================================================
      readyTextHeader = {
        type = "toggle",
        name = "Ready Text",
        desc = "Click to expand/collapse. Text shown when spell is off cooldown.",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.readyText end,
        set = function(info, value) collapsedSections.readyText = not value end,
        order = 76.95,
        width = "full",
        hidden = function()
          if IsIconMode() then return true end
          return not IsCooldownDurationBar()
        end
      },
      showReadyText = {
        type = "toggle",
        name = "Show",
        desc = "Show 'Ready' text when spell is off cooldown",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showReadyText ~= false  -- Default true
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showReadyText = value
            RefreshBar()
          end
        end,
        order = 76.96,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.readyText then return true end
          return not IsCooldownDurationBar()
        end
      },
      readyColor = {
        type = "color",
        name = "Color",
        desc = "Ready text color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.readyColor then
            local c = cfg.display.readyColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 0.3, 1, 0.3, 1  -- Default green
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.readyColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 76.97,
        width = 0.5,
        hidden = function()
          if IsIconMode() or collapsedSections.readyText then return true end
          local cfg = GetSelectedConfig()
          return not IsCooldownDurationBar() or cfg.display.showReadyText == false
        end
      },
      readyTextInput = {
        type = "input",
        name = "Text",
        desc = "Custom text to display when ready",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.readyText or "Ready"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.readyText = value
            RefreshBar()
          end
        end,
        order = 76.98,
        width = 0.6,
        hidden = function()
          if IsIconMode() or collapsedSections.readyText then return true end
          local cfg = GetSelectedConfig()
          return not IsCooldownDurationBar() or cfg.display.showReadyText == false
        end
      },
      readyTextAnchor = {
        type = "select",
        name = "Anchor",
        desc = "Position of ready text. FREE allows dragging.",
        values = {
          ["FREE"] = "Free (Draggable)",
          ["CENTER"] = "Center",
          ["LEFT"] = "Left",
          ["RIGHT"] = "Right",
          ["TOPLEFT"] = "Top Left",
          ["TOPRIGHT"] = "Top Right",
          ["BOTTOMLEFT"] = "Bottom Left",
          ["BOTTOMRIGHT"] = "Bottom Right"
        },
        sorting = {"FREE", "CENTER", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.readyTextAnchor or "RIGHT"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.readyTextAnchor = value
            cfg.display.readyTextOffsetX = 0
            cfg.display.readyTextOffsetY = 0
            RefreshBar()
          end
        end,
        order = 76.981,
        width = 0.7,
        hidden = function()
          if IsIconMode() or collapsedSections.readyText then return true end
          local cfg = GetSelectedConfig()
          return not IsCooldownDurationBar() or cfg.display.showReadyText == false
        end
      },
      readyTextOffsetX = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "X",
        desc = "X offset from anchor",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.readyTextOffsetX or 0)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.readyTextOffsetX = tonumber(value) or 0
            RefreshBar()
          end
        end,
        order = 76.982,
        width = 0.3,
        hidden = function()
          if IsIconMode() or collapsedSections.readyText then return true end
          local cfg = GetSelectedConfig()
          if not IsCooldownDurationBar() or cfg.display.showReadyText == false then return true end
          return cfg.display.readyTextAnchor == "FREE"
        end
      },
      readyTextOffsetY = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Y",
        desc = "Y offset from anchor",
        get = function()
          local cfg = GetSelectedConfig()
          return tostring(cfg and cfg.display.readyTextOffsetY or 0)
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.readyTextOffsetY = tonumber(value) or 0
            RefreshBar()
          end
        end,
        order = 76.983,
        width = 0.3,
        hidden = function()
          if IsIconMode() or collapsedSections.readyText then return true end
          local cfg = GetSelectedConfig()
          if not IsCooldownDurationBar() or cfg.display.showReadyText == false then return true end
          return cfg.display.readyTextAnchor == "FREE"
        end
      },
      readyTextLocked = {
        type = "toggle",
        name = "Lock",
        desc = "Lock position to prevent accidental dragging",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.readyTextLocked
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.readyTextLocked = value
            RefreshBar()
          end
        end,
        order = 76.984,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.readyText then return true end
          local cfg = GetSelectedConfig()
          if not IsCooldownDurationBar() or cfg.display.showReadyText == false then return true end
          return cfg.display.readyTextAnchor ~= "FREE"
        end
      },
      readyTextStrata = {
        type = "select",
        name = "Strata",
        desc = "Frame strata for ready text",
        values = {
          ["BACKGROUND"] = "Background",
          ["LOW"] = "Low",
          ["MEDIUM"] = "Medium",
          ["HIGH"] = "High",
          ["DIALOG"] = "Dialog",
          ["TOOLTIP"] = "Tooltip",
        },
        sorting = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP"},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.readyTextStrata or cfg.display.barFrameStrata or "HIGH"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.readyTextStrata = value
            RefreshBar()
          end
        end,
        order = 76.985,
        width = 0.5,
        hidden = function()
          if IsIconMode() or collapsedSections.readyText then return true end
          local cfg = GetSelectedConfig()
          return not IsCooldownDurationBar() or cfg.display.showReadyText == false
        end
      },
      readyTextLevel = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Level",
        desc = "Frame level for ready text",
        get = function()
          local cfg = GetSelectedConfig()
          local barLevel = cfg and cfg.display.barFrameLevel or 10
          return tostring(cfg and cfg.display.readyTextLevel or (barLevel + 3))
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            local num = tonumber(value)
            if num then
              cfg.display.readyTextLevel = num
              RefreshBar()
            end
          end
        end,
        order = 76.986,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.readyText then return true end
          local cfg = GetSelectedConfig()
          return not IsCooldownDurationBar() or cfg.display.showReadyText == false
        end
      },
      
      -- ============================================================
      -- NAME TEXT (for duration bars and charge bars)
      -- ============================================================
      nameHeader = {
        type = "toggle",
        name = "Name Text",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.nameText end,
        set = function(info, value) collapsedSections.nameText = not value end,
        order = 77,
        width = "full",
        hidden = function()
          if IsIconMode() then return true end
          return not IsDurationBar() and not IsChargeBar() and not IsCooldownDurationBar()
        end
      },
      showName = {
        type = "toggle",
        name = "Show",
        desc = "Show buff name text",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showName
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showName = value
            RefreshBar()
          end
        end,
        order = 77.1,
        width = 0.45,
        hidden = function()
          if IsIconMode() or collapsedSections.nameText then return true end
          return not IsDurationBar() and not IsChargeBar() and not IsCooldownDurationBar()
        end
      },
      nameColor = {
        type = "color",
        name = "Color",
        hasAlpha = true,
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.nameColor then
            local c = cfg.display.nameColor
            return c.r, c.g, c.b, c.a or 1
          end
          return 1, 1, 1, 1
        end,
        set = function(info, r, g, b, a)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.nameColor = {r=r, g=g, b=b, a=a}
            RefreshBar()
          end
        end,
        order = 77.2,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.nameText then return true end
          local cfg = GetSelectedConfig()
          local showForBarType = IsDurationBar() or IsChargeBar() or IsCooldownDurationBar()
          return not showForBarType or not (cfg and cfg.display.showName)
        end
      },
      nameFont = {
        type = "select",
        name = "Font",
        values = GetFonts,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.nameFont or "2002 Bold"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.nameFont = value
            RefreshBar()
          end
        end,
        order = 77.25,
        width = 0.8,
        hidden = function()
          if IsIconMode() or collapsedSections.nameText then return true end
          local cfg = GetSelectedConfig()
          local showForBarType = IsDurationBar() or IsChargeBar() or IsCooldownDurationBar()
          return not showForBarType or not (cfg and cfg.display.showName)
        end
      },
      nameFontSize = {
        type = "range",
        name = "Size",
        min = 4, max = 64, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.nameFontSize or 14
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.nameFontSize = value
            RefreshBar()
          end
        end,
        order = 77.3,
        width = 0.55,
        hidden = function()
          if IsIconMode() or collapsedSections.nameText then return true end
          local cfg = GetSelectedConfig()
          local showForBarType = IsDurationBar() or IsChargeBar() or IsCooldownDurationBar()
          return not showForBarType or not (cfg and cfg.display.showName)
        end
      },
      nameAnchor = {
        type = "select",
        name = "Anchor",
        desc = "Where to anchor name text relative to bar",
        values = {
          ["FREE"] = "Free (Movable)",
          ["CENTER"] = "Center",
          ["CENTERLEFT"] = "Center Left",
          ["CENTERRIGHT"] = "Center Right",
          ["TOP"] = "Top",
          ["BOTTOM"] = "Bottom",
          ["LEFT"] = "Left",
          ["RIGHT"] = "Right",
          ["TOPLEFT"] = "Top Left",
          ["TOPRIGHT"] = "Top Right",
          ["BOTTOMLEFT"] = "Bottom Left",
          ["BOTTOMRIGHT"] = "Bottom Right",
          ["OUTERTOP"] = "Outer Top",
          ["OUTERBOTTOM"] = "Outer Bottom",
          ["OUTERLEFT"] = "Outer Left",
          ["OUTERRIGHT"] = "Outer Right",
          ["OUTERCENTERLEFT"] = "Outer Center Left",
          ["OUTERCENTERRIGHT"] = "Outer Center Right",
          ["OUTERTOPLEFT"] = "Outer Top Left",
          ["OUTERTOPRIGHT"] = "Outer Top Right",
          ["OUTERBOTTOMLEFT"] = "Outer Bottom Left",
          ["OUTERBOTTOMRIGHT"] = "Outer Bottom Right"
        },
        sorting = {
          "FREE", 
          "CENTER", "CENTERLEFT", "CENTERRIGHT",
          "TOP", "BOTTOM", "LEFT", "RIGHT", 
          "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT",
          "OUTERTOP", "OUTERBOTTOM", "OUTERLEFT", "OUTERRIGHT",
          "OUTERCENTERLEFT", "OUTERCENTERRIGHT",
          "OUTERTOPLEFT", "OUTERTOPRIGHT", "OUTERBOTTOMLEFT", "OUTERBOTTOMRIGHT"
        },
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.nameAnchor or "CENTER"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.nameAnchor = value
            cfg.display.nameAnchorOffsetX = 0
            cfg.display.nameAnchorOffsetY = 0
            RefreshBar()
          end
        end,
        order = 77.4,
        width = 0.9,
        hidden = function()
          if IsIconMode() or collapsedSections.nameText then return true end
          local cfg = GetSelectedConfig()
          local showForBarType = IsDurationBar() or IsChargeBar() or IsCooldownDurationBar()
          return not showForBarType or not (cfg and cfg.display.showName)
        end
      },
      
      -- Name Offset X (charge bars only)
      nameOffsetX = {
        type = "range",
        name = "Name X Offset",
        desc = "Horizontal offset for name text (charge bars only)",
        min = -100, max = 100, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.nameOffsetX or 0
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.nameOffsetX = value
            RefreshBar()
          end
        end,
        order = 77.5,
        width = 0.8,
        hidden = function()
          if IsIconMode() or collapsedSections.nameText then return true end
          local cfg = GetSelectedConfig()
          return not IsChargeBar() or not (cfg and cfg.display.showName)
        end
      },
      
      -- Name Offset Y (charge bars only)
      nameOffsetY = {
        type = "range",
        name = "Name Y Offset",
        desc = "Vertical offset for name text (charge bars only)",
        min = -50, max = 50, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.nameOffsetY or 0
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.nameOffsetY = value
            RefreshBar()
          end
        end,
        order = 77.6,
        width = 0.8,
        hidden = function()
          if IsIconMode() or collapsedSections.nameText then return true end
          local cfg = GetSelectedConfig()
          return not IsChargeBar() or not (cfg and cfg.display.showName)
        end
      },
      
      -- Name text strata
      nameTextStrata = {
        type = "select",
        name = "Strata",
        desc = "Frame strata for name text. Higher strata appears above lower strata.",
        values = {
          ["BACKGROUND"] = "BACKGROUND",
          ["LOW"] = "LOW",
          ["MEDIUM"] = "MEDIUM",
          ["HIGH"] = "HIGH",
          ["DIALOG"] = "DIALOG",
          ["TOOLTIP"] = "TOOLTIP",
        },
        sorting = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP"},
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.nameTextStrata or cfg.display.barFrameStrata or "HIGH"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.nameTextStrata = value
            RefreshBar()
          end
        end,
        order = 77.7,
        width = 0.6,
        hidden = function()
          if IsIconMode() or collapsedSections.nameText then return true end
          local cfg = GetSelectedConfig()
          -- Show for any bar with name enabled
          return not (cfg and cfg.display.showName)
        end
      },
      -- Name text level
      nameTextLevel = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Level",
        desc = "Frame level (1-500). Text is 3 levels higher than bar by default.",
        get = function()
          local cfg = GetSelectedConfig()
          local barLevel = cfg and cfg.display.barFrameLevel or 10
          return tostring(cfg and cfg.display.nameTextLevel or (barLevel + 3))
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            local num = tonumber(value)
            if num and num >= 1 and num <= 500 then
              cfg.display.nameTextLevel = num
              RefreshBar()
            end
          end
        end,
        order = 77.8,
        width = 0.35,
        hidden = function()
          if IsIconMode() or collapsedSections.nameText then return true end
          local cfg = GetSelectedConfig()
          -- Show for any bar with name enabled
          return not (cfg and cfg.display.showName)
        end
      },
      
      -- ============================================================
      -- BAR ICON (icon alongside bar)
      -- ============================================================
      barIconHeader = {
        type = "toggle",
        name = "Bar Icon",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.barIcon end,
        set = function(info, value) collapsedSections.barIcon = not value end,
        order = 78,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or IsResourceBar() end
      },
      showBarIcon = {
        type = "toggle",
        name = "Show",
        desc = "Show tracking icon alongside bar",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.showBarIcon
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.showBarIcon = value
            RefreshBar()
          end
        end,
        order = 78.1,
        width = 0.45,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or IsResourceBar() or collapsedSections.barIcon end
      },
      barIconSize = {
        type = "range",
        name = "Size",
        min = 8, max = 128, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.barIconSize or 32
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barIconSize = value
            RefreshBar()
          end
        end,
        order = 78.2,
        width = 0.55,
        hidden = function()
          if IsResourceBar() or collapsedSections.barIcon then return true end
          local cfg = GetSelectedConfig()
          return GetSelectedConfig() == nil or IsIconMode() or not (cfg and cfg.display.showBarIcon)
        end
      },
      iconBarSpacing = {
        type = "range",
        name = "Bar Gap",
        desc = "Space between icon and fill texture",
        min = 0, max = 20, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconBarSpacing or 4
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconBarSpacing = value
            RefreshBar()
          end
        end,
        order = 78.25,
        width = 0.55,
        hidden = function()
          if IsResourceBar() or collapsedSections.barIcon then return true end
          local cfg = GetSelectedConfig()
          return GetSelectedConfig() == nil or IsIconMode() or not (cfg and cfg.display.showBarIcon)
        end
      },
      barIconAnchor = {
        type = "select",
        name = "Position",
        desc = "Icon position relative to bar",
        values = function()
          local cfg = GetSelectedConfig()
          local isVertical = cfg and cfg.display.barOrientation == "vertical"
          if isVertical then
            return {
              ["TOP"] = "Top",
              ["BOTTOM"] = "Bottom",
              ["LEFT"] = "Left",
              ["RIGHT"] = "Right"
            }
          else
            return {
              ["LEFT"] = "Left",
              ["RIGHT"] = "Right",
              ["TOP"] = "Top",
              ["BOTTOM"] = "Bottom"
            }
          end
        end,
        sorting = function()
          local cfg = GetSelectedConfig()
          local isVertical = cfg and cfg.display.barOrientation == "vertical"
          if isVertical then
            return {"TOP", "BOTTOM", "LEFT", "RIGHT"}
          else
            return {"LEFT", "RIGHT", "TOP", "BOTTOM"}
          end
        end,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.barIconAnchor or "LEFT"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barIconAnchor = value
            RefreshBar()
          end
        end,
        order = 78.3,
        width = 0.55,
        hidden = function()
          if IsResourceBar() or collapsedSections.barIcon then return true end
          local cfg = GetSelectedConfig()
          return GetSelectedConfig() == nil or IsIconMode() or not (cfg and cfg.display.showBarIcon)
        end
      },
      barIconShowBorder = {
        type = "toggle",
        name = "Border",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.barIconShowBorder
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barIconShowBorder = value
            RefreshBar()
          end
        end,
        order = 78.4,
        width = 0.45,
        hidden = function()
          if IsResourceBar() or collapsedSections.barIcon then return true end
          local cfg = GetSelectedConfig()
          return GetSelectedConfig() == nil or IsIconMode() or not (cfg and cfg.display.showBarIcon)
        end
      },
      iconOffsetX = {
        type = "range",
        name = "Icon X Offset",
        desc = "Horizontal offset for icon positioning within the frame",
        min = -100, max = 100, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconOffsetX or 0
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconOffsetX = value
            RefreshBar()
          end
        end,
        order = 78.5,
        width = 1.0,
        hidden = function()
          if IsResourceBar() or collapsedSections.barIcon then return true end
          local cfg = GetSelectedConfig()
          return GetSelectedConfig() == nil or IsIconMode() or not (cfg and cfg.display.showBarIcon) or not IsChargeBar()
        end
      },
      iconOffsetY = {
        type = "range",
        name = "Icon Y Offset",
        desc = "Vertical offset for icon positioning within the frame (positive = up, negative = down)",
        min = -50, max = 50, step = 1,
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.iconOffsetY or 0
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.iconOffsetY = value
            RefreshBar()
          end
        end,
        order = 78.6,
        width = 1.0,
        hidden = function()
          if IsResourceBar() or collapsedSections.barIcon then return true end
          local cfg = GetSelectedConfig()
          return GetSelectedConfig() == nil or IsIconMode() or not (cfg and cfg.display.showBarIcon) or not IsChargeBar()
        end
      },
      
      -- ============================================================
      -- BAR POSITION
      -- ============================================================
      positionHeader = {
        type = "toggle",
        name = "Bar Position",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.position end,
        set = function(info, value) collapsedSections.position = not value end,
        order = 80,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() end
      },
      barPositionX = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "X Offset",
        desc = "Horizontal position offset from screen center",
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.barPosition then
            local x = cfg.display.barPosition.x or 0
            -- Show decimals only if the value has them
            if x == math.floor(x) then
              return tostring(math.floor(x))
            end
            return tostring(x)
          end
          return "0"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.display.barPosition then
              cfg.display.barPosition = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
            end
            cfg.display.barPosition.x = tonumber(value) or 0
            RefreshBar()
          end
        end,
        order = 80.1,
        width = 0.35,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.position end
      },
      barPositionY = {
        type = "input",
        dialogControl = "ArcUI_EditBox",
        name = "Y Offset",
        desc = "Vertical position offset from screen center",
        get = function()
          local cfg = GetSelectedConfig()
          if cfg and cfg.display.barPosition then
            local y = cfg.display.barPosition.y or 0
            if y == math.floor(y) then
              return tostring(math.floor(y))
            end
            return tostring(y)
          end
          return "0"
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.display.barPosition then
              cfg.display.barPosition = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
            end
            cfg.display.barPosition.y = tonumber(value) or 0
            RefreshBar()
          end
        end,
        order = 80.2,
        width = 0.35,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.position end
      },
      barMovable = {
        type = "toggle",
        name = "Drag to Move",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.display.barMovable
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            cfg.display.barMovable = value
            RefreshBar()
          end
        end,
        order = 80.3,
        width = 0.7,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.position end
      },
      
      -- ============================================================
      -- BEHAVIOR
      -- ============================================================
      behaviorHeader = {
        type = "toggle",
        name = "Behavior",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.behavior end,
        set = function(info, value) collapsedSections.behavior = not value end,
        order = 90,
        width = "full",
        hidden = function() return GetSelectedConfig() == nil end
      },
      hideOutOfCombat = {
        type = "toggle",
        name = "Hide Out of Combat",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.behavior and cfg.behavior.hideOutOfCombat
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            cfg.behavior.hideOutOfCombat = value
            UpdateBar()
          end
        end,
        order = 91,
        width = 1.0,
        hidden = function() return GetSelectedConfig() == nil or collapsedSections.behavior end
      },
      hideWhenInactive = {
        type = "toggle",
        name = "Hide When Inactive",
        desc = "Hide the bar/icon when the buff/debuff is not active",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.behavior and cfg.behavior.hideWhenInactive
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            cfg.behavior.hideWhenInactive = value
            UpdateBar()
          end
        end,
        order = 92,
        width = 1.2,
        hidden = function()
          if GetSelectedConfig() == nil or collapsedSections.behavior then return true end
          if IsResourceBar() or IsChargeBar() or IsCooldownDurationBar() then return true end  -- Hide for resource/charge/CD bars
          return false
        end
      },
      
      -- Charge bar specific: Hide when full charges
      hideWhenFullCharges = {
        type = "toggle",
        name = "Hide When Full",
        desc = "Hide the charge bar when all charges are available",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.behavior and cfg.behavior.hideWhenFullCharges
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            cfg.behavior.hideWhenFullCharges = value
            UpdateBar()
          end
        end,
        order = 93,
        width = 1.0,
        hidden = function()
          if GetSelectedConfig() == nil or collapsedSections.behavior then return true end
          return not IsChargeBar()  -- Only show for charge bars
        end
      },
      
      -- Cooldown bar specific: Hide when ready
      hideWhenReady = {
        type = "toggle",
        name = "Hide When Ready",
        desc = "Hide the cooldown bar when the spell is off cooldown",
        get = function()
          local cfg = GetSelectedConfig()
          return cfg and cfg.behavior and cfg.behavior.hideWhenReady
        end,
        set = function(info, value)
          local cfg = GetSelectedConfig()
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            cfg.behavior.hideWhenReady = value
            UpdateBar()
          end
        end,
        order = 94,
        width = 1.0,
        hidden = function()
          if GetSelectedConfig() == nil or collapsedSections.behavior then return true end
          return not IsCooldownDurationBar()  -- Only show for cooldown duration bars
        end
      },
      
      -- ============================================================
      -- INFO
      -- ============================================================
      infoText = {
        type = "description",
        name = "Customize the appearance of the selected bar and text display.",
        fontSize = "medium",
        order = 100,
        hidden = function() return GetSelectedConfig() == nil or IsIconMode() or collapsedSections.behavior end
      }
    }
  }
  
  return appearanceOptions
end

-- ===================================================================
-- END OF ArcUI_AppearanceOptions.lua
-- ===================================================================