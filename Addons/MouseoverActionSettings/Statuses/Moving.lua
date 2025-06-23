local _, addonTable = ...
local addon = addonTable.addon
addonTable.events["PLAYER_MOVING_UPDATE"] = false
local CR = addonTable.callbackRegistry

local eventDelay = 0

local function OnEvent(self, event)
    local isMoving = false
    if event == "PLAYER_STARTED_MOVING" then
        isMoving = true
    elseif event == "PLAYER_STOPPED_MOVING" then
        isMoving = false
    end
    CR:Fire("PLAYER_MOVING_UPDATE", isMoving, eventDelay)
    addonTable.events["PLAYER_MOVING_UPDATE"] = isMoving
end

local frame = nil

local moving_status = {}
function moving_status:Start()
    eventDelay = addon.db.profile.EventDelayTimers.PLAYER_MOVING_UPDATE
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent) 
    end
    CR:Fire("PLAYER_MOVING_UPDATE", IsPlayerMoving())
    frame:RegisterEvent("PLAYER_STARTED_MOVING")
    frame:RegisterEvent("PLAYER_STOPPED_MOVING")
end

function moving_status:Stop()
    if not frame then
        return
    end
    frame:UnregisterAllEvents()
end

CR:RegisterStatusEvent("PLAYER_MOVING_UPDATE", moving_status)