---@type string, Addon
local _, addon = ...
local fsConfig = addon.Configuration
local wow = addon.WoW.Api
local L = addon.Locale.Current
local M = {}
fsConfig.Panels.AutoLeader = M

function M:Build(parent)
    local verticalSpacing = fsConfig.VerticalSpacing
    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Auto Leader"]
    panel.parent = parent.name

    local enabled = wow.CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enabled:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    enabled.Text:SetText(L["Auto Leader"])
    enabled.Text:SetFontObject("GameFontNormalLarge")
    enabled:SetChecked(addon.DB.Options.AutoLeader.Enabled or false)

    local lines = {
        L["Auto promote healers to leader in solo shuffle."],
        L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."],
    }

    fsConfig:TextBlock(lines, panel, enabled)

    local function OnClick(box)
        addon.DB.Options.AutoLeader.Enabled = box:GetChecked()
    end

    enabled:SetScript("OnClick", OnClick)

    return panel
end
