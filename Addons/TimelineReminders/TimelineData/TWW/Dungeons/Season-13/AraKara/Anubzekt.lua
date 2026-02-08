local _, LRP = ...

local instanceType = 2
local instance = 1
local encounter = 2

local phases = {}

local events = {
    -- Eye of the Storm
    {
        event = "SPELL_CAST_START",
        value = 433766,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 433766,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434408,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 434408,
        color = {230/255, 62/255, 218/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 434408,
        show = false,
        entries = {}
    },
    
    -- Infestation
    {
        event = "SPELL_CAST_SUCCESS",
        value = 433740,
        show = false,
        entries = {
            {3600 + 60 * 27 + 42.7},
            {3600 + 60 * 27 + 53.2},
            {3600 + 60 * 28 +  5.5},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 433740,
        color = {185/255, 230/255, 80/255},
        show = true,
        entries = {
            {3600 + 60 * 27 + 42.7, 5},
            {3600 + 60 * 27 + 53.2, 5},
            {3600 + 60 * 28 +  5.5, 5},
        }
    },

    -- Burrow Charge
    {
        event = "SPELL_CAST_START",
        value = 439506,
        color = {80/255, 165/255, 230/255},
        show = true,
        entries = {
            {3600 + 60 * 27 + 56.9, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439506,
        show = false,
        entries = {
            {3600 + 60 * 28 +  0.9},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 433731,
        show = false,
        entries = {
            {3600 + 60 * 28 +  1.9},
        }
    },

    -- Impale
    {
        event = "SPELL_CAST_START",
        value = 435012,
        color = {252/255, 94/255, 3/255},
        show = true,
        entries = {
            {3600 + 60 * 27 + 48.4, 2.5},
            {3600 + 60 * 28 +  1.9, 2.5},
            {3600 + 60 * 28 +  6.6, 2.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 435012,
        show = false,
        entries = {
            {3600 + 60 * 27 + 50.9},
            {3600 + 60 * 28 +  4.4},
            {3600 + 60 * 28 +  9.1},
        }
    },
}

local startTime = 3600 + 60 * 27 + 42.7
local repeatInterval = 60 * 1 + 20
local repeatCount = 6
local repeated = {
    -- Eye of the Storm
    {
        event = "SPELL_CAST_START",
        value = 433766,
        entries = {
            {3600 + 60 * 28 + 12.7, 7},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 433766,
        entries = {
            {3600 + 60 * 28 + 19.7},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434408,
        entries = {
            {3600 + 60 * 28 + 20.0},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 434408,
        entries = {
            {3600 + 60 * 28 + 20.0, 25},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 434408,
        entries = {
            {3600 + 60 * 28 + 45.0},
        }
    },

    -- Infestation
    {
        event = "SPELL_CAST_SUCCESS",
        value = 433740,
        entries = {
            {3600 + 60 * 28 + 20.0},
            {3600 + 60 * 28 + 28.4},
            {3600 + 60 * 28 + 37.0},
            {3600 + 60 * 28 + 45.4},
            {3600 + 60 * 28 + 56.4},
            {3600 + 60 * 29 +  8.7},
            {3600 + 60 * 29 + 19.4},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 433740,
        entries = {
            {3600 + 60 * 28 + 20.0, 5},
            {3600 + 60 * 28 + 28.4, 5},
            {3600 + 60 * 28 + 37.0, 5},
            {3600 + 60 * 28 + 45.4, 5},
            {3600 + 60 * 28 + 56.4, 5},
            {3600 + 60 * 29 +  8.7, 5},
            {3600 + 60 * 29 + 19.4, 5},
        }
    },

    -- Burrow Charge
    {
        event = "SPELL_CAST_START",
        value = 439506,
        entries = {
            {3600 + 60 * 29 +  0.0, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439506,
        entries = {
            {3600 + 60 * 29 +  4.0},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 433731,
        entries = {
            {3600 + 60 * 29 +  5.1},
        }
    },

    -- Impale
    {
        event = "SPELL_CAST_START",
        value = 435012,
        entries = {
            {3600 + 60 * 28 + 23.6, 2.5},
            {3600 + 60 * 28 + 32.1, 2.5},
            {3600 + 60 * 28 + 40.6, 2.5},
            {3600 + 60 * 28 + 50.3, 2.5},
            {3600 + 60 * 29 +  5.1, 2.5},
            {3600 + 60 * 29 +  8.9, 2.5},
            {3600 + 60 * 29 + 21.9, 2.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 435012,
        entries = {
            {3600 + 60 * 28 + 26.1},
            {3600 + 60 * 28 + 34.6},
            {3600 + 60 * 28 + 43.1},
            {3600 + 60 * 28 + 52.8},
            {3600 + 60 * 29 +  7.6},
            {3600 + 60 * 29 + 11.4},
            {3600 + 60 * 29 + 24.4},
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
            event = "SPELL_CAST_START",
            value = 433766, -- Eye of the Storm
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