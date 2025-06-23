local _, addonTable = ...
addonTable.events["TARGET_ATTACKABLE_UPDATE"] = false
local CR = addonTable.callbackRegistry

local function OnEvent()
    local targetExists = UnitExists("target")
    local isAlive = not UnitIsDead("target") 
    local canAttack = UnitCanAttack("player", "target") 
    local targetAttackable = targetExists and isAlive and canAttack
    CR:Fire("TARGET_ATTACKABLE_UPDATE", targetAttackable)
    addonTable.events["TARGET_ATTACKABLE_UPDATE"] = targetAttackable
end

local frame = nil
local targetAttackable = {}
function targetAttackable:Start()
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent ) 
    end
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_FACTION", "target") -- For when the target becomes attackable while targeting it.
    OnEvent()
end

function targetAttackable:Stop()
    if not frame then
        return
    end
    frame:UnregisterAllEvents()
end

CR:RegisterStatusEvent("TARGET_ATTACKABLE_UPDATE", targetAttackable)
