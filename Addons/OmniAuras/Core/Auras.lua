local E = unpack(select(2, ...))

-- [spellId] = { [1]=class,	[2]=type,	[3]=CLASS_SORT_ORDER,	[4]=merged,	[5]=duration,	[6]=iconTexture	}
E.aura_db = {
	["INTERRUPT"] = {
		--[[ XXX Do NOT merge Ids! ]]
		[47528 ] = { "softCC",	"interrupt",	2,	nil,	3,	237527	},	-- Mind Freeze
		[91807 ] = { "softCC",	"interrupt",	2,	nil,	2,	237569	},	-- Shambling Rush - interrupt uId (castId=Leap 47482)
		[183752] = { "softCC",	"interrupt",	12,	nil,	3,	1305153	},	-- Disrupt
		[93985 ] = { "softCC",	"interrupt",	7,	nil,	3,	236946	},	-- Skull Bash 4 - interrupt uId (castId=106839)	-- Patch 10.1 duration shortened for a lot of interrupts
		[351338] = { "softCC",	"interrupt",	13,	nil,	4,	4622469	},	-- Quell
		[147362] = { "softCC",	"interrupt",	11,	nil,	3,	249170	},	-- Countershot
		[187707] = { "softCC",	"interrupt",	11,	nil,	3,	1376045	},	-- Muzzle
		[2139  ] = { "softCC",	"interrupt",	9,	nil,	5,	135856	},	-- Counterspell 6
		[116705] = { "softCC",	"interrupt",	4,	nil,	3,	608940	},	-- Spear Hand Strike 4
		[1766  ] = { "softCC",	"interrupt",	8,	nil,	3,	132219	},	-- Kick 5
		[57994 ] = { "softCC",	"interrupt",	6,	nil,	2,	136018	},	-- Wind Shear 3
		[96231 ] = { "softCC",	"interrupt",	3,	nil,	3,	523893	},	-- Rebuke 4
		[19647 ] = { "softCC",	"interrupt",	10,	nil,	5,	136174	},	-- Spell Lock 6 - nl and Command Demon fires the same interrupt uId
		[132409] = { "softCC",	"interrupt",	10,	nil,	5,	136174	},	-- Spell Lock 6 (Grimoire of Sacrifice) - interrupt uId
--		[212619] = { "softCC",	"interrupt",	10,	nil,	6,	136174	},	-- Call Felhunter - interrupt uId	-- removed
		[347008] = { "softCC",	"interrupt",	10,	nil,	4,	236316	},	-- Axe Toss 6 (Felguard) - interrupt uId
		[6552  ] = { "softCC",	"interrupt",	1,	nil,	3,	132938	},	-- Pummel 4
		-- interrupt + silence
		-- NOTE: Solar Beam will show 2 icons simultaneously for the interrupt and silence (no duration) effect. This is intentional.
		[97547 ] = { "softCC",	"interrupt",	7,	nil,	5,	252188	},	-- Solar Beam - interrupt uId (PvE and PvP) - castId is 78675 - silence debuffId=81261
		-- NOTE: Ignore interrupt and track silence effect only since mobs do not dispel
--		[220543] = { "softCC",	"interrupt",	5,	nil,	4,	458230	},	-- Silence - interrupt uId (PvE only) - Silence debuffId=15487
		-- NOTE: Ignore PvP interrupt by Avenger's Shield w/ Shield of Virtue as it doesn't fire SPELL_INTERRUPT - castId=31935, Silence debuffId=217824
--		[31935 ] = { "softCC",	"interrupt",	3,	nil,	3,	135874	},	-- Avenger's Shield (PvE only) - Silence debuffId = castId = interruptId = 31935
	},
	["HARMFUL"] = {
		-- Priority Debuffs
--		[207736] = { "hardCC",	"priorityDebuff",	8	},	-- Shadowy Duel (player debuff=target debuff)
		[212183] = { "hardCC",	"priorityDebuff",	8,	359053	},	-- Smoke Bomb (player debuff=target debuff, old id)

		-- Stun
		[377048] = { "hardCC",	"stun",	2,	334693	},	-- Absolute Zero - (DF Talent, SL Runeforge)
		[108194] = { "hardCC",	"stun",	2,	221562	},	-- Asphyxiate (DPS, Blood DK	-- removed)
--		[287254] = { "hardCC",	"stun",	2	},	-- Dead of Winter (196770 buff)
		[91800 ] = { "hardCC",	"stun",	2	},	-- Gnaw
		[91797 ] = { "hardCC",	"stun",	2	},	-- Monstrous Blow (Dark Transformation Ghoul)
		[210141] = { "hardCC",	"stun",	2	},	-- Zombie Explosion
		[179057] = { "hardCC",	"stun",	12	},	-- Chaos Nova
		[213491] = { "hardCC",	"stun",	12	},	-- Demonic Trample (1s, no DR, PVE only)
		[211881] = { "hardCC",	"stun",	12	},	-- Fel Eruption
		[205630] = { "hardCC",	"stun",	12,	208618	},	-- Illidan's Grasp (V) - (primary stun, aoe stun on 2ndary targets - removed in 11.1)
		[200166] = { "hardCC",	"stun",	12	},	-- Metamorphosis (PVE only)
		[5211  ] = { "hardCC",	"stun",	7	},	-- Mighty Bash
		[203123] = { "hardCC",	"stun",	7	},	-- Maim
		[163505] = { "hardCC",	"stun",	7	},	-- Rake
		[202244] = { "hardCC",	"stun",	7	},	-- Overrun (knockdown stun)
		[408544] = { "hardCC",	"stun",	13	},	-- Seismic Slam
		[372245] = { "hardCC",	"stun",	13	},	-- Terror of the Skies
		[117526] = { "hardCC",	"stun",	11	},	-- Binding Shot (root in BFA) back to a stun in DF
		[357021] = { "hardCC",	"stun",	11	},	-- Consecutive Concussion (HT)
		[24394 ] = { "hardCC",	"stun",	11	},	-- Intimidation
		[449700] = { "hardCC",	"stun",	9,	473291	},	-- Gravity Lapse (pve version stun)
		[389831] = { "hardCC",	"stun",	9	},	-- Snowdrift
		[202346] = { "hardCC",	"stun",	4	},	-- Double Barrel
		[119381] = { "hardCC",	"stun",	4	},	-- Leg Sweep
		[385149] = { "hardCC",	"stun",	3	},	-- Exorcism (Demon and Undead only)
		[853   ] = { "hardCC",	"stun",	3	},	-- Hammer of Justice
		[255941] = { "hardCC",	"stun",	3	},	-- Wake of Ashes (Demon and Undead only)
		[64044 ] = { "hardCC",	"stun",	5	},	-- Psychic Horror
--		[199804] = { "hardCC",	"stun",	8	},	-- Between the Eyes	-- stun effect removed
		[1833  ] = { "hardCC",	"stun",	8	},	-- Cheap Shot
		[408   ] = { "hardCC",	"stun",	8	},	-- Kidney Shot
--		[204399] = { "hardCC",	"stun",	6	},	-- Earthfury (HT)	-- removed
		[77505 ] = { "hardCC",	"stun",	6	},	-- Earthquake (no DR)
		[305485] = { "hardCC",	"stun",	6	},	-- Lightning Lasso
		[118345] = { "hardCC",	"stun",	6	},	-- Pulverize (Earth Elemental w/ Primal Elementalist)
		[118905] = { "hardCC",	"stun",	6	},	-- Static Charge
		[89766 ] = { "hardCC",	"stun",	10	},	-- Axe Toss
		[22703 ] = { "hardCC",	"stun",	10	},	-- Infernal Awakening (Infernal)
		[213688] = { "hardCC",	"stun",	10	},	-- Fel Cleave (Fel Lord)
		[30283 ] = { "hardCC",	"stun",	10	},	-- Shadowfury
		[385954] = { "hardCC",	"stun",	1	},	-- Shield Charge
		[132168] = { "hardCC",	"stun",	1	},	-- Shockwave
		[132169] = { "hardCC",	"stun",	1	},	-- Storm Bolt
--		[199085] = { "hardCC",	"stun",	1	},	-- Warpath (P)
		[255723] = { "hardCC",	"stun",		},	-- Bull Rush (knockdown stun)
		[287712] = { "hardCC",	"stun",		},	-- Haymaker
		[20549] = { "hardCC",	"stun",		},	-- War Stomp
--		[325886] = { "hardCC",	"stun",	1,	326062	},	-- Ancient Aftershock (SL Covenant 1s, periodic stun while standing on it)
--		[325321] = { "hardCC",	"stun",		},	-- Wild Hunt's Charge (SL NF soulbind ability)
--		[332423] = { "hardCC",	"stun",		},	-- Sparkling Driftglobe Core (SL Kyrian - Soulbind Mikanikos)

		-- Disorient
		[207167] = { "hardCC",	"disorient",	2	},	-- Blinding Sleet
		[207685] = { "hardCC",	"disorient",	12	},	-- Sigil of Misery (V)
		[33786 ] = { "hardCC",	"disorient",	7	},	-- Cyclone (R/F, Balance)	-- Balance Id 209753 removed in DF
		[360806] = { "hardCC",	"disorient",	13	},	-- Sleep Walk
		[1513  ] = { "hardCC",	"disorient",	11	},	-- Scare Beast
		[31661 ] = { "hardCC",	"disorient",	9	},	-- Dragon's Breath
		[202274] = { "hardCC",	"disorient",	4	},	-- Hot Trub (Incendiary Brew (BM))
		[198909] = { "hardCC",	"disorient",	4	},	-- Song of Chi-ji
		[105421] = { "hardCC",	"disorient",	3	},	-- Blinding Light
		[10326 ] = { "hardCC",	"disorient",	3	},	-- Turn Evil
		[205364] = { "hardCC",	"disorient",	5	},	-- Dominate Mind (PVE)
--		[226943] = { "hardCC",	"disorient",	5	},	-- Mind Bomb (disorient in BFA)	-- removed
		[605   ] = { "hardCC",	"disorient",	5	},	-- Mind Control
		[8122  ] = { "hardCC",	"disorient",	5	},	-- Psychic Scream
		[358861] = { "hardCC",	"disorient",	5	},	-- Void Volley: Horrify
		[2094  ] = { "hardCC",	"disorient",	8	},	-- Blind
		[118699] = { "hardCC",	"disorient",	10,	130616	},	-- Fear (pre, DF)
		[5484  ] = { "hardCC",	"disorient",	10	},	-- Howl of Terror
		[6358  ] = { "hardCC",	"disorient",	10,	{261589,115268}	},	-- Seduction (Grimoire, Mesmerize)
		[1098  ] = { "hardCC",	"disorient",	10	},	-- Subjugate Demon
		[5246  ] = { "hardCC",	"disorient",	1,	{316593,316595}	},	-- Intimidating Shout (Menace (HT - primary), secondary)
		[388673] = { "hardCC",	"disorient",		},	-- Dragonrider's Initiative - Dragonriding
--		[331866] = { "hardCC",	"disorient",		},	-- Agent of Chaos (SL Venthyr - Soulbind Nadjia)
--		[206961] = { "hardCC",	"disorient",		},	-- Tremble Before Me (SL Runeforge - Phearamones)
--		[324263] = { "hardCC",	"disorient",		},	-- Sulfuric Emission (SL Necrolord - Soulbind Emeni)

		-- Incapacitate
		[217832] = { "hardCC",	"incapacitate",	12,	221527	},	-- Imprison (nl, HT - undispellable)
		[2637  ] = { "hardCC",	"incapacitate",	7	},	-- Hibernate
		[99    ] = { "hardCC",	"incapacitate",	7	},	-- Incapacitating Roar
		[3355  ] = { "hardCC",	"incapacitate",	11,	203337	},	-- Freezing Trap (nl, SV HT - Diamond Ice)
		[213691] = { "hardCC",	"incapacitate",	11	},	-- Scatter Shot
		[118   ] = { "hardCC",	"incapacitate",	9,	{61305,28272,61721,61780,126819,161353,161354,161355,161372,28271,61025,277787,277792,321395,391622,383121,460392}	},	-- Polymorph (sheep, black cat, pig, rabbit, turkey, porcupine, polar bear cub, monkey, penguin, peacock, turtle, serpent, direhorn, bumblebee, mawrat, duck, mass polymorph, mosswool)
		[82691 ] = { "hardCC",	"incapacitate",	9	},	-- Ring of Frost
		[115078] = { "hardCC",	"incapacitate",	4	},	-- Paralysis
		[20066 ] = { "hardCC",	"incapacitate",	3	},	-- Repentance
		[200196] = { "hardCC",	"incapacitate",	5,	200200	},	-- Holy Word: Chastise (nl, HT - stun version)
		[9484  ] = { "hardCC",	"incapacitate",	5	},	-- Shackle Undead
		[87204 ] = { "hardCC",	"incapacitate",	5	},	-- Sin and Punishment (no DR)
		[1776  ] = { "hardCC",	"incapacitate",	8	},	-- Gouge
		[6770  ] = { "hardCC",	"incapacitate",	8	},	-- Sap
		[51514 ] = { "hardCC",	"incapacitate",	6,	{211015,210873,211004,211010,277784,269352,277778,196942,309328}	},	-- Hex (cockroach, compy, spider, snake, wicker mongrel, skeletal hatchling, zandalari tendonripper, voodoo mastery(HT), living honey)
		[197214] = { "hardCC",	"incapacitate",	6	},	-- Sundering
		[710   ] = { "hardCC",	"incapacitate",	10	},	-- Banish
		[6789  ] = { "hardCC",	"incapacitate",	10	},	-- Mortal Coil
		[107079] = { "hardCC",	"incapacitate",		},	-- Quaking Palm

		-- Silence
		[47476 ] = { "softCC",	"silence",	2	},	-- Strangulate
		[374776] = { "softCC",	"silence",	2	},	-- Tightening Grasp
		[204490] = { "softCC",	"silence",	12	},	-- Sigil of Silence (V)
		[410065] = { "softCC",	"silence",	7	},	-- Reactive Resin
		[356727] = { "softCC",	"silence",	11	},	-- Spider Venom (9.1+ HT - Chimaeral Sting)
		[1330  ] = { "softCC",	"silence",	8	},	-- Garrote - Silence
		[196364] = { "softCC",	"silence",	10	},	-- Unstable Affliction (dispel)
--		[317589] = { "softCC",	"silence",		},	-- Tormenting Backlash (SL Venthyr Sig)
		[214459] = { "softCC",	"silence",		},	-- Choking Flames (trinket: Ember of Nullification, 136978)
		-- interrupt + silence
		[81261 ] = { "softCC",	"silence",	7	},	-- Solar Beam (no DR?, no duration on silence effect)
		[15487 ] = { "softCC",	"silence",	5	},	-- Silence
		[31935 ] = { "softCC",	"silence",	3	},	-- Avenger's Shield (PVE)
		[217824] = { "softCC",	"silence",	3	},	-- Shield of Virtue
--		[392061] = { "softCC",	"silence",	11	},	-- Wailing Arrow 11.0 (PVE)

		-- Disarm/etc
		[209749] = { "disarmRoot",	"disarm",	7	},	-- Faerie Swarm
		[445134] = { "disarmRoot",	"disarm",	13	},	-- Shape of Flame (Flameshaper hero talent)
		[233759] = { "disarmRoot",	"disarm",	4	},	-- Grapple Weapon
		[407032] = { "disarmRoot",	"disarm",	11,	407031	},	-- Sticky Tar Bomb (1', 2')	-- Patch 10.1 new
		[410201] = { "disarmRoot",	"disarm",	3	},	-- Searing Glare	-- Patch 10.1 new
		[207777] = { "disarmRoot",	"disarm",	8	},	-- Dismantle
		[236077] = { "disarmRoot",	"disarm",	1,	236236	},	-- Disarm (A, P	-- removed?)

		-- Roots
		[204085] = { "disarmRoot",	"root",	2,	233395	},	-- Deathchill (by Chains of Ice, by Remorseless Winter)
		[454787] = { "disarmRoot",	"root",	2	},	-- Ice Prison
		[370970] = { "disarmRoot",	"root",	12,	323996	},	-- The Hunt (DF Talent, SL Covenant)
		[339   ] = { "disarmRoot",	"root",	7,	{170855,247564,235963,460614}	},	-- Entangling Roots (Nature's Grasp (old), Nature's Grasp, Earthen Grasp (undispelable Feral HT, hit chance -80%, Storm Bolt misses)), Ursol's Vortex w/ Entangling Vortex (hero talent)
		[45334 ] = { "disarmRoot",	"root",	7	},	-- Immobilized (Wild Charge, no DR)
		[102359] = { "disarmRoot",	"root",	7	},	-- Mass Entanglement
		[127797] = { "disarmRoot",	"root",	7	},	-- Ursol's Vortex
		[355689] = { "disarmRoot",	"root",	13	},	-- Landslide
		[451517] = { "disarmRoot",	"root",	11	},	-- Catch Out (Sentinel hero talent) [rooted when attacking while affected with your Sentinel debuff 450387] 1m icd
		[393456] = { "disarmRoot",	"root",	11	},	-- Entrapment (Tar Trap)
		[190925] = { "disarmRoot",	"root",	11	},	-- Harpoon
--		[162480] = { "disarmRoot",	"root",	11	},	-- Steel Trap	-- 11.0 removed
--		[201158] = { "disarmRoot",	"root",	11	},	-- Super Sticky Tar	-- removed
		[212638] = { "disarmRoot",	"root",	11	},	-- Tracker's Net (undispelable SV HT) - hit chance -80%
		[33395 ] = { "disarmRoot",	"root",	9	},	-- Freeze (pet)
		[386770] = { "disarmRoot",	"root",	9	},	-- Freezing Cold
		[122   ] = { "disarmRoot",	"root",	9	},	-- Frost Nova
		[378760] = { "disarmRoot",	"root",	9,	198121	},	-- Frostbite (DF version, old removed HT)
		[228600] = { "disarmRoot",	"root",	9	},	-- Glacial Spike
		[473290] = { "disarmRoot",	"root",	9	},	-- Gravity Lapse (pvp version root)
		[157997] = { "disarmRoot",	"root",	9	},	-- Ice Nova (no DR)
		[324382] = { "disarmRoot",	"root",	4	},	-- Clash
		[116706] = { "disarmRoot",	"root",	4	},	-- Disable
		[201787] = { "disarmRoot",	"root",	4	},	-- Heavy-Handed Strikes (90% snare debuff) (HT Turbo Fist) (player also parry all attacks - no buff is shown)
		[114404] = { "disarmRoot",	"root",	5	},	-- Void Tendrils
		[64695 ] = { "disarmRoot",	"root",	6	},	-- Earthgrab
		[285515] = { "disarmRoot",	"root",	6	},	-- Surge of Power
		[356738] = { "disarmRoot",	"root",	6	},	-- Earth Unleashed (Unleash Shield)
--		[233582] = { "disarmRoot",	"root",	10	},	-- Entrenched in Flame (does not break with dmg)	-- 9.0.1 removed
		[105771] = { "disarmRoot",	"root",	1	},	-- Charge (Warrior) (no DR?)
--		[356356] = { "disarmRoot",	"root",	1	},	-- Warbringer
		[376080] = { "disarmRoot",	"root",	1,	307871	},	-- Spear of Bastion (DF Talent, SL Kyrian)
		[199042] = { "disarmRoot",	"root",	1	},	-- Thunderstruck
--		[424752] = { "disarmRoot",	"root",	1	},	-- Piercing Howl (w/ Battlefield Commander pvp talent)	-- 11.0 root effect removed
--		[354051] = { "disarmRoot",	"root",		},	-- Nimble Steps (SL soulbind)

		-- Dispel prio / protection
		[343294] = { "debuff",	"dispel",	2	},	-- Soul Reaper (Magic)
		[383005] = { "debuff",	"dispel",	13	},	-- Chrono Loop (Magic)
		[372048] = { "debuff",	"dispel",	13	},	-- Oppressing Roar (inc cc duration 50%) (Magic)
		[202347] = { "debuff",	"dispel",	7	},	-- Stellar Flare (Magic)
		[34914 ] = { "debuff",	"dispel",	5	},	-- Vampiric Touch (Magic)
		[375901] = { "debuff",	"dispel",	5,	323673	},	-- Mindgames (DF Talent, SL Covenant) (Magic)
--		[205369] = { "debuff",	"dispel",	5	},	-- Mind Bomb (trigger) (Magic)	-- removed
		[360194] = { "debuff",	"dispel",	8	},	-- Deathmark (Physical Bleed)
		[188389] = { "debuff",	"dispel",	6	},	-- Flame Shock (Magic)
		[316099] = { "debuff",	"dispel",	10,	342938	},	-- Unstable Affliction (onlt 1 can be applied in SL, HT - Rampant Afflictions) (Magic)
		[157736] = { "debuff",	"dispel",	10	},	-- Immolate

		-- reduced healing recieved
		[48743 ] = { "debuff",	"reduceHealingReceived",	2	},	-- Death Pact
		[356528] = { "debuff",	"reduceHealingReceived",	2	},	-- Necrotic Wound (healing absorb=effective MS)
		[356608] = { "debuff",	"reduceHealingReceived",	12	},	-- Mortal Dance (25% reduced healing recieved) - 8s cd=always up like warr MS
		[199845] = { "debuff",	"reduceHealingReceived",	5	},	-- Psyflay (50% reduced healing recieved)
		[319504] = { "debuff",	"reduceHealingReceived",	8	},	-- Shiv (nl Shiv and Shiv w/ Hemotoxin HT(354124)-30% healing reduc. has same debuffId. only the tt changes)
		[200587] = { "debuff",	"reduceHealingReceived",	10	},	-- Fel Fissure (25% reduced healing recieved)
		[30213 ] = { "debuff",	"reduceHealingReceived",	10	},	-- Legion Strike (20%, 100% uptime)
		[410598] = { "debuff",	"reduceHealingReceived",	10	},	-- Soul Rip (25% reduced healing recieved and 25% reduced dmg done)	-- Patch 10.1 new
		[354788] = { "debuff",	"reduceHealingReceived",	1	},	-- Slaughterhouse (8stack=40% reduced healing recieved, 1 rampage=4hits=4stacks)
		[115804] = { "debuff",	"reduceHealingReceived",	1	},	-- Mortal Wounds (Warrior nl MS debuff, Hunter pet)
			[198819] = { "debuff",	"reduceHealingReceived",	1	},	-- Mortal Strike (MS w/ Sharpen Blade debuff - 50% reduced healing recieved)	-- BUG? Mortal Wounds TT is always 50%

		-- increased damage taken
		[320338] = { "debuff",	"increaseDamageTaken",	12	},	-- Essence Break
		[321538] = { "debuff",	"increaseDamageTaken",	11	},	-- Bloodshed
		[441172] = { "debuff",	"increaseDamageTaken",	13	},	-- Melt Armor (Scalecommander hero talent) [Damage taken from Essence abilities and bombardments increased by 20%.]
		[409560] = { "debuff",	"increaseDamageTaken",	13	},	-- Temporal Wound
--		[375893] = { "debuff",	"increaseDamageTaken",	11	},	-- Death Chakram	-- 11.0 removed
--		[376103] = { "debuff",	"increaseDamageTaken",	9	},	-- Radiant Spark	-- 11.0 removed
		[411038] = { "debuff",	"increaseDamageTaken",	4	},	-- Sphere of Despair	-- Patch 10.1 new
--		[344021] = { "debuff",	"increaseDamageTaken",	4,	393047	},	-- Skyreach (SL Runeforge - Keefer's Skyreach, DF Talent)
		[343527] = { "debuff",	"increaseDamageTaken",	3	},	-- Execution Sentence (suffer 30% of dmg taken as Holy dmg)
		[343721] = { "debuff",	"increaseDamageTaken",	3	},	-- Final Reckoning (50% inc dmg taken by the paladin)
		[214621] = { "debuff",	"increaseDamageTaken",	5	},	-- Schism
		[196937] = { "debuff",	"increaseDamageTaken",	8	},	-- Ghostly Strike
--		[79140 ] = { "debuff",	"increaseDamageTaken",	8	},	-- Vendetta	-- removed
		[48181 ] = { "debuff",	"increaseDamageTaken",	10	},	-- Haunt (Magic)
--		[196414] = { "debuff",	"increaseDamageTaken",	10	},	-- Eradication (10% after chaos bolt/shadow burn)	-- removed
		[208086] = { "debuff",	"increaseDamageTaken",	1	},	-- Colossus Smash (Warbreaker applies same buff)
		[447513] = { "debuff",	"increaseDamageTaken",	1	},	-- Wrecked (Colossus hero talent) [Taking 10% increased damage from $auracaster. Dealing 5.0% less damage to $auracaster.]

		-- reduced damage/healing done
		[207771] = { "debuff",	"reduceDamageHealingDone",	12	},	-- Fiery Brand (40% less dmg)
--		[200947] = { "debuff",	"reduceDamageHealingDone",	7	},	-- High Winds (30% reduced healing done) (Magic)	-- 11.0 redesigned
		[441201] = { "debuff",	"reduceDamageHealingDone",	13	},	-- Menacing Presence (Scalecommander hero talent) [Damage done to $auracaster reduced by 15%]
		[356730] = { "debuff",	"reduceDamageHealingDone",	11	},	-- Viper Venom (20% reduced damage and healing done) (Magic)
		[2812  ] = { "debuff",	"reduceDamageHealingDone",	3	},	-- Denounce (Magic)
--		[212150] = { "debuff",	"reduceDamageHealingDone",	8	},	-- Cheap Tricks (-75% hit chance)	-- removed
		[256148] = { "debuff",	"reduceDamageHealingDone",	8	},	-- Iron Wire (15% less dmg)
		[356824] = { "debuff",	"reduceDamageHealingDone",	6	},	-- Water Unleashed (Unleash Shield) 50% reduced dmg healing
		[221715] = { "debuff",	"reduceDamageHealingDone",	10	},	-- Essence Drain (5stack=25% red damage to warlock) (Magic)
		[1160  ] = { "debuff",	"reduceDamageHealingDone",	1	},	-- Demoralizing Shout
		[236273] = { "debuff",	"reduceDamageHealingDone",	1	},	-- Duel (on target only, no caster aura)

		-- buff but added as a debuff
--		[343142] = { "debuff",	"offensiveDebuff",	8	},	-- Dreadblades	-- 10.2 removed

		-- Snare (70%+)
		[45524 ] = { "debuff",	"snare",	2	},	-- Chains of Ice
		[204206] = { "debuff",	"snare",	2	},	-- Chilled (Chill Streak)
		[273977] = { "debuff",	"snare",	2	},	-- Grip of the Dead
		[204843] = { "debuff",	"snare",	12	},	-- Sigil of Chains
		[370898] = { "debuff",	"snare",	13	},	-- Permeating Chill	-- Patch 10.1 new 70->50%	-- Crippling Force (pvp talent) makes it up to 80% only the tt changes
		[368970] = { "debuff",	"snare",	13	},	-- Tail Swipe (4s - 70%)
		[357214] = { "debuff",	"snare",	13	},	-- Wing Buffet (4s - 70%)
		[356723] = { "debuff",	"snare",	11	},	-- Scorpid Venom (3s - 90%)
		[157981] = { "debuff",	"snare",	9	},	-- Blast Wave
		[212792] = { "debuff",	"snare",	9	},	-- Cone of Cold
		[228354] = { "debuff",	"snare",	9	},	-- Flurry
		[390614] = { "debuff",	"snare",	9	},	-- Frost Bomb
		[1220758] = { "debuff",	"snare",	9	},	-- Overpowered Barriere (Frost)
		[205021] = { "debuff",	"snare",	9	},	-- Ray of Frost (60% snare + 10% per tick)
		[228358] = { "debuff",	"snare",	9	},	-- Winter's Chill (taking damage from Mage's spells as if frozen.)
		[451210] = { "debuff",	"snare",	5	},	-- No Escape (Entropic Rift - Voidweaver hero talent)
		[354896] = { "debuff",	"snare",	8	},	-- Creeping Venom (90% - 5% snare per stack-max 18 stacks-when moving for 3s. old 198097 damaged when moving) (Poison)
		[115196] = { "debuff",	"snare",	8	},	-- Crippling Poison by Shiv (70% snare) (3409: Crippling Poison - 50% snare)
		[384069] = { "debuff",	"snare",	10	},	-- Shadowflame
		[12323 ] = { "debuff",	"snare",	1	},	-- Piercing Howl
		[424597] = { "debuff",	"snare",	1	},	-- Storm of Destruction
--		[320267] = { "debuff",	"snare",		},	-- Soothing Voice (SL Soulbind)
		-- 60%
		[470194] = { "debuff",	"snare",	6	},	-- Ice Strike (50%, 60% in PvP - March 25, 2025 Hotfix)
		-- 50%
		-- [232559] = { "debuff",	"snare",	1	},	-- Thorns
		-- [205708] = { "debuff",	"snare",	9	},	-- Chilled
		-- [403695] = { "debuff",	"snare",	3	},	-- Truth's Wake

		-- Misc debuffs (Misc.)
		[288849] = { "debuff",	"misc",	2	},	-- Crypt Fever (HT - Necromancer's Bargain=Apocalypse used, healing spells cast on this target refreshes duration)
		[77606 ] = { "debuff",	"misc",	2	},	-- Dark Simulacrum
		[377540] = { "debuff",	"misc",	2	},	-- Death Rot
		[434765] = { "debuff",	"misc",	2	},	-- Reaper's Mark (Deathbringer hero talent, stack)
--		[206649] = { "debuff",	"misc",	12	},	-- Eye of Leotheras (casting=dmg) (Magic)	-- removed
		[274838] = { "debuff",	"misc",	7	},	-- Feral Frenzy (bleed)
		[410063] = { "debuff",	"misc",	7	},	-- Reactive Resin (stack)
		[131894] = { "debuff",	"misc",	11	},	-- A Murder of Crows
		[117405] = { "debuff",	"misc",	11	},	-- Binding Shot (trigger)
		[209967] = { "debuff",	"misc",	11	},	-- Dire Beast: Basilisk
		[212431] = { "debuff",	"misc",	11	},	-- Explosive Shot
--		[324149] = { "debuff",	"misc",	11	},	-- Flayed Shot (SL Venthyr)
		[257284] = { "debuff",	"misc",	11	},	-- Hunter's Mark (Magic)
		[459805] = { "debuff",	"misc",	11	},	-- Wailing Arrow (11.0 stack)
		[390612] = { "debuff",	"misc",	9	},	-- Frost Bomb (trigger)
		[217694] = { "debuff",	"misc",	9	},	-- Living Bomb (trigger)
		[210824] = { "debuff",	"misc",	9	},	-- Touch of the Magi
		[122470] = { "debuff",	"misc",	4	},	-- Touch of Karma (debuff on target - casted on target)
		[124280] = { "debuff",	"misc",	4	},	-- Touch of Karma (debuff on target - dmg dot) (Magic)
		[199450] = { "debuff",	"misc",	3	},	-- Blessing of Sacrifice w/ Ultimate Sacrifice (caster debuff)
		[335467] = { "debuff",	"misc",	5	},	-- Devouring Plague (Disease)
		[453   ] = { "debuff",	"misc",	5	},	-- Mind Soothe (npca stuff)
		[322460] = { "debuff",	"misc",	5,	{322461,322462,322442,322457,322458,322459,322464,322463,394902}	},	-- Thoughtstolen (Vampiric Touch, penance, renew, rejuv, blessing of freedom, renewing mist, frost shock, polymorph, fear, living flame)
--		[325203] = { "debuff",	"misc",	5	},	-- Unholy Transfusion (SL Covenant - heals attacker) (Disease)
		[263165] = { "debuff",	"misc",	5	},	-- Void Torrent (A) buff=debuff
		[198688] = { "debuff",	"misc",	8	},	-- Dagger in the Dark (Rogue near you)
		[457129] = { "debuff",	"misc",	8	},	-- Deathstalker's Mark (Deathstalker hero talent, stacks)
		[384631] = { "debuff",	"misc",	8	},	-- Flagellation (debuffId on target == buffId on caster)
		[385627] = { "debuff",	"misc",	8	},	-- Kingsbane
		[385408] = { "debuff",	"misc",	8,	328305	},	-- Sepsis (Poison)	-- (DF version, SL Covenant)
		[208997] = { "debuff",	"misc",	6	},	-- Counterstrike Totem
--		[199954] = { "debuff",	"misc",	10	},	-- Bane of Fragility (-15% cmax health) (curse)	-- removed
		[200548] = { "debuff",	"misc",	10	},	-- Bane of Havoc
--		[234877] = { "debuff",	"misc",	10	},	-- Bane of Shadows (Curse)	-- removed
--		[334275] = { "debuff",	"misc",	10	},	-- Curse of Exhaustion (50% snare)
		[1714  ] = { "debuff",	"misc",	10	},	-- Curse of Tongues (30% cast time, 20s in pvp)
		[702   ] = { "debuff",	"misc",	10	},	-- Curse of Weakness (20% attack time, 20s in pvp)
--		[264106] = { "debuff",	"misc",	10	},	-- Deathbolt	-- removed 10.1.5
		[212580] = { "debuff",	"misc",	10	},	-- Eye of the Observer (cast=dmg)
		[80240 ] = { "debuff",	"misc",	10	},	-- Havoc (DF Rolling Havoc passive applies the same Id) (Curse)
		[417537] = { "debuff",	"misc",	10	},	-- Oblivion (channeled)
		[386997] = { "debuff",	"misc",	10,	325640	},	-- Soul Rot (DF Talent, SL Covenant) - dot + multitarget drain life (Magic)
		[397364] = { "debuff",	"misc",	1	},	-- Thunderous Roar

		-- on cd (these are prioritised by blizzard)
		[123981] = { "base",	"onCd",	2	},	-- Perdition
		[209261] = { "base",	"onCd",	12	},	-- Uncontained Fel
		[87023 ] = { "base",	"onCd",	9	},	-- Cauterize (6s burning phase)
		[87024 ] = { "base",	"onCd",	9	},	-- Cauterized (5min base) both are applied at the same time
		[41425 ] = { "base",	"onCd",	9	},	-- Hypothermia
		[393879] = { "base",	"onCd",	3	},	-- Gift of the Golden Val'kyr
		[211319] = { "base",	"onCd",	5	},	-- Restitution
		[45181 ] = { "base",	"onCd",	8	},	-- Cheated Death
		[336139] = { "base",	"onCd",		},	-- Adapted
		[113942] = { "base",	"onCd",		},	-- Demonic Gateway
		[157131] = { "base",	"onCd",		},	-- Recently Saved by the Light
		[25771 ] = { "base",	"onCd",		},	-- Forbearance
--		[320227] = { "base",	"onCd",		},	-- Depleted Shell (SL soulbind - Podtender)
		[417069] = { "base",	"onCd",		},	-- Prophetic Stonescales (trinket 10.1.5~)
	},
	["HELPFUL"] = {
		-- Priority Buff
		[369162] = { "immunity",	"immunity",	nil,	{396920,314646,452384}	},	-- Drink (DF:Azure Leywine (Inn item), DF:Delicious Dragon Spittle (Crafted), SL, TWW)
		[167152] = { "immunity",	"immunity",		},	-- Refreshment (Conjured Mana Bun, BFA~)
		[23335 ] = { "immunity",	"immunity",	nil,	156621	},	-- Alliance Flag
		[23333 ] = { "immunity",	"immunity",	nil,	156618	},	-- Horde Flag (Warsong Gulch & Twin Peaks, WoD+?)
--		[140876] = { "immunity",	"immunity",		},	-- Alliance Mine Cart (old Deepwind Gorge)
--		[141210] = { "immunity",	"immunity",		},	-- Horde Mine Cart
		[34976 ] = { "immunity",	"immunity",		},	-- Netherstorm Flag (Eye of the Storm)
		-- Immunities
--		[362486] = { "immunity",	"immunity",	7	},	-- Keeper of the Grove (HT) -> (11.0 name change) Preserve Nature
		[378441] = { "immunity",	"immunity",	13	},	-- Time Stop (This should glow by default - makes healers waste huge healing CD)
		[186265] = { "immunity",	"immunity",	11	},	-- Aspect of the Turtle
		[45438 ] = { "immunity",	"immunity",	9	},	-- Ice Block
		[642   ] = { "immunity",	"immunity",	3	},	-- Divine Shield
--		[213602] = { "immunity",	"immunity",	5	},	-- Greater Fade	-- removed	--> Translucent Image (red dmg by 10% - buffId is the same as normal Fade 586)
		[408558] = { "immunity",	"immunity",	5	},	-- Phase Shift	-- Patch 10.1 new
		[215769] = { "immunity",	"immunity",	5	},	-- Spirit of Redemption (HT) NOTE: buffId 27827 == dead (so only track rez)
--		[211336] = { "immunity",	"immunity",	5	},	-- Archbishop Benedictus' Restitution (SL Runeforge) - golden
		[409293] = { "immunity",	"immunity",	6	},	-- Burrow	-- Patch 10.1 new

		-- Spell Immunities (includes CC)
		[48707 ] = { "spellImmunity",	"spellImmunity",	2,	{410358,444741}	},	-- Anti-Magic Shell, w/ Spellwarden (HT)	-- Patch 10.1 new	-- Horsemen's Aid (RIDER OF THE APOCALYPSE hero talent)
		[248519] = { "spellImmunity",	"spellImmunity",	11	},	-- Interlope (aura is applied on both player and pet, same id) trigger id == dmamge transfering id
		[202248] = { "spellImmunity",	"spellImmunity",	4	},	-- Guided Meditation
		[353319] = { "spellImmunity",	"spellImmunity",	4	},	-- Peaceweaver (HT)	-- doesn't provide immu w/ mindgames (revival healing will dmg you)
		[204018] = { "spellImmunity",	"spellImmunity",	3	},	-- Blessing of Spellwarding
		[31224 ] = { "spellImmunity",	"spellImmunity",	8	},	-- Cloak of Shadows
		[8178  ] = { "spellImmunity",	"spellImmunity",	6	},	-- Grounding Totem (Effect)
		[212295] = { "spellImmunity",	"spellImmunity",	10	},	-- Nether Ward
		[23920 ] = { "spellImmunity",	"spellImmunity",	1,	335255	},	-- Spell Reflection (P > all), Spell Reflection (2ndary on allies by Misshapen Mirror, Runeforge)
--		[330752] = { "spellImmunity",	"spellImmunity",		},	-- Ascendant Phial (SL Kyrian soulbind) Immune to Curse, Disease, Poison, and Bleed effects)

		-- CC Immunities
		[354610] = { "otherImmunity",	"ccImmunity",	12	},	-- Glimpse (HT)
		[403631] = { "otherImmunity",	"ccImmunity",	13,	442204	},	-- Breath of Eons (w/ Maneuverability (Scalecommander hero talent) - Perilous Fate effect is added to 409560 Temporal Wound
		[357210] = { "otherImmunity",	"ccImmunity",	13,	433874	},	-- Deep Breath (w/ Maneuverability (Scalecommander hero talent)
		[359816] = { "otherImmunity",	"ccImmunity",	13	},	-- Dream Flight
		[378464] = { "otherImmunity",	"ccImmunity",	13	},	-- Nullifying Shroud (HT)
		[213664] = { "otherImmunity",	"ccImmunity",	4,	354540	},	-- Nimble Brew (HT - BM) (DF version, old version)
		[213610] = { "otherImmunity",	"ccImmunity",	5	},	-- Holy Ward (immune cc, purgable)
		[269513] = { "otherImmunity",	"ccImmunity",	8	},	-- Death from Above
		[227847] = { "otherImmunity",	"ccImmunity",	1,	{46924,446035}	},	-- Bladestorm (A, F)
--		[362699] = { "otherImmunity",	"ccImmunity",		},	-- Gladiator's Resolve (both Echoing Resolve & Fastidious Resolve)
		[377362] = { "otherImmunity",	"ccImmunity"	},	-- Precognition (DF HT)
--		[323524] = { "otherImmunity",	"ccImmunity",		},	-- Ultimate Form (SL Necrolord soulbind)

		-- Stun Immunities
		[48792 ] = { "otherImmunity",	"stunFearSilenceImmunity",	2	},	-- Icebound Fortitude
		[206803] = { "defensive",	"stunFearSilenceImmunity",	12	},	-- Rain from Above (up) - immune to all damage, roots, and stuns.
--			[206804] = { "defensive",	"minorDefensive",	12	},	-- Rain from Above (down)
		[198144] = { "otherImmunity",	"stunFearSilenceImmunity",	9	},	-- Ice Form - immune to stun & knockback
		[328530] = { "defensive",	"stunFearSilenceImmunity",	5	},	-- Divine Ascension (up) - immune to all damage, roots, and stuns.
--		[329543] = { "defensive",	"stunFearSilenceImmunity",	5	},	-- Divine Ascension (down)

		-- Fear & Horror Immunities
		[49039 ] = { "otherImmunity",	"stunFearSilenceImmunity",	2	},	-- Lichborne
		[212704] = { "otherImmunity",	"stunFearSilenceImmunity",	11	},	-- The Beast Within
		[456499] = { "otherImmunity",	"stunFearSilenceImmunity",	3	},	-- 11.0 Absolute Serenity (pvp talent) (incap, disorient, snare, root immune)
		[18499 ] = { "otherImmunity",	"stunFearSilenceImmunity",	1	},	-- Berserker Rage
		[384100] = { "otherImmunity",	"stunFearSilenceImmunity",	1	},	-- Berserker Shout
		[1219201] = { "otherImmunity",	"stunFearSilenceImmunity",	1	},	-- Berserker Roar

		-- Silence & Interrupt Immunities
		[209584] = { "otherImmunity",	"stunFearSilenceImmunity",	4	},	-- Zen Focus Tea
		[31821 ] = { "otherImmunity",	"stunFearSilenceImmunity",	3,	317929	},	-- Aura Mastery (primary, secondary effect w/ Concentration Aura)
		[289655] = { "otherImmunity",	"stunFearSilenceImmunity",	5	},	-- Holy Word: Concentration
--		[290641] = { "otherImmunity",	"stunFearSilenceImmunity",	6	},	-- Ancestral Gift (HT)	-- removed, replaced by ^
		[378078] = { "otherImmunity",	"stunFearSilenceImmunity",	6	},	-- Spiritwalker's Aegis (DF Talent)
--		[221705] = { "otherImmunity",	"stunFearSilenceImmunity",	10	},	-- Casting Circle	-- removed
		[104773] = { "otherImmunity",	"stunFearSilenceImmunity",	10	},	-- Unending Resolve

		-- CC reducer
		[234084] = { "buff",	"ccDurationReducer",	7	},	-- Moon and Stars
		[210256] = { "buff",	"ccDurationReducer",	3	},	-- Blessing of Sanctuary
		[432496] = { "buff",	"ccDurationReducer",	3,	432502	},	-- Holy Bulwark, Sacred Weapon (Lightsmith hero talent); w/ Fear No Evil talent [Duration of Fear effects reduced by 50%], only the tt changes
		[1219209] = { "buff",	"ccDurationReducer",	1	},	-- Berserker Roar
--		[236321] = { "buff",	"ccDurationReducer",	1	},	-- War Banner
--		[332505] = { "buff",	"ccDurationReducer",	nil,	332506	},	-- Soulsteel Clamps (SL Kyrian soulbind, 5s timer when you start moving)

		-- Physical Immunities (incl. dodge & parry)
--		[210655] = { "otherImmunity",	"damageImmunity",	7	},	-- Protection of Ashamane	-- removed
		[1022  ] = { "otherImmunity",	"damageImmunity",	3	},	-- Blessing of Protection
		[5277  ] = { "otherImmunity",	"damageImmunity",	8	},	-- Evasion
--		[199754] = { "otherImmunity",	"damageImmunity",	8	},	-- Riposite	-- removed
--		[199027] = { "otherImmunity",	"damageImmunity",	8	},	-- Veil of Midnight (dodge)	-- removed (no buff in DF)
--		[210918] = { "otherImmunity",	"damageImmunity",	6	},	-- Ethereal Form	-- removed
		[118038] = { "otherImmunity",	"damageImmunity",	1	},	-- Die by the Sword
		[147833] = { "otherImmunity",	"damageImmunity",	1	},	-- Intervene
		-- Damage Immunities
		[196555] = { "otherImmunity",	"damageImmunity",	12	},	-- Netherwalk
		[202748] = { "otherImmunity",	"damageImmunity",	11	},	-- Survival tactics
--		[198111] = { "otherImmunity",	"damageImmunity",	9	},	-- Temporal Shield
		[110909] = { "otherImmunity",	"damageImmunity",	9,	342246	},	-- Alter Time (F/B, Arcane)
		[1221107] = { "otherImmunity",	"damageImmunity",	9	},	-- Overpowered Barrier (Arcane)
		[116849] = { "otherImmunity",	"damageImmunity",	4	},	-- Life Cocoon
		[125174] = { "otherImmunity",	"damageImmunity",	4	},	-- Touch of Karma (player buff) target debuff(122470)
		[199448] = { "otherImmunity",	"damageImmunity",	3	},	-- Blessing of Sacrifice (HT - target buff) (player debuff"Ultimate Sacrifice" id=199450, there is no player buff, debuff shows up when damage is being transfered)
		[228050] = { "otherImmunity",	"damageImmunity",	3	},	-- Guardian of the Forgotten Queen (P, T)
		[232708] = { "otherImmunity",	"damageImmunity",	5,	232707	},	-- Ray of Hope (delay dmg - blue, delay heal - yellow)
		[45182 ] = { "otherImmunity",	"damageImmunity",	8	},	-- Cheating Death

		-- External Defensive
		[145629] = { "defensive",	"externalDefensive",	2	},	-- Anti-Magic Zone
		[454863] = { "defensive",	"externalDefensive",	2	},	-- Lesser Anti-Magic Shell (on party, Vestigial Shell talent)
		[209426] = { "defensive",	"externalDefensive",	12	},	-- Darkness (w/ Cover of Darkness HT, same Id)
		[102342] = { "defensive",	"externalDefensive",	7	},	-- Ironbark
		[357170] = { "defensive",	"externalDefensive",	13	},	-- Time Dilation
		[53480 ] = { "defensive",	"externalDefensive",	11	},	-- Roar of Sacrifice (buff on player only, not pet)
		[202162] = { "defensive",	"externalDefensive",	4	},	-- Avert Harm (BM) - HT
		[6940  ] = { "defensive",	"externalDefensive",	3	},	-- Blessing of Sacrifice (player=target buff, player buff is up instantly)
		[47788 ] = { "defensive",	"externalDefensive",	5	},	-- Guardian Spirit
		[271466] = { "defensive",	"externalDefensive",	5	},	-- Luminous Barrier
		[33206 ] = { "defensive",	"externalDefensive",	5	},	-- Pain Suppression
		[81782 ] = { "defensive",	"externalDefensive",	5	},	-- Power Word: Barrier
		[201633] = { "defensive",	"externalDefensive",	6	},	-- Earthen Wall Totem
		[325174] = { "defensive",	"externalDefensive",	6	},	-- Spirit Link Totem
		[213871] = { "defensive",	"externalDefensive",	1	},	-- Bodyguard (P) - HT, buff on allies, no self buff

		-- Tank Defensive
--		[77535 ] = { "defensive",	"tankDefensive",	2	},	-- Blood Shield (BDK)
		[195181] = { "defensive",	"tankDefensive",	2	},	-- Bone Shield (BDK)
		[463730] = { "defensive",	"tankDefensive",	2	},	-- 11.0 Coagulating Blood [shows the amount of recently taken damage that will be used to calculate the value of your next Death Strike. the number of stacks shows it as a percentage of your current health.]
		[194679] = { "defensive",	"tankDefensive",	2	},	-- Rune Tap (BDK)
		[203819] = { "defensive",	"tankDefensive",	12	},	-- Demon Spikes
		[192081] = { "defensive",	"tankDefensive",	7	},	-- Ironfur
--		[215479] = { "defensive",	"tankDefensive",	4	},	-- Shuffle (uptime is almost 100%)
		[132403] = { "defensive",	"tankDefensive",	3	},	-- Shield of the Righteous
		[190456] = { "defensive",	"tankDefensive",	1	},	-- Ignore Pain
		[132404] = { "defensive",	"tankDefensive",	1	},	-- Shield Block

		-- Defensive
		-- DK
		[81256 ] = { "defensive",	"personalDefensive",	2	},	-- Dancing Rune Weapon (BDK)
		[55233 ] = { "defensive",	"personalDefensive",	2	},	-- Vampiric Blood (BDK)
		[219809] = { "defensive",	"minorDefensive",	2	},	-- Tombstone
		[194844] = { "defensive",	"minorDefensive",	2	},	-- Bonestorm (BDK)
--		[206977] = { "defensive",	"minorDefensive",	2	},	-- Blood Mirror (BDK)	-- removed
		-- DH
		[212800] = { "defensive",	"personalDefensive",	12	},	-- Blur
		-- Druid
		[22812 ] = { "defensive",	"personalDefensive",	7	},	-- Barkskin
		[61336 ] = { "defensive",	"personalDefensive",	7	},	-- Survival Instincts
		[200851] = { "defensive",	"personalDefensive",	7	},	-- Rage of the Sleeper (G) - also a dmg reflect
		[155835] = { "defensive",	"minorDefensive",	7	},	-- Bristling Fur (Rage gain)
		[247563] = { "defensive",	"minorDefensive",	7	},	-- Nature's Grasp BUFF (HT - Entangling Bark)
		[305497] = { "defensive",	"minorDefensive",	7	},	-- Thorns
		-- Evoker
		[410651] = { "defensive",	"personalDefensive",	13	},	-- Molten Blood
		[363916] = { "defensive",	"personalDefensive",	13	},	-- Obsidian Scales - Silence and Interrupt immune with 378444 Obsidian Mettle (talent) baked in
		[374348] = { "defensive",	"personalDefensive",	13	},	-- Renewing Blaze
		[404381] = { "defensive",	"minorDefensive",	13	},	-- Defy Fate
		[403760] = { "defensive",	"minorDefensive",	13	},	-- Recall
--		[410355] = { "defensive",	"minorDefensive",	13	},	-- Stretch Time
		-- Hunter
		[472708] = { "defensive",	"personalDefensive",	11	},	-- Shell cover (Pack Leader hero talent)
		[281195] = { "defensive",	"personalDefensive",	11,	{264735,272679}	},	-- Survival of the Fittest (20%) (Lone Wolf, Talent, Fortitude of the Bear)
		-- Mage
		[113862] = { "defensive",	"personalDefensive",	9	},	-- Greater Invisibility (60% dmg reduc effect)
		[414658] = { "defensive",	"personalDefensive",	9	},	-- Ice Cold
		[389714] = { "defensive",	"minorDefensive",	9,	212799	},	-- Displacement Beacon (DF Talent, old version)
--		[198065] = { "defensive",	"minorDefensive",	9	},	-- Prismatic Cloak	-- removed
--		[235313] = { "defensive",	"minorDefensive",	9	},	-- Blazing Barrier w/ Overpowered Barrier (60 dmg reflect. same buffid - no unique aura unlike other specs)

		-- Monk
		[122278] = { "defensive",	"personalDefensive",	4	},	-- Dampen Harm
		[122783] = { "defensive",	"personalDefensive",	4	},	-- Diffuse Magic
		[120954] = { "defensive",	"personalDefensive",	4,	243435	},	-- Fortifying Brew (BM, MW WW - merged to BM)
		[115176] = { "defensive",	"personalDefensive",	4	},	-- Zen Meditation (BM)
		[322507] = { "defensive",	"minorDefensive",	4	},	-- Celetial Brew
		[394112] = { "defensive",	"minorDefensive",	4,	343249	},	-- Escape from Reality (DF Talent, SL Runeforge)
		[132578] = { "defensive",	"minorDefensive",	4	},	-- Invoke Niuzao, the Black Ox (BM)
		-- Paladin
		[31850 ] = { "defensive",	"personalDefensive",	3	},	-- Ardent Defender (P)
		[498   ] = { "defensive",	"personalDefensive",	3,	403876	},	-- Divine Protection (Holy, Ret)
		[86659 ] = { "defensive",	"personalDefensive",	3,	212641	},	-- Guardian of Ancient Kings (P, P-Glyphed)
		[184662] = { "defensive",	"personalDefensive",	3	},	-- Shield of Vengeance
		[205191] = { "defensive",	"minorDefensive",	3	},	-- Eye for an Eye
--		[216328] = { "defensive",	"minorDefensive",	3	},	-- Light's Grace	-- removed
		[157128] = { "defensive",	"minorDefensive",	3	},	-- Saved by the Light
		-- Priest
		[47585 ] = { "defensive",	"personalDefensive",	5	},	-- Dispersion (immune to movement impairing effects)
		[19236 ] = { "defensive",	"minorDefensive",	5	},	-- Desperate Prayer
		[373447] = { "defensive",	"minorDefensive",	5,	337661	},	-- Translucent Image (DF Talent, Fade Conduit)
		-- Rogue
		[1966  ] = { "defensive",	"minorDefensive",	8	},	-- Feint (w/ Elusiveness talent, same Id)
		-- Shaman
		[108271] = { "defensive",	"personalDefensive",	6	},	-- Astral Shift
--		[118337] = { "defensive",	"personalDefensive",	6	},	-- Harden Skin (Earth Elemental w/ Primal Elementalist)	-- removed
		[114893] = { "defensive",	"personalDefensive",	6	},	-- Stone Bulwark Totem (init absorb)
		[207498] = { "defensive",	"minorDefensive",	6,	207495	},	-- Ancestral Protection (buff on player)
		[260881] = { "defensive",	"minorDefensive",	6	},	-- Spirit Wolf (Talent, +inc speed)
		-- Warlock
		[108416] = { "defensive",	"personalDefensive",	10	},	-- Dark Pact
--		[7870  ] = { "defensive",	"personalDefensive",	10	},	-- Lesser Invisibility (Succubus)
--		[17767 ] = { "defensive",	"personalDefensive",	10	},	-- Shadow Bulwark (Voidwalker)
		-- Warrior
		[184364] = { "defensive",	"personalDefensive",	1	},	-- Enraged Regeneration
		[871   ] = { "defensive",	"personalDefensive",	1	},	-- Shield Wall
		[12975 ] = { "defensive",	"minorDefensive",	1	},	-- Last Stand
		[97463 ] = { "defensive",	"minorDefensive",	1	},	-- Rallying Cry
		-- misc
--		[324867] = { "defensive",	"minorDefensive",		},	-- Fleshcraft (SL covenant sig)
		[345231] = { "defensive",	"minorDefensive",		},	-- Gladiator's Emblem
--		[363522] = { "defensive",	"minorDefensive",		},	-- Gladiator's Eternal Aegis
		-- Trinkets
		[425571] = { "defensive",	"personalDefensive"	},	-- Fyrakk's Tainted Rageheart

		-- Offensive
		-- DK
		[383269] = { "offensive",	"offensive",	2,	315443	},	-- Abomination Limb (DF Talent, SL Necrolord)
		[51271 ] = { "offensive",	"offensive",	2	},	-- Pillar of Frost
		[207289] = { "offensive",	"offensive",	2	},	-- Unholy Frenzy
		[42650 ] = { "offensive",	"minorOffensive",	2	},	-- Army of the Dead (summoning)
		[440861] = { "offensive",	"minorOffensive",	2	},	-- A Feast of Souls (Rider of the Apocalypse hero talent)
--		[152279] = { "offensive",	"minorOffensive",	2	},	-- Breath of Sindragosa (no duration)
		[77616 ] = { "offensive",	"minorOffensive",	2	},	-- Dark Simulacrum (duplicate spell buff)
		[63560 ] = { "offensive",	"minorOffensive",	2	},	-- Dark Transformation (buff on Ghoul)
		[47568 ] = { "offensive",	"minorOffensive",	2	},	-- Empower Rune Weapon
--		[321995] = { "offensive",	"minorOffensive",	2	},	-- Hypothermic Presence	-- removed
--		[215711] = { "offensive",	"minorOffensive",	2	},	-- Soul Reaper (130736,	-- Soul Reaper (debuff))	-- old version removed
--		[311648] = { "offensive",	"minorOffensive",	2	},	-- Swarming Mist (SL Venthyr)
		-- DH
		[162264] = { "offensive",	"offensive",	12,	187827	},	-- Metamorphosis=Meta HT, (Havoc, vengeance)
		[347765] = { "offensive",	"minorOffensive",	12	},	-- Demon Soul
		[442688] = { "offensive",	"minorOffensive",	12	},	-- Thrill of the Fight (Aldrachi Reaver hero talent)
		-- Druid
		[106951] = { "offensive",	"offensive",	7,	{102543,50334,102558}	},	-- Berserk (F), Incarnation: King of the Jungle, Berserk (G), Incarnation: Guardian of Ursoc
		[194223] = { "offensive",	"offensive",	7,	{102560,383410,390414}	},	-- Celestial Alignment, Incarnation: Chosen of Elune, CA w/ Orbital Strikes, Incarn w/ Orbital Strikes (DF Talent)
		[391528] = { "offensive",	"offensive",	7,	323764	},	-- Convoke the Spirits (DF Talent, SL NF Covenant)
--		[323546] = { "offensive",	"offensive",	7	},	-- Ravenous Frenzy (SL Venthyr)
--		[145152] = { "offensive",	"minorOffensive",	7	},	-- Bloodtalons
		[433832] = { "offensive",	"minorOffensive",	7	},	-- Dream Burst (Keeper of the Grove hero talent - Dream Surge)
		[319454] = { "offensive",	"minorOffensive",	7,	{108291,108292,108293,108294}	},	-- Heart of the Wild (DF Talent, SL - Balance Affinity, Feral, Guardian, Resto)
--		[338142] = { "offensive",	"minorOffensive",	7,	327037	},	-- Lone Empowerment (SL Kyrian), Kindred Protection (SL Kyrian)
		[5217  ] = { "offensive",	"minorOffensive",	7	},	-- Tiger's Fury
		[202425] = { "offensive",	"minorOffensive",	7	},	-- Warrior of Elune
		-- Evoker
		[375087] = { "offensive",	"offensive",	13	},	-- Dragonrage
		[395296] = { "offensive",	"minorOffensive",	13	},	-- Ebon Might (1', 2' 395152 - don't track)
		[390386] = { "offensive",	"minorOffensive",	13	},	-- Fury of the Aspect
		[370553] = { "offensive",	"minorOffensive",	13	},	-- Tip the Scales
		-- Hunter
		[19574 ] = { "offensive",	"offensive",	11,	186254	},	-- Bestial Wrath, buff on pet
		[359844] = { "offensive",	"offensive",	11	},	-- Call of the Wild
		[266779] = { "offensive",	"offensive",	11,	360952	},	-- Coordinated Assault (pre-DF), DF Talent
		[378957] = { "offensive",	"offensive",	11	},	-- Spearhead
		[288613] = { "offensive",	"offensive",	11	},	-- Trueshot (MM)
		[186289] = { "offensive",	"minorOffensive",	11	},	-- Aspect of the Eagle (SV)
--		[193530] = { "offensive",	"minorOffensive",	11	},	-- Aspect of the Wild (BM)	-- 11.0 removed
--		[260402] = { "offensive",	"minorOffensive",	11	},	-- Double Tap	-- removed
		[466904] = { "offensive",	"minorOffensive",	11	},	-- Harrier's Cry
--		[400456] = { "offensive",	"minorOffensive",	11	},	-- Salvo
		-- Mage
--		[12042 ] = { "offensive",	"offensive",	9	},	-- Arcane Power	-- removed
		[365362] = { "offensive",	"offensive",	9	},	-- Arcane Surge
		[190319] = { "offensive",	"offensive",	9	},	-- Combustion
--		[324220] = { "offensive",	"offensive",	9	},	-- Deathborne (SL Necrolord)
		[12472 ] = { "offensive",	"offensive",	9	},	-- Icy Veins
		[205025] = { "offensive",	"minorOffensive",	9	},	-- Presence of Mind
--		[116014] = { "offensive",	"minorOffensive",	9	},	-- Rune of Power	-- 10.1.5 removed
		[80353 ] = { "offensive",	"minorOffensive",	9	},	-- Time Warp
		-- Monk
		[443028] = { "offensive",	"offensive",	4	},	-- Celestial Conduit (Conduit of the Celestials hero talent, channeled) [radiate 1.6M Nature damage onto enemies]
		[137639] = { "offensive",	"offensive",	4	},	-- Storm, Earth, and Fire
--			[152173] = { "offensive",	"offensive",	4	},	-- Serenity	-- 11.0 removed
		[202335] = { "offensive",	"minorOffensive",	4	},	-- Double Barrel (BM) (HT, trigger)
--		[364277] = { "offensive",	"minorOffensive",	4	},	-- Primordial Mending (MW - SL 4 set bonus)
--		[363911] = { "offensive",	"minorOffensive",	4	},	-- Primordial Potential (WW - SL 4 set bonus) - always up, track stacks [NP]
--		[363924] = { "offensive",	"minorOffensive",	4	},	-- Primordial Power (WW - SL 4 set bonus) - at 10 stacks of Primordial Potential
		[387184] = { "offensive",	"minorOffensive",	4,	310454	},	-- Weapons of Order (BM) (DF Talent, SL Kyrian)
		-- Paladin
		[31884 ] = { "offensive",	"offensive",	3,	{216331,231895,389539}	},	-- Avenging Wrath, Avenging Crusader (H), Crusade, Sentinel
--		[152262] = { "offensive",	"offensive",	3	},	-- Seraphim	-- removed in 10.1.5
--		[328622] = { "offensive",	"minorOffensive",	3,	388010	},	-- Blessing of Autumn (SL Covenant, DF talent)
		[328620] = { "offensive",	"minorOffensive",	3,	388007	},	-- Blessing of Summer (SL Covenant, DF talent)
--		[328281] = { "offensive",	"minorOffensive",	3,	388011	},	-- Blessing of Winter (SL Covenant, DF talent)
--		[364306] = { "offensive",	"minorOffensive",	3	},	-- Dawn Will Come (SL 2 set bonus)
		[215652] = { "offensive",	"minorOffensive",	3	},	-- Shield of Virtue (HT - Prot) (trigger)
		-- Priest
--		[325013] = { "offensive",	"offensive",	5	},	-- Boon of the Ascended (SL Kyrian)
		[10060 ] = { "offensive",	"offensive",	5	},	-- Power Infusion
--		[109964] = { "offensive",	"offensive",	5	},	-- Spirit Shell	-- removed
--		[319952] = { "offensive",	"offensive",	5	},	-- Surrender to Madness	-- removed
		[197871] = { "offensive",	"minorOffensive",	5,	197874	},	-- Dark Archangel (on caster, on casted target)
		[391109] = { "offensive",	"minorOffensive",	5	},	-- Dark Ascension (Shadow)
--		[363727] = { "offensive",	"minorOffensive",	5	},	-- Divine Conversation (Holy - SL 2/4 set bonus - no duration)
--		[341207] = { "offensive",	"minorOffensive",	5	},	-- Dark Thought (Shadow - SL 2 set bonus) - proc
--		[199412] = { "offensive",	"minorOffensive",	5	},	-- Edge of Insanity (20% dmg red in BFA)	-- removed
--		[363578] = { "offensive",	"minorOffensive",	5	},	-- Living Shadow (Shadow - SL 4 set bonus) - Dark thought proc consumed
--		[198069] = { "offensive",	"minorOffensive",	5	},	-- Power of the Dark Side (Disc - SL 4 set bonus)
		[322105] = { "offensive",	"minorOffensive",	5	},	-- Shadow Covenant
		[194249] = { "offensive",	"minorOffensive",	5	},	-- Voidform
		-- Rogue
		[13750 ] = { "offensive",	"offensive",	8	},	-- Adrenaline Rush
		[121471] = { "offensive",	"offensive",	8	},	-- Shadow Blades
		-- set main id as the secondary Mastery effect (394758) so we can have separate settings for the buff and debuff (debuffId on target == buffId on caster)
		[394758] = { "offensive",	"minorOffensive",	8,	{384631,323654,345569}	},	-- Flagellation (DF Mastery buff after 384631 ends - has stacks, DF Talent - has stacks , SL Venthyr, SL haste buff after 323654 ends)
--		[270070] = { "offensive",	"minorOffensive",	8	},	-- Hidden Blades (stacks)	-- removed?
		[51690 ] = { "offensive",	"minorOffensive",	8	},	-- Killing Spree
--		[340094] = { "offensive",	"minorOffensive",	8	},	-- Master Assassin's Mark (SL Runeforge - Mark of the Master Assassin)
--		[198529] = { "offensive",	"minorOffensive",	8	},	-- Plunder Armor (player buff=target debuff)	-- removed
--		[375939] = { "offensive",	"minorOffensive",	8,	347037	},	-- Sepsis (DF Talent, SL NF) - 1 free use of stealth ability
		[185422] = { "offensive",	"minorOffensive",	8	},	-- Shadow Dance
		[212283] = { "offensive",	"minorOffensive",	8	},	-- Symbols of Death
		-- Shaman
		[114050] = { "offensive",	"offensive",	6,	114051	},	-- Ascendance (Ele, Enh)	-- Resto in healer section
		[333957] = { "offensive",	"offensive",	6	},	-- Feral Spirit
		[191634] = { "offensive",	"offensive",	6,	383009	},	-- Stormkeeper (Ele, Res)
		--[320137] = { "offensive",	"offensive",	6,	191634	},	-- Stormkeeper (Enh)	-- removed
		[2825  ] = { "offensive",	"minorOffensive",	6,	32182	},	-- Bloodlust, Heroism
		[204361] = { "offensive",	"minorOffensive",	6	},	-- Bloodlust (HT), Heroism (HT)
		[384352] = { "offensive",	"minorOffensive",	6,	335903	},	-- Doom Winds (DF Talent, SL Runeforge)
--		[320125] = { "offensive",	"minorOffensive",	6	},	-- Echoing Shock	-- removed
--		[364523] = { "offensive",	"minorOffensive",	6	},	-- Fireheart (SL Ele - 2/4 set bonus - no duration=Fire/Storm Ele is active)
--		[210714] = { "offensive",	"minorOffensive",	6	},	-- Icefury
		[378081] = { "offensive",	"minorOffensive",	6	},	-- Nature's Swiftness
--		[375986] = { "offensive",	"minorOffensive",	6,	327164	},	-- Primordial Wave (DF Talent, Necrolord-lava burst all target with flame shock)
		[208963] = { "offensive",	"minorOffensive",	6	},	-- Skyfury Totem
		-- Warlock
--		[113858] = { "offensive",	"offensive",	10	},	-- Dark Soul: Instability (Des)	-- removed
--		[113860] = { "offensive",	"offensive",	10	},	-- Dark Soul: Misery (Aff)	-- removed
		[265273] = { "offensive",	"offensive",	10	},	-- Demonic Power (Demo) - Summon Demonic Tyrant
		[344566] = { "offensive",	"offensive",	10	},	-- Rapid Contagion (Aff) - nothing else to add :v
		[267171] = { "offensive",	"minorOffensive",	10	},	-- Demonic Strength (Demo)
--		[353646] = { "offensive",	"minorOffensive",	10	},	-- Fel Obelisk	-- 11.0 removed
		[442726] = { "offensive",	"minorOffensive",	10	},	-- Malevolence (Hellcaller hero talent, CD)
--		[267218] = { "offensive",	"minorOffensive",	10	},	-- Nether Portal (Demo)	-- 11.0 removed
		-- Warrior
		[107574] = { "offensive",	"offensive",	1,	401150	},	-- Avatar (A, P)
		[1719  ] = { "offensive",	"offensive",	1	},	-- Battle Cry
--		[324143] = { "offensive",	"offensive",	1,	325862	},	-- Conqueror's Banner (SL Necrolord, 2ndary on allies)
		[199261] = { "offensive",	"minorOffensive",	1	},	-- Death Wish stacks x10
		[262228] = { "offensive",	"minorOffensive",	1	},	-- Deadly Calm
--		[311193] = { "offensive",	"minorOffensive",	1	},	-- Elysian Might
--		[331937] = { "offensive",	"minorOffensive",		},	-- Euphoria - @Thrill Seeker x40 stacks 331939 (SL Soulbind)
--		[364010] = { "offensive",	"minorOffensive",	1	},	-- Outburst (SL 2/4 set bonus) - Seeing Red transformed at 8 stacks
--		[364006] = { "offensive",	"minorOffensive",	1	},	-- Seeing Red (SL 2 set bonus) - always up, track stacks [NP]
		[198817] = { "offensive",	"minorOffensive",	1	},	-- Sharpen Blade
--		[52437 ] = { "offensive",	"minorOffensive",	1	},	-- Sudden Death (proc)
		-- passive/procs
--		[390195] = { "offensive",	"minorOffensive",	12,	337567	},	-- Chaos Theory (DF Talent, Chaotic Blades (Chaos Theory - SL Runeforge, proc))
--		[333100] = { "offensive",	"minorOffensive",	9	},	-- Firestorm (SL Runeforge) -> Hyperthermia in DF
		[199844] = { "offensive",	"minorOffensive",	9	},	-- Glacial Spike!
		[383874] = { "offensive",	"minorOffensive",	9	},	-- Hyperthermia
--		[44544 ] = { "offensive",	"minorOffensive",	9	},	-- Fingers of Frost
--		[48107 ] = { "offensive",	"minorOffensive",	9	},	-- Heating Up
--		[48108 ] = { "offensive",	"minorOffensive",	9	},	-- Hot Streak!
--		[342242] = { "offensive",	"minorOffensive",	9	},	-- Time Warp (HT - Time Anomaly! proc, 6s)
		[325202] = { "offensive",	"minorOffensive",	4,	438443	},	-- Dance of chi-Ji (talent, 10.2.6 talent)
		[247483] = { "offensive",	"minorOffensive",	4	},	-- Tigereye Brew (no cd)
		--[248646] = { "offensive",	"minorOffensive",	4	},	-- Tigereye Brew (stacks)
		[452684] = { "offensive",	"minorOffensive",	4	},	-- Wisdom of the Wall (Shadow-pan hero talent) [Critical strikes deal an additional 30% damage]
		[457280] = { "offensive",	"minorOffensive",	8	},	-- Darkest Night (Deathstalker hero talent)
--		[256735] = { "offensive",	"minorOffensive",	8	},	-- Master Assassin
--		[193359] = { "offensive",	"minorOffensive",	8	},	-- x0.5 True Bearing (CD reduction +1s/combo)
--		[193356] = { "offensive",	"minorOffensive",	8	},	-- x0.5 Broadsides (combo generator +1combo 20% dmg)
--		[193357] = { "offensive",	"minorOffensive",	8	},	-- x0.5 Ruthless Precision (crit 25%, BTE crit 60%)
--		[193358] = { "offensive",	"minorOffensive",	8	},	-- x0.5 Grand Melee (attack speed 55%, leech 25%)
--		[199600] = { "offensive",	"minorOffensive",	8	},	-- x0.5 Buried Treasure (Energy regen +4/s)
--		[199603] = { "offensive",	"minorOffensive",	8	},	-- x0.5 SKull and Crossbones (sinister strike extra hit chance 30%)
--		[77762 ] = { "offensive",	"minorOffensive",	6	},	-- Lava Surge (proc)
--		[388068] = { "offensive",	"minorOffensive",	10	},	-- Inquisitor's Gaze (proc chance to summon Inquisitor's Eye that casts Fel Barrage)
		[387157] = { "offensive",	"offensive",	10,	364349	},	-- Ritual of Ruin (Demo) (DF Talent, SL 2 set bonus) - Impending Ruin transformed at 10 stacks - nothing else to add

		-- Healing CD
		[391891] = { "healing",	"healing",	7	},	-- Adaptive Swarm
		[197721] = { "healing",	"healing",	7	},	-- Flourish
		[22842 ] = { "healing",	"healing",	7	},	-- Frenzied Regeneration
		[33891 ] = { "healing",	"healing",	7,	117679	},	-- Incarnation: Tree of Life, Incarnation - additional buff only during tree form
			[473909] = { "healing",	"healing",	7	},	-- Ancient of Lore (pvp talent)
		[132158] = { "healing",	"healing",	7	},	-- Nature's Swiftness
		[370960] = { "healing",	"healing",	13	},	-- Emerald Communion
		[136   ] = { "healing",	"healing",	11	},	-- Mend Pet (buff on pet)
		[212640] = { "healing",	"healing",	11	},	-- Mending Bandage
		[328282] = { "healing",	"healing",	3,	388013	},	-- Blessing of Spring (SL Covenant, DF Talent)
		[210294] = { "healing",	"healing",	3	},	-- Divine Favor (HT - Holy)
		[386730] = { "healing",	"healing",	3,	384029	},	-- Divine Resonance/Toll (Holy/Prot, Ret)
		[414273] = { "healing",	"healing",	3	},	-- Hand of Divinity
--		[105809] = { "healing",	"healing",	3	},	-- Holy Avenger	-- removed 10.0.7
--		[200652] = { "healing",	"healing",	3	},	-- Tyr's Deliverance (HoT effect shows on caster only)
		[200654] = { "healing",	"healing",	3	},	-- Tyr's Deliverance (inc healing recieved shows on all allies)
		[200183] = { "healing",	"healing",	5	},	-- Apotheosis
		[197862] = { "healing",	"healing",	5	},	-- Archangel
		[64843 ] = { "healing",	"healing",	5	},	-- Divine Hymn
--		[47536 ] = { "healing",	"healing",	5	},	-- Rapture
		[421453] = { "healing",	"healing",	5	},	-- Ultimate Penitence
		[15286 ] = { "healing",	"healing",	5	},	-- Vampiric Embrace
		[185311] = { "healing",	"healing",	8	},	-- Crimson Vial
		[114052] = { "healing",	"healing",	6	},	-- Ascendance (Res)
--		[108281] = { "healing",	"healing",	6	},	-- Ancestral Guidance

		-- Freedom
		-- Root and snare immunities
		[54216 ] = { "freedom",	"freedom",	11,	62305	},	-- Master's Call (player, no pet)
		[1044  ] = { "freedom",	"freedom",	3,	305395	},	-- Blessing of Freedom, Unbound Freedom (HT)
		[199545] = { "freedom",	"freedom",	3	},	-- Steed of Glory (P) (knockback)
--		[337294] = { "freedom",	"freedom",	4	},	-- Roll Out (SL Runeforge)
		-- Snare immunities
		[444347] = { "freedom",	"freedom",	2	},	-- Death Charge (Rider of the Apocalypse hero talent 444010, replaces Death's Advance)
		[48265 ] = { "freedom",	"freedom",	2	},	-- Death's Advance (snare knockback immune)
		[212552] = { "freedom",	"freedom",	2	},	-- Wraith Walk (breaks root but not immune)
		[205629] = { "freedom",	"freedom",	12	},	-- Demonic Trample
		[118922] = { "freedom",	"freedom",	11	},	-- Posthaste
		[201447] = { "freedom",	"freedom",	4	},	-- Ride the Wind
--		[197003] = { "freedom",	"freedom",	8	},	-- Maneuverability (HT)	-- effect changed
		[2645  ] = { "freedom",	"freedom",	6	},	-- Ghost Wolf
		[58875 ] = { "freedom",	"freedom",	6	},	-- Spirit Walk (removes all movement impairing effects and inc speed 60%=this breaks root on cast...sigh)
		[111400] = { "freedom",	"freedom",	10	},	-- Burning Rush
		[407582] = { "freedom",	"freedom",	9	},	-- Icy Feet	-- Patch 10.1 new

		-- Movement increase
		[1850  ] = { "buff",	"increaseMovementSpeed",	7,	252216	},	-- Dash, Tiger Dash
		[106898] = { "buff",	"increaseMovementSpeed",	7,	{77761,77764}	},	-- Stampeding Roar (noform), bear, cat
		[358267] = { "buff",	"increaseMovementSpeed",	13	},	-- Hover (Unburdened Flight freedom effect baked in)
		[186257] = { "buff",	"increaseMovementSpeed",	11,	203233	},	-- Aspect of the Cheetah, Aspect of the Cheetah on allies by Hunting Pack (HT)
		[116841] = { "buff",	"increaseMovementSpeed",	4	},	-- Tiger's Lust
		[221886] = { "buff",	"increaseMovementSpeed",	3,	{221883,221885,221887,254471,254472,254473,254474,276111,276112,363608}	},	-- Divine Steed (BE)
		[121557] = { "buff",	"increaseMovementSpeed",	5	},	-- Angelic Feather
		[65081 ] = { "buff",	"increaseMovementSpeed",	5	},	-- Body and Soul
		[209754] = { "buff",	"increaseMovementSpeed",	8	},	-- Boarding Party
		[36554 ] = { "buff",	"increaseMovementSpeed",	8	},	-- Shadowstep
		[2983  ] = { "buff",	"increaseMovementSpeed",	8	},	-- Sprint
		[378076] = { "buff",	"increaseMovementSpeed",	6,	338036	},	-- Thunderous Paws (DF Talent, SL Conduit)
		[192082] = { "buff",	"increaseMovementSpeed",	6	},	-- Windrush Totem
		[387633] = { "buff",	"increaseMovementSpeed",	10,	339412	},	-- Demonic Momentum (DF Talent- 'Soulburn', SL Conduit)
		[202164] = { "buff",	"increaseMovementSpeed",	1	},	-- Bounding Stride
--		[310143] = { "buff",	"increaseMovementSpeed",		},	-- Soulshape (SL Covenant)

		-- Stealth
		[5215  ] = { "buff",	"miscBuff",	7	},	-- Prowl
		[58984 ] = { "buff",	"miscBuff",		},	-- Shadowmeld
		[199483] = { "buff",	"miscBuff",	11	},	-- Camouflage
		[110960] = { "buff",	"miscBuff",	9	},	-- Greater Invisibility
		[66    ] = { "buff",	"miscBuff",	9,	32612	},	-- Invisibility (3s countdown), speed buff (removed?)
		[414664] = { "buff",	"miscBuff",	9,	198158	},	-- Mass Invisibility (DF, pre)
		[11327 ] = { "buff",	"miscBuff",	8	},	-- Vanish
		[1784  ] = { "buff",	"miscBuff",	8,	115191	},	-- Stealth, Stealth w/ Subterfuge
		-- Misc
		[3714  ] = { "buff",	"miscBuff",	2	},	-- Path of Frost
		[116888] = { "buff",	"miscBuff",	2	},	-- Shroud of Purgatory
		[188501] = { "buff",	"miscBuff",	12	},	-- Spectral Sight
		[29166 ] = { "buff",	"miscBuff",	7	},	-- Innervate
		[406732] = { "buff",	"miscBuff",	13,	406789	},	-- Spatial Paradox (1', 2')
		[404977] = { "buff",	"miscBuff",	13	},	-- Time Skip
		[375234] = { "buff",	"miscBuff",	13,	375258	},	-- Time Spiral (1', 2')
		[5384  ] = { "buff",	"miscBuff",	11	},	-- Feign Death
		[34477 ] = { "buff",	"miscBuff",	11,	35079	},	-- Misdirection (trigger on both, threat actively being transfered buff on caster - doesn't exist on target)
--		[209997] = { "buff",	"miscBuff",	11	},	-- Play Dead (pet)
		[12051 ] = { "buff",	"miscBuff",	9	},	-- Evocation
		[130   ] = { "buff",	"miscBuff",	9	},	-- Slow Fall
--		[415246] = { "buff",	"miscBuff",	3	},	-- Divine Plea	-- 11.0 removed
		[111759] = { "buff",	"miscBuff",	5	},	-- Levitate
--		[340094] = { "buff",	"miscBuff",	8	},	-- Master Assassin's Mark (SL Runeforge)
		[115192] = { "buff",	"miscBuff",	8	},	-- Subterfuge
		[57934 ] = { "buff",	"miscBuff",	8	},	-- Tricks of the Trade (o) 15% dmg (S) symbiosis (same id with HT?)
--		[204366] = { "buff",	"miscBuff",	6	},	-- Thundercharge	-- removed
		[546   ] = { "buff",	"miscBuff",	6	},	-- Water Walking
		[333889] = { "buff",	"miscBuff",	10	},	-- Fel Domination
		[20707 ] = { "buff",	"miscBuff",	10	},	-- Soulstone
--		[273104] = { "buff",	"miscBuff",		},	-- Fireblood
		[256948] = { "buff",	"miscBuff",		},	-- Spatial Rift
--		[65116 ] = { "buff",	"miscBuff",		},	-- Stoneform
--		[388380] = { "buff",	"miscBuff",		},	-- Dragonrider's Compassion
--		[327140] = { "buff",	"miscBuff",		},	-- Forgeborne Reveries (SL Necrolord soulbind) = dead
--		[320224] = { "buff",	"miscBuff",		},	-- Podtender (SL NF soulbind, rejuvenating buff) = dead
		[34709 ] = { "buff",	"miscBuff",		},	-- Shadow Sight
		--
		[108839] = { "buff",	"miscBuff",	9	},	-- Ice Floes
		[64901 ] = { "buff",	"miscBuff",	5	},	-- Symbol of Hope
		[322431] = { "buff",	"miscBuff",	5	},	-- Thoughtsteal (buff applied on spell steal)
		[79206 ] = { "buff",	"miscBuff",	6	},	-- Spiritwalker's Grace

		-- Hot/Stack
		[102352] = { "buff",	"hotStack",	7,	102351	},	-- Cenarion Ward (dot heal, trigger)
--		[203554] = { "buff",	"hotStack",	7,	347621	},	-- Focused Growth (stacks)
		[33763 ] = { "buff",	"hotStack",	7,	188550	},	-- Lifebloom (TWW-no stack)
		[392360] = { "buff",	"hotStack",	7,	363813	},	-- Reforestation (Ephemeral Blossom - DF Talent, SL 4 set bonus) - 3stack=tree
		[360827] = { "buff",	"hotStack",	13	},	-- Blistering Scales
		[363534] = { "buff",	"hotStack",	13	},	-- Rewind
		[411036] = { "buff",	"hotStack",	4	},	-- Sphere of Hope	-- Patch 10.1 new
		[414196] = { "buff",	"hotStack",	3	},	-- Awakening
		[441786] = { "buff",	"hotStack",	8	},	-- Escalating Blade (Trickster hero talent) (stacks - Coup de Grace)
		[974   ] = { "buff",	"hotStack",	6,	383648	},	-- Earth Shield, 2nd Earth Shield on self with Elemental Orbit Talent
		[264173] = { "buff",	"hotStack",	10	},	-- Demonic Core (stacks - instant Demonbolt)
		[364348] = { "buff",	"hotStack",	10,	387156	},	-- Impending Ruin (SL 2 set bonus, DF Talent) - stacks
		[334320] = { "buff",	"hotStack",	10	},	-- Inevitable Demise (Drain Life damage 7% * 50 stacks)

		-- Base
		[5487  ] = { "base",	"stance",	7	},	-- Bear Form
		[768   ] = { "base",	"stance",	7	},	-- Cat Form
		[197625] = { "base",	"stance",	7	},	-- Moonkin Form
		[783   ] = { "base",	"stance",	7	},	-- Travel Form (Mount Form has no aura)
		[114282] = { "base",	"stance",	7	},	-- Treant Form
--		[317920] = { "base",	"stance",	3	},	-- Concentration Aura (ccDurationReducer moved to base as it's always on)
		[386208] = { "base",	"stance",	1,	197690	},	-- Defensive Stance (DF version, old version)
	},
	["PVE"] = {
		[234422] = { "base",	"npc",		},	-- Aura of Decay (Tank, Mage Tower)
		[61573 ] = { "base",	"npc",		},	-- Banner of the Alliance (Training Dummy in Org)
		[61574 ] = { "base",	"npc",		},	-- Banner of the Horde (Training Dummy in Stormwind)
		[277242] = { "base",	"npc",		},	-- Symbiote of G'huun
	}
}

--[==[@debug@
for k, v in pairs(E.aura_db) do
	for id in pairs(v) do
		if (not C_Spell.GetSpellName(id)) then
			E.aura_db[k][id]=nil
			E.write("Removing invalid auraID |cffffd200" .. id)
		end
	end
end
--@end-debug@]==]
