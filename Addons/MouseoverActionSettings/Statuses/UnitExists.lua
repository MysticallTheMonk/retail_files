local _, addonTable = ...
addonTable.events["TARGET_UPDATE"] = false
local CR = addonTable.callbackRegistry

local function OnEvent(_, event, fireAll)
    if event == "PLAYER_TARGET_CHANGED" or fireAll then
        local exists = UnitExists("target")
        CR:Fire("TARGET_UPDATE", exists)
        addonTable.events["TARGET_UPDATE"] = exists
    end
end

local frame = nil
local active_unit_events = {}

local unit_status = {}
function unit_status:Start(event)
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent) 
    end
    active_unit_events[event] = true
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    OnEvent(nil, nil, true)
end

function unit_status:Stop(event)
    if not frame then
        return
    end
    active_unit_events[event] = nil
    if next(active_unit_events) == nil then
        frame:UnregisterAllEvents()
    end
end

CR:RegisterStatusEvent("TARGET_UPDATE", unit_status)
