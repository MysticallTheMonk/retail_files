local _, LRP = ...

if LRP.timelineData[1][2] then
    local instanceType = 1
    local instance = 2
    local encounter = 5

    local heroic = {
        phases = {
            {
                event = "SPELL_CAST_START",
                value = 466765, -- Beta Launch
                count = 1,
                name = "Phase 2 (1)",
                shortName = "P2 (1)"
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 1218318, -- Bleeding Edge
                count = 1,
                name = "Phase 1 (2)",
                shortName = "P1 (2)"
            },
            {
                event = "SPELL_CAST_START",
                value = 466765, -- Beta Launch
                count = 2,
                name = "Phase 2 (2)",
                shortName = "P2 (2)"
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 1218318, -- Bleeding Edge
                count = 2,
                name = "Phase 1 (3)",
                shortName = "P1 (3)"
            },
        },

        -- Events in first P1
        phase1 = {
            -- Activate Inventions!
            {
                event = "SPELL_CAST_START",
                value = 473276,
                color = {196/255, 134/255, 247/255},
                show = true,
                entries = {
                    {60 * 0 + 30.1, 2},
                    {60 * 1 +  0.1, 2},
                    {60 * 1 + 30.1, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 473276,
                show = false,
                entries = {
                    {60 * 0 + 31.1},
                    {60 * 1 +  1.1},
                    {60 * 1 + 31.1},
                }
            },

            -- Foot-Blasters
            {
                event = "SPELL_CAST_START",
                value = 1217231,
                color = {252/255, 80/255, 18/255},
                show = true,
                entries = {
                    {60 * 0 + 12.0, 1.5},
                    {60 * 1 + 14.0, 1.5},
                    {60 * 1 + 45.0, 1.5},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1217231,
                show = false,
                entries = {
                    {60 * 0 + 13.5},
                    {60 * 1 + 15.5},
                    {60 * 1 + 46.5},
                }
            },

            -- Wire Transfer
            {
                event = "SPELL_CAST_START",
                value = 1218418,
                color = {113/255, 212/255, 235/255},
                show = true,
                entries = {
                    {60 * 0 +  0.0, 2},
                    {60 * 0 + 41.0, 2},
                    {60 * 1 +  9.0, 2},
                    {60 * 1 + 37.0, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1218418,
                show = false,
                entries = {
                    {60 * 0 +  2.0},
                    {60 * 0 + 43.0},
                    {60 * 1 + 11.0},
                    {60 * 1 + 39.0},
                }
            },

            -- Screw Up
            {
                event = "SPELL_CAST_START",
                value = 1216508,
                show = false,
                entries = {
                    {60 * 0 + 47.0},
                    {60 * 1 + 20.0},
                    {60 * 1 + 52.0},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1216508,
                color = {240/255, 180/255, 29/255},
                show = true,
                entries = {
                    {60 * 0 + 49.0, 4.5},
                    {60 * 1 + 22.0, 4.5},
                    {60 * 1 + 54.0, 4.5},
                }
            },

            -- Sonic Ba-Boom
            {
                event = "SPELL_CAST_START",
                value = 465232,
                show = false,
                entries = {
                    {60 * 0 +  6.0, 2},
                    {60 * 0 + 34.0, 2},
                    {60 * 1 +  3.0, 2},
                    {60 * 1 + 33.0, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465232,
                color = {111/255, 130/255, 191/255},
                show = true,
                entries = {
                    {60 * 0 +  8.0, 10},
                    {60 * 0 + 36.0, 10},
                    {60 * 1 +  5.0, 10},
                    {60 * 1 + 35.0, 10},
                }
            },

            -- Pyro Party Pack
            {
                event = "SPELL_CAST_START",
                value = 465232,
                show = false,
                entries = {
                    {60 * 0 + 20.0, 1.5},
                    {60 * 0 + 54.0, 1.5},
                    {60 * 1 + 24.0, 1.5},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465232,
                show = false,
                entries = {
                    {60 * 0 + 21.5},
                    {60 * 0 + 55.5},
                    {60 * 1 + 25.5},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 1214878,
                color = {73/255, 227/255, 155/255},
                show = true,
                entries = {
                    {60 * 0 + 21.5, 6},
                    {60 * 0 + 55.5, 6},
                    {60 * 1 + 25.5, 6},
                }
            },
        },

        -- Events in first P2
        phase2 = {
            -- Beta Launch
            {
                event = "SPELL_CAST_START",
                value = 466765,
                color = {160/255, 43/255, 227/255},
                show = true,
                entries = {
                    {60 * 2 +  1.3, 4},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 466765,
                show = false,
                entries = {
                    {60 * 2 +  5.3},
                }
            },

            -- Bleeding Edge
            {
                event = "SPELL_CAST_SUCCESS",
                value = 466860,
                show = false,
                entries = {
                    {60 * 2 +  5.4},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 1218318,
                show = false,
                entries = {
                    {60 * 2 +  6.1},
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 1218318,
                show = false,
                entries = {
                    {60 * 2 +  25.4},
                }
            },
            { -- Buff doesn't have an icon/tooltip
                value = 466860,
                color = {240/255, 36/255, 226/255},
                show = true,
                entries = {
                    {60 * 2 +  6.1, 19.3},
                }
            },
        },

        events = {
        }
    }

    -- Combine heroic timers
    do
        local interval = 145 -- Time between first Wire Transfer on pull, and first Wire Transfer after first P2

        -- Repeat phase 1
        for _, eventInfo in ipairs(heroic.phase1) do
            local entries = eventInfo.entries
            local entryCount = entries and #entries or 0

            for i = 1, 2 do -- Phase 1 repeats 3 times
                for j = 1, entryCount do
                    local entry = entries[j]
                    
                    table.insert(
                        entries,
                        {entry[1] + i * interval, entry[2]}
                    )
                end
            end
        end

        -- Repeat phase 2
        for _, eventInfo in ipairs(heroic.phase2) do
            local entries = eventInfo.entries
            local entryCount = entries and #entries or 0

            -- Phase 2 repeats twice
            for j = 1, entryCount do
                local entry = entries[j]
                
                table.insert(
                    entries,
                    {entry[1] + interval, entry[2]}
                )
            end
        end

        tAppendAll(heroic.events, heroic.phase1)
        tAppendAll(heroic.events, heroic.phase2)

        -- Add Gigadeath
        tAppendAll(
            heroic.events,
            {
                -- Gigadeath
                {
                    event = "SPELL_CAST_START",
                    value = 468791,
                    color = {245/255, 29/255, 55/255},
                    show = true,
                    entries = {
                        {60 * 6 + 50.5, 4},
                    }
                },
                {
                    event = "SPELL_CAST_SUCCESS",
                    value = 468791,
                    show = false,
                    entries = {
                        {60 * 6 + 54.5},
                    }
                },
            }
        )
    end

    local mythic = {
        phases = {
            {
                event = "SPELL_CAST_START",
                value = 466765, -- Beta Launch
                count = 1,
                name = "Phase 2 (1)",
                shortName = "P2 (1)"
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 1218318, -- Bleeding Edge
                count = 1,
                name = "Phase 1 (2)",
                shortName = "P1 (2)"
            },
            {
                event = "SPELL_CAST_START",
                value = 466765, -- Beta Launch
                count = 2,
                name = "Phase 2 (2)",
                shortName = "P2 (2)"
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 1218318, -- Bleeding Edge
                count = 2,
                name = "Phase 1 (3)",
                shortName = "P1 (3)"
            },
        },

        phase1 = {
            -- Activate Inventions!
            {
                event = "SPELL_CAST_START",
                value = 473276,
                color = {196/255, 134/255, 247/255},
                show = true,
                entries = {
                    {60 * 0 + 30.1, 2},
                    {60 * 1 +  0.1, 2},
                    {60 * 1 + 30.1, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 473276,
                show = false,
                entries = {
                    {60 * 0 + 31.1},
                    {60 * 1 +  1.1},
                    {60 * 1 + 31.1},
                }
            },

            -- Polarization Generator
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1216802,
                color = {185/255, 255/255, 250/255},
                show = true,
                entries = {
                    {60 * 0 +  4.1, 4},
                    {60 * 1 + 11.0, 4},
                    {60 * 1 + 57.0, 4},
                }
            },

            -- Foot-Blasters
            {
                event = "SPELL_CAST_START",
                value = 1217231,
                color = {252/255, 80/255, 18/255},
                show = true,
                entries = {
                    {60 * 0 + 12.1, 1.5},
                    {60 * 0 + 45.1, 1.5},
                    {60 * 1 + 15.2, 1.5},
                    {60 * 1 + 45.1, 1.5},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1217231,
                show = false,
                entries = {
                    {60 * 0 + 13.6},
                    {60 * 0 + 46.6},
                    {60 * 1 + 16.7},
                    {60 * 1 + 46.6},
                }
            },

            -- Wire Transfer
            {
                event = "SPELL_CAST_START",
                value = 1218418,
                color = {113/255, 212/255, 235/255},
                show = true,
                entries = {
                    {60 * 0 +  0.1, 2},
                    {60 * 0 + 41.1, 2},
                    {60 * 1 + 41.1, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1218418,
                show = false,
                entries = {
                    {60 * 0 +  2.1},
                    {60 * 0 + 43.1},
                    {60 * 1 + 43.1},
                }
            },

            -- Screw Up
            {
                event = "SPELL_CAST_START",
                value = 1216508,
                show = false,
                entries = {
                    {60 * 0 + 18.2},
                    {60 * 0 + 48.0},
                    {60 * 1 + 20.0},
                    {60 * 1 + 47.1},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1216508,
                color = {240/255, 180/255, 29/255},
                show = true,
                entries = {
                    {60 * 0 + 20.2, 4.5},
                    {60 * 0 + 50.0, 4.5},
                    {60 * 1 + 22.0, 4.5},
                    {60 * 1 + 49.1, 4.5},
                }
            },

            -- Sonic Ba-Boom
            {
                event = "SPELL_CAST_START",
                value = 465232,
                show = false,
                entries = {
                    {60 * 0 +  9.1, 2},
                    {60 * 0 + 34.1, 2},
                    {60 * 1 +  1.1, 2},
                    {60 * 1 + 33.0, 2},
                    {60 * 1 + 51.1, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465232,
                color = {111/255, 130/255, 191/255},
                show = true,
                entries = {
                    {60 * 0 + 11.1, 10},
                    {60 * 0 + 36.1, 10},
                    {60 * 1 +  3.1, 10},
                    {60 * 1 + 35.0, 10},
                    {60 * 1 + 53.1, 10},
                }
            },

            -- Pyro Party Pack
            {
                event = "SPELL_CAST_START",
                value = 465232,
                show = false,
                entries = {
                    {60 * 0 + 23.1, 1.5},
                    {60 * 0 + 56.1, 1.5},
                    {60 * 1 + 26.0, 1.5},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465232,
                show = false,
                entries = {
                    {60 * 0 + 24.6},
                    {60 * 0 + 57.6},
                    {60 * 1 + 27.5},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 1214878,
                color = {73/255, 227/255, 155/255},
                show = true,
                entries = {
                    {60 * 0 + 24.7, 6},
                    {60 * 0 + 57.7, 6},
                    {60 * 1 + 27.7, 6},
                }
            },
        },

        phase2 = {
            -- Beta Launch
            {
                event = "SPELL_CAST_START",
                value = 466765,
                color = {160/255, 43/255, 227/255},
                show = true,
                entries = {
                    {60 * 2 +  1.3, 4},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 466765,
                show = false,
                entries = {
                    {60 * 2 +  5.3},
                }
            },

            -- Bleeding Edge
            {
                event = "SPELL_CAST_SUCCESS",
                value = 466860,
                show = false,
                entries = {
                    {60 * 2 +  5.4},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 1218318,
                show = false,
                entries = {
                    {60 * 2 +  6.1},
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 1218318,
                show = false,
                entries = {
                    {60 * 2 +  25.4},
                }
            },
            { -- Buff doesn't have an icon/tooltip
                value = 466860,
                color = {240/255, 36/255, 226/255},
                show = true,
                entries = {
                    {60 * 2 +  6.1, 19.3},
                }
            },
        },

        events = {
        }
    }

    -- Combine mythic timers
    do
        local interval = 145

        -- Repeat phase 1
        for _, eventInfo in ipairs(mythic.phase1) do
            local entries = eventInfo.entries
            local entryCount = entries and #entries or 0

            for i = 1, 2 do -- Phase 1 repeats 3 times
                for j = 1, entryCount do
                    local entry = entries[j]
                    
                    table.insert(
                        entries,
                        {entry[1] + i * interval, entry[2]}
                    )
                end
            end
        end

        -- Repeat phase 2
        for _, eventInfo in ipairs(mythic.phase2) do
            local entries = eventInfo.entries
            local entryCount = entries and #entries or 0

            -- Phase 2 repeats twice
            for j = 1, entryCount do
                local entry = entries[j]
                
                table.insert(
                    entries,
                    {entry[1] + interval, entry[2]}
                )
            end
        end

        tAppendAll(mythic.events, mythic.phase1)
        tAppendAll(mythic.events, mythic.phase2)

        -- Add Gigadeath
        tAppendAll(
            mythic.events,
            {
                -- Gigadeath
                {
                    event = "SPELL_CAST_START",
                    value = 468791,
                    color = {245/255, 29/255, 55/255},
                    show = true,
                    entries = {
                        {60 * 6 + 50.5, 4},
                    }
                },
                {
                    event = "SPELL_CAST_SUCCESS",
                    value = 468791,
                    show = false,
                    entries = {
                        {60 * 6 + 54.5},
                    }
                },
            }
        )
    end

    LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
    LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic
end