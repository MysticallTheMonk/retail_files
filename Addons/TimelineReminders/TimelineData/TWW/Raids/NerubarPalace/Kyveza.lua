local _, LRP = ...

local instanceType = 1
local instance = 1
local encounter = 6

local heroic = {
    phases = {},
    events = {}
}

local mythic = {
    phases = {},

    events = {
        -- Assassination
        {
            event = "SPELL_CAST_START",
            value = 436971,
            show = false,
            entries = {
                {60 * 0 + 14, 2},
                {60 * 2 + 24, 2},
                {60 * 4 + 34, 2},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 436971,
            show = false,
            entries = {
                {60 * 0 + 16},
                {60 * 2 + 26},
                {60 * 4 + 36},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 436867,
            show = false,
            entries = {
                {60 * 0 + 8},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 440650,
            show = false,
            entries = {
                {60 * 2 + 18},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 442573,
            show = false,
            entries = {
                {60 * 4 + 28},
            }
        },
        {
            value = 442573,
            color = {135/255, 86/255, 240/255},
            show = true,
            entries = {
                {60 * 0 +  8, 8},
                {60 * 2 + 18, 8},
                {60 * 4 + 28, 8},
            }
        },

        -- Twilight Massacre
        {
            event = "SPELL_CAST_START",
            value = 438245,
            show = false,
            entries = {
                {60 * 0 + 34},
                {60 * 1 +  4},

                {60 * 2 + 44},
                {60 * 3 + 14},

                {60 * 4 + 54},
                {60 * 5 + 24},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 438245,
            color = {242/255, 36/255, 74/255},
            show = true,
            entries = {
                {60 * 0 + 34, 6},
                {60 * 1 +  4, 6},

                {60 * 2 + 44, 6},
                {60 * 3 + 14, 6},

                {60 * 4 + 54, 6},
                {60 * 5 + 24, 6},
            }
        },

        -- Queensbane
        {
            value = 437343,
            color = {110/255, 110/255, 110/255},
            show = true,
            entries = {
                {60 * 0 + 17, 9},
                {60 * 0 + 40, 9},
                {60 * 1 + 10, 9},

                {60 * 2 + 27, 9},
                {60 * 2 + 50, 9},
                {60 * 3 + 20, 9},

                {60 * 4 + 37, 9},
                {60 * 5 +  0, 9},
                {60 * 5 + 30, 9},
            }
        },

        -- Nether Rift
        {
            event = "SPELL_CAST_START",
            value = 437620,
            show = false,
            entries = {
                {60 * 0 + 22, 4},
                {60 * 0 + 52, 4},
                {60 * 1 + 22, 4},

                {60 * 2 + 32, 4},
                {60 * 3 +  2, 4},
                {60 * 3 + 32, 4},

                {60 * 4 + 42, 4},
                {60 * 5 + 12, 4},
                {60 * 5 + 42, 4},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 437620,
            color = {245/255, 49/255, 238/255},
            show = true,
            entries = {
                {60 * 0 + 26, 6},
                {60 * 0 + 56, 6},
                {60 * 1 + 26, 6},

                {60 * 2 + 36, 6},
                {60 * 3 +  6, 6},
                {60 * 3 + 36, 6},

                {60 * 4 + 46, 6},
                {60 * 5 + 16, 6},
                {60 * 5 + 46, 6},
            }
        },

        -- Nexus Daggers
        {
            event = "SPELL_CAST_START",
            value = 439576,
            color = {116/255, 232/255, 230/255},
            show = true,
            entries = {
                {60 * 0 + 46, 5},
                {60 * 1 + 16, 5},

                {60 * 2 + 56, 5},
                {60 * 3 + 26, 5},

                {60 * 5 +  6, 5},
                {60 * 5 + 36, 5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 439576,
            show = false,
            entries = {
                {60 * 0 + 48},
                {60 * 1 + 18},

                {60 * 2 + 48},
                {60 * 3 + 18},

                {60 * 4 + 48},
                {60 * 5 + 18},
            }
        },

        -- Void Shredders
        {
            event = "SPELL_CAST_START",
            value = 440377,
            color = {235/255, 184/255, 66/255},
            show = true,
            entries = {
                {60 * 0 + 10, 3},
                {60 * 0 + 40, 3},
                {60 * 1 + 10, 3},

                {60 * 2 + 20, 3},
                {60 * 2 + 50, 3},
                {60 * 3 + 20, 3},

                {60 * 4 + 30, 3},
                {60 * 5 +  0, 3},
                {60 * 5 + 30, 3},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 440377,
            show = false,
            entries = {
                {60 * 0 + 13},
                {60 * 0 + 43},
                {60 * 1 + 13},

                {60 * 2 + 23},
                {60 * 2 + 53},
                {60 * 3 + 23},

                {60 * 4 + 33},
                {60 * 5 +  3},
                {60 * 5 + 33},
            }
        },


        -- Starless Night (include Eternal Night as well)
        {
            event = "SPELL_CAST_START",
            value = 435405,
            show = false,
            entries = {
                {60 * 1 + 36, 5},
                {60 * 3 + 46, 5},
                {60 * 5 + 56, 5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 435405,
            show = false,
            entries = {
                {60 * 1 + 41},
                {60 * 3 + 51},
                {60 * 6 +  1},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 435405,
            color = {49/255, 57/255, 140/255},
            show = true,
            entries = {
                {60 * 1 + 41, 24},
                {60 * 3 + 51, 24},
                {60 * 6 +  1, 60},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 435405,
            show = false,
            entries = {
                {60 * 2 +  5},
                {60 * 4 + 15},
            }
        },

        -- Eternal Night
        {
            event = "SPELL_CAST_START",
            value = 442277,
            show = false,
            entries = {
                {60 * 5 + 56, 5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 442277,
            show = false,
            entries = {
                {60 * 6 +  1},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 442277,
            show = false,
            entries = {
                {60 * 6 +  1},
            }
        },
    }
}

heroic = CopyTable(mythic)

LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic