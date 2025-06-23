local _, NS = ...
local DRList = LibStub("DRList-1.0")

NS.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
NS.IS_CLASSIC = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
NS.IS_TBC = WOW_PROJECT_ID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5)
NS.IS_WRATH = WOW_PROJECT_ID == (WOW_PROJECT_WRATH_CLASSIC or 11)
NS.IS_NOT_RETAIL = not NS.IS_RETAIL

-- How long a diminishing return lasts.
NS.DR_TIME = DRList:GetResetTime()

-- Border/text indicator colors
NS.DR_STATES_COLORS = {
    { 0, 1, 0, 1 }, -- applied 1, green
    { 1, 1, 0, 1 }, -- applied 2, yellow
    { 1, 0, 0, 1 }, -- applied 3, red
}

-------------------------------------------------------
-------------------------------------------------------

-- "enum" for categories
NS.CATEGORIES = CopyTable(DRList:GetCategories())
if NS.CATEGORIES.knockback then
    NS.CATEGORIES.knockback = nil -- unreliable to track, remove it for now
end

-------------------------------------------------------
-- Default SavedVariables
-------------------------------------------------------

do
    local defaultsDisabledCategories = {}

    if NS.IS_CLASSIC and NS.CATEGORIES.frost_shock then
        defaultsDisabledCategories[NS.CATEGORIES.frost_shock] = true
    end

    if NS.IS_RETAIL and NS.CATEGORIES.taunt then
        defaultsDisabledCategories[NS.CATEGORIES.taunt] = true
    end

    local defaultsTarget = {
        enabled = true,
        zones = {
            pvp = true, arena = false, none = true,
            party = false, raid = false, scenario = true,
        },
        disabledCategories = defaultsDisabledCategories,
        anchorUIParent = false,
        watchFriendly = false,
        iconSize = 22,
        iconPadding = 10,
        growDirection = "RIGHT",
        offsetY = 23,
        offsetX = 104,
        timerTextSize = 12,
    }

    NS.DEFAULT_SETTINGS = {
        version = "1.11",
        announceDRs = false,
        timerTextOutline = "NONE",
        timerText = true,
        timerSwipe = true,
        timerEdge = true,
        timerColors = false,
        timerStartAuraEnd = false,
        showCategoryText = true,
        categoryTextMaxLines = 2,
        colorBlind = false,
        trackNPCs = true,
        categoryTextures = {},
        border = {
            edgeSize = 2.5,
            edgeFile = "Interface\\BUTTONS\\UI-Quickslot-Depress",
            layer = "BORDER",
            name = "Default",
        },
        categoryFont = {
            font = nil, -- uses font from template instead
            size = tonumber(GetCVar("UIScale")) <= 0.75 and 11 or 9,
            x = 0,
            --y = 12,
            flags = nil,
        },

        unitFrames = {
            target = CopyTable(defaultsTarget),
            focus = CopyTable(defaultsTarget),

            player = {
                enabled = true,
                zones = {
                    pvp = true, arena = true, none = true,
                    party = false, raid = false, scenario = true,
                },
                disabledCategories = defaultsDisabledCategories,
                anchorUIParent = false,
                watchFriendly = true,
                iconSize = 21,
                iconPadding = 10,
                growDirection = "RIGHT",
                offsetY = 40,
                offsetX = -6,
                timerTextSize = 12,
                usePersonalNameplate = false,
            },

            party = {
                enabled = false,
                zones = {
                    pvp = false, arena = true, none = true,
                    party = false, raid = false, scenario = false,
                },
                disabledCategories = defaultsDisabledCategories,
                anchorUIParent = false,
                watchFriendly = true,
                iconSize = 24,
                iconPadding = 10,
                growDirection = "RIGHT",
                offsetY = 7,
                offsetX = 76,
                timerTextSize = 12,
            },

            arena = {
                enabled = true,
                zones = {
                    pvp = false, arena = true, none = false,
                    party = false, raid = false, scenario = false,
                },
                disabledCategories = defaultsDisabledCategories,
                anchorUIParent = false,
                iconSize = 22,
                iconPadding = 10,
                growDirection = "LEFT",
                offsetY = 20,
                offsetX = -66,
                timerTextSize = 12,
            },

            nameplate = {
                enabled = false,
                zones = {
                    pvp = true, arena = true, none = true,
                    party = false, raid = false, scenario = true,
                },
                disabledCategories = defaultsDisabledCategories,
                watchFriendly = false,
                iconSize = 22,
                iconPadding = 10,
                growDirection = "RIGHT",
                offsetY = 71,
                offsetX = -33,
                timerTextSize = 12,
            },
        },
    }

    if NS.IS_CLASSIC then
        NS.DEFAULT_SETTINGS.unitFrames.focus.enabled = false
        NS.DEFAULT_SETTINGS.unitFrames.arena.enabled = false
    end
end
