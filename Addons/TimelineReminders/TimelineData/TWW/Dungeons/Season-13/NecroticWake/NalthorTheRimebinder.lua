local _, LRP = ...

local instanceType = 2
local instance = 6
local encounter = 3

local phases = {}

for i = 1, 9 do
    table.insert(
        phases,
        {
            event = "SPELL_CAST_START",
            value = 320788, -- Frozen Binds
            count = i,
            name = string.format("Rotation %d", i),
            shortName = string.format("R%d", i),
        }
    )
end

local events = {
    -- Dark Exile
    {
        event = "SPELL_CAST_START",
        value = 321894,
        color = {59/255, 237/255, 148/255},
        show = true,
        entries = {
            {60 * 42 + 12.0, 2},
            {60 * 42 + 47.6, 2},
            {60 * 43 + 24.1, 2},
            {60 * 44 +  1.8, 2},
            {60 * 44 + 37.0, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 321894,
        show = false,
        entries = {
            {60 * 42 + 14.0},
            {60 * 42 + 49.6},
            {60 * 43 + 26.1},
            {60 * 44 +  3.8},
            {60 * 44 + 39.0},
        }
    },

    -- Icebound Aegis
    {
        event = "SPELL_CAST_SUCCESS",
        value = 321754,
        color = {59/255, 239/255, 245/255},
        show = true,
        entries = {
            {60 * 41 + 57.4, 6},
            {60 * 42 + 21.7, 6},
            {60 * 42 + 47.6, 6},
            {60 * 43 + 13.1, 6},
            {60 * 43 + 38.7, 6},
            {60 * 44 +  4.1, 6},
            {60 * 44 + 28.5, 6},
            {60 * 44 + 54.0, 6},
            {60 * 45 + 19.5, 6},
        }
    },

    -- Comet Storm
    {
        event = "SPELL_AURA_APPLIED",
        value = 320772,
        color = {235/255, 61/255, 128/255},
        show = true,
        entries = {
            {60 * 42 +  5.5, 4},
            {60 * 42 + 30.7, 4},
            {60 * 42 + 55.7, 4},
            {60 * 43 + 20.0, 4},
            {60 * 43 + 44.3, 4},
            {60 * 44 +  8.6, 4},
            {60 * 44 + 32.9, 4},
            {60 * 44 + 58.4, 4},
            {60 * 45 + 23.9, 4},
        }
    },

    -- Frozen Binds
    {
        event = "SPELL_CAST_START",
        value = 320788,
        color = {64/255, 116/255, 237/255},
        show = true,
        entries = {
            {60 * 41 + 52.5, 2},
            {60 * 42 + 16.8, 2},
            {60 * 42 + 42.8, 2},
            {60 * 43 +  8.2, 2},
            {60 * 43 + 33.8, 2},
            {60 * 43 + 59.3, 2},
            {60 * 44 + 23.6, 2},
            {60 * 44 + 49.2, 2},
            {60 * 45 + 14.6, 2},
            {60 * 45 + 40.1, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 320788,
        show = false,
        entries = {
            {60 * 41 + 54.5},
            {60 * 42 + 18.8},
            {60 * 42 + 44.8},
            {60 * 43 + 10.2},
            {60 * 43 + 35.8},
            {60 * 44 +  1.3},
            {60 * 44 + 25.6},
            {60 * 44 + 51.2},
            {60 * 45 + 16.6},
            {60 * 45 + 42.1},
        }
    },
}

local startTime = 60 * 41 + 45.3

for _, eventInfo in ipairs(events) do
    for _, entryInfo in ipairs(eventInfo.entries) do
        entryInfo[1] = entryInfo[1] - startTime
    end
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end