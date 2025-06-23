-- Namespace for managing versions, including backwards compatibility and converting data
local _, ArenaAnalytics = ...; -- Addon Namespace
local VersionManager = ArenaAnalytics.VersionManager;

-- Local module aliases
local Constants = ArenaAnalytics.Constants;
local Filters = ArenaAnalytics.Filters;
local Import = ArenaAnalytics.Import;
local API = ArenaAnalytics.API;
local Helpers = ArenaAnalytics.Helpers;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local Internal = ArenaAnalytics.Internal;
local Localization = ArenaAnalytics.Localization;
local Sessions = ArenaAnalytics.Sessions;
local Debug = ArenaAnalytics.Debug;

-------------------------------------------------------------------------

-- True if data sync was detected with a later version.
VersionManager.newDetectedVersion = false;
VersionManager.latestFormatVersion = 4;

-- Compare two version strings. Returns -1 if version is lower, 0 if equal, 1 if higher.
function VersionManager:compareVersions(version, otherVersion)
    otherVersion = otherVersion or API:GetAddonVersion();

    if(version == nil or version == "") then
        return otherVersion and 1 or 0;
    end

    if(otherVersion == nil or otherVersion == "") then
        return -1;
    end

    local function versionToTable(inVersion)
        local outTable = {}
        inVersion = inVersion or 0;

        inVersion:gsub("([^.]*).", function(c)
            table.insert(outTable, c)
        end);

        return outTable;
    end

    if(version ~= otherVersion) then
        local v1table = versionToTable(version);
        local v2table = versionToTable(otherVersion);

        local length = max(#v1table, #v2table);
        for i=1, length do
            local v1 = tonumber(v1table[i]) or 0;
            local v2 = tonumber(v2table[i]) or 0;

            if(v1 ~= v2) then
                return (v1 < v2 and -1 or 1);
            end
        end
    end

    return 0;
end

function VersionManager:HasOldData()
    -- Original format of ArenaAnalyticsDB (Outdated as of 0.3.0)
    if(ArenaAnalyticsDB) then
        local oldTotal = (ArenaAnalyticsDB["2v2"] and #ArenaAnalyticsDB["2v2"] or 0) + (ArenaAnalyticsDB["3v3"] and #ArenaAnalyticsDB["3v3"] or 0) + (ArenaAnalyticsDB["5v5"] and #ArenaAnalyticsDB["5v5"] or 0);
        if(oldTotal > 0) then
            return true;
        end
    end

    -- 0.3.0 Match History DB (Outdated as of 0.7.0)
    if(MatchHistoryDB and #MatchHistoryDB > 0) then
        return true;
    end

    return false;
end

-- Returns true if loading should convert data
function VersionManager:OnInit()
    ArenaAnalyticsDB.formatVersion = ArenaAnalyticsDB.formatVersion or 0;
    if(ArenaAnalyticsDB.formatVersion >= VersionManager.latestFormatVersion) then
        return;
    end

    if(VersionManager:HasOldData() and #ArenaAnalyticsDB == 0) then
        -- Force early init, to ensure the internal tables are valid.
        Internal:Initialize();

        ArenaAnalytics:Log("Converting old data...")

        VersionManager:convertArenaAnalyticsDBToMatchHistoryDB() -- 0.3.0
        VersionManager:renameMatchHistoryDBKeys(); -- 0.5.0

        -- Clear old data
        if(ArenaAnalyticsDB) then
            ArenaAnalyticsDB["2v2"] = nil;
            ArenaAnalyticsDB["3v3"] = nil;
            ArenaAnalyticsDB["5v5"] = nil;
        end

        -- Assign new format
        VersionManager:ConvertMatchHistoryDBToNewArenaAnalyticsDB(); -- 0.7.0

        MatchHistoryDB = nil;
    end

    -- Reverts and reset index based name and realm (To improve order and streamline formatting across version)
    if(ArenaAnalyticsDB.formatVersion == 0) then
        VersionManager:RevertIndexBasedNameAndRealm();
    end

    -- Update round delimiter and compress player to compact string
    if(ArenaAnalyticsDB.formatVersion == 1) then
        VersionManager:ConvertRoundAndPlayerFormat();
    end

    if(ArenaAnalyticsDB.formatVersion == 2) then
        for i,match in ipairs(ArenaAnalyticsDB) do
            ArenaMatch:AddWinsToRoundData(match);
        end

        ArenaAnalyticsDB.formatVersion = 3;
    end

    if(ArenaAnalyticsDB.formatVersion == 3) then
        for i,match in ipairs(ArenaAnalyticsDB) do
            ArenaMatch:UpdateComps(match);
        end

        ArenaAnalyticsDB.formatVersion = 4;
    end

    VersionManager:FinalizeConversionAttempts();

    ArenaAnalyticsDB.formatVersion = VersionManager.latestFormatVersion;
end

local function convertFormatedDurationToSeconds(inDuration)
    if(tonumber(inDuration)) then
        return inDuration;
    end

    if(inDuration ~= nil and inDuration ~= "") then
        -- Sanitize the formatted time string
        inDuration = inDuration:lower();
        inDuration = inDuration:gsub("%s+", "");

        local minutes, seconds = 0,0;

        if(inDuration:find("|", 1, true)) then
            -- Get minutes before '|' and seconds between ';' and "sec"
            minutes = tonumber(inDuration:match("(.+)|")) or 0;
            seconds = tonumber(inDuration:match(";(.+)sec")) or 0;
        elseif(inDuration:find("min", 1, true) and inDuration:find("sec", 1, true)) then
            -- Get minutes before "min" and seconds between "min" and "sec
            minutes = tonumber(inDuration:match("(.*)min")) or 0;
            seconds = inDuration:match("min(.*)sec") or 0;
        elseif(inDuration:find("sec", 1, true)) then
            -- Get seconds before "sec
            seconds = tonumber(inDuration:match("(.*)sec")) or 0;
        else
            ArenaAnalytics:LogError("Converting duration failed (:", inDuration, ")");
        end

        if(minutes and seconds) then
            return 60*minutes + seconds;
        else
            return seconds or 0;
        end
    end

    return 0;
end

local function SanitizeSeason(season, unixDate)
    if(season == nil or season == 0) then
        return nil;
    end

    return season;
end

-- v0.3.0 -> 0.5.0
local function updateGroupDataToNewFormat(group)
    local updatedGroup = {};
    for _, player in ipairs(group) do
        local class = (player["class"] and #player["class"] > 2) and player["class"] or nil;
        local spec = (player["spec"] and #player["spec"] > 2) and player["spec"] or nil;

        local updatedPlayerTable = {
            ["GUID"] = player["GUID"] or "",
            ["name"] = player["name"] or "",
            ["class"] = class,
            ["spec"] = spec,
            ["race"] = player["race"],
            ["faction"] = Constants:GetFactionByRace(player["race"]),
            ["killingBlows"] = tonumber(player["killingBlows"]),
            ["deaths"] = tonumber(player["deaths"]),
            ["damageDone"] = tonumber(player["damageDone"]),
            ["healingDone"] = tonumber(player["healingDone"])
        }
        table.insert(updatedGroup, updatedPlayerTable);
    end
    return updatedGroup;
end

-- Convert long form string comp to addon spec ID comp
local function convertCompToShortFormat(comp, bracket)
    local size = ArenaAnalytics:getTeamSizeFromBracket(bracket);

    local newComp = {}
    for i=1, size do
        local specKeyString = comp[i];
        if(specKeyString == nil) then
            return nil;
        end

        local class, spec = specKeyString:match("([^|]+)|(.+)");
        local specID = Constants:getAddonSpecializationID(class, spec, true);
        if(specID == nil) then
            return nil;
        end

        table.insert(newComp, specID);
    end

    table.sort(newComp, function(a, b)
        return a < b;
    end);

    return table.concat(newComp, '|');
end

local function getFullFirstDeathName(firstDeathName, team, enemyTeam)
    if(firstDeathName == nil or #firstDeathName < 3) then
        return nil;
    end

    for _,player in ipairs(team) do
        local name = player and player["name"] or nil;
        if(name and name:find(firstDeathName, 1, true)) then
            return name;
        end
    end

    for _,player in ipairs(enemyTeam) do
        local name = player and player["name"] or nil;
        if(name and name:find(firstDeathName, 1, true)) then
            return name;
        end
    end

    ArenaAnalytics:Log("getFullDeathName failed to find matching player name.", firstDeathName);
    return nil;
end

-- 0.3.0 conversion from ArenaAnalyticsDB per bracket to MatchHistoryDB
function VersionManager:convertArenaAnalyticsDBToMatchHistoryDB()
    MatchHistoryDB = MatchHistoryDB or {}

    local oldTotal = (ArenaAnalyticsDB["2v2"] and #ArenaAnalyticsDB["2v2"] or 0) + (ArenaAnalyticsDB["3v3"] and #ArenaAnalyticsDB["3v3"] or 0) + (ArenaAnalyticsDB["5v5"] and #ArenaAnalyticsDB["5v5"] or 0);
    if(oldTotal == 0) then
        ArenaAnalytics:Log("No old ArenaAnalyticsDB data found.")
        return;
    end

    if(#MatchHistoryDB > 0) then
        ArenaAnalytics:Log("Non-empty MatchHistoryDB.");
        return;
    end

    local brackets = { "2v2", "3v3", "5v5" }
    for _, bracket in ipairs(brackets) do
        if(ArenaAnalyticsDB[bracket] ~= nil) then
            for _, arena in ipairs(ArenaAnalyticsDB[bracket]) do
                local team = updateGroupDataToNewFormat(arena["team"]);
                local enemyTeam = updateGroupDataToNewFormat(arena["enemyTeam"]);

                local updatedArenaData = {
                    ["isRated"] = arena["isRanked"],
                    ["date"] = arena["dateInt"],
                    ["season"] = SanitizeSeason(arena["season"], arena["dateInt"]),
                    ["map"] = arena["map"], 
                    ["bracket"] = bracket,
                    ["duration"] = convertFormatedDurationToSeconds(tonumber(arena["duration"]) or 0),
                    ["team"] = team,
                    ["rating"] = tonumber(arena["rating"]),
                    ["ratingDelta"] = tonumber(arena["ratingDelta"]),
                    ["mmr"] = tonumber(arena["mmr"]), 
                    ["enemyTeam"] = enemyTeam,
                    ["enemyRating"] = tonumber(arena["enemyRating"]), 
                    ["enemyRatingDelta"] = tonumber(arena["enemyRatingDelta"]),
                    ["enemyMmr"] = tonumber(arena["enemyMmr"]),
                    ["comp"] = convertCompToShortFormat(arena["comp"], bracket),
                    ["enemyComp"] = convertCompToShortFormat(arena["enemyComp"], bracket),
                    ["won"] = arena["won"],
                    ["firstDeath"] = getFullFirstDeathName(arena["firstDeath"], team, enemyTeam)
                }

                ArenaAnalytics:Log("Adding arena from ArenaAnalyticsDB (Old format)", #MatchHistoryDB)
                table.insert(MatchHistoryDB, updatedArenaData);
            end
        end
    end

    ArenaAnalytics:PrintSystem("Converted data from old database. Old total: ", oldTotal, " New total: ", #MatchHistoryDB);

    table.sort(MatchHistoryDB, function (k1,k2)
        if (k1["date"] and k2["date"]) then
            return k1["date"] < k2["date"];
        end
    end);
end

-- 0.5.0 renamed keys
function VersionManager:renameMatchHistoryDBKeys()
    MatchHistoryDB = MatchHistoryDB or {};

    local function renameKey(table, oldKey, newKey)
        if(table[oldKey] and not table[newKey]) then
            table[newKey] = table[oldKey];
            table[oldKey] = nil;
        end
    end

    for i = 1, #MatchHistoryDB do
		local match = MatchHistoryDB[i];
        
        local teams = {"team", "enemyTeam"}

        for _,team in ipairs(teams) do
            for i = 1, #match[team] do
                local player = match[team][i];

                -- Rename keys:
                renameKey(player, "damageDone", "damage");
                renameKey(player, "healingDone", "healing");
                renameKey(player, "killingBlows", "kills");
            end    
        end
	end
end

function VersionManager:ConvertMatchHistoryDBToNewArenaAnalyticsDB()
    if(not MatchHistoryDB or #MatchHistoryDB == 0) then
        return;
    end
    
    if(ArenaAnalyticsDB and #ArenaAnalyticsDB > 0) then
        ArenaAnalytics:Log("Version Control: Non-empty ArenaAnalyticsDB.");
        return;
    end

    ArenaAnalyticsDB = {};
    ArenaAnalytics:InitializeArenaAnalyticsDB();

    local function ConvertValues(race, class, spec)
        local race_id = Localization:GetRaceID(race);
        if(race_id) then
            race = race_id;
        else
            ArenaAnalytics:Log("Failed to find race_id when converting race:", race);
        end

        local class_id = Localization:GetClassID(class);
        if(class_id) then
            class = class_id;
        else
            ArenaAnalytics:Log("Failed to find class_id when converting class:", class);
        end

        local spec_id = Internal:GetSpecFromSpecString(class, spec);
        if(spec_id) then
            spec = spec_id;
        else
            ArenaAnalytics:Log("Failed to find spec_id when converting class:", class, "spec:", spec);
        end

        return race, tonumber(spec) or tonumber(class);
    end

    local selfNames = {}

    -- Convert old arenas
    for i=1, #MatchHistoryDB do
        local oldArena = MatchHistoryDB[i];
        if(oldArena) then 
            local convertedArena = { }

            -- Set values
            ArenaMatch:SetDate(convertedArena, oldArena["date"]);
            ArenaMatch:SetDuration(convertedArena, oldArena["duration"]);
            ArenaMatch:SetMap(convertedArena, oldArena["map"]);
            ArenaMatch:SetBracket(convertedArena, oldArena["bracket"]);
            ArenaMatch:SetMatchType(convertedArena, (not oldArena["isRated"] or oldArena["rating"] == "SKIRMISH") and "skirmish" or "rated");

            ArenaMatch:SetPartyRating(convertedArena, oldArena["rating"]);
            ArenaMatch:SetPartyMMR(convertedArena, oldArena["mmr"]);
            ArenaMatch:SetPartyRatingDelta(convertedArena, oldArena["ratingDelta"]);

            ArenaMatch:SetEnemyRating(convertedArena, oldArena["enemyRating"]);
            ArenaMatch:SetEnemyMMR(convertedArena, oldArena["enemyMmr"]);
            ArenaMatch:SetEnemyRatingDelta(convertedArena, oldArena["enemyRatingDelta"]);

            ArenaMatch:SetSeason(convertedArena, oldArena["season"]);
            ArenaMatch:SetSession(convertedArena, oldArena["session"]);

            ArenaMatch:SetMatchOutcome(convertedArena, oldArena["won"]);

            local function ConvertPlayerValues(player)
                local race_id, spec_id = ConvertValues(player.race, player.class, player.spec);
                local role_id = API:GetRoleBitmap(spec_id);

                -- Update for new format values
                player.spec = spec_id;
                player.race = race_id;
                player.role = role_id;
                player.isEnemy = false;

                if(player.name) then
                    if(player.name == oldArena.player) then
                        player.isSelf = true;
                    end

                    if(player.name == oldArena.isFirstDeath) then
                        player.isFirstDeath = true;
                    end
                end
            end

            -- Add team
            for _,player in ipairs(oldArena["team"]) do
                ConvertPlayerValues(player);
                player.isEnemy = false;
                ArenaMatch:AddPlayer(convertedArena, player);
            end

            -- Add enemy team
            for _,player in ipairs(oldArena["enemyTeam"]) do
                ConvertPlayerValues(player);
                player.isEnemy = true;
                ArenaMatch:AddPlayer(convertedArena, player);
            end

            if(oldArena.player) then
                selfNames[oldArena.player] = true;
            end

            -- Comps
            ArenaMatch:UpdateComps(convertedArena);

            tinsert(ArenaAnalyticsDB, convertedArena);
        end
    end

    local myName = Helpers:GetPlayerName();
    if(myName) then
        selfNames[myName] = true;
    else
        ArenaAnalytics:Log("Failed to get local player name. Versioning called too early.");
    end

    -- Attempt retroactively assigning player names
    for i,match in ipairs(ArenaAnalyticsDB) do
        if(match and not ArenaMatch:HasSelf(match)) then
            for name,_ in pairs(selfNames) do
                local result = ArenaMatch:SetSelf(match, name);
                if(result) then
                    break;
                end
            end
        end
    end
end

function VersionManager:RevertIndexBasedNameAndRealm()
    if(ArenaAnalyticsDB.formatVersion ~= 0) then
        return;
    end

    -- Confirm that there are only one realms DB with data at a time!
    if(#ArenaAnalyticsDB.realms > 1) then
        assert(not ArenaAnalyticsRealmsDB or #ArenaAnalyticsRealmsDB == 0);
        assert(not ArenaAnalyticsDB.Realms or #ArenaAnalyticsDB.Realms == 0);
    elseif(ArenaAnalyticsRealmsDB and #ArenaAnalyticsRealmsDB > 0) then
        assert(not ArenaAnalyticsDB.Realms or #ArenaAnalyticsDB.Realms == 0);
        assert(#ArenaAnalyticsDB.realms <= 1);
    elseif(ArenaAnalyticsDB.Realms and #ArenaAnalyticsDB.Realms > 0) then
        assert(not ArenaAnalyticsRealmsDB or #ArenaAnalyticsRealmsDB == 0);
        assert(#ArenaAnalyticsDB.realms <= 1);
    end

    -- Confirm that there are only one names DB with data at a time!
    if(#ArenaAnalyticsDB.names > 1) then
        assert(not ArenaAnalyticsDB.Names or #ArenaAnalyticsDB.Names == 0);
    elseif(ArenaAnalyticsDB.Names and #ArenaAnalyticsDB.Names > 0) then
        assert(#ArenaAnalyticsDB.names <= 1);
    end

    -- Move 0.7.0 realms DB to ArenaAnalyticsDB.realms
    if(ArenaAnalyticsRealmsDB and #ArenaAnalyticsRealmsDB > 0 and #ArenaAnalyticsDB.realms <= 1) then
		ArenaAnalyticsDB.realms = Helpers:DeepCopy(ArenaAnalyticsRealmsDB) or {};
		ArenaAnalyticsRealmsDB = nil;

        -- Logging
		ArenaAnalytics:Log("Converted ArenaAnalyticsRealmsDB:", #ArenaAnalyticsDB.realms);
	end

    -- Convert realms DB to final DB
    if(#ArenaAnalyticsDB.realms == 1 and ArenaAnalyticsDB.Realms and #ArenaAnalyticsDB.Realms > 0) then
        ArenaAnalytics:Log("Deep copying ArenaAnalyticsDB.Realms", #ArenaAnalyticsDB.Realms);
        ArenaAnalyticsDB.realms = Helpers:DeepCopy(ArenaAnalyticsDB.Realms) or {};
        ArenaAnalyticsDB.Realms = nil;
    end

    -- Convert names DB to final DB
    if(#ArenaAnalyticsDB.names == 1 and ArenaAnalyticsDB.Names and #ArenaAnalyticsDB.Names > 0) then
        ArenaAnalytics:Log("Deep copying ArenaAnalyticsDB.Names", #ArenaAnalyticsDB.Names);
        ArenaAnalyticsDB.names = Helpers:DeepCopy(ArenaAnalyticsDB.Names) or {};
        ArenaAnalyticsDB.Names = nil;
    end

    -- Revert index based naming, to prioritize self as index 1
    for i=1, #ArenaAnalyticsDB do
        local match = ArenaAnalyticsDB[i];
        if(match) then
            ArenaMatch:RevertPlayerNameAndRealmIndexing(match);
        end
    end

    -- Reset names and realms lists
    ArenaAnalyticsDB.names = nil;
    ArenaAnalyticsDB.realms = nil;
    ArenaAnalytics:InitializeArenaAnalyticsDB();

    -- Set a format version, to prevent repeating formatting
    ArenaAnalyticsDB.formatVersion = 1;
end

function VersionManager:ConvertRoundAndPlayerFormat()
    assert(ArenaAnalyticsDB.names[1] == UnitNameUnmodified("player"), "Invalid or missing self as first name entry!");

    local _,realm = UnitFullName("player");
    assert(realm and ArenaAnalyticsDB.realms[1] == realm, "Invalid or missing local realm as first realm entry!");

    if(ArenaAnalyticsDB.formatVersion ~= 1) then
        return;
    end

    for i=1, #ArenaAnalyticsDB do
        local match = ArenaAnalyticsDB[i];
        if(match) then
            ArenaMatch:FixRoundFormat(match);
            ArenaMatch:ConvertPlayerValues(match, i);
        end
    end

    ArenaAnalyticsDB.formatVersion = 2;
end

function VersionManager:FinalizeConversionAttempts()
	ArenaAnalytics.unsavedArenaCount = #ArenaAnalyticsDB;

	ArenaAnalytics:ResortGroupsInMatchHistory();
	Sessions:RecomputeSessionsForMatchHistory();

    Import:TryHide();
    Filters:Refresh();
    ArenaAnalyticsScrollFrame:Hide();
end