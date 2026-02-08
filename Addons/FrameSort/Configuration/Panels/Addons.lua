---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsConfig = addon.Configuration
local L = addon.Locale.Current
local M = {}
fsConfig.Panels.Addons = M

function M:Build(parent)
    local scroller = wow.CreateFrame("ScrollFrame", nil, nil, "UIPanelScrollFrameTemplate")
    scroller.name = L["Addons"]
    scroller.parent = parent.name

    local panel = wow.CreateFrame("Frame")
    local width, height = fsConfig:SettingsSize()

    panel:SetWidth(width)
    panel:SetHeight(height)

    scroller:SetScrollChild(panel)

    local verticalSpacing = fsConfig.VerticalSpacing
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Addons"])

    local text = L["Addons_Supported_Description"]
    fsConfig:MultilineTextBlock(text, panel, title)

    return scroller
end
