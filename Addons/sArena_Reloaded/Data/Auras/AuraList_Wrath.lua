-- Auras we want tooltip info from to display as stacks
sArenaMixin.tooltipInfoAuras = {
    --[115867] = true, -- Mana Tea
    [1247275] = true,     -- Tigereye Brew
}

sArenaMixin.spellLockReducer = {
    [317920] = 0.7, -- Concentration Aura
    [234084] = 0.5, -- Moon and Stars
    [383020] = 0.5, -- Tranquil Air
}

sArenaMixin.auraList = {
    -- Special
    [122465]  = 10,    -- Dematerialize
    [114028]  = 10,    -- Mass Spell Reflection
    [23920]   = 10,    -- Spell Reflection
    [113002]  = 10,    -- Spell Reflection (Symbiosis)
    [8178]    = 10,    -- Grounding Totem Effect

    -- Full CC (Stuns and Disorients)
    [33786]   = 9,    -- Cyclone (Disorient)
    [58861]   = 9,    -- Bash (Spirit Wolves)
    [5211]    = 9,    -- Bash
    [8983]    = 9,    -- Bash
    [6789]    = 9,    -- Death Coil
    [27223]   = 9,    -- Death Coil
    [1833]    = 9,    -- Cheap Shot
    [7922]    = 9,    -- Charge Stun
    [12809]   = 9,    -- Concussion Blow
    [44572]   = 9,    -- Deep Freeze
    [60995]   = 9,    -- Demon Charge
    [47481]   = 9,    -- Gnaw
    [853]     = 9,    -- Hammer of Justice
    [10308]   = 9,    -- Hammer of Justice
    [85388]   = 9,    -- Throwdown
    [90337]   = 9,    -- Bad Manner
    [20253]   = 9,    -- Intercept
    [30153]   = 9,    -- Pursuit
    [24394]   = 9,    -- Intimidation
    [19577]   = 9,    -- Intimidation
    [408]     = 9,    -- Kidney Shot
    [8643]    = 9,    -- Kidney Shot
    [22570]   = 9,    -- Maim
    [9005]    = 9,    -- Pounce
    [64058]   = 9,    -- Psychic Horror
    [6572]    = 9,    -- Ravage
    [30283]   = 9,    -- Shadowfury
    [46968]   = 9,    -- Shockwave
    [39796]   = 9,    -- Stoneclaw Stun
    [20549]   = 9,    -- War Stomp
    [61025]   = 9,    -- Polymorph: Serpent
    [82691]   = 9,    -- Ring of Frost
    [115078]  = 9,    -- Paralysis
    [76780]   = 9,    -- Bind Elemental
    [107079]  = 9,    -- Quaking Palm (Racial)
    [99]      = 9,    -- Disorienting Roar
    [123393]  = 9,    -- Glyph of Breath of Fire
    [108194]  = 9,    -- Asphyxiate
    [91797]   = 9,    -- Monstrous Blow (Dark Transformation)
    [113801]  = 9,    -- Bash (Treants)
    [117526]  = 9,    -- Binding Shot
    [56626]   = 9,    -- Sting (Wasp)
    [50519]   = 9,    -- Sonic Blast
    [118271]  = 9,    -- Combustion Impact
    [119392]  = 9,    -- Charging Ox Wave
    [122242]  = 9,    -- Clash (Symbiosis)
    [122057]  = 9,    -- Clash
    [120086]  = 9,    -- Fists of Fury
    [119381]  = 9,    -- Leg Sweep
    [115752]  = 9,    -- Blinding Light (Glyphed)
    [110698]  = 9,    -- Hammer of Justice (Symbiosis)
    [119072]  = 9,    -- Holy Wrath
    [105593]  = 9,    -- Fist of Justice
    [118345]  = 9,    -- Pulverize (Primal Earth Elemental)
    [118905]  = 9,    -- Static Charge (Capacitor Totem)
    [89766]   = 9,    -- Axe Toss (Felguard)
    [22703]   = 9,    -- Inferno Effect
    [107570]  = 9,    -- Storm Bolt
    [132169]  = 9,    -- Storm Bolt
    [113004]  = 9,    -- Intimidating Roar (Symbiosis)
    [113056]  = 9,    -- Intimidating Roar (Symbiosis 2)
    [118699]  = 9,    -- Fear (alt ID)
    [113792]  = 9,    -- Psychic Terror (Psyfiend)
    [115268]  = 9,    -- Mesmerize (Shivarra)
    [104045]  = 9,    -- Sleep (Metamorphosis)
    [20511]   = 9,    -- Intimidating Shout (secondary)
    [96201]   = 9,    -- Web Wrap
    [132168]  = 9,    -- Shockwave
    [118895]  = 9,    -- Dragon Roar
    [115001]  = 9,    -- Remorseless Winter
    [102795]  = 9,    -- Bear Hug
    [77505]   = 9,    -- Earthquake
    [15618]   = 9,    -- Snap Kick
    [113953]  = 9,    -- Paralysis
    [137143]  = 9,    -- Blood Horror
    [87204]   = 9,    -- Sin and Punishment
    [127361]  = 9,    -- Bear Hug (Symbiosis)

    -- Stun Procs
    [34510]   = 9,    -- Stun (various procs)
    [5530]    = 9,    -- Mace Stun Effect
    [15269]   = 9,    -- Blackout Stun
    [16922]   = 9,    -- Imp Starfire Stun
    [12355]   = 9,    -- Impact
    [23454]   = 9,    -- Stun
    [20170]   = 9,    -- Seal of Justice

    -- Disorient / Incapacitate / Fear / Charm
    [2094]    = 9,    -- Blind
    [31661]   = 9,    -- Dragon's Breath
    [5782]    = 9,    -- Fear
    [130616]  = 9,    -- Fear (Glyphed)
    [3355]    = 9,    -- Freezing Trap
    [14309]   = 9,    -- Freezing Trap Effect
    [1776]    = 9,    -- Gouge
    [51514]   = 9,    -- Hex
    [2637]    = 9,    -- Hibernate
    [18658]   = 9,    -- Hibernate
    [5484]    = 9,    -- Howl of Terror
    [49203]   = 9,    -- Hungering Cold
    [5246]    = 9,    -- Intimidating Shout
    [25274]   = 9,    -- Intercept Stun
    [605]     = 9,    -- Mind Control
    [118]     = 9,    -- Polymorph
    [12826]   = 9,    -- Polymorph
    [28271]   = 9,    -- Polymorph: Turtle
    [28272]   = 9,    -- Polymorph: Pig
    [61721]   = 9,    -- Polymorph: Rabbit
    [61780]   = 9,    -- Polymorph: Turkey
    [61305]   = 9,    -- Polymorph: Black Cat
    [8122]    = 9,    -- Psychic Scream
    [20066]   = 9,    -- Repentance
    [6770]    = 9,    -- Sap
    [1513]    = 9,    -- Scare Beast
    [14327]   = 9,    -- Scare Beast
    [19503]   = 9,    -- Scatter Shot
    [6358]    = 9,    -- Seduction
    [9484]    = 9,    -- Shackle Undead
    [1090]    = 9,    -- Sleep
    [10326]   = 9,    -- Turn Evil
    [145067]  = 9,    -- Turn Evil
    [19386]   = 9,    -- Wyvern Sting
    [88625]   = 9,    -- Chastise
    [710]     = 9,    -- Banish
    [105421]  = 9,    -- Blinding Light
    [113506]  = 9,    -- Cyclone (Symbiosis)
    [126355]  = 9,    -- Paralyzing Quill
    [126246]  = 9,    -- Lullaby
    [91800]   = 9,    -- Gnaw (Ghoul stun)
    [64044]   = 9,    -- Psychic Horror (alt ID)
    [31117]   = 9,    -- UA silence (on dispel)
    [126423]  = 9,    -- Petrifying Gaze (Basilisk pet) -- TODO: verify category
    [102546]  = 9,    -- Pounce

    -- Immunities
    [115760]  = 7,      -- Glyph of Ice Block, Immune to Spells
    [46924]   = 7,      -- Bladestorm
    [19263]   = 7,      -- Deterrence
    [110617]  = 7,      -- Deterrence (Symbiosis)
    [47585]   = 7,      -- Dispersion
    [110715]  = 7,      -- Dispersion (Symbiosis)
    [642]     = 7,      -- Divine Shield
    [110700]  = 7,      -- Divine Shield (Symbiosis)
    [498]     = 7,      -- Divine Protection
    [45438]   = 7,      -- Ice Block
    [110696]  = 7,      -- Ice Block (Symbiosis)
    [34692]   = 7,      -- The Beast Within
    [26064]   = 7,      -- Shell Shield
    [19574]   = 7,      -- Bestial Wrath
    [1022]    = 7,      -- Hand of Protection
    [10278]   = 7,      -- Blessing of Protection
    [3169]    = 7,      -- Invulnerability
    [20230]   = 7,      -- Retaliation
    [16621]   = 7,      -- Self Invulnerability
    [92681]   = 7,      -- Phase Shift
    [20594]   = 7,      -- Stoneform -- FIX
    [31224]   = 7,      -- Cloak of Shadows
    [110788]  = 7,      -- Cloak of Shadows (Symbiosis)
    [27827]   = 7,      -- Spirit of Redemption
    [49039]   = 7,      -- Lichborne
    [148467]  = 7,      -- Deterrence

    [12043]   = 6.6,    -- Presence of Mind
    [132158]  = 6.6,    -- Nature's Swiftness
    [16188]   = 6.6,    -- Nature's Swiftness

    -- Anti-CCs
    [115018]  = 6.5,    -- Desecrated Ground (All CC Immunity)
    [48707]   = 6.5,    -- Anti-Magic Shell
    [110570]  = 6.5,    -- Anti-Magic Shell (Symbiosis)
    [137562]  = 6.5,    -- Nimble Brew
    [6940]    = 6.5,    -- Hand of Sacrifice
    [5384]    = 6.5,    -- Feign Death
    [34471]   = 6.5,    -- The Beast Within

    -- Silences
    [25046]   = 6,    -- Arcane Torrent
    [1330]    = 6,    -- Garrote
    [15487]   = 6,    -- Silence (Priest)
    [18498]   = 6,    -- Silenced - Gag Order (Warrior)
    [18469]   = 6,    -- Silenced - Improved Counterspell (Mage)
    [55021]   = 6,    -- Silenced - Improved Counterspell (Mage alt)
    [18425]   = 6,    -- Silenced - Improved Kick (Rogue)
    [34490]   = 6,    -- Silencing Shot (Hunter)
    [24259]   = 6,    -- Spell Lock (Felhunter)
    [47476]   = 6,    -- Strangulate (Death Knight)
    [43523]   = 6,    -- Unstable Affliction (Silence effect)
    [114238]  = 6,    -- Glyph of Fae Silence
    [102051]  = 6,    -- Frostjaw
    [137460]  = 6,    -- Ring of Peace (Silence)
    [115782]  = 6,    -- Optical Blast (Observer)
    [50613]   = 6,    -- Arcane Torrent (Runic Power)
    [28730]   = 6,    -- Arcane Torrent (Mana)
    [69179]   = 6,    -- Arcane Torrent (Rage)
    [80483]   = 6,    -- Arcane Torrent (Focus)
    [31935]   = 6,    -- Avenger's Shield
    [116709]  = 6,    -- Spear Hand Strike
    [142895]  = 6,    -- Silence (Ring of Peace?)

    [1766]    = 6,    -- Kick (Rogue)
    [2139]    = 6,    -- Counterspell (Mage)
    [6552]    = 6,    -- Pummel (Warrior)
    [19647]   = 6,    -- Spell Lock (Warlock)
    [47528]   = 6,    -- Mind Freeze (Death Knight)
    [57994]   = 6,    -- Wind Shear (Shaman)
    [91802]   = 6,    -- Shambling Rush (Death Knight)
    -- [96231] = 6, -- Rebuke (Paladin) -- intentionally commented out
    [106839]  = 6,    -- Skull Bash (Feral)
    [115781]  = 6,    -- Optical Blast (Warlock)
    [116705]  = 6,    -- Spear Hand Strike (Monk)
    [132409]  = 6,    -- Spell Lock (Warlock)
    [147362]  = 6,    -- Countershot (Hunter)
    --[171138] = 6, -- Shadow Lock (Warlock) --not mop
    --[183752] = 6, -- Consume Magic (Demon Hunter) --not mop
    --[187707] = 6, -- Muzzle (Hunter) -- not mop
    --[212619] = 6, -- Call Felhunter (Warlock) --not mop
    --[231665] = 6, -- Avenger's Shield (Paladin) --not mop
    --[351338] = 6, -- Quell (Evoker) --not mop
    [97547]   = 6,    -- Solar Beam
    [113286]  = 6,    -- Solar Beam
    [78675]   = 6,    -- Solar Beam
    [81261]   = 6,    -- Solar Beam

    -- Disarms
    [676]     = 5,    -- Disarm
    [15752]   = 5,    -- Disarm
    [14251]   = 5,    -- Riposte
    [51722]   = 5,    -- Dismantle
    [50541]   = 5,    -- Clench (Scorpid)
    [91644]   = 5,    -- Snatch (Bird of Prey)
    [117368]  = 5,    -- Grapple Weapon
    [126458]  = 5,    -- Grapple Weapon (Symbiosis)
    [137461]  = 5,    -- Ring of Peace (Disarm)
    [118093]  = 5,    -- Disarm (Voidwalker/Voidlord)
    [142896]  = 5,    -- Disarmed
    [116844]  = 5,    -- Ring of Peace (Silence / Disarm)

    -- Important Stuff
    [116849]  = 4.5,    -- life Cocoon
    [110575]  = 4.5,    -- Icebound Fortitude (Druid)
    [48792]   = 4.5,    -- Icebound Fortitude
    [122783]  = 4.5,    -- Diffuse Magic
    [125174]  = 4.5,    -- Monk: Touch of Karma
    [110909]  = 4.5,    -- Alter Time
    --[378081] = 4.5, -- Natures's Swiftness --not mop

    -- Roots
    [44047]   = 4,      -- Chastise (Root)
    [339]     = 4,      -- Entangling Roots
    [26989]   = 4,      -- Entangling Roots
    [27010]   = 4,      -- Nature's Grasp
    [19975]   = 4,      -- Entangling Roots (Nature's Grasp talent)
    [19306]   = 4,      -- Counterattack
    [25999]   = 4,      -- Boar Charge
    [4167]    = 4,      -- Web
    [122]     = 4,      -- Frost Nova
    [27088]   = 4,      -- Frost Nova
    [33395]   = 4,      -- Freeze (Water Elemental)
    [96294]   = 4,      -- Chains of Ice (Chilblains)
    [113275]  = 4,      -- Entangling Roots (Symbiosis)
    [113770]  = 4,      -- Entangling Roots (Treant)
    [102359]  = 4,      -- Mass Entanglement
    [128405]  = 4,      -- Narrow Escape
    [90327]   = 4,      -- Lock Jaw (Dog)
    [54706]   = 4,      -- Venom Web Spray (Silithid)
    [50245]   = 4,      -- Pin (Crab)
    [110693]  = 4,      -- Frost Nova (Symbiosis)
    [116706]  = 4,      -- Disable
    [87194]   = 4,      -- Glyph of Mind Blast
    [114404]  = 4,      -- Void Tendrils
    [115197]  = 4,      -- Partial Paralysis
    [63685]   = 4,      -- Freeze (Frost Shock)
    [107566]  = 4,      -- Staggering Shout
    [115757]  = 4,      -- Frost nova
    [105771]  = 4,      -- Warbringer
    [53148]   = 4,      -- Charge
    [136634]  = 4,      -- Narrow Escape
    --[127797] = 4, -- Ursol's Vortex
    [81210]   = 4,      -- Net
    [35963]   = 4,      -- Improved Wing Clip
    [19185]   = 4,      -- Entrapment
    [16979]   = 4,      -- Feral Charge
    [23694]   = 4,      -- Improved Hamstring
    [13120]   = 4,      -- Net-o-Matic
    [64803]   = 4,      -- Entrapment
    [111340]  = 4,      -- Ice Ward
    [123407]  = 4,      -- Spinning Fire Blossom
    [64695]   = 4,      -- Earthgrab Totem
    [91807]   = 4,      -- Shambling Rush
    [135373]  = 4,      -- Entrapment
    [45334]   = 4,      -- Immobilized

    [22734]   = 3.6,    -- Drink
    [28612]   = 3.6,    -- Conjured Food
    [33717]   = 3.6,    -- Conjured Food

    -- Defensive Buffs
    [115610]  = 3.5,    -- Temporal Shield
    [147833]  = 3.4,    -- Intervene
    [114029]  = 3.4,    -- Safeguard
    [3411]    = 3.4,    -- Intervene
    [122292]  = 3.4,    -- Intervene (Symbiosis)
    [53476]   = 3.4,    -- Intervene (Hunter Pet)
    [111264]  = 3.3,    -- Ice Ward (Buff)
    [89485]   = 3.3,    -- Inner Focus (instant cast immunity)
    [113862]  = 3.3,    -- Greater Invisibility (90% dmg reduction)
    [111397]  = 3.3,    -- Blood Horror (flee on attack)
    [45182]   = 3.2,    -- Cheating Death (85% reduced inc dmg)
    [31821]   = 3.2,    -- Aura Mastery
    [53480]   = 3.1,    -- Roar of Sacrifice
    --[124280] = 1, -- Touch of Karma (Debuff)
    --[122470] = 1, -- Touch of Karma (Debuff)
    [871]     = 3,      -- Shield Wall
    [118038]  = 3,      -- Die by the Sword
    [33206]   = 3,      -- Pain Suppresion
    [47788]   = 3,      -- Guardian Spirit
    [47000]   = 3,      -- Improved Blink
    [5277]    = 3,      -- Evasion
    [26669]   = 3,      -- Evasion
    [126456]  = 3,      -- Fortifying Brew (Symbiosis)
    [110791]  = 3,      -- Evasion (Symbiosis)
    [122291]  = 3,      -- Unending Resolve (Symbiosis)
    [30823]   = 3,      -- Shamanistic Rage
    [18499]   = 3,      -- Berserker Rage
    [55694]   = 3,      -- Enraged Regeneration
    [31842]   = 3,      -- Divine Favor
    [1044]    = 3,      -- Hand of Freedom
    [22812]   = 3,      -- Barkskin
    [47484]   = 3,      -- Huddle
    [97463]   = 3,      -- Rallying Cry
    [86669]   = 3,      -- Guardian of Ancient Kings
    [108359]  = 3,      -- Dark Regeneration
    [108416]  = 3,      -- Sacrificial Pact
    [104773]  = 3,      -- Unending Resolve
    [110913]  = 3,      -- Dark Bargain
    [79206]   = 3,      -- Spiritwalker's Grace (movement casting)
    [108271]  = 3,      -- Astral Shift
    [108281]  = 3,      -- Ancestral Guidance (healing)
    [31616]   = 3,      -- Nature’s Guardian
    [114052]  = 3,      -- Ascendance (Restoration)
    [61336]   = 3,      -- Survival Instincts
    [106922]  = 3,      -- Might of Ursoc
    [122278]  = 3,      -- Dampen Harm
    [120954]  = 3,      -- Fortifying Brew
    [115176]  = 3,      -- Zen Meditation
    [81782]   = 3,      -- Power Word: Barrier
    [109964]  = 2.9,    -- Spirit Shell (Buff)
    [102342]  = 2.9,    -- Ironbark
    [50461]   = 2.9,    -- Anti-Magic Zone
    [29166]   = 2.9,    -- Innervate
    [30458]   = 2.9,    -- Nigh Invulnerability Shield
    [30457]   = 2.9,    -- Nigh Invulnerability Belt Backfire
    [114908]  = 2.8,    -- Spirit Shell (Absorb Shield)
    [64901]   = 2.8,    -- Hymn of Hope
    [98007]   = 2.8,    -- Spirit Link Totem
    [114214]  = 2.5,    -- Angelic Bulwark
    [114893]  = 2.5,    -- Stone Bulwark Totem
    [145629]  = 2.5,    -- Anti-Magic Zone
    [117679]  = 2.5,    -- Incarnation: Tree of Life

    -- Offensive Buffs
    [13750]   = 2,       -- Adrenaline Rush
    [12042]   = 2,       -- Arcane Power
    [31884]   = 2,       -- Avenging Wrath
    [34936]   = 2,       -- Backlash
    [50334]   = 2,       -- Berserk
    [2825]    = 2,       -- Bloodlust
    [12292]   = 2,       -- Death Wish
    [16166]   = 2,       -- Elemental Mastery
    [12051]   = 2,       -- Evocation
    [12472]   = 2,       -- Icy Veins
    [131078]  = 2,       -- Icy Veins (split)
    [32182]   = 2,       -- Heroism
    [51690]   = 2,       -- Killing Spree
    [17941]   = 2,       -- Shadow Trance
    [10060]   = 2,       -- Power Infusion
    [3045]    = 2,       -- Rapid Fire
    [1719]    = 2,       -- Recklessness
    [51713]   = 2,       -- Shadow Dance
    [107574]  = 2,       -- Avatar
    [121471]  = 2,       -- Shadow Blades
    [14177]   = 2,       -- Cold Blood
    [18708]   = 2,       -- Fel Domination
    [47241]   = 2,       -- Metamorphosis
    [105809]  = 2,       -- Holy Avenger
    [86698]   = 2,       -- Guardian of Ancient Kings (alt)
    [113858]  = 2,       -- Dark Soul: Instability
    [113860]  = 2,       -- Dark Soul: Misery
    [113861]  = 2,       -- Dark Soul: Knowledge
    [114050]  = 2,       -- Ascendance (Enhancement)
    [114051]  = 2,       -- Ascendance (Elemental)
    [102543]  = 2,       -- Incarnation: King of the Jungle
    [102560]  = 2,       -- Incarnation: Chosen of Elune
    [106951]  = 2,       -- Berserk
    [124974]  = 2,       -- Nature’s Vigil
    [51271]   = 2,       -- Pillar of Frost
    [49206]   = 2,       -- Summon Gargoyle
    [114868]  = 2,       -- Soul Reaper (Buff)
    [137639]  = 2,       -- Storm, Earth, and Fire
    [12328]   = 2,       -- Sweeping Strikes
    [84747]   = 1.9,     -- Deep Insight (Red Buff Rogue)
    [1247275] = 1.9,     -- Tigereye Brew (Monk)

    [76577]   = 1.8,     -- Smoke Bomb
    [88611]   = 1.8,     -- Smoke Bomb

    [6346]    = 1.7,     -- Fear Ward
    [110717]  = 1.7,     -- Fear Ward (Symbiosis)
    [7744]    = 1.7,     -- Will of the Forsaken
    [126084]  = 1.6,     -- Fingers of Frost
    [44544]   = 1.6,     -- Fingers of Frost
    [77616]   = 1.6,     -- Dark Simulacrum (Buff, has spell)

    -- Freedoms
    [96268]   = 1.4,    -- Deaths Advance
    [62305]   = 1.4,    -- Master's Call
    [5024]    = 1.4,    -- Flee (Skull of Impending Doom)
    [114896]  = 1.4,    -- Windwalk Totem
    [116841]  = 1.4,    -- Tiger's Lust (70% speed)

    -- Lesser defensives
    [1966]    = 1.3,   -- Feint
    --[102351] = 1.2, -- Cenarion Ward
    --[33763] = 1.1, -- Lifebloom
    --[121279] = 1.1, -- Lifebloom


    -- Misc
    [34709]  = 0.9,     -- Shadow Sight (Arena Eye)
    [110806] = 0.9,     -- Spirit Walker's Grace (Symbiosis)
    [11426]  = 0.8,     -- Ice Barrier
    [113656] = 0.8,     -- Fists of Fury
    [83853]  = 0.8,     -- Combustion (Debuff)
    --[41635]  = 0.5, -- Prayer of Mending
    [64844]  = 0.5,     -- Divine Hymn
    [114206] = 0.5,     -- Skull Banner

    -- Forms
    [5487]   = 0.5,     -- Bear Form
    [783]    = 0.5,     -- Travel Form
    [768]    = 0.5,     -- Cat Form
    [24858]  = 0.5,     -- Moonkin Form

    -- Slows
    [50435]  = 0.4,     -- Chilblains (50%)
    [12323]  = 0.4,     -- Piercing Howl (50%)
    [113092] = 0.4,     -- Frost Bomb (70%)
    [120]    = 0.4,     -- Cone of Cold (70%)
    [60947]  = 0.4,     -- Nightmare (30%)
    [1715]   = 0.4,     -- Hamstring (50%)
    [116095] = 0.4,     -- Disable (50%)

    -- Miscellaneous
    [25771]  = 0.3,     -- Forbearance (debuff)
    [115867] = 0.1,     -- Mana Tea
    [125195] = 0.1,     -- Tigereye Brew (Stacking)
    --[28612]  = 0.2, -- Cojured Food --not mop
    --[33717]  = 0.2, -- Cojured Food --not mop
    [108366] = 0.1,     -- Soul Leech
    [41425]  = 0.1,     -- Hypothermia
    [108199] = 0,       -- Gorefiend's Grasp
    [102793] = 0,       -- Ursol's Vortex
    [61391]  = 0,       -- Typhoon
    [13812]  = 0,       -- Glyph of Explosive Trap
    [51490]  = 0,       -- Thunderstorm
    [6360]   = 0,       -- Whiplash
    [115770] = 0,       -- Fellash
    [114018] = 0,       -- Shroud of Concealment
    [110960] = 0,       -- Greater Invisibility (Invis)
    [66]     = 0,       -- Invisibility
    [2457]   = 0,       -- Battle Stance
    [2458]   = 0,       -- Berserker Stance
    [71]     = 0,       -- Defensive Stance



    -- ##########################
    -- Cata bonus ids, needs to be verified
    -- ##########################
    -- *** Controlled Stun Effects ***
    [93433] = 9,     -- Burrow Attack (Worm)
    --[83046] = 9, -- Improved Polymorph (Rank 1) --not mop
    --[83047] = 9, -- Improved Polymorph (Rank 2) --not in mop
    --[2812]  = 9, -- Holy Wrath
    --[88625] = "Stunned", -- Holy Word: Chastise
    --[93986] = 9, -- Aura of Foreboding--not mop
    [54786] = 9,     -- Demon Leap

    -- *** Non-controlled Stun Effects ***
    [85387] = 9,     -- Aftermath
    [15283] = 9,     -- Stunning Blow (Weapon Proc)
    [56]    = 9,     -- Stun (Weapon Proc)

    -- *** Fear Effects ***
    [5134]  = 9,     -- Flash Bomb Fear (Item)

    -- *** Controlled Root Effects ***
    --[96293] = 4, -- Chains of Ice (Chilblains Rank 1) --not mop
    --[87193] = 4, -- Paralysis -- not mop

    -- *** Non-controlled Root Effects ***
    [47168] = 4,     -- Improved Wing Clip
    --[83301] = 4, -- Improved Cone of Cold (Rank 1) --not mop
    --[83302] = 4, -- Improved Cone of Cold (Rank 2) --not mop
    --[55080] = 4, -- Shattered Barrier (Rank 1) --not mop
    --[83073] = 4, -- Shattered Barrier (Rank 2) --not mop
    [50479] = 6,     -- Nether Shock (Nether Ray)
    --[86759] = 6, -- Silenced - Improved Kick (Rank 2) --not mop
}