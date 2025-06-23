-- luacheck: no max line length
-- luacheck: globals GetBuildInfo LibStub

local _, addonTable = ...;

addonTable.HUNTER_FEIGN_DEATH = 5384;

addonTable.CDs = {
	[addonTable.UNKNOWN_CLASS] = {
		-- // reviewed 2023/01/09
		[336126] = 120,		-- // Медальон гладиатора https://www.wowhead.com/spell=336126
		[42292] = 120,		-- // PvP-аксессуар https://www.wowhead.com/spell=42292
		[283167] = 60,		-- // Адаптация https://www.wowhead.com/spell=283167
		[28730] = 120,		-- // Arcane Torrent https://www.wowhead.com/spell=28730
		[50613] = 120,		-- // Arcane Torrent https://www.wowhead.com/spell=50613
		[80483] = 120,		-- // Arcane Torrent https://www.wowhead.com/spell=80483
		[25046] = 120,		-- // Arcane Torrent https://www.wowhead.com/spell=25046
		[69179] = 120,		-- // Arcane Torrent https://www.wowhead.com/spell=69179
		[20572] = 120,		-- // Blood Fury https://www.wowhead.com/spell=20572
		[33702] = 120,		-- // Blood Fury https://www.wowhead.com/spell=33702
		[33697] = 120,		-- // Blood Fury https://www.wowhead.com/spell=33697
		[59543] = 180,		-- // Gift of the Naaru https://www.wowhead.com/spell=59543
		[69070] = 90,		-- // Rocket Jump https://www.wowhead.com/spell=69070
		[26297] = 180,		-- // Berserking https://www.wowhead.com/spell=26297
		[20594] = 120,		-- // Stoneform https://www.wowhead.com/spell=20594
		[58984] = 120,		-- // Shadowmeld https://www.wowhead.com/spell=58984
		[20589] = 60,		-- // Escape Artist https://www.wowhead.com/spell=20589
		[59752] = 180,		-- // Every Man for Himself https://www.wowhead.com/spell=59752
		[7744] = 120,		-- // Will of the Forsaken https://www.wowhead.com/spell=7744
		[68992] = 120,		-- // Darkflight https://www.wowhead.com/spell=68992
		[69041] = 90,		-- // Rocket Barrage https://www.wowhead.com/spell=69041
		[265221] = 120,		-- // Fireblood https://www.wowhead.com/spell=265221/fireblood
	},
	["HUNTER"] = {
		-- // reviewed 2023/01/09
		[53271] = 22.5,					-- // Master's Call https://wowhead.com/spell=53271
		[308491] = 60,					-- Resonating Arrow https://www.wowhead.com/spell=308491/resonating-arrow
		[186265] = 180-180*0.07,		-- Aspect of the Turtle https://www.wowhead.com/spell=186265
		[187650] = 30-30*0.15-2.5,		-- Freezing Trap https://www.wowhead.com/spell=187650
		[5384] = 28,					-- Feign Death https://www.wowhead.com/spell=5384
		[186257] = 90,					-- Aspect of the Cheetah https://www.wowhead.com/spell=186257
		[1543] = 20,					-- Flare https://www.wowhead.com/spell=1543
		[109304] = 120,					-- Exhilaration https://www.wowhead.com/spell=109304
		[781] = 20,						-- Disengage https://www.wowhead.com/spell=781
		[288613] = 80,					-- Trueshot https://www.wowhead.com/spell=288613
		[212431] = 30,					-- Explosive Shot https://www.wowhead.com/spell=212431
		[199483] = 60,					-- Camouflage https://www.wowhead.com/spell=199483
		[147362] = 24,					-- Counter Shot https://www.wowhead.com/spell=147362
		[19574] = 90,					-- Bestial Wrath https://www.wowhead.com/spell=19574
		[264735] = 150-180*0.07,		-- Survival of the Fittest https://www.wowhead.com/spell=264735
		[109248] = 45,					-- Binding Shot https://www.wowhead.com/spell=109248
		[213691] = 30,					-- Scatter Shot https://www.wowhead.com/spell=213691
		[236776] = 40-2.5,				-- High Explosive Trap https://www.wowhead.com/spell=236776
		[201430] = 120,					-- Stampede https://www.wowhead.com/spell=201430
		[19577] = 60,					-- Intimidation https://www.wowhead.com/spell=19577
		[359844] = 180,					-- Call of the Wild https://www.wowhead.com/spell=359844
		[186387] = 30,					-- Bursting Shot https://www.wowhead.com/spell=186387
		[190925] = 30,					-- Harpoon https://www.wowhead.com/spell=190925
		[187707] = 15,					-- Muzzle https://www.wowhead.com/spell=187707
		[205691] = 120,					-- Dire Beast: Basilisk https://www.wowhead.com/spell=205691
		[356719] = 60,					-- Chimaeral Sting https://www.wowhead.com/spell=356719
		[53480] = 60,					-- Roar of Sacrifice https://www.wowhead.com/spell=53480
		[212638] = 25,					-- Tracker's Net https://www.wowhead.com/spell=212638
		[375891] = 45,					-- Death Chakram https://www.wowhead.com/spell=375891
	},
	["WARLOCK"] = {
		-- // reviewed 2023/01/11
		[48020] = 30,		-- Demonic Circle: Teleport https://www.wowhead.com/spell=48020
		[104773] = 135,		-- Unending Resolve https://www.wowhead.com/spell=104773
		[19647] = 24,		-- Spell Lock https://www.wowhead.com/spell=19647
		[132409] = 24,		-- Spell Lock (demon sacrificed) https://www.wowhead.com/spell=132409
		[89766] = 30,		-- Axe Toss" https://www.wowhead.com/spell=89766
		[115781] = 24,		-- Optical Blast https://www.wowhead.com/spell=115781
		[325640] = 60,		-- Soul Rot https://www.wowhead.com/spell=325640/soul-rot
		[80240] = 30,		-- Havoc https://www.wowhead.com/spell=80240/havoc
		[265187] = 90,		-- Summon Demonic Tyrant https://www.wowhead.com/spell=265187
		[267217] = 180,		-- Nether Portal https://www.wowhead.com/spell=267217
		[1122] = 60,		-- Summon Infernal https://www.wowhead.com/spell=1122
		[6789] = 45,		-- Mortal Coil https://www.wowhead.com/spell=6789
		[108416] = 60,		-- Dark Pact https://www.wowhead.com/spell=108416
		[111898] = 120,		-- Grimoire: Felguard https://www.wowhead.com/spell=111898
		[30283] = 45,		-- Shadowfury https://www.wowhead.com/spell=30283
		[113860] = 120,		-- Dark Soul: Misery https://www.wowhead.com/spell=113860
		[5484] = 40,		-- Howl of Terror https://www.wowhead.com/spell=5484
		[113858] = 120,		-- Dark Soul: Instability https://www.wowhead.com/spell=113858
		[212295] = 45,		-- Nether Ward https://www.wowhead.com/spell=212295
		[353601] = 45,		-- Fel Obelisk https://www.wowhead.com/spell=353601
		[221703] = 60,		-- Casting Circle https://www.wowhead.com/spell=221703
		[212619] = 60,		-- Call Felhunter https://www.wowhead.com/spell=212619
		[353294] = 60,		-- Shadow Rift https://www.wowhead.com/spell=353294
		[212459] = 120,		-- Call Fel Lord https://www.wowhead.com/spell=212459
	},
	["MAGE"] = {
		-- // reviewed 2023/01/12
		[122] = 30,			-- Frost Nova https://www.wowhead.com/spell=122
		[1953] = 13,		-- Blink https://www.wowhead.com/spell=1953
		[45438] = 240 - 20,	-- Ice Block https://www.wowhead.com/spell=45438
		[2139] = 24,		-- Counterspell https://www.wowhead.com/spell=2139
		[12042] = 120,		-- Arcane Power https://www.wowhead.com/spell=12042
		[195676] = 30,		-- Displacement https://www.wowhead.com/spell=195676
		[110959] = 120-45,	-- Greater Invisibility https://www.wowhead.com/spell=110959
		[31661] = 45 - 2,	-- Dragon's Breath https://www.wowhead.com/spell=31661
		[84714] = 60,		-- Frozen Orb https://www.wowhead.com/spell=84714
		[12472] = 171,		-- Icy Veins https://www.wowhead.com/spell=12472
		[157980] = 25,		-- Supernova https://www.wowhead.com/spell=157980
		[55342] = 120,		-- Зеркальное изображение https://www.wowhead.com/spell=55342
		[108978] = 60,		-- Манипуляции со временем https://www.wowhead.com/spell=108978
		[113724] = 45,		-- Кольцо мороза https://www.wowhead.com/spell=113724
		[307443] = 30,		-- Radiant Spark https://www.wowhead.com/spell=307443/radiant-spark
		[365350] = 90,		-- Arcane Surge https://www.wowhead.com/spell=365350
		[190319] = 113,		-- Combustion https://www.wowhead.com/spell=190319
		[12051] = 90,		-- Evocation https://www.wowhead.com/spell=12051
		[157997] = 25,		-- Ice Nova https://www.wowhead.com/spell=157997
		[212653] = 23,		-- Shimmer https://www.wowhead.com/spell=212653
		[11426] = 25,		-- Ice Barrier https://www.wowhead.com/spell=11426
		[157981] = 25,		-- Blast Wave https://www.wowhead.com/spell=157981
		[342245] = 60,		-- Alter Time https://www.wowhead.com/spell=342245
		[235219] = 270,		-- Cold Snap https://www.wowhead.com/spell=235219
		[66] = 255,			-- Invisibility https://www.wowhead.com/spell=66
		[383121] = 60,		-- Mass Polymorph https://www.wowhead.com/spell=383121
		[389713] = 45,		-- Displacement https://www.wowhead.com/spell=389713
		[353082] = 30,		-- Ring of Fire https://www.wowhead.com/spell=353082
		[389794] = 45,		-- Snowdrift https://www.wowhead.com/spell=389794
		[198111] = 45,		-- Temporal Shield https://www.wowhead.com/spell=198111
		[352278] = 90,		-- Ice Wall https://www.wowhead.com/spell=352278
		[198158] = 60,		-- Mass Invisibility https://www.wowhead.com/spell=198158
		[198144] = 60,		-- Ice Form https://www.wowhead.com/spell=198144
	},
	["DEATHKNIGHT"] = {
		-- // reviewed 2023/01/17
		[91802] 	= 30,			-- Shambling Rush https://www.wowhead.com/spell=91802
		[275699]	= 30,			-- Апокалипсис https://www.wowhead.com/spell=275699
		[48265]		= 45,			-- Death's Advance https://www.wowhead.com/spell=48265
		[49576] 	= 25,			-- Death Grip	 https://www.wowhead.com/spell=49576
		[49039]		= 120,			-- Перерождение https://www.wowhead.com/spell=49039
		[51052] 	= 120,			-- Anti-Magic Zone https://www.wowhead.com/spell=51052
		[42650] 	= 240,			-- Army of the Dead https://www.wowhead.com/spell=42650
		[49206] 	= 180,			-- Summon Gargoyle https://www.wowhead.com/spell=49206
		[212552]	= 45,			-- Wraith Walk https://www.wowhead.com/spell=212552
		[49028] 	= 60,			-- Dancing Rune Weapon https://www.wowhead.com/spell=49028
		[207289] 	= 90,			-- Unholy Assault https://www.wowhead.com/spell=207289
		[108194] 	= 45,			-- Asphyxiate https://www.wowhead.com/spell=108194
		[221562] 	= 45,			-- Asphyxiate https://www.wowhead.com/spell=221562
		[108199] 	= 90,			-- Gorefiend's Grasp https://www.wowhead.com/spell=108199
		[114556] 	= 240,			-- Purgatory https://www.wowhead.com/spell=114556
		[207167] 	= 60, 			-- Blinding Sleet https://www.wowhead.com/spell=207167
		[48792] 	= 120,			-- Icebound Fortitude https://www.wowhead.com/spell=48792
		[48707] 	= 40,			-- Anti-Magic Shell https://www.wowhead.com/spell=48707
		[383269]	= 120,			-- Abomination Limb https://www.wowhead.com/spell=383269
		[47528] 	= 15,			-- Mind Freeze https://www.wowhead.com/spell=47528
		[55233] 	= 90,			-- Vampiric Blood https://www.wowhead.com/spell=55233
		[392962] 	= 120,			-- Empower Rune Weapon https://www.wowhead.com/spell=392962
		[392963] 	= 120,			-- Empower Rune Weapon https://www.wowhead.com/spell=392963
		[48743] 	= 120,			-- Death Pact https://www.wowhead.com/spell=48743
		[288853] 	= 90,			-- Raise Abomination https://www.wowhead.com/spell=288853
		[77606] 	= 20,			-- Dark Simulacrum https://www.wowhead.com/spell=77606
		[47476] 	= 60,			-- Strangulate https://www.wowhead.com/spell=47476
	},
	["DRUID"] = {
		-- // reviewed 2023/01/18
		[1850] = 120,							-- Dash https://www.wowhead.com/spell=1850
		[20484] = 600,							-- Rebirth https://www.wowhead.com/spell=20484
		[194223] = 180,							-- Celestial Alignment https://www.wowhead.com/spell=194223
		[106951] = 180,							-- Berserk https://www.wowhead.com/spell=106951
		[22570] = 20,							-- Maim https://www.wowhead.com/spell=22570
		[61336] = 180,							-- Survival Instincts x2 https://www.wowhead.com/spell=61336
		[102793] = 60,							-- Ursol's Vortex https://www.wowhead.com/spell=102793
		[108238] = 90,							-- Renewal https://www.wowhead.com/spell=108238
		[102543] = 180,							-- Incarnation: King of the Jungle https://www.wowhead.com/spell=102543
		[102558] = 180,							-- Incarnation: Guardian of Ursoc https://www.wowhead.com/spell=102558
		[33891] = 180,							-- Incarnation: Tree of Life https://www.wowhead.com/spell=33891
		[106839] = 15,							-- Skull Bash https://www.wowhead.com/spell=106839
		[132469] = 30,							-- Typhoon https://www.wowhead.com/spell=132469/typhoon https://www.wowhead.com/spell=132469
		[99] = 30,								-- Парализующий рык https://www.wowhead.com/spell=99
		[319454] = 300,							-- Сердце дикой природы https://www.wowhead.com/spell=319454
		[323764] = 120,							-- Convoke the Spirits https://www.wowhead.com/spell=323764/convoke-the-spirits
		[323546] = 180,							-- Ravenous Frenzy https://www.wowhead.com/spell=323546/ravenous-frenzy
		[22842] = 36,							-- Frenzied Regeneration https://www.wowhead.com/spell=22842/frenzied-regeneration
		[88423] = 8,							-- Nature's Cure https://www.wowhead.com/spell=88423/natures-cure
		[78675] = 40,							-- Solar Beam https://www.wowhead.com/spell=78675
		[102359] = 30,							-- Mass Entanglement https://www.wowhead.com/spell=102359/mass-entanglement https://www.wowhead.com/spell=102359
		[5211]	= 60,							-- Mighty Bash https://www.wowhead.com/spell=5211
		[102560] = 120,							-- Incarnation: Chosen of Elune https://www.wowhead.com/spell=102560
		[102342] = 70,							-- Ironbark https://www.wowhead.com/spell=102342
		[740] = 120,							-- Tranquility https://www.wowhead.com/spell=740
		[22812] = 51,							-- Barkskin https://www.wowhead.com/spell=22812
		[205636] = 60,							-- Force of Nature https://www.wowhead.com/spell=205636
		[102401] = 15,							-- Wild Charge https://www.wowhead.com/spell=102401
		[252216] = 45,							-- Tiger Dash https://www.wowhead.com/spell=252216
		[2782] = 8,								-- Remove Corruption https://www.wowhead.com/spell=2782
		[106898] = 60,							-- Stampeding Roar https://www.wowhead.com/spell=106898
		[329042] = 120,							-- Emerald Slumber https://www.wowhead.com/spell=329042
		[209749] = 30,							-- Faerie Swarm https://www.wowhead.com/spell=209749
		[202246] = 25,							-- Overrun https://www.wowhead.com/spell=202246
		[354654] = 60,							-- Grove Protection https://www.wowhead.com/spell=354654
		[132158] = 48,		-- Nature's Swiftness https://www.wowhead.com/spell=132158
	},
	["MONK"] = {
		-- // reviewed 2023/01/20
		[119996] = 30,					-- Transcendence: Transfer https://www.wowhead.com/spell=119996
		[119381] = 50,					-- Leg Sweep https://www.wowhead.com/spell=119381
		[322109] = 60,					-- Touch of Death https://www.wowhead.com/spell=322109
		[169340] = 90,					-- Touch of Fatality https://www.wowhead.com/spell=169340
		[115450] = 8,					-- Detox https://www.wowhead.com/spell=115450
		[137639] = 90,					-- Storm, Earth, and Fire https://www.wowhead.com/spell=137639
		[115078] = 30,					-- Paralysis https://www.wowhead.com/spell=115078
		[122783] = 90,					-- Diffuse Magic https://www.wowhead.com/spell=122783
		[116849] = 75,					-- Life Cocoon https://www.wowhead.com/spell=116849
		[122470] = 90,					-- Touch of Karma https://www.wowhead.com/spell=122470
		[113656] = 24,					-- Fists of Fury https://www.wowhead.com/spell=113656
		[123904] = 120,					-- Invoke Xuen, the White Tiger https://www.wowhead.com/spell=123904
		[152173] = 90,					-- Serenity https://www.wowhead.com/spell=152173
		[116844] = 45,					-- Ring of Peace https://www.wowhead.com/spell=116844
		[115310] = 90,					-- Revival https://www.wowhead.com/spell=115310
		[115176] = 75,					-- Zen Meditation https://www.wowhead.com/spell=115176
		[122278] = 120,					-- Dampen Harm https://www.wowhead.com/spell=122278
		[116841] = 30,					-- Tiger's Lust https://www.wowhead.com/spell=116841
		[116705] = 15,					-- Spear Hand Strike https://www.wowhead.com/spell=116705
		[198898] = 30,					-- Song of Chi-Ji https://www.wowhead.com/spell=198898
		[218164] = 8,					-- Detox https://www.wowhead.com/spell=218164
		[388615] = 90,					-- Restoral https://www.wowhead.com/spell=388615
		[324312] = 30,					-- Clash https://www.wowhead.com/spell=324312
		[233759] = 45,					-- Grapple Weapon https://www.wowhead.com/spell=233759
		[209584] = 30,					-- Zen Focus Tea https://www.wowhead.com/spell=209584
		[202370] = 30,					-- Mighty Ox Kick https://www.wowhead.com/spell=202370
		[354540] = 90,					-- Nimble Brew https://www.wowhead.com/spell=354540
	},
	["PALADIN"] = {
		-- // reviewed 2023/01/23
		[210294] = 45,					-- Divine Favor https://www.wowhead.com/spell=210294
		[642] = 210,					-- Divine Shield https://www.wowhead.com/spell=642
		[31884] = 60,					-- Avenging Wrath https://www.wowhead.com/spell=31884
		[853] = 60,						-- Hammer of Justice https://www.wowhead.com/spell=853
		[4987] = 8,						-- Cleanse https://www.wowhead.com/spell=4987
		[216331] = 120,					-- Avenging Crusader https://www.wowhead.com/spell=216331
		[1022] = 300,					-- Blessing of Protection https://www.wowhead.com/spell=1022
		[498] = 40,						-- Divine Protection https://www.wowhead.com/spell=498
		[6940] = 120,					-- Blessing of Sacrifice https://www.wowhead.com/spell=6940
		[31821] = 90,					-- Aura Mastery https://www.wowhead.com/spell=31821
		[231895] = 120,					-- Crusade https://www.wowhead.com/spell=231895
		[20066] = 15,					-- Repentance https://www.wowhead.com/spell=20066
		[633] = 240,					-- Lay on Hands https://www.wowhead.com/spell=633
		[184662] = 60,					-- Shield of Vengeance https://www.wowhead.com/spell=184662
		[1044] = 25,					-- Blessing of Freedom https://www.wowhead.com/spell=1044
		[31850] = 80,					-- Ardent Defender https://www.wowhead.com/spell=31850
		[86659] = 300,					-- Guardian of Ancient Kings https://www.wowhead.com/spell=86659
		[96231] = 15,					-- Rebuke https://www.wowhead.com/spell=96231
		[204018] = 200,					-- Blessing of Spellwarding https://www.wowhead.com/spell=204018
		[190784] = 45,					-- Divine Steed https://www.wowhead.com/spell=190784
		[115750] = 90,					-- Blinding Light https://www.wowhead.com/spell=115750
		[105809] = 180,					-- Holy Avenger https://www.wowhead.com/spell=105809
		[205191] = 60,					-- Eye for an Eye https://www.wowhead.com/spell=205191
		[389539] = 120,					-- Sentinel https://www.wowhead.com/spell=389539
		[213644] = 8,					-- Cleanse Toxins https://www.wowhead.com/spell=213644
		[210256] = 45,					-- Blessing of Sanctuary https://www.wowhead.com/spell=210256
		[228049] = 300,					-- Guardian of the Forgotten Queen https://www.wowhead.com/spell=228049
		[375576] = 60,					-- Divine Toll https://www.wowhead.com/spell=375576
		[343721] = 60,					-- Final Reckoning https://www.wowhead.com/spell=343721
	},
	["PRIEST"] = {
		-- // reviewed 2023/01/24
		[32375] = 20,		-- Mass Dispel https://www.wowhead.com/spell=32375/mass-dispel
		[47536] = 90,		-- Rapture https://www.wowhead.com/spell=47536
		[32379] = 20,		-- Shadow Word: Death https://www.wowhead.com/spell=32379
		[19236] = 90,		-- Desperate Prayer https://www.wowhead.com/spell=19236
		[8122] = 30,		-- Psychic Scream https://www.wowhead.com/spell=8122
		[527] = 8,			-- Purify https://www.wowhead.com/spell=527
		[10060] = 120,		-- Power Infusion https://www.wowhead.com/spell=10060
		[33206] = 60,		-- Pain Suppression https://www.wowhead.com/spell=33206
		[15286] = 60,		-- Vampiric Embrace https://www.wowhead.com/spell=15286
		[34433] = 180,		-- Shadowfiend https://www.wowhead.com/spell=34433
		[123040] = 60,		-- Mindbender https://www.wowhead.com/spell=123040
		[47788] = 120,		-- Guardian Spirit https://www.wowhead.com/spell=47788
		[64843] = 180,		-- Divine Hymn https://www.wowhead.com/spell=64843
		[73325] = 60,		-- Leap of Faith https://www.wowhead.com/spell=73325
		[62618] = 90,		-- Power Word: Barrier https://www.wowhead.com/spell=62618
		[373481] = 10,		-- Power Word: Life https://www.wowhead.com/spell=373481
		[15487] = 30,		-- Silence https://www.wowhead.com/spell=15487
		[2050] = 20,		-- Holy Word: Serenity https://www.wowhead.com/spell=2050
		[375901] = 45,		-- Mindgames https://www.wowhead.com/spell=375901
		[108968] = 300,		-- Void Shift https://www.wowhead.com/spell=108968
		[120517] = 25,		-- Halo https://www.wowhead.com/spell=120517
		[88625] = 60,		-- Holy Word: Chastise https://www.wowhead.com/spell=88625
		[213634] = 8,		-- Purify Disease https://www.wowhead.com/spell=213634
		[200174] = 60,		-- Mindbender https://www.wowhead.com/spell=200174
		[47585] = 120,		-- Dispersion https://www.wowhead.com/spell=47585
		[120644] = 25,		-- Halo https://www.wowhead.com/spell=120644
		[205364] = 30,		-- Dominate Mind https://www.wowhead.com/spell=205364
		[108920] = 60,		-- Void Tendrils https://www.wowhead.com/spell=108920
		[372835] = 180,		-- Lightwell https://www.wowhead.com/spell=372835
		[64044] = 45,		-- Psychic Horror https://www.wowhead.com/spell=64044
		[197268] = 90,		-- Ray of Hope https://www.wowhead.com/spell=197268
		[211522] = 45,		-- Psyfiend https://www.wowhead.com/spell=211522
		[316262] = 90,		-- Thoughtsteal https://www.wowhead.com/spell=316262
		[328530] = 60,		-- Divine Ascension https://www.wowhead.com/spell=328530
		[213610] = 45,		-- Holy Ward https://www.wowhead.com/spell=213610
		[228260] = 120,		-- Void Eruption https://www.wowhead.com/spell=228260
		[391109] = 60,		-- Dark Ascension https://www.wowhead.com/spell=391109
		[586] = 25,				-- Fade https://www.wowhead.com/spell=586
	},
	["ROGUE"] = {
		-- // reviewed 2023/01/30
		[36554] = 20,				-- Shadowstep https://www.wowhead.com/spell=36554
		[185313] = 60,				-- Танец теней https://www.wowhead.com/spell=185313
		[315341] = 45,				-- Between the Eyes https://www.wowhead.com/spell=315341/between-the-eyes
		[1856] = 80,				-- Vanish https://www.wowhead.com/spell=1856
		[114018] = 360,				-- Shroud of Concealment https://www.wowhead.com/spell=114018
		[408] = 20,					-- Kidney Shot https://www.wowhead.com/spell=408
		[1766] = 14,				-- Kick https://www.wowhead.com/spell=1766
		[2983] = 60,				-- Sprint https://www.wowhead.com/spell=2983
		[13750] = 180,				-- Adrenaline Rush https://www.wowhead.com/spell=13750
		[31224] = 120,				-- Cloak of Shadows https://www.wowhead.com/spell=31224
		[2094] = 90,				-- Blind https://www.wowhead.com/spell=2094
		[31230] = 360,				-- Cheat Death https://www.wowhead.com/spell=31230
		[5277] = 120,				-- Evasion https://www.wowhead.com/spell=5277
		[1776] = 20,				-- Gouge https://www.wowhead.com/spell=1776
		[51690] = 120,				-- Killing Spree https://www.wowhead.com/spell=51690
		[121471] = 80,				-- Shadow Blades https://www.wowhead.com/spell=121471
		[271877] = 45,				-- Blade Rush https://www.wowhead.com/spell=271877
		[343142] = 120,				-- Dreadblades https://www.wowhead.com/spell=343142
		[195457] = 30,				-- Grappling Hook https://www.wowhead.com/spell=195457
		[207736] = 120,				-- Shadowy Duel https://www.wowhead.com/spell=207736
		[212182] = 180,				-- Smoke Bomb https://www.wowhead.com/spell=212182
		[359053] = 120,				-- Smoke Bomb https://www.wowhead.com/spell=359053
		[207777] = 45,				-- Dismantle https://www.wowhead.com/spell=207777
	},
	["SHAMAN"] = {
		-- // reviewed 2023/03/03
		[79206] = 90,		-- Spiritwalker's Grace https://www.wowhead.com/spell=79206
		[196884] = 30,		-- Свирепый выпад https://www.wowhead.com/spell=196884
		[198838] = 57,		-- Earthen Wall Totem https://www.wowhead.com/spell=198838
		[320674] = 90,		-- Chain Harvest https://www.wowhead.com/spell=320674/chain-harvest
		[326059] = 45,		-- Primordial Wave https://www.wowhead.com/spell=326059/primordial-wave
		[328923] = 120,		-- Fae Transfusion https://www.wowhead.com/spell=328923/fae-transfusion
		[324386] = 60,		-- Vesper Totem https://www.wowhead.com/spell=324386/vesper-totem
		[51514] = 20,		-- Hex https://www.wowhead.com/spell=51514
		[210873] = 20,		-- Hex https://www.wowhead.com/spell=210873
		[211004] = 20,		-- Hex https://www.wowhead.com/spell=211004
		[211010] = 20,		-- Hex https://www.wowhead.com/spell=211010
		[211015] = 20,		-- Hex https://www.wowhead.com/spell=211015
		[269352] = 20,		-- Hex https://www.wowhead.com/spell=269352
		[277778] = 20,		-- Hex https://www.wowhead.com/spell=277778
		[277784] = 20,		-- Hex https://www.wowhead.com/spell=277784
		[309328] = 20,		-- Hex https://www.wowhead.com/spell=309328
		[32182] = 60,		-- Heroism https://www.wowhead.com/spell=32182
		[2825] = 60,		-- Bloodlust https://www.wowhead.com/spell=2825
		[20608] = 450,		-- Reincarnation https://www.wowhead.com/spell=20608
		[77130] = 8,		-- Purify Spirit https://www.wowhead.com/spell=77130
		[51886] = 8,		-- Cleanse Spirit https://www.wowhead.com/spell=51886
		[108281] = 120,		-- Ancestral Guidance https://www.wowhead.com/spell=108281
		[108280] = 90,		-- Healing Tide Totem https://www.wowhead.com/spell=108280
		[192249] = 150,		-- Storm Elemental https://www.wowhead.com/spell=192249
		[198067] = 150,		-- Fire Elemental https://www.wowhead.com/spell=198067
		[98008] = 180,		-- Spirit Link Totem https://www.wowhead.com/spell=98008
		[114050] = 180,		-- Elemental Ascendance https://www.wowhead.com/spell=114050
		[114051] = 180,		-- Enhancement Ascendance https://www.wowhead.com/spell=114051
		[114052] = 180,		-- Restoration Ascendance https://www.wowhead.com/spell=114052
		[51533] = 90,		-- Feral Spirit https://www.wowhead.com/spell=51533
		[51485] = 57,		-- Earthgrab Totem https://www.wowhead.com/spell=51485
		[8143] = 57,		-- Тотем трепета https://www.wowhead.com/spell=8143
		[108271] = 90,		-- Астральный сдвиг https://www.wowhead.com/spell=108271
		[192058] = 57,		-- Тотем выброса тока https://www.wowhead.com/spell=192058
		[192077] = 117,		-- Тотем ветряного порыва https://www.wowhead.com/spell=192077
		[191634] = 60,		-- Stormkeeper https://www.wowhead.com/spell=191634
		[320137] = 60,		-- Stormkeeper https://www.wowhead.com/spell=320137
		[383009] = 60,		-- Stormkeeper https://www.wowhead.com/spell=383009
		[392763] = 60,		-- Stormkeeper https://www.wowhead.com/spell=392763
		[392714] = 60,		-- Stormkeeper https://www.wowhead.com/spell=392714
		[207399] = 297,		-- Тотем защиты Предков https://www.wowhead.com/spell=207399
		[192063] = 25,		-- Gust of Wind https://www.wowhead.com/spell=192063
		[57994] = 12,		-- Wind Shear https://www.wowhead.com/spell=57994
		[197214] = 40,		-- Раскол https://www.wowhead.com/spell=197214
		[378081] = 60,		-- Nature's Swiftness https://www.wowhead.com/spell=378081
		[51490] = 25,		-- Thunderstorm https://www.wowhead.com/spell=51490
		[305483] = 45,		-- Молния-лассо https://www.wowhead.com/spell=305483
		[58875] = 52,		-- Spirit Walk https://www.wowhead.com/spell=58875
		[383019] = 57,		-- Tranquil Air Totem https://www.wowhead.com/spell=383019
		[204336] = 24,		-- Grounding Totem https://www.wowhead.com/spell=204336
		[204331] = 42,		-- Counterstrike Totem https://www.wowhead.com/spell=204331
		[204366] = 45,		-- Thundercharge https://www.wowhead.com/spell=204366
		[355580] = 57,		-- Static Field Totem https://www.wowhead.com/spell=355580
		[210918] = 60,		-- Ethereal Form https://www.wowhead.com/spell=210918
		[409293] = 120,  	-- Burrow https://www.wowhead.com/spell=409293
	},
	["WARRIOR"] = {
		-- // reviewed 2023/03/09
		[100] = 20,					-- Charge https://www.wowhead.com/spell=100
		[6552] = 13,				-- Pummel https://www.wowhead.com/spell=6552
		[1719] = 90,				-- Recklessness https://www.wowhead.com/spell=1719
		[23920] = 25,				-- Spell Reflection https://www.wowhead.com/spell=23920
		[227847] = 60,				-- Bladestorm https://www.wowhead.com/spell=227847
		[167105] = 45,				-- Colossus Smash https://www.wowhead.com/spell=167105
		[118038] = 90,				-- Die by the Sword https://www.wowhead.com/spell=118038
		[5246] = 90,				-- Intimidating Shout https://www.wowhead.com/spell=5246
		[6544] = 30,				-- Heroic Leap https://www.wowhead.com/spell=6544
		[52174] = 30,				-- Heroic Leap https://www.wowhead.com/spell=52174
		[107574] = 90,				-- Avatar https://www.wowhead.com/spell=107574
		[401150] = 90,				-- Avatar https://www.wowhead.com/spell=401150
		[871] = 150,				-- Shield Wall https://www.wowhead.com/spell=871
		[107570] = 30,				-- Storm Bolt https://www.wowhead.com/spell=107570
		[12975] = 120,				-- Last Stand https://www.wowhead.com/spell=12975
		[262161] = 45,				-- Warbreaker https://www.wowhead.com/spell=262161
		[3411] = 30,				-- Intervene https://www.wowhead.com/spell=3411/intervene
		[18499] = 60,				-- Berserker Rage https://www.wowhead.com/spell=18499
		[46968] = 40,				-- Shockwave https://www.wowhead.com/spell=46968
		[184364] = 30,				-- Enraged Regeneration https://www.wowhead.com/spell=184364
		[392966] = 90,				-- Spell Block https://www.wowhead.com/spell=392966
		[376079] = 90,				-- Spear of Bastion https://www.wowhead.com/spell=376079
		[307865] = 60,				-- Spear of Bastion https://www.wowhead.com/spell=307865
		[118000] = 30,				-- Dragon Roar https://www.wowhead.com/spell=118000
		[383762] = 180,				-- Bitter Immunity https://www.wowhead.com/spell=383762
		[385952] = 45,				-- Shield Charge https://www.wowhead.com/spell=385952
		[64382] = 90,				-- Shattering Throw https://www.wowhead.com/spell=64382
		[386071] = 90,				-- Disrupting Shout https://www.wowhead.com/spell=386071
		[46924] = 60,				-- Bladestorm https://www.wowhead.com/spell=46924
		[384100] = 60,				-- Berserker Shout https://www.wowhead.com/spell=384100
		[236320] = 90,				-- War Banner https://www.wowhead.com/spell=236320
		[236077] = 45,				-- Disarm https://www.wowhead.com/spell=236077
		[206572] = 20,				-- Dragon Charge https://www.wowhead.com/spell=206572
		[329038] = 20,				-- Кровавая ярость https://www.wowhead.com/spell=329038
		[97462] = 120,				-- Rallying Cry https://www.wowhead.com/spell=97462
	},
	["DEMONHUNTER"] = {
		-- // reviewed 2023/04/07
		[191427] = 180,			-- Metamorphosis https://www.wowhead.com/spell=191427
		[183752] = 15,			-- Disrupt https://www.wowhead.com/spell=183752
		[188501] = 30,			-- Spectral Sight https://www.wowhead.com/spell=188501
		[195072] = 10,			-- Fel Rush https://www.wowhead.com/spell=195072
		[198589] = 30,			-- Blur https://www.wowhead.com/spell=198589
		[187827] = 180,			-- Metamorphosis https://www.wowhead.com/spell=187827
		[189110] = 20,			-- Infernal Strike https://www.wowhead.com/spell=189110
		[198793] = 15,			-- Vengeful Retreat https://www.wowhead.com/spell=198793
		[207684] = 60,			-- Sigil of Misery https://www.wowhead.com/spell=207684
		[217832] = 45,			-- Imprison https://www.wowhead.com/spell=217832
		[204021] = 60,			-- Fiery Brand https://www.wowhead.com/spell=204021
		[196718] = 180,			-- Darkness https://www.wowhead.com/spell=196718
		[211881] = 30,			-- Fel Eruption https://www.wowhead.com/spell=211881
		[179057] = 48,			-- Chaos Nova https://www.wowhead.com/spell=179057
		[196555] = 180,			-- Netherwalk https://www.wowhead.com/spell=196555
		[202137] = 30,			-- Sigil of Silence https://www.wowhead.com/spell=202137
		[232893] = 15,			-- Felblade https://www.wowhead.com/spell=232893
		[390163] = 60,			-- Elysian Decree https://www.wowhead.com/spell=390163
		[263648] = 30,			-- Soul Barrier https://www.wowhead.com/spell=263648
		[206803] = 60,			-- Rain from Above https://www.wowhead.com/spell=206803
		[205604] = 60,			-- Reverse Magic https://www.wowhead.com/spell=205604
		[205630] = 60,			-- Illidan's Grasp https://www.wowhead.com/spell=205630
		[205629] = 20,			-- Demonic Trample https://www.wowhead.com/spell=205629
		[202138] = 30,			-- Sigil of Chains https://www.wowhead.com/spell=202138
		[198013] = 40,			-- Eye Beam https://www.wowhead.com/spell=198013/eye-beam
	},
	["EVOKER"] = {
		-- // reviewed 2022/12/02
		[357210] = 60,					-- Deep Breath https://www.wowhead.com/spell=357210/deep-breath
		[390386] = 300,					-- Fury of the Aspects https://www.wowhead.com/spell=390386
		[358267] = 35,					-- Hover https://www.wowhead.com/spell=358267
		[375087] = 120,					-- Dragonrage https://www.wowhead.com/spell=375087
		[360995] = 24,					-- Verdant Embrace https://www.wowhead.com/spell=360995
		[370665] = 60,					-- Rescue https://www.wowhead.com/spell=370665
		[363534] = 240,					-- Rewind https://www.wowhead.com/spell=363534
		[370553] = 120,					-- Tip the Scales https://www.wowhead.com/spell=370553
		[351338] = 20,					-- Quell https://www.wowhead.com/spell=351338
		[374348] = 60,					-- Renewing Blaze https://www.wowhead.com/spell=374348
		[357170] = 60,					-- Time Dilation https://www.wowhead.com/spell=357170
		[370537] = 90,					-- Stasis https://www.wowhead.com/spell=370537
		[374251] = 60,					-- Cauterizing Flame https://www.wowhead.com/spell=374251
		[372048] = 120,					-- Oppressing Roar https://www.wowhead.com/spell=372048
		[374968] = 120,					-- Time Spiral https://www.wowhead.com/spell=374968
		[363916] = 90,					-- Obsidian Scales https://www.wowhead.com/spell=363916
		[374227] = 120,					-- Zephyr https://www.wowhead.com/spell=374227
		[360806] = 15,					-- Sleep Walk https://www.wowhead.com/spell=360806
		[359816] = 120,					-- Dream Flight https://www.wowhead.com/spell=359816
		[358385] = 60,					-- Landslide https://www.wowhead.com/spell=358385
		[370960] = 180,					-- Emerald Communion https://www.wowhead.com/spell=370960
		[378464] = 90,					-- Nullifying Shroud https://www.wowhead.com/spell=378464
		[377509] = 90,					-- Dream Projection https://www.wowhead.com/spell=377509
		[383005] = 90,					-- Chrono Loop https://www.wowhead.com/spell=383005
		[370388] = 90,					-- Swoop Up https://www.wowhead.com/spell=370388
		[378441] = 120,					-- Time Stop https://www.wowhead.com/spell=378441
	},
};

addonTable.Interrupts = {
	[47528] = true,	-- // Mind Freeze
	[106839] = true,	-- // Skull Bash
	[2139] = true,	-- // Counterspell
	[96231] = true,	-- // Rebuke
	[15487] = true,	-- // Silence
	[1766] = true,	-- // Kick
	[57994] = true,	-- // Wind Shear
	[6552] = true,	-- // Pummel
	[19647] = true,	-- // Spell Lock https://www.wowhead.com/spell=19647
	[132409] = true, -- Spell Lock (demon sacrificed) https://www.wowhead.com/spell=132409
	[116705] = true, -- // Spear Hand Strike
	[115781] = true,	-- // Optical Blast
	[183752] = true,	-- // Consume Magic
	[187707] = true, -- // Muzzle
	[91802] = true,	-- // Shambling Rush https://www.wowhead.com/spell=91802/shambling-rush
	[212619] = true, -- // Вызов охотника Скверны
	[78675] = true,	-- // Столп солнечного света
	[351338] = true,	-- Quell https://www.wowhead.com/spell=351338
	[147362] = true,	-- Counter Shot
};

addonTable.Trinkets = {
	[59752] = true,
	[7744] = true,
	[336126] = true,
	[283167] = true,
};

-- // spells that reduce cooldown of other spells
do

	local BIG_REDUCTION = 4*1000*1000;

	local allRogueSpells = {};
	for spellId in pairs(addonTable.CDs["ROGUE"]) do
		allRogueSpells[#allRogueSpells+1] = spellId;
	end

	addonTable.Reductions = {
		[195676] = { -- // Displacement https://www.wowhead.com/spell=195676/%D1%81%D0%BC%D0%B5%D1%89%D0%B5%D0%BD%D0%B8%D0%B5
			["reduction"] = BIG_REDUCTION,
			["spells"] = { 1953 }, -- // Blink
		},
		[235219] = { -- // Cold Snap https://www.wowhead.com/spell=235219/%D1%85%D0%BE%D0%BB%D0%BE%D0%B4%D0%BD%D0%B0%D1%8F-%D1%85%D0%B2%D0%B0%D1%82%D0%BA%D0%B0
			["reduction"] = BIG_REDUCTION,
			["spells"] = {
				122,			-- // Frost Nova
				120,			-- // Cone of Cold
				11426,			-- // Ice Barrier
				45438,			-- // Ice Block
			},
		},
		[115203] = { -- // Fortifying Brew https://www.wowhead.com/spell=115203/fortifying-brew
			["reduction"] = 120,
			["spells"] = {
				243435,			-- // Fortifying Brew https://www.wowhead.com/spell=243435/fortifying-brew
			},
		},
		[585] = {	-- Кара https://www.wowhead.com/spell=585/%D0%BA%D0%B0%D1%80%D0%B0
			["reduction"] = 4,
			["spells"] = {
				88625,	-- Holy Word: Chastise https://www.wowhead.com/spell=88625
			},
		},
		[200183] = {	-- Apotheosis https://www.wowhead.com/spell=200183
			["reduction"] = BIG_REDUCTION,
			["spells"] = {
				2050,	-- Holy Word: Serenity https://www.wowhead.com/spell=2050
				88625,	-- Holy Word: Chastise https://www.wowhead.com/spell=88625
			},
		},
		[1856] = {	-- Vanish https://www.wowhead.com/spell=1856
			["reduction"] = 15,
			["spells"] = allRogueSpells,
		},
		[143914] = {	-- Readiness https://www.wowhead.com/spell=143914
			["reduction"] = BIG_REDUCTION,
			["spells"] = {
				13750,
				51690,
				121471,
				31224,
				5277,
				212182,
				359053,
			},
		},
	};

end