local _, LRP = ...

local instanceType = 1
local instance = 1
local encounter = 5

local heroic = {
    phases = {},
    events = {}
}

local mythic = {
    phases = {
        {
            event = "SPELL_CAST_SUCCESS",
            value = 442432, -- Ingest Black Blood
            count = 1,
            name = "Phase 1",
            shortName = "P1"
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 442432, -- Ingest Black Blood
            count = 2,
            name = "Phase 2",
            shortName = "P2"
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 442432, -- Ingest Black Blood
            count = 3,
            name = "Phase 3",
            shortName = "P3"
        },
    },

    events = {
        -- Ingest Black Blood
        {
            event = "SPELL_CAST_START",
            value = 442432,
            show = false,
            entries = {
                {60 * 0 + 19, 1},
                {60 * 3 + 14, 1},
                {60 * 6 +  5, 1},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 442432,
            show = false,
            entries = {
                {60 * 0 + 20},
                {60 * 3 + 15},
                {60 * 6 +  6},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 442432,
            color = {245/255, 64/255, 97/255},
            show = true,
            entries = {
                {60 * 0 + 20, 15},
                {60 * 3 + 15, 15},
                {60 * 6 +  6, 15},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 442432,
            show = false,
            entries = {
                {60 * 0 + 35},
                {60 * 3 + 30},
                {60 * 6 + 21},
            }
        },

        -- Experimental Dosage
        {
            event = "SPELL_CAST_START",
            value = 442526,
            show = false,
            entries = {
                {60 * 0 + 35, 2},
                {60 * 1 + 25, 2},
                {60 * 2 + 15, 2},

                {60 * 3 + 30, 2},
                {60 * 4 + 20, 2},
                {60 * 5 + 10, 2},

                {60 * 6 + 21, 2},
                {60 * 7 + 11, 2},
                {60 * 8 +  1, 2},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 442526,
            show = false,
            entries = {
                {60 * 0 + 37},
                {60 * 1 + 27},
                {60 * 2 + 17},

                {60 * 3 + 32},
                {60 * 4 + 22},
                {60 * 5 + 12},

                {60 * 6 + 23},
                {60 * 7 + 13},
                {60 * 8 +  3},
            }
        },
        {
            value = 442526,
            color = {240/255, 72/255, 237/255},
            show = true,
            entries = {
                {60 * 0 + 37, 6},
                {60 * 1 + 27, 6},
                {60 * 2 + 17, 6},

                {60 * 3 + 31, 6},
                {60 * 4 + 21, 6},
                {60 * 5 + 11, 6},

                {60 * 6 + 23, 6},
                {60 * 7 + 13, 6},
                {60 * 8 +  3, 6},
            }
        },

        -- Sticky Web
        {
            event = "SPELL_CAST_SUCCESS",
            value = 446344,
            show = false,
            entries = {
                {60 * 0 + 15},

                {60 * 0 + 50},
                {60 * 1 + 20},
                {60 * 1 + 50},
                {60 * 2 + 20},
                {60 * 2 + 50},

                {60 * 3 + 45},
                {60 * 4 + 15},
                {60 * 4 + 45},
                {60 * 5 + 15},
                {60 * 5 + 45},

                {60 * 6 + 36},
                {60 * 7 +  6},
                {60 * 7 + 36},
                {60 * 8 +  6},
                {60 * 8 + 36},
                {60 * 9 +  6},
                {60 * 9 + 36},
            }
        },
        {
            value = 446349,
            color = {200/255, 200/255, 200/255},
            show = true,
            entries = {
                {60 * 0 + 15, 8},

                {60 * 0 + 50, 8},
                {60 * 1 + 20, 8},
                {60 * 1 + 50, 8},
                {60 * 2 + 20, 8},
                {60 * 2 + 50, 8},

                {60 * 3 + 45, 8},
                {60 * 4 + 15, 8},
                {60 * 4 + 45, 8},
                {60 * 5 + 15, 8},
                {60 * 5 + 45, 8},

                {60 * 6 + 36, 8},
                {60 * 7 +  6, 8},
                {60 * 7 + 36, 8},
                {60 * 8 +  6, 8},
                {60 * 8 + 36, 8},
                {60 * 9 +  6, 8},
                {60 * 9 + 36, 8},
            }
        },

        -- Volatile Concoction
        {
            event = "SPELL_CAST_START",
            value = 443003,
            show = false,
            entries = {
                {60 * 0 +  2, 2},

                {60 * 0 + 37, 2},
                {60 * 0 + 57, 2},
                {60 * 1 + 17, 2},
                {60 * 1 + 37, 2},
                {60 * 1 + 57, 2},
                {60 * 2 + 17, 2},
                {60 * 2 + 37, 2},
                {60 * 2 + 57, 2},

                {60 * 3 + 32, 2},
                {60 * 3 + 52, 2},
                {60 * 4 + 12, 2},
                {60 * 4 + 32, 2},
                {60 * 4 + 52, 2},
                {60 * 5 + 12, 2},
                {60 * 5 + 32, 2},
                {60 * 5 + 52, 2},
                
                {60 * 6 + 23, 2},
                {60 * 6 + 43, 2},
                {60 * 7 +  3, 2},
                {60 * 7 + 23, 2},
                {60 * 7 + 43, 2},
                {60 * 8 +  3, 2},
                {60 * 8 + 23, 2},
                {60 * 8 + 43, 2},
                {60 * 9 +  3, 2},
                {60 * 9 + 23, 2},
                {60 * 9 + 43, 2},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 443003,
            show = false,
            entries = {
                {60 * 0 +  4},

                {60 * 0 + 39},
                {60 * 0 + 59},
                {60 * 1 + 19},
                {60 * 1 + 39},
                {60 * 1 + 59},
                {60 * 2 + 19},
                {60 * 2 + 39},
                {60 * 2 + 59},

                {60 * 3 + 34},
                {60 * 3 + 54},
                {60 * 4 + 14},
                {60 * 4 + 34},
                {60 * 4 + 54},
                {60 * 5 + 14},
                {60 * 5 + 34},
                {60 * 5 + 54},
                
                {60 * 6 + 25},
                {60 * 6 + 45},
                {60 * 7 +  5},
                {60 * 7 + 25},
                {60 * 7 + 45},
                {60 * 8 +  5},
                {60 * 8 + 25},
                {60 * 8 + 45},
                {60 * 9 +  5},
                {60 * 9 + 25},
                {60 * 9 + 45},
            }
        },
        { -- Just here because the cast that actually happens has no tooltip
            value = 441362,
            color = {193/255, 250/255, 50/255},
            show = true,
            entries = {
                {60 * 0 +  4, 8},

                {60 * 0 + 39, 8},
                {60 * 0 + 59, 8},
                {60 * 1 + 19, 8},
                {60 * 1 + 39, 8},
                {60 * 1 + 59, 8},
                {60 * 2 + 19, 8},
                {60 * 2 + 39, 8},
                {60 * 2 + 59, 8},

                {60 * 3 + 33, 8},
                {60 * 3 + 53, 8},
                {60 * 4 + 13, 8},
                {60 * 4 + 33, 8},
                {60 * 4 + 53, 8},
                {60 * 5 + 13, 8},
                {60 * 5 + 33, 8},
                {60 * 5 + 53, 8},
                
                {60 * 6 + 25, 8},
                {60 * 6 + 45, 8},
                {60 * 7 +  5, 8},
                {60 * 7 + 25, 8},
                {60 * 7 + 45, 8},
                {60 * 8 +  5, 8},
                {60 * 8 + 25, 8},
                {60 * 8 + 45, 8},
                {60 * 9 +  5, 8},
                {60 * 9 + 25, 8},
                {60 * 9 + 45, 8},
            }
        },
    }
}

heroic = CopyTable(mythic)

LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic