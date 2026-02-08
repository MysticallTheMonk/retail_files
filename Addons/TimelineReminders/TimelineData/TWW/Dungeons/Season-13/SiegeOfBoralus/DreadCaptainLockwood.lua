local _, LRP = ...

local instanceType = 2
local instance = 7
local encounter = 1

local phases = {
    {
        event = "SPELL_AURA_APPLIED",
        value = 268752,
        count = 1,
        name = "Intermission 1",
        shortName = "I1"
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 268752,
        count = 1,
        name = "Phase 2",
        shortName = "P2"
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 268752,
        count = 2,
        name = "Intermission 2",
        shortName = "I2"
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 268752,
        count = 2,
        name = "Phase 3",
        shortName = "P3"
    },
}

local events = {
    -- Withdraw
    {
        event = "SPELL_AURA_APPLIED",
        value = 268752,
        color = {85/255, 143/255, 230/255},
        show = true,
        entries = {
            {60 * 11 + 34.4, 39},
            {60 * 12 + 46.0, 35},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 268752,
        show = false,
        entries = {
            {60 * 12 + 13.4},
            {60 * 13 + 21.0},
        }
    },

    -- Clear the Deck
    {
        event = "SPELL_CAST_START",
        value = 269029,
        color = {237/255, 237/255, 57/255},
        show = true,
        entries = {
            {60 * 10 + 43.4, 3},
            {60 * 11 +  2.8, 3},
            {60 * 11 + 21.0, 3},

            {60 * 12 + 16.9, 3},
            {60 * 12 + 36.3, 3},

            {60 * 13 + 24.9, 3},
            {60 * 13 + 44.3, 3},
            {60 * 14 +  3.8, 3},
        }
    },

    -- Fiery Ricochet
    {
        event = "SPELL_CAST_START",
        value = 463182,
        color = {235/255, 112/255, 35/255},
        show = true,
        entries = {
            {60 * 10 + 47.9, 2},
            {60 * 11 +  7.3, 2},
            {60 * 11 + 25.6, 2},

            {60 * 12 + 24.1, 2},
            {60 * 12 + 43.6, 2},

            {60 * 13 + 29.4, 2},
            {60 * 13 + 48.8, 2},
            {60 * 14 +  8.3, 2},
        }
    },
}

local startTime = 60 * 10 + 38.6

for _, eventInfo in ipairs(events) do
    for _, entryInfo in ipairs(eventInfo.entries) do
        entryInfo[1] = entryInfo[1] - startTime
    end
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end