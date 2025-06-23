---@type string, Addon
local _, addon = ...
local fsConfig = addon.Configuration
local wow = addon.WoW.Api
local L = addon.Locale
local M = {}
fsConfig.Panels.Keybinding = M

local function SetBindingNames()
    BINDING_HEADER_FRAMESORT_TARGET = L["Targeting"]
    _G["BINDING_NAME_CLICK FSTarget1:LeftButton"] = L["Target frame 1 (top frame)"]
    _G["BINDING_NAME_CLICK FSTarget2:LeftButton"] = L["Target frame 2"]
    _G["BINDING_NAME_CLICK FSTarget3:LeftButton"] = L["Target frame 3"]
    _G["BINDING_NAME_CLICK FSTarget4:LeftButton"] = L["Target frame 4"]
    _G["BINDING_NAME_CLICK FSTarget5:LeftButton"] = L["Target frame 5"]
    _G["BINDING_NAME_CLICK FSTargetBottom:LeftButton"] = L["Target bottom frame"]
    _G["BINDING_NAME_CLICK FSTargetBottomMinus1:LeftButton"] = L["Target 1 frame above bottom"]
    _G["BINDING_NAME_CLICK FSTargetBottomMinus2:LeftButton"] = L["Target 2 frames above bottom"]
    _G["BINDING_NAME_CLICK FSTargetBottomMinus3:LeftButton"] = L["Target 3 frames above bottom"]
    _G["BINDING_NAME_CLICK FSTargetBottomMinus4:LeftButton"] = L["Target 4 frames above bottom"]
    _G["BINDING_NAME_CLICK FSTargetPet1:LeftButton"] = L["Target frame 1's pet"]
    _G["BINDING_NAME_CLICK FSTargetPet2:LeftButton"] = L["Target frame 2's pet"]
    _G["BINDING_NAME_CLICK FSTargetPet3:LeftButton"] = L["Target frame 3's pet"]
    _G["BINDING_NAME_CLICK FSTargetPet4:LeftButton"] = L["Target frame 4's pet"]
    _G["BINDING_NAME_CLICK FSTargetPet5:LeftButton"] = L["Target frame 5's pet"]
    _G["BINDING_NAME_CLICK FSTargetEnemy1:LeftButton"] = L["Target enemy frame 1"]
    _G["BINDING_NAME_CLICK FSTargetEnemy2:LeftButton"] = L["Target enemy frame 2"]
    _G["BINDING_NAME_CLICK FSTargetEnemy3:LeftButton"] = L["Target enemy frame 3"]
    _G["BINDING_NAME_CLICK FSTargetEnemyPet1:LeftButton"] = L["Target enemy frame 1's pet"]
    _G["BINDING_NAME_CLICK FSTargetEnemyPet2:LeftButton"] = L["Target enemy frame 2's pet"]
    _G["BINDING_NAME_CLICK FSTargetEnemyPet3:LeftButton"] = L["Target enemy frame 3's pet"]
    _G["BINDING_NAME_CLICK FSFocusEnemy1:LeftButton"] = L["Focus enemy frame 1"]
    _G["BINDING_NAME_CLICK FSFocusEnemy2:LeftButton"] = L["Focus enemy frame 2"]
    _G["BINDING_NAME_CLICK FSFocusEnemy3:LeftButton"] = L["Focus enemy frame 3"]
    _G["BINDING_NAME_CLICK FSCycleNextFrame:LeftButton"] = L["Cycle to the next frame"]
    _G["BINDING_NAME_CLICK FSCyclePreviousFrame:LeftButton"] = L["Cycle to the previous frame"]
    _G["BINDING_NAME_CLICK FSTargetNextFrame:LeftButton"] = L["Target the next frame"]
    _G["BINDING_NAME_CLICK FSTargetPreviousFrame:LeftButton"] = L["Target the previous frame"]
end

function M:Build(parent)
    local verticalSpacing = fsConfig.VerticalSpacing
    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Keybindings"]
    panel.parent = parent.name

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Keybindings"])

    local text = L["Keybindings_Description"]
    fsConfig:MultilineTextBlock(text, panel, title)

    SetBindingNames()

    return panel
end
