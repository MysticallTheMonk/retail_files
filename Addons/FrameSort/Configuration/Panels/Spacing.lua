---@type string, Addon
local _, addon = ...
local fsSorting = addon.Modules.Sorting
local fsConfig = addon.Configuration
local fsScheduler = addon.Scheduling.Scheduler
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api
local minSpacing = 0
local maxSpacing = 100
local systemChange = false
local L = addon.Locale
local M = {}
fsConfig.Panels.Spacing = M

local function ConfigureSlider(slider, value)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minSpacing, maxSpacing)
    slider:SetValue(value)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetHeight(20)
    slider:SetWidth(400)

    local low = _G[slider:GetName() .. "Low"]
    local high = _G[slider:GetName() .. "High"]

    if low and high then
        low:SetText(minSpacing)
        high:SetText(maxSpacing)
    else
        fsLog:Error("Unable to configure low/high slider values.")
    end
end

local function ConfigureEditBox(box, value)
    box:SetFontObject("GameFontWhite")
    box:SetSize(50, 20)
    box:SetAutoFocus(false)
    box:SetMaxLetters(math.log10(maxSpacing) + 1)
    box:SetText(tostring(value))
    box:SetCursorPosition(0)
    box:SetJustifyH("CENTER")
    box:SetNumeric(true)
    box:SetCursorPosition(0)
end

local function ApplySpacing()
    fsScheduler:RunWhenCombatEnds(function()
        fsSorting:Run()
    end, "ApplySpacingConfig")
end

local function SetValue(auto, slider, box)
    local value = tonumber(auto)

    if not value or value < minSpacing or value > maxSpacing then
        box:SetFontObject("GameFontRed")
        return nil
    end

    local text = tostring(value)
    box:SetFontObject("GameFontWhite")

    systemChange = true
    box:SetText(text)
    slider:SetValue(value)
    systemChange = false

    return value
end

local function BuildSpacingOptions(panel, parentAnchor, name, sliderPrefix, spacing, addX, addY, additionalTopSpacing)
    local verticalSpacing = fsConfig.VerticalSpacing
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", parentAnchor, "BOTTOMLEFT", 0, -(verticalSpacing + additionalTopSpacing))
    title:SetText(name)

    local anchor = title

    if addX then
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing)
        label:SetText(L["Horizontal"])

        local slider = wow.CreateFrame("Slider", "sld" .. sliderPrefix .. "XSpacing", panel, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -verticalSpacing)
        ConfigureSlider(slider, spacing.Horizontal)

        local box = wow.CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        box:SetPoint("CENTER", slider, "CENTER", 0, 30)
        ConfigureEditBox(box, spacing.Horizontal)

        slider.EditBox = box

        slider:SetScript("OnValueChanged", function(_, sliderValue, userInput)
            if systemChange or (userInput ~= nil and not userInput) then
                -- wotlk private doesn't have the userInput flag for sliders, but it does for text boxes
                -- so check our own flag
                return
            end

            local value = SetValue(sliderValue, slider, box)
            if value then
                spacing.Horizontal = value
                fsConfig:NotifyChanged()
                ApplySpacing()
            end
        end)

        box:SetScript("OnTextChanged", function(_, userInput)
            if not userInput then
                return
            end

            local value = SetValue(box:GetText(), slider, box)
            if value then
                spacing.Horizontal = value
                fsConfig:NotifyChanged()
                ApplySpacing()
            end
        end)

        anchor = slider
    end

    if addY then
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing)
        label:SetText(L["Vertical"])

        local slider = wow.CreateFrame("Slider", "sld" .. sliderPrefix .. "YSpacing", panel, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -verticalSpacing)
        ConfigureSlider(slider, spacing.Vertical)

        local box = wow.CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        box:SetPoint("CENTER", slider, "CENTER", 0, 30)
        ConfigureEditBox(box, spacing.Vertical)

        slider.EditBox = box

        slider:SetScript("OnValueChanged", function(_, sliderValue, userInput)
            if systemChange or (userInput ~= nil and not userInput) then
                return
            end

            box:SetText(tostring(sliderValue))

            local value = SetValue(sliderValue, slider, box)
            if value then
                spacing.Vertical = value
                fsConfig:NotifyChanged()
                ApplySpacing()
            end
        end)

        box:SetScript("OnTextChanged", function(_, userInput)
            if not userInput then
                return
            end

            local value = SetValue(box:GetText(), slider, box)

            if value then
                spacing.Vertical = value
                fsConfig:NotifyChanged()
                ApplySpacing()
            end
        end)

        anchor = slider
    end

    return anchor
end

local function RefreshValues()
    local spacing = addon.DB.Options.Spacing
    local partyX = _G["sldPartyXSpacing"]
    local partyY = _G["sldPartyYSpacing"]
    local raidX = _G["sldRaidXSpacing"]
    local raidY = _G["sldRaidYSpacing"]

    if partyX and partyY then
        SetValue(spacing.Party.Horizontal, partyX, partyX.EditBox)
        SetValue(spacing.Party.Vertical, partyY, partyY.EditBox)
    end

    if raidX and raidY then
        SetValue(spacing.Raid.Horizontal, raidX, raidX.EditBox)
        SetValue(spacing.Raid.Vertical, raidY, raidY.EditBox)
    end
end

function M:Build(parent)
    local verticalSpacing = fsConfig.VerticalSpacing
    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Spacing"]
    panel.parent = parent.name

    panel:HookScript("OnShow", RefreshValues)
    fsConfig:RegisterConfigurationChangedCallback(RefreshValues)

    local spacingTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    spacingTitle:SetPoint("TOPLEFT", panel, verticalSpacing, -verticalSpacing)
    spacingTitle:SetText(L["Spacing"])

    local lines = {
        L["Add some spacing between party, raid, and arena frames."],
        L["This only applies to Blizzard frames."],
    }

    local anchor = fsConfig:TextBlock(lines, panel, spacingTitle)
    local config = addon.DB.Options.Spacing

    if wow.IsRetail() then
        anchor = BuildSpacingOptions(panel, anchor, L["Party"], "Party", config.Party, true, true, 0)
    end

    local title = wow.IsRetail() and "Raid" or "Group"
    anchor = BuildSpacingOptions(panel, anchor, L[title], title, config.Raid, true, true, verticalSpacing)

    if wow.IsRetail() then
        anchor = BuildSpacingOptions(panel, anchor, L["Enemy Arena"], "Enemy Arena", config.EnemyArena, true, true, verticalSpacing)
    end

    return panel
end
