
AuraFramesDB = {
["namespaces"] = {
["LibDualSpec-1.0"] = {
},
},
["global"] = {
["SpellCooldowns"] = {
["MONK"] = {
},
},
["InternalCooldowns"] = {
},
},
["profileKeys"] = {
["Nerfmw - Sargeras"] = "Nerfmw - Sargeras",
},
["profiles"] = {
["Nerfmw - Sargeras"] = {
["DbVersion"] = 235,
["Containers"] = {
["PlayerBuffs"] = {
["Type"] = "ButtonContainer",
["Order"] = {
["Expert"] = false,
["Predefined"] = "NoTimeTimeLeftDesc",
["Rules"] = {
{
["Args"] = {
["Float"] = 0,
},
["Subject"] = "ExpirationTime",
["Operator"] = "First",
},
{
["Args"] = {
},
["Subject"] = "ExpirationTime",
["Operator"] = "NumberDesc",
},
},
},
["Layout"] = {
["DurationOutline"] = "OUTLINE",
["SpaceY"] = 15,
["DurationFont"] = "Friz Quadrata TT",
["DurationMonochrome"] = false,
["Clickable"] = true,
["ShowTooltip"] = true,
["HorizontalSize"] = 16,
["MiniBarDirection"] = "HIGHSHRINK",
["CountAlignment"] = "CENTER",
["TooltipShowUnitName"] = false,
["MiniBarColor"] = {
1,
1,
1,
1,
},
["CountColor"] = {
1,
1,
1,
1,
},
["MiniBarLength"] = 36,
["DurationPosY"] = -25,
["ButtonSizeX"] = 36,
["CountOutline"] = "OUTLINE",
["SpaceX"] = 5,
["VerticalSize"] = 2,
["Direction"] = "LEFTDOWN",
["DurationSize"] = 10,
["CountPosX"] = 10,
["ShowDuration"] = true,
["MiniBarOffsetY"] = -25,
["CountFont"] = "Friz Quadrata TT",
["MiniBarWidth"] = 8,
["DynamicSize"] = false,
["CountSize"] = 10,
["DurationColor"] = {
1,
1,
1,
1,
},
["Scale"] = 1,
["TooltipShowClassification"] = false,
["CountMonochrome"] = false,
["ShowCount"] = true,
["ButtonSizeY"] = 36,
["TooltipShowPrefix"] = false,
["ShowBorder"] = "ALWAYS",
["CountPosY"] = -6,
["DurationLayout"] = "ABBREVSPACE",
["CooldownReverse"] = false,
["TooltipShowAuraId"] = false,
["ShowCooldown"] = false,
["MiniBarStyle"] = "HORIZONTAL",
["DurationAlignment"] = "CENTER",
["CooldownDisableOmniCC"] = true,
["MiniBarOffsetX"] = 0,
["TooltipShowCaster"] = true,
["MiniBarEnabled"] = false,
["DurationPosX"] = 0,
["CooldownDrawEdge"] = true,
["MiniBarTexture"] = "Blizzard",
},
["Animations"] = {
["AuraNew"] = {
["Enabled"] = true,
["Duration"] = 0.5,
["Animation"] = "FadeIn",
},
["AuraChanging"] = {
["Enabled"] = true,
["Duration"] = 0.3,
["Scale"] = 2.5,
["Animation"] = "Popup",
},
["AuraExpiring"] = {
["Enabled"] = true,
["Duration"] = 1,
["Animation"] = "Flash",
["Times"] = 3,
},
["ContainerVisibility"] = {
["Enabled"] = true,
["Duration"] = 0.5,
["InvisibleAlpha"] = 0.6,
["Animation"] = "Fade",
},
},
["Sources"] = {
["target"] = {
["HARMFUL"] = true,
["HELPFUL"] = true,
},
["player"] = {
["HARMFUL"] = true,
["WEAPON"] = true,
["HELPFUL"] = true,
},
},
["Colors"] = {
["Expert"] = false,
["DefaultColor"] = {
1,
1,
1,
1,
},
["Rules"] = {
{
["Color"] = {
0.8,
0,
0,
1,
},
["Name"] = "Unknown Debuff Type",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "None",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
0.2,
0.6,
1,
1,
},
["Name"] = "Debuff Type Magic",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "Magic",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
0.6,
0,
1,
1,
},
["Name"] = "Debuff Type Curse",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "Curse",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
0.6,
0.4,
0,
1,
},
["Name"] = "Debuff Type Disease",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "Disease",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
0,
0.6,
0,
1,
},
["Name"] = "Debuff Type Poison",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "Poison",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
1,
1,
1,
1,
},
["Name"] = "Buff",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HELPFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
1,
1,
1,
1,
},
["Name"] = "Weapon",
["Groups"] = {
{
{
["Args"] = {
["String"] = "WEAPON",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
},
},
},
},
},
["Filter"] = {
["Groups"] = {
},
["Expert"] = false,
},
["Location"] = {
["OffsetX"] = -183.5,
["OffsetY"] = -7.5,
["FramePoint"] = "TOPRIGHT",
["RelativePoint"] = "TOPRIGHT",
},
["Name"] = "Player Buffs",
["Visibility"] = {
["AlwaysVisible"] = true,
["VisibleWhen"] = {
},
["VisibleWhenNot"] = {
},
},
["Id"] = "PlayerBuffs",
},
["PlayerDebuffs"] = {
["Type"] = "ButtonContainer",
["Order"] = {
["Expert"] = false,
["Predefined"] = "NoTimeTimeLeftDesc",
["Rules"] = {
{
["Args"] = {
["Float"] = 0,
},
["Subject"] = "ExpirationTime",
["Operator"] = "First",
},
{
["Args"] = {
},
["Subject"] = "ExpirationTime",
["Operator"] = "NumberDesc",
},
},
},
["Layout"] = {
["DurationOutline"] = "OUTLINE",
["SpaceY"] = 15,
["DurationFont"] = "Friz Quadrata TT",
["DurationMonochrome"] = false,
["Clickable"] = true,
["ShowTooltip"] = true,
["HorizontalSize"] = 16,
["MiniBarDirection"] = "HIGHSHRINK",
["CountAlignment"] = "CENTER",
["TooltipShowUnitName"] = false,
["MiniBarColor"] = {
1,
1,
1,
1,
},
["CountColor"] = {
1,
1,
1,
1,
},
["MiniBarLength"] = 36,
["DurationPosY"] = -25,
["ButtonSizeX"] = 36,
["CountOutline"] = "OUTLINE",
["SpaceX"] = 5,
["VerticalSize"] = 2,
["Direction"] = "LEFTDOWN",
["DurationSize"] = 10,
["CountPosX"] = 10,
["ShowDuration"] = true,
["MiniBarOffsetY"] = -25,
["CountFont"] = "Friz Quadrata TT",
["MiniBarWidth"] = 8,
["DynamicSize"] = false,
["CountSize"] = 10,
["DurationColor"] = {
1,
1,
1,
1,
},
["Scale"] = 1,
["TooltipShowClassification"] = false,
["CountMonochrome"] = false,
["ShowCount"] = true,
["ButtonSizeY"] = 36,
["TooltipShowPrefix"] = false,
["ShowBorder"] = "ALWAYS",
["CountPosY"] = -6,
["DurationLayout"] = "ABBREVSPACE",
["CooldownReverse"] = false,
["TooltipShowAuraId"] = false,
["ShowCooldown"] = false,
["MiniBarStyle"] = "HORIZONTAL",
["DurationAlignment"] = "CENTER",
["CooldownDisableOmniCC"] = true,
["MiniBarOffsetX"] = 0,
["TooltipShowCaster"] = true,
["MiniBarEnabled"] = false,
["DurationPosX"] = 0,
["CooldownDrawEdge"] = true,
["MiniBarTexture"] = "Blizzard",
},
["Animations"] = {
["AuraNew"] = {
["Enabled"] = true,
["Duration"] = 0.5,
["Animation"] = "FadeIn",
},
["AuraChanging"] = {
["Enabled"] = true,
["Duration"] = 0.3,
["Scale"] = 2.5,
["Animation"] = "Popup",
},
["AuraExpiring"] = {
["Enabled"] = true,
["Duration"] = 1,
["Animation"] = "Flash",
["Times"] = 3,
},
["ContainerVisibility"] = {
["Enabled"] = true,
["Duration"] = 0.5,
["InvisibleAlpha"] = 0.6,
["Animation"] = "Fade",
},
},
["Sources"] = {
["player"] = {
["HARMFUL"] = true,
},
},
["Colors"] = {
["Expert"] = false,
["DefaultColor"] = {
1,
1,
1,
1,
},
["Rules"] = {
{
["Color"] = {
0.8,
0,
0,
1,
},
["Name"] = "Unknown Debuff Type",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "None",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
0.2,
0.6,
1,
1,
},
["Name"] = "Debuff Type Magic",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "Magic",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
0.6,
0,
1,
1,
},
["Name"] = "Debuff Type Curse",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "Curse",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
0.6,
0.4,
0,
1,
},
["Name"] = "Debuff Type Disease",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "Disease",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
0,
0.6,
0,
1,
},
["Name"] = "Debuff Type Poison",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HARMFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
{
["Args"] = {
["String"] = "Poison",
},
["Subject"] = "Classification",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
1,
1,
1,
1,
},
["Name"] = "Buff",
["Groups"] = {
{
{
["Args"] = {
["String"] = "HELPFUL",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
},
},
},
{
["Color"] = {
1,
1,
1,
1,
},
["Name"] = "Weapon",
["Groups"] = {
{
{
["Args"] = {
["String"] = "WEAPON",
},
["Subject"] = "Type",
["Operator"] = "Equal",
},
},
},
},
},
},
["Filter"] = {
["Groups"] = {
},
["Expert"] = false,
},
["Location"] = {
["OffsetX"] = -183.5,
["OffsetY"] = -106.5,
["FramePoint"] = "TOPRIGHT",
["RelativePoint"] = "TOPRIGHT",
},
["Name"] = "Player Debuffs",
["Visibility"] = {
["AlwaysVisible"] = true,
["VisibleWhen"] = {
},
["VisibleWhenNot"] = {
},
},
["Id"] = "PlayerDebuffs",
},
},
},
},
}
