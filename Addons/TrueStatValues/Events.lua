local name, addon = ...;



--[[----------------------------------------------------------------------------
    PLAYER_SPECIALIZATION_CHANGED
------------------------------------------------------------------------------]]
function addon.tsv:PLAYER_SPECIALIZATION_CHANGED()
	self:RecalculateTrueStatRatings();
end



--[[----------------------------------------------------------------------------
	PLAYER_ENTERING_WORLD
------------------------------------------------------------------------------]]
function addon.tsv:PLAYER_ENTERING_WORLD()
	self:SetupConversionFactors();
    self:RecalculateTrueStatRatings();
end



--[[----------------------------------------------------------------------------
	COMBAT_RATING_UPDATE
------------------------------------------------------------------------------]]
function addon.tsv:COMBAT_RATING_UPDATE()
    self:RecalculateTrueStatRatings();
end



--[[----------------------------------------------------------------------------
	PLAYER_LEVEL_UP
------------------------------------------------------------------------------]]
function addon.tsv:PLAYER_LEVEL_UP()
    self:RecalculateTrueStatRatings();
end



--[[----------------------------------------------------------------------------
	Events
------------------------------------------------------------------------------]]
addon.tsv:RegisterEvent("PLAYER_LEVEL_UP");
addon.tsv:RegisterEvent("COMBAT_RATING_UPDATE");
addon.tsv:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
addon.tsv:RegisterEvent("PLAYER_ENTERING_WORLD");
