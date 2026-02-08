local _, LRP = ...

local instanceType = 2
local instance = 6
local encounter = 1

local phases = {}

local events = {
    -- Final Harvest
    {
        event = "SPELL_CAST_START",
        value = 321247,
        color = {52/255, 235/255, 152/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 321247,
        show = false,
        entries = {}
    },

    -- Land of the Dead
    {
        event = "SPELL_CAST_SUCCESS",
        value = 321226,
        color = {133/255, 153/255, 144/255},
        show = true,
        entries = {}
    },

    -- Necrotic Breath
    {
        event = "SPELL_CAST_START",
        value = 333488,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 333488,
        color = {29/255, 202/255, 224/255},
        show = true,
        entries = {}
    },

    -- Unholy Frenzy
    {
        event = "SPELL_CAST_SUCCESS",
        value = 320012,
        color = {237/255, 171/255, 222/255},
        show = true,
        entries = {}
    },
}

local startTime = 60 * 12 + 42.7
local repeatInterval = 45
local repeatCount = 8
local repeated = {
    -- Final Harvest
    {
        event = "SPELL_CAST_START",
        value = 321247,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 13 + 22.5, 4}
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 321247,
        show = false,
        entries = {
            {60 * 13 + 26.5}
        }
    },

    -- Land of the Dead
    {
        event = "SPELL_CAST_SUCCESS",
        value = 321226,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 12 + 54.6, 4}
        }
    },

    -- Necrotic Breath
    {
        event = "SPELL_CAST_START",
        value = 333488,
        show = false,
        entries = {
            {60 * 13 + 12.2, 1.5}
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 333488,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 13 + 13.7, 4.5}
        }
    },

    -- Unholy Frenzy
    {
        event = "SPELL_CAST_SUCCESS",
        value = 320012,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 12 + 51.0, 4}
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
            value = 320012, -- Unholy Frenzy
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