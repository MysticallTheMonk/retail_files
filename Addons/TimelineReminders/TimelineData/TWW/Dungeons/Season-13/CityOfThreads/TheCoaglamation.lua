local _, LRP = ...

local instanceType = 2
local instance = 2
local encounter = 3

local phases = {}

local events = {
    -- Blood Surge
    {
        event = "SPELL_CAST_START",
        value = 461880,
        color = {171/255, 118/255, 222/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 461880,
        show = false,
        entries = {}
    },

    -- Dark Pulse
    {
        event = "SPELL_CAST_START",
        value = 441395,
        color = {102/255, 24/255, 245/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 441395,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 441395,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 441395,
        show = false,
        entries = {}
    },

    -- Viscous Darkness (combine both spell IDs)
    {
        event = "SPELL_CAST_START",
        value = 441289,
        color = {217/255, 50/255, 92/255},
        show = true,
        entries = {
            {60 * 21 + 53.4, 3.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 441289,
        show = false,
        entries = {
            {60 * 21 + 56.9},
        }
    },

    -- Oozing Smash
    {
        event = "SPELL_CAST_START",
        value = 461842,
        color = {242/255, 29/255, 203/255},
        show = true,
        entries = {
            {60 * 21 + 47.3, 1.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 461842,
        show = false,
        entries = {
            {60 * 21 + 48.8},
        }
    },
}

local startTime = 60 * 21 + 43.4
local repeatInterval = 60 * 1 + 12
local repeatCount = 5
local repeated = {
    -- Blood Surge
    {
        event = "SPELL_CAST_START",
        value = 461880,
        color = {171/255, 118/255, 222/255},
        show = true,
        entries = {
            {60 * 22 +  3.1, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 461880,
        show = false,
        entries = {
            {60 * 22 +  6.1},
        }
    },

    -- Dark Pulse
    {
        event = "SPELL_CAST_START",
        value = 441395,
        show = false,
        entries = {
            {60 * 22 + 31.1, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 441395,
        show = false,
        entries = {
            {60 * 22 + 34.1, 3},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 441395,
        color = {102/255, 24/255, 245/255},
        show = true,
        entries = {
            {60 * 22 + 34.1, 6},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 441395,
        show = false,
        entries = {
            {60 * 22 + 40.1},
        }
    },

    -- Viscous Darkness (combine both spell IDs)
    {
        event = "SPELL_CAST_START",
        value = 441289,
        color = {217/255, 50/255, 92/255},
        show = true,
        entries = {
            {60 * 22 + 16.5, 3.5},
            {60 * 22 + 49.4, 3.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 441289,
        show = false,
        entries = {
            {60 * 22 + 20.0, 3.5},
            {60 * 22 + 52.9, 3.5},
        }
    },

    -- Oozing Smash (combine both spell IDs)
    {
        event = "SPELL_CAST_START",
        value = 461842,
        color = {235/255, 30/255, 94/255},
        show = true,
        entries = {
            {60 * 22 + 42.0, 1.5},
            {60 * 22 + 57.9, 1.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 461842,
        show = false,
        entries = {
            {60 * 22 + 43.5},
            {60 * 22 + 59.4},
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
            value = 461880, -- Blood Surge
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