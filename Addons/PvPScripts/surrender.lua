local function jPrint(msg)
	print("|cFFDC143CjaxSurrender:|r |cFF40E0D0"..msg.."|r")
end

SlashCmdList["CHAT_AFK"] = function(msg)
	if IsActiveBattlefieldArena() then
		if CanSurrenderArena() then
			jPrint("Successfully surrendered arena.")
			SurrenderArena();
		else
			jPrint("Failed to surrender arena. Partners still alive.")
		end
	else
		SendChatMessage(msg, "AFK");
	end
end