C_Timer.After(0,function()
	CompactPartyFrame:SetFlowSortFunction(function(a,b)if not UnitExists(a)then return false elseif not UnitExists(b)then return true elseif UnitIsUnit(a,"player")then return false elseif UnitIsUnit(b,"player")then return true else return a<b end end)
end)