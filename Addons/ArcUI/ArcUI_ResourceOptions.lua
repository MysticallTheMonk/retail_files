-- ===================================================================
-- ArcUI_ResourceOptions.lua
-- Options UI for Primary AND Secondary Resource bars with threshold color layers
-- v2.6.0: Added secondary resource support
-- ===================================================================

local ADDON, ns = ...
ns.ResourceOptions = ns.ResourceOptions or {}

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

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

local function GetFonts()
  local fonts = {["Friz Quadrata TT"] = "Friz Quadrata TT"}
  if LSM then
    for _, name in pairs(LSM:List("font")) do
      fonts[name] = name
    end
  end
  return fonts
end

local function GetPowerTypeDropdown()
  local dropdown = {}
  if ns.Resources and ns.Resources.PowerTypes then
    for _, pt in ipairs(ns.Resources.PowerTypes) do
      -- Only show power types the player actually has access to
      -- UnitPowerMax returns 0 for unused power types in WoW 12.0+
      local max = UnitPowerMax("player", pt.id)
      if max and max > 0 then
        dropdown[tostring(pt.id)] = pt.name
      end
    end
    -- Always include the player's current primary power type (safety net)
    local currentType = UnitPowerType("player")
    if currentType then
      for _, pt in ipairs(ns.Resources.PowerTypes) do
        if pt.id == currentType then
          dropdown[tostring(pt.id)] = pt.name
          break
        end
      end
    end
  else
    -- Fallback: just show the player's current power type
    local currentType = UnitPowerType("player")
    local names = {[0]="Mana",[1]="Rage",[2]="Focus",[3]="Energy",[6]="Runic Power",[8]="Astral Power",[11]="Maelstrom",[13]="Insanity",[17]="Fury",[18]="Pain"}
    if currentType and names[currentType] then
      dropdown[tostring(currentType)] = names[currentType]
    else
      dropdown["0"] = "Mana"
    end
  end
  return dropdown
end

local function GetSecondaryTypeDropdown()
  local dropdown = {}
  if ns.Resources and ns.Resources.SecondaryTypes then
    for _, st in ipairs(ns.Resources.SecondaryTypes) do
      dropdown[st.id] = st.name
    end
  else
    -- Fallback
    dropdown["comboPoints"] = "Combo Points"
    dropdown["holyPower"] = "Holy Power"
    dropdown["chi"] = "Chi"
    dropdown["runes"] = "Runes"
    dropdown["soulShards"] = "Soul Shards"
    dropdown["essence"] = "Essence"
    dropdown["arcaneCharges"] = "Arcane Charges"
    dropdown["stagger"] = "Stagger"
    dropdown["soulFragments"] = "Soul Fragments"
  end
  return dropdown
end

-- No presets needed - simplified to just Simple and Granular modes

-- ===================================================================
-- RESOURCE OPTIONS TABLE
-- ===================================================================
function ns.ResourceOptions.GetOptionsTable()
  return {
    type = "group",
    name = "Resources",
    order = 5,
    args = {
      -- ============================================================
      -- INFO SECTION
      -- ============================================================
      infoHeader = {
        type = "header",
        name = "Resource Bars",
        order = 1
      },
      infoDescription = {
        type = "description",
        name = "Track both primary resources (Mana, Rage, Energy, etc.) and secondary resources (Combo Points, Holy Power, Runes, etc.)",
        order = 2,
        fontSize = "medium",
      },
      
      -- ============================================================
      -- BAR SELECTOR
      -- ============================================================
      barSelectorHeader = {
        type = "header",
        name = "Configure Resource Bar",
        order = 10
      },
      selectedBar = {
        type = "select",
        name = "Select Bar",
        desc = "Choose which resource bar to configure",
        values = function()
          local values = {}
          for i = 1, 10 do
            local cfg = ns.API and ns.API.GetResourceBarConfig and ns.API.GetResourceBarConfig(i)
            if cfg and cfg.tracking and cfg.tracking.enabled then
              local category = cfg.tracking.resourceCategory or "primary"
              local label = ""
              if category == "secondary" then
                label = string.format("Bar %d: %s (Secondary)", i, cfg.tracking.powerName or "Unknown")
              else
                label = string.format("Bar %d: %s", i, cfg.tracking.powerName or "Unknown")
              end
              values[tostring(i)] = label
            else
              values[tostring(i)] = string.format("Bar %d: (Empty)", i)
            end
          end
          return values
        end,
        get = function()
          local selected = ns.API and ns.API.GetSelectedResourceBar and ns.API.GetSelectedResourceBar() or 1
          return tostring(selected)
        end,
        set = function(info, value)
          if ns.API and ns.API.SetSelectedResourceBar then
            ns.API.SetSelectedResourceBar(tonumber(value))
          end
        end,
        order = 11,
        width = 1.5
      },
      
      -- ============================================================
      -- RESOURCE CATEGORY (Primary vs Secondary) - SECONDARY DISABLED
      -- ============================================================
      trackingHeader = {
        type = "header",
        name = "Resource Type",
        order = 15
      },
      secondaryComingSoon = {
        type = "description",
        name = "|cffFFFF00Secondary Resources (Combo Points, Holy Power, Runes, etc.) coming soon!|r",
        order = 15.5,
        fontSize = "medium",
      },
      resourceCategory = {
        type = "select",
        name = "Resource Category",
        desc = "Primary power resources (Mana, Rage, Energy, etc.). Secondary resources coming soon!",
        values = {
          ["primary"] = "Primary Power",
          -- ["secondary"] = "Secondary Resource",  -- DISABLED: Coming soon
        },
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local category = cfg and cfg.tracking.resourceCategory or "primary"
          -- Force to primary if someone had secondary configured (also fix stored value)
          if category == "secondary" then
            cfg.tracking.resourceCategory = "primary"
            return "primary"
          end
          return category
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            -- Only allow primary for now
            cfg.tracking.resourceCategory = "primary"
            
            -- Reset the specific type
            cfg.tracking.secondaryType = nil
            cfg.tracking.powerType = 0
            cfg.tracking.powerName = ""
            cfg.tracking.maxValue = 100
            
            cfg.tracking.enabled = true
            
            if ns.Resources and ns.Resources.ApplyAppearance then
              ns.Resources.ApplyAppearance(barNum)
            end
          end
        end,
        order = 16,
        width = 1.0
      },
      
      -- ============================================================
      -- PRIMARY RESOURCE SETTINGS
      -- ============================================================
      primaryHeader = {
        type = "header",
        name = "Primary Power Settings",
        order = 20,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.tracking.resourceCategory == "secondary"
        end
      },
      powerType = {
        type = "select",
        name = "Power Type",
        desc = "Select which primary resource to track",
        values = function()
          local dropdown = GetPowerTypeDropdown()
          dropdown["none"] = "|cff888888-- Select Power Type --|r"
          return dropdown
        end,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          -- If bar is not enabled yet, show placeholder so user can click any option (including Mana)
          if cfg and not cfg.tracking.enabled then
            return "none"
          end
          return cfg and tostring(cfg.tracking.powerType) or "none"
        end,
        set = function(info, value)
          if value == "none" then return end  -- Ignore placeholder selection
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            local powerType = tonumber(value)
            cfg.tracking.powerType = powerType
            cfg.tracking.maxValue = UnitPowerMax("player", powerType)
            
            -- Find power name
            local powerName = "Unknown"
            if ns.Resources and ns.Resources.PowerTypes then
              for _, pt in ipairs(ns.Resources.PowerTypes) do
                if pt.id == powerType then
                  powerName = pt.name
                  break
                end
              end
            end
            cfg.tracking.powerName = powerName
            cfg.tracking.enabled = true
            
            -- Apply default preset scaled to max
            ns.API.ApplyThresholdPreset(barNum, "twoTone", cfg.tracking.maxValue)
            
            if ns.Resources and ns.Resources.ApplyAppearance then
              ns.Resources.ApplyAppearance(barNum)
            end
          end
        end,
        order = 21,
        width = 1.0,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.tracking.resourceCategory == "secondary"
        end
      },
      
      -- ============================================================
      -- SECONDARY RESOURCE SETTINGS (HIDDEN - Coming Soon)
      -- ============================================================
      secondaryHeader = {
        type = "header",
        name = "Secondary Resource Settings",
        order = 25,
        hidden = true  -- Always hidden - coming soon
      },
      secondaryType = {
        type = "select",
        name = "Secondary Resource",
        desc = "Select which secondary resource to track (Combo Points, Holy Power, Runes, etc.)",
        values = GetSecondaryTypeDropdown,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.tracking.secondaryType or "comboPoints"
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.tracking.secondaryType = value
            
            -- Get the max value and name for this secondary type
            local typeInfo = ns.Resources and ns.Resources.SecondaryTypesLookup and ns.Resources.SecondaryTypesLookup[value]
            if typeInfo then
              cfg.tracking.powerName = typeInfo.name
              cfg.tracking.maxValue = ns.Resources.GetSecondaryMaxValue(value)
              
              -- Set default color from type info
              if typeInfo.color and cfg.thresholds and cfg.thresholds[1] then
                cfg.thresholds[1].color = {
                  r = typeInfo.color.r,
                  g = typeInfo.color.g,
                  b = typeInfo.color.b,
                  a = 1
                }
              end
            else
              cfg.tracking.powerName = value
              cfg.tracking.maxValue = 5
            end
            
            cfg.tracking.enabled = true
            
            -- Enable tick marks for discrete secondary resources
            if ns.Resources.TickedSecondaryTypes and ns.Resources.TickedSecondaryTypes[value] then
              cfg.display.showTickMarks = true
              cfg.display.tickMode = "all"
            end
            
            if ns.Resources and ns.Resources.ApplyAppearance then
              ns.Resources.ApplyAppearance(barNum)
            end
          end
        end,
        order = 26,
        width = 1.0,
        hidden = true  -- Always hidden - coming soon
      },
      detectSecondary = {
        type = "execute",
        name = "Auto-Detect",
        desc = "Automatically detect the secondary resource for your current class/spec",
        func = function()
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg and ns.Resources and ns.Resources.DetectSecondaryResource then
            local detected = ns.Resources.DetectSecondaryResource()
            if detected then
              cfg.tracking.resourceCategory = "secondary"
              cfg.tracking.secondaryType = detected
              
              local typeInfo = ns.Resources.SecondaryTypesLookup[detected]
              if typeInfo then
                cfg.tracking.powerName = typeInfo.name
                cfg.tracking.maxValue = ns.Resources.GetSecondaryMaxValue(detected)
                
                -- Set default color from type info
                if typeInfo.color and cfg.thresholds and cfg.thresholds[1] then
                  cfg.thresholds[1].color = {
                    r = typeInfo.color.r,
                    g = typeInfo.color.g,
                    b = typeInfo.color.b,
                    a = 1
                  }
                end
              end
              
              cfg.tracking.enabled = true
              
              -- Enable tick marks for discrete secondary resources
              if ns.Resources.TickedSecondaryTypes and ns.Resources.TickedSecondaryTypes[detected] then
                cfg.display.showTickMarks = true
                cfg.display.tickMode = "all"
              end
              
              -- Set spec restriction to current spec
              cfg.behavior.showOnSpecs = { GetSpecialization() or 1 }
              
              if ns.Resources.ApplyAppearance then
                ns.Resources.ApplyAppearance(barNum)
              end
              
              -- Notify change to refresh UI
              LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            else
              print("|cffff9900ArcUI:|r No secondary resource detected for your current class/spec.")
            end
          end
        end,
        order = 27,
        width = 0.8,
        hidden = true  -- Always hidden - secondary resources coming soon
      },
      
      -- ============================================================
      -- MAX VALUE SETTINGS (Shared)
      -- ============================================================
      maxHeader = {
        type = "header",
        name = "Max Value",
        order = 30
      },
      detectMax = {
        type = "execute",
        name = "Auto-Detect Max",
        desc = "Automatically detect your current max resource value",
        func = function()
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            local resourceCategory = cfg.tracking.resourceCategory or "primary"
            local newMax
            
            if resourceCategory == "secondary" then
              newMax = ns.Resources.GetSecondaryMaxValue(cfg.tracking.secondaryType)
            else
              newMax = UnitPowerMax("player", cfg.tracking.powerType)
            end
            
            local oldMax = cfg.tracking.maxValue or 100
            cfg.tracking.maxValue = newMax
            
            -- Only rescale thresholds if thresholdAsPercent is enabled
            if cfg.display.thresholdAsPercent and cfg.thresholds and oldMax > 0 then
              for _, threshold in ipairs(cfg.thresholds) do
                threshold.minValue = math.floor((threshold.minValue / oldMax) * newMax)
                threshold.maxValue = math.floor((threshold.maxValue / oldMax) * newMax)
              end
            end
            
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 31,
        width = 1.0
      },
      currentMax = {
        type = "description",
        name = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local maxVal = cfg and cfg.tracking.maxValue or 100
          local overrideMax = cfg and cfg.tracking.overrideMax
          if overrideMax then
            return string.format("|cff00ff00Max Value:|r %d |cffff9900(Override)|r", maxVal)
          else
            return string.format("|cff00ff00Max Value:|r %d |cff888888(Auto)|r", maxVal)
          end
        end,
        fontSize = "medium",
        order = 32
      },
      overrideMaxToggle = {
        type = "toggle",
        name = "Override Max",
        desc = "Manually set the max value instead of using the game's value",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.tracking.overrideMax or false
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.tracking.overrideMax = value
            if not value then
              -- Reset to auto value
              local resourceCategory = cfg.tracking.resourceCategory or "primary"
              if resourceCategory == "secondary" then
                cfg.tracking.maxValue = ns.Resources.GetSecondaryMaxValue(cfg.tracking.secondaryType)
              else
                cfg.tracking.maxValue = UnitPowerMax("player", cfg.tracking.powerType or 0)
              end
            end
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 33,
        width = 0.7
      },
      manualMaxValue = {
        type = "input",
        name = "Max Value",
        desc = "Set a custom max value",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return tostring(cfg and cfg.tracking.maxValue or 100)
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.tracking.maxValue = tonumber(value) or 100
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 34,
        width = 0.6,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.tracking.overrideMax)
        end
      },
      
      -- ============================================================
      -- DISPLAY MODE
      -- ============================================================
      displayHeader = {
        type = "header",
        name = "Display Mode",
        order = 40
      },
      thresholdMode = {
        type = "select",
        name = "Color Mode",
        desc = "How colors change as resource fills",
        values = {
          ["simple"] = "Simple (Single Color)",
          ["granular"] = "Granular (Per Unit)",
          ["threshold"] = "Threshold (2-3 Colors)",
          ["folded"] = "Folded (Two-Tone)",
          ["fragmented"] = "Fragmented (Runes/Essence)",
        },
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.thresholdMode or "simple"
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.thresholdMode = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 41,
        width = 1.2
      },
      
      fragmentedSpacing = {
        type = "range",
        name = "Segment Spacing",
        desc = "Space between segments in fragmented mode",
        min = 0, max = 10, step = 1,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.fragmentedSpacing or 2
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.fragmentedSpacing = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 42,
        width = 1.0,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      
      -- ============================================================
      -- COLOR SETTINGS
      -- ============================================================
      colorHeader = {
        type = "header",
        name = "Colors",
        order = 50
      },
      baseColor = {
        type = "color",
        name = "Base Color",
        desc = "Primary fill color",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.thresholds and cfg.thresholds[1] and cfg.thresholds[1].color or {r=0, g=0.8, b=1, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg and cfg.thresholds then
            if not cfg.thresholds[1] then cfg.thresholds[1] = { enabled = true, minValue = 0, maxValue = 100 } end
            cfg.thresholds[1].color = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 51,
        width = 0.8
      },
      enableMaxColor = {
        type = "toggle",
        name = "Max Color",
        desc = "Use a different color when at max value",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.enableMaxColor
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.enableMaxColor = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 52,
        width = 0.6
      },
      maxColor = {
        type = "color",
        name = "Max Color",
        desc = "Color when at max value",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.display.maxColor or {r=0, g=1, b=0, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.maxColor = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 53,
        width = 0.6,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.enableMaxColor)
        end
      },
      
      -- Threshold colors (for threshold mode)
      threshold2Header = {
        type = "description",
        name = "\n|cff888888Threshold Colors (for Threshold mode)|r",
        order = 55,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not cfg or cfg.display.thresholdMode ~= "threshold"
        end
      },
      fragmentedColorHeader = {
        type = "description",
        name = "\n|cff888888Fragmented Mode:|r Use the |cffffd700Appearance|r panel to customize per-segment colors and cooldown text.",
        order = 55.1,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not cfg or cfg.display.thresholdMode ~= "fragmented"
        end
      },
      threshold2Enabled = {
        type = "toggle",
        name = "Color 2",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.thresholds and cfg.thresholds[2] and cfg.thresholds[2].enabled
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg and cfg.thresholds then
            if not cfg.thresholds[2] then cfg.thresholds[2] = { enabled = false, minValue = 50, maxValue = 100 } end
            cfg.thresholds[2].enabled = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 56,
        width = 0.5,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not cfg or cfg.display.thresholdMode ~= "threshold"
        end
      },
      threshold2Color = {
        type = "color",
        name = "",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.thresholds and cfg.thresholds[2] and cfg.thresholds[2].color or {r=1, g=1, b=0, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg and cfg.thresholds then
            if not cfg.thresholds[2] then cfg.thresholds[2] = { enabled = true, minValue = 50, maxValue = 100 } end
            cfg.thresholds[2].color = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 57,
        width = 0.4,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not cfg or cfg.display.thresholdMode ~= "threshold" or not (cfg.thresholds and cfg.thresholds[2] and cfg.thresholds[2].enabled)
        end
      },
      threshold2Value = {
        type = "range",
        name = "Starts At",
        min = 1,
        max = 100,
        step = 1,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.thresholds and cfg.thresholds[2] and cfg.thresholds[2].minValue or 50
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg and cfg.thresholds then
            if not cfg.thresholds[2] then cfg.thresholds[2] = { enabled = true, color = {r=1, g=1, b=0, a=1} } end
            cfg.thresholds[2].minValue = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 58,
        width = 0.8,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not cfg or cfg.display.thresholdMode ~= "threshold" or not (cfg.thresholds and cfg.thresholds[2] and cfg.thresholds[2].enabled)
        end
      },
      
      -- Folded mode colors
      foldedColor1 = {
        type = "color",
        name = "First Half",
        desc = "Color for first half of bar",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.display.foldedColor1 or {r=0, g=0.5, b=1, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.foldedColor1 = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 60,
        width = 0.6,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not cfg or cfg.display.thresholdMode ~= "folded"
        end
      },
      foldedColor2 = {
        type = "color",
        name = "Second Half",
        desc = "Color for second half of bar",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.display.foldedColor2 or {r=0, g=1, b=0, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.foldedColor2 = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 61,
        width = 0.6,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not cfg or cfg.display.thresholdMode ~= "folded"
        end
      },
      
      -- Fragmented mode colors - HIDDEN (use Appearance panel for per-segment colors)
      fragmentedChargingColor = {
        type = "color",
        name = "Charging",
        desc = "Color for segments that are recharging",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.display.fragmentedChargingColor or {r=0.4, g=0.4, b=0.4, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.fragmentedChargingColor = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 62,
        width = 0.6,
        hidden = function()
          return true  -- Hidden - use Appearance panel instead
        end
      },
      fragmentedReadyColor = {
        type = "color",
        name = "Ready",
        desc = "Color for segments that are fully charged",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.thresholds and cfg.thresholds[2] and cfg.thresholds[2].color or {r=0.8, g=0.1, b=0.1, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            if not cfg.thresholds then cfg.thresholds = {} end
            if not cfg.thresholds[2] then cfg.thresholds[2] = { enabled = true } end
            cfg.thresholds[2].color = {r=r, g=g, b=b, a=a}
            cfg.thresholds[2].enabled = true
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 63,
        width = 0.6,
        hidden = function()
          return true  -- Hidden - use Appearance panel instead
        end
      },
      
      -- ============================================================
      -- SIZE
      -- ============================================================
      sizeHeader = {
        type = "header",
        name = "Size",
        order = 70
      },
      width = {
        type = "range",
        name = "Width",
        min = 50,
        max = 600,
        step = 1,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.width or 250
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.width = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 71,
        width = 1.0
      },
      height = {
        type = "range",
        name = "Height",
        min = 5,
        max = 100,
        step = 1,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.height or 25
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.height = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 72,
        width = 1.0
      },
      barScale = {
        type = "range",
        name = "Scale",
        min = 0.5,
        max = 3.0,
        step = 0.05,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.barScale or 1.0
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.barScale = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 73,
        width = 0.8
      },
      
      -- ============================================================
      -- TEXTURE
      -- ============================================================
      textureHeader = {
        type = "header",
        name = "Texture",
        order = 80
      },
      texture = {
        type = "select",
        name = "Bar Texture",
        dialogControl = "LSM30_Statusbar",
        values = GetStatusBarTextures,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.texture or "Blizzard"
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.texture = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 81,
        width = 1.2
      },
      
      -- ============================================================
      -- BACKGROUND
      -- ============================================================
      backgroundHeader = {
        type = "header",
        name = "Background",
        order = 90
      },
      showBackground = {
        type = "toggle",
        name = "Show Background",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.showBackground
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.showBackground = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 91,
        width = 0.7
      },
      backgroundColor = {
        type = "color",
        name = "Background Color",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.display.backgroundColor or {r=0.1, g=0.1, b=0.1, a=0.9}
          return c.r, c.g, c.b, c.a
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.backgroundColor = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 92,
        width = 0.8,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showBackground)
        end
      },
      
      -- ============================================================
      -- BORDER
      -- ============================================================
      borderHeader = {
        type = "header",
        name = "Border",
        order = 100
      },
      showBorder = {
        type = "toggle",
        name = "Show Border",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.showBorder
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.showBorder = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 101,
        width = 0.6
      },
      borderThickness = {
        type = "range",
        name = "Thickness",
        min = 1,
        max = 10,
        step = 1,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.drawnBorderThickness or 2
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.drawnBorderThickness = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 102,
        width = 0.6,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showBorder)
        end
      },
      borderColor = {
        type = "color",
        name = "Border Color",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.display.borderColor or {r=0, g=0, b=0, a=1}
          return c.r, c.g, c.b, c.a
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.borderColor = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 103,
        width = 0.6,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showBorder)
        end
      },
      
      -- ============================================================
      -- TICK MARKS
      -- ============================================================
      tickHeader = {
        type = "header",
        name = "Tick Marks",
        order = 110
      },
      showTickMarks = {
        type = "toggle",
        name = "Show Ticks",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.showTickMarks
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.showTickMarks = value
            if ns.Resources then ns.Resources.UpdateBar(barNum) end
          end
        end,
        order = 111,
        width = 0.6
      },
      tickMode = {
        type = "select",
        name = "Tick Mode",
        values = {
          ["all"] = "Per Unit (1 per point)",
          ["percent"] = "Percentage Intervals",
          ["custom"] = "Custom (Ability Costs)",
        },
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.tickMode or "all"
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.tickMode = value
            if ns.Resources then ns.Resources.UpdateBar(barNum) end
          end
        end,
        order = 112,
        width = 1.0,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showTickMarks)
        end
      },
      tickThickness = {
        type = "range",
        name = "Thickness",
        min = 1,
        max = 5,
        step = 1,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.tickThickness or 2
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.tickThickness = value
            if ns.Resources then ns.Resources.UpdateBar(barNum) end
          end
        end,
        order = 113,
        width = 0.6,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showTickMarks)
        end
      },
      tickColor = {
        type = "color",
        name = "Tick Color",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.display.tickColor or {r=0, g=0, b=0, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.tickColor = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.UpdateBar(barNum) end
          end
        end,
        order = 114,
        width = 0.6,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showTickMarks)
        end
      },
      
      -- ============================================================
      -- TEXT
      -- ============================================================
      textHeader = {
        type = "header",
        name = "Text",
        order = 130
      },
      showText = {
        type = "toggle",
        name = "Show Text",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.showText
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.showText = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 131,
        width = 0.5
      },
      textFormat = {
        type = "select",
        name = "Text Format",
        desc = "Value shows the raw number (e.g. 45000). Percentage shows as percent (e.g. 72%).",
        values = {
          ["value"] = "Value",
          ["percent"] = "Percentage",
        },
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.textFormat or "value"
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.textFormat = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 131.5,
        width = 0.7,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          if not cfg or not cfg.display.showText then return true end
          -- Only show for primary resources (percentage doesn't make sense for 5 combo points)
          return cfg.tracking.resourceCategory == "secondary"
        end
      },
      font = {
        type = "select",
        name = "Font",
        dialogControl = "LSM30_Font",
        values = GetFonts,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.font or "Friz Quadrata TT"
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.font = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 132,
        width = 1.0,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showText)
        end
      },
      fontSize = {
        type = "range",
        name = "Font Size",
        min = 8,
        max = 48,
        step = 1,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.fontSize or 20
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.fontSize = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 133,
        width = 0.8,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showText)
        end
      },
      textColor = {
        type = "color",
        name = "Text Color",
        hasAlpha = true,
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          local c = cfg and cfg.display.textColor or {r=1, g=1, b=1, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.textColor = {r=r, g=g, b=b, a=a}
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 134,
        width = 0.6,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showText)
        end
      },
      textAnchor = {
        type = "select",
        name = "Text Position",
        values = {
          ["FREE"] = "Free (Movable)",
          ["CENTER"] = "Center",
          ["LEFT"] = "Left",
          ["RIGHT"] = "Right",
          ["OUTERTOP"] = "Above Bar",
          ["OUTERBOTTOM"] = "Below Bar",
          ["OUTERLEFT"] = "Left of Bar",
          ["OUTERRIGHT"] = "Right of Bar",
        },
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.textAnchor or "FREE"
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
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
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 135,
        width = 0.9,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not (cfg and cfg.display.showText)
        end
      },
      
      -- ============================================================
      -- BAR POSITION
      -- ============================================================
      positionHeader = {
        type = "header",
        name = "Bar Position",
        order = 140
      },
      barPositionX = {
        type = "input",
        name = "X Offset",
        desc = "Horizontal position offset from screen center",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          if cfg and cfg.display.barPosition then
            return tostring(math.floor(cfg.display.barPosition.x or 0))
          end
          return "0"
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            if not cfg.display.barPosition then
              cfg.display.barPosition = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
            end
            cfg.display.barPosition.x = tonumber(value) or 0
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 141,
        width = 0.4
      },
      barPositionY = {
        type = "input",
        name = "Y Offset",
        desc = "Vertical position offset from screen center",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          if cfg and cfg.display.barPosition then
            return tostring(math.floor(cfg.display.barPosition.y or 0))
          end
          return "0"
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            if not cfg.display.barPosition then
              cfg.display.barPosition = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
            end
            cfg.display.barPosition.y = tonumber(value) or 0
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 142,
        width = 0.4
      },
      barMovable = {
        type = "toggle",
        name = "Drag to Move",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.display.barMovable
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.display.barMovable = value
            if ns.Resources then ns.Resources.ApplyAppearance(barNum) end
          end
        end,
        order = 143,
        width = 0.7
      },
      
      -- ============================================================
      -- BEHAVIOR
      -- ============================================================
      behaviorHeader = {
        type = "header",
        name = "Behavior",
        order = 160
      },
      hideOutOfCombat = {
        type = "toggle",
        name = "Hide Out of Combat",
        get = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return cfg and cfg.behavior.hideOutOfCombat
        end,
        set = function(info, value)
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.behavior.hideOutOfCombat = value
            if ns.Resources then ns.Resources.UpdateBar(barNum) end
          end
        end,
        order = 161,
        width = 0.6
      },
      
      -- Talent Condition
      talentHeader = {
        type = "header",
        name = "Talent Condition",
        order = 170
      },
      talentConditionSummary = {
        type = "description",
        name = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          if cfg and ns.TalentPicker and ns.TalentPicker.GetConditionSummary then
            return ns.TalentPicker.GetConditionSummary(cfg.behavior.talentConditions, cfg.behavior.talentMatchMode)
          end
          return "|cff888888No talent conditions|r"
        end,
        order = 170.1
      },
      openTalentPicker = {
        type = "execute",
        name = "Edit Talent Conditions",
        desc = "Open the talent picker to set conditions for when this bar should show",
        func = function()
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg and ns.TalentPicker and ns.TalentPicker.OpenPicker then
            ns.TalentPicker.OpenPicker(
              cfg.behavior.talentConditions,
              cfg.behavior.talentMatchMode or "all",
              function(conditions, matchMode)
                cfg.behavior.talentConditions = conditions
                cfg.behavior.talentMatchMode = matchMode
                -- Clear color curve cache since visibility may have changed
                if ns.Resources and ns.Resources.ClearResourceColorCurve then
                  ns.Resources.ClearResourceColorCurve(barNum)
                end
                if ns.Resources then ns.Resources.UpdateBar(barNum) end
                -- Refresh options panel
                local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
                if AceConfigRegistry then
                  AceConfigRegistry:NotifyChange("ArcUI")
                end
              end
            )
          end
        end,
        order = 171,
        width = 0.8
      },
      clearTalentConditions = {
        type = "execute",
        name = "Clear",
        desc = "Remove all talent conditions",
        func = function()
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.behavior.talentConditions = nil
            cfg.behavior.talentMatchMode = nil
            if ns.Resources then ns.Resources.UpdateBar(barNum) end
            local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
            if AceConfigRegistry then
              AceConfigRegistry:NotifyChange("ArcUI")
            end
          end
        end,
        order = 172,
        width = 0.4,
        hidden = function()
          local cfg = ns.API.GetResourceBarConfig(ns.API.GetSelectedResourceBar())
          return not cfg or not cfg.behavior.talentConditions or #(cfg.behavior.talentConditions or {}) == 0
        end
      },
      
      -- ============================================================
      -- DELETE
      -- ============================================================
      deleteHeader = {
        type = "header",
        name = "Delete",
        order = 200
      },
      deleteBar = {
        type = "execute",
        name = "Delete This Resource Bar",
        desc = "Remove this resource bar",
        confirm = true,
        confirmText = "Delete this resource bar?",
        func = function()
          local barNum = ns.API.GetSelectedResourceBar()
          local cfg = ns.API.GetResourceBarConfig(barNum)
          if cfg then
            cfg.tracking.enabled = false
            if ns.Resources then ns.Resources.HideBar(barNum) end
          end
        end,
        order = 201
      }
    }
  }
end

-- ===================================================================
-- END OF ArcUI_ResourceOptions.lua
-- ===================================================================