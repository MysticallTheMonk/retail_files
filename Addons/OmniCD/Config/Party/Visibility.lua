local E, L = select(2, ...):unpack()
local P = E.Party

local sliderTimer

local visibility = {
	name = L["Visibility"],
	order = 0,
	type = "group",
	get = function(info) return E.profile.Party.visibility[ info[#info] ] end,
	set = function(info, value) E.profile.Party.visibility[ info[#info] ] = value P:Refresh() end,
	args = {
		zone = {
			name = ZONE,
			order = 10,
			type = "multiselect",
			values = E.L_ALL_ZONE,
			get = function(_, k) return E.profile.Party.visibility[k] end,
			set = function(_, k, value)
				E.profile.Party.visibility[k] = value
				if P.isInTestMode and P.testZone == k then
					P:Test()
				end
				P:Refresh()
			end,
		},
		groupType = {
			name = DUNGEONS_BUTTON,
			order = 20,
			type = "group",
			inline = true,
			args = {
				finder = {
					name = ENABLE,
					desc = format("%s (%s, %s, ...)", L["Enable in automated instance groups"],
						LOOKING_FOR_DUNGEON_PVEFRAME, SKIRMISH),
					type = "toggle",
				},
			}
		},
		groupSize = {
			name = L["Group Size"],
			order = 30,
			type = "group",
			inline = true,
			get = function(info) return E.profile.Party.groupSize[ info[#info] ] end,
			set = function(info, value)
				E.profile.Party.groupSize[ info[#info] ] = value
				if not sliderTimer then
					sliderTimer = C_Timer.NewTimer(1, function()
						P:Refresh()
						sliderTimer = nil
					end)
				end
			end,
			args = {}
		},
	}
}

for zone, localizedName in pairs(E.L_ALL_ZONE) do
	visibility.args.groupSize.args[zone] = {
		name = localizedName,
		desc = L["Max number of group members"],
		type = "range", min = 2, max = zone == "arena" and 5 or (zone == "party" and 10) or 40, step = 1,
	}
end

P.options.args["visibility"] = visibility
