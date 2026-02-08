-- Auras we want tooltip info from to display as stacks
sArenaMixin.tooltipInfoAuras = {}

sArenaMixin.spellLockReducer = {
    [317920] = 0.7, -- Concentration Aura
    [234084] = 0.5, -- Moon and Stars
    [383020] = 0.5, -- Tranquil Air
}

sArenaMixin.auraList = {
    -- Spell ID = Priority
    -- Immunity
    [378441] = 9.1,      -- Time Stop
    [1221107] = 9.1,     -- Overpowered Prismatic Barrier Immunity (Mage)
    -- CCs
    [33786] = 9,         -- Cyclone (Disorient)
    [5211] = 9,          -- Mighty Bash (Stun)
    [108194] = 9,        -- Asphyxiate (Unholy) (Stun)
    [221562] = 9,        -- Asphyxiate (Blood) (Stun)
    [377048] = 9,        -- Absolute Zero (Frost) (Stun)
    [91797] = 9,         -- Monstrous Blow (Mutated Ghoul) (Stun)
    [287254] = 9,        -- Dead of Winter (Stun)
    [210141] = 9,        -- Zombie Explosion (Stun)
    [118905] = 9,        -- Static Charge (Stun)
    [1833] = 9,          -- Cheap Shot (Stun)
    [853] = 9,           -- Hammer of Justice (Stun)
    [179057] = 9,        -- Chaos Nova (Stun)
    [132169] = 9,        -- Storm Bolt (Stun)
    [408] = 9,           -- Kidney Shot (Stun)
    [163505] = 9,        -- Rake (Stun)
    [119381] = 9,        -- Leg Sweep (Stun)
    [89766] = 9,         -- Axe Toss (Stun)
    [30283] = 9,         -- Shadowfury (Stun)
    [24394] = 9,         -- Intimidation (Stun)
    [117526] = 9,        -- Binding Shot (Stun)
    [357021] = 9,        -- Consecutive Concussion (Stun)
    [211881] = 9,        -- Fel Eruption (Stun)
    [91800] = 9,         -- Gnaw (Stun)
    [205630] = 9,        -- Illidan's Grasp (Stun)
    [208618] = 9,        -- Illidan's Grasp (Stun)
    [203123] = 9,        -- Maim (Stun)
    [202244] = 9,        -- Overrun
    [200200] = 9,        -- Holy Word: Chastise, Censure Talent (Stun)
    [22703] = 9,         -- Infernal Awakening (Stun)
    [132168] = 9,        -- Shockwave (Stun)
    [20549] = 9,         -- War Stomp (Stun)
    [199085] = 9,        -- Warpath (Stun)
    [305485] = 9,        -- Lightning Lasso (Stun)
    [64044] = 9,         -- Psychic Horror (Stun)
    [255723] = 9,        -- Bull Rush (Stun)
    [202346] = 9,        -- Double Barrel (Stun)
    [213688] = 9,        -- Fel Cleave (Stun)
    [204399] = 9,        -- Earthfury (Stun)
    [118345] = 9,        -- Pulverize (Stun)
    [171017] = 9,        -- Meteor Strike (Infernal) (Stun)
    [171018] = 9,        -- Meteor Strike (Abyssal) (Stun)
    [46968] = 9,         -- Shockwave
    [287712] = 9,        -- Haymaker (Stun)
    [372245] = 9,        -- Terror of the Skies (stun)
    [389831] = 9,        -- Snowdrift (Stun)

    -- Disorients
    [5246] = 9,       -- Intimidating Shout (Disorient)
    [316593] = 9,     -- Intimidating Shout (Menace Main Target) (Disorient)
    [316595] = 9,     -- Intimidating Shout (Menace Other Targets) (Disorient)
    [8122] = 9,       -- Psychic Scream (Disorient)
    [2094] = 9,       -- Blind (Disorient)
    [605] = 9,        -- Mind Control (Disorient)
    [105421] = 9,     -- Blinding Light (Disorient)
    [207167] = 9,     -- Blinding Sleet (Disorient)
    [31661] = 9,      -- Dragon's Breath (Disorient)
    [207685] = 9,     -- Sigil of Misery (Disorient)
    [198909] = 9,     -- Song of Chi-ji (Disorient)
    [202274] = 9,     -- Incendiary Brew (Disorient)
    [130616] = 9,     -- Fear (Warlock Horrify talent)
    [118699] = 9,     -- Fear (Disorient)
    [1513] = 9,       -- Scare Beast (Disorient)
    [10326] = 9,      -- Turn Evil (Disorient)
    [6358] = 9,       -- Seduction (Disorient)
    [261589] = 9,     -- Seduction 2 (Disorient)
    [5484] = 9,       -- Howl (Disorient)
    [115268] = 9,     -- Mesmerize (Shivarra) (Disorient)
    [87204] = 9,      -- Sin and Punishment (Disorient)
    [2637] = 9,       -- Hibernate (Disorient)
    [226943] = 9,     -- Mind Bomb (Disorient)
    [236748] = 9,     -- Intimidating Roar (Disorient)
    [331866] = 9,     -- Agent of Chaos (Disorient)
    [324263] = 9,     -- Sulfuric Emission (Disorient)
    [360806] = 9,     -- Sleep Walk (Disorient)
    [358861] = 9,     -- Void Volley (Disorient)

    -- Incapacitates
    [51514] = 9,      -- Hex (Incapacitate)
    [211004] = 9,     -- Hex: Spider (Incapacitate)
    [210873] = 9,     -- Hex: Raptor (Incapacitate)
    [211015] = 9,     -- Hex: Cockroach (Incapacitate)
    [211010] = 9,     -- Hex: Snake (Incapacitate)
    [196942] = 9,     -- Hex: Voodoo Totem (Incapacitate)
    [277784] = 9,     -- Hex: Wicker Mongrel (Incapacitate)
    [277778] = 9,     -- Hex: Zandalari Tendonripper (Incapacitate)
    [269352] = 9,     -- Hex: Skeletal Hatchling (Incapacitate)
    [309328] = 9,     -- Hex: Living Honey (Incapacitate)
    [118] = 9,        -- Polymorph (Incapacitate)
    [61305] = 9,      -- Polymorph: Black Cat (Incapacitate)
    [28272] = 9,      -- Polymorph: Pig (Incapacitate)
    [61721] = 9,      -- Polymorph: Rabbit (Incapacitate)
    [61780] = 9,      -- Polymorph: Turkey (Incapacitate)
    [28271] = 9,      -- Polymorph: Turtle (Incapacitate)
    [161353] = 9,     -- Polymorph: Polar Bear Cub (Incapacitate)
    [126819] = 9,     -- Polymorph: Porcupine (Incapacitate)
    [161354] = 9,     -- Polymorph: Monkey (Incapacitate)
    [161355] = 9,     -- Polymorph: Penguin (Incapacitate)
    [161372] = 9,     -- Polymorph: Peacock (Incapacitate)
    [277792] = 9,     -- Polymorph: Bumblebee (Incapacitate)
    [277787] = 9,     -- Polymorph: Baby Direhorn (Incapacitate)
    [391622] = 9,     -- Polymorph: Duck (Incapacitate)
    [383121] = 9,     -- Mass Polymorph (Incapacitate)
    [3355] = 9,       -- Freezing Trap (Incapacitate)
    [203337] = 9,     -- Freezing Trap, Diamond Ice Honor Talent (Incapacitate)
    [115078] = 9,     -- Paralysis (Incapacitate)
    [213691] = 9,     -- Scatter Shot (Incapacitate)
    [6770] = 9,       -- Sap (Incapacitate)
    [20066] = 9,      -- Repentance (Incapacitate)
    [200196] = 9,     -- Holy Word: Chastise (Incapacitate)
    [221527] = 9,     -- Imprison, Detainment Honor Talent (Incapacitate)
    [217832] = 9,     -- Imprison (Incapacitate)
    [99] = 9,         -- Incapacitating Roar (Incapacitate)
    [82691] = 9,      -- Ring of Frost (Incapacitate)
    [1776] = 9,       -- Gouge (Incapacitate)
    [107079] = 9,     -- Quaking Palm (Incapacitate)
    [236025] = 9,     -- Enraged Maim (Incapacitate)
    [197214] = 9,     -- Sundering (Incapacitate)
    [9484] = 9,       -- Shackle Undead (Incapacitate)
    [710] = 9,        -- Banish (Incapacitate)
    [6789] = 9,       -- Mortal Coil (Incapacitate)

    -- Immunities
    [213610] = 8.1,     -- Priest: Holy Ward
    [377362] = 8.1,     -- Precog
    [456499] = 8,       -- Absolute Serenity
    [473909] = 8,       -- Ancient of Lore
    [354610] = 8,       -- Demon Hunter: Glimpse
    [642] = 8,          -- Divine Shield
    [186265] = 8,       -- Aspect of the Turtle
    [45438] = 8,        -- Ice Block
    [196555] = 8,       -- Demon Hunter: Netherwalk
    [47585] = 8,        -- Priest: Dispersion
    [1022] = 8,         -- Blessing of Protection
    [204018] = 8,       -- Blessing of Spellwarding
    [323524] = 8,       -- Ultimate Form
    [216113] = 8,       -- Way of the Crane
    [31224] = 8,        -- Cloak of Shadows
    [8178] = 8,         -- Grounding Totem Effect
    [199448] = 8,       -- Blessing of Sacrifice
    [236321] = 8,       -- War Banner
    [215769] = 8,       -- Spirit of Redemption
    [227847] = 8,       -- Warrior: Bladestorm (Arms)
    [446035] = 8,       -- Warrior: Bladestorm (Fury?)
    [118038] = 8,       -- Warrior: Die by the Sword
    [357210] = 8,       -- Deep Breath
    [359816] = 8,       -- Dream Flight
    [408557] = 8,       -- Phase Shift
    [408558] = 8,       -- Phase Shift
    [362486] = 8,       -- Keeper of the Grove
    [116849] = 8,       -- Monk: Life Cocoon
    [212800] = 8,       -- Demon Hunter: Blur
    [147833] = 8,       -- Friendly Intervene
    [48792] = 8,        -- Death Knight: Icebound Fortitude
    [409293] = 8,       -- Burrow

    -- Lesser Immunity Buffs
    [5277] = 7,       -- Rogue: Evasion
    [23920] = 7,      -- Spell Reflection
    [212295] = 7,     -- Warlock: Nether Ward
    [48707] = 7,      -- Death Knight: Anti-Magic Shell
    [410358] = 7,     -- Death Knight: Anti-Magic Shell
    [5384] = 7,       -- Hunter: Feign Death
    [353319] = 7,     -- Monk: Peaceweaver
    [378464] = 7,     -- Evoker: Nullifying Shroud
    [31821] = 7,      -- Aura Mastery
    [206803] = 7,     -- Rain from Above
    [131558] = 7,     -- Shaman: Spiritwalker's Aegis

    -- Interrupts
    [1766] = 6,       -- Kick (Rogue)
    [2139] = 6,       -- Counterspell (Mage)
    [6552] = 6,       -- Pummel (Warrior)
    [19647] = 6,      -- Spell Lock (Warlock)
    [47528] = 6,      -- Mind Freeze (Death Knight)
    [57994] = 6,      -- Wind Shear (Shaman)
    [91802] = 6,      -- Shambling Rush (Death Knight)
    -- [96231] = 6, -- Rebuke (Paladin)
    [106839] = 6,     -- Skull Bash (Feral)
    [115781] = 6,     -- Optical Blast (Warlock)
    [116705] = 6,     -- Spear Hand Strike (Monk)
    [132409] = 6,     -- Spell Lock (Warlock)
    [147362] = 6,     -- Countershot (Hunter)
    [171138] = 6,     -- Shadow Lock (Warlock)
    [183752] = 6,     -- Consume Magic (Demon Hunter)
    [187707] = 6,     -- Muzzle (Hunter)
    [212619] = 6,     -- Call Felhunter (Warlock)
    [231665] = 6,     -- Avengers Shield (Paladin)
    [351338] = 6,     -- Quell (Evoker)
    [97547] = 6,      -- Solar Beam

    -- Silences
    [202933] = 6,      -- Spider Sting
    [356727] = 6,      -- Spider Venom
    [1330] = 6,        -- Garrote
    [15487] = 6,       -- Silence
    [199683] = 6,      -- Last Word
    [47476] = 6,       -- Strangulate
    [31935] = 6,       -- Avenger's Shield
    [204490] = 6,      -- Sigil of Silence
    [217824] = 6,      -- Shield of Virtue
    [43523] = 6,       -- Unstable Affliction Silence 1
    [196364] = 6,      -- Unstable Affliction Silence 2
    [317589] = 6,      -- Tormenting Backlash
    [410065] = 6,      -- Reactive Resin
    [375901] = 6,      -- Mindgames
    [81261] = 5.5,     -- Solar Beam

    -- Disarms
    [410126] = 5,     -- Searing Glare
    [410201] = 5,     -- Searing Glare
    [236077] = 5,     -- Disarm
    [236236] = 5,     -- Disarm (Protection)
    [209749] = 5,     -- Faerie Swarm (Disarm)
    [233759] = 5,     -- Grapple Weapon
    [207777] = 5,     -- Dismantle

    -- Smoke
    [212182] = 4.9,     -- Smoke Bomb
    [212183] = 4.9,     -- Smoke Bomb

    -- Offensive Debuffs
    [383005] = 4.5,     -- Chrono Loop
    [372048] = 4.5,     -- Opressing Roar
    [356723] = 4.5,     -- Scorpid Venom


    -- Roots
    [376080] = 4,     -- Spear
    [105771] = 4,     -- Charge
    [356356] = 4,     -- Warbringer
    [324382] = 4,     -- Clash
    [114404] = 4,     -- Void Tendril's
    [356738] = 4,     -- Earth Unleashed
    [288515] = 4,     -- Surge of Power
    [339] = 4,        -- Entangling Roots
    [170855] = 4,     -- Entangling Roots (Nature's Grasp)
    [201589] = 4,     -- Entangling Roots (Tree of Life)
    [235963] = 4,     -- Entangling Roots (Feral honor talent)
    [122] = 4,        -- Frost Nova
    [386770] = 4,     -- Freezing Cold
    [102359] = 4,     -- Mass Entanglement
    [64695] = 4,      -- Earthgrab
    [200108] = 4,     -- Ranger's Net
    [212638] = 4,     -- Tracker's Net
    [162480] = 4,     -- Steel Trap
    [204085] = 4,     -- Deathchill
    [233395] = 4,     -- Frozen Center
    [233582] = 4,     -- Entrenched in Flame
    [201158] = 4,     -- Super Sticky Tar
    [33395] = 4,      -- Freeze
    [228600] = 4,     -- Glacial Spike
    [116706] = 4,     -- Disable
    [45334] = 4,      -- Immobilized
    [53148] = 4,      -- Charge (Hunter Pet)
    [190927] = 4,     -- Harpoon
    [136634] = 4,     -- Narrow Escape (unused?)
    [157997] = 4,     -- Ice Nova
    [378760] = 4,     -- Frostbite
    [241887] = 4,     -- Landslide
    [355689] = 4,     -- Landslide
    [393456] = 4,     -- Entrapment
    [285515] = 4,     -- Surge of Power

    -- Refreshments
    [167152] = 3.5,     -- Mage Food
    [274914] = 3.5,     -- Rockskip Mineral Water
    [396920] = 3.5,     -- Delicious Dragon Spittle
    [369162] = 3.5,     -- drink
    [452382] = 3.5,     -- drink
    [461063] = 3.5,     -- quiet contemplation (earthen dwarf racial)


    -- Offensive Buffs
    [51271] = 3,        -- Death Knight: Pillar of Frost
    -- [47568] = 3, -- Death Knight: Empower Rune Weapon
    [207289] = 3,       -- Death Knight: Unholy Assault
    [162264] = 3,       -- Demon Hunter: Metamorphosis
    [194223] = 3,       -- Druid: Celestial Alignment
    [383410] = 3,       -- Druid: Celestial Alignment (Orbital Strike)
    [102560] = 3,       -- Druid: Incarnation: Chosen of Elune
    [390414] = 3,       -- Druid: Incarnation: Chosen of Elune (Orbital Strike)
    [5217] = 3,         -- Tiger's Fury
    [102543] = 3,       -- Druid: Incarnation: King of the Jungle
    [19574] = 3,        -- Hunter: Bestial Wrath
    [266779] = 3,       -- Hunter: Coordinated Assault
    [288613] = 3,       -- Hunter: Trueshot
    -- [260402] = 3, -- Hunter: Double Tap
    [365362] = 3,       -- Mage: Arcane Surge
    [190319] = 3,       -- Mage: Combustion
    [205025] = 3,       -- Mage: Presence of Mind
    [324220] = 3,       -- Mage: Deathborne
    [198144] = 3,       -- Mage: Ice Form
    [12472] = 3,        -- Mage: Icy Veins
    [80353] = 3,        -- Mage: Time Warp
    [152173] = 3,       -- Monk: Serenity
    [137639] = 3,       -- Monk: Storm, Earth, and Fire
    [31884] = 3,        -- Paladin: Avenging Wrath (Retribution)
    [152262] = 3,       -- Paladin: Seraphim
    [231895] = 3,       -- Paladin: Crusade
    [185313] = 3,       -- Rogue: Shadow Dance
    [185422] = 3,       -- Rogue: Shadow Dance
    [457333] = 3,       -- Death's Arrival
    [197871] = 3,       -- Priest: Dark Archangel
    [194249] = 3,       -- Priest: Voidform
    [384631] = 3,       -- Rogue: Flagellation
    [13750] = 3,        -- Rogue: Adrenaline Rush
    [121471] = 3,       -- Rogue: Shadow Blades
    [114050] = 3,       -- Shaman: Ascendance (Elemental)
    [114051] = 3,       -- Shaman: Ascendance (Enhancement)
    [2825] = 3,         -- Shaman: Bloodlust
    [204361] = 3,       -- Shaman: Bloodlust (Honor Talent)
    [32182] = 3,        -- Shaman: Heroism
    [204362] = 3,       -- Shaman: Heroism (Honor Talent)
    [191634] = 3,       -- Shaman: Stormkeeper
    [204366] = 3,       -- Shaman: Thundercharge
    [113858] = 3,       -- Warlock: Dark Soul: Instability
    [113860] = 3,       -- Warlock: Dark Soul: Misery
    [399680] = 3,       -- Soul Swap
    [442726] = 2.4,     -- Malevolence (Not more important than defensives)
    [328774] = 3,       -- Amp Curse
    [107574] = 3,       -- Warrior: Avatar
    -- [260708] = 3, -- Warrior: Sweeping Strikes
    [262228] = 3,       -- Warrior: Deadly Calm
    [1719] = 3,         -- Warrior: Recklessness
    [375087] = 3,       -- Evoker: Dragonrage
    [370553] = 3,       -- Evoker: Tip the Scales
    [10060] = 3,        -- Priest: Power Infusion
    [360952] = 3,       -- Hunter: Coordinated Assault

    -- Defensive Buffs
    [199450] = 2.6,      -- Ultimate Sacrifice
    [232707] = 2.5,      -- Priest: Ray of Hope
    [232708] = 2.5,      -- Ray of Hope
    [49039] = 2.5,       -- Death Knight: Lichborne
    [145629] = 2.5,      -- Death Knight: Anti-Magic Zone
    [81256] = 2.5,       -- Death Knight: Dancing Rune Weapon
    [55233] = 2.5,       -- Death Knight: Vampiric Blood

    [188499] = 2.5,      -- Demon Hunter: Blade Dance
    [209426] = 2.5,      -- Demon Hunter: Darkness

    [132158] = 2.5,      -- Druid: NS
    [22842] = 2.5,       -- Frenzied Regen
    [102342] = 2.5,      -- Druid: Ironbark
    [22812] = 2.5,       -- Druid: Barkskin
    [61336] = 2.5,       -- Druid: Survival Instincts
    [117679] = 2.5,      -- Druid: Incarnation: Tree of Life
    [236696] = 2.5,      -- Druid: Thorns
    [305497] = 2.5,      -- Druid: Thorns
    [29166] = 2.5,       -- Innervate

    [53480] = 2.5,       -- Hunter: Roar of Sacrifice
    [202748] = 2.5,      -- Survival Tactics

    [113862] = 2.5,      -- Greater Invisibility
    [198111] = 2.5,      -- Mage: Temporal Shield
    [342246] = 2.5,      -- Mage: Alter Time (Arcane)
    [110909] = 2.5,      -- Mage: Alter Time (Fire, Frost)
    [1221106] = 2.4,     -- Mage: Overpowered Prismatic Barrier (Use Blink to activate full dmg immunity)

    [125174] = 2.5,      -- Monk: Touch of Karma
    [209584] = 2.5,      -- Zen Focus Tea
    [120954] = 2.5,      -- Monk: Fortifying Brew
    [122783] = 2.5,      -- Monk: Diffuse Magic
    [122278] = 2.5,      -- Dampen Harm

    [228050] = 2.5,      -- Paladin: Guardian of the Forgotten Queen
    [86659] = 2.5,       -- Paladin: Guardian of Ancient Kings
    [210256] = 2.5,      -- Paladin: Blessing of Sanctuary
    [6940] = 2.5,        -- Paladin: Blessing of Sacrifice
    [184662] = 2.5,      -- Paladin: Shield of Vengeance
    [31850] = 2.5,       -- Paladin: Ardent Defender
    [210294] = 2.5,      -- Paladin: Divine Favor
    [216331] = 2.5,      -- Paladin: Avenging Crusader
    [31842] = 2.5,       -- Paladin: Avenging Wrath (Holy)
    [205191] = 2.5,      -- Paladin: Eye for an Eye
    [498] = 2.5,         -- Paladin: Divine Protection
    [289655] = 2.5,      -- Sanctified Ground

    [47788] = 2.5,       -- Priest: Guardian Spirit
    [33206] = 2.5,       -- Priest: Pain Suppression
    [81782] = 2.5,       -- Priest: Power Word: Barrier
    [15286] = 2.5,       -- Priest: Vampiric Embrace
    [19236] = 2.5,       -- Priest: Desperate Prayer
    [197862] = 2.5,      -- Priest: Archangel
    [47536] = 2.5,       -- Priest: Rapture
    [271466] = 2.5,      -- Priest: Luminous Barrier

    [207736] = 2.5,      -- Rogue: Shadowy Duel
    [199754] = 2.5,      -- Rogue: Riposte

    [378081] = 2.5,      -- Shaman: NS
    [108271] = 2.5,      -- Shaman: Astral Shift
    [114052] = 2.5,      -- Shaman: Ascendance (Restoration)
    [108281] = 2.5,      -- Ancestral Guidance

    [104773] = 2.5,      -- Warlock: Unending Resolve
    [108416] = 2.5,      -- Warlock: Dark Pact

    [12975] = 2.5,       -- Warrior: Last Stand
    [871] = 2.5,         -- Warrior: Shield Wall
    [213871] = 2.5,      -- Warrior: Bodyguard
    [184364] = 2.5,      -- Enraged Regeneration
    [345231] = 2.5,      -- Trinket: Gladiator's Emblem
    [197690] = 2.5,      -- Warrior: Defensive Stance

    [370960] = 2.5,      -- Evoker: Emerald Communion
    [363916] = 2.5,      -- Evoker: Obsidian Scales
    [406789] = 2.5,      -- Paradox 1
    [406732] = 2.5,      -- Paradox 2
    [374348] = 2.5,      -- Evoker: Renewing Blaze
    [357170] = 2.5,      -- Evoker: Time Dilation

    [201633] = 2.5,      -- Earthen Wall
    [234084] = 2.5,      -- Moon and Stars
    [281195] = 2.5,      -- Survival of the Fittest

    -- Miscellaneous
    [172865] = 2.4,     -- Stone Bulwark
    [320224] = 2.4,     -- Podtender
    [327140] = 2.4,     -- Forgeborne
    [188501] = 2.4,     -- Spectral Sight
    [305395] = 2.4,     -- Blessing of Freedom (Unbound Freedom)
    [1044] = 2.4,       -- Blessing of Freedom
    [54216] = 2.4,      -- Master's Call
    [41425] = 2.4,      -- Hypothermia
    [66] = 2.4,         -- Invisibility fade effect
    [96243] = 2.4,      -- Invisibility invis effect?
    [110960] = 2.4,     -- Greater Invisibility
    [198158] = 2.4,     -- Mass Invisibility
    [390612] = 2.4,     -- Frost Bomb
    [205021] = 2.4,     -- Ray of Frost
    [235450] = 2.4,     -- Prismatic Barrier
    [127797] = 2.4,     -- Vortex
    [342242] = 2.4,     -- Time Warp

    -- Mobility
    [384100] = 2.3,     -- Berserker Shout
    [48265] = 2.3,      -- Death Advance
    [1850] = 2.3,       -- Dash
    [106898] = 2.3,     -- Stampeding Roar
    [77761] = 2.3,      -- Stampeding Roar
    [2983] = 2.3,       -- Sprint
    [358267] = 2.3,     -- Hover
    [202163] = 2.3,     -- Bounding Stride
    [190784] = 2.3,     -- Divine Steed
    [393897] = 2.3,     -- Tireless Pursuit
    [319454] = 2.3,     -- Heart of the Wild (hotw)
    [109215] = 2.3,     -- Posthaste
    [446044] = 2.3,     -- Relentless Pursuit
    [202164] = 2.3,     -- Heroic Leap speed buff

    -- Misc 2
    [212431] = 2,     -- Explosive Shot
    [382440] = 2,     -- Shifting Power
    [394087] = 2,     -- Mayhem
    [431177] = 2,     -- Frostfire Empowerement
    [455679] = 2,     -- Embral Lattice
    [333889] = 2,     -- Fel Dom
    [383269] = 2,     -- Abo Limb
    [114108] = 2,     -- Soul of the Forest
    [20594] = 2,      -- Stone Form
    [393903] = 2,     -- Ursine Vigor
    [263165] = 2,     -- Void Torrent
    [199845] = 2,     -- Psyfiend
    [210824] = 2,     -- Touch of the Magi
    [319504] = 2,     -- Shiv
    [410598] = 2,     -- Soul Rip
    [329543] = 2,     -- Divine Ascension
    [236273] = 2,     -- Duel
    [77606] = 2,      -- Dark Sim
    [12323] = 2,      -- Piercing Howl
    [274838] = 2,     -- Feral Frenzy
    [80240] = 2,      -- Havoc
    [25771] = 2,      -- Forbearance
    [391528] = 2,     -- Convoke
    [51690] = 2,      -- Killing Spree
    [200183] = 2,     -- Apotheosis
    [212552] = 2,     -- Wraith Walk
    [256948] = 2,     -- Spatial Rift
    [208963] = 2,     -- Totem of Wrath

    -- Thoughtstolen Variants
    [322459] = 2,     -- Thoughtstolen (Shaman)
    [322464] = 2,     -- Thoughtstolen (Mage)
    [322442] = 2,     -- Thoughtstolen (Druid)
    [322462] = 2,     -- Thoughtstolen (Priest - Holy)
    [322457] = 2,     -- Thoughtstolen (Paladin)
    [322463] = 2,     -- Thoughtstolen (Warlock)
    [322461] = 2,     -- Thoughtstolen (Priest - Discipline)
    [322458] = 2,     -- Thoughtstolen (Monk)
    [394902] = 2,     -- Thoughtstolen (Evoker)
    [322460] = 2,     -- Thoughtstolen (Priest - Shadow)

    [389714] = 2,     -- Displacement Beacon
    [394112] = 2,     -- Escape from Reality

    -- Druid Forms
    [768] = 1,        -- Cat form
    [783] = 1,        -- Travel form
    [5487] = 1,       -- Bear form
    [197625] = 1,     -- Moonkin Form
}
