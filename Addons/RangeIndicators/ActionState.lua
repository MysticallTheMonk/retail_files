local _, Addon = ...

function Addon.GetActionState(slot)
	local is_usable = IsUsableAction(slot)
	local has_range = ActionHasRange(slot)

	-- If range does not apply to this action, returns true.
    -- If you can't use the spell on the target, returns true.
	-- If the target is in range, returns true, else false.
	-- If the slot is empty, returns nil.
	-- If there is no target, returns nil.
	local is_in_range = IsActionInRange(slot)

	-- Same as above, but using the player as a target.
	local is_self_castable = IsActionInRange(slot, "player")

	local spell_id = select(2, GetActionInfo(slot))

	-- Bandaid for Primordial Wave (Elemental, Enhancement) incorrectly returning true for allies.
	if spell_id == 375982 then
		is_self_castable = nil

		-- Check if the target is allied or neutral.
		if UnitCanAttack("player", "target") == false then
			is_in_range = nil
		end
	end

	return is_usable, has_range, is_in_range, is_self_castable
end

function Addon.GetPetActionState(slot)
	local is_usable = GetPetActionSlotUsable(slot)
	local spell_id, has_range, is_in_range = select(7, GetPetActionInfo(slot))

	return is_usable and spell_id, has_range, is_in_range
end
