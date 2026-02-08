---@type string, Addon
local _, addon = ...
local mini = addon.Core.Framework
local array = addon.Utils.Array
local unitWatcher = addon.Core.UnitAuraWatcher
local iconSlotContainer = addon.Core.IconSlotContainer
local paused = false
local containers = {}
---@type { string: Watcher }
local watchers = {}
---@type Db
local db

---@class PortraitModule : IModule
local M = {}
addon.Modules.PortraitModule = M

local function AddMask(tex, mask)
	tex:AddMaskTexture(mask)
end

local function GetPortraitMask(unitFrame)
	-- player
	if unitFrame.PlayerFrameContainer and unitFrame.PlayerFrameContainer.PlayerPortraitMask then
		return unitFrame.PlayerFrameContainer.PlayerPortraitMask
	end

	-- target/focus
	if unitFrame.TargetFrameContainer and unitFrame.TargetFrameContainer.PortraitMask then
		return unitFrame.TargetFrameContainer.PortraitMask
	end

	-- target of target and pet frame
	if unitFrame.PortraitMask then
		return unitFrame.PortraitMask
	end

	return nil
end

local function ApplyMaskToLayer(layer, mask)
	if not layer then
		return
	end

	if layer.Icon then
		if mask then
			AddMask(layer.Icon, mask)
		end
		-- Crop the icon like Blizzard does
		layer.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	end

	if layer.Cooldown then
		-- Keep cooldown within the portrait icon
		layer.Cooldown:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
	end
end

local function CreateContainer(unitFrame, portrait)
	-- Only 1 slot, multiple layers
	local container = iconSlotContainer:New(unitFrame, 1, 0, 0)

	-- Position the container over the portrait with inset
	container.Frame:SetPoint("TOPLEFT", portrait, "TOPLEFT", 2, -2)
	container.Frame:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT", -2, 2)
	-- the icon slot container starts at +2
	container.Frame:SetFrameLevel(math.max(0, (unitFrame:GetFrameLevel() or 0) - 1))

	-- Set initial size to match portrait
	local width = portrait:GetWidth() - 4
	local height = portrait:GetHeight() - 4
	local size = math.min(width, height)
	container:SetIconSize(size)

	local mask = GetPortraitMask(unitFrame)

	-- Hook SetLayer to apply mask when layers are created
	local originalSetLayer = container.SetLayer
	container.SetLayer = function(
		self,
		slotIndex,
		layerIndex,
		texture,
		startTime,
		duration,
		alphaBoolean,
		glow,
		reverseCooldown
	)
		-- Call original SetLayer first
		originalSetLayer(self, slotIndex, layerIndex, texture, startTime, duration, alphaBoolean, glow, reverseCooldown)

		-- Apply mask to the layer that was just created/updated
		local slot = self.Slots[slotIndex]
		if slot and slot.Layers[layerIndex] then
			ApplyMaskToLayer(slot.Layers[layerIndex], mask)
		end
	end

	return container
end

---@param watcher Watcher
---@param container IconSlotContainer
local function OnAuraInfo(watcher, container)
	if paused then
		return
	end

	container:ResetAllSlots()

	local ccAuras = watcher:GetCcState()
	local importantAuras = watcher:GetImportantState()
	local defensiveAuras = watcher:GetDefensiveState()

	-- Reverse their order so we show latest spells
	array:Reverse(ccAuras)
	array:Reverse(importantAuras)
	array:Reverse(defensiveAuras)

	local slotIndex = 1
	local layerIndex = 1

	-- Process CC auras
	for _, aura in ipairs(ccAuras) do
		if aura.SpellIcon and aura.StartTime and aura.TotalDuration then
			container:SetSlotUsed(slotIndex)
			container:SetLayer(
				slotIndex,
				layerIndex,
				aura.SpellIcon,
				aura.StartTime,
				aura.TotalDuration,
				aura.IsCC, -- alphaBoolean
				false, -- glow
				db.Portrait.ReverseCooldown
			)

			if not issecretvalue(aura.IsCC) then
				-- we're in 12.0.1
				if aura.IsCC then
					container:FinalizeSlot(slotIndex, layerIndex)
					return
				end
			end

			layerIndex = layerIndex + 1
		end
	end

	-- Process defensive auras
	for _, aura in ipairs(defensiveAuras) do
		if aura.SpellIcon and aura.StartTime and aura.TotalDuration then
			container:SetSlotUsed(slotIndex)
			container:SetLayer(
				slotIndex,
				layerIndex,
				aura.SpellIcon,
				aura.StartTime,
				aura.TotalDuration,
				true, -- alphaBoolean (we only get defensives in 12.0.1)
				false, -- glow
				db.Portrait.ReverseCooldown
			)

			container:FinalizeSlot(slotIndex, layerIndex)
			return
		end
	end

	-- Process important auras
	for _, aura in ipairs(importantAuras) do
		if aura.SpellIcon and aura.StartTime and aura.TotalDuration then
			container:SetSlotUsed(slotIndex)
			container:SetLayer(
				slotIndex,
				layerIndex,
				aura.SpellIcon,
				aura.StartTime,
				aura.TotalDuration,
				aura.IsImportant, -- alphaBoolean
				false, -- glow
				db.Portrait.ReverseCooldown
			)

			layerIndex = layerIndex + 1
		end
	end

	container:FinalizeSlot(slotIndex, layerIndex - 1)
end

---@return table? unitFrame
---@return table? portrait
local function GetBlizzardFrame(unit)
	if unit == "player" then
		if PlayerFrame and PlayerFrame.portrait then
			return PlayerFrame, PlayerFrame.portrait
		end
	elseif unit == "target" then
		if TargetFrame and TargetFrame.portrait then
			return TargetFrame, TargetFrame.portrait
		end
	elseif unit == "focus" then
		if FocusFrame and FocusFrame.portrait then
			return FocusFrame, FocusFrame.portrait
		end
	elseif unit == "pet" then
		if PetFrame and PetFrame.portrait then
			return PetFrame, PetFrame.portrait
		end
	end

	return nil
end

---@return IconSlotContainer[]
function M:GetContainers()
	local result = {}
	for _, container in pairs(containers) do
		result[#result + 1] = container
	end
	return result
end

---@param unit string
---@param events string[]?
local function Attach(unit, events)
	local unitFrame, portrait = GetBlizzardFrame(unit)

	if not unitFrame or not portrait then
		return nil
	end

	local container = CreateContainer(unitFrame, portrait)
	local watcher = unitWatcher:New(unit, events)

	watcher:RegisterCallback(function()
		OnAuraInfo(watcher, container)
	end)

	containers[unit] = container
	---@diagnostic disable-next-line: unused-local
	watchers[unit] = watcher

	return container
end

local function EnableDisable()
	local options = db.Portrait

	if options.Enabled then
		for _, watcher in ipairs(watchers) do
			watcher:Enable()
		end
	else
		for _, watcher in ipairs(watchers) do
			watcher:Disable()
		end
	end
end

function M:Pause()
	paused = true
end

function M:Resume()
	paused = false
end

function M:Refresh()
	EnableDisable()
end

function M:Init()
	db = mini:GetSavedVars()

	Attach("player")
	Attach("target", { "PLAYER_TARGET_CHANGED" })
	Attach("focus", { "PLAYER_FOCUS_CHANGED" })
	Attach("pet")

	M:Refresh()
end
