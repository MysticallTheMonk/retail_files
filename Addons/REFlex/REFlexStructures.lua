local _, RE = ...
local L = LibStub("AceLocale-3.0"):GetLocale("REFlex")

local GetRealZoneText = GetRealZoneText
local GetClassInfo = GetClassInfo
local GetNumSpecializationsForClassID = GetNumSpecializationsForClassID
local GetSpecializationInfoForClassID = GetSpecializationInfoForClassID
local ReloadUI = ReloadUI

RE.DefaultConfig = {
	["MiniMapButtonSettings"] = {["hide"] = false},
	["ShowServerName"] = false,
	["CurrentTab"] = 1,
	["Filters"] = {["Spec"] = ALL, ["Map"] = 1, ["Bracket"] = 1, ["Date"] = {0, 0}, ["Season"] = 0, ["DateMode"] = 1},
	["FirstTime"] = true,
	["LDBMode"] = 3,
	["LDBSide"] = "A",
	["ArenaStatsLimit"] = 3,
	["ForceCivilisedClock"] = false,
	["ConfigVersion"] = RE.Version
}

RE.MapList = {
	[30] = GetRealZoneText(30),
	[2107] = GetRealZoneText(2107),
	[1191] = GetRealZoneText(1191),
	[1691] = GetRealZoneText(1691),
	[2245] = GetRealZoneText(2245),
	[1105] = GetRealZoneText(1105),
	[566] = GetRealZoneText(566),
	[968] = GetRealZoneText(566),
	[628] = GetRealZoneText(628),
	[727] = GetRealZoneText(727),
	[607] = GetRealZoneText(607),
	[1035] = GetRealZoneText(1035),
	[761] = GetRealZoneText(761),
	[726] = GetRealZoneText(726),
	[2106] = GetRealZoneText(2106),
	[1280] = GetRealZoneText(1280),
	[1803] = GetRealZoneText(1803),
	[2118] = GetRealZoneText(2118),
	[2656] = GetRealZoneText(2656),
	[1552] = RE:GetShortMapName(GetRealZoneText(1552)),
	[1504] = RE:GetShortMapName(GetRealZoneText(1504)),
	[562] = RE:GetShortMapName(GetRealZoneText(1672)),
	[1672] = RE:GetShortMapName(GetRealZoneText(1672)),
	[2547] = RE:GetShortMapName(GetRealZoneText(2547)),
	[2373] = RE:GetShortMapName(GetRealZoneText(2373)),
	[617] = RE:GetShortMapName(GetRealZoneText(617)),
	[559] = RE:GetShortMapName(GetRealZoneText(1505)),
	[1505] = RE:GetShortMapName(GetRealZoneText(1505)),
	[572] = RE:GetShortMapName(GetRealZoneText(572)),
	[1134] = RE:GetShortMapName(GetRealZoneText(1134)),
	[980] = RE:GetShortMapName(GetRealZoneText(980)),
	[1911] = RE:GetShortMapName(GetRealZoneText(1911)),
	[1825] = RE:GetShortMapName(GetRealZoneText(1825)),
	[2167] = RE:GetShortMapName(GetRealZoneText(2167)),
	[2509] = RE:GetShortMapName(GetRealZoneText(2509)),
	[2563] = RE:GetShortMapName(GetRealZoneText(2563)),
	[2759] = RE:GetShortMapName(GetRealZoneText(2759))
}

RE.MapListLongBG = {
	[1] = ALL,
	[30] = GetRealZoneText(30),
	[2107] = GetRealZoneText(2107),
	[1191] = GetRealZoneText(1191),
	[1691] = GetRealZoneText(1691),
	[2245] = GetRealZoneText(2245),
	[2656] = GetRealZoneText(2656),
	[1105] = GetRealZoneText(1105),
	[566] = GetRealZoneText(566),
	[628] = GetRealZoneText(628),
	[1803] = GetRealZoneText(1803),
	[727] = GetRealZoneText(727),
	[607] = GetRealZoneText(607),
	[1280] = GetRealZoneText(1280),
	[1035] = GetRealZoneText(1035),
	[761] = GetRealZoneText(761),
	[726] = GetRealZoneText(726),
	[2106] = GetRealZoneText(2106),
	[2118] = GetRealZoneText(2118)
}

RE.MapListLongArena = {
	[1] = ALL,
	[1552] = GetRealZoneText(1552),
	[1504] = GetRealZoneText(1504),
	[1672] = GetRealZoneText(1672),
	[617] = GetRealZoneText(617),
	[2547] = GetRealZoneText(2547),
	[2373] = GetRealZoneText(2373),
	[1505] = GetRealZoneText(1505),
	[572] = GetRealZoneText(572),
	[1134] = GetRealZoneText(1134),
	[980] = GetRealZoneText(980),
	[1911] = GetRealZoneText(1911),
	[1825] = GetRealZoneText(1825),
	[2167] = GetRealZoneText(2167),
	[2509] = GetRealZoneText(2509),
	[2563] = GetRealZoneText(2563),
	[2759] = GetRealZoneText(2759)
}

RE.MapListLongOrderBG = {
	1, 30, 2107, 1191, 2118, 1691, 2656, 2245, 1105, 566, 628, 1803, 727, 1280, 607, 1035, 761, 726, 2106
}

RE.MapListLongOrderArena = {
	1, 1552, 1504, 1672, 2759, 617, 2547, 2373, 1825, 2509, 1911, 1505, 2563, 1134, 2167, 980, 572
}

RE.MapListStat = {
	[2106] = {true, "Interface\\WorldStateFrame\\ColumnIcon-FlagCapture", "Interface\\WorldStateFrame\\ColumnIcon-FlagReturn"},
	[726] = {true, "Interface\\WorldStateFrame\\ColumnIcon-FlagCapture", "Interface\\WorldStateFrame\\ColumnIcon-FlagReturn"},
	[2107] = {true, "Interface\\WorldStateFrame\\ColumnIcon-TowerCapture", "Interface\\WorldStateFrame\\ColumnIcon-TowerDefend"},
	[566] = {false, "Interface\\WorldStateFrame\\ColumnIcon-FlagCapture2"},
	[567] = {true, "Interface\\WorldStateFrame\\ColumnIcon-TowerCapture", "Interface\\WorldStateFrame\\ColumnIcon-TowerDefend", "Interface\\WorldStateFrame\\ColumnIcon-FlagCapture2"},
	[761] = {true, "Interface\\WorldStateFrame\\ColumnIcon-TowerCapture", "Interface\\WorldStateFrame\\ColumnIcon-TowerDefend"},
	[1035] = {false, "Interface\\WorldStateFrame\\ColumnIcon-FlagCapture2", "Interface\\GroupFrame\\UI-Group-MasterLooter"},
	[2245] = {true, "Interface\\WorldStateFrame\\ColumnIcon-TowerCapture", "Interface\\WorldStateFrame\\ColumnIcon-TowerDefend"},
	[1105] = {true, "Interface\\WorldStateFrame\\ColumnIcon-FlagCapture", "Interface\\WorldStateFrame\\ColumnIcon-FlagReturn", "Interface\\WorldStateFrame\\ColumnIcon-TowerCapture", "Interface\\WorldStateFrame\\ColumnIcon-TowerDefend"},
	[727] = {false, "Interface\\MINIMAP\\Vehicle-SilvershardMines-MineCart"},
	[30] = {true, "Interface\\WorldStateFrame\\ColumnIcon-GraveyardCapture", "Interface\\WorldStateFrame\\ColumnIcon-GraveyardDefend", "Interface\\WorldStateFrame\\ColumnIcon-TowerCapture", "Interface\\WorldStateFrame\\ColumnIcon-TowerDefend"},
	[628] = {true, "Interface\\WorldStateFrame\\ColumnIcon-TowerCapture", "Interface\\WorldStateFrame\\ColumnIcon-TowerDefend"},
	[607] = {false, "Interface\\MINIMAP\\Vehicle-AllianceCart", "Interface\\MINIMAP\\Suramar_Door_Icon"},
	[1803] = {false, "Interface\\WorldStateFrame\\ColumnIcon-FlagCapture2"},
	[1691] = {false, "Interface\\WorldStateFrame\\ColumnIcon-FlagCapture2"},
	[1191] = {false, "Interface\\WorldStateFrame\\ColumnIcon-FlagCapture2"},
	[2656] = {false, "Interface\\MINIMAP\\Vehicle-AllianceCart", "Interface\\MINIMAP\\Suramar_Door_Icon"}
}

RE.RaceIcons = {
	["Human"]	= "raceicon128-human-male",
	["Humans"]	= "raceicon128-human-male",
	["Dwarf"]	= "raceicon128-dwarf-male",
	["Dwarves"]	= "raceicon128-dwarf-male",
	["Gnome"]	= "raceicon128-gnome-male",
	["Gnomes"]	= "raceicon128-gnome-male",
	["Night Elf"]	= "raceicon128-nightelf-male",
	["Night elves"]	= "raceicon128-nightelf-male",
	["Tauren"]	= "raceicon128-tauren-male",
	["Undead"]	= "raceicon128-undead-male",
	["Troll"]	= "raceicon128-troll-male",
	["Trolls"]	= "raceicon128-troll-male",
	["Orc"]	= "raceicon128-orc-male",
	["Orcs"]	= "raceicon128-orc-male",
	["Blood Elf"]	= "raceicon128-bloodelf-male",
	["Blood elves"]	= "raceicon128-bloodelf-male",
	["Draenei"]	= "raceicon128-draenei-male",
	["Goblin"]	= "raceicon128-goblin-male",
	["Goblins"]	= "raceicon128-goblin-male",
	["Worgen"]	= "raceicon128-worgen-male",
	["Pandaren"]	= "raceicon128-pandaren-male",
	["Nightborne"]	= "raceicon128-nightborne-male",
	["Highmountain Tauren"]	= "raceicon128-highmountain-male",
	["Void Elf"]	= "raceicon128-voidelf-male",
	["Void elves"]	= "raceicon128-voidelf-male",
	["Lightforged Draenei"]	= "raceicon128-lightforged-male",
	["Dark Iron Dwarf"]	= "raceicon128-darkirondwarf-male",
	["Dark Iron Dwarves"]	= "raceicon128-darkirondwarf-male",
	["Mag'har Orc"]	= "raceicon128-magharorc-male",
	["Zandalari Troll"]	= "raceicon128-zandalari-male",
	["Zandalari Trolls"]	= "raceicon128-zandalari-male",
	["Kul Tiran"]	= "raceicon128-kultiran-male",
	["Vulpera"]	= "raceicon128-vulpera-male",
	["Vulperas"]	= "raceicon128-vulpera-male",
	["Mechagnome"]	= "raceicon128-mechagnome-male",
	["Mechagnomes"]	= "raceicon128-mechagnome-male",
	["Dracthyr"]	= "raceicon128-dracthyr-male",
	["Dracthyrs"]	= "raceicon128-dracthyr-male",
	["Earthen"]	= "raceicon128-earthen-male",
	["Earthens"]	= "raceicon128-earthen-male"
}

RE.BracketNames = {
	ARENA_2V2,
	ARENA_3V3,
	"",
	BATTLEGROUND_10V10,
	"",
	"",
	SOLO
}

RE.MapIDRemap = {
	[968] = 566,
	[998] = 1035,
	[1681] = 2107,
	[2197] = 30
}

RE.Roles = {}
for classID=1, MAX_CLASSES do
	local _, classTag = GetClassInfo(classID)
	local specNum = GetNumSpecializationsForClassID(classID)
	RE.Roles[classTag] = {}
	for i=1, specNum do
		local _, name, _, _, role = GetSpecializationInfoForClassID(classID, i)
		RE.Roles[classTag][name] = role
	end
end

RE.AceConfig = {
	type = "group",
	args = {
		minimap = {
			name = L["Hide minimap button"],
			type = "toggle",
			width = "full",
			order = 1,
			set = function(_, val) RE.Settings.MiniMapButtonSettings.hide = val; RE:UpdateConfig() end,
			get = function(_) return RE.Settings.MiniMapButtonSettings.hide end
		},
		servername = {
			name = L["Display server names"],
			desc = L["Show player server name in match detail tooltip."],
			type = "toggle",
			width = "full",
			order = 2,
			set = function(_, val) RE.Settings.ShowServerName = val end,
			get = function(_) return RE.Settings.ShowServerName end
		},
		civilisedclock = {
			name = L["Force 24-hour time format"],
			desc = L["Display 24-hour timestamps even if US realm is detected."],
			type = "toggle",
			width = "full",
			order = 3,
			set = function(_, val) RE.Settings.ForceCivilisedClock = val end,
			get = function(_) return RE.Settings.ForceCivilisedClock end
		},
		arenalimit = {
			name = L["Arena composition statistics limit"],
			desc = L["A minimal number of matches required to be included in arena team composition statistics."],
			type = "range",
			width = "double",
			order = 4,
			min = 1,
			max = 10,
			step = 1,
			set = function(_, val) RE.Settings.ArenaStatsLimit = val end,
			get = function(_) return RE.Settings.ArenaStatsLimit end
		},
		ldbmode = {
			name = L["LDB feed display mode"],
			desc = L["Rating display always compares the values with the previous week."],
			type = "select",
			width = "double",
			order = 5,
			values = {
				[1] = L["Current session"],
				[2] = HONOR_TODAY,
				[3] = GUILD_CHALLENGES_THIS_WEEK
			},
			set = function(_, val) RE.Settings.LDBMode = val; RE.LDBUpdate = true; RE:UpdateLDBTime(); RE:UpdateLDB() end,
			get = function(_) return RE.Settings.LDBMode end
		},
		deletebase = {
			name = L["Purge database"],
			desc = L["WARNING! This operation is not reversible!"],
			type = "execute",
			width = "double",
			confirm = true,
			order = 6,
			func = function() REFlexDatabase = {}; REFlexHonorDatabase = {}; ReloadUI() end
		},
		deleteoldseason = {
			name = L["Purge previous seasons"],
			desc = L["WARNING! This operation is not reversible!"],
			type = "execute",
			width = "double",
			confirm = true,
			order = 7,
			func = function() RE:SeasonPurge(); ReloadUI() end
		}
	}
}

RE.BGStructure = {
	{
		["name"] = L["Date"],
		["width"] = 110,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Time", 0) end,
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = BATTLEGROUND,
		["width"] = 130,
		["color"] = RE.GetMapColor,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Map", 0) end,
		["align"] = "CENTER"
	},
	{
		["name"] = AUCTION_DURATION,
		["width"] = 70,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Duration", 0) end,
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = WIN,
		["width"] = 50,
		["align"] = "CENTER"
	},
	{
		["name"] = "KB",
		["width"] = 50,
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = "HK",
		["width"] = 50,
		["align"] = "CENTER"
	},
	{
		["name"] = DAMAGE,
		["width"] = 65,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Damage", 12) end,
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = SHOW_COMBAT_HEALING,
		["width"] = 65,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Healing", 13) end,
		["align"] = "CENTER"
	},
	{
		["name"] = HONOR,
		["width"] = 65,
		["color"] = {
			["r"] = 0.80,
			["g"] = 0.60,
			["b"] = 0,
			["a"] = 1.0
		},
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = RATING,
		["width"] = 65,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Rating", 15) end,
		["align"] = "CENTER"
	}
}

RE.ArenaStructure = {
	{
		["name"] = L["Date"],
		["width"] = 110,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Time", 0) end,
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = ARENA,
		["width"] = 60,
		["color"] = RE.GetMapColorArena,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Map", 0) end,
		["align"] = "CENTER"
	},
	{
		["name"] = TEAM,
		["width"] = 100,
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = "MMR",
		["width"] = 50,
		["align"] = "CENTER"
	},
	{
		["name"] = ENEMY,
		["width"] = 100,
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = "MMR",
		["width"] = 50,
		["align"] = "CENTER"
	},
	{
		["name"] = AUCTION_DURATION,
		["width"] = 60,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Duration", 0) end,
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = DAMAGE,
		["width"] = 70,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Damage", 12) end,
		["align"] = "CENTER"
	},
	{
		["name"] = SHOW_COMBAT_HEALING,
		["width"] = 70,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Healing", 13) end,
		["bgcolor"] = {
			["r"] = 0.15,
			["g"] = 0.15,
			["b"] = 0.15,
			["a"] = 1.0
		},
		["align"] = "CENTER"
	},
	{
		["name"] = RATING,
		["width"] = 50,
		["comparesort"] = function (self, rowa, rowb, sortbycol) return RE:CustomSort(self, rowa, rowb, sortbycol, "Rating", 15) end,
		["align"] = "CENTER"
	}
}
