local i = CreateFrame("Frame", nil, UIParent)
	i:RegisterEvent("PLAYER_ENTERING_WORLD")
	i:SetScript("OnEvent", function(self, event)
			PlayerFrame:UnregisterAllEvents()
			PlayerFrame:Hide()
			TargetFrame:UnregisterAllEvents()
			TargetFrame:Hide()
end)