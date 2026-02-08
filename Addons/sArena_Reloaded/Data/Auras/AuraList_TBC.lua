-- Auras we want tooltip info from to display as stacks
sArenaMixin.tooltipInfoAuras = {
}

-- Auras reducing interrupt durations
sArenaMixin.spellLockReducer = {
}

-- Stance auras for TBC (stances don't have real auras, only cast/aura events)
sArenaMixin.stanceAuras = {
    [71]   = 0, -- Defensive Stance
    [2458] = 0, -- Berserker Stance
    [2457] = 0, -- Battle Stance
}

-- Active stance auras per unit: [unit] = spellID (e.g. ["arena1"] = 71)
sArenaMixin.activeStanceAuras = {}

sArenaMixin.auraList = {
    -- Special
    [23920]   = 10,    -- Spell Reflection
    [8178]    = 10,    -- Grounding Totem Effect

    -- Full CC (Stuns and Disorients)
    [33786]   = 9,    -- Cyclone (Disorient)
    [5211]    = 9,    -- Bash
    [6798]    = 9,    -- Bash
    [8983]    = 9,    -- Bash
    [6789]    = 9,    -- Death Coil
    [17925]   = 9,    -- Death Coil
    [17926]   = 9,    -- Death Coil
    [27223]   = 9,    -- Death Coil
    [1833]    = 9,    -- Cheap Shot
    [7922]    = 9,    -- Charge Stun
    [853]     = 9,    -- Hammer of Justice
    [5588]    = 9,    -- Hammer of Justice
    [5589]    = 9,    -- Hammer of Justice
    [10308]   = 9,    -- Hammer of Justice
    [30153]   = 9,    -- Pursuit
    [24394]   = 9,    -- Intimidation
    [19577]   = 9,    -- Intimidation
    [408]     = 9,    -- Kidney Shot
    [8643]    = 9,    -- Kidney Shot
    [22570]   = 9,    -- Maim
    [9005]    = 9,    -- Pounce
    [9823]    = 9,    -- Pounce
    [9827]    = 9,    -- Pounce
    [27006]   = 9,    -- Pounce
    [6572]    = 9,    -- Ravage
    [30283]   = 9,    -- Shadowfury
    [30413]   = 9,    -- Shadowfury
    [30414]   = 9,    -- Shadowfury
    [20549]   = 9,    -- War Stomp
    [99]      = 9,    -- Disorienting Roar
    [22703]   = 9,    -- Inferno Effect
    [20511]   = 9,    -- Intimidating Shout (secondary)
    [15618]   = 9,    -- Snap Kick
    [12809]   = 9,    -- Concussion Blow
    [20253]   = 9,    -- Intercept Stun (Rank 1)
    [20614]   = 9,    -- Intercept Stun (Rank 2)
    [20615]   = 9,    -- Intercept Stun (Rank 3)
    [25273]   = 9,    -- Intercept Stun (Rank 4)
    [13237]   = 9,    -- Goblin Mortar (Item)
    [835]     = 9,    -- Tidal Charm (Item)

    -- Stun Procs
    [34510]   = 9,    -- Stun (various procs)
    [5530]    = 9,    -- Mace Stun Effect
    [15269]   = 9,    -- Blackout Stun
    [16922]   = 9,    -- Imp Starfire Stun
    [11103]   = 9,    -- Impact
    [12355]   = 9,    -- Impact
    [12357]   = 9,    -- Impact
    [12358]   = 9,    -- Impact
    [12359]   = 9,    -- Impact
    [12360]   = 9,    -- Impact
    [23454]   = 9,    -- Stun
    [19410]   = 9,    -- Improved Concussive Shot
    [20170]   = 9,    -- Seal of Justice Stun
    [18093]   = 9,    -- Pyroclasm
    [39796]   = 9,    -- Stoneclaw Stun
    [12798]   = 9,    -- Revenge Stun

    -- Disorient / Incapacitate / Fear / Charm
    [2094]    = 9,    -- Blind
    [31661]   = 9,    -- Dragon's Breath
    [33041]   = 9,    -- Dragon's Breath
    [33042]   = 9,    -- Dragon's Breath
    [33043]   = 9,    -- Dragon's Breath
    [5782]    = 9,    -- Fear
    [6213]    = 9,    -- Fear
    [6215]    = 9,    -- Fear
    [3355]    = 9,    -- Freezing Trap
    [14309]   = 9,    -- Freezing Trap Effect
    [1776]    = 9,    -- Gouge
    [1777]    = 9,    -- Gouge
    [8629]    = 9,    -- Gouge
    [11285]   = 9,    -- Gouge
    [11286]   = 9,    -- Gouge
    [38764]   = 9,    -- Gouge
    [2637]    = 9,    -- Hibernate
    [18657]   = 9,    -- Hibernate
    [18658]   = 9,    -- Hibernate
    [5484]    = 9,    -- Howl of Terror
    [17928]   = 9,    -- Howl of Terror
    [5246]    = 9,    -- Intimidating Shout
    [25274]   = 9,    -- Intercept Stun
    [605]     = 9,    -- Mind Control
    [10911]   = 9,    -- Mind Control
    [10912]   = 9,    -- Mind Control
    [118]     = 9,    -- Polymorph
    [12824]   = 9,    -- Polymorph
    [12825]   = 9,    -- Polymorph
    [12826]   = 9,    -- Polymorph
    [28271]   = 9,    -- Polymorph: Turtle
    [28272]   = 9,    -- Polymorph: Pig
    [8122]    = 9,    -- Psychic Scream
    [8124]    = 9,    -- Psychic Scream
    [10888]   = 9,    -- Psychic Scream
    [10890]   = 9,    -- Psychic Scream
    [20066]   = 9,    -- Repentance
    [2070]    = 9,    -- Sap
    [6770]    = 9,    -- Sap
    [11297]   = 9,    -- Sap
    [1513]    = 9,    -- Scare Beast
    [14326]   = 9,    -- Scare Beast
    [14327]   = 9,    -- Scare Beast
    [19503]   = 9,    -- Scatter Shot
    [6358]    = 9,    -- Seduction
    [20407]   = 9,    -- Seduction
    [30850]   = 9,    -- Seduction
    [9484]    = 9,    -- Shackle Undead
    [1090]    = 9,    -- Sleep
    [10326]   = 9,    -- Turn Evil
    [19386]   = 9,    -- Wyvern Sting
    [24131]   = 9,    -- Wyvern Sting
    [24132]   = 9,    -- Wyvern Sting
    [24133]   = 9,    -- Wyvern Sting
    [24134]   = 9,    -- Wyvern Sting
    [24135]   = 9,    -- Wyvern Sting
    [27068]   = 9,    -- Wyvern Sting
    [27069]   = 9,    -- Wyvern Sting
    [710]     = 9,    -- Banish
    [18647]   = 9,    -- Banish

    -- Immunities
    [19263]   = 7,      -- Deterrence
    [642]     = 7,      -- Divine Shield
    [1020]    = 7,      -- Divine Shield
    [498]     = 7,      -- Divine Protection
    [45438]   = 7,      -- Ice Block
    [34692]   = 7,      -- The Beast Within
    [26064]   = 7,      -- Shell Shield
    [19574]   = 7,      -- Bestial Wrath
    [1022]    = 7,      -- Hand of Protection
    [5599]    = 7,      -- Blessing of Protection
    [10278]   = 7,      -- Blessing of Protection
    [3169]    = 7,      -- Invulnerability
    [20230]   = 7,      -- Retaliation
    [16621]   = 7,      -- Self Invulnerability
    [20594]   = 7,      -- Stoneform -- FIX
    [31224]   = 7,      -- Cloak of Shadows
    [27827]   = 7,      -- Spirit of Redemption

    [12043]   = 6.6,    -- Presence of Mind
    [16188]   = 6.6,    -- Nature's Swiftness

    -- Anti-CCs
    [6940]    = 6.5,    -- Hand of Sacrifice
    [20729]   = 6.5,    -- Blessing of Sacrifice
    [27147]   = 6.5,    -- Blessing of Sacrifice
    [27148]   = 6.5,    -- Blessing of Sacrifice
    [5384]    = 6.5,    -- Feign Death
    [34471]   = 6.5,    -- The Beast Within

    -- Silences
    [25046]   = 6,    -- Arcane Torrent
    [1330]    = 6,    -- Garrote
    [15487]   = 6,    -- Silence (Priest)
    [18498]   = 6,    -- Silenced - Gag Order (Warrior)
    [18469]   = 6,    -- Silenced - Improved Counterspell (Mage)
    [18425]   = 6,    -- Silenced - Improved Kick (Rogue)
    [34490]   = 6,    -- Silencing Shot (Hunter)
    [19244]   = 6,    -- Spell Lock (Felhunter)
    [30108]   = 6,    -- Unstable Affliction (Silence)
    [30404]   = 6,    -- Unstable Affliction (Silence)
    [30405]   = 6,    -- Unstable Affliction (Silence)
    [31117]   = 6,    -- UA silence (on dispel)
    [24259]   = 6,    -- Spell Lock (Felhunter)
    [43523]   = 6,    -- Unstable Affliction (Silence effect)
    [28730]   = 6,    -- Arcane Torrent (Mana)
    [31935]   = 6,    -- Avenger's Shield

    [1766]    = 6,    -- Kick (Rogue)
    [2139]    = 6,    -- Counterspell (Mage)
    [6552]    = 6,    -- Pummel (Warrior)
    [19647]   = 6,    -- Spell Lock (Warlock)
    -- [96231] = 6, -- Rebuke (Paladin) -- intentionally commented out

    -- Disarms
    [676]     = 5,    -- Disarm
    [15752]   = 5,    -- Disarm
    [14251]   = 5,    -- Riposte
    [34097]   = 5,    -- Riposte 2 (TODO: not sure which ID is correct)

    -- Important Stuff
    --[0] = 4.5, --

    -- Roots
    [44041]   = 4,      -- Chastise (Root)
    [44043]   = 4,      -- Chastise (Root)
    [44044]   = 4,      -- Chastise (Root)
    [44045]   = 4,      -- Chastise (Root)
    [44046]   = 4,      -- Chastise (Root)
    [44047]   = 4,      -- Chastise (Root)
    [339]     = 4,      -- Entangling Roots
    [1062]    = 4,      -- Entangling Roots
    [5195]    = 4,      -- Entangling Roots
    [5196]    = 4,      -- Entangling Roots
    [9852]    = 4,      -- Entangling Roots
    [9853]    = 4,      -- Entangling Roots
    [26989]   = 4,      -- Entangling Roots
    [19970]   = 4,      -- Entangling Roots (Nature's Grasp)
    [19971]   = 4,      -- Entangling Roots (Nature's Grasp)
    [19972]   = 4,      -- Entangling Roots (Nature's Grasp)
    [19973]   = 4,      -- Entangling Roots (Nature's Grasp)
    [19974]   = 4,      -- Entangling Roots (Nature's Grasp)
    [19975]   = 4,      -- Entangling Roots (Nature's Grasp talent)
    [27010]   = 4,      -- Nature's Grasp
    [25999]   = 4,      -- Boar Charge
    [4167]    = 4,      -- Web
    [122]     = 4,      -- Frost Nova
    [865]     = 4,      -- Frost Nova
    [6131]    = 4,      -- Frost Nova
    [10230]   = 4,      -- Frost Nova
    [27088]   = 4,      -- Frost Nova
    [33395]   = 4,      -- Freeze (Water Elemental)
    [35963]   = 4,      -- Improved Wing Clip
    [19185]   = 4,      -- Entrapment
    [16979]   = 4,      -- Feral Charge
    [23694]   = 4,      -- Improved Hamstring
    [13120]   = 4,      -- Net-o-Matic
    [45334]   = 4,      -- Immobilized
    [19306]   = 4,      -- Counterattack (Rank 1)
    [20909]   = 4,      -- Counterattack (Rank 2)
    [20910]   = 4,      -- Counterattack (Rank 3)
    [27067]   = 4,      -- Counterattack (Rank 4)
    [19229]   = 4,      -- Improved Wing Clip
    [12494]   = 4,      -- Frostbite

    [22734]   = 3.6,    -- Drink

    -- Defensive Buffs
    [3411]    = 3.4,    -- Intervene
    [45182]   = 3.2,    -- Cheating Death (85% reduced inc dmg)
    [31821]   = 3.2,    -- Aura Mastery
    [871]     = 3,      -- Shield Wall
    [33206]   = 3,      -- Pain Suppresion
    [47000]  = 3, -- Improved Blink --not mop
    [2983]    = 3,      -- Sprint
    [5277]    = 3,      -- Evasion
    [8696]    = 3,      -- Sprint
    [11305]   = 3,      -- Sprint
    [26669]   = 3,      -- Evasion
    [17116]   = 6.6,    -- Nature's Swiftness (Shaman)
    [30823]   = 3,      -- Shamanistic Rage
    [30824]   = 3,      -- Shamanistic Rage
    [18499]   = 3,      -- Berserker Rage
    [31842]   = 3,      -- Divine Favor
    [1044]    = 3,      -- Hand of Freedom
    [22812]   = 3,      -- Barkskin
    [31616]   = 3,      -- Nature’s Guardian
    [12976]   = 2.9,    -- Last Stand
    [29166]   = 2.9,    -- Innervate
    [30458]   = 2.9,    -- Nigh Invulnerability Shield

    -- Offensive Buffs
    [13750]   = 2,       -- Adrenaline Rush
    [12042]   = 2,       -- Arcane Power
    [31884]   = 2,       -- Avenging Wrath
    [34936]   = 2,       -- Backlash
    [2825]    = 2,       -- Bloodlust
    [12292]   = 2,       -- Death Wish
    [16166]   = 2,       -- Elemental Mastery
    [12051]   = 2,       -- Evocation
    [12472]   = 2,       -- Icy Veins
    [32182]   = 2,       -- Heroism
    [10060]   = 2,       -- Power Infusion
    [3045]    = 2,       -- Rapid Fire
    [1719]    = 2,       -- Recklessness
    [12328]   = 2,       -- Sweeping Strikes
    [31641]   = 2,       -- Blazing Speed
    [31642]   = 2,       -- Blazing Speed
    [31643]   = 2,       -- Blazing Speed
    [14177] = 1.9,       -- Cold Blood

    [6346]    = 1.7,     -- Fear Ward
    [7744]    = 1.7,     -- Will of the Forsaken
    [20216] = 1.6, -- Divine Favor

    -- Freedoms
    [5024]    = 1.4,    -- Flee (Skull of Impending Doom)

    -- Lesser defensives
    [1966]    = 1.3,   -- Feint

    -- Misc
    [18708] = 0.9,      -- Fel Domination
    [34709]  = 0.9,     -- Shadow Sight (Arena Eye)
    [11426]  = 0.8,     -- Ice Barrier

    -- Forms
    [5487]   = 0.5,     -- Bear Form
    [783]    = 0.5,     -- Travel Form
    [768]    = 0.5,     -- Cat Form
    [24858]  = 0.5,     -- Moonkin Form

    -- Slows
    [12323]  = 0.4,     -- Piercing Howl (50%)
    [120]    = 0.4,     -- Cone of Cold (70%)
    [1715]   = 0.4,     -- Hamstring (50%)

    [1953] = 0.5,      -- Blink
    [46989] = 0.4,     -- Improved Blink (25% chance to miss attacks and spells, 4sec buff)

    -- Miscellaneous
    [25771]  = 0.3,     -- Forbearance (debuff)
    [20600]  = 0.2,    -- Perception
    [28612]  = 0.2, -- Cojured Food --not mop
    [33717]  = 0.2, -- Cojured Food --not mop
    [41425]  = 0.1,     -- Hypothermia
    [13812]  = 0,       -- Glyph of Explosive Trap
    [6360]   = 0,       -- Whiplash
    [66]     = 0,       -- Invisibility



    -- ##########################
    -- Cata bonus ids, needs to be verified
    -- ##########################
    -- *** Controlled Stun Effects ***
    [2812]  = 9, -- Holy Wrath

    -- *** Non-controlled Stun Effects ***
    [15283] = 9,     -- Stunning Blow (Weapon Proc)
    [56]    = 9,     -- Stun (Weapon Proc)

    -- *** Fear Effects ***
    [5134]  = 9,     -- Flash Bomb Fear (Item)

    -- *** Non-controlled Root Effects ***
    [47168] = 4,     -- Improved Wing Clip
}