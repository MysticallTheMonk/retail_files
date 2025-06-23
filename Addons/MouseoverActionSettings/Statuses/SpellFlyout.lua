local _, addonTable = ...
local addon = addonTable.addon

local hide_blocked_flyout_parents = {}

local function handleShown(SpellFlyout)
    local parent = SpellFlyout:GetParent()

    if not parent then
        return
    end

    local actionBar = parent:GetParent():GetParent():GetDebugName()

    if actionBar:match("SpellBookFrame") then
        return
    end
    if not addon:IsModuleEnabled(actionBar) then
        return
    end

    local mo_unit = addon:GetModule(actionBar):GetMouseoverUnit()
    mo_unit.preventHiding["SPELL_FLYOUT"] = true
    table.insert(hide_blocked_flyout_parents, mo_unit)
end

local function handleHide(SpellFlyout)
    for _, mo_unit in next, hide_blocked_flyout_parents do
        mo_unit.preventHiding["SPELL_FLYOUT"] = nil
        mo_unit:Hide()
    end
    hide_blocked_flyout_parents = {}
end

SpellFlyout:HookScript("OnSizeChanged", handleShown)  --OnHide and OnShow do not fire when directly switching from one SpellFlyout to the other 


SpellFlyout:HookScript("OnHide", handleHide)