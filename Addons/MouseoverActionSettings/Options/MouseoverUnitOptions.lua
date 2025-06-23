local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local options = {
    minAlpha = {
        order = 1,
        name = L["min_alpha_name"] ,
        desc = L["min_alpha_desc"],
        type = "range",
        get = "GetStatus",
        set = "SetStatus",
        min = 0,
        max = 1,   
        isPercent = true,
        step = 0.01, 
        width = 2.25,   
    },
    maxAlpha = {
        order = 2,
        name = L["max_alpha_name"],
        desc = L["max_alpha_desc"],
        type = "range",
        get = "GetStatus",
        set = "SetStatus",
        min = 0,
        max = 1,   
        isPercent = true,
        step = 0.01, 
        width = 2.25,   
    },
    config = {
        order = 3,
        name = L["mouse_over_unit_config_button_name"],
        type  = "execute",
        width = 0.55,
        func = function(info)
            addon:ShowTriggerFrame(info)
        end,
    }
}

function addon:GetMouseoverUnitOptions()
    return options
end