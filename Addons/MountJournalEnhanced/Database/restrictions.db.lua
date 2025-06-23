local _, ADDON = ...

ADDON.DB.Restrictions = {
[17] = { ["class"]={"WARLOCK",}, }, -- Felsteed
[41] = { ["class"]={"PALADIN",}, }, -- Warhorse
[83] = { ["class"]={"WARLOCK",}, }, -- Dreadsteed
[84] = { ["class"]={"PALADIN",}, }, -- Charger
[149] = { ["class"]={"PALADIN",}, ["race"]={"BloodElf",}, }, -- Thalassian Charger
[150] = { ["class"]={"PALADIN",}, ["race"]={"BloodElf",}, }, -- Thalassian Warhorse
[204] = { ["skill"]={202,}, }, -- Turbo-Charged Flying Machine
[205] = { ["skill"]={202,}, }, -- Flying Machine
[221] = { ["class"]={"DEATHKNIGHT",}, }, -- Acherus Deathcharger
[236] = { ["class"]={"DEATHKNIGHT",}, }, -- Winged Steed of the Ebon Blade
[279] = { ["skill"]={197,}, }, -- Magnificent Flying Carpet
[285] = { ["skill"]={197,}, }, -- Flying Carpet
[338] = { ["class"]={"PALADIN",}, }, -- Argent Charger
[350] = { ["class"]={"PALADIN",}, ["race"]={"Tauren",}, }, -- Sunwalker Kodo
[351] = { ["class"]={"PALADIN",}, ["race"]={"Tauren",}, }, -- Great Sunwalker Kodo
[367] = { ["class"]={"PALADIN",}, ["race"]={"Draenei","LightforgedDraenei",}, }, -- Exarch's Elekk
[368] = { ["class"]={"PALADIN",}, ["race"]={"Draenei","LightforgedDraenei",}, }, -- Great Exarch's Elekk
[375] = { ["skill"]={197,}, }, -- Frosty Flying Carpet
[603] = { ["skill"]={197,}, }, -- Creeping Carpet
[650] = { ["skill"]={165,}, }, -- Dustmane Direwolf
[780] = { ["class"]={"DEMONHUNTER",}, }, -- Felsaber
[803] = { ["covenant"]={2,}, }, -- Mastercraft Gravewing
[860] = { ["class"]={"MAGE",}, }, -- Archmage's Prismatic Disc
[861] = { ["class"]={"PRIEST",}, }, -- High Priest's Lightsworn Seeker
[864] = { ["class"]={"MONK",}, }, -- Ban-Lu, Grandmaster's Companion
[865] = { ["class"]={"HUNTER",}, }, -- Huntmaster's Loyal Wolfhawk
[866] = { ["class"]={"DEATHKNIGHT",}, }, -- Deathlord's Vilebrood Vanquisher
[867] = { ["class"]={"WARRIOR",}, }, -- Battlelord's Bloodthirsty War Wyrm
[868] = { ["class"]={"DEMONHUNTER",}, }, -- Slayer's Felbroken Shrieker
[870] = { ["class"]={"HUNTER",}, }, -- Huntmaster's Fierce Wolfhawk
[872] = { ["class"]={"HUNTER",}, }, -- Huntmaster's Dire Wolfhawk
[884] = { ["class"]={"ROGUE",}, }, -- Shadowblade's Murderous Omen
[885] = { ["class"]={"PALADIN",}, }, -- Highlord's Golden Charger
[888] = { ["class"]={"SHAMAN",}, }, -- Farseer's Raging Tempest
[889] = { ["class"]={"ROGUE",}, }, -- Shadowblade's Lethal Omen
[890] = { ["class"]={"ROGUE",}, }, -- Shadowblade's Baneful Omen
[891] = { ["class"]={"ROGUE",}, }, -- Shadowblade's Crimson Omen
[892] = { ["class"]={"PALADIN",}, }, -- Highlord's Vengeful Charger
[893] = { ["class"]={"PALADIN",}, }, -- Highlord's Vigilant Charger
[894] = { ["class"]={"PALADIN",}, }, -- Highlord's Valorous Charger
[898] = { ["class"]={"WARLOCK",}, }, -- Netherlord's Chaotic Wrathsteed
[930] = { ["class"]={"WARLOCK",}, }, -- Netherlord's Brimstone Wrathsteed
[931] = { ["class"]={"WARLOCK",}, }, -- Netherlord's Accursed Wrathsteed
[1046] = { ["class"]={"PALADIN",}, ["race"]={"DarkIronDwarf",}, }, -- Darkforge Ram
[1047] = { ["class"]={"PALADIN",}, ["race"]={"Dwarf","DarkIronDwarf",}, }, -- Dawnforge Ram
[1225] = { ["class"]={"PALADIN",}, ["race"]={"ZandalariTroll",}, }, -- Crusader's Direhorn
[1298] = { ["covenant"]={2,}, }, -- Hopecrusher Gargon
[1299] = { ["covenant"]={2,}, }, -- Battle Gargon Vrednic
[1302] = { ["covenant"]={3,}, }, -- Dreamlight Runestag
[1303] = { ["covenant"]={3,}, }, -- Enchanted Dreamlight Runestag
[1354] = { ["covenant"]={3,}, }, -- Shadeleaf Runestag
[1355] = { ["covenant"]={3,}, }, -- Wakener's Runestag
[1356] = { ["covenant"]={3,}, }, -- Winterborn Runestag
[1357] = { ["covenant"]={3,}, }, -- Enchanted Shadeleaf Runestag
[1358] = { ["covenant"]={3,}, }, -- Enchanted Wakener's Runestag
[1359] = { ["covenant"]={3,}, }, -- Enchanted Winterborn Runestag
[1364] = { ["covenant"]={4,}, }, -- War-Bred Tauralus
[1365] = { ["covenant"]={4,}, }, -- Plaguerot Tauralus
[1366] = { ["covenant"]={4,}, }, -- Bonehoof Tauralus
[1367] = { ["covenant"]={4,}, }, -- Chosen Tauralus
[1368] = { ["covenant"]={4,}, }, -- Armored War-Bred Tauralus
[1369] = { ["covenant"]={4,}, }, -- Armored Plaguerot Tauralus
[1370] = { ["covenant"]={4,}, }, -- Armored Bonehoof Tauralus
[1371] = { ["covenant"]={4,}, }, -- Armored Chosen Tauralus
[1382] = { ["covenant"]={2,}, }, -- Inquisition Gargon
[1384] = { ["covenant"]={2,}, }, -- Sinfall Gargon
[1385] = { ["covenant"]={2,}, }, -- Crypt Gargon
[1387] = { ["covenant"]={2,}, }, -- Desire's Battle Gargon
[1388] = { ["covenant"]={2,}, }, -- Gravestone Battle Gargon
[1389] = { ["covenant"]={2,}, }, -- Battle Gargon Silessa
[1394] = { ["covenant"]={1,}, }, -- Phalynx of Loyalty
[1395] = { ["covenant"]={1,}, }, -- Phalynx of Humility
[1396] = { ["covenant"]={1,}, }, -- Phalynx of Courage
[1398] = { ["covenant"]={1,}, }, -- Phalynx of Purity
[1399] = { ["covenant"]={1,}, }, -- Eternal Phalynx of Purity
[1400] = { ["covenant"]={1,}, }, -- Eternal Phalynx of Courage
[1401] = { ["covenant"]={1,}, }, -- Eternal Phalynx of Loyalty
[1402] = { ["covenant"]={1,}, }, -- Eternal Phalynx of Humility
[1436] = { ["covenant"]={1,}, }, -- Battle-Hardened Aquilon
[1449] = { ["covenant"]={4,}, }, -- Lord of the Corpseflies
[1484] = { ["covenant"]={3,}, }, -- Ardenweald Wilderling
[1485] = { ["covenant"]={3,}, }, -- Autumnal Wilderling
[1486] = { ["covenant"]={3,}, }, -- Winter Wilderling
[1487] = { ["covenant"]={3,}, }, -- Summer Wilderling
[1489] = { ["covenant"]={2,}, }, -- Obsidian Gravewing
[1490] = { ["covenant"]={2,}, }, -- Sinfall Gravewing
[1491] = { ["covenant"]={2,}, }, -- Pale Gravewing
[1492] = { ["covenant"]={1,}, }, -- Elysian Aquilon
[1493] = { ["covenant"]={1,}, }, -- Forsworn Aquilon
[1494] = { ["covenant"]={1,}, }, -- Ascendant's Aquilon
[1495] = { ["covenant"]={4,}, }, -- Maldraxxian Corpsefly
[1496] = { ["covenant"]={4,}, }, -- Regal Corpsefly
[1497] = { ["covenant"]={4,}, }, -- Battlefield Swarmer
[1568] = { ["class"]={"PALADIN",}, ["race"]={"LightforgedDraenei",}, }, -- Lightforged Ruinstrider
[1597] = { ["race"]={"DarkIronDwarf",}, }, -- Grimhowl
[1727] = { ["quest"]={73199,}, }, -- Tarecgosa's Visage
[1869] = { ["class"]={"PALADIN",}, ["race"]={"Tauren",}, }, -- Summon Sunwalker Kodo
[1870] = { ["class"]={"PALADIN",}, ["race"]={"Tauren",}, }, -- Summon Great Sunwalker Kodo
[1871] = { ["class"]={"PALADIN",}, ["race"]={"Draenei","LightforgedDraenei",}, }, -- Summon Exarch's Elekk
[1872] = { ["class"]={"PALADIN",}, ["race"]={"Draenei","LightforgedDraenei",}, }, -- Summon Great Exarch's Elekk
[2233] = { ["class"]={"PALADIN",}, }, -- Earthen Ordinant's Ramolith
}
