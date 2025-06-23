local _, addonTable = ...
local addon = addonTable.addon

local module = addon:NewModule("GlobalSettings")

function module:OnEnable()
    local dbObj = addon.db.profile.GlobalSettings
    addon:MouseoverUnit_SetDefaultAnimationSpeed(dbObj.animationSpeed_In, dbObj.animationSpeed_Out)
    addon:MouseoverUnit_SetDefaultDelay(dbObj.delay)
end

