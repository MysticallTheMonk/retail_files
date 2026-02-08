local ADDON_NAME, ADDON = ...


local function updateLDB(dataObject)
    local spellInfo = C_Spell.GetSpellInfo(ADDON.Api:IsDynamicFlight() and 404464 or 404468 )
    local label, name = string.match(spellInfo.name, "^(.*)\s*: (.*)$")
    dataObject.icon = spellInfo.iconID
    dataObject.text = name
    dataObject.label = label
end

local actionButton = CreateFrame("Button", nil, nil, "InsecureActionButtonTemplate")
actionButton:SetAttribute("pressAndHoldAction", 1)
actionButton:SetAttribute("type", "spell")
actionButton:SetAttribute("typerelease", "spell")
actionButton:RegisterForClicks("AnyUp")
actionButton:SetPropagateMouseClicks(true)
actionButton:SetPropagateMouseMotion(true)
actionButton:RegisterUnitEvent("UNIT_AURA", "player")
actionButton:HookScript("PreClick", function(self)
    if not InCombatLockdown() and self:GetParent():IsDragging() then
        self:SetAttribute("type", "")
        self:SetAttribute("typerelease", "")
    end
end)
actionButton:HookScript("PostClick", function(self)
    if not InCombatLockdown() then
        self:SetAttribute("type", "spell")
        self:SetAttribute("typerelease", "spell")
    end
end)
actionButton:Hide()

ADDON.Events:RegisterCallback("OnLogin", function()
    local ldb = LibStub("LibDataBroker-1.1", true)
    if not ldb or not C_MountJournal.IsDragonridingUnlocked() then
        return
    end

    local dataObject

    actionButton:SetScript("OnEvent", function()
        updateLDB(dataObject)
    end)

    local tooltipProxy = CreateFrame("Frame")
    tooltipProxy:Hide()
    tooltipProxy:HookScript("OnShow", function(self)
        local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint(1)

        actionButton:SetAttribute("spell", C_MountJournal.GetDynamicFlightModeSpellID())
        local actionHookTarget = self:GetParent() or relativeTo
        actionButton:SetParent(actionHookTarget)
        actionButton:SetAllPoints(actionHookTarget)
        actionButton:SetFrameStrata("FULLSCREEN")
        actionButton:Raise()
        actionButton:Show()

        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
        GameTooltip:ClearLines()
        GameTooltip:SetSpellByID(C_MountJournal.GetDynamicFlightModeSpellID())
        GameTooltip:Show()
    end)
    tooltipProxy:HookScript("OnHide", function()
        GameTooltip:Hide()
        if not actionButton:GetParent():IsMouseOver() then
            actionButton:Hide()
        end
    end)
    tooltipProxy.SetOwner = ADDON.UI.SetOwner

    local ldbName = ADDON_NAME.." Flight Mode"
    local ldbData = { type = "data source", tooltip = tooltipProxy }
    updateLDB(ldbData)
    local label = ldbData.label -- Titan Panel uses label as entry name in its plugin list.
    ldbData.label = ldbName
    dataObject = ldb:NewDataObject( ldbName, ldbData)
    C_Timer.After(0, function()
        dataObject.label = label
    end)

end, "ldb-flightmode")
