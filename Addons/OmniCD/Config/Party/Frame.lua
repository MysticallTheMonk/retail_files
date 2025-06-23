local E, L, C = select(2, ...):unpack()
local P = E.Party

local frame = {
	name = L["Frame"],
	order = 50,
	type = "group",
	get = function(info) return E.profile.Party[ info[2] ].frame[ info[#info] ] end,
	set = function(info, value)
		local key, type = info[2], info[#info]
		E.profile.Party[key].frame[type] = value

		for id, v in pairs(E.profile.Party[key].spellFrame) do
			if E.hash_spelldb[id].type == type and v == value then
				E.profile.Party[key].spellFrame[id] = nil
			end
		end
		if P:IsCurrentZone(key) then
			P:UpdateEnabledSpells()
			P:UpdateAllBars()
		end
	end,
	args = {
		desc = {
			name = format("|TInterface\\FriendsFrame\\InformationIcon:14:14:0:0|t %s %s\n\n",
				L["Select the frame to use as default for each spell type."],
				L["You can override this setting on individual spells from the Spells tab."]),
			order = 0, type = "description",
		},
	},
}

for k, v in pairs(E.L_PRIORITY) do
	frame.args[k] = {
		name = v,
		desc = L["0: Raid Frame, 1: Interrupt Bar, 2-8: Extra Bar"],
		order = 300 - C.Party.arena.priority[k],
		type = "range",
		min = 0, max = 8, step = 1,
	}
end
frame.args.interrupt.disabled = true

P:RegisterSubcategory("frame", frame)
