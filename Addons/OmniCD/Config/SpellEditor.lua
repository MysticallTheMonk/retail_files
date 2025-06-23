local E, L = select(2, ...):unpack()

local GetNumSpecializationsForClassID = GetNumSpecializationsForClassID
local GetSpecializationInfoForClassID = GetSpecializationInfoForClassID
local GetSpecializationInfoByID = GetSpecializationInfoByID
if E.preCata then
	GetNumSpecializationsForClassID = function() return 0 end
	GetSpecializationInfoForClassID = E.Noop
	GetSpecializationInfoByID = E.Noop
end

local defaultBackup = {}
local classValues = {}
local specIDs = {}

for i = 1, MAX_CLASSES do
	local class = CLASS_SORT_ORDER[i]
	classValues[class] = format("|T%s:18|t %s", "Interface\\Icons\\ClassIcon_" .. class, LOCALIZED_CLASS_NAMES_MALE[class])
	for j = 1, GetNumSpecializationsForClassID(i) do
		local id = GetSpecializationInfoForClassID(i, j)
		specIDs[#specIDs + 1] = id
	end
end
classValues["TRINKET"] = format("|T%s:16|t %s", E.TEXTURES.TRINKET, L["Trinket, Main Hand"])

function E:UpdateSpell(id, isInit, oldClass, oldType)
	local spellInfo = self.hash_spelldb[id]
	local v = OmniCDDB.cooldowns[id]


	if v then

		if not spellInfo then
			self.hash_spelldb[id] = v

		elseif not v.custom and not defaultBackup[id] then
			defaultBackup[id] = self:DeepCopy(self.hash_spelldb[id])
			self.hash_spelldb[id] = v
			if self.L_HIGHLIGHTS[v.type] then
				self.Cooldowns:RegisterRemoveHighlightByCLEU(v.buff or id)
			end
			return
		end


		if self.L_HIGHLIGHTS[v.type] then
			self.Cooldowns:RegisterRemoveHighlightByCLEU(v.buff or id)
		end

	else

		v = defaultBackup[id]
		if v then
			self.hash_spelldb[id] = self:DeepCopy(v)

		else
			self.hash_spelldb[id] = nil

		end
	end

	if not isInit then
		for moduleName in pairs(self.moduleOptions) do
			local module = self[moduleName]
			local func = module.UpdateSpellsOption
			if func then
				func(module, id, oldClass, oldType, v)
			end
		end
	end
end

local GetSpellID = function(info, n)
	n = n or 1
	local id = info[#info - n]
	return tonumber(id), id
end

local function GetSpecID(info, n)
	n = n or 1
	local id = info[#info - n]:gsub("spec", "")
	return tonumber(id)
end

local isOthersCategory = function(info)
	local id = GetSpellID(info)
	return not E.BOOKTYPE_CATEGORY[OmniCDDB.cooldowns[id].class]
end

local isClassCategory = function(info)
	local id = GetSpellID(info)
	return OmniCDDB.cooldowns[id].class ~= "TRINKET"
end

local getGlobalDurationCharge = function(info)
	local option = info[#info]
	local id = GetSpellID(info)
	return OmniCDDB.cooldowns[id][option].default
end

local setGlobalDurationCharge = function(info, value)
	local option = info[#info]
	local id = GetSpellID(info)
	OmniCDDB.cooldowns[id][option].default = value
	E:UpdateSpell(id)
end

local getItem = function(info)
	local option = info[#info]
	local id = GetSpellID(info)
	local v = OmniCDDB.cooldowns[id][option]
	if v then
		return tostring(v)
	end
end

local setItem = function(info, v)
	local option = info[#info]
	local id = GetSpellID(info)
	if v == "" then
		if option == "icon" then
			local itemTexture = OmniCDDB.cooldowns[id].item
			OmniCDDB.cooldowns[id][option] = itemTexture and C_Item.GetItemIconByID(itemTexture) or select(2, C_Spell.GetSpellTexture(id))
		else
			OmniCDDB.cooldowns[id][option] = nil
		end
	else
		if strmatch(v, "[^%d]+") or strlen(v) > 9 or not C_Item.DoesItemExistByID(v) then
			E.write(L["Invalid ID"], v)
			return
		end
		OmniCDDB.cooldowns[id][option] = tonumber(v)
	end

	E:UpdateSpell(id)
end

local function CreateClassSpecTable(id)
	local t = {}
	for i = 1, #specIDs do
		local class = select(6, GetSpecializationInfoByID(specIDs[i]))
		if OmniCDDB.cooldowns[id].class == class then
			tinsert(t, specIDs[i])
		end
	end
	return #t > 0 and t or nil
end

local customSpellInfo = {
	spellName = {
		name = function(info)
			local id = GetSpellID(info)
			return format("|cffffd200 %s:|r %s |cff20ff20%s", L["Spell ID"], id, defaultBackup[id] and "" or L["Custom"])
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
			local oldClass, oldType = OmniCDDB.cooldowns[id].class, OmniCDDB.cooldowns[id].type
			if not defaultBackup[id] then
				for moduleName in pairs(E.moduleOptions) do
					local t = E[moduleName].spell_enabled
					if t then
						t[id] = nil
					end
				end
				for key in pairs(E.L_CFG_ZONE) do
					E.profile.Party[key].spells[sId] = nil
					E.profile.Party[key].spellFrame[id] = nil
					E.profile.Party[key].spellPriority[id] = nil
					E.profile.Party[key].spellGlow[id] = nil
				end
			end
			OmniCDDB.cooldowns[id] = nil
			E.options.args.SpellEditor.args.editor.args[sId] = nil
			E:UpdateSpell(id, nil, oldClass, oldType)
		end,
	},
	hd1 = {
		name = "", order = 2, type = "header",
	},
	class = {
		disabled = function(info)
			local id = GetSpellID(info)
			return defaultBackup[id]
		end,
		name = CLASS,
		order = 3,
		type = "select",
		values = classValues,
		set = function(info, value)
			local id = GetSpellID(info)
			local oldClass, oldType = OmniCDDB.cooldowns[id].class, OmniCDDB.cooldowns[id].type
			OmniCDDB.cooldowns[id].duration = { default = OmniCDDB.cooldowns[id].duration.default }
			OmniCDDB.cooldowns[id].charges = { default = OmniCDDB.cooldowns[id].charges.default }
			OmniCDDB.cooldowns[id].class = value
			OmniCDDB.cooldowns[id].spec = CreateClassSpecTable(id)

			E:UpdateSpell(id, nil, oldClass, oldType)
		end,
	},
	type = {
		name = TYPE,
		desc = L["Set the spell type for sorting"],
		order = 4,
		type = "select",
		values = E.L_PRIORITY,
		set = function(info, value)
			local id = GetSpellID(info)
			local oldClass, oldType = OmniCDDB.cooldowns[id].class, OmniCDDB.cooldowns[id].type
			OmniCDDB.cooldowns[id][ info[#info] ] = value

			E:UpdateSpell(id, nil, oldClass, oldType)
		end,
	},
	duration = {
		name = L["Cooldown"],
		desc = E.STR.MAX_RANGE_3600,
		order = 5,
		type = "range",
		min = 1, max = 3600, softMax = 300, step = 1,
		get = getGlobalDurationCharge,
		set = setGlobalDurationCharge,
	},
	charges = {
		name = function(info)
			local id = GetSpellID(info)
			local value = OmniCDDB.cooldowns[id].charges.default
			return format(SPELL_MAX_CHARGES, value)
		end,
		order = 6,
		type = "range",
		min = 1, max = 10, step = 1,
		get = getGlobalDurationCharge,
		set = setGlobalDurationCharge,
	},
	lb1 = {
		name = "\n", order = 7, type = "description",
	},
	talentId = {
		hidden = isOthersCategory,
		name = L["Talent ID"],
		desc = format("%s\n\n%s",
			L["Enter talent ID if the spell is a talent ability in any of the class specializations. This ensures proper spell detection."],
			L["Use a semi-colon(;) to seperate multiple IDs."]),
		order = 10,
		type = "input",
		get = function(info)
			local id = GetSpellID(info)
			local spec = OmniCDDB.cooldowns[id].spec or CreateClassSpecTable(id)
			if spec then
				return table.concat(spec, ";")
			end
		end,
		set = function(info, value)
			local id = GetSpellID(info)
			local t = OmniCDDB.cooldowns[id].spec
			if t then
				wipe(t)
			else
				t = {}
				OmniCDDB.cooldowns[id].spec = t
			end

			value = gsub(value, ("[^%d;]"), "")
			local s, e, v = 1
			while true do
				s, e, v = strfind(value, "([^;]+)", s)
				if s == nil then break end
				s = e + 1
				if strlen(v) < 9 and (C_Spell.DoesSpellExist(v) or GetSpecializationInfoByID(v)) then
					tinsert(t, tonumber(v))
				end
			end

			E:UpdateSpell(id)
		end,
	},
	item = {
		hidden = isClassCategory,
		name = format("%s: %s", L["Trinket, Main Hand"], L["Item ID (Optional)"]),
		desc = L["Enter item ID to enable spell when the item is equipped only"],
		order = 11,
		type = "input",
		get = getItem,
		set = setItem,
	},
	item2 = {
		disabled = function(info)
			local id = GetSpellID(info)
			return OmniCDDB.cooldowns[id].item == nil
		end,
		hidden = isClassCategory,
		name = L["Item ID (Optional)"] .. " 2",
		order = 12,
		type = "input",
		get = getItem,
		set = setItem,
	},
	lb3 = {
		name = "", order = 14, type = "description",
	},
	buff = {
		hidden = function(info)
			local id = GetSpellID(info)
			return not E.L_HIGHLIGHTS[OmniCDDB.cooldowns[id].type]
		end,
		name = L["Buff ID (Optional)"],
		desc = format("%s\n\n|cffff2020%s", L["Enter buff ID if it differs from spell ID for Highlights to work"], L["0: Disable option"]),
		order = 15,
		type = "input",
		get = function(info)
			local option = info[#info]
			local id = GetSpellID(info)
			local v = OmniCDDB.cooldowns[id][option]
			return v and tostring(v) or tostring(id)
		end,
		set = function(info, v)
			local option = info[#info]
			local id = GetSpellID(info)
			if v == "" then
				OmniCDDB.cooldowns[id][option] = id
			else
				if strmatch(v, "[^%d]+") or strlen(v) > 9 or not C_Spell.DoesSpellExist(v) then
					E.write(L["Invalid ID"], v)
					return
				end
				OmniCDDB.cooldowns[id][option] = tonumber(v)
			end

			E:UpdateSpell(id)
		end,
	},
	lb4 = {
		name = "\n", order = 16, type = "description",
	},
	icon = {
		hidden = isClassCategory,
		name = L["Icon ID (Optional)"],
		order = 17,
		type = "input",
		get = getItem,
		set = setItem,
	},
}

if E.postMoP then
	local customSpellSpecInfo = {
		enabled = {
			name = L["Always Show"],
			desc = L["Enable if the spell is a base ability for this specialization"],
			order = 1,
			type = "toggle",
			get = function(info)
				local id = GetSpellID(info, 2)
				local specID = GetSpecID(info)
				local spec = OmniCDDB.cooldowns[id].spec or CreateClassSpecTable(id)
				for i = 1, #spec do
					if spec[i] == specID then return true end
				end
			end,
			set = function(info, value)
				local id = GetSpellID(info, 2)
				local specID = GetSpecID(info)
				OmniCDDB.cooldowns[id].spec = OmniCDDB.cooldowns[id].spec or CreateClassSpecTable(id)
				if value then
					tinsert(OmniCDDB.cooldowns[id].spec, specID)
				else
					for i = #OmniCDDB.cooldowns[id].spec, 1, -1 do
						if OmniCDDB.cooldowns[id].spec[i] == specID then
							tremove(OmniCDDB.cooldowns[id].spec, i)
							break
						end
					end
				end

				E:UpdateSpell(id)
			end,
		},
		disable = {
			name = L["Force Disable"],
			desc = L["Only for talent abilities.\nCurrent ability for this specialization will no longer be tracked while you are in the selected zone(s)"],
			order = 2,
			type = "multiselect",
			dialogControl = "Dropdown-OmniCDC",
			values = E.L_ALL_ZONE,
			get = function(info, k)
				local id = GetSpellID(info, 2)
				local specID = GetSpecID(info)
				local option = OmniCDDB.cooldowns[id].disabledSpec
				return option and option[specID] and option[specID][k]
			end,
			set = function(info, k, value)
				local id = GetSpellID(info, 2)
				local specID = GetSpecID(info)
				OmniCDDB.cooldowns[id].disabledSpec = OmniCDDB.cooldowns[id].disabledSpec or {}
				OmniCDDB.cooldowns[id].disabledSpec[specID] = OmniCDDB.cooldowns[id].disabledSpec[specID] or {}
				OmniCDDB.cooldowns[id].disabledSpec[specID][k] = value or nil
				if next(OmniCDDB.cooldowns[id].disabledSpec[specID]) == nil then
					OmniCDDB.cooldowns[id].disabledSpec[specID] = nil
				end
				if next(OmniCDDB.cooldowns[id].disabledSpec) == nil then
					OmniCDDB.cooldowns[id].disabledSpec = nil
				end
				E:UpdateSpell(id)
			end,
		},
		hd1 = {
			name = "", order = 3, type = "header",
		},
		duration = {
			name = L["Cooldown"],
			desc = L["Set to override the global cooldown setting for this specialization"],
			order = 4,
			type = "range",
			min = 1, max = 999, softMax = 300, step = 1,
		},
		charges = {
			name = L["Charges"],
			order = 5,
			type = "range",
			min = 1, max = 10, step = 1,
		},
	}

	local customSpellSpecGroup = {
		hidden = function(info)
			local specID = GetSpecID(info, 0)
			if not specID then
				return
			end
			local id = GetSpellID(info)
			local class = OmniCDDB.cooldowns[id].class
			if class == "TRINKET" then return true end
			if class ~= select(6, GetSpecializationInfoByID(specID)) then return true end
		end,
		icon = function(info)
			local specID = GetSpecID(info, 0)
			return select(4,GetSpecializationInfoByID(specID))
		end,
		iconCoords = E.BORDERLESS_TCOORDS,
		name = function(info)
			local specID = GetSpecID(info, 0)
			return select(2,GetSpecializationInfoByID(specID))
		end,
		type = "group",
		get = function(info)
			local option = info[#info]
			local id = GetSpellID(info, 2)
			local specID = GetSpecID(info)
			return OmniCDDB.cooldowns[id][option][specID] or OmniCDDB.cooldowns[id][option].default
		end,
		set = function(info, value)
			local option = info[#info]
			local id = GetSpellID(info, 2)
			local specID = GetSpecID(info)
			if value == OmniCDDB.cooldowns[id][option].default then
				value = nil
			end
			OmniCDDB.cooldowns[id][option][specID] = value

			E:UpdateSpell(id)
		end,
		args = customSpellSpecInfo
	}

	for i = 1, #specIDs do
		local specID = specIDs[i]
		customSpellInfo["spec" .. specID] = customSpellSpecGroup
	end
end

local customSpellGroup = {
	icon = function(info)
		local id = GetSpellID(info, 0)
		return select(2,C_Spell.GetSpellTexture(id))
	end,
	iconCoords = E.BORDERLESS_TCOORDS,
	name = function(info)
		local id = GetSpellID(info, 0)
		return C_Spell.GetSpellName(id)
	end,

	desc = E.isClassic and function(info)
		local id = GetSpellID(info, 0)
		return C_Spell.GetSpellDescription(GetSpellID(info, 0))
	end or nil,

	tooltipHyperlink = not E.isClassic and function(info)
		local id = GetSpellID(info, 0)
		return C_Spell.GetSpellLink(id)
	end or nil,
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

	if not OmniCDDB.cooldowns[id] then
		local spellInfo = E.hash_spelldb[id]
		if spellInfo then
			OmniCDDB.cooldowns[id] = spellInfo

			local duration = spellInfo.duration
			if type(duration) == "number" then
				spellInfo.duration = { default = duration }
			end

			local charges = spellInfo.charges
			if type(charges) ~= "table" then
				spellInfo.charges = { default = charges or 1 }
			end

			local spec = spellInfo.spec or CreateClassSpecTable(id)
			spec = spec == true and id or (type(spec) == "number" and spec)
			if spec then
				spellInfo.spec = { spec }
			end
		else
			OmniCDDB.cooldowns[id] = {
				["class"] = "TRINKET",
				["spellID"] = id,
				["type"] = "trinket",
				["duration"] = {default = 30},
				["charges"] = {default = 1},
				["name"] = name,
				["icon"] = select(2, C_Spell.GetSpellTexture(id)),
				["buff"] = id,
				["custom"] = true,
			}
		end
		E.options.args.SpellEditor.args.editor.args[value] = customSpellGroup
		E:UpdateSpell(id)
	end
	E.Libs.ACD:SelectGroup(E.AddOn, "SpellEditor", "editor", value)
end

local SpellEditor = {
	name = L["Spell Editor"],
	order = 900,
	type = "group",
	childGroups = "tab",
	get = function(info)
		local option = info[#info]
		local id = GetSpellID(info)
		if id then
			return OmniCDDB.cooldowns[id][option]
		end
	end,
	set = function(info, value)
		local option = info[#info]
		local id = GetSpellID(info)
		OmniCDDB.cooldowns[id][option] = value
		E:UpdateSpell(id)
	end,
	args = {
		editor = {
			name = L["Spell Editor"],
			order = 10,
			type = "group",
			args ={
				spellId = {
					order = 0,
					name = L["Spell ID"],
					desc = L["Enter Spell ID to Add/Edit"],
					type = "input",
					set = E.EditSpell,
				},
			}
		},
	}
}

function E:AddSpellPickers()
	for moduleName in pairs(self.moduleOptions) do
		local func = self[moduleName].AddSpellPicker
		if func then
			func(self[moduleName])
		end
	end
end

function E:AddSpellEditor()
	for id in pairs(OmniCDDB.cooldowns) do
		if not C_Spell.DoesSpellExist(id) then
			OmniCDDB.cooldowns[id] = nil
			--[==[@debug@
			E.write("Removing invalid custom ID:" , id)
			--@end-debug@]==]
		else
			id = tostring(id)
			SpellEditor.args.editor.args[id] = customSpellGroup
		end
	end
	self.options.args["SpellEditor"] = SpellEditor
end

function E:UpdateSpellList(isInit)
	for id in pairs(OmniCDDB.cooldowns) do
		self:UpdateSpell(id, isInit)
	end
end
