---@type string, Addon
local _, addon = ...
local fsConfig = addon.Configuration
local capabilities = addon.WoW.Capabilities
local wow = addon.WoW.Api
local fsRun = addon.Modules
local L = addon.Locale.Current
local M = {}
fsConfig.Panels.Nameplates = M

local insetPadding = 10

local function ConfigureEditBox(box)
    box:SetSize(400, 40)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontWhite")
    box:SetCursorPosition(0)
    box:SetTextInsets(insetPadding, insetPadding, insetPadding, insetPadding)
    box:SetScript("OnEscapePressed", function()
        box:ClearFocus()
    end)

    local bg = wow.CreateFrame("Frame", nil, box, "BackdropTemplate")
    bg:SetBackdrop({
        edgeFile = "Interface\\Glues\\Common\\TextPanel-Border",
        edgeSize = 16,
    })
    bg:SetAllPoints(box)
end

function M:Build(parent)
    local verticalSpacing = fsConfig.VerticalSpacing
    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Nameplates"]
    panel.parent = parent.name

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Nameplates"])

    local blurb = L["NameplatesBlurb"]
    local blurbControl = fsConfig:MultilineTextBlock(blurb, panel, title)

    local function Update()
        fsConfig:NotifyChanged()
        fsRun:Run()
    end

    local friendlyEnabled = wow.CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    friendlyEnabled:SetPoint("TOPLEFT", blurbControl, "BOTTOMLEFT", 0, -verticalSpacing)
    friendlyEnabled.Text:SetText(L["Friendly Nameplates"])
    friendlyEnabled.Text:SetFontObject("GameFontNormal")
    friendlyEnabled:SetChecked(addon.DB.Options.Nameplates.FriendlyEnabled or false)

    local function OnFriendlyClick(box)
        addon.DB.Options.Nameplates.FriendlyEnabled = box:GetChecked()
        Update()
    end

    friendlyEnabled:SetScript("OnClick", OnFriendlyClick)

    local friendlyFormat = wow.CreateFrame("EditBox", nil, panel)
    friendlyFormat:SetPoint("TOPLEFT", friendlyEnabled, "BOTTOMLEFT", 0, -verticalSpacing)
    friendlyFormat:SetText(addon.DB.Options.Nameplates.FriendlyFormat)
    friendlyFormat:SetScript("OnEditFocusLost", function()
        addon.DB.Options.Nameplates.FriendlyFormat = friendlyFormat:GetText()
        Update()
    end)

    ConfigureEditBox(friendlyFormat)

    if capabilities:CanGetArenaNameplates() then
        local enemyEnabled = wow.CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        enemyEnabled:SetPoint("TOPLEFT", friendlyFormat, "BOTTOMLEFT", 0, -verticalSpacing)
        enemyEnabled.Text:SetText(L["Enemy Nameplates"])
        enemyEnabled.Text:SetFontObject("GameFontNormal")
        enemyEnabled:SetChecked(addon.DB.Options.Nameplates.EnemyEnabled or false)

        local function OnEnemyClick(box)
            addon.DB.Options.Nameplates.EnemyEnabled = box:GetChecked()
            Update()
        end

        enemyEnabled:SetScript("OnClick", OnEnemyClick)

        local enemyFormat = wow.CreateFrame("EditBox", nil, panel)
        enemyFormat:SetPoint("TOPLEFT", enemyEnabled, "BOTTOMLEFT", 0, -verticalSpacing)
        enemyFormat:SetText(addon.DB.Options.Nameplates.EnemyFormat)
        enemyFormat:SetScript("OnEditFocusLost", function()
            addon.DB.Options.Nameplates.EnemyFormat = enemyFormat:GetText()
            Update()
        end)

        ConfigureEditBox(enemyFormat)
    end

    return panel
end
