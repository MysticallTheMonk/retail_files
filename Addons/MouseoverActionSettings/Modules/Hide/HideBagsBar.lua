local _, addonTable = ...
local addon = addonTable.addon

local module = addon:NewModule("HideBagsBar")
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
        MainMenuBarBackpackButton,
        CharacterBag0Slot,
        CharacterBag1Slot,
        CharacterBag2Slot,
        CharacterBag3Slot,
        CharacterReagentBag0Slot,
        BagBarExpandToggle, 
    }) do
        callback(region)
    end
end