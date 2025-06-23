--[[
    currently inactive needs some more dev time to work properly
]]
local _, addonTable = ...
local CR = addonTable.callbackRegistry


local events = {
   [605] = "MIND_CONTROL_UPDATE", --spellId
}

local desiredSourceUnits = {
    ["MIND_CONTROL_UPDATE"] = {
        ["player"] = true,
    },
}

local auras = {
    target = {},
}

local function updateAurasFull(unit)
    auras[unit] = {}
    local function handleAura(aura)
        local event = events[aura.spellId]
        if event and desiredSourceUnits[event][aura.sourceUnit] then 
            CR:Fire(event, true)
            auras[unit][aura.auraInstanceID] = aura.spellId
        end
    end
    AuraUtil_ForEachAura(unit, "HELPFUL|HARMFUL", nil, handleAura, true)  
end

local function updateAurasIncremental(unit, updateInfo)
    if updateInfo.addedAuras then
        for _, aura in pairs(updateInfo.addedAuras) do
            local event = events[aura.spellId]
            if event and desiredSourceUnits[event][aura.sourceUnit] then 
                CR:Fire(event, true)
                auras[unit][aura.auraInstanceID] = aura.spellId
            end
        end
    end
    if updateInfo.removedAuraInstanceIDs then
        for _, auraInstanceID in pairs(updateInfo.removedAuraInstanceIDs) do
            if auras[unit][auraInstanceID] then
                local spellId = auras[unit][auraInstanceID]
                CR:Fire(events[spellId], false)
                auras[unit][auraInstanceID] = nil
            end
        end
    end
end

local function OnEvent(self, event, ...)
    local unit, updateInfo = ...
    if updateInfo.isFullUpdate then 
        updateAurasFull(unit)
    else
        updateAurasIncremental(unit, updateInfo)
    end
end
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", OnEvent)
frame:RegisterUnitEvent("UNIT_AURA", "target")