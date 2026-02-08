local _, LRP = ...

if LRP.timelineData[1][2] then
    local instanceType = 1
    local instance = 2
    local encounter = 1

    local heroic = {
        phases = {},

        events = {
        }
    }

    local mythic = {
        warning = "The ability timings on PTR were inconsistent at times. The timeline represents the timers that I found to be most common.|n|n" ..
        "If timers change (or become more consistent) on live, the timeline will be updated to reflect them.",

        phases = {
            {
                event = "SPELL_CAST_START",
                value = 460603, -- Mechanical Breakdown
                count = 1,
                name = "Phase 2 (1)",
                shortName = "P2 (1)"
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 460116, -- Tune-Up
                count = 1,
                name = "Phase 1 (2)",
                shortName = "P1 (2)"
            },

            {
                event = "SPELL_CAST_START",
                value = 460603, -- Mechanical Breakdown
                count = 2,
                name = "Phase 2 (2)",
                shortName = "P2 (2)"
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 460116, -- Tune-Up
                count = 2,
                name = "Phase 1 (3)",
                shortName = "P1 (3)"
            },

        },

        events = {
            -- Tune-Up
            {
                event = "SPELL_CAST_SUCCESS",
                value = 460116,
                show = false,
                entries = {
                    {60 * 2 + 10.2},
                    {60 * 5 +  0.3}
                }
            },
            {
                event = "SPELL_AURA_APPLIED",
                value = 460116,
                color = {210/255, 203/255, 214/255},
                show = true,
                entries = {
                    {60 * 2 + 10.2, 38},
                    {60 * 5 +  0.3, 44}
                }
            },
            {
                event = "SPELL_AURA_REMOVED",
                value = 460116,
                show = false,
                entries = {
                    {60 * 2 + 48.2},
                    {60 * 5 + 44.3}
                }
            },

            -- Mechanical Breakdown
            {
                event = "SPELL_CAST_START",
                value = 460603,
                color = {250/255, 200/255, 35/255},
                show = true,
                entries = {
                    {60 * 2 +  5.0, 4},
                    {60 * 4 + 55.6, 4}
                }
            },
            {
                event = "SPELL_CAST_SUCCESS",
                value = 460603,
                show = false,
                entries = {
                    {60 * 2 +  9.0},
                    {60 * 4 + 59.6}
                }
            },

            -- Call Bikers
            {
                event = "SPELL_CAST_START",
                value = 459943,
                color = {113/255, 245/255, 93/255},
                show = true,
                entries = {
                    {60 * 0 + 20.3, 1},
                    {60 * 0 + 48.7, 1},
                    {60 * 1 + 16.7, 1},
                    {60 * 1 + 45.8, 1},

                    {60 * 3 + 12.2, 1},
                    {60 * 3 + 41.3, 1},
                    {60 * 4 + 12.9, 1},
                    {60 * 4 + 42.1, 1},

                    {60 * 6 +  8.3, 1},
                    {60 * 6 + 37.5, 1},
                    {60 * 7 +  8.7, 1},
                    {60 * 7 + 37.9, 1},
                }
            },

            -- Spew Oil
            {
                event = "SPELL_CAST_START",
                value = 459671,
                color = {65/255, 99/255, 87/255},
                show = true,
                entries = {
                    {60 * 0 + 12.2, 5},
                    {60 * 0 + 49.9, 5},
                    {60 * 1 + 27.6, 5},

                    {60 * 3 +  4.9, 5},
                    {60 * 3 + 25.5, 5},
                    {60 * 3 + 46.2, 5},
                    {60 * 4 +  6.8, 5},
                    {60 * 4 + 27.1, 5},
                    {60 * 4 + 48.2, 5},

                    {60 * 6 +  1.1, 5},
                    {60 * 6 + 21.7, 5},
                    {60 * 6 + 42.0, 5},
                    {60 * 7 +  2.7, 5},
                    {60 * 7 + 23.3, 5},
                    {60 * 7 + 44.4, 5},
                }
            },

            -- Incendiary Fire
            {
                event = "SPELL_CAST_START",
                value = 468487,
                color = {255/255, 119/255, 41/255},
                show = true,
                entries = {
                    {60 * 0 + 25.7, 3},
                    {60 * 0 + 58.4, 3},
                    {60 * 1 + 24.0, 3},
                    {60 * 1 + 49.5, 3},

                    {60 * 3 + 21.9, 3},
                    {60 * 3 + 57.1, 3},
                    {60 * 4 + 32.3, 3},

                    {60 * 6 + 18.1, 3},
                    {60 * 6 + 54.2, 3},
                    {60 * 7 + 29.4, 3},
                }
            },

            -- Tank Buster
            {
                event = "SPELL_CAST_START",
                value = 459627,
                color = {245/255, 29/255, 58/255},
                show = true,
                entries = {
                    {60 * 0 +  7.4, 1.5},
                    {60 * 0 + 29.3, 1.5},
                    {60 * 0 + 56.0, 1.5},
                    {60 * 1 + 17.9, 1.5},
                    {60 * 1 + 39.8, 1.5},

                    {60 * 2 + 58.4, 1.5},
                    {60 * 3 + 15.8, 1.5},
                    {60 * 3 + 32.4, 1.5},
                    {60 * 3 + 52.3, 1.5},
                    {60 * 4 + 14.1, 1.5},
                    {60 * 4 + 36.0, 1.5},

                    {60 * 5 + 55.0, 1.5},
                    {60 * 6 + 12.0, 1.5},
                    {60 * 6 + 28.6, 1.5},
                    {60 * 6 + 48.1, 1.5},
                    {60 * 7 + 10.0, 1.5},
                    {60 * 7 + 33.1, 1.5},
                }
            },
        }
    }

    heroic = mythic -- Heroic and mythic timers look to be the same

    LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
    LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic
end