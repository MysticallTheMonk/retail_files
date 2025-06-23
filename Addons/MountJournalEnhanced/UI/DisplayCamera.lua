local _, ADDON = ...

-- unlock Y rotation with mouse

ADDON:RegisterUISetting('unlockDisplayCamera', true, ADDON.L.SETTING_YCAMERA, function(flag)
    if ADDON.initialized then
        local cam = MountJournal.MountDisplay.ModelScene:GetActiveCamera()
        if cam then
            if flag then
                cam:SetLeftMouseButtonYMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION)
            else
                cam:SetLeftMouseButtonYMode(ORBIT_CAMERA_MOUSE_MODE_NOTHING)
            end
        end
    end
end)

local function SetMinMaxZoom()
    local camera = MountJournal.MountDisplay.ModelScene:GetActiveCamera()
    if camera then
        if not camera.CalculateTransitionalValues_Org then
            camera.CalculateTransitionalValues_Org = camera.CalculateTransitionalValues
            camera.CalculateTransitionalValues = function(_, fromModelSceneCameraInfo, toModelSceneCameraInfo, modificationType)
                toModelSceneCameraInfo.minZoomDistance = toModelSceneCameraInfo.minZoomDistance / 2
                toModelSceneCameraInfo.maxZoomDistance = toModelSceneCameraInfo.maxZoomDistance * 2

                return camera:CalculateTransitionalValues_Org(fromModelSceneCameraInfo,toModelSceneCameraInfo, modificationType)
            end
        end

        -- initially force update again to recalculate min/max zoom values
        MountJournal_UpdateMountDisplay(true)
    end
end

local function SetupCamera()
    local cam = MountJournal.MountDisplay.ModelScene:GetActiveCamera()
    if cam then
        ADDON:ApplySetting('unlockDisplayCamera', ADDON.settings.ui.unlockDisplayCamera)

        -- revert Y rotation for a better feel
        local org_GetDelta = cam.GetDeltaModifierForCameraMode
        cam.GetDeltaModifierForCameraMode = function(self, mode)
            local result = org_GetDelta(self, mode)
            if (mode == ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION) then
                result = -result
            end

            return result
        end
    end
end

ADDON.Events:RegisterCallback("loadUI", function()
    SetupCamera()
    SetMinMaxZoom()
    hooksecurefunc(MountJournal.MountDisplay.ModelScene, "SetActiveCamera", SetupCamera)
end, "camera")