sArenaMixin.interruptList = {
    [1766] = 3,     -- Kick (Rogue)
    [2139] = 5,     -- Counterspell (Mage)
    [6552] = 3,     -- Pummel (Warrior)
    [19647] = 5,    -- Spell Lock (Warlock)
    [47528] = 3,    -- Mind Freeze (Death Knight)
    [57994] = 2,    -- Wind Shear (Shaman)
    [91802] = 2,    -- Shambling Rush (Death Knight)
    [96231] = 3,    -- Rebuke (Paladin)
    [106839] = 3,   -- Skull Bash (Feral)
    [115781] = 5,   -- Optical Blast (Warlock)
    [116705] = 3,   -- Spear Hand Strike (Monk)
    [132409] = 5,   -- Spell Lock (Warlock)
    [147362] = 3,   -- Countershot (Hunter)
    [171138] = 5,   -- Shadow Lock (Warlock)
    [183752] = 3,   -- Consume Magic (Demon Hunter)
    [187707] = 3,   -- Muzzle (Hunter)
    [212619] = 5,   -- Call Felhunter (Warlock)
    [231665] = 3,   -- Avengers Shield (Paladin)
    [351338] = 4,   -- Quell (Evoker)
    [97547]  = 4,   -- Solar Beam
}
sArenaMixin.auraList = tInvert({
    -- Higher up = higher priority

    -- CCs
    33786,  -- Cyclone (Disorient)
    5211,   -- Mighty Bash (Stun)
    108194, -- Asphyxiate (Unholy) (Stun)
    221562, -- Asphyxiate (Blood) (Stun)
    377048, -- Absolute Zero (Frost) (Stun)
    91797,  -- Monstrous Blow (Mutated Ghoul) (Stun)
    287254, -- Dead of Winter (Stun)
    210141, -- Zombie Explosion (Stun)
    118905, -- Static Charge (Stun)
    1833,   -- Cheap Shot (Stun)
    853,    -- Hammer of Justice (Stun)
    179057, -- Chaos Nova (Stun)
    132169, -- Storm Bolt (Stun)
    408,    -- Kidney Shot (Stun)
    163505, -- Rake (Stun)
    119381, -- Leg Sweep (Stun)
    89766,  -- Axe Toss (Stun)
    30283,  -- Shadowfury (Stun)
    24394,  -- Intimidation (Stun)
    117526, -- Binding Shot (Stun)
	-- 117405, --  Binding Shot
	357021, -- Consecutive Concussion (Stun)
    211881, -- Fel Eruption (Stun)
    91800,  -- Gnaw (Stun)
    205630, -- Illidan's Grasp (Stun)
    208618, -- Illidan's Grasp (Stun)
    203123, -- Maim (Stun)
    202244, -- Overrun
    200200, -- Holy Word: Chastise, Censure Talent (Stun)
    22703,  -- Infernal Awakening (Stun)
    132168, -- Shockwave (Stun)
    20549,  -- War Stomp (Stun)
    199085, -- Warpath (Stun)
    305485, -- Lightning Lasso (Stun)
    64044,  -- Psychic Horror (Stun)
    255723, -- Bull Rush (Stun)
    202346, -- Double Barrel (Stun)
    213688, -- Fel Cleave (Stun)
    204399, -- Earthfury (Stun)
    118345, -- Pulverize (Stun)
    171017, -- Meteor Strike (Infernal) (Stun)
    171018, -- Meteor Strike (Abyssal) (Stun)
    46968,  -- Shockwave
    132168, -- Shockwave (Protection)
    287712, -- Haymaker (Stun)
    372245, -- Terror of the Skies (stun)
	389831, -- Snowdrift (Stun)

    5246,   -- Intimidating Shout (Disorient)
	316593, -- Intimidating Shout (Menace Main Target) (Disorient)
	316595, -- Intimidating Shout (Menace Other Targets) (Disorient)
    8122,   -- Psychic Scream (Disorient)
    2094,   -- Blind (Disorient)
    605,    -- Mind Control (Disorient)
    105421, -- Blinding Light (Disorient)
    207167, -- Blinding Sleet (Disorient)
    31661,  -- Dragon's Breath (Disorient)
    207685, -- Sigil of Misery (Disorient)
    198909, -- Song of Chi-ji (Disorient)
    202274, -- Incendiary Brew (Disorient)
    130616, -- Fear (Warlock Horrify talent)
    118699, -- Fear (Disorient)
    1513,   -- Scare Beast (Disorient)
    10326,  -- Turn Evil (Disorient)
    6358,   -- Seduction (Disorient)
    261589, -- Seduction 2 (Disorient)
    5484, -- Howl (Disorient)
    115268, -- Mesmerize (Shivarra) (Disorient)
    87204,  -- Sin and Punishment (Disorient)
    2637,   -- Hibernate (Disorient)
    226943, -- Mind Bomb (Disorient)
    236748, -- Intimidating Roar (Disorient)
    331866, -- Agent of Chaos (Disorient)
    324263, -- Sulfuric Emission (Disorient)
    360806, -- Sleep Walk (Disorient)
	358861, -- Void Volley

    51514,  -- Hex (Incapacitate)
    211004, -- Hex: Spider (Incapacitate)
    210873, -- Hex: Raptor (Incapacitate)
    211015, -- Hex: Cockroach (Incapacitate)
    211010, -- Hex: Snake (Incapacitate)
    196942, -- Hex: Voodoo Totem (Incapacitate)
    277784, -- Hex: Wicker Mongrel (Incapacitate)
    277778, -- Hex: Zandalari Tendonripper (Incapacitate)
    269352, -- Hex: Skeletal Hatchling (Incapacitate)
    309328, -- Hex: Living Honey (Incapacitate)
    118,    -- Polymorph (Incapacitate)
    61305,  -- Polymorph: Black Cat (Incapacitate)
    28272,  -- Polymorph: Pig (Incapacitate)
    61721,  -- Polymorph: Rabbit (Incapacitate)
    61780,  -- Polymorph: Turkey (Incapacitate)
    28271,  -- Polymorph: Turtle (Incapacitate)
    161353, -- Polymorph: Polar Bear Cub (Incapacitate)
    126819, -- Polymorph: Porcupine (Incapacitate)
    161354, -- Polymorph: Monkey (Incapacitate)
    161355, -- Polymorph: Penguin (Incapacitate)
    161372, -- Polymorph: Peacock (Incapacitate)
    277792, -- Polymorph: Bumblebee (Incapacitate)
    277787, -- Polymorph: Baby Direhorn (Incapacitate)
	391622, -- Polymorph: Duck (Incapacitate)
	383121, -- Mass Polymorph (Incapacitate)
    3355,   -- Freezing Trap (Incapacitate)
    203337, -- Freezing Trap, Diamond Ice Honor Talent (Incapacitate)
    115078, -- Paralysis (Incapacitate)
    213691, -- Scatter Shot (Incapacitate)
    6770,   -- Sap (Incapacitate)
    20066,  -- Repentance (Incapacitate)
    200196, -- Holy Word: Chastise (Incapacitate)
    221527, -- Imprison, Detainment Honor Talent (Incapacitate)
    217832, -- Imprison (Incapacitate)
    99,     -- Incapacitating Roar (Incapacitate)
    82691,  -- Ring of Frost (Incapacitate)
    1776,   -- Gouge (Incapacitate)
    107079, -- Quaking Palm (Incapacitate)
    236025, -- Enraged Maim (Incapacitate)
    197214, -- Sundering (Incapacitate)
    9484,   -- Shackle Undead (Incapacitate)
    710,    -- Banish (Incapacitate)
    6789,   -- Mortal Coil (Incapacitate)

    -- Immunities
	378441, -- Time Stop
	354610, -- Demon Hunter: Glimpse
    642,    -- Divine Shield
    186265, -- Aspect of the Turtle
    45438,  -- Ice Block
    196555, -- Demon Hunter: Netherwalk
    47585,  -- Priest: Dispersion
	377362, -- Precog
    1022,   -- Blessing of Protection
    204018, -- Blessing of Spellwarding
    323524, -- Ultimate Form
    216113, -- Way of the Crane
    31224,  -- Cloak of Shadows
    212182, -- Smoke Bomb
    212183, -- Smoke Bomb
    8178,   -- Grounding Totem Effect
    199448, -- Blessing of Sacrifice
    236321, -- War Banner
    215769, -- Spirit of Redemption
    5277,   -- Rogue: Evasion
	227847, -- Warrior: Bladestorm (Arms)
    118038, -- Warrior: Die by the Sword
	357210, -- Deep Breath
	359816, -- Dream Flight
	408557, -- Phase Shift
	408558, -- Phase Shift
	362486, -- Keeper of the Grove
	116849, -- Monk: Life Cocoon
    212800, -- Demon Hunter: Blur
	147833, -- Friendly Intervene
    48792,  -- Death Knight: Icebound Fortitude
	409293, -- Burrow

    -- Interrupts
    1766,   -- Kick (Rogue)
    2139,   -- Counterspell (Mage)
    6552,   -- Pummel (Warrior)
    19647,  -- Spell Lock (Warlock)
    47528,  -- Mind Freeze (Death Knight)
    57994,  -- Wind Shear (Shaman)
    91802,  -- Shambling Rush (Death Knight)
    96231,  -- Rebuke (Paladin)
    106839, -- Skull Bash (Feral)
    115781, -- Optical Blast (Warlock)
    116705, -- Spear Hand Strike (Monk)
    132409, -- Spell Lock (Warlock)
    147362, -- Countershot (Hunter)
    171138, -- Shadow Lock (Warlock)
    183752, -- Consume Magic (Demon Hunter)
    187707, -- Muzzle (Hunter)
    212619, -- Call Felhunter (Warlock)
    231665, -- Avengers Shield (Paladin)
    351338, -- Quell (Evoker)
    97547,   -- Solar Beam

    -- Anti CCs
    23920,  -- Spell Reflection
    377362, -- Precognition
    213610, -- Priest: Holy Ward
    212295, -- Warlock: Nether Ward
    48707,  -- Death Knight: Anti-Magic Shell
    410358,  -- Death Knight: Anti-Magic Shell
    5384,   -- Hunter: Feign Death
    353319, -- Monk: Peaceweaver
    378464, -- Evoker: Nullifying Shroud
	31821, -- Aura Mastery
	206803, -- Rain from Above
    473909, -- Ancient of Lore
	

    -- Silences
    81261,  -- Solar Beam
    202933, -- Spider Sting
    356727, -- Spider Venom
    1330,   -- Garrote
    15487,  -- Silence
    199683, -- Last Word
    47476,  -- Strangulate
    31935,  -- Avenger's Shield
    204490, -- Sigil of Silence
    217824, -- Shield of Virtue
    43523,  -- Unstable Affliction Silence 1
    196364, -- Unstable Affliction Silence 2
    317589, -- Tormenting Backlash
	410065, -- Reactive Resin
    375901, -- Mindgames

    -- Disarms
    410126, 410201, -- Searing Glare
    236077, -- Disarm
    236236, -- Disarm (Protection)
    209749, -- Faerie Swarm (Disarm)
    233759, -- Grapple Weapon
    207777, -- Dismantle

	-- Offensive Debuffs
	383005, -- Chrono Loop
	372048, -- Opressing Roar
	356723, -- Scorpid Venom

    -- Roots
	376080, -- Spear
	105771, -- Charge
	356356, -- Warbringer
	324382, -- Clash
	114404, -- Void Tendril's
	356738, -- Earth Unleashed
	288515, -- Surge of Power
    339,    -- Entangling Roots
    170855, -- Entangling Roots (Nature's Grasp)
    201589, -- Entangling Roots (Tree of Life)
    235963, -- Entangling Roots (Feral honor talent)
    122,    -- Frost Nova
	386770, -- Freezing Cold
    102359, -- Mass Entanglement
    64695,  -- Earthgrab
    200108, -- Ranger's Net
    212638, -- Tracker's Net
    162480, -- Steel Trap
    204085, -- Deathchill
    233395, -- Frozen Center
    233582, -- Entrenched in Flame
    201158, -- Super Sticky Tar
    33395,  -- Freeze
    228600, -- Glacial Spike
    116706, -- Disable
    45334,  -- Immobilized
    53148,  -- Charge (Hunter Pet)
    190927, -- Harpoon
    136634, -- Narrow Escape (unused?)
	157997, -- Ice Nova
    378760, -- Frostbite
    233395, -- Deathchill (Remorseless Winter)
	204085, -- Deathchill (Chains of Ice)
    241887, -- Landslide
	355689, -- Landslide
	393456, -- Entrapment

    -- Refreshments
    167152, -- Mage Food
    274914, -- Rockskip Mineral Water
	396920, -- Delicious Dragon Spittle
	369162, -- drink
    452382, -- drink
    461063, -- quiet contemplation (earthen dwarf racial)

    -- Offensive Buffs
    51271,  -- Death Knight: Pillar of Frost
    -- 47568,  -- Death Knight: Empower Rune Weapon
    207289, -- Death Knight: Unholy Assault
    212800, -- Demon Hunter: Blur
    162264, -- Demon Hunter: Metamorphosis
    194223, -- Druid: Celestial Alignment
	383410, -- Druid: Celestial Alignment (Orbital Strike)
    102560, -- Druid: Incarnation: Chosen of Elune
	390414, -- Druid: Incarnation: Chosen of Elune (Orbital Strike)
	5217, -- Tiger's Fury
    102543, -- Druid: Incarnation: King of the Jungle
    19574,  -- Hunter: Bestial Wrath
    266779, -- Hunter: Coordinated Assault
    288613, -- Hunter: Trueshot
    -- 260402, -- Hunter: Double Tap
    365362, -- Mage: Arcane Surge
    190319, -- Mage: Combustion
    324220, -- Mage: Deathborne
    198144, -- Mage: Ice Form
    12472,  -- Mage: Icy Veins
    80353,  -- Mage: Time Warp
    152173, -- Monk: Serenity
    137639, -- Monk: Storm, Earth, and Fire
    31884,  -- Paladin: Avenging Wrath (Retribution)
    152262, -- Paladin: Seraphim
    231895, -- Paladin: Crusade
	185313,  -- Rogue: Shadow Dance
	185422,  -- Rogue: Shadow Dance
	457333, -- Death's Arrival
    197871, -- Priest: Dark Archangel
    194249, -- Priest: Voidform
    
    384631,  -- Rogue: Flagellation
    13750,  -- Rogue: Adrenaline Rush
    121471, -- Rogue: Shadow Blades
    114050, -- Shaman: Ascendance (Elemental)
    114051, -- Shaman: Ascendance (Enhancement)
    2825,   -- Shaman: Bloodlust
    204361, -- Shaman: Bloodlust (Honor Talent)
    32182,  -- Shaman: Heroism
    204362, -- Shaman: Heroism (Honor Talent)
    191634, -- Shaman: Stormkeeper
    204366, -- Shaman: Thundercharge
    113858, -- Warlock: Dark Soul: Instability
    113860, -- Warlock: Dark Soul: Misery
	399680, -- Soul Swap
	442726, -- Malevolence
	328774, -- Amp Curse


    107574, -- Warrior: Avatar
    227847, -- Warrior: Bladestorm (Arms)
    -- 260708, -- Warrior: Sweeping Strikes
    262228, -- Warrior: Deadly Calm
    1719,   -- Warrior: Recklessness
    375087, -- Evoker: Dragonrage
	370553, -- Evoker: Tip the Scales
    375087, -- Evoker: Dragonrage
    10060,  -- Priest: Power Infusion
    

    -- Defensive Buffs
	
    232707, -- Priest: Ray of Hope
	232708, -- Ray of Hope
    49039,  -- Death Knight: Lichborne
    145629, -- Death Knight: Anti-Magic Zone
    81256,  -- Death Knight: Dancing Rune Weapon
    55233,  -- Death Knight: Vampiric Blood

    188499, -- Demon Hunter: Blade Dance
    209426, -- Demon Hunter: Darkness

	132158, -- Duid: NS
	22842, -- Frenzied Regen
    102342, -- Druid: Ironbark
    22812,  -- Druid: Barkskin
    61336,  -- Druid: Survival Instincts
    117679, -- Druid: Incarnation: Tree of Life
    236696, -- Druid: Thorns
    305497, -- Druid: Thorns
	29166, -- Innervate
    53480,  -- Hunter: Roar of Sacrifice
	202748, -- Survival Tactics
	113862, -- Greater invis
    198111, -- Mage: Temporal Shield
    342246, -- Mage: Alter Time (Arcane)
    110909, -- Mage: Alter Time (Fire, Frost)
    125174, -- Monk: Touch of Karma
    209584, -- Zen Focus Tea
    120954, -- Monk: Fortifying Brew
    122783, -- Monk: Diffuse Magic
	122278, -- Dampen Harm
    228050, -- Paladin: Guardian of the Forgotten Queen
    86659,  -- Paladin: Guardian of Ancient Kings
    210256, -- Paladin: Blessing of Sanctuary
    6940,   -- Paladin: Blessing of Sacrifice
    184662, -- Paladin: Shield of Vengeance
    31850,  -- Paladin: Ardent Defender
    210294, -- Paladin: Divine Favor
    216331, -- Paladin: Avenging Crusader
    31842,  -- Paladin: Avenging Wrath (Holy)
    205191, -- Paladin: Eye for an Eye
    498,    -- Paladin: Divine Protection
	289655, -- Sanctified Ground
    47788,  -- Priest: Guardian Spirit
    33206,  -- Priest: Pain Suppression

    81782,  -- Priest: Power Word: Barrier
    15286,  -- Priest: Vampiric Embrace
    19236,  -- Priest: Desperate Prayer
    197862, -- Priest: Archangel
    47536,  -- Priest: Rapture
    271466, -- Priest: Luminous Barrier
    207736, -- Rogue: Shadowy Duel

    199754, -- Rogue: Riposte
	378081, -- Shaman: NS
    108271, -- Shaman: Astral Shift
    114052, -- Shaman: Ascendance (Restoration)
	108281, -- Ancestral Guidance
    104773, -- Warlock: Unending Resolve
    108416, -- Warlock: Dark Pact

    12975,  -- Warrior: Last Stand
    871,    -- Warrior: Shield Wall
    213871, -- Warrior: Bodyguard
	184364, -- Enraged Regeneration
    345231, -- Trinket: Gladiator's Emblem
    197690, -- Warrior: Defensive Stance
	370960, -- Evoker: Emerald Communion
	363916, -- Evoker: Obsidian Scales
	406789, -- Paradox 1
	406732, -- Paradox 2
    374348, -- Evoker: Renewing Blaze
    357170, -- Evoker: Time Dilation
	201633, -- Earthen Wall
	234084, -- Moon and Stars
	281195, -- Survival of the Fittest

    -- Miscellaneous
    199450, -- Ultimate Sacrifice
	172865, -- Stone Bulwark
    320224, -- Podtender
    327140, -- Forgeborne
    188501, -- Spectral Sight
    305395, -- Blessing of Freedom (Unbound Freedom)
    1044,   -- Blessing of Freedom
	54216,  -- Master's Call
    41425,  -- Hypothermia
    66,     -- Invisibility fade effect
    96243,  -- Invisibility invis effect?
    110960, -- Greater Invisibility
    198158, -- Mass Invisibility
    390612, -- Frost Bomb
    205021, -- Ray of Frost
	235450, -- Prismatic Barrier
	127797, -- Vortex
	342242, -- Time Warp
    
	-- Mobility
	384100, -- Berserker Shout
	48265, -- Death Advance
	1850, -- Dash
	106898, -- Stampeding Roar
	77761, -- Stampeding Roar
	2983, -- Sprint
	358267, -- Hover
	202163, -- Bounding Stride
	190784, -- Divine Steed
    393897, -- Tireless Pursuit
	319454, -- hotw
	109215, -- Posthaste
	446044, -- Relentless Pursuit
	202164, -- Heroic Leap speed buff
	
	
	-- Misc 2
	212431, -- Explosive Shot
	382440, -- Shifting Power
	394087, -- Mayhem
	431177, -- Frostfire Empowerement
	455679, -- Embral Lattice
	333889, -- Fel Dom
	383269, -- Abo Limb
	114108, -- Soul of the Forest
	20594, -- Stone Form
	393903, -- Ursine Vigor
	263165, -- void torrent
	199845, -- Psyfiend
	210824, -- Touch of the Magi
	319504, -- Shiv
	410598, -- Soul Rip
	329543, -- Divine Ascension
	236273, -- Duel	
	77606, -- Dark Sim
	12323, -- Piercing Howl
	274838, -- Feral Frenzy
	80240, -- Havoc
	25771, -- Forbearance
	391528, -- Convoke
	51690, -- Killing Spree
	200183, -- Apotheosis
	212552, -- Wraith Walk
	256948, -- Spatial Rift
	208963, -- Totem of Wrath
    322459, -- Thoughtstolen (Shaman)
    322464, -- Thoughtstolen (Mage)
    322442, -- Thoughtstolen (Druid)
    322462, -- Thoughtstolen (Priest - Holy)
    322457, -- Thoughtstolen (Paladin)
    322463, -- Thoughtstolen (Warlock)
    322461, -- Thoughtstolen (Priest - Discipline)
    322458, -- Thoughtstolen (Monk)
	394902, -- Thoughtstolen (Evoker)
    322460, -- Thoughtstolen (Priest - Shadow)
	389714, -- Displacement beacon
	394112, -- Escape from Reality
	345231, -- BM

    -- Druid Forms
    768,    -- Cat form
    783,    -- Travel form
    5487,   -- Bear form
	197625, -- Moonkin Form
})
