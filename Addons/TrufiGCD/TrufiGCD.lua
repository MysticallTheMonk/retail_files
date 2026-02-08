-- TrufiGCD stevemyz@gmail.com

-- The module initializes settings and provides all necessary user events to the modules.

local IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

---@type string, Namespace
local addonName, ns = ...

---@param unitA UnitType
---@param unitB UnitType
---@return boolean
local function areUnitsEqual(unitA, unitB)
    local nameA = UnitName(unitA)
    return nameA and nameA == UnitName(unitB) and UnitHealth(unitA) == UnitHealth(unitB)
end

---@param unitType UnitType
local function checkIfUnitAlreadyInUse(unitType)
    for _, existedUnitType in ipairs(ns.constants.unitTypes) do
        if areUnitsEqual(unitType, existedUnitType) then
            ns.units[unitType]:Copy(ns.units[existedUnitType])
            return
        end
    end
end

local function OnLoad()
    ns.settings:Load()
    ns.settingsFrame.syncWithSettings()
    ns.blocklistFrame.syncWithSettings()
    ns.profileFrame.syncWithSettings()

    ns.locationCheck.settingsChanged()

    if not ns.constants.IsMidnight then
        local targetFocusChangeFrame = CreateFrame("Frame", nil, UIParent)
        targetFocusChangeFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        targetFocusChangeFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
        targetFocusChangeFrame:SetScript("OnEvent", function(_, changeEvent)
            if changeEvent == "PLAYER_TARGET_CHANGED" then
                ns.units.target:Clear()
                if ns.settings.activeProfile.layoutSettings.target.enable then
                    checkIfUnitAlreadyInUse("target")
                end
            elseif changeEvent == "PLAYER_FOCUS_CHANGED" then
                ns.units.focus:Clear()
                if ns.settings.activeProfile.layoutSettings.focus.enable then
                    checkIfUnitAlreadyInUse("focus")
                end
            end
        end)
    end

    --Delay the initialisation to prevent odd abilities spam at the first world enter
    C_Timer.After(0.5, function()
        local spellEventFrame = CreateFrame("Frame", nil, UIParent)
        if ns.constants.IsMidnight then
            spellEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
            spellEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
            spellEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
            spellEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
            spellEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
        else
            spellEventFrame:RegisterEvent("UNIT_SPELLCAST_START")
            spellEventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
            spellEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            spellEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
            spellEventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        end

        if IS_RETAIL then
            if ns.constants.IsMidnight then
                spellEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
                spellEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
            else
                spellEventFrame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
                spellEventFrame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
            end
        end

        spellEventFrame:SetScript("OnEvent", function(_, unitEvent, unitType, castId, spellId)
            if ns.units[unitType] and ns.locationCheck.isAddonEnabled() then
                ns.units[unitType]:OnSpellEvent(unitEvent, spellId, unitType, castId)
            end
        end)
    end)

    local minUpdateInterval = 0.03
    local lastUpdateTime = GetTime()

    local updateFrame = CreateFrame("Frame", nil, UIParent)
    updateFrame:SetScript("OnUpdate", function()
        local time = GetTime()
        local interval = time - lastUpdateTime
        if interval > minUpdateInterval then
            for _, unit in pairs(ns.units) do
                unit:Update(time, interval)
            end
            lastUpdateTime = time
        end
    end)

    if AddonCompartmentFrame then
        AddonCompartmentFrame:RegisterAddon({
            text = "TrufiGCD",
            icon = 4622474,
            notCheckable = true,
            registerForAnyClick = true,
            func = function(_, btn)
                if btn.buttonName == "LeftButton" then
                    Settings.OpenToCategory(ns.settingsFrame.category:GetID())
                else
                    ns.settingsFrame.toggleAnchors()
                end
            end,
            funcOnEnter = function(button)
                MenuUtil.ShowTooltip(button, function(tooltip)
                    tooltip:ClearLines()
                    tooltip:SetText("TrufiGCD")
                    tooltip:AddLine("|cffeda55fLeft-Click|r to open the settings.", 1, 1, 1, true)
                    tooltip:AddLine("|cffeda55fRight-Click|r to show frame anchors.", 1, 1, 1, true)
                    tooltip:Show()
                end)
            end,
            funcOnLeave = function(button)
                MenuUtil.HideTooltip(button)
            end,
        })
    end
end

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
    EventUtil.ContinueOnAddOnLoaded(addonName, OnLoad)
else
    local loadFrame = CreateFrame("Frame", nil, UIParent)
    loadFrame:RegisterEvent("ADDON_LOADED")
    loadFrame:SetScript("OnEvent", function(self, event, name)
        if name ~= addonName or event ~= "ADDON_LOADED" then
            return
        end

        OnLoad()

        self:UnregisterEvent("ADDON_LOADED")
    end)
end
