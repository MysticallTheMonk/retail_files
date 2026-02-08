--[[--------------------------------------------------------------------------
--  TomTom by Cladhaire <cladhaire@gmail.com>
--
--  All Rights Reserved
----------------------------------------------------------------------------]]

local addonName, addon = ...

-- Simple localization table for messages
local L = TomTomLocals

local registry = {}
addon.waypointThemeRegistry = registry

local themeConfig = {}

local modernVariants = {
    "Blue",
    "Fuscia",
    "Green",
    "LightBlue",
    "Orange",
    "Purple",
    "Red",
    "Yellow",
}

for _, variant in ipairs(modernVariants) do
    local key = string.format("modern-%s", variant:lower())
    themeConfig[key] = {
        key = key,
        name = L["Modern theme %s"]:format(variant),
        arrowTexture = string.format("Interface\\AddOns\\TomTom\\Images\\Modern\\Waypoints\\WaypointArrow%s", variant),
        dotTexture = string.format("Interface\\AddOns\\TomTom\\Images\\Modern\\Waypoints\\WaypointDot%s", variant),
        dotSize = 20,
        arrowSize = 20,
    }
end

local classicVariants = {
    ["classic-gold-green"] = {
        key = "classic-gold-green",
        name = L["Classic Gold Green Dot"],
        dotTexture = "Interface\\AddOns\\TomTom\\Images\\GoldGreenDot",
        arrowTexture = "Interface\\AddOns\\TomTom\\Images\\MinimapArrow-Green",
        dotSize = 16,
        arrowSize = 30,
    },
    ["classic-gold-blue"] = {
        key = "classic-gold-blue",
        name = L["Classic Gold Blue Dot"],
        dotTexture = "Interface\\AddOns\\TomTom\\Images\\GoldBlueDotNew",
        arrowTexture = "Interface\\AddOns\\TomTom\\Images\\MinimapArrow-Green",
        dotSize = 16,
        arrowSize = 30,
    },
    ["classic-gold-green-new"] = {
        key = "classic-gold-green-new",
        name = L["Classic Gold Green Dot"],
        dotTexture = "Interface\\AddOns\\TomTom\\Images\\GoldGreenDotNew",
        arrowTexture = "Interface\\AddOns\\TomTom\\Images\\MinimapArrow-Green",
        dotSize = 16,
        arrowSize = 30,
    },
    ["classic-gold-purple"] = {
        key = "classic-gold-purple",
        name = L["Classic Gold Purple Dot"],
        dotTexture = "Interface\\AddOns\\TomTom\\Images\\GoldPurpleDotNew",
        arrowTexture = "Interface\\AddOns\\TomTom\\Images\\MinimapArrow-Green",
        dotSize = 16,
        arrowSize = 30,
    },
    ["classic-gold-red"] = {
        key = "classic-gold-red",
        name = L["Classic Gold Red Dot"],
        dotTexture = "Interface\\AddOns\\TomTom\\Images\\GoldRedDotNew",
        arrowTexture = "Interface\\AddOns\\TomTom\\Images\\MinimapArrow-Green",
        dotSize = 16,
        arrowSize = 30,
    },
    ["classic-purple-ring"] = {
        key = "classic-purple-ring",
        name = L["Classic Purple Ring"],
        dotTexture = "Interface\\AddOns\\TomTom\\Images\\PurpleRing.tga",
        arrowTexture = "Interface\\AddOns\\TomTom\\Images\\MinimapArrow-Green",
        dotSize = 16,
        arrowSize = 30,
    },
}

-- Add classic to the registry
for key, config in pairs(classicVariants) do
    themeConfig[key] = config
end

function registry:GetThemeConfigOptions()
    local options = {}
    for key,value in pairs(themeConfig) do
        options[key] = value.name
    end
    return options
end

function registry:GetThemeConfigOptionsSorting()
    return {
        "modern-green",
        "modern-blue",
        "modern-fuscia",
        "modern-lightblue",
        "modern-orange",
        "modern-purple",
        "modern-red",
        "modern-yellow",
        "classic-gold-green",
        "classic-gold-blue",
        "classic-gold-green-new",
        "classic-gold-purple",
        "classic-gold-red",
        "classic-purple-ring",
    }
end

function registry:GetThemeDotTexture(key)
    return themeConfig[key].dotTexture
end

function registry:GetThemeArrowTexture(key)
    return themeConfig[key].arrowTexture
end

function registry:GetThemeDotSize(key)
    return themeConfig[key].dotSize
end

function registry:GetThemeArrowSize(key)
    return themeConfig[key].arrowSize
end
