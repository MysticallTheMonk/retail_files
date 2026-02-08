---@type string, Addon
local _, addon = ...
local fsConfig = addon.Configuration
local wow = addon.WoW.Api
local fsEnumerable = addon.Collections.Enumerable
local L = addon.Locale.Current
local items = {
    { Locale = "enUS", Name = "English" },
    { Locale = "deDE", Name = "Deutsch" },
    { Locale = "esES", Name = "Español" },
    { Locale = "esMX", Name = "Español (México)" },
    { Locale = "frFR", Name = "Français" },
    { Locale = "koKR", Name = "한국어" },
    { Locale = "ruRU", Name = "Русский" },
    { Locale = "zhCN", Name = "简体中文" },
    { Locale = "zhTW", Name = "繁體中文" },
}
local M = {}
fsConfig.Panels.Locale = M

function M:Build(parent)
    local verticalSpacing = fsConfig.VerticalSpacing

    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Language"]
    panel.parent = parent.name

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Language"])

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -verticalSpacing)
    description:SetText(L["Specify the language we use."])

    local dd = fsConfig:Dropdown(panel, items, function()
        return fsEnumerable:From(items):First(function(item)
            return item.Locale == (addon.DB.Options.Locale or "enUS")
        end)
    end, function(item)
        addon.DB.Options.Locale = item.Locale
    end, function(item)
        return item.Name
    end)

    dd:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -verticalSpacing)
    dd:SetWidth(200)

    local reloadButton = wow.CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reloadButton:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -verticalSpacing)
    reloadButton:SetWidth(100)
    reloadButton:SetText(L["Reload"])
    reloadButton:SetScript("OnClick", function()
        wow.ReloadUI()
    end)

    return panel
end
