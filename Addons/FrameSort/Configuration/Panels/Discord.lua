---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsConfig = addon.Configuration
local L = addon.Locale.Current
local M = {}
fsConfig.Panels.Discord = M

function M:Build(parent)
    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Discord"]
    panel.parent = parent.name

    local verticalSpacing = fsConfig.VerticalSpacing
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Discord"])

    local intro = {
        L["Need help with something?"],
        L["Talk directly with the developer on Discord."],
    }

    local anchor = fsConfig:TextBlock(intro, panel, title)
    local padding = 10
    local box = wow.CreateFrame("EditBox", nil, panel)

    box:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing)
    box:SetSize(500, 1)
    box:SetFontObject("GameFontWhite")
    box:SetAutoFocus(false)
    box:SetMultiLine(true)
    box:SetText(fsConfig.DiscordUrl)
    box:SetCursorPosition(0)

    -- undo any user changes
    box:SetScript("OnTextChanged", function(_, userInput)
        if not userInput then
            return
        end

        box:SetText(fsConfig.DiscordUrl)
    end)

    box:SetScript("OnEscapePressed", function()
        box:ClearFocus()
    end)
    box:SetTextInsets(padding, padding, padding, padding)

    local bg = wow.CreateFrame("Frame", nil, panel, "BackdropTemplate")
    bg:SetBackdrop({
        edgeFile = "Interface\\Glues\\Common\\TextPanel-Border",
        edgeSize = 16,
    })
    bg:SetAllPoints(box)

    return panel
end
