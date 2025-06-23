local E, L, C = select(2, ...):unpack()
local P = E.Party

local priority = {
	name = L["Priority"],
	order = 60,
	type = "group",
	get = function(info) return E.profile.Party[ info[2] ].priority[ info[#info] ] end,
	set = function(info, value)
		local key, type = info[2], info[#info]
		E.profile.Party[key].priority[type] = value

		for id, v in pairs(E.profile.Party[key].spellPriority) do
			if E.hash_spelldb[id].type == type and v == value then
				E.profile.Party[key].spellPriority[id] = nil
			end
		end
		if P:IsCurrentZone(key) then
			P:UpdateAllBars()
		end
	end,
	args = {
		desc = {
			name = format("|TInterface\\FriendsFrame\\InformationIcon:14:14:0:0|t %s %s\n\n",
				L["Set the priority of spell types for sorting."],
				L["You can override this setting on individual spells from the Spells tab."]),
			order = 0, type = "description",
		},
	},
}

for k, v in pairs(E.L_PRIORITY) do
	priority.args[k] = {
		name = v,
		order = 300 - C.Party.arena.priority[k],
		type = "range",
		min = 0, max = 100, step = 1,
	}
end

P:RegisterSubcategory("priority", priority)
