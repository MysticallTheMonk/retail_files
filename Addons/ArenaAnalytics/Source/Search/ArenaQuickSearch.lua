local _, ArenaAnalytics = ... -- Addon Namespace
local Search = ArenaAnalytics.Search;

-- Local module aliases
local Options = ArenaAnalytics.Options;
local Constants = ArenaAnalytics.Constants;
local Helpers = ArenaAnalytics.Helpers;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local Internal = ArenaAnalytics.Internal;

-------------------------------------------------------------------------
-- Short Names

local QuickSearchValueTable = {
    ["race"] = {
        ["blood elf"] = "Belf",
        ["draenei"] = "Draenei",
        ["dwarf"] = "Dwarf",
        ["gnome"] = "Gnome",
        ["goblin"] = "Goblin",
        ["human"] = "Human",
        ["night elf"] = "Nelf",
        ["orc"] = "Orc",
        ["pandaren"] = "Pandaren",
        ["tauren"] = "Tauren",
        ["troll"] = "Troll",
        ["undead"] = "Undead",
        ["worgen"] = "Worgen",
        ["void elf"] = "Velf",
        ["lightforged draenei"] = "LDraenei",
        ["nightborne"] = "Nightborne",
        ["highmountain tauren"] = "HTauren",
        ["zandalari troll"] = "ZTroll",
        ["kul tiran"] = "KTiran",
        ["dark iron dwarf"] = "DIDwarf",
        ["mag'har orc"] = "MOrc",
        ["mechagnome"] = "MGnome",
        ["vulpera"] = "Vulpera"
    },
}

function Search:GetShortQuickSearch(typeKey, longValue)
    assert(typeKey and QuickSearchValueTable[typeKey]);
    return longValue and QuickSearchValueTable[typeKey][longValue:lower()] or longValue;
end

---------------------------------
-- Quick Search
---------------------------------

local function CheckShortcut(shortcut, btn)
    if(not shortcut or shortcut == "None") then
        return false;
    end

    if(shortcut == "Any") then
        return true;
    end

    if(shortcut == "LMB") then
        return btn == "LeftButton";
    end
    
    if(shortcut == "RMB") then
        return btn == "RightButton";
    end

    if(shortcut == "Shift") then
        return IsShiftKeyDown();
    end

    if(shortcut == "Ctrl") then
        return IsControlKeyDown();
    end
    
    if(shortcut == "Alt") then
        return IsAltKeyDown();
    end
    
    if(shortcut == "Nomod") then
        return not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown();
    end

    return false;
end

local function GetPlayerName(player)
    name = ArenaMatch:GetPlayerFullName(player);

    if(name:find('-', 1, true)) then
        local includeRealmSetting = Options:Get("quickSearchIncludeRealm");
        local includeRealm = true;

        local _, realm = UnitFullName("player");
        local isMyRealm = realm and name:find(realm, 1, true);

        if(includeRealmSetting == "All") then
            includeRealm = true;
        elseif(includeRealmSetting == "None") then
            includeRealm = false;
        elseif(includeRealmSetting == "Other Realms") then
            includeRealm = not isMyRealm;
        elseif(includeRealmSetting == "My Realm") then
            includeRealm = isMyRealm;
        end

        if(not includeRealm) then
            name = name:match("(.*)-") or name;
        end
    end

    return name;
end

local function AddSettingAction(actions, setting)
    assert(setting and actions);

    local action = Options:Get(setting);
    if(action and action ~= "None") then
        actions[action] = true;
    end
end

local function GetAppendRule(btn)
    if(CheckShortcut(Options:Get("quickSearchAppendRule_NewSearch"), btn)) then
        return "New Search";
    end

    if(CheckShortcut(Options:Get("quickSearchAppendRule_NewSegment"), btn)) then
        return "New Segment";
    end

    if(CheckShortcut(Options:Get("quickSearchAppendRule_SameSegment"), btn)) then
        return "Same Segment";
    end

    return Options:Get("quickSearchDefaultAppendRule");
end

local function AddValueByType(tokens, player, explicitType)
    assert(player);
    if(not explicitType) then
        return;
    end

    local newToken = nil;
    local value = nil;

    if(explicitType == "name") then
        value = GetPlayerName(player);
    elseif(explicitType == "spec") then
        value = ArenaMatch:GetPlayerSpec(player);
        if(Helpers:IsClassID(value)) then
            explicitType = "class";
        end
    elseif(explicitType == "class") then
        local spec_id = ArenaMatch:GetPlayerSpec(player);
        value = Helpers:GetClassID(spec_id);
    elseif(explicitType == "race") then
        value = ArenaMatch:GetPlayerRace(player);
    elseif(explicitType == "faction") then
        local race = ArenaMatch:GetPlayerRace(player);
        value = Internal:GetRaceFaction(race);
    end

    if(value) then
        local fakeToken = {
            value = Helpers:ToSafeLower(value),
            explicitType = explicitType,
            exact = true,
        };

        local _, _, _, shortValue = Search:FindSearchValueDataForToken(fakeToken);
        newToken = Search:CreateToken(shortValue or value);

        if(newToken) then
            tinsert(tokens, newToken);
        end
    end
end

local function GetQuickSearchTokens(player, team, btn)
    assert(player);
    local tokens = {};
    local hasValue = false;

    -- Inverse
    local shortcut = Options:Get("quickSearchAction_Inverse");
    if(CheckShortcut(shortcut, btn)) then
        local newToken = Search:CreateToken("not");
        if(newToken) then
            tinsert(tokens, newToken);
        end
    end

    -- Team
    local newSimpleTeamToken = nil;
    if(CheckShortcut(Options:Get("quickSearchAction_ClickedTeam"), btn)) then
        ArenaAnalytics:Log("Team of clicked player!", team);
        newSimpleTeamToken = Search:CreateToken(Helpers:ToSafeLower(team));
    elseif(CheckShortcut(Options:Get("quickSearchAction_Team"), btn)) then
        newSimpleTeamToken = Search:CreateToken("team");
    elseif(CheckShortcut(Options:Get("quickSearchAction_Enemy"), btn)) then
        newSimpleTeamToken = Search:CreateToken("enemy");
    end

    if(newSimpleTeamToken) then
        tinsert(tokens, newSimpleTeamToken);
    end

    -- Name
    shortcut = Options:Get("quickSearchAction_Name");
    if(CheckShortcut(shortcut, btn)) then
        AddValueByType(tokens, player, "name");
        hasValue = true;
    end

    -- Spec
    shortcut = Options:Get("quickSearchAction_Spec");
    if(CheckShortcut(shortcut, btn)) then
        AddValueByType(tokens, player, "spec");
        hasValue = true;
    end

    -- Race
    shortcut = Options:Get("quickSearchAction_Race");
    if(CheckShortcut(shortcut, btn)) then
        AddValueByType(tokens, player, "race");
        hasValue = true;
    end
    
    -- Faction
    shortcut = Options:Get("quickSearchAction_Faction");
    if(CheckShortcut(shortcut, btn)) then
        AddValueByType(tokens, player, "faction");
        hasValue = true;
    end

    if(not hasValue) then
        local explicitType = Options:Get("quickSearchDefaultValue");
        AddValueByType(tokens, player, Helpers:ToSafeLower(explicitType));
    end

    return tokens;
end

local function DoesTokenMatchName(existingToken, newName)
    assert(existingToken and newName);
    if(existingToken.explicitType ~= "name") then
        return false;
    end

    local existingName = Helpers:ToSafeLower(existingToken.value);

    if(existingToken.value == newName) then
        return true, true;
    end

    if(not existingToken.exact) then
        local isPartialMatch = newName:find(existingName, 1, true) ~= nil;
        return isPartialMatch, false;
    end

    return false;
end

local function FindExistingNameMatch(segments, newName)
    assert(segments);

    if(not newName or newName == "" or type(newName) ~= "string") then
        return nil, nil;
    end

    for i,segment in ipairs(segments) do
        for j,currentToken in ipairs(segment.tokens) do
            -- Compare name with current 
            local isMatch, isExact = DoesTokenMatchName(currentToken, newName);
            if(isMatch) then
                return i, j, isExact;
            end
        end
    end
end

local function RemoveSeparatorFromTokens(tokens)
    assert(tokens);

    for i=#tokens, 1, -1 do
        local token = tokens[i];
        
        if(token and token.isSeparator) then
            table.remove(tokens, i);
        end
    end
end

local function TokensContainExact(existingTokens, token)
    assert(existingTokens and token);

    for index,existingToken in ipairs(existingTokens) do
        if(existingToken.explicitType == token.explicitType and existingToken.value == token.value) then
            return true;
        end
    end
    
    return false;
end

local function DoesAllTokensMatchExact(segment, tokens, skipName)
    if(not segment or not tokens) then
        return false;
    end

    for _,token in ipairs(tokens) do
        if(not skipName or token.explicitType ~= "name") then
            if(not TokensContainExact(segment.tokens, token)) then
                return false;
            end    
        end
    end

    return true;
end

local locked = nil;
function Search:QuickSearch(playerFrame, mouseButton)
    if(not Options:Get("quickSearchEnabled")) then
        ArenaAnalytics:Log("QuickSearch: Disabled");
        return;
    end

    if(not playerFrame or not playerFrame.player) then
        ArenaAnalytics:Log("QuickSearch: invalid player frame");
        return;
    end

    if(locked) then
        return;
    end
    locked = true;

    team = playerFrame.isEnemyTeam and "enemy" or "team";
    local appendRule = GetAppendRule(mouseButton);
    local tokens = GetQuickSearchTokens(playerFrame.player, team, mouseButton);

    if(not tokens or #tokens == 0) then
        ArenaAnalytics:Log("QuickSearch: No tokens.");
        return;
    end

    -- Current Search Data
    local currentSegments = Search:GetCurrentSegments();

    if(appendRule == "New Search") then
        if(#currentSegments == 1 and DoesAllTokensMatchExact(currentSegments[1], tokens)) then
            Search:CommitEmptySearch();
            locked = false;
            return;
        end

        currentSegments = {};
    end

    local newSegment = {}
    local segmentIndex = 0;

    -- Check for name match
    local nameMatch = nil;
    local newName = nil;
    for _,token in ipairs(tokens) do
        if(token.explicitType == "name") then
            newName = token.value;
        end
    end

    if(newName) then
        local matchedSegmentIndex, matchedTokenIndex, isExactNameMatch = FindExistingNameMatch(currentSegments, newName);
        if(matchedSegmentIndex and matchedTokenIndex) then
            if(isExactNameMatch) then
                -- If all tokens match, and this was an existing named match, then remove the entire segment
                if(DoesAllTokensMatchExact(currentSegments[matchedSegmentIndex], tokens, true)) then
                    -- Remove separator from new last segment, if we are about to remove last segment
                    if(matchedSegmentIndex > 1 and matchedSegmentIndex == #currentSegments) then
                        local previousSegment = currentSegments[matchedSegmentIndex - 1];
                        if(previousSegment) then
                            RemoveSeparatorFromTokens(previousSegment.tokens);
                        end
                    end

                    table.remove(currentSegments, matchedSegmentIndex);

                    Search:CommitQuickSearch(currentSegments);
                    return;
                end

                nameMatch = "exact";
            else
                nameMatch = "partial";
            end
        end

        segmentIndex = matchedSegmentIndex;
    end

    if(not nameMatch) then
        if(#currentSegments > 0 and appendRule == "New Segment") then
            local newSeparatorToken = Search:CreateSymbolToken(', ', true);
            tinsert(currentSegments[#currentSegments].tokens, newSeparatorToken);
        end

        if(#currentSegments == 0 or appendRule ~= "Same Segment") then
            tinsert(currentSegments, Search:GetEmptySegment());
        end

        segmentIndex = #currentSegments;
    end

    Search:CommitQuickSearch(currentSegments, segmentIndex, tokens, appendRule, nameMatch);
end

function Search:CommitQuickSearch(currentSegments, segmentIndex, newTokens, appendRule, nameMatch)
    if(segmentIndex and newTokens) then
        -- For each new token, add, remove or replace based on type and value match
        for i,token in ipairs(newTokens) do
            if(token.explicitType and token.raw) then
                assert(token.explicitType and token.explicitType ~= "");
                assert(currentSegments[segmentIndex]);

                local isUniqueToken = true;

                local existingTokens = currentSegments[segmentIndex].tokens;
                for tokenIndex = #existingTokens, 1, -1 do
                    local existingToken = existingTokens[tokenIndex];

                    if(existingToken.explicitType == token.explicitType) then
                        isUniqueToken = false;
                        
                        -- Different values, replace with the new token
                        if(existingToken.value ~= token.value) then
                            existingTokens[tokenIndex] = token;
                        elseif(nameMatch ~= "partial" and token.explicitType ~= "name" and not (nameMatch or appendRule == "Same Segment")) then
                            table.remove(existingTokens, tokenIndex);
                        end
                        break;
                    end
                end

                -- If the token type is unique
                if(isUniqueToken) then
                    if(#existingTokens > 0) then
                        local newSpaceToken = Search:CreateSymbolToken(' ');
                        tinsert(existingTokens, newSpaceToken);
                    end

                    -- Add the new token
                    tinsert(existingTokens, token);
                end
            end
        end
    end

    Search:SetCurrentData(currentSegments);
    Search:CommitSearch();
    
    locked = false;
end