local _, LRP = ...

local instanceType = 1
local instance = 1
local encounter = 1

local heroic = {
}

local mythic = {
    phases = {
        {
            event = "SPELL_AURA_APPLIED",
            value = 445052, -- Chittering Swarm
            count = 1,
            name = "Phase 2 (1)",
            shortName = "P2"
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 440177, -- Ready to Feed
            count = 1,
            name = "Phase 1 (2)",
            shortName = "P1"
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 445052, -- Chittering Swarm
            count = 2,
            name = "Phase 2 (2)",
            shortName = "P2"
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 440177, -- Ready to Feed
            count = 2,
            name = "Phase 1 (3)",
            shortName = "P1"
        }
    },

    events = {
        -- Carnivorous Contest (start)
        {
            event = "SPELL_CAST_SUCCESS",
            value = 434803,
            show = false,
            entries = {
                {60 * 0 + 34},
                {60 * 1 + 10},
                {60 * 3 + 43},
                {60 * 4 + 19},
                {60 * 6 + 57},
                {60 * 7 + 32},
            }
        },

        -- Carnivorous Contest (end)
        {
            event = "SPELL_CAST_SUCCESS",
            value = 457668,
            show = false,
            entries = {
                {60 * 0 + 42},
                {60 * 1 + 18},
                {60 * 3 + 51},
                {60 * 4 + 27},
                {60 * 7 +  4},
                {60 * 7 + 40},
            }
        },

        -- Carnivorous Contest (debuff)
        {
            event = "SPELL_AURA_APPLIED",
            value = 434803,
            color = {227/255, 227/255, 227/255},
            show = true,
            entries = {
                {60 * 0 + 34, 8},
                {60 * 1 + 10, 8},
                {60 * 3 + 43, 8},
                {60 * 4 + 19, 8},
                {60 * 6 + 57, 8},
                {60 * 7 + 32, 8},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 434803,
            show = false,
            entries = {
                {60 * 0 + 42},
                {60 * 1 + 18},
                {60 * 3 + 51},
                {60 * 4 + 27},
                {60 * 7 +  4},
                {60 * 7 + 40},
            }
        },


        -- Stalker's Webbing
        {
            event = "SPELL_CAST_START",
            value = 441452,
            color = {132/255, 217/255, 214/255},
            show = true,
            entries = {
                {60 * 0 +  9, 3},
                {60 * 0 + 54, 3},
                {60 * 3 + 18, 3},
                {60 * 4 +  3, 3},
                {60 * 6 + 31, 3},
                {60 * 7 + 16, 3},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 441452,
            show = false,
            entries = {
                {60 * 0 + 12, 3},
                {60 * 0 + 15, 3},
                {60 * 3 + 21, 3},
                {60 * 4 +  6, 3},
                {60 * 6 + 34, 3},
                {60 * 7 + 19, 3},
            }
        },

        -- Digestive Acid
        {
            event = "SPELL_CAST_START",
            value = 435138,
            show = false,
            entries = {
                {60 * 0 + 15},
                {60 * 1 +  2},
                {60 * 3 + 24},
                {60 * 4 + 11},
                {60 * 6 + 37},
                {60 * 7 + 24},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 435138,
            color = {25/255, 255/255, 71/255},
            show = true,
            entries = {
                {60 * 0 + 17, 6},
                {60 * 1 +  4, 6},
                {60 * 3 + 26, 6},
                {60 * 4 + 13, 6},
                {60 * 6 + 39, 6},
                {60 * 7 + 26, 6},
            }
        },

        -- Venomous Lash
        {
            event = "SPELL_CAST_START",
            value = 435136,
            show = false,
            entries = {
                {60 * 0 +  5},
                {60 * 0 + 30},
                {60 * 0 + 58},
                {60 * 3 + 14},
                {60 * 3 + 39},
                {60 * 4 +  7},
                {60 * 6 + 27},
                {60 * 6 + 52},
                {60 * 7 + 20},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 435136,
            color = {245/255, 196/255, 255/255},
            show = true,
            entries = {
                {60 * 0 +  7, 6},
                {60 * 0 + 32, 6},
                {60 * 1 +  0, 6},
                {60 * 3 + 16, 6},
                {60 * 3 + 41, 6},
                {60 * 4 +  9, 6},
                {60 * 6 + 29, 6},
                {60 * 6 + 54, 6},
                {60 * 7 + 22, 6},
            }
        },

        -- Brutal Crush
        {
            event = "SPELL_CAST_START",
            value = 434697,
            color = {15/255, 102/255, 89/255},
            show = true,
            entries = {
                {60 * 0 +  3, 1},
                {60 * 0 + 18, 1},
                {60 * 0 + 33, 1},
                {60 * 0 + 52, 1},
                {60 * 1 +  7, 1},

                {60 * 3 + 12, 1},
                {60 * 3 + 27, 1},
                {60 * 3 + 42, 1},
                {60 * 4 +  1, 1},
                {60 * 4 + 16, 1},

                {60 * 6 + 25, 1},
                {60 * 6 + 40, 1},
                {60 * 6 + 55, 1},
                {60 * 7 + 14, 1},
                {60 * 7 + 29, 1},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 434697,
            show = false,
            entries = {
                {60 * 0 +  4},
                {60 * 0 + 19},
                {60 * 0 + 34},
                {60 * 0 + 53},
                {60 * 1 +  8},

                {60 * 3 + 13},
                {60 * 3 + 28},
                {60 * 3 + 43},
                {60 * 4 +  2},
                {60 * 4 + 17},

                {60 * 6 + 26},
                {60 * 6 + 41},
                {60 * 6 + 56},
                {60 * 7 + 15},
                {60 * 7 + 30},
            }
        },

        -- Hulking Crash
        {
            event = "SPELL_CAST_START",
            value = 445123,
            color = {224/255, 175/255, 76/255},
            show = true,
            entries = {
                {60 * 1 + 30, 5},
                {60 * 4 + 39, 5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 445123,
            show = false,
            entries = {
                {60 * 1 + 35},
                {60 * 4 + 44},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 435341,
            show = false,
            entries = {
                {60 * 1 + 36},
                {60 * 4 + 45},
            }
        },


        -- Juggernaut Charge (circle)
        {
            event = "SPELL_CAST_START",
            value = 436200,
            show = false,
            entries = {
                {60 * 1 + 43, 4},
                {60 * 1 + 52, 4},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 436200,
            show = false,
            entries = {
                {60 * 1 + 47},
                {60 * 1 + 56},
            }
        },

        -- Juggernaut Charge
        {
            event = "SPELL_CAST_START",
            value = 436203,
            color = {226/255, 104/255, 247/255},
            show = true,
            entries = {
                {60 * 1 + 48, 4},
                {60 * 1 + 55, 4},
                {60 * 2 +  2, 4},
                {60 * 2 +  9, 4},
                {60 * 4 + 56, 4},
                {60 * 5 +  4, 4},
                {60 * 5 + 11, 4},
                {60 * 5 + 18, 4},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 436203,
            show = false,
            entries = {
                {60 * 1 + 52},
                {60 * 1 + 59},
                {60 * 2 +  6},
                {60 * 2 + 13},
                {60 * 5 +  0},
                {60 * 5 +  8},
                {60 * 5 + 15},
                {60 * 5 + 22},
            }
        },

        -- Swallowing Darkness
        {
            event = "SPELL_CAST_START",
            value = 443842,
            color = {101/255, 8/255, 140/255},
            show = true,
            entries = {
                {60 * 2 + 18, 4},
                {60 * 5 + 27, 4},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 443842,
            show = false,
            entries = {
                {60 * 2 + 22},
                {60 * 5 + 31},
            }
        },

        -- Chittering Swarm
        {
            event = "SPELL_CAST_START",
            value = 445052,
            show = false,
            entries = {
                {60 * 1 + 37, 3},
                {60 * 4 + 46, 3},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 445052,
            show = false,
            entries = {
                {60 * 1 + 40},
                {60 * 4 + 49},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 445052,
            color = {81/255, 189/255, 142/255},
            show = true,
            entries = {
                {60 * 1 + 40, 36},
                {60 * 4 + 48, 36},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 445052,
            show = false,
            entries = {
                {60 * 2 + 16},
                {60 * 5 + 24},
            }
        },

        -- Ready to Feed
        {
            event = "SPELL_AURA_APPLIED",
            value = 440177,
            color = {240/255, 53/255, 81/255},
            show = true,
            entries = {
                {60 * 2 + 27, 37},
                {60 * 5 + 36, 41},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 440177,
            show = false,
            entries = {
                {60 * 3 + 4},
                {60 * 6 + 17},
            }
        },
    }
}

heroic = CopyTable(mythic)

LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic