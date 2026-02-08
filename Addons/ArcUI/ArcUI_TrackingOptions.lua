-- ===================================================================
-- ArcUI_TrackingOptions.lua
-- Tracking options with visual catalog-based setup
-- - Removed search box
-- - Filter dropdown next to Open CD Manager
-- - Added Hide CDM Icon toggle to bar/icon setup and appearance
-- - v2.5.1: Secondary resources temporarily disabled (coming soon)
-- ===================================================================

local ADDON, ns = ...
ns.TrackingOptions = ns.TrackingOptions or {}

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- ===================================================================
-- UI STATE
-- ===================================================================
local showOnlyCurrentSpec = true
local catalogConfigFilter = "all"  -- "all", "configured", "notconfigured"
local selectedCatalogEntry = nil

-- Track which bars are expanded (collapsed by default)
local expandedBars = {}  -- expandedBars["buff_1"] = true means bar 1 is expanded
local expandedResources = {}  -- expandedResources["resource_1"] = true means resource bar 1 is expanded

-- ===================================================================
-- POWER TYPES BY CLASS
-- ===================================================================
local ALL_POWER_TYPES = {
  [0]  = "Mana", [1]  = "Rage", [2]  = "Focus", [3]  = "Energy",
  [4]  = "Combo Points", [5]  = "Runes", [6]  = "Runic Power",
  [7]  = "Soul Shards", [8]  = "Astral Power", [9]  = "Holy Power",
  [11] = "Maelstrom", [12] = "Chi", [13] = "Insanity",
  [16] = "Arcane Charges", [17] = "Fury", [18] = "Pain", [19] = "Essence"
}

local SECONDARY_POWER_TYPES = {
  [4] = true, [5] = true, [7] = true, [9] = true,
  [12] = true, [16] = true, [19] = true,
}

local CLASS_POWER_TYPES = {
  ["WARRIOR"] = {1}, ["PALADIN"] = {0, 9}, ["HUNTER"] = {2},
  ["ROGUE"] = {3, 4}, ["PRIEST"] = {0, 13}, ["DEATHKNIGHT"] = {6, 5},
  ["SHAMAN"] = {0}, ["MAGE"] = {0, 16}, ["WARLOCK"] = {0, 7},
  ["MONK"] = {12}, ["DRUID"] = {0, 1, 3, 8, 4},
  ["DEMONHUNTER"] = {17, 18}, ["EVOKER"] = {0, 19}
}

local SPEC_POWER_TYPES = {
  ["SHAMAN"] = { [1] = {11}, [2] = {}, [3] = {} },
  ["MONK"]   = { [1] = {3}, [2] = {0}, [3] = {3} },  -- BrM=Energy, MW=Mana, WW=Energy
}

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================
local function GetCurrentSpecIndex()
  return GetSpecialization() or 1
end

local function GetPowerTypeDropdown()
  local dropdown = { ["none"] = "-- Select --" }
  local _, playerClass = UnitClass("player")
  local classPowers = CLASS_POWER_TYPES[playerClass]
  local currentSpec = GetSpecialization() or 1
  
  if classPowers then
    for _, powerID in ipairs(classPowers) do
      if not SECONDARY_POWER_TYPES[powerID] then
        local powerName = ALL_POWER_TYPES[powerID]
        if powerName then dropdown[tostring(powerID)] = powerName end
      end
    end
  end
  
  local specPowers = SPEC_POWER_TYPES[playerClass]
  if specPowers and specPowers[currentSpec] then
    for _, powerID in ipairs(specPowers[currentSpec]) do
      if not SECONDARY_POWER_TYPES[powerID] then
        local powerName = ALL_POWER_TYPES[powerID]
        if powerName then dropdown[tostring(powerID)] = powerName end
      end
    end
  end
  
  return dropdown
end

local function ShouldShowBar(cfg)
  if not cfg or not cfg.tracking then return false end
  if not cfg.tracking.enabled and not cfg.tracking.customEnabled then return false end
  
  -- Filter out cooldownCharge bars - they belong in Cooldown Bars panel
  if cfg.tracking.trackType == "cooldownCharge" then return false end
  
  if not showOnlyCurrentSpec then return true end
  
  local currentSpec = GetCurrentSpecIndex()
  if cfg.behavior and cfg.behavior.showOnSpecs and #cfg.behavior.showOnSpecs > 0 then
    local specMatch = false
    for _, spec in ipairs(cfg.behavior.showOnSpecs) do
      if spec == currentSpec then 
        specMatch = true
        break 
      end
    end
    if not specMatch then return false end
  else
    local barSpec = cfg.behavior and cfg.behavior.showOnSpec or 0
    if barSpec ~= 0 and barSpec ~= currentSpec then return false end
  end
  
  -- NOTE: Talent conditions are NOT checked here - this function is for OPTIONS filtering only
  -- Talent conditions are checked in the display/core layer to hide the actual bar
  
  return true
end

-- Check if talent conditions are met (for display purposes, not options filtering)
local function AreTalentConditionsMet(cfg)
  if not cfg or not cfg.behavior then return true end
  if not cfg.behavior.talentConditions or #cfg.behavior.talentConditions == 0 then return true end
  
  if ns.TalentPicker and ns.TalentPicker.CheckTalentConditions then
    local matchMode = cfg.behavior.talentMatchMode or "all"
    return ns.TalentPicker.CheckTalentConditions(cfg.behavior.talentConditions, matchMode)
  end
  
  return true
end

-- Get linked spells from a bar's CDM frame for the Track Spell dropdown
-- Returns: { [spellID] = "Spell Name (spellID)", ... }
-- ONLY includes spells from the linkedSpellIDs array (the actual aura variants)
local function GetLinkedSpellsForBar(barNum)
  local result = { [0] = "Auto (follow CDM)" }
  
  local cfg = ns.API.GetBarConfig(barNum)
  if not cfg then return result end
  
  local cooldownID = cfg.tracking.cooldownID
  if not cooldownID or cooldownID <= 0 then return result end
  
  -- Find CDM frame with this cooldownID
  local cdmFrame = nil
  local viewers = {"BuffIconCooldownViewer", "CooldownViewer", "EssentialCooldownViewer", "UtilityCooldownViewer"}
  
  for _, viewerName in ipairs(viewers) do
    local viewer = _G[viewerName]
    if viewer and viewer.GetChildren then
      local success, children = pcall(function() return {viewer:GetChildren()} end)
      if success and children then
        for _, child in ipairs(children) do
          if child.cooldownInfo and child.cooldownInfo.cooldownID == cooldownID then
            cdmFrame = child
            break
          end
        end
      end
    end
    if cdmFrame then break end
  end
  
  if cdmFrame and cdmFrame.cooldownInfo then
    local ci = cdmFrame.cooldownInfo
    
    -- ONLY add linkedSpellIDs array entries - these are the actual aura variants
    local linkedSpellIDs = ci.linkedSpellIDs
    if linkedSpellIDs and type(linkedSpellIDs) == "table" then
      for _, spellID in ipairs(linkedSpellIDs) do
        if spellID and type(spellID) == "number" and spellID > 0 then
          local spellInfo = C_Spell.GetSpellInfo(spellID)
          local spellName = spellInfo and spellInfo.name or ("Spell " .. spellID)
          result[spellID] = spellName .. " (" .. spellID .. ")"
        end
      end
    end
  end
  
  return result
end

-- Check if a bar has multiple linked spells (shows Track Spell dropdown)
-- Only shows dropdown when there are 2+ entries in linkedSpellIDs array
-- (meaning the buff can actually appear as different spell IDs)
local function HasMultipleLinkedSpells(barNum)
  local cfg = ns.API.GetBarConfig(barNum)
  if not cfg then return false end
  
  local cooldownID = cfg.tracking and cfg.tracking.cooldownID
  if not cooldownID or cooldownID <= 0 then return false end
  
  -- Find CDM frame to check linkedSpellIDs array
  local cdmFrame = nil
  local viewers = {"BuffIconCooldownViewer", "EssentialCooldownViewer", "UtilityCooldownViewer", "CooldownViewer"}
  
  for _, viewerName in ipairs(viewers) do
    local viewer = _G[viewerName]
    if viewer and viewer.GetChildren then
      local success, children = pcall(function() return {viewer:GetChildren()} end)
      if success and children then
        for _, child in ipairs(children) do
          if child.cooldownInfo and child.cooldownInfo.cooldownID == cooldownID then
            cdmFrame = child
            break
          end
        end
      end
    end
    if cdmFrame then break end
  end
  
  if not cdmFrame or not cdmFrame.cooldownInfo then return false end
  
  -- Check linkedSpellIDs array - only show dropdown if 2+ entries
  local linkedSpellIDs = cdmFrame.cooldownInfo.linkedSpellIDs
  if linkedSpellIDs and type(linkedSpellIDs) == "table" then
    local count = 0
    for _ in ipairs(linkedSpellIDs) do
      count = count + 1
      if count >= 2 then
        return true  -- 2+ linked spells = show dropdown
      end
    end
  end
  
  return false  -- 0 or 1 linked spell = no dropdown needed
end

-- Expose to namespace for use by display layer
ns.TrackingOptions.AreTalentConditionsMet = AreTalentConditionsMet

local function ShouldShowBarWithType(cfg, filterDisplayType)
  if not ShouldShowBar(cfg) then return false end
  local barDisplayType = cfg.display.displayType or "bar"
  return barDisplayType == filterDisplayType
end

-- ===================================================================
-- CATALOG DROPDOWN BUILDER
-- ===================================================================

-- Helper to get selected entry info (works for both CDM and custom definitions)
local function GetSelectedCatalogEntry()
  if not selectedCatalogEntry then return nil end
  
  -- Check if it's a custom definition (format: "customAura_uuid" or "customCooldown_uuid")
  if type(selectedCatalogEntry) == "string" then
    if selectedCatalogEntry:find("^customAura_") then
      local customDefID = selectedCatalogEntry:sub(12)  -- Remove "customAura_" prefix
      local auras = ns.Catalog.GetCustomAuraEntries and ns.Catalog.GetCustomAuraEntries() or {}
      for _, entry in ipairs(auras) do
        if entry.customDefinitionID == customDefID then
          return entry
        end
      end
      return nil
    elseif selectedCatalogEntry:find("^customCooldown_") then
      local customDefID = selectedCatalogEntry:sub(16)  -- Remove "customCooldown_" prefix
      local cooldowns = ns.Catalog.GetCustomCooldownEntries and ns.Catalog.GetCustomCooldownEntries() or {}
      for _, entry in ipairs(cooldowns) do
        if entry.customDefinitionID == customDefID then
          return entry
        end
      end
      return nil
    end
  end
  
  -- It's a CDM cooldownID (numeric or stringified number)
  local cooldownID = tonumber(selectedCatalogEntry) or selectedCatalogEntry
  return ns.Catalog and ns.Catalog.GetEntry and ns.Catalog.GetEntry(cooldownID)
end

local function GetCatalogDropdown(filterType, configuredFilter)
  local dropdown = { ["none"] = "-- Select from Catalog --" }
  
  if not ns.Catalog or not ns.Catalog.GetFilteredCatalog then return dropdown end
  if not ns.Catalog.IsPopulated or not ns.Catalog.IsPopulated() then
    dropdown["none"] = "-- Click 'Scan CD Manager' first --"
    return dropdown
  end
  
  local filter = filterType or "tracked"
  local entries = ns.Catalog.GetFilteredCatalog(filter, "")
  
  for i, entry in ipairs(entries) do
    local statusText = ""
    -- "Configured" means it's displayed in CDM (in Tracked Buffs or Tracked Bars, not "Not Displayed")
    local isConfigured = entry.isDisplayed
    
    if isConfigured then
      -- Check if also set up in ArcUI
      local existingBars = ns.Catalog.FindAllArcUIBarsByCooldownID and 
                           ns.Catalog.FindAllArcUIBarsByCooldownID(entry.cooldownID) or {}
      
      if #existingBars > 0 then
        -- Has ArcUI bar(s)
        local hasStacks, hasDuration = false, false
        for _, barInfo in ipairs(existingBars) do
          if barInfo.mode == "stacks" then hasStacks = true end
          if barInfo.mode == "duration" then hasDuration = true end
        end
        if hasStacks and hasDuration then
          statusText = " |cff00ff00[ArcUI: Stacks+Duration]|r"
        elseif hasStacks then
          statusText = " |cff00ff00[ArcUI: Stacks]|r"
        elseif hasDuration then
          statusText = " |cff00ff00[ArcUI: Duration]|r"
        else
          statusText = " |cff00ff00[ArcUI]|r"
        end
      else
        -- Displayed in CDM but no ArcUI bar yet
        statusText = " |cff00ccff[CDM Ready]|r"
      end
    else
      -- Not displayed in CDM (in "Not Displayed" section)
      statusText = " |cff888888(Not Displayed)|r"
    end
    
    -- Apply configured filter
    local passesFilter = true
    if configuredFilter == "configured" and not isConfigured then
      passesFilter = false
    elseif configuredFilter == "notconfigured" and isConfigured then
      passesFilter = false
    end
    
    if passesFilter then
      dropdown[tostring(entry.cooldownID)] = string.format("|T%d:16:16:0:0|t %s%s", 
        entry.icon, entry.name, statusText)
    end
  end
  
  return dropdown
end

-- ===================================================================
-- CATALOG ICON ENTRY HELPER
-- ===================================================================
-- Pre-create a fixed number of icon slots that dynamically show/hide
local MAX_CATALOG_ICONS = 50

local function GetCatalogEntryByIndex(index)
  if not ns.Catalog or not ns.Catalog.GetFilteredCatalog then
    return nil
  end
  
  -- Get CDM catalog entries
  local catalogEntries = ns.Catalog.GetFilteredCatalog("tracked", "")
  local visibleIndex = 0
  
  for _, entry in ipairs(catalogEntries) do
    local isConfigured = entry.isDisplayed
    local passesFilter = true
    
    if catalogConfigFilter == "configured" and not isConfigured then
      passesFilter = false
    elseif catalogConfigFilter == "notconfigured" and isConfigured then
      passesFilter = false
    end
    
    if passesFilter then
      visibleIndex = visibleIndex + 1
      if visibleIndex == index then
        return entry
      end
    end
  end
  
  -- Also include custom auras (always pass filter as "configured")
  if ns.Catalog.GetCustomAuraEntries then
    local customAuras = ns.Catalog.GetCustomAuraEntries()
    for _, entry in ipairs(customAuras) do
      if catalogConfigFilter ~= "notconfigured" then  -- Show in "all" or "configured"
        visibleIndex = visibleIndex + 1
        if visibleIndex == index then
          return entry
        end
      end
    end
  end
  
  -- Also include custom cooldowns
  if ns.Catalog.GetCustomCooldownEntries then
    local customCooldowns = ns.Catalog.GetCustomCooldownEntries()
    for _, entry in ipairs(customCooldowns) do
      if catalogConfigFilter ~= "notconfigured" then
        visibleIndex = visibleIndex + 1
        if visibleIndex == index then
          return entry
        end
      end
    end
  end
  
  return nil
end

local function CreateCatalogIconEntry(index)
  return {
    type = "execute",
    name = function()
      local entry = GetCatalogEntryByIndex(index)
      if not entry then return "" end
      -- Return just a space so the button has a "name" area that can show tooltip
      return " "
    end,
    desc = function()
      local entry = GetCatalogEntryByIndex(index)
      if not entry then return "" end
      
      -- Handle custom definitions
      if entry.isCustom then
        local desc = "|cff00ff00[Custom]|r |cffffd700" .. entry.name .. "|r"
        if entry.spellID and entry.spellID > 0 then
          desc = desc .. "\nSpell ID: " .. entry.spellID
        end
        desc = desc .. "\nType: " .. (entry.customType == "customAura" and "Custom Aura" or "Custom Cooldown")
        
        if entry.arcUIBarNum then
          desc = desc .. "\n\n|cff00ccffAlready in ArcUI:|r Bar " .. entry.arcUIBarNum
        else
          desc = desc .. "\n\n|cff888888Click to select, then create a bar/icon|r"
        end
        return desc
      end
      
      -- CDM entries
      local cooldownID = entry.cooldownID
      local existingBars = ns.Catalog.FindAllArcUIBarsByCooldownID and 
                           ns.Catalog.FindAllArcUIBarsByCooldownID(cooldownID) or {}
      
      local desc = "|cffffd700" .. entry.name .. "|r"
      if entry.spellID then
        desc = desc .. "\nSpell ID: " .. entry.spellID
      end
      desc = desc .. "\nCooldown ID: " .. cooldownID
      
      -- Add spell description from tooltip
      if entry.spellID then
        local spellDesc = C_Spell.GetSpellDescription(entry.spellID)
        if spellDesc and spellDesc ~= "" then
          desc = desc .. "\n\n|cff00ff00" .. spellDesc .. "|r"
        end
      end
      
      if #existingBars > 0 then
        local barsList = {}
        for _, barInfo in ipairs(existingBars) do
          table.insert(barsList, string.format("Bar %d (%s)", barInfo.barNum, barInfo.mode))
        end
        desc = desc .. "\n\n|cff00ccffAlready in ArcUI:|r\n" .. table.concat(barsList, "\n")
      elseif entry.isDisplayed then
        desc = desc .. "\n\n|cff888888Click to select|r"
      else
        desc = desc .. "\n\n|cffff6600⚠ Not configured in CD Manager|r"
        desc = desc .. "\n|cff888888Open Blizzard's CD Manager and enable|r"
        desc = desc .. "\n|cff888888this aura before adding to ArcUI.|r"
      end
      return desc
    end,
    func = function()
      local entry = GetCatalogEntryByIndex(index)
      if not entry then return end
      
      -- Handle custom definitions
      if entry.isCustom then
        local customKey = entry.customType .. "_" .. entry.customDefinitionID
        if selectedCatalogEntry == customKey then
          selectedCatalogEntry = nil
        else
          selectedCatalogEntry = customKey
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        return
      end
      
      -- Warn if not configured (CDM entries only)
      if not entry.isDisplayed then
        print("|cff00ccffArcUI|r: |cffff6600" .. entry.name .. "|r is not configured in CD Manager. Please enable it there first.")
        return
      end
      
      local cooldownID = entry.cooldownID
      if selectedCatalogEntry == cooldownID then
        selectedCatalogEntry = nil
      else
        selectedCatalogEntry = cooldownID
      end
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end,
    image = function()
      local entry = GetCatalogEntryByIndex(index)
      if entry then
        return entry.icon
      end
      return nil
    end,
    imageWidth = 36,
    imageHeight = 36,
    order = 7 + (index * 0.001),
    width = 0.25,
    hidden = function()
      return GetCatalogEntryByIndex(index) == nil
    end
  }
end

-- ===================================================================
-- DELETE CONFIRMATION FRAME
-- ===================================================================
local deleteConfirmFrame = nil

local function ShowDeleteConfirmation(barNum, barType, barName)
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
  
  deleteConfirmFrame.text:SetText(string.format("Delete %s?", barName or "this bar"))
  deleteConfirmFrame.deleteBtn:SetScript("OnClick", function()
    if barType == "buff" then
      local cfg = ns.API.GetBarConfig(barNum)
      if cfg then
        -- Fully reset tracking config
        cfg.tracking.enabled = false
        cfg.tracking.customEnabled = false
        cfg.tracking.buffName = ""
        cfg.tracking.spellID = 0
        cfg.tracking.cooldownID = 0
        cfg.tracking.trackType = "buff"  -- Reset to default
        cfg.tracking.customDefinitionID = nil  -- Clear custom tracking
        cfg.tracking.sourceType = "icon"  -- Reset to default
        cfg.tracking.useDurationBar = false
        cfg.tracking.useBaseSpell = false
        cfg.tracking.trackedSpellID = nil  -- Clear tracked spell selection
        cfg.tracking.maxStacks = 10
        cfg.tracking.maxDuration = 30
        cfg.tracking.iconTextureID = nil
        cfg.tracking.displaySpellID = nil
        cfg.tracking.dynamicMaxDuration = false
        
        -- Reset behavior
        if cfg.behavior then
          cfg.behavior.showOnSpecs = nil
          cfg.behavior.talentConditions = nil
          cfg.behavior.talentMatchMode = nil
          cfg.behavior.hideWhenInactive = false
          cfg.behavior.hideOutOfCombat = false
          cfg.behavior.hideBuffIcon = false
        end
        
        -- Reset display type but keep other display settings
        cfg.display.displayType = "bar"
        
        -- Clear bar state cache
        if ns.API.ClearBarState then
          ns.API.ClearBarState(barNum)
        end
        
        if ns.Display and ns.Display.HideBar then ns.Display.HideBar(barNum) end
      end
    elseif barType == "resource" then
      local cfg = ns.API.GetResourceBarConfig(barNum)
      if cfg then
        -- Fully clear tracking data
        cfg.tracking.enabled = false
        cfg.tracking.powerType = nil
        cfg.tracking.powerName = nil
        
        -- Clear behavior data including talent conditions
        if cfg.behavior then
          cfg.behavior.talentConditions = nil
          cfg.behavior.talentMatchMode = nil
          cfg.behavior.showOnSpecs = nil
        end
        
        -- Reset display
        cfg.display.enabled = false
        
        if ns.Resources and ns.Resources.HideBar then ns.Resources.HideBar(barNum) end
      end
    end
    deleteConfirmFrame:Hide()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
  end)
  
  deleteConfirmFrame:ClearAllPoints()
  deleteConfirmFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
  deleteConfirmFrame:Raise()
  deleteConfirmFrame:Show()
end

-- ===================================================================
-- CREATE ACTIVE BAR ENTRY
-- ===================================================================
local function CreateActiveBarEntry(barNum, orderBase, filterDisplayType, labelPrefix)
  local barKey = "buff_" .. barNum
  
  return {
    type = "group",
    name = "",
    inline = true,
    order = orderBase,
    hidden = function()
      local cfg = ns.API.GetBarConfig(barNum)
      return not ShouldShowBarWithType(cfg, filterDisplayType)
    end,
    args = {
      header = {
        type = "toggle",
        name = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and (cfg.tracking.enabled or cfg.tracking.customEnabled) then
            local name = cfg.tracking.buffName or "(Not configured)"
            local trackType = cfg.tracking.trackType or "buff"
            local typeLabel
            if trackType == "debuff" then
              typeLabel = "|cffff6b6bDebuff|r"
            elseif trackType == "pet" then
              typeLabel = "|cffaa88ffPet|r"
            elseif trackType == "customAura" then
              typeLabel = "|cff00ff00Custom Aura|r"
            elseif trackType == "customCooldown" then
              typeLabel = "|cff00ccffCustom CD|r"
            else
              typeLabel = "|cff00ff00Buff|r"
            end
            
            local modeLabel = ""
            if trackType == "customAura" or trackType == "customCooldown" then
              -- Custom definitions show their mode
              if cfg.tracking.useDurationBar then
                modeLabel = " |cffff9900[Duration]|r"
              else
                modeLabel = " |cff00ccff[Stacks]|r"
              end
            elseif cfg.tracking.customEnabled then
              modeLabel = " |cffff9900[Custom]|r"
            elseif cfg.tracking.useDurationBar then
              modeLabel = " |cffff9900[Duration]|r"
            else
              modeLabel = " |cff00ccff[Stacks]|r"
            end
            
            local statusLabel = ""
            local cooldownID = cfg.tracking.cooldownID
            -- Check if bar is properly configured
            -- ALL bars need: spell identification AND trackType (buff/debuff/pet)
            local hasSpellIdentification = (cfg.tracking.spellID and cfg.tracking.spellID > 0) or 
                                            (cooldownID and cooldownID > 0) or 
                                            (cfg.tracking.buffName and cfg.tracking.buffName ~= "")
            local hasTrackType = cfg.tracking.trackType and cfg.tracking.trackType ~= "" and cfg.tracking.trackType ~= "none"
            local isCustomTracking = cfg.tracking.trackType == "customAura" or cfg.tracking.trackType == "customCooldown"
            
            -- Custom tracking doesn't need spell identification from CDM
            -- All other bars need both spell identification AND trackType
            local isProperlyConfigured = isCustomTracking or (hasSpellIdentification and hasTrackType)
            
            if not isProperlyConfigured then
              statusLabel = " |cffffff00[MISSING SETUP]|r"
            elseif trackType ~= "customAura" and trackType ~= "customCooldown" then
              -- Custom definitions don't need CDM tracking status
              if cooldownID and cooldownID > 0 and not cfg.tracking.customEnabled then
                local trackingOK = ns.API.IsTrackingOK and ns.API.IsTrackingOK(barNum)
                statusLabel = trackingOK and " |cff00ff00[OK]|r" or " |cffff0000[FAIL]|r"
              end
            end
            
            -- Check talent conditions
            local talentLabel = ""
            if cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
              if not AreTalentConditionsMet(cfg) then
                talentLabel = " |cffff9900[Talent Hidden]|r"
              end
            end
            
            return string.format("|T%d:16:16:0:0|t %s %d: %s (%s)%s%s%s", 
              cfg.tracking.iconTextureID or 134400,
              labelPrefix, barNum, name, typeLabel, modeLabel, statusLabel, talentLabel)
          end
          return ""
        end,
        desc = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
            if not AreTalentConditionsMet(cfg) then
              return "Click to expand/collapse\n\n|cffff9900Bar hidden: Talent condition not met|r"
            end
          end
          return "Click to expand/collapse"
        end,
        dialogControl = "CollapsibleHeader",
        get = function() return expandedBars[barKey] end,
        set = function(info, value) expandedBars[barKey] = value end,
        order = 0,
        width = "full",
      },
      show = {
        type = "toggle",
        name = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
            if not AreTalentConditionsMet(cfg) then
              return "|cff888888Show|r"
            end
          end
          return "Show"
        end,
        desc = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
            if not AreTalentConditionsMet(cfg) then
              return "|cffff9900Hidden due to talent condition not met|r\n\nChange your talents or edit the talent condition to show this bar."
            end
          end
          return "Show/hide this " .. labelPrefix:lower()
        end,
        get = function()
          local cfg = ns.API.GetBarConfig(barNum)
          -- If talent conditions not met, always show as unchecked
          if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
            if not AreTalentConditionsMet(cfg) then
              return false
            end
          end
          return cfg and cfg.display.enabled
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            -- Don't allow enabling if talent conditions not met
            if value and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
              if not AreTalentConditionsMet(cfg) then
                print("|cff00ccffArc UI|r: Cannot show bar - talent condition not met")
                return
              end
            end
            cfg.display.enabled = value
            if ns.Display and ns.Display.ApplyAppearance then
              ns.Display.ApplyAppearance(barNum)
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 1,
        width = 0.45,
        hidden = function() return not expandedBars[barKey] end
      },
      trackType = {
        type = "select",
        name = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and (not cfg.tracking.trackType or cfg.tracking.trackType == "") then
            return "|cffFF6600Type|r"
          end
          return "Type"
        end,
        desc = "Track as buff, debuff, pet, totem, or ground effect duration\n\n|cffFFD100Buff|r - Player buffs (Maelstrom Weapon, procs, etc.)\n|cffFFD100Debuff|r - Target debuffs (DoTs, applied effects)\n|cffFFD100Pet|r - Guardians/pets (Dreadstalkers, Wild Imps, Spirit Wolves)\n|cffFFD100Totem|r - Actual totems (Healing Stream, Capacitor)\n|cffFFD100Ground Effect|r - Placed effects (Consecration, Efflorescence, Death and Decay)",
        values = { [""] = "-- Select Type --", ["buff"] = "Buff", ["debuff"] = "Debuff", ["pet"] = "Pet", ["totem"] = "Totem", ["ground"] = "Ground Effect" },
        sorting = { "", "buff", "debuff", "pet", "totem", "ground" },
        get = function()
          local cfg = ns.API.GetBarConfig(barNum)
          return cfg and cfg.tracking.trackType or ""
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            cfg.tracking.trackType = value
            if ns.Display and ns.Display.UpdateBar then
              ns.Display.UpdateBar(barNum)
            end
          end
        end,
        order = 2,
        width = 0.75,
        hidden = function()
          if not expandedBars[barKey] then return true end
          if filterDisplayType == "icon" then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          -- Hide for custom tracking (customEnabled or custom definitions)
          if cfg and cfg.tracking.customEnabled then return true end
          if cfg and (cfg.tracking.trackType == "customAura" or cfg.tracking.trackType == "customCooldown") then
            return true
          end
          return false
        end
      },
      mode = {
        type = "select",
        name = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.tracking.useDurationBar == nil then
            return "|cffFF6600Mode|r"
          end
          return "Mode"
        end,
        desc = "Stacks: bar fills based on stack count. Duration: bar depletes as buff expires.",
        values = { [""] = "-- Select Mode --", ["stacks"] = "Stacks", ["duration"] = "Duration" },
        get = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.tracking.useDurationBar == nil then
            return ""
          end
          return (cfg and cfg.tracking.useDurationBar) and "duration" or "stacks"
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and value ~= "" then
            cfg.tracking.useDurationBar = (value == "duration")
            if value == "duration" then cfg.display.showDuration = true end
            if ns.Display and ns.Display.ApplyAppearance then
              ns.Display.ApplyAppearance(barNum)
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 3,
        width = 0.6,
        hidden = function()
          if not expandedBars[barKey] then return true end
          if filterDisplayType == "icon" then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          return cfg and cfg.tracking.customEnabled
        end
      },
      maxStacks = {
        type = "input",
        name = function()
          local cfg = ns.API.GetBarConfig(barNum)
          local needsValue = false
          if cfg and cfg.tracking.useDurationBar then
            needsValue = not cfg.tracking.maxDuration or cfg.tracking.maxDuration == 0
            if needsValue then
              return "|cffFF6600Max Duration|r"
            end
            return "Max Duration"
          end
          needsValue = not cfg or not cfg.tracking.maxStacks or cfg.tracking.maxStacks == 0
          if needsValue then
            return "|cffFF6600Max Stacks|r"
          end
          return "Max Stacks"
        end,
        desc = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.tracking.useDurationBar then
            return "Maximum duration in seconds (REQUIRED when Auto is off)"
          end
          return "Maximum stack count (REQUIRED)"
        end,
        dialogControl = "ArcUI_EditBox",
        get = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.tracking.useDurationBar then
            local val = cfg.tracking.maxDuration
            return val and val > 0 and tostring(val) or ""
          end
          local val = cfg and cfg.tracking.maxStacks
          return val and val > 0 and tostring(val) or ""
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            local numValue = tonumber(value)
            if numValue and numValue > 0 then
              if cfg.tracking.useDurationBar then
                cfg.tracking.maxDuration = numValue
              else
                cfg.tracking.maxStacks = numValue
              end
              if ns.Display and ns.Display.ApplyAppearance then
                ns.Display.ApplyAppearance(barNum)
              end
              LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            end
          end
        end,
        order = 4,
        width = 0.6,
        hidden = function()
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.tracking.customEnabled then return true end
          -- Hide for duration bars with Auto enabled (Max Ticks moved to Appearance panel)
          if cfg and cfg.tracking.useDurationBar and cfg.tracking.dynamicMaxDuration then return true end
          return false
        end
      },
      dynamicMax = {
        type = "toggle",
        name = "Auto",
        desc = "Automatically get max duration from the CDM bar (adapts to haste, talents, etc.). Set Max (Ticks) in the Appearance panel for tick mark positioning.",
        get = function()
          local cfg = ns.API.GetBarConfig(barNum)
          return cfg and cfg.tracking.dynamicMaxDuration
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            cfg.tracking.dynamicMaxDuration = value
            if ns.Display and ns.Display.ApplyAppearance then
              ns.Display.ApplyAppearance(barNum)
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 4.5,
        width = 0.4,
        hidden = function()
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          -- Only show for duration bars, not custom tracking
          if cfg and cfg.tracking.customEnabled then return true end
          if cfg and (cfg.tracking.trackType == "customAura" or cfg.tracking.trackType == "customCooldown") then return true end
          return not (cfg and cfg.tracking.useDurationBar)
        end
      },
      hideCDM = {
        type = "toggle",
        name = "Hide CDM Icon",
        desc = "Hide the CD Manager icon/bar for this aura",
        get = function()
          local cfg = ns.API.GetBarConfig(barNum)
          return cfg and cfg.behavior and cfg.behavior.hideBuffIcon
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            cfg.behavior.hideBuffIcon = value
            if ns.API.RefreshDisplay then ns.API.RefreshDisplay(barNum) end
          end
        end,
        order = 4.7,
        width = 0.7,
        hidden = function() return not expandedBars[barKey] end
      },
      useBaseSpell = {
        type = "toggle",
        name = "Use Base Spell",
        desc = "LEGACY: Handle CDM override spell switching by unit type.\n\nFor more control, use 'Track Spell' dropdown instead.",
        get = function()
          local cfg = ns.API.GetBarConfig(barNum)
          return cfg and cfg.tracking and cfg.tracking.useBaseSpell
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            cfg.tracking.useBaseSpell = value
            -- Clear trackedSpellID if enabling useBaseSpell (they're mutually exclusive)
            if value then
              cfg.tracking.trackedSpellID = nil
            end
            if ns.API.RefreshDisplay then ns.API.RefreshDisplay(barNum) end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 4.75,
        width = 0.7,
        hidden = function() 
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          if not cfg or not cfg.tracking then return true end
          -- Hide if no cooldownID
          if not cfg.tracking.cooldownID or cfg.tracking.cooldownID <= 0 then return true end
          -- Hide if using trackedSpellID (they're mutually exclusive)
          return cfg.tracking.trackedSpellID and cfg.tracking.trackedSpellID > 0
        end
      },
      trackSpellBreak = {
        type = "description",
        name = "",
        order = 4.76,
        width = "full",
        hidden = function() 
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          return not cfg or not cfg.tracking or not cfg.tracking.cooldownID or cfg.tracking.cooldownID <= 0
        end
      },
      trackedSpellID = {
        type = "select",
        name = "|cff00ff00Track Spell|r",
        desc = "Select which specific spell to track from this CDM slot.\n\n|cffffd700Works for:|r\n• Buff + Debuff combos\n• Multiple buffs on one slot\n• Multiple debuffs on one slot\n\n|cffffd700How it works:|r\nCompares CDM's linkedSpellID (non-secret) to your selection.\nCaches the auraInstanceID when CDM shows your spell.\nUses cached ID when CDM switches to other spells.",
        values = function() return GetLinkedSpellsForBar(barNum) end,
        get = function()
          local cfg = ns.API.GetBarConfig(barNum)
          return cfg and cfg.tracking and cfg.tracking.trackedSpellID or 0
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            if value and value > 0 then
              -- Setting a specific spell to track
              cfg.tracking.trackedSpellID = value
              cfg.tracking.useBaseSpell = false
              -- Cache the icon texture for combat use (out of combat, textures are non-secret)
              local texture = C_Spell.GetSpellTexture(value)
              if texture then
                cfg.tracking.iconTextureID = texture
              end
            else
              -- Switching to Auto - restore the base spellID's texture
              cfg.tracking.trackedSpellID = nil
              -- Get the base spellID from CDM frame
              local cooldownID = cfg.tracking.cooldownID
              if cooldownID and cooldownID > 0 then
                local viewers = {"BuffIconCooldownViewer", "CooldownViewer", "EssentialCooldownViewer", "UtilityCooldownViewer"}
                for _, viewerName in ipairs(viewers) do
                  local viewer = _G[viewerName]
                  if viewer and viewer.GetChildren then
                    local success, children = pcall(function() return {viewer:GetChildren()} end)
                    if success and children then
                      for _, child in ipairs(children) do
                        if child.cooldownInfo and child.cooldownInfo.cooldownID == cooldownID then
                          local spellID = child.cooldownInfo.spellID
                          if spellID then
                            local texture = C_Spell.GetSpellTexture(spellID)
                            if texture then
                              cfg.tracking.iconTextureID = texture
                            end
                          end
                          break
                        end
                      end
                    end
                  end
                end
              end
            end
            -- Clear cached state when changing tracked spell
            if ns.API.ClearBarState then
              ns.API.ClearBarState(barNum)
            end
            if ns.API.RefreshDisplay then ns.API.RefreshDisplay(barNum) end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 4.77,
        width = 1.4,
        hidden = function() 
          if not expandedBars[barKey] then return true end
          -- Only show dropdown when there are 2+ linked spells
          return not HasMultipleLinkedSpells(barNum)
        end
      },
      trackedSpellIDInput = {
        type = "input",
        name = "Manual Spell ID",
        desc = "Enter a spell ID to track manually.\n\nUse this if the dropdown doesn't show all spells.\n\n|cffffd700How to find spell ID:|r\nHover over the buff/debuff and look at the tooltip, or use /dump to see the aura data.",
        get = function()
          local cfg = ns.API.GetBarConfig(barNum)
          local id = cfg and cfg.tracking and cfg.tracking.trackedSpellID
          return id and id > 0 and tostring(id) or ""
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            local numValue = tonumber(value)
            cfg.tracking.trackedSpellID = numValue and numValue > 0 and numValue or nil
            if numValue and numValue > 0 then
              cfg.tracking.useBaseSpell = false
              -- Cache the icon texture for combat use
              local texture = C_Spell.GetSpellTexture(numValue)
              if texture then
                cfg.tracking.iconTextureID = texture
              end
            end
            -- Don't clear iconTextureID when clearing - let Core.lua handle it
            if ns.API.ClearBarState then
              ns.API.ClearBarState(barNum)
            end
            if ns.API.RefreshDisplay then ns.API.RefreshDisplay(barNum) end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 4.78,
        width = 0.8,
        hidden = function() 
          if not expandedBars[barKey] then return true end
          -- Only show when there are 2+ linked spells (same as dropdown)
          return not HasMultipleLinkedSpells(barNum)
        end
      },
      lineBreak1 = {
        type = "description",
        name = "",
        order = 4.9,
        width = "full",
        hidden = function() return not expandedBars[barKey] end
      },
      specLabel = {
        type = "description",
        name = "|cffffd700Specs:|r",
        order = 5.0,
        width = 0.35,
        fontSize = "medium",
        hidden = function() return not expandedBars[barKey] end
      },
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
          local cfg = ns.API.GetBarConfig(barNum)
          if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs then return true end
          if #cfg.behavior.showOnSpecs == 0 then return true end
          for _, spec in ipairs(cfg.behavior.showOnSpecs) do
            if spec == 1 then return true end
          end
          return false
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
            if value then
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
        order = 5.1,
        width = 0.85,
        hidden = function() return not expandedBars[barKey] end
      },
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
          local cfg = ns.API.GetBarConfig(barNum)
          if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs then return true end
          if #cfg.behavior.showOnSpecs == 0 then return true end
          for _, spec in ipairs(cfg.behavior.showOnSpecs) do
            if spec == 2 then return true end
          end
          return false
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
            if value then
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
        order = 5.2,
        width = 0.85,
        hidden = function() return not expandedBars[barKey] end
      },
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
          local cfg = ns.API.GetBarConfig(barNum)
          if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs then return true end
          if #cfg.behavior.showOnSpecs == 0 then return true end
          for _, spec in ipairs(cfg.behavior.showOnSpecs) do
            if spec == 3 then return true end
          end
          return false
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
            if value then
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
        order = 5.3,
        width = 0.85,
        hidden = function()
          if not expandedBars[barKey] then return true end
          return GetNumSpecializations() < 3
        end
      },
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
          local cfg = ns.API.GetBarConfig(barNum)
          if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs then return true end
          if #cfg.behavior.showOnSpecs == 0 then return true end
          for _, spec in ipairs(cfg.behavior.showOnSpecs) do
            if spec == 4 then return true end
          end
          return false
        end,
        set = function(info, value)
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg then
            if not cfg.behavior then cfg.behavior = {} end
            if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
            if value then
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
        order = 5.4,
        width = 0.85,
        hidden = function()
          if not expandedBars[barKey] then return true end
          return GetNumSpecializations() < 4
        end
      },
      talentCondLabel = {
        type = "description",
        name = "|cffffd700Talent Conditions:|r",
        order = 5.5,
        width = 0.65,
        fontSize = "medium",
        hidden = function() return not expandedBars[barKey] end
      },
      talentCondBtn = {
        type = "execute",
        name = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
            return "|cff00ff00Active|r"
          end
          return "None"
        end,
        desc = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
            local summary = ns.TalentPicker and ns.TalentPicker.GetConditionSummary and 
                            ns.TalentPicker.GetConditionSummary(cfg.behavior.talentConditions, cfg.behavior.talentMatchMode) or "Active"
            return summary .. "\n\n|cffffd700Click to edit talent conditions|r"
          end
          return "Show/hide this bar based on your talent choices.\n\n|cffffd700Click to open talent picker|r"
        end,
        func = function()
          local cfg = ns.API.GetBarConfig(barNum)
          local existingConditions = cfg and cfg.behavior and cfg.behavior.talentConditions
          local matchMode = cfg and cfg.behavior and cfg.behavior.talentMatchMode or "all"
          
          if ns.TalentPicker and ns.TalentPicker.OpenPicker then
            ns.TalentPicker.OpenPicker(existingConditions, matchMode, function(conditions, newMatchMode)
              local barCfg = ns.API.GetBarConfig(barNum)
              if barCfg then
                if not barCfg.behavior then barCfg.behavior = {} end
                barCfg.behavior.talentConditions = conditions
                barCfg.behavior.talentMatchMode = newMatchMode
                LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
              end
            end)
          else
            print("|cff00ccffArc UI|r: Talent picker not available")
          end
        end,
        order = 5.6,
        width = 0.45,
        hidden = function() return not expandedBars[barKey] end
      },
      talentCondClear = {
        type = "execute",
        name = "X",
        desc = "Clear talent conditions",
        func = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and cfg.behavior then
            cfg.behavior.talentConditions = nil
            cfg.behavior.talentMatchMode = nil
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 5.7,
        width = 0.2,
        hidden = function()
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          return not cfg or not cfg.behavior or not cfg.behavior.talentConditions or #cfg.behavior.talentConditions == 0
        end
      },
      lineBreak2 = {
        type = "description",
        name = "",
        order = 5.9,
        width = "full",
        hidden = function() return not expandedBars[barKey] end
      },
      appearance = {
        type = "execute",
        name = "Edit",
        desc = "Configure appearance",
        func = function()
          ns.TrackingOptions.SelectBarForAppearance("buff", barNum)
        end,
        order = 6,
        width = 0.45,
        hidden = function() return not expandedBars[barKey] end
      },
      identify = {
        type = "execute",
        name = "Find",
        desc = "Flash this bar on screen",
        func = function()
          ns.TrackingOptions.IdentifyBar("buff", barNum)
        end,
        order = 7,
        width = 0.45,
        hidden = function() return not expandedBars[barKey] end
      },
      -- ═══════════════════════════════════════════════════════════════════
      -- LINKED COOLDOWN IDS (Cross-Spec Support)
      -- ═══════════════════════════════════════════════════════════════════
      linkedCdIDsHeader = {
        type = "description",
        name = "\n|cffffd700Linked Cooldown IDs|r |cff888888(for cross-spec tracking)|r",
        fontSize = "medium",
        order = 7.1,
        width = "full",
        hidden = function()
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          -- Hide for custom tracking
          if cfg and (cfg.tracking.customEnabled or cfg.tracking.trackType == "customAura" or cfg.tracking.trackType == "customCooldown") then
            return true
          end
          -- Hide if no cooldownID set
          if not cfg or not cfg.tracking.cooldownID or cfg.tracking.cooldownID <= 0 then
            return true
          end
          return false
        end
      },
      linkedCdIDsList = {
        type = "description",
        name = function()
          local cfg = ns.API.GetBarConfig(barNum)
          if not cfg or not cfg.tracking then return "" end
          
          local lines = {}
          local activeCdID = nil
          if ns.API.GetActiveCooldownIDForBar then
            activeCdID = ns.API.GetActiveCooldownIDForBar(barNum)
          end
          
          -- Primary cooldownID
          local primaryCdID = cfg.tracking.cooldownID
          if primaryCdID and primaryCdID > 0 then
            local isActive = (activeCdID == primaryCdID)
            local activeMarker = isActive and " |cff00ff00[ACTIVE]|r" or ""
            local spellName = ""
            if C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
              local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(primaryCdID)
              if info and info.spellID then
                spellName = C_Spell.GetSpellName(info.spellID) or ""
                if spellName ~= "" then spellName = " (" .. spellName .. ")" end
              end
            end
            table.insert(lines, string.format("|cffffd700Primary:|r %d%s%s", primaryCdID, spellName, activeMarker))
          end
          
          -- Alternate cooldownIDs
          if cfg.tracking.alternateCooldownIDs and #cfg.tracking.alternateCooldownIDs > 0 then
            for i, altCdID in ipairs(cfg.tracking.alternateCooldownIDs) do
              local isActive = (activeCdID == altCdID)
              local activeMarker = isActive and " |cff00ff00[ACTIVE]|r" or ""
              local spellName = ""
              if C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
                local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(altCdID)
                if info and info.spellID then
                  spellName = C_Spell.GetSpellName(info.spellID) or ""
                  if spellName ~= "" then spellName = " (" .. spellName .. ")" end
                end
              end
              table.insert(lines, string.format("|cff888888Alt %d:|r %d%s%s", i, altCdID, spellName, activeMarker))
            end
          else
            table.insert(lines, "|cff666666No alternates - verify to auto-discover|r")
          end
          
          return table.concat(lines, "\n")
        end,
        fontSize = "medium",
        order = 7.2,
        width = "full",
        hidden = function()
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and (cfg.tracking.customEnabled or cfg.tracking.trackType == "customAura" or cfg.tracking.trackType == "customCooldown") then
            return true
          end
          if not cfg or not cfg.tracking.cooldownID or cfg.tracking.cooldownID <= 0 then
            return true
          end
          return false
        end
      },
      addCdIDInput = {
        type = "input",
        name = "Add Cooldown ID",
        desc = "Manually add a cooldown ID for this bar (useful for cross-spec tracking)",
        dialogControl = "ArcUI_EditBox",
        get = function() return "" end,
        set = function(info, value)
          local cdID = tonumber(value)
          if cdID then
            local success, msg = ns.API.AddAlternateCooldownID(barNum, cdID)
            print("|cff00ccffArc UI|r: " .. msg)
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          else
            print("|cff00ccffArc UI|r: Invalid cooldown ID - must be a number")
          end
        end,
        order = 7.3,
        width = 0.9,
        hidden = function()
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and (cfg.tracking.customEnabled or cfg.tracking.trackType == "customAura" or cfg.tracking.trackType == "customCooldown") then
            return true
          end
          if not cfg or not cfg.tracking.cooldownID or cfg.tracking.cooldownID <= 0 then
            return true
          end
          return false
        end
      },
      removeCdIDDropdown = {
        type = "select",
        name = "Remove",
        desc = "Remove an alternate cooldown ID",
        values = function()
          local cfg = ns.API.GetBarConfig(barNum)
          local vals = { [""] = "-- Select --" }
          if cfg and cfg.tracking and cfg.tracking.alternateCooldownIDs then
            for i, cdID in ipairs(cfg.tracking.alternateCooldownIDs) do
              vals[tostring(cdID)] = tostring(cdID)
            end
          end
          return vals
        end,
        get = function() return "" end,
        set = function(info, value)
          if value ~= "" then
            local cdID = tonumber(value)
            if cdID then
              local success, msg = ns.API.RemoveAlternateCooldownID(barNum, cdID)
              print("|cff00ccffArc UI|r: " .. msg)
              LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            end
          end
        end,
        order = 7.4,
        width = 0.55,
        hidden = function()
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and (cfg.tracking.customEnabled or cfg.tracking.trackType == "customAura" or cfg.tracking.trackType == "customCooldown") then
            return true
          end
          if not cfg or not cfg.tracking.cooldownID or cfg.tracking.cooldownID <= 0 then
            return true
          end
          -- Hide if no alternates to remove
          if not cfg.tracking.alternateCooldownIDs or #cfg.tracking.alternateCooldownIDs == 0 then
            return true
          end
          return false
        end
      },
      linkedCdIDsBreak = {
        type = "description",
        name = "",
        order = 7.9,
        width = "full",
        hidden = function()
          if not expandedBars[barKey] then return true end
          local cfg = ns.API.GetBarConfig(barNum)
          if cfg and (cfg.tracking.customEnabled or cfg.tracking.trackType == "customAura" or cfg.tracking.trackType == "customCooldown") then
            return true
          end
          if not cfg or not cfg.tracking.cooldownID or cfg.tracking.cooldownID <= 0 then
            return true
          end
          return false
        end
      },
      delete = {
        type = "execute",
        name = "Delete",
        desc = "Remove this bar",
        func = function()
          local cfg = ns.API.GetBarConfig(barNum)
          local barName = cfg and cfg.tracking.buffName or labelPrefix .. " " .. barNum
          ShowDeleteConfirmation(barNum, "buff", barName)
        end,
        order = 8,
        width = 0.55,
        hidden = function() return not expandedBars[barKey] end
      }
    }
  }
end

-- ===================================================================
-- HELPER FUNCTIONS FOR OPTIONS
-- ===================================================================
function ns.TrackingOptions.SelectBarForAppearance(barType, barNum)
  if ns.AppearanceOptions and ns.AppearanceOptions.SetSelectedBar then
    ns.AppearanceOptions.SetSelectedBar(barType, barNum)
  end
  -- Resource bars go to resources -> appearance, all others go to bars -> appearance
  if barType == "resource" then
    LibStub("AceConfigDialog-3.0"):SelectGroup("ArcUI", "resources", "appearance")
  else
    LibStub("AceConfigDialog-3.0"):SelectGroup("ArcUI", "bars", "appearance")
  end
end

function ns.TrackingOptions.IdentifyBar(barType, barNum)
  local frame = nil
  if barType == "buff" then
    if ns.Display and ns.Display.GetDisplayFrame then
      frame = ns.Display.GetDisplayFrame(barNum)
    elseif ns.Display and ns.Display.GetBarFrame then
      frame = ns.Display.GetBarFrame(barNum)
    end
  else
    if ns.Resources and ns.Resources.GetBarFrame then
      frame = ns.Resources.GetBarFrame(barNum)
    end
  end
  
  if not frame then return end
  
  if not frame.identifyOverlay then
    frame.identifyOverlay = CreateFrame("Frame", nil, frame)
    frame.identifyOverlay:SetAllPoints()
    frame.identifyOverlay:SetFrameStrata("DIALOG")
    frame.identifyOverlay:SetFrameLevel(200)
    frame.identifyOverlay.flash = frame.identifyOverlay:CreateTexture(nil, "BACKGROUND")
    frame.identifyOverlay.flash:SetAllPoints()
    frame.identifyOverlay.flash:SetColorTexture(1, 1, 0, 0.4)
    frame.identifyOverlay.text = frame.identifyOverlay:CreateFontString(nil, "OVERLAY")
    frame.identifyOverlay.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    frame.identifyOverlay.text:SetPoint("CENTER")
    frame.identifyOverlay.text:SetTextColor(1, 1, 0, 1)
    frame.identifyOverlay.text:SetText("HERE")
  end
  
  frame.identifyOverlay:Show()
  C_Timer.After(2.5, function()
    if frame.identifyOverlay then frame.identifyOverlay:Hide() end
  end)
end

-- ===================================================================
-- BUFF/DEBUFF SETUP TABLE
-- ===================================================================
function ns.TrackingOptions.GetBuffDebuffSetupTable()
  local args = {
    -- ═══════════════════════════════════════════════════════════════════
    -- CATALOG SECTION
    -- ═══════════════════════════════════════════════════════════════════
    catalogHeader = {
      type = "header",
      name = "Aura Catalog",
      order = 1
    },
    catalogNotice = {
      type = "description",
      name = "|cffFFCC00Auras must be enabled in CD Manager to work with ArcUI.|r",
      fontSize = "medium",
      order = 1.5
    },
    catalogDesc = {
      type = "description",
      name = function()
          local displayedCount = 0
          if ns.Catalog and ns.Catalog.GetAllEntries then
            for _, entry in ipairs(ns.Catalog.GetAllEntries()) do
              if entry.isDisplayed then
                displayedCount = displayedCount + 1
              end
            end
          end
          if displayedCount > 0 then
            return string.format("|cff00ff00%d|r auras configured in CD Manager.", displayedCount)
          else
            return "|cffaaaaaaClick 'Scan CD Manager' to discover available auras.|r"
          end
        end,
        fontSize = "medium",
        order = 2
      },
      
      helpText = {
        type = "description",
        name = "|cffffffffTo add new auras: Click 'Open CD Manager' and move auras to 'Tracked Buffs' for stack bars, or 'Tracked Bars' for both stack and duration bars.|r",
        fontSize = "small",
        order = 2.5
      },
      
      scanCatalogBtn = {
        type = "execute",
        name = "Scan CD Manager",
        desc = "Scan CD Manager for tracked buffs and bars",
        func = function()
          if ns.Catalog and ns.Catalog.ScanAll then
            local success, count, buffs, bars = ns.Catalog.ScanAll()
            if success then
              print(string.format("|cff00ccffArc UI|r: Found %d tracked auras (%d buffs, %d bars)", 
                count or 0, buffs or 0, bars or 0))
            else
              print("|cff00ccffArc UI|r: " .. (count or "Failed to scan"))
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 3,
        width = 1.0
      },
      openCDMBtn = {
        type = "execute",
        name = "Open CD Manager",
        desc = "Open the Cooldown Manager settings panel",
        func = function()
          local frame = _G["CooldownViewerSettings"]
          if frame and frame.Show then
            frame:Show()
            frame:Raise()
          end
        end,
        order = 4,
        width = 0.9
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- AURA ICON GRID
      -- ═══════════════════════════════════════════════════════════════════
      iconGridHeader = {
        type = "description",
        name = function()
          local count = 0
          if ns.Catalog and ns.Catalog.GetFilteredCatalog then
            local entries = ns.Catalog.GetFilteredCatalog("tracked", "")
            for _, entry in ipairs(entries) do
              local isConfigured = entry.isDisplayed
              local passesFilter = true
              if catalogConfigFilter == "configured" and not isConfigured then
                passesFilter = false
              elseif catalogConfigFilter == "notconfigured" and isConfigured then
                passesFilter = false
              end
              if passesFilter then count = count + 1 end
            end
          end
          if count > 0 then
            if catalogConfigFilter == "notconfigured" then
              return "\n|cffff9900Auras Needing CDM Setup|r |cff888888(enable in CD Manager first)|r"
            else
              return "\n|cffffd700Available Auras|r |cff888888(click to select)|r"
            end
          else
            return "\n|cff888888No auras found. Click 'Scan CD Manager' to discover auras.|r"
          end
        end,
        fontSize = "medium",
        order = 6,
        width = "full"
      },
      
      -- Selected entry info
      selectedInfoHeader = {
        type = "header",
        name = function()
          if not selectedCatalogEntry then return "" end
          local entry = GetSelectedCatalogEntry()
          if entry then
            local prefix = entry.isCustom and "|cff00ff00[Custom]|r " or ""
            return string.format("%s|T%d:20:20:0:0|t %s", prefix, entry.icon, entry.name)
          end
          return "Selected Aura"
        end,
        order = 8,
        hidden = function() return not selectedCatalogEntry end
      },
      selectedInfo = {
        type = "description",
        name = function()
          if not selectedCatalogEntry then return "" end
          local entry = GetSelectedCatalogEntry()
          if not entry then return "" end
          
          -- Handle custom definitions
          if entry.isCustom then
            local typeText = entry.customType == "customAura" and "Custom Aura" or "Custom Cooldown"
            local barsText = ""
            if entry.arcUIBarNum then
              barsText = "\n|cff00ff00ArcUI Bar:|r #" .. entry.arcUIBarNum
            end
            
            local stackInfo = ""
            if entry.maxStacks then
              stackInfo = string.format("    |cffffd700Max Stacks:|r %d", entry.maxStacks)
            end
            if entry.maxCharges then
              stackInfo = string.format("    |cffffd700Max Charges:|r %d", entry.maxCharges)
            end
            
            -- Custom auras can create both stack and duration bars
            local canCreate = ""
            if entry.customType == "customAura" then
              canCreate = "\n|cff00ff00Can create:|r Stack Bar or Duration Bar"
            else
              canCreate = "\n|cff00ff00Can create:|r Stack Bar (Charges)"
            end
            
            return string.format("|cffffd700Type:|r %s%s%s%s",
              typeText, stackInfo, barsText, canCreate)
          end
          
          -- CDM entries
          local existingBars = ns.Catalog.FindAllArcUIBarsByCooldownID and 
                               ns.Catalog.FindAllArcUIBarsByCooldownID(selectedCatalogEntry) or {}
          local barsText = ""
          if #existingBars > 0 then
            local barsList = {}
            for _, barInfo in ipairs(existingBars) do
              table.insert(barsList, string.format("Bar %d (%s)", barInfo.barNum, barInfo.mode))
            end
            barsText = "\n|cff00ff00ArcUI Bars:|r " .. table.concat(barsList, ", ")
          end
          
          local availableText = ""
          if entry.isDisplayedAsBar or entry.isDisplayedAsBuff or entry.isDisplayed then
            -- We can get stacks AND duration from any CDM source using auraInstanceID
            availableText = "\n|cff00ff00Can create:|r Stack Bar or Duration Bar"
          end
          
          return string.format("|cffffd700Spell ID:|r %d    |cffffd700Cooldown ID:|r %d\n|cffffd700CDM Category:|r %s%s%s",
            entry.spellID or 0, entry.cooldownID or 0, entry.categoryName or "Unknown", barsText, availableText)
        end,
        fontSize = "medium",
        order = 8.5,
        hidden = function() return not selectedCatalogEntry end
      },
      
      createStackBarBtn = {
        type = "execute",
        name = "Create Stack Bar",
        desc = "Create a bar that fills based on stack count.\nYou will need to configure Type and Max Stacks after creation.",
        func = function()
          if not selectedCatalogEntry then return end
          local entry = GetSelectedCatalogEntry()
          
          -- Handle custom definitions
          if entry and entry.isCustom then
            local success, result = ns.Catalog.CreateCustomArcUIDisplay(
              entry.customDefinitionID, 
              entry.customType, 
              "bar",
              { showOnSpecs = {GetCurrentSpecIndex()} }
            )
            if success then
              print(string.format("|cff00ccffArc UI|r: Created custom bar #%d", result))
            else
              print("|cff00ccffArc UI|r: " .. (result or "Failed"))
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            return
          end
          
          -- CDM entries
          -- Use bar source if available (Tracked Bars), otherwise use icon source (Tracked Buffs)
          local sourceType = (entry and entry.isTrackedBar) and "bar" or "icon"
          local success, result = ns.Catalog.CreateArcUIDisplay(selectedCatalogEntry, "bar", {
            sourceType = sourceType,
            useDurationBar = false,
            -- Don't pass maxStacks or trackType - user must configure
            showOnSpecs = {GetCurrentSpecIndex()},
          })
          if success then
            print(string.format("|cff00ccffArc UI|r: Created bar #%d - |cffFF6600Please configure Type and Max Stacks|r", result))
          else
            print("|cff00ccffArc UI|r: " .. (result or "Failed"))
          end
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        order = 8.6,
        width = 1.2,
        hidden = function() return not selectedCatalogEntry end,
        disabled = function()
          if not selectedCatalogEntry then return true end
          local entry = GetSelectedCatalogEntry()
          -- Enable for custom definitions always
          if entry and entry.isCustom then return false end
          -- Enable if in Tracked Buffs OR Tracked Bars
          return not entry or (not entry.isTrackedBuff and not entry.isTrackedBar)
        end
      },
      createDurationBarBtn = {
        type = "execute",
        name = function()
          if not selectedCatalogEntry then return "Create Duration Bar" end
          local entry = GetSelectedCatalogEntry()
          -- Enable for custom auras (we track duration ourselves)
          if entry and entry.isCustom and entry.customType == "customAura" then
            return "Create Duration Bar"
          end
          -- Disable for custom cooldowns (no duration tracking)
          if entry and entry.isCustom and entry.customType == "customCooldown" then
            return "|cff888888Create Duration Bar|r"
          end
          -- Enable for any CDM entry (bar, buff, or displayed)
          if entry and (entry.isDisplayedAsBar or entry.isDisplayedAsBuff or entry.isDisplayed) then
            return "Create Duration Bar"
          else
            return "|cff888888Create Duration Bar|r"
          end
        end,
        desc = function()
          if not selectedCatalogEntry then 
            return "Create a bar that depletes as the buff expires."
          end
          local entry = GetSelectedCatalogEntry()
          -- Enable for custom auras
          if entry and entry.isCustom and entry.customType == "customAura" then
            return "Create a bar that depletes based on the custom aura's duration.\nYou will need to configure Max Duration after creation."
          end
          -- Disable for custom cooldowns
          if entry and entry.isCustom and entry.customType == "customCooldown" then
            return "Duration bars are not available for custom cooldowns.\nUse Stack Bar instead to show charge counts."
          end
          -- Enable for any CDM entry
          if entry and (entry.isDisplayedAsBar or entry.isDisplayedAsBuff or entry.isDisplayed) then
            return "Create a bar that depletes as the buff expires.\nYou will need to configure Type and Max Duration after creation."
          else
            return "Create a bar that depletes as the buff expires.\n\n|cffff6b6bAura must be tracked in CD Manager.|r"
          end
        end,
        func = function()
          if not selectedCatalogEntry then return end
          local entry = GetSelectedCatalogEntry()
          
          -- Handle custom auras - create duration bar
          if entry and entry.isCustom and entry.customType == "customAura" then
            local success, result = ns.Catalog.CreateCustomArcUIDisplay(
              entry.customDefinitionID, 
              entry.customType, 
              "bar",
              { 
                showOnSpecs = {GetCurrentSpecIndex()},
                useDurationBar = true,
              }
            )
            if success then
              print(string.format("|cff00ccffArc UI|r: Created custom duration bar #%d - |cffFF6600Please configure Type (buff/debuff)|r", result))
            else
              print("|cff00ccffArc UI|r: " .. (result or "Failed"))
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            return
          end
          
          -- Deny for custom cooldowns
          if entry and entry.isCustom and entry.customType == "customCooldown" then
            print("|cff00ccffArc UI|r: |cffff6b6bDuration bars are not available for custom cooldowns.|r")
            return
          end
          
          -- Check if we can actually create a duration bar (CDM entries)
          if not entry or not (entry.isDisplayedAsBar or entry.isDisplayedAsBuff or entry.isDisplayed) then
            print("|cff00ccffArc UI|r: |cffff6b6bAura must be tracked in CD Manager.|r")
            return
          end
          
          -- Determine source type based on what CDM has available
          local sourceType = entry.isDisplayedAsBar and "bar" or "icon"
          
          local success, result = ns.Catalog.CreateArcUIDisplay(selectedCatalogEntry, "bar", {
            sourceType = sourceType,
            useDurationBar = true,
            -- Don't pass maxDuration or trackType - user must configure
            showOnSpecs = {GetCurrentSpecIndex()},
          })
          if success then
            print(string.format("|cff00ccffArc UI|r: Created bar #%d - |cffFF6600Please configure Type (buff/debuff)|r", result))
          else
            print("|cff00ccffArc UI|r: " .. (result or "Failed"))
          end
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        order = 8.7,
        width = 1.2,
        hidden = function() return not selectedCatalogEntry end,
        disabled = function()
          if not selectedCatalogEntry then return true end
          local entry = GetSelectedCatalogEntry()
          -- Enable for custom auras
          if entry and entry.isCustom and entry.customType == "customAura" then return false end
          -- Disable for custom cooldowns
          if entry and entry.isCustom and entry.customType == "customCooldown" then return true end
          -- Enable for any CDM entry
          return not entry or not (entry.isDisplayedAsBar or entry.isDisplayedAsBuff or entry.isDisplayed)
        end
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- ACTIVE BARS SECTION
      -- ═══════════════════════════════════════════════════════════════════
      activeBarsHeader = {
        type = "header",
        name = "Active Buff/Debuff Bars",
        order = 20
      },
      filterCurrentSpec = {
        type = "toggle",
        name = "Show Only Current Spec",
        get = function() return showOnlyCurrentSpec end,
        set = function(info, value)
          showOnlyCurrentSpec = value
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        order = 21,
        width = 1.2
      },
      verifyTrackingBtn = {
        type = "execute",
        name = "Verify Tracking",
        desc = "Check if all bars can find their auras. Also auto-discovers alternate cooldown IDs for cross-spec tracking.",
        func = function()
          if ns.API.ValidateAllBarTracking then ns.API.ValidateAllBarTracking() end
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        order = 22,
        width = 0.8
      },
      
      -- Bar entries 1-30
      bar1 = CreateActiveBarEntry(1, 30, "bar", "Bar"),
      bar2 = CreateActiveBarEntry(2, 31, "bar", "Bar"),
      bar3 = CreateActiveBarEntry(3, 32, "bar", "Bar"),
      bar4 = CreateActiveBarEntry(4, 33, "bar", "Bar"),
      bar5 = CreateActiveBarEntry(5, 34, "bar", "Bar"),
      bar6 = CreateActiveBarEntry(6, 35, "bar", "Bar"),
      bar7 = CreateActiveBarEntry(7, 36, "bar", "Bar"),
      bar8 = CreateActiveBarEntry(8, 37, "bar", "Bar"),
      bar9 = CreateActiveBarEntry(9, 38, "bar", "Bar"),
      bar10 = CreateActiveBarEntry(10, 39, "bar", "Bar"),
      bar11 = CreateActiveBarEntry(11, 40, "bar", "Bar"),
      bar12 = CreateActiveBarEntry(12, 41, "bar", "Bar"),
      bar13 = CreateActiveBarEntry(13, 42, "bar", "Bar"),
      bar14 = CreateActiveBarEntry(14, 43, "bar", "Bar"),
      bar15 = CreateActiveBarEntry(15, 44, "bar", "Bar"),
      bar16 = CreateActiveBarEntry(16, 45, "bar", "Bar"),
      bar17 = CreateActiveBarEntry(17, 46, "bar", "Bar"),
      bar18 = CreateActiveBarEntry(18, 47, "bar", "Bar"),
      bar19 = CreateActiveBarEntry(19, 48, "bar", "Bar"),
      bar20 = CreateActiveBarEntry(20, 49, "bar", "Bar"),
      bar21 = CreateActiveBarEntry(21, 50, "bar", "Bar"),
      bar22 = CreateActiveBarEntry(22, 51, "bar", "Bar"),
      bar23 = CreateActiveBarEntry(23, 52, "bar", "Bar"),
      bar24 = CreateActiveBarEntry(24, 53, "bar", "Bar"),
      bar25 = CreateActiveBarEntry(25, 54, "bar", "Bar"),
      bar26 = CreateActiveBarEntry(26, 55, "bar", "Bar"),
      bar27 = CreateActiveBarEntry(27, 56, "bar", "Bar"),
      bar28 = CreateActiveBarEntry(28, 57, "bar", "Bar"),
      bar29 = CreateActiveBarEntry(29, 58, "bar", "Bar"),
      bar30 = CreateActiveBarEntry(30, 59, "bar", "Bar"),
      
      noActiveBars = {
        type = "description",
        name = "|cff888888No active bars. Select an aura above to create one!|r",
        fontSize = "medium",
        order = 60,
        hidden = function()
          local db = ns.API and ns.API.GetDB and ns.API.GetDB()
          if db and db.bars then
            for i, cfg in pairs(db.bars) do
              if ShouldShowBarWithType(cfg, "bar") then return true end
            end
          end
          return false
        end
      }
  }
  
  -- Add pre-created catalog icon entries (slots 1-50)
  for i = 1, MAX_CATALOG_ICONS do
    args["catalogIcon" .. i] = CreateCatalogIconEntry(i)
  end
  
  return {
    type = "group",
    name = "Bars",
    order = 1,
    args = args
  }
end

-- ===================================================================
-- ICON SETUP TABLE
-- ===================================================================
function ns.TrackingOptions.GetIconSetupTable()
  local args = {
    catalogHeader = {
      type = "header",
      name = "Aura Catalog",
      order = 1
    },
    catalogNotice = {
      type = "description",
      name = "|cffFFCC00Auras must be enabled in CD Manager to work with ArcUI.|r",
      fontSize = "medium",
      order = 1.5
    },
    catalogDesc = {
      type = "description",
      name = function()
          local displayedCount = 0
          if ns.Catalog and ns.Catalog.GetAllEntries then
            for _, entry in ipairs(ns.Catalog.GetAllEntries()) do
              if entry.isDisplayed then
                displayedCount = displayedCount + 1
              end
            end
          end
          if displayedCount > 0 then
            return string.format("|cff00ff00%d|r auras configured in CD Manager.", displayedCount)
          else
            return "|cffaaaaaaClick 'Scan CD Manager' first.|r"
          end
        end,
        fontSize = "medium",
        order = 2
      },
      
      helpText = {
        type = "description",
        name = "|cffffffffTo add new auras: Click 'Open CD Manager' and move auras to 'Tracked Buffs'. You can also use auras from 'Tracked Bars' for icons.|r",
        fontSize = "small",
        order = 2.5
      },
      
      scanCatalogBtn = {
        type = "execute",
        name = "Scan CD Manager",
        func = function()
          if ns.Catalog and ns.Catalog.ScanAll then
            local success, count = ns.Catalog.ScanAll()
            if success then
              print(string.format("|cff00ccffArc UI|r: Found %d tracked auras", count or 0))
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
          end
        end,
        order = 3,
        width = 1.0
      },
      
      openCDMBtn = {
        type = "execute",
        name = "Open CD Manager",
        desc = "Open the Cooldown Manager settings panel",
        func = function()
          local frame = _G["CooldownViewerSettings"]
          if frame and frame.Show then
            frame:Show()
            frame:Raise()
          end
        end,
        order = 4,
        width = 0.9
      },
      
      -- ═══════════════════════════════════════════════════════════════════
      -- AURA ICON GRID (for Icons tab)
      -- ═══════════════════════════════════════════════════════════════════
      iconGridHeader = {
        type = "description",
        name = function()
          local count = 0
          if ns.Catalog and ns.Catalog.GetFilteredCatalog then
            local entries = ns.Catalog.GetFilteredCatalog("tracked", "")
            for _, entry in ipairs(entries) do
              local isConfigured = entry.isDisplayed
              local passesFilter = true
              if catalogConfigFilter == "configured" and not isConfigured then
                passesFilter = false
              elseif catalogConfigFilter == "notconfigured" and isConfigured then
                passesFilter = false
              end
              if passesFilter then count = count + 1 end
            end
          end
          if count > 0 then
            if catalogConfigFilter == "notconfigured" then
              return "\n|cffff9900Auras Needing CDM Setup|r |cff888888(enable in CD Manager first)|r"
            else
              return "\n|cffffd700Available Auras|r |cff888888(click to select)|r"
            end
          else
            return "\n|cff888888No auras found. Click 'Scan CD Manager' to discover auras.|r"
          end
        end,
        fontSize = "medium",
        order = 6,
        width = "full"
      },
      
      createIconBtn = {
        type = "execute",
        name = "Create Icon",
        desc = "Create an icon for this aura. Works with both Tracked Buffs and Tracked Bars.",
        func = function()
          if not selectedCatalogEntry then return end
          local entry = GetSelectedCatalogEntry()
          
          -- Handle custom definitions
          if entry and entry.isCustom then
            local success, result = ns.Catalog.CreateCustomArcUIDisplay(
              entry.customDefinitionID, 
              entry.customType, 
              "icon",
              { showOnSpecs = {GetCurrentSpecIndex()} }
            )
            if success then
              print(string.format("|cff00ccffArc UI|r: Created custom icon #%d", result))
              selectedCatalogEntry = nil
            else
              print("|cff00ccffArc UI|r: " .. (result or "Failed"))
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            return
          end
          
          -- CDM entries
          local success, result = ns.Catalog.CreateIcon(selectedCatalogEntry, 10, {GetCurrentSpecIndex()})
          if success then
            print(string.format("|cff00ccffArc UI|r: Created icon #%d - |cffFF6600Please configure Max Stacks|r", result))
            selectedCatalogEntry = nil
          else
            print("|cff00ccffArc UI|r: " .. (result or "Failed"))
          end
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        order = 10,
        width = 1.2,
        hidden = function() return not selectedCatalogEntry end,
        disabled = function()
          if not selectedCatalogEntry then return true end
          local entry = GetSelectedCatalogEntry()
          -- Enable for custom definitions
          if entry and entry.isCustom then return false end
          -- Allow both Tracked Buffs AND Tracked Bars for icons
          return not entry or (not entry.isTrackedBuff and not entry.isTrackedBar)
        end
      },
      
      activeIconsHeader = {
        type = "header",
        name = "Active Icons",
        order = 20
      },
      filterCurrentSpecIcons = {
        type = "toggle",
        name = "Show Only Current Spec",
        get = function() return showOnlyCurrentSpec end,
        set = function(info, value)
          showOnlyCurrentSpec = value
          LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        order = 21,
        width = 1.2
      },
      
      -- Icon entries 1-30
      icon1 = CreateActiveBarEntry(1, 30, "icon", "Icon"),
      icon2 = CreateActiveBarEntry(2, 31, "icon", "Icon"),
      icon3 = CreateActiveBarEntry(3, 32, "icon", "Icon"),
      icon4 = CreateActiveBarEntry(4, 33, "icon", "Icon"),
      icon5 = CreateActiveBarEntry(5, 34, "icon", "Icon"),
      icon6 = CreateActiveBarEntry(6, 35, "icon", "Icon"),
      icon7 = CreateActiveBarEntry(7, 36, "icon", "Icon"),
      icon8 = CreateActiveBarEntry(8, 37, "icon", "Icon"),
      icon9 = CreateActiveBarEntry(9, 38, "icon", "Icon"),
      icon10 = CreateActiveBarEntry(10, 39, "icon", "Icon"),
      icon11 = CreateActiveBarEntry(11, 40, "icon", "Icon"),
      icon12 = CreateActiveBarEntry(12, 41, "icon", "Icon"),
      icon13 = CreateActiveBarEntry(13, 42, "icon", "Icon"),
      icon14 = CreateActiveBarEntry(14, 43, "icon", "Icon"),
      icon15 = CreateActiveBarEntry(15, 44, "icon", "Icon"),
      icon16 = CreateActiveBarEntry(16, 45, "icon", "Icon"),
      icon17 = CreateActiveBarEntry(17, 46, "icon", "Icon"),
      icon18 = CreateActiveBarEntry(18, 47, "icon", "Icon"),
      icon19 = CreateActiveBarEntry(19, 48, "icon", "Icon"),
      icon20 = CreateActiveBarEntry(20, 49, "icon", "Icon"),
      icon21 = CreateActiveBarEntry(21, 50, "icon", "Icon"),
      icon22 = CreateActiveBarEntry(22, 51, "icon", "Icon"),
      icon23 = CreateActiveBarEntry(23, 52, "icon", "Icon"),
      icon24 = CreateActiveBarEntry(24, 53, "icon", "Icon"),
      icon25 = CreateActiveBarEntry(25, 54, "icon", "Icon"),
      icon26 = CreateActiveBarEntry(26, 55, "icon", "Icon"),
      icon27 = CreateActiveBarEntry(27, 56, "icon", "Icon"),
      icon28 = CreateActiveBarEntry(28, 57, "icon", "Icon"),
      icon29 = CreateActiveBarEntry(29, 58, "icon", "Icon"),
      icon30 = CreateActiveBarEntry(30, 59, "icon", "Icon"),
      
      noActiveIcons = {
        type = "description",
        name = "|cff888888No active icons.|r",
        fontSize = "medium",
        order = 60,
        hidden = function()
          local db = ns.API and ns.API.GetDB and ns.API.GetDB()
          if db and db.bars then
            for i, cfg in pairs(db.bars) do
              if ShouldShowBarWithType(cfg, "icon") then return true end
            end
          end
          return false
        end
      }
  }
  
  -- Add pre-created catalog icon entries (slots 1-50)
  for i = 1, MAX_CATALOG_ICONS do
    args["catalogIcon" .. i] = CreateCatalogIconEntry(i)
  end
  
  return {
    type = "group",
    name = "Icons",
    order = 2,
    args = args
  }
end

-- ===================================================================
-- RESOURCE SETUP TABLE
-- ===================================================================

function ns.TrackingOptions.GetResourceSetupTable()
  -- expandedResources is now at module level (line 25)
  
  -- Get icon for power type (primary resources)
  local function GetPowerIcon(powerType)
    local icons = {
      [0] = 136116,   -- Mana
      [1] = 132352,   -- Rage
      [2] = 132150,   -- Focus
      [3] = 132173,   -- Energy
      [4] = 132287,   -- Combo Points
      [5] = 135277,   -- Runes
      [6] = 458718,   -- Runic Power (Death Knight)
      [7] = 136163,   -- Soul Shards
      [8] = 136096,   -- Astral Power (Balance)
      [9] = 135959,   -- Holy Power
      [11] = 136048,  -- Maelstrom
      [12] = 606548,  -- Chi
      [13] = 132840,  -- Insanity
      [16] = 135932,  -- Arcane Charges
      [17] = 1344651, -- Fury
      [18] = 1344647, -- Pain
      [19] = 4630435, -- Essence
    }
    return icons[powerType] or 134400
  end
  
  -- Get icon for secondary resource type
  local function GetSecondaryIcon(secondaryType)
    local icons = {
      comboPoints = 132287,   -- Combo Points
      holyPower = 135959,     -- Holy Power
      chi = 606548,           -- Chi
      runes = 135277,         -- Runes
      soulShards = 136163,    -- Soul Shards
      essence = 4630435,      -- Essence
      arcaneCharges = 135932, -- Arcane Charges
      stagger = 611419,       -- Stagger (Monk keg icon)
      soulFragments = 1355117, -- Soul Fragments (DH)
    }
    return icons[secondaryType] or 134400
  end
  
  -- Secondary resource definitions with class/spec availability
  local SECONDARY_RESOURCES = {
    { id = "comboPoints",   name = "Combo Points",   classes = {"ROGUE"}, specs = {[103]=true} },  -- Rogue, Feral Druid
    { id = "holyPower",     name = "Holy Power",     classes = {"PALADIN"} },
    { id = "chi",           name = "Chi",            classes = {}, specs = {[269]=true} },  -- Windwalker
    { id = "runes",         name = "Runes",          classes = {"DEATHKNIGHT"} },
    { id = "soulShards",    name = "Soul Shards",    classes = {"WARLOCK"} },
    { id = "essence",       name = "Essence",        classes = {"EVOKER"} },
    { id = "arcaneCharges", name = "Arcane Charges", classes = {}, specs = {[62]=true} },  -- Arcane Mage
    { id = "stagger",       name = "Stagger",        classes = {}, specs = {[268]=true} },  -- Brewmaster
    { id = "soulFragments", name = "Soul Fragments", classes = {}, specs = {[581]=true} },  -- Vengeance DH
  }
  
  -- Check if secondary resource is available for current class/spec
  local function IsSecondaryAvailable(secondaryType)
    local _, playerClass = UnitClass("player")
    local currentSpec = GetSpecialization()
    local specID = currentSpec and GetSpecializationInfo(currentSpec)
    
    for _, resource in ipairs(SECONDARY_RESOURCES) do
      if resource.id == secondaryType then
        -- Check class
        for _, class in ipairs(resource.classes or {}) do
          if class == playerClass then return true end
        end
        -- Check spec
        if resource.specs and specID and resource.specs[specID] then
          return true
        end
        return false
      end
    end
    return false
  end
  
  -- Create collapsible resource bar entry (matches Bars tab style)
  local function CreateResourceBarEntry(barNum, orderBase)
    local barKey = "resource_" .. barNum
    
    return {
      type = "group",
      name = "",
      inline = true,
      order = orderBase,
      hidden = function()
        local cfg = ns.API.GetResourceBarConfig(barNum)
        if not cfg or not cfg.tracking.enabled then return true end
        return false
      end,
      args = {
        header = {
          type = "toggle",
          name = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.tracking.enabled then
              local name = cfg.tracking.powerName or "(Not configured)"
              local resourceCategory = cfg.tracking.resourceCategory or "primary"
              local icon
              
              if resourceCategory == "secondary" then
                icon = GetSecondaryIcon(cfg.tracking.secondaryType)
              else
                icon = GetPowerIcon(cfg.tracking.powerType)
              end
              
              -- Check talent conditions
              local talentLabel = ""
              if cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
                if not AreTalentConditionsMet(cfg) then
                  talentLabel = " |cffff9900[Talent Hidden]|r"
                end
              end
              
              -- Add category label for secondary
              local categoryLabel = ""
              if resourceCategory == "secondary" then
                categoryLabel = " |cff00ccff(Secondary)|r"
              end
              
              return string.format("|T%d:16:16:0:0|t Resource %d: %s%s%s", icon, barNum, name, categoryLabel, talentLabel)
            end
            return ""
          end,
          desc = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
              if not AreTalentConditionsMet(cfg) then
                return "Click to expand/collapse\n\n|cffff9900Bar hidden: Talent condition not met|r"
              end
            end
            return "Click to expand/collapse"
          end,
          dialogControl = "CollapsibleHeader",
          get = function() return expandedResources[barKey] end,
          set = function(info, value) expandedResources[barKey] = value end,
          order = 0,
          width = "full",
        },
        show = {
          type = "toggle",
          name = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
              if not AreTalentConditionsMet(cfg) then
                return "|cff888888Show|r"
              end
            end
            return "Show"
          end,
          desc = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
              if not AreTalentConditionsMet(cfg) then
                return "|cffff9900Hidden due to talent condition not met|r\n\nChange your talents or edit the talent condition to show this bar."
              end
            end
            return "Show/hide this resource bar"
          end,
          get = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
              if not AreTalentConditionsMet(cfg) then
                return false
              end
            end
            return cfg and cfg.display.enabled
          end,
          set = function(info, value)
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg then
              if value and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
                if not AreTalentConditionsMet(cfg) then
                  print("|cff00ccffArc UI|r: Cannot show bar - talent condition not met")
                  return
                end
              end
              cfg.display.enabled = value
              if ns.Resources and ns.Resources.ApplyAppearance then
                ns.Resources.ApplyAppearance(barNum)
              end
            end
          end,
          order = 1,
          width = 0.45,
          hidden = function() return not expandedResources[barKey] end
        },
        talentCondLabel = {
          type = "description",
          name = "|cffffd700Talent Conditions:|r",
          order = 2.0,
          width = 0.65,
          fontSize = "medium",
          hidden = function() return not expandedResources[barKey] end
        },
        talentCondBtn = {
          type = "execute",
          name = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
              return "|cff00ff00Active|r"
            end
            return "None"
          end,
          desc = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0 then
              local summary = ns.TalentPicker and ns.TalentPicker.GetConditionSummary and 
                              ns.TalentPicker.GetConditionSummary(cfg.behavior.talentConditions, cfg.behavior.talentMatchMode) or "Active"
              return summary .. "\n\n|cffffd700Click to edit talent conditions|r"
            end
            return "Show/hide this bar based on your talent choices.\n\n|cffffd700Click to open talent picker|r"
          end,
          func = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            local existingConditions = cfg and cfg.behavior and cfg.behavior.talentConditions
            local matchMode = cfg and cfg.behavior and cfg.behavior.talentMatchMode or "all"
            
            if ns.TalentPicker and ns.TalentPicker.OpenPicker then
              ns.TalentPicker.OpenPicker(existingConditions, matchMode, function(conditions, newMatchMode)
                local barCfg = ns.API.GetResourceBarConfig(barNum)
                if barCfg then
                  if not barCfg.behavior then barCfg.behavior = {} end
                  barCfg.behavior.talentConditions = conditions
                  barCfg.behavior.talentMatchMode = newMatchMode
                  LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end
              end)
            else
              print("|cff00ccffArc UI|r: Talent picker not available")
            end
          end,
          order = 2.1,
          width = 0.45,
          hidden = function() return not expandedResources[barKey] end
        },
        talentCondClear = {
          type = "execute",
          name = "X",
          desc = "Clear talent conditions",
          func = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior then
              cfg.behavior.talentConditions = nil
              cfg.behavior.talentMatchMode = nil
              if ns.Resources and ns.Resources.ApplyAppearance then
                ns.Resources.ApplyAppearance(barNum)
              end
              LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            end
          end,
          order = 2.2,
          width = 0.25,
          hidden = function()
            if not expandedResources[barKey] then return true end
            local cfg = ns.API.GetResourceBarConfig(barNum)
            return not (cfg and cfg.behavior and cfg.behavior.talentConditions and #cfg.behavior.talentConditions > 0)
          end
        },
        lineBreak1 = {
          type = "description",
          name = "",
          order = 2.9,
          width = "full",
          hidden = function() return not expandedResources[barKey] end
        },
        specLabel = {
          type = "description",
          name = "|cffffd700Specs:|r",
          order = 3.0,
          width = 0.35,
          fontSize = "medium",
          hidden = function() return not expandedResources[barKey] end
        },
        specAll = {
          type = "toggle",
          name = "All",
          desc = "Show on all specs",
          get = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            return not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs or #cfg.behavior.showOnSpecs == 0
          end,
          set = function(info, value)
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg then
              if not cfg.behavior then cfg.behavior = {} end
              cfg.behavior.showOnSpecs = value and {} or { GetSpecialization() or 1 }
              if ns.Resources and ns.Resources.RefreshAllBars then
                ns.Resources.RefreshAllBars()
              end
            end
          end,
          order = 3.1,
          width = 0.35,
          hidden = function() return not expandedResources[barKey] end
        },
        spec1 = {
          type = "toggle",
          name = function()
            local _, specName, _, specIcon = GetSpecializationInfo(1)
            if specIcon and specName then
              return string.format("|T%s:14:14:0:0|t %s", specIcon, specName)
            end
            return specName or "Spec 1"
          end,
          get = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.showOnSpecs then
              for _, s in ipairs(cfg.behavior.showOnSpecs) do
                if s == 1 then return true end
              end
            end
            return false
          end,
          set = function(info, value)
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg then
              if not cfg.behavior then cfg.behavior = {} end
              if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
              if value then
                table.insert(cfg.behavior.showOnSpecs, 1)
              else
                for i, s in ipairs(cfg.behavior.showOnSpecs) do
                  if s == 1 then table.remove(cfg.behavior.showOnSpecs, i) break end
                end
              end
              if ns.Resources and ns.Resources.RefreshAllBars then
                ns.Resources.RefreshAllBars()
              end
            end
          end,
          order = 3.2,
          width = 0.85,
          hidden = function()
            if not expandedResources[barKey] then return true end
            local cfg = ns.API.GetResourceBarConfig(barNum)
            return not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs or #cfg.behavior.showOnSpecs == 0
          end
        },
        spec2 = {
          type = "toggle",
          name = function()
            local _, specName, _, specIcon = GetSpecializationInfo(2)
            if specIcon and specName then
              return string.format("|T%s:14:14:0:0|t %s", specIcon, specName)
            end
            return specName or "Spec 2"
          end,
          get = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.showOnSpecs then
              for _, s in ipairs(cfg.behavior.showOnSpecs) do
                if s == 2 then return true end
              end
            end
            return false
          end,
          set = function(info, value)
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg then
              if not cfg.behavior then cfg.behavior = {} end
              if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
              if value then
                table.insert(cfg.behavior.showOnSpecs, 2)
              else
                for i, s in ipairs(cfg.behavior.showOnSpecs) do
                  if s == 2 then table.remove(cfg.behavior.showOnSpecs, i) break end
                end
              end
              if ns.Resources and ns.Resources.RefreshAllBars then
                ns.Resources.RefreshAllBars()
              end
            end
          end,
          order = 3.3,
          width = 0.85,
          hidden = function()
            if not expandedResources[barKey] then return true end
            local cfg = ns.API.GetResourceBarConfig(barNum)
            return not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs or #cfg.behavior.showOnSpecs == 0
          end
        },
        spec3 = {
          type = "toggle",
          name = function()
            local _, specName, _, specIcon = GetSpecializationInfo(3)
            if specIcon and specName then
              return string.format("|T%s:14:14:0:0|t %s", specIcon, specName)
            end
            return specName or "Spec 3"
          end,
          get = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.showOnSpecs then
              for _, s in ipairs(cfg.behavior.showOnSpecs) do
                if s == 3 then return true end
              end
            end
            return false
          end,
          set = function(info, value)
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg then
              if not cfg.behavior then cfg.behavior = {} end
              if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
              if value then
                table.insert(cfg.behavior.showOnSpecs, 3)
              else
                for i, s in ipairs(cfg.behavior.showOnSpecs) do
                  if s == 3 then table.remove(cfg.behavior.showOnSpecs, i) break end
                end
              end
              if ns.Resources and ns.Resources.RefreshAllBars then
                ns.Resources.RefreshAllBars()
              end
            end
          end,
          order = 3.4,
          width = 0.85,
          hidden = function()
            if not expandedResources[barKey] then return true end
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs or #cfg.behavior.showOnSpecs == 0 then return true end
            return GetNumSpecializations() < 3
          end
        },
        spec4 = {
          type = "toggle",
          name = function()
            local _, specName, _, specIcon = GetSpecializationInfo(4)
            if specIcon and specName then
              return string.format("|T%s:14:14:0:0|t %s", specIcon, specName)
            end
            return specName or "Spec 4"
          end,
          get = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg and cfg.behavior and cfg.behavior.showOnSpecs then
              for _, s in ipairs(cfg.behavior.showOnSpecs) do
                if s == 4 then return true end
              end
            end
            return false
          end,
          set = function(info, value)
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if cfg then
              if not cfg.behavior then cfg.behavior = {} end
              if not cfg.behavior.showOnSpecs then cfg.behavior.showOnSpecs = {} end
              if value then
                table.insert(cfg.behavior.showOnSpecs, 4)
              else
                for i, s in ipairs(cfg.behavior.showOnSpecs) do
                  if s == 4 then table.remove(cfg.behavior.showOnSpecs, i) break end
                end
              end
              if ns.Resources and ns.Resources.RefreshAllBars then
                ns.Resources.RefreshAllBars()
              end
            end
          end,
          order = 3.5,
          width = 0.85,
          hidden = function()
            if not expandedResources[barKey] then return true end
            local cfg = ns.API.GetResourceBarConfig(barNum)
            if not cfg or not cfg.behavior or not cfg.behavior.showOnSpecs or #cfg.behavior.showOnSpecs == 0 then return true end
            return GetNumSpecializations() < 4
          end
        },
        spacer = {
          type = "description",
          name = "",
          order = 5.9,
          width = "full",
          hidden = function() return not expandedResources[barKey] end
        },
        appearance = {
          type = "execute",
          name = "Edit",
          desc = "Configure appearance",
          func = function() ns.TrackingOptions.SelectBarForAppearance("resource", barNum) end,
          order = 6,
          width = 0.45,
          hidden = function() return not expandedResources[barKey] end
        },
        identify = {
          type = "execute",
          name = "Find",
          desc = "Flash this bar on screen",
          func = function() ns.TrackingOptions.IdentifyBar("resource", barNum) end,
          order = 7,
          width = 0.45,
          hidden = function() return not expandedResources[barKey] end
        },
        delete = {
          type = "execute",
          name = "Delete",
          desc = "Remove this resource bar",
          func = function()
            local cfg = ns.API.GetResourceBarConfig(barNum)
            local barName = cfg and cfg.tracking.powerName or "Resource " .. barNum
            ShowDeleteConfirmation(barNum, "resource", barName)
          end,
          order = 8,
          width = 0.55,
          hidden = function() return not expandedResources[barKey] end
        }
      }
    }
  end
  
  -- Create power type icon button for the grid (PRIMARY resources)
  local function CreatePowerIconEntry(powerType, orderNum)
    local powerName = ALL_POWER_TYPES[powerType]
    local icon = GetPowerIcon(powerType)
    
    return {
      type = "execute",
      name = " ",
      desc = "|cffffd700" .. powerName .. "|r\n\n|cff888888Click to create a resource bar|r",
      func = function()
        local barNum = ns.API.InitializeNewResourceBar(powerType, powerName, "primary", nil)
        if barNum then
          print(string.format("|cff00ccffArc UI|r: Created resource bar #%d for %s", barNum, powerName))
        else
          print("|cff00ccffArc UI|r: All resource bar slots are full")
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      image = icon,
      imageWidth = 32,
      imageHeight = 32,
      order = orderNum,
      width = 0.22,
      hidden = function()
        -- Only show power types available to this class/spec
        local _, playerClass = UnitClass("player")
        local classPowers = CLASS_POWER_TYPES[playerClass] or {}
        local currentSpec = GetSpecialization() or 1
        local specPowers = SPEC_POWER_TYPES[playerClass] and SPEC_POWER_TYPES[playerClass][currentSpec] or {}
        
        -- Check if this power type is available
        for _, pType in ipairs(classPowers) do
          if pType == powerType and not SECONDARY_POWER_TYPES[powerType] then
            return false
          end
        end
        for _, pType in ipairs(specPowers) do
          if pType == powerType and not SECONDARY_POWER_TYPES[powerType] then
            return false
          end
        end
        return true
      end
    }
  end
  
  -- Create secondary resource icon button for the grid
  local function CreateSecondaryIconEntry(secondaryType, displayName, orderNum)
    local icon = GetSecondaryIcon(secondaryType)
    
    return {
      type = "execute",
      name = " ",
      desc = "|cff00ccff" .. displayName .. "|r |cff888888(Secondary)|r\n\n|cff888888Click to create a resource bar|r",
      func = function()
        local barNum = ns.API.InitializeNewResourceBar(nil, displayName, "secondary", secondaryType)
        if barNum then
          print(string.format("|cff00ccffArc UI|r: Created secondary resource bar #%d for %s", barNum, displayName))
        else
          print("|cff00ccffArc UI|r: All resource bar slots are full")
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end,
      image = icon,
      imageWidth = 32,
      imageHeight = 32,
      order = orderNum,
      width = 0.22,
      hidden = function()
        return true  -- DISABLED: Secondary resources coming soon
      end
    }
  end
  
  return {
    type = "group",
    name = "Resources",
    order = 2,
    args = {
      description = {
        type = "description",
        name = "|cff00ccffResource bars|r track power types like Mana, Energy, Maelstrom, etc.\nClick an icon below to create a new resource bar.\n",
        fontSize = "medium",
        order = 0
      },
      
      createHeader = {
        type = "description",
        name = "|cffffd700Available Resources|r",
        fontSize = "medium",
        order = 1
      },
      
      -- Primary power type icon grid
      powerMana = CreatePowerIconEntry(0, 2.0),
      powerRage = CreatePowerIconEntry(1, 2.1),
      powerFocus = CreatePowerIconEntry(2, 2.2),
      powerEnergy = CreatePowerIconEntry(3, 2.3),
      powerRunicPower = CreatePowerIconEntry(6, 2.4),
      powerAstralPower = CreatePowerIconEntry(8, 2.5),
      powerMaelstrom = CreatePowerIconEntry(11, 2.6),
      powerInsanity = CreatePowerIconEntry(13, 2.7),
      powerFury = CreatePowerIconEntry(17, 2.8),
      powerPain = CreatePowerIconEntry(18, 2.9),
      
      noPowerTypes = {
        type = "description",
        name = "|cff888888No primary resource types available for your class.|r",
        fontSize = "medium",
        order = 3,
        hidden = function()
          local _, playerClass = UnitClass("player")
          local classPowers = CLASS_POWER_TYPES[playerClass] or {}
          for _, pType in ipairs(classPowers) do
            if not SECONDARY_POWER_TYPES[pType] then
              return true
            end
          end
          -- Also check spec-specific power types
          local currentSpec = GetSpecialization() or 1
          local specPowers = SPEC_POWER_TYPES[playerClass] and SPEC_POWER_TYPES[playerClass][currentSpec] or {}
          for _, pType in ipairs(specPowers) do
            if not SECONDARY_POWER_TYPES[pType] then
              return true
            end
          end
          return false
        end
      },
      
      -- Secondary resources section (COMING SOON)
      secondaryHeader = {
        type = "description",
        name = "\n|cff00ccffSecondary Resources|r |cffFFFF00(Coming Soon!)|r",
        fontSize = "medium",
        order = 4
      },
      
      -- Secondary resource icon grid
      secComboPoints = CreateSecondaryIconEntry("comboPoints", "Combo Points", 5.0),
      secHolyPower = CreateSecondaryIconEntry("holyPower", "Holy Power", 5.1),
      secChi = CreateSecondaryIconEntry("chi", "Chi", 5.2),
      secRunes = CreateSecondaryIconEntry("runes", "Runes", 5.3),
      secSoulShards = CreateSecondaryIconEntry("soulShards", "Soul Shards", 5.4),
      secEssence = CreateSecondaryIconEntry("essence", "Essence", 5.5),
      secArcaneCharges = CreateSecondaryIconEntry("arcaneCharges", "Arcane Charges", 5.6),
      secStagger = CreateSecondaryIconEntry("stagger", "Stagger", 5.7),
      secSoulFragments = CreateSecondaryIconEntry("soulFragments", "Soul Fragments", 5.8),
      
      noSecondaryTypes = {
        type = "description",
        name = "|cff888888Combo Points, Holy Power, Runes, Chi, Soul Shards, Essence, Arcane Charges, Stagger, Soul Fragments - coming in a future update.|r",
        fontSize = "medium",
        order = 6,
        hidden = false  -- Always show the coming soon message
      },
      
      activeHeader = {
        type = "header",
        name = "Active Resource Bars",
        order = 20
      },
      
      resource1 = CreateResourceBarEntry(1, 30),
      resource2 = CreateResourceBarEntry(2, 31),
      resource3 = CreateResourceBarEntry(3, 32),
      resource4 = CreateResourceBarEntry(4, 33),
      resource5 = CreateResourceBarEntry(5, 34),
      resource6 = CreateResourceBarEntry(6, 35),
      resource7 = CreateResourceBarEntry(7, 36),
      resource8 = CreateResourceBarEntry(8, 37),
      resource9 = CreateResourceBarEntry(9, 38),
      resource10 = CreateResourceBarEntry(10, 39),
      
      noActiveResources = {
        type = "description",
        name = "\n|cff888888No active resource bars. Click an icon above to create one.|r",
        fontSize = "medium",
        order = 60,
        hidden = function()
          local db = ns.API and ns.API.GetDB and ns.API.GetDB()
          if db and db.resourceBars then
            for i, cfg in pairs(db.resourceBars) do
              if cfg and cfg.tracking and cfg.tracking.enabled then
                return true
              end
            end
          end
          return false
        end
      }
    }
  }
end

-- ===================================================================
-- END OF ArcUI_TrackingOptions.lua
-- ===================================================================