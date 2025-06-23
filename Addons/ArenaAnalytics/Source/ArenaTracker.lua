local _, ArenaAnalytics = ... -- Namespace
local ArenaTracker = ArenaAnalytics.ArenaTracker;

-- Local module aliases
local AAmatch = ArenaAnalytics.AAmatch;
local Constants = ArenaAnalytics.Constants;
local SpecSpells = ArenaAnalytics.SpecSpells;
local API = ArenaAnalytics.API;
local Helpers = ArenaAnalytics.Helpers;
local Internal = ArenaAnalytics.Internal;
local Localization = ArenaAnalytics.Localization;
local Inspection = ArenaAnalytics.Inspection;
local Events = ArenaAnalytics.Events;
local TablePool = ArenaAnalytics.TablePool;
local Debug = ArenaAnalytics.Debug;

-------------------------------------------------------------------------

-- Arena variables
local currentArena = {}

function ArenaTracker:GetCurrentArena()
	return currentArena;
end

-- Reset current arena values
function ArenaTracker:Reset()
	ArenaAnalytics:Log("Resetting current arena values..");

	-- Current Arena
	currentArena.battlefieldId = nil;
	currentArena.mapId = nil;

	currentArena.playerName = "";

	currentArena.startTime = nil;
	currentArena.hasRealStartTime = nil;
	currentArena.endTime = nil;

	currentArena.oldRating = nil;
	currentArena.seasonPlayed = nil;
	currentArena.requireRatingFix = nil;

	currentArena.partyRating = nil;
	currentArena.partyRatingDelta = nil;
	currentArena.partyMMR = nil;

	currentArena.enemyRating = nil;
	currentArena.enemyRatingDelta = nil;
	currentArena.enemyMMR = nil;

	currentArena.size = nil;
	currentArena.isRated = nil;
	currentArena.isShuffle = nil;

	currentArena.players = TablePool:Acquire();

	currentArena.ended = false;
	currentArena.endedProperly = false;
	currentArena.outcome = nil;

	currentArena.round = TablePool:Acquire();
	currentArena.committedRounds = TablePool:Acquire();

	currentArena.deathData = TablePool:Acquire();

	-- Current Round
	currentArena.round.hasStarted = nil;
	currentArena.round.startTime = nil;
	currentArena.round.team = TablePool:Acquire();

	ArenaAnalyticsDB.currentArena = currentArena;
end

function ArenaTracker:Clear()
	ArenaAnalytics:Log("Clearing current arena.");

	ArenaAnalyticsDB.currentArena = nil;
	currentArena = {};
end

-------------------------------------------------------------------------
-- Solo Shuffle

-- Get current player wins and all players summed wins
function ArenaTracker:GetCurrentWins()
	if(not currentArena.isShuffle) then
		return;
	end

	local myWins, totalWins = 0,0;
	for i=1, GetNumBattlefieldScores() do
		local score = API:GetPlayerScore(i);
		if(score and score.wins) then
			if(score.name == currentArena.playerName) then
				myWins = score.wins;
			end

			totalWins = totalWins + score.wins;
		end
	end

	return myWins, totalWins;
end

function ArenaTracker:UpdateRoundTeam()
	if(not currentArena.isShuffle) then
		return;
	end

	if(ArenaTracker:IsSameRoundTeam()) then
		ArenaAnalytics:Log("Still same team, round team update delayed.");
		return;
	end

	TablePool:Release(currentArena.round.team)
	currentArena.round.team = TablePool:Acquire();
	for i=1, 2 do
		local name = Helpers:GetUnitFullName("party"..i);
		tinsert(currentArena.round.team, name);
		ArenaAnalytics:Log("Adding team player:", name, #currentArena.round.team);
	end

	ArenaAnalytics:Log("UpdateRoundTeam", #currentArena.round.team);
end

function ArenaTracker:RoundTeamContainsPlayer(playerName)
	if(not currentArena.isShuffle) then
		return;
	end

	if(not playerName) then
		return nil;
	end

	for _,teamMember in ipairs(currentArena.round.team) do
		if(teamMember == playerName) then
			return true;
		end
	end

	return playerName == Helpers:GetPlayerName();
end

function ArenaTracker:IsSameRoundTeam()
	if(not currentArena.isShuffle) then
		return nil;
	end

	for i=1, 2 do
		local unitName = Helpers:GetUnitFullName("party"..i);

		if(unitName and not ArenaTracker:RoundTeamContainsPlayer(unitName)) then
			return false;
		end
	end

	return true;
end

function ArenaTracker:CommitCurrentRound(force)
	if(not currentArena.isShuffle) then
		return;
	end

	if(not currentArena.round.hasStarted) then
		return;
	end

	ArenaAnalytics:LogGreen("CommitCurrentRound triggered!")

	-- Delay commit until team has changed, unless match ended.
	if(not force and ArenaTracker:IsSameRoundTeam() and not GetBattlefieldWinner()) then
		ArenaAnalytics:LogGreen("Delaying round commit. Team has not yet changed.");
		return;
	end

	local startTime = currentArena.round.startTime;
	local death, endTime = ArenaTracker:GetFirstDeathFromCurrentArena();
	endTime = endTime or time();

	-- Get death stats, then wipe the deaths to avoid double counting
	ArenaTracker:CommitDeaths();
	wipe(currentArena.deathData);

	local roundData = {
		duration = startTime and (endTime - startTime) or nil,
		firstDeath = death,
		team = {},
		enemy = {},
	};

	-- Get the total wins after current round
	local myWins, totalWins = ArenaTracker:GetCurrentWins();
	if(myWins == currentArena.round.wins and totalWins == currentArena.round.totalWins) then
		ArenaAnalytics:LogGreen("Neither wins changed since last round. Assuming draw.");
		roundData.outcome = 2;
	else
		local isWin = (myWins > currentArena.round.wins);
		roundData.outcome = isWin and 1 or 0;
		ArenaAnalytics:LogGreen("Outcome determined:", roundData.outcome, "New wins:", myWins, totalWins, "Old wins:", currentArena.round.wins, currentArena.round.totalWins, "Rounds played:", #currentArena.committedRounds);
	end

	-- Fill round teams
	for _,player in ipairs(currentArena.players) do
		if(player and player.name) then
			local team = ArenaTracker:RoundTeamContainsPlayer(player.name) and roundData.team or roundData.enemy;
			tinsert(team, player.name);
		end
	end

	ArenaAnalytics:LogGreen("Committed round:!", roundData.duration, roundData.firstDeath, #roundData.team, #roundData.enemy, #currentArena.players);
	tinsert(currentArena.committedRounds, roundData);

	-- Reset currentArena round data
	currentArena.deathData = TablePool:Acquire();

	-- Reset current round
	currentArena.round.team = {};
	currentArena.round.startTime = nil;
	currentArena.round.hasStarted = false;

	currentArena.round.wins = myWins;
	currentArena.round.totalWins = totalWins;

	-- Make sure we update the team, if we're not done playing.
	if(not GetBattlefieldWinner()) then
		ArenaAnalytics:LogGreen("Round commit forcing team update!");
		ArenaTracker:UpdateRoundTeam();
	end
end

-------------------------------------------------------------------------

-- Is tracking player, supports GUID, name and unitToken
function ArenaTracker:IsTrackingPlayer(playerID)
	return (ArenaTracker:GetPlayer(playerID) ~= nil);
end

function ArenaTracker:IsTrackingArena()
	return currentArena.mapId ~= nil;
end

function ArenaTracker:GetArenaEndedProperly()
	return currentArena.endedProperly;
end

-- TEMP (?)
function ArenaTracker:SetNotEnded()
	currentArena.ended = false;
end

function ArenaTracker:HasMapData()
	return currentArena.mapId ~= nil;
end

function ArenaTracker:GetPlayer(playerID)
	if(not playerID or playerID == "") then
		return nil;
	end

	if(currentArena.players) then
		for i = 1, #currentArena.players do
			local player = currentArena.players[i];
			if (player) then
				if(Helpers:ToSafeLower(player.name) == Helpers:ToSafeLower(playerID)) then
					return player;
				elseif(player.GUID == playerID) then
					return player;
				else -- Unit Token
					local GUID = UnitGUID(playerID);
					if(GUID and GUID == player.GUID) then
						return player;
					end
				end
			end
		end
	end

	return nil;
end

function ArenaTracker:HasSpec(GUID)
	local player = ArenaTracker:GetPlayer(GUID);
	return player and Helpers:IsSpecID(player.spec);
end

function ArenaTracker:GetShuffleOutcome()
	if(currentArena.committedRounds) then
		local wins = 0;

        -- Iterate through all the rounds
        for _, round in ipairs(currentArena.committedRounds) do
            -- Check if firstDeath exists
            if(round.firstDeath) then
                for _, enemyPlayer in ipairs(round.enemy) do
                    if enemyPlayer == round.firstDeath then
                        wins = wins + 1;
						break;
                    end
                end
            end
        end

        if(wins == 3) then
			-- Draw
			return 2; 
		else
			return wins > 3 and 1 or 0;
		end
	end

	return nil;
end

function ArenaTracker:IsTrackingCurrentArena(battlefieldId, bracket)
	if(not API:IsInArena()) then
		ArenaAnalytics:Log("IsTrackingCurrentArena: Not in arena.")
		return false;
	end
	
	local arena = ArenaAnalyticsDB.currentArena;
	if(not arena) then
		ArenaAnalytics:Log("IsTrackingCurrentArena: No existing arena.", arena, ArenaAnalyticsDB.currentArena);
		return false;
	end

	if(arena.bracketIndex ~= bracket) then
		ArenaAnalytics:Log("IsTrackingCurrentArena: New bracket.");
		return false;
	end

	if(arena.battlefieldId ~= battlefieldId) then
		ArenaAnalytics:Log("IsTrackingCurrentArena: New battlefield id.");
		return false;
	end

	if(arena.isRated) then
		if(not arena.seasonPlayed) then
			ArenaAnalytics:Log("IsTrackingCurrentArena: Existing rated arena has no season played.", arena.seasonPlayed)
			return false;
		end

		local _, seasonPlayed = API:GetPersonalRatedInfo(bracket);
		local trackedSeasonPlayed = arena.seasonPlayed - (arena.endedProperly and 1 or 0);
		if(not seasonPlayed or seasonPlayed ~= trackedSeasonPlayed) then
			ArenaAnalytics:Log("IsTrackingCurrentArena: Invalid season played, or mismatch to tracked value.", seasonPlayed, arena.seasonPlayed)
			return false;
		end
	end

	ArenaAnalytics:Log("IsTrackingCurrentArena: Arena alrady tracked")
	return true;
end

-- Begins capturing data for the current arena
-- Gets arena player, size, map, ranked/skirmish
function ArenaTracker:HandleArenaEnter()
	if(ArenaTracker:IsTrackingArena()) then
		ArenaAnalytics:Log("HandleArenaEnter: Already tracking arena");
		return;
	end

	Events:RegisterArenaEvents();

	-- Retrieve current arena info
	local battlefieldId = API:GetActiveBattlefieldID();
	if(not battlefieldId) then
		return;
	end

	local status, bracket, teamSize, isRated, isShuffle = API:GetBattlefieldStatus(battlefieldId);

	if(not ArenaTracker:IsTrackingCurrentArena(battlefieldId, bracket)) then
		ArenaTracker:Reset();
	else
		ArenaAnalytics:Log("Keeping existing tracking!")
		currentArena = ArenaAnalyticsDB.currentArena;
	end

	currentArena.battlefieldId = battlefieldId;

	-- Bail out if it ended by now
	if (status ~= "active" or not teamSize) then
		ArenaAnalytics:Log("HandleArenaEnter bailing out. Status:", status, "Team Size:", teamSize);
		return false
	end

	-- Update start time immediately, might be overridden by gates open if it hasn't happened yet.
	if(not currentArena.hasRealStartTime) then
		currentArena.startTime = time();
	end

	if(not currentArena.battlefieldId) then
		ArenaAnalytics:Log("ERROR: Invalid Battlefield ID in HandleArenaEnter");
	end

	currentArena.playerName = Helpers:GetPlayerName();

	currentArena.bracketIndex = bracket;
	currentArena.isRated = isRated;
	currentArena.isShuffle = isShuffle;
	currentArena.size = teamSize;

	ArenaAnalytics:Log("TeamSize:", teamSize, currentArena.size, "Bracket:", currentArena.bracketIndex);

	if(isRated) then
		local oldRating, seasonPlayed = API:GetPersonalRatedInfo(currentArena.bracketIndex);
		if(GetBattlefieldWinner()) then
			currentArena.seasonPlayed = seasonPlayed and seasonPlayed - 1; -- Season Played during the match
		else
			currentArena.oldRating = oldRating;
			currentArena.seasonPlayed = seasonPlayed;
		end
	end

	-- Add self
	if (not ArenaTracker:IsTrackingPlayer(currentArena.playerName)) then
		-- Add player
		local GUID = UnitGUID("player");
		local name = currentArena.playerName;
		local race_id = Helpers:GetUnitRace("player");
		local class_id = Helpers:GetUnitClass("player");
		local spec_id = API:GetSpecialization() or class_id;
		ArenaAnalytics:Log("Using MySpec:", spec_id);

		local player = ArenaTracker:CreatePlayerTable(false, GUID, name, race_id, spec_id);
		table.insert(currentArena.players, player);
	end

	if(ArenaAnalytics.DataSync) then
		ArenaAnalytics.DataSync:sendMatchGreetingMessage();
	end

	currentArena.mapId = API:GetCurrentMapID();
	ArenaAnalytics:Log("Match entered! Tracking mapId: ", currentArena.mapId);

	ArenaTracker:HandlePartyUpdate();

	RequestBattlefieldScoreData();
end

-- Gates opened, match has officially started
function ArenaTracker:HandleArenaStart(...)
	currentArena.startTime = time();
	currentArena.hasRealStartTime = true; -- The start time has been set by gates opened

	local myWins, totalWins = ArenaTracker:GetCurrentWins();
	currentArena.round.wins = myWins;
	currentArena.round.totalWins = totalWins;
	ArenaAnalytics:LogGreen("Assigned round wins:", myWins, totalWins);

	ArenaTracker:FillMissingPlayers();
	ArenaTracker:HandleOpponentUpdate();
	ArenaTracker:HandlePartyUpdate();
	ArenaTracker:UpdateRoundTeam();

	currentArena.round.startTime = time();
	currentArena.round.hasStarted = true;

	ArenaAnalytics:LogGreen("Match started!", API:GetCurrentMapID(), GetZoneText(), #currentArena.players);
end

function ArenaTracker:CheckRoundEnded()
	if(not API:IsInArena() or not currentArena.isShuffle) then
		return;
	end

	if(not ArenaTracker:IsTrackingArena() or not currentArena.round.hasStarted) then
		ArenaAnalytics:Log("CheckRoundEnded called while not tracking arena, or without active shuffle round.", currentArena.round.hasStarted);
		return;
	end

	-- Check if this is a new round
	if(#currentArena.round.team ~= 2) then
		ArenaAnalytics:Log("CheckRoundEnded missing players.");
		return;
	end

	-- Team remains same, thus round has not changed.
	if(ArenaTracker:IsSameRoundTeam()) then
		ArenaAnalytics:Log("CheckRoundEnded has same team.");
		return;
	end

	ArenaAnalytics:Log("CheckRoundEnded");
	ArenaTracker:HandleRoundEnd();
end

-- Solo Shuffle specific round end
function ArenaTracker:HandleRoundEnd(force)
	if(not API:IsInArena() or not currentArena.isShuffle) then
		return;
	end

	ArenaAnalytics:Log("HandleRoundEnd!", #currentArena.players);

	ArenaTracker:CommitCurrentRound(force);
end

-- Gets arena information when it ends and the scoreboard is shown
-- Matches obtained info with previously collected player values
function ArenaTracker:HandleArenaEnd()
	currentArena.endedProperly = true;
	currentArena.ended = true;
	currentArena.endTime = time();

	ArenaAnalytics:Log("HandleArenaEnd!", #currentArena.players);

	-- Solo Shuffle
	ArenaTracker:HandleRoundEnd(true);

	local winner = GetBattlefieldWinner();
	local players = {};

	-- Figure out how to default to nil, without failing to count losses.
	local myTeamIndex = nil;

	local firstDeath = ArenaTracker:GetFirstDeathFromCurrentArena();
	ArenaTracker:CommitDeaths();
	wipe(currentArena.deathData);

	for i=1, GetNumBattlefieldScores() do
		local score = API:GetPlayerScore(i);

		-- Find or add player
		local player = ArenaTracker:GetPlayer(score.name);
		if(not player) then
			-- Use scoreboard info
			ArenaAnalytics:Log("Creating new player by scoreboard:", score.name);
			player = ArenaTracker:CreatePlayerTable(nil, nil, score.name);
		end

		-- Fill missing data
		player.teamIndex = score.team;
		player.spec = Helpers:IsSpecID(player.spec) and player.spec or score.spec;
		player.race = player.race or score.race;
		player.kills = score.kills;
		player.deaths = API.trustScoreboardDeaths and score.deaths or player.deaths or 0;
		player.damage = score.damage;
		player.healing = score.healing;

		if(currentArena.isRated) then
			player.rating = score.rating;
			player.ratingDelta = score.ratingDelta;
			player.mmr = score.mmr;
			player.mmrDelta = score.mmrDelta;
		end

		if(currentArena.isShuffle) then
			player.wins = score.wins or 0;
		end

		if(player.name) then
			-- First Death
			if(not currentArena.isShuffle and player.name == firstDeath) then
				player.isFirstDeath = true;
			end

			if (player.name == currentArena.playerName) then
				myTeamIndex = player.teamIndex;
				player.isSelf = true;
			elseif(currentArena.isShuffle) then
				player.isEnemy = true;
			end

			table.insert(players, player);
		else
			ArenaAnalytics:Log("Tracker: Invalid player name, player will not be stored!");
		end

		TablePool:Release(score);
	end

	if(currentArena.isShuffle) then
		-- Determine match outcome
		currentArena.outcome = ArenaTracker:GetShuffleOutcome()
	else
		-- Assign isEnemy value
		for _,player in ipairs(players) do
			if(player and player.teamIndex) then
				player.isEnemy = (player.teamIndex ~= myTeamIndex);
			end
		end

		-- Assign Winner
		if(winner == 255) then
			currentArena.outcome = 2;
		elseif(winner ~= nil) then
			currentArena.outcome = (myTeamIndex == winner) and 1 or 0;
		end
	end

	-- Process ranked information
	if (currentArena.isRated and myTeamIndex) then
		local otherTeamIndex = (myTeamIndex == 0) and 1 or 0;

		currentArena.partyMMR = API:GetTeamMMR(myTeamIndex);
		currentArena.enemyMMR = API:GetTeamMMR(otherTeamIndex);
	end

	currentArena.players = players;

	ArenaAnalytics:Log("Match ended!", #currentArena.players, "players tracked.");
end

-- Player left an arena (Zone changed to non-arena with valid arena data)
function ArenaTracker:HandleArenaExit()
	assert(currentArena.size);
	assert(currentArena.mapId);

	if(Inspection and Inspection.Clear) then
		Inspection:Clear();
	end

	-- Solo Shuffle
	ArenaTracker:HandleRoundEnd(true);

	currentArena.endTime = currentArena.endTime or time();

	if(not currentArena.endedProperly) then
		currentArena.ended = true;
		currentArena.outcome = false;

		ArenaAnalytics:Log("Detected early leave. Has valid current arena: ", currentArena.mapId);
	end

	ArenaAnalytics:Log("Exited Arena:", API:GetPersonalRatedInfo(currentArena.bracketIndex));

	if(currentArena.isRated and not currentArena.partyRating) then
		local newRating, seasonPlayed = API:GetPersonalRatedInfo(currentArena.bracketIndex);
		if(newRating and seasonPlayed) then
			local oldRating = currentArena.oldRating;
			if(not oldRating) then
				local season = API:GetCurrentSeason();
				oldRating = ArenaAnalytics:GetLatestRating(currentArena.bracketIndex, season, (seasonPlayed - 1));
				ArenaAnalytics:LogWarning("Fixed missing old rating:", oldRating, currentArena.bracketIndex, season, seasonPlayed);
			end

			currentArena.partyRating = newRating;
			currentArena.partyRatingDelta = oldRating and newRating - oldRating or nil;
		else
			ArenaAnalytics:Log("Warning: Nil current rating retrieved from API upon leaving arena.");
		end

		if(currentArena.seasonPlayed) then
			if(seasonPlayed and seasonPlayed < (currentArena.seasonPlayed + 1)) then
				-- Rating has updated, no longer needed to store transient Season Played for fixup.
				currentArena.requireRatingFix = true;
			else
				ArenaAnalytics:Log("Tracker: Invalid or up to date seasonPlayed.", seasonPlayed, currentArena.seasonPlayed);
			end
		else
			ArenaAnalytics:Log("Tracker: No season played stored on currentArena");
		end
	end

	ArenaAnalytics:InsertArenaToMatchHistory(currentArena);
	ArenaTracker:Clear();
end

-- Search for missing members of group (party or arena), 
-- Adds each non-tracked player to currentArena.players table.
-- If spec and GUID are passed, include them when creating the player table
function ArenaTracker:FillMissingPlayers(unitGUID, unitSpec)
	if(not currentArena.size) then
		ArenaAnalytics:Log("FillMissingPlayers missing size.");
		return;
	end

	if(#currentArena.players >= 2*currentArena.size) then
		return;
	end

	for _,group in ipairs({"party", "arena"}) do
		for i = 1, currentArena.size do
			local unitToken = group..i;

			local name = Helpers:GetUnitFullName(unitToken);
			local player = ArenaTracker:GetPlayer(name);
			if(name and not player) then
				local GUID = UnitGUID(unitToken);
				local isEnemy = (group == "arena");
				local race_id = Helpers:GetUnitRace(unitToken);
				local class_id = Helpers:GetUnitClass(unitToken);
				local spec_id = GUID and GUID == unitGUID and tonumber(unitSpec);

				if(GUID and name) then
					player = ArenaTracker:CreatePlayerTable(isEnemy, GUID, name, race_id, (spec_id or class_id));
					table.insert(currentArena.players, player);

					if(not isEnemy and Inspection and Inspection.RequestSpec) then
						Inspection:RequestSpec(unitToken);
					end
				end
			end
		end
	end

	if(#currentArena.players == 2*currentArena.size) then
		ArenaTracker:UpdateRoundTeam();
	end
end

-- Returns a table with unit information to be placed inside arena.players
function ArenaTracker:CreatePlayerTable(isEnemy, GUID, name, race_id, spec_id, kills, deaths, damage, healing)
	return {
		["isEnemy"] = isEnemy,
		["GUID"] = GUID,
		["name"] = name,
		["race"] = race_id,
		["spec"] = spec_id,
		["kills"] = kills,
		["deaths"] = deaths,
		["damage"] = damage,
		["healing"] = healing,
	};
end

-- Called from unit actions, to remove false deaths
local function tryRemoveFromDeaths(playerGUID, spell)
	local existingData = currentArena.deathData[playerGUID];
	if(existingData ~= nil) then
		local timeSinceDeath = time() - existingData.time;

		local minimumDelay = existingData.isHunter and 2 or 10;
		if(existingData.hasKillCredit) then
			minimumDelay = minimumDelay + 5;
		end

		if(timeSinceDeath > 0) then
			ArenaAnalytics:Log("Removed death by post-death action: ", spell, " for player: ",currentArena.deathData[playerGUID].name, " Time since death: ", timeSinceDeath);
			currentArena.deathData[playerGUID] = nil;
		end
	end
end

-- Handle a player's death, through death or kill credit message
local function handlePlayerDeath(playerGUID, isKillCredit)
	if(playerGUID == nil) then
		return;
	end

	currentArena.deathData[playerGUID] = currentArena.deathData[playerGUID] or TablePool:Acquire();

	local class, race, name, realm = API:GetPlayerInfoByGUID(playerGUID);
	if(not realm or realm == "") then
		name = Helpers:ToFullName(name);
	else
		name = name .. "-" .. realm;
	end

	ArenaAnalytics:Log("Player Kill!", isKillCredit, name);

	-- Store death
	currentArena.deathData[playerGUID] = {
		time = time(), 
		name = name,
		isHunter = (class == "HUNTER") or nil,
		hasKillCredit = isKillCredit or currentArena.deathData[playerGUID].hasKillCredit,
	};

	if(currentArena.isShuffle and (isKillCredit or class ~= "HUNTER")) then
		C_Timer.After(0, ArenaTracker.HandleRoundEnd);
	end
end

-- Commits current deaths to player stats (May be overridden by scoreboard, if value is trusted for the expansion)
function ArenaTracker:CommitDeaths()
	for GUID,data in pairs(currentArena.deathData) do
		local player = ArenaTracker:GetPlayer(GUID);
		if(player and data) then
			-- Increment deaths
			player.deaths = (player.deaths or 0) + 1;
		end
	end
end

-- Fetch the real first death when saving the match
function ArenaTracker:GetFirstDeathFromCurrentArena()
	if(currentArena.deathData == nil) then
		return;
	end

	local bestKey, bestTime;
	for key,data in pairs(currentArena.deathData) do
		if(bestTime == nil or data.time < bestTime) then
			bestKey = key;
			bestTime = data.time;
		end
	end

	if(not bestKey or not currentArena.deathData[bestKey]) then
		ArenaAnalytics:Log("Death data missing from currentArena.");
		return nil;
	end

	local firstDeathData = currentArena.deathData[bestKey];
	return firstDeathData.name, firstDeathData.time;
end

function ArenaTracker:HandleOpponentUpdate()
	if (not API:IsInArena()) then
		return;
	end

	ArenaTracker:FillMissingPlayers();

	-- If API exist to get opponent spec, use it
	if(GetArenaOpponentSpec) then
		for i = 1, currentArena.size do
			local unitToken = "arena"..i;
			local player = ArenaTracker:GetPlayer(unitToken);
			if(player) then
				if(not Helpers:IsSpecID(player.spec)) then
					local spec_id = API:GetArenaPlayerSpec(i, true);
					ArenaTracker:OnSpecDetected(unitToken, spec_id);
				end
			end
		end
	end
end

function ArenaTracker:HandlePartyUpdate()
	if (not API:IsInArena()) then
		return;
	end

	ArenaTracker:FillMissingPlayers();

	for i = 1, currentArena.size do
		local unitToken = "party"..i;
		local player = ArenaTracker:GetPlayer(UnitGUID(unitToken));
		if(player and not Helpers:IsSpecID(player.spec)) then
			if(Inspection and Inspection.RequestSpec) then
				ArenaAnalytics:Log("Tracker: HandlePartyUpdate requesting spec:", unitToken);
				Inspection:RequestSpec(unitToken);
			end
		end
	end

	if(currentArena.isShuffle) then
		ArenaTracker:CheckRoundEnded();
		ArenaTracker:UpdateRoundTeam();
	end
end

-- Attempts to get initial data on arena players:
-- GUID, name, race, class, spec
function ArenaTracker:ProcessCombatLogEvent(...)
	if (not API:IsInArena()) then
		return;
	end

	-- Tracking teams for spec/race and in case arena is quitted
	local timestamp,logEventType,_,sourceGUID,_,_,_,destGUID,_,_,_,spellID,spellName = CombatLogGetCurrentEventInfo();
	if (logEventType == "SPELL_CAST_SUCCESS") then
		ArenaTracker:DetectSpec(sourceGUID, spellID, spellName);
		tryRemoveFromDeaths(sourceGUID, spellName);
	elseif(logEventType == "SPELL_AURA_APPLIED" or logEventType == "SPELL_AURA_REMOVED") then
		ArenaTracker:DetectSpec(sourceGUID, spellID, spellName);
	elseif(destGUID and destGUID:find("Player-", 1, true)) then
		-- Player Death
		if (logEventType == "UNIT_DIED") then
			handlePlayerDeath(destGUID, false);
		end
		-- Player killed
		if (logEventType == "PARTY_KILL") then
			handlePlayerDeath(destGUID, true);
		end
	end
end

function ArenaTracker:ProcessUnitAuraEvent(...)
	-- Excludes versions without spell detection included
	if(not SpecSpells or not SpecSpells.GetSpec) then
		return;
	end

	if (not API:IsInArena()) then
		return;
	end

	local unitTarget, updateInfo = ...;
	if(not updateInfo or updateInfo.isFullUpdate) then
		return;
	end

	if(updateInfo.addedAuras) then
		for _,aura in ipairs(updateInfo.addedAuras) do
			if(aura and aura.sourceUnit and aura.isFromPlayerOrPlayerPet) then
				local sourceGUID = UnitGUID(aura.sourceUnit);

				ArenaTracker:DetectSpec(sourceGUID, aura.spellId, aura.name);
			end
		end
	end
end

-- Detects spec if a spell is spec defining, attaches it to its
-- caster if they weren't defined yet, or adds a new unit with it
function ArenaTracker:DetectSpec(sourceGUID, spellID, spellName)
	if(not SpecSpells or not SpecSpells.GetSpec) then
		return;
	end

	-- Only players matter for spec detection
	if (not string.find(sourceGUID, "Player-", 1, true)) then
		return;
	end

	-- Check if spell belongs to spec defining spells
	local spec_id = SpecSpells:GetSpec(spellID);
	if (spec_id ~= nil) then
		-- Check if unit should be added
		ArenaTracker:FillMissingPlayers(sourceGUID, spec_id);
		ArenaTracker:OnSpecDetected(sourceGUID, spec_id);
	end
end

function ArenaTracker:OnSpecDetected(playerID, spec_id)
	if(not playerID or not spec_id) then
		return;
	end

	local player = ArenaTracker:GetPlayer(playerID);
	if(not player) then
		return;
	end

	if(not Helpers:IsSpecID(player.spec) or player.spec == 13) then -- Preg doesn't count as a known spec
		ArenaAnalytics:Log("Assigning spec: ", spec_id, " for player: ", player.name);
		player.spec = spec_id;
	elseif(player.spec) then
		ArenaAnalytics:Log("Tracker: Keeping old spec:", player.spec, " for player: ", player.name);
	end
end