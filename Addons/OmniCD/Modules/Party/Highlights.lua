local E = select(2, ...):unpack()
local P = E.Party
local BarFrameIconMixin = P.BarFrameIconMixin

local unusedOverlayGlows = {}

local OverlayGlowFrameMixin = {}

function OverlayGlowFrameMixin:Release()
	self:Hide()
	unusedOverlayGlows[#unusedOverlayGlows + 1] = self
end

local function OverlayGlow_AnimOutFinished(animGroup)
	local overlay = animGroup:GetParent()
	local icon = overlay:GetParent()
	overlay:Release()
	icon.overlay = nil
end

local function OverlayGlow_OnHide(self)
	if not self.animOut:IsPlaying() then
		return
	end
	self.animOut:Stop()
	OverlayGlow_AnimOutFinished(self.animOut)
end

local function AcquireOverlayGlow()
	local overlay = tremove(unusedOverlayGlows)
	if not overlay then
		overlay = CreateFrame("Frame", nil, UIParent, "OmniCDButtonSpellActivationAlert")
		overlay.animOut:SetScript("OnFinished", OverlayGlow_AnimOutFinished)
		overlay:SetScript("OnHide", OverlayGlow_OnHide)
		Mixin(overlay, OverlayGlowFrameMixin)
	end
	return overlay
end

function OverlayGlowFrameMixin:ShowOverlayGlowNoAnim()
	local frameWidth, frameHeight = self:GetSize()
	self.spark:SetSize(frameWidth, frameHeight)
	self.spark:SetAlpha(0)
	self.innerGlow:SetSize(frameWidth, frameHeight)
	self.innerGlow:SetAlpha(0)
	self.innerGlowOver:SetAlpha(0)
	self.outerGlow:SetSize(frameWidth, frameHeight)
	self.outerGlow:SetAlpha(1.0)
	self.outerGlowOver:SetAlpha(0)
	self.ants:SetSize(frameWidth * 0.85, frameHeight * 0.85)
	self.ants:SetAlpha(1.0)
	self:Show()
end

local RemoveHighlight_OnTimerEnd
RemoveHighlight_OnTimerEnd = function(icon)
	local info = P.groupInfo[icon.guid]
	if not info or not icon.isHighlighted then
		return
	end


	local duration, expTime = P:GetBuffDuration(info.unit, icon.buff)
	if duration and duration > 0 then
		duration = expTime - GetTime()
		if duration > 0 then
			icon.isHighlighted = C_Timer.NewTimer(duration + 0.1, function() RemoveHighlight_OnTimerEnd(icon) end)
			return
		end
	end
	icon:RemoveHighlight()
	icon:SetCooldownElements()
	icon:SetOpacity()
	icon:SetColorSaturation()
end

function BarFrameIconMixin:ShowOverlayGlow(duration, isRefresh)
	if E.db.highlight.glowType == "wardrobe" then
		if not self.isHighlighted then
			self.PendingFrame:Show()
			if not isRefresh then
				self.AnimFrame.animIn:Play()
			end
		end
	elseif self.overlay then
		if self.overlay.animOut:IsPlaying() then
			self.overlay.animOut:Stop()
			if isRefresh then
				self.overlay:ShowOverlayGlowNoAnim()
			else
				self.overlay.animIn:Play()
			end
		end
	else
		self.overlay = AcquireOverlayGlow()
		local frameWidth, frameHeight = self:GetSize()
		self.overlay:SetParent(self)
		self.overlay.parent = self
		self.overlay:ClearAllPoints()
		self.overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4)
		self.overlay:SetPoint("TOPLEFT", self, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2)
		self.overlay:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2)
		if isRefresh then
			self.overlay:ShowOverlayGlowNoAnim()
		else
			self.overlay.animIn:Play()
		end
	end

	if type(self.isHighlighted) == "userdata" then
		self.isHighlighted:Cancel()
	end

	self.isHighlighted = C_Timer.NewTimer(duration + 0.1, function() RemoveHighlight_OnTimerEnd(self) end)
end

function BarFrameIconMixin:HideOverlayGlow()
	if self.overlay then
		if self.overlay.animIn:IsPlaying() then
			self.overlay.animIn:Stop()
		end

		if self:IsVisible() then
			self.overlay.animOut:Play()
		else
			OverlayGlow_AnimOutFinished(self.overlay.animOut)
		end
	elseif self.isHighlighted then
		self.PendingFrame:Hide()
		if self:IsVisible() then
			self.AnimFrame.animOut:Play()
		else
			self.AnimFrame:Hide()
		end
	end

	if type(self.isHighlighted) == "userdata" then
		self.isHighlighted:Cancel()
	end

	self.isHighlighted = nil
end

function BarFrameIconMixin:RemoveHighlight()
	local info = P.groupInfo[self.guid]
	if not info or not info.glowIcons[self.buff] then
		return
	end
	info.glowIcons[self.buff] = nil
	self:HideOverlayGlow()
end

function BarFrameIconMixin:SetHighlight(isRefresh)
	if not E.db.highlight.glowBuffs or not E.db.highlight.glowBuffTypes[self.type] or self.isUserSyncOnly then
		return
	end

	local buff = self.buff
	if buff == 0 or not E.spell_highlighted[buff] then
		return
	end

	local info = P.groupInfo[self.guid]
	if not info then
		return
	end

	local spellID = self.spellID
	local duration, expTime = E.summonedBuffDuration[spellID]

	if duration then

		local active = info.active[spellID]
		if active then
			duration = duration - GetTime() + active.startTime
		end
	else
		duration, expTime = P:GetBuffDuration(info.unit, buff)
		if duration and duration > 0 then
			duration = expTime - GetTime()
		end
	end
	if duration and duration > 0 then
		if E.buffFixNoCLEU[buff] and (not E.isBFA or not P.isInArena) then
			info.bar:RegisterUnitEvent("UNIT_AURA", info.unit)
		end

		self:ShowOverlayGlow(duration, isRefresh)
		info.glowIcons[buff] = self
		return true
	end
end

function BarFrameIconMixin:SetGlow()
	self.AnimFrame.animIn:Play()
end
