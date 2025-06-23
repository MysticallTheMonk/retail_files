local _, addonTable = ...
addonTable.events["PARTY_GROUP_UPDATE"] = false
addonTable.events["RAID_GROUP_UPDATE"] = false
local CR = addonTable.callbackRegistry

local function updateGroupType()
    local inGroup = IsInGroup()
    local inRaid = IsInRaid() 
    local inParty = not inRaid and inGroup
    CR:Fire("PARTY_GROUP_UPDATE", inGroup)
    addonTable.events["PARTY_GROUP_UPDATE"] = inParty
    CR:Fire("RAID_GROUP_UPDATE", inRaid)
    addonTable.events["RAID_GROUP_UPDATE"] = inRaid
end

local frame = nil
local active_group_events = {}

local group_status = {}
function group_status:Start(event)
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", updateGroupType) 
    end
    active_group_events[event] = true
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    updateGroupType()
end

function group_status:Stop(event)
    if not frame then
        return
    end
    active_group_events[event] = nil
    if next(active_group_events) == nil then
        frame:UnregisterAllEvents()
    end
end

CR:RegisterStatusEvent("PARTY_GROUP_UPDATE", group_status)
CR:RegisterStatusEvent("RAID_GROUP_UPDATE", group_status)