
local mod, L, cap
do
	local _, core = ...
	mod, L, cap = core:NewMod()
end

do
	local UnitGUID, strsplit, GetNumGossipActiveQuests, SelectGossipActiveQuest = UnitGUID, strsplit, C_GossipInfo.GetNumActiveQuests, C_GossipInfo.SelectActiveQuest
	local tonumber, GetGossipOptions = tonumber, C_GossipInfo.GetOptions
	local GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount -- XXX 10.2.6
	local blockedIds = {
		[30907] = true, -- alliance
		[30908] = true, -- alliance
		[30909] = true, -- alliance
		[97828] = true, -- alliance (classic era)
		[97829] = true, -- alliance (classic era)
		[97830] = true, -- alliance (classic era)
		[35739] = true, -- horde
		[35740] = true, -- horde
		[35741] = true, -- horde
		[97507] = true, -- horde (classic era)
		[97508] = true, -- horde (classic era)
		[97509] = true, -- horde (classic era)
	}
	function mod:GOSSIP_SHOW()
		if not cap.db.profile.autoTurnIn then return end

		local target = UnitGUID("npc")
		if target then
			local _, _, _, _, _, id = strsplit("-", target)
			local mobId = tonumber(id)
			if mobId == 13176 or mobId == 13257 then -- Smith Regzar, Murgot Deepforge
				-- Open Quest to Smith or Murgot
				if self:GetGossipID(30904) then -- Alliance
					self:SelectGossipID(30904) -- Upgrade to seasoned units!
				elseif self:GetGossipID(30905) then -- Alliance
					self:SelectGossipID(30905) -- Upgrade to veteran units!
				elseif self:GetGossipID(30906) then -- Alliance
					self:SelectGossipID(30906) -- Upgrade to champion units!
				elseif self:GetGossipID(35736) then -- Horde
					self:SelectGossipID(35736) -- Upgrade to seasoned units!
				elseif self:GetGossipID(35737) then -- Horde
					self:SelectGossipID(35737) -- Upgrade to veteran units!
				elseif self:GetGossipID(35738) then -- Horde
					self:SelectGossipID(35738) -- Upgrade to champion units!
				-- Classic
				elseif self:GetGossipID(97833) then -- Alliance (classic era)
					self:SelectGossipID(97833) -- Upgrade to seasoned units!
				elseif self:GetGossipID(90270) then -- Alliance (WotLK classic)
					self:SelectGossipID(90270) -- Upgrade to seasoned units!
				elseif self:GetGossipID(97511) then -- Horde (classic era)
					self:SelectGossipID(97511) -- Upgrade to veteran units!
				elseif self:GetGossipID(97512) then -- Horde (classic era)
					self:SelectGossipID(97512) -- Upgrade to seasoned units!
				else
					local gossipOptions = GetGossipOptions()
					if gossipOptions[1] then
						for i = 1, #gossipOptions do
							local gossipTable = gossipOptions[i]
							if not blockedIds[gossipTable.gossipOptionID] then
								print("|cFF33FF99Capping|r: NEW ID FOUND, TELL THE DEVS!", gossipTable.gossipOptionID, mobId, gossipTable.name)
								geterrorhandler()("|cFF33FF99Capping|r: NEW ID FOUND, TELL THE DEVS! ".. tostring(gossipTable.gossipOptionID) ..", ".. mobId ..", ".. tostring(gossipTable.name))
								BasicMessageDialog.Text:SetText("Capping error, see chat for details")
								BasicMessageDialog:Show()
								return
							end
						end
					end
				end

				if GetItemCount(17422) >= 20 then -- Armor Scraps 17422
					if self:GetGossipAvailableQuestID(6781) then -- Alliance, More Armor Scraps
						self:SelectGossipAvailableQuestID(6781)
					elseif self:GetGossipAvailableQuestID(6741) then -- Horde, More Booty!
						self:SelectGossipAvailableQuestID(6741)
					elseif self:GetGossipAvailableQuestID(57318) then -- Horde, More Booty! [Specific to Korrak's Revenge]
						self:SelectGossipAvailableQuestID(57318)
					elseif self:GetGossipAvailableQuestID(57306) then -- Alliance, More Armor Scraps [Specific to Korrak's Revenge]
						self:SelectGossipAvailableQuestID(57306)
					end
				end
			elseif mobId == 13236 then -- Horde, Primalist Thurloga
				local num = GetItemCount(17306) -- Stormpike Soldier's Blood 17306
				if num > 0 then
					if GetNumGossipActiveQuests() > 0 then
						local tbl = C_GossipInfo.GetActiveQuests()
						for i = 1, #tbl do
							local questTable = tbl[i]
							print("|cFF33FF99Capping|r: NEW ACTIVE QUEST, TELL THE DEVS!", questTable.questID, mobId, questTable.title)
							geterrorhandler()("|cFF33FF99Capping|r: NEW ACTIVE QUEST, TELL THE DEVS! ".. tostring(questTable.questID) ..", ".. mobId ..", ".. tostring(questTable.title))
						end
						return
						SelectGossipActiveQuest(1)
					elseif self:GetGossipAvailableQuestID(7385) and num >= 5 then -- A Gallon of Blood
						self:SelectGossipAvailableQuestID(7385)
					elseif self:GetGossipAvailableQuestID(6801) then -- Lokholar the Ice Lord
						self:SelectGossipAvailableQuestID(6801)
					end
				end
			elseif mobId == 13442 then -- Alliance, Archdruid Renferal
				local num = GetItemCount(17423) -- Storm Crystal 17423
				if num > 0 then
					if GetNumGossipActiveQuests() > 0 then
						local tbl = C_GossipInfo.GetActiveQuests()
						for i = 1, #tbl do
							local questTable = tbl[i]
							print("|cFF33FF99Capping|r: NEW ACTIVE QUEST, TELL THE DEVS!", questTable.questID, mobId, questTable.title)
							geterrorhandler()("|cFF33FF99Capping|r: NEW ACTIVE QUEST, TELL THE DEVS! ".. tostring(questTable.questID) ..", ".. mobId ..", ".. tostring(questTable.title))
						end
						return
						SelectGossipActiveQuest(1)
					elseif self:GetGossipAvailableQuestID(7386) and num >= 5 then -- Crystal Cluster
						self:SelectGossipAvailableQuestID(7386)
					elseif self:GetGossipAvailableQuestID(6881) then -- Ivus the Forest Lord
						self:SelectGossipAvailableQuestID(6881)
					end
				end
			elseif mobId == 13577 then -- Alliance, Stormpike Ram Rider Commander
				if GetItemCount(17643) > 0 then -- Frost Wolf Hide 17643
					if self:GetGossipAvailableQuestID(7026) then
						self:SelectGossipAvailableQuestID(7026)
					else
						print("|cFF33FF99Capping|r: RAM RIDER, TELL THE DEVS! 7026 was not found!")
						geterrorhandler()("|cFF33FF99Capping|r: RAM RIDER, TELL THE DEVS! 7026 was not found!")
					end
				end
			elseif mobId == 13441 then -- Horde, Frostwolf Wolf Rider Commander
				if GetItemCount(17642) > 0 then -- Alterac Ram Hide 17642
					if self:GetGossipAvailableQuestID(7002) then
						self:SelectGossipAvailableQuestID(7002) -- Ram Hide Harnesses
					else
						print("|cFF33FF99Capping|r: WOLF RIDER, TELL THE DEVS! 7002 was not found!")
						geterrorhandler()("|cFF33FF99Capping|r: WOLF RIDER, TELL THE DEVS! 7002 was not found!")
					end
				end
			end
		end
	end
end

do
	local hasPrinted = false
	local function allowPrints()
		hasPrinted = false
	end
	local IsQuestCompletable, CompleteQuest = IsQuestCompletable, CompleteQuest
	function mod:QUEST_PROGRESS()
		if not cap.db.profile.autoTurnIn then return end
		if IsQuestCompletable() then
			CompleteQuest()
			if not hasPrinted then
				hasPrinted = true
				C_Timer.After(10, allowPrints)
				print(L.handIn)
			end
		end
	end
end

do
	local GetNumQuestRewards, GetQuestReward = GetNumQuestRewards, GetQuestReward
	function mod:QUEST_COMPLETE()
		if not cap.db.profile.autoTurnIn then return end
		if GetNumQuestRewards() == 0 then
			GetQuestReward(0)
		end
	end
end

local NewTicker = C_Timer.NewTicker
local hereFromTheStart, hasData = true, true
local stopTimer = nil
local function allow() hereFromTheStart = false end
local function stop() hereFromTheStart = true hasData = true stopTimer = nil end
--local GetScoreInfo = C_PvP.GetScoreInfo
local SendAddonMessage = C_ChatInfo.SendAddonMessage
local function AVSyncRequest()
	for i = 1, 80 do
		local _, _, _, _, _, _, _, _, _, _, damageDone = GetBattlefieldScore(i)
		if damageDone and damageDone ~= 0 then
			hereFromTheStart = true
			hasData = false
			mod:Timer(0.5, allow)
			stopTimer = NewTicker(3, stop, 1)
			SendAddonMessage("Capping", "tr", "INSTANCE_CHAT")
			return
		end
	end

	hereFromTheStart = true
	hasData = true
end

do
	local timer = nil
	local function SendAVTimers()
		timer = nil
		if IsInGroup(2) then -- We've not just ragequit
			local str = ""
			for bar in next, CappingFrame.bars do
				local poiId = bar:Get("capping:poiid")
				if poiId then
					str = string.format("%s%d-%d~", str, poiId, math.floor(bar.remaining))
				end
			end

			if str ~= "" and string.len(str) < 250 then
				SendAddonMessage("Capping", str, "INSTANCE_CHAT")
			end
		end
	end

	do
		local function Unwrap(self, ...)
			local inProgressDataTbl = {}
			for i = 1, select("#", ...) do
				local arg = select(i, ...)
				local id, remaining = strsplit("-", arg)
				if id and remaining then
					local widget, barTime = tonumber(id), tonumber(remaining)
					if widget and barTime and barTime > 5 and barTime < 245 then
						inProgressDataTbl[widget] = barTime
					end
				end
			end

			if next(inProgressDataTbl) then
				self:RestoreFlagCaptures(inProgressDataTbl, 242)
			end
		end

		local me = UnitName("player").. "-" ..GetRealmName()
		function mod:CHAT_MSG_ADDON(prefix, msg, channel, sender)
			if prefix == "Capping" and channel == "INSTANCE_CHAT" then
				if msg == "tr" and sender ~= me then -- timer request
					if hasData then -- Joined a late game, don't send data
						if timer then timer:Cancel() end
						timer = NewTicker(1, SendAVTimers, 1)
					elseif stopTimer then
						stopTimer:Cancel()
						stopTimer = NewTicker(3, stop, 1)
					end
				elseif not hereFromTheStart and sender ~= me and msg:find("~", nil, true) then
					hereFromTheStart = true
					hasData = true
					Unwrap(self, strsplit("~", msg))
				end
			end
		end
	end
end

do
	local RequestBattlefieldScoreData = RequestBattlefieldScoreData
	function mod:EnterZone(id)
		if id == 2197 then
			self:StartFlagCaptures(241) -- Korrak's Revenge (WoW 15th)
		else
			self:StartFlagCaptures(300)
		end
		self:SetupHealthCheck("11946", L.hordeBoss, "Horde Boss", 134170, "colorAlliance") -- Interface/Icons/Inv_misc_head_orc_01
		self:SetupHealthCheck("11948", L.allianceBoss, "Alliance Boss", 134159, "colorHorde") -- Interface/Icons/inv_misc_head_dwarf_01
		self:SetupHealthCheck("11947", L.galvangar, "Galvangar", 134170, "colorAlliance") -- Interface/Icons/Inv_misc_head_orc_01
		self:SetupHealthCheck("11949", L.balinda, "Balinda", 134167, "colorHorde") -- Interface/Icons/inv_misc_head_human_02
		self:SetupHealthCheck("13419", L.ivus, "Ivus", 132129, "colorAlliance") -- Interface/Icons/ability_druid_forceofnature
		self:SetupHealthCheck("13256", L.lokholar, "Lokholar", 135861, "colorHorde") -- Interface/Icons/spell_frost_summonwaterelemental
		self:RegisterEvent("CHAT_MSG_ADDON")
		self:RegisterEvent("GOSSIP_SHOW")
		self:RegisterEvent("QUEST_PROGRESS")
		self:RegisterEvent("QUEST_COMPLETE")
		RequestBattlefieldScoreData()
		self:Timer(1, function() RequestBattlefieldScoreData() end)
		self:Timer(2, AVSyncRequest)
	end
end

function mod:ExitZone()
	self:UnregisterEvent("GOSSIP_SHOW")
	self:UnregisterEvent("QUEST_PROGRESS")
	self:UnregisterEvent("QUEST_COMPLETE")
	self:UnregisterEvent("CHAT_MSG_ADDON")
	self:StopFlagCaptures()
	self:StopHealthCheck()
end

mod:RegisterZone(30)
mod:RegisterZone(2197) -- Korrak's Revenge (WoW 15th)
