local E, L, C = select(2, ...):unpack()
local P = E.Party

P.clearAllDefault = function(info)
	local key = info[2]
	P:ResetOption(key, "spells")
	P:ResetOption(key, "spellFrame")
	P:ResetOption(key, "spellPriority")
	P:ResetOption(key, "spellGlow")
	if info[#info] == "clearAll" then
		for sId, t in pairs(E.profile.Party[key].spells) do
			E.profile.Party[key].spells[sId] = false
		end
	end
	if P:IsCurrentZone(key) then
		P:UpdateEnabledSpells()
		P:UpdateAllBars()
	end
end

P.getForbearance = function(info)
	return E.profile.Party[ info[2] ].icons.showForbearanceCounter
end

P.setForbearance = function(info, state)
	local key = info[2]
	E.profile.Party[key].icons.showForbearanceCounter = state
	if P:IsCurrentZone(key) then
		P:Refresh()
	end
end

P.getSpell = function(info)
	return E.profile.Party[ info[2] ][ info[#info] ][ info[#info-1] ]
end

P.setSpell = function(info, state)
	local key, sId, opt = info[2], info[#info-1], info[#info]
	E.profile.Party[key][opt][sId] = state
	if P:IsCurrentZone(key) then
		P:UpdateEnabledSpells()
		P:UpdateAllBars()
	end
end

P.getFrame = function(info)
	local key, id = info[2], tonumber(info[#info-1])
	return E.profile.Party[key].spellFrame[id] or E.profile.Party[key].frame[E.hash_spelldb[id].type]
end

P.setFrame = function(info, value)
	local key, id = info[2], tonumber(info[#info-1])

	if E.profile.Party[key].frame[E.hash_spelldb[id].type] == value then
		value = nil
	end
	E.profile.Party[key].spellFrame[id] = value
	if P:IsCurrentZone(key) then
		P:UpdateEnabledSpells()
		P:UpdateAllBars()
	end
end

P.getPriority = function(info)
	local key, id = info[2], tonumber(info[#info-1])
	return E.profile.Party[key].spellPriority[id] or E.profile.Party[key].priority[E.hash_spelldb[id].type]
end

P.setPriority = function(info, value)
	local key, id = info[2], tonumber(info[#info-1])
	local type = E.hash_spelldb[id].type
	if E.profile.Party[key].priority[type] == value then
		value = nil
	end
	E.profile.Party[key].spellPriority[id] = value
	if P:IsCurrentZone(key) then
		P:UpdateAllBars()
	end
end

P.getGlow = function(info)
	return E.profile.Party[ info[2] ][ info[#info] ][ tonumber(info[#info-1]) ]
end

P.setGlow = function(info, state)
	local key, id, opt = info[2], tonumber(info[#info-1]), info[#info]
	E.profile.Party[key][opt][id] = state
	if P:IsCurrentZone(key) then
		P:Refresh()
	end
end

local function clearAllDefault(info) E[ info[1] ].clearAllDefault(info) end
local function GetForbearance(info) return E[ info[1] ].getForbearance(info) end
local function SetForbearance(info, value) E[ info[1] ].setForbearance(info, value) end
local function GetSpell(info) return E[ info[1] ].getSpell(info) end
local function SetSpell(info, value) E[ info[1] ].setSpell(info, value) end
local function GetFrame(info) return E[ info[1] ].getFrame(info) end
local function SetFrame(info, value) return E[ info[1] ].setFrame(info, value) end
local function GetPriority(info) return E[ info[1] ].getPriority(info) end
local function SetPriority(info, value) E[ info[1] ].setPriority(info, value) end
local function GetGlow(info) return E[ info[1] ].getGlow(info) end
local function SetGlow(info, value) E[ info[1] ].setGlow(info, value) end

local function GetSpellsTbl()
	return {
	name = L["Spells"],
	order = 70,
	type = "group", childGroups = "tab",
	args = {
		clearAll = {
			name = CLEAR_ALL,
			order = 1,
			type = "execute",
			func = clearAllDefault,
			confirm = E.ConfirmAction,
		},
		default = {
			name = RESET_TO_DEFAULT,
			order = 2,
			type = "execute",
			func = clearAllDefault,
			confirm = E.ConfirmAction,
		},
		showForbearanceCounter = {
			hidden = E.isClassic,
			name = L["Show Forbearance CD"],
			desc = L["Show timer on spells while under the effect of Forbearance or Hypothermia. Spells castable to others will darken instead"],
			order = 3,
			type = "toggle",
			get = GetForbearance,
			set = SetForbearance,
		},
		list_OFFENSIVE = {
			name = L["Offensive"],
			order = 10,
			type = "group",
			args = {}
		},
		list_DEFENSIVE = {
			name = L["Defensive"],
			order = 20,
			type = "group",
			args = {}
		},
		list_UTIL = {
			name = L["Utility"],
			order = 30,
			type = "group",
			args = {}
		},
		list_TRINKET = {
			name = format("%s, %s...",L["Trinket"], L["Racial Traits"]),
			order = 50,
			type = "group",
			args = {
				lb0 = { name = "|CFF20FF20"..L["Healthstone and Demonic Gateway are added on cast"], order = 1, type = "description" }
			}
		},
	}
}
end

local itemsOrdered = {
	[-1] = "R",
	[0] = "I",
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 5,
	[6] = 6,
	[7] = 7,
	[8] = 8,
	[9] = "h",
}

local header = {
	name = "header",
	order = 0,
	type = "group", dialogControl = "InlineGroupList2-OmniCDC", inline = true,
	args = {
		li0 = {
			name = L["Spells"],
			desc = L["CTRL+click to edit spell."],
			order = 0, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 1, justifyH = "CENTER",
		},
		li1 = {
			name = L["Frame"],
			desc = format("%s\n%s", L["Override spell-type frame."], L["0: Raid Frame, 1: Interrupt Bar, 2-8: Extra Bar"]),
			order = 1, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.7, justifyH = "CENTER",
		},
		li2 = {
			name = L["Priority"],
			desc = L["Override spell-type priority."],
			order = 2, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.7, justifyH = "CENTER",
		},
		li3 = {
			name = L["Glow"],
			desc = format("%s.\n\n%s", L["Glow Border"], L["Glow condition can be changed from the Highlighting tab."]),
			order = 3, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.7,
		},
	}
}

function P:AddSpellTypeSpell(spells, tab, spellID, class, type, icon, name, itemID)
	local sId = tostring(spellID)

	local classFileName = LOCALIZED_CLASS_NAMES_MALE[class]
	local category = (type == "covenant" and "COVENANT") or class

	local t = spells.args[tab].args
	if tab ~= "list_TRINKET" then
		t[category] = t[category] or {
			icon = E.TEXTURES[category] or E.TEXTURES.CLASS .. category, iconCoords = E.BORDERLESS_TCOORDS,
			name = E.L_PRIORITY[strlower(category)] or classFileName,
			type = "group",
			args = {
				header = header,
			}
		}

		t[category].args[sId] = {
			name = name,
			order = type == "covenant" and E.BOOKTYPE_CATEGORY[class] or nil,
			type = "group", dialogControl = "InlineGroupList2-OmniCDC", inline = true,
			arg = classFileName and class,
			args = {
				spells = {
					image = icon, imageCoords = E.BORDERLESS_TCOORDS,
					name = name,
					desc = E.isClassic and C_Spell.GetSpellDescription(spellID) or nil,
					tooltipHyperlink = not E.isClassic and C_Spell.GetSpellLink(spellID) or nil,
					order = 1,
					type = "toggle", dialogControl = "InlineGroupList2CheckBox-OmniCDC",
					get = GetSpell,
					set = SetSpell,
					arg = spellID,
				},
				spellFrame = {
					name = "",
					order = 2,
					type = "range", dialogControl = "InlineGroupList2Slider-OmniCDC",
					min = 0, max = 8, step = 1,
					width = 0.7,
					get = GetFrame,
					set = SetFrame,
				},
				spellPriority = {
					name = "",
					order = 3,
					type = "range", dialogControl = "InlineGroupList2Slider-OmniCDC",
					min = 0, max = 100, step = 1,
					width = 0.7,
					get = GetPriority,
					set = SetPriority,
				},
				spellGlow = {
					name = "",
					order = 4,
					type = "toggle", dialogControl = "InlineGroupListCheckBox-OmniCDC",
					width = 0.7,
					get = GetGlow,
					set = SetGlow,
				},
			},
		}
	end

	if tab ~= "list_OFFENSIVE" then
		t.splitter = t.splitter or {
			disabled = true,
			name = "```",
			order = 199,
			type = "group",
			args = {}
		}

		t[type] = t[type] or {
			icon = icon, iconCoords = E.BORDERLESS_TCOORDS,
			name = E.L_PRIORITY[type],
			order = 300 - C.Party.arena.priority[type],
			type = "group",
			args = {
				header = header,
			}
		}

		t[type].args[sId] = {
			name = name,
			order = E.BOOKTYPE_CATEGORY[class] or nil,
			type = "group", dialogControl = "InlineGroupList2-OmniCDC", inline = true,
			arg = classFileName and class,
			args = {
				spells = {
					image = icon, imageCoords = E.BORDERLESS_TCOORDS,
					name = name,
					desc = E.isClassic and C_Spell.GetSpellDescription(spellID) or nil,
					tooltipHyperlink = not E.isClassic and C_Spell.GetSpellLink(spellID) or nil,
					order = 1,
					type = "toggle", dialogControl = "InlineGroupList2CheckBox-OmniCDC",
					get = GetSpell,
					set = SetSpell,
					arg = spellID,
				},
				spellFrame = {
					name = "",
					order = 2,
					type = "range", dialogControl = "InlineGroupList2Slider-OmniCDC",
					min = 0, max = 8, step = 1,
					width = 0.7,
					get = GetFrame,
					set = SetFrame,
				},
				spellPriority = {
					name = "",
					order = 3,
					type = "range", dialogControl = "InlineGroupList2Slider-OmniCDC",
					min = 0, max = 100, step = 1,
					width = 0.7,
					get = GetPriority,
					set = SetPriority,
				},
				spellGlow = {
					name = "",
					order = 4,
					type = "toggle", dialogControl = "InlineGroupListCheckBox-OmniCDC",
					width = 0.7,
					get = GetGlow,
					set = SetGlow,
				},
			}
		}
	end

	if class == "TRINKET" and itemID and itemID > 0 and t[type] then
		local item = Item:CreateFromItemID(itemID)
		if item then
			item:ContinueOnItemLoad(function()
				local itemName = item:GetItemName()
				if itemName then
					t[type].args[sId].args.spells.name = itemName

					if E.hash_spelldb[spellID] then
						E.hash_spelldb[spellID].name = itemName
					end
				end
			end)
		end
	end
	local spell = Spell:CreateFromSpellID(spellID)
	spell:ContinueOnSpellLoad(function()
		if E.isClassic then
			local tooltip = spell:GetSpellDescription()
			if t[category] then
				t[category].args[sId].args.spells.desc = tooltip
			end
			if t[type] then
				t[type].args[sId].args.spells.desc = tooltip
			end
		else
			local tooltip = C_Spell.GetSpellLink(spellID)
			if t[category] then
				t[category].args[sId].args.spells.tooltipHyperlink = tooltip
			end
			if t[type] then
				t[type].args[sId].args.spells.tooltipHyperlink = tooltip
			end
		end
	end)
end

local spellTabs = {
	["interrupt"] = "UTIL",
	["dispel"] = "UTIL",
	["aoeCC"] = "UTIL",
	["cc"] = "UTIL",
	["disarm"] = "UTIL",
	["counterCC"] = "UTIL",
	["other"] = "UTIL",
	["raidMovement"] = "UTIL",
	["freedom"] = "UTIL",
	["movement"] = "UTIL",
	["taunt"] = "UTIL",
	["custom1"] = "UTIL",
	["custom2"] = "UTIL",
	["offensive"] = "OFFENSIVE",
	["immunity"] = "DEFENSIVE",
	["externalDefensive"] = "DEFENSIVE",
	["raidDefensive"] = "DEFENSIVE",
	["defensive"] = "DEFENSIVE",
	["tankDefensive"] = "DEFENSIVE",
	["heal"] = "DEFENSIVE",
	["pvptrinket"] = "TRINKET",
	["racial"] = "TRINKET",
	["consumable"] = "TRINKET",
	["trinket"] = "TRINKET",
	["essence"] = "TRINKET",
	["covenant"] = "TRINKET",
}

function P:AddSpellPickerSpells(spells)
	for spellID, v in pairs(E.hash_spelldb) do
		local class, type, icon, name, itemID = v.class, v.type, v.icon, v.name, v.item
		local tab = spellTabs[type]
		if tab then
			self:AddSpellTypeSpell(spells, "list_" .. tab, spellID, class, type, icon, name, itemID)
		end
	end
end

function P:UpdateSpellsOption(spellID, oldClass, oldType, v, force)
	local spells = E.spellsOptionTbl

	if oldClass then
		local oldtab = spellTabs[oldType]
		oldClass = (oldType == "covenant" and "COVENANT") or oldClass
		local sId = tostring(spellID)
		local t = spells.args["list_" .. oldtab].args

		local found
		if t[oldClass] then
			t[oldClass].args[sId] = nil
			for k in pairs(t[oldClass].args) do
				if k ~= "header" then found = true break end
			end
			if not found then t[oldClass] = nil end
		end

		if t[oldType] then
			found = nil
			t[oldType].args[sId] = nil
			for k in pairs(t[oldType].args) do
				if k ~= "header" then found = true break end
			end
			if not found then t[oldType] = nil end
		end
	end

	if v then
		local tab = spellTabs[v.type]
		self:AddSpellTypeSpell(spells, "list_" .. tab, spellID, v.class, v.type, v.icon, v.name, v.item)
	end

	for moduleName in pairs(E.moduleOptions) do
		local module = E[moduleName]
		if module.AddSpellPicker then
			module:Refresh()
		end
	end
end

function P:AddSpellPicker()


	if not E.spellsOptionTbl or next(E.spellsOptionTbl) == nil then
		local spells = GetSpellsTbl()
		self:AddSpellPickerSpells(spells)
		self:RegisterSubcategory("spells", spells)
		E.spellsOptionTbl = spells
	end
end

E:RegisterModuleOptions("Party", P.options, "Party")
