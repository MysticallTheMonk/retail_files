local _, LRP = ...

local instanceType = 1
local instance = 1
local encounter = 3

local heroic = {
    phases = {
        {
            event = "SPELL_AURA_REMOVED",
            value = 99432, -- Burnout
            count = 1,
            name = "Rotation 2",
            shortName = "R2"
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 99432, -- Burnout
            count = 2,
            name = "Rotation 3",
            shortName = "R3"
        },
    },

    events = {
        -- Fiery Vortex
        {
            value = 99794,
            color = {237/255, 242/255, 78/255},
            show = true,
            entries = {
                {60 * 3 + 24.5, 22.5},
                {60 * 7 + 50.0, 22.5},
            }
        },

        -- Burnout
        {
            event = "SPELL_AURA_APPLIED",
            value = 99432,
            color = {242/255, 182/255, 78/255},
            show = true,
            entries = {
                {60 *  3 + 50.0, 30.8},
                {60 *  8 + 15.5, 32.4},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 99432,
            show = false,
            entries = {
                {60 *  4 + 20.8},
                {60 *  8 + 47.9},
            }
        },

        -- Blazing Buffet
        {
            value = 99757,
            color = {242/255, 130/255, 78/255},
            show = true,
            entries = {
                {60 *  4 + 20.8, 27},
                {60 *  8 + 47.9, 27},
            }
        },

        -- Full Power
        {
            value = 99925,
            color = {242/255, 78/255, 78/255},
            show = true,
            entries = {
                {60 *  4 + 47.8, 2},
                {60 *  9 + 14.9, 2},
            }
        },

        -- Summon Voracious Hatchling
        {
            value = 100363,
            color = {59/255, 111/255, 245/255},
            show = true,
            entries = {
                {60 *  0 + 52.0, 2},
                {60 *  5 + 28.0, 2},
                {60 *  9 + 55.0, 2},
            }
        },

        -- Molting
        {
            event = "SPELL_AURA_APPLIED",
            value = 100836,
            color = {104/255, 237/255, 104/255},
            show = true,
            entries = {
                {60 *  0 + 13.2, 9},
                {60 *  1 + 16.4, 9},
                {60 *  2 + 19.5, 9},

                {60 *  5 + 41.7, 9},
                {60 *  6 + 44.8, 9},

                {60 * 10 + 10.5, 9},
                {60 * 11 + 13.6, 9},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 100836,
            show = false,
            entries = {
                {60 *  0 + 22.2},
                {60 *  1 + 25.4},
                {60 *  2 + 28.5},

                {60 *  5 + 50.7},
                {60 *  6 + 53.8},

                {60 * 10 + 19.5},
                {60 * 11 + 22.6},
            }
        },
	}
}

local mythic = {
    phases = {
        {
            event = "SPELL_AURA_REMOVED",
            value = 99432, -- Burnout
            count = 1,
            name = "Rotation 2",
            shortName = "R2"
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 99432, -- Burnout
            count = 2,
            name = "Rotation 3",
            shortName = "R3"
        },
    },

    events = {
        -- Fiery Vortex
        {
            value = 99794,
            color = {237/255, 242/255, 78/255},
            show = true,
            entries = {
                {60 * 4 + 16.0, 22.5},
                {60 * 9 + 35.3, 22.5},
            }
        },

        -- Burnout
        {
            event = "SPELL_AURA_APPLIED",
            value = 99432,
            color = {242/255, 182/255, 78/255},
            show = true,
            entries = {
                {60 *  4 + 41.6, 35.6},
                {60 * 10 +  0.8, 36.8},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 99432,
            show = false,
            entries = {
                {60 *  5 + 17.2},
                {60 * 10 + 37.6},
            }
        },

        -- Blazing Buffet
        {
            value = 99757,
            color = {242/255, 130/255, 78/255},
            show = true,
            entries = {
                {60 *  5 + 17.2, 25},
                {60 * 10 + 37.6, 25},
            }
        },

        -- Full Power
        {
            value = 99925,
            color = {242/255, 78/255, 78/255},
            show = true,
            entries = {
                {60 *  5 + 42.2, 2},
                {60 * 11 +  2.6, 2},
            }
        },

        -- Meteoric Impact
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99558,
            color = {163/255, 157/255, 122/255},
            show = true,
            entries = {
                {60 * 0 + 40.8, 4},
                {60 * 2 +  8.4, 4},
                {60 * 6 + 11.0, 4},
                {60 * 7 + 27.1, 4},
            }
        },

        -- Firestorm
        {
            event = "SPELL_CAST_START",
            value = 100744,
            color = {237/255, 102/255, 228/255},
            show = true,
            entries = {
                {60 * 1 + 37.5, 5},
                {60 * 3 +  1.6, 5},
                {60 * 6 + 56.3, 5},
                {60 * 8 + 20.5, 5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 100744,
            show = false,
            entries = {
                {60 * 1 + 42.5, 5},
                {60 * 3 +  6.6, 5},
                {60 * 7 +  1.3, 5},
                {60 * 8 + 25.5, 5},
            }
        },

        -- Molting
        {
            event = "SPELL_AURA_APPLIED",
            value = 100836,
            color = {104/255, 237/255, 104/255},
            show = true,
            entries = {
                {60 * 0 + 13.2, 9},
                {60 * 1 + 37.5, 9},
                {60 * 3 +  1.7, 9},

                {60 * 6 + 56.3, 9},
                {60 * 8 + 20.5, 9},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 100836,
            show = false,
            entries = {
                {60 * 0 + 22.2},
                {60 * 1 + 46.5},
                {60 * 3 + 10.7},

                {60 * 7 +  5.3},
                {60 * 8 + 29.5},
            }
        },
	}
}

LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic