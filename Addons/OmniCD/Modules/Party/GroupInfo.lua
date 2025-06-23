local E = select(2, ...):unpack()
local P, CM, CD = E.Party, E.Comm, E.Cooldowns

local pairs, ipairs, type = pairs, ipairs, type
local GetSpellLevelLearned = E.spell_requiredLevel and function(id)
		return not P.isInTestMode and E.spell_requiredLevel[id] or 0
	end
	or E.preCata and function() return 0 end
	or C_Spell and C_Spell.GetSpellLevelLearned
	or GetSpellLevelLearned

local loginsessionData = {}

local GroupInfoMixin = {}

function GroupInfoMixin:ProcessSpell(spellID)

	local guid = self.guid

	if E.specTalentChangeIDs[spellID] then
		if guid ~= E.userGUID and not CM.syncedGroupMembers[guid] then
			CM:EnqueueInspect(nil, guid)
		end
		return
	end

	local covenantID = E.covenant_abilities[spellID]
	if covenantID and P.isInShadowlands and guid ~= E.userGUID and not CM.syncedGroupMembers[guid] then
		loginsessionData[guid] = loginsessionData[guid] or {}
		local currID = loginsessionData[guid].covenantID
		if covenantID ~= currID then
			if currID then
				local currSpellID = E.covenant_to_spellid[currID]
				loginsessionData[guid][currSpellID] = nil
				self.talentData[currSpellID] = nil
				if currID == 3 then
					self.talentData[319217] = nil
				end
			end

			local covenantSpellID = E.covenant_to_spellid[covenantID]
			loginsessionData[guid][covenantSpellID] = "C"
			loginsessionData[guid].covenantID = covenantID
			self.talentData[covenantSpellID] = "C"
			self.shadowlandsData.covenantID = covenantID
			if spellID == 319217 then
				self.talentData[spellID] = 0
			end
			self:SetupBar()
		else
			if spellID == 319217 and not self.talentData[spellID] then
				self.talentData[spellID] = 0
				self:SetupBar()
			end
		end
	end

	local icon, mergedID
	if E.spellcast_merged[spellID] then
		icon, mergedID = self:FindIconFromCastID(spellID)
	else
		icon = self.spellIcons[spellID]
	end

	local linked = E.spellcast_linked[mergedID or spellID]
	if linked then
		for _, linkedID in pairs(linked) do
			local icon = self.spellIcons[linkedID]
			if icon then
				if linkedID == mergedID then
					if P.isHighlightEnabled and mergedID and icon.buff == mergedID then
						icon.buff = spellID
					end
				end

				icon:StartCooldown((E.isWOTLKC or E.isCata) and (spellID == 6552 and 10 or (spellID == 72 and 12)) or icon.duration)

				if E.preCata then
					self.active[linkedID].castedLink = mergedID or spellID
				end
			end
		end
		return
	end


	if icon and icon.duration > 0 then


		if P.isHighlightEnabled and mergedID and icon.buff == mergedID then
			icon.buff = spellID
		end

		if E.spell_auraremoved_cdstart_preactive[spellID] then
			if icon.active then
				icon.cooldown:Clear()
			end
			self.preactiveIcons[icon.spellID] = icon

			icon:SetHighlight()
			icon:SetCooldownElements()
			icon:SetOpacity()
			icon:SetColorSaturation()

			if icon.statusBar then
				icon.statusBar:SetColors()
			end


			if spellID == 5384 then
				self.bar:RegisterUnitEvent("UNIT_AURA", self.unit)
			end
			return
		end

		local updateSpell = E.spellcast_merged_updateoncast[spellID]
		if updateSpell then
			local cd = updateSpell[1] or icon.duration

			if mergedID == 272651 and P.isPvP and self.talentData[356962] then
				cd = cd / 2
			end
			local iconID = self.talentData[ updateSpell[3] ] and updateSpell[4] or updateSpell[2]
			if iconID then
				icon.icon:SetTexture(iconID)
			end
			icon:StartCooldown(cd)
			return
		end

		icon:StartCooldown()
	end


	if E.wwDamageSpells[spellID] and self.talentData[391330] then
		if self.lastComboStrikesID and self.lastComboStrikesID ~= spellID then
			local icon = self.spellIcons[322109]
			if icon and icon.active then
				icon:UpdateCooldown(.6)
			end
		end
		self.lastComboStrikesID = spellID
	end

	local shared = E.spellcast_shared_cdstart[spellID]
	if shared then
		local now = GetTime()
		for i = 1, #shared, 2 do
			local sharedID = shared[i]
			local sharedCD = shared[i+1]
			if type(sharedCD) == "function" then
				sharedCD = sharedCD(self.spec)
			end
			local sharedIcon = self.spellIcons[sharedID]
			if sharedIcon then
				local active = sharedIcon.active and self.active[sharedID]
				if not active or (active.startTime + active.duration - now < sharedCD) then
					sharedIcon:StartCooldown(sharedCD)
				end
				if not E.preCata then
					break
				end
			end
		end
		return
	end

	local reset = E.spellcast_cdreset[spellID]
	if reset then
		if self:IsTalentForPvpStatus(reset[1]) then
			self:ResetCdByCast(reset)
		end
	end


	local reducer = E.spellcast_cdr[spellID]
	if reducer then
		for i = 1, #reducer, 5 do
			local talent, pvpMult, duration, target, aura = reducer[i], reducer[i+1], reducer[i+2], reducer[i+3], reducer[i+4]
			if not aura or self.auras[aura] then
				local talentRank = self:IsSpecOrTalentForPvpStatus(talent, 1)
				if talentRank then
					self:ReduceCdByCast(talentRank, pvpMult, duration, target)
				end
			end
		end
	end

	if not E.isBFA then
		return
	end

	local azerite = E.spellcast_cdr_azerite[spellID]
	if azerite and self.talentData[azerite.azerite] then
		for k, reducedTime in pairs(azerite.target) do
			local targetIcon = self.spellIcons[k]
			if targetIcon then
				if targetIcon.active then
					targetIcon:UpdateCooldown(reducedTime)
				end
				break
			end
		end
	end

	local stiveSpec = E.spell_cdmod_ess_strive_mult[spellID]
	if (stiveSpec == true or stiveSpec == self.spec) and guid == E.userGUID and P.isPvP then
		C_Timer.After(2, function() CM.SendStrivePvpTalentCD(spellID) end)
	end
end

local wotlkcReadinessExcluded = {
	[23989] = true,
	[19574] = true,
	[53480] = true,
	[54044] = true,
	[53490] = true,
	[53517] = true,
	[26090] = true,
}

local shouldResetAllCharges = {
	[204596] = true,
	[258920] = true,
	[205625] = true,
	[358267] = true,
	[119582] = true,
}

function GroupInfoMixin:ResetClassicSpellsOnReadinessPrep()
	for id, icon in pairs(self.spellIcons) do
		if icon.active and icon.isBookType and not wotlkcReadinessExcluded[id] then
			icon:ResetCooldown()
		end
	end
end

function GroupInfoMixin:ResetClassicWardsOnColdSnap(icon, resetID)

	if self.active[resetID] and resetID == self.active[resetID].castedLink then
		local linkedIcon = self.spellIcons[543]
		if linkedIcon and linkedIcon.active then
			linkedIcon:ResetCooldown()
		end
		icon:ResetCooldown()
	end
end

function GroupInfoMixin:ResetCdByCast(reset)
	for i = 2, #reset do
		local resetID = reset[i]
		if type(resetID) == "table" then
			if self:IsTalentForPvpStatus(resetID[1]) then
				self:ResetCdByCast(resetID)
			end
		elseif resetID == "*" then
			self:ResetClassicSpellsOnReadinessPrep()
		else
			local icon = self.spellIcons[resetID]
			if icon and icon.active then
				if resetID == 6143 then
					self:ResetClassicWardsOnColdSnap(icon, resetID)
				elseif resetID ~= 120 or not self.talentData[417493] then
					icon:ResetCooldown(shouldResetAllCharges[resetID])
				end
			end
		end
	end
end

function GroupInfoMixin:ReduceCdByCast(talentRank, pvpMult, duration, target)
	if type(target) == "table" then
		for targetID, reducedTime in pairs(target) do
			self:ReduceCdByCast(talentRank, pvpMult, reducedTime, targetID)
		end
	else
		local icon = self.spellIcons[target]
		if icon and icon.active then
			if type(duration) == "table" then
				duration = duration[talentRank]
			end
			if pvpMult and P.isPvP then
				duration = pvpMult * duration
			end
			icon:UpdateCooldown(duration)
		end
	end
end

function GroupInfoMixin:FindIconFromCastID(spellID)
	local icon = self.spellIcons[spellID]
	if icon then
		return icon, spellID
	end
	spellID = E.spellcast_merged[spellID]
	if spellID then
		return self:FindIconFromCastID(spellID)
	end
	return nil
end

function GroupInfoMixin:AddOnCast(spellID, itemID, castID)

	castID = castID or spellID
	local isUser = self.guid == E.userGUID
	local isSyncSpell = E.sync_cooldowns[self.class][castID] or E.sync_cooldowns.ALL[castID]

	if not P.spell_enabled[spellID] and (not isUser or not isSyncSpell) then
		return
	end

	if itemID then
		self.sessionItemData[itemID] = true
	end


	if isUser and isSyncSpell then
		CM.cooldownSyncIDs[castID] = spellID
		CM.cooldownSyncSpellIDs[spellID] = true
		CM:ToggleCooldownSync()
	end
	self:SetupBar()

	return self.spellIcons[spellID]
end

local twwHeroTalents = {
	[436358] = true,
	[439843] = true,
	[444347] = true,
	[443328] = true,
	[442726] = true,
	[428933] = true,
	[451235] = true,
	[432472] = true,
	[443454] = true,
	[444995] = true,
}

function GroupInfoMixin:SetupBar(isUpdateBarsOrGRU)
	local guid, index, unit, raceID, specID, class, name, lvl = self.guid, self.index, self.unit, self.raceID, self.spec, self.class, self.name, self.level
	local isUser = guid == E.userGUID

	wipe(self.spellIcons)

	local bar = self.bar or self:GetBarFrame()
	bar:UnregisterAllEvents()
	bar:SetUnit(self, unit, index)
	bar:RefreshUnitBarFrames()

	if self.isAdminForMDI then
		if isUser then
			CM.CooldownSyncFrame:ReleaseIcons()
		end
		bar:ReleaseIcons()
		bar.anchor:Hide()
		return
	end

	local sessionData = loginsessionData[guid]
	self:SetSessionTalentData(sessionData)
	self:SetUnitAuraItemData()
	self:SetClassVariables()

	local iconIndex = 0
	local syncIndex = 0
	for spellID, spell in pairs(E.hash_spelldb) do
		local cat, spellType, spec, race, item, talent, disabledSpec = spell.class, spell.type, spell.spec, spell.race, spell.item, spell.talent, spell.disabledSpec

		local isDisabledSpec = disabledSpec and disabledSpec[specID] and disabledSpec[specID][P.zone]
		if not isDisabledSpec or isUser then
			local isValidSpell
			local enabledSpell = P.spell_enabled[spellID]

			local extraBarKey, extraBarFrame
			if enabledSpell and enabledSpell > 0 then
				extraBarKey = P.extraBarKeys[enabledSpell]
				extraBarFrame = P.activeExBars[extraBarKey]
			end

			local isUserEnabled, isUserSyncOnly
			if isUser then
				isUserEnabled = not isDisabledSpec and enabledSpell and (enabledSpell > 0 and extraBarFrame.db.showPlayer or enabledSpell == 0 and not P.isUserHidden)
				if not isUserEnabled then
					isUserSyncOnly = CM.cooldownSyncSpellIDs[spellID]
				end
			end

			if not isUser and enabledSpell or isUserEnabled or isUserSyncOnly then
				if cat == "RACIAL" then
					if type(race) == "table" then
						for k = 1, #race do
							local id = race[k]
							if id == raceID then
								isValidSpell = true
							end
						end
					elseif race == raceID then
						isValidSpell = true
					end
				elseif specID then
					if cat == class then
						isValidSpell = (not E.postSL or not E.covenant_abilities[spellID] or P.isInShadowlands)
							and self:IsSpecOrTalentForPvpStatus(spec==true and spellID or spec, lvl >= GetSpellLevelLearned(spellID))
							and (not talent or not self:IsSpecOrTalentForPvpStatus(talent, true))
					elseif cat == "COVENANT" then
						isValidSpell = P.isInShadowlands and self:IsSpecOrTalentForPvpStatus(spec==true and spellID or spec, true)
					elseif cat == "ESSENCE" then
						isValidSpell = self.talentData[spec]
					elseif not E.BOOKTYPE_CATEGORY[cat] then
						isValidSpell = self:IsEquipped(item) or (self.sessionItemData[item] and (item ~= 5512 or not self.talentData[386689]))
					end
				else

					if cat == class then
						isValidSpell = lvl >= GetSpellLevelLearned(spellID) and (not spec or (sessionData and sessionData[spec])) and not talent
					elseif cat == "COVENANT" then
						isValidSpell = P.isInShadowlands and sessionData and sessionData[spec]
					elseif cat == "TRINKET" then
						isValidSpell = not item or self.sessionItemData[item] and (item ~= 5512 or class ~= "WARLOCK")
					end
				end
			end

			if isValidSpell then
				local cd = self:GetValueByType(spell.duration)
				if cd and (not E.preCata or not P.isInArena or cd < 900) then
					local buffID, iconTexture = spell.buff, spell.icon
					local ch = self:GetValueByType(spell.charges) or 1
					local baseCooldown = cd
					if specID then
						if cat == class then
							local modData = E.spell_cdmod_talents[spellID]
							if modData then
								for k = 1, #modData, 2 do
									local rank = self:IsTalentForPvpStatus(modData[k])
									if rank then
										local rt = modData[k+1]
										if type(rt) == "table" then
											rt = self:FindReducedTime(rt, specID, rank)
										end
										if rt then cd = cd - rt end
									end
								end
							end

							modData = E.spell_cxmod_azerite[spellID]
							if modData and self.talentData[modData.azerite] then
								if modData.duration then
									cd = cd - modData.duration
								elseif modData.charges then
									ch = ch + modData.charges
								end
							end

							modData = E.spell_cdmod_conduits[spellID]
							if modData and P.isInShadowlands then
								local rankValue = self.talentData[modData]
								if rankValue then
									if P.isPvP and modData == 336636 then
										rankValue = rankValue / 2
									end
									cd = cd - rankValue
								end
							end

							modData = E.spell_cdmod_by_haste[spellID]
							if modData == true or modData == specID then
								if E.preCata then
									cd = cd + (self.rangedWeaponSpeed or 0)
								else
									local spellHasteMult = self.spellHasteMult or 1/(1 + UnitSpellHaste("player")/100)
									cd = cd * spellHasteMult
								end
							end

							modData = E.spell_cdmod_talents_mult[spellID]
							if modData then
								for k = 1, #modData, 2 do
									local rank = self:IsTalentForPvpStatus(modData[k])
									if rank then
										local mult = modData[k+1]
										if type(mult) == "table" then
											mult = self:FindReducedTime(mult, specID, rank, true)
										end
										if mult then cd = cd * mult end
									end
								end
							end

							modData = E.spell_cdmod_conduits_mult[spellID]
							if modData and P.isInShadowlands then
								local rankValue = self.talentData[modData]
								if rankValue then
									cd = cd * rankValue
								end
							end

							modData = self.talentData["essStriveMult"]
							if modData then
								local stiveSpec = E.spell_cdmod_ess_strive_mult[spellID]
								if stiveSpec == true or stiveSpec == specID then
									cd = P.isPvP and sessionData and sessionData["strivedPvpCD"] or cd * modData
								elseif spellID == 107574 and specID == 71 then
									cd = cd - 5
								end
							end


							if self.talentData[412713] and spellID ~= 404381 then
								cd = cd * 0.9
							end

							modData = E.spell_chmod_talents[spellID]
							if modData then
								for k = 1, #modData, 2 do
									local tal = modData[k]
									local rank = self:IsTalentForPvpStatus(tal)
									if rank then
										local charges = modData[k + 1]
										charges = type(charges) == "table" and (charges[rank] or charges[1]) or charges
										ch = ch + charges
									end
								end
							end
						elseif cat == "COVENANT" then
							local covData = E.covenant_cdmod_conduits[spellID]
							if covData and self.talentData[ covData[1] ] then
								cd = cd - covData[2]
							end

							covData = E.covenant_cdmod_items_mult[spellID]
							if covData and self.itemData[ covData[1] ] then
								cd = cd * covData[2]
							end

							covData = E.covenant_chmod_conduits[spellID]
							if covData and self.talentData[ covData[1] ] then
								ch = ch + covData[2]
							end
						elseif cat == "ESSENCE" then
							local essData = E.spell_cdmod_essrank23 [spellID]
							if essData then
								if E:IsEssenceRankUpgraded(self.talentData["essMajorID"]) then
									cd = cd - essData
								end
							end

							essData = E.spell_chargemod_essrank3 [spellID]
							if essData then
								if essData[1] == self.talentData["essMajorID"] then
									ch = ch + essData[2]
								end
							end
						elseif cat == "RACIAL" then
							local modData = E.spell_cdmod_talents[spellID]
							if modData then
								for k = 1, #modData, 2 do
									local tal = modData[k]
									local rank = self:IsTalentForPvpStatus(tal)
									if rank then
										local rt = modData[k+1]
										rt = type(rt) == "table" and (rt[rank] or rt[1]) or rt
										cd = cd - rt
									end
								end
							end


							if self.talentData[412713] then
								cd = cd * 0.9
							end
						end
					end
					ch = ch > 1 and ch

					local icon
					if isUserSyncOnly then
						syncIndex = syncIndex + 1
						icon = CM.CooldownSyncFrame.icons[syncIndex]
						if not icon then
							icon = P.IconPool:Acquire()
							CM.CooldownSyncFrame.icons[syncIndex] = icon
							icon:SetParent(CM.CooldownSyncFrame)
							icon.parent = CM.CooldownSyncFrame
							icon:ClearAllPoints()
							icon:SetPoint("BOTTOMLEFT", CM.CooldownSyncFrame, "BOTTOMLEFT", syncIndex * 36, 0)
							--[==[@debug@
							icon:HideBorder()
							--@end-debug@]==]
							icon:Show()
						end
					elseif extraBarFrame then
						icon = P.IconPool:Acquire()
						if extraBarFrame.db.unitBar then
							local unitBar = bar.activeUnitBars[enabledSpell]
							icon:SetParent(unitBar)
							icon.parent = unitBar
							unitBar.icons[#unitBar.icons + 1] = icon
						else
							icon:SetParent(extraBarFrame.container)
							icon.parent = extraBarFrame.container
						end
						extraBarFrame.numIcons = extraBarFrame.numIcons + 1
						extraBarFrame.icons[extraBarFrame.numIcons] = icon
					else
						iconIndex = iconIndex + 1
						icon = bar.icons[iconIndex]
						if not icon then
							icon = P.IconPool:Acquire()
							bar.icons[iconIndex] = icon
						end
						icon:SetParent(bar.container)
						icon.parent = bar.container
					end
					icon.name:Hide()
					icon.guid = guid
					icon.spellID = spellID
					icon.class = class
					icon.unit = unit
					icon.unitName = name
					icon.type = spellType
					icon.priority = E.db.spellPriority[spellID] or E.db.priority[spellType]
					icon.category = cat

					icon.isBookType = (E.BOOKTYPE_CATEGORY[cat] or cat == "COVENANT") and not twwHeroTalents[spellID]
					icon.buff = buffID
					icon.duration = cd and cd < 1 and 1 or cd
					icon.baseCooldown = baseCooldown
					icon.maxcharges = ch
					icon.count:SetText(ch or (spellID == 323436 and self.auras.purifySoulStacks) or (spellID == 6262 and self.auras.healthStoneStacks) or "")

					iconTexture = spellID == 371032 and (self.talentData[403631] and 5199622 or 4622450) or iconTexture
					icon.icon:SetTexture(iconTexture)
					icon.iconTexture = iconTexture
					icon.isUserSyncOnly = isUserSyncOnly

					icon.active = nil
					icon.tooltipID = nil
					icon.modRate = self.spellModRates[spellID] or 1
					icon.glowBorder = (not extraBarFrame or extraBarFrame.db.unitBar) and E.db.highlight.glowBorder and E.db.spellGlow[spellID]
					icon.Glow:Hide()
					icon:HideOverlayGlow()

					local active = self.active[spellID]
					if active and active.startTime then

						if icon.maxcharges then
							active.charges = active.charges or (icon.maxcharges - 1)
							icon.count:SetText(active.charges)
						else
							active.charges = nil
						end
						icon.cooldown:SetCooldown(active.startTime, active.duration, active.modRate)
						icon.active = active.charges or 0

						icon:SetHighlight(true)
					else
						icon.cooldown:Clear()
					end


					if self.preactiveIcons[spellID] then

						if spellID == 642 and self.talentData[146956] then
							self.preactiveIcons[spellID] = nil
						else
							self.preactiveIcons[spellID] = icon
						end
						icon:SetHighlight(true)
					end
					self.spellIcons[spellID] = icon


					if extraBarFrame and extraBarFrame.shouldShowProgressBar and not isUserSyncOnly then
						P:GetStatusBarFrame(icon, extraBarKey, self.nameWithoutRealm)
					end
				end
			end
		end
	end

	if isUser then
		CM.CooldownSyncFrame:ReleaseIcons(syncIndex)
	end
	bar:ReleaseIcons(iconIndex)

	bar:UpdatePosition()
	bar:UpdateLayout(true)
	bar:UpdateSettings()

	if not isUpdateBarsOrGRU then
		P:UpdateExBars()
	end
end

function GroupInfoMixin:GetBarFrame()

	local bar = P.BarPool:Acquire()
	bar.guid = self.guid
	bar.class = self.class
	bar.raceID = self.raceID
	bar.info = self
	self.bar = bar
	return bar
end

function GroupInfoMixin:SetSessionTalentData(data)
	if not data or not self.specID or self.shadowlandsData.covenantID or CM.syncedGroupMembers[self.guid] then
		return
	end
	for k, v in pairs(data) do
		if k == "covenantID" then
			self.shadowlandsData.covenantID = v
		else
			self.talentData[k] = v
		end
	end
end

function GroupInfoMixin:SetUnitAuraItemData()
	if not E.postDF then
		return
	end

	local found
	AuraUtil.ForEachAura(self.unit, "HELPFUL", nil, function(_,_, count, _,_,_, source, _,_, id)

		if id == 410318 then
			found = true
			self.itemData[205146] = true

		elseif id == 1214887 then
			self.auras.numCycleOfHatred = count
		end

		local auraStr = E.auraMultString[id]
		if auraStr then
			self.auras[auraStr] = true
		end

	end)

	if not found and self.itemData[205146] then
		self.itemData[205146] = nil
	end
end

function GroupInfoMixin:SetClassVariables()
	if not E.postDF then
		return
	end
	if self.class == "ROGUE" then
		local points = GetUnitChargedPowerPoints(self.unit)
		self.auras.numChargedPP = points and #points
		self.bonusCP = (self.talentData[470347] or 0) + (self.talentData[470668] or 0)
		local cp = 5
		if self.talentData[193531] then
			cp = cp + 1
		end
		if self.talentData[394320] then
			cp = cp + 1
		end
		if self.talentData[394321] then
			cp = cp + 1
		end
		self.maxCP = cp
	elseif self.class == "EVOKER" then
		self.isWingleader = self.talentData[441206]
			and (P.spell_enabled[357210] or P.spell_enabled[371032] or P.spell_enabled[403631])
		CD:UpdateBombardiers(self.isWingleader)
	end
end


local specIDs = {
	[62]=true, [63]=true, [64]=true, [65]=true, [66]=true, [70]=true, [71]=true, [72]=true, [73]=true,
	[102]=true, [103]=true, [104]=true, [105]=true, [250]=true, [251]=true, [252]=true, [253]=true, [254]=true, [255]=true,
	[256]=true, [257]=true, [258]=true, [259]=true, [260]=true, [261]=true, [262]=true, [263]=true, [264]=true,
	[265]=true, [266]=true, [267]=true, [268]=true, [269]=true, [270]=true, [577]=true, [581]=true, [1467]=true, [1468]=true, [1473]=true
}

local covenantIDs = {
	[321076]=true, [321079]=true, [321077]=true, [321078]=true
}


function GroupInfoMixin:IsSpecOrTalentForPvpStatus(talentID, isLearnedLevel)
	if not talentID then
		return isLearnedLevel
	end
	if type(talentID) == "table" then
		for _, id in ipairs(talentID) do
			local talent = self:IsSpecOrTalentForPvpStatus(id, isLearnedLevel)
			if talent then
				return talent
			end
		end
	else
		if talentID < 0 then
			return not self.talentData[-talentID]
		end
		if specIDs[talentID] then
			return isLearnedLevel and self.spec == talentID
		end
		if covenantIDs[talentID] and not P.isInShadowlands then
			return
		end
		local talent = self.talentData[talentID]
		if talent == "PVP" then
			return P.isPvP and 1
		end
		return talent
	end
end

function GroupInfoMixin:IsEquipped(item, item2)
	if not item then
		return true
	end
	return self.itemData[item] or self.itemData[item2]
end

function GroupInfoMixin:GetValueByType(value)
	if not value then
		return
	elseif type(value) == "table" then
		return value[self.spec] or value.default
	end
	return value
end

function GroupInfoMixin:IsTalentForPvpStatus(talentID)
	if not talentID then
		return true
	end
	local talent = self.talentData[talentID]
	if talent == "PVP" then
		return P.isPvP and 1
	end
	return talent
end

function GroupInfoMixin:FindReducedTime(rt, specID, rank, isMult)
	local pvpMult = P.isPvP and rt.pvp
	if rt[1] and rt[1] > 999 then
		rt = self:IsTalentForPvpStatus(rt[1]) and rt[2] or rt[3]
	end
	if type(rt) == "table" then
		rt = rt[specID] or rt[rank] or rt[1]
		if not rt then
			return
		end
		if pvpMult then
			rt = (isMult and 1 - (1 - rt) * pvpMult) or rt * pvpMult
		end
	end
	return rt
end

function GroupInfoMixin:UpdateColorScheme()
	local isDeadOrOffline = self.isDeadOrOffline
	local condition = E.db.highlight.glowBorderCondition

	for id, icon in pairs(self.spellIcons) do

		if isDeadOrOffline and icon.isHighlighted then
			icon:RemoveHighlight()
		end

		icon:SetCooldownElements()
		icon:SetOpacity()
		icon:SetColorSaturation()
		icon:SetBorderGlow(isDeadOrOffline, condition)
		if icon.statusBar then
			icon.statusBar:SetColors()
		end
	end
	P:RearrangeExBarIcons()

	if isDeadOrOffline then
		self.bar:RegisterUnitEvent("UNIT_HEALTH", self.unit)
	end
end

function GroupInfoMixin:Delete()
	local minionGUID = self.petGUID
	if minionGUID then
		CD.minionGUIDS[minionGUID] = nil
	end

	local guid = self.guid
	CM.syncedGroupMembers[guid] = nil
	CM:DequeueInspect(guid)

	self:CancelTimers()

	P.BarPool:Release(self.bar)
	P.groupInfo[guid] = nil

	if guid == E.userGUID then


		wipe(P.userInfo.active)
		wipe(P.userInfo.sessionItemData)
	end
end

function GroupInfoMixin:CancelTimers(isEncounterEnd)
	for k, timer in pairs(self.callbackTimers) do

		if not isEncounterEnd or k ~= "inCombatTicker" then
			if type(timer) == "userdata" then
				timer:Cancel()
			end
			self.callbackTimers[k] = nil
		end
	end
end

function GroupInfoMixin:ClearSessionItemData()
	wipe(self.sessionItemData)
end

function GroupInfoMixin:SetUnit(unit, index, ...)
	self.unit = unit
	self.index = index

	local numArguments = select("#", ...)
	if numArguments > 0 then
		local isDead, isDeadOrOffline, isAdminForMDI, petGUID = ...
		self.isDead = isDead
		self.isDeadOrOffline = isDeadOrOffline
		self.isAdminForMDI = isAdminForMDI
	end
end

function P:CreateUnitInfo(unit, guid, name, level, class, raceID, nameWithoutRealm)

	local info = CreateFromMixins(GroupInfoMixin)
	info.guid = guid
	info.name = name
	info.class = class
	info.level = level > 0 and level or 200
	info.raceID = raceID or select(3, UnitRace(unit))
	info.nameWithoutRealm = nameWithoutRealm or UnitName(unit)
	info.preactiveIcons = {}
	info.spellIcons = {}
	info.glowIcons = {}
	info.active = {}
	info.auras = {}
	info.itemData = {}
	info.talentData = {}
	info.shadowlandsData = {}
	info.callbackTimers = {}
	info.spellModRates = {}
	info.sessionItemData = {}
	return info
end

function P:GetUnitInfo(unit, guid, name, level, class)

	if self.groupInfo[guid] then
		return
	end

	local info = guid == E.userGUID and self.userInfo or self:CreateUnitInfo(unit, guid, name, level, class)
	self.groupInfo[guid] = info
	return info
end

P.loginsessionData = loginsessionData
