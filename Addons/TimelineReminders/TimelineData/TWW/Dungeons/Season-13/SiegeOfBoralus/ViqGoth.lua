local _, LRP = ...

local instanceType = 2
local instance = 7
local encounter = 3

local phases = {
    {
        event = "SPELL_CAST_SUCCESS",
        value = 269456, -- Eradication
        count = 1,
        name = "Platform 2",
        shortName = "P2"
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 269456, -- Eradication
        count = 2,
        name = "Platform 3",
        shortName = "P3"
    }
}

local events = {
    -- Eradication
    {
        event = "SPELL_CAST_START",
        value = 269456,
        color = {237/255, 40/255, 67/255},
        show = true,
        entries = {
            {60 * 46 + 38.0, 3},
            {60 * 48 + 12.0, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 269456,
        show = false,
        entries = {
            {60 * 46 + 41.0},
            {60 * 48 + 15.0},
        }
    },

    -- Putrid Waters
    {
        event = "SPELL_CAST_START",
        value = 274991,
        color = {41/255, 150/255, 240/255},
        show = true,
        entries = {
            {60 * 45 + 11.3, 2},
            {60 * 45 + 33.3, 2},
            {60 * 45 + 53.3, 2},
            {60 * 46 + 13.3, 2},
            {60 * 46 + 35.7, 2},
            {60 * 46 + 55.8, 2},
            {60 * 47 + 20.0, 2},
            {60 * 47 + 40.2, 2},
            {60 * 48 +  3.3, 2},
            {60 * 48 + 28.5, 2},
            {60 * 48 + 50.0, 2},
            {60 * 49 + 11.8, 2},
            {60 * 49 + 33.2, 2},
            {60 * 49 + 54.5, 2},
            {60 * 50 + 16.3, 2},
        }
    },
}

local startTime = 60 * 45 + 8

for _, eventInfo in ipairs(events) do
    for _, entryInfo in ipairs(eventInfo.entries) do
        entryInfo[1] = entryInfo[1] - startTime
    end
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end