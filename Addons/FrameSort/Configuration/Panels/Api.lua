---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsConfig = addon.Configuration
local fsLog = addon.Logging.Log
local L = addon.Locale
local M = {}
fsConfig.Panels.Api = M

function M:Build(parent)
    local scroller = wow.CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroller.name = L["Api"]
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
    title:SetText(L["Api"])

    local anchor = title
    local intro = {
        L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"],
        L["Here are some examples."],
    }

    anchor = fsConfig:TextBlock(intro, panel, title)

    local examples = {
        {
            Description = L["Retrieved an ordered array of party/raid unit tokens."],
            Text = "/dump FrameSortApi.v2.Sorting:GetFriendlyUnits()",
        },
        {
            Description = L["Retrieved an ordered array of arena unit tokens."],
            Text = "/dump FrameSortApi.v2.Sorting:GetEnemyUnits()",
        },
        {
            Description = L["Register a callback function to run after FrameSort sorts frames."],
            Text = [[/run FrameSortApi.v2.Sorting:RegisterPostSortCallback(function() print("FrameSort has sorted frames.") end)]],
        },
        {
            Description = L["Retrieve an ordered array of party frames."],
            Text = "/dump FrameSortApi.v2.Sorting:GetPartyFrames()",
        },
        {
            Description = L["Change a FrameSort setting."],
            Text = [[/run FrameSortApi.v2.Options:SetPlayerSortMode("Arena - 2v2", "Top")]],
        },
        {
            Description = L["View a full listing of all API methods on GitHub."],
            Text = [[https://github.com/Verubato/framesort/tree/main/src/Api]],
        },
    }

    local padding = 10

    for _, example in ipairs(examples) do
        local header = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
        header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing)
        header:SetText(example.Description)

        local box = wow.CreateFrame("EditBox", nil, panel)
        box:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -verticalSpacing)
        box:SetSize(500, 1)
        box:SetFontObject("GameFontWhite")
        box:SetAutoFocus(false)
        box:SetMultiLine(true)
        box:SetText(example.Text)
        box:SetCursorPosition(0)

        -- undo any user changes
        box:SetScript("OnTextChanged", function(_, userInput)
            if not userInput then
                return
            end

            box:SetText(example.Text)
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

    return scroller
end
