-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI Data Repair Module
-- Fixes SavedVariables corruption (sparse arrays in resourceBars/cooldownBars)
-- Version: 1.4
-- ═══════════════════════════════════════════════════════════════════════════

local ADDON_NAME, ns = ...

ns.DataRepair = ns.DataRepair or {}
local DR = ns.DataRepair

local MSG_PREFIX = "|cff00ccffArcUI|r |cffffaa00[DataRepair]|r: "

local function PrintMsg(msg)
    print(MSG_PREFIX .. msg)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- REPAIR: Fill Sparse Array Holes in resourceBars
-- ═══════════════════════════════════════════════════════════════════════════
local function FillResourceBarHoles()
    if not ns.db or not ns.db.char or not ns.db.char.resourceBars then 
        return 0 
    end
    
    local resourceBars = ns.db.char.resourceBars
    local maxIndex = 0
    local fixed = 0
    
    for k, v in pairs(resourceBars) do
        if type(k) == "number" and k >= 1 and math.floor(k) == k then
            if k > maxIndex then maxIndex = k end
        end
    end
    
    for i = 1, maxIndex do
        if resourceBars[i] == nil then
            resourceBars[i] = CopyTable(ns.DB_DEFAULTS.char.resourceBars[1])
            resourceBars[i].tracking.enabled = false
            resourceBars[i].display.enabled = false
            local yOffset = -100 - ((i - 1) * 35)
            resourceBars[i].display.barPosition.y = yOffset
            resourceBars[i].display.textPosition.y = yOffset + 30
            PrintMsg("Filled empty resourceBars[" .. i .. "]")
            fixed = fixed + 1
        end
    end
    
    return fixed
end

-- ═══════════════════════════════════════════════════════════════════════════
-- REPAIR: Fill Sparse Array Holes in cooldownBars
-- ═══════════════════════════════════════════════════════════════════════════
local function FillCooldownBarHoles()
    if not ns.db or not ns.db.char or not ns.db.char.cooldownBars then 
        return 0 
    end
    
    local cooldownBars = ns.db.char.cooldownBars
    local maxIndex = 0
    local fixed = 0
    
    for k, v in pairs(cooldownBars) do
        if type(k) == "number" and k >= 1 and math.floor(k) == k then
            if k > maxIndex then maxIndex = k end
        end
    end
    
    for i = 1, maxIndex do
        if cooldownBars[i] == nil then
            cooldownBars[i] = CopyTable(ns.DB_DEFAULTS.char.cooldownBars[1])
            cooldownBars[i].tracking.enabled = false
            cooldownBars[i].display.enabled = false
            local yOffset = -200 - ((i - 1) * 30)
            cooldownBars[i].display.barPosition.y = yOffset
            cooldownBars[i].display.textPosition.y = yOffset + 30
            cooldownBars[i].display.iconPosition.y = yOffset
            PrintMsg("Filled empty cooldownBars[" .. i .. "]")
            fixed = fixed + 1
        end
    end
    
    return fixed
end

-- ═══════════════════════════════════════════════════════════════════════════
-- REPAIR: Fix Missing CDM Profile
-- ═══════════════════════════════════════════════════════════════════════════
local function FixMissingActiveProfile()
    if not ns.db or not ns.db.char or not ns.db.char.cdmGroups then
        return 0
    end
    
    local cdmGroups = ns.db.char.cdmGroups
    if not cdmGroups.specData then return 0 end
    
    local fixed = 0
    
    for specKey, specData in pairs(cdmGroups.specData) do
        if type(specData) == "table" and specData.layoutProfiles and specData.activeProfile then
            local activeProfile = specData.activeProfile
            if not specData.layoutProfiles[activeProfile] then
                PrintMsg("Profile '" .. activeProfile .. "' missing for " .. specKey)
                
                if specData.layoutProfiles["Default"] then
                    specData.activeProfile = "Default"
                    PrintMsg("Reset to 'Default' profile")
                else
                    specData.layoutProfiles["Default"] = {
                        savedPositions = {},
                        freeIcons = {},
                        groupLayouts = {},
                        iconSettings = {},
                    }
                    specData.activeProfile = "Default"
                    PrintMsg("Created new 'Default' profile")
                end
                fixed = fixed + 1
            end
        end
    end
    
    return fixed
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MAIN REPAIR FUNCTION
-- ═══════════════════════════════════════════════════════════════════════════
function DR.RepairSavedVariables()
    local repairCount = 0
    
    repairCount = repairCount + FillResourceBarHoles()
    repairCount = repairCount + FillCooldownBarHoles()
    repairCount = repairCount + FixMissingActiveProfile()
    
    return repairCount
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EMERGENCY REPAIR
-- ═══════════════════════════════════════════════════════════════════════════
function DR.EmergencyRepair()
    PrintMsg("Running emergency repair...")
    
    local repairCount = DR.RepairSavedVariables()
    
    -- Create current spec data if missing
    if ns.db and ns.db.char and ns.db.char.cdmGroups then
        local cdmGroups = ns.db.char.cdmGroups
        
        if not cdmGroups.specData then
            cdmGroups.specData = {}
            PrintMsg("Created missing specData table")
            repairCount = repairCount + 1
        end
        
        local specIdx = GetSpecialization() or 1
        local _, _, classID = UnitClass("player")
        classID = classID or 0
        local currentSpec = "class_" .. classID .. "_spec_" .. specIdx
        
        if not cdmGroups.specData[currentSpec] then
            cdmGroups.specData[currentSpec] = {
                iconSettings = {},
                layoutProfiles = {
                    ["Default"] = {
                        savedPositions = {},
                        freeIcons = {},
                        groupLayouts = {},
                        iconSettings = {},
                    },
                },
                activeProfile = "Default",
                groupSettings = {},
            }
            PrintMsg("Created specData for " .. currentSpec)
            repairCount = repairCount + 1
        end
    end
    
    if repairCount > 0 then
        PrintMsg("|cff00ff00Emergency repair: " .. repairCount .. " fixes|r")
        PrintMsg("Please /reload to apply changes")
    else
        PrintMsg("No repairs needed - data looks healthy!")
    end
    
    return repairCount
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SLASH COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════
SLASH_ARCUIREPAIR1 = "/arcuirepair"
SLASH_ARCUIREPAIR2 = "/arcrepair"
SlashCmdList["ARCUIREPAIR"] = function(msg)
    if msg == "emergency" then
        DR.EmergencyRepair()
    else
        local count = DR.RepairSavedVariables()
        if count == 0 then
            PrintMsg("No repairs needed - data looks healthy!")
        else
            PrintMsg("|cff00ff00Completed " .. count .. " repairs|r")
        end
    end
end

-- Export
ns.DataRepair = DR