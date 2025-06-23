local _, ArenaAnalytics = ...; -- Addon Namespace
local Selection = ArenaAnalytics.Selection;

-- Local module aliases
local Options = ArenaAnalytics.Options;
local AAtable = ArenaAnalytics.AAtable;
local ArenaMatch = ArenaAnalytics.ArenaMatch;

------------------------------------------------------------------

Selection.selectedGames = {}

-- Initialize latestSelectionInfo and latestMultiSelect
local latestSelectionInfo = {
    ["isDeselecting"] = false,
    ["start"] = {
        ["index"] = nil,
        ["isSessionSelect"] = false
    },
    ["end"] = {
        ["index"] = nil,
        ["isSessionSelect"] = false
    }
}

Selection.latestMultiSelect = {}
Selection.latestDeselect = {}

local function IsValidMatch(index)
    return ArenaAnalytics:GetFilteredMatch(index) ~= nil;
end

local function selectMatchByIndex(index, autoCommit, isDeselect)
    autoCommit = autoCommit or IsControlKeyDown();
    if(ArenaAnalytics:GetFilteredMatch(index) ~= nil) then
        if (isDeselect) then
            if autoCommit then
                Selection.selectedGames[index] = nil;
            else
                Selection.latestDeselect[index] = true;
            end
        else
            Selection.latestDeselect[index] = nil;
            if autoCommit then
                Selection.selectedGames[index] = true;
            else
                Selection.latestMultiSelect[index] = true;
            end
        end
    end
end

local function resetLatestSelection(keepStart, resetDeselectState)
    if (keepStart) then
        latestSelectionInfo["end"]["index"] = nil;
        latestSelectionInfo["end"]["isSessionSelect"] = false;
    else
        latestSelectionInfo["start"] = {
            ["index"] = nil,
            ["isSessionSelect"] = false
        }
        latestSelectionInfo["end"] = {
            ["index"] = nil,
            ["isSessionSelect"] = false
        }
    end

    if (resetDeselectState) then
        latestSelectionInfo["isDeselecting"] = false;
        Selection.latestDeselect = {}
    end

    Selection.latestMultiSelect = {}
end
resetLatestSelection();

local function getMultiSelectStart()
    -- return index/session and boolean for isSessionSelect for the start. Nil when invalid
    if(latestSelectionInfo["start"]) then
        return latestSelectionInfo["start"]["index"], latestSelectionInfo["start"]["isSessionSelect"];
    end
    return nil, nil;
end

local function getMultiSelectEnd()
    -- return index/session and boolean for isSessionSelect for the end. Nil when invalid
    if(latestSelectionInfo["end"]) then
        return latestSelectionInfo["start"]["index"], latestSelectionInfo["start"]["isSessionSelect"];
    end
    return nil, nil;
end

-- returns true if two given indices are for matches with the same session. False if either is nil.
function Selection:isMatchesSameSession(index, otherIndex)
    local match = ArenaAnalytics:GetFilteredMatch(index);
    local otherMatch = ArenaAnalytics:GetFilteredMatch(otherIndex);
    if(match == nil or otherMatch == nil) then
        return false;
    end

    return ArenaMatch:GetSession(match) == ArenaMatch:GetSession(otherMatch);
end

function Selection:isMatchSelected(matchIndex)
    return (not Selection.latestDeselect[matchIndex] and (Selection.selectedGames[matchIndex] or Selection.latestMultiSelect[matchIndex])) or false;
end

-- Helper function to select a range of matches
local function selectRange(startIndex, endIndex, includeStartSession, includeEndSession, isDeselect)
    assert(startIndex);
    assert(endIndex);

    local minIndex = min(startIndex, endIndex);
    local maxIndex = max(startIndex, endIndex);

    if(not IsValidMatch(minIndex) or not IsValidMatch(maxIndex)) then
        ArenaAnalytics:Log("Invalid filtered match index in selectRange! Selection ignored..");
        return;
    end

    local startSession = ArenaMatch:GetSession(ArenaAnalytics:GetFilteredMatch(startIndex));
    local endSession = ArenaMatch:GetSession(ArenaAnalytics:GetFilteredMatch(endIndex));
    
    for i = minIndex, maxIndex do
        -- Skip matches that belong to the same session as the start and end index,
        -- unless includeStartSession or includeEndSession is true
        local session = ArenaMatch:GetSession(ArenaAnalytics:GetFilteredMatch(i));
        local isStartSession = session == startSession;
        local isEndSession = session == endSession;
        if ((includeStartSession and (isStartSession or not isEndSession)) or (includeEndSession and isEndSession)) then
            selectMatchByIndex(i, false, isDeselect);
        end
    end
end

-- Helper function to select or deselect a session by index
local function selectSessionByIndex(index, autoCommit, isDeselect)
    if(not IsValidMatch(index)) then
        ArenaAnalytics:Log("Invalid filtered match index in selectSessionByIndex! Selection ignored..");
        return;
    end

    local clickedMatch = ArenaAnalytics:GetFilteredMatch(index);
    local session = ArenaMatch:GetSession(clickedMatch);
    if(not session) then
        return;
    end

    -- Select or deselect the match at the given index using selectMatchByIndex
    selectMatchByIndex(index, autoCommit, isDeselect);

    -- Table with delta values
    local deltas = {-1, 1}

    -- Nested for loops to expand in both directions until reaching a match with a different session
    for _, delta in ipairs(deltas) do
        local i = index + delta
        local potentialMatch = ArenaAnalytics:GetFilteredMatch(i)
        while session == ArenaMatch:GetSession(potentialMatch) do
            selectMatchByIndex(i, autoCommit, isDeselect);
            i = i + delta;
            potentialMatch = ArenaAnalytics:GetFilteredMatch(i);
        end
    end
end 

-- Clears current selection of matches
function Selection:ClearSelectedMatches()
    Selection.selectedGames = {}
    Selection.latestMultiSelect = {}
    resetLatestSelection(false, true);

    -- Update UI
    AAtable:UpdateSelected();
    AAtable:RefreshLayout();
end

local function commitLatestSelections()
    for i in pairs(Selection.latestMultiSelect) do
        Selection.selectedGames[i] = true;
    end
    
    for i in pairs(Selection.latestDeselect) do
        Selection.selectedGames[i] = nil;
        Selection.latestMultiSelect[i] = nil;
    end
    Selection.latestMultiSelect = {}
    Selection.latestDeselect = {}
end

local function clearLatestSelections()
    Selection.latestMultiSelect = {}
    Selection.latestDeselect = {}
end

-- Main function to handle click events on match entries
function Selection:handleMatchEntryClicked(key, isDoubleClick, index)    
    if(not IsValidMatch(index)) then
        ArenaAnalytics:Log("Invalid filtered match index in handleMatchEntryClicked! Selection ignored..");
        return;
    end

    -- whether we're changing the endpoint of a multiselect
    local startIndex = latestSelectionInfo["start"] and latestSelectionInfo["start"]["index"] or nil;
    local isStartSessionSelect = latestSelectionInfo["start"] and latestSelectionInfo["start"]["isSessionSelect"];
    local selectedByStartSession = isStartSessionSelect and Selection:isMatchesSameSession(index, startIndex);

    local changeMultiSelectEndpoint = IsShiftKeyDown() and tonumber(startIndex) ~= nil and not selectedByStartSession;

    local isDeselect;
    if(changeMultiSelectEndpoint) then
        isDeselect = latestSelectionInfo["isDeselecting"]
    else
        isDeselect = (key == "RightButton") or Selection:isMatchSelected(index) or false;
    end

    -- If Ctrl is not pressed, clear the previous selection and latestMultiSelect.
    local isControlModInversed = Options:Get("selectionControlModInversed") or false;
    if (IsControlKeyDown() == isControlModInversed) and not IsShiftKeyDown() then
        Selection.selectedGames = {}
        resetLatestSelection(true);
    end

    -- Single or session select? (Single vs double click)
    local isSessionSelect = isDoubleClick or IsAltKeyDown();
    
    if (isDeselect ~= latestSelectionInfo["isDeselecting"]) then
        latestSelectionInfo["isDeselecting"] = isDeselect or false;
    end
    
    -- Clear the last uncommitted multiselect endpoint and selection
    if (changeMultiSelectEndpoint) then
        clearLatestSelections();
        latestSelectionInfo["end"]["index"] = nil;
        latestSelectionInfo["end"]["isSessionSelect"] = false;
    else -- Commit previous multiselect
        commitLatestSelections();
    end
    
    -- Update selection
    if changeMultiSelectEndpoint then
        selectRange(startIndex, index, true, not isSessionSelect, isDeselect) -- Select range between start and current index
        if (isSessionSelect) then
            selectSessionByIndex(index, false, isDeselect);
        end
        latestSelectionInfo["end"]["index"] = index -- Update the end point of multi-select.
        latestSelectionInfo["end"]["isSessionSelect"] = isSessionSelect -- Update whether it's a session select.
    else -- change start point
        if (isSessionSelect) then
            selectSessionByIndex(index, true, isDeselect) -- Select session by index
        else
            selectMatchByIndex(index, true, isDeselect) -- Select match by index
        end
        
        latestSelectionInfo["start"]["index"] = index -- Update the start point of multi-select.
        latestSelectionInfo["start"]["isSessionSelect"] = isSessionSelect -- Set this to false as we're selecting a single match now.
    end

    -- Update UI
    AAtable:UpdateSelected();
    AAtable:RefreshLayout();
end