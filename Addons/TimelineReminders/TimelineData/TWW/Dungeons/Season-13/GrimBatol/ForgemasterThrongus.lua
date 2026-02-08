local _, LRP = ...

local instanceType = 2
local instance = 8
local encounter = 2

local phases = {}

local events = {
    -- Fiery Cleave
    {
        event = "SPELL_CAST_START",
        value = 447395,
        color = {250/255, 20/255, 85/255},
        show = true,
        entries = {
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 447395,
        show = false,
        entries = {
        }
    },

    -- Molten Mace
    {
        event = "SPELL_AURA_APPLIED",
        value = 449687,
        color = {235/255, 225/255, 40/255},
        show = true,
        entries = {
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 449687,
        show = false,
        entries = {
        }
    },

    -- Forge Mace
    {
        event = "SPELL_AURA_APPLIED",
        value = 456900,
        color = {230/255, 152/255, 44/255},
        show = true,
        entries = {
        }
    },

    -- Forge Swords
    {
        event = "SPELL_AURA_APPLIED",
        value = 456902,
        color = {230/255, 152/255, 44/255},
        show = true,
        entries = {
        }
    },

    -- Forge Axe
    {
        event = "SPELL_AURA_APPLIED",
        value = 451996,
        color = {230/255, 152/255, 44/255},
        show = true,
        entries = {
        }
    },

    -- Molten Flurry
    {
        event = "SPELL_CAST_START",
        value = 449444,
        color = {156/255, 128/255, 89/255},
        show = true,
        entries = {
        }
    },
}

local startTime = 60 * 10 + 37.7
local repeatInterval = 61
local repeatCount = 5
local repeated = {
    -- Fiery Cleave
    {
        event = "SPELL_CAST_START",
        value = 447395,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 10 + 57.0, 3}
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 447395,
        show = false,
        entries = {
            {60 * 11 +  0.0}
        }
    },

    -- Molten Mace
    {
        event = "SPELL_AURA_APPLIED",
        value = 449687,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 11 + 36.5, 10}
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 449687,
        show = false,
        entries = {
            {60 * 11 + 46.5}
        }
    },

    -- Forge Mace
    {
        event = "SPELL_AURA_APPLIED",
        value = 456900,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 11 + 26.5, 4}
        }
    },

    -- Forge Swords
    {
        event = "SPELL_AURA_APPLIED",
        value = 456902,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 11 +  6.6, 4}
        }
    },

    -- Forge Axe
    {
        event = "SPELL_AURA_APPLIED",
        value = 451996,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 10 + 47.4, 4}
        }
    },

    -- Molten Flurry
    {
        event = "SPELL_CAST_START",
        value = 449444,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 11 + 17.0, 2.5}
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
            event = "SPELL_AURA_APPLIED",
            value = 451996, -- Molten Mace
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