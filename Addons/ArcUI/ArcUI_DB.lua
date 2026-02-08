-- ===================================================================
-- ArcUI_DB.lua
-- Database structure with support for multiple bar slots, resource bars,
-- and cooldown bars (charge-based ability tracking)
-- v2.8.0: Added ColorCurve threshold support for duration bars
-- ===================================================================

local ADDON, ns = ...
ns.API = ns.API or {}  -- Initialize API table

-- ===================================================================
-- DEFAULT THRESHOLD PRESETS
-- ===================================================================
local DEFAULT_THRESHOLDS = {
  simple = {
    { enabled = true, minValue = 0, maxValue = 100, color = {r=0, g=0.8, b=1, a=1} }
  },
  threshold = {
    { enabled = true, minValue = 0,  maxValue = 100, color = {r=1, g=0, b=0, a=1} },
    { enabled = true, minValue = 50, maxValue = 100, color = {r=1, g=1, b=0, a=1} },
    { enabled = true, minValue = 80, maxValue = 100, color = {r=0, g=1, b=0, a=1} },
    { enabled = false, minValue = 50, color = {r=1, g=0.5, b=0, a=1} },
    { enabled = false, minValue = 70, color = {r=0.5, g=0, b=1, a=1} },
    { enabled = false, minValue = 90, color = {r=1, g=0, b=1, a=1} }
  }
}

ns.DB_DEFAULTS = {
  global = {
    profileSnapshots = {},
    migrationWarningSeen = false,
    minimap = {
      hide = false,
      minimapPos = 220,
      radius = 80
    },
    menuBackgroundAlpha = 1.0,
    -- CDM Master Kill Switch - stored in global so it's checked before CDM modules init
    cdmStylingEnabled = true,
    -- Pending CDM profiles from master import (for classes not yet logged)
    masterCDMPending = nil,
  },
  
  -- Profile storage (shared across characters using same profile)
  profile = {
    -- CDM Enhancement settings (per-profile for cross-character use)
    cdmEnhance = {
      enabled = true,
      enableAuraCustomization = true,
      enableCooldownCustomization = true,
      unlocked = false,
      textDragMode = false,
      iconSettings = {},        -- [cooldownID] = { per-icon settings }
      globalAuraSettings = {},  -- Default settings for all aura icons
      globalCooldownSettings = {}, -- Default settings for all cooldown icons
      globalApplyScale = false,
      globalApplyHideShadow = false,
      groupSettings = {         -- Group-level settings per viewer type
        aura = { padding = nil, scale = nil },
        cooldown = { padding = nil, scale = nil },
        utility = { padding = nil, scale = nil },
      },
    },
    -- CDM Groups settings (per-profile for cross-character use)
    cdmGroups = {
      specData = {},        -- [specIndex] = { groups = {}, savedPositions = {}, freeIcons = {} }
      specInheritedFrom = {},
      lastActiveSpec = nil,
    },
  },
  
  char = {
    -- NOTE: cdmGroups is NOT in defaults anymore!
    -- We manage cdmGroups storage directly in ArcUIDB.char[charKey].cdmGroups
    -- to bypass AceDB's removeDefaults which strips our nested specData.
    -- See ArcUI_CDM_Shared.lua GetCDMGroupsDB() for the storage implementation.
    
    selectedBar = 1,
    selectedResourceBar = 1,
    selectedCooldownBar = 1,
    
    -- Array of buff/debuff bar configurations (up to 30 bars)
    bars = {
      [1] = {
        tracking = {
          enabled = false,
          trackType = "buff",
          spellID = 0,
          buffName = "",
          iconTextureID = 0,
          cooldownID = 0,
          alternateCooldownIDs = {},  -- Additional cooldownIDs for cross-spec support
          slotNumber = 0,
          maxStacks = 10,
          auraInstanceID = 0,
          useBaseSpell = false,  -- Ignore CDM override spell, use base spell for icon
          customEnabled = false,
          customSpellID = 0,
          customDuration = 10,
          customStacksPerCast = 1,
          customMaxStacks = 10,
          customRefreshMode = "add",
          sourceType = "icon",
          useDurationBar = false,
          dynamicMaxDuration = false,
          maxDuration = 30,
        },
        display = {
          enabled = true,
          displayMode = "single",
          width = 200,
          height = 20,
          barScale = 1.0,
          opacity = 1.0,
          
          displayType = "bar",
          iconSize = 48,
          iconShowTexture = true,
          iconShowStacks = true,
          iconStackAnchor = "TOPRIGHT",
          iconStackPosition = nil,
          iconStackFont = "2002 Bold",
          iconStackFontSize = 16,
          iconStackColor = {r=1, g=1, b=1, a=1},
          iconStackOutline = "THICKOUTLINE",
          iconStackShadow = false,
          iconShowDuration = true,
          iconDurationFont = "2002 Bold",
          iconDurationFontSize = 14,
          iconDurationColor = {r=1, g=1, b=1, a=1},
          iconDurationOutline = "THICKOUTLINE",
          iconDurationShadow = false,
          iconShowBorder = true,
          iconBorderColor = {r=0, g=0, b=0, a=1},
          iconMultiMode = false,
          iconMultiFreeMode = false,
          iconMultiLockPositions = false,
          iconMultiShowDesatBg = true,
          iconMultiSpacing = 4,
          iconMultiDirection = "RIGHT",
          iconMultiPositions = {},
          iconMultiShowDurationOn = 1,
          iconMultiDurationAnchor = "BOTTOM",
          
          -- ═══════════════════════════════════════════════════════════════
          -- CUSTOM TRACKING DISPLAY OPTIONS (for customAura/customCooldown)
          -- ═══════════════════════════════════════════════════════════════
          -- Cooldown Swipe (COOLDOWNS ONLY)
          iconShowCooldownSwipe = true,
          iconCooldownReverse = false,
          iconCooldownDrawEdge = true,
          iconCooldownDrawBling = true,
          
          -- Desaturation options
          iconDesaturateOnCooldown = true,
          iconDesaturateWhenInactive = false,
          
          -- Icon Zoom (crop edges)
          iconZoom = 0,
          
          texture = "Blizzard",
          fillTextureScale = 1.0,
          barOrientation = "horizontal",  -- "horizontal" or "vertical"
          barReverseFill = false,         -- Reverse fill direction (right-to-left / top-to-bottom)
          useGradient = false,
          gradientSecondColor = {r=0, g=0, b=0, a=0.5},  -- Second color for gradient (darker by default)
          gradientDirection = "VERTICAL",  -- "VERTICAL" or "HORIZONTAL"
          gradientIntensity = 0.5,  -- How much the second color affects the gradient (0-1)
          barColor = {r=0, g=0.5, b=1, a=1},
          thresholdMode = "simple",
          fragmentedSpacing = 2,
          fragmentedColors = {},
          fragmentedChargingColor = {r=0.4, g=0.4, b=0.4, a=1},
          fragmentedShowSegmentText = false,
          fragmentedTextSize = 10,
          -- Icons mode settings (for secondary resources like Runes/Essence)
          iconsMode = "row",  -- "row" or "freeform"
          iconsSize = 32,
          iconsSpacing = 4,
          iconsShape = "square",  -- "square" or "circle"
          iconsPositions = {},  -- saved positions for freeform mode
          iconsShowCooldownText = true,
          iconsCooldownTextSize = 12,
          enableMaxColor = false,
          maxColor = {r=0, g=1, b=0, a=1},
          foldedColor1 = {r=0, g=0.5, b=1, a=1},
          foldedColor2 = {r=0, g=1, b=0, a=1},
          enableSmoothing = false,
          showBackground = true,
          backgroundColor = {r=0.2, g=0.2, b=0.2, a=0.8},
          showBorder = true,
          borderStyle = "Drawn",
          drawnBorderThickness = 2,
          borderColor = {r=0, g=0, b=0, a=1},
          showTickMarks = true,
          tickMode = "all",
          tickThickness = 1,
          tickColor = {r=0, g=0, b=0, a=1},
          showText = true,
          font = "2002 Bold",
          fontSize = 24,
          textColor = {r=1, g=1, b=1, a=1},
          textOutline = "THICKOUTLINE",
          textShadow = false,
          textAnchor = "OUTERTOP",
          textAnchorOffsetX = 0,
          textAnchorOffsetY = 0,
          showDuration = false,
          durationFont = "2002 Bold",
          durationFontSize = 18,
          durationColor = {r=1, g=1, b=1, a=1},
          durationOutline = "THICKOUTLINE",
          durationShadow = false,
          durationAnchor = "CENTER",
          durationAnchorOffsetX = 0,
          durationAnchorOffsetY = 0,
          durationDecimals = 1,
          durationShowWhenReady = false,
          
          -- ═══════════════════════════════════════════════════════════════
          -- DURATION BAR COLORCURVE THRESHOLD SETTINGS (v2.8.0)
          -- Uses WoW 12.0 ColorCurve API for secret-safe color transitions
          -- ═══════════════════════════════════════════════════════════════
          durationColorCurveEnabled = false,       -- Enable ColorCurve thresholds
          durationColorCurveMode = "step",         -- "step" (threshold) or "gradient"
          durationColorCurveThreshold = 0.30,      -- Percentage (0-1) for threshold
          durationColorCurveLowColor = {r=1, g=0, b=0, a=1},   -- Color below threshold (red)
          durationColorCurveHighColor = {r=0, g=1, b=0, a=1},  -- Color at/above threshold (green)
          durationColorCurveMidColor = {r=1, g=1, b=0, a=1},   -- Mid color for gradient mode (yellow)
          durationBarFillMode = "drain",   -- "drain" (shrinks as time passes) or "fill" (grows as time passes)
          
          showName = false,
          nameFont = "2002 Bold",
          nameFontSize = 14,
          nameColor = {r=1, g=1, b=1, a=1},
          nameOutline = "THICKOUTLINE",
          nameShadow = false,
          nameAnchor = "CENTER",
          nameAnchorOffsetX = 0,
          nameAnchorOffsetY = 0,
          showBarIcon = false,
          barIconSize = 32,
          barIconAnchor = "LEFT",
          barIconAnchorOffsetX = 0,
          barIconAnchorOffsetY = 0,
          barIconShowBorder = true,
          barIconBorderColor = {r=0, g=0, b=0, a=1},
          barMovable = true,
          textMovable = true,
          barPosition = {
            point = "CENTER",
            relPoint = "CENTER",
            x = 0,
            y = 200
          },
          textPosition = {
            point = "CENTER",
            relPoint = "CENTER",
            x = 0,
            y = 230
          },
          -- Frame strata settings
          barFrameStrata = "MEDIUM",
          barFrameLevel = 10,
        },
        behavior = {
          hideBuffIcon = false,
          hideWhenZeroStacks = false,
          hideWhenInactive = false,
          hideOutOfCombat = false,
          showOnSpec = 0,
          showOnSpecs = {}
        },
        thresholds = {
          [1] = { enabled = true, minValue = 0, maxValue = 10, color = {r=0, g=0.5, b=1, a=1} },
          [2] = { enabled = false, minValue = 5, maxValue = 10, color = {r=1, g=1, b=0, a=1} },
          [3] = { enabled = false, minValue = 8, maxValue = 10, color = {r=0, g=1, b=0, a=1} }
        },
        stackColors = {},
        colorRanges = {
          [1] = { from = 1, to = 4, color = {r=0, g=0.5, b=1, a=1} },
          [2] = { enabled = false, from = 5, to = 8, color = {r=1, g=1, b=0, a=1} },
          [3] = { enabled = false, from = 9, to = 12, color = {r=0, g=1, b=0, a=1} }
        },
        
        -- ═══════════════════════════════════════════════════════════════
        -- CONDITIONAL EVENTS (for customAura/customCooldown)
        -- ═══════════════════════════════════════════════════════════════
        events = {},
      },
    },
    
    -- ===============================================================
    -- RESOURCE BARS (Primary AND Secondary resources with threshold color layers)
    -- v2.6.0: Added resourceCategory, secondaryType for secondary resource support
    -- ===============================================================
    resourceBars = {
      [1] = {
        tracking = {
          enabled = false,
          resourceCategory = "primary",  -- "primary" or "secondary"
          powerType = 0,                 -- For primary resources (Enum.PowerType)
          secondaryType = nil,           -- For secondary: "comboPoints", "holyPower", "chi", "runes", "soulShards", "essence", "arcaneCharges", "stagger", "soulFragments"
          powerName = "",
          maxValue = 100,
          overrideMax = false,
          -- Rune-specific settings
          showRuneTimer = false,         -- Show time until next rune ready
        },
        thresholds = {
          { enabled = true, minValue = 0, maxValue = 100, color = {r=0, g=0.8, b=1, a=1} },
          { enabled = false, minValue = 50, maxValue = 100, color = {r=1, g=1, b=0, a=1} },
          { enabled = false, minValue = 80, maxValue = 100, color = {r=0, g=1, b=0, a=1} }
        },
        abilityThresholds = {},
        display = {
          enabled = true,
          thresholdMode = "simple",
          enableMaxColor = false,
          maxColor = {r=0, g=1, b=0, a=1},
          foldedColor1 = {r=0, g=0.5, b=1, a=1},
          foldedColor2 = {r=0, g=1, b=0, a=1},
          enableSmoothing = false,
          width = 250,
          height = 25,
          barScale = 1.0,
          opacity = 1.0,
          
          texture = "Blizzard",
          fillTextureScale = 1.0,
          barOrientation = "horizontal",  -- "horizontal" or "vertical"
          barReverseFill = false,         -- Reverse fill direction
          showBackground = true,
          backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9},
          showBorder = true,
          drawnBorderThickness = 2,
          borderColor = {r=0, g=0, b=0, a=1},
          showTickMarks = false,
          tickMode = "all",
          tickThickness = 2,
          tickColor = {r=1, g=1, b=1, a=0.8},
          showText = true,
          textFormat = "value",  -- "value" or "percent"
          font = "Friz Quadrata TT",
          fontSize = 20,
          textColor = {r=1, g=1, b=1, a=1},
          textAnchor = "OUTERTOP",
          textAnchorOffsetX = 0,
          textAnchorOffsetY = 0,
          barMovable = true,
          textMovable = true,
          barPosition = {
            point = "CENTER",
            relPoint = "CENTER",
            x = 0,
            y = -100
          },
          textPosition = {
            point = "CENTER",
            relPoint = "CENTER",
            x = 0,
            y = -70
          },
          -- Frame strata settings
          barFrameStrata = "MEDIUM",
          barFrameLevel = 10,
        },
        behavior = {
          hideOutOfCombat = false,
          hideWhenFull = false,
          hideWhenEmpty = false,
          showOnSpec = 0,
          showOnSpecs = {}
        }
      }
    },
    
    -- ===============================================================
    -- COOLDOWN BARS (Charge-based ability tracking)
    -- Structure mirrors buff bars for Appearance panel compatibility
    -- ===============================================================
    cooldownBars = {
      [1] = {
        tracking = {
          enabled = false,
          cooldownID = 0,
          spellID = 0,
          spellName = "",
          buffName = "",  -- Alias for spellName (display compatibility)
          iconTextureID = 0,
          maxStacks = 3,  -- Max charges
          trackType = "charge",
        },
        display = {
          enabled = true,
          displayType = "bar",  -- "bar" or "icon"
          
          -- Size
          width = 200,
          height = 20,
          barScale = 1.0,
          opacity = 1.0,
          
          
          -- Icon Mode Settings
          iconSize = 48,
          iconShowTexture = true,
          iconShowStacks = true,
          iconStackAnchor = "TOPRIGHT",
          iconStackPosition = nil,
          iconStackFont = "2002 Bold",
          iconStackFontSize = 16,
          iconStackColor = {r=1, g=1, b=1, a=1},
          iconStackOutline = "THICKOUTLINE",
          iconStackShadow = false,
          iconShowBorder = true,
          iconBorderColor = {r=0, g=0, b=0, a=1},
          
          -- Texture and fill
          texture = "Blizzard",
          fillTextureScale = 1.0,
          barOrientation = "horizontal",  -- "horizontal" or "vertical"
          barReverseFill = false,         -- Reverse fill direction
          
          -- Colors
          useGradient = false,
          barColor = {r=0.2, g=0.8, b=1, a=1},
          thresholdMode = "simple",
          enableMaxColor = false,
          maxColor = {r=0, g=1, b=0, a=1},
          
          -- Background
          showBackground = true,
          backgroundColor = {r=0.2, g=0.2, b=0.2, a=0.8},
          
          -- Border
          showBorder = true,
          borderStyle = "Drawn",
          drawnBorderThickness = 2,
          borderColor = {r=0, g=0, b=0, a=1},
          
          -- Tick marks
          showTickMarks = true,
          tickMode = "all",
          tickThickness = 1,
          tickColor = {r=0, g=0, b=0, a=1},
          
          -- Stack/Charge Text
          showText = true,
          font = "2002 Bold",
          fontSize = 18,
          textColor = {r=1, g=1, b=1, a=1},
          textOutline = "THICKOUTLINE",
          textShadow = false,
          textAnchor = "CENTER",
          textAnchorOffsetX = 0,
          textAnchorOffsetY = 0,
          
          -- Bar Icon
          showBarIcon = true,
          barIconSize = 20,
          barIconAnchor = "LEFT",
          barIconAnchorOffsetX = 0,
          barIconAnchorOffsetY = 0,
          barIconShowBorder = true,
          barIconBorderColor = {r=0, g=0, b=0, a=1},
          
          -- Position
          barMovable = true,
          textMovable = true,
          barPosition = {
            point = "CENTER",
            relPoint = "CENTER",
            x = 0,
            y = -200
          },
          textPosition = {
            point = "CENTER",
            relPoint = "CENTER",
            x = 0,
            y = -170
          },
          iconPosition = {
            point = "CENTER",
            relPoint = "CENTER",
            x = 0,
            y = -200
          },
          -- Frame strata settings
          barFrameStrata = "MEDIUM",
          barFrameLevel = 10,
        },
        behavior = {
          hideOutOfCombat = false,
          hideWhenFull = false,
          hideWhenZero = false,
          showOnSpec = 0,
          showOnSpecs = {},
          talentConditions = nil,
          talentMatchMode = nil,
        },
        thresholds = {
          [1] = { enabled = true, minValue = 0, maxValue = 3, color = {r=0.2, g=0.8, b=1, a=1} },
          [2] = { enabled = false, minValue = 2, maxValue = 3, color = {r=1, g=1, b=0, a=1} },
          [3] = { enabled = false, minValue = 3, maxValue = 3, color = {r=0, g=1, b=0, a=1} }
        },
        stackColors = {},
        colorRanges = {
          [1] = { from = 1, to = 1, color = {r=0.2, g=0.8, b=1, a=1} },
          [2] = { enabled = false, from = 2, to = 2, color = {r=1, g=1, b=0, a=1} },
          [3] = { enabled = false, from = 3, to = 3, color = {r=0, g=1, b=0, a=1} }
        }
      }
    },
    
    -- LEGACY: CDM Enhancement settings were moved to profile storage
    -- This stub exists only for migration purposes (CDMEnhance.lua migrates to profile)
    -- DO NOT add new fields here - use profile.cdmEnhance instead
    cdmEnhance = nil,
    
    -- Custom aura and cooldown definitions
    customDefinitions = {
      auras = {},     -- Custom aura definitions keyed by unique ID
      cooldowns = {}, -- Custom cooldown definitions keyed by unique ID
    },
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- COOLDOWN BAR SETUP (ArcUI_CooldownBars.lua active bar tracking)
    -- Stores which spells have bars created (spellID lists/maps)
    -- ═══════════════════════════════════════════════════════════════════════════
    cooldownBarSetup = {
      activeCooldowns = {},  -- {spellID, spellID, ...} - Duration bars
      activeCharges = {},    -- {spellID, spellID, ...} - Charge bars  
      activeResources = {},  -- {[spellID] = true, ...} - Resource bars
      manualSpells = {},     -- {spellID, ...} - Manually added spells
      hiddenSpells = {},     -- {[spellID] = true, ...} - Hidden from catalog
    },
    
    configVersion = 1
  }
}

-- Store presets for easy access
ns.ThresholdPresets = DEFAULT_THRESHOLDS

-- ===================================================================
-- HELPER: Get Bar Config (Buff/Debuff bars)
-- ===================================================================
function ns.API.GetBarConfig(barNumber)
  local db = ns.API.GetDB()
  if not db or not db.bars then return nil end
  
  barNumber = barNumber or db.selectedBar or 1
  
  if not db.bars[barNumber] then
    db.bars[barNumber] = CopyTable(ns.DB_DEFAULTS.char.bars[1])
    local yOffset = 200 - ((barNumber - 1) * 30)
    db.bars[barNumber].display.barPosition.y = yOffset
    db.bars[barNumber].display.textPosition.y = yOffset + 30
  end
  
  local barConfig = db.bars[barNumber]
  
  -- Skip migration if already done this session (major performance optimization)
  if barConfig._migrated then
    return barConfig
  end
  
  -- Migration: ensure events table exists
  if not barConfig.events then
    barConfig.events = {}
  end
  
  -- Migration: ensure new display options exist
  local display = barConfig.display
  if display.iconShowCooldownSwipe == nil then display.iconShowCooldownSwipe = true end
  if display.iconCooldownReverse == nil then display.iconCooldownReverse = false end
  if display.iconCooldownDrawEdge == nil then display.iconCooldownDrawEdge = true end
  if display.iconCooldownDrawBling == nil then display.iconCooldownDrawBling = true end
  if display.iconDesaturateOnCooldown == nil then display.iconDesaturateOnCooldown = true end
  if display.iconDesaturateWhenInactive == nil then display.iconDesaturateWhenInactive = false end
  if display.iconZoom == nil then display.iconZoom = 0 end
  if display.durationShowWhenReady == nil then display.durationShowWhenReady = false end
  -- v2.8.0: Migration for ColorCurve duration bar settings
  if display.durationColorCurveEnabled == nil then display.durationColorCurveEnabled = false end
  if display.durationColorCurveMode == nil then display.durationColorCurveMode = "step" end
  if display.durationColorCurveThreshold == nil then display.durationColorCurveThreshold = 0.30 end
  if display.durationColorCurveLowColor == nil then display.durationColorCurveLowColor = {r=1, g=0, b=0, a=1} end
  if display.durationColorCurveHighColor == nil then display.durationColorCurveHighColor = {r=0, g=1, b=0, a=1} end
  if display.durationColorCurveMidColor == nil then display.durationColorCurveMidColor = {r=1, g=1, b=0, a=1} end
  if display.durationBarFillMode == nil then display.durationBarFillMode = "drain" end
  -- Migration: fillDirection -> barOrientation
  if display.fillDirection and not display.barOrientation then
    -- Convert old 4-way direction to new orientation system
    if display.fillDirection == "BOTTOM_TO_TOP" or display.fillDirection == "TOP_TO_BOTTOM" then
      display.barOrientation = "vertical"
    else
      display.barOrientation = "horizontal"
    end
    display.fillDirection = nil  -- Remove old setting
  end
  if display.barOrientation == nil then display.barOrientation = "horizontal" end
  if display.barReverseFill == nil then display.barReverseFill = false end
  -- Migration: ensure text anchor defaults exist (prevents free-drag mode for old bars)
  if display.textAnchor == nil then display.textAnchor = "OUTERTOP" end
  if display.durationAnchor == nil then display.durationAnchor = "CENTER" end
  if display.nameAnchor == nil then display.nameAnchor = "CENTER" end
  if display.barIconAnchor == nil then display.barIconAnchor = "LEFT" end
  -- Migration: ensure frame strata defaults exist
  if display.barFrameStrata == nil then display.barFrameStrata = "MEDIUM" end
  if display.barFrameLevel == nil then display.barFrameLevel = 10 end
  
  -- Migration: ensure behavior table exists
  if not barConfig.behavior then
    barConfig.behavior = {
      hideBuffIcon = false,
      hideWhenZeroStacks = false,
      hideWhenInactive = false,
      hideOutOfCombat = false,
      showOnSpec = 0,
      showOnSpecs = {}
    }
  end
  
  -- Mark as migrated for this session
  barConfig._migrated = true
  
  return barConfig
end

-- ===================================================================
-- HELPER: Get Resource Bar Config
-- ===================================================================
function ns.API.GetResourceBarConfig(barNumber)
  local db = ns.API.GetDB()
  if not db then return nil end
  
  if not db.resourceBars then
    db.resourceBars = {}
  end
  
  barNumber = barNumber or db.selectedResourceBar or 1
  
  if not db.resourceBars[barNumber] then
    db.resourceBars[barNumber] = CopyTable(ns.DB_DEFAULTS.char.resourceBars[1])
    local yOffset = -100 - ((barNumber - 1) * 35)
    db.resourceBars[barNumber].display.barPosition.y = yOffset
    db.resourceBars[barNumber].display.textPosition.y = yOffset + 30
  end
  
  -- Migration: ensure new fields exist
  -- FORCE resourceCategory to primary (secondary resources not ready yet)
  db.resourceBars[barNumber].tracking.resourceCategory = "primary"
  
  return db.resourceBars[barNumber]
end

-- ===================================================================
-- HELPER: Get Cooldown Bar Config
-- ===================================================================
function ns.API.GetCooldownBarConfig(barNumber)
  local db = ns.API.GetDB()
  if not db then return nil end
  
  if not db.cooldownBars then
    db.cooldownBars = {}
  end
  
  barNumber = barNumber or db.selectedCooldownBar or 1
  
  if not db.cooldownBars[barNumber] then
    db.cooldownBars[barNumber] = CopyTable(ns.DB_DEFAULTS.char.cooldownBars[1])
    local yOffset = -200 - ((barNumber - 1) * 30)
    db.cooldownBars[barNumber].display.barPosition.y = yOffset
    db.cooldownBars[barNumber].display.textPosition.y = yOffset + 30
    db.cooldownBars[barNumber].display.iconPosition.y = yOffset
  end
  
  return db.cooldownBars[barNumber]
end

-- ===================================================================
-- HELPER: Get Selected Bar Number
-- ===================================================================
function ns.API.GetSelectedBar()
  local db = ns.API.GetDB()
  return db and db.selectedBar or 1
end

-- ===================================================================
-- HELPER: Set Selected Bar
-- ===================================================================
function ns.API.SetSelectedBar(barNumber)
  local db = ns.API.GetDB()
  if db then
    db.selectedBar = barNumber
  end
end

-- ===================================================================
-- HELPER: Get Selected Resource Bar Number
-- ===================================================================
function ns.API.GetSelectedResourceBar()
  local db = ns.API.GetDB()
  return db and db.selectedResourceBar or 1
end

-- ===================================================================
-- HELPER: Set Selected Resource Bar
-- ===================================================================
function ns.API.SetSelectedResourceBar(barNumber)
  local db = ns.API.GetDB()
  if db then
    db.selectedResourceBar = barNumber
  end
end

-- ===================================================================
-- HELPER: Get Selected Cooldown Bar Number
-- ===================================================================
function ns.API.GetSelectedCooldownBar()
  local db = ns.API.GetDB()
  return db and db.selectedCooldownBar or 1
end

-- ===================================================================
-- HELPER: Set Selected Cooldown Bar
-- ===================================================================
function ns.API.SetSelectedCooldownBar(barNumber)
  local db = ns.API.GetDB()
  if db then
    db.selectedCooldownBar = barNumber
  end
end

-- ===================================================================
-- HELPER: Get All Active Bars (Buff/Debuff)
-- ===================================================================
function ns.API.GetActiveBars()
  local db = ns.API.GetDB()
  if not db or not db.bars then return {} end
  
  local activeBars = {}
  for i = 1, 500 do
    if db.bars[i] and db.bars[i].tracking.enabled then
      table.insert(activeBars, i)
    end
  end
  
  return activeBars
end

-- ===================================================================
-- HELPER: Get All Active Resource Bars
-- ===================================================================
function ns.API.GetActiveResourceBars()
  local db = ns.API.GetDB()
  if not db or not db.resourceBars then return {} end
  
  local activeBars = {}
  for i = 1, 500 do
    if db.resourceBars[i] and db.resourceBars[i].tracking.enabled then
      table.insert(activeBars, i)
    end
  end
  
  return activeBars
end

-- ===================================================================
-- HELPER: Get All Active Cooldown Bars
-- ===================================================================
function ns.API.GetActiveCooldownBars()
  local db = ns.API.GetDB()
  if not db or not db.cooldownBars then return {} end
  
  local activeBars = {}
  for i = 1, 500 do
    if db.cooldownBars[i] and db.cooldownBars[i].tracking and db.cooldownBars[i].tracking.enabled then
      table.insert(activeBars, i)
    end
  end
  
  return activeBars
end

-- ===================================================================
-- HELPER: Apply Threshold Preset
-- ===================================================================
function ns.API.ApplyThresholdPreset(barNumber, presetName, maxValue)
  local cfg = ns.API.GetResourceBarConfig(barNumber)
  if not cfg then return false end
  
  local preset = ns.ThresholdPresets[presetName]
  if not preset then return false end
  
  cfg.thresholds = {}
  for i, threshold in ipairs(preset) do
    local scaled = CopyTable(threshold)
    scaled.minValue = math.floor((threshold.minValue / 100) * maxValue)
    scaled.maxValue = math.floor((threshold.maxValue / 100) * maxValue)
    cfg.thresholds[i] = scaled
  end
  
  return true
end

-- Initialize a new empty bar slot (makes it appear in UI)
function ns.API.InitializeNewBar()
  local db = ns.API.GetDB()
  if not db or not db.bars then return nil end
  
  for i = 1, 500 do
    if db.bars[i] and not db.bars[i].tracking.enabled then
      db.bars[i].tracking.enabled = true
      db.bars[i].tracking.buffName = "(Not configured yet)"
      db.bars[i].tracking.spellID = 0
      db.bars[i].tracking.maxStacks = 10
      
      if ns.Display and ns.Display.ShowBar then
        ns.Display.ShowBar(i)
      end
      
      return i
    end
  end
  
  return nil
end

-- ===================================================================
-- HELPER: Initialize New Resource Bar
-- ===================================================================
function ns.API.InitializeNewResourceBar(powerType, powerName, resourceCategory, secondaryType)
  local db = ns.API.GetDB()
  if not db then return nil end
  
  if not db.resourceBars then
    db.resourceBars = {}
  end
  
  resourceCategory = resourceCategory or "primary"
  
  for i = 1, 500 do
    local cfg = db.resourceBars[i]
    
    local isEmpty = not cfg or 
                    not cfg.tracking or 
                    not cfg.tracking.enabled or 
                    (not cfg.tracking.powerType and (not cfg.tracking.powerName or cfg.tracking.powerName == ""))
    
    if isEmpty then
      cfg = ns.API.GetResourceBarConfig(i)
      
      cfg.tracking.enabled = true
      cfg.tracking.resourceCategory = resourceCategory
      cfg.tracking.powerType = powerType
      cfg.tracking.secondaryType = secondaryType
      cfg.tracking.powerName = powerName
      
      -- Get max value based on resource type
      if resourceCategory == "secondary" and secondaryType then
        cfg.tracking.maxValue = ns.Resources and ns.Resources.GetSecondaryMaxValue(secondaryType) or 5
      else
        local max = UnitPowerMax("player", powerType)
        -- Use queried value if valid, otherwise default to 100 (will be updated at runtime)
        cfg.tracking.maxValue = (max and max > 0) and max or 100
      end
      
      if cfg.behavior then
        cfg.behavior.talentConditions = nil
        cfg.behavior.talentMatchMode = nil
        -- Set current spec so resource bar only shows on the spec it was created for
        cfg.behavior.showOnSpecs = { GetSpecialization() or 1 }
      end
      
      cfg.display.enabled = true
      
      -- Enable tick marks for discrete secondary resources
      if resourceCategory == "secondary" then
        local discreteTypes = {
          comboPoints = true, holyPower = true, chi = true,
          runes = true, soulShards = true, essence = true, arcaneCharges = true
        }
        if discreteTypes[secondaryType] then
          cfg.display.showTickMarks = true
          cfg.display.tickMode = "all"
        end
        
        -- Auto-enable fragmented mode for runes and essence
        local fragmentedTypes = {
          runes = true, essence = true
        }
        if fragmentedTypes[secondaryType] then
          cfg.display.thresholdMode = "fragmented"
          cfg.display.showTickMarks = false  -- No ticks needed for fragmented
          
          -- Set up per-segment colors for fragmented resources
          if not cfg.display.fragmentedColors then cfg.display.fragmentedColors = {} end
          
          if secondaryType == "runes" then
            -- DK Rune colors - each rune gets the same dark red by default
            local runeColor = {r=0.77, g=0.12, b=0.23, a=1}
            for j = 1, 6 do
              cfg.display.fragmentedColors[j] = {r=runeColor.r, g=runeColor.g, b=runeColor.b, a=runeColor.a}
            end
            cfg.display.fragmentedChargingColor = {r=0.4, g=0.4, b=0.4, a=1}
          elseif secondaryType == "essence" then
            -- Evoker Essence colors - bright teal
            local essenceColor = {r=0, g=0.8, b=0.8, a=1}
            for j = 1, 5 do
              cfg.display.fragmentedColors[j] = {r=essenceColor.r, g=essenceColor.g, b=essenceColor.b, a=essenceColor.a}
            end
            cfg.display.fragmentedChargingColor = {r=0, g=0.4, b=0.4, a=1}
          end
          
          -- Skip the standard preset
          if ns.Resources and ns.Resources.ApplyAppearance then
            ns.Resources.ApplyAppearance(i)
          end
          
          return i
        end
      end
      
      ns.API.ApplyThresholdPreset(i, "threeTone", cfg.tracking.maxValue)
      
      if ns.Resources and ns.Resources.ApplyAppearance then
        ns.Resources.ApplyAppearance(i)
      end
      
      return i
    end
  end
  
  return nil
end

-- ===================================================================
-- HELPER: Initialize New Cooldown Bar
-- ===================================================================
function ns.API.InitializeNewCooldownBar(cooldownID, spellID, spellName, maxCharges, iconTexture)
  local db = ns.API.GetDB()
  if not db then return nil end
  
  if not db.bars then
    db.bars = {}
  end
  
  -- Find an empty bar slot (cooldown bars share slots with regular bars)
  for i = 1, 500 do
    local cfg = db.bars[i]
    
    local isEmpty = not cfg or 
                    not cfg.tracking or 
                    not cfg.tracking.enabled
    
    if isEmpty then
      cfg = ns.API.GetBarConfig(i)
      
      cfg.tracking.enabled = true
      cfg.tracking.cooldownID = cooldownID
      cfg.tracking.spellID = spellID
      cfg.tracking.spellName = spellName
      cfg.tracking.buffName = spellName  -- For display compatibility
      cfg.tracking.iconTextureID = iconTexture or (spellID and C_Spell.GetSpellTexture(spellID)) or 134400
      cfg.tracking.maxStacks = maxCharges or 3
      cfg.tracking.trackType = "cooldownCharge"  -- CRITICAL: Use correct trackType
      
      cfg.display.enabled = true
      cfg.behavior.showOnSpecs = { GetSpecialization() or 1 }
      
      if ns.Display and ns.Display.ApplyAppearance then
        ns.Display.ApplyAppearance(i)
      end
      
      return i
    end
  end
  
  return nil
end

-- ===================================================================
-- END OF ArcUI_DB.lua
-- ===================================================================