local _, addonTable = ...
local addon = addonTable.addon
addonTable.events["DRAGONRIDING_UPDATE"] = false
local CR = addonTable.callbackRegistry

local eventDelay = 0

local UnitPowerBarID = UnitPowerBarID

local function updateDragonriding()
    local isDragonRiding = UnitPowerBarID("player") == 631
    addonTable.events["DRAGONRIDING_UPDATE"] = isDragonRiding
    CR:Fire("DRAGONRIDING_UPDATE", isDragonRiding, eventDelay)
end

local function OnEvent(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, updateDragonriding)
    else
        updateDragonriding()
    end
end

local frame = nil

local dragonriding_status = {}
function dragonriding_status:Start()
    eventDelay = addon.db.profile.EventDelayTimers.DRAGONRIDING_UPDATE
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent) 
    end
    frame:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "player")
    frame:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "player")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    updateDragonriding()
end

function dragonriding_status:Stop()
    if not frame then
        return
    end
    frame:UnregisterAllEvents()
end

CR:RegisterStatusEvent("DRAGONRIDING_UPDATE", dragonriding_status)