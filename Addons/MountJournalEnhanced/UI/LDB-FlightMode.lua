local ADDON_NAME, ADDON = ...


local function updateLDB(dataObject)
    local spellInfo = C_Spell.GetSpellInfo(ADDON.Api:IsDynamicFlight() and 404464 or 404468 )
    local label, name = string.match(spellInfo.name, "^(.*)\s*: (.*)$")
    dataObject.icon = spellInfo.iconID
    dataObject.text = name
    dataObject.label = label
end

ADDON.Events:RegisterCallback("OnLogin", function()
    local ldb = LibStub("LibDataBroker-1.1", true)
    if not ldb or not C_MountJournal.IsDragonridingUnlocked() then
        return
    end

    local dataObject

    local actionButton = CreateFrame("Button", nil, nil, "InsecureActionButtonTemplate")
    actionButton:SetAttribute("pressAndHoldAction", 1)
    actionButton:SetAttribute("type", "spell")
    actionButton:SetAttribute("typerelease", "spell")
    actionButton:RegisterForClicks("AnyUp")
    actionButton:SetPropagateMouseClicks(true)
    actionButton:SetPropagateMouseMotion(true)
    actionButton:RegisterUnitEvent("UNIT_AURA", "player")
    actionButton:SetScript("OnEvent", function()
        updateLDB(dataObject)
    end)
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

    local tooltipProxy = CreateFrame("Frame")
    tooltipProxy:Hide()
    tooltipProxy:HookScript("OnShow", function(self)
        local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint(1)

        actionButton:SetAttribute("spell", C_MountJournal.GetDynamicFlightModeSpellID())
        actionButton:SetParent(self:GetParent())
        actionButton:SetAllPoints(self:GetParent())
        actionButton:SetFrameStrata("DIALOG")
        actionButton:Raise()
        actionButton:Show()

        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
        GameTooltip:ClearLines()
        GameTooltip:SetSpellByID(C_MountJournal.GetDynamicFlightModeSpellID())
        GameTooltip:Show()
    end)
    tooltipProxy:HookScript("OnHide", function(self)
        GameTooltip:Hide()
        if not self:GetParent():IsMouseOver() then
            actionButton:Hide()
        end
    end)
    tooltipProxy.SetOwner = ADDON.UI.SetOwner

    local spellId = C_MountJournal.GetDynamicFlightModeSpellID()
    local icon = C_Spell.GetSpellTexture(spellId)
    dataObject = ldb:NewDataObject( ADDON_NAME.." Flight Mode", {
        type = "data source",
        text = C_Spell.GetSpellName(spellId),
        icon = icon,
        tooltip = tooltipProxy,
    })
    updateLDB(dataObject)

end, "ldb-flightmode")
