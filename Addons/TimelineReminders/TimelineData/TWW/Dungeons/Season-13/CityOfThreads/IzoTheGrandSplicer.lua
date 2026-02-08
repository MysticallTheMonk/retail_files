local _, LRP = ...

local instanceType = 2
local instance = 2
local encounter = 4

local phases = {}

local events = {
    -- Umbral Weave
    {
        event = "SPELL_CAST_START",
        value = 438860,
        color = {169/255, 59/255, 247/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 438860,
        show = false,
        entries = {}
    },

    -- Tremor Slam
    {
        event = "SPELL_CAST_START",
        value = 437700,
        color = {242/255, 185/255, 85/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 437700,
        show = false,
        entries = {}
    },

    -- Shifting Anomalies
    {
        event = "SPELL_CAST_START",
        value = 439401,
        color = {38/255, 49/255, 255/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439401,
        show = false,
        entries = {}
    },

    -- Splice
    {
        event = "SPELL_CAST_START",
        value = 439341,
        color = {247/255, 59/255, 241/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439341,
        show = false,
        entries = {}
    },

    -- Process of Elimination
    {
        event = "SPELL_CAST_START",
        value = 439646,
        color = {55/255, 182/255, 250/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439646,
        show = false,
        entries = {}
    },
}

local startTime = 60 * 26 + 55.0
local repeatInterval = 60
local repeatCount = 6
local repeated = {
    -- Umbral Weave
    {
        event = "SPELL_CAST_START",
        value = 438860,
        color = {169/255, 59/255, 247/255},
        show = true,
        entries = {
            {60 * 27 + 11.1, 4.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 438860,
        show = false,
        entries = {
            {60 * 27 + 15.6},
        }
    },

    -- Tremor Slam
    {
        event = "SPELL_CAST_START",
        value = 437700,
        color = {242/255, 185/255, 85/255},
        show = true,
        entries = {
            {60 * 27 + 33.1, 4.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 437700,
        show = false,
        entries = {
            {60 * 27 + 37.6},
        }
    },

    -- Shifting Anomalies
    {
        event = "SPELL_CAST_START",
        value = 439401,
        color = {38/255, 49/255, 255/255},
        show = true,
        entries = {
            {60 * 26 + 59.1, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439401,
        show = false,
        entries = {
            {60 * 27 +  1.1},
        }
    },

    -- Splice
    {
        event = "SPELL_CAST_START",
        value = 439341,
        color = {247/255, 59/255, 241/255},
        show = true,
        entries = {
            {60 * 27 +  5.1, 1.5},
            {60 * 27 + 27.1, 1.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439341,
        show = false,
        entries = {
            {60 * 27 +  6.6},
            {60 * 27 + 28.6},
        }
    },

    -- Process of Elimination
    {
        event = "SPELL_CAST_START",
        value = 439646,
        color = {55/255, 182/255, 250/255},
        show = true,
        entries = {
            {60 * 27 + 50.1, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439646,
        show = false,
        entries = {
            {60 * 27 + 52.1},
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
            value = 439401, -- Shifting Anomalies
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