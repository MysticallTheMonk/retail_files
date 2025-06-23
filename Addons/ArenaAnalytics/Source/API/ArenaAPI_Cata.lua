-- API adjusted functions to let calling code stay version agnostic.
local _, ArenaAnalytics = ...; -- Addon Namespace
local API = ArenaAnalytics.API;

-- Local module aliases
local Helpers = ArenaAnalytics.Helpers;
local Localization = ArenaAnalytics.Localization;
local Internal = ArenaAnalytics.Internal;
local Bitmap = ArenaAnalytics.Bitmap;

-------------------------------------------------------------------------

API.defaultButtonTemplate = "UIServiceButtonTemplate";

API.availableBrackets = {
	{ name = "2v2", key = 1},
	{ name = "3v3", key = 2},
	{ name = "5v5", key = 3},
};

API.availableMaps = {
    "BladesEdgeArena",
    "NagrandArena",
    "RuinsOfLordaeron",
    "DalaranArena",
};

function API:IsInArena()
    return IsActiveBattlefieldArena();
end

function API:IsRatedArena()
    return API:IsInArena() and not IsWargame() and not IsArenaSkirmish();
end

function API:GetBattlefieldStatus(battlefieldId)
    if(not battlefieldId) then
        ArenaAnalytics:LogError("API:GetBattlefieldStatus called with invalid battlefieldId.");
        return nil;
    end

    local status, _, _, _, _, teamSize, isRated = GetBattlefieldStatus(battlefieldId);

    local bracket = nil;
    if(teamSize == 2) then
        bracket = 1;
    elseif(teamSize == 3) then
        bracket = 2;
    elseif(teamSize == 5) then
        bracket = 3;
    end

    return status, bracket, teamSize, isRated;
end

function API:GetTeamMMR(teamIndex)
    local _,_,_,mmr = GetBattlefieldTeamInfo(teamIndex);
    return tonumber(mmr);
end

function API:GetPersonalRatedInfo(bracketIndex)
    bracketIndex = tonumber(bracketIndex);
    if(not bracketIndex) then
        return nil;
    end

    -- Solo Shuffle
    if(bracketIndex == 4) then
        return nil; -- NYI
    end

    local rating,_,_,seasonPlayed = GetPersonalRatedInfo(bracketIndex);
    return rating, seasonPlayed;
end

function API:GetPlayerScore(index)
    local name, kills, _, deaths, _, teamIndex, _, race, _, classToken, damage, healing = GetBattlefieldScore(index);
    name = Helpers:ToFullName(name);

    -- Convert values
    local race_id = Localization:GetRaceID(race);
    local class_id = Internal:GetAddonClassID(classToken);

    local score = {
        name = name,
        race = race_id,
        spec = class_id,
        team = teamIndex,
        kills = kills,
        deaths = deaths,
        damage = damage,
        healing = healing,
    };

    return score;
end

local function getPointsSpent(index, isInspect)
    if(isInspect) then
        local id, name, _, _, pointsSpent = GetTalentTabInfo(index, true);
        return tonumber(id), tonumber(pointsSpent), name;
    end

    local id, name, _, _, pointsSpent = GetTalentTabInfo(index);
    return tonumber(id), tonumber(pointsSpent), name;
end

function API:GetSpecialization(unitToken, explicit)
    if(explicit and not unitToken) then
        return nil;
    end

    unitToken = unitToken or "player";
    if(not UnitExists(unitToken)) then
        return nil;
    end

    local isInspect = (UnitGUID(unitToken) ~= UnitGUID("player"));

    local spec, currentSpecPoints = nil, 0;
    for i = 1, 3 do
        local id, pointsSpent = getPointsSpent(i, isInspect);

		if (id and pointsSpent) then
            local spec_id = API:GetMappedAddonSpecID(id);
            if(not spec_id) then
                local _,classToken = UnitClass(unitToken);
                ArenaAnalytics:LogError("API:GetSpecialization failed to retrieve internal spec ID for:", id, classToken, i);
            end

            if(pointsSpent > currentSpecPoints) then
                currentSpecPoints = pointsSpent;
                spec = spec_id;
            end
		end
 	end

    return spec;
end

function API:GetPlayerInfoByGUID(GUID)
    local _,class,_,race,_,name,realm = GetPlayerInfoByGUID(GUID);
    return class,race,name,realm;
end

API.maxRaceID = 70;

-- Internal Addon Spec ID to expansion spec IDs
API.specMappingTable = {
    [748] = 1, -- Restoration Druid
    [750] = 2, -- Feral Druid
    [752] = 3, -- Balance Druid

    [831] = 11, -- Holy Paladin
    [839] = 12, -- Protection Paladin
    [855] = 14, -- Retribution Paladin

    [262] = 21, -- Restoration Shaman
    [261] = 22, -- Elemental Shaman
    [263] = 23, -- Enhancement Shaman

    [400] = 31, -- Unholy Death Knight
    [399] = 32, -- Frost Death Knight
    [398] = 33, -- Blood Death Knight

    [811] = 41, -- Beast Mastery Hunter
    [807] = 42, -- Marksmanship Hunter
    [809] = 43, -- Survival Hunter

    [823] = 51, -- Frost Mage
    [851] = 52, -- Fire Mage
    [799] = 53, -- Arcane Mage

    [183] = 61, -- Subtlety Rogue
    [182] = 62, -- Assassination Rogue
    [181] = 63, -- Combat Rogue

    [871] = 71, -- Affliction Warlock
    [865] = 72, -- Destruction Warlock
    [867] = 73, -- Demonology Warlock

    [845] = 81, -- Protection Warrior
    [746] = 82, -- Arms Warrior
    [815] = 83, -- Fury Warrior

    [760] = 91, -- Discipline Priest
    [813] = 92, -- Holy Priest
    [795] = 93, -- Shadow Priest
};

-------------------------------------------------------------------------
-- Overrides

API.roleBitmapOverrides = nil;
local function InitializeRoleBitmapOverrides()
    API.roleBitmapOverrides = {
        [43] = Bitmap.roles.ranged_damager, -- Survival hunter
    }
end

API.specIconOverrides = nil;
local function InitializeSpecOverrides()
    API.specIconOverrides = {
        -- Paladin
        [12] = [[Interface\Icons\spell_holy_devotionaura]], -- Protection

        -- Hunter
        [41] = [[Interface\Icons\ability_hunter_bestialdiscipline]], -- Beast Mastery
        [42] = [[Interface\Icons\ability_hunter_focusedaim]], -- Marksmanship
        [43] = [[Interface\Icons\ability_hunter_camouflage]], -- Survival

        -- Warrior
        [82] = [[Interface\Icons\ability_warrior_savageblow]], -- Arms
    }
end

-------------------------------------------------------------------------
-- Expansion API initializer

function API:InitializeExpansion()
    InitializeRoleBitmapOverrides();
    InitializeSpecOverrides();
end