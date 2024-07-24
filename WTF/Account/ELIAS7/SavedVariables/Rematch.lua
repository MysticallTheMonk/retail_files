
RematchSaved = {
	[150922] = {
		{
			"random:0", -- [1]
		}, -- [1]
		{
			"BattlePet-0-000014DD5C57", -- [1]
			626, -- [2]
			919, -- [3]
			706, -- [4]
			2648, -- [5]
		}, -- [2]
		{
			"random:0", -- [1]
		}, -- [3]
		["teamName"] = "Sludge Belcher",
		["notes"] = "Attack once if you can with first pet - you'll get swapped out\nBlack Claw\nSwarm",
	},
	[150911] = {
		{
			"BattlePet-0-000014DD5B22", -- [1]
			119, -- [2]
			155, -- [3]
			706, -- [4]
			556, -- [5]
		}, -- [1]
		{
			"random:5", -- [1]
		}, -- [2]
		{
			"random:2", -- [1]
		}, -- [3]
		["teamName"] = "Crypt Fiend",
		["notes"] = "Scratch x4-5",
	},
	[155267] = {
		{
			"BattlePet-0-000014DD5AC9", -- [1]
			119, -- [2]
			155, -- [3]
			706, -- [4]
			393, -- [5]
		}, -- [1]
		{
			"random:5", -- [1]
		}, -- [2]
		{
			"random:2", -- [1]
		}, -- [3]
		["teamName"] = "Risen Guard",
		["notes"] = "Scratch x3-4\nFinish off secondary pets",
	},
	[150923] = {
		{
			"BattlePet-0-000014DD58D5", -- [1]
			115, -- [2]
			611, -- [3]
			612, -- [4]
			1167, -- [5]
		}, -- [1]
		{
			"random:5", -- [1]
		}, -- [2]
		{
			"random:2", -- [1]
		}, -- [3]
		["teamName"] = "Belchling",
		["notes"] = "1. Breathx3-4\n2. Defeat secondary pets",
	},
	[150925] = {
		{
			"BattlePet-0-000014DD59B4", -- [1]
			122, -- [2]
			763, -- [3]
			592, -- [4]
			1165, -- [5]
		}, -- [1]
		{
			"BattlePet-0-000014DD5BA5", -- [1]
			122, -- [2]
			764, -- [3]
			1960, -- [4]
			2081, -- [5]
		}, -- [2]
		{
			"random:2", -- [1]
		}, -- [3]
		["teamName"] = "Liz the Tormentor",
		["notes"] = "Tail Sweep until your Dragonkin dies\n Bring in Twilight Clutch-Sister\n Tail Sweep (make sure Dragonkin is activated)\n Twilight Meteorite\n Tail Sweep",
	},
	[150917] = {
		{
			"random:0", -- [1]
		}, -- [1]
		{
			"BattlePet-0-000014DD5869", -- [1]
			119, -- [2]
			155, -- [3]
			706, -- [4]
			468, -- [5]
		}, -- [2]
		{
			"random:0", -- [1]
		}, -- [3]
		["teamName"] = "Huncher",
		["notes"] = "Put random pet in first slot\n Attack/pass, Scratch pet will be swapped in\n Scratch as much as you can, use other pets to finish it off",
	},
	[150914] = {
		{
			"BattlePet-0-000014DD5B90", -- [1]
			119, -- [2]
			360, -- [3]
			163, -- [4]
			417, -- [5]
		}, -- [1]
		{
			"random:5", -- [1]
		}, -- [2]
		{
			"random:2", -- [1]
		}, -- [3]
		["teamName"] = "Wandering Phantasm",
		["notes"] = "Scratch\n",
	},
	["Plagued Critters"] = {
		{
			"BattlePet-0-000014DD58AE", -- [1]
			356, -- [2]
			511, -- [3]
			310, -- [4]
			746, -- [5]
		}, -- [1]
		{
			"random:8", -- [1]
		}, -- [2]
		{
			"random:0", -- [1]
		}, -- [3]
		["notes"] = "Ensure Renewing Mists and Shell Shield are always active\nSnap in between keeping up both",
	},
	[150858] = {
		{
			"BattlePet-0-000014DD591A", -- [1]
			1002, -- [2]
			392, -- [3]
			985, -- [4]
			1320, -- [5]
		}, -- [1]
		{
			"BattlePet-0-000014DD5880", -- [1]
			360, -- [2]
			312, -- [3]
			159, -- [4]
			448, -- [5]
		}, -- [2]
		{
			"random:0", -- [1]
		}, -- [3]
		["teamName"] = "Blackmane",
		["notes"] = "Against Form 1\n\n Extra Plating\n Make it Rain\n Inflation\n Make it Rain\n\nAgainst Form 2\n\n Inflation- bling dies\n Bring in Hare/Rabbit\n Flurry x2",
	},
	[150918] = {
		{
			"BattlePet-0-000014DD5866", -- [1]
			119, -- [2]
			155, -- [3]
			706, -- [4]
			406, -- [5]
		}, -- [1]
		{
			"BattlePet-0-000014DD5A52", -- [1]
			119, -- [2]
			162, -- [3]
			163, -- [4]
			487, -- [5]
		}, -- [2]
		{
			"random:0", -- [1]
		}, -- [3]
		["teamName"] = "Tommy the Cruel",
		["notes"] = "Swarm - your pet will die\nScratch x3",
	},
	[150929] = {
		{
			"BattlePet-0-000014DD5C57", -- [1]
			626, -- [2]
			919, -- [3]
			706, -- [4]
			2648, -- [5]
		}, -- [1]
		{
			"random:0", -- [1]
		}, -- [2]
		{
			"random:0", -- [1]
		}, -- [3]
		["teamName"] = "Nefarious Terry",
		["notes"] = "Black Claw\nSwarm",
	},
}
RematchSettings = {
	["ScriptFilters"] = {
		{
			"Unnamed Pets", -- [1]
			"-- Collected pets that still have their original name.\n\nreturn owned and not customName", -- [2]
		}, -- [1]
		{
			"Partially Leveled", -- [1]
			"-- Pets that have earned some xp in battle.\n\nreturn xp and xp>0", -- [2]
		}, -- [2]
		{
			"Unique Abilities", -- [1]
			"-- Pets with abilities not shared by other pets.\n\nif not count then\n  -- create count of each ability per species\n  count = {}\n  for speciesID in AllSpeciesIDs() do\n    for abilityID in AllAbilities(speciesID) do\n      if not count[abilityID] then\n        count[abilityID] = 0\n      end\n      count[abilityID] = count[abilityID] + 1\n    end\n  end\nend\n\nfor _,abilityID in ipairs(abilityList) do\n  if count[abilityID]==1 then\n    return true\n  end\nend", -- [2]
		}, -- [3]
		{
			"Pets Without Rares", -- [1]
			"-- Collected battle pets that have no rare version.\n\nif not rares then\n  rares = {}\n  for petID in AllPetIDs() do\n    if select(5,C_PetJournal.GetPetStats(petID))==4 then\n      rares[C_PetJournal.GetPetInfoByPetID(petID)]=true\n    end\n  end\nend\n\nif canBattle and owned and not rares[speciesID] then\n  return true\nend", -- [2]
		}, -- [4]
		{
			"Hybrid Counters", -- [1]
			"-- Pets with three or more attack types different than their pet type.\n\nlocal count = 0\nfor _,abilityID in ipairs(abilityList) do\n  local abilityType,noHints = select(7, C_PetBattles.GetAbilityInfoByID(abilityID) )\n  if not noHints and abilityType~=petType then\n    count = count + 1\n  end\nend\n\nreturn count>=3\n", -- [2]
		}, -- [5]
	},
	["QueueSortOrder"] = 1,
	["XPos"] = 675,
	["JournalPanel"] = 1,
	["loadedTeam"] = 150925,
	["QueueSanctuary"] = {
	},
	["Sort"] = {
		["Order"] = 2,
		["FavoritesFirst"] = true,
	},
	["AllowHiddenPetsDefaulted"] = true,
	["BackupCount"] = 0,
	["TeamGroups"] = {
		{
			"General", -- [1]
			"Interface\\Icons\\PetJournalPortrait", -- [2]
		}, -- [1]
		{
			"Best Team", -- [1]
			"Interface\\Icons\\PetJournalPortrait", -- [2]
		}, -- [2]
	},
	["CustomScaleValue"] = 100,
	["Filters"] = {
		["Other"] = {
		},
		["Expansion"] = {
		},
		["Script"] = {
		},
		["Types"] = {
		},
		["Favorite"] = {
		},
		["Collected"] = {
		},
		["Strong"] = {
		},
		["Similar"] = {
		},
		["Breed"] = {
		},
		["Rarity"] = {
		},
		["Sources"] = {
		},
		["Level"] = {
		},
		["Tough"] = {
		},
		["Moveset"] = {
		},
	},
	["ExpandedOptHeaders"] = {
	},
	["YPos"] = 237.9999389648438,
	["FavoriteFilters"] = {
	},
	["CollapsedOptHeaders"] = {
	},
	["ExpandedTargetHeaders"] = {
	},
	["PreferredMode"] = 1,
	["ActivePanel"] = 1,
	["Sanctuary"] = {
		["BattlePet-0-000014DD58D5"] = {
			1, -- [1]
			true, -- [2]
			1167, -- [3]
			25, -- [4]
			1465, -- [5]
			305, -- [6]
			257, -- [7]
			4, -- [8]
		},
		["BattlePet-0-000014DD5B22"] = {
			1, -- [1]
			true, -- [2]
			556, -- [3]
			22, -- [4]
			1116, -- [5]
			206, -- [6]
			215, -- [7]
			2, -- [8]
		},
		["BattlePet-0-000014DD5866"] = {
			1, -- [1]
			true, -- [2]
			406, -- [3]
			15, -- [4]
			805, -- [5]
			113, -- [6]
			134, -- [7]
			1, -- [8]
		},
		["BattlePet-0-000014DD59B4"] = {
			1, -- [1]
			true, -- [2]
			1165, -- [3]
			25, -- [4]
			1400, -- [5]
			305, -- [6]
			273, -- [7]
			4, -- [8]
		},
		["random:8"] = {
			1, -- [1]
		},
		["BattlePet-0-000014DD5C57"] = {
			2, -- [1]
			true, -- [2]
			2648, -- [3]
			25, -- [4]
			1343, -- [5]
			288, -- [6]
			299, -- [7]
			4, -- [8]
		},
		["BattlePet-0-000014DD5880"] = {
			1, -- [1]
			true, -- [2]
			448, -- [3]
			12, -- [4]
			610, -- [5]
			90, -- [6]
			114, -- [7]
			1, -- [8]
		},
		["BattlePet-0-000014DD5BA5"] = {
			1, -- [1]
			true, -- [2]
			2081, -- [3]
			1, -- [4]
			152, -- [5]
			12, -- [6]
			12, -- [7]
			4, -- [8]
		},
		["BattlePet-0-000014DD5B90"] = {
			1, -- [1]
			true, -- [2]
			417, -- [3]
			8, -- [4]
			537, -- [5]
			82, -- [6]
			98, -- [7]
			4, -- [8]
		},
		["BattlePet-0-000014DD58AE"] = {
			1, -- [1]
			true, -- [2]
			746, -- [3]
			25, -- [4]
			1806, -- [5]
			292, -- [6]
			211, -- [7]
			4, -- [8]
		},
		["random:5"] = {
			4, -- [1]
		},
		["BattlePet-0-000014DD591A"] = {
			1, -- [1]
			true, -- [2]
			1320, -- [3]
			4, -- [4]
			308, -- [5]
			42, -- [6]
			52, -- [7]
			4, -- [8]
		},
		["random:2"] = {
			5, -- [1]
		},
		["BattlePet-0-000014DD5AC9"] = {
			1, -- [1]
			true, -- [2]
			393, -- [3]
			25, -- [4]
			1546, -- [5]
			240, -- [6]
			305, -- [7]
			4, -- [8]
		},
		["random:0"] = {
			9, -- [1]
		},
		["BattlePet-0-000014DD5869"] = {
			1, -- [1]
			true, -- [2]
			468, -- [3]
			1, -- [4]
			152, -- [5]
			9, -- [6]
			9, -- [7]
			2, -- [8]
		},
		["BattlePet-0-000014DD5A52"] = {
			1, -- [1]
			true, -- [2]
			487, -- [3]
			16, -- [4]
			740, -- [5]
			128, -- [6]
			160, -- [7]
			1, -- [8]
		},
	},
	["SpecialSlots"] = {
	},
	["CornerPos"] = "BOTTOMLEFT",
	["LevelingQueue"] = {
	},
	["JournalUsed"] = true,
	["UseTypeBar"] = false,
	["SelectedTab"] = 2,
	["PetNotes"] = {
	},
}
