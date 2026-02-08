local _, ADDON = ...

-- Normally the rider flies from over the saddle into it every time you switch to another mount.
-- It seems that the playerActor starts with some animation, which has that as first position.
-- With the AnimationBlendOperation=ANIM and some other SetAnimation() call during mountActor:AttachToMount()
-- the rider basically blends back into the saddle.
-- Therefore setting the AnimationBlendOperation=NONE beforehand avoids that issue.
local function fixInitialRiderBlend()
    local playerActor = MountJournal.MountDisplay.ModelScene:GetPlayerActor("player-rider")
    if playerActor then
        playerActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
    end
end

-- Rotating the display camera wildly extends the internal vector further and further.
-- At some point on very high/low values, the UI bugs with an error. (https://legacy.curseforge.com/wow/addons/mount-journal-enhanced/issues/97)
-- Although that might only happen with an unlocked Y-rotation/pitch.
-- Also, when resetting the camera the whole rotation gets reverted. That looks a bit funny.
--
-- To fix both we keep the rotation values within a fixed boundary of -2*PI and 2*PI. That prevents the LUA error and
-- keeps the reset rotation short.
local function keepCameraValuesInBound()
    local two_pi = 2 * math.pi
    local keepValueInBound = function(self, newValue, index, interpolatedIndex)
        if newValue < -two_pi then
            self[index] = newValue + two_pi
            if nil ~= self[interpolatedIndex] then
                self[interpolatedIndex] = self[interpolatedIndex] + two_pi
            end
        elseif newValue > two_pi then
            self[index] = newValue - two_pi
            if nil ~= self[interpolatedIndex] then
                self[interpolatedIndex] = self[interpolatedIndex] - two_pi
            end
        end
    end

    -- horizontal rotation
    hooksecurefunc(MountJournal.MountDisplay.ModelScene.activeCamera, "SetYaw", function(self, yaw)
        keepValueInBound(self, yaw, "yaw", "interpolatedYaw")
    end)
    -- vertical rotation
    hooksecurefunc(MountJournal.MountDisplay.ModelScene.activeCamera, "SetPitch", function(self, pitch)
        keepValueInBound(self, pitch, "pitch", "interpolatedPitch")
    end)
    -- same could be done with roll. but that's not necessary for the mount display.
end

-- Since 11.2.5 all calls of MountJournal_UpdateMountDisplay do get a forceSceneChange, including in MountJournal_FullUpdate().
-- MountJournal_FullUpdate is called during the events of COMPANION_UPDATE and MOUNT_JOURNAL_SEARCH_UPDATED,
-- which can trigger constantly.
-- https://github.com/Stanzilla/WoWUIBugs/issues/789
local function avoidResettingDisplay()
    local original_MountJournal_UpdateMountDisplay = MountJournal_UpdateMountDisplay
    hooksecurefunc("MountJournal_UpdateMountList", function()
        -- called from within FullUpdate
        -- might taint a lot
        MountJournal_UpdateMountDisplay = function()
            original_MountJournal_UpdateMountDisplay() -- no refreshs here
            MountJournal_UpdateMountDisplay = original_MountJournal_UpdateMountDisplay
        end
    end)
end

ADDON.Events:RegisterCallback("loadUI", function()
    fixInitialRiderBlend()
    keepCameraValuesInBound()
    avoidResettingDisplay()
end, "blizz plz fix")