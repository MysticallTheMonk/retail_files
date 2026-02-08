local _, addon = ...;

-- https://github.com/wardz/DRList-1.0/blob/master/DRList-1.0/Spells.lua
if addon.PROJECT_MAINLINE then
    addon.DRList = {
        -- *** Disorient Effects ***
        [207167]  = "disorient", -- Blinding Sleet
        [207685]  = "disorient", -- Sigil of Misery
        [33786]   = "disorient", -- Cyclone
        [360806]  = "disorient", -- Sleep Walk
        [1513]    = "disorient", -- Scare Beast
        [31661]   = "disorient", -- Dragon's Breath
        [353084]  = "disorient", -- Ring of Fire
        [198909]  = "disorient", -- Song of Chi-ji
        [202274]  = "disorient", -- Hot Trub
        [105421]  = "disorient", -- Blinding Light
        [10326]   = "disorient", -- Turn Evil
        [205364]  = "disorient", -- Dominate Mind
        [605]     = "disorient", -- Mind Control
        [8122]    = "disorient", -- Psychic Scream
        [2094]    = "disorient", -- Blind
        [118699]  = "disorient", -- Fear
        [130616]  = "disorient", -- Fear (Horrify)
        [5484]    = "disorient", -- Howl of Terror
        [261589]  = "disorient", -- Seduction (Grimoire of Sacrifice)
        [6358]    = "disorient", -- Seduction (Succubus)
        [5246]    = "disorient", -- Intimidating Shout
        [316593]  = "disorient", -- Intimidating Shout (Menace Main Target)
        [316595]  = "disorient", -- Intimidating Shout (Menace Other Targets)
        [331866]  = "disorient", -- Agent of Chaos (Venthyr Covenant)
        [324263]  = "disorient", -- Sulfuric Emission (Soulbind Ability)

        -- *** Incapacitate Effects ***
        [217832]  = "incapacitate", -- Imprison
        [221527]  = "incapacitate", -- Imprison (Honor talent)
        [2637]    = "incapacitate", -- Hibernate
        [99]      = "incapacitate", -- Incapacitating Roar
        [378441]  = "incapacitate", -- Time Stop
        [3355]    = "incapacitate", -- Freezing Trap
        [203337]  = "incapacitate", -- Freezing Trap (Honor talent)
        [213691]  = "incapacitate", -- Scatter Shot
        [383121]  = "incapacitate", -- Mass Polymorph
        [118]     = "incapacitate", -- Polymorph
        [28271]   = "incapacitate", -- Polymorph (Turtle)
        [28272]   = "incapacitate", -- Polymorph (Pig)
        [61025]   = "incapacitate", -- Polymorph (Snake)
        [61305]   = "incapacitate", -- Polymorph (Black Cat)
        [61780]   = "incapacitate", -- Polymorph (Turkey)
        [61721]   = "incapacitate", -- Polymorph (Rabbit)
        [126819]  = "incapacitate", -- Polymorph (Porcupine)
        [161353]  = "incapacitate", -- Polymorph (Polar Bear Cub)
        [161354]  = "incapacitate", -- Polymorph (Monkey)
        [161355]  = "incapacitate", -- Polymorph (Penguin)
        [161372]  = "incapacitate", -- Polymorph (Peacock)
        [277787]  = "incapacitate", -- Polymorph (Baby Direhorn)
        [277792]  = "incapacitate", -- Polymorph (Bumblebee)
        [321395]  = "incapacitate", -- Polymorph (Mawrat)
        [391622]  = "incapacitate", -- Polymorph (Duck)
        [460396]  = "incapacitate", -- Polymorph (Mosswool)
        [461489]  = "incapacitate", -- Polymorph (Mosswool) 2
        [82691]   = "incapacitate", -- Ring of Frost
        [115078]  = "incapacitate", -- Paralysis
        [357768]  = "incapacitate", -- Paralysis 2 (Perpetual Paralysis?)
        [20066]   = "incapacitate", -- Repentance
        [9484]    = "incapacitate", -- Shackle Undead
        [200196]  = "incapacitate", -- Holy Word: Chastise
        [1776]    = "incapacitate", -- Gouge
        [6770]    = "incapacitate", -- Sap
        [51514]   = "incapacitate", -- Hex
        [196942]  = "incapacitate", -- Hex (Voodoo Totem)
        [210873]  = "incapacitate", -- Hex (Raptor)
        [211004]  = "incapacitate", -- Hex (Spider)
        [211010]  = "incapacitate", -- Hex (Snake)
        [211015]  = "incapacitate", -- Hex (Cockroach)
        [269352]  = "incapacitate", -- Hex (Skeletal Hatchling)
        [309328]  = "incapacitate", -- Hex (Living Honey)
        [277778]  = "incapacitate", -- Hex (Zandalari Tendonripper)
        [277784]  = "incapacitate", -- Hex (Wicker Mongrel)
        [197214]  = "incapacitate", -- Sundering
        [710]     = "incapacitate", -- Banish
        [6789]    = "incapacitate", -- Mortal Coil
        [107079]  = "incapacitate", -- Quaking Palm (Racial, Pandaren)

        -- *** Controlled Stun Effects ***
        [210141]  = "stun", -- Zombie Explosion
        [377048]  = "stun", -- Absolute Zero (Breath of Sindragosa)
        [108194]  = "stun", -- Asphyxiate (Unholy)
        [221562]  = "stun", -- Asphyxiate (Blood)
        [91800]   = "stun", -- Gnaw (Ghoul)
        [91797]   = "stun", -- Monstrous Blow (Mutated Ghoul)
        [287254]  = "stun", -- Dead of Winter
        [179057]  = "stun", -- Chaos Nova
        [205630]  = "stun", -- Illidan's Grasp (Primary effect)
        [208618]  = "stun", -- Illidan's Grasp (Secondary effect)
        [211881]  = "stun", -- Fel Eruption
        [200166]  = "stun", -- Metamorphosis (PvE stun effect)
        [203123]  = "stun", -- Maim
        [163505]  = "stun", -- Rake (Prowl)
        [5211]    = "stun", -- Mighty Bash
        [202244]  = "stun", -- Overrun
        [325321]  = "stun", -- Wild Hunt's Charge
        [372245]  = "stun", -- Terror of the Skies
        [408544]  = "stun", -- Seismic Slam
        [117526]  = "stun", -- Binding Shot
        [357021]  = "stun", -- Consecutive Concussion
        [24394]   = "stun", -- Intimidation
        [389831]  = "stun", -- Snowdrift
        [119381]  = "stun", -- Leg Sweep
        [458605]  = "stun", -- Leg Sweep 2
        [202346]  = "stun", -- Double Barrel
        [853]     = "stun", -- Hammer of Justice
        [255941]  = "stun", -- Wake of Ashes
        [64044]   = "stun", -- Psychic Horror
        [200200]  = "stun", -- Holy Word: Chastise Censure
        [1833]    = "stun", -- Cheap Shot
        [408]     = "stun", -- Kidney Shot
        [118905]  = "stun", -- Static Charge (Capacitor Totem)
        [118345]  = "stun", -- Pulverize (Primal Earth Elemental)
        [305485]  = "stun", -- Lightning Lasso
        [89766]   = "stun", -- Axe Toss
        [171017]  = "stun", -- Meteor Strike (Infernal)
        [171018]  = "stun", -- Meteor Strike (Abyssal)
        [30283]   = "stun", -- Shadowfury
        [385954]  = "stun", -- Shield Charge
        [46968]   = "stun", -- Shockwave
        [132168]  = "stun", -- Shockwave (Protection)
        [145047]  = "stun", -- Shockwave (Proving Grounds PvE)
        [132169]  = "stun", -- Storm Bolt
        [199085]  = "stun", -- Warpath
        [20549]   = "stun", -- War Stomp (Racial, Tauren)
        [255723]  = "stun", -- Bull Rush (Racial, Highmountain Tauren)
        [287712]  = { "stun", "knockback" }, -- Haymaker (Racial, Kul Tiran)
        [332423]  = "stun", -- Sparkling Driftglobe Core (Kyrian Covenant)

        -- *** Controlled Root Effects ***
        -- Note: roots with duration <= 2s has no DR and are commented out
        [204085]  = "root", -- Deathchill (Chains of Ice)
        [233395]  = "root", -- Deathchill (Remorseless Winter)
        [454787]  = "root", -- Ice Prison
        [339]     = "root", -- Entangling Roots
        [235963]  = "root", -- Entangling Roots (Earthen Grasp)
        [170855]  = "root", -- Entangling Roots (Nature's Grasp)
        --[16979]   = "root", -- Wild Charge (has no DR)
        [102359]  = "root", -- Mass Entanglement
        [355689]  = "root", -- Landslide
        [393456]  = "root", -- Entrapment (Tar Trap)
        [162480]  = "root", -- Steel Trap
--      [190927]  = "root", -- Harpoon (has no DR)
        [212638]  = "root", -- Tracker's Net
        [201158]  = "root", -- Super Sticky Tar
        [122]     = "root", -- Frost Nova
        [33395]   = "root", -- Freeze
        [386770]  = "root", -- Freezing Cold
        [378760]  = "root", -- Frostbite
        --[199786]  = "root", -- Glacial Spike (has no DR)
        [114404]  = "root", -- Void Tendril's Grasp
        [342375]  = "root", -- Tormenting Backlash (Torghast PvE)
        [116706]  = "root", -- Disable
        [324382]  = "root", -- Clash
        [64695]   = "root", -- Earthgrab (Totem effect)
        --[356738]  = "root", -- Earth Unleashed
        [285515]  = "root", -- Surge of Power
        [199042]  = "root", -- Thunderstruck (Protection PvP Talent)
        --[356356]  = "root", -- Warbringer
        [39965]   = "root", -- Frost Grenade (Item)
        [75148]   = "root", -- Embersilk Net (Item)
        [55536]   = "root", -- Frostweave Net (Item)
        [268966]  = "root", -- Hooked Deep Sea Net (Item)

        -- *** Silence Effects ***
        [47476]   = "silence", -- Strangulate
        [374776]  = "silence", -- Tightening Grasp
        [204490]  = "silence", -- Sigil of Silence
--      [78675]   = "silence", -- Solar Beam (has no DR)
        [410065]  = "silence", -- Reactive Resin
        [202933]  = "silence", -- Spider Sting
        [356727]  = "silence", -- Spider Venom
        [354831]  = "silence", -- Wailing Arrow 1
        [355596]  = "silence", -- Wailing Arrow 2
        [217824]  = "silence", -- Shield of Virtue
        [15487]   = "silence", -- Silence
        [1330]    = "silence", -- Garrote
        [196364]  = "silence", -- Unstable Affliction Silence Effect

        -- *** Disarm Weapon Effects ***
        [209749]  = "disarm", -- Faerie Swarm (Balance Honor Talent)
        [407032]  = "disarm", -- Sticky Tar Bomb 1
        [407031]  = "disarm", -- Sticky Tar Bomb 2
        [207777]  = "disarm", -- Dismantle
        [233759]  = "disarm", -- Grapple Weapon
        [236077]  = "disarm", -- Disarm

        -- *** Force Taunt Effects ***
        [56222]   = "taunt", -- Dark Command
        [51399]   = "taunt", -- Death Grip (Taunt Effect)
        [185245]  = "taunt", -- Torment
        [6795]    = "taunt", -- Growl (Druid)
        [2649]    = "taunt", -- Growl (Hunter Pet)
        [20736]   = "taunt", -- Distracting Shot
        [116189]  = "taunt", -- Provoke
        [118635]  = "taunt", -- Provoke (Black Ox Statue)
        [196727]  = "taunt", -- Provoke (Niuzao)
        [204079]  = "taunt", -- Final Stand
        [62124]   = "taunt", -- Hand of Reckoning
        [17735]   = "taunt", -- Suffering (Voidwalker)
        [1161]    = "taunt", -- Challenging Shout
        [355]     = "taunt", -- Taunt

        -- *** Controlled Knockback Effects ***
        -- Note: not every knockback has an aura.
        [108199]  = "knockback", -- Gorefiend's Grasp
        [202249]  = "knockback", -- Overrun
        [61391]   = "knockback", -- Typhoon
        [102793]  = "knockback", -- Ursol's Vortex
        [431620]  = "knockback", -- Upheaval
        [186387]  = "knockback", -- Bursting Shot
        [236776]  = "knockback", -- Hi-Explosive Trap
        [236777]  = "knockback", -- Hi-Explosive Trap 2
        [462031]  = "knockback", -- Implosive Trap
        [157981]  = "knockback", -- Blast Wave
        [51490]   = "knockback", -- Thunderstorm
        [368970]  = "knockback", -- Tail Swipe (Racial, Dracthyr)
        [357214]  = "knockback", -- Wing Buffet (Racial, Dracthyr)
    };
else
    addon.DRList = {
        -- *** Incapacitate Effects ***
        [2637]   = "incapacitate", -- Hibernate
        [3355]   = "incapacitate", -- Freezing Trap Effect
        [19386]  = "incapacitate", -- Wyvern Sting
        [118]    = "incapacitate", -- Polymorph
        [28271]  = "incapacitate", -- Polymorph: Turtle
        [28272]  = "incapacitate", -- Polymorph: Pig
        [61025]  = "incapacitate", -- Polymorph: Serpent
        [61721]  = "incapacitate", -- Polymorph: Rabbit
        [61780]  = "incapacitate", -- Polymorph: Turkey
        [61305]  = "incapacitate", -- Polymorph: Black Cat
        [82691]  = "incapacitate", -- Ring of Frost
        [115078] = "incapacitate", -- Paralysis
        [20066]  = "incapacitate", -- Repentance
        [9484]   = "incapacitate", -- Shackle Undead
        [1776]   = "incapacitate", -- Gouge
        [6770]   = "incapacitate", -- Sap
        [76780]  = "incapacitate", -- Bind Elemental
        [51514]  = "incapacitate", -- Hex
        [710]    = "incapacitate", -- Banish
        [107079] = "incapacitate", -- Quaking Palm (Racial)

        -- *** Disorient Effects ***
        [99]     = "disorient", -- Disorienting Roar
        [19503]  = "disorient", -- Scatter Shot
        [31661]  = "disorient", -- Dragon's Breath
        [123393] = "disorient", -- Glyph of Breath of Fire
        [105421] = "disorient", -- Blinding Light
        [88625]  = "disorient", -- Holy Word: Chastise

        -- *** Controlled Stun Effects ***
        [108194] = "stun", -- Asphyxiate
        [91800]  = "stun", -- Gnaw (Ghoul)
        [91797]  = "stun", -- Monstrous Blow (Dark Transformation Ghoul)
        [115001] = "stun", -- Remorseless Winter
        [102795] = "stun", -- Bear Hug
        [5211]   = "stun", -- Mighty Bash
        [9005]   = "stun", -- Pounce
        [22570]  = "stun", -- Maim
        [113801] = "stun", -- Bash (Treants)
        [117526] = "stun", -- Binding Shot
        [24394]  = "stun", -- Intimidation
        [126246] = "stun", -- Lullaby (Crane pet) -- TODO: verify category
        [126423] = "stun", -- Petrifying Gaze (Basilisk pet) -- TODO: verify category
        [126355] = "stun", -- Quill (Porcupine pet) -- TODO: verify category
        [90337]  = "stun", -- Bad Manner (Monkey)
        [56626]  = "stun", -- Sting (Wasp)
        [50519]  = "stun", -- Sonic Blast
        [118271] = "stun", -- Combustion
        [44572]  = "stun", -- Deep Freeze
        [119392] = "stun", -- Charging Ox Wave
        [122242] = "stun", -- Clash
        [120086] = "stun", -- Fists of Fury
        [119381] = "stun", -- Leg Sweep
        [115752] = "stun", -- Blinding Light (Glyphed)
        [853]    = "stun", -- Hammer of Justice
        [110698] = "stun", -- Hammer of Justice (Symbiosis)
        [119072] = "stun", -- Holy Wrath
        [105593] = "stun", -- Fist of Justice
        [408]    = "stun", -- Kidney Shot
        [1833]   = "stun", -- Cheap Shot
        [118345] = "stun", -- Pulverize (Primal Earth Elemental)
        [118905] = "stun", -- Static Charge (Capacitor Totem)
        [89766]  = "stun", -- Axe Toss (Felguard)
        [22703]  = "stun", -- Inferno Effect
        [30283]  = "stun", -- Shadowfury
        [132168] = "stun", -- Shockwave
        [107570] = "stun", -- Storm Bolt
        [132169] = "stun", -- Storm Bolt 2
        [20549]  = "stun", -- War Stomp (Racial)

        -- *** Non-controlled Stun Effects ***
        [113953] = "random_stun", -- Paralysis
        [118895] = "random_stun", -- Dragon Roar
        [77505]  = "random_stun", -- Earthquake
        [100]    = "random_stun", -- Charge
        [118000] = "random_stun", -- Dragon Roar

        -- *** Fear Effects ***
        [113004] = "fear", -- Intimidating Roar (Symbiosis)
        [113056] = "fear", -- Intimidating Roar (Symbiosis 2)
        [1513]   = "fear", -- Scare Beast
        [10326]  = "fear", -- Turn Evil
        [145067] = "fear", -- Turn Evil (Evil is a Point of View)
        [8122]   = "fear", -- Psychic Scream
        [113792] = "fear", -- Psychic Terror (Psyfiend)
        [2094]   = "fear", -- Blind
        [5782]   = "fear", -- Fear
        [118699] = "fear", -- Fear 2
        [5484]   = "fear", -- Howl of Terror
        [115268] = "fear", -- Mesmerize (Shivarra)
        [6358]   = "fear", -- Seduction (Succubus)
        [104045] = "fear", -- Sleep (Metamorphosis) -- TODO: verify this is the correct category
        [5246]   = "fear", -- Intimidating Shout
        [20511]  = "fear", -- Intimidating Shout (secondary targets)

        -- *** Controlled Root Effects ***
        [96294]  = "root", -- Chains of Ice (Chilblains Root)
        [339]    = "root", -- Entangling Roots
        [113275] = "root", -- Entangling Roots (Symbiosis)
        [113770] = "root", -- Entangling Roots (Treants)
        [102359] = "root", -- Mass Entanglement
        [19975]  = "root", -- Nature's Grasp
        [128405] = "root", -- Narrow Escape
        --[53148]  = "root", -- Charge (Tenacity pet)
        [90327]  = "root", -- Lock Jaw (Dog)
        [54706]  = "root", -- Venom Web Spray (Silithid)
        [50245]  = "root", -- Pin (Crab)
        [4167]   = "root", -- Web (Spider)
        [33395]  = "root", -- Freeze (Water Elemental)
        [122]    = "root", -- Frost Nova
        [110693] = "root", -- Frost Nova (Symbiosis)
        [116706] = "root", -- Disable
        [87194]  = "root", -- Glyph of Mind Blast
        [114404] = "root", -- Void Tendrils
        [115197] = "root", -- Partial Paralysis
        [63685]  = "root", -- Freeze (Frost Shock)
        [107566] = "root", -- Staggering Shout

        -- *** Non-controlled Root Effects ***
        [64803]  = "random_root", -- Entrapment
        [111340] = "random_root", -- Ice Ward
        [123407] = "random_root", -- Spinning Fire Blossom
        [64695]  = "random_root", -- Earthgrab Totem

        -- *** Disarm Weapon Effects ***
        [50541]  = "disarm", -- Clench (Scorpid)
        [91644]  = "disarm", -- Snatch (Bird of Prey)
        [117368] = "disarm", -- Grapple Weapon
        [126458] = "disarm", -- Grapple Weapon (Symbiosis)
        [137461] = "disarm", -- Ring of Peace (Disarm effect)
        [64058]  = "disarm", -- Psychic Horror (Disarm Effect)
        [51722]  = "disarm", -- Dismantle
        [118093] = "disarm", -- Disarm (Voidwalker/Voidlord)
        [676]    = "disarm", -- Disarm

        -- *** Silence Effects ***
        -- [108194] = "silence", -- Asphyxiate (TODO: check silence id)
        [47476]  = "silence", -- Strangulate
        [114238] = "silence", -- Glyph of Fae Silence
        [34490]  = "silence", -- Silencing Shot
        [102051] = "silence", -- Frostjaw
        [55021]  = "silence", -- Counterspell
        [137460] = "silence", -- Ring of Peace (Silence effect)
        [116709] = "silence", -- Spear Hand Strike
        [31935]  = "silence", -- Avenger's Shield
        [15487]  = "silence", -- Silence
        [1330]   = "silence", -- Garrote
        [24259]  = "silence", -- Spell Lock
        [115782] = "silence", -- Optical Blast (Observer)
        [18498]  = "silence", -- Silenced - Gag Order
        [50613]  = "silence", -- Arcane Torrent (Racial, Runic Power)
        [28730]  = "silence", -- Arcane Torrent (Racial, Mana)
        [25046]  = "silence", -- Arcane Torrent (Racial, Energy)
        [69179]  = "silence", -- Arcane Torrent (Racial, Rage)
        [80483]  = "silence", -- Arcane Torrent (Racial, Focus)

        -- *** Horror Effects ***
        [64044]  = "horror", -- Psychic Horror
        [137143] = "horror", -- Blood Horror
        [6789]   = "horror", -- Death Coil

        -- *** Mind Control Effects ***
        [605]   = "mind_control", -- Dominate Mind
        [13181] = "mind_control", -- Gnomish Mind Control Cap (Item)
        [67799] = "mind_control", -- Mind Amplification Dish (Item)

        -- *** Force Taunt Effects ***
        [56222]   = "taunt", -- Dark Command
        [51399]   = "taunt", -- Death Grip (Taunt Effect)
        [6795]    = "taunt", -- Growl (Druid)
        [20736]   = "taunt", -- Distracting Shot
        [116189]  = "taunt", -- Provoke
        [62124]   = "taunt", -- Hand of Reckoning
        [355]     = "taunt", -- Taunt

        -- *** Knockback Effects ***
        [108199] = "knockback", -- Gorefiend's Grasp
        [102793] = "knockback", -- Ursol's Vortex
        [61391]  = "knockback", -- Typhoon
        [13812]  = "knockback", -- Glyph of Explosive Trap
        [51490]  = "knockback", -- Thunderstorm
        [6360]   = "knockback", -- Whiplash
        [115770] = "knockback", -- Fellash

        -- *** Spells that DRs with itself only ***
        [33786]  = "cyclone", -- Cyclone
        [113506] = "cyclone", -- Cyclone (Symbiosis)
    };
end

-- Reference the list from BigDebuffs
addon.DRList[81261]   = "silence"; -- Solar Beam

addon.CrowdControlAuras = {};
for spellId, drType in pairs(addon.DRList) do
    if ( type(drType) == "table" ) or ( drType ~= "taunt" and drType ~= "knockback" ) then
        addon.CrowdControlAuras[spellId] = true;
    end
end

if addon.PROJECT_MAINLINE then
    local breakers = {};

    breakers[205604] = { -- Reverse Magic
        [360806]  = "disorient", -- Sleep Walk
        [1513]    = "disorient", -- Scare Beast
        [605]     = "disorient", -- Mind Control
        [8122]    = "disorient", -- Psychic Scream
        [118699]  = "disorient", -- Fear
        [130616]  = "disorient", -- Fear (Horrify)
        [5484]    = "disorient", -- Howl of Terror
        [353084]  = "disorient", -- Ring of Fire
        [261589]  = "disorient", -- Seduction (Grimoire of Sacrifice)
        [6358]    = "disorient", -- Seduction (Succubus)
        [217832]  = "incapacitate", -- Imprison
        [2637]    = "incapacitate", -- Hibernate
        [3355]    = "incapacitate", -- Freezing Trap
        [383121]  = "incapacitate", -- Mass Polymorph
        [118]     = "incapacitate", -- Polymorph
        [28271]   = "incapacitate", -- Polymorph (Turtle)
        [28272]   = "incapacitate", -- Polymorph (Pig)
        [61025]   = "incapacitate", -- Polymorph (Snake)
        [61305]   = "incapacitate", -- Polymorph (Black Cat)
        [61780]   = "incapacitate", -- Polymorph (Turkey)
        [61721]   = "incapacitate", -- Polymorph (Rabbit)
        [126819]  = "incapacitate", -- Polymorph (Porcupine)
        [161353]  = "incapacitate", -- Polymorph (Polar Bear Cub)
        [161354]  = "incapacitate", -- Polymorph (Monkey)
        [161355]  = "incapacitate", -- Polymorph (Penguin)
        [161372]  = "incapacitate", -- Polymorph (Peacock)
        [277787]  = "incapacitate", -- Polymorph (Baby Direhorn)
        [277792]  = "incapacitate", -- Polymorph (Bumblebee)
        [321395]  = "incapacitate", -- Polymorph (Mawrat)
        [391622]  = "incapacitate", -- Polymorph (Duck)
        [460396]  = "incapacitate", -- Polymorph (Mosswool)
        [461489]  = "incapacitate", -- Polymorph (Mosswool) 2
        [82691]   = "incapacitate", -- Ring of Frost
        [20066]   = "incapacitate", -- Repentance
        [9484]    = "incapacitate", -- Shackle Undead
        [6789]    = "incapacitate", -- Mortal Coil
        [211881]  = "stun", -- Fel Eruption
        [853]     = "stun", -- Hammer of Justice
        [64044]   = "stun", -- Psychic Horror
        [15487]   = "silence", -- Silence
    };

    breakers[2782] = { -- Remove Corruption (Curse/Poison)
        [51514]   = "incapacitate", -- Hex
        [196942]  = "incapacitate", -- Hex (Voodoo Totem)
        [210873]  = "incapacitate", -- Hex (Raptor)
        [211004]  = "incapacitate", -- Hex (Spider)
        [211010]  = "incapacitate", -- Hex (Snake)
        [211015]  = "incapacitate", -- Hex (Cockroach)
        [269352]  = "incapacitate", -- Hex (Skeletal Hatchling)
        [309328]  = "incapacitate", -- Hex (Living Honey)
        [277778]  = "incapacitate", -- Hex (Zandalari Tendonripper)
        [277784]  = "incapacitate", -- Hex (Wicker Mongrel)
        [356727]  = "silence", -- Spider Venom (Poison)
    };

    breakers[374251] = { -- Cauterizing Flame (Curse/Poison/Bleed/Disease)
        [51514]   = "incapacitate", -- Hex
        [196942]  = "incapacitate", -- Hex (Voodoo Totem)
        [210873]  = "incapacitate", -- Hex (Raptor)
        [211004]  = "incapacitate", -- Hex (Spider)
        [211010]  = "incapacitate", -- Hex (Snake)
        [211015]  = "incapacitate", -- Hex (Cockroach)
        [269352]  = "incapacitate", -- Hex (Skeletal Hatchling)
        [309328]  = "incapacitate", -- Hex (Living Honey)
        [277778]  = "incapacitate", -- Hex (Zandalari Tendonripper)
        [277784]  = "incapacitate", -- Hex (Wicker Mongrel)
        [356727]  = "silence", -- Spider Venom (Poison)
        [210141]  = "stun", -- Zombie Explosion (Disease)
    };

    breakers[19801] = { -- Tranqulizer Shot
        [605]     = "disorient", -- Mind Control
    };

    breakers[475] = { -- Remove Curse
        [51514]   = "incapacitate", -- Hex
        [196942]  = "incapacitate", -- Hex (Voodoo Totem)
        [210873]  = "incapacitate", -- Hex (Raptor)
        [211004]  = "incapacitate", -- Hex (Spider)
        [211010]  = "incapacitate", -- Hex (Snake)
        [211015]  = "incapacitate", -- Hex (Cockroach)
        [269352]  = "incapacitate", -- Hex (Skeletal Hatchling)
        [309328]  = "incapacitate", -- Hex (Living Honey)
        [277778]  = "incapacitate", -- Hex (Zandalari Tendonripper)
        [277784]  = "incapacitate", -- Hex (Wicker Mongrel)
    };

    breakers[218164] = { -- Detox (Poison/Disease)
        [356727]  = "silence", -- Spider Venom (Poison)
        [210141]  = "stun", -- Zombie Explosion (Disease)
    };

    breakers[213644] = { -- Cleanse Toxins (Poison/Disease)
        [356727]  = "silence", -- Spider Venom (Poison)
        [210141]  = "stun", -- Zombie Explosion (Disease)
    };

    breakers[210256] = { -- Blessing of Sanctuary (stun/silence/fear/horror)
        [8122]    = "disorient", -- Psychic Scream
        [118699]  = "disorient", -- Fear
        [130616]  = "disorient", -- Fear (Horrify)
        [5484]    = "disorient", -- Howl of Terror
        [5246]    = "disorient", -- Intimidating Shout
        [210141]  = "stun", -- Zombie Explosion
        [377048]  = "stun", -- Absolute Zero (Breath of Sindragosa)
        [108194]  = "stun", -- Asphyxiate (Unholy)
        [221562]  = "stun", -- Asphyxiate (Blood)
        [91800]   = "stun", -- Gnaw (Ghoul)
        [91797]   = "stun", -- Monstrous Blow (Mutated Ghoul)
        [287254]  = "stun", -- Dead of Winter
        [179057]  = "stun", -- Chaos Nova
        [205630]  = "stun", -- Illidan's Grasp (Primary effect)
        [208618]  = "stun", -- Illidan's Grasp (Secondary effect)
        [211881]  = "stun", -- Fel Eruption
        [200166]  = "stun", -- Metamorphosis (PvE stun effect)
        [203123]  = "stun", -- Maim
        [163505]  = "stun", -- Rake (Prowl)
        [5211]    = "stun", -- Mighty Bash
        [202244]  = "stun", -- Overrun
        [325321]  = "stun", -- Wild Hunt's Charge
        [372245]  = "stun", -- Terror of the Skies
        [408544]  = "stun", -- Seismic Slam
        [117526]  = "stun", -- Binding Shot
        [357021]  = "stun", -- Consecutive Concussion
        [24394]   = "stun", -- Intimidation
        [389831]  = "stun", -- Snowdrift
        [119381]  = "stun", -- Leg Sweep
        [458605]  = "stun", -- Leg Sweep 2
        [202346]  = "stun", -- Double Barrel
        [853]     = "stun", -- Hammer of Justice
        [255941]  = "stun", -- Wake of Ashes
        [64044]   = "stun", -- Psychic Horror
        [200200]  = "stun", -- Holy Word: Chastise Censure
        [1833]    = "stun", -- Cheap Shot
        [408]     = "stun", -- Kidney Shot
        [118905]  = "stun", -- Static Charge (Capacitor Totem)
        [118345]  = "stun", -- Pulverize (Primal Earth Elemental)
        [305485]  = "stun", -- Lightning Lasso
        [89766]   = "stun", -- Axe Toss
        [171017]  = "stun", -- Meteor Strike (Infernal)
        [171018]  = "stun", -- Meteor Strike (Abyssal)
        [30283]   = "stun", -- Shadowfury
        [385954]  = "stun", -- Shield Charge
        [46968]   = "stun", -- Shockwave
        [132168]  = "stun", -- Shockwave (Protection)
        [145047]  = "stun", -- Shockwave (Proving Grounds PvE)
        [132169]  = "stun", -- Storm Bolt
        [199085]  = "stun", -- Warpath
        [20549]   = "stun", -- War Stomp (Racial, Tauren)
        [255723]  = "stun", -- Bull Rush (Racial, Highmountain Tauren)
        [287712]  = { "stun", "knockback" }, -- Haymaker (Racial, Kul Tiran)
        [332423]  = "stun", -- Sparkling Driftglobe Core (Kyrian Covenant)
        [47476]   = "silence", -- Strangulate
        [374776]  = "silence", -- Tightening Grasp
        [204490]  = "silence", -- Sigil of Silence
--      [78675]   = "silence", -- Solar Beam (has no DR)
        [410065]  = "silence", -- Reactive Resin
        [202933]  = "silence", -- Spider Sting
        [356727]  = "silence", -- Spider Venom
        [354831]  = "silence", -- Wailing Arrow 1
        [355596]  = "silence", -- Wailing Arrow 2
        [217824]  = "silence", -- Shield of Virtue
        [15487]   = "silence", -- Silence
        [1330]    = "silence", -- Garrote
        [196364]  = "silence", -- Unstable Affliction Silence Effect
    };

    breakers[1022] = { -- Blessing of Protection
        [2094]    = "disorient", -- Blind
        [108194]  = "stun", -- Asphyxiate (Unholy)
        [221562]  = "stun", -- Asphyxiate (Blood)
        [91800]   = "stun", -- Gnaw (Ghoul)
        [179057]  = "stun", -- Chaos Nova
        [203123]  = "stun", -- Maim
        [163505]  = "stun", -- Rake (Prowl)
        [5211]    = "stun", -- Mighty Bash
        [24394]   = "stun", -- Intimidation
        [119381]  = "stun", -- Leg Sweep
        [458605]  = "stun", -- Leg Sweep 2
        [1833]    = "stun", -- Cheap Shot
        [408]     = "stun", -- Kidney Shot
        [89766]   = "stun", -- Axe Toss
        [46968]   = "stun", -- Shockwave
        [132168]  = "stun", -- Shockwave (Protection)
        [132169]  = "stun", -- Storm Bolt
        [20549]   = "stun", -- War Stomp (Racial, Tauren)
        [255723]  = "stun", -- Bull Rush (Racial, Highmountain Tauren)
        [287712]  = { "stun", "knockback" }, -- Haymaker (Racial, Kul Tiran)
        [1330]    = "silence", -- Garrote
    };

    breakers[213634] = { -- Purify Disease
        [210141]  = "stun", -- Zombie Explosion (Disease)
    };

    breakers[528] = { -- Dispel Magic
        [605]     = "disorient", -- Mind Control
    };

    breakers[32375] = { -- Mass Dispel
        [360806]  = "disorient", -- Sleep Walk
        [1513]    = "disorient", -- Scare Beast
        --[605]     = "disorient", -- Mind Control (We can purge Mind Control, so don't show Mass Dispel for it)
        [8122]    = "disorient", -- Psychic Scream
        [118699]  = "disorient", -- Fear
        [130616]  = "disorient", -- Fear (Horrify)
        [5484]    = "disorient", -- Howl of Terror
        [353084]  = "disorient", -- Ring of Fire
        [261589]  = "disorient", -- Seduction (Grimoire of Sacrifice)
        [6358]    = "disorient", -- Seduction (Succubus)
        [217832]  = "incapacitate", -- Imprison
        [2637]    = "incapacitate", -- Hibernate
        [3355]    = "incapacitate", -- Freezing Trap
        [383121]  = "incapacitate", -- Mass Polymorph
        [118]     = "incapacitate", -- Polymorph
        [28271]   = "incapacitate", -- Polymorph (Turtle)
        [28272]   = "incapacitate", -- Polymorph (Pig)
        [61025]   = "incapacitate", -- Polymorph (Snake)
        [61305]   = "incapacitate", -- Polymorph (Black Cat)
        [61780]   = "incapacitate", -- Polymorph (Turkey)
        [61721]   = "incapacitate", -- Polymorph (Rabbit)
        [126819]  = "incapacitate", -- Polymorph (Porcupine)
        [161353]  = "incapacitate", -- Polymorph (Polar Bear Cub)
        [161354]  = "incapacitate", -- Polymorph (Monkey)
        [161355]  = "incapacitate", -- Polymorph (Penguin)
        [161372]  = "incapacitate", -- Polymorph (Peacock)
        [277787]  = "incapacitate", -- Polymorph (Baby Direhorn)
        [277792]  = "incapacitate", -- Polymorph (Bumblebee)
        [321395]  = "incapacitate", -- Polymorph (Mawrat)
        [391622]  = "incapacitate", -- Polymorph (Duck)
        [460396]  = "incapacitate", -- Polymorph (Mosswool)
        [461489]  = "incapacitate", -- Polymorph (Mosswool) 2
        [82691]   = "incapacitate", -- Ring of Frost
        [20066]   = "incapacitate", -- Repentance
        [9484]    = "incapacitate", -- Shackle Undead
        [6789]    = "incapacitate", -- Mortal Coil
        [211881]  = "stun", -- Fel Eruption
        [853]     = "stun", -- Hammer of Justice
        [64044]   = "stun", -- Psychic Horror
        [15487]   = "silence", -- Silence

        -- Extra compared to Reverse Magic
        [33786]   = "disorient", -- Cyclone
        [203337]  = "incapacitate", -- Freezing Trap (Honor talent)
        [78675]   = "silence", -- Solar Beam (has no DR)
    };

    breakers[370] = { -- Purge
        [605]     = "disorient", -- Mind Control
    };

    breakers[8143] = { -- Tremor Totem
        [360806]  = "disorient", -- Sleep Walk
        [1513]    = "disorient", -- Scare Beast
        [8122]    = "disorient", -- Psychic Scream
        [118699]  = "disorient", -- Fear
        [130616]  = "disorient", -- Fear (Horrify)
        [5484]    = "disorient", -- Howl of Terror
        [5246]    = "disorient", -- Intimidating Shout
    };

    breakers[51886] = { -- Cleanse Spirit
        [51514]   = "incapacitate", -- Hex
        [196942]  = "incapacitate", -- Hex (Voodoo Totem)
        [210873]  = "incapacitate", -- Hex (Raptor)
        [211004]  = "incapacitate", -- Hex (Spider)
        [211010]  = "incapacitate", -- Hex (Snake)
        [211015]  = "incapacitate", -- Hex (Cockroach)
        [269352]  = "incapacitate", -- Hex (Skeletal Hatchling)
        [309328]  = "incapacitate", -- Hex (Living Honey)
        [277778]  = "incapacitate", -- Hex (Zandalari Tendonripper)
        [277784]  = "incapacitate", -- Hex (Wicker Mongrel)
    };

    breakers[119905] = { -- Singe Magic
        [360806]  = "disorient", -- Sleep Walk
        [1513]    = "disorient", -- Scare Beast
        [605]     = "disorient", -- Mind Control
        [8122]    = "disorient", -- Psychic Scream
        [118699]  = "disorient", -- Fear
        [130616]  = "disorient", -- Fear (Horrify)
        [5484]    = "disorient", -- Howl of Terror
        [353084]  = "disorient", -- Ring of Fire
        [261589]  = "disorient", -- Seduction (Grimoire of Sacrifice)
        [6358]    = "disorient", -- Seduction (Succubus)
        [217832]  = "incapacitate", -- Imprison
        [2637]    = "incapacitate", -- Hibernate
        [3355]    = "incapacitate", -- Freezing Trap
        [383121]  = "incapacitate", -- Mass Polymorph
        [118]     = "incapacitate", -- Polymorph
        [28271]   = "incapacitate", -- Polymorph (Turtle)
        [28272]   = "incapacitate", -- Polymorph (Pig)
        [61025]   = "incapacitate", -- Polymorph (Snake)
        [61305]   = "incapacitate", -- Polymorph (Black Cat)
        [61780]   = "incapacitate", -- Polymorph (Turkey)
        [61721]   = "incapacitate", -- Polymorph (Rabbit)
        [126819]  = "incapacitate", -- Polymorph (Porcupine)
        [161353]  = "incapacitate", -- Polymorph (Polar Bear Cub)
        [161354]  = "incapacitate", -- Polymorph (Monkey)
        [161355]  = "incapacitate", -- Polymorph (Penguin)
        [161372]  = "incapacitate", -- Polymorph (Peacock)
        [277787]  = "incapacitate", -- Polymorph (Baby Direhorn)
        [277792]  = "incapacitate", -- Polymorph (Bumblebee)
        [321395]  = "incapacitate", -- Polymorph (Mawrat)
        [391622]  = "incapacitate", -- Polymorph (Duck)
        [460396]  = "incapacitate", -- Polymorph (Mosswool)
        [461489]  = "incapacitate", -- Polymorph (Mosswool) 2
        [82691]   = "incapacitate", -- Ring of Frost
        [20066]   = "incapacitate", -- Repentance
        [9484]    = "incapacitate", -- Shackle Undead
        [6789]    = "incapacitate", -- Mortal Coil
        [211881]  = "stun", -- Fel Eruption
        [853]     = "stun", -- Hammer of Justice
        [64044]   = "stun", -- Psychic Horror
        [15487]   = "silence", -- Silence
    };

    breakers[132411] = { -- Singe Magic (Grimoire of Sacrifice)
        [360806]  = "disorient", -- Sleep Walk
        [1513]    = "disorient", -- Scare Beast
        [605]     = "disorient", -- Mind Control
        [8122]    = "disorient", -- Psychic Scream
        [118699]  = "disorient", -- Fear
        [130616]  = "disorient", -- Fear (Horrify)
        [5484]    = "disorient", -- Howl of Terror
        [353084]  = "disorient", -- Ring of Fire
        [261589]  = "disorient", -- Seduction (Grimoire of Sacrifice)
        [6358]    = "disorient", -- Seduction (Succubus)
        [217832]  = "incapacitate", -- Imprison
        [2637]    = "incapacitate", -- Hibernate
        [3355]    = "incapacitate", -- Freezing Trap
        [383121]  = "incapacitate", -- Mass Polymorph
        [118]     = "incapacitate", -- Polymorph
        [28271]   = "incapacitate", -- Polymorph (Turtle)
        [28272]   = "incapacitate", -- Polymorph (Pig)
        [61025]   = "incapacitate", -- Polymorph (Snake)
        [61305]   = "incapacitate", -- Polymorph (Black Cat)
        [61780]   = "incapacitate", -- Polymorph (Turkey)
        [61721]   = "incapacitate", -- Polymorph (Rabbit)
        [126819]  = "incapacitate", -- Polymorph (Porcupine)
        [161353]  = "incapacitate", -- Polymorph (Polar Bear Cub)
        [161354]  = "incapacitate", -- Polymorph (Monkey)
        [161355]  = "incapacitate", -- Polymorph (Penguin)
        [161372]  = "incapacitate", -- Polymorph (Peacock)
        [277787]  = "incapacitate", -- Polymorph (Baby Direhorn)
        [277792]  = "incapacitate", -- Polymorph (Bumblebee)
        [321395]  = "incapacitate", -- Polymorph (Mawrat)
        [391622]  = "incapacitate", -- Polymorph (Duck)
        [460396]  = "incapacitate", -- Polymorph (Mosswool)
        [461489]  = "incapacitate", -- Polymorph (Mosswool) 2
        [82691]   = "incapacitate", -- Ring of Frost
        [20066]   = "incapacitate", -- Repentance
        [9484]    = "incapacitate", -- Shackle Undead
        [6789]    = "incapacitate", -- Mortal Coil
        [211881]  = "stun", -- Fel Eruption
        [853]     = "stun", -- Hammer of Justice
        [64044]   = "stun", -- Psychic Horror
        [15487]   = "silence", -- Silence
    };

    addon.CrowdControlBreakers = {};

    -- write logic to fill addon.CrowdControlBreakers, e.g.,
    -- given breakers[123] = 456, fill addon.CrowdControlBreakers[456][123] = true
    for breaker, spells in pairs(breakers) do
        if type(spells) == "table" then
            for spellID, _ in pairs(spells) do
                addon.CrowdControlBreakers[spellID] = addon.CrowdControlBreakers[spellID] or {};
                addon.CrowdControlBreakers[spellID][breaker] = true;
                --print("Spell", spellID, "can be broken by", breaker);
            end
        end
    end
end
