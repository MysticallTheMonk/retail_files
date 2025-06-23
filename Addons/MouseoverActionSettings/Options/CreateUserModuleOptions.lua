local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local tmp = {
    name_input_txt = "",
    parent_input_txt = "",
    scriptRegions_input_txt = "",
}

local function stringToTable(string)
    local table = {}
    for word in string.gmatch(string, "([^;,%s]+)") do
        table[#table + 1] = word
    end
    return table
end

local create_module_options = {
    name = "Create Module",
    handler = addon,
    type = "group",
    args = {
        name_input = {
            order = 1,
            --inline = true,
            width = "full",
            name = L["name_input_name"],
            type = "input",
            set = function(self, input)
                tmp.name_input_txt = input
            end,
            get = function() 
                return tmp.name_input_txt
            end,
        },
        parent_input = {
            order = 2,
            disabled = function()
                return string.len(tmp.name_input_txt) < 1
            end,
            width = "full",
            name = L["parent_input_name"],
            type = "input",
            set = function(self, input)
                tmp.parent_input_txt = input
            end,
            get = function() 
                return tmp.parent_input_txt
            end,
        },
        scriptRegions_input = {
            order = 3,
            disabled = function()
                return string.len(tmp.parent_input_txt) < 1
            end,
            width = "full",
            name = L["scriptRegions_input_name"],
            type = "input",
            multiline = 5,
            set = function(self, input)
                tmp.scriptRegions_input_txt = input
            end,
            get = function() 
                return tmp.scriptRegions_input_txt
            end,
        },
        button = {
            order = 4,
            disabled = function()
                return string.len(tmp.name_input_txt) < 1 or string.len(tmp.parent_input_txt) < 1
            end,
            name = L["create_module_button_txt"],
            type = "execute",
            width = 1,
            func = function(info)
                addon.db.global.UserModules[tmp.name_input_txt] = {}
                addon.db.global.UserModules[tmp.name_input_txt].name = tmp.name_input_txt
                addon.db.global.UserModules[tmp.name_input_txt].parentNames = stringToTable(tmp.parent_input_txt)
                addon.db.global.UserModules[tmp.name_input_txt].scriptRegionNames = stringToTable(tmp.scriptRegions_input_txt)
                addon:CreateUserModule(tmp.name_input_txt)
                tmp.name_input_txt = ""
                tmp.parent_input_txt = ""
                tmp.scriptRegions_input_txt = ""
                local popUpFrame = addon:GetPopUpFrame()
                popUpFrame:Hide()
            end,
            confirm = function()
                local confirm_msg = L["create_module_confirm_msg"] .. "\n" .. L["name_input_name"] .. " " .. tmp.name_input_txt .. "\n" .. L["parent_input_name"] .. " " .. tmp.parent_input_txt .. "\n" .. L["scriptRegions_input_name"] .. " " .. tmp.scriptRegions_input_txt
                return confirm_msg
            end,
        },
        fstack_button = {
            order = 4.1,
            name = "/fstack",
            desc = L["framestack_desc"],
            type = "execute",
            width = 0.7,
            func = function()
                SlashCmdList["FRAMESTACK"]()
            end,
        },
        newline1 = {
            order = 5,
            name = "",
            type = "description",
        },
        newline2 = {
            order = 6,
            name = "",
            type = "description",
        },
        info_field = {
            order = 8,
            fontSize = "large",
            name = L["create_module_info_field"],
            type = "description",
        },
    },
}

function addon:GetCreateModuleOptions()
    return create_module_options
end
--[[]]