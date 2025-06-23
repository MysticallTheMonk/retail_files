local _, ArenaAnalytics = ...; -- Addon Namespace
local GroupSorter = ArenaAnalytics.GroupSorter;

-- Local module aliases
local Helpers = ArenaAnalytics.Helpers;
local Constants = ArenaAnalytics.Constants;
local Internal = ArenaAnalytics.Internal;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local TablePool = ArenaAnalytics.TablePool;
local Bitmap = ArenaAnalytics.Bitmap;

-------------------------------------------------------------------------

local specPriorities = {
    -- Druid
    1,  -- Restoration Druid (Healer)
    3,  -- Balance Druid (Caster DPS)
    2,  -- Feral Druid (Melee DPS)

    -- Warlock
    71, -- Affliction Warlock (Caster DPS)
    72, -- Destruction Warlock (Caster DPS)
    73, -- Demonology Warlock (Caster DPS)

    -- Mage
    52, -- Fire Mage (Caster DPS)
    53, -- Arcane Mage (Caster DPS)
    51, -- Frost Mage (Caster DPS)

    -- Priest
    91, -- Discipline Priest (Caster Healer)
    92, -- Holy Priest (Caster Healer)
    93, -- Shadow Priest (Caster DPS)

    -- Shaman
    21, -- Restoration Shaman (Caster Healer)
    22, -- Elemental Shaman (Caster DPS)
    23, -- Enhancement Shaman (Melee DPS)

    -- Evoker
    121,-- Preservation Evoker (Caster Healer)
    122,-- Augmentation Evoker (Caster DPS)
    123,-- Devastation Evoker (Caster DPS)

    -- Hunter
    41, -- Beast Mastery Hunter (Ranged DPS)
    42, -- Marksmanship Hunter (Ranged DPS)
    43, -- Survival Hunter (Melee DPS)

    -- Paladin
    11, -- Holy Paladin (Melee Healer)
    12, -- Protection Paladin (Melee Tank)
    13, -- Preg Paladin (Melee DPS)
    14, -- Retribution Paladin (Melee DPS)

    -- Death Knight
    33, -- Blood Death Knight (Melee Tank)
    31, -- Unholy Death Knight (Melee DPS)
    32, -- Frost Death Knight (Melee DPS)

    -- Rogue
    61, -- Subtlety Rogue (Melee DPS)
    62, -- Assassination Rogue (Melee DPS)
    63, -- Combat Rogue (Melee DPS)
    64, -- Outlaw Rogue (Melee DPS)

    -- Monk
    101,-- Mistweaver Monk (Healer)
    102,-- Brewmaster Monk (Melee Tank)
    103,-- Windwalker Monk (Melee DPS)

    -- Demon Hunter
    111,-- Vengeance Demon Hunter (Melee Tank)
    112,-- Havoc Demon Hunter (Melee DPS)

    -- Warrior
    81, -- Protection Warrior (Melee Tank)
    82, -- Arms Warrior (Melee DPS)
    83, -- Fury Warrior (Melee DPS)

    -- Class-only IDs
    0,   -- Druid
    70,  -- Warlock
    50,  -- Mage
    90,  -- Priest
    20,  -- Shaman
    120, -- Evoker
    40,  -- Hunter
    10,  -- Paladin
    30,  -- Death Knight
    60,  -- Rogue
    100, -- Monk
    110, -- Demon Hunter
    80,  -- Warrior
}

function GroupSorter:GetSpecPriority(spec_id)
    if(spec_id) then
        for i,specID in ipairs(specPriorities) do
            if(specID == spec_id) then
                return i;
            end
        end
    end
    return 10000;
end

-------------------------------------------------------------------------

local function ComparePlayersToSelf(playerInfoA, playerInfoB, selfPlayerInfo)
    if(not selfPlayerInfo) then
        return nil;
    end

    -- Name Comparison
    if(selfPlayerInfo.fullName and playerInfoA.fullName ~= playerInfoB.fullName) then
        if(playerInfoA.fullName == selfPlayerInfo.fullName) then
            return true;
        elseif(playerInfoB.fullName == selfPlayerInfo.fullName) then
            return false;
        end
    end

    -- Main Role Comparison
    if(selfPlayerInfo.role_main and playerInfoA.role_main ~= playerInfoB.role_main) then
        local matchedA = playerInfoA.role_main == selfPlayerInfo.role_main;
        local matchedB = playerInfoB.role_main == selfPlayerInfo.role_main;

        if(matchedA ~= matchedB) then
            return matchedA;
        end
    end

    -- Main Role Comparison
    if(selfPlayerInfo.role_sub and playerInfoA.role_sub ~= playerInfoB.role_sub) then
        local matchedA = playerInfoA.role_sub == selfPlayerInfo.role_sub;
        local matchedB = playerInfoB.role_sub == selfPlayerInfo.role_sub;

        if(matchedA ~= matchedB) then
            return matchedA;
        end
    end

    -- Spec and Class Comparison
    if(selfPlayerInfo.spec and playerInfoA.spec ~= playerInfoB.spec) then
        if(playerInfoA.spec == selfPlayerInfo.spec) then
            return true;
        elseif(playerInfoB.spec == selfPlayerInfo.spec) then
            return false;
        end

        local classA = Helpers:GetClassID(playerInfoA.spec);
        local classB = Helpers:GetClassID(playerInfoB.spec);

        if(classA ~= classB) then
            local selfClassID = Helpers:GetClassID(selfPlayerInfo.spec);

            if(classA == selfClassID) then
                return true;
            elseif(classB == selfClassID) then
                return false;
            end
        end
    end

    -- If both matched equally, return nil to indicate no decision
    return nil;
end

local function ComparePlayers(playerInfoA, playerInfoB, selfPlayerInfo)
    -- Missing info has no priority, assume the other 
    if(not playerInfoB) then
        return true;
    elseif(not playerInfoA) then
        return false;
    end

    -- Prioritize self
    local selfComparisonResult = ComparePlayersToSelf(playerInfoA, playerInfoB, selfPlayerInfo);
    if(selfComparisonResult ~= nil) then
        return selfComparisonResult;
    end

    local specPriorityA = GroupSorter:GetSpecPriority(playerInfoA.spec);
    local specPriorityB = GroupSorter:GetSpecPriority(playerInfoB.spec);
    if(specPriorityA ~= specPriorityB) then
        return specPriorityA < specPriorityB;
    end

    return playerInfoA.fullName and playerInfoA.fullName < playerInfoB.fullName;
end

function GroupSorter:SortGroup(group, selfPlayerInfo)
    if(not group or #group == 0) then
		return;
	end

    table.sort(group, function(playerA, playerB)
        local playerInfoA = ArenaMatch:GetPlayerInfo(playerA);
        local playerInfoB = ArenaMatch:GetPlayerInfo(playerB);

        local result = ComparePlayers(playerInfoA, playerInfoB, selfPlayerInfo);

        TablePool:Release(playerInfoA);
        TablePool:Release(playerInfoB);

        return result;
    end);
end

function GroupSorter:SortIndexGroup(group, players, selfPlayerInfo)
    if(not group or #group == 0) then
        ArenaAnalytics:Log("SortIndexGroup got invalid group.")
        return;
    end

    -- Requires players table to process indices
    if(not players or #players == 0) then
        ArenaAnalytics:Log("SortIndexGroup got invalid players table")
        return;
    end

    table.sort(group, function(indexA, indexB)
        indexA = tonumber(indexA);
        indexB = tonumber(indexB);

        local playerInfoA, playerInfoB;

        -- 0 is always self
        if(indexA == 0) then
            return true;
        elseif(indexB == 0) then
            return false;
        end

        local playerInfoA = indexA and ArenaMatch:GetPlayerInfo(players[indexA]);
        local playerInfoB = indexB and ArenaMatch:GetPlayerInfo(players[indexB]);

        local result = ComparePlayers(playerInfoA, playerInfoB, selfPlayerInfo);

        TablePool:Release(playerInfoA);
        TablePool:Release(playerInfoB);

        return result;
    end);
end

local function MakeSpecPlayerInfo(spec_id)
    spec_id = tonumber(spec_id);
    if(not spec_id) then
        return nil;
    end

    local playerInfo = TablePool:Acquire();
    playerInfo.spec = spec_id;    
    playerInfo.role = Internal:GetRoleBitmap(spec_id);
    playerInfo.role_main = Bitmap:GetMainRole(playerInfo.role);
    playerInfo.role_sub = Bitmap:GetSubRole(playerInfo.role);
    return playerInfo;
end

function GroupSorter:SortSpecs(specs, selfPlayerInfo)
    if(not specs or #specs == 0) then
        return;
    end

    table.sort(specs, function(specA, specB)
        local playerInfoA = MakeSpecPlayerInfo(specA);
        local playerInfoB = MakeSpecPlayerInfo(specB);

        local result = ComparePlayers(playerInfoA, playerInfoB, selfPlayerInfo);

        TablePool:Release(playerInfoA);
        TablePool:Release(playerInfoB);

        return result;
    end);
end