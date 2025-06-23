local _, addonTable = ...
local addon = addonTable.addon
addonTable.events["MOUNT_UPDATE"] = false
local CR = addonTable.callbackRegistry

local eventDelay = 0

local function updateMounted()
    local mounted = IsMounted()
    CR:Fire("MOUNT_UPDATE", mounted, eventDelay)
    addonTable.events["MOUNT_UPDATE"] = mounted
end

local function OnEvent(self, event, arg1)
    updateMounted()
    if event == "PLAYER_ENTERING_WORLD" and arg1 == true then
        C_Timer.After(2, OnEvent)
    end
end

local frame = nil

local mount_status = {}
function mount_status:Start()
    eventDelay = addon.db.profile.EventDelayTimers.MOUNT_UPDATE
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent) 
    end
    updateMounted()
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function mount_status:Stop()
    if not frame then
        return
    end
    frame:UnregisterAllEvents()
end

CR:RegisterStatusEvent("MOUNT_UPDATE", mount_status)