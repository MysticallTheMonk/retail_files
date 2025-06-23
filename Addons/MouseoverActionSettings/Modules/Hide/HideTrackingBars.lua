local _, addonTable = ...
local addon = addonTable.addon

local module = addon:NewModule("HideTrackingBars")
Mixin(module, addonTable.hooks)

function module:OnEnable()
    local function hideRegion(region)
        self:HookScript(region, "OnShow", region.hide)
        region:Hide()
    end
    self:IterateRegions(hideRegion)
end

function module:OnDisable()
    self:DisableHooks()
    local function restoreRegion(region)
        region:Show()
    end
    self:IterateRegions(restoreRegion)
end

function module:IterateRegions(callback)
    for _, region in pairs({
        StatusTrackingBarManager
    }) do
        callback(region)
    end
end