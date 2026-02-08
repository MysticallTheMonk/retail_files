local _, LRP = ...

if LRP.timelineData[1][2] then
    local instanceType = 1
    local instance = 2
    local encounter = 7

    local heroic = {
        warning = "Mug'Zee heroic PTR testing was extremely buggy/overtuned. Heroic timeline will be released when we see the boss on live.",
        phases = {},

        events = {
        }
    }
    
    local mug = {
        -- Mug Taking Charge
        {
            event = "SPELL_CAST_SUCCESS",
            value = 468728,
            show = false,
            entries = {
                {60 * 0 + 57.8},
            }
        },

        -- Head Honcho: Mug
        {
            event = "SPELL_AURA_APPLIED",
            value = 466459,
            show = false,
            entries = {
                {60 * 0 + 57.8},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 466459,
            show = false,
            entries = {
                {60 * 1 + 57.8},
            }
        },

        -- Elemental Carnage
        {
            event = "SPELL_CAST_SUCCESS",
            value = 468658,
            show = false,
            entries = {
                {60 * 0 + 57.9},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 468658,
            color = {46/255, 240/255, 143/255},
            show = true,
            entries = {
                {60 * 0 + 57.8, 6},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 468658,
            show = false,
            entries = {
                {60 * 1 +  3.8},
            }
        },

        -- Earthshaker Gaol
        {
            event = "SPELL_CAST_SUCCESS",
            value = 472631,
            color = {201/255, 151/255, 50/255},
            show = true,
            entries = {
                {60 * 1 + 11.8, 6},
            }
        },
        {
            event = "SPELL_CAST_START",
            value = 474461,
            show = false,
            entries = {
                {60 * 1 + 15.3, 2.5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 474461,
            show = false,
            entries = {
                {60 * 1 + 17.8},
            }
        },

        -- Frostshatter Boots
        {
            event = "SPELL_CAST_START",
            value = 466470,
            show = false,
            entries = {
                {60 * 1 + 32.6, 2},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 466470,
            show = false,
            entries = {
                {60 * 0 + 34.6},
            }
        },
        { -- Actual cast event has no tooltip
            value = 466476,
            color = {110/255, 225/255, 240/255},
            show = true,
            entries = {
                {60 * 1 + 32.6, 2},
            }
        },
        
        -- Stormfury Finger Gun
        {
            event = "SPELL_CAST_START",
            value = 466509,
            show = false,
            entries = {
                {60 * 1 + 47.9, 3},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 466509,
            color = {56/255, 99/255, 242/255},
            show = true,
            entries = {
                {60 * 1 + 50.9, 4},
            }
        },

        -- Molten Gold Knuckles
        {
            event = "SPELL_CAST_START",
            value = 466518,
            color = {247/255, 234/255, 92/255},
            show = true,
            entries = {
                {60 * 1 + 25.6, 2.5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 466518,
            show = false,
            entries = {
                {60 * 1 + 28.1},
            }
        },
    }

    local zee = {
        -- Zee Taking Charge
        {
            event = "SPELL_CAST_SUCCESS",
            value = 468794,
            show = false,
            entries = {
                {60 * 0 +  0.0},
            }
        },

        -- Head Honcho: Zee
        {
            event = "SPELL_AURA_APPLIED",
            value = 466460,
            show = false,
            entries = {
                {60 * 0 +  0.0},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 466460,
            show = false,
            entries = {
                {60 * 1 +  0.0},
            }
        },

        -- Uncontrolled Destruction
        {
            event = "SPELL_CAST_SUCCESS",
            value = 468694,
            show = false,
            entries = {
                {60 * 0 +  0.1},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 468694,
            color = {237/255, 26/255, 75/255},
            show = true,
            entries = {
                {60 * 0 +  0.1, 6},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 468694,
            show = false,
            entries = {
                {60 * 0 +  6.1},
            }
        },

        -- Unstable Crawler Mines
        {
            event = "SPELL_CAST_START",
            value = 472458,
            show = false,
            entries = {
                {60 * 0 + 13.9, 1.5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 472458,
            show = false,
            entries = {
                {60 * 0 + 15.4},
            }
        },
        { -- The actual cast doesn't have a tooltip
            value = 466539,
            color = {108/255, 117/255, 108/255},
            show = true,
            entries = {
                {60 * 0 + 13.9, 4},
            }
        },

        -- Goblin-guided Rocket
        {
            event = "SPELL_CAST_START",
            value = 467379,
            show = false,
            entries = {
                {60 * 0 + 27.9, 2},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 467379,
            show = false,
            entries = {
                {60 * 0 + 29.9},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 467380,
            color = {242/255, 210/255, 65/255},
            show = true,
            entries = {
                {60 * 0 + 29.9, 8},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 467380,
            show = false,
            entries = {
                {60 * 0 + 37.9},
            }
        },

        -- Spray and Pray
        {
            event = "SPELL_CAST_START",
            value = 466545,
            show = false,
            entries = {
                {60 * 0 + 50.0, 3.5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 466545,
            color = {148/255, 39/255, 22/255},
            show = true,
            entries = {
                {60 * 0 + 53.5, 3},
            }
        },

        -- Double Whammy Shot
        {
            event = "SPELL_CAST_START",
            value = 1223085,
            color = {245/255, 80/255, 20/255},
            show = true,
            entries = {
                {60 * 0 + 44.9, 2.5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 1223085,
            show = false,
            entries = {
                {60 * 0 + 47.4},
            }
        },
    }

    local mythic = {
        phases = {
            {
                event = "SPELL_AURA_APPLIED",
                value = 466459, -- Head Honcho: Mug
                count = 1,
                name = "Mug 1",
                shortName = "Mug 1"
            }
        },

        events = {
            
        }
    }

    -- Subtract Mug start time from all the Mug events
    -- Add 60 seconds, since that is when we want to start Mug side
    local mugStart = mug[1].entries[1][1]

    for _, eventInfo in ipairs(mug) do
        for _, entry in ipairs(eventInfo.entries) do
            entry[1] = entry[1] - mugStart + 60
        end
    end

    tAppendAll(mythic.events, mug)
    tAppendAll(mythic.events, zee)

    local repeatCount = 2
    local interval = 120

    for i = 1, repeatCount do
        table.insert(
            mythic.phases,
            {
                event = "SPELL_AURA_APPLIED",
                value = 466460, -- Head Honcho: Zee
                count = i + 1,
                name = string.format("Zee %d", i + 1),
                shortName = string.format("Zee %d", i + 1)
            }
        )

        table.insert(
            mythic.phases,
            {
                event = "SPELL_AURA_APPLIED",
                value = 466459, -- Head Honcho: Mug
                count = i + 1,
                name = string.format("Mug %d", i + 1),
                shortName = string.format("Mug %d", i + 1)
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

    LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
    LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic
end