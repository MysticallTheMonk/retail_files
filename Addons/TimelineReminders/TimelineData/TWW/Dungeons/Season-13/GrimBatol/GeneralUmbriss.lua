local _, LRP = ...

local instanceType = 2
local instance = 8
local encounter = 1

local phases = {}

local events = {
    -- Commanding Roar
    {
        event = "SPELL_CAST_START",
        value = 448847,
        color = {240/255, 76/255, 22/255},
        show = true,
        entries = {
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448847,
        show = false,
        entries = {
        }
    },

    -- Rock Spikes
    {
        event = "SPELL_CAST_START",
        value = 448877,
        color = {181/255, 148/255, 78/255},
        show = true,
        entries = {
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448877,
        show = false,
        entries = {
        }
    },

    -- Skullsplitter
    {
        event = "SPELL_CAST_START",
        value = 447261,
        color = {60/255, 163/255, 114/255},
        show = true,
        entries = {
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 447261,
        show = false,
        entries = {
        }
    },
}

local startTime = 60 * 4 + 53.8
local repeatInterval = 25
local repeatCount = 12
local repeated = {
    -- Commanding Roar
    {
        event = "SPELL_CAST_START",
        value = 448847,
        color = {240/255, 76/255, 22/255},
        show = true,
        entries = {
            {60 * 4 + 59.8, 3}
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448847,
        show = false,
        entries = {
            {60 * 5 +  2.8}
        }
    },

    -- Rock Spikes
    {
        event = "SPELL_CAST_START",
        value = 448877,
        color = {181/255, 148/255, 78/255},
        show = true,
        entries = {
            {60 * 5 +  9.8, 4}
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448877,
        show = false,
        entries = {
            {60 * 5 + 13.8}
        }
    },

    -- Skullsplitter
    {
        event = "SPELL_CAST_START",
        value = 447261,
        color = {60/255, 163/255, 114/255},
        show = true,
        entries = {
            {60 * 5 + 17.8, 1}
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 447261,
        show = false,
        entries = {
            {60 * 5 + 18.8}
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
            value = 448847, -- Commanding Roar
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