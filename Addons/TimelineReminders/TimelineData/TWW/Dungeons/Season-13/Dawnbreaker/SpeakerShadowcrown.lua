local _, LRP = ...

local instanceType = 2
local instance = 3
local encounter = 1

local phases = {
    {
        event = "SPELL_AURA_REMOVED",
        value = 453859, -- Darkness Comes
        count = 1,
        name = "Phase 2",
        shortName = "P2"
    }
}

local events = {
    -- Darkness Comes
    {
        event = "SPELL_CAST_START",
        value = 451026,
        show = false,
        entries = {
            {60 * 10 + 41.4, 15},
            {60 * 13 + 52.1, 15},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 451026,
        show = false,
        entries = {
            {60 * 10 + 56.4},
            {60 * 14 +  7.1},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 453859,
        color = {235/255, 45/255, 83/255},
        show = true,
        entries = {
            {60 * 10 + 41.4, 15},
            {60 * 13 + 52.1, 15},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 453859,
        show = false,
        entries = {
            {60 * 10 + 56.4},
            {60 * 14 +  7.1},
        }
    },

    -- Obsidian Beam
    {
        event = "SPELL_CAST_START",
        value = 453212,
        show = false,
        entries = {
            {60 *  8 + 53.8, 3},
            {60 *  9 + 24.7, 3},
            {60 *  9 + 51.4, 3},
            {60 * 10 + 21.2, 3},
            {60 * 11 + 15.2, 3},
            {60 * 11 + 38.8, 3},
            {60 * 12 +  3.6, 3},
            {60 * 12 + 30.3, 3},
            {60 * 12 + 57.0, 3},
            {60 * 13 + 27.6, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 453212,
        show = false,
        entries = {
            {60 *  8 + 55.8},
            {60 *  9 + 27.7},
            {60 *  9 + 54.4},
            {60 * 10 + 24.2},
            {60 * 11 + 18.2},
            {60 * 11 + 41.8},
            {60 * 12 +  6.6},
            {60 * 12 + 33.3},
            {60 * 13 +  0.0},
            {60 * 13 + 30.6},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 453212,
        color = {235/255, 45/255, 219/255},
        show = true,
        entries = {
            {60 *  8 + 55.8, 6},
            {60 *  9 + 27.7, 6},
            {60 *  9 + 54.4, 6},
            {60 * 10 + 24.2, 6},
            {60 * 11 + 18.2, 6},
            {60 * 11 + 41.8, 6},
            {60 * 12 +  6.6, 6},
            {60 * 12 + 33.3, 6},
            {60 * 13 +  0.0, 6},
            {60 * 13 + 30.6, 6},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 453212,
        show = false,
        entries = {
            {60 *  9 +  1.8},
            {60 *  9 + 33.7},
            {60 * 10 +  0.4},
            {60 * 10 + 30.2},
            {60 * 11 + 24.2},
            {60 * 11 + 47.8},
            {60 * 12 + 12.6},
            {60 * 12 + 39.3},
            {60 * 13 +  6.0},
            {60 * 13 + 36.6},
        }
    },

    -- Collapsing Night
    {
        event = "SPELL_CAST_START",
        value = 453140,
        color = {117/255, 103/255, 245/255},
        show = true,
        entries = {
            {60 *  9 +  9.0, 1.5},
            {60 *  9 + 37.0, 1.5},
            {60 * 10 +  3.6, 1.5},
            {60 * 10 + 33.5, 1.5},
            {60 * 11 +  5.3, 1.5},
            {60 * 11 + 32.8, 1.5},
            {60 * 11 + 58.0, 1.5},
            {60 * 12 + 24.4, 1.5},
            {60 * 12 + 51.3, 1.5},
            {60 * 13 + 18.0, 1.5},
            {60 * 13 + 45.3, 1.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 453140,
        show = false,
        entries = {
            {60 *  9 + 10.5},
            {60 *  9 + 38.5},
            {60 * 10 +  5.1},
            {60 * 10 + 35.0},
            {60 * 11 +  6.8},
            {60 * 11 + 34.3},
            {60 * 11 + 59.5},
            {60 * 12 + 25.9},
            {60 * 12 + 52.8},
            {60 * 13 + 19.5},
            {60 * 13 + 46.8},
        }
    },

    -- Burning Shadows
    {
        event = "SPELL_CAST_START",
        value = 426734,
        color = {145/255, 19/255, 235/255},
        show = true,
        entries = {
            {60 *  9 +  4.8, 2},
            {60 *  9 + 20.5, 2},
            {60 *  9 + 45.3, 2},
            {60 * 10 +  9.8, 2},
            {60 * 11 + 11.3, 2},
            {60 * 11 + 29.1, 2},
            {60 * 11 + 51.1, 2},
            {60 * 12 + 14.3, 2},
            {60 * 12 + 41.3, 2},
            {60 * 13 +  8.0, 2},
            {60 * 13 + 23.4, 2},
            {60 * 13 + 41.6, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 426734,
        show = false,
        entries = {
            {60 *  9 +  6.8, 2},
            {60 *  9 + 22.5, 2},
            {60 *  9 + 47.3, 2},
            {60 * 10 + 11.8, 2},
            {60 * 11 + 13.3, 2},
            {60 * 11 + 31.1, 2},
            {60 * 11 + 53.1, 2},
            {60 * 12 + 16.3, 2},
            {60 * 12 + 43.3, 2},
            {60 * 13 + 10.0, 2},
            {60 * 13 + 25.4, 2},
            {60 * 13 + 43.6, 2},
        }
    },
}

local startTime = 60 * 8 + 45

for _, eventInfo in ipairs(events) do
    for _, entryInfo in ipairs(eventInfo.entries) do
        entryInfo[1] = entryInfo[1] - startTime
    end
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end