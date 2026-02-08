local _, LRP = ...

local instanceType = 2
local instance = 6
local encounter = 2

local phases = {}

local events = {
    -- Noxious Fog
    {
        event = "SPELL_AURA_APPLIED",
        value = 326629,
        color = {51/255, 214/255, 149/255},
        show = true,
        entries = {
            {60 * 37 + 42.9, 16.4},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 326629,
        show = false,
        entries = {
            {60 * 37 + 59.3},
        }
    },
    
    -- Awaken Creation
    {
        event = "SPELL_CAST_START",
        value = 320358,
        color = {212/255, 181/255, 152/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 320358,
        show = false,
        entries = {}
    },

    -- Morbid Fixation
    {
        event = "SPELL_CAST_START",
        value = 343556,
        color = {230/255, 44/255, 75/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 343556,
        show = false,
        entries = {}
    },

    -- Embalming Ichor (includes casts while boss is immune)
    {
        event = "SPELL_CAST_START",
        value = 327664,
        color = {139/255, 199/255, 44/255},
        show = true,
        entries = {
            {60 * 37 + 50.2, 1},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 327664,
        show = false,
        entries = {
            {60 * 37 + 51.2},
        }
    },

    -- Sever Flesh
    {
        event = "SPELL_CAST_START",
        value = 334488,
        color = {242/255, 144/255, 46/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 334488,
        show = false,
        entries = {}
    },
}

local startTime = 60 * 37 + 40.3
local repeatInterval = 56
local repeatCount = 4
local repeated = {
    -- Noxious Fog
    {
        event = "SPELL_AURA_APPLIED",
        value = 326629,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 38 + 29.8, 25.5},
        }
    },
    {
        event = "SPELL_AURA_REMOVED",
        value = 326629,
        show = false,
        entries = {
            {60 * 38 + 55.3},
        }
    },
    
    -- Awaken Creation
    {
        event = "SPELL_CAST_START",
        value = 320358,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 38 + 31.0, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 320358,
        show = false,
        entries = {
            {60 * 38 + 33.0},
        }
    },

    -- Morbid Fixation
    {
        event = "SPELL_CAST_START",
        value = 343556,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 38 + 14.4, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 343556,
        show = false,
        entries = {
            {60 * 38 + 16.4},
        }
    },

    -- Embalming Ichor (includes casts while boss is immune)
    {
        event = "SPELL_CAST_START",
        value = 327664,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 38 +  9.5, 2.5},
            {60 * 38 + 21.7, 2.5},
            {60 * 38 + 41.2, 1.0},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 327664,
        show = false,
        entries = {
            {60 * 38 + 12.0},
            {60 * 38 + 24.2},
            {60 * 38 + 42.2},
        }
    },

    -- Sever Flesh
    {
        event = "SPELL_CAST_START",
        value = 334488,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 38 +  5.9, 1},
            {60 * 38 + 17.0, 1},
            {60 * 38 + 26.5, 1},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 334488,
        show = false,
        entries = {
            {60 * 38 +  6.9},
            {60 * 38 + 18.0},
            {60 * 38 + 27.5},
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
            event = "SPELL_AURA_REMOVED",
            value = 326629, -- Noxious Fog
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