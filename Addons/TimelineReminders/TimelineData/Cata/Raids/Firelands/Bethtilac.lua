local _, LRP = ...

local instanceType = 1
local instance = 1
local encounter = 1

local heroic = {
    phases = {
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99052, -- Smoldering Devastation
            count = 1,
            name = "Rotation 2",
            shortName = "R2"
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99052, -- Smoldering Devastation
            count = 2,
            name = "Rotation 3",
            shortName = "R3"
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99052, -- Smoldering Devastation
            count = 3,
            name = "Phase 2",
            shortName = "P2"
        },
    },

    events = {
        -- Smoldering Devastation
        {
            event = "SPELL_CAST_START",
            value = 99052,
            color = {235/255, 88/255, 52/255},
            show = true,
            entries = {
                {60 * 1 + 30.2, 8},
                {60 * 3 +  0.8, 8},
                {60 * 4 + 33.1, 8},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99052,
            show = false,
            entries = {
                {60 * 1 + 38.2, 8},
                {60 * 3 +  8.8, 8},
                {60 * 4 + 41.1, 8},
            }
        },

        -- The Widow's Kiss
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99476,
            color = {46/255, 242/255, 89/255},
            show = true,
            entries = {
                {60 * 5 + 15.3, 2},
                {60 * 5 + 47.8, 2},
                {60 * 6 + 20.2, 2},
                {60 * 6 + 51.3, 2},
                {60 * 7 + 23.3, 2},
            }
        },
    }
}

local mythic = {
    phases = {
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99052, -- Smoldering Devastation
            count = 1,
            name = "Rotation 2",
            shortName = "R2"
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99052, -- Smoldering Devastation
            count = 2,
            name = "Rotation 3",
            shortName = "R3"
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99052, -- Smoldering Devastation
            count = 3,
            name = "Phase 2",
            shortName = "P2"
        },
    },

    events = {
        -- Smoldering Devastation
        {
            event = "SPELL_CAST_START",
            value = 99052,
            color = {235/255, 88/255, 52/255},
            show = true,
            entries = {
                {60 * 1 + 30.2, 8},
                {60 * 3 +  0.8, 8},
                {60 * 4 + 33.1, 8},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99052,
            show = false,
            entries = {
                {60 * 1 + 38.2, 8},
                {60 * 3 +  8.8, 8},
                {60 * 4 + 41.1, 8},
            }
        },

        -- The Widow's Kiss
        {
            event = "SPELL_CAST_SUCCESS",
            value = 99476,
            color = {46/255, 242/255, 89/255},
            show = true,
            entries = {
                {60 * 5 + 15.3, 2},
                {60 * 5 + 47.8, 2},
                {60 * 6 + 20.2, 2},
                {60 * 6 + 51.3, 2},
                {60 * 7 + 23.3, 2},
            }
        },
	}
}

LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic