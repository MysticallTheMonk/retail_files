local _, LRP = ...

local instanceType = 1
local instance = 1
local encounter = 2

local heroic = {
    phases = {
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99846, -- Immolation
            count = 1,
            name = "Phase 2",
            shortName = "P2"
        },
    },

    events = {
        -- Immolation
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99846,
            show = false,
            entries = {
                {60 * 4 +  4.3},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 99846,
            color = {43/255, 240/255, 109/255},
            show = true,
            entries = {
                {60 * 4 +  4.3, 25},
            }
        },

        -- Concussive Stomp
        {
            event = "SPELL_CAST_START",
            value = 97282,
            color = {240/255, 79/255, 38/255},
            show = true,
            entries = {
                {60 * 0 + 16.1, 3},
                {60 * 0 + 46.8, 3},
                {60 * 1 + 17.6, 3},
                {60 * 1 + 48.4, 3},
                {60 * 2 + 19.2, 3},
                {60 * 2 + 50.0, 3},
                {60 * 3 + 20.7, 3},
                {60 * 3 + 51.4, 3},

                {60 * 4 + 10.8, 3},
                {60 * 4 + 25.3, 3},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 97282,
            show = false,
            entries = {
                {60 * 0 + 19.1},
                {60 * 0 + 49.8},
                {60 * 1 + 20.6},
                {60 * 1 + 51.4},
                {60 * 2 + 22.2},
                {60 * 2 + 53.0},
                {60 * 3 + 23.7},
                {60 * 3 + 54.4},
                
                {60 * 4 + 13.8},
                {60 * 4 + 28.3},
            }
        },

        -- Heated Volcano
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98493,
            color = {255/255, 233/255, 69/255},
            show = true,
            entries = {
                {60 * 0 + 30.7, 2},
                {60 * 1 + 11.1, 2},
                {60 * 1 + 51.6, 2},
                {60 * 2 + 32.1, 2},
                {60 * 3 + 12.5, 2},
            }
        },

        -- Summon Fragment of Rhyolith
        {
            value = 98136,
            color = {135/255, 145/255, 144/255},
            show = true,
            entries = {
                {60 * 0 + 23.4, 2},
                {60 * 1 +  9.6, 2},
                {60 * 1 + 33.2, 2},
                {60 * 2 + 19.2, 2},
                {60 * 2 + 41.7, 2},
                {60 * 3 + 27.4, 2},
                {60 * 3 + 50.5, 2},
            }
        },

        -- Summon Spark of Rhyolith
        {
            value = 98552,
            color = {138/255, 118/255, 103/255},
            show = true,
            entries = {
                {60 * 0 + 46.5, 2},
                {60 * 1 + 55.9, 2},
                {60 * 3 +  4.8, 2},
            }
        },
	}
}

local mythic = {
    phases = {
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99846, -- Immolation
            count = 1,
            name = "Phase 2",
            shortName = "P2"
        },
    },

    events = {
        -- Immolation
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99846,
            show = false,
            entries = {
                {60 * 5 + 29.3},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 99846,
            color = {43/255, 240/255, 109/255},
            show = true,
            entries = {
                {60 * 5 + 29.3, 44.7},
            }
        },

        -- Concussive Stomp
        {
            event = "SPELL_CAST_START",
            value = 97282,
            color = {240/255, 79/255, 38/255},
            show = true,
            entries = {
                {60 * 0 + 16.1, 3},
                {60 * 0 + 46.6, 3},
                {60 * 1 + 17.2, 3},
                {60 * 1 + 48.0, 3},
                {60 * 2 + 18.8, 3},
                {60 * 2 + 49.5, 3},
                {60 * 3 + 20.3, 3},
                {60 * 3 + 51.1, 3},
                {60 * 4 + 21.9, 3},
                {60 * 4 + 52.6, 3},
                {60 * 5 + 23.4, 3},

                {60 * 5 + 40.7, 3},
                {60 * 5 + 55.3, 3},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 97282,
            show = false,
            entries = {
                {60 * 0 + 19.1, 3},
                {60 * 0 + 49.6, 3},
                {60 * 1 + 20.2, 3},
                {60 * 1 + 51.0, 3},
                {60 * 2 + 21.8, 3},
                {60 * 2 + 52.5, 3},
                {60 * 3 + 23.3, 3},
                {60 * 3 + 54.1, 3},
                {60 * 4 + 24.9, 3},
                {60 * 4 + 55.6, 3},
                {60 * 5 + 26.4, 3},

                {60 * 5 + 43.7, 3},
                {60 * 5 + 58.3, 3},
            }
        },

        -- Heated Volcano
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98493,
            color = {255/255, 233/255, 69/255},
            show = true,
            entries = {
                {60 * 0 + 30.7, 2},
                {60 * 0 + 56.7, 2},
                {60 * 1 + 22.4, 2},
                {60 * 1 + 48.3, 2},
                {60 * 2 + 14.2, 2},
                {60 * 2 + 40.2, 2},
                {60 * 3 +  6.1, 2},
                {60 * 3 + 32.0, 2},
                {60 * 3 + 57.9, 2},
                {60 * 4 + 25.4, 2},
                {60 * 4 + 51.3, 2},
            }
        },

        -- Summon Fragment of Rhyolith
        {
            value = 98136,
            color = {135/255, 145/255, 144/255},
            show = true,
            entries = {
                {60 * 0 + 23.4, 2},
                {60 * 1 +  9.6, 2},
                {60 * 1 + 33.2, 2},
                {60 * 2 + 19.2, 2},
                {60 * 2 + 41.7, 2},
                {60 * 3 + 27.4, 2},
                {60 * 3 + 50.5, 2},
                {60 * 4 + 36.9, 2},
                {60 * 4 + 59.1, 2},
            }
        },

        -- Summon Spark of Rhyolith
        {
            value = 98552,
            color = {138/255, 118/255, 103/255},
            show = true,
            entries = {
                {60 * 0 + 46.5, 2},
                {60 * 1 + 55.9, 2},
                {60 * 3 +  4.8, 2},
                {60 * 4 + 13.7, 2},
                {60 * 5 + 22.7, 2},
            }
        },
	}
}

LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic