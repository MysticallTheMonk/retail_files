local _, addonTable = ...
local addon = addonTable.addon

local module = addon:NewModule("ActionBarConfig")
Mixin(module, addonTable.hooks)
local Media = LibStub("LibSharedMedia-3.0")

local actionBars = {
    "Action", --MainActionBar Buttons are not named after parent
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarRight",
    "MultiBarLeft",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7",
}

function module:OnEnable()
    local dbObj = addon.db.profile.ActionBarConfig
    for _, actionBar in pairs (actionBars) do 
        if dbObj[actionBar] then
            self:UpdateButtonTextVisibility(actionBar, dbObj.hideHotkey, dbObj.hideCount, dbObj.hideName)
        end
        self:UpdateFonts(actionBar)
    end
end

function module:OnDisable()
    self:DisableHooks()
    for _, actionBar in pairs (actionBars) do 
        self:UpdateButtonTextVisibility(actionBar, false, false, false)
    end
end

function module:UpdateButtonTextVisibility(actionBar, hideHotkey, hideCount, hideName)
    for actionButton = 1, 12 do 
        local hotKeyTxt = _G[actionBar .. "Button" .. actionButton .. "HotKey"]
        if hideHotkey then
            hotKeyTxt:SetAlpha(0)
            self:HookScript(hotKeyTxt, "OnShow", function()
                hotKeyTxt:SetAlpha(0)
            end)
        else
            hotKeyTxt:SetAlpha(1)
        end
        local countTxt = _G[actionBar .. "Button" .. actionButton .. "Count"]
        if hideCount then
            countTxt:SetAlpha(0)
            self:HookScript(countTxt, "OnShow", function()
                countTxt:SetAlpha(0)
            end)
        else
            countTxt:SetAlpha(1)
        end
        local nameTxt = _G[actionBar .. "Button" .. actionButton .. "Name"]
        if hideName then
            nameTxt:SetAlpha(0)
            self:HookScript(nameTxt, "OnShow", function()
                nameTxt:SetAlpha(0)
            end)
        else
            nameTxt:SetAlpha(1)
        end
    end
end

function module:UpdateFonts(actionbar)
    local dbObjHotKey = addon.db.profile.HotKeyFontSettings
    local dbObjCount = addon.db.profile.CountFontSettings
    local dbObjName = addon.db.profile.NameFontSettings
    
    for actionButton = 1, 12 do 
        local hotKeyTxt = _G[actionbar .. "Button" .. actionButton .. "HotKey"]
        hotKeyTxt:SetFont(Media:Fetch("font", dbObjHotKey.font), dbObjHotKey.height, dbObjHotKey.flags)

        local countTxt = _G[actionbar .. "Button" .. actionButton .. "Count"]
        countTxt:SetFont(Media:Fetch("font", dbObjCount.font), dbObjCount.height, dbObjCount.flags)

        local nameTxt = _G[actionbar .. "Button" .. actionButton .. "Name"]
        nameTxt:SetFont(Media:Fetch("font", dbObjName.font), dbObjName.height, dbObjName.flags)
    end
end