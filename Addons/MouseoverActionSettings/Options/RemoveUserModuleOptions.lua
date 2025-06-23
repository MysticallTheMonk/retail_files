local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local selected_module = ""

local function getUserModules()
    local tbl = {}
    for k, v in pairs(addon.db.global.UserModules) do
        table.insert(tbl, v.name)
    end
    return tbl
end

local options = {
    name = "Remove Module",
    handler = addon,
    type = "group",
    args = {
        dropwdown = {
            order = 1,
            name = L["select"] .. ":",
            type = "select",
            values = function()
                return getUserModules()
            end,
            get = function()
                local userModules = getUserModules()
                for k,v in pairs(userModules) do
                    if v == selected_module then
                        return k
                    end
                end
            end,
            set = function(info, value)
                local userModules = getUserModules()
                selected_module = userModules[value]
            end,
        },    
        button = {
            order = 2,
            name = L["remove_module_name"],
            type = "execute",
            func = function()
                addon:RemoveUserModule(selected_module)
            end,
        },          
    },
}

function addon:GetRemoveModuleOptions()
    return options
end