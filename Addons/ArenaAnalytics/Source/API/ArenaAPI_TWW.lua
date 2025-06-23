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

API.defaultButtonTemplate = "UIPanelButtonTemplate";
API.showPerPlayerRatedInfo = true;
API.useThirdTooltipBackdrop = true;
API.enableInspection = true;

-- Order defines the UI order of maps bracket dropdown
API.availableBrackets = {
    { name = "Solo", key = 4},
	{ name = "2v2", key = 1},
	{ name = "3v3", key = 2},
	{ name = "5v5", key = 3, requireMatches = true },    -- TODO: Implement requireMatches logic
};

-- Order defines the UI order of maps filter dropdown
API.availableMaps = {
    "NagrandArena",
    "RuinsOfLordaeron",
    "TheRobodrome",
    "NokhudonProvingGrounds",
    "AshamanesFall",
    "BladesEdgeArena",
    "Mugambala",
    "BlackRookHoldArena",
    "HookPoint",
    "EmpyreanDomain",
    "DalaranArena",
    "TigersPeak",
    "EnigmaCrucible",
    "MaldraxxusColiseum",
    "TolVironArena",
    "CageOfCarnage",
};

function API:IsInArena()
    return IsActiveBattlefieldArena() and not C_PvP.IsInBrawl();
end

function API:IsRatedArena()
    return API:IsInArena() and (C_PvP.IsRatedArena() or C_PvP.IsRatedSoloShuffle()) and not IsWargame() and not IsArenaSkirmish() and not C_PvP.IsInBrawl();
end

function API:GetBattlefieldStatus(battlefieldId)
    if(not battlefieldId) then
        ArenaAnalytics:LogError("API:GetBattlefieldStatus called with invalid battlefieldId.");
        return nil;
    end

    local status, _, teamSize = GetBattlefieldStatus(battlefieldId);
    local isRated = API:IsRatedArena();
    local isShuffle = API:IsSoloShuffle();

    local bracket = nil;
    if(isShuffle) then
        teamSize = 3;
        bracket = 4;
    elseif(teamSize == 2) then
        bracket = 1;
    elseif(teamSize == 3) then
        bracket = 2;
    elseif(teamSize == 5) then
        bracket = 3;
    end

    return status, bracket, teamSize, isRated, isShuffle;
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
        bracketIndex = 7;
    end

    local rating,_,_,seasonPlayed = GetPersonalRatedInfo(bracketIndex);
    return rating, seasonPlayed;
end

function API:GetPlayerScore(index)
    local scoreInfo = C_PvP.GetScoreInfo(index);

    local score = TablePool:Acquire();
    if(not scoreInfo) then
        return score;
    end

    local spec_id = Localization:GetSpecID(scoreInfo.classToken, scoreInfo.talentSpec);
    if(not spec_id) then
        spec_id = Internal:GetAddonClassID(scoreInfo.classToken);
    end

    score.name = Helpers:ToFullName(scoreInfo.name);
    score.race = Localization:GetRaceID(scoreInfo.raceName);
    score.spec = spec_id;
    score.team = scoreInfo.faction;
    score.kills = scoreInfo.killingBlows;
    score.deaths = scoreInfo.deaths;
    score.damage = scoreInfo.damageDone;
    score.healing = scoreInfo.healingDone;
    score.rating = scoreInfo.rating;
    score.ratingDelta = scoreInfo.ratingChange;

    if(API:IsSoloShuffle()) then
        -- Assume shuffle only has one stat (ID changes randomly)
        local firstStat = scoreInfo.stats and scoreInfo.stats[1];
        if(firstStat) then
            score.wins = firstStat.pvpStatValue;
        end
    end

    -- MMR
    local oldMMR = tonumber(scoreInfo.prematchMMR);
    local newMMR = tonumber(scoreInfo.postmatchMMR);
    if(oldMMR and oldMMR > 0) then
        score.mmr = oldMMR;

        if(newMMR and newMMR > 0) then
            score.mmrDelta = newMMR - oldMMR;
        end
    end

    return score;
end

function API:GetSpecialization(unitToken, explicit)
    if(explicit and not unitToken) then
        return nil;
    end

    unitToken = unitToken or "player";
    if(not UnitExists(unitToken)) then
        return nil;
    end

    if(UnitGUID(unitToken) == UnitGUID("player")) then
        local currentSpec = GetSpecialization();
		if(currentSpec == 5) then
			return nil;
		end

        local id = currentSpec and GetSpecializationInfo(currentSpec);
        return API:GetMappedAddonSpecID(id);
    end

    local specID = GetInspectSpecialization(unitToken);
    return API:GetMappedAddonSpecID(specID);
end

function API:GetPlayerInfoByGUID(GUID)
    local _,class,_,race,_,name,realm = GetPlayerInfoByGUID(GUID);
    return class,race,name,realm;
end

API.maxRaceID = 70;

-- Internal Addon Spec ID to expansion spec IDs
API.specMappingTable = {
    [105] = 1, -- Restoration Druid
    [103] = 2, -- Feral Druid
    [102] = 3, -- Balance Druid
    [104] = 4, -- Guardian Druid

    [65] = 11, -- Holy Paladin
    [66] = 12, -- Protection Paladin
    [70] = 14, -- Retribution Paladin

    [264] = 21, -- Restoration Shaman
    [262] = 22, -- Elemental Shaman
    [263] = 23, -- Enhancement Shaman

    [252] = 31, -- Unholy Death Knight
    [251] = 32, -- Frost Death Knight
    [250] = 33, -- Blood Death Knight

    [253] = 41, -- Beast Mastery Hunter
    [254] = 42, -- Marksmanship Hunter
    [255] = 43, -- Survival Hunter

    [64] = 51, -- Frost Mage
    [63] = 52, -- Fire Mage
    [62] = 53, -- Arcane Mage

    [261] = 61, -- Subtlety Rogue
    [259] = 62, -- Assassination Rogue
    [260] = 64, -- Outlaw Rogue

    [265] = 71, -- Affliction Warlock
    [267] = 72, -- Destruction Warlock
    [266] = 73, -- Demonology Warlock

    [73] = 81, -- Protection Warrior
    [71] = 82, -- Arms Warrior
    [72] = 83, -- Fury Warrior

    [256] = 91, -- Discipline Priest
    [257] = 92, -- Holy Priest
    [258] = 93, -- Shadow Priest

    [270] = 101, -- Mistweaver Monk
    [268] = 102, -- Brewmaster Monk
    [269] = 103, -- Windwalker Monk

    [581] = 111, -- Vengeance Demon Hunter
    [577] = 112, -- Havoc Demon Hunter

    [1468] = 121, -- Preservation Evoker
    [1473] = 122, -- Augmentation Evoker
    [1467] = 123, -- Devastation Evoker
};

-------------------------------------------------------------------------
-- Overrides

API.roleBitmapOverrides = nil;
local function InitializeRoleBitmapOverrides()
    API.roleBitmapOverrides = {
        [43] = Bitmap.roles.melee_damager, -- Survival hunter
    };
end

API.specIconOverrides = nil;
local function InitializeSpecOverrides()
    API.specIconOverrides = {
        -- Paladin
        [12] = [[Interface\Icons\spell_holy_devotionaura]], -- Protection

        -- Shaman
        [23] = [[Interface\Icons\spell_shaman_improvedstormstrike]], -- Enhancement

        -- Hunter
        [41] = [[Interface\Icons\ability_hunter_bestialdiscipline]], -- Beast Mastery
        [42] = [[Interface\Icons\ability_hunter_focusedaim]], -- Marksmanship
        [43] = [[Interface\Icons\ability_hunter_camouflage]], -- Survival

        -- Rogue
        [62] = [[Interface\Icons\Ability_rogue_deadlybrew]], -- Assassination

        -- Warrior
        [82] = [[Interface\Icons\ability_warrior_savageblow]], -- Arms
    };
end

-------------------------------------------------------------------------
-- Expansion API initializer

function API:InitializeExpansion()
    InitializeRoleBitmapOverrides();
    InitializeSpecOverrides();
end