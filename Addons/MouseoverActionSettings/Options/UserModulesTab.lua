local addonName, addonTable = ...
local addon = addonTable.addon
local ACD = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local options = {
    name = "User Modules",
    handler = addon,
    type = "group",
    args = {
        user_module_creation = {
            order = 0,
            name = L["user_module_creation_name"],
            type = "group",
            inline = true,
            args = {
                create_module = {
                    order = 1,
                    name = L["create_module_name"],
                    desc = L["create_module_desc"],
                    type = "execute",
                    func = function(info)
                        local frame = addon:GetPopUpFrame()
                        frame:Show()
                        frame.title:SetText(L["create_module_name"])
                        ACD:Open("MouseOverActionSettings_Options_CreateModule", frame.container)
                    end,
                },
                import_module = {
                    hidden = true,
                    order = 2,
                    name = L["import_module_name"],
                    desc = L["import_module_desc"],
                    type = "execute",
                    func = function(info)

                    end,
                },
                remove_module = {
                    order = 3,
                    name = L["remove_module_name"],
                    desc = L["remove_module_desc"],
                    type = "execute",
                    func = function(info)
                        local frame = addon:GetPopUpFrame()
                        frame:Show()
                        frame.title:SetText(L["remove_module_name"])
                        ACD:Open("MouseOverActionSettings_Options_RemoveModule", frame.container)
                    end,
                },
            },
        },
        modules = {
            order = 0.1,
            name = L["enabled_units"] ,
            type = "group",
            inline = true,
            args = {},
        },
    },
}

function addon:CreateUserModuleEntry(moduleName)
    local mouseover_unit_options = self:GetMouseoverUnitOptions()
    local displayedName = string.gsub(moduleName, "UserModule_", "")
    local module_toggle = {
        name = displayedName,
        desc = "",
        type = "toggle",
        get = "GetModuleStatus",
        set = "SetModuleStatus",
    }
    local module_control = {
        hidden = function()
            return not addon:IsModuleEnabled(moduleName)
        end,
        name = displayedName,
        type = "group",
        inline = true,
        args = mouseover_unit_options,
    }
    options.args.modules.args[moduleName] = module_toggle
    options.args[moduleName] = module_control
end

function addon:RemoveUserModuleEntry(moduleName)
    options.args.modules.args[moduleName] = nil
    options.args[moduleName] = nil
end

function addon:GetUserModuleTabOptions()
    return options
end