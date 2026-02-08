---@type string, Addon
local _, addon = ...
local mini = addon.Core.Framework
local dropdownWidth = 200
local growOptions = {
	"LEFT",
	"RIGHT",
	"CENTER",
}
local verticalSpacing = mini.VerticalSpacing
local horizontalSpacing = mini.HorizontalSpacing
local columns = 4
local columnWidth = mini:ColumnWidth(columns, 0, 0)
local config = addon.Config

---@class NameplatesConfig
local M = {}

config.Nameplates = M

---@param parent table
---@param options NameplateSpellTypeOptions
---@return table bottom left anchor
local function BuildSpellTypeSettings(parent, anchor, options)
	local container = CreateFrame("Frame", nil, parent)

	local function SetEnabled()
		container:SetHeight(250)

		if options.Enabled then
			container:Show()
		else
			container:Hide()
			-- kinda dodgy, but it works
			container:SetHeight(1)
		end
	end

	local enabled = mini:Checkbox({
		Parent = parent,
		LabelText = "Enabled",
		Tooltip = "Whether to enable or disable this type.",
		GetValue = function()
			return options.Enabled
		end,
		SetValue = function(value)
			options.Enabled = value
			SetEnabled()
			config:Apply()
		end,
	})

	enabled:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing)

	container:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 0, -verticalSpacing)
	container:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

	SetEnabled()

	local glowChk = mini:Checkbox({
		Parent = container,
		LabelText = "Glow icons",
		Tooltip = "Show a glow around the icons.",
		GetValue = function()
			return options.Icons.Glow
		end,
		SetValue = function(value)
			options.Icons.Glow = value
			config:Apply()
		end,
	})

	glowChk:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)

	local reverseChk = mini:Checkbox({
		Parent = container,
		LabelText = "Reverse swipe",
		Tooltip = "Reverses the direction of the cooldown swipe animation.",
		GetValue = function()
			return options.Icons.ReverseCooldown
		end,
		SetValue = function(value)
			options.Icons.ReverseCooldown = value
			config:Apply()
		end,
	})

	reverseChk:SetPoint("LEFT", glowChk, "LEFT", columnWidth, 0)

	local iconSize = mini:Slider({
		Parent = container,
		Min = 10,
		Max = 200,
		Width = (columnWidth * columns) - horizontalSpacing,
		Step = 1,
		LabelText = "Icon Size",
		GetValue = function()
			return options.Icons.Size
		end,
		SetValue = function(v)
			options.Icons.Size = mini:ClampInt(v, 10, 200, 32)
			config:Apply()
		end,
	})

	iconSize.Slider:SetPoint("TOPLEFT", glowChk, "BOTTOMLEFT", 4, -verticalSpacing * 3)

	local growDdlLbl = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	growDdlLbl:SetText("Grow")

	local growDdl, modernDdl = mini:Dropdown({
		Parent = container,
		Items = growOptions,
		Width = columnWidth * 2 - horizontalSpacing,
		GetValue = function()
			return options.Grow
		end,
		SetValue = function(value)
			if options.Grow ~= value then
				options.Grow = value
				config:Apply()
			end
		end,
	})

	growDdl:SetWidth(dropdownWidth)
	growDdlLbl:SetPoint("TOPLEFT", iconSize.Slider, "BOTTOMLEFT", 0, -verticalSpacing)
	growDdl:SetPoint("TOPLEFT", growDdlLbl, "BOTTOMLEFT", modernDdl and 0 or -16, -8)

	local containerX = mini:Slider({
		Parent = container,
		Min = -250,
		Max = 250,
		Step = 1,
		Width = columnWidth * 2 - horizontalSpacing,
		LabelText = "Offset X",
		GetValue = function()
			return options.Offset.X
		end,
		SetValue = function(v)
			options.Offset.X = mini:ClampInt(v, -250, 250, 0)
			config:Apply()
		end,
	})

	containerX.Slider:SetPoint("TOPLEFT", growDdl, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local containerY = mini:Slider({
		Parent = container,
		Min = -250,
		Max = 250,
		Step = 1,
		Width = columnWidth * 2 - horizontalSpacing,
		LabelText = "Offset Y",
		GetValue = function()
			return options.Offset.Y
		end,
		SetValue = function(v)
			options.Offset.Y = mini:ClampInt(v, -250, 250, 0)
			config:Apply()
		end,
	})

	containerY.Slider:SetPoint("LEFT", containerX.Slider, "RIGHT", horizontalSpacing, 0)

	return container
end

---@param parent table
---@param options NameplateOptions
function M:Build(parent, options)
	local enemyCCDivider = mini:Divider({
		Parent = parent,
		Text = "Enemy - CC",
	})

	enemyCCDivider:SetPoint("LEFT", parent, "LEFT", 0, 0)
	enemyCCDivider:SetPoint("RIGHT", parent, "RIGHT", -horizontalSpacing, 0)
	enemyCCDivider:SetPoint("TOP", parent, "TOP", 0, 0)

	local enemyCCPanel = BuildSpellTypeSettings(parent, enemyCCDivider, options.Enemy.CC)

	local enemyImportantDivider = mini:Divider({
		Parent = parent,
		Text = "Enemy - Important Spells",
	})
	enemyImportantDivider:SetPoint("LEFT", parent, "LEFT", 0, 0)
	enemyImportantDivider:SetPoint("RIGHT", parent, "RIGHT", -horizontalSpacing, 0)
	enemyImportantDivider:SetPoint("TOP", enemyCCPanel, "BOTTOM", 0, -verticalSpacing)

	local enemyImportantPanel = BuildSpellTypeSettings(parent, enemyImportantDivider, options.Enemy.Important)

	local friendlyCCDivider = mini:Divider({
		Parent = parent,
		Text = "Friendly - CC",
	})

	friendlyCCDivider:SetPoint("LEFT", parent, "LEFT", 0, 0)
	friendlyCCDivider:SetPoint("RIGHT", parent, "RIGHT", -horizontalSpacing, 0)
	friendlyCCDivider:SetPoint("TOP", enemyImportantPanel, "BOTTOM", 0, -verticalSpacing)

	local friendlyCCPanel = BuildSpellTypeSettings(parent, friendlyCCDivider, options.Friendly.CC)

	local friendlyImportantDivider = mini:Divider({
		Parent = parent,
		Text = "Friendly - Important Spells",
	})
	friendlyImportantDivider:SetPoint("LEFT", parent, "LEFT", 0, 0)
	friendlyImportantDivider:SetPoint("RIGHT", parent, "RIGHT", -horizontalSpacing, 0)
	friendlyImportantDivider:SetPoint("TOP", friendlyCCPanel, "BOTTOM", 0, -verticalSpacing)

	BuildSpellTypeSettings(parent, friendlyImportantDivider, options.Friendly.Important)
end
