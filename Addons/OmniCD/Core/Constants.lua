local E, L = select(2, ...):unpack()

do
	L["Arena"] = ARENA
	L["Battlegrounds"] = BATTLEGROUNDS
	L["Dungeons"] = DUNGEONS
	L["Raids"] = RAIDS
	L["Scenarios"] = SCENARIOS
	L["Outdoor Zones"] = BUG_CATEGORY2
	L["More..."] = LFG_LIST_MORE
	L["Trinket"] = INVTYPE_TRINKET
	L["Interrupt"] = LOC_TYPE_INTERRUPT
	L["Dispels"] = DISPELS
	L["Other"] = OTHER
	L["PvP Trinket"] = C_Spell.GetSpellName(42292) or C_Spell.GetSpellName(283167) or L["PvP Trinket"]
	L["Racial Traits"] = type(RACIAL_TRAITS) == "string" and gsub(RACIAL_TRAITS, ":", "") or L["Racial Traits"]
	L["Disarm"] = LOC_TYPE_DISARM
	L["Root"] = LOC_TYPE_ROOT
	L["Silence"] = LOC_TYPE_SILENCE
	L["Disrm, Root, Silence"] = format("%s, %s, %s", L["Disarm"], L["Root"], L["Silence"])
	L["Main Hand"] = INVTYPE_WEAPONMAINHAND
	L["Consumables"] = BAG_FILTER_CONSUMABLES
	L["Trinket, Main Hand"] = format("%s, %s, %s", L["Trinket"], L["Main Hand"], L["Consumables"])
	L["Signature Ability"] = COVENANT_PREVIEW_RACIAL_ABILITY or "Signature Ability"
	L["Essence"] = AZERITE_ESSENCE_ITEM_TYPE or "Essence"
	L["Max"] = MAXIMUM
	L["Spells"] = type(SPELLS) == "string" and SPELLS or L["Spells"]
	L["Highlighting"] = HIGHLIGHTING:gsub(":", "")
	L["Custom"] = CUSTOM
end

E.L_CFG_ZONE = {
	["arena"] = L["Arena"],
	["pvp"] = L["Battlegrounds"],
	["party"] = L["Dungeons"],
	["raid"] = L["Raids"],
}

E.L_ALL_ZONE = {
	["arena"] = L["Arena"],
	["pvp"] = L["Battlegrounds"],
	["party"] = L["Dungeons"],
	["raid"] = L["Raids"],
	["scenario"] = L["Scenarios"],
	["none"] = L["Outdoor Zones"],
}

E.L_PRIORITY = {
	["pvptrinket"] = L["PvP Trinket"],
	["racial"] = L["Racial Traits"],
	["interrupt"] = L["Interrupt"],
	["dispel"] = L["Dispels"],
	["cc"] = L["Hard CC"],
	["aoeCC"] = L["AOE CC"],
	["disarm"] = L["Soft CC"],
	["immunity"] = L["Immunity"],
	["defensive"] = L["Defensive"],
	["tankDefensive"] = L["Tank Defensive"],
	["externalDefensive"] = L["External Defensive"],
	["raidDefensive"] = L["Raid Defensive"],
	["heal"] = L["Heal"],
	["offensive"] = L["Offensive"],
	["counterCC"] = L["Counter CC"],
	["freedom"] = L["Freedom"],
	["movement"] = L["Movement"],
	["raidMovement"] = L["Raid Movement"],
	["other"] = L["Other"],
	["taunt"] = L["Taunt"],
	["trinket"] = L["Trinket"],
	["covenant"] = L["Covenant"],
	["essence"] = L["Essence"],
	["consumable"] = L["Consumables"],
	["custom1"] = L["Custom"] .. 1,
	["custom2"] = L["Custom"] .. 2,
}

E.L_HIGHLIGHTS = {
	["racial"] = L["Racial Traits"],
	["immunity"] = L["Immunity"],
	["defensive"] = L["Defensive"],
	["tankDefensive"] = L["Tank Defensive"],
	["externalDefensive"] = L["External Defensive"],
	["raidDefensive"] = L["Raid Defensive"],
	["heal"] = L["Heal"],
	["offensive"] = L["Offensive"],
	["counterCC"] = L["Counter CC"],
	["freedom"] = L["Freedom"],
	["movement"] = L["Movement"],
	["raidMovement"] = L["Raid Movement"],
	["other"] = L["Other"],
	["trinket"] = L["Trinket"],
	["covenant"] = L["Covenant"],
	["essence"] = L["Essence"],
}

if E.preCata then
	E.L_PRIORITY.essence = nil
	E.L_PRIORITY.covenant = nil
	E.L_HIGHLIGHTS.covenant = nil
end

E.TEXTURES = E.preCata and {
	["White8x8"] = "Interface\\BUTTONS\\White8x8",
	["CLASS"] = "Interface\\Icons\\classicon_",
	["DEATHKNIGHT"] = "Interface\\Icons\\spell_deathknight_classicon",
	["PVPTRINKET"] = "Interface\\Icons\\inv_jewelry_trinketpvp_01",
	["RACIAL"] = "Interface\\Icons\\achievement_character_troll_male",
	["TRINKET"] = "Interface\\Icons\\inv_misc_armorkit_10",
} or {
	["White8x8"] = "Interface\\BUTTONS\\White8x8",
	--["CLASS"] = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
	["CLASS"] = "Interface\\Icons\\classicon_",
	["PVPTRINKET"] = "Interface\\Icons\\ability_pvp_gladiatormedallion",
	["RACIAL"] = "Interface\\Icons\\Achievement_character_human_female",
	["TRINKET"] = "Interface\\Icons\\inv_60pvp_trinket2d",
	["ESSENCE"] = "Interface\\Icons\\inv_heartofazeroth",
	["COVENANT"] = 3257750,
	["CONSUMABLE"] = 3566860,
}

E.BORDERLESS_TCOORDS = { 0.07, 0.93, 0.07, 0.93 }

E.STR = {
	["RELOAD_UI"] = L["Reload UI?"],
	["ENABLE_BLIZZARD_CRF"] = L["Blizzard Raid Frames has been disabled by your AddOn(s). Enable and reload UI?"],
	["UNSUPPORTED_ADDON"] = L["Raid Frames for testing doesn't exist for %s. If it fails to load, configure OmniCD while in a group or temporarily set it to \'Manual Mode\'."],
	["MAX_RANGE"] = L["Max"] .. ": 999",
	["MAX_RANGE_3600"] = L["Max"] .. ": 3600",
	["ENABLE_HUDEDITMODE_FRAME"] = L["You must manually enable either the \'Party Frames\' or \'Raid Frames\' in Blizzard's \'HUD Edit Mode\'."],
	["WHATS_NEW_ESCSEQ"] = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t ",
}

E.HEX_C = {
	[1] = "|cff99cdff",
	[2] = "|cff0291b0",
	[5] = "|cff7bbb4e",
	[11] = "|cff99cdff",
	[14] = "|cffA63416",
	["CURSE_ORANGE"] = "|cfff16436",
	["TWITCH_PURPLE"] = "|cff9146ff",
}

E.BOOKTYPE_CATEGORY = {
	["WARRIOR"] = 1,
	["PALADIN"] = 2,
	["HUNTER"] = 3,
	["ROGUE"] = 4,
	["PRIEST"] = 5,
	["DEATHKNIGHT"] = 6,
	["SHAMAN"] = 7,
	["MAGE"] = 8,
	["WARLOCK"] = 9,
	["MONK"] = 10,
	["DRUID"] = 11,
	["DEMONHUNTER"] = 12,
	["EVOKER"] = 13,
}

E.OTHER_SORT_ORDER = {
	["PVPTRINKET"] = L["PvP Trinket"],
	["RACIAL"] = L["Racial Traits"],
	["TRINKET"] = L["Trinket, Main Hand"],
	["ESSENCES"] = L["Essence"],
	["COVENANT"] = L["Signature Ability"],
	["CONSUMABLE"] = L["Consumables"],
}

E.RAID_TARGET_MARKERS = {
	[0x00000001] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	[0x00000002] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	[0x00000004] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	[0x00000008] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	[0x00000010] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	[0x00000020] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	[0x00000040] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	[0x00000080] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
}

E.HEALER_SPEC = {
	[65] = 90,
	[105] = 90,
	[256] = 90,
	[257] = 90,
	[264] = 90,
	[270] = 90,
	[1468] = 90,
	["default"] = 120,
}

E.BLANK = {}
