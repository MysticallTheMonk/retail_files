--@curseforge-project-slug: libkeystone@
if WOW_PROJECT_ID ~= 1 then return end -- Retail

local LKS = LibStub:NewLibrary("LibKeystone", 3)
if not LKS then return end -- No upgrade needed

LKS.callbackMap = LKS.callbackMap or {}
LKS.frame = LKS.frame or CreateFrame("Frame")
LKS.isGuildHidden = LKS.isGuildHidden or false

local callbackMap = LKS.callbackMap
local type, error = type, error

do
	local result = C_ChatInfo.RegisterAddonMessagePrefix("LibKS")
	-- 0=success, 1=duplicate, 2=invalid, 3=toomany
	if type(result) == "number" and result > 1 then
		error("LibKeystone: Failed to register the addon prefix.")
	end
end

function LKS.Register(addon, func)
	if type(addon) ~= "table" or addon == LKS then
		error("LibKeystone: The function lib.Register expects your own addon object as the first arg.")
	end

	local t = type(func)
	if t == "function" then
		callbackMap[addon] = func
	else
		error("LibKeystone: The function lib.Register expects your own function as the second arg.")
	end
end

function LKS.Unregister(addon)
	if type(addon) ~= "table" or addon == LKS then
		error("LibKeystone: The function lib.Unregister expects your own addon object.")
	end
	callbackMap[addon] = nil
end

function LKS.SetGuildHidden(isHidden)
	if type(isHidden) ~= "boolean" then
		error("LibKeystone: The function lib.SetGuildHidden expects a boolean value.")
	end
	LKS.isGuildHidden = isHidden
end

local GetInfo
do
	local GetOwnedKeystoneLevel, GetOwnedKeystoneMapID = C_MythicPlus.GetOwnedKeystoneLevel, C_MythicPlus.GetOwnedKeystoneMapID
	local GetPlayerMythicPlusRatingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary
	function GetInfo()
		-- Keystone level
		local keyLevel = GetOwnedKeystoneLevel()
		if type(keyLevel) ~= "number" then
			keyLevel = 0
		end
		-- Keystone instance ID
		local keyMap = GetOwnedKeystoneMapID()
		if type(keyMap) ~= "number" then
			keyMap = 0
		end
		-- M+ rating
		local playerRatingSummary = GetPlayerMythicPlusRatingSummary("player")
		local playerRating = 0
		if type(playerRatingSummary) == "table" and type(playerRatingSummary.currentSeasonScore) == "number" then
			playerRating = playerRatingSummary.currentSeasonScore
		end
		return keyLevel, keyMap, playerRating
	end
end

local SendAddonMessage, CTimerNewTimer = C_ChatInfo.SendAddonMessage, C_Timer.NewTimer
local GetTime = GetTime
local next = next
local throttleTime = 3 -- Seconds
do
	local throttleTable = {
		GUILD = 0,
		PARTY = 0,
	}
	local timerTable = {}
	local functionTable
	local tonumber, match, format = tonumber, string.match, string.format
	local Ambiguate = Ambiguate

	do
		local function SendToParty()
			if timerTable.PARTY then
				timerTable.PARTY:Cancel()
				timerTable.PARTY = nil
			end
			local keyLevel, keyMap, playerRating = GetInfo()
			local result = SendAddonMessage("LibKS", format("%d,%d,%d", keyLevel, keyMap, playerRating), "PARTY")
			if result == 9 then
				timerTable.PARTY = CTimerNewTimer(throttleTime, SendToParty)
			end
		end
		local function SendToGuild()
			if timerTable.GUILD then
				timerTable.GUILD:Cancel()
				timerTable.GUILD = nil
			end
			local keyLevel, keyMap, playerRating = GetInfo()
			if keyLevel ~= 0 and LKS.isGuildHidden then
				keyLevel, keyMap = -1, -1
			end
			local result = SendAddonMessage("LibKS", format("%d,%d,%d", keyLevel, keyMap, playerRating), "GUILD")
			if result == 9 then
				timerTable.GUILD = CTimerNewTimer(throttleTime, SendToGuild)
			end
		end
		functionTable = {
			PARTY = SendToParty,
			GUILD = SendToGuild,
		}
	end

	LKS.frame:SetScript("OnEvent", function(_, _, prefix, msg, channel, sender)
		if prefix == "LibKS" and throttleTable[channel] then
			if msg == "R" then
				local t = GetTime()
				if t - throttleTable[channel] > throttleTime then
					throttleTable[channel] = t
					functionTable[channel]()
				elseif not timerTable[channel] then
					timerTable[channel] = CTimerNewTimer(throttleTime, functionTable[channel])
				end
				return
			end

			local keyLevelStr, keyMapStr, playerRatingStr = match(msg, "^(%d+),(%d+),(%d+)$")
			if keyLevelStr and keyMapStr and playerRatingStr then
				local keyLevel = tonumber(keyLevelStr)
				local keyMap = tonumber(keyMapStr)
				local playerRating = tonumber(playerRatingStr)
				if keyLevel and keyMap and playerRating then
					for _,func in next, callbackMap do
						func(keyLevel, keyMap, playerRating, Ambiguate(sender, "none"), channel)
					end
				end
			end
		end
	end)
	LKS.frame:RegisterEvent("CHAT_MSG_ADDON")
end

do
	local throttleSendTable = {
		GUILD = 0,
		PARTY = 0,
	}
	local statusCheckTable = {
		GUILD = IsInGuild,
		PARTY = IsInGroup,
	}
	local timers = {}
	local pName = UnitNameUnmodified("player")
	function LKS.Request(channel)
		if not throttleSendTable[channel] then
			error("LibKeystone: The function lib.Request expects a channel type of PARTY or GUILD.")
		else
			local keyLevel, keyMap, playerRating = GetInfo()
			if keyLevel ~= 0 and LKS.isGuildHidden and channel == "GUILD" then
				keyLevel, keyMap = -1, -1
			end
			for _,func in next, callbackMap do
				func(keyLevel, keyMap, playerRating, pName, channel) -- This allows us to show our own stats when not grouped
			end
			if statusCheckTable[channel]() then
				local t = GetTime()
				if t - throttleSendTable[channel] > throttleTime then
					if timers[channel] then
						timers[channel]:Cancel()
						timers[channel] = nil
					end
					throttleSendTable[channel] = t
					SendAddonMessage("LibKS", "R", channel)
				elseif not timers[channel] then
					timers[channel] = CTimerNewTimer((throttleTime+0.1)-(t-throttleSendTable[channel]), function() LKS.Request(channel) end)
				end
			end
		end
	end
end
