local E, L = select(2, ...):unpack()
local P = E.Party

local L_POINTS = {
	["LEFT"] = L["LEFT"],
	["RIGHT"] = L["RIGHT"],
	["TOPLEFT"] = L["TOPLEFT"],
	["TOPRIGHT"] = L["TOPRIGHT"],
	["BOTTOMLEFT"] = L["BOTTOMLEFT"],
	["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
}

local isPreset = function(info)
	return E.profile.Party[ info[2] ].position.preset ~= "manual"
end

local disabledItems = {}
local function GetDisabledItems(info)
	wipe(disabledItems)
	local db = E.profile.Party[ info[2] ]
	local bp = db.priority[db.position.breakPoint]
	for k in pairs(E.L_PRIORITY) do
		local prio = db.priority[k]
		if prio >= bp then
			disabledItems[k] = true
		end
	end
	return disabledItems
end

local isBySpellPrio = function(info) return E.profile.Party[ info[2] ].position.sortBy == 1 end
local isBySpellTypePrio = function(info) return E.profile.Party[ info[2] ].position.sortBy == 2 end

local isSingleLine = function(info)
	local layout = E.profile.Party[ info[2] ].position.layout
	return layout == "vertical" or layout == "horizontal"
end
local isSingleOrDoubleLine = function(info)
	local layout = E.profile.Party[ info[2] ].position.layout
	return layout ~= "tripleRow" and layout ~= "tripleColumn"
end

local position = {
	name = L["Position"],
	type = "group",
	order = 20,
	get = function(info) return E.profile.Party[ info[2] ].position[ info[#info] ] end,
	set = function(info, value)
		local key = info[2]
		local option = info[#info]
		local db = E.profile.Party[key].position
		db[option] = value

		if option == "preset" then
			if value == "TOPLEFT" then
				db.anchor = "TOPRIGHT"
				db.attach = value
			elseif value == "TOPRIGHT" then
				db.anchor = "TOPLEFT"
				db.attach = value
			else
				db.anchor = db.anchorMore or "LEFT"
				db.attach = db.attachMore or "LEFT"
			end
		elseif option == "anchor" or option == "attach" then
			if db.preset == "manual" then
				db[option .. "More"] = value
			end
		end
		if P:IsCurrentZone(key) then
			P:Refresh()
		end
	end,
	args = {
		positionSettings = {
			disabled = function(info) return E.profile.Party[ info[2] ].position.detached end,
			name = L["Position"],
			type = "group",
			inline = true,
			order = 2,
			args = {
				uf = {
					name = ADDONS,
					desc = L["Select addon to override auto anchoring"],
					order = 1,
					type = "select",
					values = function() return E.customUF.optionTable end,
					set = function(info, value)
						local key = info[2]
						local db = E.profile.Party[key].position
						if P:IsCurrentZone(key) then
							if not db.detached
								and (not E.customUF.enabledList or value == "blizz")
								and not E:IsBlizzardCUFLoaded() then
								E.Libs.OmniCDC.StaticPopup_Show("OMNICD_RELOADUI", E.STR.ENABLE_BLIZZARD_CRF)
							else
								if P.isInTestMode then
									P:Test()
									db.uf = value
									P:Test(key)
								else
									db.uf = value
									P:Refresh()
								end
							end
						else
							db.uf = value
						end
					end,
				},
				preset = {
					name = L["Position"],
					desc = L["Set the spell bar position"],
					order = 2,
					type = "select",
					values = {
						["TOPLEFT"] = L["LEFT"],
						["TOPRIGHT"] = L["RIGHT"],
						["manual"] = L["More..."],
					},
				},
				anchor = {
					disabled = isPreset,
					name = L["Anchor Point"],
					desc = format("%s\n\n%s", L["Set the anchor point on the spell bar"],
						L["Having \"RIGHT\" in the anchor point, icons grow left, otherwise right"]),
					order = 3,
					type = "select",
					values = L_POINTS,
				},
				attach = {
					disabled = isPreset,
					name = L["Attachment Point"],
					desc = L["Set the anchor attachment point on the party/raid frame"],
					order = 4,
					type = "select",
					values = L_POINTS,
				},
				lb1 = {
					name = "", order = 5, type = "description",
				},
				offsetX = {
					name = L["Offset X"],
					desc = E.STR.MAX_RANGE,
					order = 6,
					type = "range",
					min = -999, max = 999, softMin = -100, softMax = 100, step = 1,
				},
				offsetY = {
					name = L["Offset Y"],
					desc = E.STR.MAX_RANGE,
					order = 7,
					type = "range",
					min = -999, max = 999, softMin = -100, softMax = 100, step = 1,
				},
			}
		},
		layoutSettings = {
			name = L["Layout"],
			type = "group",
			inline = true,
			order = 3,
			args = {
				layout = {
					name = L["Layout"],
					desc = L["Select the icon layout"],
					order = 11,
					type = "select",
					values = {
						["horizontal"] = L["Horizontal"],
						["vertical"] = L["Vertical"],
						["doubleRow"] = L["Use Double Row"],
						["doubleColumn"] = L["Use Double Column"],
						["tripleRow"] = L["Use Triple Row"],
						["tripleColumn"] = L["Use Triple Column"],
					},
					sorting = {"horizontal", "doubleRow", "tripleRow", "vertical", "doubleColumn", "tripleColumn"},
				},
				sortBy = {
					name = COMPACT_UNIT_FRAME_PROFILE_SORTBY,
					desc = format("%s.\n%s > %s.", L["Spell Priority"], L["Spell-Type Priority"], L["Spell Priority"]),
					order = 12,
					type = "select",
					values = {
						L["Spell Priority"],
						format("%s > %s", L["Spell-Type Priority"], L["Spell Priority"]),
					},
				},
				breakPoint = {
					hidden = isBySpellPrio,
					disabled = isSingleLine,
					name = L["Breakpoint"],
					desc = L["Select the highest priority spell type to use as the start of the 2nd row"],
					order = 13,
					type = "select",
					values = E.L_PRIORITY,
					sorting = function(info)
						return E.SortHashToArray(E.L_PRIORITY, E.profile.Party[ info[2] ].priority)
					end,
				},
				breakPoint2 = {
					hidden = isBySpellPrio,
					disabled = isSingleOrDoubleLine,
					name = L["Breakpoint"] .. " 2",
					desc = L["Select the highest priority spell type to use as the start of the 3rd row"],
					order = 14,
					type = "select",
					values = E.L_PRIORITY,
					sorting = function(info)
						return E.SortHashToArray(E.L_PRIORITY, E.profile.Party[ info[2] ].priority)
					end,
					disabledItem = function(info)
						return GetDisabledItems(info)
					end,
				},
				breakPoint3 = {
					hidden = isBySpellTypePrio,
					disabled = isSingleLine,
					name = L["Breakpoint"],
					desc = L["Select the highest spell priority to use as the start of the 2nd row"],
					order = 13,
					type = "range", min = 0, max = 100, step = 1,
				},
				breakPoint4 = {
					hidden = isBySpellTypePrio,
					disabled = isSingleOrDoubleLine,
					name = L["Breakpoint"] .. " 2",
					desc = L["Select the highest spell priority to use as the start of the 3rd row"],
					order = 14,
					type = "range", min = 0, max = 100, step = 1,
					confirm = function(info, value)
						return value >= E.profile.Party[ info[2] ].position.breakPoint3
							and L["Select a value lower than Breakpoint1"]
					end,
				},
				lb1 = {
					name = "", order = 15, type = "description",
				},
				columns = {
					disabled = function(info)
						local layout = E.profile.Party[ info[2] ].position.layout
						return layout ~= "vertical" and layout ~= "horizontal"
					end,
					name = function(info)
						return E.profile.Party[ info[2] ].position.layout == "vertical" and L["Row"] or L["Column"]
					end,
					desc = function(info)
						return E.profile.Party[ info[2] ].position.layout == "vertical"
							and L["Set the number of icons per column"] or L["Set the number of icons per row"]
					end,
					order = 16,
					type = "range",
					min = 1, max = 100, softMax = 20, step = 1,
				},
				paddingX = {
					name = L["Padding X"],
					desc = L["Set the padding space between icon columns"],
					order = 17,
					type = "range",
					min = -5, max = 100, softMin = 0, softMax = 10, step = 1,
				},
				paddingY = {
					name = L["Padding Y"],
					desc = L["Set the padding space between icon rows"],
					order = 18,
					type = "range",
					min = -5, max = 100, softMin = 0, softMax = 10, step = 1,
				},
				maxNumIcons = {
					name = L["Max Number of Visible Icons"],
					desc = format("%s\n\n%s\n\n|cffff2020%s",
						L["Set the max number of icons that can be displayed per unit"],
						L["For double/triple layout, it will limit the number of icons per line"],
						L["0: Disable option"]),
					order = 19,
					type = "range",
					min = 0, max = 100, softMax = 20, step = 1,
				},
				displayInactive = {
					name = L["Display Inactive Icons"],
					desc = L["Display icons not on cooldown"],
					order = 21,
					type = "toggle",
				},
				growUpward = {
					name = L["Grow Rows Upward"],
					desc = L["Toggle the grow direction of icon rows"],
					order = 22,
					type = "toggle",
				},
			}
		},
		manualModeSettings = {
			disabled = function(info)
				return info[5] and not E.profile.Party[ info[2] ].position.detached
			end,
			name = L["Manual Mode"],
			order = 4,
			type = "group",
			inline = true,
			args = {
				detached = {
					disabled = false,
					name = ENABLE,
					desc = L["Detach from raid frames and set position manually"],
					order = 1,
					type = "toggle",
					set = function(info, state)
						local key = info[2]
						E.profile.Party[key].position.detached = state

						if P:IsCurrentZone(key) then
							if not state
								and (not E.customUF.enabledList or E.profile.Party[key].position.uf == "blizz")
								and not E:IsBlizzardCUFLoaded() then
								E.Libs.OmniCDC.StaticPopup_Show("OMNICD_RELOADUI", E.STR.ENABLE_BLIZZARD_CRF)
							end
							P:Refresh()
						end

						if E.postDF and P.isInTestMode then
							local testZone = P.testZone
							P:Test()
							P:Test(testZone)
						end
					end,
				},
				locked = {
					name = LOCK_FRAME,
					desc = L["Lock frame position"],
					order = 2,
					type = "toggle",
				},
				reset = {
					name = RESET_POSITION,
					desc = L["Reset frame position"],
					order = 5,
					type = "execute",
					func = function(info)
						local key = info[2]
						for k in pairs(E.profile.Party[key].manualPos) do
							if type(k) == "number" then
								E.profile.Party[key].manualPos[k] = nil
							end
						end
						P:Refresh()
					end,
					confirm = E.ConfirmAction,
				},
			}
		},
	}
}

P:RegisterSubcategory("position", position)
