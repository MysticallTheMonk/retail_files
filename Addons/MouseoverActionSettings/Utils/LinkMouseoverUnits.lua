--[[
    one-way link by design to allow greater flexibility while tweaking the UI
]]
local _, addonTable = ...
local addon = addonTable.addon
local CR = addonTable.callbackRegistry
local Timer = addonTable.timerRegistry

function addon:LinkMouseoverUnit(target_mo_unit, link_with_module_name)
    local link_module = addon:GetModule(link_with_module_name, true)
    if not link_module then
        return
    end
    if not link_module.GetMouseoverUnit then
        return
    end
    local link_mo_unit = link_module:GetMouseoverUnit()
    local event = link_mo_unit.visibilityEvent
    local id = CR:RegisterCallback(event, function(status)
        target_mo_unit.preventHiding[event] = status
        if status then
            target_mo_unit:Show() 
        else
            target_mo_unit:Hide()
        end
    end)
    target_mo_unit.callbacks[id] = event
end