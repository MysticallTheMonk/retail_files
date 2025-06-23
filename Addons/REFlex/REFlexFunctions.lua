local _, RE = ...
local L = LibStub("AceLocale-3.0"):GetLocale("REFlex")
local BR = LibStub("LibBabble-Race-3.0"):GetReverseLookupTable()
local ST = LibStub("ScrollingTable")
local QTIP = LibStub("LibQTip-1.0")
local DUMP = LibStub("LibTextDump-1.0")

local tinsert, tsort, tconcat, tremove = table.insert, table.sort, table.concat, table.remove
local mfloor, min, mfmod = math.floor, math.min, math.fmod
local sgsub, sbyte, slower, srep = string.gsub, string.byte, string.lower, string.rep
local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo
local GetHonorRewardInfo = C_PvP.GetHonorRewardInfo
local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local GetConquestWeeklyProgress = C_WeeklyRewards.GetConquestWeeklyProgress
local GetSecondsUntilWeeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset
local PanelTemplates_GetSelectedTab = PanelTemplates_GetSelectedTab
local IsActiveBattlefieldArena = IsActiveBattlefieldArena
local IsInBrawl = C_PvP.IsInBrawl
local CanSurrenderArena = CanSurrenderArena
local SurrenderArena = SurrenderArena
local StaticPopup_Hide = StaticPopup_Hide

function RE:GetPlayerData(databaseID)
	return RE.Database[databaseID].Players[RE.Database[databaseID].PlayerNum]
end

function RE:GetPlayerWin(databaseID, icon)
	if RE.Database[databaseID].isSoloShuffle then
		if icon then
			return "|TInterface\\RaidFrame\\ReadyCheck-Waiting:14:14:0:0|t"
		else
			return nil
		end
	elseif RE.Database[databaseID].PlayerSide == RE.Database[databaseID].Winner then
		if icon then
			return "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t"
		else
			return true
		end
	else
		if icon then
			return "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14:0:0|t"
		else
			return false
		end
	end
end

function RE:GetPlayerKD(databaseID)
	local playerData = RE:GetPlayerData(databaseID)
	local deaths = playerData[4]
	if deaths == 0 then
		deaths = 1
	end
	return RE:Round(playerData[3]/deaths, 2)
end

function RE:GetMMR(databaseID, player, csv)
	local faction = RE:GetFactionID(databaseID, player) + 1
	if RE.Database[databaseID].isRated then
		if RE.Database[databaseID].isSoloShuffle then
			if player then
				return RE.Database[databaseID].TeamData[1][4]
			else
				return RE.Database[databaseID].TeamData[2][4]
			end
		else
			return RE.Database[databaseID].TeamData[faction][4]
		end
	else
		if csv then
			return 0
		else
			return "-"
		end
	end
end

function RE:GetArenaTeamIcons(databaseID, player)
	if RE.Database[databaseID].isSoloShuffle and not player then
		return srep("|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12:0:0|t", RE.Database[databaseID].PlayerStats[1])..srep("|TInterface\\RaidFrame\\ReadyCheck-NotReady:12:12:0:0|t", (6 - RE.Database[databaseID].PlayerStats[1]))
	end
	local faction = RE:GetFactionID(databaseID, player)
	local teamRaw, team = {}, {}
	local iconSize = 20
	if RE.Database[databaseID].isSoloShuffle then
		iconSize = 10
	end
	for i=1, #RE.Database[databaseID].Players do
		if RE.Database[databaseID].Players[i][6] == faction or RE.Database[databaseID].isSoloShuffle then
			tinsert(teamRaw, RE.Database[databaseID].Players[i][9])
		end
	end
	tsort(teamRaw)
	for i=1, #teamRaw do
		tinsert(team, RE:GetClassIcon(teamRaw[i], iconSize))
	end
	return tconcat(team, " ")
end

function RE:GetArenaTeamDetails(databaseID, player)
	local faction = RE:GetFactionID(databaseID, player)
	local team, damageSum, healingSum = {}, 0, 0
	for i=1, #RE.Database[databaseID].Players do
		if RE.Database[databaseID].Players[i][6] == faction or RE.Database[databaseID].isSoloShuffle then
			damageSum = damageSum + RE.Database[databaseID].Players[i][10]
			healingSum = healingSum + RE.Database[databaseID].Players[i][11]
			tinsert(team, {RE:GetRaceIcon(RE.Database[databaseID].Players[i][7], 30).."   "..RE:GetClassIcon(RE.Database[databaseID].Players[i][9], 30),
			"|c"..RAID_CLASS_COLORS[RE.Database[databaseID].Players[i][9]].colorStr..RE:NameClean(RE.Database[databaseID].Players[i][1]).."|r",
			"|c"..RAID_CLASS_COLORS[RE.Database[databaseID].Players[i][9]].colorStr..RE.Database[databaseID].Players[i][16].."|r",
			RE:AbbreviateNumbers(RE.Database[databaseID].Players[i][10]),
			RE:AbbreviateNumbers(RE.Database[databaseID].Players[i][11]),
			"|n["..RE:RatingChangeClean(RE.Database[databaseID].Players[i][13], databaseID).."]",
			RE:GetPrestigeIcon(RE.Database[databaseID].Players[i][17], 16)})
		end
	end
	while #team < 3 do
		tinsert(team, {"", "", "", "", "", "", ""})
	end
	return team, RE:AbbreviateNumbers(damageSum), RE:AbbreviateNumbers(healingSum)
end

function RE:GetArenaTeamCSV(databaseID, player)
	local faction = RE:GetFactionID(databaseID, player)
	local team = {}
	for i=1, #RE.Database[databaseID].Players do
		if RE.Database[databaseID].Players[i][6] == faction then
			tinsert(team, RE.Database[databaseID].Players[i][9].."-"..RE.Database[databaseID].Players[i][16].."-"..RE.Database[databaseID].Players[i][1])
		end
	end
	tsort(team)
	return tconcat(team, ",")
end

function RE:GetArenaTeamStats(mode)
	local teamMatrix = {}
	local payload = {}
	for i=1, #RE.TableArena.filtered do
		local databaseID = RE.TableArena.data[RE.TableArena.filtered[i]][11]
		if not RE.Database[databaseID].isSoloShuffle then
			local faction = RE:GetFactionID(databaseID, false)
			local win = RE:GetPlayerWin(databaseID, false)
			local teamID = {}
			for j=1, #RE.Database[databaseID].Players do
				if RE.Database[databaseID].Players[j][6] == faction then
					tinsert(teamID, RE.Database[databaseID].Players[j][9].."-"..RE.Database[databaseID].Players[j][16])
				end
			end
			tsort(teamID)
			---@diagnostic disable-next-line: cast-local-type
			teamID = tconcat(teamID, ";")
			if teamMatrix[teamID] then
				if win then
					teamMatrix[teamID].Count = teamMatrix[teamID].Count + 1
					teamMatrix[teamID].Win = teamMatrix[teamID].Win + 1
				else
					teamMatrix[teamID].Count = teamMatrix[teamID].Count + 1
					teamMatrix[teamID].Loss = teamMatrix[teamID].Loss + 1
				end
			else
				if win then
					teamMatrix[teamID] = {["Count"] = 1, ["Win"] = 1, ["Loss"] = 0}
				else
					teamMatrix[teamID] = {["Count"] = 1, ["Win"] = 0, ["Loss"] = 1}
				end
			end
		end
	end
	teamMatrix[""] = nil
	for t, v in pairs(teamMatrix) do
		if v.Count <= RE.Settings.ArenaStatsLimit then
			teamMatrix[t] = nil
		end
	end
	if mode == 1 then
		RE:ForeachInOrder(teamMatrix, function(t, v) if #payload < 6 then tinsert(payload, {t, v.Count, v.Win, v.Loss}) end end, function(a,b) return teamMatrix[a].Count > teamMatrix[b].Count end)
	elseif mode == 2 then
		RE:ForeachInOrder(teamMatrix, function(t, v) if #payload < 6 then tinsert(payload, {t, v.Count, v.Win, v.Loss}) end end, function(a,b) return (teamMatrix[a].Win / teamMatrix[a].Count) > (teamMatrix[b].Win / teamMatrix[b].Count) end)
	else
		RE:ForeachInOrder(teamMatrix, function(t, v) if #payload < 6 then tinsert(payload, {t, v.Count, v.Win, v.Loss}) end end, function(a,b) return (teamMatrix[a].Loss / teamMatrix[a].Count) > (teamMatrix[b].Loss / teamMatrix[b].Count) end)
	end
	return payload
end

function RE:GetRGBTeamDetails(databaseID, player)
	local faction = RE:GetFactionID(databaseID, player)
	local team, damageSum, healingSum, kbSum = {}, 0, 0, 0
	for i=1, #RE.Database[databaseID].Players do
		if RE.Database[databaseID].Players[i][6] == faction then
			damageSum = damageSum + RE.Database[databaseID].Players[i][10]
			healingSum = healingSum + RE.Database[databaseID].Players[i][11]
			kbSum = kbSum + RE.Database[databaseID].Players[i][2]
			tinsert(team, {RE:GetRaceIcon(RE.Database[databaseID].Players[i][7], 30).."   "..RE:GetClassIcon(RE.Database[databaseID].Players[i][9], 30),
			"|c"..RAID_CLASS_COLORS[RE.Database[databaseID].Players[i][9]].colorStr..RE:NameClean(RE.Database[databaseID].Players[i][1]).."|r",
			"|c"..RAID_CLASS_COLORS[RE.Database[databaseID].Players[i][9]].colorStr..RE.Database[databaseID].Players[i][16].."|r",
			RE:GetPrestigeIcon(RE.Database[databaseID].Players[i][17], 16),
			RE.Database[databaseID].Players[i][2],
			RE:AbbreviateNumbers(RE.Database[databaseID].Players[i][10]),
			RE:AbbreviateNumbers(RE.Database[databaseID].Players[i][11]),
			"|n"..RE.Database[databaseID].Players[i][12].." ["..RE:RatingChangeClean(RE.Database[databaseID].Players[i][13], databaseID).."]"})
		end
	end
	return team, RE:AbbreviateNumbers(damageSum), RE:AbbreviateNumbers(healingSum), kbSum
end

function RE:GetWinNumber(filter, arena)
	local won, lost = 0, 0
	for i=1, #RE.Database do
		if (RE.Database[i].isArena == arena or arena == nil) and not RE.Database[i].Hidden then
			local playerData = RE:GetPlayerData(i)
			if RE:FilterStats(i, playerData) then
				local win = RE:GetPlayerWin(i, false)
				if win then
					if filter == 1 or (filter == 2 and not RE.Database[i].isRated) or (filter == 3 and RE.Database[i].isRated) then
						won = won + 1
					end
				elseif win == false then
					if filter == 1 or (filter == 2 and not RE.Database[i].isRated) or (filter == 3 and RE.Database[i].isRated) then
						lost = lost + 1
					end
				else
					if filter == 1 or (filter == 2 and not RE.Database[i].isRated) or (filter == 3 and RE.Database[i].isRated) then
						won = won + RE.Database[i].PlayerStats[1]
						-- TODO: Handle better Solo Shuffles that had less than 6 rounds
						-- lost = lost + (6 - RE.Database[i].PlayerStats[1])
					end
				end
			end
		end
	end
	return won, lost
end

function RE:GetHonor()
	local honor = 0
	local from = RE.Settings.Filters.Date[1]
	local to = RE.Settings.Filters.Date[2]
	if RE.Settings.LDBMode == 1 then
		from = RE:ParseUTCTimestamp()
	elseif RE.Settings.LDBMode == 3 then
		from = RE:ParseUTCTimestamp() - (RE:GetPreviousWeeklyReset() - mfmod(RE:GetPreviousWeeklyReset(), 86400))
	end
	for t, v in pairs(RE.HDatabase) do
		if t >= from and (to == 0 or t <= to) then
			honor = honor + v
		end
	end
	return honor
end

function RE:GetSessionHonor()
	local savedFilters = RE.Settings.Filters
	RE.Settings.Filters = {["Spec"] = ALL, ["Map"] = 1, ["Bracket"] = 1, ["Date"] = {RE.SessionStart, 0}, ["Season"] = 0}
	RE.SessionHonor = RE:GetHonor()
	RE.Settings.Filters = savedFilters
end

function RE:ParseHonor(points)
	local today = RE:ParseUTCTimestamp()
	if not RE.HDatabase[today] then
		RE.HDatabase[today] = 0
	end
	RE.HDatabase[today] = RE.HDatabase[today] + points
	RE:UpdateLDB()
end

function RE:GetStats(filter, arena, skipLatest)
	local ili = #RE.Database
	local kb, topKB, hk, topHK, honor, topHonor, damage, topDamage, healing, topHealing = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	if skipLatest then
		ili = ili - 1
	end
	for i=1, ili do
		if (RE.Database[i].isArena == arena or arena == nil) and not RE.Database[i].Hidden then
			if filter == 1 or (filter == 2 and not RE.Database[i].isRated) or (filter == 3 and RE.Database[i].isRated) then
				local playerData = RE:GetPlayerData(i)
				if RE:FilterStats(i, playerData) then
					kb = kb + playerData[2]
					hk = hk + playerData[3]
					honor = honor + playerData[5]
					if RE.Database[i].Time > RE.LastSquash then
						damage = damage + playerData[10]
						healing = healing + playerData[11]
					end
					if playerData[2] > topKB then
						topKB = playerData[2]
					end
					if playerData[3] > topHK then
						topHK = playerData[3]
					end
					if playerData[5] > topHonor then
						topHonor = playerData[5]
					end
					if RE.Database[i].Time > RE.LastSquash then
						if playerData[10] > topDamage then
							topDamage = playerData[10]
						end
						if playerData[11] > topHealing then
							topHealing = playerData[11]
						end
					end
				end
			end
		end
	end
	return kb, topKB, hk, topHK, honor, topHonor, damage, topDamage, healing, topHealing
end

function RE:GetBGPlace(matchData, onlyFaction)
	local placeKB, placeHK, placeHonor, placeDamage, placeHealing = 1, 1, 1, 1, 1
	local playerData = matchData.Players[matchData.PlayerNum]
	for i=1, #matchData.Players do
		if matchData.Players[i][1]:lower() ~= RE.PlayerName and (not onlyFaction or (onlyFaction and matchData.Players[i][6] == matchData.PlayerSide)) then
			if playerData[2] < matchData.Players[i][2] then
				placeKB = placeKB + 1
			end
			if playerData[3] < matchData.Players[i][3] then
				placeHK = placeHK + 1
			end
			if playerData[5] < matchData.Players[i][5] then
				placeHonor = placeHonor + 1
			end
			if playerData[10] < matchData.Players[i][10] then
				placeDamage = placeDamage + 1
			end
			if playerData[11] < matchData.Players[i][11] then
				placeHealing = placeHealing + 1
			end
		end
	end
	return placeKB, placeHK, placeHonor, placeDamage, placeHealing
end

function RE:GetBGComposition(matchData, player)
	local tank, healer, dps, faction = 0, 0, 0, nil
	if player then
		faction = matchData.PlayerSide
	else
		faction = 1 - matchData.PlayerSide
	end
	for i=1, #matchData.Players do
		if matchData.Players[i][6] == faction and matchData.Players[i][9] ~= nil then
			local role = RE.Roles[matchData.Players[i][9]][matchData.Players[i][16]]
			if role == "TANK" then
				tank = tank + 1
			elseif role == "HEALER" then
				healer = healer + 1
			else
				dps = dps + 1
			end
		end
	end
	return tank, healer, dps
end

function RE:GetMercenaryStatus(databaseID)
	return not (RE.Database[databaseID].PlayerSide == RE.PlayerFaction)
end

function RE:GetBGScoreText(databaseID)
	local text = {}
	local savedFilters = RE.Settings.Filters
	RE.Settings.Filters = {["Spec"] = ALL, ["Map"] = RE.Database[databaseID].Map, ["Bracket"] = 1, ["Date"] = {0, 0}, ["Season"] = 0}
	local playerData = RE:GetPlayerData(databaseID)
	local placeKB, placeHK, placeHonor, placeDamage, placeHealing = unpack(RE.Database[databaseID].BGPlace[2])
	local _, topKB, _, topHK, _, topHonor, _, topDamage, _, topHealing = RE:GetStats(1, false, true)
	RE.Settings.Filters = savedFilters
	tinsert(text, RE:ScoreTextParser("KB", playerData[2], databaseID, placeKB, topKB))
	tinsert(text, RE:ScoreTextParser("HK", playerData[3], databaseID, placeHK, topHK))
	tinsert(text, RE:ScoreTextParser(HONOR, playerData[5], databaseID, placeHonor, topHonor))
	tinsert(text, RE:ScoreTextParser(DAMAGE, playerData[10], databaseID, placeDamage, topDamage))
	tinsert(text, RE:ScoreTextParser(SHOW_COMBAT_HEALING, playerData[11], databaseID, placeHealing, topHealing))
	return tconcat(text, " |cFF808080|||r ")
end

function RE:GetArenaStatsTooltip(mode)
	if #RE.TableArena.filtered > 0 then
		local payload = RE:GetArenaTeamStats(mode)
		RE.Tooltip = QTIP:Acquire("REFlexTooltipArena", 1, "CENTER")
		RE.Tooltip:SmartAnchorTo(REFlexFrame_StatsButton)
		if mode == 1 then
			RE.Tooltip:AddHeader("|cFF74D06C"..L["Most common teams"].."|r")
		elseif mode == 2 then
			RE.Tooltip:AddHeader("|cFF74D06C"..L["Easiest teams"].."|r")
		else
			RE.Tooltip:AddHeader("|cFF74D06C"..L["Hardest teams"].."|r")
		end
		RE.Tooltip:AddLine()
		RE.Tooltip:AddLine()
		for _, v in pairs(payload) do
			local members = {strsplit(";", v[1])}
			for i=1, #members do
				local class, spec = strsplit("-", members[i])
				RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[class]:GenerateHexColor()..LOCALIZED_CLASS_NAMES_MALE[class].." "..spec.."|r")
			end
			if mode == 1 then
				RE.Tooltip:AddLine("|cFFFFFFFF"..v[2].."|r | |cFF00FF00"..v[3].."|r - |cFFFF0000"..v[4].."|r")
			elseif mode == 2 then
				RE.Tooltip:AddLine("|cFF00FF00"..v[3].."|r - |cFFFF0000"..v[4].."|r | |cFFFFFFFF"..v[2])
			else
				RE.Tooltip:AddLine("|cFFFF0000"..v[4].."|r - |cFF00FF00"..v[3].."|r | |cFFFFFFFF"..v[2])
			end
			RE.Tooltip:AddLine()
		end
		RE.Tooltip:Show()
	end
end

function RE:GetFactionID(databaseID, player)
	if player then
		return RE.Database[databaseID].PlayerSide
	else
		return 1 - RE.Database[databaseID].PlayerSide
	end
end

function RE:GetMapName(mapID)
	local map = RE.MapList[mapID]
	if map then
		return map
	else
		return "E"..mapID
	end
end

function RE:GetShortMapName(mapName)
	local mapNameTemp = {strsplit(" ", mapName)}
	local mapShortName = ""
	for i=1, #mapNameTemp do
		mapShortName = mapShortName..RE:StrSub(mapNameTemp[i],0,1)
	end
	return mapShortName
end

function RE:GetMapColor(_, realrow, _, table)
	if RE.Database[table.data[realrow][11]].isRated then
		return {["r"] = 0.52,
		["g"] = 1.0,
		["b"] = 0.52,
		["a"] = 1.0}
	elseif RE.Database[table.data[realrow][11]].isBrawl then
		return {["r"] = 1.0,
		["g"] = 0.98,
		["b"] = 0.72,
		["a"] = 1.0}
	elseif RE:GetMercenaryStatus(table.data[realrow][11]) then
		if RE.PlayerFaction == 0 then
			return {["r"] = 0,
			["g"] = 0.66,
			["b"] = 1.0,
			["a"] = 1.0}
		else
			return {["r"] = 1.0,
			["g"] = 0.08,
			["b"] = 0.11,
			["a"] = 1.0}
		end
	else
		return {["r"] = 1.0,
		["g"] = 1.0,
		["b"] = 1.0,
		["a"] = 1.0}
	end
end

function RE:GetMapColorArena(_, realrow, _, table)
	local win = RE:GetPlayerWin(table.data[realrow][11], false)
	if win then
		return {["r"] = 0,
		["g"] = 1.0,
		["b"] = 0,
		["a"] = 1.0}
	elseif win == false then
		return {["r"] = 1.0,
		["g"] = 0,
		["b"] = 0,
		["a"] = 1}
	else
		return {["r"] = 1.0,
		["g"] = 1.0,
		["b"] = 0,
		["a"] = 1}
	end
end

function RE:GetClassIcon(token, size)
	return "|A:classicon-"..slower(token)..":"..size..":"..size.."|a"
end

function RE:GetRaceIcon(token, size)
	if RE.RaceIcons[token] ~= nil then
		return "|A:"..RE.RaceIcons[token]..":"..size..":"..size.."|a"
	elseif BR[token] == nil then
		return "|TInterface\\Icons\\INV_Misc_QuestionMark:"..size..":"..size.."|t"
	else
		return "|A:"..RE.RaceIcons[sgsub(BR[token], "_PL", "")]..":"..size..":"..size.."|a"
	end
end

function RE:GetPrestigeIcon(level, size)
	local hLevelData = GetHonorRewardInfo(level)
	if hLevelData and hLevelData.badgeFileDataID then
		return "|T"..hLevelData.badgeFileDataID..":"..size..":"..size..":0:0|t"
	else
		return ""
	end
end

function RE:NameClean(name)
	if RE.Settings.ShowServerName then
		return name
	else
		return strsplit("-", name)
	end
end

function RE:RatingChangeClean(change, databaseID)
	if change > 0 then
		return "|cFF00FF00+"..change.."|r"
	elseif change < 0 then
		return "|cFFFF141C"..change.."|r"
	else
		if not databaseID or RE.Database[databaseID].isRated then
			return "0"
		else
			return "-"
		end
	end
end

function RE:DateClean(timeRaw)
	-- Barbarian friendly
	if RE.PlayerZone == "US" and not RE.Settings.ForceCivilisedClock then
		return date("%I:%M %p %m/%d/%y", timeRaw + (RE.PlayerTimezone * 3600))
	else
		return date("%H:%M %d.%m.%y", timeRaw + (RE.PlayerTimezone * 3600))
	end
end

function RE:TimeClean(timeRaw, isSoloShuffle)
	if isSoloShuffle then
		return "-"
	end
	local timeSec = mfloor(timeRaw % 60)
	local timeMin = mfloor(timeRaw / 60)
	if timeSec < 10 then
		---@diagnostic disable-next-line: cast-local-type
		timeSec = "0"..timeSec
	end
	return timeMin..":"..timeSec
end

function RE:CustomSort(obj, rowa, rowb, sortbycol, field, inside)
	local column = obj.cols[sortbycol]
	local direction = column.sort or column.defaultsort or ST.SORT_ASC
	local rowA, rowB
	if inside > 0 then
		rowA = obj.data[rowa][inside]
		rowB = obj.data[rowb][inside]
	else
		rowA = RE.Database[obj.data[rowa][11]][field]
		rowB = RE.Database[obj.data[rowb][11]][field]
	end
	if rowA == rowB then
		return false
	else
		if direction == ST.SORT_ASC then
			return rowA > rowB
		else
			return rowA < rowB
		end
	end
end

function RE:SpecFilter(rowdata)
	if RE.Settings.Filters.Spec ~= ALL then
		if rowdata[14] == RE.Settings.Filters.Spec then
			return true
		else
			return false
		end
	else
		return true
	end
end

function RE:MapFilter(rowdata)
	if RE.Settings.Filters.Map ~= 1 then
		if RE.Database[rowdata[11]].Map == RE.Settings.Filters.Map then
			return true
		else
			return false
		end
	else
		return true
	end
end

function RE:BracketFilter(rowdata)
	if RE.Database[rowdata[11]].isArena and RE.Settings.Filters.Bracket ~= 1 then
		if RE.Settings.Filters.Bracket == 2 then
			return RE.Database[rowdata[11]].isSoloShuffle
		else
			if RE.Database[rowdata[11]].PlayersNum == RE.Settings.Filters.Bracket and not RE.Database[rowdata[11]].isSoloShuffle then
				return true
			else
				return false
			end
		end
	else
		return true
	end
end

function RE:DateFilter(rowdata)
	local from = RE.Settings.Filters.Date[1]
	local to = RE.Settings.Filters.Date[2]
	if from > 0 or to > 0 then
		if RE.Database[rowdata[11]].Time >= from and (to == 0 or RE.Database[rowdata[11]].Time <= to) then
			return true
		else
			return false
		end
	else
		if RE.Settings.Filters.Season > 0 then
			if RE.Database[rowdata[11]].Season == RE.Settings.Filters.Season then
				return true
			else
				return false
			end
		else
			return true
		end
	end
end

function RE:FilterDefault(rowdata)
	return not RE.Database[rowdata[11]].Hidden and RE:SpecFilter(rowdata) and RE:MapFilter(rowdata) and RE:BracketFilter(rowdata) and RE:DateFilter(rowdata)
end

function RE:FilterCasual(rowdata)
	return not RE.Database[rowdata[11]].Hidden and not RE.Database[rowdata[11]].isRated and RE:SpecFilter(rowdata) and RE:MapFilter(rowdata) and RE:BracketFilter(rowdata) and RE:DateFilter(rowdata)
end

function RE:FilterRated(rowdata)
	return not RE.Database[rowdata[11]].Hidden and RE.Database[rowdata[11]].isRated and RE:SpecFilter(rowdata) and RE:MapFilter(rowdata) and RE:BracketFilter(rowdata) and RE:DateFilter(rowdata)
end

function RE:FilterStats(id, playerdata)
	local data = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, id, 0, 0, playerdata[16], 0}
	return not RE.Database[data[11]].Hidden and RE:SpecFilter(data) and RE:MapFilter(data) and RE:BracketFilter(data) and RE:DateFilter(data)
end

function RE:CalendarParser()
	if RE.CalendarMode == 1 then
		local t = {day = CalendarFrame.selectedDay, month = CalendarFrame.selectedMonth, year = CalendarFrame.selectedYear, hour = 0}
		PlaySound(624)
		RE.Settings.Filters.Date[1] = time(t) - (RE.PlayerTimezone * 3600)
		RE.CalendarMode = 2
	elseif RE.CalendarMode == 2 then
		local t = {day = CalendarFrame.selectedDay, month = CalendarFrame.selectedMonth, year = CalendarFrame.selectedYear, hour = 23, min = 59, sec = 59}
		PlaySound(624)
		RE.Settings.Filters.Date[2] = time(t) - (RE.PlayerTimezone * 3600)
		CalendarFrame:Hide()
		RE:UpdateGUI()
	end
end

function RE:CalendarCleanup()
	RE.CalendarMode = 0
	StaticPopup_Hide("REFLEX_CUSTOMDATE")
end

function RE:HKBarUpdate()
	local hk = select(4, GetAchievementCriteriaInfo(5363, 1))
	local hkMax = 0
	if hk < 100 then
		hkMax = 100
	elseif hk < 500 then
		hkMax = 500
	elseif hk < 1000 then
		hkMax = 1000
	elseif hk < 5000 then
		hkMax = 5000
	elseif hk < 10000 then
		hkMax = 10000
	elseif hk < 25000 then
		hkMax = 25000
	elseif hk < 50000 then
		hkMax = 50000
	elseif hk < 100000 then
		hkMax = 100000
	elseif hk < 250000 then
		hkMax = 250000
	end
	if hkMax ~= 0 then
		REFlexFrame_HKBar_Text:SetText(hk.." / "..hkMax)
		REFlexFrame_HKBar_I:SetMinMaxValues(0, hkMax)
	else
		REFlexFrame_HKBar_Text:SetText(hk)
		REFlexFrame_HKBar_I:SetMinMaxValues(0, hk)
	end
	REFlexFrame_HKBar_I:SetValue(hk)
end

function RE:ScoreTextParser(label, value, databaseID, place, top)
	local text = {}
	tinsert(text, "|cFF90EE90"..label..":|r |cFFFFFFFF"..RE:AbbreviateNumbers(value).." - "..place.."/"..RE.Database[databaseID].PlayersNum.."|r")
	if value > top then
		tinsert(text, " |TInterface\\GroupFrame\\UI-Group-LeaderIcon:14:14:0:0|t")
	end
	return tconcat(text, "")
end

function RE:HideEntry(databaseID)
	RE.Database[databaseID].Hidden = true
	RE:UpdateGUI()
end

function RE:SeasonPurge()
	if RE.Season < 1 then return end
	local toWipe = {}
	for i=1, #RE.Database do
		if RE.Database[i].Season ~= RE.Season then
			tinsert(toWipe, i)
		end
	end
	RE:DatabasePurge(toWipe)
end

function RE:HiddenPurge()
	local currentTime = RE:GetUTCTimestamp()
	local toWipe = {}
	for i=1, #RE.Database do
		if RE.Database[i].Hidden and currentTime - RE.Database[i].Time > 604800 then
			tinsert(toWipe, i)
		end
	end
	RE:DatabasePurge(toWipe)
end

function RE:DatabasePurge(idTable)
	local wipeI = 0
	for i=1, #idTable do
		local wipeID = idTable[i] - wipeI
		tremove(RE.Database, wipeID)
		wipeI = wipeI + 1
	end
end

function RE:DumpCSV()
	local id, d, s
	if not REFlexFrame:IsShown() then return end
	RE.DumpFrame:Clear()
	if PanelTemplates_GetSelectedTab(REFlexFrame) < 4 then
		RE.DumpFrame:AddLine("Timestamp;Map;Duration;Victory;KillingBlows;HonorKills;Deaths;Damage;Healing;Honor;RatingChange;MMR;EnemyMMR;Specialization;PrestigeLevel;isRated;isBrawl;isMercenary")
		for i=1, #RE.TableBG.filtered do
			id = RE.TableBG.data[RE.TableBG.filtered[i]][11]
			d = RE.Database[id]
			s = RE:GetPlayerData(id)
			RE.DumpFrame:AddLine(tostring(d.Time)..";"..tostring(d.Map)..";"..tostring(d.Duration)..";"..tostring(RE:GetPlayerWin(id, false))..";"..
			tostring(s[2])..";"..tostring(s[3])..";"..tostring(s[4])..";"..tostring(s[10])..";"..tostring(s[11])..";"..tostring(s[5])..";"..tostring(s[13])..";"..tostring(RE:GetMMR(id, true, true))..";"..
			tostring(RE:GetMMR(id, false, true))..";"..tostring(s[16])..";"..tostring(s[17])..";"..tostring(d.isRated)..";"..tostring(d.isBrawl)..";"..tostring(RE:GetMercenaryStatus(id)))
		end
	else
		RE.DumpFrame:AddLine("Timestamp;Map;PlayersNumber;TeamComposition;EnemyComposition;Duration;Victory;KillingBlows;Damage;Healing;Honor;RatingChange;MMR;EnemyMMR;Specialization;isRated")
		for i=1, #RE.TableArena.filtered do
			id = RE.TableArena.data[RE.TableArena.filtered[i]][11]
			if not RE.Database[id].isSoloShuffle then
				d = RE.Database[id]
				s = RE:GetPlayerData(id)
				RE.DumpFrame:AddLine(tostring(d.Time)..";"..tostring(d.Map)..";"..tostring(d.PlayersNum)..";"..RE:GetArenaTeamCSV(id, true)..";"..RE:GetArenaTeamCSV(id, false)..";"..tostring(d.Duration)..";"..
				tostring(RE:GetPlayerWin(id, false))..";"..tostring(s[2])..";"..tostring(s[10])..";"..tostring(s[11])..";"..tostring(s[5])..";"..tostring(s[13])..";"..tostring(RE:GetMMR(id, true, true))..";"..tostring(RE:GetMMR(id, false, true))..";"..tostring(s[16])..";"..tostring(d.isRated))
			end
		end
	end
	RE.DumpFrame:Display()

	if RE.IsSkinned then
		local f = DUMP.frames[RE.DumpFrame]:GetName()
		AddOnSkins[1]:SkinFrame(_G[f])
		AddOnSkins[1]:CreateBackdrop(_G[f].scrollArea)
		AddOnSkins[1]:SetOutside(_G[f].scrollArea.Backdrop, _G[f].scrollArea, 4, 4)
		AddOnSkins[1]:SkinCloseButton(_G[f.."Close"])
		AddOnSkins[1]:SkinScrollBar(_G[f].scrollArea.ScrollBar)
	end
end

function RE:GetConquestPoints()
	local currencyInfo = GetCurrencyInfo(Constants.CurrencyConsts.CONQUEST_CURRENCY_ID)
	if currencyInfo then
		return min(currencyInfo.totalEarned, currencyInfo.maxQuantity), currencyInfo.maxQuantity
	else
		return 0, 0
	end
end

function RE:GetWeeklyChest()
	local progress = GetConquestWeeklyProgress()
	if progress then
		local weeklyStatus = {}
		for _=1, progress.unlocksCompleted do
			tinsert(weeklyStatus, "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t")
		end
		for _=1, progress.maxUnlocks - progress.unlocksCompleted do
			tinsert(weeklyStatus, "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t")
		end
		return progress.progress, progress.maxProgress, tconcat(weeklyStatus, " ")
	else
		return 0, 0, ""
	end
end

function RE:GetPreviousWeeklyReset()
	local timeToNextWeeklyReset = GetSecondsUntilWeeklyReset()
	return 604800 - timeToNextWeeklyReset
end

function RE:GetUTCTimestamp(timezone)
	local d1 = date("*t")
	local d2 = date("!*t")
	d2.isdst = d1.isdst
	local utc = time(d2)
	if timezone then
		local player = time(d1)
		return utc, RE:Round((player - utc) / 3600, 0)
	else
		return utc
	end
end

function RE:ParseUTCTimestamp(month)
	local d1 = date("*t")
	local d2 = date("!*t")
	d2.isdst = d1.isdst
	if month then
		return time(d2) - (86400 * (d2.day - 1)) - (3600 * d2.hour) - (60 * d2.min) - d2.sec
	else
		return time(d2) - (3600 * d2.hour) - (60 * d2.min) - d2.sec
	end
end

function RE:SurrenderMatch()
	if IsActiveBattlefieldArena() and not IsInBrawl() and CanSurrenderArena() then
		SurrenderArena()
	end
end

function RE:Round(num, idp)
	local mult = 10^(idp or 0)
	return mfloor(num * mult + 0.5) / mult
end

function RE:AbbreviateNumbers(value)
	if value >= 10000000000 then
		value = RE:Round(value / 1000000000, 1).."B"
	elseif value >= 1000000000 then
		value = RE:Round(value / 1000000000, 2).."B"
	elseif value >= 100000000 then
		value = RE:Round(value / 1000000, 1).."M"
	elseif value >= 1000000 then
		value = RE:Round(value / 1000000, 2).."M"
	elseif value >= 1000 then
		value = RE:Round(value / 1000, 0).."K"
	end
	return value
end

function RE:CSize(char)
	if not char then
		return 0
	elseif char > 240 then
		return 4
	elseif char > 225 then
		return 3
	elseif char > 192 then
		return 2
	else
		return 1
	end
end

function RE:StrSub(str, startChar, numChars)
	local startIndex = 1
	while startChar > 1 do
		local char = sbyte(str, startIndex)
		startIndex = startIndex + RE:CSize(char)
		startChar = startChar - 1
	end
	local currentIndex = startIndex
	while numChars > 0 and currentIndex <= #str do
		local char = sbyte(str, currentIndex)
		currentIndex = currentIndex + RE:CSize(char)
		numChars = numChars -1
	end
	return str:sub(startIndex, currentIndex - 1)
end

function RE:ForeachInOrder(t, f, cmp)
	local keys = {}
	for k, _ in pairs(t) do
		keys[#keys + 1] = k
	end
	tsort(keys,cmp)
	for _, k in ipairs(keys) do
		f(k, t[k])
	end
end

function REFlex_CompartmentOnClick(_, button)
	REFlex_CompartmentClick = true
	RE.LDB:OnClick(button)
end

function REFlex_CompartmentOnEnter(_, frame)
	RE.LDB:OnEnter(frame)
end

function REFlex_CompartmentOnLeave()
	RE.LDB:OnLeave()
end
