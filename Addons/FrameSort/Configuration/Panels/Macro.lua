---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsMacro = addon.Modules.Macro.Parser
local fsConfig = addon.Configuration
local fsLog = addon.Logging.Log
local L = addon.Locale
local M = {}
fsConfig.Panels.Macro = M

local function CountMacros()
    local count = 0

    for i = 1, addon.Modules.Macro.MaxMacros do
        local _, _, body = wow.GetMacroInfo(i)

        if body and fsMacro:IsFrameSortMacro(body) then
            count = count + 1
        end
    end

    return count
end

function M:Build(parent)
    local scroller = wow.CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroller.name = L["Macros"]
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
    title:SetText(L["Macros"])

    local countText = L["FrameSort has found %d |4macro:macros; to manage."]
    local countLine = panel:CreateFontString(nil, "ARTWORK", "GameFontGreen")
    countLine:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -verticalSpacing)
    countLine:SetText(string.format(countText, 0))

    panel:HookScript("OnShow", function()
        local count = CountMacros()
        countLine:SetText(string.format(countText, count))
    end)

    local intro = {
        L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'],
        L["Below are some examples on how to use this."],
    }

    local anchor = fsConfig:TextBlock(intro, panel, countLine)
    local examples = {
        L["Macro_Example1"],
        L["Macro_Example2"],
        L["Macro_Example3"],
    }

    local padding = 10
    for i, example in ipairs(examples) do
        local header = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
        header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing)
        header:SetText(string.format(L["Example %d"], i))

        local box = wow.CreateFrame("EditBox", nil, panel)
        box:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -verticalSpacing)
        box:SetSize(500, 1)
        box:SetFontObject("GameFontWhite")
        box:SetAutoFocus(false)
        box:SetMultiLine(true)
        box:SetText(example)
        box:SetCursorPosition(0)

        -- undo any user changes
        box:SetScript("OnTextChanged", function(_, userInput)
            if not userInput then
                return
            end

            box:SetText(example)
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

        anchor = box
    end

    local notes = {
        L["Supported variables:"],
        " - Frame1, Frame2, Frame3, etc.",
        " - Frame1Pet, Frame2Pet, Frame3Pet, etc.",
        " - BottomFrame",
        " - BFM1, BFM2, BFM3 - Bottom Frame Minus 1/2/3, etc.",
        " - Tank, Healer, DPS",
        " - TankTarget, HealerTarget, Frame1Target, etc.",
        " - OtherDps - " .. L["The first DPS that's not you."],
    }

    if wow.IsRetail() then
        notes[#notes + 1] = " - EnemyFrame1, EnemyFrame2, EnemyFrame3, etc."
        notes[#notes + 1] = " - EnemyFrame1Pet, EnemyFrame2Pet, EnemyFrame3Pet, etc."
        notes[#notes + 1] = " - EnemyTank, EnemyHealer, EnemyDPS"
    end

    notes[#notes + 1] = " - " .. L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."]
    notes[#notes + 1] = " - " .. L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."]

    anchor = fsConfig:TextBlock(notes, panel, anchor)

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

    if wow.IsRetail() then
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
