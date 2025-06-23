local E = select(2, ...):unpack()
local P = E.Party

local BarFrameIconMixin = {}

local textureUVs = { "borderTop", "borderBottom", "borderRight", "borderLeft" }
function BarFrameIconMixin:HideBorder()
	for _, pieceName in pairs(textureUVs) do
		local region = self[pieceName]
		if region then
			region:Hide()
		end
	end
	self.icon:SetTexCoord(0, 1, 0, 1)
end

function BarFrameIconMixin:SetBorder(settings, edgeSize)
	if self.isUserSyncOnly then
		return
	end

	local db = E.db.icons
	local statusBar = self.statusBar

	if not db.displayBorder and not statusBar then
		self:HideBorder()
		return
	end

	local r, g, b = db.borderColor.r, db.borderColor.g, db.borderColor.b
	edgeSize = edgeSize or P.pixel

	self.borderTop:ClearAllPoints()
	self.borderTop:SetPoint("TOPLEFT", self, "TOPLEFT")
	self.borderTop:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -edgeSize)
	self.borderTop:SetColorTexture(r, g, b)
	self.borderTop:Show()

	self.borderBottom:ClearAllPoints()
	self.borderBottom:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
	self.borderBottom:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, edgeSize)
	self.borderBottom:SetColorTexture(r, g, b)
	self.borderBottom:Show()

	self.borderRight:ClearAllPoints()
	self.borderRight:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -edgeSize)
	self.borderRight:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -edgeSize, edgeSize)
	self.borderRight:SetColorTexture(r, g, b)
	self.borderRight:Show()

	self.borderLeft:ClearAllPoints()
	self.borderLeft:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -edgeSize)
	self.borderLeft:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", edgeSize, edgeSize)
	self.borderLeft:SetColorTexture(r, g, b)
	self.borderLeft:Show()

	self.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	if statusBar then
		statusBar:SetBorder(settings, edgeSize, r, g, b)
	end
end

function BarFrameIconMixin:SetMarker()
	if self.isUserSyncOnly then
		return
	end

	local mark = E.spell_marked[self.spellID]
	if not mark or self.statusBar then
		self.hotKey:Hide()
	elseif mark == true or P.groupInfo[self.guid]:IsTalentForPvpStatus(mark) then
		self.hotKey:Show()
	end
end

function BarFrameIconMixin:SetOpacity()
	if self.isUserSyncOnly then
		return
	end


	local statusBar = self.statusBar
	if self.isHighlighted or (statusBar and not E.db.extraBars[statusBar.key].useIconAlpha) then
		self:SetAlpha(1.0)
	else
		self:SetAlpha(self.active == 0 and E.db.icons.activeAlpha or E.db.icons.inactiveAlpha)
	end
end

function BarFrameIconMixin:SetColorSaturation()
	if self.isUserSyncOnly then
		return
	end

	local info = P.groupInfo[self.guid]
	if info.isDeadOrOffline then
		self.icon:SetVertexColor(0.3, 0.3, 0.3)
		self.icon:SetDesaturated(true)
	elseif self.isHighlighted then
		self.icon:SetVertexColor(1, 1, 1)
		self.icon:SetDesaturated(false)
	else

		local c = info.preactiveIcons[self.spellID] and 0.4 or 1
		self.icon:SetVertexColor(c, c, c)
		self.icon:SetDesaturated(E.db.icons.desaturateActive and self.active == 0)
	end
end

function BarFrameIconMixin:SetSwipeCounter()
	if self.isUserSyncOnly then
		return
	end

	if self.active then
		self:SetCooldownElements()
	end
	local db = E.db.icons
	self.cooldown:SetReverse(db.reverse)
	self.cooldown:SetSwipeColor(0, 0, 0, db.swipeAlpha)
	self.counter:SetScale(db.counterScale)
end

function BarFrameIconMixin:SetChargeScale()
	if self.isUserSyncOnly then
		return
	end
	self.count:SetScale(E.db.icons.chargeScale)
end

function BarFrameIconMixin:SetTooltip()
	if self.isUserSyncOnly then
		return
	end
	self:EnableMouse((not self.SetPassThroughButtons or self.isPassThrough) and (E.db.icons.showTooltip or self.tooltipID))
end

function BarFrameIconMixin:SetBorderGlow(isDeadOrOffline, condition)
	if self.isUserSyncOnly or not self.glowBorder then
		return
	end

	local shouldShow = condition==3 or (condition==1 and self.active~=0) or (condition==2 and self.active==0)
	self.Glow:SetShown(not isDeadOrOffline and shouldShow)
end

function BarFrameIconMixin:SetExIconName(db)
	if db.layout == "vertical" and db.progressBar or not db.showName or db.unitBar then
		self.name:Hide()
	else
		self.name:SetPoint("BOTTOM", 0, db.nameOfsY)
		local nameWithoutRealm = P.groupInfo[self.guid].nameWithoutRealm
		local numChar = db.truncateIconName
		if numChar > 0 then
			nameWithoutRealm = string.utf8sub(nameWithoutRealm, 1, numChar)
		end
		if db.classColor then
			local c = RAID_CLASS_COLORS[self.class]
			if c and c.r then
				self.name:SetTextColor(c.r, c.g, c.b)
			end
		else
			self.name:SetTextColor(1, 1, 1)
		end
		self.name:SetText(nameWithoutRealm)
		self.name:Show()
	end
end


local pendingPassThroughButtons = {}

function P:UpdatePassThroughButtons()
	if #pendingPassThroughButtons == 0 then
		return
	end

	local showTooltip = E.db.icons.showTooltip
	for i = #pendingPassThroughButtons, 1, -1 do
		local icon = pendingPassThroughButtons[i]
		icon:SetPassThroughButtons("LeftButton", "RightButton")
		icon.isPassThrough = true
		if showTooltip then
			icon:EnableMouse(true)
		end
		pendingPassThroughButtons[i] = nil
	end
end

local function OmniCDCooldown_OnHide(self)
	if self:GetCooldownTimes() > 0 then
		return
	end

	local icon = self:GetParent()
	local info = P.groupInfo[icon.guid]

	if not info then
		return
	end

	local spellID = icon.spellID
	local active = info.active[spellID]

	if not active then
		return
	end

	local maxcharges = icon.maxcharges
	local charges = active.charges
	if maxcharges and charges then
		if charges + 1 < maxcharges then
			icon:StartCooldown(icon.duration, true)
			return
		end
		icon.count:SetText(maxcharges)
	end

	info.active[spellID] = nil
	icon.active = nil


	if info.talentData[434249] then
		local auraString = E.controlOfTheDreamIDs[spellID]
		if auraString then
			info.auras[auraString] = GetTime()
		end
	end

	local frame = icon:GetParent():GetParent()
	local key = frame.key
	if type(key) == "number" then
		if not P.displayInactive then
			frame:UpdateLayout()
		end
	else
		if frame.shouldRearrangeInterrupts then
			frame:UpdateLayout(true)
		end
	end

	if icon.isHighlighted then
		icon:RemoveHighlight()
	end
	icon:SetCooldownElements()
	icon:SetOpacity()
	icon:SetColorSaturation()
	icon:SetBorderGlow(info.isDeadOrOffline, E.db.highlight.glowBorderCondition)
	if icon.statusBar then
		icon.statusBar.CastingBar:OnEvent("UNIT_SPELLCAST_STOP")
	end
end

local SpellTooltip = CreateFrame("GameTooltip", "OmniCDSpellTooltip", UIParent, "GameTooltipTemplate")
local TOOLTIP_UPDATE_TIME = 0.2
SpellTooltip.updateTooltipTimer = TOOLTIP_UPDATE_TIME

local function SpellTooltip_OnUpdate(self, elapsed)
	self.updateTooltipTimer = self.updateTooltipTimer - elapsed
	if self.updateTooltipTimer > 0 then
		return
	end
	self.updateTooltipTimer = TOOLTIP_UPDATE_TIME
	local owner = self:GetOwner()
	if owner then
		self:SetSpellByID(owner.tooltipID or owner.spellID)
	end
end
SpellTooltip:SetScript("OnUpdate", SpellTooltip_OnUpdate)

local function OmniCDIcon_OnEnter(self)
	local id = self.tooltipID or self.spellID
	if id then
		SpellTooltip:SetOwner(self, "ANCHOR_RIGHT")
		SpellTooltip:SetSpellByID(id)
	end
end

local function OmniCDIcon_OnLeave()
	SpellTooltip:Hide()
end

E.BASE_ICON_HEIGHT = 36

function P:CreateIconFramePool()
	local function initializeFunc(framePool, icon)
		icon:SetSize(E.BASE_ICON_HEIGHT, E.BASE_ICON_HEIGHT)
		icon.counter = icon.cooldown:GetRegions()
		for _, pieceName in ipairs(textureUVs) do
			local region = icon[pieceName]
			if region then
				region:SetTexelSnappingBias(0.0)
				region:SetSnapToPixelGrid(false)
			end
		end
		icon.icon:SetTexelSnappingBias(0.0)
		icon.icon:SetSnapToPixelGrid(false)

		icon.name:SetFontObject(E.IconFont)
		if E.ElvUI1 then
			E.ElvUI1:RegisterCooldown(icon.cooldown, "OmniCD")
		end
		icon.cooldown:SetScript("OnHide", OmniCDCooldown_OnHide)
		icon:SetScript("OnEnter", OmniCDIcon_OnEnter)
		icon:SetScript("OnLeave", OmniCDIcon_OnLeave)
		if icon.SetPassThroughButtons then
			if self.inLockdown then
				tinsert(pendingPassThroughButtons, icon)
			else
				icon:SetPassThroughButtons("LeftButton", "RightButton")
				icon.isPassThrough = true
			end
		end
		Mixin(icon, BarFrameIconMixin)
	end

	local function resetterFunc(framePool, icon)
		local statusBar = icon.statusBar
		if statusBar then
			self.StatusBarPool:Release(statusBar)
			icon.statusBar = nil
		end
		icon:HideOverlayGlow()
		icon:Hide()
	end

	self.IconPool = E:CreateFramePool("Button", UIParent, "OmniCDButtonTemplate", resetterFunc, initializeFunc)
end

P.BarFrameIconMixin = BarFrameIconMixin
