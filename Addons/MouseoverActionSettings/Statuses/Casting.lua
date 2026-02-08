local _, addonTable = ...
local addon = addonTable.addon
addonTable.events["PLAYER_CASTING_UPDATE"] = false
local CR = addonTable.callbackRegistry

local eventDelay = 0

local function OnEvent(_, event)
    local isCasting = false
    
    if event == "UNIT_SPELLCAST_START" then
        isCasting = true
    elseif event == "UNIT_SPELLCAST_STOP" then
        isCasting = false
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        isCasting = true
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        isCasting = false
    end

    CR:Fire("PLAYER_CASTING_UPDATE", isCasting, eventDelay)
    addonTable.events["PLAYER_CASTING_UPDATE"] = isCasting
end

local frame = nil

local casting_status = {}
function casting_status:Start()
    eventDelay = addon.db.profile.EventDelayTimers.PLAYER_CASTING_UPDATE
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent) 
    end
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    OnEvent()
end

function casting_status:Stop()
    if not frame then
        return
    end
    frame:UnregisterAllEvents()
end

CR:RegisterStatusEvent("PLAYER_CASTING_UPDATE", casting_status)