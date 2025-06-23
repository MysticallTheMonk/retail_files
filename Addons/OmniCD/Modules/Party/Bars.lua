local E = select(2, ...):unpack()
local P, CM = E.Party, E.Comm

local UNIT_TO_PET = {
	["raid1"]="raidpet1", ["raid2"]="raidpet2", ["raid3"]="raidpet3", ["raid4"]="raidpet4", ["raid5"]="raidpet5",
	["raid6"]="raidpet6", ["raid7"]="raidpet7", ["raid8"]="raidpet8", ["raid9"]="raidpet9", ["raid10"]="raidpet10",
	["raid11"]="raidpet11", ["raid12"]="raidpet12", ["raid13"]="raidpet13", ["raid14"]="raidpet14", ["raid15"]="raidpet15",
	["raid16"]="raidpet16", ["raid17"]="raidpet17", ["raid18"]="raidpet18", ["raid19"]="raidpet19", ["raid20"]="raidpet20",
	["raid21"]="raidpet21", ["raid22"]="raidpet22", ["raid23"]="raidpet23", ["raid24"]="raidpet24", ["raid25"]="raidpet25",
	["raid26"]="raidpet26", ["raid27"]="raidpet27", ["raid28"]="raidpet28", ["raid29"]="raidpet29", ["raid30"]="raidpet30",
	["raid31"]="raidpet31", ["raid32"]="raidpet32", ["raid33"]="raidpet33", ["raid34"]="raidpet34", ["raid35"]="raidpet35",
	["raid36"]="raidpet36", ["raid37"]="raidpet37", ["raid38"]="raidpet38", ["raid39"]="raidpet39", ["raid40"]="raidpet40",
	["party1"]="partypet1", ["party2"]="partypet2", ["party3"]="partypet3", ["party4"]="partypet4", ["player"]="pet"
}

local BarFrameMixin = {}

function BarFrameMixin:OnEvent(event, ...)
	local info = self.info
	if event == "UNIT_SPELLCAST_SUCCEEDED" then


		local unit, _, spellID = ...
		if unit ~= self.unit and unit ~= UNIT_TO_PET[self.unit] then
			return
		end
		if E.spellcast_all[spellID] then
			info:ProcessSpell(spellID)
		end
	elseif event == "UNIT_HEALTH" then
		local unit = ...
		if unit ~= self.unit then
			return
		end







		if not UnitIsDeadOrGhost(unit) then
			if E.preCata then
				local icon = info.spellIcons[20608]
				if icon then
					local mult = info.talentData[16184] and 0.3 or (info.talentData[16209] and 0.4) or 0.2
					if UnitHealth(unit) == floor(UnitHealthMax(unit) * mult) then
						icon:StartCooldown()
					end
				end
			else
				E.Libs.CBH:Fire("OnBattleRezed")
			end

			info.isDead = nil
			info.isDeadOrOffline = not UnitIsConnected(unit)
			info:UpdateColorScheme()
			self:UnregisterEvent(event)
		end
	elseif event == "UNIT_AURA" then
		local unit = ...
		if unit ~= self.unit then
			return
		end

		local icon = info.glowIcons[125174]
		if icon then
			if not P:GetBuffDuration(unit, 125174) then
				icon:RemoveHighlight()
				icon:SetCooldownElements()
				icon:SetOpacity()
				icon:SetColorSaturation()
				self:UnregisterEvent(event)
			end
			return
		end

		icon = info.preactiveIcons[5384]
		if icon then
			if not P:GetBuffDuration(unit, 5384) then
				icon:RemoveHighlight()
				icon:StartCooldown()
				self:UnregisterEvent(event)
			end
			return
		end

		self:UnregisterEvent(event)
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
		local unit = ...
		if unit ~= self.unit then
			return
		end
		if UnitIsConnected(unit) then
			CM:EnqueueInspect(nil, self.guid)
		end
	elseif event == "UNIT_CONNECTION" then


		local unit, isConnected = ...
		if unit ~= self.unit then
			return
		end
		info.isDead = UnitIsDeadOrGhost(unit)
		info.isDeadOrOffline = info.isDead or not isConnected
		info:UpdateColorScheme()

		if isConnected and not info.spec then
			CM:EnqueueInspect(nil, self.guid)
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		local unit, _, spellID = ...
		if unit ~= self.unit then
			return
		end

		if spellID == 391528 then
			self:UnregisterEvent(event)
		end
		C_Timer.After(0.5, function() info.auras.isChannelingConvoke = nil end)
	end
end

function BarFrameMixin:SetUnit(info, unit, index)
	self.unit = unit
	self.key = index
	self.anchor.text:SetText(index)

	if self.isAdminForMDI then
		return
	end
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit, UNIT_TO_PET[unit])
	self:RegisterUnitEvent("UNIT_CONNECTION", unit)
	if E.postMoP and info.guid ~= E.userGUID then
		self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", unit)
	end
	if info.glowIcons[125174] or info.preactiveIcons[5384] then
		self:RegisterUnitEvent("UNIT_AURA", unit)
	end
	if info.isDead then
		self:RegisterUnitEvent("UNIT_HEALTH", unit)
	end
end

function BarFrameMixin:RefreshUnitBarFrames()
	for exBar in P.ExBarPool:EnumerateActive() do
		local unitBar = self.activeUnitBars[exBar.index]
		if unitBar then
			wipe(unitBar.icons)
		elseif exBar.db.unitBar then
			self:GetUnitBarFrame(exBar.index)
		end
	end
end

function BarFrameMixin:GetUnitBarFrame(exBarIndex)
	local unitBar = P.UnitBarPool:Acquire()
	unitBar.index = exBarIndex
	unitBar.bar = self
	self.activeUnitBars[exBarIndex] = unitBar
end

function BarFrameMixin:ReleaseUnitBars()
	for _, unitBar in pairs(self.activeUnitBars) do
		P.UnitBarPool:Release(unitBar)
	end
end

function BarFrameMixin:UpdateUnitBarPosition()
	for _, unitBar in pairs(self.activeUnitBars) do
		unitBar:UpdatePosition()
	end
end

function BarFrameMixin:ReleaseIcons(n)
	n = n or 0
	for i = #self.icons, n + 1, -1 do
		local icon = self.icons[i]
		P.IconPool:Release(icon)
		self.icons[i] = nil
	end
	self.numIcons = n
end

function BarFrameMixin:ReleaseExtraBarIcons()
	local guid = self.guid
	for exBar in P.ExBarPool:EnumerateActive() do
		local icons = exBar.icons
		local n = 0
		local shouldUpdateLayout
		for j = exBar.numIcons, 1, -1 do
			local icon = icons[j]
			local iconGUID = icon.guid
			if guid == iconGUID then
				P.IconPool:Release(icon)
				tremove(icons, j)
				n = n + 1
				shouldUpdateLayout = true
			end
		end
		exBar.numIcons = exBar.numIcons - n
		if shouldUpdateLayout then
			exBar:UpdateLayout()
		end
	end
end

local function SetEffectivePixelMult(relFrame)
	P.effectivePixelMult = E.uiUnitFactor / relFrame:GetEffectiveScale()
	P:UpdatePositionValues()
end

function BarFrameMixin:UpdatePosition()
	self:Hide()

	if E.db.position.detached then
		if self.parent ~= UIParent then
			self:SetParent(UIParent)
			self.parent = UIParent
		end
		E.LoadPosition(self)
		self:Show()
	else
		local relFrame = P:FindRelativeFrame(self.guid, E.db.position.uf)
		if relFrame then
			if E.db.general.showRange then
				if not P.effectivePixelMult then
					SetEffectivePixelMult(relFrame)
				end
				if self.parent ~= relFrame then
					self:SetParent(relFrame)
					self.parent = relFrame
					self:SetFrameLevel(10)
				end
			else
				if self.parent ~= UIParent then
					self:SetParent(UIParent)
					self.parent = UIParent
				end
			end
			self.relativeFrame = relFrame
			self:ClearAllPoints()
			self:SetPoint(P.point, relFrame, P.relativePoint)
			self:Show()
		end
	end

	self:UpdateUnitBarPosition()

	self:SetContainerOffset()
	self:SetAnchorPosition()
end

function BarFrameMixin:UpdatePosition_OnDelayEnd()
	C_Timer.After(0, function() self:UpdatePosition() end)
end

function BarFrameMixin:SetContainerOffset()
	self.container:ClearAllPoints()
	self.container:SetPoint("TOPLEFT", self, P.containerOfsX, P.containerOfsY)
end

function BarFrameMixin:SetAnchorPosition()
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(P.anchorPoint, self, P.point)
end

local sorters
sorters = {
	function(a, b)
		if a.priority == b.priority then
			return a.spellID < b.spellID
		end
		return a.priority > b.priority
	end,
	function(a, b)
		local type1, type2 = E.db.priority[a.type], E.db.priority[b.type]
		if type1 == type2 then
			return sorters[1](a, b)
		end
		return type1 > type2
	end,
}

function BarFrameMixin:UpdateLayout(sortOrder)
	local icons = self.icons
	local displayInactive = P.displayInactive

	local sorter = P.sortBy
	if sortOrder then
		local sortFunc = sorters[sorter]
		sort(icons, sortFunc)
	end

	local db_prio = E.db.priority
	local count, rows, numActive, lastActiveIndex = 0, 1, 1
	for i = 1, self.numIcons do
		local icon = icons[i]
		local iconPrio = sorter == 2 and db_prio[icon.type] or icon.priority
		icon:Hide()

		if (displayInactive or icon.active) and (P.multiline or numActive <= P.maxNumIcons) then
			icon:ClearAllPoints()
			if numActive > 1 then
				count = count + 1
				if not P.multiline and count == P.columns or (P.multiline and
				(rows == 1 and iconPrio <= P.breakPoint or (P.tripleline and rows == 2 and iconPrio <= P.breakPoint2))) then
					if P.tripleline and rows == 1 and iconPrio <= P.breakPoint2 then
						rows = rows + 1
					end
					icon:SetPoint(P.point, self.container, P.ofsX * rows, P.ofsY * rows)
					count = 0
					rows = rows + 1
				else
					icon:SetPoint(P.point2, icons[lastActiveIndex], P.relativePoint2, P.ofsX2, P.ofsY2)
				end
			else
				if P.multiline and iconPrio <= P.breakPoint then
					if P.tripleline and rows == 1 and iconPrio <= P.breakPoint2 then
						rows = rows + 1
					end
					icon:SetPoint(P.point, self.container, P.ofsX * rows, P.ofsY * rows)
					rows = rows + 1
				else
					icon:SetPoint(P.point, self.container)
				end
			end

			numActive = numActive + 1
			lastActiveIndex = i

			if not P.multiline or count < P.maxNumIcons then
				icon:Show()
			end
		end
	end
end

function BarFrameMixin:UpdateSettings()
	self:SetAnchor()
	self:SetContainerSize()

	local isDeadOrOffline = self.info.isDeadOrOffline
	local condition = E.db.highlight.glowBorderCondition

	local numIcons = self.numIcons
	for i = 1, numIcons do
		local icon = self.icons[i]
		icon:SetBorder()
		icon:SetMarker()
		icon:SetOpacity()
		icon:SetColorSaturation()
		icon:SetSwipeCounter()
		icon:SetChargeScale()
		icon:SetTooltip()
		icon:SetBorderGlow(isDeadOrOffline, condition)
	end
end

function BarFrameMixin:SetAnchor()
	local showMovableAnchor = E.db.position.detached and not E.db.position.locked
	if showMovableAnchor or E.db.general.showAnchor and (self.guid ~= E.userGUID or not P.isUserHidden) then
		self.anchor:Show()
	else
		self.anchor:Hide()
	end
	if showMovableAnchor then
		self.anchor:EnableMouse(true)
		self.anchor.background:SetColorTexture(0, 0.8, 0, 1)
	else
		self.anchor:EnableMouse(false)
		self.anchor.background:SetColorTexture(0.756, 0, 0.012, 0.7)
	end
end

function BarFrameMixin:SetContainerSize()
	local scale = P.iconScale
	self.anchor:SetScale(min(max(0.7, scale), 1))
	self.container:SetScale(scale)
end

function BarFrameMixin:SetBarBackdrop()
	local icons = self.icons
	for i = 1, self.numIcons do
		local icon = icons[i]
		icon:SetBorder()
	end
end

function P:UpdatePositionValues()
	local db = E.db.position
	local pixelMult = (E.db.general.showRange and not db.detached) and self.effectivePixelMult or E.PixelMult

	local size = E.BASE_ICON_HEIGHT * E.db.icons.scale
	self.iconScale = (size - size % pixelMult) / E.BASE_ICON_HEIGHT

	local pixel = pixelMult / self.iconScale
	self.pixel = pixel

	local growLeft = strfind(db.anchor, "RIGHT")
	local growX = growLeft and -1 or 1
	local growRowsUpward = db.growUpward
	local growY = growRowsUpward and 1 or -1

	self.point = db.anchor
	self.relativePoint = db.attach
	self.anchorPoint = growLeft and "BOTTOMLEFT" or "BOTTOMRIGHT"
	self.containerOfsX = db.offsetX * growX * pixel
	self.containerOfsY = -(db.offsetY * pixel)
	self.columns = db.columns
	self.multiline = db.layout ~= "vertical" and db.layout ~= "horizontal"
	self.tripleline = db.layout == "tripleRow" or db.layout == "tripleColumn"
	self.sortBy = db.sortBy
	self.breakPoint = self.sortBy == 2 and E.db.priority[db.breakPoint] or db.breakPoint3
	self.breakPoint2 = self.sortBy == 2 and E.db.priority[db.breakPoint2] or db.breakPoint4
	self.displayInactive = db.displayInactive
	self.maxNumIcons = db.maxNumIcons == 0 and 100 or db.maxNumIcons

	if db.layout == "horizontal" or db.layout == "doubleRow" or db.layout == "tripleRow" then
		self.ofsX = 0
		self.ofsY = growY * (E.BASE_ICON_HEIGHT + db.paddingY * pixel)
		self.ofsY2 = 0
		if growLeft then
			self.point2 = "TOPRIGHT"
			self.relativePoint2 = "TOPLEFT"
			self.ofsX2 = -(db.paddingX * pixel)
		else
			self.point2 = "TOPLEFT"
			self.relativePoint2 = "TOPRIGHT"
			self.ofsX2 = db.paddingX * pixel
		end
	else
		self.ofsX = growX * (E.BASE_ICON_HEIGHT + db.paddingX * pixel)
		self.ofsY = 0
		self.ofsX2 = 0
		if growRowsUpward then
			self.point2 = "BOTTOMRIGHT"
			self.relativePoint2 = "TOPRIGHT"
			self.ofsY2 = db.paddingY * pixel
		else
			self.point2 = "TOPRIGHT"
			self.relativePoint2 = "BOTTOMRIGHT"
			self.ofsY2 = -(db.paddingY * pixel)
		end
	end
end

function P:UpdateBars()
	for _, info in pairs(self.groupInfo) do
		info:SetupBar(true)
	end
end

function P:CreateBarFramePool()
	local function initializeFunc(framePool, bar)
		bar.icons = {}
		bar.numIcons = 0
		bar.activeUnitBars = {}
		bar.anchor.text:SetFontObject(E.AnchorFont)
		bar.anchor:SetScript("OnMouseUp", E.OmniCDAnchor_OnMouseUp)
		bar.anchor:SetScript("OnMouseDown", E.OmniCDAnchor_OnMouseDown)
		Mixin(bar, BarFrameMixin)
		bar:SetScript("OnEvent", bar.OnEvent)
	end

	local function resetterFunc(framePool, bar)
		bar:Hide()
		bar:ReleaseUnitBars()
		bar:ReleaseIcons()
		bar:ReleaseExtraBarIcons()
		bar:UnregisterAllEvents()

		bar.info = nil

		if bar.guid == E.userGUID then
			P.userInfo.bar = nil
			CM.CooldownSyncFrame:ReleaseIcons()
		end
	end

	self.BarPool = E:CreateFramePool("Frame", UIParent, "OmniCDTemplate", resetterFunc, initializeFunc)
end

E.UNIT_TO_PET = UNIT_TO_PET
P.sorters = sorters
