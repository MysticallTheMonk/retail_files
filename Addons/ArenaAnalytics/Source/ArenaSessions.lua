local _, ArenaAnalytics = ...; -- Addon Namespace
local Sessions = ArenaAnalytics.Sessions;

-- Local module aliases
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local Options = ArenaAnalytics.Options;
local AAtable = ArenaAnalytics.AAtable;
local Helpers = ArenaAnalytics.Helpers;
local Debug = ArenaAnalytics.Debug;

-------------------------------------------------------------------------

function Sessions:AssignSession(match)
    assert(match);

	local session, expired = Sessions:GetLatestSession();
	local lastMatch = ArenaAnalytics:GetLastMatch();
	if (expired or not Sessions:IsMatchesSameSession(lastMatch, match)) then
		session = session + 1;
	end

	ArenaMatch:SetSession(match, session);
	ArenaAnalytics:Log("Assigned session:", session);
end

function Sessions:RecomputeSessionsForMatchHistory()
	-- Assign session to filtered matches
	local session = 1
	for i = 1, #ArenaAnalyticsDB do
		local current = ArenaAnalytics:GetMatch(i);
		local prev = ArenaAnalytics:GetMatch(i - 1);

		if(current) then
			if(prev and not Sessions:IsMatchesSameSession(prev, current)) then
				session = session + 1;
			end

			ArenaMatch:SetSession(current, session);
		end
	end
end

-- Whether the session requires a group check for the given match
local function RequiresGroupForMatch(match)
    assert(match);

    if(Options:Get("ignoreGroupForSkirmishSession")) then
        local matchType = ArenaMatch:GetMatchType(match);
        if(matchType == "skirmish") then
            return false;
        end
    end

    local bracket = ArenaMatch:GetBracket(match);
    if(bracket == "shuffle") then
        return false;
    end

    return true;
end

function Sessions:ShouldSkipMatchForSessions(match)
	-- Invalid match Check
	if(match == nil) then
		return true;
	end

	-- Invalid session Check
	if(ArenaMatch:GetSession(match) == nil) then
		return true;
	end

	-- Invalid date Check
	local date = ArenaMatch:GetDate(match);
	if(not date or date == 0) then
		return true;
	end

    if(RequiresGroupForMatch(match)) then
        -- Invalid comp check (Missing players)
        local team = ArenaMatch:GetTeam(match);
        local requiredTeamSize = ArenaMatch:GetTeamSize(match, true) or 0;
        if(not team or #team < requiredTeamSize) then
            return true;
        end
    end

	-- Don't skip
	return false; 
end

-- Returns the start and end times of the last session
function Sessions:GetLatestSessionStartAndEndTime()
	local lastSession, expired, bestStartTime, endTime = nil, true, nil, nil;

	for i=#ArenaAnalyticsDB, 1, -1 do
		local match = ArenaAnalytics:GetMatch(i);

		if(not Sessions:ShouldSkipMatchForSessions(match)) then
			local date = ArenaMatch:GetDate(match);
			local session = ArenaMatch:GetSession(match);

			if(lastSession == nil) then
				lastSession = session;

				local duration = ArenaMatch:GetDuration(match);
				local testEndTime = duration and date + duration or date;

				expired = not testEndTime or (time() - testEndTime) > 3600;
				endTime = expired and testEndTime or time();
			end

			if(lastSession == session) then
				bestStartTime = date;
			else
				break;
			end
		end
	end

	return lastSession, expired, bestStartTime, endTime;
end

-- Returns the whether last session and whether it has expired by time
function Sessions:GetLatestSession()
	for i=#ArenaAnalyticsDB, 1, -1 do
		local match = ArenaAnalytics:GetMatch(i);
		if(not Sessions:ShouldSkipMatchForSessions(match)) then
			local session = ArenaMatch:GetSession(match) or 0;
			local expired = Sessions:HasMatchSessionExpired(match);
			return session, expired;
		end
	end
	return 0, false;
end

function Sessions:HasMatchSessionExpired(match)
	if(not match) then
		return nil;
	end

	local date = ArenaMatch:GetDate(match);
	local duration = ArenaMatch:GetDuration(match) or 0;

	local endTime = date and date + duration;
	if(not endTime) then
		return true;
	end

	return (time() - endTime) > 3600;
end

-- Check if 2 arenas are in the same session
function Sessions:IsMatchesSameSession(firstArena, secondArena)
	if(not firstArena or not secondArena) then
		return false;
	end

	local date1 = ArenaMatch:GetDate(firstArena) or 0;
	local date2 = ArenaMatch:GetDate(secondArena) or 0;

	if(date2 - date1 > 3600) then
		return false;
	end

	local matchType1 = ArenaMatch:GetMatchType(firstArena);
	local matchType2 = ArenaMatch:GetMatchType(secondArena);

	if(matchType1 ~= "skirmish" or matchType2 ~= "skirmish") then	
		if(not Sessions:ArenasHaveSameParty(firstArena, secondArena)) then
			return false;
		end
	end

	return true;
end

function TeamContainsPlayer(team, player)
	if(not team or not player) then
		return nil;
	end

	local fullName = ArenaMatch:GetPlayerFullName(player, false, true);
	for _,player in ipairs(team) do
		if (ArenaMatch:IsSamePlayer(player, fullName)) then
			return true;
		end
	end

	return false;
end

-- Checks if 2 arenas have the same party members
function Sessions:ArenasHaveSameParty(arena1, arena2)
    if(not arena1 or not arena2) then
        return false;
    end

	local team1, team2 = ArenaMatch:GetTeam(arena1), ArenaMatch:GetTeam(arena2);
	if(not team1 or not team2) then
		return false;
	end

	local bracket1, bracket2 = ArenaMatch:GetBracketIndex(arena1), ArenaMatch:GetBracketIndex(arena2);
	if(bracket1 ~= bracket2) then
		return false;
	end

    if(RequiresGroupForMatch(arena1) and RequiresGroupForMatch(arena2)) then
        -- In case one team is smaller, make sure we loop through that one.
        local teamOneIsSmaller = (#team1 < #team2);
        local smallerTeam = teamOneIsSmaller and team1 or team2;
        local largerTeam = teamOneIsSmaller and team2 or team1;

        for _,player in ipairs(smallerTeam) do
            if(not TeamContainsPlayer(largerTeam, player)) then
                return false;
            end
        end
    end

    return true;
end

-------------------------------------------------------------------------
-- Session Duration (Bottom Stats)

local function handleSessionDurationTimer()
    local _,expired, startTime, endTime = Sessions:GetLatestSessionStartAndEndTime();

    isSessionTimerActive = false;

    -- Update text
    AAtable:SetLatestSessionDurationText(expired, startTime, endTime);

    if (startTime and not expired and not isSessionTimerActive) then
        local duration = endTime - startTime;
        local desiredInterval = (duration > 3600) and 60 or 1;
        isSessionTimerActive = true;
        C_Timer.After(desiredInterval, function() handleSessionDurationTimer() end);
    end
end

function Sessions:TryStartSessionDurationTimer()
    local _,expired, startTime, endTime = Sessions:GetLatestSessionStartAndEndTime();
    -- Update text
    AAtable:SetLatestSessionDurationText(expired, startTime, endTime);

    if (startTime and not expired and not isSessionTimerActive) then
        local duration = time() - startTime;
        local desiredInterval = (duration > 3600) and 60 or 1;
        local firstInterval = desiredInterval - duration % desiredInterval;
        isSessionTimerActive = true;
        C_Timer.After(firstInterval, function() handleSessionDurationTimer() end);
    end
end