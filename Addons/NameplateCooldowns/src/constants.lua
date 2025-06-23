local _, addonTable = ...;

addonTable.SPELL_PVPADAPTATION = 195901;
addonTable.SPELL_PVPTRINKET = 336126;

addonTable.ICON_GROW_DIRECTION_RIGHT = "right";
addonTable.ICON_GROW_DIRECTION_LEFT = "left";
addonTable.ICON_GROW_DIRECTION_UP = "up";
addonTable.ICON_GROW_DIRECTION_DOWN = "down";

addonTable.SORT_MODE_NONE = "none";
addonTable.SORT_MODE_TRINKET_INTERRUPT_OTHER = "trinket-interrupt-other";
addonTable.SORT_MODE_INTERRUPT_TRINKET_OTHER = "interrupt-trinket-other";
addonTable.SORT_MODE_TRINKET_OTHER = "trinket-other";
addonTable.SORT_MODE_INTERRUPT_OTHER = "interrupt-other";

addonTable.GLOW_TIME_INFINITE = 4*1000*1000*1000;

addonTable.INSTANCE_TYPE_NONE = "none";
addonTable.INSTANCE_TYPE_UNKNOWN = "unknown";
addonTable.INSTANCE_TYPE_PVP = "pvp";
addonTable.INSTANCE_TYPE_PVP_BG_40PPL = "pvp_bg_40ppl";
addonTable.INSTANCE_TYPE_ARENA = "arena";
addonTable.INSTANCE_TYPE_PARTY = "party";
addonTable.INSTANCE_TYPE_RAID = "raid";
addonTable.INSTANCE_TYPE_SCENARIO = "scenario";

addonTable.UNKNOWN_CLASS = "MISC";
addonTable.ALL_CLASSES = "ALL-CLASSES";

addonTable.EPIC_BG_ZONE_IDS = {
	[30] = true, -- Alterac Valley
	[628] = true, -- Isle of Conquest
	[1191] = true, -- Ashran
	[1280] = true, -- Southshore vs. Tarren Mill
	[2118] = true, -- Battle for Wintergrasp
	[2197] = true, -- Korrak's Revenge
};