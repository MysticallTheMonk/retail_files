local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local options = {} --to access options from "in itself"
options = { 
    name = "Trigger",
    handler = addon,
    type = "group",
    args = {
        module = {
            --name will be replaced with the module name by
            --the function ShowTriggerFrame() in file TriggerFrame.lua
            --to carry the module name information for saving to the db
            order = 0,
            type = "description",
            name = "",
            guiHidden = true,
        },
        trigger_desc = {
            order = 0.1,
            type = "description",
            fontSize = "medium",
            name = " " .. L["trigger_desc_name"],
        },
        --[[Status]]--
        status_header = {
            order = 1,
            type = "header",
            name = L["status_header_name"],
        },
        COMBAT_UPDATE = {
            order = 1.1,
            name = L["combat_update_name"],
            desc = L["combat_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        MOUNT_UPDATE = {
            order = 1.2,
            name = L["mount_update_name"],
            desc = L["mount_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        DRAGONRIDING_UPDATE = {
            order = 1.3,
            name = L["dragonriding_update_name"],
            desc = L["dragonriding_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        NPC_UPDATE = {
            order = 1.4,
            name = L["npc_update_name"],
            desc = L["npc_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        PARTY_GROUP_UPDATE = {
            order = 1.5,
            name = L["party_group_update_name"],
            desc = L["party_group_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        RAID_GROUP_UPDATE = {
            order = 1.6,
            name = L["raid_group_update_name"],
            desc = L["raid_group_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        TARGET_UPDATE = {
            order = 1.7,
            name = L["target_update_name"],
            desc = L["target_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        TARGET_ATTACKABLE_UPDATE = {
            order = 1.71,
            name = L["target_attackable_update_name"],
            desc = L["target_attackable_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        PLAYER_MOVING_UPDATE = {
            order = 1.8,
            name = L["player_moving_update_name"],
            desc = L["player_moving_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        PLAYER_HEALTH_UPDATE = {
            order = 1.9,
            name = L["player_health_update_name"],
            desc = L["player_health_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        --[[Zone]]--
        zone_header = {
            order = 2,
            type = "header",
            name = L["zone_header_name"],
        },
        RAID_UPDATE = {
            order = 2.1,
            name = L["raid_update_name"],
            desc = L["raid_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        DUNGEON_UPDATE = {
            order = 2.2,
            name = L["dungeon_update_name"],
            desc = L["dungeon_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        BATTLEGROUND_UPDATE = {
            order = 2.3,
            name = L["battleground_update_name"],
            desc = L["battleground_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        ARENA_UPDATE = {
            order = 2.4,
            name = L["arena_update_name"],
            desc = L["arena_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        SCENARIO_UPDATE = {
            order = 2.5,
            name = L["scenario_update_name"],
            desc = L["scenario_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        OPEN_WORLD_UPDATE = {
            order = 2.6,
            name = L["open_world_update_name"],
            desc = L["open_world_update_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        --[[config]]
        config_header = {
            order = 10,
            type = "header",
            name = L["config_header_name"],
        },
        useCustomAnimationSpeed = {
            order = 10.1,
            name = L["custom_animation_toggle_name"],
            desc = L["custom_animation_toggle_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        animationSpeed_In = {
            disabled = function()
                return not addon.db.profile[options.args.module.name].useCustomAnimationSpeed
            end,
            order = 10.1,
            name = L["animation_speed_in_name"] ,
            desc = L["animation_speed_in_desc"],
            type = "range",
            get = "GetTrigger",
            set = "SetTrigger",
            min = 0,
            max = 10,   
            step = 0.01, 
            width = 1.4,   
        },
        animationSpeed_Out = {
            disabled = function()
                return not addon.db.profile[options.args.module.name].useCustomAnimationSpeed
            end,
            order = 10.2,
            name = L["animation_speed_out_name"] ,
            desc = L["animation_speed_out_desc"],
            type = "range",
            get = "GetTrigger",
            set = "SetTrigger",
            min = 0,
            max = 10,   
            step = 0.01, 
            width = 1.4,   
        },
        newline = {
            order = 11,
            type = "description",
            name = "",
        },
        useCustomDelay = {
            order = 11.1,
            name = L["custom_delay_toggle_name"],
            desc = L["custom_delay_toggle_desc"],
            type = "toggle",
            get = "GetTrigger",
            set = "SetTrigger",
        },
        delay = {
            disabled = function()
                return not addon.db.profile[options.args.module.name].useCustomDelay
            end,
            order = 11.2,
            name = L["delay_name"],
            desc = L["delay_desc"],
            type = "range",
            get = "GetTrigger",
            set = "SetTrigger",
            min = 0,
            softMax = 10,   
            step = 1,   
            width = 1.4,                    
        },
    },
}

function addon:GetTriggerOptionsTable()
    return options
end

function addon:SetTrigger(info, value)
    local module_name = options.args.module.name
    local event = info[#info]
    self.db.profile[module_name][event] = value
    self:ReloadModule(module_name)
end

function addon:GetTrigger(info)
    local module_name = options.args.module.name
    local event = info[#info]
    return self.db.profile[module_name][event]
end