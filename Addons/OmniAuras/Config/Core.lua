local E, L = unpack(select(2, ...))
local module = E.Aura

E.moduleOptions = {}
E.optionsFrames = {}

local BORDERLESS_TCOORDS = { 0.07, 0.93, 0.07, 0.93 }
E.BORDERLESS_TCOORDS = BORDERLESS_TCOORDS

local function ConfirmAction()
	return L["All user set values will be lost. Do you want to proceed?"]
end
E.ConfirmAction = ConfirmAction

local function GetLocalization()
	local localization = E.Localizations
	localization = localization:gsub("enUS", ENUS):gsub("deDE", DEDE)
	localization = localization:gsub("esES", ESES):gsub("esMX", ESMX)
	localization = localization:gsub("frFR", FRFR):gsub("koKR", KOKR)
	localization = localization:gsub("ruRU", RURU):gsub("zhCN", ZHCN)
	localization = localization:gsub("zhTW", ZHTW)
	localization = localization:gsub("itIT", LFG_LIST_LANGUAGE_ITIT)
--	localization = localization:gsub("ptBR", LFG_LIST_LANGUAGE_PTBR)
	return localization
end

L["Localizations"] = LANGUAGES_LABEL or L["Languages"]
L["Translations"] = BUG_CATEGORY15 or L["Language Translation"]

local labels = {
	"Version",
	"Author",
	"Localizations",
	"Translations",
	"/oa t:",
	"/oa rl:",
	"/oa rt db:",
}

local fields = {
	["Localizations"] = GetLocalization(),
	["Translations"] = format("%s (%s), %s (%s)", LFG_LIST_LANGUAGE_ITIT, "Grifo92", KOKR, "007bb"),
	["/oa t:"] = L["Toggle test frames."],
	["/oa rl:"] = L["Reload addon."],
	["/oa rt db:"] = L["Clean wipe the savedvariable file. |cffff2020Warning|r: This can not be undone!"],
}

local getField = function(info) local label = info[#info] return fields[label] or E[label] or "" end

local getGlobalOption = function(info) return E.global[ info[#info] ] end
local setGlobalOption = function(info, value) E.global[ info[#info] ] = value end

local isRaidFramePreset = function(info)
	local filter = info[#info-2]
	return not E.profile.raidFrame[filter].enabled or E.profile.raidFrame[filter].preset ~= "manual"
end

local isRaidFrameOverDebuffs = function()
	return not E.profile.raidFrame.HARMFUL.enabled or E.profile.raidFrame.HARMFUL.preset == "overDebuffs"
end

local isRaidFrameOverBuffs = function()
	return not E.profile.raidFrame.MYHELPFUL.enabled or E.profile.raidFrame.MYHELPFUL.preset == "overBuffs"
end

local notAuto = function(info)
	local frame, filter = info[2], info[3]
	return not E.profile.unitFrame[frame][filter].enabled or E.profile.unitFrame[frame][filter].preset ~= "AUTO"
end

local isPortrait = function(info)
	local frame, filter = info[2], info[3]
	return not E.profile.unitFrame[frame][filter].enabled or E.profile.unitFrame[frame][filter].preset == "PORTRAIT"
end

local notArenaFrameOverDebuffs = function(info)
	local filter = info[#info-2]
	return not E.profile.unitFrame.arena[filter].enabled or E.profile.unitFrame.arena[filter].preset ~= "overDebuffs"
end

local isArenaFrameOverDebuffs = function(info)
	local filter = info[#info-2]
	return not E.profile.unitFrame.arena[filter].enabled or E.profile.unitFrame.arena[filter].preset == "overDebuffs"
end

local getColor = function(info)
	local frame, filter, option = info[#info-3], info[#info-2], info[#info]
	local db = info[1] == "unitFrame" and E.profile.unitFrame[frame][filter][option] or E.profile[frame][filter][option]
	return db.r, db.g, db.b
end

local setColor = function(info, r, g, b)
	local frame, filter, option = info[#info-3], info[#info-2], info[#info]
	local db = info[1] == "unitFrame" and E.profile.unitFrame[frame][filter][option] or E.profile[frame][filter][option]
	db.r, db.g, db.b = r, g, b
	E:Refresh()
end

local notPixelOrIsPortrait = function(info)
	local frame, filter = info[#info-3], info[#info-2]
	local db = info[1] == "unitFrame" and E.profile.unitFrame[frame][filter] or E.profile[frame][filter]
	return not db.enabled or db.preset == "PORTRAIT" or db.borderType ~= "pixel"
end

local notPixelDebuff = function(info)
	local frame, filter = info[#info-3], info[#info-2]
	local db = info[1] == "unitFrame" and E.profile.unitFrame[frame][filter] or E.profile[frame][filter]
	return not db.enabled or db.borderType ~= "pixelDebuff"
end

local notRaidFrameOverDebuffs = function()
	return not E.profile.raidFrame.enabled or not E.profile.raidFrame.HARMFUL.enabled or E.profile.raidFrame.HARMFUL.preset ~= "overDebuffs"
end

local getTypeColor = function(info)
	local frame, filter, option = info[#info-3], info[#info-2], info[#info]
	local db = info[1] == "unitFrame" and E.profile.unitFrame[frame][filter].debuffTypeColor[option] or E.profile[frame][filter].debuffTypeColor[option]
	return db.r, db.g, db.b
end

local setTypeColor = function(info, r, g, b)
	local frame, filter, option = info[#info-3], info[#info-2], info[#info]
	local db = info[1] == "unitFrame" and E.profile.unitFrame[frame][filter].debuffTypeColor[option] or E.profile[frame][filter].debuffTypeColor[option]
	db.r, db.g, db.b = r, g, b
	E:Refresh()
end

--
-- Options
--

local glow = {
	name = L["Glow"],
	order = 60,
	type = "group", inline = true,
	args = {
		glow = {
			name = L["Enable"],
			desc = format("%s\n\n%s", L["Display a glow animation around an icon when a new aura is shown"],
			L["|cffff2020Only applies to auras that have Glow enabled in the Auras tab"]),
			order = 1,
			type = "toggle",
		},
	}
}

local visibility = {
	zone = {
		name = L["Zone"],
		type = "multiselect",
		values = {
			["arena"] = ARENA,
			["pvp"] = BATTLEGROUNDS,
			["party"] = DUNGEONS,
			["raid"] = RAIDS,
			["scenario"] = SCENARIOS,
			["none"] = BUG_CATEGORY2,
		},
		width = "full",
	}
}

local priority = {}
for typeClass, prio in pairs(E.auraClassPriority) do
	priority[typeClass] = {
		order = 200 - prio,
		name = L[typeClass],
		type = "range", min = 0, max = 100, step = 10,
	}
end

local function GetOptions()
	if not E.options then
		E.options = {
			name = E.AddOn,
			type = "group",
			plugins = { profiles = { profiles = E.optionsFrames.profiles } },
			args = {
				Home = {
					order = 0,
					name = format("|T%s:18|t %s", E.Libs.OmniCDC.texture.logo, E.AddOn),
					type = "group", childGroups = "tab",
					get = function(info) return E.profile[info[#info]] end,
					set = function(info, value) E.profile[info[#info]] = value end,
					args = {
						title = {
							image = E.Libs.OmniCDC.texture.logo, imageWidth = 64, imageHeight = 64, imageCoords = { 0, 1, 0, 1 },
							name = E.AddOn,
							order = 0,
							type = "description",
							fontSize = "large",
						},
						pd1 = {
							name = "\n\n\n", order = .5, type = "description", -- keep order. label added in between
						},
						pd2 = {
							name = "\n\n", order = 10, type = "description",
						},
						loginMessage = {
							name = L["Login Message"],
							order = 11,
							type = "toggle",
							get = getGlobalOption,
							set = setGlobalOption,
						},
						minusScale = {
							disabled = function() return E.global.optionPanelScale < 0.84 end,
							image = E.Libs.OmniCDC.texture.minus, imageWidth = 18, imageHeight = 18,
							name = "",
							order = 13,
							type = "execute",
							func = function()
								local currScale = E.global.optionPanelScale
								if currScale > 0.84 then
									currScale = currScale - 0.05
									E.global.optionPanelScale = currScale
									E.Libs.ACD:SetDefaultSize(E.AddOn, nil,nil, currScale)
								end
							end,
							width = 0.15,
						},
						currScale = {
							name = function() return format("%s%%", E.global.optionPanelScale * 100) end,
							order = 14,
							type = "description",
							justifyH = "CENTER",
							width = 0.3,
						},
						plusScale = {
							disabled = function() return E.global.optionPanelScale == 1.5 end,
							image = E.Libs.OmniCDC.texture.plus, imageWidth = 18, imageHeight = 18,
							name = "",
							order = 15,
							type = "execute",
							func = function()
								local currScale = E.global.optionPanelScale
								if currScale < 1.46 then
									currScale = currScale + 0.05
									E.global.optionPanelScale = currScale
									E.Libs.ACD:SetDefaultSize(E.AddOn, nil,nil, currScale)
								end
							end,
							width = 0.15,
						},
						pd3 = {
							name = "\n", order = 16, type = "description",
						},
						notice = {
							image = E.Libs.OmniCDC.texture.recent, imageWidth = 32, imageHeight = 16, imageCoords = { 0.13, 1.13, 0.25, 0.75 },
							name = " ",
							order = 17,
							type = "description",
						},
						pd4 = {
							name = "\n\n\n", order = 30, type = "description",
						},
						changelog = {
							name = L["Changelog"],
							order = 40,
							type = "group",
							args = {
								lb1 = {
									name = "\n", order = 0, type = "description",
								},
								changelog = {
									name = E.changelog,
									order = 1,
									type = "description",
								},
							}
						},
						slashCommands = {
							name = L["Slash Commands"],
							order = 50,
							type = "group",
							get = getField,
							args = {
								lb1 = { name = L["Usage:"], order = 1, type = "description" },
								lb2 = { name = "/oa <command> <value:optional>", order = 2, type = "description"},
								lb3 = { name = "\n\n", order = 3, type = "description"},
								lb4 = { name = L["Commands:"], order = 4, type = "description"},
							}
						},
						feedback = {
							name = L["Feedback"],
							order = 60,
							type = "group",
							args = {
								issues = {
									name = SUGGESTFRAME_TITLE or L["Suggestions and Bugs"],
									desc = L["Press Ctrl+C to copy URL"],
									order = 1,
									type = "input", dialogControl = "Link-OmniCDC",
									get = function() return "https://www.curseforge.com/wow/addons/omniauras/issues" end,
								},
								translate = {
									name = L["Help Translate"],
									desc = L["Press Ctrl+C to copy URL"],
									order = 2,
									type = "input", dialogControl = "Link-OmniCDC",
									get = function() return "https://www.curseforge.com/wow/addons/omniauras/localization" end,
								},
							}
						},
						otherAddOns = {
							name = ADDONS,
							order = 70,
							type = "group",
							args = {
								omnicd = {
									name = "OmniCD",
									desc = "Party cooldown tracker",
									order = 1,
									type = "input",
									dialogControl = "Link-OmniCDC",
									get = function() return "https://www.curseforge.com/wow/addons/omnicd" end,
								},
								--[[
								omnisort = {
									name = "OmniSort",
									desc = "Party group sorter with auto-adjusting keybinds and macros",
									order = 2,
									type = "input",
									dialogControl = "Link-OmniCDC",
									get = function() return "https://www.curseforge.com/wow/addons/omnisort" end,
								},
								]]
							}
						},
					}
				},
				raidFrame = {
					disabled = function(info) return info[2] and not E.profile.raidFrame.enabled end,
					name = L["Raid Frame"],
					order = 100,
					type = "group", childGroups = "tab",
					get = function(info) local name = info[#info] return E.profile.raidFrame[name] end,
					set = function(info, value) local name = info[#info] E.profile.raidFrame[name] = value E:Refresh() end,
					args = {
						enabled = {
							disabled = false,
							name = L["Enable"],
							order = 1,
							type = "toggle",
						},
						test = {
							name = format("%s (%s)", L["Test"], UNLOCK),
							order = 2,
							type = "toggle",
							get = function() return module.isInTestMode end,
							set = "ToggleTestMode",
							handler = module,
						},
						globalScale = {
							name = L["Global Scale"],
							desc = format("%s\n\n%s\n%s", L["Set the global scale of raid frame auras"], L["15: 10.1 default"], L["22: Legacy default"]),
							order = 3,
							type = "range", min = 15, max = 22, step = 1,
						},
						HARMFUL = {
							disabled = function(info) return not E.profile.raidFrame.enabled or (info[3] and not E.profile.raidFrame.HARMFUL.enabled) end,
							name = L["Debuffs"],
							order = 10,
							type = "group",
							get = function(info) local name = info[#info] return E.profile.raidFrame.HARMFUL[name] end,
							set = function(info, value) local name = info[#info] E.profile.raidFrame.HARMFUL[name] = value E:Refresh(name == "sortby") end,
							args = {
								enabled = {
									disabled = false,
									name = L["Enable"],
									order = 1,
									type = "toggle",
								},
								showPlayer = {
									name = L["Show Player"],
									order = 2,
									type = "toggle",
								},
								showTooltip = {
									name = L["Show Tooltip"],
									order = 3,
									type = "toggle",
								},
								redirectBlizzardDebuffs = {
									name = L["Redirect Blizzard Debuffs"],
									desc = L["Hide Blizzard's debuff frame and redirect all debuffs displayed by Blizzard to this frame"],
									order = 4,
									type = "toggle",
								},
								anchor = {
									name = L["Position"],
									order = 10,
									type = "group", inline = true,
									args = {
										preset = {
											name = L["Presets"],
											desc = L["When using Blizzard Default Location, use the Global Scale option to resize icons."],
											order = 0,
											type = "select",
											values = {
												overDebuffs = L["Blizzard Default Location"],
												raidFrameLeft = L["Raid Frame Left"],
												raidFrameRight = L["Raid Frame Right"],
											},
											set = function(_, value)
												E.profile.raidFrame.HARMFUL.preset = value
												if (value == "overDebuffs") then
													E.profile.raidFrame.HARMFUL.point = "BOTTOMLEFT"
													E.profile.raidFrame.HARMFUL.relativeFrame = "debuffFrame"
													E.profile.raidFrame.HARMFUL.relativePoint = "BOTTOMLEFT"
												elseif (value == "raidFrameLeft") then
													E.profile.raidFrame.HARMFUL.point = "BOTTOMRIGHT"
													E.profile.raidFrame.HARMFUL.relativeFrame = "debuffFrame"
													E.profile.raidFrame.HARMFUL.relativePoint = "BOTTOMLEFT"
												elseif (value == "raidFrameRight") then
													E.profile.raidFrame.HARMFUL.point = "BOTTOMLEFT"
													E.profile.raidFrame.HARMFUL.relativeFrame = "buffFrame"
													E.profile.raidFrame.HARMFUL.relativePoint = "BOTTOMRIGHT"
												end
												E:Refresh()
											end
										},
										offsetX = {
											disabled = isRaidFrameOverDebuffs,
											name = L["Offset X"],
											order = 1,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										offsetY = {
											disabled = isRaidFrameOverDebuffs,
											name = L["Offset Y"],
											order = 2,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										frameLevel = {
											name = L["Frame Level"],
											desc = L["-1: Show below Blizzard's buff/debuff icons (Tooltips will no longer work)"],
											order = 3,
											type = "range", min = -1, max = 9, step = 2,
										},
										detachBigDebuffs = {
											disabled = function(info) return info[5] and not E.profile.raidFrame.HARMFUL.enabled or E.profile.raidFrame.HARMFUL.preset ~= "overDebuffs" end,
											name = L["Detach Big Debuffs"],
											order = 25,
											type = "group", inline = true,
											args = {
												detachBigDebuffs = {
													name = L["Zone"],
													desc = L["Detach big debuffs and show them in a separate display attached to the left or right of the raid frame"],
													order = 1,
													type =	"multiselect",
													dialogControl = "Dropdown-OmniCDC",
													values = {
														["arena"] = ARENA,
														["pvp"] = BATTLEGROUNDS,
														["party"] = DUNGEONS,
														["none"] = BUG_CATEGORY2,
													},
													get = function(_, k) return E.profile.raidFrame.HARMFUL.detachBigDebuffs[k] end,
													set = function(_, k, value) E.profile.raidFrame.HARMFUL.detachBigDebuffs[k] = value E:Refresh() end,
												},
												detachPreset = {
													name = L["Position"],
													order = 2,
													type = "select",
													values = {
														raidFrameLeft = L["Raid Frame Left"],
														raidFrameRight = L["Raid Frame Right"],
													},
													set = function(_, value)
														E.profile.raidFrame.HARMFUL.detachPreset = value
														if (value == "raidFrameLeft") then
															E.profile.raidFrame.HARMFUL.detachPoint = "BOTTOMRIGHT"
															E.profile.raidFrame.HARMFUL.detachRelativeFrame = "debuffFrame"
															E.profile.raidFrame.HARMFUL.detachRelativePoint = "BOTTOMLEFT"
														elseif (value == "raidFrameRight") then
															E.profile.raidFrame.HARMFUL.detachPoint = "BOTTOMLEFT"
															E.profile.raidFrame.HARMFUL.detachRelativeFrame = "buffFrame"
															E.profile.raidFrame.HARMFUL.detachRelativePoint = "BOTTOMRIGHT"
														end
														E:Refresh()
													end
												},
												detachScale = {
													name = L["Filter by Scale"],
													desc = L["Debuffs with greater scaling than the selected value will detach"],
													order = 3,
													type = "range", min = 1, softMin = 1.1, max = 3, step = 0.05, isPercent = true, -- XXX softMin req if we're comparing equality with other opt values
													set = function(_, value)
														E.profile.raidFrame.HARMFUL.detachScale = value == 1 and 1.05 or value
														E:Refresh()
													end,
												},
												detachMaxIcons = {
													name = L["Max Number of Detached Debuffs"],
													order = 4,
													type = "range", min = 1, max = 6, step = 1,
												},
												detachOffsetX = {
													name = L["Offset X"],
													order = 5,
													type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
												},
											}
										},
									}
								},
								layout = {
									name = L["Layout"],
									order = 20,
									type = "group", inline = true,
									args = {
										sortby = {
											name = L["Sort By"],
											desc = L["Use New if your Max Number of Aura is less than 3"],
											order = 0,
											type = "select",
											values = {
												scalePrioNew = L["Scale > Priority > New"],
												scalePrioOld = L["Scale > Priority > Old"],
											},
										},
										maxIcons = {
											name = L["Max Number of Auras"],
											desc = format("%s\n\n%s\n\n%s", L["Set the max number of displayed auras."],
											L["Layout will automatically adjust to prevent the buff and debuff frames from overlapping each other."],
											L["When you are in a raid group outside of arena and using the Blizzard Default Location, the number of buffs/debuffs are limited to 6/3 to prevent them from covering adjacent frames."]),
											order = 1,
											type = "range", min = 1, max = E.NUM_RF_OVERLAYS.HARMFUL, step = 1,
										},
										alwaysShowMaxNumIcons = {
											disabled = notRaidFrameOverDebuffs,
											name = L["Always Show Max Number of Debuffs"],
											desc = L["Debuffs that can't fit inside the raid frame when multiple big debuffs are displayed will attach to the outer left side of the raid frame. Disabling this option will only show what can fit inside the raid frame when your Max Number of Auras is equal to or smaller than the number of base size icons that can fit inside the raid frame."],
											order = 2,
											type = "toggle",
										},
										stackOuter = {
											disabled = notRaidFrameOverDebuffs,
											name = L["Stack Outer Icons"],
											desc = L["Stack outer icons (3x3). Disable to show outer icon in a single row"],
											order = 3,
											type = "toggle",
										},
									}
								},
								icon = {
									name = L["Icon"],
									order = 30,
									type = "group", inline = true,
									args = {
										scale = {
											disabled = isRaidFrameOverDebuffs,
											name = format("%s.\n\n%s", L["Icon Size"],
											L["Max icon height will auto-adjust so that it doesn't exceed the raid frame's height"]),
											order = 1,
											type = "range", min = 1, max = 2, step = 0.01, isPercent = true,
										},
										opacity = {
											name = L["Icon Opacity"],
											order = 2,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										counterScale = {
											name = L["Counter Size"],
											order = 3,
											type = "range", min = 0.5, max = 1, step = 0.05, isPercent = true,
										},
										swipeAlpha = {
											name = L["Swipe Opacity"],
											order = 4,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										hideCounter = {
											name = L["Hide Counter"],
											order = 5,
											type = "toggle",
										},
										hideNonCCCounter = {
											disabled = function() return not E.profile.raidFrame.enabled or not E.profile.raidFrame.HARMFUL.enabled
											or E.profile.raidFrame.HARMFUL.hideCounter end,
											name = L["Hide Counter on Base Size Icons"],
											order = 6,
											type = "toggle",
										},
									}
								},
								border = {
									name = L["Border"],
									order = 40,
									type = "group", inline = true,
									args = {
										borderType = {
											name = L["Border Type"],
											order = 0,
											type = "select",
											values = {
												pixel = L["Pixel"],
												pixelDebuff = L["Pixel - Debuff Type"],
												blizzard = L["Blizzard"],
											}
										},
										borderColor = {
											disabled = notPixelOrIsPortrait,
											name = L["Default"],
											order = 1,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getColor,
											set = setColor,
										},
										none = {
											disabled = notPixelDebuff,
											name = L["Physical"], --STRING_SCHOOL_PHYSICAL,
											order = 3,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
										Magic = {
											disabled = notPixelDebuff,
											name = L["Magic"], --STRING_SCHOOL_MAGIC,
											order = 4,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
										Curse = {
											disabled = notPixelDebuff,
											name = L["Curse"],
											order = 5,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
										Disease = {
											disabled = notPixelDebuff,
											name = L["Disease"],
											order = 6,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
										Poison = {
											disabled = notPixelDebuff,
											name = L["Poison"],
											order = 7,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
									}
								},
								typeScale = {
									name = L["Debuff Size"],
									type = "group", inline = true,
									order = 50,
									args = {
										hardCC = {
											name = L["hardCC"],
											desc = format("%s.\n\n%s", L["Values are relative to Icon Size"],
											L["Max icon height will auto-adjust so that it doesn't exceed the raid frame's height"]),
											order = 1,
											type = "range", min = 1, max = 3, step = 0.05, isPercent = true,
											get = function() return E.profile.raidFrame.HARMFUL.typeScale.hardCC end,
											set = function(_, value) E.profile.raidFrame.HARMFUL.typeScale.hardCC = value E:Refresh() end,
										},
										softCC = {
											name = L["softCC"],
											desc = format("%s.\n\n%s", L["Values are relative to Icon Size"],
											L["Max icon height will auto-adjust so that it doesn't exceed the raid frame's height"]),
											order = 2,
											type = "range", min = 1, max = 3, step = 0.05, isPercent = true,
											get = function() return E.profile.raidFrame.HARMFUL.typeScale.softCC end,
											set = function(_, value) E.profile.raidFrame.HARMFUL.typeScale.softCC = value E:Refresh() end,
										},
										disarmRoot = {
											name = L["disarmRoot"],
											desc = format("%s.\n\n%s", L["Values are relative to Icon Size"],
											L["Max icon height will auto-adjust so that it doesn't exceed the raid frame's height"]),
											order = 3,
											type = "range", min = 1, max = 3, step = 0.05, isPercent = true,
											get = function() return E.profile.raidFrame.HARMFUL.typeScale.disarmRoot end,
											set = function(_, value) E.profile.raidFrame.HARMFUL.typeScale.disarmRoot = value E:Refresh() end,
										},
										largerIcon = {
											name = L["Larger Icon"],
											desc = format("%s.\n\n%s", L["Values are relative to Icon Size"], L["|cffff2020Only applies to auras that have Larger Icon enabled in the Auras tab"]),
											order = 4,
											type = "range", min = 1, max = 1.5, step = 0.05, isPercent = true,
										},
										dispellableNPCSizeIncrease = {
											name = L["Dispellable NPC Debuffs"],
											desc = L["9: Boss debuff size"],
											order = 5,
											type = "range", min = 0, max = 9, step = 1,
										},
									}
								},
								glow = glow,
							}
						},
						HELPFUL = {
							disabled = function(info) return not E.profile.raidFrame.enabled or (info[3] and not E.profile.raidFrame.HELPFUL.enabled) end,
							name = L["Buffs"],
							order = 20,
							type = "group",
							get = function(info) local name = info[#info] return E.profile.raidFrame.HELPFUL[name] end,
							set = function(info, value) local name = info[#info] E.profile.raidFrame.HELPFUL[name] = value E:Refresh(name == "sortby") end,
							args = {
								enabled = {
									disabled = false,
									name = L["Enable"],
									order = 1,
									type = "toggle",
								},
								showPlayer = {
									name = L["Show Player"],
									order = 2,
									type = "toggle",
								},
								showTooltip = {
									name = L["Show Tooltip"],
									order = 3,
									type = "toggle",
								},
								anchor = {
									name = L["Position"],
									order = 10,
									type = "group", inline = true,
									args = {
										preset = {
											name = L["Presets"],
											order = 0,
											type = "select",
											values = {
												raidFrameLeft = L["Raid Frame Left"],
												raidFrameRight = L["Raid Frame Right"],
												raidFrameCenter = L["Raid Frame Center"],
												manual = L["More..."],
											},
											set = function(_, value)
												E.profile.raidFrame.HELPFUL.preset = value
												if (value == "raidFrameLeft") then
													E.profile.raidFrame.HELPFUL.point = "BOTTOMRIGHT"
													E.profile.raidFrame.HELPFUL.relativeFrame = "debuffFrame"
													E.profile.raidFrame.HELPFUL.relativePoint = "BOTTOMLEFT"
												elseif (value == "raidFrameRight") then
													E.profile.raidFrame.HELPFUL.point = "BOTTOMLEFT"
													E.profile.raidFrame.HELPFUL.relativeFrame = "buffFrame"
													E.profile.raidFrame.HELPFUL.relativePoint = "BOTTOMRIGHT"
												elseif (value == "raidFrameCenter") then
													E.profile.raidFrame.HELPFUL.point = "CENTER"
													E.profile.raidFrame.HELPFUL.relativeFrame = "raidFrame"
													E.profile.raidFrame.HELPFUL.relativePoint = "CENTER"
												end
												E:Refresh()
											end
										},
										point = {
											disabled = isRaidFramePreset,
											name = L["Point"],
											order = 1,
											type = "select",
											values = {
												["BOTTOMLEFT"] = L["BOTTOMLEFT"],
												["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
												["CENTER"] = L["CENTER"],
												["LEFT"] = L["LEFT"],
												["RIGHT"] = L["RIGHT"],
												["TOPLEFT"] = L["TOPLEFT"],
												["TOPRIGHT"] = L["TOPRIGHT"],
											},
										},
										relativeFrame = {
											disabled = isRaidFramePreset,
											name = L["Relative Frame"],
											order = 2,
											type = "select",
											values = {
												raidFrame = L["Raid Frame"],
												debuffFrame = L["Debuff Frame"],
												buffFrame = L["Buff Frame"],
											},
										},
										relativePoint = {
											disabled = isRaidFramePreset,
											name = L["Relative Point"],
											order = 3,
											type = "select",
											values = {
												["BOTTOMLEFT"] = L["BOTTOMLEFT"],
												["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
												["CENTER"] = L["CENTER"],
												["LEFT"] = L["LEFT"],
												["RIGHT"] = L["RIGHT"],
												["TOPLEFT"] = L["TOPLEFT"],
												["TOPRIGHT"] = L["TOPRIGHT"],
											},
										},
										offsetX = {
											name = L["Offset X"],
											order = 4,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										offsetY = {
											name = L["Offset Y"],
											order = 5,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										frameLevel = {
											name = L["Frame Level"],
											desc = L["-1: Show below Blizzard's buff/debuff icons (Tooltips will no longer work)"],
											order = 6,
											type = "range", min = -1, max = 9, step = 2,
										},
									}
								},
								layout = {
									name = L["Layout"],
									order = 20,
									type = "group", inline = true,
									args = {
										sortby = {
											name = L["Sort By"],
											desc = L["Use New if your Max Number of Aura is less than 3"],
											order = 0,
											type = "select",
											values = {
												prioOld = L["Priority > Old"],
												prioNew = L["Priority > New"],
											},
										},
										maxIcons = {
											name = L["Max Number of Auras"],
											desc = L["Set the max number of displayed auras."],
											order = 1,
											type = "range", min = 1, max = E.NUM_RF_OVERLAYS.HELPFUL, step = 1,
										},
									}
								},
								icon = {
									name = L["Icon"],
									order = 30,
									type = "group", inline = true,
									args = {
										scale = {
											name = L["Icon Size"],
											order = 1,
											type = "range", min = 1, max = 2, step = 0.01, isPercent = true,
										},
										opacity = {
											name = L["Icon Opacity"],
											order = 2,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										counterScale = {
											name = L["Counter Size"],
											order = 3,
											type = "range", min = 0.5, max = 1, step = 0.05, isPercent = true,
										},
										swipeAlpha = {
											name = L["Swipe Opacity"],
											order = 4,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										hideCounter = {
											name = L["Hide Counter"],
											order = 5,
											type = "toggle",
										},
									}
								},
								border = {
									name = L["Border"],
									order = 40,
									type = "group", inline = true,
									args = {
										borderType = {
											name = L["Border Type"],
											type = "select",
											values = {
												pixel = L["Pixel"],
											}
										},
									}
								},
								glow = glow,
							}
						},
						MYHELPFUL = {
							disabled = function(info) return not E.profile.raidFrame.enabled or (info[3] and not E.profile.raidFrame.MYHELPFUL.enabled) end,
							name = L["Blizzard Buffs"],
							order = 25,
							type = "group",
							get = function(info) local name = info[#info] return E.profile.raidFrame.MYHELPFUL[name] end,
							set = function(info, value) local name = info[#info] E.profile.raidFrame.MYHELPFUL[name] = value E:Refresh(name == "sortby") end,
							args = {
								enabled = {
									disabled = false,
									name = L["Enable"],
									desc = L["Hide Blizzard's buff frame and redirect all buffs displayed by Blizzard to this frame"],
									order = 1,
									type = "toggle",
								},
								showPlayer = {
									name = L["Show Player"],
									order = 2,
									type = "toggle",
								},
								showTooltip = {
									name = L["Show Tooltip"],
									order = 3,
									type = "toggle",
								},
								anchor = {
									name = L["Position"],
									order = 10,
									type = "group", inline = true,
									args = {
										preset = {
											name = L["Presets"],
											desc = L["When using Blizzard Default Location, use the Global Scale option to resize icons."],
											order = 0,
											type = "select",
											values = {
												overBuffs = L["Blizzard Default Location"],
												raidFrameLeft = L["Raid Frame Left"],
												raidFrameRight = L["Raid Frame Right"],
											},
											set = function(_, value)
												E.profile.raidFrame.MYHELPFUL.preset = value
												if (value == "overBuffs") then
													E.profile.raidFrame.MYHELPFUL.point = "BOTTOMRIGHT"
													E.profile.raidFrame.MYHELPFUL.relativeFrame = "buffFrame"
													E.profile.raidFrame.MYHELPFUL.relativePoint = "BOTTOMRIGHT"
												elseif (value == "raidFrameLeft") then
													E.profile.raidFrame.MYHELPFUL.point = "BOTTOMRIGHT"
													E.profile.raidFrame.MYHELPFUL.relativeFrame = "debuffFrame"
													E.profile.raidFrame.MYHELPFUL.relativePoint = "BOTTOMLEFT"
												elseif (value == "raidFrameRight") then
													E.profile.raidFrame.MYHELPFUL.point = "BOTTOMLEFT"
													E.profile.raidFrame.MYHELPFUL.relativeFrame = "buffFrame"
													E.profile.raidFrame.MYHELPFUL.relativePoint = "BOTTOMRIGHT"
												end
												E:Refresh()
											end
										},
										offsetX = {
											disabled = isRaidFrameOverBuffs,
											name = L["Offset X"],
											order = 1,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										offsetY = {
											disabled = isRaidFrameOverBuffs,
											name = L["Offset Y"],
											order = 2,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										frameLevel = {
											name = L["Frame Level"],
											desc = L["-1: Show below Blizzard's buff/debuff icons (Tooltips will no longer work)"],
											order = 3,
											type = "range", min = -1, max = 9, step = 2,
										},
									}
								},
								layout = {
									name = L["Layout"],
									order = 20,
									type = "group", inline = true,
									args = {
										sortby = {
											name = L["Sort By"],
											desc = L["Use New if your Max Number of Aura is less than 3"],
											order = 0,
											type = "select",
											values = {
												none = L["Castable > Old (Blizzard Default)"],
											},
										},
										maxIcons = {
											name = L["Max Number of Auras"],
											desc = format("%s\n\n%s\n\n%s", L["Set the max number of displayed auras."],
											L["Layout will automatically adjust to prevent the buff and debuff frames from overlapping each other."],
											L["When you are in a raid group outside of arena and using the Blizzard Default Location, the number of buffs/debuffs are limited to 6/3 to prevent them from covering adjacent frames."]),
											order = 1,
											type = "range", min = 1, max = E.NUM_RF_OVERLAYS.MYHELPFUL, step = 1,
										},
										numInnerIcons = {
											disabled = function() return not E.profile.raidFrame.enabled or not E.profile.raidFrame.MYHELPFUL.enabled
											or E.profile.raidFrame.MYHELPFUL.preset ~= "overBuffs" end,
											name = L["Number of Inner Icons"],
											desc = format("%s\n\n%s", L["Set the number of icons you want to show inside the raid frame"],
											L["Layout will automatically adjust to prevent the buff and debuff frames from overlapping each other."]),
											order = 2,
											type = "select",
											values = { [3]=3, [6]=6, [9]=9 },
										},
									}
								},
								icon = {
									name = L["Icon"],
									order = 30,
									type = "group", inline = true,
									args = {
										scale = {
											disabled = isRaidFrameOverBuffs,
											name = L["Icon Size"],
											order = 1,
											type = "range", min = 1, max = 2, step = 0.01, isPercent = true,
										},
										opacity = {
											name = L["Icon Opacity"],
											order = 2,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										counterScale = {
											name = L["Counter Size"],
											order = 3,
											type = "range", min = 0.5, max = 1, step = 0.05, isPercent = true,
										},
										swipeAlpha = {
											name = L["Swipe Opacity"],
											order = 4,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										hideCounter = {
											name = L["Hide Counter"],
											order = 5,
											type = "toggle",
										},
									}
								},
								border = {
									name = L["Border"],
									order = 40,
									type = "group", inline = true,
									args = {
										borderType = {
											name = L["Border Type"],
											type = "select",
											values = {
												pixel = L["Pixel"],
											}
										},
									}
								},
								glow = glow,
							}
						},
						visibility = {
							name = L["Visibility"],
							order = 30,
							type = "group",
							get = function(_, k) return E.profile.raidFrame.visibility[k] end,
							set = function(_, k, value) E.profile.raidFrame.visibility[k] = value E:Refresh() end,
							args = visibility,
						},
						priority = {
							name = L["Priority"],
							order = 90,
							type = "group",
							get = function(info) local option = info[#info] return E.profile.raidFrame.priority[option] end,
							set = function(info, value) local option = info[#info] E.profile.raidFrame.priority[option] = value E:Refresh() end,
							args = priority,
						},
					}
				},
				unitFrame = {
					disabled = function(info) return info[2] and not E.profile.unitFrame.enabled end,
					name = L["Unit Frame"],
					order = 200,
					type = "group", --childGroups = "tab",
					get = function(info) local name = info[#info] return E.profile.unitFrame[name] end,
					set = function(info, value) local name = info[#info] E.profile.unitFrame[name] = value E:Refresh() end,
					args = {
						enabled = {
							disabled = false,
							name = L["Enable"],
							order = 1,
							type = "toggle",
						},
						test = {
							name = format("%s (%s)", L["Test"], UNLOCK),
							order = 2,
							type = "toggle",
							get = function() return module.isInTestMode end,
							set = "ToggleTestMode",
							handler = module,
						},
						resetModule = {
							name = RESET_TO_DEFAULT,
							desc = L["Reset current frame settings to default"],
							order = 3,
							type = "execute",
							func = function()
								E.profile.unitFrame = {}
								--E:Refresh()
								local currentProfile = E.DB:GetCurrentProfile()
								E.DB.keys.profile = currentProfile .. ":D" -- Bypass same profile check and force update
								E.DB:SetProfile(currentProfile)
							end,
							confirm = ConfirmAction,
						},
					},
				},
				nameplate = {
					disabled = function(info) return info[2] and not E.profile.nameplate.enabled end,
					name = L["Nameplate"],
					order = 300,
					type = "group", childGroups = "tab",
					get = function(info) local name = info[#info] return E.profile.nameplate[name] end,
					set = function(info, value) local name = info[#info] E.profile.nameplate[name] = value E:Refresh(name == "mergeAuraFrame" or name == "showCCOnly") end,
					args = {
						enabled = {
							disabled = false,
							name = L["Enable"],
							order = 1,
							type = "toggle",
						},
						test = {
							name = format("%s (%s)", L["Test"], UNLOCK or L["Unlock"]),
							order = 2,
							type = "toggle",
							get = function() return module.isInTestMode end,
							set = "ToggleTestMode",
							handler = module,
						},
						disableNPC = {
							name = L["Disable NPC"],
							desc = L["Disable auras on NPC units"],
							order = 3,
							type = "toggle",
						},
						disableMinions = {
							name = L["Disable Minions"],
							desc = L["Disable auras on player controlled pets, totems, and guardians"],
							order = 4,
							type = "toggle",
						},
						showMinionCCOnly = {
							disabled = function() return not E.profile.nameplate.enabled or E.profile.nameplate.disableMinions end,
							name = L["Only Show CC on Minions"],
							desc = L["Only show CC auras that are enabled on minion nameplates"],
							order = 5,
							type = "toggle",
						},
						HARMFUL = {
							disabled = function(info) return not E.profile.nameplate.enabled or (info[3] and not E.profile.nameplate.HARMFUL.enabled) end,
							name = L["Debuffs"],
							order = 10,
							type = "group",
							get = function(info) local name = info[#info] return E.profile.nameplate.HARMFUL[name] end,
							set = function(info, value) local name = info[#info] E.profile.nameplate.HARMFUL[name] = value E:Refresh(name == "sortby" or name == "mergedSortby" or name == "maxIcons") end,
							args = {
								enabled = {
									disabled = false,
									name = L["Enable"],
									order = 1,
									type = "toggle",
								},
								showPlayer = {
									name = L["Show Player"],
									desc = L["Show auras on player nameplate"],
									order = 2,
									type = "toggle",
								},
								showFriendly = {
									name = L["Show Friendly"],
									desc = L["Show auras on friendly nameplates (Does not work in PvE instances)"],
									order = 3,
									type = "toggle",
								},
								showTooltip = {
									name = L["Show Tooltip"],
									order = 4,
									type = "toggle",
								},
								mergeAuraFrame = {
									name = L["Merge Buff Frame"],
									desc = format("%s\n\n%s", L["Use this frame to display both buffs and debuffs."], L["Enabling this option will disable Buff Frames."]),
									order = 5,
									type = "toggle",
									get = function() return E.profile.nameplate.mergeAuraFrame end,
									set = function(_, state) E.profile.nameplate.mergeAuraFrame = state E:Refresh() end,
								},
								showCCOnly = {
									name = L["Show CC Only"],
									desc = format("%s\n\n%s", L["Only show CC auras that are enabled."], L["Enabling this option will disable Buff Frames."]),
									order = 6,
									type = "toggle",
									get = function() return E.profile.nameplate.showCCOnly end,
									set = function(_, state) E.profile.nameplate.showCCOnly = state E:Refresh() end,
								},
								redirectBlizzardDebuffs = { -- Blizzard's 'player nameplate' shows buffs, instead of debuffs
									name = L["Redirect Blizzard Debuffs"],
									desc = L["Hide Blizzard's debuff frame and redirect all debuffs displayed by Blizzard to this frame"],
									order = 7,
									type = "toggle",
								},
								hideBlizzardDebuffs = {
									disabled = function() return not E.profile.nameplate.enabled or not E.profile.nameplate.HARMFUL.enabled or E.profile.nameplate.HARMFUL.redirectBlizzardDebuffs end,
									name = L["Hide Blizzard Debuffs"],
									desc = L["Hide all debuffs displayed by Blizzard"],
									order = 8,
									type = "toggle",
								},
								anchor = {
									name = L["Position"],
									order = 10,
									type = "group", inline = true,
									args = {
										preset = {
											name = L["Presets"],
											desc = L["Debuff Frame Top Left will correctly position the icons above the name and special resources when you target a unit"],
											order = 0,
											type = "select",
											values = {
												debuffFrameLeft = L["Debuff Frame Top Left"],
												debuffFrameCenter = L["Debuff Frame Top Center"],
												healthBarLeft = L["Health Bar Left"],
												healthBarRight = L["Health Bar Right"],
--												healthBarTop = L["Health Bar Top Center"],
											},
											set = function(_, value)
												E.profile.nameplate.HARMFUL.preset = value
												if (value == "debuffFrameLeft" or value == "debuffFrameCenter") then
													E.profile.nameplate.HARMFUL.point = "BOTTOMLEFT"
													E.profile.nameplate.HARMFUL.relativeFrame = "debuffFrame"
													E.profile.nameplate.HARMFUL.relativePoint = "TOPLEFT"
												elseif (value == "healthBarLeft") then
													E.profile.nameplate.HARMFUL.point = "RIGHT"
													E.profile.nameplate.HARMFUL.relativeFrame = "healthBar"
													E.profile.nameplate.HARMFUL.relativePoint = "LEFT"
												elseif (value == "healthBarRight") then
													E.profile.nameplate.HARMFUL.point = "LEFT"
													E.profile.nameplate.HARMFUL.relativeFrame = "healthBar"
													E.profile.nameplate.HARMFUL.relativePoint = "RIGHT"
--												elseif (value == "healthBarTop") then
--													E.profile.nameplate.HARMFUL.point = "BOTTOM"
--													E.profile.nameplate.HARMFUL.relativeFrame = "healthBar"
--													E.profile.nameplate.HARMFUL.relativePoint = "TOP"
												end
												E:Refresh()
											end
										},
										offsetX = {
											name = L["Offset X"],
											order = 1,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										offsetY = {
											name = L["Offset Y"],
											order = 2,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										paddingX = {
											name = L["Padding X"],
											order = 3,
											type = "range", min = 0, max = 10, step = 1,
										},
										frameStrata = {
											name = L["Frams Strata"],
											order = 4,
											type = "select",
											values = {
												HIGH = L["HIGH"],
												MEDIUM = L["MEDIUM"],
												LOW = L["LOW"],
											},
										},
										frameLevel = {
											name = L["Frame Level"],
											order = 5,
											type = "range", min = 1, max = 9, step = 1,
										},
									}
								},
								layout = {
									name = L["Layout"],
									order = 20,
									type = "group", inline = true,
									args = {
										sortby = {
											disabled = function() return not E.profile.nameplate.enabled or not E.profile.nameplate.HARMFUL.enabled
											or E.profile.nameplate.mergeAuraFrame end,
											name = L["Sort By"],
											desc = L["Use New if your Max Number of Aura is less than 3"],
											order = 0,
											type = "select",
											values = {
												scalePrioOld = L["Scale > Priority > Old"],
												scalePrioNew = L["Scale > Priority > New"],
											},
										},
										mergedSortby = {
											disabled = function() return not E.profile.nameplate.enabled or not E.profile.nameplate.HARMFUL.enabled
											or not E.profile.nameplate.mergeAuraFrame end,
											name = L["Merged Sorting"],
											desc = L["If the Max Number of Auras is under 3 then the addon will ignore scaling and sort by higher priority and then newly added auras. This is to prevent lower priority auras with larger icon set in the aura list showing over higher priorities."],
											order = 1,
											type = "select",
											values = {
												scaleOld = L["Scale > Old"],
												scaleNew = L["Scale > New"],
												scalePrioOld = L["Scale > Priority > Old"],
												scalePrioNew = L["Scale > Priority > New"],
												scaleDebuffOld = L["Scale > Debuffs > Old"],
												scaleDebuffNew = L["Scale > Debuffs > New"],
												scaleBuffOld = L["Scale > Buffs > Old"],
												scaleBuffNew = L["Scale > Buffs > New"],
												scaleDebuffPrioOld = L["Scale > Debuffs > Priority > Old"],
												scaleDebuffPrioNew = L["Scale > Debuffs > Priority > New"],
												scaleBuffPrioOld = L["Scale > Buffs > Priority > Old"],
												scaleBuffPrioNew = L["Scale > Buffs > Priority > New"],
											},
										},
										maxIcons = {
											name = L["Max Number of Auras"],
											desc = L["Set the max number of displayed auras."],
											order = 2,
											type = "range", min = 1, max = E.NUM_NP_OVERLAYS, step = 1,
										},
									}
								},
								icon = {
									name = L["Icon"],
									order = 30,
									type = "group", inline = true,
									args = {
										scale = {
											name = L["Icon Size"],
											order = 1,
											type = "range", min = 0.5, max = 2, step = 0.01, isPercent = true,
										},
										opacity = {
											name = L["Icon Opacity"],
											order = 2,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										counterScale = {
											name = L["Counter Size"],
											order = 3,
											type = "range", min = 0.5, max = 2, step = 0.05, isPercent = true,
										},
										swipeAlpha = {
											name = L["Swipe Opacity"],
											order = 4,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										drawEdge = {
											name = L["Draw Swipe Edge"],
											order = 5,
											type = "toggle",
										},
										hideCounter = {
											name = L["Hide Counter"],
											order = 6,
											type = "toggle",
										},
									}
								},
								border = {
									name = L["Border"],
									order = 40,
									type = "group", inline = true,
									args = {
										borderType = {
											name = L["Border Type"],
											desc = L["If Merge Buff Frame is enabled, buffs will have a green border when using the Texture borders"],
											order = 1,
											type = "select",
											values = {
												pixel = L["Pixel"],
												texture = L["Texture"],
												pixelDebuff = L["Pixel - Debuff Type"],
											},
										},
										none = {
											disabled = notPixelDebuff,
											name = L["Physical"],
											order = 3,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
										Magic = {
											disabled = notPixelDebuff,
											name = L["Magic"],
											order = 4,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
										Curse = {
											disabled = notPixelDebuff,
											name = L["Curse"],
											order = 5,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
										Disease = {
											disabled = notPixelDebuff,
											name = L["Disease"],
											order = 6,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
										Poison = {
											disabled = notPixelDebuff,
											name = L["Poison"],
											order = 7,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
										buff = {
											disabled = notPixelDebuff,
											name = L["Merged Buff"],
											order = 8,
											type = "color", dialogControl = "ColorPicker-OmniCDC",
											get = getTypeColor,
											set = setTypeColor,
										},
									}
								},
								typeScale = {
									name = L["Debuff Size"],
									type = "group", inline = true,
									order = 50,
									args = {
										hardCC = {
											name = L["hardCC"],
											desc = L["Values are relative to Icon Size"],
											order = 1,
											type = "range", min = 1, max = 3, step = 0.05, isPercent = true,
											get = function() return E.profile.nameplate.HARMFUL.typeScale.hardCC end,
											set = function(_, value) E.profile.nameplate.HARMFUL.typeScale.hardCC = value E:Refresh() end,
										},
										softCC = {
											name = L["softCC"],
											desc = L["Values are relative to Icon Size"],
											order = 2,
											type = "range", min = 1, max = 3, step = 0.05, isPercent = true,
											get = function() return E.profile.nameplate.HARMFUL.typeScale.softCC end,
											set = function(_, value) E.profile.nameplate.HARMFUL.typeScale.softCC = value E:Refresh() end,
										},
										disarmRoot = {
											name = L["disarmRoot"],
											desc = L["Values are relative to Icon Size"],
											order = 3,
											type = "range", min = 1, max = 3, step = 0.05, isPercent = true,
											get = function() return E.profile.nameplate.HARMFUL.typeScale.disarmRoot end,
											set = function(_, value) E.profile.nameplate.HARMFUL.typeScale.disarmRoot = value E:Refresh() end,
										},
										largerIcon = {
											name = L["Larger Icon"],
											desc = format("%s.\n\n%s", L["Values are relative to Icon Size"], L["|cffff2020Only applies to auras that have Larger Icon enabled in the Auras tab"]),
											order = 4,
											type = "range", min = 1, max = 1.5, step = 0.05, isPercent = true,
										},
										blizzardDebuffs = {
											disabled = function() return not E.profile.nameplate.enabled or not E.profile.nameplate.HARMFUL.enabled
											or not E.profile.nameplate.HARMFUL.redirectBlizzardDebuffs end,
											name = L["Blizzard Debuffs"],
											desc = L["Values are relative to Icon Size"],
											order = 5,
											type = "range", min = 0.5, max = 1, step = 0.01, isPercent = true,
										},
									}
								},
								glow = glow,
							}
						},
						HELPFUL = {
							disabled = function(info) return not E.profile.nameplate.enabled or E.profile.nameplate.mergeAuraFrame
							or E.profile.nameplate.showCCOnly
							or (info[3] and not E.profile.nameplate.HELPFUL.enabled) end,
							name = L["Buffs"],
							order = 20,
							type = "group",
							get = function(info) local name = info[#info] return E.profile.nameplate.HELPFUL[name] end,
							set = function(info, value) local name = info[#info] E.profile.nameplate.HELPFUL[name] = value E:Refresh(name == "sortby") end,
							args = {
								enabled = {
									disabled = false,
									name = L["Enable"],
									order = 1,
									type = "toggle",
								},
								showPlayer = {
									name = L["Show Player"],
									desc = L["Show auras on player nameplate"],
									order = 2,
									type = "toggle",
								},
								showFriendly = {
									name = L["Show Friendly"],
									desc = L["Show auras on friendly nameplates (Does not work in PvE instances)"],
									order = 3,
									type = "toggle",
								},
								showTooltip = {
									name = L["Show Tooltip"],
									order = 4,
									type = "toggle",
								},
								anchor = {
									name = L["Position"],
									order = 10,
									type = "group", inline = true,
									args = {
										preset = {
											name = L["Presets"],
											desc = L["Debuff Frame Top Left will correctly position the icons above the name and special resources when you target a unit"],
											order = 0,
											type = "select",
											values = {
												debuffFrameLeft = L["Debuff Frame Top Left"],
												debuffFrameCenter = L["Debuff Frame Top Center"],
												healthBarLeft = L["Health Bar Left"],
												healthBarRight = L["Health Bar Right"],
--												healthBarTop = L["Health Bar Top Center"],
											},
											set = function(_, value)
												E.profile.nameplate.HELPFUL.preset = value
												if (value == "debuffFrameLeft" or value == "debuffFrameCenter") then
													E.profile.nameplate.HELPFUL.point = "BOTTOMLEFT"
													E.profile.nameplate.HELPFUL.relativeFrame = "debuffFrame"
													E.profile.nameplate.HELPFUL.relativePoint = "TOPLEFT"
												elseif (value == "healthBarLeft") then
													E.profile.nameplate.HELPFUL.point = "RIGHT"
													E.profile.nameplate.HELPFUL.relativeFrame = "healthBar"
													E.profile.nameplate.HELPFUL.relativePoint = "LEFT"
												elseif (value == "healthBarRight") then
													E.profile.nameplate.HELPFUL.point = "LEFT"
													E.profile.nameplate.HELPFUL.relativeFrame = "healthBar"
													E.profile.nameplate.HELPFUL.relativePoint = "RIGHT"
--												elseif (value == "healthBarTop") then
--													E.profile.nameplate.HELPFUL.point = "BOTTOM"
--													E.profile.nameplate.HELPFUL.relativeFrame = "healthBar"
--													E.profile.nameplate.HELPFUL.relativePoint = "TOP"
												end
												E:Refresh()
											end
										},
										offsetX = {
											name = L["Offset X"],
											order = 1,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										offsetY = {
											name = L["Offset Y"],
											order = 2,
											type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
										},
										paddingX = {
											name = L["Padding X"],
											order = 3,
											type = "range", min = 0, max = 10, step = 1,
										},
										frameStrata = {
											name = L["Frams Strata"],
											order = 4,
											type = "select",
											values = {
												HIGH = L["HIGH"],
												MEDIUM = L["MEDIUM"],
												LOW = L["LOW"],
											},
										},
										frameLevel = {
											name = L["Frame Level"],
											order = 5,
											type = "range", min = 1, max = 9, step = 1,
										},
									}
								},
								layout = {
									name = L["Layout"],
									order = 20,
									type = "group", inline = true,
									args = {
										sortby = {
											name = L["Sort By"],
											desc = L["Use New if your Max Number of Aura is less than 3"],
											order = 0,
											type = "select",
											values = {
												scalePrioOld = L["Scale > Priority > Old"],
												scalePrioNew = L["Scale > Priority > New"],
											},
										},
										maxIcons = {
											name = L["Max Number of Auras"],
											desc = L["Set the max number of displayed auras."],
											order = 1,
											type = "range", min = 1, max = E.NUM_NP_OVERLAYS, step = 1,
										},
										largerIcon = {
											name = L["Larger Icon"],
											desc = format("%s.\n\n%s", L["Values are relative to Icon Size"], L["|cffff2020Only applies to auras that have Larger Icon enabled in the Auras tab"]),
											order = 2,
											type = "range", min = 1, max = 1.5, step = 0.05, isPercent = true,
										},
									}
								},
								icon = {
									name = L["Icon"],
									order = 30,
									type = "group", inline = true,
									args = {
										scale = {
											name = L["Icon Size"],
											order = 1,
											type = "range", min = 0.5, max = 2, step = 0.01, isPercent = true,
										},
										opacity = {
											name = L["Icon Opacity"],
											order = 2,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										counterScale = {
											name = L["Counter Size"],
											order = 3,
											type = "range", min = 0.5, max = 2, step = 0.05, isPercent = true,
										},
										swipeAlpha = {
											name = L["Swipe Opacity"],
											order = 4,
											type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
										},
										drawEdge = {
											name = L["Draw Swipe Edge"],
											order = 5,
											type = "toggle",
										},
										hideCounter = {
											name = L["Hide Counter"],
											order = 6,
											type = "toggle",
										},
									}
								},
								border = {
									name = L["Border"],
									order = 40,
									type = "group", inline = true,
									args = {
										borderType = {
											name = L["Border Type"],
											type = "select",
											values = {
												pixel = L["Pixel"],
												texture = L["Texture"],
											},
										},
									}
								},
								glow = glow,
							}
						},
						visibility = {
							name = L["Visibility"],
							order = 30,
							type = "group",
							get = function(_, k) return E.profile.nameplate.visibility[k] end,
							set = function(_, k, value) E.profile.nameplate.visibility[k] = value E:Refresh() end,
							args = visibility,
						},
						priority = {
							name = L["Priority"],
							order = 90,
							type = "group",
							get = function(info) local option = info[#info] return E.profile.nameplate.priority[option] end,
							set = function(info, value) local option = info[#info] E.profile.nameplate.priority[option] = value E:Refresh() end,
							args = priority,
						},
					}
				},
			}
		}
		-- end of E.options

		--
		-- UF unittypes
		--
		local UNITFRAME_UNITTYPE = {
			"player", "pet", "target", "focus", "party", --"arena",
		}

		for order, v in ipairs(UNITFRAME_UNITTYPE) do
			E.options.args.unitFrame.args[v] = {
				disabled = function(info) return not E.profile.unitFrame.enabled or (info[3] and not E.profile.unitFrame[v].enabled) end,
				name = L[v],
				order = order,
				type = "group", childGroups = "tab",
				get = function(info) local name = info[#info] return E.profile.unitFrame[v][name] end,
				set = function(info, value) local name = info[#info] E.profile.unitFrame[v][name] = value E:Refresh() end,
				args = {
					enabled = {
						disabled = false,
						name = L["Enable"],
						order = 1,
						type = "toggle",
					},
					test = {
						name = format("%s (%s)", L["Test"], UNLOCK),
						order = 2,
						type = "toggle",
						get = function() return module.isInTestMode end,
						set = "ToggleTestMode",
						handler = module,
					},
					HARMFUL = {
						disabled = function(info) return not E.profile.unitFrame[v].enabled or (info[4] and not E.profile.unitFrame[v].HARMFUL.enabled) end,
						name = L["Debuffs"],
						order = 10,
						type = "group",
						get = function(info) local name = info[#info] return E.profile.unitFrame[v].HARMFUL[name] end,
						set = function(info, value) local name = info[#info] E.profile.unitFrame[v].HARMFUL[name] = value E:Refresh() end,
						args = {
							enabled = {
								disabled = false,
								name = L["Enable"],
								order = 1,
								type = "toggle",
							},
							mergeAuraFrame = {
								name = L["Merge Buff Frame"],
								desc = format("%s\n\n%s", L["Use this frame to display both buffs and debuffs."], L["Enabling this option will disable Buff Frames."]),
								order = 2,
								type = "toggle",
								get = function() return E.profile.unitFrame[v].mergeAuraFrame end,
								set = function(_, state) E.profile.unitFrame[v].mergeAuraFrame = state E:Refresh() end,
							},
							showCCOnly = {
								name = L["Show CC Only"],
								desc = format("%s\n\n%s", L["Only show CC auras that are enabled."], L["Enabling this option will disable Buff Frames."]),
								order = 3,
								type = "toggle",
								get = function() return E.profile.unitFrame[v].showCCOnly end,
								set = function(_, state) E.profile.unitFrame[v].showCCOnly = state E:Refresh() end,
							},
							anchor = {
								name = L["Position"],
								order = 10,
								type = "group", inline = true,
								args = {
									preset = {
										name = L["Presets"],
										order = 0,
										type = "select",
										values = {
											["AUTO"] = L["AUTO"],
											["PORTRAIT"] = L["PORTRAIT"],
											["MANUAL"] = L["MANUAL"],
										},
									},
									point = {
										disabled = notAuto,
										name = L["Point"],
										order = 1,
										type = "select",
										values = {
											["BOTTOMLEFT"] = L["BOTTOMLEFT"],
											["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
											["LEFT"] = L["LEFT"],
											["RIGHT"] = L["RIGHT"],
											["TOPLEFT"] = L["TOPLEFT"],
											["TOPRIGHT"] = L["TOPRIGHT"],
										},
									},
									relativeFrame = {
										disabled = notAuto,
										name = L["Relative Frame"],
										order = 2,
										type = "select",
										values = {
											unitFrame = L["Unit Frame"],
										},
									},
									relativePoint = {
										disabled = notAuto,
										name = L["Relative Point"],
										order = 3,
										type = "select",
										values = {
											["BOTTOMLEFT"] = L["BOTTOMLEFT"],
											["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
											["LEFT"] = L["LEFT"],
											["RIGHT"] = L["RIGHT"],
											["TOPLEFT"] = L["TOPLEFT"],
											["TOPRIGHT"] = L["TOPRIGHT"],
										},
									},
									offsetX = {
										disabled = notAuto,
										name = L["Offset X"],
										order = 4,
										type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
									},
									offsetY = {
										disabled = notAuto,
										name = L["Offset Y"],
										order = 5,
										type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
									},
								}
							},
							layout = {
								name = L["Layout"],
								order = 20,
								type = "group", inline = true,
								args = {
									-- NOTE: use sorting method without scale for UF as it doesn't process scaling
									sortby = {
										name = L["Sort By"],
										order = 4,
										type = "select",
										values = {
											prioNew = L["Priority > New"],
										},
									},
								}
							},
							icon = {
								name = L["Icon"],
								order = 30,
								type = "group", inline = true,
								args = {
									scale = {
										disabled = isPortrait,
										name = L["Icon Size"],
										order = 11,
										type = "range", min = 0.5, softMax = 1.5, max = 3, step = 0.01, isPercent = true,
									},
									opacity = {
										disabled = isPortrait,
										name = L["Icon Opacity"],
										order = 12,
										type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
									},
									counterScale = {
										name = L["Counter Size"],
										order = 13,
										type = "range", min = 0.5, max = 1, step = 0.05, isPercent = true,
									},
									swipeAlpha = {
										name = L["Swipe Opacity"],
										order = 14,
										type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
									},
									drawEdge = {
										name = L["Draw Swipe Edge"],
										order = 15,
										type = "toggle",
									},
									hideCounter = {
										name = L["Hide Counter"],
										order = 16,
										type = "toggle",
									},
								}
							},
							border = {
								disabled = isPortrait,
								name = L["Border"],
								order = 40,
								type = "group", inline = true,
								args = {
									borderType = {
										name = L["Border Type"],
										order = 0,
										type = "select",
										values = {
											pixel = L["Pixel"],
											texture = L["Texture"],
										}
									},
									borderColor = {
										disabled = notPixelOrIsPortrait,
										name = L["Default"],
										order = 1,
										type = "color", dialogControl = "ColorPicker-OmniCDC",
										get = getColor,
										set = setColor,
									},
								}
							},
							glow = {
								name = L["Glow"],
								order = 60,
								type = "group", inline = true,
								args = {
									glow = {
										name = L["Enable"],
										desc = format("%s\n\n%s", L["Display a glow animation around an icon when a new aura is shown"],
										L["|cffff2020Only applies to auras that have Glow enabled in the Auras tab"]),
										order = 1,
										type = "toggle",
									},
									alwaysGlowCC = {
										disabled = function() return not E.profile.unitFrame[v].HARMFUL.enabled or not E.profile.unitFrame[v].HARMFUL.glow end,
										name = L["Always Glow CC"],
										desc = L["Always glow crowd control, silence, and interrupt effects regardless of the individual aura's glow setting"],
										order = 2,
										type = "toggle",
									},
								}
							},
						}
					},
					HELPFUL = {
						disabled = function(info) return not E.profile.unitFrame[v].enabled or E.profile.unitFrame[v].mergeAuraFrame
						or E.profile.unitFrame[v].showCCOnly
						or (info[4] and not E.profile.unitFrame[v].HELPFUL.enabled) end,
						name = L["Buffs"],
						order = 20,
						type = "group",
						get = function(info) local name = info[#info] return E.profile.unitFrame[v].HELPFUL[name] end,
						set = function(info, value) local name = info[#info] E.profile.unitFrame[v].HELPFUL[name] = value E:Refresh() end,
						args = {
							enabled = {
								disabled = false,
								name = L["Enable"],
								order = 1,
								type = "toggle",
							},
							anchor = {
								name = L["Position"],
								order = 10,
								type = "group", inline = true,
								args = {
									preset = {
										name = L["Presets"],
										order = 0,
										type = "select",
										values = {
											["AUTO"] = L["AUTO"],
											["PORTRAIT"] = L["PORTRAIT"],
											["MANUAL"] = L["MANUAL"],
										},
									},
									point = {
										disabled = notAuto,
										name = L["Point"],
										order = 1,
										type = "select",
										values = {
											["BOTTOMLEFT"] = L["BOTTOMLEFT"],
											["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
											["LEFT"] = L["LEFT"],
											["RIGHT"] = L["RIGHT"],
											["TOPLEFT"] = L["TOPLEFT"],
											["TOPRIGHT"] = L["TOPRIGHT"],
										},
									},
									relativeFrame = {
										disabled = notAuto,
										name = L["Relative Frame"],
										order = 2,
										type = "select",
										values = {
											unitFrame = L["Unit Frame"],
										},
									},
									relativePoint = {
										disabled = notAuto,
										name = L["Relative Point"],
										order = 3,
										type = "select",
										values = {
											["BOTTOMLEFT"] = L["BOTTOMLEFT"],
											["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
											["LEFT"] = L["LEFT"],
											["RIGHT"] = L["RIGHT"],
											["TOPLEFT"] = L["TOPLEFT"],
											["TOPRIGHT"] = L["TOPRIGHT"],
										},
									},
									offsetX = {
										disabled = notAuto,
										name = L["Offset X"],
										order = 4,
										type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
									},
									offsetY = {
										disabled = notAuto,
										name = L["Offset Y"],
										order = 5,
										type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
									},
								}
							},
							layout = {
								name = L["Layout"],
								order = 20,
								type = "group", inline = true,
								args = {
									-- NOTE: use sorting method without scale for UF as it doesn't process scaling
									sortby = {
										name = L["Sort By"],
										order = 4,
										type = "select",
										values = {
											prioNew = L["Priority > New"],
										},
									},
								}
							},
							icon = {
								name = L["Icon"],
								order = 30,
								type = "group", inline = true,
								args = {
									scale = {
										disabled = isPortrait,
										name = L["Icon Size"],
										order = 11,
										type = "range", min = 0.5, max = 1.5, step = 0.01, isPercent = true,
									},
									opacity = {
										disabled = isPortrait,
										name = L["Icon Opacity"],
										order = 12,
										type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
									},
									counterScale = {
										name = L["Counter Size"],
										order = 13,
										type = "range", min = 0.5, max = 1, step = 0.05, isPercent = true,
									},
									swipeAlpha = {
										name = L["Swipe Opacity"],
										order = 14,
										type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
									},
									drawEdge = {
										name = L["Draw Swipe Edge"],
										order = 15,
										type = "toggle",
									},
									hideCounter = {
										name = L["Hide Counter"],
										order = 16,
										type = "toggle",
									},
								}
							},
							border = {
								disabled = isPortrait,
								name = L["Border"],
								order = 40,
								type = "group", inline = true,
								args = {
									borderType = {
										name = L["Border Type"],
										order = 0,
										type = "select",
										values = {
											pixel = L["Pixel"],
											texture = L["Texture"],
										}
									},
									borderColor = {
										disabled = notPixelOrIsPortrait,
										name = L["Default"],
										order = 1,
										type = "color", dialogControl = "ColorPicker-OmniCDC",
										get = getColor,
										set = setColor,
									},
								}
							},
							glow = glow,
						}
					},
					visibility = {
						name = L["Visibility"],
						order = 30,
						type = "group",
						get = function(_, k) return E.profile.unitFrame[v].visibility[k] end,
						set = function(_, k, value) E.profile.unitFrame[v].visibility[k] = value E:Refresh() end,
						args = v == "party" and {
							zone = {
								name = L["Zone"],
								type = "multiselect",
								values = {
									["arena"] = ARENA,
									["party"] = DUNGEONS,
									["scenario"] = SCENARIOS,
									["none"] = BUG_CATEGORY2,
								},
								width = "full",
							}
						} or visibility,
					},
					priority = {
						name = L["Priority"],
						order = 90,
						type = "group",
						get = function(info) local option = info[#info] return E.profile.unitFrame[v].priority[option] end,
						set = function(info, value) local option = info[#info] E.profile.unitFrame[v].priority[option] = value E:Refresh() end,
						args = priority,
					},
				}
			}
		end

		-- CompactArenaFrame
		E.options.args.unitFrame.args.arena = {
			disabled = function(info) return not E.profile.unitFrame.enabled or (info[3] and not E.profile.unitFrame.arena.enabled) end,
			name = L["Arena"],
			type = "group", childGroups = "tab",
			get = function(info) local name = info[#info] return E.profile.unitFrame.arena[name] end,
			set = function(info, value) local name = info[#info] E.profile.unitFrame.arena[name] = value E:Refresh() end,
			args = {
				enabled = {
					disabled = false,
					name = L["Enable"],
					order = 1,
					type = "toggle",
				},
				test = {
					name = format("%s (%s)", L["Test"], UNLOCK),
					order = 2,
					type = "toggle",
					get = function() return module.isInTestMode end,
					set = "ToggleTestMode",
					handler = module,
				},
				globalScale = {
					name = L["Global Scale"],
					desc = format("%s\n\n15: %s", L["Set the global scale of arena frame auras"], DEFAULT),
					order = 3,
					type = "range", min = 15, max = 22, step = 1,
				},
				HARMFUL = {
					disabled = function(info) return not E.profile.unitFrame.arena.enabled or (info[4] and not E.profile.unitFrame.arena.HARMFUL.enabled) end,
					name = L["Debuffs"],
					order = 10,
					type = "group",
					get = function(info) local name = info[#info] return E.profile.unitFrame.arena.HARMFUL[name] end,
					set = function(info, value) local name = info[#info] E.profile.unitFrame.arena.HARMFUL[name] = value E:Refresh() end,
					args = {
						enabled = {
							disabled = false,
							name = L["Enable"],
							order = 1,
							type = "toggle",
						},
						showTooltip = {
							name = L["Show Tooltip"],
							order = 2,
							type = "toggle",
						},
						mergeAuraFrame = {
							name = L["Merge Buff Frame"],
							desc = format("%s\n\n%s", L["Use this frame to display both buffs and debuffs."], L["Enabling this option will disable Buff Frames."]),
							order = 3,
							type = "toggle",
							get = function() return E.profile.unitFrame.arena.mergeAuraFrame end,
							set = function(_, state) E.profile.unitFrame.arena.mergeAuraFrame = state E:Refresh() end,
						},
						redirectBlizzardDebuffs = {
							name = L["Redirect Blizzard Debuffs"],
							desc = L["Hide Blizzard's debuff frame and redirect all debuffs displayed by Blizzard to this frame"],
							order = 4,
							type = "toggle",
						},
						anchor = {
							name = L["Position"],
							order = 10,
							type = "group", inline = true,
							args = {
								preset = {
									name = L["Presets"],
									order = 0,
									type = "select",
									values = {
										["AUTO"] = L["AUTO"],
										["overDebuffs"] = L["Blizzard Default Location"],
									},
									set = function(_, value)
										E.profile.unitFrame.arena.HARMFUL.preset = value
										if (value == "overDebuffs") then
											E.profile.unitFrame.arena.HARMFUL.point = "BOTTOMLEFT"
											E.profile.unitFrame.arena.HARMFUL.relativeFrame = "Debuff1"
											E.profile.unitFrame.arena.HARMFUL.relativePoint = "BOTTOMLEFT"
										end
										E:Refresh()
									end
								},
								point = {
									disabled = notAuto,
									name = L["Point"],
									order = 1,
									type = "select",
									values = {
										["BOTTOMLEFT"] = L["BOTTOMLEFT"],
										["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
										["LEFT"] = L["LEFT"],
										["RIGHT"] = L["RIGHT"],
										["TOPLEFT"] = L["TOPLEFT"],
										["TOPRIGHT"] = L["TOPRIGHT"],
										["CENTER"] = L["CENTER"],
									},
								},
								relativeFrame = {
									disabled = notAuto,
									name = L["Relative Frame"],
									order = 2,
									type = "select",
									values = {
										["CastingBarFrame"] = L["CASTBAR"],
										["castBarIcon"] = L["CASTBAR-ICON"],
										["Debuff1"] = L["Inner Debuff Frame"], -- frame.Debuff1 = frame.debuffFrames[1]
										["DebuffFrame"] = L["Debuff Frame"],
										["CcRemoverFrame"] = L["TRINKET"],
										["arenaFrame"] = L["Arena Frame"],
									},
								},
								relativePoint = {
									disabled = notAuto,
									name = L["Relative Point"],
									order = 3,
									type = "select",
									values = {
										["BOTTOMLEFT"] = L["BOTTOMLEFT"],
										["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
										["LEFT"] = L["LEFT"],
										["RIGHT"] = L["RIGHT"],
										["TOPLEFT"] = L["TOPLEFT"],
										["TOPRIGHT"] = L["TOPRIGHT"],
									},
								},
								offsetX = {
									disabled = notAuto,
									name = L["Offset X"],
									order = 4,
									type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
								},
								offsetY = {
									disabled = notAuto,
									name = L["Offset Y"],
									order = 5,
									type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
								},
								frameLevel = {
									disabled = notArenaFrameOverDebuffs,
									name = L["Frame Level"],
									desc = L["-1: Show below Blizzard's buff/debuff icons (Tooltips will no longer work)"],
									order = 6,
									type = "range", min = -1, max = 9, step = 2,
								},
							}
						},
						layout = {
							name = L["Layout"],
							order = 20,
							type = "group", inline = true,
							args = {
								sortby = {
									name = L["Sort By"],
									order = 1,
									type = "select",
									values = {
										scalePrioNew = L["Scale > Priority > New"],
										scalePrioOld = L["Scale > Priority > Old"],
									},
								},
								maxIcons = {
									name = L["Max Number of Auras"],
									desc = L["Set the max number of displayed auras."],
									order = 2,
									type = "range", min = 1, max = E.NUM_AF_OVERLAYS.HARMFUL, step = 1,
								},
							}
						},
						icon = {
							name = L["Icon"],
							order = 30,
							type = "group", inline = true,
							args = {
								scale = {
									disabled = isArenaFrameOverDebuffs,
									name = L["Icon Size"],
									order = 1,
									type = "range", min = 1, max = 2, step = 0.01, isPercent = true,
								},
								opacity = {
									name = L["Icon Opacity"],
									order = 2,
									type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
								},
								counterScale = {
									name = L["Counter Size"],
									order = 3,
									type = "range", min = 0.5, max = 1, step = 0.05, isPercent = true,
								},
								swipeAlpha = {
									name = L["Swipe Opacity"],
									order = 4,
									type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
								},
								hideCounter = {
									name = L["Hide Counter"],
									order = 5,
									type = "toggle",
								},
								hideNonCCCounter = {
									disabled = function() return not E.profile.unitFrame.arena.enabled or not E.profile.unitFrame.arena.HARMFUL.enabled
									or E.profile.unitFrame.arena.HARMFUL.hideCounter end,
									name = L["Hide Counter on Base Size Icons"],
									order = 6,
									type = "toggle",
								},
							}
						},
						border = {
							name = L["Border"],
							order = 40,
							type = "group", inline = true,
							args = {
								borderType = {
									name = L["Border Type"],
									order = 0,
									type = "select",
									values = {
										pixel = L["Pixel"],
										pixelDebuff = L["Pixel - Debuff Type"],
										blizzard = L["Blizzard"],
									}
								},
								borderColor = {
									disabled = notPixelOrIsPortrait,
									name = L["Default"],
									order = 1,
									type = "color", dialogControl = "ColorPicker-OmniCDC",
									get = getColor,
									set = setColor,
								},
								none = {
									disabled = notPixelDebuff,
									name = L["Physical"],
									order = 3,
									type = "color", dialogControl = "ColorPicker-OmniCDC",
									get = getTypeColor,
									set = setTypeColor,
								},
								Magic = {
									disabled = notPixelDebuff,
									name = L["Magic"],
									order = 4,
									type = "color", dialogControl = "ColorPicker-OmniCDC",
									get = getTypeColor,
									set = setTypeColor,
								},
								Curse = {
									disabled = notPixelDebuff,
									name = L["Curse"],
									order = 5,
									type = "color", dialogControl = "ColorPicker-OmniCDC",
									get = getTypeColor,
									set = setTypeColor,
								},
								Disease = {
									disabled = notPixelDebuff,
									name = L["Disease"],
									order = 6,
									type = "color", dialogControl = "ColorPicker-OmniCDC",
									get = getTypeColor,
									set = setTypeColor,
								},
								Poison = {
									disabled = notPixelDebuff,
									name = L["Poison"],
									order = 7,
									type = "color", dialogControl = "ColorPicker-OmniCDC",
									get = getTypeColor,
									set = setTypeColor,
								},
							}
						},
						typeScale = {
							name = L["Debuff Size"],
							type = "group", inline = true,
							order = 50,
							args = {
								hardCC = {
									name = L["hardCC"],
									desc = format("%s.\n\n%s", L["Values are relative to Icon Size"],
									L["Max icon height will auto-adjust so that it doesn't exceed the raid frame's height"]),
									order = 1,
									type = "range", min = 1, max = 3, step = 0.05, isPercent = true,
									get = function() return E.profile.unitFrame.arena.HARMFUL.typeScale.hardCC end,
									set = function(_, value) E.profile.unitFrame.arena.HARMFUL.typeScale.hardCC = value E:Refresh() end,
								},
								softCC = {
									name = L["softCC"],
									desc = format("%s.\n\n%s", L["Values are relative to Icon Size"],
									L["Max icon height will auto-adjust so that it doesn't exceed the raid frame's height"]),
									order = 2,
									type = "range", min = 1, max = 3, step = 0.05, isPercent = true,
									get = function() return E.profile.unitFrame.arena.HARMFUL.typeScale.softCC end,
									set = function(_, value) E.profile.unitFrame.arena.HARMFUL.typeScale.softCC = value E:Refresh() end,
								},
								disarmRoot = {
									name = L["disarmRoot"],
									desc = format("%s.\n\n%s", L["Values are relative to Icon Size"],
									L["Max icon height will auto-adjust so that it doesn't exceed the raid frame's height"]),
									order = 3,
									type = "range", min = 1, max = 3, step = 0.05, isPercent = true,
									get = function() return E.profile.unitFrame.arena.HARMFUL.typeScale.disarmRoot end,
									set = function(_, value) E.profile.unitFrame.arena.HARMFUL.typeScale.disarmRoot = value E:Refresh() end,
								},
								largerIcon = {
									name = L["Larger Icon"],
									desc = format("%s.\n\n%s", L["Values are relative to Icon Size"], L["|cffff2020Only applies to auras that have Larger Icon enabled in the Auras tab"]),
									order = 4,
									type = "range", min = 1, max = 1.5, step = 0.05, isPercent = true,
								},
							}
						},
						glow = {
							name = L["Glow"],
							order = 60,
							type = "group", inline = true,
							args = {
								glow = {
									name = L["Enable"],
									desc = format("%s\n\n%s", L["Display a glow animation around an icon when a new aura is shown"],
									L["|cffff2020Only applies to auras that have Glow enabled in the Auras tab"]),
									order = 1,
									type = "toggle",
								},
								alwaysGlowCC = {
									disabled = function() return not E.profile.unitFrame.arena.HARMFUL.enabled or not E.profile.unitFrame.arena.HARMFUL.glow end,
									name = L["Always Glow CC"],
									desc = L["Always glow crowd control, silence, and interrupt effects regardless of the individual aura's glow setting"],
									order = 2,
									type = "toggle",
								},
							}
						},
					}
				},
				HELPFUL = {
					disabled = function(info) return not E.profile.unitFrame.arena.enabled or E.profile.unitFrame.arena.mergeAuraFrame
					or (info[4] and not E.profile.unitFrame.arena.HELPFUL.enabled) end,
					name = L["Buffs"],
					order = 20,
					type = "group",
					get = function(info) local name = info[#info] return E.profile.unitFrame.arena.HELPFUL[name] end,
					set = function(info, value) local name = info[#info] E.profile.unitFrame.arena.HELPFUL[name] = value E:Refresh() end,
					args = {
						enabled = {
							disabled = false,
							name = L["Enable"],
							order = 1,
							type = "toggle",
						},
						showTooltip = {
							name = L["Show Tooltip"],
							order = 3,
							type = "toggle",
						},
						anchor = {
							name = L["Position"],
							order = 10,
							type = "group", inline = true,
							args = {
								preset = {
									name = L["Presets"],
									order = 0,
									type = "select",
									values = {
										["AUTO"] = L["AUTO"],
										["raidFrameCenter"] = L["Arena Frame Center"],
									},
									set = function(_, value)
										E.profile.unitFrame.arena.HELPFUL.preset = value
										if (value == "raidFrameCenter") then
											E.profile.unitFrame.arena.HELPFUL.point = "CENTER"
											E.profile.unitFrame.arena.HELPFUL.relativeFrame = "arenaFrame"
											E.profile.unitFrame.arena.HELPFUL.relativePoint = "CENTER"
										end
										E:Refresh()
									end
								},
								point = {
									disabled = notAuto,
									name = L["Point"],
									order = 1,
									type = "select",
									values = {
										["BOTTOMLEFT"] = L["BOTTOMLEFT"],
										["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
										["LEFT"] = L["LEFT"],
										["RIGHT"] = L["RIGHT"],
										["TOPLEFT"] = L["TOPLEFT"],
										["TOPRIGHT"] = L["TOPRIGHT"],
										["CENTER"] = L["CENTER"],
									},
								},
								relativeFrame = {
									disabled = notAuto,
									name = L["Relative Frame"],
									order = 2,
									type = "select",
									values = {
										["CastingBarFrame"] = L["CASTBAR"],
										["castBarIcon"] = L["CASTBAR-ICON"],
										--["CompactArenaFrameMember1Buff1"] = L["Buff Frame"], -- key = CompactArenaFrameMember1.buffFrames[1]:GetName()
										["CcRemoverFrame"] = L["TRINKET"],
										["arenaFrame"] = L["Arena Frame"],
									},
								},
								relativePoint = {
									disabled = notAuto,
									name = L["Relative Point"],
									order = 3,
									type = "select",
									values = {
										["BOTTOMLEFT"] = L["BOTTOMLEFT"],
										["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
										["LEFT"] = L["LEFT"],
										["RIGHT"] = L["RIGHT"],
										["TOPLEFT"] = L["TOPLEFT"],
										["TOPRIGHT"] = L["TOPRIGHT"],
										["CENTER"] = L["CENTER"],
									},
								},
								offsetX = {
									name = L["Offset X"],
									order = 4,
									type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
								},
								offsetY = {
									name = L["Offset Y"],
									order = 5,
									type = "range", softMin = -100, softMax = 100, min = -999, max = 999, step = 1,
								},
								frameLevel = {
									name = L["Frame Level"],
									desc = L["-1: Show below Blizzard's buff/debuff icons (Tooltips will no longer work)"],
									order = 6,
									type = "range", min = -1, max = 9, step = 2,
								},
							}
						},
						layout = {
							name = L["Layout"],
							order = 20,
							type = "group", inline = true,
							args = {
								sortby = {
									name = L["Sort By"],
									desc = L["Use New if your Max Number of Aura is less than 3"],
									order = 0,
									type = "select",
									values = {
										prioOld = L["Priority > Old"],
										prioNew = L["Priority > New"],
									},
								},
								maxIcons = {
									name = L["Max Number of Auras"],
									desc = L["Set the max number of displayed auras."],
									order = 1,
									type = "range", min = 1, max = E.NUM_AF_OVERLAYS.HELPFUL, step = 1,
								},
							}
						},
						icon = {
							name = L["Icon"],
							order = 30,
							type = "group", inline = true,
							args = {
								scale = {
									disabled = isArenaFrameOverDebuffs,
									name = L["Icon Size"],
									order = 1,
									type = "range", min = 1, max = 2, step = 0.01, isPercent = true,
								},
								opacity = {
									name = L["Icon Opacity"],
									order = 2,
									type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
								},
								counterScale = {
									name = L["Counter Size"],
									order = 3,
									type = "range", min = 0.5, max = 1, step = 0.05, isPercent = true,
								},
								swipeAlpha = {
									name = L["Swipe Opacity"],
									order = 4,
									type = "range", min = 0, max = 1, step = 0.05, isPercent = true,
								},
								hideCounter = {
									name = L["Hide Counter"],
									order = 5,
									type = "toggle",
								},
							}
						},
						border = {
							name = L["Border"],
							order = 40,
							type = "group", inline = true,
							args = {
								borderType = {
									name = L["Border Type"],
									order = 0,
									type = "select",
									values = {
										pixel = L["Pixel"],
									}
								},
							}
						},
						glow = glow,
					}
				},
				ccFrame = {
					name = L["Cc Frame"],
					order = 25,
					type = "group",
					get = function(info) return E.profile.unitFrame.arena.ccFrame[ info[#info] ] end,
					set = function(info, state) E.profile.unitFrame.arena.ccFrame[ info[#info] ] = state E:Refresh() end,
					args = {
						hideCc = {
							name = L["Hide Blizzard CC Frame"],
							type = "toggle",
						},
						--[[
						hideCcRemover = {
							name = L["Hide CC Remover Frame"],
							type = "toggle",
						},
						]]
					}
				},
				visibility = {
					name = L["Visibility"],
					order = 30,
					type = "group",
					get = function(_, k) return E.profile.unitFrame.arena.visibility[k] end,
					set = function(_, k, value) E.profile.unitFrame.arena.visibility[k] = value E:Refresh() end,
					args = {
						zone = {
							name = L["Zone"],
							type = "multiselect",
							values = {
								["arena"] = ARENA,
							},
							width = "full",
						}
					}
				},
				priority = {
					name = L["Priority"],
					order = 90,
					type = "group",
					get = function(info) local option = info[#info] return E.profile.unitFrame.arena.priority[option] end,
					set = function(info, value) local option = info[#info] E.profile.unitFrame.arena.priority[option] = value E:Refresh() end,
					args = priority,
				},
			}
		}

		--
		-- Home labels
		--
		for i = 1, #labels do
			local label = labels[i]
			if (i > 4) then
				E.options.args.Home.args.slashCommands.args[label] = {
					name = label,
					order = i,
					type = "input", dialogControl = "Info-OmniCDC",
				}
			else
				E.options.args.Home.args[label] = {
					name = L[label] or label,
					order = i,
					type = "input", dialogControl = "Info-OmniCDC",
					get = getField,
				}
			end
		end

		E:AddGeneral()
		E:AddSpellEditor()
		E:AddAuraBlacklist()
		E:AddAuraAlert()
		E:AddProfileSharing()

		for modname, optionTbl in pairs(E.moduleOptions) do
			E.options.args[modname] = (type(optionTbl) == "function") and optionTbl() or optionTbl
		end
	end

	return E.options
end

function E:SetupOptions()
	self.Libs.OmniCDC.texture = self.Libs.OmniCDC.texture or {
		logo	= [[Interface\AddOns\OmniAuras\Libs\LibOmniCDC\Media\omnicd-logo64]],
		recent	= [[Interface\AddOns\OmniAuras\Libs\LibOmniCDC\Media\omnicd-recent]],
		resizer	= [[Interface\AddOns\OmniAuras\Libs\LibOmniCDC\Media\omnicd-bullet-resizer]],
		plus	= [[Interface\AddOns\OmniAuras\Libs\LibOmniCDC\Media\omnicd-bg-gnav2-plus]],
		minus	= [[Interface\AddOns\OmniAuras\Libs\LibOmniCDC\Media\omnicd-bg-gnav2-minus]],
		arrow	= [[Interface\AddOns\OmniAuras\Libs\LibOmniCDC\Media\omnicd-bg-gnav2-dn]],
		arrowb	= [[Interface\AddOns\OmniAuras\Libs\LibOmniCDC\Media\omnicd-bg-gnav2-dn-b]],
	}
	self.Libs.OmniCDC.SetOptionFontDefaults(nil, nil)
	self.Libs.ACR:RegisterOptionsTable(self.AddOn, GetOptions, true)

	self.optionsFrames.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.DB)
	self.optionsFrames.profiles.order = 1000

	local LDS = LibStub("LibDualSpec-1.0")
	if LDS then
		LDS:EnhanceDatabase(self.DB, "OmniAurasDB")
		LDS:EnhanceOptions(self.optionsFrames.profiles, self.DB)
	end

	self.SetupOptions = nil
end

function E:RegisterModuleOptions(name, optionTbl, displayName, uproot)
	self.moduleOptions[name] = optionTbl
	self.optionsFrames[name] = uproot and self.Libs.ACD:AddToBlizOptions(self.AddOn, displayName, self.AddOn, name)
end

function E:ACR_NotifyChange()
	if self.Libs.ACD.OpenFrames.OmniAuras then
		self.Libs.ACR:NotifyChange(E.AddOn)
	end
end
