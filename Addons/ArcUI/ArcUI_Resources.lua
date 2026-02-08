-- ===================================================================
-- ArcUI_Resources.lua
-- Primary AND Secondary Resource tracking with threshold color layers
-- Uses multi-bar overlay technique for secret-value-safe color changes
-- v2.6.0: Added secondary resource support (Combo Points, Runes, etc.)
-- ===================================================================

local ADDON, ns = ...
ns.Resources = ns.Resources or {}

-- Track if delete buttons should be visible (set when options panel opens)
local deleteButtonsVisible = false

-- Forward declaration for delete confirmation (defined later in file)
local ShowResourceDeleteConfirmation

-- ===================================================================
-- HELPER: CHECK IF OPTIONS PANEL IS OPEN
-- Used to show bars hidden by talent conditions when editing
-- ===================================================================
local function IsOptionsOpen()
  -- Check namespace flag first (set explicitly by Options.lua)
  if ns._arcUIOptionsOpen then
    return true
  end
  -- Fallback: Check AceConfigDialog directly
  local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
  if AceConfigDialog and AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["ArcUI"] then
    return true
  end
  return false
end

-- ===================================================================
-- HELPER: CHECK TALENT CONDITIONS
-- Returns true if conditions are met (or no conditions set)
-- ===================================================================
local function AreTalentConditionsMet(cfg)
  if not cfg or not cfg.behavior then return true end
  if not cfg.behavior.talentConditions or #cfg.behavior.talentConditions == 0 then return true end
  
  if ns.TalentPicker and ns.TalentPicker.CheckTalentConditions then
    local matchMode = cfg.behavior.talentMatchMode or "all"
    return ns.TalentPicker.CheckTalentConditions(cfg.behavior.talentConditions, matchMode)
  end
  
  return true
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
-- HELPER: GET ORIENTATION FROM CONFIG
-- Config uses lowercase "horizontal"/"vertical", WoW API uses uppercase
-- ===================================================================
local function GetBarOrientation(cfg)
  local orient = cfg and cfg.display and cfg.display.barOrientation or "horizontal"
  if orient == "vertical" then
    return "VERTICAL"
  end
  return "HORIZONTAL"
end

local function GetBarReverseFill(cfg)
  return cfg and cfg.display and cfg.display.barReverseFill or false
end

-- ===================================================================
-- HELPER: CONFIGURE STATUSBAR FOR CRISP RENDERING
-- Prevents pixel snapping artifacts
-- ===================================================================
local function ConfigureStatusBar(bar)
  if not bar then return end
  -- Note: SetRotatesTexture is set later when orientation is known
  local tex = bar:GetStatusBarTexture()
  if tex then
    tex:SetSnapToPixelGrid(false)
    tex:SetTexelSnappingBias(0)
  end
end

-- ===================================================================
-- POWER TYPE DEFINITIONS (Primary Resources)
-- ===================================================================
ns.Resources.PowerTypes = {
  { id = 0,  name = "Mana",         token = "MANA",         color = {r=0, g=0.5, b=1} },
  { id = 1,  name = "Rage",         token = "RAGE",         color = {r=1, g=0, b=0} },
  { id = 2,  name = "Focus",        token = "FOCUS",        color = {r=1, g=0.5, b=0.25} },
  { id = 3,  name = "Energy",       token = "ENERGY",       color = {r=1, g=1, b=0} },
  { id = 6,  name = "Runic Power",  token = "RUNIC_POWER",  color = {r=0, g=0.82, b=1} },
  { id = 8,  name = "Astral Power", token = "LUNAR_POWER",  color = {r=0.3, g=0.52, b=0.9} },
  { id = 11, name = "Maelstrom",    token = "MAELSTROM",    color = {r=0, g=0.5, b=1} },
  { id = 13, name = "Insanity",     token = "INSANITY",     color = {r=0.4, g=0, b=0.8} },
  { id = 17, name = "Fury",         token = "FURY",         color = {r=0.78, g=0.26, b=0.99} },
  { id = 18, name = "Pain",         token = "PAIN",         color = {r=1, g=0.61, b=0} },
}

-- ===================================================================
-- SECONDARY RESOURCE TYPE DEFINITIONS
-- These are discrete/segmented resources separate from primary power
-- ===================================================================
ns.Resources.SecondaryTypes = {
  { id = "comboPoints",   name = "Combo Points",   powerType = Enum.PowerType.ComboPoints,   color = {r=1, g=0.96, b=0.41}, maxDefault = 5 },
  { id = "holyPower",     name = "Holy Power",     powerType = Enum.PowerType.HolyPower,     color = {r=0.95, g=0.9, b=0.6}, maxDefault = 5 },
  { id = "chi",           name = "Chi",            powerType = Enum.PowerType.Chi,           color = {r=0.71, g=1, b=0.92}, maxDefault = 5 },
  { id = "runes",         name = "Runes",          powerType = Enum.PowerType.Runes,         color = {r=0.5, g=0.5, b=0.5}, maxDefault = 6 },
  { id = "soulShards",    name = "Soul Shards",    powerType = Enum.PowerType.SoulShards,    color = {r=0.58, g=0.51, b=0.79}, maxDefault = 5 },
  { id = "essence",       name = "Essence",        powerType = Enum.PowerType.Essence,       color = {r=0, g=0.8, b=0.8}, maxDefault = 5 },
  { id = "arcaneCharges", name = "Arcane Charges", powerType = Enum.PowerType.ArcaneCharges, color = {r=0.1, g=0.1, b=0.98}, maxDefault = 4 },
  { id = "stagger",       name = "Stagger",        powerType = nil,                          color = {r=0.52, g=1, b=0.52}, maxDefault = 100 },  -- Special: uses UnitStagger
  { id = "soulFragments", name = "Soul Fragments", powerType = nil,                          color = {r=0.64, g=0.22, b=0.93}, maxDefault = 5 },   -- Special: DH Vengeance
}

-- Lookup table for quick access
ns.Resources.SecondaryTypesLookup = {}
for _, st in ipairs(ns.Resources.SecondaryTypes) do
  ns.Resources.SecondaryTypesLookup[st.id] = st
end

-- Secondary resources that show discrete ticks (1 per point)
ns.Resources.TickedSecondaryTypes = {
  comboPoints = true,
  holyPower = true,
  chi = true,
  runes = true,
  soulShards = true,
  essence = true,
  arcaneCharges = true,
  soulFragments = true,
}

-- Secondary resources that have independent segments (like runes)
ns.Resources.FragmentedSecondaryTypes = {
  runes = true,
  essence = true,
}

-- ===================================================================
-- FRAME STORAGE (per resource bar)
-- ===================================================================
local resourceFrames = {}  -- [barNumber] = {mainFrame, textFrame, layers = {}}

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER: Rotate StatusBar Texture for Vertical Bars
-- ===================================================================
-- HELPER: APPLY FILL TEXTURE SCALE
-- ===================================================================
local function ApplyFillTextureScale(statusBar, scale)
  if not statusBar then return end
  scale = scale or 1.0
  
  -- Get the StatusBar texture and apply scaling
  local texture = statusBar:GetStatusBarTexture()
  if texture then
    -- Reset to defaults first
    texture:SetTexCoord(0, 1, 0, 1)
    
    -- For StatusBars, we control tiling through HorizTile
    -- Scale < 1 = more repetitions (tiled), Scale > 1 = stretched
    if scale < 1 then
      -- Tiled mode - texture repeats
      texture:SetHorizTile(true)
      texture:SetVertTile(false)
    else
      -- Stretched mode - texture stretches
      texture:SetHorizTile(false)
      texture:SetVertTile(false)
      -- Adjust tex coords to stretch - smaller right value = more stretch visible
      local right = 1.0 / scale
      texture:SetTexCoord(0, right, 0, 1)
    end
  end
end

-- ===================================================================
-- GET SECONDARY RESOURCE MAX VALUE
-- ===================================================================
function ns.Resources.GetSecondaryMaxValue(secondaryType)
  if not secondaryType then return 5 end
  
  local typeInfo = ns.Resources.SecondaryTypesLookup[secondaryType]
  if not typeInfo then return 5 end
  
  -- Special cases
  if secondaryType == "stagger" then
    -- Stagger max is player's max health
    return UnitHealthMax("player") or 100
  elseif secondaryType == "soulFragments" then
    -- Soul Fragments max is typically 5
    if DemonHunterSoulFragmentsBar and DemonHunterSoulFragmentsBar:IsShown() then
      local _, max = DemonHunterSoulFragmentsBar:GetMinMaxValues()
      if max and max > 0 then return max end
    end
    return 5
  elseif secondaryType == "soulShards" then
    -- Soul shards can be fractional for Destruction
    local spec = GetSpecialization()
    local specID = spec and GetSpecializationInfo(spec)
    if specID == 267 then  -- Destruction
      -- Return 50 for fractional display (5 shards * 10)
      return UnitPowerMax("player", Enum.PowerType.SoulShards, true) or 50
    end
    return UnitPowerMax("player", Enum.PowerType.SoulShards) or 5
  elseif typeInfo.powerType then
    return UnitPowerMax("player", typeInfo.powerType) or typeInfo.maxDefault
  end
  
  return typeInfo.maxDefault or 5
end

-- ===================================================================
-- GET SECONDARY RESOURCE VALUE
-- Returns: maxValue, currentValue, displayValue, displayFormat
-- displayFormat: "number" (integer), "decimal" (fractional), "custom"
-- ===================================================================
function ns.Resources.GetSecondaryResourceValue(secondaryType)
  if not secondaryType then return nil, nil, nil, nil end
  
  local typeInfo = ns.Resources.SecondaryTypesLookup[secondaryType]
  if not typeInfo then return nil, nil, nil, nil end
  
  -- ═══════════════════════════════════════════════════════════════
  -- STAGGER (Brewmaster Monk)
  -- Uses UnitStagger, max is player's max health
  -- ═══════════════════════════════════════════════════════════════
  if secondaryType == "stagger" then
    local stagger = UnitStagger("player") or 0
    local maxHealth = UnitHealthMax("player") or 1
    return maxHealth, stagger, stagger, "number"
  end
  
  -- ═══════════════════════════════════════════════════════════════
  -- SOUL FRAGMENTS (Vengeance Demon Hunter)
  -- Hacks the DemonHunterSoulFragmentsBar (secret values in combat)
  -- ═══════════════════════════════════════════════════════════════
  if secondaryType == "soulFragments" then
    -- The hack needs the PlayerFrame to be shown
    if not PlayerFrame or not PlayerFrame:IsShown() then 
      return nil, nil, nil, nil 
    end
    
    if not DemonHunterSoulFragmentsBar or not DemonHunterSoulFragmentsBar:IsShown() then
      return nil, nil, nil, nil
    end
    
    local current = DemonHunterSoulFragmentsBar:GetValue()
    local _, max = DemonHunterSoulFragmentsBar:GetMinMaxValues()
    
    if not max or max <= 0 then return nil, nil, nil, nil end
    
    return max, current, current, "number"
  end
  
  -- ═══════════════════════════════════════════════════════════════
  -- RUNES (Death Knight)
  -- Count ready runes via GetRuneCooldown
  -- ═══════════════════════════════════════════════════════════════
  if secondaryType == "runes" then
    local max = UnitPowerMax("player", Enum.PowerType.Runes) or 6
    if max <= 0 then return nil, nil, nil, nil end
    
    local readyRunes = 0
    for i = 1, max do
      local _, _, runeReady = GetRuneCooldown(i)
      if runeReady then
        readyRunes = readyRunes + 1
      end
    end
    
    return max, readyRunes, readyRunes, "number"
  end
  
  -- ═══════════════════════════════════════════════════════════════
  -- SOUL SHARDS (Warlock)
  -- Destruction spec uses fractional shards (10ths)
  -- ═══════════════════════════════════════════════════════════════
  if secondaryType == "soulShards" then
    local currentDisplay = UnitPower("player", Enum.PowerType.SoulShards)
    local current = UnitPower("player", Enum.PowerType.SoulShards, true)  -- True for fractional
    local max = UnitPowerMax("player", Enum.PowerType.SoulShards, true)
    
    if not max or max <= 0 then return nil, nil, nil, nil end
    
    -- Check if Destruction spec (uses fractional shards)
    local spec = GetSpecialization()
    local specID = spec and GetSpecializationInfo(spec)
    
    if specID == 267 then  -- Destruction
      -- Display as decimal (e.g., 3.5 shards)
      return max, current, current / 10, "decimal"
    end
    
    -- Affliction/Demonology use whole shards
    return UnitPowerMax("player", Enum.PowerType.SoulShards) or 5, currentDisplay, currentDisplay, "number"
  end
  
  -- ═══════════════════════════════════════════════════════════════
  -- REGULAR SECONDARY RESOURCES
  -- ComboPoints, HolyPower, Chi, Essence, ArcaneCharges
  -- ═══════════════════════════════════════════════════════════════
  if typeInfo.powerType then
    local current = UnitPower("player", typeInfo.powerType)
    local max = UnitPowerMax("player", typeInfo.powerType)
    
    if not max or max <= 0 then return nil, nil, nil, nil end
    
    return max, current, current, "number"
  end
  
  return nil, nil, nil, nil
end

-- ===================================================================
-- GET SECONDARY RESOURCE COLOR
-- ===================================================================
function ns.Resources.GetSecondaryResourceColor(secondaryType)
  if not secondaryType then return {r=1, g=1, b=1} end
  
  local typeInfo = ns.Resources.SecondaryTypesLookup[secondaryType]
  if typeInfo and typeInfo.color then
    return typeInfo.color
  end
  
  return {r=1, g=1, b=1}
end

-- ===================================================================
-- GET RUNE COOLDOWN DETAILS (Per-rune cooldown data)
-- Returns: table of { start, duration, ready, fillPercent } for each rune
-- ===================================================================
function ns.Resources.GetRuneCooldownDetails()
  local max = UnitPowerMax("player", Enum.PowerType.Runes) or 6
  if max <= 0 then return nil end
  
  local runeData = {}
  local now = GetTime()
  
  for i = 1, max do
    local start, duration, runeReady = GetRuneCooldown(i)
    
    local fillPercent = 1  -- Default to full
    if not runeReady and start and duration and duration > 0 then
      -- Calculate progress
      local elapsed = now - start
      fillPercent = math.min(1, math.max(0, elapsed / duration))
    end
    
    runeData[i] = {
      start = start or 0,
      duration = duration or 0,
      ready = runeReady,
      fillPercent = fillPercent
    }
  end
  
  return runeData, max
end

-- ===================================================================
-- GET ESSENCE COOLDOWN DETAILS (Per-essence charge data for Evoker)
-- Returns: table of { ready, fillPercent } for each essence
-- ===================================================================
function ns.Resources.GetEssenceCooldownDetails()
  local max = UnitPowerMax("player", Enum.PowerType.Essence) or 5
  if max <= 0 then return nil end
  
  local current = UnitPower("player", Enum.PowerType.Essence)
  local essenceData = {}
  local now = GetTime()
  
  -- Get charge info for the next essence
  local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(GetSpellInfo(Enum.PowerType.Essence))
  
  -- If GetSpellCharges doesn't work, fall back to UnitPower
  if not charges then
    charges = current
    chargeDuration = 0
  end
  
  for i = 1, max do
    if i <= current then
      -- Fully charged
      essenceData[i] = {
        ready = true,
        fillPercent = 1
      }
    elseif i == current + 1 and chargeStart and chargeDuration and chargeDuration > 0 then
      -- Currently charging
      local elapsed = now - chargeStart
      local fillPercent = math.min(1, math.max(0, elapsed / chargeDuration))
      essenceData[i] = {
        ready = false,
        fillPercent = fillPercent
      }
    else
      -- Not yet charging
      essenceData[i] = {
        ready = false,
        fillPercent = 0
      }
    end
  end
  
  return essenceData, max
end

-- ===================================================================
-- DETECT AVAILABLE SECONDARY RESOURCE FOR CURRENT CLASS/SPEC
-- Returns: secondaryType string or nil
-- ===================================================================
function ns.Resources.DetectSecondaryResource()
  local _, playerClass = UnitClass("player")
  local spec = GetSpecialization()
  local specID = spec and GetSpecializationInfo(spec)
  
  local classResources = {
    ["DEATHKNIGHT"] = "runes",
    ["EVOKER"] = "essence",
    ["PALADIN"] = "holyPower",
    ["ROGUE"] = "comboPoints",
    ["WARLOCK"] = "soulShards",
  }
  
  -- Spec-specific resources
  local specResources = {
    -- Demon Hunter
    [577] = nil,           -- Havoc - no secondary shown here
    [581] = "soulFragments", -- Vengeance
    
    -- Druid
    [102] = nil,           -- Balance
    [103] = "comboPoints", -- Feral
    [104] = nil,           -- Guardian
    [105] = nil,           -- Restoration
    
    -- Mage
    [62] = "arcaneCharges", -- Arcane
    [63] = nil,            -- Fire
    [64] = nil,            -- Frost
    
    -- Monk
    [268] = "stagger",     -- Brewmaster
    [270] = nil,           -- Mistweaver
    [269] = "chi",         -- Windwalker
  }
  
  -- Check spec-specific first
  if specID and specResources[specID] then
    return specResources[specID]
  end
  
  -- Fall back to class-wide
  return classResources[playerClass]
end

-- ===================================================================
-- COLORCURVE SYSTEM FOR RESOURCE BARS
-- Uses WoW 12.0's ColorCurve API for secret-value-safe color thresholds
-- Much simpler than the multi-stacked bar approach!
-- ===================================================================

-- Cache for max power values (needed for numeric threshold mode)
local cachedMaxPower = {}  -- [powerType] = maxValue

-- Cache for ColorCurves
local resourceColorCurves = {}  -- [barNumber] = { curve, settingsHash }

-- Default threshold colors
local RESOURCE_THRESHOLD_DEFAULT_COLORS = {
  [2] = {r = 1, g = 1, b = 0, a = 1},     -- Yellow
  [3] = {r = 1, g = 0.5, b = 0, a = 1},   -- Orange
  [4] = {r = 1, g = 0, b = 0, a = 1},     -- Red
  [5] = {r = 0.5, g = 0, b = 0.5, a = 1}, -- Purple
}

local RESOURCE_THRESHOLD_DEFAULT_VALUES = {
  [2] = 75,  -- 75%
  [3] = 50,  -- 50%
  [4] = 25,  -- 25%
  [5] = 10,  -- 10%
}

-- Cache max power when non-secret (out of combat)
local function CacheMaxPowerValue(powerType)
  if not powerType or powerType < 0 then return end
  
  local max = UnitPowerMax("player", powerType)
  if not max then return end
  
  -- Check if it's secret
  if issecretvalue and issecretvalue(max) then
    return  -- Can't cache secret value
  end
  
  if max and max > 0 then
    cachedMaxPower[powerType] = max
  end
end

-- Get cached max power (for numeric threshold conversion)
local function GetCachedMaxPower(powerType)
  return cachedMaxPower[powerType]
end

-- Safe color extraction: handles both {r=, g=, b=} tables and indexed {[1]=r, [2]=g, [3]=b} arrays
local function SafeColorRGBA(color, defaultR, defaultG, defaultB, defaultA)
  if not color then return defaultR or 1, defaultG or 1, defaultB or 1, defaultA or 1 end
  local r = color.r or color[1] or defaultR or 1
  local g = color.g or color[2] or defaultG or 1
  local b = color.b or color[3] or defaultB or 1
  local a = color.a or color[4] or defaultA or 1
  return r, g, b, a
end

-- Hash function for cache invalidation
local function GetResourceThresholdHash(cfg, baseColor)
  local parts = {}
  local bcR, bcG, bcB = SafeColorRGBA(baseColor, 0, 0.8, 1, 1)
  table.insert(parts, string.format("bc:%.2f,%.2f,%.2f", bcR, bcG, bcB))
  
  for i = 2, 5 do
    local enabled = cfg["colorCurveThreshold" .. i .. "Enabled"]
    local value = cfg["colorCurveThreshold" .. i .. "Value"] or RESOURCE_THRESHOLD_DEFAULT_VALUES[i]
    local color = cfg["colorCurveThreshold" .. i .. "Color"] or RESOURCE_THRESHOLD_DEFAULT_COLORS[i]
    if enabled then
      local cR, cG, cB = SafeColorRGBA(color, 1, 1, 1, 1)
      table.insert(parts, string.format("t%d:%d,%.2f,%.2f,%.2f", i, value, cR, cG, cB))
    end
  end
  
  table.insert(parts, cfg.colorCurveThresholdAsPercent and "pct" or "num")
  table.insert(parts, tostring(cfg.colorCurveMaxValue or 100))
  return table.concat(parts, "|")
end

-- Create or get cached ColorCurve for resource bar
-- NOTE: For resources, thresholds work OPPOSITE to cooldowns:
-- - Cooldowns: low % = urgent (about to be ready)
-- - Resources: low % = urgent (almost empty/out of resource)
local function GetResourceColorCurve(barNumber, barConfig, powerType)
  if not barConfig or not barConfig.display then return nil end
  
  local cfg = barConfig.display
  if not cfg.colorCurveEnabled then return nil end
  
  -- Check if ColorCurve API exists (WoW 12.0+)
  if not C_CurveUtil or not C_CurveUtil.CreateColorCurve then
    return nil
  end
  
  -- Get base bar color (used above all thresholds - "healthy" color)
  local baseColor = cfg.barColor or {r = 0, g = 0.8, b = 1, a = 1}
  
  -- Check if we need to rebuild the curve
  local currentHash = GetResourceThresholdHash(cfg, baseColor)
  local cached = resourceColorCurves[barNumber]
  
  if cached and cached.settingsHash == currentHash then
    return cached.curve
  end
  
  -- Build threshold points from UI settings
  local thresholds = {}
  
  for i = 2, 5 do
    local enabled = cfg["colorCurveThreshold" .. i .. "Enabled"]
    local value = cfg["colorCurveThreshold" .. i .. "Value"] or RESOURCE_THRESHOLD_DEFAULT_VALUES[i]
    local color = cfg["colorCurveThreshold" .. i .. "Color"] or RESOURCE_THRESHOLD_DEFAULT_COLORS[i]
    
    if enabled then
      table.insert(thresholds, { value = value, color = color })
    end
  end
  
  -- If no thresholds enabled, return nil (use base color only)
  if #thresholds == 0 then
    resourceColorCurves[barNumber] = nil
    return nil
  end
  
  -- Sort thresholds by value ASCENDING (lowest % first)
  -- e.g., [{10%, Red}, {25%, Orange}, {50%, Yellow}]
  -- At 0% = most urgent color, at 100% = base color
  table.sort(thresholds, function(a, b) return a.value < b.value end)
  
  -- Create the ColorCurve
  local curve = C_CurveUtil.CreateColorCurve()
  
  -- Mode settings
  local asPercent = cfg.colorCurveThresholdAsPercent ~= false  -- Default true for resources
  local maxValue = cfg.colorCurveMaxValue or 100
  
  -- For numeric mode, try to get actual max power
  if not asPercent and powerType then
    local cachedMax = GetCachedMaxPower(powerType)
    if cachedMax and cachedMax > 0 then
      maxValue = cachedMax
    end
  end
  
  local EPSILON = 0.0001
  
  -- Build curve: 0% = empty (urgent), 100% = full (healthy)
  -- We want: low % = threshold colors, high % = base color
  --
  -- Example: thresholds = [{10%, Red}, {25%, Orange}, {50%, Yellow}], base = Green
  -- 0% to 10%: Red
  -- 10% to 25%: Orange
  -- 25% to 50%: Yellow
  -- 50% to 100%: Green (base)
  
  -- Start at 0% with the lowest (most urgent) threshold color
  local lowestThreshold = thresholds[1]
  local lR, lG, lB, lA = SafeColorRGBA(lowestThreshold.color)
  curve:AddPoint(0.0, CreateColor(lR, lG, lB, lA))
  
  -- Add transition points for each threshold (going from lowest to highest)
  for i = 1, #thresholds do
    local t = thresholds[i]
    local pct
    if asPercent then
      pct = t.value / 100
    else
      pct = t.value / maxValue
    end
    pct = math.max(0, math.min(1, pct))
    
    -- Determine next color (above this threshold / more resource)
    local nextColor
    if i == #thresholds then
      -- Highest threshold - above this use base color
      nextColor = baseColor
    else
      -- Use next threshold's color
      nextColor = thresholds[i + 1].color
    end
    
    local currentColor = t.color
    
    -- Add point just before threshold (current color)
    if pct > EPSILON then
      local cR, cG, cB, cA = SafeColorRGBA(currentColor)
      curve:AddPoint(pct - EPSILON, CreateColor(cR, cG, cB, cA))
    end
    
    -- Add point at threshold (next color begins)
    local nR, nG, nB, nA = SafeColorRGBA(nextColor)
    curve:AddPoint(pct, CreateColor(nR, nG, nB, nA))
  end
  
  -- End with base color at 100%
  local bR, bG, bB, bA = SafeColorRGBA(baseColor)
  curve:AddPoint(1.0, CreateColor(bR, bG, bB, bA))
  
  -- Cache
  resourceColorCurves[barNumber] = { curve = curve, settingsHash = currentHash }
  return curve
end

-- Clear cached curve (called when settings change)
function ns.Resources.ClearResourceColorCurve(barNumber)
  resourceColorCurves[barNumber] = nil
end

function ns.Resources.ClearAllResourceColorCurves()
  wipe(resourceColorCurves)
end

-- Cache max power for all common power types (call on PLAYER_ENTERING_WORLD, etc.)
function ns.Resources.CacheAllMaxPowerValues()
  for _, pt in ipairs(ns.Resources.PowerTypes) do
    CacheMaxPowerValue(pt.id)
  end
end

-- ===================================================================
-- CREATE RESOURCE BAR FRAME
-- ===================================================================
local function CreateResourceBarFrame(barNumber)
  local frame = CreateFrame("Frame", "ArcUIResourceFrame" .. barNumber, UIParent)
  frame:SetSize(250, 25)
  frame:SetPoint("CENTER", 0, -100 - ((barNumber - 1) * 35))
  frame:SetMovable(true)
  frame:EnableMouse(false)
  frame:SetClampedToScreen(true)
  
  -- Background
  frame.bg = frame:CreateTexture(nil, "BACKGROUND")
  frame.bg:SetAllPoints()
  frame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
  frame.bg:SetSnapToPixelGrid(false)
  frame.bg:SetTexelSnappingBias(0)
  
  -- Border textures created later on borderOverlay frame
  
  -- Threshold layers container (bars stacked on top of each other)
  -- These create the "color change" illusion with secret values!
  frame.layers = {}
  
  -- Create up to 5 threshold layers (bottom to top)
  for i = 1, 5 do
    local layer = CreateFrame("StatusBar", nil, frame)
    layer:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    layer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    layer:SetMinMaxValues(0, 100)
    layer:SetValue(0)
    layer:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    layer:SetStatusBarColor(1, 1, 1, 1)
    layer:SetFrameLevel(frame:GetFrameLevel() + i)  -- Stack in order
    ConfigureStatusBar(layer)  -- Enable rotation and prevent pixel snapping
    layer:Hide()
    frame.layers[i] = layer
  end
  
  -- Tick marks overlay (must be above all granular bars which go up to +105)
  frame.tickOverlay = CreateFrame("Frame", nil, frame)
  frame.tickOverlay:SetAllPoints(frame)
  frame.tickOverlay:SetFrameLevel(frame:GetFrameLevel() + 150)
  
  frame.tickMarks = {}
  for i = 1, 100 do
    local tick = frame.tickOverlay:CreateLine(nil, "OVERLAY")
    tick:SetDrawLayer("OVERLAY", 7)
    tick:SetColorTexture(0, 0, 0, 1)
    tick:SetThickness(1)
    tick:Hide()
    frame.tickMarks[i] = tick
  end
  
  -- Border textures (4 separate textures for pixel-perfect borders - no centered edge issues)
  -- This approach gives precise control unlike BackdropTemplate which centers edges
  frame.borderOverlay = CreateFrame("Frame", nil, frame)
  frame.borderOverlay:SetAllPoints(frame)
  frame.borderOverlay:SetFrameLevel(frame:GetFrameLevel() + 151)
  
  frame.borderOverlay.top = frame.borderOverlay:CreateTexture(nil, "OVERLAY")
  frame.borderOverlay.top:SetSnapToPixelGrid(false)
  frame.borderOverlay.top:SetTexelSnappingBias(0)
  
  frame.borderOverlay.bottom = frame.borderOverlay:CreateTexture(nil, "OVERLAY")
  frame.borderOverlay.bottom:SetSnapToPixelGrid(false)
  frame.borderOverlay.bottom:SetTexelSnappingBias(0)
  
  frame.borderOverlay.left = frame.borderOverlay:CreateTexture(nil, "OVERLAY")
  frame.borderOverlay.left:SetSnapToPixelGrid(false)
  frame.borderOverlay.left:SetTexelSnappingBias(0)
  
  frame.borderOverlay.right = frame.borderOverlay:CreateTexture(nil, "OVERLAY")
  frame.borderOverlay.right:SetSnapToPixelGrid(false)
  frame.borderOverlay.right:SetTexelSnappingBias(0)
  
  -- Drag functionality + right-click to edit
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not IsShiftKeyDown() then
      local cfg = ns.API.GetResourceBarConfig(barNumber)
      if cfg and cfg.display.barMovable then
        self:StartMoving()
      end
    end
  end)
  
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and not IsShiftKeyDown() then
      self:StopMovingOrSizing()
      local cfg = ns.API.GetResourceBarConfig(barNumber)
      if cfg then
        local point, _, relPoint, x, y = self:GetPoint()
        cfg.display.barPosition = {
          point = point,
          relPoint = relPoint,
          x = x,
          y = y
        }
      end
    elseif button == "RightButton" or (button == "LeftButton" and IsShiftKeyDown()) then
      -- Open options and select this resource bar
      if ns.Resources.OpenOptionsForBar then
        ns.Resources.OpenOptionsForBar(barNumber)
      end
    end
  end)
  
  -- Delete button (small red X in corner, only visible when options panel is open)
  frame.deleteButton = CreateFrame("Button", nil, frame)
  frame.deleteButton:SetSize(12, 12)
  frame.deleteButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  -- Must be above tickOverlay (which is at +150) to be visible
  frame.deleteButton:SetFrameLevel(frame:GetFrameLevel() + 200)
  
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
    if ShowResourceDeleteConfirmation then
      ShowResourceDeleteConfirmation(barNumber)
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
-- CREATE TEXT FRAME
-- ===================================================================
local function CreateResourceTextFrame(barNumber)
  local frame = CreateFrame("Frame", "ArcUIResourceText" .. barNumber, UIParent)
  frame:SetSize(100, 40)
  frame:SetPoint("CENTER", 0, -70 - ((barNumber - 1) * 35))
  frame:SetMovable(true)
  frame:EnableMouse(false)
  frame:SetClampedToScreen(true)
  -- Use MEDIUM strata so we don't overlap Blizzard UI panels
  -- Frame level 200 to be above tick overlay (~151) but still in MEDIUM strata
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(250)
  
  frame.text = frame:CreateFontString(nil, "OVERLAY")
  frame.text:SetPoint("CENTER")
  frame.text:SetFont("Fonts\\FRIZQT__.TTF", 20, "THICKOUTLINE")
  frame.text:SetText("0")
  frame.text:SetTextColor(1, 1, 1, 1)
  frame.text:SetShadowOffset(0, 0)  -- Default to no shadow (setting controls this)
  
  -- Drag functionality
  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      self:StartMoving()
    end
  end)
  
  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      self:StopMovingOrSizing()
      local cfg = ns.API.GetResourceBarConfig(barNumber)
      if cfg then
        local point, _, relPoint, x, y = self:GetPoint()
        cfg.display.textPosition = {
          point = point,
          relPoint = relPoint,
          x = x,
          y = y
        }
      end
    end
  end)
  
  frame:Hide()
  return frame
end

-- ===================================================================
-- GET OR CREATE RESOURCE FRAMES
-- ===================================================================
local function GetResourceFrames(barNumber)
  if not resourceFrames[barNumber] then
    resourceFrames[barNumber] = {
      mainFrame = CreateResourceBarFrame(barNumber),
      textFrame = CreateResourceTextFrame(barNumber)
    }
  end
  return resourceFrames[barNumber].mainFrame, resourceFrames[barNumber].textFrame
end

-- ===================================================================
-- UPDATE THRESHOLD LAYERS
-- ===================================================================
-- TWO MODES:
--
-- SIMPLE MODE: Single bar with proportional fill (1 color)
-- GRANULAR MODE: TRUE color change at ANY threshold using ~100 bars
--
local function UpdateThresholdLayers(barNumber, secretValue, passedMaxValue)
  local cfg = ns.API.GetResourceBarConfig(barNumber)
  if not cfg or not cfg.tracking.enabled then return end
  
  local mainFrame, _ = GetResourceFrames(barNumber)
  local thresholds = cfg.thresholds or {}
  
  -- Use passed maxValue if provided, otherwise fall back to stored
  local maxValue = passedMaxValue or cfg.tracking.maxValue or 100
  local displayMode = cfg.display.thresholdMode or "simple"
  
  -- MIGRATION: Convert old granular/threshold modes to colorCurve
  -- Granular mode (1 StatusBar per unit) caused "script ran too long" on high-value resources
  -- and threshold mode (stacked bars) is redundant with colorCurve. Both are now removed.
  if displayMode == "granular" or displayMode == "threshold" then
    -- Migrate old thresholds[2-5] config to colorCurve keys if present
    if cfg.thresholds and not cfg.display.colorCurveEnabled then
      cfg.display.colorCurveEnabled = true
      cfg.display.colorCurveThresholdAsPercent = cfg.display.thresholdAsPercent or false
      for i = 2, 5 do
        if cfg.thresholds[i] then
          cfg.display["colorCurveThreshold" .. i .. "Enabled"] = cfg.thresholds[i].enabled
          cfg.display["colorCurveThreshold" .. i .. "Value"] = cfg.thresholds[i].minValue
          -- Normalize color to {r=, g=, b=, a=} format (old data may use indexed arrays)
          local oldColor = cfg.thresholds[i].color
          if oldColor then
            local r, g, b, a = SafeColorRGBA(oldColor)
            cfg.display["colorCurveThreshold" .. i .. "Color"] = {r=r, g=g, b=b, a=a}
          end
        end
      end
    end
    cfg.display.thresholdMode = "colorCurve"
    displayMode = "colorCurve"
  end
  
  -- Hide all existing layers
  for i = 1, #mainFrame.layers do
    mainFrame.layers[i]:Hide()
  end
  
  -- Hide granular bars if they exist
  if mainFrame.granularBars then
    for i = 1, #mainFrame.granularBars do
      mainFrame.granularBars[i]:Hide()
    end
  end
  
  -- Hide stacked bars if they exist
  if mainFrame.stackedBars then
    for i = 1, #mainFrame.stackedBars do
      mainFrame.stackedBars[i]:Hide()
    end
  end
  
  -- Hide fragmented bars if they exist
  if mainFrame.fragmentedBars then
    for i = 1, #mainFrame.fragmentedBars do
      mainFrame.fragmentedBars[i]:Hide()
    end
  end
  if mainFrame.fragmentedBgs then
    for i = 1, #mainFrame.fragmentedBgs do
      mainFrame.fragmentedBgs[i]:Hide()
    end
  end
  -- Clear fragmented OnUpdate when switching away
  if displayMode ~= "fragmented" and mainFrame.fragmentedOnUpdate then
    mainFrame:SetScript("OnUpdate", nil)
    mainFrame.fragmentedOnUpdate = nil
  end
  
  -- Get texture from settings
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  local texturePath = "Interface\\TargetingFrame\\UI-StatusBar"
  if LSM and cfg.display.texture then
    local fetchedTexture = LSM:Fetch("statusbar", cfg.display.texture)
    if fetchedTexture then
      texturePath = fetchedTexture
    end
  end
  
  -- Get fill texture scale
  local fillTextureScale = cfg.display.fillTextureScale or 1.0
  
  if displayMode == "folded" then
    -- ═══════════════════════════════════════════════════════════════
    -- FOLDED MODE: Bar folds at midpoint, second color overlays first
    -- Visual: 2nd color fills over 1st after midpoint
    -- ═══════════════════════════════════════════════════════════════
    local midpoint = math.ceil(maxValue / 2)
    local color1 = cfg.display.foldedColor1 or {r=0, g=0.5, b=1, a=1}
    local color2 = cfg.display.foldedColor2 or {r=0, g=1, b=0, a=1}
    
    -- Get smoothing and orientation settings
    local enableSmooth = cfg.display.enableSmoothing
    local orientation = GetBarOrientation(cfg)
    local reverseFill = GetBarReverseFill(cfg)
    local isVertical = (orientation == "VERTICAL")
    
    -- Hide other bar types
    if mainFrame.granularBars then
      for _, bar in ipairs(mainFrame.granularBars) do bar:Hide() end
    end
    if mainFrame.layers then
      for _, layer in ipairs(mainFrame.layers) do layer:Hide() end
    end
    -- Hide foldedBgFrame if exists from old code
    if mainFrame.foldedBgFrame then
      mainFrame.foldedBgFrame:Hide()
    end
    -- Hide fragment frames if they exist
    if mainFrame.fragmentFrames then
      for _, frame in ipairs(mainFrame.fragmentFrames) do frame:Hide() end
    end
    -- Hide icon frames if they exist
    if mainFrame.iconFrames then
      for _, frame in ipairs(mainFrame.iconFrames) do frame:Hide() end
    end
    
    if not mainFrame.stackedBars then
      mainFrame.stackedBars = {}
    end
    
    while #mainFrame.stackedBars < 2 do
      local bar = CreateFrame("StatusBar", nil, mainFrame)
      bar:SetStatusBarTexture(texturePath)
      bar:SetOrientation(orientation)
      bar:SetReverseFill(reverseFill)
      bar:SetRotatesTexture(isVertical)
      table.insert(mainFrame.stackedBars, bar)
    end
    
    -- Bar 1: First half color (0 to midpoint)
    local bar1 = mainFrame.stackedBars[1]
    bar1:SetParent(mainFrame)
    bar1:ClearAllPoints()
    bar1:SetAllPoints(mainFrame)  -- Fill entire frame like MWRB
    bar1:SetMinMaxValues(0, midpoint)
    bar1:SetStatusBarTexture(texturePath)
    bar1:SetStatusBarColor(color1.r, color1.g, color1.b, color1.a or 1)
    bar1:SetOrientation(orientation)
    bar1:SetReverseFill(reverseFill)
    bar1:SetRotatesTexture(isVertical)
    bar1:SetFrameLevel(mainFrame:GetFrameLevel() + 6)
    ApplyBarSmoothing(bar1, enableSmooth)
    bar1:SetValue(secretValue)  -- Will cap at midpoint naturally
    bar1:Show()
    
    -- Bar 2: Second half color (midpoint to max) - overlays bar1 directly
    local bar2 = mainFrame.stackedBars[2]
    bar2:SetParent(mainFrame)
    bar2:ClearAllPoints()
    bar2:SetAllPoints(mainFrame)  -- Fill entire frame like MWRB
    bar2:SetMinMaxValues(midpoint, maxValue)
    bar2:SetStatusBarTexture(texturePath)
    bar2:SetStatusBarColor(color2.r, color2.g, color2.b, color2.a or 1)
    bar2:SetOrientation(orientation)
    bar2:SetReverseFill(reverseFill)
    bar2:SetRotatesTexture(isVertical)
    bar2:SetFrameLevel(mainFrame:GetFrameLevel() + 7)
    ApplyBarSmoothing(bar2, enableSmooth)
    bar2:SetValue(secretValue)  -- Only fills when value > midpoint
    bar2:Show()
    
    -- MAX COLOR OVERLAY for folded mode
    local enableMaxColor = cfg.display.enableMaxColor
    if enableMaxColor and maxValue > 1 then
      if not mainFrame.maxColorBar then
        mainFrame.maxColorBar = CreateFrame("StatusBar", nil, mainFrame)
        mainFrame.maxColorBar:SetOrientation(orientation)
        mainFrame.maxColorBar:SetReverseFill(reverseFill)
        mainFrame.maxColorBar:SetRotatesTexture(isVertical)
      end
      
      local maxColor = cfg.display.maxColor or {r=0, g=1, b=0, a=1}
      local maxBar = mainFrame.maxColorBar
      
      maxBar:ClearAllPoints()
      maxBar:SetAllPoints(mainFrame)
      maxBar:SetMinMaxValues(maxValue - 1, maxValue)
      maxBar:SetStatusBarTexture(texturePath)
      maxBar:SetStatusBarColor(maxColor.r, maxColor.g, maxColor.b, maxColor.a or 1)
      maxBar:SetOrientation(orientation)
      maxBar:SetReverseFill(reverseFill)
      maxBar:SetRotatesTexture(isVertical)
      maxBar:SetFrameLevel(mainFrame:GetFrameLevel() + 8)
      ApplyBarSmoothing(maxBar, enableSmooth)
      maxBar:SetValue(secretValue)
      maxBar:Show()
    elseif mainFrame.maxColorBar then
      mainFrame.maxColorBar:Hide()
    end
    
  elseif displayMode == "fragmented" then
    -- ═══════════════════════════════════════════════════════════════
    -- FRAGMENTED MODE: Completely separate bars for each segment
    -- For Runes (DK) and Essence (Evoker) where each segment charges independently
    -- Each segment is its own independent frame with background, fill, border, text
    -- The gaps between segments are TRUE EMPTY SPACE (no background)
    -- ═══════════════════════════════════════════════════════════════
    
    -- Hide other bar types
    if mainFrame.granularBars then
      for _, bar in ipairs(mainFrame.granularBars) do bar:Hide() end
    end
    if mainFrame.stackedBars then
      for _, bar in ipairs(mainFrame.stackedBars) do bar:Hide() end
    end
    if mainFrame.maxColorBar then
      mainFrame.maxColorBar:Hide()
    end
    -- Hide simple mode layers
    for i = 1, #mainFrame.layers do
      mainFrame.layers[i]:Hide()
    end
    
    -- CRITICAL: Hide main frame's background and borders so gaps show through
    if mainFrame.bg then
      mainFrame.bg:Hide()
    end
    if mainFrame.borderOverlay then
      if mainFrame.borderOverlay.top then mainFrame.borderOverlay.top:Hide() end
      if mainFrame.borderOverlay.bottom then mainFrame.borderOverlay.bottom:Hide() end
      if mainFrame.borderOverlay.left then mainFrame.borderOverlay.left:Hide() end
      if mainFrame.borderOverlay.right then mainFrame.borderOverlay.right:Hide() end
      mainFrame.borderOverlay:Hide()
    end
    -- Hide icon frames if they exist
    if mainFrame.iconFrames then
      for _, frame in ipairs(mainFrame.iconFrames) do frame:Hide() end
    end
    
    -- Get resource type from config
    local secondaryType = cfg.tracking.secondaryType
    local numSegments = maxValue
    local segmentData = nil
    
    -- Get per-segment cooldown data
    if secondaryType == "runes" then
      segmentData, numSegments = ns.Resources.GetRuneCooldownDetails()
    elseif secondaryType == "essence" then
      segmentData, numSegments = ns.Resources.GetEssenceCooldownDetails()
    end
    
    if not segmentData or numSegments <= 0 then
      numSegments = maxValue
    end
    
    -- Get colors
    local chargingColor = cfg.display.fragmentedChargingColor or {r=0.4, g=0.4, b=0.4, a=1}
    local perSegmentColors = cfg.display.fragmentedColors or {}
    local defaultReadyColor = {r=0.77, g=0.12, b=0.23, a=1}
    local bgColor = cfg.display.backgroundColor or {r=0.1, g=0.1, b=0.1, a=0.8}
    local borderColor = cfg.display.borderColor or {r=0, g=0, b=0, a=1}
    local showBorder = cfg.display.showBorder
    local borderThickness = cfg.display.drawnBorderThickness or 2
    
    -- Get smoothing setting
    local enableSmooth = cfg.display.enableSmoothing
    
    -- Text settings
    local showSegmentText = cfg.display.fragmentedShowSegmentText
    local textSize = cfg.display.fragmentedTextSize or 10
    
    -- Spacing between segments (actual gap between separate frames)
    local spacing = cfg.display.fragmentedSpacing or 2
    local totalWidth = mainFrame:GetWidth()
    local totalHeight = mainFrame:GetHeight()
    local segmentWidth = (totalWidth - (spacing * (numSegments - 1))) / numSegments
    
    -- Create fragment frames container if it doesn't exist
    if not mainFrame.fragmentFrames then
      mainFrame.fragmentFrames = {}
    end
    
    -- Ensure we have enough fragment frames
    while #mainFrame.fragmentFrames < numSegments do
      local idx = #mainFrame.fragmentFrames + 1
      
      -- Create container frame for this segment
      local segFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
      segFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 1)
      
      -- Background texture
      segFrame.bg = segFrame:CreateTexture(nil, "BACKGROUND")
      segFrame.bg:SetAllPoints()
      segFrame.bg:SetTexture(texturePath)
      segFrame.bg:SetSnapToPixelGrid(false)
      segFrame.bg:SetTexelSnappingBias(0)
      
      -- Fill StatusBar
      segFrame.fill = CreateFrame("StatusBar", nil, segFrame)
      segFrame.fill:SetPoint("TOPLEFT", segFrame, "TOPLEFT", 0, 0)
      segFrame.fill:SetPoint("BOTTOMRIGHT", segFrame, "BOTTOMRIGHT", 0, 0)
      segFrame.fill:SetStatusBarTexture(texturePath)
      segFrame.fill:SetOrientation("HORIZONTAL")
      segFrame.fill:SetReverseFill(false)
      segFrame.fill:SetMinMaxValues(0, 1)
      segFrame.fill:SetFrameLevel(segFrame:GetFrameLevel() + 1)
      ConfigureStatusBar(segFrame.fill)  -- Prevent pixel snapping
      
      -- Border (drawn style)
      segFrame.borderTop = segFrame:CreateTexture(nil, "OVERLAY")
      segFrame.borderTop:SetSnapToPixelGrid(false)
      segFrame.borderTop:SetTexelSnappingBias(0)
      segFrame.borderBottom = segFrame:CreateTexture(nil, "OVERLAY")
      segFrame.borderBottom:SetSnapToPixelGrid(false)
      segFrame.borderBottom:SetTexelSnappingBias(0)
      segFrame.borderLeft = segFrame:CreateTexture(nil, "OVERLAY")
      segFrame.borderLeft:SetSnapToPixelGrid(false)
      segFrame.borderLeft:SetTexelSnappingBias(0)
      segFrame.borderRight = segFrame:CreateTexture(nil, "OVERLAY")
      segFrame.borderRight:SetSnapToPixelGrid(false)
      segFrame.borderRight:SetTexelSnappingBias(0)
      
      -- Cooldown text
      segFrame.cdText = segFrame.fill:CreateFontString(nil, "OVERLAY")
      segFrame.cdText:SetPoint("CENTER", segFrame.fill, "CENTER", 0, 0)
      segFrame.cdText:SetTextColor(1, 1, 1, 1)
      
      table.insert(mainFrame.fragmentFrames, segFrame)
    end
    
    -- Position and update each segment frame
    for i = 1, numSegments do
      local segFrame = mainFrame.fragmentFrames[i]
      
      -- Calculate position (actual separate frame positioning)
      local xOffset = (i - 1) * (segmentWidth + spacing)
      
      -- Position and size segment frame
      segFrame:ClearAllPoints()
      segFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xOffset, 0)
      segFrame:SetSize(segmentWidth, totalHeight)
      
      -- Update background
      segFrame.bg:SetTexture(texturePath)
      segFrame.bg:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
      
      -- Update fill bar
      segFrame.fill:SetStatusBarTexture(texturePath)
      ApplyBarSmoothing(segFrame.fill, enableSmooth)
      
      -- Update border
      if showBorder then
        local bt = borderThickness
        -- Top border
        segFrame.borderTop:ClearAllPoints()
        segFrame.borderTop:SetPoint("TOPLEFT", segFrame, "TOPLEFT", 0, 0)
        segFrame.borderTop:SetPoint("TOPRIGHT", segFrame, "TOPRIGHT", 0, 0)
        segFrame.borderTop:SetHeight(bt)
        segFrame.borderTop:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        segFrame.borderTop:Show()
        
        -- Bottom border
        segFrame.borderBottom:ClearAllPoints()
        segFrame.borderBottom:SetPoint("BOTTOMLEFT", segFrame, "BOTTOMLEFT", 0, 0)
        segFrame.borderBottom:SetPoint("BOTTOMRIGHT", segFrame, "BOTTOMRIGHT", 0, 0)
        segFrame.borderBottom:SetHeight(bt)
        segFrame.borderBottom:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        segFrame.borderBottom:Show()
        
        -- Left border
        segFrame.borderLeft:ClearAllPoints()
        segFrame.borderLeft:SetPoint("TOPLEFT", segFrame, "TOPLEFT", 0, -bt)
        segFrame.borderLeft:SetPoint("BOTTOMLEFT", segFrame, "BOTTOMLEFT", 0, bt)
        segFrame.borderLeft:SetWidth(bt)
        segFrame.borderLeft:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        segFrame.borderLeft:Show()
        
        -- Right border
        segFrame.borderRight:ClearAllPoints()
        segFrame.borderRight:SetPoint("TOPRIGHT", segFrame, "TOPRIGHT", 0, -bt)
        segFrame.borderRight:SetPoint("BOTTOMRIGHT", segFrame, "BOTTOMRIGHT", 0, bt)
        segFrame.borderRight:SetWidth(bt)
        segFrame.borderRight:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        segFrame.borderRight:Show()
      else
        segFrame.borderTop:Hide()
        segFrame.borderBottom:Hide()
        segFrame.borderLeft:Hide()
        segFrame.borderRight:Hide()
      end
      
      -- Get fill percentage for this segment
      local fillPercent = 0
      local isReady = false
      local cooldownRemaining = 0
      
      if segmentData and segmentData[i] then
        fillPercent = segmentData[i].fillPercent or 0
        isReady = segmentData[i].ready
        -- Calculate remaining time
        if not isReady and segmentData[i].start and segmentData[i].duration and segmentData[i].duration > 0 then
          local elapsed = GetTime() - segmentData[i].start
          cooldownRemaining = math.max(0, segmentData[i].duration - elapsed)
        end
      else
        -- Fallback: check if we have this many resources
        fillPercent = (secretValue >= i) and 1 or 0
        isReady = (secretValue >= i)
      end
      
      -- Get color for this segment
      local segmentColor
      if isReady then
        segmentColor = perSegmentColors[i] or defaultReadyColor
      else
        segmentColor = chargingColor
      end
      
      segFrame.fill:SetStatusBarColor(segmentColor.r, segmentColor.g, segmentColor.b, segmentColor.a or 1)
      segFrame.fill:SetValue(fillPercent)
      
      -- Update cooldown text
      segFrame.cdText:SetFont(STANDARD_TEXT_FONT, textSize, "OUTLINE")
      if showSegmentText and not isReady and cooldownRemaining > 0 then
        if cooldownRemaining >= 1 then
          segFrame.cdText:SetText(string.format("%.0f", cooldownRemaining))
        else
          segFrame.cdText:SetText(string.format("%.1f", cooldownRemaining))
        end
        segFrame.cdText:Show()
      else
        segFrame.cdText:Hide()
      end
      
      segFrame:Show()
    end
    
    -- Hide unused segment frames
    for i = numSegments + 1, #mainFrame.fragmentFrames do
      if mainFrame.fragmentFrames[i] then
        mainFrame.fragmentFrames[i]:Hide()
      end
    end
    
    -- Hide old fragmented bars if they exist
    if mainFrame.fragmentedBars then
      for _, bar in ipairs(mainFrame.fragmentedBars) do bar:Hide() end
    end
    if mainFrame.fragmentedBgs then
      for _, bg in ipairs(mainFrame.fragmentedBgs) do bg:Hide() end
    end
    
    -- Set up OnUpdate for animation (only for runes/essence which have cooldowns)
    if secondaryType == "runes" or secondaryType == "essence" then
      mainFrame.fragmentedSecondaryType = secondaryType
      mainFrame.fragmentedConfig = cfg
      mainFrame.fragmentedTexturePath = texturePath
      
      if not mainFrame.fragmentedOnUpdate then
        mainFrame.fragmentedOnUpdate = function(self, elapsed)
          if not self.fragmentFrames or not self:IsShown() then return end
          
          local secType = self.fragmentedSecondaryType
          local config = self.fragmentedConfig
          if not secType or not config then return end
          
          local data, num
          if secType == "runes" then
            data, num = ns.Resources.GetRuneCooldownDetails()
          elseif secType == "essence" then
            data, num = ns.Resources.GetEssenceCooldownDetails()
          end
          
          if not data then return end
          
          local chargingCol = config.display.fragmentedChargingColor or {r=0.4, g=0.4, b=0.4, a=1}
          local segColors = config.display.fragmentedColors or {}
          local defReadyCol = {r=0.77, g=0.12, b=0.23, a=1}
          local showText = config.display.fragmentedShowSegmentText
          local txtSize = config.display.fragmentedTextSize or 10
          
          for i = 1, num do
            local segFrame = self.fragmentFrames[i]
            
            if segFrame and data[i] then
              local fillPct = data[i].fillPercent or 0
              local ready = data[i].ready
              
              -- Get segment color
              local col
              if ready then
                col = segColors[i] or defReadyCol
              else
                col = chargingCol
              end
              
              segFrame.fill:SetStatusBarColor(col.r, col.g, col.b, col.a or 1)
              segFrame.fill:SetValue(fillPct)
              
              -- Update text
              if showText and not ready and data[i].start and data[i].duration and data[i].duration > 0 then
                local remaining = math.max(0, data[i].duration - (GetTime() - data[i].start))
                if remaining > 0 then
                  if remaining >= 1 then
                    segFrame.cdText:SetText(string.format("%.0f", remaining))
                  else
                    segFrame.cdText:SetText(string.format("%.1f", remaining))
                  end
                  segFrame.cdText:Show()
                else
                  segFrame.cdText:Hide()
                end
              else
                segFrame.cdText:Hide()
              end
            end
          end
        end
        mainFrame:SetScript("OnUpdate", mainFrame.fragmentedOnUpdate)
      end
    else
      -- Clear OnUpdate for non-cooldown resources
      mainFrame:SetScript("OnUpdate", nil)
      mainFrame.fragmentedOnUpdate = nil
    end
    
  elseif displayMode == "icons" then
    -- ═══════════════════════════════════════════════════════════════
    -- ICONS MODE: Individual square/circle icons for each segment
    -- For Runes (DK) and Essence (Evoker) displayed as separate icons
    -- Supports Row (horizontal line) and Freeform (draggable) layouts
    -- ═══════════════════════════════════════════════════════════════
    
    -- Hide other bar types
    if mainFrame.granularBars then
      for _, bar in ipairs(mainFrame.granularBars) do bar:Hide() end
    end
    if mainFrame.stackedBars then
      for _, bar in ipairs(mainFrame.stackedBars) do bar:Hide() end
    end
    if mainFrame.maxColorBar then
      mainFrame.maxColorBar:Hide()
    end
    -- Hide simple mode layers
    for i = 1, #mainFrame.layers do
      mainFrame.layers[i]:Hide()
    end
    -- Hide fragmented frames if they exist
    if mainFrame.fragmentFrames then
      for _, frame in ipairs(mainFrame.fragmentFrames) do frame:Hide() end
    end
    
    -- Hide main frame's background and borders (icons have their own)
    if mainFrame.bg then
      mainFrame.bg:Hide()
    end
    if mainFrame.borderOverlay then
      if mainFrame.borderOverlay.top then mainFrame.borderOverlay.top:Hide() end
      if mainFrame.borderOverlay.bottom then mainFrame.borderOverlay.bottom:Hide() end
      if mainFrame.borderOverlay.left then mainFrame.borderOverlay.left:Hide() end
      if mainFrame.borderOverlay.right then mainFrame.borderOverlay.right:Hide() end
      mainFrame.borderOverlay:Hide()
    end
    
    -- Get resource type from config
    local secondaryType = cfg.tracking.secondaryType
    local numIcons = maxValue
    local segmentData = nil
    
    -- Get per-segment cooldown data
    if secondaryType == "runes" then
      segmentData, numIcons = ns.Resources.GetRuneCooldownDetails()
    elseif secondaryType == "essence" then
      segmentData, numIcons = ns.Resources.GetEssenceCooldownDetails()
    end
    
    if not segmentData or numIcons <= 0 then
      numIcons = maxValue
    end
    
    -- Get colors
    local chargingColor = cfg.display.fragmentedChargingColor or {r=0.4, g=0.4, b=0.4, a=1}
    local perSegmentColors = cfg.display.fragmentedColors or {}
    local defaultReadyColor = {r=0.77, g=0.12, b=0.23, a=1}
    local bgColor = cfg.display.backgroundColor or {r=0.1, g=0.1, b=0.1, a=0.8}
    local borderColor = cfg.display.borderColor or {r=0, g=0, b=0, a=1}
    local showBorder = cfg.display.showBorder
    local borderThickness = cfg.display.drawnBorderThickness or 2
    
    -- Icons settings
    local iconsMode = cfg.display.iconsMode or "row"
    local iconSize = cfg.display.iconsSize or 32
    local iconSpacing = cfg.display.iconsSpacing or 4
    local showCDText = cfg.display.iconsShowCooldownText
    local cdTextSize = cfg.display.iconsCooldownTextSize or 12
    local savedPositions = cfg.display.iconsPositions or {}
    
    -- Create icon frames container
    if not mainFrame.iconFrames then
      mainFrame.iconFrames = {}
    end
    
    -- Ensure we have enough icon frames
    while #mainFrame.iconFrames < numIcons do
      local idx = #mainFrame.iconFrames + 1
      
      -- Create container frame for this icon
      local iconFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
      iconFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 1)
      iconFrame.index = idx
      
      -- Background
      iconFrame.bg = iconFrame:CreateTexture(nil, "BACKGROUND")
      iconFrame.bg:SetAllPoints()
      
      -- Fill overlay (for cooldown progress)
      iconFrame.fill = iconFrame:CreateTexture(nil, "ARTWORK")
      iconFrame.fill:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 0, 0)
      iconFrame.fill:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
      
      -- Border textures
      iconFrame.borderTop = iconFrame:CreateTexture(nil, "OVERLAY")
      iconFrame.borderBottom = iconFrame:CreateTexture(nil, "OVERLAY")
      iconFrame.borderLeft = iconFrame:CreateTexture(nil, "OVERLAY")
      iconFrame.borderRight = iconFrame:CreateTexture(nil, "OVERLAY")
      
      -- Cooldown text
      iconFrame.cdText = iconFrame:CreateFontString(nil, "OVERLAY")
      iconFrame.cdText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
      iconFrame.cdText:SetTextColor(1, 1, 1, 1)
      
      -- Make draggable in freeform mode
      iconFrame:SetMovable(true)
      iconFrame:EnableMouse(true)
      iconFrame:RegisterForDrag("LeftButton")
      
      iconFrame:SetScript("OnDragStart", function(self)
        local db = ns.API.GetDB()
        local barNum = cfg._barIndex or 1
        local resCfg = ns.API.GetResourceBarConfig(barNum)
        if resCfg and resCfg.display.iconsMode == "freeform" then
          self:StartMoving()
        end
      end)
      
      iconFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local barNum = cfg._barIndex or 1
        local resCfg = ns.API.GetResourceBarConfig(barNum)
        if resCfg then
          if not resCfg.display.iconsPositions then
            resCfg.display.iconsPositions = {}
          end
          local point, _, relPoint, x, y = self:GetPoint(1)
          resCfg.display.iconsPositions[self.index] = {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y
          }
        end
      end)
      
      table.insert(mainFrame.iconFrames, iconFrame)
    end
    
    -- Position and update each icon
    for i = 1, numIcons do
      local iconFrame = mainFrame.iconFrames[i]
      
      -- Size
      iconFrame:SetSize(iconSize, iconSize)
      
      -- Position based on layout mode
      iconFrame:ClearAllPoints()
      if iconsMode == "freeform" and savedPositions[i] then
        -- Use saved position
        local pos = savedPositions[i]
        iconFrame:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "CENTER", pos.x or 0, pos.y or 0)
      elseif iconsMode == "freeform" then
        -- Default freeform position (spread out horizontally)
        local xOffset = (i - 1) * (iconSize + iconSpacing)
        iconFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xOffset, 0)
      else
        -- Row mode - horizontal line
        local xOffset = (i - 1) * (iconSize + iconSpacing)
        iconFrame:SetPoint("LEFT", mainFrame, "LEFT", xOffset, 0)
      end
      
      -- Get fill percentage for this icon
      local fillPercent = 0
      local isReady = false
      local cooldownRemaining = 0
      
      if segmentData and segmentData[i] then
        fillPercent = segmentData[i].fillPercent or 0
        isReady = segmentData[i].ready
        if not isReady and segmentData[i].start and segmentData[i].duration and segmentData[i].duration > 0 then
          local elapsed = GetTime() - segmentData[i].start
          cooldownRemaining = math.max(0, segmentData[i].duration - elapsed)
        end
      else
        fillPercent = (secretValue >= i) and 1 or 0
        isReady = (secretValue >= i)
      end
      
      -- Get color for this icon
      local iconColor
      if isReady then
        iconColor = perSegmentColors[i] or defaultReadyColor
      else
        iconColor = chargingColor
      end
      
      -- Update background (dimmed version of ready color)
      iconFrame.bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
      
      -- Update fill (shows cooldown progress from bottom to top)
      local fillHeight = iconSize * fillPercent
      iconFrame.fill:SetHeight(math.max(1, fillHeight))
      iconFrame.fill:SetColorTexture(iconColor.r, iconColor.g, iconColor.b, iconColor.a or 1)
      if fillPercent > 0 then
        iconFrame.fill:Show()
      else
        iconFrame.fill:Hide()
      end
      
      -- Update border
      if showBorder then
        local bt = borderThickness
        iconFrame.borderTop:ClearAllPoints()
        iconFrame.borderTop:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
        iconFrame.borderTop:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 0, 0)
        iconFrame.borderTop:SetHeight(bt)
        iconFrame.borderTop:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        iconFrame.borderTop:Show()
        
        iconFrame.borderBottom:ClearAllPoints()
        iconFrame.borderBottom:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 0, 0)
        iconFrame.borderBottom:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
        iconFrame.borderBottom:SetHeight(bt)
        iconFrame.borderBottom:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        iconFrame.borderBottom:Show()
        
        iconFrame.borderLeft:ClearAllPoints()
        iconFrame.borderLeft:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, -bt)
        iconFrame.borderLeft:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 0, bt)
        iconFrame.borderLeft:SetWidth(bt)
        iconFrame.borderLeft:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        iconFrame.borderLeft:Show()
        
        iconFrame.borderRight:ClearAllPoints()
        iconFrame.borderRight:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 0, -bt)
        iconFrame.borderRight:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, bt)
        iconFrame.borderRight:SetWidth(bt)
        iconFrame.borderRight:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        iconFrame.borderRight:Show()
      else
        iconFrame.borderTop:Hide()
        iconFrame.borderBottom:Hide()
        iconFrame.borderLeft:Hide()
        iconFrame.borderRight:Hide()
      end
      
      -- Update cooldown text
      iconFrame.cdText:SetFont(STANDARD_TEXT_FONT, cdTextSize, "OUTLINE")
      if showCDText and not isReady and cooldownRemaining > 0 then
        if cooldownRemaining >= 1 then
          iconFrame.cdText:SetText(string.format("%.0f", cooldownRemaining))
        else
          iconFrame.cdText:SetText(string.format("%.1f", cooldownRemaining))
        end
        iconFrame.cdText:Show()
      else
        iconFrame.cdText:Hide()
      end
      
      iconFrame:Show()
    end
    
    -- Hide unused icons
    for i = numIcons + 1, #mainFrame.iconFrames do
      if mainFrame.iconFrames[i] then
        mainFrame.iconFrames[i]:Hide()
      end
    end
    
    -- Set up OnUpdate for animation
    if secondaryType == "runes" or secondaryType == "essence" then
      mainFrame.iconsSecondaryType = secondaryType
      mainFrame.iconsConfig = cfg
      
      if not mainFrame.iconsOnUpdate then
        mainFrame.iconsOnUpdate = function(self, elapsed)
          if not self.iconFrames or not self:IsShown() then return end
          
          local secType = self.iconsSecondaryType
          local config = self.iconsConfig
          if not secType or not config then return end
          
          local data, num
          if secType == "runes" then
            data, num = ns.Resources.GetRuneCooldownDetails()
          elseif secType == "essence" then
            data, num = ns.Resources.GetEssenceCooldownDetails()
          end
          
          if not data then return end
          
          local chargingCol = config.display.fragmentedChargingColor or {r=0.4, g=0.4, b=0.4, a=1}
          local segColors = config.display.fragmentedColors or {}
          local defReadyCol = {r=0.77, g=0.12, b=0.23, a=1}
          local showText = config.display.iconsShowCooldownText
          local iSize = config.display.iconsSize or 32
          
          for i = 1, num do
            local iconFrame = self.iconFrames[i]
            
            if iconFrame and data[i] then
              local fillPct = data[i].fillPercent or 0
              local ready = data[i].ready
              
              -- Get icon color
              local col
              if ready then
                col = segColors[i] or defReadyCol
              else
                col = chargingCol
              end
              
              -- Update fill
              local fillH = iSize * fillPct
              iconFrame.fill:SetHeight(math.max(1, fillH))
              iconFrame.fill:SetColorTexture(col.r, col.g, col.b, col.a or 1)
              if fillPct > 0 then
                iconFrame.fill:Show()
              else
                iconFrame.fill:Hide()
              end
              
              -- Update text
              if showText and not ready and data[i].start and data[i].duration and data[i].duration > 0 then
                local remaining = math.max(0, data[i].duration - (GetTime() - data[i].start))
                if remaining > 0 then
                  if remaining >= 1 then
                    iconFrame.cdText:SetText(string.format("%.0f", remaining))
                  else
                    iconFrame.cdText:SetText(string.format("%.1f", remaining))
                  end
                  iconFrame.cdText:Show()
                else
                  iconFrame.cdText:Hide()
                end
              else
                iconFrame.cdText:Hide()
              end
            end
          end
        end
        mainFrame:SetScript("OnUpdate", mainFrame.iconsOnUpdate)
      end
    else
      mainFrame:SetScript("OnUpdate", nil)
      mainFrame.iconsOnUpdate = nil
    end
    
  elseif displayMode == "colorCurve" then
    -- ═══════════════════════════════════════════════════════════════
    -- COLORCURVE MODE: Single bar with dynamic color from ColorCurve API
    -- Uses UnitPowerPercent(unit, powerType, unmod, curve) which returns Color directly!
    -- Much simpler than multi-stacked bar approach, and fully secret-value safe.
    -- ═══════════════════════════════════════════════════════════════
    
    -- Hide all other bar types
    if mainFrame.fragmentFrames then
      for _, frame in ipairs(mainFrame.fragmentFrames) do frame:Hide() end
    end
    if mainFrame.iconFrames then
      for _, frame in ipairs(mainFrame.iconFrames) do frame:Hide() end
    end
    if mainFrame.granularBars then
      for _, bar in ipairs(mainFrame.granularBars) do bar:Hide() end
    end
    if mainFrame.maxColorBar then
      mainFrame.maxColorBar:Hide()
    end
    
    -- Get power type for ColorCurve
    local powerType = cfg.tracking.powerType
    
    -- Cache max power value when available (for numeric threshold conversion)
    if powerType and powerType >= 0 then
      CacheMaxPowerValue(powerType)
    end
    
    -- Get or create the ColorCurve
    local colorCurve = GetResourceColorCurve(barNumber, cfg, powerType)
    local baseColor = cfg.display.barColor or thresholds[1] and thresholds[1].color or {r=0, g=0.8, b=1, a=1}
    
    -- Get smoothing and orientation settings
    local enableSmooth = cfg.display.enableSmoothing
    local orientation = GetBarOrientation(cfg)
    local reverseFill = GetBarReverseFill(cfg)
    local isVertical = (orientation == "VERTICAL")
    
    -- Create stacked bars container if it doesn't exist (we only use 1 bar)
    if not mainFrame.stackedBars then
      mainFrame.stackedBars = {}
    end
    
    -- Ensure we have at least 1 bar
    if #mainFrame.stackedBars < 1 then
      local bar = CreateFrame("StatusBar", nil, mainFrame)
      bar:SetStatusBarTexture(texturePath)
      bar:SetOrientation(orientation)
      bar:SetReverseFill(reverseFill)
      bar:SetRotatesTexture(isVertical)
      table.insert(mainFrame.stackedBars, bar)
    end
    
    -- Hide any extra bars from other modes
    for i = 2, #mainFrame.stackedBars do
      mainFrame.stackedBars[i]:Hide()
    end
    
    -- Setup the single bar
    local bar = mainFrame.stackedBars[1]
    bar:ClearAllPoints()
    bar:SetAllPoints(mainFrame)
    bar:SetMinMaxValues(0, maxValue)
    bar:SetStatusBarTexture(texturePath)
    bar:SetOrientation(orientation)
    bar:SetReverseFill(reverseFill)
    bar:SetRotatesTexture(isVertical)
    bar:SetFrameLevel(mainFrame:GetFrameLevel() + 6)
    ApplyBarSmoothing(bar, enableSmooth)
    bar:SetValue(secretValue)
    bar:Show()
    
    -- Get the bar texture for color application
    local barTexture = bar:GetStatusBarTexture()
    
    -- Apply color using ColorCurve
    if colorCurve and powerType and powerType >= 0 then
      -- Use UnitPowerPercent with curve - returns Color directly, handles secrets internally!
      local colorOK = pcall(function()
        local colorResult = UnitPowerPercent("player", powerType, false, colorCurve)
        if colorResult and colorResult.GetRGB then
          barTexture:SetVertexColor(colorResult:GetRGB())
        else
          barTexture:SetVertexColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
        end
      end)
      if not colorOK then
        barTexture:SetVertexColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
      end
    else
      -- No color curve - use base color
      barTexture:SetVertexColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
    end
    
    -- Clear any OnUpdate handlers from other modes
    mainFrame:SetScript("OnUpdate", nil)
    mainFrame.fragmentedOnUpdate = nil
    mainFrame.iconsOnUpdate = nil
    
  else
    -- ═══════════════════════════════════════════════════════════════
    -- SIMPLE MODE: 2 bars (base color + optional max color overlay)
    -- ═══════════════════════════════════════════════════════════════
    -- Bar 1: Full width, 0 to max - base color
    -- Bar 2: Full width, (max-1) to max - max color overlay (on top)
    
    -- Hide fragment frames if they exist
    if mainFrame.fragmentFrames then
      for _, frame in ipairs(mainFrame.fragmentFrames) do frame:Hide() end
    end
    -- Hide icon frames if they exist
    if mainFrame.iconFrames then
      for _, frame in ipairs(mainFrame.iconFrames) do frame:Hide() end
    end
    -- Clear any OnUpdate handlers from other modes
    mainFrame:SetScript("OnUpdate", nil)
    mainFrame.fragmentedOnUpdate = nil
    mainFrame.iconsOnUpdate = nil
    
    local baseColor = thresholds[1] and thresholds[1].color or {r=0, g=0.8, b=1, a=1}
    local maxColor = cfg.display.maxColor or {r=0, g=1, b=0, a=1}
    local enableMaxColor = cfg.display.enableMaxColor
    
    -- Get smoothing and orientation settings
    local enableSmooth = cfg.display.enableSmoothing
    local orientation = GetBarOrientation(cfg)
    local reverseFill = GetBarReverseFill(cfg)
    local isVertical = (orientation == "VERTICAL")
    
    -- Hide maxColorBar from continuous mode (simple mode uses stackedBars[2] instead)
    if mainFrame.maxColorBar then
      mainFrame.maxColorBar:Hide()
    end
    
    -- Create stacked bars container if it doesn't exist
    if not mainFrame.stackedBars then
      mainFrame.stackedBars = {}
    end
    
    -- Ensure we have 2 stacked bars
    while #mainFrame.stackedBars < 2 do
      local bar = CreateFrame("StatusBar", nil, mainFrame)
      bar:SetStatusBarTexture(texturePath)
      bar:SetOrientation(orientation)
      bar:SetReverseFill(reverseFill)
      bar:SetRotatesTexture(isVertical)
      table.insert(mainFrame.stackedBars, bar)
    end
    
    if enableMaxColor and maxValue > 1 then
      -- TWO BARS: base (full width) + max color overlay (full width, on top)
      
      -- Bar 1: Base color (0 to max) - full width
      local bar1 = mainFrame.stackedBars[1]
      
      bar1:ClearAllPoints()
      bar1:SetAllPoints(mainFrame)  -- Fill entire frame like MWRB
      bar1:SetMinMaxValues(0, maxValue)
      bar1:SetStatusBarTexture(texturePath)
      bar1:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
      bar1:SetOrientation(orientation)
      bar1:SetReverseFill(reverseFill)
      bar1:SetRotatesTexture(isVertical)
      bar1:SetFrameLevel(mainFrame:GetFrameLevel() + 6)
      ApplyBarSmoothing(bar1, enableSmooth)
      bar1:SetValue(secretValue)
      bar1:Show()
      
      -- Bar 2: Max color overlay (max-1 to max) - full width, on top
      -- Only fills when at max value
      local bar2 = mainFrame.stackedBars[2]
      
      bar2:ClearAllPoints()
      bar2:SetAllPoints(mainFrame)  -- Fill entire frame like MWRB
      bar2:SetMinMaxValues(maxValue - 1, maxValue)
      bar2:SetStatusBarTexture(texturePath)
      bar2:SetStatusBarColor(maxColor.r, maxColor.g, maxColor.b, maxColor.a or 1)
      bar2:SetOrientation(orientation)
      bar2:SetReverseFill(reverseFill)
      bar2:SetRotatesTexture(isVertical)
      bar2:SetFrameLevel(mainFrame:GetFrameLevel() + 7)
      ApplyBarSmoothing(bar2, enableSmooth)
      bar2:SetValue(secretValue)
      bar2:Show()
      
    else
      -- SINGLE BAR: just base color
      local bar1 = mainFrame.stackedBars[1]
      
      bar1:ClearAllPoints()
      bar1:SetAllPoints(mainFrame)  -- Fill entire frame like MWRB
      bar1:SetMinMaxValues(0, maxValue)
      bar1:SetStatusBarTexture(texturePath)
      bar1:SetStatusBarColor(baseColor.r, baseColor.g, baseColor.b, baseColor.a or 1)
      bar1:SetOrientation(orientation)
      bar1:SetReverseFill(reverseFill)
      bar1:SetRotatesTexture(isVertical)
      bar1:SetFrameLevel(mainFrame:GetFrameLevel() + 6)
      ApplyBarSmoothing(bar1, enableSmooth)
      bar1:SetValue(secretValue)
      bar1:Show()
      
      -- Hide bar 2
      mainFrame.stackedBars[2]:Hide()
    end
  end
end

-- ===================================================================
-- UPDATE RESOURCE BAR (Called on power events)
-- ===================================================================
function ns.Resources.UpdateBar(barNumber)
  local cfg = ns.API.GetResourceBarConfig(barNumber)
  if not cfg or not cfg.tracking.enabled then
    if resourceFrames[barNumber] then
      resourceFrames[barNumber].mainFrame:Hide()
      resourceFrames[barNumber].textFrame:Hide()
    end
    return
  end
  
  -- Check if options panel is open - bypass spec/talent checks to allow editing
  local optionsOpen = IsOptionsOpen()
  
  -- ═══════════════════════════════════════════════════════════════════
  -- EARLY SPEC CHECK - Don't create/update frames for wrong spec
  -- This prevents "phantom bars" from appearing on other specs
  -- (Bypassed when options panel is open for editing)
  -- ═══════════════════════════════════════════════════════════════════
  local currentSpec = GetSpecialization() or 0
  local showOnSpecs = cfg.behavior and cfg.behavior.showOnSpecs
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
  elseif cfg.behavior and cfg.behavior.showOnSpec and cfg.behavior.showOnSpec > 0 then
    -- Legacy single spec check
    specAllowed = (currentSpec == cfg.behavior.showOnSpec)
  end
  
  -- If wrong spec, hide existing frames and return early (unless options open)
  if not specAllowed and not optionsOpen then
    if resourceFrames[barNumber] then
      resourceFrames[barNumber].mainFrame:Hide()
      resourceFrames[barNumber].textFrame:Hide()
    end
    return
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- TALENT CONDITION CHECK
  -- Hide bar if talent conditions not met (unless options panel is open)
  -- ═══════════════════════════════════════════════════════════════════
  local talentsMet = AreTalentConditionsMet(cfg)
  if not talentsMet and not optionsOpen then
    if resourceFrames[barNumber] then
      resourceFrames[barNumber].mainFrame:Hide()
      resourceFrames[barNumber].textFrame:Hide()
    end
    return
  end
  
  local mainFrame, textFrame = GetResourceFrames(barNumber)
  
  -- ═══════════════════════════════════════════════════════════════════
  -- DETERMINE RESOURCE TYPE (Primary vs Secondary)
  -- ═══════════════════════════════════════════════════════════════════
  local resourceCategory = cfg.tracking.resourceCategory or "primary"
  local secretValue, maxValue, displayValue, displayFormat
  
  if resourceCategory == "secondary" then
    -- SECONDARY RESOURCE (Combo Points, Runes, etc.)
    local secondaryType = cfg.tracking.secondaryType
    if not secondaryType then
      mainFrame:Hide()
      textFrame:Hide()
      return
    end
    
    local max, current, display, format = ns.Resources.GetSecondaryResourceValue(secondaryType)
    if not max or max <= 0 then
      mainFrame:Hide()
      textFrame:Hide()
      return
    end
    
    secretValue = current
    maxValue = max
    displayValue = display
    displayFormat = format
    
    -- Update stored max value if not overridden
    if not cfg.tracking.overrideMax then
      cfg.tracking.maxValue = maxValue
    else
      maxValue = cfg.tracking.maxValue or max
    end
  else
    -- PRIMARY RESOURCE (Mana, Rage, Energy, etc.)
    local powerType = cfg.tracking.powerType
    
    -- Guard: powerType must be valid (>= 0)
    if not powerType or powerType < 0 then
      mainFrame:Hide()
      textFrame:Hide()
      return
    end
    
    -- PRIMARY: Always use UnitPowerMax directly
    local unitMax = UnitPowerMax("player", powerType)
    maxValue = unitMax
    if not maxValue or maxValue <= 0 then
      maxValue = cfg.tracking.maxValue or 100
    end
    
    secretValue = UnitPower("player", powerType)
    displayValue = secretValue
    displayFormat = "number"
  end
  
  -- Update all threshold layers with the secret value AND maxValue
  UpdateThresholdLayers(barNumber, secretValue, maxValue)
  
  -- Update text (SetText handles secret values!)
  if cfg.display.showText then
    local textFormat = cfg.display.textFormat or "value"
    
    if textFormat == "percent" and cfg.tracking.resourceCategory ~= "secondary" then
      -- Percentage format using CurveConstants.ScaleTo100 for secret-safe 0-100 scaling
      local powerType = cfg.tracking.powerType
      if powerType and powerType >= 0 then
        -- CurveConstants.ScaleTo100 scales 0-1 to 0-100 internally (handles secrets!)
        local pct = UnitPowerPercent("player", powerType, false, CurveConstants.ScaleTo100)
        textFrame.text:SetFormattedText("%.0f%%", pct)
      else
        textFrame.text:SetText(secretValue)
      end
    elseif displayFormat == "decimal" then
      -- Format as decimal (e.g., Soul Shards for Destruction)
      textFrame.text:SetFormattedText("%.1f", displayValue)
    else
      -- Default: raw value
      textFrame.text:SetText(secretValue)
    end
    local tc = cfg.display.textColor
    textFrame.text:SetTextColor(tc.r, tc.g, tc.b, tc.a)
    textFrame:Show()
  else
    textFrame:Hide()
  end
  
  -- Update tick marks for ability costs / discrete units
  if cfg.display.showTickMarks then
    local width = mainFrame:GetWidth()
    local tickIndex = 1
    
    -- For folded mode, ticks are based on midpoint
    local tickMaxValue = maxValue
    local displayMode = cfg.display.thresholdMode or "simple"
    if displayMode == "folded" then
      tickMaxValue = math.ceil(maxValue / 2)
    end
    
    local tickMode = cfg.display.tickMode or "percent"
    local tickPositions = {}
    
    if tickMode == "all" then
      -- All mode: one tick per unit division (for small max values like combo points)
      -- Cap at 50 ticks to avoid performance issues with large resources
      if tickMaxValue <= 50 then
        for i = 1, tickMaxValue - 1 do
          table.insert(tickPositions, i)
        end
      else
        -- For large values, fall back to 10 evenly spaced ticks
        for i = 1, 9 do
          table.insert(tickPositions, math.floor(tickMaxValue * i / 10))
        end
      end
    elseif tickMode == "percent" then
      -- Percent mode: ticks at percentage intervals (including 100%)
      local tickPercent = cfg.display.tickPercent or 10
      local numTicks = math.floor(100 / tickPercent)
      for i = 1, numTicks do
        local tickVal = math.floor(tickMaxValue * (i * tickPercent / 100))
        if tickVal > 0 and tickVal <= tickMaxValue then
          table.insert(tickPositions, tickVal)
        end
      end
    elseif tickMode == "custom" and cfg.abilityThresholds and #cfg.abilityThresholds > 0 then
      -- Custom tick positions from abilityThresholds
      local usePercent = cfg.display.customTicksAsPercent
      for _, ability in ipairs(cfg.abilityThresholds) do
        if ability.enabled and ability.cost and ability.cost > 0 then
          local tickVal = ability.cost
          if usePercent then
            -- Interpret cost as percentage
            tickVal = math.floor(tickMaxValue * ability.cost / 100)
          end
          if tickVal > 0 and tickVal <= tickMaxValue then
            table.insert(tickPositions, tickVal)
          end
        end
      end
    end
    
    -- Render tick marks (no padding since we use SetAllPoints)
    for _, tickValue in ipairs(tickPositions) do
      if mainFrame.tickMarks[tickIndex] then
        local xPos = (tickValue / tickMaxValue) * width
        mainFrame.tickMarks[tickIndex]:SetStartPoint("TOPLEFT", mainFrame.tickOverlay, xPos, 0)
        mainFrame.tickMarks[tickIndex]:SetEndPoint("BOTTOMLEFT", mainFrame.tickOverlay, xPos, 0)
        -- Use PixelUtil for crisp, uniform tick width
        local thickness = cfg.display.tickThickness or 2
        local pixelThickness = PixelUtil.GetNearestPixelSize(thickness, mainFrame:GetEffectiveScale(), thickness)
        mainFrame.tickMarks[tickIndex]:SetThickness(pixelThickness)
        local tc = cfg.display.tickColor or {r=1, g=1, b=1, a=0.8}
        mainFrame.tickMarks[tickIndex]:SetColorTexture(tc.r, tc.g, tc.b, tc.a or 1)
        mainFrame.tickMarks[tickIndex]:Show()
        tickIndex = tickIndex + 1
      end
    end
    
    -- Hide unused ticks
    for i = tickIndex, 100 do
      if mainFrame.tickMarks[i] then
        mainFrame.tickMarks[i]:Hide()
      end
    end
  else
    -- Hide all ticks
    for i = 1, 100 do
      if mainFrame.tickMarks[i] then
        mainFrame.tickMarks[i]:Hide()
      end
    end
  end
  
  -- Show bar
  -- Note: Spec and talent checks were already done at the top of this function
  local shouldShow = cfg.display.enabled
  
  -- Bypass hideOutOfCombat when options panel is open for editing
  if cfg.behavior and cfg.behavior.hideOutOfCombat and not InCombatLockdown() and not optionsOpen then
    shouldShow = false
  end
  
  if shouldShow then
    mainFrame:Show()
  else
    mainFrame:Hide()
    textFrame:Hide()
  end
end

-- ===================================================================
-- APPLY APPEARANCE
-- ===================================================================
function ns.Resources.ApplyAppearance(barNumber)
  local cfg = ns.API.GetResourceBarConfig(barNumber)
  if not cfg then return end
  
  -- Check if options panel is open - bypass spec/talent checks to allow editing
  local optionsOpen = IsOptionsOpen()
  
  -- Early spec check - don't apply appearance for wrong spec bars (unless options open)
  local currentSpec = GetSpecialization() or 0
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
  
  -- If wrong spec, just hide any existing frames and return (unless options open)
  if not specAllowed and not optionsOpen then
    if resourceFrames[barNumber] then
      resourceFrames[barNumber].mainFrame:Hide()
      resourceFrames[barNumber].textFrame:Hide()
    end
    return
  end
  
  local mainFrame, textFrame = GetResourceFrames(barNumber)
  local display = cfg.display
  
  -- Size - SWAP width and height for vertical bars (like aura bars do)
  local isVertical = (display.barOrientation == "vertical")
  local scale = display.barScale or 1.0
  local scaledWidth = display.width * scale
  local scaledHeight = display.height * scale
  
  if isVertical then
    mainFrame:SetSize(scaledHeight, scaledWidth)  -- Swap dimensions for vertical!
  else
    mainFrame:SetSize(scaledWidth, scaledHeight)  -- Normal horizontal
  end
  
  -- NOTE: We apply scale to SIZE instead of SetScale() to avoid anchor drift
  -- mainFrame:SetScale(display.barScale or 1.0)  -- REMOVED - scale applied to size above
  mainFrame:SetAlpha(display.opacity or 1.0)
  
  -- Position
  if display.barPosition then
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint(
      display.barPosition.point,
      UIParent,
      display.barPosition.relPoint,
      display.barPosition.x,
      display.barPosition.y
    )
  end
  
  -- Text font and sizing (MUST happen before anchor positioning)
  if LSM and display.font then
    local font = LSM:Fetch("font", display.font)
    if font then
      -- Use textOutline setting (default to THICKOUTLINE for backwards compatibility)
      local outline = display.textOutline or "THICKOUTLINE"
      textFrame.text:SetFont(font, display.fontSize, outline)
      
      -- Apply text shadow setting
      if display.textShadow then
        textFrame.text:SetShadowOffset(2, -2)
        textFrame.text:SetShadowColor(0, 0, 0, 1)
      else
        textFrame.text:SetShadowOffset(0, 0)
      end
      
      -- Size frame based on fontSize (avoid secret value issues with GetStringWidth)
      local estimatedWidth = display.fontSize * 3  -- Enough for 2-3 digit numbers
      local estimatedHeight = display.fontSize + 4
      textFrame:SetSize(estimatedWidth, estimatedHeight)
    end
  end
  
  -- Text positioning - either anchored to bar or free-floating
  local textAnchor = display.textAnchor or "FREE"
  if textAnchor ~= "FREE" then
    -- Anchor text to bar edge points
    textFrame:ClearAllPoints()
    local offsetX = display.textAnchorOffsetX or 0
    local offsetY = display.textAnchorOffsetY or 0
    local padding = 5  -- Small padding from edge for visual clarity
    
    -- Inner anchors (text inside bar)
    if textAnchor == "CENTER" then
      textFrame:SetPoint("CENTER", mainFrame, "CENTER", offsetX, offsetY)
    elseif textAnchor == "RIGHT" or textAnchor == "CENTERRIGHT" then
      textFrame:SetPoint("CENTER", mainFrame, "RIGHT", -padding + offsetX, offsetY)
    elseif textAnchor == "LEFT" or textAnchor == "CENTERLEFT" then
      textFrame:SetPoint("CENTER", mainFrame, "LEFT", padding + offsetX, offsetY)
    elseif textAnchor == "TOP" then
      textFrame:SetPoint("CENTER", mainFrame, "TOP", offsetX, -padding + offsetY)
    elseif textAnchor == "BOTTOM" then
      textFrame:SetPoint("CENTER", mainFrame, "BOTTOM", offsetX, padding + offsetY)
    elseif textAnchor == "TOPLEFT" then
      textFrame:SetPoint("CENTER", mainFrame, "TOPLEFT", padding + offsetX, -padding + offsetY)
    elseif textAnchor == "TOPRIGHT" then
      textFrame:SetPoint("CENTER", mainFrame, "TOPRIGHT", -padding + offsetX, -padding + offsetY)
    elseif textAnchor == "BOTTOMLEFT" then
      textFrame:SetPoint("CENTER", mainFrame, "BOTTOMLEFT", padding + offsetX, padding + offsetY)
    elseif textAnchor == "BOTTOMRIGHT" then
      textFrame:SetPoint("CENTER", mainFrame, "BOTTOMRIGHT", -padding + offsetX, padding + offsetY)
    -- Outer anchors (text outside bar, touching the border)
    -- Use -20 for right-side outers, +20 for left-side outers to compensate for text centering
    elseif textAnchor == "OUTERRIGHT" or textAnchor == "OUTERCENTERRIGHT" then
      textFrame:SetPoint("LEFT", mainFrame, "RIGHT", -20 + offsetX, offsetY)
    elseif textAnchor == "OUTERLEFT" or textAnchor == "OUTERCENTERLEFT" then
      textFrame:SetPoint("RIGHT", mainFrame, "LEFT", 20 + offsetX, offsetY)
    elseif textAnchor == "OUTERTOP" then
      textFrame:SetPoint("BOTTOM", mainFrame, "TOP", offsetX, offsetY)
    elseif textAnchor == "OUTERBOTTOM" then
      textFrame:SetPoint("TOP", mainFrame, "BOTTOM", offsetX, offsetY)
    elseif textAnchor == "OUTERTOPLEFT" then
      textFrame:SetPoint("BOTTOMRIGHT", mainFrame, "TOPLEFT", 20 + offsetX, offsetY)
    elseif textAnchor == "OUTERTOPRIGHT" then
      textFrame:SetPoint("BOTTOMLEFT", mainFrame, "TOPRIGHT", -20 + offsetX, offsetY)
    elseif textAnchor == "OUTERBOTTOMLEFT" then
      textFrame:SetPoint("TOPRIGHT", mainFrame, "BOTTOMLEFT", 20 + offsetX, offsetY)
    elseif textAnchor == "OUTERBOTTOMRIGHT" then
      textFrame:SetPoint("TOPLEFT", mainFrame, "BOTTOMRIGHT", -20 + offsetX, offsetY)
    else
      -- Fallback
      textFrame:SetPoint("CENTER", mainFrame, "CENTER", offsetX, offsetY)
    end
  elseif display.textPosition then
    textFrame:ClearAllPoints()
    textFrame:SetPoint(
      display.textPosition.point,
      UIParent,
      display.textPosition.relPoint,
      display.textPosition.x,
      display.textPosition.y
    )
  end
  
  -- Background - fills entire frame like MWRB
  -- Skip if in fragmented mode (each segment has its own background)
  local isFragmented = display.thresholdMode == "fragmented"
  
  if display.showBackground and not isFragmented then
    local bg = display.backgroundColor
    local bgTextureName = display.backgroundTexture or "Solid"
    
    -- Background fills entire frame (SetAllPoints) like MWRB
    mainFrame.bg:ClearAllPoints()
    mainFrame.bg:SetAllPoints(mainFrame)
    
    if bgTextureName == "Solid" then
      mainFrame.bg:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
    else
      -- Try to fetch from LSM background type
      local bgTexture = LSM and LSM:Fetch("background", bgTextureName)
      if bgTexture then
        mainFrame.bg:SetTexture(bgTexture)
        mainFrame.bg:SetVertexColor(bg.r, bg.g, bg.b, bg.a)
      else
        mainFrame.bg:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
      end
    end
    mainFrame.bg:Show()
  else
    mainFrame.bg:Hide()
  end
  
  -- Border - draw around entire frame using 4 manual textures for pixel-perfect borders
  -- Skip if in fragmented mode (each segment has its own border)
  if display.showBorder and not isFragmented then
    local bt = display.drawnBorderThickness or 2
    local bc = display.borderColor
    
    -- Top border (spans full width at top)
    mainFrame.borderOverlay.top:ClearAllPoints()
    mainFrame.borderOverlay.top:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    mainFrame.borderOverlay.top:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
    mainFrame.borderOverlay.top:SetHeight(bt)
    mainFrame.borderOverlay.top:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
    mainFrame.borderOverlay.top:Show()
    
    -- Bottom border (spans full width at bottom)
    mainFrame.borderOverlay.bottom:ClearAllPoints()
    mainFrame.borderOverlay.bottom:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 0, 0)
    mainFrame.borderOverlay.bottom:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    mainFrame.borderOverlay.bottom:SetHeight(bt)
    mainFrame.borderOverlay.bottom:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
    mainFrame.borderOverlay.bottom:Show()
    
    -- Left border (between top and bottom borders)
    mainFrame.borderOverlay.left:ClearAllPoints()
    mainFrame.borderOverlay.left:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, -bt)
    mainFrame.borderOverlay.left:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 0, bt)
    mainFrame.borderOverlay.left:SetWidth(bt)
    mainFrame.borderOverlay.left:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
    mainFrame.borderOverlay.left:Show()
    
    -- Right border (between top and bottom borders)
    mainFrame.borderOverlay.right:ClearAllPoints()
    mainFrame.borderOverlay.right:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, -bt)
    mainFrame.borderOverlay.right:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, bt)
    mainFrame.borderOverlay.right:SetWidth(bt)
    mainFrame.borderOverlay.right:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
    mainFrame.borderOverlay.right:Show()
    
    mainFrame.borderOverlay:Show()
  else
    if mainFrame.borderOverlay.top then mainFrame.borderOverlay.top:Hide() end
    if mainFrame.borderOverlay.bottom then mainFrame.borderOverlay.bottom:Hide() end
    if mainFrame.borderOverlay.left then mainFrame.borderOverlay.left:Hide() end
    if mainFrame.borderOverlay.right then mainFrame.borderOverlay.right:Hide() end
    mainFrame.borderOverlay:Hide()
  end
  
  -- Texture for all layers (positioning is done in UpdateThresholdLayers)
  for i = 1, 5 do
    local layer = mainFrame.layers[i]
    
    -- Position to span full bar like MWRB (SetAllPoints)
    layer:ClearAllPoints()
    layer:SetAllPoints(mainFrame)
    
    if LSM and display.texture then
      local texture = LSM:Fetch("statusbar", display.texture)
      if texture then
        layer:SetStatusBarTexture(texture)
      end
    end
    
    -- Fill direction - use barOrientation and barReverseFill
    local isVertical = (display.barOrientation == "vertical")
    layer:SetOrientation(isVertical and "VERTICAL" or "HORIZONTAL")
    layer:SetReverseFill(display.barReverseFill or false)
    -- Rotate texture to match fill direction
    layer:SetRotatesTexture(isVertical)
  end
  
  -- Movability
  mainFrame:EnableMouse(display.barMovable)
  textFrame:EnableMouse(display.textMovable)
  
  -- Refresh display
  ns.Resources.UpdateBar(barNumber)
end

-- ===================================================================
-- HIDE BAR
-- ===================================================================
function ns.Resources.HideBar(barNumber)
  if resourceFrames[barNumber] then
    resourceFrames[barNumber].mainFrame:Hide()
    resourceFrames[barNumber].textFrame:Hide()
  end
end

-- ===================================================================
-- UPDATE ALL RESOURCE BARS
-- ===================================================================
function ns.Resources.UpdateAllBars()
  local activeBars = ns.API.GetActiveResourceBars()
  for _, barNumber in ipairs(activeBars) do
    ns.Resources.UpdateBar(barNumber)
  end
end

-- ===================================================================
-- APPLY ALL BARS
-- ===================================================================
function ns.Resources.ApplyAllBars()
  if not ns.API.GetActiveResourceBars then return end
  
  local activeBars = ns.API.GetActiveResourceBars()
  for _, barNumber in ipairs(activeBars) do
    ns.Resources.ApplyAppearance(barNumber)
  end
end

-- ===================================================================
-- REFRESH ALL BARS (for spec changes, etc.)
-- ===================================================================
function ns.Resources.RefreshAllBars()
  local currentSpec = GetSpecialization() or 0
  local optionsOpen = IsOptionsOpen()
  
  -- Get all active bars from DB (supports bars beyond index 10)
  local activeBars = ns.API.GetActiveResourceBars and ns.API.GetActiveResourceBars() or {}
  local activeSet = {}
  for _, barNum in ipairs(activeBars) do
    activeSet[barNum] = true
  end
  
  -- Also check bars 1-30 in case some are configured but not in activeBars yet
  for barNumber = 1, 30 do
    local cfg = ns.API.GetResourceBarConfig(barNumber)
    if cfg and cfg.tracking.enabled then
      activeSet[barNumber] = true
    end
  end
  
  -- Refresh all bars we found
  for barNumber, _ in pairs(activeSet) do
    local cfg = ns.API.GetResourceBarConfig(barNumber)
    if cfg and cfg.tracking.enabled then
      -- Check spec visibility first (bypassed when options panel open)
      local showOnSpecs = cfg.behavior and cfg.behavior.showOnSpecs
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
      elseif cfg.behavior and cfg.behavior.showOnSpec and cfg.behavior.showOnSpec > 0 then
        -- Legacy single spec check
        specAllowed = (currentSpec == cfg.behavior.showOnSpec)
      end
      
      -- Show bar if spec allowed OR options panel is open for editing
      if specAllowed or optionsOpen then
        -- CRITICAL: Apply appearance FIRST to restore saved position/styling
        -- Then update the bar values
        ns.Resources.ApplyAppearance(barNumber)
        ns.Resources.UpdateBar(barNumber)
      else
        -- Hide bar - wrong spec (only hide if frames exist, don't create them)
        if resourceFrames[barNumber] then
          resourceFrames[barNumber].mainFrame:Hide()
          resourceFrames[barNumber].textFrame:Hide()
        end
      end
    else
      -- Hide bars that aren't enabled (only hide if frames exist, don't create them)
      if resourceFrames[barNumber] then
        resourceFrames[barNumber].mainFrame:Hide()
        resourceFrames[barNumber].textFrame:Hide()
      end
    end
  end
end

-- ===================================================================
-- GET BAR FRAME (for external access)
-- ===================================================================
function ns.Resources.GetBarFrame(barNumber)
  if resourceFrames[barNumber] then
    return resourceFrames[barNumber].mainFrame
  end
  return nil
end

-- ===================================================================
-- OPEN OPTIONS AND SELECT RESOURCE BAR (for click-to-edit)
-- Only works if options panel is already open
-- ===================================================================
function ns.Resources.OpenOptionsForBar(barNumber)
  local AceConfigDialog = LibStub("AceConfigDialog-3.0")
  
  -- Check if options panel is already open
  if not AceConfigDialog.OpenFrames or not AceConfigDialog.OpenFrames["ArcUI"] then
    -- Panel is not open, do nothing
    return
  end
  
  -- Set the selected bar in AppearanceOptions
  if ns.AppearanceOptions and ns.AppearanceOptions.SetSelectedBar then
    ns.AppearanceOptions.SetSelectedBar("resource", barNumber)
  end
  
  -- Refresh and switch to Appearance tab
  local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
  
  -- Refresh the options to show updated selection
  AceConfigRegistry:NotifyChange("ArcUI")
  
  -- Select the appearance tab under resources
  AceConfigDialog:SelectGroup("ArcUI", "resources", "appearance")
end

-- ===================================================================
-- SET PREVIEW VALUE (for live preview in appearance options)
-- ===================================================================
function ns.Resources.SetPreviewValue(barNumber, previewValue)
  local cfg = ns.API.GetResourceBarConfig(barNumber)
  if not cfg then return end
  
  local mainFrame, textFrame = GetResourceFrames(barNumber)
  if not mainFrame then return end
  
  -- Calculate correct maxValue for preview
  local maxValue
  local resourceCategory = cfg.tracking.resourceCategory or "primary"
  if resourceCategory == "secondary" then
    maxValue = cfg.tracking.maxValue or 100
  else
    -- PRIMARY: Use UnitPowerMax
    local powerType = cfg.tracking.powerType or 0
    maxValue = UnitPowerMax("player", powerType)
    if not maxValue or maxValue <= 0 then
      maxValue = cfg.tracking.maxValue or 100
    end
  end
  
  -- Call UpdateThresholdLayers with the preview value AND maxValue
  UpdateThresholdLayers(barNumber, previewValue, maxValue)
  
  -- Update text
  if cfg.display.showText and textFrame and textFrame.text then
    textFrame.text:SetText(previewValue)
  end
  
  -- Make sure bar is visible for preview
  mainFrame:Show()
  if cfg.display.showText then
    textFrame:Show()
  end
end

-- ===================================================================
-- EVENT HANDLING
-- ===================================================================
local eventFrame = CreateFrame("Frame")
local isInitialized = false

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UNIT_POWER_FREQUENT")
eventFrame:RegisterEvent("UNIT_MAXPOWER")
eventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")  -- For spec-based visibility
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")  -- Talent changes can affect max resource

-- Secondary resource specific events
eventFrame:RegisterEvent("RUNE_POWER_UPDATE")           -- Death Knight runes
eventFrame:RegisterEvent("UNIT_POWER_POINT_CHARGE")     -- Evoker essence charging
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")      -- Druid form changes
eventFrame:RegisterEvent("UNIT_HEALTH")                 -- For Stagger (based on health)
eventFrame:RegisterEvent("UNIT_MAXHEALTH")              -- For Stagger max

-- Safe initialization - waits for DB to be ready
local function TryInitialize()
  -- Check if DB functions exist and DB is loaded
  if not ns.API or not ns.API.GetDB then
    return false
  end
  
  local db = ns.API.GetDB()
  if not db then
    return false
  end
  
  -- DB is ready - initialize!
  isInitialized = true
  ns.Resources.ApplyAllBars()
  
  return true
end

-- Retry initialization until successful
local function InitWithRetry(attempts)
  attempts = attempts or 0
  
  if TryInitialize() then
    return  -- Success!
  end
  
  -- Retry up to 10 times (5 seconds total)
  if attempts < 10 then
    C_Timer.After(0.5, function()
      InitWithRetry(attempts + 1)
    end)
  end
end

-- Check if a bar tracks a specific secondary type
local function BarTracksSecondaryType(barNumber, secondaryType)
  local cfg = ns.API.GetResourceBarConfig(barNumber)
  if not cfg or not cfg.tracking.enabled then return false end
  if cfg.tracking.resourceCategory ~= "secondary" then return false end
  return cfg.tracking.secondaryType == secondaryType
end

-- Update all bars that track a specific secondary type
local function UpdateBarsForSecondaryType(secondaryType)
  if not isInitialized then return end
  if not ns.API.GetActiveResourceBars then return end
  
  local activeBars = ns.API.GetActiveResourceBars()
  for _, barNumber in ipairs(activeBars) do
    if BarTracksSecondaryType(barNumber, secondaryType) then
      ns.Resources.UpdateBar(barNumber)
    end
  end
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    -- Addon loaded, but DB might not be ready yet
    -- Start retry loop
    C_Timer.After(0.5, function()
      InitWithRetry()
    end)
    
  elseif event == "PLAYER_LOGIN" then
    -- Player is logged in, UnitPower() should work now
    -- Try to initialize if not already done
    C_Timer.After(1.0, function()
      if not isInitialized then
        InitWithRetry()
      else
        -- Already initialized, update max values and refresh
        ns.Resources.UpdateMaxValues()
        ns.Resources.UpdateAllBars()
      end
    end)
    
  elseif event == "UNIT_POWER_FREQUENT" and arg1 == "player" then
    if not isInitialized then return end
    
    -- Update all resource bars that track this power type
    if not ns.API.GetActiveResourceBars then return end
    
    local powerToken = arg2
    local activeBars = ns.API.GetActiveResourceBars()
    for _, barNumber in ipairs(activeBars) do
      local cfg = ns.API.GetResourceBarConfig(barNumber)
      if cfg and cfg.tracking.enabled then
        local resourceCategory = cfg.tracking.resourceCategory or "primary"
        
        if resourceCategory == "primary" then
          -- Primary resource: check power type token
          local powerType = cfg.tracking.powerType
          local expectedToken = nil
          for _, pt in ipairs(ns.Resources.PowerTypes) do
            if pt.id == powerType then
              expectedToken = pt.token
              break
            end
          end
          
          if powerToken == expectedToken then
            ns.Resources.UpdateBar(barNumber)
          end
        else
          -- Secondary resource: check if token matches
          local secondaryType = cfg.tracking.secondaryType
          local typeInfo = ns.Resources.SecondaryTypesLookup[secondaryType]
          if typeInfo and typeInfo.powerType then
            local powerTypeEnum = typeInfo.powerType
            -- Match token to Enum
            local tokenMatches = false
            if powerToken == "COMBO_POINTS" and secondaryType == "comboPoints" then tokenMatches = true
            elseif powerToken == "HOLY_POWER" and secondaryType == "holyPower" then tokenMatches = true
            elseif powerToken == "CHI" and secondaryType == "chi" then tokenMatches = true
            elseif powerToken == "SOUL_SHARDS" and secondaryType == "soulShards" then tokenMatches = true
            elseif powerToken == "ESSENCE" and secondaryType == "essence" then tokenMatches = true
            elseif powerToken == "ARCANE_CHARGES" and secondaryType == "arcaneCharges" then tokenMatches = true
            elseif powerToken == "RUNES" and secondaryType == "runes" then tokenMatches = true
            end
            
            if tokenMatches then
              ns.Resources.UpdateBar(barNumber)
            end
          end
        end
      end
    end
    
  elseif event == "RUNE_POWER_UPDATE" then
    -- Death Knight rune update
    UpdateBarsForSecondaryType("runes")
    
  elseif event == "UNIT_POWER_POINT_CHARGE" and arg1 == "player" then
    -- Evoker essence charging
    UpdateBarsForSecondaryType("essence")
    
  elseif event == "UPDATE_SHAPESHIFT_FORM" then
    -- Druid form change - may affect combo points availability
    if not isInitialized then return end
    C_Timer.After(0.1, function()
      ns.Resources.UpdateAllBars()
    end)
    
  elseif event == "UNIT_HEALTH" and arg1 == "player" then
    -- Stagger is based on health percentage
    UpdateBarsForSecondaryType("stagger")
    
  elseif event == "UNIT_MAXHEALTH" and arg1 == "player" then
    -- Stagger max changes with max health
    UpdateBarsForSecondaryType("stagger")
    
  elseif event == "UNIT_MAXPOWER" and arg1 == "player" then
    if not isInitialized then return end
    ns.Resources.UpdateAllBars()
    
  elseif event == "UNIT_DISPLAYPOWER" and arg1 == "player" then
    if not isInitialized then return end
    ns.Resources.UpdateAllBars()
    
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Entering world (login, reload, zone change)
    C_Timer.After(1.5, function()
      if isInitialized then
        ns.Resources.UpdateMaxValues()
        ns.Resources.ApplyAllBars()
      else
        InitWithRetry()
      end
    end)
    
  elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
    if not isInitialized then return end
    ns.Resources.UpdateAllBars()
    
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    -- Spec changed - refresh all bar visibility and update max values
    if not isInitialized then return end
    C_Timer.After(0.1, function()
      ns.Resources.UpdateMaxValues()
      ns.Resources.RefreshAllBars()
    end)
    
  elseif event == "TRAIT_CONFIG_UPDATED" then
    -- Talent changed - may affect max resource values
    if not isInitialized then return end
    C_Timer.After(0.2, function()
      ns.Resources.UpdateMaxValues()
      ns.Resources.UpdateAllBars()
    end)
  end
end)

-- ===================================================================
-- UPDATE MAX VALUES
-- ===================================================================
function ns.Resources.UpdateMaxValues()
  local db = ns.API.GetDB()
  if not db or not db.resourceBars then return end
  
  -- Cache max power values for ColorCurve numeric threshold conversion
  ns.Resources.CacheAllMaxPowerValues()
  
  -- Get active bars and also check bars 1-30 for any enabled
  local activeBars = ns.API.GetActiveResourceBars and ns.API.GetActiveResourceBars() or {}
  local checkedBars = {}
  for _, barNum in ipairs(activeBars) do
    checkedBars[barNum] = true
  end
  for i = 1, 30 do
    checkedBars[i] = true
  end
  
  for barNumber, _ in pairs(checkedBars) do
    local cfg = ns.API.GetResourceBarConfig(barNumber)
    if cfg and cfg.tracking.enabled then
      local resourceCategory = cfg.tracking.resourceCategory or "primary"
      
      if cfg.tracking.overrideMax then
        -- User wants manual control, don't auto-update
      elseif resourceCategory == "secondary" then
        -- Secondary resource max
        local secondaryType = cfg.tracking.secondaryType
        if secondaryType then
          local newMax = ns.Resources.GetSecondaryMaxValue(secondaryType)
          if newMax and newMax > 0 and newMax ~= cfg.tracking.maxValue then
            local oldMax = cfg.tracking.maxValue or 5
            cfg.tracking.maxValue = newMax
            
            -- Only rescale thresholds if thresholdAsPercent is enabled
            if cfg.display.thresholdAsPercent and cfg.thresholds and oldMax > 0 then
              for _, threshold in ipairs(cfg.thresholds) do
                threshold.minValue = math.floor((threshold.minValue / oldMax) * newMax)
                threshold.maxValue = math.floor((threshold.maxValue / oldMax) * newMax)
              end
            end
          end
        end
      else
        -- Primary resource max
        local powerType = cfg.tracking.powerType
        
        -- Guard: powerType must be valid (>= 0)
        if not powerType or powerType < 0 then
          -- Skip this bar, invalid powerType
        else
          local newMax = UnitPowerMax("player", powerType)
          if newMax and newMax > 0 and newMax ~= cfg.tracking.maxValue then
            local oldMax = cfg.tracking.maxValue or 100
            cfg.tracking.maxValue = newMax
            
            -- Only rescale thresholds if thresholdAsPercent is enabled
            if cfg.display.thresholdAsPercent and cfg.thresholds and oldMax > 0 then
              for _, threshold in ipairs(cfg.thresholds) do
                threshold.minValue = math.floor((threshold.minValue / oldMax) * newMax)
                threshold.maxValue = math.floor((threshold.maxValue / oldMax) * newMax)
              end
            end
          end
        end
      end
    end
  end
end

-- ===================================================================
-- DELETE CONFIRMATION DIALOG
-- ===================================================================
local resourceDeleteConfirmFrame = nil

ShowResourceDeleteConfirmation = function(barNumber)
  if not resourceDeleteConfirmFrame then
    resourceDeleteConfirmFrame = CreateFrame("Frame", "ArcUIResourceDeleteConfirm", UIParent, "BackdropTemplate")
    resourceDeleteConfirmFrame:SetSize(300, 120)
    resourceDeleteConfirmFrame:SetFrameStrata("TOOLTIP")
    resourceDeleteConfirmFrame:SetToplevel(true)
    resourceDeleteConfirmFrame:SetFrameLevel(9999)
    resourceDeleteConfirmFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    resourceDeleteConfirmFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    resourceDeleteConfirmFrame:EnableMouse(true)
    resourceDeleteConfirmFrame:SetMovable(true)
    resourceDeleteConfirmFrame:RegisterForDrag("LeftButton")
    resourceDeleteConfirmFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    resourceDeleteConfirmFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    resourceDeleteConfirmFrame:SetClampedToScreen(true)
    
    resourceDeleteConfirmFrame.title = resourceDeleteConfirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    resourceDeleteConfirmFrame.title:SetPoint("TOP", 0, -16)
    resourceDeleteConfirmFrame.title:SetText("Delete Resource Bar?")
    
    resourceDeleteConfirmFrame.text = resourceDeleteConfirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resourceDeleteConfirmFrame.text:SetPoint("TOP", 0, -40)
    resourceDeleteConfirmFrame.text:SetWidth(260)
    
    resourceDeleteConfirmFrame.deleteBtn = CreateFrame("Button", nil, resourceDeleteConfirmFrame, "UIPanelButtonTemplate")
    resourceDeleteConfirmFrame.deleteBtn:SetSize(100, 24)
    resourceDeleteConfirmFrame.deleteBtn:SetPoint("BOTTOMLEFT", 30, 16)
    resourceDeleteConfirmFrame.deleteBtn:SetText("Delete")
    
    resourceDeleteConfirmFrame.cancelBtn = CreateFrame("Button", nil, resourceDeleteConfirmFrame, "UIPanelButtonTemplate")
    resourceDeleteConfirmFrame.cancelBtn:SetSize(100, 24)
    resourceDeleteConfirmFrame.cancelBtn:SetPoint("BOTTOMRIGHT", -30, 16)
    resourceDeleteConfirmFrame.cancelBtn:SetText("Cancel")
    resourceDeleteConfirmFrame.cancelBtn:SetScript("OnClick", function() resourceDeleteConfirmFrame:Hide() end)
  end
  
  -- Get bar name for display
  local barName = "Resource Bar " .. barNumber
  local cfg = ns.API and ns.API.GetResourceBarConfig and ns.API.GetResourceBarConfig(barNumber)
  if cfg and cfg.tracking and cfg.tracking.powerName and cfg.tracking.powerName ~= "" then
    barName = cfg.tracking.powerName
  end
  
  resourceDeleteConfirmFrame.text:SetText(string.format("Delete %s?", barName))
  resourceDeleteConfirmFrame.deleteBtn:SetScript("OnClick", function()
    ns.Resources.DeleteBar(barNumber)
    resourceDeleteConfirmFrame:Hide()
  end)
  
  resourceDeleteConfirmFrame:ClearAllPoints()
  resourceDeleteConfirmFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
  resourceDeleteConfirmFrame:Raise()
  resourceDeleteConfirmFrame:Show()
end

-- Expose for external use
ns.Resources.ShowDeleteConfirmation = ShowResourceDeleteConfirmation

-- ===================================================================
-- DELETE RESOURCE BAR (Clear config and hide)
-- ===================================================================
function ns.Resources.DeleteBar(barNumber)
  local cfg = ns.API and ns.API.GetResourceBarConfig and ns.API.GetResourceBarConfig(barNumber)
  if cfg then
    -- Clear tracking config
    cfg.tracking.enabled = false
    cfg.tracking.resourceCategory = "primary"
    cfg.tracking.powerType = 0
    cfg.tracking.secondaryType = nil
    cfg.tracking.powerName = ""
    cfg.display.enabled = false
    
    -- Hide the bar
    local mainFrame, textFrame = GetResourceFrames(barNumber)
    if mainFrame then mainFrame:Hide() end
    if textFrame then textFrame:Hide() end
    
    -- Refresh options panel
    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end
  end
end

-- ===================================================================
-- SHOW/HIDE DELETE BUTTONS ON ALL RESOURCE BARS
-- Only visible when options panel is open
-- ===================================================================

function ns.Resources.ShowDeleteButtons()
  deleteButtonsVisible = true
  for barNumber = 1, 10 do
    local mainFrame, textFrame = GetResourceFrames(barNumber)
    if mainFrame and mainFrame:IsShown() and mainFrame.deleteButton then
      mainFrame.deleteButton:Show()
    end
  end
end

function ns.Resources.HideDeleteButtons()
  deleteButtonsVisible = false
  for barNumber = 1, 10 do
    local mainFrame, textFrame = GetResourceFrames(barNumber)
    if mainFrame and mainFrame.deleteButton then
      mainFrame.deleteButton:Hide()
    end
  end
end

function ns.Resources.AreDeleteButtonsVisible()
  return deleteButtonsVisible
end

-- ===================================================================
-- INITIALIZATION (Backup)
-- ===================================================================
-- This is a backup in case events don't fire properly
C_Timer.After(3.0, function()
  if not isInitialized then
    InitWithRetry()
  end
end)

-- ===================================================================
-- END OF ArcUI_Resources.lua
-- ===================================================================