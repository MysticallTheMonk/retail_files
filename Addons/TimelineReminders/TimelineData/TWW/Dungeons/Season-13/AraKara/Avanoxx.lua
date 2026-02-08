local _, LRP = ...

local instanceType = 2
local instance = 1
local encounter = 1

local phases = {}

local events = {
    -- Gossamer Onslaught
    {
        event = "SPELL_CAST_START",
        value = 438473,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 438473,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {}
    },

    -- Alerting Shrill
    {
        event = "SPELL_CAST_START",
        value = 438476,
        show = false,
        entries = {
            {60 * 50 + 49.6, 1.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 438476,
        show = false,
        entries = {
            {60 * 50 + 51.1},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 438494,
        color = {250/255, 236/255, 112/255},
        show = true,
        entries = {
            {60 * 50 + 51.1, 5},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 438494,
        show = false,
        entries = {
            {60 * 50 + 56.1},
        }
    },

    -- Voracious Bite
    {
        event = "SPELL_CAST_START",
        value = 438471,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 50 + 42.3, 3},
            {60 * 50 + 56.9, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 438471,
        show = false,
        entries = {
            {60 * 50 + 44.3},
            {60 * 50 + 58.9},
        }
    },
}

local startTime = 60 * 50 + 38.9
local repeatInterval = 40
local repeatCount = 10
local repeated = {
    -- Gossamer Onslaught
    {
        event = "SPELL_CAST_START",
        value = 438473,
        show = false,
        entries = {
            {60 * 51 +  9.0, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 438473,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 51 + 13.0, 5},
        }
    },

    -- Alerting Shrill
    {
        event = "SPELL_CAST_START",
        value = 438476,
        show = false,
        entries = {
            {60 * 51 + 28.4, 1.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 438476,
        show = false,
        entries = {
            {60 * 51 + 29.9},
        }
    },
    {
        event = "SPELL_AURA_APPLIED",
        value = 438494,
        color = {250/255, 236/255, 112/255},
        show = true,
        entries = {
            {60 * 51 + 29.9, 5},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 438494,
        show = false,
        entries = {
            {60 * 51 + 34.9},
        }
    },

    -- Voracious Bite
    {
        event = "SPELL_CAST_START",
        value = 438471,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 51 + 21.2, 3},
            {60 * 51 + 35.7, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 438471,
        show = false,
        entries = {
            {60 * 51 + 23.2},
            {60 * 51 + 37.7},
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
            value = 438473, -- Gossamer Onslaught
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