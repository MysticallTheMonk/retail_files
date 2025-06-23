--
-- OmniAuras
--	Track auras on any Blizzard frame.
--	Copyright 2018-2025 Treebonker. All rights reserved.
--
--	https://www.curseforge.com/wow/addons/omniauras
--
local E, L = unpack(select(2, ...))

local pairs, ipairs, strfind, min, floor = pairs, ipairs, strfind, min, floor
local GetTime, GetNumGroupMembers = GetTime, GetNumGroupMembers
local UnitExists, UnitGUID, UnitIsUnit, UnitCanAttack, UnitIsPlayer = UnitExists, UnitGUID, UnitIsUnit, UnitCanAttack, UnitIsPlayer
local UnitPlayerControlled, UnitIsPossessed = UnitPlayerControlled, UnitIsPossessed
local AuraUtil_ForEachAura = AuraUtil.ForEachAura
local AuraUtil_IsPriorityDebuff = AuraUtil.IsPriorityDebuff
local AuraUtil_ShouldDisplayBuff = AuraUtil.ShouldDisplayBuff
local AuraUtil_ShouldDisplayDebuff = AuraUtil.ShouldDisplayDebuff
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local C_UnitAuras_GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
local band = bit.band
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitChannelInfo = UnitChannelInfo
local module = E.Aura
local db
local userGUID = E.userGUID

local Aura_Enabled = { raidFrame = {}, nameplate = {}, friendlyNameplate = {}, unitFrame = {}, arenaFrame = {}, playerFrame = {}, largerIcon = {}, glow = {}, byPlayer = {} }
local Aura_NoFriend = {}
local Aura_Blacklist

local UnitFrameContainer = {}
local CompactUnitFrameContainer = {}
local NameplateContainer = {}
local ActiveContainer = { HARMFUL = {}, HELPFUL = {}, MYHELPFUL = {} }
local ActiveCompactUnitFrame = {}
local ActiveNameplate = {}
local SpellLockedGUIDS = {}
local CallbackTimers = {}
local DispellableDebuffType = {}

-- Option max values
local NUM_RF_OVERLAYS = { HARMFUL = 15, HELPFUL = 3, MYHELPFUL = 9 }
local NUM_AF_OVERLAYS = { HARMFUL = 6, HELPFUL = 3 }
local NUM_NP_OVERLAYS = 12
local NUM_UF_OVERLAYS = 1

local BASE_ICON_HEIGHT = 39
local UNDETACHEDFRAME_LASTINDEX = NUM_RF_OVERLAYS.HARMFUL - 6 -- detached max value

local AuraComparator = {}

function AuraComparator.default(a, b)
	local aFromPlayer = (a.sourceUnit ~= nil) and UnitIsUnit("player", a.sourceUnit) or false;
	local bFromPlayer = (b.sourceUnit ~= nil) and UnitIsUnit("player", b.sourceUnit) or false;
	if aFromPlayer ~= bFromPlayer then
		return aFromPlayer;
	end

	if a.canApplyAura ~= b.canApplyAura then
		return a.canApplyAura;
	end

	return a.auraInstanceID < b.auraInstanceID;
end

function AuraComparator.none(a, b)
	if a.canApplyAura ~= b.canApplyAura then
		return a.canApplyAura
	end
	return a.auraInstanceID < b.auraInstanceID
end

function AuraComparator.prioOld(a, b)
	if a.priority ~= b.priority then
		return a.priority > b.priority
	end
	return a.auraInstanceID < b.auraInstanceID
end

function AuraComparator.prioNew(a, b)
	if a.priority ~= b.priority then
		return a.priority > b.priority
	end
	return a.auraInstanceID > b.auraInstanceID
end

function AuraComparator.scaleOld(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	return a.auraInstanceID < b.auraInstanceID
end

function AuraComparator.scaleNew(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	return a.auraInstanceID > b.auraInstanceID
end

function AuraComparator.scalePrioOld(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	return AuraComparator.prioOld(a, b)
end

function AuraComparator.scalePrioNew(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	return AuraComparator.prioNew(a, b)
end

function AuraComparator.scaleDebuffOld(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	if a.isHarmful ~= b.isHarmful then
		return a.isHarmful
	end
	return a.auraInstanceID < b.auraInstanceID
end

function AuraComparator.scaleDebuffNew(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	if a.isHarmful ~= b.isHarmful then
		return a.isHarmful
	end
	return a.auraInstanceID > b.auraInstanceID
end

function AuraComparator.scaleBuffOld(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	if a.isHarmful ~= b.isHarmful then
		return b.isHarmful
	end
	return a.auraInstanceID < b.auraInstanceID
end

function AuraComparator.scaleBuffNew(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	if a.isHarmful ~= b.isHarmful then
		return b.isHarmful
	end
	return a.auraInstanceID > b.auraInstanceID
end

function AuraComparator.scaleDebuffPrioOld(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	if a.isHarmful ~= b.isHarmful then
		return a.isHarmful
	end
	return AuraComparator.prioOld(a, b)
end

function AuraComparator.scaleDebuffPrioNew(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	if a.isHarmful ~= b.isHarmful then
		return a.isHarmful
	end
	return AuraComparator.prioNew(a, b)
end

function AuraComparator.scaleBuffPrioOld(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	if a.isHarmful ~= b.isHarmful then
		return b.isHarmful
	end
	return AuraComparator.prioOld(a, b)
end

function AuraComparator.scaleBuffPrioNew(a, b)
	if a.scale ~= b.scale then
		return a.scale > b.scale
	end
	if a.isHarmful ~= b.isHarmful then
		return b.isHarmful
	end
	return AuraComparator.prioNew(a, b)
end

local AuraTooltip = CreateFrame("GameTooltip", "OmniAurasAuraTooltip", UIParent, "GameTooltipTemplate")
local TOOLTIP_UPDATE_TIME = 0.2
AuraTooltip.updateTooltipTimer = TOOLTIP_UPDATE_TIME

-- in DF, tooltip shows an empty text if the spell hasn't been cached yet
local function AuraTooltip_OnUpdate(self, elapsed)
	if module.isInTestMode then
		return
	end

	self.updateTooltipTimer = self.updateTooltipTimer - elapsed
	if self.updateTooltipTimer > 0 then
		return
	end
	self.updateTooltipTimer = TOOLTIP_UPDATE_TIME
	local owner = self:GetOwner()
	if owner then
		if owner.container.filter == "HELPFUL" then
			self:SetUnitBuffByAuraInstanceID(owner.container.unit, owner.auraInstanceID, owner.filter)
		else
			if owner.isBossBuff then
				self:SetUnitBuffByAuraInstanceID(owner.container.unit, owner.auraInstanceID, owner.filter)
			else
				self:SetUnitDebuffByAuraInstanceID(owner.container.unit, owner.auraInstanceID, owner.filter)
			end
		end

		if E.global.quickBlacklist then
			local spellId = owner.spellId
			if spellId and Aura_Blacklist[spellId] == nil and IsControlKeyDown() and IsAltKeyDown() then
				local spellName = C_Spell.GetSpellName(spellId)
				Aura_Blacklist[spellId] = true
				E:AddAuraToBlacklist(spellId)
				E:ACR_NotifyChange()
				module:Refresh()
				E.write(format(L["%s added to blacklist"], spellName))
			end
		end
	end
end
AuraTooltip:SetScript("OnUpdate", AuraTooltip_OnUpdate)

local function Overlay_OnEnter(self)
	AuraTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
	if module.isInTestMode and self.spellId then -- test auras have fake auraInstanceID
		AuraTooltip:SetSpellByID(self.spellId)
	elseif self.auraInstanceID then
		if self.container.filter == "HELPFUL" then
			AuraTooltip:SetUnitBuffByAuraInstanceID(self.container.unit, self.auraInstanceID, self.filter)
		else
			if self.isBossBuff then
				AuraTooltip:SetUnitBuffByAuraInstanceID(self.container.unit, self.auraInstanceID, self.filter)
			else
				AuraTooltip:SetUnitDebuffByAuraInstanceID(self.container.unit, self.auraInstanceID, self.filter)
			end
		end
	end
end

local function Overlay_OnLeave()
	AuraTooltip:Hide()
end

local function ClearHideOverlayFrame(self)
	self:Hide()
	if self.spellId then
		self.spellId = nil
		self.expirationTime = nil
		self.stack = nil
		self.iconTexture = nil
		self.cooldown:Clear()
		self.debuffScale = nil
	end
	if self.HighlightFlash.Anim:IsPlaying() then
		self.HighlightFlash.Anim:Stop()
		self.HighlightFlash:Hide()
	end
end

local pendingPassThroughButtons = {}
local function UpdatePassThroughButtons()
	for i = #pendingPassThroughButtons, 1, -1 do
		local overlay = pendingPassThroughButtons[i]
		overlay:SetPassThroughButtons("LeftButton", "RightButton")
		overlay.isPassThrough = true
		if overlay.container.db.showTooltip then
			overlay:EnableMouse(true)
		end
		pendingPassThroughButtons[i] = nil
	end
end

local textureUVs = {
	"borderTop", "borderBottom", "borderRight", "borderLeft",
}

local function CreateOverlay(container, inherit)
	local overlay = CreateFrame("Button", nil, container, inherit or "OmniAurasUnitAuraTemplate")
	overlay.container = container
	overlay.cooldown.counter = overlay.cooldown:GetRegions()
	overlay.count = overlay.CountFrame.Count
	if container.frameType ~= "unitFrame" then -- TT
		overlay:SetScript("OnEnter", Overlay_OnEnter)
		overlay:SetScript("OnLeave", Overlay_OnLeave)
		if overlay.SetPassThroughButtons then
			if module.inLockdown then
				tinsert(pendingPassThroughButtons, overlay)
			else
				overlay:SetPassThroughButtons("LeftButton", "RightButton")
				overlay.isPassThrough = true
			end
		end
	end
	for _, pieceName in ipairs(textureUVs) do
		local region = overlay[pieceName]
		if region then
			region:SetTexelSnappingBias(0.0)
			region:SetSnapToPixelGrid(false)
		end
	end
	overlay.icon:SetTexelSnappingBias(0.0)
	overlay.icon:SetSnapToPixelGrid(false)
	return overlay
end

local DebuffTypeColor = { }
DebuffTypeColor["none"] = { r = 0.80, g = 0, b = 0 }
DebuffTypeColor["Magic"] = { r = 0.20, g = 0.60, b = 1.00 }
DebuffTypeColor["Curse"] = { r = 0.60, g = 0.00, b = 1.00 }
DebuffTypeColor["Disease"] = { r = 0.60, g = 0.40, b = 0 }
DebuffTypeColor["Poison"] = { r = 0.00, g = 0.60, b = 0 }
DebuffTypeColor[""] = DebuffTypeColor["none"]

local AdjustedDebuffTypeColor = {}
local AdjustedDebuffTypeColorArena = {}
local AdjustedDebuffTypeColorNamePlate = {}

local UnitFrameDebuffType_BossDebuff = 5
local UnitFrameDebuffType_BossBuff = 4
local UnitFrameDebuffType_PriorityDebuff = 3
local UnitFrameDebuffType_NonBossRaidDebuff = 2
local UnitFrameDebuffType_NonBossDebuff = 1

--
-- Unit Frame
--

local UnitFrameMixin = {}

function UnitFrameMixin:ProcessAura(aura)
	if not aura or not aura.name then
		return false
	end
	local spellId, sourceUnit = aura.spellId, aura.sourceUnit
	local enabledAuraData = not Aura_Blacklist[spellId] and self.enabledAura[spellId]
	if enabledAuraData
		and (self.isMerged or aura[self.auraType])
		and (not Aura_NoFriend[spellId] or (self.auraType == "isHarmful" and sourceUnit and UnitCanAttack("player", sourceUnit))) then
		aura.priority = self.priority[ enabledAuraData[1] ]
		aura.forceGlow = self.db.alwaysGlowCC and (enabledAuraData[1] == "hardCC" or enabledAuraData[1] == "softCC")
		return true
	end
end

function UnitFrameMixin:ParseAllAuras(unit)
	if module.isInTestMode then
		module.InjectTestAuras(self)
		return
	end

	if self.auraInfo == nil then
		self.auraInfo = TableUtil.CreatePriorityTable(self.sorter, true)
	else
		self.auraInfo:Clear()
	end

	local batchCount = nil
	local usePackedAura = true
	local function HandleAura(aura)
		local type = self:ProcessAura(aura)
		if type then
			self.auraInfo[aura.auraInstanceID] = aura
		end
	end
	AuraUtil_ForEachAura(unit, self.filter, batchCount, HandleAura, usePackedAura)

	if self.filter == "HARMFUL" then
		local guid = self.guid or UnitGUID(unit)
		if SpellLockedGUIDS[guid] then
			for auraInstanceID, callbackTimer in pairs(SpellLockedGUIDS[guid]) do
				--local aura = callbackTimer.args[3] -- can use src table for if scale and priority doesn't change
				local aura = E:DeepCopy(callbackTimer.args[3])
				aura.priority = self.priority.softCC + 1
				self.auraInfo[auraInstanceID] = aura
			end
		end
		if self.isMerged then
			AuraUtil_ForEachAura(unit, "HELPFUL", batchCount, HandleAura, usePackedAura)
		end
	end
end

function UnitFrameMixin:OnEvent(event, ...)
	if event == "UNIT_AURA" then
		local unit, unitAuraUpdateInfo, auraChanged = ...

		if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or self.auraInfo == nil then
			self:ParseAllAuras(unit)
			auraChanged = true
		else
			if unitAuraUpdateInfo.addedAuras ~= nil then
				for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
					local type = self:ProcessAura(aura)
					if type then
						self.auraInfo[aura.auraInstanceID] = aura
						auraChanged = true
					end
				end
			end

			if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
				for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
					if self.auraInfo[auraInstanceID] ~= nil then
						local newAura = C_UnitAuras_GetAuraDataByAuraInstanceID(unit, auraInstanceID)
						if newAura ~= nil then
							newAura.priority = self.auraInfo[auraInstanceID].priority
							newAura.scale = self.auraInfo[auraInstanceID].scale
						end
						self.auraInfo[auraInstanceID] = newAura
						auraChanged = true
					end
				end
			end

			if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
				for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
					if self.auraInfo[auraInstanceID] ~= nil then
						self.auraInfo[auraInstanceID] = nil
						auraChanged = true
					end
				end
			end
		end

		if auraChanged then
			local aura = self.auraInfo:GetTop()
			if not aura then
				local ol = self[1]
				ClearHideOverlayFrame(ol)
				return
			end

			local count, expirationTime, spellId, icon, duration = aura.applications, aura.expirationTime, aura.spellId, aura.icon, aura.duration
			local overlay = self[1]
			if spellId ~= overlay.spellId or aura.expirationTime ~= overlay.expirationTime or count ~= overlay.stack then
				if count > 1 then
					overlay.count:SetText(count)
					overlay.count:Show()
				else
					overlay.count:Hide()
				end
				overlay.icon:SetTexture(icon)
				if expirationTime > 0 then
					local startTime = expirationTime - duration
					overlay.cooldown:SetCooldown(startTime, duration)
					if self.shouldGlow and (Aura_Enabled.glow[spellId] or aura.forceGlow) and spellId ~= overlay.spellId and GetTime() - startTime < 0.1 then
						overlay.HighlightFlash:Show()
						overlay.HighlightFlash.Anim:Play()
					elseif overlay.HighlightFlash.Anim:IsPlaying() then
						overlay.HighlightFlash.Anim:Stop()
						overlay.HighlightFlash:Hide()
					end
				else
					overlay.cooldown:Clear()
					if overlay.HighlightFlash.Anim:IsPlaying() then
						overlay.HighlightFlash.Anim:Stop()
						overlay.HighlightFlash:Hide()
					end
				end
				overlay.spellId = spellId
				overlay.expirationTime = expirationTime
				overlay.stack = count
				overlay.iconTexture = icon
				overlay:Show()
			end
		end
	elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
		local unit = self.unit
		local guid = UnitGUID(unit)
		-- Toggle visibility for manual position --> Required for all (Portrait, auto) as we can no longer parent to UF
		if guid then
			self.guid = guid
			self:OnEvent("UNIT_AURA", unit, nil)
			self:Show()
		else
			self:Hide()
		end
	end
end

function UnitFrameMixin:UpdateSettings(filter, uf, unitTypeDB, isMerged, enabledAura)
	local db = unitTypeDB[filter]
	local isHARMFUL = filter == "HARMFUL"
	local isManual = db.preset == "MANUAL"

	-- Container settings
	self.isMerged = isMerged
	self.shouldGlow = db.preset ~= "PORTRAIT" and db.glow
	self.priority = unitTypeDB.priority
	self.sorter = AuraComparator[db.sortby]
	self.db = db
	self.enabledAura = unitTypeDB.showCCOnly and enabledAura.CC or enabledAura

	-- Overlay settings
	local size = BASE_ICON_HEIGHT * db.scale
	local iconScale = (size - size % E.PixelMult) / BASE_ICON_HEIGHT -- self:GetParent() == UIParent
	local edgeSize = E.PixelMult / iconScale
	local r, g, b = db.borderColor.r, db.borderColor.g, db.borderColor.b

	for j = 1, NUM_UF_OVERLAYS do
		local overlay = self[j]
		ClearHideOverlayFrame(overlay)

		overlay:ClearAllPoints()
		if db.preset == "PORTRAIT" then
			overlay:SetParent(overlay.portraitParent)
			overlay:SetFrameLevel(overlay.portraitParent:GetFrameLevel())
			overlay:SetScale(1.0)
			overlay:SetAlpha(1.0)
			overlay:EnableMouse(false)
			-- portrait's textureSubLevel is 1 and frameart is 2 so we need to lower the
			-- portrait textureSubLevel to place our texture in between
			overlay.icon:SetDrawLayer("BACKGROUND", 1)
			overlay.portrait:SetDrawLayer("BACKGROUND", -1)
			overlay:SetAllPoints(overlay.portrait)
			--[[ old ArenaEnemyFrame
			if unitType == "arena" then -- fix misalignment
				overlay:SetPoint("BOTTOMLEFT", overlay.portrait, 4, 4)
			end
			]]
			if not overlay.mask then
				overlay.mask = overlay:CreateMaskTexture()
				overlay.mask:SetAllPoints(overlay.icon)
				overlay.mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
			end
			overlay.icon:AddMaskTexture(overlay.mask)
			overlay.Border:Hide()
			overlay.borderTop:Hide()
			overlay.borderBottom:Hide()
			overlay.borderLeft:Hide()
			overlay.borderRight:Hide()
			overlay.icon:SetTexCoord(0, 1, 0, 1)
			overlay.cooldown:ClearAllPoints()
			overlay.cooldown:SetPoint("TOPLEFT", 2, -2.5)
			overlay.cooldown:SetPoint("BOTTOMRIGHT", -2.5, 2)
			overlay.cooldown:SetSwipeTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
			overlay.cooldown:SetDrawEdge(false)
		else
			overlay:SetParent(overlay.container)
			overlay:SetFrameLevel(600) -- target, focus frame texture is 500

			overlay:SetScale(iconScale)
			overlay:SetAlpha(db.opacity)
			overlay:EnableMouse(module.isInTestMode and isManual)
			if overlay.mask then
				overlay.icon:RemoveMaskTexture(overlay.mask)
				overlay.icon:SetDrawLayer("ARTWORK", 0)
			end
			if isManual then
				overlay:SetPoint("CENTER")
				E.LoadPosition(overlay.container)
				if module.isInTestMode then
					if not overlay.name then
						overlay.name = overlay:CreateFontString(nil, "OVERLAY", "UFCounter-OmniAuras")
						overlay.name:SetPoint("TOP", overlay, "BOTTOM", 0, -5)
					end
					overlay.name:SetFormattedText("%s|%s%s", self.unit, isHARMFUL and "debuffs" or "buffs",
						unitTypeDB.mergeAuraFrame and " + buffs" or "")
				end
			else
				if j == 1 then
					overlay:SetPoint(db.point, uf, db.relativePoint, db.offsetX, db.offsetY)
				else
					overlay:SetPoint(db.point, self[j-1], db.relativePoint)
				end
			end
			if db.borderType == "texture" then
				overlay.borderTop:Hide()
				overlay.borderBottom:Hide()
				overlay.borderLeft:Hide()
				overlay.borderRight:Hide()
				overlay.Border:Show()
				overlay.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			else
				overlay.Border:Hide()

				overlay.borderTop:ClearAllPoints()
				overlay.borderTop:SetPoint("TOPLEFT", overlay, "TOPLEFT")
				overlay.borderTop:SetPoint("BOTTOMRIGHT", overlay, "TOPRIGHT", 0, -edgeSize)
				overlay.borderTop:SetVertexColor(r, g, b)
				overlay.borderTop:Show()

				overlay.borderBottom:ClearAllPoints()
				overlay.borderBottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT")
				overlay.borderBottom:SetPoint("TOPRIGHT", overlay, "BOTTOMRIGHT", 0, edgeSize)
				overlay.borderBottom:SetVertexColor(r, g, b)
				overlay.borderBottom:Show()

				overlay.borderRight:ClearAllPoints()
				overlay.borderRight:SetPoint("TOPRIGHT", overlay.borderTop, "BOTTOMRIGHT")
				overlay.borderRight:SetPoint("BOTTOMLEFT", overlay.borderBottom, "TOPRIGHT", -edgeSize, 0)
				overlay.borderRight:SetVertexColor(r, g, b)
				overlay.borderRight:Show()

				overlay.borderLeft:ClearAllPoints()
				overlay.borderLeft:SetPoint("TOPLEFT", overlay.borderTop, "BOTTOMLEFT")
				overlay.borderLeft:SetPoint("BOTTOMRIGHT", overlay.borderBottom, "TOPLEFT", edgeSize, 0)
				overlay.borderLeft:SetVertexColor(r, g, b)
				overlay.borderLeft:Show()

				overlay.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			end
			overlay.cooldown:ClearAllPoints()
			overlay.cooldown:SetAllPoints()
			overlay.cooldown:SetSwipeTexture("", 0, 0, 0, 1)
			overlay.cooldown:SetDrawEdge(db.drawEdge)
		end
		overlay.cooldown:SetSwipeColor(0, 0, 0, db.swipeAlpha)
		overlay.cooldown.counter:SetScale(db.counterScale)
		overlay.cooldown:SetHideCountdownNumbers(db.hideCounter)
		if overlay.name then
			overlay.name:SetShown(isManual and module.isInTestMode)
		end
	end
end

--
-- compact Arena Frame
--

local BOSS_DEBUFF_SIZE_INCREASE = 9
local CUF_NAME_SECTION_SIZE = 15
local CUF_AURA_BOTTOM_OFFSET = 2
local NATIVE_UNIT_FRAME_HEIGHT = 36
local NATIVE_UNIT_FRAME_WIDTH = 72

local CompactRaidGroupTypeEnumParty = CompactRaidGroupTypeEnum.Party	-- 4
local CompactRaidGroupTypeEnumRaid = CompactRaidGroupTypeEnum.Raid	-- 5
local CompactRaidGroupTypeEnumArena = CompactRaidGroupTypeEnum.Arena	-- 7

local BuffFrameBase = {
	[CompactRaidGroupTypeEnumParty] = {},
	[CompactRaidGroupTypeEnumRaid] = {},
	[CompactRaidGroupTypeEnumArena] = {}
}

local function GetOptionDisplayPowerBar(systemIndex)
	local options = DefaultCompactUnitFrameSetupOptions
	if systemIndex == CompactRaidGroupTypeEnumArena then
		return options.pvpDisplayPowerBar
	else
		return options.displayPowerBar
	end
end

function module:SetBuffFrameBase()
	for systemIndex, base in pairs(BuffFrameBase) do
		local frameDB = systemIndex == CompactRaidGroupTypeEnumArena and db.unitFrame.arena or db.raidFrame
		local frameWidth = EditModeManagerFrame:GetRaidFrameWidth(systemIndex)
		local frameHeight = EditModeManagerFrame:GetRaidFrameHeight(systemIndex)
		local componentScale = min(frameHeight / NATIVE_UNIT_FRAME_HEIGHT, frameWidth / NATIVE_UNIT_FRAME_WIDTH)
		local buffSize = min(frameDB.globalScale, 11 * componentScale)

		local powerBarHeight = 8
		local displayPowerBar = GetOptionDisplayPowerBar(systemIndex)
		local powerBarUsedHeight = displayPowerBar and powerBarHeight or 0
		local maxDebuffSize = frameHeight - powerBarUsedHeight - CUF_AURA_BOTTOM_OFFSET - CUF_NAME_SECTION_SIZE

		base.baseSize = buffSize
		base.maxScale = maxDebuffSize / buffSize

		local usableSpace = frameWidth - 6 -- default padding
		if systemIndex == CompactRaidGroupTypeEnumArena then
			if frameDB.HARMFUL.preset == "overDebuffs" then
				base.totInnerDebuffs = usableSpace / buffSize -- can be greater than NUM_AF_OVERLAYS
			end
		else
			local totInnerDebuffs
			local numInnerDebuffs
			local shouldDetachBigDebuffs

			if frameDB.HARMFUL.preset == "overDebuffs" then
				if frameDB.HARMFUL.detachBigDebuffs[self.zone] and systemIndex == CompactRaidGroupTypeEnumParty then
					shouldDetachBigDebuffs = true
				end
				if not frameDB.MYHELPFUL.enabled or frameDB.MYHELPFUL.preset == "overBuffs" then
					local debuffSpace = usableSpace - (3 * buffSize + 3) -- our center padding
					totInnerDebuffs = debuffSpace / buffSize
					numInnerDebuffs = floor(totInnerDebuffs)
				elseif frameDB.MYHELPFUL.preset == "raidFrameRight" then
					totInnerDebuffs = usableSpace / buffSize
					numInnerDebuffs = floor(totInnerDebuffs)
				end
			end
			base.totInnerDebuffs = totInnerDebuffs -- no limit if nil
			base.numInnerDebuffs = numInnerDebuffs

			-- Limit how many skipped frames we can compensate
			base.totDebuffs = shouldDetachBigDebuffs and UNDETACHEDFRAME_LASTINDEX
				or (numInnerDebuffs and min(9 + numInnerDebuffs, NUM_RF_OVERLAYS.HARMFUL) or NUM_RF_OVERLAYS.HARMFUL)
			-- Limit maxIcons by group type to avoid covering adjacent frames (anchor set to L/R of raidframe isn't affected)
			base.maxOverlays = base.maxOverlays or {}
			if systemIndex == CompactRaidGroupTypeEnumParty then
				base.maxOverlays.HARMFUL = min(base.totDebuffs, frameDB.HARMFUL.maxIcons)
				base.maxOverlays.MYHELPFUL = frameDB.MYHELPFUL.maxIcons
				base.shouldDetachBigDebuffs = shouldDetachBigDebuffs
				base.alwaysShowMaxNumIcons = frameDB.HARMFUL.alwaysShowMaxNumIcons
			else
				base.maxOverlays.HARMFUL = min(numInnerDebuffs or 3, frameDB.HARMFUL.maxIcons)
				base.maxOverlays.MYHELPFUL = min(6, frameDB.MYHELPFUL.maxIcons)
			end

			base.bossScale = min(maxDebuffSize, buffSize + BOSS_DEBUFF_SIZE_INCREASE) / buffSize

			local dispellableNPCSizeIncrease = frameDB.HARMFUL.dispellableNPCSizeIncrease or 0
			base.dispellableScale = dispellableNPCSizeIncrease > 0 and min(maxDebuffSize, buffSize + dispellableNPCSizeIncrease) / buffSize
		end

		local counterScale = componentScale / 2 -- Set to 1 when CUF is at max size (i.e. componentScale == 2)
		counterScale = counterScale * (buffSize / (11 * componentScale)) -- match legacy counter size as non-legacy overlay scaling goes much higher
		base.currCounterScale = counterScale
	end
end

local CompactArenaFrameMixin = {}

function CompactArenaFrameMixin:ProcessAura(aura)
	if not aura or not aura.name then
		return false
	end
	local spellId = aura.spellId
	if not Aura_Blacklist[spellId] then
		local enabledAuraData = self.enabledAura[spellId]
		if enabledAuraData then
			if (self.isMerged or aura[self.auraType])
				and (not Aura_NoFriend[spellId] or (self.auraType == "isHarmful" and aura.sourceUnit and UnitCanAttack("player", aura.sourceUnit))) then
				local type = enabledAuraData[1]
				local scale = self.db.typeScale and self.db.typeScale[type] or 1
				if self.db.largerIcon and Aura_Enabled.largerIcon[spellId] then
					scale = scale * self.db.largerIcon
				end
				aura.scale = scale
				aura.priority = self.priority[type]
				aura.forceGlow = self.db.alwaysGlowCC and (enabledAuraData[1] == "hardCC" or enabledAuraData[1] == "softCC")
				return true
			end
		elseif self.db.redirectBlizzardDebuffs then
			local priority
			if aura.isBossAura then
				priority = aura.isHarmful and UnitFrameDebuffType_BossDebuff or UnitFrameDebuffType_BossBuff
			elseif aura.isHarmful then
				if AuraUtil_IsPriorityDebuff(spellId) then
					priority = UnitFrameDebuffType_PriorityDebuff
				elseif AuraUtil_ShouldDisplayDebuff(aura.sourceUnit, spellId) then
					priority = UnitFrameDebuffType_NonBossDebuff
				end
			end
			if priority then
				aura.scale = aura.isBossAura and BuffFrameBase[self.systemIndex].bossScale or 1
				aura.priority = priority
				return true
			end
		end
	end
end

function CompactArenaFrameMixin:ParseAllAuras(unit)
	if module.isInTestMode then
		module.InjectTestAuras(self)
		return
	end

	if self.auraInfo == nil then
		self.auraInfo = TableUtil.CreatePriorityTable(self.sorter, true)
	else
		self.auraInfo:Clear()
	end

	local batchCount = nil
	local usePackedAura = true
	local function HandleAura(aura)
		local type = self:ProcessAura(aura)
		if type then
			self.auraInfo[aura.auraInstanceID] = aura
		end
	end
	AuraUtil_ForEachAura(unit, self.filter, batchCount, HandleAura, usePackedAura)

	if self.filter == "HARMFUL" then
		local guid = self.guid or UnitGUID(unit)
		if SpellLockedGUIDS[guid] then
			for auraInstanceID, callbackTimer in pairs(SpellLockedGUIDS[guid]) do
				local aura = E:DeepCopy(callbackTimer.args[3])
				aura.scale = self.db.typeScale.softCC + 1
				aura.priority = self.priority.softCC
				self.auraInfo[auraInstanceID] = aura
			end
		end
		if self.isMerged then
			AuraUtil_ForEachAura(unit, "HELPFUL", batchCount, HandleAura, usePackedAura)
		end
	end
end

function CompactArenaFrameMixin:OnEvent(event, ...)
	if event == "UNIT_AURA" then
		local unitId, unitAuraUpdateInfo, auraChanged = ...

		if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or self.auraInfo == nil then
			self:ParseAllAuras(unitId)
			auraChanged = true
		else
			if unitAuraUpdateInfo.addedAuras ~= nil then
				for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
					local type = self:ProcessAura(aura)
					if type then
						self.auraInfo[aura.auraInstanceID] = aura
						auraChanged = true
					end
				end
			end

			if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
				for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
					if self.auraInfo[auraInstanceID] ~= nil then
						local newAura = C_UnitAuras_GetAuraDataByAuraInstanceID(unitId, auraInstanceID)
						if newAura ~= nil then
							newAura.priority = self.auraInfo[auraInstanceID].priority
							newAura.scale = self.auraInfo[auraInstanceID].scale
						end
						self.auraInfo[auraInstanceID] = newAura
						auraChanged = true
					end
				end
			end

			if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
				for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
					if self.auraInfo[auraInstanceID] ~= nil then
						self.auraInfo[auraInstanceID] = nil
						auraChanged = true
					end
				end
			end
		end

		if auraChanged then
			local frameNum = self.auraInfo:Size()
			local oldNum = self.frameNum
			if frameNum == 0 and oldNum and oldNum > 0 then
				for i = 1, oldNum do
					local ol = self[i]
					ClearHideOverlayFrame(ol)
				end
				self.frameNum = frameNum
				return
			end

			local now = GetTime()
			local isDebuff = self.filter == "HARMFUL"
			local db = self.db
			local maxIcons = db.maxIcons
			local base = BuffFrameBase[self.systemIndex]
			local baseSize = base.baseSize

			local maxScale, numInnerDebuffs, remainingSpace
			if isDebuff then
				maxScale = base.maxScale
				numInnerDebuffs = base.numInnerDebuffs
				remainingSpace = base.totInnerDebuffs
			end
			frameNum = 1

			self.auraInfo:Iterate(function(auraInstanceID, aura)
				local overlay = self[frameNum]
				local count, expirationTime, spellId, icon, duration = aura.applications, aura.expirationTime, aura.spellId, aura.icon, aura.duration
				if spellId ~= overlay.spellId or expirationTime ~= overlay.expirationTime or count ~= overlay.stack then
					overlay.icon:SetTexture(icon)
					if count > 1 then
						if count >= 100 then
							count = BUFF_STACKS_OVERFLOW
						end
						overlay.count:SetText(count)
						overlay.count:Show()
					else
						overlay.count:Hide()
					end
					if expirationTime and expirationTime ~= 0 then
						local startTime = expirationTime - duration
						overlay.cooldown:SetCooldown(startTime, duration)
						if db.glow and (Aura_Enabled.glow[spellId] or aura.forceGlow) and spellId ~= overlay.spellId and now - startTime < 0.1 then
							overlay.HighlightFlash:Show()
							overlay.HighlightFlash.Anim:Play()
						elseif overlay.HighlightFlash.Anim:IsPlaying() then
							overlay.HighlightFlash.Anim:Stop()
							overlay.HighlightFlash:Hide()
						end
					else
						overlay.cooldown:Clear()
						if overlay.HighlightFlash.Anim:IsPlaying() then
							overlay.HighlightFlash.Anim:Stop()
							overlay.HighlightFlash:Hide()
						end
					end

					if isDebuff then
						local scale = aura.scale or 1
						if scale > 1 and numInnerDebuffs then
							scale = min(scale, maxScale)
						end
						if scale ~= overlay.debuffScale then
							local debuffSize
							if scale > 1 then
								debuffSize = scale * baseSize
							else
								debuffSize = baseSize
							end
							overlay:SetSize(debuffSize, debuffSize)
							overlay.cooldown.counter:SetScale(base.currCounterScale * db.counterScale * scale)
							overlay.cooldown:SetHideCountdownNumbers(db.hideCounter or (scale == 1 and db.hideNonCCCounter))
							overlay.HighlightFlash:SetScale(debuffSize / BASE_ICON_HEIGHT)
							overlay.debuffScale = scale
						end
						if db.borderType == "blizzard" then
							local color = DebuffTypeColor[aura.dispelName] or DebuffTypeColor["none"]
							overlay.border:SetVertexColor(color.r, color.g, color.b)
						elseif db.borderType == "pixelDebuff" then
							local color = AdjustedDebuffTypeColorArena[aura.dispelName] or AdjustedDebuffTypeColorArena["none"]
							local r, g, b = color.r, color.g, color.b
							overlay.borderTop:SetVertexColor(r, g, b)
							overlay.borderBottom:SetVertexColor(r, g, b)
							overlay.borderLeft:SetVertexColor(r, g, b)
							overlay.borderRight:SetVertexColor(r, g, b)
						end
					end
					overlay.filter = nil
					overlay.auraInstanceID = auraInstanceID
					overlay.spellId = spellId
					overlay.expirationTime = expirationTime
					overlay.stack = count
					overlay.iconTexture = icon
					overlay:Show()
				end

				if numInnerDebuffs then
					remainingSpace = remainingSpace - overlay.debuffScale
					-- If the last debuff is a "big" debuff, then let it cross border (remainingSpace < 0), else cut off.
					if remainingSpace < 1 then
						frameNum = frameNum + 1
						return true
					end
				end
				frameNum = frameNum + 1

				return frameNum > maxIcons
			end)

			if maxIcons > 1 and db.point == "CENTER" then
				local newOffsetX = -baseSize / 2 * (frameNum - 2)
				if (unitAuraUpdateInfo == nil or newOffsetX ~= self.cOffsetX) then
					local leadOverlay = self[1]
					leadOverlay:ClearAllPoints()
					leadOverlay:SetPoint(db.point, self, db.point, newOffsetX, 0)
					self.cOffsetX = newOffsetX
				end
			end

			frameNum = frameNum - 1
			if oldNum and oldNum > frameNum then
				for i = frameNum + 1, oldNum do
					local ol = self[i]
					ClearHideOverlayFrame(ol)
				end
			end
			self.frameNum = frameNum
		end
	elseif event == "ARENA_OPPONENT_UPDATE" then
		local unit, updateReason = ...
		if unit == self.unit then -- 'arenaN' is invalid for RegisterUnitEvent
			-- toggle visibility to prevent last icon texture being shown on a new "seen" event
			if updateReason == "seen" then
				local guid = UnitGUID(unit)
				if guid then
					self.guid = guid
					self:OnEvent("UNIT_AURA", unit, nil)
				end
				self:Show()
			elseif updateReason == "unseen" then
				self:Hide()
			end
		end
	end
end

local reversePoint = {
	["BOTTOMLEFT"] = "BOTTOMRIGHT",
	["BOTTOMRIGHT"] = "BOTTOMLEFT",
	["LEFT"] = "RIGHT",
	["RIGHT"] = "LEFT",
}

function CompactArenaFrameMixin:UpdateSettings(filter, uf, unitTypeDB, isMerged)
	local db = unitTypeDB[filter]
	local isHARMFUL = filter == "HARMFUL"
	local isManual = db.preset == "MANUAL"

	self.isMerged = isMerged
	self.shouldGlow = db.preset ~= "PORTRAIT" and db.glow
	self.priority = unitTypeDB.priority
	self.sorter = AuraComparator[db.sortby]
	self.db = db
	self.frameNum = nil

	-- Blizzard visibility
	uf.DebuffFrame:SetAlpha(unitTypeDB.ccFrame.hideCc and 0 or 1) -- shows stealth icon
	--uf.CcRemoverFrame:SetAlpha(unitTypeDB.ccFrame.hideCcRemover and 0 or 1)
	if isHARMFUL then
		if uf.debuffFrames then
			local shouldHide = unitTypeDB.visibility[self.zone] and unitTypeDB.enabled and db.enabled and db.redirectBlizzardDebuffs
			local n = #uf.debuffFrames
			for i = 1, n do
				local debuffFrame = uf.debuffFrames[i]
				debuffFrame:SetAlpha(shouldHide and 0 or 1)
				debuffFrame:EnableMouse(not shouldHide)
			end
		end
	end

	-- Container settings
	self:SetFrameLevel(uf:GetFrameLevel() + db.frameLevel)
	self:ClearAllPoints()
	local scale
	if isManual then
		E.LoadPosition(self)
		scale = db.scale
	else
		local relTo = db.relativeFrame == "castBarIcon" and uf.CastingBarFrame.Icon or uf[db.relativeFrame] or uf
		local xOfs, yOfs
		if db.preset == "overDebuffs" then
			xOfs, yOfs, scale = 0, 0, 1
		else
			xOfs, yOfs, scale = db.offsetX, db.offsetY, db.scale
		end
		self:SetPoint(db.point, relTo, db.relativePoint, xOfs, yOfs)
	end

	-- Overlay settings
	local base = BuffFrameBase[self.systemIndex]
	local baseSize = base.baseSize
	local point = db.point == "CENTER" and "LEFT" or db.point
	local relPoint = db.point == "CENTER" and "RIGHT" or reversePoint[db.point]

	local pixelMult = E.uiUnitFactor / self.parent:GetEffectiveScale()
	local size = BASE_ICON_HEIGHT * scale
	local iconScale
	local edgeSize
	-- Protect against atypical scaling of CAF by other mods
	if pixelMult > size then
		pixelMult = E.uiUnitFactor
		iconScale = size / BASE_ICON_HEIGHT
	else
		iconScale = (size - size % pixelMult) / BASE_ICON_HEIGHT
	end
	edgeSize = pixelMult / iconScale
	local r, g, b = db.borderColor.r, db.borderColor.g, db.borderColor.b

	local n = NUM_AF_OVERLAYS[filter]
	for j = 1, n do
		local overlay = self[j]
		ClearHideOverlayFrame(overlay)

		overlay:SetScale(iconScale)
		overlay:ClearAllPoints()
		if isManual then
			overlay:SetPoint("CENTER")
			if module.isInTestMode then
				if not overlay.name then
					overlay.name = overlay:CreateFontString(nil, "OVERLAY", "UFCounter-OmniAuras")
					overlay.name:SetPoint("TOP", overlay, "BOTTOM", 0, -5)
				end
				overlay.name:SetFormattedText("%s|%s%s", self.unit, isHARMFUL and "debuffs" or "buffs", unitTypeDB.mergeAuraFrame and " + buffs" or "")
			end
			if j > 1 then
				overlay:SetPoint("BOTTOMLEFT", self[j-1], "BOTTOMRIGHT")
			end
		elseif j == 1 then
			overlay:SetPoint(db.point, self, db.point)
		else
			overlay:SetPoint(point, self[j-1], relPoint)
		end

		if overlay.name then
			overlay.name:SetShown(isManual and module.isInTestMode)
		end
		overlay:SetSize(baseSize, baseSize)
		overlay.HighlightFlash:SetScale(baseSize / BASE_ICON_HEIGHT)
		overlay:SetAlpha(db.opacity)
		overlay:EnableMouse(module.isInTestMode and isManual or (overlay.isPassThrough and db.showTooltip))
		overlay.cooldown:SetSwipeColor(0, 0, 0, db.swipeAlpha)
		overlay.cooldown.counter:SetScale(base.currCounterScale * db.counterScale)
		overlay.cooldown:SetHideCountdownNumbers(db.hideCounter)

		if db.borderType == "blizzard" then
			overlay.border:Show()
			overlay.borderTop:Hide()
			overlay.borderBottom:Hide()
			overlay.borderLeft:Hide()
			overlay.borderRight:Hide()
			overlay.icon:SetTexCoord(0, 1, 0, 1)
		else
			if overlay.border then
				overlay.border:Hide()
			end

			overlay.borderTop:ClearAllPoints()
			overlay.borderTop:SetPoint("TOPLEFT", overlay, "TOPLEFT")
			overlay.borderTop:SetPoint("BOTTOMRIGHT", overlay, "TOPRIGHT", 0, -edgeSize)
			overlay.borderTop:SetVertexColor(r, g, b)
			overlay.borderTop:Show()

			overlay.borderBottom:ClearAllPoints()
			overlay.borderBottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT")
			overlay.borderBottom:SetPoint("TOPRIGHT", overlay, "BOTTOMRIGHT", 0, edgeSize)
			overlay.borderBottom:SetVertexColor(r, g, b)
			overlay.borderBottom:Show()

			overlay.borderRight:ClearAllPoints()
			overlay.borderRight:SetPoint("TOPRIGHT", overlay.borderTop, "BOTTOMRIGHT")
			overlay.borderRight:SetPoint("BOTTOMLEFT", overlay.borderBottom, "TOPRIGHT", -edgeSize, 0)
			overlay.borderRight:SetVertexColor(r, g, b)
			overlay.borderRight:Show()

			overlay.borderLeft:ClearAllPoints()
			overlay.borderLeft:SetPoint("TOPLEFT", overlay.borderTop, "BOTTOMLEFT")
			overlay.borderLeft:SetPoint("BOTTOMRIGHT", overlay.borderBottom, "TOPLEFT", edgeSize, 0)
			overlay.borderLeft:SetVertexColor(r, g, b)
			overlay.borderLeft:Show()

			overlay.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		end
	end
end

-- NOTE: UF uses fake unitIds for player, and party1-4
local function UnitFrame_RegisterUnitAura(self, unit, filter)
	local unitId = unit == "player" and "uplayer" or unit
	ActiveContainer[filter][unitId] = self
	self:RegisterUnitEvent("UNIT_AURA", unit)
	self:OnEvent("UNIT_AURA", unit, nil)
	self:Show()
end

local function UnitFrame_UnregisterUnitAura(self, unit, filter)
	unit = unit == "player" and "uplayer" or unit
	if ActiveContainer[filter][unit] then
		ActiveContainer[filter][unit] = nil
		self:UnregisterEvent("UNIT_AURA")
		self:Hide()
	end
end

local UF_FRAMENAME = {
	["player"]="PlayerFrame",
	["target"]="TargetFrame",
	["focus"]="FocusFrame",
	["pet"]="PetFrame",
	["arena1"]="CompactArenaFrameMember1", -- 10.1.5
	["arena2"]="CompactArenaFrameMember2",
	["arena3"]="CompactArenaFrameMember3",
	["arena4"]="CompactArenaFrameMember4",
	["arena5"]="CompactArenaFrameMember5",
--	["arena1"]="ArenaEnemyMatchFrame1", -- now loads in BG only
--	["arena2"]="ArenaEnemyMatchFrame2",
--	["arena3"]="ArenaEnemyMatchFrame3",
--	["arena4"]="ArenaEnemyMatchFrame4",
--	["arena5"]="ArenaEnemyMatchFrame5",
--	["targettarget"]="TargetFrameToT",
--	["focustarget"]="FocusFrameToT",
}

for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
	UF_FRAMENAME[memberFrame.unit] = memberFrame -- memberFrame can now be directly accessed via _G.PartyFrame.MemberFrame1-4 (no frame name)
end

local UF_UNITTYPE = {
	["player"]="player",["target"]="target",["focus"]="focus",["pet"]="pet",
	["party1"]="party",["party2"]="party",["party3"]="party",["party4"]="party",
	["arena1"]="arena",["arena2"]="arena",["arena3"]="arena",["arena4"]="arena",["arena5"]="arena",
--	["targettarget"]="targettarget",["focustarget"]="focustarget",
}

local AURA_FILTER = { "HARMFUL", "HELPFUL" }

function module.CreateUnitFrameOverlays_OnLoad()
	for unit, frameName in pairs(UF_FRAMENAME) do
		local unitType = UF_UNITTYPE[unit]
		local isArenaUnit = unitType == "arena"
		local uf = unitType == "party" and frameName or _G[frameName]
		if uf and not UnitFrameContainer[unit] then
			UnitFrameContainer[unit] = {}

			-- All db settings are done in Refresh for UF
			-- UnitFrame_Initialize will save each portrait frame reference to frame.portrait (old arena saved in .classPortrait .specPortrait)
			local portrait = (unitType == "party" and frameName.portrait) or _G[frameName].portrait
			for _, filter in pairs(AURA_FILTER) do
				local isHARMFUL = filter == "HARMFUL"
				local container = CreateFrame("Frame", nil, UIParent)
				-- Parenting to other UF taints in 10.1.7
				if isArenaUnit then
					container.parent = uf
					container:SetParent(uf)
					container.systemIndex = CompactRaidGroupTypeEnumArena
				end
				container:SetSize(1, 1)
				container.frameType = isArenaUnit and "arenaFrame" or "unitFrame"
				container.filter = filter
				container.auraType = isHARMFUL and "isHarmful"or "isHelpful"
				Mixin(container, isArenaUnit and CompactArenaFrameMixin or UnitFrameMixin)
				container:SetScript("OnEvent", container.OnEvent)

				container.unit = unit
				container.guid = unit == "player" and userGUID
				container.enabledAura = unit == "player" and Aura_Enabled.playerFrame or (isArenaUnit and Aura_Enabled.arenaFrame) or Aura_Enabled.unitFrame
				container.isArenaDebuff = isHARMFUL and isArenaUnit
				container.key = format("%s%s%s", E.AddOn, unitType == "party" and "PartyMemberFrame" .. frameName.layoutIndex or frameName, filter)
				container:SetMovable(true)
				container.portrait = portrait

				local n = isArenaUnit and NUM_AF_OVERLAYS[filter] or NUM_UF_OVERLAYS
				for j = 1, n do
					local overlay
					if isArenaUnit then
						overlay = CreateOverlay(container, isHARMFUL and "OmniAurasCompactDebuffTemplate" or "OmniAurasCompactAuraTemplate")
						overlay.cooldown.counter:SetFontObject(E.RFCounter)
					else
						overlay = CreateOverlay(container)
						overlay.cooldown.counter:SetFontObject(E.UFCounter)
						overlay.count:SetFontObject("NumberFontNormalLarge")
						overlay.count:ClearAllPoints()
						overlay.count:SetPoint("TOPRIGHT", 3, 2)
						overlay.portrait = portrait
						overlay.portraitParent = portrait:GetParent()
					end
					overlay:SetScript("OnMouseDown", E.OmniAurasAnchor_OnMouseDown)
					overlay:SetScript("OnMouseUp", E.OmniAurasAnchor_OnMouseUp)
					container[j] = overlay
				end
				UnitFrameContainer[unit][filter] = container
			end
		end
	end
end

--
-- Compact Unit Frame
--

local CompactUnitFrameMixin = {}

-- PrivateAura woes (PTR)
--	If a member with a privateaura leaves the group then the aura will incorrectly show up on the next
--	unitId member which now has the matching unitId and then stick to the raidframe when it times out.

OmniAurasCompactUnitPrivateAuraAnchorMixin = {}

function OmniAurasCompactUnitPrivateAuraAnchorMixin:SetUnit(unit)
	if unit == self.unit then
		return
	end
	self.unit = unit

	if self.anchorID then
		C_UnitAuras.RemovePrivateAuraAnchor(self.anchorID)
		self.anchorID = nil
	end

	if unit then
		local iconAnchor =
		{
			point = "CENTER",
			relativeTo = self,
			relativePoint = "CENTER",
			offsetX = 0,
			offsetY = 0,
		}

		local privateAnchorArgs = {}
		privateAnchorArgs.unitToken = unit
		privateAnchorArgs.auraIndex = self.auraIndex
		privateAnchorArgs.parent = self
		privateAnchorArgs.showCountdownFrame = true
		privateAnchorArgs.showCountdownNumbers = false
		privateAnchorArgs.iconInfo =
		{
			iconAnchor = iconAnchor,
			iconWidth = self:GetWidth(),
			iconHeight = self:GetHeight(),
		}
		privateAnchorArgs.durationAnchor = nil

		self.anchorID = C_UnitAuras.AddPrivateAuraAnchor(privateAnchorArgs)
	end
end

function CompactUnitFrameMixin:UpdatePrivateAuras()
	if not self.PrivateAuraAnchors then
		return
	end

	if self.PrivateAuraAnchors then
		for _, auraAnchor in ipairs(self.PrivateAuraAnchors) do
			auraAnchor:SetUnit(self.unit)
		end
	end

	local base = BuffFrameBase[self.systemIndex]
	local lastShownDebuff = base.numInnerDebuffs and self[self.innerFrameNum] or self[self.frameNum]

	self.PrivateAuraAnchor1:ClearAllPoints()
	if lastShownDebuff then
		if self.db.preset == "raidFrameLeft" then
			self.PrivateAuraAnchor1:SetPoint("BOTTOMRIGHT", lastShownDebuff, "BOTTOMLEFT", 0, 0)
		else
			self.PrivateAuraAnchor1:SetPoint("BOTTOMLEFT", lastShownDebuff, "BOTTOMRIGHT", 0, 0)
		end
	else
		if self.db.preset == "raidFrameLeft" then
			self.PrivateAuraAnchor1:SetPoint("BOTTOMRIGHT", self[1], "BOTTOMRIGHT", 0, 0)
		else
			self.PrivateAuraAnchor1:SetPoint("BOTTOMLEFT", self[1], "BOTTOMLEFT", 0, 0)
		end
	end
end

function CompactUnitFrameMixin:ProcessAura(aura)
	if not aura or not aura.name then
		return false
	end
	local spellId = aura.spellId
	if not Aura_Blacklist[spellId] then
		if self.isMyBuffs then -- include enabledAura since it can be masked by higher priorities
			if not aura.isBossAura and aura.isHelpful then
				local priority = AuraUtil_ShouldDisplayBuff(aura.sourceUnit, spellId, aura.canApplyAura) and UnitFrameDebuffType_NonBossDebuff
				if priority then
					aura.priority = priority
					return true
				end
			end
			return
		end

		local enabledAuraData = self.enabledAura[spellId]
		if enabledAuraData then
			if aura[self.auraType] and (not Aura_NoFriend[spellId] or (self.auraType == "isHarmful" and aura.sourceUnit and UnitCanAttack("player", aura.sourceUnit))) then
				local type = enabledAuraData[1]
				local scale = self.db.typeScale and self.db.typeScale[type] or 1
				if self.db.largerIcon and Aura_Enabled.largerIcon[spellId] then
					scale = scale * self.db.largerIcon
				end
				aura.scale = scale
				aura.priority = aura.isHarmful and aura.dispelName == "none" and self.priority[type] + 1 or self.priority[type]
				return true
			end
		elseif self.db.redirectBlizzardDebuffs then
			local priority
			if aura.isBossAura then
				priority = aura.isHarmful and UnitFrameDebuffType_BossDebuff or UnitFrameDebuffType_BossBuff
			elseif aura.isHarmful then
				if aura.isRaid then
					priority = UnitFrameDebuffType_NonBossRaidDebuff
				elseif AuraUtil_IsPriorityDebuff(spellId) then
					priority = UnitFrameDebuffType_PriorityDebuff
				elseif AuraUtil_ShouldDisplayDebuff(aura.sourceUnit, spellId) then
					priority = UnitFrameDebuffType_NonBossDebuff
				end
			end
			if priority then
				local base = BuffFrameBase[self.systemIndex]
				if aura.isBossAura then
					aura.scale = base.bossScale
				elseif base.dispellableScale and not aura.isFromPlayerOrPlayerPet and DispellableDebuffType[aura.dispelName] then
					aura.scale = base.dispellableScale
				else
					aura.scale = 1
				end
				aura.priority = priority
				return true
			end
		end
	end
end

function CompactUnitFrameMixin:ParseAllAuras(unit)
	if module.isInTestMode then
		module.InjectTestAuras(self)
		return
	end

	if self.auraInfo == nil then
		self.auraInfo = TableUtil.CreatePriorityTable(self.sorter, true)
	else
		self.auraInfo:Clear()
	end

	local batchCount = nil
	local usePackedAura = true
	local function HandleAura(aura)
		local type = self:ProcessAura(aura)
		if type then
			self.auraInfo[aura.auraInstanceID] = aura
		end
	end
	AuraUtil_ForEachAura(unit, self.filter, batchCount, HandleAura, usePackedAura)

	if self.filter == "HARMFUL" then
		local guid = self.guid or UnitGUID(unit)
		if SpellLockedGUIDS[guid] then
			for auraInstanceID, callbackTimer in pairs(SpellLockedGUIDS[guid]) do
				local aura = E:DeepCopy(callbackTimer.args[3])
				aura.scale = self.db.typeScale.softCC
				aura.priority = self.priority.softCC + 1
				self.auraInfo[auraInstanceID] = aura
			end
		end
	end
end

function CompactUnitFrameMixin:OnEvent(event, ...)
	if event == "UNIT_AURA" then
		local unitId, unitAuraUpdateInfo, auraChanged = ...

		if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or self.auraInfo == nil then
			self:ParseAllAuras(unitId)
			auraChanged = true
		else
			if unitAuraUpdateInfo.addedAuras ~= nil then
				for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
					local type = self:ProcessAura(aura)
					if type then
						self.auraInfo[aura.auraInstanceID] = aura
						auraChanged = true
					end
				end
			end

			if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
				for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
					if self.auraInfo[auraInstanceID] ~= nil then
						local newAura = C_UnitAuras_GetAuraDataByAuraInstanceID(unitId, auraInstanceID)
						if newAura ~= nil then
							newAura.priority = self.auraInfo[auraInstanceID].priority
							newAura.scale = self.auraInfo[auraInstanceID].scale
						end
						self.auraInfo[auraInstanceID] = newAura
						auraChanged = true
					end
				end
			end

			if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
				for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
					if self.auraInfo[auraInstanceID] ~= nil then
						self.auraInfo[auraInstanceID] = nil
						auraChanged = true
					end
				end
			end
		end

		if auraChanged then
			local isDebuff = self.filter == "HARMFUL"
			local frameNum = self.auraInfo:Size()
			local oldNum = self.frameNum
			if frameNum == 0 then
				if oldNum and oldNum > 0 then
					for i = 1, oldNum do
						local ol = self[i]
						ClearHideOverlayFrame(ol)
					end
				end
				if self.detachedFrameNum and self.detachedFrameNum > 0 then
					for i = self.detachedFrameNum, 1, -1 do
						local ol = self[UNDETACHEDFRAME_LASTINDEX + i]
						ClearHideOverlayFrame(ol)
					end
				end
				self.frameNum = frameNum
				self.innerFrameNum = frameNum
				self.detachedFrameNum = frameNum
				-- Update anchors since we have no way of knowing when it gets added
				if isDebuff and module.isInPvEInstance then
					self:UpdatePrivateAuras()
				end
				return
			end

			local now = GetTime()
			local db = self.db
			local base = BuffFrameBase[self.systemIndex]
			local maxIcons = base.maxOverlays[self.rawFilter] or db.maxIcons
			local baseSize = base.baseSize

			local maxScale, numInnerDebuffs, remainingSpace, detachScale, detachedFrameNum
			if isDebuff then
				maxScale = base.maxScale
				numInnerDebuffs = base.numInnerDebuffs
				remainingSpace = base.totInnerDebuffs
				detachScale = base.shouldDetachBigDebuffs and db.detachScale
				detachedFrameNum = 1
			end
			frameNum = 1

			self.auraInfo:Iterate(function(auraInstanceID, aura)
				local overlay
				local isDetachedFrame
				local debuffScale

				if isDebuff then
					debuffScale = aura.scale or 1
					if detachScale and debuffScale >= detachScale and detachedFrameNum <= db.detachMaxIcons then
						overlay = self[UNDETACHEDFRAME_LASTINDEX + detachedFrameNum]
						isDetachedFrame = true
					else
						overlay = self[frameNum]
						-- If the last debuff is a big debuff, then down scale it so that it fits inside
						-- the available space without clipping over the buffs. If the remaining space is
						-- smaller than the base size then cut off or compensate like we used to.
						if numInnerDebuffs then
							-- inner doesn't use db.scale and is fixed @1
							if frameNum > numInnerDebuffs then
								debuffScale = 1
							else
								debuffScale = min(debuffScale, maxScale)
								if debuffScale > remainingSpace then
									debuffScale = remainingSpace
								end
							end
						end
					end
				else
					overlay = self[frameNum]
				end

				local count, expirationTime, spellId, icon, duration = aura.applications, aura.expirationTime, aura.spellId, aura.icon, aura.duration
				if spellId ~= overlay.spellId or expirationTime ~= overlay.expirationTime or count ~= overlay.stack then
					overlay.icon:SetTexture(icon)
					if count > 1 then
						if count >= 100 then
							count = BUFF_STACKS_OVERFLOW
						end
						overlay.count:SetText(count)
						overlay.count:Show()
					else
						overlay.count:Hide()
					end
					if expirationTime and expirationTime ~= 0 then
						local startTime = expirationTime - duration
						overlay.cooldown:SetCooldown(startTime, duration)
						--if db.glow and Aura_Enabled.glow[spellId] and icon ~= overlay.iconTexture and now - startTime < 0.1 then
						--fix aura's with trigger+effect that uses the same texture (e.g. Binding Shot)
						if db.glow and Aura_Enabled.glow[spellId] and spellId ~= overlay.spellId and now - startTime < 0.1 then
							overlay.HighlightFlash:Show()
							overlay.HighlightFlash.Anim:Play()
						elseif overlay.HighlightFlash.Anim:IsPlaying() then
							overlay.HighlightFlash.Anim:Stop()
							overlay.HighlightFlash:Hide()
						end
					else
						overlay.cooldown:Clear()
						if overlay.HighlightFlash.Anim:IsPlaying() then
							overlay.HighlightFlash.Anim:Stop()
							overlay.HighlightFlash:Hide()
						end
					end

					if isDebuff then
						if debuffScale ~= overlay.debuffScale then
							local debuffSize
							if debuffScale > 1 then
								debuffSize = debuffScale * baseSize
							else
								debuffSize = baseSize
							end
							-- Set size instead of scale for pixel borders
							overlay:SetSize(debuffSize, debuffSize)
							overlay.cooldown.counter:SetScale(base.currCounterScale * db.counterScale * debuffScale)
							overlay.cooldown:SetHideCountdownNumbers(db.hideCounter or (debuffScale == 1 and db.hideNonCCCounter))
							overlay.HighlightFlash:SetScale(debuffSize / BASE_ICON_HEIGHT)
							overlay.debuffScale = debuffScale
						end
						if db.borderType == "blizzard" then
							local color = DebuffTypeColor[aura.dispelName] or DebuffTypeColor["none"]
							overlay.border:SetVertexColor(color.r, color.g, color.b)
						elseif db.borderType == "pixelDebuff" then
							local color = AdjustedDebuffTypeColor[aura.dispelName] or AdjustedDebuffTypeColor["none"]
							local r, g, b = color.r, color.g, color.b
							overlay.borderTop:SetVertexColor(r, g, b)
							overlay.borderBottom:SetVertexColor(r, g, b)
							overlay.borderLeft:SetVertexColor(r, g, b)
							overlay.borderRight:SetVertexColor(r, g, b)
						end
					else
						overlay.isBossBuff = aura.isBossAura -- TT
					end
					overlay.filter = aura.isRaid and AuraUtil.AuraFilters.Raid or nil -- TT
					overlay.auraInstanceID = auraInstanceID -- TT
					overlay.spellId = spellId
					overlay.expirationTime = expirationTime
					overlay.stack = count
					overlay.iconTexture = icon
					overlay:Show()
				end

				if isDetachedFrame then
					detachedFrameNum = detachedFrameNum + 1
				else
					if numInnerDebuffs and frameNum <= numInnerDebuffs then
						remainingSpace = remainingSpace - debuffScale
						if remainingSpace < 1 then
							for i = frameNum + 1, numInnerDebuffs do
								local ol = self[i]
								if ol then
									ClearHideOverlayFrame(ol)
								end
							end
							-- If outer is being used or forced, then increase the soft cap to compensate for
							-- skipped inner frames, else just cut off.
							if maxIcons > numInnerDebuffs or base.alwaysShowMaxNumIcons then
								local skipped = numInnerDebuffs - frameNum
								if skipped > 0 then
									maxIcons = min(maxIcons + skipped, base.totDebuffs)
								end
							end
							frameNum = numInnerDebuffs
						end
						self.innerFrameNum = frameNum
					end
					frameNum = frameNum + 1
				end

				return frameNum > maxIcons
			end)

			if maxIcons > 1 and db.point == "CENTER" then
				local newOffsetX = -baseSize / 2 * (frameNum - 2)
				if (unitAuraUpdateInfo == nil or newOffsetX ~= self.cOffsetX) then -- force update on reg unitaura
					local leadOverlay = self[1]
					leadOverlay:ClearAllPoints()
					leadOverlay:SetPoint(db.point, self, db.point, newOffsetX, 0)
					self.cOffsetX = newOffsetX
				end
			end

			frameNum = frameNum - 1
			if oldNum and oldNum > frameNum then
				for i = frameNum + 1, oldNum do
					local ol = self[i]
					ClearHideOverlayFrame(ol)
				end
			end
			self.frameNum = frameNum

			if isDebuff then
				detachedFrameNum = detachedFrameNum - 1
				if self.detachedFrameNum and self.detachedFrameNum > detachedFrameNum then
					for i = detachedFrameNum + 1, self.detachedFrameNum do
						local ol = self[UNDETACHEDFRAME_LASTINDEX + i]
						ClearHideOverlayFrame(ol)
					end
				end
				self.detachedFrameNum = detachedFrameNum

				-- This attaches to the last visible debuff, potentially crossing over to the buff area,
				-- but it shouldn't be an issue as you rarely have more than 2 debuffs in a raid.
				if module.isInPvEInstance then
					self:UpdatePrivateAuras()
				end
			end
		end
	elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
		self:OnEvent("UNIT_AURA", self.unit, nil)
	end
end

local function CompactUnitFrame_RegisterUnitAura(self, unit, filter, guid, isRefresh)
	if ActiveContainer[filter][unit] ~= self -- compare frame-to-unitId
		or self.guid ~= guid -- compare frame-to-actualUnit
		or isRefresh then -- Refresh hides all overlays so force update
		self:UnregisterEvent("UNIT_AURA")
		self:RegisterUnitEvent("UNIT_AURA", unit)
		if filter ~= "HELPFUL" then
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
			self:RegisterEvent("PLAYER_REGEN_DISABLED")
		end
		ActiveContainer[filter][unit] = self
		self.unit = unit
		self.guid = guid
		self:OnEvent("UNIT_AURA", unit, nil) -- pass nil to force update
		self:Show()
	end

	if ( filter ~= "HELPFUL" ) then
		local shouldHide = filter == "MYHELPFUL" or self.db.redirectBlizzardDebuffs or nil
		if ( shouldHide ~= self.isBlizzardAuraHidden ) then
			local auraFrames = self.parent[filter == "MYHELPFUL" and "buffFrames" or "debuffFrames"]
			if ( auraFrames ) then
				local n = #auraFrames
				for i = 1, n do
					local auraFrame = auraFrames[i]
					auraFrame:SetAlpha(shouldHide and 0 or 1)
					auraFrame:EnableMouse(not shouldHide)
				end
				self.isBlizzardAuraHidden = shouldHide
			end
		end
	end
end

local function CompactUnitFrame_UnregisterUnitAura(self, unit, filter)
	if ActiveContainer[filter][unit] then
		self:UnregisterEvent("UNIT_AURA")
		if filter ~= "HELPFUL" then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		self.unit = nil
		self.guid = nil
		ActiveContainer[filter][unit] = nil
		self:Hide()
	end

	if ( self.isBlizzardAuraHidden ) then
		local auraFrames = self.parent[filter == "MYHELPFUL" and "buffFrames" or "debuffFrames"]
		if ( auraFrames ) then
			local n = #auraFrames
			for i = 1, n do
				local auraFrame = auraFrames[i]
				auraFrame:SetAlpha(1)
				auraFrame:EnableMouse(true)
			end
			self.isBlizzardAuraHidden = nil
		end
	end
end

local Refresh_OnTimerEnd = function()
	E:Refresh()
	CallbackTimers.hookDelay = nil
end

function module:HookFunc()
	if self.enabled and not CallbackTimers.hookDelay then
		CallbackTimers.hookDelay = C_Timer.NewTimer(0.5, Refresh_OnTimerEnd)
	end
end

function module:UI_SCALE_CHANGED()
	E:SetPixelMult()
	self:HookFunc()
end

local pauseTimer

local function ResetPause()
	pauseTimer = nil
end

function module.OnRefreshMemebers()
	if pauseTimer or module.disabledCUF
		or EditModeManagerFrame:GetSettingValue(
			Enum.EditModeSystem.UnitFrame,
			Enum.EditModeUnitFrameSystemIndices.Party,
			Enum.EditModeUnitFrameSetting.SortPlayersBy
		) == 1 then
		return
	end
	module:GROUP_ROSTER_UPDATE()
	pauseTimer = C_Timer.NewTimer(6, ResetPause)
end

function module:SetHooks()
	if self.hooked or not C_AddOns.IsAddOnLoaded("Blizzard_CompactRaidFrames") or not C_AddOns.IsAddOnLoaded("Blizzard_CUFProfiles") then
		return
	end

	self.useRaidStylePartyFrames = EditModeManagerFrame:UseRaidStylePartyFrames()
	self.keepGroupsTogether = EditModeManagerFrame:ShouldRaidFrameShowSeparateGroups()
	self.isCompactFrameSetShown = CompactRaidFrameManager_GetSetting("IsShown")

	-- HUD Raid Frame
	self:SecureHook(EditModeManagerFrame, "UpdateRaidContainerFlow", function()
		if self.isInEditMode then
			self.keepGroupsTogether = EditModeManagerFrame:ShouldRaidFrameShowSeparateGroups()
			self:HookFunc()
		end
	end)

	-- HUD Party Frame (Raid Frame UpdateRaidContainerFlow equiv. called by every option)
	self:SecureHook(PartyFrame, "UpdatePaddingAndLayout", function()
		if self.isInEditMode then -- Do not remove. This is super spammy
			self.useRaidStylePartyFrames = EditModeManagerFrame:UseRaidStylePartyFrames()
			self:HookFunc()
		end
	end)

	self.hooked = true
end

local COMPACT_RAID = {
	"CompactRaidFrame1", "CompactRaidFrame2", "CompactRaidFrame3", "CompactRaidFrame4", "CompactRaidFrame5",
	"CompactRaidFrame6", "CompactRaidFrame7", "CompactRaidFrame8", "CompactRaidFrame9", "CompactRaidFrame10",
	"CompactRaidFrame11", "CompactRaidFrame12", "CompactRaidFrame13", "CompactRaidFrame14", "CompactRaidFrame15",
	"CompactRaidFrame16", "CompactRaidFrame17", "CompactRaidFrame18", "CompactRaidFrame19", "CompactRaidFrame20",
	"CompactRaidFrame21", "CompactRaidFrame22", "CompactRaidFrame23", "CompactRaidFrame24", "CompactRaidFrame25",
	"CompactRaidFrame26", "CompactRaidFrame27", "CompactRaidFrame28", "CompactRaidFrame29", "CompactRaidFrame30",
	"CompactRaidFrame31", "CompactRaidFrame32", "CompactRaidFrame33", "CompactRaidFrame34", "CompactRaidFrame35",
	"CompactRaidFrame36", "CompactRaidFrame37", "CompactRaidFrame38", "CompactRaidFrame39", "CompactRaidFrame40",
	-- Index starts from 41 if you join LFR in Edit Mode with 40 raid frames opened :(
	"CompactRaidFrame41", "CompactRaidFrame42", "CompactRaidFrame43", "CompactRaidFrame44", "CompactRaidFrame45",
	"CompactRaidFrame46", "CompactRaidFrame47", "CompactRaidFrame48", "CompactRaidFrame49", "CompactRaidFrame50",
	"CompactRaidFrame51", "CompactRaidFrame52", "CompactRaidFrame53", "CompactRaidFrame54", "CompactRaidFrame55",
	"CompactRaidFrame56", "CompactRaidFrame57", "CompactRaidFrame58", "CompactRaidFrame59", "CompactRaidFrame60",
	"CompactRaidFrame61", "CompactRaidFrame62", "CompactRaidFrame63", "CompactRaidFrame64", "CompactRaidFrame65",
	"CompactRaidFrame66", "CompactRaidFrame67", "CompactRaidFrame68", "CompactRaidFrame69", "CompactRaidFrame70",
	"CompactRaidFrame71", "CompactRaidFrame72", "CompactRaidFrame73", "CompactRaidFrame74", "CompactRaidFrame75",
	"CompactRaidFrame76", "CompactRaidFrame77", "CompactRaidFrame78", "CompactRaidFrame79", "CompactRaidFrame80",
	"CompactRaidFrame81", "CompactRaidFrame82", "CompactRaidFrame83", "CompactRaidFrame84", "CompactRaidFrame85",
	"CompactRaidFrame86", "CompactRaidFrame87", "CompactRaidFrame88", "CompactRaidFrame89", "CompactRaidFrame90",
}

local COMPACT_RAID_KGT = { -- pet frames use COMPACT_RAID
	"CompactRaidGroup1Member1", "CompactRaidGroup1Member2", "CompactRaidGroup1Member3", "CompactRaidGroup1Member4", "CompactRaidGroup1Member5",
	"CompactRaidGroup2Member1", "CompactRaidGroup2Member2", "CompactRaidGroup2Member3", "CompactRaidGroup2Member4", "CompactRaidGroup2Member5",
	"CompactRaidGroup3Member1", "CompactRaidGroup3Member2", "CompactRaidGroup3Member3", "CompactRaidGroup3Member4", "CompactRaidGroup3Member5",
	"CompactRaidGroup4Member1", "CompactRaidGroup4Member2", "CompactRaidGroup4Member3", "CompactRaidGroup4Member4", "CompactRaidGroup4Member5",
	"CompactRaidGroup5Member1", "CompactRaidGroup5Member2", "CompactRaidGroup5Member3", "CompactRaidGroup5Member4", "CompactRaidGroup5Member5",
	"CompactRaidGroup6Member1", "CompactRaidGroup6Member2", "CompactRaidGroup6Member3", "CompactRaidGroup6Member4", "CompactRaidGroup6Member5",
	"CompactRaidGroup7Member1", "CompactRaidGroup7Member2", "CompactRaidGroup7Member3", "CompactRaidGroup7Member4", "CompactRaidGroup7Member5",
	"CompactRaidGroup8Member1", "CompactRaidGroup8Member2", "CompactRaidGroup8Member3", "CompactRaidGroup8Member4", "CompactRaidGroup8Member5",
}

local COMPACT_PARTY = {
	"CompactPartyFrameMember1", "CompactPartyFrameMember2", "CompactPartyFrameMember3", "CompactPartyFrameMember4", "CompactPartyFrameMember5",
}

function module:FindRelativeFrame(guid)
	-- Prioritize where to anchor the test frames
	local compactFrame
	if IsInRaid() and not self.isInArena then
		compactFrame = self.isCompactFrameSetShown and (self.keepGroupsTogether and COMPACT_RAID_KGT or COMPACT_RAID)
	elseif GetNumGroupMembers() > 0 then
		compactFrame = self.useRaidStylePartyFrames and COMPACT_PARTY or false
	elseif EditModeManagerFrame:ArePartyFramesForcedShown() then
		compactFrame = EditModeManagerFrame:UseRaidStylePartyFrames() and COMPACT_PARTY or false
	elseif EditModeManagerFrame:AreRaidFramesForcedShown() then
		compactFrame = self.isCompactFrameSetShown and (self.keepGroupsTogether and COMPACT_RAID_KGT or COMPACT_RAID)
	end

	if compactFrame then
		local n = #compactFrame
		for i = 1, n do
			local name = compactFrame[i]
			local f = _G[name]
			local unit = f and f.unit
			if unit and UnitGUID(unit) == guid then
				return f:IsVisible() and f, compactFrame[1] == "CompactPartyFrameMember1" and CompactRaidGroupTypeEnumParty or CompactRaidGroupTypeEnumRaid
			end
		end
	end
end

local RAID_UNIT = {
	"raid1","raid2","raid3","raid4","raid5","raid6","raid7","raid8","raid9","raid10",
	"raid11","raid12","raid13","raid14","raid15","raid16","raid17","raid18","raid19","raid20",
	"raid21","raid22","raid23","raid24","raid25","raid26","raid27","raid28","raid29","raid30",
	"raid31","raid32","raid33","raid34","raid35","raid36","raid37","raid38","raid39","raid40",
}

local PARTY_UNIT = {
	"party1","party2","party3","party4","player",
}

local RF_AURA_FILTER = {
	"HARMFUL", "HELPFUL", "MYHELPFUL",
}

local function CreateCompactUnitFrameContainer(parentFrame, filter, systemIndex)
	local container = CreateFrame("Frame", nil, parentFrame)
	container.parent = parentFrame
	container.systemIndex = systemIndex
	container:SetSize(1, 1)
	container.frameType = "raidFrame"
	container.isMyBuffs = filter == "MYHELPFUL"
	container.rawFilter = filter
	container.filter = filter == "MYHELPFUL" and "HELPFUL" or filter
	container.auraType = filter == "HARMFUL" and "isHarmful"or "isHelpful"
	container.enabledAura = Aura_Enabled.raidFrame
	Mixin(container, CompactUnitFrameMixin)
	container:SetScript("OnEvent", container.OnEvent)
	return container
end

function module:GetEffectiveNumGroupMembers()
	local n = GetNumGroupMembers()
	return n == 0 and self.isInTestMode and 1 or n
end

function module:CompactFrameIsActive(isInRaid)
	return (isInRaid or IsInRaid()) and not self.isInArena or self.useRaidStylePartyFrames
end

local RAID_UNITID_HASH = {
	["raid1"]=true,["raid2"]=true,["raid3"]=true,["raid4"]=true,["raid5"]=true,["raid6"]=true,["raid7"]=true,["raid8"]=true,["raid9"]=true,["raid10"]=true,
	["raid11"]=true,["raid12"]=true,["raid13"]=true,["raid14"]=true,["raid15"]=true,["raid16"]=true,["raid17"]=true,["raid18"]=true,["raid19"]=true,["raid20"]=true,
	["raid21"]=true,["raid22"]=true,["raid23"]=true,["raid24"]=true,["raid25"]=true,["raid26"]=true,["raid27"]=true,["raid28"]=true,["raid29"]=true,["raid30"]=true,
	["raid31"]=true,["raid32"]=true,["raid33"]=true,["raid34"]=true,["raid35"]=true,["raid36"]=true,["raid37"]=true,["raid38"]=true,["raid39"]=true,["raid40"]=true,
}

local PARTY_UNITID_HASH = {
	["party1"]=true,["party2"]=true,["party3"]=true,["party4"]=true,["player"]=true,
}

local function CompactUnitFrame_UnregisterAllUnitAura(groupType)
	for filter, t in pairs(ActiveContainer) do
		for unit, container in pairs(t) do
			if groupType == nil then
				if PARTY_UNITID_HASH[unit] or RAID_UNITID_HASH[unit] then
					CompactUnitFrame_UnregisterUnitAura(container, unit, filter)
				end
			elseif groupType == CompactRaidGroupTypeEnumRaid then
				if PARTY_UNITID_HASH[unit] then
					CompactUnitFrame_UnregisterUnitAura(container, unit, filter)
				end
			else
				if RAID_UNITID_HASH[unit] then
					CompactUnitFrame_UnregisterUnitAura(container, unit, filter)
				end
			end
		end
	end
end

local partyFrameUnitIdentifier = {
	["party1"]="uparty1",["party2"]="uparty2",["party3"]="uparty3",["party4"]="uparty4",
}

local partyFrameUnitId = {
	["uparty1"]="party1",["uparty2"]="party2",["uparty3"]="party3",["uparty4"]="party4",
}

-- party unitframe
local function PartyUnitFrame_RegisterUnitAura(self, unit, filter, guid, isRefresh)
	local uId = partyFrameUnitIdentifier[unit]
	if ActiveContainer[filter][uId] ~= self then -- exist check
		ActiveContainer[filter][uId] = self
		self:RegisterUnitEvent("UNIT_AURA", unit)
		self:Show()
	end
	if guid ~= self.guid or isRefresh then -- The unitId-to-PF is fixed, and actualUnit-to-PF changes (giving lead will reassign unitId to party1)
		self.guid = guid
		self:OnEvent("UNIT_AURA", unit, nil)
	end
end

local function PartyUnitFrame_UnregisterUnitAura(self, unit, filter)
	local uId = partyFrameUnitIdentifier[unit] or unit
	if ActiveContainer[filter][uId] then
		self:UnregisterEvent("UNIT_AURA")
		self.guid = nil
		ActiveContainer[filter][uId] = nil
		self:Hide()
	end
end

local function PartyUnitFrame_UnregisterAllUnitAura()
	for filter, t in pairs(ActiveContainer) do
		for unit, container in pairs(t) do
			if partyFrameUnitId[unit] then
				PartyUnitFrame_UnregisterUnitAura(container, unit, filter)
			end
		end
	end
end

function module:GROUP_ROSTER_UPDATE(isRefresh)
	local isCompactFrameActive = self:CompactFrameIsActive()
	local areRaidFramesForcedShown = EditModeManagerFrame:AreRaidFramesForcedShown()
	--local arePartyFramesForcedShown = EditModeManagerFrame:ArePartyFramesForcedShown()
	local isInRaid = IsInRaid()
	local size = self:GetEffectiveNumGroupMembers()

	-- Remove units no longer in group before iterating curr group, else any frame that was
	-- reassigned will get removed if it belonged to a unit no longer in group
	for unit, frame in pairs(ActiveCompactUnitFrame) do
		if size == 0 or not UnitExists(unit) then
			for filter, container in pairs(CompactUnitFrameContainer[frame]) do
				CompactUnitFrame_UnregisterUnitAura(container, unit, filter, nil)
			end
			ActiveCompactUnitFrame[unit] = nil -- NOTE: can have party1 raid1, if same unit
		end
	end
	if size == 0 then
		return
	end

	-- Remove unitIds no longer in current CUF/PF - if group type changed
	if isInRaid ~= self.isInRaid then
		if isInRaid then
			if self.isCompactFrameActive then
				CompactUnitFrame_UnregisterAllUnitAura(CompactRaidGroupTypeEnumParty) -- remove party#
			else
				PartyUnitFrame_UnregisterAllUnitAura() -- remove uparty#
			end
		else
			CompactUnitFrame_UnregisterAllUnitAura(CompactRaidGroupTypeEnumRaid) -- remove raid#
		end
	end

	if not self.disabledCUF and (isCompactFrameActive or areRaidFramesForcedShown) then
		local raidDB = db.raidFrame
		for i = 1, size do
			local unit = isInRaid and RAID_UNIT[i] or PARTY_UNIT[i == size and 5 or i]
			local guid = UnitGUID(unit)
			local frame, systemIndex = self:FindRelativeFrame(guid)
			if frame then
				if not CompactUnitFrameContainer[frame] then
					CompactUnitFrameContainer[frame] = {}
					for _, filter in pairs(RF_AURA_FILTER) do
						local db = raidDB[filter]
						local container = CreateCompactUnitFrameContainer(frame, filter, systemIndex)
						container:UpdateSettings(filter, frame, raidDB)
						CompactUnitFrameContainer[frame][filter] = container
						if db.enabled and (guid ~= userGUID or db.showPlayer) then
							CompactUnitFrame_RegisterUnitAura(container, unit, filter, guid, true)
						end
					end
				else
					for filter, container in pairs(CompactUnitFrameContainer[frame]) do
						local db = raidDB[filter]
						-- Set individual filter visibility (Refresh toggles entire CUF on and off)
						if db.enabled and (guid ~= userGUID or db.showPlayer) then
							CompactUnitFrame_RegisterUnitAura(container, unit, filter, guid, isRefresh)
						else
							CompactUnitFrame_UnregisterUnitAura(container, unit, filter)
						end
					end
				end

				if ActiveCompactUnitFrame[unit] ~= frame then
					ActiveCompactUnitFrame[unit] = frame
				end
			end
		end
	elseif not self.disabledPartyUF and not isCompactFrameActive then
		local isMerged = db.unitFrame.party.mergeAuraFrame
		for i = 1, 4 do
			local unit = PARTY_UNIT[i]
			local guid = UnitGUID(unit)
			for filter, container in pairs(UnitFrameContainer[unit]) do
				if i <= size and container.db.enabled and (not isMerged or filter == "HARMFUL") then
					PartyUnitFrame_RegisterUnitAura(container, unit, filter, guid, isRefresh)
				else
					PartyUnitFrame_UnregisterUnitAura(container, unit, filter)
				end
			end
		end
	end

	self.isCompactFrameActive = isCompactFrameActive
	self.isInRaid = isInRaid
end

function CompactUnitFrameMixin:UpdateSettings(filter, frame, raidDB)
	local db = raidDB[filter]
	local isHARMFUL = filter == "HARMFUL"
	local isMYHELPFUL = filter == "MYHELPFUL"

	-- Blizzard visibility
	local shouldHide = raidDB.visibility[module.zone] and raidDB.enabled and db.enabled -- recheck all
	if isHARMFUL then
		shouldHide = shouldHide and db.redirectBlizzardDebuffs
		if frame.debuffFrames then
			local n = #frame.debuffFrames -- preloaded with 3 debuff frames
			for i = 1, n do
				local debuffFrame = frame.debuffFrames[i]
				debuffFrame:SetAlpha(shouldHide and 0 or 1)
				debuffFrame:EnableMouse(not shouldHide)
			end
			self.isBlizzardAuraHidden = shouldHide
		end
		if frame.PrivateAuraAnchors then
			for _, auraAnchor in ipairs(frame.PrivateAuraAnchors) do
				auraAnchor:SetAlpha(shouldHide and 0 or 1)
				-- Toggles tooltip by checking IsMouseMotionFocus in OnUpdate
				-- and isn't click-through, so just make it tiny.
				auraAnchor:SetScale(shouldHide and 0.01 or 1)
			end
		end
	elseif isMYHELPFUL then
		if frame.buffFrames then
			local n = #frame.buffFrames -- preloaded with 8 buff frames. <cf: NP returns 0
			for i = 1, n do
				local buffFrame = frame.buffFrames[i]
				buffFrame:SetAlpha(shouldHide and 0 or 1)
				buffFrame:EnableMouse(not shouldHide)
			end
			self.isBlizzardAuraHidden = shouldHide
		end
	end

	-- Container settings
	self:SetFrameLevel(frame:GetFrameLevel() + db.frameLevel)
	self:ClearAllPoints()
	local relTo, xOfs, yOfs, scale
	if db.relativeFrame == "debuffFrame" and frame.debuffFrames then
		relTo = frame.debuffFrames[1]
	elseif db.relativeFrame == "buffFrame" and frame.buffFrames then
		relTo = frame.buffFrames[1]
	else
		relTo = frame
	end
	if db.preset == "overDebuffs" or db.preset == "overBuffs" then
		xOfs, yOfs, scale = 0, 0, 1
	else
		xOfs, yOfs, scale = db.preset == "raidFrameLeft" and -db.offsetX or db.offsetX, db.offsetY, db.scale
	end
	self:SetPoint(db.point, relTo, db.relativePoint, xOfs, yOfs)
	self.priority = raidDB.priority
	self.sorter = AuraComparator[db.sortby]
	self.db = db
	-- All overlays will be hidden below, so reset frame num
	self.frameNum = nil
	self.detachedFrameNum = nil

	-- Overlay settings
	local base = BuffFrameBase[self.systemIndex]
	local baseSize = base.baseSize
	local point = db.point == "CENTER" and "LEFT" or db.point
	local relPoint = db.point == "CENTER" and "RIGHT" or reversePoint[db.point]
	local numInnerDebuffs, shouldDetachBigDebuffs, detachedFrameStart
	if isHARMFUL then
		numInnerDebuffs = base.numInnerDebuffs
		shouldDetachBigDebuffs = base.shouldDetachBigDebuffs
		detachedFrameStart = UNDETACHEDFRAME_LASTINDEX + 1
	end

	local pixelMult = E.uiUnitFactor / self.parent:GetEffectiveScale()
	local size = BASE_ICON_HEIGHT * scale
	local iconScale = (size - size % pixelMult) / BASE_ICON_HEIGHT
	local edgeSize = pixelMult / iconScale
	local r, g, b = db.borderColor.r, db.borderColor.g, db.borderColor.b

	local n = NUM_RF_OVERLAYS[filter]
	for j = 1, n do
		local overlay = self[j]
		if not overlay then
			overlay = CreateOverlay(self, isHARMFUL and "OmniAurasCompactDebuffTemplate" or "OmniAurasCompactAuraTemplate") -- BuffTemplate not used yet
			overlay.cooldown.counter:SetFontObject(E.RFCounter)
			self[j] = overlay
		else
			-- Hide all on Refresh. Subsequent PEW will parse all
			ClearHideOverlayFrame(overlay)
		end

		overlay:SetScale(iconScale)
		overlay:ClearAllPoints()
		if j == 1 then
			overlay:SetPoint(db.point, self, db.point)
		elseif shouldDetachBigDebuffs and j >= detachedFrameStart then
			overlay:SetPoint(
				db.detachPoint,
				j == detachedFrameStart and (db.detachRelativeFrame == "debuffFrame" and frame.debuffFrames[1] or frame.buffFrames[1]) or self[j-1],
				db.detachRelativePoint,
				db.detachPreset == "raidFrameLeft" and (j > detachedFrameStart and -1 or -db.detachOffsetX) or (j > detachedFrameStart and 1 or db.detachOffsetX),
				0
			)
		elseif numInnerDebuffs then
			if db.stackOuter and j > numInnerDebuffs + 3 then
				overlay:SetPoint("BOTTOMRIGHT", self[j-3], "TOPRIGHT")
			elseif j > numInnerDebuffs then
				overlay:SetPoint(reversePoint[point], self[j == numInnerDebuffs + 1 and 1 or j-1], reversePoint[relPoint])
			else
				overlay:SetPoint(point, self[j-1], relPoint)
			end
		elseif isMYHELPFUL and db.preset == "overBuffs" and db.numInnerIcons <= 6 and raidDB.HARMFUL.preset ~= "raidFrameRight"
			and (not base.shouldDetachBigDebuffs or raidDB.HARMFUL.detachPreset ~= "raidFrameRight") then
			if j > db.numInnerIcons then -- 3,6,9
				overlay:SetPoint(reversePoint[point], self[j == db.numInnerIcons+1 and 1 or j-1], reversePoint[relPoint])
			elseif j > 3 then
				overlay:SetPoint("BOTTOMRIGHT", self[j-3], "TOPRIGHT")
			else
				overlay:SetPoint(point, self[j-1], relPoint)
			end
		else
			if isMYHELPFUL and j > 3 then
				overlay:SetPoint("BOTTOMRIGHT", self[j-3], "TOPRIGHT")
			else
				overlay:SetPoint(point, self[j-1], relPoint)
			end
		end

		overlay:SetSize(baseSize, baseSize)
		overlay.HighlightFlash:SetScale(baseSize / BASE_ICON_HEIGHT)
		overlay:SetAlpha(db.opacity)
		overlay:EnableMouse(overlay.isPassThrough and db.showTooltip)
		overlay.cooldown:SetSwipeColor(0, 0, 0, db.swipeAlpha)
		overlay.cooldown.counter:SetScale(base.currCounterScale * db.counterScale)
		overlay.cooldown:SetHideCountdownNumbers(db.hideCounter) -- hiding base size overlay's counter done in UNIT_AURA

		if db.borderType == "blizzard" then
			overlay.border:Show()
			overlay.borderTop:Hide()
			overlay.borderBottom:Hide()
			overlay.borderLeft:Hide()
			overlay.borderRight:Hide()
			overlay.icon:SetTexCoord(0, 1, 0, 1)
		else
			if overlay.border then
				overlay.border:Hide()
			end

			overlay.borderTop:ClearAllPoints()
			overlay.borderTop:SetPoint("TOPLEFT", overlay, "TOPLEFT")
			overlay.borderTop:SetPoint("BOTTOMRIGHT", overlay, "TOPRIGHT", 0, -edgeSize)
			overlay.borderTop:SetVertexColor(r, g, b)
			overlay.borderTop:Show()

			overlay.borderBottom:ClearAllPoints()
			overlay.borderBottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT")
			overlay.borderBottom:SetPoint("TOPRIGHT", overlay, "BOTTOMRIGHT", 0, edgeSize)
			overlay.borderBottom:SetVertexColor(r, g, b)
			overlay.borderBottom:Show()

			overlay.borderRight:ClearAllPoints()
			overlay.borderRight:SetPoint("TOPRIGHT", overlay.borderTop, "BOTTOMRIGHT")
			overlay.borderRight:SetPoint("BOTTOMLEFT", overlay.borderBottom, "TOPRIGHT", -edgeSize, 0)
			overlay.borderRight:SetVertexColor(r, g, b)
			overlay.borderRight:Show()

			overlay.borderLeft:ClearAllPoints()
			overlay.borderLeft:SetPoint("TOPLEFT", overlay.borderTop, "BOTTOMLEFT")
			overlay.borderLeft:SetPoint("BOTTOMRIGHT", overlay.borderBottom, "TOPLEFT", edgeSize, 0)
			overlay.borderLeft:SetVertexColor(r, g, b)
			overlay.borderLeft:Show()

			overlay.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		end
	end

	if isHARMFUL then
		if not self.PrivateAuraAnchors then
			self.PrivateAuraAnchor1 = CreateFrame("Frame", nil, self, "OmniAurasCompactUnitPrivateAuraAnchorTemplate")
			self.PrivateAuraAnchor1.auraIndex = 1
			self.PrivateAuraAnchor2 = CreateFrame("Frame", nil, self, "OmniAurasCompactUnitPrivateAuraAnchorTemplate")
			self.PrivateAuraAnchor2.auraIndex = 2
		end
		for _, privateAuraAnchor in ipairs(self.PrivateAuraAnchors) do
			local iconSize = baseSize * base.bossScale
			privateAuraAnchor:SetSize(iconSize, iconSize)
		end
		if db.preset == "raidFrameLeft" then
			self.PrivateAuraAnchor2:SetPoint("BOTTOMRIGHT", self.PrivateAuraAnchor1, "BOTTOMLEFT", 0, 0)
		else
			self.PrivateAuraAnchor2:SetPoint("BOTTOMLEFT", self.PrivateAuraAnchor1, "BOTTOMRIGHT", 0, 0)
		end
	end
end

--
-- Nameplate
--

local NamePlateMixin = {}

function NamePlateMixin:Nameplate_ProcessAura(aura)
	if not aura or not aura.name then
		return false
	end
	local spellId, sourceUnit = aura.spellId, aura.sourceUnit
	if not Aura_Blacklist[spellId] and (self.isMerged or aura[self.auraType]) then
		local enabledAuraData = self.enabledAura[spellId]
		if enabledAuraData then
			if self.auraType == "isHarmful" and aura.sourceUnit ~= "player" and Aura_Enabled.byPlayer[spellId] then
				return false
			end
			local type = enabledAuraData[1]
			local scale = self.db.typeScale and self.db.typeScale[type] or 1
			if Aura_Enabled.largerIcon[spellId] then
				scale = scale * self.db.largerIcon
			end
			aura.scale = scale
			aura.priority = self.priority[type]
			return true
		elseif self.db.redirectBlizzardDebuffs and not self.shouldShowCCOnly
			and (aura.nameplateShowAll or (aura.nameplateShowPersonal and (sourceUnit == "player" or sourceUnit == "pet" or sourceUnit == "vehicle"))) then
			aura.scale = self.db.blizzardDebuffs
			aura.priority = 0
			return true
		end
	end
end

function NamePlateMixin:ParseAllAuras(unit)
	if module.isInTestMode then
		module.InjectTestAuras(self)
		return
	end

	if self.auraInfo == nil then
		self.auraInfo = TableUtil.CreatePriorityTable(self.sorter, true)
	else
		self.auraInfo:Clear()
	end

	local batchCount = nil
	local usePackedAura = true
	local function HandleAura(aura)
		local type = self:Nameplate_ProcessAura(aura)
		if type then
			self.auraInfo[aura.auraInstanceID] = aura
		end
	end
	AuraUtil_ForEachAura(unit, self.filter, batchCount, HandleAura, usePackedAura)

	if self.filter == "HARMFUL" then
		local guid = self.guid or UnitGUID(unit)
		if SpellLockedGUIDS[guid] then
			for auraInstanceID, callbackTimer in pairs(SpellLockedGUIDS[guid]) do
				local aura = E:DeepCopy(callbackTimer.args[3])
				aura.scale = self.db.typeScale.softCC
				aura.priority = self.priority.softCC + 1
				self.auraInfo[auraInstanceID] = aura
			end
		end
		if self.isMerged then
			AuraUtil_ForEachAura(unit, "HELPFUL", batchCount, HandleAura, usePackedAura)
		end
	end
end

local sameIconHT = {
	[221527] = true, -- Imprison (HT) debuff
	[199448] = true, -- Ultimate Sacrifice buff on target
}

function NamePlateMixin:OnEvent(event, ...)
	if event == "UNIT_AURA" then
		local unitId, unitAuraUpdateInfo, auraChanged = ...

		if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or self.auraInfo == nil then
			self:ParseAllAuras(unitId)
			auraChanged = true
		else
			if unitAuraUpdateInfo.addedAuras ~= nil then
				for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
					local type = self:Nameplate_ProcessAura(aura)
					if type then
						self.auraInfo[aura.auraInstanceID] = aura
						auraChanged = true
					end
				end
			end

			if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
				for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
					if self.auraInfo[auraInstanceID] ~= nil then
						local newAura = C_UnitAuras_GetAuraDataByAuraInstanceID(unitId, auraInstanceID)
						if newAura ~= nil then
							newAura.priority = self.auraInfo[auraInstanceID].priority
							newAura.scale = self.auraInfo[auraInstanceID].scale
						end
						self.auraInfo[auraInstanceID] = newAura
						auraChanged = true
					end
				end
			end

			if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
				for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
					if self.auraInfo[auraInstanceID] ~= nil then
						self.auraInfo[auraInstanceID] = nil
						auraChanged = true
					end
				end
			end
		end

		if auraChanged then -- and self.auraInfo then -- req if we're limiting the number of nameplate on TestMode
			local frameNum = self.auraInfo:Size()
			local oldNum = self.frameNum
			if frameNum == 0 and oldNum and oldNum > 0 then
				for i = 1, oldNum do
					local ol = self[i]
					ClearHideOverlayFrame(ol)
				end
				self.frameNum = frameNum
				return
			end

			local now = GetTime()
			local db = self.db
			local maxIcons = db.maxIcons
			local cOffsetX, leadOverlay, leadScale = db.preset == "debuffFrameCenter" and 0
			frameNum = 1
			self.auraInfo:Iterate(function(auraInstanceID, aura)
				local overlay = self[frameNum]
				local buffScale
				local count, expirationTime, spellId, icon, duration, scale = aura.applications, aura.expirationTime, aura.spellId, aura.icon, aura.duration, aura.scale
				if spellId ~= overlay.spellId or expirationTime ~= overlay.expirationTime or count ~= overlay.stack then
					buffScale = db.scale * scale
					overlay:SetScale(buffScale)
					overlay.buffSizeScale = buffScale -- cOffsetX

					if ( db.borderType == "texture" ) then
						if ( sameIconHT[spellId] ) then
							overlay.Border:SetVertexColor(1, 0, 0)
						elseif ( self.isMerged and aura.isHelpful ) then
							overlay.Border:SetVertexColor(0, 1, 0)
						else
							overlay.Border:SetVertexColor(1, 1, 0)
						end
					elseif db.borderType == "pixelDebuff" then
						local color = aura.isHelpful and AdjustedDebuffTypeColorNamePlate["buff"]
						or AdjustedDebuffTypeColorNamePlate[aura.dispelName] or AdjustedDebuffTypeColorNamePlate["none"]
						overlay.border:SetVertexColor(color.r, color.g, color.b)
					end

					if count and count > 1 then
						--[[
						-- static stack size for scaled CC's
						if buffScale then
							overlay.count:SetScale(1 / buffScale)
						end
						]]
						overlay.count:SetText(count)
						overlay.count:Show()
					else
						overlay.count:Hide()
					end
					overlay.icon:SetTexture(icon)

					if expirationTime > 0 then
						local startTime = expirationTime - duration
						overlay.cooldown:SetCooldown(startTime, duration)
						if db.glow and Aura_Enabled.glow[spellId] and spellId ~= overlay.spellId and now - startTime < 0.1 then
							overlay.HighlightFlash:Show()
							overlay.HighlightFlash.Anim:Play()
						elseif overlay.HighlightFlash.Anim:IsPlaying() then
							overlay.HighlightFlash.Anim:Stop()
							overlay.HighlightFlash:Hide()
						end
					else
						overlay.cooldown:Clear()
						if overlay.HighlightFlash.Anim:IsPlaying() then
							overlay.HighlightFlash.Anim:Stop()
							overlay.HighlightFlash:Hide()
						end
					end
					overlay.filter = nil
					overlay.auraInstanceID = auraInstanceID
					overlay.spellId = spellId
					overlay.expirationTime = expirationTime
					overlay.stack = count
					overlay.iconTexture = icon
					overlay:Show()
				end

				if cOffsetX then
					-- if same aura then use cached value since we don't process it
					buffScale = buffScale or overlay.buffSizeScale
					if frameNum == 1 then
						leadOverlay = overlay
						leadScale = buffScale
						cOffsetX = BASE_ICON_HEIGHT * buffScale / 2
					else
						cOffsetX = cOffsetX + ((BASE_ICON_HEIGHT + db.paddingX) * buffScale) / 2
					end
				end

				frameNum = frameNum + 1
				return frameNum > maxIcons
			end)

			-- This is bad
			if cOffsetX and (unitAuraUpdateInfo == nil or cOffsetX ~= self.cOffsetX) then
				if leadOverlay then
					leadOverlay:ClearAllPoints()
					leadOverlay:SetPoint(db.point, self, db.point, (module.namePlateBuffFrameWidth/2 - cOffsetX) / leadScale, 0)
				end
				self.cOffsetX = cOffsetX
			end

			frameNum = frameNum - 1
			if oldNum and oldNum > frameNum then
				for i = frameNum + 1, oldNum do
					local ol = self[i]
					ClearHideOverlayFrame(ol)
				end
			end
			self.frameNum = frameNum
		end
	end
end

function NamePlateMixin:RegisterUnitAura(unit, filter)
	ActiveContainer[filter][unit] = self -- update namePlateFrameBase to unit
	self:RegisterUnitEvent("UNIT_AURA", unit)
	self:OnEvent("UNIT_AURA", unit, nil)
	self:Show()
end

function NamePlateMixin:UnregisterUnitAura(unit, filter)
	if ActiveContainer[filter][unit] then
		self:UnregisterEvent("UNIT_AURA")
		ActiveContainer[filter][unit] = nil
		-- NOTE: NP can selectively disable friendly nameplates. If the frame was
		-- previously on a hostile unit then the last icon texture will show up stuck
		-- on the friendly overlay (timers are cleared on Hide, textures are not).
		self:Hide()
	end
end

local function CreateNamePlateContainer(parentFrame, filter)
	local container = CreateFrame("Frame", nil, parentFrame)
	container.parent = parentFrame
	container:SetSize(1, 1)
	container.frameType = "nameplate"
	container.filter = filter
	container.auraType = filter == "HARMFUL" and "isHarmful"or "isHelpful"
	Mixin(container, NamePlateMixin)
	container:SetScript("OnEvent", container.OnEvent)
	return container
end

function module:NAME_PLATE_UNIT_ADDED(unit)
	-- namePlateFrameBase:GetName() == namePlateFrameBase.namePlateUnitToken == namePlateFrameBase.UnitFrame.unit == "nameplate#"
	local namePlateFrameBase = C_NamePlate_GetNamePlateForUnit(unit)
	if not namePlateFrameBase or namePlateFrameBase:IsForbidden() or not namePlateFrameBase.UnitFrame then
		return
	end

	local isPlayerControlled = UnitPlayerControlled(unit)
	if db.nameplate.disableNPC and not isPlayerControlled then
		return
	end

	local isMinion = isPlayerControlled and not UnitIsPlayer(unit)
	if isMinion and db.nameplate.disableMinions then
		return
	end

	ActiveNameplate[unit] = namePlateFrameBase

	local nameDB = db.nameplate
	local isMerged = nameDB.mergeAuraFrame or nameDB.showCCOnly
	local guid = UnitGUID(unit)
	local isUser = guid == userGUID
	local shouldShowCCOnly = nameDB.showCCOnly or ( isMinion and nameDB.showMinionCCOnly )

	local isHostile, enabledAura
	if isUser then
		enabledAura = Aura_Enabled.playerFrame
	else
		if UnitIsPossessed(unit) then
			isHostile = not UnitCanAttack("player", unit)
		else
			isHostile = UnitCanAttack("player", unit)
		end
		if shouldShowCCOnly then
			enabledAura = isHostile and Aura_Enabled.nameplate.CC or Aura_Enabled.friendlyNameplate.CC
		else
			enabledAura = isHostile and Aura_Enabled.nameplate or Aura_Enabled.friendlyNameplate
		end
	end

	if not NameplateContainer[namePlateFrameBase] then
		NameplateContainer[namePlateFrameBase] = {}
		for _, filter in pairs(AURA_FILTER) do
			local db = nameDB[filter]
			local container = CreateNamePlateContainer(namePlateFrameBase, filter)
			container.unit = unit
			container.guid = guid
			container.isUser = isUser
			container.isHostile = isHostile
			container.shouldShowCCOnly = shouldShowCCOnly
			container.enabledAura = enabledAura
			-- NOTE: UnitFrame is niled when nameplates are hidden before _REMOVED fires. Cache BuffFrame
			-- so we can update settings on Refresh for hidden nameplates, else we would have to call
			-- UpdateSettings everytime this event fires (BuffFrame points to the same frame when reacquired).
			-- Note2: BuffFrame width depends on active number of debuffs (full width at 0 debuffs).
			container.BuffFrame = namePlateFrameBase.UnitFrame.BuffFrame
			container.healthBar = namePlateFrameBase.UnitFrame.healthBar
			container:UpdateSettings(filter, namePlateFrameBase, nameDB, isMerged)
			NameplateContainer[namePlateFrameBase][filter] = container
			if db.enabled and (isUser and db.showPlayer or (not isUser and (isHostile or db.showFriendly)))
				and (not isMerged or filter == "HARMFUL") then
				container:RegisterUnitAura(unit, filter)
			end
		end
	else
		for filter, container in pairs(NameplateContainer[namePlateFrameBase]) do
			local db = nameDB[filter]
			container.guid = guid
			container.unit = unit
			container.isUser = isUser
			container.isHostile = isHostile
			container.shouldShowCCOnly = shouldShowCCOnly
			container.enabledAura = enabledAura
			if db.enabled and (isUser and db.showPlayer or (not isUser and (isHostile or db.showFriendly)))
				and (not isMerged or filter == "HARMFUL") then
				if filter == "HARMFUL" then
					local shouldHide = db.redirectBlizzardDebuffs or db.hideBlizzardDebuffs or nil
					if ( shouldHide ~= container.isBlizzardAuraHidden ) then
						container.BuffFrame:SetAlpha(shouldHide and 0 or 1)
						container.isBlizzardAuraHidden = shouldHide
					end
				end
				container:RegisterUnitAura(unit, filter)
			end
		end
	end
end

function module:NAME_PLATE_UNIT_REMOVED(unit)
	local namePlateFrameBase = ActiveNameplate[unit]
	if namePlateFrameBase then
		local t = NameplateContainer[namePlateFrameBase]
		for filter, container in pairs(t) do
			if ( container.isBlizzardAuraHidden ) then
				container.BuffFrame:SetAlpha(1)
				container.isBlizzardAuraHidden = nil
			end
			container:UnregisterUnitAura(unit, filter)
		end
		ActiveNameplate[unit] = nil
	end
end

-- Overlays not updating position when you have no target (switching target works) is caused by
-- Blizzard not updating the buffFrame position
function NamePlateMixin:UpdateSettings(filter, namePlateFrameBase, nameDB, isMerged)
	local db = nameDB[filter]

	-- Blizzard visibility
	if filter == "HARMFUL" then
		local shouldHide = nameDB.visibility[module.zone] and nameDB.enabled and db.enabled
			and (db.redirectBlizzardDebuffs or db.hideBlizzardDebuffs)
			and (self.isUser and db.showPlayer or (not self.isUser and (self.isHostile or db.showFriendly)))
		self.BuffFrame:SetAlpha(shouldHide and 0 or 1)
		self.isBlizzardAuraHidden = shouldHide
		-- Unlike RF, buffs are acquired on demand from the buffPool. Using hookscript to avoid calling buffPool:EnumerateActive
		-- on UNIT_AURA. This will hide tooltips on all nameplate buffs which may be undesired.
		if NamePlateTooltip then
			if shouldHide and not module.isNamePlateTooltipHidden then
				module:SecureHookScript(NamePlateTooltip, "OnShow", function() NamePlateTooltip:Hide() end)
				module.isNamePlateTooltipHidden = true
			elseif not shouldHide and module.isNamePlateTooltipHidden then
				module:Unhook(NamePlateTooltip, "OnShow")
				module.isNamePlateTooltipHidden = nil
			end
		end
	end

	-- Container settings
	self:SetFrameStrata(db.frameStrata) -- set above elite icon
	self:SetFrameLevel(namePlateFrameBase:GetFrameLevel() + db.frameLevel) -- set above nameplate healthbar
	self:ClearAllPoints()
	local relTo = db.relativeFrame == "healthBar" and self.healthBar or self.BuffFrame
	local relPoint = (nameDB.HARMFUL.redirectBlizzardDebuffs or nameDB.HARMFUL.hideBlizzardDebuffs) and db.relativeFrame == "debuffFrame" and db.point or db.relativePoint
	self:SetPoint(db.point, relTo, relPoint, db.point == "RIGHT" and -db.offsetX or db.offsetX, db.offsetY)
	self.isMerged = isMerged
	self.priority = nameDB.priority
	self.sorter = AuraComparator[isMerged and filter == "HARMFUL" and (db.maxIcons < 3 and "prioNew" or db.mergedSortby) or db.sortby]
	self.db = db

	-- Overlay settings
	local paddingX = strfind(db.point, "RIGHT") and -db.paddingX or db.paddingX
	local scale = db.scale
	for j = 1, NUM_NP_OVERLAYS do
		local overlay = self[j]
		if not overlay then
			overlay = CreateOverlay(self)
			overlay.cooldown.counter:SetFontObject(E.NpCounter)
			self[j] = overlay
		else
			ClearHideOverlayFrame(overlay)
		end
		overlay:ClearAllPoints()
		if j == 1 then
			overlay:SetPoint(db.point, self, db.point)
		else
			local rel = db.point == "BOTTOM" and "BOTTOMRIGHT" or reversePoint[db.point]
			overlay:SetPoint(db.point == "BOTTOM" and "BOTTOMLEFT" or db.point, self[j-1], rel, paddingX, 0)
		end

		overlay:SetSize(BASE_ICON_HEIGHT, BASE_ICON_HEIGHT)
		overlay:SetScale(scale)
		overlay.count:SetScale(1 / scale)
		overlay:SetAlpha(db.opacity)
		overlay:EnableMouse(overlay.isPassThrough and db.showTooltip)
		overlay.cooldown:SetSwipeColor(0, 0, 0, db.swipeAlpha)
		overlay.cooldown.counter:SetScale(db.counterScale)
		overlay.cooldown:SetHideCountdownNumbers(db.hideCounter)
		overlay.cooldown:SetDrawEdge(db.drawEdge)

		if db.borderType == "texture" then
			overlay.borderTop:Hide()
			overlay.borderBottom:Hide()
			overlay.borderLeft:Hide()
			overlay.borderRight:Hide()
			if overlay.border then
				overlay.border:Hide()
			end

			--[[
			if scale < 1 then
				--overlay.Border:SetTexture("Interface\\BUTTONS\\UI-Quickslot-Depress")
				--overlay.Border:SetDrawLayer("BORDER") -- draw under icon to mask the depress texture
				overlay.Border:SetTexture("Interface/AddOns/OmniAuras/Media/omnicd-ui-quickslot-no-depress-white")
				overlay.Border:SetDrawLayer("OVERLAY")
				overlay.Border:ClearAllPoints()
				overlay.Border:SetPoint("TOPLEFT", -2.5, 2.5)
				overlay.Border:SetPoint("BOTTOMRIGHT", 2.5, -2.5)
			else
				overlay.Border:SetAtlas("orderhalltalents-spellborder-yellow", true)
				overlay.Border:SetDrawLayer("OVERLAY")
				overlay.Border:ClearAllPoints()
				overlay.Border:SetPoint("CENTER")
			end
			]]
			overlay.Border:SetAtlas("orderhalltalents-spellborder-yellow", true)
			overlay.Border:SetDrawLayer("OVERLAY")
			overlay.Border:ClearAllPoints()
			overlay.Border:SetPoint("CENTER")

			overlay.Border:Show()
			overlay.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		else
			overlay.borderTop:Hide()
			overlay.borderBottom:Hide()
			overlay.borderLeft:Hide()
			overlay.borderRight:Hide()
			overlay.Border:Hide()

			-- Can't use GetEffectiveScale on animated frames
			if not overlay.border then
				overlay.border = CreateFrame("Frame", nil, overlay, "NamePlateFullBorderTemplate")
				overlay.border:SetBorderSizes(1, 1, 1, 1)
				for _, texture in ipairs(overlay.border.Textures) do
					texture:SetTexelSnappingBias(0.0)
					texture:SetSnapToPixelGrid(false)
				end
			end
			overlay.border:UpdateSizes()
			overlay.border:SetVertexColor(0, 0, 0, 1)
			overlay.border:Show()

			overlay.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		end
	end
end

--
-- Spell Lockout
--

local WarningFramePool = {}

local function ReleaseWarningFrame_OnHide(self)
	if self.pulseAnim:IsPlaying() then
		self.pulseAnim:Stop()
	end
	self:Hide()
	self.icon.warningFrame = nil
	tinsert(WarningFramePool, self)
end

local function AcquireWarningFrame(icon)
	local frame = tremove(WarningFramePool)
	if not frame then
		frame = CreateFrame("Frame", nil, UIParent, "OmniAurasLockOutButtonTemplate")
		frame:SetFrameStrata(icon:GetFrameStrata())
		frame:SetFrameLevel(icon:GetFrameLevel()+1)
		frame:SetScript("OnHide", ReleaseWarningFrame_OnHide)
	end
	-- NOTE: SetParent to hide and release the lockout frame whenever UpdateUnitBar is called
	-- as icons may no longer point to the same spell (all icons are hidden initially on SetIconLayout)
	frame:SetParent(icon)
	frame.icon = icon
	frame:ClearAllPoints()
	frame:SetAllPoints(icon)
	return frame
end

local UpdateOmniCDWarning = function(destGUID, auraInstanceID)
	local info = module.OmniCDParty.groupInfo[destGUID]
	if info and not info.isDeadOrOffline then
		local icon = info.spellIcons[45438] -- Ice Block. Ignore Cold Snap availability
		if icon and not icon.active and icon:IsVisible() then
			if not icon.warningFrame then
				icon.warningFrame = AcquireWarningFrame(icon)
				icon.warningFrame.pulseAnim:Play()
			end
			-- redirect if duration is off and it sees another frost lockout
			SpellLockedGUIDS[destGUID][auraInstanceID].args.warningFrame = icon.warningFrame
		end
	end
end

local function UpdateAllActiveFrameDebuffs(guid)
	for unit, container in pairs(ActiveContainer.HARMFUL) do
		if container.guid == guid then
			if (unit ~= "target" and unit ~= "focus") or container:IsVisible() then -- target/focus are never removed from ActiveContainer
				container:OnEvent("UNIT_AURA", unit, nil)
			end
		end
	end
end

local Lockout_OnTimerEnd = function(destGUID, auraInstanceID)
	local callbackTimer = SpellLockedGUIDS[destGUID] and SpellLockedGUIDS[destGUID][auraInstanceID]
	if callbackTimer then
		if callbackTimer.args.warningFrame then
			-- check if there's another frost lockout
			local found
			for id, timer in pairs(SpellLockedGUIDS[destGUID]) do
				if id ~= auraInstanceID and timer.args[3].mageLockedFrostSchool then
					found = true
				end
			end
			if not found then
				callbackTimer.args.warningFrame:Hide()
			end
		end
		SpellLockedGUIDS[destGUID][auraInstanceID] = nil
		UpdateAllActiveFrameDebuffs(destGUID)
	end
end

local InterruptData = {}

for spellId, spell in pairs(E.aura_db.INTERRUPT) do
	InterruptData[spellId] = {
		icon = spell[6],
		applications = 0,
		dispelName = "none",
		duration = spell[5],
		expirationTime = 0,
		spellId = spellId,
		auraInstanceID = 0,
		isHarmful = true,
		name = C_Spell.GetSpellName(spellId),
		priority = 1,
		scale = 1,
	}
end

local spellLockReducer = {
	[317920] = 0.7, -- Concentration Aura (no duration)
	[234084] = 0.3, -- Moon and Stars (10sec duration)
	[383020] = 0.5, -- Tranquil Air (20sec duration)
}

local RegisteredEvents = {}
RegisteredEvents.SPELL_INTERRUPT = {}
RegisteredEvents.SPELL_CAST_SUCCESS = {}

for spellId, spell in pairs(InterruptData) do
	RegisteredEvents.SPELL_INTERRUPT[spellId] = function(destGUID, extraSchool)
		local aura
		for unit, container in pairs(ActiveContainer.HARMFUL) do
			unit = unit == "uplayer" and "player" or partyFrameUnitId[unit] or unit
			local guid = container.guid or UnitGUID(unit)
			if guid == destGUID then
				if not aura then
					aura = E:DeepCopy(spell)
					local duration = aura.duration
					AuraUtil_ForEachAura(unit, "HELPFUL", nil, function(_,_,_,_,_,_,_,_,_, id)
						local mult = spellLockReducer[id]
						if mult then
							duration = duration * mult
						end
					end)
					AuraUtil_ForEachAura(unit, "HARMFUL", nil, function(_,_,_,_,_,_,_,_,_, id)
						if id == 372048 then
							duration = duration * (module.isInPvPInstance and 1.3 or 1.5)
							return true
						end
					end)

					aura.expirationTime = GetTime() + duration
					aura.auraInstanceID = floor(aura.expirationTime)
					aura.lockedSchool = extraSchool
					local isLockedInFrost = band(aura.lockedSchool, 16)
					if isLockedInFrost ~= 0 then
						aura.mageLockedFrostSchool = select(2, UnitClass(unit)) == "MAGE" and isLockedInFrost
					end
					aura.lockedSchoolName = C_Spell.GetSchoolString(extraSchool) -- localized string (e.g 48: Shadowfrost)

					SpellLockedGUIDS[destGUID] = SpellLockedGUIDS[destGUID] or {}
					SpellLockedGUIDS[destGUID][aura.auraInstanceID] = E.TimerAfter(duration, Lockout_OnTimerEnd, destGUID, aura.auraInstanceID, aura) -- append aura timer.args

					if aura.mageLockedFrostSchool and module.OmniCDParty then
						UpdateOmniCDWarning(destGUID, aura.auraInstanceID)
					end
				end
				if container.auraInfo and container.enabledAura[spellId] then
					local caura = E:DeepCopy(aura)
					caura.scale = container.db.typeScale and container.db.typeScale.softCC
					caura.priority = container.priority.softCC + 1
					container.auraInfo[caura.auraInstanceID] = caura
				end
				container:OnEvent("UNIT_AURA", unit, E.BLANK, true) -- skip parsing
			end
		end
	end

	-- NOTE: Interrupting a channel usually doesn't fire SPELL_INTERRUPT (e.g. Penance).
	-- However, some channels do (e.g. Ray of Frost), but as long as we're using the same auraInstanceID
	-- we won't have duplicate icons showing.
	RegisteredEvents.SPELL_CAST_SUCCESS[spellId] = function(destGUID)
		local aura
		for unit, container in pairs(ActiveContainer.HARMFUL) do
			unit = unit == "uplayer" and "player" or partyFrameUnitId[unit] or unit
			local guid = container.guid or UnitGUID(unit)
			if guid == destGUID then
				if not aura then
					local _,_,_,_,_,_, notInterruptable, channelID = UnitChannelInfo(unit)
					if notInterruptable ~= false then -- nil when not channeling
						return
					end
					aura = E:DeepCopy(spell)
					local duration = aura.duration
					AuraUtil_ForEachAura(unit, "HELPFUL", nil, function(_,_,_,_,_,_,_,_,_, id)
						local mult = spellLockReducer[id]
						if mult then
							duration = duration * mult
						end
					end)
					AuraUtil_ForEachAura(unit, "HARMFUL", nil, function(_,_,_,_,_,_,_,_,_, id)
						if id == 372048 then
							duration = duration * (module.isInPvPInstance and 1.3 or 1.5)
							return true
						end
					end)

					aura.expirationTime = GetTime() + duration
					aura.auraInstanceID = floor(aura.expirationTime)

					SpellLockedGUIDS[destGUID] = SpellLockedGUIDS[destGUID] or {}
					SpellLockedGUIDS[destGUID][aura.auraInstanceID] = E.TimerAfter(duration, Lockout_OnTimerEnd, destGUID, aura.auraInstanceID, aura)

					if channelID == 205021 then -- Ray of Frost -- TODO: any other channeled frost spells for Mage?
						aura.lockedSchool = 16
						aura.mageLockedFrostSchool = true
						if module.OmniCDParty then
							UpdateOmniCDWarning(destGUID, aura.auraInstanceID)
						end
					end
				end
				if container.auraInfo and container.enabledAura[spellId] then
					local caura = E:DeepCopy(aura)
					caura.scale = container.db.typeScale and container.db.typeScale.softCC
					caura.priority = container.priority.softCC + 1
					container.auraInfo[caura.auraInstanceID] = caura
				end
				container:OnEvent("UNIT_AURA", unit, E.BLANK, true)
			end
		end
	end
end

-- Remove Frost lockout on Cold Snap
RegisteredEvents.SPELL_CAST_SUCCESS[235219] = function(_,_, srcGUID)
	if SpellLockedGUIDS[srcGUID] then
		local frostLockoutRemoved
		for auraInstanceID, callbackTimer in pairs(SpellLockedGUIDS[srcGUID]) do
			local aura = callbackTimer.args[3]
			if aura and aura.mageLockedFrostSchool then
				if callbackTimer.args.warningFrame then
					callbackTimer.args.warningFrame:Hide()
				end
				if aura.mageLockedFrostSchool == 16 then
					callbackTimer:Cancel()
					SpellLockedGUIDS[srcGUID][auraInstanceID] = nil
				elseif aura.mageLockedFrostSchool > 16 then
					local newSchool = aura.mageLockedFrostSchool - 16
					aura.lockedSchool = newSchool
					aura.lockedSchoolName = C_Spell.GetSchoolString(newSchool)
					aura.mageLockedFrostSchool = nil
				end
				frostLockoutRemoved = true
			end
		end
		if frostLockoutRemoved then
			UpdateAllActiveFrameDebuffs(srcGUID)
		end
	end
end

function module:COMBAT_LOG_EVENT_UNFILTERED()
	local _, event, _,srcGUID, _,_,_, destGUID, _,_,_, spellId, _,_, extraSpellId, _, extraSchool = CombatLogGetCurrentEventInfo()
	local func = RegisteredEvents[event] and RegisteredEvents[event][spellId]
	if func then
		func(destGUID, extraSchool, srcGUID, extraSpellId)
	end
end

--
-- Event Handling
--

local AddEnabledAura
AddEnabledAura = function(frame, id, v, ccEnabledFrame)
	if type(id) == "table" then
		for _, mergedId in pairs(id) do
			AddEnabledAura(frame, mergedId, v, ccEnabledFrame)
		end
	else
		Aura_Enabled[frame][id] = v
		if ccEnabledFrame then
			ccEnabledFrame[id] = v
		end
	end
end

local function UpdateEnabledAuras()
	for k, v in pairs(Aura_Enabled) do
		wipe(v)
		if k == "nameplate" or k == "friendlyNameplate" or k == "unitFrame" or k == "playerFrame" then
			Aura_Enabled[k].CC = {}
		end
	end
	for _, t in pairs(E.aura_db) do
		for id, v in pairs(t) do
			local classPriority, mergedAuraIDs = v[1], v[4]
			local sId = tostring(id)
			local auraData = db.auras[sId] -- blacklist filtered in _ProcessAura
			if auraData then
				for frame, state in pairs(auraData) do
					local ccEnabledFrame = (classPriority == "hardCC" or classPriority == "softCC") and Aura_Enabled[frame].CC
					if state then
						if mergedAuraIDs then
							AddEnabledAura(frame, mergedAuraIDs, v, ccEnabledFrame)
						end
						AddEnabledAura(frame, id, v, ccEnabledFrame)
					end
				end
			end
		end
	end
end

local function FindMergedIDs(spellId)
	for _, t in pairs(E.aura_db) do
		if t[spellId] then
			return t[spellId][4]
		end
	end
end

local AddNoFriendAura
AddNoFriendAura = function(id)
	if type(id) == "table" then
		for _, mergedId in pairs(id) do
			AddNoFriendAura(mergedId)
		end
	else
		Aura_NoFriend[id] = true
	end
end

local function UpdateFilteredAuras()
	wipe(Aura_NoFriend)
	for type, t in pairs(db.auraFiltered) do
		for sId, state in pairs(t) do
			if state and type == "noFriend" then
				local id = tonumber(sId)
				local mergedAuraIDs = FindMergedIDs(id)
				if mergedAuraIDs then
					AddNoFriendAura(mergedAuraIDs)
				end
				AddNoFriendAura(id)
			end
		end
	end
end

-- TWW: this require maintenance as it's tied to talents
local dispelsBySpecialization = {
	[62] = { 475, "Curse" }, -- Remove Curse
	[63] = { 475, "Curse" },
	[64] = { 475, "Curse" },
	[65] = { 4987, "Magic", 393024, "Poison:Disease" }, -- Cleanse, Improved Cleanse
	[66] = { 213644, "Poison:Disease" }, -- Cleans Toxins
	[70] = { 213644, "Poison:Disease" },
	[102] = { 2782, "Curse:Poison" }, -- Remove Corruption
	[103] = { 2782, "Curse:Poison" },
	[104] = { 2782, "Curse:Poison" },
	[105] = { 88423, "Magic", 392378, "Curse:Poison" }, -- Nature's cure, Improved Nature's cure
	[256] = { 527, "Magic", 390632, "Disease" }, -- Purify, Improved Purify
	[257] = { 527, "Magic", 390632, "Disease" },
	[258] = { 213634, "Disease" }, -- Purify Disease
	[262] = { 51886, "Curse" }, -- Cleanse Spirit
	[263] = { 51886, "Curse" },
	[264] = { 77130, "Magic", 383016, "Curse" }, -- Purify Spirit, Improved Purify Spirit
	[268] = { 218164, "Poison:Disease" }, -- Detox
	[269] = { 218164, "Poison:Disease" },
	[270] = { 115450, "Magic", 388874, "Poison:Disease" }, -- Detox, Improved Detox
	[1467] = { 365585, "Poison" }, -- Expunge
	[1468] = { 360823, "Magic", 365585, "Poison" }, -- Expunge(default), Naturalize
	[1473] = { 365585, "Poison" },
}

local function UpdateDispellableDebuffType()
	wipe(DispellableDebuffType)

	local specIndex = GetSpecialization()
	local specID = GetSpecializationInfo(specIndex)

	local dispelInfo = dispelsBySpecialization[specID]
	if dispelInfo then
		for i = 1, #dispelInfo, 2 do
			local talentId, debuffStr = dispelInfo[i], dispelInfo[i+1]
			if IsPlayerSpell(talentId) then
				debuffStr = strsplittable(":", debuffStr)
				for _, debuffType in pairs(debuffStr) do
					DispellableDebuffType[debuffType] = true
				end
			end
		end
	end
end

function module:UnitFrame_UpdateAll(updateComparator)
	for unit, t in pairs(UnitFrameContainer) do
		local unitType = UF_UNITTYPE[unit]
		local unitTypeDB = db.unitFrame[unitType]
		local frameName = UF_FRAMENAME[unit]
		local uf = unitType == "party" and frameName or _G[frameName]
		local isMerged = unitTypeDB.mergeAuraFrame or unitTypeDB.showCCOnly
			or (unitTypeDB.HARMFUL.enabled and unitTypeDB.HARMFUL.preset == "PORTRAIT" and unitTypeDB.HELPFUL.enabled and unitTypeDB.HELPFUL.preset == "PORTRAIT")
		local enabledAura = unit == "player" and Aura_Enabled.playerFrame or (unitType == "arena" and Aura_Enabled.arenaFrame) or Aura_Enabled.unitFrame
		enabledAura = unitTypeDB.showCCOnly and enabledAura.CC or enabledAura
		for filter, container in pairs(t) do
			container:UpdateSettings(filter, uf, unitTypeDB, isMerged, enabledAura)
			if updateComparator then
				container.auraInfo = nil
			end
		end
	end
end

function module:CompactUnitFrame_UpdateAll(updateComparator)
	local raidDB = db.raidFrame
	for frame, t in pairs(CompactUnitFrameContainer) do
		for filter, container in pairs(t) do
			container:UpdateSettings(filter, frame, raidDB, BuffFrameBase[container.systemIndex])
			if updateComparator then
				container.auraInfo = nil
			end
		end
	end
end

function module:Nameplate_UpdateAll(updateComparator)
	local nameDB = db.nameplate
	local isMerged = nameDB.mergeAuraFrame or nameDB.showCCOnly
	for namePlateFrameBase, t in pairs(NameplateContainer) do
		for filter, container in pairs(t) do
			container:UpdateSettings(filter, namePlateFrameBase, nameDB, isMerged)
			if updateComparator then
				container.auraInfo = nil
			end
		end
	end
end

function module:UnitFrame_RegisterEvents()
	local enabled = db.unitFrame.enabled
	local disabled = true
	for unit, t in pairs(UnitFrameContainer) do
		local unitType = UF_UNITTYPE[unit]
		if unitType ~= "party" then -- party done in CompactUnitFrame_RegisterEvents
			local unitTypeDB = db.unitFrame[unitType]
			local guid = UnitGUID(unit)
			local enabledUnitType = enabled and unitTypeDB.enabled
				and (self.isInTestMode or unitTypeDB.visibility[self.zone])
				and (unit ~= "pet" or E.userClass == "WARLOCK" or E.userClass == "HUNTER")
			local isMerged = unitTypeDB.mergeAuraFrame or unitTypeDB.showCCOnly
			for filter, container in pairs(t) do
				if enabledUnitType and unitTypeDB[filter].enabled and (not isMerged or filter == "HARMFUL") then
					-- Handle updating auras on target change
					if unit == "focus" then
						container:RegisterEvent("PLAYER_FOCUS_CHANGED")
					elseif unit == "target" then
						container:RegisterEvent("PLAYER_TARGET_CHANGED")
					-- Handle updating auras on new arena enemy
					elseif unitType == "arena" then
						container:RegisterEvent("ARENA_OPPONENT_UPDATE")
					end
					-- Register UNIT_AURA
					container.guid = guid -- can be nil
					UnitFrame_RegisterUnitAura(container, unit, filter)
					disabled = nil
				else
					if unit == "focus" then
						container:UnregisterEvent("PLAYER_FOCUS_CHANGED")
					elseif unit == "target" then
						container:UnregisterEvent("PLAYER_TARGET_CHANGED")
					elseif unitType == "arena" then
						container:UnregisterEvent("ARENA_OPPONENT_UPDATE")
					end
					UnitFrame_UnregisterUnitAura(container, unit, filter)
				end
			end
		end
	end
	self.disabledUF = disabled
end

local function UpdateZoneHooks()
	if not C_AddOns.IsAddOnLoaded("Blizzard_CompactRaidFrames") or not C_AddOns.IsAddOnLoaded("Blizzard_CUFProfiles") then
		return
	end
	local isHooked = module:IsHooked(CompactPartyFrame, "RefreshMembers")
	if isHooked and not module.isInArena then
		module:Unhook(CompactPartyFrame, "RefreshMembers")
	elseif not isHooked and module.isInArena then
		module:SecureHook(CompactPartyFrame, "RefreshMembers", module.OnRefreshMemebers)
	end
end

function module:CompactUnitFrame_RegisterEvents(isRefresh)
	local raidDB, unitDB = db.raidFrame, db.unitFrame
	local disabledCUF = not (raidDB.visibility[self.zone] and raidDB.enabled and (raidDB.HARMFUL.enabled or raidDB.HELPFUL.enabled or raidDB.MYHELPFUL.enabled))
	local disabledPartyUF = not (unitDB.party.visibility[self.zone] and unitDB.enabled and unitDB.party.enabled and (unitDB.party.HARMFUL.enabled or unitDB.party.HELPFUL.enabled))
	self.disabledCUF = disabledCUF
	self.disabledPartyUF = disabledPartyUF

	if disabledCUF then
		CompactUnitFrame_UnregisterAllUnitAura(nil) -- remove all#
	end
	if disabledPartyUF or self:CompactFrameIsActive() then
		PartyUnitFrame_UnregisterAllUnitAura()
	end
	if disabledCUF and disabledPartyUF then
		self:UnregisterEvent("GROUP_ROSTER_UPDATE")
	else
		-- NOTE: Using EditMode even once will start to cause a delay in updating frame.unit to the correct unitId.
		C_Timer.After(0, function() self:GROUP_ROSTER_UPDATE(isRefresh) end)
		self:RegisterEvent("GROUP_ROSTER_UPDATE")
	end

	UpdateZoneHooks()
end

function module:Nameplate_RegisterEvents()
	local nameDB = db.nameplate
	local enabled = nameDB.visibility[self.zone] and nameDB.enabled and (nameDB.HARMFUL.enabled or nameDB.HELPFUL.enabled)
	if enabled then
		self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
		-- Update all existing nameplates
		for _, namePlateFrameBase in ipairs(C_NamePlate.GetNamePlates(false)) do
			local unit = namePlateFrameBase.namePlateUnitToken
			self:NAME_PLATE_UNIT_REMOVED(unit)
			self:NAME_PLATE_UNIT_ADDED(unit)
		end
	else
		self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
		self:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
		for _, t in pairs(NameplateContainer) do
			local unit = t.HARMFUL.unit
			self:NAME_PLATE_UNIT_REMOVED(unit)
		end
	end
	self.disabledNP = not enabled
end

function module:Refresh(updateComparator) -- wipe auraInfo and create new metatable to update comparator. Clear() only empties table
	-- Update db
	db = E.profile
	Aura_Blacklist = E.global.auraBlacklist
	self.OmniCDParty = db.warnFrostLockout and OmniCD and OmniCD[1] and OmniCD[1].Party

	self.namePlateBuffFrameWidth = C_CVar.GetCVar("NamePlateVerticalScale") == "2.7" and 131 or 87
	if db.nameplate.HARMFUL.preset == "debuffFrameCenter" or db.nameplate.HELPFUL.preset == "debuffFrameCenter" then
		self:RegisterEvent("CVAR_UPDATE")
	else
		self:UnregisterEvent("CVAR_UPDATE")
	end

	-- Clear timers
	for guid, timers in pairs(SpellLockedGUIDS) do
		for _, callbackTimer in pairs(timers) do
			callbackTimer:Cancel()
		end
		SpellLockedGUIDS[guid] = nil
	end

	-- Update general settings
	E:UpdateFontObjects()
	E:SetPixelMult()

	-- Update auras
	UpdateEnabledAuras()
	UpdateFilteredAuras()
	UpdateDispellableDebuffType()

	-- Update display settings
	AdjustedDebuffTypeColor = E:CopyAdjustedColors(db.raidFrame.HARMFUL.debuffTypeColor, 0.7)
	AdjustedDebuffTypeColorArena = E:CopyAdjustedColors(db.unitFrame.arena.HARMFUL.debuffTypeColor, 0.7)
	AdjustedDebuffTypeColorNamePlate = E:CopyAdjustedColors(db.nameplate.HARMFUL.debuffTypeColor, 0.7)

	-- Zone dependent stuff
	module:PLAYER_ENTERING_WORLD(nil, true, updateComparator)
end

function module:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi, updateComparator)
	local _, instanceType = IsInInstance()
	self.zone = instanceType
	self.isInArena = instanceType == "arena"
	self.isInPvPInstance = self.isInArena or instanceType == "pvp"
	self.isInPvEInstance = instanceType == "party" or instanceType == "raid"

	-- Update display settings
	self:SetBuffFrameBase()
	self:CompactUnitFrame_UpdateAll(updateComparator)
	self:Nameplate_UpdateAll(updateComparator)
	self:UnitFrame_UpdateAll(updateComparator)

	-- Update visibility
	self:CompactUnitFrame_RegisterEvents(true) -- Do not change (need to force update on GRU)
	self:UnitFrame_RegisterEvents()
	self:Nameplate_RegisterEvents()
	if self.disabledUF and self.disabledNP and self.disabledCUF then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
	-- Fix LFR/SS
	C_Timer.After(5, function() self:CompactUnitFrame_RegisterEvents(isReloadingUi or updateComparator) end)
end
module.ZONE_CHANGED_NEW_AREA = module.PLAYER_ENTERING_WORLD

--
-- Test Mode
--

module.testAuras = {}

module.testAuras.HARMFUL = {
--	[99] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=118699,["icon"]=136183,["dispelName"]="Magic",["duration"]=15,["classType"]="hardCC" }, -- Fear
--	[98] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=118699,["icon"]=136183,["dispelName"]="Magic",["duration"]=15,["classType"]="hardCC" }, -- Fear
--	[97] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=118699,["icon"]=136183,["dispelName"]="Magic",["duration"]=15,["classType"]="hardCC" }, -- Fear
	[31] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=118699,["icon"]=136183,["dispelName"]="Magic",["duration"]=15,["classType"]="hardCC" }, -- Fear
	[32] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=236077,["icon"]=132343,["dispelName"]="none",["duration"]=15,["classType"]="disarmRoot" }, -- Disarm
	[33] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=198819,["icon"]=132355,["dispelName"]="none",["duration"]=15,["classType"]="debuff" }, -- Mortal Strike (big debuff)
	[34] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" }, -- Mortal Wounds
	[35] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[36] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[37] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[38] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[39] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[40] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[41] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[42] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[43] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[44] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[45] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
	[46] = { ["applications"]=0,["expirationTime"]=0,["isHarmful"]=true,["spellId"]=115804,["icon"]=132109,["dispelName"]="none",["duration"]=15,["classType"]="debuff" },
}
module.testAuras.HELPFUL = {
	[11] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" }, -- Unending Resolve
	[12] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[13] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[14] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[15] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[16] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[17] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[18] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[19] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[20] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[21] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[22] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=104773,["icon"]=136150,["dispelName"]="none",["duration"]=15,["classType"]="otherImmunity" },
	[23] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=47788,["icon"]=237542,["dispelName"]="none",["duration"]=15,["classType"]="defensive" }, -- Guardian Spirit
	[24] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=47788,["icon"]=237542,["dispelName"]="none",["duration"]=15,["classType"]="defensive" },
	[25] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=47788,["icon"]=237542,["dispelName"]="none",["duration"]=15,["classType"]="defensive" },
	[26] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=47788,["icon"]=237542,["dispelName"]="none",["duration"]=15,["classType"]="defensive" },
}
module.testAuras.MYHELPFUL = {
	[51] = { ["applications"]=3,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=203554,["icon"]=1408837,["dispelName"]="Magic",["duration"]=15,["classType"]="buff", ["isBossAura"]=true }, -- Focused Growth
	[52] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" }, -- Rejuvenation
	[53] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[54] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[55] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[56] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[57] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[58] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[59] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[60] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[61] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[62] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[63] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[64] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[65] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
	[66] = { ["applications"]=0,["expirationTime"]=0,["isHelpful"]=true,["spellId"]=774,["icon"]=136081,["dispelName"]="Magic",["duration"]=15,["classType"]="buff" },
}

-- Set true if you want to see disabled auras on nameplates
local showAllTestAuras = nil

local function ForEachTestAura(self, filter)
	local now = GetTime()
	for fakeInstanceID, aura in pairs(module.testAuras[filter]) do
		if showAllTestAuras or self.frameType ~= "nameplate" or self.enabledAura[aura.spellId] then
			if filter == "MYHELPFUL" or not self.isMerged or (filter == "HARMFUL" and fakeInstanceID < 37) or (filter == "HELPFUL" and fakeInstanceID < 17) then
				aura = E:DeepCopy(aura)
				aura.auraInstanceID = fakeInstanceID
				aura.expirationTime = now + aura.duration
				local scale = self.db.typeScale and self.db.typeScale[aura.classType] or 1
				if self.db.largerIcon and Aura_Enabled.largerIcon[aura.spellId] then
					scale = scale * self.db.largerIcon
				end
				aura.scale = scale
				aura.priority = self.priority[aura.classType] + (aura.dispelName == "none" and 1 or 0)
				aura.forceGlow = self.db.alwaysGlowCC and (aura.classType == "hardCC" or aura.classType == "softCC")
				self.auraInfo[fakeInstanceID] = aura
			end
		end
	end
end

function module.InjectTestAuras(self)
	if self.auraInfo == nil then
		self.auraInfo = TableUtil.CreatePriorityTable(self.sorter, true)
	else
		self.auraInfo:Clear()
	end

	ForEachTestAura(self, self.rawFilter or self.filter)
	if self.isMerged and self.filter == "HARMFUL" then
		ForEachTestAura(self, "HELPFUL")
	end
end

function module:ToggleTestMode()
	self.isInTestMode = not self.isInTestMode
	if self.isInTestMode then
		if self.inLockdown then
			self.isInTestMode = false
			return E.write(ERR_NOT_IN_COMBAT)
		end
		if not self.isInEditMode then
			ShowUIPanel(EditModeManagerFrame)
		end
	elseif self.isInEditMode then
		if self.inLockdown then
			self.endTestModeOCC = true
		else
			HideUIPanel(EditModeManagerFrame)
		end
	end

	local updateComparator = true
	self:Refresh(updateComparator)
end

function module:PLAYER_REGEN_ENABLED()
	self.inLockdown = false
	if self.endTestModeOCC then
		HideUIPanel(EditModeManagerFrame)
		self.endTestModeOCC = nil
	end
	UpdatePassThroughButtons()
end

function module:PLAYER_REGEN_DISABLED()
	self.inLockdown = true
end

function module:PLAYER_SPECIALIZATION_CHANGED()
	UpdateDispellableDebuffType()
end

function module:CVAR_UPDATE(cvar, value)
	if cvar == "NamePlateVerticalScale" then
		self.namePlateBuffFrameWidth = value == "2.7" and 131 or 87 -- Blizzard defaults
		self:Nameplate_RegisterEvents()
	end
end

EventRegistry:RegisterCallback("EditMode.Exit", function()
	module.isInEditMode = nil
	if module.isInTestMode then
		module:ToggleTestMode()
		E:ACR_NotifyChange()
	else
		-- Fix temporary unitIds. EditMode w/o raidstylepartframe sets all unit to 'player' until a group is formed
		module:Refresh()
	end
end)

-- Use EditModeManagerFrame:IsEditModeActive() if this value is needed instantly on Enter
EventRegistry:RegisterCallback("EditMode.Enter", function()
	module.isInEditMode = true
end)

E.NUM_RF_OVERLAYS = NUM_RF_OVERLAYS
E.NUM_AF_OVERLAYS = NUM_AF_OVERLAYS
E.NUM_NP_OVERLAYS = NUM_NP_OVERLAYS
