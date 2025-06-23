local E, L = unpack(select(2, ...))

local PS = E.ProfileSharing
local title = L["Profile Sharing"]

local selectedProfileType

PS.profileTypeValues = {
	["all"] = L["All"],
	["cds"] = L["Aura Editor"],
	["blacklist"] = L["Aura Blacklist"],
}

local ProfileSharing = {
	name = title,
	order = -1,
	type = "group",
	args = {
		desc = {
			name = "",
			order = 1,
			type = "description",
		},
		export = {
			name = L["Export Profile"],
			order = 100,
			type = "group",
			inline = true,
			args = {
				lb1 = {
					name = L["Exports your currently active profile."], order = 0, type = "description",
				},
				profileType = {
					name = L["Profile Type"],
					order = 1,
					type = "select",
					values = PS.profileTypeValues,
					get = function() return selectedProfileType end,
					set = function(_, value) selectedProfileType = value end,
				},
				openExportDialog = {
					disabled = function() return not selectedProfileType end,
					name = L["Export"],
					order = 2,
					type = "execute",
					func = function()
						local _, encodedData = PS:ExportProfile(selectedProfileType)
						PS:ShowProfileDialog(encodedData or PS.errorMsg)
					end,
				},
			}
		},
		import = {
			name = L["Import Profile"],
			order = 200,
			type = "group",
			inline = true,
			args = {
				lb1 = {
					name = format(L["Importing `%s` will create a new profile."], PS.profileTypeValues.all), order = 0, type = "description",
				},
				lb2 = {
					name = format(L["Importing `%s` will merge new spells to your list and overwrite same spells."], PS.profileTypeValues.cds), order = 1, type = "description",
				},
				lb3 = {
					name = format(L["Importing `%s` will merge new spells to your list and overwrite same spells."], PS.profileTypeValues.blacklist), order = 2, type = "description",
				},
				openImportDialog = {
					name = L["Import"],
					order = 3,
					type = "execute",
					func = function() PS:ShowProfileDialog(nil) end,
				},
			}
		},
		lb1 = {
			name = "\n\n", order = 201, type = "description",
		},
	}
}

function E:AddProfileSharing()
	self.options.args["ProfileSharing"] = ProfileSharing
end
