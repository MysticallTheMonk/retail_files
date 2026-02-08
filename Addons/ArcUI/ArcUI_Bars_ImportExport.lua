-- ===================================================================
-- ArcUI_Bars_ImportExport.lua
-- Import/Export functionality for ArcUI bar configurations
-- Supports all bar settings including alternateCooldownIDs for cross-spec
-- Now supports cooldown bars (charge and duration types)
-- ===================================================================

local ADDON, ns = ...
ns.BarsImportExport = ns.BarsImportExport or {}

local LibDeflate = LibStub("LibDeflate")
local AceSerializer = LibStub("AceSerializer-3.0")

-- Constants
local EXPORT_VERSION = 3  -- Bumped for resource bar support
local EXPORT_PREFIX = "ARCUI_BARS"

-- Module state
local selectedBarsForExport = {}
local selectedCooldownBarsForExport = {}  -- keyed by "spellID_barType"
local selectedResourceBarsForExport = {}  -- keyed by slot number
local importPreviewData = nil
local lastExportString = ""
local lastImportString = ""
local importMode = "add"  -- "add" or "replace"

-- ===================================================================
-- UTILITY FUNCTIONS
-- ===================================================================

local function DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[DeepCopy(k)] = DeepCopy(v)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- ===================================================================
-- ExtractAuraBarConfig: Reads an aura bar config by explicitly
-- accessing every field by name, NOT via pairs(). This is critical
-- because AceDB proxy tables only expose non-default values through
-- pairs(), silently dropping fields that match defaults (like
-- cooldownID=0 or alternateCooldownIDs={}).
--
-- By reading each field through bar.tracking.fieldName, we go through
-- AceDB's __index which ALWAYS returns the value (from sv or defaults).
-- ===================================================================
local function ExtractAuraBarConfig(bar)
    if not bar then return nil end
    local t = bar.tracking or {}
    local d = bar.display or {}
    local b = bar.behavior or {}
    
    local out = {}
    
    -- TRACKING: read every field by name through __index
    out.tracking = {
        enabled         = t.enabled,
        trackType       = t.trackType,
        spellID         = t.spellID,
        buffName        = t.buffName,
        iconTextureID   = t.iconTextureID,
        cooldownID      = t.cooldownID,
        slotNumber      = t.slotNumber,
        maxStacks       = t.maxStacks,
        auraInstanceID  = t.auraInstanceID,
        useBaseSpell    = t.useBaseSpell,
        customEnabled   = t.customEnabled,
        customSpellID   = t.customSpellID,
        customDuration  = t.customDuration,
        customStacksPerCast = t.customStacksPerCast,
        customMaxStacks = t.customMaxStacks,
        customRefreshMode = t.customRefreshMode,
        sourceType      = t.sourceType,
        useDurationBar  = t.useDurationBar,
        dynamicMaxDuration = t.dynamicMaxDuration,
        maxDuration     = t.maxDuration,
        customDefinitionID = t.customDefinitionID,
        trackedSpellID  = t.trackedSpellID,
        displaySpellID  = t.displaySpellID,
    }
    -- Explicitly copy alternateCooldownIDs array element-by-element
    out.tracking.alternateCooldownIDs = {}
    if t.alternateCooldownIDs then
        for i = 1, #t.alternateCooldownIDs do
            out.tracking.alternateCooldownIDs[i] = t.alternateCooldownIDs[i]
        end
    end
    
    -- DISPLAY: DeepCopy is fine here since display is a plain data subtable
    -- (no cooldownID-like fields that need special handling)
    out.display = DeepCopy(d)
    
    -- BEHAVIOR
    out.behavior = DeepCopy(b)
    
    -- THRESHOLDS, STACK COLORS, COLOR RANGES, EVENTS
    out.thresholds = bar.thresholds and DeepCopy(bar.thresholds) or {}
    out.stackColors = bar.stackColors and DeepCopy(bar.stackColors) or {}
    out.colorRanges = bar.colorRanges and DeepCopy(bar.colorRanges) or {}
    out.events = bar.events and DeepCopy(bar.events) or {}
    
    return out
end

local function GetEnabledBars()
    local db = ns.API.GetDB and ns.API.GetDB()
    if not db or not db.bars then return {} end
    
    local enabled = {}
    for i = 1, 500 do
        local bar = db.bars[i]
        if bar and bar.tracking and bar.tracking.enabled then
            table.insert(enabled, {
                slot = i,
                name = bar.tracking.buffName or "Unknown",
                spellID = bar.tracking.spellID or 0,
                cooldownID = bar.tracking.cooldownID or 0,
                trackType = bar.tracking.trackType or "buff",
                alternateCooldownIDs = bar.tracking.alternateCooldownIDs or {},
            })
        end
    end
    return enabled
end

local function GetEnabledCooldownBars()
    if not ns.db or not ns.db.char or not ns.db.char.cooldownBarConfigs then 
        return {} 
    end
    
    local enabled = {}
    for spellID, configs in pairs(ns.db.char.cooldownBarConfigs) do
        for barType, cfg in pairs(configs) do
            if cfg and cfg.tracking and cfg.tracking.enabled then
                -- Get spell name
                local spellName = C_Spell.GetSpellName(spellID) or "Unknown"
                
                table.insert(enabled, {
                    spellID = spellID,
                    barType = barType,
                    key = spellID .. "_" .. barType,
                    name = spellName,
                    displayType = barType == "charge" and "Charge Bar" or "Duration Bar",
                })
            end
        end
    end
    
    -- Sort by name for consistent display
    table.sort(enabled, function(a, b) return a.name < b.name end)
    
    return enabled
end

local function GetEnabledResourceBars()
    local db = ns.API.GetDB and ns.API.GetDB()
    if not db or not db.resourceBars then return {} end
    
    local enabled = {}
    for i = 1, 500 do
        local bar = db.resourceBars[i]
        if bar and bar.tracking and bar.tracking.enabled then
            -- Determine resource name
            local resourceName = bar.tracking.powerName or ""
            if resourceName == "" then
                if bar.tracking.resourceCategory == "secondary" and bar.tracking.secondaryType then
                    resourceName = bar.tracking.secondaryType
                elseif bar.tracking.powerType then
                    local powerInfo = PowerBarColor[bar.tracking.powerType]
                    resourceName = powerInfo and powerInfo.name or ("Power " .. bar.tracking.powerType)
                else
                    resourceName = "Unknown Resource"
                end
            end
            
            table.insert(enabled, {
                slot = i,
                name = resourceName,
                resourceCategory = bar.tracking.resourceCategory or "primary",
                powerType = bar.tracking.powerType,
                secondaryType = bar.tracking.secondaryType,
            })
        end
    end
    return enabled
end

local function FindFirstEmptySlot()
    local db = ns.API.GetDB and ns.API.GetDB()
    if not db or not db.bars then return nil end
    
    for i = 1, 500 do
        local bar = db.bars[i]
        if not bar or not bar.tracking or not bar.tracking.enabled then
            return i
        end
    end
    return nil
end

local function CountEmptySlots()
    local db = ns.API.GetDB and ns.API.GetDB()
    if not db or not db.bars then return 0 end
    
    local count = 0
    for i = 1, 500 do
        local bar = db.bars[i]
        if not bar or not bar.tracking or not bar.tracking.enabled then
            count = count + 1
        end
    end
    return count
end

local function FindFirstEmptyResourceSlot()
    local db = ns.API.GetDB and ns.API.GetDB()
    if not db then return nil end
    if not db.resourceBars then db.resourceBars = {} end
    
    for i = 1, 500 do
        local bar = db.resourceBars[i]
        if not bar or not bar.tracking or not bar.tracking.enabled then
            return i
        end
    end
    return nil
end

local function CountEmptyResourceSlots()
    local db = ns.API.GetDB and ns.API.GetDB()
    if not db then return 0 end
    if not db.resourceBars then return 500 end
    
    local count = 0
    for i = 1, 500 do
        local bar = db.resourceBars[i]
        if not bar or not bar.tracking or not bar.tracking.enabled then
            count = count + 1
        end
    end
    return count
end

-- ===================================================================
-- EXPORT FUNCTIONS
-- ===================================================================

local function ExportSelectedBars()
    local db = ns.API.GetDB and ns.API.GetDB()
    if not db then 
        return nil, "Database not available"
    end
    
    local barsToExport = {}
    local cooldownBarsToExport = {}
    local resourceBarsToExport = {}
    local auraExportCount = 0
    local cooldownExportCount = 0
    local resourceExportCount = 0
    
    -- Export selected aura bars
    if db.bars then
        for slot, isSelected in pairs(selectedBarsForExport) do
            if isSelected then
                local bar = db.bars[slot]
                if bar and bar.tracking and bar.tracking.enabled then
                    -- Extract config by reading every field by name (not pairs)
                    -- This ensures AceDB proxy values are captured correctly
                    local barCopy = ExtractAuraBarConfig(bar)
                    barCopy._category = "aura"
                    table.insert(barsToExport, barCopy)
                    auraExportCount = auraExportCount + 1
                end
            end
        end
    end
    
    -- Export selected cooldown bars
    if ns.db and ns.db.char and ns.db.char.cooldownBarConfigs then
        for key, isSelected in pairs(selectedCooldownBarsForExport) do
            if isSelected then
                -- Parse key back to spellID and barType
                local spellID, barType = key:match("^(%d+)_(.+)$")
                spellID = tonumber(spellID)
                
                if spellID and barType then
                    local configs = ns.db.char.cooldownBarConfigs[spellID]
                    if configs and configs[barType] then
                        local barCopy = DeepCopy(configs[barType])
                        barCopy._category = "cooldown"
                        barCopy._spellID = spellID
                        barCopy._barType = barType
                        table.insert(cooldownBarsToExport, barCopy)
                        cooldownExportCount = cooldownExportCount + 1
                    end
                end
            end
        end
    end
    
    -- Export selected resource bars
    if db.resourceBars then
        for slot, isSelected in pairs(selectedResourceBarsForExport) do
            if isSelected then
                local bar = db.resourceBars[slot]
                if bar and bar.tracking and bar.tracking.enabled then
                    local barCopy = DeepCopy(bar)
                    barCopy._category = "resource"
                    table.insert(resourceBarsToExport, barCopy)
                    resourceExportCount = resourceExportCount + 1
                end
            end
        end
    end
    
    local totalCount = auraExportCount + cooldownExportCount + resourceExportCount
    if totalCount == 0 then
        return nil, "No bars selected for export"
    end
    
    -- Build export data structure
    local exportData = {
        version = EXPORT_VERSION,
        prefix = EXPORT_PREFIX,
        timestamp = time(),
        exportedBy = UnitName("player") or "Unknown",
        realm = GetRealmName() or "Unknown",
        barCount = totalCount,
        auraBarCount = auraExportCount,
        cooldownBarCount = cooldownExportCount,
        resourceBarCount = resourceExportCount,
        bars = barsToExport,              -- Aura bars (for backward compatibility)
        cooldownBars = cooldownBarsToExport,  -- Cooldown bars
        resourceBars = resourceBarsToExport,  -- Resource bars (new)
    }
    
    -- Serialize → Compress → Encode
    local serialized = AceSerializer:Serialize(exportData)
    if not serialized then
        return nil, "Serialization failed"
    end
    
    local compressed = LibDeflate:CompressDeflate(serialized)
    if not compressed then
        return nil, "Compression failed"
    end
    
    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then
        return nil, "Encoding failed"
    end
    
    lastExportString = encoded
    return encoded, nil
end

-- ===================================================================
-- IMPORT FUNCTIONS
-- ===================================================================

local function ParseImportString(importString)
    if not importString or importString == "" then
        return nil, "Empty import string"
    end
    
    -- Clean up the string
    importString = importString:gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Decode → Decompress → Deserialize
    local decoded = LibDeflate:DecodeForPrint(importString)
    if not decoded then
        return nil, "Invalid import string (decode failed)"
    end
    
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return nil, "Invalid import string (decompress failed)"
    end
    
    local success, data = AceSerializer:Deserialize(decompressed)
    if not success or not data then
        return nil, "Invalid import string (deserialize failed)"
    end
    
    -- Validate structure
    if data.prefix ~= EXPORT_PREFIX then
        return nil, "Invalid import string (wrong format)"
    end
    
    -- Check for at least some bars
    local hasAuraBars = data.bars and #data.bars > 0
    local hasCooldownBars = data.cooldownBars and #data.cooldownBars > 0
    local hasResourceBars = data.resourceBars and #data.resourceBars > 0
    
    if not hasAuraBars and not hasCooldownBars and not hasResourceBars then
        return nil, "No bars found in import data"
    end
    
    return data, nil
end

local function GenerateImportPreview(data)
    if not data then return "No data" end
    
    local lines = {}
    
    -- Header with counts
    local auraCount = data.bars and #data.bars or 0
    local cooldownCount = data.cooldownBars and #data.cooldownBars or 0
    local resourceCount = data.resourceBars and #data.resourceBars or 0
    local totalCount = auraCount + cooldownCount + resourceCount
    
    table.insert(lines, string.format(
        "|cff00FF00Found %d bar(s)|r from %s @ %s",
        totalCount,
        data.exportedBy or "Unknown",
        data.realm or "Unknown"
    ))
    
    -- Aura bars
    if auraCount > 0 then
        local barNames = {}
        for i, bar in ipairs(data.bars) do
            local name = bar.tracking and bar.tracking.buffName or "Unknown"
            local cdID = bar.tracking and bar.tracking.cooldownID or 0
            local alts = bar.tracking and bar.tracking.alternateCooldownIDs
            local altCount = alts and #alts or 0
            
            if cdID > 0 then
                name = name .. string.format(" |cffAADDFF[cd:%d]|r", cdID)
            end
            if altCount > 0 then
                local altIDs = {}
                for j = 1, altCount do
                    altIDs[j] = tostring(alts[j])
                end
                name = name .. string.format(" |cff00FF00(+%d alt: %s)|r", altCount, table.concat(altIDs, ","))
            end
            table.insert(barNames, name)
        end
        table.insert(lines, "|cffFFFF00Aura Bars:|r " .. table.concat(barNames, ", "))
    end
    
    -- Cooldown bars
    if cooldownCount > 0 then
        local barNames = {}
        for i, bar in ipairs(data.cooldownBars) do
            local spellID = bar._spellID or (bar.tracking and bar.tracking.spellID) or 0
            local barType = bar._barType or (bar.tracking and bar.tracking.barType) or "cooldown"
            local name = C_Spell.GetSpellName(spellID) or "Unknown"
            local typeLabel = barType == "charge" and "|cff00FFFFCharge|r" or "|cffFF8800Duration|r"
            table.insert(barNames, name .. " (" .. typeLabel .. ")")
        end
        table.insert(lines, "|cff00FFFFCooldown Bars:|r " .. table.concat(barNames, ", "))
    end
    
    -- Resource bars
    if resourceCount > 0 then
        local barNames = {}
        for i, bar in ipairs(data.resourceBars) do
            local name = bar.tracking and bar.tracking.powerName or ""
            if name == "" then
                if bar.tracking and bar.tracking.resourceCategory == "secondary" and bar.tracking.secondaryType then
                    name = bar.tracking.secondaryType
                else
                    name = "Resource"
                end
            end
            local category = bar.tracking and bar.tracking.resourceCategory or "primary"
            local categoryLabel = category == "secondary" and "|cffFF00FFSecondary|r" or "|cff00FF88Primary|r"
            table.insert(barNames, name .. " (" .. categoryLabel .. ")")
        end
        table.insert(lines, "|cff00FF88Resource Bars:|r " .. table.concat(barNames, ", "))
    end
    
    return table.concat(lines, "\n")
end

-- ===================================================================
-- WriteAuraBarToSlot: Writes an imported aura bar config to a DB slot
-- by explicitly setting each tracking field through the AceDB path.
-- This ensures __newindex fires for every critical field, preventing
-- AceDB proxy quirks from silently dropping nested values.
-- ===================================================================
local function WriteAuraBarToSlot(db, slot, importedBar)
    -- Save alternateCooldownIDs BEFORE any assignment, because
    -- db.bars[slot] = importedBar stores a reference, making
    -- importedBar.tracking and db.bars[slot].tracking the SAME object.
    -- If we clear target.alternateCooldownIDs first, we also destroy
    -- the source data we're trying to copy from.
    local savedAlts = {}
    if importedBar.tracking and importedBar.tracking.alternateCooldownIDs then
        for i = 1, #importedBar.tracking.alternateCooldownIDs do
            savedAlts[i] = importedBar.tracking.alternateCooldownIDs[i]
        end
    end
    local savedCooldownID = importedBar.tracking and importedBar.tracking.cooldownID or 0
    local savedSpellID = importedBar.tracking and importedBar.tracking.spellID or 0
    
    -- Assign the full table to create the slot
    importedBar._category = nil  -- Remove internal marker
    db.bars[slot] = importedBar
    
    -- Now explicitly write critical tracking fields through the DB path
    local target = db.bars[slot].tracking
    if target then
        target.cooldownID = savedCooldownID
        target.spellID = savedSpellID
        
        -- Write the saved alts array
        target.alternateCooldownIDs = savedAlts
    end
    
    -- Debug output for verification
    local cdID = db.bars[slot].tracking.cooldownID or 0
    local altCount = db.bars[slot].tracking.alternateCooldownIDs and #db.bars[slot].tracking.alternateCooldownIDs or 0
    local name = db.bars[slot].tracking.buffName or "?"
    
    local altList = ""
    if altCount > 0 then
        local ids = {}
        for i = 1, altCount do
            ids[i] = tostring(db.bars[slot].tracking.alternateCooldownIDs[i])
        end
        altList = " alts=[" .. table.concat(ids, ",") .. "]"
    end
    print(string.format("|cff00ccffArc UI Import|r: Slot %d '%s' → cdID=%d%s", slot, name, cdID, altList))
end

local function ImportBars(data, mode)
    local db = ns.API.GetDB and ns.API.GetDB()
    if not db then 
        return false, "Database not available"
    end
    
    local imported = 0
    local skipped = 0
    local messages = {}
    
    -- ═══════════════════════════════════════════════════════════════
    -- IMPORT AURA BARS
    -- ═══════════════════════════════════════════════════════════════
    if data.bars and #data.bars > 0 then
        -- Ensure bars table exists
        if not db.bars then
            db.bars = {}
        end
        
        if mode == "replace" then
            -- Reset all aura bars to disabled first
            for i = 1, 500 do
                if db.bars[i] then
                    db.bars[i].tracking = db.bars[i].tracking or {}
                    db.bars[i].tracking.enabled = false
                end
            end
            
            -- Import from slot 1
            for i, importedBar in ipairs(data.bars) do
                if i <= 500 then
                    WriteAuraBarToSlot(db, i, importedBar)
                    imported = imported + 1
                else
                    table.insert(messages, "Slot limit reached, skipped: " .. (importedBar.tracking and importedBar.tracking.buffName or "Unknown"))
                    skipped = skipped + 1
                end
            end
        else
            -- Add mode: find empty slots
            for _, importedBar in ipairs(data.bars) do
                local emptySlot = FindFirstEmptySlot()
                if emptySlot then
                    WriteAuraBarToSlot(db, emptySlot, importedBar)
                    imported = imported + 1
                else
                    local name = importedBar.tracking and importedBar.tracking.buffName or "Unknown"
                    table.insert(messages, "No empty slots, skipped: " .. name)
                    skipped = skipped + 1
                end
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- IMPORT COOLDOWN BARS
    -- ═══════════════════════════════════════════════════════════════
    if data.cooldownBars and #data.cooldownBars > 0 then
        -- Ensure cooldown bar structure exists
        if not ns.db then
            return false, "Cooldown database not available"
        end
        ns.db.char = ns.db.char or {}
        ns.db.char.cooldownBarConfigs = ns.db.char.cooldownBarConfigs or {}
        
        -- Ensure active lists exist
        ns.db.char.activeCooldowns = ns.db.char.activeCooldowns or {}
        ns.db.char.activeCharges = ns.db.char.activeCharges or {}
        
        if mode == "replace" then
            -- Hide and remove all existing cooldown bars first
            if ns.CooldownBars then
                -- Collect spellIDs first (can't modify while iterating)
                local cooldownsToRemove = {}
                local chargesToRemove = {}
                
                if ns.CooldownBars.activeCooldowns then
                    for spellID, _ in pairs(ns.CooldownBars.activeCooldowns) do
                        table.insert(cooldownsToRemove, spellID)
                    end
                end
                if ns.CooldownBars.activeCharges then
                    for spellID, _ in pairs(ns.CooldownBars.activeCharges) do
                        table.insert(chargesToRemove, spellID)
                    end
                end
                
                -- Now remove them
                for _, spellID in ipairs(cooldownsToRemove) do
                    ns.CooldownBars.RemoveCooldownBar(spellID)
                end
                for _, spellID in ipairs(chargesToRemove) do
                    ns.CooldownBars.RemoveChargeBar(spellID)
                end
            end
            
            -- Clear all existing cooldown bar configs and active lists
            ns.db.char.cooldownBarConfigs = {}
            ns.db.char.activeCooldowns = {}
            ns.db.char.activeCharges = {}
            
            -- Also clear runtime state
            if ns.CooldownBars then
                ns.CooldownBars.activeCooldowns = {}
                ns.CooldownBars.activeCharges = {}
            end
        end
        
        -- Track which bars to create after config is saved
        local barsToCreate = {}
        
        for _, importedBar in ipairs(data.cooldownBars) do
            local spellID = importedBar._spellID or (importedBar.tracking and importedBar.tracking.spellID) or 0
            local barType = importedBar._barType or (importedBar.tracking and importedBar.tracking.barType) or "cooldown"
            
            if spellID > 0 then
                -- Check if bar already exists in add mode
                local alreadyExists = false
                if mode == "add" then
                    if barType == "charge" then
                        alreadyExists = ns.CooldownBars and ns.CooldownBars.activeCharges and ns.CooldownBars.activeCharges[spellID]
                    else
                        alreadyExists = ns.CooldownBars and ns.CooldownBars.activeCooldowns and ns.CooldownBars.activeCooldowns[spellID]
                    end
                end
                
                if alreadyExists then
                    local name = C_Spell.GetSpellName(spellID) or "Unknown"
                    table.insert(messages, "Cooldown bar already exists, skipped: " .. name)
                    skipped = skipped + 1
                else
                    -- Save the config first
                    ns.db.char.cooldownBarConfigs[spellID] = ns.db.char.cooldownBarConfigs[spellID] or {}
                    
                    local barCopy = DeepCopy(importedBar)
                    -- Remove internal markers
                    barCopy._category = nil
                    barCopy._spellID = nil
                    barCopy._barType = nil
                    
                    -- Ensure tracking has correct spellID and barType
                    barCopy.tracking = barCopy.tracking or {}
                    barCopy.tracking.spellID = spellID
                    barCopy.tracking.barType = barType
                    barCopy.tracking.enabled = true
                    
                    ns.db.char.cooldownBarConfigs[spellID][barType] = barCopy
                    
                    -- Queue bar for creation
                    table.insert(barsToCreate, {spellID = spellID, barType = barType})
                    imported = imported + 1
                end
            else
                table.insert(messages, "Invalid cooldown bar (no spellID), skipped")
                skipped = skipped + 1
            end
        end
        
        -- Now create the actual bar frames
        if ns.CooldownBars and #barsToCreate > 0 then
            for _, barInfo in ipairs(barsToCreate) do
                if barInfo.barType == "charge" then
                    ns.CooldownBars.AddChargeBar(barInfo.spellID)
                else
                    ns.CooldownBars.AddCooldownBar(barInfo.spellID)
                end
            end
            
            -- Save the updated state
            ns.CooldownBars.SaveBarConfig()
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- IMPORT RESOURCE BARS
    -- ═══════════════════════════════════════════════════════════════
    if data.resourceBars and #data.resourceBars > 0 then
        -- Ensure resourceBars table exists
        if not db.resourceBars then
            db.resourceBars = {}
        end
        
        if mode == "replace" then
            -- Reset all resource bars to disabled first
            for i = 1, 500 do
                if db.resourceBars[i] then
                    db.resourceBars[i].tracking = db.resourceBars[i].tracking or {}
                    db.resourceBars[i].tracking.enabled = false
                end
            end
            
            -- Import from slot 1
            for i, importedBar in ipairs(data.resourceBars) do
                if i <= 500 then
                    local barCopy = DeepCopy(importedBar)
                    barCopy._category = nil  -- Remove internal marker
                    db.resourceBars[i] = barCopy
                    imported = imported + 1
                else
                    local name = importedBar.tracking and importedBar.tracking.powerName or "Unknown Resource"
                    table.insert(messages, "Resource slot limit reached, skipped: " .. name)
                    skipped = skipped + 1
                end
            end
        else
            -- Add mode: find empty slots
            for _, importedBar in ipairs(data.resourceBars) do
                local emptySlot = FindFirstEmptyResourceSlot()
                if emptySlot then
                    local barCopy = DeepCopy(importedBar)
                    barCopy._category = nil  -- Remove internal marker
                    db.resourceBars[emptySlot] = barCopy
                    imported = imported + 1
                else
                    local name = importedBar.tracking and importedBar.tracking.powerName or "Unknown Resource"
                    table.insert(messages, "No empty resource slots, skipped: " .. name)
                    skipped = skipped + 1
                end
            end
        end
    end
    
    -- Trigger validation for imported aura bars
    if ns.API.ValidateAllBarTracking then
        C_Timer.After(0.1, function()
            ns.API.ValidateAllBarTracking()
        end)
    end
    
    -- Refresh aura bar UI
    if ns.Display and ns.Display.RefreshAllBars then
        C_Timer.After(0.2, function()
            ns.Display.RefreshAllBars()
        end)
    end
    
    -- Refresh cooldown bars
    if ns.CooldownBars and ns.CooldownBars.RefreshAllBars then
        C_Timer.After(0.3, function()
            ns.CooldownBars.RefreshAllBars()
        end)
    end
    
    -- Refresh resource bars
    if ns.Resources and ns.Resources.RefreshAllBars then
        C_Timer.After(0.4, function()
            ns.Resources.RefreshAllBars()
        end)
    end
    
    local result = string.format("Imported %d bar(s)", imported)
    if skipped > 0 then
        result = result .. string.format(", skipped %d", skipped)
    end
    
    if #messages > 0 then
        result = result .. "\n" .. table.concat(messages, "\n")
    end
    
    return true, result
end

-- ===================================================================
-- OPTIONS TABLE
-- ===================================================================

function ns.BarsImportExport.GetOptionsTable()
    local enabledBars = GetEnabledBars()
    local enabledCooldownBars = GetEnabledCooldownBars()
    local enabledResourceBars = GetEnabledResourceBars()
    
    -- Initialize selection state for aura bars
    for _, bar in ipairs(enabledBars) do
        if selectedBarsForExport[bar.slot] == nil then
            selectedBarsForExport[bar.slot] = true  -- Default to selected
        end
    end
    
    -- Initialize selection state for cooldown bars
    for _, bar in ipairs(enabledCooldownBars) do
        if selectedCooldownBarsForExport[bar.key] == nil then
            selectedCooldownBarsForExport[bar.key] = true  -- Default to selected
        end
    end
    
    -- Initialize selection state for resource bars
    for _, bar in ipairs(enabledResourceBars) do
        if selectedResourceBarsForExport[bar.slot] == nil then
            selectedResourceBarsForExport[bar.slot] = true  -- Default to selected
        end
    end
    
    local options = {
        type = "group",
        name = "Import/Export",
        order = 4,
        args = {
            -- ═══════════════════════════════════════════════════════════════
            -- EXPORT SECTION
            -- ═══════════════════════════════════════════════════════════════
            exportHeader = {
                type = "header",
                name = "Export Bars",
                order = 1,
            },
            
            exportDesc = {
                type = "description",
                name = "Select bars to export. The export string includes all settings including alternate cooldownIDs for cross-spec support and resource bar configurations.",
                order = 2,
            },
            
            selectAllBtn = {
                type = "execute",
                name = "Select All",
                order = 3,
                width = 0.6,
                func = function()
                    for _, bar in ipairs(GetEnabledBars()) do
                        selectedBarsForExport[bar.slot] = true
                    end
                    for _, bar in ipairs(GetEnabledCooldownBars()) do
                        selectedCooldownBarsForExport[bar.key] = true
                    end
                    for _, bar in ipairs(GetEnabledResourceBars()) do
                        selectedResourceBarsForExport[bar.slot] = true
                    end
                end,
            },
            
            selectNoneBtn = {
                type = "execute",
                name = "Select None",
                order = 4,
                width = 0.6,
                func = function()
                    for k in pairs(selectedBarsForExport) do
                        selectedBarsForExport[k] = false
                    end
                    for k in pairs(selectedCooldownBarsForExport) do
                        selectedCooldownBarsForExport[k] = false
                    end
                    for k in pairs(selectedResourceBarsForExport) do
                        selectedResourceBarsForExport[k] = false
                    end
                end,
            },
            
            spacer1 = {
                type = "description",
                name = "",
                order = 5,
            },
            
            -- Aura bar selection checkboxes
            auraBarSelectionGroup = {
                type = "group",
                name = "Aura Bars",
                order = 6,
                inline = true,
                args = (function()
                    local args = {}
                    local bars = GetEnabledBars()
                    
                    if #bars == 0 then
                        args.noBars = {
                            type = "description",
                            name = "|cff888888No enabled aura bars.|r",
                            order = 1,
                        }
                    else
                        for i, bar in ipairs(bars) do
                            local cdText = ""
                            if bar.cooldownID and bar.cooldownID > 0 then
                                cdText = string.format(" |cffAADDFF[cd:%d]|r", bar.cooldownID)
                            end
                            local altText = ""
                            if bar.alternateCooldownIDs and #bar.alternateCooldownIDs > 0 then
                                local altIDs = {}
                                for _, altCdID in ipairs(bar.alternateCooldownIDs) do
                                    altIDs[#altIDs+1] = tostring(altCdID)
                                end
                                altText = string.format(" |cff00FF00(+%d alt: %s)|r", #bar.alternateCooldownIDs, table.concat(altIDs, ","))
                            end
                            
                            args["bar" .. bar.slot] = {
                                type = "toggle",
                                name = string.format("Bar %d: %s%s%s", bar.slot, bar.name, cdText, altText),
                                desc = string.format("Type: %s, Primary CooldownID: %d, Alternates: %d", bar.trackType, bar.cooldownID, bar.alternateCooldownIDs and #bar.alternateCooldownIDs or 0),
                                order = i,
                                width = "full",
                                get = function() return selectedBarsForExport[bar.slot] end,
                                set = function(_, val) selectedBarsForExport[bar.slot] = val end,
                            }
                        end
                    end
                    
                    return args
                end)(),
            },
            
            -- Cooldown bar selection checkboxes
            cooldownBarSelectionGroup = {
                type = "group",
                name = "Cooldown Bars",
                order = 7,
                inline = true,
                args = (function()
                    local args = {}
                    local bars = GetEnabledCooldownBars()
                    
                    if #bars == 0 then
                        args.noCooldownBars = {
                            type = "description",
                            name = "|cff888888No enabled cooldown bars.|r",
                            order = 1,
                        }
                    else
                        for i, bar in ipairs(bars) do
                            local typeColor = bar.barType == "charge" and "|cff00FFFF" or "|cffFF8800"
                            
                            args["cdbar_" .. bar.key] = {
                                type = "toggle",
                                name = string.format("%s%s|r: %s", typeColor, bar.displayType, bar.name),
                                desc = string.format("SpellID: %d, Type: %s", bar.spellID, bar.barType),
                                order = i,
                                width = "full",
                                get = function() return selectedCooldownBarsForExport[bar.key] end,
                                set = function(_, val) selectedCooldownBarsForExport[bar.key] = val end,
                            }
                        end
                    end
                    
                    return args
                end)(),
            },
            
            -- Resource bar selection checkboxes
            resourceBarSelectionGroup = {
                type = "group",
                name = "Resource Bars",
                order = 7.5,
                inline = true,
                args = (function()
                    local args = {}
                    local bars = GetEnabledResourceBars()
                    
                    if #bars == 0 then
                        args.noResourceBars = {
                            type = "description",
                            name = "|cff888888No enabled resource bars.|r",
                            order = 1,
                        }
                    else
                        for i, bar in ipairs(bars) do
                            local categoryColor = bar.resourceCategory == "secondary" and "|cffFF00FF" or "|cff00FF88"
                            local categoryLabel = bar.resourceCategory == "secondary" and "Secondary" or "Primary"
                            
                            args["resbar_" .. bar.slot] = {
                                type = "toggle",
                                name = string.format("%s%s|r: %s", categoryColor, categoryLabel, bar.name),
                                desc = string.format("Slot: %d, Type: %s", bar.slot, bar.secondaryType or "Power"),
                                order = i,
                                width = "full",
                                get = function() return selectedResourceBarsForExport[bar.slot] end,
                                set = function(_, val) selectedResourceBarsForExport[bar.slot] = val end,
                            }
                        end
                    end
                    
                    return args
                end)(),
            },
            
            exportBtn = {
                type = "execute",
                name = "Export Selected",
                order = 8,
                width = 1,
                func = function()
                    local result, err = ExportSelectedBars()
                    if err then
                        print("|cffFF0000[ArcUI]|r Export failed: " .. err)
                    else
                        print("|cff00FF00[ArcUI]|r Export successful! Copy the string from the box below.")
                    end
                end,
            },
            
            exportString = {
                type = "input",
                name = "Export String",
                order = 9,
                multiline = 6,
                width = "full",
                get = function() return lastExportString end,
                set = function() end,  -- Read-only
            },
            
            -- ═══════════════════════════════════════════════════════════════
            -- IMPORT SECTION
            -- ═══════════════════════════════════════════════════════════════
            importHeader = {
                type = "header",
                name = "Import Bars",
                order = 20,
            },
            
            importDesc = {
                type = "description",
                name = "Paste an export string below to import bar configurations. Supports aura bars, cooldown bars, and resource bars.",
                order = 21,
            },
            
            importString = {
                type = "input",
                name = "Paste Export String",
                order = 22,
                multiline = 6,
                width = "full",
                get = function() return lastImportString end,
                set = function(_, val)
                    lastImportString = val
                    -- Auto-parse for preview
                    local data, err = ParseImportString(val)
                    if data then
                        importPreviewData = data
                    else
                        importPreviewData = nil
                    end
                end,
            },
            
            previewBtn = {
                type = "execute",
                name = "Preview",
                order = 23,
                width = 0.6,
                func = function()
                    local data, err = ParseImportString(lastImportString)
                    if err then
                        print("|cffFF0000[ArcUI]|r " .. err)
                        importPreviewData = nil
                    else
                        importPreviewData = data
                        print("|cff00FF00[ArcUI]|r " .. GenerateImportPreview(data))
                    end
                end,
            },
            
            importPreview = {
                type = "description",
                name = function()
                    if importPreviewData then
                        return GenerateImportPreview(importPreviewData)
                    else
                        return "|cff888888Paste a string and click Preview to see contents.|r"
                    end
                end,
                order = 24,
                fontSize = "medium",
            },
            
            importModeSelect = {
                type = "select",
                name = "Import Mode",
                order = 25,
                width = 1.2,
                values = {
                    add = "Add to existing bars",
                    replace = "Replace all bars",
                },
                get = function() return importMode end,
                set = function(_, val) importMode = val end,
            },
            
            importModeDesc = {
                type = "description",
                name = function()
                    local emptyAuraSlots = CountEmptySlots()
                    local emptyResourceSlots = CountEmptyResourceSlots()
                    if importMode == "add" then
                        return string.format("|cff888888Aura bars: %d empty slots. Resource bars: %d empty slots. Cooldown bars added if not present.|r", emptyAuraSlots, emptyResourceSlots)
                    else
                        return "|cffFF6600WARNING: This will disable ALL existing aura bars, resource bars, and clear ALL cooldown bar configs!|r"
                    end
                end,
                order = 26,
            },
            
            importBtn = {
                type = "execute",
                name = "Import",
                order = 27,
                width = 1,
                disabled = function() return importPreviewData == nil end,
                func = function()
                    if not importPreviewData then
                        print("|cffFF0000[ArcUI]|r No valid import data. Paste a string and Preview first.")
                        return
                    end
                    
                    local success, result = ImportBars(importPreviewData, importMode)
                    if success then
                        print("|cff00FF00[ArcUI]|r " .. result)
                        -- Clear import state
                        lastImportString = ""
                        importPreviewData = nil
                    else
                        print("|cffFF0000[ArcUI]|r Import failed: " .. result)
                    end
                end,
            },
        },
    }
    
    return options
end

-- Export the function for Options.lua to use
ns.GetBarsImportExportOptionsTable = function()
    return ns.BarsImportExport.GetOptionsTable()
end