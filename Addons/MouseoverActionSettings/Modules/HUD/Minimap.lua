local addonName, addonTable = ...
local addon = addonTable.addon
local CR = addonTable.callbackRegistry
local Timer = addonTable.timerRegistry
local LDBI = LibStub("LibDBIcon-1.0")

local mo_unit = {
    Parents = {MinimapCluster},
    visibilityEvent = "MINIMAP_UPDATE",   
    scriptRegions = {
        Minimap,
        MinimapCluster,
        --MiniMapMailIcon, --hooking this will prevent the unread mail pop up from showing
        GameTimeFrame,
        AddonCompartmentFrame,
        MinimapZoneText,
        ExpansionLandingPageMinimapButton,
        --MinimapBackdrop, --hooking this will prevent the minimap content from showing tooltips and pinging
        --MinimapCompassTexture,
    },
    statusEvents = {},
}

mo_unit = addon:NewMouseoverUnit(mo_unit)

local module = addon:NewModule("Minimap")

function module:OnEnable()
    local dbObj = addon.db.profile["Minimap"]
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
    local buttonList = LDBI:GetButtonList()
    for _,name in pairs(buttonList) do 
        local button = LDBI:GetMinimapButton(name)
        table.insert(mo_unit.scriptRegions, button)
    end
    LDBI.RegisterCallback(addonName, "LibDBIcon_IconCreated", function(_, button, _) 
        table.insert(mo_unit.scriptRegions, button)
        mo_unit:CreateHooks()
    end)
    mo_unit:Enable()
end

function module:OnDisable()
    mo_unit:Disable()
end

function module:GetMouseoverUnit()
    return mo_unit
end

--[[
    :SetAlpha(0) does not hide the the Minimap content like player arrow and quest zones
]]

function mo_unit:FadeIn()
    if not Minimap:IsShown() then
        Minimap:Show()
    end
    local info = {
        duration = self.animationSpeed_In,
        startAlpha = self.minAlpha,
        endAlpha = self.maxAlpha,
    }
    addon:Fade(self.Parents[1], info)
end

function mo_unit:FadeOut()
    local info = {
        duration = self.animationSpeed_Out,
        startAlpha = self.maxAlpha,
        endAlpha = self.minAlpha,
    }
    info.onAnimationFinished = function(info)
        if info.currentAlpha == 0 then
            Minimap:Hide()
        end
    end
    addon:Fade(self.Parents[1], info)
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
    for _, parent in pairs(self.Parents) do
        parent:SetAlpha(1)
    end
    if not Minimap:IsShown() then
        Minimap:Show()
    end
    self.isShown = true
end