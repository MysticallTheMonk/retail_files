local E = select(2, ...):unpack()
local P, CM = E.Party, E.Comm

local pairs, tonumber, abs, floor, format, gsub, strmatch, strsplit = pairs, tonumber, abs, floor, format, gsub, strmatch, strsplit
local GetTime = GetTime

--[[ Oof, there's an addon that overwrites depricated function names in the global namespace... ]]
local GetSpellCooldown = GetSpellCooldown or function(spellID)
	local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
	if spellCooldownInfo then
		return spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.isEnabled, spellCooldownInfo.modRate
	end
end

local GetSpellCharges = GetSpellCharges or function(spellID)
	local spellChargeInfo = C_Spell.GetSpellCharges(spellID)
	if spellChargeInfo then
		return spellChargeInfo.currentCharges, spellChargeInfo.maxCharges, spellChargeInfo.cooldownStartTime, spellChargeInfo.cooldownDuration, spellChargeInfo.chargeModRate
	end
end

local LibDeflate = LibStub("LibDeflate")
local COOLDOWN_SYNC_INTERVAL = 2
local MSG_DESYNC = "DESYNC"
local MSG_INFO_REQUEST = "REQ"
local MSG_INFO_UPDATE = "UPD"
local MSG_STRIVE_PVP = "STRIVE"
local MSG_COOLDOWN_SYNC = "CD"
local NULL = ""

CM.syncedGroupMembers = {}
CM.cooldownSyncIDs = {}
CM.cooldownSyncSpellIDs = {}
CM.serializedSyncData = NULL

function CM:SendComm(...)
	local message = strjoin(",", ...)
	if IsInRaid() then
		self:SendCommMessage(self.AddonPrefix, message, (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "RAID")
	elseif IsInGroup() then
		self:SendCommMessage(self.AddonPrefix, message, (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "PARTY")
	end
end

function CM:RequestSync()
	self:SendComm(MSG_INFO_REQUEST, E.userGUID, self.serializedSyncData)
end

function CM:SendUserSyncData(sender)
	if self.serializedSyncData == NULL then
		self:InspectUser()
	end
	self:SendComm(sender or MSG_INFO_UPDATE, E.userGUID, self.serializedSyncData)
end

function CM:DesyncUserFromGroup()


	wipe(self.syncedGroupMembers)
	self.CooldownSyncFrame:Hide()
	self:SendComm(MSG_DESYNC, E.userGUID, 1)
end

function CM:IsVersionIncompatible(serializationVersion)
	return serializationVersion ~= self.SERIALIZATION_VERSION
end

local aceUserNameFix = CM.ACECOMM and E.userName or gsub(E.userNameWithRealm, " ", "")

function CM:CHAT_MSG_ADDON(prefix, message, _, sender)
	if prefix ~= self.AddonPrefix or sender == aceUserNameFix then
		return
	end

	local header, guid, body = strmatch(message, "(.-),(.-),(.+)")
	local info = P.groupInfo[guid]
	if not info then
		return
	end

	local unitIsSynced = self.syncedGroupMembers[guid]
	if header == MSG_COOLDOWN_SYNC then
		if unitIsSynced then
			self.SyncCooldowns(guid, body)
		end
		return
	elseif header == MSG_INFO_REQUEST then
		self:SendUserSyncData(guid)
	elseif header == MSG_INFO_UPDATE then
		if not unitIsSynced then
			return
		end
	elseif header == MSG_DESYNC then
		if unitIsSynced then
			self.syncedGroupMembers[guid] = nil
			self:ToggleCooldownSync()
		end
		return
	elseif header == MSG_STRIVE_PVP then
		if unitIsSynced and (not P.loginsessionData[guid] or not P.loginsessionData[guid]["strivedPvpCD"]) then
			local spellID, cd = strsplit(":", body)
			self.SyncStrivePvpTalentCD(guid, tonumber(spellID), tonumber(cd))
		end
		return
	elseif header ~= E.userGUID then
		return
	end

	local decodedData = LibDeflate:DecodeForWoWAddonChannel(body)
	if not decodedData then
		error("Error decoding sync message from " .. info.name)
	end

	local decompressedData = LibDeflate:DecompressDeflate(decodedData)
	if not decompressedData then
		error("Error decompressing sync message from " .. info.name)
	end

	while ( decompressedData ) do
		local t, rest = strsplit("^", decompressedData, 2)
		decompressedData = rest

		local k, v = strsplit(",", t, 2)
		if ( k == "T" ) then
			while ( v ) do
				local id, idlist = strsplit(",", v, 2)
				v = idlist
				local spellID, rank = strsplit(":", id)
				spellID = tonumber(spellID)
				if ( spellID ) then
					if ( spellID > 0 ) then
						info.talentData[spellID] = tonumber(rank) or 1
					else
						info.talentData[-spellID] = "PVP"
					end
				end
			end
		elseif ( k == "M" ) then
			while ( v ) do
				local id, idlist = strsplit(",", v, 2)
				v = idlist
				local key, src = strsplit(":", id)
				local spellID = tonumber(key)
				local value = tonumber(src) or src or true
				if ( not spellID ) then
					info.talentData[key] = value
				elseif ( spellID > 0 ) then
					if ( src == "AE" ) then
						local rank1 = self.essencePowerIDs[spellID]
						if ( rank1 ) then
							info.talentData[rank1] = src
							info.talentData["essMajorRank1"] = rank1
							info.talentData["essMajorID"] = spellID
						end
					elseif ( src == "ae" ) then
						info.talentData["essStriveMult"] = spellID
					else
						info.talentData[spellID] = value
					end
				else
					info.talentData[-spellID] = value
				end
			end
		elseif ( k == "E" ) then
			while ( v ) do
				local id, idlist = strsplit(",", v, 2)
				v = idlist
				id = tonumber(id)
				if ( id ) then
					if ( id > 0 ) then
						info.itemData[id] = true
					else
						info.rangedWeaponSpeed = -id
					end
				end
			end
		elseif ( k == "C" ) then
			wipe(info.shadowlandsData)
			local covenantID, soulbindID, conduits = strsplit(",", v, 3)
			covenantID = tonumber(covenantID)
			soulbindID = tonumber(soulbindID)
			local covenantSpellID = E.covenant_to_spellid[covenantID]
			info.shadowlandsData.covenantID = covenantSpellID
			info.shadowlandsData.soulbindID = soulbindID
			info.talentData[covenantSpellID] = "C"
			while ( conduits ) do
				local id, idlist = strsplit(",", conduits, 2)
				conduits = idlist
				local conduitSpellID, rankValue = strsplit(":", id)
				conduitSpellID = tonumber(conduitSpellID)
				rankValue = tonumber(rankValue)
				if ( rankValue ) then
					info.talentData[conduitSpellID] = rankValue
				elseif ( conduitSpellID ) then
					info.talentData[conduitSpellID] = 0
				end
			end
		else
			k = tonumber(k)
			if ( not k or self:IsVersionIncompatible(k) ) then
				return
			end
			info.spec = tonumber(v)
			wipe(info.talentData)
			wipe(info.itemData)
		end
	end

	local unit = info.unit
	if info.name == "" or info.name == "Unknown" then
		info.name = GetUnitName(unit, true)
	end
	if info.level == 200 then
		local lvl = UnitLevel(unit)
		if lvl > 0 then
			info.level = lvl
		end
	end

	self.syncedGroupMembers[guid] = true
	self:DequeueInspect(guid)
	info:SetupBar()

	self:ToggleCooldownSync()
end

local function SendUpdatedUserSyncData()
	CM:InspectUser()
	CM:SendUserSyncData()
end

function CM:CHARACTER_POINTS_CHANGED(change)
	if change == -1 then
		SendUpdatedUserSyncData()
	end
end

local equipmentTimer

local SendUpdatedUserSyncData_OnTimerEnd = function()
	SendUpdatedUserSyncData()
	equipmentTimer = nil
end

function CM:PLAYER_EQUIPMENT_CHANGED(equipmentSlot)
	if not equipmentTimer and equipmentSlot < 18 then
		equipmentTimer = C_Timer.NewTicker(0.1, SendUpdatedUserSyncData_OnTimerEnd, 1)
	end
end

CM.PLAYER_TALENT_UPDATE = SendUpdatedUserSyncData
CM.PLAYER_SPECIALIZATION_CHANGED = SendUpdatedUserSyncData
CM.COVENANT_CHOSEN = SendUpdatedUserSyncData
CM.SOULBIND_ACTIVATED = SendUpdatedUserSyncData
CM.SOULBIND_NODE_LEARNED = SendUpdatedUserSyncData
CM.SOULBIND_NODE_UNLEARNED = SendUpdatedUserSyncData
CM.SOULBIND_NODE_UPDATED = SendUpdatedUserSyncData
CM.SOULBIND_CONDUIT_INSTALLED = SendUpdatedUserSyncData
CM.SOULBIND_PATH_CHANGED = SendUpdatedUserSyncData
CM.COVENANT_SANCTUM_RENOWN_LEVEL_CHANGED = SendUpdatedUserSyncData
CM.TRAIT_CONFIG_UPDATED = SendUpdatedUserSyncData



CM.PLAYER_LEAVING_WORLD = CM.DesyncUserFromGroup

local outlawMinor = {
	315341,
	13877,
	271877,
	195457,
	315508,
	2983,
}

local function UpdateOutlawMinorCD(info, offset)
	for _, spellID in ipairs(outlawMinor) do
		local icon = info.spellIcons[spellID]
		if icon and icon.active then
			icon:UpdateCooldown(offset)
		end
	end
end

local function SetHealthstoneCD(info, icon, charges, isEnabled)
	icon.count:SetText(charges)
	info.auras.healthStoneStacks = charges
	info.preactiveIcons[6262] = isEnabled and icon or nil
end

function CM.SyncCooldowns(guid, encodedData)
	local info = P.groupInfo[guid]
	if not info then
		return
	end

	local compressedData = LibDeflate:DecodeForWoWAddonChannel(encodedData)
	if not compressedData then
		return
	end

	local serializedCooldownData = LibDeflate:DecompressDeflate(compressedData)
	if not serializedCooldownData then
		return
	end

	local isDeadOrOffline = info.isDeadOrOffline
	local condition = E.db.highlight.glowBorderCondition
	local isOutlawMinor = info.spec == 260
	local now = GetTime()

	while serializedCooldownData do
		local spellID, duration, remainingTime, modRate, charges, rest = strsplit(",", serializedCooldownData, 6)
		serializedCooldownData = rest
		spellID = tonumber(spellID)

		if spellID then
			local icon = info.spellIcons[spellID]
			if icon then
				duration, remainingTime, modRate = tonumber(duration), tonumber(remainingTime), tonumber(modRate)
				charges = charges ~= "-1" and tonumber(charges) or nil

				local active = icon.active and info.active[spellID]
				if duration == 0 then

					if active then
						if spellID == 6262 then
							SetHealthstoneCD(info, icon, charges, now - active.startTime < 10)
						end
						icon:ResetCooldown(true)
						info.spellModRates[spellID] = modRate
						icon.modRate = modRate
					end
				else

					if not active or

						abs(active.startTime + active.duration - now - remainingTime) > 1 or
						abs(active.modRate - modRate) > 0.1 or
						spellID ~= 6262 and active.charges ~= charges then


						if isOutlawMinor and active and spellID ~= 5277 and spellID ~= 1966 then
							UpdateOutlawMinorCD(info, active.startTime + active.duration - now - remainingTime)
							isOutlawMinor = nil
						end


						local startTime = now - (duration - remainingTime)
						icon.cooldown:SetCooldown(startTime, duration, modRate)
						if not active then
							active = {}
							info.active[spellID] = active
						end
						active.startTime = startTime
						active.duration = duration
						active.modRate = modRate
						icon.modRate = modRate
						info.spellModRates[spellID] = modRate


						if spellID == 6262 then
							SetHealthstoneCD(info, icon, charges)
							icon.active = 0
						else
							if charges and not icon.maxcharges then
								icon.maxcharges = charges + 1
							elseif not charges and icon.maxcharges then
								icon.maxcharges = nil
							end
							active.charges = charges
							icon.count:SetText(charges or "")
							icon.active = charges or 0
						end

						if icon.isUserSyncOnly then
							return
						end

						icon:SetCooldownElements()
						icon:SetOpacity()
						icon:SetColorSaturation()
						icon:SetBorderGlow(isDeadOrOffline, condition)

						local statusBar = icon.statusBar
						if statusBar then
							statusBar.CastingBar:OnEvent(E.db.extraBars[statusBar.key].reverseFill and "UNIT_SPELLCAST_CHANNEL_START" or "UNIT_SPELLCAST_START")
						end
					end
				end
			end
		end
	end
end



local function GetCooldownFix(spellID)
	local startTime, duration, enabled, modRate = GetSpellCooldown(spellID)
	local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetSpellCharges(spellID)
	local charges = (maxCharges and maxCharges > 1) and currentCharges or nil
	if enabled then
		if startTime and startTime > 0 then
			if duration < 1.5 or (currentCharges and currentCharges > 0) then
				return nil
			end
			return startTime, duration, modRate, charges
		elseif maxCharges and maxCharges > currentCharges then
			return cooldownStart, cooldownDuration, chargeModRate, charges
		end
	end
	return 0, 0, 1, charges, enabled
end

local cooldownData = {}
local elapsedTime = 0
local OFF_CD, THIRD_DECIMAL, TRUNCATE_ZEROS = "0,0,1", "%.3f", "%.?0+$"

local function CooldownSyncFrame_OnUpdate(_, elapsed)
	elapsedTime = elapsedTime + elapsed
	if elapsedTime < COOLDOWN_SYNC_INTERVAL then
		return
	end

	local info = P.userInfo
	local now = GetTime()
	local c = 0

	for castID, spellID in pairs(CM.cooldownSyncIDs) do
		local startTime, duration, modRate, charges, enabled = GetCooldownFix(castID)
		if startTime then
			local active = info.active[spellID]

			if spellID == 6262 then

				charges = C_Item.GetItemCount(5512, false, true)
			end

			if duration == 0 then
				if E.sync_reset[spellID] and active then
					cooldownData[c + 1] = spellID
					cooldownData[c + 2] = OFF_CD
					cooldownData[c + 3] = charges or -1
					c = c + 3
				end
			else

				local remainingTime = startTime + duration - now
				if not active or
					abs(remainingTime - (active.startTime + active.duration - now)) > 1 or
					abs(modRate - active.modRate) > 0.1 or
					spellID ~= 6262 and charges ~= active.charges then

					if modRate == 1 then
						remainingTime = floor(remainingTime)
					else

						duration = format(THIRD_DECIMAL, duration):gsub(TRUNCATE_ZEROS, NULL)
						modRate = format(THIRD_DECIMAL, modRate):gsub(TRUNCATE_ZEROS, NULL)
						remainingTime = format(THIRD_DECIMAL, remainingTime):gsub(TRUNCATE_ZEROS, NULL)
					end
					cooldownData[c + 1] = spellID
					cooldownData[c + 2] = duration
					cooldownData[c + 3] = remainingTime
					cooldownData[c + 4] = modRate
					cooldownData[c + 5] = charges or -1
					c = c + 5
				end
			end
		end
	end

	elapsedTime = 0

	if c == 0 then
		return
	end

	for i = #cooldownData, c + 1, -1 do
		cooldownData[i] = nil
	end

	local serializedCooldownData = table.concat(cooldownData, ",")
	local compressedData = LibDeflate:CompressDeflate(serializedCooldownData)
	local encodedData = LibDeflate:EncodeForWoWAddonChannel(compressedData)

	CM.SyncCooldowns(E.userGUID, encodedData)
	if next(CM.syncedGroupMembers) then
		CM:SendComm(MSG_COOLDOWN_SYNC, E.userGUID, encodedData)
	end
end

function CM.SyncStrivePvpTalentCD(guid, spellID, cd)
	local info = P.groupInfo[guid]
	if not info then
		return
	end

	local icon = info.spellIcons[spellID]
	if icon then
		local active = info.active[spellID]
		if active then
			local modRate = active.modRate or 1
			local newCd = cd * modRate
			icon.cooldown:SetCooldown(active.startTime, newCd, modRate)
			active.duration = newCd
		end
		icon.duration = cd
	end
	P.loginsessionData[guid] = P.loginsessionData[guid] or {}
	P.loginsessionData[guid]["strivedPvpCD"] = cd
end

function CM.SendStrivePvpTalentCD(spellID)
	local _, cd, modRate = GetCooldownFix(spellID)
	if cd == 0 then
		return
	end

	cd = cd/modRate
	CM.SyncStrivePvpTalentCD(E.userGUID, spellID, cd)
	CM:SendComm(MSG_STRIVE_PVP, E.userGUID, cd)
end

local function FindValidSpellID(info, v)
	if type(v) ~= "table" then
		return info.spec == v or (info:IsTalentForPvpStatus(v) and true)
	end
	if v[1] > 0 then

		for _, id in pairs(v) do
			if info.spec == id or info:IsTalentForPvpStatus(id) then
				return true
			end
		end
		return false
	else

		local spellID
		for i = 1, #v, 2 do
			local tid, sid = v[i], v[i + 1]
			tid = i == 1 and -tid or tid
			if info:IsTalentForPvpStatus(tid) then
				spellID = sid
			end
		end
		return spellID or true
	end
end

function CM:RefreshCooldownSyncIDs(info)
	if E.preWOTLKC then
		return
	end

	wipe(self.cooldownSyncIDs)
	wipe(self.cooldownSyncSpellIDs)

	if info.isAdminForMDI then
		return
	end

	local notRaid = P.zone ~= "raid"
	for id, t in E.pairs(E.sync_cooldowns.ALL, E.sync_cooldowns[E.userClass]) do
		if notRaid or E.sync_in_raid[id] then
			local castID
			for i = 1, #t do
				local v = t[i]
				castID = not v or FindValidSpellID(info, v)
				if not castID then break end
			end
			if castID then
				castID = castID == true and id or castID
				self.cooldownSyncIDs[castID == true and id or castID] = true
			end
		end
	end

	for id in pairs(self.cooldownSyncIDs) do
		while true do
			if E.hash_spelldb[id] then
				self.cooldownSyncSpellIDs[id] = true
			end
			id = E.spellcast_merged[id]
			if not id then
				break
			end
		end
	end

	self:ToggleCooldownSync()
end

function CM:AssignSpellIDsToCooldownSyncIDs(info)
	if E.preWOTLKC then
		return
	end

	for id in pairs(self.cooldownSyncIDs) do
		local _, spellID = info:FindIconFromCastID(id)
		self.cooldownSyncIDs[id] = spellID
	end
end

function CM:ForceSyncCooldowns()
	elapsedTime = 100
end

function CM:ToggleCooldownSync()
	if E.preWOTLKC then
		return
	end
	if next(self.cooldownSyncIDs) and (not P.isUserDisabled or next(self.syncedGroupMembers)) then
		if not self.CooldownSyncFrame.isShown then
			self.CooldownSyncFrame:Show()
		end
	else
		if self.CooldownSyncFrame.isShown then
			self.CooldownSyncFrame:Hide()
		end
	end
end

local CooldownSyncFrame_OnShow = function(self)
	self.isShown = true
end

local CooldownSyncFrame_OnHide = function(self)
	self.isShown = false
end

function CM:InitCooldownSync()
	if self.initCooldownSync then
		return
	end

	local CooldownSyncFrame = CreateFrame("Frame", nil, UIParent)
	CooldownSyncFrame:Hide()
	CooldownSyncFrame:SetPoint("BOTTOMLEFT", UIParent)
	CooldownSyncFrame:SetSize(1, 1)
	CooldownSyncFrame:SetScale(0.001)
	--[==[@debug@
	CooldownSyncFrame:SetScale(0.7)
	--@end-debug@]==]
	CooldownSyncFrame.icons = {}
	CooldownSyncFrame.ReleaseIcons = function(container, n)
		local numIcons = #container.icons
		if numIcons == 0 then
			return
		end
		n = n or 0
		for i = numIcons, n + 1, -1 do
			local icon = container.icons[i]
			P.IconPool:Release(icon)
			container.icons[i] = nil
		end
		container.numIcons = n
	end
	CooldownSyncFrame:SetScript("OnShow", CooldownSyncFrame_OnShow)
	CooldownSyncFrame:SetScript("OnHide", CooldownSyncFrame_OnHide)
	CooldownSyncFrame:SetScript("OnUpdate", CooldownSyncFrame_OnUpdate)
	self.CooldownSyncFrame = CooldownSyncFrame

	self.initCooldownSync = true
end
