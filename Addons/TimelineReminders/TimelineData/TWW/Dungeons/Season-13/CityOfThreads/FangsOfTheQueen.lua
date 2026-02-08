local _, LRP = ...

local instanceType = 2
local instance = 2
local encounter = 2

local phases = {}

local events = {
    -- Synergetic Step (Nx)
    {
        event = "SPELL_CAST_START",
        value = 441381,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 441381,
        color = {28/255, 181/255, 252/255},
        show = true,
        entries = {}
    },

    -- Synergetic Step (Vx)
    {
        event = "SPELL_CAST_START",
        value = 441384,
        show = false,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 441384,
        show = false,
        entries = {}
    },

    -- Shade Slash (Nx)
    {
        event = "SPELL_CAST_START",
        value = 439621,
        color = {139/255, 0/255, 219/255},
        show = true,
        entries = {
            {60 * 13 + 28.7, 3},
            {60 * 13 + 38.1, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439621,
        show = false,
        entries = {
            {60 * 13 + 31.7},
            {60 * 13 + 41.1},
        }
    },

    -- Duksbringer (Nx)
    {
        event = "SPELL_CAST_START",
        value = 439692,
        show = false,
        entries = {
            {60 * 13 + 44.0, 1.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439692,
        color = {219/255, 0/255, 212/255},
        show = true,
        entries = {
            {60 * 13 + 45.5, 3.5},
        }
    },

    -- Ice Sickles (Vx)
    {
        event = "SPELL_CAST_START",
        value = 440218,
        color = {122/255, 237/255, 245/255},
        show = true,
        entries = {
            {60 * 13 + 45.5, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 440218,
        show = false,
        entries = {
            {60 * 13 + 49.5, 4},
        }
    },

    -- Rime Dagger (Vx)
    {
        event = "SPELL_CAST_START",
        value = 440468,
        color = {38/255, 122/255, 212/255},
        show = true,
        entries = {}
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 440468,
        show = false,
        entries = {}
    },
}

local startTime = 60 * 13 + 24.6
local repeatInterval = 60 * 1 + 35
local repeatCount = 4
local repeated = {
    -- Synergetic Step (Nx)
    {
        event = "SPELL_CAST_START",
        value = 441381,
        show = false,
        entries = {
            {60 * 13 + 52.3, 2.5},
            {60 * 14 + 39.5, 2.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 441381,
        color = {28/255, 181/255, 252/255},
        show = true,
        entries = {
            {60 * 13 + 54.8, 6},
            {60 * 14 + 42.0, 6},
        }
    },

    -- Synergetic Step (Vx)
    {
        event = "SPELL_CAST_START",
        value = 441384,
        show = false,
        entries = {
            {60 * 13 + 52.3, 2.5},
            {60 * 14 + 39.5, 2.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 441384,
        show = false,
        entries = {
            {60 * 13 + 54.8},
            {60 * 14 + 42.0},
        }
    },

    -- Shade Slash (Nx)
    {
        event = "SPELL_CAST_START",
        value = 439621,
        color = {139/255, 0/255, 219/255},
        show = true,
        entries = {
            {60 * 15 +  3.5, 3},
            {60 * 15 + 13.0, 3},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439621,
        show = false,
        entries = {
            {60 * 15 +  6.5},
            {60 * 15 + 16.0},
        }
    },

    -- Duksbringer (Nx)
    {
        event = "SPELL_CAST_START",
        value = 439692,
        show = false,
        entries = {
            {60 * 14 + 28.3, 1.5},
            {60 * 15 + 18.8, 1.5},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 439692,
        color = {219/255, 0/255, 212/255},
        show = true,
        entries = {
            {60 * 14 + 29.8, 3.5},
            {60 * 15 + 20.3, 3.5},
        }
    },

    -- Ice Sickles (Vx)
    {
        event = "SPELL_CAST_START",
        value = 440218,
        color = {122/255, 237/255, 245/255},
        show = true,
        entries = {
            {60 * 15 + 20.3, 4},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 440218,
        show = false,
        entries = {
            {60 * 15 + 24.3},
        }
    },

    -- Rime Dagger (Vx)
    {
        event = "SPELL_CAST_START",
        value = 440468,
        color = {38/255, 122/255, 212/255},
        show = true,
        entries = {
            {60 * 14 + 17.4, 2},
            {60 * 14 + 26.8, 2},
        }
    },
    {
        event = "SPELL_CAST_SUCCESS",
        value = 440468,
        show = false,
        entries = {
            {60 * 14 + 19.4},
            {60 * 14 + 28.8},
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
            value = 441381, -- Synergetix Step (Nx)
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