---@type string, Addon
local _, addon = ...
local mini = addon.Core.Framework
local scheduler = addon.Utils.Scheduler
local frames = addon.Core.Frames
local eventsFrame
local db
local auras = addon.Core.CcHeader
---@type InstanceOptions|nil
local currentInstanceOptions
---@type table<table, table>
local headers = {}
---@class CcModule : IModule
local M = {}

addon.Modules.CcModule = M

local function GetInstanceOptions()
	local inInstance, instanceType = IsInInstance()
	local isBgOrRaid = inInstance and (instanceType == "pvp" or instanceType == "raid")
	return isBgOrRaid and db.Raid or db.Default
end

local function OnCufUpdateVisible(frame)
	if not frame or not frames:IsFriendlyCuf(frame) then
		return
	end

	local header = headers[frame]

	if not header then
		return
	end

	scheduler:RunWhenCombatEnds(function()
		local instanceOptions = M:GetCurrentInstanceOptions()

		if not instanceOptions then
			return
		end

		frames:ShowHideFrame(header, frame, false, instanceOptions)
	end)
end

local function OnCufSetUnit(frame, unit)
	if not frame or not frames:IsFriendlyCuf(frame) then
		return
	end

	if not unit then
		return
	end

	scheduler:RunWhenCombatEnds(function()
		M:EnsureHeader(frame, unit)
	end)
end

local function OnFrameSortSorted()
	M:Refresh()
end

local function OnEvent(_, event)
	if event == "GROUP_ROSTER_UPDATE" then
		M:Refresh()
	end
end

function M:GetHeaders()
	return headers
end

---@return InstanceOptions|nil
function M:GetCurrentInstanceOptions()
	return currentInstanceOptions
end

function M:RefreshInstanceOptions()
	currentInstanceOptions = GetInstanceOptions()

	return currentInstanceOptions
end

---@param header table
---@param anchor table
---@param options InstanceOptions
function M:AnchorHeader(header, anchor, options)
	if not options then
		return
	end

	header:ClearAllPoints()
	header:SetIgnoreParentAlpha(true)
	header:SetAlpha(1)
	header:SetFrameLevel(anchor:GetFrameLevel() + 1)
	header:SetFrameStrata("HIGH")

	if options.SimpleMode.Enabled then
		local anchorPoint = "CENTER"
		local relativeToPoint = "CENTER"

		if options.SimpleMode.Grow == "LEFT" then
			anchorPoint = "RIGHT"
			relativeToPoint = "LEFT"
		elseif options.SimpleMode.Grow == "RIGHT" then
			anchorPoint = "LEFT"
			relativeToPoint = "RIGHT"
		end
		header:SetPoint(anchorPoint, anchor, relativeToPoint, options.SimpleMode.Offset.X, options.SimpleMode.Offset.Y)
	elseif options.AdvancedMode then
		header:SetPoint(
			options.AdvancedMode.Point,
			anchor,
			options.AdvancedMode.RelativePoint,
			options.AdvancedMode.Offset.X,
			options.AdvancedMode.Offset.Y
		)
	end
end

---@param anchor table
---@param unit string?
function M:EnsureHeader(anchor, unit)
	unit = unit or anchor.unit or anchor:GetAttribute("unit")
	if not unit then
		return nil
	end

	local options = currentInstanceOptions

	if not options then
		return
	end

	local header = headers[anchor]

	if not header then
		header = auras:New(unit, options.Icons)
		headers[anchor] = header
	else
		auras:Update(header, unit, options.Icons)
	end

	self:AnchorHeader(header, anchor, options)
	frames:ShowHideFrame(header, anchor, false, options)

	return header
end

function M:EnsureHeaders()
	local anchors = frames:GetAll(true)

	for _, anchor in ipairs(anchors) do
		M:EnsureHeader(anchor)
	end
end

function M:HideHeaders()
	for _, header in pairs(headers) do
		header:Hide()
	end
end

function M:Refresh()
	if InCombatLockdown() then
		scheduler:RunWhenCombatEnds(function()
			M:Refresh()
		end, "CcModuleRefresh")
		return
	end

	local options = M:RefreshInstanceOptions()

	if not options then
		return
	end

	M:EnsureHeaders()

	for anchor, header in pairs(headers) do
		local unit = header:GetAttribute("unit") or anchor.unit or anchor:GetAttribute("unit")

		if unit then
			auras:Update(header, unit, options.Icons)
		end

		M:AnchorHeader(header, anchor, options)
		frames:ShowHideFrame(header, anchor, false, options)
	end
end

function M:Pause()
	-- this module doesn't support pausing
end

function M:Resume() end

function M:Init()
	db = mini:GetSavedVars()

	eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", OnEvent)
	eventsFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

	if CompactUnitFrame_SetUnit then
		hooksecurefunc("CompactUnitFrame_SetUnit", OnCufSetUnit)
	end

	if CompactUnitFrame_UpdateVisible then
		hooksecurefunc("CompactUnitFrame_UpdateVisible", OnCufUpdateVisible)
	end

	local fs = FrameSortApi and FrameSortApi.v3
	if fs and fs.Sorting and fs.Sorting.RegisterPostSortCallback then
		fs.Sorting:RegisterPostSortCallback(OnFrameSortSorted)
	end

	M:RefreshInstanceOptions()
	M:EnsureHeaders()
end
