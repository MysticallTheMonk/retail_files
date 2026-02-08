local _, LRP = ...

local instanceType = 2
local instance = 2
local encounter = 1

local phases = {}

local events = {
    -- Shadows of Doubt
    {
        event = "SPELL_CAST_START",
        value = 448560,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448560,
        color = {181/255, 64/255, 227/255},
        show = true,
        entries = {}
    },

    -- Vociferous Indoctrination
    {
        event = "SPELL_CAST_START",
        value = 434829,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434829,
        color = {112/255, 40/255, 237/255},
        show = true,
        entries = {}
    },

    -- Terrorize
    {
        event = "SPELL_CAST_START",
        value = 434779,
        color = {230/255, 44/255, 211/255},
        show = true,
        entries = {
            {60 *  2 + 42.9, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434779,
        show = false,
        entries = {
            {60 *  2 + 45.9},
        }
    },

    -- Subjugate
    {
        event = "SPELL_CAST_START",
        value = 434722,
        color = {64/255, 230/255, 221/255},
        show = true,
        entries = {
            {60 *  2 + 36.8, 1.25},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434722,
        show = false,
        entries = {
            {60 *  2 + 38.1},
        }
    },
}

local startTime = 60 * 2 + 32.8
local repeatInterval = 32
local repeatCount = 10
local repeated = {
    -- Shadows of Doubt
    {
        event = "SPELL_CAST_START",
        value = 448560,
        show = false,
        entries = {
            {60 *  2 + 47.0, 1},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448560,
        color = {185/255, 230/255, 80/255},
        show = true,
        entries = {
            {60 *  2 + 48.0, 6},
        }
    },

    -- Vociferous Indoctrination
    {
        event = "SPELL_CAST_START",
        value = 434829,
        show = false,
        entries = {
            {60 *  2 + 58.6, 1},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434829,
        color = {185/255, 230/255, 80/255},
        show = true,
        entries = {
            {60 *  2 + 59.6, 4},
        }
    },

    -- Terrorize
    {
        event = "SPELL_CAST_START",
        value = 434779,
        color = {185/255, 230/255, 80/255},
        show = true,
        entries = {
            {60 *  2 + 51.4, 3},
            {60 *  3 + 14.4, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434779,
        show = false,
        entries = {
            {60 *  2 + 54.4, 3},
            {60 *  3 + 17.4, 3},
        }
    },

    -- Subjugate
    {
        event = "SPELL_CAST_START",
        value = 434722,
        color = {185/255, 230/255, 80/255},
        show = true,
        entries = {
            {60 *  2 + 56.2, 1.25},
            {60 *  3 +  9.6, 1.25},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 434722,
        show = false,
        entries = {
            {60 *  2 + 57.5, 1.25},
            {60 *  3 + 10.9, 1.25},
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
            value = 448560, -- Shadow of Doubt
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