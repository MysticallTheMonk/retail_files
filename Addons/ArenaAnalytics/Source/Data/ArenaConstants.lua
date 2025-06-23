local _, ArenaAnalytics = ...; -- Addon Namespace
local Constants = ArenaAnalytics.Constants;

-- Local module aliases
local Helpers = ArenaAnalytics.Helpers;
local Internal = ArenaAnalytics.Internal;

-------------------------------------------------------------------------

-- Text colors
Constants.titleColor = "ffffffff";
Constants.headerColor = "ffd0d0d0";
Constants.prefixColor = "FFAAAAAA";
Constants.statsColor = "ffffffff";
Constants.valueColor = nil; -- f5f5f5 for white?
Constants.infoColor = "ffbbbbbb";

-- Outcome colors
Constants.winColor = "ff00cc66";
Constants.lossColor = "ffff0000";
Constants.drawColor = "ffefef00";
Constants.invalidColor = "ff999999";

-- Faction colors
Constants.allianceColor = "FF009DEC";
Constants.hordeColor = "ffE00A05";

-------------------------------------------------------------------------

-- NOTE: Indices here affect save data
Constants.roleIndexes = { 
    -- Main roles
    { token = "tank", isMain = true, name = "Tank" },
    { token = "damager", isMain = true, name = "Dps" },
    { token = "healer", isMain = true, name = "Healer" },

    -- Sub roles
    { token = "caster", name = "Caster" },
    { token = "ranged", name = "Ranged" },
    { token = "melee", name = "Melee" },
}

Constants.playerFlags = {
    isFirstDeath = 1,
    isEnemy = 2,
    isSelf = 3,
}

-------------------------------------------------------------------------

-- Addon specific spec IDs { ID, "class|spec", "class", "spec", priority value } (ID must never change to preserve data validity, priority is a runtime check)
local addonSpecializationIDs = {
    -- Druid
    ["Druid"] = 0,
    ["Druid|Restoration"] = 1,
    ["Druid|Feral"] = 2,
    ["Druid|Balance"] = 3,
    
    -- Paladin
    ["Paladin"] = 10,
    ["Paladin|Holy"] = 11,
    ["Paladin|Protection"] = 12,
    ["Paladin|Preg"] = 13,
    ["Paladin|Retribution"] = 14,
    
    -- Shaman
    ["Shaman"] = 20,
    ["Shaman|Restoration"] = 21,
    ["Shaman|Elemental"] = 22,
    ["Shaman|Enhancement"] = 23,

    -- Death Knight
    ["Death Knight"] = 30,
    ["Death Knight|Unholy"] = 31,
    ["Death Knight|Frost"] = 32,
    ["Death Knight|Blood"] = 33,

    -- Hunter
    ["Hunter"] = 40,
    ["Hunter|Beast Mastery"] = 41,
    ["Hunter|Marksmanship"] = 42,
    ["Hunter|Survival"] = 43,

    -- Mage
    ["Mage"] = 50,
    ["Mage|Frost"] = 51,
    ["Mage|Fire"] = 52,
    ["Mage|Arcane"] = 53,

    -- Rogue
    ["Rogue"] = 60,
    ["Rogue|Subtlety"] = 61,
    ["Rogue|Assassination"] = 62,
    ["Rogue|Combat"] = 63,
    ["Rogue|Outlaw"] = 64,

    -- Warlock
    ["Warlock"] = 70,
    ["Warlock|Affliction"] = 71,
    ["Warlock|Destruction"] = 72,
    ["Warlock|Demonology"] = 73,

    -- Warrior
    ["Warrior"] = 80,
    ["Warrior|Protection"] = 81,
    ["Warrior|Arms"] = 82,
    ["Warrior|Fury"] = 83,
    
    -- Priest
    ["Priest"] = 90,
    ["Priest|Discipline"] = 91,
    ["Priest|Holy"] = 92,
    ["Priest|Shadow"] = 93,
}
function Constants:getAddonSpecializationID(class, spec, forceExactSpec)
    if(class == nil) then 
        return nil;
    end

    if(forceExactSpec and spec == nil) then
        return nil;
    end

    local specKey = spec and (class .. "|" .. spec) or class;
    return tonumber(addonSpecializationIDs[specKey]);
end

local raceToFaction = {
    -- Horde Races
    ["Orc"] = "Horde",
    ["Undead"] = "Horde",
    ["Tauren"] = "Horde",
    ["Troll"] = "Horde",
    ["Blood Elf"] = "Horde",
    ["Goblin"] = "Horde",
    ["Nightborne"] = "Horde",
    ["Highmountain Tauren"] = "Horde",
    ["Mag'har Orc"] = "Horde",
    ["Vulpera"] = "Horde",
    ["Zandalari Troll"] = "Horde",

    -- Alliance Races
    ["Human"] = "Alliance",
    ["Dwarf"] = "Alliance",
    ["Night Elf"] = "Alliance",
    ["Gnome"] = "Alliance",
    ["Draenei"] = "Alliance",
    ["Worgen"] = "Alliance",
    ["Void Elf"] = "Alliance",
    ["Lightforged Draenei"] = "Alliance",
    ["Dark Iron Dwarf"] = "Alliance",
    ["Kul Tiran"] = "Alliance",
    ["Mechagnome"] = "Alliance",

    -- Neutral Races
    ["Pandaren"] = "Neutral",
    ["Dracthyr"] = "Neutral"
}

function Constants:GetFactionByRace(race)
    return race and raceToFaction[race] or nil;
end

local matchStartedMessages = {
    "The Arena battle has begun!", -- English / Default
    "¡La batalla en arena ha comenzado!", -- esES / esMX
    "A batalha na Arena começou!", -- ptBR
    "Der Arenakampf hat begonnen!", -- deDE
    "Le combat d'arène commence\194\160!", -- frFR
    "Бой начался!", -- ruRU
    "투기장 전투가 시작되었습니다!", -- koKR
    "竞技场战斗开始了！", -- zhCN
    "竞技场的战斗开始了！", -- zhCN (Wotlk)
    "競技場戰鬥開始了！", -- zhTW (Unconfirmed, classic?)
};

function Constants:IsMatchStartedMessage(msg)
    if(not msg) then
        return nil;
    end

    for i,message in ipairs(matchStartedMessages) do
        if(msg:find(message, 1, true)) then
            return true;
        end
    end

    return false;
end

local specIconTable = {
        -- Druid
        [1] = [[Interface\Icons\spell_nature_healingtouch]],
        [2] = [[Interface\Icons\ability_druid_catform]],
        [3] = [[Interface\Icons\spell_nature_starfall]],
        [4] = [[Interface\Icons\ability_racial_bearform]],
    
        -- Paladin
        [11] = [[Interface\Icons\spell_holy_holybolt]],
        [12] = [[Interface\Icons\spell_holy_devotionaura]],
        [13] = [[Interface\Icons\ability_paladin_hammeroftherighteous]],
        [14] = [[Interface\Icons\spell_holy_auraoflight]],
    
        -- Shaman
        [21] = [[Interface\Icons\spell_nature_magicimmunity]],
        [22] = [[Interface\Icons\spell_nature_lightning]],
        [23] = [[Interface\Icons\spell_nature_lightningshield]],
    
        -- Death Knight
        [31] = [[Interface\Icons\spell_deathknight_unholypresence]],
        [32] = [[Interface\Icons\spell_deathknight_frostpresence]],
        [33] = [[Interface\Icons\spell_deathknight_bloodpresence]],
    
        -- Hunter
        [41] = [[Interface\Icons\ability_hunter_beasttaming]],
        [42] = [[Interface\Icons\ability_marksmanship]],
        [43] = [[Interface\Icons\ability_hunter_swiftstrike]],
    
        -- Mage
        [51] = [[Interface\Icons\spell_frost_frostbolt02]],
        [52] = [[Interface\Icons\spell_fire_firebolt02]],
        [53] = [[Interface\Icons\spell_holy_magicalsentry]],
    
        -- Rogue
        [61] = [[Interface\Icons\ability_stealth]],
        [62] = [[Interface\Icons\ability_rogue_eviscerate]],
        [63] = [[Interface\Icons\ability_backstab]],
        [64] = [[Interface\Icons\ability_rogue_waylay]], -- Outlaw
    
        -- Warlock
        [71] = [[Interface\Icons\spell_shadow_deathcoil]], -- Affliction
        [72] = [[Interface\Icons\spell_shadow_rainoffire]], -- Destruction
        [73] = [[Interface\Icons\spell_shadow_metamorphosis]], -- Demonology
    
        -- Warrior
        [81] = [[Interface\Icons\inv_shield_06]], -- Protection
        [82] = [[Interface\Icons\ability_rogue_eviscerate]], -- Arms
        [83] = [[Interface\Icons\ability_warrior_innerrage]], -- Fury
    
        -- Priest
        [91] = [[Interface\Icons\spell_holy_wordfortitude]], -- Disc
        [92] = [[Interface\Icons\spell_holy_guardianspirit]], -- Holy
        [93] = [[Interface\Icons\spell_shadow_shadowwordpain]], -- Shadow
    
        -- Monk
        [101] = [[Interface\Icons\Spell_monk_mistweaver_spec]], -- Mistweaver
        [102] = [[Interface\Icons\spell_monk_brewmaster_spec]], -- Brewmaster
        [103] = [[Interface\Icons\spell_monk_windwalker_spec]], -- Windwalker
    
        -- Demon Hunter
        [111] = [[Interface\Icons\ability_demonhunter_spectank]], -- Vengeance
        [112] = [[Interface\Icons\ability_demonhunter_specdps]], -- Havoc
    
        -- Evoker
        [121] = [[Interface\Icons\classicon_evoker_preservation]], -- Preservation
        [122] = [[Interface\Icons\classicon_evoker_augmentation]], -- Augmentation
        [123] = [[Interface\Icons\classicon_evoker_devastation]], -- Devastation
}

-- Returns spec icon path string
function Constants:GetBaseSpecIcon(spec_id)
    if(not spec_id or Helpers:IsClassID(spec_id)) then
        return "";
    end

    return specIconTable[spec_id] or 134400;
end

function ArenaAnalytics:getBracketFromTeamSize(teamSize)
    if(teamSize == 2) then
        return "2v2";
    elseif(teamSize == 3) then
        return "3v3";
    end
    return "5v5";
end

function ArenaAnalytics:getBracketIdFromTeamSize(teamSize)
    if(teamSize == 2) then
        return 1;
    elseif(teamSize == 3) then
        return 2;
    end
    return 3;
end

local bracketTeamSizes = { 2, 3, 5, 3 };
function ArenaAnalytics:getTeamSizeFromBracketIndex(bracketIndex)
    bracketIndex = tonumber(bracketIndex);
    return bracketIndex and bracketTeamSizes[bracketIndex];
end

function ArenaAnalytics:getTeamSizeFromBracketId(bracketId)
    if(bracketId == 1) then
        return 2;
    elseif(bracketId == 2) then
        return 3;
    end
    return 5
end

function ArenaAnalytics:getTeamSizeFromBracket(bracket)
    if(bracket == "2v2") then
        return 2;
    elseif(bracket == "3v3") then
        return 3;
    end
    return 5;
end