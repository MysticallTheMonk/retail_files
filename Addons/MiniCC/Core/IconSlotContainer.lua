---@type string, Addon
local _, addon = ...
local LCG = LibStub and LibStub("LibCustomGlow-1.0", false)

---@class IconSlotContainer
local M = {}
M.__index = M

addon.Core.IconSlotContainer = M

---Creates a new IconSlotContainer instance
---@param parent table frame to attach to
---@param count number of slots to create (default: 3)
---@param size number of each icon slot (default: 20)
---@param spacing number between slots (default: 2)
---@return IconSlotContainer
function M:New(parent, count, size, spacing)
	local instance = setmetatable({}, M)

	count = count or 3
	size = size or 20
	spacing = spacing or 2

	instance.Frame = CreateFrame("Frame", nil, parent)
	instance.Slots = {}
	instance.Count = 0
	instance.Size = size
	instance.Spacing = spacing

	instance:SetCount(count)

	return instance
end

local function CreateLayer(parentFrame, level)
	local layerFrame = CreateFrame("Frame", nil, parentFrame)
	layerFrame:SetAllPoints()

	if level then
		layerFrame:SetFrameLevel(level)
	end

	local icon = layerFrame:CreateTexture(nil, "OVERLAY")
	icon:SetAllPoints()

	local cd = CreateFrame("Cooldown", nil, layerFrame, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetDrawEdge(false)
	cd:SetDrawBling(false)
	cd:SetHideCountdownNumbers(false)
	cd:SetSwipeColor(0, 0, 0, 0.8)

	return {
		Frame = layerFrame,
		Icon = icon,
		Cooldown = cd,
	}
end

local function EnsureLayer(slot, layerIndex)
	local slotLevel = slot.Frame:GetFrameLevel() or 0
	local baseLevel = slotLevel + 1

	-- Create any missing layers
	-- Use +2 per layer to ensure cooldown text doesn't overlap next icon
	for l = #slot.Layers + 1, layerIndex do
		slot.Layers[l] = CreateLayer(slot.Frame, baseLevel + ((l - 1) * 2))
	end

	-- re-apply levels to existing layers (covers cases where slot level changes)
	for l = 1, #slot.Layers do
		local layer = slot.Layers[l]
		if layer and layer.Frame then
			layer.Frame:SetFrameLevel(baseLevel + ((l - 1) * 2))
		end
	end

	return slot.Layers[layerIndex]
end

function M:Layout()
	local usedSlots = {}

	for i = 1, self.Count do
		local slot = self.Slots[i]
		if slot and slot.IsUsed then
			usedSlots[#usedSlots + 1] = i
		end
	end

	local usedCount = #usedSlots
	local totalWidth = (usedCount * self.Size) + ((usedCount - 1) * self.Spacing)
	self.Frame:SetSize((usedCount > 0) and totalWidth or self.Size, self.Size)

	-- Position used slots contiguously
	for displayIndex, slotIndex in ipairs(usedSlots) do
		local slot = self.Slots[slotIndex]
		local x = (displayIndex - 1) * (self.Size + self.Spacing) - (totalWidth / 2) + (self.Size / 2)
		slot.Frame:ClearAllPoints()
		slot.Frame:SetPoint("CENTER", self.Frame, "CENTER", x, 0)
		slot.Frame:SetSize(self.Size, self.Size)
		slot.Frame:Show()
	end

	-- Hide unused active slots
	for i = 1, self.Count do
		local slot = self.Slots[i]
		if slot and not slot.IsUsed then
			slot.Frame:Hide()
		end
	end

	-- Always hide inactive pooled slots
	for i = self.Count + 1, #self.Slots do
		local slot = self.Slots[i]
		if slot then
			slot.IsUsed = false
			slot.Frame:Hide()
		end
	end
end

---Sets the icon size for all slots
---@param newSize number
function M:SetIconSize(newSize)
	---@diagnostic disable-next-line: cast-local-type
	newSize = tonumber(newSize)
	if not newSize or newSize <= 0 then
		return
	end
	if self.Size == newSize then
		return
	end

	self.Size = newSize

	-- Resize active slots
	for i = 1, self.Count do
		local slot = self.Slots[i]
		if slot and slot.Frame then
			slot.Frame:SetSize(self.Size, self.Size)
		end
	end

	self:Layout()
end

---Sets the total number of slots
---@param newCount number of slots to maintain
function M:SetCount(newCount)
	newCount = math.max(0, newCount or 0)

	-- If shrinking, disable anything beyond newCount (pooled slots)
	if newCount < self.Count then
		for i = newCount + 1, #self.Slots do
			local slot = self.Slots[i]
			if slot then
				slot.IsUsed = false
				self:ClearSlot(i)
				slot.Frame:Hide()
			end
		end
	end

	self.Count = newCount

	-- Grow pool if needed
	for i = #self.Slots + 1, newCount do
		local slotFrame = CreateFrame("Frame", nil, self.Frame)
		slotFrame:SetSize(self.Size, self.Size)

		self.Slots[i] = {
			Frame = slotFrame,
			Layers = {},
			LayerCount = 0,
			IsUsed = false,
		}
	end

	self:Layout()
end

---Sets a layer on a specific slot
---@param slotIndex number Slot index (1-based)
---@param layerIndex number Layer index (1-based, higher = on top)
---@param texture string Texture path/ID
---@param startTime number Cooldown start time (GetTime())
---@param duration number Cooldown duration in seconds
---@param alphaBoolean boolean to control alpha (true = 1.0, false = dimmed)
---@param glow boolean Whether to show glow effect (requires LibCustomGlow)
---@param reverseCooldown boolean Whether to reverse the cooldown animation
function M:SetLayer(slotIndex, layerIndex, texture, startTime, duration, alphaBoolean, glow, reverseCooldown)
	if slotIndex < 1 or slotIndex > self.Count then
		return
	end
	if layerIndex < 1 then
		return
	end

	local slot = self.Slots[slotIndex]
	if not slot then
		return
	end

	local layer = EnsureLayer(slot, layerIndex)
	slot.LayerCount = math.max(slot.LayerCount or 0, layerIndex)

	if texture and startTime and duration then
		layer.Icon:SetTexture(texture)
		layer.Cooldown:SetReverse(reverseCooldown)
		layer.Cooldown:SetCooldown(startTime, duration)
		layer.Frame:SetAlphaFromBoolean(alphaBoolean)

		if LCG then
			if glow then
				LCG.ProcGlow_Start(layer.Frame, { startAnim = false })
				local procGlow = layer.Frame._ProcGlow
				if procGlow then
					procGlow:SetAlphaFromBoolean(alphaBoolean)
				end
			else
				LCG.ProcGlow_Stop(layer.Frame)
			end
		end
	end
end

-- Clears a specific layer on a slot
---@param slotIndex number Slot index
---@param layerIndex number Layer index
function M:ClearLayer(slotIndex, layerIndex)
	if slotIndex < 1 or slotIndex > #self.Slots then
		return
	end

	local slot = self.Slots[slotIndex]
	if not slot then
		return
	end
	local layer = slot.Layers[layerIndex]
	if not layer then
		return
	end

	layer.Icon:SetTexture(nil)
	layer.Cooldown:Clear()

	if LCG then
		LCG.ProcGlow_Stop(layer.Frame)
	end
end

-- Clears all layers on a slot
---@param slotIndex number Slot index
function M:ClearSlot(slotIndex)
	if slotIndex < 1 or slotIndex > #self.Slots then
		return
	end

	local slot = self.Slots[slotIndex]
	if not slot then
		return
	end

	for l = 1, #slot.Layers do
		self:ClearLayer(slotIndex, l)
	end

	slot.LayerCount = 0
end

-- Finalizes a slot by clearing unused layers
---@param slotIndex number Slot index
---@param usedCount number Number of layers actually used
function M:FinalizeSlot(slotIndex, usedCount)
	if slotIndex < 1 or slotIndex > #self.Slots then
		return
	end

	local slot = self.Slots[slotIndex]
	if not slot then
		return
	end

	usedCount = usedCount or 0

	for l = usedCount + 1, #slot.Layers do
		self:ClearLayer(slotIndex, l)
	end

	slot.LayerCount = usedCount
end

---Marks a slot as used and triggers layout update
---@param slotIndex number Slot index
function M:SetSlotUsed(slotIndex)
	if slotIndex < 1 or slotIndex > self.Count then
		return
	end

	local slot = self.Slots[slotIndex]
	if not slot then
		return
	end

	if not slot.IsUsed then
		slot.IsUsed = true
		self:Layout()
	end
end

---Marks a slot as unused and triggers layout update
---This will shift all other used slots to fill the gap
---@param slotIndex number Slot index
function M:SetSlotUnused(slotIndex)
	if slotIndex < 1 or slotIndex > self.Count then
		return
	end

	local slot = self.Slots[slotIndex]
	if not slot then
		return
	end

	if slot.IsUsed then
		slot.IsUsed = false
		self:ClearSlot(slotIndex)
		self:Layout()
	end
end

---Checks if a slot is currently used
---@param slotIndex number Slot index
---@return boolean indicating if slot is used
function M:IsSlotUsed(slotIndex)
	if slotIndex < 1 or slotIndex > self.Count then
		return false
	end
	local slot = self.Slots[slotIndex]
	if not slot then
		return false
	end
	return slot.IsUsed or false
end

---Gets the number of currently used slots
---@return number Count of used slots
function M:GetUsedSlotCount()
	local count = 0
	for i = 1, self.Count do
		if self.Slots[i] and self.Slots[i].IsUsed then
			count = count + 1
		end
	end
	return count
end

---Resets all slots to unused (active range only)
function M:ResetAllSlots()
	for i = 1, self.Count do
		local slot = self.Slots[i]
		if slot and slot.IsUsed then
			self:SetSlotUnused(i)
		end
	end
end

---@class IconLayer
---@field Frame table
---@field Icon table
---@field Cooldown table

---@class IconSlot
---@field Frame table
---@field Layers IconLayer[]
---@field LayerCount number
---@field IsUsed boolean

---@class IconSlotContainer
---@field Frame table
---@field Slots IconSlot[]
---@field Count number
---@field Size number
---@field Spacing number
---@field SetCount fun(self: IconSlotContainer, count: number)
---@field SetIconSize fun(self: IconSlotContainer, size: number)
---@field SetLayer fun(self: IconSlotContainer, slotIndex: number, layerIndex: number, texture: string, startTime: number?, duration: number?, alphaBoolean: boolean, glow: boolean, reverseCooldown: boolean)
---@field ClearLayer fun(self: IconSlotContainer, slotIndex: number, layerIndex: number)
---@field ClearSlot fun(self: IconSlotContainer, slotIndex: number)
---@field FinalizeSlot fun(self: IconSlotContainer, slotIndex: number, usedCount: number)
---@field SetSlotUsed fun(self: IconSlotContainer, slotIndex: number)
---@field SetSlotUnused fun(self: IconSlotContainer, slotIndex: number)
---@field IsSlotUsed fun(self: IconSlotContainer, slotIndex: number): boolean
---@field GetUsedSlotCount fun(self: IconSlotContainer): number
---@field ResetAllSlots fun(self: IconSlotContainer)
