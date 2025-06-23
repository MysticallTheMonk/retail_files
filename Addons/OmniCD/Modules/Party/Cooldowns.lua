local E = select(2, ...):unpack()
local P = E.Party
local BarFrameIconMixin = P.BarFrameIconMixin

function BarFrameIconMixin:SetCooldownElements()
	if self.isUserSyncOnly then
		return
	end

	local noSwipe = self.isHighlighted or self.active ~= 0 or (self.statusBar and not E.db.extraBars[self.statusBar.key].nameBar)
	local noCount = noSwipe or not E.db.icons.showCounter
	self.cooldown:SetDrawEdge(not self.isHighlighted and self.maxcharges)
	self.cooldown:SetDrawSwipe(not noSwipe)
	self.cooldown:SetHideCountdownNumbers(noCount)

	if E.OmniCC then
		E.OmniCC.Cooldown.SetNoCooldownCount(self.cooldown, noCount)
	elseif self.cooldown.timer then
		self.cooldown.timer:SetShown(not noCount)
		self.cooldown.timer.forceDisabled = noCount
	end
end

function BarFrameIconMixin:ResetCooldown(resetAllCharges)
	local info = P.groupInfo[self.guid]
	if not info then
		return
	end

	local active = info.active[self.spellID]
	if not active then
		return
	end


	if (self.spellID == 45438 or self.spellID == 414658) and E.db.icons.showForbearanceCounter then
		local duration, expTime = P:GetDebuffDuration(info.unit, 41425)
		if duration and duration > 0 then
			duration = expTime - GetTime()
			if duration > 0 then
				self:StartCooldown(duration, nil, true)
			end
			return
		end
	end


	local maxcharges = self.maxcharges
	local currCharges = active.charges
	local statusBar = self.statusBar
	if maxcharges and currCharges and currCharges + 1 < maxcharges then
		if resetAllCharges then
			active.charges = maxcharges
			self.cooldown:Clear()
			if statusBar then

				statusBar.CastingBar:OnEvent("UNIT_SPELLCAST_FAILED")
			end
			return
		end

		currCharges = currCharges + 1
		active.charges = currCharges
		self.count:SetText(currCharges)
		self.active = currCharges

		if self.isUserSyncOnly then
			return
		end

		self:SetCooldownElements()
		self:SetOpacity()
		self:SetColorSaturation()
		self:SetBorderGlow(info.isDeadOrOffline, E.db.highlight.glowBorderCondition)
		if statusBar then
			statusBar:SetColors()
		end
	else
		self.cooldown:Clear()
		if statusBar then
			statusBar.CastingBar:OnEvent("UNIT_SPELLCAST_FAILED")
		end
	end
end

function BarFrameIconMixin:UpdateCooldown(reducedTime, updateActiveTimer)
	local info = P.groupInfo[self.guid]
	if not info then
		return
	end

	local active = info.active[self.spellID]
	if not active then
		return
	end

	local startTime = active.startTime
	local duration = active.duration
	local modRate = active.modRate or 1
	local now = GetTime()





	reducedTime = reducedTime * modRate



	if updateActiveTimer then
		local elapsed = (now - startTime) * updateActiveTimer
		startTime = now - elapsed
		duration = duration * updateActiveTimer

	end

	startTime = startTime - reducedTime

	if active.charges then
		local queuedCdrOnRecharge = now - startTime - duration
		if queuedCdrOnRecharge > 0 and active.charges + 1 < self.maxcharges then
			active.queuedCdrOnRecharge = queuedCdrOnRecharge
		end
	end

	self.cooldown:SetCooldown(startTime, duration, modRate)
	active.startTime = startTime
	active.duration = duration
	local statusBar = self.statusBar
	if statusBar then
		statusBar.CastingBar:OnEvent(statusBar.CastingBar.channeling and "UNIT_SPELLCAST_CHANNEL_UPDATE" or "UNIT_SPELLCAST_CAST_UPDATE")
	end
end

function BarFrameIconMixin:StartCooldown(cd, isRecharge, noGlow, reducedStartTime)
	local info = P.groupInfo[self.guid]
	if not info then
		return
	end

	local spellID = self.spellID



	local multiplier
	local auraMult = E.spell_cdmod_by_aura_mult[spellID]
	if auraMult then
		for i = 1, #auraMult, 2 do
			local auraString = auraMult[i + 1]
			if info.auras[auraString] then
				local mult = auraMult[i]
				if mult == 0 and not isRecharge then
					if self.active and info.auras.mult_premonitionOfInsight then
						self:UpdateCooldown(info.talentData[440743] and 9.8 or 7)
					end
					return
				end
				multiplier = (multiplier or 1) * mult
			end
		end
	end


	cd = cd or self.duration
	local ocd = cd
	local reduceStartTimeInstead
	if not isRecharge and self.isBookType then
		if info.auras.glimpseOfClarity then
			cd = cd - 3
		end
		if spellID ~= 428933 and info.auras.mult_premonitionOfInsight then
			reduceStartTimeInstead = true
			cd = cd - (info.talentData[440743] and 9.8 or 7)
		end
	end


	if multiplier then
		cd = cd * multiplier
	end

	if E.spell_cdmod_by_haste[spellID] and info.auras.mult_lust then
		cd = cd * 0.7
	end


	local modRate = self.modRate
	cd = cd * modRate

	info.active[spellID] = info.active[spellID] or {}
	local active = info.active[spellID]
	local currCharges = active.charges or self.maxcharges
	local now = GetTime()
	if reducedStartTime then
		reducedStartTime = reducedStartTime * modRate
		now = now - reducedStartTime
	end










	if currCharges then
		if isRecharge then
			if active.queuedCdrOnRecharge then
				now = now - active.queuedCdrOnRecharge
				active.queuedCdrOnRecharge = nil
			end
			currCharges = currCharges + 1
			self.cooldown:SetCooldown(now, cd, modRate)
		elseif currCharges == self.maxcharges then
			currCharges = currCharges - 1
			if reduceStartTimeInstead then
				now = now - (ocd - cd)
				cd = ocd * modRate
			end
			self.cooldown:SetCooldown(now, cd, modRate)
		elseif currCharges == 0 then
			self.cooldown:SetCooldown(now, cd, modRate)
		else
			if reduceStartTimeInstead then
				local rt = active.duration - cd
				local remainingTime = active.startTime + active.duration - now - rt
				if remainingTime < 0 then
					now = now + remainingTime
				else
					currCharges = currCharges - 1
					now = active.startTime - rt
				end
				cd = active.duration
				self.cooldown:SetCooldown(now, cd, modRate)
			else
				currCharges = currCharges - 1
				now = active.startTime
				cd = active.duration
			end
		end
		self.count:SetText(currCharges)
		active.charges = currCharges
	else
		if reduceStartTimeInstead then
			now = now - (ocd - cd)
			cd = ocd * modRate
		end
		self.cooldown:SetCooldown(now, cd, modRate)
	end
	active.startTime = now
	active.duration = cd
	active.modRate = modRate
	if E.selfLimitedMinMaxReducer[spellID] then
		active.numHits = 0
	end

	local statusBar = self.statusBar
	if info.preactiveIcons[spellID] then
		info.preactiveIcons[spellID] = nil

		if statusBar then
			statusBar:SetColors()
		end
	end

	self.active = currCharges or 0

	if self.isUserSyncOnly then
		return
	end

	local frame = self:GetParent():GetParent()
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

	if not self:SetHighlight() and not isRecharge and not noGlow and E.db.highlight.glow then
		self:SetGlow()
	end
	self:SetCooldownElements()
	self:SetOpacity()
	self:SetColorSaturation()
	self:SetBorderGlow(info.isDeadOrOffline, E.db.highlight.glowBorderCondition)
	if statusBar then
		statusBar.CastingBar:OnEvent(E.db.extraBars[key].reverseFill and "UNIT_SPELLCAST_CHANNEL_START" or "UNIT_SPELLCAST_START")
	end
end

local MIN_RESET_DURATION = ((E.isWOTLKC or E.isCata) or E.TocVersion > 90100) and 120 or 180
function P:ResetAllIcons(reason, clearSession)
	local notEncounterEnd = reason ~= "encounterEnd"
	for guid, info in pairs(self.groupInfo) do
		local isDeadOrOffline = info.isDeadOrOffline
		local condition = E.db.highlight.glowBorderCondition
		for spellID, icon in pairs(info.spellIcons) do
			if notEncounterEnd or not E.spell_noreset_onencounterend[spellID] and icon.baseCooldown >= MIN_RESET_DURATION then
				local statusBar = icon.statusBar
				if icon.active then
					info.active[spellID] = nil
					icon.active = nil
					icon.cooldown:Clear()
					if icon.maxcharges then
						icon.count:SetText(icon.maxcharges)
					end
					if statusBar then
						statusBar.CastingBar:OnEvent("UNIT_SPELLCAST_FAILED")
					end
				end

				if info.preactiveIcons[spellID] then
					info.preactiveIcons[spellID] = nil
					if statusBar then
						statusBar:SetColors()
					end
				end

				if icon.isHighlighted then
					icon:RemoveHighlight()
				end
				icon:SetCooldownElements()
				icon:SetOpacity()
				icon:SetColorSaturation()
				icon:SetBorderGlow(isDeadOrOffline, condition)

				if reason == "joinedPvP" and (spellID == 323436 or spellID == 6262) then
					info.auras.healthStoneStacks = nil
					info.auras.purifySoulStacks = nil
					icon.count:SetText("")
				end
			end
		end

		info:CancelTimers(not notEncounterEnd)
		if clearSession then
			info:ClearSessionItemData()
			info:SetupBar()
		elseif not self.displayInactive then
			info.bar:UpdateLayout()
		end
	end

	if not clearSession then
		self:RearrangeExBarIcons()
	end
end
