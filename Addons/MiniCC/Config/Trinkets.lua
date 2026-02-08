---@type string, Addon
local _, addon = ...
local mini = addon.Core.Framework
local verticalSpacing = mini.VerticalSpacing
local horizontalSpacing = mini.HorizontalSpacing
local config = addon.Config

---@class TrinketsConfig
local M = {}

config.Trinkets = M

function M:Build()
	local db = mini:GetSavedVars()
	local columns = 3
	local columnWidth = mini:ColumnWidth(columns, 0, 0)

	local panel = CreateFrame("Frame")
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 0, -verticalSpacing)
	title:SetText("Party Trinkets")

	local enabled = mini:Checkbox({
		Parent = panel,
		LabelText = "Enabled",
		Tooltip = "Whether to enable or disable this module.",
		GetValue = function()
			return db.Trinkets.Enabled
		end,
		SetValue = function(value)
			db.Trinkets.Enabled = value
			config:Apply()
		end,
	})

	enabled:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -verticalSpacing)

	local iconSizeSlider = mini:Slider({
		Parent = panel,
		LabelText = "Icon Size",
		GetValue = function()
			return db.Trinkets.Icons.Size
		end,
		SetValue = function(value)
			db.Trinkets.Icons.Size = mini:ClampInt(value, 20, 120, 50)
			config:Apply()
		end,
		Width = columns * columnWidth - horizontalSpacing,
		Min = 20,
		Max = 120,
		Step = 1,
	})

	iconSizeSlider.Slider:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local offsetXSlider = mini:Slider({
		Parent = panel,
		LabelText = "Offset X",
		GetValue = function()
			return db.Trinkets.Offset.X
		end,
		SetValue = function(value)
			db.Trinkets.Offset.X = mini:ClampInt(value, -200, 200, 0)
			config:Apply()
		end,
		Width = (columns / 2) * columnWidth - horizontalSpacing,
		Min = -200,
		Max = 200,
		Step = 1,
	})

	offsetXSlider.Slider:SetPoint("TOPLEFT", iconSizeSlider.Slider, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local offsetYSlider = mini:Slider({
		Parent = panel,
		LabelText = "Offset Y",
		GetValue = function()
			return db.Trinkets.Offset.Y
		end,
		SetValue = function(value)
			db.Trinkets.Offset.Y = mini:ClampInt(value, -200, 200, 0)
			config:Apply()
		end,
		Width = (columns / 2) * columnWidth - horizontalSpacing,
		Min = -200,
		Max = 200,
		Step = 1,
	})

	offsetYSlider.Slider:SetPoint("LEFT", offsetXSlider.Slider, "RIGHT", horizontalSpacing, 0)

	local lines = mini:TextBlock({
		Parent = panel,
		Lines = {
			"Limitations:",
			" - Doesn't work if your team mates trinket in the starting room.",
			" - Doesn't work in the open world.",
		},
	})

	lines:SetPoint("TOPLEFT", offsetXSlider.Slider, "BOTTOMLEFT", 0, -verticalSpacing * 2)

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
