local E, L, C = unpack(select(2, ...))

local tooltipFix = {
	[362486] = 353114,
	[8178] = 204336,
	[248519] = 248518,
	[255723] = 255654,
	[411038] = 411038,
}

local auras = {
	name = L["Auras"],
	order = 400,
	type = "group", childGroups = "tab",
	args = {
		uncheckAll = {
			name = L["Uncheck All"],
			order = 1,
			type = "execute",
			func = function()
				for sId, t in pairs(C.auras) do
					E.profile.auras[sId] = E.profile.auras[sId] or {}
					for k in pairs(t) do
						E.profile.auras[sId][k] = false
					end
				end
				E:Refresh()
			end,
			confirm = E.ConfirmAction,
		},
		reset = {
			name = RESET_TO_DEFAULT,
			order = 2,
			type = "execute",
			func = function()
				E.profile.auras = {}
				local currentProfile = E.DB:GetCurrentProfile()
				E.DB.keys.profile = currentProfile .. ":D" -- Bypass same profile check and force update
				E.DB:SetProfile(currentProfile)
			end,
			confirm = E.ConfirmAction,
		},
		list_INTERRUPT = { -- list_ triggers Flow-Nopadding-OmniCDC layout
			name = L["Interrupts"],
			order = 10,
			type = "group",
			args = {}
		},
		list_HARMFUL = {
			name = L["Debuffs"],
			order = 20,
			type = "group",
			args = {}
		},
		list_HELPFUL = {
			name = L["Buffs"],
			order = 30,
			type = "group",
			args = {}
		},
		list_PVE = {
			name = L["NPC Auras"],
			order = 40,
			type = "group",
			args = {}
		},
		auraFiltered = {
			name = L["Filters"],
			order = 50,
			type = "group",
			args = {
				noFriend = {
					name = L["Hide Friendly Source"],
					order = 1,
					type = "group", inline = true,
					get = function(info) return E.profile.auraFiltered.noFriend[info[#info]] end,
					set = function(info, state) E.profile.auraFiltered.noFriend[ info[#info] ] = state E:Refresh() end,
					args = {
						["212183"] = {
							image = C_Spell.GetSpellTexture(212183), imageCoords = E.BORDERLESS_TCOORDS,
							name = C_Spell.GetSpellName(212183),
							tooltipHyperlink = C_Spell.GetSpellLink(212183),
							type = "toggle",
						},
					},
				}
			}
		},
	},
}

--
-- Spell picker
--
local auraItemsOrdered = {
	[1] = "R",
	[2] = "|cffff2020N|r",
	[3] = "|cff20ff20N|r",
	[4] = "U",
	[5] = "A",
	[6] = "P",
	[7] = "l",
	[8] = "g",
	--[9] = "a",
	[9] = "Np"
}

local itemIndexToKey = { -- treat as hash table
	[1] = "raidFrame",
	[2] = "nameplate",
	[3] = "friendlyNameplate",
	[4] = "unitFrame",
	[5] = "arenaFrame",
	[6] = "playerFrame",	-- player unitFrame and player nameplate
	[7] = "largerIcon",
	[8] = "glow",
	--[9] = "alert",
	[9] = "byPlayer"
}

local header = {
	name = "header",
	order = 0,
	type = "group", dialogControl = "InlineGroupList2-OmniCDC", inline = true,
	args = {
		li0 = { name = "", order = 0, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 1, },
		li1 = { name = "R", desc = L["Raid Frame"], order = 1, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
		li2 = { name = "|cffff2020N|r", desc = L["Enemy Nameplate"], order = 2, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
		li3 = { name = "|cff20ff20N|r", desc = L["Friendly Nameplate"], order = 3, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
		li4 = { name = "U", desc = L["Unit Frame"], order = 4, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
		li5 = { name = "A", desc = L["Arena Unit Frame"], order = 5, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
		li6 = { name = "P", desc = L["Player Unit Frame & Nameplate"], order = 6, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
		li7 = { name = "l", desc = L["Larger Icon"], order = 7, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
		li8 = { name = "g", desc = L["Glow icon"], order = 8, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
		--li9 = { name = "a", desc = L["Aura Alert"], order = 9, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
		li9 = { name = "|cffff2020Np|r", desc = L["Only show player applied debuff on enemy nameplates"], order = 9, type = "description", dialogControl = "InlineGroupList2Label-OmniCDC", width = 0.25, justifyH = "LEFT", },
	}
}

function E:AddAuraTypeSpell(spellID, sId, tab, auraClassPriority, auraType, classID)
	local _, icon = C_Spell.GetSpellTexture(spellID)
	local name = C_Spell.GetSpellName(spellID)
	local classFileName = CLASS_SORT_ORDER[classID]
	local order = self.auraTypeOrder[auraType]
	local tooltipID = tooltipFix[spellID] or spellID

	auras.args[tab].args[auraType] = auras.args[tab].args[auraType] or {
		icon = icon, iconCoords = E.BORDERLESS_TCOORDS,
		name = L[auraType],
		order = order,
		type = "group", childGroups = "tab",
		args = {
			header = header,
		}
	}

	auras.args[tab].args[auraType].args[sId] = {
		disabled = function() return E.global.auraBlacklist[spellID] and not E.aura_db.INTERRUPT[spellID] end,
		image = icon, imageCoords = E.BORDERLESS_TCOORDS,
		name = name,
		tooltipHyperlink = C_Spell.GetSpellLink(tooltipID),
		descStyle = "", -- empty string will effective disables the default tooltip. We're adding tooltips from the widget title fx for InlineGroupList.
		order = classID,
		type = "multiselect", dialogControl = "InlineGroupList-OmniCDC",
		values = auraItemsOrdered,
		width = 0.25,
		get = function(_, k)
			k = itemIndexToKey[k]
			return self.profile.auras[sId] and self.profile.auras[sId][k]
		end,
		set = function(_, k, state)
			k = itemIndexToKey[k]
			self.profile.auras[sId] = self.profile.auras[sId] or {}
			self.profile.auras[sId][k] = state -- keep boolean
			self:Refresh()
		end,
		arg = classFileName,
		-- TODO: alert
		--disabledItem = C.raidFrame.HARMFUL.typeScale[auraClassPriority] and { [7]=true, [9]=true } or 9,
		disabledItem = C.raidFrame.HARMFUL.typeScale[auraClassPriority] and { [7]=true, [9]=true } or (auraClassPriority ~= "debuff" and 9),
	}

	local spell = Spell:CreateFromSpellID(tooltipID)
	spell:ContinueOnSpellLoad(function()
		auras.args[tab].args[auraType].args[sId].tooltipHyperlink = C_Spell.GetSpellLink(tooltipID)
	end)
end

function E:AddSpellPickerSpells()
	for tab, v in pairs(self.aura_db) do
		tab = "list_" .. tab
		for spellID, spell in pairs(v) do
			local auraClassPriority, auraType, classID = spell[1], spell[2], spell[3]
			local sId = tostring(spellID)
			self:AddAuraTypeSpell(spellID, sId, tab, auraClassPriority, auraType, classID)
		end
	end
end

function E:UpdateSpellsOption(spellID, oldFilter, oldType, auraFilter, auraClassPriority, auraType, classID, isNewCustom)
	if oldFilter or isNewCustom then
		local sId = tostring(spellID)
		if oldFilter then
			auras.args["list_" .. oldFilter].args[oldType].args[sId] = nil
		end

		if auraFilter then
			local tab = "list_" .. auraFilter
			self:AddAuraTypeSpell(spellID, sId, tab, auraClassPriority, auraType, classID)
		end
	end
	self:Refresh()
end

function E:AddSpellPicker()
	self:AddSpellPickerSpells()
	self.options.args.auras = auras
end
