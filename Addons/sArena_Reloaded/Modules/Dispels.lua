if sArenaMixin.isMidnight then return end

local GetTime = GetTime
local isRetail = sArenaMixin.isRetail
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local L = sArenaMixin.L

-- Helper function to get localized spell name with fallback
-- Compatible with both legacy (pre-12.0) and new API (12.0.0+)
local function GetSpellName(spellID, fallbackName)
	-- Try new API first (12.0.0+): C_Spell.GetSpellName returns just the name string
	if C_Spell and C_Spell.GetSpellName then
		local name = C_Spell.GetSpellName(spellID)
		if name then return name end
	end
	-- Try new API alternative: C_Spell.GetSpellInfo returns a table with .name field
	if C_Spell and C_Spell.GetSpellInfo then
		local spellInfo = C_Spell.GetSpellInfo(spellID)
		if spellInfo and spellInfo.name then return spellInfo.name end
	end
	-- Fallback to legacy API (deprecated in 12.0.0 but may still work)
	if GetSpellInfo then
		local name = GetSpellInfo(spellID)
		if name then return name end
	end
	-- Last resort: use provided fallback or "Unknown"
	return fallbackName or "Unknown"
end

if isRetail then
	sArenaMixin.dispelData = {
		[527] = { texture = GetSpellTexture(527), name = "Purify", classes = L["DispelClass_DiscHolyPriest"], cooldown = 8, healer = true },
		[213634] = { texture = GetSpellTexture(213634), name = "Purify Disease", classes = L["DispelClass_ShadowPriest"], cooldown = 8, showAfterUse = true },
		[4987] = { texture = GetSpellTexture(4987), name = "Cleanse", classes = L["DispelClass_HolyPaladin"], cooldown = 8, healer = true },
		[213644] = { texture = GetSpellTexture(213644), name = "Cleanse Toxins", classes = L["DispelClass_ProtRetPaladin"], cooldown = 8, showAfterUse = true },
		[77130] = { texture = GetSpellTexture(77130), name = "Purify Spirit", classes = L["DispelClass_RestoShaman"], cooldown = 8, healer = true },
		[51886] = { texture = GetSpellTexture(51886), name = "Cleanse Spirit", classes = L["DispelClass_EnhEleShaman"], cooldown = 8, showAfterUse = true },
		[88423] = { texture = GetSpellTexture(88423), name = "Nature's Cure", classes = L["DispelClass_RestoDruid"], cooldown = 8, healer = true },
		[2782] = { texture = GetSpellTexture(2782), name = "Remove Corruption", classes = L["DispelClass_BalFeralGuardianDruid"], cooldown = 8, showAfterUse = true },
		[475] = { texture = GetSpellTexture(475), name = "Remove Curse", classes = L["DispelClass_Mage"], cooldown = 8, showAfterUse = true },
		[218164] = { texture = GetSpellTexture(218164), name = "Detox", classes = L["DispelClass_Monk"], cooldown = 8, showAfterUse = true },
		[115450] = { texture = GetSpellTexture(115450), name = "Detox", classes = L["DispelClass_MistweaverMonk"], cooldown = 8, healer = true },
		[360823] = { texture = GetSpellTexture(360823), name = "Naturalize", classes = L["DispelClass_Evoker"], cooldown = 8, healer = true },
		[374251] = { texture = GetSpellTexture(374251), name = "Cauterizing Flame", classes = L["DispelClass_DevEvoker"], cooldown = 60, showAfterUse = true },
		[119905] = { texture = GetSpellTexture(119905), name = "Singe Magic", classes = L["DispelClass_WarlockPet"], cooldown = 15, showAfterUse = true },
		[132411] = { texture = GetSpellTexture(132411), name = "Singe Magic", classes = L["DispelClass_WarlockGrimoire"], cooldown = 15, showAfterUse = true },
		[212640] = { texture = GetSpellTexture(212640), name = "Mending Bandage", classes = L["DispelClass_SurvivalHunter"], cooldown = 25, showAfterUse = true },
	}

	sArenaMixin.specToDispel = {
		-- Druid
		[102] = 2782,   -- Balance -> Remove Corruption
		[103] = 2782,   -- Feral -> Remove Corruption  
		[104] = 2782,   -- Guardian -> Remove Corruption
		[105] = 88423,  -- Restoration -> Nature's Cure

		-- Evoker
		[1467] = 374251, -- Devastation -> Cauterizing Flame
		[1468] = 360823, -- Preservation -> Naturalize

		-- Hunter
		[255] = 212640,  -- Survival -> Mending Bandage

		-- Mage
		[62] = 475,     -- Arcane -> Remove Curse
		[63] = 475,     -- Fire -> Remove Curse
		[64] = 475,     -- Frost -> Remove Curse

		-- Monk
		[268] = 218164, -- Brewmaster -> Detox
		[269] = 218164, -- Windwalker -> Detox
		[270] = 115450, -- Mistweaver -> Detox

		-- Paladin
		[65] = 4987,    -- Holy -> Cleanse
		[66] = 213644,  -- Protection -> Cleanse Toxins
		[70] = 213644,  -- Retribution -> Cleanse Toxins

		-- Priest
		[256] = 527,    -- Discipline -> Purify
		[257] = 527,    -- Holy -> Purify
		[258] = 213634, -- Shadow -> Purify Disease

		-- Shaman
		[262] = 51886,  -- Elemental -> Cleanse Spirit
		[263] = 51886,  -- Enhancement -> Cleanse Spirit
		[264] = 77130,  -- Restoration -> Purify Spirit

		-- Warlock (both pet and grimoire variants)
		[265] = {119905, 132411}, -- Affliction -> Singe Magic (both pet and grimoire)
		[266] = {119905, 132411}, -- Demonology -> Singe Magic (both pet and grimoire)
		[267] = {119905, 132411}, -- Destruction -> Singe Magic (both pet and grimoire)
	}

	-- Default dispel categories for retail
	sArenaMixin.defaultSettings.profile.dispelCategories = {
		[527] = true,     -- Purify (Priest - Discipline/Holy)
		[4987] = true,    -- Cleanse (Holy Paladin)
		[77130] = true,   -- Purify Spirit (Resto Shaman)
		[88423] = true,   -- Nature's Cure (Resto Druid)
		[115450] = true,  -- Detox (Mistweaver Monk)
		[360823] = true,  -- Naturalize (Preservation Evoker)
	}

else
	sArenaMixin.dispelData = {
		[527] = { texture = GetSpellTexture(527), name = "Purify", classes = L["DispelClass_Priest"], cooldown = 8, healer = true },
		[4987] = { texture = GetSpellTexture(4987), name = "Cleanse", classes = L["DispelClass_HolyPaladin"], cooldown = 8, sharedSpecSpellID = true },
		[77130] = { texture = GetSpellTexture(77130), name = "Purify Spirit", classes = L["DispelClass_RestoShaman"], cooldown = 8, healer = true },
		[51886] = { texture = GetSpellTexture(51886), name = "Cleanse Spirit", classes = L["DispelClass_EnhEleShaman"], cooldown = 8, showAfterUse = true },
		[88423] = { texture = GetSpellTexture(88423), name = "Nature's Cure", classes = L["DispelClass_RestoDruid"], cooldown = 8, healer = true },
		[2782] = { texture = GetSpellTexture(2782), name = "Remove Corruption", classes = L["DispelClass_Druid"], cooldown = 8, showAfterUse = true },
		[475] = { texture = GetSpellTexture(475), name = "Remove Curse", classes = L["DispelClass_Mage"], cooldown = 8, showAfterUse = true },
		[115450] = { texture = GetSpellTexture(115450), name = "Detox", classes = L["DispelClass_Monk"], cooldown = 8, sharedSpecSpellID = true },
		[103150] = { texture = GetSpellTexture(103150), name = "Singe Magic", classes = L["DispelClass_WarlockPet"], cooldown = 10, showAfterUse = true },
		[132411] = { texture = GetSpellTexture(132411), name = "Singe Magic", classes = L["DispelClass_WarlockGrimoire"], cooldown = 10, showAfterUse = true },
		[32375] = { texture = GetSpellTexture(32375), name = "Mass Dispel", classes = L["DispelClass_ShadowPriest"], cooldown = 15, showAfterUse = true },
	}

	sArenaMixin.specToDispel = {
		-- Druid
		[102] = 2782, -- Balance -> Remove Corruption
		[103] = 2782, -- Feral -> Remove Corruption
		[104] = 2782, -- Guardian -> Remove Corruption
		[105] = 88423, -- Restoration -> Nature's Cure

		-- Hunter
		[255] = 212640, -- Survival -> Mending Bandage

		-- Mage
		[62] = 475, -- Arcane -> Remove Curse
		[63] = 475, -- Fire -> Remove Curse
		[64] = 475, -- Frost -> Remove Curse

		-- Monk
		[268] = 115450, -- Brewmaster -> Detox
		[269] = 115450, -- Windwalker -> Detox
		[270] = 115450, -- Mistweaver -> Detox

		-- Paladin
		[65] = 4987, -- Holy -> Cleanse
		[66] = 4987, -- Protection -> Cleanse
		[70] = 4987, -- Retribution -> Cleanse

		-- Priest
		[256] = 527, -- Discipline -> Purify
		[257] = 527, -- Holy -> Purify
		[258] = 32375, -- Shadow -> Mass Dispel

		-- Shaman
		[262] = 51886, -- Elemental -> Cleanse Spirit
		[263] = 51886, -- Enhancement -> Cleanse Spirit
		[264] = 77130, -- Restoration -> Purify Spirit

		-- Warlock (both pet and grimoire variants)
		[265] = { 103150, 132411 }, -- Affliction -> Singe Magic (both pet and grimoire)
		[266] = { 103150, 132411 }, -- Demonology -> Singe Magic (both pet and grimoire)
		[267] = { 103150, 132411 }, -- Destruction -> Singe Magic (both pet and grimoire)
	}

	-- Default dispel categories for MoP  
	sArenaMixin.defaultSettings.profile.dispelCategories = {
		-- Healer spells (enabled by default)
		[77130] = true,   -- Purify Spirit (Resto Shaman)
		[88423] = true,   -- Nature's Cure (Resto Druid)
		[527] = true,   -- Purify (Priest healers)

		-- Shared spells - healer variants (enabled by default)
		["4987_healer"] = true,    -- Cleanse (Holy Paladin)
		["115450_healer"] = true,  -- Detox (Mistweaver)
	}
end

local detectedDispels = {}
local dispelStacks = {}
local lastDispelTime = {}

local DISPEL_RECHARGE_TIME = 8
local DISPEL_THROTTLE = 0.2

local function updateDispelStacksForFrame(frame)
	local unit = frame.unit
	local data = dispelStacks[unit]

	if not data then
		if frame.DispelStacks then
			frame.DispelStacks:SetText("")
		end
		return
	end

	local now = GetTime()

	if #data.rechargeTimes > 0 then
		local newRechargeTimes = {}
		for _, rechargeTime in ipairs(data.rechargeTimes) do
			if rechargeTime > now then
				table.insert(newRechargeTimes, rechargeTime)
			else
				data.charges = math.min(data.maxCharges, data.charges + 1)
			end
		end
		data.rechargeTimes = newRechargeTimes
	end

	if frame.DispelStacks then
		if data.hasMultiCharges then
			frame.DispelStacks:SetText(tostring(data.charges))
		else
			frame.DispelStacks:SetText("")
		end
	end

	local db = frame.parent and frame.parent.db
	local desaturateSetting = db and db.profile and db.profile.desaturateDispelCD

	if data.hasMultiCharges then
		frame.Dispel.Texture:SetDesaturated(desaturateSetting and data.charges == 0)
	else
		frame.Dispel.Texture:SetDesaturated(desaturateSetting and data.charges == 0)
	end

	if #data.rechargeTimes > 0 then
		local soonest = math.huge
		for _, rechargeTime in ipairs(data.rechargeTimes) do
			if rechargeTime < soonest then
				soonest = rechargeTime
			end
		end

		local remaining = soonest - now
		if remaining > 0 then
			local startTime = soonest - DISPEL_RECHARGE_TIME
			frame.Dispel.Cooldown:SetCooldown(startTime, DISPEL_RECHARGE_TIME)

			C_Timer.After(remaining + 0.01, function()
				updateDispelStacksForFrame(frame)
			end)
		else
			frame.Dispel.Cooldown:Clear()
		end
	else
		frame.Dispel.Cooldown:Clear()
	end
end

function sArenaFrameMixin:FindDispel(spellID)
	if not sArenaMixin.dispelData[spellID] then return end

	if not detectedDispels[self.unit] then
		detectedDispels[self.unit] = {}
	end
	detectedDispels[self.unit][spellID] = true

	local dispelInfo = sArenaMixin.dispelData[spellID]
	local cooldown = dispelInfo and dispelInfo.cooldown or 8
	local now = GetTime()

	-- Throttle
	local unitKey = self.unit .. "_" .. spellID
	if lastDispelTime[unitKey] and (now - lastDispelTime[unitKey]) < DISPEL_THROTTLE then
		return
	end

	-- Only handle charge tracking for spell ID 527 (Purify - can have 2 charges with talent)
	if spellID == 527 then
		if not dispelStacks[self.unit] then
			dispelStacks[self.unit] = {
				charges = 1,
				maxCharges = 1,
				hasMultiCharges = false,
				rechargeTimes = {}
			}
		end

		local data = dispelStacks[self.unit]
		-- If they used dispel recently (within cooldown period but past throttle window),
		-- they must have the 2-charge talent. Add 1s leeway to avoid edge cases.
		local timeSinceLastDispel = lastDispelTime[unitKey] and (now - lastDispelTime[unitKey]) or math.huge
		local hasUsedDispelOnCooldown = timeSinceLastDispel < (DISPEL_RECHARGE_TIME - 0.5)

		if hasUsedDispelOnCooldown and not data.hasMultiCharges then
			data.hasMultiCharges = true
			data.maxCharges = 2
		end
	end

	lastDispelTime[unitKey] = now

	if spellID == 527 then
		local data = dispelStacks[self.unit]

		if data.charges > 0 then
			data.charges = data.charges - 1
		end

		-- Calculate when this charge should finish recharging
		-- If there are already charges recharging, queue this one after the last one
		local rechargeEndTime
		if #data.rechargeTimes > 0 then
			-- Start recharging after the last charge finishes
			local lastRechargeTime = data.rechargeTimes[#data.rechargeTimes]
			rechargeEndTime = lastRechargeTime + DISPEL_RECHARGE_TIME
		else
			-- No charges recharging, start immediately
			rechargeEndTime = now + DISPEL_RECHARGE_TIME
		end

		table.insert(data.rechargeTimes, rechargeEndTime)

		updateDispelStacksForFrame(self)
	end

	self.Dispel.Cooldown:SetCooldown(now, cooldown)
	self:UpdateDispel()
end

function sArenaFrameMixin:GetDispelData()
	local specID = self.specID
	if not specID then return end

	local spellData = sArenaMixin.specToDispel[specID]
	if not spellData then return end

	local spellIDs = type(spellData) == "table" and spellData or {spellData}

	for _, spellID in ipairs(spellIDs) do
		if sArenaMixin.dispelData[spellID] then
			local dispelInfo = sArenaMixin.dispelData[spellID]
			local isValid = true

			-- For MoP shared spells, DPS specs need to have used the spell first
			if not isRetail and dispelInfo.sharedSpecSpellID then
				local isHealer = sArenaMixin.healerSpecIDs[specID]
				if not isHealer then
					-- DPS specs need to use the spell first
					if not detectedDispels[self.unit] or not detectedDispels[self.unit][spellID] then
						isValid = false
					end
				end
			elseif dispelInfo.showAfterUse then
				-- Regular showAfterUse logic for unique DPS spells
				if not detectedDispels[self.unit] or not detectedDispels[self.unit][spellID] then
					isValid = false
				end
			end

			if isValid then
				local isEnabled = false

				if isRetail then
					-- Retail: use simple spell-based categories
					isEnabled = self.parent.db.profile.dispelCategories[spellID]
				else
					-- MoP: check if this spell is available for this spec type
					local isHealer = sArenaMixin.healerSpecIDs[specID]

					-- For shared spells, use separate settings
					if dispelInfo.sharedSpecSpellID then
						local settingKey = spellID .. (isHealer and "_healer" or "_dps")
						isEnabled = self.parent.db.profile.dispelCategories[settingKey]
					else
						-- For unique spells, use regular spell setting but check spec type match
						isEnabled = self.parent.db.profile.dispelCategories[spellID]
						if isEnabled then
							local availableForSpec = false
							if isHealer and dispelInfo.healer then
								availableForSpec = true
							elseif not isHealer and not dispelInfo.healer then
								availableForSpec = true
							end

							if not availableForSpec then
								isEnabled = false
							end
						end
					end
				end

				if not isEnabled then
					isValid = false
				end
			end

			if isValid then
				return {
					spellID = spellID,
					texture = dispelInfo.texture,
					name = GetSpellName(spellID, dispelInfo.name),
				}
			end
		end
	end

	return nil
end

function sArenaFrameMixin:GetTestModeDispelData()
	local class = self.tempClass
	if not class then return nil end

	local classToSpellID = {
		["DRUID"] = 88423,   -- Nature's Cure (Resto)
		["EVOKER"] = 360823, -- Naturalize (Preservation)  
		["MAGE"] = 475,      -- Remove Curse
		["MONK"] = 115450,   -- Detox (Mistweaver)
		["PALADIN"] = 4987,  -- Cleanse (Holy)
		["PRIEST"] = 527,    -- Purify
		["SHAMAN"] = 77130,  -- Purify Spirit (Resto)
	}

	local classToTestSpec = {
		["DRUID"] = 105,     -- Restoration
		["EVOKER"] = 1468,   -- Preservation
		["MAGE"] = 62,       -- Arcane
		["MONK"] = 270,      -- Mistweaver
		["PALADIN"] = 65,    -- Holy
		["PRIEST"] = 256,    -- Discipline
		["SHAMAN"] = 264,    -- Restoration
	}

	local spellID = classToSpellID[class]
	local testSpecID = classToTestSpec[class]
	if not spellID or not testSpecID then return nil end

	local dispelInfo = sArenaMixin.dispelData[spellID]
	if not dispelInfo then return nil end

	if self.parent and self.parent.db then
		local isEnabled = false

		if isRetail then
			-- Retail: use simple spell-based categories
			isEnabled = self.parent.db.profile.dispelCategories[spellID]
		else
			-- MoP: check if this spell is available for this spec type
			local isHealer = sArenaMixin.healerSpecIDs[testSpecID]

			-- For shared spells, use separate settings
			if dispelInfo.sharedSpecSpellID then
				local settingKey = spellID .. (isHealer and "_healer" or "_dps")
				isEnabled = self.parent.db.profile.dispelCategories[settingKey]
			else
				-- For unique spells, use regular spell setting but check spec type match
				isEnabled = self.parent.db.profile.dispelCategories[spellID]
				if isEnabled then
					local availableForSpec = false
					if isHealer and dispelInfo.healer then
						availableForSpec = true
					elseif not isHealer and not dispelInfo.healer then
						availableForSpec = true
					end

					if not availableForSpec then
						isEnabled = false
					end
				end
			end
		end

		if isEnabled then
			return {
				spellID = spellID,
				texture = dispelInfo.texture,
				name = GetSpellName(spellID, dispelInfo.name),
			}
		end
	end
end

function sArenaFrameMixin:UpdateDispel()
	local dispel = self.Dispel
	local db = self.parent.db
	local dispelEnabled = db.profile.showDispels
	local dispelInfo = self:GetDispelData()

	local shouldShow = dispelEnabled and dispelInfo ~= nil
	dispel:SetShown(shouldShow)

	if not dispelInfo then
		dispel.Texture:SetTexture(nil)
		return
	end

	dispel.spellID = dispelInfo.spellID
	dispel.Texture:SetTexture(dispelInfo.texture)

	-- Only spell ID 527 (Purify) uses charge tracking
	if dispelInfo.spellID == 527 then
		updateDispelStacksForFrame(self)
	else
		local onCooldown = db.profile.desaturateDispelCD and dispel.Cooldown:GetCooldownDuration() > 0
		dispel.Texture:SetDesaturated(onCooldown)
	end
end


function sArenaMixin:ResetDetectedDispels()
	wipe(detectedDispels)
	wipe(dispelStacks)
	wipe(lastDispelTime)
end

function sArenaFrameMixin:ResetDispel()
	local dispel = self.Dispel

	dispel.spellID = nil
	dispel.Texture:SetTexture(nil)
	dispel.Cooldown:Clear()
	detectedDispels[self.unit] = nil
	dispelStacks[self.unit] = nil
	dispel.Texture:SetDesaturated(false)

	for key in pairs(lastDispelTime) do
		if key:match("^" .. self.unit .. "_") then
			lastDispelTime[key] = nil
		end
	end

	if self.DispelStacks then
		self.DispelStacks:SetText("")
	end
end
