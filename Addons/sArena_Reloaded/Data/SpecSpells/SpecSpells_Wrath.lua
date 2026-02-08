sArenaMixin.specIconTextures = {
    DEATHKNIGHT = {
        ["Blood"] = 135770,
        ["Frost"] = 135773,
        ["Unholy"] = 135775
    },
    DRUID = {
        ["Balance"] = 136096,
        ["Feral"] = 132115,
        ["Restoration"] = 136041
    },
    HUNTER = {
        ["Beast Mastery"] = 132164,
        ["Marksmanship"] = 132222,
        ["Survival"] = 132215
    },
    MAGE = {
        ["Arcane"] = 135932,
        ["Fire"] = 135812,
        ["Frost"] = 135846
    },
    PALADIN = {
        ["Holy"] = 135920,
        ["Protection"] = 135893,
        ["Retribution"] = 135873
    },
    PRIEST = {
        ["Discipline"] = 135940,
        ["Holy"] = 237542,
        ["Shadow"] = 136207
    },
    ROGUE = {
        ["Assassination"] = 132292,
        ["Combat"] = 132090,
        ["Subtlety"] = 132320
    },
    SHAMAN = {
        ["Elemental"] = 136048,
        ["Enhancement"] = 136051,
        ["Restoration"] = 136052
    },
    WARLOCK = {
        ["Affliction"] = 136145,
        ["Demonology"] = 136172,
        ["Destruction"] = 136186
    },
    WARRIOR = {
        ["Arms"] = 132355,
        ["Fury"] = 132347,
        ["Protection"] = 132341
    }
}

sArenaMixin.specBuffs = {
    -- WARRIOR
    [56638] = "Arms",          -- Taste for Blood
    [64976] = "Arms",          -- Juggernaut
    [57522] = "Arms",          -- Enrage
    [52437] = "Arms",          -- Sudden Death
    [46857] = "Arms",          -- Trauma
    [56112] = "Fury",          -- Furious Attacks
    [29801] = "Fury",          -- Rampage
    [46916] = "Fury",          -- Slam!
    [50227] = "Protection",    -- Sword and Board
    [50720] = "Protection",    -- Vigilance
    [74347] = "Protection",    -- Silenced - Gag Order
    -- PALADIN
    [20375] = "Retribution",   -- Seal of Command
    [59578] = "Retribution",   -- The Art of War
    [31836] = "Holy",          -- Light's Grace
    [53563] = "Holy",          -- Beacon of Light
    [54149] = "Holy",          -- Infusion of Light
    [63529] = "Protection",    -- Silenced - Shield of the Templar
    -- ROGUE
    [36554] = "Subtlety",      -- Shadowstep
    [44373] = "Subtlety",      -- Shadowstep Speed
    [36563] = "Subtlety",      -- Shadowstep DMG
    [51713] = "Subtlety",      -- Shadow Dance
    [31665] = "Subtlety",      -- Master of Subtlety
    [14278] = "Subtlety",      -- Ghostly Strike
    [51690] = "Combat",        -- Killing Spree
    [13877] = "Combat",        -- Blade Flurry
    [13750] = "Combat",        -- Adrenaline Rush
    [14177] = "Assassination", -- Cold Blood
    -- PRIEST
    [47788] = "Holy",          -- Guardian Spirit
    [52800] = "Discipline",    -- Borrowed Time
    [63944] = "Discipline",    -- Renewed Hope
    [15473] = "Shadow",        -- Shadowform
    [15286] = "Shadow",        -- Vampiric Embrace
    -- DEATHKNIGHT
    [49222] = "Unholy",        -- Bone Shield
    [49016] = "Blood",         -- Hysteria
    [53138] = "Blood",         -- Abomination's Might
    [55610] = "Frost",         -- Imp. Icy Talons
    -- MAGE
    [43039] = "Frost",         -- Ice Barrier
    [74396] = "Frost",         -- Fingers of Frost
    [57761] = "Frost",         -- Fireball!
    [11129] = "Fire",          -- Combustion
    [64346] = "Fire",          -- Fiery Payback
    [48108] = "Fire",          -- Hot Streak
    [54741] = "Fire",          -- Firestarter
    [55360] = "Fire",          -- Living Bomb
    [31583] = "Arcane",        -- Arcane Empowerment
    [44413] = "Arcane",        -- Incanter's Absorption
    -- WARLOCK
    [30302] = "Destruction",   -- Nether Protection
    [63244] = "Destruction",   -- Pyroclasm
    [54277] = "Destruction",   -- Backdraft
    [47283] = "Destruction",   -- Empowered Imp
    [34936] = "Destruction",   -- Backlash
    [47193] = "Demonology",    -- Demonic Empowerment
    [64371] = "Affliction",    -- Eradication
    -- SHAMAN
    [57663] = "Elemental",     -- Totem of Wrath
    [65264] = "Elemental",     -- Lava Flows
    [51470] = "Elemental",     -- Elemental Oath
    [52179] = "Elemental",     -- Astral Shift
    [49284] = "Restoration",   -- Earth Shield
    [53390] = "Restoration",   -- Tidal Waves
    [30809] = "Enhancement",   -- Unleashed Rage
    [53817] = "Enhancement",   -- Maelstrom Weapon
    [63685] = "Enhancement",   -- Freeze (Frozen Power)
    -- HUNTER
    [20895] = "Beast Mastery", -- Spirit Bond
    [34471] = "Beast Mastery", -- The Beast Within
    [75447] = "Beast Mastery", -- Ferocious Inspiration
    [19506] = "Marksmanship",  -- Trueshot Aura
    [64420] = "Survival",      -- Sniper Training
    -- DRUID
    [24932] = "Feral",         -- Leader of the Pack
    [16975] = "Feral",         -- Predatory Strikes
    [24907] = "Balance",       -- Moonkin Aura
    [24858] = "Balance",       -- Moonkin Form
    [48504] = "Restoration",   -- Living Seed
    [45283] = "Restoration",   -- Natural Perfection
    [53251] = "Restoration",   -- Wild Growth
    [16188] = "Restoration",   -- Nature's Swiftness
    [33891] = "Restoration"    -- Tree of Life
}

sArenaMixin.specCasts = {
    -- WARRIOR
    [47486] = "Arms",          -- Mortal Strike
    [46924] = "Arms",          -- Bladestorm
    [23881] = "Fury",          -- Bloodthirst
    [12809] = "Protection",    -- Concussion Blow
    [47498] = "Protection",    -- Devastate
    [46968] = "Protection",    -- Shockwave
    [50720] = "Protection",    -- Vigilance
    -- PALADIN
    [48827] = "Protection",    -- Avenger's Shield
    [48825] = "Holy",          -- Holy Shock
    [53563] = "Holy",          -- Beacon of Light
    [35395] = "Retribution",   -- Crusader Strike
    [66006] = "Retribution",   -- Divine Storm
    [20066] = "Retribution",   -- Repentance
    -- ROGUE
    [48666] = "Assassination", -- Mutilate
    [14177] = "Assassination", -- Cold Blood
    [51690] = "Combat",        -- Killing Spree
    [13877] = "Combat",        -- Blade Flurry
    [13750] = "Combat",        -- Adrenaline Rush
    [36554] = "Subtlety",      -- Shadowstep
    [48660] = "Subtlety",      -- Hemorrhage
    [51713] = "Subtlety",      -- Shadow Dance
    -- PRIEST
    [53007] = "Discipline",    -- Penance
    [10060] = "Discipline",    -- Power Infusion
    [33206] = "Discipline",    -- Pain Suppression
    [34861] = "Holy",          -- Circle of Healing
    [15487] = "Shadow",        -- Silence
    [48160] = "Shadow",        -- Vampiric Touch
    -- DEATHKNIGHT
    [55262] = "Blood",         -- Heart Strike
    [49203] = "Frost",         -- Hungering Cold
    [55268] = "Frost",         -- Frost Strike
    [51411] = "Frost",         -- Howling Blast
    [55271] = "Unholy",        -- Scourge Strike
    -- MAGE
    [44781] = "Arcane",        -- Arcane Barrage
    [55360] = "Fire",          -- Living Bomb
    [42950] = "Fire",          -- Dragon's Breath
    [42945] = "Fire",          -- Blast Wave
    [44572] = "Frost",         -- Deep Freeze
    -- WARLOCK
    [59164] = "Affliction",    -- Haunt
    [47843] = "Affliction",    -- Unstable Affliction
    [47241] = "Demonology",    -- Metamorphosis
    [47193] = "Demonology",    -- Demonic Empowerment
    [59172] = "Destruction",   -- Chaos Bolt
    [47847] = "Destruction",   -- Shadowfury
    -- SHAMAN
    [59159] = "Elemental",     -- Thunderstorm
    [16166] = "Elemental",     -- Elemental Mastery
    [51533] = "Enhancement",   -- Feral Spirit
    [30823] = "Enhancement",   -- Shamanistic Rage
    [17364] = "Enhancement",   -- Stormstrike
    [61301] = "Restoration",   -- Riptide
    [51886] = "Restoration",   -- Cleanse Spirit
    -- HUNTER
    [19577] = "Beast Mastery", -- Intimidation
    [34490] = "Marksmanship",  -- Silencing Shot
    [53209] = "Marksmanship",  -- Chimera Shot
    [60053] = "Survival",      -- Explosive Shot
    [49012] = "Survival",      -- Wyvern Sting
    -- DRUID
    [53201] = "Balance",       -- Starfall
    [61384] = "Balance",       -- Typhoon
    [24858] = "Balance",       -- Moonkin Form
    [48566] = "Feral",         -- Mangle (Cat)
    [48564] = "Feral",         -- Mangle (Bear)
    [61336] = "Feral",         -- Survival Instincts
    [18562] = "Restoration",   -- Swiftmend
    [17116] = "Restoration",   -- Nature's Swiftness
    [33891] = "Restoration",   -- Tree of Life
    [53251] = "Restoration"    -- Wild Growth
}