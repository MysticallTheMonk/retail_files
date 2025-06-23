local E, L = unpack(select(2, ...))

function E:AddAuraAlert()
	self.options.args["auraAlert"] = {
		name = L["Aura Alert"],
		type = "group",
		order = 700,
		get = function(info) return self.profile[info[#info]] end,
		set = function(info, value) self.profile[info[#info]] = value end,
		args = {
			warnFrostLockout = {
				disabled = function() return not _G.OmniCD end,
				name = L["Warn Frost Lockout in OmniCD"],
				desc = L["Show a red pulsing overlay over Ice Block if the Mage is locked in frost and Ice Block is off CD"],
				order = 1,
				type = "toggle",
				width = "double",
			},
		}
	}
end
