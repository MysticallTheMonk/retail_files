local _, addonTable = ...
local addon = addonTable.addon
addonTable.events["NPC_UPDATE"] = false
local CR = addonTable.callbackRegistry

local eventDelay = 0

local frames = {
    QuestFrame,
    GossipFrame,
}

local function updateNPC()
    local isShown = false
    for _, frame in pairs(frames) do
        if frame:IsShown() then
            isShown = true 
            break
        end
    end
    CR:Fire("NPC_UPDATE", isShown, eventDelay)
end

local npc_status = {}
Mixin(npc_status, addonTable.hooks)

function npc_status:Start()
    eventDelay = addon.db.profile.EventDelayTimers.NPC_UPDATE
    for _, frame in pairs(frames) do
        self:HookScript(frame, "OnShow", updateNPC)
        self:HookScript(frame, "OnHide", updateNPC)
    end
    updateNPC()
end

function npc_status:Stop()
    self:DisableHooks()
end

CR:RegisterStatusEvent("NPC_UPDATE", npc_status)