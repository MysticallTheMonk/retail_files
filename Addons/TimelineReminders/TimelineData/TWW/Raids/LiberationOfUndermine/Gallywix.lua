local _, LRP = ...

if LRP.timelineData[1][2] then
    local instanceType = 1
    local instance = 2
    local encounter = 8

    local heroic = {
        phases = {},

        events = {
        }
    }

    local mythic = {
        phases = {},

        events = {
            {
                event = "SPELL_CAST_SUCCESS",
                value = 352295,
                color = {242/255, 22/255, 70/255},
                show = true,
                entries = {
                    {0, 5},
                    {595, 5}
                }
            },
        }
    }

    LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
    LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic
end