---@type string, Addon
local _, addon = ...
local mini = addon.Core.Framework
local verticalSpacing = mini.VerticalSpacing
local horizontalSpacing = mini.HorizontalSpacing
---@type Db
local db
---@class GeneralConfig
local M = {}

addon.Config.General = M

function M:Build(panel)
	local columns = 4
	local columnStep = mini:ColumnWidth(columns, 0, 0)

	db = mini:GetSavedVars()

	local portraitDivider = mini:Divider({
		Parent = panel,
		Text = "Portrait Icons",
	})

	portraitDivider:SetPoint("LEFT", panel, "LEFT")
	portraitDivider:SetPoint("RIGHT", panel, "RIGHT", -horizontalSpacing, 0)
	portraitDivider:SetPoint("TOP", panel, "TOP", 0, 0)

	local portraitsChk = mini:Checkbox({
		Parent = panel,
		LabelText = "Portrait icons",
		Tooltip = "Shows CC, defensives, and other important spells on the player/target/focus portraits.",
		GetValue = function()
			return db.Portrait.Enabled
		end,
		SetValue = function(value)
			db.Portrait.Enabled = value
			addon.Config:Apply()
		end,
	})

	portraitsChk:SetPoint("TOPLEFT", portraitDivider, "BOTTOMLEFT", 0, -verticalSpacing)

	local reverseSweepChk = mini:Checkbox({
		Parent = panel,
		LabelText = "Reverse swipe",
		Tooltip = "Reverses the direction of the cooldown swipe.",
		GetValue = function()
			return db.Portrait.ReverseCooldown
		end,
		SetValue = function(value)
			db.Portrait.ReverseCooldown = value
			addon.Config:Apply()
		end,
	})

	reverseSweepChk:SetPoint("LEFT", panel, "LEFT", columnStep, -verticalSpacing)
	reverseSweepChk:SetPoint("TOP", portraitsChk, "TOP", 0, 0)

	local divider = mini:Divider({
		Parent = panel,
		Text = "Info",
	})

	divider:SetPoint("LEFT", panel, "LEFT")
	divider:SetPoint("RIGHT", panel, "RIGHT", -horizontalSpacing, 0)
	divider:SetPoint("TOP", reverseSweepChk, "BOTTOM", 0, -verticalSpacing)

	local lines = mini:TextBlock({
		Parent = panel,
		Lines = {
			"Supported addons:",
			"  - ElvUI, DandersFrames, Grid2, Shadowed Unit Frames, Plexus.",
			"",
			"Things that work on beta (12.0.1) that don't work on retail (12.0.0):",
			"  - Showing multiple/overlapping CC's.",
			"  - Healer in CC sound effect.",
			"  - More spells are shown on portraits.",
			"  - Hex and roots.",
			"",
			"Any feedback is more than welcome!",
		},
	})

	lines:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -verticalSpacing)

	local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetBtn:SetSize(120, 26)
	resetBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, verticalSpacing)
	resetBtn:SetText("Reset")
	resetBtn:SetScript("OnClick", function()
		if InCombatLockdown() then
			mini:NotifyCombatLockdown()
			return
		end

		StaticPopup_Show("MINICC_CONFIRM", "Are you sure you wish to reset to factory settings?", nil, {
			OnYes = function()
				db = mini:ResetSavedVars(addon.Config.DbDefaults)

				local tabController = addon.Config.TabController
				for i = 1, #tabController.Tabs do
					local content = tabController:GetContent(tabController.Tabs[i].Key)

					if content and content.MiniRefresh then
						content:MiniRefresh()
					end
				end

				addon:Refresh()
				mini:Notify("Settings reset to default.")
			end,
		})
	end)
end
