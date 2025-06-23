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

local options = {
    name = "Links",
    handler = addon,
    type = "group",
    args = {

    },
}

function addon:GetLinksTabOptions()
    return options
end

local function getDisplayedModuleName(module_name)
    local displayedName 
    if string.match(module_name, "UserModule_") then
        displayedName = addonTable.colors.user_module_color:WrapTextInColorCode(string.gsub(module_name, "UserModule_", ""))
    else
        displayedName = L[module_name]
    end
    return displayedName
end

local function createLinkGroup(module_name, enabled_mouseover_modules)
    local linkGroup = {
        hidden = function()
            return unitExcludedBySearch(getDisplayedModuleName(module_name))
        end,
        name = L["Show"] .. " " .. getDisplayedModuleName(module_name) .. " " .. L["alongside"] .. "...",
        type = "group",
        inline = true,
        args = {},
    }
    for name, module in pairs(enabled_mouseover_modules) do
        if name ~= module_name then
            linkGroup.args[name] = {
                name = "..." .. getDisplayedModuleName(name), --locale
                type = "toggle",
                get = "GetLinkStatus",
                set = "SetLinkStatus",
            }
        end
    end
    return linkGroup
end

function addon:CreateLinkGroupEntrys()
    options.args = {} --this will hide since disabled modules
    local enabled_mouseover_modules = {}
    for name, module in self:IterateModules() do
        if module.GetMouseoverUnit and self:IsModuleEnabled(name) then
            enabled_mouseover_modules[name] = module
        end
    end
    for name, module in pairs(enabled_mouseover_modules) do
        local linkGroup = createLinkGroup(name, enabled_mouseover_modules)
        options.args[name] = linkGroup
    end
end

function addon:GetLinkStatus(info)
    local module_name = info[#info-1]
    local link = info[#info]
    return self.db.profile[module_name].links[link]
end

function addon:SetLinkStatus(info, value)
    local module_name = info[#info-1]
    local link = info[#info]
    self.db.profile[module_name].links[link] = value
    self:ReloadModule(module_name)
end