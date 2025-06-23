local _, addonTable = ...
addonTable.events["BATTLEGROUND_UPDATE"] = false
addonTable.events["ARENA_UPDATE"] = false
addonTable.events["DUNGEON_UPDATE"] = false
addonTable.events["RAID_UPDATE"] = false
addonTable.events["SCENARIO_UPDATE"] = false
addonTable.events["OPEN_WORLD_UPDATE"] = false
local CR = addonTable.callbackRegistry

local function OnEvent()
    local inInstance, instanceType = IsInInstance() --now return false not nil when not in an instance
    local inBattleground = instanceType == "pvp" and true or false
    local inArena = instanceType == "arena" and true or false
    local inDungeon = instanceType == "party" and true or false
    local inRaid = instanceType == "raid" and true or false
    local inScenario = instanceType == "scenario" and true or false
    local inOpenWorld = not inInstance
    CR:Fire("BATTLEGROUND_UPDATE", inBattleground)
    addonTable.events["BATTLEGROUND_UPDATE"] = inBattleground
    CR:Fire("ARENA_UPDATE", inArena)
    addonTable.events["ARENA_UPDATE"] = inArena
    CR:Fire("DUNGEON_UPDATE", inDungeon)
    addonTable.events["DUNGEON_UPDATE"] = inDungeon
    CR:Fire("RAID_UPDATE", inRaid)
    addonTable.events["RAID_UPDATE"] = inRaid
    CR:Fire("SCENARIO_UPDATE", inScenario)
    addonTable.events["SCENARIO_UPDATE"] = inScenario
    CR:Fire("OPEN_WORLD_UPDATE", inOpenWorld)
    addonTable.events["OPEN_WORLD_UPDATE"] = inOpenWorld
end

local frame = nil
local active_zone_events = {}

local zone_status = {}
function zone_status:Start(event)
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent) 
    end
    active_zone_events[event] = true
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    OnEvent()
end

function zone_status:Stop(event)
    if not frame then
        return
    end
    active_zone_events[event] = nil
    if next(active_zone_events) == nil then
        frame:UnregisterAllEvents()
    end
end

CR:RegisterStatusEvent("BATTLEGROUND_UPDATE", zone_status)
CR:RegisterStatusEvent("ARENA_UPDATE", zone_status)
CR:RegisterStatusEvent("DUNGEON_UPDATE", zone_status)
CR:RegisterStatusEvent("RAID_UPDATE", zone_status)
CR:RegisterStatusEvent("SCENARIO_UPDATE", zone_status)
CR:RegisterStatusEvent("OPEN_WORLD_UPDATE", zone_status)