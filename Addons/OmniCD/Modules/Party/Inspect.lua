local E = select(2, ...):unpack()
local P, CM = E.Party, E.Comm

local pairs, ipairs, type, format, gsub = pairs, ipairs, type, format, gsub
local UnitIsConnected, CanInspect, CheckInteractDistance = UnitIsConnected, CanInspect, CheckInteractDistance
local GetPvpTalentInfoByID, GetTalentInfo, GetGlyphSocketInfo = GetPvpTalentInfoByID, GetTalentInfo, GetGlyphSocketInfo
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
local C_SpecializationInfo_GetInspectSelectedPvpTalent = C_SpecializationInfo and C_SpecializationInfo.GetInspectSelectedPvpTalent
local C_SpecializationInfo_GetPvpTalentSlotInfo = C_SpecializationInfo and C_SpecializationInfo.GetPvpTalentSlotInfo
local C_Traits_GetNodeInfo = C_Traits and C_Traits.GetNodeInfo
local C_Soulbinds_GetConduitSpellID = C_Soulbinds and C_Soulbinds.GetConduitSpellID

local InspectQueueFrame = CreateFrame("Frame")
local InspectTooltip, tooltipData
if not E.postDF then
	InspectTooltip = CreateFrame("GameTooltip", "OmniCDInspectToolTip", nil, "GameTooltipTemplate")
	InspectTooltip:SetOwner(UIParent, "ANCHOR_NONE")
end

local LibDeflate = LibStub("LibDeflate")
local INSPECT_INTERVAL = 2
local INSPECT_TIMEOUT = 300
local queriedGUID

local inspectOrderList = {}
local queueEntries = {}
local staleEntries = {}

CM.SERIALIZATION_VERSION = E.preWOTLKC and 6 or 7
CM.ACECOMM = LibStub("AceComm-3.0"):Embed(CM)

function CM:Enable()
	if self.isEnabled then
		return
	end

	self.AddonPrefix = E.AddOn
	self:RegisterComm(self.AddonPrefix, "CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	if E.isWOTLKC or E.isCata then

		self:RegisterEvent("PLAYER_TALENT_UPDATE")
	elseif E.preCata then
		self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	else

		self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

		self:RegisterEvent("COVENANT_CHOSEN")
		self:RegisterEvent("SOULBIND_ACTIVATED")
		self:RegisterEvent("SOULBIND_NODE_LEARNED")
		self:RegisterEvent("SOULBIND_NODE_UNLEARNED")
		self:RegisterEvent("SOULBIND_NODE_UPDATED")
		self:RegisterEvent("SOULBIND_CONDUIT_INSTALLED")
		self:RegisterEvent("SOULBIND_PATH_CHANGED")
		self:RegisterEvent("COVENANT_SANCTUM_RENOWN_LEVEL_CHANGED")


		self:RegisterEvent("TRAIT_CONFIG_UPDATED")
	end
	self:SetScript("OnEvent", function(self, event, ...)
		self[event](self, ...)
	end)

	self:InitInspect()
	self:InitCooldownSync()
	self.isEnabled = true
end

function CM:Disable()
	if not self.isEnabled then
		return
	end
	self:UnregisterAllEvents()
	self:DisableInspect()
	self:DesyncUserFromGroup()
	self.isEnabled = false
end

local timeSinceUpdate = 0

local function InspectQueueFrame_OnUpdate(_, elapsed)
	timeSinceUpdate = timeSinceUpdate + elapsed


	if timeSinceUpdate > INSPECT_INTERVAL then
		CM:RequestInspect()
		timeSinceUpdate = 0
	end
end

function CM:InitInspect()
	if self.initInspect then
		return
	end
	InspectQueueFrame:Hide()
	InspectQueueFrame:SetScript("OnUpdate", InspectQueueFrame_OnUpdate)
	self.initInspect = true
end

function CM:EnableInspect()
	if self.enabledInspect or #inspectOrderList == 0 then
		return
	end
	InspectQueueFrame:Show()
	self:RegisterEvent("INSPECT_READY")
	self.enabledInspect = true
end

function CM:DisableInspect()
	if not self.enabledInspect then
		return
	end
	ClearInspectPlayer()
	InspectQueueFrame:Hide()
	self:UnregisterEvent("INSPECT_READY")

	wipe(inspectOrderList)
	wipe(queueEntries)
	wipe(staleEntries)
	queriedGUID = nil
	self.enabledInspect = false
end

local function PendingInspect(guid)
	return queueEntries[guid] or staleEntries[guid]
end

function CM:AddToInspectList(guid)




	if not PendingInspect(guid) then
		inspectOrderList[#inspectOrderList + 1] = guid
	end
end

function CM:AddToInspectListAndQueue(guid, addedTime)
	if guid == E.userGUID then
		self:InspectUser()
	elseif not PendingInspect(guid) then
		queueEntries[guid] = addedTime
		inspectOrderList[#inspectOrderList + 1] = guid
	end
end

function CM:EnqueueInspect(force, guid)
	local addedTime = GetTime()
	if force then
		for infoGUID in pairs(P.groupInfo) do
			self:AddToInspectListAndQueue(infoGUID, addedTime)
		end
	elseif guid then
		self:AddToInspectListAndQueue(guid, addedTime)
	else
		local n = #inspectOrderList
		if n == 0 then
			return
		end
		for i = 1, n do
			local listGUID = inspectOrderList[i]
			if not PendingInspect(guid) then
				queueEntries[listGUID] = addedTime
			end
		end
	end

	self:EnableInspect()
end

function CM:DequeueInspect(guid, moveToStale)
	if queriedGUID == guid then
		ClearInspectPlayer()
		queriedGUID = nil
	end

	if moveToStale then
		staleEntries[guid] = queueEntries[guid]
	else
		for i = #inspectOrderList, 1, -1 do
			local listGUID = inspectOrderList[i]
			if guid == listGUID then
				tremove(inspectOrderList, i)
			end
		end
	end
	queueEntries[guid] = nil
end

function CM:RequestInspect()
	if UnitIsDead("player") or InspectFrame and InspectFrame:IsShown() then
		return
	end

	if #inspectOrderList == 0 then
		self:DisableInspect()
		return
	end


	if queriedGUID then
		ClearInspectPlayer()
		staleEntries[queriedGUID] = queueEntries[queriedGUID]
		queueEntries[queriedGUID] = nil
		queriedGUID = nil
	end

	if next(queueEntries) == nil and next(staleEntries) then
		local copy = queueEntries
		queueEntries = staleEntries
		staleEntries = copy
	end

	local now = GetTime()
	local inCombat = InCombatLockdown()

	for i = 1, #inspectOrderList do
		local guid = inspectOrderList[i]
		local addedTime = queueEntries[guid]
		if addedTime then
			local info = P.groupInfo[guid]
			local unitIsSynced = self.syncedGroupMembers[guid]
			if info and not info.isNPC and not unitIsSynced then
				local unit = info.unit
				local elapsed = now - addedTime
				if not UnitIsConnected(unit) or elapsed > INSPECT_TIMEOUT or info.isAdminForMDI then
					self:DequeueInspect(guid)
				elseif E.preCata and (inCombat or not CheckInteractDistance(unit,1))


					or not CanInspect(unit) then

					staleEntries[guid] = addedTime
					queueEntries[guid] = nil
				else
					queriedGUID = guid
					NotifyInspect(unit)
					return
				end
			else
				self:DequeueInspect(guid)
			end
		end
	end
end

function CM:INSPECT_READY(guid)
	if queriedGUID == guid then
		self:InspectUnit(guid)
	end
end

local INVSLOT_INDEX = {
	INVSLOT_HEAD,
	INVSLOT_NECK,
	INVSLOT_SHOULDER,

	INVSLOT_CHEST,
	INVSLOT_WAIST,
	INVSLOT_LEGS,
	INVSLOT_FEET,
	INVSLOT_WRIST,
	INVSLOT_HAND,
	INVSLOT_FINGER1,
	INVSLOT_FINGER2,
	INVSLOT_TRINKET1,
	INVSLOT_TRINKET2,
	INVSLOT_BACK,
	INVSLOT_MAINHAND,
	INVSLOT_OFFHAND,
}
local NUM_INVSLOTS = #INVSLOT_INDEX

E.essenceData = {
	[2]  = { 293019, 298080, 298081, 298081, 294668, 298082, 298083, 298083 },
	[3]  = { 293031, 300009, 300010, 300010, 294910, 300012, 300013, 300013 },
	[4]  = { 295186, 298628, 299334, 299334, 295078, 298627, 299333, 299333 },
	[5]  = { 295258, 299336, 299338, 299338, 295246, 299335, 299337, 299337 },
	[6]  = { 295337, 299345, 299347, 299347, 295293, 299343, 299346, 299346 },
	[7]  = { 294926, 300002, 300003, 300003, 294964, 300004, 300005, 300005 },
	[12] = { 295373, 299349, 299353, 299353, 295365, 299348, 299350, 299350 },
	[13] = { 295746, 300015, 300016, 300016, 295750, 300018, 300020, 300020 },
	[14] = { 295840, 299355, 299358, 299358, 295834, 299354, 299357, 299357 },
	[15] = { 302731, 302982, 302983, 302983, 302916, 302984, 302985, 302985 },
	[16] = { 296036, 310425, 310442, 310442, 293030, 310422, 310426, 310426 },
	[17] = { 296072, 299875, 299876, 299876, 296050, 299878, 299879, 299879 },
	[18] = { 296094, 299882, 299883, 299883, 296081, 299885, 299887, 299887 },
	[19] = { 296197, 299932, 299933, 299933, 296136, 299935, 299936, 299936 },
	[20] = { 293032, 299943, 299944, 299944, 296207, 299939, 299940, 299940 },
	[21] = { 296230, 299958, 299959, 299959, 303448, 303474, 303476, 303476 },
	[22] = { 296325, 299368, 299370, 299370, 296320, 299367, 299369, 299369 },
	[23] = { 297108, 298273, 298277, 298277, 297147, 298274, 298275, 298275 },
	[24] = { 297375, 298309, 298312, 298312, 297411, 298302, 298304, 298304 },
	[25] = { 298168, 299273, 299275, 299275, 298193, 299274, 299277, 299277 },
	[27] = { 298357, 299372, 299374, 299374, 298268, 299371, 299373, 299373 },
	[28] = { 298452, 299376, 299378, 299378, 298407, 299375, 299377, 299377 },
	[32] = { 303823, 304088, 304121, 304121, 304081, 304089, 304123, 304123 },
	[33] = { 295046, 299984, 299988, 299988, 295164, 299989, 299991, 299991 },
	[34] = { 310592, 310601, 310602, 310602, 310603, 310607, 310608, 310608 },
	[35] = { 310690, 311194, 311195, 311195, 310712, 311197, 311198, 311198 },
	[36] = { 311203, 311302, 311303, 311303, 311210, 311304, 311306, 311306 },
	[37] = { 312725, 313921, 313922, 313922, 312771, 313919, 313920, 313920 },
}

CM.essencePowerIDs = {}

for essenceID, essencePowers in pairs(E.essenceData) do

	local link = E.postSL and C_AzeriteEssence.GetEssenceHyperlink(essenceID, 1)
	if link and link ~= "" then
		link = link:match("%[(.-)%]"):gsub("%-","%%-")
		essencePowers.name = link
		essencePowers.ID = essenceID
		for i = 1, #essencePowers do
			local spellID = essencePowers[i]
			local rank1ID = essencePowers[i > 4 and 5 or 1]
			CM.essencePowerIDs[spellID] = rank1ID
		end
	end
end

function E:IsEssenceRankUpgraded(id)
	return id and id ~= CM.essencePowerIDs[id]
end

local function GetNumTooltipLines()
	if InspectTooltip then
		return InspectTooltip:NumLines()
	end
	return tooltipData and tooltipData.lines and #tooltipData.lines or 0
end

local function GetTooltipLineData(i)
	local lineData
	if tooltipData then
		lineData = tooltipData.lines[i]
		return lineData, lineData.leftText
	elseif InspectTooltip then
		lineData = _G["OmniCDInspectToolTipTextLeft" .. i]
		return lineData, lineData:GetText()
	end
end

local function GetTooltipLineTextColor(lineData)
	if not lineData then
		return 1, 1, 1
	elseif tooltipData then
		return lineData.leftColor.r, lineData.leftColor.g, lineData.leftColor.b
	elseif InspectTooltip then
		return lineData:GetTextColor()
	end
end

local ITEM_LEVEL = gsub(ITEM_LEVEL,"%%d","(%%d+)")

local function FindAzeriteEssencePower(info, specID, list)
	local heartOfAzerothLevel
	local majorID

	local numLines = math.min(16, GetNumTooltipLines())
	for j = 2, numLines do
		local lineData, text = GetTooltipLineData(j)
		if text and text ~= "" then
			if not heartOfAzerothLevel then
				heartOfAzerothLevel = strmatch(text, ITEM_LEVEL)
				if heartOfAzerothLevel then
					heartOfAzerothLevel = tonumber(heartOfAzerothLevel)
				end
			elseif j > 10 then
				for essenceID, essencePowers in pairs(E.essenceData) do
					if strfind(text, essencePowers.name .. "$") == 1 then
						local r, _, b = GetTooltipLineTextColor(lineData)
						local rank = 3
						if r < .01 then
							rank = 2
						elseif r > .90 then
							rank = 4
						elseif b < .01 then
							rank = 1
						end

						if not majorID and GetTooltipLineData(j - 1) == " " then
							majorID = essencePowers[rank]
							local rank1 = essencePowers[1]
							info.talentData[rank1] = "AE"
							info.talentData["essMajorRank1"] = rank1
							info.talentData["essMajorID"] = majorID
							if list then
								list[#list + 1] = majorID .. ":AE"
							end

							if E.essMajorConflict[majorID] then
								local pvpTalent = E.pvpTalentsByEssMajorConflict[specID]
								if pvpTalent then
									info.talentData[pvpTalent] = "AE"
									if list then
										list[#list + 1] = pvpTalent
									end
								end
							end
							if rank1 ~= 296325 then
								break
							end
						end

						local minorID = essencePowers[rank + 4]
						if E.essMinorStrive[minorID] then

							local mult = (90.1 - ((heartOfAzerothLevel - 117) * 0.15)) / 100
							if P.isInPvPInstance then
								mult = 0.2 + mult * 0.8
							end
							mult = math.max(0.75, math.min(0.9, mult))
							info.talentData["essStriveMult"] = mult
							if list then
								list[#list + 1] = mult .. ":ae"
							end
							return
						end
						break
					end
				end
			end
		end
	end
end

local function FindAzeritePower(info, list)
	local numLines = GetNumTooltipLines()
	for j = 10, numLines do
		local _, text = GetTooltipLineData(j)
		if text and text ~= "" and strfind(text, "^-") == 1 then
			for _, v in pairs(E.spell_cxmod_azerite) do
				if strfind(text, v.name .. "$") == 3 then
					info.talentData[v.azerite] = "A"
					if list then list[#list + 1] = v.azerite .. ":A" end
					return
				end
			end
		end
	end
end

local S_ITEM_SET_NAME = "^" .. ITEM_SET_NAME:gsub("([%(%)])", "%%%1"):gsub("%%%d?$?d", "(%%d+)"):gsub("%%%d?$?s", "(.+)") .. "$"

local function FindSetBonus(info, specBonus, list)
	local bonusID, numRequired = specBonus[1], specBonus[2]
	local numLines = GetNumTooltipLines()
	for j = 10, numLines do
		local _, text = GetTooltipLineData(j)
		if text and text ~= "" then
			local name, numEquipped, numFullSet = strmatch(text, S_ITEM_SET_NAME)
			if name and numEquipped and numFullSet then
				numEquipped = tonumber(numEquipped)
				if numEquipped and numEquipped >= numRequired then
					info.talentData[bonusID] = "S"
					if list then list[#list + 1] = bonusID .. ":S" end

					local bonusID2 = specBonus[3]
					if bonusID2 and numEquipped >= specBonus[4] then
						info.talentData[bonusID2] = "S"
						if list then list[#list + 1] = bonusID2 .. ":S" end
					end
				end
				return bonusID
			end
		end
	end
end

local function FindCraftedRuneforgeLegendary(info, itemLink, list)
	local _,_,_,_,_,_,_,_,_,_,_,_,_, numBonusIDs, bonusIDs = strsplit(":", itemLink, 15)
	numBonusIDs = tonumber(numBonusIDs)
	if numBonusIDs and bonusIDs then
		local t = { strsplit(":", bonusIDs, numBonusIDs + 1) }
		for j = 1, numBonusIDs do
			local bonusID = t[j]
			bonusID = tonumber(bonusID)
			local runeforgeDescID = E.runeforge_bonus_to_descid[bonusID]
			if runeforgeDescID then
				if type(runeforgeDescID) == "table" then
					for _, descID in pairs(runeforgeDescID) do
						info.talentData[descID] = "R"
						if list then list[#list + 1] = descID .. ":R" end
					end
				else
					info.talentData[runeforgeDescID] = "R"
					if list then list[#list + 1] = runeforgeDescID .. ":R" end
				end
				return
			end
		end
	end
end

local runeforgeBaseItems = {
	[1]  = { 173245, 172317, 172325, 171415 },
	[2]  = { 178927, 178927, 178927, 178927 },
	[3]  = { 173247, 172319, 172327, 171417 },
	[5]  = { 173241, 172314, 172322, 171412 },
	[6]  = { 173248, 172320, 172328, 171418 },
	[7]  = { 173246, 172318, 172326, 171416 },
	[8]  = { 173243, 172315, 172323, 171413 },
	[9]  = { 173249, 172321, 172329, 171419 },
	[10] = { 173244, 172316, 172324, 171414 },
	[11] = { 178926, 178926, 178926, 178926 },
	[12] = { 178926, 178926, 178926, 178926 },
	[15] = { 173242, 173242, 173242, 173242 },
}

--[[
if we're separating player inspect:
	local itemID = GetInventoryItemID(unit, slotID)
	local itemLink = GetInventoryItemLink(unit, slotID)
	local itemLocation = ItemLocation:CreateFromEquipmentSlot(slotID)
	local isRuenforgeBaseItem = C_LegendaryCrafting.IsValidRuneforgeBaseItem(itemLocation)
	local isRuneforgeLegendary = C_LegendaryCrafting.IsRuneforgeLegendary(itemLocation)
]]
local function GetEquippedItemData(info, unit, specID, list)
	local moveToStale
	local numRuneforge = 0
	local numTierSetBonus = 0
	local foundTierSpecBonus
	local e
	if list then list[#list + 1] = "^M"; e = { "^E" }; end

	for i = 1, NUM_INVSLOTS do
		local slotID = INVSLOT_INDEX[i]
		local itemLink = GetInventoryItemLink(unit, slotID)
		if itemLink then
			local itemID, _,_,_,_,_, subclassID = GetItemInfoInstant(itemLink)
			if itemID then
				if i < 10 then
					local tierSetBonus = E.item_set_bonus[itemID]
					local equipBonusID = E.item_equip_bonus[itemID]
					subclassID = subclassID == 0 and 1 or subclassID
					local unityRuneforgeLegendary = E.item_unity[itemID]
					local isCraftedRuneforgeLegendary = numRuneforge <= 2
						and runeforgeBaseItems[slotID]
						and itemID == runeforgeBaseItems[slotID][subclassID]
					if InspectTooltip then
						InspectTooltip:SetInventoryItem(unit, slotID)
					else

						tooltipData = C_TooltipInfo.GetInventoryItem(unit, slotID)
						--[[ removed in 11.0
						if tooltipData and TooltipUtil.SurfaceArgs then
							TooltipUtil.SurfaceArgs(tooltipData)
							for _, line in ipairs(tooltipData.lines) do
							TooltipUtil.SurfaceArgs(line)
							end
						end
						]]
					end
					if equipBonusID then
						info.talentData[equipBonusID] = true
						if list then list[#list + 1] = equipBonusID .. ":S" end
					end
					if tierSetBonus then
						local specBonus = E.preCata and tierSetBonus or tierSetBonus[specID]
						if specBonus and numTierSetBonus < 2 and specBonus[1] ~= foundTierSpecBonus then
							foundTierSpecBonus = FindSetBonus(info, specBonus, list)
							if foundTierSpecBonus then
								numTierSetBonus = numTierSetBonus + 1
							end
						end

					elseif isCraftedRuneforgeLegendary then
						FindCraftedRuneforgeLegendary(info, itemLink, list)
						numRuneforge = numRuneforge + 1
					elseif unityRuneforgeLegendary then
						if type(unityRuneforgeLegendary) == "table" then
							for _, runeforgeDescID in pairs(unityRuneforgeLegendary) do
								info.talentData[runeforgeDescID] = "R"
								if list then list[#list + 1] = runeforgeDescID .. ":R" end
							end
						else
							info.talentData[unityRuneforgeLegendary] = "R"
							if list then list[#list + 1] = unityRuneforgeLegendary .. ":R" end
						end
						numRuneforge = numRuneforge + 1
					elseif itemID == 158075 then
						FindAzeriteEssencePower(info, specID, list)
					elseif C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(itemLink) then
						FindAzeritePower(info, list)
					end
					if InspectTooltip then
						InspectTooltip:ClearLines()
					end
				end
				itemID = E.item_merged[itemID] or itemID
				info.itemData[itemID] = true
				if e then e[#e + 1] = itemID end
			elseif not moveToStale then
				moveToStale = true
			end
		end
	end
	if e then
		list[#list + 1] = table.concat(e, ",")
		e = nil
	end

	return moveToStale
end


local talentIDFix = {
	[103211] = 377779,
	[103216] = 343240,
	[103224] = 377623
}


local talentChargeFix = {
	[5394] = true
}

local MAX_NUM_TALENTS = MAX_NUM_TALENTS or ((E.isWOTLKC or E.isCata) and 31 or 25)

local GetSelectedTalentData = (E.postDF and function(info, unit, isInspect)
	local list, c
	if not isInspect then
		list, c = { CM.SERIALIZATION_VERSION, info.spec, "^T" }, 4
	end

	for i = 1, 3 do
		local talentID
		if isInspect then
			talentID = C_SpecializationInfo_GetInspectSelectedPvpTalent(unit, i)
		else
			local slotInfo = C_SpecializationInfo_GetPvpTalentSlotInfo(i)
			talentID = slotInfo and slotInfo.selectedTalentID
		end
		if talentID then
			local _,_,_,_,_, spellID = GetPvpTalentInfoByID(talentID)
			info.talentData[spellID] = "PVP"
			if list then
				list[c] = -spellID
				c = c + 1
			end
		end
	end

	local configID = isInspect and Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID or C_ClassTalents.GetActiveConfigID()
	if configID then
		local configInfo = C_Traits.GetConfigInfo(configID)
		if configInfo then
			for _, treeID in ipairs(configInfo.treeIDs) do
				local treeNodes = C_Traits.GetTreeNodes(treeID)
				for _, treeNodeID in ipairs(treeNodes) do
					local treeNode = C_Traits_GetNodeInfo(configID, treeNodeID)
					local activeEntry = treeNode.activeEntry
					if activeEntry then
						local activeRank = treeNode.activeRank
						if activeRank > 0 then
							local activeEntryID = activeEntry.entryID
							local entryInfo = C_Traits.GetEntryInfo(configID, activeEntryID)
							local definitionID = entryInfo.definitionID
							if definitionID then
								local definitionInfo = C_Traits.GetDefinitionInfo(definitionID)
								local spellID = definitionInfo.spellID
								spellID = talentIDFix[activeEntryID] or spellID
								if spellID then
									if not treeNode.subTreeID or treeNode.subTreeActive then
										if talentChargeFix[spellID] then

											if talentChargeFix[spellID] == true then
												if info.talentData[spellID] then
													activeRank = 2
												end

											elseif talentChargeFix[spellID][info.spec] then
												activeRank = 2
											end
										end
										info.talentData[spellID] = activeRank
										if list then
											if activeRank > 1 then
												list[c] = format("%s:%s", spellID, activeRank)
											else
												list[c] = spellID
											end
											c = c + 1
										end
										--[[
										if treeNode.subTreeActive then

										end
										]]
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return list
end) or (E.isSL and function(info, unit, isInspect)
	local list
	if not isInspect then
		list = { CM.SERIALIZATION_VERSION, info.spec, "^T" }
	end

	for i = 1, 3 do
		local talentID
		if isInspect then
			talentID = C_SpecializationInfo_GetInspectSelectedPvpTalent(unit, i)
		else
			local slotInfo = C_SpecializationInfo_GetPvpTalentSlotInfo(i)
			talentID = slotInfo and slotInfo.selectedTalentID
		end
		if talentID then
			local _,_,_,_,_, spellID = GetPvpTalentInfoByID(talentID)
			info.talentData[spellID] = "PVP"
			if list then list[#list + 1] = -spellID end
		end
	end

	local specGroupIndex = 1
	for tier = 1, MAX_TALENT_TIERS do
		for column = 1, NUM_TALENT_COLUMNS do
			local _,_,_, selected, _, spellID = GetTalentInfo(tier, column, specGroupIndex , isInspect, unit)
			if selected then
				info.talentData[spellID] = true
				if list then list[#list + 1] = spellID end
				break
			end
		end
	end

	return list
end) or (E.isWOTLKC and function(info, unit, isInspect)
	local list
	if not isInspect then
		list = { CM.SERIALIZATION_VERSION, info.spec, "^T" }
	end

	local talentGroup = GetActiveTalentGroup and GetActiveTalentGroup(isInspect, nil)

	if list then
		for i = 1, 6 do
			local _,_, glyphSpellID = GetGlyphSocketInfo(i, talentGroup)
			if glyphSpellID then
				info.talentData[glyphSpellID] = true
				list[#list + 1] = glyphSpellID
			end
		end
	end

	for tabIndex = 1, 3 do
		for talentIndex = 1, MAX_NUM_TALENTS do
			local name, _,_,_, currentRank = GetTalentInfo(tabIndex, talentIndex, isInspect, unit, talentGroup)
			if not name then
				break
			end
			if currentRank > 0 then
				local talentRankIDs = E.talentNameToRankIDs[name]
				if talentRankIDs then
					if type(talentRankIDs[1]) == "table" then
						for _, t in pairs(talentRankIDs) do
							local talentID = t[currentRank]
							if talentID then
								info.talentData[talentID] = true
								if list then list[#list + 1] = talentID end
							end
						end
					else
						local talentID = talentRankIDs[currentRank]
						if talentID then
							info.talentData[talentID] = true
							if list then list[#list + 1] = talentID end
						end
					end
				end
			end
		end
	end

	return list
end) or (E.isCata and function(info, unit, isInspect)
	local list
	if not isInspect then
		list = { CM.SERIALIZATION_VERSION, 0, "^T" }
	end

	local talentGroup = GetActiveTalentGroup and GetActiveTalentGroup(isInspect, nil)


	local primaryTree = GetPrimaryTalentTree(isInspect, nil, talentGroup)
	if primaryTree then
		info.spec = primaryTree
		info.talentData[primaryTree] = true
		if list then
			list[2] = primaryTree
			list[#list + 1] = primaryTree
		end
	end

	if list then
		for i = 1, 9 do
			local _,_,_, glyphSpellID = GetGlyphSocketInfo(i, talentGroup)
			if glyphSpellID then
				info.talentData[glyphSpellID] = true
				list[#list + 1] = glyphSpellID
			end
		end
	end

	for tabIndex = 1, 3 do
		for talentIndex = 1, MAX_NUM_TALENTS do
			local name, _,_,_, currentRank = GetTalentInfo(tabIndex, talentIndex, isInspect, unit, talentGroup)
			if not name then
				break
			end
			if currentRank > 0 then
				local talentRankIDs = E.talentNameToRankIDs[name]
				if talentRankIDs then
					if type(talentRankIDs[1]) == "table" then
						for _, t in pairs(talentRankIDs) do
							local talentID = t[currentRank]
							if talentID then
								info.talentData[talentID] = true
								if list then list[#list + 1] = talentID end
							end
						end
					else
						local talentID = talentRankIDs[currentRank]
						if talentID then
							info.talentData[talentID] = true
							if list then list[#list + 1] = talentID end
						end
					end
				end
			end
		end
	end

	return list
end) or function(info, unit, isInspect)
	local list
	if not isInspect then
		list = { CM.SERIALIZATION_VERSION, info.spec, "^T" }
	end

	for tabIndex = 1, 3 do
		for talentIndex = 1, MAX_NUM_TALENTS do
			local name, _,_,_, currentRank = GetTalentInfo(tabIndex, talentIndex, isInspect, unit)
			if not name then
				break
			end
			if currentRank > 0 then
				local talentRankIDs = E.talentNameToRankIDs[name]
				if talentRankIDs then
					if type(talentRankIDs[1]) == "table" then
						for _, t in pairs(talentRankIDs) do
							local talentID = t[currentRank]
							if talentID then
								info.talentData[talentID] = true
								if list then list[#list + 1] = talentID end
							end
						end
					else
						local talentID = talentRankIDs[currentRank]
						if talentID then
							info.talentData[talentID] = true
							if list then list[#list + 1] = talentID end
						end
					end
				end
			end
		end
	end

	return list
end

function CM:InspectUnit(guid)
	local info = P.groupInfo[guid]


	if not info or self.syncedGroupMembers[guid] then
		self:DequeueInspect(guid)
		return
	end

	local unit = info.unit
	local specID = E.preCata and info.raceID or GetInspectSpecialization(unit)


	if not specID or specID == 0 then
		return
	end

	info.spec = specID
	if info.name == "" or info.name == UNKNOWN then
		info.name = GetUnitName(unit, true)
		info.nameWithoutRealm = UnitName(unit)
	end
	if info.level == 200 then
		local lvl = UnitLevel(unit)
		if lvl > 0 then
			info.level = lvl
		end
	end

	if UnitSpellHaste then
		info.spellHasteMult = 1/(1 + UnitSpellHaste(unit)/100)
	end

	wipe(info.talentData)
	wipe(info.itemData)

	GetSelectedTalentData(info, unit, true)
	local failed = GetEquippedItemData(info, unit, specID)

	self:DequeueInspect(guid, failed)
	info:SetupBar()
end

local enhancedSoulbindRowRenownLevel = {
	[1]  = { [1] = 63, [3] = 66, [5] = 68, [6] = 72, [8] = 73, [10] = 78 },
	[2]  = { [1] = 61, [3] = 64, [5] = 67, [6] = 70, [8] = 75, [10] = 79 },
	[3]  = { [1] = 62, [3] = 65, [5] = 69, [6] = 71, [8] = 74, [10] = 77 },
	[4]  = { [1] = 63, [3] = 66, [5] = 68, [6] = 72, [8] = 73, [10] = 78 },
	[5]  = { [1] = 61, [3] = 64, [5] = 67, [6] = 70, [8] = 75, [10] = 79 },
	[6]  = { [1] = 62, [3] = 65, [5] = 69, [6] = 71, [8] = 74, [10] = 77 },
	[7]  = { [1] = 63, [3] = 66, [5] = 68, [6] = 72, [8] = 73, [10] = 78 },
	[8]  = { [1] = 63, [3] = 66, [5] = 68, [6] = 72, [8] = 73, [10] = 78 },
	[9]  = { [1] = 61, [3] = 64, [5] = 67, [6] = 70, [8] = 75, [10] = 79 },
	[10] = { [1] = 62, [3] = 65, [5] = 69, [6] = 71, [8] = 74, [10] = 77 },
	[13] = { [1] = 61, [3] = 64, [5] = 67, [6] = 70, [8] = 75, [10] = 79 },
	[18] = { [1] = 62, [3] = 65, [5] = 69, [6] = 71, [8] = 74, [10] = 77 },
}

local function IsSoulbindRowEnhanced(soulbindID, row, renownLevel)
	local minLevel = enhancedSoulbindRowRenownLevel[soulbindID] and enhancedSoulbindRowRenownLevel[soulbindID][row]
	if minLevel then
		return renownLevel >= minLevel
	end
end

local function GetCovenantSoulbindData(info, list)
	wipe(info.shadowlandsData)

	local covenantID = C_Covenants.GetActiveCovenantID()
	if covenantID == 0 then
		return
	end

	local covenantSpellID = E.covenant_to_spellid[covenantID]
	info.shadowlandsData.covenantID = covenantID
	info.talentData[covenantSpellID] = "C"
	list[#list + 1] = "^C," .. covenantID

	local soulbindID = C_Soulbinds.GetActiveSoulbindID()
	if soulbindID == 0 then
		return
	end

	info.shadowlandsData.soulbindID = soulbindID
	list[#list + 1] = soulbindID

	local soulbindData = C_Soulbinds.GetSoulbindData(soulbindID)
	local nodes = soulbindData.tree and soulbindData.tree.nodes
	if not nodes then
		return
	end

	local renownLevel = C_CovenantSanctumUI.GetRenownLevel()
	for i = 1, #nodes do
		local node = nodes[i]
		if node.state == Enum.SoulbindNodeState.Selected then
			local conduitID, conduitRank, row, spellID = node.conduitID, node.conduitRank, node.row, node.spellID
			if conduitID ~= 0 then
				spellID = C_Soulbinds_GetConduitSpellID(conduitID, conduitRank)
				if IsSoulbindRowEnhanced(soulbindID, row, renownLevel) then
					conduitRank = conduitRank + 2
				end
				local rankValue = E.soulbind_conduits_rank[spellID] and (E.soulbind_conduits_rank[spellID][conduitRank]
				or E.soulbind_conduits_rank[spellID][1])
				if rankValue then
					info.talentData[spellID] = rankValue
					list[#list + 1] = format("%s:%s", spellID, rankValue)
				end
			elseif E.soulbind_abilities[spellID] then
				info.talentData[spellID] = 0
				list[#list + 1] = spellID
			end
		end
	end
end

function CM:InspectUser()
	local info = P.userInfo
	local specID

	if E.preCata then
		specID = info.raceID
	else
		local specIndex = GetSpecialization()
		specID = GetSpecializationInfo(specIndex)
	end

	if not specID or specID == 0 then
		return false
	end
	info.spec = specID

	wipe(info.talentData)
	wipe(info.itemData)

	local dataList = GetSelectedTalentData(info, "player")
	GetEquippedItemData(info, "player", specID, dataList)

	if E.postSL then
		GetCovenantSoulbindData(info, dataList)
		info.spellHasteMult = 1/(1 + UnitSpellHaste("player")/100)

	elseif E.isClassic or E.isBCC then
		local speed = UnitRangedDamage("player")
		if speed and speed > 0 then
			info.rangedWeaponSpeed = speed
			dataList[#dataList + 1] = -speed
		end
	end

	local serializedData = table.concat(dataList, ","):gsub(",%^", "^")
	local compressedData = LibDeflate:CompressDeflate(serializedData)
	local encodedData = LibDeflate:EncodeForWoWAddonChannel(compressedData)
	self.serializedSyncData = encodedData


	if P.groupInfo[info.guid] then
		CM:RefreshCooldownSyncIDs(info)
		info:SetupBar()
		CM:AssignSpellIDsToCooldownSyncIDs(info)
	end

	return true
end
