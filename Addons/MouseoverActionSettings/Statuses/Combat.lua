local _, addonTable = ...
local addon = addonTable.addon
addonTable.events["COMBAT_UPDATE"] = false
local CR = addonTable.callbackRegistry

local eventDelay = 0

local function OnEvent(self, event)
    local inCombat = false
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
    end
    CR:Fire("COMBAT_UPDATE", inCombat, eventDelay)
    addonTable.events["COMBAT_UPDATE"] = inCombat
end

local frame = nil

local combat_status = {}
function combat_status:Start()
    eventDelay = addon.db.profile.EventDelayTimers.COMBAT_UPDATE
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent) 
    end
    CR:Fire("COMBAT_UPDATE", InCombatLockdown())
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function combat_status:Stop()
    if not frame then
        return
    end
    frame:UnregisterAllEvents()
end

CR:RegisterStatusEvent("COMBAT_UPDATE", combat_status)