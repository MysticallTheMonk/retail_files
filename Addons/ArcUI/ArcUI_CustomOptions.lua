-- ===================================================================
-- ArcUI_CustomOptions.lua
-- Options panel for creating and editing custom aura/cooldown definitions
-- Integrates with the Catalog system for bar/icon creation
-- ===================================================================

local ADDON, ns = ...
ns.CustomOptions = ns.CustomOptions or {}

local AceGUI = LibStub("AceGUI-3.0")

-- ===================================================================
-- STATE
-- ===================================================================
local selectedAuraID = nil
local selectedCooldownID = nil

-- ===================================================================
-- HELPER: Get Spell Info
-- ===================================================================
local function GetSpellInfo(spellID)
  if not spellID or spellID == 0 then return nil end
  local name = C_Spell.GetSpellName(spellID)
  local icon = C_Spell.GetSpellTexture(spellID)
  return name, icon
end

-- ===================================================================
-- CUSTOM AURAS OPTIONS TABLE
-- ===================================================================
function ns.CustomOptions.GetAurasOptionsTable()
  return {
    type = "group",
    name = "Custom Auras",
    order = 1,
    args = {
      description = {
        type = "description",
        name = "|cff00ccffCustom Auras|r allow you to track buffs that aren't in CD Manager.\n" ..
               "These use |cffffd700UNIT_SPELLCAST_SUCCEEDED|r to detect when spells are cast.\n" ..
               "|cffff6b6bOnly tracks deterministic events|r - no proc chances.\n\n",
        order = 1,
        fontSize = "medium",
      },
      
      createNew = {
        type = "execute",
        name = "Create New Custom Aura",
        desc = "Create a new custom aura definition",
        order = 2,
        width = 1.5,
        func = function()
          ns.CustomOptions.ShowAuraCreationDialog()
        end,
      },
      
      spacer1 = { type = "description", name = "\n", order = 3 },
      
      existingHeader = {
        type = "header",
        name = "Existing Custom Auras",
        order = 10,
      },
      
      existingAuras = {
        type = "group",
        name = "",
        order = 11,
        inline = true,
        func = function() end,  -- Force refresh
        args = {},  -- Will be populated dynamically
      },
    }
  }
end

-- Dynamically get aura options (called by AceConfig)
function ns.CustomOptions.GetAurasDynamicArgs()
  local baseArgs = {
    description = {
      type = "description",
      name = "|cff00ccffCustom Auras|r allow you to track buffs that aren't in CD Manager.\n" ..
             "These use |cffffd700UNIT_SPELLCAST_SUCCEEDED|r to detect when spells are cast.\n" ..
             "|cffff6b6bOnly tracks deterministic events|r - no proc chances.\n\n",
      order = 1,
      fontSize = "medium",
    },
    
    createNew = {
      type = "execute",
      name = "Create New Custom Aura",
      desc = "Create a new custom aura definition",
      order = 2,
      width = 1.5,
      func = function()
        ns.CustomOptions.ShowAuraCreationDialog()
      end,
    },
    
    spacer1 = { type = "description", name = "\n", order = 3 },
    
    existingHeader = {
      type = "header",
      name = "Existing Custom Auras",
      order = 10,
    },
  }
  
  -- Add dynamic aura list
  local auraArgs = ns.CustomOptions.BuildAuraListArgs()
  local order = 11
  for key, arg in pairs(auraArgs) do
    arg.order = order + (arg.order or 0) / 100
    baseArgs[key] = arg
  end
  
  return baseArgs
end

function ns.CustomOptions.BuildAuraListArgs()
  local args = {}
  local auras = ns.CustomTracking and ns.CustomTracking.GetAllAuras() or {}
  
  local order = 1
  local hasAuras = false
  
  for auraID, def in pairs(auras) do
    hasAuras = true
    local iconTexture = def.iconTextureID or 134400
    local name = def.name or "Unnamed"
    
    -- Icon and name display
    args["icon_" .. auraID] = {
      type = "description",
      name = string.format("|T%d:20:20:0:0|t |cffffd700%s|r", iconTexture, name),
      order = order,
      width = 1.2,
    }
    
    -- Trigger spells
    local triggerText = ""
    if def.triggers then
      local spellNames = {}
      for _, trigger in ipairs(def.triggers) do
        local spellName = GetSpellInfo(trigger.spellID) or ("ID: " .. tostring(trigger.spellID))
        table.insert(spellNames, spellName)
      end
      triggerText = table.concat(spellNames, ", ")
    end
    
    args["triggers_" .. auraID] = {
      type = "description",
      name = "|cff888888Triggers: " .. triggerText .. "|r",
      order = order + 0.1,
      width = 1.2,
    }
    
    -- Edit button
    args["edit_" .. auraID] = {
      type = "execute",
      name = "Edit",
      order = order + 0.2,
      width = 0.4,
      func = function()
        ns.CustomOptions.ShowAuraEditDialog(auraID)
      end,
    }
    
    -- Delete button
    args["delete_" .. auraID] = {
      type = "execute",
      name = "Delete",
      order = order + 0.3,
      width = 0.4,
      func = function()
        StaticPopup_Show("ARCUI_DELETE_CUSTOM_AURA", name, nil, { auraID = auraID })
      end,
    }
    
    -- Spacer
    args["spacer_" .. auraID] = {
      type = "description",
      name = "",
      order = order + 0.9,
      width = "full",
    }
    
    order = order + 1
  end
  
  if not hasAuras then
    args.noAuras = {
      type = "description",
      name = "|cff666666No custom auras defined yet. Click 'Create New Custom Aura' above.|r",
      order = 1,
    }
  end
  
  return args
end

-- ===================================================================
-- CUSTOM COOLDOWNS OPTIONS TABLE
-- ===================================================================
function ns.CustomOptions.GetCooldownsOptionsTable()
  return {
    type = "group",
    name = "Custom Cooldowns",
    order = 2,
    args = {
      description = {
        type = "description",
        name = "|cff00ccffCustom Cooldowns|r let you track ability cooldowns not in CD Manager.\n" ..
               "Supports charges, cooldown reduction, and cooldown resets.\n\n",
        order = 1,
        fontSize = "medium",
      },
      
      createNew = {
        type = "execute",
        name = "Create New Custom Cooldown",
        desc = "Create a new custom cooldown definition",
        order = 2,
        width = 1.5,
        func = function()
          ns.CustomOptions.ShowCooldownCreationDialog()
        end,
      },
      
      spacer1 = { type = "description", name = "\n", order = 3 },
      
      existingHeader = {
        type = "header",
        name = "Existing Custom Cooldowns",
        order = 10,
      },
      
      existingCooldowns = {
        type = "group",
        name = "",
        order = 11,
        inline = true,
        args = {},  -- Will be populated dynamically
      },
    }
  }
end

-- Dynamically get cooldown options (called by AceConfig)
function ns.CustomOptions.GetCooldownsDynamicArgs()
  local baseArgs = {
    description = {
      type = "description",
      name = "|cff00ccffCustom Cooldowns|r let you track ability cooldowns not in CD Manager.\n" ..
             "Supports charges, cooldown reduction, and cooldown resets.\n\n",
      order = 1,
      fontSize = "medium",
    },
    
    createNew = {
      type = "execute",
      name = "Create New Custom Cooldown",
      desc = "Create a new custom cooldown definition",
      order = 2,
      width = 1.5,
      func = function()
        ns.CustomOptions.ShowCooldownCreationDialog()
      end,
    },
    
    spacer1 = { type = "description", name = "\n", order = 3 },
    
    existingHeader = {
      type = "header",
      name = "Existing Custom Cooldowns",
      order = 10,
    },
  }
  
  -- Add dynamic cooldown list
  local cdArgs = ns.CustomOptions.BuildCooldownListArgs()
  local order = 11
  for key, arg in pairs(cdArgs) do
    arg.order = order + (arg.order or 0) / 100
    baseArgs[key] = arg
  end
  
  return baseArgs
end

function ns.CustomOptions.BuildCooldownListArgs()
  local args = {}
  local cooldowns = ns.CustomTracking and ns.CustomTracking.GetAllCooldowns() or {}
  
  local order = 1
  local hasCooldowns = false
  
  for cdID, def in pairs(cooldowns) do
    hasCooldowns = true
    local iconTexture = def.iconTextureID or 134400
    local name = def.name or "Unnamed"
    
    -- Icon and name display
    args["icon_" .. cdID] = {
      type = "description",
      name = string.format("|T%d:20:20:0:0|t |cffffd700%s|r", iconTexture, name),
      order = order,
      width = 1.2,
    }
    
    -- Duration and charges info
    local infoText = string.format("%ds", def.cooldown and def.cooldown.baseDuration or 0)
    if def.charges and def.charges.enabled then
      infoText = infoText .. string.format(" (%d charges)", def.charges.maxCharges or 1)
    end
    
    args["info_" .. cdID] = {
      type = "description",
      name = "|cff888888" .. infoText .. "|r",
      order = order + 0.1,
      width = 1.2,
    }
    
    -- Edit button
    args["edit_" .. cdID] = {
      type = "execute",
      name = "Edit",
      order = order + 0.2,
      width = 0.4,
      func = function()
        ns.CustomOptions.ShowCooldownEditDialog(cdID)
      end,
    }
    
    -- Delete button
    args["delete_" .. cdID] = {
      type = "execute",
      name = "Delete",
      order = order + 0.3,
      width = 0.4,
      func = function()
        StaticPopup_Show("ARCUI_DELETE_CUSTOM_COOLDOWN", name, nil, { cdID = cdID })
      end,
    }
    
    -- Spacer
    args["spacer_" .. cdID] = {
      type = "description",
      name = "",
      order = order + 0.9,
      width = "full",
    }
    
    order = order + 1
  end
  
  if not hasCooldowns then
    args.noCooldowns = {
      type = "description",
      name = "|cff666666No custom cooldowns defined yet. Click 'Create New Custom Cooldown' above.|r",
      order = 1,
    }
  end
  
  return args
end

-- ===================================================================
-- MAIN OPTIONS TABLE
-- ===================================================================
function ns.CustomOptions.GetOptionsTable()
  return {
    type = "group",
    name = "Custom",
    order = 5,
    childGroups = "tab",
    args = {
      auras = {
        type = "group",
        name = "Custom Auras",
        order = 1,
        args = ns.CustomOptions.GetAurasDynamicArgs(),
      },
      cooldowns = {
        type = "group",
        name = "Custom Cooldowns",
        order = 2,
        args = ns.CustomOptions.GetCooldownsDynamicArgs(),
      },
    }
  }
end

-- Force refresh when options are opened
function ns.CustomOptions.RefreshOptions()
  LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
end

-- ===================================================================
-- AURA CREATION/EDIT DIALOG
-- ===================================================================
local auraDialogFrame = nil
local auraDialogData = {}

function ns.CustomOptions.ShowAuraCreationDialog()
  -- Reset dialog data to defaults
  wipe(auraDialogData)
  auraDialogData.triggers = { [1] = { spellID = 0, stacksGranted = 1 } }
  auraDialogData.duration = { baseDuration = 10, refreshMode = "refresh" }
  auraDialogData.stacks = { enabled = true, maxStacks = 10, gainMode = "add" }
  auraDialogData.consumption = { enabled = false, consumers = {} }
  auraDialogData.cancellation = { cancelSpells = {}, cancelOnCombatEnd = false, cancelOnDeath = true }
  
  ns.CustomOptions.ShowAuraDialog(nil)
end

function ns.CustomOptions.ShowAuraEditDialog(auraID)
  local def = ns.CustomTracking and ns.CustomTracking.GetAuraDefinition(auraID)
  if not def then return end
  
  -- Copy definition to dialog data
  wipe(auraDialogData)
  for k, v in pairs(def) do
    if type(v) == "table" then
      auraDialogData[k] = CopyTable(v)
    else
      auraDialogData[k] = v
    end
  end
  
  ns.CustomOptions.ShowAuraDialog(auraID)
end

function ns.CustomOptions.ShowAuraDialog(editingAuraID)
  if auraDialogFrame then
    auraDialogFrame:Release()
  end
  
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(editingAuraID and "Edit Custom Aura" or "Create Custom Aura")
  frame:SetWidth(500)
  frame:SetHeight(600)
  frame:SetLayout("Flow")
  frame:SetCallback("OnClose", function(widget)
    AceGUI:Release(widget)
    auraDialogFrame = nil
  end)
  auraDialogFrame = frame
  
  local scrollContainer = AceGUI:Create("SimpleGroup")
  scrollContainer:SetFullWidth(true)
  scrollContainer:SetFullHeight(true)
  scrollContainer:SetLayout("Fill")
  frame:AddChild(scrollContainer)
  
  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("Flow")
  scrollContainer:AddChild(scroll)
  
  -- ═══════════════════════════════════════════════════════════════
  -- TRIGGER SPELL
  -- ═══════════════════════════════════════════════════════════════
  local triggerHeader = AceGUI:Create("Heading")
  triggerHeader:SetText("Trigger Spell")
  triggerHeader:SetFullWidth(true)
  scroll:AddChild(triggerHeader)
  
  local triggerDesc = AceGUI:Create("Label")
  triggerDesc:SetText("What spell grants this buff? Enter the Spell ID.")
  triggerDesc:SetFullWidth(true)
  scroll:AddChild(triggerDesc)
  
  local triggerSpellID = AceGUI:Create("EditBox")
  triggerSpellID:SetLabel("Spell ID")
  triggerSpellID:SetRelativeWidth(0.4)
  triggerSpellID:SetText(tostring(auraDialogData.triggers[1].spellID or 0))
  triggerSpellID:SetCallback("OnEnterPressed", function(widget, event, text)
    local id = tonumber(text) or 0
    auraDialogData.triggers[1].spellID = id
    -- Auto-fill name and icon
    if id > 0 then
      local name, icon = GetSpellInfo(id)
      if name then
        auraDialogData.name = name
        auraDialogData.iconTextureID = icon
      end
    end
    widget:ClearFocus()
  end)
  scroll:AddChild(triggerSpellID)
  
  local triggerStacks = AceGUI:Create("EditBox")
  triggerStacks:SetLabel("Stacks Per Cast")
  triggerStacks:SetRelativeWidth(0.3)
  triggerStacks:SetText(tostring(auraDialogData.triggers[1].stacksGranted or 1))
  triggerStacks:SetCallback("OnEnterPressed", function(widget, event, text)
    auraDialogData.triggers[1].stacksGranted = tonumber(text) or 1
    widget:ClearFocus()
  end)
  scroll:AddChild(triggerStacks)
  
  -- ═══════════════════════════════════════════════════════════════
  -- DURATION
  -- ═══════════════════════════════════════════════════════════════
  local durationHeader = AceGUI:Create("Heading")
  durationHeader:SetText("Duration")
  durationHeader:SetFullWidth(true)
  scroll:AddChild(durationHeader)
  
  local baseDuration = AceGUI:Create("EditBox")
  baseDuration:SetLabel("Duration (seconds)")
  baseDuration:SetRelativeWidth(0.4)
  baseDuration:SetText(tostring(auraDialogData.duration.baseDuration or 10))
  baseDuration:SetCallback("OnEnterPressed", function(widget, event, text)
    auraDialogData.duration.baseDuration = tonumber(text) or 10
    widget:ClearFocus()
  end)
  scroll:AddChild(baseDuration)
  
  local refreshMode = AceGUI:Create("Dropdown")
  refreshMode:SetLabel("On Recast")
  refreshMode:SetRelativeWidth(0.5)
  refreshMode:SetList({
    refresh = "Refresh to Full",
    extend = "Extend (Pandemic)",
    overlap = "Independent Timers",
    noRefresh = "No Refresh",
  })
  refreshMode:SetValue(auraDialogData.duration.refreshMode or "refresh")
  refreshMode:SetCallback("OnValueChanged", function(widget, event, value)
    auraDialogData.duration.refreshMode = value
  end)
  scroll:AddChild(refreshMode)
  
  -- ═══════════════════════════════════════════════════════════════
  -- STACKS
  -- ═══════════════════════════════════════════════════════════════
  local stacksHeader = AceGUI:Create("Heading")
  stacksHeader:SetText("Stacks")
  stacksHeader:SetFullWidth(true)
  scroll:AddChild(stacksHeader)
  
  local stacksEnabled = AceGUI:Create("CheckBox")
  stacksEnabled:SetLabel("Does this buff stack?")
  stacksEnabled:SetRelativeWidth(0.5)
  stacksEnabled:SetValue(auraDialogData.stacks.enabled ~= false)
  stacksEnabled:SetCallback("OnValueChanged", function(widget, event, value)
    auraDialogData.stacks.enabled = value
  end)
  scroll:AddChild(stacksEnabled)
  
  local maxStacks = AceGUI:Create("EditBox")
  maxStacks:SetLabel("Max Stacks")
  maxStacks:SetRelativeWidth(0.4)
  maxStacks:SetText(tostring(auraDialogData.stacks.maxStacks or 10))
  maxStacks:SetCallback("OnEnterPressed", function(widget, event, text)
    auraDialogData.stacks.maxStacks = tonumber(text) or 10
    widget:ClearFocus()
  end)
  scroll:AddChild(maxStacks)
  
  -- ═══════════════════════════════════════════════════════════════
  -- CONSUMPTION (Collapsible)
  -- ═══════════════════════════════════════════════════════════════
  local consumptionHeader = AceGUI:Create("Heading")
  consumptionHeader:SetText("Consumption (Optional)")
  consumptionHeader:SetFullWidth(true)
  scroll:AddChild(consumptionHeader)
  
  local consumptionEnabled = AceGUI:Create("CheckBox")
  consumptionEnabled:SetLabel("Can another spell consume these stacks?")
  consumptionEnabled:SetFullWidth(true)
  consumptionEnabled:SetValue(auraDialogData.consumption.enabled or false)
  consumptionEnabled:SetCallback("OnValueChanged", function(widget, event, value)
    auraDialogData.consumption.enabled = value
  end)
  scroll:AddChild(consumptionEnabled)
  
  local consumerSpellID = AceGUI:Create("EditBox")
  consumerSpellID:SetLabel("Consumer Spell ID")
  consumerSpellID:SetRelativeWidth(0.4)
  local firstConsumer = auraDialogData.consumption.consumers[1]
  consumerSpellID:SetText(firstConsumer and firstConsumer.spellIDs and firstConsumer.spellIDs[1] and tostring(firstConsumer.spellIDs[1]) or "0")
  consumerSpellID:SetCallback("OnEnterPressed", function(widget, event, text)
    local id = tonumber(text) or 0
    if not auraDialogData.consumption.consumers[1] then
      auraDialogData.consumption.consumers[1] = { spellIDs = {}, consumeAmount = 5, minimumRequired = 0, partialConsume = true }
    end
    auraDialogData.consumption.consumers[1].spellIDs = { id }
    widget:ClearFocus()
  end)
  scroll:AddChild(consumerSpellID)
  
  local consumeAmount = AceGUI:Create("EditBox")
  consumeAmount:SetLabel("Stacks Consumed")
  consumeAmount:SetRelativeWidth(0.3)
  consumeAmount:SetText(firstConsumer and tostring(firstConsumer.consumeAmount or 5) or "5")
  consumeAmount:SetCallback("OnEnterPressed", function(widget, event, text)
    if not auraDialogData.consumption.consumers[1] then
      auraDialogData.consumption.consumers[1] = { spellIDs = {}, consumeAmount = 5, minimumRequired = 0, partialConsume = true }
    end
    auraDialogData.consumption.consumers[1].consumeAmount = tonumber(text) or 5
    widget:ClearFocus()
  end)
  scroll:AddChild(consumeAmount)
  
  -- ═══════════════════════════════════════════════════════════════
  -- CANCELLATION (Collapsible)
  -- ═══════════════════════════════════════════════════════════════
  local cancelHeader = AceGUI:Create("Heading")
  cancelHeader:SetText("Cancellation (Optional)")
  cancelHeader:SetFullWidth(true)
  scroll:AddChild(cancelHeader)
  
  local cancelOnCombatEnd = AceGUI:Create("CheckBox")
  cancelOnCombatEnd:SetLabel("Cancel when leaving combat")
  cancelOnCombatEnd:SetRelativeWidth(0.5)
  cancelOnCombatEnd:SetValue(auraDialogData.cancellation.cancelOnCombatEnd or false)
  cancelOnCombatEnd:SetCallback("OnValueChanged", function(widget, event, value)
    auraDialogData.cancellation.cancelOnCombatEnd = value
  end)
  scroll:AddChild(cancelOnCombatEnd)
  
  local cancelOnDeath = AceGUI:Create("CheckBox")
  cancelOnDeath:SetLabel("Cancel on death")
  cancelOnDeath:SetRelativeWidth(0.5)
  cancelOnDeath:SetValue(auraDialogData.cancellation.cancelOnDeath ~= false)
  cancelOnDeath:SetCallback("OnValueChanged", function(widget, event, value)
    auraDialogData.cancellation.cancelOnDeath = value
  end)
  scroll:AddChild(cancelOnDeath)
  
  -- ═══════════════════════════════════════════════════════════════
  -- SAVE/CANCEL BUTTONS
  -- ═══════════════════════════════════════════════════════════════
  local buttonSpacer = AceGUI:Create("Label")
  buttonSpacer:SetText(" ")
  buttonSpacer:SetFullWidth(true)
  scroll:AddChild(buttonSpacer)
  
  local saveButton = AceGUI:Create("Button")
  saveButton:SetText(editingAuraID and "Save Changes" or "Create Aura")
  saveButton:SetRelativeWidth(0.45)
  saveButton:SetCallback("OnClick", function()
    -- Validate
    local triggerSpell = auraDialogData.triggers[1].spellID
    if not triggerSpell or triggerSpell == 0 then
      print("|cffff0000[Arc UI] Error:|r Trigger Spell ID is required")
      return
    end
    
    -- Auto-fill name if empty
    if not auraDialogData.name or auraDialogData.name == "" then
      local name, icon = GetSpellInfo(triggerSpell)
      auraDialogData.name = name or ("Custom Aura " .. triggerSpell)
      auraDialogData.iconTextureID = icon or 134400
    end
    
    -- Save
    if editingAuraID then
      ns.CustomTracking.UpdateAura(editingAuraID, auraDialogData)
      print("|cff00ccff[Arc UI]|r Custom aura updated: " .. auraDialogData.name)
    else
      local newID = ns.CustomTracking.CreateAura(auraDialogData)
      print("|cff00ccff[Arc UI]|r Custom aura created: " .. auraDialogData.name)
    end
    
    -- Refresh options and close
    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    frame:Release()
    auraDialogFrame = nil
  end)
  scroll:AddChild(saveButton)
  
  local cancelButton = AceGUI:Create("Button")
  cancelButton:SetText("Cancel")
  cancelButton:SetRelativeWidth(0.45)
  cancelButton:SetCallback("OnClick", function()
    frame:Release()
    auraDialogFrame = nil
  end)
  scroll:AddChild(cancelButton)
end

-- ===================================================================
-- COOLDOWN CREATION/EDIT DIALOG
-- ===================================================================
local cooldownDialogFrame = nil
local cooldownDialogData = {}

function ns.CustomOptions.ShowCooldownCreationDialog()
  wipe(cooldownDialogData)
  cooldownDialogData.trigger = { spellIDs = {}, triggerUnit = "player", startCondition = "onCast" }
  cooldownDialogData.cooldown = { baseDuration = 60, hasteAffected = false }
  cooldownDialogData.charges = { enabled = false, maxCharges = 1, rechargeDuration = 0, startAtMax = true }
  cooldownDialogData.reduction = { enabled = false, reducers = {} }
  cooldownDialogData.reset = { enabled = false, resetters = {} }
  
  ns.CustomOptions.ShowCooldownDialog(nil)
end

function ns.CustomOptions.ShowCooldownEditDialog(cdID)
  local def = ns.CustomTracking and ns.CustomTracking.GetCooldownDefinition(cdID)
  if not def then return end
  
  wipe(cooldownDialogData)
  for k, v in pairs(def) do
    if type(v) == "table" then
      cooldownDialogData[k] = CopyTable(v)
    else
      cooldownDialogData[k] = v
    end
  end
  
  ns.CustomOptions.ShowCooldownDialog(cdID)
end

function ns.CustomOptions.ShowCooldownDialog(editingCdID)
  if cooldownDialogFrame then
    cooldownDialogFrame:Release()
  end
  
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(editingCdID and "Edit Custom Cooldown" or "Create Custom Cooldown")
  frame:SetWidth(500)
  frame:SetHeight(600)
  frame:SetLayout("Flow")
  frame:SetCallback("OnClose", function(widget)
    AceGUI:Release(widget)
    cooldownDialogFrame = nil
  end)
  cooldownDialogFrame = frame
  
  local scrollContainer = AceGUI:Create("SimpleGroup")
  scrollContainer:SetFullWidth(true)
  scrollContainer:SetFullHeight(true)
  scrollContainer:SetLayout("Fill")
  frame:AddChild(scrollContainer)
  
  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("Flow")
  scrollContainer:AddChild(scroll)
  
  -- ═══════════════════════════════════════════════════════════════
  -- TRIGGER SPELL
  -- ═══════════════════════════════════════════════════════════════
  local triggerHeader = AceGUI:Create("Heading")
  triggerHeader:SetText("Trigger Spell")
  triggerHeader:SetFullWidth(true)
  scroll:AddChild(triggerHeader)
  
  local triggerDesc = AceGUI:Create("Label")
  triggerDesc:SetText("What spell starts this cooldown? Enter the Spell ID.")
  triggerDesc:SetFullWidth(true)
  scroll:AddChild(triggerDesc)
  
  local triggerSpellID = AceGUI:Create("EditBox")
  triggerSpellID:SetLabel("Spell ID")
  triggerSpellID:SetRelativeWidth(0.4)
  local firstTriggerSpell = cooldownDialogData.trigger.spellIDs[1] or 0
  triggerSpellID:SetText(tostring(firstTriggerSpell))
  triggerSpellID:SetCallback("OnEnterPressed", function(widget, event, text)
    local id = tonumber(text) or 0
    cooldownDialogData.trigger.spellIDs = { id }
    -- Auto-fill name and icon
    if id > 0 then
      local name, icon = GetSpellInfo(id)
      if name then
        cooldownDialogData.name = name
        cooldownDialogData.iconTextureID = icon
      end
      -- Try to auto-detect cooldown duration
      local cdInfo = C_Spell.GetSpellCooldown(id)
      if cdInfo and cdInfo.duration and cdInfo.duration > 0 then
        cooldownDialogData.cooldown.baseDuration = cdInfo.duration
      end
    end
    widget:ClearFocus()
  end)
  scroll:AddChild(triggerSpellID)
  
  -- ═══════════════════════════════════════════════════════════════
  -- COOLDOWN DURATION
  -- ═══════════════════════════════════════════════════════════════
  local durationHeader = AceGUI:Create("Heading")
  durationHeader:SetText("Cooldown Duration")
  durationHeader:SetFullWidth(true)
  scroll:AddChild(durationHeader)
  
  local baseDuration = AceGUI:Create("EditBox")
  baseDuration:SetLabel("Duration (seconds)")
  baseDuration:SetRelativeWidth(0.4)
  baseDuration:SetText(tostring(cooldownDialogData.cooldown.baseDuration or 60))
  baseDuration:SetCallback("OnEnterPressed", function(widget, event, text)
    cooldownDialogData.cooldown.baseDuration = tonumber(text) or 60
    widget:ClearFocus()
  end)
  scroll:AddChild(baseDuration)
  
  local hasteAffected = AceGUI:Create("CheckBox")
  hasteAffected:SetLabel("Affected by Haste")
  hasteAffected:SetRelativeWidth(0.5)
  hasteAffected:SetValue(cooldownDialogData.cooldown.hasteAffected or false)
  hasteAffected:SetCallback("OnValueChanged", function(widget, event, value)
    cooldownDialogData.cooldown.hasteAffected = value
  end)
  scroll:AddChild(hasteAffected)
  
  -- ═══════════════════════════════════════════════════════════════
  -- CHARGES
  -- ═══════════════════════════════════════════════════════════════
  local chargesHeader = AceGUI:Create("Heading")
  chargesHeader:SetText("Charges")
  chargesHeader:SetFullWidth(true)
  scroll:AddChild(chargesHeader)
  
  local chargesEnabled = AceGUI:Create("CheckBox")
  chargesEnabled:SetLabel("Does this ability have charges?")
  chargesEnabled:SetFullWidth(true)
  chargesEnabled:SetValue(cooldownDialogData.charges.enabled or false)
  chargesEnabled:SetCallback("OnValueChanged", function(widget, event, value)
    cooldownDialogData.charges.enabled = value
  end)
  scroll:AddChild(chargesEnabled)
  
  local maxCharges = AceGUI:Create("EditBox")
  maxCharges:SetLabel("Max Charges")
  maxCharges:SetRelativeWidth(0.4)
  maxCharges:SetText(tostring(cooldownDialogData.charges.maxCharges or 2))
  maxCharges:SetCallback("OnEnterPressed", function(widget, event, text)
    cooldownDialogData.charges.maxCharges = tonumber(text) or 2
    widget:ClearFocus()
  end)
  scroll:AddChild(maxCharges)
  
  local rechargeDuration = AceGUI:Create("EditBox")
  rechargeDuration:SetLabel("Recharge Time (0 = use base)")
  rechargeDuration:SetRelativeWidth(0.5)
  rechargeDuration:SetText(tostring(cooldownDialogData.charges.rechargeDuration or 0))
  rechargeDuration:SetCallback("OnEnterPressed", function(widget, event, text)
    cooldownDialogData.charges.rechargeDuration = tonumber(text) or 0
    widget:ClearFocus()
  end)
  scroll:AddChild(rechargeDuration)
  
  -- ═══════════════════════════════════════════════════════════════
  -- REDUCTION (Collapsible)
  -- ═══════════════════════════════════════════════════════════════
  local reductionHeader = AceGUI:Create("Heading")
  reductionHeader:SetText("Cooldown Reduction (Optional)")
  reductionHeader:SetFullWidth(true)
  scroll:AddChild(reductionHeader)
  
  local reductionEnabled = AceGUI:Create("CheckBox")
  reductionEnabled:SetLabel("Can other spells reduce this cooldown?")
  reductionEnabled:SetFullWidth(true)
  reductionEnabled:SetValue(cooldownDialogData.reduction.enabled or false)
  reductionEnabled:SetCallback("OnValueChanged", function(widget, event, value)
    cooldownDialogData.reduction.enabled = value
  end)
  scroll:AddChild(reductionEnabled)
  
  local reducerSpellID = AceGUI:Create("EditBox")
  reducerSpellID:SetLabel("Reducer Spell ID")
  reducerSpellID:SetRelativeWidth(0.4)
  local firstReducer = cooldownDialogData.reduction.reducers[1]
  reducerSpellID:SetText(firstReducer and firstReducer.spellIDs and firstReducer.spellIDs[1] and tostring(firstReducer.spellIDs[1]) or "0")
  reducerSpellID:SetCallback("OnEnterPressed", function(widget, event, text)
    local id = tonumber(text) or 0
    if not cooldownDialogData.reduction.reducers[1] then
      cooldownDialogData.reduction.reducers[1] = { spellIDs = {}, reductionType = "flat", amount = 2 }
    end
    cooldownDialogData.reduction.reducers[1].spellIDs = { id }
    widget:ClearFocus()
  end)
  scroll:AddChild(reducerSpellID)
  
  local reductionAmount = AceGUI:Create("EditBox")
  reductionAmount:SetLabel("Reduction (seconds)")
  reductionAmount:SetRelativeWidth(0.4)
  reductionAmount:SetText(firstReducer and tostring(firstReducer.amount or 2) or "2")
  reductionAmount:SetCallback("OnEnterPressed", function(widget, event, text)
    if not cooldownDialogData.reduction.reducers[1] then
      cooldownDialogData.reduction.reducers[1] = { spellIDs = {}, reductionType = "flat", amount = 2 }
    end
    cooldownDialogData.reduction.reducers[1].amount = tonumber(text) or 2
    widget:ClearFocus()
  end)
  scroll:AddChild(reductionAmount)
  
  -- ═══════════════════════════════════════════════════════════════
  -- RESET (Collapsible)
  -- ═══════════════════════════════════════════════════════════════
  local resetHeader = AceGUI:Create("Heading")
  resetHeader:SetText("Cooldown Reset (Optional)")
  resetHeader:SetFullWidth(true)
  scroll:AddChild(resetHeader)
  
  local resetEnabled = AceGUI:Create("CheckBox")
  resetEnabled:SetLabel("Can other spells reset this cooldown?")
  resetEnabled:SetFullWidth(true)
  resetEnabled:SetValue(cooldownDialogData.reset.enabled or false)
  resetEnabled:SetCallback("OnValueChanged", function(widget, event, value)
    cooldownDialogData.reset.enabled = value
  end)
  scroll:AddChild(resetEnabled)
  
  local resetterSpellID = AceGUI:Create("EditBox")
  resetterSpellID:SetLabel("Resetter Spell ID")
  resetterSpellID:SetRelativeWidth(0.4)
  local firstResetter = cooldownDialogData.reset.resetters[1]
  resetterSpellID:SetText(firstResetter and firstResetter.spellIDs and firstResetter.spellIDs[1] and tostring(firstResetter.spellIDs[1]) or "0")
  resetterSpellID:SetCallback("OnEnterPressed", function(widget, event, text)
    local id = tonumber(text) or 0
    if not cooldownDialogData.reset.resetters[1] then
      cooldownDialogData.reset.resetters[1] = { spellIDs = {}, resetCharges = true }
    end
    cooldownDialogData.reset.resetters[1].spellIDs = { id }
    widget:ClearFocus()
  end)
  scroll:AddChild(resetterSpellID)
  
  local resetCharges = AceGUI:Create("CheckBox")
  resetCharges:SetLabel("Also reset charges to max")
  resetCharges:SetRelativeWidth(0.5)
  resetCharges:SetValue(firstResetter and firstResetter.resetCharges ~= false or true)
  resetCharges:SetCallback("OnValueChanged", function(widget, event, value)
    if not cooldownDialogData.reset.resetters[1] then
      cooldownDialogData.reset.resetters[1] = { spellIDs = {}, resetCharges = true }
    end
    cooldownDialogData.reset.resetters[1].resetCharges = value
  end)
  scroll:AddChild(resetCharges)
  
  -- ═══════════════════════════════════════════════════════════════
  -- SAVE/CANCEL BUTTONS
  -- ═══════════════════════════════════════════════════════════════
  local buttonSpacer = AceGUI:Create("Label")
  buttonSpacer:SetText(" ")
  buttonSpacer:SetFullWidth(true)
  scroll:AddChild(buttonSpacer)
  
  local saveButton = AceGUI:Create("Button")
  saveButton:SetText(editingCdID and "Save Changes" or "Create Cooldown")
  saveButton:SetRelativeWidth(0.45)
  saveButton:SetCallback("OnClick", function()
    -- Validate
    local triggerSpell = cooldownDialogData.trigger.spellIDs[1]
    if not triggerSpell or triggerSpell == 0 then
      print("|cffff0000[Arc UI] Error:|r Trigger Spell ID is required")
      return
    end
    
    -- Auto-fill name if empty
    if not cooldownDialogData.name or cooldownDialogData.name == "" then
      local name, icon = GetSpellInfo(triggerSpell)
      cooldownDialogData.name = name or ("Custom CD " .. triggerSpell)
      cooldownDialogData.iconTextureID = icon or 134400
    end
    
    -- Save
    if editingCdID then
      ns.CustomTracking.UpdateCooldown(editingCdID, cooldownDialogData)
      print("|cff00ccff[Arc UI]|r Custom cooldown updated: " .. cooldownDialogData.name)
    else
      local newID = ns.CustomTracking.CreateCooldown(cooldownDialogData)
      print("|cff00ccff[Arc UI]|r Custom cooldown created: " .. cooldownDialogData.name)
    end
    
    -- Refresh options and close
    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    frame:Release()
    cooldownDialogFrame = nil
  end)
  scroll:AddChild(saveButton)
  
  local cancelButton = AceGUI:Create("Button")
  cancelButton:SetText("Cancel")
  cancelButton:SetRelativeWidth(0.45)
  cancelButton:SetCallback("OnClick", function()
    frame:Release()
    cooldownDialogFrame = nil
  end)
  scroll:AddChild(cancelButton)
end

-- ===================================================================
-- STATIC POPUPS FOR DELETE CONFIRMATION
-- ===================================================================
StaticPopupDialogs["ARCUI_DELETE_CUSTOM_AURA"] = {
  text = "Delete custom aura '%s'?\n\nThis cannot be undone.",
  button1 = "Delete",
  button2 = "Cancel",
  OnAccept = function(self, data)
    if data and data.auraID then
      ns.CustomTracking.DeleteAura(data.auraID)
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      print("|cff00ccff[Arc UI]|r Custom aura deleted")
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["ARCUI_DELETE_CUSTOM_COOLDOWN"] = {
  text = "Delete custom cooldown '%s'?\n\nThis cannot be undone.",
  button1 = "Delete",
  button2 = "Cancel",
  OnAccept = function(self, data)
    if data and data.cdID then
      ns.CustomTracking.DeleteCooldown(data.cdID)
      LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      print("|cff00ccff[Arc UI]|r Custom cooldown deleted")
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- ===================================================================
-- END OF ArcUI_CustomOptions.lua
-- ===================================================================
