local _, addon = ...;
addon.TEST_MODE = false;

addon.PROJECT_MAINLINE = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE);
addon.PROJECT_TBC = (WOW_PROJECT_ID == 5);
addon.PROFILE_VERSION = 1.0; -- To validate export string

addon.SPELLCATEGORY = {
    IMMUNITY = 1,
    DEFENSIVE = 2,
    DISPEL = 3,
    MASS_DISPEL = 4,
    INTERRUPT = 5,
    STUN = 6,
    SILENCE = 7,
    KNOCKBACK = 8,
    CROWDCONTROL = 9,
    BURST = 10,
    HEAL = 11,
    MOBILITY = 12,
    OTHERS = 100,
};

addon.SPELLCATEGORY_NAME = {
    [addon.SPELLCATEGORY.IMMUNITY] = "Immunity",
    [addon.SPELLCATEGORY.DEFENSIVE] = "Defensive",
    [addon.SPELLCATEGORY.DISPEL] = "Dispel",
    [addon.SPELLCATEGORY.MASS_DISPEL] = "Mass Dispel",
    [addon.SPELLCATEGORY.INTERRUPT] = "Interrupt",
    [addon.SPELLCATEGORY.STUN] = "Stun",
    [addon.SPELLCATEGORY.SILENCE] = "Silence",
    [addon.SPELLCATEGORY.KNOCKBACK] = "Knockback",
    [addon.SPELLCATEGORY.CROWDCONTROL] = "Crowd Control",
    [addon.SPELLCATEGORY.BURST] = "Burst",
    [addon.SPELLCATEGORY.HEAL] = "Heal",
    [addon.SPELLCATEGORY.MOBILITY] = "Mobility",
    [addon.SPELLCATEGORY.OTHERS] = "Others",
};

addon.SPELLPRIORITY = {
    DEADLY = 1,
    HIGH = 10,
    DEFAULT = 50,
    LOW = 100,
};

addon.ICON_TEMPLATE = {
    GLOW = 1, -- AWC style
    FLASH = 2, -- OmniBar style
};

addon.ARENA_COOLDOWN_GROW_DIRECTION = {
    RIGHT = 1,
    LEFT = 3,

    CENTER = 4, -- Probably will never include this option
};

addon.STANDALONE_GROW_DIRECTION = {
    CENTER = 1,
    LEFT = 2,
    RIGHT = 3,
};

addon.ICON_SET_ID = {
    ARENA_MAIN = "Arena",
    ARENA_SECONDARY = "ArenaSecondary",

    STANDALONE_1 = "Bar 1",
    STANDALONE_2 = "Bar 2",
    STANDALONE_3 = "Bar 3",
    STANDALONE_4 = "Bar 4",
    STANDALONE_5 = "Bar 5",
    STANDALONE_6 = "Bar 6",
};

addon.ARENA_FRAME_BARS = {
    [addon.ICON_SET_ID.ARENA_MAIN] = true,
    [addon.ICON_SET_ID.ARENA_SECONDARY] = true,
};

addon.ARENA_FRAME_BARS_SUPPORTED = function()
    if addon.PROJECT_MAINLINE then
        return true;
    else
        return GladiusEx or Gladius or sArena or ArenaLiveUnitFrames or SlashCmdList.GLADDY;
    end
end

addon.GET_ARENA_FRAME_PREFIX = function()
    if addon.ARENA_FRAME_PREFIX == nil then
        addon.ARENA_FRAME_PREFIX =
            ( GladiusEx and "GladiusExButtonFramearena" )
            or ( Gladius and "GladiusButtonFramearena" )
            or ( sArena and "sArenaEnemyFrame" )
            or ( ArenaLiveUnitFrames and "ALUF_ArenaEnemyFramesArenaEnemyFrame" )
            or ( SlashCmdList.GLADDY and "GladdyButtonFrame" )
            or "CompactArenaFrameMember";
    end

    return addon.ARENA_FRAME_PREFIX;
end

addon.DURATION_DYNAMIC = "DURATION_DYNAMIC";

addon.SPECID = {
    BLOOD = 250,
    FROST_DK = 251,
    UNHOLY = 252,

    HAVOC = 577,
    VENGEANCE = 581,

    BALANCE = 102,
    FERAL = 103,
    GUARDIAN = 104,
    RESTORATION_DRUID = 105,

    DEVASTATION = 1467,
    PRESERVATION = 1468,
    AUGMENTATION = 1473,

    BEASTMASTERY = 253,
    MARKSMANSHIP = 254,
    SURVIVAL = 255,

    ARCANE = 62,
    FIRE = 63,
    FROST_MAGE = 64,

    BREWMASTER = 268,
    MISTWEAVER = 270,
    WINDWALKER = 269,

    HOLY_PALADIN = 65,
    PROTECTION_PALADIN = 66,
    RETRIBUTION = 70,

    DISCIPLINE = 256,
    HOLY_PRIEST = 257,
    SHADOW = 258,

    ASSASSINATION = 259,
    OUTLAW = 260,
    SUBTLETY = 261,

    ELEMENTAL = 262,
    ENHANCEMENT = 263,
    RESTORATION_SHAMAN = 264,

    AFFLICTION = 265,
    DEMONOLOGY = 266,
    DESTRUCTION = 267,

    ARMS = 71,
    FURY = 72,
    PROTECTION_WARRIOR = 73,
};

-- Event name constants
addon.BAG_UPDATE = "BAG_UPDATE";
addon.LOSS_OF_CONTROL_ADDED = "LOSS_OF_CONTROL_ADDED";
addon.LOSS_OF_CONTROL_UPDATE = "LOSS_OF_CONTROL_UPDATE";
addon.PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD";
addon.ZONE_CHANGED_NEW_AREA = "ZONE_CHANGED_NEW_AREA";
addon.PLAYER_TARGET_CHANGED = "PLAYER_TARGET_CHANGED";
addon.PLAYER_FOCUS_CHANGED = "PLAYER_FOCUS_CHANGED";
addon.PLAYER_REGEN_ENABLED = "PLAYER_REGEN_ENABLED";
addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS = "ARENA_PREP_OPPONENT_SPECIALIZATIONS";
addon.ARENA_OPPONENT_UPDATE = "ARENA_OPPONENT_UPDATE";
addon.PVP_MATCH_STATE_CHANGED = "PVP_MATCH_STATE_CHANGED";
addon.PLAYER_SPECIALIZATION_CHANGED = "PLAYER_SPECIALIZATION_CHANGED";
addon.UNIT_SPELLCAST_SUCCEEDED = "UNIT_SPELLCAST_SUCCEEDED";
addon.UNIT_AURA = "UNIT_AURA";
addon.UNIT_TARGET = "UNIT_TARGET";
addon.UNIT_HEALTH = "UNIT_HEALTH";
addon.UNIT_MAXHEALTH = "UNIT_MAXHEALTH";
addon.UNIT_POWER_UPDATE = "UNIT_POWER_UPDATE";
addon.UNIT_POWER_FREQUENT = "UNIT_POWER_FREQUENT";
addon.UNIT_MAXPOWER = "UNIT_MAXPOWER";
addon.UNIT_PET = "UNIT_PET";
addon.UNIT_FLAGS = "UNIT_FLAGS";
addon.UPDATE_SHAPESHIFT_FORM = "UPDATE_SHAPESHIFT_FORM";
addon.COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED";
addon.GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE";
addon.NAME_PLATE_UNIT_ADDED = "NAME_PLATE_UNIT_ADDED";
addon.NAME_PLATE_UNIT_REMOVED = "NAME_PLATE_UNIT_REMOVED";
-- Sub event name constants
addon.SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS";
addon.SPELL_AURA_APPLIED = "SPELL_AURA_APPLIED";
addon.SPELL_AURA_REMOVED = "SPELL_AURA_REMOVED";
addon.SPELL_DAMAGE = "SPELL_DAMAGE";
addon.SPELL_CAST_START = "SPELL_CAST_START";
addon.SPELL_SUMMON = "SPELL_SUMMON";
addon.SPELL_EMPOWER_END = "SPELL_EMPOWER_END";
addon.PARTY_KILL = "PARTY_KILL";
addon.UNIT_DIED = "UNIT_DIED";
addon.UNIT_DESTROYED = "UNIT_DESTROYED";
addon.UNIT_DISSIPATES = "UNIT_DISSIPATES";
addon.SPELL_DISPEL = "SPELL_DISPEL";
addon.SPELL_INTERRUPT = "SPELL_INTERRUPT";
addon.SPELL_HEAL = "SPELL_HEAL";
addon.UPDATE_BATTLEFIELD_SCORE = "UPDATE_BATTLEFIELD_SCORE";
addon.UNIT_FACTION = "UNIT_FACTION";

addon.EVENTS_PET_DISMISS = {
    [addon.PARTY_KILL] = true,
    [addon.UNIT_DIED] = true,
    [addon.UNIT_DESTROYED] = true,
    [addon.UNIT_DISSIPATES] = true,
};

-- classFileName constants
addon.DEATHKNIGHT = "DEATHKNIGHT";
addon.DEMONHUNTER = "DEMONHUNTER";
addon.DRUID = "DRUID";
addon.EVOKER = "EVOKER";
addon.HUNTER = "HUNTER";
addon.MAGE = "MAGE";
addon.MONK = "MONK";
addon.PALADIN = "PALADIN";
addon.PRIEST = "PRIEST";
addon.ROGUE = "ROGUE";
addon.SHAMAN = "SHAMAN";
addon.WARLOCK = "WARLOCK";
addon.WARRIOR = "WARRIOR";

addon.CLASSID = {
    WARRIOR = 1,
    PALADIN = 2,
    HUNTER = 3,
    ROGUE = 4,
    PRIEST = 5,
    DEATHKNIGHT = 6,
    SHAMAN = 7,
    MAGE = 8,
    WARLOCK = 9,
    MONK = 10,
    DRUID = 11,
    DEMONHUNTER = 12,
    EVOKER = 13,
};

addon.CLASSORDER = {
    addon.CLASSID.DEATHKNIGHT,
    addon.CLASSID.DEMONHUNTER,
    addon.CLASSID.DRUID,
    addon.CLASSID.EVOKER,
    addon.CLASSID.HUNTER,
    addon.CLASSID.MAGE,
    addon.CLASSID.MONK,
    addon.CLASSID.PALADIN,
    addon.CLASSID.PRIEST,
    addon.CLASSID.ROGUE,
    addon.CLASSID.SHAMAN,
    addon.CLASSID.WARLOCK,
    addon.CLASSID.WARRIOR,
};

addon.DEFAULT_ICON_SIZE = 36;
addon.CHARGE_TEXTURE = "Crosshair_Recurring_32"; -- TODO: make it available for classic: https://github.com/seblindfors/WoWAtlasExtract/blob/master/README.md
addon.CHARGE_TEXTURE_SIZE = 16;

addon.RAID_FRAME_SORT_ORDER = {
    DISABLED = 0,
    PLAYER_TOP = 1,
    PLAYER_BOTTOM = 2,
    PLAYER_MID = 3,
};

addon.INTERFACE_SWEEPY = "interface/addons/SweepyBoop/";

addon.FLAG_CARRIER_HORDE_LOGO = addon.INTERFACE_SWEEPY .. "art/FlagCarrierHorde";
addon.FLAG_CARRIER_ALLIANCE_LOGO = addon.INTERFACE_SWEEPY .. "art/FlagCarrierAlliance";

addon.SPEC_ICON_HEALER_LOGO = addon.INTERFACE_SWEEPY .. "art/HealingTouch"; -- icon 136041
addon.SPEC_ICON_OTHERS_LOGO = addon.INTERFACE_SWEEPY .. "art/DeathMark"; -- icon 236270

addon.SPEC_ICON_ALIGNMENT = {
    TOP = 0,
    LEFT = 1,
    RIGHT = 2,
};

addon.FORMAT_TEXTURE = function (texture, customSize)
    local size = customSize or 20;
    return format("|T%s:" .. size .. "|t", texture);
end
addon.FORMAT_ATLAS = function (texture, customSize)
    local size = customSize or 20;
    return format("|A:%s:" .. size .. ":" .. size .. ":|a", texture);
end
addon.ICON_PATH = function (iconName)
    return "interface/icons/" .. iconName;
end

addon.EXCLAMATION = "|TInterface/OptionsFrame/UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t";

addon.ICON_ID_HEALER = "interface/lfgframe/uilfgprompts";
if addon.PROJECT_MAINLINE then
    addon.ICON_ID_HEALER_ENEMY = "Healing_Red";
    addon.SPEC_ICON_ENEMY_HEALER_LOGO = addon.FORMAT_ATLAS(addon.ICON_ID_HEALER_ENEMY);
else
    addon.ICON_ID_HEALER_ENEMY = "GreenCross";
    addon.SPEC_ICON_ENEMY_HEALER_LOGO = format("|A:%s:20:20:0:0:255:0:0|a", addon.ICON_ID_HEALER_ENEMY);
end
addon.ICON_ID_PET = addon.ICON_PATH("ability_hunter_mendpet");
addon.ICON_CRITTER = "WildBattlePet";
addon.ICON_ID_CLASSES = "Interface/GLUES/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES";
addon.ICON_ID_FLAG_CARRIER_HORDE = addon.ICON_PATH("inv_bannerpvp_01");
addon.ICON_ID_FLAG_CARRIER_ALLIANCE = addon.ICON_PATH("inv_bannerpvp_02");
addon.ICON_ID_FLAG_CARRIER_NEUTRAL = addon.ICON_PATH("inv_bannerpvp_03");
addon.ICON_ID_PVP_CURSOR = "interface/cursor/pvp";

-- https://warcraft.wiki.gg/wiki/UI_escape_sequences
addon.HELAER_LOGO = addon.FORMAT_ATLAS("UI-LFG-RoleIcon-Healer");

addon.ICON_COORDS_HEALER = {0.005, 0.116, 0.76, 0.87};

addon.CLASS_ICON_STYLE = {
    ICON = 0,
    ARROW = 1,
    ICON_AND_ARROW = 2,
};

addon.GetSpellTexture = function(spellId)
    local _, originalIconID = C_Spell.GetSpellTexture(spellId);
    return originalIconID;
end

addon.SPELL_DESCRIPTION = {}; -- by spellId, requested via -- https://warcraft.wiki.gg/wiki/SpellMixin

addon.PRINT = function(message)
    DEFAULT_CHAT_FRAME:AddMessage(addon.FORMAT_ATLAS("pvptalents-warmode-swords", 16) .. " |cff00c0ffSweepyBoop's PvP Helper:|r " .. message);
end
