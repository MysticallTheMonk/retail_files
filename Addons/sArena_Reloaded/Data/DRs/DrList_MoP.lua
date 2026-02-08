sArenaMixin.drCategories = {
	"Incapacitate",
	"Stun",
	"RandomStun",
	"RandomRoot",
	"Root",
	"Disarm",
	"Fear",
	"Disorient",
	"Silence",
	"Horror",
	"MindControl",
	"Cyclone",
	"Charge",
}

sArenaMixin.defaultSettings.profile.drCategories = {
	["Incapacitate"] = true,
	["Stun"] = true,
	["RandomStun"] = true,
	["RandomRoot"] = true,
	["Root"] = true,
	["Disarm"] = true,
	["Fear"] = true,
	["Disorient"] = true,
	["Silence"] = true,
	["Horror"] = true,
	["MindControl"] = true,
	["Cyclone"] = true,
	["Charge"] = false,
}

sArenaMixin.defaultSettings.profile.drIcons = {
	["Incapacitate"] = 136071,
	["Stun"] = 132298,
	["RandomStun"] = 133477,
	["RandomRoot"] = 135852,
	["Root"] = 135848,
	["Disarm"] = 132343,
	["Fear"] = 136183,
	["Disorient"] = 134153,
	["Silence"] = 458230,
	["Horror"] = 237568,
	["MindControl"] = 136206,
	["Cyclone"] = 136022,
	["Charge"] = 132337,
}

sArenaMixin.drList = {
	[49203]  = "Incapacitate", -- Hungering Cold
	[2637]   = "Incapacitate", -- Hibernate
	[3355]   = "Incapacitate", -- Freezing Trap Effect
	[19386]  = "Incapacitate", -- Wyvern Sting
	[118]    = "Incapacitate", -- Polymorph
	[28271]  = "Incapacitate", -- Polymorph: Turtle
	[28272]  = "Incapacitate", -- Polymorph: Pig
	[61721]  = "Incapacitate", -- Polymorph: Rabbit
	[61780]  = "Incapacitate", -- Polymorph: Turkey
	[61305]  = "Incapacitate", -- Polymorph: Black Cat
	[20066]  = "Incapacitate", -- Repentance
	[1776]   = "Incapacitate", -- Gouge
	[6770]   = "Incapacitate", -- Sap
	[710]    = "Incapacitate", -- Banish
	[9484]   = "Incapacitate", -- Shackle Undead
	[51514]  = "Incapacitate", -- Hex
	[13327]  = "Incapacitate", -- Reckless Charge (Rocket Helmet)
	[4064]   = "Incapacitate", -- Rough Copper Bomb
	[4065]   = "Incapacitate", -- Large Copper Bomb
	[4066]   = "Incapacitate", -- Small Bronze Bomb
	[4067]   = "Incapacitate", -- Big Bronze Bomb
	[4068]   = "Incapacitate", -- Iron Grenade
	[12421]  = "Incapacitate", -- Mithril Frag Bomb
	[4069]   = "Incapacitate", -- Big Iron Bomb
	[12562]  = "Incapacitate", -- The Big One
	[12543]  = "Incapacitate", -- Hi-Explosive Bomb
	[19769]  = "Incapacitate", -- Thorium Grenade
	[19784]  = "Incapacitate", -- Dark Iron Bomb
	[30216]  = "Incapacitate", -- Fel Iron Bomb
	[30461]  = "Incapacitate", -- The Bigger One
	[30217]  = "Incapacitate", -- Adamantite Grenade
	[61025]  = "Incapacitate", -- Polymorph: Serpent
	[82691]  = "Incapacitate", -- Ring of Frost
	[115078] = "Incapacitate", -- Paralysis
	[76780]  = "Incapacitate", -- Bind Elemental
	[107079] = "Incapacitate", -- Quaking Palm (Racial)

	[47481]  = "Stun",       -- Gnaw (Ghoul Pet)
	[5211]   = "Stun",       -- Bash
	[22570]  = "Stun",       -- Maim
	[24394]  = "Stun",       -- Intimidation
	[50519]  = "Stun",       -- Sonic Blast
	[50518]  = "Stun",       -- Ravage
	[44572]  = "Stun",       -- Deep Freeze
	[853]    = "Stun",       -- Hammer of Justice
	--[2812]  = "Stun",      -- Holy Wrath
	[408]    = "Stun",       -- Kidney Shot
	[1833]   = "Stun",       -- Cheap Shot
	[58861]  = "Stun",       -- Bash (Spirit Wolves)
	[30283]  = "Stun",       -- Shadowfury
	[12809]  = "Stun",       -- Concussion Blow
	[60995]  = "Stun",       -- Demon Charge
	[30153]  = "Stun",       -- Pursuit
	[20253]  = "Stun",       -- Intercept Stun
	[46968]  = "Stun",       -- Shockwave
	[20549]  = "Stun",       -- War Stomp (Racial)
	[85388]  = "Stun",       -- Throwdown
	[90337]  = "Stun",       -- Bad Manner (Hunter Pet Stun)
	[91800]  = "Stun",       -- Gnaw (DK Pet Stun)
	[108194] = "Stun",       -- Asphyxiate
	[91797]  = "Stun",       -- Monstrous Blow (Dark Transformation Ghoul)
	[115001] = "Stun",       -- Remorseless Winter
	[102795] = "Stun",       -- Bear Hug
	[113801] = "Stun",       -- Bash (Treants)
	[117526] = "Stun",       -- Binding Shot
	[126246] = "Stun",       -- Lullaby (Crane pet) -- TODO: verify category
	[126423] = "Stun",       -- Petrifying Gaze (Basilisk pet) -- TODO: verify category
	[126355] = "Stun",       -- Quill (Porcupine pet) -- TODO: verify category
	[56626]  = "Stun",       -- Sting (Wasp)
	[118271] = "Stun",       -- Combustion
	[119392] = "Stun",       -- Charging Ox Wave
	[122242] = "Stun",       -- Clash
	[120086] = "Stun",       -- Fists of Fury
	[119381] = "Stun",       -- Leg Sweep
	[115752] = "Stun",       -- Blinding Light (Glyphed)
	[110698] = "Stun",       -- Hammer of Justice (Symbiosis)
	[119072] = "Stun",       -- Holy Wrath
	[105593] = "Stun",       -- Fist of Justice
	[118345] = "Stun",       -- Pulverize (Primal Earth Elemental)
	[118905] = "Stun",       -- Static Charge (Capacitor Totem)
	[89766]  = "Stun",       -- Axe Toss (Felguard)
	[22703]  = "Stun",       -- Inferno Effect
	[132168] = "Stun",       -- Shockwave
	[107570] = "Stun",       -- Storm Bolt
	[132169] = "Stun",       -- Storm Bolt
	[96201]  = "Stun",       -- Web Wrap
	[122057] = "Stun",       -- Clash
	[15618]  = "Stun",       -- Snap Kick
	[9005]   = "Stun",       -- Pounce
	[102546] = "Stun",       -- Pounce (MoP)
	[127361] = "Stun",       -- Bear Hug (Symbiosis)

	[16922]  = "RandomStun", -- Celestial Focus (Starfire Stun)
	[28445]  = "RandomStun", -- Improved Concussive Shot
	[12355]  = "RandomStun", -- Impact
	[20170]  = "RandomStun", -- Seal of Justice Stun
	[39796]  = "RandomStun", -- Stoneclaw Stun
	[12798]  = "RandomStun", -- Revenge Stun
	[5530]   = "RandomStun", -- Mace Stun Effect (Mace Specialization)
	[15283]  = "RandomStun", -- Stunning Blow (Weapon Proc)
	[56]     = "RandomStun", -- Stun (Weapon Proc)
	[34510]  = "RandomStun", -- Stormherald/Deep Thunder (Weapon Proc)
	[113953] = "RandomStun", -- Paralysis
	[118895] = "RandomStun", -- Dragon Roar
	[77505]  = "RandomStun", -- Earthquake
	[100]    = "RandomStun", -- Charge
	[118000] = "RandomStun", -- Dragon Roar

	[1513]   = "Fear",       -- Scare Beast
	[10326]  = "Fear",       -- Turn Evil
	[8122]   = "Fear",       -- Psychic Scream
	[2094]   = "Fear",       -- Blind
	[5782]   = "Fear",       -- Fear
	[130616] = "Fear",       -- Fear (Glyphed)
	[6358]   = "Fear",       -- Seduction (Succubus)
	[5484]   = "Fear",       -- Howl of Terror
	[5246]   = "Fear",       -- Intimidating Shout
	[5134]   = "Fear",       -- Flash Bomb Fear (Item)
	[113004] = "Fear",       -- Intimidating Roar (Symbiosis)
	[113056] = "Fear",       -- Intimidating Roar (Symbiosis 2)
	[145067] = "Fear",       -- Turn Evil (Evil is a Point of View)
	[113792] = "Fear",       -- Psychic Terror (Psyfiend)
	[118699] = "Fear",       -- Fear 2
	[115268] = "Fear",       -- Mesmerize (Shivarra)
	[104045] = "Fear",       -- Sleep (Metamorphosis) -- TODO: verify this is the correct category
	[20511]  = "Fear",       -- Intimidating Shout (secondary targets)

	[339]    = "Root",       -- Entangling Roots
	[19975]  = "Root",       -- Nature's Grasp
	[50245]  = "Root",       -- Pin
	[33395]  = "Root",       -- Freeze (Water Elemental)
	[122]    = "Root",       -- Frost Nova
	[39965]  = "Root",       -- Frost Grenade (Item)
	[63685]  = "Root",       -- Freeze (Frost Shock)
	[96294]  = "Root",       -- Chains of Ice (Chilblains Root)
	[113275] = "Root",       -- Entangling Roots (Symbiosis)
	[102359] = "Root",       -- Mass Entanglement
	[128405] = "Root",       -- Narrow Escape
	--[53148]  = "Root", -- Charge (Tenacity pet)
	[90327]  = "Root",       -- Lock Jaw (Dog)
	[54706]  = "Root",       -- Venom Web Spray (Silithid)
	[4167]   = "Root",       -- Web (Spider)
	[110693] = "Root",       -- Frost Nova (Symbiosis)
	[116706] = "Root",       -- Disable
	[87194]  = "Root",       -- Glyph of Mind Blast
	[114404] = "Root",       -- Void Tendrils
	[115197] = "Root",       -- Partial Paralysis
	[107566] = "Root",       -- Staggering Shout
	[113770] = "Root",       -- Entangling Roots
	[53148]  = "Root",       -- Charge
	[136634] = "Root",       -- Narrow Escape
	--[127797] = "PseudoRoot", -- Ursol's Vortex
	[81210]  = "Root",       -- Net
	[135373] = "Root",       -- Entrapment (MoP)
	[45334]  = "Root",       -- Immobilized (MoP)

	[12494]  = "RandomRoot", -- Frostbite
	[55080]  = "RandomRoot", -- Shattered Barrier
	[58373]  = "RandomRoot", -- Glyph of Hamstring
	[23694]  = "RandomRoot", -- Improved Hamstring
	[47168]  = "RandomRoot", -- Improved Wing Clip
	[19185]  = "RandomRoot", -- Entrapment
	[64803]  = "RandomRoot", -- Entrapment
	[111340] = "RandomRoot", -- Ice Ward
	[123407] = "RandomRoot", -- Spinning Fire Blossom
	[64695]  = "RandomRoot", -- Earthgrab Totem

	[53359]  = "Disarm",     -- Chimera Shot (Scorpid)
	[50541]  = "Disarm",     -- Clench
	[64058]  = "Disarm",     -- Psychic Horror Disarm Effect
	[51722]  = "Disarm",     -- Dismantle
	[676]    = "Disarm",     -- Disarm
	[91644]  = "Disarm",     -- Snatch (Bird of Prey)
	[117368] = "Disarm",     -- Grapple Weapon
	[126458] = "Disarm",     -- Grapple Weapon (Symbiosis)
	[137461] = "Disarm",     -- Ring of Peace (Disarm effect)
	[118093] = "Disarm",     -- Disarm (Voidwalker/Voidlord)

	[47476]  = "Silence",    -- Strangulate
	[34490]  = "Silence",    -- Silencing Shot
	[35334]  = "Silence",    -- Nether Shock (Rank 1)
	[44957]  = "Silence",    -- Nether Shock (Rank 2)
	[18469]  = "Silence",    -- Silenced - Improved Counterspell (Rank 1)
	[55021]  = "Silence",    -- Silenced - Improved Counterspell (Rank 2)
	[15487]  = "Silence",    -- Silence
	[1330]   = "Silence",    -- Garrote - Silence
	[18425]  = "Silence",    -- Silenced - Improved Kick
	[24259]  = "Silence",    -- Spell Lock
	[43523]  = "Silence",    -- Unstable Affliction 1
	[31117]  = "Silence",    -- Unstable Affliction 2
	[18498]  = "Silence",    -- Silenced - Gag Order (Shield Slam)
	[50613]  = "Silence",    -- Arcane Torrent (Racial, Runic Power)
	[28730]  = "Silence",    -- Arcane Torrent (Racial, Mana)
	[25046]  = "Silence",    -- Arcane Torrent (Racial, Energy)
	-- [108194] = "Silence", -- Asphyxiate (TODO: check silence id)
	[114238] = "Silence",    -- Glyph of Fae Silence
	[102051] = "Silence",    -- Frostjaw
	[137460] = "Silence",    -- Ring of Peace (Silence effect)
	[116709] = "Silence",    -- Spear Hand Strike
	[31935]  = "Silence",    -- Avenger's Shield
	[115782] = "Silence",    -- Optical Blast (Observer)
	[69179]  = "Silence",    -- Arcane Torrent (Racial, Rage)
	[80483]  = "Silence",    -- Arcane Torrent (Racial, Focus)

	[64044]  = "Horror",     -- Psychic Horror
	[6789]   = "Horror",     -- Death Coil
	[137143] = "Horror",     -- Blood Horror

	-- Spells that DR with itself only
	[33786]  = "Cyclone",   -- Cyclone
	[113506] = "Cyclone",   -- Cyclone (Symbiosis)
	[605]    = "MindControl", -- Mind Control
	[13181]  = "MindControl", -- Gnomish Mind Control Cap
	[67799]  = "MindControl", -- Mind Amplification Dish (Item)
	[7922]   = "Charge",    -- Charge Stun

	-- *** Disorient Effects ***
	[99]     = "Disorient", -- Disorienting Roar
	[19503]  = "Disorient", -- Scatter Shot
	[31661]  = "Disorient", -- Dragon's Breath
	[123393] = "Disorient", -- Glyph of Breath of Fire
	[88625]  = "Disorient", -- Holy Word: Chastise


	-- Bonus cata ones
	-- *** Controlled Stun Effects ***
	[93433] = "Stun",     -- Burrow Attack (Worm)
	[83046] = "Stun",     -- Improved Polymorph (Rank 1)
	[83047] = "Stun",     -- Improved Polymorph (Rank 2)
	--[88625] = "Stun", -- Holy Word: Chastise
	[93986] = "Stun",     -- Aura of Foreboding
	[54786] = "Stun",     -- Demon Leap
	-- *** Non-controlled Stun Effects ***
	[85387] = "RandomStun", -- Aftermath

	-- *** Controlled Root Effects ***
	[96293] = "Root", -- Chains of Ice (Chilblains Rank 1)
	[87193] = "Root", -- Paralysis
	[55536] = "Root", -- Frostweave Net (Item)

	-- *** Non-controlled Root Effects ***
	[83301] = "RandomRoot", -- Improved Cone of Cold (Rank 1)
	[83302] = "RandomRoot", -- Improved Cone of Cold (Rank 2)
	[83073] = "RandomRoot", -- Shattered Barrier (Rank 2)

	[50479] = "Silence",  -- Nether Shock (Nether Ray)
	[86759] = "Silence",  -- Silenced - Improved Kick (Rank 2)
}