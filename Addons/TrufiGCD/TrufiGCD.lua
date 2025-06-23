-- TrufiGCD stevemyz@gmail.com

-- The module initializes settings and provides all necessary user events to the modules.

local IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

---@type string, Namespace
local _, ns = ...

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

local loadFrame = CreateFrame("Frame", nil, UIParent)
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:SetScript("OnEvent", function(_, event, name)
    if name ~= "TrufiGCD" or event ~= "ADDON_LOADED" then
        return
    end

    ns.settings:Load()
    ns.settingsFrame.syncWithSettings()
    ns.blocklistFrame.syncWithSettings()
    ns.profileFrame.syncWithSettings()

    ns.locationCheck.settingsChanged()

    local targetFocusChangeFrame = CreateFrame("Frame", nil, UIParent)
    targetFocusChangeFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
    targetFocusChangeFrame:RegisterEvent('PLAYER_FOCUS_CHANGED')
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

    --Delay the initialisation to prevent odd abilities spam at the first world enter
    C_Timer.After(0.5, function()
        local spellEventFrame = CreateFrame("Frame", nil, UIParent)
        spellEventFrame:RegisterEvent("UNIT_SPELLCAST_START")
        spellEventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        spellEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        spellEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
        spellEventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

        if IS_RETAIL then
            spellEventFrame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
            spellEventFrame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
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
end)

if IS_RETAIL then
    AddonCompartmentFrame:RegisterAddon({
        text = "TrufiGCD",
        icon = 4622474,
        notCheckable = true,
        registerForAnyClick = true,
        func = function(_, btn)
            if btn.buttonName == "LeftButton" then
                Settings.OpenToCategory(ns.settingsFrame.frame.name)
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
