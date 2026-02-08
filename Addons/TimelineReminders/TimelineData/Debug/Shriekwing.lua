local _, LRP = ...

if LRP.gs.debug then
    local instanceType = 1
    local instance = 2
    local encounter = 1

    local heroic = {
        phases = {},
        events = {}
    }

    local mythic = {
        phases = {
            {
                event = "SPELL_CAST_START",
                value = 328857,
                count = 1,
                name = "Phase 2",
                shortName = "P2"
            },
            {
                event = "SPELL_CAST_START",
                value = 328857,
                count = 2,
                name = "Phase 2",
                shortName = "P2"
            },
            {
                event = "SPELL_CAST_START",
                value = 328857,
                count = 3,
                name = "Phase 2",
                shortName = "P2"
            },
            {
                event = "SPELL_CAST_START",
                value = 328857,
                count = 4,
                name = "Phase 2",
                shortName = "P2"
            },
        },
        
        events = {
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
