---@type string, Addon
local _, addon = ...
local mini = addon.Core.Framework
local verticalSpacing = mini.VerticalSpacing
local columns = 4
local columnWidth = mini:ColumnWidth(columns, 0, 0)
local config = addon.Config
---@type Db
local db

---@class AnchorsConfig
local M = {}

config.Anchors = M

function M:Build(panel)
	db = mini:GetSavedVars()

	local description = mini:TextBlock({
		Parent = panel,
		Lines = {
			"You can /fstack to find the name of your addon's frames, then enter them here.",
		},
	})

	description:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)

	local anchorWidth = columnWidth * 3
	local anchor1 = mini:EditBox({
		Parent = panel,
		LabelText = "Anchor1 Frame",
		Width = anchorWidth,
		GetValue = function()
			return tostring(db.Anchor1)
		end,
		SetValue = function(v)
			db.Anchor1 = tostring(v)
			config:Apply()
		end,
	})

	anchor1.Label:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -verticalSpacing)
	anchor1.EditBox:SetPoint("TOPLEFT", anchor1.Label, "BOTTOMLEFT", 4, -8)

	local anchor2 = mini:EditBox({
		Parent = panel,

		LabelText = "Anchor2 Frame",
		Width = anchorWidth,
		GetValue = function()
			return tostring(db.Anchor2)
		end,
		SetValue = function(v)
			db.Anchor2 = tostring(v)
			config:Apply()
		end,
	})

	anchor2.Label:SetPoint("TOPLEFT", anchor1.EditBox, "BOTTOMLEFT", -4, -verticalSpacing)
	anchor2.EditBox:SetPoint("TOPLEFT", anchor2.Label, "BOTTOMLEFT", 4, -8)

	local anchor3 = mini:EditBox({
		Parent = panel,

		LabelText = "Anchor3 Frame",
		Width = anchorWidth,
		GetValue = function()
			return tostring(db.Anchor3)
		end,
		SetValue = function(v)
			db.Anchor3 = tostring(v)
			config:Apply()
		end,
	})

	anchor3.Label:SetPoint("TOPLEFT", anchor2.EditBox, "BOTTOMLEFT", -4, -verticalSpacing)
	anchor3.EditBox:SetPoint("TOPLEFT", anchor3.Label, "BOTTOMLEFT", 4, -8)
end
