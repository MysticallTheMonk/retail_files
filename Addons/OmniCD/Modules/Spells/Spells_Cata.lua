local E = select(2,	...):unpack()

E.spell_db = {
	["DEATHKNIGHT"] = {
		{ spellID = 47528,	duration = 10,	type = "interrupt",	rlvl = 57	},
		{ spellID = 49203,	duration = 60,	type = "cc",	spec = true	},
		{ spellID = 47476,	duration = 120,	type = "disarm",	rlvl = 59	},
		{ spellID = 49576,	duration = 35,	type = "disarm",	rlvl = 55	},
		{ spellID = 48707,	duration = 45,	type = "defensive",	rlvl = 68	},
		{ spellID = 49222,	duration = 60,	type = "defensive",	spec = true	},
		{ spellID = 49028,	duration = 90,	type = "defensive",	spec = true	},
		{ spellID = 48743,	duration = 120,	type = "defensive",	rlvl = 66	},
		{ spellID = 48792,	duration = 180,	type = "defensive",	rlvl = 62	},
		{ spellID = 48982,	duration = 30,	type = "defensive",	spec = true	},
		{ spellID = 55233,	duration = 60,	type = "defensive",	spec = true	},
		{ spellID = 51052,	duration = 120,	type = "raidDefensive",	spec = true	},
		{ spellID = 42650,	duration = 600,	type = "offensive",	rlvl = 80	},

		{ spellID = 43265,	duration = 30,	type = "offensive",	rlvl = 60	},
		{ spellID = 47568,	duration = 300,	type = "offensive",	rlvl = 75	},
		{ spellID = 57330,	duration = 20,	type = "offensive",	rlvl = 65	},

		{ spellID = 77575,	duration = {[1]=30,default=60},	type = "offensive",	rlvl = 81	},
		{ spellID = 51271,	duration = 60,	type = "offensive",	spec = true	},
		{ spellID = 61999,	duration = 600,	type = "offensive",	rlvl = 72	},
		{ spellID = 46584,	duration = 180,	type = "offensive",	rlvl = 56	},
		{ spellID = 49016,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 49206,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 49039,	duration = 120,	type = "counterCC",	spec = true	},
		{ spellID = 45529,	duration = 60,	type = "other",	rlvl = 64	},
		{ spellID = 56222,	duration = 8,	type = "other",	rlvl = 65	},
		{ spellID = 77606,	duration = 60,	type = "other",	rlvl = 85	},
	},
	["DRUID"] = {
		{ spellID = 80964,	duration = 60,	type = "interrupt",	rlvl = 22	},
		{ spellID = 78675,	duration = 60,	type = "interrupt",	spec = true	},
		{ spellID = 5211,	duration = 60,	type = "cc",	rlvl = 32	},
		{ spellID = 22570,	duration = 10,	type = "cc",	rlvl = 62	},
		{ spellID = 16979,	duration = 15,	type = "disarm",	spec = 49377	},
		{ spellID = 49376,	duration = 30,	type = "disarm",	spec = 49377	},
		{ spellID = 50516,	duration = 20,	type = "disarm",	spec = true	},
		{ spellID = 22812,	duration = 60,	type = "defensive",	rlvl = 58	},
		{ spellID = 22842,	duration = 180,	type = "defensive",	rlvl = 52	},
		{ spellID = 16689,	duration = 60,	type = "defensive",	rlvl = 52	},
		{ spellID = 61336,	duration = 180,	type = "defensive",	spec = true	},
		{ spellID = 18562,	duration = 15,	type = "defensive",	spec = 3	},
		{ spellID = 467,	duration = 45,	type = "defensive",	rlvl = 5	},
		{ spellID = 33891,	duration = 180,	type = "defensive",	spec = true	},

		{ spellID = 740,	duration = 480,	type = "raidDefensive",	rlvl = 68	},
		{ spellID = 50334,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 33831,	duration = 180,	type = "offensive",	spec = true	},

		{ spellID = 48505,	duration = 90,	type = "offensive",	spec = true	},
		{ spellID = 78674,	duration = 15,	type = "offensive",	spec = 1	},
		{ spellID = 5217,	duration = 30,	type = "offensive",	rlvl = 24	},
		{ spellID = 5209,	duration = 180,	type = "other",	rlvl = 28	},
		{ spellID = 1850,	duration = 180,	type = "other",	rlvl = 26	},
		{ spellID = 5229,	duration = 60,	type = "other",	rlvl = 22	},

		{ spellID = 6795,	duration = 8,	type = "other",	rlvl = 15	},
		{ spellID = 29166,	duration = 180,	type = "other",	rlvl = 28	},
		{ spellID = 17116,	duration = 180,	type = "other",	spec = true	},
		{ spellID = 5215,	duration = 10,	type = "other",	rlvl = 10	},
		{ spellID = 20484,	duration = 600,	type = "other",	rlvl = 20	},
		{ spellID = 77761,	duration = 120,	type = "other",	rlvl = 83	},
	},
	["HUNTER"] = {
		{ spellID = 26090,	duration = 30,	type = "interrupt",	rlvl = 1	},

		{ spellID = 1499,	duration = 30,	type = "cc",	rlvl = 28	},
		{ spellID = 19577,	duration = 60,	type = "cc",	spec = 1	},

		{ spellID = 19503,	duration = 30,	type = "cc",	rlvl = 15	},
		{ spellID = 19386,	duration = 60,	type = "cc",	spec = true	},
		{ spellID = 34490,	duration = 20,	type = "disarm",	spec = true	},
		{ spellID = 19263,	duration = 120,	type = "defensive",	rlvl = 78	},
		{ spellID = 5384,	duration = 30,	type = "defensive",	rlvl = 32	},
		{ spellID = 23989,	duration = 180,	type = "defensive",	spec = true	},

		{ spellID = 19574,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 3674,	duration = 30,	type = "offensive",	spec = true	},



		{ spellID = 13813,	duration = 30,	type = "offensive",	rlvl = 38	},

		{ spellID = 13795,	duration = 30,	type = "offensive",	rlvl = 22	},



		{ spellID = 3045,	duration = 300,	type = "offensive",	rlvl = 54	},

		{ spellID = 34600,	duration = 30,	type = "offensive",	rlvl = 66	},
		{ spellID = 51753,	duration = 60,	type = "other",	rlvl = 85	},

		{ spellID = 781,	duration = 25,	type = "other",	rlvl = 14	},


		{ spellID = 1543,	duration = 20,	type = "other",	rlvl = 38	},
		{ spellID = 82726,	duration = 120,	type = "other",	spec = true	},
		{ spellID = 13809,	duration = 30,	type = "other",	rlvl = 46	},
		{ spellID = 53271,	duration = 45,	type = "other",	rlvl = 74	},
		{ spellID = 34477,	duration = 30,	type = "other",	rlvl = 76	},

		{ spellID = 53480,	duration = 60,	type = "other",	rlvl = 1	},
	},
	["MAGE"] = {
		{ spellID = 2139,	duration = 24,	type = "interrupt",	rlvl = 9	},
		{ spellID = 44572,	duration = 30,	type = "cc",	spec = true	},
		{ spellID = 31661,	duration = 20,	type = "cc",	spec = true	},
		{ spellID = 82676,	duration = 120,	type = "cc",	rlvl = 83	},
		{ spellID = 11113,	duration = 15,	type = "disarm",	spec = true	},
		{ spellID = 122,	duration = 25,	type = "disarm",	rlvl = 8	},
		{ spellID = 33395,	duration = 25,	type = "disarm",	rlvl = 10,	spec = 3	},
		{ spellID = 45438,	duration = 300,	type = "immunity",	rlvl = 30	},
		{ spellID = 86948,	duration = 60,	type = "defensive",	spec = {86948,86949}	},
		{ spellID = 11958,	duration = 480,	type = "defensive",	spec = true	},
		{ spellID = 543,	duration = 30,	type = "defensive",	rlvl = 36	},
		{ spellID = 11426,	duration = 30,	type = "defensive",	spec = true	},

		{ spellID = 12042,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 11129,	duration = 120,	type = "offensive",	spec = true	},

		{ spellID = 82731,	duration = 60,	type = "offensive",	rlvl = 81	},
		{ spellID = 12472,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 55342,	duration = 180,	type = "offensive",	rlvl = 50	},
		{ spellID = 12043,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 31687,	duration = 180,	type = "offensive",	spec = 3	},
		{ spellID = 80353,	duration = 300,	type = "offensive",	rlvl = 85	},
		{ spellID = 1953,	duration = 15,	type = "other",	rlvl = 16	},

		{ spellID = 12051,	duration = 240,	type = "other",	rlvl = 12	},
		{ spellID = 66,	duration = 180,	type = "other",	rlvl = 78	},

	},
	["PALADIN"] = {
		{ spellID = 96231,	duration = 10,	type = "interrupt",	rlvl = 54	},
		{ spellID = 853,	duration = 60,	type = "cc",	rlvl = 14	},
		{ spellID = 2812,	duration = 15,	type = "cc",	rlvl = 28	},
		{ spellID = 20066,	duration = 60,	type = "cc",	spec = true	},
		{ spellID = 10326,	duration = 8,	type = "cc",	spec = 54931	},
		{ spellID = 31935,	duration = 15,	type = "disarm",	spec = 2	},
		{ spellID = 642,	duration = 300,	type = "immunity",	rlvl = 48	},
		{ spellID = 1022,	duration = 300,	type = "externalDefensive",	rlvl = 18	},
		{ spellID = 6940,	duration = 120,	type = "externalDefensive",	rlvl = 80	},
		{ spellID = 64205,	duration = 120,	type = "raidDefensive",	spec = true	},
		{ spellID = 633,	duration = 600,	type = "externalDefensive",	rlvl = 16	},
		{ spellID = 31850,	duration = 180,	type = "defensive",	spec = true	},
		{ spellID = 70940,	duration = 180,	type = "defensive",	spec = true	},
		{ spellID = 498,	duration = 60,	type = "defensive",	rlvl = 30	},
		{ spellID = 86150,	duration = 300,	type = "defensive",	rlvl = 85	},
		{ spellID = 20925,	duration = 30,	type = "defensive",	spec = true	},
		{ spellID = 31821,	duration = 120,	type = "raidDefensive",	spec = true	},
		{ spellID = 31884,	duration = 180,	type = "offensive",	rlvl = 72	},
		{ spellID = 26573,	duration = 30,	type = "offensive",	rlvl = 24	},

		{ spellID = 31842,	duration = 180,	type = "offensive",	spec = true	},






		{ spellID = 85673,	duration = 20,	type = "offensive",	rlvl = 9,	spec = {2,3}	},
		{ spellID = 85696,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 54428,	duration = 120,	type = "other",	rlvl = 44	},
		{ spellID = 1044,	duration = 25,	type = "other",	rlvl = 52	},
		{ spellID = 62124,	duration = 8,	type = "other",	rlvl = 14	},
		{ spellID = 1038,	duration = 120,	type = "other",	rlvl = 66	},

	},

	["PRIEST"] = {
		{ spellID = 64044,	duration = 120,	type = "cc",	spec = true	},
		{ spellID = 8122,	duration = 30,	type = "cc",	rlvl = 12	},
		{ spellID = 88625,	duration = 30,	type = "cc",	spec = 2	},
		{ spellID = 15487,	duration = 45,	type = "disarm",	spec = true	},
		{ spellID = 47788,	duration = 180,	type = "externalDefensive",	spec = true	},
		{ spellID = 33206,	duration = 180,	type = "externalDefensive",	spec = true	},
		{ spellID = 19236,	duration = 120,	type = "defensive",	spec = true	},
		{ spellID = 47585,	duration = 120,	type = "defensive",	spec = true	},


		{ spellID = 64843,	duration = 480,	type = "raidDefensive",	rlvl = 78	},
		{ spellID = 724,	duration = 180,	type = "raidDefensive",	spec = true	},
		{ spellID = 62618,	duration = 180,	type = "raidDefensive",	spec = true	},
		{ spellID = 14751,	duration = 30,	type = "offensive",	spec = true	},


		{ spellID = 89485,	duration = 45,	type = "offensive",	spec = true	},


		{ spellID = 10060,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 34433,	duration = 300,	type = "offensive",	rlvl = 66	},
		{ spellID = 6346,	duration = 180,	type = "counterCC",	rlvl = 54	},
		{ spellID = 32379,	duration = 10,	type = "counterCC",	rlvl = 32	},
		{ spellID = 586,	duration = 30,	type = "other",	rlvl = 24	},
		{ spellID = 64901,	duration = 360,	type = "other",	rlvl = 64	},
		{ spellID = 73325,	duration = 90,	type = "other",	rlvl = 85	},
	},
	["ROGUE"] = {
		{ spellID = 1766,	duration = 10,	type = "interrupt",	rlvl = 14	},
		{ spellID = 2094,	duration = 180,	type = "cc",	rlvl = 34	},
		{ spellID = 1776,	duration = 10,	type = "cc",	rlvl = 16	},
		{ spellID = 408,	duration = 20,	type = "cc",	rlvl = 30	},
		{ spellID = 76577,	duration = 180,	type = "cc",	rlvl = 85	},
		{ spellID = 51722,	duration = 60,	type = "disarm",	rlvl = 38	},
		{ spellID = 31228,	duration = 90,	type = "defensive",	spec = {31228,31229,31230}	},
		{ spellID = 31224,	duration = 120,	type = "defensive",	rlvl = 58	},
		{ spellID = 74001,	duration = 120,	type = "defensive",	rlvl = 81	},
		{ spellID = 5277,	duration = 180,	type = "defensive",	rlvl = 9	},

		{ spellID = 14185,	duration = 300,	type = "defensive",	spec = true	},

		{ spellID = 1856,	duration = 180,	type = "defensive",	rlvl = 24	},
		{ spellID = 13750,	duration = 180,	type = "offensive",	spec = true	},

		{ spellID = 14177,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 51690,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 14183,	duration = 20,	type = "offensive",	spec = true	},
		{ spellID = 51713,	duration = 60,	type = "offensive",	spec = true	},
		{ spellID = 79140,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 1725,	duration = 30,	type = "other",	rlvl = 28	},
		{ spellID = 73981,	duration = 60,	type = "other",	rlvl = 83	},
		{ spellID = 36554,	duration = 24,	type = "other",	spec = 3	},
		{ spellID = 2983,	duration = 60,	type = "other",	rlvl = 16	},
		{ spellID = 1784,	duration = 6,	type = "other",	rlvl = 5	},
		{ spellID = 57934,	duration = 30,	type = "other",	rlvl = 75	},
	},
	["SHAMAN"] = {
		{ spellID = 57994,	duration = 15,	type = "interrupt",	rlvl = 16	},
		{ spellID = 51514,	duration = 45,	type = "cc",	rlvl = 80	},
		{ spellID = 51490,	duration = 45,	type = "disarm",	spec = 1	},
		{ spellID = 30881,	duration = 30,	type = "defensive",	spec = {30881,30883,30884}	},
		{ spellID = 30823,	duration = 60,	type = "defensive",	spec = true	},
		{ spellID = 98008,	duration = 180,	type = "raidDefensive",	spec = true	},
		{ spellID = 2825,	duration = 300,	type = "offensive",	rlvl = 70	},



		{ spellID = 16166,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 51533,	duration = 120,	type = "offensive",	spec = true	},

		{ spellID = 2894,	duration = 600,	type = "offensive",	rlvl = 66	},





		{ spellID = 55198,	duration = 180,	type = "offensive",	spec = true	},
		{ spellID = 73680,	duration = 15,	type = "offensive",	rlvl = 81	},
		{ spellID = 8177,	duration = 25,	type = "counterCC",	rlvl = 38	},
		{ spellID = 8143,	duration = 60,	type = "counterCC",	rlvl = 52	},
		{ spellID = 2062,	duration = 600,	type = "other",	rlvl = 56	},
		{ spellID = 2484,	duration = 15,	type = "other",	rlvl = 18	},

		{ spellID = 16190,	duration = 180,	type = "other",	spec = true	},
		{ spellID = 16188,	duration = 120,	type = "other",	spec = true	},
		{ spellID = 20608,	duration = 1800,	type = "other",	rlvl = 30	},
		{ spellID = 79206,	duration = 120,	type = "other",	rlvl = 85	},
		{ spellID = 5730,	duration = 20,	type = "other",	rlvl = 58	},
	},
	["WARLOCK"] = {
		{ spellID = 19647,	duration = 24,	type = "interrupt",	rlvl = 52	},
		{ spellID = 19505,	duration = 15,	type = "dispel",	rlvl = 38	},
		{ spellID = 6789,	duration = 120,	type = "cc",	rlvl = 42	},
		{ spellID = 5484,	duration = 40,	type = "cc",	rlvl = 44	},
		{ spellID = 30283,	duration = 20,	type = "cc",	spec = true	},
		{ spellID = 54785,	duration = 45,	type = "cc",	spec = 59672	},
		{ spellID = 48020,	duration = 30,	type = "defensive",	rlvl = 78	},
		{ spellID = 91713,	duration = 30,	type = "defensive",	spec = true	},
		{ spellID = 6229,	duration = 30,	type = "defensive",	rlvl = 34	},
		{ spellID = 79268,	duration = 30,	type = "defensive",	rlvl = 12	},
		{ spellID = 50796,	duration = 12,	type = "offensive",	spec = true	},


		{ spellID = 47193,	duration = 60,	type = "offensive",	spec = true	},
		{ spellID = 77801,	duration = 120,	type = "offensive",	rlvl = 85	},

		{ spellID = 50589,	duration = 30,	type = "offensive",	spec = 59672	},
		{ spellID = 47241,	duration = 180,	type = "offensive",	spec = 59672	},


		{ spellID = 86121,	duration = 30,	type = "offensive",	spec = 56226	},
		{ spellID = 18540,	duration = 600,	type = "offensive",	rlvl = 58	},
		{ spellID = 1122,	duration = 600,	type = "offensive",	rlvl = 50	},
		{ spellID = 18708,	duration = 180,	type = "other",	spec = true	},


		{ spellID = 74434,	duration = 45,	type = "other",	rlvl = 10	},
		{ spellID = 29858,	duration = 120,	type = "other",	rlvl = 66	},
		{ spellID = 20707,	duration = 900,	type = "other",	rlvl = 18,	buff = 0	},
},
	["WARRIOR"] = {
		{ spellID = 6552,	duration = 10,	type = "interrupt",	rlvl = 38	},
		{ spellID = 100,	duration = 15,	type = "cc",	rlvl = 3	},
		{ spellID = 12809,	duration = 30,	type = "cc",	spec = true	},
		{ spellID = 20252,	duration = 30,	type = "cc",	rlvl = 50	},
		{ spellID = 5246,	duration = 120,	type = "cc",	rlvl = 42	},
		{ spellID = 46968,	duration = 20,	type = "cc",	spec = true	},
		{ spellID = 85388,	duration = 45,	type = "cc",	spec = true	},
		{ spellID = 676,	duration = 60,	type = "disarm",	rlvl = 34	},
		{ spellID = 57755,	duration = 60,	type = "disarm",	spec = {12311,12958}	},
		{ spellID = 469,	duration = 60,	type = "defensive",	rlvl = 68	},
		{ spellID = 55694,	duration = 180,	type = "defensive",	rlvl = 76	},
		{ spellID = 12975,	duration = 180,	type = "defensive",	spec = true	},
		{ spellID = 97462,	duration = 180,	type = "raidDefensive",	rlvl = 83	},
		{ spellID = 2565,	duration = 60,	type = "defensive",	rlvl = 28	},
		{ spellID = 871,	duration = 300,	type = "defensive",	rlvl = 48	},
		{ spellID = 46924,	duration = 90,	type = "offensive",	spec = true	},

		{ spellID = 86346,	duration = 20,	type = "offensive",	rlvl = 81	},
		{ spellID = 85730,	duration = 120,	type = "offensive",	spec = true	},
		{ spellID = 12292,	duration = 180,	type = "offensive",	spec = true	},


		{ spellID = 1719,	duration = 300,	type = "offensive",	rlvl = 64	},
		{ spellID = 20230,	duration = 300,	type = "offensive",	rlvl = 62	},


		{ spellID = 12328,	duration = 60,	type = "offensive",	spec = true	},


		{ spellID = 18499,	duration = 30,	type = "counterCC",	rlvl = 54	},
		{ spellID = 3411,	duration = 30,	type = "counterCC",	rlvl = 72	},
		{ spellID = 23920,	duration = 25,	type = "counterCC",	rlvl = 66	},
		{ spellID = 1161,	duration = 180,	type = "other",	rlvl = 46	},
		{ spellID = 60970,	duration = 30,	type = "other",	spec = true	},
		{ spellID = 6544,	duration = 60,	type = "other",	rlvl = 85	},
		{ spellID = 1134,	duration = 30,	type = "other",	rlvl = 56	},
		{ spellID = 64382,	duration = 300,	type = "other",	rlvl = 74	},
		{ spellID = 355,	duration = 8,	type = "other",	rlvl = 12	},
	},
	["PVPTRINKET"] = {
		{ spellID = 42292,	duration = {[18859]=300,default=120},	type = "pvptrinket",	item = 37864,	item2 = 18859	},
		{ spellID = 44055,	duration = 180,	type = "trinket",	item = 34050,	icon = 132344	},
		{ spellID = 92223,	duration = 120,	type = "trinket",	item = 64740,	icon = 132344	},
		{ spellID = 92226,	duration = 120,	type = "trinket",	item = 64687,	icon = 135884	},
	},
	["RACIAL"] = {
		{ spellID = 28730,	duration = 120,	type = "racial",	race = 10	},
		{ spellID = 26297,	duration = 180,	type = "racial",	race = 8	},
		{ spellID = 20572,	duration = 120,	type = "racial",	race = 2	},
		{ spellID = 20589,	duration = 105,	type = "racial",	race = 7	},
		{ spellID = 28880,	duration = 180,	type = "racial",	race = 11	},
		{ spellID = 59752,	duration = 120,	type = "racial",	race = 1	},
		{ spellID = 58984,	duration = 120,	type = "racial",	race = 4	},
		{ spellID = 20594,	duration = 120,	type = "racial",	race = 3	},
		{ spellID = 20549,	duration = 120,	type = "racial",	race = 6	},
		{ spellID = 7744,	duration = 120,	type = "racial",	race = 5	},
		{ spellID = 68992,	duration = 120,	type = "racial",	race = 22	},
		{ spellID = 69070,	duration = 120,	type = "racial",	race = 9	},
	},
	["TRINKET"] = {

	},
}

E.buffFix = E.BLANK
E.buffFixNoCLEU = E.BLANK
E.spell_requiredLevel = {}
E.summonedBuffDuration = E.BLANK

E.spellDefaults = {
	42292,
	59752,
	20594,
	20549,
	7744,

	47528,
	49203,
	47476,
	49576,
	48707,
	48743,
	48792,
	49005,
	51052,
	42650,
	49028,
	47568,
	49016,
	49206,
	49039,
	51271,

	80964,
	78675,
	5211,
	22812,
	61336,
	740,
	50334,
	48505,
	33831,
	17116,
	33891,

	1499,
	19577,
	19503,
	19386,
	34490,
	19263,
	23989,
	19574,
	3045,

	2139,
	44572,
	31661,
	82676,
	45438,
	11958,
	86948,
	12042,
	11129,
	12472,
	55342,
	12043,

	96231,
	853,
	20066,
	642,
	1022,
	6940,
	64205,
	31842,
	498,
	70940,
	86150,
	633,
	31850,
	31884,
	85696,
	31821,

	64044,
	8122,
	88625,
	15487,
	47788,
	33206,
	19236,
	47585,
	64843,
	724,
	62618,
	14751,
	10060,
	34433,
	6346,
	32379,

	1766,
	2094,
	408,
	76577,
	51722,
	31228,
	31224,
	5277,
	14185,
	1856,
	74001,
	13750,
	13877,
	14177,
	51690,
	51713,
	79140,
	36554,

	57994,
	51514,
	30881,
	30823,
	98008,
	2825,
	16166,
	51533,
	2894,
	55198,
	8177,
	8143,
	16188,

	19647,
	6789,
	5484,
	30283,
	54785,
	48020,
	1122,
	18540,
	47241,
	18708,

	6552,
	72,
	12809,
	5246,
	46968,
	85388,
	676,
	57755,
	55694,
	12975,
	97462,
	871,
	46924,
	12292,
	1719,
	85730,
	20230,
	3411,
	64382,
	18499,
	23920,
}

E.interruptDefaults = {
	47528, 16979, 26090, 2139, 1766, 57994, 19244, 6552, 72,
}

E.raidDefaults = {
	51052,
	740,
	31821,
	64843,
	724,
	62618,
	98008,
	97462,
}
