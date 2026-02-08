local _, LRP = ...

local instanceType = 2
local instance = 4
local encounter = 1

local phases = {}

local events = {
    -- Earth Shatterer
    {
        event = "SPELL_CAST_START",
        value = 424879,
        color = {250/255, 87/255, 201/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424879,
        show = false,
        entries = {}
    },

    -- Volatile Spike
    {
        event = "SPELL_CAST_START",
        value = 424903,
        color = {217/255, 180/255, 72/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424903,
        show = false,
        entries = {}
    },

    -- Refracting Beam
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424795,
        color = {242/255, 36/255, 60/255},
        show = true,
        entries = {}
    },

    -- Seismic Smash
    {
        event = "SPELL_CAST_START",
        value = 424888,
        color = {245/255, 158/255, 27/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424888,
        show = false,
        entries = {}
    },
}

local startTime = 60 * 4 + 2.5
local repeatInterval = 48
local repeatCount = 8
local repeated = {
    -- Earth Shatterer
    {
        event = "SPELL_CAST_START",
        value = 424879,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 *  4 + 45.5, 5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424879,
        show = false,
        entries = {
            {60 *  4 + 49.5},
        }
    },

    -- Volatile Spike
    {
        event = "SPELL_CAST_START",
        value = 424903,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 *  4 +  8.5, 2.5},
            {60 *  4 + 28.5, 2.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424903,
        show = false,
        entries = {
            {60 *  4 + 11.0},
            {60 *  4 + 31.0},
        }
    },

    -- Refracting Beam
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424795,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 *  4 + 16.5, 9},
            {60 *  4 + 36.5, 9},
        }
    },

    -- Seismic Smash
    {
        event = "SPELL_CAST_START",
        value = 424888,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 *  4 + 20.5, 4},
            {60 *  4 + 40.5, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 424888,
        show = false,
        entries = {
            {60 *  4 + 20, 4},
            {60 *  4 + 44, 4},
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
            value = 424903, -- Volatile Spike
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