local _, LRP = ...

local instanceType = 1
local instance = 1
local encounter = 2

local heroic = {
    phases = {},

    events = {
        -- Gruesome Disgorge
        {
            event = "SPELL_CAST_START",
            value = 444363,
            color = {245/255, 140/255, 245/255},
            show = true,
            entries = {
                {60 * 0 + 14, 5},
                {60 * 1 + 13, 5},
                {60 * 2 + 22, 5},
                {60 * 3 + 21, 5},
                {60 * 4 + 30, 5},
                {60 * 5 + 29, 5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 444363,
            show = false,
            entries = {
                {60 * 0 + 19},
                {60 * 1 + 18},
                {60 * 2 + 27},
                {60 * 3 + 26},
                {60 * 4 + 35},
                {60 * 5 + 34},
            }
        },
    
        -- Spewing Hemorrhage
        {
            event = "SPELL_CAST_START",
            value = 445936,
            show = false,
            entries = {
                {60 * 0 + 32, 5},
                {60 * 1 + 31, 5},
                {60 * 2 + 40, 5},
                {60 * 3 + 39, 5},
                {60 * 4 + 48, 5},
                {60 * 5 + 47, 5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 445936,
            show = false,
            entries = {
                {60 * 0 + 37},
                {60 * 1 + 36},
                {60 * 2 + 45},
                {60 * 3 + 34},
                {60 * 4 + 43},
                {60 * 5 + 42},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 454848,
            color = {83/255, 36/255, 240/255},
            show = true,
            entries = {
                {60 * 0 + 37, 21},
                {60 * 1 + 36, 21},
                {60 * 2 + 45, 21},
                {60 * 3 + 44, 21},
                {60 * 4 + 53, 21},
                {60 * 5 + 52, 21},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 454848,
            show = false,
            entries = {
                {60 * 0 + 58},
                {60 * 1 + 57},
                {60 * 3 +  6},
                {60 * 4 +  5},
                {60 * 5 + 14},
                {60 * 6 + 13},
            }
        },
    
        -- Crimson Rain
        {
            event = "SPELL_CAST_SUCCESS",
            value = 443203,
            show = false,
            entries = {
                {60 * 0 + 11},
                {60 * 2 + 19},
                {60 * 4 + 27},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 443203,
            show = false,
            entries = {
                {60 * 0 + 11},
                {60 * 2 + 19},
                {60 * 4 + 27},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 443203,
            show = false,
            entries = {
                {60 * 1 + 55},
                {60 * 4 +  3},
                {60 * 6 + 11},
            }
        },
        {
            value = 443203,
            color = {99/255, 7/255, 19/255},
            show = true,
            entries = {
                {60 * 0 + 12, 10},
                {60 * 0 + 42, 10},
                {60 * 1 + 12, 10},
                {60 * 1 + 42, 10},
                {60 * 2 + 20, 10},
                {60 * 2 + 50, 10},
                {60 * 3 + 20, 10},
                {60 * 3 + 50, 10},
                {60 * 4 + 28, 10},
                {60 * 4 + 58, 10},
                {60 * 5 + 28, 10},
                {60 * 5 + 58, 10},
            }
        },
    
        -- Grasp From Beyond
        {
            value = 443042,
            color = {114/255, 27/255, 207/255},
            show = true,
            entries = {
                {60 * 0 + 19, 12},
                {60 * 0 + 47, 12},
                {60 * 1 + 18, 12},
                {60 * 1 + 46, 12},
    
                {60 * 2 + 27, 12},
                {60 * 2 + 55, 12},
                {60 * 3 + 26, 12},
                {60 * 3 + 54, 12},
    
                {60 * 4 + 35, 12},
                {60 * 5 +  3, 12},
                {60 * 5 + 34, 12},
                {60 * 6 +  2, 12},
            }
        },
    
        -- Goresplatter
        {
            event = "SPELL_CAST_START",
            value = 442530,
            color = {255/255, 0/255, 0/255},
            show = true,
            entries = {
                {60 * 2 +  0, 8},
                {60 * 4 +  8, 8},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 442530,
            show = false,
            entries = {
                {60 * 2 +  8},
                {60 * 4 +  16},
            }
        },
    }
}

local mythic = {
    phases = {},

    events = {
        -- Gruesome Disgorge
        {
            event = "SPELL_CAST_START",
            value = 444363,
            color = {245/255, 140/255, 245/255},
            show = true,
            entries = {
                {60 * 0 + 14, 5},
                {60 * 1 + 13, 5},
                {60 * 2 + 22, 5},
                {60 * 3 + 21, 5},
                {60 * 4 + 30, 5},
                {60 * 5 + 29, 5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 444363,
            show = false,
            entries = {
                {60 * 0 + 19},
                {60 * 1 + 18},
                {60 * 2 + 27},
                {60 * 3 + 26},
                {60 * 4 + 35},
                {60 * 5 + 34},
            }
        },
    
        -- Bloodcurdle
        {
            event = "SPELL_CAST_START",
            value = 452237,
            show = false,
            entries = {
                {60 * 0 +  9, 2},
                {60 * 0 + 41, 2},
                {60 * 1 +  8, 2},
                {60 * 1 + 40, 2},
                {60 * 2 + 17, 2},
                {60 * 2 + 49, 2},
                {60 * 3 + 16, 2},
                {60 * 3 + 48, 2},
                {60 * 4 + 25, 2},
                {60 * 4 + 57, 2},
                {60 * 5 + 24, 2},
                {60 * 5 + 56, 2},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 452237,
            color = {245/255, 49/255, 78/255},
            show = true,
            entries = {
                {60 * 0 + 11, 5},
                {60 * 0 + 43, 5},
                {60 * 1 + 10, 5},
                {60 * 1 + 42, 5},
                {60 * 2 + 19, 5},
                {60 * 2 + 51, 5},
                {60 * 3 + 18, 5},
                {60 * 3 + 50, 5},
                {60 * 4 + 27, 5},
                {60 * 4 + 59, 5},
                {60 * 5 + 26, 5},
                {60 * 5 + 58, 5},
            }
        },
    
        -- Spewing Hemorrhage
        {
            event = "SPELL_CAST_START",
            value = 445936,
            show = false,
            entries = {
                {60 * 0 + 32, 5},
                {60 * 1 + 31, 5},
                {60 * 2 + 40, 5},
                {60 * 3 + 39, 5},
                {60 * 4 + 48, 5},
                {60 * 5 + 47, 5},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 445936,
            show = false,
            entries = {
                {60 * 0 + 37},
                {60 * 1 + 36},
                {60 * 2 + 45},
                {60 * 3 + 34},
                {60 * 4 + 43},
                {60 * 5 + 42},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 454848,
            color = {83/255, 36/255, 240/255},
            show = true,
            entries = {
                {60 * 0 + 37, 21},
                {60 * 1 + 36, 21},
                {60 * 2 + 45, 21},
                {60 * 3 + 44, 21},
                {60 * 4 + 53, 21},
                {60 * 5 + 52, 21},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 454848,
            show = false,
            entries = {
                {60 * 0 + 58},
                {60 * 1 + 57},
                {60 * 3 +  6},
                {60 * 4 +  5},
                {60 * 5 + 14},
                {60 * 6 + 13},
            }
        },
    
        -- Crimson Rain
        {
            event = "SPELL_CAST_SUCCESS",
            value = 443203,
            show = false,
            entries = {
                {60 * 0 + 11},
                {60 * 2 + 19},
                {60 * 4 + 27},
            }
        },
        {
            event = "SPELL_AURA_APPLIED",
            value = 443203,
            show = false,
            entries = {
                {60 * 0 + 11},
                {60 * 2 + 19},
                {60 * 4 + 27},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 443203,
            show = false,
            entries = {
                {60 * 1 + 55},
                {60 * 4 +  3},
                {60 * 6 + 11},
            }
        },
        {
            value = 443203,
            color = {99/255, 7/255, 19/255},
            show = true,
            entries = {
                {60 * 0 + 12, 10},
                {60 * 0 + 42, 10},
                {60 * 1 + 12, 10},
                {60 * 1 + 42, 10},
                {60 * 2 + 20, 10},
                {60 * 2 + 50, 10},
                {60 * 3 + 20, 10},
                {60 * 3 + 50, 10},
                {60 * 4 + 28, 10},
                {60 * 4 + 58, 10},
                {60 * 5 + 28, 10},
                {60 * 5 + 58, 10},
            }
        },
    
        -- Grasp From Beyond
        {
            value = 443042,
            color = {114/255, 27/255, 207/255},
            show = true,
            entries = {
                {60 * 0 + 19, 12},
                {60 * 0 + 47, 12},
                {60 * 1 + 18, 12},
                {60 * 1 + 46, 12},
    
                {60 * 2 + 27, 12},
                {60 * 2 + 55, 12},
                {60 * 3 + 26, 12},
                {60 * 3 + 54, 12},
    
                {60 * 4 + 35, 12},
                {60 * 5 +  3, 12},
                {60 * 5 + 34, 12},
                {60 * 6 +  2, 12},
            }
        },
    
        -- Goresplatter
        {
            event = "SPELL_CAST_START",
            value = 442530,
            color = {255/255, 0/255, 0/255},
            show = true,
            entries = {
                {60 * 2 +  0, 8},
                {60 * 4 +  8, 8},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 442530,
            show = false,
            entries = {
                {60 * 2 +  8},
                {60 * 4 +  16},
            }
        },
    }
}

LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic