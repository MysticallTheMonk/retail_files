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

ADDON.Events:RegisterCallback("loadUI", function()
    fixInitialRiderBlend()
    keepCameraValuesInBound()
end, "blizz plz fix")