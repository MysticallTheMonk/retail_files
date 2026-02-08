---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsLog = addon.Logging.Log
local locale = "enUS"
local M = addon.Locale

local function DefaultIndex(_, key)
    local language = addon.Locale[locale]

    if not language then
        fsLog:ErrorOnce("Incorrect locale settings, locale = %s.", locale)

        language = addon.Locale.enUS
    end

    local entry = language[key]

    if not entry and locale ~= "enUS" then
        fsLog:WarnOnce("Missing translation for key '%s' and locale '%s'", key, locale)
        return key
    end

    return entry or key
end

function M:Init()
    locale = addon.DB.Options.Locale

    if not locale or locale == "" then
        locale = wow.GetLocale()
    end

    if not locale or locale == "" then
        locale = "enUS"
    end

    setmetatable(M.Current, { __index = DefaultIndex })
end
