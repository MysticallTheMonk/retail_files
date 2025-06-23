local _, ArenaAnalytics = ... -- Addon Namespace
local Search = ArenaAnalytics.Search;

-- Local module aliases
local Options = ArenaAnalytics.Options;
local Filters = ArenaAnalytics.Filters;
local Constants = ArenaAnalytics.Constants;
local Bitmap = ArenaAnalytics.Bitmap;
local Helpers = ArenaAnalytics.Helpers;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local TablePool = ArenaAnalytics.TablePool;

-------------------------------------------------------------------------

-- DOCUMENTATION
-- Player Name
--  Charactername // name:Charactername // n:Charactername // Charactername-server // etc

-- Alts
--  altone/alttwo/altthree // name:ltone/alttwo/altthree // n:ltone/alttwo/altthree

-- Class
--  Death Knight // DK // class:Death Knight // class:DeathKnight // class:DK // c:DK // etc

-- Spec
--  Frost // spec:frost // spec:frost // s:frost
--  Frost Mage // spec:frost mage // s:frost mage
 
-- Race
--  Undead // race:undead // r:undead

-- Role
--  Tank // Healer // Damage // role:healer // etc

-- Logical keywords
--  not: placed anywhere in a player segment to inverse the value
--  ! (exclamation mark) prefixes tokens to fails if the token would've passed

-- Team
--  Team:Friend // t:team // t:enemy // t:foe // !t:foe

-- Exact Search:
--  Wrap one or more terms in quotation marks to require an exact match
--  Decide what to do when exact search start and end among different players

-------------------------------------------------------------------------


function Search:GetEmptySegment()
    return { tokens = {} };
end

function Search:GetEmptyData()
    return { segments = {}, nonInversedCount = 0 }
end

-- The current search data
Search.current = {
    display = "", -- Search string sanitized and colored(?) for display
    segments = {} -- Tokenized player segments
}

function Search:GetCurrentSegments()
    assert(Search.current);
    return Search.current.segments or {};
end

function Search:GetCurrentSegmentCount()
    return #Search:GetCurrentSegments();
end

local lastCommittedSearchDisplay = "";
local activeSearchData = Search:GetEmptyData();

---------------------------------
-- Search API
---------------------------------

function Search:Get(key)
    if key then
        return key and Search.current[key];
    else
        return Search.current;
    end
end

function Search:GetLastDisplay()
    return lastCommittedSearchDisplay or "";
end

function Search:GetDisplay()
    return Search.current.display or "";
end

function Search:IsEmpty()
    return Search.current.display == "" and #Search.current.segments == 0 and #activeSearchData.segments == 0;
end

function Search:Reset()
    if(Search:IsEmpty()) then
        return;
    end

    Search:CommitSearch("");
    return true;
end

function Search:Update(input)
    local searchBox = ArenaAnalyticsScrollFrame.searchBox;
    local oldCursorPosition = searchBox:GetCursorPosition();

    local newSearchData = Search:ProcessInput(input, oldCursorPosition);
    Search:SetCurrentData(newSearchData);
end

function Search:SetCurrentData(tokenizedSegments)
    Search.current.segments = tokenizedSegments or {};
    Search:SetCurrentDisplay();
end

local function LogSearchData()
    ArenaAnalytics:LogSpacer();
    ArenaAnalytics:Log("Committing Search..", #activeSearchData.segments, " (" .. activeSearchData.nonInversedCount .. ")");

    for i,segment in ipairs(activeSearchData.segments) do
        for j,token in ipairs(segment.tokens) do
            assert(token and token.value);
            ArenaAnalytics:Log("  Token:", j, "Segment:",i..":", token.value, (token.explicitType or ""), (token.exact and " exact" or ""), (token.negated and " Negated" or ""), (segment.isEnemyTeam or ""), (segment.inversed and "Inversed" or ""));
        end
    end
end

local function GetPersistentData()
    local persistentData = Search:GetEmptyData();

    for i,segment in ipairs(Search:GetCurrentSegments()) do
        assert(segment.tokens);
        local persistentSegment = Search:GetEmptySegment();

        for j,token in ipairs(segment.tokens) do
            -- Process transient tokens for logic only
            if(token.value and token.value ~= "") then
                if(token.transient) then
                    if(token.explicitType == "logical") then
                        if(token.value == "not") then
                            persistentSegment.inversed = true;
                        end
                    elseif(token.explicitType == "team") then
                        persistentSegment.isEnemyTeam = (token.value == "enemy");
                    end
                else -- Persistent tokens, kept for direct comparisons
                    tinsert(persistentSegment.tokens, token);
                end
            end
        end

        if(persistentSegment.isEnemyTeam == nil and Options:Get("searchDefaultExplicitEnemy")) then
            persistentSegment.isEnemyTeam = true;
        end

        if(not persistentSegment.inversed) then
            persistentData.nonInversedCount = persistentData.nonInversedCount + 1;
        end

        tinsert(persistentData.segments, persistentSegment);
    end


    return persistentData;
end

function Search:CommitEmptySearch()
    Search:SetCurrentData();
    Search:CommitSearch();
end

function Search:CommitSearch(input)
    Search.isCommitting = true;

    -- Update active search filter
    if(input) then
        Search:Update(input);
    end

    lastCommittedSearchDisplay = Search.current.display;
    
    -- Add all segments and non-transient tokens to the active data
    activeSearchData = GetPersistentData();

    LogSearchData();

    -- Force filter refresh
    Filters:Refresh();

    Search.isCommitting = nil;
end

---------------------------------
-- Search matching logic
---------------------------------

-- NOTE: This is the main part to modify to handle actual token matching logic
-- Returns true if a given type on a player matches the given value
local function CheckTypeForPlayer(searchType, token, player)
    if(type(token.value) == "number") then
        if(searchType == "class" or searchType == "spec") then
            return Search:CheckSpecMatch(token.value, player);
        elseif(searchType == "race") then
            -- Overrides to treat neutral races as same ID
            local race = ArenaMatch:GetPlayerRace(player);
            return token.value == Search:GetNormalizedRace(race);
        elseif (searchType == "faction") then
            local race = ArenaMatch:GetPlayerRace(player);
            return race and token.value == (race % 2);
        elseif(searchType == "role") then
            local role = ArenaMatch:GetPlayerRole(player);
            return Bitmap:HasBitByIndex(role, token.value);
        end
    elseif(searchType == "name") then
        return ArenaMatch:CheckPlayerName(player, token.value, token.exact);
    elseif(searchType == "alts") then
        if(token.value:find('/', 1, true)) then
            -- Split value into table
            for value in token.value:gmatch("([^/]+)") do
                if(ArenaMatch:CheckPlayerName(player, value, token.exact)) then
                    return true;
                end
            end
            return false;
        else
            ArenaAnalytics:Log("Alts search without /");
            return ArenaMatch:CheckPlayerName(player, token.value, token.exact);
        end
    elseif(searchType == "logical") then
        if(token.value == "self") then
            return ArenaMatch:IsPlayerSelf(player);
        end
    end

    local playerValue = ArenaMatch:GetPlayerValue(player, searchType);
    if(not playerValue or playerValue == "") then
        return false;
    end

    -- Class and Spec IDs may be numbers in the token
    if(type(playerValue) == "number" or type(token.value) == "number") then
        return tonumber(playerValue) == tonumber(token.value);
    else
        return not token.exact and playerValue:find(token.value, 1, true) or (token.value == playerValue);
    end
end

local function CheckTokenForPlayer(token, playerInfo)
    assert(token and playerInfo);

    if(token.explicitType) then
        if(CheckTypeForPlayer(token.explicitType, token, playerInfo)) then
            return true;
        end
    else -- Loop through all types
        ArenaAnalytics:Log("Looping through all types for search!");

        local types = { "name", "spec", "class", "race", "faction" }
        for _,searchType in ipairs(types) do
            if(CheckTypeForPlayer(searchType, token, playerInfo)) then
                return true;
            end
        end
    end
    return false;
end

local function CheckSegmentForPlayer(segment, player)
    assert(segment and player);

    if(not player) then
        return false;
    end

    for i,token in ipairs(segment.tokens) do
        local successValue = not token.negated;
        if(CheckTokenForPlayer(token, player) ~= successValue) then
            return false;
        end
    end

    return true;
end

---------------------------------
-- Simple Pass
---------------------------------

local function CheckSegmentForMatch(segment, match, alreadyMatchedPlayers)
    assert(match);

    if(not segment) then
        return false;
    end

    local teams = segment.isEnemyTeam ~= nil and {segment.isEnemyTeam} or {false, true};
    local foundConflictMatch = false;

    for _,isEnemyTeam in ipairs(teams) do
        local team = ArenaMatch:GetTeam(match, isEnemyTeam);
        for _, player in ipairs(team) do
            local result = CheckSegmentForPlayer(segment, player);
            if(result) then
                local fullName = ArenaMatch:GetPlayerFullName(player);
                if(not alreadyMatchedPlayers or segment.inversed or not fullName) then
                    -- Skip conflict handling
                    return true;
                elseif(alreadyMatchedPlayers[fullName] == nil) then
                    alreadyMatchedPlayers[fullName] = true;
                    return true;
                else
                    foundConflictMatch = true;
                end
            end
        end
    end

    -- In case of no unique matches above
    if(foundConflictMatch) then
        return nil; -- No final result
    else
        return false; -- Failed to pass
    end
end

-- Returns true/false depending on whether it passed, or nil if it could not yet be determined
local function CheckSimplePass(match)
    assert(match);

    -- Cache found matches
    local alreadyMatchedPlayers = {}

    -- Look for segments with no matches or no unique matches
    for _,segment in ipairs(activeSearchData.segments) do
        local segmentResult = CheckSegmentForMatch(segment, match, alreadyMatchedPlayers);

        if(segmentResult == nil) then
            return nil; -- Segment detected conflict
        end
        
        local successValue = not segment.inversed;
        if(segmentResult ~= successValue) then
            return false; -- Failed to pass.
        end    
    end
    
    -- All segments passed without conflict
    return true;
end

---------------------------------
-- Advanced Pass
---------------------------------

local function PruneUniqueMatches(segmentMatches, playerMatches)
    if(#segmentMatches == 0 and #playerMatches == 0) then
        return;
    end
    
    local changed = true;

    local function PruneLockedValues(tableToPrune, valueToRemove)
        for i = #tableToPrune, 1, -1 do
            local matches = tableToPrune[i];
            
            for j = #matches, 1, -1 do
                local value = matches[j];
                if(value and value == valueToRemove) then
                    if(#matches == 1) then
                        table.remove(tableToPrune, i);
                    else
                        table.remove(matches, j);
                    end

                    changed = true;
                    break;
                end
            end
        end
    end

    local function LockUniqueMatches(tableToCheck, pairedTable)
        for i = #tableToCheck, 1, -1 do
            local matches = tableToCheck[i];
            
            if #matches == 1 then
                local value = matches[1];
                if(pairedTable[value] ~= nil and #pairedTable[value] > 0) then
                    table.remove(tableToCheck, i);
                    
                    PruneLockedValues(tableToCheck, value);
                    pairedTable[value] = nil;
                else
                    return false;
                end
            end
        end
        return true;
    end

    while changed do
        changed = false

        -- Find segments with only one matched player
        if(LockUniqueMatches(segmentMatches, playerMatches) == false) then
            return false;
        end

        -- Find players with only one matched segment
        if(LockUniqueMatches(playerMatches, segmentMatches) == false) then
            return false;
        end
    end
end

local function recursivelyMatchSegments(segmentMatches, segmentIndex, alreadyMatchedPlayers)
    if segmentIndex > #segmentMatches then
        return true;
    end

    local segment = segmentMatches[segmentIndex];
    if(#segment == 0) then
        ArenaAnalytics:Log("Recursion found empty segment matches")
        return false;
    end

    for _, player in ipairs(segment) do
        if not alreadyMatchedPlayers[player] then
            alreadyMatchedPlayers[player] = true;
            if recursivelyMatchSegments(segmentMatches, segmentIndex + 1, alreadyMatchedPlayers) then
                return true;
            end
            alreadyMatchedPlayers[player] = nil;
        end
    end

    return false;
end

local function CheckAdvancedPass(match)
    ArenaAnalytics:Log("Search: Checking advanced pass..")
    local segmentMatches, playerMatches = {}, {}

    local matchedTables = {}
    local currentIndex = 1;

    -- Fill matched tables
    for segmentIndex, segment in ipairs(activeSearchData.segments) do
        local teams = segment.isEnemyTeam ~= nil and {segment.isEnemyTeam} or {false, true};

        for _,isEnemyTeam in ipairs(teams) do
            local team = ArenaMatch:GetTeam(match, isEnemyTeam);
            for playerIndex, player in ipairs(team) do
                if(CheckSegmentForPlayer(segment, player)) then
                    if(segment.inversed) then
                        -- Inverse segments fail the pass if they match
                        return false;
                    end

                    local playerKey = (isEnemyTeam and "enemy" or "team") .. playerIndex;

                    -- Add player to segment matches
                    segmentMatches[currentIndex] = segmentMatches[currentIndex] or {};
                    tinsert(segmentMatches[currentIndex], playerKey);

                    -- Add segment to player matches
                    playerMatches[playerKey] = playerMatches[playerKey] or {};
                    tinsert(playerMatches[playerKey], currentIndex);
                end
            end
        end

        -- Failed to find a match for the segment
        if(not segment.inversed and not segmentMatches[currentIndex]) then
            return false;
        end

        currentIndex = currentIndex + 1;
    end

    -- If all segment matches were removed by pruning, then unique matches were found
    if(#segmentMatches == 0) then
        return true;
    end

    table.sort(segmentMatches, function(a, b)
        return #a < #b;
    end);

    local alreadyMatchedPlayers = {};
    return recursivelyMatchSegments(segmentMatches, 1, alreadyMatchedPlayers);
end

---------------------------------
-- Check Match for Search
---------------------------------

local function CheckSearchPassInternal(match)
    if(#activeSearchData.segments == 0) then
        return true;
    end

    if(match == nil) then
        ArenaAnalytics:Log("Nil match reached search filter.")
        return false;
    end

    -- Cannot match a search with more players than the match has data for.
    if(activeSearchData.nonInversedCount > ArenaMatch:GetPlayerCount(match)) then
        return false;
    end

    -- Simple pass first
    local simplePassResult = CheckSimplePass(match);
    if(simplePassResult == false) then
        -- Simple pass failed explicitly
        return false;
    end

    -- Advanced pass in case of segment conflict from simple pass
    if(simplePassResult == nil and not CheckAdvancedPass(match)) then
        return false;
    end

    return true;
end

-- Main Matching Function to Check Feasibility
function Search:DoesMatchPassSearch(match)
    --debugprofilestart();

    local result = CheckSearchPassInternal(match);

    --ArenaAnalytics:Log("Search pass elapsed:", debugprofilestop());

    return result;
end

-------------------------------------------------------------------------
-- Initialize

function Search:Initialize()

end