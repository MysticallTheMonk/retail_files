local _, ADDON = ...

ADDON.DB = {}

local build = select(4, GetBuildInfo())
if build < 120000 then
    ADDON.DB.Recent = {
        ["minID"] = 2795,
        ["blacklist"] = {},
        ["whitelist"] = {1374, 2550},
    }
else
    ADDON.DB.Recent = {
        ["minID"] = 2733,
        ["blacklist"] = {2795,2796,2797,2798,2802,2803,2804,2807,2808,2815,2823,2825 },
        ["whitelist"] = {16,1946,2161,2220,2492,2595,2607,2608,2614,2615,2693,2694,2708,2710,2713},
    }
end


ADDON.DB.Source = {
    ["Drop"] = {
        -- sourceType = 1
        -- generated drop chances and locations are within sources.db.lua

        -- Wrath of the Lich King
        [61294] = true, -- Green Proto-Drake - Mysterious Egg

        -- Mists of Pandaria
        [132036] = true, -- Thundering Ruby Cloud Serpent - 10x Skyshard
        [138641] = true, -- Red Primal Raptor - Primal Egg
        [138642] = true, -- Black Primal Raptor - Primal Egg
        [138643] = true, -- Green Primal Raptor - Primal Egg

        -- Warlords of Draenor
        [171619] = true, -- Tundra Icehoof - Vengeance, Deathtalon, Terrorfist, Doomroller
        [171630] = true, -- Armored Razorback - Vengeance, Deathtalon, Terrorfist, Doomroller
        [171837] = true, -- Warsong Direfang - Vengeance, Deathtalon, Terrorfist, Doomroller
        [179478] = true, -- Voidtalon of the Dark Star- Edge of Reality

        -- Legion
        [223018] = true, -- Fathom Dweller - World Boss, Kosumoth the Hungering
        [235764] = true, -- Darkspore Mana Ray
        [243025] = true, -- Riddler's Mind-Worm
        [243652] = true, -- Vile Fiend
        [247402] = true, -- Lucid Nightmare
        [253058] = true, -- Maddened Chaosrunner
        [253106] = true, -- Vibrant Mana Ray
        [253107] = true, -- Lambent Mana Ray
        [253108] = true, -- Felglow Mana Ray
        [253109] = true, -- Scintillating Mana Ray
        [253660] = true, -- Biletooth Gnasher
        [253661] = true, -- Crimson Slavermaw
        [253662] = true, -- Acid Belcher

        -- Battle for Azeroth
        [261395] = true, -- The Hivemind - hidden mount
        [288499] = true, -- Frightened Kodo - Darkshore Warfront
        [300150] = true, -- Fabious - Nazjatar
        [315014] = true, -- Ivory Cloud Serpent - Vale of Eternal Blossoms
        [315427] = true, -- Rajani Warserpent (actually just the scale drops from rare) - Vale of Eternal Blossoms
        [316493] = true, -- Elusive Quickhoof - Vol'dun

        -- Shadowlands
        [215545] = true, -- Mastercraft Gravewing - Korthia - venthyr drop: Gravewing Crystal
        [312765] = true, -- Sundancer - Bastion - Sundancer
        [332252] = true, -- Shimmermist Runner - Ardenweald - Treasure
        [334352] = true, -- Wildseed Cradle - Ardenweald - Treasure
        [334433] = true, -- Silverwind Larion - Bastion - Treasure
        [336038] = true, -- Callow Flayedwing - Random Egg drop in Maldraxxus
        [342335] = true, -- Ascended Skymane - Bastion - Kyrian drop
        [344574] = true, -- Bulbous Necroray - Necroray Egg
        [344575] = true, -- Pestilent Necroray - Necroray Egg
        [344576] = true, -- Infested Necroray - Necroray Egg
        [347250] = true, -- Lord of the Corpseflies - Korthia - necrolord drop: Fleshwing
        [353859] = true, -- Summer Wilderling - Korthia - Escaped Wilderling
        [353877] = true, -- Foresworn Aquilon - Korthia - Wild Worldcracker
        [354354] = true, -- Hand of Nilganihmaht - The Maw - secret/treasure hunt
        [368105] = true, -- Colossal Plaguespew Mawrat - Rhuv, Gorger of Ruin - Zereth Mortis
        [368128] = true, -- Colossal Wraithbound Mawrat - Zereth Mortis - treasure

        -- Dragonflight
        [350219] = true, -- Magmashell
        [374138] = true, -- Seething Slug
        [374157] = true, -- Gooey Snailemental
        [374194] = true, -- Mossy Mammoth
        [374196] = true, -- Plainswalker Bearer
        [374278] = true, -- Renewed Magmammoth
        [385266] = true, -- Zenet Hatchling - Ohn'ahran Plains - Zenet Egg
        [408651] = true, -- Cataloged Shalewing
        [420097] = true, -- Azure Worldchiller
        [424476] = true, -- Winter Night Dreamsaber

        -- War Within
        [448979] = true, -- Dauntless Imperial Lynx
        [466020] = true, -- Personalized Goblin S.C.R.A.Per
        [466021] = true, -- Violet Goblin Shredder
        [466026] = true, -- Salvaged Goblin Gazillionaire's Flying Machine
        [471562] = true, -- Thrayir, Eyes of the Siren (secret hunt)
        [1228865] = true, -- Void-Scarred Lynx -- Daily Incursions in Hallowfall
        [1233561] = true, -- Curious Slateback
        [1240632] = true, -- Pearlesent Krolusk
        [1241070] = true, -- Translocated Gorger
        [1241076] = true, -- Sthaarb's Last Lunch
        
        -- Midnight
        [1243597] = true, -- Rootstalker Grimlynx
        [1253927] = true, -- Vibrant Petalwing
        [1253938] = true, -- Ruddy Sporeglider -- Treasure
        [1260354] = true, -- Untainted Grove Crawler -- Treasure
        [1260356] = true, -- Echo of Aln'sharan
        [1261155] = true, -- Augmented Stormray
        [1261302] = true, -- Cobalt Dragonhawk
        [1261316] = true, -- Amani Sharptalon
        [1261323] = true, -- Cerulian Hawkstrider
        [1261332] = true, -- Duskbrute Harrower
        [1261351] = true, -- Witherbark Pango
        [1261360] = true, -- Ancestral War Bear -- Treasure
        [1261576] = true, -- Hexed Vilefeather Eagle -- Treasure
        [1266700] = true, -- Sanguine Harrower

    },

    ["Quest"] = {
        -- sourceType = 2
        ------------------------------
        -- Alliance & Horde ----------
        ------------------------------

        [54753] = true, -- White Polar Bear - Quest from Gretta the Arbiter, needs reputation to be able to accept the quest
        [73313] = true, -- Crimson Deathcharger - Mograine's Reunion
        [75207] = true, -- Abyssal Seahorse - The Abyssal Ride
        [127154] = true, -- Onyx Cloud Serpent - Quest Surprise Attack!, needs reputation to be able to accept the quest
        [138640] = true, -- Bone-White Primal Raptor - A Mountain of Giant Dinosaur Bones
        [171850] = true, -- Llothien Prowler - Volpin the Elusive
        [213158] = true, -- Predatory Bloodgazer - Bloodgazer Reunion
        [213163] = true, -- Snowfeather Hunter - Snowfeather Reunion
        [213164] = true, -- Brilliant Direbeak - Direbeak Reunion
        [213165] = true, -- Viridian Sharptalon - Sharptalon Reunion
        [215159] = true, -- Long-Forgotten Hippogryph - Ephemeral Crystal x5
        [230987] = true, -- Arcanist's Manasaber - Fate of the Nightborne
        [299159] = true, -- Scrapforged Mechaspider - Drive It Away Today
        [312754] = true, -- Battle Gargon Vrednic - venthyr campaign quest
        [312759] = true, -- Dreamlight Runestag - night fae campaign quest
        [312761] = true, -- Enchanted Dreamlight Runestag - night fae campaign quest
        [316339] = true, -- Shadowbarb Drone - Uldum
        [316802] = true, -- Springfur Alpaca - Uldum
        [332455] = true, -- War-Bred Tauralus - necrolord campaign quest
        [332462] = true, -- Armored War-Bred Tauralus - necrolord covenant quest
        [332904] = true, -- Harvester's Dredwing - Venthyr Assault
        [332932] = true, -- Crypt Gargon - venthyr campaign quest
        [333027] = true, -- Loyal Gorger - Revendreth
        [334391] = true, -- Phalynx of Courage - kyrian campaign quest
        [334406] = true, -- Eternal Phalynx of Courage - kyrian campaign quest
        [339588] = true, -- Sinrunner Blanchy - treasure quest chain
        [344577] = true, -- Bound Shadehound (secret)
        [352441] = true, -- Wild Hunt Legsplitter - Night Fae Assault
        [352742] = true, -- Undying Darkhound - Necrolord Assault
        [354358] = true, -- Darkmaul - Korthia - Darkmaul treasure quest
        [354361] = true, -- Dusklight Razorwing - Korthia - random eggs
        [354362] = true, -- Maelie the Wanderer - Korthia - treasure quest chain
        [360954] = true, -- Highland Drake
        [363701] = true, -- Patient Bufonid - Zereth Mortis - treasure quest chain
        [368893] = true, -- Winding Slitherdrake
        [368896] = true, -- Renewed Proto-Drake
        [368899] = true, -- Windborne Velocidrake
        [368901] = true, -- Cliffside Wylderdrake
        [374247] = true, -- Lizi, Thunderspine Tramper
        [376873] = true, -- Otto
        [385738] = true, -- Temperamental Skyclaw
        [395644] = true, -- Divine Kiss of Ohn'ahra
        [407555] = true, -- Tarecgosa's Visage
        [408313] = true, -- Big Slick in the City
        [413409] = true, -- Highland Drake
        [413825] = true, -- Scarlet Pterrordax
        [413827] = true, -- Harbor Gryphon
        [417548] = true, -- Renewed Proto-Drake
        [417552] = true, -- Windborne Velocidrake
        [417554] = true, -- Cliffside Wylderdrake
        [417556] = true, -- Winding Slitherdrake
        [412088] = true, -- Grotto Netherwing Drake
        [425338] = true, -- Flourishing Whimsydrake
        [427041] = true, -- Ochre Dreamtalon
        [430225] = true, -- Gilnean Prowler
        [446052] = true, -- Delver's Dirigible
        [451489] = true, -- Siesbarg
        [466027] = true, -- Darkfuse Spy-Eye -- WQ
        [466133] = true, -- Delver's Gob-Trotter -- I Want My Hat Back
        [474086] = true, -- Prismatic Snapdragon
        [1221132] = true, -- Resplendent K'arroc
        [1224048] = true, -- Delver's Mana-Skimmer
        [1233559] = true, -- Blue Barry
        [1242272] = true, -- Royal Voidwing
        [353264] = true, -- Xy Trustee's Gearglider
        [1233516] = true, -- K'arroc Swiftwing
        [1261391] = true, -- Relinquished Scarlet Charger

        ------------------------------
        -- Alliance ------------------
        ------------------------------

        [136163] = true, -- Grand Gryphon - Operation: Shieldwall; The Silence
        [259741] = true, -- Honeyback Harvester - Leaving the Hive: Harvester
        [300147] = true, -- Deepcoral Snapdragon - Wild Tame
        [369666] = true, -- Grimhowl - Good Fiery Boy

        ------------------------------
        -- Horde ---------------------
        ------------------------------

        [136164] = true, -- Grand Wyvern - Dominance Offensive; Breath of Darkest Shadow
        [267270] = true, -- Kua'fon - Down, But Not Out
        [297560] = true, -- Child of Torcali - Wander Not Alone
        [300146] = true, -- Snapdragon Kelpstalker - Good Girl
        [370620] = true, -- Elusive Emerald Hawkstrider - Blood Knight
    },

    ["Vendor"] = {
        -- sourceType = 3
        ------------------------------
        -- Alliance & Horde ----------
        ------------------------------

        [122708] = true, -- Grand Expedition Yak
        [127216] = true, -- Grey Riding Yak
        [127220] = true, -- Blonde Riding Yak
        [171616] = true, -- Witherhide Cliffstomper
        [171628] = true, -- Rocktusk Battleboar - Trader Araanda, Trader Darakk
        [171825] = true, -- Mosshide Riverwallow
        [213115] = true, -- Bloodfang Widow - The Mad Merchant
        [214791] = true, -- Brinedeep Bottom-Feeder - Conjurer Margoss
        [227956] = true, -- Arcadian War Turtle - Xur'ios
        [259740] = true, -- Green Marsh Hopper
        [266925] = true, -- Siltwing Albatross - Island expedition
        [279474] = true, -- Palehide Direhorn
        [288506] = true, -- Sandy Nightsaber
        [288587] = true, -- Blue Marsh Hopper
        [288589] = true, -- Yellow Marsh Hopper
        [288711] = true, -- Saltwater Seahorse - Island expedition
        [294143] = true, -- X-995 Mechanocat
        [300151] = true, -- Inkscale Deepseeker
        [300153] = true, -- Crimson Tidestallion
        [316340] = true, -- Wicked Swarmer
        [318051] = true, -- Silky Shimmermoth - Ardenweald
        [332243] = true, -- Shadeleaf Runestag - night fae renown vendor
        [332245] = true, -- Winterborn Runestag - night fae feature vendor
        [332246] = true, -- Enchanted Shadeleaf Runestag - night fae renown vendor
        [332248] = true, -- Enchanted Winterborn Runestag - night fae feature vendor
        [332456] = true, -- Plaguerot Tauralus - necrolord renown vendor
        [332464] = true, -- Armored Plaguerot Tauralus - necrolord renown vendor
        [332927] = true, -- Sinfall Gargon - venthyr renown vendor
        [333021] = true, -- Gravestone Battle Armor - venthyr renown vendor
        [334386] = true, -- Phalynx of Humility - kyrian renown vendor
        [334398] = true, -- Phalynx of Purity - kyrian renown vendor
        [334403] = true, -- Eternal Phalynx of Purity - kyrian renown vendor
        [334408] = true, -- Eternal Phalynx of Loyalty - kyrian feature vendor
        [334409] = true, -- Eternal Phalynx of Humility - kyrian feature vendor
        [340503] = true, -- Umbral Scythehorn - night fae feature vendor
        [342667] = true, -- Vibrant Flutterwing - night fae feature vendor
        [349935] = true, -- Noble Bruffalon
        [352926] = true, -- Skyskin Hornstrider - Brendormi
        [359409] = true, -- Iskaara Trader's Ottuk - Tattukiaka
        [371176] = true, -- Subterranean Magmammoth
        [373859] = true, -- Loyal Magmammoth - Yries Lightfingers
        [374098] = true, -- Stormhide Salamanther
        [374162] = true, -- Scrappy Worldsnail - Dealer Vexil
        [374204] = true, -- Explorer's Stonehide Packbeast - Azerothian Archivists
        [376875] = true, -- Brown Scouting Ottuk - Tatto
        [376879] = true, -- Ivory Trader's Ottuk - Tattukiaka
        [376880] = true, -- Yellow Scouting Ottuk - Tatto
        [376910] = true, -- Brown War Ottuk - Tatto
        [376913] = true, -- Yellow War Ottuk - Tatto
        [384963] = true, -- Guardian Vorquin - dracthyr vendor
        [385115] = true, -- Swift Armored Vorquin - dracthyr vendor
        [385131] = true, -- Armored Vorquin Leystrider - dracthyr vendor
        [385134] = true, -- Majestic Armored Vorquin - dracthyr vendor
        [385262] = true, -- Duskwing Ohuna
        [394216] = true, -- Crimson Vorquin - dracthyr vendor
        [394218] = true, -- Sapphire Vorquin - dracthyr vendor
        [394219] = true, -- Bronze Vorquin - dracthyr vendor
        [394220] = true, -- Obsidian Vorquin - dracthyr vendor
        [408627] = true, -- Igneous Shalewing
        [408653] = true, -- Boulder Hauler
        [408655] = true, -- Morsel Sniffer
        [414316] = true, -- White War Wolf - Time Rift vendor
        [414323] = true, -- Ravenous Black Gryphon - Time Rift vendor
        [414324] = true, -- Gold-Toed Albatross - Time Rift vendor
        [414326] = true, -- Felstorm Dragon - Time Rift vendor
        [414327] = true, -- Sulfur Hound - Time Rift vendor
        [414328] = true, -- Perfected Juggernaut - Time Rift vendor
        [414334] = true, -- Scourgebound Vanquisher - Time Rift vendor
        [423871] = true, -- Blossoming Dreamstag - Emerald Dream vendor
        [423873] = true, -- Suntouched Dreamstag - Emerald Dream Renown vendor
        [423877] = true, -- Rekindled Dreamstag - Emerald Dream vendor
        [423891] = true, -- Lunar Dreamstag - Emerald Dream Renown vendor
        [424479] = true, -- Evening Sun Dreamsaber - Emerald Dream vendor
        [424482] = true, -- Mourning Flourish Dreamsaber - Emerald Dream vendor
        [426955] = true, -- Springtide Dreamtalon - Emerald Dream vendor
        [427043] = true, -- Snowfluff Dreamtalon - Emerald Dream vendor
        [427222] = true, -- Delugen - Emerald Dream vendor
        [427224] = true, -- Talont - Emerald Dream vendor
        [427226] = true, -- Stargrazer - Emerald Dream vendor
        [427546] = true, -- Mammyth - Emerald Dream vendor
        [427549] = true, -- Imagiwing - Emerald Dream vendor
        [427724] = true, -- Salatrancer - Emerald Dream vendor
        [428060] = true, -- Golden Regal Scarab

        -- War Within
        [447057] = true, -- Smoldering Cinderbee
        [447151] = true, -- Soaring Meaderbee
        [447176] = true, -- Cyan Glowmite
        [447185] = true, -- Aquamarine Swarmite
        [447957] = true, -- Ferocious Jawcrawler
        [448680] = true, -- Widow's Undercrawler
        [448685] = true, -- Heritage Undercrawler
        [448689] = true, -- Royal Court Undercrawler
        [448939] = true, -- Shackled Shadow
        [448978] = true, -- Vermillion Imperial Lynx
        [449269] = true, -- Crimson Mudnose
        [449418] = true, -- Shale Ramolith
        [465999] = true, -- Crimson Armored Growler -- renown
        [466000] = true, -- Darkfuse Chompactor -- Gallagio Rewards Club 17
        [466002] = true, -- Violet Armored Growler -- renown
        [466011] = true, -- Furious Flarendo -- Gallagio Rewards Club 20
        [466012] = true, -- Thunderdrum Misfire -- Gallagio Rewards Club 8
        [466013] = true, -- Ocher Delivery Rocket -- renown
        [466016] = true, -- The Topskimmer Special -- renown
        [466017] = true, -- Innovation Investigator -- Mechanica vendor
        [466018] = true, -- Darkfuse Demolisher -- ?
        [466019] = true, -- Blackwater Shredder Deluxe Mk 2 -- renown
        [466023] = true, -- Asset Advocator -- Mechanica vendor
        [466025] = true, -- Margin Manipulator -- Mechanica vendor
        [466028] = true, -- Mean Green Flying Machine -- renown
        [473137] = true, -- Soweezi's Vintage Waveshredder
        [1218316] = true, -- Corruption of the Aspects
        [1226421] = true, -- Radiant Imperial Lynx -- renown
        [1233518] = true, -- Lavender K'arroc
        [1233547] = true, -- Acidic Void Creeper

        -- Midnight
        [447173] = true, -- Elder Glowmite
        [451487] = true, -- Retrained Skyrazor
        [1243593] = true, -- Fierce Grimlynx
        [1251433] = true, -- Amani Sunfeather
        [1251630] = true, -- Amani Windcaller
        [1253929] = true, -- Cerulean Sporeglider
        [1261291] = true, -- Fiery Dragonhawk
        [1261322] = true, -- Crimson Silvermoon Hawkstrider
        [1261336] = true, -- Preyseeker's Hubris
        [1261337] = true, -- Preyseeker's Wrath
        [1261348] = true, -- Blessed Amani Burrower
        [1261357] = true, -- Amani Blessed Bear
        [1261584] = true, -- Prowling Shredclaw
        [1261585] = true, -- Frenzied Shredclaw
        [1268924] = true, -- Silvermoon's Arcane Defender
        [1268926] = true, -- Elven Arcane Guardian
        [1270675] = true, -- Vivid Chloroceros

        ------------------------------
        -- Alliance ------------------
        ------------------------------

        [171846] = true, -- Champion's Treadblade

        -- pre 1.4
        [15780] = true, -- Green Mechanostrider
        [33630] = true, -- Green Mechanostrider

        -- Stormwind
        [32235] = true, -- Golden Gryphon
        [32239] = true, -- Ebon Gryphon
        [32240] = true, -- Snowy Gryphon
        [32242] = true, -- Swift Blue Gryphon
        [32289] = true, -- Swift Red Gryphon
        [32290] = true, -- Swift Green Gryphon
        [32292] = true, -- Swift Purple Gryphon

        -- Kirin Tor
        [59791] = true, -- Wooly Mammoth - Alliance
        [60114] = true, -- Armored Brown Bear - Alliance
        [61229] = true, -- Armored Snowy Gryphon
        [61425] = true, -- Traveler's Tundra Mammoth - Alliance

        -- Warfront Service Medal
        [288740] = true, -- Priestess' Moonsaber
        [288736] = true, -- Azureshell Krolusk

        ------------------------------
        -- Horde ---------------------
        ------------------------------

        -- pre 1.4
        [578] = true, -- Black Wolf

        -- Orgrimmar
        [32243] = true, -- Tawny Wind Rider
        [32244] = true, -- Blue Wind Rider
        [32245] = true, -- Green Wind Rider
        [32246] = true, -- Swift Red Wind Rider
        [32295] = true, -- Swift Green Wind Rider
        [32296] = true, -- Swift Yellow Wind Rider
        [32297] = true, -- Swift Purple Wind Rider

        -- Kirin Tor
        [59793] = true, -- Wooly Mammoth - Horde
        [60116] = true, -- Armored Brown Bear - Horde
        [61230] = true, -- Armored Blue Wind Rider
        [61447] = true, -- Traveler's Tundra Mammoth - Horde

        -- Warfront Service Medal
        [288714] = true, -- Bloodthirsty Dreadwing
        [288735] = true, -- Rubyshell Krolusk
    },

    ["Profession"] = {
        sourceType = { 4 },
        [30174] = true, -- Riding Turtle
        [121838] = true, -- Ruby Panther
    },

    ["Instance"] = {
        -- spellId => {JournalEncounterID, difficultyId}
        -- look for JournalEncounterID in JournalEncounterItem with ItemId
        -- https://warcraft.wiki.gg/wiki/JournalEncounterID

        -- Dungeon
        -- difficulty: 1=Normal; 2=Heroic; 23=Mythic
        [17481] = { 456, 0 }, -- Rivendare's Deathcharger - Stratholme, Lord Aurius Rivendare
        [41252] = { 542, 2 }, -- Raven Lord - Sethekk Halls, Anzu
        [46628] = { 533, 2}, -- Swift White Hawkstrider - Magisters' Terrace, Kael'thas Sunstrider
        [59569] = true, -- Bronze Drake - The Culling of Stratholme, Infinite Corruptor
        [59996] = { 643, 2 }, -- Blue Proto-Drake - Utgarde Pinnacle, Skadi
        [88742] = { 115, 0 }, -- Drake of the North Wind - The Vortex Pinnacle, Altarius
        [88746] = { 111, 0 }, -- Vitreous Stone Drake - The Stonecore, Slabhide
        [96491] = { 176, 0 }, -- Armored Razzashi Raptor - Zul'Gurub, Bloodlord Mandokir
        [96499] = { 181, 0 }, -- Swift Zulian Panther - Zul'Gurub, High Priestess Kilnara
        [231428] = true, -- Smoldering Ember Wyrm - Return to Karazhan timerun
        [229499] = { 1835, 23 }, -- Midnight - Return to Karazhan
        [254813] = { 2095, 23 }, -- Sharkbait - Freehold (Mythic)
        [266058] = { 2172, 23 }, -- Tomb Stalker - Kings' Rest (Mythic)
        [273541] = { 2158, 23 }, -- Underrot Crawg - The Underrot (Mythic)
        [290718] = { 2331, 23 }, -- Aerial Unit R-21/X - King Mechagon
        [299158] = { 2355, 23 }, -- Mechagon Peacekeeper - Mechagon
        [336036] = { 2396, 23 }, -- Marrowfang - The Necrotic Wake
        [346141] = true, -- Slime Serpent - Plaguefall (secret)
        [353263] = { 2455, 2 }, -- Cartel Master's Gearglider - Tazavesh, the Veiled Market
        [363178] = true, -- Colossal Umbrahide Mawrat - Torghast 13+
        [442358] = { 2582, 23 }, -- Stonevault Mechasuit -- Stonevault mythic
        [449264] = { 2561, 23 }, -- Wick - Darkflame Cleft
        [428068] = true, -- Felreaver Deathcycle - Vision of Stormwind/Orgrimmar (Revisited)
        [447189] = true, -- Nesting Swarmite - Vision of Stormwind/Orgrimmar (Revisited)
        [1218229] = true, -- Void-Scarred Gryphon - Vision of Stormwind (Revisited)
        [1218305] = true, -- Void-Forged Stallion - Vision of Stormwind (Revisited)
        [1218306] = true, -- Void-Scarred Pack Mother - Vision of Orgrimmar (Revisited)
        [1218307] = true, -- Void-Scarred Windrider - Vision of Orgrimmar (Revisited)
        [1265784] = true, -- Lucent Hawkstrider - Magister's Terrace (?)

        -- Raid
        -- difficulty: 3=10Normal; 4=25Normal; 5=10Hero; 6=25Hero; 14=Normal; 15=Hero; 16=Mythic; 17=LFR
        [25953] = true, -- Blue Qiraji Battle Tank - Temple of Ahn'Qiraj
        [26054] = true, -- Red Qiraji Battle Tank - Temple of Ahn'Qiraj
        [26055] = true, -- Yellow Qiraji Battle Tank - Temple of Ahn'Qiraj
        [26056] = true, -- Green Qiraji Battle Tank - Temple of Ahn'Qiraj
        [36702] = { 1553, 0 }, -- Fiery Warhorse - Karazhan, Attumen the Huntsman
        [40192] = { 1576, 0 }, -- Ashes of Al'ar - The Eye, Kael'thas Sunstrider
        [59567] = { 1617, 0 }, -- Azure Drake - The Eye of Eternity, Malygos
        [59568] = { 1617, 0 }, -- Blue Drake - The Eye of Eternity, Malygos
        [59571] = { 1616, 4 }, -- Twilight Drake - The Obsidian Sanctum, Sartharion
        [59650] = { 1616, 3 }, -- Black Drake - The Obsidian Sanctum, Sartharion
        [61465] = { 1597, 0}, -- Grand Black War Mammoth - Vault of Archavon, Alliance
        [61467] = { 1597, 0}, -- Grand Black War Mammoth - Vault of Archavon, Horde
        [69395] = { 1651, 0 }, -- Onyxian Drake - Onyxia's Lair, Onyxia
        [63796] = { 1649, 0 }, -- Mimiron's Head - Ulduar, Yogg-Saron
        [72286] = { 1636, 6 }, -- Invincible - Icecrown Citadel, The Lich King
        [88744] = { 155, 0 }, -- Drake of the South Wind - Throne of Four Winds, Al'Akir
        [97493] = { 198, 0 }, -- Pureblood Fire Hawk - Firelands, Ragnaros
        [101542] = { 194, 0 }, -- Flametalon of Alysrazor - Firelands, Alysrazor
        [107842] = { 333, 3 }, -- Blazing Drake - Dragon Soul, Deathwing
        [107845] = { 333, 6 }, -- Life-Binder's Handmaiden - Dragon Soul, Deathwing
        [110039] = { 331, 3 }, -- Experiment 12-B - Dragon Soul, Ultraxion
        [127170] = { 726, 3 }, -- Astral Cloud Serpent - Mogu'shan Vaults, Elegon
        [136471] = { 819, 3 }, -- Spawn of Horridon - Throne of Thunder, Horridon
        [139448] = { 828, 3 }, -- Clutch of Ji-Kun - Throne of Thunder, Ji-Kun
        [148417] = { 869, 16 }, -- Kor'kron Juggernaut - Siege of Orgrimmar, Garrosh Hellscream Mythic
        [171621] = { 959, 16 }, -- Ironhoof Destroyer - Blackrock Foundry, Blackhand Mythic
        [182912] = { 1438, 16 }, -- Felsteel Annihilator - Hellfire Citadel, Archimonde
        [213134] = { 1737, 14 }, -- Felblaze Infernal - The Nighthold, Gul'dan
        [171827] = { 1737, 16 }, -- Hellfire Infernal - The Nighthold, Gul'dan (Mythic)
        [232519] = { 1861, 14 }, -- Abyss Worm - Tomb of Sargeras, Mistress Sassz'ine
        [253088] = { 1987, 14 }, -- Antoran Charhound - Antorus, Shatug
        [243651] = { 2031, 16 }, -- Shackled Ur'zul - Antorus, Argus Mythic
        [289083] = { 2334, 14 }, -- G.M.O.D. - Battle of Dazar'alor
        [289555] = { 2343, 16 }, -- Glacial Tidestorm - Battle of Dazar'alor
        [308814] = { 2375, 16 }, -- Ny'alotha Allseer - Mythic N'Zoth, Ny'alotha
        [351195] = { 2441, 16 }, -- Vengeance - Sylvanas Mythic
        [354351] = { 2439, 14 }, -- Sanctum Gloomcharger - The Nine, Sanctum of Domination
        [368158] = { 2464, 16 }, -- Zereth Overseer - The Jailer, Sepulcher of the First Ones
        [413922] = true, -- Valiance -- Naxxramas - Discovery
        [424484] = { 2519, 16 }, -- Anu'relos -- Amirdrassil - Fyrak Mythic
        [451486] = { 2602, 17 }, -- Sureki Skyrazor -- Nerub-ar Palace
        [451491] = { 2602, 16 }, -- Ascendant Skyrazor -- Nerub-ar Palace Mythic
        [1217760] = { 2646, 16 }, -- The Big G -- Liberation of Undermine Mythic
        [1221155] = { 2646, 17 }, -- Prototype A.S.M.R. -- Liberation of Undermine
        [1234573] = { 2691, 16 }, -- Unbound Star-Eater -- Manaforge Omega Hc
        [1242272] = true, -- Royal Voidwing -- Manaforge Omega Hc
        [1242904] = { 2740, 16 }, -- Ashes of Belo'ren -- March on Quel Danas Mythic
    },

    ["Reputation"] = {
        ------------------------------
        -- Alliance & Horde ----------
        ------------------------------

        -- Sha'tari Skyguard
        [39798] = true, -- Green Riding Nether Ray
        [39800] = true, -- Red Riding Nether Ray
        [39801] = true, -- Purple Riding Nether Ray
        [39802] = true, -- Silver Riding Nether Ray
        [39803] = true, -- Blue Riding Nether Ray

        -- Netherwing
        [41513] = true, -- Onyx Netherwing Drake
        [41514] = true, -- Azure Netherwing Drake
        [41515] = true, -- Cobalt Netherwing Drake
        [41516] = true, -- Purple Netherwing Drake
        [41517] = true, -- Veridian Netherwing Drake
        [41518] = true, -- Violet Netherwing Drake

        -- Cenarion Expedition
        [43927] = true, -- Cenarion War Hippogryph

        -- The Storm Peaks
        [54753] = true, -- White Polar Bear - Quest from Gretta the Arbiter

        -- The Wyrmrest Accord
        [59570] = true, -- Red Drake

        -- Argent Tournament
        [63844] = true, -- Argent Hippogryph
        [66906] = true, -- Argent Charger
        [67466] = true, -- Argent Warhorse

        -- Ramkahen
        [88748] = true, -- Brown Riding Camel
        [88749] = true, -- Tan Riding Camel

        -- Tol Barad
        [88741] = true, -- Drake of the West Wind

        -- The Anglers
        [118089] = true, -- Azure Water Strider

        -- The Klaxxi
        [123886] = true, -- Amber Scorpion

        -- Order of the Cloud Serpent
        [113199] = true, -- Jade Cloud Serpent
        [123992] = true, -- Azure Cloud Serpent
        [123993] = true, -- Golden Cloud Serpent

        -- Golden Lotus
        [127174] = true, -- Azure Riding Crane
        [127176] = true, -- Golden Riding Crane
        [127177] = true, -- Regal Riding Crane

        -- Tushui Pandaren/Huojin Pandaren
        [120822] = true, -- Great Red Dragon Turtle
        [120395] = true, -- Green Dragon Turtle
        [127286] = true, -- Black Dragon Turtle
        [127287] = true, -- Blue Dragon Turtle
        [127288] = true, -- Brown Dragon Turtle
        [127289] = true, -- Purple Dragon Turtle
        [127290] = true, -- Red Dragon Turtle
        [127293] = true, -- Great Green Dragon Turtle
        [127295] = true, -- Great Black Dragon Turtle
        [127302] = true, -- Great Blue Dragon Turtle
        [127308] = true, -- Great Brown Dragon Turtle
        [127310] = true, -- Great Purple Dragon Turtle

        -- Shado-Pan
        [127154] = true, -- Onyx Cloud Serpent - From Quest Surprise Attack!
        [129932] = true, -- Green Shado-Pan Riding Tiger
        [129934] = true, -- Blue Shado-Pan Riding Tiger
        [129935] = true, -- Red Shado-Pan Riding Tiger

        -- The Tillers
        [130086] = true, -- Brown Riding Goat
        [130137] = true, -- White Riding Goat
        [130138] = true, -- Black Riding Goat

        -- The August Celestials
        [129918] = true, -- Thundering August Cloud Serpent

        -- The Lorewalkers
        [130092] = true, -- Red Flying Cloud

        -- Emperor Shaohao
        [127164] = true, -- Heavenly Golden Cloud Serpent

        -- The Saberstalkers
        [171633] = true, -- Wild Goretusk
        [190690] = true, -- Bristling Hellboar

        -- Steamwheedle Preservation Society
        [171634] = true, -- Domesticated Razorback

        -- Arakkoa Outcasts
        [171829] = true, -- Shadowmane Charger

        -- Order of the Awakened
        [183117] = true, -- Corrupted Dreadwing

        -- Vol'jin's Headhunters, Hand of the Prophet
        [190977] = true, -- Deathtusk Felboar

        [230401] = true, -- White Hawkstrider -- Talon's Vengeance
        [242305] = true, -- Sable Ruinstrider -- Argussian Reach
        [253004] = true, -- Amethyst Ruinstrider -- Argussian Reach
        [253005] = true, -- Beryl Ruinstrider -- Argussian Reach
        [253006] = true, -- Russet Ruinstrider -- Argussian Reach
        [253007] = true, -- Cerulean Ruinstrider -- Argussian Reach
        [253008] = true, -- Umber Ruinstrider -- Argussian Reach
        [239013] = true, -- Lightforged Warframe -- Army of the Light
        [242881] = true, -- Cloudwing Hippogryph - Farondis cache (paragon)
        [242874] = true, -- Highmountain Elderhorn - Highmountain Supplies (paragon)
        [233364] = true, -- Leywoven Flying Carpet - Nightfallen Cache (paragon)
        [242882] = true, -- Valarjar Stormwing - Valarjar Strongbox (paragon)
        [242875] = true, -- Wild Dreamrunner - Dreamweaver Cache (paragon)
        [254258] = true, -- Blessed Felcrusher - Army of the Light Cache (paragon)
        [254259] = true, -- Avenging Felcrusher - Army of the Light Cache (paragon)
        [254069] = true, -- Glorious Felcrusher - Army of the Light Cache (paragon)

        [294038] = true, -- Royal Snapdragon - Nazjatar (supplies/paragon)
        [299170] = true, -- Rustbolt Resistor -- Rustbolt Resistance
        [316276] = true, -- Wastewander Skyterror -- Uldum Accord

        [327405] = true, -- Colossal Slaughterclaw - Supplies of the Undying Army (paragon)
        [332256] = true, -- Duskflutter Ardenmoth - Wild Hunt
        [332484] = true, -- Lurid Bloodtusk - The Undying Army
        [332923] = true, -- Inquisition Gargon - The Avowed
        [341639] = true, -- Court Sinrunner -- Court of Harvesters
        [342334] = true, -- Gilded Prowler - The Ascended
        [342666] = true, -- Amber Ardenmoth - Wild Hunt Supplies (paragon)
        [347251] = true, -- Soaring Razorwing - Korthia - The Archivists' Codex - Tier 6
        [347536] = true, -- Tamed Mauler - Korthia - Supplies of the Archivists' Codex
        [347810] = true, -- Beryl Shardhide - Korthia - Death's Advance Supplies
        [354352] = true, -- Soulbound Gloomcharger - The Maw - Mysterious Gift from Ve'nari
        [354356] = true, -- Amber Shardhide - Korthia - Death's Advance
        [354359] = true, -- Fierce Razorwing - Korthia - Death's Advance Supplies
        [359229] = true, -- Heartlight Vombata - Zereth Mortis - The Enlightened
        [359276] = true, -- Anointed Protostag - Zereth Mortis - The Enlightened

        [374204] = true, -- Explorer's Stonehide Packbeast - Azerothian Archivists
        [374034] = true, -- Azure Skitterfly - Dragonscale Expedition
        [374048] = true, -- Verdant Skitterfly - Dragonscale Expedition
        [374032] = true, -- Tamed Skitterfly - Dragonscale Expedition
        [376875] = true, -- Brown Scouting Ottuk - Iskaara Tuskar - Renown 34
        [376880] = true, -- Yellow Scouting Ottuk - Iskaara Tuskar - Renown 34
        [376910] = true, -- Brown War Ottuk - Iskaara Tuskarr - Renown 30
        [376913] = true, -- Yellow War Ottuk - Iskaara Tuskarr - Renown 30
        [408655] = true, -- Morsel Sniffer - Niffel Renown 18
        [423873] = true, -- Suntouched Dreamstag - Emerald Dream Renown vendor
        [423891] = true, -- Lunar Dreamstag - Emerald Dream Renown vendor

        [353265] = true, -- Vandal's Gearglider -- Manaforge Vandals Renown 8
        [447057] = true, -- Smoldering Cinderbee
        [447176] = true, -- Cyan Glowmite
        [447185] = true, -- Aquamarine Swarmite
        [447957] = true, -- Ferocious Jawcrawler
        [448680] = true, -- Widow's Undercrawler
        [448685] = true, -- Heritage Undercrawler
        [448689] = true, -- Royal Court Undercrawler
        [448939] = true, -- Shackled Shadow
        [448978] = true, -- Vermillion Imperial Lynx
        [449269] = true, -- Crimson Mudnose
        [449418] = true, -- Shale Ramolith
        [465999] = true, -- Crimson Armored Growler -- renown
        [466000] = true, -- Darkfuse Chompactor -- Gallagio Rewards Club 17
        [466001] = true, -- Blackwater Bonecrusher -- Trove from weekly reputation or maybe from paragon grind ?
        [466002] = true, -- Violet Armored Growler -- renown
        [466011] = true, -- Furious Flarendo -- Gallagio Rewards Club 20
        [466012] = true, -- Thunderdrum Misfire -- Gallagio Rewards Club 8
        [466013] = true, -- Ocher Delivery Rocket -- renown
        [466014] = true, -- Steamwheedle Supplier -- Trove
        [466016] = true, -- The Topskimmer Special -- renown
        [466018] = true, -- Darkfuse Demolisher -- ?
        [466019] = true, -- Blackwater Shredder Deluxe Mk 2 -- renown
        [466022] = true, -- Venture co-ordinator -- Trove
        [466024] = true, -- Bilgewater Bombardier -- Trove
        [466028] = true, -- Mean Green Flying Machine -- renown
        [473188] = true, -- Bronze Goblin Waveshredder -- Trove
        [1226421] = true, -- Radiant Imperial Lynx -- renown
        [1223187] = true, -- Terror of the Wastes -- K'aresh Trust renown 19
        [1233542] = true, -- The Bone Freezer - Manaforge Vandals renown 14
        [1233546] = true, -- Ruby Void Creeper - K'aresh Trust 15
        [1264621] = true, -- Brawlin' Bruno -- Brawlers Guild
        [1264643] = true, -- Ballistic Bronco -- Brawlers Guild

        ------------------------------
        -- Alliance ------------------
        ------------------------------

        -- Stormwind
        [458] = true, -- Brown Horse
        [470] = true, -- Black Stallion
        [472] = true, -- Pinto
        [6648] = true, -- Chestnut Mare
        [23227] = true, -- Swift Palomino
        [23228] = true, -- Swift White Steed
        [23229] = true, -- Swift Brown Steed

        -- Ironforge
        [6777] = true, -- Gray Ram
        [6898] = true, -- White Ram
        [6899] = true, -- Brown Ram
        [23238] = true, -- Swift Brown Ram
        [23239] = true, -- Swift Gray Ram
        [23240] = true, -- Swift White Ram

        -- Gnomeregan
        [10873] = true, -- Red Mechanostrider
        [10969] = true, -- Blue Mechanostrider
        [17453] = true, -- Green Mechanostrider
        [17454] = true, -- Unpainted Mechanostrider
        [23222] = true, -- Swift Yellow Mechanostrider
        [23223] = true, -- Swift White Mechanostrider
        [23225] = true, -- Swift Green Mechanostrider

        -- Darnassus
        [8394] = true, -- Striped Frostsaber
        [10793] = true, -- Striped Nightsaber
        [10789] = true, -- Spotted Frostsaber
        [23219] = true, -- Swift Mistsaber
        [23221] = true, -- Swift Frostsaber
        [23338] = true, -- Swift Stormsaber
        [66847] = true, -- Striped Dawnsaber

        -- Exodar
        [34406] = true, -- Brown Elekk
        [35710] = true, -- Gray Elekk
        [35711] = true, -- Purple Elekk
        [35712] = true, -- Great Green Elekk
        [35713] = true, -- Great Blue Elekk
        [35714] = true, -- Great Purple Elekk

        -- Gilneas
        [103195] = true, -- Mountain Horse
        [103196] = true, -- Swift Mountain Horse

        -- Wintersaber Trainers
        [17229] = true, -- Winterspring Frostsaber

        -- Kurenai & Mag'har
        [34896] = true, -- Cobalt War Talbuk
        [34897] = true, -- White War Talbuk
        [34898] = true, -- Silver War Talbuk
        [34899] = true, -- Tan War Talbuk
        [39315] = true, -- Cobalt Riding Talbuk
        [39317] = true, -- Silver Riding Talbuk
        [39318] = true, -- Tan Riding Talbuk
        [39319] = true, -- White Riding Talbuk

        -- The Sons of Hodir
        [59799] = true, -- Ice Mammoth - Alliance
        [61470] = true, -- Grand Ice Mammoth - Alliance

        -- Argent Tournament
        [63232] = true, -- Stormwind Steed
        [63636] = true, -- Ironforge Ram
        [63637] = true, -- Darnassian Nightsaber
        [63638] = true, -- Gnomeregan Mechanostrider
        [63639] = true, -- Exodar Elekk
        [65637] = true, -- Great Red Elekk
        [65638] = true, -- Swift Moonsaber
        [65640] = true, -- Swift Gray Steed
        [65642] = true, -- Turbostrider
        [65643] = true, -- Swift Violet Ram

        -- The Silver Covenant
        [66087] = true, -- Silver Covenant Hippogryph
        [66090] = true, -- Quel'dorei Steed

        -- Tol Barad
        [92231] = true, -- Spectral Steed

        -- Operation: Shieldwall
        [135416] = true, -- Grand Armored Gryphon

        -- Kirin Tor Offensive
        [140249] = true, -- Golden Primal Direhorn

        -- Council of Exarchs
        [171625] = true, -- Dusty Rockhide

        -- Order of Embers
        [260173] = true, -- Smoky Charger
        [275859] = true, -- Dusky Waycrest Gryphon

        -- Proudmoore Admiralty
        [259213] = true, -- Admiralty Stallion
        [275868] = true, -- Proudmoore Sea Scout

        -- Storm's Wake
        [260172] = true, -- Dapple Gray
        [275866] = true, -- Stormsong Coastwatcher

        -- Ankoan
        [292407] = true, -- Ankoan Waveray

        ------------------------------
        -- Horde ---------------------
        ------------------------------

        -- Orgrimmar
        [580] = true, -- Timber Wolf
        [6653] = true, -- Dire Wolf
        [6654] = true, -- Brown Wolf
        [23250] = true, -- Swift Brown Wolf
        [23251] = true, -- Swift Timber Wolf
        [23252] = true, -- Swift Gray Wolf
        [64658] = true, -- Black Wolf

        -- Darkspear Trolls
        [8395] = true, -- Emerald Raptor
        [10796] = true, -- Turquoise Raptor
        [10799] = true, -- Violet Raptor
        [23241] = true, -- Swift Blue Raptor
        [23242] = true, -- Swift Olive Raptor
        [23243] = true, -- Swift Orange Raptor

        -- Undercity
        [17462] = true, -- Red Skeletal Horse
        [17463] = true, -- Blue Skeletal Horse
        [17464] = true, -- Brown Skeletal Horse
        [17465] = true, -- Green Skeletal Warhorse
        [23246] = true, -- Purple Skeletal Warhorse
        [64977] = true, -- Black Skeletal Horse
        [66846] = true, -- Ochre Skeletal Warhorse

        -- Thunder Bluff
        [18989] = true, -- Gray Kodo
        [18990] = true, -- Brown Kodo
        [23247] = true, -- Great White Kodo
        [23248] = true, -- Great Gray Kodo
        [23249] = true, -- Great Brown Kodo
        [64657] = true, -- White Kodo

        -- Silvermoon City
        [35027] = true, -- Swift Purple Hawkstrider
        [33660] = true, -- Swift Pink Hawkstrider
        [34795] = true, -- Red Hawkstrider
        [35018] = true, -- Purple Hawkstrider
        [35020] = true, -- Blue Hawkstrider
        [35022] = true, -- Black Hawkstrider
        [35025] = true, -- Swift Green Hawkstrider

        -- Bilgewater Cartel
        [87090] = true, -- Goblin Trike
        [87091] = true, -- Goblin Turbo-Trike

        -- Darkspear Trolls in Un'Goro Crater
        [64659] = true, -- Venomhide Ravasaur

        -- The Sons of Hodir
        [59797] = true, -- Ice Mammoth - Horde
        [61469] = true, -- Grand Ice Mammoth - Horde

        -- The Sunreavers
        [66088] = true, -- Sunreaver Dragonhawk
        [66091] = true, -- Sunreaver Hawkstrider

        -- Argent Tournament
        [63635] = true, -- Darkspear Raptor
        [63641] = true, -- Thunder Bluff Kodo
        [63640] = true, -- Orgrimmar Wolf
        [63642] = true, -- Silvermoon Hawkstrider
        [63643] = true, -- Forsaken Warhorse
        [65645] = true, -- White Skeletal Warhorse
        [65639] = true, -- Swift Red Hawkstrider
        [65641] = true, -- Great Golden Kodo
        [65644] = true, -- Swift Purple Raptor
        [65646] = true, -- Swift Burgundy Wolf

        -- Tol Barad
        [92232] = true, -- Spectral Wolf

        -- Sunreaver Onslaught
        [140250] = true, -- Crimson Primal Direhorn

        -- Dominance Offensive
        [135418] = true, -- Grand Armored Wyvern

        -- Frostwolf Orcs
        [171842] = true, -- Swift Frostwolf

        -- Talanji's Expedition
        [275838] = true, -- Captured Swampstalker
        [275841] = true, -- Expedition Bloodswarmer

        -- Voldunai
        [237287] = true, -- Alabaster Hyena
        [275840] = true, -- Voldunai Dunescraper

        -- Zandalari Empire
        [244712] = true, -- Spectral Pterrorwing
        [275837] = true, -- Cobalt Pterrordax

        -- Unshackled
        [291538] = true, -- Unshackled Waveray
    },

    ["Achievement"] = {
        -- sourceType = 6
        ------------------------------
        -- Alliance & Horde ----------
        ------------------------------

        [60024] = 2144, -- Violet Proto-Drake - What a Long, Strange Trip It's Been
        [60025] = 2143, -- Albino Drake - Leading the Cavalry
        [98204] = 5858, -- Amani Battle Bear - Bear-ly Made It
        [133023] = { 7860, 7862 }, -- Jade Pandaren Kite - We're Going to Need More Saddles
        [127169] = { 10355, 10356 }, -- Heavenly Azure Cloud Serpent - Lord of the Reins

        -- Wrath of the Lichking
        [59961] = 2136, -- Red Proto-Drake - Glory of the Hero
        [63956] = { 2958, 12401 }, -- Ironbound Proto-Drake - Glory of the Ulduar Raider (25 player)
        [63963] = { 2957, 12401 }, -- Rusted Proto-Drake - Glory of the Ulduar Raider (10 player)
        [72807] = 4603, -- Icebound Frostbrood Vanquisher - Glory of the Icecrown Raider (25 player)
        [72808] = 4602, -- Bloodbathed Frostbrood Vanquisher - Glory of the Icecrown Raider (10 player)

        -- Cataclysm
        [97359] = 5866, -- Flameward Hippogryph - The Molten Front Offensive
        [88331] = 4845, -- Volcanic Stone Drake - Glory of the Cataclysm Hero
        [88335] = 4853, -- Drake of the East Wind - Glory of the Cataclysm Raider
        [88990] = true, -- Dark Phoenix - Guild Glory of the Cataclysm Raider
        [97560] = 5828, -- Corrupted Fire Hawk - Glory of the Firelands Raider
        [107844] = 6169, -- Twilight Harbinger - Glory of the Dragon Soul Raider

        -- Mists of Pandaria
        [124408] = true, -- Thundering Jade Cloud Serpent - Guild Glory of the Pandaria Raider
        [127156] = 6927, -- Crimson Cloud Serpent - Glory of the Pandaria Hero
        [127161] = 6932, -- Heavenly Crimson Cloud Serpent - Glory of the Pandaria Raider
        [136400] = 8124, -- Armored Skyscreamer - Glory of the Thundering Raider
        [148392] = 8454, -- Spawn of Galakras - Glory of the Orgrimmar Raider

        -- Warlords of Draenor
        [97501] = { 9598, 9599 }, -- Felfire Hawk - Mountacular
        [170347] = 9550, -- Core Hound - Boldly, You Sought the Power of Ragnaros
        [175700] = 9713, -- Emerald Drake - Awake the Drakes
        [171436] = 8985, -- Gorestrider Gronnling - Glory of the Draenor Raider
        [171627] = true, -- Blacksteel Battleboar - Guild Glory of the Draenor Raider
        [171632] = 9396, -- Frostplains Battleboar - Glory of the Draenor Hero
        [186305] = 10149, -- Infernal Direwolf - Glory of the Hellfire Raider
        [191633] = 10018, -- Soaring Skyterror - Draenor Pathfinder

        -- Legion
        [223814] = 11176, -- Mechanized Lumber Extractor - Remember to Share
        [225765] = 11163, -- Leyfeather Hippogryph - Glory of the Legion Hero
        [215558] = 11066, -- Ratstallion - Underbelly Tycoon
        [193007] = 11180, -- Grove Defiler - Glory of the Legion Raider
        [254260] = 12103, -- Bleakhoof Ruinstrider - ...And Chew Mana Buns
        [253087] = 11987, -- Antoran Gloomhound - Glory of the Argus Raider
        [258022] = 12243, -- Lightforged Felcrusher - Allied Races: Lightforged Draenei
        [258060] = 12245, -- Highmountain Thunderhoof - Allied Races: Highmountain Tauren
        [258845] = 12244, -- Nightborne Manasaber - Allied Races: Nightborne
        [259202] = 12242, -- Starcursed Voidstrider - Allied Races: Void Elf
        [359318] = 15310, -- Soaring Spelltome - A Tour of Towers

        -- Battle for Azeroth
        [213350] = { 12931, 12932 }, -- Frostshard Infernal - No Stable Big Enough
        [280729] = { 12933, 12934 }, -- Frenzied Feltalon - A Horde of Hoofbeats
        [263707] = 13161, -- Zandalari Direhorn - Allied Races: Zandalari Troll
        [267274] = 12518, -- Mag'har Direwolf - Allied Races: Mag'har Orc
        [271646] = 12515, -- Dark Iron Core Hound - Allied Races: Dark Iron Dwarf
        [239049] = 12812, -- Obsidian Krolusk - Glory of the Wartorn Hero
        [250735] = 12806, -- Bloodgorged Crawg - Glory of the Uldir Raider
        [279454] = { 12604, 12605 }, -- Conquerer's Scythemaw - Conqueror of Azeroth
        [280730] = 12866, -- Pureheart Courser - 100 Exalted Reputations
        [289101] = 13315, -- DazarDazar'alor Windreaver - Glory of the Dazar'alor Raider
        [282682] = 13163, -- Kul Tiran Charger - Allied Races: Kul Tiran Human
        [290328] = 13250, -- Wonderwing 2.0 - Battle for Azeroth Pathfinder, Part Two
        [292419] = 13687, -- Azshari Bloatray - Glory of the Eternal Raider
        [294039] = 13638, -- Snapback Scuttler - Undersea Usurper
        [296788] = 13541, -- Mechacycle Model W - Mecha-Done
        [294197] = 13931, -- Obsidian Worldbreaker - Memories of Fel, Frost and Fire
        [305182] = { 13994, 41929 }, -- Black Serpent of N'Zoth - Through the Depths of Visions
        [305592] = 14013, -- Mechagon Mechanostrider - Allied Races: Mechagnome
        [306423] = 13206, -- Caravan Hyena - Allied Races: Vulpera
        [316343] = 14146, -- Wriggling Parasite - Glory of the Ny'alotha Raider
        [405623] = 13541, -- Armadillo Roller - Mecha-Done

        -- Shadowlands
        [318052] = 14520, -- Deathbringer's Flayedwing - Deathbringer
        [332460] = 14751, -- Chosen Tauralus - The Gang's All Here
        [332467] = 14752, -- Armored Chosen Tauralus - Things To Do When You're Dead
        [332903] = 14355, -- Rampart Screecher - Glory of the Nathria Raider
        [344578] = 14570, -- Corridor Creeper - Twisting Corridors: Layer 8
        [344659] = 14322, -- Voracious Gorger - Glory of the Shadowlands Hero
        [339956] = 15089, -- Mawsworn Charger - Flawless Master
        [339957] = 15130, -- Hand of Hrestimorak - Glory of the Dominant Raider
        [346554] = 15178, -- Tazavesh Gearglider - Fake It 'Til You Make It
        [354355] = 15064, -- Hand of Salaranga - Breaking the Chains
        [359379] = 15491, -- Shimmering Aurelid - Glory of the Sepulcher Raider
        [359381] = 15336, -- Cryptic Aurelid - From A to Zereth
        [363136] = 15254, -- Colossal Ebonclaw Mawrat - The Jailer's Gauntlet: Layer 4
        [363297] = 15322, -- Colossal Soulshredder Mawrat - Flawless Master (Layer 16)
        [366791] = 15684, -- Jigglesworth, Sr. - Fates of the Shadowlands Raids

        -- Dragonflight
        [351408] = 19481, -- Bestowed Thunderspine Packleader - Centaur of Attention
        [360954] = 15797, -- Highland Drake - An Azure Ally
        [368893] = 17779, -- Winding Slitherdrake - A Serpentine Discovery
        [368896] = 15794, -- Renewed Proto-Drake - A New Friend
        [368899] = 15795, -- Windborne Velocidrake - Together in the Skies
        [368901] = 15796, -- Cliffside Wylderdrake - Cliffside Companion
        [373967] = 19486, -- Stormtouched Bruffalon - Across the Isles
        [374071] = 19485, -- Bestowed Sandskimmer - Closing Time
        [374097] = 16492, -- Coralscale Salamanther - Into the Storm
        [374155] = 16295, -- Shellack - Glory of the Dragonflight Hero
        [374172] = 19482, -- Bestowed Trawling Mammoth - Army of the Fed
        [374275] = 16355, -- Raging Magmammoth - Glory of the Vault Raider
        [376898] = 19483, -- Bestowed Ottuk Vanguard - Fight Club
        [376912] = { 15833, 15834 }, -- Otterworldly Ottuk Carrier - Thanks for the Carry!
        [385260] = 19479, -- Bestowed Ohuna Spotter - Wake Me Up
        [408648] = 17785, -- Calescent Shalewing - Que Zara(lek), Zara(lek)
        [408649] = 18251, -- Shadowflame Shalewing - Glory of the Aberrus Raider
        [413409] = 15797, -- Highland Drake - An Azure Ally
        [417548] = 15794, -- Renewed Proto-Drake - A New Friend
        [417552] = 15795, -- Windborne Velocidrake - Together in the Skies
        [417554] = 15796, -- Cliffside Wylderdrake - Cliffside Companion
        [417556] = 17779, -- Winding Slitherdrake - A Serpentine Discovery
        [418078] = 18646, -- Pattie - Whodunnit?
        [424474] = 19349, -- Shadow Dusk Dreamsaber - Glory of the Dream Raider
        [424607] = 19458, -- Taivan - A World Awoken
        [439138] = 19574, -- Voyaging Wilderling - Awakening the Dragonflight Raids
        [440444] = 20501, -- Zovaal's Soul Eater - Back from the Beyond

        -- War Within
        [447160] = 40097, -- Raging Cinderbee
        [447190] = 40232, -- Shadowed Swarmite - Glory of the Nerub-ar Raider
        [447195] = 40702, -- Swarmite Skyhunter - Swarmite Skyhunter
        [448188] = 40662, -- Machine Defense Unit 1-11 - It's not much
        [448850] = 40539, -- Kah, Legend of the Deep - The Derby Dash
        [449415] = 40307, -- Slatestone Ramolith - Allied Races: Earthen
        [452779] = 40438, -- Ivory Goliathus - Glory of the Delver
        [303767] = 40956, -- Honeyback Hivemother - I'm On Island Time
        [448934] = 41201, -- Shadow of Doubt - You Xal Not Pass
        [468068] = 41286, -- Junkmaestro's Magnetomech - Glory of the Liberation of Undermine Raider
        [471538] = 41056, -- Timely Buzzbee - Master of the Turbulent Timeways II
        [472752] = 41133, -- The Breaker's Song - Isle Remember You
        [473472] = 40953, -- Jani's Trashpile - A Farewell to Arms
        [1218314] = 41966, -- Ny'alothan Shadow Worm - Mastering the Visions
        [1241263] = 42212, -- OC91 Chariot - Titan Console Overcharged
        [1223191] = 41980, -- Terror of the Night - Vigilante
        [1233511] = 41597, -- Umbral K'arroc - Glory of the Omega Raider
        [1245517] = 42172, -- Scarlet Void Flyer - WW Keystone Legend S3
        [1246781] = 41973, -- Azure Void Flyer - WW Keystone Master S3
        [1250578] = 61017, -- Phase-Lost Slateback - Phase-Lost-and-Found
        [1262886] = 61451, -- Geargrinder MK. 11 - Worldsoul-Searching

        -- Midnight
        [1243003] = 42300, -- Light-Forged Mechsuit - Two Minutes to Midnight
        [1257058] = 61256, -- Calamitous Carrion - Midnight Keystone Master: Season One
        [1257081] = 61258, -- Convalescent Carrion - Midnight Keystone Legend: Season One
        [1261338] = 42703, -- Preyseeker's Nightmare - Prey: Nightmare Mode III
        [1266980] = 61380, -- Tenebrous Harrower - Glory of the Midnight Raider
        [1268949] = 61799, -- Arcanovoid Construct - Let Me Solo Him: Nullaeus
        [1276650] = {62103,62096}, -- Anu'shalla, Shadow's Guidance -  Insurmountable Collection

        ------------------------------
        -- Alliance ------------------
        ------------------------------

        [90621] = true, -- Golden King - Guild Level 25
        [130985] = 6828, -- Pandaren Kite - Pandaren Ambassador, Alliance
        [295386] = 13517, -- Ironclad Frostclaw - Two Sides to Every Tale

        [61996] = 2536, -- Blue Dragonhawk - Mountain o' Mounts, Alliance
        [142478] = 8304, -- Armored Blue Dragonhawk - Mount Parade, Alliance
        [179245] = 9909, -- Chauffeur - Heirloom Hoarder, Alliance
        [308250] = 13928, -- Stormpike Battle Ram - Alterac Valley of Olde

        ------------------------------
        -- Horde ---------------------
        ------------------------------

        [93644] = true, -- Kor'kron Annihilator - Guild Level 25
        [118737] = 6827, -- Pandaren Kite - Pandaren Ambassador, Horde
        [295387] = 13517, -- Bloodflank Charger - Two Sides to Every Tale

        [61997] = 2537, -- Red Dragonhawk - Mountain o' Mounts, Horde
        [142266] = 8302, -- Armored Red Dragonhawk - Mount Parade, Horde
        [179244] = 9909, -- Chauffeur - Heirloom Hoarder, Horde
        [306421] = 13930, -- Frostwolf Snarler - Alterac Valley of Olde
    },

    ["Covenants"] = {
        -- adventures
        [312763] = true, -- Darkwarren Hardshell
        [312776] = true, -- Chittering Animite
        [341766] = true, -- Warstitched Darkhound
        [341776] = true, -- Highwind Darkmane

        [215545] = true, -- Mastercraft Gravewing - Korthia - venthyr drop: Gravewing Crystal
        [312753] = true, -- Hopecrusher Gargon - Venthyr drop: Hopecrusher
        [312754] = true, -- Battle Gargon Vrednic - venthyr campaign quest
        [312759] = true, -- Dreamlight Runestag - night fae campaign quest
        [312761] = true, -- Enchanted Dreamlight Runestag - night fae campaign quest
        [312777] = true, -- Silvertip Dredwing - generic covenant feature
        [332243] = true, -- Shadeleaf Runestag - night fae renown vendor
        [332244] = true, -- Wakener's Runestag - night fae covenant feature
        [332245] = true, -- Winterborn Runestag - night fae feature vendor
        [332246] = true, -- Enchanted Shadeleaf Runestag - night fae renown vendor
        [332247] = true, -- Enchanted Wakener's Runestag - night fae feature
        [332248] = true, -- Enchanted Winterborn Runestag - night fae feature vendor
        [332455] = true, -- War-Bred Tauralus - necrolord campaign quest
        [332456] = true, -- Plaguerot Tauralus - necrolord renown vendor
        [332457] = true, -- Bonehoof Tauralus - necrolord drop: Tahonta
        [332460] = true, -- Chosen Tauralus - necrolord achievement: The Gang's All Here
        [332462] = true, -- Armored War-Bred Tauralus - necrolord covenant quest
        [332464] = true, -- Armored Plaguerot Tauralus - necrolord renown vendor
        [332466] = true, -- Armored Bonehoof Tauralus - necrolord drop: Sabriel
        [332467] = true, -- Armored Chosen Tauralus - necrolord feature achievement: Things To Do When You're Dead
        [332882] = true, -- Horrid Dredwing - Revendreth - venthyr drop: Harika the Horrid
        [332923] = true, -- Inquisition Gargon - The Avowed (venthyr)
        [332927] = true, -- Sinfall Gargon - venthyr renown vendor
        [332932] = true, -- Crypt Gargon - venthyr campaign quest
        [332949] = true, -- Desire's Battle Gargon - venthyr feature
        [333021] = true, -- Gravestone Battle Armor - venthyr renown vendor
        [333023] = true, -- Battle Gargon Silessa - venthyr feature
        [334365] = true, -- Pale Acidmaw - generic covenant feature
        [334366] = true, -- Wild Glimmerfur Prowler - Ardenweald - Valfir the Unrelenting for night fae
        [334382] = true, -- Phalynx of Loyalty - kyrian covenant feature
        [334386] = true, -- Phalynx of Humility - kyrian renown vendor
        [334391] = true, -- Phalynx of Courage - kyrian campaign quest
        [334398] = true, -- Phalynx of Purity - kyrian renown vendor
        [334403] = true, -- Eternal Phalynx of Purity - kyrian renown vendor
        [334406] = true, -- Eternal Phalynx of Courage - kyrian campaign quest
        [334408] = true, -- Eternal Phalynx of Loyalty - kyrian feature vendor
        [334409] = true, -- Eternal Phalynx of Humility - kyrian feature vendor
        [336039] = true, -- Gruesome Flayedwing - generic covenant feature
        [336041] = true, -- Bonesewn Fleshroc - necrolord feature
        [336045] = true, -- Predatory Plagueroc - Maldraxxus - Gieger for necrolord
        [336064] = true, -- Dauntless Duskrunner - generic covenant feature
        [340503] = true, -- Umbral Scythehorn - night fae feature vendor
        [342667] = true, -- Vibrant Flutterwing - night fae feature vendor
        [343550] = true, -- Battle-Hardened Aquilon - kyrian korthia vendor
        [347250] = true, -- Lord of the Corpseflies - Korthia - necrolord drop: Fleshwing
        [353856] = true, -- Ardenweald Wilderling - night fae renown 45
        [353857] = true, -- Autumnal Wilderling - night fae renown vendor
        [353858] = true, -- Winter Wilderling - night fae korthia vendor
        [353859] = true, -- Summer Wilderling - Korthia - Escaped Wilderling for night fae
        [353866] = true, -- Obsidian Gravewing - venthyr renown vendor
        [353872] = true, -- Sinfall Gravewing - venthyr renown 45
        [353873] = true, -- Pale Gravewing - venthyr korthia vendor
        [353875] = true, -- Elysian Aquilon - kyrian renown 45
        [353877] = true, -- Foresworn Aquilon - Korthia - Wild Worldcracker for Kyrian
        [353880] = true, -- Ascendant's Aquilon - kyrian renown vendor
        [353883] = true, -- Maldraxxian Corpsefly - necrolord renown 45
        [353884] = true, -- Regal Corpsefly - necrolord renown vendor
        [353885] = true, -- Battlefield Swarmer - necrolord korthia vendor
    },

    ["Island Expedition"] = {
        [254811] = true, -- Squawks
        [278979] = true, -- Surf Jelly
        [279466] = true, -- Twilight Avenger
        [279469] = true, -- Qinsho's Eternal Hound
        [279467] = true, -- Craghorn Chasm-Leaper
        [288711] = true, -- Saltwater Seahorse
        [288712] = true, -- Stonehide Elderhorn
        [288720] = true, -- Bloodgorged Hunter
        [288721] = true, -- Island Thunderscale
        [288722] = true, -- Risen Mare
        [266925] = true, -- Siltwing Albatross
    },

    ["Garrison"] = {
        ------------------------------
        -- Alliance & Horde ----------
        ------------------------------

        -- Stables
        [171617] = true, -- Trained Icehoof
        [171623] = true, -- Trained Meadowstomper
        [171637] = true, -- Trained Rocktusk
        [171638] = true, -- Trained Riverwallow
        [171831] = true, -- Trained Silverpelt
        [171841] = true, -- Trained Snarler
        [171629] = true, -- Armored Frostboar - Advanced Husbandry
        [171838] = true, -- Armored Frostwolf - The Stable Master

        -- Fishing Shack
        [127271] = true, -- Crimson Water Strider

        -- Garrison Invasion
        [171624] = true, -- Shadowhide Pearltusk
        [171635] = true, -- Giant Coldsnout
        [171836] = true, -- Garn Steelmaw
        [171843] = true, -- Smoky Direwolf

        -- Garrison Mission
        [189364] = true, -- Coalfist Gronnling - Breaker Two
        [171826] = true, -- Mudback Riverbeast - It's a Boat, It's a Plane, It's... Just a Riverbeast.

        ------------------------------
        -- Alliance ------------------
        ------------------------------

        -- Trading Post
        [171626] = true, -- Armored Irontusk - Alliance

        ------------------------------
        -- Horde ---------------------
        ------------------------------

        -- Trading Post
        [171839] = true, -- Ironside Warwolf - Horde
    },

    ["PVP"] = {
        ------------------------------
        -- Alliance & Horde ----------
        ------------------------------

        -- Halaa
        [39316] = true, -- Dark Riding Talbuk
        [34790] = true, -- Dark War Talbuk

        -- Tol Barad
        [88741] = true, -- Drake of the West Wind

        -- Timeless Isle
        [148428] = true, -- Ashhide Mushan Beast

        -- Arena
        [434470] = true, -- Vicious Dreamtalon - Dragonflight: Season 4
        [434477] = true, -- Vicious Dreamtalon - Dragonflight: Season 4
        [447405] = true, -- Vicious Skyflayer - War Within: Season 1
        [449325] = true, -- Vicious Skyflayer - War Within: Season 1
        [472157] = true, -- Astral Gladiator's Fel Bat - Gladiator: The War Within Season 3
        [1262840] = true, -- Galactic Gladiator's Goredrake - Gladiator: Midnight Season One

        -- Prestige Reward
        [222202] = true, -- Prestigious Bronze Courser
        [222236] = true, -- Prestigious Royal Courser
        [222237] = true, -- Prestigious Forest Courser
        [222238] = true, -- Prestigious Ivory Courser
        [222240] = true, -- Prestigious Azure Courser
        [222241] = true, -- Prestigious Midnight Courser
        [281044] = true, -- Prestigious Bloodforged Courser

        ------------------------------
        -- Alliance ------------------
        ------------------------------

        -- War Mounts
        [22717] = true, -- Black War Steed
        [22719] = true, -- Black Battlestrider
        [22720] = true, -- Black War Ram
        [22723] = true, -- Black War Tiger
        [48027] = true, -- Black War Elekk
        [183889] = true, -- Vicious War Mechanostrider
        [223578] = true, -- Vicious War Elekk
        [223341] = true, -- Vicious Gilnean Warhorse
        [229487] = true, -- Vicious War Bear
        [229512] = true, -- Vicious War Lion
        [232523] = true, -- Vicious War Turtle
        [242896] = true, -- Vicious War Fox
        [261433] = true, -- Vicious War Basilisk
        [272481] = true, -- Vicious War Riverbeast
        [281887] = true, -- Vicious Black Warsaber
        [281888] = true, -- Vicious White Warsaber
        [327407] = true, -- Vicious War Spider
        [348770] = true, -- Vicious War Gorm
        [347256] = true, -- Vicious War Croaker
        [349824] = true, -- Vicious War Warstalker
        [394737] = true, -- Vicious Sabertooth
        [409034] = true, -- Vicious War Snail
        [424534] = true, -- Vicious Moon Beast
        [466145] = true, -- Vicious Electro Eel
        [1234820] = true, -- Vicious Void Creeper

        -- Achievement
        [60118] = true, -- Black War Bear - For The Alliance!
        [100332] = true, -- Vicious War Steed - Veteran of the Alliance
        [146615] = true, -- Vicious Warsaber - Grievous Combatant
        [171834] = true, -- Vicious War Ram - Primal Combatant
        [193695] = true, -- Prestigious War Steed - Free For All, More For Me
        [1261648] = true, -- Vicious Snaplizard - Galactic Combatant

        -- Stormpike Guard
        [23510] = true, -- Stormpike Battle Charger

        -- Wintergrasp
        [59785] = true, -- Black War Mammoth - Alliance

        -- Tol Barad
        [92231] = true, -- Spectral Steed

        -- Wrynn's Vanguard
        [171833] = true, -- Pale Thorngrazer

        ------------------------------
        -- Horde ---------------------
        ------------------------------

        -- War Mounts
        [22718] = true, -- Black War Kodo
        [22724] = true, -- Black War Wolf
        [22722] = true, -- Red Skeletal Warhorse
        [35028] = true, -- Swift Warstrider
        [22721] = true, -- Black War Raptor
        [185052] = true, -- Vicious War Kodo
        [223354] = true, -- Vicious War Trike
        [223363] = true, -- Vicious Warstrider
        [229486] = true, -- Vicious War Bear
        [232525] = true, -- Vicious War Turtle
        [230988] = true, -- Vicious War Scorpion
        [242897] = true, -- Vicious War Fox
        [261434] = true, -- Vicious War Basilisk
        [270560] = true, -- Vicious War Clefthoof
        [281889] = true, -- Vicious White Bonesteed
        [281890] = true, -- Vicious Black Bonesteed
        [327408] = true, -- Vicious War Spider
        [348769] = true, -- Vicious War Gorm
        [347255] = true, -- Vicious War Croaker
        [349823] = true, -- Vicious War Warstalker
        [394738] = true, -- Vicious Sabertooth
        [409032] = true, -- Vicious War Snail
        [424535] = true, -- Vicious Moon Beast
        [466146] = true, -- Vicious Electro Eel
        [1234821] = true, -- Vicious Void Creeper

        -- Achievement
        [60119] = true, -- Black War Bear - For The Horde!
        [100333] = true, -- Vicious War Wolf - Veteran of the Horde
        [146622] = true, -- Vicious Skeletal Warhorse - Grievous Combatant
        [171835] = true, -- Vicious War Raptor - Primal Combatant
        [204166] = true, -- Prestigious War Wolf - Free For All, More For Me
        [1261629] = true, -- Vicious Snaplizard - Galactic Combatant

        -- Frostwolf Clan
        [23509] = true, -- Frostwolf Howler

        -- Wintergrasp
        [59788] = true, -- Black War Mammoth - Horde

        -- Tol Barad
        [92232] = true, -- Spectral Wolf

        -- Vol'jin's Spear
        [171832] = true, -- Breezestrider Stallion
    },

    ["Class"] = {
        ------------------------------
        -- Alliance & Horde ----------
        ------------------------------

        --Warlock
        [5784] = true, -- Felsteed
        [23161] = true, -- Dreadsteed
        [232412] = true, -- Netherlord's Chaotic Wrathsteed
        [238452] = true, -- Netherlord's Brimstone Wrathsteed
        [238454] = true, -- Netherlord's Accursed Wrathsteed

        -- Death Knight
        [48778] = true, -- Acherus Deathcharger
        [54729] = true, -- Winged Steed of the Ebon Blade
        [229387] = true, -- Deathlord's Vilebrood Vanquisher

        -- Demon Hunter
        [200175] = true, -- Felsaber
        [229417] = true, -- Slayer's Felbroken Shrieker

        -- Mage
        [229376] = true, -- Archmage's Prismatic Disc

        -- Paladin
        [66906] = true, -- Argent Charger
        [231435] = true, -- Highlord's Golden Charger
        [231587] = true, -- Highlord's Vengeful Charger
        [231588] = true, -- Highlord's Vigilant Charger
        [231589] = true, -- Highlord's Valorous Charger
        [270564] = true, -- Dawnforge Ram
        [270562] = true, -- Darkforge Ram
        [290608] = true, -- Crusader's Direhorn
        [363613] = true, -- Lightforged Ruinstrider
        [453785] = true, -- Earthen Ordinant's Ramolith

        -- Priest
        [229377] = true, -- High Priest's Lightsworn Seeker

        -- Monk
        [229385] = true, -- Ban-Lu, Grandmaster's Companion

        --Hunter
        [229438] = true, -- Huntmaster's Fierce Wolfhawk
        [229439] = true, -- Huntmaster's Dire Wolfhawk
        [229386] = true, -- Huntmaster's Loyal Wolfhawk

        -- Warrior
        [229388] = true, -- Battlelord's Bloodthirsty War Wyrm

        -- Shaman
        [231442] = true, -- Farseer's Raging Tempest

        -- Rogue
        [231434] = true, -- Shadowblade's Murderous Omen
        [231523] = true, -- Shadowblade's Lethal Omen
        [231524] = true, -- Shadowblade's Baneful Omen
        [231525] = true, -- Shadowblade's Crimson Omen

        ------------------------------
        -- Alliance ------------------
        ------------------------------

        -- Paladin
        [23214] = true, -- Summon Charger
        [13819] = true, -- Summon Warhorse
        [73629] = true, -- Summon Exarch's Elekk
        [73630] = true, -- Summon Great Exarch's Elekk

        ------------------------------
        -- Horde ---------------------
        ------------------------------

        -- Paladin
        [34767] = true, -- Summon Thalassian Charger
        [34769] = true, -- Summon Thalassian Warhorse
        [69820] = true, -- Summon Sunwalker Kodo
        [69826] = true, -- Summon Great Sunwalker Kodo
    },

    ["World Event"] = {
        -- https://wago.tools/db2/Mount?filter%5BSourceTypeEnum%5D=6&page=1
        --sourceType = { 7 }, -- cant use it, because some mounts are missassigned

        ["Timewalking"] = {
            [127165] = true, -- Yu'lei, Daughter of Jade
            [142910] = true, -- Ironbound Wraithcharger
            [194464] = true, -- Eclipse Dragonhawk
            [201098] = true, -- Infinite Timereaver
            [294568] = true, -- Beastlord's Irontusk
            [294569] = true, -- Beastlord's Warwolf
            [332482] = true, -- Bonecleaver's Skullboar
            [359013] = true, -- Val'sharah Hippogryph
            [359318] = true, -- Soaring Spelltome - A Tour of Towers
            [408654] = true, -- Sandy Shalewing
            [452645] = true, -- Amani Hunting Bear
            [468353] = true, -- Enchanted Spellweave Carpet
            [1214920] = true, -- Nightfall Skyreaver
            [1214940] = true, -- Ur'zul Fleshreaper
            [1214946] = true, -- Broodling of Sinestra
            [1214974] = true, -- Copper-Maned Quilen
            [1226144] = true, -- Chrono Corsair
            [1237631] = true, -- Moonlit Nightsaber
            [1237703] = true, -- Ivory Savagemane
            [1261668] = true, -- Bronze Wilderling
            [1261671] = true, -- Bronze Aquilon
            [1261677] = true, -- Bronze Corpsefly
            [1261681] = true, -- Bronze Gravewing
            [1263369] = true, -- Skypaw Glimmerfur
            [1263387] = true, -- Crimson Lupine
            [1264988] = true, -- Snowpaw Glimmerfur Prowler
        },

        ["Darkmoon Faire"] = {
            [103081] = true, -- Darkmoon Dancing Bear
            [102346] = true, -- Swift Forest Strider
            [228919] = true, -- Darkwater Skate
            [247448] = true, -- Darkmoon Dirigible
        },

        ["Plunderstorm"] = {
            [254812] = true, -- Royal Seafeather
            [300154] = true, -- Silver Tidestallion
            [437162] = true, -- Polly Roger
            [446902] = true, -- Polly Roger (classic)
            [457656] = true, -- Plunderlord's Midnight Crocolisk
            [471696] = true, -- Hooktalon
        },

        ["Call of the Scarab"] = {
            [239766] = true, -- Blue Qiraji War Tank
            [239767] = true, -- Red Qiraji War Tank
        },

        ["Lunar Festival"] = {
            [472253] = true, -- Lunar Launcher
        },

        ["Love is in the Air"] = {
            [71342] = true, -- Big Love Rocket
            [102350] = true, -- Swift Lovebird
            [427777] = true, -- Heartseeker Mana Ray
            [472479] = true, -- Love Witch's Sweeper
            [1218013] = true, -- Spring Butterfly
        },

        ["Noblegarden"] = {
            [102349] = true, -- Swift Springstrider
            [432455] = true, -- Noble Flying Carpet
        },

        ["Secrets of Azeroth"] = {
            [418078] = true, -- Pattie - Whodunnit?
            [424082] = true, -- Mimiron's Jumpjets
        },

        ["Brewfest"] = {
            [43900] = true, -- Swift Brewfest Ram
            [49378] = true, -- Brewfest Riding Kodo
            [49379] = true, -- Great Brewfest Kodo
            [1247662] = true, -- Brewfest Barrel Bomber
        },

        ["Anniversary"] = {
            [62048] = true, -- Illidari Doomhawk - 17th Anniversary
            [294197] = true, -- Obsidian Worldbreaker - 15th Anniversary
            [428013] = true, -- Incognitro
            [452643] = true, -- Frayfeather Hippogryph
            [463133] = true, -- Coldflame Tempest
        },

        ["Hallow's End"] = {
            [48025] = true, -- Headless Horseman's Mount
            [1245198] = true, -- The Headless Horseman's Ghoulish Charger
        },

        ["Feast of Winter Veil"] = {
            [191314] = true, -- Minion of Grumpus
        },
    },

    ["Trading Post"] = {
        filterFunc = function(mountId)
            return nil ~= (BATTLE_PET_SOURCE_12 and string.find(select(3, C_MountJournal.GetMountInfoExtraByID(mountId)), BATTLE_PET_SOURCE_12))
        end,
    },

    ["Shop"] = {
        sourceType = { 10 },

        [431360] = true, -- Twilight Sky Prowler
        [457485] = true, -- Grizzly Hills Packmaster
    },

    ["Promotion"] = {
        sourceType = { 8, 9 },
        --  8 = promotion
        --  9 = TCG
    },
}

ADDON.DB.FeatsOfStrength = {
    -- from https://wowhead.com/mount-feats-of-strength (69)
    -- and https://www.wowhead.com/achievements/character-achievements/feats-of-strength/player-vs-player?filter=3;0;Mount#0+4+7 (14)
    -- mountId => AchievementId
    [55] = 3356, -- Winterspring Frostsaber
    [69] = 729, -- Deathcharger's Reins
    [110] = 881, -- Swift Razzashi Raptor
    [111] = 880, -- Swift Zulian Tiger
    [122] = 416, -- Scarab Lord
    [168] = 882, -- Fiery Warhorse's Reins
    [169] = 886, -- Swift Nether Drake
    [183] = 885, -- Ashes of Al'ar
    [185] = 883, -- Reins of the Raven Lord
    [199] = 430, -- Amani War Bear - no longer available
    [207] = 887, -- Merciless Nether Drake
    [213] = 884, -- Swift White Hawkstrider
    [219] = 980, -- The Horseman's Reins
    [223] = 888, -- Vengeful Nether Drake
    [224] = 1436, -- Friends In High Places
    [241] = 2316, -- Brutal Nether Drake
    [263] = 2138, -- Black Proto-Drake - no longer available - Glory of the Raider (25 player)
    [286] = 2081, -- Grand Black War Mammoth
    [287] = 2081, -- Grand Black War Mammoth
    [304] = 4626, -- And I'll Form the Head!
    [311] = 3357, -- Venomhide Ravasaur
    [313] = 3096, -- Deadly Gladiator's Frost Wyrm
    [317] = 3756, -- Furious Gladiator's Frost Wyrm
    [340] = 3757, -- Relentless Gladiator's Frost Wyrm
    [352] = 4627, -- X-45 Heartbreaker
    [358] = 4600, -- Wrathful Gladiator's Frost Wyrm
    [363] = 4625, -- Invincible's Reins
    [382] = 4832, -- Friends In Even Higher Places
    [400] = 5767, -- Scourer of the Eternal Sands
    [424] = 6003, -- Vicious Gladiator's Twilight Drake
    [428] = 6322, -- Ruthless Gladiator's Twilight Drake
    [454] = 9925, -- Friends In Places Yet Even Higher Than That
    [455] = 8213, -- Friends In Places Higher Yet
    [467] = 6741, -- Cataclysmic Gladiator's Twilight Drake
    [537] = 8092, -- Bone-White Primal Raptor
    [541] = 8216, -- Malevolent Gladiator's Cloud Serpent
    [558] = { 8398, 8399 }, -- Kor'kron War Wolf - Ahead of the Curve: Garrosh Hellscream (10/25 player)
    [562] = 8678, -- Tyrannical Gladiator's Cloud Serpent
    [563] = 8705, -- Grievous Gladiator's Cloud Serpent
    [564] = 8707, -- Prideful Gladiator's Cloud Serpent
    [568] = 8794, -- Friends In Places Even Higher Than That
    [651] = 9496, -- Warlord's Deathwheel - Warlord's Deathwheel
    [654] = 8898, -- Challenger's War Yeti - Challenge Warlord: Silver
    [759] = 9229, -- Primal Gladiator's Felblood Gronnling
    [760] = 10137, -- Wild Gladiator's Felblood Gronnling
    [761] = 10146, -- Warmongering Gladiator's Felblood Gronnling
    [848] = 10999, -- Vindictive Gladiator's Storm Dragon
    [849] = 11000, -- Fearless Gladiator's Storm Dragon
    [850] = 11001, -- Cruel Gladiator's Storm Dragon
    [851] = 11002, -- Ferocious Gladiator's Storm Dragon
    [852] = 13450, -- Fierce Gladiator's Storm Dragon
    [853] = 12139, -- Dominating Gladiator's Storm Dragon
    [936] = 424, -- Why? Because It's Red
    [948] = 12140, -- Demonic Gladiator's Storm Dragon
    [1026] = 13636, -- Vicious War Basilisk -- Notorious Combatant
    [1027] = 13637, -- Vicious War Basilisk -- Notorious Combatant
    [1030] = {12961, 13093}, -- Dread Gladiator's Proto-Drake -- Gladiator: Battle for Azeroth Season 1
    [1031] = {13202, 13212}, -- Sinister Gladiator's Proto-Drake -- Gladiator: Battle for Azeroth Season 2
    [1032] = {13632, 13647}, -- Notorious Gladiator's Proto-Drake -- Gladiator: Battle for Azeroth Season 3
    [1035] = {13958, 13967}, -- Corrupted Gladiator's Proto-Drake -- Gladiator: Battle for Azeroth Season 4
    [1039] = 14183, -- Mighty Caravan Brutosaur
    [1045] = 13136, -- Vicious War Clefthoof -- Dread Combatant
    [1050] = 13137, -- Vicious War Riverbeast -- Dread Combatant
    [1194] = 13943, -- Vicious White Warsaber -- Corrupted Combatant
    [1195] = 13228, -- Vicious Black Warsaber -- Sinister Combatant
    [1196] = 13227, -- Vicious Black Bonestead -- Sinister Combatant
    [1197] = 13944, -- Vicious White Bonesteed -- Corrupted Combatant
    [1326] = 14145, -- Awakened Mindborer - Battle for Azeroth Keystone Master: Season Four
    [1351] = 14612, -- Vicious War Spider -- Sinful Combatant
    [1352] = 14611, -- Vicious War Spider -- Sinful Combatant
    [1363] = {14816, 14689}, -- Sinful Gladiator's Soul Eater -- Gladiator: Shadowlands Season 1
    [1405] = 15690, -- Restoration Deathwalker - Shadowlands Keystone Master: Season Four
    [1419] = 14532, -- Sintouched Deathwalker - Shadowlands Keystone Master: Season One
    [1451] = 15346, -- Vicious War Croaker -- Cosmic Combatant
    [1452] = 15347, -- Vicious War Croaker -- Cosmic Combatant
    [1459] = 14966, -- Vicious War Gorm -- Unchained Combatant
    [1460] = 14967, -- Vicious War Gorm -- Unchained Combatant
    [1465] = 15599, -- Vicious Warstalker -- Eternal Combatant
    [1466] = 15598, -- Vicious Warstalker -- Eternal Combatant
    [1480] = {14999, 14972}, -- Unchained Gladiator's Soul Eater -- Gladiator: Shadowlands Season 2
    [1520] = 15078, -- Soultwisted Deathwalker - Shadowlands Keystone Master: Season Two
    [1544] = 15499, -- Wastewarped Deathwalker - Shadowlands Keystone Master: Season Three
    [1552] = 15470, -- Carcinized Zerethsteed - Ahead of the Curve: The Jailer
    [1572] = {15384, 15352}, -- Cosmic Gladiator's Soul Eater -- Gladiator: Shadowlands Season 3
    [1599] = {15612, 15605}, -- Eternal Gladiator's Soul Eater -- Gladiator: Shadowlands Season 4
    [1660] = {16730, 15957}, -- Crimson Gladiator's Drake -- Gladiator: Dragonflight Season 1
    [1681] = 16649, -- Hailstorm Armoredon - Dragonflight Keystone Master: Season One
    [1688] = 15943, -- Vicious Sabertooth -- Crimson Combatant
    [1689] = 15942, -- Vicious Sabertooth -- Crimson Combatant
    [1725] = 17844, -- Inferno Armoredon - Dragonflight Keystone Master: Season Two
    [1737] = 19079, -- Sandy Shalewing - Master of the Turbulent Timeways
    [1739] = {17740, 17764, 17778}, -- Obsidian Gladiator's Slitherdrake - Gladiator: Dragonflight Season 2
    [1740] = 17727, -- Vicious War Snail -- Obsidian Combatant
    [1741] = 17728, -- Vicious War Snail -- Obsidian Combatant
    [1819] = 19140, -- Vicious Moonbeast -- Verdant Combatant
    [1820] = 19141, -- Vicious Moonbeast -- Verdant Combatant
    [1822] = {19490, 19503}, -- Draconic Gladiator's Drake - Gladiator: Dragonflight Season 4
    [1831] = {19091, 19295}, -- Verdant Gladiator's Slitherdrake - Gladiator: Dragonflight Season 3
    [2056] = 19501, -- Vicious Dreamtalon -- Draconic Combatant
    [2057] = 19502, -- Vicious Dreamtalon -- Draconic Combatant
    [2142] = 20593, -- August Phoenix
    [2143] = 19876, -- Astral Emperor's Serpent
    [2150] = 40397, -- Vicious Skyflayer - Forged Combatant -- War Within: Season 1
    [2211] = 40396, -- Vicious Skyflayer - Forged Combatant -- War Within: Season 1
    [2218] = {40398, 40393}, -- Forged Gladiator's Fel Bat - Gladiator: War Within Season 1
    [2298] = {41032, 41362}, -- Prized Gladiator's Fel Bat - Gladiator: War Within Season 2
    [2299] = 41129, -- Vicious Electro Eel - Prized Combatant
    [2300] = 41128, -- Vicious Electro Eel - Prized Combatant
    [2326] = 41049, -- Astral Gladiator's Fel Bat - Gladiator: The War Within Season 3
    [2480] = 41533, -- Crimson Shreddertank - WW Keystone Master S2
    [2508] = 40951, -- Enterprising Shreddertank - WW Keystone Legend S2
    [2570] = 42043, -- Vicious Void Creeper - Astral Combatant
    [2571] = 42042, -- Vicious Void Creeper - Astral Combatant
    [2631] = 42172, -- Scarlet Void Flyer - WW Keystone Legend S3
    [2633] = 41973, -- Azure Void Flyer - WW Keystone Master S3
    [2733] = 61256, -- Calamitous Carrion - Midnight Keystone Master: Season One
    [2734] = 61258, -- Convalescent Carrion - Midnight Keystone Legend: Season One
    [2793] = 61403, -- Vicious Snaplizard - Galactic Combatant
    [2794] = 61405, -- Vicious Snaplizard - Galactic Combatant
    [2801] = 61188, -- Galactic Gladiator's Goredrake - Gladiator: Midnight Season One
    [2842] = 61799, -- Arcanovoid Construct - Let Me Solo Him: Nullaeus
}

ADDON.DB.Expansion = {

    [0] = { -- Classic
        ["minID"] = 0,
        ["maxID"] = 122,
    },

    [1] = { -- The Burning Crusade
        ["minID"] = 123,
        ["maxID"] = 226,
        [241] = true, -- Brutal Nether Drake
        [243] = true, -- Big Blizzard Bear
    },

    [2] = { -- Wrath of the Lich King
        ["minID"] = 227,
        ["maxID"] = 382,
        [211] = true, -- X-51 Nether-Rocket
        [212] = true, -- X-51 Nether-Rocket X-TREME
        [221] = true, -- Acherus Deathcharger
        [1679] = true, -- Frostbrood Proto-Wyrm (WotLK Classic)
    },

    [3] = { -- Cataclysm
        ["minID"] = 383,
        ["maxID"] = 447,
        [358] = true, -- Wrathful Gladiator's Frost Wyrm
        [373] = true, -- Abyssal Seahorse
        [1812] = true, -- Runebound Firelord (Cataclysm Classic)
    },

    [4] = { -- Mists of Pandaria
        ["minID"] = 448,
        ["maxID"] = 571,
        [467] = true, -- Cataclysmic Gladiator's Twilight Drake
        [2476] = true, -- Sha-Warped Cloud Serpent (MoP Classic)
        [2477] = true, -- Sha-Warped Riding Tiger (MoP Classic)
        [2582] = true, -- Shaohao's Sage Serpent (MoP Classic)
    },

    [5] = { -- Warlords of Draenor
        ["minID"] = 572,
        ["maxID"] = 772,
        [454] = true, -- Cindermane Charger
        [552] = true, -- Ironbound Wraithcharger
        [778] = true, -- Eclipse Dragonhawk
        [781] = true, -- Infinite Timereaver
    },

    [6] = { -- Legion
        ["minID"] = 773,
        ["maxID"] = 991,
        [476] = true, -- Yu'lei, Daughter of Jade
        [633] = true, -- Hellfire Infernal
        [656] = true, -- Llothien Prowler
        [663] = true, -- Bloodfang Widow
        [763] = true, -- Illidari Felstalker - Legion Collector's Edition
        [1006] = true, -- Lightforged Felcrusher
        [1007] = true, -- Highmountain Thunderhoof
        [1008] = true, -- Nightborne Manasaber
        [1009] = true, -- Starcursed Voidstrider
        [1011] = true, -- Shu-zen, the Divine Sentinel
    },

    [7] = { -- Battle for Azeroth
        ["minID"] = 993,
        ["maxID"] = 1329,
        [926] = true, -- Alabaster Hyena
        [928] = true, -- Dune Scavenger
        [933] = true, -- Obsidian Krolusk
        [956] = true, -- Leaping Veinseeker
        [958] = true, -- Spectral Pterrorwing
        [963] = true, -- Bloodgorged Crawg
        [1346] = true, -- Steamscale Incinerator
    },

    [8] = { -- Shadowlands
        ["minID"] = 1330,
        ["maxID"] = 1576,
        [803] = true, -- Mastercraft Gravewing
        [1289] = true, -- Ensorcelled Everwyrm
        [1298] = true, -- Hopecrusher Gargon
        [1299] = true, -- Battle Gargon Vrednic
        [1302] = true, -- Dreamlight Runestag
        [1303] = true, -- Enchanted Dreamlight Runestag
        [1304] = true, -- Mawsworn Soulhunter
        [1305] = true, -- Darkwarren Hardshell
        [1306] = true, -- Swift Gloomhoof
        [1307] = true, -- Sundancer
        [1309] = true, -- Chittering Animite
        [1310] = true, -- Horrid Dredwing
        [1580] = true, -- Heartbond Lupine
        [1581] = true, -- Nether-Gorged Greatwyrm
        [1584] = true, -- Colossal Plaguespew Mawrat
        [1585] = true, -- Colossal Wraithbound Mawrat
        [1587] = true, -- Zereth Overseer
        [1597] = true, -- Grimhowl
        [1599] = true, -- Eternal Gladiator's Soul Eater
        [1600] = true, -- Elusive Emerald Hawkstrider
        [1602] = true, -- Tuskarr Shoreglider
        [1679] = true, -- Frostbrood Proto-Wyrm
    },

    [9] = { -- Dragonflight
        ["minID"] = 1577,
        ["maxID"] = 2115,
        [1469] = true, -- Magmashell
        [1478] = true, -- Skyskin Hornstrider
        [1545] = true, -- Divine Kiss of Ohn'ahra
        [1546] = true, -- Iskaara Trader's Ottuk
        [1553] = true, -- Liberated Slyvern
        [1556] = true, -- Tangled Dreamweaver
        [1563] = true, -- Highland Drake
        [2118] = true, -- Amber Pterrordax
        [2142] = true, -- August Phoenix
        [2143] = true, -- Astral Emperor's Serpent
        [2152] = true, -- Pearlescent Goblin Wave Shredder
        [2140] = true, -- Charming Courier
        [2189] = true, -- Underlight Corrupted Behemoth
    },

    [10] = { -- War Within
        ["minID"] = 2116,
        ["maxID"] = 2732,
        [1550] = true, -- Depthstalker
        [1792] = true, -- Algarian Stormrider
        [2795] = true, -- Bronze Wilderling
        [2796] = true, -- Bronze Aquilon
        [2797] = true, -- Bronze Corpsefly
        [2798] = true, -- Bronze Gravewing
        [2802] = true, -- Geargrinder Mk. 11
        [2803] = true, -- Skypaw Glimmerfur
        [2804] = true, -- Crimson Lupine
        [2807] = true, -- Brawlin' Bruno
        [2808] = true, -- Ballistic Bronco
        [2815] = true, -- Snowpaw Glimmerfur Prowler
        [2823] = true, -- Savage Crimson Battle Turtle
        [2825] = true, -- Cloudborn Razorwing
    },

    [11] = { -- Midnight
        ["minID"] = 2733,
        ["maxID"] = 9999999999,
        [16] = true, -- Lost Nether Drake
        [1946] = true, -- Jeweled Jade Scarab
        [2161] = true, -- Elder Glowmite
        [2220] = true, -- Retrained Skyrazor
        [2492] = true, -- Spring Butterfly
        [2595] = true, -- Swift Spectral Dragonhawk
        [2607] = true, -- Ashens of Belo'ren
        [2608] = true, -- Light-Forged Mechsuit
        [2614] = true, -- Fierce Grimlynx
        [2615] = true, -- Rootstalker Grimlynx
        [2693] = true, -- Amani Sunfeather
        [2694] = true, -- Amani Windcaller
        [2708] = true, -- Vibrant Petalwing
        [2710] = true, -- Cerulean Sporeglider
        [2713] = true, -- Ruddy Sporeglider
    }
}

ADDON.DB.Type = {
    -- https://warcraft.wiki.gg/wiki/API_C_MountJournal.GetMountInfoExtraByID
    -- https://wago.tools/db2/MountType
    ground = {
        typeIDs = { 225, 230, 231, 241, 269, 284, 408, 412 },
    },
    flying = {
        typeIDs = { 229, 238, 247, 248, 263, 398, 402, 407, 424, 426, 428, 429, 436, 437, 444, 445 },
    },
    underwater = {
        typeIDs = { 231, 232, 254, 407, 412, 436},
    },
    repair = {
        [280] = true, -- Traveler's Tundra Mammoth (Alliance)
        [284] = true, -- Traveler's Tundra Mammoth (Horde)
        [460] = true, -- Grand Expedition Yak
        [1039] = true, -- Mighty Caravan Brutosaur
        [2237] = true, -- Grizzly Hills Packmaster
    },
    passenger = {
        [240] = true, -- Mechano-Hog
        [275] = true, -- Mekgineer's Chopper
        [280] = true, -- Traveler's Tundra Mammoth (Alliance)
        [284] = true, -- Traveler's Tundra Mammoth (Horde)
        [286] = true, -- Grand Black War Mammoth
        [287] = true, -- Grand Black War Mammoth
        [288] = true, -- Grand Ice Mammoth
        [289] = true, -- Grand Ice Mammoth
        [382] = true, -- X-53 Touring Rocket
        [407] = true, -- Sandstone Drake
        [455] = true, -- Obsidian Nightwing
        [460] = true, -- Grand Expedition Yak
        [959] = true, -- Stormwind Skychaser - Blizzcon 2017
        [960] = true, -- Orgrimmar Interceptor - Blizzcon 2017
        [1025] = true, -- The Hivemind
        [1039] = true, -- Mighty Caravan Brutosaur
        [1287] = true, -- Explorer's Jungle Hopper
        [1288] = true, -- Explorer's Dunetrekker
        [1698] = true, -- Rocket Shredder 9001
    },
    rideAlong = {
        typeIDs = { 402, 445},
    },
}

-- used as filter
-- mountId as Index
ADDON.DB.Ignored = {
    ["types"] = {
        [242] = true, -- ghosts
        [426] = true, -- dragonriding racing duplicates
    },

    ["ids"] = {
        [7] = true, -- Gray Wolf
        [8] = true, -- White Stallion
        [13] = true, -- Red Wolf
        [15] = true, -- Winter Wolf
        [22] = true, -- Black Ram
        [28] = true, -- Skeletal Horse
        [32] = true, -- Tiger
        [35] = true, -- Ivory Raptor
        [70] = true, -- Riding Kodo
        [116] = true, -- Black Qiraji Battle Tank
        [121] = true, -- Black Qiraji Battle Tank
        [123] = true, -- Nether Drake
        [206] = true, -- Merciless Nether Drake
        [251] = true, -- Black Polar Bear
        [273] = true, -- Grand Caravan Mammoth
        [274] = true, -- Grand Caravan Mammoth
        [308] = true, -- Blue Skeletal Warhorse
        [333] = true, -- Magic Rooster
        [334] = true, -- Magic Rooster
        [335] = true, -- Magic Rooster
        [462] = true, -- White Riding Yak
        [484] = true, -- Black Riding Yak
        [485] = true, -- Brown Riding Yak
        [776] = true, -- Swift Spectral Rylak
        [1269] = true, -- Swift Spectral Fathom Ray
        [1578] = true, -- DNT Test Mount JZB
        [1690] = true, -- Whelpling
        [1796] = true, -- Whelpling
        [2115] = true, -- Soar
        [2301] = true, -- Unstable Rocket
        [2302] = true, -- Unstable Rocket
        [2716] = true, -- (PH) Legion Remix Mount
    },
}