-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI_CDMGroups_ImportRestore.lua
-- Handles smart import restoration:
--   - Icons in imported data → placed according to import (groups, positions)
--   - Icons NOT in imported data → placed as free icons in a grid sequence
-- This ensures imported layouts work perfectly while new abilities are accessible
-- PERSISTS ACROSS RELOAD via SavedVariables
-- ═══════════════════════════════════════════════════════════════════════════

local ADDON, ns = ...

ns.CDMGroups = ns.CDMGroups or {}
ns.CDMGroups.ImportRestore = ns.CDMGroups.ImportRestore or {}

local ImportRestore = ns.CDMGroups.ImportRestore

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE (will be loaded from/saved to DB)
-- ═══════════════════════════════════════════════════════════════════════════

local importState = {
    active = false,                  -- Are we in import restoration mode?
    knownCooldownIDs = {},           -- Set of cdIDs that were in the import
    unknownIconsPlaced = {},         -- cdIDs we placed as free icons
    expirationTime = nil,            -- Auto-expire import mode (Unix timestamp via time())
    
    -- Grid placement for unknown icons
    gridStartX = 0,                  -- Starting X position (center)
    gridStartY = 200,                -- Starting Y position (above center)
    gridSpacing = 42,                -- Spacing between icons (36 + 6 padding)
    gridCols = 8,                    -- Icons per row
    nextGridIndex = 0,               -- Next position in grid
}

-- Duration to stay in import mode (seconds) - auto-expire after this
local IMPORT_MODE_DURATION = 300  -- 5 minutes to allow for reload

-- Helper to normalize cdID to consistent type (number if possible)
local function NormalizeCdID(cdID)
    if type(cdID) == "number" then return cdID end
    if type(cdID) == "string" then
        -- Arc Aura IDs start with "arc_" - keep as string
        if cdID:match("^arc_") then return cdID end
        -- Try to convert numeric strings to numbers
        local num = tonumber(cdID)
        if num then return num end
    end
    return cdID
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function PrintMsg(msg)
    print("|cff00ccffArcUI Import:|r " .. msg)
end

local function DebugPrint(msg)
    if ns.CDMGroups and ns.CDMGroups.debugEnabled then
        print("|cff888888[ImportRestore]|r " .. msg)
    end
end

-- Calculate grid position for the Nth unknown icon
local function GetGridPosition(index)
    local col = index % importState.gridCols
    local row = math.floor(index / importState.gridCols)
    
    -- Center the grid horizontally
    local totalWidth = (importState.gridCols - 1) * importState.gridSpacing
    local startX = importState.gridStartX - (totalWidth / 2)
    
    local x = startX + (col * importState.gridSpacing)
    local y = importState.gridStartY - (row * importState.gridSpacing)
    
    return x, y
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PERSISTENCE (Save/Load state to survive reload)
-- ═══════════════════════════════════════════════════════════════════════════

local function GetDB()
    if not ns.db or not ns.db.char then return nil end
    if not ns.db.char.importRestore then
        ns.db.char.importRestore = {}
    end
    return ns.db.char.importRestore
end

local function SaveState()
    local db = GetDB()
    if not db then 
        DebugPrint("Cannot save state - no DB")
        return 
    end
    
    -- Convert knownCooldownIDs set to array for serialization
    local knownArray = {}
    for cdID in pairs(importState.knownCooldownIDs) do
        table.insert(knownArray, cdID)
    end
    
    db.active = importState.active
    db.knownCooldownIDs = knownArray
    db.unknownIconsPlaced = importState.unknownIconsPlaced
    db.expirationTime = importState.expirationTime
    db.nextGridIndex = importState.nextGridIndex
    
    DebugPrint("State saved to DB")
end

local function ClearSavedState()
    local db = GetDB()
    if db then
        db.active = nil
        db.knownCooldownIDs = nil
        db.unknownIconsPlaced = nil
        db.expirationTime = nil
        db.nextGridIndex = nil
    end
end

local function LoadState()
    local db = GetDB()
    if not db then return false end
    
    if not db.active then
        return false  -- No pending import
    end
    
    -- Check if expired using Unix timestamp (time() persists across reload)
    if db.expirationTime and time() >= db.expirationTime then
        DebugPrint("Import state expired during reload")
        ClearSavedState()
        return false
    end
    
    -- Restore state
    importState.active = true
    importState.expirationTime = db.expirationTime
    importState.nextGridIndex = db.nextGridIndex or 0
    importState.unknownIconsPlaced = db.unknownIconsPlaced or {}
    
    -- Convert array back to set with normalized keys
    importState.knownCooldownIDs = {}
    if db.knownCooldownIDs then
        for _, cdID in ipairs(db.knownCooldownIDs) do
            local normalized = NormalizeCdID(cdID)
            importState.knownCooldownIDs[normalized] = true
        end
    end
    
    local knownCount = 0
    for _ in pairs(importState.knownCooldownIDs) do
        knownCount = knownCount + 1
    end
    
    PrintMsg("Import mode restored after reload - " .. knownCount .. " known cooldowns")
    
    -- Set up expiration timer using remaining time
    local timeRemaining = importState.expirationTime - time()
    if timeRemaining > 0 then
        C_Timer.After(timeRemaining + 1, function()
            if importState.active and time() >= importState.expirationTime then
                ImportRestore.Deactivate("timeout")
            end
        end)
    else
        -- Already expired
        ImportRestore.Deactivate("timeout")
        return false
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- IMPORT MODE CONTROL
-- ═══════════════════════════════════════════════════════════════════════════

-- Activate import restoration mode with the imported data
-- Called by ImportExport after successful import
function ImportRestore.Activate(importedData)
    -- Reset state
    importState.active = true
    importState.knownCooldownIDs = {}
    importState.unknownIconsPlaced = {}
    importState.expirationTime = time() + IMPORT_MODE_DURATION  -- Use Unix timestamp
    importState.nextGridIndex = 0
    
    -- Build the set of known cooldownIDs from imported data
    -- ONLY count cdIDs that have actual POSITIONS (savedPositions and freeIcons)
    -- iconSettings is just visual config - doesn't indicate placement
    local knownCount = 0
    
    -- From savedPositions (group members and free icons with positions)
    if importedData.cdmGroups and importedData.cdmGroups.savedPositions then
        for cdID, _ in pairs(importedData.cdmGroups.savedPositions) do
            local id = NormalizeCdID(cdID)
            importState.knownCooldownIDs[id] = true
            knownCount = knownCount + 1
        end
    end
    
    -- From freeIcons
    if importedData.cdmGroups and importedData.cdmGroups.freeIcons then
        for cdID, _ in pairs(importedData.cdmGroups.freeIcons) do
            local id = NormalizeCdID(cdID)
            if not importState.knownCooldownIDs[id] then
                importState.knownCooldownIDs[id] = true
                knownCount = knownCount + 1
            end
        end
    end
    
    -- NOTE: We intentionally do NOT include iconSettings in "known" list
    -- iconSettings is just visual configuration, not positioning
    -- A cdID with iconSettings but no savedPosition should still be placed as free icon
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- BRILLIANT FIX: Find unknown icons NOW and add them as free icons
    -- This way they'll be part of the import and load correctly after reload!
    -- We also MOVE them immediately so user sees the change right away.
    -- ═══════════════════════════════════════════════════════════════════════
    local unknownCount = 0
    local gridIndex = 0
    local iconsToMove = {}  -- Collect first, then move (avoid modifying while iterating)
    
    -- Find cdIDs in runtime that are NOT in import (alt-only icons)
    if ns.CDMGroups and ns.CDMGroups.savedPositions then
        for cdID, _ in pairs(ns.CDMGroups.savedPositions) do
            local id = NormalizeCdID(cdID)
            if not importState.knownCooldownIDs[id] then
                table.insert(iconsToMove, id)
            end
        end
    end
    
    -- Also check runtime freeIcons (might have some not in savedPositions)
    if ns.CDMGroups and ns.CDMGroups.freeIcons then
        for cdID, _ in pairs(ns.CDMGroups.freeIcons) do
            local id = NormalizeCdID(cdID)
            if not importState.knownCooldownIDs[id] then
                -- Check if already in list
                local found = false
                for _, existing in ipairs(iconsToMove) do
                    if existing == id then found = true break end
                end
                if not found then
                    table.insert(iconsToMove, id)
                end
            end
        end
    end
    
    -- Now move each unknown icon to free position
    for _, cdID in ipairs(iconsToMove) do
        local x, y = GetGridPosition(gridIndex)
        gridIndex = gridIndex + 1
        
        -- ACTUALLY MOVE THE FRAME using TrackFreeIcon!
        -- This removes from current group and positions as free icon
        -- TrackFreeIcon calls SavePositionToSpec and SaveFreeIconToSpec
        -- which save to the Arc Manager profile (authoritative source)
        if ns.CDMGroups.TrackFreeIcon then
            ns.CDMGroups.TrackFreeIcon(cdID, x, y, 36)
        end
        
        -- Add to known list
        importState.knownCooldownIDs[cdID] = true
        knownCount = knownCount + 1
        unknownCount = unknownCount + 1
        
        local spellName = C_Spell.GetSpellName(cdID) or "Unknown"
        PrintMsg(string.format("Alt ability |cffff8800%s|r (ID:%s) → free icon at (%.0f, %.0f)", 
            spellName, tostring(cdID), x, y))
    end
    
    if unknownCount > 0 then
        PrintMsg(string.format("Added %d alt-only abilities as free icons", unknownCount))
    end
    
    -- Update grid index for any future unknowns
    importState.nextGridIndex = gridIndex
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- SYNC GROUP LAYOUTS FROM DB
    -- Import wrote new layout settings to specData, but runtime groups still
    -- have old layouts. Sync them so placeholders get correct sizes.
    -- Also create any new groups that were imported.
    -- ═══════════════════════════════════════════════════════════════════════
    local specKey = ns.CDMGroups and ns.CDMGroups.currentSpec
    if specKey and ns.db and ns.db.char and ns.db.char.cdmGroups and ns.db.char.cdmGroups.specData then
        local specData = ns.db.char.cdmGroups.specData[specKey]
        if specData and specData.groups and ns.CDMGroups.groups then
            for groupName, dbGroupData in pairs(specData.groups) do
                local runtimeGroup = ns.CDMGroups.groups[groupName]
                
                -- Create group if it doesn't exist
                if not runtimeGroup and ns.CDMGroups.CreateGroup and dbGroupData.enabled ~= false then
                    ns.CDMGroups.CreateGroup(groupName)
                    runtimeGroup = ns.CDMGroups.groups[groupName]
                    PrintMsg(string.format("Created new group: |cff00ff00%s|r", groupName))
                end
                
                if runtimeGroup and dbGroupData.layout then
                    -- Deep copy layout from DB to runtime
                    runtimeGroup.layout = runtimeGroup.layout or {}
                    for k, v in pairs(dbGroupData.layout) do
                        runtimeGroup.layout[k] = v
                    end
                    -- Also update position
                    if dbGroupData.position then
                        runtimeGroup.position = runtimeGroup.position or {}
                        runtimeGroup.position.x = dbGroupData.position.x
                        runtimeGroup.position.y = dbGroupData.position.y
                        -- Reposition the container
                        if runtimeGroup.container then
                            runtimeGroup.container:ClearAllPoints()
                            runtimeGroup.container:SetPoint("CENTER", UIParent, "CENTER", 
                                runtimeGroup.position.x, runtimeGroup.position.y)
                        end
                    end
                end
            end
            -- Refresh all group layouts to apply the new settings
            if ns.CDMGroups.RefreshAllGroupLayouts then
                ns.CDMGroups.RefreshAllGroupLayouts()
            end
            -- Refresh placeholders to get correct sizes
            if ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.RefreshAllPlaceholders then
                ns.CDMGroups.Placeholders.RefreshAllPlaceholders()
            end
        end
    end
    
    -- SAVE STATE TO DB (survives reload!)
    SaveState()
    
    PrintMsg("Import mode activated - " .. knownCount .. " known cooldowns")
    PrintMsg("Unknown abilities will be placed as free icons above center")
    PrintMsg("Mode persists across /reload for 5 minutes")
    PrintMsg("Type |cff00ff00/arcimport status|r to check, |cff00ff00/arcimport end|r to finish")
    
    -- Set up auto-expiration timer (use time() for consistency)
    C_Timer.After(IMPORT_MODE_DURATION + 1, function()
        if importState.active and time() >= importState.expirationTime then
            ImportRestore.Deactivate("timeout")
        end
    end)
    
    return true
end

-- Deactivate import restoration mode
function ImportRestore.Deactivate(reason)
    if not importState.active then return end
    
    importState.active = false
    
    local unknownCount = 0
    for _ in pairs(importState.unknownIconsPlaced) do
        unknownCount = unknownCount + 1
    end
    
    -- Silent deactivation for automatic cleanup after reload
    -- (profile already has the data, no need to spam chat)
    if reason ~= "profile_has_data" then
        local msg = "Import mode ended"
        if reason then
            msg = msg .. " (" .. reason .. ")"
        end
        if unknownCount > 0 then
            msg = msg .. " - " .. unknownCount .. " new abilities placed as free icons"
        end
        
        PrintMsg(msg)
    end
    
    -- Clear saved state
    ClearSavedState()
    
    -- Clear local state
    importState.knownCooldownIDs = {}
    importState.unknownIconsPlaced = {}
end

-- Called when a profile is successfully loaded
-- Clears import state silently since the profile has all the data
function ImportRestore.OnProfileLoaded()
    if not importState.active then return end
    
    importState.active = false
    ClearSavedState()
    importState.knownCooldownIDs = {}
    importState.unknownIconsPlaced = {}
    
    -- No message - silent deactivation
end

-- Check if import mode is active
function ImportRestore.IsActive()
    if not importState.active then return false end
    
    -- Check expiration using Unix timestamp (time() persists across reload)
    if importState.expirationTime and time() >= importState.expirationTime then
        ImportRestore.Deactivate("timeout")
        return false
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ICON PLACEMENT DECISIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if a cooldownID was in the imported data
function ImportRestore.IsKnownCooldown(cdID)
    if not ImportRestore.IsActive() then
        return true  -- Not in import mode, treat all as "known" (normal behavior)
    end
    
    local id = NormalizeCdID(cdID)
    return importState.knownCooldownIDs[id] == true
end

-- Handle an unknown cooldown that arrived during import mode
-- Returns: placement data {x, y, iconSize} for free icon placement, or nil
function ImportRestore.PlaceUnknownIcon(cdID)
    if not ImportRestore.IsActive() then
        return nil  -- Not in import mode
    end
    
    local id = NormalizeCdID(cdID)
    
    -- Already placed?
    if importState.unknownIconsPlaced[id] then
        return importState.unknownIconsPlaced[id]
    end
    
    -- Calculate position
    local x, y = GetGridPosition(importState.nextGridIndex)
    importState.nextGridIndex = importState.nextGridIndex + 1
    
    -- Store placement
    local placement = {
        x = x,
        y = y,
        iconSize = 36,
    }
    importState.unknownIconsPlaced[id] = placement
    
    -- Save updated state
    SaveState()
    
    local spellName = C_Spell.GetSpellName(id) or "Unknown"
    PrintMsg(string.format("Unknown ability |cffff8800%s|r (ID:%s) → free icon at (%.0f, %.0f)", 
        spellName, tostring(id), x, y))
    
    return placement
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INTEGRATION HOOK
-- Called by main CDMGroups when deciding where to place an icon
-- Returns: nil (use normal logic) or {type="free", x, y, iconSize} for override
-- ═══════════════════════════════════════════════════════════════════════════

-- Main hook function - call this when an icon arrives without a saved position
-- Returns: nil to use default behavior, or position data to use
function ImportRestore.GetPlacementOverride(cdID, hasSavedPosition)
    local id = NormalizeCdID(cdID)
    
    if not ImportRestore.IsActive() then
        return nil  -- Normal behavior
    end
    
    -- If this cdID has a saved position, let normal logic handle it
    if hasSavedPosition then
        return nil
    end
    
    -- If this cdID is known (was in import data), let normal logic handle it
    if importState.knownCooldownIDs[id] then
        return nil
    end
    
    -- Unknown icon during import mode - place as free icon!
    local spellName = C_Spell.GetSpellName(id) or "Unknown"
    PrintMsg(string.format("Unknown ability |cffff8800%s|r (ID:%s) → placing as free icon", spellName, tostring(id)))
    
    local placement = ImportRestore.PlaceUnknownIcon(cdID)
    if placement then
        return {
            type = "free",
            x = placement.x,
            y = placement.y,
            iconSize = placement.iconSize,
        }
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATUS & DEBUG
-- ═══════════════════════════════════════════════════════════════════════════

function ImportRestore.GetStatus()
    local knownCount = 0
    for _ in pairs(importState.knownCooldownIDs) do
        knownCount = knownCount + 1
    end
    
    local unknownCount = 0
    for _ in pairs(importState.unknownIconsPlaced) do
        unknownCount = unknownCount + 1
    end
    
    return {
        active = importState.active,
        knownCooldowns = knownCount,
        unknownPlaced = unknownCount,
        nextGridIndex = importState.nextGridIndex,
        timeRemaining = importState.active and importState.expirationTime and 
            math.max(0, importState.expirationTime - GetTime()) or 0,
    }
end

function ImportRestore.PrintStatus()
    local status = ImportRestore.GetStatus()
    if status.active then
        PrintMsg(string.format("Import mode |cff00ff00ACTIVE|r - %d known, %d unknown placed, %.0fs remaining",
            status.knownCooldowns, status.unknownPlaced, status.timeRemaining))
        
        -- List unknown icons placed
        if status.unknownPlaced > 0 then
            PrintMsg("Unknown icons placed as free:")
            local count = 0
            for cdID, pos in pairs(importState.unknownIconsPlaced) do
                count = count + 1
                if count <= 10 then
                    local spellName = C_Spell.GetSpellName(cdID) or "Unknown"
                    PrintMsg(string.format("  - %s (ID: %s) at (%.0f, %.0f)", spellName, tostring(cdID), pos.x, pos.y))
                end
            end
            if count > 10 then
                PrintMsg("  ... and " .. (count - 10) .. " more")
            end
        else
            PrintMsg("No unknown abilities encountered yet")
        end
    else
        PrintMsg("Import mode |cffff0000inactive|r")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SLASH COMMAND
-- ═══════════════════════════════════════════════════════════════════════════

SLASH_ARCUIIMPORTSTATUS1 = "/arcimport"
SlashCmdList["ARCUIIMPORTSTATUS"] = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "status" or msg == "" then
        ImportRestore.PrintStatus()
    elseif msg == "end" or msg == "stop" or msg == "finish" then
        ImportRestore.Deactivate("manual")
    elseif msg == "debug" then
        -- Toggle debug mode
        ns.CDMGroups = ns.CDMGroups or {}
        ns.CDMGroups.debugEnabled = not ns.CDMGroups.debugEnabled
        PrintMsg("Debug mode: " .. (ns.CDMGroups.debugEnabled and "ON" or "OFF"))
    else
        print("|cff00ccffArcUI Import|r Usage:")
        print("  /arcimport - Show import mode status")
        print("  /arcimport status - Show import mode status")
        print("  /arcimport end - End import mode early")
        print("  /arcimport debug - Toggle debug messages")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION - Load saved state SYNCHRONOUSLY and EARLY
-- Must happen BEFORE CDMGroups does initial restoration!
-- ═══════════════════════════════════════════════════════════════════════════

-- Try to load immediately when this file loads (if DB is ready)
local function TryImmediateLoad()
    if ns.db and ns.db.char then
        if LoadState() then
            DebugPrint("Import state restored immediately (DB was ready)")
            return true
        end
    end
    return false
end

-- Called by CDMGroups BEFORE it does initial restoration
-- This is the critical hook point
function ImportRestore.EnsureLoaded()
    if importState.active then
        return true  -- Already loaded
    end
    
    local loaded = LoadState()
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL FIX: If we just loaded import state but the profile already has
    -- savedPositions, it means the import was ALREADY SUCCESSFUL before the reload.
    -- Deactivate ImportRestore immediately - we don't need it anymore.
    -- ═══════════════════════════════════════════════════════════════════════════
    if loaded and importState.active then
        -- Check if active profile already has positions (import already wrote to it)
        local specData = nil
        if ns.db and ns.db.char and ns.db.char.cdmGroups then
            local specIndex = GetSpecialization() or 1
            local cdmDb = ns.db.char.cdmGroups
            if cdmDb.specData and cdmDb.specData[specIndex] then
                specData = cdmDb.specData[specIndex]
            end
        end
        
        if specData and specData.layoutProfiles then
            local activeProfileName = specData.activeProfile or "Default"
            local profile = specData.layoutProfiles[activeProfileName]
            
            if profile and profile.savedPositions then
                local posCount = 0
                for _ in pairs(profile.savedPositions) do
                    posCount = posCount + 1
                end
                
                if posCount > 0 then
                    -- Profile already has data! Import was successful before reload.
                    DebugPrint("Profile already has " .. posCount .. " positions - import was already successful")
                    ImportRestore.Deactivate("profile_has_data")
                    return false
                end
            end
        end
    end
    
    return loaded
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        -- Try to load as soon as our addon loads
        -- This might be too early if DB isn't ready yet
        C_Timer.After(0, function()
            TryImmediateLoad()
        end)
    elseif event == "PLAYER_LOGIN" then
        -- Backup: ensure loaded by login (no delay!)
        if not importState.active then
            LoadState()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- END OF MODULE
-- ═══════════════════════════════════════════════════════════════════════════