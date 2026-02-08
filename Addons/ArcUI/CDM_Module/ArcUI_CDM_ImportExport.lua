-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI CDM Import/Export Module
-- Comprehensive export/import of all CDM settings including:
--   - Group layouts and positions (CDMGroups)
--   - Per-icon visual settings (CDMEnhance iconSettings)
--   - Global aura/cooldown defaults (CDMEnhance)
--   - Group-level settings (spacing, scale, direction)
--   - Layout profiles with talent conditions
-- ═══════════════════════════════════════════════════════════════════════════

local ADDON_NAME, ns = ...

ns.CDMImportExport = ns.CDMImportExport or {}
local IE = ns.CDMImportExport

-- Use shared helpers (dynamic lookup to handle load order)
local function GetShared()
    return ns.CDMShared
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════════

local EXPORT_VERSION = 1  -- Increment when export format changes
local EXPORT_PREFIX = "ARCCDM"  -- Identifier for validation
local MSG_PREFIX = "|cff00ccffArcUI|r: "

-- ═══════════════════════════════════════════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════════════════════════════════════════

local LibDeflate
local function GetLibDeflate()
    if not LibDeflate then
        LibDeflate = LibStub and LibStub("LibDeflate", true)
    end
    return LibDeflate
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function PrintMsg(msg)
    print(MSG_PREFIX .. msg)
end

-- Serialize table to string (simple Lua serialization)
local function SerializeTable(tbl, indent)
    indent = indent or ""
    local parts = {}
    
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then
            return string.format("%q", tbl)
        elseif type(tbl) == "number" or type(tbl) == "boolean" then
            return tostring(tbl)
        elseif tbl == nil then
            return "nil"
        else
            return "nil"  -- Skip unsupported types
        end
    end
    
    table.insert(parts, "{")
    local nextIndent = indent .. " "
    local items = {}
    
    -- Handle both array and hash parts
    local arrayLen = #tbl
    local hasArrayPart = arrayLen > 0
    
    -- Array part first
    for i = 1, arrayLen do
        local v = tbl[i]
        if v ~= nil then
            table.insert(items, SerializeTable(v, nextIndent))
        end
    end
    
    -- Hash part
    for k, v in pairs(tbl) do
        -- Skip array indices we already handled
        if type(k) ~= "number" or k < 1 or k > arrayLen or math.floor(k) ~= k then
            local keyStr
            if type(k) == "string" then
                -- Use simple key format if valid identifier, else use brackets
                if k:match("^[%a_][%w_]*$") then
                    keyStr = k
                else
                    keyStr = "[" .. string.format("%q", k) .. "]"
                end
            elseif type(k) == "number" then
                keyStr = "[" .. tostring(k) .. "]"
            else
                keyStr = "[" .. string.format("%q", tostring(k)) .. "]"
            end
            table.insert(items, keyStr .. "=" .. SerializeTable(v, nextIndent))
        end
    end
    
    if #items > 0 then
        table.insert(parts, table.concat(items, ","))
    end
    table.insert(parts, "}")
    
    return table.concat(parts)
end

-- Deserialize string back to table
local function DeserializeTable(str)
    if not str or str == "" then return nil, "Empty string" end
    
    -- Security: Only allow specific patterns (no function calls, etc.)
    local sanitized = str:gsub("%s+", " ")
    
    -- Check for dangerous patterns
    -- More precise checks to avoid false positives while catching actual threats
    if sanitized:match("[%[%]]+%s*function") or 
       sanitized:match("loadstring") or 
       sanitized:match("dofile") or
       sanitized:match("require%s*%(") or
       sanitized:match("require%s*%[") or
       sanitized:match("_G%s*[%[%.]") or  -- _G[ or _G. (actual global access)
       sanitized:match("getfenv") or
       sanitized:match("setfenv") or
       sanitized:match("rawget") or
       sanitized:match("rawset") then
        return nil, "Invalid data: potentially unsafe content"
    end
    
    -- Wrap in return statement for loadstring
    local func, err = loadstring("return " .. str)
    if not func then
        return nil, "Parse error: " .. tostring(err)
    end
    
    -- Execute in protected environment
    setfenv(func, {})
    local ok, result = pcall(func)
    if not ok then
        return nil, "Execution error: " .. tostring(result)
    end
    
    return result, nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORT FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Build export data structure from current settings
local function BuildExportData(options)
    options = options or {}
    local Shared = GetShared()
    
    if not Shared then
        print(MSG_PREFIX .. "|cffff0000ERROR: CDMShared not available!|r")
        return nil
    end
    
    local exportData = {
        version = EXPORT_VERSION,
        prefix = EXPORT_PREFIX,
        timestamp = time(),
        exportedBy = UnitName("player") or "Unknown",
        realm = GetRealmName() or "Unknown",
    }
    
    -- Get current spec key
    local currentSpec = ns.CDMGroups and ns.CDMGroups.currentSpec
    if currentSpec then
        exportData.sourceSpec = currentSpec
    end
    
    print(MSG_PREFIX .. "BuildExportData: currentSpec=" .. tostring(currentSpec))
    
    -- ─────────────────────────────────────────────────────────────────────────
    -- CDMGroups Data (group layouts, positions, free icons, iconSettings, groupSettings)
    -- Uses character-specific storage via Shared.GetCDMGroupsDB()
    -- iconSettings and groupSettings are now stored per-spec alongside layouts
    -- ─────────────────────────────────────────────────────────────────────────
    local cdmGroupsDB = Shared.GetCDMGroupsDB()
    print(MSG_PREFIX .. "BuildExportData: cdmGroupsDB exists=" .. tostring(cdmGroupsDB ~= nil))
    
    if cdmGroupsDB then
        print(MSG_PREFIX .. "BuildExportData: specData exists=" .. tostring(cdmGroupsDB.specData ~= nil))
        if cdmGroupsDB.specData then
            print(MSG_PREFIX .. "BuildExportData: specData[currentSpec] exists=" .. tostring(cdmGroupsDB.specData[currentSpec] ~= nil))
        end
        
        -- Export current spec data
        if cdmGroupsDB.specData and currentSpec and cdmGroupsDB.specData[currentSpec] then
            local specData = cdmGroupsDB.specData[currentSpec]
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- PHASE 1: Export from PROFILE (single source of truth)
            -- ═══════════════════════════════════════════════════════════════════════════
            local activeProfileName = specData.activeProfile or "Default"
            local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
            
            -- Debug: count iconSettings from PROFILE (now that profile is defined!)
            local iconCount = 0
            if profile and profile.iconSettings then
                for _ in pairs(profile.iconSettings) do iconCount = iconCount + 1 end
            end
            print(MSG_PREFIX .. "BuildExportData: profile.iconSettings has " .. iconCount .. " entries")
            print(MSG_PREFIX .. "BuildExportData: options.includeIconSettings=" .. tostring(options.includeIconSettings))
            
            -- Build layoutProfiles with ONLY the active profile
            local exportedLayoutProfiles = nil
            if profile then
                exportedLayoutProfiles = {
                    [activeProfileName] = DeepCopy(profile)
                }
            end
            
            -- iconSettings is now in profile, but we also export at top level for backwards compatibility
            local exportedIconSettings = nil
            if options.includeIconSettings ~= false and profile and profile.iconSettings then
                exportedIconSettings = DeepCopy(profile.iconSettings)
            end
            
            -- Export global icon settings (stored at root of cdmGroups, not per-spec)
            -- These include: disableTooltips, clickThrough
            local exportedGlobalIconSettings = nil
            if options.includeGroupSettings ~= false then
                exportedGlobalIconSettings = {
                    disableTooltips = cdmGroupsDB.disableTooltips,
                    clickThrough = cdmGroupsDB.clickThrough,
                }
            end
            
            exportData.cdmGroups = {
                -- DEPRECATED: Don't export specData.groups (has runtime data)
                groups = nil,
                -- Export positions from PROFILE (the authoritative source)
                savedPositions = (options.includePositions ~= false) and profile and profile.savedPositions and DeepCopy(profile.savedPositions) or nil,
                freeIcons = (options.includePositions ~= false) and profile and profile.freeIcons and DeepCopy(profile.freeIcons) or nil,
                -- Export ONLY the active profile (not all profiles)
                layoutProfiles = exportedLayoutProfiles,
                activeProfile = activeProfileName,
                -- Export iconSettings at TOP LEVEL for backwards compat with old imports
                -- (Also in profile.iconSettings within layoutProfiles above)
                iconSettings = exportedIconSettings,
                groupSettings = (options.includeGroupSettings ~= false) and specData.groupSettings and DeepCopy(specData.groupSettings) or nil,
                -- Global icon settings (tooltips, click-through) - stored at root, not per-spec
                globalIconSettings = exportedGlobalIconSettings,
            }
            
            -- Debug: verify what was copied
            local exportedIconCount = 0
            if exportData.cdmGroups.iconSettings then
                for _ in pairs(exportData.cdmGroups.iconSettings) do exportedIconCount = exportedIconCount + 1 end
            end
            print(MSG_PREFIX .. "BuildExportData: exportData.cdmGroups.iconSettings has " .. exportedIconCount .. " entries")
            
            -- Debug: count positions
            local posCount = 0
            local freeCount = 0
            if exportData.cdmGroups.savedPositions then
                for _ in pairs(exportData.cdmGroups.savedPositions) do posCount = posCount + 1 end
            end
            if exportData.cdmGroups.freeIcons then
                for _ in pairs(exportData.cdmGroups.freeIcons) do freeCount = freeCount + 1 end
            end
            print(MSG_PREFIX .. "BuildExportData: Exported " .. posCount .. " positions, " .. freeCount .. " freeIcons from PROFILE")
            
            -- Clean runtime data from layout profiles (shouldn't have any, but be safe)
            if exportData.cdmGroups.layoutProfiles then
                for profileName, profileData in pairs(exportData.cdmGroups.layoutProfiles) do
                    if profileData.groupLayouts then
                        for gName, gLayout in pairs(profileData.groupLayouts) do
                            gLayout.members = nil
                            gLayout.grid = nil
                            gLayout.container = nil
                            gLayout.dragBar = nil
                        end
                    end
                end
            end
        end
    end
    
    -- ─────────────────────────────────────────────────────────────────────────
    -- CDMEnhance Data (global defaults ONLY - shared across all specs)
    -- iconSettings and groupSettings are now in cdmGroups above (per-spec)
    -- ─────────────────────────────────────────────────────────────────────────
    if ns.db and ns.db.profile and ns.db.profile.cdmEnhance then
        local cdmEnhance = ns.db.profile.cdmEnhance
        
        exportData.cdmEnhance = {
            -- Global defaults for auras and cooldowns (SHARED across all specs)
            globalAuraSettings = (options.includeGlobalSettings ~= false) and cdmEnhance.globalAuraSettings and DeepCopy(cdmEnhance.globalAuraSettings) or nil,
            globalCooldownSettings = (options.includeGlobalSettings ~= false) and cdmEnhance.globalCooldownSettings and DeepCopy(cdmEnhance.globalCooldownSettings) or nil,
            
            -- Global toggle states
            globalApplyScale = cdmEnhance.globalApplyScale,
            globalApplyHideShadow = cdmEnhance.globalApplyHideShadow,
            disableRightClickSelect = cdmEnhance.disableRightClickSelect,
            lockGridSize = cdmEnhance.lockGridSize,
        }
    end
    
    -- ─────────────────────────────────────────────────────────────────────────
    -- Arc Auras Data (per-character item tracking)
    -- Includes tracked items (trinkets, consumables) and their positions
    -- ─────────────────────────────────────────────────────────────────────────
    if ns.db and ns.db.char and ns.db.char.arcAuras then
        local arcAuras = ns.db.char.arcAuras
        
        if (options.includeArcAuras ~= false) and arcAuras.trackedItems and next(arcAuras.trackedItems) then
            exportData.arcAuras = {
                trackedItems = DeepCopy(arcAuras.trackedItems),
                positions = arcAuras.positions and DeepCopy(arcAuras.positions) or nil,
                globalSettings = arcAuras.globalSettings and next(arcAuras.globalSettings) and DeepCopy(arcAuras.globalSettings) or nil,
                enabled = arcAuras.enabled,
            }
            
            -- Debug count
            local itemCount = 0
            for _ in pairs(arcAuras.trackedItems) do itemCount = itemCount + 1 end
            print(MSG_PREFIX .. "BuildExportData: arcAuras.trackedItems has " .. itemCount .. " entries")
        end
    end
    
    return exportData
end

-- Export settings to compressed base64 string
function IE.Export(options)
    local LD = GetLibDeflate()
    if not LD then
        return nil, "LibDeflate not available"
    end
    
    -- Build export data
    local exportData = BuildExportData(options)
    if not exportData then
        return nil, "Failed to build export data"
    end
    
    -- Serialize to string
    local serialized = SerializeTable(exportData)
    if not serialized then
        return nil, "Failed to serialize data"
    end
    
    -- Compress with LibDeflate
    local compressed = LD:CompressDeflate(serialized)
    if not compressed then
        return nil, "Failed to compress data"
    end
    
    -- Encode to base64 for clipboard-safe output
    local encoded = LD:EncodeForPrint(compressed)
    if not encoded then
        return nil, "Failed to encode data"
    end
    
    return encoded, nil
end

-- Get export data statistics (for UI display)
function IE.GetExportStats()
    local Shared = GetShared()
    local stats = {
        groups = 0,
        savedPositions = 0,
        freeIcons = 0,
        iconSettings = 0,
        layoutProfiles = 0,
        hasGlobalAura = false,
        hasGlobalCooldown = false,
        hasGroupSettings = false,
    }
    
    if not Shared then return stats end
    
    -- CDMGroups stats (character-specific storage)
    local cdmGroupsDB = Shared.GetCDMGroupsDB()
    if cdmGroupsDB then
        local currentSpec = ns.CDMGroups and ns.CDMGroups.currentSpec
        
        if cdmGroupsDB.specData and currentSpec and cdmGroupsDB.specData[currentSpec] then
            local specData = cdmGroupsDB.specData[currentSpec]
            
            -- Count layout profiles
            if specData.layoutProfiles then
                for _ in pairs(specData.layoutProfiles) do
                    stats.layoutProfiles = stats.layoutProfiles + 1
                end
            end
            
            -- Get active profile for stats
            local activeProfileName = specData.activeProfile or "Default"
            local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
            
            if profile then
                -- Count groups from profile.groupLayouts
                if profile.groupLayouts then
                    for _ in pairs(profile.groupLayouts) do
                        stats.groups = stats.groups + 1
                    end
                end
                
                -- Count positions from profile.savedPositions
                if profile.savedPositions then
                    for _ in pairs(profile.savedPositions) do
                        stats.savedPositions = stats.savedPositions + 1
                    end
                end
                
                -- Count free icons from profile.freeIcons
                if profile.freeIcons then
                    for _ in pairs(profile.freeIcons) do
                        stats.freeIcons = stats.freeIcons + 1
                    end
                end
                
                -- Count iconSettings from profile.iconSettings (NEW location)
                if profile.iconSettings then
                    for _ in pairs(profile.iconSettings) do
                        stats.iconSettings = stats.iconSettings + 1
                    end
                end
            end
            
            -- groupSettings is still at specData level
            stats.hasGroupSettings = specData.groupSettings and next(specData.groupSettings) ~= nil
        end
    end
    
    -- CDMEnhance stats (global defaults only - shared)
    if ns.db and ns.db.profile and ns.db.profile.cdmEnhance then
        local cdmEnhance = ns.db.profile.cdmEnhance
        
        stats.hasGlobalAura = cdmEnhance.globalAuraSettings and next(cdmEnhance.globalAuraSettings) ~= nil
        stats.hasGlobalCooldown = cdmEnhance.globalCooldownSettings and next(cdmEnhance.globalCooldownSettings) ~= nil
    end
    
    -- Arc Auras stats (per-character)
    stats.arcAuras = 0
    if ns.db and ns.db.char and ns.db.char.arcAuras and ns.db.char.arcAuras.trackedItems then
        for _ in pairs(ns.db.char.arcAuras.trackedItems) do
            stats.arcAuras = stats.arcAuras + 1
        end
    end
    
    return stats
end

-- ═══════════════════════════════════════════════════════════════════════════
-- IMPORT FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Validate import data structure
local function ValidateImportData(data)
    if type(data) ~= "table" then
        return false, "Invalid data format"
    end
    
    if data.prefix ~= EXPORT_PREFIX then
        return false, "Invalid export prefix - this doesn't appear to be ArcUI CDM data"
    end
    
    if not data.version then
        return false, "Missing version number"
    end
    
    if data.version > EXPORT_VERSION then
        return false, "Export version " .. data.version .. " is newer than supported version " .. EXPORT_VERSION
    end
    
    return true, nil
end

-- Parse import string and return data structure (for preview)
function IE.ParseImportString(importString)
    if not importString or importString == "" then
        return nil, "Empty import string"
    end
    
    -- Clean up the string (remove whitespace, newlines)
    importString = importString:gsub("%s+", "")
    
    local LD = GetLibDeflate()
    if not LD then
        return nil, "LibDeflate not available"
    end
    
    -- Decode from base64
    local decoded = LD:DecodeForPrint(importString)
    if not decoded then
        return nil, "Failed to decode data - invalid format"
    end
    
    -- Decompress
    local decompressed = LD:DecompressDeflate(decoded)
    if not decompressed then
        return nil, "Failed to decompress data - corrupted or invalid"
    end
    
    -- Deserialize
    local data, err = DeserializeTable(decompressed)
    if not data then
        return nil, "Failed to parse data: " .. (err or "unknown error")
    end
    
    -- Validate
    local valid, validErr = ValidateImportData(data)
    if not valid then
        return nil, validErr
    end
    
    return data, nil
end

-- Get import data statistics (for preview UI)
function IE.GetImportStats(data)
    if not data then return nil end
    
    local stats = {
        version = data.version,
        timestamp = data.timestamp,
        exportedBy = data.exportedBy,
        realm = data.realm,
        sourceSpec = data.sourceSpec,
        groups = 0,
        savedPositions = 0,
        freeIcons = 0,
        iconSettings = 0,
        layoutProfiles = 0,
        hasGlobalAuraSettings = false,
        hasGlobalCooldownSettings = false,
        hasGroupSettings = false,
    }
    
    if data.cdmGroups then
        -- Count groups from layoutProfiles.groupLayouts (groups field is deprecated)
        if data.cdmGroups.layoutProfiles then
            for profileName, profileData in pairs(data.cdmGroups.layoutProfiles) do
                if profileData.groupLayouts then
                    for _ in pairs(profileData.groupLayouts) do
                        stats.groups = stats.groups + 1
                    end
                    break  -- Only count first profile (the exported active profile)
                end
            end
        end
        -- LEGACY: Old exports had groups at top level
        if stats.groups == 0 and data.cdmGroups.groups then
            for _ in pairs(data.cdmGroups.groups) do
                stats.groups = stats.groups + 1
            end
        end
        
        if data.cdmGroups.savedPositions then
            for _ in pairs(data.cdmGroups.savedPositions) do
                stats.savedPositions = stats.savedPositions + 1
            end
        end
        
        if data.cdmGroups.freeIcons then
            for _ in pairs(data.cdmGroups.freeIcons) do
                stats.freeIcons = stats.freeIcons + 1
            end
        end
        
        if data.cdmGroups.layoutProfiles then
            for _ in pairs(data.cdmGroups.layoutProfiles) do
                stats.layoutProfiles = stats.layoutProfiles + 1
            end
        end
        
        -- Check iconSettings at TOP LEVEL (legacy exports + new backwards compat export)
        if data.cdmGroups.iconSettings then
            for _ in pairs(data.cdmGroups.iconSettings) do
                stats.iconSettings = stats.iconSettings + 1
            end
        end
        
        -- Also check iconSettings INSIDE layoutProfiles (new format)
        if stats.iconSettings == 0 and data.cdmGroups.layoutProfiles then
            local profileName = data.cdmGroups.activeProfile or "Default"
            local profileData = data.cdmGroups.layoutProfiles[profileName]
            if profileData and profileData.iconSettings then
                for _ in pairs(profileData.iconSettings) do
                    stats.iconSettings = stats.iconSettings + 1
                end
            end
        end
        
        -- groupSettings are at specData level
        stats.hasGroupSettings = data.cdmGroups.groupSettings ~= nil
    end
    
    if data.cdmEnhance then
        -- BACKWARDS COMPAT: Old exports had iconSettings in cdmEnhance
        if data.cdmEnhance.iconSettings and stats.iconSettings == 0 then
            for _ in pairs(data.cdmEnhance.iconSettings) do
                stats.iconSettings = stats.iconSettings + 1
            end
        end
        
        stats.hasGlobalAuraSettings = data.cdmEnhance.globalAuraSettings ~= nil
        stats.hasGlobalCooldownSettings = data.cdmEnhance.globalCooldownSettings ~= nil
        
        -- BACKWARDS COMPAT: Old exports had groupSettings in cdmEnhance
        if not stats.hasGroupSettings then
            stats.hasGroupSettings = data.cdmEnhance.groupSettings ~= nil
        end
    end
    
    -- Arc Auras stats
    stats.arcAuras = 0
    if data.arcAuras and data.arcAuras.trackedItems then
        for _ in pairs(data.arcAuras.trackedItems) do
            stats.arcAuras = stats.arcAuras + 1
        end
    end
    
    return stats
end

-- Apply imported data to current settings
function IE.Import(importString, options)
    options = options or {}
    
    -- Parse and validate
    local data, err = IE.ParseImportString(importString)
    if not data then
        return false, err
    end
    
    -- Check database availability
    if not ns.db then
        return false, "Database not ready"
    end
    
    -- Get current spec - calculate if not determined yet
    local currentSpec = ns.CDMGroups and ns.CDMGroups.currentSpec
    if not currentSpec then
        local specIdx = GetSpecialization() or 1
        local _, _, classID = UnitClass("player")
        classID = classID or 0
        currentSpec = "class_" .. classID .. "_spec_" .. specIdx
        if ns.CDMGroups then
            ns.CDMGroups.currentSpec = currentSpec
        end
    end
    
    local importedCounts = {
        layoutProfiles = 0,
        arcAuras = 0,
    }
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- SIMPLIFIED IMPORT: Just add profiles to the database
    -- ═══════════════════════════════════════════════════════════════════════════
    if data.cdmGroups then
        -- Ensure database structure exists (robust for fresh load)
        if not ns.db.char then ns.db.char = {} end
        if not ns.db.char.cdmGroups then
            ns.db.char.cdmGroups = {
                specData = {},
                specInheritedFrom = {},
                enabled = true,
            }
        end
        
        local cdmGroupsDB = ns.db.char.cdmGroups
        if not cdmGroupsDB.specData then cdmGroupsDB.specData = {} end
        
        -- Ensure specData for current spec exists
        if not cdmGroupsDB.specData[currentSpec] then
            cdmGroupsDB.specData[currentSpec] = {
                layoutProfiles = {},
                activeProfile = "Default",
            }
        end
        
        local specData = cdmGroupsDB.specData[currentSpec]
        
        -- Ensure layoutProfiles exists
        if not specData.layoutProfiles then
            specData.layoutProfiles = {}
        end
        
        -- Ensure Default profile exists
        if not specData.layoutProfiles["Default"] then
            specData.layoutProfiles["Default"] = {
                savedPositions = {},
                freeIcons = {},
                groupLayouts = {},
                iconSettings = {},
            }
        end
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- ADD IMPORTED PROFILES
        -- Naming strategy: If profile name exists, use "ProfileName (ExportedBy)"
        -- If that also exists, append number: "ProfileName (ExportedBy) 2", etc.
        -- ═══════════════════════════════════════════════════════════════════════════
        local importedProfileName = nil
        local exportedBy = data.exportedBy or "Imported"
        
        if data.cdmGroups.layoutProfiles then
            for profileName, profileData in pairs(data.cdmGroups.layoutProfiles) do
                local finalName = profileName
                
                -- Check if profile name already exists
                if specData.layoutProfiles[profileName] then
                    -- Profile exists - create new name with exportedBy
                    local baseName = profileName .. " (" .. exportedBy .. ")"
                    finalName = baseName
                    
                    -- If that also exists, append numbers
                    local counter = 2
                    while specData.layoutProfiles[finalName] do
                        finalName = baseName .. " " .. counter
                        counter = counter + 1
                    end
                    
                    print(MSG_PREFIX .. "|cffFFFF00Profile '" .. profileName .. "' already exists|r - importing as '" .. finalName .. "'")
                end
                
                -- Import the profile with the final (possibly renamed) name
                specData.layoutProfiles[finalName] = DeepCopy(profileData)
                importedCounts.layoutProfiles = importedCounts.layoutProfiles + 1
                importedProfileName = importedProfileName or finalName
                print(MSG_PREFIX .. "Added profile: " .. finalName)
            end
        end
        
        -- Use activeProfile from import if available
        if not importedProfileName then
            importedProfileName = data.cdmGroups.activeProfile
        end
        
        -- Default to "Default" if nothing imported
        importedProfileName = importedProfileName or "Default"
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- REPAIR: Ensure all profiles have valid groupLayouts
        -- ═══════════════════════════════════════════════════════════════════════════
        local DEFAULT_GROUPS = ns.CDMGroups and ns.CDMGroups.DEFAULT_GROUPS
        
        for profileName, profileData in pairs(specData.layoutProfiles) do
            -- Ensure required tables exist
            if not profileData.savedPositions then profileData.savedPositions = {} end
            if not profileData.freeIcons then profileData.freeIcons = {} end
            if not profileData.iconSettings then profileData.iconSettings = {} end
            
            -- If groupLayouts is empty, populate from DEFAULT_GROUPS
            if not profileData.groupLayouts or not next(profileData.groupLayouts) then
                print(MSG_PREFIX .. "|cffff8800[Repair]|r Profile '" .. profileName .. "' has no groups - adding defaults")
                profileData.groupLayouts = {}
                if DEFAULT_GROUPS then
                    for groupName, groupData in pairs(DEFAULT_GROUPS) do
                        local layout = groupData.layout
                        profileData.groupLayouts[groupName] = {
                            position = groupData.position and DeepCopy(groupData.position) or { x = 0, y = 100 },
                            gridRows = layout and layout.gridRows or 2,
                            gridCols = layout and layout.gridCols or 4,
                            iconSize = layout and layout.iconSize or 36,
                            iconWidth = layout and layout.iconWidth or 36,
                            iconHeight = layout and layout.iconHeight or 36,
                            spacing = layout and layout.spacing or 2,
                            spacingX = layout and layout.spacingX,
                            spacingY = layout and layout.spacingY,
                            separateSpacing = layout and layout.separateSpacing,
                            alignment = layout and layout.alignment,
                            horizontalGrowth = layout and layout.horizontalGrowth,
                            verticalGrowth = layout and layout.verticalGrowth,
                            showBorder = groupData.showBorder or false,
                            showBackground = groupData.showBackground or false,
                            autoReflow = groupData.autoReflow or false,
                            dynamicLayout = groupData.dynamicLayout or false,
                            lockGridSize = groupData.lockGridSize or false,
                            containerPadding = groupData.containerPadding or 0,
                            borderColor = groupData.borderColor and DeepCopy(groupData.borderColor) or { r = 0.5, g = 0.5, b = 0.5, a = 1 },
                            bgColor = groupData.bgColor and DeepCopy(groupData.bgColor) or { r = 0, g = 0, b = 0, a = 0.6 },
                            visibility = groupData.visibility or "always",
                        }
                    end
                else
                    -- Fallback (no DEFAULT_GROUPS available)
                    local fallbackDefaults = { iconWidth = 36, iconHeight = 36, showBorder = false, showBackground = false, autoReflow = false, containerPadding = 0, borderColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 }, bgColor = { r = 0, g = 0, b = 0, a = 0.6 }, visibility = "always" }
                    local function MakeFallback(x, y)
                        local g = { position = { x = x, y = y }, gridRows = 2, gridCols = 4, iconSize = 36, spacing = 2 }
                        for k, v in pairs(fallbackDefaults) do g[k] = type(v) == "table" and DeepCopy(v) or v end
                        return g
                    end
                    profileData.groupLayouts = {
                        ["Essential"] = MakeFallback(0, 100),
                        ["Utility"] = MakeFallback(0, 0),
                        ["Buffs"] = MakeFallback(0, 200),
                    }
                end
            end
        end
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- SET ACTIVE PROFILE to the imported one
        -- ═══════════════════════════════════════════════════════════════════════════
        specData.activeProfile = importedProfileName
        print(MSG_PREFIX .. "Set active profile to: " .. importedProfileName)
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- IMPORT GROUP SETTINGS (scale, padding, direction, rowLimit for aura/cooldown/utility)
        -- These are at specData level, not profile level
        -- ═══════════════════════════════════════════════════════════════════════════
        if data.cdmGroups.groupSettings then
            specData.groupSettings = DeepCopy(data.cdmGroups.groupSettings)
            print(MSG_PREFIX .. "Imported groupSettings (aura/cooldown/utility scale, padding, direction)")
        end
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- IMPORT GLOBAL ICON SETTINGS (tooltips, click-through)
        -- These are at cdmGroups root level, not per-spec
        -- ═══════════════════════════════════════════════════════════════════════════
        if data.cdmGroups.globalIconSettings then
            local globalSettings = data.cdmGroups.globalIconSettings
            if globalSettings.disableTooltips ~= nil then
                cdmGroupsDB.disableTooltips = globalSettings.disableTooltips
            end
            if globalSettings.clickThrough ~= nil then
                cdmGroupsDB.clickThrough = globalSettings.clickThrough
            end
            print(MSG_PREFIX .. "Imported globalIconSettings (tooltips, click-through)")
            
            -- Refresh cached settings so changes take effect
            if ns.CDMGroups and ns.CDMGroups.RefreshCachedLayoutSettings then
                ns.CDMGroups.RefreshCachedLayoutSettings()
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- IMPORT CDM ENHANCE SETTINGS (global aura/cooldown visuals)
    -- These are in ns.db.profile.cdmEnhance
    -- ═══════════════════════════════════════════════════════════════════════════
    if data.cdmEnhance then
        if not ns.db.profile then ns.db.profile = {} end
        if not ns.db.profile.cdmEnhance then
            ns.db.profile.cdmEnhance = {}
        end
        
        local cdmEnhance = ns.db.profile.cdmEnhance
        
        -- Import global aura settings
        if data.cdmEnhance.globalAuraSettings then
            cdmEnhance.globalAuraSettings = DeepCopy(data.cdmEnhance.globalAuraSettings)
            print(MSG_PREFIX .. "Imported globalAuraSettings (aura visuals, text, glow)")
        end
        
        -- Import global cooldown settings  
        if data.cdmEnhance.globalCooldownSettings then
            cdmEnhance.globalCooldownSettings = DeepCopy(data.cdmEnhance.globalCooldownSettings)
            print(MSG_PREFIX .. "Imported globalCooldownSettings (cooldown visuals, text, glow)")
        end
        
        -- Import other CDMEnhance flags
        if data.cdmEnhance.globalApplyScale ~= nil then
            cdmEnhance.globalApplyScale = data.cdmEnhance.globalApplyScale
        end
        if data.cdmEnhance.globalApplyHideShadow ~= nil then
            cdmEnhance.globalApplyHideShadow = data.cdmEnhance.globalApplyHideShadow
        end
        if data.cdmEnhance.disableRightClickSelect ~= nil then
            cdmEnhance.disableRightClickSelect = data.cdmEnhance.disableRightClickSelect
        end
        if data.cdmEnhance.lockGridSize ~= nil then
            cdmEnhance.lockGridSize = data.cdmEnhance.lockGridSize
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- IMPORT ARC AURAS (if present)
    -- ═══════════════════════════════════════════════════════════════════════════
    if data.arcAuras and data.arcAuras.trackedItems then
        if not ns.db.char then ns.db.char = {} end
        if not ns.db.char.arcAuras then
            ns.db.char.arcAuras = {
                enabled = false,
                trackedItems = {},
                positions = {},
            }
        end
        
        local arcAuras = ns.db.char.arcAuras
        
        -- Add tracked items
        for arcID, config in pairs(data.arcAuras.trackedItems) do
            arcAuras.trackedItems[arcID] = DeepCopy(config)
            importedCounts.arcAuras = importedCounts.arcAuras + 1
        end
        
        -- Add positions
        if data.arcAuras.positions then
            for arcID, pos in pairs(data.arcAuras.positions) do
                arcAuras.positions[arcID] = DeepCopy(pos)
            end
        end
        
        -- Set enabled
        if data.arcAuras.enabled then
            arcAuras.enabled = data.arcAuras.enabled
        end
        
        print(MSG_PREFIX .. "Imported " .. importedCounts.arcAuras .. " Arc Auras")
        
        -- Also copy to target profile for profile system
        local cdmGroupsDB = ns.db.char.cdmGroups
        if cdmGroupsDB and cdmGroupsDB.specData and cdmGroupsDB.specData[currentSpec] then
            local specData = cdmGroupsDB.specData[currentSpec]
            local targetProfile = specData.layoutProfiles and specData.layoutProfiles[specData.activeProfile or "Default"]
            if targetProfile then
                targetProfile.arcAuras = {
                    trackedItems = DeepCopy(arcAuras.trackedItems),
                    positions = DeepCopy(arcAuras.positions),
                    enabled = arcAuras.enabled,
                }
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- POST-IMPORT: Clear cache and load the profile
    -- ═══════════════════════════════════════════════════════════════════════════
    
    -- Clear any cached database references
    local Shared = GetShared()
    if Shared and Shared.ClearDBCache then
        Shared.ClearDBCache()
    end
    
    -- Invalidate CDMEnhance settings cache
    if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
        ns.CDMEnhance.InvalidateCache()
    end
    
    -- Get the profile name to load
    local profileToLoad = "Default"
    if ns.db.char.cdmGroups and ns.db.char.cdmGroups.specData and ns.db.char.cdmGroups.specData[currentSpec] then
        profileToLoad = ns.db.char.cdmGroups.specData[currentSpec].activeProfile or "Default"
    end
    
    -- Load the imported profile
    if ns.CDMGroups and ns.CDMGroups.LoadProfile then
        C_Timer.After(0.2, function()
            PrintMsg("Loading profile '" .. profileToLoad .. "'...")
            ns.CDMGroups.LoadProfile(profileToLoad)
        end)
    end
    
    -- Notify FrameController that layout changed
    if ns.FrameController and ns.FrameController.OnLayoutChange then
        ns.FrameController.OnLayoutChange()
    end
    
    return true, importedCounts
end


-- ═══════════════════════════════════════════════════════════════════════════
-- ACCOUNT IMPORT FUNCTIONS
-- Import group layouts from other specs/characters on the same account
-- ═══════════════════════════════════════════════════════════════════════════

-- Class names for fallback display
local CLASS_NAMES = {
    [1] = "Warrior",
    [2] = "Paladin",
    [3] = "Hunter",
    [4] = "Rogue",
    [5] = "Priest",
    [6] = "Death Knight",
    [7] = "Shaman",
    [8] = "Mage",
    [9] = "Warlock",
    [10] = "Monk",
    [11] = "Druid",
    [12] = "Demon Hunter",
    [13] = "Evoker",
}

-- Class file names for RAID_CLASS_COLORS lookup
local CLASS_FILES = {
    [1] = "WARRIOR",
    [2] = "PALADIN", 
    [3] = "HUNTER",
    [4] = "ROGUE",
    [5] = "PRIEST",
    [6] = "DEATHKNIGHT",
    [7] = "SHAMAN",
    [8] = "MAGE",
    [9] = "WARLOCK",
    [10] = "MONK",
    [11] = "DRUID",
    [12] = "DEMONHUNTER",
    [13] = "EVOKER",
}

-- Get available layouts for import from both character and account-wide data
function IE.GetAvailableLayoutsForImport()
    local layouts = {}
    
    local currentSpec = ns.CDMGroups and ns.CDMGroups.currentSpec
    local currentProfile = (ns.CDMGroups and ns.CDMGroups.GetActiveProfileName) and ns.CDMGroups.GetActiveProfileName() or "Default"
    local currentCharKey = ns.db and ns.db.keys and ns.db.keys.char  -- e.g., "Arcgem - Anasterian"
    
    -- Helper to add layouts from a specData table
    local function AddLayoutsFromSpecData(specData, charKey, isCurrentChar)
        if not specData then return end
        
        for specKey, data in pairs(specData) do
            -- Parse spec key: "class_7_spec_2" -> classID=7, specIndex=2
            local classID, specIndex = specKey:match("class_(%d+)_spec_(%d+)")
            classID = tonumber(classID)
            specIndex = tonumber(specIndex)
            
            if classID and specIndex and data.groups and next(data.groups) then
                -- Get spec name using API
                local specName = "Spec " .. specIndex
                if GetSpecializationInfoForClassID then
                    local _, name = GetSpecializationInfoForClassID(classID, specIndex)
                    if name then specName = name end
                end
                
                -- Get character name from the data, or parse from charKey
                local charName = data.characterName
                if not charName and charKey then
                    charName = charKey:match("^([^%-]+)") or "Unknown"
                end
                charName = charName or CLASS_NAMES[classID] or "Unknown"
                
                -- Get class color
                local classFile = CLASS_FILES[classID]
                local classColor = RAID_CLASS_COLORS and classFile and RAID_CLASS_COLORS[classFile]
                local colorHex = classColor and classColor:GenerateHexColor() or "ffffffff"
                
                -- Create unique key using || delimiter
                local layoutKey = (charKey or "current") .. "||" .. specKey .. "||Default"
                
                -- Add the Default/base layout (skip if it's our current spec+profile from current char)
                local isCurrentDefault = (isCurrentChar and specKey == currentSpec and currentProfile == "Default")
                if not isCurrentDefault then
                    -- Check if we already added this
                    local alreadyAdded = false
                    for _, existing in ipairs(layouts) do
                        if existing.key == layoutKey then
                            alreadyAdded = true
                            break
                        end
                    end
                    
                    if not alreadyAdded then
                        table.insert(layouts, {
                            key = layoutKey,
                            specKey = specKey,
                            profileName = "Default",
                            charKey = charKey,
                            isCurrentChar = isCurrentChar,
                            displayName = "|c" .. colorHex .. charName .. "|r - " .. specName,
                            charName = charName,
                            specName = specName,
                            classID = classID,
                            colorHex = colorHex,
                            isDefault = true,
                            isArcProfile = false,
                        })
                    end
                end
                
                -- Add Arc Manager Profiles (all profiles including Default)
                if data.layoutProfiles then
                    for profileName, profileData in pairs(data.layoutProfiles) do
                        -- Skip if it's our current spec+profile (can't load what's already loaded)
                        local isCurrentProfile = (isCurrentChar and specKey == currentSpec and profileName == currentProfile)
                        if not isCurrentProfile then
                            -- Include profile if it has group layouts to load
                            -- Fall back to specData.groups for legacy profiles with empty groupLayouts
                            local hasGroupLayouts = profileData.groupLayouts and next(profileData.groupLayouts)
                            local hasSpecGroups = data.groups and next(data.groups)
                            
                            if hasGroupLayouts or hasSpecGroups then
                                local profileKey = (charKey or "current") .. "||" .. specKey .. "||" .. profileName
                                
                                -- Check if we already added this
                                local alreadyAdded = false
                                for _, existing in ipairs(layouts) do
                                    if existing.key == profileKey then
                                        alreadyAdded = true
                                        break
                                    end
                                end
                                
                                if not alreadyAdded then
                                    -- Count groups from profile or fall back to specData.groups
                                    local groupCount = 0
                                    local groupSource = hasGroupLayouts and profileData.groupLayouts or data.groups
                                    if groupSource then
                                        for _ in pairs(groupSource) do
                                            groupCount = groupCount + 1
                                        end
                                    end
                                    
                                    -- Format: "ProfileName (3 groups) (CharName - SpecName) [Profile]"
                                    local groupInfo = " |cff888888(" .. groupCount .. " groups)|r"
                                    table.insert(layouts, {
                                        key = profileKey,
                                        specKey = specKey,
                                        profileName = profileName,
                                        charKey = charKey,
                                        isCurrentChar = isCurrentChar,
                                        displayName = "|cff00ccff" .. profileName .. "|r" .. groupInfo .. " |cff888888(" .. charName .. " - " .. specName .. ")|r |cffff9900[Profile]|r",
                                        charName = charName,
                                        specName = specName,
                                        classID = classID,
                                        colorHex = colorHex,
                                        isDefault = false,
                                        isArcProfile = true,
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Access ALL characters via ns.db.sv.char (raw SavedVariables table)
    if ns.db and ns.db.sv and ns.db.sv.char then
        for charKey, charData in pairs(ns.db.sv.char) do
            if type(charData) == "table" and charData.cdmGroups and charData.cdmGroups.specData then
                local isCurrentChar = (charKey == currentCharKey)
                AddLayoutsFromSpecData(charData.cdmGroups.specData, charKey, isCurrentChar)
            end
        end
    end
    
    -- Sort: Specs first, then Arc Profiles; current char first, then by class/char/spec
    local _, _, myClassID = UnitClass("player")
    myClassID = myClassID or 0
    
    table.sort(layouts, function(a, b) 
        -- Spec layouts before Arc Profiles
        if a.isArcProfile ~= b.isArcProfile then
            return not a.isArcProfile
        end
        -- Current character first
        if a.isCurrentChar ~= b.isCurrentChar then
            return a.isCurrentChar
        end
        -- Same class as current character first
        local aIsMyClass = (a.classID == myClassID)
        local bIsMyClass = (b.classID == myClassID)
        if aIsMyClass ~= bIsMyClass then
            return aIsMyClass
        end
        -- Then by character name
        if a.charName ~= b.charName then
            return a.charName < b.charName
        end
        -- Default profiles before custom profiles
        if a.isDefault ~= b.isDefault then
            return a.isDefault
        end
        -- Then by spec/profile name
        if a.isDefault then
            return a.specName < b.specName
        else
            return a.profileName < b.profileName
        end
    end)
    
    return layouts
end

-- Import group layout structure from another spec/character
-- importKey format: "charKey||specKey||profileName" (e.g., "Arcgem - Anasterian||class_7_spec_2||Test1")
function IE.ImportLayoutFromAccount(importKey)
    -- Parse import key using || delimiter
    local charKey, specKey, profileName = importKey:match("^(.-)%|%|(.-)%|%|(.+)$")
    if not charKey or not specKey or not profileName then
        -- Try legacy format for backwards compatibility
        local sourceType, legacySpecKey, legacyProfileName = importKey:match("^(%a+):(.+):([^:]+)$")
        if sourceType and legacySpecKey and legacyProfileName then
            -- Legacy format - assume current character
            charKey = ns.db and ns.db.keys and ns.db.keys.char
            specKey = legacySpecKey
            profileName = legacyProfileName
        else
            PrintMsg("Invalid import key format")
            return false
        end
    end
    
    -- Get source database from the specific character's data
    local sourceSpecData
    if ns.db and ns.db.sv and ns.db.sv.char and ns.db.sv.char[charKey] then
        local charData = ns.db.sv.char[charKey]
        if charData.cdmGroups and charData.cdmGroups.specData then
            sourceSpecData = charData.cdmGroups.specData[specKey]
        end
    end
    
    if not sourceSpecData then
        PrintMsg("Source spec has no saved data (char: " .. (charKey or "nil") .. ", spec: " .. (specKey or "nil") .. ")")
        return false
    end
    
    -- Get profile data
    if not sourceSpecData.layoutProfiles or not sourceSpecData.layoutProfiles[profileName] then
        PrintMsg("Profile '" .. profileName .. "' not found in source")
        return false
    end
    
    local profileData = sourceSpecData.layoutProfiles[profileName]
    local sourceGroups
    local sourceName = "'" .. profileName .. "' profile"
    
    -- Check if profile has groupLayouts
    if profileData.groupLayouts and next(profileData.groupLayouts) then
        -- Build groups from groupLayouts (new format)
        sourceGroups = {}
        for groupName, layoutData in pairs(profileData.groupLayouts) do
            sourceGroups[groupName] = {
                enabled = true,
                position = DeepCopy(layoutData.position or { x = 0, y = 0 }),
                showBorder = layoutData.showBorder,
                showBackground = layoutData.showBackground,
                autoReflow = layoutData.autoReflow,
                dynamicLayout = layoutData.dynamicLayout,
                lockGridSize = layoutData.lockGridSize,
                containerPadding = layoutData.containerPadding,
                visibility = layoutData.visibility or "always",
                borderColor = DeepCopy(layoutData.borderColor or { r = 0.5, g = 0.5, b = 0.5, a = 1 }),
                bgColor = DeepCopy(layoutData.bgColor or { r = 0, g = 0, b = 0, a = 0.6 }),
                layout = {
                    gridRows = layoutData.gridRows or 2,
                    gridCols = layoutData.gridCols or 4,
                    iconSize = layoutData.iconSize or 36,
                    iconWidth = layoutData.iconWidth or 36,
                    iconHeight = layoutData.iconHeight or 36,
                    spacing = layoutData.spacing or 2,
                    spacingX = layoutData.spacingX,
                    spacingY = layoutData.spacingY,
                    separateSpacing = layoutData.separateSpacing,
                    alignment = layoutData.alignment,
                    horizontalGrowth = layoutData.horizontalGrowth,
                    verticalGrowth = layoutData.verticalGrowth,
                },
                grid = {},
                members = {},
            }
        end
    elseif sourceSpecData.groups and next(sourceSpecData.groups) then
        -- LEGACY FALLBACK: Use specData.groups for old profiles that didn't save groupLayouts
        sourceGroups = DeepCopy(sourceSpecData.groups)
        sourceName = "'" .. profileName .. "' profile (legacy format)"
        PrintMsg("Using legacy specData.groups for profile import")
    else
        PrintMsg("Profile '" .. profileName .. "' has no saved group layouts")
        return false
    end
    
    if not sourceGroups or not next(sourceGroups) then
        PrintMsg("No groups to import")
        return false
    end
    
    -- Need CDMGroups module for the actual import
    if not ns.CDMGroups then
        PrintMsg("CDMGroups module not available")
        return false
    end
    
    local currentSpec = ns.CDMGroups.currentSpec
    local GetSpecData = ns.CDMGroups.GetSpecData
    if not GetSpecData then
        PrintMsg("GetSpecData not available")
        return false
    end
    
    local currentSpecData = GetSpecData(currentSpec)
    if not currentSpecData then
        PrintMsg("Current spec data not available")
        return false
    end
    
    -- Step 1: Hide and clean up ALL existing group elements (including control buttons!)
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        -- Hide and orphan edge arrows first - they're parented to UIParent, not container!
        if group.edgeArrows then
            for _, arrow in pairs(group.edgeArrows) do
                if arrow then
                    arrow:ClearAllPoints()
                    arrow:Hide()
                    arrow:SetParent(nil)
                end
            end
        end
        
        -- Hide and orphan drag toggle button (parented to UIParent!)
        if group.dragToggleBtn then
            group.dragToggleBtn:ClearAllPoints()
            group.dragToggleBtn:Hide()
            group.dragToggleBtn:SetParent(nil)
        end
        
        -- Hide and orphan drag bar
        if group.dragBar then
            group.dragBar:ClearAllPoints()
            group.dragBar:Hide()
            group.dragBar:SetParent(nil)
        end
        
        -- Hide and orphan selection highlight
        if group.selectionHighlight then
            group.selectionHighlight:ClearAllPoints()
            group.selectionHighlight:Hide()
            group.selectionHighlight:SetParent(nil)
        end
        
        -- Hide and orphan container last
        if group.container then
            group.container:ClearAllPoints()
            group.container:Hide()
            group.container:SetParent(nil)
        end
        
        -- Notify EditModeContainers to clean up wrapper for this group
        if ns.EditModeContainers and ns.EditModeContainers.OnGroupDeleted then
            ns.EditModeContainers.OnGroupDeleted(groupName)
        end
    end
    
    -- Step 2: Release all icons back to CDM (this also wipes ns.CDMGroups.groups)
    if ns.CDMGroups.ReleaseAllIcons then
        ns.CDMGroups.ReleaseAllIcons()
    end
    
    if ns.CDMGroups.savedPositions then wipe(ns.CDMGroups.savedPositions) end
    if ns.CDMGroups.freeIcons then wipe(ns.CDMGroups.freeIcons) end
    
    -- Step 3: Get current profile and update groupLayouts (single source of truth)
    local activeProfileName = currentSpecData.activeProfile or "Default"
    local profile = currentSpecData.layoutProfiles and currentSpecData.layoutProfiles[activeProfileName]
    if profile then
        -- Clear savedPositions and freeIcons (these are cooldownID specific)
        profile.savedPositions = {}
        profile.freeIcons = {}
        
        -- CRITICAL: Update runtime savedPositions to point to profile's table
        ns.CDMGroups.savedPositions = profile.savedPositions
        if ns.CDMGroups.specSavedPositions and currentSpec then
            ns.CDMGroups.specSavedPositions[currentSpec] = profile.savedPositions
        end
        
        -- CRITICAL: Update profile.groupLayouts (single source of truth)
        profile.groupLayouts = {}
        for groupName, groupData in pairs(sourceGroups) do
            profile.groupLayouts[groupName] = {
                gridRows = groupData.layout and groupData.layout.gridRows or 2,
                gridCols = groupData.layout and groupData.layout.gridCols or 4,
                position = DeepCopy(groupData.position or { x = 0, y = 0 }),
                iconSize = groupData.layout and groupData.layout.iconSize or 36,
                iconWidth = groupData.layout and groupData.layout.iconWidth or 36,
                iconHeight = groupData.layout and groupData.layout.iconHeight or 36,
                spacing = groupData.layout and groupData.layout.spacing or 2,
                spacingX = groupData.layout and groupData.layout.spacingX,
                spacingY = groupData.layout and groupData.layout.spacingY,
                separateSpacing = groupData.layout and groupData.layout.separateSpacing,
                alignment = groupData.layout and groupData.layout.alignment,
                horizontalGrowth = groupData.layout and groupData.layout.horizontalGrowth,
                verticalGrowth = groupData.layout and groupData.layout.verticalGrowth,
                showBorder = groupData.showBorder,
                showBackground = groupData.showBackground,
                autoReflow = groupData.autoReflow,
                dynamicLayout = groupData.dynamicLayout,
                lockGridSize = groupData.lockGridSize,
                containerPadding = groupData.containerPadding,
                visibility = groupData.visibility or "always",
                borderColor = DeepCopy(groupData.borderColor or { r = 0.5, g = 0.5, b = 0.5, a = 1 }),
                bgColor = DeepCopy(groupData.bgColor or { r = 0, g = 0, b = 0, a = 0.6 }),
            }
        end
    end
    -- Also clear runtime tables
    currentSpecData.freeIcons = {}
    
    -- Step 4: Recreate groups from profile.groupLayouts
    for groupName, _ in pairs(profile and profile.groupLayouts or {}) do
        if ns.CDMGroups.CreateGroup then
            ns.CDMGroups.CreateGroup(groupName)
        end
    end
    
    -- Step 5: Update shortcuts
    if ns.CDMGroups.specGroups then
        ns.CDMGroups.specGroups[currentSpec] = ns.CDMGroups.groups
    end
    -- REMOVED: specSavedPositions no longer used - savedPositions points directly to specData
    if ns.CDMGroups.specFreeIcons then
        ns.CDMGroups.specFreeIcons[currentSpec] = ns.CDMGroups.freeIcons
    end
    
    -- CRITICAL: Notify FrameController that layout changed (ensures hidden frames get fixed)
    if ns.FrameController and ns.FrameController.OnLayoutChange then
        ns.FrameController.OnLayoutChange()
    end
    
    -- Step 6: Scan and auto-assign icons
    C_Timer.After(0.3, function()
        if ns.CDMGroups.ScanAllViewers then
            ns.CDMGroups.ScanAllViewers()
        end
        if ns.CDMGroups.AutoAssignNewIcons then
            ns.CDMGroups.AutoAssignNewIcons()
        end
        
        -- Layout all groups
        for _, group in pairs(ns.CDMGroups.groups or {}) do
            if group.Layout then group:Layout() end
        end
        
        -- Reflow icons for groups with Fill Gaps enabled
        for _, group in pairs(ns.CDMGroups.groups or {}) do
            if group.autoReflow and group.ReflowIcons then
                group:ReflowIcons()
            end
        end
        
        -- Update visibility
        if ns.CDMGroups.UpdateGroupVisibility then
            ns.CDMGroups.UpdateGroupVisibility()
        end
        
        -- Force CDMEnhance refresh
        if ns.CDMEnhance and ns.CDMEnhance.RefreshAllIcons then
            ns.CDMEnhance.RefreshAllIcons()
        end
    end)
    
    -- Parse source spec for display
    local classID, specIndex = specKey:match("class_(%d+)_spec_(%d+)")
    classID = tonumber(classID)
    specIndex = tonumber(specIndex)
    
    -- Get spec name
    local specName = "Spec " .. (specIndex or "?")
    if GetSpecializationInfoForClassID and classID and specIndex then
        local _, name = GetSpecializationInfoForClassID(classID, specIndex)
        if name then specName = name end
    end
    
    -- Get character name from source data
    local charName = sourceSpecData.characterName or CLASS_NAMES[classID] or "Unknown"
    
    local groupCount = 0
    if profile and profile.groupLayouts then
        for _ in pairs(profile.groupLayouts) do groupCount = groupCount + 1 end
    end
    
    PrintMsg("Imported " .. groupCount .. " groups from " .. charName .. " " .. specName .. " (" .. sourceName .. ")")
    PrintMsg("Icons will be auto-assigned to groups")
    
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UI STATE
-- ═══════════════════════════════════════════════════════════════════════════

-- Collapsible sections state
local collapsedSections = {
    arcManagerProfiles = true,  -- Start collapsed
    quickImport = true,      -- Start collapsed (formerly "Account Import")
    externalExport = true,
    statsOverview = true,
    exportOptions = true,
    importOptions = true,
}

-- Import/Export state
local uiState = {
    exportString = "",
    importString = "",
    importPreview = nil,
    importError = nil,
    -- Export options
    exportGroupLayouts = true,
    exportPositions = true,
    exportIconSettings = true,
    exportGlobalSettings = true,
    exportGroupSettings = true,
    exportProfiles = true,
    -- Import options (what to import)
    importGroupLayouts = true,
    importPositions = true,
    importIconSettings = true,
    importGlobalSettings = true,
    importGroupSettings = true,
    importProfiles = true,
    -- Quick Import selection (formerly Account Import)
    selectedAccountImport = nil,
    -- Group Templates state
    selectedGroupTemplate = nil,
    newTemplateName = "",
    newTemplateDesc = "",
    saveTemplateMode = "new",  -- "new" or "update"
    updateTemplateName = nil,
    -- Unified Load Group Layout selection
    selectedLayoutSource = nil,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- GROUP TEMPLATES SYSTEM
-- Account-wide shareable group layouts (no cooldownID data)
-- ═══════════════════════════════════════════════════════════════════════════

-- Get list of all Group Templates with metadata
function IE.GetGroupTemplates()
    local Shared = GetShared()
    if not Shared then return {} end
    
    local templatesDB = Shared.GetGroupTemplatesDB()
    if not templatesDB then return {} end
    
    local templates = {}
    for name, data in pairs(templatesDB) do
        local groupCount = 0
        if data.groups then
            for _ in pairs(data.groups) do groupCount = groupCount + 1 end
        end
        table.insert(templates, {
            name = name,
            displayName = data.displayName or name,
            description = data.description or "",
            createdBy = data.createdBy or "Unknown",
            createdAt = data.createdAt or 0,
            groupCount = groupCount,
        })
    end
    
    -- Sort by name
    table.sort(templates, function(a, b) return a.name < b.name end)
    
    return templates
end

-- Get templates formatted for dropdown
function IE.GetGroupTemplatesForDropdown()
    local templates = IE.GetGroupTemplates()
    local vals = { [""] = "|cff888888Select a template...|r" }
    
    for _, t in ipairs(templates) do
        local label = t.displayName
        if t.groupCount > 0 then
            label = label .. " |cff888888(" .. t.groupCount .. " groups)|r"
        end
        vals[t.name] = label
    end
    
    return vals
end

-- Get ALL layout sources (templates + other specs) for unified dropdown
-- Returns: values table for dropdown, and a lookup table for source info
function IE.GetAllLayoutSources()
    local vals = {}
    local sourceInfo = {}  -- Lookup table: key -> { type = "template" or "spec", ... }
    
    -- Add placeholder
    vals[""] = "|cff666666Select a source...|r"
    
    -- Add saved templates first (with [Template] suffix to distinguish)
    local templates = IE.GetGroupTemplates()
    for _, t in ipairs(templates) do
        local groupInfo = t.groupCount > 0 and (" |cff888888(" .. t.groupCount .. " groups)|r") or ""
        local key = "template:" .. t.name
        vals[key] = "|cff00ccff" .. t.displayName .. "|r" .. groupInfo .. " |cff666666[Template]|r"
        sourceInfo[key] = {
            type = "template",
            name = t.name,
            displayName = t.displayName,
            groupCount = t.groupCount,
        }
    end
    
    -- Add other specs/profiles (character - spec format)
    local layouts = IE.GetAvailableLayoutsForImport()
    for _, layout in ipairs(layouts) do
        local key = "spec:" .. layout.key
        vals[key] = layout.displayName
        sourceInfo[key] = {
            type = "spec",
            importKey = layout.key,
            displayName = layout.displayName,
            charName = layout.charName,
            specName = layout.specName,
            isArcProfile = layout.isArcProfile,
        }
    end
    
    return vals, sourceInfo
end

-- Get Arc Manager Profiles only (for the profiles dropdown)
-- Returns array of profile info objects from ALL characters on the account
function IE.GetAvailableProfiles()
    local profiles = {}
    
    local currentSpec = ns.CDMGroups and ns.CDMGroups.currentSpec
    local currentProfile = (ns.CDMGroups and ns.CDMGroups.GetActiveProfileName) and ns.CDMGroups.GetActiveProfileName() or "Default"
    local currentCharKey = ns.db and ns.db.keys and ns.db.keys.char  -- e.g., "Arcgem - Anasterian"
    
    -- Helper to add profiles from a specData table
    local function AddProfilesFromSpecData(specData, charKey, isCurrentChar)
        if not specData then return end
        
        for specKey, data in pairs(specData) do
            -- Parse spec key: "class_7_spec_2" -> classID=7, specIndex=2
            local classID, specIndex = specKey:match("class_(%d+)_spec_(%d+)")
            classID = tonumber(classID)
            specIndex = tonumber(specIndex)
            
            if classID and specIndex and data.layoutProfiles then
                -- Get spec name using API
                local specName = "Spec " .. specIndex
                if GetSpecializationInfoForClassID then
                    local _, name = GetSpecializationInfoForClassID(classID, specIndex)
                    if name then specName = name end
                end
                
                -- Get character name from the data, or parse from charKey
                local charName = data.characterName
                if not charName and charKey then
                    charName = charKey:match("^([^%-]+)") or "Unknown"
                end
                charName = charName or CLASS_NAMES[classID] or "Unknown"
                
                -- Get class color
                local classFile = CLASS_FILES[classID]
                local classColor = RAID_CLASS_COLORS and classFile and RAID_CLASS_COLORS[classFile]
                local colorHex = classColor and classColor:GenerateHexColor() or "ffffffff"
                
                -- Add all profiles with saved layouts
                for profileName, profileData in pairs(data.layoutProfiles) do
                    -- Skip if it's our current spec+profile on current character (can't load what's already loaded)
                    local isCurrentProfile = (isCurrentChar and specKey == currentSpec and profileName == currentProfile)
                    if not isCurrentProfile then
                        -- Check for groupLayouts in profile
                        local hasGroupLayouts = profileData.groupLayouts and next(profileData.groupLayouts)
                        
                        -- LEGACY FALLBACK: Also check specData.groups for old profiles that didn't save groupLayouts
                        -- This allows us to still show these profiles in the dropdown
                        local hasLegacyGroups = data.groups and next(data.groups)
                        
                        if hasGroupLayouts or hasLegacyGroups then
                            -- Use || as delimiter since charKey can contain special characters
                            local profileKey = (charKey or "current") .. "||" .. specKey .. "||" .. profileName
                            
                            -- Check if we already added this exact profile
                            local alreadyAdded = false
                            for _, existing in ipairs(profiles) do
                                if existing.key == profileKey then
                                    alreadyAdded = true
                                    break
                                end
                            end
                            
                            if not alreadyAdded then
                                -- Count groups - prefer profile.groupLayouts, fall back to specData.groups
                                local groupCount = 0
                                local groupSource = hasGroupLayouts and profileData.groupLayouts or data.groups
                                if groupSource then
                                    for _ in pairs(groupSource) do
                                        groupCount = groupCount + 1
                                    end
                                end
                                
                                -- Add marker if using legacy data
                                local legacyMarker = ""
                                if not hasGroupLayouts and hasLegacyGroups then
                                    legacyMarker = " |cffff8800[legacy]|r"
                                end
                                
                                -- Format: "ProfileName (3 groups) - CharName SpecName"
                                table.insert(profiles, {
                                    key = profileKey,
                                    specKey = specKey,
                                    profileName = profileName,
                                    charKey = charKey,
                                    isCurrentChar = isCurrentChar,
                                    isLegacy = not hasGroupLayouts and hasLegacyGroups,
                                    displayName = "|cff00ccff" .. profileName .. "|r |cff888888(" .. groupCount .. " groups)|r" .. legacyMarker .. " - |c" .. colorHex .. charName .. "|r " .. specName,
                                    charName = charName,
                                    specName = specName,
                                    classID = classID,
                                    groupCount = groupCount,
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Access ALL characters via ns.db.sv.char (raw SavedVariables table)
    -- This gives us access to all characters' data, not just the current one
    if ns.db and ns.db.sv and ns.db.sv.char then
        for charKey, charData in pairs(ns.db.sv.char) do
            -- Each character has their own cdmGroups.specData
            if type(charData) == "table" and charData.cdmGroups and charData.cdmGroups.specData then
                local isCurrentChar = (charKey == currentCharKey)
                AddProfilesFromSpecData(charData.cdmGroups.specData, charKey, isCurrentChar)
            end
        end
    end
    
    -- Sort: current character first, then by char name, then by profile name
    local _, _, myClassID = UnitClass("player")
    myClassID = myClassID or 0
    
    table.sort(profiles, function(a, b) 
        -- Current character first
        if a.isCurrentChar ~= b.isCurrentChar then
            return a.isCurrentChar
        end
        -- Same class as current character first
        local aIsMyClass = (a.classID == myClassID)
        local bIsMyClass = (b.classID == myClassID)
        if aIsMyClass ~= bIsMyClass then
            return aIsMyClass
        end
        -- Then by character name
        if a.charName ~= b.charName then
            return a.charName < b.charName
        end
        -- Then by spec
        if a.specName ~= b.specName then
            return a.specName < b.specName
        end
        -- Then by profile name
        return a.profileName < b.profileName
    end)
    
    return profiles
end

-- Cache for source info lookup (refreshed when dropdown values are built)
local cachedSourceInfo = {}

-- Save current groups as a Group Template
function IE.SaveGroupTemplate(name, description, silent)
    if not name or name == "" then
        if not silent then PrintMsg("Template name cannot be empty") end
        return false
    end
    
    local Shared = GetShared()
    if not Shared then return false end
    
    local templatesDB = Shared.GetGroupTemplatesDB()
    if not templatesDB then return false end
    
    if not ns.CDMGroups or not ns.CDMGroups.groups then
        if not silent then PrintMsg("No groups to save") end
        return false
    end
    
    -- Build group data (NO cooldownID data - just structure)
    local groups = {}
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.layout then
            groups[groupName] = {
                -- Position
                position = group.position and { x = group.position.x, y = group.position.y },
                -- Grid settings
                gridRows = group.layout.gridRows,
                gridCols = group.layout.gridCols,
                -- Layout settings
                iconSize = group.layout.iconSize,
                iconWidth = group.layout.iconWidth,
                iconHeight = group.layout.iconHeight,
                spacing = group.layout.spacing,
                spacingX = group.layout.spacingX,
                spacingY = group.layout.spacingY,
                separateSpacing = group.layout.separateSpacing,
                alignment = group.layout.alignment,
                horizontalGrowth = group.layout.horizontalGrowth,
                verticalGrowth = group.layout.verticalGrowth,
                -- Appearance
                showBorder = group.showBorder,
                showBackground = group.showBackground,
                autoReflow = group.autoReflow,
                dynamicLayout = group.dynamicLayout,
                lockGridSize = group.lockGridSize,
                containerPadding = group.containerPadding,
                borderColor = group.borderColor and DeepCopy(group.borderColor),
                bgColor = group.bgColor and DeepCopy(group.bgColor),
                -- Visibility
                visibility = group.visibility,
            }
        end
    end
    
    if not next(groups) then
        if not silent then PrintMsg("No groups to save") end
        return false
    end
    
    -- Get character info
    local playerName = UnitName("player") or "Unknown"
    local realmName = GetRealmName() or "Unknown"
    
    -- Save template
    templatesDB[name] = {
        displayName = name,
        description = description or "",
        createdBy = playerName .. "-" .. realmName,
        createdAt = time(),
        groups = groups,
    }
    
    if not silent then
        PrintMsg("Saved Group Template '" .. name .. "'")
    end
    return true
end

-- Delete a Group Template
function IE.DeleteGroupTemplate(name)
    if not name or name == "" then return false end
    
    local Shared = GetShared()
    if not Shared then return false end
    
    local templatesDB = Shared.GetGroupTemplatesDB()
    if not templatesDB then return false end
    
    if not templatesDB[name] then
        PrintMsg("Template '" .. name .. "' not found")
        return false
    end
    
    -- If this was the default, clear the default setting
    local settings = Shared.GetGroupTemplateSettings()
    if settings and settings.defaultTemplate == name then
        settings.defaultTemplate = nil
    end
    
    templatesDB[name] = nil
    PrintMsg("Deleted Group Template '" .. name .. "'")
    return true
end

-- Load a Group Template into current spec (replaces current groups)
function IE.LoadGroupTemplate(name)
    if not name or name == "" then return false end
    
    local Shared = GetShared()
    if not Shared then return false end
    
    local templatesDB = Shared.GetGroupTemplatesDB()
    if not templatesDB or not templatesDB[name] then
        PrintMsg("Template '" .. name .. "' not found")
        return false
    end
    
    local template = templatesDB[name]
    if not template.groups or not next(template.groups) then
        PrintMsg("Template has no groups")
        return false
    end
    
    if not ns.CDMGroups then
        PrintMsg("CDMGroups module not available")
        return false
    end
    
    -- Use the same import logic as ImportLayoutFromAccount
    -- Step 1: Hide and cleanup existing groups
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        -- Hide and orphan edge arrows first - they're parented to UIParent, not container!
        if group.edgeArrows then
            for _, arrow in pairs(group.edgeArrows) do
                if arrow then
                    arrow:ClearAllPoints()
                    arrow:Hide()
                    arrow:SetParent(nil)
                end
            end
        end
        
        -- Hide and orphan drag toggle button (parented to UIParent!)
        if group.dragToggleBtn then
            group.dragToggleBtn:ClearAllPoints()
            group.dragToggleBtn:Hide()
            group.dragToggleBtn:SetParent(nil)
        end
        
        -- Hide and orphan drag bar
        if group.dragBar then
            group.dragBar:ClearAllPoints()
            group.dragBar:Hide()
            group.dragBar:SetParent(nil)
        end
        
        -- Hide and orphan selection highlight
        if group.selectionHighlight then
            group.selectionHighlight:ClearAllPoints()
            group.selectionHighlight:Hide()
            group.selectionHighlight:SetParent(nil)
        end
        
        -- Hide and orphan container last
        if group.container then
            group.container:ClearAllPoints()
            group.container:Hide()
            group.container:SetParent(nil)
        end
        
        -- Notify EditModeContainers to clean up wrapper for this group
        if ns.EditModeContainers and ns.EditModeContainers.OnGroupDeleted then
            ns.EditModeContainers.OnGroupDeleted(groupName)
        end
    end
    
    -- Step 2: Release all icons back to CDM
    if ns.CDMGroups.ReleaseAllIcons then
        ns.CDMGroups.ReleaseAllIcons()
    end
    
    -- Step 3: Clear runtime data
    wipe(ns.CDMGroups.groups)
    wipe(ns.CDMGroups.savedPositions)
    wipe(ns.CDMGroups.freeIcons)
    
    -- Step 4: Get current spec data and update groups
    local specData = ns.CDMGroups.GetSpecData and ns.CDMGroups.GetSpecData()
    if specData then
        -- CRITICAL FIX: Update profile.groupLayouts (single source of truth)
        local activeProfileName = specData.activeProfile or "Default"
        local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
        if profile then
            profile.savedPositions = {}
            profile.freeIcons = {}
            
            -- CRITICAL: Update runtime savedPositions to point to profile's table
            ns.CDMGroups.savedPositions = profile.savedPositions
            local specKey = ns.CDMGroups.currentSpec
            if ns.CDMGroups.specSavedPositions and specKey then
                ns.CDMGroups.specSavedPositions[specKey] = profile.savedPositions
            end
            
            -- CRITICAL: Update profile.groupLayouts (single source of truth)
            profile.groupLayouts = {}
            for groupName, layoutData in pairs(template.groups) do
                profile.groupLayouts[groupName] = {
                    gridRows = layoutData.gridRows or 2,
                    gridCols = layoutData.gridCols or 4,
                    position = layoutData.position and DeepCopy(layoutData.position) or { x = 0, y = 0 },
                    iconSize = layoutData.iconSize or 36,
                    iconWidth = layoutData.iconWidth or 36,
                    iconHeight = layoutData.iconHeight or 36,
                    spacing = layoutData.spacing or 2,
                    spacingX = layoutData.spacingX,
                    spacingY = layoutData.spacingY,
                    separateSpacing = layoutData.separateSpacing,
                    alignment = layoutData.alignment,
                    horizontalGrowth = layoutData.horizontalGrowth,
                    verticalGrowth = layoutData.verticalGrowth,
                    showBorder = layoutData.showBorder,
                    showBackground = layoutData.showBackground,
                    autoReflow = layoutData.autoReflow,
                    dynamicLayout = layoutData.dynamicLayout,
                    lockGridSize = layoutData.lockGridSize,
                    containerPadding = layoutData.containerPadding,
                    visibility = layoutData.visibility or "always",
                    borderColor = layoutData.borderColor and DeepCopy(layoutData.borderColor) or { r = 0.5, g = 0.5, b = 0.5, a = 1 },
                    bgColor = layoutData.bgColor and DeepCopy(layoutData.bgColor) or { r = 0, g = 0, b = 0, a = 0.6 },
                }
            end
        end
        -- Clear runtime freeIcons table
        specData.freeIcons = {}
    end
    
    -- Step 5: Create group containers
    for groupName, _ in pairs(template.groups) do
        ns.CDMGroups.CreateGroup(groupName)
    end
    
    -- Step 6: Update shortcuts
    local specKey = ns.CDMGroups.currentSpec
    if specKey then
        ns.CDMGroups.specGroups = ns.CDMGroups.specGroups or {}
        ns.CDMGroups.specGroups[specKey] = ns.CDMGroups.groups
        -- REMOVED: specSavedPositions no longer used - savedPositions points directly to specData
        ns.CDMGroups.specFreeIcons = ns.CDMGroups.specFreeIcons or {}
        ns.CDMGroups.specFreeIcons[specKey] = ns.CDMGroups.freeIcons
    end
    
    -- CRITICAL: Notify FrameController that layout changed (ensures hidden frames get fixed)
    if ns.FrameController and ns.FrameController.OnLayoutChange then
        ns.FrameController.OnLayoutChange()
    end
    
    -- Step 7: Scan and auto-assign icons
    C_Timer.After(0.3, function()
        if ns.CDMGroups.ScanAllViewers then ns.CDMGroups.ScanAllViewers() end
        if ns.CDMGroups.AutoAssignNewIcons then ns.CDMGroups.AutoAssignNewIcons() end
        
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.Layout then group:Layout() end
        end
        
        -- Reflow icons for groups with Fill Gaps enabled
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.autoReflow and group.ReflowIcons then
                group:ReflowIcons()
            end
        end
        
        if ns.CDMGroups.UpdateGroupVisibility then
            ns.CDMGroups.UpdateGroupVisibility()
        end
        
        if ns.CDMEnhance and ns.CDMEnhance.RefreshAllIcons then
            ns.CDMEnhance.RefreshAllIcons()
        end
    end)
    
    -- Step 8: Store loaded template name in spec data
    if specData then
        specData.loadedTemplateName = name
        
        -- Check if this template is linked by any other spec - if so, auto-link this spec too
        if IE.IsTemplateLinkedByAnySpec and IE.IsTemplateLinkedByAnySpec(name) then
            specData.linkedTemplateName = name
            PrintMsg("Auto-linked to template '" .. name .. "' (shared with other specs)")
        end
    end
    
    PrintMsg("Loaded Group Template '" .. name .. "'")
    
    -- Notify UI to refresh immediately
    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
    if AceConfigRegistry then
        AceConfigRegistry:NotifyChange("ArcUI")
    end
    
    return true
end

-- Get template info
function IE.GetGroupTemplateInfo(name)
    if not name or name == "" then return nil end
    
    local Shared = GetShared()
    if not Shared then return nil end
    
    local templatesDB = Shared.GetGroupTemplatesDB()
    if not templatesDB or not templatesDB[name] then return nil end
    
    local data = templatesDB[name]
    local groupCount = 0
    local groupNames = {}
    if data.groups then
        for gName in pairs(data.groups) do
            groupCount = groupCount + 1
            table.insert(groupNames, gName)
        end
    end
    table.sort(groupNames)
    
    return {
        name = name,
        displayName = data.displayName or name,
        description = data.description or "",
        createdBy = data.createdBy or "Unknown",
        createdAt = data.createdAt or 0,
        groupCount = groupCount,
        groupNames = groupNames,
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LINKED TEMPLATE SYSTEM
-- Auto-save changes to a linked template
-- ═══════════════════════════════════════════════════════════════════════════

-- Debounce timer for auto-save
local autoSaveTimer = nil
local AUTO_SAVE_DELAY = 2.0  -- Wait 2 seconds after last change before saving

-- Get the currently loaded template name for this spec
function IE.GetLoadedTemplateName()
    if not ns.CDMGroups or not ns.CDMGroups.GetSpecData then return nil end
    local specData = ns.CDMGroups.GetSpecData()
    return specData and specData.loadedTemplateName or nil
end

-- Set the loaded template name (called when loading a template)
function IE.SetLoadedTemplateName(name)
    if not ns.CDMGroups or not ns.CDMGroups.GetSpecData then return end
    local specData = ns.CDMGroups.GetSpecData()
    if specData then
        specData.loadedTemplateName = name
    end
end

-- Clear the loaded template name (e.g., when groups are manually modified)
function IE.ClearLoadedTemplateName()
    IE.SetLoadedTemplateName(nil)
end

-- Get the linked template name (auto-save target)
function IE.GetLinkedTemplateName()
    if not ns.CDMGroups or not ns.CDMGroups.GetSpecData then return nil end
    local specData = ns.CDMGroups.GetSpecData()
    return specData and specData.linkedTemplateName or nil
end

-- Set the linked template (will auto-save changes to this template)
function IE.SetLinkedTemplateName(name)
    if not ns.CDMGroups or not ns.CDMGroups.GetSpecData then return end
    local specData = ns.CDMGroups.GetSpecData()
    if specData then
        specData.linkedTemplateName = name
        if name then
            PrintMsg("Linked to template '" .. name .. "' - changes will auto-save")
        else
            PrintMsg("Unlinked from template - changes will not auto-save")
        end
    end
end

-- Unlink from any template
function IE.UnlinkTemplate()
    IE.SetLinkedTemplateName(nil)
end

-- Check if a template is linked by any spec (across all characters on this account)
-- Returns true if any spec has this template linked
function IE.IsTemplateLinkedByAnySpec(templateName)
    if not templateName or templateName == "" then return false end
    
    local Shared = GetShared()
    if not Shared then return false end
    
    local db = Shared.GetCDMGroupsDB()
    if not db or not db.specData then return false end
    
    local currentSpec = ns.CDMGroups and ns.CDMGroups.currentSpec
    
    for specKey, specData in pairs(db.specData) do
        -- Skip current spec (we're asking about OTHER specs)
        if specKey ~= currentSpec and specData.linkedTemplateName == templateName then
            return true
        end
    end
    
    return false
end

-- Get all specs that have a template linked
-- Returns array of spec keys
function IE.GetSpecsLinkedToTemplate(templateName)
    if not templateName or templateName == "" then return {} end
    
    local Shared = GetShared()
    if not Shared then return {} end
    
    local db = Shared.GetCDMGroupsDB()
    if not db or not db.specData then return {} end
    
    local linkedSpecs = {}
    for specKey, specData in pairs(db.specData) do
        if specData.linkedTemplateName == templateName then
            table.insert(linkedSpecs, specKey)
        end
    end
    
    return linkedSpecs
end

-- Auto-save current groups to linked template (with debouncing)
function IE.TriggerAutoSave()
    local linkedName = IE.GetLinkedTemplateName()
    if not linkedName then return end
    
    -- Cancel existing timer if any
    if autoSaveTimer then
        autoSaveTimer:Cancel()
        autoSaveTimer = nil
    end
    
    -- Start new debounce timer
    autoSaveTimer = C_Timer.NewTimer(AUTO_SAVE_DELAY, function()
        autoSaveTimer = nil
        IE.AutoSaveToLinkedTemplate()
    end)
end

-- Actually perform the auto-save
function IE.AutoSaveToLinkedTemplate()
    local linkedName = IE.GetLinkedTemplateName()
    if not linkedName or linkedName == "" then return false end
    
    local Shared = GetShared()
    if not Shared then return false end
    
    local templatesDB = Shared.GetGroupTemplatesDB()
    if not templatesDB or not templatesDB[linkedName] then
        -- Template was deleted, unlink
        IE.UnlinkTemplate()
        return false
    end
    
    -- Get existing description
    local existingData = templatesDB[linkedName]
    local description = existingData and existingData.description or ""
    
    -- Save silently (don't print message for auto-save)
    local success = IE.SaveGroupTemplate(linkedName, description, true)  -- true = silent
    
    if success then
        -- Also update loadedTemplateName since we just saved to it
        IE.SetLoadedTemplateName(linkedName)
        
        -- Sync to other specs that have this template linked
        -- They will pick up changes on next spec switch
        -- (The template data is shared, so they'll automatically get updates)
    end
    
    return success
end

-- Check if a template exists
function IE.TemplateExists(name)
    if not name or name == "" then return false end
    
    local Shared = GetShared()
    if not Shared then return false end
    
    local templatesDB = Shared.GetGroupTemplatesDB()
    return templatesDB and templatesDB[name] ~= nil
end

-- Sync current spec to its linked template (reload groups from template)
-- Call this after spec switch if the spec has a linked template
-- Returns true if sync was performed
function IE.SyncToLinkedTemplate()
    local linkedName = IE.GetLinkedTemplateName()
    if not linkedName or linkedName == "" then return false end
    
    -- Check if template still exists
    if not IE.TemplateExists(linkedName) then
        -- Template was deleted, unlink
        IE.UnlinkTemplate()
        return false
    end
    
    -- Reload from template (this will update the groups to match the template)
    local success = IE.LoadGroupTemplate(linkedName)
    if success then
        -- Re-set the linked name (LoadGroupTemplate may have already done this via auto-link detection)
        local specData = ns.CDMGroups and ns.CDMGroups.GetSpecData and ns.CDMGroups.GetSpecData()
        if specData then
            specData.linkedTemplateName = linkedName
        end
    end
    
    return success
end

-- Check if current spec should sync to linked template
-- Returns linked template name if sync needed, nil otherwise
function IE.ShouldSyncToLinkedTemplate()
    local linkedName = IE.GetLinkedTemplateName()
    if not linkedName or linkedName == "" then return nil end
    
    if not IE.TemplateExists(linkedName) then
        return nil
    end
    
    return linkedName
end

-- Create default Group Template on first load
function IE.EnsureDefaultTemplate()
    local Shared = GetShared()
    if not Shared then return end
    
    local templatesDB = Shared.GetGroupTemplatesDB()
    if not templatesDB then return end
    
    -- Only create if no templates exist at all
    if next(templatesDB) then return end
    
    -- Create "Default" template from DEFAULT_GROUPS
    local DEFAULT_GROUPS = {
        Buffs = {
            position = { x = 0, y = 200 },
            gridRows = 2, gridCols = 4,
            iconSize = 36, iconWidth = 36, iconHeight = 36,
            spacing = 2,
            showBorder = false, showBackground = false,
            autoReflow = false, lockGridSize = false,
            containerPadding = 0,
            borderColor = { r = 0.3, g = 0.8, b = 0.3, a = 1 },
            bgColor = { r = 0, g = 0, b = 0, a = 0.6 },
            visibility = "always",
        },
        Essential = {
            position = { x = 0, y = 100 },
            gridRows = 2, gridCols = 4,
            iconSize = 36, iconWidth = 36, iconHeight = 36,
            spacing = 2,
            showBorder = false, showBackground = false,
            autoReflow = false, lockGridSize = false,
            containerPadding = 0,
            borderColor = { r = 0.8, g = 0.6, b = 0.2, a = 1 },
            bgColor = { r = 0, g = 0, b = 0, a = 0.6 },
            visibility = "always",
        },
        Utility = {
            position = { x = 0, y = 0 },
            gridRows = 2, gridCols = 4,
            iconSize = 36, iconWidth = 36, iconHeight = 36,
            spacing = 2,
            showBorder = false, showBackground = false,
            autoReflow = false, lockGridSize = false,
            containerPadding = 0,
            borderColor = { r = 0.3, g = 0.6, b = 0.9, a = 1 },
            bgColor = { r = 0, g = 0, b = 0, a = 0.6 },
            visibility = "always",
        },
    }
    
    templatesDB["Default"] = {
        displayName = "Default",
        description = "Default 3-group layout (Buffs, Essential, Utility)",
        createdBy = "System",
        createdAt = time(),
        groups = DEFAULT_GROUPS,
    }
    
    print("|cff00ccffArcUI|r: Created default Group Template")
end

-- Save another spec's layout as a Group Template
-- layoutKey format: "charKey||specKey||profileName" (e.g., "Arcgem - Anasterian||class_7_spec_2||Default")
function IE.SaveSpecAsTemplate(layoutKey, templateName)
    if not layoutKey or layoutKey == "" then return false end
    if not templateName or templateName == "" then
        PrintMsg("Template name cannot be empty")
        return false
    end
    
    local Shared = GetShared()
    if not Shared then return false end
    
    local templatesDB = Shared.GetGroupTemplatesDB()
    if not templatesDB then return false end
    
    -- Parse the layout key (new format with || delimiter)
    local charKey, specKey, profileName = layoutKey:match("^(.-)%|%|(.-)%|%|(.+)$")
    if not charKey or not specKey then
        -- Try legacy format for backwards compatibility
        local sourceType, legacySpecKey, legacyProfileName = layoutKey:match("^(%w+):([^:]+):(.+)$")
        if sourceType and legacySpecKey then
            charKey = ns.db and ns.db.keys and ns.db.keys.char
            specKey = legacySpecKey
            profileName = legacyProfileName
        else
            PrintMsg("Invalid layout key")
            return false
        end
    end
    
    -- Get the source data from the specific character
    local sourceSpecData = nil
    if ns.db and ns.db.sv and ns.db.sv.char and ns.db.sv.char[charKey] then
        local charData = ns.db.sv.char[charKey]
        if charData.cdmGroups and charData.cdmGroups.specData then
            sourceSpecData = charData.cdmGroups.specData[specKey]
        end
    end
    
    if not sourceSpecData then
        PrintMsg("Source spec data not found")
        return false
    end
    
    -- Get groups from the appropriate source
    local sourceGroups = nil
    if profileName == "Default" then
        -- Use the spec's base groups
        sourceGroups = sourceSpecData.groups
    else
        -- Use a specific profile's groupLayouts
        if sourceSpecData.layoutProfiles and sourceSpecData.layoutProfiles[profileName] then
            sourceGroups = sourceSpecData.layoutProfiles[profileName].groupLayouts
        end
    end
    
    if not sourceGroups or not next(sourceGroups) then
        PrintMsg("No groups found in source layout")
        return false
    end
    
    -- Build group data (NO cooldownID data - just structure)
    local groups = {}
    for groupName, group in pairs(sourceGroups) do
        -- Handle both runtime group format and profile groupLayouts format
        local layout = group.layout or group
        groups[groupName] = {
            -- Position
            position = group.position and { x = group.position.x, y = group.position.y },
            -- Grid settings
            gridRows = layout.gridRows or 2,
            gridCols = layout.gridCols or 4,
            -- Layout settings
            iconSize = layout.iconSize or 36,
            iconWidth = layout.iconWidth or 36,
            iconHeight = layout.iconHeight or 36,
            spacing = layout.spacing or 2,
            spacingX = layout.spacingX,
            spacingY = layout.spacingY,
            separateSpacing = layout.separateSpacing,
            alignment = layout.alignment,
            horizontalGrowth = layout.horizontalGrowth,
            verticalGrowth = layout.verticalGrowth,
            -- Appearance
            showBorder = group.showBorder,
            showBackground = group.showBackground,
            autoReflow = group.autoReflow,
            dynamicLayout = group.dynamicLayout,
            lockGridSize = group.lockGridSize,
            containerPadding = group.containerPadding,
            borderColor = group.borderColor and DeepCopy(group.borderColor),
            bgColor = group.bgColor and DeepCopy(group.bgColor),
            -- Visibility
            visibility = group.visibility or "always",
        }
    end
    
    if not next(groups) then
        PrintMsg("Failed to extract groups from source")
        return false
    end
    
    -- Get source info for metadata
    local charName = sourceSpecData.characterName or "Unknown"
    local classID = tonumber(specKey:match("class_(%d+)"))
    local specIndex = tonumber(specKey:match("spec_(%d+)"))
    local specName = "Unknown Spec"
    if classID and specIndex and GetSpecializationInfoForClassID then
        local _, name = GetSpecializationInfoForClassID(classID, specIndex)
        if name then specName = name end
    end
    
    -- Save template
    templatesDB[templateName] = {
        displayName = templateName,
        description = "Imported from " .. charName .. " - " .. specName,
        createdBy = charName,
        createdAt = time(),
        groups = groups,
    }
    
    PrintMsg("Saved template '" .. templateName .. "' from " .. charName .. " " .. specName)
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- OPTIONS TABLE FOR ACECONFIG
-- ═══════════════════════════════════════════════════════════════════════════

local function GetOptionsTable()
    local Shared = GetShared()
    
    local options = {
        type = "group",
        name = "Profiles & Import/Export",
        args = {
            -- ═══════════════════════════════════════════════════════════════════
            -- HEADER
            -- ═══════════════════════════════════════════════════════════════════
            headerDesc = {
                type = "description",
                name = "|cffffd100Manage Arc Manager Profiles and import/export settings.|r",
                fontSize = "medium",
                order = 1,
            },
            spacer1 = {
                type = "description",
                name = " ",
                order = 2,
            },
            
            -- ═══════════════════════════════════════════════════════════════════
            -- ARC MANAGER PROFILES (Per-spec profiles with talent conditions)
            -- Moved from Groups tab - full profile management
            -- ═══════════════════════════════════════════════════════════════════
            arcProfilesToggle = {
                type = "toggle",
                name = function()
                    local active = ns.CDMGroups and ns.CDMGroups.GetActiveProfileName and ns.CDMGroups.GetActiveProfileName() or "Default"
                    return "Arc Manager Profiles |cff00ff00[" .. active .. "]|r"
                end,
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 15,
                width = "full",
                get = function() return not collapsedSections.arcManagerProfiles end,
                set = function(_, v) collapsedSections.arcManagerProfiles = not v end,
            },
            arcProfilesDesc = {
                type = "description",
                name = "|cffaaaaaaPer-spec profiles with full layout snapshots. Supports talent-based auto-switching.|r",
                order = 15.1,
                width = "full",
                fontSize = "small",
                hidden = function() return collapsedSections.arcManagerProfiles end,
            },
            arcProfileSelect = {
                type = "select",
                name = "Profile",
                desc = "Select a layout profile. Profiles can store different icon arrangements.",
                order = 15.2,
                width = 1.0,
                hidden = function() return collapsedSections.arcManagerProfiles end,
                values = function()
                    local vals = {}
                    if ns.CDMGroups and ns.CDMGroups.GetProfileNames then
                        for _, name in ipairs(ns.CDMGroups.GetProfileNames()) do
                            vals[name] = name
                        end
                    else
                        vals["Default"] = "Default"
                    end
                    return vals
                end,
                get = function()
                    return ns.CDMGroups and ns.CDMGroups.GetActiveProfileName and ns.CDMGroups.GetActiveProfileName() or "Default"
                end,
                set = function(_, val)
                    if ns.CDMGroups and ns.CDMGroups.LoadProfile then
                        ns.CDMGroups.LoadProfile(val)
                    end
                end,
            },
            arcProfileNewBtn = {
                type = "execute",
                name = "|cff88ff88+ New|r",
                desc = "Create a new profile from current layout",
                order = 15.3,
                width = 0.45,
                hidden = function() return collapsedSections.arcManagerProfiles end,
                func = function()
                    StaticPopupDialogs["ARCUI_ARC_NEW_PROFILE"] = {
                        text = "Enter name for new profile:",
                        button1 = "Create",
                        button2 = "Cancel",
                        hasEditBox = true,
                        OnAccept = function(self)
                            local name = self.EditBox:GetText()
                            if name and name ~= "" then
                                if ns.CDMGroups and ns.CDMGroups.CreateProfile then
                                    ns.CDMGroups.CreateProfile(name)
                                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                                    if AceConfigRegistry then
                                        AceConfigRegistry:NotifyChange("ArcUI")
                                    end
                                end
                            end
                        end,
                        OnShow = function(self)
                            self:SetFrameStrata("FULLSCREEN_DIALOG")
                            self.EditBox:SetText("")
                            self.EditBox:SetFocus()
                        end,
                        EditBoxOnTextChanged = function(self)
                            -- Validation handled in OnAccept
                        end,
                        EditBoxOnEnterPressed = function(self)
                            local parent = self:GetParent()
                            local name = self:GetText()
                            if name and name ~= "" then
                                if ns.CDMGroups and ns.CDMGroups.CreateProfile then
                                    ns.CDMGroups.CreateProfile(name)
                                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                                    if AceConfigRegistry then
                                        AceConfigRegistry:NotifyChange("ArcUI")
                                    end
                                end
                            end
                            parent:Hide()
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("ARCUI_ARC_NEW_PROFILE")
                end,
            },
            arcProfileDeleteBtn = {
                type = "execute",
                name = "|cffff8888Delete|r",
                desc = "Delete the selected profile",
                order = 15.4,
                width = 0.45,
                hidden = function() return collapsedSections.arcManagerProfiles end,
                disabled = function()
                    local active = ns.CDMGroups and ns.CDMGroups.GetActiveProfileName and ns.CDMGroups.GetActiveProfileName() or "Default"
                    return active == "Default"
                end,
                func = function()
                    local active = ns.CDMGroups and ns.CDMGroups.GetActiveProfileName and ns.CDMGroups.GetActiveProfileName() or "Default"
                    if active == "Default" then return end
                    
                    StaticPopupDialogs["ARCUI_ARC_DELETE_PROFILE"] = {
                        text = "Delete profile '" .. active .. "'?",
                        button1 = "Delete",
                        button2 = "Cancel",
                        OnAccept = function()
                            if ns.CDMGroups and ns.CDMGroups.DeleteProfile then
                                ns.CDMGroups.DeleteProfile(active)
                                local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                                if AceConfigRegistry then
                                    AceConfigRegistry:NotifyChange("ArcUI")
                                end
                            end
                        end,
                        OnShow = function(self)
                            self:SetFrameStrata("FULLSCREEN_DIALOG")
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("ARCUI_ARC_DELETE_PROFILE")
                end,
            },
            arcProfileSaveBtn = {
                type = "execute",
                name = "Save Layout",
                desc = "Save current icon layout to the active profile",
                order = 15.5,
                width = 0.6,
                hidden = function() return collapsedSections.arcManagerProfiles end,
                func = function()
                    local active = ns.CDMGroups and ns.CDMGroups.GetActiveProfileName and ns.CDMGroups.GetActiveProfileName() or "Default"
                    if ns.CDMGroups and ns.CDMGroups.SaveCurrentToProfile then
                        ns.CDMGroups._explicitSaveRequested = true
                        ns.CDMGroups.SaveCurrentToProfile(active)
                        ns.CDMGroups._explicitSaveRequested = nil
                    end
                end,
            },
            arcProfileTalentConditionsBtn = {
                type = "execute",
                name = "Talent Conditions |cffff6666[Disabled]|r",
                desc = "Talent-based profile auto-switching is under construction",
                order = 15.6,
                width = 0.85,
                hidden = function() return true end,  -- DISABLED: Talent profile switching under construction
                func = function()
                    PrintMsg("Talent-based profile switching is currently under construction.")
                end,
            },
            arcProfileTalentConditionsSummary = {
                type = "description",
                name = "|cffff6666Talent-based auto-switching is under construction.|r",
                order = 15.7,
                fontSize = "medium",
                hidden = function() return true end,  -- DISABLED: Talent profile switching under construction
            },
            arcProfileRenameBtn = {
                type = "execute",
                name = "Rename",
                desc = "Rename the current profile",
                order = 15.8,
                width = 0.5,
                hidden = function() return collapsedSections.arcManagerProfiles end,
                disabled = function()
                    local active = ns.CDMGroups and ns.CDMGroups.GetActiveProfileName and ns.CDMGroups.GetActiveProfileName() or "Default"
                    return active == "Default"
                end,
                func = function()
                    local active = ns.CDMGroups and ns.CDMGroups.GetActiveProfileName and ns.CDMGroups.GetActiveProfileName() or "Default"
                    if active == "Default" then return end
                    
                    StaticPopupDialogs["ARCUI_ARC_RENAME_PROFILE"] = {
                        text = "Enter new name for profile '" .. active .. "':",
                        button1 = "Rename",
                        button2 = "Cancel",
                        hasEditBox = true,
                        OnAccept = function(self)
                            local newName = self.EditBox:GetText()
                            if newName and newName ~= "" then
                                if ns.CDMGroups and ns.CDMGroups.RenameProfile then
                                    local success, err = ns.CDMGroups.RenameProfile(active, newName)
                                    if not success then
                                        PrintMsg(err or "Failed to rename profile")
                                    end
                                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                                    if AceConfigRegistry then
                                        AceConfigRegistry:NotifyChange("ArcUI")
                                    end
                                end
                            end
                        end,
                        OnShow = function(self)
                            self:SetFrameStrata("FULLSCREEN_DIALOG")
                            self.EditBox:SetText(active)
                            self.EditBox:HighlightText()
                            self.EditBox:SetFocus()
                        end,
                        EditBoxOnEnterPressed = function(self)
                            local parent = self:GetParent()
                            local newName = self:GetText()
                            if newName and newName ~= "" then
                                if ns.CDMGroups and ns.CDMGroups.RenameProfile then
                                    local success, err = ns.CDMGroups.RenameProfile(active, newName)
                                    if not success then
                                        PrintMsg(err or "Failed to rename profile")
                                    end
                                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                                    if AceConfigRegistry then
                                        AceConfigRegistry:NotifyChange("ArcUI")
                                    end
                                end
                            end
                            parent:Hide()
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("ARCUI_ARC_RENAME_PROFILE")
                end,
            },
            arcProfileResetDefaultBtn = {
                type = "execute",
                name = "|cffff9900Reset Default|r",
                desc = "Reset the Default profile to factory settings (empty layout with default groups)",
                order = 15.9,
                width = 0.7,
                hidden = function() return collapsedSections.arcManagerProfiles end,
                func = function()
                    StaticPopupDialogs["ARCUI_ARC_RESET_DEFAULT"] = {
                        text = "|cffff9900Warning:|r This will reset the Default profile to factory settings.\n\nAll icon positions and settings in the Default profile will be lost.\n\nAre you sure?",
                        button1 = "Reset",
                        button2 = "Cancel",
                        OnAccept = function()
                            if ns.CDMGroups and ns.CDMGroups.ResetDefaultProfile then
                                ns.CDMGroups.ResetDefaultProfile()
                                
                                -- Show reload prompt
                                StaticPopupDialogs["ARCUI_ARC_RESET_RELOAD"] = {
                                    text = "Default profile has been reset.\n\nPlease reload your UI to complete the reset.",
                                    button1 = "Reload Now",
                                    button2 = "Later",
                                    OnAccept = function()
                                        ReloadUI()
                                    end,
                                    OnShow = function(self)
                                        self:SetFrameStrata("FULLSCREEN_DIALOG")
                                    end,
                                    timeout = 0,
                                    whileDead = true,
                                    hideOnEscape = true,
                                    preferredIndex = 3,
                                }
                                StaticPopup_Show("ARCUI_ARC_RESET_RELOAD")
                            end
                        end,
                        OnShow = function(self)
                            self:SetFrameStrata("FULLSCREEN_DIALOG")
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("ARCUI_ARC_RESET_DEFAULT")
                end,
            },
            
            -- ═══════════════════════════════════════════════════════════════════
            -- EXTERNAL EXPORT/IMPORT (Collapsible)
            -- ═══════════════════════════════════════════════════════════════════
            externalExportToggle = {
                type = "toggle",
                name = "External Export/Import",
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 20,
                width = "full",
                get = function() return not collapsedSections.externalExport end,
                set = function(_, v) collapsedSections.externalExport = not v end,
            },
            externalExportDesc = {
                type = "description",
                name = "|cffaaaaaaShare settings with others via export strings or backup/restore your configuration.|r",
                order = 21,
                width = "full",
                fontSize = "small",
                hidden = function() return collapsedSections.externalExport end,
            },
            
            -- CURRENT SETTINGS STATS (Collapsible, inside External)
            statsToggle = {
                type = "toggle",
                name = "|cffffd100Current Settings Overview|r",
                desc = "Expand to see what's currently configured",
                dialogControl = "CollapsibleHeader",
                order = 30,
                width = "full",
                hidden = function() return collapsedSections.externalExport end,
                get = function() return not collapsedSections.statsOverview end,
                set = function(_, v) collapsedSections.statsOverview = not v end,
            },
            statsInfo = {
                type = "description",
                name = function()
                    local stats = IE.GetExportStats()
                    local specName = "Unknown"
                    if ns.CDMGroups and ns.CDMGroups.currentSpec then
                        -- Try to get readable spec name
                        local specIndex = GetSpecialization()
                        if specIndex and GetSpecializationInfo then
                            local _, name = GetSpecializationInfo(specIndex)
                            if name then specName = name end
                        else
                            specName = ns.CDMGroups.currentSpec
                        end
                    end
                    
                    local lines = {
                        "|cff888888Current Spec:|r |cffffffff" .. specName .. "|r",
                        "",
                        "|cff00ccffGroups:|r          |cffffffff" .. stats.groups .. "|r",
                        "|cff00ccffIcon Positions:|r  |cffffffff" .. stats.savedPositions .. "|r",
                        "|cff00ccffFree Icons:|r      |cffffffff" .. stats.freeIcons .. "|r",
                        "|cff00ccffLayout Profiles:|r |cffffffff" .. stats.layoutProfiles .. "|r",
                        "|cff00ccffIcon Settings:|r   |cffffffff" .. stats.iconSettings .. "|r",
                        "",
                        "|cff888888Global Aura Defaults:|r " .. (stats.hasGlobalAura and "|cff00ff00Yes|r" or "|cff666666No|r"),
                        "|cff888888Global CD Defaults:|r   " .. (stats.hasGlobalCooldown and "|cff00ff00Yes|r" or "|cff666666No|r"),
                        "|cff888888Group Settings:|r       " .. (stats.hasGroupSettings and "|cff00ff00Yes|r" or "|cff666666No|r"),
                    }
                    return table.concat(lines, "\n")
                end,
                fontSize = "medium",
                order = 31,
                hidden = function() return collapsedSections.externalExport or collapsedSections.statsOverview end,
            },
            
            -- EXPORT SECTION
            exportHeader = {
                type = "header",
                name = "Export Settings",
                order = 40,
                hidden = function() return collapsedSections.externalExport end,
            },
            exportOptionsToggle = {
                type = "toggle",
                name = "|cffffd100Export Options|r",
                desc = "Expand to choose what to include in the export",
                dialogControl = "CollapsibleHeader",
                order = 41,
                width = "full",
                hidden = function() return collapsedSections.externalExport end,
                get = function() return not collapsedSections.exportOptions end,
                set = function(_, v) collapsedSections.exportOptions = not v end,
            },
            -- Export option checkboxes
            exportGroupLayouts = {
                type = "toggle",
                name = "Group Layouts",
                desc = "Include group structure (positions, sizes, appearance settings)",
                order = 42,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.exportOptions end,
                get = function() return uiState.exportGroupLayouts end,
                set = function(_, v) uiState.exportGroupLayouts = v end,
            },
            exportPositions = {
                type = "toggle",
                name = "Icon Positions",
                desc = "Include which icons are assigned to which groups and slots",
                order = 43,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.exportOptions end,
                get = function() return uiState.exportPositions end,
                set = function(_, v) uiState.exportPositions = v end,
            },
            exportIconSettings = {
                type = "toggle",
                name = "Icon Settings",
                desc = "Include per-icon visual customizations (borders, text, glows, etc.)",
                order = 44,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.exportOptions end,
                get = function() return uiState.exportIconSettings end,
                set = function(_, v) uiState.exportIconSettings = v end,
            },
            exportGlobalSettings = {
                type = "toggle",
                name = "Global Defaults",
                desc = "Include global aura and cooldown default settings",
                order = 45,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.exportOptions end,
                get = function() return uiState.exportGlobalSettings end,
                set = function(_, v) uiState.exportGlobalSettings = v end,
            },
            exportGroupSettings = {
                type = "toggle",
                name = "Group Settings",
                desc = "Include spacing, scale, and direction settings per viewer type",
                order = 46,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.exportOptions end,
                get = function() return uiState.exportGroupSettings end,
                set = function(_, v) uiState.exportGroupSettings = v end,
            },
            exportProfiles = {
                type = "toggle",
                name = "Layout Profiles",
                desc = "Include layout profiles with talent conditions",
                order = 47,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.exportOptions end,
                get = function() return uiState.exportProfiles end,
                set = function(_, v) uiState.exportProfiles = v end,
            },
            exportSpacer = {
                type = "description",
                name = "",
                order = 48,
                hidden = function() return collapsedSections.externalExport or collapsedSections.exportOptions end,
            },
            -- Export button
            exportButton = {
                type = "execute",
                name = "|TInterface\\BUTTONS\\UI-GuildButton-PublicNote-Up:16|t Generate Export String",
                desc = "Generate export string with selected options",
                order = 50,
                width = 1.3,
                hidden = function() return collapsedSections.externalExport end,
                func = function()
                    local exportStr, err = IE.Export({
                        includePositions = uiState.exportPositions,
                        includeIconSettings = uiState.exportIconSettings,
                        includeGlobalSettings = uiState.exportGlobalSettings,
                        includeGroupSettings = uiState.exportGroupSettings,
                    })
                    if exportStr then
                        uiState.exportString = exportStr
                        PrintMsg("|cff00ff00Export generated!|r Copy the string below.")
                    else
                        uiState.exportString = "ERROR: " .. (err or "Unknown error")
                        PrintMsg("|cffff0000Export failed:|r " .. (err or "Unknown error"))
                    end
                end,
            },
            exportCopyBtn = {
                type = "execute",
                name = "|TInterface\\BUTTONS\\UI-GuildButton-MOTD-Up:16|t Copy to Clipboard",
                desc = "Select the export string for easy copying",
                order = 51,
                width = 1.0,
                hidden = function() return collapsedSections.externalExport end,
                disabled = function() return uiState.exportString == "" end,
                func = function()
                    -- This will focus the editbox, user can then Ctrl+C
                    PrintMsg("Click in the export box below and press |cffffd100Ctrl+A|r then |cffffd100Ctrl+C|r to copy.")
                end,
            },
            exportString = {
                type = "input",
                name = "Export String",
                desc = "Copy this string to share your settings",
                order = 52,
                multiline = 6,
                width = "full",
                hidden = function() return collapsedSections.externalExport end,
                get = function() return uiState.exportString end,
                set = function(_, v) uiState.exportString = v end,
            },
            
            -- IMPORT SECTION
            importHeader = {
                type = "header",
                name = "Import Settings",
                order = 60,
                hidden = function() return collapsedSections.externalExport end,
            },
            importString = {
                type = "input",
                name = "Paste Export String Here",
                desc = "Paste an exported settings string to import",
                order = 61,
                multiline = 6,
                width = "full",
                hidden = function() return collapsedSections.externalExport end,
                get = function() return uiState.importString end,
                set = function(_, v)
                    uiState.importString = v
                    -- Auto-preview on paste
                    if v and v ~= "" then
                        local data, err = IE.ParseImportString(v)
                        if data then
                            uiState.importPreview = IE.GetImportStats(data)
                            uiState.importError = nil
                        else
                            uiState.importPreview = nil
                            uiState.importError = err
                        end
                    else
                        uiState.importPreview = nil
                        uiState.importError = nil
                    end
                end,
            },
            -- Preview info
            importPreviewInfo = {
                type = "description",
                name = function()
                    if uiState.importError then
                        return "|cffff0000Error:|r " .. uiState.importError
                    end
                    if not uiState.importPreview then
                        return "|cff888888Paste an export string above to see preview|r"
                    end
                    local p = uiState.importPreview
                    local timeStr = p.timestamp and date("%Y-%m-%d %H:%M", p.timestamp) or "Unknown"
                    local lines = {
                        "|cff00ff00Valid export detected!|r",
                        "",
                        "|cff888888From:|r " .. (p.exportedBy or "?") .. " - " .. (p.realm or "?"),
                        "|cff888888Date:|r " .. timeStr,
                        "|cff888888Version:|r " .. (p.version or "?"),
                        "",
                        "|cff00ccffContents:|r",
                        "  Groups: |cffffffff" .. p.groups .. "|r",
                        "  Icon Positions: |cffffffff" .. p.savedPositions .. "|r",
                        "  Free Icons: |cffffffff" .. p.freeIcons .. "|r",
                        "  Layout Profiles: |cffffffff" .. p.layoutProfiles .. "|r",
                        "  Icon Settings: |cffffffff" .. p.iconSettings .. "|r",
                        "  Global Defaults: " .. (p.hasGlobalAuraSettings and "|cff00ff00Aura|r " or "") .. (p.hasGlobalCooldownSettings and "|cff00ff00Cooldown|r" or ""),
                        "  Group Settings: " .. (p.hasGroupSettings and "|cff00ff00Yes|r" or "|cff666666No|r"),
                    }
                    return table.concat(lines, "\n")
                end,
                fontSize = "medium",
                order = 62,
                hidden = function() return collapsedSections.externalExport end,
            },
            -- Import options
            importOptionsToggle = {
                type = "toggle",
                name = "|cffffd100Import Options|r",
                desc = "Expand to choose what to import and how",
                dialogControl = "CollapsibleHeader",
                order = 63,
                width = "full",
                hidden = function() return collapsedSections.externalExport end,
                get = function() return not collapsedSections.importOptions end,
                set = function(_, v) collapsedSections.importOptions = not v end,
            },
            importGroupLayouts = {
                type = "toggle",
                name = "Group Layouts",
                desc = "Import group structure",
                order = 65,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.importOptions end,
                get = function() return uiState.importGroupLayouts end,
                set = function(_, v) uiState.importGroupLayouts = v end,
            },
            importPositions = {
                type = "toggle",
                name = "Icon Positions",
                desc = "Import icon assignments",
                order = 66,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.importOptions end,
                get = function() return uiState.importPositions end,
                set = function(_, v) uiState.importPositions = v end,
            },
            importIconSettings = {
                type = "toggle",
                name = "Icon Settings",
                desc = "Import per-icon visual settings",
                order = 67,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.importOptions end,
                get = function() return uiState.importIconSettings end,
                set = function(_, v) uiState.importIconSettings = v end,
            },
            importGlobalSettings = {
                type = "toggle",
                name = "Global Defaults",
                desc = "Import global aura/cooldown defaults",
                order = 68,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.importOptions end,
                get = function() return uiState.importGlobalSettings end,
                set = function(_, v) uiState.importGlobalSettings = v end,
            },
            importGroupSettings = {
                type = "toggle",
                name = "Group Settings",
                desc = "Import spacing/scale/direction settings",
                order = 69,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.importOptions end,
                get = function() return uiState.importGroupSettings end,
                set = function(_, v) uiState.importGroupSettings = v end,
            },
            importProfiles = {
                type = "toggle",
                name = "Layout Profiles",
                desc = "Import layout profiles",
                order = 70,
                width = 0.7,
                hidden = function() return collapsedSections.externalExport or collapsedSections.importOptions end,
                get = function() return uiState.importProfiles end,
                set = function(_, v) uiState.importProfiles = v end,
            },
            importSpacer = {
                type = "description",
                name = "",
                order = 71,
                hidden = function() return collapsedSections.externalExport end,
            },
            -- Import button
            importButton = {
                type = "execute",
                name = "|TInterface\\BUTTONS\\UI-GuildButton-PublicNote-Disabled:16|t Import Settings",
                desc = "Apply the imported settings",
                order = 72,
                width = 1.0,
                hidden = function() return collapsedSections.externalExport end,
                disabled = function() return uiState.importPreview == nil end,
                confirm = function()
                    return "This will REPLACE your current CDM settings with the imported ones.\n\nAre you sure?"
                end,
                func = function()
                    local success, result = IE.Import(uiState.importString, {
                        mergeMode = "replace",  -- Always replace
                        importGroupLayouts = uiState.importGroupLayouts,
                        importPositions = uiState.importPositions,
                        importIconSettings = uiState.importIconSettings,
                        importGlobalSettings = uiState.importGlobalSettings,
                        importGroupSettings = uiState.importGroupSettings,
                        importProfiles = uiState.importProfiles,
                    })
                    
                    if success then
                        PrintMsg("|cff00ff00Import successful!|r")
                        if type(result) == "table" then
                            PrintMsg(string.format("Imported: %d groups, %d positions, %d icon settings",
                                result.groups or 0, result.savedPositions or 0, result.iconSettings or 0))
                        end
                        -- Clear import state
                        uiState.importString = ""
                        uiState.importPreview = nil
                        uiState.importError = nil
                        -- Show reload dialog
                        StaticPopup_Show("ARCUI_RELOAD_AFTER_IMPORT")
                    else
                        PrintMsg("|cffff0000Import failed:|r " .. (result or "Unknown error"))
                    end
                end,
            },
            clearImportBtn = {
                type = "execute",
                name = "Clear",
                desc = "Clear the import field",
                order = 73,
                width = 0.5,
                hidden = function() return collapsedSections.externalExport end,
                func = function()
                    uiState.importString = ""
                    uiState.importPreview = nil
                    uiState.importError = nil
                end,
            },
            
            -- HELP SECTION
            helpHeader = {
                type = "header",
                name = "Help",
                order = 80,
                hidden = function() return collapsedSections.externalExport end,
            },
            helpText = {
                type = "description",
                name = "|cffffd100What gets exported:|r\n\n" ..
                       "- |cff00ccffGroup Layouts|r - Container positions, sizes, rows/columns, borders, backgrounds\n" ..
                       "- |cff00ccffIcon Positions|r - Which icons are in which groups and their grid positions\n" ..
                       "- |cff00ccffIcon Settings|r - Per-icon borders, text styles, glows, state visuals\n" ..
                       "- |cff00ccffGlobal Defaults|r - Default settings for all auras/cooldowns\n" ..
                       "- |cff00ccffGroup Settings|r - Spacing, scale, direction per viewer type\n" ..
                       "- |cff00ccffGlobal Icon Settings|r - Tooltip visibility, click-through\n" ..
                       "- |cff00ccffLayout Profiles|r - Saved profiles with talent conditions\n\n" ..
                       "|cffffd100Note:|r Icon positions use internal cooldownIDs which are spec-specific.\n" ..
                       "Importing positions from a different spec may not work correctly.",
                fontSize = "medium",
                order = 81,
                hidden = function() return collapsedSections.externalExport end,
            },
        },
    }
    
    return options
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORT FUNCTION FOR OPTIONS INTEGRATION
-- ═══════════════════════════════════════════════════════════════════════════

-- This is called by ArcUI_Options.lua to get the options table
function ns.GetCDMImportExportOptionsTable()
    return GetOptionsTable()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RELOAD CONFIRMATION POPUP
-- ═══════════════════════════════════════════════════════════════════════════

StaticPopupDialogs["ARCUI_RELOAD_AFTER_IMPORT"] = {
    text = "|cff00ccffArcUI|r CDM settings imported.\n\nReload UI to apply all changes?",
    button1 = "Reload Now",
    button2 = "Later",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SLASH COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

SLASH_ARCUICDMEXPORT1 = "/arccdmexport"
SLASH_ARCUICDMEXPORT2 = "/cdmexport"
SlashCmdList["ARCUICDMEXPORT"] = function()
    -- Open options to Import/Export tab
    if ns.API and ns.API.OpenOptions then
        ns.API.OpenOptions()
        -- Navigate to the import/export panel
        C_Timer.After(0.1, function()
            local ACD = LibStub("AceConfigDialog-3.0", true)
            if ACD then
                ACD:SelectGroup("ArcUI", "icons", "importExport")
            end
        end)
    else
        PrintMsg("Options not available yet.")
    end
end

SLASH_ARCUICDMIMPORT1 = "/arccdmimport"
SLASH_ARCUICDMIMPORT2 = "/cdmimport"
SlashCmdList["ARCUICDMIMPORT"] = function()
    -- Same as export, opens options to Import/Export tab
    if ns.API and ns.API.OpenOptions then
        ns.API.OpenOptions()
        C_Timer.After(0.1, function()
            local ACD = LibStub("AceConfigDialog-3.0", true)
            if ACD then
                ACD:SelectGroup("ArcUI", "icons", "importExport")
            end
        end)
    else
        PrintMsg("Options not available yet.")
    end
end

-- Debug command to dump raw export data
SLASH_ARCUICDMDEBUGEXPORT1 = "/cdmdebug"
SlashCmdList["ARCUICDMDEBUGEXPORT"] = function(msg)
    local Shared = GetShared()
    PrintMsg("=== CDM Export Debug ===")
    
    if not Shared then
        PrintMsg("|cffff0000ERROR: CDMShared not available!|r")
        return
    end
    
    -- Get current spec data
    local currentSpec = ns.CDMGroups and ns.CDMGroups.currentSpec
    PrintMsg("Current spec: " .. tostring(currentSpec))
    
    local cdmGroupsDB = Shared.GetCDMGroupsDB()
    if not cdmGroupsDB then
        PrintMsg("|cffff0000CDMGroups DB not available|r")
        return
    end
    
    PrintMsg("char.cdmGroups exists: " .. tostring(cdmGroupsDB ~= nil))
    PrintMsg("specData exists: " .. tostring(cdmGroupsDB.specData ~= nil))
    
    if currentSpec and cdmGroupsDB.specData and cdmGroupsDB.specData[currentSpec] then
        local specData = cdmGroupsDB.specData[currentSpec]
        PrintMsg("specData[" .. currentSpec .. "] contents:")
        
        local groupCount = 0
        if specData.groups then
            for _ in pairs(specData.groups) do groupCount = groupCount + 1 end
        end
        PrintMsg("  groups: " .. groupCount)
        
        local posCount = 0
        if specData.savedPositions then
            for _ in pairs(specData.savedPositions) do posCount = posCount + 1 end
        end
        PrintMsg("  savedPositions: " .. posCount)
        
        local freeCount = 0
        if specData.freeIcons then
            for _ in pairs(specData.freeIcons) do freeCount = freeCount + 1 end
        end
        PrintMsg("  freeIcons: " .. freeCount)
        
        local iconCount = 0
        if specData.iconSettings then
            for _ in pairs(specData.iconSettings) do iconCount = iconCount + 1 end
        end
        PrintMsg("  iconSettings: " .. iconCount)
        
        PrintMsg("  groupSettings exists: " .. tostring(specData.groupSettings ~= nil))
        
        -- Show first few iconSettings keys
        if specData.iconSettings and iconCount > 0 then
            local count = 0
            PrintMsg("  First 5 iconSettings keys:")
            for k, _ in pairs(specData.iconSettings) do
                count = count + 1
                if count <= 5 then
                    PrintMsg("    - " .. tostring(k))
                end
            end
        end
    else
        PrintMsg("|cffff0000specData[" .. tostring(currentSpec) .. "] is nil!|r")
    end
    
    -- Test actual export
    PrintMsg("")
    PrintMsg("Testing BuildExportData()...")
    local exportData = BuildExportData({})
    if exportData and exportData.cdmGroups then
        local iconCount = 0
        if exportData.cdmGroups.iconSettings then
            for _ in pairs(exportData.cdmGroups.iconSettings) do iconCount = iconCount + 1 end
        end
        PrintMsg("Export would include " .. iconCount .. " iconSettings")
    else
        PrintMsg("|cffff0000Export data or cdmGroups is nil!|r")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- END OF MODULE
-- ═══════════════════════════════════════════════════════════════════════════