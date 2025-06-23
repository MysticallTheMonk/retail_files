local _, addon = ...;

local POWERTYPE = Enum.PowerType;
local specID = addon.SPECID;
local category = addon.SPELLCATEGORY;

-- charges: baseline 2 charges
-- opt_charges: optionally 2 charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind, priest fear

addon.SpellData = {
    -- General

    -- Death Knight
    -- Abomination Limb
    [383269] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 120,
        duration = 12,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Unholy
    -- Raise Abomination
    [455395] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 90,
        duration = 30,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Unholy Assult
    [207289] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 90,
        duration = 20,
    },
    -- Dark Transformation
    [63560] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 45,
        duration = 15, -- extended by Eternal Agony (need to track buff on pet, is it feasible)
        baseline = true,
    },
    -- Apocalypse
    [275699] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 45,
        duration = 20,
    },
    -- Summon Gargoyle
    [49206] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 180,
        duration = 25,
    },
    -- Frost
    -- Remorseless Winter
    [196770] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 20,
        duration = 8,
        extend = true, -- Gathering Storm
        baseline = true,
    },
    -- Pillar of Frost
    [51271] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 60,
        duration = 12,
        baseline = true,
        default = true,
    },
    -- Absolute zero (Frostwyrm's Fury)
    [279302] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 90,
        duration = 10,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Empower Rune Weapon
    [47568] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
    },
    -- Chill Streak
    [305392] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 45,
        duration = 4,
    },
    -- Interrupt
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
    -- Disrupt
    -- Death Grip
    [49576] = {
        class = addon.DEATHKNIGHT,
        category = category.OTHERS,
        cooldown = 25,
        charges = true, -- Death's Echo is almost always picked
        baseline = true,
    },
    -- Crowd Control
    -- Strangulate
    [47476] = {
        class = addon.DEATHKNIGHT,
        category = category.SILENCE,
        cooldown = 45,
    },
    -- Blinding Sleet
    [207167] = {
        class = addon.DEATHKNIGHT,
        category = category.CROWDCONTROL,
        cooldown = 60,
    },
    -- Asphyxiate
    [221562] = {
        class = addon.DEATHKNIGHT,
        category = category.STUN,
        cooldown = 45,
    },
    -- Dark Simulacrum
    [77606] = {
        class = addon.DEATHKNIGHT,
        category = category.OTHERS,
        cooldown = 20,
    },
    -- Gnaw
    [47481] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.CROWDCONTROL,
        cooldown = 90,
        trackPet = true,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
        baseline = true,
    },
    -- Defensive
    -- Icebound Fortitude
    [48792] = {
        class = addon.DEATHKNIGHT,
        category = category.IMMUNITY,
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
    -- Anti-Magic Shell
    [48707] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 40, -- Anti-Magic Barrier almost always picked
        default = true,
        -- Not set as baseline, since it can be replaced by Spellwarden
    },
        -- Anti-Magic Shell (Spellwarden)
        [410358] = {
            parent = 48707,
            cooldown = 30,
        },
    -- Anti-Magic Zone
    [51052] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
        opt_lower_cooldown = 90, -- Assimilation
        default = true,
    },
    -- Lichborne
    [49039] = {
        class = addon.DEATHKNIGHT,
        category = category.IMMUNITY,
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
    -- Death Pact
    [48743] = {
        class = addon.DEATHKNIGHT,
        category = category.HEAL,
        cooldown = 120,
    },
    -- Sacrificial Pact
    [327574] = {
        class = addon.DEATHKNIGHT,
        category = category.HEAL,
        cooldown = 120,
    },

    -- Demon Hunter
    -- Eye Beam
    [198013] = {
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.BURST,
        cooldown = 40,
        index = addon.SPELLPRIORITY.LOW,
        baseline = true,
        -- Cooldown reduced by Blade dance, Chaos Strike, Glaive Tempest
        -- Cooldown reset by activating Metamorphosis
    },
    -- The Hunt
    [370965] = {
        class = addon.DEMONHUNTER,
        category = category.BURST,
        cooldown = 90,
        baseline = true,
    },
    -- Metamorphosis (have to track with UNIT_SPELLCAST_SUCCEEDED to exclude auto proc from Eye Beam)
    [191427] = {
        class = addon.DEMONHUNTER,
        category = category.BURST,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
        cooldown = 120,
        duration = 20,
        baseline = true,
        default = true,
    },
    -- Essence Break
    [258860] = {
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.BURST,
        cooldown = 40,
        duration = 4,
    },
    -- Fel Barrage
    [258925] = {
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.BURST,
        cooldown = 90,
        duration = 8,
    },
    -- Rain from Above
    [206803] = {
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.IMMUNITY,
        cooldown = 90,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
    -- Sigil of Spite
    [390163] = {
        class = addon.DEMONHUNTER,
        category = category.BURST,
        cooldown = 60,
    },
    -- Interrupt
    -- Disrupt
    [183752] = {
        class = addon.DEMONHUNTER,
        category = category.INTERRUPT,
        cooldown = 15,
        baseline = true,
    },
    -- Defensive
    -- Blur
    [198589] = {
        cooldown = 60,
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.DEFENSIVE,
        baseline = true,
        default = true,
    },
    -- Netherwalk
    [196555] = {
        cooldown = 180,
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.DEFENSIVE,
        baseline = true,
        default = true,
    },
    -- Darkness
    [196718] = {
        cooldown = 180,
        class = addon.DEMONHUNTER,
        category = category.DEFENSIVE,
        baseline = true,
        default = true,
    },
    -- Reverse Magic
    [205604] = {
        cooldown = 60,
        class = addon.DEMONHUNTER,
        category = category.DEFENSIVE,
        default = true,
    },
    -- Crowd Control
    -- Imprison
    [217832] = {
        cooldown = 45,
        class = addon.DEMONHUNTER,
        category = category.CROWDCONTROL,
    },
    -- Imprison (Detainment)
    [221527] = {
        parent = 217832,
    },
    -- Fel Eruption
    [211881] = {
        cooldown = 30,
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.STUN,
        baseline = true,
    },
    -- Chaos Nova
    [179057] = {
        cooldown = 45,
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.STUN,
        baseline = true,
    },
    -- Sigil of Misery
    [207684] = {
        cooldown = 90,
        class = addon.DEMONHUNTER,
        category = category.CROWDCONTROL,
        baseline = true,
    },
    -- Others
    -- Consume Magic
    [278326] = {
        cooldown = 10,
        class = addon.DEMONHUNTER,
        category = category.OTHERS,
        baseline = true,
    },
    -- Vengeful Retreat
    [198793] = {
        class = addon.DEMONHUNTER,
        category = category.OTHERS,
        cooldown = { default = 20, [specID.VENGEANCE] = 25 },
        baseline = true,
    },

    -- Druid
    -- Convoke the Spirits
    [391528] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 60,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Balance
    -- Incarnation: Chosen of Elune
    [102560] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 100, -- Whirling Stars
        duration = 16,
        charges = true, -- Whirling Stars
        index = addon.SPELLPRIORITY.HIGH,
        default = true,
    },
        -- Incarnation: Chosen of Elune (Orbital Strike)
        [390414] = {
            parent = 102560,
            cooldown = 120,
            duration = 20,
        },
    -- Celestial Alignment
    [194223] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 100, -- Whirling Stars
        duration = 12,
        charges = true, -- Whirling Stars
        index = addon.SPELLPRIORITY.HIGH,
        default = true,
    },
        -- Celestial Alignment (Orbital Strike)
        [383410] = {
            parent = 194223,
            cooldown = 120,
            duration = 15,
        },
    -- Force of Nature
    [205636] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 60,
        duration = 10,
    },
    -- Fury of Elune
    [202770] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 60,
        duration = 8,
    },
    -- Feral
    -- Berserk
    [106951] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
        default = true,
    },
    -- Incarnation: Avatar of Ashamane
    [102543] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
        default = true,
    },
    -- Feral Frenzy
    [274837] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 45,
    },
    -- Tiger's Fury
    [5217] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 30,
        duration = 20, -- can end early
        index = addon.SPELLPRIORITY.LOW,
    },
    -- Crowd Control
    -- Mighty Bash
    [5211] = {
        cooldown = 60,
        class = addon.DRUID,
        category = category.STUN
    },
    -- Maim
    [22570] = {
        cooldown = 20,
        class = addon.DRUID,
        category = category.STUN
    },
    -- Incapacitating Roar
    [99] = {
        cooldown = 30,
        class = addon.DRUID,
        category = category.CROWDCONTROL
    },
    -- Solar Beam
    [78675] = {
        cooldown = 60,
        class = addon.DRUID,
        spec = { specID.BALANCE },
        reduce_on_interrupt = 15,
        category = category.SILENCE,
        baseline = true,
    },
    -- Mass Entanglement
    [102359] = {
        cooldown = 30,
        class = addon.DRUID,
        category = category.CROWDCONTROL,
    },
    -- Ursol's Vortex
    [102793] = {
        cooldown = 60,
        class = addon.DRUID,
        category = category.CROWDCONTROL,
    },
    -- Disrupt
    -- Faerie Swarm
    [209749] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.SILENCE,
        cooldown = 30,
    },
    -- Typhoon
    [132469] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 30,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
    },
    -- Innervate
    [29166] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 180,
    },
    -- Interrupt
    -- Skull Bash
    [106839] = {
        cooldown = 15,
        class = addon.DRUID,
        category = category.INTERRUPT
    },
    -- Defensive
    -- Survival Instincts
    [61336] = {
        cooldown = {default = 180, [specID.GUARDIAN] = 120},
        class = addon.DRUID,
        spec = { specID.GUARDIAN, specID.FERAL },
        charges = {[specID.GUARDIAN] = true},
        category = category.DEFENSIVE,
        baseline = true,
        default = true,
    },
    -- Ironbark
    [102342] = {
        cooldown = 90,
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        opt_lower_cooldown = 70,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Barkskin
    [22812] = {
        cooldown = 60,
        class = addon.DRUID,
        category = category.DEFENSIVE,
        baseline = true,
        default = true,
    },
    -- Renewal
    [108238] = {
        cooldown = 90,
        class = addon.DRUID,
        category = category.HEAL,
        baseline = true,
    },
    -- Incarnation: Tree of Life
    [33891] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DEFENSIVE,
        cooldown = 180,
        default = true,
    },
    -- Ancient of Lore
    [473909] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.IMMUNITY,
        cooldown = 90,
        default = true,
    },
    -- Nature's Swiftness
    [132158] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.HEAL,
        cooldown = 48, -- Passing Seasons
        charges = true,
        baseline = true,
    },
    -- Overgrowth
    [203651] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.HEAL,
        cooldown = 60,
    },
    -- Tranquility
    [740] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.HEAL,
        cooldown = 180,
    },
    -- Dispel
    -- Nature's Cure
    [88423] = {
        cooldown = 8,
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },
    -- Remove Corruption
    [2782] = {
        cooldown = 8,
        class = addon.DRUID,
        spec = { specID.FERAL, specID.GUARDIAN, specID.BALANCE },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
    },

    -- Evoker
    -- Devastation
    -- Deep Breath
    [357210] = {
        class = addon.EVOKER,
        category = category.BURST,
        cooldown = 120,
        baseline = true,
    },
    -- Dragon Rage
    [375087] = {
        class = addon.EVOKER,
        spec = { specID.DEVASTATION },
        category = category.BURST,
        duration = 14,
        cooldown = 120,
        extend = true, -- Animosity
        baseline = true,
        default = true,
    },
    -- Tip the Scales
    [370553] = {
        class = addon.EVOKER,
        category = category.BURST,
        cooldown = 120,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Augmentation
    -- Breath of Eons
    [403631] = {
        class = addon.EVOKER,
        spec = { specID.AUGMENTATION },
        category = category.BURST,
        cooldown = 120,
    },
    -- Upheaval
    [396286] = {
        class = addon.EVOKER,
        spec = { specID.AUGMENTATION },
        category = category.BURST,
        cooldown = 40,
        trackEvent = addon.SPELL_EMPOWER_END,
    },
    -- Ebon Might
    [395152] = {
        class = addon.EVOKER,
        spec = { specID.AUGMENTATION },
        category = category.BURST,
        cooldown = 30,
        duration = 10,
        extend = true,
        index = addon.SPELLPRIORITY.LOW,
    },
    -- Defensive
    -- Obsidian Scales
    [363916] = {
        class = addon.EVOKER,
        category = category.DEFENSIVE,
        cooldown = 90,
        charges = true,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Renewing Blaze
    [374348] = {
        class = addon.EVOKER,
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Emerald Communion
    [370960] = {
        class = addon.EVOKER,
        spec = { specID.PRESERVATION },
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Cauterizing Flame
    [374251] = {
        class = addon.EVOKER,
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Nullifying Shroud
    [378464] = {
        class = addon.EVOKER,
        category = category.DEFENSIVE,
        cooldown = 90,
        baseline = true,
        default = true,
    },
    -- Time Stop
    [378441] = {
        class = addon.EVOKER,
        category = category.DEFENSIVE,
        cooldown = 45,
        priority = addon.SPELLPRIORITY.HIGH,
    },
    -- Dream Projection
    [377509] = {
        class = addon.EVOKER,
        spec = { specID.PRESERVATION },
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Time Dilation
    [357170] = {
        class = addon.EVOKER,
        spec = { specID.PRESERVATION },
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Stasis (after 3 casts, aura is removed and cooldown starts, before we press it again or the new aura expires / is purged)
    [370537] = {
        class = addon.EVOKER,
        spec = { specID.PRESERVATION },
        category = category.DEFENSIVE,
        cooldown = 90,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Interrupt
    -- Quell
    [351338] = {
        cooldown = { default = 40, [specID.DEVASTATION] = 20, [specID.AUGMENTATION] = 20 },
        class = addon.EVOKER,
        category = category.INTERRUPT,
        baseline = true, -- technically a talent, but always picked
    },
    -- Crowd Control
    -- Dispel
    -- Naturalize
    [360823] = {
        cooldown = 8,
        class = addon.EVOKER,
        spec = { specID.PRESERVATION },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },
    -- Disrupt
    -- Fire Breath (Scouring Flame which purges 1 buff per empower level)
    -- Issue: Tip the Scales empowered Fire Breath still doesn't trigger cooldown
    [357208] = {
        cooldown = 30,
        class = addon.EVOKER,
        spec = { specID.DEVASTATION, specID.AUGMENTATION },
        category = category.OTHERS,
        trackEvent = addon.SPELL_EMPOWER_END,
        baseline = true,
    },
    -- Fire Breath (Preservation)
    [382266] = {
        cooldown = 30,
        class = addon.EVOKER,
        spec = { specID.PRESERVATION },
        category = category.OTHERS,
        trackEvent = addon.SPELL_EMPOWER_END,
        baseline = true,
    },
    -- Rescue
    [370665] = {
        class = addon.EVOKER,
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
    },
    -- Rewind
    [363534] = {
        class = addon.EVOKER,
        spec = { specID.PRESERVATION },
        category = category.OTHERS,
        cooldown = 240,
        opt_lower_cooldown = 180,
        baseline = true,
    },
    -- Landslide
    [358385] = {
        class = addon.EVOKER,
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
    },
    -- Oppressing Roar
    [406971] = {
        class = addon.EVOKER,
        category = category.OTHERS,
        cooldown = 120,
        opt_lower_cooldown = 90,
    },

    -- Hunter
    -- Beast Mastery
    -- Bestial Wrath
    [19574] = {
        class = addon.HUNTER,
        spec = { specID.BEASTMASTERY },
        category = category.BURST,
        cooldown = 90, -- Reduced by Barbed Shot
        duration = 15,
        baseline = true, -- technically a talent, but always picked
    },
    -- Call of the Wild
    [359844] = {
        class = addon.HUNTER,
        spec = { specID.BEASTMASTERY },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Survival
    -- Coordinated Assult
    [360952] = {
        class = addon.HUNTER,
        spec = { specID.SURVIVAL },
        category = category.BURST,
        cooldown = 60, -- Symboitic Adrenaline (almost always picked)
        duration = 20,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Marksmanship
    -- Trueshot
    [288613] = {
        class = addon.HUNTER,
        spec = { specID.MARKSMANSHIP },
        category = category.BURST,
        cooldown = 120, -- Reduced by spending focus
        duration = 15,
        reduce_power_type = POWERTYPE.Focus,
        reduce_amount = 0.05, -- Every 50 focus reduces cd by 2.5s
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Volley
    [260243] = {
        class = addon.HUNTER,
        spec = { specID.MARKSMANSHIP },
        category = category.BURST,
        cooldown = 45,
        duration = 6,
    },
    -- Disrupt
    -- Feign Death
    [5384] = {
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        cooldown = 30,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
        baseline = true,
    },
    -- Mending Bandage
    [212640] = {
        class = addon.HUNTER,
        spec = { specID.SURVIVAL },
        category = category.OTHERS,
        cooldown = 25,
    },
    -- Tar Trap
    [187698] = {
        class = addon.HUNTER,
        category = category.OTHERS,
        cooldown = 25,
    },
    -- Stick Tar Bomb
    [407028] = {
        class = addon.HUNTER,
        spec = { specID.SURVIVAL },
        category = category.OTHERS,
        cooldown = 45,
    },
    -- Crowd Control
    -- Intimidation
    [19577] = {
        cooldown = 50,
        class = addon.HUNTER,
        category = category.STUN,
        baseline = true,
    },
        -- Intimidation (Marksman)
        [474421] = {
            parent = 19577,
            use_parent_icon = true,
        },
    -- Freezing Trap
    [187650] = {
        cooldown = 25,
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        baseline = true,
    },
    -- Binding Shot
    [109248] = {
        cooldown = 45,
        class = addon.HUNTER,
        category = category.STUN,
        baseline = true,
    },
    -- Scatter Shot
    [213691] = {
        cooldown = 30,
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Chimaeral Sting
    [356719] = {
        cooldown = 60,
        class = addon.HUNTER,
        category = category.SILENCE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Defensive
    -- Survival of the Fittest
    [264735] = {
        cooldown = 90,
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        charges = true,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Aspect of the Turtle
    [186265] = {
        cooldown = 144,
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
    -- Roar of Sacrifice
    [53480] = {
        cooldown = 60,
        class = addon.HUNTER,
        category = category.DEFENSIVE
    },
    -- Exhilaration
    [109304] = {
        cooldown = 120,
        class = addon.HUNTER,
        category = category.HEAL,
    },
    -- Interrupt
    -- Counter Shot
    [147362] = {
        cooldown = 22,
        class = addon.HUNTER,
        spec = { specID.MARKSMANSHIP, specID.BEASTMASTERY },
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Muzzle
    [187707] = {
        cooldown = 13,
        class = addon.HUNTER,
        spec = { specID.SURVIVAL },
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Others
    -- Master's Call
    [53271] = {
        class = addon.HUNTER,
        category = category.OTHERS,
        cooldown = 45,
        trackPet = true,
    },
    -- Harpoon
    [190925] = {
        class = addon.HUNTER,
        spec = { specID.SURVIVAL },
        category = category.OTHERS,
        cooldown = 20,
        baseline = true,
    },
    -- Tranquilizing Shot
    [19801] = {
        class = addon.HUNTER,
        category = category.OTHERS,
        cooldown = 10,
        baseline = true,
    },
    -- High Explosive Trap
    [236776] = {
        class = addon.HUNTER,
        category = category.OTHERS,
        cooldown = 35,
    },

    -- Mage
    -- Frost
    -- Icy Veins (make sure it's not triggered by Time Anomaly)
    [12472] = {
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.BURST,
        cooldown = 120,
        duration = 30,
        index = addon.SPELLPRIORITY.HIGH,
        extend = true,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Ice Form
    [198144] = {
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.BURST,
        cooldown = 60,
        duration = 12,
        extend = true,
    },
    -- Fire
    -- Combustion
    [190319] = {
        class = addon.MAGE,
        spec = { specID.FIRE },
        category = category.BURST,
        duration = 12,
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,

        critResets = {
            [133] = 1, -- Fireball
            [11366] = 1, -- Pyroblast
            [108853] = 1, -- Fire Blast
            [2948] = 1, -- Scorch
            [257542] = 1, -- Phoenix Flames
        },

        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Arcane
    -- Arcane Surge
    [365350] = {
        class = addon.MAGE,
        spec = { specID.ARCANE },
        category = category.BURST,
        cooldown = 90,
        duration = 15,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Touch of the Magi
    [321507] = {
        class = addon.MAGE,
        spec = { specID.ARCANE },
        category = category.BURST,
        cooldown = 45,
        duration = 12,
        baseline = true,
        default = true,
    },
    -- Interrupt
    -- Counterspell
    [2139] = {
        cooldown = 24,
        class = addon.MAGE,
        reduce_on_interrupt = 4,
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Defensive
    -- Ice Block
    [45438] = {
        cooldown = 240,
        --duration = 10, -- TODO: enable duration for defensives
        opt_lower_cooldown = 180,
        class = addon.MAGE,
        category = category.IMMUNITY,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
    -- Cauterize
    [87024] = {
        cooldown = 300,
        class = addon.MAGE,
        spec = { specID.FIRE },
        category = category.DEFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
    -- Cold Snap (resets ice block)
    [235219] = {
        cooldown = 300,
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Alter Time (all specs)
    [342246] = {
        cooldown = 50,
        class = addon.MAGE,
        category = category.DEFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Blazing Barrier
    [235313] = {
        class = addon.MAGE,
        spec = { specID.FIRE },
        category = category.DEFENSIVE,
        cooldown = 25,
        index = addon.SPELLPRIORITY.LOW,
        baseline = true,
    },
    -- Prismatic Barrier
    [235450] = {
        class = addon.MAGE,
        spec = { specID.ARCANE },
        category = category.DEFENSIVE,
        cooldown = 25,
        index = addon.SPELLPRIORITY.LOW,
        baseline = true, -- technically a talent, but always picked
    },
    -- Ice Barrier
    [11426] = {
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.DEFENSIVE,
        cooldown = 25,
        index = addon.SPELLPRIORITY.LOW,
        baseline = true, -- technically a talent, but always picked
    },
    -- Mass Barrier
    [414660] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true, -- technically a talent, but always picked
    },
    -- Mirror Image
    [55342] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true, -- technically a talent, but always picked
    },
    -- Crowd Control
    -- Ring of Frost
    [113724] = {
        cooldown = 45,
        class = addon.MAGE,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Dragon's Breath
    [31661] = {
        cooldown = { default = 45, [specID.FROST_MAGE] = 31.5 },
        class = addon.MAGE,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Mass Polymorph
    [383121] = {
        cooldown = 60,
        class = addon.MAGE,
        category = category.CROWDCONTROL,
    },
    -- Snowdrift
    [389794] = {
        cooldown = 45,
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.STUN,
    },
    -- Ice Wall
    [352278] = {
        cooldown = 90,
        class = addon.MAGE,
        category = category.OTHERS,
    },
    -- Disrupt
    -- Kleptomania (now a channel with a different spellID)
    [198100] = {
        cooldown = 20,
        class = addon.MAGE,
        spec = { specID.ARCANE },
        category = category.OTHERS,
    },
    -- Greater Invisibility
    [110959] = {
        cooldown = 120,
        class = addon.MAGE,
        category = category.OTHERS,
    },
    -- Blink
    [1953] = {
        cooldown = 11, -- 15s - 4s from Flow of Time
        class = addon.MAGE,
        category = category.OTHERS,
        -- Not baseline since it can be replaced by Shimmer
    },
    -- Shimmer
    [212653] = {
        cooldown = 21, -- 25s - 4s from Flow of Time
        class = addon.MAGE,
        category = category.OTHERS,
        charges = true,
    },
    -- Blast Wave
    [157981] = {
        class = addon.MAGE,
        category = category.KNOCKBACK,
        cooldown = 30,
        baseline = true,
    },
    -- Frost Nova
    [122] = {
        class = addon.MAGE,
        category = category.OTHERS,
        cooldown = 30,
        baseline = true, -- technically a talent, but always picked
    },
    -- Remove Curse
    [475] = {
        cooldown = 8,
        class = addon.MAGE,
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
    },

    -- Monk
    -- Celestial Conduit
    [443028] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER, specID.WINDWALKER },
        category = category.BURST,
        cooldown = 90,
        duration = 4,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Storm, Earth, and Fire (icon is strange when testing with a monk probably because the icon changes after spell is cast...)
    [137639] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.BURST,
        cooldown = 90,
        duration = 15,
        charges = true,
        reduce_power_type = POWERTYPE.Chi,
        reduce_amount = 0.5, -- Every 2 Chi spent reduces the cooldown by 1 sec.
        extend = true,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Invoke Xuen, the White Tiger
    [123904] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.BURST,
        cooldown = 120,
        duration = 24,
        baseline = true, -- technically a talent, but always picked
    },
    -- Strike of the Windlord
    [392983] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.BURST,
        cooldown = 30,
    },
    -- Crowd Control
    -- Paralysis
    [115078] = {
        cooldown = 30,
        class = addon.MONK,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Leg Sweep
    [119381] = {
        cooldown = 50,
        class = addon.MONK,
        category = category.STUN,
        baseline = true, -- technically a talent, but always picked
    },
    -- Ring of Peace
    [116844] = {
        cooldown = 45,
        class = addon.MONK,
        category = category.KNOCKBACK,
        -- not baseline, it's on the same node as Song of Chi-Ji
    },
    -- Spear Hand Strike
    [116705] = {
        cooldown = 15,
        class = addon.MONK,
        category = category.INTERRUPT,
        baseline = true, -- technically a talent, but always picked
    },
    -- Touch of Karma
    [122470] = {
        cooldown = 90,
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
    -- Life Cocoon (120 baseline - 45s from Chrysalis)
    [116849] = {
        cooldown = 75,
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Diffuse Magic
    [122783] = {
        cooldown = 90,
        class = addon.MONK,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Revival
    [115310] = {
        cooldown = 150,
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
        -- Restoral (once detected, reuse Revival icon but change texture to Restoral)
        [388615] = {
            parent = 115310,
            use_parent_icon = true,
        },
    -- Fortifying Brew
    [115203] = {
        cooldown = 90,
        class = addon.MONK,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.LOW,
        baseline = true,
        default = true,
    },
    -- Transcendence: Transfer
    [119996] = {
        cooldown = 45,
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Zen Focus Tea
    [209584] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        cooldown = 30,
        trackEvent = addon.SPELL_AURA_APPLIED,
    },
    -- Invoke Yu'lon, the Jade Serpent
    [322118] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Invoke Chi-Ji, the Red Crane
    [325197] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Dampen Harm
    [122278] = {
        cooldown = 120,
        class = addon.MONK,
        spec = { specID.BREWMASTER },
        category = category.DEFENSIVE,
    },
    -- Disrupt
    -- Grapple Weapon
    [233759] = {
        class = addon.MONK,
        category = category.OTHERS,
        cooldown = 45,
    },
    -- Tiger's Lust
    [116841] = {
        class = addon.MONK,
        category = category.OTHERS,
        cooldown = 30,
        baseline = true,
    },
    -- Dispel
    -- Detox
    [115450] = {
        cooldown = 8,
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },
    -- Detox
    [218164] = {
        cooldown = 8,
        class = addon.MONK,
        spec = { specID.WINDWALKER, specID.BREWMASTER },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
    },

    -- Paladin
    -- Avenging Wrath
    [31884] = {
        class = addon.PALADIN,
        category = category.BURST,
        duration = 23, -- Baseline: 20s, Divine Wrath: 3s
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        spec = { specID.RETRIBUTION },
        default = true,
    },
    -- Crusade
    [231895] = {
        class = addon.PALADIN,
        category = category.BURST,
        duration = 30, -- Baseline: 27s, Divine Wrath: 3s
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        spec = { specID.RETRIBUTION },
        default = true,
    },
    -- Wake of Ashes
    [255937] = {
        class = addon.PALADIN,
        spec = { specID.RETRIBUTION },
        category = category.BURST,
        cooldown = 30,
        index = addon.SPELLPRIORITY.HIGH, -- the new way of activating wing
    },
    -- Divine Toll
    [375576] = {
        class = addon.PALADIN,
        category = category.BURST,
        spec = { specID.RETRIBUTION },
        cooldown = 60,
        opt_lower_cooldown = 45,
    },
    -- Blessing of Summer (cannot reliably track cooldown, assume 45s * 3 = 135s perhaps)
    [388007] = {
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.BURST,
        --trackEvent = addon.SPELL_AURA_APPLIED,
        --trackDest = true,
        cooldown = 135,
        duration = 30,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Final Reckoning
    [343721] = {
        class = addon.PALADIN,
        spec = { specID.RETRIBUTION },
        category = category.BURST,
        cooldown = 60,
        duration = 12,
    },
    -- Defensive
    -- Divine Shield
    [642] = {
        cooldown = 210,
        class = addon.PALADIN,
        category = category.IMMUNITY,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
    -- Blessing of Protection
    [1022] = {
        cooldown = 240,
        class = addon.PALADIN,
        category = category.IMMUNITY,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
        -- Blessing of SpellWarding
        [204018] = {
            -- Available to all specs
            baseline = false, -- to avoid inheriting parent baseline property
            parent = 1022,
            use_parent_icon = true, -- different abilities but sharing cooldown
        },
    -- Lay on Hands
    [633] = {
        cooldown = 420,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
        -- Lay on Hands (Empyreal Ward)
        [471195] = {
            parent = 633,
            use_parent_icon = true,
        },
    -- Divine Protection
    [498] = {
        cooldown = 42, -- 60 * 0.7 (Unbreakable Spirit)
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.DEFENSIVE,
        baseline = true,
        default = true,
    },
    -- Divine Protection (Retribution)
    [403876] = {
        cooldown = 63, -- 90 * 0.7 (Unbreakable Spirit)
        class = addon.PALADIN,
        spec = { specID.RETRIBUTION },
        category = category.DEFENSIVE,
        baseline = true,
        default = true,
    },
    -- Shield of Vengeance
    [184662] = {
        cooldown = 63,
        class = addon.PALADIN,
        spec = { specID.RETRIBUTION },
        category = category.DEFENSIVE,
        default = true,
    },
    -- Searing Glare
    [410126] = {
        cooldown = 45,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
    },
    -- Tyr's Deliverance
    [200652] = {
        cooldown = 90,
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.HEAL,
        baseline = true,
    },
    -- Aura Mastery
    [31821] = {
        cooldown = 120,
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Hand of Divinity
    [414273] = {
        cooldown = 90,
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.DEFENSIVE,
    },
    -- Avenging Crusader
    [216331] = {
        cooldown = 60,
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.DEFENSIVE,
    },
    -- Crowd Control
    -- Hammer of Justice
    [853] = {
        cooldown = 30,
        class = addon.PALADIN,
        category = category.STUN,
        baseline = true,
    },
    -- Blinding Light
    [115750] = {
        cooldown = 75,
        class = addon.PALADIN,
        category = category.CROWDCONTROL,
    },
    -- Shield of Virtue
    [215652] = {
        cooldown = 45,
        class = addon.PALADIN,
        spec = { specID.PROTECTION_PALADIN },
        category = category.SILENCE,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Interrupt
    -- Rebuke
    [96231] = {
        cooldown = 15,
        class = addon.PALADIN,
        category = category.INTERRUPT,
        baseline = true, -- technically a talent, but always picked
    },
    -- Disrupt
    -- Blessing of Sacrifice
    [6940] = {
        class = addon.PALADIN,
        category = category.OTHERS,
        cooldown = 105,
        baseline = true,
    },
        -- Ultimate Sacrifice
        [199448] = {
            parent = 6940,
            use_parent_icon = true,
        },
    -- Blessing of Freedom
    [1044] = {
        cooldown = 25,
        class = addon.PALADIN,
        category = category.OTHERS,
        baseline = true,
    },
    -- Dispel
    -- Cleanse
    [4987] = {
        cooldown = 8,
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },
    -- Cleanse Toxins
    [213644] = {
        cooldown = 8,
        class = addon.PALADIN,
        spec = { specID.PROTECTION_PALADIN, specID.RETRIBUTION },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Blessing of Sanctuary
    [210256] = {
        cooldown = 60,
        class = addon.PALADIN,
        spec = { specID.RETRIBUTION },
        category = category.DEFENSIVE,
    },

    -- Priest
    -- Shadow Crash
    [205385] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.BURST,
        cooldown = 20,
    },
    -- Shadow Crash
        [457042] = {
            parent = 205385,
            use_parent_icon = true,
        },
    -- Mindgames
    [375901] = {
        class = addon.PRIEST,
        category = category.BURST,
        cooldown = 45,
        duration = 7, -- Confirm early dismiss
    },
    -- Psyfiend (triggers SPELL_AURA_REMOVED when dismissed)
    [211522] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.BURST,
        spellID = 211522,
        cooldown = 45,
    },
    -- Power Infusion
    [10060] = {
        class = addon.PRIEST,
        category = category.BURST,
        --trackDest = true,
        --trackEvent = addon.SPELL_AURA_APPLIED, -- Twins of the Sun Pristess (when casting on allies, the self buff doesn't trigger SPELL_CAST_SUCCESS)
        cooldown = 120,
        duration = 20, -- Dismissed when either aura is gone (Twins of the Sun Priestess)
        baseline = true, -- technically a talent, but always picked
    },
    -- Shadow
    -- Mindbender (Idol of Y'Shaarj)
    [200174] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.BURST,
        cooldown = 60,
        duration = 15, -- UNIT_DIED not triggered when expiring, consider using UNIT_PET to scan the entire npcMap
    },
    -- Dark Ascension
    [391109] = {
        category = category.BURST,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        cooldown = 60,
        duration = 20,
        default = true,
    },
    -- Void Torrent
    [263165] = {
        category = category.BURST,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        cooldown = 45,
    },
    -- Voidform
    [194249] = {
        category = category.BURST,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        trackEvent = addon.SPELL_AURA_APPLIED,
        cooldown = 120, -- Reduced by Driven to Madness, cannot track reliably
        duration = addon.DURATION_DYNAMIC,
        extend = true,
        default = true,
    },
    -- Dispel
    -- Mass Dispel
    [32375] = {
        cooldown = 120,
        class = addon.PRIEST,
        category = category.MASS_DISPEL,
    },
    -- Purify
    [527] = {
        cooldown = 8,
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST, specID.DISCIPLINE },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        opt_charges = true,
        baseline = true,
    },
    -- Purify Disease
    [213634] = {
        cooldown = 8,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Crowd Control
    -- Psychic Scream
    [8122] = {
        cooldown = 30,
        class = addon.PRIEST,
        category = category.CROWDCONTROL,
        baseline = true,
    },
    -- Holy Word: Chastise
    [88625] = {
        cooldown = 45, -- Baseline 45 Sec cooldown now?
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.STUN,
        baseline = true, -- technically a talent, but always picked
    },
    -- Silence
    [15487] = {
        cooldown = 45,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.SILENCE,
        opt_lower_cooldown = 30,
        baseline = true, -- technically a talent, but always picked
    },
    -- Psychic Horror
    [64044] = {
        cooldown = 45,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.STUN,
    },
    -- Defensive
    -- Void Shift
    [108968] = {
        cooldown = 300,
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Pain Suppression
    [33206] = {
        cooldown = 180,
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.DEFENSIVE,
        charges = true,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Desperate Prayer
    [19236] = {
        cooldown = 70,
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Power Word: Barrier
    [62618] = {
        cooldown = 180,
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Guardian Spirit
    [47788] = {
        cooldown = 180, -- reduce to 1 min if it didn't proc
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Dispersion
    [47585] = {
        cooldown = 90,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Restitution
    [211319] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.DEFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        cooldown = 600,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Divine Ascension
    [328530] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Ultimate Penitence
    [421453] = {
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.DEFENSIVE,
        cooldown = 240,
        baseline = true,
    },
    -- Apotheosis
    [200183] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
        default = true,
    },
    -- Spirit of Redemption
    [215769] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.DEFENSIVE,
        cooldown = 120,
        default = true,
    },
    -- Evangelism
    [472433] = {
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.HEAL,
        cooldown = 90,
        baseline = true,
    },
    -- Ray of Hope
    [197268] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Holy Word: Serenity
    [2050] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.HEAL,
        cooldown = 45,
        charges = true,
        baseline = true,
    },
    -- Power Word: Life
    [440678] = {
        class = addon.PRIEST,
        category = category.HEAL,
        cooldown = 12,
        priority = addon.SPELLPRIORITY.LOW,
    },
    -- Symbol of Hope
    [64901] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Vampiric Embrace
    [15286] = {
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Divine Hymn
    [64843] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.HEAL,
        cooldown = 120,
        baseline = true,
    },
    -- Disrupt
    -- Holy Ward
    [213610] = {
        cooldown = 45,
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.OTHERS,
    },
    -- Fade
    [586] = {
        cooldown = 20,
        class = addon.PRIEST,
        category = category.IMMUNITY,
        baseline = true,
    },
    -- Shadow Word: Death
    [32379] = {
        cooldown = 10,
        class = addon.PRIEST,
        category = category.OTHERS,
        baseline = true,
    },
    -- Leap of Faith
    [73325] = {
        cooldown = 60,
        class = addon.PRIEST,
        category = category.OTHERS,
        baseline = true,
    },
    -- Thoughtsteal
    [316262] = {
        cooldown = 90,
        class = addon.PRIEST,
        category = category.OTHERS,
    },
    -- Void Tendrils
    [108920] = {
        cooldown = 60,
        class = addon.PRIEST,
        category = category.OTHERS,
    },

    -- Rogue
    -- Cold Blood
    [382245] = {
        class = addon.ROGUE,
        category = category.BURST,
        cooldown = 45,
        index = addon.SPELLPRIORITY.HIGH,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Subtlety
    -- Shadow Blades
    [121471] = {
        class = addon.ROGUE,
        spec = { specID.SUBTLETY },
        category = category.BURST,
        cooldown = 90,
        duration = 20,
        baseline = true, -- technically a talent, but always picked
    },
    -- Shadow Dance
    [185313] = {
        class = addon.ROGUE,
        spec = { specID.SUBTLETY },
        category = category.BURST,
        cooldown = 30, -- 2 charges but cannot track cd reliably, just divide cd by 2
        duration = 8,
        baseline = true,
    },
    -- Symbols of Death
    [212283] = {
        class = addon.ROGUE,
        spec = { specID.SUBTLETY },
        category = category.BURST,
        cooldown = 30,
        duration = 10,
        baseline = true,
    },
    -- Secret Technique
    [280719] = {
        class = addon.ROGUE,
        spec = { specID.SUBTLETY },
        category = category.BURST,
        cooldown = 45,
    },
    -- Flagellation
    [384631] = {
        class = addon.ROGUE,
        spec = { specID.SUBTLETY },
        category = category.BURST,
        cooldown = 90,
        duration = 12,
    },
    -- Outlaw
    -- Adrenaline Rush
    [13750] = {
        class = addon.ROGUE,
        spec = { specID.OUTLAW },
        category = category.BURST,
        cooldown = 180,
        duration = 20,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Killing Spree
    [51690] = {
        class = addon.ROGUE,
        spec = { specID.OUTLAW },
        category = category.BURST,
        cooldown = 90,
        duration = 3,
        baseline = true,
    },
    -- Between the Eyes
    [315341] = {
        class = addon.ROGUE,
        spec = { specID.OUTLAW },
        category = category.BURST,
        cooldown = 45,
        duration = 21, -- Max duration, can dismiss early
        baseline = true,
    },
    -- Assassination
    -- Death Mark
    [360194] = {
        class = addon.ROGUE,
        spec = { specID.ASSASSINATION },
        category = category.BURST,
        duration = 16, -- confirm early dismiss
        cooldown = 120,
        index = addon.SPELLPRIORITY.DEADLY,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Kingsbane
    [385627] = {
        class = addon.ROGUE,
        spec = { specID.ASSASSINATION },
        category = category.BURST,
        cooldown = 60,
        duration = 14,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Interrupt
    -- Kick
    [1766] = {
        cooldown = 15,
        class = addon.ROGUE,
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Defensive
    -- Vanish (addition charge in class talent tree)
    [1856] = {
        cooldown = 120,
        class = addon.ROGUE,
        charges = true,
        category = category.DEFENSIVE,
        baseline = true,
        default = true,
    },
    -- Cloak of Shadows
    [31224] = {
        cooldown = 120,
        class = addon.ROGUE,
        category = category.IMMUNITY,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Evasion
    [5277] = {
        cooldown = 120,
        class = addon.ROGUE,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Feint
    -- [1966] = {
    --     cooldown = 7.5, -- 15s with 2 charges
    --     class = addon.ROGUE,
    --     category = category.DEFENSIVE,
    --     baseline = true, -- technically a talent, but always picked
    -- },
    -- Crowd Control
    -- Kidney Shot
    [408] = {
        cooldown = 30,
        class = addon.ROGUE,
        category = category.STUN,
        baseline = true,
    },
    -- Blind
    [2094] = {
        cooldown = {default = 120, [specID.OUTLAW] = 90},
        class = addon.ROGUE,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Smoke Bomb
    [212182] = {
        cooldown = 180,
        class = addon.ROGUE,
        spec = { specID.ASSASSINATION, specID.OUTLAW },
        category = category.CROWDCONTROL,
    },
    -- Smoke Bomb (Subtlety)
    [359053] = {
        parent = 212182,
        cooldown = 120,
        spec = { specID.SUBTLETY },
    },
    -- Gouge
    [1776] = {
        cooldown = 25,
        class = addon.ROGUE,
        category = category.CROWDCONTROL,
        baseline = true,
    },
    -- Disrupt
    -- Shadowstep
    [36554] = {
        cooldown = 30,
        class = addon.ROGUE,
        spec = { specID.SUBTLETY, specID.ASSASSINATION },
        charges = true,
        category = category.OTHERS,
        baseline = true,
    },
    -- Grappling Hook
    [195457] = {
        cooldown = 30,
        class = addon.ROGUE,
        spec = { specID.OUTLAW },
        charges = true,
        category = category.OTHERS,
        baseline = true,
    },
    -- Dismantle
    [207777] = {
        cooldown = 45,
        class = addon.ROGUE,
        category = category.OTHERS
    },
    -- Sprint
    [2983] = {
        cooldown = 60,
        class = addon.ROGUE,
        category = category.OTHERS,
        baseline = true,
    },

    -- Shaman
    -- Enhancement
    -- Ascendance (Enhancement)
    [114051] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        cooldown = 180,
        duration = 15,
    },
    -- Doom Winds
    [384352] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        duration = 8,
        cooldown = 60,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Feral Spirit
    [51533] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        cooldown = 90,
        duration = 15,
    },
    -- Bloodlust (Shamanism)
    [204361] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        cooldown = 60,
        duration = 10,
        trackEvent = addon.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Heroism (Shamanism)
    [204362] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        cooldown = 60,
        duration = 10,
        trackEvent = addon.SPELL_AURA_APPLIED,
        --trackDest = true,
    },
    -- Elemental
    -- Stormkeeper
    [191634] = {
        class = addon.SHAMAN,
        spec = { specID.ELEMENTAL },
        category = category.BURST,
        cooldown = 60, -- reduced by Lighting Bolt and Chain Lightning
        duration = 15,
    },
    -- Fire Elemental
    [198067] = {
        class = addon.SHAMAN,
        spec = { specID.ELEMENTAL },
        category = category.BURST,
        cooldown = 150,
        duration = 24,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Primoridal Wave
    [375982] = {
        class = addon.SHAMAN,
        spec = { specID.ELEMENTAL },
        category = category.BURST,
        cooldown = 30,
        baseline = true,
    },
    -- Ascendance (Elemental)
    [114050] = {
        class = addon.SHAMAN,
        spec = { specID.ELEMENTAL },
        category = category.BURST,
        cooldown = 180,
        opt_lower_cooldown = 120, -- Talent that is not picked often
        duration = 15,
        baseline = true,
    },
    -- Interrupt
    -- Wind Shear
    [57994] = {
        cooldown = 12,
        class = addon.SHAMAN,
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Defensive
    -- Astral Shift (120s baseline, -30 Planes Traveler)
    [108271] = {
        cooldown = 90,
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        baseline = true,
        default = true,
    },
    -- Spirit Link Totem
    [98008] = {
        cooldown = 174,
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        spec = { specID.RESTORATION_SHAMAN },
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Ascendance (Restoration)
    [114052] = {
        class = addon.SHAMAN,
        spec = { specID.RESTORATION_SHAMAN },
        category = category.DEFENSIVE,
        cooldown = 180,
        opt_lower_cooldown = 120,
        baseline = true,
    },
    -- Spirit Walk
    [58875] = {
        cooldown = 60,
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Spirit Walker's Grace
    [79206] = {
        cooldown = 120,
        opt_lower_cooldown = 90,
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Burrow
    [409293] = {
        cooldown = 120,
        class = addon.SHAMAN,
        category = category.IMMUNITY,
        default = true,
    },
    -- Stone Bulwark Totem (can be reset by Totemic Recall)
    [108270] = {
        cooldown = 174,
        class = addon.SHAMAN,
        category = category.DEFENSIVE
    },
    -- Totemic Recall
    [108285] = {
        cooldown = 180,
        opt_lower_cooldown = 120,
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Healing Tide Totem
    [108280] = {
        cooldown = 180,
        opt_lower_cooldown = 135,
        class = addon.SHAMAN,
        category = category.HEAL,
        spec = { specID.RESTORATION_SHAMAN },
        baseline = true,
    },
    -- Earthen Wall Totem
    [198838] = {
        cooldown = 54,
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        spec = { specID.RESTORATION_SHAMAN },
        baseline = true,
    },
    -- Disrupt
    -- Grounding Totem
    [204336] = {
        cooldown = 24,
        class = addon.SHAMAN,
        category = category.OTHERS,
        baseline = true,
    },
    -- Tremor Totem
    [8143] = {
        cooldown = 54,
        class = addon.SHAMAN,
        category = category.OTHERS
    },
    -- Thunderstorm
    [51490] = {
        cooldown = 30,
        class = addon.SHAMAN,
        category = category.KNOCKBACK,
        baseline = true, -- technically a talent, but always picked
    },
        -- Thunderstorm (Traveling Thunders)
        [204406] = {
            parent = 51490,
            use_parent_icon = true,
        },
    -- Earthgrab Totem
    [51485] = {
        cooldown = 24,
        class = addon.SHAMAN,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Greater Purge
    [378773] = {
        cooldown = 12,
        class = addon.SHAMAN,
        category = category.OTHERS,
    },
    -- Nature's Swiftness
    [378081] = {
        cooldown = 60,
        class = addon.SHAMAN,
        category = category.OTHERS,
        baseline = true,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Crowd Control
    -- Hex
    [51514] = {
        cooldown = 30,
        class = addon.SHAMAN,
        category = category.CROWDCONTROL,
        baseline = true,
    },
    -- Static Field Totem
    [355580] = {
        cooldown = 84,
        class = addon.SHAMAN,
        category = category.OTHERS,
        baseline = true, -- technically a talent, but always picked
    },
    -- Dispel
    -- Purify Spirit
    [77130] = {
        cooldown = 8,
        class = addon.SHAMAN,
        spec = { specID.RESTORATION_SHAMAN },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },
    -- Cleanse Spirit
    [51886] = {
        cooldown = 8,
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT, specID.ELEMENTAL },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Crowd Control
    -- Lightning Lasso
    [305483] = {
        cooldown = 45,
        class = addon.SHAMAN,
        category = category.STUN,
        baseline = true, -- technically a talent, but always picked
    },
    -- Unleash Shield
    [356736] = {
        cooldown = 30,
        class = addon.SHAMAN,
        category = category.OTHERS,
    },
    -- Capacitor Totem
    [192058] = {
        cooldown = 54,
        class = addon.SHAMAN,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },

    -- Warlock
    -- Affliction
    -- Soul Rot
    [386997] = {
        class = addon.WARLOCK,
        spec = { specID.AFFLICTION },
        category = category.BURST,
        cooldown = 60,
    },
    -- Summon Darkglare
    [205180] = {
        class = addon.WARLOCK,
        spec = { specID.AFFLICTION },
        category = category.BURST,
        cooldown = 120,
        duration = 20, -- confirm early dismiss if killed
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
    -- Destruction
    -- Summon Infernal
    [1122] = {
        class = addon.WARLOCK,
        spec = { specID.DESTRUCTION },
        category = category.BURST,
        cooldown = 120,
        duration = 30,
        baseline = true,
        default = true,
    },
    -- Demonology
    -- Summon Demonic Tyrant
    [265187] = {
        class = addon.WARLOCK,
        spec = { specID.DEMONOLOGY },
        category = category.BURST,
        cooldown = 60,
        duration = 15,
        baseline = true,
        default = true,
    },
    -- Grimoire: Felguard
    [111898] = {
        class = addon.WARLOCK,
        spec = { specID.DEMONOLOGY },
        category = category.BURST,
        cooldown = 120,
        duration = 17,
    },
    -- Demonic Strength
    [267171] = {
        class = addon.WARLOCK,
        spec = { specID.DEMONOLOGY },
        category = category.BURST,
        cooldown = 60,
    },
    -- Haunt
    [48181] = {
        class = addon.WARLOCK,
        spec = { specID.AFFLICTION },
        category = category.BURST,
        cooldown = 15,
    },
    -- Malevolence
    [442726] = {
        class = addon.WARLOCK,
        spec = { specID.AFFLICTION, specID.DESTRUCTION },
        category = category.BURST,
        cooldown = 60,
        duration = 15,
    },
    -- Crowd Control
    -- Mortal Coil
    [6789] = {
        cooldown = 45,
        class = addon.WARLOCK,
        category = category.CROWDCONTROL,
    },
    -- Howl of Terror
    [5484] = {
        cooldown = 40,
        opt_lower_cooldown = 25,
        class = addon.WARLOCK,
        category = category.CROWDCONTROL,
    },
    -- Axe Toss
    [89766] = {
        cooldown = 30,
        class = addon.WARLOCK,
        spec = { specID.DEMONOLOGY },
        trackPet = true,
        category = category.STUN,
    },
        -- Axe Toss (Command Demon Ability) (only shows up once no matter which version is cast)
        [119914] = {
            parent = 89766,
            use_parent_icon = true, -- Shouldn't show 2 icons, since they share cd
        },
    -- Shadowfury
    [30283] = {
        cooldown = 60,
        class = addon.WARLOCK,
        category = category.STUN,
    },
    -- Seduction
    [6358] = {
        cooldown = 30,
        class = addon.WARLOCK,
        trackPet = true,
        category = category.CROWDCONTROL,
    },
    -- Defensive
    -- Unending Resolve
    [104773] = {
        cooldown = 180,
        class = addon.WARLOCK,
        opt_lower_cooldown = 135,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
        default = true,
    },
    -- Soul Rip
    [410598] = {
        cooldown = 60,
        class = addon.WARLOCK,
        opt_lower_cooldown = 135,
        category = category.DEFENSIVE,
    },
    -- Dark Pact
    [108416] = {
        cooldown = 45,
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Demonic Circle: Teleport
    [48020] = {
        cooldown = 30,
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Demonic Healthstone
    [452930] = {
        cooldown = 60,
        class = addon.WARLOCK,
        category = category.HEAL,
    },
    -- Interrupt
    -- Spell Lock (Command Demon Ability)
    [19647] = {
        cooldown = 24,
        class = addon.WARLOCK,
        trackPet = true,
        category = category.INTERRUPT,
    },
        -- Spell Lock (Grimoire of Sacrifice)
        [132409] = {
            parent = 19647,
        },
        -- Optical Blast (Command Demon)
        [119911] = {
            parent = 19647,
        },
        -- Optical Blast (Observer)
        [115781] = {
            parent = 19647,
        },
        -- Shadow Lock (Doomguard)
        [171138] = {
            parent = 19647,
        },
        -- Shadow Lock (Grimoire of Sacrifice)
        [171139] = {
            parent = 19647,
        },
        -- Shadow Lock (Command Demon)
        [171140] = {
            parent = 19647,
        },
    -- Nether Ward
    [212295] = {
        cooldown = 45,
        class = addon.WARLOCK,
        category = category.OTHERS,
    },
    -- Others
    -- Havoc
    [80240] = {
        class = addon.WARLOCK,
        spec = { specID.DESTRUCTION },
        category = category.OTHERS,
        cooldown = 30,
        baseline = true,
    },
    -- Devour Magic
    [19505] = {
        cooldown = 15,
        class = addon.WARLOCK,
        category = category.OTHERS,
        trackPet = true,
        -- Not baseline since the enemy player is not necessarily playing Felhunter
    },
    -- Amplify Curse
    [328774] = {
        cooldown = 45,
        class = addon.WARLOCK,
        category = category.OTHERS,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },

    -- Warrior
    -- Champion's Spear
    [376079] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 90,
        duration = 6,
        index = addon.SPELLPRIORITY.HIGH,
        default = true,
    },
    -- Avatar
    [107574] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 90,
        duration = 20,
        baseline = true, -- technically a talent, but always picked
    },
    -- Warbreaker
    [262161] = {
        class = addon.WARRIOR,
        spec = { specID.ARMS },
        category = category.BURST,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Colossus Smash
    [167105] = {
        class = addon.WARRIOR,
        spec = { specID.ARMS },
        category = category.BURST,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Recklessness
    [1719] = {
        class = addon.WARRIOR,
        spec = { specID.FURY },
        category = category.BURST,
        cooldown = 90,
        duration = 16,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Thunderous Roar
    [384318] = {
        class = addon.WARRIOR,
        spec = { specID.FURY },
        category = category.BURST,
        cooldown = 45,
        duration = 8,
    },
    -- Death Wish
    [199261] = {
        class = addon.WARRIOR,
        spec = { specID.FURY },
        category = category.OTHERS,
        cooldown = 15,
    },
    -- Demolish
    [436358] = {
        class = addon.WARRIOR,
        spec = { specID.ARMS, specID.FURY },
        category = category.BURST,
        cooldown = 45,
    },
    -- Charge
    [100] = {
        cooldown = 17,
        class = addon.WARRIOR,
        charges = true,
        category = category.OTHERS,
        baseline = true,
    },
    -- Spell Reflection
    [23920] = {
        cooldown = 23.75,
        class = addon.WARRIOR,
        category = category.OTHERS,
    },
    -- Bladestorm
    [227847] = {
        cooldown = 90,
        class = addon.WARRIOR,
        spec = { specID.ARMS, specID.FURY },
        category = category.IMMUNITY,
        baseline = true, -- technically a talent, but always picked
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05,
    },
        -- Bladestorm (Slayer)
        [446035] = {
            parent = 227847,
            use_parent_icon = true,
            reduce_power_type = POWERTYPE.Rage,
            reduce_amount = 0.05,
        },
    -- Heroic Leap
    [52174] = {
        cooldown = 30,
        class = addon.WARRIOR,
        category = category.OTHERS,
        baseline = true, -- technically a talent, but always picked
    },
    -- Disarm
    [236077] = {
        cooldown = 45,
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
    },
    -- Duel
    [236273] = {
        cooldown = 60,
        class = addon.WARRIOR,
        spec = { specID.ARMS },
        category = category.DEFENSIVE,
    },
    -- Pummel
    [6552] = {
        cooldown = 13.3, -- with both cd reduction talents
        class = addon.WARRIOR,
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Disrupting Shout
    [386071] = {
        cooldown = 90,
        class = addon.WARRIOR,
        spec = { specID.PROTECTION_WARRIOR },
        category = category.INTERRUPT,
        baseline = true, -- technically a talent, but always picked
    },
    -- Storm Bolt
    [107570] = {
        cooldown = 28.5,
        class = addon.WARRIOR,
        category = category.STUN,
        baseline = true, -- technically a talent, but always picked
    },
    -- Shockwave
    [46968] = {
        cooldown = 40,
        class = addon.WARRIOR,
        category = category.STUN,
        baseline = true, -- technically a talent, but always picked
    },
    -- Intimidating Shout
    [5246] = {
        cooldown = 90,
        opt_lower_cooldown = 75, -- Battlefield Commander
        class = addon.WARRIOR,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Die by the Sword
    [118038] = {
        cooldown = 85.5,
        class = addon.WARRIOR,
        spec = { specID.ARMS },
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Enraged Regeneration
    [184364] = {
        cooldown = 114,
        class = addon.WARRIOR,
        spec = { specID.FURY },
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
        default = true,
    },
    -- Intervene
    [3411] = {
        cooldown = 28.5,
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Rallying Cry
    [97462] = {
        cooldown = 180,
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
    },
    -- Impending Victory
    [202168] = {
        cooldown = 25,
        class = addon.WARRIOR,
        category = category.HEAL,
        baseline = true,
    },
    -- Berserker Rage
    [18499] = {
        cooldown = 60,
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
        -- Berserker Shout
        [384100] = {
            parent = 18499,
            use_parent_icon = true,
        },
        -- Berserker Roar
        [1219201] = {
            parent = 18499,
            use_parent_icon = true,
        },
};

addon.SpellResets = {
    -- Metamorphosis
    [191427] = {
        198013, -- Eye Beam
    },
    -- Blade Dance
    [188499] = {
        { spellID = 198013, amount = 1 }, -- Eye Beam
    },
    -- Chaos Strike
    [162794] = {
        { spellID = 198013, amount = 1 }, -- Eye Beam
    },
    -- Glaive Tempest
    [342817] = {
        { spellID = 198013, amount = 1 }, -- Eye Beam
    },

    -- Bestial Wrath
    -- Barbed Shot
    [217200] = {
        { spellID = 19574, amount = 12 }, -- Bestial Wrath
    },

    -- Cold Snap
    [235219] = {
        45438, -- Ice Block
    },

    -- Apotheosis
    [200183] = {
        88625, -- Holy Word: Chastise
        2050, -- Grants one charge of Holy Word: Serenity
    },

    -- Holy Fire
    [14914] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },
    -- Smite
    [585] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },
    -- Holy Nova
    [132157] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },

    -- Prayer of Mending
    [33076] = {
        { spellID = 2050, amount = 4 }, -- Holy Word: Serenity
    },
    -- Power Word: Life
    [440678] = {
        { spellID = 2050, amount = 4 }, -- Holy Word: Serenity
    },
    -- Heal
    [2060] = {
        { spellID = 2050, amount = 6 }, -- Holy Word: Serenity
    },
    -- Flash Heal
    [2061] = {
        { spellID = 2050, amount = 6 }, -- Holy Word: Serenity
    },

    -- Power Word: Shield
    [17] = {
        { spellID = 33206, amount = 3 }, -- Pain Suppression
    },

    -- Kill Command
    [34026] = {
        { spellID = 19577, amount = 0.5 }, -- Intimidation
        { spellID = 109248, amount = 0.5 }, -- Binding Shot
    }
};

addon.SpellResets[382445] = {}; -- Shifting Power each tick
addon.SpellResets[157982] = {}; -- Tranquility each tick
-- Reduce each Mage spell by 3 Sec
-- Fill the entries programatically from addon.Spells
for spellID, spell in pairs(addon.SpellData) do
    if spell.class == addon.MAGE then
        table.insert(addon.SpellResets[382445], { spellID = spellID, amount = 3 });
    elseif ( spell.class == addon.DRUID and spellID ~= 740 ) then
        table.insert(addon.SpellResets[157982], { spellID = spellID, amount = 4 });
    end
end

addon.SpellResetsAffectedByApotheosis = {
    [14914] = 2, -- Holy Fire (nerfed in PvP)
    [585] = 3, -- Smite
    [132157] = 3, -- Holy Nova

    [33076] = 3, -- Prayer of Mending
    [440678] = 3, -- Power Word: Life
    [2060] = 3, -- Heal
    [2061] = 3, -- Flash Heal
};

if addon.TEST_MODE then
    -- Test
    -- Mark of the Wild
    addon.SpellData[1126] = {
        class = addon.DRUID,
        category = category.INTERRUPT,
        duration = 8,
        cooldown = 30,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
    };
    -- Regrowth
    addon.SpellData[8936] = {
        class = addon.DRUID,
        category = category.INTERRUPT,
        duration = 5,
        cooldown = 10,
        baseline = true,
    };
    -- Rejuv
    addon.SpellData[774] = {
        class = addon.DRUID,
        category = category.DEFENSIVE,
        cooldown = 8,
        baseline = true,
        opt_charges = true,
    };
    -- Wild Growth
    addon.SpellData[48438] = {
        class = addon.DRUID,
        category = category.BURST,
        duration = 7,
        cooldown = 30,
        trackDest = true,
        trackEvent = addon.SPELL_AURA_APPLIED,
        baseline = true,
    };

    addon.SpellData[1459] = {
        class = addon.MAGE,
        category = category.BURST,
        duration = 12,
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,

        -- Fireball, Pyroblast, Fire Blast, Scorch, Phoenix Flames
        critResets = {
            [133] = 1,
            [11366] = 1,
            [108853] = 1,
            [2948] = 1,
            [257542] = 1,
        }
    };
end

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
