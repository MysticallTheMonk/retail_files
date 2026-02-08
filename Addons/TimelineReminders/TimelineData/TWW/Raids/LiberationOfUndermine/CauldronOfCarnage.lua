local _, LRP = ...

if LRP.timelineData[1][2] then
    local instanceType = 1
    local instance = 2
    local encounter = 2

    local heroic = {
        phases = {},

        events = {
        }
    }

    local mythic = {
        phases = {},

        events = {
            -- Colossal Clash (Flarendo)
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465863,
                show = false,
                entries = {
                    {60 * 1 + 14.7},
                    {60 * 2 + 49.7},
                    {60 * 4 + 24.7},
                    {60 * 5 + 59.7},
                }
            },

            -- Colossal Clash (Torq)
            {
                event = "SPELL_CAST_SUCCESS",
                value = 465872,
                show = false,
                entries = {
                    {60 * 1 + 14.7},
                    {60 * 2 + 49.7},
                    {60 * 4 + 24.7},
                    {60 * 5 + 59.7},
                }
            },

            -- Colossal Clash (Flarendo & Torq)
            {
                event = "SPELL_AURA_APPLIED",
                value = 465863,
                color = {247/255, 241/255, 72/255},
                show = true,
                entries = {
                    {60 * 1 + 14.7, 20},
                    {60 * 1 + 14.7, 20},
                    {60 * 2 + 49.7, 20},
                    {60 * 2 + 49.7, 20},
                    {60 * 4 + 24.7, 20},
                    {60 * 4 + 24.7, 20},
                    {60 * 5 + 59.7, 20},
                    {60 * 5 + 59.7, 20},
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 465872,
                show = false,
                entries = {
                    {60 * 1 + 14.7, 20},
                    {60 * 1 + 14.7, 20},
                    {60 * 2 + 49.7, 20},
                    {60 * 2 + 49.7, 20},
                    {60 * 4 + 24.7, 20},
                    {60 * 4 + 24.7, 20},
                    {60 * 5 + 59.7, 20},
                    {60 * 5 + 59.7, 20},
                }
            },

            -- Scrapbomb
            {
                event = "SPELL_CAST_START",
                value = 473650,
                show = false,
                entries = {
                    {60 * 0 +  9.0, 3},
                    {60 * 0 + 33.0, 3},
                    {60 * 0 + 56.0, 3},

                    {60 * 1 + 44.0, 3},
                    {60 * 2 +  8.0, 3},
                    {60 * 2 + 31.0, 3},

                    {60 * 3 + 19.1, 3},
                    {60 * 3 + 43.1, 3},
                    {60 * 4 +  6.0, 3},

                    {60 * 4 + 54.1, 3},
                    {60 * 5 + 18.0, 3},
                    {60 * 5 + 41.0, 3},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 473650,
                show = false,
                entries = {
                    {60 * 0 + 12.0},
                    {60 * 0 + 36.0},
                    {60 * 0 + 59.0},

                    {60 * 1 + 47.0},
                    {60 * 2 + 11.0},
                    {60 * 2 + 34.0},

                    {60 * 3 + 22.1},
                    {60 * 3 + 46.1},
                    {60 * 4 +  9.0},

                    {60 * 4 + 57.1},
                    {60 * 5 + 21.0},
                    {60 * 5 + 44.0},
                }
            },
            {
                value = 473650,
                color = {237/255, 33/255, 67/255},
                show = true,
                entries = { -- Applied 1 second after SPELL_CAST_SUCCESS
                    {60 * 0 + 13.0, 10},
                    {60 * 0 + 37.0, 10},
                    {60 * 1 +  0.0, 10},

                    {60 * 1 + 48.0, 10},
                    {60 * 2 + 12.0, 10},
                    {60 * 2 + 35.0, 10},

                    {60 * 3 + 23.1, 10},
                    {60 * 3 + 47.1, 10},
                    {60 * 4 + 10.0, 10},

                    {60 * 4 + 58.1, 10},
                    {60 * 5 + 22.0, 10},
                    {60 * 5 + 45.0, 10},
                }
            },

            -- Molten Phlegm
            {
                value = 1213690,
                color = {242/255, 105/255, 41/255},
                show = true,
                entries = {
                    {60 * 0 + 24.5, 10},
                    {60 * 0 + 52.0, 10},

                    {60 * 1 + 59.6, 10},
                    {60 * 2 + 27.0, 10},

                    {60 * 3 + 34.6, 10},
                    {60 * 4 +  2.1, 10},

                    {60 * 5 +  9.7, 10},
                    {60 * 5 + 37.2, 10},
                }
            },

            -- Blastburn Cannon
            {
                event = "SPELL_CAST_START",
                value = 472233,
                show = false,
                entries = {
                    {60 * 0 + 15.0, 3.5},
                    {60 * 0 + 39.0, 3.5},
                    {60 * 1 +  2.0, 3.5},

                    {60 * 1 + 50.0, 3.5},
                    {60 * 2 + 14.0, 3.5},
                    {60 * 2 + 37.0, 3.5},

                    {60 * 3 + 25.0, 3.5},
                    {60 * 3 + 49.0, 3.5},
                    {60 * 4 + 12.1, 3.5},

                    {60 * 5 +  0.1, 3.5},
                    {60 * 5 + 24.1, 3.5},
                    {60 * 5 + 47.1, 3.5},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 472233,
                color = {235/255, 49/255, 167/255},
                show = true,
                entries = {
                    {60 * 0 + 18.5, 3},
                    {60 * 0 + 42.5, 3},
                    {60 * 1 +  5.5, 3},

                    {60 * 1 + 53.5, 3},
                    {60 * 2 + 17.5, 3},
                    {60 * 2 + 40.5, 3},

                    {60 * 3 + 28.5, 3},
                    {60 * 3 + 52.5, 3},
                    {60 * 4 + 15.6, 3},

                    {60 * 5 +  3.6, 3},
                    {60 * 5 + 27.6, 3},
                    {60 * 5 + 50.6, 3},
                }
            },

            -- Eruption Stomp
            {
                event = "SPELL_CAST_START",
                value = 1214190,
                color = {191/255, 142/255, 96/255},
                show = true,
                entries = {
                    {60 * 0 + 27.0, 4},
                    {60 * 0 + 51.1, 4},

                    {60 * 2 +  2.0, 4},
                    {60 * 2 + 26.0, 4},

                    {60 * 3 + 37.1, 4},
                    {60 * 4 +  1.1, 4},

                    {60 * 5 + 12.0, 4},
                    {60 * 5 + 36.0, 4},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 1214190,
                show = false,
                entries = {
                    {60 * 0 + 31.0},
                    {60 * 0 + 55.1},

                    {60 * 2 +  6.0},
                    {60 * 2 + 30.0},

                    {60 * 3 + 41.1},
                    {60 * 4 +  5.1},

                    {60 * 5 + 16.0},
                    {60 * 5 + 40.0},
                }
            },

            -- Voltaic Image
            {
                value = 1214009,
                color = {72/255, 98/255, 247/255},
                show = true,
                entries = {
                    {60 * 0 + 30.3, 12},
                    {60 * 2 +  5.3, 12},
                    {60 * 3 + 40.3, 12},
                    {60 * 5 + 15.3, 12},
                }
            },

            -- Thunderdrum Salvo
            {
                event = "SPELL_CAST_SUCCESS",
                value = 463900,
                color = {140/255, 234/255, 237/255},
                show = true,
                entries = {
                    {60 * 0 + 10.0, 8},
                    {60 * 0 + 40.0, 8},

                    {60 * 1 + 45.0, 8},
                    {60 * 2 + 15.0, 8},

                    {60 * 3 + 20.1, 8},
                    {60 * 3 + 50.1, 8},

                    {60 * 4 + 55.1, 8},
                    {60 * 5 + 25.1, 8},
                }
            },

            -- Lightning Bash
            {
                event = "SPELL_CAST_START",
                value = 466178,
                color = {89/255, 201/255, 126/255},
                show = true,
                entries = {
                    {60 * 0 + 21.0, 4},
                    {60 * 0 + 51.0, 4},

                    {60 * 1 + 56.0, 4},
                    {60 * 2 + 26.0, 4},

                    {60 * 3 + 31.0, 4},
                    {60 * 4 +  1.1, 4},

                    {60 * 5 +  6.0, 4},
                    {60 * 5 + 36.1, 4},
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 466178,
                show = false,
                entries = {
                    {60 * 0 + 25.0},
                    {60 * 0 + 55.0},

                    {60 * 2 +  0.0},
                    {60 * 2 + 30.0},

                    {60 * 3 + 35.0},
                    {60 * 4 +  5.1},

                    {60 * 5 + 10.0},
                    {60 * 5 + 40.1},
                }
            },
        }
    }

    heroic = mythic -- Heroic and mythic timers look to be the same

    LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
    LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic
end

