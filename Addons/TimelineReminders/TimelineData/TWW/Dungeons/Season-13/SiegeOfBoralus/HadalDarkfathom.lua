local _, LRP = ...

local instanceType = 2
local instance = 7
local encounter = 2

local phases = {}

for i = 1, 5 do
    table.insert(
        phases,
        {
            event = "SPELL_CAST_SUCCESS",
            value = 276068, -- Tidal Surge
            count = i,
            name = string.format("Rotation %d", i),
            shortName = string.format("R%d", i),
        }
    )
end

local events = {
    -- Tidal Surge
    {
        event = "SPELL_CAST_START",
        value = 276068,
        color = {235/255, 26/255, 68/255},
        show = true,
        entries = {
            {60 * 34 + 38.8, 4},
            {60 * 35 + 28.7, 4},
            {60 * 36 + 17.2, 4},
            {60 * 37 +  5.8, 4},
            {60 * 37 + 55.6, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 276068,
        show = false,
        entries = {
            {60 * 34 + 42.8},
            {60 * 35 + 32.7},
            {60 * 36 + 21.2},
            {60 * 37 +  9.8},
            {60 * 37 + 59.6},
        }
    },

    -- Crashing Tide
    {
        event = "SPELL_CAST_START",
        value = 257862,
        color = {91/255, 235/255, 165/255},
        show = true,
        entries = {
            {60 * 34 + 27.9, 3},
            {60 * 34 + 59.5, 3},
            {60 * 35 + 22.6, 3},
            {60 * 35 + 54.2, 3},
            {60 * 36 + 22.1, 3},
            {60 * 36 + 46.4, 3},
            {60 * 37 + 17.9, 3},
            {60 * 37 + 41.0, 3},
            {60 * 38 + 12.7, 3},
        }
    },

    -- Break Water
    {
        event = "SPELL_CAST_START",
        value = 257882,
        color = {64/255, 197/255, 237/255},
        show = true,
        entries = {
            {60 * 34 + 23.0, 1},
            {60 * 34 + 52.2, 1},
            {60 * 35 + 12.9, 1},
            {60 * 35 + 42.0, 1},
            {60 * 36 +  2.7, 1},
            {60 * 36 + 31.8, 1},
            {60 * 36 + 53.7, 1},
            {60 * 37 + 25.2, 1},
            {60 * 37 + 48.3, 1},
            {60 * 38 + 20.0, 1},
        }
    },
}

local startTime = 60 * 34 + 15.7

for _, eventInfo in ipairs(events) do
    for _, entryInfo in ipairs(eventInfo.entries) do
        entryInfo[1] = entryInfo[1] - startTime
    end
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end