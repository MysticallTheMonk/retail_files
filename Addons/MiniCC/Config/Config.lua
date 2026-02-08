---@type string, Addon
local addonName, addon = ...
local mini = addon.Core.Framework
local verticalSpacing = mini.VerticalSpacing
local horizontalSpacing = mini.HorizontalSpacing
---@type Db
local db

---@class Db
local dbDefaults = {
	Version = 15,
	WhatsNew = {},

	NotifiedChanges = true,

	---@class InstanceOptions : HeaderOptions
	Default = {
		Enabled = true,
		ExcludePlayer = false,

		-- TODO: after a few patches once people have moved over, remove simple/advanced mode into just one single mode
		SimpleMode = {
			Enabled = true,
			Offset = {
				X = 2,
				Y = 0,
			},
			Grow = "RIGHT",
		},

		AdvancedMode = {
			Point = "TOPLEFT",
			RelativePoint = "TOPRIGHT",
			Offset = {
				X = 2,
				Y = 0,
			},
		},

		Icons = {
			Size = 50,
			Glow = true,
			ReverseCooldown = true,
			ColorByDispelType = true,
		},
	},

	Raid = {
		Enabled = true,
		ExcludePlayer = false,

		SimpleMode = {
			Enabled = true,
			Offset = {
				X = 2,
				Y = 0,
			},
			Grow = "CENTER",
		},

		AdvancedMode = {
			Point = "TOPLEFT",
			RelativePoint = "TOPRIGHT",
			Offset = {
				X = 2,
				Y = 0,
			},
		},

		Icons = {
			Size = 50,
			Glow = true,
			ReverseCooldown = true,
			ColorByDispelType = true,
		},
	},

	---@class HealerOptions
	Healer = {
		Enabled = false,
		Sound = {
			Enabled = true,
			Channel = "Master",
		},

		Point = "CENTER",
		RelativePoint = "TOP",
		RelativeTo = "UIParent",
		Offset = {
			X = 0,
			Y = -200,
		},

		Icons = {
			Size = 72,
			Glow = true,
			ReverseCooldown = true,
			ColorByDispelType = true,
		},

		Filters = {
			Arena = true,
			BattleGrounds = false,
			World = true,
		},

		Font = {
			File = "Fonts\\FRIZQT__.TTF",
			Size = 32,
			Flags = "OUTLINE",
		},
	},

	---@class AlertOptions
	Alerts = {
		Enabled = true,
		Point = "CENTER",
		RelativePoint = "TOP",
		RelativeTo = "UIParent",

		Offset = {
			X = 0,
			Y = -100,
		},

		Icons = {
			Size = 72,
			Glow = true,
			ReverseCooldown = true,
		},
	},

	---@class NameplateOptions
	Nameplates = {
		Friendly = {
			---@class NameplateSpellTypeOptions
			CC = {
				Enabled = false,
				Grow = "RIGHT",
				Offset = {
					X = 2,
					Y = 0,
				},

				Icons = {
					Size = 50,
					Glow = true,
					ReverseCooldown = true,
					ColorByDispelType = true,
					MaxIcons = 5,
				},
			},
			Important = {
				Enabled = false,
				Grow = "LEFT",
				Offset = {
					X = -2,
					Y = 0,
				},

				Icons = {
					Size = 50,
					Glow = true,
					ReverseCooldown = true,
					ColorByDispelType = true,
					MaxIcons = 5,
				},
			},
		},
		Enemy = {
			CC = {
				Enabled = true,
				Grow = "RIGHT",
				Offset = {
					X = 2,
					Y = 0,
				},

				Icons = {
					Size = 50,
					Glow = true,
					ReverseCooldown = true,
					ColorByDispelType = true,
					MaxIcons = 5,
				},
			},
			Important = {
				Enabled = true,
				Grow = "LEFT",
				Offset = {
					X = -2,
					Y = 0,
				},

				Icons = {
					Size = 50,
					Glow = true,
					ColorByDispelType = true,
					MaxIcons = 5,
				},
			},
		},
	},

	Portrait = {
		Enabled = true,
		ReverseCooldown = true,
	},

	---@class KickTimerOptions
	KickTimer = {
		CasterEnabled = true,
		HealerEnabled = true,
		AllEnabled = false,
		Point = "CENTER",
		RelativeTo = "UIParent",
		RelativePoint = "CENTER",
		Offset = {
			X = 0,
			Y = -300,
		},

		Icons = {
			Size = 50,
			Glow = false,
			ReverseCooldown = true,
		},
	},

	---@class TrinketsOptions
	Trinkets = {
		Enabled = true,

		Point = "RIGHT",
		RelativePoint = "LEFT",
		Offset = {
			X = -2,
			Y = 0,
		},

		Icons = {
			Size = 50,
			Glow = false,
			ReverseCooldown = false,
			ShowText = true,
		},

		Font = {
			File = "GameFontHighlightSmall",
		},
	},

	Anchor1 = "",
	Anchor2 = "",
	Anchor3 = "",
}

local config = {}
config.DbDefaults = dbDefaults
addon.Config = config

local function GetAndUpgradeDb()
	local vars = mini:GetSavedVars()

	if vars == nil or not vars.Version then
		vars = mini:GetSavedVars(dbDefaults)
	end

	if vars.Version == 1 then
		vars.SimpleMode = vars.SimpleMode or {}
		vars.SimpleMode.Enabled = true
		vars.Version = 2
	end

	if vars.Version == 2 then
		-- made some strucure changes
		mini:CleanTable(db, dbDefaults, true, true)
		vars.Version = 3
	end

	if vars.Version == 3 then
		vars.Arena = {
			SimpleMode = mini:CopyTable(vars.SimpleMode),
			AdvancedMode = mini:CopyTable(vars.AdvancedMode),
			Icons = mini:CopyTable(vars.Icons),
			Enabled = true,
			ExcludePlayer = vars.ExcludePlayer,
		}

		vars.BattleGrounds = {
			SimpleMode = mini:CopyTable(vars.SimpleMode),
			AdvancedMode = mini:CopyTable(vars.AdvancedMode),
			Icons = mini:CopyTable(vars.Icons),
			Enabled = not vars.ArenaOnly,
			ExcludePlayer = vars.ExcludePlayer,
		}

		vars.Default = {
			SimpleMode = mini:CopyTable(vars.SimpleMode),
			AdvancedMode = mini:CopyTable(vars.AdvancedMode),
			Icons = mini:CopyTable(vars.Icons),
			Enabled = not vars.ArenaOnly,
			ExcludePlayer = vars.ExcludePlayer,
		}

		mini:CleanTable(db, dbDefaults, true, true)
		vars.Version = 4
	end

	if vars.Version == 4 then
		vars.Raid = vars.BattleGrounds
		vars.BattleGrounds = nil

		vars.Default = vars.Arena
		vars.Arena = nil
		mini:CleanTable(db, dbDefaults, true, true)
		vars.Version = 5
	end

	if vars.Version == 5 then
		if vars.Anchor1 == "CompactPartyFrameMember1" then
			vars.Anchor1 = ""
		end
		if vars.Anchor2 == "CompactPartyFrameMember2" then
			vars.Anchor2 = ""
		end
		if vars.Anchor3 == "CompactPartyFrameMember3" then
			vars.Anchor3 = ""
		end

		vars.NotifiedChanges = false
		vars.Version = 6
	end

	if vars.Version == 6 then
		vars.NotifiedChanges = false
		vars.Version = 7
	end

	if vars.Version == 7 then
		vars.NotifiedChanges = false
		vars.Version = 8
	end

	if vars.Version == 8 then
		vars.NotifiedChanges = false
		vars.WhatsNew = vars.WhatsNew or {}
		table.insert(vars.WhatsNew, " - New spell alerts bar that shows enemy cooldowns.")
		vars.Version = 9
	end

	if vars.Version == 9 then
		vars.WhatsNew = vars.WhatsNew or {}
		table.insert(vars.WhatsNew, " - New feature to show enemy cooldowns on nameplates.")
		vars.NotifiedChanges = false
		vars.Version = 10
	end

	if vars.Version == 10 then
		-- they may not have the nameplates table yet if upgrading from say v8
		if vars.Nameplates then
			vars.Nameplates.FriendlyEnabled = vars.Nameplates.Enabled
			vars.Nameplates.EnemyEnabled = vars.Nameplates.Enabled
		end
		vars.Version = 11
	end

	if vars.Version == 11 then
		-- get the new nameplate config
		vars = mini:GetSavedVars(dbDefaults)

		vars.Nameplates.Friendly.CC.Enabled = vars.Nameplates.FriendlyEnabled
		vars.Nameplates.Friendly.Important.Enabled = vars.Nameplates.FriendlyEnabled

		vars.Nameplates.Enemy.CC.Enabled = vars.Nameplates.EnemyEnabled
		vars.Nameplates.Enemy.Important.Enabled = vars.Nameplates.EnemyEnabled

		table.insert(vars.WhatsNew, " - Separated CC and important spell positions on nameplates.")
		vars.NotifiedChanges = false

		-- clean up old values
		mini:CleanTable(db, dbDefaults, true, true)
		vars.Version = 12
	end

	if vars.Version == 12 then
		table.insert(vars.WhatsNew, " - New poor man's kick timer (don't get too excited, it's really basic).")
		table.insert(vars.WhatsNew, " - Various bug fixes and performance improvements.")
		vars.NotifiedChanges = false
		vars.Version = 13
	end

	if vars.Version == 13 then
		table.insert(vars.WhatsNew, " - Added pet portrait CC icon.")
		vars.NotifiedChanges = false
		vars.Version = 14
	end

	if vars.Version == 14 then
		table.insert(vars.WhatsNew, " - Improved kick detection logic (can now detect who kicked you).")
		table.insert(vars.WhatsNew, " - Added party trinkets tracker.")
		table.insert(vars.WhatsNew, " - Added Shadowed Unit Frames and Plexus frames support.")
		table.insert(vars.WhatsNew, " - Improved addon performance.")
		vars.NotifiedChanges = false
		vars.Version = 15
	end

	vars = mini:GetSavedVars(dbDefaults)

	return vars
end

function config:Apply()
	if InCombatLockdown() then
		mini:Notify("Can't apply settings during combat.")
		return
	end

	addon:Refresh()
end

function config:Init()
	db = GetAndUpgradeDb()

	local scroll = CreateFrame("ScrollFrame", nil, nil, "UIPanelScrollFrameTemplate")
	scroll.name = addonName

	local category = mini:AddCategory(scroll)

	if not category then
		return
	end

	local panel = CreateFrame("Frame", nil, scroll)
	local width, height = mini:SettingsSize()

	panel:SetWidth(width)
	panel:SetHeight(height)

	scroll:SetScrollChild(panel)

	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(scrollSelf, delta)
		local step = 20

		local current = scrollSelf:GetVerticalScroll()
		local max = scrollSelf:GetVerticalScrollRange()

		if delta > 0 then
			scrollSelf:SetVerticalScroll(math.max(current - step, 0))
		else
			scrollSelf:SetVerticalScroll(math.min(current + step, max))
		end
	end)

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
	title:SetPoint("TOPLEFT", 0, -verticalSpacing)
	title:SetText(string.format("%s - %s", addonName, version))

	local lines = mini:TextBlock({
		Parent = panel,
		Lines = {
			"Shows CC and other important spell alerts for pvp.",
		},
	})

	lines:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)

	local tabsPanel = CreateFrame("Frame", nil, panel)
	tabsPanel:SetPoint("TOPLEFT", lines, "BOTTOMLEFT", 0, -verticalSpacing)
	tabsPanel:SetPoint("BOTTOM", panel, "BOTTOM", 0, verticalSpacing * 2)

	local keys = {
		General = "General",
		Default = "Default",
		Raids = "Raids",
		Alerts = "Alerts",
		Healer = "Healer",
		Nameplates = "Nameplates",
	}

	local tabs = {
		{
			Key = keys.General,
			Title = "General",
			Build = function(content)
				config.General:Build(content)
			end,
		},
		{
			Key = keys.Default,
			Title = "Arena/Default",
			Build = function(content)
				config.Instance:Build(content, db.Default)
			end,
		},
		{
			Key = keys.Raids,
			Title = "BGs/Raids",
			Build = function(content)
				config.Instance:Build(content, db.Raid)
			end,
		},
		{
			Key = keys.Alerts,
			Title = "Alerts",
			Build = function(content)
				config.Alerts:Build(content, db.Alerts)
			end,
		},
		{
			Key = keys.Healer,
			Title = "Healer",
			Build = function(content)
				config.Healer:Build(content, db.Healer)
			end,
		},
		{
			Key = keys.Nameplates,
			Title = "Nameplates",
			Build = function(content)
				config.Nameplates:Build(content, db.Nameplates)
			end,
		},
	}

	local tabController = mini:CreateTabs({
		Parent = tabsPanel,
		InitialKey = "general",
		ContentInsets = {
			Top = verticalSpacing,
		},
		Tabs = tabs,
		OnTabChanged = function(key, _)
			-- swap the test options when the user changes tabs in case we're in test mode already
			if key == keys.Raids then
				addon:TestOptions(db.Raid)
			elseif key == keys.Default then
				addon:TestOptions(db.Default)
			end
		end,
	})

	local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	testBtn:SetSize(120, 26)
	testBtn:SetPoint("RIGHT", panel, "RIGHT", -horizontalSpacing, 0)
	testBtn:SetPoint("TOP", title, "TOP", 0, 0)
	testBtn:SetText("Test")
	testBtn:SetScript("OnClick", function()
		local options = db.Default

		local selectedTab = tabController:GetSelected()
		if selectedTab == keys.Raids then
			options = db.Raid
		end

		addon:ToggleTest(options)
	end)

	config.TabController = tabController

	StaticPopupDialogs["MINICC_CONFIRM"] = {
		text = "%s",
		button1 = YES,
		button2 = NO,
		OnAccept = function(_, data)
			if data and data.OnYes then
				data.OnYes()
			end
		end,
		OnCancel = function(_, data)
			if data and data.OnNo then
				data.OnNo()
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	SLASH_MINICC1 = "/minicc"
	SLASH_MINICC2 = "/mcc"
	SLASH_MINICC3 = "/cc"

	SlashCmdList.MINICC = function(msg)
		-- normalize input
		msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""

		if msg == "test" then
			addon:ToggleTest(db.Default)
			return
		end

		mini:OpenSettings(category, panel)
	end

	local kickTimerPanel = config.KickTimer:Build()
	kickTimerPanel.name = "Kick Timer"

	mini:AddSubCategory(category, kickTimerPanel)

	local trinketsPanel = config.Trinkets:Build()
	trinketsPanel.name = "Trinkets"

	mini:AddSubCategory(category, trinketsPanel)
end

---@class Config
---@field Init fun(self: table)
---@field Apply fun(self: table)
---@field DbDefaults Db
---@field TabController TabReturn
---@field General GeneralConfig
---@field Instance InstanceConfig
---@field Anchors AnchorsConfig
---@field Healer HealerConfig
---@field Alerts AlertsConfig
---@field Nameplates NameplatesConfig
---@field KickTimer KickTimerConfig
---@field Trinkets TrinketsConfig

---@class HeaderOptions
---@field Enabled boolean
---@field ExcludePlayer boolean

---@class IconOptions
---@field Size number?
---@field Glow boolean?
---@field ReverseCooldown boolean?
---@field ColorByDispelType boolean?
