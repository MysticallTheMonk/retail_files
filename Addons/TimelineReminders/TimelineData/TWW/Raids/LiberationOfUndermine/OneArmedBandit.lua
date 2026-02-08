local _, LRP = ...

if LRP.timelineData[1][2] then
    local instanceType = 1
    local instance = 2
    local encounter = 6

    local heroic = {
        warning = "This is very much a sample timeline, since timers were inconistent on testing.|n|n" ..
        "The timeline will be updated when we see the fight on live.",

        phases = {
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465309, -- Cheat to Win!
                count = 1,
                name = "Phase 2",
                shortName = "P2"
            },
        },

        events = {
            -- Spin To Win!
            {
                event = "SPELL_CAST_START",
                value = 461060,
                show = false,
                entries = {
                    {60 * 0 + 20.0, 2},
                    {60 * 1 + 23.4, 2},
                    {60 * 2 + 24.9, 2},
                    {60 * 3 + 28.6, 2},
                    {60 * 4 + 31.2, 2},
                    {60 * 5 + 34.9, 2},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 461060,
                show = false,
                entries = {
                    {60 * 0 + 22.0},
                    {60 * 1 + 25.4},
                    {60 * 2 + 26.9},
                    {60 * 3 + 30.6},
                    {60 * 4 + 33.2},
                    {60 * 5 + 36.9},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 461060,
                color = {71/255, 204/255, 171/255},
                show = true,
                entries = {
                    {60 * 0 + 22.0, 30},
                    {60 * 1 + 25.4, 30},
                    {60 * 2 + 26.9, 30},
                    {60 * 3 + 30.6, 30},
                    {60 * 4 + 33.2, 30},
                    {60 * 5 + 36.9, 30},
                }
            },

            -- Pay-Line
            {
                event = "SPELL_CAST_START",
                value = 460181,
                color = {212/255, 148/255, 30/255},
                show = true,
                entries = {
                    {60 * 0 +  4.0, 1},
                    {60 * 0 + 49.3, 1},
                    {60 * 1 + 27.2, 1},
                    {60 * 1 + 59.1, 1},
                    {60 * 2 + 34.7, 1},
                    {60 * 3 +  9.9, 1},
                    {60 * 3 + 42.0, 1},
                    {60 * 4 + 13.9, 1},
                    {60 * 4 + 46.0, 1},
                    {60 * 5 + 28.7, 1},
                    {60 * 6 +  4.0, 1},
                    {60 * 6 + 54.4, 1},
                    {60 * 7 + 25.8, 1},
                    {60 * 7 + 56.2, 1},
                }
            },

            -- Foul Exhaust
            {
                event = "SPELL_CAST_START",
                value = 469993,
                color = {88/255, 29/255, 224/255},
                show = true,
                entries = {
                    {60 * 0 +  9.0, 2},
                    {60 * 0 + 40.8, 2},
                    {60 * 1 + 12.4, 2},
                    {60 * 1 + 44.4, 2},
                    {60 * 2 + 15.1, 2},
                    {60 * 2 + 45.7, 2},
                    {60 * 3 + 16.4, 2},
                    {60 * 3 + 46.9, 2},
                    {60 * 4 + 18.9, 2},
                    {60 * 4 + 50.9, 2},
                    {60 * 5 + 22.6, 2},
                    {60 * 5 + 53.4, 2},
                    {60 * 6 + 24.8, 2},
                    {60 * 6 + 48.3, 2},
                    {60 * 7 + 14.0, 2},
                    {60 * 7 + 44.0, 2},
                }
            },

            -- The Big Hit
            {
                event = "SPELL_CAST_START",
                value = 460472,
                color = {124/255, 119/255, 125/255},
                show = true,
                entries = {
                    {60 * 0 + 15.1, 2.5},
                    {60 * 0 + 34.7, 2.5},
                    {60 * 0 + 55.0, 2.5},
                    {60 * 1 + 18.6, 2.5},
                    {60 * 1 + 38.3, 2.5},
                    {60 * 2 +  5.2, 2.5},
                    {60 * 2 + 28.6, 2.5},
                    {60 * 3 +  4.1, 2.5},
                    {60 * 3 + 23.7, 2.5},
                    {60 * 4 +  7.7, 2.5},
                    {60 * 4 + 26.4, 2.5},
                    {60 * 4 + 57.0, 2.5},
                    {60 * 5 + 16.5, 2.5},
                    {60 * 5 + 36.0, 2.5},
                    {60 * 6 + 10.1, 2.5},
                    {60 * 6 + 30.9, 2.5},
                    {60 * 6 + 59.3, 2.5},
                    {60 * 7 + 20.0, 2.5},
                    {60 * 7 + 35.5, 2.5},
                    {60 * 7 + 50.0, 2.5},
                    {60 * 8 +  4.6, 2.5},
                }
            },

            -- Cheat to Win!
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465309,
                show = false,
                entries = {
                    {60 * 6 + 49.6, 2},
                    {60 * 7 + 15.2, 2},
                    {60 * 7 + 40.3, 2},
                    {60 * 8 +  8.3, 2},
                }
            },

            -- Linked Machines
            {
                event = "SPELL_CAST_START",
                value = 465432,
                color = {75/255, 178/255, 219/255},
                show = true,
                entries = {
                    {60 * 6 + 49.8, 3},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465432,
                show = false,
                entries = {
                    {60 * 6 + 52.8},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 465432,
                show = false,
                entries = {
                    {60 * 6 + 52.8},
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 465432,
                show = false,
                entries = {
                    {60 * 6 + 58.8},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 473195,
                show = false,
                entries = {
                    {60 * 6 + 57.3},
                }
            },

            -- Hot Hot Heat
            {
                event = "SPELL_CAST_START",
                value = 465322,
                color = {245/255, 128/255, 44/255},
                show = true,
                entries = {
                    {60 * 7 + 15.4, 3},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465322,
                show = false,
                entries = {
                    {60 * 7 + 18.4},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 465322,
                show = false,
                entries = {
                    {60 * 7 + 18.4},
                }
            },

            -- Scattered Payout
            {
                event = "SPELL_CAST_START",
                value = 465580,
                color = {217/255, 181/255, 52/255},
                show = true,
                entries = {
                    {60 * 7 + 40.6, 3},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465580,
                show = false,
                entries = {
                    {60 * 7 + 43.6},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 465580,
                show = false,
                entries = {
                    {60 * 7 + 43.6},
                }
            },

            -- Explosive Jackpot
            {
                event = "SPELL_CAST_START",
                value = 465587,
                color = {230/255, 54/255, 34/255},
                show = true,
                entries = {
                    {60 * 8 +  8.6, 10},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465587,
                show = false,
                entries = {
                    {60 * 8 + 18.6},
                }
            },
        }
    }

    local mythic = {
        warning = "Coming soon when we pull the boss!",

        phases = {},

        events = {
        }
    }

    LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
    LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic
end