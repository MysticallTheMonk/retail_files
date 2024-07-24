
EasyScrap_SaveData = {
	["addonSettings"] = {
		["canScrapTooltip"] = false,
		["defaultFilter"] = 1,
	},
	["addonVersion"] = 31,
	["customFilters"] = {
		{
			["name"] = "Tailoring",
			["rules"] = {
				{
					["filterType"] = "equipmentSet",
				}, -- [1]
				{
					["data"] = {
						false, -- [1]
						true, -- [2]
						false, -- [3]
						false, -- [4]
					},
					["filterType"] = "itemQuality",
				}, -- [2]
			},
		}, -- [1]
	},
}
