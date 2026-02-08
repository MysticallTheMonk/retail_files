local _, LRP = ...

local instanceType = 2
local instance = 4
local encounter = 3

local phases = {}

local events = {
    -- Dorlita: Blazing Crescendo
    {
        event = "SPELL_CAST_SUCCESS",
        value = 428508,
        color = {252/255, 218/255, 63/255},
        show = true,
        entries = {
        }
    },

    -- Dorlita: Lava Cannon
    {
        event = "SPELL_CAST_START",
        value = 449167,
        color = {252/255, 69/255, 18/255},
        show = true,
        entries = {
            {60 * 18 +  4.4, 3},
            {60 * 18 + 21.8, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 449167,
        show = false,
        entries = {
            {60 * 18 +  7.4},
            {60 * 18 + 24.8},
        }
    },

    -- Dorlita: Igneous Hammer
    {
        event = "SPELL_CAST_START",
        value = 428711,
        color = {214/255, 147/255, 64/255},
        show = true,
        entries = {
            {60 * 17 + 58.3, 2},
            {60 * 18 + 10.8, 2},
            {60 * 18 + 25.3, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 428711,
        show = false,
        entries = {
            {60 * 18 +  0.3},
            {60 * 18 + 12.8},
            {60 * 18 + 27.3},
        }
    },

    -- Brokk: Scrap Song
    {
        event = "SPELL_CAST_START",
        value = 428202,
        color = {181/255, 179/255, 176/255},
        show = true,
        entries = {
            {60 * 18 +  6.8, 6},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 428202,
        show = false,
        entries = {
            {60 * 18 +  8.8},
        }
    },

    -- Brokk: Exhaust Vents
    {
        event = "SPELL_CAST_SUCCESS",
        value = 445541,
        color = {242/255, 92/255, 247/255},
        show = true,
        entries = {
            {60 * 18 + 25.4, 6},
        }
    },

    -- Brokk: Molten Metal
    {
        event = "SPELL_CAST_START",
        value = 430097,
        color = {95/255, 130/255, 237/255},
        show = true,
        entries = {
            {60 * 17 + 55.9, 3},
            {60 * 18 + 14.5, 3},
            {60 * 18 + 32.7, 3},
        }
    },
}

local startTime = 60 * 17 + 51.2
local repeatInterval = 52
local repeatCount = 6
local repeated = {
    -- Dorlita: Blazing Crescendo
    {
        event = "SPELL_CAST_SUCCESS",
        value = 428508,
        color = {109/255, 45/255, 237/255},
        show = true,
        entries = {
            {60 * 18 + 36.3, 6}
        }
    },

    -- Dorlita: Lava Cannon
    {
        event = "SPELL_CAST_START",
        value = 449167,
        color = {109/255, 45/255, 237/255},
        show = true,
        entries = {
            {60 * 18 + 58.8, 3},
            {60 * 19 + 19.4, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 449167,
        show = false,
        entries = {
            {60 * 19 +  1.8},
            {60 * 19 + 22.4},
        }
    },

    -- Dorlita: Igneous Hammer
    {
        event = "SPELL_CAST_START",
        value = 428711,
        color = {109/255, 45/255, 237/255},
        show = true,
        entries = {
            {60 * 18 + 49.7, 2},
            {60 * 19 +  1.8, 2},
            {60 * 19 + 14.0, 2},
            {60 * 19 + 26.1, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 428711,
        show = false,
        entries = {
            {60 * 18 + 51.7},
            {60 * 19 +  3.8},
            {60 * 19 + 16.0},
            {60 * 19 + 28.1},
        }
    },

    -- Brokk: Scrap Song
    {
        event = "SPELL_CAST_START",
        value = 428202,
        color = {109/255, 45/255, 237/255},
        show = true,
        entries = {
            {60 * 19 +  0.6, 6},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 428202,
        show = false,
        entries = {
            {60 * 19 +  2.6},
        }
    },

    -- Brokk: Exhaust Vents
    {
        event = "SPELL_CAST_SUCCESS",
        value = 445541,
        show = false,
        entries = {
            {60 * 18 + 53.4, 6},
            {60 * 19 + 21.3, 6},
        }
    },

    -- Brokk: Molten Metal
    {
        event = "SPELL_CAST_START",
        value = 430097,
        color = {109/255, 45/255, 237/255},
        show = true,
        entries = {
            {60 * 18 + 48.5, 3},
            {60 * 19 +  7.9, 3},
            {60 * 19 + 24.9, 3},
        }
    },
}

for _, eventInfo in ipairs(events) do
    for _, entryInfo in ipairs(eventInfo.entries) do
        entryInfo[1] = entryInfo[1] - startTime
    end
end

for _, eventInfo in ipairs(repeated) do
    for _, entryInfo in ipairs(eventInfo.entries) do
        entryInfo[1] = entryInfo[1] - startTime
    end
end

for i = 1, repeatCount do
    for _, repeatEventInfo in ipairs(repeated) do
        for _, eventInfo in ipairs(events) do
            if repeatEventInfo.event == eventInfo.event and repeatEventInfo.value== eventInfo.value then
                local toAdd = CopyTable(repeatEventInfo.entries)

                for _, entryInfo in ipairs(toAdd) do
                    entryInfo[1] = entryInfo[1] + (i - 1) * repeatInterval
                end

                tAppendAll(eventInfo.entries, toAdd)

                break
            end
        end
    end

    table.insert(
        phases,
        {
            event = "SPELL_CAST_SUCCESS",
            value = 428508, -- Blazing Crescendo
            count = i,
            name = string.format("Rotation %d", i),
            shortName = string.format("R%d", i),
        }
    )
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end