local _, LRP = ...

local instanceType = 2
local instance = 8
local encounter = 3

local phases = {
    {
        event = "SPELL_AURA_APPLIED",
        value = 76303, -- Twilight Protection
        count = 1,
        name = "Phase 2",
        shortName = "P2",
    }
}

local events = {
    -- Twilight Protection
    {
        event = "SPELL_AURA_APPLIED",
        value = 76303,
        show = false,
        entries = {
            {60 * 38 + 8.0},
        }
    },

    -- Curse of Entropy
    {
        event = "SPELL_CAST_START",
        value = 450095,
        color = {232/255, 81/255, 217/255},
        show = true,
        entries = {
            {60 * 37 + 38.3, 2},
            {60 * 37 + 56.3, 2},
        }
    },

    -- Invocation of Shadowflame
    {
        event = "SPELL_CAST_START",
        value = 448013,
        color = {204/255, 20/255, 100/255},
        show = true,
        entries = {
            {60 * 37 + 31.2, 3},
            {60 * 37 + 49.3, 3},
        }
    },

    -- Twilight Buffet
    {
        event = "SPELL_CAST_START",
        value = 456751,
        color = {91/255, 175/255, 212/255},
        show = true,
        entries = {
        }
    },

    -- Devouring Flame
    {
        event = "SPELL_CAST_START",
        value = 448105,
        color = {164/255, 49/255, 222/255},
        show = true,
        entries = {
        }
    },
}

local startTime = 60 * 37 + 23.3
local repeatInterval = 35
local repeatCount = 8
local repeated = {
    -- Curse of Entropy
    {
        event = "SPELL_CAST_START",
        value = 450095,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 38 + 28.0, 2},
        }
    },

    -- Invocation of Shadowflame
    {
        event = "SPELL_CAST_START",
        value = 448013,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 38 + 30.0, 3},
        }
    },

    -- Twilight Buffet
    {
        event = "SPELL_CAST_START",
        value = 456751,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 38 + 41.0, 5},
        }
    },

    -- Devouring Flame
    {
        event = "SPELL_CAST_START",
        value = 448105,
        color = {237/255, 122/255, 14/255},
        show = true,
        entries = {
            {60 * 38 + 51.0, 5},
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
end

if LRP.gs.season == 13 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end