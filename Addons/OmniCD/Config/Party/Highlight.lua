local E, L = select(2, ...):unpack()
local P = E.Party

E.spell_marked = E.isRetail and {
	[48707] = 205727,
	[198589] = 205411,
	[217832] = 205596,
	[198793] = 354489,
	[187650] = 203340,
	[205625] = 205625,
	[371032] = 371032,
	[116849] = 388218,
	[122470] = 280195,
	[853] = 234299,
	[228049] = true,
	[199448] = true,
	[88625] = 200199,
	[586] = 408557,
	[8122] = 196704,
	[34433] = 314867,
	[123040] = 314867,
	[2094] = 200733,
	[1966] = 79008,
	[1218128] = 1218692,
} or E.BLANK

local markEnhancedDesc = {}
for k, v in pairs(E.spell_marked) do
	if not C_Spell.DoesSpellExist(k) or (v ~= true and not C_Spell.DoesSpellExist(v)) then
		E.spell_marked[k] = nil
		--[==[@debug@
		E.write("Removing invalid spell_marked ID:" , k)
		--@end-debug@]==]
	else
		local id = v == true and k or v
		local spellInfo = C_Spell.GetSpellInfo(id)
		if spellInfo then
			markEnhancedDesc[#markEnhancedDesc + 1] = format("|T%s:18|t %s", spellInfo.originalIconID, spellInfo.name)
		end
	end
end
markEnhancedDesc = table.concat(markEnhancedDesc, "\n")

local highlight = {
	name = L["Highlighting"],
	order = 35,
	type = "group",
	get = function(info) return E.profile.Party[ info[2] ].highlight[ info[#info] ] end,
	set = function(info, value)
		local key = info[2]
		E.profile.Party[key].highlight[ info[#info] ] = value
		if P:IsCurrentZone(key) then
			P:Refresh()
		end
	end,
	args = {
		glow = {
			name = L["Glow Icons"],
			order = 10,
			type = "group",
			inline = true,
			args = {
				glow = {
					name = ENABLE,
					desc = L["Display a glow animation around an icon when it is activated"],
					order = 1,
					type = "toggle",
				},
			}
		},
		highlight = {
			disabled = function(info) return info[5] and not E.profile.Party[ info[2] ].highlight.glowBuffs end,
			name = L["Highlight Icons"],
			order = 20,
			type = "group",
			inline = true,
			args = {
				glowBuffs = {
					disabled = false,
					name = ENABLE,
					desc = L["Highlight the icon when a buffing spell is used until the buff falls off"],
					order = 1,
					type = "toggle",
				},
				glowType = {
					name = TYPE,
					order = 2,
					type = "select",
					values = {
						actionBar = L["Strong Yellow Glow"],
						wardrobe = L["Weak Purple Glow"],
					}
				},
				buffTypes = {
					name = L["Spell Types"],
					order = 3,
					type = "multiselect",
					values = E.L_HIGHLIGHTS,
					get = function(info, k) return E.profile.Party[ info[2] ].highlight.glowBuffTypes[k] end,
					set = function(info, k, value)
						local key = info[2]
						E.profile.Party[key].highlight.glowBuffTypes[k] = value
						if P:IsCurrentZone(key) then
							P:Refresh()
						end
					end,
				},
			}
		},
		glowBorder = {
			disabled = function(info) return not E.profile.Party[ info[2] ].highlight.glowBorder end,
			name = L["Glow Border"],
			order = 30,
			type = "group",
			inline = true,
			args = {
				glowBorder = {
					disabled = false,
					name = ENABLE,
					desc = format("%s.\n\n|cffff2020%s", L["Glow Border"],
						L["Only applies to spells that have Glow enabled in the Spells tab"]),
					order = 1,
					type = "toggle",
				},
				glowBorderCondition = {
					name = L["Condition"],
					order = 2,
					type = "select",
					values = {
						[1] = L["Usable"],
						[2] = L["Unusable"],
						[3] = L["Both"],
					},
				},
			}
		},
		markEnhanced = {
			disabled = function(info) return not E.profile.Party[ info[2] ].icons.markEnhanced end,
			name = L["Mark Enhanced Spells"],
			order = 40,
			type = "group",
			inline = true,
			args = {
				markEnhanced = {
					disabled = false,
					name = ENABLE,
					desc = L["Mark icons with a red dot to indicate enhanced spells"] .. "\n\n" .. markEnhancedDesc,
					order = 1,
					type = "toggle",
					get = P.getIcons,
					set = P.setIcons,
				},
			}
		},
	}
}

P:RegisterSubcategory("highlight", highlight)
