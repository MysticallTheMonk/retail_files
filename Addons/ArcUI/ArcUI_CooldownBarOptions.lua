-- ===================================================================
-- ArcUI_CooldownBarOptions.lua
-- Cooldown Bars options with visual catalog-based setup
-- Matches TrackingOptions style with collapsible subsections
-- ===================================================================

local ADDON, ns = ...
ns.CooldownBarOptions = ns.CooldownBarOptions or {}

-- ===================================================================
-- UI STATE
-- ===================================================================
local selectedSpellID = nil
local searchText = ""
local filterType = "all"

-- Track which bars are expanded (collapsed by default)
local expandedBars = {}  -- expandedBars["cooldown_spellID"] = true means expanded

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================
local function GetSpellDataByID(spellID)
  if not ns.CooldownBars or not ns.CooldownBars.spellCatalog then return nil end
  for _, data in ipairs(ns.CooldownBars.spellCatalog) do
    if data.spellID == spellID then return data end
  end
  return nil
end

local function GetBarStates(spellID)
  if not ns.CooldownBars then return {} end
  return {
    hasCooldownBar = ns.CooldownBars.activeCooldowns[spellID] ~= nil,
    hasChargeBar = ns.CooldownBars.activeCharges[spellID] ~= nil,
    hasResourceBar = ns.CooldownBars.activeResources[spellID] ~= nil,
  }
end

local function GetCatalogEntries()
  if not ns.CooldownBars or not ns.CooldownBars.spellCatalog then return {} end
  
  local entries = {}
  local searchLower = searchText:lower()
  
  for _, data in ipairs(ns.CooldownBars.spellCatalog) do
    local match = true
    
    if searchText ~= "" then
      match = data.name:lower():find(searchLower, 1, true) ~= nil
    end
    
    if match and filterType ~= "all" then
      if filterType == "cooldown" then
        match = data.hasCooldown and not data.hasCharges
      elseif filterType == "charges" then
        match = data.hasCharges
      elseif filterType == "resource" then
        match = data.hasResourceCost
      end
    end
    
    if match then
      table.insert(entries, data)
    end
  end
  
  return entries
end

-- ===================================================================
-- LEGACY COOLDOWN BARS HELPERS
-- Gets buff bars with trackType "cooldownCharge" (rendered by ArcUI_Display)
-- ===================================================================
local function GetLegacyCooldownBars()
  local bars = {}
  
  for barIndex = 1, 30 do
    local cfg = ns.API.GetBarConfig(barIndex)
    if cfg and cfg.tracking and cfg.tracking.enabled and cfg.tracking.trackType == "cooldownCharge" then
      local spellID = cfg.tracking.spellID or cfg.tracking.cooldownID or 0
      local spellName = cfg.tracking.buffName or cfg.tracking.spellName or ""
      if spellID > 0 then
        local updatedName = C_Spell.GetSpellName(spellID)
        if updatedName then spellName = updatedName end
      end
      table.insert(bars, {
        barIndex = barIndex,
        spellID = spellID,
        spellName = spellName,
        maxCharges = cfg.tracking.maxStacks or 3,
        iconTexture = cfg.tracking.iconTextureID or C_Spell.GetSpellTexture(spellID) or 134400,
      })
    end
  end
  
  return bars
end

-- Create an entry for a legacy bar in the options panel
local function CreateLegacyBarEntry(barInfo, orderBase)
  local barKey = "legacy_" .. barInfo.barIndex
  local spellName = barInfo.spellName or "Unknown"
  local spellTexture = barInfo.iconTexture or 134400
  
  return {
    type = "group",
    name = "",
    inline = true,
    order = orderBase,
    args = {
      -- Header row with icon, name, and buttons
      header = {
        type = "description",
        name = function()
          return string.format("|T%s:20:20:0:0|t  |cffffd700%s|r  |cff888888(Charge Bar #%d)|r",
            spellTexture, spellName, barInfo.barIndex)
        end,
        fontSize = "medium",
        order = 1,
        width = 2.0,
      },
      
      -- Edit button - opens Appearance panel for this bar (same as right-click)
      editBtn = {
        type = "execute",
        name = "Edit",
        desc = "Open appearance settings for this bar",
        func = function()
          -- Use existing Display function (same as right-click)
          -- These are buff bars with trackType "cooldownCharge"
          if ns.Display and ns.Display.OpenOptionsForBar then
            ns.Display.OpenOptionsForBar("buff", barInfo.barIndex)
          end
        end,
        order = 2,
        width = 0.5,
      },
      
      -- Delete button - disables the bar
      deleteBtn = {
        type = "execute",
        name = "|cffff4444Delete|r",
        desc = "Disable and hide this charge bar",
        func = function()
          local cfg = ns.API.GetBarConfig(barInfo.barIndex)
          if cfg and cfg.tracking then
            cfg.tracking.enabled = false
            -- Hide the bar frame
            if ns.Display and ns.Display.barPool then
              local barData = ns.Display.barPool[barInfo.barIndex]
              if barData and barData.frame then
                barData.frame:Hide()
              end
            end
            print("|cff00ff00[ArcUI]|r Disabled charge bar #" .. barInfo.barIndex .. " (" .. spellName .. ")")
          end
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        order = 3,
        width = 0.5,
        confirm = true,
        confirmText = "Disable charge bar '" .. spellName .. "'?",
      },
    },
  }
end

-- ===================================================================
-- BAR SETTINGS ACCESS (uses new GetBarConfig structure)
-- ===================================================================
local function GetBarConfig(spellID, barType)
  if ns.CooldownBars and ns.CooldownBars.GetBarConfig then
    return ns.CooldownBars.GetBarConfig(spellID, barType)
  end
  return nil
end

-- ===================================================================
-- CREATE ACTIVE BAR ENTRY (collapsible dropdown)
-- ===================================================================
local function CreateActiveBarEntry(spellID, barType, orderBase)
  local barKey = barType .. "_" .. spellID
  local spellName = C_Spell.GetSpellName(spellID) or "Unknown"
  local spellTexture = C_Spell.GetSpellTexture(spellID) or 134400
  
  -- Type labels and colors (3 bar types: Duration, Charges, Resource)
  local typeLabels = {
    cooldown = { label = "Duration", color = "ff8800" },
    charge = { label = "Charges", color = "00ccff" },
    resource = { label = "Resource", color = "cc33cc" },
  }
  local typeInfo = typeLabels[barType] or { label = barType, color = "ffffff" }
  
  return {
    type = "group",
    name = "",
    inline = true,
    order = orderBase,
    hidden = function()
      -- Hide if this bar type isn't active for this spell
      if barType == "cooldown" then
        return not ns.CooldownBars or not ns.CooldownBars.activeCooldowns[spellID]
      elseif barType == "charge" then
        return not ns.CooldownBars or not ns.CooldownBars.activeCharges[spellID]
      elseif barType == "resource" then
        return not ns.CooldownBars or not ns.CooldownBars.activeResources[spellID]
      end
      return true
    end,
    args = {
      header = {
        type = "toggle",
        name = function()
          local cfg = GetBarConfig(spellID, barType)
          local presetLabel = (cfg and cfg.tracking and cfg.tracking.preset == "simple") and "|cff888888Simple|r" or "|cffffd700ArcUI|r"
          
          return string.format("|T%d:16:16:0:0|t |cff%s%s|r: %s [%s]",
            spellTexture, typeInfo.color, typeInfo.label, spellName, presetLabel)
        end,
        desc = "Click to expand/collapse settings",
        dialogControl = "CollapsibleHeader",
        get = function() return expandedBars[barKey] end,
        set = function(info, value) expandedBars[barKey] = value end,
        order = 0,
        width = "full",
      },
      
      -- Show toggle
      show = {
        type = "toggle",
        name = "Show",
        desc = "Show/hide this bar",
        get = function()
          local cfg = GetBarConfig(spellID, barType)
          return cfg and cfg.tracking and cfg.tracking.enabled ~= false
        end,
        set = function(info, value)
          local cfg = GetBarConfig(spellID, barType)
          if cfg and cfg.tracking then
            cfg.tracking.enabled = value
            if ns.CooldownBars and ns.CooldownBars.ApplyAppearance then
              ns.CooldownBars.ApplyAppearance(spellID, barType)
            end
          end
        end,
        order = 1,
        width = 0.4,
        hidden = function() return not expandedBars[barKey] end,
      },
      
      -- Preset selector
      preset = {
        type = "select",
        name = "Style",
        desc = "Simple: Basic status bar\nArcUI: Fancy styling with icon",
        values = {
          simple = "Simple",
          arcui = "ArcUI",
        },
        get = function()
          local cfg = GetBarConfig(spellID, barType)
          return cfg and cfg.tracking and cfg.tracking.preset or "arcui"
        end,
        set = function(info, value)
          local cfg = GetBarConfig(spellID, barType)
          if cfg and cfg.tracking then
            cfg.tracking.preset = value
            if ns.CooldownBars and ns.CooldownBars.ApplyPreset then
              ns.CooldownBars.ApplyPreset(spellID, barType, value)
            end
          end
        end,
        order = 2,
        width = 0.5,
        hidden = function() return not expandedBars[barKey] end,
      },
      
      -- Edit Display button
      editDisplay = {
        type = "execute",
        name = "Edit Display",
        desc = "Open Appearance options for this bar",
        func = function()
          if ns.CooldownBars and ns.CooldownBars.OpenOptionsForBar then
            ns.CooldownBars.OpenOptionsForBar(barType, spellID)
          end
        end,
        order = 2.5,
        width = 0.55,
        hidden = function() return not expandedBars[barKey] end,
      },
      
      -- Spec 1 toggle
      spec1 = {
        type = "toggle",
        name = function()
          local _, specName, _, specIcon = GetSpecializationInfo(1)
          if specIcon and specName then
            return string.format("|T%s:14:14:0:0|t %s", specIcon, specName)
          end
          return specName or "Spec 1"
        end,
        desc = function()
          local _, specName = GetSpecializationInfo(1)
          return specName and ("Show for " .. specName) or "Show for Spec 1"
        end,
        get = function()
          local cfg = GetBarConfig(spellID, barType)
          if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs then return true end
          if #cfg.behavior.showOnSpecs == 0 then return true end  -- Empty = all specs
          for _, spec in ipairs(cfg.behavior.showOnSpecs) do
            if spec == 1 then return true end
          end
          return false
        end,
        set = function(info, value)
          local cfg = GetBarConfig(spellID, barType)
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
            
            -- If array is empty (all specs) and we're unchecking, populate with all EXCEPT this one
            if not value and #cfg.behavior.showOnSpecs == 0 then
              local numSpecs = GetNumSpecializations() or 4
              for i = 1, numSpecs do
                if i ~= 1 then
                  table.insert(cfg.behavior.showOnSpecs, i)
                end
              end
            elseif value then
              local found = false
              for _, spec in ipairs(cfg.behavior.showOnSpecs) do
                if spec == 1 then found = true break end
              end
              if not found then table.insert(cfg.behavior.showOnSpecs, 1) end
            else
              for i = #cfg.behavior.showOnSpecs, 1, -1 do
                if cfg.behavior.showOnSpecs[i] == 1 then
                  table.remove(cfg.behavior.showOnSpecs, i)
                end
              end
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 3.1,
        width = 0.85,
        hidden = function() return not expandedBars[barKey] end,
      },
      
      -- Spec 2 toggle
      spec2 = {
        type = "toggle",
        name = function()
          local _, specName, _, specIcon = GetSpecializationInfo(2)
          if specIcon and specName then
            return string.format("|T%s:14:14:0:0|t %s", specIcon, specName)
          end
          return specName or "Spec 2"
        end,
        desc = function()
          local _, specName = GetSpecializationInfo(2)
          return specName and ("Show for " .. specName) or "Show for Spec 2"
        end,
        get = function()
          local cfg = GetBarConfig(spellID, barType)
          if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs then return true end
          if #cfg.behavior.showOnSpecs == 0 then return true end  -- Empty = all specs
          for _, spec in ipairs(cfg.behavior.showOnSpecs) do
            if spec == 2 then return true end
          end
          return false
        end,
        set = function(info, value)
          local cfg = GetBarConfig(spellID, barType)
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
            
            -- If array is empty (all specs) and we're unchecking, populate with all EXCEPT this one
            if not value and #cfg.behavior.showOnSpecs == 0 then
              local numSpecs = GetNumSpecializations() or 4
              for i = 1, numSpecs do
                if i ~= 2 then
                  table.insert(cfg.behavior.showOnSpecs, i)
                end
              end
            elseif value then
              local found = false
              for _, spec in ipairs(cfg.behavior.showOnSpecs) do
                if spec == 2 then found = true break end
              end
              if not found then table.insert(cfg.behavior.showOnSpecs, 2) end
            else
              for i = #cfg.behavior.showOnSpecs, 1, -1 do
                if cfg.behavior.showOnSpecs[i] == 2 then
                  table.remove(cfg.behavior.showOnSpecs, i)
                end
              end
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 3.2,
        width = 0.85,
        hidden = function() return not expandedBars[barKey] end,
      },
      
      -- Spec 3 toggle
      spec3 = {
        type = "toggle",
        name = function()
          local _, specName, _, specIcon = GetSpecializationInfo(3)
          if specIcon and specName then
            return string.format("|T%s:14:14:0:0|t %s", specIcon, specName)
          end
          return specName or "Spec 3"
        end,
        desc = function()
          local _, specName = GetSpecializationInfo(3)
          return specName and ("Show for " .. specName) or "Show for Spec 3"
        end,
        get = function()
          local cfg = GetBarConfig(spellID, barType)
          if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs then return true end
          if #cfg.behavior.showOnSpecs == 0 then return true end  -- Empty = all specs
          for _, spec in ipairs(cfg.behavior.showOnSpecs) do
            if spec == 3 then return true end
          end
          return false
        end,
        set = function(info, value)
          local cfg = GetBarConfig(spellID, barType)
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
            
            -- If array is empty (all specs) and we're unchecking, populate with all EXCEPT this one
            if not value and #cfg.behavior.showOnSpecs == 0 then
              local numSpecs = GetNumSpecializations() or 4
              for i = 1, numSpecs do
                if i ~= 3 then
                  table.insert(cfg.behavior.showOnSpecs, i)
                end
              end
            elseif value then
              local found = false
              for _, spec in ipairs(cfg.behavior.showOnSpecs) do
                if spec == 3 then found = true break end
              end
              if not found then table.insert(cfg.behavior.showOnSpecs, 3) end
            else
              for i = #cfg.behavior.showOnSpecs, 1, -1 do
                if cfg.behavior.showOnSpecs[i] == 3 then
                  table.remove(cfg.behavior.showOnSpecs, i)
                end
              end
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 3.3,
        width = 0.85,
        hidden = function()
          if not expandedBars[barKey] then return true end
          -- Hide if class has less than 3 specs
          local numSpecs = GetNumSpecializations()
          return numSpecs < 3
        end,
      },
      
      -- Spec 4 toggle (for Druid)
      spec4 = {
        type = "toggle",
        name = function()
          local _, specName, _, specIcon = GetSpecializationInfo(4)
          if specIcon and specName then
            return string.format("|T%s:14:14:0:0|t %s", specIcon, specName)
          end
          return specName or "Spec 4"
        end,
        desc = function()
          local _, specName = GetSpecializationInfo(4)
          return specName and ("Show for " .. specName) or "Show for Spec 4"
        end,
        get = function()
          local cfg = GetBarConfig(spellID, barType)
          if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs then return true end
          if #cfg.behavior.showOnSpecs == 0 then return true end  -- Empty = all specs
          for _, spec in ipairs(cfg.behavior.showOnSpecs) do
            if spec == 4 then return true end
          end
          return false
        end,
        set = function(info, value)
          local cfg = GetBarConfig(spellID, barType)
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
            
            -- If array is empty (all specs) and we're unchecking, populate with all EXCEPT this one
            if not value and #cfg.behavior.showOnSpecs == 0 then
              local numSpecs = GetNumSpecializations() or 4
              for i = 1, numSpecs do
                if i ~= 4 then
                  table.insert(cfg.behavior.showOnSpecs, i)
                end
              end
            elseif value then
              local found = false
              for _, spec in ipairs(cfg.behavior.showOnSpecs) do
                if spec == 4 then found = true break end
              end
              if not found then table.insert(cfg.behavior.showOnSpecs, 4) end
            else
              for i = #cfg.behavior.showOnSpecs, 1, -1 do
                if cfg.behavior.showOnSpecs[i] == 4 then
                  table.remove(cfg.behavior.showOnSpecs, i)
                end
              end
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 3.4,
        width = 0.85,
        hidden = function()
          if not expandedBars[barKey] then return true end
          -- Hide if class has less than 4 specs (only Druid has 4)
          local numSpecs = GetNumSpecializations()
          return numSpecs < 4
        end,
      },
      
      -- Delete button
      deleteBtn = {
        type = "execute",
        name = "|cffff4444Delete|r",
        desc = "Remove this bar",
        func = function()
          if ns.CooldownBars and ns.CooldownBars.ToggleBarType then
            ns.CooldownBars.ToggleBarType(spellID, barType, false)
          end
          expandedBars[barKey] = nil
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        order = 10,
        width = 0.5,
        confirm = true,
        confirmText = "Delete this " .. typeInfo.label .. " bar?",
        hidden = function() return not expandedBars[barKey] end,
      },
      
      -- Line break
      lineBreak1 = {
        type = "description",
        name = "",
        order = 11,
        width = "full",
        hidden = function() return not expandedBars[barKey] end,
      },
      
      -- Edit in Appearance link
      editAppearance = {
        type = "description",
        name = "|cff888888Detailed appearance settings available in the Appearance tab.|r",
        order = 20,
        width = "full",
        fontSize = "small",
        hidden = function() return not expandedBars[barKey] end,
      },
    },
  }
end

-- ===================================================================
-- BUILD OPTIONS TABLE
-- ===================================================================
function ns.CooldownBarOptions.GetOptionsTable()
  local args = {
    description = {
      type = "description",
      name = "|cffffd700Cooldown Bars|r track spell cooldowns, resource costs, and charge abilities.\nSelect a spell from the catalog below, then create the bar type you want.\n",
      fontSize = "medium",
      order = 1,
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- SPELL CATALOG HEADER
    -- ═══════════════════════════════════════════════════════════════
    catalogHeader = {
      type = "header",
      name = "Spell Catalog",
      order = 2,
    },
    
    searchBox = {
      type = "input",
      name = "Search",
      desc = "Search for spells by name",
      get = function() return searchText end,
      set = function(info, value)
        searchText = value
        selectedSpellID = nil
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      order = 3,
      width = 0.9,
    },
    
    filterDropdown = {
      type = "select",
      name = "Filter",
      values = {
        all = "All Spells",
        cooldown = "Cooldowns",
        charges = "Charge Abilities",
        -- resource = "Has Resource Cost",  -- Disabled until resource bars implemented
      },
      get = function() return filterType end,
      set = function(info, value)
        filterType = value
        selectedSpellID = nil
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      order = 4,
      width = 0.7,
    },
    
    rescanBtn = {
      type = "execute",
      name = "Rescan",
      desc = "Rescan spellbook for available abilities",
      func = function()
        if ns.CooldownBars and ns.CooldownBars.ScanPlayerSpells then
          local count = ns.CooldownBars.ScanPlayerSpells()
          print(string.format("|cff00ccffArc UI|r: Found %d spells", count))
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      order = 5,
      width = 0.5,
      disabled = function() return InCombatLockdown() end,
    },
    
    addSpellInput = {
      type = "input",
      name = "Add ID",
      desc = "Enter a spell ID to manually add",
      get = function() return "" end,
      set = function(info, value)
        local spellID = tonumber(value)
        if spellID and ns.CooldownBars and ns.CooldownBars.AddSpellByID then
          local success, name = ns.CooldownBars.AddSpellByID(spellID)
          if success then
            print(string.format("|cff00ff00[ArcUI]|r Added: %s (ID: %d)", name, spellID))
            selectedSpellID = spellID
          else
            print(string.format("|cffff0000[ArcUI]|r Failed: %s", name or "Unknown"))
          end
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end
      end,
      order = 6,
      width = 0.5,
    },
    
    catalogCount = {
      type = "description",
      name = function()
        local entries = GetCatalogEntries()
        local total = ns.CooldownBars and #ns.CooldownBars.spellCatalog or 0
        local shown = #entries
        if shown < total then
          return string.format("|cff888888Showing %d of %d spells|r", shown, total)
        else
          return string.format("|cff888888%d spells|r", shown)
        end
      end,
      fontSize = "medium",
      order = 7,
    },
    
    catalogSpacer = {
      type = "description",
      name = " ",
      order = 8,
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- SELECTED SPELL SECTION
    -- ═══════════════════════════════════════════════════════════════
    selectedHeader = {
      type = "header",
      name = function()
        if not selectedSpellID then return "" end
        local name = C_Spell.GetSpellName(selectedSpellID) or "Unknown"
        local texture = C_Spell.GetSpellTexture(selectedSpellID) or 134400
        return string.format("|T%d:20:20:0:0|t %s", texture, name)
      end,
      order = 200,
      hidden = function() return not selectedSpellID end,
    },
    
    selectedInfo = {
      type = "description",
      name = function()
        if not selectedSpellID then return "" end
        local data = GetSpellDataByID(selectedSpellID)
        if not data then return "Spell not found in catalog" end
        
        local lines = {}
        table.insert(lines, string.format("|cffffd700Spell ID:|r %d", data.spellID))
        
        local features = {}
        if data.hasCharges then
          table.insert(features, string.format("Charges (%d max)", data.maxCharges or 0))
        elseif data.hasCooldown then
          table.insert(features, "Has Cooldown")
        end
        if data.hasResourceCost then
          table.insert(features, string.format("%d %s cost", data.resourceCost or 0, data.resourceName or ""))
        end
        if #features > 0 then
          table.insert(lines, "|cffffd700Features:|r " .. table.concat(features, ", "))
        end
        
        return table.concat(lines, "\n")
      end,
      fontSize = "medium",
      order = 201,
      hidden = function() return not selectedSpellID end,
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- CREATE BAR BUTTONS
    -- ═══════════════════════════════════════════════════════════════
    
    -- Duration Bar (any cooldown spell)
    btnDuration = {
      type = "execute",
      name = function()
        if not selectedSpellID then return "Duration Bar" end
        local states = GetBarStates(selectedSpellID)
        return states.hasCooldownBar and "|cff00ff00Duration Bar|r" or "Duration Bar"
      end,
      desc = "Create a bar showing cooldown/recharge time remaining",
      func = function()
        if selectedSpellID and ns.CooldownBars then
          local states = GetBarStates(selectedSpellID)
          if not states.hasCooldownBar then
            ns.CooldownBars.ToggleBarType(selectedSpellID, "cooldown", true)
          end
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      order = 210,
      width = 0.75,
      hidden = function()
        if not selectedSpellID then return true end
        local data = GetSpellDataByID(selectedSpellID)
        return not (data and data.hasCooldown)
      end,
    },
    
    -- Resource Bar (DISABLED - Coming Soon)
    btnResource = {
      type = "execute",
      name = function()
        if not selectedSpellID then return "Resource Bar" end
        local states = GetBarStates(selectedSpellID)
        return states.hasResourceBar and "|cff00ff00Resource Bar|r" or "Resource Bar"
      end,
      desc = "Track resource progress toward spell cost (Coming Soon)",
      func = function()
        -- Disabled
      end,
      order = 211,
      width = 0.75,
      hidden = true,  -- Always hidden - resource bars not yet implemented
    },
    
    -- Charges Bar (for charge spells)
    btnCharges = {
      type = "execute",
      name = function()
        if not selectedSpellID then return "Charges Bar" end
        local states = GetBarStates(selectedSpellID)
        return states.hasChargeBar and "|cff00ff00Charges Bar|r" or "Charges Bar"
      end,
      desc = "Create charge indicators",
      func = function()
        if selectedSpellID and ns.CooldownBars then
          local states = GetBarStates(selectedSpellID)
          if not states.hasChargeBar then
            ns.CooldownBars.ToggleBarType(selectedSpellID, "charge", true)
          end
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      order = 212,
      width = 0.7,
      hidden = function()
        if not selectedSpellID then return true end
        local data = GetSpellDataByID(selectedSpellID)
        return not (data and data.hasCharges)
      end,
    },
    
    -- Spacer
    btnSpacer = {
      type = "description",
      name = "",
      order = 220,
      hidden = function() return not selectedSpellID end,
    },
    
    -- Clear selection button
    clearBtn = {
      type = "execute",
      name = "Clear Selection",
      func = function()
        selectedSpellID = nil
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      order = 221,
      width = 0.8,
      hidden = function() return not selectedSpellID end,
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- ACTIVE BARS SECTION
    -- ═══════════════════════════════════════════════════════════════
    activeBarsHeader = {
      type = "header",
      name = "Active Cooldown Bars",
      order = 500,
    },
    
    activeBarsDesc = {
      type = "description",
      name = function()
        if not ns.CooldownBars then return "" end
        local count = 0
        for _ in pairs(ns.CooldownBars.activeCooldowns or {}) do count = count + 1 end
        for _ in pairs(ns.CooldownBars.activeCharges or {}) do count = count + 1 end
        -- Resource bars disabled: for _ in pairs(ns.CooldownBars.activeResources or {}) do count = count + 1 end
        if count == 0 then
          return "|cff888888No active bars. Select a spell above and create a bar.|r"
        end
        return string.format("|cff888888%d active bar(s). Click to expand settings.|r", count)
      end,
      fontSize = "medium",
      order = 501,
    },
  }
  
  -- ═══════════════════════════════════════════════════════════════
  -- ADD SPELL CATALOG ICONS
  -- ═══════════════════════════════════════════════════════════════
  local entries = GetCatalogEntries()
  local iconOrder = 100
  
  for i, data in ipairs(entries) do
    if i <= 60 then
      local states = GetBarStates(data.spellID)
      local hasAnyBar = states.hasCooldownBar or states.hasChargeBar  -- Resource bars disabled
      
      args["spell_" .. data.spellID] = {
        type = "execute",
        name = " ",
        image = function() return C_Spell.GetSpellTexture(data.spellID) or 134400 end,
        imageWidth = 28,
        imageHeight = 28,
        func = function()
          if selectedSpellID == data.spellID then
            selectedSpellID = nil
          else
            selectedSpellID = data.spellID
          end
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        order = iconOrder + i,
        width = 0.22,
        desc = function()
          local tooltip = "|cffffd700" .. data.name .. "|r\nID: " .. data.spellID
          if data.hasCharges then
            tooltip = tooltip .. "\n|cff00ccffCharges: " .. data.maxCharges .. "|r"
          end
          if data.hasResourceCost then
            tooltip = tooltip .. "\n|cffcc33ccCost: " .. (data.resourceCost or "?") .. " " .. (data.resourceName or "") .. "|r"
          end
          if hasAnyBar then
            tooltip = tooltip .. "\n\n|cff00ff00[Has Active Bar]|r"
          end
          tooltip = tooltip .. "\n\n|cff888888Click to select|r"
          return tooltip
        end,
      }
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════
  -- ADD ACTIVE BAR ENTRIES (collapsible dropdowns)
  -- ═══════════════════════════════════════════════════════════════
  local barOrder = 510
  
  if ns.CooldownBars then
    -- Duration bars
    for spellID, _ in pairs(ns.CooldownBars.activeCooldowns or {}) do
      args["activeBar_cooldown_" .. spellID] = CreateActiveBarEntry(spellID, "cooldown", barOrder)
      barOrder = barOrder + 1
    end
    
    -- Charge bars
    for spellID, _ in pairs(ns.CooldownBars.activeCharges or {}) do
      args["activeBar_charge_" .. spellID] = CreateActiveBarEntry(spellID, "charge", barOrder)
      barOrder = barOrder + 1
    end
    
    -- Resource bars (DISABLED - Coming Soon)
    -- for spellID, _ in pairs(ns.CooldownBars.activeResources or {}) do
    --   args["activeBar_resource_" .. spellID] = CreateActiveBarEntry(spellID, "resource", barOrder)
    --   barOrder = barOrder + 1
    -- end
  end
  
  -- ═══════════════════════════════════════════════════════════════
  -- LEGACY CHARGE BARS SECTION
  -- Shows bars from the old cooldownBars system (rendered by Display)
  -- ═══════════════════════════════════════════════════════════════
  local legacyBars = GetLegacyCooldownBars()
  
  if #legacyBars > 0 then
    args.legacyBarsHeader = {
      type = "header",
      name = "Existing Charge Bars",
      order = 600,
    }
    
    args.legacyBarsDesc = {
      type = "description",
      name = "|cff888888These are your existing charge bars (trackType: cooldownCharge). Click Edit to open appearance settings, or Delete to disable.|r",
      fontSize = "medium",
      order = 601,
    }
    
    local legacyOrder = 610
    for _, barInfo in ipairs(legacyBars) do
      args["legacyBar_" .. barInfo.barIndex] = CreateLegacyBarEntry(barInfo, legacyOrder)
      legacyOrder = legacyOrder + 1
    end
  end
  
  return {
    type = "group",
    name = "Cooldown Bars",
    args = args,
  }
end

-- ===================================================================
-- END
-- ===================================================================