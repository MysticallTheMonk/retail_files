local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local LDS = LibStub("LibDualSpec-1.0")

local options = {
    name = L["Profiles"],
    handler = addon,
    type = "group",
    childGroups = "tab",
    args = {
        ImportExportPofile = {
            order = 2,
            name = L["share_profile_title"],
            type = "group",
            args = {
                Header = {
                    order = 1,
                    name = L["share_profile_header"],
                    type = "header",
                },
                Desc = {
                    order = 2,
                    name = L["share_profile_desc_row1"] .. "\n" .. L["share_profile_desc_row2"],
                    fontSize = "medium",
                    type = "description",
                },
                Textfield = {
                    order = 3,
                    name = L["share_profile_input_name"],
                    desc = L["share_profile_input_desc"],
                    type = "input",
                    multiline = 20,
                    width = "full",
                    confirm = function() 
                        return L["share_profile_input_desc"] 
                    end,
                    get = function() 
                        return addon:ShareProfile() 
                    end,
                    set = function(self, input) 
                        addon:ImportProfile(input)
                        ReloadUI() 
                    end, 
                },
            },
        },
    },
} 

function addon:GetProfileTabOptions()
    local profile_options = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) 
    --add dual specc support 
    LDS:EnhanceDatabase(self.db, addonName) 
    LDS:EnhanceOptions(profile_options, self.db)
    profile_options.order = 1
    options.args.profiles = profile_options
    return options
end