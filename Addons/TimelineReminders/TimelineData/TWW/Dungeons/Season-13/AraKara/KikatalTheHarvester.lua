local _, LRP = ...

local instanceType = 2
local instance = 1
local encounter = 3

local phases = {}

local events = {
    -- Cosmic Singularity
    {
        event = "SPELL_CAST_START",
        value = 432117,
        color = {64/255, 70/255, 255/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 432117,
        show = false,
        entries = {}
    },

    -- Cultivated Poisons
    {
        event = "SPELL_CAST_START",
        value = 461487,
        show = false,
        entries = {
            {3600 * 3 + 60 *  8 +  0.0, 1},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 461487,
        color = {188/255, 255/255, 64/255},
        show = true,
        entries = {
            {3600 * 3 + 60 *  8 +  1.0, 8},
        }
    },

    -- Erupting Webs
    {
        event = "SPELL_CAST_START",
        value = 432130,
        color = {181/255, 64/255, 227/255},
        show = true,
        entries = {
            {3600 * 3 + 60 *  7 + 53.9, 3},
            {3600 * 3 + 60 *  8 + 12.1, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 432130,
        show = false,
        entries = {
            {3600 * 3 + 60 *  7 + 56.9},
            {3600 * 3 + 60 *  8 + 15.1},
        }
    },
}

local startTime = 3600 * 3 + 60 * 7 + 46.9
local repeatInterval = 60 * 1 + 35
local repeatCount = 4
local repeated = {
    -- Cosmic Singularity
    {
        event = "SPELL_CAST_START",
        value = 432117,
        show = false,
        entries = {
            {3600 * 3 + 60 *  8 + 15.8, 7},
            {3600 * 3 + 60 *  9 +  2.0, 7},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 432117,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {3600 * 3 + 60 *  8 + 22.8},
            {3600 * 3 + 60 *  9 +  9.0},
        }
    },

    -- Cultivated Poisons
    {
        event = "SPELL_CAST_START",
        value = 461487,
        show = false,
        entries = {
            {3600 * 3 + 60 *  8 + 29.2, 1},
            {3600 * 3 + 60 *  8 + 52.2, 1},
            {3600 * 3 + 60 *  9 + 15.3, 1},
            {3600 * 3 + 60 *  9 + 37.1, 1},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 461487,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {3600 * 3 + 60 *  8 + 30.2, 8},
            {3600 * 3 + 60 *  8 + 53.2, 8},
            {3600 * 3 + 60 *  9 + 16.3, 8},
            {3600 * 3 + 60 *  9 + 38.1, 8},
        }
    },

    -- Erupting Webs
    {
        event = "SPELL_CAST_START",
        value = 432130,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {3600 * 3 + 60 *  8 + 12.1, 3},
            {3600 * 3 + 60 *  8 + 30.4, 3},
            {3600 * 3 + 60 *  8 + 48.6, 3},
            {3600 * 3 + 60 *  9 +  9.3, 3},
            {3600 * 3 + 60 *  9 + 27.4, 3},
            {3600 * 3 + 60 *  9 + 46.0, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 432130,
        show = false,
        entries = {
            {3600 * 3 + 60 *  8 + 15.1},
            {3600 * 3 + 60 *  8 + 33.4},
            {3600 * 3 + 60 *  8 + 51.6},
            {3600 * 3 + 60 *  9 + 12.3},
            {3600 * 3 + 60 *  9 + 30.4},
            {3600 * 3 + 60 *  9 + 49.0},
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
            value = 432117, -- Cosmic Singularity
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