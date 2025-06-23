-- API adjusted functions to let calling code stay version agnostic.
local _, ArenaAnalytics = ...; -- Addon Namespace
local API = ArenaAnalytics.API;

-- Local module aliases
local Internal = ArenaAnalytics.Internal;
local Constants = ArenaAnalytics.Constants;
local Options = ArenaAnalytics.Options;

-------------------------------------------------------------------------

API.numClasses = 13; -- Number of class indices to check for class info (Custom to support cross expansion import)

API.classMappingTable = {
    [1] = 80,
    [2] = 10,
    [3] = 40,
    [4] = 60,
    [5] = 90,
    [6] = 30,
    [7] = 20,
    [8] = 50,
    [9] = 70,
    [10] = 100,
    [11] = 0,
    [12] = 110,
    [13] = 120,
};

function API:GetAddonVersion()
    if(GetAddOnMetadata) then
        return GetAddOnMetadata("ArenaAnalytics", "Version") or "-";
    end
    return C_AddOns and C_AddOns.GetAddOnMetadata("ArenaAnalytics", "Version") or "-";
end

function API:GetActiveBattlefieldID()
    for index = 1, GetMaxBattlefieldID() do
        local status = API:GetBattlefieldStatus(index)
        if status == "active" then
			ArenaAnalytics:Log("Found battlefield ID ", index)
            return index;
        end
    end
	ArenaAnalytics:Log("Failed to find battlefield ID");
end

-- Unused
function API:GetMaxSpecializationsForClass(classIndex)
    if(C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID) then
        return C_SpecializationInfo.GetNumSpecializationsForClassID(classIndex);
    end

    if(GetNumSpecializationsForClassID) then
        return GetNumSpecializationsForClassID(classIndex);
    end

    return nil;
end

-- TODO: Custom off season logic?
function API:GetCurrentSeason()
    return GetCurrentArenaSeason();
end

function API:GetCurrentMapID()
    local mapID = select(8,GetInstanceInfo());
    return tonumber(mapID);
end

function API:IsSoloShuffle()
    return C_PvP and C_PvP.IsSoloShuffle and C_PvP.IsSoloShuffle();
end

-------------------------------------------------------------------------

function API:HasSurrenderAPI()
    return CanSurrenderArena and SurrenderArena;
end

function API:TrySurrenderArena(source)
    if(not API:HasSurrenderAPI()) then
        return nil;
    end

    if(not IsActiveBattlefieldArena()) then
        return nil;
    end

    if(source == "afk" and not Options:Get("enableSurrenderAfkOverride")) then
        return nil;
    elseif(source == "gg" and not Options:Get("enableSurrenderGoodGameCommand")) then
        return nil;
    end

    if(CanSurrenderArena()) then
        ArenaAnalytics:PrintSystem("You have surrendered!");
        ArenaAnalytics.lastSurrenderAttempt = nil;
        SurrenderArena();
        return true;
    elseif(Options:Get("enableDoubleAfkToLeave") and source == "afk") then
        if(not ArenaAnalytics.lastSurrenderAttempt or (ArenaAnalytics.lastSurrenderAttempt + 5 < time())) then
            ArenaAnalytics:PrintSystem("Type /afk again to leave.");
            ArenaAnalytics.lastSurrenderAttempt = time();
        else
            ArenaAnalytics:PrintSystem("Double /afk triggered.");
            ArenaAnalytics.lastSurrenderAttempt = nil;
            LeaveBattlefield();
        end
    else
        ArenaAnalytics:PrintSystem("You cannot surrender yet!");
        return false;
    end
end

-------------------------------------------------------------------------

function API:UpdateDialogueVolume()
    if(API:IsInArena() and Options:Get("muteArenaDialogSounds")) then
        if(ArenaAnalyticsSharedSettingsDB.previousDialogMuteValue == nil) then
            local previousValue = tonumber(GetCVar("Sound_DialogVolume"));
            if(previousValue ~= 0) then
                ArenaAnalytics:Log("Muted dialogue sound.");
                SetCVar("Sound_DialogVolume", 0);
                local newValue = tonumber(GetCVar("Sound_DialogVolume"));
                if(tonumber(newValue) == 0) then
                    ArenaAnalyticsSharedSettingsDB.previousDialogMuteValue = previousValue;
                    ArenaAnalytics:LogGreen("previousDialogMuteValue set to previous value:", previousValue);
                end
            end
        end
    elseif(ArenaAnalyticsSharedSettingsDB.previousDialogMuteValue ~= nil) then
        if(tonumber(GetCVar("Sound_DialogVolume")) == 0) then
            SetCVar("Sound_DialogVolume", ArenaAnalyticsSharedSettingsDB.previousDialogMuteValue);
            ArenaAnalytics:Log("Unmuted dialogue sound.");
        end

        ArenaAnalyticsSharedSettingsDB.previousDialogMuteValue = nil;
    end
end

-------------------------------------------------------------------------

function API:GetArenaPlayerSpec(index, isEnemy)
    if(isEnemy) then
        -- Depends on GotArenaOpponentSpec API to function    
        if(GetArenaOpponentSpec) then
            local id = GetArenaOpponentSpec(index);
            return API:GetMappedAddonSpecID(id);
        end
    else
        -- Add friendly support
    end
end

function API:GetRoleBitmap(spec_id)
    spec_id = tonumber(spec_id);
    if(not spec_id) then
        return;
    end

    -- Check for override
    local bitmapOverride = API.roleBitmapOverrides and API.roleBitmapOverrides[spec_id];

    return bitmapOverride or Internal:GetRoleBitmap(spec_id);
end

function API:GetMappedAddonSpecID(specID)
    if(not API.specMappingTable) then
        ArenaAnalytics:Log("GetMappedAddonSpecID: Failed to find specMappingTable. Ignoring spec:", specID);
        return nil;
    end

    specID = tonumber(specID);

    local spec_id = specID and API.specMappingTable[specID];
    if(not spec_id) then
        ArenaAnalytics:Log("Failed to find spec_id for:", specID, type(specID));
        return nil;
    end

    return spec_id;
end

function API:GetSpecIcon(spec_id)
    spec_id = tonumber(spec_id);
    if(not spec_id) then
        return;
    end

    -- Check for override
    local bitmapOverride = API.specIconOverrides and API.specIconOverrides[spec_id];

    return bitmapOverride or Constants:GetBaseSpecIcon(spec_id);
end

-------------------------------------------------------------------------
-- Initialize the general and expansion specific addon API
function API:Initialize()
    if(API.InitializeExpansion) then
        API:InitializeExpansion();
    end
end