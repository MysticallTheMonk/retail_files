---@type string, Addon
local _, addon = ...
local fsConfig = addon.Configuration
local wow = addon.WoW.Api
local fsLog = addon.Logging.Log
local modules = addon.Modules
local L = addon.Locale
local M = {}
fsConfig.Panels.Ordering = M

function M:Build(parent)
    local verticalSpacing = fsConfig.VerticalSpacing
    local horizontalSpacing = fsConfig.HorizontalSpacing

    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Ordering"]
    panel.parent = parent.name

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Ordering"])

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -verticalSpacing)
    description:SetText(L["Specify the ordering you wish to use when sorting by role."])

    local all = {}

    local function setValue(type, value)
        -- grab the current order
        local config = addon.DB.Options.Sorting.Ordering
        local toSwap = nil

        -- find the existing item to be swapped
        for k, v in pairs(config) do
            if v == value then
                toSwap = k
            end
        end

        if not toSwap then
            fsLog:Error("Couldn't determine existing value to swap.")
            return
        end

        local currentValue = config[type]
        config[type] = value
        config[toSwap] = currentValue

        for _, ddl in ipairs(all) do
            ddl:FrameSortRefresh()
        end

        modules:Run()
    end

    local items = { 1, 2, 3, 4, 5 }

    local function setup(ddl, label)
        label:SetWidth(100)
        label:SetJustifyH("LEFT")

        ddl:SetPoint("CENTER", label, "CENTER")
        ddl:SetPoint("LEFT", label, "RIGHT", horizontalSpacing)
    end

    local orderingConfig = addon.DB.Options.Sorting.Ordering
    local tanksLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    tanksLabel:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -verticalSpacing * 2)
    tanksLabel:SetText(L["Tanks"])

    local tanks = fsConfig:Dropdown(panel, items, function()
        return orderingConfig.Tanks
    end, function(value)
        setValue("Tanks", value)
    end)

    setup(tanks, tanksLabel)

    local healersLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    healersLabel:SetPoint("TOPLEFT", tanksLabel, "BOTTOMLEFT", 0, -verticalSpacing * 2)
    healersLabel:SetText(L["Healers"])

    local healers = fsConfig:Dropdown(panel, items, function()
        return orderingConfig.Healers
    end, function(value)
        setValue("Healers", value)
    end)

    setup(healers, healersLabel)

    local castersLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    castersLabel:SetPoint("TOPLEFT", healersLabel, "BOTTOMLEFT", 0, -verticalSpacing * 2)
    castersLabel:SetText(L["Casters"])

    local casters = fsConfig:Dropdown(panel, items, function()
        return orderingConfig.Casters
    end, function(value)
        setValue("Casters", value)
    end)

    setup(casters, castersLabel)

    local huntersLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    huntersLabel:SetPoint("TOPLEFT", castersLabel, "BOTTOMLEFT", 0, -verticalSpacing * 2)
    huntersLabel:SetText(L["Hunters"])

    local hunters = fsConfig:Dropdown(panel, items, function()
        return orderingConfig.Hunters
    end, function(value)
        setValue("Hunters", value)
    end)

    setup(hunters, huntersLabel)

    local meleeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    meleeLabel:SetPoint("TOPLEFT", huntersLabel, "BOTTOMLEFT", 0, -verticalSpacing * 2)
    meleeLabel:SetText(L["Melee"])

    local melee = fsConfig:Dropdown(panel, items, function()
        return orderingConfig.Melee
    end, function(value)
        setValue("Melee", value)
    end)

    setup(melee, meleeLabel)

    all = { tanks, healers, casters, hunters, melee }

    return panel
end
