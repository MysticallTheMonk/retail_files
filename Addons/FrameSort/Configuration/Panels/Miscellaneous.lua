---@type string, Addon
local _, addon = ...
local fsConfig = addon.Configuration
local fsRun = addon.Modules
local wow = addon.WoW.Api
local L = addon.Locale.Current
local M = {}
fsConfig.Panels.Miscellaneous = M

local function CreateSettingCheckbox(panel, setting)
    local checkbox = wow.CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox.Text:SetText(" " .. setting.Name)
    checkbox.Text:SetFontObject("GameFontNormal")
    checkbox:SetChecked(setting.Enabled())
    checkbox:HookScript("OnClick", function()
        setting.OnChanged(checkbox:GetChecked())
    end)

    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(setting.Name, 1, 0.82, 0)
        GameTooltip:AddLine(setting.Tooltip, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    checkbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return checkbox
end

function M:Build(parent)
    local verticalSpacing = fsConfig.VerticalSpacing
    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Miscellaneous"]
    panel.parent = parent.name

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Miscellaneous"])

    local intro = L["Various tweaks you can apply."]
    fsConfig:TextLine(intro, panel, title, nil, -verticalSpacing)

    local settings = {
        {
            Name = L["Player top of role"],
            Tooltip = L["Places you at the top of your corresponding role (healer/tank/dps)."],
            Enabled = function()
                return addon.DB.Options.Sorting.Miscellaneous.PlayerRoleSort == fsConfig.PlayerSortMode.Top
            end,
            OnChanged = function(enabled)
                addon.DB.Options.Sorting.Miscellaneous.PlayerRoleSort = enabled and fsConfig.PlayerSortMode.Top or fsConfig.PlayerSortMode.None
                fsConfig:NotifyChanged()
                fsRun:Run()
            end,
        },
    }

    local checkboxesPerLine = 4
    local checkboxWidth = 150
    local start = verticalSpacing
    local yOffset = verticalSpacing * 5
    local xOffset = start

    for i, setting in ipairs(settings) do
        local checkbox = CreateSettingCheckbox(panel, setting)
        checkbox:SetPoint("TOPLEFT", panel, "TOPLEFT", xOffset, -yOffset)

        if i % checkboxesPerLine == 0 then
            yOffset = yOffset + (verticalSpacing * 3)
            xOffset = start
        else
            xOffset = xOffset + checkboxWidth
        end
    end

    return panel
end
