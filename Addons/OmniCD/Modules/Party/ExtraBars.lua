local E, L = select(2, ...):unpack()
local P = E.Party

local select, strsub, tonumber = select, strsub, tonumber
local GetRaidRosterInfo, UnitGroupRolesAssigned, UnitInRaid = GetRaidRosterInfo, UnitGroupRolesAssigned, UnitInRaid

local extraBarKeys = {
	"raidBar1",
	"raidBar2",
	"raidBar3",
	"raidBar4",
	"raidBar5",
	"raidBar6",
	"raidBar7",
	"raidBar8",
}

local ExtraBarFrameMixin = {}
local activeExBars = {}

function ExtraBarFrameMixin:ReleaseUnitBars()
	for bar in P.BarPool:EnumerateActive() do
		local unitBar = bar.activeUnitBars[self.index]
		if unitBar then
			P.UnitBarPool:Release(unitBar)
		end
	end
end

function ExtraBarFrameMixin:ReleaseIcons()
	for i = self.numIcons, 1, -1 do
		local icon = self.icons[i]
		P.IconPool:Release(icon)
		self.icons[i] = nil
	end
	self.numIcons = 0
end

function ExtraBarFrameMixin:UpdatePosition()
	if not self.db.unitBar then
		E.LoadPosition(self)
	end
end

local roleValues = { MAINTANK = 1, MAINASSIST = 2, TANK = 3, HEALER = 4, DAMAGER = 5, NONE = 6 }
local sorters
sorters = {

	function(a, b)
		if a.duration == b.duration then
			return a.unitName < b.unitName
		end
		return a.duration < b.duration
	end,

	function(a, b)
		local info1, info2 = P.groupInfo[a.guid], P.groupInfo[b.guid]
		if info1.isDeadOrOffline == info2.isDeadOrOffline then
			local active1, active2 = a.active == 0 and info1.active[a.spellID], b.active == 0 and info2.active[b.spellID]
			if active1 and active2 then
				return a.duration + active1.startTime < b.duration + active2.startTime
			elseif not active1 and not active2 then
				return sorters[1](a, b)
			end
			return active2
		end
		return info2.isDeadOrOffline
	end,

	function(a, b)
		if a.priority == b.priority then
			if a.class == b.class then
				if a.spellID == b.spellID then
					return a.unitName < b.unitName
				end
				return a.spellID < b.spellID
			end
			return a.class < b.class
		end
		return a.priority > b.priority
	end,

	function(a, b)
		if a.class == b.class then
			if a.priority == b.priority then
				if a.spellID == b.spellID then
					return a.unitName < b.unitName
				end
				return a.spellID < b.spellID
			end
			return a.priority > b.priority
		end
		return a.class < b.class
	end,

	function(a, b)
		local token1, token2 = a.unit, b.unit
		if ( token1 == token2 ) then
			if ( a.priority == b.priority ) then
				return a.spellID < b.spellID
			end
			return a.priority > b.priority
		end

		local id1, id2 = UnitInRaid(token1), UnitInRaid(token2);
		local role1, role2
		if ( id1 ) then
			role1 = select(10, GetRaidRosterInfo(id1));
		end
		if ( id2 ) then
			role2 = select(10, GetRaidRosterInfo(id2));
		end

		role1 = role1 or UnitGroupRolesAssigned(token1);
		role2 = role2 or UnitGroupRolesAssigned(token2);

		local value1, value2 = roleValues[role1], roleValues[role2];
		if ( value1 ~= value2 ) then
			return value1 < value2
		end


		return a.unitName < b.unitName
	end,

	function(a, b)
		if ( a.unit == b.unit ) then
			if ( a.priority == b.priority ) then
				return a.spellID < b.spellID
			end
			return a.priority > b.priority
		end

		if a.class == b.class then
			return a.unitName < b.unitName
		end
		return a.class < b.class
	end,

	function(a, b)
		local info1, info2 = P.groupInfo[a.guid], P.groupInfo[b.guid]
		if info1.isDeadOrOffline == info2.isDeadOrOffline then
			local active1, active2 = a.active == 0 and info1.active[a.spellID], b.active == 0 and info2.active[b.spellID]
			if active1 and active2 then
				return a.duration + active1.startTime < b.duration + active2.startTime
			elseif not active1 and not active2 then
				return sorters[5](a, b)
			end
			return active2
		end
		return info2.isDeadOrOffline
	end,

	function(a, b)
		local info1, info2 = P.groupInfo[a.guid], P.groupInfo[b.guid]
		if info1.isDeadOrOffline == info2.isDeadOrOffline then
			local active1, active2 = a.active == 0 and info1.active[a.spellID], b.active == 0 and info2.active[b.spellID]
			if active1 and active2 then
				return a.duration + active1.startTime < b.duration + active2.startTime
			elseif not active1 and not active2 then
				return sorters[6](a, b)
			end
			return active2
		end
		return info2.isDeadOrOffline
	end,

	function(a, b)
		local info1, info2 = P.groupInfo[a.guid], P.groupInfo[b.guid]
		if info1.isDeadOrOffline == info2.isDeadOrOffline then
			local id1, id2 = a.spellID, b.spellID
			local active1, active2 = a.active == 0 and info1.active[id1], b.active == 0 and info2.active[id2]
			if active1 and active2 then
				return a.duration + active1.startTime < b.duration + active2.startTime
			elseif not active1 and not active2 then
				if a.priority == b.priority then
					if a.class == b.class then
						if id1 == id2 then
							return a.unitName < b.unitName
						end
						return id1 < id2
					end
					return a.class < b.class
				end
				return a.priority > b.priority
			end
			return active2
		end
		return info2.isDeadOrOffline
	end,

	function(a, b)
		local info1, info2 = P.groupInfo[a.guid], P.groupInfo[b.guid]
		if info1.isDeadOrOffline == info2.isDeadOrOffline then
			local id1, id2 = a.spellID, b.spellID
			local active1, active2 = a.active == 0 and info1.active[id1], b.active == 0 and info2.active[id2]
			if active1 and active2 then
				return a.duration + active1.startTime < b.duration + active2.startTime
			elseif not active1 and not active2 then
				if a.class == b.class then
					if a.priority == b.priority then
						if id1 == id2 then
							return a.unitName < b.unitName
						end
						return id1 < id2
					end
					return a.priority > b.priority
				end
				return a.class < b.class
			end
			return active2
		end
		return info2.isDeadOrOffline
	end,

	function(a, b)
		local token1, token2 = a.unit, b.unit
		if ( token1 == token2 ) then
			if ( a.priority == b.priority ) then
				return a.spellID < b.spellID
			end
			return a.priority > b.priority
		end

		if ( IsInRaid() ) then
			local id1 = tonumber(string.sub(token1, 5));
			local id2 = tonumber(string.sub(token2, 5));

			if ( not id1 or not id2 ) then
				return id1
			end

			local _, _, subgroup1 = GetRaidRosterInfo(id1);
			local _, _, subgroup2 = GetRaidRosterInfo(id2);

			if ( subgroup1 and subgroup2 and subgroup1 ~= subgroup2 ) then
				return subgroup1 < subgroup2
			end


			return id1 < id2
		else
			if ( token1 == "player" ) then
				return true
			elseif ( token2 == "player" ) then
				return false
			else
				return token1 < token2
			end
		end
	end,

	function(a, b)
		if ( a.unit == b.unit ) then
			if ( a.priority == b.priority ) then
				return a.spellID < b.spellID
			end
			return a.priority > b.priority
		end
		return a.unitName < b.unitName
	end,

	function(a, b)
		local info1, info2 = P.groupInfo[a.guid], P.groupInfo[b.guid]
		if info1.isDeadOrOffline == info2.isDeadOrOffline then
			local active1, active2 = a.active == 0 and info1.active[a.spellID], b.active == 0 and info2.active[b.spellID]
			if active1 and active2 then
				return a.duration + active1.startTime < b.duration + active2.startTime
			elseif not active1 and not active2 then
				return sorters[11](a, b)
			end
			return active2
		end
		return info2.isDeadOrOffline
	end,

	function(a, b)
		local info1, info2 = P.groupInfo[a.guid], P.groupInfo[b.guid]
		if info1.isDeadOrOffline == info2.isDeadOrOffline then
			local active1, active2 = a.active == 0 and info1.active[a.spellID], b.active == 0 and info2.active[b.spellID]
			if active1 and active2 then
				return a.duration + active1.startTime < b.duration + active2.startTime
			elseif not active1 and not active2 then
				return sorters[12](a, b)
			end
			return active2
		end
		return info2.isDeadOrOffline
	end,

	function(a, b)
		if a.priority == b.priority then
			return a.unitName < b.unitName
		end
		return a.priority > b.priority
	end,

	function(a, b)
		local info1, info2 = P.groupInfo[a.guid], P.groupInfo[b.guid]
		if info1.isDeadOrOffline == info2.isDeadOrOffline then
			local id1, id2 = a.spellID, b.spellID
			local active1, active2 = a.active == 0 and info1.active[id1], b.active == 0 and info2.active[id2]
			if active1 and active2 then
				return a.duration + active1.startTime < b.duration + active2.startTime
			elseif not active1 and not active2 then
				return sorters[15](a, b)
			end
			return active2
		end
		return info2.isDeadOrOffline
	end,
}

local Sorter

local ReverseSorter = function(a, b)
	return Sorter(b, a)
end

function ExtraBarFrameMixin:UpdateLayout(sortOrder, updateIcons)

	if updateIcons then
		local n = 0
		for i = self.numIcons, 1, -1 do
			local icons = self.icons
			local icon = icons[i]
			local info = P.groupInfo[icon.guid]
			local spellIcon = info and info.spellIcons[icon.spellID]
			if icon ~= spellIcon then
				P.IconPool:Release(icon)
				tremove(icons, i)
				n = n + 1
			end
		end
		self.numIcons = self.numIcons - n
	end

	if self.numIcons == 0 then
		return
	end

	local db = self.db
	if db.unitBar then
		for bar in P.BarPool:EnumerateActive() do
			local unitBar = bar.activeUnitBars[self.index]
			if unitBar then
				unitBar:UpdateLayout(sortOrder)
				unitBar:Show()
			end
		end
	else
		if sortOrder then
			Sorter = sorters[db.sortBy]
			local sortFunc = db.sortDirection == "dsc" and ReverseSorter or Sorter
			sort(self.icons, sortFunc)
		end

		local count, rows = 0, 1
		local columns = db.columns
		for i = 1, self.numIcons do
			local icon = self.icons[i]
			icon:Hide()
			icon:ClearAllPoints()
			if i > 1 then
				count = count + 1
				if count == columns then
					icon:SetPoint(self.point, self.container, self.ofsX * rows, self.ofsY * rows)
					rows = rows + 1
					count = 0
				else
					icon:SetPoint(self.point2, self.icons[i-1], self.relativePoint2, self.ofsX2, self.ofsY2)
				end
			else
				icon:SetPoint(self.point, self.container)
			end
			icon:Show()
		end
	end
end

function ExtraBarFrameMixin:UpdateSettings()
	self:SetAnchor()
	self:SetContainerSize()

	local db = self.db
	local pixel = self.pixel

	local numIcons = self.numIcons
	for i = 1, numIcons do

		local icon = self.icons[i]
		icon:SetBorder(db, pixel)
		icon:SetExIconName(db)
		local statusBar = icon.statusBar
		if statusBar then
			statusBar:UpdateSettings(db)
		end

		icon:SetMarker()
		icon:SetOpacity()
		icon:SetColorSaturation()
		icon:SetSwipeCounter()
		icon:SetChargeScale()
		icon:SetTooltip()
	end
end

function ExtraBarFrameMixin:SetAnchor()
	local anchor = self.anchor
	local db = self.db

	if db.locked or db.unitBar then
		anchor:Hide()
	else
		anchor:ClearAllPoints()
		anchor:SetPoint(self.anchorPoint, self, self.point, 0, self.anchorOfsY)
		if self.shouldShowProgressBar then
			anchor:SetWidth((E.BASE_ICON_HEIGHT + db.statusBarWidth) * self.iconScale)
		else
			local width = math.max(anchor.text:GetWidth() + 20, E.BASE_ICON_HEIGHT * self.iconScale)
			anchor:SetWidth(width)
		end
		anchor.text:SetText(db.name or (self.index == 1 and L["Interrupts"] or self.index))
		anchor:Show()
	end
end

function ExtraBarFrameMixin:SetContainerSize()
	if self.db.unitBar then
		for bar in P.BarPool:EnumerateActive() do
			local unitBar = bar.activeUnitBars[self.index]
			if unitBar then
				unitBar:SetScale(self.iconScale)
			end
		end
	else
		self.container:SetScale(self.iconScale)
	end
end

function ExtraBarFrameMixin:UpdatePositionValues()
	local db = self.db
	local isUnitBar = db.unitBar
	local pixelMult = isUnitBar and E.db.general.showRange and self.effectivePixelMult or E.PixelMult

	local size = E.BASE_ICON_HEIGHT * db.scale
	self.iconScale = (size - size % pixelMult) / E.BASE_ICON_HEIGHT

	local pixel = pixelMult / self.iconScale
	self.pixel = pixel

	local growLeft = isUnitBar and strfind(db.anchor, "RIGHT") or db.growLeft
	local growX = growLeft and -1 or 1
	local growRowsUpward = db.growUpward
	local growY = growRowsUpward and 1 or -1
	local isProgressBarEnabled = db.enabled and not isUnitBar and db.progressBar

	self.point = isUnitBar and db.anchor or "TOPLEFT"
	self.relativePoint = db.attach
	self.containerOfsX = db.offsetX * growX * pixel
	self.containerOfsY = db.offsetY * pixel
	self.anchorPoint = "BOTTOMLEFT"
	self.anchorOfsY = growRowsUpward and -(E.BASE_ICON_HEIGHT * self.iconScale + 15) or 0

	if db.layout == "horizontal" then
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
		self.shouldShowProgressBar = nil
	else
		self.ofsX = growX * (E.BASE_ICON_HEIGHT + (db.paddingX * pixel) + (isProgressBarEnabled and db.statusBarWidth or 0))
		self.ofsY = 0
		self.ofsX2 = 0
		if growRowsUpward then
			self.point2 = "BOTTOMLEFT"
			self.relativePoint2 = "TOPLEFT"
			self.ofsY2 = db.paddingY * pixel
		else
			self.point2 = "TOPLEFT"
			self.relativePoint2 = "BOTTOMLEFT"
			self.ofsY2 = -(db.paddingY * pixel)
		end
		self.shouldShowProgressBar = isProgressBarEnabled
	end

	local sortBy = db.sortBy
	self.shouldRearrangeInterrupts = not isUnitBar and db.enabled and (sortBy == 2 or sortBy >= 7)
end

function ExtraBarFrameMixin:UpdateExBarBackdrop()
	local icons = self.icons
	local db = self.db
	local pixel = self.pixel
	for i = 1, self.numIcons do
		local icon = icons[i]
		icon:SetBorder(db, pixel)
	end
end

function ExtraBarFrameMixin:SetUnitBarOffset()
	for bar in P.BarPool:EnumerateActive() do
		local unitBar = bar.activeUnitBars[self.index]
		if unitBar then
			local point, relativeTo, relativePoint, offsetX, offsetY = unitBar:GetPoint()
			unitBar:ClearAllPoints()
			unitBar:SetPoint(point, relativeTo, relativePoint, self.containerOfsX, self.containerOfsY)
		end
	end
end

function P:RearrangeExBarIcons()
	for exBar in self.ExBarPool:EnumerateActive() do
		if exBar.shouldRearrangeInterrupts then
			exBar:UpdateLayout(true)
		end
	end
end

function P:UpdateExBars()

	for exBar in self.ExBarPool:EnumerateActive() do
		exBar:UpdatePosition()
		exBar:UpdateLayout(true, true)
		exBar:UpdateSettings()
		exBar:Show()
	end
end

function P:ReleaseExBarIcons()
	for exBar in self.ExBarPool:EnumerateActive() do
		exBar:ReleaseIcons()
	end
end

function P:CreateExBarFramePool()
	local function initializeFunc(framePool, exBar)
		exBar.icons = {}
		exBar.numIcons = 0
		exBar.anchor.text:SetFontObject(E.AnchorFont)
		exBar.anchor.text:SetTextColor(1, 0.824, 0)
		exBar.anchor.background:SetColorTexture(0, 0, 0, 1)
		exBar.anchor.background:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 1), CreateColor(1, 1, 1, .05))

		exBar.anchor:SetScript("OnMouseUp", E.OmniCDAnchor_OnMouseUp)
		exBar.anchor:SetScript("OnMouseDown", E.OmniCDAnchor_OnMouseDown)
		Mixin(exBar, ExtraBarFrameMixin)
	end

	local function resetterFunc(framePool, exBar)
		exBar:Hide()
		exBar:ReleaseIcons()
		exBar:ReleaseUnitBars()
		activeExBars[exBar.key] = nil
	end

	self.ExBarPool = E:CreateFramePool("Frame", UIParent, "OmniCDTemplate", resetterFunc, initializeFunc)
end

local function GetExBarFrame(key)
	local exBar = P.ExBarPool:Acquire()
	local exBarIndex = tonumber(strsub(key, 8))
	exBar.index = exBarIndex
	exBar.key = key
	exBar.anchor.text:SetText(exBarIndex == 1 and L["Interrupts"] or exBarIndex)
	exBar.anchor.text:SetTextColor(1, 0.824, 0)

	activeExBars[key] = exBar
	return exBar
end

function P:RefreshExBarFrames()
	for key, db in pairs(E.db.extraBars) do
		local exBar = activeExBars[key]
		if db.enabled then
			if exBar then
				exBar:ReleaseIcons()
			else
				exBar = GetExBarFrame(key)
			end
			exBar.db = E.db.extraBars[key]
			exBar.effectivePixelMult = nil
			--[[ We're not going to remember not to use cached values in SetupBar

			if not db.unitBar or not E.db.general.showRange then
				exBar:UpdatePositionValues()
			end
			]]
			exBar:UpdatePositionValues()
		else
			if exBar then
				self.ExBarPool:Release(exBar)
			end
		end
	end
end

local UnitBarFrameMixin = {}

function UnitBarFrameMixin:UpdatePosition()
	self:Hide()
	local exKey = P.extraBarKeys[self.index]
	local exBar = activeExBars[exKey]
	local relFrame = (exBar.db.uf == "auto" or exBar.db.uf == E.db.position.uf) and self.bar.relativeFrame
		or P:FindRelativeFrame(self.bar.guid, exBar.db.uf)
	if relFrame then
		if E.db.general.showRange then
			if not exBar.effectivePixelMult then
				exBar.effectivePixelMult = E.uiUnitFactor / relFrame:GetEffectiveScale()
				exBar:UpdatePositionValues()
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
		self:ClearAllPoints()
		self:SetPoint(exBar.point, relFrame, exBar.relativePoint, exBar.containerOfsX, exBar.containerOfsY)
		self:Show()
	end
end

function UnitBarFrameMixin:UpdateLayout(sortOrder)
	local icons = self.icons
	if sortOrder then
		sort(icons, P.sorters[P.sortBy])
	end

	local exKey = P.extraBarKeys[self.index]
	local exBar = activeExBars[exKey]
	local count, rows = 0, 1
	local columns = exBar.db.columns
	for i = 1, #icons do
		local icon = icons[i]
		icon:Hide()
		icon:ClearAllPoints()
		if i > 1 then
			count = count + 1
			if count == columns then
				icon:SetPoint(exBar.point, self, exBar.ofsX * rows, exBar.ofsY * rows)
				rows = rows + 1
				count = 0
			else
				icon:SetPoint(exBar.point2, icons[i-1], exBar.relativePoint2, exBar.ofsX2, exBar.ofsY2)
			end
		else
			icon:SetPoint(exBar.point, self)
		end
		icon:Show()
	end
end

function P:CreateUnitBarFramePool()
	local function initializeFunc(framePool, unitBar)
		unitBar:SetSize(1, 1)
		unitBar:Hide()
		unitBar.icons = {}
		Mixin(unitBar, UnitBarFrameMixin)
	end

	local function resetterFunc(framePool, unitBar)
		unitBar:Hide()
		wipe(unitBar.icons)
		unitBar.bar.activeUnitBars[unitBar.index] = nil
	end

	self.UnitBarPool = E:CreateFramePool("Frame", UIParent, nil, resetterFunc, initializeFunc)
end

P.extraBarKeys = extraBarKeys
P.activeExBars = activeExBars
