sArenaMixin.drCategories = {
	"Incapacitate",
	"Disorient",
	"Stun",
	"RandomStun",
	"Fear",
	"Root",
	"RandomRoot",
	"MindControl",
	"Disarm",
	"Scatter",
	"Counterattack",
	"Chastise",
	"KidneyShot",
	"UnstableAffliction",
	"DeathCoil",
}

sArenaMixin.defaultSettings.profile.drCategories = {
	["Incapacitate"] = true,
	["Disorient"] = true,
	["Stun"] = true,
	["RandomStun"] = true,
	["Fear"] = true,
	["Root"] = true,
	["RandomRoot"] = true,
	["MindControl"] = true,
	["Disarm"] = true,
	["Scatter"] = true,
	["Counterattack"] = false,
	["Chastise"] = false,
	["KidneyShot"] = true,
	["UnstableAffliction"] = false,
	["DeathCoil"] = false,
}

sArenaMixin.defaultSettings.profile.drIcons = {
	["Incapacitate"] = 136071,
	["Disorient"] = 134153,
	["Stun"] = 132092,
	["RandomStun"] = 133477,
	["Fear"] = 136183,
	["Root"] = 135848,
	["RandomRoot"] = 135852,
	["MindControl"] = 136206,
	["Disarm"] = 132343,
	["Scatter"] = 132153,
	["Counterattack"] = 132336,
	["Chastise"] = 135886,
	["KidneyShot"] = 132298,
	["UnstableAffliction"] = 136228,
	["DeathCoil"] = 136145,
}

sArenaMixin.drList = {
	-- *** Incapacitate Effects ***
	[2637]  = "Incapacitate",     -- Hibernate (Rank 1)
	[18657] = "Incapacitate",     -- Hibernate (Rank 2)
	[18658] = "Incapacitate",     -- Hibernate (Rank 3)
	[22570] = "Incapacitate",     -- Maim
	[3355]  = "Incapacitate",     -- Freezing Trap Effect (Rank 1)
	[14308] = "Incapacitate",     -- Freezing Trap Effect (Rank 2)
	[14309] = "Incapacitate",     -- Freezing Trap Effect (Rank 3)
	[19386] = "Incapacitate",     -- Wyvern Sting (Rank 1)
	[24132] = "Incapacitate",     -- Wyvern Sting (Rank 2)
	[24133] = "Incapacitate",     -- Wyvern Sting (Rank 3)
	[27068] = "Incapacitate",     -- Wyvern Sting (Rank 4)
	[118]   = "Incapacitate",     -- Polymorph (Rank 1)
	[12824] = "Incapacitate",     -- Polymorph (Rank 2)
	[12825] = "Incapacitate",     -- Polymorph (Rank 3)
	[12826] = "Incapacitate",     -- Polymorph (Rank 4)
	[28271] = "Incapacitate",     -- Polymorph: Turtle
	[28272] = "Incapacitate",     -- Polymorph: Pig
	[20066] = "Incapacitate",     -- Repentance
	[6770]  = "Incapacitate",     -- Sap (Rank 1)
	[2070]  = "Incapacitate",     -- Sap (Rank 2)
	[11297] = "Incapacitate",     -- Sap (Rank 3)
	[1776]  = "Incapacitate",     -- Gouge (Rank 1)
	[1777]  = "Incapacitate",     -- Gouge (Rank 2)
	[8629]  = "Incapacitate",     -- Gouge (Rank 3)
	[11285] = "Incapacitate",     -- Gouge (Rank 4)
	[11286] = "Incapacitate",     -- Gouge (Rank 5)
	[38764] = "Incapacitate",     -- Gouge (Rank 6)
	[710]   = "Incapacitate",     -- Banish (Rank 1)
	[18647] = "Incapacitate",     -- Banish (Rank 2)
	[13327] = "Incapacitate",     -- Reckless Charge (Item)
	[4064]  = "Incapacitate",     -- Rough Copper Bomb (Item)
	[4065]  = "Incapacitate",     -- Large Copper Bomb (Item)
	[4066]  = "Incapacitate",     -- Small Bronze Bomb (Item)
	[4067]  = "Incapacitate",     -- Big Bronze Bomb (Item)
	[4068]  = "Incapacitate",     -- Iron Grenade (Item)
	[12421] = "Incapacitate",     -- Mithril Frag Bomb (Item)
	[4069]  = "Incapacitate",     -- Big Iron Bomb (Item)
	[12562] = "Incapacitate",     -- The Big One (Item)
	[12543] = "Incapacitate",     -- Hi-Explosive Bomb (Item)
	[19769] = "Incapacitate",     -- Thorium Grenade (Item)
	[19784] = "Incapacitate",     -- Dark Iron Bomb (Item)
	[30216] = "Incapacitate",     -- Fel Iron Bomb (Item)
	[30461] = "Incapacitate",     -- The Bigger One (Item)
	[30217] = "Incapacitate",     -- Adamantite Grenade (Item)

	-- *** Disorient Effects ***
	[33786] = "Disorient",     -- Cyclone
	[2094]  = "Disorient",     -- Blind

	-- *** Controlled Stun Effects ***
	[5211]  = "Stun",     -- Bash (Rank 1)
	[6798]  = "Stun",     -- Bash (Rank 2)
	[8983]  = "Stun",     -- Bash (Rank 3)
	[9005]  = "Stun",     -- Pounce (Rank 1)
	[9823]  = "Stun",     -- Pounce (Rank 2)
	[9827]  = "Stun",     -- Pounce (Rank 3)
	[27006] = "Stun",     -- Pounce (Rank 4)
	[24394] = "Stun",     -- Intimidation
	[853]   = "Stun",     -- Hammer of Justice (Rank 1)
	[5588]  = "Stun",     -- Hammer of Justice (Rank 2)
	[5589]  = "Stun",     -- Hammer of Justice (Rank 3)
	[10308] = "Stun",     -- Hammer of Justice (Rank 4)
	[1833]  = "Stun",     -- Cheap Shot
	[30283] = "Stun",     -- Shadowfury (Rank 1)
	[30413] = "Stun",     -- Shadowfury (Rank 2)
	[30414] = "Stun",     -- Shadowfury (Rank 3)
	[12809] = "Stun",     -- Concussion Blow
	[7922]  = "Stun",     -- Charge Stun
	[20253] = "Stun",     -- Intercept Stun (Rank 1)
	[20614] = "Stun",     -- Intercept Stun (Rank 2)
	[20615] = "Stun",     -- Intercept Stun (Rank 3)
	[25273] = "Stun",     -- Intercept Stun (Rank 4)
	[25274] = "Stun",     -- Intercept Stun (Rank 5)
	[20549] = "Stun",     -- War Stomp (Racial)
	[13237] = "Stun",     -- Goblin Mortar (Item)
	[835]   = "Stun",     -- Tidal Charm (Item)

	-- *** Non-Controlled Stun Effects ***
	[16922] = "RandomStun",       -- Celestial Focus (Starfire Stun)
	[19410] = "RandomStun",       -- Improved Concussive Shot
	[12355] = "RandomStun",       -- Impact
	[20170] = "RandomStun",       -- Seal of Justice Stun
	[15269] = "RandomStun",       -- Blackout
	[18093] = "RandomStun",       -- Pyroclasm
	[39796] = "RandomStun",       -- Stoneclaw Stun
	[12798] = "RandomStun",       -- Revenge Stun
	[5530]  = "RandomStun",       -- Mace Stun Effect (Mace Specialization)
	[15283] = "RandomStun",       -- Stunning Blow (Weapon Proc)
	[56]    = "RandomStun",       -- Stun (Weapon Proc)
	[34510] = "RandomStun",       -- Stormherald/Deep Thunder (Weapon Proc)

	-- *** Fear Effects ***
	[1513]  = "Fear",     -- Scare Beast (Rank 1)
	[14326] = "Fear",     -- Scare Beast (Rank 2)
	[14327] = "Fear",     -- Scare Beast (Rank 3)
	[10326] = "Fear",     -- Turn Evil
	[8122]  = "Fear",     -- Psychic Scream (Rank 1)
	[8124]  = "Fear",     -- Psychic Scream (Rank 2)
	[10888] = "Fear",     -- Psychic Scream (Rank 3)
	[10890] = "Fear",     -- Psychic Scream (Rank 4)
	[5782]  = "Fear",     -- Fear (Rank 1)
	[6213]  = "Fear",     -- Fear (Rank 2)
	[6215]  = "Fear",     -- Fear (Rank 3)
	[6358]  = "Fear",     -- Seduction (Succubus)
	[5484]  = "Fear",     -- Howl of Terror (Rank 1)
	[17928] = "Fear",     -- Howl of Terror (Rank 2)
	[5246]  = "Fear",     -- Intimidating Shout
	[5134]  = "Fear",     -- Flash Bomb Fear (Item)

	-- *** Controlled Root Effects ***
	[339]   = "Root",     -- Entangling Roots (Rank 1)
	[1062]  = "Root",     -- Entangling Roots (Rank 2)
	[5195]  = "Root",     -- Entangling Roots (Rank 3)
	[5196]  = "Root",     -- Entangling Roots (Rank 4)
	[9852]  = "Root",     -- Entangling Roots (Rank 5)
	[9853]  = "Root",     -- Entangling Roots (Rank 6)
	[26989] = "Root",     -- Entangling Roots (Rank 7)
	[19975] = "Root",     -- Nature's Grasp (Rank 1)
	[19974] = "Root",     -- Nature's Grasp (Rank 2)
	[19973] = "Root",     -- Nature's Grasp (Rank 3)
	[19972] = "Root",     -- Nature's Grasp (Rank 4)
	[19971] = "Root",     -- Nature's Grasp (Rank 5)
	[19970] = "Root",     -- Nature's Grasp (Rank 6)
	[27010] = "Root",     -- Nature's Grasp (Rank 7)
	[122]   = "Root",     -- Frost Nova (Rank 1)
	[865]   = "Root",     -- Frost Nova (Rank 2)
	[6131]  = "Root",     -- Frost Nova (Rank 3)
	[10230] = "Root",     -- Frost Nova (Rank 4)
	[27088] = "Root",     -- Frost Nova (Rank 5)
	[33395] = "Root",     -- Freeze (Water Elemental)
	[39965] = "Root",     -- Frost Grenade (Item)

	-- *** Non-controlled Root Effects ***
	[19185] = "RandomRoot",     -- Entrapment
	[19229] = "RandomRoot",     -- Improved Wing Clip
	[12494] = "RandomRoot",     -- Frostbite
	[23694] = "RandomRoot",     -- Improved Hamstring

	-- *** Mind Control Effects ***
	[605]   = "MindControl",     -- Mind Control (Rank 1)
	[10911] = "MindControl",     -- Mind Control (Rank 2)
	[10912] = "MindControl",     -- Mind Control (Rank 3)
	[13181] = "MindControl",     -- Gnomish Mind Control Cap (Item)

	-- *** Disarm Weapon Effects ***
	[14251] = "Disarm",     -- Riposte
	[34097] = "Disarm",     -- Riposte 2 (TODO: not sure which ID is correct)
	[676]   = "Disarm",     -- Disarm

	-- *** Scatter Effects ***
	[19503] = "Scatter",     -- Scatter Shot
	[31661] = "Scatter",     -- Dragon's Breath (Rank 1)
	[33041] = "Scatter",     -- Dragon's Breath (Rank 2)
	[33042] = "Scatter",     -- Dragon's Breath (Rank 3)
	[33043] = "Scatter",     -- Dragon's Breath (Rank 4)

	-- *** Spells that DRs with itself only ***
	[19306] = "Counterattack",          -- Counterattack (Rank 1)
	[20909] = "Counterattack",          -- Counterattack (Rank 2)
	[20910] = "Counterattack",          -- Counterattack (Rank 3)
	[27067] = "Counterattack",          -- Counterattack (Rank 4)
	[44041] = "Chastise",               -- Chastise (Rank 1)
	[44043] = "Chastise",               -- Chastise (Rank 2)
	[44044] = "Chastise",               -- Chastise (Rank 3)
	[44045] = "Chastise",               -- Chastise (Rank 4)
	[44046] = "Chastise",               -- Chastise (Rank 5)
	[44047] = "Chastise",               -- Chastise (Rank 6)
	[408]   = "KidneyShot",             -- Kidney Shot (Rank 1)
	[8643]  = "KidneyShot",             -- Kidney Shot (Rank 2)
	[43523] = "UnstableAffliction",     -- Unstable Affliction 1
	[31117] = "UnstableAffliction",     -- Unstable Affliction 2 (TODO: not sure which ID is correct)
	[6789]  = "DeathCoil",              -- Death Coil (Rank 1)
	[17925] = "DeathCoil",              -- Death Coil (Rank 2)
	[17926] = "DeathCoil",              -- Death Coil (Rank 3)
	[27223] = "DeathCoil",              -- Death Coil (Rank 4)
}