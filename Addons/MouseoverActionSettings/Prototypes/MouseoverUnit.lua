local _, addonTable = ...
local addon = addonTable.addon
local CR = addonTable.callbackRegistry
local Timer = addonTable.timerRegistry

local MouseoverUnit = {
    visibilityEvent = "META_UPDATE", --each object should have its own event
    statusEvents = {},
    isShown = true, --to guarantee that the frame can be hidden on first load
    minAlpha = 0,
    currentAlpha = 0,
    maxAlpha = 1,
    scriptRegions = {},
    delay = 3,
    animationSpeed_In = 0.2,  
    animationSpeed_Out = 0.25,
}
MouseoverUnit.metatable = {__index = MouseoverUnit}

function MouseoverUnit:Show()
    if self.isShown then
        return
    end
    self:StopAnimation()
    self:FadeIn()
    self.isShown = true
end

function MouseoverUnit:Hide()
    if not self.isShown then
        return
    end
    for status, value in pairs(self.preventHiding) do
        if value == true then
            return
        end
    end
    self:FadeOut()
    self.isShown = false
end

function MouseoverUnit:CreateHooks()
    for _, scriptRegion in pairs(self.scriptRegions) do
        self:HookScript(scriptRegion, "OnEnter", function()
            self.preventHiding.entered = true
            Timer:Stop(self.timer)
            CR:Fire(self.visibilityEvent, true)
            self:Show()
        end)
        self:HookScript(scriptRegion, "OnLeave", function()
            self.timer = Timer:Start(self.delay, function()
                self.preventHiding.entered = nil
                CR:Fire(self.visibilityEvent, false)
                self:Hide()
            end)
        end)
    end
end

function MouseoverUnit:RestoreMetaValues()
    self.delay = nil
    self.animationSpeed_In = nil
    self.animationSpeed_Out = nil
end

function MouseoverUnit:Disable()
    self:DisableHooks()
    for id, event in pairs(self.callbacks) do
        CR:UnregisterCallback(event, id)
        self.callbacks[id] = nil
    end
    Timer:Stop(self.timer)
    for _, timer in pairs(self.eventTimers) do
        Timer:Stop(timer)
    end
    self:StopAnimation()
    CR:Fire(self.visibilityEvent, false)
    self.preventHiding = {}
    for _, parent in pairs(self.Parents) do
        parent:SetAlpha(1)
    end
    self.isShown = true
    self:RestoreMetaValues()
end

function MouseoverUnit:Enable()
    for i=1,#self.statusEvents do
        local event = self.statusEvents[i]
        local id = CR:RegisterCallback(event, function(...)
            local status, delay = ...
            Timer:Stop(self.eventTimers[event])
            if status == true then       
                self.preventHiding[event] = true
                self:Show()
            else
                if delay and delay > 0 then
                    self.eventTimers[event] = Timer:Start(delay, function()
                        self.preventHiding[event] = nil
                        self:Hide()
                    end)
                else
                    self.preventHiding[event] = nil
                    self:Hide()
                end
            end
        end)
        self.callbacks[id] = event
    end
    self:CreateHooks()
    self:Hide()
end

function addon:NewMouseoverUnit(unit)
    setmetatable(unit, MouseoverUnit.metatable)
    Mixin(unit, addonTable.hooks)
    Mixin(unit, addonTable.animations)
    --following attributes have to be unit specific 
    unit.callbacks = {}
    unit.preventHiding = {}
    unit.timer = {}
    unit.eventTimers = {}
    unit.animationInfo = {}
    return unit 
end

function addon:MouseoverUnit_SetDefaultAnimationSpeed(animationSpeed_In, animationSpeed_Out)
    MouseoverUnit.animationSpeed_In = animationSpeed_In
    MouseoverUnit.animationSpeed_Out = animationSpeed_Out
end

function addon:MouseoverUnit_SetDefaultDelay(delay)
    MouseoverUnit.delay = delay
end