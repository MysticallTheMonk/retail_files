local _, LRP = ...

local instanceType = 2
local instance = 3
local encounter = 3

local phases = {
    {
        event = "SPELL_AURA_APPLIED",
        value = 449042, -- Radiant Light
        count = 1,
        name = "Intermission",
        shortName = "I1",
    },
    {
        event = "SPELL_CAST_START",
        value = 449734, -- Acidic Eruption
        count = 1,
        name = "Phase 2",
        shortName = "P2",
    }
}

local events = {
    -- Rolling Acid
    {
        event = "SPELL_CAST_START",
        value = 434407,
        show = false,
        entries = {
            {60 * 20 + 51.7, 3},
            {60 * 21 + 11.8, 3},
            {60 * 21 + 35.7, 3},

            {60 * 22 + 48.2, 3},
            {60 * 23 + 25.2, 3},
            {60 * 24 +  2.2, 3},
            {60 * 24 + 45.2, 3},
            {60 * 25 + 16.3, 3},
            {60 * 25 + 59.3, 3},
            {60 * 26 + 34.8, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434407,
        color = {226/255, 242/255, 82/255},
        show = true,
        entries = {
            {60 * 20 + 54.7, 4},
            {60 * 21 + 14.8, 4},
            {60 * 21 + 38.7, 4},

            {60 * 22 + 51.2, 4},
            {60 * 23 + 28.2, 4},
            {60 * 24 +  5.2, 4},
            {60 * 24 + 48.2, 4},
            {60 * 25 + 19.3, 4},
            {60 * 26 +  2.3, 4},
            {60 * 26 + 37.8, 4},
        }
    },

    -- Arathi Bombs
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434671,
        color = {245/255, 104/255, 22/255},
        show = true,
        entries = {
            {60 * 20 + 54, 4},
            {60 * 21 + 27, 4},
        }
    },

    -- Erosive Spray
    {
        event = "SPELL_CAST_START",
        value = 448888,
        color = {233/255, 137/255, 240/255},
        show = true,
        entries = {
            {60 * 21 +  1.0, 3.5},
            {60 * 21 + 29.0, 3.5},

            {60 * 23 + 16.3, 3.5},
            {60 * 23 + 47.4, 3.5},
            {60 * 24 + 19.3, 3.5},
            {60 * 24 + 51.9, 3.5},
            {60 * 25 + 27.4, 3.5},
            {60 * 25 + 51.8, 3.5},
            {60 * 26 + 22.9, 3.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448888,
        show = false,
        entries = {
            {60 * 21 +  2.5},
            {60 * 21 + 30.5},

            {60 * 23 + 17.8},
            {60 * 23 + 48.9},
            {60 * 24 + 20.8},
            {60 * 24 + 53.4},
            {60 * 25 + 28.9},
            {60 * 25 + 53.3},
            {60 * 26 + 24.4},
        }
    },

    -- Expel Webs
    {
        event = "SPELL_CAST_START",
        value = 448213,
        color = {174/255, 205/255, 209/255},
        show = true,
        entries = {
            {60 * 20 + 47.7, 2},
            {60 * 21 +  7.7, 2},
            {60 * 21 + 19.7, 2},
            {60 * 21 + 41.7, 2},
            {60 * 21 + 51.7, 2},

            {60 * 23 +  7.4, 2},
            {60 * 23 + 37.8, 2},
            {60 * 23 + 54.8, 2},
            {60 * 24 + 14.8, 2},
            {60 * 24 + 40.8, 2},
            {60 * 24 + 59.3, 2},
            {60 * 25 + 23.0, 2},
            {60 * 25 + 45.0, 2},
            {60 * 26 +  6.0, 2},
            {60 * 26 + 30.4, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448213,
        show = false,
        entries = {
            {60 * 20 + 49.7},
            {60 * 21 +  9.7},
            {60 * 21 + 21.7},
            {60 * 21 + 43.7},
            {60 * 21 + 53.7},

            {60 * 23 +  9.4},
            {60 * 23 + 39.8},
            {60 * 23 + 56.8},
            {60 * 24 + 16.8},
            {60 * 24 + 42.8},
            {60 * 25 +  1.3},
            {60 * 25 + 25.0},
            {60 * 25 + 47.0},
            {60 * 26 +  8.0},
            {60 * 26 + 32.4},
        }
    },

    -- Spinneret's Strands
    {
        event = "SPELL_CAST_START",
        value = 434089,
        color = {150/255, 150/255, 150/255},
        show = true,
        entries = {
            {60 * 22 + 57.0, 4},
            {60 * 23 + 31.9, 4},
            {60 * 24 +  8.9, 4},
            {60 * 24 + 34.8, 4},
            {60 * 25 +  7.4, 4},
            {60 * 25 + 40.0, 4},
            {60 * 26 + 12.6, 4},
            {60 * 26 + 45.2, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434089,
        show = false,
        entries = {
            {60 * 22 + 59.5},
            {60 * 23 + 34.4},
            {60 * 24 + 11.4},
            {60 * 24 + 37.3},
            {60 * 25 +  9.9},
            {60 * 25 + 42.5},
            {60 * 26 + 15.1},
            {60 * 26 + 47.7},
        }
    },

    -- Radiant Light
    {
        event = "SPELL_AURA_APPLIED",
        value = 449042,
        show = false,
        entries = {
            {60 * 21 + 57.9},
        }
    },

    -- Acidic Eruption
    {
        event = "SPELL_CAST_START",
        value = 449734,
        show = false,
        entries = {
            {60 * 22 + 41.8},
        }
    },
}

local startTime = 60 * 20 + 41

for _, eventInfo in ipairs(events) do
    for _, entryInfo in ipairs(eventInfo.entries) do
        entryInfo[1] = entryInfo[1] - startTime
    end
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end