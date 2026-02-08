---@type string, Addon
local _, addon = ...
local capabilities = addon.Capabilities
local mini = addon.Core.Framework
local unitWatcher = addon.Core.UnitAuraWatcher
local iconSlotContainer = addon.Core.IconSlotContainer
local paused = false
local inPrepRoom = false
local eventsFrame
---@type Db
local db
---@type IconSlotContainer
local container
---@type Watcher[]
local watchers

---@class AlertsModule : IModule
local M = {}
addon.Modules.AlertsModule = M

local function OnAuraDataChanged()
	if paused then
		return
	end

	if not db.Alerts.Enabled then
		return
	end

	if inPrepRoom then
		-- don't know why it picks up garbage in the starting room
		container:ResetAllSlots()
		return
	end

	local slot = 0

	for _, watcher in ipairs(watchers) do
		local unit = watcher:GetUnit()

		-- when rogues go stealth, we can't get their aura data anymore
		if unit and UnitExists(unit) then
			local importantData = watcher:GetImportantState()

			if slot > container.Count then
				break
			end

			if #importantData > 0 then
				if capabilities:HasNewFilters() then
					for _, data in ipairs(importantData) do
						slot = slot + 1
						container:ClearSlot(slot)
						container:SetSlotUsed(slot)
						container:SetLayer(
							slot,
							1,
							data.SpellIcon,
							data.StartTime,
							data.TotalDuration,
							data.IsImportant,
							db.Alerts.Icons.Glow,
							db.Alerts.Icons.ReverseCooldown
						)

						container:FinalizeSlot(slot, 1)
					end
				else
					slot = slot + 1
					container:ClearSlot(slot)
					container:SetSlotUsed(slot)

					local used = 0
					for _, data in ipairs(importantData) do
						used = used + 1
						container:SetLayer(
							slot,
							used,
							data.SpellIcon,
							data.StartTime,
							data.TotalDuration,
							data.IsImportant,
							db.Alerts.Icons.Glow,
							db.Alerts.Icons.ReverseCooldown
						)
					end

					container:FinalizeSlot(slot, used)
				end
			end
		end
	end

	-- advance forward by 1 for clearing
	if slot > 0 then
		slot = slot + 1
	end

	if slot == 0 then
		container:ResetAllSlots()
	else
		-- clear any slots above what we used
		for i = slot, container.Count do
			container:SetSlotUnused(i)
		end
	end
end

local function OnMatchStateChanged()
	local matchState = C_PvP.GetActiveMatchState()

	inPrepRoom = matchState == Enum.PvPMatchState.StartUp

	if not inPrepRoom then
		return
	end

	for _, watcher in ipairs(watchers) do
		watcher:ClearState(true)
	end

	container:ResetAllSlots()
end

local function EnableDisable()
	local options = db.Alerts

	if options.Enabled then
		for _, watcher in ipairs(watchers) do
			watcher:Enable()
		end

		OnAuraDataChanged()
	else
		for _, watcher in ipairs(watchers) do
			watcher:Disable()
		end
	end
end

function M:GetAnchor()
	return container
end

function M:ClearAll()
	if not container then
		return
	end

	container:ResetAllSlots()
end

function M:Refresh()
	local options = db.Alerts

	container.Frame:ClearAllPoints()
	container.Frame:SetPoint(
		options.Point,
		_G[options.RelativeTo] or UIParent,
		options.RelativePoint,
		options.Offset.X,
		options.Offset.Y
	)

	container:SetIconSize(db.Alerts.Icons.Size)

	EnableDisable()
end

function M:Pause()
	paused = true
end

function M:Resume()
	paused = false
	OnAuraDataChanged()
end

function M:Init()
	db = mini:GetSavedVars()

	local options = db.Alerts
	local count = 3
	local size = options.Icons.Size

	container = iconSlotContainer:New(UIParent, count, size, 2)
	container.Frame:SetIgnoreParentScale(true)

	local initialRelativeTo = _G[options.RelativeTo] or UIParent
	container.Frame:SetPoint(
		options.Point,
		initialRelativeTo,
		options.RelativePoint,
		options.Offset.X,
		options.Offset.Y
	)
	container.Frame:SetFrameStrata("HIGH")
	container.Frame:SetFrameLevel((initialRelativeTo:GetFrameLevel() or 0) + 5)
	container.Frame:EnableMouse(false)
	container.Frame:SetMovable(false)
	container.Frame:RegisterForDrag("LeftButton")
	container.Frame:SetScript("OnDragStart", function(anchorSelf)
		anchorSelf:StartMoving()
	end)
	container.Frame:SetScript("OnDragStop", function(anchorSelf)
		anchorSelf:StopMovingOrSizing()

		local point, relativeTo, relativePoint, x, y = anchorSelf:GetPoint()
		options.Point = point
		options.RelativePoint = relativePoint
		options.RelativeTo = (relativeTo and relativeTo:GetName()) or "UIParent"
		options.Offset.X = x
		options.Offset.Y = y
	end)
	container.Frame:Show()

	local events = {
		-- seen/unseen
		"ARENA_OPPONENT_UPDATE",
	}

	watchers = {
		unitWatcher:New("arena1", events),
		unitWatcher:New("arena2", events),
		unitWatcher:New("arena3", events),
	}

	container:SetCount(#watchers)

	for _, watcher in ipairs(watchers) do
		watcher:RegisterCallback(OnAuraDataChanged)
	end

	eventsFrame = CreateFrame("Frame")
	eventsFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
	eventsFrame:SetScript("OnEvent", OnMatchStateChanged)

	EnableDisable()
end
