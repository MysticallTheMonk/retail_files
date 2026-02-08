local addonName, addon = ...

local L = TomTomLocals

local function createconfig()
	local options = {}

	options.type = "group"
	options.name = "TomTom"

	local function get(info)
		local ns,opt = string.split(".", info.arg)
		local val = TomTom.db.profile[ns][opt]
		if type(val) == "table" then
			return unpack(val)
		else
			return val
		end
	end

	local function set(info, arg1, arg2, arg3, arg4)
		local ns,opt = string.split(".", info.arg)
		if arg2 then
			local entry = TomTom.db.profile[ns][opt]
			entry[1] = arg1
			entry[2] = arg2
			entry[3] = arg3
			entry[4] = arg4
		else
			TomTom.db.profile[ns][opt] = arg1
		end

		if ns == "block" then
			TomTom:ShowHideCoordBlock()
		elseif ns == "mapcoords" then
			TomTom:ShowHideWorldCoords()
		elseif ns == "arrow" then
			TomTom:ShowHideCrazyArrow()
		elseif ns == "minimap" and (opt == "theme" or opt == "default_iconsize") then
			TomTom:ReloadWaypoints()
		elseif ns == "worldmap" and (opt == "theme" or opt == "default_iconsize") then
			TomTom:ReloadWaypoints()
		elseif ns == "poi" and TomTom.WOW_MAINLINE then
			TomTom:EnableDisablePOIIntegration()
		elseif ns == "paste" then
			TomTom:PasteConfigChanged()
		elseif opt == "otherzone" then
			TomTom:ReloadWaypoints()
		elseif info.arg == "minimap.enable" or info.arg == "worldmap.enable" then
			TomTom:ReloadWaypoints()
		elseif info.arg == "feeds.coords_throttle" then
			TomTom:UpdateCoordFeedThrottle()
		elseif info.arg == "feeds.arrow_throttle" then
			TomTom:UpdateArrowFeedThrottle()
		end
	end

	options.args = {}

	options.args.coordblock = {
		type = "group",
		order = 2,
		name = L["Coordinate Block"],
		desc = L["Options that alter the coordinate block"],
		get = get,
		set = set,
		args = {
			desc = {
				order = 1,
				type = "description",
				name = L["TomTom provides you with a floating coordinate display that can be used to determine your current position.  These options can be used to enable or disable this display, or customize the block's display."],
			},
			enable = {
				order = 2,
				type = "toggle",
				name = L["Enable coordinate block"],
				desc = L["Enables a floating block that displays your current position in the current zone"],
				width = "double",
				arg = "block.enable",
			},
			lock = {
				order = 3,
				type = "toggle",
				name = L["Lock coordinate block"],
				desc = L["Locks the coordinate block so it can't be accidentally dragged to another location"],
				width = "double",
				arg = "block.lock",
			},
			accuracy = {
				order = 4,
				type = "range",
				name = L["Coordinate Accuracy"],
				desc = L["Coordinates can be displayed as simple XX, YY coordinate, or as more precise XX.XX, YY.YY.  This setting allows you to control that precision"],
				min = 0, max = 2, step = 1,
				arg = "block.accuracy",
			},
            coords_throttle = {
				type = "range",
				order = 5,
				name = L["Update throttle"],
				desc = L["Controls the frequency of updates for the coordinate block."],
				width = "double",
				min = 0, max = 2.0, step = 0.05,
				arg = "block.throttle",
			},
			display = {
				order = 5,
				type = "group",
				inline = true,
				name = L["Display Settings"],
				args = {
					help = {
						type = "description",
						name = L["The display of the coordinate block can be customized by changing the options below."],
						order = 1,
					},
					textcolor = {
						type = "color",
						name = L["Text color"],
						arg = "block.textcolor",
						hasAlpha = true,
					},
					bordercolor = {
						type = "color",
						name = L["Border color"],
						arg = "block.bordercolor",
						hasAlpha = true,
					},
					bgcolor = {
						type = "color",
						name = L["Background color"],
						arg = "block.bgcolor",
						hasAlpha = true,
					},
					height = {
						type = "range",
						name = L["Block height"],
						arg = "block.height",
						min = 5, max = 50, step = 1,
					},
					width = {
						type = "range",
						name = L["Block width"],
						arg = "block.width",
						min = 50, max = 250, step = 5,
					},
					fontsize = {
						type = "range",
						name = L["Font size"],
						arg = "block.fontsize",
						min = 1, max = 24, step = 1,
					},
					reset_position = {
						type = "execute",
						name = L["Reset Position"],
						desc = L["Resets the position of the waypoint arrow if it has been dragged off screen"],
						func = function()
							if TomTomBlock then
								TomTomBlock:ClearAllPoints()
								local pos = {"CENTER", nil, "CENTER", 0, -100}
								set({arg="block.position"}, pos)
								TomTomBlock:SetPoint(pos[1], UIParent, pos[3], pos[4], pos[5])
							end
						end,
					},
				},
			},
		},
	} -- End coordinate block settings

	local arrowThemeConfig = {
		["classic"] = {
			texture = "Interface\\Addons\\TomTom\\Images\\Arrow-1024",
			iconCoords = {0, 256 / 2304, 0, 256 / 3072},
		},
		["modern"] = {
			texture = "Interface\\Addons\\TomTom\\Images\\Modern\\ArrowNavColour",
			iconCoords = {0, 256 / 2304, 0, 256 / 3072},
		},
		["modern-top-down"] = {
			texture = "Interface\\Addons\\TomTom\\Images\\Modern\\ArrowNavTopDownColour",
			iconCoords = {0, 256 / 2304, 0, 256 / 3072},
		}
	}

	local function getThemeConfig(key)
		local theme = addon.db.profile.arrow.theme
		if not theme then theme = "classic" end

		local config = arrowThemeConfig[theme]
		return config[key]
	end

	local function getArrowTexture()
		return getThemeConfig("texture")
	end

	local function getArrowTextureCoords()
		return getThemeConfig("iconCoords")
	end

	options.args.crazytaxi = {
		type = "group",
		order = 3,
		name = L["Waypoint Arrow"],
		get = get,
		set = set,
		args = {
			help = {
				order = 1,
				type = "description",
				name = L["TomTom provides an arrow that can be placed anywhere on the screen.  Similar to the arrow in \"Crazy Taxi\" it will point you towards your next waypoint"],
			},
			enable = {
				order = 2,
				type = "toggle",
				name = L["Enable floating waypoint arrow"],
				width = "double",
				arg = "arrow.enable",
			},
			theme = {
				order = 2.1,
				type = "group",
				name = L["Themes"],
				width = "half",
				inline = true,
				args = {
					help = {
						type = "description",
						order = 1,
						name = L["There are a few different themes that you can apply to the waypoint arrow, use this section to configure."],
					},
					theme = {
						order = 2,
						type = "select",
						name = L["Theme"],
						desc = L["You can customize the display of the crazy arrow with a variety of themes."],
						width = "double",
						values = {
							["classic"] = L["Classic theme"],
							["modern"] = L["Modern theme"],
							["modern-top-down"] = L["Modern top-down theme"],
						},
						arg = "arrow.theme",
					},
					spacer = {
						order = 3,
						type = "description",
						name = "    ",
						width = "half",
					},
					arrowTexture = {
						order = 4,
						type = "description",
						name = " ",
						width = 0.25,
						image = getArrowTexture,
						imageCoords = getArrowTextureCoords,
						imageWidth = 75,
						imageHeight = 75,
					},
				}
			},
			autoqueue = {
				order = 3,
				type = "toggle",
				width = "double",
				name = L["Automatically set waypoint arrow"],
				desc = L["When a new waypoint is added, TomTom can automatically set the new waypoint as the \"Crazy Arrow\" waypoint."],
				arg = "arrow.autoqueue",
			},
			lock = {
				order = 4,
				type = "toggle",
				name = L["Lock waypoint arrow"],
				desc = L["Locks the waypoint arrow, so it can't be moved accidentally"],
				width = "double",
				arg = "arrow.lock",
			},
			rightclick = {
				order = 7,
				type = "toggle",
				name = L["Enable the right-click contextual menu"],
				desc = L["Enables a menu when right-clicking on the waypoint arrow allowing you to clear or remove waypoints"],
				width = "double",
				arg = "arrow.menu",
			},
			disableclick = {
				order = 8,
				type = "toggle",
				name = L["Disable all mouse input"],
				desc = L["Disables the crazy taxi arrow for mouse input, allowing all clicks to pass through"],
				width = "double",
				arg = "arrow.noclick",
			},
			setclosest = {
				order = 9,
				type = "toggle",
				name = L["Automatically set to next closest waypoint"],
				desc = L["When the current waypoint is cleared (either by the user or automatically) and this option is set, TomTom will automatically set the closest waypoint in the current zone as active waypoint."],
				width = "double",
				arg = "arrow.setclosest",
			},
			closestusecontinent = {
				order = 10,
				type = "toggle",
				name = L["Allow closest waypoint to be outside current zone"],
				desc = L["Normally when TomTom sets the closest waypoint it chooses the waypoint in your current zone. This option will cause TomTom to search for any waypoints on your current continent. This may lead you outside your current zone, so it is disabled by default."],
				width = "double",
				arg = "arrow.closestusecontinent",
			},
			heredistance = {
				order = 11,
				type = "range",
				name = L["\"Arrival Distance\""],
				desc = L["This setting will control the distance at which the waypoint arrow switches to a downwards arrow, indicating you have arrived at your destination"],
				min = 0, max = 150, step = 1,
				width = "double",
				arg = "arrow.arrival",
			},
            enablePing = {
                order = 12,
                type = "toggle",
                name = L["Play a sound when arriving at a waypoint"],
                desc = L["When you 'arrive' at a waypoint (this distance is controlled by the 'Arrival Distance' setting in this group) a sound can be played to indicate this.  You can enable or disable this sound using this setting."],
                width = "double",
                arg = "arrow.enablePing",
            },
			setPingChannel = {
                order = 12,
                type = "select",
                name = L["Channel to play the ping through"],
                desc = L["When a 'ping' is played, use the indicated sound channel so the volume can be controlled."],
                width = "double",
                values = {
					["Master"] = MASTER_VOLUME,
					["SFX"] = SOUND_VOLUME,
					["Music"] = MUSIC_VOLUME,
					["Ambience"] = AMBIENCE_VOLUME,
					["Dialog"] = DIALOG_VOLUME
                },
                arg = "arrow.pingChannel",
            },
			hideDuringPetBattles = {
				order = 13,
				type = "toggle",
				name = L["Hide the crazy arrow display during pet battles"],
				desc = L["When a pet battle begins, the crazy arrow will be hidden from view. When you exit the pet battle, it will be re-shown."],
				width = "double",
				arg = "arrow.hideDuringPetBattles",
			},
			stickyCorpse = {
				order = 14,
				type = "toggle",
				name = L["Allow the corpse arrow to override other waypoints"],
				desc = L["When the player is dead and has a waypoint towards their corpse, it will prevent other waypoints from changing the crazy arrow"],
				width = "double",
				arg = "arrow.stickycorpse",
			},
			strata = {
				order = 16,
				type = "toggle",
				name = L["Place the arrow in the HIGH strata"],
				desc = L["If your arrow is covered up by something else, try this to bump it up a layer."],
				width = "double",
				arg = "arrow.highstrata",
			},
			display = {
				type = "group",
				name = L["Arrow display"],
				order = 16,
				inline = true,
				args = {
					help = {
						type = "description",
						order = 1,
						name = L["These options let you customize the size and opacity of the waypoint arrow, making it larger or partially transparent, as well as limiting the size of the title display."],
					},
					arrival = {
						order = 1,
						type = "toggle",
						name = L["Show estimated time to arrival"],
						desc = L["Shows an estimate of how long it will take you to reach the waypoint at your current speed"],
						width = "double",
						arg = "arrow.showtta",
					},
					showdistance = {
						order = 2,
						type = "toggle",
						name = L["Show the distance to the waypoint"],
						desc = L["Shows the distance (in yards) to the waypoint"],
						width = "double",
						arg = "arrow.showdistance",
					},
					distanceUnits = {
						order = 3,
						type = "select",
						name = L["Distance unit to use"],
						desc = L["Configures which unit (yards, metrics, auto) to show distances in"],
						width = "double",
						values = {
							["auto"] = "Automatic (yards for US, metric elsewhere)",
							["yards"] = "Show the distance in yards",
							["meters"] = "Show the distance in meters",
							["humanyards"] = "Show distance in miles and yards",
							["humanmeters"] = "Show distance in km and meters",
						},
						arg = "arrow.distanceUnits",
					},
					scale = {
						type = "range",
						order = 4,
						name = L["Scale"],
						desc = L["This setting allows you to change the scale of the waypoint arrow, making it larger or smaller"],
						min = 0, max = 3, step = 0.05,
						arg = "arrow.scale",
					},
					alpha = {
						type = "range",
						order = 5,
						name = L["Alpha"],
						desc = L["This setting allows you to change the opacity of the waypoint arrow, making it transparent or opaque"],
						min = 0.1, max = 1.0, step = 0.05,
						arg = "arrow.alpha",
					},
					title_width = {
						type = "range",
						order = 6,
						name = L["Title Width"],
						desc = L["This setting allows you to specify the maximum width of the title text.  Any titles that are longer than this width (in game pixels) will be wrapped to the next line."],
						min = 0, max = 500, step = 1,
						arg = "arrow.title_width",
					},
					title_height = {
						type = "range",
						order = 7,
						name = L["Title Height"],
						desc = L["This setting allows you to specify the maximum height of the title text.  Any titles that are longer than this height (in game pixels) will be truncated."],
						min = 0, max = 300, step = 1,
						arg = "arrow.title_height",
					},
					title_scale = {
						type = "range",
						order = 8,
						name = L["Title Scale"],
						desc = L["This setting allows you to specify the scale of the title text."],
						min = 0, max = 3, step = 0.05,
						arg = "arrow.title_scale",
					},
					title_alpha = {
						type = "range",
						order = 9,
						name = L["Title Alpha"],
						desc = L["This setting allows you to change the opacity of the title text, making it transparent or opaque"],
						min = 0, max = 1.0, step = 0.05,
						arg = "arrow.title_alpha",
					},
					reset_position = {
						order = 10,
						type = "execute",
						name = L["Reset Position"],
						desc = L["Resets the position of the waypoint arrow if it has been dragged off screen"],
						func = function()
							TomTomCrazyArrow:ClearAllPoints()
							local pos = {"CENTER", nil , "CENTER", 0, 0}
							set({arg="arrow.position"}, pos)
							TomTomCrazyArrow:SetPoint(pos[1], UIParent, pos[3], pos[4], pos[5])
						end,
					},
				}
			},
			color = {
				type = "group",
				name = L["Arrow colors"],
				order = 15,
				inline = true,
				args = {
					help = {
						order = 1,
						type = "description",
						name = L["The floating waypoint arrow can change color depending on whether or not you are facing your destination.  By default it will display green when you are facing it directly, and red when you are facing away from it.  These colors can be changed in this section.  Setting these options to the same color will cause the arrow to not change color at all"],
					},
					colorstart = {
						order = 2,
						type = "color",
						name = L["Good color"],
						desc = L["The color to be displayed when you are moving in the direction of the active waypoint"],
						arg = "arrow.goodcolor",
						hasAlpha = false,
					},
					colormiddle = {
						order = 3,
						type = "color",
						name = L["Middle color"],
						desc = L["The color to be displayed when you are halfway between the direction of the active waypoint and the completely wrong direction"],
						arg = "arrow.middlecolor",
						hasAlpha = false,
					},
					colorend = {
						order = 4,
						type = "color",
						name = L["Bad color"],
						desc = L["The color to be displayed when you are moving in the opposite direction of the active waypoint"],
						arg = "arrow.badcolor",
						hasAlpha = false,
					},
					exactcolor = {
						order = 5,
						type = "color",
						name = L["Exact color"],
						desc = L["The color to be displayed when you are moving in the exact direction of the active waypoint"],
						arg = "arrow.exactcolor",
						hasAlpha = false,
					},
				},
			},
		},
	} -- End crazy taxi options

	-- Enable texture theme lookup
	local function getMinimapThemeDotTexture()
		local theme = addon.db.profile.minimap.theme
		return addon.waypointThemeRegistry:GetThemeDotTexture(theme)
	end

	local function getMinimapThemeArrowTexture()
		local theme = addon.db.profile.minimap.theme
		return addon.waypointThemeRegistry:GetThemeArrowTexture(theme)
	end

	local function getWorldMapThemeDotTexture()
		local theme = addon.db.profile.worldmap.theme
		return addon.waypointThemeRegistry:GetThemeDotTexture(theme)
	end

	options.args.minimap = {
		type = "group",
		order = 4,
		name = L["Minimap"],
		get = get,
		set = set,
		args = {
			help = {
				order = 1,
				type = "description",
				name = L["TomTom can display multiple waypoint arrows on the minimap.  These options control the display of these waypoints"],
			},
			enable = {
				order = 2,
				type = "toggle",
				name = L["Enable minimap waypoints"],
				width = "double",
				arg = "minimap.enable",
			},
			otherzone = {
				order = 3,
				type = "toggle",
				name = L["Display waypoints from other zones"],
				desc = L["TomTom can hide waypoints in other zones, this setting toggles that functionality"],
				width = "double",
				arg = "minimap.otherzone",
			},
			tooltip = {
				order = 4,
				type = "toggle",
				name = L["Enable mouseover tooltips"],
				desc = L["TomTom can display a tooltip containing information about waypoints, when they are moused over.  This setting toggles that functionality"],
				width = "double",
				arg = "minimap.tooltip",
			},
			rightclick = {
				order = 5,
				type = "toggle",
				name = L["Enable the right-click contextual menu"],
				desc = L["Enables a menu when right-clicking on a waypoint allowing you to clear or remove waypoints"],
				width = "double",
				arg = "minimap.menu",
			},
			theme = {
				order = 6,
				type = "group",
				name = L["Themes"],
				width = "half",
				inline = true,
				args = {
					help = {
						type = "description",
						order = 1,
						name = L["There are a few different themes that you can apply to the waypoints, use this section to configure."],
					},
					theme = {
						order = 2,
						type = "select",
						name = L["Theme"],
						desc = L["You can customize the display of the waypoints with a variety of themes."],
						width = "double",
						values = addon.waypointThemeRegistry:GetThemeConfigOptions(),
						sorting = addon.waypointThemeRegistry:GetThemeConfigOptionsSorting(),
						arg = "minimap.theme",
					},
					spacer = {
						order = 3,
						type = "description",
						name = "    ",
						width = "half",
					},
					dotTexture = {
						order = 4,
						type = "description",
						name = " ",
						width = 0.25,
						image = getMinimapThemeDotTexture,
						imageWidth = 20,
						imageHeight = 20,
					},
					arrowTexture = {
						order = 4,
						type = "description",
						name = " ",
						width = 0.25,
						image = getMinimapThemeArrowTexture,
						imageWidth = 20,
						imageHeight = 20,
					},
				}
			},
			iconsize = {
				order = 10,
				type = "range",
				name = L["Minimap Icon Size"],
				desc = L["This setting allows you to control the default size of the minimap icon. "],
				min = 4, max = 64, step = 2,
				arg = "minimap.default_iconsize",
			},
		},
	} -- End minimap options

	options.args.worldmap = {
		type = "group",
		order = 5,
		name = L["World Map"],
		get = get,
		set = set,
		args = {
			help = {
				order = 1,
				type = "description",
				name = L["TomTom can display multiple waypoints on the world map.  These options control the display of these waypoints"],
			},
			enable = {
				order = 2,
				type = "toggle",
				name = L["Enable world map waypoints"],
				width = "double",
				arg = "worldmap.enable",
			},
			otherzone = {
				order = 3,
				type = "toggle",
				name = L["Display waypoints from other zones"],
				desc = L["TomTom can hide waypoints in other zones, this setting toggles that functionality"],
				width = "double",
				arg = "worldmap.otherzone",
			},
			tooltip = {
				order = 4,
				type = "toggle",
				name = L["Enable mouseover tooltips"],
				desc = L["TomTom can display a tooltip containing information about waypoints, when they are moused over.  This setting toggles that functionality"],
				width = "double",
				arg = "worldmap.tooltip",
			},
			createclick = {
				order = 5,
				type = "toggle",
				name = L["Allow control-right clicking on map to create new waypoint"],
				width = "double",
				arg = "worldmap.clickcreate",
			},
			rightclick = {
				type = "toggle",
				order = 6,
				name = L["Enable the right-click contextual menu"],
				desc = L["Enables a menu when right-clicking on a waypoint allowing you to clear or remove waypoints"],
				width = "double",
				arg = "worldmap.menu",
			},
			modifier = {
				type = "select",
				order = 7,
				name = L["Create note modifier"],
				desc = L["This setting changes the modifier used by TomTom when right-clicking on the world map to create a waypoint"],
				values = {
					["A"] = "Alt",
					["C"] = "Ctrl",
					["S"] = "Shift",
					["AC"] = "Alt-Ctrl",
					["AS"] = "Alt-Shift",
					["CS"] = "Ctrl-Shift",
					["ACS"] = "Alt-Ctrl-Shift",
				},
				arg = "worldmap.create_modifier",
			},
			player = {
				order = 8,
				type = "group",
				inline = true,
				name = L["Player Coordinates"],
				args = {
					enableplayer = {
						order = 1,
						type = "toggle",
						name = L["Enable showing player coordinates"],
						width = "double",
						arg = "mapcoords.playerenable",
					},
					playeraccuracy = {
						order = 4,
						type = "range",
						name = L["Player coordinate accuracy"],
						desc = L["Coordinates can be displayed as simple XX, YY coordinate, or as more precise XX.XX, YY.YY.  This setting allows you to control that precision"],
						min = 0, max = 2, step = 1,
						arg = "mapcoords.playeraccuracy",
					},
					playeroffset = {
						order = 8,
						type = "range",
						name = L["Player coordinate offset"],
						desc = L["Coordinates can be moved from the default location, this setting allows you to control that offset"],
						min = -16, max = 256, step = 1,
						arg = "mapcoords.playeroffset",
					},
				},
			},
			cursor = {
				order = 9,
				type = "group",
				inline = true,
				name = L["Cursor Coordinates"],
				args = {
					enablecursor = {
						order = 3,
						type = "toggle",
						name = L["Enable showing cursor coordinates"],
						width = "double",
						arg = "mapcoords.cursorenable",
					},
					cursoraccuracy = {
						order = 5,
						type = "range",
						name = L["Cursor coordinate accuracy"],
						desc = L["Coordinates can be displayed as simple XX, YY coordinate, or as more precise XX.XX, YY.YY.  This setting allows you to control that precision"],
						min = 0, max = 2, step = 1,
						arg = "mapcoords.cursoraccuracy",
					},
					cursoroffset = {
						order = 7,
						type = "range",
						name = L["Cursor coordinate offset"],
						desc = L["Coordinates can be moved from the default location, this setting allows you to control that offset"],
						min = -32, max = 128, step = 1,
						arg = "mapcoords.cursoroffset",
					},
				},
			},
			theme = {
				order = 9,
				type = "group",
				name = L["Themes"],
				width = "half",
				inline = true,
				args = {
					help = {
						type = "description",
						order = 1,
						name = L["There are a few different themes that you can apply to the waypoints, use this section to configure."],
					},
					theme = {
						order = 2,
						type = "select",
						name = L["Theme"],
						desc = L["You can customize the display of the waypoints with a variety of themes."],
						width = "double",
						values = addon.waypointThemeRegistry:GetThemeConfigOptions(),
						sorting = addon.waypointThemeRegistry:GetThemeConfigOptionsSorting(),
						arg = "worldmap.theme",
					},
					spacer = {
						order = 3,
						type = "description",
						name = "    ",
						width = "half",
					},
					dotTexture = {
						order = 4,
						type = "description",
						name = " ",
						width = 0.25,
						image = getWorldMapThemeDotTexture,
						imageWidth = 20,
						imageHeight = 20,
					},
					iconsize = {
						order = 5,
						type = "range",
						name = L["World Map Icon Size"],
						desc = L["This setting allows you to control the default size of the world map icon"],
						min = 4, max = 64, step = 2,
						arg = "worldmap.default_iconsize",
					},
				}
			},
		},
	} -- End world map options

	-- LDB Data Feeds
	options.args.feeds = {
		type = "group",
		order = 8,
		name = L["Data Feed Options"],
		get = get,
		set = set,
		args = {
			help = {
				order = 1,
				type = "description",
				name = L["TomTom is capable of providing data sources via LibDataBroker, which allows them to be displayed in any LDB compatible display.  These options enable or disable the individual feeds, but will only take effect after a reboot."],
			},
			coords = {
				type = "toggle",
				order = 2,
				name = L["Provide an LDB data source for coordinates"],
				width = "double",
				arg = "feeds.coords",
			},
			coords_throttle = {
				type = "range",
				order = 3,
				name = L["Coordinate feed throttle"],
				desc = L["Controls the frequency of updates for the coordinate LDB feed."],
				width = "double",
				min = 0, max = 2.0, step = 0.05,
				arg = "feeds.coords_throttle",
			},
			accuracy = {
				order = 4,
				type = "range",
				name = L["Coordinate feed accuracy"],
				desc = L["Coordinates can be displayed as simple XX, YY coordinate, or as more precise XX.XX, YY.YY.  This setting allows you to control that precision"],
				min = 0, max = 2, step = 1,
				arg = "feeds.coords_accuracy",
			},
			arrow = {
				type = "toggle",
				order = 5,
				name = L["Provide a LDB data source for the crazy-arrow"],
				width = "double",
				arg = "feeds.arrow",
			},
			arrow_throttle = {
				type = "range",
				order = 6,
				name = L["Crazy Arrow feed throttle"],
				desc = L["Controls the frequency of updates for the crazy arrow LDB feed."],
				width = "double",
				min = 0, max = 2.0, step = 0.05,
				arg = "feeds.arrow_throttle",
			},
		},
	}

	options.args.general = {
		type = "group",
		order = 1,
		name = L["General Options"],
		get = get,
		set = set,
		args = {
			--[[
			comm = {
				type = "toggle",
				order = 1,
				name = L["Accept waypoints from guild and party members"],
				width = "double",
				arg = "comm.enable",
			},
			promptcomm = {
				type = "toggle",
				order = 2,
				name = L["Prompt before accepting sent waypoints"],
				width = "double",
				arg = "comm.prompt",
			},
			--]]
			announce = {
				type = "toggle",
				order = 1,
				name = L["Announce new waypoints when they are added"],
				desc = L["TomTom can announce new waypoints to the default chat frame when they are added"],
				width = "double",
				arg = "general.announce",
			},
			confirmremove = {
				type = "toggle",
				order = 2,
				name = L["Ask for confirmation on \"Remove All\""],
				desc = L["This option will toggle whether or not you are asked to confirm removing all waypoints.  If enabled, a dialog box will appear, requiring you to confirm removing the waypoints"],
				width = "double",
				arg = "general.confirmremoveall",
			},
			persistence = {
				type = "toggle",
				order = 3,
				name = L["Save new waypoints until I remove them"],
				desc = L["This option will not remove any waypoints that are currently set to persist, but only effects new waypoints that get set"],
				width = "double",
				arg = "persistence.savewaypoints",
			},
			cleardistance = {
				type = "range",
				order = 4,
				name = L["Clear waypoint distance"],
				desc = L["Waypoints can be automatically cleared when you reach them.  This slider allows you to customize the distance in yards that signals your \"arrival\" at the waypoint.  A setting of 0 turns off the auto-clearing feature\n\nChanging this setting only takes effect after reloading your interface."],
				min = 0, max = 150, step = 1,
				width = "double",
				arg = "persistence.cleardistance",
			},
			corpse_arrow = {
				type = "toggle",
				order = 6,
				name = L["Automatically set a waypoint when I die"],
				desc = L["TomTom can automatically set a waypoint when you die, guiding you back to your corpse"],
				width = "double",
				arg = "general.corpse_arrow",
			},
			reset_waypoint_options = {
				type = "execute",
				order = 7,
				name = L["Reset waypoint display options to current"],
				desc = L["If you have changed the waypoint display settings (minimap, world), this will reset all waypoints to the current options."],
				func = function()
					TomTom:ResetWaypointOptions()
					TomTom:ReloadWaypoints()
				end,
				width = "double",
			},
		},
	}

	options.args.poi = {
		type = "group",
		order = 6,
		name = L["Quest Objectives"],
		desc = L["Options that alter quest objective integration"],
		get = get,
		set = set,
		args = {
			desc = {
				order = 1,
				type = "description",
				name = L["TomTom can be configured to set waypoints for the quest objectives that are shown in the watch frame and on the world map.  These options can be used to configure these options."],
			},
			enable = {
				order = 2,
				type = "toggle",
				name = L["Enable quest objective click integration"],
				desc = L["Enables the setting of waypoints when modified-clicking on quest objectives"],
				width = "double",
				arg = "poi.enable",
			},
            modifier = {
				type = "select",
				order = 3,
				name = L["set waypoint modifier"],
				desc = L["This setting changes the modifier used by TomTom when right-clicking on a quest objective POI to create a waypoint"],
				values = {
					["A"] = "Alt",
					["C"] = "Ctrl",
					["S"] = "Shift",
					["AC"] = "Alt-Ctrl",
					["AS"] = "Alt-Shift",
					["CS"] = "Ctrl-Shift",
					["ACS"] = "Alt-Ctrl-Shift",
				},
				arg = "poi.modifier",
			},
            enableClosest = {
				order = 4,
				type = "toggle",
				name = L["Enable automatic quest objective waypoints"],
				desc = L["Enables the automatic setting of quest objective waypoints based on which objective is closest to your current location.  This setting WILL override the setting of manual waypoints."],
				width = "double",
				arg = "poi.setClosest",
			},
			arrival = {
				order = 5,
				type = "range",
				name = L["\"Arrival Distance\""],
				desc = L["This setting will control the distance at which the waypoint arrow switches to a downwards arrow, indicating you have arrived at your destination"],
				min = 0, max = 150, step = 5,
				arg = "poi.arrival",
			},
		},
	} -- End POI Integration settings

	options.args.paste = {
		type = "group",
		order = 7,
		name = L["Paste window"],
		desc = L["Options that affect the /ttpaste bulk waypoint window"],
		get = get,
		set = set,
		args = {
			desc = {
				order = 1,
				type = "description",
				name = L["TomTom supports setting multiple waypoints at the same time, and storing and loading pages of waypoints. This section enables you to configure some settings for this feature."],
			},
			enableMinimap = {
				order = 2,
				type = "toggle",
				name = L["Show minimap button to open TomTom-Paste window"],
				desc = L["Enables or disables the showing of a minimap button to toggle the paste window."],
				width = "double",
				arg = "paste.minimap_button",
			},
			enableAddonCompartment = {
				order = 3,
				type = "toggle",
				name = L["Show addon compartment button to open TomTom-Paste window"],
				desc = L["Enables or disables the showing of an addon-compartment button to toggle the paste window."],
				width = "double",
				arg = "paste.addon_compartment_button",
			},
		}
	}

	options.args.profile = {
		type = "group",
		order = 8,
		name = L["Profile Options"],
		args = {
			desc = {
				order = 1,
				type = "description",
				name = L["TomTom's saved variables are organized so you can have shared options across all your characters, while having different sets of waypoints for each.  These options sections allow you to change the saved variable configurations so you can set up per-character options, or even share waypoints between characters"],
			},
			options = LibStub("AceDBOptions-3.0"):GetOptionsTable(TomTom.db),
			waypoints = LibStub("AceDBOptions-3.0"):GetOptionsTable(TomTom.waydb)
		}
	}

	options.args.profile.args.options.name = L["Options profile"]
	options.args.profile.args.options.desc = L["Saved profile for TomTom options"]
	options.args.profile.args.options.order = 2

	options.args.profile.args.waypoints.name = L["Waypoints profile"]
	options.args.profile.args.waypoints.desc = L["Save profile for TomTom waypoints"]
	options.args.profile.args.waypoints.order = 3

	return options
end

local config = LibStub("AceConfig-3.0")
local dialog = LibStub("AceConfigDialog-3.0")
local registered = false;

local options
local function createBlizzOptions()
	options = createconfig()

	-- General Options
	config:RegisterOptionsTable("TomTom-General", options.args.general)
	local blizzPanel = dialog:AddToBlizOptions("TomTom-General", options.args.general.name, "TomTom")

	-- Coordinate Block Options
	config:RegisterOptionsTable("TomTom-CoordBlock", options.args.coordblock)
	dialog:AddToBlizOptions("TomTom-CoordBlock", options.args.coordblock.name, "TomTom")

	-- Crazy Taxi Options
	config:RegisterOptionsTable("TomTom-CrazyTaxi", options.args.crazytaxi)
	dialog:AddToBlizOptions("TomTom-CrazyTaxi", options.args.crazytaxi.name, "TomTom")

	-- Minimap Options
	config:RegisterOptionsTable("TomTom-Minimap", options.args.minimap)
	dialog:AddToBlizOptions("TomTom-Minimap", options.args.minimap.name, "TomTom")

	-- World Map Options
	config:RegisterOptionsTable("TomTom-Worldmap", options.args.worldmap)
	dialog:AddToBlizOptions("TomTom-Worldmap", options.args.worldmap.name, "TomTom")

	-- World Map Options
	config:RegisterOptionsTable("TomTom-Feeds", options.args.feeds)
	dialog:AddToBlizOptions("TomTom-Feeds", options.args.feeds.name, "TomTom")

	-- POI Options
	if TomTom.WOW_MAINLINE then
		config:RegisterOptionsTable("TomTom-POI", options.args.poi)
		dialog:AddToBlizOptions("TomTom-POI", options.args.poi.name, "TomTom")
	end

	-- Paste Options
	config:RegisterOptionsTable("TomTom-Paste", options.args.paste)
	dialog:AddToBlizOptions("TomTom-Paste", options.args.paste.name, "TomTom")

	-- Profile Options
	local p_options = options.args.profile.args.options
	local w_options = options.args.profile.args.waypoints
	config:RegisterOptionsTable("TomTom-Profiles-Waypoints", w_options)
	config:RegisterOptionsTable("TomTom-Profiles-Options", p_options)
	dialog:AddToBlizOptions("TomTom-Profiles-Waypoints", w_options.name, "TomTom")
	dialog:AddToBlizOptions("TomTom-Profiles-Options", p_options.name, "TomTom")
	return blizzPanel
end

local aboutOptions = {
	type = "group",
	args = {
		logo = {
			order = 1,
			type = "description",
			name = " ",
			image = "Interface\\AddOns\\TomTom\\Images\\Modern\\TomTom-Logo.tga",
			imageWidth = 128,
			imageHeight = 128,
		},
		version = {
			order = 2,
			type = "description",
			fontSize = "medium",
			name = function() return "|cffffd200Version:|r TomTom-".. addon.version end,
		},
		spacer = {
			order = 3,
			type = "description",
			name = " ",
		},
		creditsHeader = {
			order = 4,
			type = "header",
			name = "Credits",
		},
		creditsList = {
			order = 5,
			type = "description",
			fontSize = "medium",
			name = table.concat({
				"|cffffd200Author:|r Cladhaire",
				"|cffffd200Co-maintainer:|r Ludovicus",
				"|cffffd200Contributors:|r",
				"- Carl Thomas (modern artwork)",
				"- Chris Braithwaite (modern artwork)",
				"- Localization by many helpers",
				"",
				"|cffffd200Special Thanks:|r",
				" The WoW addon community",
			}, "\n"),
		},
	},
}

local blizzPanel
function addon:CreateConfigPanels()
	config:RegisterOptionsTable("TomTom", aboutOptions)
	local aboutFrame, category = dialog:AddToBlizOptions("TomTom", "TomTom")
	addon.aboutCategory = category
	if not registered then
		blizzPanel = createBlizzOptions()
		registered = true
	end
end

SLASH_TOMTOM1 = "/tomtom"
SlashCmdList["TOMTOM"] = function(msg)
	local tokens = {}
	for token in msg:gmatch("%S+") do table.insert(tokens, token) end

	if tokens[1] and tokens[1]:lower() == "help" then
		TomTom.slashCommandUsage()
		return
	end

	if Settings then
		Settings.OpenToCategory(addon.aboutCategory)
	elseif InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory("TomTom")
		InterfaceOptionsFrame_OpenToCategory("TomTom")
	end
end
