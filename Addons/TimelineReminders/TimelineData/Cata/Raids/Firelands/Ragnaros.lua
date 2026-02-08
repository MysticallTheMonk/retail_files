local _, LRP = ...

local L = LRP.L
local instanceType = 1
local instance = 1
local encounter = 7

local heroic = {
    phases = {
        {
            event = "SPELL_CAST_START",
            value = 98951, -- Splitting Blow
            count = 1,
            name = "Intermission 1",
            shortName = "I1"
        },
        {
            event = "CHAT_MSG_MONSTER_YELL",
            value = L.ragnaros_intermission_end1,
            count = 1,
            name = "Phase 2",
            shortName = "P2"
        },
        {
            event = "SPELL_CAST_START",
            value = 98951, -- Splitting Blow
            count = 2,
            name = "Intermission 2",
            shortName = "I2"
        },
        {
            event = "CHAT_MSG_MONSTER_YELL",
            value = L.ragnaros_intermission_end1,
            count = 2,
            name = "Phase 3",
            shortName = "P3"
        },
    },

    events = {
        -- Wrath of Ragnaros
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98263,
            color = {245/255, 27/255, 38/255},
            show = true,
            entries = {
                {60 * 0 +  6.4, 1},
                {60 * 0 + 43.7, 1},
                {60 * 1 + 14.4, 1},
                {60 * 1 + 45.2, 1},
            }
        },

        -- Hand of Ragnaros
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98237,
            color = {104/255, 44/255, 209/255},
            show = true,
            entries = {
                {60 * 0 + 25.9, 1},
                {60 * 0 + 51.8, 1},
                {60 * 1 + 17.7, 1},
                {60 * 1 + 43.6, 1},
            }
        },

        -- Magma Trap
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98164,
            color = {245/255, 152/255, 39/255},
            show = true,
            entries = {
                {60 * 0 + 16.1, 4},
                {60 * 0 + 42.1, 4},
                {60 * 1 +  8.0, 4},
                {60 * 1 + 38.7, 4},
            }
        },

        -- Phase 2/3 start
        {
            event = "CHAT_MSG_MONSTER_YELL",
            value = L.ragnaros_intermission_end1,
            show = false,
            entries = {
                {60 * 2 + 43.7},
                {60 * 6 + 20.1},
            }
        },

        -- Sulfuras Smash
        {
            event = "SPELL_CAST_START",
            value = 98710,
            color = {247/255, 203/255, 42/255},
            show = true,
            entries = {
                {60 * 0 + 30.8, 2.5},
                {60 * 1 +  1.5, 2.5},
                {60 * 1 + 32.3, 2.5},

                {60 * 2 + 59.7, 2.5},
                {60 * 3 + 40.1, 2.5},
                {60 * 4 + 20.2, 2.5},
                {60 * 5 +  1.5, 2.5},

                {60 * 6 + 36.1, 2.5},
                {60 * 7 +  6.9, 2.5},
                {60 * 7 + 38.1, 2.5},
                {60 * 8 +  8.4, 2.5},
                {60 * 8 + 39.2, 2.5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98710,
            show = false,
            entries = {
                {60 * 0 + 33.3},
                {60 * 1 +  4.0},
                {60 * 1 + 34.8},

                {60 * 3 +  2.2},
                {60 * 3 + 42.6},
                {60 * 4 + 22.7},
                {60 * 5 +  4.0},

                {60 * 6 + 38.6},
                {60 * 7 +  9.4},
                {60 * 7 + 40.6},
                {60 * 8 + 11.0},
                {60 * 8 + 41.7},
            }
        },
        
        -- Molten Seed
        {
            value = 98498,
            color = {237/255, 82/255, 242/255},
            show = true,
            entries = {
                {60 * 3 +  6.4, 10},
                {60 * 4 +  6.8, 10},
                {60 * 5 +  8.0, 10},
            }
        },

        -- Living Meteor
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99317,
            color = {179/255, 141/255, 125/255},
            show = true,
            entries = {
                {60 * 7 +  9.3, 2},
                {60 * 7 + 54.6, 2},
                {60 * 8 + 39.7, 2},
            }
        },

        -- Splitting Blow
        {
            event = "SPELL_CAST_START",
            value = 98951,
            color = {247/255, 106/255, 35/255},
            show = true,
            entries = {
                {60 * 1 + 59.7, 8},
                {60 * 5 + 31.8, 8},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98951,
            show = false,
            entries = {
                {60 * 2 +  7.7},
                {60 * 5 + 39.8},
            }
        },
	}
}

local mythic = {
    phases = {
        {
            event = "SPELL_CAST_START",
            value = 98951, -- Splitting Blow
            count = 1,
            name = "Intermission 1",
            shortName = "I1"
        },
        {
            event = "CHAT_MSG_MONSTER_YELL",
            value = L.ragnaros_intermission_end1,
            count = 1,
            name = "Phase 2",
            shortName = "P2"
        },
        {
            event = "SPELL_CAST_START",
            value = 98951, -- Splitting Blow
            count = 2,
            name = "Intermission 2",
            shortName = "I2"
        },
        {
            event = "CHAT_MSG_MONSTER_YELL",
            value = L.ragnaros_intermission_end1,
            count = 2,
            name = "Phase 3",
            shortName = "P3"
        },
        {
            event = "CHAT_MSG_MONSTER_YELL",
            value = L.ragnaros_phase_4,
            count = 1,
            name = "Phase 4",
            shortName = "P4"
        },
    },

    events = {
        -- Wrath of Ragnaros
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98263,
            color = {245/255, 27/255, 38/255},
            show = true,
            entries = {
                {60 * 0 +  6.4, 1},
                {60 * 0 + 43.7, 1},
                {60 * 1 + 14.4, 1},
                {60 * 1 + 45.2, 1},
            }
        },

        -- Hand of Ragnaros
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98237,
            color = {104/255, 44/255, 209/255},
            show = true,
            entries = {
                {60 * 0 + 25.9, 1},
                {60 * 0 + 51.8, 1},
                {60 * 1 + 17.7, 1},
                {60 * 1 + 43.6, 1},
                {60 * 2 +  9.5, 1},
            }
        },

        -- Magma Trap
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98164,
            color = {245/255, 152/255, 39/255},
            show = true,
            entries = {
                {60 * 0 + 16.1, 4},
                {60 * 0 + 42.1, 4},
                {60 * 1 +  8.0, 4},
                {60 * 1 + 38.7, 4},
                {60 * 2 +  9.5, 4},
            }
        },

        -- Phase 2/3 start
        {
            event = "CHAT_MSG_MONSTER_YELL",
            value = L.ragnaros_intermission_end1,
            show = false,
            entries = {
                {60 * 2 + 53.6},
                {60 * 7 + 48.4},
            }
        },

        -- Sulfuras Smash
        {
            event = "SPELL_CAST_START",
            value = 98710,
            color = {247/255, 203/255, 42/255},
            show = true,
            entries = {
                {60 * 0 + 30.8, 2.5},
                {60 * 1 +  1.5, 2.5},
                {60 * 1 + 32.3, 2.5},
                {60 * 2 +  3.0, 2.5},

                {60 * 2 + 59.6, 2.5},
                {60 * 3 + 48.3, 2.5},
                {60 * 4 + 29.0, 2.5},
                {60 * 5 +  9.5, 2.5},
                {60 * 5 + 50.0, 2.5},
                {60 * 6 + 30.6, 2.5},

                {60 * 8 +  4.4, 2.5},
                {60 * 8 + 36.8, 2.5},
                {60 * 9 +  7.5, 2.5},
                {60 * 9 + 38.3, 2.5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98710,
            show = false,
            entries = {
                {60 * 0 + 33.3},
                {60 * 1 +  4.0},
                {60 * 1 + 34.8},
                {60 * 2 +  5.5},

                {60 * 3 +  2.1},
                {60 * 3 + 50.8},
                {60 * 4 + 31.5},
                {60 * 5 + 12.0},
                {60 * 5 + 52.5},
                {60 * 6 + 33.1},

                {60 * 8 +  6.9},
                {60 * 8 + 39.3},
                {60 * 9 + 10.0},
                {60 * 9 + 40.8},
            }
        },

        -- World in Flames
        {
            event = "SPELL_CAST_SUCCESS",
            value = 100171,
            color = {184/255, 50/255, 17/255},
            show = true,
            entries = {
                {60 * 3 + 35.2, 12},
                {60 * 4 + 35.5, 12},
                {60 * 5 + 35.5, 12},
                {60 * 6 + 37.0, 12},

                {60 * 8 + 20.6, 12},
                {60 * 8 + 51.3, 12},
                {60 * 9 + 22.1, 12},
                {60 * 9 + 52.9, 12},
            }
        },
        
        -- Molten Seed
        {
            value = 98498,
            color = {237/255, 82/255, 242/255},
            show = true,
            entries = {
                {60 * 3 + 11.9, 10},
                {60 * 4 + 13.8, 10},
                {60 * 5 + 16.7, 10},
                {60 * 6 + 18.0, 10},
            }
        },

        -- Living Meteor
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99317,
            color = {179/255, 141/255, 125/255},
            show = true,
            entries = {
                {60 * 8 + 39.2, 2},
                {60 * 9 + 24.5, 2},
            }
        },

        -- Splitting Blow (intermission 1)
        {
            event = "SPELL_CAST_START",
            value = 98951,
            color = {247/255, 106/255, 35/255},
            show = true,
            entries = {
                {60 * 2 + 16.0, 8},
                {60 * 6 + 50.0, 8},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98951,
            show = false,
            entries = {
                {60 * 2 + 24.0},
                {60 * 6 + 58.0},
            }
        },

        -- Phase 4 start
        {
            event = "CHAT_MSG_MONSTER_YELL",
            value = L.ragnaros_phase_4,
            show = false,
            entries = {
                {60 * 10 + 15.4, 3},
            }
        },

        -- Superheated
        {
            event = "SPELL_CAST_SUCCESS",
            value = 100593,
            show = false,
            entries = {
                {60 * 10 + 48.4},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 100593,
            show = false,
            entries = {
                {60 * 10 + 48.4},
            }
        },

        -- Empower Sulfuras
        {
            event = "SPELL_CAST_SUCCESS",
            value = 100604,
            show = false,
            entries = {
                {60 * 11 + 37.1},
                {60 * 12 + 37.0},
                {60 * 13 + 32.0},
                {60 * 14 + 27.2},
                {60 * 15 + 22.2},
            }
        },

        -- Empowered Sulfuras
        {
            event = "SPELL_AURA_APPLIED",
            value = 100628,
            color = {230/255, 34/255, 80/255},
            show = true,
            entries = {
                {60 * 11 + 42.1, 10},
                {60 * 12 + 42.0, 10},
                {60 * 13 + 37.0, 10},
                {60 * 14 + 32.2, 10},
                {60 * 15 + 27.2, 10},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 100628,
            show = false,
            entries = {
                {60 * 11 + 52.1},
                {60 * 12 + 52.0},
                {60 * 13 + 47.0},
                {60 * 14 + 42.2},
                {60 * 15 + 37.2},
            }
        },

        -- Entrapping Roots
        {
            event = "SPELL_CAST_START",
            value = 100646,
            color = {72/255, 163/255, 102/255},
            show = true,
            entries = {
                {60 * 11 + 22.5, 3},
                {60 * 12 + 17.6, 3},
                {60 * 13 + 12.6, 3},
                {60 * 14 +  7.7, 3},
                {60 * 15 +  2.8, 3},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 100646,
            show = false,
            entries = {
                {60 * 11 + 25.5},
                {60 * 12 + 20.6},
                {60 * 13 + 15.6},
                {60 * 14 + 10.7},
                {60 * 15 +  5.8},
            }
        },

        -- Breadth of Frost
        {
            event = "SPELL_CAST_START",
            value = 100479,
            color = {164/255, 214/255, 245/255},
            show = true,
            entries = {
                {60 * 10 + 48.4, 3},
                {60 * 11 + 33.9, 3},
                {60 * 12 + 19.2, 3},
                {60 * 13 +  4.5, 3},
                {60 * 13 + 49.9, 3},
                {60 * 14 + 35.3, 3},
                {60 * 15 + 20.6, 3},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 100479,
            show = false,
            entries = {
                {60 * 10 + 51.4},
                {60 * 11 + 36.9},
                {60 * 12 + 22.2},
                {60 * 13 +  7.5},
                {60 * 13 + 52.9},
                {60 * 14 + 38.3},
                {60 * 15 + 23.6},
            }
        },
	}
}

LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic