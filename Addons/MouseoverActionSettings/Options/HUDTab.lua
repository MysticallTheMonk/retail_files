local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local function unitExcludedBySearch(name)
    if string.len(addonTable.searchText) < 1 then
        return false
    end
    local text1, text2 = string.lower(name), string.lower(addonTable.searchText)
    if not text1:match(text2) then
        return true
    end
    return false
end

local mouseover_unit_options = addon:GetMouseoverUnitOptions()
local options = {
    name = "HUD",
    handler = addon,
    type = "group",
    args = {
        modules = {
            order = 0,
            name = L["enabled_units"] ,
            type = "group",
            inline = true,
            args = {
                BagsBar = {
                    order = 1,
                    name = L["BagsBar"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                MicroMenu = {
                    order = 2,
                    name = L["MicroMenu"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                PlayerFrame = {
                    order = 3,
                    name = L["PlayerFrame"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                TargetFrame = {
                    order = 3.1,
                    name = L["TargetFrame"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                FocusFrame = {
                    order = 3.2,
                    name = L["FocusFrame"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                PetFrame = {
                    order = 3.3,
                    name = L["PetFrame"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                PartyFrame = {
                    order = 3.4,
                    name = L["PartyFrame"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                Minimap = {
                    order = 4,
                    name = L["Minimap"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                ObjectiveTracker = {
                    order = 5,
                    name = L["ObjectiveTracker"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                BuffFrame = {
                    order = 6,
                    name = L["BuffFrame"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                DebuffFrame = {
                    order = 7,
                    name = L["DebuffFrame"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                TrackingBarContainer = {
                    order = 8,
                    name = L["TrackingBarContainer"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                ChatFrame = {
                    order = 9,
                    name = L["ChatFrame"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
            },
        },
        BagsBar = {
            hidden = function()
                return not addon:IsModuleEnabled("BagsBar") or unitExcludedBySearch(L["BagsBar"])
            end,
            order = 1,
            name = L["BagsBar"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        MicroMenu = {
            hidden = function()
                return not addon:IsModuleEnabled("MicroMenu") or unitExcludedBySearch(L["MicroMenu"])
            end,
            order = 2,
            name = L["MicroMenu"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        PlayerFrame = {
            hidden = function()
                return not addon:IsModuleEnabled("PlayerFrame") or unitExcludedBySearch(L["PlayerFrame"])
            end,
            order = 3,
            name = L["PlayerFrame"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        TargetFrame = {
            hidden = function()
                return not addon:IsModuleEnabled("TargetFrame") or unitExcludedBySearch(L["TargetFrame"])
            end,
            order = 3.1,
            name = L["TargetFrame"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        FocusFrame = {
            hidden = function()
                return not addon:IsModuleEnabled("FocusFrame") or unitExcludedBySearch(L["FocusFrame"])
            end,
            order = 3.2,
            name = L["FocusFrame"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        PetFrame = {
            hidden = function()
                return not addon:IsModuleEnabled("PetFrame") or unitExcludedBySearch(L["PetFrame"])
            end,
            order = 3.3,
            name = L["PetFrame"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
		PartyFrame = {
            hidden = function()
                return not addon:IsModuleEnabled("PartyFrame") or unitExcludedBySearch(L["PartyFrame"])
            end,
            order = 3.4,
            name = L["PartyFrame"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        Minimap = {
            hidden = function()
                return not addon:IsModuleEnabled("Minimap") or unitExcludedBySearch(L["Minimap"])
            end,
            order = 4,
            name = L["Minimap"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        ObjectiveTracker = {
            hidden = function()
                return not addon:IsModuleEnabled("ObjectiveTracker") or unitExcludedBySearch(L["ObjectiveTracker"])
            end,
            order = 5,
            name = L["ObjectiveTracker"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        BuffFrame = {
            hidden = function()
                return not addon:IsModuleEnabled("BuffFrame") or unitExcludedBySearch(L["BuffFrame"])
            end,
            order = 6,
            name = L["BuffFrame"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        DebuffFrame = {
            hidden = function()
                return not addon:IsModuleEnabled("DebuffFrame") or unitExcludedBySearch(L["DebuffFrame"])
            end,
            order = 7,
            name = L["DebuffFrame"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        TrackingBarContainer = {
            hidden = function()
                return not addon:IsModuleEnabled("TrackingBarContainer") or unitExcludedBySearch(L["TrackingBarContainer"])
            end,
            order = 8,
            name = L["TrackingBarContainer"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        ChatFrame = {
            hidden = function()
                return not addon:IsModuleEnabled("ChatFrame") or unitExcludedBySearch(L["ChatFrame"])
            end,
            order = 9,
            name = L["ChatFrame"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
    },
}

function addon:GetHUDTabOptions()
    return options
end