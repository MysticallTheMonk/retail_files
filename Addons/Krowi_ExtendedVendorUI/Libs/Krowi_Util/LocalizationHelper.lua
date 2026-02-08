--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local sub, parent = KROWI_LIBMAN:NewSubmodule('LocalizationHelper', 0)
if not sub or not parent then return end

local aceLocale = LibStub(parent.Constants.AceLocaleName)
local defaultLocale = 'enUS'

local function NewDefaultLocale(app, appName, localeIsLoaded, addMore)
    if localeIsLoaded[defaultLocale] and not addMore then return end
    localeIsLoaded[defaultLocale] = true
    local L = aceLocale:NewLocale(appName, defaultLocale, true)
    if not L then return end
    app.L = L
    return L
end

local function NewLocale(app, appName, localeIsLoaded, locale, addMore)
    if localeIsLoaded[locale] and not addMore then return end
    localeIsLoaded[locale] = true
    local L = aceLocale:NewLocale(appName, locale)
    if not L then return end
    app.L = L
    return L
end

local function GetLocale(appName)
    return aceLocale:GetLocale(appName)
end

function sub.InitLocalization(app, appName)
    if app.Localization then return end
    appName = appName or app.Name or app
    local localeIsLoaded = {}
    app.Localization = {
        NewDefaultLocale = function(addMore)
            return NewDefaultLocale(app, appName, localeIsLoaded, addMore)
        end,
        NewLocale = function(locale, addMore)
            return NewLocale(app, appName, localeIsLoaded, locale, addMore)
        end,
        GetLocale = function()
            return GetLocale(appName)
        end
    }
end
parent.LocalizationHelper.InitLocalization(parent)