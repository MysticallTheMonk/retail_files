--[[
    This is meant to be used as Mixin for MouseoverUnits as in MouseoverUnit.lua
    The mo_unit has to have a table named mo_unit.animationInfo = {}
    Why this ?
    Creating an AnimationGroup on default frames would sometimes spread taint even on non protected frames. This solution only calls SetAlpha on the frame.
--]]
local _, addonTable = ...
local addon = addonTable.addon
addonTable.animations = {}
local MouseoverUnitAnimationMixin = addonTable.animations

local next = next

local AnimationQueue = {}

local AnimationUpdateFrame = CreateFrame("Frame")

local function Animation_OnUpdate(_, elapsed)
    for id, info in next, AnimationQueue do
        if not info.playing then
            info.playing = true
            info.elapsed = 0
            info.currentAlpha = info.startAlpha
        end
        info.elapsed = info.elapsed + elapsed
        if info.elapsed < info.duration then
            local alpha = info.startAlpha + ( ( info.endAlpha - info.startAlpha ) * ( info.elapsed / info.duration) )
            info.currentAlpha = alpha
            for _, frame in next, info.frames do
                frame:SetAlpha(alpha)
            end
        else
            info.currentAlpha = info.endAlpha
            if info.onAnimationFinished then
                info.onAnimationFinished(info)
            end
            for _, frame in next, info.frames do
                frame:SetAlpha(info.endAlpha)
            end
            AnimationQueue[id] = nil
        end
    end
    if next(AnimationQueue) == nil then
        AnimationUpdateFrame:SetScript("OnUpdate", nil)
        return
    end
end

--[[
    MouseOverUnit Mixins
]]

function MouseoverUnitAnimationMixin:FadeIn()
    local info = {
        frames = self.Parents,
        duration = self.animationSpeed_In,
        startAlpha = self.minAlpha,
        endAlpha = self.maxAlpha,
    }
    AnimationQueue[self.Parents] = info
    if next(AnimationQueue) ~= nil then
        AnimationUpdateFrame:SetScript("OnUpdate", Animation_OnUpdate)
    end
end

function MouseoverUnitAnimationMixin:FadeOut()
    local info = {
        frames = self.Parents,
        duration = self.animationSpeed_Out,
        startAlpha = self.maxAlpha,
        endAlpha = self.minAlpha,
    }
    AnimationQueue[self.Parents] = info
    if next(AnimationQueue) ~= nil then
        AnimationUpdateFrame:SetScript("OnUpdate", Animation_OnUpdate)
    end
end

function MouseoverUnitAnimationMixin:StopAnimation()
    AnimationQueue[self.Parents] = nil
    self.animationInfo.playing = nil
    if next(AnimationQueue) == nil then
        AnimationUpdateFrame:SetScript("OnUpdate", nil)
    end
end

--[[
    Addon wide:
    mandatory:
    frame = frame to play the animation on
    info = {
        duration = ...,
        startAlpha = ...,
        endAlpha = ...,
    }
    optional:
    info.onAnimationFinished = function(info)
        ...
    end
]]

function addon:Fade(frame, info)
    local info = info
    info.frames = {frame}
    AnimationQueue[frame] = info
    if next(AnimationQueue) ~= nil then
        AnimationUpdateFrame:SetScript("OnUpdate", Animation_OnUpdate)
    end
end

function addon:StopAnimation(frame)
    AnimationQueue[frame] = nil
    if next(AnimationQueue) == nil then
        AnimationUpdateFrame:SetScript("OnUpdate", nil)
    end
end
