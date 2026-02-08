---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsConfig = addon.Configuration
local L = addon.Locale.Current
local M = {}
fsConfig.Panels.MacroVariables = M

function M:Build(parent)
    local scroller = wow.CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroller.name = L["Macro Variables"]
    scroller.parent = parent.name

    local panel = wow.CreateFrame("Frame")
    local width, height = fsConfig:SettingsSize()

    panel:SetWidth(width)
    panel:SetHeight(height)

    scroller:SetScrollChild(panel)

    local verticalSpacing = fsConfig.VerticalSpacing
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Macro Variables"])

    local notes = {
        " - Frame1, Frame2, Frame3, etc.",
        " - Frame1Pet, Frame2Pet, Frame3Pet, etc.",
        " - BottomFrame",
        " - BFM1, BFM2, BFM3 - Bottom Frame Minus 1/2/3, etc.",
        " - Tank, Healer, DPS",
        " - TankTarget, HealerTarget, Frame1Target, etc.",
        " - OtherDps - " .. L["The first DPS that's not you."],
    }

    if wow.GetArenaOpponentSpec then
        notes[#notes + 1] = " - EnemyFrame1, EnemyFrame2, EnemyFrame3, etc."
        notes[#notes + 1] = " - EnemyFrame1Pet, EnemyFrame2Pet, EnemyFrame3Pet, etc."
        notes[#notes + 1] = " - EnemyTank, EnemyHealer, EnemyDPS"
    end

    notes[#notes + 1] = " - " .. L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."]
    notes[#notes + 1] = " - " .. L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."]

    local anchor = fsConfig:TextBlock(notes, panel, title)

    local abbreviations = {
        L["Need to save on macro characters? Use abbreviations to shorten them:"],
        " - #FS = #FrameSort",
        " - F1, F2, F3 = Frame1, Frame2, Frame3",
        " - F1P, F2P, F3P = Frame1Pet, Frame2Pet, Frame3Pet",
        " - BF = BottomFrame",
        " - T, H, D = Tank, Healer, DPS",
        " - OD = OtherDPS",
        " - EH = EnemyHealer",
        " - SomethingTG = SomethingTarget",
    }

    if wow.GetArenaOpponentSpec then
        abbreviations[#abbreviations + 1] = " - EF1, EF2, EF3 = EnemyFrame1, EnemyFrame2, EnemyFrame3."
        abbreviations[#abbreviations + 1] = " - EF1P, EF2P, EF3P = EnemyFrame1Pet, EnemyFrame2Pet, EnemyFrame3Pet, etc."
        abbreviations[#abbreviations + 1] = " - ET, EH, DP = EnemyTank, EnemyHealer, EnemyDPS."
    end

    anchor = fsConfig:TextBlock(abbreviations, panel, anchor)

    local skipDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    skipDescription:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing)
    skipDescription:SetText(L['Use "X" to tell FrameSort to ignore an @unit selector:'])

    local skipExample = L["Skip_Example"]
    local skipBox = wow.CreateFrame("EditBox", nil, panel)
    skipBox:SetPoint("TOPLEFT", skipDescription, "BOTTOMLEFT", 0, -verticalSpacing)
    skipBox:SetSize(500, 1)
    skipBox:SetFontObject("GameFontWhite")
    skipBox:SetAutoFocus(false)
    skipBox:SetMultiLine(true)
    skipBox:SetText(skipExample)
    skipBox:SetCursorPosition(0)

    -- undo any user changes
    skipBox:SetScript("OnTextChanged", function(_, userInput)
        if not userInput then
            return
        end

        skipBox:SetText(skipExample)
    end)

    local padding = 10
    skipBox:SetScript("OnEscapePressed", function()
        skipBox:ClearFocus()
    end)
    skipBox:SetTextInsets(padding, padding, padding, padding)

    local bg = wow.CreateFrame("Frame", nil, panel, "BackdropTemplate")
    bg:SetBackdrop({
        edgeFile = "Interface\\Glues\\Common\\TextPanel-Border",
        edgeSize = 16,
    })
    bg:SetAllPoints(skipBox)

    return scroller
end
