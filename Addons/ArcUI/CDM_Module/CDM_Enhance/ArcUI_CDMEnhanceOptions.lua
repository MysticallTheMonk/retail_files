-- ===================================================================
-- ArcUI_CDMEnhanceOptions.lua


local ADDON, ns = ...

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- Use shared CDM helpers
local Shared = ns.CDMShared

-- ===================================================================
-- UI STATE (Unified CDM Icons Panel)
-- ===================================================================
local selectedAuraIcon = nil
local selectedCooldownIcon = nil

-- Multi-select support
local selectedAuraIcons = {}      -- [cdID] = true for multi-selected auras
local selectedCooldownIcons = {}  -- [cdID] = true for multi-selected cooldowns

-- Unified panel state
local unifiedFilterMode = "cooldowns"  -- "cooldowns", "auras", "freeposition", "group:GroupName"
local editAllUnifiedMode = false

-- Internal helpers synced with editAllUnifiedMode (for backwards compatibility with merged panel options)
local editAllAurasMode = false
local editAllCooldownsMode = false

-- Legacy filter modes (kept for backwards compatibility, always synced with unifiedFilterMode)
local auraFilterMode = "all"
local cooldownFilterMode = "all"

-- Collapsible sections (shared between aura and cooldown options display)
local collapsedSections = {
  globalOptions = true,
  keybinds = true,
  iconAppearance = true,
  position = true,
  activeState = true,      -- For auras
  inactiveState = true,    -- For auras
  readyState = true,       -- For cooldowns
  cooldownState = true,    -- For cooldowns
  auraActiveState = true,  -- For cooldowns with aura overrides
  rangeIndicator = true,
  procGlow = true,
  alertEvents = true,
  border = true,
  cooldownSwipe = true,
  chargeText = true,
  cooldownText = true,
  keybindText = true,      -- Per-icon keybind display settings
  customLabel = true,      -- Per-icon custom label text
}

-- Cache for unified icon list
local cachedUnifiedIcons = {}
local cachedUnifiedFilterMode = nil

-- ===================================================================
-- FORWARD DECLARATIONS
-- These functions are defined later but referenced by other functions
-- ===================================================================
local IsEditingMixedTypes
local GetCooldownIconsToUpdate
local UpdateCooldown
local RebuildUnifiedIconCache

-- ===================================================================
-- SECTION CUSTOMIZATION DETECTION
-- Define which fields belong to each section for per-icon indicator
-- ===================================================================
local SECTION_FIELDS = {
  iconAppearance = { "scale", "width", "height", "aspectRatio", "zoom", "padding", "useGroupScale", "hideShadow", "debuffBorder.enabled", "pandemicBorder.enabled" },
  position = { "position" },
  -- Ready State / Aura Active - all actual stored fields
  activeState = { 
    "cooldownStateVisuals.readyState.alpha",
    "cooldownStateVisuals.readyState.glow",
    "cooldownStateVisuals.readyState.glowCombatOnly",
    "cooldownStateVisuals.readyState.glowType",
    "cooldownStateVisuals.readyState.glowColor",
    "cooldownStateVisuals.readyState.glowIntensity",
    "cooldownStateVisuals.readyState.glowScale",
    "cooldownStateVisuals.readyState.glowSpeed",
    "cooldownStateVisuals.readyState.glowLines",
    "cooldownStateVisuals.readyState.glowThickness",
    "cooldownStateVisuals.readyState.glowParticles",
    "cooldownStateVisuals.readyState.glowXOffset",
    "cooldownStateVisuals.readyState.glowYOffset",
  },
  -- On Cooldown State / Aura Missing - all actual stored fields
  inactiveState = { 
    "cooldownStateVisuals.cooldownState.alpha",
    "cooldownStateVisuals.cooldownState.desaturate",
    "cooldownStateVisuals.cooldownState.noDesaturate",
    "cooldownStateVisuals.cooldownState.tint",
    "cooldownStateVisuals.cooldownState.tintColor",
    "cooldownStateVisuals.cooldownState.preserveDurationText",
    "cooldownStateVisuals.cooldownState.waitForNoCharges",
  },
  auraActiveState = { "auraActiveState.ignoreAuraOverride" },  -- Aura Active State settings
  rangeIndicator = { "rangeIndicator.rangeAlpha", "rangeIndicator.showRangeOverlay", "rangeIndicator.enabled" },
  procGlow = { "procGlow.showProcGlow", "procGlow.procGlowType", "procGlow.procGlowColor", "procGlow.color", "procGlow.enabled" },
  border = { "border.enabled", "border.texture", "border.color", "border.thickness", "border.inset", "border.useClassColor", "border.followDesaturation" },
  cooldownSwipe = { "cooldownSwipe.showSwipe", "cooldownSwipe.showEdge", "cooldownSwipe.showBling", "cooldownSwipe.reverse", "cooldownSwipe.noGCDSwipe", "cooldownSwipe.swipeWaitForNoCharges", "cooldownSwipe.swipeColor", "cooldownSwipe.edgeColor", "cooldownSwipe.edgeScale", "cooldownSwipe.swipeInset", "cooldownSwipe.swipeInsetX", "cooldownSwipe.swipeInsetY", "cooldownSwipe.separateInsets", "cooldownSwipe.ignoreAuraOverride" },
  chargeText = { "chargeText.enabled", "chargeText.font", "chargeText.size", "chargeText.color", "chargeText.outline", "chargeText.anchor", "chargeText.offsetX", "chargeText.offsetY", "chargeText.shadow", "chargeText.shadowColor", "chargeText.shadowOffsetX", "chargeText.shadowOffsetY", "chargeText.mode", "chargeText.position", "chargeText.freeX", "chargeText.freeY" },
  cooldownText = { "cooldownText.enabled", "cooldownText.font", "cooldownText.size", "cooldownText.color", "cooldownText.outline", "cooldownText.anchor", "cooldownText.offsetX", "cooldownText.offsetY", "cooldownText.shadow", "cooldownText.shadowColor", "cooldownText.shadowOffsetX", "cooldownText.shadowOffsetY", "cooldownText.mmss", "cooldownText.decimals", "cooldownText.mode", "cooldownText.position", "cooldownText.freeX", "cooldownText.freeY" },
  keybindText = { "keybindText.enabled", "keybindText.font", "keybindText.size", "keybindText.color", "keybindText.outline", "keybindText.anchor", "keybindText.offsetX", "keybindText.offsetY", "hideKeybind" },
  customLabel = { "customLabel.text", "customLabel.size", "customLabel.color", "customLabel.anchor", "customLabel.xOffset", "customLabel.yOffset", "customLabel.showWhenActive", "customLabel.showWhenInactive", "customLabel.showInReadyState", "customLabel.showInCooldownState", "customLabel.showWhileRecharging", "customLabel.text2", "customLabel.size2", "customLabel.color2", "customLabel.anchor2", "customLabel.xOffset2", "customLabel.yOffset2", "customLabel.showWhenActive2", "customLabel.showWhenInactive2", "customLabel.showInReadyState2", "customLabel.showInCooldownState2", "customLabel.showWhileRecharging2", "customLabel.text3", "customLabel.size3", "customLabel.color3", "customLabel.anchor3", "customLabel.xOffset3", "customLabel.yOffset3", "customLabel.showWhenActive3", "customLabel.showWhenInactive3", "customLabel.showInReadyState3", "customLabel.showInCooldownState3", "customLabel.showWhileRecharging3", "customLabel.labelCount", "customLabel.font", "customLabel.outline", "customLabel.frameStrata", "customLabel.frameLevel" },
  alertEvents = { "alertEvents" },
}

-- Purple indicator for customized sections
local CUSTOM_INDICATOR = "|cffaa55ffEdited|r "

-- Helper: Check if Masque skinning is active (disables zoom/aspectRatio/padding controls)
-- Returns true only if Masque is installed, enabled in ArcUI settings, and has active groups
local function IsMasqueActive()
    if not ns.Masque then return false end
    
    -- Check if any groups are registered and enabled
    if not ns.Masque.IsAnyGroupEnabled or not ns.Masque.IsAnyGroupEnabled() then
        return false
    end
    
    -- Check if Masque skinning is enabled in ArcUI settings
    if ns.Masque.IsEnabled then
        return ns.Masque.IsEnabled()
    end
    
    return false
end

-- Helper: Check if Masque controls cooldown animations (disables cooldown swipe options)
-- Returns true only if Masque is active AND useMasqueCooldowns is enabled
local function IsMasqueCooldownsActive()
    if not IsMasqueActive() then return false end
    
    -- Check if Masque should control cooldowns
    if ns.Masque.ShouldMasqueControlCooldowns then
        return ns.Masque.ShouldMasqueControlCooldowns()
    end
    
    return false
end

-- Static popup for Masque disable reload prompt
StaticPopupDialogs["ARCUI_MASQUE_DISABLE_RELOAD"] = {
    text = "Masque skinning has been disabled.\n\nA UI reload is recommended to fully remove Masque elements from icons.",
    button1 = "Reload Now",
    button2 = "Later",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ARCUI_MASQUE_ENABLE_RELOAD"] = {
    text = "Masque skinning has been enabled.\n\nA UI reload is recommended for Masque to properly skin all icons.",
    button1 = "Reload Now",
    button2 = "Later",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Check if a section has per-icon customizations for the selected aura
local function AuraSectionHasCustomizations(sectionName)
  if not ns.CDMEnhance or not ns.CDMEnhance.HasSectionCustomizations then return false end
  
  -- Only check for single icon selection (not edit-all or multi-select)
  if editAllUnifiedMode or next(selectedAuraIcons) then return false end
  if not selectedAuraIcon then return false end
  
  local fields = SECTION_FIELDS[sectionName]
  if not fields then return false end
  
  return ns.CDMEnhance.HasSectionCustomizations(selectedAuraIcon, fields)
end

-- Check if a section has per-icon customizations for the selected cooldown
local function CooldownSectionHasCustomizations(sectionName)
  if not ns.CDMEnhance or not ns.CDMEnhance.HasSectionCustomizations then return false end
  
  -- Only check for single icon selection (not edit-all or multi-select)
  if editAllUnifiedMode or next(selectedCooldownIcons) then return false end
  if not selectedCooldownIcon then return false end
  
  local fields = SECTION_FIELDS[sectionName]
  if not fields then return false end
  
  return ns.CDMEnhance.HasSectionCustomizations(selectedCooldownIcon, fields)
end

-- Generate header name with optional customization indicator
local function GetAuraHeaderName(sectionName, displayName)
  if AuraSectionHasCustomizations(sectionName) then
    return CUSTOM_INDICATOR .. displayName
  end
  return displayName
end

local function GetCooldownHeaderName(sectionName, displayName)
  if CooldownSectionHasCustomizations(sectionName) then
    return CUSTOM_INDICATOR .. displayName
  end
  return displayName
end

-- ===================================================================
-- GROUP POSITION HELPERS
-- ===================================================================

-- Get the CDM viewer frame by type
local function GetViewerByType(viewerType)
  local viewerNames = {
    aura = "BuffIconCooldownViewer",
    essential = "EssentialCooldownViewer",
    utility = "UtilityCooldownViewer",
  }
  local name = viewerNames[viewerType]
  return name and _G[name]
end

-- Get group X/Y position (relative to UIParent center)
local function GetGroupPosition(viewerType)
  local viewer = GetViewerByType(viewerType)
  if not viewer then return 0, 0 end
  
  local scale = viewer:GetEffectiveScale()
  local uiScale = UIParent:GetEffectiveScale()
  local uiCenterX, uiCenterY = UIParent:GetCenter()
  local viewerX, viewerY = viewer:GetCenter()
  
  if not viewerX or not viewerY then return 0, 0 end
  
  -- Calculate offset from UIParent center
  local offsetX = (viewerX - uiCenterX) * scale / uiScale
  local offsetY = (viewerY - uiCenterY) * scale / uiScale
  
  return math.floor(offsetX + 0.5), math.floor(offsetY + 0.5)
end

-- Set group X/Y position (relative to UIParent center)
local function SetGroupPosition(viewerType, x, y)
  local viewer = GetViewerByType(viewerType)
  if not viewer or not viewer.systemInfo then return end
  
  -- Update the anchor info
  viewer.systemInfo.anchorInfo = {
    point = "CENTER",
    relativeTo = "UIParent",
    relativePoint = "CENTER",
    offsetX = x or 0,
    offsetY = y or 0,
  }
  viewer.systemInfo.isInDefaultPosition = false
  
  -- Apply and save
  if viewer.ApplySystemAnchor then
    viewer:ApplySystemAnchor()
  end
  if EditModeManagerFrame and EditModeManagerFrame.OnSystemPositionChange then
    EditModeManagerFrame:OnSystemPositionChange(viewer)
  end
  
  -- Try to save
  if ns.CDMGroupSettings and ns.CDMGroupSettings.SaveLayoutIfPossible then
    ns.CDMGroupSettings.SaveLayoutIfPossible()
  end
end

-- ===================================================================
-- DROPDOWN VALUES
-- ===================================================================
local FONT_OUTLINES = {
  [""] = "None",
  ["OUTLINE"] = "Outline",
  ["THICKOUTLINE"] = "Thick Outline",
  ["MONOCHROME"] = "Monochrome",
}

-- Helper to normalize outline values (legacy "NONE" -> "")
-- Returns the outline value, or nil if not set (so caller can apply default)
local function NormalizeOutline(outline)
  if outline == "NONE" then return "" end
  return outline
end

-- Helper to get outline with proper nil/NONE handling
local function GetOutlineValue(outline, default)
  if outline == nil then return default or "OUTLINE" end
  if outline == "NONE" then return "" end
  return outline
end

local TEXT_ANCHORS = {
  ["TOPLEFT"] = "Top Left",
  ["TOP"] = "Top",
  ["TOPRIGHT"] = "Top Right",
  ["LEFT"] = "Left",
  ["CENTER"] = "Center",
  ["RIGHT"] = "Right",
  ["BOTTOMLEFT"] = "Bottom Left",
  ["BOTTOM"] = "Bottom",
  ["BOTTOMRIGHT"] = "Bottom Right",
}

local TEXT_MODES = {
  ["anchor"] = "Anchor Position",
  ["free"] = "Free Drag",
}

-- Build sound dropdown from custom sounds list
local function GetSoundDropdownValues()
  local sounds = { [""] = "None (Use Sound ID)" }
  if ns.CUSTOM_SOUNDS then
    for _, name in ipairs(ns.CUSTOM_SOUNDS) do
      sounds[name] = name
    end
  end
  return sounds
end

-- ===================================================================
-- HELPERS
-- ===================================================================
local function GetFonts()
  local fonts = { ["Friz Quadrata TT"] = "Friz Quadrata TT" }
  if LSM then
    for _, name in pairs(LSM:List("font")) do
      fonts[name] = name
    end
  end
  return fonts
end

local function GetAuraIconByIndex(index)
  -- Use the unified cache for consistency
  if cachedUnifiedFilterMode ~= unifiedFilterMode then
    RebuildUnifiedIconCache()
  end
  
  -- Filter to only auras
  local auraIndex = 0
  for _, entry in ipairs(cachedUnifiedIcons) do
    if entry.isAura then
      auraIndex = auraIndex + 1
      if auraIndex == index then
        return entry
      end
    end
  end
  return nil
end

local function GetCooldownIconByIndex(index)
  -- Use the unified cache for consistency
  if cachedUnifiedFilterMode ~= unifiedFilterMode then
    RebuildUnifiedIconCache()
  end
  
  -- Filter to only cooldowns
  local cooldownIndex = 0
  for _, entry in ipairs(cachedUnifiedIcons) do
    if not entry.isAura then
      cooldownIndex = cooldownIndex + 1
      if cooldownIndex == index then
        return entry
      end
    end
  end
  return nil
end

-- ===================================================================
-- AURA ICON HELPERS
-- ===================================================================
local function HideIfNoAuraSelection()
  -- Check unified mode first - if unified edit-all is active with auras in cache, show aura options
  if editAllUnifiedMode then
    -- Check if cache has any auras
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if entry.isAura then
        return false  -- Has auras, show aura options
      end
    end
    return true  -- No auras in cache
  end
  -- Standard check
  return not next(selectedAuraIcons) and selectedAuraIcon == nil
end

local function HideAuraIconAppearance()
  return HideIfNoAuraSelection() or collapsedSections.iconAppearance
end

local function HideAuraBorder()
  return HideIfNoAuraSelection() or collapsedSections.border
end

local function HideAuraChargeText()
  return HideIfNoAuraSelection() or collapsedSections.chargeText
end

local function HideAuraCooldownText()
  return HideIfNoAuraSelection() or collapsedSections.cooldownText
end

local function HideAuraCooldownSwipe()
  if HideIfNoAuraSelection() then return true end
  return collapsedSections.cooldownSwipe
end

-- Check if cooldown swipe options should be disabled (when Masque controls cooldowns)
-- Show Swipe and Show Edge are NOT disabled - user can still toggle visibility
local function DisableAuraCooldownSwipe()
  return false  -- Always enabled - user can toggle swipe/edge visibility even with Masque
end

-- Disable function for options that ARE controlled by Masque (insets, colors, etc)
local function DisableAuraCooldownSwipeMasqueControlled()
  return IsMasqueCooldownsActive()
end

-- Swipe color options ARE disabled when Masque controls cooldowns
-- ArcUI helps Masque apply its skin color by reading _MSQ_Color and calling SetSwipeColor
-- (This works in combat because our method doesn't do secret value comparisons)
local function DisableAuraCooldownSwipeExceptColor()
  return IsMasqueCooldownsActive()
end

-- No GCD Swipe is NOT disabled when Masque controls cooldowns
-- Hiding GCD swipes doesn't conflict with Masque's visual styling
local function DisableAuraCooldownSwipeExceptNoGCD()
  return false  -- Always enabled
end

-- Finish Flash (Bling) is NOT disabled when Masque controls cooldowns
-- ArcUI can control the flash animation independently of Masque
local function DisableAuraCooldownSwipeExceptBling()
  return false  -- Always enabled
end

local function HideAuraRangeIndicator()
  return HideIfNoAuraSelection() or collapsedSections.rangeIndicator
end

local function HideAuraInactiveState()
  return HideIfNoAuraSelection() or collapsedSections.inactiveState
end

local function HideAuraProcGlow()
  return HideIfNoAuraSelection() or collapsedSections.procGlow
end

local function HideAuraAlertEvents()
  return HideIfNoAuraSelection() or collapsedSections.alertEvents
end

local function HideAuraPosition()
  return HideIfNoAuraSelection() or collapsedSections.position
end

-- Get global settings for auras
local function GetAuraGlobalCfg()
  if ns.CDMEnhance and ns.CDMEnhance.GetGlobalSettings then
    return ns.CDMEnhance.GetGlobalSettings("aura")
  end
  return {}
end

-- Get global settings for cooldowns
local function GetCooldownGlobalCfg()
  if ns.CDMEnhance and ns.CDMEnhance.GetGlobalSettings then
    return ns.CDMEnhance.GetGlobalSettings("cooldown")
  end
  return {}
end

-- Apply a global setting for auras
local function ApplyAuraGlobalSetting(path, value)
  if ns.CDMEnhance and ns.CDMEnhance.SetGlobalSetting then
    ns.CDMEnhance.SetGlobalSetting("aura", path, value)
  end
end

-- Apply a global setting for cooldowns
local function ApplyCooldownGlobalSetting(path, value)
  if ns.CDMEnhance and ns.CDMEnhance.SetGlobalSetting then
    ns.CDMEnhance.SetGlobalSetting("cooldown", path, value)
  end
end

-- Helper: Get aura icons being edited (for aura panel)
-- In mixed mode, includes BOTH auras and cooldowns since aura panel applies to both
local function GetAuraIconsForBoolCheck()
  local icons = {}
  
  -- Collect aura icons based on current mode
  if editAllUnifiedMode then
    -- Unified mode: use cache
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if entry.isAura and entry.cooldownID then
        table.insert(icons, entry.cooldownID)
      end
    end
  elseif next(selectedAuraIcons) then
    for cdID, _ in pairs(selectedAuraIcons) do
      table.insert(icons, cdID)
    end
  elseif selectedAuraIcon then
    table.insert(icons, selectedAuraIcon)
  end
  
  -- In mixed mode (editing group/freeposition), also include cooldown icons
  -- This is for SHARED settings that apply to both types
  local shouldIncludeCooldowns = false
  if IsEditingMixedTypes and IsEditingMixedTypes() then
    shouldIncludeCooldowns = true
  elseif editAllUnifiedMode and unifiedFilterMode ~= "auras" and unifiedFilterMode ~= "cooldowns" then
    -- Groups and freeposition can have both auras and cooldowns
    shouldIncludeCooldowns = true
  end
  
  if shouldIncludeCooldowns then
    if editAllUnifiedMode then
      for _, entry in ipairs(cachedUnifiedIcons) do
        if not entry.isAura and entry.cooldownID then
          table.insert(icons, entry.cooldownID)
        end
      end
    elseif next(selectedCooldownIcons) then
      for cdID, _ in pairs(selectedCooldownIcons) do
        table.insert(icons, cdID)
      end
    elseif selectedCooldownIcon then
      table.insert(icons, selectedCooldownIcon)
    end
  end
  
  return icons
end

-- Helper: Get ONLY aura icons for TYPE-SPECIFIC bool check (never includes cooldowns)
-- Use this for aura-specific settings like activeState glow that don't exist on cooldowns
local function GetAuraOnlyIconsForBoolCheck()
  local icons = {}
  
  if editAllUnifiedMode then
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if entry.isAura and entry.cooldownID then
        table.insert(icons, entry.cooldownID)
      end
    end
  elseif next(selectedAuraIcons) then
    for cdID, _ in pairs(selectedAuraIcons) do
      table.insert(icons, cdID)
    end
  elseif selectedAuraIcon then
    table.insert(icons, selectedAuraIcon)
  end
  
  return icons
end

-- Helper: Get cooldown icons being edited (for cooldown panel)
local function GetCooldownIconsForBoolCheck()
  local icons = {}
  
  if editAllUnifiedMode then
    -- Use unified cache
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if not entry.isAura and entry.cooldownID then
        table.insert(icons, entry.cooldownID)
      end
    end
  elseif next(selectedCooldownIcons) then
    for cdID, _ in pairs(selectedCooldownIcons) do
      table.insert(icons, cdID)
    end
  elseif selectedCooldownIcon then
    table.insert(icons, selectedCooldownIcon)
  end
  
  return icons
end

-- Helper: Get consistent boolean value across icons (aura context)
-- In Edit All mode: returns false if ANY icon has the option disabled (so toggle shows unchecked)
-- This makes it clear to users they need to enable it to synchronize all icons
local function GetAuraConsistentBool(getter)
  local icons = GetAuraIconsForBoolCheck()
  if #icons <= 1 then return nil end
  
  local firstValue = nil
  local allSame = true
  local anyFalse = false
  
  for _, cdID in ipairs(icons) do
    local cfg = ns.CDMEnhance and ns.CDMEnhance.GetIconSettings(cdID)
    if cfg then
      local val = getter(cfg)
      -- Track if any icon has the option disabled
      if not val then
        anyFalse = true
      end
      if firstValue == nil then
        firstValue = val
      elseif val ~= firstValue then
        allSame = false
      end
    end
  end
  
  -- If ANY icon has false, return false so toggle shows unchecked
  -- This makes it clear to users that not all icons have the setting enabled
  if anyFalse then return false end
  if not allSame then return false end
  return firstValue
end

-- Helper: Get consistent boolean for AURA-ONLY settings (TYPE-SPECIFIC, never checks cooldowns)
-- Use this for aura active/inactive state settings that don't exist on cooldowns
local function GetAuraOnlyConsistentBool(getter)
  local icons = GetAuraOnlyIconsForBoolCheck()
  if #icons <= 1 then return nil end
  
  local firstValue = nil
  local allSame = true
  local anyFalse = false
  
  for _, cdID in ipairs(icons) do
    local cfg = ns.CDMEnhance and ns.CDMEnhance.GetIconSettings(cdID)
    if cfg then
      local val = getter(cfg)
      if not val then
        anyFalse = true
      end
      if firstValue == nil then
        firstValue = val
      elseif val ~= firstValue then
        allSame = false
      end
    end
  end
  
  if anyFalse then return false end
  if not allSame then return false end
  return firstValue
end

-- Helper: Get consistent boolean value across icons (cooldown context)
-- In Edit All mode: returns false if ANY icon has the option disabled (so toggle shows unchecked)
-- This makes it clear to users they need to enable it to synchronize all icons
local function GetCooldownConsistentBool(getter)
  local icons = GetCooldownIconsForBoolCheck()
  if #icons <= 1 then return nil end
  
  local firstValue = nil
  local allSame = true
  local anyFalse = false
  
  for _, cdID in ipairs(icons) do
    local cfg = ns.CDMEnhance and ns.CDMEnhance.GetIconSettings(cdID)
    if cfg then
      local val = getter(cfg)
      -- Track if any icon has the option disabled
      if not val then
        anyFalse = true
      end
      if firstValue == nil then
        firstValue = val
      elseif val ~= firstValue then
        allSame = false
      end
    end
  end
  
  -- If ANY icon has false, return false so toggle shows unchecked
  -- This makes it clear to users that not all icons have the setting enabled
  if anyFalse then return false end
  if not allSame then return false end
  return firstValue
end

-- Wrapper for aura boolean toggle getters (SHARED settings - includes cooldowns in mixed mode)
local function GetAuraBoolSetting(getter, fallbackGetter)
  local consistent = GetAuraConsistentBool(getter)
  if consistent ~= nil then return consistent end
  return fallbackGetter()
end

-- Wrapper for AURA-ONLY boolean toggle getters (TYPE-SPECIFIC - never includes cooldowns)
-- Use this for aura active/inactive state settings that don't exist on cooldowns
local function GetAuraOnlyBoolSetting(getter, fallbackGetter)
  local consistent = GetAuraOnlyConsistentBool(getter)
  if consistent ~= nil then return consistent end
  return fallbackGetter()
end

-- Wrapper for cooldown boolean toggle getters
local function GetCooldownBoolSetting(getter, fallbackGetter)
  local consistent = GetCooldownConsistentBool(getter)
  if consistent ~= nil then return consistent end
  return fallbackGetter()
end

local function GetAuraCfg()
  if editAllUnifiedMode then
    -- Edit-all mode: use unified cache
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if entry.isAura and entry.cooldownID and ns.CDMEnhance then
        return ns.CDMEnhance.GetIconSettings(entry.cooldownID)
      end
    end
    -- Fallback to cooldowns for shared settings display
    for _, entry in ipairs(cachedUnifiedIcons) do
      if not entry.isAura and entry.cooldownID and ns.CDMEnhance then
        return ns.CDMEnhance.GetIconSettings(entry.cooldownID)
      end
    end
    return nil
  end
  
  -- Multi-select: return first selected icon's config for display
  if next(selectedAuraIcons) then
    for cdID, _ in pairs(selectedAuraIcons) do
      if ns.CDMEnhance then
        return ns.CDMEnhance.GetIconSettings(cdID)
      end
    end
  end
  
  -- Single selection
  if not selectedAuraIcon or not ns.CDMEnhance then return nil end
  return ns.CDMEnhance.GetIconSettings(selectedAuraIcon)
end

-- Get list of aura icons to update (supports multi-select and edit-all mode)
local function GetAuraIconsToUpdate()
  local icons = {}
  
  if editAllUnifiedMode then
    -- Edit-all mode: use unified cache
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if entry.isAura and entry.cooldownID then
        table.insert(icons, entry.cooldownID)
      end
    end
  elseif next(selectedAuraIcons) then
    -- Multi-select mode
    for cdID, _ in pairs(selectedAuraIcons) do
      table.insert(icons, cdID)
    end
  elseif selectedAuraIcon then
    -- Single selection
    table.insert(icons, selectedAuraIcon)
  end
  
  return icons
end

local function UpdateAura()
  if not ns.CDMEnhance then return end
  
  -- Invalidate cache first so changes take effect
  ns.CDMEnhance.InvalidateCache()
  
  local icons = GetAuraIconsToUpdate()
  for _, cdID in ipairs(icons) do
    ns.CDMEnhance.UpdateIcon(cdID)
    
    -- For Arc Auras, also call RefreshFrameSettings to apply cooldown swipe settings
    if ns.ArcAuras and ns.ArcAuras.RefreshFrameSettings and type(cdID) == "string" and cdID:match("^arc_") then
      ns.ArcAuras.RefreshFrameSettings(cdID)
    end
  end
  
  -- Also refresh Arc Auras stack text styling (for chargeText changes)
  if ns.ArcAuras and ns.ArcAuras.RefreshStackTextStyle then
    ns.ArcAuras.RefreshStackTextStyle()
  end
end

-- Apply a setting to all selected/applicable aura icons
-- In mixed mode or unified edit-all mode, also applies to cooldown icons (shared settings)
local function ApplyAuraSetting(setter)
  local icons = GetAuraIconsToUpdate()
  for _, cdID in ipairs(icons) do
    -- Use GetOrCreateIconSettings to get/create the stored per-icon settings
    local cfg = ns.CDMEnhance.GetOrCreateIconSettings(cdID)
    if cfg then
      setter(cfg)
    end
  end
  
  -- In mixed mode OR unified edit-all with groups, also apply to cooldowns
  -- This ensures shared settings apply to all visible icons regardless of type
  local shouldApplyToCooldowns = false
  if IsEditingMixedTypes and IsEditingMixedTypes() then
    shouldApplyToCooldowns = true
  elseif editAllUnifiedMode and (unifiedFilterMode ~= "auras" and unifiedFilterMode ~= "cooldowns") then
    -- Unified edit-all mode with a group or freeposition filter
    shouldApplyToCooldowns = true
  end
  
  if shouldApplyToCooldowns then
    local cooldownIcons = GetCooldownIconsToUpdate()
    for _, cdID in ipairs(cooldownIcons) do
      local cfg = ns.CDMEnhance.GetOrCreateIconSettings(cdID)
      if cfg then
        setter(cfg)
      end
    end
  end
  
  -- Invalidate cache to ensure changes are picked up
  if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
    ns.CDMEnhance.InvalidateCache()
  end
  UpdateAura()
  
  -- Also update cooldowns if we applied to them
  if shouldApplyToCooldowns then
    UpdateCooldown()
  end
  
  -- Refresh CDMGroups layouts to recalculate container bounds for size changes
  if ns.CDMGroups and ns.CDMGroups.RefreshAllGroupLayouts then
    ns.CDMGroups.RefreshAllGroupLayouts()
  end
  
  -- Refresh Masque skins after style/size changes
  if ns.Masque and ns.Masque.QueueRefresh then
    ns.Masque.QueueRefresh()
  end
  
  -- Refresh cooldown preview if active
  if ns.CDMEnhance and ns.CDMEnhance.IsCooldownPreviewMode and ns.CDMEnhance.IsCooldownPreviewMode() then
    ns.CDMEnhance.RefreshCooldownPreview()
  end
end

-- Apply a TYPE-SPECIFIC setting to aura icons only (NOT shared with cooldowns)
-- Use this for aura active/inactive state settings
local function ApplyAuraOnlySetting(setter)
  local icons = GetAuraIconsToUpdate()
  for _, cdID in ipairs(icons) do
    local cfg = ns.CDMEnhance.GetOrCreateIconSettings(cdID)
    if cfg then
      setter(cfg)
    end
  end
  
  if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
    ns.CDMEnhance.InvalidateCache()
  end
  UpdateAura()
  
  -- Refresh Masque skins after style changes
  if ns.Masque and ns.Masque.QueueRefresh then
    ns.Masque.QueueRefresh()
  end
  
  -- Refresh cooldown preview if active
  if ns.CDMEnhance and ns.CDMEnhance.IsCooldownPreviewMode and ns.CDMEnhance.IsCooldownPreviewMode() then
    ns.CDMEnhance.RefreshCooldownPreview()
  end
end

-- Wrapper for proc glow settings (CDM built-in glow) - SHARED setting
-- Applies to both types in mixed mode since proc glow is shared
local function ApplyAuraGlowSetting(setter)
  ApplyAuraSetting(setter)
  -- Refresh proc glow for all affected icons (both preview AND active glows)
  local allIcons = {}
  
  -- Get aura icons
  local auraIcons = GetAuraIconsToUpdate()
  for _, cdID in ipairs(auraIcons) do
    table.insert(allIcons, cdID)
  end
  
  -- In mixed mode, also get cooldown icons (ApplyAuraSetting already applied to them)
  local isMixedMode = (IsEditingMixedTypes and IsEditingMixedTypes()) or
                      (editAllUnifiedMode and unifiedFilterMode ~= "auras" and unifiedFilterMode ~= "cooldowns")
  if isMixedMode then
    local cooldownIcons = GetCooldownIconsToUpdate()
    for _, cdID in ipairs(cooldownIcons) do
      table.insert(allIcons, cdID)
    end
  end
  
  -- Refresh glow for all affected icons
  for _, cdID in ipairs(allIcons) do
    -- Refresh preview if active
    if ns.CDMEnhanceOptions.IsProcGlowPreviewActive and ns.CDMEnhanceOptions.IsProcGlowPreviewActive(cdID) then
      if ns.CDMEnhance and ns.CDMEnhance.ShowProcGlowPreview then
        ns.CDMEnhance.ShowProcGlowPreview(cdID)
      end
    end
    
    -- Also refresh active glows (not just preview) - this is the fix for multi-select
    if ns.CDMEnhance and ns.CDMEnhance.RefreshProcGlow then
      ns.CDMEnhance.RefreshProcGlow(cdID)
    end
  end
end

-- Apply aura active state glow TOGGLE settings with immediate refresh (TYPE-SPECIFIC to auras)
-- Clears glow signature to force restart with new settings
-- NOTE: This is for aura active state glow - NOT shared with cooldowns (they have their own ready state glow)
local function ApplyAuraReadyStateGlowSetting(setter)
  ApplyAuraOnlySetting(setter)
  if ns.CDMEnhance then
    local icons = GetAuraIconsToUpdate()
    for _, cdID in ipairs(icons) do
      local data = ns.CDMEnhance.GetEnhancedFrameData and ns.CDMEnhance.GetEnhancedFrameData(cdID)
      if data and data.frame then
        data.frame._arcCurrentGlowSig = nil
        -- If preview is active, force immediate glow refresh
        if ns.CDMEnhanceOptions.IsGlowPreviewActive and ns.CDMEnhanceOptions.IsGlowPreviewActive(cdID) then
          ns.CDMEnhanceOptions.SetGlowPreview(cdID, true)
        end
      end
    end
    if ns.CDMEnhance.InvalidateCache then ns.CDMEnhance.InvalidateCache() end
    for _, cdID in ipairs(icons) do
      if ns.CDMEnhance.UpdateIcon then ns.CDMEnhance.UpdateIcon(cdID) end
    end
  end
end

-- Apply aura active state glow SLIDER settings (TYPE-SPECIFIC to auras)
-- Lighter version that doesn't clear glow signature - just updates preview if active
-- Use this for continuous slider changes to avoid FPS drops
local function ApplyAuraReadyStateGlowSliderSetting(setter)
  ApplyAuraOnlySetting(setter)
  if ns.CDMEnhance then
    local icons = GetAuraIconsToUpdate()
    -- Only refresh preview if active - no signature clearing, no full UpdateIcon
    for _, cdID in ipairs(icons) do
      if ns.CDMEnhanceOptions.IsGlowPreviewActive and ns.CDMEnhanceOptions.IsGlowPreviewActive(cdID) then
        ns.CDMEnhanceOptions.SetGlowPreview(cdID, true)
      end
    end
  end
end

-- ===================================================================
-- COOLDOWN ICON HELPERS
-- ===================================================================
local function HideIfNoCooldownSelection()
  -- Check edit-all mode - if active with cooldowns in cache, show cooldown options
  if editAllUnifiedMode then
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if not entry.isAura then
        return false  -- Has cooldowns, show cooldown options
      end
    end
    return true  -- No cooldowns in cache
  end
  -- Standard check
  return not next(selectedCooldownIcons) and selectedCooldownIcon == nil
end

-- ===================================================================
-- SECTION RESET HELPERS
-- Removes specific section fields from per-icon settings
-- Now using spec-based iconSettings storage
-- ===================================================================

-- Helper to clear a nested field by dot-separated path (e.g., "a.b.c")
-- Returns true if something was cleared, and cleans up empty parent tables
local function ClearNestedField(settings, path)
  local keys = {}
  for key in path:gmatch("[^.]+") do
    table.insert(keys, key)
  end
  
  if #keys == 0 then return false end
  
  -- Navigate to parent table
  local current = settings
  local parents = {{tbl = settings, key = nil}}
  
  for i = 1, #keys - 1 do
    if type(current) ~= "table" then return false end
    local nextTbl = current[keys[i]]
    if nextTbl == nil then return false end
    current = nextTbl
    table.insert(parents, {tbl = current, key = keys[i]})
  end
  
  -- Clear the final key
  local finalKey = keys[#keys]
  if type(current) ~= "table" or current[finalKey] == nil then
    return false
  end
  
  current[finalKey] = nil
  
  -- Clean up empty parent tables (walk backwards)
  for i = #parents, 2, -1 do
    local parent = parents[i]
    if parent.tbl and not next(parent.tbl) then
      -- This table is empty, remove it from its parent
      local grandparent = parents[i-1]
      if grandparent and grandparent.tbl and parent.key then
        -- Actually we need the key used to access this table
        local keyToRemove = keys[i-1]
        grandparent.tbl[keyToRemove] = nil
      end
    else
      break  -- Stop if we hit a non-empty table
    end
  end
  
  return true
end

local function ResetAuraSectionSettings(sectionName)
  local fields = SECTION_FIELDS[sectionName]
  if not fields then return end
  
  local Shared = ns.CDMShared
  local icons = GetAuraIconsToUpdate()
  for _, cdID in ipairs(icons) do
    local iconSettings = Shared and Shared.GetSpecIconSettings and Shared.GetSpecIconSettings()
    if iconSettings then
      local key = tostring(cdID)
      local settings = iconSettings[key]
      if settings then
        for _, field in ipairs(fields) do
          ClearNestedField(settings, field)
        end
        -- Remove empty settings entry
        if not next(settings) then
          iconSettings[key] = nil
        end
      end
    end
  end
  
  -- Check if we should also reset for cooldowns (mixed mode or unified mode with groups)
  local shouldResetCooldowns = false
  if IsEditingMixedTypes and IsEditingMixedTypes() then
    shouldResetCooldowns = true
  elseif editAllUnifiedMode and (unifiedFilterMode ~= "auras" and unifiedFilterMode ~= "cooldowns") then
    shouldResetCooldowns = true
  end
  
  if shouldResetCooldowns then
    local cooldownIcons = GetCooldownIconsToUpdate()
    for _, cdID in ipairs(cooldownIcons) do
      local iconSettings = Shared and Shared.GetSpecIconSettings and Shared.GetSpecIconSettings()
      if iconSettings then
        local key = tostring(cdID)
        local settings = iconSettings[key]
        if settings then
          for _, field in ipairs(fields) do
            ClearNestedField(settings, field)
          end
          if not next(settings) then
            iconSettings[key] = nil
          end
        end
      end
    end
  end
  
  if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
    ns.CDMEnhance.InvalidateCache()
  end
  UpdateAura()
  if shouldResetCooldowns then
    UpdateCooldown()
  end
  LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
end

local function ResetCooldownSectionSettings(sectionName)
  local fields = SECTION_FIELDS[sectionName]
  if not fields then return end
  
  local Shared = ns.CDMShared
  local icons = GetCooldownIconsToUpdate()
  for _, cdID in ipairs(icons) do
    local iconSettings = Shared and Shared.GetSpecIconSettings and Shared.GetSpecIconSettings()
    if iconSettings then
      local key = tostring(cdID)
      local settings = iconSettings[key]
      if settings then
        for _, field in ipairs(fields) do
          ClearNestedField(settings, field)
        end
        if not next(settings) then
          iconSettings[key] = nil
        end
      end
    end
  end
  
  if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
    ns.CDMEnhance.InvalidateCache()
  end
  UpdateCooldown()
  LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
end

-- ===================================================================
-- MIXED TYPE DETECTION
-- When editing both auras AND cooldowns, shared options only show once
-- ===================================================================
IsEditingMixedTypes = function()
  -- If in unified edit-all mode, check what types are actually in the cache
  if editAllUnifiedMode then
    -- Ensure cache is current
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    local hasAurasInCache = false
    local hasCooldownsInCache = false
    for _, entry in ipairs(cachedUnifiedIcons) do
      if entry.isAura then
        hasAurasInCache = true
      else
        hasCooldownsInCache = true
      end
      -- Early exit if we found both
      if hasAurasInCache and hasCooldownsInCache then
        return true
      end
    end
    return hasAurasInCache and hasCooldownsInCache
  end
  
  -- Standard check based on selections
  local hasAuras = next(selectedAuraIcons) or selectedAuraIcon ~= nil
  local hasCooldowns = next(selectedCooldownIcons) or selectedCooldownIcon ~= nil
  return hasAuras and hasCooldowns
end

-- Shared panels: hidden in cooldown section when mixed (aura section shows them)
local function HideCooldownIconAppearance()
  if HideIfNoCooldownSelection() then return true end
  if IsEditingMixedTypes() then return true end
  return collapsedSections.iconAppearance
end

local function HideCooldownBorder()
  if HideIfNoCooldownSelection() then return true end
  if IsEditingMixedTypes() then return true end
  return collapsedSections.border
end

local function HideCooldownChargeText()
  if HideIfNoCooldownSelection() then return true end
  if IsEditingMixedTypes() then return true end
  return collapsedSections.chargeText
end

local function HideCooldownCooldownText()
  if HideIfNoCooldownSelection() then return true end
  if IsEditingMixedTypes() then return true end
  return collapsedSections.cooldownText
end

local function HideCooldownKeybindText()
  if HideIfNoCooldownSelection() then return true end
  if IsEditingMixedTypes() then return true end
  return collapsedSections.keybindText
end

local function HideCooldownCooldownSwipe()
  if HideIfNoCooldownSelection() then return true end
  if IsEditingMixedTypes() then return true end
  return collapsedSections.cooldownSwipe
end

-- Check if cooldown swipe options should be disabled (when Masque controls cooldowns)
-- Show Swipe and Show Edge are NOT disabled - user can still toggle visibility
local function DisableCooldownCooldownSwipe()
  return false  -- Always enabled - user can toggle swipe/edge visibility even with Masque
end

-- Disable function for options that ARE controlled by Masque (insets, colors, etc)
local function DisableCooldownCooldownSwipeMasqueControlled()
  return IsMasqueCooldownsActive()
end

-- Swipe color options ARE disabled when Masque controls cooldowns
-- ArcUI helps Masque apply its skin color by reading _MSQ_Color and calling SetSwipeColor
local function DisableCooldownCooldownSwipeExceptColor()
  return IsMasqueCooldownsActive()
end

-- No GCD Swipe is NOT disabled when Masque controls cooldowns
-- Hiding GCD swipes doesn't conflict with Masque's visual styling
local function DisableCooldownCooldownSwipeExceptNoGCD()
  return false  -- Always enabled
end

-- Finish Flash (Bling) is NOT disabled when Masque controls cooldowns
-- ArcUI can control the flash animation independently of Masque
local function DisableCooldownCooldownSwipeExceptBling()
  return false  -- Always enabled
end

local function HideCooldownRangeIndicator()
  if HideIfNoCooldownSelection() then return true end
  if IsEditingMixedTypes() then return true end
  return collapsedSections.rangeIndicator
end

local function HideCooldownProcGlow()
  if HideIfNoCooldownSelection() then return true end
  if IsEditingMixedTypes() then return true end
  return collapsedSections.procGlow
end

local function HideCooldownAlertEvents()
  return HideIfNoCooldownSelection() or collapsedSections.alertEvents
end

local function HideCooldownPosition()
  if HideIfNoCooldownSelection() then return true end
  if IsEditingMixedTypes() then return true end
  return collapsedSections.position
end

local function HideCooldownInactiveState()
  return HideIfNoCooldownSelection() or collapsedSections.cooldownState
end

local function HideCooldownAuraActiveState()
  return HideIfNoCooldownSelection() or collapsedSections.auraActiveState
end

-- Get the viewer type for the currently selected cooldown(s)
-- Returns "cooldown" for Essential, "utility" for Utility
local function GetSelectedCooldownViewerType()
  if not ns.CDMEnhance or not ns.CDMEnhance.GetCooldownIcons then return nil end
  
  local cooldowns = ns.CDMEnhance.GetCooldownIcons()
  local cdID = nil
  
  -- Get first selected cooldown ID
  if editAllUnifiedMode then
    -- Use unified cache
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if not entry.isAura and entry.cooldownID then
        cdID = entry.cooldownID
        break
      end
    end
  elseif next(selectedCooldownIcons) then
    for id, _ in pairs(selectedCooldownIcons) do
      cdID = id
      break
    end
  elseif selectedCooldownIcon then
    cdID = selectedCooldownIcon
  end
  
  if not cdID then return nil end
  
  -- Find the viewer type for this cooldown
  local data = cooldowns[cdID]
  if data and data.viewerName then
    if data.viewerName == "EssentialCooldownViewer" then
      return "cooldown"
    elseif data.viewerName == "UtilityCooldownViewer" then
      return "utility"
    end
  end
  
  return nil
end

local function GetCooldownCfg()
  if editAllUnifiedMode then
    -- Use unified cache
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if not entry.isAura and entry.cooldownID and ns.CDMEnhance then
        return ns.CDMEnhance.GetIconSettings(entry.cooldownID)
      end
    end
    -- Fallback to auras for shared settings display
    for _, entry in ipairs(cachedUnifiedIcons) do
      if entry.isAura and entry.cooldownID and ns.CDMEnhance then
        return ns.CDMEnhance.GetIconSettings(entry.cooldownID)
      end
    end
    return nil
  end
  
  -- Multi-select: return first selected icon's config for display
  if next(selectedCooldownIcons) then
    for cdID, _ in pairs(selectedCooldownIcons) do
      if ns.CDMEnhance then
        return ns.CDMEnhance.GetIconSettings(cdID)
      end
    end
  end
  
  -- Single selection
  if not selectedCooldownIcon or not ns.CDMEnhance then return nil end
  return ns.CDMEnhance.GetIconSettings(selectedCooldownIcon)
end

-- Get list of cooldown icons to update (supports multi-select and edit-all mode)
-- Note: Forward declared at top of file for use in ApplyAuraSetting mixed mode
GetCooldownIconsToUpdate = function()
  local icons = {}
  
  if editAllUnifiedMode then
    -- Use unified cache
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    for _, entry in ipairs(cachedUnifiedIcons) do
      if not entry.isAura and entry.cooldownID then
        table.insert(icons, entry.cooldownID)
      end
    end
  elseif next(selectedCooldownIcons) then
    -- Multi-select mode
    for cdID, _ in pairs(selectedCooldownIcons) do
      table.insert(icons, cdID)
    end
  elseif selectedCooldownIcon then
    -- Single selection
    table.insert(icons, selectedCooldownIcon)
  end
  
  return icons
end

-- Note: Forward declared at top of file for use in ApplyAuraSetting mixed mode
UpdateCooldown = function()
  if not ns.CDMEnhance then return end
  
  -- Invalidate cache first so changes take effect
  ns.CDMEnhance.InvalidateCache()
  
  local icons = GetCooldownIconsToUpdate()
  for _, cdID in ipairs(icons) do
    ns.CDMEnhance.UpdateIcon(cdID)
    
    -- For Arc Auras, also call RefreshFrameSettings to apply cooldown swipe settings
    if ns.ArcAuras and ns.ArcAuras.RefreshFrameSettings and type(cdID) == "string" and cdID:match("^arc_") then
      ns.ArcAuras.RefreshFrameSettings(cdID)
    end
  end
  
  -- Also refresh Arc Auras stack text styling (for chargeText changes)
  if ns.ArcAuras and ns.ArcAuras.RefreshStackTextStyle then
    ns.ArcAuras.RefreshStackTextStyle()
  end
end

-- Apply a setting to all selected/applicable cooldown icons
-- NOTE: This applies ONLY to cooldowns. For shared settings that should apply
-- to both types in mixed mode, use ApplySharedSetting instead.
local function ApplyCooldownSetting(setter)
  local icons = GetCooldownIconsToUpdate()
  for _, cdID in ipairs(icons) do
    -- Use GetOrCreateIconSettings to get/create the stored per-icon settings
    local cfg = ns.CDMEnhance.GetOrCreateIconSettings(cdID)
    if cfg then
      setter(cfg)
    end
  end
  -- Invalidate cache to ensure changes are picked up
  if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
    ns.CDMEnhance.InvalidateCache()
  end
  UpdateCooldown()
  
  -- Refresh CDMGroups layouts to recalculate container bounds for size changes
  if ns.CDMGroups and ns.CDMGroups.RefreshAllGroupLayouts then
    ns.CDMGroups.RefreshAllGroupLayouts()
  end
  
  -- Refresh Masque skins after style/size changes
  if ns.Masque and ns.Masque.QueueRefresh then
    ns.Masque.QueueRefresh()
  end
end

-- Apply a SHARED setting to all selected icons (both auras AND cooldowns in mixed mode)
-- Use this for settings that make sense for both types: scale, borders, text, etc.
local function ApplySharedCooldownSetting(setter)
  local icons = GetCooldownIconsToUpdate()
  for _, cdID in ipairs(icons) do
    local cfg = ns.CDMEnhance.GetOrCreateIconSettings(cdID)
    if cfg then
      setter(cfg)
    end
  end
  
  -- In mixed mode, also apply to auras
  local shouldApplyToAuras = false
  if IsEditingMixedTypes and IsEditingMixedTypes() then
    shouldApplyToAuras = true
  elseif editAllUnifiedMode and (unifiedFilterMode ~= "auras" and unifiedFilterMode ~= "cooldowns") then
    shouldApplyToAuras = true
  end
  
  if shouldApplyToAuras then
    local auraIcons = GetAuraIconsToUpdate()
    for _, cdID in ipairs(auraIcons) do
      local cfg = ns.CDMEnhance.GetOrCreateIconSettings(cdID)
      if cfg then
        setter(cfg)
      end
    end
  end
  
  if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
    ns.CDMEnhance.InvalidateCache()
  end
  UpdateCooldown()
  if shouldApplyToAuras then
    UpdateAura()
  end
  
  -- Refresh CDMGroups layouts to recalculate container bounds for size changes
  if ns.CDMGroups and ns.CDMGroups.RefreshAllGroupLayouts then
    ns.CDMGroups.RefreshAllGroupLayouts()
  end
  
  -- Refresh Masque skins after style/size changes
  if ns.Masque and ns.Masque.QueueRefresh then
    ns.Masque.QueueRefresh()
  end
  
  -- Refresh cooldown preview if active
  if ns.CDMEnhance and ns.CDMEnhance.IsCooldownPreviewMode and ns.CDMEnhance.IsCooldownPreviewMode() then
    ns.CDMEnhance.RefreshCooldownPreview()
  end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORT HELPERS FOR EXTERNAL OPTION MODULES
-- External option files (e.g. ArcUI_CustomLabelOptions) use these to build
-- option entries that work seamlessly with edit-all / multi-select.
-- Placed AFTER all local helper functions are defined so references are valid.
-- ═══════════════════════════════════════════════════════════════════════════
ns.OptionsHelpers = {
  collapsedSections       = collapsedSections,
  GetAuraCfg              = GetAuraCfg,
  GetCooldownCfg          = GetCooldownCfg,
  ApplyAuraSetting        = ApplyAuraSetting,
  ApplySharedCooldownSetting = ApplySharedCooldownSetting,
  HideIfNoAuraSelection   = HideIfNoAuraSelection,
  HideIfNoCooldownSelection = HideIfNoCooldownSelection,
  IsEditingMixedTypes     = IsEditingMixedTypes,
  GetAuraHeaderName       = GetAuraHeaderName,
  GetCooldownHeaderName   = GetCooldownHeaderName,
  ResetAuraSectionSettings   = ResetAuraSectionSettings,
  ResetCooldownSectionSettings = ResetCooldownSectionSettings,
}

-- Wrapper for proc glow settings (CDM built-in glow) - SHARED setting
-- Applies to both types in mixed mode since proc glow is shared
local function ApplyCooldownGlowSetting(setter)
  ApplySharedCooldownSetting(setter)
  -- Refresh proc glow for all affected icons (both preview AND active glows)
  local allIcons = {}
  
  -- Get cooldown icons
  local cooldownIcons = GetCooldownIconsToUpdate()
  for _, cdID in ipairs(cooldownIcons) do
    table.insert(allIcons, cdID)
  end
  
  -- In mixed mode, also get aura icons
  local isMixedMode = (IsEditingMixedTypes and IsEditingMixedTypes()) or
                      (editAllUnifiedMode and unifiedFilterMode ~= "auras" and unifiedFilterMode ~= "cooldowns")
  if isMixedMode then
    local auraIcons = GetAuraIconsToUpdate()
    for _, cdID in ipairs(auraIcons) do
      table.insert(allIcons, cdID)
    end
  end
  
  -- Refresh glow for all affected icons
  for _, cdID in ipairs(allIcons) do
    -- Refresh preview if active
    if ns.CDMEnhanceOptions.IsProcGlowPreviewActive and ns.CDMEnhanceOptions.IsProcGlowPreviewActive(cdID) then
      if ns.CDMEnhance and ns.CDMEnhance.ShowProcGlowPreview then
        ns.CDMEnhance.ShowProcGlowPreview(cdID)
      end
    end
    
    -- Also refresh active glows (not just preview) - this is the fix for multi-select
    if ns.CDMEnhance and ns.CDMEnhance.RefreshProcGlow then
      ns.CDMEnhance.RefreshProcGlow(cdID)
    end
  end
end

-- Apply ready state glow settings with immediate refresh (TYPE-SPECIFIC to cooldowns)
-- Clears glow signature to force restart with new settings
-- NOTE: This is for cooldown ready state glow - NOT shared with auras
local function ApplyReadyStateGlowSetting(setter)
  ApplyCooldownSetting(setter)
  if ns.CDMEnhance then
    local icons = GetCooldownIconsToUpdate()
    for _, cdID in ipairs(icons) do
      local data = ns.CDMEnhance.GetEnhancedFrameData and ns.CDMEnhance.GetEnhancedFrameData(cdID)
      if data and data.frame then
        data.frame._arcCurrentGlowSig = nil
        -- If preview is active, force immediate glow refresh
        if ns.CDMEnhanceOptions.IsGlowPreviewActive and ns.CDMEnhanceOptions.IsGlowPreviewActive(cdID) then
          ns.CDMEnhanceOptions.SetGlowPreview(cdID, true)
        end
      end
    end
    if ns.CDMEnhance.InvalidateCache then ns.CDMEnhance.InvalidateCache() end
    for _, cdID in ipairs(icons) do
      if ns.CDMEnhance.UpdateIcon then ns.CDMEnhance.UpdateIcon(cdID) end
    end
  end
end

-- Apply cooldown ready state glow SLIDER settings (TYPE-SPECIFIC to cooldowns)
-- Lighter version that doesn't clear glow signature - just updates preview if active
-- Use this for continuous slider changes to avoid FPS drops
local function ApplyReadyStateGlowSliderSetting(setter)
  ApplyCooldownSetting(setter)
  if ns.CDMEnhance then
    local icons = GetCooldownIconsToUpdate()
    -- Only refresh preview if active - no signature clearing, no full UpdateIcon
    for _, cdID in ipairs(icons) do
      if ns.CDMEnhanceOptions.IsGlowPreviewActive and ns.CDMEnhanceOptions.IsGlowPreviewActive(cdID) then
        ns.CDMEnhanceOptions.SetGlowPreview(cdID, true)
      end
    end
  end
end

-- Count selected icons for display
local function GetAuraSelectionCount()
  if editAllUnifiedMode then
    -- Use unified cache for count
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    local count = 0
    for _, entry in ipairs(cachedUnifiedIcons) do
      if entry.isAura then count = count + 1 end
    end
    return count
  end
  local count = 0
  for _ in pairs(selectedAuraIcons) do count = count + 1 end
  return count > 0 and count or (selectedAuraIcon and 1 or 0)
end

local function GetCooldownSelectionCount()
  if editAllUnifiedMode then
    -- Use unified cache for count
    if cachedUnifiedFilterMode ~= unifiedFilterMode then
      RebuildUnifiedIconCache()
    end
    local count = 0
    for _, entry in ipairs(cachedUnifiedIcons) do
      if not entry.isAura then count = count + 1 end
    end
    return count
  end
  local count = 0
  for _ in pairs(selectedCooldownIcons) do count = count + 1 end
  return count > 0 and count or (selectedCooldownIcon and 1 or 0)
end

-- ===================================================================
-- UNIFIED CDM ICONS PANEL HELPERS
-- ===================================================================

local function GetUnifiedFilterValues()
  local values = {
    ["auras"] = "|cff00ccffAuras|r",
    ["cooldowns"] = "|cff00ff00Cooldowns|r",
    ["freeposition"] = "|cffff00ffFree Position|r",
  }
  
  if ns.CDMGroups and ns.CDMGroups.groups then
    for groupName, group in pairs(ns.CDMGroups.groups) do
      if group.members and next(group.members) then
        values["group:" .. groupName] = "|cff88ccff" .. groupName .. "|r"
      end
    end
  end
  
  return values
end

-- Note: Forward declared at top of file for use in GetAuraIconsToUpdate/GetCooldownIconsToUpdate
RebuildUnifiedIconCache = function()
  wipe(cachedUnifiedIcons)
  cachedUnifiedFilterMode = unifiedFilterMode
  
  if not ns.CDMEnhance then return end
  
  local auras = ns.CDMEnhance.GetAuraIcons() or {}
  local cooldowns = ns.CDMEnhance.GetCooldownIcons() or {}
  
  -- Helper to create cache entry (shallow copy with isAura flag)
  local function createCacheEntry(data, isAura)
    return {
      cooldownID = data.cooldownID,
      spellID = data.spellID,
      overrideSpellID = data.overrideSpellID,
      name = data.name,
      icon = data.icon,
      hasCustomPos = data.hasCustomPos,
      viewerName = data.viewerName,
      isTotem = data.isTotem,
      totemSlot = data.totemSlot,
      isAura = isAura,
      -- Arc Aura fields
      isArcAura = data.isArcAura,
      arcType = data.arcType,
      itemID = data.itemID,
    }
  end
  
  if unifiedFilterMode == "cooldowns" then
    for cdID, data in pairs(cooldowns) do
      table.insert(cachedUnifiedIcons, createCacheEntry(data, false))
    end
  elseif unifiedFilterMode == "auras" then
    for cdID, data in pairs(auras) do
      table.insert(cachedUnifiedIcons, createCacheEntry(data, true))
    end
  elseif unifiedFilterMode == "freeposition" then
    if ns.CDMGroups and ns.CDMGroups.freeIcons then
      for cdID in pairs(ns.CDMGroups.freeIcons) do
        if auras[cdID] then
          table.insert(cachedUnifiedIcons, createCacheEntry(auras[cdID], true))
        elseif cooldowns[cdID] then
          table.insert(cachedUnifiedIcons, createCacheEntry(cooldowns[cdID], false))
        end
      end
    end
  elseif unifiedFilterMode and unifiedFilterMode:match("^group:") then
    local groupName = unifiedFilterMode:sub(7)
    if ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName] then
      local group = ns.CDMGroups.groups[groupName]
      if group.members then
        for cdID in pairs(group.members) do
          if auras[cdID] then
            table.insert(cachedUnifiedIcons, createCacheEntry(auras[cdID], true))
          elseif cooldowns[cdID] then
            table.insert(cachedUnifiedIcons, createCacheEntry(cooldowns[cdID], false))
          end
        end
      end
    end
  end
  
  table.sort(cachedUnifiedIcons, function(a, b)
    local aID, bID = a.cooldownID or 0, b.cooldownID or 0
    local aType, bType = type(aID), type(bID)
    -- Handle mixed types (string Arc Auras vs numeric CDM IDs)
    if aType ~= bType then
      -- Numbers sort before strings
      return aType == "number"
    end
    return aID < bID
  end)
end

local function GetUnifiedIconByIndex(index)
  if cachedUnifiedFilterMode ~= unifiedFilterMode then
    RebuildUnifiedIconCache()
  end
  return cachedUnifiedIcons[index]
end

local function GetUnifiedIconCount()
  if cachedUnifiedFilterMode ~= unifiedFilterMode then
    RebuildUnifiedIconCache()
  end
  return #cachedUnifiedIcons
end

local function GetUnifiedSelectionCount()
  if editAllUnifiedMode then
    return GetUnifiedIconCount()
  end
  -- Count from both aura and cooldown selections
  local count = 0
  for _ in pairs(selectedAuraIcons) do count = count + 1 end
  for _ in pairs(selectedCooldownIcons) do count = count + 1 end
  if count > 0 then return count end
  if selectedAuraIcon or selectedCooldownIcon then return 1 end
  return 0
end

local function HideIfNoUnifiedSelection()
  return not editAllUnifiedMode 
     and not next(selectedAuraIcons) 
     and not next(selectedCooldownIcons) 
     and selectedAuraIcon == nil 
     and selectedCooldownIcon == nil
end

-- Check if selected icon is an aura (for showing correct options)
local function IsSelectedIconAura()
  return selectedAuraIcon ~= nil or next(selectedAuraIcons)
end

-- Check if selected icon is a cooldown (for showing correct options)
local function IsSelectedIconCooldown()
  return selectedCooldownIcon ~= nil or next(selectedCooldownIcons)
end

-- Create unified catalog icon entry
local function CreateUnifiedCatalogIconEntry(index)
  return {
    type = "execute",
    name = function()
      local entry = GetUnifiedIconByIndex(index)
      if not entry then return "" end
      
      local cdID = entry.cooldownID
      local hasCustom = ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(cdID)
      
      if editAllUnifiedMode then
        return hasCustom and "|cff00ffffAll|r |cffaa55ff*|r" or "|cff00ffffAll|r"
      end
      
      -- Check if selected
      local isSelected = (entry.isAura and (selectedAuraIcon == cdID or selectedAuraIcons[cdID]))
                      or (not entry.isAura and (selectedCooldownIcon == cdID or selectedCooldownIcons[cdID]))
      
      if selectedAuraIcons[cdID] or selectedCooldownIcons[cdID] then
        return hasCustom and "|cff00ff00Multi|r |cffaa55ff*|r" or "|cff00ff00Multi|r"
      elseif isSelected then
        return hasCustom and "|cff00ff00Edit|r |cffaa55ff*|r" or "|cff00ff00Edit|r"
      end
      
      return hasCustom and "|cffaa55ff*|r" or ""
    end,
    desc = function()
      local entry = GetUnifiedIconByIndex(index)
      if not entry then return "" end
      
      local typeColor = entry.isAura and "|cff00ccff" or "|cff00ff00"
      local typeStr = entry.isAura and "Aura" or "Cooldown"
      
      local desc = "|cffffd700" .. (entry.name or "Unknown") .. "|r"
      if entry.spellID then desc = desc .. "\nSpell ID: " .. entry.spellID end
      desc = desc .. "\nCooldown ID: " .. entry.cooldownID
      desc = desc .. "\nType: " .. typeColor .. typeStr .. "|r"
      
      -- Check if this is a charge spell
      if entry.spellID then
        local chargeInfo = nil
        pcall(function() chargeInfo = C_Spell.GetSpellCharges(entry.spellID) end)
        if chargeInfo then
          desc = desc .. "\n|cffff9900Charge Spell|r: " .. (chargeInfo.currentCharges or "?") .. "/" .. (chargeInfo.maxCharges or "?")
        end
      end
      
      local hasCustom = ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(entry.cooldownID)
      if hasCustom then desc = desc .. "\n\n|cffaa55ffCustomized|r" end
      
      desc = desc .. "\n\n|cff888888Click to select  •  Shift+Click multi-select|r"
      return desc
    end,
    func = function()
      local entry = GetUnifiedIconByIndex(index)
      if not entry then return end
      
      local cdID = entry.cooldownID
      
      -- Exit edit-all mode when clicking on specific icon
      if editAllUnifiedMode then
        editAllUnifiedMode = false
        editAllAurasMode = false
        editAllCooldownsMode = false
      end
      
      if IsShiftKeyDown() then
        -- Multi-select
        if entry.isAura then
          -- When starting multi-select, add the currently single-selected icon to the set
          if selectedAuraIcon and not next(selectedAuraIcons) then
            selectedAuraIcons[selectedAuraIcon] = true
          end
          
          if selectedAuraIcons[cdID] then
            selectedAuraIcons[cdID] = nil
          else
            selectedAuraIcons[cdID] = true
            if not selectedAuraIcon then selectedAuraIcon = cdID end
          end
        else
          -- When starting multi-select, add the currently single-selected icon to the set
          if selectedCooldownIcon and not next(selectedCooldownIcons) then
            selectedCooldownIcons[selectedCooldownIcon] = true
          end
          
          if selectedCooldownIcons[cdID] then
            selectedCooldownIcons[cdID] = nil
          else
            selectedCooldownIcons[cdID] = true
            if not selectedCooldownIcon then selectedCooldownIcon = cdID end
          end
        end
      else
        -- Single select - clear all, set one
        wipe(selectedAuraIcons)
        wipe(selectedCooldownIcons)
        
        if entry.isAura then
          if selectedAuraIcon == cdID then
            selectedAuraIcon = nil
          else
            selectedAuraIcon = cdID
            selectedCooldownIcon = nil
          end
        else
          if selectedCooldownIcon == cdID then
            selectedCooldownIcon = nil
          else
            selectedCooldownIcon = cdID
            selectedAuraIcon = nil
          end
        end
      end
      -- Refresh cooldown preview for newly selected icon
      if ns.CDMEnhance and ns.CDMEnhance.RefreshCooldownPreview then
        ns.CDMEnhance.RefreshCooldownPreview()
      end
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end,
    image = function()
      local entry = GetUnifiedIconByIndex(index)
      return entry and entry.icon or nil
    end,
    imageWidth = 32,
    imageHeight = 32,
    order = 10 + index,
    width = 0.25,
    hidden = function()
      return GetUnifiedIconByIndex(index) == nil
    end,
  }
end

-- ===================================================================
-- CATALOG ICON ENTRY CREATOR (AURAS)
-- ===================================================================
local function CreateAuraCatalogIconEntry(index)
  return {
    type = "execute",
    name = function()
      local entry = GetAuraIconByIndex(index)
      if not entry then return "" end
      
      -- Check if this icon has per-icon customizations
      local hasCustom = ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(entry.cooldownID)
      
      -- Show selection state
      if editAllUnifiedMode or editAllAurasMode then
        return hasCustom and "|cff00ffffAll|r |cffaa55ff*|r" or "|cff00ffffAll|r"
      elseif selectedAuraIcons[entry.cooldownID] then
        return hasCustom and "|cff00ff00Multi|r |cffaa55ff*|r" or "|cff00ff00Multi|r"
      elseif selectedAuraIcon == entry.cooldownID then
        return hasCustom and "|cff00ff00Edit|r |cffaa55ff*|r" or "|cff00ff00Edit|r"
      end
      
      -- Not selected - show customized indicator if applicable
      return hasCustom and "|cffaa55ff*|r" or ""
    end,
    desc = function()
      local entry = GetAuraIconByIndex(index)
      if not entry then return "" end
      
      local desc = "|cffffd700" .. (entry.name or "Unknown") .. "|r"
      if entry.spellID then
        desc = desc .. "\nSpell ID: " .. entry.spellID
      end
      desc = desc .. "\nCooldown ID: " .. entry.cooldownID
      desc = desc .. "\nType: |cff00ff00Aura|r"
      
      -- Check if this is a charge spell
      if entry.spellID then
        local chargeInfo = nil
        pcall(function() chargeInfo = C_Spell.GetSpellCharges(entry.spellID) end)
        if chargeInfo then
          desc = desc .. "\n|cffff9900Charge Spell|r: " .. (chargeInfo.currentCharges or "?") .. "/" .. (chargeInfo.maxCharges or "?")
        end
      end
      
      -- Check for per-icon customizations
      local hasCustom = ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(entry.cooldownID)
      if hasCustom then
        desc = desc .. "\n\n|cffaa55ffCustomized|r - Has per-icon settings"
      end
      
      if entry.hasCustomPos then
        desc = desc .. "\n|cff00ff00Custom Position Set|r"
      end
      
      if editAllUnifiedMode or editAllAurasMode then
        desc = desc .. "\n\n|cff00ffffEdit All Mode Active|r"
      elseif selectedAuraIcons[entry.cooldownID] then
        desc = desc .. "\n\n|cff00ff00MULTI-SELECTED|r\n|cff888888Click to remove from selection|r"
      elseif selectedAuraIcon == entry.cooldownID then
        desc = desc .. "\n\n|cff00ff00PRIMARY SELECTION|r"
      else
        desc = desc .. "\n\n|cff888888Click to select\nShift+Click to multi-select|r"
      end
      return desc
    end,
    func = function()
      local entry = GetAuraIconByIndex(index)
      if not entry then return end
      
      -- Exit edit-all modes when clicking on specific icon
      if editAllUnifiedMode or editAllAurasMode then
        editAllUnifiedMode = false
        editAllAurasMode = false
        editAllCooldownsMode = false
      end
      
      -- Check if Shift is held for multi-select
      if IsShiftKeyDown() then
        -- When starting multi-select, add the currently single-selected icon to the set
        if selectedAuraIcon and not next(selectedAuraIcons) then
          selectedAuraIcons[selectedAuraIcon] = true
        end
        
        if selectedAuraIcons[entry.cooldownID] then
          selectedAuraIcons[entry.cooldownID] = nil
        else
          selectedAuraIcons[entry.cooldownID] = true
          -- Also set as primary if none selected
          if not selectedAuraIcon then
            selectedAuraIcon = entry.cooldownID
          end
        end
      else
        -- Normal click - single select (clears multi-select)
        wipe(selectedAuraIcons)
        if selectedAuraIcon == entry.cooldownID then
          selectedAuraIcon = nil
        else
          selectedAuraIcon = entry.cooldownID
        end
      end
      -- Refresh cooldown preview for newly selected icon
      if ns.CDMEnhance and ns.CDMEnhance.RefreshCooldownPreview then
        ns.CDMEnhance.RefreshCooldownPreview()
      end
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end,
    image = function()
      local entry = GetAuraIconByIndex(index)
      if not entry then return nil end
      return entry.icon
    end,
    imageWidth = 32,
    imageHeight = 32,
    order = 10 + index,
    width = 0.25,
    hidden = function()
      return GetAuraIconByIndex(index) == nil
    end,
  }
end

-- ===================================================================
-- CATALOG ICON ENTRY CREATOR (COOLDOWNS)
-- ===================================================================
local function CreateCooldownCatalogIconEntry(index)
  return {
    type = "execute",
    name = function()
      local entry = GetCooldownIconByIndex(index)
      if not entry then return "" end
      
      -- Check if this icon has per-icon customizations
      local hasCustom = ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(entry.cooldownID)
      
      -- Show selection state
      if editAllUnifiedMode or editAllCooldownsMode then
        return hasCustom and "|cff00ffffAll|r |cffaa55ff*|r" or "|cff00ffffAll|r"
      elseif selectedCooldownIcons[entry.cooldownID] then
        return hasCustom and "|cff00ff00Multi|r |cffaa55ff*|r" or "|cff00ff00Multi|r"
      elseif selectedCooldownIcon == entry.cooldownID then
        return hasCustom and "|cff00ff00Edit|r |cffaa55ff*|r" or "|cff00ff00Edit|r"
      end
      
      -- Not selected - show customized indicator if applicable
      return hasCustom and "|cffaa55ff*|r" or ""
    end,
    desc = function()
      local entry = GetCooldownIconByIndex(index)
      if not entry then return "" end
      
      local desc = "|cffffd700" .. (entry.name or "Unknown") .. "|r"
      if entry.spellID then
        desc = desc .. "\nSpell ID: " .. entry.spellID
      end
      desc = desc .. "\nCooldown ID: " .. entry.cooldownID
      desc = desc .. "\nType: |cff00ffccCooldown|r"
      
      -- Check if this is a charge spell
      if entry.spellID then
        local chargeInfo = nil
        pcall(function() chargeInfo = C_Spell.GetSpellCharges(entry.spellID) end)
        if chargeInfo then
          desc = desc .. "\n|cffff9900Charge Spell|r: " .. (chargeInfo.currentCharges or "?") .. "/" .. (chargeInfo.maxCharges or "?")
        end
      end
      
      -- Check for per-icon customizations
      local hasCustom = ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(entry.cooldownID)
      if hasCustom then
        desc = desc .. "\n\n|cffaa55ffCustomized|r - Has per-icon settings"
      end
      
      if entry.hasCustomPos then
        desc = desc .. "\n|cff00ff00Custom Position Set|r"
      end
      
      if editAllUnifiedMode or editAllCooldownsMode then
        desc = desc .. "\n\n|cff00ffffEdit All Mode Active|r"
      elseif selectedCooldownIcons[entry.cooldownID] then
        desc = desc .. "\n\n|cff00ff00MULTI-SELECTED|r\n|cff888888Click to remove from selection|r"
      elseif selectedCooldownIcon == entry.cooldownID then
        desc = desc .. "\n\n|cff00ff00PRIMARY SELECTION|r"
      else
        desc = desc .. "\n\n|cff888888Click to select\nShift+Click to multi-select|r"
      end
      return desc
    end,
    func = function()
      local entry = GetCooldownIconByIndex(index)
      if not entry then return end
      
      -- Exit edit-all modes when clicking on specific icon
      if editAllUnifiedMode or editAllCooldownsMode then
        editAllUnifiedMode = false
        editAllAurasMode = false
        editAllCooldownsMode = false
      end
      
      -- Check if Shift is held for multi-select
      if IsShiftKeyDown() then
        -- When starting multi-select, add the currently single-selected icon to the set
        if selectedCooldownIcon and not next(selectedCooldownIcons) then
          selectedCooldownIcons[selectedCooldownIcon] = true
        end
        
        if selectedCooldownIcons[entry.cooldownID] then
          selectedCooldownIcons[entry.cooldownID] = nil
        else
          selectedCooldownIcons[entry.cooldownID] = true
          -- Also set as primary if none selected
          if not selectedCooldownIcon then
            selectedCooldownIcon = entry.cooldownID
          end
        end
      else
        -- Normal click - single select (clears multi-select)
        wipe(selectedCooldownIcons)
        if selectedCooldownIcon == entry.cooldownID then
          selectedCooldownIcon = nil
        else
          selectedCooldownIcon = entry.cooldownID
        end
      end
      -- Refresh cooldown preview for newly selected icon
      if ns.CDMEnhance and ns.CDMEnhance.RefreshCooldownPreview then
        ns.CDMEnhance.RefreshCooldownPreview()
      end
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end,
    image = function()
      local entry = GetCooldownIconByIndex(index)
      if not entry then return nil end
      return entry.icon
    end,
    imageWidth = 32,
    imageHeight = 32,
    order = 10 + index,
    width = 0.25,
    hidden = function()
      return GetCooldownIconByIndex(index) == nil
    end,
  }
end

-- ===================================================================
-- AURA ICONS OPTIONS TABLE
-- ===================================================================

-- Build dynamic filter values for auras including CDMGroups
local function GetAuraFilterValues()
  local values = {
    ["all"] = "All Auras",
    ["freeposition"] = "Free Position Only",
  }
  
  -- Add CDMGroups group names that contain aura icons
  if ns.CDMGroups and ns.CDMGroups.groups then
    for groupName, group in pairs(ns.CDMGroups.groups) do
      -- Only add groups that have aura icons
      local hasAuras = false
      if group.members then
        for cdID, member in pairs(group.members) do
          if member.viewerType == "aura" or member.originalViewerName == "BuffIconCooldownViewer" then
            hasAuras = true
            break
          else
            -- Check CDM category as fallback (safe for Arc Aura string IDs)
            -- Shared already defined at file level
            local cdInfo = Shared and Shared.SafeGetCDMInfo and Shared.SafeGetCDMInfo(cdID)
            if cdInfo and (cdInfo.category == 2 or cdInfo.category == 3) then
              hasAuras = true
              break
            end
          end
        end
      end
      if hasAuras then
        values["group:" .. groupName] = "|cff00ccff" .. groupName .. "|r"
      end
    end
  end
  
  return values
end

function ns.GetCDMAuraIconsOptionsTable()
  local args = {
    desc = {
      type = "description",
      name = "Customize individual CDM aura icons (BuffIconCooldownViewer). Select an icon below to edit its appearance.",
      order = 1,
    },
    disclaimer = {
      type = "description",
      name = "|cffff8800Note:|r Buffs must be set to |cffffd700Always Display|r in Cooldown Manager for ArcUI to detect them. Buffs set to 'Display only when active' will only appear here while the buff is active.",
      order = 1.5,
      fontSize = "small",
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CONTROLS ROW 1: Main toggles
    -- ═══════════════════════════════════════════════════════════════════
    enableCustomization = {
      type = "toggle",
      name = "|cff00ff00Enable Customization|r",
      desc = "Enable custom styling for aura icons. When disabled, only repositioning works and all custom styles are removed.",
      order = 2,
      width = 1.1,
      get = function() return ns.CDMEnhance and ns.CDMEnhance.IsAuraCustomizationEnabled() end,
      set = function(_, v)
        if ns.CDMEnhance then ns.CDMEnhance.SetAuraCustomizationEnabled(v) end
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CONTROLS ROW 2: Actions
    -- ═══════════════════════════════════════════════════════════════════
    openCDM = {
      type = "execute",
      name = "Open CD Manager",
      desc = "Open the Cooldown Manager settings panel",
      order = 3,
      width = 0.85,
      func = function()
        local frame = _G["CooldownViewerSettings"]
        if frame and frame.Show then
          frame:Show()
          frame:Raise()
        end
      end,
    },
    scanBtn = {
      type = "execute",
      name = "Scan CDM",
      desc = "Rescan CDM viewers for icons",
      order = 3.1,
      width = 0.55,
      func = function()
        if ns.CDMEnhance then
          ns.CDMEnhance.ScanCDM()
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end
      end,
    },
    masqueRefreshBtn = {
      type = "execute",
      name = "Refresh Masque",
      desc = "Force Masque to re-register all frames and refresh skins.\n\nUse this if Masque skins appear broken after zone changes or loading screens.",
      order = 3.2,
      width = 0.7,
      func = function()
        if ns.Masque and ns.Masque.ReregisterAllFrames then
          print("|cff00CCFF[ArcUI]|r Re-registering all frames with Masque...")
          ns.Masque.ReregisterAllFrames()
          print("|cff00FF00[ArcUI]|r Masque frames refreshed")
        elseif ns.Masque and ns.Masque.RefreshAllGroups then
          ns.Masque.RefreshAllGroups()
          print("|cff00FF00[ArcUI]|r Masque skins refreshed")
        else
          print("|cffFFAA00[ArcUI]|r Masque not detected or not active on CDM frames")
        end
      end,
    },
    filterDropdown = {
      type = "select",
      name = "Filter",
      desc = "Filter which aura icons to show",
      values = GetAuraFilterValues,
      get = function() return auraFilterMode end,
      set = function(_, v)
        auraFilterMode = v
        selectedAuraIcon = nil  -- Clear selection when filter changes
        wipe(selectedAuraIcons)
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      order = 4,
      width = 0.85,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- GLOBAL OPTIONS SECTION
    -- ═══════════════════════════════════════════════════════════════════
    globalOptionsHeader = {
      type = "header",
      name = "Global Options",
      order = 5,
    },
    showTooltips = {
      type = "toggle",
      name = "Show Tooltips",
      desc = "When enabled, hovering over icons shows spell tooltips.\n\nWhen disabled, tooltips are hidden on all icons managed by ArcUI.",
      order = 5.1,
      width = 0.9,
      get = function()
        local db = Shared.GetCDMGroupsDB()
        if not db then
          return true  -- Default: show tooltips
        end
        return db.disableTooltips ~= true
      end,
      set = function(_, val)
        local db = Shared.GetCDMGroupsDB()
        if not db then return end
        
        db.disableTooltips = not val
        if ns.CDMGroups and ns.CDMGroups.RefreshIconSettings then
          ns.CDMGroups.RefreshIconSettings()
        end
      end,
    },
    clickThrough = {
      type = "toggle",
      name = "Click-Through",
      desc = "When enabled, icons cannot be clicked - mouse clicks pass through to whatever is behind them.\n\nUseful if icons overlap clickable UI elements.",
      order = 5.2,
      width = 0.9,
      get = function()
        local db = Shared.GetCDMGroupsDB()
        if not db then
          return false  -- Default: clickable
        end
        return db.clickThrough == true
      end,
      set = function(_, val)
        local db = Shared.GetCDMGroupsDB()
        if not db then return end
        
        db.clickThrough = val
        if ns.CDMGroups and ns.CDMGroups.RefreshIconSettings then
          ns.CDMGroups.RefreshIconSettings()
        end
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- MASQUE INTEGRATION OPTIONS
    -- ═══════════════════════════════════════════════════════════════════
    masqueHeader = {
      type = "header",
      name = "Masque Integration",
      order = 8,
      hidden = function()
        return not (ns.Masque and ns.Masque.IsMasqueActive and ns.Masque.IsMasqueActive())
      end,
    },
    masqueDesc = {
      type = "description",
      name = "|cff888888Enable Masque to skin icon borders and textures. When disabled, ArcUI controls everything.|r",
      order = 8.1,
      fontSize = "small",
      hidden = function()
        return not (ns.Masque and ns.Masque.IsMasqueActive and ns.Masque.IsMasqueActive())
      end,
    },
    masqueEnabled = {
      type = "toggle",
      name = "Enable Masque Skinning",
      desc = "When enabled, Masque controls icon borders and textures.\n\nWhen disabled, ArcUI controls everything (zoom, padding, borders).\n\n|cffFFAA00Note:|r Use 'Use Masque Cooldowns' below to choose whether Masque or ArcUI handles cooldown animations.\n\n|cff888888Disabling requires a UI reload to fully remove Masque elements.|r",
      order = 8.2,
      width = 1.2,
      hidden = function()
        return not (ns.Masque and ns.Masque.IsMasqueActive and ns.Masque.IsMasqueActive())
      end,
      get = function()
        if ns.Masque and ns.Masque.IsEnabled then
          return ns.Masque.IsEnabled()
        end
        return false
      end,
      set = function(_, val)
        if ns.Masque and ns.Masque.SetSetting then
          ns.Masque.SetSetting("enabled", val)
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        
        -- Prompt for reload when toggling Masque
        if val then
          StaticPopup_Show("ARCUI_MASQUE_ENABLE_RELOAD")
        else
          StaticPopup_Show("ARCUI_MASQUE_DISABLE_RELOAD")
        end
      end,
    },
    masqueCooldowns = {
      type = "toggle",
      name = "Use Masque Cooldowns",
      desc = "Let Masque control the cooldown animation (swipe overlay, spinning edge, finish flash).\n\n|cff00FF00When enabled:|r Masque's skin handles all cooldown visuals. ArcUI's Cooldown Animation options are hidden.\n\n|cffFFAA00When disabled:|r ArcUI controls cooldown animations with full customization (swipe color, edge scale, insets, etc.).",
      order = 8.25,
      width = 1.2,
      hidden = function()
        return not IsMasqueActive()
      end,
      disabled = function()
        return not IsMasqueActive()
      end,
      get = function()
        if ns.Masque and ns.Masque.ShouldMasqueControlCooldowns then
          return ns.Masque.ShouldMasqueControlCooldowns()
        end
        return false
      end,
      set = function(_, val)
        if ns.Masque and ns.Masque.SetSetting then
          ns.Masque.SetSetting("useMasqueCooldowns", val)
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    masqueZoomNote = {
      type = "description",
      name = "|cffFFAA00When Masque is enabled:|r Zoom, Aspect Ratio, and Padding controls are disabled. Use Masque's settings to adjust icon appearance.",
      order = 8.3,
      fontSize = "small",
      hidden = function()
        return not IsMasqueActive()
      end,
    },
    masqueResetZoom = {
      type = "execute",
      name = "Reset All Zoom Settings",
      desc = "Reset Zoom, Aspect Ratio, and Padding to default (0) for ALL icons.\n\n|cffFF6600Use this if:|r You have old zoom settings from before enabling Masque.",
      order = 8.5,
      width = 1.1,
      hidden = function()
        return not (ns.Masque and ns.Masque.IsMasqueActive and ns.Masque.IsMasqueActive())
      end,
      confirm = true,
      confirmText = "Reset Zoom, Aspect Ratio, and Padding to 0 for ALL icons?\n\nThis cannot be undone.",
      func = function()
        if not ns.CDMEnhance then return end
        local db = Shared.GetCDMGroupsDB()
        if not db or not db.perIcon then return end
        
        local count = 0
        for cdID, settings in pairs(db.perIcon) do
          if settings.zoom or settings.aspectRatio or settings.padding then
            settings.zoom = nil
            settings.aspectRatio = nil
            settings.padding = nil
            count = count + 1
          end
        end
        
        -- Also reset globals
        if db.global then
          db.global.zoom = nil
          db.global.aspectRatio = nil
          db.global.padding = nil
        end
        if db.globalAura then
          db.globalAura.zoom = nil
          db.globalAura.aspectRatio = nil
          db.globalAura.padding = nil
        end
        if db.globalCooldown then
          db.globalCooldown.zoom = nil
          db.globalCooldown.aspectRatio = nil
          db.globalCooldown.padding = nil
        end
        
        -- Invalidate cache and refresh
        if ns.CDMEnhance.InvalidateCache then
          ns.CDMEnhance.InvalidateCache()
        end
        if ns.CDMEnhance.RefreshAllStyles then
          ns.CDMEnhance.RefreshAllStyles()
        end
        
        print("|cff00FF00[ArcUI]|r Reset zoom settings for " .. count .. " icons")
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- ═══════════════════════════════════════════════════════════════════
    -- GROUP SETTINGS - Position and CDM settings for Buff Icons
    -- ═══════════════════════════════════════════════════════════════════
    catalogHeader = {
      type = "header",
      name = function()
        local count = GetAuraSelectionCount()
        if editAllAurasMode then
          return "Icon Catalog |cff00ffff(Editing All: " .. count .. " icons)|r"
        elseif count > 1 then
          return "Icon Catalog |cff00ff00(Multi-Select: " .. count .. " icons)|r"
        end
        return "Icon Catalog"
      end,
      order = 9,
    },
    editAllToggle = {
      type = "toggle",
      name = function()
        if editAllAurasMode then
          return "|cff00ffffEdit All Icons|r"
        end
        return "Edit All Icons"
      end,
      desc = "When enabled, any setting change will apply to ALL aura icons at once",
      order = 9.1,
      width = 0.85,
      get = function() return editAllAurasMode end,
      set = function(_, v)
        editAllAurasMode = v
        if v then
          -- Clear multi-select when entering edit-all mode
          wipe(selectedAuraIcons)
          selectedAuraIcon = nil
          -- Ensure unified mode is off when using separate panel edit-all
          editAllUnifiedMode = false
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    catalogHint = {
      type = "description",
      name = function()
        local hint = "|cff888888Click to select  •  Shift+Click to multi-select"
        hint = hint .. "  •  |cffaa55ff*|r = Customized|r"
        return hint
      end,
      order = 9.5,
      fontSize = "small",
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CURRENTLY EDITING DISPLAY
    -- ═══════════════════════════════════════════════════════════════════
    currentlyEditingHeader = {
      type = "header",
      name = function()
        local count = GetAuraSelectionCount()
        if editAllAurasMode then
          return "|cff00ffffEditing All Auras (" .. count .. " icons)|r"
        elseif count > 1 then
          return "|cff00ff00Editing " .. count .. " Icons|r"
        elseif selectedAuraIcon then
          local icons = ns.CDMEnhance and ns.CDMEnhance.GetAuraIcons() or {}
          for cdID, entry in pairs(icons) do
            if cdID == selectedAuraIcon then
              return "|cff00ff00Editing:|r |cffffd700" .. (entry.name or "Unknown") .. "|r"
            end
          end
          return "|cff00ff00Editing:|r |cffffd700Unknown|r"
        end
        return ""
      end,
      order = 99,
      hidden = function()
        return not editAllAurasMode and not next(selectedAuraIcons) and not selectedAuraIcon
      end,
    },
    
    resetSelectedIconBtn = {
      type = "execute",
      name = "|cffff6666Reset Selected Icon(s)|r",
      desc = "Remove ALL per-icon customizations for the selected icon(s), returning them to default/global settings",
      order = 99.5,
      width = 1.2,
      hidden = HideIfNoAuraSelection,
      confirm = true,
      confirmText = "Remove ALL per-icon customizations for the selected icon(s)? This cannot be undone.",
      func = function()
        local icons = GetAuraIconsToUpdate()
        for _, cdID in ipairs(icons) do
          if ns.CDMEnhance and ns.CDMEnhance.ResetIconToDefaults then
            ns.CDMEnhance.ResetIconToDefaults(cdID)
          end
        end
        if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
          ns.CDMEnhance.InvalidateCache()
        end
        UpdateAura()
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- ICON APPEARANCE SECTION
    -- ═══════════════════════════════════════════════════════════════════
    iconAppearanceHeader = {
      type = "toggle",
      name = function() return GetAuraHeaderName("iconAppearance", "Icon Appearance") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.iconAppearance end,
      set = function(_, v) collapsedSections.iconAppearance = not v end,
      order = 100,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    masqueNotice = {
      type = "description",
      name = "|cffff9900Masque Active:|r Zoom, Aspect Ratio, and Padding are controlled by your Masque skin. Disable the skin group in Masque to use these settings.",
      order = 100.1,
      width = "full",
      fontSize = "medium",
      hidden = function() return collapsedSections.iconAppearance or not IsMasqueActive() end,
    },
    
    useGroupScale = {
      type = "toggle", name = "Group Scale",
      desc = "When Group Scale Override is ON in Group Settings, all icons follow the group scale by default. Disable this to use a custom per-icon scale instead.",
      get = function() 
        local c = GetAuraCfg()
        -- nil or true = follow group, false = opt out
        return not c or c.useGroupScale ~= false
      end,
      set = function(_, v) 
        -- v=true means follow group (store nil to use default behavior)
        -- v=false means opt out (store false explicitly)
        ApplyAuraSetting(function(c) 
          if v then
            c.useGroupScale = nil  -- nil = follow group (default)
            -- Clear custom size values so icon uses group dimensions
            c.width = nil
            c.height = nil
            c.scale = nil
          else
            c.useGroupScale = false  -- false = opt out
          end
        end)
        if ns.CDMEnhance and ns.CDMEnhance.ApplyGroupScaleToIcon then
          local icons = GetAuraIconsToUpdate()
          for _, cdID in ipairs(icons) do
            ns.CDMEnhance.ApplyGroupScaleToIcon(cdID)
          end
        end
      end,
      order = 100.5, width = 0.7, hidden = HideAuraIconAppearance,
    },
    scale = {
      type = "range", name = "Scale", min = 0.25, max = 4.0, step = 0.05,
      desc = "Per-icon scale multiplier (only used when Group Scale is disabled)",
      get = function() local c = GetAuraCfg(); return c and c.scale or 1.0 end,
      set = function(_, v)
        ApplyAuraSetting(function(c) c.scale = v end)
      end,
      order = 101, width = 0.7,
      hidden = function()
        if HideAuraIconAppearance() then return true end
        local c = GetAuraCfg()
        -- Show only when useGroupScale is explicitly false
        return c and c.useGroupScale ~= false
      end,
    },
    iconWidth = {
      type = "range", name = "Width", min = 5, max = 200, step = 1,
      desc = "Icon width in pixels (before scale). Default is CDM's native size (36).",
      get = function() local c = GetAuraCfg(); return c and c.width or 36 end,
      set = function(_, v) ApplyAuraSetting(function(c) c.width = v end) end,
      order = 102, width = 0.65,
      hidden = function()
        if HideAuraIconAppearance() then return true end
        -- Show when icon has opted out of group scale
        local c = GetAuraCfg()
        if c and c.useGroupScale == false then return false end
        -- Hide when group scale override is enabled (group controls size)
        if ns.CDMEnhance and ns.CDMEnhance.IsGroupScaleOverrideEnabled and ns.CDMEnhance.IsGroupScaleOverrideEnabled("aura") then
          return true
        end
        return false
      end,
    },
    iconHeight = {
      type = "range", name = "Height", min = 5, max = 200, step = 1,
      desc = "Icon height in pixels (before scale). Default is CDM's native size (36).",
      get = function() local c = GetAuraCfg(); return c and c.height or 36 end,
      set = function(_, v) ApplyAuraSetting(function(c) c.height = v end) end,
      order = 103, width = 0.65,
      hidden = function()
        if HideAuraIconAppearance() then return true end
        -- Show when icon has opted out of group scale
        local c = GetAuraCfg()
        if c and c.useGroupScale == false then return false end
        -- Hide when group scale override is enabled (group controls size)
        if ns.CDMEnhance and ns.CDMEnhance.IsGroupScaleOverrideEnabled and ns.CDMEnhance.IsGroupScaleOverrideEnabled("aura") then
          return true
        end
        return false
      end,
    },
    aspectRatio = {
      type = "range", name = "Aspect Ratio", min = 0.25, max = 2.5, step = 0.05,
      desc = "Adjusts icon shape. 1 = square, higher = wider, lower = taller.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls icon appearance via its skin settings.",
      get = function() local c = GetAuraCfg(); return c and c.aspectRatio or 1.0 end,
      set = function(_, v) ApplyAuraSetting(function(c) c.aspectRatio = v end) end,
      order = 104, width = 0.85, hidden = HideAuraIconAppearance,
      disabled = IsMasqueActive,
    },
    zoom = {
      type = "range", name = "Zoom", min = 0, max = 0.3, step = 0.01,
      desc = "Crops icon edges for a cleaner look.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls zoom via its skin settings.",
      get = function() local c = GetAuraCfg(); return c and c.zoom or 0.075 end,
      set = function(_, v) ApplyAuraSetting(function(c) c.zoom = v end) end,
      order = 105, width = 0.65, hidden = HideAuraIconAppearance,
      disabled = IsMasqueActive,
    },
    padding = {
      type = "range", name = "Padding", min = -5, max = 20, step = 1,
      desc = "Space between icon and frame edges.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls icon appearance via its skin settings.",
      get = function() local c = GetAuraCfg(); return c and c.padding or 0 end,
      set = function(_, v) ApplyAuraSetting(function(c) c.padding = v end) end,
      order = 106, width = 0.65, hidden = HideAuraIconAppearance,
      disabled = IsMasqueActive,
    },
    alpha = {
      type = "range", name = "Opacity", min = 0, max = 1.0, step = 0.05,
      desc = "Icon visibility (0 = hidden, 1 = fully visible)",
      get = function() local c = GetAuraCfg(); return c and c.alpha or 1.0 end,
      set = function(_, v) ApplyAuraSetting(function(c) c.alpha = v end) end,
      order = 107, width = 0.65, hidden = HideAuraIconAppearance,
    },
    hideShadow = {
      type = "toggle", name = "Hide CDM Shadow",
      desc = "Removes the default shadow around the icon",
      get = function()
        return GetAuraBoolSetting(function(c) return c.hideShadow end, function() local c = GetAuraCfg(); return c and c.hideShadow end)
      end,
      set = function(_, v) ApplyAuraSetting(function(c) c.hideShadow = v end) end,
      order = 107.5, width = 0.85, hidden = HideAuraIconAppearance,
    },
    showDebuffBorder = {
      type = "toggle", name = "Debuff Border",
      desc = "Shows the debuff type colored border (magic=blue, curse=purple, etc.)",
      get = function()
        return GetAuraBoolSetting(function(c) return c.debuffBorder and c.debuffBorder.enabled end, function() local c = GetAuraCfg(); return c and c.debuffBorder and c.debuffBorder.enabled end)
      end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.debuffBorder then c.debuffBorder = {} end; c.debuffBorder.enabled = v end) end,
      order = 107.52, width = 0.8, hidden = HideAuraIconAppearance,
    },
    showPandemicBorder = {
      type = "toggle", name = "Pandemic Glow",
      desc = "Shows the red pandemic glow when aura is at 30% remaining (default: hidden, use Alert Events instead).\n\n|cff888888Note:|r If glow persists after disabling, /reload fixes it. This will be addressed in a future update.",
      get = function()
        return GetAuraBoolSetting(function(c) return c.pandemicBorder and c.pandemicBorder.enabled end, function() local c = GetAuraCfg(); return c and c.pandemicBorder and c.pandemicBorder.enabled end)
      end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.pandemicBorder then c.pandemicBorder = {} end; c.pandemicBorder.enabled = v end) end,
      order = 107.53, width = 0.8, hidden = HideAuraIconAppearance,
    },
    resetIconAppearance = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Icon Appearance settings to defaults for selected icon(s)",
      order = 107.54,
      width = 0.7,
      hidden = HideAuraIconAppearance,
      func = function() ResetAuraSectionSettings("iconAppearance") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- ICON POSITIONING SECTION (collapsible)
    -- ═══════════════════════════════════════════════════════════════════
    iconPositionHeader = {
      type = "toggle",
      name = function() return GetAuraHeaderName("position", "Icon Positioning") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.position end,
      set = function(_, v) collapsedSections.position = not v end,
      order = 107.55,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    iconPositionDesc = {
      type = "description",
      name = function()
        if not ns.CDMEnhance then return "" end
        local cdID = selectedAuraIcon or ns.CDMEnhance.GetFirstIconOfType("aura")
        if not cdID then return "" end
        local mode = ns.CDMEnhance.GetIconPositionMode(cdID)
        if mode == "free" then
          return "|cff00ff00Free Positioned|r - Drag to reposition"
        else
          return "|cffffd700In Group|r - Drag icon out of group to free position"
        end
      end,
      order = 107.57,
      width = "full",
      fontSize = "medium",
      hidden = HideAuraPosition,
    },
    iconPosX = {
      type = "input",
      dialogControl = "ArcUI_EditBox",
      name = "X Offset",
      desc = "Horizontal offset from screen center (0 = center)",
      get = function()
        if not ns.CDMEnhance then return "" end
        local cdID = selectedAuraIcon or ns.CDMEnhance.GetFirstIconOfType("aura")
        if not cdID then return "" end
        local x, y = ns.CDMEnhance.GetIconPosition(cdID)
        return x and tostring(math.floor(x)) or "0"
      end,
      set = function(_, v)
        if not ns.CDMEnhance then return end
        local cdID = selectedAuraIcon or ns.CDMEnhance.GetFirstIconOfType("aura")
        if not cdID then return end
        local x, y = ns.CDMEnhance.GetIconPosition(cdID)
        local newX = tonumber(v)
        if newX then
          ns.CDMEnhance.SetIconPosition(cdID, newX, y or 0)
        end
      end,
      order = 107.7,
      width = 0.45,
      hidden = function()
        if HideAuraPosition() then return true end
        local cdID = selectedAuraIcon or (ns.CDMEnhance and ns.CDMEnhance.GetFirstIconOfType("aura"))
        if not cdID then return true end
        -- Only show for free positioned icons (controlled by CDMGroups)
        return ns.CDMEnhance.GetIconPositionMode(cdID) ~= "free"
      end,
    },
    iconPosY = {
      type = "input",
      dialogControl = "ArcUI_EditBox",
      name = "Y Position",
      desc = "Vertical offset from screen center (0 = center)",
      get = function()
        if not ns.CDMEnhance then return "" end
        local cdID = selectedAuraIcon or ns.CDMEnhance.GetFirstIconOfType("aura")
        if not cdID then return "" end
        local x, y = ns.CDMEnhance.GetIconPosition(cdID)
        return y and tostring(math.floor(y)) or "0"
      end,
      set = function(_, v)
        if not ns.CDMEnhance then return end
        local cdID = selectedAuraIcon or ns.CDMEnhance.GetFirstIconOfType("aura")
        if not cdID then return end
        local x, y = ns.CDMEnhance.GetIconPosition(cdID)
        local newY = tonumber(v)
        if newY then
          ns.CDMEnhance.SetIconPosition(cdID, x or 0, newY)
        end
      end,
      order = 107.8,
      width = 0.45,
      hidden = function()
        if HideAuraPosition() then return true end
        local cdID = selectedAuraIcon or (ns.CDMEnhance and ns.CDMEnhance.GetFirstIconOfType("aura"))
        if not cdID then return true end
        return ns.CDMEnhance.GetIconPositionMode(cdID) == "group"
      end,
    },
    iconPosReset = {
      type = "execute",
      name = "Reset Position",
      desc = "Reset this icon to follow the group layout",
      func = function()
        if not ns.CDMEnhance then return end
        local cdID = selectedAuraIcon or ns.CDMEnhance.GetFirstIconOfType("aura")
        if cdID then
          ns.CDMEnhance.ResetIconPosition(cdID)
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end
      end,
      order = 107.9,
      width = 0.7,
      hidden = function()
        if HideAuraPosition() then return true end
        local cdID = selectedAuraIcon or (ns.CDMEnhance and ns.CDMEnhance.GetFirstIconOfType("aura"))
        if not cdID then return true end
        return ns.CDMEnhance.GetIconPositionMode(cdID) == "group"
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- INACTIVE STATE SECTION (When aura is not active)
    -- ═══════════════════════════════════════════════════════════════════
    -- ACTIVE STATE SECTION (when buff/debuff is applied)
    -- ═══════════════════════════════════════════════════════════════════
    activeStateHeader = {
      type = "toggle",
      name = function() return GetAuraHeaderName("activeState", "Aura Active") end,
      desc = "Click to expand/collapse. Configure how the icon appears when the buff/debuff IS currently on you. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.activeState end,
      set = function(_, v) collapsedSections.activeState = not v end,
      order = 107.81,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    activeStateDesc = {
      type = "description",
      name = "|cff888888Configure how the icon appears when the buff/debuff IS currently on you.|r",
      order = 107.82, width = "full",
      hidden = function() return HideIfNoAuraSelection() or collapsedSections.activeState end,
    },
    activeStateAlpha = {
      type = "range",
      name = "Active Alpha",
      desc = "Icon visibility when active",
      min = 0, max = 1.0, step = 0.05,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.alpha or 1.0
        end
        return 1.0
      end,
      set = function(_, v)
        ApplyAuraOnlySetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.alpha = v
        end)
      end,
      order = 107.83, width = 0.8,
      hidden = function() return HideIfNoAuraSelection() or collapsedSections.activeState end,
    },
    activeStateGlow = {
      type = "toggle",
      name = "Glow When Active",
      desc = "Show a glow effect while the buff/debuff is active",
      get = function()
        return GetAuraOnlyBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow end,
          function()
            local c = GetAuraCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
              return c.cooldownStateVisuals.readyState.glow or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glow = v
        end)
        -- Clear preview when disabling glow
        if not v then
          ns.CDMEnhanceOptions.ClearGlowPreviewForSelection(true)
        end
      end,
      order = 107.84, width = 0.9,
      hidden = function() return HideIfNoAuraSelection() or collapsedSections.activeState end,
    },
    activeStateGlowPreview = {
      type = "toggle",
      name = "Preview",
      desc = "Toggle glow preview for selected icon(s). Preview will automatically stop when you close the options panel.",
      get = function()
        return ns.CDMEnhanceOptions.GetGlowPreviewState(true)
      end,
      set = function(_, v)
        ns.CDMEnhanceOptions.ToggleGlowPreviewForSelection(true)
      end,
      order = 107.8401, width = 0.5,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    activeStateGlowCombatOnly = {
      type = "toggle",
      name = "In Combat Only",
      desc = "Only show the active glow while in combat",
      get = function()
        return GetAuraOnlyBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glowCombatOnly end,
          function()
            local c = GetAuraCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
              return c.cooldownStateVisuals.readyState.glowCombatOnly or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowCombatOnly = v
        end)
        -- If enabling combat-only and not in combat, hide glows immediately
        if v and not InCombatLockdown() and not UnitAffectingCombat("player") then
          local icons = GetAuraIconsToUpdate()
          for _, cdID in ipairs(icons) do
            local data = ns.CDMEnhance and ns.CDMEnhance.GetEnhancedFrameData and ns.CDMEnhance.GetEnhancedFrameData(cdID)
            if data and data.frame and ns.CDMEnhance.HideReadyGlow then
              ns.CDMEnhance.HideReadyGlow(data.frame)
            end
          end
        end
      end,
      order = 107.8405, width = 0.8,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    activeStateGlowType = {
      type = "select",
      name = "Glow Style",
      desc = "Select the glow animation style\n\n|cffffd700Button|r - Classic button glow (default)\n|cffffd700Pixel|r - Rotating pixel lines\n|cffffd700AutoCast|r - Sparkle particles\n|cffffd700Proc|r - Flashy proc effect",
      values = {
        ["pixel"] = "Pixel Glow",
        ["autocast"] = "AutoCast Sparkles",
        ["button"] = "Button Glow (Default)",
        ["proc"] = "Proc Effect",
      },
      sorting = {"button", "pixel", "autocast", "proc"},
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowType or "button"
        end
        return "button"
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowType = v
        end)
      end,
      order = 107.841, width = 0.9,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    activeStateGlowColor = {
      type = "color",
      name = "Color",
      desc = "Glow color",
      hasAlpha = false,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          local col = c.cooldownStateVisuals.readyState.glowColor
          if col then return col.r or 1, col.g or 0.85, col.b or 0.1 end
        end
        return 1, 0.85, 0.1  -- Default gold
      end,
      set = function(_, r, g, b)
        ApplyAuraReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowColor = {r = r, g = g, b = b}
        end)
      end,
      order = 107.842, width = 0.5,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    activeStateGlowIntensity = {
      type = "range",
      name = "Intensity",
      desc = "How bright the glow appears",
      min = 0, max = 1.0, step = 0.05,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowIntensity or 1.0
        end
        return 1.0
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowIntensity = v
        end)
      end,
      order = 107.843, width = 0.6,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    activeStateGlowScale = {
      type = "range",
      name = "Scale",
      desc = "Size of the glow effect",
      min = 0.5, max = 4.0, step = 0.05,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowScale or 1.0
        end
        return 1.0
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowScale = v
        end)
      end,
      order = 107.844, width = 0.55,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        local gt = c.cooldownStateVisuals.readyState.glowType; return gt ~= "autocast" and gt ~= "button"
      end,
    },
    activeStateGlowSpeed = {
      type = "range",
      name = "Speed",
      desc = "How fast the glow animates",
      min = 0.05, max = 1.0, step = 0.05,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowSpeed or 0.25
        end
        return 0.25
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowSpeed = v
        end)
      end,
      order = 107.845, width = 0.55,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        -- Proc glow doesn't use speed
        return c.cooldownStateVisuals.readyState.glowType == "proc"
      end,
    },
    activeStateGlowLines = {
      type = "range",
      name = "Lines",
      desc = "Number of glow lines",
      min = 1, max = 16, step = 1,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowLines or 8
        end
        return 8
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowLines = v
        end)
      end,
      order = 107.846, width = 0.55,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        return c.cooldownStateVisuals.readyState.glowType ~= "pixel"
      end,
    },
    activeStateGlowThickness = {
      type = "range",
      name = "Thickness",
      desc = "Thickness of glow lines",
      min = 1, max = 10, step = 1,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowThickness or 2
        end
        return 2
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowThickness = v
        end)
      end,
      order = 107.847, width = 0.55,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        return c.cooldownStateVisuals.readyState.glowType ~= "pixel"
      end,
    },
    activeStateGlowParticles = {
      type = "range",
      name = "Particles",
      desc = "Number of sparkle groups",
      min = 1, max = 16, step = 1,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowParticles or 4
        end
        return 4
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowParticles = v
        end)
      end,
      order = 107.848, width = 0.55,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        return c.cooldownStateVisuals.readyState.glowType ~= "autocast"
      end,
    },
    activeStateGlowXOffset = {
      type = "range",
      name = "X Offset",
      desc = "Horizontal glow size adjustment",
      min = -50, max = 50, step = 1,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowXOffset or 0
        end
        return 0
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowXOffset = v
        end)
      end,
      order = 107.849, width = 0.55,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        -- Button glow doesn't support offset
        return c.cooldownStateVisuals.readyState.glowType == "button"
      end,
    },
    activeStateGlowYOffset = {
      type = "range",
      name = "Y Offset",
      desc = "Vertical glow size adjustment",
      min = -50, max = 50, step = 1,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowYOffset or 0
        end
        return 0
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowYOffset = v
        end)
      end,
      order = 107.8495, width = 0.55,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        -- Button glow doesn't support offset
        return c.cooldownStateVisuals.readyState.glowType == "button"
      end,
    },
    activeStateGlowThreshold = {
      type = "range",
      name = "Threshold %",
      desc = "Show glow when remaining duration is at or below this percentage.\n\n|cffffd700100%|r = Always glow when active\n|cffffd70030%|r = Pandemic window (glow when ≤30% remaining)",
      min = 0.05, max = 1.0, step = 0.05,
      isPercent = true,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowThreshold or 1.0
        end
        return 1.0
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowThreshold = v
        end)
      end,
      order = 107.8406, width = 0.7,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    activeStateGlowAuraType = {
      type = "select",
      name = "Check On",
      desc = "Where to check for this aura's duration.\n\n|cffffd700Buff (Player)|r = Check player buffs\n|cffffd700Debuff (Target)|r = Check target debuffs",
      values = { buff = "Buff (Player)", debuff = "Debuff (Target)" },
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          local val = c.cooldownStateVisuals.readyState.glowAuraType
          -- Convert old "auto" to "buff" as default
          if val == "auto" or not val then return "buff" end
          return val
        end
        return "buff"
      end,
      set = function(_, v)
        ApplyAuraReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowAuraType = v
        end)
      end,
      order = 107.8407, width = 0.85,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.activeState then return true end
        local c = GetAuraCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        -- Only show if threshold is < 100%
        local threshold = c.cooldownStateVisuals.readyState.glowThreshold or 1.0
        return threshold >= 1.0
      end,
    },
    resetActiveState = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Aura Active settings to defaults for selected icon(s)",
      order = 107.89,
      width = 0.7,
      hidden = function() return HideIfNoAuraSelection() or collapsedSections.activeState end,
      func = function() ResetAuraSectionSettings("activeState") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- INACTIVE STATE SECTION (when buff/debuff is not applied)
    -- ═══════════════════════════════════════════════════════════════════
    inactiveStateHeader = {
      type = "toggle",
      name = function() return GetAuraHeaderName("inactiveState", "Aura Missing") end,
      desc = "Click to expand/collapse. Configure how the icon appears when the buff/debuff is NOT currently on you. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.inactiveState end,
      set = function(_, v) collapsedSections.inactiveState = not v end,
      order = 107.91,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    inactiveStateDesc = {
      type = "description",
      name = "|cff888888Configure how the icon appears when the buff/debuff is NOT currently on you.|r",
      order = 107.92, width = "full",
      hidden = function() return HideIfNoAuraSelection() or collapsedSections.inactiveState end,
    },
    inactiveStateAlpha = {
      type = "range",
      name = "Inactive Alpha",
      desc = "Icon visibility when inactive",
      min = 0, max = 1.0, step = 0.05,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState then
          return c.cooldownStateVisuals.cooldownState.alpha or 1.0
        end
        return 1.0
      end,
      set = function(_, v)
        ApplyAuraOnlySetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.cooldownState then c.cooldownStateVisuals.cooldownState = {} end
          c.cooldownStateVisuals.cooldownState.alpha = v
        end)
      end,
      order = 107.93, width = 0.8,
      hidden = function() return HideIfNoAuraSelection() or collapsedSections.inactiveState end,
    },
    inactiveStateDesaturate = {
      type = "toggle",
      name = "Desaturate",
      desc = "Make icon grayscale when inactive",
      get = function()
        return GetAuraOnlyBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState and c.cooldownStateVisuals.cooldownState.desaturate end,
          function()
            local c = GetAuraCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState then
              return c.cooldownStateVisuals.cooldownState.desaturate or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyAuraOnlySetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.cooldownState then c.cooldownStateVisuals.cooldownState = {} end
          c.cooldownStateVisuals.cooldownState.desaturate = v
        end)
        -- Force immediate visual update
        if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
          ns.CDMEnhance.RefreshIconType("aura")
        end
      end,
      order = 107.94, width = 0.55,
      hidden = function() return HideIfNoAuraSelection() or collapsedSections.inactiveState end,
    },
    inactiveStateTint = {
      type = "toggle",
      name = "Color Tint",
      desc = "Apply a color tint to the icon when inactive",
      get = function()
        return GetAuraOnlyBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState and c.cooldownStateVisuals.cooldownState.tint end,
          function()
            local c = GetAuraCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState then
              return c.cooldownStateVisuals.cooldownState.tint or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyAuraOnlySetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.cooldownState then c.cooldownStateVisuals.cooldownState = {} end
          c.cooldownStateVisuals.cooldownState.tint = v
        end)
        if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
          ns.CDMEnhance.RefreshIconType("aura")
        end
      end,
      order = 107.95, width = 0.55,
      hidden = function() return HideIfNoAuraSelection() or collapsedSections.inactiveState end,
    },
    inactiveStateTintColor = {
      type = "color",
      name = "Tint",
      desc = "Color to tint the icon when inactive",
      hasAlpha = false,
      get = function()
        local c = GetAuraCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState then
          local col = c.cooldownStateVisuals.cooldownState.tintColor
          if col then return col.r or 0.5, col.g or 0.5, col.b or 0.5 end
        end
        return 0.5, 0.5, 0.5
      end,
      set = function(_, r, g, b)
        ApplyAuraOnlySetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.cooldownState then c.cooldownStateVisuals.cooldownState = {} end
          c.cooldownStateVisuals.cooldownState.tintColor = {r = r, g = g, b = b}
        end)
        if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
          ns.CDMEnhance.RefreshIconType("aura")
        end
      end,
      order = 107.96, width = 0.35,
      hidden = function()
        if HideIfNoAuraSelection() or collapsedSections.inactiveState then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState and c.cooldownStateVisuals.cooldownState.tint)
      end,
    },
    resetInactiveState = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Aura Missing settings to defaults for selected icon(s)",
      order = 107.99,
      width = 0.7,
      hidden = function() return HideIfNoAuraSelection() or collapsedSections.inactiveState end,
      func = function() ResetAuraSectionSettings("inactiveState") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- RANGE INDICATOR SECTION
    -- ═══════════════════════════════════════════════════════════════════
    rangeIndicatorHeader = {
      type = "toggle",
      name = function() return GetAuraHeaderName("rangeIndicator", "Range Indicator") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.rangeIndicator end,
      set = function(_, v) collapsedSections.rangeIndicator = not v end,
      order = 108,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    rangeEnabled = {
      type = "toggle", name = "Show Range Overlay",
      desc = "Show the out-of-range darkening overlay when spells are out of range",
      get = function() return GetAuraBoolSetting(function(c) return c and c.rangeIndicator and c.rangeIndicator.enabled ~= false end, function() local c = GetAuraCfg(); return c and c.rangeIndicator and c.rangeIndicator.enabled ~= false end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.rangeIndicator then c.rangeIndicator = {} end; c.rangeIndicator.enabled = v end) end,
      order = 108.1, width = 1.0, hidden = HideAuraRangeIndicator,
    },
    resetRangeIndicator = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Range Indicator settings to defaults for selected icon(s)",
      order = 108.9,
      width = 0.7,
      hidden = HideAuraRangeIndicator,
      func = function() ResetAuraSectionSettings("rangeIndicator") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- PROC GLOW SECTION (HIDDEN - Coming Soon)
    -- ═══════════════════════════════════════════════════════════════════
    procGlowHeader = {
      type = "toggle",
      name = function() return GetAuraHeaderName("procGlow", "Proc Glow") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.procGlow end,
      set = function(_, v) collapsedSections.procGlow = not v end,
      order = 109,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    procGlowEnabled = {
      type = "toggle", name = "Show Glow",
      desc = "Show the proc glow animation when ability procs",
      get = function() return GetAuraBoolSetting(function(c) return c and c.procGlow and c.procGlow.enabled ~= false end, function() local c = GetAuraCfg(); return c and c.procGlow and c.procGlow.enabled ~= false end) end,
      set = function(_, v) ApplyAuraGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.enabled = v end) end,
      order = 109.1, width = 0.6, hidden = HideAuraProcGlow,
    },
    procGlowPreview = {
      type = "toggle", name = "Preview",
      desc = "Toggle proc glow preview for selected icon(s). Preview will automatically stop when you close the options panel.",
      get = function()
        return ns.CDMEnhanceOptions.GetProcGlowPreviewState(true)
      end,
      set = function(_, v)
        ns.CDMEnhanceOptions.ToggleProcGlowPreviewForSelection(true)
      end,
      order = 109.11, width = 0.5, hidden = HideAuraProcGlow,
    },
    procGlowType = {
      type = "select", name = "Glow Style",
      desc = "Select the glow animation style\n\n|cffffd700Default|r - Blizzard's proc glow with proper sizing\n|cffffd700Proc|r - LibCustomGlow flashy proc effect\n|cffffd700Pixel|r - Rotating pixel lines\n|cffffd700AutoCast|r - Sparkle particles\n|cffffd700Button|r - Classic button glow",
      values = {
        ["default"] = "Default (Blizzard)",
        ["pixel"] = "Pixel Glow",
        ["autocast"] = "AutoCast Sparkles",
        ["button"] = "Button Glow",
        ["proc"] = "Proc Effect",
      },
      sorting = {"default", "proc", "pixel", "autocast", "button"},
      get = function() local c = GetAuraCfg(); return c and c.procGlow and c.procGlow.glowType or "default" end,
      set = function(_, v) ApplyAuraGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.glowType = v end) end,
      order = 109.15, width = 0.8, hidden = HideAuraProcGlow,
    },
    procGlowColor = {
      type = "color", name = "Color",
      desc = "Glow color (white = default gold for custom types)",
      get = function()
        local c = GetAuraCfg()
        local col = c and c.procGlow and c.procGlow.color
        if col then return col.r or 1, col.g or 1, col.b or 1 end
        return 1, 1, 1
      end,
      set = function(_, r, g, b)
        ApplyAuraGlowSetting(function(c)
          if not c.procGlow then c.procGlow = {} end
          if r == 1 and g == 1 and b == 1 then
            c.procGlow.color = nil  -- Reset to default
          else
            c.procGlow.color = {r=r, g=g, b=b}
          end
        end)
      end,
      order = 109.2, width = 0.55,
      hidden = function()
        if HideAuraProcGlow() then return true end
        local c = GetAuraCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Hide for default type (color breaks Blizzard animation)
        return glowType == "default"
      end,
    },
    procGlowAlpha = {
      type = "range", name = "Intensity", min = 0, max = 1.0, step = 0.05,
      desc = "How bright the glow appears",
      get = function() local c = GetAuraCfg(); return c and c.procGlow and c.procGlow.alpha or 1.0 end,
      set = function(_, v) ApplyAuraGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.alpha = v end) end,
      order = 109.25, width = 0.6,
      hidden = function()
        if HideAuraProcGlow() then return true end
        local c = GetAuraCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Hide for default type (alpha changes can break Blizzard animation)
        return glowType == "default"
      end,
    },
    procGlowScale = {
      type = "range", name = "Scale", min = 0.25, max = 4.0, step = 0.05,
      desc = "Size of the glow effect",
      get = function() local c = GetAuraCfg(); return c and c.procGlow and c.procGlow.scale or 1.0 end,
      set = function(_, v) ApplyAuraGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.scale = v end) end,
      order = 109.3, width = 0.55, 
      hidden = function()
        if HideAuraProcGlow() then return true end
        local c = GetAuraCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Show for autocast and button types (scale works via SetScale)
        return glowType ~= "autocast" and glowType ~= "button"
      end,
    },
    procGlowSpeed = {
      type = "range", name = "Speed", min = 0.05, max = 1.0, step = 0.05,
      desc = "Animation speed (Pixel, AutoCast, Button only)",
      get = function() local c = GetAuraCfg(); return c and c.procGlow and c.procGlow.speed or 0.25 end,
      set = function(_, v) ApplyAuraGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.speed = v end) end,
      order = 109.35, width = 0.55,
      hidden = function()
        if HideAuraProcGlow() then return true end
        local c = GetAuraCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Speed doesn't apply to default or proc types
        return glowType == "default" or glowType == "proc"
      end,
    },
    procGlowLines = {
      type = "range", name = "Lines", min = 1, max = 16, step = 1,
      desc = "Number of glow lines",
      get = function() local c = GetAuraCfg(); return c and c.procGlow and c.procGlow.lines or 8 end,
      set = function(_, v) ApplyAuraGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.lines = v end) end,
      order = 109.4, width = 0.6,
      hidden = function()
        if HideAuraProcGlow() then return true end
        local c = GetAuraCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Only show for pixel type
        return glowType ~= "pixel"
      end,
    },
    procGlowThickness = {
      type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
      desc = "Thickness of glow lines",
      get = function() local c = GetAuraCfg(); return c and c.procGlow and c.procGlow.thickness or 2 end,
      set = function(_, v) ApplyAuraGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.thickness = v end) end,
      order = 109.45, width = 0.65,
      hidden = function()
        if HideAuraProcGlow() then return true end
        local c = GetAuraCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Only show for pixel type
        return glowType ~= "pixel"
      end,
    },
    procGlowParticles = {
      type = "range", name = "Particles", min = 1, max = 16, step = 1,
      desc = "Number of sparkle groups",
      get = function() local c = GetAuraCfg(); return c and c.procGlow and c.procGlow.particles or 4 end,
      set = function(_, v) ApplyAuraGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.particles = v end) end,
      order = 109.5, width = 0.6,
      hidden = function()
        if HideAuraProcGlow() then return true end
        local c = GetAuraCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Only show for autocast type
        return glowType ~= "autocast"
      end,
    },
    resetProcGlow = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Proc Glow settings to defaults for selected icon(s)",
      order = 109.59,
      width = 0.7,
      hidden = HideAuraProcGlow,
      func = function() ResetAuraSectionSettings("procGlow") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- ALERT EVENTS SECTION (Auras) - Coming Soon
    -- ═══════════════════════════════════════════════════════════════════
    alertEventsHeader = {
      type = "toggle",
      name = "|cff666666Alert Events|r",
      desc = "Alert Events for auras - Coming Soon!",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.alertEvents end,
      set = function(_, v) collapsedSections.alertEvents = not v end,
      order = 109.6,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    alertEventsComingSoon = {
      type = "description",
      name = "\n|cff888888Alert Events for auras are |cffFFCC00Coming Soon|r!|r\n\n|cff666666This feature will allow you to trigger sounds, glows, or visual changes when:\n• Buff is applied\n• Buff enters pandemic window (30% remaining)\n• Buff expires|r\n",
      order = 109.61,
      width = "full",
      hidden = HideAuraAlertEvents,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- BORDER SECTION
    -- ═══════════════════════════════════════════════════════════════════
    borderHeader = {
      type = "toggle",
      name = function() return GetAuraHeaderName("border", "Border") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.border end,
      set = function(_, v) collapsedSections.border = not v end,
      order = 110,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    borderEnabled = {
      type = "toggle", name = "Show Border",
      get = function() return GetAuraBoolSetting(function(c) return c and c.border and c.border.enabled end, function() local c = GetAuraCfg(); return c and c.border and c.border.enabled end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.border then c.border = {} end; c.border.enabled = v end) end,
      order = 111, width = 0.7, hidden = HideAuraBorder,
    },
    borderUseClass = {
      type = "toggle", name = "Class Color",
      get = function() return GetAuraBoolSetting(function(c) return c and c.border and c.border.useClassColor end, function() local c = GetAuraCfg(); return c and c.border and c.border.useClassColor end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.border then c.border = {} end; c.border.useClassColor = v end) end,
      order = 112, width = 0.7, hidden = HideAuraBorder,
    },
    borderThickness = {
      type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
      get = function() local c = GetAuraCfg(); return c and c.border and c.border.thickness or 1 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.border then c.border = {} end; c.border.thickness = v end) end,
      order = 113, width = 0.6, hidden = HideAuraBorder,
    },
    borderInset = {
      type = "range", name = "Offset", min = -20, max = 20, step = 1,
      desc = "Border position offset. Negative = outset (outside icon), Positive = inset (inside icon). Automatically accounts for zoom.",
      get = function() local c = GetAuraCfg(); return c and c.border and c.border.inset or 0 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.border then c.border = {} end; c.border.inset = v end) end,
      order = 114, width = 0.6, hidden = HideAuraBorder,
    },
    borderColor = {
      type = "color", name = "Color", hasAlpha = true,
      desc = "Border color (ignored if using class color)",
      get = function()
        local c = GetAuraCfg()
        local col = c and c.border and c.border.color or {1,1,1,1}
        return col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1
      end,
      set = function(_, r, g, b, a)
        ApplyAuraSetting(function(c) if not c.border then c.border = {} end; c.border.color = {r, g, b, a} end)
      end,
      order = 115, width = 0.55, hidden = HideAuraBorder,
    },
    borderFollowDesat = {
      type = "toggle", name = "Follow Desat",
      desc = "Desaturate border when icon is desaturated (cooldown state)",
      get = function() return GetAuraBoolSetting(function(c) return c and c.border and c.border.followDesaturation end, function() local c = GetAuraCfg(); return c and c.border and c.border.followDesaturation end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.border then c.border = {} end; c.border.followDesaturation = v end) end,
      order = 116, width = 0.65, hidden = HideAuraBorder,
    },
    resetBorder = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Border settings to defaults for selected icon(s)",
      order = 119,
      width = 0.7,
      hidden = HideAuraBorder,
      func = function() ResetAuraSectionSettings("border") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- COOLDOWN SWIPE SECTION
    -- ═══════════════════════════════════════════════════════════════════
    cooldownSwipeHeader = {
      type = "toggle",
      name = function() 
        local baseName = GetAuraHeaderName("cooldownSwipe", "Cooldown Animation")
        if IsMasqueCooldownsActive() then
          return baseName .. " |cff00CCFF(Masque)|r"
        end
        return baseName
      end,
      desc = function()
        if IsMasqueCooldownsActive() then
          return "|cff00CCFFMasque controls most cooldown settings.|r You can still change swipe COLOR here (works in combat). Other options require disabling 'Use Masque Cooldowns' in Global Options."
        end
        return "Click to expand/collapse. Purple dot indicates per-icon customizations."
      end,
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.cooldownSwipe end,
      set = function(_, v) collapsedSections.cooldownSwipe = not v end,
      order = 120,
      width = "full",
      hidden = HideIfNoAuraSelection,
      -- NOT disabled - users need to expand this to access swipe color options
    },
    -- Row 1: Preview + Finish Flash + No GCD
    cooldownPreview = {
      type = "toggle", name = "Preview",
      desc = "Show a preview cooldown animation to see your changes in real-time",
      get = function() return ns.CDMEnhance and ns.CDMEnhance.IsCooldownPreviewMode() end,
      set = function(_, v) 
        if ns.CDMEnhance then 
          ns.CDMEnhance.SetCooldownPreviewMode(v) 
        end 
      end,
      order = 120.1, width = 0.5, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    showBling = {
      type = "toggle", name = "Finish Flash",
      desc = "Flash when cooldown finishes",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.showBling ~= false end, function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.showBling ~= false end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.showBling = v end) end,
      order = 120.2, width = 0.7, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipeExceptBling,
    },
    noGCDSwipe = {
      type = "toggle", name = "No GCD",
      desc = "Hide GCD swipes (cooldowns 1.5s or less). Only shows the swipe animation for actual spell cooldowns.",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.noGCDSwipe end, function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.noGCDSwipe or false end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.noGCDSwipe = v end) end,
      order = 120.3, width = 0.5, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipeExceptNoGCD,
    },
    swipeWaitForNoCharges = {
      type = "toggle", name = "Wait No Charges",
      desc = "For charge spells: Only show swipe when ALL charges are consumed. When disabled, shows swipe during any charge recharge.",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.swipeWaitForNoCharges end, function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeWaitForNoCharges or false end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeWaitForNoCharges = v end) end,
      order = 120.4, width = 0.7, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- SWIPE (the darkening overlay)
    -- ═══════════════════════════════════════════════════════════════════
    swipeSpacer = { type = "description", name = "", order = 121, width = "full", hidden = HideAuraCooldownSwipe },
    swipeLabel = {
      type = "description", name = "|cffccccccSwipe|r",
      order = 121.05, width = 0.35, fontSize = "medium", hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    showSwipe = {
      type = "toggle", name = "Show",
      desc = "The darkening clock animation overlay",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.showSwipe ~= false end, function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.showSwipe ~= false end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.showSwipe = v end) end,
      order = 121.1, width = 0.4, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    reverseSwipe = {
      type = "toggle", name = "Reverse",
      desc = "Reverse the swipe direction",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.reverse end, function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.reverse end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.reverse = v end) end,
      order = 121.2, width = 0.5, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    useCustomSwipeColor = {
      type = "toggle", name = "Color",
      desc = function()
        if IsMasqueCooldownsActive() then
          return "|cff00CCFFMasque controls swipe color.|r ArcUI applies Masque's skin color using a method that works in combat."
        end
        return "Use a custom swipe color instead of the default"
      end,
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.swipeColor ~= nil end, function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeColor ~= nil end) end,
      set = function(_, v)
        ApplyAuraSetting(function(c)
          if not c.cooldownSwipe then c.cooldownSwipe = {} end
          if v then
            c.cooldownSwipe.swipeColor = {r=0, g=0, b=0, a=0.8}
          else
            c.cooldownSwipe.swipeColor = nil
          end
        end)
      end,
      order = 121.3, width = 0.4, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipeExceptColor,
    },
    swipeColor = {
      type = "color", name = "", hasAlpha = true,
      desc = "Color of the swipe overlay",
      get = function()
        local c = GetAuraCfg()
        local col = c and c.cooldownSwipe and c.cooldownSwipe.swipeColor or {r=0,g=0,b=0,a=0.8}
        return col.r or 0, col.g or 0, col.b or 0, col.a or 0.8
      end,
      set = function(_, r, g, b, a)
        ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeColor = {r=r, g=g, b=b, a=a} end)
      end,
      order = 121.4, width = 0.3,
      hidden = function()
        if HideAuraCooldownSwipe() then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownSwipe and c.cooldownSwipe.swipeColor)
      end,
    },
    -- Swipe Inset (same row as swipe)
    swipeInset = {
      type = "range", name = "Inset", min = -20, max = 40, step = 1,
      desc = "Inset for the swipe animation (all sides). Positive = smaller, negative = larger.",
      get = function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeInset or 0 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeInset = v end) end,
      order = 121.5, width = 0.7,
      hidden = function()
        if HideAuraCooldownSwipe() then return true end
        local c = GetAuraCfg()
        return c and c.cooldownSwipe and c.cooldownSwipe.separateInsets
      end,
    },
    separateInsets = {
      type = "toggle", name = "W/H",
      desc = "Enable separate Width and Height insets instead of a single inset",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.separateInsets end, function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.separateInsets end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.separateInsets = v end) end,
      order = 121.6, width = 0.35, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    swipeInsetX = {
      type = "range", name = "Inset W", min = -20, max = 40, step = 1,
      desc = "Horizontal inset (left/right). Positive = narrower, negative = wider.",
      get = function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeInsetX or 0 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeInsetX = v end) end,
      order = 121.7, width = 0.55,
      hidden = function()
        if HideAuraCooldownSwipe() then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownSwipe and c.cooldownSwipe.separateInsets)
      end,
    },
    swipeInsetY = {
      type = "range", name = "H", min = -20, max = 40, step = 1,
      desc = "Vertical inset (top/bottom). Positive = shorter, negative = taller.",
      get = function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeInsetY or 0 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeInsetY = v end) end,
      order = 121.8, width = 0.45,
      hidden = function()
        if HideAuraCooldownSwipe() then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownSwipe and c.cooldownSwipe.separateInsets)
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- EDGE (the spinning line)
    -- ═══════════════════════════════════════════════════════════════════
    edgeSpacer = { type = "description", name = "", order = 122, width = "full", hidden = HideAuraCooldownSwipe },
    edgeLabel = {
      type = "description", name = "|cffccccccEdge|r",
      order = 122.05, width = 0.35, fontSize = "medium", hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    showEdge = {
      type = "toggle", name = "Show",
      desc = "The spinning bright line on the cooldown edge",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.showEdge ~= false end, function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.showEdge ~= false end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.showEdge = v end) end,
      order = 122.1, width = 0.4, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    edgeScale = {
      type = "range", name = "Scale", min = 0.1, max = 3.0, step = 0.1,
      desc = "Size of the cooldown edge spinner",
      get = function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.edgeScale or 1.0 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.edgeScale = v end) end,
      order = 122.2, width = 0.6, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    edgeColorEnabled = {
      type = "toggle", name = "Color",
      desc = "Enable custom edge color",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.edgeColor ~= nil end, function() local c = GetAuraCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.edgeColor ~= nil end) end,
      set = function(_, v)
        ApplyAuraSetting(function(c) 
          if not c.cooldownSwipe then c.cooldownSwipe = {} end
          if v then
            c.cooldownSwipe.edgeColor = {r=1, g=1, b=1, a=1}
          else
            c.cooldownSwipe.edgeColor = nil
          end
        end)
      end,
      order = 122.3, width = 0.4, hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
    },
    edgeColor = {
      type = "color", name = "", hasAlpha = true,
      desc = "Color of the spinning edge line",
      get = function()
        local c = GetAuraCfg()
        local col = c and c.cooldownSwipe and c.cooldownSwipe.edgeColor or {r=1,g=1,b=1,a=1}
        return col.r or 1, col.g or 1, col.b or 1, col.a or 1
      end,
      set = function(_, r, g, b, a)
        ApplyAuraSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.edgeColor = {r=r, g=g, b=b, a=a} end)
      end,
      order = 122.4, width = 0.3,
      hidden = function()
        if HideAuraCooldownSwipe() then return true end
        local c = GetAuraCfg()
        return not (c and c.cooldownSwipe and c.cooldownSwipe.edgeColor)
      end,
    },
    
    resetSpacer = { type = "description", name = "", order = 128, width = "full", hidden = HideAuraCooldownSwipe },
    resetCooldownSwipe = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Cooldown Animation settings to defaults for selected icon(s)",
      order = 129,
      width = 0.7,
      hidden = HideAuraCooldownSwipe, disabled = DisableAuraCooldownSwipe,
      func = function() ResetAuraSectionSettings("cooldownSwipe") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CHARGE TEXT SECTION
    -- ═══════════════════════════════════════════════════════════════════
    chargeTextHeader = {
      type = "toggle",
      name = function() return GetAuraHeaderName("chargeText", "Charge/Stack Text") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.chargeText end,
      set = function(_, v) collapsedSections.chargeText = not v end,
      order = 130,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    chargeEnabled = {
      type = "toggle", name = "Show",
      get = function() return GetAuraBoolSetting(function(c) return c and c.chargeText and c.chargeText.enabled ~= false end, function() local c = GetAuraCfg(); return c and c.chargeText and c.chargeText.enabled ~= false end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.enabled = v end) end,
      order = 131, width = 0.55, hidden = HideAuraChargeText,
    },
    chargeTextDrag = {
      type = "toggle", name = "Text Drag",
      desc = "Enable dragging charge/stack text to custom positions",
      get = function() return ns.CDMEnhance and ns.CDMEnhance.IsTextDragMode() end,
      set = function(_, v) if ns.CDMEnhance then ns.CDMEnhance.SetTextDragMode(v) end end,
      order = 131.6, width = 0.6, hidden = HideAuraChargeText,
    },
    chargeSize = {
      type = "range", name = "Size", min = 4, max = 64, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.chargeText and c.chargeText.size or 16 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.size = v end) end,
      order = 132, width = 0.6, hidden = HideAuraChargeText,
    },
    chargeColor = {
      type = "color", name = "Color", hasAlpha = true,
      get = function()
        local c = GetAuraCfg()
        local col = c and c.chargeText and c.chargeText.color or {r=1,g=1,b=0,a=1}
        return col.r or 1, col.g or 1, col.b or 0, col.a or 1
      end,
      set = function(_, r, g, b, a)
        ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.color = {r=r, g=g, b=b, a=a} end)
      end,
      order = 133, width = 0.55, hidden = HideAuraChargeText,
    },
    chargeFont = {
      type = "select", name = "Font", dialogControl = "LSM30_Font",
      values = LSM and LSM:HashTable("font") or {},
      get = function() local c = GetAuraCfg(); return c and c.chargeText and c.chargeText.font or "Friz Quadrata TT" end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.font = v end) end,
      order = 134, width = 0.9, hidden = HideAuraChargeText,
    },
    chargeOutline = {
      type = "select", name = "Outline", values = FONT_OUTLINES,
      get = function() local c = GetAuraCfg(); return GetOutlineValue(c and c.chargeText and c.chargeText.outline) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.outline = v end) end,
      order = 135, width = 0.85, hidden = HideAuraChargeText,
    },
    chargeShadow = {
      type = "toggle", name = "Shadow",
      get = function() return GetAuraBoolSetting(function(c) return c and c.chargeText and c.chargeText.shadow end, function() local c = GetAuraCfg(); return c and c.chargeText and c.chargeText.shadow end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.shadow = v end) end,
      order = 136, width = 0.55, hidden = HideAuraChargeText,
    },
    chargeShadowX = {
      type = "range", name = "Shadow X", min = -20, max = 20, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.chargeText and c.chargeText.shadowOffsetX or 1 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.shadowOffsetX = v end) end,
      order = 137, width = 0.6, hidden = function() return HideAuraChargeText() or not (GetAuraCfg() and GetAuraCfg().chargeText and GetAuraCfg().chargeText.shadow) end,
    },
    chargeShadowY = {
      type = "range", name = "Shadow Y", min = -20, max = 20, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.chargeText and c.chargeText.shadowOffsetY or -1 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.shadowOffsetY = v end) end,
      order = 138, width = 0.6, hidden = function() return HideAuraChargeText() or not (GetAuraCfg() and GetAuraCfg().chargeText and GetAuraCfg().chargeText.shadow) end,
    },
    
    -- Position Mode
    chargePositionHeader = {
      type = "description", name = "\n|cffffd700Position|r", order = 139, width = "full", hidden = HideAuraChargeText,
    },
    chargeMode = {
      type = "select", name = "Mode", values = TEXT_MODES,
      desc = "Anchor = fixed position. Free = drag anywhere (automatically enables Text Drag Mode)",
      get = function() local c = GetAuraCfg(); return c and c.chargeText and c.chargeText.mode or "anchor" end,
      set = function(_, v)
        ApplyAuraSetting(function(c)
          if not c.chargeText then c.chargeText = {} end
          c.chargeText.mode = v
        end)
        -- Auto-enable text drag mode when switching to free
        if v == "free" and ns.CDMEnhance and not ns.CDMEnhance.IsTextDragMode() then
          ns.CDMEnhance.SetTextDragMode(true)
        end
      end,
      order = 140, width = 0.85, hidden = HideAuraChargeText,
    },
    chargeAnchor = {
      type = "select", name = "Anchor", values = TEXT_ANCHORS,
      get = function() local c = GetAuraCfg(); return c and c.chargeText and (c.chargeText.anchor or c.chargeText.position) or "BOTTOMRIGHT" end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.anchor = v; c.chargeText.position = v end) end,
      order = 141, width = 0.75, hidden = function() return HideAuraChargeText() or (GetAuraCfg() and GetAuraCfg().chargeText and GetAuraCfg().chargeText.mode == "free") end,
    },
    chargeOffsetX = {
      type = "range", name = "X Offset", min = -100, max = 100, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.chargeText and c.chargeText.offsetX or -2 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.offsetX = v end) end,
      order = 142, width = 0.55, hidden = function() return HideAuraChargeText() or (GetAuraCfg() and GetAuraCfg().chargeText and GetAuraCfg().chargeText.mode == "free") end,
    },
    chargeOffsetY = {
      type = "range", name = "Y Offset", min = -100, max = 100, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.chargeText and c.chargeText.offsetY or 2 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.offsetY = v end) end,
      order = 143, width = 0.55, hidden = function() return HideAuraChargeText() or (GetAuraCfg() and GetAuraCfg().chargeText and GetAuraCfg().chargeText.mode == "free") end,
    },
    chargeFreeHint = {
      type = "description", 
      name = "|cff00ff00Text Drag Mode enabled.|r |cff888888Drag the charge text in-game to position it.|r",
      order = 144, width = "full", 
      hidden = function() return HideAuraChargeText() or not (GetAuraCfg() and GetAuraCfg().chargeText and GetAuraCfg().chargeText.mode == "free") end,
    },
    resetChargeText = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Charge/Stack Text settings to defaults for selected icon(s)",
      order = 149,
      width = 0.7,
      hidden = HideAuraChargeText,
      func = function() ResetAuraSectionSettings("chargeText") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- COOLDOWN TEXT SECTION
    -- ═══════════════════════════════════════════════════════════════════
    cooldownTextHeader = {
      type = "toggle",
      name = function() return GetAuraHeaderName("cooldownText", "Duration/Cooldown Text Style") end,
      desc = "Click to expand/collapse. Style the duration/countdown timer. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.cooldownText end,
      set = function(_, v) collapsedSections.cooldownText = not v end,
      order = 150,
      width = "full",
      hidden = HideIfNoAuraSelection,
    },
    cdEnabled = {
      type = "toggle", name = "Show",
      desc = "Show custom cooldown timer text",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownText and c.cooldownText.enabled ~= false end, function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.enabled ~= false end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.enabled = v end) end,
      order = 151, width = 0.55, hidden = HideAuraCooldownText,
    },
    cdTextDrag = {
      type = "toggle", name = "Text Drag",
      desc = "Enable dragging cooldown text to custom positions",
      get = function() return ns.CDMEnhance and ns.CDMEnhance.IsTextDragMode() end,
      set = function(_, v) if ns.CDMEnhance then ns.CDMEnhance.SetTextDragMode(v) end end,
      order = 151.5, width = 0.6, hidden = HideAuraCooldownText,
    },
    cdSize = {
      type = "range", name = "Size", min = 4, max = 64, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.size or 14 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.size = v end) end,
      order = 152, width = 0.6, hidden = HideAuraCooldownText,
    },
    cdColor = {
      type = "color", name = "Color", hasAlpha = true,
      get = function()
        local c = GetAuraCfg()
        local col = c and c.cooldownText and c.cooldownText.color or {r=1,g=1,b=1,a=1}
        return col.r or 1, col.g or 1, col.b or 1, col.a or 1
      end,
      set = function(_, r, g, b, a)
        ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.color = {r=r, g=g, b=b, a=a} end)
      end,
      order = 153, width = 0.55, hidden = HideAuraCooldownText,
    },
    cdFont = {
      type = "select", name = "Font", dialogControl = "LSM30_Font",
      values = LSM and LSM:HashTable("font") or {},
      get = function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.font or "Friz Quadrata TT" end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.font = v end) end,
      order = 154, width = 0.9, hidden = HideAuraCooldownText,
    },
    cdOutline = {
      type = "select", name = "Outline", values = FONT_OUTLINES,
      get = function() local c = GetAuraCfg(); return GetOutlineValue(c and c.cooldownText and c.cooldownText.outline) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.outline = v end) end,
      order = 155, width = 0.85, hidden = HideAuraCooldownText,
    },
    cdShadow = {
      type = "toggle", name = "Shadow",
      get = function() return GetAuraBoolSetting(function(c) return c and c.cooldownText and c.cooldownText.shadow end, function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.shadow end) end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.shadow = v end) end,
      order = 156, width = 0.55, hidden = HideAuraCooldownText,
    },
    cdShadowX = {
      type = "range", name = "Shadow X", min = -20, max = 20, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.shadowOffsetX or 1 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.shadowOffsetX = v end) end,
      order = 157, width = 0.6, hidden = function() return HideAuraCooldownText() or not (GetAuraCfg() and GetAuraCfg().cooldownText and GetAuraCfg().cooldownText.shadow) end,
    },
    cdShadowY = {
      type = "range", name = "Shadow Y", min = -20, max = 20, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.shadowOffsetY or -1 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.shadowOffsetY = v end) end,
      order = 158, width = 0.6, hidden = function() return HideAuraCooldownText() or not (GetAuraCfg() and GetAuraCfg().cooldownText and GetAuraCfg().cooldownText.shadow) end,
    },
    
    -- Position Mode
    cdPositionHeader = {
      type = "description", name = "\n|cffffd700Position|r", order = 159, width = "full", hidden = HideAuraCooldownText,
    },
    cdMode = {
      type = "select", name = "Mode", values = TEXT_MODES,
      desc = "Anchor = fixed position. Free = drag anywhere (automatically enables Text Drag Mode)",
      get = function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.mode or "anchor" end,
      set = function(_, v)
        ApplyAuraSetting(function(c)
          if not c.cooldownText then c.cooldownText = {} end
          c.cooldownText.mode = v
        end)
        -- Auto-enable text drag mode when switching to free
        if v == "free" and ns.CDMEnhance and not ns.CDMEnhance.IsTextDragMode() then
          ns.CDMEnhance.SetTextDragMode(true)
        end
      end,
      order = 160, width = 0.85, hidden = HideAuraCooldownText,
    },
    cdAnchor = {
      type = "select", name = "Anchor", values = TEXT_ANCHORS,
      get = function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.anchor or "CENTER" end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.anchor = v end) end,
      order = 161, width = 0.75, hidden = function() return HideAuraCooldownText() or (GetAuraCfg() and GetAuraCfg().cooldownText and GetAuraCfg().cooldownText.mode == "free") end,
    },
    cdOffsetX = {
      type = "range", name = "X Offset", min = -100, max = 100, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.offsetX or 0 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.offsetX = v end) end,
      order = 162, width = 0.55, hidden = function() return HideAuraCooldownText() or (GetAuraCfg() and GetAuraCfg().cooldownText and GetAuraCfg().cooldownText.mode == "free") end,
    },
    cdOffsetY = {
      type = "range", name = "Y Offset", min = -100, max = 100, step = 1,
      get = function() local c = GetAuraCfg(); return c and c.cooldownText and c.cooldownText.offsetY or 0 end,
      set = function(_, v) ApplyAuraSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.offsetY = v end) end,
      order = 163, width = 0.55, hidden = function() return HideAuraCooldownText() or (GetAuraCfg() and GetAuraCfg().cooldownText and GetAuraCfg().cooldownText.mode == "free") end,
    },
    cdFreeHint = {
      type = "description", 
      name = "|cff00ff00Text Drag Mode enabled.|r |cff888888Drag the cooldown text in-game to position it.|r",
      order = 164, width = "full", 
      hidden = function() return HideAuraCooldownText() or not (GetAuraCfg() and GetAuraCfg().cooldownText and GetAuraCfg().cooldownText.mode == "free") end,
    },
    resetCooldownText = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Cooldown Text settings to defaults for selected icon(s)",
      order = 165,
      width = 0.7,
      hidden = HideAuraCooldownText,
      func = function() ResetAuraSectionSettings("cooldownText") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CUSTOM LABEL SECTION  → defined in ArcUI_CustomLabelOptions.lua
    -- Entries are merged into this args table below (after catalog icons)
    -- ═══════════════════════════════════════════════════════════════════
    
    -- ═══════════════════════════════════════════════════════════════════
    -- BOTTOM BUTTONS (side by side)
    -- ═══════════════════════════════════════════════════════════════════
    bottomSpacer = {
      type = "header",
      name = "",
      order = 190,
    },
    
    noSelectionHint = {
      type = "description",
      name = "\n|cff888888Click an icon in the catalog above to customize it.|r",
      order = 191,
      hidden = function() return selectedAuraIcon ~= nil end,
    },
    
    resetSingleIconBtn = {
      type = "execute",
      name = "Reset Selected Icon Settings",
      desc = "Remove all per-icon customizations from the selected icon. The icon will use global defaults instead.",
      func = function()
        if selectedAuraIcon and ns.CDMEnhance and ns.CDMEnhance.ResetIconToDefaults then
          ns.CDMEnhance.ResetIconToDefaults(selectedAuraIcon)
          print("|cff00FF00[ArcUI CDM]|r Cleared per-icon settings. Icon now uses global defaults.")
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end
      end,
      order = 194,
      width = 1.35,
      hidden = function()
        -- Only show when a single icon is selected AND it has customizations
        if editAllAurasMode or next(selectedAuraIcons) or not selectedAuraIcon then
          return true
        end
        return not (ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(selectedAuraIcon))
      end,
      confirm = true,
      confirmText = "Reset all per-icon settings for this icon?\n\nThe icon will use global defaults instead.",
    },
    
    resetAllPositions = {
      type = "execute",
      name = "Reset All Positions",
      desc = "Reset all aura icon positions to default CDM layout",
      order = 195,
      width = 1.0,
      confirm = true,
      confirmText = "Reset all CDM aura icon positions to default?",
      func = function()
        if ns.CDMEnhance and ns.CDMEnhance.ResetAllAuraPositions then
          ns.CDMEnhance.ResetAllAuraPositions()
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    
    resetAllOptions = {
      type = "execute",
      name = "Reset All Options",
      desc = "Reset all aura icon customization settings to defaults (scale, text, glow, etc.)",
      order = 195.5,
      width = 1.0,
      confirm = true,
      confirmText = "Reset all aura icon customization settings to defaults? This will clear all custom styling.",
      func = function()
        if ns.CDMEnhance and ns.CDMEnhance.ResetAllIconsToDefaults then
          ns.CDMEnhance.ResetAllIconsToDefaults("aura")
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    
    deselectBtn = {
      type = "execute",
      name = "Deselect Icon",
      order = 196,
      width = 0.75,
      hidden = HideIfNoAuraSelection,
      func = function()
        selectedAuraIcon = nil
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
  }
  
  -- Add catalog icon grid (auras only)
  for i = 1, 50 do
    args["catalogIcon" .. i] = CreateAuraCatalogIconEntry(i)
  end
  
  -- Merge Custom Label options from external module
  if ns.CustomLabelOptions and ns.CustomLabelOptions.GetAuraArgs then
    for k, v in pairs(ns.CustomLabelOptions.GetAuraArgs()) do
      args[k] = v
    end
  end
  
  return {
    type = "group",
    name = "CDM Aura Icons",
    order = 1,
    args = args,
  }
end

-- ===================================================================
-- COOLDOWN ICONS OPTIONS TABLE
-- ===================================================================

-- Build dynamic filter values including CDMGroups
local function GetCooldownFilterValues()
  local values = {
    ["all"] = "All Cooldowns",
    ["essential"] = "Essential Only",
    ["utility"] = "Utility Only",
    ["freeposition"] = "Free Position Only",
  }
  
  -- Add CDMGroups group names
  if ns.CDMGroups and ns.CDMGroups.groups then
    for groupName, group in pairs(ns.CDMGroups.groups) do
      -- Only add groups that have cooldown icons (not aura groups)
      local hasCooldowns = false
      if group.members then
        for cdID, member in pairs(group.members) do
          if member.viewerType == "cooldown" or member.viewerType == "utility" 
             or member.originalViewerName == "EssentialCooldownViewer" 
             or member.originalViewerName == "UtilityCooldownViewer" then
            hasCooldowns = true
            break
          else
            -- Check CDM category as fallback (safe for Arc Aura string IDs)
            -- Shared already defined at file level
            local cdInfo = Shared and Shared.SafeGetCDMInfo and Shared.SafeGetCDMInfo(cdID)
            if cdInfo and (cdInfo.category == 0 or cdInfo.category == 1) then
              hasCooldowns = true
              break
            end
          end
        end
      end
      if hasCooldowns then
        values["group:" .. groupName] = "|cff00ccff" .. groupName .. "|r"
      end
    end
  end
  
  return values
end

function ns.GetCDMCooldownIconsOptionsTable()
  local args = {
    desc = {
      type = "description",
      name = "Customize individual CDM cooldown icons (Essential/Utility viewers). Select an icon below to edit its appearance.",
      order = 1,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CONTROLS ROW 1: Main toggles
    -- ═══════════════════════════════════════════════════════════════════
    enableCustomization = {
      type = "toggle",
      name = "|cff00ff00Enable Customization|r",
      desc = "Enable custom styling for cooldown icons. When disabled, only repositioning works and all custom styles are removed.",
      order = 2,
      width = 1.1,
      get = function() return ns.CDMEnhance and ns.CDMEnhance.IsCooldownCustomizationEnabled() end,
      set = function(_, v)
        if ns.CDMEnhance then ns.CDMEnhance.SetCooldownCustomizationEnabled(v) end
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CONTROLS ROW 2: Actions
    -- ═══════════════════════════════════════════════════════════════════
    openCDM = {
      type = "execute",
      name = "Open CD Manager",
      desc = "Open the Cooldown Manager settings panel",
      order = 3,
      width = 0.85,
      func = function()
        local frame = _G["CooldownViewerSettings"]
        if frame and frame.Show then
          frame:Show()
          frame:Raise()
        end
      end,
    },
    scanBtn = {
      type = "execute",
      name = "Scan CDM",
      desc = "Rescan CDM viewers for icons",
      order = 3.1,
      width = 0.55,
      func = function()
        if ns.CDMEnhance then
          ns.CDMEnhance.ScanCDM()
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end
      end,
    },
    filterDropdown = {
      type = "select",
      name = "Filter",
      desc = "Filter which cooldown icons to show",
      values = GetCooldownFilterValues,
      get = function() return cooldownFilterMode end,
      set = function(_, v)
        cooldownFilterMode = v
        selectedCooldownIcon = nil  -- Clear selection when filter changes
        wipe(selectedCooldownIcons)
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      order = 4,
      width = 0.85,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- GLOBAL OPTIONS SECTION
    -- ═══════════════════════════════════════════════════════════════════
    globalOptionsHeader = {
      type = "header",
      name = "Global Options",
      order = 5,
    },
    showTooltips = {
      type = "toggle",
      name = "Show Tooltips",
      desc = "When enabled, hovering over icons shows spell tooltips.\n\nWhen disabled, tooltips are hidden on all icons managed by ArcUI.",
      order = 5.1,
      width = 0.9,
      get = function()
        local db = Shared.GetCDMGroupsDB()
        if not db then
          return true  -- Default: show tooltips
        end
        return db.disableTooltips ~= true
      end,
      set = function(_, val)
        local db = Shared.GetCDMGroupsDB()
        if not db then return end
        
        db.disableTooltips = not val
        if ns.CDMGroups and ns.CDMGroups.RefreshIconSettings then
          ns.CDMGroups.RefreshIconSettings()
        end
      end,
    },
    clickThrough = {
      type = "toggle",
      name = "Click-Through",
      desc = "When enabled, icons cannot be clicked - mouse clicks pass through to whatever is behind them.\n\nUseful if icons overlap clickable UI elements.",
      order = 5.2,
      width = 0.9,
      get = function()
        local db = Shared.GetCDMGroupsDB()
        if not db then
          return false  -- Default: clickable
        end
        return db.clickThrough == true
      end,
      set = function(_, val)
        local db = Shared.GetCDMGroupsDB()
        if not db then return end
        
        db.clickThrough = val
        if ns.CDMGroups and ns.CDMGroups.RefreshIconSettings then
          ns.CDMGroups.RefreshIconSettings()
        end
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- GROUP SETTINGS - Position and CDM settings for Cooldowns
    -- ═══════════════════════════════════════════════════════════════════
    catalogHeader = {
      type = "header",
      name = function()
        local count = GetCooldownSelectionCount()
        if editAllCooldownsMode then
          return "Icon Catalog |cff00ffff(Editing All: " .. count .. " icons)|r"
        elseif count > 1 then
          return "Icon Catalog |cff00ff00(Multi-Select: " .. count .. " icons)|r"
        end
        return "Icon Catalog"
      end,
      order = 9,
    },
    editAllToggle = {
      type = "toggle",
      name = function()
        if editAllCooldownsMode then
          return "|cff00ffffEdit All Icons|r"
        end
        return "Edit All Icons"
      end,
      desc = "When enabled, any setting change will apply to ALL cooldown icons at once",
      order = 9.1,
      width = 0.85,
      get = function() return editAllCooldownsMode end,
      set = function(_, v)
        editAllCooldownsMode = v
        if v then
          -- Clear multi-select when entering edit-all mode
          wipe(selectedCooldownIcons)
          selectedCooldownIcon = nil
          -- Ensure unified mode is off when using separate panel edit-all
          editAllUnifiedMode = false
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    catalogHint = {
      type = "description",
      name = function()
        local hint = "|cff888888Click to select  •  Shift+Click to multi-select"
        hint = hint .. "  •  |cffaa55ff*|r = Customized|r"
        return hint
      end,
      order = 9.5,
      fontSize = "small",
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CURRENTLY EDITING DISPLAY
    -- ═══════════════════════════════════════════════════════════════════
    currentlyEditingHeader = {
      type = "header",
      name = function()
        local count = GetCooldownSelectionCount()
        if editAllCooldownsMode then
          return "|cff00ffffEditing All Cooldowns (" .. count .. " icons)|r"
        elseif count > 1 then
          return "|cff00ff00Editing " .. count .. " Icons|r"
        elseif selectedCooldownIcon then
          -- Get ALL cooldowns (not filtered) to find the name
          local icons = ns.CDMEnhance and ns.CDMEnhance.GetCooldownIcons() or {}
          for cdID, entry in pairs(icons) do
            if cdID == selectedCooldownIcon then
              return "|cff00ff00Editing:|r |cffffd700" .. (entry.name or "Unknown") .. "|r"
            end
          end
          return "|cff00ff00Editing:|r |cffffd700Unknown|r"
        end
        return ""
      end,
      order = 99,
      hidden = function()
        return not editAllCooldownsMode and not next(selectedCooldownIcons) and not selectedCooldownIcon
      end,
    },
    
    resetSelectedIconBtn = {
      type = "execute",
      name = "|cffff6666Reset Selected Icon(s)|r",
      desc = "Remove ALL per-icon customizations for the selected icon(s), returning them to default/global settings",
      order = 99.5,
      width = 1.2,
      hidden = HideIfNoCooldownSelection,
      confirm = true,
      confirmText = "Remove ALL per-icon customizations for the selected icon(s)? This cannot be undone.",
      func = function()
        local icons = GetCooldownIconsToUpdate()
        for _, cdID in ipairs(icons) do
          if ns.CDMEnhance and ns.CDMEnhance.ResetIconToDefaults then
            ns.CDMEnhance.ResetIconToDefaults(cdID)
          end
        end
        if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
          ns.CDMEnhance.InvalidateCache()
        end
        UpdateCooldown()
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- ICON APPEARANCE SECTION
    -- ═══════════════════════════════════════════════════════════════════
    iconAppearanceHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("iconAppearance", "Icon Appearance") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.iconAppearance end,
      set = function(_, v) collapsedSections.iconAppearance = not v end,
      order = 100,
      width = "full",
      hidden = function()
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return false
      end,
    },
    masqueNotice = {
      type = "description",
      name = "|cffff9900Masque Active:|r Zoom, Aspect Ratio, and Padding are controlled by your Masque skin. Disable the skin group in Masque to use these settings.",
      order = 100.1,
      width = "full",
      fontSize = "medium",
      hidden = function() 
        if collapsedSections.iconAppearance then return true end
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return not IsMasqueActive()
      end,
    },
    
    useGroupScale = {
      type = "toggle", name = "Group Scale",
      desc = "When Group Scale Override is ON in Group Settings, all icons follow the group scale by default. Disable this to use a custom per-icon scale instead.",
      get = function() 
        local c = GetCooldownCfg()
        -- nil or true = follow group, false = opt out
        return not c or c.useGroupScale ~= false
      end,
      set = function(_, v) 
        -- v=true means follow group (store nil to use default behavior)
        -- v=false means opt out (store false explicitly)
        ApplySharedCooldownSetting(function(c) 
          if v then
            c.useGroupScale = nil  -- nil = follow group (default)
            -- Clear custom size values so icon uses group dimensions
            c.width = nil
            c.height = nil
            c.scale = nil
          else
            c.useGroupScale = false  -- false = opt out
          end
        end)
        if ns.CDMEnhance and ns.CDMEnhance.ApplyGroupScaleToIcon then
          local icons = GetCooldownIconsToUpdate()
          for _, cdID in ipairs(icons) do
            ns.CDMEnhance.ApplyGroupScaleToIcon(cdID)
          end
        end
      end,
      order = 100.5, width = 0.7, hidden = HideCooldownIconAppearance,
    },
    scale = {
      type = "range", name = "Scale", min = 0.25, max = 4.0, step = 0.05,
      desc = "Per-icon scale multiplier (only used when Group Scale is disabled)",
      get = function() local c = GetCooldownCfg(); return c and c.scale or 1.0 end,
      set = function(_, v)
        ApplySharedCooldownSetting(function(c) c.scale = v end)
      end,
      order = 101, width = 0.7,
      hidden = function()
        if HideCooldownIconAppearance() then return true end
        local c = GetCooldownCfg()
        -- Show only when useGroupScale is explicitly false
        return c and c.useGroupScale ~= false
      end,
    },
    iconWidth = {
      type = "range", name = "Width", min = 5, max = 200, step = 1,
      desc = "Icon width in pixels (before scale). Default is CDM's native size (36).",
      get = function() local c = GetCooldownCfg(); return c and c.width or 36 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) c.width = v end) end,
      order = 102, width = 0.65,
      hidden = function()
        if HideCooldownIconAppearance() then return true end
        -- Show when icon has opted out of group scale
        local c = GetCooldownCfg()
        if c and c.useGroupScale == false then return false end
        -- Hide when group scale override is enabled (group controls size)
        local viewerType = GetSelectedCooldownViewerType()
        if viewerType and ns.CDMEnhance and ns.CDMEnhance.IsGroupScaleOverrideEnabled and ns.CDMEnhance.IsGroupScaleOverrideEnabled(viewerType) then
          return true
        end
        return false
      end,
    },
    iconHeight = {
      type = "range", name = "Height", min = 5, max = 200, step = 1,
      desc = "Icon height in pixels (before scale). Default is CDM's native size (36).",
      get = function() local c = GetCooldownCfg(); return c and c.height or 36 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) c.height = v end) end,
      order = 103, width = 0.65,
      hidden = function()
        if HideCooldownIconAppearance() then return true end
        -- Show when icon has opted out of group scale
        local c = GetCooldownCfg()
        if c and c.useGroupScale == false then return false end
        -- Hide when group scale override is enabled (group controls size)
        local viewerType = GetSelectedCooldownViewerType()
        if viewerType and ns.CDMEnhance and ns.CDMEnhance.IsGroupScaleOverrideEnabled and ns.CDMEnhance.IsGroupScaleOverrideEnabled(viewerType) then
          return true
        end
        return false
      end,
    },
    aspectRatio = {
      type = "range", name = "Aspect Ratio", min = 0.25, max = 2.5, step = 0.05,
      desc = "Adjusts icon shape. 1 = square, higher = wider, lower = taller.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls icon appearance via its skin settings.",
      get = function() local c = GetCooldownCfg(); return c and c.aspectRatio or 1.0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) c.aspectRatio = v end) end,
      order = 104, width = 0.85, hidden = HideCooldownIconAppearance,
      disabled = IsMasqueActive,
    },
    zoom = {
      type = "range", name = "Zoom", min = 0, max = 0.3, step = 0.01,
      desc = "Crops icon edges for a cleaner look.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls zoom via its skin settings.",
      get = function() local c = GetCooldownCfg(); return c and c.zoom or 0.075 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) c.zoom = v end) end,
      order = 105, width = 0.65, hidden = HideCooldownIconAppearance,
      disabled = IsMasqueActive,
    },
    padding = {
      type = "range", name = "Padding", min = -5, max = 20, step = 1,
      desc = "Space between icon and frame edges.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls icon appearance via its skin settings.",
      get = function() local c = GetCooldownCfg(); return c and c.padding or 0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) c.padding = v end) end,
      order = 106, width = 0.65, hidden = HideCooldownIconAppearance,
      disabled = IsMasqueActive,
    },
    alpha = {
      type = "range", name = "Opacity", min = 0, max = 1.0, step = 0.05,
      desc = "Icon visibility (0 = hidden, 1 = fully visible)",
      get = function() local c = GetCooldownCfg(); return c and c.alpha or 1.0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) c.alpha = v end) end,
      order = 107, width = 0.65, hidden = HideCooldownIconAppearance,
    },
    hideShadow = {
      type = "toggle", name = "Hide CDM Shadow",
      desc = "Removes the default shadow around the icon",
      get = function()
        return GetCooldownBoolSetting(function(c) return c.hideShadow end, function() local c = GetCooldownCfg(); return c and c.hideShadow end)
      end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) c.hideShadow = v end) end,
      order = 107.5, width = 0.85, hidden = HideCooldownIconAppearance,
    },
    showPandemicBorder = {
      type = "toggle", name = "Pandemic Glow",
      desc = "Shows the red pandemic glow when cooldown is at 30% remaining.\n\n|cff888888Note:|r If glow persists after disabling, /reload fixes it.",
      get = function()
        return GetCooldownBoolSetting(function(c) return c.pandemicBorder and c.pandemicBorder.enabled end, function() local c = GetCooldownCfg(); return c and c.pandemicBorder and c.pandemicBorder.enabled end)
      end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.pandemicBorder then c.pandemicBorder = {} end; c.pandemicBorder.enabled = v end) end,
      order = 107.52, width = 0.85, hidden = HideCooldownIconAppearance,
    },
    resetIconAppearance = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Icon Appearance settings to defaults for selected icon(s)",
      order = 107.54,
      width = 0.7,
      hidden = HideCooldownIconAppearance,
      func = function() ResetCooldownSectionSettings("iconAppearance") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- ICON POSITIONING SECTION (collapsible)
    -- ═══════════════════════════════════════════════════════════════════
    iconPositionHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("position", "Icon Positioning") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.position end,
      set = function(_, v) collapsedSections.position = not v end,
      order = 107.55,
      width = "full",
      hidden = function()
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return false
      end,
    },
    iconPositionDesc = {
      type = "description",
      name = function()
        if not ns.CDMEnhance then return "" end
        local cdID = selectedCooldownIcon or ns.CDMEnhance.GetFirstIconOfType("cooldown")
        if not cdID then return "" end
        local mode = ns.CDMEnhance.GetIconPositionMode(cdID)
        if mode == "free" then
          return "|cff00ff00Free Positioned|r - Drag to reposition"
        else
          return "|cffffd700In Group|r - Drag icon out of group to free position"
        end
      end,
      order = 107.57,
      width = "full",
      fontSize = "medium",
      hidden = HideCooldownPosition,
    },
    iconPosX = {
      type = "input",
      dialogControl = "ArcUI_EditBox",
      name = "X Offset",
      desc = "Horizontal offset from screen center (0 = center)",
      get = function()
        if not ns.CDMEnhance then return "" end
        local cdID = selectedCooldownIcon or ns.CDMEnhance.GetFirstIconOfType("cooldown")
        if not cdID then return "" end
        local x, y = ns.CDMEnhance.GetIconPosition(cdID)
        return x and tostring(math.floor(x)) or "0"
      end,
      set = function(_, v)
        if not ns.CDMEnhance then return end
        local cdID = selectedCooldownIcon or ns.CDMEnhance.GetFirstIconOfType("cooldown")
        if not cdID then return end
        local x, y = ns.CDMEnhance.GetIconPosition(cdID)
        local newX = tonumber(v)
        if newX then
          ns.CDMEnhance.SetIconPosition(cdID, newX, y or 0)
        end
      end,
      order = 107.7,
      width = 0.45,
      hidden = function()
        if HideCooldownPosition() then return true end
        local cdID = selectedCooldownIcon or (ns.CDMEnhance and ns.CDMEnhance.GetFirstIconOfType("cooldown"))
        if not cdID then return true end
        -- Only show for free positioned icons (controlled by CDMGroups)
        return ns.CDMEnhance.GetIconPositionMode(cdID) ~= "free"
      end,
    },
    iconPosY = {
      type = "input",
      dialogControl = "ArcUI_EditBox",
      name = "Y Position",
      desc = "Vertical offset from screen center (0 = center)",
      get = function()
        if not ns.CDMEnhance then return "" end
        local cdID = selectedCooldownIcon or ns.CDMEnhance.GetFirstIconOfType("cooldown")
        if not cdID then return "" end
        local x, y = ns.CDMEnhance.GetIconPosition(cdID)
        return y and tostring(math.floor(y)) or "0"
      end,
      set = function(_, v)
        if not ns.CDMEnhance then return end
        local cdID = selectedCooldownIcon or ns.CDMEnhance.GetFirstIconOfType("cooldown")
        if not cdID then return end
        local x, y = ns.CDMEnhance.GetIconPosition(cdID)
        local newY = tonumber(v)
        if newY then
          ns.CDMEnhance.SetIconPosition(cdID, x or 0, newY)
        end
      end,
      order = 107.8,
      width = 0.45,
      hidden = function()
        if HideCooldownPosition() then return true end
        local cdID = selectedCooldownIcon or (ns.CDMEnhance and ns.CDMEnhance.GetFirstIconOfType("cooldown"))
        if not cdID then return true end
        return ns.CDMEnhance.GetIconPositionMode(cdID) == "group"
      end,
    },
    iconPosReset = {
      type = "execute",
      name = "Reset Position",
      desc = "Reset this icon to follow the group layout",
      func = function()
        if not ns.CDMEnhance then return end
        local cdID = selectedCooldownIcon or ns.CDMEnhance.GetFirstIconOfType("cooldown")
        if cdID then
          ns.CDMEnhance.ResetIconPosition(cdID)
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end
      end,
      order = 107.9,
      width = 0.7,
      hidden = function()
        if HideCooldownPosition() then return true end
        local cdID = selectedCooldownIcon or (ns.CDMEnhance and ns.CDMEnhance.GetFirstIconOfType("cooldown"))
        if not cdID then return true end
        return ns.CDMEnhance.GetIconPositionMode(cdID) == "group"
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- INACTIVE STATE SECTION (when NOT on cooldown)
    -- ═══════════════════════════════════════════════════════════════════
    -- ═══════════════════════════════════════════════════════════════════
    -- READY STATE SECTION (when ability is available)
    -- ═══════════════════════════════════════════════════════════════════
    readyStateHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("activeState", "Ready State") end,
      desc = "Click to expand/collapse. Configure how the icon appears when the ability IS READY (not on cooldown). Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.readyState end,
      set = function(_, v) collapsedSections.readyState = not v end,
      order = 107.81,
      width = "full",
      hidden = HideIfNoCooldownSelection,
    },
    readyStateDesc = {
      type = "description",
      name = "|cff888888Configure how the icon appears when the ability is READY to use.|r",
      order = 107.82, width = "full",
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.readyState end,
    },
    readyStateAlpha = {
      type = "range",
      name = "Ready Alpha",
      desc = "Icon opacity when the ability is ready (0 = hidden, 1 = fully visible)",
      min = 0, max = 1.0, step = 0.05,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.alpha or 1.0
        end
        return 1.0
      end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.alpha = v
        end)
      end,
      order = 107.83, width = 0.8,
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.readyState end,
    },
    readyStateGlow = {
      type = "toggle",
      name = "Glow When Ready",
      desc = "Show a glow effect while the ability is ready to use",
      get = function()
        return GetCooldownBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow end,
          function()
            local c = GetCooldownCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
              return c.cooldownStateVisuals.readyState.glow or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glow = v
        end)
        -- Clear preview when disabling glow
        if not v then
          ns.CDMEnhanceOptions.ClearGlowPreviewForSelection(false)
        end
      end,
      order = 107.84, width = 0.9,
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.readyState end,
    },
    readyStateGlowPreview = {
      type = "toggle",
      name = "Preview",
      desc = "Toggle glow preview for selected icon(s). Preview will automatically stop when you close the options panel.",
      get = function()
        return ns.CDMEnhanceOptions.GetGlowPreviewState(false)
      end,
      set = function(_, v)
        ns.CDMEnhanceOptions.ToggleGlowPreviewForSelection(false)
      end,
      order = 107.8401, width = 0.5,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    readyStateGlowCombatOnly = {
      type = "toggle",
      name = "In Combat Only",
      desc = "Only show the ready glow while in combat",
      get = function()
        return GetCooldownBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glowCombatOnly end,
          function()
            local c = GetCooldownCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
              return c.cooldownStateVisuals.readyState.glowCombatOnly or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowCombatOnly = v
        end)
        -- If enabling combat-only and not in combat, hide glows immediately
        if v and not InCombatLockdown() and not UnitAffectingCombat("player") then
          local icons = GetCooldownIconsToUpdate()
          for _, cdID in ipairs(icons) do
            local data = ns.CDMEnhance and ns.CDMEnhance.GetEnhancedFrameData and ns.CDMEnhance.GetEnhancedFrameData(cdID)
            if data and data.frame and ns.CDMEnhance.HideReadyGlow then
              ns.CDMEnhance.HideReadyGlow(data.frame)
            end
          end
        end
      end,
      order = 107.8405, width = 0.8,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    readyStateGlowWhileChargesAvailable = {
      type = "toggle",
      name = "Glow While Any Charge Available",
      desc = "For charge spells: Show glow as long as any charge is available.\n\n|cff888888Off|r: Glow only when ALL charges are ready\n|cffffd700On|r: Glow while any charge can be used",
      get = function()
        return GetCooldownBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glowWhileChargesAvailable end,
          function()
            local c = GetCooldownCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
              return c.cooldownStateVisuals.readyState.glowWhileChargesAvailable or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowWhileChargesAvailable = v
        end)
      end,
      order = 107.8406, width = 1.2,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    readyStateGlowType = {
      type = "select",
      name = "Glow Style",
      desc = "Select the glow animation style\n\n|cffffd700Button|r - Classic button glow (default)\n|cffffd700Pixel|r - Rotating pixel lines\n|cffffd700AutoCast|r - Sparkle particles\n|cffffd700Proc|r - Flashy proc effect",
      values = {
        ["pixel"] = "Pixel Glow",
        ["autocast"] = "AutoCast Sparkles",
        ["button"] = "Button Glow (Default)",
        ["proc"] = "Proc Effect",
      },
      sorting = {"button", "pixel", "autocast", "proc"},
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowType or "button"
        end
        return "button"
      end,
      set = function(_, v)
        ApplyReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowType = v
        end)
      end,
      order = 107.841, width = 0.9,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    readyStateGlowColor = {
      type = "color",
      name = "Color",
      desc = "Glow color",
      hasAlpha = false,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          local col = c.cooldownStateVisuals.readyState.glowColor
          if col then return col.r or 1, col.g or 0.85, col.b or 0.1 end
        end
        return 1, 0.85, 0.1  -- Default gold
      end,
      set = function(_, r, g, b)
        ApplyReadyStateGlowSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowColor = {r = r, g = g, b = b}
        end)
      end,
      order = 107.842, width = 0.5,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    readyStateGlowIntensity = {
      type = "range",
      name = "Intensity",
      desc = "How bright the glow appears",
      min = 0, max = 1.0, step = 0.05,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowIntensity or 1.0
        end
        return 1.0
      end,
      set = function(_, v)
        ApplyReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowIntensity = v
        end)
      end,
      order = 107.843, width = 0.6,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow)
      end,
    },
    readyStateGlowScale = {
      type = "range",
      name = "Scale",
      desc = "Size of the glow effect",
      min = 0.5, max = 4.0, step = 0.05,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowScale or 1.0
        end
        return 1.0
      end,
      set = function(_, v)
        ApplyReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowScale = v
        end)
      end,
      order = 107.844, width = 0.55,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        local gt = c.cooldownStateVisuals.readyState.glowType; return gt ~= "autocast" and gt ~= "button"
      end,
    },
    readyStateGlowSpeed = {
      type = "range",
      name = "Speed",
      desc = "How fast the glow animates",
      min = 0.05, max = 1.0, step = 0.05,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowSpeed or 0.25
        end
        return 0.25
      end,
      set = function(_, v)
        ApplyReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowSpeed = v
        end)
      end,
      order = 107.845, width = 0.55,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        -- Proc glow doesn't use speed
        return c.cooldownStateVisuals.readyState.glowType == "proc"
      end,
    },
    readyStateGlowLines = {
      type = "range",
      name = "Lines",
      desc = "Number of glow lines",
      min = 1, max = 16, step = 1,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowLines or 8
        end
        return 8
      end,
      set = function(_, v)
        ApplyReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowLines = v
        end)
      end,
      order = 107.846, width = 0.55,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        return c.cooldownStateVisuals.readyState.glowType ~= "pixel"
      end,
    },
    readyStateGlowThickness = {
      type = "range",
      name = "Thickness",
      desc = "Thickness of glow lines",
      min = 1, max = 10, step = 1,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowThickness or 2
        end
        return 2
      end,
      set = function(_, v)
        ApplyReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowThickness = v
        end)
      end,
      order = 107.847, width = 0.55,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        return c.cooldownStateVisuals.readyState.glowType ~= "pixel"
      end,
    },
    readyStateGlowParticles = {
      type = "range",
      name = "Particles",
      desc = "Number of sparkle groups",
      min = 1, max = 16, step = 1,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowParticles or 4
        end
        return 4
      end,
      set = function(_, v)
        ApplyReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowParticles = v
        end)
      end,
      order = 107.848, width = 0.55,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        return c.cooldownStateVisuals.readyState.glowType ~= "autocast"
      end,
    },
    readyStateGlowXOffset = {
      type = "range",
      name = "X Offset",
      desc = "Horizontal glow size adjustment",
      min = -50, max = 50, step = 1,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowXOffset or 0
        end
        return 0
      end,
      set = function(_, v)
        ApplyReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowXOffset = v
        end)
      end,
      order = 107.849, width = 0.55,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        -- Button glow doesn't support offset
        return c.cooldownStateVisuals.readyState.glowType == "button"
      end,
    },
    readyStateGlowYOffset = {
      type = "range",
      name = "Y Offset",
      desc = "Vertical glow size adjustment",
      min = -50, max = 50, step = 1,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState then
          return c.cooldownStateVisuals.readyState.glowYOffset or 0
        end
        return 0
      end,
      set = function(_, v)
        ApplyReadyStateGlowSliderSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.readyState then c.cooldownStateVisuals.readyState = {} end
          c.cooldownStateVisuals.readyState.glowYOffset = v
        end)
      end,
      order = 107.8495, width = 0.55,
      hidden = function()
        if HideIfNoCooldownSelection() or collapsedSections.readyState then return true end
        local c = GetCooldownCfg()
        if not (c and c.cooldownStateVisuals and c.cooldownStateVisuals.readyState and c.cooldownStateVisuals.readyState.glow) then return true end
        -- Button glow doesn't support offset
        return c.cooldownStateVisuals.readyState.glowType == "button"
      end,
    },
    resetReadyState = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Ready State settings to defaults for selected icon(s)",
      order = 107.89,
      width = 0.7,
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.readyState end,
      func = function() ResetCooldownSectionSettings("activeState") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- ON COOLDOWN STATE SECTION (when ability is on cooldown)
    -- ═══════════════════════════════════════════════════════════════════
    cooldownStateHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("inactiveState", "On Cooldown State") end,
      desc = "Click to expand/collapse. Configure how the icon appears when the ability IS ON COOLDOWN. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.cooldownState end,
      set = function(_, v) collapsedSections.cooldownState = not v end,
      order = 107.91,
      width = "full",
      hidden = HideIfNoCooldownSelection,
    },
    cooldownStateDesc = {
      type = "description",
      name = "|cff888888Configure how the icon appears when on cooldown. GCD is ignored (GCD-only shows as ready).|r",
      order = 107.92, width = "full",
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.cooldownState end,
    },
    cooldownStateAlpha = {
      type = "range",
      name = "Cooldown Alpha",
      desc = "Icon opacity when on cooldown (0 = hidden, 1 = fully visible)",
      min = 0, max = 1.0, step = 0.05,
      get = function()
        local c = GetCooldownCfg()
        if c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState then
          return c.cooldownStateVisuals.cooldownState.alpha or 1.0
        end
        return 1.0
      end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.cooldownState then c.cooldownStateVisuals.cooldownState = {} end
          c.cooldownStateVisuals.cooldownState.alpha = v
        end)
      end,
      order = 107.93, width = 0.8,
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.cooldownState end,
    },
    cooldownStateDesaturate = {
      type = "toggle",
      name = "No Desaturation",
      desc = "Block the default desaturation when on cooldown. By default, CDM desaturates icons on cooldown - enable this to keep icons in full color.",
      get = function()
        return GetCooldownBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState and c.cooldownStateVisuals.cooldownState.noDesaturate end,
          function()
            local c = GetCooldownCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState then
              return c.cooldownStateVisuals.cooldownState.noDesaturate or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.cooldownState then c.cooldownStateVisuals.cooldownState = {} end
          c.cooldownStateVisuals.cooldownState.noDesaturate = v
          -- Clear old desaturate flag
          c.cooldownStateVisuals.cooldownState.desaturate = nil
        end)
        -- Force immediate visual update
        if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
          ns.CDMEnhance.RefreshIconType("cooldown")
        end
      end,
      order = 107.94, width = 1.0,
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.cooldownState end,
    },
    cooldownStatePreserveDurationText = {
      type = "toggle",
      name = "Preserve Duration Text",
      desc = "Keep the cooldown duration text at full opacity even when the icon alpha is reduced. Useful for seeing cooldown timers on dimmed icons.",
      get = function()
        return GetCooldownBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState and c.cooldownStateVisuals.cooldownState.preserveDurationText end,
          function()
            local c = GetCooldownCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState then
              return c.cooldownStateVisuals.cooldownState.preserveDurationText or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.cooldownState then c.cooldownStateVisuals.cooldownState = {} end
          c.cooldownStateVisuals.cooldownState.preserveDurationText = v
        end)
        -- Force immediate visual update
        if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
          ns.CDMEnhance.RefreshIconType("cooldown")
        end
      end,
      order = 107.945, width = 1.2,
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.cooldownState end,
    },
    cooldownStateWaitForNoCharges = {
      type = "toggle",
      name = "Wait For No Charges",
      desc = "For charge spells only: Don't apply the cooldown alpha until all charges are consumed. The icon stays at full alpha while charges remain.\n\n|cffff6600Note:|r For spells that don't trigger the GCD (off-GCD abilities), a brief ~1 second flicker may occur due to API limitations.",
      get = function()
        return GetCooldownBoolSetting(
          function(c) return c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState and c.cooldownStateVisuals.cooldownState.waitForNoCharges end,
          function()
            local c = GetCooldownCfg()
            if c and c.cooldownStateVisuals and c.cooldownStateVisuals.cooldownState then
              return c.cooldownStateVisuals.cooldownState.waitForNoCharges or false
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.cooldownStateVisuals then c.cooldownStateVisuals = {} end
          if not c.cooldownStateVisuals.cooldownState then c.cooldownStateVisuals.cooldownState = {} end
          c.cooldownStateVisuals.cooldownState.waitForNoCharges = v
        end)
        -- Force immediate visual update
        if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
          ns.CDMEnhance.RefreshIconType("cooldown")
        end
      end,
      order = 107.946, width = 1.2,
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.cooldownState end,
    },
    resetCooldownState = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset On Cooldown State settings to defaults for selected icon(s)",
      order = 107.949,
      width = 0.7,
      hidden = function() return HideIfNoCooldownSelection() or collapsedSections.cooldownState end,
      func = function() ResetCooldownSectionSettings("inactiveState") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- AURA ACTIVE STATE SECTION (when associated buff/aura is active)
    -- ═══════════════════════════════════════════════════════════════════
    auraActiveStateHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("auraActiveState", "Aura Active State") end,
      desc = "Click to expand/collapse. Configure how the icon appears when its associated aura/buff is active. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.auraActiveState end,
      set = function(_, v) collapsedSections.auraActiveState = not v end,
      order = 107.95,
      width = "full",
      hidden = HideIfNoCooldownSelection,
    },
    auraActiveStateDesc = {
      type = "description",
      name = "|cff888888Configure how the icon behaves when its associated buff/aura is active on you.|r",
      order = 107.96, width = "full",
      hidden = HideCooldownAuraActiveState,
    },
    auraActiveStateIgnoreOverride = {
      type = "toggle", 
      name = "Ignore Aura Override",
      desc = "Show the actual spell cooldown instead of the aura/buff duration. When enabled, the icon will display your spell's cooldown even while the buff is active, with desaturation applied.",
      get = function()
        return GetCooldownBoolSetting(
          function(c)
            -- Check both new location (auraActiveState) and old location (cooldownSwipe) for backward compatibility
            if c then
              if c.auraActiveState and c.auraActiveState.ignoreAuraOverride then
                return true
              end
              if c.cooldownSwipe and c.cooldownSwipe.ignoreAuraOverride then
                return true
              end
            end
            return false
          end,
          function()
            local c = GetCooldownCfg()
            -- Check both new location (auraActiveState) and old location (cooldownSwipe) for backward compatibility
            if c then
              if c.auraActiveState and c.auraActiveState.ignoreAuraOverride then
                return true
              end
              if c.cooldownSwipe and c.cooldownSwipe.ignoreAuraOverride then
                return true
              end
            end
            return false
          end
        )
      end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          -- Set in new location
          if not c.auraActiveState then c.auraActiveState = {} end
          c.auraActiveState.ignoreAuraOverride = v
          -- Clear from old location if present
          if c.cooldownSwipe and c.cooldownSwipe.ignoreAuraOverride then
            c.cooldownSwipe.ignoreAuraOverride = nil
          end
        end)
      end,
      order = 107.97, width = 1.2,
      hidden = HideCooldownAuraActiveState,
    },
    resetAuraActiveState = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Aura Active State settings to defaults for selected icon(s)",
      order = 107.99,
      width = 0.7,
      hidden = HideCooldownAuraActiveState,
      func = function() ResetCooldownSectionSettings("auraActiveState") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- RANGE INDICATOR SECTION
    -- ═══════════════════════════════════════════════════════════════════
    rangeIndicatorHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("rangeIndicator", "Range Indicator") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.rangeIndicator end,
      set = function(_, v) collapsedSections.rangeIndicator = not v end,
      order = 108,
      width = "full",
      hidden = function()
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return false
      end,
    },
    rangeEnabled = {
      type = "toggle", name = "Show Range Overlay",
      desc = "Show the out-of-range darkening overlay when spells are out of range",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.rangeIndicator and c.rangeIndicator.enabled ~= false end, function() local c = GetCooldownCfg(); return c and c.rangeIndicator and c.rangeIndicator.enabled ~= false end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.rangeIndicator then c.rangeIndicator = {} end; c.rangeIndicator.enabled = v end) end,
      order = 108.1, width = 1.0, hidden = HideCooldownRangeIndicator,
    },
    resetRangeIndicator = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Range Indicator settings to defaults for selected icon(s)",
      order = 108.9,
      width = 0.7,
      hidden = HideCooldownRangeIndicator,
      func = function() ResetCooldownSectionSettings("rangeIndicator") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- PROC GLOW SECTION
    -- ═══════════════════════════════════════════════════════════════════
    procGlowHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("procGlow", "Proc Glow") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.procGlow end,
      set = function(_, v) collapsedSections.procGlow = not v end,
      order = 109,
      width = "full",
      hidden = function()
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return false
      end,
    },
    procGlowEnabled = {
      type = "toggle", name = "Show Glow",
      desc = "Show the proc glow animation when ability procs",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.procGlow and c.procGlow.enabled ~= false end, function() local c = GetCooldownCfg(); return c and c.procGlow and c.procGlow.enabled ~= false end) end,
      set = function(_, v) ApplyCooldownGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.enabled = v end) end,
      order = 109.1, width = 0.6, hidden = HideCooldownProcGlow,
    },
    procGlowPreview = {
      type = "toggle", name = "Preview",
      desc = "Toggle proc glow preview for selected icon(s). Preview will automatically stop when you close the options panel.",
      get = function()
        return ns.CDMEnhanceOptions.GetProcGlowPreviewState(false)
      end,
      set = function(_, v)
        ns.CDMEnhanceOptions.ToggleProcGlowPreviewForSelection(false)
      end,
      order = 109.11, width = 0.5, hidden = HideCooldownProcGlow,
    },
    procGlowType = {
      type = "select", name = "Glow Style",
      desc = "Select the glow animation style\n\n|cffffd700Default|r - Blizzard's proc glow with proper sizing\n|cffffd700Proc|r - LibCustomGlow flashy proc effect\n|cffffd700Pixel|r - Rotating pixel lines\n|cffffd700AutoCast|r - Sparkle particles\n|cffffd700Button|r - Classic button glow",
      values = {
        ["default"] = "Default (Blizzard)",
        ["pixel"] = "Pixel Glow",
        ["autocast"] = "AutoCast Sparkles",
        ["button"] = "Button Glow",
        ["proc"] = "Proc Effect",
      },
      sorting = {"default", "proc", "pixel", "autocast", "button"},
      get = function() local c = GetCooldownCfg(); return c and c.procGlow and c.procGlow.glowType or "default" end,
      set = function(_, v) ApplyCooldownGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.glowType = v end) end,
      order = 109.15, width = 0.8, hidden = HideCooldownProcGlow,
    },
    procGlowColor = {
      type = "color", name = "Color",
      desc = "Glow color (white = default gold for custom types)",
      get = function()
        local c = GetCooldownCfg()
        local col = c and c.procGlow and c.procGlow.color
        if col then return col.r or 1, col.g or 1, col.b or 1 end
        return 1, 1, 1
      end,
      set = function(_, r, g, b)
        ApplyCooldownGlowSetting(function(c)
          if not c.procGlow then c.procGlow = {} end
          if r == 1 and g == 1 and b == 1 then
            c.procGlow.color = nil  -- Reset to default
          else
            c.procGlow.color = {r=r, g=g, b=b}
          end
        end)
      end,
      order = 109.2, width = 0.55,
      hidden = function()
        if HideCooldownProcGlow() then return true end
        local c = GetCooldownCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Hide for default type (color breaks Blizzard animation)
        return glowType == "default"
      end,
    },
    procGlowAlpha = {
      type = "range", name = "Intensity", min = 0, max = 1.0, step = 0.05,
      desc = "How bright the glow appears",
      get = function() local c = GetCooldownCfg(); return c and c.procGlow and c.procGlow.alpha or 1.0 end,
      set = function(_, v) ApplyCooldownGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.alpha = v end) end,
      order = 109.25, width = 0.6,
      hidden = function()
        if HideCooldownProcGlow() then return true end
        local c = GetCooldownCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Hide for default type (alpha changes can break Blizzard animation)
        return glowType == "default"
      end,
    },
    procGlowScale = {
      type = "range", name = "Scale", min = 0.25, max = 4.0, step = 0.05,
      desc = "Size of the glow effect",
      get = function() local c = GetCooldownCfg(); return c and c.procGlow and c.procGlow.scale or 1.0 end,
      set = function(_, v) ApplyCooldownGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.scale = v end) end,
      order = 109.3, width = 0.55, 
      hidden = function()
        if HideCooldownProcGlow() then return true end
        local c = GetCooldownCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Show for autocast and button types (scale works via SetScale)
        return glowType ~= "autocast" and glowType ~= "button"
      end,
    },
    procGlowSpeed = {
      type = "range", name = "Speed", min = 0.05, max = 1.0, step = 0.05,
      desc = "Animation speed (Pixel, AutoCast, Button only)",
      get = function() local c = GetCooldownCfg(); return c and c.procGlow and c.procGlow.speed or 0.25 end,
      set = function(_, v) ApplyCooldownGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.speed = v end) end,
      order = 109.35, width = 0.55,
      hidden = function()
        if HideCooldownProcGlow() then return true end
        local c = GetCooldownCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Speed doesn't apply to default or proc types
        return glowType == "default" or glowType == "proc"
      end,
    },
    procGlowLines = {
      type = "range", name = "Lines", min = 1, max = 16, step = 1,
      desc = "Number of glow lines",
      get = function() local c = GetCooldownCfg(); return c and c.procGlow and c.procGlow.lines or 8 end,
      set = function(_, v) ApplyCooldownGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.lines = v end) end,
      order = 109.4, width = 0.6,
      hidden = function()
        if HideCooldownProcGlow() then return true end
        local c = GetCooldownCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Only show for pixel type
        return glowType ~= "pixel"
      end,
    },
    procGlowThickness = {
      type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
      desc = "Thickness of glow lines",
      get = function() local c = GetCooldownCfg(); return c and c.procGlow and c.procGlow.thickness or 2 end,
      set = function(_, v) ApplyCooldownGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.thickness = v end) end,
      order = 109.45, width = 0.65,
      hidden = function()
        if HideCooldownProcGlow() then return true end
        local c = GetCooldownCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Only show for pixel type
        return glowType ~= "pixel"
      end,
    },
    procGlowParticles = {
      type = "range", name = "Particles", min = 1, max = 16, step = 1,
      desc = "Number of sparkle groups",
      get = function() local c = GetCooldownCfg(); return c and c.procGlow and c.procGlow.particles or 4 end,
      set = function(_, v) ApplyCooldownGlowSetting(function(c) if not c.procGlow then c.procGlow = {} end; c.procGlow.particles = v end) end,
      order = 109.5, width = 0.6,
      hidden = function()
        if HideCooldownProcGlow() then return true end
        local c = GetCooldownCfg()
        local glowType = c and c.procGlow and c.procGlow.glowType or "default"
        -- Only show for autocast type
        return glowType ~= "autocast"
      end,
    },
    resetProcGlow = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Proc Glow settings to defaults for selected icon(s)",
      order = 109.9,
      width = 0.7,
      hidden = HideCooldownProcGlow,
      func = function() ResetCooldownSectionSettings("procGlow") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- BORDER SECTION
    -- ═══════════════════════════════════════════════════════════════════
    borderHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("border", "Border") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.border end,
      set = function(_, v) collapsedSections.border = not v end,
      order = 110,
      width = "full",
      hidden = function()
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return false
      end,
    },
    borderEnabled = {
      type = "toggle", name = "Show Border",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.border and c.border.enabled end, function() local c = GetCooldownCfg(); return c and c.border and c.border.enabled end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.border then c.border = {} end; c.border.enabled = v end) end,
      order = 111, width = 0.7, hidden = HideCooldownBorder,
    },
    borderUseClass = {
      type = "toggle", name = "Class Color",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.border and c.border.useClassColor end, function() local c = GetCooldownCfg(); return c and c.border and c.border.useClassColor end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.border then c.border = {} end; c.border.useClassColor = v end) end,
      order = 112, width = 0.7, hidden = HideCooldownBorder,
    },
    borderThickness = {
      type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
      get = function() local c = GetCooldownCfg(); return c and c.border and c.border.thickness or 1 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.border then c.border = {} end; c.border.thickness = v end) end,
      order = 113, width = 0.6, hidden = HideCooldownBorder,
    },
    borderInset = {
      type = "range", name = "Offset", min = -20, max = 20, step = 1,
      desc = "Border position offset. Negative = outset (outside icon), Positive = inset (inside icon). Automatically accounts for zoom.",
      get = function() local c = GetCooldownCfg(); return c and c.border and c.border.inset or 0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.border then c.border = {} end; c.border.inset = v end) end,
      order = 114, width = 0.6, hidden = HideCooldownBorder,
    },
    borderColor = {
      type = "color", name = "Color", hasAlpha = true,
      desc = "Border color (ignored if using class color)",
      get = function()
        local c = GetCooldownCfg()
        local col = c and c.border and c.border.color or {1,1,1,1}
        return col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1
      end,
      set = function(_, r, g, b, a)
        ApplySharedCooldownSetting(function(c) if not c.border then c.border = {} end; c.border.color = {r, g, b, a} end)
      end,
      order = 115, width = 0.55, hidden = HideCooldownBorder,
    },
    borderFollowDesat = {
      type = "toggle", name = "Follow Desat",
      desc = "Desaturate border when icon is desaturated (cooldown state)",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.border and c.border.followDesaturation end, function() local c = GetCooldownCfg(); return c and c.border and c.border.followDesaturation end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.border then c.border = {} end; c.border.followDesaturation = v end) end,
      order = 116, width = 0.65, hidden = HideCooldownBorder,
    },
    resetBorder = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Border settings to defaults for selected icon(s)",
      order = 119,
      width = 0.7,
      hidden = HideCooldownBorder,
      func = function() ResetCooldownSectionSettings("border") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- COOLDOWN SWIPE SECTION
    -- ═══════════════════════════════════════════════════════════════════
    cooldownSwipeHeader = {
      type = "toggle",
      name = function() 
        local baseName = GetCooldownHeaderName("cooldownSwipe", "Cooldown Animation")
        if IsMasqueCooldownsActive() then
          return baseName .. " |cff00CCFF(Masque)|r"
        end
        return baseName
      end,
      desc = function()
        if IsMasqueCooldownsActive() then
          return "|cff00CCFFMasque controls most cooldown settings.|r You can still change swipe COLOR here (works in combat). Other options require disabling 'Use Masque Cooldowns' in Global Options."
        end
        return "Click to expand/collapse. Purple dot indicates per-icon customizations."
      end,
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.cooldownSwipe end,
      set = function(_, v) collapsedSections.cooldownSwipe = not v end,
      order = 120,
      width = "full",
      hidden = function()
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return false
      end,
      -- NOT disabled - users need to expand this to access swipe color options
    },
    -- Row 1: Preview + Finish Flash + No GCD
    cooldownPreview = {
      type = "toggle", name = "Preview",
      desc = "Show a preview cooldown animation to see your changes in real-time",
      get = function() return ns.CDMEnhance and ns.CDMEnhance.IsCooldownPreviewMode() end,
      set = function(_, v) 
        if ns.CDMEnhance then 
          ns.CDMEnhance.SetCooldownPreviewMode(v) 
        end 
      end,
      order = 120.1, width = 0.5, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    showBling = {
      type = "toggle", name = "Finish Flash",
      desc = "Flash when cooldown finishes",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.showBling ~= false end, function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.showBling ~= false end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.showBling = v end) end,
      order = 120.2, width = 0.7, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipeExceptBling,
    },
    noGCDSwipe = {
      type = "toggle", name = "No GCD",
      desc = "Hide GCD swipes (cooldowns 1.5s or less). Only shows the swipe animation for actual spell cooldowns.",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.noGCDSwipe end, function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.noGCDSwipe or false end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.noGCDSwipe = v end) end,
      order = 120.3, width = 0.5, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipeExceptNoGCD,
    },
    swipeWaitForNoCharges = {
      type = "toggle", name = "Wait No Charges",
      desc = "For charge spells: Only show swipe when ALL charges are consumed. When disabled, shows swipe during any charge recharge.",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.swipeWaitForNoCharges end, function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeWaitForNoCharges or false end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeWaitForNoCharges = v end) end,
      order = 120.4, width = 0.7, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- SWIPE (the darkening overlay)
    -- ═══════════════════════════════════════════════════════════════════
    swipeSpacer = { type = "description", name = "", order = 121, width = "full", hidden = HideCooldownCooldownSwipe },
    swipeLabel = {
      type = "description", name = "|cffccccccSwipe|r",
      order = 121.05, width = 0.35, fontSize = "medium", hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    showSwipe = {
      type = "toggle", name = "Show",
      desc = "The darkening clock animation overlay",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.showSwipe ~= false end, function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.showSwipe ~= false end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.showSwipe = v end) end,
      order = 121.1, width = 0.4, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    reverseSwipe = {
      type = "toggle", name = "Reverse",
      desc = "Reverse the swipe direction",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.reverse end, function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.reverse end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.reverse = v end) end,
      order = 121.2, width = 0.5, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    useCustomSwipeColor = {
      type = "toggle", name = "Color",
      desc = function()
        if IsMasqueCooldownsActive() then
          return "|cff00CCFFMasque controls swipe color.|r ArcUI applies Masque's skin color using a method that works in combat."
        end
        return "Use a custom swipe color instead of the default"
      end,
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.swipeColor ~= nil end, function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeColor ~= nil end) end,
      set = function(_, v)
        ApplySharedCooldownSetting(function(c)
          if not c.cooldownSwipe then c.cooldownSwipe = {} end
          if v then
            c.cooldownSwipe.swipeColor = {r=0, g=0, b=0, a=0.8}
          else
            c.cooldownSwipe.swipeColor = nil
          end
        end)
      end,
      order = 121.3, width = 0.4, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipeExceptColor,
    },
    swipeColor = {
      type = "color", name = "", hasAlpha = true,
      desc = "Color of the swipe overlay",
      get = function()
        local c = GetCooldownCfg()
        local col = c and c.cooldownSwipe and c.cooldownSwipe.swipeColor or {r=0,g=0,b=0,a=0.8}
        return col.r or 0, col.g or 0, col.b or 0, col.a or 0.8
      end,
      set = function(_, r, g, b, a)
        ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeColor = {r=r, g=g, b=b, a=a} end)
      end,
      order = 121.4, width = 0.3,
      hidden = function()
        if HideCooldownCooldownSwipe() then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownSwipe and c.cooldownSwipe.swipeColor)
      end,
    },
    -- Swipe Inset (same row as swipe)
    swipeInset = {
      type = "range", name = "Inset", min = -20, max = 40, step = 1,
      desc = "Inset for the swipe animation (all sides). Positive = smaller, negative = larger.",
      get = function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeInset or 0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeInset = v end) end,
      order = 121.5, width = 0.7,
      hidden = function()
        if HideCooldownCooldownSwipe() then return true end
        local c = GetCooldownCfg()
        return c and c.cooldownSwipe and c.cooldownSwipe.separateInsets
      end,
    },
    separateInsets = {
      type = "toggle", name = "W/H",
      desc = "Enable separate Width and Height insets instead of a single inset",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.separateInsets end, function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.separateInsets end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.separateInsets = v end) end,
      order = 121.6, width = 0.35, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    swipeInsetX = {
      type = "range", name = "Inset W", min = -20, max = 40, step = 1,
      desc = "Horizontal inset (left/right). Positive = narrower, negative = wider.",
      get = function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeInsetX or 0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeInsetX = v end) end,
      order = 121.7, width = 0.55,
      hidden = function()
        if HideCooldownCooldownSwipe() then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownSwipe and c.cooldownSwipe.separateInsets)
      end,
    },
    swipeInsetY = {
      type = "range", name = "H", min = -20, max = 40, step = 1,
      desc = "Vertical inset (top/bottom). Positive = shorter, negative = taller.",
      get = function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.swipeInsetY or 0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.swipeInsetY = v end) end,
      order = 121.8, width = 0.45,
      hidden = function()
        if HideCooldownCooldownSwipe() then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownSwipe and c.cooldownSwipe.separateInsets)
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- EDGE (the spinning line)
    -- ═══════════════════════════════════════════════════════════════════
    edgeSpacer = { type = "description", name = "", order = 122, width = "full", hidden = HideCooldownCooldownSwipe },
    edgeLabel = {
      type = "description", name = "|cffccccccEdge|r",
      order = 122.05, width = 0.35, fontSize = "medium", hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    showEdge = {
      type = "toggle", name = "Show",
      desc = "The spinning bright line on the cooldown edge",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.showEdge ~= false end, function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.showEdge ~= false end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.showEdge = v end) end,
      order = 122.1, width = 0.4, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    edgeScale = {
      type = "range", name = "Scale", min = 0.1, max = 3.0, step = 0.1,
      desc = "Size of the cooldown edge spinner",
      get = function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.edgeScale or 1.0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.edgeScale = v end) end,
      order = 122.2, width = 0.6, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    edgeColorEnabled = {
      type = "toggle", name = "Color",
      desc = "Enable custom edge color",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownSwipe and c.cooldownSwipe.edgeColor ~= nil end, function() local c = GetCooldownCfg(); return c and c.cooldownSwipe and c.cooldownSwipe.edgeColor ~= nil end) end,
      set = function(_, v)
        ApplySharedCooldownSetting(function(c) 
          if not c.cooldownSwipe then c.cooldownSwipe = {} end
          if v then
            c.cooldownSwipe.edgeColor = {r=1, g=1, b=1, a=1}
          else
            c.cooldownSwipe.edgeColor = nil
          end
        end)
      end,
      order = 122.3, width = 0.4, hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
    },
    edgeColor = {
      type = "color", name = "", hasAlpha = true,
      desc = "Color of the spinning edge line",
      get = function()
        local c = GetCooldownCfg()
        local col = c and c.cooldownSwipe and c.cooldownSwipe.edgeColor or {r=1,g=1,b=1,a=1}
        return col.r or 1, col.g or 1, col.b or 1, col.a or 1
      end,
      set = function(_, r, g, b, a)
        ApplySharedCooldownSetting(function(c) if not c.cooldownSwipe then c.cooldownSwipe = {} end; c.cooldownSwipe.edgeColor = {r=r, g=g, b=b, a=a} end)
      end,
      order = 122.4, width = 0.3,
      hidden = function()
        if HideCooldownCooldownSwipe() then return true end
        local c = GetCooldownCfg()
        return not (c and c.cooldownSwipe and c.cooldownSwipe.edgeColor)
      end,
    },
    
    resetSpacer = { type = "description", name = "", order = 128, width = "full", hidden = HideCooldownCooldownSwipe },
    resetCooldownSwipe = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Cooldown Animation settings to defaults for selected icon(s)",
      order = 129,
      width = 0.7,
      hidden = HideCooldownCooldownSwipe, disabled = DisableCooldownCooldownSwipe,
      func = function() ResetCooldownSectionSettings("cooldownSwipe") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CHARGE TEXT SECTION
    -- ═══════════════════════════════════════════════════════════════════
    chargeTextHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("chargeText", "Charge/Stack Text") end,
      desc = "Click to expand/collapse. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.chargeText end,
      set = function(_, v) collapsedSections.chargeText = not v end,
      order = 130,
      width = "full",
      hidden = function()
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return false
      end,
    },
    chargeEnabled = {
      type = "toggle", name = "Show",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.chargeText and c.chargeText.enabled ~= false end, function() local c = GetCooldownCfg(); return c and c.chargeText and c.chargeText.enabled ~= false end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.enabled = v end) end,
      order = 131, width = 0.55, hidden = HideCooldownChargeText,
    },
    chargeTextDrag = {
      type = "toggle", name = "Text Drag",
      desc = "Enable dragging charge text to custom positions",
      get = function() return ns.CDMEnhance and ns.CDMEnhance.IsTextDragMode() end,
      set = function(_, v) if ns.CDMEnhance then ns.CDMEnhance.SetTextDragMode(v) end end,
      order = 131.6, width = 0.6, hidden = HideCooldownChargeText,
    },
    chargeSize = {
      type = "range", name = "Size", min = 4, max = 64, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.chargeText and c.chargeText.size or 16 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.size = v end) end,
      order = 132, width = 0.6, hidden = HideCooldownChargeText,
    },
    chargeColor = {
      type = "color", name = "Color", hasAlpha = true,
      get = function()
        local c = GetCooldownCfg()
        local col = c and c.chargeText and c.chargeText.color or {r=1,g=1,b=0,a=1}
        return col.r or 1, col.g or 1, col.b or 0, col.a or 1
      end,
      set = function(_, r, g, b, a)
        ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.color = {r=r, g=g, b=b, a=a} end)
      end,
      order = 133, width = 0.55, hidden = HideCooldownChargeText,
    },
    chargeFont = {
      type = "select", name = "Font", dialogControl = "LSM30_Font",
      values = LSM and LSM:HashTable("font") or {},
      get = function() local c = GetCooldownCfg(); return c and c.chargeText and c.chargeText.font or "Friz Quadrata TT" end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.font = v end) end,
      order = 134, width = 0.9, hidden = HideCooldownChargeText,
    },
    chargeOutline = {
      type = "select", name = "Outline", values = FONT_OUTLINES,
      get = function() local c = GetCooldownCfg(); return GetOutlineValue(c and c.chargeText and c.chargeText.outline) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.outline = v end) end,
      order = 135, width = 0.85, hidden = HideCooldownChargeText,
    },
    chargeShadow = {
      type = "toggle", name = "Shadow",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.chargeText and c.chargeText.shadow end, function() local c = GetCooldownCfg(); return c and c.chargeText and c.chargeText.shadow end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.shadow = v end) end,
      order = 136, width = 0.55, hidden = HideCooldownChargeText,
    },
    chargeShadowX = {
      type = "range", name = "Shadow X", min = -20, max = 20, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.chargeText and c.chargeText.shadowOffsetX or 1 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.shadowOffsetX = v end) end,
      order = 137, width = 0.55, hidden = function() return HideCooldownChargeText() or not (GetCooldownCfg() and GetCooldownCfg().chargeText and GetCooldownCfg().chargeText.shadow) end,
    },
    chargeShadowY = {
      type = "range", name = "Shadow Y", min = -20, max = 20, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.chargeText and c.chargeText.shadowOffsetY or -1 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.shadowOffsetY = v end) end,
      order = 138, width = 0.55, hidden = function() return HideCooldownChargeText() or not (GetCooldownCfg() and GetCooldownCfg().chargeText and GetCooldownCfg().chargeText.shadow) end,
    },
    
    -- Position Mode
    chargePositionHeader = {
      type = "description", name = "\n|cffffd700Position|r", order = 139, width = "full", hidden = HideCooldownChargeText,
    },
    chargeMode = {
      type = "select", name = "Mode", values = TEXT_MODES,
      desc = "Anchor = fixed position. Free = drag anywhere (automatically enables Text Drag Mode)",
      get = function() local c = GetCooldownCfg(); return c and c.chargeText and c.chargeText.mode or "anchor" end,
      set = function(_, v)
        ApplySharedCooldownSetting(function(c)
          if not c.chargeText then c.chargeText = {} end
          c.chargeText.mode = v
        end)
        -- Auto-enable text drag mode when switching to free
        if v == "free" and ns.CDMEnhance and not ns.CDMEnhance.IsTextDragMode() then
          ns.CDMEnhance.SetTextDragMode(true)
        end
      end,
      order = 140, width = 0.85, hidden = HideCooldownChargeText,
    },
    chargeAnchor = {
      type = "select", name = "Anchor", values = TEXT_ANCHORS,
      get = function() local c = GetCooldownCfg(); return c and c.chargeText and (c.chargeText.anchor or c.chargeText.position) or "BOTTOMRIGHT" end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.anchor = v; c.chargeText.position = v end) end,
      order = 141, width = 0.75, hidden = function() return HideCooldownChargeText() or (GetCooldownCfg() and GetCooldownCfg().chargeText and GetCooldownCfg().chargeText.mode == "free") end,
    },
    chargeOffsetX = {
      type = "range", name = "X Offset", min = -100, max = 100, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.chargeText and c.chargeText.offsetX or -2 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.offsetX = v end) end,
      order = 142, width = 0.55, hidden = function() return HideCooldownChargeText() or (GetCooldownCfg() and GetCooldownCfg().chargeText and GetCooldownCfg().chargeText.mode == "free") end,
    },
    chargeOffsetY = {
      type = "range", name = "Y Offset", min = -100, max = 100, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.chargeText and c.chargeText.offsetY or 2 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.chargeText then c.chargeText = {} end; c.chargeText.offsetY = v end) end,
      order = 143, width = 0.55, hidden = function() return HideCooldownChargeText() or (GetCooldownCfg() and GetCooldownCfg().chargeText and GetCooldownCfg().chargeText.mode == "free") end,
    },
    chargeFreeHint = {
      type = "description", 
      name = "|cff00ff00Text Drag Mode enabled.|r |cff888888Drag the charge text in-game to position it.|r",
      order = 144, width = "full", 
      hidden = function() return HideCooldownChargeText() or not (GetCooldownCfg() and GetCooldownCfg().chargeText and GetCooldownCfg().chargeText.mode == "free") end,
    },
    resetChargeText = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Charge/Stack Text settings to defaults for selected icon(s)",
      order = 149,
      width = 0.7,
      hidden = HideCooldownChargeText,
      func = function() ResetCooldownSectionSettings("chargeText") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- COOLDOWN TEXT SECTION
    -- ═══════════════════════════════════════════════════════════════════
    cooldownTextHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("cooldownText", "Duration/Cooldown Text Style") end,
      desc = "Click to expand/collapse. Style the duration/countdown timer. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.cooldownText end,
      set = function(_, v) collapsedSections.cooldownText = not v end,
      order = 150,
      width = "full",
      hidden = function()
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return false
      end,
    },
    cdEnabled = {
      type = "toggle", name = "Show",
      desc = "Show custom cooldown timer text",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownText and c.cooldownText.enabled ~= false end, function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.enabled ~= false end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.enabled = v end) end,
      order = 151, width = 0.55, hidden = HideCooldownCooldownText,
    },
    cdTextDrag = {
      type = "toggle", name = "Text Drag",
      desc = "Enable dragging cooldown text to custom positions",
      get = function() return ns.CDMEnhance and ns.CDMEnhance.IsTextDragMode() end,
      set = function(_, v) if ns.CDMEnhance then ns.CDMEnhance.SetTextDragMode(v) end end,
      order = 151.5, width = 0.6, hidden = HideCooldownCooldownText,
    },
    cdSize = {
      type = "range", name = "Size", min = 4, max = 64, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.size or 14 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.size = v end) end,
      order = 152, width = 0.6, hidden = HideCooldownCooldownText,
    },
    cdColor = {
      type = "color", name = "Color", hasAlpha = true,
      get = function()
        local c = GetCooldownCfg()
        local col = c and c.cooldownText and c.cooldownText.color or {r=1,g=1,b=1,a=1}
        return col.r or 1, col.g or 1, col.b or 1, col.a or 1
      end,
      set = function(_, r, g, b, a)
        ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.color = {r=r, g=g, b=b, a=a} end)
      end,
      order = 153, width = 0.55, hidden = HideCooldownCooldownText,
    },
    cdFont = {
      type = "select", name = "Font", dialogControl = "LSM30_Font",
      values = LSM and LSM:HashTable("font") or {},
      get = function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.font or "Friz Quadrata TT" end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.font = v end) end,
      order = 154, width = 0.9, hidden = HideCooldownCooldownText,
    },
    cdOutline = {
      type = "select", name = "Outline", values = FONT_OUTLINES,
      get = function() local c = GetCooldownCfg(); return GetOutlineValue(c and c.cooldownText and c.cooldownText.outline) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.outline = v end) end,
      order = 155, width = 0.85, hidden = HideCooldownCooldownText,
    },
    cdShadow = {
      type = "toggle", name = "Shadow",
      get = function() return GetCooldownBoolSetting(function(c) return c and c.cooldownText and c.cooldownText.shadow end, function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.shadow end) end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.shadow = v end) end,
      order = 156, width = 0.55, hidden = HideCooldownCooldownText,
    },
    cdShadowX = {
      type = "range", name = "Shadow X", min = -20, max = 20, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.shadowOffsetX or 1 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.shadowOffsetX = v end) end,
      order = 157, width = 0.55, hidden = function() return HideCooldownCooldownText() or not (GetCooldownCfg() and GetCooldownCfg().cooldownText and GetCooldownCfg().cooldownText.shadow) end,
    },
    cdShadowY = {
      type = "range", name = "Shadow Y", min = -20, max = 20, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.shadowOffsetY or -1 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.shadowOffsetY = v end) end,
      order = 158, width = 0.55, hidden = function() return HideCooldownCooldownText() or not (GetCooldownCfg() and GetCooldownCfg().cooldownText and GetCooldownCfg().cooldownText.shadow) end,
    },
    
    -- Position Mode
    cdPositionHeader = {
      type = "description", name = "\n|cffffd700Position|r", order = 159, width = "full", hidden = HideCooldownCooldownText,
    },
    cdMode = {
      type = "select", name = "Mode", values = TEXT_MODES,
      desc = "Anchor = fixed position. Free = drag anywhere (automatically enables Text Drag Mode)",
      get = function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.mode or "anchor" end,
      set = function(_, v)
        ApplySharedCooldownSetting(function(c)
          if not c.cooldownText then c.cooldownText = {} end
          c.cooldownText.mode = v
        end)
        -- Auto-enable text drag mode when switching to free
        if v == "free" and ns.CDMEnhance and not ns.CDMEnhance.IsTextDragMode() then
          ns.CDMEnhance.SetTextDragMode(true)
        end
      end,
      order = 160, width = 0.85, hidden = HideCooldownCooldownText,
    },
    cdAnchor = {
      type = "select", name = "Anchor", values = TEXT_ANCHORS,
      get = function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.anchor or "CENTER" end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.anchor = v end) end,
      order = 161, width = 0.75, hidden = function() return HideCooldownCooldownText() or (GetCooldownCfg() and GetCooldownCfg().cooldownText and GetCooldownCfg().cooldownText.mode == "free") end,
    },
    cdOffsetX = {
      type = "range", name = "X Offset", min = -100, max = 100, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.offsetX or 0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.offsetX = v end) end,
      order = 162, width = 0.55, hidden = function() return HideCooldownCooldownText() or (GetCooldownCfg() and GetCooldownCfg().cooldownText and GetCooldownCfg().cooldownText.mode == "free") end,
    },
    cdOffsetY = {
      type = "range", name = "Y Offset", min = -100, max = 100, step = 1,
      get = function() local c = GetCooldownCfg(); return c and c.cooldownText and c.cooldownText.offsetY or 0 end,
      set = function(_, v) ApplySharedCooldownSetting(function(c) if not c.cooldownText then c.cooldownText = {} end; c.cooldownText.offsetY = v end) end,
      order = 163, width = 0.55, hidden = function() return HideCooldownCooldownText() or (GetCooldownCfg() and GetCooldownCfg().cooldownText and GetCooldownCfg().cooldownText.mode == "free") end,
    },
    cdFreeHint = {
      type = "description", 
      name = "|cff00ff00Text Drag Mode enabled.|r |cff888888Drag the cooldown text in-game to position it.|r",
      order = 164, width = "full", 
      hidden = function() return HideCooldownCooldownText() or not (GetCooldownCfg() and GetCooldownCfg().cooldownText and GetCooldownCfg().cooldownText.mode == "free") end,
    },
    resetCooldownText = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Cooldown Text settings to defaults for selected icon(s)",
      order = 165,
      width = 0.7,
      hidden = HideCooldownCooldownText,
      func = function() ResetCooldownSectionSettings("cooldownText") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- KEYBIND TEXT SECTION
    -- ═══════════════════════════════════════════════════════════════════
    keybindTextHeader = {
      type = "toggle",
      name = function() return GetCooldownHeaderName("keybindText", "Keybind Display") end,
      desc = "Click to expand/collapse. Per-icon keybind display settings. Purple dot indicates per-icon customizations.",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsedSections.keybindText end,
      set = function(_, v) collapsedSections.keybindText = not v end,
      order = 170,
      width = "full",
      hidden = function()
        if HideIfNoCooldownSelection() then return true end
        if IsEditingMixedTypes() then return true end
        return false
      end,
    },
    keybindEnabled = {
      type = "toggle", name = "Show",
      desc = "Show keybind text on this icon. Uses global settings if no per-icon overrides are set.",
      get = function()
        local c = GetCooldownCfg()
        -- hideKeybind = true means disabled, so invert
        return not (c and c.hideKeybind == true)
      end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          c.hideKeybind = (not v) or nil  -- nil when showing to keep settings clean
        end)
        if ns.Keybinds and ns.Keybinds.RefreshAll then
          ns.Keybinds.RefreshAll()
        end
      end,
      order = 171, width = 0.5, hidden = HideCooldownKeybindText,
    },
    keybindUsePerIcon = {
      type = "toggle", name = "Override Global",
      desc = "Use per-icon settings instead of global keybind settings",
      get = function()
        local c = GetCooldownCfg()
        return c and c.keybindText and c.keybindText.enabled == true
      end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.keybindText then c.keybindText = {} end
          c.keybindText.enabled = v or nil
        end)
        if ns.Keybinds and ns.Keybinds.RefreshAll then
          ns.Keybinds.RefreshAll()
        end
      end,
      order = 171.5, width = 0.7, hidden = HideCooldownKeybindText,
    },
    keybindSize = {
      type = "range", name = "Size", min = 6, max = 32, step = 1,
      desc = "Font size for keybind text",
      get = function() local c = GetCooldownCfg(); return c and c.keybindText and c.keybindText.size or 12 end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.keybindText then c.keybindText = {} end
          c.keybindText.size = v
        end)
        if ns.Keybinds and ns.Keybinds.QueueRefresh then
          ns.Keybinds.QueueRefresh()
        end
      end,
      order = 172, width = 0.6,
      hidden = function()
        if HideCooldownKeybindText() then return true end
        local c = GetCooldownCfg()
        return not (c and c.keybindText and c.keybindText.enabled)
      end,
    },
    keybindColor = {
      type = "color", name = "Color", hasAlpha = true,
      desc = "Color of keybind text",
      get = function()
        local c = GetCooldownCfg()
        local col = c and c.keybindText and c.keybindText.color or {1,1,1,1}
        return col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1
      end,
      set = function(_, r, g, b, a)
        ApplyCooldownSetting(function(c)
          if not c.keybindText then c.keybindText = {} end
          c.keybindText.color = {r, g, b, a}
        end)
        if ns.Keybinds and ns.Keybinds.QueueRefresh then
          ns.Keybinds.QueueRefresh()
        end
      end,
      order = 173, width = 0.5,
      hidden = function()
        if HideCooldownKeybindText() then return true end
        local c = GetCooldownCfg()
        return not (c and c.keybindText and c.keybindText.enabled)
      end,
    },
    keybindFont = {
      type = "select", name = "Font",
      desc = "Font for keybind text",
      dialogControl = "LSM30_Font",
      values = AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {},
      get = function() local c = GetCooldownCfg(); return c and c.keybindText and c.keybindText.font or "Friz Quadrata TT" end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.keybindText then c.keybindText = {} end
          c.keybindText.font = v
        end)
        if ns.Keybinds and ns.Keybinds.QueueRefresh then
          ns.Keybinds.QueueRefresh()
        end
      end,
      order = 174, width = 1.0,
      hidden = function()
        if HideCooldownKeybindText() then return true end
        local c = GetCooldownCfg()
        return not (c and c.keybindText and c.keybindText.enabled)
      end,
    },
    keybindOutline = {
      type = "select", name = "Outline",
      desc = "Font outline style",
      values = { [""] = "None", ["OUTLINE"] = "Thin", ["THICKOUTLINE"] = "Thick", ["MONOCHROME"] = "Mono" },
      get = function() local c = GetCooldownCfg(); return c and c.keybindText and c.keybindText.outline or "OUTLINE" end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.keybindText then c.keybindText = {} end
          c.keybindText.outline = v
        end)
        if ns.Keybinds and ns.Keybinds.QueueRefresh then
          ns.Keybinds.QueueRefresh()
        end
      end,
      order = 175, width = 0.6,
      hidden = function()
        if HideCooldownKeybindText() then return true end
        local c = GetCooldownCfg()
        return not (c and c.keybindText and c.keybindText.enabled)
      end,
    },
    keybindAnchor = {
      type = "select", name = "Anchor",
      desc = "Position of keybind text on icon",
      values = TEXT_ANCHORS,
      get = function() local c = GetCooldownCfg(); return c and c.keybindText and c.keybindText.anchor or "TOPRIGHT" end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.keybindText then c.keybindText = {} end
          c.keybindText.anchor = v
        end)
        if ns.Keybinds and ns.Keybinds.QueueRefresh then
          ns.Keybinds.QueueRefresh()
        end
      end,
      order = 176, width = 0.7,
      hidden = function()
        if HideCooldownKeybindText() then return true end
        local c = GetCooldownCfg()
        return not (c and c.keybindText and c.keybindText.enabled)
      end,
    },
    keybindOffsetX = {
      type = "range", name = "X Offset", min = -50, max = 50, step = 1,
      desc = "Horizontal offset",
      get = function() local c = GetCooldownCfg(); return c and c.keybindText and c.keybindText.offsetX or 0 end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.keybindText then c.keybindText = {} end
          c.keybindText.offsetX = v
        end)
        if ns.Keybinds and ns.Keybinds.QueueRefresh then
          ns.Keybinds.QueueRefresh()
        end
      end,
      order = 177, width = 0.6,
      hidden = function()
        if HideCooldownKeybindText() then return true end
        local c = GetCooldownCfg()
        return not (c and c.keybindText and c.keybindText.enabled)
      end,
    },
    keybindOffsetXInput = {
      type = "input", name = "X",
      desc = "Type an exact X offset value (any integer)",
      dialogControl = "ArcUI_EditBox",
      get = function() local c = GetCooldownCfg(); return tostring(c and c.keybindText and c.keybindText.offsetX or 0) end,
      set = function(_, v)
        local num = tonumber(v)
        if num then
          ApplyCooldownSetting(function(c)
            if not c.keybindText then c.keybindText = {} end
            c.keybindText.offsetX = math.floor(num)
          end)
          if ns.Keybinds and ns.Keybinds.QueueRefresh then
            ns.Keybinds.QueueRefresh()
          end
        end
      end,
      order = 177.5, width = 0.35,
      hidden = function()
        if HideCooldownKeybindText() then return true end
        local c = GetCooldownCfg()
        return not (c and c.keybindText and c.keybindText.enabled)
      end,
    },
    keybindOffsetY = {
      type = "range", name = "Y Offset", min = -50, max = 50, step = 1,
      desc = "Vertical offset",
      get = function() local c = GetCooldownCfg(); return c and c.keybindText and c.keybindText.offsetY or 0 end,
      set = function(_, v)
        ApplyCooldownSetting(function(c)
          if not c.keybindText then c.keybindText = {} end
          c.keybindText.offsetY = v
        end)
        if ns.Keybinds and ns.Keybinds.QueueRefresh then
          ns.Keybinds.QueueRefresh()
        end
      end,
      order = 178, width = 0.6,
      hidden = function()
        if HideCooldownKeybindText() then return true end
        local c = GetCooldownCfg()
        return not (c and c.keybindText and c.keybindText.enabled)
      end,
    },
    keybindOffsetYInput = {
      type = "input", name = "Y",
      desc = "Type an exact Y offset value (any integer)",
      dialogControl = "ArcUI_EditBox",
      get = function() local c = GetCooldownCfg(); return tostring(c and c.keybindText and c.keybindText.offsetY or 0) end,
      set = function(_, v)
        local num = tonumber(v)
        if num then
          ApplyCooldownSetting(function(c)
            if not c.keybindText then c.keybindText = {} end
            c.keybindText.offsetY = math.floor(num)
          end)
          if ns.Keybinds and ns.Keybinds.QueueRefresh then
            ns.Keybinds.QueueRefresh()
          end
        end
      end,
      order = 178.5, width = 0.35,
      hidden = function()
        if HideCooldownKeybindText() then return true end
        local c = GetCooldownCfg()
        return not (c and c.keybindText and c.keybindText.enabled)
      end,
    },
    resetKeybindText = {
      type = "execute",
      name = "Reset Section",
      desc = "Reset Keybind Display settings to defaults for selected icon(s)",
      order = 185,
      width = 0.7,
      hidden = HideCooldownKeybindText,
      func = function() ResetCooldownSectionSettings("keybindText") end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CUSTOM LABEL SECTION  → defined in ArcUI_CustomLabelOptions.lua
    -- Entries are merged into this args table below (after catalog icons)
    -- ═══════════════════════════════════════════════════════════════════
    
    -- ═══════════════════════════════════════════════════════════════════
    -- BOTTOM BUTTONS (side by side)
    -- ═══════════════════════════════════════════════════════════════════
    bottomSpacer = {
      type = "header",
      name = "",
      order = 190,
    },
    
    noSelectionHint = {
      type = "description",
      name = "\n|cff888888Click an icon in the catalog above to customize it.|r",
      order = 191,
      hidden = function() return selectedCooldownIcon ~= nil end,
    },
    
    resetSingleIconBtn = {
      type = "execute",
      name = "Reset Selected Icon Settings",
      desc = "Remove all per-icon customizations from the selected icon. The icon will use global defaults instead.",
      func = function()
        if selectedCooldownIcon and ns.CDMEnhance and ns.CDMEnhance.ResetIconToDefaults then
          ns.CDMEnhance.ResetIconToDefaults(selectedCooldownIcon)
          print("|cff00FF00[ArcUI CDM]|r Cleared per-icon settings. Icon now uses global defaults.")
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end
      end,
      order = 194,
      width = 1.35,
      hidden = function()
        -- Only show when a single icon is selected AND it has customizations
        if editAllCooldownsMode or next(selectedCooldownIcons) or not selectedCooldownIcon then
          return true
        end
        return not (ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(selectedCooldownIcon))
      end,
      confirm = true,
      confirmText = "Reset all per-icon settings for this icon?\n\nThe icon will use global defaults instead.",
    },
    
    resetAllPositions = {
      type = "execute",
      name = "Reset All Positions",
      desc = "Reset all cooldown icon positions to default CDM layout",
      order = 195,
      width = 1.0,
      confirm = true,
      confirmText = "Reset all CDM cooldown icon positions to default?",
      func = function()
        if ns.CDMEnhance and ns.CDMEnhance.ResetAllCooldownPositions then
          ns.CDMEnhance.ResetAllCooldownPositions()
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    
    resetAllOptions = {
      type = "execute",
      name = "Reset All Options",
      desc = "Reset all cooldown icon customization settings to defaults (scale, text, glow, etc.)",
      order = 195.5,
      width = 1.0,
      confirm = true,
      confirmText = "Reset all cooldown icon customization settings to defaults? This will clear all custom styling.",
      func = function()
        if ns.CDMEnhance and ns.CDMEnhance.ResetAllIconsToDefaults then
          ns.CDMEnhance.ResetAllIconsToDefaults("cooldown")
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    
    deselectBtn = {
      type = "execute",
      name = "Deselect Icon",
      order = 196,
      width = 0.75,
      hidden = HideIfNoCooldownSelection,
      func = function()
        selectedCooldownIcon = nil
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
  }
  
  -- Add catalog icon grid (cooldowns only)
  for i = 1, 50 do
    args["catalogIcon" .. i] = CreateCooldownCatalogIconEntry(i)
  end
  
  -- Merge Custom Label options from external module
  if ns.CustomLabelOptions and ns.CustomLabelOptions.GetCooldownArgs then
    for k, v in pairs(ns.CustomLabelOptions.GetCooldownArgs()) do
      args[k] = v
    end
  end
  
  return {
    type = "group",
    name = "CDM Cooldown Icons",
    order = 1,
    args = args,
  }
end

-- ===================================================================
-- GLOBAL DEFAULTS OPTIONS TABLES
-- These create sub-tabs for configuring default settings for all icons
-- ===================================================================

-- Collapsed state for global defaults sections
local collapsedGlobalAuraSections = {
  iconAppearance = false,
  activeState = true,
  inactiveState = true,
  cooldownSwipe = false,
  chargeText = false,
  cooldownText = false,
  procGlow = false,
  rangeIndicator = true,
  border = true,
}

local collapsedGlobalCooldownSections = {
  iconAppearance = false,
  readyState = true,
  inactiveState = true,
  auraActiveState = true,  -- New section for aura active customizations
  cooldownSwipe = false,
  chargeText = false,
  cooldownText = false,
  procGlow = false,
  rangeIndicator = true,
  border = true,
}

-- Refresh all icons of a type after global change
local function RefreshGlobalAuras()
  if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
    ns.CDMEnhance.RefreshIconType("aura")
  end
  -- Refresh Masque skins after style changes
  if ns.Masque and ns.Masque.QueueRefresh then
    ns.Masque.QueueRefresh()
  end
end

local function RefreshGlobalCooldowns()
  if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
    ns.CDMEnhance.RefreshIconType("cooldown")
  end
  -- Refresh Masque skins after style changes
  if ns.Masque and ns.Masque.QueueRefresh then
    ns.Masque.QueueRefresh()
  end
end

function ns.GetCDMGlobalAuraDefaultsOptionsTable()
  return {
    type = "group",
    name = "Aura Defaults",
    order = 2,
    args = {
      desc = {
        type = "description",
        name = "|cff00ccffGlobal Defaults for Aura Icons|r\n\nThese settings apply to ALL aura icons automatically.\n\n|cffff9900Note:|r Icons with per-icon customizations will NOT be affected by these defaults. To apply defaults to a customized icon, use |cffffffffReset to Defaults|r on that icon first.",
        order = 1,
        fontSize = "medium",
      },
      openCDM = {
        type = "execute",
        name = "Open CD Manager",
        desc = "Open the Cooldown Manager settings panel",
        order = 1.5,
        width = 0.85,
        func = function()
          local frame = _G["CooldownViewerSettings"]
          if frame and frame.Show then
            frame:Show()
            frame:Raise()
          end
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- ICON APPEARANCE
      -- ═══════════════════════════════════════════════════════════════════
      iconAppearanceHeader = {
        type = "toggle", name = "Icon Appearance", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalAuraSections.iconAppearance end,
        set = function(_, v) collapsedGlobalAuraSections.iconAppearance = not v end,
        order = 10, width = "full",
      },
      masqueNotice = {
        type = "description",
        name = "|cffff9900Masque Active:|r Zoom, Aspect Ratio, and Padding are controlled by your Masque skin. Disable the skin group in Masque to use these settings.",
        order = 10.1,
        width = "full",
        fontSize = "medium",
        hidden = function() return collapsedGlobalAuraSections.iconAppearance or not IsMasqueActive() end,
      },
      scaleOverride = {
        type = "toggle", name = "Override",
        desc = "When enabled, this Default Scale controls the Aura group. When changed, it pushes the scale to the group.",
        get = function() return GetAuraGlobalCfg().scaleOverride end,
        set = function(_, v)
          ApplyAuraGlobalSetting("scaleOverride", v)
          if v then
            -- Push current default scale to aura group
            local defaultScale = GetAuraGlobalCfg().scale or 1.0
            if ns.CDMEnhance then
              ns.CDMEnhance.SetGroupScale("aura", defaultScale)
            end
          else
            -- Clear the group scale when disabling (restore Edit Mode control)
            if ns.CDMEnhance then
              ns.CDMEnhance.SetGroupScale("aura", nil)
            end
          end
          RefreshGlobalAuras()
        end,
        order = 10.5, width = 0.5, hidden = function() return collapsedGlobalAuraSections.iconAppearance end,
      },
      scale = {
        type = "range", name = "Default Scale", min = 0.25, max = 4.0, step = 0.05, isPercent = true,
        desc = function()
          local g = GetAuraGlobalCfg()
          if g.scaleOverride then
            return "Controls scale for the Aura group. Changes are pushed to the group."
          else
            return "Default scale for icons without Group Scale override enabled."
          end
        end,
        get = function() return GetAuraGlobalCfg().scale or 1.0 end,
        set = function(_, v)
          ApplyAuraGlobalSetting("scale", v)
          -- If override is ON, push to aura group
          local g = GetAuraGlobalCfg()
          if g.scaleOverride and ns.CDMEnhance then
            ns.CDMEnhance.SetGroupScale("aura", v)
          end
          RefreshGlobalAuras()
        end,
        order = 11, width = 1.1, hidden = function() return collapsedGlobalAuraSections.iconAppearance end,
      },
      alpha = {
        type = "range", name = "Opacity", min = 0, max = 1.0, step = 0.05,
        desc = "Overall icon opacity",
        get = function() return GetAuraGlobalCfg().alpha or 1.0 end,
        set = function(_, v) ApplyAuraGlobalSetting("alpha", v); RefreshGlobalAuras() end,
        order = 11.5, width = 0.8, hidden = function() return collapsedGlobalAuraSections.iconAppearance end,
      },
      aspectRatio = {
        type = "range", name = "Aspect Ratio", min = 0.25, max = 2.5, step = 0.05,
        desc = "Width/height ratio (1.0 = square).\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls icon appearance via its skin settings.",
        get = function() return GetAuraGlobalCfg().aspectRatio or 1.0 end,
        set = function(_, v) ApplyAuraGlobalSetting("aspectRatio", v); RefreshGlobalAuras() end,
        order = 11.6, width = 0.8, hidden = function() return collapsedGlobalAuraSections.iconAppearance end,
        disabled = IsMasqueActive,
      },
      zoom = {
        type = "range", name = "Zoom", min = 0, max = 0.3, step = 0.01,
        desc = "Crop edges to zoom into icon center.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls zoom via its skin settings.",
        get = function() return GetAuraGlobalCfg().zoom or 0.075 end,
        set = function(_, v) ApplyAuraGlobalSetting("zoom", v); RefreshGlobalAuras() end,
        order = 11.7, width = 0.8, hidden = function() return collapsedGlobalAuraSections.iconAppearance end,
        disabled = IsMasqueActive,
      },
      padding = {
        type = "range", name = "Padding", min = -5, max = 20, step = 1,
        desc = "Space between icon and frame edges.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls icon appearance via its skin settings.",
        get = function() return GetAuraGlobalCfg().padding or 0 end,
        set = function(_, v) ApplyAuraGlobalSetting("padding", v); RefreshGlobalAuras() end,
        order = 12, width = 0.8, hidden = function() return collapsedGlobalAuraSections.iconAppearance end,
        disabled = IsMasqueActive,
      },
      hideShadow = {
        type = "toggle", name = "Hide CDM Shadow",
        desc = "Hide CDM's default shadow/border texture",
        get = function() return GetAuraGlobalCfg().hideShadow end,
        set = function(_, v) ApplyAuraGlobalSetting("hideShadow", v); RefreshGlobalAuras() end,
        order = 13, width = 0.7, hidden = function() return collapsedGlobalAuraSections.iconAppearance end,
      },
      showDebuffBorder = {
        type = "toggle", name = "Debuff Border",
        desc = "Show debuff type colored border (magic=blue, curse=purple, etc.)",
        get = function() local g = GetAuraGlobalCfg(); return g.debuffBorder and g.debuffBorder.enabled end,
        set = function(_, v) ApplyAuraGlobalSetting("debuffBorder.enabled", v); RefreshGlobalAuras() end,
        order = 13.5, width = 0.7, hidden = function() return collapsedGlobalAuraSections.iconAppearance end,
      },
      showPandemicBorder = {
        type = "toggle", name = "Pandemic Glow",
        desc = "Show red pandemic glow when aura is at 30% remaining.\n\n|cff888888Note:|r If glow persists after disabling, /reload fixes it. This will be addressed in a future update.",
        get = function() local g = GetAuraGlobalCfg(); return g.pandemicBorder and g.pandemicBorder.enabled end,
        set = function(_, v) ApplyAuraGlobalSetting("pandemicBorder.enabled", v); RefreshGlobalAuras() end,
        order = 13.6, width = 0.7, hidden = function() return collapsedGlobalAuraSections.iconAppearance end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- ACTIVE STATE
      -- ═══════════════════════════════════════════════════════════════════
      activeStateHeader = {
        type = "toggle", name = "Aura Active", dialogControl = "CollapsibleHeader",
        desc = "How icons appear when the buff/debuff IS currently on you",
        get = function() return not collapsedGlobalAuraSections.activeState end,
        set = function(_, v) collapsedGlobalAuraSections.activeState = not v end,
        order = 14, width = "full",
      },
      activeStateAlpha = {
        type = "range", name = "Active Alpha", min = 0, max = 1.0, step = 0.05,
        desc = "Icon visibility when active",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.alpha or 1.0
          end
          return 1.0
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.alpha = v
          RefreshGlobalAuras()
        end,
        order = 14.1, width = 0.8,
        hidden = function() return collapsedGlobalAuraSections.activeState end,
      },
      activeStateGlow = {
        type = "toggle", name = "Glow When Active",
        desc = "Show a glow effect while the buff/debuff is active",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glow or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glow = v
          RefreshGlobalAuras()
          -- Clear preview when disabling glow
          if not v then
            ns.CDMEnhanceOptions.ClearGlowPreviewForAllIcons(true)
          end
        end,
        order = 14.2, width = 0.8,
        hidden = function() return collapsedGlobalAuraSections.activeState end,
      },
      activeStateGlowCombatOnly = {
        type = "toggle", name = "In Combat Only",
        desc = "Only show the active glow while in combat",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowCombatOnly or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowCombatOnly = v
          RefreshGlobalAuras()
          -- If enabling combat-only and not in combat, hide ALL aura glows immediately
          if v and not InCombatLockdown() and not UnitAffectingCombat("player") then
            if ns.CDMEnhance and ns.CDMEnhance.HideAllCombatOnlyGlows then
              ns.CDMEnhance.HideAllCombatOnlyGlows("aura")
            end
          end
        end,
        order = 14.205, width = 0.75,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      activeStateGlowPreview = {
        type = "toggle", name = "Preview",
        desc = "Toggle glow preview for all aura icons. Preview will automatically stop when you close the options panel.",
        get = function()
          return ns.CDMEnhanceOptions.GetGlowPreviewStateForAllIcons(true)
        end,
        set = function(_, v)
          ns.CDMEnhanceOptions.ToggleGlowPreviewForAllIcons(true)
        end,
        order = 14.206, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      activeStateGlowType = {
        type = "select", name = "Glow Style",
        desc = "Select the glow animation style",
        values = {
          ["pixel"] = "Pixel Glow",
          ["autocast"] = "AutoCast Sparkles",
          ["button"] = "Button Glow (Default)",
          ["proc"] = "Proc Effect",
        },
        sorting = {"button", "pixel", "autocast", "proc"},
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowType or "button"
          end
          return "button"
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowType = v
          RefreshGlobalAuras()
        end,
        order = 14.21, width = 0.9,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      activeStateGlowColor = {
        type = "color", name = "Color",
        desc = "Glow color",
        hasAlpha = false,
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            local col = g.cooldownStateVisuals.readyState.glowColor
            if col then return col.r or 1, col.g or 0.85, col.b or 0.1 end
          end
          return 1, 0.85, 0.1  -- Default gold
        end,
        set = function(_, r, gc, b)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowColor = {r = r, g = gc, b = b}
          RefreshGlobalAuras()
        end,
        order = 14.22, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      activeStateGlowIntensity = {
        type = "range", name = "Intensity", min = 0, max = 1.0, step = 0.05,
        desc = "Glow brightness",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowIntensity or 1.0
          end
          return 1.0
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowIntensity = v
          RefreshGlobalAuras()
        end,
        order = 14.23, width = 0.6,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      activeStateGlowScale = {
        type = "range", name = "Scale", min = 0.25, max = 4.0, step = 0.05,
        desc = "Size of the glow effect",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowScale or 1.0
          end
          return 1.0
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowScale = v
          RefreshGlobalAuras()
        end,
        order = 14.24, width = 0.55,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          local gt = g.cooldownStateVisuals.readyState.glowType; return gt ~= "autocast" and gt ~= "button"
        end,
      },
      activeStateGlowSpeed = {
        type = "range", name = "Speed", min = 0.05, max = 1.0, step = 0.05,
        desc = "How fast the glow animates",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowSpeed or 0.25
          end
          return 0.25
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowSpeed = v
          RefreshGlobalAuras()
        end,
        order = 14.25, width = 0.55,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          -- Proc glow doesn't use speed
          return g.cooldownStateVisuals.readyState.glowType == "proc"
        end,
      },
      activeStateGlowLines = {
        type = "range", name = "Lines", min = 1, max = 16, step = 1,
        desc = "Number of glow lines",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowLines or 8
          end
          return 8
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowLines = v
          RefreshGlobalAuras()
        end,
        order = 14.26, width = 0.55,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          return g.cooldownStateVisuals.readyState.glowType ~= "pixel"
        end,
      },
      activeStateGlowThickness = {
        type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
        desc = "Thickness of glow lines",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowThickness or 2
          end
          return 2
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowThickness = v
          RefreshGlobalAuras()
        end,
        order = 14.27, width = 0.55,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          return g.cooldownStateVisuals.readyState.glowType ~= "pixel"
        end,
      },
      activeStateGlowParticles = {
        type = "range", name = "Particles", min = 1, max = 16, step = 1,
        desc = "Number of sparkle groups",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowParticles or 4
          end
          return 4
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowParticles = v
          RefreshGlobalAuras()
        end,
        order = 14.28, width = 0.55,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          return g.cooldownStateVisuals.readyState.glowType ~= "autocast"
        end,
      },
      activeStateGlowXOffset = {
        type = "range", name = "X Offset", min = -50, max = 50, step = 1,
        desc = "Horizontal glow size adjustment",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowXOffset or 0
          end
          return 0
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowXOffset = v
          RefreshGlobalAuras()
        end,
        order = 14.29, width = 0.55,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          -- Button glow doesn't support offset
          return g.cooldownStateVisuals.readyState.glowType == "button"
        end,
      },
      activeStateGlowYOffset = {
        type = "range", name = "Y Offset", min = -50, max = 50, step = 1,
        desc = "Vertical glow size adjustment",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowYOffset or 0
          end
          return 0
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowYOffset = v
          RefreshGlobalAuras()
        end,
        order = 14.295, width = 0.55,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          -- Button glow doesn't support offset
          return g.cooldownStateVisuals.readyState.glowType == "button"
        end,
      },
      activeStateGlowThreshold = {
        type = "range", name = "Threshold %", min = 0.05, max = 1.0, step = 0.05,
        desc = "Show glow when remaining duration is at or below this percentage.\n\n|cffffd700100%|r = Always glow when active\n|cffffd70030%|r = Pandemic window (glow when ≤30% remaining)",
        isPercent = true,
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowThreshold or 1.0
          end
          return 1.0
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowThreshold = v
          RefreshGlobalAuras()
        end,
        order = 14.296, width = 0.7,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      activeStateGlowAuraType = {
        type = "select", name = "Check On",
        desc = "Where to check for this aura's duration.\n\n|cffffd700Buff (Player)|r = Check player buffs\n|cffffd700Debuff (Target)|r = Check target debuffs",
        values = { buff = "Buff (Player)", debuff = "Debuff (Target)" },
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            local val = g.cooldownStateVisuals.readyState.glowAuraType
            if val == "auto" or not val then return "buff" end
            return val
          end
          return "buff"
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowAuraType = v
          RefreshGlobalAuras()
        end,
        order = 14.297, width = 0.85,
        hidden = function()
          if collapsedGlobalAuraSections.activeState then return true end
          local g = GetAuraGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          -- Only show if threshold is < 100%
          local threshold = g.cooldownStateVisuals.readyState.glowThreshold or 1.0
          return threshold >= 1.0
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- INACTIVE STATE
      -- ═══════════════════════════════════════════════════════════════════
      inactiveStateHeader = {
        type = "toggle", name = "Aura Missing", dialogControl = "CollapsibleHeader",
        desc = "How icons appear when the buff/debuff is NOT currently on you",
        get = function() return not collapsedGlobalAuraSections.inactiveState end,
        set = function(_, v) collapsedGlobalAuraSections.inactiveState = not v end,
        order = 15, width = "full",
      },
      inactiveStateAlpha = {
        type = "range", name = "Inactive Alpha", min = 0, max = 1.0, step = 0.05,
        desc = "Icon visibility when inactive",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.cooldownState then
            return g.cooldownStateVisuals.cooldownState.alpha or 1.0
          end
          return 1.0
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.cooldownState then g.cooldownStateVisuals.cooldownState = {} end
          g.cooldownStateVisuals.cooldownState.alpha = v
          RefreshGlobalAuras()
        end,
        order = 16, width = 0.8,
        hidden = function() return collapsedGlobalAuraSections.inactiveState end,
      },
      inactiveStateDesaturate = {
        type = "toggle", name = "Desaturate When Inactive",
        desc = "Make icon grayscale when inactive",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.cooldownState then
            return g.cooldownStateVisuals.cooldownState.desaturate or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.cooldownState then g.cooldownStateVisuals.cooldownState = {} end
          g.cooldownStateVisuals.cooldownState.desaturate = v
          -- Clear legacy settings
          if g.inactiveState then
            g.inactiveState.desaturateWhenInactive = nil
          end
          RefreshGlobalAuras()
        end,
        order = 17, width = 0.9,
        hidden = function() return collapsedGlobalAuraSections.inactiveState end,
      },
      inactiveStateTint = {
        type = "toggle", name = "Color Tint",
        desc = "Apply a color tint to the icon when inactive",
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.cooldownState then
            return g.cooldownStateVisuals.cooldownState.tint or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.cooldownState then g.cooldownStateVisuals.cooldownState = {} end
          g.cooldownStateVisuals.cooldownState.tint = v
          RefreshGlobalAuras()
        end,
        order = 17.1, width = 0.6,
        hidden = function() return collapsedGlobalAuraSections.inactiveState end,
      },
      inactiveStateTintColor = {
        type = "color", name = "Tint Color",
        desc = "Color to tint the icon when inactive",
        hasAlpha = false,
        get = function()
          local g = GetAuraGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.cooldownState then
            local col = g.cooldownStateVisuals.cooldownState.tintColor
            if col then return col.r or 0.5, col.g or 0.5, col.b or 0.5 end
          end
          return 0.5, 0.5, 0.5  -- Default gray
        end,
        set = function(_, r, gc, b)
          local g = GetAuraGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.cooldownState then g.cooldownStateVisuals.cooldownState = {} end
          g.cooldownStateVisuals.cooldownState.tintColor = {r = r, g = gc, b = b}
          RefreshGlobalAuras()
        end,
        order = 17.2, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.inactiveState then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.cooldownState and g.cooldownStateVisuals.cooldownState.tint)
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- COOLDOWN SWIPE
      -- ═══════════════════════════════════════════════════════════════════
      cooldownSwipeHeader = {
        type = "toggle", dialogControl = "CollapsibleHeader",
        name = function()
          if IsMasqueCooldownsActive() then
            return "Cooldown Swipe |cff00CCFF(Masque)|r"
          end
          return "Cooldown Swipe"
        end,
        desc = function()
          if IsMasqueCooldownsActive() then
            return "|cff00CCFFMasque controls most cooldown settings.|r You can still change swipe COLOR here (works in combat). Other options require disabling 'Use Masque Cooldowns' above."
          end
          return "Click to expand/collapse cooldown animation settings."
        end,
        get = function() return not collapsedGlobalAuraSections.cooldownSwipe end,
        set = function(_, v) collapsedGlobalAuraSections.cooldownSwipe = not v end,
        order = 20, width = "full",
        -- NOT disabled - users need to expand this to access swipe color options
      },
      showSwipe = {
        type = "toggle", name = "Show Swipe",
        get = function() local g = GetAuraGlobalCfg(); return not g.cooldownSwipe or g.cooldownSwipe.showSwipe ~= false end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.showSwipe", v); RefreshGlobalAuras() end,
        order = 21, width = 0.6, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end,
        -- NOT disabled when Masque controls cooldowns - user can still toggle swipe visibility
      },
      noGCDSwipe = {
        type = "toggle", name = "No GCD Swipe",
        desc = "Hide GCD swipes (cooldowns 1.5s or less)",
        get = function() 
          local g = GetAuraGlobalCfg()
          if not g.cooldownSwipe then return false end
          return g.cooldownSwipe.noGCDSwipe or false
        end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.noGCDSwipe", v); RefreshGlobalAuras() end,
        order = 22, width = 0.7, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end,
        -- NOT disabled when Masque controls cooldowns - hiding GCD doesn't conflict with Masque
      },
      swipeWaitForNoCharges = {
        type = "toggle", name = "Wait No Charges",
        desc = "For charge spells: Only show swipe when ALL charges are consumed",
        get = function() 
          local g = GetAuraGlobalCfg()
          if not g.cooldownSwipe then return false end
          return g.cooldownSwipe.swipeWaitForNoCharges or false
        end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.swipeWaitForNoCharges", v); RefreshGlobalAuras() end,
        order = 22.5, width = 0.8, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      showEdge = {
        type = "toggle", name = "Edge",
        get = function() local g = GetAuraGlobalCfg(); return not g.cooldownSwipe or g.cooldownSwipe.showEdge ~= false end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.showEdge", v); RefreshGlobalAuras() end,
        order = 23, width = 0.4, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end,
        -- NOT disabled when Masque controls cooldowns - user can still toggle edge visibility
      },
      showBling = {
        type = "toggle", name = "Bling",
        get = function() local g = GetAuraGlobalCfg(); return not g.cooldownSwipe or g.cooldownSwipe.showBling ~= false end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.showBling", v); RefreshGlobalAuras() end,
        order = 24, width = 0.4, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end,
        -- NOT disabled when Masque controls cooldowns - finish flash can be controlled independently
      },
      reverse = {
        type = "toggle", name = "Reverse",
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.reverse end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.reverse", v); RefreshGlobalAuras() end,
        order = 25, width = 0.5, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      swipeColorEnabled = {
        type = "toggle", name = "Custom Color",
        desc = function()
          if IsMasqueCooldownsActive() then
            return "|cff00CCFFMasque controls swipe color.|r ArcUI applies Masque's skin color using a method that works in combat."
          end
          return "Use a custom swipe color instead of CDM default"
        end,
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.swipeColor ~= nil end,
        set = function(_, v)
          if v then
            ApplyAuraGlobalSetting("cooldownSwipe.swipeColor", {r=0, g=0, b=0, a=0.8})
          else
            ApplyAuraGlobalSetting("cooldownSwipe.swipeColor", nil)
          end
          RefreshGlobalAuras()
        end,
        order = 26, width = 0.7, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end,
        disabled = IsMasqueCooldownsActive,  -- Masque controls color, ArcUI applies it
      },
      swipeColor = {
        type = "color", name = "Color", hasAlpha = true,
        get = function()
          local g = GetAuraGlobalCfg()
          local c = g.cooldownSwipe and g.cooldownSwipe.swipeColor
          if c then return c.r or c[1] or 0, c.g or c[2] or 0, c.b or c[3] or 0, c.a or c[4] or 0.8 end
          return 0, 0, 0, 0.8
        end,
        set = function(_, r, g, b, a)
          ApplyAuraGlobalSetting("cooldownSwipe.swipeColor", {r=r, g=g, b=b, a=a}); RefreshGlobalAuras()
        end,
        order = 27, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.cooldownSwipe then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownSwipe and g.cooldownSwipe.swipeColor)
        end,
      },
      edgeScale = {
        type = "range", name = "Edge Scale", min = 0.05, max = 3.0, step = 0.1,
        desc = "Size of the cooldown edge spinner",
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.edgeScale or 1.0 end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.edgeScale", v); RefreshGlobalAuras() end,
        order = 27.1, width = 0.7, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      edgeColorEnabled = {
        type = "toggle", name = "Edge Color",
        desc = "Enable custom edge color",
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.edgeColor ~= nil end,
        set = function(_, v)
          if v then
            ApplyAuraGlobalSetting("cooldownSwipe.edgeColor", {r=1, g=1, b=1, a=1})
          else
            ApplyAuraGlobalSetting("cooldownSwipe.edgeColor", nil)
          end
          RefreshGlobalAuras()
        end,
        order = 27.2, width = 0.65, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      edgeColor = {
        type = "color", name = "Edge", hasAlpha = true,
        desc = "Color of the spinning edge line",
        get = function()
          local g = GetAuraGlobalCfg()
          local c = g.cooldownSwipe and g.cooldownSwipe.edgeColor
          if c then return c.r or c[1] or 1, c.g or c[2] or 1, c.b or c[3] or 1, c.a or c[4] or 1 end
          return 1, 1, 1, 1
        end,
        set = function(_, r, g, b, a)
          ApplyAuraGlobalSetting("cooldownSwipe.edgeColor", {r=r, g=g, b=b, a=a}); RefreshGlobalAuras()
        end,
        order = 27.3, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.cooldownSwipe then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownSwipe and g.cooldownSwipe.edgeColor)
        end,
      },
      swipeInset = {
        type = "range", name = "Swipe Inset", min = -20, max = 40, step = 1,
        desc = "Inset for the swipe animation (all sides). Positive = smaller, negative = larger.",
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.swipeInset or 0 end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.swipeInset", v); RefreshGlobalAuras() end,
        order = 27.4, width = 0.6,
        hidden = function()
          if collapsedGlobalAuraSections.cooldownSwipe then return true end
          local g = GetAuraGlobalCfg()
          return g.cooldownSwipe and g.cooldownSwipe.separateInsets
        end,
      },
      separateInsets = {
        type = "toggle", name = "W/H",
        desc = "Enable separate Width and Height insets instead of a single inset",
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.separateInsets end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.separateInsets", v); RefreshGlobalAuras() end,
        order = 27.45, width = 0.35, hidden = function() return collapsedGlobalAuraSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      swipeInsetX = {
        type = "range", name = "Width", min = -20, max = 40, step = 1,
        desc = "Horizontal inset (left/right). Positive = narrower, negative = wider.",
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.swipeInsetX or 0 end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.swipeInsetX", v); RefreshGlobalAuras() end,
        order = 27.5, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.cooldownSwipe then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownSwipe and g.cooldownSwipe.separateInsets)
        end,
      },
      swipeInsetY = {
        type = "range", name = "Height", min = -20, max = 40, step = 1,
        desc = "Vertical inset (top/bottom). Positive = shorter, negative = taller.",
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.swipeInsetY or 0 end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownSwipe.swipeInsetY", v); RefreshGlobalAuras() end,
        order = 27.6, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.cooldownSwipe then return true end
          local g = GetAuraGlobalCfg()
          return not (g.cooldownSwipe and g.cooldownSwipe.separateInsets)
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- CHARGE TEXT
      -- ═══════════════════════════════════════════════════════════════════
      chargeTextHeader = {
        type = "toggle", name = "Charge/Stack Text", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalAuraSections.chargeText end,
        set = function(_, v) collapsedGlobalAuraSections.chargeText = not v end,
        order = 30, width = "full",
      },
      chargeEnabled = {
        type = "toggle", name = "Enabled",
        get = function() local g = GetAuraGlobalCfg(); return not g.chargeText or g.chargeText.enabled ~= false end,
        set = function(_, v) ApplyAuraGlobalSetting("chargeText.enabled", v); RefreshGlobalAuras() end,
        order = 31, width = 0.5, hidden = function() return collapsedGlobalAuraSections.chargeText end,
      },
      chargeSize = {
        type = "range", name = "Size", min = 4, max = 64, step = 1,
        get = function() local g = GetAuraGlobalCfg(); return g.chargeText and g.chargeText.size or 14 end,
        set = function(_, v) ApplyAuraGlobalSetting("chargeText.size", v); RefreshGlobalAuras() end,
        order = 32, width = 0.7, hidden = function() return collapsedGlobalAuraSections.chargeText end,
      },
      chargeColor = {
        type = "color", name = "Color", hasAlpha = true,
        get = function()
          local g = GetAuraGlobalCfg()
          local c = g.chargeText and g.chargeText.color
          if c then return c.r or 1, c.g or 1, c.b or 1, c.a or 1 end
          return 1, 1, 1, 1
        end,
        set = function(_, r, g, b, a)
          ApplyAuraGlobalSetting("chargeText.color", {r=r, g=g, b=b, a=a}); RefreshGlobalAuras()
        end,
        order = 32.5, width = 0.5, hidden = function() return collapsedGlobalAuraSections.chargeText end,
      },
      chargeFont = {
        type = "select", name = "Font", dialogControl = "LSM30_Font",
        values = LSM and LSM:HashTable("font") or {},
        get = function() local g = GetAuraGlobalCfg(); return g.chargeText and g.chargeText.font or "Friz Quadrata TT" end,
        set = function(_, v) ApplyAuraGlobalSetting("chargeText.font", v); RefreshGlobalAuras() end,
        order = 33, width = 1.0, hidden = function() return collapsedGlobalAuraSections.chargeText end,
      },
      chargeOutline = {
        type = "select", name = "Outline",
        values = { [""] = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick" },
        get = function() local g = GetAuraGlobalCfg(); return GetOutlineValue(g.chargeText and g.chargeText.outline) end,
        set = function(_, v) ApplyAuraGlobalSetting("chargeText.outline", v); RefreshGlobalAuras() end,
        order = 34, width = 0.7, hidden = function() return collapsedGlobalAuraSections.chargeText end,
      },
      chargeShadow = {
        type = "toggle", name = "Shadow",
        get = function() local g = GetAuraGlobalCfg(); return g.chargeText and g.chargeText.shadow end,
        set = function(_, v) ApplyAuraGlobalSetting("chargeText.shadow", v); RefreshGlobalAuras() end,
        order = 34.5, width = 0.5, hidden = function() return collapsedGlobalAuraSections.chargeText end,
      },
      chargePositionLabel = {
        type = "description", name = "|cffffd700Position|r", fontSize = "medium",
        order = 34.8, width = "full", hidden = function() return collapsedGlobalAuraSections.chargeText end,
      },
      chargeMode = {
        type = "select", name = "Mode",
        values = { anchor = "Anchor Position", free = "Free Drag" },
        get = function() local g = GetAuraGlobalCfg(); return g.chargeText and g.chargeText.mode or "anchor" end,
        set = function(_, v) ApplyAuraGlobalSetting("chargeText.mode", v); RefreshGlobalAuras() end,
        order = 35, width = 0.8, hidden = function() return collapsedGlobalAuraSections.chargeText end,
      },
      chargeAnchor = {
        type = "select", name = "Anchor",
        values = { TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right", LEFT = "Left", CENTER = "Center", RIGHT = "Right", BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right" },
        get = function() local g = GetAuraGlobalCfg(); return g.chargeText and g.chargeText.anchor or "BOTTOMRIGHT" end,
        set = function(_, v) ApplyAuraGlobalSetting("chargeText.anchor", v); RefreshGlobalAuras() end,
        order = 35.1, width = 0.8,
        hidden = function()
          if collapsedGlobalAuraSections.chargeText then return true end
          local g = GetAuraGlobalCfg()
          return g.chargeText and g.chargeText.mode == "free"
        end,
      },
      chargeOffsetX = {
        type = "range", name = "X Offset", min = -100, max = 100, step = 1,
        get = function() local g = GetAuraGlobalCfg(); return g.chargeText and g.chargeText.offsetX or -2 end,
        set = function(_, v) ApplyAuraGlobalSetting("chargeText.offsetX", v); RefreshGlobalAuras() end,
        order = 35.2, width = 0.7,
        hidden = function()
          if collapsedGlobalAuraSections.chargeText then return true end
          local g = GetAuraGlobalCfg()
          return g.chargeText and g.chargeText.mode == "free"
        end,
      },
      chargeOffsetY = {
        type = "range", name = "Y Offset", min = -100, max = 100, step = 1,
        get = function() local g = GetAuraGlobalCfg(); return g.chargeText and g.chargeText.offsetY or 2 end,
        set = function(_, v) ApplyAuraGlobalSetting("chargeText.offsetY", v); RefreshGlobalAuras() end,
        order = 35.3, width = 0.7,
        hidden = function()
          if collapsedGlobalAuraSections.chargeText then return true end
          local g = GetAuraGlobalCfg()
          return g.chargeText and g.chargeText.mode == "free"
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- COOLDOWN TEXT
      -- ═══════════════════════════════════════════════════════════════════
      cooldownTextHeader = {
        type = "toggle", name = "Cooldown/Duration Text", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalAuraSections.cooldownText end,
        set = function(_, v) collapsedGlobalAuraSections.cooldownText = not v end,
        order = 40, width = "full",
      },
      cdTextEnabled = {
        type = "toggle", name = "Enabled",
        get = function() local g = GetAuraGlobalCfg(); return not g.cooldownText or g.cooldownText.enabled ~= false end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownText.enabled", v); RefreshGlobalAuras() end,
        order = 41, width = 0.5, hidden = function() return collapsedGlobalAuraSections.cooldownText end,
      },
      cdTextSize = {
        type = "range", name = "Size", min = 4, max = 64, step = 1,
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownText and g.cooldownText.size or 14 end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownText.size", v); RefreshGlobalAuras() end,
        order = 42, width = 0.7, hidden = function() return collapsedGlobalAuraSections.cooldownText end,
      },
      cdTextColor = {
        type = "color", name = "Color", hasAlpha = true,
        get = function()
          local g = GetAuraGlobalCfg()
          local c = g.cooldownText and g.cooldownText.color
          if c then return c.r or 1, c.g or 1, c.b or 1, c.a or 1 end
          return 1, 1, 1, 1
        end,
        set = function(_, r, g, b, a)
          ApplyAuraGlobalSetting("cooldownText.color", {r=r, g=g, b=b, a=a}); RefreshGlobalAuras()
        end,
        order = 42.5, width = 0.5, hidden = function() return collapsedGlobalAuraSections.cooldownText end,
      },
      cdTextFont = {
        type = "select", name = "Font", dialogControl = "LSM30_Font",
        values = LSM and LSM:HashTable("font") or {},
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownText and g.cooldownText.font or "Friz Quadrata TT" end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownText.font", v); RefreshGlobalAuras() end,
        order = 43, width = 1.0, hidden = function() return collapsedGlobalAuraSections.cooldownText end,
      },
      cdTextOutline = {
        type = "select", name = "Outline",
        values = { [""] = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick" },
        get = function() local g = GetAuraGlobalCfg(); return GetOutlineValue(g.cooldownText and g.cooldownText.outline) end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownText.outline", v); RefreshGlobalAuras() end,
        order = 44, width = 0.7, hidden = function() return collapsedGlobalAuraSections.cooldownText end,
      },
      cdTextShadow = {
        type = "toggle", name = "Shadow",
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownText and g.cooldownText.shadow end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownText.shadow", v); RefreshGlobalAuras() end,
        order = 44.5, width = 0.5, hidden = function() return collapsedGlobalAuraSections.cooldownText end,
      },
      cdPositionLabel = {
        type = "description", name = "|cffffd700Position|r", fontSize = "medium",
        order = 44.8, width = "full", hidden = function() return collapsedGlobalAuraSections.cooldownText end,
      },
      cdTextMode = {
        type = "select", name = "Mode",
        values = { anchor = "Anchor Position", free = "Free Drag" },
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownText and g.cooldownText.mode or "anchor" end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownText.mode", v); RefreshGlobalAuras() end,
        order = 45, width = 0.8, hidden = function() return collapsedGlobalAuraSections.cooldownText end,
      },
      cdTextAnchor = {
        type = "select", name = "Anchor",
        values = { TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right", LEFT = "Left", CENTER = "Center", RIGHT = "Right", BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right" },
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownText and g.cooldownText.anchor or "CENTER" end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownText.anchor", v); RefreshGlobalAuras() end,
        order = 45.1, width = 0.8,
        hidden = function()
          if collapsedGlobalAuraSections.cooldownText then return true end
          local g = GetAuraGlobalCfg()
          return g.cooldownText and g.cooldownText.mode == "free"
        end,
      },
      cdTextOffsetX = {
        type = "range", name = "X Offset", min = -100, max = 100, step = 1,
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownText and g.cooldownText.offsetX or 0 end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownText.offsetX", v); RefreshGlobalAuras() end,
        order = 45.2, width = 0.7,
        hidden = function()
          if collapsedGlobalAuraSections.cooldownText then return true end
          local g = GetAuraGlobalCfg()
          return g.cooldownText and g.cooldownText.mode == "free"
        end,
      },
      cdTextOffsetY = {
        type = "range", name = "Y Offset", min = -100, max = 100, step = 1,
        get = function() local g = GetAuraGlobalCfg(); return g.cooldownText and g.cooldownText.offsetY or 0 end,
        set = function(_, v) ApplyAuraGlobalSetting("cooldownText.offsetY", v); RefreshGlobalAuras() end,
        order = 45.3, width = 0.7,
        hidden = function()
          if collapsedGlobalAuraSections.cooldownText then return true end
          local g = GetAuraGlobalCfg()
          return g.cooldownText and g.cooldownText.mode == "free"
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- PROC GLOW
      -- ═══════════════════════════════════════════════════════════════════
      procGlowHeader = {
        type = "toggle", name = "Proc Glow", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalAuraSections.procGlow end,
        set = function(_, v) collapsedGlobalAuraSections.procGlow = not v end,
        order = 50, width = "full",
      },
      glowEnabled = {
        type = "toggle", name = "Enabled",
        get = function() local g = GetAuraGlobalCfg(); return not g.procGlow or g.procGlow.enabled ~= false end,
        set = function(_, v) ApplyAuraGlobalSetting("procGlow.enabled", v); RefreshGlobalAuras() end,
        order = 51, width = 0.5, hidden = function() return collapsedGlobalAuraSections.procGlow end,
      },
      glowType = {
        type = "select", name = "Type",
        values = { default = "Default (Blizzard)", pixel = "Pixel", autocast = "Autocast", button = "Button", proc = "Proc" },
        sorting = {"default", "proc", "pixel", "autocast", "button"},
        get = function() local g = GetAuraGlobalCfg(); return g.procGlow and g.procGlow.glowType or "default" end,
        set = function(_, v) ApplyAuraGlobalSetting("procGlow.glowType", v); RefreshGlobalAuras() end,
        order = 52, width = 0.7, hidden = function() return collapsedGlobalAuraSections.procGlow end,
      },
      glowColor = {
        type = "color", name = "Color",
        desc = "Glow color (white = default)",
        get = function()
          local g = GetAuraGlobalCfg()
          local col = g.procGlow and g.procGlow.color
          if col then return col.r or 1, col.g or 1, col.b or 1 end
          return 1, 1, 1
        end,
        set = function(_, r, gc, b)
          if r == 1 and gc == 1 and b == 1 then
            ApplyAuraGlobalSetting("procGlow.color", nil)
          else
            ApplyAuraGlobalSetting("procGlow.color", {r=r, g=gc, b=b})
          end
          RefreshGlobalAuras()
        end,
        order = 52.5, width = 0.4,
        hidden = function()
          if collapsedGlobalAuraSections.procGlow then return true end
          local g = GetAuraGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType == "default"
        end,
      },
      glowAlpha = {
        type = "range", name = "Intensity", min = 0, max = 1.0, step = 0.05,
        desc = "How bright the glow appears",
        get = function() local g = GetAuraGlobalCfg(); return g.procGlow and g.procGlow.alpha or 1.0 end,
        set = function(_, v) ApplyAuraGlobalSetting("procGlow.alpha", v); RefreshGlobalAuras() end,
        order = 52.6, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.procGlow then return true end
          local g = GetAuraGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType == "default"
        end,
      },
      glowScale = {
        type = "range", name = "Scale", min = 0.25, max = 4.0, step = 0.05, isPercent = true,
        get = function() local g = GetAuraGlobalCfg(); return g.procGlow and g.procGlow.scale or 1.0 end,
        set = function(_, v) ApplyAuraGlobalSetting("procGlow.scale", v); RefreshGlobalAuras() end,
        order = 53, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.procGlow then return true end
          local g = GetAuraGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType ~= "autocast" and glowType ~= "button"
        end,
      },
      glowSpeed = {
        type = "range", name = "Speed", min = 0.05, max = 1.0, step = 0.05,
        desc = "Animation speed",
        get = function() local g = GetAuraGlobalCfg(); return g.procGlow and g.procGlow.speed or 0.25 end,
        set = function(_, v) ApplyAuraGlobalSetting("procGlow.speed", v); RefreshGlobalAuras() end,
        order = 53.5, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.procGlow then return true end
          local g = GetAuraGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType == "default" or glowType == "proc"
        end,
      },
      glowLines = {
        type = "range", name = "Lines", min = 1, max = 16, step = 1,
        desc = "Number of glow lines",
        get = function() local g = GetAuraGlobalCfg(); return g.procGlow and g.procGlow.lines or 8 end,
        set = function(_, v) ApplyAuraGlobalSetting("procGlow.lines", v); RefreshGlobalAuras() end,
        order = 54, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.procGlow then return true end
          local g = GetAuraGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType ~= "pixel"
        end,
      },
      glowThickness = {
        type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
        desc = "Thickness of glow lines",
        get = function() local g = GetAuraGlobalCfg(); return g.procGlow and g.procGlow.thickness or 2 end,
        set = function(_, v) ApplyAuraGlobalSetting("procGlow.thickness", v); RefreshGlobalAuras() end,
        order = 54.5, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.procGlow then return true end
          local g = GetAuraGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType ~= "pixel"
        end,
      },
      glowParticles = {
        type = "range", name = "Particles", min = 1, max = 16, step = 1,
        desc = "Number of sparkle groups",
        get = function() local g = GetAuraGlobalCfg(); return g.procGlow and g.procGlow.particles or 4 end,
        set = function(_, v) ApplyAuraGlobalSetting("procGlow.particles", v); RefreshGlobalAuras() end,
        order = 55, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.procGlow then return true end
          local g = GetAuraGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType ~= "autocast"
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- BORDER
      -- ═══════════════════════════════════════════════════════════════════
      borderHeader = {
        type = "toggle", name = "Border", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalAuraSections.border end,
        set = function(_, v) collapsedGlobalAuraSections.border = not v end,
        order = 56, width = "full",
      },
      borderEnabled = {
        type = "toggle", name = "Show Border",
        get = function() local g = GetAuraGlobalCfg(); return g.border and g.border.enabled end,
        set = function(_, v) ApplyAuraGlobalSetting("border.enabled", v); RefreshGlobalAuras() end,
        order = 56.1, width = 0.6, hidden = function() return collapsedGlobalAuraSections.border end,
      },
      borderUseClassColor = {
        type = "toggle", name = "Class Color",
        desc = "Use your class color for the border",
        get = function() local g = GetAuraGlobalCfg(); return g.border and g.border.useClassColor end,
        set = function(_, v) ApplyAuraGlobalSetting("border.useClassColor", v); RefreshGlobalAuras() end,
        order = 56.2, width = 0.7,
        hidden = function()
          if collapsedGlobalAuraSections.border then return true end
          local g = GetAuraGlobalCfg()
          return not (g.border and g.border.enabled)
        end,
      },
      borderThickness = {
        type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
        get = function() local g = GetAuraGlobalCfg(); return g.border and g.border.thickness or 1 end,
        set = function(_, v) ApplyAuraGlobalSetting("border.thickness", v); RefreshGlobalAuras() end,
        order = 56.3, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.border then return true end
          local g = GetAuraGlobalCfg()
          return not (g.border and g.border.enabled)
        end,
      },
      borderInset = {
        type = "range", name = "Offset", min = -20, max = 20, step = 1,
        desc = "Border position offset. Negative = outset (outside icon), Positive = inset (inside icon). Automatically accounts for zoom.",
        get = function() local g = GetAuraGlobalCfg(); return g.border and g.border.inset or 0 end,
        set = function(_, v) ApplyAuraGlobalSetting("border.inset", v); RefreshGlobalAuras() end,
        order = 56.4, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.border then return true end
          local g = GetAuraGlobalCfg()
          return not (g.border and g.border.enabled)
        end,
      },
      borderColor = {
        type = "color", name = "Color", hasAlpha = true,
        get = function()
          local g = GetAuraGlobalCfg()
          local c = g.border and g.border.color
          if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
          return 1, 1, 1, 1
        end,
        set = function(_, r, gc, b, a)
          ApplyAuraGlobalSetting("border.color", {r, gc, b, a}); RefreshGlobalAuras()
        end,
        order = 56.5, width = 0.5,
        hidden = function()
          if collapsedGlobalAuraSections.border then return true end
          local g = GetAuraGlobalCfg()
          return not (g.border and g.border.enabled) or (g.border and g.border.useClassColor)
        end,
      },
      borderFollowDesat = {
        type = "toggle", name = "Follow Desat",
        desc = "Desaturate border when icon is desaturated",
        get = function() local g = GetAuraGlobalCfg(); return g.border and g.border.followDesaturation end,
        set = function(_, v) ApplyAuraGlobalSetting("border.followDesaturation", v); RefreshGlobalAuras() end,
        order = 56.6, width = 0.6,
        hidden = function()
          if collapsedGlobalAuraSections.border then return true end
          local g = GetAuraGlobalCfg()
          return not (g.border and g.border.enabled)
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- RANGE INDICATOR
      -- ═══════════════════════════════════════════════════════════════════
      rangeHeader = {
        type = "toggle", name = "Range Indicator", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalAuraSections.rangeIndicator end,
        set = function(_, v) collapsedGlobalAuraSections.rangeIndicator = not v end,
        order = 60, width = "full",
      },
      rangeEnabled = {
        type = "toggle", name = "Show Range Overlay",
        desc = "Show the out-of-range darkening overlay when spells are out of range",
        get = function() local g = GetAuraGlobalCfg(); return not g.rangeIndicator or g.rangeIndicator.enabled ~= false end,
        set = function(_, v) ApplyAuraGlobalSetting("rangeIndicator.enabled", v); RefreshGlobalAuras() end,
        order = 61, width = 1.0, hidden = function() return collapsedGlobalAuraSections.rangeIndicator end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- RESET DEFAULTS
      -- ═══════════════════════════════════════════════════════════════════
      resetSpacer = {
        type = "description", name = "", order = 90, width = "full",
      },
      clearPerIconOverrides = {
        type = "execute",
        name = "Clear Per-Icon Overrides",
        desc = "Remove all per-icon customizations from aura icons so they use global defaults.\n\n|cffff9900This will clear any individual icon scale, text, glow settings you've set!|r",
        func = function()
          if ns.CDMEnhance and ns.CDMEnhance.ResetAllIconsToDefaults then
            local count = ns.CDMEnhance.ResetAllIconsToDefaults("aura")
            print(string.format("|cff00FF00[ArcUI CDM]|r Cleared per-icon settings from %d aura icons. Global defaults now apply.", count or 0))
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 90.5,
        width = 1.3,
        confirm = true,
        confirmText = "Clear ALL per-icon customizations from aura icons?\n\nThis will make all aura icons use global defaults.",
      },
      resetDefaults = {
        type = "execute",
        name = "Reset All Aura Defaults",
        desc = "Reset all aura global defaults to their original values",
        func = function()
          if ns.CDMEnhance and ns.CDMEnhance.ResetGlobalDefaults then
            ns.CDMEnhance.ResetGlobalDefaults("aura")
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 91,
        width = 1.3,
        confirm = true,
        confirmText = "Reset all aura global defaults to original values?",
      },
    },
  }
end

function ns.GetCDMGlobalCooldownDefaultsOptionsTable()
  return {
    type = "group",
    name = "Cooldown Defaults",
    order = 2,
    args = {
      desc = {
        type = "description",
        name = "|cff00ccffGlobal Defaults for Cooldown Icons|r\n\nThese settings apply to ALL cooldown icons (Essential & Utility) automatically.\n\n|cffff9900Note:|r Icons with per-icon customizations will NOT be affected by these defaults. To apply defaults to a customized icon, use |cffffffffReset to Defaults|r on that icon first.",
        order = 1,
        fontSize = "medium",
      },
      openCDM = {
        type = "execute",
        name = "Open CD Manager",
        desc = "Open the Cooldown Manager settings panel",
        order = 1.5,
        width = 0.85,
        func = function()
          local frame = _G["CooldownViewerSettings"]
          if frame and frame.Show then
            frame:Show()
            frame:Raise()
          end
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- ICON APPEARANCE
      -- ═══════════════════════════════════════════════════════════════════
      iconAppearanceHeader = {
        type = "toggle", name = "Icon Appearance", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalCooldownSections.iconAppearance end,
        set = function(_, v) collapsedGlobalCooldownSections.iconAppearance = not v end,
        order = 10, width = "full",
      },
      masqueNotice = {
        type = "description",
        name = "|cffff9900Masque Active:|r Zoom, Aspect Ratio, and Padding are controlled by your Masque skin. Disable the skin group in Masque to use these settings.",
        order = 10.1,
        width = "full",
        fontSize = "medium",
        hidden = function() return collapsedGlobalCooldownSections.iconAppearance or not IsMasqueActive() end,
      },
      scaleOverride = {
        type = "toggle", name = "Override",
        desc = "When enabled, this Default Scale controls ALL cooldown groups (Essential & Utility). When changed, it pushes the scale to all groups.",
        get = function() return GetCooldownGlobalCfg().scaleOverride end,
        set = function(_, v)
          ApplyCooldownGlobalSetting("scaleOverride", v)
          if v then
            -- Push current default scale to both groups
            local defaultScale = GetCooldownGlobalCfg().scale or 1.0
            if ns.CDMEnhance then
              ns.CDMEnhance.SetGroupScale("cooldown", defaultScale)
              ns.CDMEnhance.SetGroupScale("utility", defaultScale)
            end
          else
            -- Clear the group scales when disabling (restore Edit Mode control)
            if ns.CDMEnhance then
              ns.CDMEnhance.SetGroupScale("cooldown", nil)
              ns.CDMEnhance.SetGroupScale("utility", nil)
            end
          end
          RefreshGlobalCooldowns()
        end,
        order = 10.5, width = 0.5, hidden = function() return collapsedGlobalCooldownSections.iconAppearance end,
      },
      scale = {
        type = "range", name = "Default Scale", min = 0.25, max = 4.0, step = 0.05, isPercent = true,
        desc = function()
          local g = GetCooldownGlobalCfg()
          if g.scaleOverride then
            return "Controls scale for ALL cooldown groups (Essential & Utility). Changes are pushed to both groups."
          else
            return "Default scale for icons without Group Scale override enabled."
          end
        end,
        get = function() return GetCooldownGlobalCfg().scale or 1.0 end,
        set = function(_, v)
          ApplyCooldownGlobalSetting("scale", v)
          -- If override is ON, push to both groups
          local g = GetCooldownGlobalCfg()
          if g.scaleOverride and ns.CDMEnhance then
            ns.CDMEnhance.SetGroupScale("cooldown", v)
            ns.CDMEnhance.SetGroupScale("utility", v)
          end
          RefreshGlobalCooldowns()
        end,
        order = 11, width = 1.1, hidden = function() return collapsedGlobalCooldownSections.iconAppearance end,
      },
      alpha = {
        type = "range", name = "Opacity", min = 0, max = 1.0, step = 0.05,
        desc = "Overall icon opacity",
        get = function() return GetCooldownGlobalCfg().alpha or 1.0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("alpha", v); RefreshGlobalCooldowns() end,
        order = 11.5, width = 0.8, hidden = function() return collapsedGlobalCooldownSections.iconAppearance end,
      },
      aspectRatio = {
        type = "range", name = "Aspect Ratio", min = 0.25, max = 2.5, step = 0.05,
        desc = "Width/height ratio (1.0 = square).\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls icon appearance via its skin settings.",
        get = function() return GetCooldownGlobalCfg().aspectRatio or 1.0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("aspectRatio", v); RefreshGlobalCooldowns() end,
        order = 11.6, width = 0.8, hidden = function() return collapsedGlobalCooldownSections.iconAppearance end,
        disabled = IsMasqueActive,
      },
      zoom = {
        type = "range", name = "Zoom", min = 0, max = 0.3, step = 0.01,
        desc = "Crop edges to zoom into icon center.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls zoom via its skin settings.",
        get = function() return GetCooldownGlobalCfg().zoom or 0.075 end,
        set = function(_, v) ApplyCooldownGlobalSetting("zoom", v); RefreshGlobalCooldowns() end,
        order = 11.7, width = 0.8, hidden = function() return collapsedGlobalCooldownSections.iconAppearance end,
        disabled = IsMasqueActive,
      },
      padding = {
        type = "range", name = "Padding", min = -5, max = 20, step = 1,
        desc = "Space between icon and frame edges.\n\n|cffff9900Note:|r Disabled when Masque is active - Masque controls icon appearance via its skin settings.",
        get = function() return GetCooldownGlobalCfg().padding or 0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("padding", v); RefreshGlobalCooldowns() end,
        order = 12, width = 0.8, hidden = function() return collapsedGlobalCooldownSections.iconAppearance end,
        disabled = IsMasqueActive,
      },
      hideShadow = {
        type = "toggle", name = "Hide CDM Shadow",
        desc = "Hide CDM's default shadow/border texture",
        get = function() return GetCooldownGlobalCfg().hideShadow end,
        set = function(_, v) ApplyCooldownGlobalSetting("hideShadow", v); RefreshGlobalCooldowns() end,
        order = 13, width = 0.75, hidden = function() return collapsedGlobalCooldownSections.iconAppearance end,
      },
      showPandemicBorder = {
        type = "toggle", name = "Pandemic Glow",
        desc = "Show red pandemic glow when cooldown is at 30% remaining.\n\n|cff888888Note:|r If glow persists after disabling, /reload fixes it.",
        get = function() local g = GetCooldownGlobalCfg(); return g.pandemicBorder and g.pandemicBorder.enabled end,
        set = function(_, v) ApplyCooldownGlobalSetting("pandemicBorder.enabled", v); RefreshGlobalCooldowns() end,
        order = 13.5, width = 0.85, hidden = function() return collapsedGlobalCooldownSections.iconAppearance end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- READY STATE
      -- ═══════════════════════════════════════════════════════════════════
      readyStateHeader = {
        type = "toggle", name = "Ready State", dialogControl = "CollapsibleHeader",
        desc = "How icons appear when the ability IS READY (not on cooldown)",
        get = function() return not collapsedGlobalCooldownSections.readyState end,
        set = function(_, v) collapsedGlobalCooldownSections.readyState = not v end,
        order = 14, width = "full",
      },
      readyStateAlpha = {
        type = "range", name = "Ready Alpha", min = 0, max = 1.0, step = 0.05,
        desc = "Icon opacity when the ability is ready (0 = hidden, 1 = fully visible)",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.alpha or 1.0
          end
          return 1.0
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.alpha = v
          RefreshGlobalCooldowns()
        end,
        order = 14.1, width = 0.8,
        hidden = function() return collapsedGlobalCooldownSections.readyState end,
      },
      readyStateGlow = {
        type = "toggle", name = "Glow When Ready",
        desc = "Show a glow effect while the ability is ready to use",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glow or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glow = v
          RefreshGlobalCooldowns()
          -- Clear preview when disabling glow
          if not v then
            ns.CDMEnhanceOptions.ClearGlowPreviewForAllIcons(false)
          end
        end,
        order = 14.2, width = 0.8,
        hidden = function() return collapsedGlobalCooldownSections.readyState end,
      },
      readyStateGlowCombatOnly = {
        type = "toggle", name = "In Combat Only",
        desc = "Only show the ready glow while in combat",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowCombatOnly or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowCombatOnly = v
          RefreshGlobalCooldowns()
          -- If enabling combat-only and not in combat, hide ALL cooldown glows immediately
          if v and not InCombatLockdown() and not UnitAffectingCombat("player") then
            if ns.CDMEnhance and ns.CDMEnhance.HideAllCombatOnlyGlows then
              ns.CDMEnhance.HideAllCombatOnlyGlows("cooldown")
            end
          end
        end,
        order = 14.205, width = 0.75,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      readyStateGlowPreview = {
        type = "toggle", name = "Preview",
        desc = "Toggle glow preview for all cooldown icons. Preview will automatically stop when you close the options panel.",
        get = function()
          return ns.CDMEnhanceOptions.GetGlowPreviewStateForAllIcons(false)
        end,
        set = function(_, v)
          ns.CDMEnhanceOptions.ToggleGlowPreviewForAllIcons(false)
        end,
        order = 14.2055, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      readyStateGlowWhileChargesAvailable = {
        type = "toggle", name = "Glow While Any Charge Available",
        desc = "For charge spells: Show glow as long as any charge is available.\n\n|cff888888Off|r: Glow only when ALL charges are ready\n|cffffd700On|r: Glow while any charge can be used",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowWhileChargesAvailable or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowWhileChargesAvailable = v
          RefreshGlobalCooldowns()
        end,
        order = 14.206, width = 1.2,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      readyStateGlowType = {
        type = "select", name = "Glow Style",
        desc = "Select the glow animation style",
        values = {
          ["pixel"] = "Pixel Glow",
          ["autocast"] = "AutoCast Sparkles",
          ["button"] = "Button Glow (Default)",
          ["proc"] = "Proc Effect",
        },
        sorting = {"button", "pixel", "autocast", "proc"},
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowType or "button"
          end
          return "button"
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowType = v
          RefreshGlobalCooldowns()
        end,
        order = 14.21, width = 0.9,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      readyStateGlowColor = {
        type = "color", name = "Color",
        desc = "Glow color",
        hasAlpha = false,
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            local col = g.cooldownStateVisuals.readyState.glowColor
            if col then return col.r or 1, col.g or 0.85, col.b or 0.1 end
          end
          return 1, 0.85, 0.1  -- Default gold
        end,
        set = function(_, r, gc, b)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowColor = {r = r, g = gc, b = b}
          RefreshGlobalCooldowns()
        end,
        order = 14.22, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      readyStateGlowIntensity = {
        type = "range", name = "Intensity", min = 0, max = 1.0, step = 0.05,
        desc = "Glow brightness",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowIntensity or 1.0
          end
          return 1.0
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowIntensity = v
          RefreshGlobalCooldowns()
        end,
        order = 14.23, width = 0.6,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow)
        end,
      },
      readyStateGlowScale = {
        type = "range", name = "Scale", min = 0.25, max = 4.0, step = 0.05,
        desc = "Size of the glow effect",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowScale or 1.0
          end
          return 1.0
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowScale = v
          RefreshGlobalCooldowns()
        end,
        order = 14.24, width = 0.55,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          local gt = g.cooldownStateVisuals.readyState.glowType; return gt ~= "autocast" and gt ~= "button"
        end,
      },
      readyStateGlowSpeed = {
        type = "range", name = "Speed", min = 0.05, max = 1.0, step = 0.05,
        desc = "How fast the glow animates",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowSpeed or 0.25
          end
          return 0.25
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowSpeed = v
          RefreshGlobalCooldowns()
        end,
        order = 14.25, width = 0.55,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          -- Proc glow doesn't use speed
          return g.cooldownStateVisuals.readyState.glowType == "proc"
        end,
      },
      readyStateGlowLines = {
        type = "range", name = "Lines", min = 1, max = 16, step = 1,
        desc = "Number of glow lines",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowLines or 8
          end
          return 8
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowLines = v
          RefreshGlobalCooldowns()
        end,
        order = 14.26, width = 0.55,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          return g.cooldownStateVisuals.readyState.glowType ~= "pixel"
        end,
      },
      readyStateGlowThickness = {
        type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
        desc = "Thickness of glow lines",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowThickness or 2
          end
          return 2
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowThickness = v
          RefreshGlobalCooldowns()
        end,
        order = 14.27, width = 0.55,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          return g.cooldownStateVisuals.readyState.glowType ~= "pixel"
        end,
      },
      readyStateGlowParticles = {
        type = "range", name = "Particles", min = 1, max = 16, step = 1,
        desc = "Number of sparkle groups",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowParticles or 4
          end
          return 4
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowParticles = v
          RefreshGlobalCooldowns()
        end,
        order = 14.28, width = 0.55,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          return g.cooldownStateVisuals.readyState.glowType ~= "autocast"
        end,
      },
      readyStateGlowXOffset = {
        type = "range", name = "X Offset", min = -50, max = 50, step = 1,
        desc = "Horizontal glow size adjustment",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowXOffset or 0
          end
          return 0
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowXOffset = v
          RefreshGlobalCooldowns()
        end,
        order = 14.29, width = 0.55,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          -- Button glow doesn't support offset
          return g.cooldownStateVisuals.readyState.glowType == "button"
        end,
      },
      readyStateGlowYOffset = {
        type = "range", name = "Y Offset", min = -50, max = 50, step = 1,
        desc = "Vertical glow size adjustment",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.readyState then
            return g.cooldownStateVisuals.readyState.glowYOffset or 0
          end
          return 0
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.readyState then g.cooldownStateVisuals.readyState = {} end
          g.cooldownStateVisuals.readyState.glowYOffset = v
          RefreshGlobalCooldowns()
        end,
        order = 14.295, width = 0.55,
        hidden = function()
          if collapsedGlobalCooldownSections.readyState then return true end
          local g = GetCooldownGlobalCfg()
          if not (g.cooldownStateVisuals and g.cooldownStateVisuals.readyState and g.cooldownStateVisuals.readyState.glow) then return true end
          -- Button glow doesn't support offset
          return g.cooldownStateVisuals.readyState.glowType == "button"
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- ON COOLDOWN STATE
      -- ═══════════════════════════════════════════════════════════════════
      inactiveStateHeader = {
        type = "toggle", name = "On Cooldown State", dialogControl = "CollapsibleHeader",
        desc = "How icons appear when the ability IS ON COOLDOWN. GCD is ignored.",
        get = function() return not collapsedGlobalCooldownSections.inactiveState end,
        set = function(_, v) collapsedGlobalCooldownSections.inactiveState = not v end,
        order = 15, width = "full",
      },
      cooldownStateAlpha = {
        type = "range", name = "Cooldown Alpha", min = 0, max = 1.0, step = 0.05,
        desc = "Icon opacity when on cooldown (0 = hidden, 1 = fully visible)",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.cooldownState then
            return g.cooldownStateVisuals.cooldownState.alpha or 1.0
          end
          return 1.0
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.cooldownState then g.cooldownStateVisuals.cooldownState = {} end
          g.cooldownStateVisuals.cooldownState.alpha = v
          RefreshGlobalCooldowns()
        end,
        order = 16, width = 0.8,
        hidden = function() return collapsedGlobalCooldownSections.inactiveState end,
      },
      cooldownStateDesaturate = {
        type = "toggle", name = "No Desaturation",
        desc = "Block the default desaturation when on cooldown. By default, CDM desaturates icons on cooldown - enable this to keep icons in full color.",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.cooldownState then
            return g.cooldownStateVisuals.cooldownState.noDesaturate or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.cooldownState then g.cooldownStateVisuals.cooldownState = {} end
          g.cooldownStateVisuals.cooldownState.noDesaturate = v
          RefreshGlobalCooldowns()
        end,
        order = 17, width = 1.0,
        hidden = function() return collapsedGlobalCooldownSections.inactiveState end,
      },
      cooldownStatePreserveDurationText = {
        type = "toggle", name = "Preserve Duration Text",
        desc = "Keep the cooldown duration text at full opacity even when the icon alpha is reduced. Useful for seeing cooldown timers on dimmed icons.",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.cooldownState then
            return g.cooldownStateVisuals.cooldownState.preserveDurationText or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.cooldownState then g.cooldownStateVisuals.cooldownState = {} end
          g.cooldownStateVisuals.cooldownState.preserveDurationText = v
          RefreshGlobalCooldowns()
        end,
        order = 17.1, width = 1.2,
        hidden = function() return collapsedGlobalCooldownSections.inactiveState end,
      },
      cooldownStateWaitForNoCharges = {
        type = "toggle", name = "Wait For No Charges",
        desc = "For charge spells only: Don't apply the cooldown alpha until all charges are consumed. The icon stays at full alpha while charges remain.\n\n|cffff6600Note:|r For spells that don't trigger the GCD (off-GCD abilities), a brief ~1 second flicker may occur due to API limitations.",
        get = function()
          local g = GetCooldownGlobalCfg()
          if g.cooldownStateVisuals and g.cooldownStateVisuals.cooldownState then
            return g.cooldownStateVisuals.cooldownState.waitForNoCharges or false
          end
          return false
        end,
        set = function(_, v)
          local g = GetCooldownGlobalCfg()
          if not g.cooldownStateVisuals then g.cooldownStateVisuals = {} end
          if not g.cooldownStateVisuals.cooldownState then g.cooldownStateVisuals.cooldownState = {} end
          g.cooldownStateVisuals.cooldownState.waitForNoCharges = v
          RefreshGlobalCooldowns()
        end,
        order = 17.2, width = 1.2,
        hidden = function() return collapsedGlobalCooldownSections.inactiveState end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- AURA ACTIVE STATE
      -- ═══════════════════════════════════════════════════════════════════
      auraActiveStateHeader = {
        type = "toggle", name = "Aura Active State", dialogControl = "CollapsibleHeader",
        desc = "Configure how icons appear when their associated aura/buff is active",
        get = function() return not collapsedGlobalCooldownSections.auraActiveState end,
        set = function(_, v) collapsedGlobalCooldownSections.auraActiveState = not v end,
        order = 18, width = "full",
      },
      globalIgnoreAuraOverride = {
        type = "toggle", name = "Ignore Aura Override",
        desc = "Show spell cooldown instead of aura duration when buff is active",
        get = function() 
          local g = GetCooldownGlobalCfg()
          -- Check new location first, then old location for backward compatibility
          if g.auraActiveState and g.auraActiveState.ignoreAuraOverride then
            return true
          end
          if g.cooldownSwipe and g.cooldownSwipe.ignoreAuraOverride then
            return true
          end
          return false
        end,
        set = function(_, v)
          -- Set in new location
          ApplyCooldownGlobalSetting("auraActiveState.ignoreAuraOverride", v)
          -- Clear from old location
          local g = GetCooldownGlobalCfg()
          if g.cooldownSwipe and g.cooldownSwipe.ignoreAuraOverride then
            g.cooldownSwipe.ignoreAuraOverride = nil
          end
          RefreshGlobalCooldowns()
        end,
        order = 18.1, width = 1.2,
        hidden = function() return collapsedGlobalCooldownSections.auraActiveState end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- COOLDOWN SWIPE
      -- ═══════════════════════════════════════════════════════════════════
      cooldownSwipeHeader = {
        type = "toggle", dialogControl = "CollapsibleHeader",
        name = function()
          if IsMasqueCooldownsActive() then
            return "Cooldown Swipe |cff00CCFF(Masque)|r"
          end
          return "Cooldown Swipe"
        end,
        desc = function()
          if IsMasqueCooldownsActive() then
            return "|cff00CCFFMasque controls most cooldown settings.|r You can still change swipe COLOR here (works in combat). Other options require disabling 'Use Masque Cooldowns' above."
          end
          return "Click to expand/collapse cooldown animation settings."
        end,
        get = function() return not collapsedGlobalCooldownSections.cooldownSwipe end,
        set = function(_, v) collapsedGlobalCooldownSections.cooldownSwipe = not v end,
        order = 20, width = "full",
        -- NOT disabled - users need to expand this to access swipe color options
      },
      showSwipe = {
        type = "toggle", name = "Show Swipe",
        get = function() local g = GetCooldownGlobalCfg(); return not g.cooldownSwipe or g.cooldownSwipe.showSwipe ~= false end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.showSwipe", v); RefreshGlobalCooldowns() end,
        order = 21, width = 0.6, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end,
        -- NOT disabled when Masque controls cooldowns - user can still toggle swipe visibility
      },
      noGCDSwipe = {
        type = "toggle", name = "No GCD Swipe",
        desc = "Hide GCD swipes (cooldowns 1.5s or less)",
        get = function() 
          local g = GetCooldownGlobalCfg()
          if not g.cooldownSwipe then return false end
          return g.cooldownSwipe.noGCDSwipe or false
        end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.noGCDSwipe", v); RefreshGlobalCooldowns() end,
        order = 22, width = 0.7, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end,
        -- NOT disabled when Masque controls cooldowns - hiding GCD doesn't conflict with Masque
      },
      swipeWaitForNoCharges = {
        type = "toggle", name = "Wait No Charges",
        desc = "For charge spells: Only show swipe when ALL charges are consumed",
        get = function() 
          local g = GetCooldownGlobalCfg()
          if not g.cooldownSwipe then return false end
          return g.cooldownSwipe.swipeWaitForNoCharges or false
        end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.swipeWaitForNoCharges", v); RefreshGlobalCooldowns() end,
        order = 22.5, width = 0.8, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      showEdge = {
        type = "toggle", name = "Edge",
        get = function() local g = GetCooldownGlobalCfg(); return not g.cooldownSwipe or g.cooldownSwipe.showEdge ~= false end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.showEdge", v); RefreshGlobalCooldowns() end,
        order = 23, width = 0.4, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end,
        -- NOT disabled when Masque controls cooldowns - user can still toggle edge visibility
      },
      showBling = {
        type = "toggle", name = "Bling",
        get = function() local g = GetCooldownGlobalCfg(); return not g.cooldownSwipe or g.cooldownSwipe.showBling ~= false end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.showBling", v); RefreshGlobalCooldowns() end,
        order = 24, width = 0.4, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end,
        -- NOT disabled when Masque controls cooldowns - finish flash can be controlled independently
      },
      reverse = {
        type = "toggle", name = "Reverse",
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.reverse end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.reverse", v); RefreshGlobalCooldowns() end,
        order = 25, width = 0.5, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      swipeColorEnabled = {
        type = "toggle", name = "Custom Color",
        desc = function()
          if IsMasqueCooldownsActive() then
            return "|cff00CCFFMasque controls swipe color.|r ArcUI applies Masque's skin color using a method that works in combat."
          end
          return "Use a custom swipe color instead of CDM default"
        end,
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.swipeColor ~= nil end,
        set = function(_, v)
          if v then
            ApplyCooldownGlobalSetting("cooldownSwipe.swipeColor", {r=0, g=0, b=0, a=0.8})
          else
            ApplyCooldownGlobalSetting("cooldownSwipe.swipeColor", nil)
          end
          RefreshGlobalCooldowns()
        end,
        order = 26, width = 0.7, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end,
        disabled = IsMasqueCooldownsActive,  -- Masque controls color, ArcUI applies it
      },
      swipeColor = {
        type = "color", name = "Color", hasAlpha = true,
        get = function()
          local g = GetCooldownGlobalCfg()
          local c = g.cooldownSwipe and g.cooldownSwipe.swipeColor
          if c then return c.r or c[1] or 0, c.g or c[2] or 0, c.b or c[3] or 0, c.a or c[4] or 0.8 end
          return 0, 0, 0, 0.8
        end,
        set = function(_, r, gc, b, a)
          ApplyCooldownGlobalSetting("cooldownSwipe.swipeColor", {r=r, g=gc, b=b, a=a}); RefreshGlobalCooldowns()
        end,
        order = 27, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.cooldownSwipe then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownSwipe and g.cooldownSwipe.swipeColor)
        end,
      },
      swipeInset = {
        type = "range", name = "Swipe Inset", min = -20, max = 40, step = 1,
        desc = "Inset for the swipe animation (all sides). Positive = smaller, negative = larger.",
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.swipeInset or 0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.swipeInset", v); RefreshGlobalCooldowns() end,
        order = 27.4, width = 0.6,
        hidden = function()
          if collapsedGlobalCooldownSections.cooldownSwipe then return true end
          local g = GetCooldownGlobalCfg()
          return g.cooldownSwipe and g.cooldownSwipe.separateInsets
        end,
      },
      separateInsets = {
        type = "toggle", name = "W/H",
        desc = "Enable separate Width and Height insets instead of a single inset",
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.separateInsets end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.separateInsets", v); RefreshGlobalCooldowns() end,
        order = 27.45, width = 0.35, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      swipeInsetX = {
        type = "range", name = "Width", min = -20, max = 40, step = 1,
        desc = "Horizontal inset (left/right). Positive = narrower, negative = wider.",
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.swipeInsetX or 0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.swipeInsetX", v); RefreshGlobalCooldowns() end,
        order = 27.5, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.cooldownSwipe then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownSwipe and g.cooldownSwipe.separateInsets)
        end,
      },
      swipeInsetY = {
        type = "range", name = "Height", min = -20, max = 40, step = 1,
        desc = "Vertical inset (top/bottom). Positive = shorter, negative = taller.",
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.swipeInsetY or 0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.swipeInsetY", v); RefreshGlobalCooldowns() end,
        order = 27.6, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.cooldownSwipe then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownSwipe and g.cooldownSwipe.separateInsets)
        end,
      },
      edgeScale = {
        type = "range", name = "Edge Scale", min = 0.1, max = 3.0, step = 0.1,
        desc = "Size of the cooldown edge spinner",
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.edgeScale or 1.0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownSwipe.edgeScale", v); RefreshGlobalCooldowns() end,
        order = 28.1, width = 0.7, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      edgeColorEnabled = {
        type = "toggle", name = "Edge Color",
        desc = "Enable custom edge color",
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownSwipe and g.cooldownSwipe.edgeColor ~= nil end,
        set = function(_, v)
          if v then
            ApplyCooldownGlobalSetting("cooldownSwipe.edgeColor", {r=1, g=1, b=1, a=1})
          else
            ApplyCooldownGlobalSetting("cooldownSwipe.edgeColor", nil)
          end
          RefreshGlobalCooldowns()
        end,
        order = 28.2, width = 0.65, hidden = function() return collapsedGlobalCooldownSections.cooldownSwipe end, disabled = IsMasqueCooldownsActive,
      },
      edgeColor = {
        type = "color", name = "Edge", hasAlpha = true,
        desc = "Color of the spinning edge line",
        get = function()
          local g = GetCooldownGlobalCfg()
          local c = g.cooldownSwipe and g.cooldownSwipe.edgeColor
          if c then return c.r or c[1] or 1, c.g or c[2] or 1, c.b or c[3] or 1, c.a or c[4] or 1 end
          return 1, 1, 1, 1
        end,
        set = function(_, r, gc, b, a)
          ApplyCooldownGlobalSetting("cooldownSwipe.edgeColor", {r=r, g=gc, b=b, a=a}); RefreshGlobalCooldowns()
        end,
        order = 28.3, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.cooldownSwipe then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.cooldownSwipe and g.cooldownSwipe.edgeColor)
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- CHARGE TEXT
      -- ═══════════════════════════════════════════════════════════════════
      chargeTextHeader = {
        type = "toggle", name = "Charge/Stack Text", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalCooldownSections.chargeText end,
        set = function(_, v) collapsedGlobalCooldownSections.chargeText = not v end,
        order = 30, width = "full",
      },
      chargeEnabled = {
        type = "toggle", name = "Enabled",
        get = function() local g = GetCooldownGlobalCfg(); return not g.chargeText or g.chargeText.enabled ~= false end,
        set = function(_, v) ApplyCooldownGlobalSetting("chargeText.enabled", v); RefreshGlobalCooldowns() end,
        order = 31, width = 0.5, hidden = function() return collapsedGlobalCooldownSections.chargeText end,
      },
      chargeSize = {
        type = "range", name = "Size", min = 4, max = 64, step = 1,
        get = function() local g = GetCooldownGlobalCfg(); return g.chargeText and g.chargeText.size or 14 end,
        set = function(_, v) ApplyCooldownGlobalSetting("chargeText.size", v); RefreshGlobalCooldowns() end,
        order = 32, width = 0.7, hidden = function() return collapsedGlobalCooldownSections.chargeText end,
      },
      chargeColor = {
        type = "color", name = "Color", hasAlpha = true,
        get = function()
          local g = GetCooldownGlobalCfg()
          local c = g.chargeText and g.chargeText.color
          if c then return c.r or 1, c.g or 1, c.b or 1, c.a or 1 end
          return 1, 1, 1, 1
        end,
        set = function(_, r, g, b, a)
          ApplyCooldownGlobalSetting("chargeText.color", {r=r, g=g, b=b, a=a}); RefreshGlobalCooldowns()
        end,
        order = 32.5, width = 0.5, hidden = function() return collapsedGlobalCooldownSections.chargeText end,
      },
      chargeFont = {
        type = "select", name = "Font", dialogControl = "LSM30_Font",
        values = LSM and LSM:HashTable("font") or {},
        get = function() local g = GetCooldownGlobalCfg(); return g.chargeText and g.chargeText.font or "Friz Quadrata TT" end,
        set = function(_, v) ApplyCooldownGlobalSetting("chargeText.font", v); RefreshGlobalCooldowns() end,
        order = 33, width = 1.0, hidden = function() return collapsedGlobalCooldownSections.chargeText end,
      },
      chargeOutline = {
        type = "select", name = "Outline",
        values = { [""] = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick" },
        get = function() local g = GetCooldownGlobalCfg(); return GetOutlineValue(g.chargeText and g.chargeText.outline) end,
        set = function(_, v) ApplyCooldownGlobalSetting("chargeText.outline", v); RefreshGlobalCooldowns() end,
        order = 34, width = 0.7, hidden = function() return collapsedGlobalCooldownSections.chargeText end,
      },
      chargeShadow = {
        type = "toggle", name = "Shadow",
        get = function() local g = GetCooldownGlobalCfg(); return g.chargeText and g.chargeText.shadow end,
        set = function(_, v) ApplyCooldownGlobalSetting("chargeText.shadow", v); RefreshGlobalCooldowns() end,
        order = 34.5, width = 0.5, hidden = function() return collapsedGlobalCooldownSections.chargeText end,
      },
      chargePositionLabel = {
        type = "description", name = "|cffffd700Position|r", fontSize = "medium",
        order = 34.8, width = "full", hidden = function() return collapsedGlobalCooldownSections.chargeText end,
      },
      chargeMode = {
        type = "select", name = "Mode",
        values = { anchor = "Anchor Position", free = "Free Drag" },
        get = function() local g = GetCooldownGlobalCfg(); return g.chargeText and g.chargeText.mode or "anchor" end,
        set = function(_, v) ApplyCooldownGlobalSetting("chargeText.mode", v); RefreshGlobalCooldowns() end,
        order = 35, width = 0.8, hidden = function() return collapsedGlobalCooldownSections.chargeText end,
      },
      chargeAnchor = {
        type = "select", name = "Anchor",
        values = { TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right", LEFT = "Left", CENTER = "Center", RIGHT = "Right", BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right" },
        get = function() local g = GetCooldownGlobalCfg(); return g.chargeText and g.chargeText.anchor or "BOTTOMRIGHT" end,
        set = function(_, v) ApplyCooldownGlobalSetting("chargeText.anchor", v); RefreshGlobalCooldowns() end,
        order = 35.1, width = 0.8,
        hidden = function()
          if collapsedGlobalCooldownSections.chargeText then return true end
          local g = GetCooldownGlobalCfg()
          return g.chargeText and g.chargeText.mode == "free"
        end,
      },
      chargeOffsetX = {
        type = "range", name = "X Offset", min = -100, max = 100, step = 1,
        get = function() local g = GetCooldownGlobalCfg(); return g.chargeText and g.chargeText.offsetX or -2 end,
        set = function(_, v) ApplyCooldownGlobalSetting("chargeText.offsetX", v); RefreshGlobalCooldowns() end,
        order = 35.2, width = 0.7,
        hidden = function()
          if collapsedGlobalCooldownSections.chargeText then return true end
          local g = GetCooldownGlobalCfg()
          return g.chargeText and g.chargeText.mode == "free"
        end,
      },
      chargeOffsetY = {
        type = "range", name = "Y Offset", min = -100, max = 100, step = 1,
        get = function() local g = GetCooldownGlobalCfg(); return g.chargeText and g.chargeText.offsetY or 2 end,
        set = function(_, v) ApplyCooldownGlobalSetting("chargeText.offsetY", v); RefreshGlobalCooldowns() end,
        order = 35.3, width = 0.7,
        hidden = function()
          if collapsedGlobalCooldownSections.chargeText then return true end
          local g = GetCooldownGlobalCfg()
          return g.chargeText and g.chargeText.mode == "free"
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- COOLDOWN TEXT
      -- ═══════════════════════════════════════════════════════════════════
      cooldownTextHeader = {
        type = "toggle", name = "Cooldown/Duration Text", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalCooldownSections.cooldownText end,
        set = function(_, v) collapsedGlobalCooldownSections.cooldownText = not v end,
        order = 40, width = "full",
      },
      cdTextEnabled = {
        type = "toggle", name = "Enabled",
        get = function() local g = GetCooldownGlobalCfg(); return not g.cooldownText or g.cooldownText.enabled ~= false end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownText.enabled", v); RefreshGlobalCooldowns() end,
        order = 41, width = 0.5, hidden = function() return collapsedGlobalCooldownSections.cooldownText end,
      },
      cdTextSize = {
        type = "range", name = "Size", min = 4, max = 64, step = 1,
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownText and g.cooldownText.size or 14 end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownText.size", v); RefreshGlobalCooldowns() end,
        order = 42, width = 0.7, hidden = function() return collapsedGlobalCooldownSections.cooldownText end,
      },
      cdTextColor = {
        type = "color", name = "Color", hasAlpha = true,
        get = function()
          local g = GetCooldownGlobalCfg()
          local c = g.cooldownText and g.cooldownText.color
          if c then return c.r or 1, c.g or 1, c.b or 1, c.a or 1 end
          return 1, 1, 1, 1
        end,
        set = function(_, r, g, b, a)
          ApplyCooldownGlobalSetting("cooldownText.color", {r=r, g=g, b=b, a=a}); RefreshGlobalCooldowns()
        end,
        order = 42.5, width = 0.5, hidden = function() return collapsedGlobalCooldownSections.cooldownText end,
      },
      cdTextFont = {
        type = "select", name = "Font", dialogControl = "LSM30_Font",
        values = LSM and LSM:HashTable("font") or {},
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownText and g.cooldownText.font or "Friz Quadrata TT" end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownText.font", v); RefreshGlobalCooldowns() end,
        order = 43, width = 1.0, hidden = function() return collapsedGlobalCooldownSections.cooldownText end,
      },
      cdTextOutline = {
        type = "select", name = "Outline",
        values = { [""] = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick" },
        get = function() local g = GetCooldownGlobalCfg(); return GetOutlineValue(g.cooldownText and g.cooldownText.outline) end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownText.outline", v); RefreshGlobalCooldowns() end,
        order = 44, width = 0.7, hidden = function() return collapsedGlobalCooldownSections.cooldownText end,
      },
      cdTextShadow = {
        type = "toggle", name = "Shadow",
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownText and g.cooldownText.shadow end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownText.shadow", v); RefreshGlobalCooldowns() end,
        order = 44.5, width = 0.5, hidden = function() return collapsedGlobalCooldownSections.cooldownText end,
      },
      cdPositionLabel = {
        type = "description", name = "|cffffd700Position|r", fontSize = "medium",
        order = 44.8, width = "full", hidden = function() return collapsedGlobalCooldownSections.cooldownText end,
      },
      cdTextMode = {
        type = "select", name = "Mode",
        values = { anchor = "Anchor Position", free = "Free Drag" },
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownText and g.cooldownText.mode or "anchor" end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownText.mode", v); RefreshGlobalCooldowns() end,
        order = 45, width = 0.8, hidden = function() return collapsedGlobalCooldownSections.cooldownText end,
      },
      cdTextAnchor = {
        type = "select", name = "Anchor",
        values = { TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right", LEFT = "Left", CENTER = "Center", RIGHT = "Right", BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right" },
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownText and g.cooldownText.anchor or "CENTER" end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownText.anchor", v); RefreshGlobalCooldowns() end,
        order = 45.1, width = 0.8,
        hidden = function()
          if collapsedGlobalCooldownSections.cooldownText then return true end
          local g = GetCooldownGlobalCfg()
          return g.cooldownText and g.cooldownText.mode == "free"
        end,
      },
      cdTextOffsetX = {
        type = "range", name = "X Offset", min = -100, max = 100, step = 1,
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownText and g.cooldownText.offsetX or 0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownText.offsetX", v); RefreshGlobalCooldowns() end,
        order = 45.2, width = 0.7,
        hidden = function()
          if collapsedGlobalCooldownSections.cooldownText then return true end
          local g = GetCooldownGlobalCfg()
          return g.cooldownText and g.cooldownText.mode == "free"
        end,
      },
      cdTextOffsetY = {
        type = "range", name = "Y Offset", min = -100, max = 100, step = 1,
        get = function() local g = GetCooldownGlobalCfg(); return g.cooldownText and g.cooldownText.offsetY or 0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("cooldownText.offsetY", v); RefreshGlobalCooldowns() end,
        order = 45.3, width = 0.7,
        hidden = function()
          if collapsedGlobalCooldownSections.cooldownText then return true end
          local g = GetCooldownGlobalCfg()
          return g.cooldownText and g.cooldownText.mode == "free"
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- PROC GLOW
      -- ═══════════════════════════════════════════════════════════════════
      procGlowHeader = {
        type = "toggle", name = "Proc Glow", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalCooldownSections.procGlow end,
        set = function(_, v) collapsedGlobalCooldownSections.procGlow = not v end,
        order = 50, width = "full",
      },
      glowEnabled = {
        type = "toggle", name = "Enabled",
        get = function() local g = GetCooldownGlobalCfg(); return not g.procGlow or g.procGlow.enabled ~= false end,
        set = function(_, v) ApplyCooldownGlobalSetting("procGlow.enabled", v); RefreshGlobalCooldowns() end,
        order = 51, width = 0.5, hidden = function() return collapsedGlobalCooldownSections.procGlow end,
      },
      glowType = {
        type = "select", name = "Type",
        values = { default = "Default (Blizzard)", pixel = "Pixel", autocast = "Autocast", button = "Button", proc = "Proc" },
        sorting = {"default", "proc", "pixel", "autocast", "button"},
        get = function() local g = GetCooldownGlobalCfg(); return g.procGlow and g.procGlow.glowType or "default" end,
        set = function(_, v) ApplyCooldownGlobalSetting("procGlow.glowType", v); RefreshGlobalCooldowns() end,
        order = 52, width = 0.7, hidden = function() return collapsedGlobalCooldownSections.procGlow end,
      },
      glowColor = {
        type = "color", name = "Color",
        desc = "Glow color (white = default)",
        get = function()
          local g = GetCooldownGlobalCfg()
          local col = g.procGlow and g.procGlow.color
          if col then return col.r or 1, col.g or 1, col.b or 1 end
          return 1, 1, 1
        end,
        set = function(_, r, gc, b)
          if r == 1 and gc == 1 and b == 1 then
            ApplyCooldownGlobalSetting("procGlow.color", nil)
          else
            ApplyCooldownGlobalSetting("procGlow.color", {r=r, g=gc, b=b})
          end
          RefreshGlobalCooldowns()
        end,
        order = 52.5, width = 0.4,
        hidden = function()
          if collapsedGlobalCooldownSections.procGlow then return true end
          local g = GetCooldownGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType == "default"
        end,
      },
      glowAlpha = {
        type = "range", name = "Intensity", min = 0, max = 1.0, step = 0.05,
        desc = "How bright the glow appears",
        get = function() local g = GetCooldownGlobalCfg(); return g.procGlow and g.procGlow.alpha or 1.0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("procGlow.alpha", v); RefreshGlobalCooldowns() end,
        order = 52.6, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.procGlow then return true end
          local g = GetCooldownGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType == "default"
        end,
      },
      glowScale = {
        type = "range", name = "Scale", min = 0.25, max = 4.0, step = 0.05, isPercent = true,
        get = function() local g = GetCooldownGlobalCfg(); return g.procGlow and g.procGlow.scale or 1.0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("procGlow.scale", v); RefreshGlobalCooldowns() end,
        order = 53, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.procGlow then return true end
          local g = GetCooldownGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType ~= "autocast" and glowType ~= "button"
        end,
      },
      glowSpeed = {
        type = "range", name = "Speed", min = 0.05, max = 1.0, step = 0.05,
        desc = "Animation speed",
        get = function() local g = GetCooldownGlobalCfg(); return g.procGlow and g.procGlow.speed or 0.25 end,
        set = function(_, v) ApplyCooldownGlobalSetting("procGlow.speed", v); RefreshGlobalCooldowns() end,
        order = 53.5, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.procGlow then return true end
          local g = GetCooldownGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType == "default" or glowType == "proc"
        end,
      },
      glowLines = {
        type = "range", name = "Lines", min = 1, max = 16, step = 1,
        desc = "Number of glow lines",
        get = function() local g = GetCooldownGlobalCfg(); return g.procGlow and g.procGlow.lines or 8 end,
        set = function(_, v) ApplyCooldownGlobalSetting("procGlow.lines", v); RefreshGlobalCooldowns() end,
        order = 54, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.procGlow then return true end
          local g = GetCooldownGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType ~= "pixel"
        end,
      },
      glowThickness = {
        type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
        desc = "Thickness of glow lines",
        get = function() local g = GetCooldownGlobalCfg(); return g.procGlow and g.procGlow.thickness or 2 end,
        set = function(_, v) ApplyCooldownGlobalSetting("procGlow.thickness", v); RefreshGlobalCooldowns() end,
        order = 54.5, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.procGlow then return true end
          local g = GetCooldownGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType ~= "pixel"
        end,
      },
      glowParticles = {
        type = "range", name = "Particles", min = 1, max = 16, step = 1,
        desc = "Number of sparkle groups",
        get = function() local g = GetCooldownGlobalCfg(); return g.procGlow and g.procGlow.particles or 4 end,
        set = function(_, v) ApplyCooldownGlobalSetting("procGlow.particles", v); RefreshGlobalCooldowns() end,
        order = 55, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.procGlow then return true end
          local g = GetCooldownGlobalCfg()
          local glowType = g.procGlow and g.procGlow.glowType or "default"
          return glowType ~= "autocast"
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- BORDER
      -- ═══════════════════════════════════════════════════════════════════
      borderHeader = {
        type = "toggle", name = "Border", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalCooldownSections.border end,
        set = function(_, v) collapsedGlobalCooldownSections.border = not v end,
        order = 56, width = "full",
      },
      borderEnabled = {
        type = "toggle", name = "Show Border",
        get = function() local g = GetCooldownGlobalCfg(); return g.border and g.border.enabled end,
        set = function(_, v) ApplyCooldownGlobalSetting("border.enabled", v); RefreshGlobalCooldowns() end,
        order = 56.1, width = 0.6, hidden = function() return collapsedGlobalCooldownSections.border end,
      },
      borderUseClassColor = {
        type = "toggle", name = "Class Color",
        desc = "Use your class color for the border",
        get = function() local g = GetCooldownGlobalCfg(); return g.border and g.border.useClassColor end,
        set = function(_, v) ApplyCooldownGlobalSetting("border.useClassColor", v); RefreshGlobalCooldowns() end,
        order = 56.2, width = 0.7,
        hidden = function()
          if collapsedGlobalCooldownSections.border then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.border and g.border.enabled)
        end,
      },
      borderThickness = {
        type = "range", name = "Thickness", min = 1, max = 10, step = 0.5,
        get = function() local g = GetCooldownGlobalCfg(); return g.border and g.border.thickness or 1 end,
        set = function(_, v) ApplyCooldownGlobalSetting("border.thickness", v); RefreshGlobalCooldowns() end,
        order = 56.3, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.border then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.border and g.border.enabled)
        end,
      },
      borderInset = {
        type = "range", name = "Offset", min = -20, max = 20, step = 1,
        desc = "Border position offset. Negative = outset (outside icon), Positive = inset (inside icon). Automatically accounts for zoom.",
        get = function() local g = GetCooldownGlobalCfg(); return g.border and g.border.inset or 0 end,
        set = function(_, v) ApplyCooldownGlobalSetting("border.inset", v); RefreshGlobalCooldowns() end,
        order = 56.4, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.border then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.border and g.border.enabled)
        end,
      },
      borderColor = {
        type = "color", name = "Color", hasAlpha = true,
        get = function()
          local g = GetCooldownGlobalCfg()
          local c = g.border and g.border.color
          if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
          return 1, 1, 1, 1
        end,
        set = function(_, r, gc, b, a)
          ApplyCooldownGlobalSetting("border.color", {r, gc, b, a}); RefreshGlobalCooldowns()
        end,
        order = 56.5, width = 0.5,
        hidden = function()
          if collapsedGlobalCooldownSections.border then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.border and g.border.enabled) or (g.border and g.border.useClassColor)
        end,
      },
      borderFollowDesat = {
        type = "toggle", name = "Follow Desat",
        desc = "Desaturate border when icon is desaturated",
        get = function() local g = GetCooldownGlobalCfg(); return g.border and g.border.followDesaturation end,
        set = function(_, v) ApplyCooldownGlobalSetting("border.followDesaturation", v); RefreshGlobalCooldowns() end,
        order = 56.6, width = 0.6,
        hidden = function()
          if collapsedGlobalCooldownSections.border then return true end
          local g = GetCooldownGlobalCfg()
          return not (g.border and g.border.enabled)
        end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- RANGE INDICATOR
      -- ═══════════════════════════════════════════════════════════════════
      rangeHeader = {
        type = "toggle", name = "Range Indicator", dialogControl = "CollapsibleHeader",
        get = function() return not collapsedGlobalCooldownSections.rangeIndicator end,
        set = function(_, v) collapsedGlobalCooldownSections.rangeIndicator = not v end,
        order = 60, width = "full",
      },
      rangeEnabled = {
        type = "toggle", name = "Show Range Overlay",
        desc = "Show the out-of-range darkening overlay when spells are out of range",
        get = function() local g = GetCooldownGlobalCfg(); return not g.rangeIndicator or g.rangeIndicator.enabled ~= false end,
        set = function(_, v) ApplyCooldownGlobalSetting("rangeIndicator.enabled", v); RefreshGlobalCooldowns() end,
        order = 61, width = 1.0, hidden = function() return collapsedGlobalCooldownSections.rangeIndicator end,
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- RESET DEFAULTS
      -- ═══════════════════════════════════════════════════════════════════
      resetSpacer = {
        type = "description", name = "", order = 90, width = "full",
      },
      clearPerIconOverrides = {
        type = "execute",
        name = "Clear Per-Icon Overrides",
        desc = "Remove all per-icon customizations from cooldown icons so they use global defaults.\n\n|cffff9900This will clear any individual icon scale, text, glow settings you've set!|r",
        func = function()
          if ns.CDMEnhance and ns.CDMEnhance.ResetAllIconsToDefaults then
            local count = ns.CDMEnhance.ResetAllIconsToDefaults("cooldown")
            print(string.format("|cff00FF00[ArcUI CDM]|r Cleared per-icon settings from %d cooldown icons. Global defaults now apply.", count or 0))
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 90,
        width = 1.3,
        confirm = true,
        confirmText = "Clear ALL per-icon customizations from cooldown icons?\n\nThis will make all cooldown icons use global defaults.",
      },
      resetDefaults = {
        type = "execute",
        name = "Reset All Cooldown Defaults",
        desc = "Reset all cooldown global defaults to their original values",
        func = function()
          if ns.CDMEnhance and ns.CDMEnhance.ResetGlobalDefaults then
            ns.CDMEnhance.ResetGlobalDefaults("cooldown")
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 91,
        width = 1.3,
        confirm = true,
        confirmText = "Reset all cooldown global defaults to original values?",
      },
    },
  }
end

-- ===================================================================
-- UNIFIED CDM ICONS OPTIONS TABLE
-- Merges aura and cooldown per-icon options into a single panel
-- ===================================================================
function ns.GetCDMIconsOptionsTable()
  -- Get the aura and cooldown option tables to extract per-icon options
  local auraTable = ns.GetCDMAuraIconsOptionsTable()
  local cooldownTable = ns.GetCDMCooldownIconsOptionsTable()
  
  -- Keys to skip (control/catalog elements that we replace with unified versions)
  local skipKeys = {
    desc = true, disclaimer = true, enableCustomization = true,
    openCDM = true, scanBtn = true, filterDropdown = true,
    catalogHeader = true, editAllToggle = true, catalogHint = true,
    currentlyEditingHeader = true, bottomSpacer = true,
    noSelectionHint = true, resetAllPositions = true, resetAllOptions = true,
    deselectBtn = true, resetSingleIconBtn = true, resetSelectedIconBtn = true,
    -- Skip global options (they're defined in the unified panel already)
    globalOptionsHeader = true, globalOptionsDesc = true,
    showTooltips = true, clickThrough = true,
  }
  -- Also skip catalogIcon entries
  for i = 1, 50 do
    skipKeys["catalogIcon" .. i] = true
  end
  
  local args = {
    desc = {
      type = "description",
      name = "Customize CDM icons. Use the filter dropdown to switch between Cooldowns, Auras, or view icons in specific groups.",
      order = 1,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CONTROLS
    -- ═══════════════════════════════════════════════════════════════════
    masterEnable = {
      type = "toggle",
      name = "|cff00ff00Enable CDM Styling|r",
      desc = "Master toggle to enable/disable all CDM icon styling and group management.\n\n|cffffaa00Reload recommended after changing.|r\n\nWhen disabled, icons stay under default CDM control.",
      order = 2,
      width = 1.0,
      get = function() 
        -- Use centralized function from CDM_Shared
        if Shared and Shared.IsCDMStylingEnabled then
          return Shared.IsCDMStylingEnabled()
        end
        return true
      end,
      set = function(_, val) 
        -- Use centralized function from CDM_Shared
        if Shared and Shared.SetCDMStylingEnabled then
          Shared.SetCDMStylingEnabled(val)
        end
      end,
    },
    openCDM = {
      type = "execute",
      name = "Open CD Manager",
      desc = "Open the Cooldown Manager settings panel",
      order = 3,
      width = 0.85,
      func = function()
        local frame = _G["CooldownViewerSettings"]
        if frame and frame.Show then frame:Show(); frame:Raise() end
      end,
    },
    scanBtn = {
      type = "execute",
      name = "Scan CDM",
      desc = "Rescan CDM viewers for icons",
      order = 3.1,
      width = 0.55,
      func = function()
        if ns.CDMEnhance then
          ns.CDMEnhance.ScanCDM()
          cachedUnifiedFilterMode = nil
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end
      end,
    },
    filterDropdown = {
      type = "select",
      name = "Filter",
      desc = "Filter icons to show",
      values = GetUnifiedFilterValues,
      get = function() return unifiedFilterMode end,
      set = function(_, v)
        unifiedFilterMode = v
        cachedUnifiedFilterMode = nil
        selectedAuraIcon = nil
        selectedCooldownIcon = nil
        wipe(selectedAuraIcons)
        wipe(selectedCooldownIcons)
        -- Reset edit-all modes when filter changes to prevent stale state
        editAllUnifiedMode = false
        editAllAurasMode = false
        editAllCooldownsMode = false
        -- Refresh cooldown preview when filter changes
        if ns.CDMEnhance and ns.CDMEnhance.RefreshCooldownPreview then
          ns.CDMEnhance.RefreshCooldownPreview()
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      order = 4,
      width = 1.0,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- GLOBAL OPTIONS (collapsible)
    -- ═══════════════════════════════════════════════════════════════════
    globalOptionsToggle = {
      type = "toggle",
      name = "Global Options",
      desc = "Click to expand/collapse",
      dialogControl = "CollapsibleHeader",
      order = 5,
      width = "full",
      get = function() return not collapsedSections.globalOptions end,
      set = function(_, v)
        collapsedSections.globalOptions = not v
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    globalOptionsDesc = {
      type = "description",
      name = "|cffaaaaaaSettings that apply to all icons managed by ArcUI.|r",
      order = 5.05,
      width = "full",
      fontSize = "small",
      hidden = function() return collapsedSections.globalOptions end,
    },
    showTooltips = {
      type = "toggle",
      name = "Show Tooltips",
      desc = "When enabled, hovering over icons shows spell tooltips.\n\nWhen disabled, tooltips are hidden on all icons managed by ArcUI.",
      order = 5.1,
      width = 0.7,
      hidden = function() return collapsedSections.globalOptions end,
      get = function()
        local db = Shared.GetCDMGroupsDB()
        if not db then
          return true  -- Default: show tooltips
        end
        return db.disableTooltips ~= true
      end,
      set = function(_, val)
        local db = Shared.GetCDMGroupsDB()
        if not db then return end
        
        db.disableTooltips = not val
        if ns.CDMGroups and ns.CDMGroups.RefreshIconSettings then
          ns.CDMGroups.RefreshIconSettings()
        end
      end,
    },
    clickThrough = {
      type = "toggle",
      name = "Click-Through",
      desc = "When enabled, icons cannot be clicked - mouse clicks pass through to whatever is behind them.\n\nUseful if icons overlap clickable UI elements.",
      order = 5.2,
      width = 0.7,
      hidden = function() return collapsedSections.globalOptions end,
      get = function()
        local db = Shared.GetCDMGroupsDB()
        if not db then
          return false  -- Default: clickable
        end
        return db.clickThrough == true
      end,
      set = function(_, val)
        local db = Shared.GetCDMGroupsDB()
        if not db then return end
        
        db.clickThrough = val
        if ns.CDMGroups and ns.CDMGroups.RefreshIconSettings then
          ns.CDMGroups.RefreshIconSettings()
        end
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- KEYBINDS SECTION
    -- ═══════════════════════════════════════════════════════════════════
    keybindsToggle = {
      type = "toggle",
      name = "Keybind Display",
      desc = "Click to expand/collapse",
      dialogControl = "CollapsibleHeader",
      order = 6,
      width = "full",
      get = function() return not collapsedSections.keybinds end,
      set = function(_, v)
        collapsedSections.keybinds = not v
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    showKeybinds = {
      type = "toggle",
      name = "Enable",
      desc = "When enabled, action bar keybinds are displayed on cooldown icons.\n\nShows the key you press to activate each ability.",
      order = 6.02,
      width = 0.5,
      hidden = function() return collapsedSections.keybinds end,
      get = function()
        return ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled() or false
      end,
      set = function(_, val)
        if ns.Keybinds and ns.Keybinds.SetEnabled then
          ns.Keybinds.SetEnabled(val)
        end
      end,
    },
    keybindFont = {
      type = "select",
      name = "Font",
      dialogControl = "LSM30_Font",
      values = LSM and LSM:HashTable("font") or {},
      order = 6.03,
      width = 0.9,
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return settings and settings.font or "Friz Quadrata TT"
      end,
      set = function(_, val)
        if ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("font", val)
        end
      end,
    },
    keybindFontSize = {
      type = "range",
      name = "Size",
      desc = "Font size for keybind text",
      order = 6.04,
      width = 0.7,
      min = 6, max = 32, step = 1,
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return settings and settings.fontSize or 12
      end,
      set = function(_, val)
        if ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("fontSize", val)
        end
      end,
    },
    keybindOutline = {
      type = "select",
      name = "Outline",
      values = {
        [""] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick",
        ["MONOCHROME"] = "Mono",
      },
      order = 6.05,
      width = 0.55,
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return settings and settings.fontOutline or "OUTLINE"
      end,
      set = function(_, val)
        if ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("fontOutline", val)
        end
      end,
    },
    keybindColor = {
      type = "color",
      name = "Color",
      hasAlpha = true,
      order = 6.06,
      width = 0.45,
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        local c = settings and settings.color or { 1, 1, 1, 1 }
        return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
      end,
      set = function(_, r, g, b, a)
        if ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("color", { r, g, b, a })
        end
      end,
    },
    keybindAnchor = {
      type = "select",
      name = "Anchor",
      desc = "Position to display keybind text on the icon",
      order = 6.07,
      width = 0.65,
      values = {
        TOPLEFT = "Top Left",
        TOP = "Top",
        TOPRIGHT = "Top Right",
        LEFT = "Left",
        CENTER = "Center",
        RIGHT = "Right",
        BOTTOMLEFT = "Bottom Left",
        BOTTOM = "Bottom",
        BOTTOMRIGHT = "Bottom Right",
      },
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return settings and settings.anchor or "TOPRIGHT"
      end,
      set = function(_, val)
        if ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("anchor", val)
        end
      end,
    },
    keybindOffsetX = {
      type = "range",
      name = "X Offset",
      desc = "Horizontal offset for keybind text",
      order = 6.08,
      width = 0.6,
      min = -50, max = 50, step = 1,
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return settings and settings.offsetX or -1
      end,
      set = function(_, val)
        if ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("offsetX", val)
        end
      end,
    },
    keybindOffsetXInput = {
      type = "input",
      name = "X",
      desc = "Type an exact X offset value (any integer)",
      dialogControl = "ArcUI_EditBox",
      order = 6.081,
      width = 0.35,
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return tostring(settings and settings.offsetX or -1)
      end,
      set = function(_, val)
        local num = tonumber(val)
        if num and ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("offsetX", math.floor(num))
        end
      end,
    },
    keybindOffsetY = {
      type = "range",
      name = "Y Offset",
      desc = "Vertical offset for keybind text",
      order = 6.09,
      width = 0.6,
      min = -50, max = 50, step = 1,
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return settings and settings.offsetY or -1
      end,
      set = function(_, val)
        if ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("offsetY", val)
        end
      end,
    },
    keybindOffsetYInput = {
      type = "input",
      name = "Y",
      desc = "Type an exact Y offset value (any integer)",
      dialogControl = "ArcUI_EditBox",
      order = 6.091,
      width = 0.35,
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return tostring(settings and settings.offsetY or -1)
      end,
      set = function(_, val)
        local num = tonumber(val)
        if num and ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("offsetY", math.floor(num))
        end
      end,
    },
    keybindStrata = {
      type = "select",
      name = "Strata",
      desc = "Frame strata for keybind text. 'Inherit' uses the icon's strata.",
      order = 6.10,
      width = 0.55,
      values = {
        [""] = "Inherit",
        ["BACKGROUND"] = "Background",
        ["LOW"] = "Low",
        ["MEDIUM"] = "Medium",
        ["HIGH"] = "High",
        ["DIALOG"] = "Dialog",
        ["TOOLTIP"] = "Tooltip",
      },
      sorting = { "", "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP" },
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return settings and settings.frameStrata or ""
      end,
      set = function(_, val)
        if ns.Keybinds and ns.Keybinds.SetSetting then
          ns.Keybinds.SetSetting("frameStrata", val)
        end
      end,
    },
    keybindLevel = {
      type = "input",
      name = "Level",
      desc = "Frame level for keybind text (higher = on top). 0 = inherit from icon.",
      dialogControl = "ArcUI_EditBox",
      order = 6.11,
      width = 0.4,
      hidden = function() return collapsedSections.keybinds end,
      disabled = function() return not (ns.Keybinds and ns.Keybinds.IsEnabled and ns.Keybinds.IsEnabled()) end,
      get = function()
        local settings = ns.Keybinds and ns.Keybinds.GetSettings and ns.Keybinds.GetSettings()
        return tostring(settings and settings.frameLevel or 0)
      end,
      set = function(_, val)
        if ns.Keybinds and ns.Keybinds.SetSetting then
          local num = tonumber(val)
          if num then
            ns.Keybinds.SetSetting("frameLevel", math.max(0, math.floor(num)))
          end
        end
      end,
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CATALOG
    -- ═══════════════════════════════════════════════════════════════════
    catalogHeader = {
      type = "header",
      name = function()
        local count = GetUnifiedSelectionCount()
        local totalCount = GetUnifiedIconCount()
        local filterName = ""
        if unifiedFilterMode == "cooldowns" then filterName = " |cff00ff00Cooldowns|r"
        elseif unifiedFilterMode == "auras" then filterName = " |cff00ccffAuras|r"
        elseif unifiedFilterMode == "freeposition" then filterName = " |cffff00ffFree Position|r"
        elseif unifiedFilterMode and unifiedFilterMode:match("^group:") then
          filterName = " |cff88ccff" .. unifiedFilterMode:sub(7) .. "|r"
        end
        
        if editAllUnifiedMode then
          return "Icon Catalog" .. filterName .. " |cff00ffff(Editing All: " .. totalCount .. ")|r"
        elseif count > 1 then
          return "Icon Catalog" .. filterName .. " |cff00ff00(Multi-Select: " .. count .. ")|r"
        end
        return "Icon Catalog" .. filterName .. " (" .. totalCount .. " icons)"
      end,
      order = 9,
    },
    editAllToggle = {
      type = "toggle",
      name = function() return editAllUnifiedMode and "|cff00ffffEdit All Visible|r" or "Edit All Visible" end,
      desc = "When enabled, changes apply to ALL visible icons",
      order = 9.1,
      width = 0.85,
      get = function() return editAllUnifiedMode end,
      set = function(_, v)
        editAllUnifiedMode = v
        -- CRITICAL: Force cache rebuild when toggling Edit All
        cachedUnifiedFilterMode = nil
        
        if v then
          -- Set type-specific edit-all based on filter
          -- For groups/freeposition that can contain mixed types, enable both
          if unifiedFilterMode == "auras" then
            editAllAurasMode = true
            editAllCooldownsMode = false
          elseif unifiedFilterMode == "cooldowns" then
            editAllCooldownsMode = true
            editAllAurasMode = false
          else
            -- Groups, freeposition, etc. can have both types
            editAllAurasMode = true
            editAllCooldownsMode = true
          end
          -- Clear individual selections when entering edit-all mode
          wipe(selectedAuraIcons)
          wipe(selectedCooldownIcons)
          selectedAuraIcon = nil
          selectedCooldownIcon = nil
        else
          editAllAurasMode = false
          editAllCooldownsMode = false
        end
        -- Refresh cooldown preview when edit all mode changes
        if ns.CDMEnhance and ns.CDMEnhance.RefreshCooldownPreview then
          ns.CDMEnhance.RefreshCooldownPreview()
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
    catalogHint = {
      type = "description",
      name = "|cff888888Click to select  •  Shift+Click multi-select  •  |cffaa55ff*|r = Customized|r",
      order = 9.5,
      fontSize = "small",
    },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CURRENTLY EDITING HEADER
    -- ═══════════════════════════════════════════════════════════════════
    currentlyEditingHeader = {
      type = "header",
      name = function()
        local count = GetUnifiedSelectionCount()
        if editAllUnifiedMode then
          return "|cff00ffffEditing All Visible Icons (" .. count .. ")|r"
        elseif count > 1 then
          return "|cff00ff00Editing " .. count .. " Icons|r"
        elseif selectedAuraIcon then
          local auras = ns.CDMEnhance and ns.CDMEnhance.GetAuraIcons() or {}
          local entry = auras[selectedAuraIcon]
          if entry then
            return "|cff00ccff[Aura]|r |cffffd700" .. (entry.name or "Unknown") .. "|r"
          end
        elseif selectedCooldownIcon then
          local cooldowns = ns.CDMEnhance and ns.CDMEnhance.GetCooldownIcons() or {}
          local entry = cooldowns[selectedCooldownIcon]
          if entry then
            return "|cff00ff00[Cooldown]|r |cffffd700" .. (entry.name or "Unknown") .. "|r"
          end
        end
        return ""
      end,
      order = 99,
      hidden = HideIfNoUnifiedSelection,
    },
    
    -- Unified Reset Button (resets all selected icons - both auras and cooldowns)
    unifiedResetBtn = {
      type = "execute",
      name = "|cffff6666Reset Selected Icon(s)|r",
      desc = "Remove ALL per-icon customizations for the selected icon(s), returning them to default/global settings",
      order = 99.5,
      width = 1.2,
      hidden = HideIfNoUnifiedSelection,
      confirm = true,
      confirmText = "Remove ALL per-icon customizations for the selected icon(s)? This cannot be undone.",
      func = function()
        -- Reset aura icons
        local auraIcons = GetAuraIconsToUpdate()
        for _, cdID in ipairs(auraIcons) do
          if ns.CDMEnhance and ns.CDMEnhance.ResetIconToDefaults then
            ns.CDMEnhance.ResetIconToDefaults(cdID)
          end
        end
        -- Reset cooldown icons
        local cooldownIcons = GetCooldownIconsToUpdate()
        for _, cdID in ipairs(cooldownIcons) do
          if ns.CDMEnhance and ns.CDMEnhance.ResetIconToDefaults then
            ns.CDMEnhance.ResetIconToDefaults(cdID)
          end
        end
        if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
          ns.CDMEnhance.InvalidateCache()
        end
        UpdateAura()
        UpdateCooldown()
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
    },
  }
  
  -- Add catalog icons
  for i = 1, 50 do
    args["catalogIcon" .. i] = CreateUnifiedCatalogIconEntry(i)
  end
  
  -- Copy AURA per-icon options (order 100-199) - they use HideIfNoAuraSelection
  if auraTable and auraTable.args then
    for key, opt in pairs(auraTable.args) do
      if not skipKeys[key] then
        args[key] = opt
      end
    end
  end
  
  -- Copy COOLDOWN per-icon options with "cd_" prefix (order 200-299) - they use HideIfNoCooldownSelection
  if cooldownTable and cooldownTable.args then
    for key, opt in pairs(cooldownTable.args) do
      if not skipKeys[key] then
        -- Deep copy the option and adjust order
        local newOpt = {}
        for k, v in pairs(opt) do
          newOpt[k] = v
        end
        -- Offset cooldown options to avoid order collision
        if newOpt.order then
          newOpt.order = newOpt.order + 100
        end
        args["cd_" .. key] = newOpt
      end
    end
  end
  
  -- Bottom controls
  args.bottomSpacer = {
    type = "header",
    name = "",
    order = 390,
  }
  args.resetAllPositions = {
    type = "execute",
    name = "Reset All Positions",
    desc = "Reset all icon positions to default CDM layout",
    order = 395,
    width = 1.0,
    confirm = true,
    confirmText = "Reset all icon positions to default?",
    func = function()
      if ns.CDMEnhance then
        if ns.CDMEnhance.ResetAllAuraPositions then ns.CDMEnhance.ResetAllAuraPositions() end
        if ns.CDMEnhance.ResetAllCooldownPositions then ns.CDMEnhance.ResetAllCooldownPositions() end
      end
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end,
  }
  args.resetAllOptions = {
    type = "execute",
    name = "Reset All Options",
    desc = "Reset all icon customizations to defaults",
    order = 395.5,
    width = 1.0,
    confirm = true,
    confirmText = "Reset all icon customization settings to defaults?",
    func = function()
      if ns.CDMEnhance and ns.CDMEnhance.ResetAllIconsToDefaults then
        ns.CDMEnhance.ResetAllIconsToDefaults("aura")
        ns.CDMEnhance.ResetAllIconsToDefaults("cooldown")
      end
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end,
  }
  args.deselectBtn = {
    type = "execute",
    name = "Deselect",
    order = 396,
    width = 0.7,
    hidden = HideIfNoUnifiedSelection,
    func = function()
      -- Reset all selections
      selectedAuraIcon = nil
      selectedCooldownIcon = nil
      wipe(selectedAuraIcons)
      wipe(selectedCooldownIcons)
      -- Also reset edit-all modes
      editAllUnifiedMode = false
      editAllAurasMode = false
      editAllCooldownsMode = false
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end,
  }
  
  return {
    type = "group",
    name = "CDM Icons",
    order = 2,
    args = args,
  }
end

-- ===================================================================
-- LEGACY FUNCTION (for backwards compatibility)
-- ===================================================================
function ns.GetCDMEnhanceOptionsTable()
  return ns.GetCDMCooldownIconsOptionsTable()
end

-- ===================================================================
-- PUBLIC API FOR RIGHT-CLICK ICON SELECTION
-- ===================================================================
ns.CDMEnhanceOptions = ns.CDMEnhanceOptions or {}

function ns.CDMEnhanceOptions.SelectIcon(cooldownID, isAura)
  -- Set the selected icon FIRST (before opening/navigating)
  if isAura then
    selectedAuraIcon = cooldownID
    selectedCooldownIcon = nil  -- Clear the other selection
    wipe(selectedAuraIcons)
    wipe(selectedCooldownIcons)
  else
    selectedCooldownIcon = cooldownID
    selectedAuraIcon = nil  -- Clear the other selection
    wipe(selectedAuraIcons)
    wipe(selectedCooldownIcons)
  end
  
  -- Reset edit-all modes when selecting a specific icon
  editAllUnifiedMode = false
  editAllAurasMode = false
  editAllCooldownsMode = false
  
  -- Auto-update filter to show the selected icon
  -- Check if icon is in a group or free positioned
  local filterToSet = nil
  
  if ns.CDMGroups then
    -- Check free icons first
    if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cooldownID] then
      filterToSet = "freeposition"
    else
      -- Check groups
      if ns.CDMGroups.groups then
        for groupName, group in pairs(ns.CDMGroups.groups) do
          if group.members and group.members[cooldownID] then
            filterToSet = "group:" .. groupName
            break
          end
        end
      end
    end
  end
  
  -- If not in group or free, use aura/cooldown filter based on type
  if not filterToSet then
    filterToSet = isAura and "auras" or "cooldowns"
  end
  
  -- Update the filter mode and invalidate cache
  unifiedFilterMode = filterToSet
  cachedUnifiedFilterMode = nil  -- Force cache rebuild
  
  local ACD = LibStub("AceConfigDialog-3.0", true)
  if not ACD then return end
  
  -- Check if panel is already open
  local panelWasOpen = ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
  
  if not panelWasOpen then
    -- Panel not open - open it first
    ACD:Open("ArcUI")
  end
  
  -- Navigate after a brief delay to ensure UI is ready
  -- This ensures we switch even if already on a different sub-panel
  C_Timer.After(0.05, function()
    -- Refresh first to update selection
    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    -- Navigate to: Icons (CDM) > CDM Icons
    -- The unified CDM Icons panel handles both auras and cooldowns
    ACD:SelectGroup("ArcUI", "icons", "cdmIcons")
  end)
end

-- Check if ArcUI options panel is currently open
function ns.CDMEnhanceOptions.IsOptionsOpen()
  local ACD = LibStub("AceConfigDialog-3.0", true)
  if ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] then
    return true
  end
  return false
end

-- Track last known state to detect changes
local lastOptionsOpenState = false

-- Get currently selected icons for preview text
function ns.CDMEnhanceOptions.GetSelectedIcon()
  return selectedAuraIcon, selectedCooldownIcon
end

-- Get ALL icons currently being edited (supports edit-all, multi-select, and single select)
-- Returns a table of cooldownIDs
function ns.CDMEnhanceOptions.GetAllIconsToUpdate()
  local icons = {}
  local seen = {}  -- Prevent duplicates
  
  -- Get aura icons
  local auraIcons = GetAuraIconsToUpdate()
  for _, cdID in ipairs(auraIcons) do
    if not seen[cdID] then
      seen[cdID] = true
      table.insert(icons, cdID)
    end
  end
  
  -- Get cooldown icons
  local cooldownIcons = GetCooldownIconsToUpdate()
  for _, cdID in ipairs(cooldownIcons) do
    if not seen[cdID] then
      seen[cdID] = true
      table.insert(icons, cdID)
    end
  end
  
  return icons
end

-- Check if we're in edit-all mode
function ns.CDMEnhanceOptions.IsEditAllMode()
  return editAllUnifiedMode or editAllAurasMode or editAllCooldownsMode
end

-- Glow preview toggle system
-- Tracks which icons have glow preview enabled (persistent until panel closes)
local glowPreviewActive = {}  -- cdID -> true/false

-- Set glow preview state for an icon
function ns.CDMEnhanceOptions.SetGlowPreview(cdID, enabled)
  glowPreviewActive[cdID] = enabled or nil
  -- Trigger update to show/hide glow
  if ns.CDMEnhance then
    if ns.CDMEnhance.InvalidateCache then ns.CDMEnhance.InvalidateCache() end
    if ns.CDMEnhance.UpdateIcon then ns.CDMEnhance.UpdateIcon(cdID) end
  end
end

-- Check if glow preview is active for an icon
function ns.CDMEnhanceOptions.IsGlowPreviewActive(cdID)
  return glowPreviewActive[cdID] == true
end

-- Clear all glow previews (called when options panel closes)
function ns.CDMEnhanceOptions.ClearAllGlowPreviews()
  -- Collect all cdIDs first (don't modify table during iteration)
  local cdIDs = {}
  for cdID in pairs(glowPreviewActive) do
    table.insert(cdIDs, cdID)
  end
  
  -- Clear the table BEFORE updating icons
  -- This ensures IsGlowPreviewActive returns false during UpdateIcon
  glowPreviewActive = {}
  
  -- Now update all icons to hide their glows
  if ns.CDMEnhance and ns.CDMEnhance.UpdateIcon then
    for _, cdID in ipairs(cdIDs) do
      ns.CDMEnhance.UpdateIcon(cdID)
    end
  end
end

-- Toggle glow preview for currently selected icons
function ns.CDMEnhanceOptions.ToggleGlowPreviewForSelection(isAura)
  local icons = isAura and GetAuraIconsToUpdate() or GetCooldownIconsToUpdate()
  if #icons == 0 then return false end
  
  -- Check current state - if ANY are active, turn all off; otherwise turn all on
  local anyActive = false
  for _, cdID in ipairs(icons) do
    if glowPreviewActive[cdID] then
      anyActive = true
      break
    end
  end
  
  local newState = not anyActive
  for _, cdID in ipairs(icons) do
    ns.CDMEnhanceOptions.SetGlowPreview(cdID, newState)
  end
  
  return newState
end

-- Clear glow preview for selected icons (unconditionally turn off, not toggle)
function ns.CDMEnhanceOptions.ClearGlowPreviewForSelection(isAura)
  local icons = isAura and GetAuraIconsToUpdate() or GetCooldownIconsToUpdate()
  for _, cdID in ipairs(icons) do
    if glowPreviewActive[cdID] then
      ns.CDMEnhanceOptions.SetGlowPreview(cdID, false)
    end
  end
end

-- Get preview state for display (checks if any selected icons have preview)
function ns.CDMEnhanceOptions.GetGlowPreviewState(isAura)
  local icons = isAura and GetAuraIconsToUpdate() or GetCooldownIconsToUpdate()
  if #icons == 0 then return false end
  
  for _, cdID in ipairs(icons) do
    if glowPreviewActive[cdID] then
      return true
    end
  end
  return false
end

-- Proc glow preview (separate from ready/active state glow)

-- Toggle glow preview for ALL icons of a type (for global defaults panel)
function ns.CDMEnhanceOptions.ToggleGlowPreviewForAllIcons(isAura)
  if not ns.CDMEnhance then return false end
  
  local iconData = isAura and ns.CDMEnhance.GetAuraIcons() or ns.CDMEnhance.GetCooldownIcons()
  if not iconData then return false end
  
  -- Collect all cdIDs
  local icons = {}
  for cdID, _ in pairs(iconData) do
    table.insert(icons, cdID)
  end
  
  if #icons == 0 then return false end
  
  -- Check current state - if ANY are active, turn all off; otherwise turn all on
  local anyActive = false
  for _, cdID in ipairs(icons) do
    if glowPreviewActive[cdID] then
      anyActive = true
      break
    end
  end
  
  local newState = not anyActive
  for _, cdID in ipairs(icons) do
    ns.CDMEnhanceOptions.SetGlowPreview(cdID, newState)
  end
  
  return newState
end

-- Clear glow preview for ALL icons of a type (unconditionally turn off, not toggle)
function ns.CDMEnhanceOptions.ClearGlowPreviewForAllIcons(isAura)
  if not ns.CDMEnhance then return end
  
  local iconData = isAura and ns.CDMEnhance.GetAuraIcons() or ns.CDMEnhance.GetCooldownIcons()
  if not iconData then return end
  
  for cdID, _ in pairs(iconData) do
    if glowPreviewActive[cdID] then
      ns.CDMEnhanceOptions.SetGlowPreview(cdID, false)
    end
  end
end

-- Get preview state for ALL icons of a type (for global defaults panel)
function ns.CDMEnhanceOptions.GetGlowPreviewStateForAllIcons(isAura)
  if not ns.CDMEnhance then return false end
  
  local iconData = isAura and ns.CDMEnhance.GetAuraIcons() or ns.CDMEnhance.GetCooldownIcons()
  if not iconData then return false end
  
  for cdID, _ in pairs(iconData) do
    if glowPreviewActive[cdID] then
      return true
    end
  end
  return false
end

-- Proc glow preview (separate from ready/active state glow)
local procGlowPreviewActive = {}  -- cdID -> true/false

-- Set proc glow preview state for an icon
function ns.CDMEnhanceOptions.SetProcGlowPreview(cdID, enabled)
  procGlowPreviewActive[cdID] = enabled or nil
  -- Show or hide proc glow via CDMEnhance
  if ns.CDMEnhance then
    if enabled then
      if ns.CDMEnhance.ShowProcGlowPreview then
        ns.CDMEnhance.ShowProcGlowPreview(cdID)
      end
    else
      if ns.CDMEnhance.HideProcGlowPreview then
        ns.CDMEnhance.HideProcGlowPreview(cdID)
      end
    end
  end
end

-- Check if proc glow preview is active for an icon
function ns.CDMEnhanceOptions.IsProcGlowPreviewActive(cdID)
  return procGlowPreviewActive[cdID] == true
end

-- Clear all proc glow previews
function ns.CDMEnhanceOptions.ClearAllProcGlowPreviews()
  -- Collect all cdIDs first (don't modify table during iteration)
  local cdIDs = {}
  for cdID in pairs(procGlowPreviewActive) do
    table.insert(cdIDs, cdID)
  end
  
  -- Clear the table BEFORE hiding glows
  procGlowPreviewActive = {}
  
  -- Now hide all proc glows
  if ns.CDMEnhance and ns.CDMEnhance.HideProcGlowPreview then
    for _, cdID in ipairs(cdIDs) do
      ns.CDMEnhance.HideProcGlowPreview(cdID)
    end
  end
end

-- Helper: Get all icons for proc glow (shared setting, includes both types in mixed mode)
local function GetAllIconsForProcGlow(isAura)
  local icons = {}
  
  -- Get the primary type icons
  local primaryIcons = isAura and GetAuraIconsToUpdate() or GetCooldownIconsToUpdate()
  for _, cdID in ipairs(primaryIcons) do
    table.insert(icons, cdID)
  end
  
  -- In mixed mode, also get the other type
  local isMixedMode = (IsEditingMixedTypes and IsEditingMixedTypes()) or
                      (editAllUnifiedMode and unifiedFilterMode ~= "auras" and unifiedFilterMode ~= "cooldowns")
  if isMixedMode then
    local otherIcons = isAura and GetCooldownIconsToUpdate() or GetAuraIconsToUpdate()
    for _, cdID in ipairs(otherIcons) do
      table.insert(icons, cdID)
    end
  end
  
  return icons
end

-- Toggle proc glow preview for currently selected icons
-- In mixed mode, toggles both auras and cooldowns since proc glow is a shared setting
function ns.CDMEnhanceOptions.ToggleProcGlowPreviewForSelection(isAura)
  local icons = GetAllIconsForProcGlow(isAura)
  if #icons == 0 then return false end
  
  -- Check current state - if ANY are active, turn all off; otherwise turn all on
  local anyActive = false
  for _, cdID in ipairs(icons) do
    if procGlowPreviewActive[cdID] then
      anyActive = true
      break
    end
  end
  
  local newState = not anyActive
  for _, cdID in ipairs(icons) do
    ns.CDMEnhanceOptions.SetProcGlowPreview(cdID, newState)
  end
  
  return newState
end

-- Get proc glow preview state for display
-- In mixed mode, checks both auras and cooldowns since proc glow is a shared setting
function ns.CDMEnhanceOptions.GetProcGlowPreviewState(isAura)
  local icons = GetAllIconsForProcGlow(isAura)
  if #icons == 0 then return false end
  
  for _, cdID in ipairs(icons) do
    if procGlowPreviewActive[cdID] then
      return true
    end
  end
  return false
end

-- Called periodically to check if options panel state changed
local function CheckOptionsStateChange()
  local isOpen = ns.CDMEnhanceOptions.IsOptionsOpen()
  if isOpen ~= lastOptionsOpenState then
    lastOptionsOpenState = isOpen
    -- Refresh overlay mouse states when options panel opens/closes
    if ns.CDMEnhance and ns.CDMEnhance.RefreshOverlayMouseState then
      ns.CDMEnhance.RefreshOverlayMouseState()
    end
    
    -- When options panel opens, trigger a CDM scan to ensure all icons are available
    if isOpen then
      -- Reset all per-icon collapsible sections to collapsed state
      collapsedSections.globalOptions = true
      collapsedSections.iconAppearance = true
      collapsedSections.position = true
      collapsedSections.activeState = true
      collapsedSections.inactiveState = true
      collapsedSections.readyState = true
      collapsedSections.cooldownState = true
      collapsedSections.auraActiveState = true
      collapsedSections.rangeIndicator = true
      collapsedSections.procGlow = true
      collapsedSections.alertEvents = true
      collapsedSections.border = true
      collapsedSections.cooldownSwipe = true
      collapsedSections.chargeText = true
      collapsedSections.cooldownText = true
      
      -- Reset global aura defaults sections to collapsed state
      collapsedGlobalAuraSections.iconAppearance = true
      collapsedGlobalAuraSections.activeState = true
      collapsedGlobalAuraSections.inactiveState = true
      collapsedGlobalAuraSections.cooldownSwipe = true
      collapsedGlobalAuraSections.chargeText = true
      collapsedGlobalAuraSections.cooldownText = true
      collapsedGlobalAuraSections.procGlow = true
      collapsedGlobalAuraSections.rangeIndicator = true
      collapsedGlobalAuraSections.border = true
      
      -- Reset global cooldown defaults sections to collapsed state
      collapsedGlobalCooldownSections.iconAppearance = true
      collapsedGlobalCooldownSections.readyState = true
      collapsedGlobalCooldownSections.inactiveState = true
      collapsedGlobalCooldownSections.auraActiveState = true
      collapsedGlobalCooldownSections.cooldownSwipe = true
      collapsedGlobalCooldownSections.chargeText = true
      collapsedGlobalCooldownSections.cooldownText = true
      collapsedGlobalCooldownSections.procGlow = true
      collapsedGlobalCooldownSections.rangeIndicator = true
      collapsedGlobalCooldownSections.border = true
      
      if ns.CDMEnhance and ns.CDMEnhance.ScanCDM then
        ns.CDMEnhance.ScanCDM()
      end
      -- Also invalidate cache to pick up any new icons
      cachedUnifiedFilterMode = nil
    end
    
    -- When options panel closes, disable all drag options and clear glow previews
    if not isOpen then
      if ns.CDMEnhance and ns.CDMEnhance.DisableAllDrags then
        ns.CDMEnhance.DisableAllDrags()
      end
      -- Clear all glow previews (both ready/active state and proc glows)
      if ns.CDMEnhanceOptions.ClearAllGlowPreviews then
        ns.CDMEnhanceOptions.ClearAllGlowPreviews()
      end
      if ns.CDMEnhanceOptions.ClearAllProcGlowPreviews then
        ns.CDMEnhanceOptions.ClearAllProcGlowPreviews()
      end
      -- Turn off cooldown animation preview
      if ns.CDMEnhance and ns.CDMEnhance.SetCooldownPreviewMode then
        ns.CDMEnhance.SetCooldownPreviewMode(false)
      end
    end
  end
end

-- Invalidate the unified icon cache (call when icons are added/removed from groups)
function ns.CDMEnhanceOptions.InvalidateCache()
  cachedUnifiedFilterMode = nil
end

-- Get current edit mode state (for debugging)
function ns.CDMEnhanceOptions.GetEditModeState()
  return {
    editAllUnifiedMode = editAllUnifiedMode,
    editAllAurasMode = editAllAurasMode,
    editAllCooldownsMode = editAllCooldownsMode,
    unifiedFilterMode = unifiedFilterMode,
    cachedUnifiedFilterMode = cachedUnifiedFilterMode,
    cachedIconCount = #cachedUnifiedIcons,
    selectedAuraIcon = selectedAuraIcon,
    selectedCooldownIcon = selectedCooldownIcon,
    selectedAuraCount = next(selectedAuraIcons) and 1 or 0,
    selectedCooldownCount = next(selectedCooldownIcons) and 1 or 0,
  }
end

-- Start a ticker to monitor options panel state
C_Timer.NewTicker(0.5, CheckOptionsStateChange)