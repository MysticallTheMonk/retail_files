local E = select(2,	...):unpack()

E.spell_db = {
	["DRUID"] = {
		{ spellID = 16979,	duration = 15,	type = "interrupt",	spec = true	},
		{ spellID = 5211,	duration = 60,	type = "cc"	},
		{ spellID = 22812,	duration = 60,	type = "defensive"	},
		{ spellID = 22842,	duration = 180,	type = "defensive"	},
		{ spellID = 16689,	duration = 60,	type = "defensive",	spec = true	},
		{ spellID = 18562,	duration = 15,	type = "defensive",	spec = true	},
		{ spellID = 740,	duration = 300,	type = "raidDefensive"	},
		{ spellID = 16914,	duration = 60,	type = "offensive"	},
		{ spellID = 5209,	duration = 600,	type = "other"	},
		{ spellID = 8998,	duration = 10,	type = "other"	},
		{ spellID = 1850,	duration = 300,	type = "other"	},


		{ spellID = 6795,	duration = 10,	type = "other"	},
		{ spellID = 29166,	duration = 360,	type = "other"	},
		{ spellID = 17116,	duration = 180,	type = "other",	spec = true	},
		{ spellID = 5215,	duration = 10,	type = "other"	},
		{ spellID = 20484,	duration = 1800,	type = "other"	},
	},
	["HUNTER"] = {
		{ spellID = 19801,	duration = 20,	type = "dispel"	},
		{ spellID = 1499,	duration = 15,	type = "cc"	},
		{ spellID = 19577,	duration = 60,	type = "cc",	spec = true	},
		{ spellID = 1513,	duration = 30,	type = "cc"	},
		{ spellID = 19503,	duration = 30,	type = "cc",	spec = true	},
		{ spellID = 19386,	duration = 120,	type = "cc",	spec = true	},
		{ spellID = 19263,	duration = 300,	type = "defensive",	spec = true	},

		{ spellID = 23989,	duration = 300,	type = "defensive",	spec = true	},


		{ spellID = 19574,	duration = 120,	type = "offensive",	spec = true	},

		{ spellID = 13813,	duration = 15,	type = "offensive"	},
		{ spellID = 13795,	duration = 15,	type = "offensive"	},


		{ spellID = 3045,	duration = 300,	type = "offensive"	},

		{ spellID = 1510,	duration = 60,	type = "offensive"	},


		{ spellID = 20736,	duration = 8,	type = "other"	},
		{ spellID = 1543,	duration = 15,	type = "other"	},
		{ spellID = 13809,	duration = 15,	type = "other"	},












	},
	["MAGE"] = {
		{ spellID = 2139,	duration = 30,	type = "interrupt"	},
		{ spellID = 122,	duration = 25,	type = "disarm"	},
		{ spellID = 11958,	duration = 300,	type = "immunity",	spec = true	},
		{ spellID = 12472,	duration = 600,	type = "defensive",	spec = true	},
		{ spellID = 543,	duration = 30,	type = "defensive"	},
		{ spellID = 6143,	duration = 30,	type = "defensive"	},
		{ spellID = 11426,	duration = 30,	type = "defensive",	spec = true	},
		{ spellID = 12042,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 11113,	duration = 45,	type = "offensive",	spec = true	},
		{ spellID = 11129,	duration = 180,	type = "offensive",	spec = true	},

		{ spellID = 12043,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 1953,	duration = 15,	type = "other"	},
		{ spellID = 120,	duration = 10,	type = "other"	},
		{ spellID = 12051,	duration = 480,	type = "other"	},
	},
	["PALADIN"] = {
		{ spellID = 853,	duration = 60,	type = "cc"	},
		{ spellID = 20066,	duration = 60,	type = "cc",	spec = true	},
		{ spellID = 2878,	duration = 30,	type = "cc"	},
		{ spellID = 498,	duration = 300,	type = "immunity"	},
		{ spellID = 642,	duration = 300,	type = "immunity"	},
		{ spellID = 1022,	duration = 300,	type = "externalDefensive"	},
		{ spellID = 19752,	duration = 3600,	type = "externalDefensive"	},
		{ spellID = 20216,	duration = 120,	type = "defensive",	spec = true	},
		{ spellID = 20925,	duration = 10,	type = "defensive",	spec = true	},
		{ spellID = 633,	duration = 3600,type = "defensive"	},

		{ spellID = 879,	duration = 15,	type = "offensive"	},

		{ spellID = 20473,	duration = 30,	type = "offensive",	spec = true	},
		{ spellID = 2812,	duration = 60,	type = "offensive"	},
		{ spellID = 20271,	duration = 10,	type = "offensive"	},
		{ spellID = 1044,	duration = 20,	type = "other"	},
	},

	["PRIEST"] = {
		{ spellID = 8122,	duration = 30,	type = "cc"	},
		{ spellID = 15487,	duration = 45,	type = "disarm",	spec = true	},
		{ spellID = 13908,	duration = 600,	type = "defensive",	spec = {1,3}	},
		{ spellID = 2944,	duration = 180,	type = "defensive",	spec = {5}	},
		{ spellID = 2651,	duration = 300,	type = "defensive",	spec = {4}	},
		{ spellID = 13896,	duration = 180,	type = "defensive",	spec = {1}	},
		{ spellID = 724,	duration = 600,	type = "defensive",	spec = true	},

		{ spellID = 15286,	duration = 10,	type = "defensive",	spec = true	},
		{ spellID = 14751,	duration = 180,	type = "offensive",	spec = true	},

		{ spellID = 10060,	duration = 180,	type = "offensive",	spec = true	},

		{ spellID = 6346,	duration = 30,	type = "counterCC"	},
		{ spellID = 586,	duration = 30,	type = "other"	},
	},
	["ROGUE"] = {
		{ spellID = 1766,	duration = 10,	type = "interrupt"	},
		{ spellID = 2094,	duration = 300,	type = "cc"	},
		{ spellID = 1776,	duration = 10,	type = "cc"	},
		{ spellID = 408,	duration = 20,	type = "cc"	},

		{ spellID = 5277,	duration = 300,	type = "defensive"	},
		{ spellID = 14185,	duration = 600,	type = "defensive",	spec = true	},
		{ spellID = 1856,	duration = 300,	type = "defensive"	},
		{ spellID = 13750,	duration = 300,	type = "offensive",	spec = true	},
		{ spellID = 13877,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 14177,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 14278,	duration = 20,	type = "offensive",	spec = true	},
		{ spellID = 14183,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 1725,	duration = 30,	type = "other"	},
		{ spellID = 1966,	duration = 10,	type = "other"	},
		{ spellID = 2983,	duration = 300,	type = "other"	},
		{ spellID = 1784,	duration = 10,	type = "other"	},
	},
	["SHAMAN"] = {
		{ spellID = 8042,	duration = 6,	type = "interrupt"	},

		{ spellID = 1535,	duration = 15,	type = "offensive"	},

		{ spellID = 16166,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 17364,	duration = 20,	type = "offensive",	spec = true	},
		{ spellID = 8177,	duration = 15,	type = "counterCC"	},
		{ spellID = 2484,	duration = 15,	type = "other"	},

		{ spellID = 16190,	duration = 300,	type = "other",	spec = true	},
		{ spellID = 16188,	duration = 180,	type = "other",	spec = true	},
		{ spellID = 20608,	duration = 3600,	type = "other"	},
		{ spellID = 5730,	duration = 30,	type = "other"	},
	},
	["WARLOCK"] = {

		{ spellID = 19244,	duration = 24,	type = "interrupt"	},
		{ spellID = 19505,	duration = 8,	type = "dispel"	},
		{ spellID = 6789,	duration = 120,	type = "cc"	},
		{ spellID = 5484,	duration = 40,	type = "cc",	},
		{ spellID = 6229,	duration = 30,	type = "defensive"	},
		{ spellID = 18288,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 17962,	duration = 10,	type = "offensive",	spec = true	},
		{ spellID = 603,	duration = 60,	type = "offensive"	},
		{ spellID = 1122,	duration = 3600,	type = "offensive"	},
		{ spellID = 17877,	duration = 15,	type = "offensive",	spec = true	},
		{ spellID = 6353,	duration = 60,	type = "offensive"	},
		{ spellID = 18708,	duration = 900,	type = "other",	spec = true	},
		{ spellID = 20707,	duration = 1800,	type = "other",	buff = 0	},









	},
	["WARRIOR"] = {
		{ spellID = 6552,	duration = 10,	type = "interrupt"	},
		{ spellID = 72,	duration = 12,	type = "interrupt"	},
		{ spellID = 100,	duration = 15,	type = "cc"	},
		{ spellID = 12809,	duration = 45,	type = "cc",	spec = true	},
		{ spellID = 20252,	duration = 30,	type = "cc"	},
		{ spellID = 5246,	duration = 180,	type = "cc"	},
		{ spellID = 676,	duration = 60,	type = "disarm"	},
		{ spellID = 12975,	duration = 600,	type = "defensive",	spec = true	},

		{ spellID = 871,	duration = 1800,	type = "defensive"	},
		{ spellID = 2687,	duration = 60,	type = "offensive"	},

		{ spellID = 12292,	duration = 30,	type = "offensive",	spec = true	},


		{ spellID = 1719,	duration = 1800,	type = "offensive"	},
		{ spellID = 20230,	duration = 1800,	type = "offensive"	},


		{ spellID = 12328,	duration = 180,	type = "offensive",	spec = true	},

		{ spellID = 1680,	duration = 10,	type = "offensive"	},
		{ spellID = 18499,	duration = 30,	type = "counterCC"	},
		{ spellID = 1161,	duration = 600,	type = "other"	},
		{ spellID = 694,	duration = 120,	type = "other"	},
		{ spellID = 355,	duration = 10,	type = "other"	},
	},
	["PVPTRINKET"] = {
		{ spellID = 5579,	duration = 300,	type = "pvptrinket",	item = 18834	},
		{ spellID = 23274,	duration = 300,	type = "pvptrinket",	item = 18850	},
		{ spellID = 23276,	duration = 300,	type = "pvptrinket",	item = 18851	},
		{ spellID = 23273,	duration = 300,	type = "pvptrinket",	item = 18852	},
		{ spellID = 23277,	duration = 300,	type = "pvptrinket",	item = 18853	},
	},
	["RACIAL"] = {
		{ spellID = 26297,	duration = 180,	type = "racial",	race = 8	},
		{ spellID = 20572,	duration = 120,	type = "racial",	race = 2	},
		{ spellID = 20589,	duration = 105,	type = "racial",	race = 7	},
		{ spellID = 20600,	duration = 180,	type = "racial",	race = 1	},
		{ spellID = 20580,	duration = 10,	type = "racial",	race = 4	},
		{ spellID = 20594,	duration = 180,	type = "racial",	race = 3	},
		{ spellID = 20549,	duration = 90,	type = "racial",	race = 6	},
		{ spellID = 7744,	duration = 120,	type = "racial",	race = 5	},
	},
	["TRINKET"] = {
	},
}

E.buffFix = E.BLANK
E.buffFixNoCLEU = E.BLANK
E.summonedBuffDuration = E.BLANK

E.spellDefaults = {
	5579,
	28730,
	26297,
	28880,
	20594,
	20549,
	7744,

	16979,
	5211,
	22812,
	22842,
	740,
	33831,
	17116,

	1499,
	19577,
	19503,
	19386,

	19263,
	23989,
	19574,
	3045,

	2139,
	45438,
	11958,
	12042,
	11129,
	12472,
	12043,

	853,
	20066,
	642,
	1022,
	6940,
	19752,
	20216,
	633,
	31884,

	8122,
	44041,
	15487,
	33206,
	13908,
	2651,
	2944,
	13896,
	724,
	14751,
	10060,
	34433,
	6346,

	1766,
	2094,
	408,
	31224,
	5277,
	14185,
	1856,
	13750,
	13877,
	14177,
	14183,

	8042,
	30823,
	2825,
	16166,
	2894,
	8177,
	16188,

	19244,
	19505,
	6789,
	5484,
	30283,
	18288,
	1122,

	6552,
	72,
	12809,
	5246,
	676,
	12975,
	871,
	12292,
	1719,
	20230,
	18499,
	3411,
	23920,
}

E.interruptDefaults = {
	16979, 2139, 1766, 8042, 19244, 6552, 72,
}

E.raidDefaults = {
	740,
}
