-- API adjusted functions to let calling code stay version agnostic.
local _, ArenaAnalytics = ...; -- Addon Namespace
local API = ArenaAnalytics.API;

-- Local module aliases
local Helpers = ArenaAnalytics.Helpers;
local Localization = ArenaAnalytics.Localization;
local Internal = ArenaAnalytics.Internal;
local Bitmap = ArenaAnalytics.Bitmap;
local TablePool = ArenaAnalytics.TablePool;

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
    return API:IsInArena() and C_PvP.IsRatedArena() and not IsWargame() and not IsArenaSkirmish() and not C_PvP.IsInBrawl();
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

--[[
local specByIndex = {
    ["DRUID"] = { 3, 2, 1 }, -- Balance, Feral, Resto
    ["PALADIN"] = { 11, 12, 14 }, -- Holy, Prot, Ret
    ["SHAMAN"] = { 22, 23, 21 }, -- Ele, Enh, Resto
    ["DEATHKNIGHT"] = { 33, 32, 31 }, -- Blood, Frost, Unholy
    ["HUNTER"] = { 41, 42, 43 }, -- BM, MM, Surv
    ["MAGE"] = { 53, 52, 51 }, -- Arcane, Fire, Frost
    ["ROGUE"] = { 62, 63, 61 }, -- Assa, Combat, Sub
    ["WARLOCK"] = { 71, 73, 72 }, -- Affli, Demo, Destro
    ["WARRIOR"] = { 82, 83, 81 }, -- Arms, Fury, Prot
    ["PRIEST"] = { 91, 92, 93 }, -- Disc, Holy, Shadow
};
--]]

local function getPointsSpent(index, isInspect)
    if(isInspect) then
        local id, name, _, _, pointsSpent = GetTalentTabInfo(index, true);
        return tonumber(id), tonumber(pointsSpent), name;
    end

    local id, name, _, _, pointsSpent = GetTalentTabInfo(index);
    return tonumber(id), tonumber(pointsSpent), name;
end

local function checkPlausiblePreg(spec_id, pointsSpent)
    if(pointsSpent > 45) then
        return false; -- No spec has more than 45 points for Preg.
    elseif(spec_id == 11) then -- Holy
        if(pointsSpent > 10) then -- Max 10 holy points for preg (0 is expected)
            return false;
        end
    elseif(spec_id == 12) then -- Protection
        if(pointsSpent < 15 or pointsSpent > 30) then -- Max 30 protection points for preg (28 expected)
            return false;
        end
    elseif(spec_id == 14) then -- Retribution
        if(pointsSpent < 15 or pointsSpent > 45) then -- Max 45 retribution points for preg (43 expected)
            return false;
        end
    end

    -- No change to plausibility proven
    return true;
end

-- Get local player current spec
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
    local isPlausiblePreg = true;

    -- Determine spec
    local _,classToken = UnitClass(unitToken);
    if(not classToken) then
        ArenaAnalytics:LogWarning("API:GetSpecialization failed to retrieve class token. unitToken:", unitToken);
        return nil;
    end

    if(classToken ~= "PALADIN") then
        -- Not paladin, cannot be preg.
        isPlausiblePreg = false;
    end

    for i = 1, 3 do
        local id, pointsSpent = getPointsSpent(i, isInspect);

		if (id and pointsSpent) then
            local spec_id = API:GetMappedAddonSpecID(id);
            if(not spec_id) then
                ArenaAnalytics:LogError("API:GetSpecialization failed to retrieve internal spec ID for:", id, classToken, i);
            end

            -- Update plausible preg flag
            isPlausiblePreg = isPlausiblePreg and checkPlausiblePreg(spec_id, pointsSpent);

            if(pointsSpent > currentSpecPoints) then
                currentSpecPoints = pointsSpent;
                spec = spec_id;
            end
        end
 	end

    if(spec and isPlausiblePreg) then
        spec = 13;
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
    [282] = 1, -- Restoration Druid
    [281] = 2, -- Feral Druid
    [283] = 3, -- Balance Druid

    [382] = 11, -- Holy Paladin
    [383] = 12, -- Protection Paladin
    [381] = 14, -- Retribution Paladin

    [262] = 21, -- Restoration Shaman
    [261] = 22, -- Elemental Shaman
    [263] = 23, -- Enhancement Shaman

    [400] = 31, -- Unholy Death Knight
    [399] = 32, -- Frost Death Knight
    [398] = 33, -- Blood Death Knight

    [361] = 41, -- Beast Mastery Hunter
    [363] = 42, -- Marksmanship Hunter
    [362] = 43, -- Survival Hunter

    [61] = 51, -- Frost Mage
    [41] = 52, -- Fire Mage
    [81] = 53, -- Arcane Mage

    [183] = 61, -- Subtlety Rogue
    [182] = 62, -- Assassination Rogue
    [181] = 63, -- Combat Rogue

    [302] = 71, -- Affliction Warlock
    [301] = 72, -- Destruction Warlock
    [303] = 73, -- Demonology Warlock

    [163] = 81, -- Protection Warrior
    [161] = 82, -- Arms Warrior
    [164] = 83, -- Fury Warrior

    [201] = 91, -- Discipline Priest
    [202] = 92, -- Holy Priest
    [203] = 93, -- Shadow Priest
};

-------------------------------------------------------------------------
-- Overrides

API.roleBitmapOverrides = nil;
local function InitializeRoleBitmapOverrides()
    API.roleBitmapOverrides = {
        [43] = Bitmap.roles.ranged_damager, -- Survival hunter
    };
end

-------------------------------------------------------------------------
-- Expansion API initializer

function API:InitializeExpansion()
    InitializeRoleBitmapOverrides();
end