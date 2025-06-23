local _, addonTable = ...
addonTable.events["EDIT_MODE_UPDATE"] = false
local CR = addonTable.callbackRegistry

local EditModeManagerFrame = EditModeManagerFrame

EditModeManagerFrame:HookScript("OnShow", function()
    CR:Fire("EDIT_MODE_UPDATE", true)
end)

EditModeManagerFrame:HookScript("OnHide", function()
    CR:Fire("EDIT_MODE_UPDATE", false)
end)