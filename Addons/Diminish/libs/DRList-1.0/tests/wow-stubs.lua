-- Stubs/polyfills when running tests from outside the game

WOW_PROJECT_MAINLINE = 1
WOW_PROJECT_CLASSIC = 2
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
WOW_PROJECT_WRATH_CLASSIC = 11
WOW_PROJECT_CATACLYSM_CLASSIC = 14
WOW_PROJECT_MISTS_CLASSIC = 19

strmatch = string.match

GetSpellInfo = function(spellID)
    if spellID and type(spellID) == "number" then
        return tostring({}):sub(10)
    end
end

GetLocale = function()
    if _G.arg and _G.arg[1] then
        local locale = _G.arg[1]:gsub("-", "")
        print("Setting locale to " .. locale) -- luacheck: ignore
        return locale
    end

    return "enUS"
end
