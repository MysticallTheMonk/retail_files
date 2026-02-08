local _, LRP = ...

local instanceType = 1
local instance = 1
local encounter = 6

local heroic = {
    phases = {
        
    },

    events = {

    }
}

local mythic = {
    phases = {
        
    },

    events = {
        -- Scorpion Form
        {
            event = "SPELL_AURA_APPLIED",
            value = 98379,
            color = {156/255, 121/255, 117/255},
            show = true,
            entries = {
                {60 * 1 +  5.6, 12.8},
                {60 * 2 + 25.6, 12.8},
                {60 * 3 + 46.4,  8.0},
                {60 * 4 + 58.4, 12.0},
                {60 * 6 + 19.2, 11.2},
                {60 * 7 + 37.6,  9.6},
                {60 * 8 + 50.4, 12.0},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 98379,
            show = false,
            entries = {
                {60 * 1 + 18.4},
                {60 * 2 + 38.4},
                {60 * 3 + 54.4},
                {60 * 5 + 10.4},
                {60 * 6 + 30.4},
                {60 * 7 + 47.2},
                {60 * 9 +  2.4},
            }
        },

        -- Cat Form
        {
            event = "SPELL_AURA_APPLIED",
            value = 98374,
            color = {207/255, 184/255, 126/255},
            show = true,
            entries = {
                {60 * 0 +  2.4, 63.2},
                {60 * 1 + 23.2, 62.4},
                {60 * 2 + 38.4, 63.2},
                {60 * 3 + 54.4, 64.0},
                {60 * 5 + 15.2, 64.0},
                {60 * 6 + 30.4, 62.4},
                {60 * 7 + 47.2, 63.2},
                {60 * 9 +  7.2, 23.7},
            }
        },
        {
            event = "SPELL_AURA_REMOVED",
            value = 98374,
            show = false,
            entries = {
                {60 * 1 +  5.6},
                {60 * 2 + 25.6},
                {60 * 3 + 41.6},
                {60 * 4 + 58.4},
                {60 * 6 + 19.2},
                {60 * 7 + 32.8},
                {60 * 8 + 50.4},
                {60 * 9 + 30.9},
            }
        },

        -- Leaping Flames
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98476,
            color = {67/255, 182/255, 240/255},
            show = true,
            entries = {
                {60 * 0 + 20.6, 2},
                {60 * 0 + 35.6, 2},
                {60 * 0 + 48.6, 2},
                {60 * 0 + 59.5, 2},

                {60 * 1 + 41.6, 2},
                {60 * 1 + 56.1, 2},
                {60 * 2 +  9.1, 2},
                {60 * 2 + 20.4, 2},

                {60 * 2 + 56.1, 2},
                {60 * 3 + 10.7, 2},
                {60 * 3 + 23.6, 2},
                {60 * 3 + 34.9, 2},

                {60 * 4 + 12.2, 2},
                {60 * 4 + 27.1, 2},
                {60 * 4 + 40.1, 2},
                {60 * 4 + 51.0, 2},

                {60 * 5 + 33.1, 2},
                {60 * 5 + 47.6, 2},
                {60 * 6 +  0.5, 2},
                {60 * 6 + 11.9, 2},

                {60 * 6 + 47.5, 2},
                {60 * 7 +  2.1, 2},
                {60 * 7 + 15.0, 2},
                {60 * 7 + 26.3, 2},

                {60 * 8 +  4.0, 2},
                {60 * 8 + 19.8, 2},
                {60 * 8 + 32.7, 2},
                {60 * 8 + 44.0, 2},

                {60 * 9 + 24.5, 2},
            }
        },

        -- Burning Orbs
        {
            event = "SPELL_CAST_START",
            value = 98451,
            color = {235/255, 123/255, 38/255},
            show = true,
            entries = {
                {60 * 1 + 18.4, 4},
                {60 * 5 + 10.4, 4},
                {60 * 9 +  2.4, 4},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98451,
            show = false,
            entries = {
                {60 * 1 + 22.4},
                {60 * 5 + 14.4},
                {60 * 9 +  6.4},
            }
        },

        -- Searing Seeds
        {
            event = "SPELL_CAST_START",
            value = 98450,
            color = {232/255, 32/255, 72/255},
            show = true,
            entries = {
                {60 * 3 + 41.6, 4},
                {60 * 7 + 32.8, 4},
            }
        },
        {
            event = "SPELL_CAST_SUCCESS",
            value = 98450,
            show = false,
            entries = {
                {60 * 3 + 45.6},
                {60 * 7 + 36.8},
            }
        },
	}
}

for i = 1, 8 do
    table.insert(
        mythic.phases,
        {
            event = "SPELL_AURA_APPLIED",
            value = 98374, -- Cat Form
            count = i,
            name = string.format("Cat %d", i),
            shortName = string.format("C%d", i)
        }
    )
end

heroic = CopyTable(mythic)

LRP.timelineData[instanceType][instance].encounters[encounter][1] = heroic
LRP.timelineData[instanceType][instance].encounters[encounter][2] = mythic