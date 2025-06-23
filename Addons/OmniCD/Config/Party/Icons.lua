local E, L = select(2, ...):unpack()
local P = E.Party

local icons = {
	name = L["Icons"],
	order = 30,
	type = "group",
	get = P.getIcons,
	set = P.setIcons,
	args = {
		scaleSettings = {
			name = L["Size"],
			order = 10,
			type = "group",
			inline = true,
			args = {
				scale = {
					name = L["Icon Size"],
					desc = L["Set the size of icons"],
					order = 10,
					type = "range",
					min = 0.2, max = 2.0, step = 0.01, isPercent = true,
					set = function(info, value)
						local key, option = info[2], info[#info]
						E.profile.Party[key].icons[option] = value
						if P:IsCurrentZone(key) then
							P:ConfigSize()
						end
					end,
				},
				chargeScale = {
					name = L["Charge Size"],
					desc = L["Set the size of charge numbers"],
					order = 11,
					type = "range",
					min = 0.5, max = 1.5, step = 0.1, isPercent = true,
				},
				counterScale = {
					name = L["Counter Size"],
					desc = L["Set the size of cooldown numbers"],
					order = 12,
					type = "range",
					min = 0.1, max = 1, step = 0.05, isPercent = true,
				},
			}
		},
		alphaSettings = {
			name = OPACITY,
			order = 20,
			type = "group",
			inline = true,
			args = {
				swipeAlpha = {
					name = L["Swipe Opacity"],
					desc = L["Set the opacity of swipe animations"],
					order = 13,
					type = "range",
					min = 0, max = 1, step = 0.1,
				},
				inactiveAlpha = {
					name = L["Inactive Icon Opacity"],
					desc = L["Set the opacity of icons not on cooldown"],
					order = 14,
					type = "range",
					min = 0, max = 1, step = 0.1,
				},
				activeAlpha = {
					name = L["Active Icon Opacity"],
					desc = L["Set the opacity of icons on cooldown"],
					order = 15,
					type = "range",
					min = 0, max = 1, step = 0.1,
				},
			}
		},
		borderSettings = {
			disabled = function(info) return not E.profile.Party[ info[2] ].icons.displayBorder end,
			name = L["Border"],
			order = 30,
			type = "group",
			inline = true,
			args = {
				displayBorder = {
					disabled = false,
					name = ENABLE,
					desc = format("%s\n\n%s: %s", L["Display custom border around icons"],
						L["Pixel Perfect"],
						L["Borders retain 1px width regardless of the UI scale"]),
					order = 0,
					type = "toggle",
				},
				borderColor = {
					name = L["Border Color"],
					order = 1,
					type = "color",
					dialogControl = "ColorPicker-OmniCDC",
					get = function(info)
						local db = E.profile.Party[ info[2] ].icons
						return db.borderColor.r, db.borderColor.g, db.borderColor.b
					end,
					set = function(info, r, g, b)
						local db = E.profile.Party[ info[2] ].icons
						db.borderColor.r = r
						db.borderColor.g = g
						db.borderColor.b = b
						P:Refresh()
					end,
				},
			}
		},
		miscSettings = {
			name = MISCELLANEOUS,
			order = 40,
			type = "group",
			inline = true,
			args = {
				showCounter = {
					name = COUNTDOWN_FOR_COOLDOWNS_TEXT,
					desc = format("%s\n\n|cffff2020%s",
						L["Toggle the cooldown numbers. Spells with charges only show cooldown numbers at 0 charge"],
						L["[Show Numbers for Cooldowns] must be enabled in Blizzard's \'Options/Action Bars\' menu when using Blizzard's cooldown numbers."]),
					order = 1,
					type = "toggle",
				},
				reverse = {
					name = L["Reverse Swipe"],
					desc = L["Reverse the cooldown swipe animation"],
					order = 2,
					type = "toggle",
				},
				desaturateActive = {
					name = L["Desaturate Colors"],
					desc = L["Desaturate colors on active icons"],
					order = 3,
					type = "toggle",
				},

				displayInactive = {
					name = L["Display Inactive Icons"],
					desc = L["Display icons not on cooldown"],
					order = 4,
					type = "toggle",
					get = function(info) return E.profile.Party[ info[2] ].position.displayInactive end,
					set = function(info, state)
						local key = info[2]
						E.profile.Party[key].position.displayInactive = state
						P:Refresh()
					end,
				},
				lb1 = {
					name = "\n", order = 5, type = "description",
				},
			}
		},
	}
}

local sliderTimer
local function UpdatePixelObjects()
	for bar in P.BarPool:EnumerateActive() do
		bar:SetBarBackdrop()
		bar:UpdateLayout()
	end
	sliderTimer = nil
end

function P:ConfigSize()
	self:UpdatePositionValues()
	for bar in P.BarPool:EnumerateActive() do
		bar:SetContainerSize()
		bar:SetContainerOffset()
	end
	if E.db.icons.displayBorder then
		if not sliderTimer then
			sliderTimer = C_Timer.After(0.3, UpdatePixelObjects)
		end
	end
end

P:RegisterSubcategory("icons", icons)
