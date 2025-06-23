local _, addonTable = ...
local addon = addonTable.addon
local CR = addonTable.callbackRegistry
local Timer = addonTable.timerRegistry

local mo_unit = {
    visibilityEvent = "CHAT_FRAME_UPDATE",   
    scriptRegions = {
        QuickJoinToastButton,
        CombatLogQuickButtonFrame_Custom,
        CombatLogQuickButtonFrameButton1,
        CombatLogQuickButtonFrameButton2,
        TextToSpeechButton,
    },
    statusEvents = {},
}

for i=1, NUM_CHAT_WINDOWS do
    for _, texture in pairs {
        _G["ChatFrame" .. i .. "Tab"],
        _G["ChatFrame" .. i],
        _G["ChatFrame" .. i .. "TopTexture"],
        _G["ChatFrame" .. i .. "EditBox"],
    } do
        table.insert(mo_unit.scriptRegions, texture)
    end
end

mo_unit = addon:NewMouseoverUnit(mo_unit)

local module = addon:NewModule("ChatFrame")
Mixin(module, addonTable.hooks)

function module:OnEnable()
    local dbObj = addon.db.profile["ChatFrame"]
    if dbObj.useCustomDelay then
        mo_unit.delay = dbObj.delay
    end
    mo_unit.minAlpha = dbObj.minAlpha
    mo_unit.maxAlpha = dbObj.maxAlpha
    if dbObj.useCustomAnimationSpeed then
        mo_unit.animationSpeed_In = dbObj.animationSpeed_In
        mo_unit.animationSpeed_Out = dbObj.animationSpeed_Out
    end
    mo_unit.statusEvents = {}
    for event, _ in pairs(addonTable.events) do
        if dbObj[event] then
            table.insert(mo_unit.statusEvents, event)
        end
    end
    for link, value in pairs(dbObj.links) do
        if value == true then
            addon:LinkMouseoverUnit(mo_unit, link)
        end
    end
    self:HookFunc("ChatEdit_DeactivateChat", function(editBox)
        mo_unit.preventHiding["ChatEdit_ActivateChat"] = nil
        mo_unit:Hide()
    end)
    self:HookFunc("ChatEdit_ActivateChat", function()
        mo_unit.preventHiding["ChatEdit_ActivateChat"] = true
        mo_unit:Show()
    end)
    self:HookFunc("FCFTab_UpdateAlpha", function()
        if mo_unit.isShown then
            return
        end
        mo_unit:Hide()
    end)    
    mo_unit:Enable()
end

function module:OnDisable()
    self:DisableHooks()
    mo_unit:Disable()
end

function module:GetMouseoverUnit()
    return mo_unit
end

--[[
    Chat Frames Parent is UIParent so this module needs its own solution
    original function in Animation.lua
]]--

function mo_unit:FadeIn()
    for _, region in next, self.scriptRegions do
        -- info table must be a unique instance for each region for Animation_OnUpdate to work properly
        local info = {
            duration = self.animationSpeed_In,
            startAlpha = self.minAlpha,
            endAlpha = self.maxAlpha,
        }
        addon:Fade(region, info)
    end
end

function mo_unit:FadeOut()
    for _, region in next, self.scriptRegions do
        local info = {
            duration = self.animationSpeed_Out,
            startAlpha = self.maxAlpha,
            endAlpha = self.minAlpha,
        }
        addon:Fade(region, info)
    end
end

function mo_unit:StopAnimation()
    for _, region in next, self.scriptRegions do
        addon:StopAnimation(region)
    end 
end

function mo_unit:Disable()
    self:DisableHooks()
    for id, event in pairs(self.callbacks) do
        CR:UnregisterCallback(event, id)
        self.callbacks[id] = nil
    end
    Timer:Stop(self.timer)
    self:StopAnimation()
    CR:Fire(self.visibilityEvent, false)
    self.preventHiding = {}
    for _, region in next, self.scriptRegions do
        region:SetAlpha(1)
    end 
    self.isShown = true
end


