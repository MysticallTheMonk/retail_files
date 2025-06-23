local _, addon = ...;

function SweepyBoop:SetupArenaSurrender()
    SlashCmdList["CHAT_AFK"] = function(msg)
        if IsActiveBattlefieldArena() and SweepyBoop.db.profile.misc.arenaSurrenderEnabled then
            if CanSurrenderArena() then
                SurrenderArena();
            else
                ConfirmOrLeaveBattlefield();
            end
        else
            SendChatMessage(msg, "AFK");
        end
    end

    if SweepyBoop.db.profile.misc.arenaSurrenderEnabled then
        SLASH_ArenaGG1 = "/gg";
        SlashCmdList.ArenaGG = function(msg)
            if IsActiveBattlefieldArena() then
                LeaveBattlefield();
            end
        end
    end
end
