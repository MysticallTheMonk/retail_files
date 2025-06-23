local _, addonTable = ...
local addon = addonTable.addon
addonTable.events["PLAYER_HEALTH_UPDATE"] = false
local CR = addonTable.callbackRegistry

local eventDelay = 0

local last_isBelowThreshold = false
local function OnEvent()
    local currentHealth = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    local healthPerc = currentHealth / maxHealth
    local isBelowThreshold = healthPerc < addon.db.profile.GlobalSettings.healthThreshold
    if isBelowThreshold ~= last_isBelowThreshold then
        CR:Fire("PLAYER_HEALTH_UPDATE", isBelowThreshold, eventDelay)
        addonTable.events["PLAYER_HEALTH_UPDATE"] = isBelowThreshold
        last_isBelowThreshold = isBelowThreshold
    end
end

local frame = nil

local health_status = {}
function health_status:Start()
    eventDelay = addon.db.profile.EventDelayTimers.PLAYER_HEALTH_UPDATE
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent) 
    end
    OnEvent()
    frame:RegisterUnitEvent("UNIT_HEALTH", "player")
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
end

function health_status:Stop()
    if not frame then
        return
    end
    frame:UnregisterAllEvents()
end

CR:RegisterStatusEvent("PLAYER_HEALTH_UPDATE", health_status)