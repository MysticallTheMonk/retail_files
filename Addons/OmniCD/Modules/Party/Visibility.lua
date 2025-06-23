local E = select(2, ...):unpack()
local P, CM, CD = E.Party, E.Comm, E.Cooldowns

local C_PvP_IsRatedSoloShuffle = C_PvP and C_PvP.IsRatedSoloShuffle or E.Noop

local groupInfo = {}
local callbackTimers = {}

local UPDATE_ROSTER_DELAY = 2
local MSG_INFO_REQUEST_DELAY = 3

local RAID_UNIT = {
	"raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10",
	"raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20",
	"raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30",
	"raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40",
}

local PARTY_UNIT = {
	"party1", "party2", "party3", "party4", "player"
}

local INSTANCETYPE_EVENTS = {
	party = {
		"CHALLENGE_MODE_START"
	},
	raid = {
		"ENCOUNTER_END"
	},
	none = {
		"PLAYER_FLAGS_CHANGED"
	},
	arena = {
		"UPDATE_UI_WIDGET"
	},
	pvp = {
		"CHAT_MSG_BG_SYSTEM_NEUTRAL",
		"UPDATE_UI_WIDGET"
	}
}

if E.preCata then
	if E.preBCC then
		INSTANCETYPE_EVENTS.raid = nil
	end
	INSTANCETYPE_EVENTS.party = nil
	INSTANCETYPE_EVENTS.none = nil
end

function P:RegisterZoneEvents()
	if self.eventZone == self.zone then
		return
	end

	local events = INSTANCETYPE_EVENTS[self.eventZone]
	if events then
		for _, event in ipairs(events) do
			self:UnregisterEvent(event)
		end
	end

	events = INSTANCETYPE_EVENTS[self.zone]
	if events then
		for _, event in ipairs(events) do
			self:RegisterEvent(event)
		end
	end
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("GROUP_JOINED")
	self.eventZone = self.zone
end

function P:UnregisterZoneEvents()
	if not self.eventZone then
		return
	end

	local events = INSTANCETYPE_EVENTS[self.eventZone]
	if events then
		for _, event in ipairs(INSTANCETYPE_EVENTS[self.eventZone]) do
			self:UnregisterEvent(event)
		end
	end
	self:UnregisterEvent("GROUP_ROSTER_UPDATE")
	self:UnregisterEvent("GROUP_JOINED")
	self.eventZone = nil
end

local function IsInShadowlands()
	local mapID = C_Map and C_Map.GetBestMapForUnit("player")
	if mapID then
		local mapInfo = C_Map.GetMapInfo(mapID)
		while mapInfo do
			if mapInfo.mapType == Enum.UIMapType.Continent then
				return mapInfo.mapID == 1550
			end
			mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
		end
	end
end

function P:UpdateDelayedZoneData()
	self.isInShadowlands = E.isSL or (E.postDF and not self.isInPvPInstance and IsInShadowlands())
end

local function InspectAllGroupMembers()
	CM:EnqueueInspect(true)
end

local function IsExtraBarDisabled()
	for key, db in pairs(E.db.extraBars) do
		if db.enabled and db.showPlayer then
			return false
		end
	end
	return true
end

local function GetRosterInfo(i, unit)
	local _, name, subgroup, level, fileName, online, isDead
	if unit == true then
		name, _, subgroup, level, _, fileName, _, online, isDead = GetRaidRosterInfo(i)
	else
		name = GetUnitName(unit, true)
		level = UnitLevel(unit)
		_, fileName = UnitClass(unit)
		online = UnitIsConnected(unit)
		isDead = UnitIsDeadOrGhost(unit)
	end
	return name, subgroup, level, fileName, online, isDead
end

local function RequestSync_OnDelayEnd()
	local success = CM:InspectUser()
	if success then
		CM:RequestSync()
		callbackTimers.syncDelay = nil
	else
		callbackTimers.syncDelay = C_Timer.NewTimer(2, RequestSync_OnDelayEnd)
	end
end

local function ScheduleSyncRequest()



	if callbackTimers.syncDelay then
		callbackTimers.syncDelay:Cancel()
	end
	callbackTimers.syncDelay = C_Timer.NewTimer(MSG_INFO_REQUEST_DELAY, RequestSync_OnDelayEnd)
end

local function UpdateAnchor_OnDelayEnd()
	P:UpdatePosition()
	callbackTimers.anchorBackup = nil
end

local function ScheduleAnchorUpdate()

	if callbackTimers.anchorBackup then
		callbackTimers.anchorBackup:Cancel()
	end
	callbackTimers.anchorBackup = C_Timer.NewTicker(3, UpdateAnchor_OnDelayEnd, 2)
end

local function ScheduleRosterUpdate()

	if callbackTimers.rosterDelay then
		callbackTimers.rosterDelay:Cancel()
	end
	callbackTimers.rosterDelay = C_Timer.NewTimer(2, P.UpdateRosterInfo)
end

function P:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi, isRefresh)
	local _, instanceType = IsInInstance()

	local wasDisabled = self.disabledZone
	self.disabledZone = not self.isInTestMode and not E.profile.Party.visibility[instanceType]

	if self.disabledZone then
		if not wasDisabled then
			self:ResetModule(true)
		end
		return
	end

	if not isRefresh and self.isInTestMode then
		self:Test()
		return
	end

	E.db = E:GetCurrentZoneSettings(self.isInTestMode and self.testZone or instanceType)
	self.isUserHidden = not self.isInTestMode and not E.db.general.showPlayer
	self.isUserDisabled = self.isUserHidden and IsExtraBarDisabled()
	self.isHighlightEnabled = E.db.highlight.glowBuffs
	self.zone = instanceType
	self.isInArena = instanceType == "arena"
	self.isInPvPInstance = self.isInArena or instanceType == "pvp"
	self.isPvP = E.preCata or self.isInPvPInstance or (instanceType == "none" and C_PvP.IsWarModeDesired())
	self.effectivePixelMult = nil

	self:RegisterZoneEvents()
	self:UpdateEnabledSpells()
	self:UpdatePositionValues()

	if self.isInPvPInstance then
		self:ResetAllIcons("joinedPvP")
	end


	if self.isInArena then
		if not callbackTimers.arenaTicker then
			callbackTimers.arenaTicker = C_Timer.NewTicker(12, InspectAllGroupMembers, 6)
		end
	else
		if callbackTimers.arenaTicker then
			callbackTimers.arenaTicker:Cancel()
			callbackTimers.arenaTicker = nil
		end
	end
	self:RefreshExBarFrames()
	self:HookRefreshMembers()



	self:GROUP_ROSTER_UPDATE(true, isRefresh)
end

P.ZONE_CHANGED_NEW_AREA = P.PLAYER_ENTERING_WORLD

function P:GROUP_JOINED()

	self.groupJoined = true


	if self.disabled then
		return
	end


	if self.isInArena and C_PvP_IsRatedSoloShuffle() then
		self:ResetAllIcons("joinedPvP", true)
		if not callbackTimers.arenaTicker then
			callbackTimers.arenaTicker = C_Timer.NewTicker(6, InspectAllGroupMembers, 5)
		end
	end
end

function P:UpdateRosterInfo(force, clearSession)
	local size = P:GetEffectiveNumGroupMembers()

	local wasDisabled = P.disabled
	P.disabled = not P.isInTestMode and (size == 0 or E.isInPetBattle
		or (size == 1 and P.isUserDisabled)
		or (GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) == 0 and not E.profile.Party.visibility.finder)
		or (size > E.profile.Party.groupSize[P.zone]))

	if P.disabled then
		if not wasDisabled then
			P:ResetModule()
		end
		return
	elseif wasDisabled then
		P:RefreshExBarFrames()
		P:HookRefreshMembers()
	end

	CM:Enable()
	CD:Enable()

	E.Libs.CBH:Fire("OnStartup")

	local isInRaid = IsInRaid()
	local isCallback = type(self) == "userdata"
	local isReadyForSync = isCallback and P.groupJoined



	for guid, info in pairs(groupInfo) do
		if not UnitExists(info.name) or (not P.isInTestMode and info.isNPC) then
			info:Delete()
		elseif clearSession then
			info:ClearSessionItemData()
		end
	end

	for i = 1, size do
		local index = not isInRaid and i == size and 5 or i
		local unit = isInRaid and RAID_UNIT[index] or PARTY_UNIT[index]
		local guid = UnitGUID(unit)
		local info = groupInfo[guid]
		local name, subgroup, level, fileName, online, isDead = GetRosterInfo(i, isInRaid or unit)
		local isDeadOrOffline = isDead or not online
		local isNPC = strsub(guid, 1, 6) ~= "Player"


		local isAdminForMDI = false
		if P.zone == "party" and subgroup then
			isAdminForMDI = subgroup > 1
		end

		if info and not isCallback then

			if force or info.isAdminForMDI ~= isAdminForMDI then
				info:SetUnit(unit, index, isDead, isDeadOrOffline, isAdminForMDI)
				info:SetupBar(true)
				CM:AddToInspectList(guid)
			else

				if info.unit ~= unit then
					info:SetUnit(unit, index)
					info.bar:UnregisterAllEvents()
					info.bar:SetUnit(info, unit, index)
					info.bar:UpdatePosition()
				end

				if not info.spec then
					CM:AddToInspectList(guid)
				end

				if info.isDeadOrOffline ~= isDeadOrOffline then
					if not online then
						CM.syncedGroupMembers[guid] = nil
					end
					info.isDead = isDead
					info.isDeadOrOffline = isDeadOrOffline
					info:UpdateColorScheme()
				end
			end
		elseif not info and (isCallback or force) and (P.isInTestMode or not isNPC) then

			if fileName then
				local petGUID = (fileName == "WARLOCK" or fileName == "HUNTER" or fileName == "DEATHKNIGHT")
					and E.UNIT_TO_PET[unit]
				if petGUID then
					petGUID = UnitGUID(petGUID)
					if petGUID then
						CD.minionGUIDS[petGUID] = guid
					end
				end

				info = P:GetUnitInfo(unit, guid, name, level, fileName)
				info:SetUnit(unit, index, isDead, isDeadOrOffline, isAdminForMDI)
				info.petGUID = petGUID
				info.isNPC = isNPC
				info:SetupBar(true)
				CM:AddToInspectList(guid)
			else

				ScheduleRosterUpdate()
				isReadyForSync = false
			end
		end
	end

	P:UpdateExBars()

	CM:EnqueueInspect()
	CM:ToggleCooldownSync()



	if force or isReadyForSync then
		if isReadyForSync then
			P.groupJoined = nil
		end
		ScheduleSyncRequest()
	end

	if isCallback then
		callbackTimers.rosterDelay = nil
	else
		ScheduleAnchorUpdate()
		ScheduleRosterUpdate()
	end
end

function P:GROUP_ROSTER_UPDATE(isPEW, isRefresh)
	if isRefresh or GetNumGroupMembers() == 0 then
		self:UpdateRosterInfo(true)
	elseif isPEW then
		C_Timer.After(1, function()
			self:UpdateDelayedZoneData()
			self:UpdateRosterInfo(true, true)
		end)
	else
		C_Timer.After(0, function()
			self:UpdateRosterInfo()
		end)
	end
end

function P:CHAT_MSG_BG_SYSTEM_NEUTRAL(arg1)
	if self.disabled then
		return
	end

	if strfind(arg1, "!$") then
		CM:EnqueueInspect(true)
	end
end

function P:UPDATE_UI_WIDGET(widgetInfo)
	if self.disabled then
		return
	end
	if widgetInfo.widgetSetID == 1 and widgetInfo.widgetType == 0 then
		local info = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(widgetInfo.widgetID)
		if info and info.state == 1 and info.hasTimer then
			self:UnregisterEvent("UPDATE_UI_WIDGET")
			C_Timer.After(.5, InspectAllGroupMembers)
		end
	end
end

function P:PLAYER_FLAGS_CHANGED(unitTarget)
	if self.disabled then
		return
	end
	if unitTarget == "player" and not self.inLockdown then
		local wasPvP = self.isPvP
		self.isPvP = C_PvP.IsWarModeDesired()
		if self.isPvP ~= wasPvP then
			self:UpdateAllBars()
			CM:EnqueueInspect(true)
		end
	end
end

function P:CHALLENGE_MODE_START()
	if self.disabled then
		return
	end
	CM:EnqueueInspect(true)
	self:ResetAllIcons()
	self:UnregisterEvent("CHALLENGE_MODE_START")
end

function P:ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success)
	if self.disabled then
		return
	end
	if groupSize > 5 then
		self:ResetAllIcons("encounterEnd")
	end
end

P.groupInfo = groupInfo
P.callbackTimers = callbackTimers
