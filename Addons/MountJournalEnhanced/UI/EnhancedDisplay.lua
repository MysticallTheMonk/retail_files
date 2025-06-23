local _, ADDON = ...

ADDON.Events:RegisterCallback("preloadUI", function()

    -- view variant mount color
    local mountActor = MountJournal.MountDisplay.ModelScene:GetActorByTag("unwrapped")
    hooksecurefunc(mountActor, "SetModelByCreatureDisplayID", function(self, creatureDisplayID, flag, _, _, _, recursion)
        if not recursion then
            local mountID, mountVariation = ADDON.Api:GetSelected()
            if mountVariation then
                local creatureData = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)
                if creatureData[mountVariation] then
                    local variationDisplayID = creatureData[mountVariation].creatureDisplayID or nil
                    if variationDisplayID then
                        self:SetModelByCreatureDisplayID(variationDisplayID, flag, nil, nil, nil, true)
                    end
                end
            end
        end
    end)

    local gotUpdated = false
    hooksecurefunc(MountJournal.MountDisplay.ModelScene, "TransitionToModelSceneID", function()
        gotUpdated = true
    end)
    hooksecurefunc("MountJournal_UpdateMountDisplay", function()
        if gotUpdated then
            ADDON.Events:TriggerEvent("OnUpdateMountDisplay")
        end
        gotUpdated = false
    end)
end, "enhanced display")

ADDON.Events:RegisterCallback("postloadUI", function()
    -- trigger initial update
    ADDON.Events:TriggerEvent("OnUpdateMountDisplay")
end , "enhanced display")