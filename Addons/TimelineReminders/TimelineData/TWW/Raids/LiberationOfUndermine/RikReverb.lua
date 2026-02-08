local _, LRP = ...

if LRP.timelineData[1][2] then
    local instanceType = 1
    local instance = 2
    local encounter = 3

    local heroic = {
        phases = {},

        events = {
        }
    }

    local mythic = {
        phases = {},

        events = {
            -- Amplification!
            {
                event = "SPELL_CAST_START",
                value = 473748,
                color = {107/255, 114/255, 117/255},
                show = true,
                entries = {
                    {60 * 0 + 10.8, 3.3},
                    {60 * 0 + 48.7, 3.3},
                    {60 * 1 + 29.1, 3.3},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 473748,
                show = false,
                entries = {
                    {60 * 0 + 14.1},
                    {60 * 0 + 52.0},
                    {60 * 1 + 32.4},
                }
            },

            -- Echoing Chant
            {
                event = "SPELL_CAST_START",
                value = 466866,
                color = {247/255, 177/255, 72/255},
                show = true,
                entries = {
                    {60 * 0 + 22.0, 3.5},
                    {60 * 1 + 19.5, 3.5},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 466866,
                show = false,
                entries = {
                    {60 * 0 + 25.5, 3.5},
                    {60 * 1 + 23.0, 3.5},
                }
            },

            -- Sound Cannon
            {
                event = "SPELL_CAST_START",
                value = 467606,
                color = {131/255, 105/255, 201/255},
                show = true,
                entries = {
                    {60 * 0 + 30.0, 5},
                    {60 * 1 +  7.0, 5},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 467606,
                show = false,
                entries = {
                    {60 * 0 + 35.0},
                    {60 * 1 + 12.0},
                }
            },

            -- Faulty Zap
            {
                event = "SPELL_CAST_START",
                value = 466979,
                color = {94/255, 191/255, 247/255},
                show = true,
                entries = {
                    {60 * 0 + 38.0, 2.1},
                    {60 * 1 + 15.0, 2.1},
                    {60 * 1 + 39.0, 2.1},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 466979,
                show = false,
                entries = {
                    {60 * 0 + 40.1},
                    {60 * 1 + 17.1},
                    {60 * 1 + 41.1},
                }
            },

            -- Grand Finale
            {
                event = "SPELL_CAST_SUCCESS",
                value = 472293,
                color = {245/255, 68/255, 37/255},
                show = true,
                entries = {
                    {60 * 0 + 23.1, 15},
                    {60 * 1 +  6.3, 15},
                    {60 * 1 + 47.5, 15},
                }
            },

            -- Blaring Drop
            {
                event = "SPELL_CAST_START",
                value = 473260,
                color = {62/255, 79/255, 237/255},
                show = true,
                entries = {
                    {60 * 2 +  1.3, 5},
                    {60 * 2 +  8.3, 5},
                    {60 * 2 + 15.2, 5},
                    {60 * 2 + 22.2, 5},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 473260,
                show = false,
                entries = {
                    {60 * 2 +  6.3},
                    {60 * 2 + 13.3},
                    {60 * 2 + 20.2},
                    {60 * 2 + 27.2},
                }
            },

            -- Sound Cloud
            {
                event = "SPELL_CAST_START",
                value = 464584,
                show = false,
                entries = {
                    {60 * 1 + 56.0, 5},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 464584,
                show = false,
                entries = {
                    {60 * 2 +  1.0},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 464584,
                color = {194/255, 245/255, 83/255},
                show = true,
                entries = {
                    {60 * 2 +  1.0, 28},
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 464584,
                show = false,
                entries = {
                    {60 * 2 + 29.0},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 1213817,
                show = false,
                entries = {
                    {60 * 2 +  1.0, 28},
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 1213817,
                show = false,
                entries = {
                    {60 * 2 + 29.0},
                }
            },
        }
    }

    local repeatCount = 3
    local interval = 60 * 2 + 29
    
    for i = 1, repeatCount do
        table.insert(
            mythic.phases,
            {
                event = "SPELL_AURA_REMOVED",
                value = 464584, -- Sound Cloud
                count = i,
                name = string.format("Phase 1 (%d)", i + 1),
                shortName = string.format("P1 (%d)", i + 1)
            }
        )
    end

    for _, eventInfo in ipairs(mythic.events) do
        local entries = eventInfo.entries
        local entryCount = entries and #entries or 0

        for i = 1, repeatCount do
            for j = 1, entryCount do
                local entry = entries[j]
                
                table.insert(
                    entries,
                    {entry[1] + i * interval, entry[2]}
                )
            end
        end
    end

    heroic = mythic -- Heroic and mythic timers look to be the same

    LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
    LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic
end