local _, LRP = ...

local instanceType = 2
local instance = 5
local encounter = 2

local phases = {}

local events = {
    -- Consumption
    {
        event = "SPELL_CAST_SUCCESS",
        value = 322450,
        color = {252/255, 130/255, 15/255},
        show = true,
        entries = {
        }
    },

    -- Coalescing Poison
    {
        event = "SPELL_CAST_START",
        value = 463602,
        show = false,
        entries = {
            {60 * 48 + 48.2, 2},
            {60 * 49 + 23.3, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 463602,
        show = false,
        entries = {
            {60 * 48 + 50.2},
            {60 * 49 + 25.3},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 463602,
        color = {212/255, 227/255, 73/255},
        show = true,
        entries = {
            {60 * 48 + 55.2, 5},
            {60 * 49 + 30.3, 5},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 463602,
        show = false,
        entries = {
            {60 * 49 +  0.2},
            {60 * 49 + 35.3},
        }
    },

    -- Mind Link
    {
        event = "SPELL_CAST_START",
        value = 322614,
        color = {109/255, 176/255, 242/255},
        show = true,
        entries = {
            {60 * 48 + 45.2, 2},
            {60 * 49 + 20.3, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 322614,
        show = false,
        entries = {
            {60 * 48 + 47.2},
            {60 * 49 + 22.3},
        }
    },

    -- Accelerated Incubation
    {
        event = "SPELL_CAST_START",
        value = 322550,
        color = {240/255, 84/255, 125/255},
        show = true,
        entries = {
            {60 * 48 + 33.2, 2},
            {60 * 49 +  8.3, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 322550,
        show = false,
        entries = {
            {60 * 48 + 35.2},
            {60 * 49 + 10.3},
        }
    },

    -- Acid Expulsion
    {
        event = "SPELL_CAST_SUCCESS",
        value = 322654,
        color = {31/255, 224/255, 86/255},
        show = true,
        entries = {
            {60 * 48 + 29.2, 3},
            {60 * 49 +  4.2, 3},
            {60 * 49 + 39.2, 3},
        }
    },
}

local startTime = 60 * 48 + 22.2
local repeatInterval = 60 * 1 + 44.4
local repeatCount = 3
local repeated = {
    -- Consumption
    {
        event = "SPELL_CAST_SUCCESS",
        value = 322450,
        color = {252/255, 130/255, 15/255},
        show = true,
        entries = {
            {60 * 49 + 43.4, 10},
        }
    },

    -- Coalescing Poison
    {
        event = "SPELL_CAST_START",
        value = 463602,
        show = false,
        entries = {
            {60 * 50 + 20.0, 2},
            {60 * 50 + 55.0, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 463602,
        show = false,
        entries = {
            {60 * 50 + 22.0},
            {60 * 50 + 57.0},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 463602,
        color = {212/255, 227/255, 73/255},
        show = true,
        entries = {
            {60 * 50 + 22.0, 5},
            {60 * 50 + 57.0, 5},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 463602,
        show = false,
        entries = {
            {60 * 50 + 27.0},
            {60 * 51 +  2.0},
        }
    },

    -- Mind Link
    {
        event = "SPELL_CAST_START",
        value = 322614,
        color = {109/255, 176/255, 242/255},
        show = true,
        entries = {
            {60 * 50 + 17.0, 2},
            {60 * 50 + 52.0, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 322614,
        show = false,
        entries = {
            {60 * 50 + 19.0, 2},
            {60 * 50 + 54.0, 2},
        }
    },

    -- Accelerated Incubation
    {
        event = "SPELL_CAST_START",
        value = 322550,
        color = {240/255, 84/255, 125/255},
        show = true,
        entries = {
            {60 * 50 +  5.0, 2},
            {60 * 50 + 40.0, 2},
            {60 * 51 + 15.0, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 322550,
        show = false,
        entries = {
            {60 * 50 +  7.0, 2},
            {60 * 50 + 42.0, 2},
            {60 * 51 + 17.0, 2},
        }
    },

    -- Acid Expulsion
    {
        event = "SPELL_CAST_SUCCESS",
        value = 322654,
        color = {31/255, 224/255, 86/255},
        show = true,
        entries = {
            {60 * 50 +  1.0, 3},
            {60 * 50 + 36.0, 3},
            {60 * 51 + 11.0, 3},
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
            value = 322450, -- Consumption
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