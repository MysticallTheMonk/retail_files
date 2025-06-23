--[[Created by Slothpala]]--
local addonName, addonTable = ...
addonTable.addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceSerializer-3.0", "AceEvent-3.0")
local addon = addonTable.addon
addon:SetDefaultModuleState(false)
addon:SetDefaultModuleLibraries("AceEvent-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local AC = LibStub("AceConfig-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local CR = {}
local LDBI = LibStub("LibDBIcon-1.0")

function addon:OnInitialize()
    CR = addonTable.callbackRegistry
    self:LoadDataBase()    

    local action_bars_tab = self:GetActionBarTabSettings()
    local hud_tab = self:GetHUDTabOptions()
    local user_modules_tab = self:GetUserModuleTabOptions()
    local links_tab = self:GetLinksTabOptions()
    local config_tab = self:GetConfigOptions()
    local profile_options = self:GetProfileTabOptions()
    local trigger_options = self:GetTriggerOptionsTable()
    local event_delay_timer_options = self:GetEventDelayTimerOptions()
    local create_module_options = self:GetCreateModuleOptions()
    local remove_module_options = self:GetRemoveModuleOptions()

    AC:RegisterOptionsTable("MouseOverActionSettings_Options_Tab_1", action_bars_tab)
    AC:RegisterOptionsTable("MouseOverActionSettings_Options_Tab_2", hud_tab)
    AC:RegisterOptionsTable("MouseOverActionSettings_Options_Tab_3", user_modules_tab)
    AC:RegisterOptionsTable("MouseOverActionSettings_Options_Tab_4", links_tab)
    AC:RegisterOptionsTable("MouseOverActionSettings_Options_Tab_5", config_tab)
    AC:RegisterOptionsTable("MouseOverActionSettings_Options_Tab_6", profile_options)
    AC:RegisterOptionsTable("MouseOverActionSettings_Options_Trigger", trigger_options)
    AC:RegisterOptionsTable("MouseOverActionSettings_Options_EventTimer", event_delay_timer_options)
    AC:RegisterOptionsTable("MouseOverActionSettings_Options_CreateModule", create_module_options)
    AC:RegisterOptionsTable("MouseOverActionSettings_Options_RemoveModule", remove_module_options)
    --Slash command
    self:RegisterChatCommand(addonName, "SlashCommand")
    self:RegisterChatCommand("mbars", "SlashCommand") --keeping this for a while for users that previously used mouseover action abrs
    self:RegisterChatCommand("mas", "SlashCommand")
    
    if self.db.global.TinkerZone then
        C_Timer.After(3, function() --wait for other addons to load their stuff
            addon:LoadUserModules()
        end)
    end
end
  
function addon:OnEnable()
    for name, module in self:IterateModules() do
        if self.db.profile[name].enabled then
            module:Enable()
        end
    end
    local minimap_button = LDBI:GetMinimapButton(addonName)
    if not minimap_button then 
        return
    end
    minimap_button.icon:SetDesaturation(0)
end
  
function addon:OnDisable()
    for name, module in self:IterateModules() do
        module:Disable()
    end
    local minimap_button = LDBI:GetMinimapButton(addonName)
    if not minimap_button then 
        return
    end
    minimap_button.icon:SetDesaturation(1)
end

function addon:UpdateTrigger()
    --used to apply trigger settings immediately
    for event, status in pairs(addonTable.events) do
        CR:Fire(event, status)
    end
end

function addon:ReloadConfig()
    self:Disable()
    self:Enable()
    self:UpdateTrigger()
end

local moduleAssociations = {
    ["HotKeyFontSettings"] = "ActionBarConfig",
    ["CountFontSettings"] = "ActionBarConfig",
    ["NameFontSettings"] = "ActionBarConfig",
}

function addon:ReloadModule(name)
    local name = moduleAssociations[name] or name
    self:DisableModule(name)
    self:EnableModule(name)
    self:UpdateTrigger()
end

function addon:IsModuleEnabled(name)
    return self.db.profile[name].enabled
end

function addon:SlashCommand()
    if InCombatLockdown() then
        self:Print(L["combat_message"])
        return
    end
    local frame = addon:GetOptionsFrame()
    if not frame:IsShown() then
        frame:Show()
    else
        frame:Hide()
    end
end

function MouseoverActionSettings_OnAddonCompartmentClick()
    addon:SlashCommand()
end