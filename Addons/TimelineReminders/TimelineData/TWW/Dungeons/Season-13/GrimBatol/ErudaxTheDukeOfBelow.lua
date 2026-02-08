local _, LRP = ...

local instanceType = 2
local instance = 8
local encounter = 4

local phases = {}

local events = {
    -- Shadow Gale
    {
        event = "SPELL_CAST_SUCCESS",
        value = 449939,
        color = {240/255, 34/255, 82/255},
        show = true,
        entries = {
        }
    },

    -- Abyssal Corruption
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448057,
        color = {181/255, 31/255, 222/255},
        show = true,
        entries = {
        }
    },

    -- Void Infusion
    {
        event = "SPELL_AURA_APPLIED",
        value = 450088,
        color = {245/255, 59/255, 226/255},
        show = true,
        entries = {
        }
    },

    -- Void Surge
    {
        event = "SPELL_CAST_SUCCESS",
        value = 450077,
        color = {84/255, 59/255, 245/255},
        show = true,
        entries = {
        }
    },

    -- Crush
    {
        event = "SPELL_CAST_START",
        value = 450100,
        color = {173/255, 131/255, 81/255},
        show = true,
        entries = {
        }
    },
}

local startTime = 60 * 48 + 25.5
local repeatInterval = 50
local repeatCount = 6
local repeated = {
    -- Shadow Gale
    {
        event = "SPELL_CAST_SUCCESS",
        value = 449939,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 48 + 40.6, 15}
        }
    },

    -- Abyssal Corruption
    {
        event = "SPELL_CAST_SUCCESS",
        value = 448057,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 48 + 57.6, 8}
        }
    },

    -- Void Infusion
    {
        event = "SPELL_AURA_APPLIED",
        value = 450088,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 49 +  4.6, 10}
        }
    },

    -- Void Surge
    {
        event = "SPELL_CAST_SUCCESS",
        value = 450077,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 48 + 32.6, 3}
        }
    },

    -- Crush
    {
        event = "SPELL_CAST_START",
        value = 450100,
        color = {179/255, 38/255, 255/255},
        show = true,
        entries = {
            {60 * 49 + 10.6, 1.5}
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
            value = 450077, -- Void Surge
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