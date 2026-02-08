local _, LRP = ...

local instanceType = 2
local instance = 4
local encounter = 4

local phases = {}

local events = {
    -- Entropic Reckoning
    {
        event = "SPELL_CAST_START",
        value = 427852,
        color = {245/255, 42/255, 201/255},
        show = true,
        entries = {
            {60 * 37 + 28.7, 5},
            {60 * 37 + 45.7, 5},
            {60 * 38 +  2.7, 5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 427852,
        show = false,
        entries = {
            {60 * 37 + 33.7},
            {60 * 37 + 50.7},
            {60 * 38 +  7.7},
        }
    },

    -- Unbridled Void
    {
        event = "SPELL_CAST_START",
        value = 427869,
        color = {146/255, 33/255, 217/255},
        show = true,
        entries = {
            {60 * 37 +  9.1, 4.5},
            {60 * 37 + 29.8, 4.5},
            {60 * 37 + 50.4, 4.5},
            {60 * 38 + 11.1, 4.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 427869,
        show = false,
        entries = {
            {60 * 37 + 13.6},
            {60 * 37 + 34.3},
            {60 * 37 + 54.9},
            {60 * 38 + 15.6},
        }
    },

    -- Void Corruption
    {
        event = "UNIT_SPELLCAST_START",
        value = 427461,
        color = {27/255, 78/255, 245/255},
        show = true,
        entries = {
            {60 * 37 + 17.7, 3.5},
            {60 * 37 + 46.8, 3.5},
            {60 * 38 + 17.3, 3.5},
        }
    },
    {
        event = "UNIT_SPELLCAST_SUCCEEDED",
        value = 427461,
        show = false,
        entries = {
            {60 * 37 + 21.2},
            {60 * 37 + 50.3},
            {60 * 38 + 20.8},
        }
    },
}

local startTime = 60 * 37 + 1.6
local repeatInterval = 62
local repeatCount = 4
local repeated = {
    -- Entropic Reckoning
    {
        event = "SPELL_CAST_START",
        value = 427852,
        color = {252/255, 69/255, 18/255},
        show = true,
        entries = {
            {60 * 38 + 20.9, 5},
            {60 * 38 + 37.9, 5},
            {60 * 38 + 59.3, 5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 427852,
        show = false,
        entries = {
            {60 * 38 + 25.9},
            {60 * 38 + 42.9},
            {60 * 39 +  4.3},
        }
    },

    -- Unbridled Void
    {
        event = "SPELL_CAST_START",
        value = 427869,
        color = {252/255, 69/255, 18/255},
        show = true,
        entries = {
            {60 * 38 + 31.8, 4.5},
            {60 * 38 + 52.4, 4.5},
            {60 * 39 + 12.7, 4.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 427869,
        show = false,
        entries = {
            {60 * 38 + 36.3, 4.5},
            {60 * 38 + 56.9, 4.5},
            {60 * 39 + 17.2, 4.5},
        }
    },

    -- Void Corruption
    {
        event = "UNIT_SPELLCAST_START",
        value = 427461,
        show = false,
        entries = {
            {60 * 38 + 46.4, 3.5},
            {60 * 39 + 19.2, 3.5},
        }
    },
    {
        event = "UNIT_SPELLCAST_SUCCEEDED",
        value = 427461,
        show = false,
        entries = {
            {60 * 38 + 49.9},
            {60 * 39 + 22.7},
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
            value = 427852, -- Entropic Reckoning
            count = (i - 1) * 3 + 4,
            name = string.format("Rotation %d", i),
            shortName = string.format("R%d", i),
        }
    )
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end