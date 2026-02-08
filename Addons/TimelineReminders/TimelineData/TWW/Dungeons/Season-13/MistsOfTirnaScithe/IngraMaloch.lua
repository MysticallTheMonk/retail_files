local _, LRP = ...

local instanceType = 2
local instance = 5
local encounter = 1

local phases = {}

local events = {
    -- Soul Shackle
    {
        event = "SPELL_CAST_SUCCESS",
        value = 321005,
        show = false,
        entries = {
            {60 * 11 + 53.7},
        }
    },

    -- Droman's Wrath
    {
        event = "SPELL_CAST_START",
        value = 323059,
        show = false,
        entries = {
            {60 * 11 + 35.0, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 323059,
        show = false,
        entries = {
            {60 * 11 + 37.0},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 323059,
        color = {197/255, 235/255, 75/255},
        show = true,
        entries = {
            {60 * 11 + 37.0, 15},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 323059,
        show = false,
        entries = {
            {60 * 11 + 52.0},
        }
    },

    -- Ingra Maloch: Embrace Darkness
    {
        event = "SPELL_CAST_START",
        value = 323149,
        show = false,
        entries = {
            {60 * 10 + 41.5, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 323149,
        show = false,
        entries = {
            {60 * 10 + 45.5},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 323149,
        color = {250/255, 30/255, 235/255},
        show = true,
        entries = {
            {60 * 10 + 45.5, 34.4},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 323149,
        show = false,
        entries = {
            {60 * 11 + 19.9},
        }
    },

    -- Ingra Maloch: Repulsive Visage
    {
        event = "SPELL_CAST_START",
        value = 328756,
        show = false,
        entries = {
            {60 * 10 + 37.9, 3},
            {60 * 11 + 19.4, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 328756,
        color = {124/255, 218/255, 247/255},
        show = true,
        entries = {
            {60 * 10 + 40.9, 3},
            {60 * 11 + 22.4, 3},
        }
    },

    -- Droman Oulfarran: Bewildering Pollen
    {
        event = "SPELL_CAST_START",
        value = 323137,
        color = {160/255, 73/255, 227/255},
        show = true,
        entries = {
            {60 * 10 + 13.6, 3.5},
            {60 * 10 + 33.0, 3.5},
            {60 * 10 + 59.7, 3.5},
            {60 * 11 + 24.0, 3.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 323137,
        show = false,
        entries = {
            {60 * 10 + 17.1},
            {60 * 10 + 36.5},
            {60 * 11 +  3.2},
            {60 * 11 + 27.5},
        }
    },

    -- Droman Oulfarran: Tears of the Forest
    {
        event = "SPELL_CAST_SUCCESS",
        value = 323177,
        show = false,
        entries = {
            {60 * 10 + 22.9},
            {60 * 10 + 49.9},
            {60 * 11 + 13.0},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 323177,
        color = {121/255, 217/255, 193/255},
        show = true,
        entries = {
            {60 * 10 + 22.9, 6.3},
            {60 * 10 + 49.9, 6.3},
            {60 * 11 + 13.0, 6.3},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 323177,
        show = false,
        entries = {
            {60 * 10 + 29.2},
            {60 * 10 + 56.2},
            {60 * 11 + 19.2},
        }
    },
}

local startTime = 60 * 10 + 6.4
local repeatInterval = 110.4
local repeatCount = 3
local repeated = {
    -- Soul Shackle
    {
        event = "SPELL_CAST_SUCCESS",
        value = 321005,
        show = false,
        entries = {
            {60 * 11 + 53.7},
        }
    },

    -- Droman's Wrath
    {
        event = "SPELL_CAST_START",
        value = 323059,
        show = false,
        entries = {
            {60 * 11 + 35.0, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 323059,
        show = false,
        entries = {
            {60 * 11 + 37.0},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 323059,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 11 + 37.0, 15},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 323059,
        show = false,
        entries = {
            {60 * 11 + 52.0},
        }
    },

    -- Ingra Maloch: Embrace Darkness
    {
        event = "SPELL_CAST_START",
        value = 323149,
        show = false,
        entries = {
            {60 * 10 + 41.5, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 323149,
        show = false,
        entries = {
            {60 * 10 + 45.5},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 323149,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 10 + 45.5, 34.4},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 323149,
        show = false,
        entries = {
            {60 * 11 + 19.9},
        }
    },

    -- Ingra Maloch: Repulsive Visage
    {
        event = "SPELL_CAST_START",
        value = 328756,
        show = false,
        entries = {
            {60 * 10 + 37.9, 3},
            {60 * 11 + 19.4, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 328756,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 10 + 40.9, 3},
            {60 * 11 + 22.4, 3},
        }
    },

    -- Droman Oulfarran: Bewildering Pollen
    {
        event = "SPELL_CAST_START",
        value = 323137,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 10 + 13.6, 3.5},
            {60 * 10 + 33.0, 3.5},
            {60 * 10 + 59.7, 3.5},
            {60 * 11 + 24.0, 3.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 323137,
        show = false,
        entries = {
            {60 * 10 + 17.1},
            {60 * 10 + 36.5},
            {60 * 11 +  3.2},
            {60 * 11 + 27.5},
        }
    },

    -- Droman Oulfarran: Tears of the Forest
    {
        event = "SPELL_CAST_SUCCESS",
        value = 323177,
        show = false,
        entries = {
            {60 * 10 + 22.9},
            {60 * 10 + 49.9},
            {60 * 11 + 13.0},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 323177,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 10 + 22.9, 6.3},
            {60 * 10 + 49.9, 6.3},
            {60 * 11 + 13.0, 6.3},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 323177,
        show = false,
        entries = {
            {60 * 10 + 29.2},
            {60 * 10 + 56.2},
            {60 * 11 + 19.2},
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
        entryInfo[1] = entryInfo[1] - startTime + 110.4
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
            value = 321005, -- Soul Shackle
            count = i,
            name = string.format("Rotation %d", i + 1),
            shortName = string.format("R%d", i + 1),
        }
    )
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end