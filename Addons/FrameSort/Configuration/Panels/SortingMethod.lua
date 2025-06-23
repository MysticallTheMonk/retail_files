---@type string, Addon
local _, addon = ...
local fsConfig = addon.Configuration
local wow = addon.WoW.Api
local L = addon.Locale
local M = {}
fsConfig.Panels.SortingMethod = M

function M:Build(parent)
    local verticalSpacing = fsConfig.VerticalSpacing
    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Sorting Method"]
    panel.parent = parent.name

    local secure = wow.CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    -- not sure why, but checkbox left seems to be off by about 4 units by default
    secure:SetPoint("TOPLEFT", panel, verticalSpacing - 4, -verticalSpacing + 4)
    secure.Text:SetText(L["Secure"])
    secure.Text:SetFontObject("GameFontNormalLarge")
    secure:SetChecked(addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Secure)

    local secureDescription = L["SortingMethod_Secure_Description"]
    local anchor = fsConfig:MultilineTextBlock(secureDescription, panel, secure)

    local traditional = wow.CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    traditional:SetPoint("TOPLEFT", anchor, -4, -verticalSpacing * 2)
    traditional.Text:SetText(L["Traditional"])
    traditional.Text:SetFontObject("GameFontNormalLarge")
    traditional:SetChecked(addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Traditional)

    local traditionalDescription = L["SortingMethod_Traditional_Description"]
    anchor = fsConfig:MultilineTextBlock(traditionalDescription, panel, traditional)

    local reloadReminder = panel:CreateFontString(nil, "ARTWORK", "GameFontRed")
    reloadReminder:SetPoint("TOPLEFT", anchor, 0, -verticalSpacing * 2)
    reloadReminder:SetText(L["Please reload after changing these settings."])

    local reloadButton = wow.CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reloadButton:SetPoint("TOPLEFT", reloadReminder, 0, -verticalSpacing * 1.5)
    reloadButton:SetWidth(100)
    reloadButton:SetText(L["Reload"])
    reloadButton:HookScript("OnClick", function()
        wow.ReloadUI()
    end)
    reloadButton:SetShown(false)

    local function setSortingMethod(method)
        if method == fsConfig.SortingMethod.Secure then
            traditional:SetChecked(false)
        elseif method == fsConfig.SortingMethod.Traditional then
            secure:SetChecked(false)
        end

        addon.DB.Options.Sorting.Method = method
        reloadButton:SetShown(true)
    end

    secure:HookScript("OnClick", function()
        if not secure:GetChecked() then
            secure:SetChecked(true)
            return
        end

        setSortingMethod(fsConfig.SortingMethod.Secure)
    end)

    traditional:HookScript("OnClick", function()
        if not traditional:GetChecked() then
            traditional:SetChecked(true)
            return
        end

        setSortingMethod(fsConfig.SortingMethod.Traditional)
    end)

    return panel
end
