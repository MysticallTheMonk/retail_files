if not ActionBarButtonRangeCheckFrame then return end

local _, Addon = ...

local states = {}
local registered = {}

local function UpdateColor(hotkey, state)
	local color = Addon.sets[state]

	-- If the state is hidden, make the text invisible, else make it visible.
	hotkey:SetAlpha(color[4])

	-- Change the text again just in case it has been edited by the game.
	hotkey:SetText(RANGE_INDICATOR)

	-- Change the color of the text.
	hotkey:SetVertexColor(color[1], color[2], color[3])

	states[hotkey] = state
end

local function UpdatePlayerButtonState(button)
	local hotkey = button.HotKey
	local is_usable, has_range, is_in_range, is_self_castable = Addon.GetActionState(button.action)
	local state

	-- Check if it is usable, it has range, the slot isn't empty and there is a target.
	if is_usable and has_range and is_in_range ~= nil then

		-- Check if the target is in range or if the player is in range, so it is castable on self.
		if is_in_range == false or is_self_castable == false then
			state = "OUT_OF_RANGE"
		else
			state = "IN_RANGE"
		end
	else
		state = "HIDDEN"
	end

	UpdateColor(hotkey, state)
end

local function UpdatePlayerButtonUsable(button)
	if button:IsVisible() then
		UpdatePlayerButtonState(button)
	end
end

local function RegisterPlayerButton(button)
	if registered[button] then
		return
	end

	hooksecurefunc(button, "UpdateUsable", UpdatePlayerButtonUsable)

	registered[button] = true
end

local watched_pet_buttons = {}

local function UpdatePetButtonState(button)
	local hotkey = button.HotKey
	local is_usable, has_range, is_in_range = Addon.GetPetActionState(button:GetID())
	local state

	-- Check if it usable, it has range, the slot isn't empty, and the slot contains a Spell.
	if is_usable and has_range and is_in_range ~= nil then

		-- Check if the target isn't in range.
		if is_in_range == false then
			state = "OUT_OF_RANGE"
		else
			state = "IN_RANGE"
		end
	else
		state = "HIDDEN"
	end

	UpdateColor(hotkey, state)
end

local function UpdatePetButtons()
	for button in pairs(watched_pet_buttons) do
		UpdatePetButtonState(button)
	end
end

local ticker = nil

local function UpdatePetRangeChecker()
	if next(watched_pet_buttons) then
		if not ticker then
			ticker = C_Timer.NewTicker(TOOLTIP_UPDATE_TIME, UpdatePetButtons)
		end

	elseif ticker then
		ticker:Cancel()
		ticker = nil
	end
end

local function ShouldWatchPetAction(button)
	if button:IsVisible() then
		local has_range = select(8, GetPetActionInfo(button:GetID()))

		return has_range
	end

	return false
end

local function UpdatePetButtonWatched(button)
	local state = ShouldWatchPetAction(button) or nil

	if state ~= watched_pet_buttons[button] then
		watched_pet_buttons[button] = state
		UpdatePetRangeChecker()
	end
end

local function RegisterPetButton(button)
	if registered[button] then
		return
	end

	button:SetScript("OnUpdate", nil)
	button:HookScript("OnShow", UpdatePetButtonWatched)
	button:HookScript("OnHide", UpdatePetButtonWatched)

	registered[button] = true
end

function Addon:Enable()
	-- Register known Action Buttons.
	for _, button in pairs(ActionBarButtonEventsFrame.frames) do
		RegisterPlayerButton(button)
	end

	-- Watch for additional Action Buttons.
	hooksecurefunc(ActionBarButtonEventsFrame, "RegisterFrame", function(_, button)
		RegisterPlayerButton(button)
	end)

	-- Disable the ActionBarButtonUpdateFrame OnUpdate handler.
	ActionBarButtonUpdateFrame:SetScript("OnUpdate", nil)

	self.frame:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")

	-- Register all Pet Action Buttons.
	for _, button in pairs(PetActionBar.actionButtons) do
		RegisterPetButton(button)
	end

	hooksecurefunc(PetActionBar, "Update", function(bar)
		-- Reset the timer on update, so that we don't trigger the bar's own range updater code.
		bar.rangeTimer = nil

		if PetHasActionBar() then
			for _, button in pairs(bar.actionButtons) do
				if button.icon:IsVisible() then
					UpdatePetButtonState(button)
				end

				UpdatePetButtonWatched(button)
			end
		else
			-- Removes the contents of the table, but retains the variable's internal pointer.
			wipe(watched_pet_buttons)

			UpdatePetRangeChecker()
		end
	end)
end

local function UpdatePlayerButtons()
	for _, buttons in pairs(ActionBarButtonRangeCheckFrame.actions) do
		for _, button in pairs(buttons) do
			if button:IsVisible() then
				UpdatePlayerButtonState(button)
			end
		end
	end

	for _, button in pairs(PetActionBar.actionButtons) do
		if button:IsVisible() then
			UpdatePetButtonState(button)
		end
	end
end

function Addon:RequestUpdate()
	UpdatePlayerButtons()
end

function Addon:ACTION_RANGE_CHECK_UPDATE(_, slot)
	local buttons = ActionBarButtonRangeCheckFrame.actions[slot]

	if not buttons then
		return
	end

	for _, button in pairs(buttons) do
		UpdatePlayerButtonState(button)
	end
end