local E, L, C = select(2, ...):unpack()
local P = E.Party

P.options = {
	disabled = function(info)
		return info[2] and not E:GetModuleEnabled("Party")
	end,
	name = FRIENDLY,
	order = 20,
	type = "group",
	get = function(info) return E.profile.Party[ info[#info] ] end,
	set = function(info, value) E.profile.Party[ info[#info] ] = value end,
	args = {},
}

local getEnabled = function(info) return E.profile.Party.visibility[ info[2] ] end
local setEnabled = function(info, value)
	local key = info[2]
	E.profile.Party.visibility[key] = value
	if P.isInTestMode and P.testZone == key then
		P:Test()
	end
	P:Refresh()
end
local getTestMode = function(info) return P.testZone == info[2] and P.isInTestMode end
local setTestMode = function(info, state) P:Test(state and info[2]) end
local disableZone = function(info) return info[3] and not E.profile.Party.visibility[ info[2] ] or not E:GetModuleEnabled("Party") end
local getZoneName = function(info) return E.L_ALL_ZONE[ info[2] ] end

local configZone = {
	disabled = disableZone,
	name = getZoneName,
	type = "group",
	childGroups = "tab",
	args = {
		enabled = {
			disabled = false,
			name = ENABLE,
			desc = L["Enable CD tracking in the current zone"],
			order = 1,
			type = "toggle",
			get = getEnabled,
			set = setEnabled,
		},
		test = {
			name = L["Test"],
			desc = L["Toggle raid-style party frame and player spell bar for testing"],
			order = 2,
			type = "toggle",
			get = getTestMode,
			set = setTestMode,
		},
	}
}

local noCfgZone = {
	disabled = disableZone,
	name = getZoneName,
	type = "group",
	childGroups = "tab",
	args = {
		enabled = {
			disabled = false,
			name = ENABLE,
			desc = L["Enable CD tracking in the current zone"],
			order = 1,
			type = "toggle",
			get = getEnabled,
			set = setEnabled,
		},
		test = {
			name = L["Test"],
			desc = L["Toggle raid-style party frame and player spell bar for testing"],
			order = 2,
			type = "toggle",
			get = getTestMode,
			set = setTestMode,
		},
		lb1 = {
			name = "\n", order = 3, type = "description",
		},
		zoneSetting = {
			name = L["Use Zone Settings From:"],
			desc = L["Select the zone setting to use for this zone."],
			order = 4,
			type = "select",
			values = E.L_CFG_ZONE,
			get = function(info) return E.profile.Party[info[2] == "none" and "noneZoneSetting" or "scenarioZoneSetting"] end,
			set = function(info, value) E.profile.Party[info[2] == "none" and "noneZoneSetting" or "scenarioZoneSetting"] = value
				P:Refresh()
			end,
		},
	}
}

for key in pairs(E.L_CFG_ZONE) do
	P.options.args[key] = configZone
end
P.options.args.none = noCfgZone
P.options.args.scenario = noCfgZone

P.getIcons = function(info) return E.profile.Party[ info[2] ].icons[ info[#info] ] end
P.setIcons = function(info, value) E.profile.Party[ info[2] ].icons[ info[#info] ] = value P:Refresh() end

function P:IsCurrentZone(key)
	return E.db == E.profile.Party[key]
end

function P:ResetOption(key, tab, subtab)
	if subtab then
		E.profile.Party[key][tab][subtab] = E:DeepCopy(C.Party[key][tab][subtab])
	elseif tab then
		E.profile.Party[key][tab] = E:DeepCopy(C.Party[key][tab])
	elseif key then
		E.profile.Party[key] = E:DeepCopy(C.Party[key])
	else
		E.profile.Party = E:DeepCopy(C.Party)
	end
end

function P:RegisterSubcategory(optionName, optionTable)
	configZone.args[optionName] = optionTable
end
