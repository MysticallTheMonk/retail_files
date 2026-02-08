
Grid2DB = {
["namespaces"] = {
["Grid2Frame"] = {
["profiles"] = {
["mysticall-midnight"] = {
["iconSize"] = 12,
["frameBorderDistance"] = -1,
["frameHeight"] = 44,
["displayZoomedIcons"] = true,
["frameColor"] = {
["a"] = 0,
},
["barTexture"] = "sArena Default",
["orientation"] = "HORIZONTAL",
["frameTexture"] = "sArena Default",
["frameWidth"] = 86,
["frameContentColor"] = {
["a"] = 0,
},
},
["Mysticallx - Sargeras"] = {
["frameHeight"] = 52,
["frameTexture"] = "Blizzard DF",
["iconSize"] = 18,
["barTexture"] = "Blizzard Raid Bar",
["displayZoomedIcons"] = true,
["frameWidth"] = 100,
},
},
},
["Grid2Layout"] = {
["profiles"] = {
["mysticall-midnight"] = {
["BackgroundTexture"] = "None",
["ScaleSize"] = 1.65,
["HideInPetBattle"] = true,
["PosX"] = 417.8668483216825,
["PosY"] = -351.4666052080793,
["horizontal"] = false,
["BorderTexture"] = "None",
},
["Mysticallx - Sargeras"] = {
["BackgroundG"] = 0.1019607931375504,
["BackgroundTexture"] = "Blizzard Dialog Background",
["BorderB"] = 0.501960813999176,
["BackgroundR"] = 0.1019607931375504,
["ScaleSize"] = 1.5,
["BorderA"] = 0,
["BorderR"] = 0.501960813999176,
["PosX"] = 416.7999516212949,
["PosY"] = -350.3997284960806,
["BackgroundA"] = 0,
["BorderG"] = 0.501960813999176,
["BackgroundB"] = 0.1019607931375504,
},
},
},
},
["global"] = {
["defaultProfileName"] = "mysticall-midnight",
},
["profileKeys"] = {
["Mysticallx - Sargeras"] = "mysticall-midnight",
},
["profiles"] = {
["mysticall-midnight"] = {
["hideBlizzard"] = {
["party"] = true,
["raid"] = true,
},
["indicators"] = {
["power-bar-color"] = {
["type"] = "bar-color",
},
["icon-left"] = {
["type"] = "icon",
["location"] = {
["y"] = 15,
["relPoint"] = "LEFT",
["point"] = "LEFT",
["x"] = 0,
},
["disableCooldown"] = true,
["level"] = 8,
["fontSize"] = 8,
["size"] = 10,
},
["health-bar-color"] = {
["type"] = "multibar-color",
},
["background"] = {
["type"] = "background",
},
["icon-center"] = {
["disableStack"] = true,
["type"] = "icon",
["fontSize"] = 8,
["location"] = {
["y"] = 0,
["relPoint"] = "CENTER",
["point"] = "CENTER",
["x"] = 0,
},
["level"] = 9,
["disableCooldown"] = true,
["size"] = 20,
},
["private-auras"] = {
["maxIcons"] = 1,
["type"] = "privateauras",
["location"] = {
["y"] = 14,
["relPoint"] = "CENTER",
["point"] = "CENTER",
["x"] = 0,
},
["level"] = 9,
["load"] = {
["unitType"] = {
["self"] = true,
["player"] = true,
},
},
["iconSize"] = 24,
},
["icon-right"] = {
["type"] = "icon",
["location"] = {
["y"] = 0,
["relPoint"] = "RIGHT",
["point"] = "RIGHT",
["x"] = 2,
},
["disableCooldown"] = true,
["level"] = 8,
["fontSize"] = 8,
["size"] = 12,
},
["health-bar"] = {
{
["horTile"] = "REPEAT",
["reverse"] = true,
["color"] = {
["a"] = 0.699999988079071,
["r"] = 0.2745098173618317,
["g"] = 0.2352941334247589,
["b"] = 1,
},
["verTile"] = "REPEAT",
["texture"] = "Grid2 Shield",
},
{
["color"] = {
["a"] = 0.7,
},
},
{
["horTile"] = "REPEAT",
["color"] = {
["a"] = 0.7,
},
["verTile"] = "REPEAT",
["prevBar"] = 1,
["texture"] = "Grid2 Shield",
},
{
["color"] = {
["a"] = 1,
["r"] = 0.965,
["g"] = 0.992,
["b"] = 1,
},
["glowLine"] = 6,
["prevBar"] = -1,
["texture"] = "Grid2 GlowV",
},
["textureColor"] = {
["a"] = 1,
},
["backColor"] = {
["a"] = 0.8203127980232239,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["location"] = {
["y"] = 0,
["relPoint"] = "CENTER",
["point"] = "CENTER",
["x"] = 0,
},
["level"] = 3,
["type"] = "multibar",
},
["tooltip"] = {
["type"] = "tooltip",
["showDefault"] = true,
["showTooltip"] = 2,
},
["alpha"] = {
["type"] = "alpha",
},
["buffs-icons"] = {
["fontSize"] = 9,
["borderOpacity"] = 1,
["tooltipEnabled"] = true,
["fontJustifyV"] = "TOP",
["borderSize"] = 1,
["iconSize"] = 0.24,
["maxIconsPerRow"] = 4,
["tooltipAnchor"] = "ANCHOR_RIGHT",
["type"] = "icons",
["iconSpacing"] = 0,
["fontJustifyH"] = "RIGHT",
["color1"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["maxIcons"] = 9,
["ctFontSize"] = 10,
["location"] = {
["y"] = 0,
["relPoint"] = "BOTTOMRIGHT",
["point"] = "BOTTOMRIGHT",
["x"] = 0,
},
["disableOmniCC"] = true,
["reverseCooldown"] = true,
["level"] = 8,
},
["debuffs-icons"] = {
["fontSize"] = 9,
["borderOpacity"] = 1,
["disableCooldown"] = true,
["fontJustifyV"] = "TOP",
["borderSize"] = 1,
["iconSize"] = 19,
["level"] = 8,
["tooltipAnchor"] = "ANCHOR_LEFT",
["type"] = "icons",
["enableCooldownText"] = true,
["reverseCooldown"] = true,
["maxIconsPerRow"] = 4,
["color1"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["maxIcons"] = 9,
["fontOffsetY"] = 4,
["ctFontSize"] = 12,
["tooltipEnabled"] = true,
["location"] = {
["y"] = -31,
["relPoint"] = "LEFT",
["point"] = "LEFT",
["x"] = -20,
},
["useStatusColor"] = true,
["disableOmniCC"] = true,
["fontJustifyH"] = "RIGHT",
},
["text-name-color"] = {
["type"] = "text-color",
},
["role-icons"] = {
["disableStack"] = true,
["type"] = "icons",
["disableCooldown"] = true,
["level"] = 9,
["location"] = {
["y"] = 0,
["relPoint"] = "TOPRIGHT",
["point"] = "TOPRIGHT",
["x"] = -1,
},
["iconSize"] = 12,
},
["power-bar"] = {
["type"] = "bar",
["backColor"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["color1"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["hideWhenInactive"] = true,
["orientation"] = "HORIZONTAL",
["height"] = 3,
["backTexture"] = "Grid2 Flat",
["level"] = 5,
["location"] = {
["y"] = 0,
["relPoint"] = "BOTTOM",
["point"] = "BOTTOM",
["x"] = 0,
},
["texture"] = "Gradient",
},
["text-name"] = {
["type"] = "text",
["percent"] = true,
["location"] = {
["y"] = -2,
["relPoint"] = "TOPLEFT",
["point"] = "TOPLEFT",
["x"] = 10,
},
["level"] = 7,
["textlength"] = 20,
["fontSize"] = 7,
},
["border"] = {
["type"] = "border",
["color1"] = {
["a"] = 0,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
},
},
["statusMap"] = {
["debuffs-icons"] = {
["debuffs-Relevant"] = 50,
},
["power-bar-color"] = {
["power"] = 51,
},
["icon-right"] = {
["raid-icon-target"] = 151,
},
["health-bar"] = {
["heal-absorbs"] = 2,
["shields"] = 4,
["shields-overflow"] = 5,
["heals-incoming"] = 3,
["health-current"] = 1,
},
["icon-left"] = {
["dungeon-role"] = 158,
["raid-icon-player"] = 156,
["role"] = 157,
},
["border"] = {
["target"] = 50,
},
["buffs-icons"] = {
["buffs-Relevant"] = 100,
},
["text-name-color"] = {
["offline"] = 97,
["feign-death"] = 96,
["death"] = 98,
},
["text-name"] = {
["name"] = 70,
["offline"] = 97,
["feign-death"] = 96,
["death"] = 98,
},
["power-bar"] = {
},
["alpha"] = {
["range"] = 99,
},
["role-icons"] = {
["offline"] = 50,
["role"] = 52,
["death"] = 51,
},
["background"] = {
["health-current"] = 50,
},
["health-bar-color"] = {
["classcolor"] = 50,
},
["icon-center"] = {
["phased"] = 50,
["resurrection"] = 54,
["death"] = 53,
["ready-check"] = 55,
["offline"] = 52,
["summon"] = 51,
},
},
["statuses"] = {
["buffs-Relevant"] = {
["type"] = "mbuffs",
["aura_filter"] = {
["blizFilter"] = "HELPFUL|RAID",
["sortRule"] = 3,
},
["color1"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["master-looter"] = {
["hideInCombat"] = true,
},
["dungeon-role"] = {
["hideInCombat"] = true,
},
["heals-incoming"] = {
["includePlayerHeals"] = true,
},
["threat"] = {
["color3"] = {
["g"] = 0.5,
},
},
["debuffs-Relevant"] = {
["type"] = "mdebuffs",
["colors"] = {
},
["aura_filter"] = {
["sortRule"] = 3,
},
},
["leader"] = {
["hideInCombat"] = true,
},
},
["versions"] = {
["Grid2"] = 100,
},
["__template"] = "Blizzard",
["themes"] = {
["indicators"] = {
[0] = {
},
},
},
},
["Mysticallx - Sargeras"] = {
["statuses"] = {
["dungeon-role"] = {
["hideInCombat"] = true,
},
["heals-incoming"] = {
["includePlayerHeals"] = true,
},
["buffs-Relevant"] = {
["type"] = "mbuffs",
["aura_filter"] = {
["filter"] = "HELPFUL|RAID",
["sortRule"] = 3,
},
["color1"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["debuffs-Relevant"] = {
["type"] = "mdebuffs",
["colors"] = {
},
["aura_filter"] = {
["sortRule"] = 3,
},
},
},
["indicators"] = {
["power-bar-color"] = {
["type"] = "bar-color",
},
["text-down"] = {
["type"] = "text",
["location"] = {
["y"] = 4,
["relPoint"] = "BOTTOM",
["point"] = "BOTTOM",
["x"] = 0,
},
["level"] = 6,
["textlength"] = 6,
["fontSize"] = 10,
},
["icon-left"] = {
["type"] = "icon",
["location"] = {
["y"] = 0,
["relPoint"] = "LEFT",
["point"] = "LEFT",
["x"] = -2,
},
["level"] = 8,
["fontSize"] = 8,
["size"] = 12,
},
["border"] = {
["type"] = "border",
["color1"] = {
["a"] = 0,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
},
["text-down-color"] = {
["type"] = "text-color",
},
["icon-center"] = {
["type"] = "icon",
["location"] = {
["y"] = 0,
["relPoint"] = "CENTER",
["point"] = "CENTER",
["x"] = 0,
},
["level"] = 9,
["fontSize"] = 8,
["size"] = 20,
},
["private-auras"] = {
["maxIcons"] = 1,
["type"] = "privateauras",
["location"] = {
["y"] = 0,
["relPoint"] = "CENTER",
["point"] = "CENTER",
["x"] = 0,
},
["level"] = 9,
["load"] = {
["unitType"] = {
["self"] = true,
["player"] = true,
},
},
["iconSize"] = 25,
},
["icon-right"] = {
["type"] = "icon",
["location"] = {
["y"] = 0,
["relPoint"] = "RIGHT",
["point"] = "RIGHT",
["x"] = 2,
},
["level"] = 8,
["fontSize"] = 8,
["size"] = 12,
},
["health-bar"] = {
{
["horTile"] = "REPEAT",
["reverse"] = true,
["color"] = {
["a"] = 0.7,
["r"] = 1,
["g"] = 0,
["b"] = 0.737,
},
["verTile"] = "REPEAT",
["texture"] = "Grid2 Shield",
},
{
["color"] = {
["a"] = 0.5,
},
},
{
["horTile"] = "REPEAT",
["color"] = {
["a"] = 0.7,
},
["verTile"] = "REPEAT",
["prevBar"] = 1,
["texture"] = "Grid2 Shield",
},
{
["color"] = {
["a"] = 1,
["r"] = 0.965,
["g"] = 0.992,
["b"] = 1,
},
["glowLine"] = 6,
["prevBar"] = -1,
["texture"] = "Grid2 GlowH",
},
["location"] = {
["y"] = 0,
["relPoint"] = "CENTER",
["point"] = "CENTER",
["x"] = 0,
},
["type"] = "multibar",
["textureColor"] = {
["a"] = 1,
},
["level"] = 3,
},
["debuffs-icons"] = {
["fontSize"] = 9,
["borderOpacity"] = 1,
["disableCooldown"] = true,
["fontJustifyV"] = "TOP",
["borderSize"] = 1,
["iconSize"] = 26,
["level"] = 8,
["tooltipAnchor"] = "ANCHOR_BOTTOMRIGHT",
["type"] = "icons",
["enableCooldownText"] = true,
["reverseCooldown"] = true,
["color1"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["tooltipEnabled"] = true,
["ctFontSize"] = 10,
["disableOmniCC"] = true,
["location"] = {
["y"] = -2,
["relPoint"] = "CENTER",
["point"] = "CENTER",
["x"] = 0,
},
["fontJustifyH"] = "RIGHT",
["useStatusColor"] = true,
["smartCenter"] = true,
},
["alpha"] = {
["type"] = "alpha",
},
["buffs-icons"] = {
["tooltipAnchor"] = "ANCHOR_TOPRIGHT",
["disableOmniCC"] = true,
["enableCooldownText"] = true,
["tooltipEnabled"] = true,
["reverseCooldown"] = true,
["color1"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["fontJustifyV"] = "TOP",
["fontSize"] = 9,
["borderSize"] = 1,
["ctFontSize"] = 10,
["borderOpacity"] = 1,
["location"] = {
["y"] = 0,
["relPoint"] = "TOPLEFT",
["point"] = "TOPLEFT",
["x"] = 0,
},
["level"] = 8,
["type"] = "icons",
["fontJustifyH"] = "RIGHT",
},
["health-bar-color"] = {
["type"] = "multibar-color",
},
["corner-bottom"] = {
["type"] = "square",
["location"] = {
["y"] = 5,
["relPoint"] = "BOTTOM",
["point"] = "BOTTOM",
["x"] = 0,
},
["level"] = 9,
["size"] = 7,
["color1"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["text-up-color"] = {
["type"] = "text-color",
},
["text-up"] = {
["type"] = "text",
["percent"] = true,
["location"] = {
["y"] = -8,
["relPoint"] = "TOP",
["point"] = "TOP",
["x"] = 0,
},
["level"] = 7,
["textlength"] = 6,
["fontSize"] = 9,
},
["power-bar"] = {
["type"] = "bar",
["backColor"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["color1"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["hideWhenInactive"] = true,
["orientation"] = "HORIZONTAL",
["height"] = 4,
["backTexture"] = "Grid2 Flat",
["level"] = 5,
["location"] = {
["y"] = -1,
["relPoint"] = "BOTTOM",
["point"] = "BOTTOM",
["x"] = 0,
},
["texture"] = "Gradient",
},
["tooltip"] = {
["showDefault"] = true,
["type"] = "tooltip",
},
["background"] = {
["type"] = "background",
},
},
["statusMap"] = {
["icon-right"] = {
["dungeon-role"] = 150,
},
["debuffs-icons"] = {
["debuffs-Relevant"] = 50,
},
["power-bar-color"] = {
["power"] = 51,
},
["text-down"] = {
["name"] = 99,
},
["health-bar"] = {
["heal-absorbs"] = 2,
["shields"] = 4,
["shields-overflow"] = 5,
["heals-incoming"] = 3,
["health-current"] = 1,
},
["icon-left"] = {
["raid-icon-player"] = 155,
},
["health-bar-color"] = {
["classcolor"] = 50,
},
["buffs-icons"] = {
["buffs-Relevant"] = 100,
},
["text-down-color"] = {
["classcolor"] = 99,
},
["alpha"] = {
["range"] = 99,
},
["corner-bottom"] = {
["threat"] = 99,
},
["border"] = {
["target"] = 50,
["debuffs-DispellableByMe"] = 51,
},
["text-up"] = {
["charmed"] = 70,
["feign-death"] = 96,
["death"] = 97,
["vehicle"] = 93,
["health-current"] = 65,
["offline"] = 95,
},
["text-up-color"] = {
["charmed"] = 93,
["feign-death"] = 96,
["death"] = 98,
["classcolor"] = 65,
["offline"] = 97,
["vehicle"] = 95,
},
["power-bar"] = {
["power"] = 50,
},
["icon-center"] = {
["phased"] = 50,
["resurrection"] = 54,
["death"] = 53,
["ready-check"] = 55,
["offline"] = 52,
["summon"] = 51,
},
},
["formatting"] = {
["longDurationStackFormat"] = "%.0f:%d",
["longDecimalFormat"] = "%.0f",
},
["versions"] = {
["Grid2"] = 100,
},
["__template"] = "Classic",
["themes"] = {
["indicators"] = {
[0] = {
},
},
},
},
},
}
