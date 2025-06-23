local E, L, C = select(2, ...):unpack()
local P = E.Party

local extraBars = {
	name = E.STR.WHATS_NEW_ESCSEQ .. L["Extra Bars"],
	type = "group",
	childGroups = "tab",
	order = 80,
	get = function(info) return E.profile.Party[ info[2] ].extraBars[ info[4] ][ info[#info] ] end,
	set = function(info, value)
		local key, bar, option = info[2], info[4], info[#info]
		E.profile.Party[key].extraBars[bar][option] = value
		if P:IsCurrentZone(key) then
			P:Refresh()
		end
	end,
	args = {}
}

local L_POINTS = {
	["TOPLEFT"] = L["TOPLEFT"],
	["TOPRIGHT"] = L["TOPRIGHT"],
	["BOTTOMLEFT"] = L["BOTTOMLEFT"],
	["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
}

local getColor = function(info)
	local ele, option, c = info[#info-1], info[#info]
	if ele == "bgColors" and option == "inactiveColor" then
		c = E.profile.Party[ info[2] ].extraBars[ info[4] ].barColors.inactiveColor
	else
		c = E.profile.Party[ info[2] ].extraBars[ info[4] ][ele][option]
	end
	return c.r, c.g, c.b, c.a
end

local setColor = function(info, r, g, b, a)
	local key, bar, ele, option = info[2], info[4], info[#info-1], info[#info]
	local c = E.profile.Party[key].extraBars[bar][ele][option]
	c.r, c.g, c.b, c.a = r, g, b, a
	if P:IsCurrentZone(key) then
		P:Refresh()
	end
end

local isRaidCDBar = function(info)
	return info[4] ~= "raidBar1"
end

local notInterruptBar = function(info)
	return E.preCata or info[4] ~= "raidBar1"
end

local isEnabled = function(info)
	return E.profile.Party[ info[2] ].extraBars[ info[4] ].enabled
end

local isDisabled = function(info)
	return not E.profile.Party[ info[2] ].extraBars[ info[4] ].enabled
end

local isUnitBar = function(info)
	local db = E.profile.Party[ info[2] ].extraBars[ info[4] ]
	return not db.enabled or db.unitBar
end

local notUnitBar = function(info)
	local db = E.profile.Party[ info[2] ].extraBars[ info[4] ]
	return not db.enabled or not db.unitBar
end

local isDisabledProgressBarOrNameBar = function(info)
	local db = E.profile.Party[ info[2] ].extraBars[ info[4] ]
	return not db.enabled or not db.progressBar or db.layout == "horizontal" or db.nameBar
end

local isEnabledProgressBar = function(info)
	local db = E.profile.Party[ info[2] ].extraBars[ info[4] ]
	return not db.enabled or (db.layout == "vertical" and db.progressBar)
end

local notTextColor = function(info)
	return info[#info-1] ~= "textColors"
end

local isIconNameHidden = function(info)
	return not E.profile.Party[ info[2] ].extraBars[ info[4] ].showName or isEnabledProgressBar(info)
end

local sortByValues = {
	raidBar1 = {
		[1] = L["Cooldown"],
		[5] = ROLE,
		[6] = CLASS,
		[15] = L["Priority"],
		[2] = format("%s>%s", L["Cooldown Remaining"], L["Cooldown"]),
		[7] = format("%s>%s", L["Cooldown Remaining"], ROLE),
		[8] = format("%s>%s", L["Cooldown Remaining"], CLASS),
		[16] = format("%s>%s", L["Cooldown Remaining"], L["Priority"]),
		--[11] = GROUP,
		--[12] = NAME,
		--[13] = format("%s>%s", L["Cooldown Remaining"], GROUP),
		--[14] = format("%s>%s", L["Cooldown Remaining"], NAME),
	},
	raidBar2 = {
		[3] = L["Priority"],
		[4] = CLASS,
		[9] = format("%s>%s", L["Cooldown Remaining"], L["Priority"]),
		[10] = format("%s>%s", L["Cooldown Remaining"], CLASS),
	},
}

local progressBarColorInfo = {
	lb1 = {
		name = function(info)
			local opt = info[#info-1]
			return opt == "textColors" and NAME or (opt == "barColors" and L["Bar"]) or (opt == "bgColors" and L["BG"])
		end,
		order = 0,
		type = "description",
		width = 0.5
	},
	activeColor = {
		name = "",
		order = 1,
		type = "color",
		dialogControl = "ColorPicker-OmniCDC",
		hasAlpha = notTextColor,
		width = 0.5,

	},
	rechargeColor = {
		name = "",
		order = 2,
		type = "color",
		dialogControl = "ColorPicker-OmniCDC",
		hasAlpha = notTextColor,
		width = 0.5,
	},
	inactiveColor = {
		disabled = function(info)
			local db = E.profile.Party[ info[2] ].extraBars[ info[4] ]
			return not db.enabled or not db.progressBar or db.layout == "horizontal"
				or info[#info-1] == "bgColors" or (info[#info-1] == "barColors" and db.nameBar)
		end,
		name = "",
		order = 3,
		type = "color",
		dialogControl = "ColorPicker-OmniCDC",
		hasAlpha = notTextColor,
		width = 0.5,
	},
	useClassColor = {
		name = "",
		order = 4,
		type = "multiselect",
		dialogControl = "Dropdown-OmniCDC",
		values = {
			active = L["Active"],
			inactive = L["Inactive"],
			recharge = L["Recharge"],
		},
		get = function(info, k) return E.profile.Party[ info[2] ].extraBars[ info[4] ][ info[#info-1] ].useClassColor[k] end,
		set = function(info, k, value)
			local key, bar = info[2], info[4]
			E.profile.Party[key].extraBars[bar][ info[#info-1] ].useClassColor[k] = value
			if P:IsCurrentZone(key) then
				P:Refresh()
			end
		end,
		disabledItem = function(info)
			return info[#info-1] == "bgColors" and "inactive"
		end,
	},
}

local extraBarsInfo = {
	disabled = function(info)
		return info[5] and not E.profile.Party[ info[2] ].extraBars[ info[4] ].enabled
	end,
	name = function(info)
		local bar = info[4]
		return E.profile.Party[ info[2] ].extraBars[bar].name or bar == "raidBar1" and L["Interrupts"] or strsub(info[4], 8)
	end,
	order = function(info) return tonumber(strsub(info[4], 8)) end,
	type = "group",
	args = {
		enabled = {
			disabled = false,
			name = ENABLE,
			--[[
			desc = function(info)
				return info[4] == "raidBar1" and format("%s\n\n|cffffd200%s",
				L["Move your group's Interrupt spells to the Interrupt Bar."],
				L["Interrupt spell types are automatically added to this bar."])
				or format("%s\n\n|cffffd200%s",
				L["Move your group's Raid Cooldowns to the Raid Bar."],
				L["Select the spells you want to move from the \'Raid CD\' tab. The spell must be enabled from the \'Spells\' tab first."])
			end,
			]]
			order = 1,
			type = "toggle",
		},
		redirect = {
			hidden = isEnabled,
			disabled = false,
			name = L["Redirect Spells"],
			desc = L["Redirect spells to the raid frame instead of removing them when this bar is disabled."],
			order = 2,
			type = "toggle",
		},
		showPlayer = {
			hidden = isDisabled,
			name = E.STR.WHATS_NEW_ESCSEQ .. L["Show Player"],
			order = 3,
			type = "toggle",
		},
		unitBar = {
			hidden = isDisabled,
			name = L["Attach to Raid Frame"],
			desc = L["Convert to additional CD bars that attach to each unit's raid frame."],
			order = 4,
			type = "toggle",
		},
		locked = {
			hidden = isUnitBar,
			name = LOCK_FRAME,
			desc = L["Lock frame position"],
			order = 5,
			type = "toggle",
		},
		positionSettings = {
			hidden = notUnitBar,
			name = L["Position"],
			type = "group",
			inline = true,
			order = 10,
			args = {
				uf = {
					name = E.STR.WHATS_NEW_ESCSEQ .. ADDONS,
					desc = L["Select addon to override auto anchoring"],
					order = 1,
					type = "select",
					values = function() return E.customUF.optionTable end,
					set = function(info, value)
						local key, bar = info[2], info[4]
						local db = E.profile.Party[key].extraBars[bar]
						if P:IsCurrentZone(key) then
							if (not E.customUF.enabledList or value == "blizz") and not E:IsBlizzardCUFLoaded() then
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
				anchor = {
					name = L["Anchor Point"],
					desc = format("%s\n\n%s", L["Set the anchor point on the spell bar"],
						L["Having \"RIGHT\" in the anchor point, icons grow left, otherwise right"]),
					order = 2,
					type = "select",
					values = L_POINTS,
				},
				attach = {
					name = L["Attachment Point"],
					desc = L["Set the anchor attachment point on the party/raid frame"],
					order = 3,
					type = "select",
					values = L_POINTS,
				},
				offsetX = {
					name = L["Offset X"],
					desc = E.STR.MAX_RANGE,
					order = 5,
					type = "range",
					min = -999, max = 999, softMin = -100, softMax = 100, step = 1,
				},
				offsetY = {
					name = L["Offset Y"],
					desc = E.STR.MAX_RANGE,
					order = 6,
					type = "range",
					min = -999, max = 999, softMin = -100, softMax = 100, step = 1,
				},
			}
		},
		layoutSettings = {
			hidden = isDisabled,
			name = L["Layout"],
			type = "group",
			inline = true,
			order = 20,
			args = {
				spellType = {
					name = format("%s (%s)", L["Spell Types"], L["Multiselect"]),
					desc = format("%s\n\n%s", L["Select the spell types you want to display on this column."],
						L["You can mangage spell types for all bars from the Frame option"]),
					order = 1,
					type = "multiselect",
					dialogControl = "Dropdown-OmniCDC",
					values = E.L_PRIORITY,
					get = function(info, k) return E.profile.Party[ info[2] ].frame[k] == tonumber(strsub(info[4], 8)) end,
					set = function(info, k, state)
						local key = info[2]
						local value = state and tonumber(strsub(info[4], 8)) or 0
						E.profile.Party[key].frame[k] = value

						for id, v in pairs(E.profile.Party[key].spellFrame) do
							if E.hash_spelldb[id].type == k and v == value then
								E.profile.Party[key].spellFrame[id] = nil
							end
						end
						if P:IsCurrentZone(key) then
							P:UpdateEnabledSpells()
							P:UpdateAllBars()
						end
					end,
					disabledItem = function() return "interrupt" end,
				},
				layout = {
					name = L["Layout"],
					desc = L["Select the icon layout"],
					order = 2,
					type = "select",
					values = {
						horizontal = L["Horizontal"],
						vertical = L["Vertical"],
					},
				},
				sortBy = {
					hidden = isUnitBar,
					disabled = isUnitBar,
					name = COMPACT_UNIT_FRAME_PROFILE_SORTBY,
					order = 3,
					type = "select",
					values = function(info)
						return sortByValues[ info[4] ] or sortByValues.raidBar2
					end,
					sorting = function(info)
						return info[4] == "raidBar1" and {1,5,6,15,2,7,8,16} or nil
					end,
				},
				sortDirection = {
					hidden = isUnitBar,
					disabled = isUnitBar,
					name = L["Sort Direction"],
					order = 4,
					type = "select",
					values = {
						asc = L["Ascending"],
						dsc = L["Descending"],
					}
				},
				columns = {
					name = function(info)
						return E.profile.Party[ info[2] ].extraBars[ info[4] ].layout == "horizontal"
							and L["Column"] or L["Row"]
					end,
					desc = function(info)
						return E.profile.Party[ info[2] ].extraBars[ info[4] ].layout == "horizontal"
							and L["Set the number of icons per row"] or L["Set the number of icons per column"]
					end,
					order = 5,
					type = "range",
					min = 1, max = 100, softMax = 30, step = 1,
				},
				paddingX = {
					name = L["Padding X"],
					desc = L["Set the padding space between icon columns"],
					order = 6,
					type = "range",
					min = -5, max = 100, softMin = -1, softMax = 20, step = 1,
				},
				paddingY = {
					name = L["Padding Y"],
					desc = L["Set the padding space between icon rows"],
					order = 7,
					type = "range",
					min = -5, max = 100, softMin = -1, softMax = 20, step = 1,
				},
				growUpward = {
					name = L["Grow Rows Upward"],
					desc = L["Toggle the grow direction of icon rows"],
					order = 8,
					type = "toggle",
				},
				growLeft = {
					hidden = isUnitBar,
					disabled = isUnitBar,
					name = L["Grow Columns Left"],
					desc = L["Toggle the grow direction of icon columns"],
					order = 9,
					type = "toggle",
				},
			}
		},
		iconSettings = {
			hidden = isDisabled,
			name = L["Icon"],
			type = "group",
			inline = true,
			order = 30,
			args = {
				scale = {
					name = L["Icon Size"],
					desc = L["Set the size of icons"],
					order = 1,
					type = "range",
					min = 0.2, max = 2.0, step = 0.01, isPercent = true,
					set = function(info, value)
						local key, bar, option = info[2], info[4], info[#info]
						E.profile.Party[key].extraBars[bar].scale = value
						if P:IsCurrentZone(key) then
							local exBar = P.activeExBars[bar]
							if exBar then
								P:ConfigExSize(exBar)
							end
						end
					end
				},
				showName = {
					hidden = isUnitBar,
					disabled = isEnabledProgressBar,
					name = L["Show Name"],
					desc = L["Show name on icons"],
					order = 2,
					type = "toggle",
				},
				nameOfsY = {
					hidden = isUnitBar,
					disabled = isIconNameHidden,
					name = L["Name Offset Y"],
					order = 3,
					type = "range",
					min = -20, max = 50, step = 1,
				},
				truncateIconName = {
					hidden = isUnitBar,
					disabled = isIconNameHidden,
					name = L["Truncate Name"],
					desc = L["Adjust value until the truncate symbol [...] disappears.\n|cffff20200: Disable option"],
					order = 4,
					type = "range",
					min = 0, max = 20, step = 1,
				},
				classColor = {
					hidden = isUnitBar,
					disabled = isIconNameHidden,
					name = CLASS_COLORS,
					order = 5,
					type = "toggle",
				},
			}
		},
		progressBar = {
			hidden = isUnitBar,
			disabled = function(info)
				local db = E.profile.Party[ info[2] ].extraBars[ info[4] ]
				return not db.enabled or db.layout == "horizontal" or not db.progressBar
			end,
			name = L["Status Bar Timer"],
			order = 40,
			type = "group",
			inline = true,
			args = {
				progressBar = {
					disabled = function(info)
						local db = E.profile.Party[ info[2] ].extraBars[ info[4] ]
						return not db.enabled or db.layout == "horizontal"
					end,
					name = ENABLE,
					desc = L["Replace default timers with a status bar timer."],
					order = 1,
					type = "toggle",
				},
				lb1 = {
					name = "", order = 2, type = "description"
				},
				colField = {
					name = "",
					order = 3,
					type = "group",
					inline = true,
					args = {
						lb0 = { name = "", order = 0, type = "description", width = 0.5 },
						lb1 = { name = L["Active"], order = 1, type = "description", width = 0.5 },
						lb2 = { name = L["Recharge"], order = 2, type = "description", width = 0.5 },
						lb3 = { name = L["Inactive"], order = 3, type = "description", width = 0.5 },
						lb4 = { name = format("%s (%s)", CLASS_COLORS, L["Multiselect"]), order = 4, type = "description", width = 1 },
					}
				},
				textColors = {
					name = "",
					order = 4,
					type = "group",
					inline = true,
					get = getColor,
					set = setColor,
					args = progressBarColorInfo,
				},
				barColors = {
					disabled = isDisabledProgressBarOrNameBar,
					name = "",
					order = 5,
					type = "group",
					inline = true,
					get = getColor,
					set = setColor,
					args = progressBarColorInfo,
				},
				bgColors = {
					disabled = isDisabledProgressBarOrNameBar,
					name = "",
					order = 6,
					type = "group",
					inline = true,
					get = getColor,
					set = setColor,
					args = progressBarColorInfo,
				},
				lb2 = {
					name = "\n\n", order = 7, type = "description"
				},
				nameBar = {
					name = L["Convert to Name Bar"],
					desc = L["Convert the status bar timer to a simple name display by disabling all timer functions. The \'Name\' color scheme will be retained."],
					order = 8,
					type = "toggle",
				},
				invertNameBar = {
					disabled = function(info)
						local db = E.profile.Party[ info[2] ].extraBars[ info[4] ]
						return not db.enabled or db.layout == "horizontal" or not db.progressBar or not db.nameBar
					end,
					name = L["Invert Name Bar"],
					desc = L["Attach Name Bar to the left of icon"],
					order = 9,
					type = "toggle",
				},
				useIconAlpha = {
					name = L["Use Icon Alpha"],
					desc = L["Apply \'Icons\' alpha settings to the status bar"],
					order = 10,
					type = "toggle",
				},
				reverseFill = {
					disabled = isDisabledProgressBarOrNameBar,
					name = L["Reverse Fill"],
					desc = L["Timer will progress from right to left"],
					order = 11,
					type = "toggle",
				},
				hideSpark = {
					disabled = isDisabledProgressBarOrNameBar,
					name = L["Hide Spark"],
					desc = L["Hide the leading spark texture."],
					order = 12,
					type = "toggle",
				},
				hideBorder = {
					disabled = isDisabledProgressBarOrNameBar,
					name = L["Hide Border"],
					desc = L["Hide status bar border"],
					order = 13,
					type = "toggle",
				},
				showInterruptedSpell = {
					hidden = notInterruptBar,
					disabled = isDisabledProgressBarOrNameBar,
					name = L["Interrupted Spell Icon"],
					desc = format("%s\n\n|cffff2020%s", L["Show the interrupted spell icon."],
						L["Mouseovering the icon will show the interrupted spell information regardless of \'Show Tooltip\' option."]),
					order = 14,
					type = "toggle",
				},
				showRaidTargetMark = {
					hidden = notInterruptBar,
					disabled = isDisabledProgressBarOrNameBar,
					name = L["Interrupted Target Marker"] .. E.RAID_TARGET_MARKERS[1],
					desc = L["Show the interrupted unit's target marker if it exists."],
					order = 15,
					type = "toggle",
				},
				lb3 = {
					name = "\n", order = 16, type = "description"
				},
				statusBarWidth = {
					name = L["Bar width"],
					desc = format("%s\n\n%s", L["Set the status bar width. Adjust height with \'Icon Size\'."], E.STR.MAX_RANGE),
					order = 17,
					type = "range",
					min = 50, max = 999, softMax = 300, step = 1,
				},

				textOfsX = {
					name = L["Name Offset X"],
					order = 18,
					type = "range",
					min = 1, max = 30, step = 1,
				},
				textOfsY = {
					name = L["Name Offset Y"],
					order = 19,
					type = "range",
					min = -15, max = 15, step = 1,
				},
				truncateStatusBarName = {
					name = L["Truncate Name"],
					desc = L["Adjust value until the truncate symbol [...] disappears.\n|cffff20200: Disable option"],
					order = 20,
					type = "range",
					min = 0, max = 20, step = 1,
					get = function(info) return E.profile.Party[ info[2] ].extraBars[ info[4] ].truncateStatusBarName end,
					set = function(info, value)
						local key, bar = info[2], info[4]
						E.profile.Party[key].extraBars[bar].truncateStatusBarName = value
						if P:IsCurrentZone(key) then
							local icons = P.activeExBars[bar] and P.activeExBars[bar].icons
							if icons then
								for _, icon in ipairs(icons) do
									local name = P.groupInfo[icon.guid].nameWithoutRealm
									if value > 0 then
										name = string.utf8sub(name, 1, value)
									end
									local statusBar = icon.statusBar
									local castingBar = statusBar.CastingBar
									statusBar.name = name
									castingBar.name = name
									statusBar.Text:SetText(name)
									castingBar.Text:SetText(name)
								end
							end
						end
					end,
				},
				textScale = {
					name = L["Name Scale"],
					desc = format("%s\n\n%s", L["Set the Name Bar name scale"], L["The global font settings are in the General menu"]),
					order = 21,
					type = "range",
					min = 0.5, max = 1.0, step = 0.01, isPercent = true,
				},
			}
		},
		miscSettings = {
			hidden = isDisabled,
			name = MISCELLANEOUS,
			type = "group",
			inline = true,
			order = 50,
			args = {
				renameBar = {
					name = L["Rename Bar"],
					order = 1,
					type = "input",
					get = function(info)
						local value = E.profile.Party[ info[2] ].extraBars[ info[4] ].name
						if not value then
							local index = strsub(info[4], 8)
							value = index == "1" and L["Interrupts"] or index
						end
						return value
					end,
					set = function(info, value)
						local key, bar = info[2], info[4]
						if value == "" then
							local index = strsub(info[4], 8)
							value = index == "1" and L["Interrupts"] or index
						end
						E.profile.Party[key].extraBars[bar].name = value
						if P:IsCurrentZone(key) then
							local exBar = P.activeExBars[bar]
							if exBar then
								exBar:UpdatePositionValues()
								exBar:SetAnchor()
							end
						end
					end,
				},
				resetPos = {
					hidden = isUnitBar,
					name = RESET_POSITION,
					desc = L["Reset frame position"],
					order = 2,
					type = "execute",
					func = function(info)
						local key, bar = info[2], info[4]
						local exBar = P.activeExBars[bar]
						if exBar then
							if E.profile.Party[key].extraBars[bar].manualPos[bar] then
								wipe(E.profile.Party[key].extraBars[bar].manualPos[bar])
							end
							if P:IsCurrentZone(key) then
								E.LoadPosition(exBar)
							end
						end
					end,
					confirm = E.ConfirmAction,
				},
				resetBar = {
					name = RESET_TO_DEFAULT,
					desc = L["Reset current bar settings to default"],
					order = 3,
					type = "execute",
					func = function(info)
						local key, bar = info[2], info[4]
						E.profile.Party[key].extraBars[bar] = E:DeepCopy(C.Party[key].extraBars[bar])
						E:RefreshProfile()
					end,
					confirm = E.ConfirmAction,
				},
			}
		},
	}
}
for i = 1, 8 do
	local bar = P.extraBarKeys[i]
	extraBars.args[bar] = extraBarsInfo
end

local sliderTimer = {}
local updatePixelObj = function(exBar)
	exBar:UpdateExBarBackdrop()
	exBar:UpdateLayout()
	exBar:SetAnchor()
	sliderTimer[exBar.key] = nil
end

function P:ConfigExSize(exBar)
	exBar:UpdatePositionValues()
	exBar:SetContainerSize()
	exBar:SetUnitBarOffset()
	if E.db.icons.displayBorder or (exBar.db.layout == "vertical" and exBar.db.progressBar) then
		if not sliderTimer[exBar.key] then
			sliderTimer[exBar.key] = E.TimerAfter(0.3, updatePixelObj, exBar)
		end
	end
end

P:RegisterSubcategory("extraBars", extraBars)
