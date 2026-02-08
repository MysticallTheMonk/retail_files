local _, LRP = ...

if LRP.gs.debug then
    local instanceType = 2
    local instance = 9
    local encounter = 1

    local heroic = {
        phases = {},
        events = {}
    }

    local mythic = {
        phases = {
            {
                event = "CHAT_MSG_MONSTER_YELL",
                value = "bloodshed begin",
                count = 1,
                name = "Phase 2",
                shortName = "P2"
            },
        },
        
        events = {
            {
                event = "CHAT_MSG_MONSTER_YELL",
                value = "bloodshed begin",
                count = 1,
                entries = {
                    {60 * 0 + 20},
                    {60 * 2 + 20},
                }
            },

            {
                event = "SPELL_CAST_START",
                value = 328857,
                color = {245/255, 49/255, 78/255},
                show = true,
                entries = {
                    {60 * 0 + 10, 2},
                    {60 * 0 + 20, 2},
                    {60 * 0 + 30, 2},
                    {60 * 0 + 40, 2},
                }
            },
        }
    }

    LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
    LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic
end
