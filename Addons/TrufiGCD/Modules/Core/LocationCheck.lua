---@type string, Namespace
local _, ns = ...

---Watches for player location changes and turns on/off the addon according to location settings.
---@class LocationCheck
local locationCheck = {}
ns.locationCheck = locationCheck

local eventFrame = CreateFrame("Frame", nil, UIParent)
eventFrame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

--- @type "unknown" | "world" | "party" | "arena" | "pvp" | "raid"
local playerLocation = "unknown"

local addonEnabled = true

locationCheck.isAddonEnabled = function()
    return addonEnabled
end

---@param event string
local function onEvent(_, event)
    local _, instanceType = IsInInstance()
    local enabledIn = ns.settings.activeProfile.enabledIn

    if event == "PLAYER_REGEN_DISABLED" and enabledIn.combatOnly then -- Entering combat, specific for each zone
        if instanceType == "arena" then
            playerLocation = "arena"
            addonEnabled = enabledIn.arena
        elseif instanceType == "pvp" then
            playerLocation = "pvp"
            addonEnabled = enabledIn.battleground
        elseif instanceType == "party" then
            playerLocation = "party"
            addonEnabled = enabledIn.party
        elseif instanceType == "raid" then
            playerLocation = "raid"
            addonEnabled = enabledIn.raid
        elseif instanceType ~= "arena" or instanceType ~= "pvp" then
            playerLocation = "world"
            addonEnabled = enabledIn.world
        end
    elseif event == "PLAYER_REGEN_ENABLED" and enabledIn.combatOnly then -- Ending combat
        addonEnabled = false
    elseif event == "PLAYER_ENTERING_BATTLEGROUND" and not enabledIn.combatOnly then -- if not Combat only, try to load at locations
        if instanceType == "arena" then
            playerLocation = "arena"
            addonEnabled = enabledIn.arena
        elseif instanceType == "pvp" then
            playerLocation = "pvp"
            addonEnabled = enabledIn.battleground
        end
    elseif event == "PLAYER_ENTERING_WORLD" and not enabledIn.combatOnly then -- if not Combat only, try to load at locations
        if instanceType == "party" then
            playerLocation = "party"
            addonEnabled = enabledIn.party
        elseif instanceType == "raid" then
            playerLocation = "raid"
            addonEnabled = enabledIn.raid
        elseif instanceType ~= "arena" or instanceType ~= "pvp" then
            playerLocation = "world"
            addonEnabled = enabledIn.world
        end
    elseif event == "PLAYER_ENTERING_BATTLEGROUND" and enabledIn.combatOnly then -- if Combat only and just loaded in location
        if instanceType == "arena" then
            playerLocation = "arena"
            if enabledIn.arena then addonEnabled = false end
        elseif instanceType == "pvp" then
            playerLocation = "pvp"
            if enabledIn.battleground then addonEnabled = false end
        end
    elseif event == "PLAYER_ENTERING_WORLD" and enabledIn.combatOnly then -- if Combat only and just loaded in location
        if instanceType == "party" then
            playerLocation = "party"
            if enabledIn.party then addonEnabled = false end
        elseif instanceType == "raid" then
            playerLocation = "raid"
            if enabledIn.raid then addonEnabled = false end
        elseif instanceType ~= "arena" or instanceType ~= "pvp" then
            playerLocation = "world"
            if enabledIn.world then addonEnabled = false end
        end
    end
end

eventFrame:SetScript("OnEvent", onEvent)

locationCheck.settingsChanged = function()
    local settings = ns.settings.activeProfile

    if not settings.enabledIn.enabled or settings.enabledIn.combatOnly then
        addonEnabled = false
    elseif playerLocation == "world" then
        addonEnabled = settings.enabledIn.world
    elseif playerLocation == "party" then
        addonEnabled = settings.enabledIn.party
    elseif playerLocation == "arena" then
        addonEnabled = settings.enabledIn.arena
    elseif playerLocation == "pvp" then
        addonEnabled = settings.enabledIn.battleground
    elseif playerLocation == "raid" then
        addonEnabled = settings.enabledIn.raid
    end

    if not addonEnabled then
        for _, unit in ipairs(ns.units) do
            unit:Clear()
        end
    end
end
