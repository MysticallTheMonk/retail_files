function HideDisgustingFlash(barName)
	for i = 1, 12 do
		local o = _G[barName.."Button"..i]
		if (o) then
			o.CooldownFlash:SetAlpha(0)
			o.SpellCastAnimFrame:SetAlpha(0)
		end
	end
end

HideDisgustingFlash("Action")
HideDisgustingFlash("PetAction")
HideDisgustingFlash("MultiBarBottomLeft")
HideDisgustingFlash("MultiBarBottomRight")
HideDisgustingFlash("MultiBarRight")
HideDisgustingFlash("MultiBarLeft")
HideDisgustingFlash("MultiBar5")
HideDisgustingFlash("MultiBar6")
HideDisgustingFlash("MultiBar7")