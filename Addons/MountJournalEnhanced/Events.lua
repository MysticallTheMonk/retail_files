local _, ADDON = ...

local activeMount, activeAuraId

function ADDON:IsPlayerMounted()
    return activeMount ~= nil
end

local function GetActiveMount()
    local numMounts = C_MountJournal.GetNumDisplayedMounts()
    for index = 1, numMounts do
        local _, _, _, isActive, _, _, _, _, _, _, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(index)
        if isActive then
            return mountID
        end
        if not isCollected then
            return
        end
    end
end

local function triggerEvents(unit, isOnLogin, mountId, auraInstanceID)
    if mountId then
        if unit == "player" then
            if issecretvalue and issecretvalue(mountId) then
                -- data from UNIT_AURA are now secret values since 12.0
                -- therefore parse active mount again from different source
                mountId = GetActiveMount()
            end
            activeMount = mountId
            activeAuraId = auraInstanceID
            ADDON.Events:TriggerEvent("OnMountUp", activeMount, isOnLogin)
        elseif unit == "target" then
            ADDON.Events:TriggerEvent("OnMountUpTarget", mountId)
        end
    end
end

local function checkAuras(auras)
    for _, aura in ipairs(auras) do
        if aura then
            local mountId = C_MountJournal.GetMountFromSpell(aura.spellId)
            if mountId then
                return mountId, aura.auraInstanceID
            end
        end
    end
end

function ADDON:ScanAuras(unit)
    local continuationToken, aura1, aura2, aura3, aura4, aura5
    repeat
        continuationToken, aura1, aura2, aura3, aura4, aura5 = C_UnitAuras.GetAuraSlots(unit, "HELPFUL|CANCELABLE", 5, continuationToken)
        local mountId, auraInstanceID = checkAuras({
            aura1 and C_UnitAuras.GetAuraDataBySlot(unit, aura1),
            aura2 and C_UnitAuras.GetAuraDataBySlot(unit, aura2),
            aura3 and C_UnitAuras.GetAuraDataBySlot(unit, aura3),
            aura4 and C_UnitAuras.GetAuraDataBySlot(unit, aura4),
            aura5 and C_UnitAuras.GetAuraDataBySlot(unit, aura5),
        })
        if mountId then
            return mountId, auraInstanceID
        end
    until continuationToken == nil
end

ADDON.Events:RegisterCallback("OnLogin", function()
    triggerEvents("player", true,  ADDON:ScanAuras("player"))

    ADDON.Events:RegisterFrameEventAndCallback("UNIT_AURA", function(_, target, updateInfo)
        if target == "player" or target == "target" then
            if updateInfo.isFullUpdate then
                triggerEvents(target, false,  ADDON:ScanAuras(target))
            end
            if updateInfo.addedAuras then
                triggerEvents(target, false, checkAuras(updateInfo.addedAuras))
            end
            if target == "player" and updateInfo.removedAuraInstanceIDs and tContains(updateInfo.removedAuraInstanceIDs, activeAuraId) then
                local mountId = activeMount
                activeMount = nil
                activeAuraId = nil
                ADDON.Events:TriggerEvent("OnMountDown", mountId)
            end
        end
    end, 'external events')

    ADDON.Events:RegisterFrameEventAndCallback("PLAYER_TARGET_CHANGED", function()
        C_Timer.After(0, function()
            triggerEvents("target", false,  ADDON:ScanAuras("target"))
        end)
    end, 'external events')

    ADDON.Events:RegisterFrameEventAndCallback("NEW_MOUNT_ADDED", function(_, ...)
        local param1, param2, param3 = ...
        C_Timer.After(1, function() -- mount infos are not properly updated in current frame
            ADDON:FilterMounts()
            ADDON.Events:TriggerEvent("OnNewMount", param1, param2, param3)
        end)
    end, 'external events')

    ADDON.Events:RegisterFrameEventAndCallback("UNIT_SPELLCAST_START", function(_, unit, _, spellId)
        if InCombatLockdown() -- no use case for now in combat
           or (unit ~= "player" and unit ~= "target")
        then
            return
        end

        local mountId = C_MountJournal.GetMountFromSpell(spellId)
        if mountId then
            if unit == "player" then
                ADDON.Events:TriggerEvent("CastMount", mountId)
            elseif unit == "target" then
                ADDON.Events:TriggerEvent("CastMountTarget", mountId)
            end
        end
    end, 'external events')

    -- on unpacking mount
    hooksecurefunc(C_MountJournal, "ClearFanfare", function(mountId)
        ADDON:FilterMounts()
        ADDON.Events:TriggerEvent("OnNewMount", mountId)
    end)
end, 'external events')