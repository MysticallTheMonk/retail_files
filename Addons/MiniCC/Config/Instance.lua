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

---@class InstanceConfig
local M = {}

config.Instance = M

---@param parent table
---@param options InstanceOptions
local function BuildAnchorSettings(parent, options)
	local panel = CreateFrame("Frame", nil, parent)

	local growDdlLbl = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	growDdlLbl:SetText("Grow")

	local growDdl, modernDdl = mini:Dropdown({
		Parent = panel,
		Items = growOptions,
		Width = columnWidth * 2 - horizontalSpacing,
		GetValue = function()
			return options.SimpleMode.Grow
		end,
		SetValue = function(value)
			options.SimpleMode.Enabled = true

			if options.SimpleMode.Grow ~= value then
				options.SimpleMode.Grow = value
				config:Apply()
			end
		end,
	})

	growDdl:SetWidth(dropdownWidth)
	growDdlLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
	growDdl:SetPoint("TOPLEFT", growDdlLbl, "BOTTOMLEFT", modernDdl and 0 or -16, -8)

	local containerX = mini:Slider({
		Parent = panel,
		Min = -250,
		Max = 250,
		Step = 1,
		Width = columnWidth * 2 - horizontalSpacing,
		LabelText = "Offset X",
		GetValue = function()
			return options.SimpleMode.Offset.X
		end,
		SetValue = function(v)
			options.SimpleMode.Enabled = true
			options.SimpleMode.Offset.X = mini:ClampInt(v, -250, 250, 0)
			config:Apply()
		end,
	})

	containerX.Slider:SetPoint("TOPLEFT", growDdl, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local containerY = mini:Slider({
		Parent = panel,
		Min = -250,
		Max = 250,
		Step = 1,
		Width = columnWidth * 2 - horizontalSpacing,
		LabelText = "Offset Y",
		GetValue = function()
			return options.SimpleMode.Offset.Y
		end,
		SetValue = function(v)
			options.SimpleMode.Enabled = true
			options.SimpleMode.Offset.Y = mini:ClampInt(v, -250, 250, 0)
			config:Apply()
		end,
	})

	containerY.Slider:SetPoint("LEFT", containerX.Slider, "RIGHT", horizontalSpacing, 0)

	panel:SetHeight(containerX.Slider:GetHeight() + growDdl:GetHeight() + growDdlLbl:GetHeight() + verticalSpacing * 3)

	return panel
end

---@param panel table
---@param options InstanceOptions
function M:Build(panel, options)
	local anchorPanel = BuildAnchorSettings(panel, options)

	local enabledChk = mini:Checkbox({
		Parent = panel,
		LabelText = "Enabled",
		Tooltip = "Whether to enable or disable this module.",
		GetValue = function()
			return options.Enabled
		end,
		SetValue = function(value)
			options.Enabled = value

			config:Apply()
		end,
	})

	enabledChk:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)

	local excludePlayerChk = mini:Checkbox({
		Parent = panel,
		LabelText = "Exclude self",
		Tooltip = "Exclude yourself from showing CC icons.",
		GetValue = function()
			return options.ExcludePlayer
		end,
		SetValue = function(value)
			options.ExcludePlayer = value
			addon:Refresh()
		end,
	})

	excludePlayerChk:SetPoint("LEFT", panel, "LEFT", columnWidth, 0)
	excludePlayerChk:SetPoint("TOP", enabledChk, "TOP", 0, 0)

	local glowChk = mini:Checkbox({
		Parent = panel,
		LabelText = "Glow icons",
		Tooltip = "Show a glow around the CC icons.",
		GetValue = function()
			return options.Icons.Glow
		end,
		SetValue = function(value)
			options.Icons.Glow = value
			config:Apply()
		end,
	})

	glowChk:SetPoint("LEFT", panel, "LEFT", columnWidth * 2, 0)
	glowChk:SetPoint("TOP", enabledChk, "TOP", 0, 0)

	local reverseChk = mini:Checkbox({
		Parent = panel,
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

	reverseChk:SetPoint("LEFT", panel, "LEFT", columnWidth * 3, 0)
	reverseChk:SetPoint("TOP", enabledChk, "TOP", 0, 0)

	local dispelColoursChk = mini:Checkbox({
		Parent = panel,
		LabelText = "Dispel colours",
		Tooltip = "Change the colour of the glow based on the type of debuff.",
		GetValue = function()
			return options.Icons.ColorByDispelType
		end,
		SetValue = function(value)
			options.Icons.ColorByDispelType = value
			config:Apply()
		end,
	})

	dispelColoursChk:SetPoint("TOPLEFT", enabledChk, "BOTTOMLEFT", 0, -verticalSpacing)

	local iconSize = mini:Slider({
		Parent = panel,
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

	iconSize.Slider:SetPoint("TOPLEFT", dispelColoursChk, "BOTTOMLEFT", 4, -verticalSpacing * 3)

	anchorPanel:SetPoint("TOPLEFT", iconSize.Slider, "BOTTOMLEFT", 0, -verticalSpacing * 2)
	anchorPanel:SetPoint("TOPRIGHT", iconSize.Slider, "BOTTOMRIGHT", 0, -verticalSpacing * 2)

	panel:HookScript("OnShow", function()
		panel:MiniRefresh()
		addon:TestOptions(options)
	end)

	panel.OnMiniRefresh = function()
		anchorPanel:MiniRefresh()
	end
end
