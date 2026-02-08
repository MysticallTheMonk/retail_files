local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Media = LibStub("LibSharedMedia-3.0")

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
    name = "Action Bars",
    handler = addon,
    type = "group",
    inline = true,
    args = {
        modules = {
            order = 0,
            name = L["enabled_units"],
            type = "group",
            inline = true,
            args = {
                MainActionBar = {
                    order = 1,
                    name = L["MainActionBar"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                MultiBarBottomLeft = {
                    order = 2,
                    name = L["MultiBarBottomLeft"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                MultiBarBottomRight = {
                    order = 3,
                    name = L["MultiBarBottomRight"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                MultiBarRight = {
                    order = 4,
                    name = L["MultiBarRight"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                MultiBarLeft = {
                    order = 5,
                    name = L["MultiBarLeft"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                MultiBar5 = {
                    order = 6,
                    name = L["MultiBar5"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                MultiBar6 = {
                    order = 7,
                    name = L["MultiBar6"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                MultiBar7 = {
                    order = 8,
                    name = L["MultiBar7"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                StanceBar = {
                    order = 9,
                    name = L["StanceBar"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                PetActionBar = {
                    order = 10,
                    name = L["PetActionBar"],
                    desc = "",
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
            },
        },
        MainActionBar = {
            hidden = function()
                return not addon:IsModuleEnabled("MainActionBar") or unitExcludedBySearch(L["MainActionBar"])
            end,
            order = 1,
            name = L["MainActionBar"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        MultiBarBottomLeft = {
            hidden = function()
                return not addon:IsModuleEnabled("MultiBarBottomLeft") or unitExcludedBySearch(L["MultiBarBottomLeft"])
            end,
            order = 2,
            name = L["MultiBarBottomLeft"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        MultiBarBottomRight = {
            hidden = function()
                return not addon:IsModuleEnabled("MultiBarBottomRight") or unitExcludedBySearch(L["MultiBarBottomRight"])
            end,
            order = 3,
            name = L["MultiBarBottomRight"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        MultiBarRight = {
            hidden = function()
                return not addon:IsModuleEnabled("MultiBarRight") or unitExcludedBySearch(L["MultiBarRight"])
            end,
            order = 4,
            name = L["MultiBarRight"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        MultiBarLeft = {
            hidden = function()
                return not addon:IsModuleEnabled("MultiBarLeft") or unitExcludedBySearch(L["MultiBarLeft"])
            end,
            order = 5,
            name = L["MultiBarLeft"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        MultiBar5 = {
            hidden = function()
                return not addon:IsModuleEnabled("MultiBar5") or unitExcludedBySearch(L["MultiBar5"])
            end,
            order = 6,
            name = L["MultiBar5"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        MultiBar6 = {
            hidden = function()
                return not addon:IsModuleEnabled("MultiBar6") or unitExcludedBySearch(L["MultiBar6"])
            end,
            order = 7,
            name = L["MultiBar6"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        MultiBar7 = {
            hidden = function()
                return not addon:IsModuleEnabled("MultiBar7") or unitExcludedBySearch(L["MultiBar7"])
            end,
            order = 8,
            name = L["MultiBar7"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        StanceBar = {
            hidden = function()
                return not addon:IsModuleEnabled("StanceBar") or unitExcludedBySearch(L["StanceBar"])
            end,
            order = 9,
            name = L["StanceBar"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
        PetActionBar = {
            hidden = function()
                return not addon:IsModuleEnabled("PetActionBar") or unitExcludedBySearch(L["PetActionBar"])
            end,
            order = 10,
            name = L["PetActionBar"],
            type = "group",
            inline = true,
            args = mouseover_unit_options,
        },
    },
}

function addon:GetActionBarTabSettings()
    return options
end