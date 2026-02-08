local _, LRP = ...

local instanceType = 2
local instance = 4
local encounter = 2

local phases = {}

local events = {
    -- Fortified Shell
    {
        event = "SPELL_CAST_START",
        value = 424879,
        show = false,
        entries = {
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424879,
        show = false,
        entries = {
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 423228,
        color = {248/255, 125/255, 250/255},
        show = true,
        entries = {
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 423228,
        show = false,
        entries = {
        }
    },

    -- Void Discharge
    {
        event = "SPELL_CAST_START",
        value = 423324,
        show = false,
        entries = {
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 423324,
        show = false,
        entries = {
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 423324,
        color = {132/255, 2/255, 219/255},
        show = true,
        entries = {
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 423324,
        show = false,
        entries = {
        }
    },

    -- Unstable Crash
    {
        event = "SPELL_CAST_START",
        value = 423538,
        color = {109/255, 45/255, 237/255},
        show = true,
        entries = {
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 423538,
        show = false,
        entries = {
        }
    },

    -- Crystalline Smash
    {
        event = "SPELL_CAST_START",
        value = 422233,
        color = {214/255, 155/255, 92/255},
        show = true,
        entries = {
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 422233,
        show = false,
        entries = {
        }
    },
}

local startTime = 3600 + 15.7
local repeatInterval = 55.8
local repeatCount = 8
local repeated = {
    -- Fortified Shell
    {
        event = "SPELL_CAST_START",
        value = 424879,
        show = false,
        entries = {
            {3600 + 60 *  0 + 53.3, 6},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424879,
        show = false,
        entries = {
            {3600 + 60 *  0 + 59.3},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 423228,
        color = {250/255, 87/255, 201/255},
        show = true,
        entries = {
            {3600 + 60 *  0 + 59.3, 9},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 423228,
        show = false,
        entries = {
            {3600 + 60 *  1 +  8.3, 9},
        }
    },

    -- Void Discharge
    {
        event = "SPELL_CAST_START",
        value = 423324,
        show = false,
        entries = {
            {3600 + 60 *  1 + 1.8, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 423324,
        show = false,
        entries = {
            {3600 + 60 *  1 + 3.8},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 423324,
        color = {250/255, 87/255, 201/255},
        show = true,
        entries = {
            {3600 + 60 *  1 + 3.8, 4.6},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 423324,
        show = false,
        entries = {
            {3600 + 60 *  1 + 8.4},
        }
    },

    -- Unstable Crash
    {
        event = "SPELL_CAST_START",
        value = 423538,
        color = {250/255, 87/255, 201/255},
        show = true,
        entries = {
            {3600 + 60 *  0 + 26.6, 3},
            {3600 + 60 *  0 + 46.0, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 423538,
        show = false,
        entries = {
            {3600 + 60 *  0 + 29.6},
            {3600 + 60 *  0 + 49.0},
        }
    },

    -- Crystalline Smash
    {
        event = "SPELL_CAST_START",
        value = 422233,
        color = {250/255, 87/255, 201/255},
        show = true,
        entries = {
            {3600 + 60 *  0 + 20.5, 2},
            {3600 + 60 *  0 + 37.5, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 422233,
        show = false,
        entries = {
            {3600 + 60 *  0 + 22.5},
            {3600 + 60 *  0 + 39.5},
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
            value = 422233, -- Crystalline Smash
            count = (i - 1) * 2 + 1,
            name = string.format("Rotation %d", i),
            shortName = string.format("R%d", i),
        }
    )
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end