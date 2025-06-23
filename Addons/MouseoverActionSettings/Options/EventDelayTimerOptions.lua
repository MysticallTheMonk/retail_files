local addonName, addonTable = ...
local addon = addonTable.addon
local CR = addonTable.callbackRegistry
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local sliderWidth = 2.58

local options = {
    name = "",
    handler = addon,
    type = "group",
    args = {
        event_delay_timer_header = {
            order = 0,
            type = "header",
            --fontSize = "medium",
            name = L["event_delay_timer_header_name"],
        },
        MOUNT_UPDATE = {
            order = 1,
            name = L["mount_update_delay_timer_name"],
            desc = L["event_delay_timer_desc"],
            type = "range",
            get = "GetEventDelayTimerStaus",
            set = "SetEventDelayTimerStaus",
            min = 0,
            softMax = 10,   
            step = 1,   
            width = sliderWidth,                    
        },
        COMBAT_UPDATE = {
            order = 2,
            name = L["combat_update_delay_timer_name"],
            desc = L["event_delay_timer_desc"],
            type = "range",
            get = "GetEventDelayTimerStaus",
            set = "SetEventDelayTimerStaus",
            min = 0,
            softMax = 10,   
            step = 1,   
            width = sliderWidth,                    
        },
        DRAGONRIDING_UPDATE = {
            order = 3,
            name = L["dragonriding_update_delay_timer_name"],
            desc = L["event_delay_timer_desc"],
            type = "range",
            get = "GetEventDelayTimerStaus",
            set = "SetEventDelayTimerStaus",
            min = 0,
            softMax = 10,   
            step = 1,   
            width = sliderWidth,                    
        },
        NPC_UPDATE = {
            order = 4,
            name = L["npc_update_delay_timer_name"],
            desc = L["event_delay_timer_desc"],
            type = "range",
            get = "GetEventDelayTimerStaus",
            set = "SetEventDelayTimerStaus",
            min = 0,
            softMax = 10,   
            step = 1,   
            width = sliderWidth,                    
        },
        PLAYER_MOVING_UPDATE = {
            order = 5,
            name = L["player_moving_update_delay_timer_name"],
            desc = L["event_delay_timer_desc"],
            type = "range",
            get = "GetEventDelayTimerStaus",
            set = "SetEventDelayTimerStaus",
            min = 0,
            softMax = 10,   
            step = 1,   
            width = sliderWidth,                    
        },
        PLAYER_HEALTH_UPDATE = {
            order = 6,
            name = L["player_health_update_delay_timer_name"],
            desc = L["event_delay_timer_desc"],
            type = "range",
            get = "GetEventDelayTimerStaus",
            set = "SetEventDelayTimerStaus",
            min = 0,
            softMax = 10,   
            step = 1,   
            width = sliderWidth,                    
        },
    },
}

function addon:GetEventDelayTimerOptions()
    return options
end

function addon:GetEventDelayTimerStaus(info)
    return self.db.profile.EventDelayTimers[info[#info]]
end

function addon:SetEventDelayTimerStaus(info, value)
    local event = info[#info]
    self.db.profile.EventDelayTimers[event] = value
    CR:RestartStatus(event)
end