---@type string, Addon
local _, addon = ...
local mini = addon.Core.Framework
local verticalSpacing = mini.VerticalSpacing
local config = addon.Config

---@class KickTimerConfig
local M = {}

config.KickTimer = M

function M:Build()
	local db = mini:GetSavedVars()
	local columns = 3
	local columnWidth = mini:ColumnWidth(columns, 0, 0)
	local horizontalSpacing = mini.HorizontalSpacing

	local panel = CreateFrame("Frame")
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 0, -verticalSpacing)
	title:SetText("Kick timer")

	local text = mini:TextLine({
		Parent = panel,
		Text = "Enable if you are:",
	})

	text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -verticalSpacing)

	local healerEnabled = mini:Checkbox({
		Parent = panel,
		LabelText = "Healer",
		Tooltip = "Whether to enable or disable this module if you are a healer.",
		GetValue = function()
			return db.KickTimer.HealerEnabled
		end,
		SetValue = function(value)
			db.KickTimer.HealerEnabled = value
			config:Apply()
		end,
	})

	healerEnabled:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -verticalSpacing)

	local casterEnabled = mini:Checkbox({
		Parent = panel,
		LabelText = "Caster",
		Tooltip = "Whether to enable or disable this module if you are a caster.",
		GetValue = function()
			return db.KickTimer.CasterEnabled
		end,
		SetValue = function(value)
			db.KickTimer.CasterEnabled = value
			config:Apply()
		end,
	})

	casterEnabled:SetPoint("LEFT", panel, "LEFT", columnWidth, 0)
	casterEnabled:SetPoint("TOP", healerEnabled, "TOP", 0, o)

	local allEnabled = mini:Checkbox({
		Parent = panel,
		LabelText = "Any",
		Tooltip = "Whether to enable or disable this module regardless of what spec you are.",
		GetValue = function()
			return db.KickTimer.AllEnabled
		end,
		SetValue = function(value)
			db.KickTimer.AllEnabled = value
			config:Apply()
		end,
	})

	allEnabled:SetPoint("LEFT", panel, "LEFT", columnWidth * 2, 0)
	allEnabled:SetPoint("TOP", healerEnabled, "TOP", 0, 0)

	local iconSizeSlider = mini:Slider({
		Parent = panel,
		LabelText = "Icon Size",
		GetValue = function()
			return db.KickTimer.Icons.Size
		end,
		SetValue = function(value)
			db.KickTimer.Icons.Size = mini:ClampInt(value, 20, 120, 50)
			config:Apply()
		end,
		Width = columns * columnWidth - horizontalSpacing,
		Min = 20,
		Max = 120,
		Step = 1,
	})

	iconSizeSlider.Slider:SetPoint("TOPLEFT", healerEnabled, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local important = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	important:SetPoint("TOPLEFT", iconSizeSlider.Slider, "BOTTOMLEFT", 0, -verticalSpacing * 2)
	important:SetText("Important Notes")

	local lines = mini:TextBlock({
		Parent = panel,
		Lines = {
			"It's not great, it's arguably not even good, but it's better than nothing.",
			"How does it work? It guesses who kicked you by correlating enemy action events against interrupt events.",
			"For example you are facing 3 enemies who are all pressing buttons.",
			"You just got kicked and the last enemy who successfully landed a spell was enemy A, therefore we deduce it was enemy A who kicked you.",
			"As you can tell it's not guaranteed to be accurate, but so far from our testing it's pretty damn good with ancedotally a 95%+ success rate.",
			"",
			"Limitations:",
			" - Doesn't work if the enemy misses kick (still investigating potential workaround/solution).",
			" - Currently only works inside arena (doesn't work in duels/world, will add this later).",
			"",
			"Still working on improving this, so stay tuned for updates.",
		},
	})

	lines:SetPoint("TOPLEFT", important, "BOTTOMLEFT", 0, -verticalSpacing)

	local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	testBtn:SetSize(120, 26)
	testBtn:SetPoint("RIGHT", panel, "RIGHT", -horizontalSpacing, 0)
	testBtn:SetPoint("TOP", title, "TOP", 0, 0)
	testBtn:SetText("Test")
	testBtn:SetScript("OnClick", function()
		local options = db.Default

		addon:ToggleTest(options)
	end)

	return panel
end
