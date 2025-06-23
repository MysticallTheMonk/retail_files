local _, addonTable = ...
local addon = addonTable.addon
local CR = addonTable.callbackRegistry

local mo_unit = {
    Parents = {FocusFrame},
    visibilityEvent = "Focus_FRAME_UPDATE",   
    scriptRegions = {
        FocusFrame,
        FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar,
        FocusFrameToT,
        FocusFrameToT.HealthBar
    },
    statusEvents = {},
}

mo_unit = addon:NewMouseoverUnit(mo_unit)

local module = addon:NewModule("FocusFrame")

function module:OnEnable()
    local dbObj = addon.db.profile["FocusFrame"]
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
    mo_unit:Enable()
end

function module:OnDisable()
    mo_unit:Disable()
end

function module:GetMouseoverUnit()
    return mo_unit
end