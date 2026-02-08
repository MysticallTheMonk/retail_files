local _, LRP = ...

if LRP.timelineData[1][2] then
    local instanceType = 1
    local instance = 2
    local encounter = 4

    local heroic = {
        phases = {},

        -- A single rotation of abilities (these just repeat until the boss enrages/dies)
        -- Use the timestamps of the single rotation that happens before Overdrive
        rotation = {
            -- Electromagnetic Sorting
            {
                event = "SPELL_CAST_START",
                value = 464399,
                show = false,
                entries = {
                    {60 * 0 + 22.3, 1}
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 464399,
                show = false,
                entries = {
                    {60 * 0 + 23.3}
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 464399,
                color = {83/255, 237/255, 188/255},
                show = true,
                entries = {
                    {60 * 0 + 23.3, 5}
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 464399,
                show = false,
                entries = {
                    {60 * 0 + 28.3}
                }
            },

            -- Rolling Rubbish
            {
                value = 461536,
                color = {207/255, 173/255, 116/255},
                show = true,
                entries = {
                    {60 * 0 + 27.8, 20}
                }
            },

            -- Incinerator
            {
                event = "SPELL_CAST_SUCCESS",
                value = 464149,
                color = {252/255, 138/255, 38/255},
                show = true,
                entries = {
                    {60 * 0 + 11.1, 3},
                    {60 * 0 + 36.7, 3},
                }
            },

            -- Demolish
            {
                event = "SPELL_CAST_START",
                value = 464112,
                color = {174/255, 108/255, 245/255},
                show = true,
                entries = {
                    {60 * 0 + 17.8, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 464112,
                show = false,
                entries = {
                    {60 * 0 + 19.0},
                }
            },

            -- Meltdown
            {
                event = "SPELL_CAST_START",
                value = 1217954,
                color = {86/255, 148/255, 125/255},
                show = true,
                entries = {
                    {60 * 0 + 44.4, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1217954,
                show = false,
                entries = {
                    {60 * 0 + 45.4},
                }
            },
        },

        events = {
            -- Overdrive
            {
                event = "SPELL_CAST_START",
                value = 467117,
                show = false,
                entries = {
                    {60 * 1 + 51.1, 1}
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 467117,
                show = false,
                entries = {
                    {60 * 1 + 52.1}
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 467117,
                color = {69/255, 120/255, 247/255},
                show = true,
                entries = {
                    {60 * 1 + 52.2, 9}
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 467117,
                show = false,
                entries = {
                    {60 * 2 + 1.2}
                }
            },
        }
    }

    -- The events in the rotation table are relative to pull
    local startTime = 60 * 2 + 4.9 -- This value is the time that the first rotation starts after Overdrive
    local repeatCount = 6 -- Number of repeats after Overdrive
    local interval = 51.1

    -- Add the rotations after Overdrive
    for _, eventInfo in ipairs(heroic.rotation) do
        local entries = eventInfo.entries
        local entryCount = entries and #entries or 0

        -- Add the rotation before Overdrive
        for j = 1, entryCount do
            local entry = entries[j]
            
            table.insert(
                entries,
                {entry[1] + interval, entry[2]}
            )
        end

        -- Add the rotations after Overdrive
        for i = 1, repeatCount do
            for j = 1, entryCount do
                local entry = entries[j]
                
                table.insert(
                    entries,
                    {startTime + entry[1] + (i - 1) * interval, entry[2]}
                )
            end
        end
    end

    tAppendAll(heroic.events, heroic.rotation)

    local mythic = {
        phases = {
        },

        -- A single rotation of abilities (these just repeat until the boss enrages/dies)
        -- Use the timestamps of the single rotation that happens before Overdrive
        rotation = {
            -- Electromagnetic Sorting
            {
                event = "SPELL_CAST_START",
                value = 464399,
                show = false,
                entries = {
                    {60 * 0 + 22.3, 1}
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 464399,
                show = false,
                entries = {
                    {60 * 0 + 23.3}
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 464399,
                color = {83/255, 237/255, 188/255},
                show = true,
                entries = {
                    {60 * 0 + 23.3, 5}
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 464399,
                show = false,
                entries = {
                    {60 * 0 + 28.3}
                }
            },

            -- Rolling Rubbish
            {
                value = 461536,
                color = {207/255, 173/255, 116/255},
                show = true,
                entries = {
                    {60 * 0 + 27.8, 20}
                }
            },

            -- Incinerator
            {
                event = "SPELL_CAST_SUCCESS",
                value = 464149,
                color = {252/255, 138/255, 38/255},
                show = true,
                entries = {
                    {60 * 0 + 11.1, 3},
                    {60 * 0 + 36.7, 3},
                }
            },

            -- Demolish
            {
                event = "SPELL_CAST_START",
                value = 464112,
                color = {174/255, 108/255, 245/255},
                show = true,
                entries = {
                    {60 * 0 + 17.8, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 464112,
                show = false,
                entries = {
                    {60 * 0 + 19.0},
                }
            },

            -- Meltdown
            {
                event = "SPELL_CAST_START",
                value = 1217954,
                color = {86/255, 148/255, 125/255},
                show = true,
                entries = {
                    {60 * 0 + 44.4, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1217954,
                show = false,
                entries = {
                    {60 * 0 + 45.4},
                }
            },
        },

        events = {
            -- Overdrive
            {
                event = "SPELL_CAST_START",
                value = 467117,
                show = false,
                entries = {
                    {60 * 1 +  6.7, 1}
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 467117,
                show = false,
                entries = {
                    {60 * 1 +  7.7}
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 467117,
                color = {69/255, 120/255, 247/255},
                show = true,
                entries = {
                    {60 * 1 +  7.7, 9}
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 467117,
                show = false,
                entries = {
                    {60 * 1 + 16.7}
                }
            },
        }
    }

    -- The events in the rotation table are relative to pull
    startTime = 60 * 1 + 19 -- This value is the time that the first rotation starts after Overdrive
    repeatCount = 6 -- Number of repeats after Overdrive
    interval = 51.1

    for _, eventInfo in ipairs(mythic.rotation) do
        local entries = eventInfo.entries
        local entryCount = entries and #entries or 0

        for i = 1, repeatCount do
            for j = 1, entryCount do
                local entry = entries[j]
                
                table.insert(
                    entries,
                    {startTime + entry[1] + (i - 1) * interval, entry[2]}
                )
            end
        end
    end

    tAppendAll(mythic.events, mythic.rotation)

    -- Add the extra Incinerator cast just before Electromagnetic Sorting
    for _, eventInfo in ipairs(mythic.events) do
        if eventInfo.event == "SPELL_CAST_SUCCESS" and eventInfo.value == 464149 then -- Incinerator
            table.insert(eventInfo.entries, {60 * 1 + 2.2, 3})

            break
        end
    end

    LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
    LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic
end