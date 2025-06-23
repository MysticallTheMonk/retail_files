local E, L = unpack(select(2, ...))

local defaultBackup = {}
local classValues = {}
local classIndex = {}

for i = 1, MAX_CLASSES do
	local class = CLASS_SORT_ORDER[i] -- 1 == WARRIOR
	classValues[class] = format("|T%s:18|t %s", "Interface\\Icons\\ClassIcon_" .. class, LOCALIZED_CLASS_NAMES_MALE[class])
	classIndex[class] = i
end
classValues["ALL"] = ALL

local auraTypeToClassPriority = {
	priorityDebuff="hardCC",stun="hardCC",disorient="hardCC",incapacitate="hardCC",silence="softCC",interrupt="softCC",disarm="disarmRoot",root="disarmRoot",
	dispel="debuff",dispelProtection="debuff",increaseDamageTaken="debuff",reduceHealingReceived="debuff",reduceDamageHealingDone="debuff",offensiveDebuff="debuff",snare="debuff",misc="debuff",
	onCd="base",
	priorityBuff="immunity",immunity="immunity",ccImmunity="otherImmunity",spellImmunity="spellImmunity",stunFearSilenceImmunity="otherImmunity",damageImmunity="otherImmunity",
	ccDurationReducer="buff",externalDefensive="defensive",personalDefensive="defensive",tankDefensive="defensive",minorDefensive="defensive",
	offensive="offensive",minorOffensive="offensive",healing="healing",
	freedom="freedom",
	increaseMovementSpeed="buff",hotStack="buff",miscBuff="buff",
	stance="base",npc="base",
}

local function GetAuraInfo(id)
	for auraFilter, t in pairs(E.aura_db) do
		local aura = t[id]
		if aura then
			return auraFilter,  aura[1],  aura[2],	aura[3]
		end
	end
end

local L_AURATYPE = {
	INTERRUPT = {
		interrupt=L["interrupt"],
	},
	HARMFUL = {
		priorityDebuff=L["priorityDebuff"],stun=L["stun"],disorient=L["disorient"],incapacitate=L["incapacitate"],silence=L["silence"],disarm=L["disarm"],root=L["root"],
		dispel=L["dispel"],dispelProtection=L["dispelProtection"],increaseDamageTaken=L["increaseDamageTaken"],reduceHealingReceived=L["reduceHealingReceived"],reduceDamageHealingDone=L["reduceDamageHealingDone"],offensiveDebuff=L["offensiveDebuff"],snare=L["snare"],misc=L["misc"],
		onCd=L["onCd"],
	},
	HELPFUL = {
		priorityBuff=L["priorityBuff"],immunity=L["immunity"],ccImmunity=L["ccImmunity"],spellImmunity=L["spellImmunity"],stunFearSilenceImmunity=L["stunFearSilenceImmunity"],damageImmunity=L["damageImmunity"],
		ccDurationReducer=L["ccDurationReducer"],externalDefensive=L["externalDefensive"],personalDefensive=L["personalDefensive"],tankDefensive=L["tankDefensive"],minorDefensive=L["minorDefensive"],
		offensive=L["offensive"],minorOffensive=L["minorOffensive"],healing=L["healing"],
		freedom=L["freedom"],
		increaseMovementSpeed=L["increaseMovementSpeed"],hotStack=L["hotStack"],miscBuff=L["miscBuff"],
		stance=L["stance"],
	},
	PVE = {
		npc=L["npc"],
	},
}

local function GetAuraFilterByType(auraType)
	for filter, v in pairs(L_AURATYPE) do
		if v[auraType] then
			return filter
		end
	end
end

function E:UpdateSpell(id, isInit, oldFilter, oldType)
	local auraFilter = GetAuraInfo(id)
	local v = OmniAurasDB.cooldowns[id]
	local vauraFilter, vauraClassPriority, vauraType, vclassID, isNewCustom
	if v then
		vauraClassPriority, vauraType, vclassID = v[1], v[2], v[3]
		vauraFilter = GetAuraFilterByType(vauraType)
		if auraFilter ~= vauraFilter then
			if auraFilter then -- filter change
				self.aura_db[auraFilter][id] = nil
			else -- add custom
				isNewCustom = true
			end
		elseif not v.custom and not defaultBackup[id] then -- add default
			defaultBackup[id] = self:DeepCopy(self.aura_db[auraFilter][id])
		end -- type/class change
		self.aura_db[vauraFilter][id] = v
	else
		v = defaultBackup[id]
		if v then -- delete default
			vauraClassPriority, vauraType, vclassID = v[1], v[2], v[3]
			vauraFilter = GetAuraFilterByType(vauraType)
			self.aura_db[vauraFilter][id] = self:DeepCopy(v)
		else -- delete custom
			self.aura_db[auraFilter][id] = nil
			-- clean up db
			local sId = tostring(id)
			if OmniAurasDB.profiles then
				for _, profile in pairs(OmniAurasDB.profiles) do
					if profile.auras and profile.auras[sId] then
						profile.auras[sId] = nil
					end
				end
			end
		end
	end

	if not isInit then
		self:UpdateSpellsOption(id, oldFilter, oldType, vauraFilter, vauraClassPriority, vauraType, vclassID, isNewCustom)
	end
end

local GetSpellID = function(info, n)
	n = n or 1
	local id = info[#info - n]
	return tonumber(id), id
end

local customSpellInfo = {
	spellName = {
		name = function(info)
			local id = GetSpellID(info)
			return format("|cffffd200 %s:|r %s |cff20ff20%s", L["Aura ID"], id, defaultBackup[id] and "" or L["Custom"])
		end,
		order = 0,
		type = "description",
	},
	delete = {
		name = DELETE,
		desc = L["Default spells are reverted back to original values and removed from the list only"],
		order = 1,
		type = "execute",
		func = function(info)
			local id, sId = GetSpellID(info)
			local oldType = OmniAurasDB.cooldowns[id][2]
			local oldFilter = GetAuraFilterByType(oldType)
			OmniAurasDB.cooldowns[id] = nil
			E.options.args.SpellEditor.args.editor.args[sId] = nil

			E:UpdateSpell(id, nil, oldFilter, oldType)
		end,
	},
	hd1 = {
		name = "", order = 2, type = "header",
	},
	filter = {
		name = L["Filter"],
		order = 3,
		type = "select",
		values = {
			INTERRUPT = L["Interrupts"],
			HARMFUL = L["Debuffs"],
			HELPFUL = L["Buffs"],
			PVE = L["NPC Auras"],
		},
		get = function(info)
			local id = GetSpellID(info)
			local v = OmniAurasDB.cooldowns[id]
			return GetAuraFilterByType(v[2])
		end,
		set = function(info, value)
			local id = GetSpellID(info)
			local oldType = OmniAurasDB.cooldowns[id][2]
			local oldFilter = GetAuraFilterByType(oldType)
			local v = OmniAurasDB.cooldowns[id]
			local auraFilter = GetAuraFilterByType(v[2])
			if value ~= auraFilter then
				if value == "HARMFUL" then
					OmniAurasDB.cooldowns[id][1] = "hardCC"
					OmniAurasDB.cooldowns[id][2] = "priorityDebuff"
				elseif value == "HELPFUL" then
					OmniAurasDB.cooldowns[id][1] = "immunity"
					OmniAurasDB.cooldowns[id][2] = "immunity"
				elseif value == "INTERRUPT" then
					OmniAurasDB.cooldowns[id][1] = "softCC"
					OmniAurasDB.cooldowns[id][2] = "interrupt"
				else
					OmniAurasDB.cooldowns[id][1] = "base"
					OmniAurasDB.cooldowns[id][2] = "npc"
				end
			end

			E:UpdateSpell(id, nil, oldFilter, oldType)
		end,
	},
	type = {
		name = TYPE,
		order = 4,
		type = "select",
		values = function(info)
			local id = GetSpellID(info)
			local value = OmniAurasDB.cooldowns[id][2]
			for _, v in pairs(L_AURATYPE) do
				if v[value] then
					return v
				end
			end
		end,
		get = function(info)
			local id = GetSpellID(info)
			return OmniAurasDB.cooldowns[id][2]
		end,
		set = function(info, value)
			local id = GetSpellID(info)
			local oldType = OmniAurasDB.cooldowns[id][2]
			local oldFilter = GetAuraFilterByType(oldType)
			local classPriority = auraTypeToClassPriority[value]
			OmniAurasDB.cooldowns[id][1] = classPriority
			OmniAurasDB.cooldowns[id][2] = value

			E:UpdateSpell(id, nil, oldFilter, oldType)
		end,
	},
	class = {
		disabled = function(info)
			local id = GetSpellID(info)
			return defaultBackup[id]
		end,
		name = CLASS,
		order = 5,
		type = "select",
		values = classValues,
		get = function(info)
			local id = GetSpellID(info)
			return CLASS_SORT_ORDER[ OmniAurasDB.cooldowns[id][3] ] or "ALL"
		end,
		set = function(info, value)
			local id = GetSpellID(info)
			local oldType = OmniAurasDB.cooldowns[id][2]
			local oldFilter = GetAuraFilterByType(oldType)
			OmniAurasDB.cooldowns[id][3] = classIndex[value]

			E:UpdateSpell(id, nil, oldFilter, oldType)
		end,
	},
}

local customSpellGroup = {
	icon = function(info)
		local id = GetSpellID(info,0)
		return select(2,C_Spell.GetSpellTexture(id))
	end,
	iconCoords = E.BORDERLESS_TCOORDS,
	name = function(info)
		local id = GetSpellID(info,0)
		return C_Spell.GetSpellName(id)
	end,
	type = "group",
	args = customSpellInfo,
}

E.EditSpell = function(_, value)
	if strlen(value) > 9 then
		return E.write(L["Invalid ID"], value)
	end
	local id = tonumber(value)
	local name = id and C_Spell.GetSpellName(id)
	if not name then
		return E.write(L["Invalid ID"], value)
	end

	if OmniAurasDB.cooldowns[id] then
		return E.Libs.ACD:SelectGroup(E.AddOn, "SpellEditor", "editor", value)
	end

	local auraFilter, auraClassPriority, auraType, classID = GetAuraInfo(id)
	if auraFilter then
		OmniAurasDB.cooldowns[id] = { auraClassPriority, auraType, classID }
	else
		OmniAurasDB.cooldowns[id] = { "hardCC", "priorityDebuff", nil, custom = true }
	end

	E.options.args.SpellEditor.args.editor.args[value] = customSpellGroup

	E:UpdateSpell(id)
	E.Libs.ACD:SelectGroup(E.AddOn, "SpellEditor", "editor", value)
end

local SpellEditor = {
	name = L["Aura Editor"],
	order = 500,
	type = "group",
	childGroups = "tab",
	args = {
		editor = {
			name = L["Aura Editor"],
			order = 10,
			type = "group",
			args ={
				spellId = {
					order = 0,
					name = L["Aura ID"],
					desc = L["Enter aura ID to add/edit"],
					type = "input",
					set = E.EditSpell,
				},
			}
		},
	}
}

function E:AddSpellEditor()
	for id in pairs(OmniAurasDB.cooldowns) do
		if not C_Spell.DoesSpellExist(id) then
			OmniAurasDB.cooldowns[id] = nil
			E.write("Removing invalid custom ID:" , id)
		else
			id = tostring(id)
			SpellEditor.args.editor.args[id] = customSpellGroup
		end
	end

	self.options.args["SpellEditor"] = SpellEditor
	self:AddSpellPicker()
end

function E:UpdateSpellList(isInit)
	for id in pairs(OmniAurasDB.cooldowns) do
		self:UpdateSpell(id, isInit)
	end
end

--OmniAuras.EditSpell = E.EditSpell -- multiselect checkbox doesn't support click-to-edit
