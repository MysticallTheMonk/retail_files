local E = select(2, ...):unpack()
local P, CM, CD = E.Party, E.Comm, E.Cooldowns

local pairs, ipairs, type, tonumber, abs, min, max = pairs, ipairs, type, tonumber, abs, min, max
local GetTime, UnitTokenFromGUID, UnitHealth, UnitHealthMax, UnitLevel, UnitChannelInfo, UnitAffectingCombat = GetTime, UnitTokenFromGUID, UnitHealth, UnitHealthMax, UnitLevel, UnitChannelInfo, UnitAffectingCombat
local AuraUtil_ForEachAura = AuraUtil and AuraUtil.ForEachAura
local C_Timer_After, C_Timer_NewTimer, C_Timer_NewTicker = C_Timer.After, C_Timer.NewTimer, C_Timer.NewTicker
local band = bit.band
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE

local BOOKTYPE_CATEGORY = E.BOOKTYPE_CATEGORY
local groupInfo = P.groupInfo
local userGUID = E.userGUID

local auraMultString = {}
local minionGUIDS = {}

function CD:Enable()
	if self.isEnabled then
		return
	end
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UNIT_PET")
	self:SetScript("OnEvent", function(self, event, ...)
		self[event](self, ...)
	end)
	self.isEnabled = true
end

function CD:Disable()
	if not self.isEnabled then
		return
	end
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("UNIT_PET")
	wipe(minionGUIDS)
	self.isEnabled = false
end

local mt = {
	__index = function(t, k)
		t[k] = {}
		return t[k]
	end
}

local registeredEvents = setmetatable({}, mt)
local registeredHostileEvents = setmetatable({}, mt)






local function RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
	if P.isHighlightEnabled and destGUID == srcGUID then
		local icon = info.glowIcons[spellID]
		if icon then
			icon:RemoveHighlight()
			icon:SetCooldownElements()
			icon:SetOpacity()
			icon:SetColorSaturation()
		end
	end
end

for k in pairs(E.spell_highlighted) do
	registeredEvents["SPELL_AURA_REMOVED"][k] = RemoveHighlightByCLEU
end

function CD:RegisterRemoveHighlightByCLEU(spellID)
	local func = registeredEvents["SPELL_AURA_REMOVED"][spellID]
	if not func then
		registeredEvents["SPELL_AURA_REMOVED"][spellID] = RemoveHighlightByCLEU
	elseif func ~= RemoveHighlightByCLEU then
		registeredEvents["SPELL_AURA_REMOVED"][spellID] = function(...)
			func(...)
			RemoveHighlightByCLEU(...)
		end
	end
end






local playerInterrupts = {
	47528,
	183752,
	106839,
	93985,
	97547,
	351338,
	147362,
	187707,
	2139,
	116705,
	96231,
	31935,
	220543,
	1766,
	57994,
	132409,
	6552,
	386071,
}

local function AppendInterruptExtras(info, _, spellID, _,_,_, extraSpellId, extraSpellName, _,_, destRaidFlags)
	local icon = info.spellIcons[E.spellcast_merged[spellID] or spellID]
	local statusBar = icon and icon.type == "interrupt" and icon.statusBar
	if statusBar then
		local frame = icon:GetParent():GetParent()
		if frame.index == 1 then
			if frame.db.showInterruptedSpell then
				local extraSpellTexture = C_Spell.GetSpellTexture(extraSpellId)
				if extraSpellTexture then
					icon.icon:SetTexture(extraSpellTexture)
					icon.tooltipID = extraSpellId
					if not E.db.icons.showTooltip and icon.isPassThrough then
						icon:EnableMouse(true)
					end
				end
			end
			if frame.db.showRaidTargetMark then
				local mark = E.RAID_TARGET_MARKERS[destRaidFlags]
				if mark then
					statusBar.CastingBar.Text:SetFormattedText("%s %s", statusBar.name, mark)
				end
			end
		end
	end
end

for _, id in pairs(playerInterrupts) do
	registeredEvents["SPELL_INTERRUPT"][id] = AppendInterruptExtras
end






local function StartCdOnAuraRemoved(info, srcGUID, spellID, destGUID)
	if srcGUID == destGUID then
		spellID = E.spell_auraremoved_cdstart_preactive[spellID]
		local icon = info.spellIcons[spellID]
		if icon then
			RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
			icon:StartCooldown()
		end
	end
end

for k, v in pairs(E.spell_auraremoved_cdstart_preactive) do
	if v > 0 then
		registeredEvents["SPELL_AURA_REMOVED"][k] = StartCdOnAuraRemoved
	end
end






local function ProcessSpellOnAuraApplied(info, srcGUID, spellID)
	spellID = E.spell_auraapplied_processspell[spellID]
	info:ProcessSpell(spellID)
end

for k in pairs(E.spell_auraapplied_processspell) do
	registeredEvents["SPELL_AURA_APPLIED"][k] = ProcessSpellOnAuraApplied
end






for id in pairs(E.spell_dispel_cdstart) do
	registeredEvents["SPELL_DISPEL"][id] = function(info)
		local icon = info.spellIcons[id]
		if icon then
			icon:StartCooldown()
		end
	end
end







registeredEvents["SPELL_ENERGIZE"][378849] = function(info)
	local icon = info.spellIcons[47528]
	if icon and icon.active then
		icon:UpdateCooldown(3)
	end
end



registeredEvents["SPELL_CAST_SUCCESS"][219809] = function(info)


	local numShields = info.auras.numBoneShields
	if not numShields or numShields == 1 then
		return
	end

	local consumed = min(5, numShields)

	local icon = info.spellIcons[221699]
	if icon and icon.active then
		icon:UpdateCooldown(2 * consumed)
	end

	if info.talentData[377637] then
		icon = info.spellIcons[49028]
		if icon and icon.active then
			icon:UpdateCooldown(5 * consumed)
		end
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][194844] = registeredEvents["SPELL_CAST_SUCCESS"][219809]

registeredEvents["SPELL_AURA_APPLIED_DOSE"][195181] = function(info, _,_,_,_,_,_, amount)
	if info.spellIcons[221699] or info.spellIcons[49028] then
		info.auras.numBoneShields = amount
	end
end

registeredEvents["SPELL_AURA_REMOVED"][195181] = function(info, _,_,_,_,_,_, amount)
	local numShields = info.auras.numBoneShields
	if not numShields then
		return
	end

	amount = amount or 0
	info.auras.numBoneShields = amount

	local consumed = numShields - amount
	if consumed ~= 1 then
		return
	end

	local icon = info.spellIcons[221699]
	if icon and icon.active then
		icon:UpdateCooldown(2)
	end
	if info.talentData[377637] then
		icon = info.spellIcons[49028]
		if icon and icon.active then
			icon:UpdateCooldown(5)
		end
	end
end
registeredEvents["SPELL_AURA_REMOVED_DOSE"][195181] = registeredEvents["SPELL_AURA_REMOVED"][195181]


local runicPowerSpenders = {
	[49998] = 45,
	[47541] = 30,
	[61999] = 30,

}

local function ReduceVampiricBloodCD(info, _, spellID)
	if info.talentData[205723] then
		local icon = info.spellIcons[55233]
		if icon and icon.active then
			local rp = runicPowerSpenders[spellID]
			if spellID == 49998 then
				--[[ BUG2: cost reduction ignored
				if info.talentData[374277] then
					rp = rp - 5
				end
				]]
				if info.auras.rrt_ossuary then
					rp = rp - 5
				end
				if info.auras.rrt_bloodDraw then
					rp = rp - 10
				end
			elseif spellID == 47541 then

				if info.auras.rrt_ossuary then
					rp = rp - 5
				end
			end

			icon:UpdateCooldown(rp * 0.2)
		end
	end
end

for id in pairs(runicPowerSpenders) do
	registeredEvents["SPELL_CAST_SUCCESS"][id] = ReduceVampiricBloodCD
end

registeredEvents["SPELL_AURA_APPLIED"][219788] = function(info) info.auras.rrt_ossuary = true end
registeredEvents["SPELL_AURA_REMOVED"][219788] = function(info) info.auras.rrt_ossuary = nil end
registeredEvents["SPELL_AURA_APPLIED"][454871] = function(info) info.auras.rrt_bloodDraw = true end
registeredEvents["SPELL_AURA_REMOVED"][454871] = function(info) info.auras.rrt_bloodDraw = nil end


registeredEvents["SPELL_DAMAGE"][436304] = function(info)
	local icon = info.spellIcons[48743]
	if icon and icon.active then
		icon:UpdateCooldown(5)
	end
end




registeredEvents["PARTY_KILL"]["DEATHKNIGHT"] = function(info, _,_, destGUID)
	local unit = UnitTokenFromGUID(destGUID)
	if unit then
		if abs(info.level - UnitLevel(unit)) < 9 then
			local icon = info.talentData[276079] and info.spellIcons[49576]
			if icon and icon.active then
				icon:ResetCooldown()
			end
			icon = info.talentData[434136] and info.spellIcons[48792]
			if icon and icon.active then
				icon:UpdateCooldown(3)
			end
		end
	end
end


registeredEvents["SPELL_SUMMON"][52150] = function(info, srcGUID, spellID, destGUID, _,_,_,_,_,_,_, ts)
	if (not info.talentData[276079] or not info.spellIcons[49576]) and (not info.talentData[434136] or not info.spellIcons[48792]) then
		return
	end

	minionGUIDS[destGUID] = srcGUID
	if spellID == 52150 or spellID == 196910 then
		return
	end

	info.tempMinions = info.tempMinions or {}
	if ts - (info.auras.time_lastSummon or 0) > 30 then
		for i = #info.tempMinions, 1, -1 do
			local guid = info.tempMinions[i]
			minionGUIDS[guid] = nil
			info.tempMinions[i] = nil
		end
	end
	info.tempMinions[#info.tempMinions + 1] = destGUID
	info.auras.time_lastSummon = ts
end

registeredEvents["SPELL_SUMMON"][196910] = registeredEvents["SPELL_SUMMON"][52150]
registeredEvents["SPELL_SUMMON"][ 42651] = registeredEvents["SPELL_SUMMON"][52150]
registeredEvents["SPELL_SUMMON"][275430] = registeredEvents["SPELL_SUMMON"][52150]
registeredEvents["SPELL_SUMMON"][317776] = registeredEvents["SPELL_SUMMON"][52150]
registeredEvents["SPELL_SUMMON"][455395] = registeredEvents["SPELL_SUMMON"][52150]
registeredEvents["SPELL_SUMMON"][444248] = registeredEvents["SPELL_SUMMON"][52150]
registeredEvents["SPELL_SUMMON"][444251] = registeredEvents["SPELL_SUMMON"][52150]
registeredEvents["SPELL_SUMMON"][444252] = registeredEvents["SPELL_SUMMON"][52150]
registeredEvents["SPELL_SUMMON"][444254] = registeredEvents["SPELL_SUMMON"][52150]








local demonHunterSigils = {
	204596,
	207684,
	202137,
	202138,
	390163,
}

registeredEvents["SPELL_CAST_SUCCESS"][204596] = function(info, _,_,_,_,_,_,_,_,_,_, timestamp)
	if info.talentData[389718] then
		if timestamp > (info.auras.time_cycleOfBinding or 0) then
			for _, id in ipairs(demonHunterSigils) do
				local icon = info.spellIcons[id]
				if icon and icon.active then
					icon:UpdateCooldown(5)
				end
			end
			info.auras.time_cycleOfBinding = timestamp + 0.1
		end
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][389810] = registeredEvents["SPELL_CAST_SUCCESS"][204596]
registeredEvents["SPELL_CAST_SUCCESS"][469991] = registeredEvents["SPELL_CAST_SUCCESS"][204596]




registeredEvents["SPELL_CAST_SUCCESS"][198013] = function(info)
	if info.talentData[258887] then
		local icon = info.spellIcons[198013]
		if icon and icon.active then
			icon:UpdateCooldown(5 * (info.auras.numCycleOfHatred or 1))
		end
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][452497] = registeredEvents["SPELL_CAST_SUCCESS"][198013]

registeredEvents["SPELL_AURA_APPLIED_DOSE"][1214887] = function(info, _,_,_,_,_,_, amount)
	info.auras.numCycleOfHatred = amount
end

registeredEvents["SPELL_AURA_REMOVED_DOSE"][1214887] = function(info, _,_,_,_,_,_, amount)
	info.auras.numCycleOfHatred = amount
end



registeredEvents["SPELL_ENERGIZE"][391345] = function(info, _,_,_,_,_, amount)
	local icon = info.spellIcons[212084]
	if icon and icon.active then
		icon:UpdateCooldown(icon.duration * amount/100)
	end
end


registeredEvents["SPELL_AURA_APPLIED"][212800] = function(info)
	if info.talentData[205411] then
		local icon = info.spellIcons[198589]
		if icon and not icon.active then
			icon:StartCooldown(icon.duration/2)
		end
	end
end


registeredEvents["SPELL_HEAL"][203794] = function(info)
	if info.talentData[218612] then
		local icon = info.spellIcons[203720]
		if icon and icon.active then
			icon:UpdateCooldown(.35)
		end
	end
end


registeredEvents["SPELL_AURA_REMOVED"][162264] = function(info, srcGUID, spellID, destGUID)
	if info.talentData[390142] then
		local icon = info.spellIcons[195072]
		if icon and icon.active then
			icon:ResetCooldown()
		end
	end
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end







registeredEvents["SPELL_AURA_APPLIED"][319454] = function(info)
	if info.spec == 104 then
		return
	end
	local icon = info.spellIcons[22842]
	if icon then
		icon.maxcharges = 2
		local active = icon.active and info.active[22842]
		if active then
			active.charges = 1
			icon.active = 1
			icon.count:SetText(1)
			icon:SetCooldownElements()
			icon:SetBorderGlow(info.isDeadOrOffline, E.db.highlight.glowBorderCondition)
		else
			icon.count:SetText(2)
		end
	end
end

registeredEvents["SPELL_AURA_REMOVED"][319454] = function(info, srcGUID, spellID, destGUID)
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)

	if info.spec == 104 then
		return
	end
	local icon = info.spellIcons[22842]
	if icon then
		icon.maxcharges = nil
		icon.count:SetText("")
		local active = icon.active and info.active[22842]
		if active and active.charges then
			if active.charges == 0 then
				active.charges = nil
				icon.active = 0
				icon:SetCooldownElements()
			else
				icon:ResetCooldown()
			end
		end
	end
end


registeredEvents["SPELL_INTERRUPT"][97547] = function(info, _, spellID, _,_,_, extraSpellId, extraSpellName, _,_, destRaidFlags)
	if info.talentData[202918] then
		local icon = info.spellIcons[78675]
		if icon and icon.active then
			icon:UpdateCooldown(15)
		end
	end
	AppendInterruptExtras(info, nil, spellID, nil,nil,nil, extraSpellId, extraSpellName, nil,nil, destRaidFlags)
end


local savageMomentumIDs = {
	5217,
	61336,
	1850,
	252216,
}

registeredEvents["SPELL_INTERRUPT"][93985] = function(info, _, spellID, _,_,_, extraSpellId, extraSpellName, _,_, destRaidFlags)
	if P.isPvP and info.talentData[205673] then
		for i = 1, 4 do
			local id = savageMomentumIDs[i]
			local icon = info.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(10)
			end
		end
	end
	AppendInterruptExtras(info, nil, spellID, nil,nil,nil, extraSpellId, extraSpellName, nil,nil, destRaidFlags)
end


registeredEvents["SPELL_AURA_REMOVED"][50334] = function(info, srcGUID, spellID, destGUID)
	info.auras.mult_berserkRavage = nil
	info.auras.mult_berserkPersistence = nil
	info.auras.mult_berserkUnchecdAggression = nil
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end

registeredEvents["SPELL_AURA_APPLIED"][50334] = function(info)

	if info.talentData[343240] then
		local icon = info.spellIcons[6795]
		if icon and icon.active then
			icon:ResetCooldown()
		end
		info.auras.mult_berserkRavage = true
	end

	if info.talentData[377779] then
		local icon = info.spellIcons[22842]
		if icon and icon.active then
			icon:ResetCooldown(true)
		end
		info.auras.mult_berserkPersistence = true
	end

	if info.talentData[377623] then
		info.auras.mult_berserkUnchecdAggression = true
	end
end

registeredEvents["SPELL_AURA_REMOVED"][102558] = registeredEvents["SPELL_AURA_REMOVED"][50334]
registeredEvents["SPELL_AURA_APPLIED"][102558] = registeredEvents["SPELL_AURA_APPLIED"][50334]


local guardianRageSpenders = {
	[22842] = 10,
	[192081] = 40,
	[20484] = 30,
	[6807] = 40,
	[400254] = 40,
	[441605] = 40,
}

local function ReduceGuardianIncarnationCD(info, srcGUID, spellID)
	if info.talentData[393414] then
		local icon = info.spellIcons[102558]
		if icon and icon.active then
			local rCD = guardianRageSpenders[spellID] / 25
			if spellID == 6807 or spellID == 400254 or spellID == 441605 then
				if info.auras.rrt_toothAndClaw then
					return
				end
				if info.auras.mult_berserkUnchecdAggression then
					rCD = rCD * .5
				end
			elseif spellID == 192081 then
				if info.auras.mult_berserkPersistence then
					rCD = rCD * .5
				end
				if info.auras.rrt_goryFur then
					rCD = rCD * .75
				end
			end
			icon:UpdateCooldown(rCD)
		end
	end
end

for id in pairs(guardianRageSpenders) do
	registeredEvents["SPELL_CAST_SUCCESS"][id] = ReduceGuardianIncarnationCD
end

registeredEvents["SPELL_AURA_APPLIED"][135286] = function(info) info.auras.rrt_toothAndClaw = true end
registeredEvents["SPELL_AURA_REMOVED"][135286] = function(info) info.auras.rrt_toothAndClaw = nil end
registeredEvents["SPELL_AURA_APPLIED"][201671] = function(info) info.auras.rrt_goryFur = true end
registeredEvents["SPELL_AURA_REMOVED"][201671] = function(info) info.auras.rrt_goryFur = nil end


local ReduceIncarnTree_OnDurationEnd = function(srcGUID)
	local info = groupInfo[srcGUID]
	if info then
		local icon = info.spellIcons[33891] or info.spellIcons[473909]
		if icon and icon.active then
			icon:UpdateCooldown(info.spellIcons[473909] and 2.5 or 5)
		end
	end
end

registeredEvents["SPELL_SUMMON"][102693] = function(info, srcGUID)
	if info.talentData[393371] then
		local icon = info.spellIcons[33891] or info.spellIcons[473909]
		if icon then
			C_Timer_After(15, function() ReduceIncarnTree_OnDurationEnd(srcGUID) end)
		end
	end
end


registeredEvents["SPELL_CAST_SUCCESS"][157982] = function(info)
	if info.talentData[392162] then
		for _, icon in pairs(info.spellIcons) do
			if icon and icon.active and icon.isBookType and icon.spellD ~= 740 then
				icon:UpdateCooldown(4)
			end
		end
	end
end



registeredEvents["SPELL_CAST_SUCCESS"][33891] = function(info)
	if info.auras.isTreeOfLife then
		return
	end
	local icon = info.spellIcons[33891]
	if icon then


		C_Timer_After(0, function()
			icon:StartCooldown(nil, nil, nil, info.talentData[434249] and min(GetTime() - (info.auras.endTime_incarnConvoke or 0), 15))
		end)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][117679] = function(info)
	info.auras.isTreeOfLife = true
end

registeredEvents["SPELL_AURA_REMOVED"][117679] = function(info, srcGUID, spellID, destGUID)
	info.auras.isTreeOfLife = nil
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end


local controlOfTheDreamIDs = {
	[132158] = "endTime_naturesSwiftness",
	[33891] = "endTime_incarnConvoke",
	[391528] = "endTime_incarnConvoke",
	[194223] = "endTime_celetialAlignment",
	[102560] = "endTime_incarnConvoke",
	[205636] = "endTime_forceOfNature",
}

registeredEvents["SPELL_CAST_SUCCESS"][391528] = function(info, _, spellID)
	if info.talentData[434249] then
		spellID = spellID == 383410 and 194223 or (spellID == 390414 and 102560) or spellID
		local icon = info.spellIcons[spellID]
		if icon and icon.active then
			if not icon.maxcharges or icon.active == icon.maxcharges - 1 then
				local key = controlOfTheDreamIDs[spellID]
				icon:UpdateCooldown(min(GetTime() - (info.auras[key] or 0), 15))
			end
		end
	end

	if spellID == 391528 and info.talentData[429539] then
		info.auras.isChannelingConvoke = true
		info.bar:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", info.unit)
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][194223] = registeredEvents["SPELL_CAST_SUCCESS"][391528]
registeredEvents["SPELL_CAST_SUCCESS"][383410] = registeredEvents["SPELL_CAST_SUCCESS"][391528]
registeredEvents["SPELL_CAST_SUCCESS"][102560] = registeredEvents["SPELL_CAST_SUCCESS"][391528]
registeredEvents["SPELL_CAST_SUCCESS"][390414] = registeredEvents["SPELL_CAST_SUCCESS"][391528]
registeredEvents["SPELL_CAST_SUCCESS"][205636] = registeredEvents["SPELL_CAST_SUCCESS"][391528]
registeredEvents["SPELL_CAST_SUCCESS"][132158] = registeredEvents["SPELL_CAST_SUCCESS"][391528]



registeredEvents["SPELL_CAST_SUCCESS"][16979] = function(info)
	if info.talentData[443046] then
		local icon = info.spellIcons[102401]
		if icon and icon.active then
			icon:UpdateCooldown(3)
		end
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][102383] = registeredEvents["SPELL_CAST_SUCCESS"][16979]



registeredEvents["SPELL_DAMAGE"][164812] = function(info, _, spellID, _,_,_,_,_,_,_,_, timestamp)
	if spellID == 77758 and (info.spec ~= 104 or not info.talentData[429523]) then
		return
	end
	if info.auras.isChannelingConvoke and timestamp > (info.auras[spellID] or 0) then
		if info.spec == 102 then

			local icon = info.spellIcons[202770]
			if icon and icon.active then
				icon:UpdateCooldown(2)
			end
			icon = info.spellIcons[274281]
			if icon and icon.active then
				icon:UpdateCooldown(1)
			end
		elseif info.spec == 104 then
			local icon = info.spellIcons[204066]
			if icon and icon.active then
				icon:UpdateCooldown(3)
			end
		end
		info.auras[spellID] = timestamp
	end
end

registeredEvents["SPELL_DAMAGE"][78674] = registeredEvents["SPELL_DAMAGE"][164812]
registeredEvents["SPELL_DAMAGE"][191037] = registeredEvents["SPELL_DAMAGE"][164812]
registeredEvents["SPELL_DAMAGE"][77758] = registeredEvents["SPELL_DAMAGE"][164812]

registeredEvents["SPELL_AURA_APPLIED"][213708] = function(info)


	if info.auras.isChannelingConvoke then
		local icon = info.spellIcons[204066]
		if icon and icon.active then
			icon:UpdateCooldown(-3)
		end
	end
end
registeredEvents["SPELL_AURA_REFRESH"][213708] = registeredEvents["SPELL_AURA_APPLIED"][213708]

registeredEvents["SPELL_CAST_SUCCESS"][164812] = function(info)
	if info.auras.isChannelingConvoke then
		info.auras.isChannelingConvoke = nil
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][77758] = registeredEvents["SPELL_CAST_SUCCESS"][164812]








E.majorMovementAbilities = {
	[381732] = { 48265, 444347 },
	[381741] = { 195072, 189110 },
	[381746] = { 1850, 252216 },
	[381748] = 358267,
	[381749] = 186257,
	[381750] = { 1953, 212653 },
	[381751] = { 109132, 115008 },
	[381752] = 190784,

	[381754] = 2983,
	[381756] = { 79206, 58875, 192063 },
	[381757] = 48020,
	[381758] = 6544,
}

E.majorMovementAbilitiesByIDs = {}
for buffID, spellID in pairs(E.majorMovementAbilities) do
	if type(spellID) == "table" then
		for _, id in pairs(spellID) do
			E.majorMovementAbilitiesByIDs[id] = buffID
		end
	else
		E.majorMovementAbilitiesByIDs[spellID] = buffID
	end
end

local updateCDonBronzeRemoval = {
	[381732] = true,
	[381741] = true,
	[381748] = true,
	[381750] = true,
	[381751] = true,
	[381752] = true,

	[381758] = true,
}

registeredEvents["SPELL_AURA_REMOVED"][381748] = function(_,_, spellID, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo and destInfo.auras.mult_blessingOfTheBronze then
		if updateCDonBronzeRemoval[spellID] then
			local id = E.majorMovementAbilities[spellID]
			if type(id) == "table" then
				for _, target in pairs(id) do
					local icon = destInfo.spellIcons[target]
					if icon and icon.active then
						icon:UpdateCooldown(0, 1/0.85)
					end
				end
			else
				local icon = destInfo.spellIcons[id]
				if icon and icon.active then
					icon:UpdateCooldown(0, 1/0.85)
				end
			end
		end
		destInfo.auras.mult_blessingOfTheBronze = nil
	end
end

registeredEvents["SPELL_AURA_REMOVED"][381732] = registeredEvents["SPELL_AURA_REMOVED"][381748]
registeredEvents["SPELL_AURA_REMOVED"][381741] = registeredEvents["SPELL_AURA_REMOVED"][381748]
registeredEvents["SPELL_AURA_REMOVED"][381746] = registeredEvents["SPELL_AURA_REMOVED"][381748]
registeredEvents["SPELL_AURA_REMOVED"][381749] = registeredEvents["SPELL_AURA_REMOVED"][381748]
registeredEvents["SPELL_AURA_REMOVED"][381750] = registeredEvents["SPELL_AURA_REMOVED"][381748]
registeredEvents["SPELL_AURA_REMOVED"][381751] = registeredEvents["SPELL_AURA_REMOVED"][381748]
registeredEvents["SPELL_AURA_REMOVED"][381752] = registeredEvents["SPELL_AURA_REMOVED"][381748]

registeredEvents["SPELL_AURA_REMOVED"][381754] = registeredEvents["SPELL_AURA_REMOVED"][381748]
registeredEvents["SPELL_AURA_REMOVED"][381756] = registeredEvents["SPELL_AURA_REMOVED"][381748]
registeredEvents["SPELL_AURA_REMOVED"][381757] = registeredEvents["SPELL_AURA_REMOVED"][381748]
registeredEvents["SPELL_AURA_REMOVED"][381758] = registeredEvents["SPELL_AURA_REMOVED"][381748]

registeredEvents["SPELL_AURA_APPLIED"][381748] = function(_,_, spellID, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo and not destInfo.auras.mult_blessingOfTheBronze then
		local id = E.majorMovementAbilities[spellID]
		if type(id) == "table" then
			for _, target in pairs(id) do
				local icon = destInfo.spellIcons[target]
				if icon and icon.active then
					icon:UpdateCooldown(0, 0.85)
				end
			end
		else
			local icon = destInfo.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(0, 0.85)
			end
		end
		destInfo.auras.mult_blessingOfTheBronze = true
	end
end

registeredEvents["SPELL_AURA_APPLIED"][381732] = registeredEvents["SPELL_AURA_APPLIED"][381748]
registeredEvents["SPELL_AURA_APPLIED"][381741] = registeredEvents["SPELL_AURA_APPLIED"][381748]
registeredEvents["SPELL_AURA_APPLIED"][381746] = registeredEvents["SPELL_AURA_APPLIED"][381748]
registeredEvents["SPELL_AURA_APPLIED"][381749] = registeredEvents["SPELL_AURA_APPLIED"][381748]
registeredEvents["SPELL_AURA_APPLIED"][381750] = registeredEvents["SPELL_AURA_APPLIED"][381748]
registeredEvents["SPELL_AURA_APPLIED"][381751] = registeredEvents["SPELL_AURA_APPLIED"][381748]
registeredEvents["SPELL_AURA_APPLIED"][381752] = registeredEvents["SPELL_AURA_APPLIED"][381748]

registeredEvents["SPELL_AURA_APPLIED"][381754] = registeredEvents["SPELL_AURA_APPLIED"][381748]
registeredEvents["SPELL_AURA_APPLIED"][381756] = registeredEvents["SPELL_AURA_APPLIED"][381748]
registeredEvents["SPELL_AURA_APPLIED"][381757] = registeredEvents["SPELL_AURA_APPLIED"][381748]
registeredEvents["SPELL_AURA_APPLIED"][381758] = registeredEvents["SPELL_AURA_APPLIED"][381748]

auraMultString[381748] = "mult_blessingOfTheBronze"
auraMultString[381732] = "mult_blessingOfTheBronze"
auraMultString[381741] = "mult_blessingOfTheBronze"
auraMultString[381746] = "mult_blessingOfTheBronze"
auraMultString[381749] = "mult_blessingOfTheBronze"
auraMultString[381750] = "mult_blessingOfTheBronze"
auraMultString[381751] = "mult_blessingOfTheBronze"
auraMultString[381752] = "mult_blessingOfTheBronze"

auraMultString[381754] = "mult_blessingOfTheBronze"
auraMultString[381756] = "mult_blessingOfTheBronze"
auraMultString[381757] = "mult_blessingOfTheBronze"
auraMultString[381758] = "mult_blessingOfTheBronze"


registeredEvents["SPELL_AURA_REMOVED"][375234] = function(info, srcGUID, spellID, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo then
		destInfo.auras.mult_timeSpiral = nil
	end
	if spellID == 375234 then
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
	end
end

registeredEvents["SPELL_AURA_REMOVED"][375226] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375229] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375230] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375238] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375240] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375252] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375253] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375254] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375255] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375256] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375257] = registeredEvents["SPELL_AURA_REMOVED"][375234]
registeredEvents["SPELL_AURA_REMOVED"][375258] = registeredEvents["SPELL_AURA_REMOVED"][375234]

registeredEvents["SPELL_AURA_APPLIED"][375234] = function(_,_,_, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo then
		destInfo.auras.mult_timeSpiral = true
	end
end

registeredEvents["SPELL_AURA_APPLIED"][375226] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375229] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375230] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375238] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375240] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375252] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375253] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375254] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375255] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375256] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375257] = registeredEvents["SPELL_AURA_APPLIED"][375234]
registeredEvents["SPELL_AURA_APPLIED"][375258] = registeredEvents["SPELL_AURA_APPLIED"][375234]

auraMultString[375234] = "mult_timeSpiral"
auraMultString[375226] = "mult_timeSpiral"
auraMultString[375229] = "mult_timeSpiral"
auraMultString[375230] = "mult_timeSpiral"
auraMultString[375238] = "mult_timeSpiral"
auraMultString[375240] = "mult_timeSpiral"
auraMultString[375252] = "mult_timeSpiral"
auraMultString[375253] = "mult_timeSpiral"
auraMultString[375254] = "mult_timeSpiral"
auraMultString[375255] = "mult_timeSpiral"
auraMultString[375256] = "mult_timeSpiral"
auraMultString[375257] = "mult_timeSpiral"
auraMultString[375258] = "mult_timeSpiral"


registeredEvents["SPELL_PERIODIC_DAMAGE"][356995] = function(info, _,_,_,_,_,_,_,_,_,_, timestamp)
	if info.talentData[375777] and timestamp > (info.auras.time_disintegrate or 0) then
		local icon = info.spellIcons[357208]
		if icon and icon.active then
			icon:UpdateCooldown(.5)
		end
		icon = info.spellIcons[359073]
		if icon and icon.active then
			icon:UpdateCooldown(.5)
		end
		info.auras.time_disintegrate = timestamp
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][357211] = function(info)
	if info.talentData[375777] then
		info.auras.numHits_pyre = 0
	end
end

registeredEvents["SPELL_DAMAGE"][357212] = function(info, srcGUID)
	if info.auras.numHits_pyre and info.auras.numHits_pyre < 5 then
		local icon = info.spellIcons[357208]
		if icon and icon.active then
			icon:UpdateCooldown(0.4)
		end
		icon = info.spellIcons[359073]
		if icon and icon.active then
			icon:UpdateCooldown(0.4)
		end
		info.auras.numHits_pyre = info.auras.numHits_pyre + 1
	end
end


registeredEvents["SPELL_AURA_APPLIED"][370818] = function(info)
	info.auras.mult_snapFire = true
end

registeredEvents["SPELL_AURA_REMOVED"][370818] = function(info)
	info.auras.mult_snapFire = nil
end

auraMultString[370818] = "mult_snapFire"


registeredEvents["SPELL_SUMMON"][368415] = function(info)
	local icon = info.spellIcons[368412]
	if icon then
		icon:StartCooldown()
	end
end



local UpdateAllBars_OnDelayEnd = function()
	P:UpdateAllBars()
end

registeredEvents["SPELL_CAST_SUCCESS"][408233] = function(info, _,_, destGUID)
	C_Timer_After(0.5, UpdateAllBars_OnDelayEnd)
end








local bombardmentSource = {}
local bombardmentTarget = {}

local hasNewMark
registeredEvents["SPELL_AURA_APPLIED"][434473] =  function(info, srcGUID, _, destGUID)
	hasNewMark = true
	bombardmentSource[destGUID] = srcGUID
end

registeredEvents["SPELL_AURA_REMOVED"][434473] =  function(info, srcGUID, _, destGUID, _,_,_,_,_,_,_, timestamp)
	hasNewMark = nil
	C_Timer_After(1, function()
		if not hasNewMark then
			bombardmentSource[destGUID] = nil
		end
	end)
end

local numBarbardmentHits = 0
local ReduceDeepBreathCD_OnDelayEnd = function()
	for tar in pairs(bombardmentTarget) do
		local src = bombardmentSource[tar]
		if src then
			local srcInfo = groupInfo[src]
			if srcInfo then
				local icon = srcInfo.spellIcons[357210] or srcInfo.spellIcons[371032] or srcInfo.spellIcons[403631]
				if icon and icon.active then
					icon:UpdateCooldown(min(3, numBarbardmentHits))
				end
			end
		end
	end
end

local lastBombardmentTime = 0
local function OnBombardmentDamage(destGUID, timestamp)
	if timestamp > lastBombardmentTime then
		for tar in pairs(bombardmentTarget) do
			bombardmentTarget[tar] = nil
		end
		bombardmentTarget[destGUID] = true
		numBarbardmentHits = 1
		lastBombardmentTime = timestamp
		C_Timer_After(0, ReduceDeepBreathCD_OnDelayEnd)
	else
		numBarbardmentHits = numBarbardmentHits + 1
		bombardmentTarget[destGUID] = true
	end
end

local shouldTrackBombardment
function CD:UpdateBombardiers(value)
	shouldTrackBombardment = value
	if not value then
		for _, info in pairs(groupInfo) do
			if info.isWingleader then
				shouldTrackBombardment = true
				break
			end
		end
	end
end


registeredEvents["SPELL_AURA_APPLIED"][1215550] = function(info, _, srcGUID, destGUID)
	if info.talentData[1215610] and srcGUID == destGUID then
		local icon = info.spellIcons[360995]
		if icon and icon.active then
			icon:UpdateCooldown(P.isPvP and 2 or 4)
		end
	end
end







local ReduceTranquilizerCD_OnDelayEnd = function(srcGUID)
	local info = groupInfo[srcGUID]
	if info then
		if info.auras.tranquilizedSchool == 1 then
			local icon = info.spellIcons[19801]
			if icon and icon.active then
				icon:UpdateCooldown(5)
			end
		end
		info.auras.tranquilizedSchool = nil
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][19801] = function(info, srcGUID)
	if info.talentData[459991] then
		local icon = info.spellIcons[19801]
		if icon then
			C_Timer_After(0.5, function() ReduceTranquilizerCD_OnDelayEnd(srcGUID) end)
		end
	end
end

registeredEvents["SPELL_DISPEL"][19801] = function(info, _,_,_,_,_,_,_,_,_,_,_, extraSchool)
	if info.talentData[459991] then
		local school = info.auras.tranquilizedSchool
		school =  school and school * band(extraSchool, 1) or band(extraSchool, 1)
		info.auras.tranquilizedSchool = school
	end
end


local focusSpenders = {
	[19434] = 35,
	[185358] = 40,
	[120360] = 40,
	[466930] = 10,
	[186387] = 10,
	[212436] = 30,
	[193455] = 35,
	[208652] = 30,
	[34026] = 30,
	[53351] = 10,
	[320976] = 10,
	[2643] = 40,
	[257620] = 30,
	[212431] = 20,
	[269751] = 15,
	[259387] = 30,
	[186270] = 30,
	[265189] = 30,
	[982] = 35,
	[1513] = 25,
	[259495] = 10,
	[195645] = 20,
}

local function ReduceNaturalMendingCD(info, _, spellID)
	if not info.talentData[270581] then
		return
	end
	local icon = info.spellIcons[109304]
	if icon and icon.active then
		local f = focusSpenders[spellID]
		if info.spec == 253 then
			if spellID == 193455 then
				if info.talentData[378244] then
					f = f - 5
				end
			end
		elseif info.spec == 254 then
			if spellID == 19434 then
				if info.auras.rrt_lockAndLoad then
					return
				end
				local sl = info.auras.rrt_streamline
				if sl then
					f = f * (1 - (info.auras.mult_trueshot and info.talentData[471366] and 0.3 or 0.2 ) * sl)
				end
			elseif spellID == 185358 or spellID == 257620 then
				if info.auras.rrt_preciseShots then
					f = f * 0.6
				end
			end
		end

		icon:UpdateCooldown(f * (info.talentData[343242] and 0.15 or 0.1))
	end
end

for id in pairs(focusSpenders) do
	registeredEvents["SPELL_CAST_SUCCESS"][id] = ReduceNaturalMendingCD
end

registeredEvents["SPELL_AURA_APPLIED"][260242] = function(info) info.auras.rrt_preciseShots = true end
local RemovePreciseShots_OnDelayEnd = function(srcGUID)
	local info = groupInfo[srcGUID]
	if info then
		info.auras.rrt_preciseShots = nil
	end
end
registeredEvents["SPELL_AURA_REMOVED"][260242] = function(_, srcGUID)
	C_Timer_After(0.2, function() RemovePreciseShots_OnDelayEnd(srcGUID) end)
end

registeredEvents["SPELL_AURA_APPLIED"][194594] = function(info) info.auras.rrt_lockAndLoad = true end
local RemoveLockAndLoad_OnDelayEnd = function(srcGUID)
	local info = groupInfo[srcGUID]
	if info then
		info.auras.rrt_lockAndLoad = nil
	end
end
registeredEvents["SPELL_AURA_REMOVED"][194594] = function(_, srcGUID)
	C_Timer_After(0.2, function() RemoveLockAndLoad_OnDelayEnd(srcGUID) end)
end

registeredEvents["SPELL_AURA_APPLIED"][342076] = function(info, _,_,_,_,_,_, amount) info.auras.rrt_streamline = amount or 1 end
registeredEvents["SPELL_AURA_APPLIED_DOSE"][342076] = registeredEvents["SPELL_AURA_APPLIED"][342076]
registeredEvents["SPELL_AURA_REMOVED"][342076] = function(info) info.auras.rrt_streamline = nil end


registeredEvents["SPELL_DAMAGE"][19434] = function(info, _,_,_,_,_,_,_,_,_,_, timestamp)
	if info.talentData[473378] then
		local icon = info.spellIcons[260243]
		if icon and icon.active then

			icon:UpdateCooldown(0.3)
		end
	end
end

registeredEvents["SPELL_DAMAGE"][257620] = function(info)
	if info.talentData[473378] then
		local icon = info.spellIcons[257044]
		if icon and icon.active then
			icon:UpdateCooldown(0.3)
		end
	end
end
registeredEvents["SPELL_DAMAGE"][260247] = registeredEvents["SPELL_DAMAGE"][257620]



registeredEvents["SPELL_CAST_SUCCESS"][185358] = function(info, _, spellID)
	ReduceNaturalMendingCD(info, _, spellID)

	if info.talentData[473522] and info.auras.rrt_preciseShots then
		local icon = info.spellIcons[212431]
		if icon and icon.active then
			icon:UpdateCooldown(2)
		end
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][257620] = registeredEvents["SPELL_CAST_SUCCESS"][185358]

registeredEvents["SPELL_CAST_SUCCESS"][19434] = function(info, _, spellID, destGUID)
	ReduceNaturalMendingCD(info, _, spellID)

	if info.talentData[473522] and info.auras.rrt_lockAndLoad then
		local icon = info.spellIcons[212431]
		if icon and icon.active then
			icon:UpdateCooldown(8)
		end
	end

	if info.auras.target_spottersMark and info.auras.target_spottersMark[destGUID] then
		local icon = info.spellIcons[288613]
		if icon and icon.active then
			icon:UpdateCooldown(info.talentData[474738] and 3 or 2)
		end
	end
end

registeredEvents["SPELL_AURA_APPLIED"][466872] = function(info, _,_, destGUID)
	if info.talentData[260404] then
		info.auras.target_spottersMark = info.auras.target_spottersMark or {}
		info.auras.target_spottersMark[destGUID] = true
	end
end

registeredEvents["SPELL_AURA_REMOVED"][466872] = function(info, _,_, destGUID)
	if info.auras.target_spottersMark and info.auras.target_spottersMark[destGUID] then
		info.auras.target_spottersMark[destGUID] = nil
	end
end

registeredEvents["SPELL_AURA_APPLIED"][1215057] = registeredEvents["SPELL_AURA_APPLIED"][466872]
registeredEvents["SPELL_AURA_REMOVED"][1215057] = registeredEvents["SPELL_AURA_REMOVED"][466872]


registeredEvents["SPELL_AURA_APPLIED"][385646] = function(info)
	local icon = info.spellIcons[186387] or info.spellIcons[213691]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end


registeredEvents["SPELL_AURA_APPLIED"][288613] = function(info)
	info.auras.mult_trueshot = true
	local icon = info.spellIcons[257044]
	if icon and icon.active then
		icon:UpdateCooldown(0, 0.6)
	end
end

registeredEvents["SPELL_AURA_REMOVED"][288613] = function(info, srcGUID, spellID, destGUID)
	info.auras.mult_trueshot = nil
	local icon = info.spellIcons[257044]
	if icon and icon.active then
		icon:UpdateCooldown(0, 1/0.6)
	end
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end

auraMultString[288613] = "mult_trueshot"


registeredEvents["SPELL_AURA_REMOVED"][360952] = function(info, srcGUID, spellID, destGUID)
	if info.talentData[389880] then
		local icon = info.spellIcons[212431]
		if icon and icon.active then
			icon:ResetCooldown()
		end
	end
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end



registeredEvents["PARTY_KILL"]["HUNTER"] = function(info, _,_, destGUID)
	if not info.talentData[265895] then
		return
	end
	local unit = UnitTokenFromGUID(destGUID)
	if unit then
		local icon = info.spellIcons[190925]
		if icon and icon.active then
			icon:ResetCooldown()
		end
	end
end







registeredEvents["SPELL_AURA_APPLIED"][470488] = function(info)
	local icon = info.spellIcons[212431]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end


registeredEvents["SPELL_AURA_REMOVED_DOSE"][408518] = function(info, _,_,_,_,_,_,_,_,_,_, timestamp)
	if P.isPvP and info.talentData[248443] then
		local icon = info.spellIcons[186265]
		if icon and icon.active then
			if timestamp > (info.auras.time_rangersFinesse or 0) then
				icon:UpdateCooldown(20)
				info.auras.time_rangersFinesse = timestamp + 1
			end
		end
	end
end


registeredEvents["SPELL_DAMAGE"][450412] = function(info)
	local c = info.auras.numSentinelWatch
	if c then
		local icon = info.spellIcons[288613] or info.spellIcons[360952]
		if icon and icon.active then
			icon:UpdateCooldown(1)
			c = c - 1
			info.auras.numSentinelWatch = c > 0 and c or nil
		end
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][288613] = function(info, _, spellID)
	if info.spellIcons[spellID] and info.talentData[451546] then
		info.auras.numSentinelWatch = 15
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][360952] = function(info, _, spellID)
	if info.spellIcons[spellID] and info.talentData[451546] then
		info.auras.numSentinelWatch = 15
	end
end



registeredEvents["SPELL_DISPEL"][781] = function(info, _, spellID)
	if info.talentData[472719] then
		local icon = info.spellIcons[spellID]
		if icon and icon.active then
			icon:UpdateCooldown(4)
		end
	end
end







registeredEvents["SPELL_INTERRUPT"][2139] = function(info, _, spellID, _,_,_, extraSpellId, extraSpellName, _,_, destRaidFlags)
	if info.talentData[382297] then
		local icon = info.spellIcons[spellID]
		if icon and icon.active then
			icon:UpdateCooldown(4)
		end
	end
	AppendInterruptExtras(info, nil, spellID, nil,nil,nil, extraSpellId, extraSpellName, nil,nil, destRaidFlags)
end

registeredEvents["SPELL_CAST_SUCCESS"][2139] = function(info, _, spellID, destGUID)
	if info.talentData[382297] then
		local icon = info.spellIcons[spellID]
		if icon and icon.active then
			local unit = UnitTokenFromGUID(destGUID)
			if unit then
				local _,_,_,_,_,_, notInterruptable, channelID = UnitChannelInfo(unit)
				if notInterruptable ~= false then
					return
				end
				if channelID == 47758 then
					icon:UpdateCooldown(4)
				end
			end
		end
	end
end

--[[



registeredEvents["SPELL_SUMMON"][321686] = function(info, srcGUID, _, destGUID, _,_,_,_,_,_,_, ts)
	if not info.talentData[382569] or not info.spellIcons[55342] then
		return
	end
	if not info.auras.mirrorImages then
		info.auras.mirrorImages = {}
	end
	if ts > (info.auras.time_mirrorImages or 0) then
		for guid in pairs(info.auras.mirrorImages) do
			info.auras.mirrorImages[guid] = nil
			minionGUIDS[guid] = nil
		end
		info.auras.time_mirrorImages = ts
	end
	minionGUIDS[destGUID] = srcGUID
	info.auras.mirrorImages[destGUID] = true
end
]]


registeredEvents["SPELL_CAST_SUCCESS"][382445] = function(info)
	for id in pairs(info.active) do
		local icon = info.spellIcons[id]
		if icon and icon.active and icon.isBookType and id ~= 382440 and (id ~= 120 or not info.talentData[417493]) then
			icon:UpdateCooldown(3)
		end
	end
end


local mageLossOfControlAbilities = {
	[122] = true,
	[120] = true,
	[157997] = true,
	[113724] = true,
	[31661] = true,
	[383121] = true,
	[389794] = true,
	[157980] = true,
	[449700] = true,
	[353082] = true,
}


registeredEvents["SPELL_AURA_REMOVED"][263725] = function(info)
	info.auras.isClearcasting = nil
end

registeredEvents["SPELL_AURA_APPLIED"][263725] = function(info)
	if info.talentData[387807] then
		info.auras.isClearcasting = true
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][5143] = function(info)
	if not info.auras.isClearcasting then
		return
	end
	for id in pairs(mageLossOfControlAbilities) do
		local icon = info.spellIcons[id]
		if icon and icon.active and (id ~= 120 or info.talentData[386763]) then
			icon:UpdateCooldown(2)
		end
	end
end


registeredEvents["SPELL_CAST_SUCCESS"][319836] = function(info)
	if info.spec == 63 and info.talentData[387807] then
		for id in pairs(mageLossOfControlAbilities) do
			local icon = info.spellIcons[id]
			if icon and icon.active and (id ~= 120 or info.talentData[386763]) then
				icon:UpdateCooldown(2)
			end
		end
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][108853] = registeredEvents["SPELL_CAST_SUCCESS"][319836]


local frozenDebuffs = {
	[122] = true,
	[386770] = true,
	[157997] = true,
	[82691] = true,
	[228358] = true,
	[228600] = true,
	[33395] = true,
}

registeredEvents["SPELL_AURA_REMOVED"][44544] = function(info)
	info.auras.hasFingerOfFrost = nil
end

registeredEvents["SPELL_AURA_APPLIED"][44544] = function(info)
	info.auras.hasFingerOfFrost = true
end

registeredEvents["SPELL_CAST_SUCCESS"][30455] = function(info, _,_, destGUID)
	if info.talentData[387807] then
		if info.auras.hasFingerOfFrost then
			for id in pairs(mageLossOfControlAbilities) do
				local icon = info.spellIcons[id]
				if icon and icon.active and (id ~= 120 or (info.talentData[386763] and not info.talentData[417493])) then
					icon:UpdateCooldown(2)
				end
			end
		else
			local unit = UnitTokenFromGUID(destGUID)
			if unit and AuraUtil_ForEachAura then
				AuraUtil_ForEachAura(unit, "HARMFUL", nil, function(_,_,_,_,_,_,_,_,_, id)
					if frozenDebuffs[id] then
						for id in pairs(mageLossOfControlAbilities) do
							local icon = info.spellIcons[id]
							if icon and icon.active and (id ~= 120 or (info.talentData[386763] and not info.talentData[417493])) then
								icon:UpdateCooldown(2)
							end
						end
						return true
					end
				end)
			end
		end
	end
end



registeredEvents["SPELL_AURA_REMOVED"][342246] = function(info, srcGUID, spellID, destGUID)
	if info.talentData[342249] then
		local icon = info.spellIcons[1953] or info.spellIcons[212653]
		if icon and icon.active then
			icon:ResetCooldown()

			local talentRank = info.talentData[382268]
			if talentRank then
				icon:UpdateCooldown(2 * talentRank)
			end
		end
	end
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end



local fireMageDirectDamageIDs = {

	11366,
	319836,
	108853,
	2948,
	257542,
	468655,
}

local function ReduceDirectDamageCD(info, _, spellID, destGUID, critical)
	if spellID == 257542 and destGUID ~= info.auras.target_phoenixFlame then
		return
	end
	local icon = info.spellIcons[190319]
	if icon and icon.active then
		local cdr
		if critical and info.talentData[155148] then
			cdr = 1
		end
		if info.auras.isCombustion and info.talentData[416506] then
			cdr = cdr and cdr + 1.25 or 1.25
		end
		if cdr then
			icon:UpdateCooldown(cdr)
		end
		if spellID == 257542 then
			info.auras.target_phoenixFlame = nil
		end
	end
end

for _, id in pairs(fireMageDirectDamageIDs) do
	registeredEvents["SPELL_DAMAGE"][id] = ReduceDirectDamageCD
end

--[[
registeredEvents["SPELL_CAST_SUCCESS"][257541] = function(info, _,_, destGUID)
	info.auras.target_phoenixFlame = destGUID
end
]]

registeredEvents["SPELL_CAST_SUCCESS"][2120] = function(info)
	if info.talentData[155148] or info.talentData[416506] then
		info.auras.numHits_flamestrike = 0
	end
end

registeredEvents["SPELL_DAMAGE"][2120] = function(info, _,_,_, critical)
	if critical then
		local c = info.auras.numHits_flamestrike or 0
		local icon = info.spellIcons[190319]
		if icon and icon.active and c < 5 then
			local cdr
			if info.talentData[155148] then
				cdr = 0.2
			end
			if info.auras.isCombustion and info.talentData[416506] then
				cdr = cdr and cdr + 0.25 or 0.25
			end
			if cdr then
				icon:UpdateCooldown(cdr)
			end
			info.auras.numHits_flamestrike = c + 1
		end
	end
end

registeredEvents["SPELL_AURA_APPLIED"][190319] = function(info)
	info.auras.isCombustion = true
end

registeredEvents["SPELL_AURA_REMOVED"][190319] = function(info, srcGUID, spellID, destGUID)
	info.auras.isCombustion = nil
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end


registeredEvents["SPELL_AURA_APPLIED"][190446] = function(info)
	local icon = info.spellIcons[44614]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end


registeredEvents["SPELL_CAST_SUCCESS"][120] = function(info)
	if info.talentData[417493] then
		info.auras.numHits_coneOfCold = 0
	end
end

registeredEvents["SPELL_DAMAGE"][120] = function(info)
	if info.talentData[417493] then
		info.auras.numHits_coneOfCold = (info.auras.numHits_coneOfCold or 0) + 1
		if info.auras.numHits_coneOfCold == 3 then
			local icon = info.spellIcons[153595]
			if icon and icon.active then
				icon:ResetCooldown()
			end
			icon = info.spellIcons[84714]
			if icon and icon.active then
				icon:ResetCooldown()
			end
		end
	end
end


registeredEvents["SPELL_DAMAGE"][190357] = function(info)
	if info.talentData[236662] then
		local icon = info.spellIcons[84714]
		if icon and icon.active then
			icon:UpdateCooldown(.5)
		end
	end
end


local reduceBlinkCD = function(srcGUID)
	local info = groupInfo[srcGUID]
	if info and info.auras.numEtherealBlinkSlow then
		local icon = info.spellIcons[1953] or info.spellIcons[212653]
		if icon and icon.active and info.auras.numEtherealBlinkSlow > 0 then
			icon:UpdateCooldown(min(5, info.auras.numEtherealBlinkSlow))
		end
		info.auras.numEtherealBlinkSlow = nil
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][1953] = function(info, srcGUID)
	if P.isPvP and info.talentData[410939] and (info.spellIcons[1953] or info.spellIcons[212653]) then
		info.auras.numEtherealBlinkSlow = 0
		C_Timer_After(0.3, function() reduceBlinkCD(srcGUID) end)
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][212653] = registeredEvents["SPELL_CAST_SUCCESS"][1953]

registeredEvents["SPELL_AURA_APPLIED"][31589] = function(info)
	if info.auras.numEtherealBlinkSlow then
		info.auras.numEtherealBlinkSlow = info.auras.numEtherealBlinkSlow + 1
	end
end
registeredEvents["SPELL_AURA_REFRESH"][31589] = registeredEvents["SPELL_AURA_APPLIED"][31589]
registeredEvents["SPELL_MISSED"][31589] = registeredEvents["SPELL_AURA_APPLIED"][31589]


registeredEvents["SPELL_AURA_APPLIED"][438611] = function(info)
	info.auras.hasExcessFrost = true
end

registeredEvents["SPELL_AURA_REMOVED"][438611] = function(info)
	info.auras.hasExcessFrost = nil
end

registeredEvents["SPELL_CAST_SUCCESS"][44614] = function(info)
	if info.auras.hasExcessFrost then
		local icon = info.spellIcons[153595]
		if icon and icon.active then
			icon:UpdateCooldown(3)
		end
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][257541] = function(info, _,_, destGUID)
	if info.auras.hasExcessFrost then
		local icon = info.spellIcons[153561]
		if icon and icon.active then
			icon:UpdateCooldown(5)
		end
	end
	info.auras.target_phoenixFlame = destGUID
end



local fireMageFrostSpellIDs = {
	120,
	122,
	113724,
	157997,
	108839,

}

registeredEvents["SPELL_AURA_APPLIED"][87023] = function(info, srcGUID, spellID)

	if not E.postDF and E.spell_auraapplied_processspell[spellID] then
		info:ProcessSpell(spellID)
	end

	for _, id in pairs(fireMageFrostSpellIDs) do
		local icon = info.spellIcons[id]
		if icon and icon.active then
			icon:ResetCooldown(true)
		end
	end
end


registeredEvents["SPELL_AURA_APPLIED"][458411] = function(info)
	local icon = info.spellIcons[84714]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end



registeredEvents["SPELL_CAST_SUCCESS"][190319] = function(info, _, spellID)
	if info.talentData[1215132] then
		local icon = info.spellIcons[spellID]
		if icon and icon.active then
			icon:UpdateCooldown(P.isPvP and 2 or 4)
		end
	end
end







registeredEvents["SPELL_INTERRUPT"][116705] = function(info, _, spellID, _,_,_, extraSpellId, extraSpellName, _,_, destRaidFlags)
	if info.talentData[450631] then
		local icon = info.spellIcons[115078]
		if icon and icon.active then
			icon:UpdateCooldown(5)
		end
	end
	AppendInterruptExtras(info, nil, spellID, nil,nil,nil, extraSpellId, extraSpellName, nil,nil, destRaidFlags)
end





registeredEvents["SPELL_AURA_REMOVED"][394112] = function(info)
	if info and info.auras.hasEscapeFromReality then
		info.auras.hasEscapeFromReality = nil
		local icon = info.spellIcons[119996]
		if icon and not icon.active then
			icon:StartCooldown(35)
		end
	end
end

registeredEvents["SPELL_AURA_APPLIED"][394112] = function(info)
	if info.spellIcons[119996] then
		info.auras.hasEscapeFromReality = true
	end
end


local monkBrews = {
	115203,
	322507,
	119582,
	115399,
}

local function TigerPalmCDR(info)
	if info.spec ~= 268 then
		return
	end
	local rCD = info.talentData[389942] and 1.5 or 1
	rCD = P.isPvP and info.talentData[202107] and rCD/2 or rCD
	for _, id in ipairs(monkBrews) do
		local icon = info.spellIcons[id]
		if icon and icon.active then
			icon:UpdateCooldown(rCD)
		end
	end
end

local function KegSmashCDR(info)
	local rCD = info.auras.hasBlackoutCombo and 5 or 3
	for _, id in ipairs(monkBrews) do
		local icon = info.spellIcons[id]
		if icon and icon.active then

			icon:UpdateCooldown(id == 115203 and P.isPvP and info.talentData[202107] and rCD * 1.5 or rCD)
		end
	end
end






local function ReduceBrewCD(destInfo, _,_, missType, _,_, timestamp)
	local talentRank = destInfo.talentData[386937]
	if talentRank and (missType == "DODGE" or missType == "MISS" ) then
		for i = 1, 4 do
			local id = monkBrews[i]
			local icon = destInfo.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(talentRank / 2)
			end
		end
	end
end

registeredHostileEvents["SWING_MISSED"]["MONK"] = function(destInfo,_,spellID,_,_,_,timestamp) ReduceBrewCD(destInfo,nil,nil,spellID,nil,nil,timestamp) end
registeredHostileEvents["RANGE_MISSED"]["MONK"] = ReduceBrewCD
registeredHostileEvents["SPELL_MISSED"]["MONK"] = ReduceBrewCD


registeredEvents["SPELL_AURA_APPLIED"][228563] = function(info)
	info.auras.hasBlackoutCombo = true
end

registeredEvents["SPELL_AURA_REMOVED"][228563] = function(info)
	info.auras.hasBlackoutCombo = nil
end


registeredEvents["SPELL_AURA_APPLIED"][393786] = function(info)
	local active = info.active[387184]
	if active then
		active.numHits = (active.numHits or 0) + 1
		if active.numHits <= 5 then
			local icon = info.spellIcons[387184]
			if icon and icon.active then
				icon:UpdateCooldown(4)
			end
		end
	end
end



registeredEvents["SPELL_AURA_APPLIED"][418361] = function(info, _,_,_, isOffhand)
	if info.talentData[418359] then
		for i = 1, 4 do
			local id = monkBrews[i]
			local icon = info.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(0.5)
			end
		end
	end
end

registeredEvents["SPELL_AURA_APPLIED_DOSE"][418361] = function(info, _,_,_,_,_,_, amount)
	if amount == 2 and info.talentData[418359] then
		for i = 1, 4 do
			local id = monkBrews[i]
			local icon = info.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(0.5)
			end
		end
	end
end

registeredEvents["SPELL_AURA_REFRESH"][418361] = registeredEvents["SPELL_AURA_APPLIED"][418361]



registeredEvents["SPELL_DAMAGE"][121253] = function(info, _,_,_,_,_,_,_,_,_,_, timestamp)
	local talentRank = info.talentData[322120] and info.talentData[387219]
	if talentRank then
		local icon = info.spellIcons[132578]
		if icon and icon.active then
			if timestamp > (info.auras.time_shuffle or 0) then
				icon:UpdateCooldown(.25 * talentRank)
				info.auras.time_shuffle = timestamp + .1
			end
		end
	end
end

registeredEvents["SPELL_DAMAGE"][107270] = registeredEvents["SPELL_DAMAGE"][121253]
registeredEvents["SPELL_DAMAGE"][205523] = registeredEvents["SPELL_DAMAGE"][121253]


registeredEvents["SPELL_AURA_APPLIED"][388203] = function(info)
	local icon = info.spellIcons[388193]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end



registeredEvents["SPELL_HEAL"][116670] = function(info, _,_,_,_,_,_,_,_, criticalHeal)
	if info.talentData[388551] and criticalHeal then
		local icon = info.spellIcons[115310] or info.spellIcons[388615]
		if icon and icon.active then
			icon:UpdateCooldown(1)
		end
	end
end

registeredEvents["SPELL_DAMAGE"][185099] = function(info, _,_,_, critical)
	if info.talentData[388551] then
		local icon = info.spellIcons[115310] or info.spellIcons[388615]
		if icon and icon.active then
			icon:UpdateCooldown(1)
		end
	end

	if critical and info.talentData[392993] then
		local icon = info.spellIcons[113656]
		if icon and icon.active then
			icon:UpdateCooldown(P.isPvP and 2 or 4)
		end
	end
end
registeredEvents["SPELL_DAMAGE"][467307] = registeredEvents["SPELL_DAMAGE"][185099]



local wwChiSpenders = {
	[113656] = 3,
	[392983] = 2,
	[107428] = 2,
	[100784] = 1,
	[101546] = 2,
}

local function ReduceSEFCD(info, _, spellID)
	if info.talentData[280197] then
		local icon = info.spellIcons[137639]
		if icon and icon.active then
			local c = wwChiSpenders[spellID]
			--[[ all cost reduction are ignored
			if spellID == 101546 then
				if info.auras.rrt_danceOfChiJi then
					return
				end
			if spellID == 100784 then
				if info.auras.rrt_blackotKick then
					return
				end
			end
			if info.auras.rrt_orderedElements then
				c = c - 1
			end
			]]

			c = (info.auras.remainderChi or 0) + c
			local rem
			if c >= 2 then
				rem = c%2
				icon:UpdateCooldown((c-rem) / 4)
			end
			info.auras.remainderChi = rem or c
		end
	end
end

for id in pairs(wwChiSpenders) do
	registeredEvents["SPELL_CAST_SUCCESS"][id] = ReduceSEFCD
end

--[[
registeredEvents["SPELL_CAST_SUCCESS"][137639] = function(info)
	local icon = info.spellIcons[137639]
	if not icon.active or icon.maxcharges and icon.maxcharges == icon.active + 1 then
		info.auras.remainderChi = 0
	end
end
]]

registeredEvents["SPELL_AURA_APPLIED"][325202] = function(info) info.auras.rrt_danceOfChiJi = true end
registeredEvents["SPELL_AURA_REMOVED"][325202] = function(info) info.auras.rrt_danceOfChiJi = nil end
registeredEvents["SPELL_AURA_APPLIED"][116768] = function(info) info.auras.rrt_blackotKick = true end
registeredEvents["SPELL_AURA_REMOVED"][116768] = function(info) info.auras.rrt_blackotKick = nil end
registeredEvents["SPELL_AURA_APPLIED"][451462] = function(info) info.auras.rrt_orderedElements = true end
registeredEvents["SPELL_AURA_REMOVED"][451462] = function(info) info.auras.rrt_orderedElements = nil end


local stunDebuffs = {
	108194,
	221562,
	91800,
	91797,

	210141,
	377048,
	179057,
	211881,
	205630,
	208618,
	200166,
	213491,
	5211,
	203123,
	163505,
	202244,
	372245,
	408544,
	117526,
	24394,
	357021,
	389831,
	119381,
	202346,
	853,
	255941,
	385149,
	64044,
	200200,
	408,
	1833,
	305485,
	118905,
	77505,
	118345,
	30283,
	89766,
	22703,
	213688,
	171017,
	171018,
	385954,
	46968,
	132168,
	132169,

	20549,
	255723,
	287712,
}

local function OnStunApplied(destInfo)
	if P.isPvP and destInfo.talentData[353584] and destInfo.spellIcons[119996] then
		destInfo.auras.isStunned = (destInfo.auras.isStunned or 0) + 1
	end
end

local function OnStunRemoved(destInfo)
	local c = destInfo.auras.isStunned
	if c and c > 0 then
		destInfo.auras.isStunned = c - 1
	end
end

for _, id in pairs(stunDebuffs) do
	registeredHostileEvents["SPELL_AURA_APPLIED"][id] = OnStunApplied
	registeredHostileEvents["SPELL_AURA_REMOVED"][id] = OnStunRemoved
end

registeredEvents["SPELL_CAST_SUCCESS"][119996] = function(info, _, spellID)
	local icon = info.spellIcons[spellID]
	if icon and not info.auras.hasEscapeFromReality then
		icon:StartCooldown(P.isPvP and info.talentData[353584] and (not info.auras.isStunned or info.auras.isStunned < 1) and icon.duration - 15 or icon.duration)
	end
end


registeredEvents["SPELL_DAMAGE"][322109] = function(info, _,_,_,_, destFlags, _, overkill)
	if overkill > -1 and info:IsTalentForPvpStatus(345829) and band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
		local icon = info.spellIcons[122470]
		if icon and icon.active then
			icon:UpdateCooldown(60)
		end
	end
end



local bmEnergySpenders = {

	[117952] = 20,
	[116095] = 15,
	[322101] = 15,
	[115078] = 20,
	[322729] = 25,
	[100780] = 25,
	[116670] = 30,
	[121253] = 40,
	[115175] = 15,
	[218164] = 10,
}

local wwEnergySpenders = {
	[117952] = 20,
	[116095] = 15,
	[115078] = 20,
	[100780] = 60,
	[116670] = 30,
	[115175] = 15,
	[218164] = 10,
}

local function ReduceWoOSEFCD(info, _, spellID)
	if spellID == 100780 then
		TigerPalmCDR(info)
	elseif spellID == 121253 then
		KegSmashCDR(info)
	end

	if not info.talentData[450989] then
		return
	end
	if info.spec == 268 then
		local icon = info.spellIcons[387184]
		if icon and icon.active then
			local e = bmEnergySpenders[spellID]
			if spellID == 116670 and info.auras.rrt_vivaciousVivification then
				e = e/4
			end

			e = (info.auras.remainderEnergy or 0) + e
			local rem
			if e >= 50 then
				rem = e%50
				icon:UpdateCooldown((e-rem) / 50)
			end
			info.auras.remainderEnergy = rem or e
		end
	elseif info.spec == 269 then
		local icon = info.spellIcons[137639]
		if icon and icon.active then
			local e = wwEnergySpenders[spellID]
			if spellID == 100780 then
				if info.talentData[397768] then
					e = e - 5
				end
			elseif spellID == 117952 then
				if info.auras.rrt_theEmperorsCapacitor then
					e = e * (1 - 0.05 * info.auras.rrt_theEmperorsCapacitor)
				end
			elseif spellID == 116670 then
				if info.auras.rrt_vivaciousVivification then
					e = e/4
				end
			end

			e = (info.auras.remainderEnergy or 0) + e
			local rem
			if e >= 50 then
				rem = e%50
				icon:UpdateCooldown((e-rem) / 50)
			end
			info.auras.remainderEnergy = rem or e
		end
	end
end

for id in pairs(bmEnergySpenders) do
	if id == 115175 then
		registeredEvents["SPELL_PERIODIC_HEAL"][id] = ReduceWoOSEFCD
	elseif id == 117952 then
		registeredEvents["SPELL_PERIODIC_DAMAGE"][id] = ReduceWoOSEFCD
	else
		registeredEvents["SPELL_CAST_SUCCESS"][id] = ReduceWoOSEFCD
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][387184] = function(info)
	info.auras.remainderEnergy = 0
end

registeredEvents["SPELL_CAST_SUCCESS"][137639] = function(info)
	local icon = info.spellIcons[137639]
	if icon and (not icon.active or icon.maxcharges and icon.maxcharges == icon.active + 1) then
		info.auras.remainderEnergy = 0
		info.auras.remainderChi = 0
	end
end

registeredEvents["SPELL_AURA_APPLIED"][393039] = function(info, _,_,_,_,_,_, amount) info.auras.rrt_theEmperorsCapacitor = amount or 1 end
registeredEvents["SPELL_AURA_APPLIED_DOSE"][393039] = registeredEvents["SPELL_AURA_APPLIED"][393039]
registeredEvents["SPELL_AURA_REMOVED"][393039] = function(info) info.auras.rrt_theEmperorsCapacitor = nil end
registeredEvents["SPELL_AURA_APPLIED"][392883] = function(info) info.auras.rrt_vivaciousVivification = true end
registeredEvents["SPELL_AURA_REMOVED"][392883] = function(info) info.auras.rrt_vivaciousVivification = nil end







registeredEvents["SPELL_AURA_APPLIED"][6940] = function(info, srcGUID, spellID, destGUID)
	if info.talentData[469279] and srcGUID ~= destGUID then
		local icon = info.spellIcons[spellID]
		if icon and not icon.active then
			icon:StartCooldown()
		end
	end
end
registeredEvents["SPELL_AURA_APPLIED"][199448] = registeredEvents["SPELL_AURA_APPLIED"][6940]



local holyPowerSpenders = {
	85673,
	156322,
	427453,
	53600,
	391054,
	85222,
	415091,
	2812,
	85256,
	383328,
	215661,
	53385,
	343527,
	384052,
	198034,
}

local righteousProtectorTargetIDs = {
	31884,
	389539,
	86659,
	228049
}

local function HolyPowerSpenderCDR(info, _, spellID, _,_,_,_,_,_,_,_, timestamp)
	if info.spec == 66 then

		local talentRank = info.talentData[385422]
		if talentRank then
			local icon = info.spellIcons[642]
			if icon and icon.active then
				icon:UpdateCooldown(talentRank)
			end
			icon = info.spellIcons[31850]
			if icon and icon.active then
				icon:UpdateCooldown(talentRank)
			end
		end


		if info.talentData[392928] then

				local icon = info.spellIcons[633]
				if icon and icon.active then
					icon:UpdateCooldown(3)
				end


		end

		if spellID == 427453 then
			return
		end


		if info.talentData[204074] then

				for _, id in pairs(righteousProtectorTargetIDs) do
					local icon = info.spellIcons[id]
					if icon and icon.active then
						icon:UpdateCooldown(P.isPvP and 1.0 or 1.5)
					end
				end


		end
	elseif spellID == 391054 then
		return
	else

		if info.talentData[414720] and spellID ~= 2812 then
			if timestamp > (info.auras.time_TD or 0) then
				local icon = info.spellIcons[633]
				if icon and icon.active then
					icon:UpdateCooldown(4.5)
				end
				info.auras.time_TD = timestamp + 0.5
			end
		end


		if info.talentData[1215613] then
			if timestamp > (info.auras.time_DT or 0) then
				local icon = info.spellIcons[375576]
				if icon and icon.active then
					icon:UpdateCooldown(P.isPvP and 0.5 or 1)
				end
				info.auras.time_TD = timestamp + 0.5
			end
		end
	end
end

for _, id in pairs(holyPowerSpenders) do
	registeredEvents["SPELL_CAST_SUCCESS"][id] = HolyPowerSpenderCDR
end

registeredEvents["SPELL_AURA_APPLIED"][327510] = function(info) info.auras.rrt_shiningLight = true end
registeredEvents["SPELL_AURA_REMOVED"][327510] = function(info) info.auras.rrt_shiningLight = nil end












local forbearanceIDs = E.isBCC and {
	[1022] = 0,
	[5599] = 0,
	[10278] = 0,
	[498] = 60,
	[5573] = 60,
	[642] = 60,
	[1020] = 60,
	[31884] = 60,
} or (E.isWOTLKC and {
	[1022] = 0,
	[633] = 0,
	[498] = 120,
	[642] = 120,
	[31884] = 30,
}) or (E.isCata and {
	[1022] = 0,
	[642] = 60,
	[633] = 0,
}) or {
	[1022] = 0,
	[204018] = 0,
	[642] = 30,
	[633] = 0,

}

registeredEvents["SPELL_AURA_REMOVED"][25771] = function(_,_,_, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo then
		for id in pairs(forbearanceIDs) do
			local icon = destInfo.preactiveIcons[id]
			if icon then
				destInfo.preactiveIcons[id] = nil
				icon:SetColorSaturation()
				if icon.statusBar then
					icon.statusBar:SetColors()
				end
			end
		end
	end
end

registeredEvents["SPELL_AURA_APPLIED"][25771] = function(_,_,_, destGUID)

	if not E.db.icons.showForbearanceCounter then
		return
	end
	local destInfo = groupInfo[destGUID]
	if destInfo then
		for id in pairs(forbearanceIDs) do
			if id ~= 642 or not destInfo.talentData[146956] then
				local icon = destInfo.spellIcons[id]
				if icon then
					destInfo.preactiveIcons[id] = icon
					icon:SetColorSaturation()
					if icon.statusBar then
						icon.statusBar:SetColors()
					end
				end
			end
		end
	end
end



registeredEvents["SPELL_AURA_APPLIED"][54149] = function(info)
	info.auras.hasInfusionOfLight = true
end

registeredEvents["SPELL_AURA_REMOVED"][54149] = function(info)
	info.auras.hasInfusionOfLight = nil
end


registeredEvents["SPELL_DAMAGE"][31935] = function(info)
	if info.talentData[378279] then
		local icon = info.spellIcons[86659] or info.spellIcons[228049]
		if icon and icon.active then
			icon:UpdateCooldown(1)
		end
	end
end


registeredEvents["SPELL_AURA_APPLIED"][85416] = function(info)
	local icon = info.spellIcons[31935]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end


registeredEvents["SPELL_AURA_REMOVED"][327193] = function(info, srcGUID, spellID, destGUID)
	info.auras.mult_momentOfGlory = nil
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end

registeredEvents["SPELL_AURA_APPLIED"][327193] = function(info)
	local icon = info.spellIcons[31935]
	if icon then
		if icon.active then
			icon:ResetCooldown()
		end
		info.auras.mult_momentOfGlory = true
	end
end

auraMultString[327193] = "mult_momentOfGlory"


registeredEvents["SPELL_AURA_APPLIED"][383283] = function(info)
	local icon = info.spellIcons[255937]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end


registeredEvents["SPELL_AURA_APPLIED"][383329] = function(info)
	local icon = info.spellIcons[24275]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end


registeredEvents["SPELL_HEAL"][633] = function(info, _,_, destGUID, _,_, amount, overhealing)
	local icon = info.spellIcons[633]
	if icon then
		local reducedTime
		if info.talentData[326734] then
			local unit = UnitTokenFromGUID(destGUID)
			if unit then
				local maxHP = UnitHealthMax(unit)
				if maxHP > 0 then
					local actualhealing = amount - overhealing
					local reducedMult = min(actualhealing / maxHP * 6/7, 0.6)
					reducedTime = icon.duration * reducedMult
				end
			end
		end
		icon:StartCooldown(nil, nil, nil, reducedTime)
	end
end
registeredEvents["SPELL_HEAL"][471195] = registeredEvents["SPELL_HEAL"][633]



local function ReduceLayOnHandsCD(info, srcGUID, _, destGUID)
	if srcGUID == destGUID then
		local icon = info.spellIcons[633]
		if icon and icon.active then
			icon:UpdateCooldown(15)
		end
	end
end

registeredEvents["SPELL_AURA_REMOVED"][432496] = function(info, srcGUID, spellID, destGUID)
	ReduceLayOnHandsCD(info, srcGUID, nil, destGUID)
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)


	local found
	AuraUtil_ForEachAura(info.unit, "HELPFUL", nil, function(_,_,_,_,_,_,_,_,_, id)
		if id == 432496 or id == 432502 then
			found = true
			return true
		end
	end)
	if not found then
		info.auras.isWieldingArnament = nil
	end
end

registeredEvents["SPELL_AURA_REMOVED"][432502] = registeredEvents["SPELL_AURA_REMOVED"][432496]
registeredEvents["SPELL_AURA_REFRESH"][432502] = ReduceLayOnHandsCD
registeredEvents["SPELL_AURA_REFRESH"][432496] = ReduceLayOnHandsCD

registeredEvents["SPELL_INTERRUPT"][96231] = function(info, _, spellID, _,_,_, extraSpellId, extraSpellName, _,_, destRaidFlags)
	if info.talentData[469886] then
		local icon = info.spellIcons[spellID]
		if icon and icon.active then
			icon:UpdateCooldown(info.auras.isWieldingArnament and 2 or 1)
		end
	end
	AppendInterruptExtras(info, nil, spellID, nil,nil,nil, extraSpellId, extraSpellName, nil,nil, destRaidFlags)
end

registeredEvents["SPELL_AURA_APPLIED"][432496] = function(info) info.auras.isWieldingArnament = true end
registeredEvents["SPELL_AURA_APPLIED"][432502] = registeredEvents["SPELL_AURA_APPLIED"][432496]








registeredEvents["SPELL_CAST_SUCCESS"][32379] = function(info, _,_, destGUID, _,_,_,_,_,_,_, timestamp)
	if info.talentData[321291] and info.spellIcons[32379] then
		if timestamp > (info.auras.time_shadowWordDeathReset or 0) then
			local unit = UnitTokenFromGUID(destGUID)
			if unit then
				local maxHP = UnitHealthMax(unit)
				if maxHP > 0 then
					info.auras.isDeathTargetUnder20 = UnitHealth(unit) / maxHP <= .2
				end
			end
		end
	end
end

registeredEvents["SPELL_DAMAGE"][32379] = function(info, _,_,_,_,_,_, overkill, _,_,_, timestamp)
	if info.talentData[321291] then
		if overkill == -1 and info.auras.isDeathTargetUnder20 then
			local icon = info.spellIcons[32379]
			if icon and icon.active then
				icon:ResetCooldown()
			end
			info.auras.time_shadowWordDeathReset = timestamp + 10
		end
		info.auras.isDeathTargetUnder20 = nil
	end
end


registeredEvents["SPELL_CAST_SUCCESS"][17] = function(info)
	if info.talentData[373035] then
		local icon = info.spellIcons[33206]
		if icon and icon.active then
			icon:UpdateCooldown(3)
		end
	end
end


local function GetHolyWordReducedTime(info, reducedTime)

	local naaruRank = info.talentData[196985]
	if naaruRank then
		reducedTime = reducedTime + reducedTime * (E.postDF and 0.1 * naaruRank or .33)
	end

	if info.auras.isApotheosisActive then
		reducedTime = reducedTime * 3
	end

	if info.talentData[453677] then
		reducedTime = reducedTime * (P.isPvP and 1.05 or 1.1)
	end

	return reducedTime
end

registeredEvents["SPELL_CAST_SUCCESS"][139] = function(info, _, spellID)
	local icon = info.spellIcons[34861]
	if icon and icon.active then
		local reducedTime = GetHolyWordReducedTime(info, spellID == 139 and (info.talentData[391339] and 8 or 2) or 6)
		--[[

		if spellID == 139 and info.talentData[391339] then
			reducedTime = reducedTime + 6
		end
		]]
		icon:UpdateCooldown(reducedTime)
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][596] = registeredEvents["SPELL_CAST_SUCCESS"][139]

registeredEvents["SPELL_CAST_SUCCESS"][2060] = function(info)
	local icon = info.spellIcons[2050]
	if icon and icon.active then
		local reducedTime = GetHolyWordReducedTime(info, 6)
		icon:UpdateCooldown(reducedTime)
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][2061] = registeredEvents["SPELL_CAST_SUCCESS"][2060]

registeredEvents["SPELL_CAST_SUCCESS"][585] = function(info)
	local icon = info.spellIcons[88625]
	if icon and icon.active then
		local reducedTime = GetHolyWordReducedTime(info, 4)
		icon:UpdateCooldown(reducedTime)
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][132157] = registeredEvents["SPELL_CAST_SUCCESS"][585]

registeredEvents["SPELL_CAST_SUCCESS"][2050] = function(info)
	local icon = info.spellIcons[372835]
	if icon and icon.active then
		local reducedTime = GetHolyWordReducedTime(info, 3)
		icon:UpdateCooldown(reducedTime)
	end
end
registeredEvents["SPELL_CAST_SUCCESS"][34861] = registeredEvents["SPELL_CAST_SUCCESS"][2050]



local function ReduceHolyWordCDsByVoiceOfHarmony(info, _, spellID)
	if info.talentData[390994] then
		if spellID == 33076 or spellID == 373481 then
			spellID = 2050
		elseif spellID == 120517 or spellID == 110744 then
			spellID = 34861
		elseif spellID == 14914 then
			spellID = 88625
		end

		local icon = info.spellIcons[spellID]
		if icon and icon.active then
			local reducedTime = GetHolyWordReducedTime(info, spellID == 88625 and P.isPvP and 2 or 4)
			icon:UpdateCooldown(reducedTime)
		end
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][33076] = ReduceHolyWordCDsByVoiceOfHarmony
registeredEvents["SPELL_CAST_SUCCESS"][373481] = ReduceHolyWordCDsByVoiceOfHarmony
registeredEvents["SPELL_CAST_SUCCESS"][120517] = ReduceHolyWordCDsByVoiceOfHarmony
registeredEvents["SPELL_CAST_SUCCESS"][110744] = ReduceHolyWordCDsByVoiceOfHarmony
registeredEvents["SPELL_CAST_SUCCESS"][14914] = ReduceHolyWordCDsByVoiceOfHarmony



registeredEvents["SPELL_AURA_REMOVED"][372760] = function(info, srcGUID, spellID, destGUID)
	info.auras.hasDivineWord = nil
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end

registeredEvents["SPELL_AURA_APPLIED"][372760] = function(info)
	info.auras.hasDivineWord = true
end

registeredEvents["SPELL_CAST_SUCCESS"][88625] = function(info)
	if info.auras.hasDivineWord then
		local icon = info.spellIcons[88625]
		if icon and icon.active then
			icon:UpdateCooldown(15)
		end
	end
end


registeredEvents["SPELL_AURA_REMOVED"][200183] = function(info, srcGUID, spellID, destGUID)
	info.auras.isApotheosisActive = nil
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end

registeredEvents["SPELL_AURA_APPLIED"][200183] = function(info)
	info.auras.isApotheosisActive = true
end


local onGSRemoval = function(srcGUID, spellID, destGUID)
	local info = groupInfo[srcGUID]
	if info then
		if info.auras.wasSavedByGS then
			info.auras.wasSavedByGS = nil
		else
			local icon = info.spellIcons[47788]
			if icon and info.talentData[200209] or info.talentData[63231] then
				icon:StartCooldown(60)
			end
		end
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
	end
end

registeredEvents["SPELL_AURA_REMOVED"][47788] = function(info, srcGUID, spellID, destGUID)
	local icon = info.spellIcons[47788]
	if icon then
		C_Timer_After(0.1, function() onGSRemoval(srcGUID, spellID, destGUID) end)
	end
end

registeredEvents["SPELL_HEAL"][48153] = function(info)
	if info.spellIcons[47788] then
		info.auras.wasSavedByGS = true
	end
end


registeredEvents["SPELL_AURA_APPLIED"][392511] = function(info)
	info.auras.mult_deathSpeaker = true
end

registeredEvents["SPELL_AURA_REMOVED"][392511] = function(info)
	info.auras.mult_deathSpeaker = nil
end

auraMultString[392511] = "mult_deathSpeaker"


registeredEvents["SPELL_AURA_APPLIED"][375981] = function(info)
	local icon = info.spellIcons[8092]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end


registeredEvents["SPELL_AURA_REMOVED"][194249] = function(info, srcGUID, spellID, destGUID)
	if info.callbackTimers.isVoidForm then
		if srcGUID ~= userGUID then
			info.callbackTimers.isVoidForm:Cancel()
		end
		info.callbackTimers.isVoidForm = nil
	end
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end
registeredEvents["SPELL_AURA_REMOVED"][391109] = registeredEvents["SPELL_AURA_REMOVED"][194249]

local RemoveVoidForm_OnDurationEnd
RemoveVoidForm_OnDurationEnd = function(srcGUID, spellID, destGUID)
	local info = groupInfo[srcGUID]
	if info and info.callbackTimers.isVoidForm then
		local duration, expTime = P:GetBuffDuration(info.unit, spellID)
		if duration and duration > 0 then
			duration = expTime - GetTime()
			if duration > 0 then
				info.callbackTimers.isVoidForm = C_Timer_NewTimer(duration + 1, function() RemoveVoidForm_OnDurationEnd(srcGUID, spellID, destGUID) end)
				return
			end
		end
		info.callbackTimers.isVoidForm = nil
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][194249] = function(info, srcGUID, spellID, destGUID)
	if P.isPvP and info.talentData[199259] and info.spellIcons[228260] then
		info.auras.isPvpAndDrivenToMadness = true
		info.callbackTimers.isVoidForm = srcGUID == userGUID or C_Timer_NewTimer(20.1, function() RemoveVoidForm_OnDurationEnd(srcGUID, spellID, destGUID) end)
	else
		info.auras.isPvpAndDrivenToMadness = nil
	end
end

registeredEvents["SPELL_AURA_APPLIED"][391109] = function(info, srcGUID, spellID, destGUID)
	if P.isPvP and info.talentData[199259] and info.spellIcons[391109] then
		info.auras.isPvpAndDrivenToMadness = true
		info.callbackTimers.isVoidForm = srcGUID == userGUID or C_Timer_NewTimer(20.1, function() RemoveVoidForm_OnDurationEnd(srcGUID, spellID, destGUID) end)
	else
		info.auras.isPvpAndDrivenToMadness = nil
	end
end

local function ReduceVoidEruptionCD(destInfo, _,_,_,_,_, timestamp, _,_, missType)
	if missType and missType ~= "ABSORB" then
		return
	end
	if destInfo.auras.isPvpAndDrivenToMadness and not destInfo.callbackTimers.isVoidForm then
		local icon = destInfo.spellIcons[228260] or destInfo.spellIcons[391109]
		if icon and icon.active then
			if timestamp > (destInfo.auras.time_drivenToMadness or 0) then
				icon:UpdateCooldown(3)
				destInfo.auras.time_drivenToMadness = timestamp + 1
			end
		end
	end
end

registeredHostileEvents["SWING_DAMAGE"]["PRIEST"] = ReduceVoidEruptionCD
registeredHostileEvents["RANGE_DAMAGE"]["PRIEST"] = ReduceVoidEruptionCD
registeredHostileEvents["SPELL_DAMAGE"]["PRIEST"] = ReduceVoidEruptionCD
registeredHostileEvents["SWING_MISSED"]["PRIEST"] = function(destInfo,_,spellID,_,_,_,timestamp) ReduceVoidEruptionCD(destInfo,nil,nil,nil,nil,nil,timestamp,nil,nil,spellID) end
registeredHostileEvents["RANGE_MISSED"]["PRIEST"] = function(destInfo,_,_,amount,_,_,timestamp) ReduceVoidEruptionCD(destInfo,nil,nil,nil,nil,nil,timestamp,nil,nil,amount) end
registeredHostileEvents["SPELL_MISSED"]["PRIEST"] = registeredHostileEvents["RANGE_MISSED"]["PRIEST"]


registeredEvents["SPELL_AURA_APPLIED"][322431] = function(info)
	local icon = info.spellIcons[316262]
	if icon then
		if icon.active then
			icon.cooldown:Clear()
		end
		info.preactiveIcons[316262] = icon
		icon:SetHighlight()
		icon:SetCooldownElements()
		icon:SetOpacity()
		icon:SetColorSaturation()
		if icon.statusBar then
			icon.statusBar:SetColors()
		end
	end
end

registeredEvents["SPELL_AURA_REMOVED"][322431] = function(info)
	local icon = info.spellIcons[316262]
	if icon then
		icon:StartCooldown()
	end
end



registeredEvents["SPELL_AURA_APPLIED"][114255] = function(info)
	info.auras.hasSurgeOfLight = true
end

registeredEvents["SPELL_AURA_REMOVED"][114255] = function(info)
	info.auras.hasSurgeOfLight = nil
end

registeredEvents["SPELL_HEAL"][2061] = function(info, _,_,_,_,_, amount, _,_, critical, _, ts)
	if info.talentData[453828] and info.auras.hasSurgeOfLight then
		local icon = info.spellIcons[34861]
		if icon and icon.active then
			icon:UpdateCooldown(4)
		end
	end

	if info.talentData[453678] then
		local icon = info.spellIcons[2050]
		if icon and icon.active then
			amount = critical and amount / (P.isPvP and 1.5 or 2) or amount
			if ts - (info.auras.time_flashHeal or 0) < 0.3 and amount / (info.auras.lastFlashHealAmount or 0) < .5 then
				icon:UpdateCooldown(GetHolyWordReducedTime(info, 6 * (P.isPvP and .175 or .35)))
			end
			info.auras.time_flashHeal = ts
			info.auras.lastFlashHealAmount = amount
		end
	end
end

registeredEvents["SPELL_HEAL"][596] = function(info, srcGUID, _, destGUID, _,_, amount, _,_, critical, _, ts)
	if info.talentData[453678] and srcGUID == destGUID then
		local icon = info.spellIcons[34861]
		if icon and icon.active then
			amount = critical and amount / (P.isPvP and 1.5 or 2) or amount
			if ts - (info.auras.time_prayerHeal or 0) < 0.3 and amount / (info.auras.lastPrayerhHealAmount or 0) < .5 then
				icon:UpdateCooldown(GetHolyWordReducedTime(info, 6 * (P.isPvP and .175 or .35)))
			end
			info.auras.time_prayerHeal = ts
			info.auras.lastPrayerhHealAmount = amount
		end
	end
end


registeredEvents["SPELL_AURA_APPLIED"][428933] = function(info)
	info.auras.mult_premonitionOfInsight = true
end

registeredEvents["SPELL_AURA_REMOVED"][428933] = function(info, srcGUID, spellID, destGUID)
	info.auras.mult_premonitionOfInsight = nil
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end

auraMultString[428933] = "mult_premonitionOfInsight"


registeredEvents["SPELL_AURA_APPLIED"][458650] = function(info)
	info.auras.mult_saveTheDay = true
end

registeredEvents["SPELL_AURA_REMOVED"][458650] = function(info)
	info.auras.mult_saveTheDay = nil
end

auraMultString[458650] = "mult_saveTheDay"







registeredEvents["SPELL_ENERGIZE"][381623] = function(info)
	local icon = info.spellIcons[381623]
	if icon then
		icon:StartCooldown()
	end
end




registeredEvents["SPELL_AURA_REMOVED"][57934] = function(info, srcGUID, spellID, destGUID)
	local icon = info.spellIcons[spellID] or info.spellIcons[221622]
	if icon then
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)

		info.preactiveIcons[spellID] = nil
		icon:SetColorSaturation()
		if icon.statusBar then
			icon.statusBar:SetColors()
		end
	end
end

local function StartTricksCD(info, srcGUID, spellID, destGUID)
	local icon = info.spellIcons[57934]
	if icon and srcGUID == destGUID then
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
		icon:StartCooldown()
	end
end

registeredEvents["SPELL_AURA_APPLIED"][59628] = StartTricksCD
registeredEvents["SPELL_AURA_APPLIED"][221630] = StartTricksCD





local comboPointSpenders = {

	2098,
	196819,
	462140,
	462241,
	315496,
	408,
	315341,
	319175,
	1943,
	280719,
	51690,
}

local restlessBladesIDs = {
	13750,
	315341,
	13877,
	271877,
	196937,
	195457,
	381989,
	51690,
	315508,
	2983,
	1856,
	5277,
	1966,
}

local function ConsumedComboPoints(info, _, spellID, _,_,_,_,_,_,_,_, ts)
	if info.spec == 259 then
		return
	end

	local cp = 5
	if spellID ~= 408 and info.maxCP then
		cp = info.maxCP
		if info.auras.numChargedPP and info.auras.numChargedPP > 0 then
			cp = cp + info.bonusCP
			info.auras.numChargedPP = info.auras.numChargedPP - 1
		end
		if spellID == 462140 or spellID == 462241 then
			cp = cp + 5
		end
	end

	if info.spec == 261 then
		if info.talentData[185314] then
			local icon = info.spellIcons[185313]
			if icon and icon.active then
				icon:UpdateCooldown(cp * 0.5)
			end
		end
		if spellID ~= 280719 then
			local icon = info.spellIcons[280719]
			if icon and icon.active then
				icon:UpdateCooldown(cp * 1.0)
			end
		end
		return
	end


	if ts > (info.auras.time_restlessBlades or 0) then
		local hasTB = info.auras.hasTrueBearing
		local hasFB = info.talentData[354897]
		local reducedTime = hasTB and 1.5 or 1
		local ReducedTimeFB = P.isPvP and (hasTB and 1 or 0.5)/2 or (hasTB and 1 or 0.5)

		for i = 1, #restlessBladesIDs do
			local id = restlessBladesIDs[i]
			local icon = (i < 12 or hasFB) and info.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(cp * (i < 12 and reducedTime or ReducedTimeFB))
			end
		end
		info.auras.time_restlessBlades = ts + 0.1
	end
end

for _, id in ipairs(comboPointSpenders) do
	if id == 196819 or id == 2098 or id == 462140 or id == 462241 then
		registeredEvents["SPELL_DAMAGE"][id] = ConsumedComboPoints
	else
		registeredEvents["SPELL_CAST_SUCCESS"][id] = ConsumedComboPoints
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][212283] = function(info)
	local points = GetUnitChargedPowerPoints(info.unit)
	info.auras.numChargedPP = points and #points
end
registeredEvents["SPELL_CAST_SUCCESS"][315508] = registeredEvents["SPELL_CAST_SUCCESS"][212283]


registeredEvents["SPELL_AURA_REMOVED"][1784] = function(info, srcGUID)
	if info.auras.mult_isStealthed then
		C_Timer_After(.05, function() info.auras.mult_isStealthed = nil end)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][1784] = function(info)
	local icon = info.spellIcons[315341]
	if icon then
		if icon.active then
			icon:ResetCooldown()
		end
		info.auras.mult_isStealthed = true
	end
end

auraMultString[1784] = "mult_isStealthed"


registeredEvents["SPELL_AURA_REMOVED"][193359] = function(info)
	info.auras.hasTrueBearing = nil
end

registeredEvents["SPELL_AURA_APPLIED"][193359] = function(info)
	info.auras.hasTrueBearing = true
end


registeredEvents["SPELL_CAST_SUCCESS"][36554] = function(info, _, spellID, destGUID, _, destFlags)
	local icon = info.spellIcons[spellID]
	if icon and icon.active then
		if info.talentData[197899] then
			if P.isPvP and band(destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
				icon:UpdateCooldown(icon.duration * .67)
			end
		elseif info.talentData[381630] then
			local unit = UnitTokenFromGUID(destGUID)
			if unit then
				if P:GetDebuffDuration(unit, 703) then
					icon:UpdateCooldown(icon.duration * .33)
				end
			end
		end
	end
end


registeredEvents["SPELL_AURA_APPLIED"][457333] = function(info)
	info.auras.mult_deathsArrival = true
end

registeredEvents["SPELL_AURA_REMOVED"][457333] = function(info)
	info.auras.mult_deathsArrival = nil
end

registeredEvents["SPELL_AURA_APPLIED"][457343] = function(info)
	info.auras.mult_deathsArrival = true
end

registeredEvents["SPELL_AURA_REMOVED"][457343] = function(info)
	info.auras.mult_deathsArrival = nil
end

auraMultString[457333] = "mult_deathsArrival"
auraMultString[457343] = "mult_deathsArrival"


registeredEvents["SPELL_DAMAGE"][457157] = function(info)
	local icon = info.spellIcons[36554]
	if icon and icon.active then
		icon:UpdateCooldown(3)
	end
end







registeredEvents["SPELL_HEAL"][31616] = function(info)
	local icon = info.spellIcons[30884]
	if icon then
		icon:StartCooldown()
	end
end


registeredEvents["SPELL_CAST_SUCCESS"][21169] = function(info)
	local icon = info.spellIcons[20608]
	if icon then
		icon:StartCooldown()
	end
end




registeredEvents["SPELL_SUMMON"][192058] = function(info, srcGUID, spellID, destGUID)
	if info.talentData[265046] or info.talentData[445027] then
		local icon = info.spellIcons[spellID]
		if icon then
			local capGUID = info.auras.capTotemGUID
			if capGUID then
				minionGUIDS[capGUID] = nil
			end
			minionGUIDS[destGUID] = srcGUID
			info.auras.capTotemGUID = destGUID
		end
	end
end

registeredEvents["SPELL_SUMMON"][383013] = function(info, srcGUID, spellID, destGUID)
	if info.talentData[445027] then
		local icon = info.spellIcons[spellID]
		if icon then
			local poiGUID = info.auras.poisonCleansingTotemGUID
			if poiGUID then
				minionGUIDS[poiGUID] = nil
			end
			minionGUIDS[destGUID] = srcGUID
			info.auras.poisonCleansingTotemGUID = destGUID
		end
	end
end

registeredEvents["SPELL_SUMMON"][51485] = function(info, srcGUID, spellID, destGUID)
	if info.talentData[445027] then
		local icon = info.spellIcons[spellID]
		if icon then
			local earGUID = info.auras.earthgrabTotemGUID
			if earGUID then
				minionGUIDS[earGUID] = nil
			end
			minionGUIDS[destGUID] = srcGUID
			info.auras.earthgrabTotemGUID = destGUID
		end
	end
end


local shamanTotems = {
	192058,
	157153,
	204331,
	2484,
	198838,
	51485,
	204336,
	5394,
	192222,
	383013,
	355580,
	108270,
	444995,
	383019,
	8143,
	192077,
}

local function CacheLastTotemUsed(info, _, spellID)
	if info.talentData[108285] and info.auras.lastTotemUsed ~= spellID then
		if info.talentData[383012] then
			info.auras.usedTotemList = info.auras.usedTotemList or {}
			local c = #info.auras.usedTotemList
			c = c == 1 and 2 or 1
			info.auras.usedTotemList[c] = spellID
		end
		info.auras.lastTotemUsed = spellID
	end
end

for _, id in pairs(shamanTotems) do
	registeredEvents["SPELL_CAST_SUCCESS"][id] = CacheLastTotemUsed
end

registeredEvents["SPELL_CAST_SUCCESS"][108285] = function(info)
	if info.talentData[383012] and info.auras.usedTotemList then
		for _, id in ipairs(info.auras.usedTotemList) do
			local icon = info.spellIcons[id]
			if icon and icon.active then
				icon:ResetCooldown()
			end
		end
	else
		local icon = info.spellIcons[info.auras.lastTotemUsed]
		if icon and icon.active then
			icon:ResetCooldown()
		end
	end
end


registeredEvents["SPELL_AURA_REMOVED"][285514] = function(info, srcGUID)
	if info.auras.hasSurgeOfPower then
		C_Timer_After(0, function() info.auras.hasSurgeOfPower = nil end)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][285514] = function(info)
	if info.spellIcons[198067] or info.spellIcons[192249] then
		info.auras.hasSurgeOfPower = true
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][51505] = function(info)
	if info.auras.hasSurgeOfPower then
		local icon = info.spellIcons[198067] or info.spellIcons[192249]
		if icon and icon.active then
			icon:UpdateCooldown(4)
		end
	end
end


registeredEvents["SPELL_AURA_APPLIED"][344179] = function(info)
	if info.talentData[384447] then
		local icon = info.spellIcons[51533]
		if icon and icon.active then
			icon:UpdateCooldown(1)
		end
	end
end

registeredEvents["SPELL_AURA_APPLIED_DOSE"][344179] = function(info, _,_,_,_,_,_, amount)
	if info.talentData[384447] and amount == 2 then
		local icon = info.spellIcons[51533]
		if icon and icon.active then
			icon:UpdateCooldown(1)
		end
	end
end

registeredEvents["SPELL_AURA_REFRESH"][344179] = registeredEvents["SPELL_AURA_APPLIED"][344179]



local stormConduitIDs = {
	108271,
	192063,
	57994,

	5394,
	383013,
	383019,
	51485,
	192077,
	192058,
	355580,
	204331,
	204336,
	2484,
	8143,
	108270,
	444995,
}

registeredEvents["SPELL_CAST_SUCCESS"][188443] = function(info)

	if info.talentData[468571] then
		local icon = info.spellIcons[191634]
		if icon and icon.active then
			icon:UpdateCooldown(2)
		end
	end

	if P.isPvP and info.talentData[1217092] then
		local reducedTime = info.spec == 262 and 1 or 4
		for i = 1, #stormConduitIDs do
			local id = stormConduitIDs[i]
			local icon = info.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(reducedTime)
			end
		end
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][188196] = registeredEvents["SPELL_CAST_SUCCESS"][188443]
registeredEvents["SPELL_CAST_SUCCESS"][452201] = registeredEvents["SPELL_CAST_SUCCESS"][188443]


registeredEvents["SPELL_SUMMON"][445624] = function(info)
	local icon = info.spellIcons[198067] or info.spellIcons[192249]
	if icon and icon.active then
		icon:UpdateCooldown(10)
	end
end







registeredEvents["SPELL_AURA_APPLIED"][457555] = function(info)
	local icon = info.spellIcons[6353]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end



local function ReduceUnendingResolveCD(destInfo, destName, _, amount, _,_, timestamp, spellSchool)
	local talentRank = destInfo.talentData[389359]
	if talentRank then
		local icon = destInfo.spellIcons[104773]
		if icon and icon.active then
			if timestamp > (destInfo.auras.time_resoluteBarrier or 0) then
				local maxHP = UnitHealthMax(destName)
				if maxHP > 0 and (amount / maxHP) > 0.05 then
					icon:UpdateCooldown(10)
					destInfo.auras.time_resoluteBarrier = timestamp + 30 - (5 * talentRank)
				end
			end
		end
	end

	if P.isPvP and destInfo.talentData[409835] and spellSchool and band(spellSchool,1) > 0 then
		local icon = destInfo.spellIcons[48020]
		if icon and icon.active then
			if timestamp > (destInfo.auras.time_impishInstinct or 0) then
				icon:UpdateCooldown(3)
				destInfo.auras.time_impishInstinct = timestamp + 5
			end
		end
	end
end

registeredHostileEvents["SWING_DAMAGE"]["WARLOCK"] = function(destInfo,destName,spellID,_,_,_,timestamp,spellSchool) ReduceUnendingResolveCD(destInfo,destName,nil,spellID,nil,nil,timestamp,spellSchool) end
registeredHostileEvents["RANGE_DAMAGE"]["WARLOCK"] = ReduceUnendingResolveCD
registeredHostileEvents["SPELL_DAMAGE"]["WARLOCK"] = ReduceUnendingResolveCD


local function ReduceDemonicCircleTeleportCD(destInfo, destName, _, amount, _,_, timestamp, spellSchool, _, missType)
	if missType and missType ~= "ABSORB" then
		return
	end
	if P.isPvP and destInfo.talentData[409835] and spellSchool and band(spellSchool,1) > 0 then
		local icon = destInfo.spellIcons[48020]
		if icon and icon.active then
			if timestamp > (destInfo.auras.time_impishInstinct or 0) then
				icon:UpdateCooldown(3)
				destInfo.auras.time_impishInstinct = timestamp + 5
			end
		end
	end
end

registeredHostileEvents["SWING_MISSED"]["WARLOCK"] = function(destInfo,destName,spellID,_,_,_,timestamp,spellSchool) ReduceDemonicCircleTeleportCD(destInfo,destName,nil,spellSchool,nil,nil,timestamp,1,nil,spellID) end
registeredHostileEvents["RANGE_MISSED"]["WARLOCK"] = function(destInfo,destName,_,missType,_,_,timestamp,spellSchool,amountMissed) ReduceDemonicCircleTeleportCD(destInfo,destName,nil,amountMissed,nil,nil,timestamp,spellSchool,nil,missType) end
registeredHostileEvents["SPELL_MISSED"]["WARLOCK"] = registeredHostileEvents["RANGE_MISSED"]["WARLOCK"]








registeredEvents["SPELL_AURA_APPLIED"][32216] = function(info)
	local icon = info.spellIcons[202168]
	if icon and icon.active then
		icon:ResetCooldown()
		info.auras.rrt_victorious = true
	end
end


local warriorRageSpenders = {
	[845   ] = { 20, 262161, 167105, 227847, 228920,                   },
	[12294 ] = { 30, 262161, 167105, 227847, 228920,                   },
	[772   ] = { 20, 262161, 167105, 227847, 228920,                   },
	[5308  ] = { 40,                 227847, 228920, 1719,             },
	[280735] = { 40,                 227847, 228920, 1719,             },
	[184367] = { 80,                 227847, 228920, 1719,             },
	[394062] = { 20,                                       107574, 871 },
	[6572  ] = { 20,                                       107574, 871 },
	[163201] = { 40, 262161, 167105, 227847, 228920,       107574, 871 },
	[281000] = { 40, 262161, 167105, 227847, 228920,       107574, 871 },
	[1715  ] = { 10, 262161, 167105, 227847, 228920, 1719, 107574, 871 },
	[190456] = { 35, 262161, 167105, 227847, 228920,       107574, 871 },
	[202168] = { 10, 262161, 167105, 227847, 228920, 1719, 107574, 871 },
	[2565  ] = { 30, 262161, 167105, 227847, 228920, 1719, 107574, 871 },
	[1464  ] = { 20, 262161, 167105, 227847, 228920, 1719, 107574, 871 },
	[6343  ] = { 20, 262161, 167105, 227847, 228920, 1719, 107574, 871 },
	[1680  ] = { 20, 262161, 167105, 227847, 228920,       107574, 871 },
}

local function ReduceAngerManagementCD(info, _, spellID)
	local spenderInfo = warriorRageSpenders[spellID]
	local r = spenderInfo[1]

	if spellID == 845 or spellID == 1680 then
		if info.auras.rrt_stormOfSwords then
			return
		end
	elseif spellID == 12294 then
		if info.auras.isBladestorming then
			return
		end
	elseif spellID == 184367 then
		if info.talentData[390135] and info.auras.hasAvatar then
			r = r - 20
		end
	elseif spellID == 5308 or spellID == 280735 or spellID == 163201 or spellID == 281000 then
		if info.talentData[316402] or info.auras.rrt_suddenDeath then
			return
		end
	elseif spellID == 6572 then
		if info.auras.rrt_revenge then
			return
		end
	elseif spellID == 190456 then
		if info.spec == 71 then
			return
		end
	elseif spellID == 202168 then
		if info.auras.rrt_victorious then
			return
		end
	elseif spellID == 1464 then
		if info.spec == 72 then
			return
		end
	elseif spellID == 6343 then
		if info.spec == 73 then
			return
		end
	end

	local reducedTime = info.spec == 73 and r/10 or r/20
	if info.spec == 72 and P.isPvP then
		reducedTime = reducedTime * 2
	end
	for i = 2, #spenderInfo do
		local id = spenderInfo[i]
		if (id ~= 107574 or info.spec == 73) and (id ~= 228920 or info.spec ~= 73) then
			local icon = info.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(reducedTime)
			end
		end
	end
end

for id in pairs(warriorRageSpenders) do
	registeredEvents["SPELL_CAST_SUCCESS"][id] = ReduceAngerManagementCD
end

registeredEvents["SPELL_AURA_REMOVED"][107574] = function(info, srcGUID, spellID, destGUID)
	info.auras.hasAvatar = nil
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end
registeredEvents["SPELL_AURA_APPLIED"][107574] = function(info) info.auras.hasAvatar = true end
registeredEvents["SPELL_AURA_REMOVED"][439601] = function(info) info.auras.rrt_stormOfSwords = nil end
registeredEvents["SPELL_AURA_APPLIED"][439601] = function(info) info.auras.rrt_stormOfSwords = true end
registeredEvents["SPELL_AURA_REMOVED"][52437] = function(info) info.auras.rrt_suddenDeath = nil end
registeredEvents["SPELL_AURA_APPLIED"][52437] = function(info) info.auras.rrt_suddenDeath = true end
registeredEvents["SPELL_AURA_REMOVED"][5302] = function(info) info.auras.rrt_revenge = nil end
registeredEvents["SPELL_AURA_APPLIED"][5302] = function(info) info.auras.rrt_revenge = true end

registeredEvents["SPELL_AURA_REMOVED"][227847] = function(info, srcGUID, spellID, destGUID)
	info.auras.isBladestorming = nil
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end
registeredEvents["SPELL_AURA_APPLIED"][227847] = function(info) info.auras.isBladestorming = true end
registeredEvents["SPELL_AURA_REMOVED"][446035] = registeredEvents["SPELL_AURA_REMOVED"][227847]
registeredEvents["SPELL_AURA_APPLIED"][446035] = registeredEvents["SPELL_AURA_APPLIED"][227847]


registeredEvents["SPELL_DAMAGE"][46968] = function(info)
	if info.talentData[275339] then
		local active = info.active[46968]
		if active then
			active.numHits = (active.numHits or 0) + 1
			if active.numHits == 3 then
				local icon = info.spellIcons[46968]
				if icon and icon.active then
					icon:UpdateCooldown(15)
				end
			end
		end
	end
end


registeredEvents["SPELL_DAMAGE"][6343] = function(info)
	if info.talentData[385840] then
		local active = info.active[1160]
		if active then
			active.numHits = (active.numHits or 0) + 1
			if active.numHits <= 3 then
				local icon = info.spellIcons[1160]
				if icon and icon.active then
					icon:UpdateCooldown(1.5)
				end
			end
		end
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][6343] = function(info, _, spellID)
	if info.talentData[385840] then
		local active = info.active[1160]
		if active then
			active.numHits = 0
		end
	end
	ReduceAngerManagementCD(info, _, spellID)
end


registeredEvents["SPELL_AURA_APPLIED_DOSE"][440989] = function(info, _,_,_,_,_,_, amount)
	if info.talentData[429636] then
		info.auras.numColossalMight = amount
	end
end

registeredEvents["SPELL_AURA_REFRESH"][440989] = function(info)
	if info.talentData[429636] then
		local c = info.auras.numColossalMight or 11
		if c == 10 then
			info.auras.numColossalMight = 11
		elseif c > 10 then
			local icon = info.spellIcons[436358]
			if icon and icon.active then
				icon:UpdateCooldown(2)
			end
		end
	end
end


registeredEvents["SPELL_AURA_REMOVED"][445584] = function(info, srcGUID)
	if info.auras.numMarkedForExecution then
		C_Timer_After(0, function() info.auras.numMarkedForExecution = nil end)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][445584] = function(info)
	if info.talentData[444780] then
		info.auras.numMarkedForExecution = 1
	end
end

registeredEvents["SPELL_AURA_APPLIED_DOSE"][445584] = function(info, _,_,_,_,_,_, amount)
	if info.talentData[444780] then
		info.auras.numMarkedForExecution = amount
	end
end

registeredEvents["SPELL_CAST_SUCCESS"][5308] = function(info, _, spellID)
	if info.auras.numMarkedForExecution then
		local icon = info.spellIcons[227847]
		if icon and icon.active then
			icon:UpdateCooldown(info.auras.numMarkedForExecution * 5)
		end
	end
	ReduceAngerManagementCD(info, _, spellID)
end

registeredEvents["SPELL_CAST_SUCCESS"][280735] = registeredEvents["SPELL_CAST_SUCCESS"][5308]
registeredEvents["SPELL_CAST_SUCCESS"][163201] = registeredEvents["SPELL_CAST_SUCCESS"][5308]
registeredEvents["SPELL_CAST_SUCCESS"][281000] = registeredEvents["SPELL_CAST_SUCCESS"][5308]


registeredEvents["SPELL_AURA_APPLIED"][1218163] = function(info)
	if info.talentData[1215995] then
		info.auras.hasLuckOfTheDraw = true
	end
end

registeredEvents["SPELL_AURA_REMOVED"][1218163] = function(info)
	info.auras.hasLuckOfTheDraw = nil
end

registeredEvents["SPELL_DAMAGE"][23922] = function(info, _,_,_, critical)
	if critical and info.auras.hasLuckOfTheDraw then
		local icon = info.spellIcons[385952]
		if icon and icon.active then
			icon:UpdateCooldown(12)
		end
	end
end















local function UpdateSpellRR(info, spellID, modRate, icon, now)
	icon = icon or info.spellIcons[spellID]
	if icon then
		local newRate = icon.modRate * modRate
		local active = icon.active and info.active[spellID]
		if active then
			now = now or GetTime()
			local elapsed = (now - active.startTime) * modRate
			local newTime = now - elapsed
			local newCd = active.duration * modRate
			icon.cooldown:SetCooldown(newTime, newCd, newRate)
			active.startTime = newTime
			active.duration = newCd
			active.modRate = newRate
			local statusBar = icon.statusBar
			if statusBar then
				statusBar.CastingBar:OnEvent(statusBar.CastingBar.channeling and "UNIT_SPELLCAST_CHANNEL_UPDATE" or "UNIT_SPELLCAST_CAST_UPDATE")
			end
		end
		info.spellModRates[spellID] = newRate
		icon.modRate = newRate
	end
end

local function UpdateCDRR(info, modRate, excludeID, forcedIDs)
	local now = GetTime()
	for spellID, icon in pairs(info.spellIcons) do
		if icon and (icon.isBookType and spellID ~= excludeID or (forcedIDs and forcedIDs[spellID])) then
			UpdateSpellRR(info, spellID, modRate, icon, now)
		end
	end
end





local evokerRacials = {
	[368970] = true,
	[357214] = true,
	[369536] = true,
}


local OnFlowStateTimerEnd
OnFlowStateTimerEnd = function(srcGUID, spellID)
	local info = groupInfo[srcGUID]
	if info and info.callbackTimers[spellID] then
		UpdateCDRR(info, info.auras.flowStateRankValue, nil, evokerRacials)
		info.auras.flowStateRankValue = nil
		info.callbackTimers[spellID] = nil
	end
end

registeredEvents["SPELL_AURA_REFRESH"][390148] = function(info, srcGUID, spellID)
	if info.callbackTimers[spellID] and srcGUID ~= userGUID then
		info.callbackTimers[spellID]:Cancel()
		info.callbackTimers[spellID] = C_Timer_NewTimer(10.1, function() OnFlowStateTimerEnd(srcGUID, spellID) end)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][390148] = function(info, srcGUID, spellID)
	if not info.auras.flowStateRankValue then
		local talentValue = info.talentData[385696] == 2 and 1.1 or 1.05
		info.auras.flowStateRankValue = talentValue
		info.callbackTimers[spellID] = srcGUID == userGUID or C_Timer_NewTimer(10.1, function() OnFlowStateTimerEnd(srcGUID, spellID) end)
		UpdateCDRR(info, 1/talentValue, nil, evokerRacials)
	end
end

registeredEvents["SPELL_AURA_REMOVED"][390148] = function(info, srcGUID, spellID)
	if info.callbackTimers[spellID] then
		if srcGUID ~= userGUID then
			info.callbackTimers[spellID]:Cancel()
		end
		UpdateCDRR(info, info.auras.flowStateRankValue, nil, evokerRacials)
		info.callbackTimers[spellID] = nil
		info.auras.flowStateRankValue = nil
	end
end


registeredEvents["SPELL_AURA_REMOVED"][404977] = function(info, srcGUID, spellID, destGUID)
	info = info or groupInfo[srcGUID]
	if info then
		if info.callbackTimers[spellID] then
			UpdateCDRR(info, 11, nil, evokerRacials)
			if srcGUID ~= userGUID then
				info.callbackTimers[spellID]:Cancel()
			end
			info.callbackTimers[spellID] = nil
		end
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][404977] = function(info, srcGUID, spellID, destGUID)

	info.callbackTimers[spellID] = srcGUID == userGUID or C_Timer_NewTimer(info.talentData[412723] and 3.05 or 2.05, function() registeredEvents["SPELL_AURA_REMOVED"][404977](nil, srcGUID, spellID, destGUID) end)
	UpdateCDRR(info, 1/11, nil, evokerRacials)
end


registeredEvents["SPELL_AURA_REMOVED"][378441] = function(info, srcGUID, spellID, destGUID)
	info = info or groupInfo[srcGUID]
	if info then
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
	end
	info = groupInfo[destGUID]
	if info and info.callbackTimers[spellID] then
		if destGUID ~= userGUID then
			info.callbackTimers[spellID]:Cancel()
		end
		info.callbackTimers[spellID] = nil
		UpdateCDRR(info, .01, spellID, evokerRacials)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][378441] = function(_, srcGUID, spellID, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo then
		destInfo.callbackTimers[spellID] = destGUID == userGUID or C_Timer_NewTimer(4.1, function() registeredEvents["SPELL_AURA_REMOVED"][spellID](nil, srcGUID, spellID, destGUID) end)
		UpdateCDRR(destInfo, 100, spellID, evokerRacials)
	end
end


registeredEvents["SPELL_AURA_APPLIED"][431698] = function(info, srcGUID, spellID)
	local rr = 1/1.3
	UpdateCDRR(info, rr, nil, evokerRacials)
	info.auras.modrate_temporalBurst = rr
	info.callbackTimers[spellID] = srcGUID == userGUID or C_Timer_NewTimer(30.1, function() registeredEvents["SPELL_AURA_REMOVED"][431698](nil, srcGUID, spellID) end)
end

registeredEvents["SPELL_AURA_REMOVED_DOSE"][431698] = function(info, _, spellID, _,_,_,_, amount)
	if info.auras.modrate_temporalBurst then
		local rr = 1/(1 + (amount/100))
		UpdateCDRR(info, 1/info.auras.modrate_temporalBurst * rr, nil, evokerRacials)
		info.auras.modrate_temporalBurst = rr
	end
end

registeredEvents["SPELL_AURA_REMOVED"][431698] = function(info, srcGUID, spellID)
	info = info or groupInfo[srcGUID]
	if info and info.auras.modrate_temporalBurst then
		UpdateCDRR(info, 1/info.auras.modrate_temporalBurst, nil, evokerRacials)
		info.auras.modrate_temporalBurst = nil
		if info.callbackTimers[spellID] then
			if srcGUID ~= userGUID then
				info.callbackTimers[spellID]:Cancel()
			end
			info.callbackTimers[spellID] = nil
		end
	end
end


registeredEvents["SPELL_AURA_REMOVED"][329042] = function(info, srcGUID, spellID, destGUID)
	info = info or groupInfo[srcGUID]
	if info then
		if info.callbackTimers[spellID] then
			UpdateCDRR(info, 5, spellID)
			if srcGUID ~= userGUID then
				info.callbackTimers[spellID]:Cancel()
			end
			info.callbackTimers[spellID] = nil
		end
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][329042] = function(info, srcGUID, spellID, destGUID)

	if srcGUID == destGUID then
		info.callbackTimers[spellID] = srcGUID == userGUID or C_Timer_NewTimer(10.1, function() registeredEvents["SPELL_AURA_REMOVED"][329042](nil, srcGUID, spellID, destGUID) end)
		UpdateCDRR(info, 0.2, spellID)
	end
end


registeredEvents["SPELL_AURA_REMOVED"][388010] = function(info, srcGUID, spellID, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo then
		if destInfo.callbackTimers[spellID] then
			if destGUID ~= userGUID then
				destInfo.callbackTimers[spellID]:Cancel()
			end
			destInfo.callbackTimers[spellID] = nil
			UpdateCDRR(destInfo, 1.3)
		end
	end
	info = info or groupInfo[srcGUID]
	if info then
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][388010] = function(info, srcGUID, spellID, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo then
		destInfo.callbackTimers[spellID] = destGUID == userGUID or C_Timer_NewTimer(30.5, function() registeredEvents["SPELL_AURA_REMOVED"][388010](nil, srcGUID, spellID, destGUID) end)
		UpdateCDRR(destInfo, 1/1.3)
	end
end










local mageBarriers = {
	11426,
	235450,
	235313,
}

for _, id in pairs(mageBarriers) do
	registeredEvents["SPELL_AURA_REMOVED"][id] = function(info, srcGUID, spellID, destGUID)
		if info.auras.rr_mageBarrier then
			UpdateSpellRR(info, spellID, P.isPvP and 1.2 or 1.3)
			info.auras.rr_mageBarrier = nil
		end
		RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)


		if info.talentData[455428] then
			local icon = info.spellIcons[spellID]
			if icon and icon.active then
				icon:UpdateCooldown(4)
			end
		end
	end
	registeredEvents["SPELL_AURA_APPLIED"][id] = function(info, _, spellID)
		if info.talentData[382800] then
			UpdateSpellRR(info, spellID, P.isPvP and 1/1.2 or 1/1.3)
			info.auras.rr_mageBarrier = true
		end
	end
end


local wwHotJSTargetIDs = {

	113656,
	392983,
	152175,
	101545,
	1217413,
}

local mwHotJSTargetIDs = {


	116849,
	116680,
}

registeredEvents["SPELL_AURA_APPLIED"][443421] = function(info)
	local t = info.spec == 270 and mwHotJSTargetIDs or wwHotJSTargetIDs
	for _, id in ipairs(t) do
		UpdateSpellRR(info, id, 1/1.75)
	end
	info.auras.rr_HotJS = true
end

registeredEvents["SPELL_AURA_REMOVED"][443421] = function(info)
	local t = info.spec == 270 and mwHotJSTargetIDs or wwHotJSTargetIDs
	for _, id in ipairs(t) do
		UpdateSpellRR(info, id, 1.75)
	end
	info.auras.rr_HotJS = nil
end


local symbolOfHopeIDs = {
	[71]=118038,	[72]=184364,	[73]=871,
	[65]=498,	[66]=31850,	[70]=403876,
	[253]=109304,	[254]=109304,	[255]=109304,
	[259]=185311,	[260]=185311,	[261]=185311,
	[256]=19236,	[257]=19236,	[258]=19236,
	[250]=48792,	[251]=48792,	[252]=48792,
	[262]=108271,	[263]=108271,	[264]=108271,
	[62]=55342,	[63]=55342,	[64]=55342,
	[265]=104773,	[266]=104773,	[267]=104773,
	[268]=115203,	[269]=115203,	[270]=115203,
	[102]=22812,	[103]=22812,	[104]=22812,	[105]=22812,
	[577]=198589,	[581]=204021,
	[1467]=363916,	[1468]=363916,	[1473]=363916,
}

registeredEvents["SPELL_AURA_REMOVED"][265144] = function(_,_,_, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo then
		local id = symbolOfHopeIDs[destInfo.spec]
		if id then
			local rr = destInfo.auras.rr_symbolOfHope
			if rr then
				UpdateSpellRR(destInfo, id, 1/rr)
				destInfo.auras.rr_symbolOfHope = nil
			end
		end
	end
end

registeredEvents["SPELL_AURA_APPLIED"][265144] = function(info, _,_, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo then
		local id = symbolOfHopeIDs[destInfo.spec]
		if id then

			local _,_,_, startTimeMS, endTimeMS = UnitChannelInfo(info.unit)
			if startTimeMS and endTimeMS then
				local channelTime = (endTimeMS - startTimeMS) / 1000
				local rr = 1 / ((30 + channelTime) / channelTime)
				UpdateSpellRR(destInfo, id, rr)
				destInfo.auras.rr_symbolOfHope = rr
			end
		end
	end
end


registeredEvents["SPELL_AURA_REMOVED"][381684] = function(info)
	if info.auras.rr_brimmingWithLife then
		UpdateSpellRR(info, 20608, 1.75)
	end
end

registeredEvents["SPELL_AURA_APPLIED"][381684] = function(info)
	local icon = info.spellIcons[20608]
	if icon then
		UpdateSpellRR(info, 20608, 1/1.75)
		info.auras.rr_brimmingWithLife = true
	end
end







registeredEvents["SPELL_AURA_APPLIED"][2825] = function(_,_,_, destGUID)

	local destInfo = groupInfo[destGUID]
	if destInfo then
		destInfo.auras.mult_lust = true
		for id in pairs(E.spell_cdmod_by_haste) do
			local icon = destInfo.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(0, 0.7)
			end
		end
	end
end

registeredEvents["SPELL_AURA_REMOVED"][2825] = function(info, srcGUID, spellID, destGUID)
	local destInfo = groupInfo[destGUID]
	if destInfo then
		destInfo.auras.mult_lust = nil
		for id in pairs(E.spell_cdmod_by_haste) do
			local icon = destInfo.spellIcons[id]
			if icon and icon.active then
				icon:UpdateCooldown(0, 1/0.7)
			end
		end
	end
	RemoveHighlightByCLEU(info, srcGUID, spellID, destGUID)
end

registeredEvents["SPELL_AURA_APPLIED"][32182] = registeredEvents["SPELL_AURA_APPLIED"][2825]
registeredEvents["SPELL_AURA_REMOVED"][32182] = registeredEvents["SPELL_AURA_REMOVED"][2825]
registeredEvents["SPELL_AURA_APPLIED"][80353] = registeredEvents["SPELL_AURA_APPLIED"][2825]
registeredEvents["SPELL_AURA_REMOVED"][80353] = registeredEvents["SPELL_AURA_REMOVED"][2825]
registeredEvents["SPELL_AURA_APPLIED"][264667] = registeredEvents["SPELL_AURA_APPLIED"][2825]
registeredEvents["SPELL_AURA_REMOVED"][264667] = registeredEvents["SPELL_AURA_REMOVED"][2825]
registeredEvents["SPELL_AURA_APPLIED"][390386] = registeredEvents["SPELL_AURA_APPLIED"][2825]
registeredEvents["SPELL_AURA_REMOVED"][390386] = registeredEvents["SPELL_AURA_REMOVED"][2825]
registeredEvents["SPELL_AURA_APPLIED"][466904] = registeredEvents["SPELL_AURA_APPLIED"][2825]
registeredEvents["SPELL_AURA_REMOVED"][466904] = registeredEvents["SPELL_AURA_REMOVED"][2825]

auraMultString[2825] = "mult_lust"
auraMultString[32182] = "mult_lust"
auraMultString[80353] = "mult_lust"
auraMultString[264667] = "mult_lust"
auraMultString[390386] = "mult_lust"
auraMultString[466904] = "mult_lust"


local function CancelEmpoweredSpell(info, _, spellID)
	local icon = info.spellIcons[E.spellcast_merged[spellID] or spellID]
	if icon and icon.active then
		icon:ResetCooldown()
	end
end

registeredEvents["SPELL_EMPOWER_INTERRUPT"][367226] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][382731] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][355936] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][382614] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][357208] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][382266] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][396286] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][408092] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][359073] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][382411] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][436344] = CancelEmpoweredSpell
registeredEvents["SPELL_EMPOWER_INTERRUPT"][1217413] = CancelEmpoweredSpell


registeredEvents["SPELL_AURA_APPLIED"][113942] = function(info, _, spellID)
	local icon = info.spellIcons[spellID] or info:AddOnCast(spellID, 0)
	if icon then

		if AuraUtil_ForEachAura then
			AuraUtil_ForEachAura(info.unit, "HARMFUL", nil, function(_,_,_,_, duration, _,_,_,_, id)
				if id == spellID then
					if duration > 0 then
						icon.duration = duration
					end
					icon:StartCooldown()
					return true
				end
			end)
		else
			for i = 1, 50 do
				local _,_,_,_, duration, _,_,_,_, id = UnitDebuff(info.unit, i)
				if not id then return end
				if id == spellID then
					if duration > 0 then
						icon.duration = duration
					end
					icon:StartCooldown()
					break
				end
			end
		end
	end
end



local consumables = {
	323436,
	6262,

}

local startCdOutOfCombat = function(guid)
	local info = groupInfo[guid]
	if not info or UnitAffectingCombat(info.unit) then
		return
	end

	if info.callbackTimers.inCombatTicker then
		info.callbackTimers.inCombatTicker:Cancel()
		info.callbackTimers.inCombatTicker = nil
	end
	for i = 1, #consumables do
		local spellID = consumables[i]
		local icon = info.preactiveIcons[spellID]
		if icon then
			icon:StartCooldown()

			CM:ForceSyncCooldowns()
		end
	end
end

local function StartConsumablesCD(info, srcGUID, spellID)
	local icon = info.spellIcons[spellID] or info:AddOnCast(spellID, 5512)
	if icon then

		if spellID == 323436 or spellID == 6262 then
			local stacks = icon.count:GetText()
			stacks = tonumber(stacks)
			stacks = (stacks and stacks > 0 and stacks or 3) - 1
			icon.count:SetText(stacks)
			if spellID == 6262 then
				info.auras.healthStoneStacks = stacks
			else
				info.auras.purifySoulStacks = stacks
			end
		end

		if info.callbackTimers.inCombatTicker then
			info.callbackTimers.inCombatTicker:Cancel()
			info.callbackTimers.inCombatTicker = nil
		end
		if UnitAffectingCombat(info.unit) then
			if icon.active then
				icon.cooldown:Clear()
			end
			info.preactiveIcons[spellID] = icon
			icon:SetColorSaturation()
			if icon.statusBar then
				icon.statusBar:SetColors()
			end
			info.callbackTimers.inCombatTicker = C_Timer_NewTicker(1, function() startCdOutOfCombat(icon.guid) end, 900)
		else
			icon:StartCooldown()
		end
	end
end

for i = 1, #consumables do
	local spellID = consumables[i]
	if spellID == 323436 then
		registeredEvents["SPELL_HEAL"][spellID] = function(info, srcGUID)
			if not info.auras.ignorePurifySoul then
				info.auras.ignorePurifySoul = true
				C_Timer_After(0.1, function() info.auras.ignorePurifySoul = false end)
				StartConsumablesCD(info, srcGUID, spellID)
			end
		end
		registeredEvents["SPELL_CAST_SUCCESS"][spellID] = registeredEvents["SPELL_HEAL"][spellID]
	else
		registeredEvents["SPELL_CAST_SUCCESS"][spellID] = StartConsumablesCD
	end
end






if E.isCata then

	registeredEvents["SPELL_DAMAGE"][78674] = function(info)
		if info.talentData[62971] then
			local icon = info.spellIcons[48505]
			if icon and icon.active then
				icon:UpdateCooldown(5)
			end
		end
	end


	registeredEvents["SPELL_CAST_SUCCESS"][5185] = function(info)
		if info.talentData[54825] then
			local icon = info.spellIcons[17116]
			if icon and icon.active then
				icon:UpdateCooldown(10)
			end
		end
	end


	registeredEvents["SPELL_CAST_SUCCESS"][2060] = function(info)
		if info.talentData[92297] then
			local icon = info.spellIcons[89485]
			if icon and icon.active then
				icon:UpdateCooldown(5)
			end
		end
	end
	registeredEvents["SPELL_CAST_SUCCESS"][585] = function(info)
		if info.talentData[92297] then
			local icon = info.spellIcons[47540]
			if icon and icon.active then
				icon:UpdateCooldown(0.5)
			end
		end
	end


	registeredEvents["SPELL_PERIODIC_DAMAGE"][15407] = function(info, _,_,_, critical)
		if critical then
			local rt = info.talentData[87099] and 5 or (info.talentData[87100] and 10)
			if rt then
				local icon = info.spellIcons[34433]
				if icon and icon.active then
					icon:UpdateCooldown(rt)
				end
			end
		end
	end


	registeredEvents["SPELL_INTERRUPT"][1766] = function(info, _, spellID, _,_,_, extraSpellId, extraSpellName, _,_, destRaidFlags)
		if info.talentData[56805] then
			local icon = info.spellIcons[spellID]
			if icon and icon.active then
				icon:UpdateCooldown(6)
			end
		end
		AppendInterruptExtras(info, nil, spellID, nil,nil,nil, extraSpellId, extraSpellName, nil,nil, destRaidFlags)
	end
	local arenaUnits = { "arena1", "arena2", "arena3", "arena4", "arena5", "target" }
	registeredEvents["SPELL_CAST_SUCCESS"][1766] = function(info, _, spellID, destGUID)
		if info.talentData[56805] then
			local icon = info.spellIcons[spellID]
			if icon and icon.active then
				for i = 1, #arenaUnits do
					local unit = arenaUnits[i]
					local guid = UnitGUID(unit)
					if guid == destGUID then
						local _,_,_,_,_,_, notInterruptable, channelID = UnitChannelInfo(unit)
						if notInterruptable ~= false then
							return
						end
						if channelID == 47758 then
							icon:UpdateCooldown(6)
						end
					end
				end
			end
		end
	end


	registeredEvents["SPELL_CAST_SUCCESS"][403] = function(info)
		local icon = info.spellIcons[16166]
		if icon and icon.active then
			local rt = info.talentData[86183] and 1 or (info.talentData[86184] and 2) or (info.talentData[86185] and 3)
			if rt then
				icon:UpdateCooldown(rt)
			end
		end
	end
	registeredEvents["SPELL_CAST_SUCCESS"][421] = function(info)
		local icon = info.spellIcons[16166]
		if icon and icon.active then
			local rt = info.talentData[86183] and 1 or (info.talentData[86184] and 2) or (info.talentData[86185] and 3)
			if rt then
				icon:UpdateCooldown(rt)
			end
		end
	end
end

setmetatable(registeredEvents, nil)
setmetatable(registeredHostileEvents, nil)

local function UpdateDeadStatus(destInfo)

	if E.preCata and UnitHealth(destInfo.unit) > 1 then
		return
	end
	destInfo.isDead = true
	destInfo.isDeadOrOffline = true
	destInfo:UpdateColorScheme()
end






if E.preCata then
	function CD:COMBAT_LOG_EVENT_UNFILTERED()
		local timestamp, event, _, srcGUID, _, srcFlags, _, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, _, amount, overkill, school, resisted, _,_, critical = CombatLogGetCurrentEventInfo()


		local info = groupInfo[srcGUID]
		if info then
			local func = registeredEvents[event] and registeredEvents[event][spellID]
			if func then
				func(info, srcGUID, spellID, destGUID, critical, destFlags, amount, overkill, destName, resisted, destRaidFlags, timestamp, school)
			end
			return
		end

		if band(srcFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0 then
			local destInfo = groupInfo[destGUID]
			if destInfo and event == "UNIT_DIED" then
				UpdateDeadStatus(destInfo)
			end
		end
	end
else
	function CD:COMBAT_LOG_EVENT_UNFILTERED()
		local timestamp, event, _, srcGUID, srcName, srcFlags, _, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount, overkill, school, resisted, _,_, critical = CombatLogGetCurrentEventInfo()




		local info = groupInfo[srcGUID]


		if shouldTrackBombardment and event == "SPELL_DAMAGE" and spellID == 434481 and (info or band(srcFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0) then

			OnBombardmentDamage(destGUID, timestamp)
		end


		if info then
			local func = registeredEvents[event] and (registeredEvents[event][spellID] or registeredEvents[event][info.class])
			if func then
				func(info, srcGUID, spellID, destGUID, critical, destFlags, amount, overkill, destName, resisted, destRaidFlags, timestamp, school)
			end
			return
		end


		local ownerGUID = minionGUIDS[srcGUID]
		if ownerGUID then
			info = groupInfo[ownerGUID]
			if not info then
				return
			end

			if event == "SPELL_INTERRUPT" then
				AppendInterruptExtras(info, nil, spellID, nil, nil, nil, amount, overkill, nil, nil, destRaidFlags)
			elseif event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" then

				if event == "SPELL_DAMAGE" and spellID == 1218004 then
					local icon = info.spellIcons[19574]
					if icon and icon.active then
						icon:UpdateCooldown(0.25)
					end
				end

				if overkill > -1 then
					local func = registeredEvents["PARTY_KILL"][info.class]
					if func then
						func(info, nil, nil, destGUID)
					end
				end
			elseif event == "SWING_DAMAGE" then

				if spellName > -1 then
					local func = registeredEvents["PARTY_KILL"][info.class]
					if func then
						func(info, nil, nil, destGUID)
					end
				end
			elseif event == "SPELL_AURA_APPLIED" then

				if spellID == 118905 then
					local icon = info.spellIcons[192058]
					if icon and icon.active then
						local active = info.talentData[265046] and info.active[192058]
						if active then
							active.numHits = (active.numHits or 0) + 1
							if active.numHits < 5 then
								icon:UpdateCooldown(5)
							end
						end

						if info.talentData[445027] and timestamp > (info.auras.time_capTotem or 0) then
							icon:UpdateCooldown(5)
							info.auras.time_capTotem = timestamp + 20
						end
					end

				elseif spellID == 64695 then
					local icon = info.spellIcons[51485]
					if icon and icon.active then
						if timestamp > (info.auras.time_earthgrabTotem or 0) then
							icon:UpdateCooldown(5)
							info.auras.time_earthgrabTotem = timestamp + 20
						end
					end
				end
			elseif event == "SPELL_DISPEL" then

				if spellID == 383015 then
					local icon = info.spellIcons[383013]
					if icon and icon.active then
						if timestamp > (info.auras.time_poisonCleansingTotem or 0) then
							icon:UpdateCooldown(5)
							info.auras.time_poisonCleansingTotem = timestamp + 20
						end
					end
				end
			end
			return
		end

		if band(srcFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0 then
			info = groupInfo[destGUID]
			if info then
				local func = registeredHostileEvents[event] and (registeredHostileEvents[event][spellID] or registeredHostileEvents[event][info.class])
				if func then
					func(info, destName, spellID, amount, overkill, destGUID, timestamp, spellSchool, school)
				elseif event == "UNIT_DIED" then
					UpdateDeadStatus(info)
				end
				return
			end

			--[[
			local ownerGUID = minionGUIDS[destGUID]
			info = groupInfo[ownerGUID]
			if info then

				if event == "UNIT_DIED" then
					if info.auras.mirrorImages and info.auras.mirrorImages[destGUID] then
						local icon = info.spellIcons[55342]
						if icon and icon.active then
							icon:UpdateCooldown(10)
						end
						info.auras.mirrorImages[destGUID] = nil
						minionGUIDS[destGUID] = nil
					end
				end
				return
			end
			]]
		end
	end
end

function CD:UNIT_PET(unit)
	local unitPet = E.UNIT_TO_PET[unit]
	if not unitPet then
		return
	end

	local guid = UnitGUID(unit)
	local info = groupInfo[guid]
	if info and (info.class == "WARLOCK" or info.class == "HUNTER" or info.spec == 252) then
		local petGUID = info.petGUID
		if petGUID then
			minionGUIDS[petGUID] = nil
		end
		petGUID = UnitGUID(unitPet)
		if petGUID then
			minionGUIDS[petGUID] = guid
		end
		info.petGUID = petGUID
	end
end

E.forbearanceIDs = forbearanceIDs
E.auraMultString = auraMultString
E.controlOfTheDreamIDs = controlOfTheDreamIDs
CD.minionGUIDS = minionGUIDS
