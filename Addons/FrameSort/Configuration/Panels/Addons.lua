---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsConfig = addon.Configuration
local fsLog = addon.Logging.Log
local L = addon.Locale
local M = {}
fsConfig.Panels.Addons = M

function M:Build(parent)
    local scroller = wow.CreateFrame("ScrollFrame", nil, nil, "UIPanelScrollFrameTemplate")
    scroller.name = L["Addons"]
    scroller.parent = parent.name

    local panel = wow.CreateFrame("Frame")

    if wow.SettingsPanel then
        panel:SetWidth(wow.SettingsPanel.Container:GetWidth())
        panel:SetHeight(wow.SettingsPanel.Container:GetHeight())
    elseif wow.InterfaceOptionsFramePanelContainer then
        panel:SetWidth(wow.InterfaceOptionsFramePanelContainer:GetWidth())
        panel:SetHeight(wow.InterfaceOptionsFramePanelContainer:GetHeight())
    else
        fsLog:Error("Unable to set configuration panel width.")
    end

    scroller:SetScrollChild(panel)

    local verticalSpacing = fsConfig.VerticalSpacing
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Addons"])

    local text = L["Addons_Supported_Description"]
    fsConfig:MultilineTextBlock(text, panel, title)

    return scroller
end
