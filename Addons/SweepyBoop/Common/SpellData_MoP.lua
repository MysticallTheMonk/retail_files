local _, addon = ...;

local specID = addon.SPECID;
local category = addon.SPELLCATEGORY;

-- charges: baseline 2 charges
-- opt_charges: optionally 2 charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind, priest fear

addon.SpellData = {
    -- Death Knight
    -- Anti-Magic Shell
    [48707] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 45,
        baseline = true,
    },
    -- Dark Simulacrum
    [77606] = {
        class = addon.DEATHKNIGHT,
        category = category.OTHERS,
        cooldown = 30, -- baseline 60s, glyph to reduce to 30s
        baseline = true,
    },
    -- Death Grip
    [49576] = {
        class = addon.DEATHKNIGHT,
        category = category.OTHERS,
        cooldown = 25,
        baseline = true,
    },
    -- Empower Rune Weapon
    [47568] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 300,
        baseline = true,
    },
    -- Icebound Fortitude
    [48792] = {
        class = addon.DEATHKNIGHT,
        category = category.IMMUNITY,
        cooldown = 180,
        baseline = true,
    },
    -- Mind Freeze
    [47528] = {
        class = addon.DEATHKNIGHT,
        category = category.INTERRUPT,
        cooldown = 15,
        baseline = true,
    },
    -- Shambling Rush
    [91807] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.INTERRUPT,
        cooldown = 30,
        trackPet = true,
        trackEvent = addon.SPELL_AURA_APPLIED,
    },
    -- Strangulate
    [47476] = {
        class = addon.DEATHKNIGHT,
        category = category.SILENCE,
        cooldown = 60,
        baseline = true,
    },
    -- Unholy Blight
    [115989] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 90,
        duration = 10,
    },
    -- Lichborne
    [49039] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Anti-Magic Zone
    [51052] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Asphyxiate
    [108194] = {
        class = addon.DEATHKNIGHT,
        category = category.STUN,
        cooldown = 30,
    },
    -- Death Pact
    [48743] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Gorefiend's Grasp
    [108199] = {
        class = addon.DEATHKNIGHT,
        category = category.OTHERS,
        cooldown = 60,
    },
    -- Remorseless Winter
    [108200] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 60,
        duration = 8,
    },
    -- Desecrated Ground
    [108201] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Unholy
    -- Summon Gargoyle
    [49206] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 180,
        duration = 30,
        baseline = true,
    },
    -- Unholy Frenzy
    [49016] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 180,
        duration = 30,
        baseline = true,
    },
    -- Frost
    -- Pillar of Frost
    [51271] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 60,
        duration = 20,
        baseline = true,
    },
    -- Symbiosis/Wild Mashroom: Plague
    [113516] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK, specID.UNHOLY },
        category = category.BURST,
        cooldown = 180,
        duration = 30,
    },

    -- Druid
    -- Displacer Beast
    [102280] = {
        class = addon.DRUID,
        category = category.MOBILITY,
        cooldown = 30,
    },
    -- Barkskin
    [22812] = {
        class = addon.DRUID,
        category = category.DEFENSIVE,
        cooldown = 45,
        baseline = true,
    },
    -- Innervate
    [29166] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 180,
        baseline = true,
    },
    -- Maim
    [22570] = {
        class = addon.DRUID,
        category = category.STUN,
        cooldown = 10,
        baseline = true,
    },
    -- Might of Ursoc
    [106922] = {
        class = addon.DRUID,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Nature's Grasp
    [16689] = {
        class = addon.DRUID,
        category = category.CROWDCONTROL,
        cooldown = 60,
        baseline = true,
    },
    -- Nature's Swiftness
    [132158] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID, specID.BALANCE },
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
    -- Stampeding Roar
    [106898] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 120,
        baseline = true,
    },
    -- Tranquility
    [740] = {
        class = addon.DRUID,
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
    },
    -- Berserk
    [106951] = {
        class = addon.DRUID,
        spec = { specID.FERAL, specID.GUARDIAN },
        category = category.BURST,
        cooldown = 180,
        duration = 15,
        baseline = true,
    },
    -- Survival Instincts
    [61336] = {
        class = addon.DRUID,
        spec = { specID.FERAL, specID.GUARDIAN },
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Displacer Beast
    [102280] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 30,
    },
    -- Renewal
    [108238] = {
        class = addon.DRUID,
        category = category.HEAL,
        cooldown = 120,
    },
    -- Typhoon
    [132469] = {
        class = addon.DRUID,
        category = category.KNOCKBACK,
        cooldown = 30,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
    -- Disorienting Roar
    [99] = {
        class = addon.DRUID,
        category = category.CROWDCONTROL,
        cooldown = 30,
    },
    -- Ursol's Vortex
    [102793] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 60,
    },
    -- Mighty Bash
    [5211] = {
        class = addon.DRUID,
        category = category.STUN,
        cooldown = 50,
    },
    -- Nature's Vigil
    [124974] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 90,
    },
    -- Skull Bash
    [80965] = {
        class = addon.DRUID,
        spec = { specID.FERAL, specID.GUARDIAN },
        category = category.INTERRUPT,
        cooldown = 15,
        baseline = true,
    },
        [80964] = {
            parent = 80965,
            use_parent_icon = true,
        },
    -- Remove Corruption
    [2782] = {
        class = addon.DRUID,
        spec = { specID.BALANCE, specID.FERAL },
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Mass Entanglement
    [102359] = {
        class = addon.DRUID,
        category = category.CROWDCONTROL,
        cooldown = 30,
    },
    -- Restoration
    -- Ironbark
    [102342] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DEFENSIVE,
        cooldown = 30,
        baseline = true,
    },
    -- Nature's Cure
    [88423] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Incarnation: Tree of Life
    [33891] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DEFENSIVE,
        cooldown = 180,
    },
    -- Feral
    -- Tiger's Fury
    [5217] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 30,
        duration = 6,
        baseline = true,
    },
    -- Incarnation: King of the Jungle
    [102543] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 180,
        duration = 30,
        baseline = true,
    },
    -- Balance
    -- Celestial Alignment
    [112071] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 180,
        duration = 15,
        baseline = true,
    },
    -- Incarnation: Chosen of Elune
    [102560] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 180,
        duration = 30,
    },
    -- Solar Beam
    [78675] = {
        cooldown = 60,
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.SILENCE,
        baseline = true,
    },
    -- Symbiosis (Balance)
    -- Anti-Magic Shell
    [110570] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.DEFENSIVE,
        cooldown = 45,
    },
    -- Grapple Weapon
    [126458] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Hammer of Justice
    [110698] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.STUN,
        cooldown = 60,
    },
    -- Mass Dispel
    [110707] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.DISPEL,
        cooldown = 60,
    },
    -- Cloak of Shadows
    [110788] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Unending Resolve
    [122291] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.DEFENSIVE,
        cooldown = 180,
    },
    -- Intervene
    [122292] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.DEFENSIVE,
        cooldown = 30,
    },
    -- Symbiosis/Feral
    -- Play Dead
    [110597] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.DEFENSIVE,
        cooldown = 30,
    },
    -- Clash
    [126449] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.OTHERS,
        cooldown = 35,
    },
    -- Divine Shield
    [110700] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.IMMUNITY,
        cooldown = 300,
    },
    -- Dispersion
    [110715] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.DEFENSIVE,
        cooldown = 180,
    },
    -- Feral Spirit
    [110807] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 120,
        duration = 30,
    },
    -- Shattering Blow
    [112997] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.OTHERS,
        cooldown = 300,
    },
    -- Symbiosis/Restoration
    -- Icebound Fortitude
    [110575] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.IMMUNITY,
        cooldown = 180,
    },
    -- Deterrence
    [110617] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DEFENSIVE,
        cooldown = 180,
    },
    -- Ice Block
    [110696] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.IMMUNITY,
        cooldown = 300,
    },
    -- Fortifying Brew
    [126456] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DEFENSIVE,
        cooldown = 180,
    },
    -- Cleanse
    [122288] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DISPEL,
        cooldown = 8,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Leap of Faith
    [110718] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Evasion
    [110791] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DEFENSIVE,
        cooldown = 180,
    },
    -- Spirit Walker's Grace
    [110806] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.OTHERS,
        cooldown = 120,
    },
    -- Demonic Circle: Teleport
    [112970] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DEFENSIVE,
        cooldown = 30,
    },
    -- Intimidating Roar
    [113004] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.CROWDCONTROL,
        cooldown = 90,
    },

    -- Hunter
    -- Nether Shock
    [50479] = {
        class = addon.HUNTER,
        category = category.INTERRUPT,
        cooldown = 40,
        trackPet = true,
    },
    -- Camouflage
    [51753] = {
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Counter Shot
    [147362] = {
        class = addon.HUNTER,
        spec = { specID.BEASTMASTERY, specID.SURVIVAL },
        category = category.INTERRUPT,
        cooldown = 24,
        baseline = true,
    },
    -- Deterrence
    [19263] = {
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
        charges = true,
    },
    -- Feign Death
    [5384] = {
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        cooldown = 30,
        baseline = true,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
    -- Master's Call
    [53271] = {
        class = addon.HUNTER,
        category = category.OTHERS,
        cooldown = 45,
        trackPet = true,
    },
    -- Rapid Fire
    [3045] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 180,
        duration = 15,
        baseline = true,
    },
    -- Scatter Shot
    [19503] = {
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        cooldown = 30,
        baseline = true,
    },
    -- Stampede (bugged)
    [121818] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 300,
        duration = 20,
        baseline = true,
    },
    -- Explosive Trap
    [13813] = {
        class = addon.HUNTER,
        category = category.KNOCKBACK,
        cooldown = 30,
        baseline = true,
    },
        -- Explosive Trap (Trap Launcher)
        [82939] = {
            parent = 13813,
            use_parent_icon = true,
        },
    -- Freezing Trap
    [1499] = {
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        cooldown = 30,
        baseline = true,
    },
        -- Freezing Trap (Trap Launcher)
        [60192] = {
            parent = 1499,
            use_parent_icon = true,
        },
    -- Ice Trap
    [13809] = {
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        cooldown = 30,
        baseline = true,
    },
        -- Ice Trap (Trap Launcher)
        [82941] = {
            parent = 13809,
            use_parent_icon = true,
        },
    -- Bining Shot
    [109248] = {
        class = addon.HUNTER,
        category = category.STUN,
        cooldown = 45,
    },
    -- Wyvern Sting
    [19386] = {
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        cooldown = 45,
    },
    -- Intimidation
    [19577] = {
        class = addon.HUNTER,
        category = category.STUN,
        cooldown = 60,
    },
    -- Exhilaration
    [109304] = {
        class = addon.HUNTER,
        category = category.HEAL,
        cooldown = 120,
    },
    -- A Murder of Crows
    [131894] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 120,
        duration = 30,
    },
    -- Lynx Rush
    [120697] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 90,
        duration = 4,
    },
    -- Powershot
    [109259] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 45,
    },
    -- Snake Trap
    [34600] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = { default = 30, [specID.SURVIVAL] = 24 },
        baseline = true,
    },
    -- Beast Mastery
    -- Bestial Wrath
    [19574] = {
        class = addon.HUNTER,
        spec = { specID.BEASTMASTERY },
        category = category.BURST,
        cooldown = 60,
        duration = 10,
        baseline = true,
    },
    -- Marksmanship
    -- Silencing Shot
    [34490] = {
        class = addon.HUNTER,
        spec = { specID.MARKSMANSHIP },
        category = category.SILENCE,
        cooldown = 24,
        baseline = true,
    },
    -- Disengage
    [781] = {
        class = addon.HUNTER,
        category = category.OTHERS,
        cooldown = 20,
        baseline = true,
    },
    -- Flare
    [1543] = {
        class = addon.HUNTER,
        category = category.OTHERS,
        cooldown = 20,
        baseline = true,
    },
    -- Roar of Sacrifice
    [53480] = {
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        cooldown = 60,
        trackPet = true,
    },

    -- Mage
    -- Incanter's Ward
    [1463] = {
        class = addon.MAGE,
        category = category.OTHERS,
        cooldown = 25,
    },
    -- Alter Time
    [110909] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 90, -- 180s baseline and 90s reduction from tier set
        baseline = true,
        trackEvent = addon.SPELL_AURA_APPLIED,
    },
    -- Blink
    [1953] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 15,
        baseline = true,
    },
    -- Counterspell
    [2139] = {
        class = addon.MAGE,
        category = category.INTERRUPT,
        cooldown = 24,
        baseline = true,
        reduce_on_interrupt = 4,
    },
    -- Deep Freeze
    [44572] = {
        class = addon.MAGE,
        category = category.STUN,
        cooldown = 30,
        baseline = true,
    },
    -- Evocation
    [12051] = {
        class = addon.MAGE,
        category = category.OTHERS,
        cooldown = 120,
        baseline = true,
    },
    -- Ice Block
    [45438] = {
        class = addon.MAGE,
        category = category.IMMUNITY,
        cooldown = 300,
        baseline = true,
    },
    -- Cold Snap
    [11958] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Remove Curse
    [475] = {
        class = addon.MAGE,
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Presence of Mind
    [12043] = {
        class = addon.MAGE,
        category = category.BURST,
        cooldown = 90,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
    -- Temporal Shield
    [115610] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 25,
    },
    -- Ice Barrier
    [11426] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 25,
    },
    -- Ring of Frost
    [113724] = {
        class = addon.MAGE,
        category = category.CROWDCONTROL,
        cooldown = 45,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
        -- Ring of frost with PoM
        [140376] = {
            parent = 113724,
            use_parent_icon = true,
        },
    -- Frostjaw
    [102051] = {
        class = addon.MAGE,
        category = category.SILENCE,
        cooldown = 20,
    },
    -- Frost Nova
    [122] = {
        class = addon.MAGE,
        category = category.CROWDCONTROL,
        cooldown = 25,
        baseline = true,
    },
    -- Cauterize (almost never picked since on the same node with Code Snap)
    -- [87024] = {
    --     class = addon.MAGE,
    --     category = category.DEFENSIVE,
    --     cooldown = 120,
    --     trackEvent = addon.SPELL_AURA_APPLIED,
    -- },
    -- Fire
    -- Combustion
    [11129] = {
        class = addon.MAGE,
        spec = { specID.FIRE },
        category = category.BURST,
        cooldown = 45,
        duration = 3,
        baseline = true,
    },
    -- Dragon's Breath
    [31661] = {
        class = addon.MAGE,
        spec = { specID.FIRE },
        category = category.CROWDCONTROL,
        cooldown = 20,
        baseline = true,
    },
    -- Arcane
    -- Arcane Power
    [12042] = {
        class = addon.MAGE,
        spec = { specID.ARCANE },
        category = category.BURST,
        cooldown = 90,
        duration = 15,
        baseline = true,
    },
    -- Frost
    -- Icy Veins
    [12472] = {
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.BURST,
        cooldown = 180,
        duration = 20,
        baseline = true,
    },
    -- Frozen Orb
    [84714] = {
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.BURST,
        cooldown = 60,
        duration = 10,
        baseline = true,
    },
    -- Freeze (Water Elemental)
    [33395] = {
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.CROWDCONTROL,
        cooldown = 25,
        trackPet = true,
    },
    -- Summon Water Elemental
    [31687] = {
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
    },

    -- Monk
    -- Roll
    [109132] = {
        class = addon.MONK,
        category = category.MOBILITY,
        cooldown = 20,
        baseline = true,
        charges = true,
    },
    -- Detox
    [115450] = {
        class = addon.MONK,
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Fortifying Brew
    [115203] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Grapple Weapon
    [117368] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Nimble Brew
    [137562] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
    },
    -- Paralysis
    [115078] = {
        class = addon.MONK,
        category = category.CROWDCONTROL,
        cooldown = 15,
        baseline = true,
    },
    -- Spear Hand Strike
    [116705] = {
        class = addon.MONK,
        category = category.INTERRUPT,
        cooldown = 15,
        baseline = true,
    },
    -- Tiger's Lust
    [116841] = {
        class = addon.MONK,
        category = category.OTHERS,
        cooldown = 30,
        baseline = true,
    },
    -- Touch of Death
    [115080] = {
        class = addon.MONK,
        category = category.BURST,
        cooldown = 90,
        baseline = true,
    },
    -- Transcendence: Transfer
    [119996] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 25,
        baseline = true,
    },
    -- Zen Meditation
    [115176] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Leg Sweep
    [119381] = {
        class = addon.MONK,
        category = category.STUN,
        cooldown = 45,
    },
    -- Ring of Peace
    [116844] = {
        class = addon.MONK,
        category = category.KNOCKBACK,
        cooldown = 45,
    },
    -- Dampen Harm
    [122278] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Diffuse Magic
    [122783] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Invoke Xuen, the White Tiger
    [123904] = {
        class = addon.MONK,
        category = category.BURST,
        cooldown = 180,
        duration = 45,
    },
    -- Charging Ox Wave
    [119392] = {
        class = addon.MONK,
        category = category.CROWDCONTROL,
        cooldown = 30,
    },
    -- Windwalker
    -- Flying Serpent Kick
    [101545] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.MOBILITY,
        cooldown = 25,
        baseline = true,
    },
    -- Energizing Brew
    [115288] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.BURST,
        cooldown = 60,
        baseline = true,
    },
    -- Touch of Karma
    [122470] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.DEFENSIVE,
        cooldown = 90,
        baseline = true,
    },
    -- Fists of Fury
    [113656] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.STUN,
        cooldown = 25,
        baseline = true,
    },
    -- Mistweaver
    -- Life Cocoon
    [116849] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
    },
    -- Revival
    [115310] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
    },
    -- Symbiosis/Bear Hug
    [127361] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.STUN,
        cooldown = 60,
    },
    -- Dematerialize
    [122465] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.IMMUNITY,
        cooldown = 10,
    },
    -- Thunder Focus Tea
    [116680] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        cooldown = 45,
    },

    -- Paladin
    -- Avenging Wrath
    [31884] = {
        class = addon.PALADIN,
        category = category.BURST,
        cooldown = 180,
        duration = 20,
        baseline = true,
    },
    -- Blindiong Light
    [115750] = {
        class = addon.PALADIN,
        category = category.CROWDCONTROL,
        cooldown = 120,
        baseline = true,
    },
    -- Cleanse
    [4987] = {
        class = addon.PALADIN,
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Devotion Aura
    [31821] = {
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Divine Protection
    [498] = {
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Divine Shield
    [642] = {
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        cooldown = 300,
        baseline = true,
    },
    -- Hammer of Justice
    [853] = {
        class = addon.PALADIN,
        category = category.STUN,
        cooldown = 60,
        baseline = true,
    },
        -- Fist of Justice
        [105593] = {
            parent = 853,
            use_parent_icon = true,
            cooldown = 30,
        },
    -- Hand of Freedom
    [1044] = {
        class = addon.PALADIN,
        category = category.OTHERS,
        cooldown = 25,
        baseline = true,
    },
    -- Hand of Protection
    [1022] = {
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        cooldown = 300,
        baseline = true,
    },
    -- Rebuke
    [96231] = {
        class = addon.PALADIN,
        category = category.INTERRUPT,
        cooldown = 15,
        baseline = true,
    },
    -- Hand of Sacrifice (need test)
    [6940] = {
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
    },
    -- Holy
    -- Divine Favor
    [31842] = {
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Divine Plea
    [54428] = {
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.OTHERS,
        cooldown = 120,
        baseline = true,
    },
    -- Guardian of Ancient Kings
    [86669] = {
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
    -- Protection
    -- Ardent Defender
    -- [31850] = {
    --     class = addon.PALADIN,
    --     spec = { specID.PROTECTION_PALADIN },
    --     category = category.DEFENSIVE,
    --     cooldown = 180,
    --     baseline = true,
    -- },
    -- Guardian of Ancient Kings
    -- [86659] = {
    --     class = addon.PALADIN,
    --     spec = { specID.PROTECTION_PALADIN },
    --     category = category.DEFENSIVE,
    --     cooldown = 180,
    --     baseline = true,
    --     trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    -- },
    -- Retribution
    -- Guardian of Ancient Kings
    [86698] = {
        class = addon.PALADIN,
        spec = { specID.RETRIBUTION },
        category = category.BURST,
        cooldown = 180,
        duration = 30,
        baseline = true,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
    -- Symbiosis/Barkskin
    -- [113075] = {
    --     class = addon.PALADIN,
    --     spec = { specID.PROTECTION_PALADIN },
    --     category = category.DEFENSIVE,
    --     cooldown = 60,
    -- },

    -- Priest
    -- Shadow Word: Death
    [32379] = {
        class = addon.PRIEST,
        category = category.OTHERS,
        cooldown = 8,
        baseline = true,
    },
        [129176] = {
            parent = 32379,
            use_parent_icon = true,
        },
    -- Void Tendrils
    [108920] = {
        class = addon.PRIEST,
        category = category.OTHERS,
        cooldown = 30,
    },
    -- Psyfiend
    [108921] = {
        class = addon.PRIEST,
        category = category.BURST,
        cooldown = 45,
    },
    -- Fear Ward
    [6346] = {
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        cooldown = 180,
        opt_lower_cooldown = 120,
        baseline = true,
    },
    -- Hymn of Hope
    [64901] = {
        class = addon.PRIEST,
        category = category.OTHERS,
        cooldown = 360,
        baseline = true,
    },
    -- Leap of Faith (need test)
    [73325] = {
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        cooldown = 90,
        baseline = true,
    },
    -- Mass Dispel
    [32375] = {
        class = addon.PRIEST,
        category = category.DISPEL,
        cooldown = 15,
        baseline = true,
    },
    -- Mindbender
    [123040] = {
        class = addon.PRIEST,
        category = category.BURST,
        cooldown = 60,
        duration = 15,
    },
    -- Desperate Prayer
    [19236] = {
        class = addon.PRIEST,
        category = category.HEAL,
        cooldown = 120,
    },
    -- Spectral Guise
    [112833] = {
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        cooldown = 30,
    },
    -- Psychic Scream
    [8122] = {
        class = addon.PRIEST,
        category = category.CROWDCONTROL,
        cooldown = 27,
        baseline = true,
    },
    -- Purify
    [527] = {
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE, specID.HOLY_PRIEST },
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Void Shift (need test)
    [108968] = {
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE, specID.HOLY_PRIEST },
        category = category.OTHERS,
        cooldown = 300,
        baseline = true,
    },
    -- Power Infusion
    [10060] = {
        class = addon.PRIEST,
        category = category.BURST,
        cooldown = 120,
        duration = 20,
        baseline = true,
    },
    -- Discipline
    -- Archangel
    [81700] = {
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.HEAL,
        cooldown = 30,
        baseline = true,
    },
    -- Inner Focus
    [89485] = {
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        cooldown = 45,
        baseline = true,
    },
    -- Pain Suppression
    [33206] = {
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Power Word: Barrier
    [62618] = {
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Spirit Shell
    [109964] = {
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Holy
    -- Divine Hymn
    [64843] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
    },
    -- Guardian Spirit
    [47788] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
    },
    -- Holy Word: Chastise
    [88625] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.CROWDCONTROL,
        cooldown = 30,
        baseline = true,
    },
    -- Lightwell
    [126135] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
    },
    -- Shadow
    -- Dispersion
    [47585] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
    },
    -- Psychic Horror
    [64044] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.STUN,
        cooldown = 45,
        baseline = true,
    },
    -- Silence
    [15487] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.SILENCE,
        cooldown = 45,
        baseline = true,
    },
    -- Vampiric Embrace
    [15286] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
    },

    -- Rogue
    -- Redirect
    [73981] = {
        class = addon.ROGUE,
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
    },
    -- Blind
    [2094] = {
        class = addon.ROGUE,
        category = category.CROWDCONTROL,
        cooldown = 120,
        baseline = true,
    },
    -- Cloak of Shadows
    [31224] = {
        class = addon.ROGUE,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Dismantle
    [51722] = {
        class = addon.ROGUE,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Evasion
    [5277] = {
        class = addon.ROGUE,
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
    },
    -- Gouge
    [1776] = {
        class = addon.ROGUE,
        category = category.CROWDCONTROL,
        cooldown = 10,
        baseline = true,
    },
    -- Kick
    [1766] = {
        class = addon.ROGUE,
        category = category.INTERRUPT,
        cooldown = 15,
        baseline = true,
    },
    -- Kidney Shot
    [408] = {
        class = addon.ROGUE,
        category = category.STUN,
        cooldown = 20,
        baseline = true,
    },
    -- Preparation
    [14185] = {
        class = addon.ROGUE,
        category = category.OTHERS,
        cooldown = 300,
        baseline = true,
    },
    -- Shadow Blades
    [121471] = {
        class = addon.ROGUE,
        category = category.BURST,
        cooldown = 180,
        duration = 12,
        baseline = true,
    },
    -- Shroud of Concealment
    [114018] = {
        class = addon.ROGUE,
        category = category.OTHERS,
        cooldown = 300,
        baseline = true,
    },
    -- Smoke Bomb
    [76577] = {
        class = addon.ROGUE,
        category = category.OTHERS,
        cooldown = 180,
        baseline = true,
    },
    -- Sprint
    [2983] = {
        class = addon.ROGUE,
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
    },
    -- Vanish
    [1856] = {
        class = addon.ROGUE,
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
    },
    -- Combat Readiness
    [74001] = {
        class = addon.ROGUE,
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Shadowstep
    [36554] = {
        class = addon.ROGUE,
        category = category.OTHERS,
        cooldown = 20,
        baseline = true,
    },
    -- Marked for Death
    [137619] = {
        class = addon.ROGUE,
        category = category.BURST,
        cooldown = 60,
    },
    -- Subtlety
    -- Shadow Dance
    [51713] = {
        class = addon.ROGUE,
        spec = { specID.SUBTLETY },
        category = category.BURST,
        cooldown = 60,
        duration = 8,
        baseline = true,
    },
    -- Assassination
    -- Vendetta
    [79140] = {
        class = addon.ROGUE,
        spec = { specID.ASSASSINATION },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
        baseline = true,
    },
    -- Combat (Outlaw)
    -- Adrenaline Rush
    [13750] = {
        class = addon.ROGUE,
        spec = { specID.OUTLAW },
        category = category.BURST,
        cooldown = 180,
        duration = 15,
        baseline = true,
    },
    -- Killing Spree
    [51690] = {
        class = addon.ROGUE,
        spec = { specID.OUTLAW },
        category = category.BURST,
        cooldown = 120,
        baseline = true,
    },

    -- Shaman
    -- Capacitor Totem
    [108269] = {
        class = addon.SHAMAN,
        category = category.STUN,
        cooldown = 45,
        baseline = true,
    },
    -- Grounding Totem
    [8177] = {
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        cooldown = 25,
        baseline = true,
    },
    -- Tremor Totem
    [8143] = {
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Ascendance
    [114049] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 180,
        duration = 15,
        baseline = true,
    },
    -- Fire Elemental Totem
    [2894] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 300,
        duration = 60,
        baseline = true,
    },
    -- Hex
    [51514] = {
        class = addon.SHAMAN,
        category = category.CROWDCONTROL,
        cooldown = 35, -- 45s baseline, 10s reduction with Glyph of Hex
        baseline = true,
    },
    -- Spiritwalker's Grace
    [79206] = {
        class = addon.SHAMAN,
        category = category.OTHERS,
        cooldown = 120,
        baseline = true,
    },
    -- Healing Tide Totem
    [108280] = {
        class = addon.SHAMAN,
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
    },
    -- Mana Tide Totem
    [16190] = {
        class = addon.SHAMAN,
        category = category.OTHERS,
        cooldown = 180,
        baseline = true,
    },
    -- Shamanistic Rage
    [30823] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT, specID.ELEMENTAL },
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Wind Shear
    [57994] = {
        class = addon.SHAMAN,
        category = category.INTERRUPT,
        cooldown = 12,
        baseline = true,
    },
    -- Stone Bulwark Totem
    [108270] = {
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Astral Shift
    [108271] = {
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Earthgrab Totem
    [51485] = {
        class = addon.SHAMAN,
        category = category.OTHERS,
        cooldown = 30,
    },
    -- Call of the Elements
    [108285] = {
        class = addon.SHAMAN,
        category = category.OTHERS,
        cooldown = 180,
    },
    -- Elemental Mastery
    [16166] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 120,
        duration = 20,
    },
    -- Ancestral Swiftness
    [16188] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 90,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
    -- Ancestral Guidance
    [108281] = {
        class = addon.SHAMAN,
        category = category.OTHERS,
        cooldown = 120,
    },
    -- Windwalk Totem
    [108273] = {
        class = addon.SHAMAN,
        category = category.OTHERS,
        cooldown = 60,
    },
    -- Stormlash Totem
    [120668] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 300,
    },
    -- Healing Stream Totem
    [5394] = {
        class = addon.SHAMAN,
        category = category.HEAL,
        cooldown = 30,
        baseline = true,
    },
    -- Elemental
    -- Restoration
    -- Spirit Link Totem
    [98008] = {
        class = addon.SHAMAN,
        spec = { specID.RESTORATION_SHAMAN },
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Purify Spirit
    [77130] = {
        class = addon.SHAMAN,
        spec = { specID.RESTORATION_SHAMAN },
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Elemental
    -- Thunderstorm
    [51490] = {
        class = addon.SHAMAN,
        spec = { specID.ELEMENTAL },
        category = category.KNOCKBACK,
        cooldown = 22.5, -- 45s baseline, 22.5s from PvP set bonus
        baseline = true,
    },
    -- Enhancement
    -- Spirit Walk
    [58875] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
    },
    -- Feral Spirit
    [51533] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        cooldown = 120,
        duration = 30,
        baseline = true,
    },
    -- Symbiosis/Solar Beam
    [113286] = {
        class = addon.SHAMAN,
        spec = { specID.ELEMENTAL, specID.ENHANCEMENT },
        category = category.SILENCE,
        cooldown = 60,
    },

    -- Warlock
    -- Blood Horror
    [111397] = {
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
        cooldown = 30,
    },
    -- Demonic Circle: Teleport
    [48020] = {
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
        cooldown = 30,
        baseline = true,
    },
    -- Howl of Terror
    [5484] = {
        class = addon.WARLOCK,
        category = category.CROWDCONTROL,
        cooldown = 40,
        baseline = true,
    },
    -- Unending Resolve
    [104773] = {
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Dark Regeneration
    [108359] = {
        class = addon.WARLOCK,
        category = category.HEAL,
        cooldown = 120,
    },
    -- Mortal Coil
    [6789] = {
        class = addon.WARLOCK,
        category = category.HEAL,
        cooldown = 45,
    },
    -- Shadowfury
    [30283] = {
        class = addon.WARLOCK,
        category = category.STUN,
        cooldown = 30,
    },
    -- Saceificial Pact
    [108416] = {
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Dark Bargain
    [110913] = {
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
        cooldown = 180,
    },
    -- Unbound Will
    [108482] = {
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Grimoire of Service (Felhunter)
    [111897] = {
        class = addon.WARLOCK,
        category = category.INTERRUPT,
        cooldown = 120,
    },
    -- Spell Lock (Command Demon Ability)
    [19647] = {
        cooldown = 24,
        class = addon.WARLOCK,
        trackPet = true,
        category = category.INTERRUPT,
    },
        -- Spell Lock (Special Ability)
        [119910] = {
            parent = 19647,
            use_parent_icon = true,
        },
        -- Optical Blast (Command Demon)
        [119911] = {
            parent = 19647,
            use_parent_icon = true,
        },
        -- Optical Blast (Observer)
        [115781] = {
            parent = 19647,
            use_parent_icon = true,
        },

        -- Grimoire of Sacrifice
        [132409] = {
            parent = 19647,
            -- Do NOT share icon with Spell Lock
        },
    -- Demonology
    -- Dark Soul: Knowledge
    [113861] = {
        class = addon.WARLOCK,
        spec = { specID.DEMONOLOGY },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
        baseline = true,
    },
    -- Affliction
    -- Dark Soul: Misery
    [113860] = {
        class = addon.WARLOCK,
        spec = { specID.AFFLICTION },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
        baseline = true,
    },
    -- Destruction
    -- Dark Soul: Instability
    [113858] = {
        class = addon.WARLOCK,
        spec = { specID.DESTRUCTION },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
        baseline = true,
    },
    -- Flame of Xoroth
    [120451] = {
        class = addon.WARLOCK,
        spec = { specID.DESTRUCTION },
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
    },

    -- Warrior
    -- Berserker Rage
    [18499] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 30,
        baseline = true,
    },
    -- Charge
    [100] = {
        class = addon.WARRIOR,
        category = category.OTHERS,
        cooldown = 20,
        baseline = true,
        opt_charges = true,
    },
    -- Colossus Smash
    [86346] = {
        class = addon.WARRIOR,
        spec = { specID.ARMS, specID.FURY },
        category = category.BURST,
        cooldown = 20,
        duration = 6,
        baseline = true,
    },
    -- Commanding Shout
    [469] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Die by the Sword
    [118038] = {
        class = addon.WARRIOR,
        spec = { specID.ARMS, specID.FURY },
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
    },
    -- Disarm
    [676] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Heroic Leap
    [6544] = {
        class = addon.WARRIOR,
        category = category.OTHERS,
        cooldown = 45,
        opt_lower_cooldown = 30,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
        baseline = true,
    },
    -- Intervene
    [3411] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 30,
        baseline = true,
    },
        -- Safeguard (need test)
        [114029] = {
            parent = 3411,
            use_parent_icon = true,
        },
    -- Intimidating Shout
    [5246] = {
        class = addon.WARRIOR,
        category = category.CROWDCONTROL,
        cooldown = 90,
        baseline = true,
    },
    -- Pummel
    [6552] = {
        class = addon.WARRIOR,
        category = category.INTERRUPT,
        cooldown = 15,
        baseline = true,
    },
    -- Rallying Cry
    [97462] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Recklessness
    [1719] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 180,
        duration = 12,
        baseline = true,
    },
    -- Shattering Throw
    [64382] = {
        class = addon.WARRIOR,
        category = category.OTHERS,
        cooldown = 300,
        baseline = true,
    },
    -- Shield Wall
    [871] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Spell Reflection
    [23920] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 25,
        opt_lower_cooldown = 20, -- Glyph of Spell Reflection
        baseline = true,
    },
    -- Demoralizing Banner
    [114203] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Skull Banner
    [114207] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 180,
        duration = 10,
        baseline = true,
    },
    -- Enraged Regeneration
    [55694] = {
        class = addon.WARRIOR,
        category = category.HEAL,
        cooldown = 60,
    },
    -- Disrupting Shout
    [102060] = {
        class = addon.WARRIOR,
        category = category.INTERRUPT,
        cooldown = 40,
    },
    -- Bladestorm
    [46924] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 60,
        duration = 6,
    },
    -- Shockwave
    [46968] = {
        class = addon.WARRIOR,
        category = category.STUN,
        cooldown = 40,
    },
    -- Dragon Roar
    [118000] = {
        class = addon.WARRIOR,
        category = category.KNOCKBACK,
        cooldown = 60,
    },
    -- Mass Spell Reflection
    [114028] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Vigilance (need test)
    [114030] = {
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Avatar
    [107574] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 180,
        duration = 24,
    },
    -- Bloodbath
    [12292] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 60,
        duration = 12,
    },
    -- Storm Bolt
    [107570] = {
        class = addon.WARRIOR,
        category = category.STUN,
        cooldown = 30,
    },
    -- Staggering Shout
    [107566] = {
        class = addon.WARRIOR,
        category = category.OTHERS,
        cooldown = 40,
    },
};

addon.SpellResets = {
    -- Cold Snap
    [11958] = {
        45438, -- Ice Block
    },

    -- Call of the Elements
    [108285] = {
        108269, -- Capacitor Totem
        8177, -- Grounding Totem
        108270, -- Stone Bulwark Totem
        51485, -- Earthgrab Totem
        8143, -- Tremor Totem
    },

    -- Preparation
    [14185] = {
        2983, -- Sprint
        1856, -- Vanish
        5277, -- Evasion
        51722, -- Dismantle
    },
};

addon.SpellResetsAffectedByApotheosis = {};

for _, spell in pairs(addon.SpellData) do
    -- Fill default glow duration for burst abilities
    if spell.category == category.BURST and ( not spell.duration ) then
        spell.duration = 3;
    end
end

for _, spell in pairs(addon.SpellData) do
    -- Fill options from parent
    if spell.parent then
        local parent = addon.SpellData[spell.parent];

        spell.cooldown = spell.cooldown or parent.cooldown;
        spell.duration = spell.duration or parent.duration;
        spell.class = spell.class or parent.class;
        spell.spec = spell.spec or parent.spec;
        spell.category = spell.category or parent.category;
        spell.trackPet = spell.trackPet or parent.trackPet;
        spell.trackEvent = spell.trackEvent or parent.trackEvent;
        spell.baseline = spell.baseline or parent.baseline;
        spell.index = spell.index or parent.index;
        spell.default = spell.default or parent.default;
    end
end
