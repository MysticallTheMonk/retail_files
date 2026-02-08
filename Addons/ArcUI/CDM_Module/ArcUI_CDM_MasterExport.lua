-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI CDM Master Export Module
-- Global export/import of CDM icon profiles across all characters and specs
-- Scans ArcUIDB.char directly — no snapshot copies needed
-- Users cherry-pick which Arc Manager profiles to include (like bars export)
-- Import auto-routes profiles to the correct spec with rename-on-conflict
-- ═══════════════════════════════════════════════════════════════════════════

local ADDON_NAME, ns = ...

ns.CDMMasterExport = ns.CDMMasterExport or {}
local ME = ns.CDMMasterExport

-- ═══════════════════════════════════════════════════════════════════════════
-- CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════════

local EXPORT_VERSION = 1
local EXPORT_PREFIX = "ARCMASTER"
local MSG_PREFIX = "|cff00ccffArcUI|r: "

-- ═══════════════════════════════════════════════════════════════════════════
-- DEPENDENCIES (lazy-loaded)
-- ═══════════════════════════════════════════════════════════════════════════

local AceSerializer
local LibDeflate

local function GetLibs()
    if not AceSerializer then
        AceSerializer = LibStub and LibStub("AceSerializer-3.0", true)
    end
    if not LibDeflate then
        LibDeflate = LibStub and LibStub("LibDeflate", true)
    end
    return AceSerializer, LibDeflate
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CLASS / SPEC DISPLAY HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local CLASS_INFO = {
    [1]  = { name = "Warrior",       token = "WARRIOR",      color = "ffc79c6e",
             specs = { "Arms", "Fury", "Protection" } },
    [2]  = { name = "Paladin",       token = "PALADIN",      color = "fff58cba",
             specs = { "Holy", "Protection", "Retribution" } },
    [3]  = { name = "Hunter",        token = "HUNTER",       color = "ffabd473",
             specs = { "Beast Mastery", "Marksmanship", "Survival" } },
    [4]  = { name = "Rogue",         token = "ROGUE",        color = "fffff569",
             specs = { "Assassination", "Outlaw", "Subtlety" } },
    [5]  = { name = "Priest",        token = "PRIEST",       color = "ffffffff",
             specs = { "Discipline", "Holy", "Shadow" } },
    [6]  = { name = "Death Knight",  token = "DEATHKNIGHT",  color = "ffc41f3b",
             specs = { "Blood", "Frost", "Unholy" } },
    [7]  = { name = "Shaman",        token = "SHAMAN",       color = "ff0070de",
             specs = { "Elemental", "Enhancement", "Restoration" } },
    [8]  = { name = "Mage",          token = "MAGE",         color = "ff69ccf0",
             specs = { "Arcane", "Fire", "Frost" } },
    [9]  = { name = "Warlock",       token = "WARLOCK",      color = "ff9482c9",
             specs = { "Affliction", "Demonology", "Destruction" } },
    [10] = { name = "Monk",          token = "MONK",         color = "ff00ff96",
             specs = { "Brewmaster", "Mistweaver", "Windwalker" } },
    [11] = { name = "Druid",         token = "DRUID",        color = "ffff7d0a",
             specs = { "Balance", "Feral", "Guardian", "Restoration" } },
    [12] = { name = "Demon Hunter",  token = "DEMONHUNTER",  color = "ffa330c9",
             specs = { "Havoc", "Vengeance" } },
    [13] = { name = "Evoker",        token = "EVOKER",       color = "ff33937f",
             specs = { "Devastation", "Preservation", "Augmentation" } },
}

-- Get spec name from hardcoded table (works for ALL classes, not just current)
local function GetSpecName(classID, specIndex)
    local classInfo = CLASS_INFO[classID]
    if classInfo and classInfo.specs and classInfo.specs[specIndex] then
        return classInfo.specs[specIndex]
    end
    return "Spec " .. (specIndex or "?")
end

-- Parse "class_7_spec_2" → classID=7, specIndex=2
local function ParseSpecKey(specKey)
    if not specKey then return nil, nil end
    local classID, specIndex = specKey:match("^class_(%d+)_spec_(%d+)$")
    return tonumber(classID), tonumber(specIndex)
end

-- Colored display name: "|cff0070deShaman|r - Enhancement"
local function GetSpecDisplayName(specKey, fallbackSpecName)
    local classID, specIndex = ParseSpecKey(specKey)
    if not classID then return specKey end
    
    local classInfo = CLASS_INFO[classID]
    local className = classInfo and classInfo.name or ("Class " .. classID)
    local classColor = classInfo and classInfo.color or "ffffffff"
    -- Always prefer hardcoded spec name, fallback to provided name
    local specName = GetSpecName(classID, specIndex)
    if specName:find("^Spec ") and fallbackSpecName then
        specName = fallbackSpecName  -- Only use fallback if hardcoded wasn't found
    end
    
    return string.format("|c%s%s|r - %s", classColor, className, specName)
end

-- Get short character name (strip realm)
local function GetCharName(charKey)
    return charKey:match("^(.-)%s*%-") or charKey
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════════════════════

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SCAN ALL CHARACTERS' PROFILES
-- Reads ArcUIDB.char directly to find every Arc Manager profile
-- across all characters and specs on this account
-- ═══════════════════════════════════════════════════════════════════════════

function ME.ScanAllProfiles()
    -- Use ns.db.sv.char (AceDB's internal reference to raw SavedVariables)
    -- This is the same data source the working Arc Manager Profiles dropdown uses
    local svChar = ns.db and ns.db.sv and ns.db.sv.char
    if not svChar then
        -- Fallback to global if AceDB not initialized yet
        svChar = ArcUIDB and ArcUIDB.char
    end
    if not svChar then return {} end
    
    local results = {}
    
    for charKey, charData in pairs(svChar) do
        if type(charData) == "table" and charData.cdmGroups and charData.cdmGroups.specData then
            for specKey, specData in pairs(charData.cdmGroups.specData) do
                if type(specData) == "table" and specData.layoutProfiles then
                    local classID, specIndex = ParseSpecKey(specKey)
                    
                    -- Get spec name: prefer WoW API (works for all classes), fallback to hardcoded
                    local specName = GetSpecName(classID, specIndex)
                    if GetSpecializationInfoForClassID and classID and specIndex then
                        local _, apiName = GetSpecializationInfoForClassID(classID, specIndex)
                        if apiName then specName = apiName end
                    end
                    
                    for profileName, profileData in pairs(specData.layoutProfiles) do
                        if type(profileData) == "table" then
                            local uniqueKey = charKey .. "|" .. specKey .. "|" .. profileName
                            
                            -- Count data in this profile for display
                            local posCount = 0
                            local iconSettingsCount = 0
                            if profileData.savedPositions then
                                for _ in pairs(profileData.savedPositions) do posCount = posCount + 1 end
                            end
                            if profileData.iconSettings then
                                for _ in pairs(profileData.iconSettings) do iconSettingsCount = iconSettingsCount + 1 end
                            end
                        
                        table.insert(results, {
                            charKey = charKey,
                            specKey = specKey,
                            classID = classID or 0,
                            specIndex = specIndex or 0,
                            specName = specName,
                            profileName = profileName,
                            profileData = profileData,
                            uniqueKey = uniqueKey,
                            posCount = posCount,
                            iconSettingsCount = iconSettingsCount,
                            groupSettings = specData.groupSettings,
                            globalIconSettings = {
                                disableTooltips = charData.cdmGroups.disableTooltips,
                                clickThrough = charData.cdmGroups.clickThrough,
                            },
                        })
                        end -- if type(profileData) == "table"
                    end
                end
            end
        end
    end
    
    -- Sort: charKey → specIndex → profileName (group by character)
    table.sort(results, function(a, b)
        if a.charKey ~= b.charKey then return a.charKey < b.charKey end
        if a.specIndex ~= b.specIndex then return a.specIndex < b.specIndex end
        return a.profileName < b.profileName
    end)
    
    return results
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORT
-- ═══════════════════════════════════════════════════════════════════════════

function ME.Export(selectedKeys)
    local Serializer, Deflate = GetLibs()
    if not Serializer then return nil, "AceSerializer-3.0 not available" end
    if not Deflate then return nil, "LibDeflate not available" end
    
    local allProfiles = ME.ScanAllProfiles()
    
    local exportPayload = {
        version = EXPORT_VERSION,
        prefix = EXPORT_PREFIX,
        timestamp = time(),
        exportedBy = UnitName("player") or "Unknown",
        realm = GetRealmName() or "Unknown",
        specs = {},
    }
    
    local totalProfiles = 0
    
    for _, entry in ipairs(allProfiles) do
        if selectedKeys[entry.uniqueKey] then
            local specKey = entry.specKey
            
            if not exportPayload.specs[specKey] then
                exportPayload.specs[specKey] = {
                    specName = entry.specName,
                    classID = entry.classID,
                    specIndex = entry.specIndex,
                    sourceChar = entry.charKey,
                    profiles = {},
                    groupSettings = entry.groupSettings and DeepCopy(entry.groupSettings) or nil,
                    globalIconSettings = entry.globalIconSettings and DeepCopy(entry.globalIconSettings) or nil,
                }
            end
            
            exportPayload.specs[specKey].profiles[entry.profileName] = DeepCopy(entry.profileData)
            totalProfiles = totalProfiles + 1
        end
    end
    
    if totalProfiles == 0 then
        return nil, "No profiles selected for export"
    end
    
    -- Include cdmEnhance global defaults
    if ns.db and ns.db.profile and ns.db.profile.cdmEnhance then
        local enhance = ns.db.profile.cdmEnhance
        exportPayload.cdmEnhance = {
            globalAuraSettings = enhance.globalAuraSettings and DeepCopy(enhance.globalAuraSettings) or nil,
            globalCooldownSettings = enhance.globalCooldownSettings and DeepCopy(enhance.globalCooldownSettings) or nil,
            globalApplyScale = enhance.globalApplyScale,
            globalApplyHideShadow = enhance.globalApplyHideShadow,
        }
    end
    
    exportPayload.profileCount = totalProfiles
    local specCount = 0
    for _ in pairs(exportPayload.specs) do specCount = specCount + 1 end
    exportPayload.specCount = specCount
    
    -- Serialize → Compress → Encode
    local serialized = Serializer:Serialize(exportPayload)
    if not serialized then return nil, "Serialization failed" end
    
    local compressed = Deflate:CompressDeflate(serialized)
    if not compressed then return nil, "Compression failed" end
    
    local encoded = Deflate:EncodeForPrint(compressed)
    if not encoded then return nil, "Encoding failed" end
    
    return encoded, nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- IMPORT
-- ═══════════════════════════════════════════════════════════════════════════

function ME.ParseImportString(importString)
    if not importString or importString == "" then
        return nil, "Empty import string"
    end
    
    local Serializer, Deflate = GetLibs()
    if not Serializer then return nil, "AceSerializer-3.0 not available" end
    if not Deflate then return nil, "LibDeflate not available" end
    
    importString = importString:gsub("%s+", "")
    
    local decoded = Deflate:DecodeForPrint(importString)
    if not decoded then return nil, "Invalid string (decode failed)" end
    
    local decompressed = Deflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "Invalid string (decompress failed)" end
    
    local success, data = Serializer:Deserialize(decompressed)
    if not success or type(data) ~= "table" then
        return nil, "Invalid string (deserialize failed)"
    end
    
    if data.prefix ~= EXPORT_PREFIX then
        return nil, "Wrong format — this is not an ArcUI Master Export string"
    end
    if not data.version then return nil, "Missing version" end
    if data.version > EXPORT_VERSION then
        return nil, "Export version " .. data.version .. " is newer than supported (" .. EXPORT_VERSION .. ")"
    end
    if not data.specs or not next(data.specs) then
        return nil, "No spec data found in import"
    end
    
    return data, nil
end

function ME.GenerateImportPreview(data)
    if not data then return "|cff888888No data|r" end
    
    local lines = {}
    local _, _, myClassID = UnitClass("player")
    
    table.insert(lines, string.format(
        "|cff00ff00Master Export|r from |cff00ccff%s|r @ %s",
        data.exportedBy or "Unknown", data.realm or "Unknown"
    ))
    if data.timestamp then
        table.insert(lines, "|cff888888Exported: " .. date("%Y-%m-%d %H:%M", data.timestamp) .. "|r")
    end
    table.insert(lines, "")
    
    local sorted = {}
    for specKey, specEntry in pairs(data.specs) do
        table.insert(sorted, { key = specKey, entry = specEntry })
    end
    table.sort(sorted, function(a, b)
        local ac = a.entry.classID or 99
        local bc = b.entry.classID or 99
        if ac ~= bc then return ac < bc end
        return (a.entry.specIndex or 99) < (b.entry.specIndex or 99)
    end)
    
    local totalProfiles = 0
    local myClassCount = 0
    local otherClassCount = 0
    
    for _, s in ipairs(sorted) do
        local specEntry = s.entry
        local displayName = GetSpecDisplayName(s.key, specEntry.specName)
        local isMyClass = specEntry.classID == myClassID
        
        local profileNames = {}
        if specEntry.profiles then
            for pName, pData in pairs(specEntry.profiles) do
                local posCount = 0
                if pData.savedPositions then
                    for _ in pairs(pData.savedPositions) do posCount = posCount + 1 end
                end
                table.insert(profileNames, string.format("'%s' (%d icons)", pName, posCount))
                totalProfiles = totalProfiles + 1
            end
        end
        table.sort(profileNames)
        
        local routeTag = isMyClass
            and "|cff00ff00→ Will merge into this character|r"
            or "|cff888888→ Stored for future (different class)|r"
        
        if isMyClass then myClassCount = myClassCount + 1
        else otherClassCount = otherClassCount + 1 end
        
        table.insert(lines, displayName .. "  " .. routeTag)
        for _, pStr in ipairs(profileNames) do
            table.insert(lines, "    • " .. pStr)
        end
        if specEntry.sourceChar then
            table.insert(lines, "    |cff666666from " .. specEntry.sourceChar .. "|r")
        end
    end
    
    table.insert(lines, "")
    table.insert(lines, string.format(
        "|cffffd100Total: %d profile(s) across %d spec(s)|r  |cff00ff00(%d for this class|r, |cff888888%d other)|r",
        totalProfiles, #sorted, myClassCount, otherClassCount
    ))
    
    if data.cdmEnhance then
        local extras = {}
        if data.cdmEnhance.globalAuraSettings then table.insert(extras, "Aura Defaults") end
        if data.cdmEnhance.globalCooldownSettings then table.insert(extras, "Cooldown Defaults") end
        if #extras > 0 then
            table.insert(lines, "|cffffd100Includes:|r " .. table.concat(extras, ", "))
        end
    end
    
    return table.concat(lines, "\n")
end

-- Merge profiles into specData with rename-on-conflict
-- This is the core merge logic shared by Import() and AutoApplyPendingProfiles()
-- Returns mergedCount, firstImportedProfileName
local function MergeProfilesIntoSpec(cdmGroupsDB, specKey, specEntry, sourceLabel)
    if not cdmGroupsDB.specData then cdmGroupsDB.specData = {} end
    
    -- Ensure specData entry exists
    if not cdmGroupsDB.specData[specKey] then
        cdmGroupsDB.specData[specKey] = {
            layoutProfiles = {},
            activeProfile = "Default",
            groupSettings = {},
        }
    end
    
    local targetSpec = cdmGroupsDB.specData[specKey]
    if not targetSpec.layoutProfiles then
        targetSpec.layoutProfiles = {}
    end
    
    local mergedCount = 0
    local firstImportedName = nil
    
    if specEntry.profiles then
        for profileName, profileData in pairs(specEntry.profiles) do
            local finalName = profileName
            
            if targetSpec.layoutProfiles[profileName] then
                local baseName = profileName .. " (" .. sourceLabel .. ")"
                finalName = baseName
                local counter = 2
                while targetSpec.layoutProfiles[finalName] do
                    finalName = baseName .. " " .. counter
                    counter = counter + 1
                end
                print(MSG_PREFIX .. "|cffFFFF00'" .. profileName .. "' exists|r → imported as '" .. finalName .. "'")
            end
            
            targetSpec.layoutProfiles[finalName] = DeepCopy(profileData)
            mergedCount = mergedCount + 1
            firstImportedName = firstImportedName or finalName
            print(MSG_PREFIX .. "Added profile: " .. finalName)
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- REPAIR: Ensure all imported profiles have valid groupLayouts
    -- Matches the same repair logic as the normal per-spec import
    -- ═══════════════════════════════════════════════════════════════════════════
    local DEFAULT_GROUPS = ns.CDMGroups and ns.CDMGroups.DEFAULT_GROUPS
    
    for profileName, profileData in pairs(targetSpec.layoutProfiles) do
        -- Ensure required tables exist
        if not profileData.savedPositions then profileData.savedPositions = {} end
        if not profileData.freeIcons then profileData.freeIcons = {} end
        if not profileData.iconSettings then profileData.iconSettings = {} end
        
        -- If groupLayouts is empty, populate from DEFAULT_GROUPS
        if not profileData.groupLayouts or not next(profileData.groupLayouts) then
            print(MSG_PREFIX .. "|cffff8800[Repair]|r Profile '" .. profileName .. "' has no groups — adding defaults")
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
                -- Fallback if DEFAULT_GROUPS not available
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
    -- SET ACTIVE PROFILE to the first imported one (same as normal import)
    -- ═══════════════════════════════════════════════════════════════════════════
    if firstImportedName then
        targetSpec.activeProfile = firstImportedName
        print(MSG_PREFIX .. "Set active profile to: " .. firstImportedName)
    end
    
    -- Merge groupSettings (fill missing only)
    if specEntry.groupSettings then
        if not targetSpec.groupSettings then
            targetSpec.groupSettings = DeepCopy(specEntry.groupSettings)
        else
            for vtype, settings in pairs(specEntry.groupSettings) do
                if not targetSpec.groupSettings[vtype] or not next(targetSpec.groupSettings[vtype]) then
                    targetSpec.groupSettings[vtype] = DeepCopy(settings)
                end
            end
        end
    end
    
    -- Apply global icon settings
    if specEntry.globalIconSettings then
        if specEntry.globalIconSettings.disableTooltips ~= nil then
            cdmGroupsDB.disableTooltips = specEntry.globalIconSettings.disableTooltips
        end
        if specEntry.globalIconSettings.clickThrough ~= nil then
            cdmGroupsDB.clickThrough = specEntry.globalIconSettings.clickThrough
        end
    end
    
    return mergedCount, firstImportedName
end

function ME.Import(data, importMode)
    if not data or not data.specs then
        return false, "No spec data to import"
    end
    
    importMode = importMode or "merge"
    
    local Shared = ns.CDMShared
    if not Shared then return false, "CDMShared not available" end
    
    local cdmGroupsDB = Shared.GetCDMGroupsDB()
    if not cdmGroupsDB then return false, "CDMGroups database not available" end
    if not cdmGroupsDB.specData then cdmGroupsDB.specData = {} end
    
    local _, _, myClassID = UnitClass("player")
    local importedProfiles = 0
    local storedForLater = 0
    local currentSpec = ns.CDMGroups and ns.CDMGroups.currentSpec
    local currentSpecProfileName = nil  -- Track which profile to load for current spec
    
    -- Replace mode: wipe specData for matching class specs first
    if importMode == "replace" then
        for specKey, specEntry in pairs(data.specs) do
            local classID = ParseSpecKey(specKey)
            if classID == myClassID then
                cdmGroupsDB.specData[specKey] = nil
            end
        end
    end
    
    for specKey, specEntry in pairs(data.specs) do
        local classID = ParseSpecKey(specKey)
        
        if not classID then
            -- Skip malformed keys
        elseif classID == myClassID then
            local sourceLabel = specEntry.sourceChar or data.exportedBy or "Imported"
            local merged, firstProfileName = MergeProfilesIntoSpec(cdmGroupsDB, specKey, specEntry, sourceLabel)
            importedProfiles = importedProfiles + merged
            
            -- If this is the current spec, remember which profile to load
            if specKey == currentSpec and firstProfileName then
                currentSpecProfileName = firstProfileName
            end
            
            print(MSG_PREFIX .. "|cff00ff00Merged " .. merged .. " profile(s) into " ..
                GetSpecDisplayName(specKey, specEntry.specName) .. "|r")
        else
            -- Different class — store in global.masterCDMPending
            if ns.db and ns.db.global then
                if not ns.db.global.masterCDMPending then
                    ns.db.global.masterCDMPending = {}
                end
                ns.db.global.masterCDMPending[specKey] = DeepCopy(specEntry)
                storedForLater = storedForLater + 1
                print(MSG_PREFIX .. "|cff888888Stored " .. GetSpecDisplayName(specKey, specEntry.specName) .. " for future use|r")
            end
        end
    end
    
    -- Apply cdmEnhance global defaults
    if data.cdmEnhance and ns.db and ns.db.profile then
        if not ns.db.profile.cdmEnhance then ns.db.profile.cdmEnhance = {} end
        local enhance = ns.db.profile.cdmEnhance
        if data.cdmEnhance.globalAuraSettings then
            enhance.globalAuraSettings = DeepCopy(data.cdmEnhance.globalAuraSettings)
        end
        if data.cdmEnhance.globalCooldownSettings then
            enhance.globalCooldownSettings = DeepCopy(data.cdmEnhance.globalCooldownSettings)
        end
        if data.cdmEnhance.globalApplyScale ~= nil then
            enhance.globalApplyScale = data.cdmEnhance.globalApplyScale
        end
        if data.cdmEnhance.globalApplyHideShadow ~= nil then
            enhance.globalApplyHideShadow = data.cdmEnhance.globalApplyHideShadow
        end
    end
    
    if Shared.ClearDBCache then Shared.ClearDBCache() end
    
    -- Invalidate CDMEnhance settings cache
    if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
        ns.CDMEnhance.InvalidateCache()
    end
    
    -- Refresh cached layout settings (tooltips, click-through)
    if ns.CDMGroups and ns.CDMGroups.RefreshCachedLayoutSettings then
        ns.CDMGroups.RefreshCachedLayoutSettings()
    end
    
    -- If the current spec received profiles, switch to and load the imported profile
    if currentSpecProfileName then
        if ns.CDMGroups and ns.CDMGroups.LoadProfile then
            C_Timer.After(0.2, function()
                print(MSG_PREFIX .. "Loading imported profile '" .. currentSpecProfileName .. "'...")
                ns.CDMGroups.LoadProfile(currentSpecProfileName)
            end)
        end
    end
    
    -- Notify FrameController that layout changed
    if ns.FrameController and ns.FrameController.OnLayoutChange then
        ns.FrameController.OnLayoutChange()
    end
    
    local result = string.format("Imported %d profile(s) to this character", importedProfiles)
    if storedForLater > 0 then
        result = result .. string.format(", %d spec(s) stored for other classes", storedForLater)
    end
    
    return true, result
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTO-APPLY PENDING PROFILES ON LOGIN
-- ═══════════════════════════════════════════════════════════════════════════

function ME.AutoApplyPendingProfiles()
    if not ns.db or not ns.db.global or not ns.db.global.masterCDMPending then return end
    
    local pending = ns.db.global.masterCDMPending
    if not next(pending) then return end
    
    local Shared = ns.CDMShared
    if not Shared then return end
    
    local cdmGroupsDB = Shared.GetCDMGroupsDB()
    if not cdmGroupsDB then return end
    
    local _, _, myClassID = UnitClass("player")
    local applied = 0
    local keysToRemove = {}
    local currentSpec = ns.CDMGroups and ns.CDMGroups.currentSpec
    local currentSpecProfileName = nil
    
    for specKey, specEntry in pairs(pending) do
        local classID = ParseSpecKey(specKey)
        
        if classID == myClassID then
            local sourceLabel = specEntry.sourceChar or "Master Import"
            local merged, firstProfileName = MergeProfilesIntoSpec(cdmGroupsDB, specKey, specEntry, sourceLabel)
            
            if merged > 0 then
                applied = applied + 1
                print(MSG_PREFIX .. "|cff00ff00Auto-merged " .. merged .. " pending profile(s) into " ..
                    GetSpecDisplayName(specKey, specEntry.specName) .. "|r")
                
                -- Track which profile to load for current spec
                if specKey == currentSpec and firstProfileName then
                    currentSpecProfileName = firstProfileName
                end
            end
            
            table.insert(keysToRemove, specKey)
        end
    end
    
    for _, key in ipairs(keysToRemove) do
        pending[key] = nil
    end
    
    if not next(pending) then
        ns.db.global.masterCDMPending = nil
    end
    
    if applied > 0 and Shared.ClearDBCache then
        Shared.ClearDBCache()
        
        -- Invalidate CDMEnhance settings cache
        if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
            ns.CDMEnhance.InvalidateCache()
        end
        
        -- Refresh cached layout settings
        if ns.CDMGroups and ns.CDMGroups.RefreshCachedLayoutSettings then
            ns.CDMGroups.RefreshCachedLayoutSettings()
        end
        
        -- Load the imported profile for current spec
        if currentSpecProfileName and ns.CDMGroups and ns.CDMGroups.LoadProfile then
            C_Timer.After(0.5, function()
                print(MSG_PREFIX .. "Loading imported profile '" .. currentSpecProfileName .. "'...")
                ns.CDMGroups.LoadProfile(currentSpecProfileName)
            end)
        end
        
        -- Notify FrameController
        if ns.FrameController and ns.FrameController.OnLayoutChange then
            ns.FrameController.OnLayoutChange()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- OPTIONS TABLE (AceConfig)
-- ═══════════════════════════════════════════════════════════════════════════

local uiState = {
    selectedForExport = {},
    exportString = "",
    importString = "",
    importPreview = nil,
    importError = nil,
    importMode = "merge",
    collapsedChars = {},  -- charKey → true if collapsed (default: all collapsed)
}

local function GetOptionsTable()
    local options = {
        type = "group",
        name = "Master Export",
        order = 6,
        args = {
            description = {
                type = "description",
                name = "|cffffd100Master Export|r lets you pick individual Arc Manager profiles from any character and spec, then bundle them into a single export string.\n\n" ..
                       "|cff00ccffHow it works:|r\n" ..
                       "1. Select which profiles to include from the list below\n" ..
                       "2. Export generates one string containing all selected profiles\n" ..
                       "3. Import on any character — profiles for your class merge into the matching spec (renamed on conflict), profiles for other classes are stored and auto-merged when you log that class\n",
                fontSize = "medium",
                order = 1,
            },
            
            -- ═══════════════════════════════════════════════════════════════
            -- EXPORT SECTION
            -- ═══════════════════════════════════════════════════════════════
            exportHeader = {
                type = "header",
                name = "Export Profiles",
                order = 10,
            },
            
            selectAllBtn = {
                type = "execute",
                name = "Select All",
                order = 11,
                width = 0.6,
                func = function()
                    local allProfiles = ME.ScanAllProfiles()
                    for _, entry in ipairs(allProfiles) do
                        uiState.selectedForExport[entry.uniqueKey] = true
                    end
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end,
            },
            
            selectNoneBtn = {
                type = "execute",
                name = "Select None",
                order = 12,
                width = 0.6,
                func = function()
                    wipe(uiState.selectedForExport)
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end,
            },
            
            exportBtn = {
                type = "execute",
                name = "Export Selected",
                order = 40,
                width = 1,
                func = function()
                    local result, err = ME.Export(uiState.selectedForExport)
                    if err then
                        print(MSG_PREFIX .. "|cffff0000Export failed:|r " .. err)
                        uiState.exportString = ""
                    else
                        uiState.exportString = result
                        print(MSG_PREFIX .. "|cff00ff00Master export successful!|r Copy the string below.")
                    end
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end,
            },
            
            exportString = {
                type = "input",
                name = "Export String",
                order = 41,
                multiline = 6,
                width = "full",
                get = function() return uiState.exportString end,
                set = function() end,
            },
            
            -- ═══════════════════════════════════════════════════════════════
            -- IMPORT SECTION
            -- ═══════════════════════════════════════════════════════════════
            importHeader = {
                type = "header",
                name = "Import",
                order = 50,
            },
            
            importDesc = {
                type = "description",
                name = "Paste a Master Export string below. Profiles for your class merge into the matching spec's Arc Manager (renamed on conflict). Profiles for other classes are stored and auto-merged when you log that class.",
                order = 51,
                fontSize = "medium",
            },
            
            importString = {
                type = "input",
                name = "Paste Master Export String",
                order = 52,
                multiline = 6,
                width = "full",
                get = function() return uiState.importString end,
                set = function(_, val)
                    uiState.importString = val
                    local data, err = ME.ParseImportString(val)
                    if data then
                        uiState.importPreview = data
                        uiState.importError = nil
                    else
                        uiState.importPreview = nil
                        uiState.importError = err
                    end
                end,
            },
            
            previewBtn = {
                type = "execute",
                name = "Preview",
                order = 53,
                width = 0.5,
                func = function()
                    local data, err = ME.ParseImportString(uiState.importString)
                    if err then
                        uiState.importPreview = nil
                        uiState.importError = err
                        print(MSG_PREFIX .. "|cffff0000" .. err .. "|r")
                    else
                        uiState.importPreview = data
                        uiState.importError = nil
                    end
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end,
            },
            
            importPreviewText = {
                type = "description",
                name = function()
                    if uiState.importError then
                        return "|cffff0000Error:|r " .. uiState.importError
                    elseif uiState.importPreview then
                        return ME.GenerateImportPreview(uiState.importPreview)
                    else
                        return "|cff888888Paste a string and click Preview to see contents.|r"
                    end
                end,
                order = 54,
                fontSize = "medium",
            },
            
            importModeSelect = {
                type = "select",
                name = "Import Mode",
                order = 55,
                width = 1.2,
                values = {
                    merge = "Merge (add profiles alongside existing)",
                    replace = "Replace (wipe matching specs first)",
                },
                get = function() return uiState.importMode end,
                set = function(_, val) uiState.importMode = val end,
            },
            
            importModeDesc = {
                type = "description",
                name = function()
                    if uiState.importMode == "merge" then
                        return "|cff888888Profiles are added alongside existing ones. Conflicting names are renamed (e.g. 'Default (Arc - Illidan)').|r"
                    else
                        return "|cffff6600WARNING: All existing Arc Manager profiles for matching specs will be wiped before importing!|r"
                    end
                end,
                order = 56,
            },
            
            importBtn = {
                type = "execute",
                name = "Import",
                order = 57,
                width = 1.0,
                disabled = function() return uiState.importPreview == nil end,
                func = function()
                    if not uiState.importPreview then
                        print(MSG_PREFIX .. "|cffff0000No valid import data.|r Paste a string and Preview first.")
                        return
                    end
                    local success, result = ME.Import(uiState.importPreview, uiState.importMode)
                    if success then
                        print(MSG_PREFIX .. "|cff00ff00" .. result .. "|r")
                        uiState.importString = ""
                        uiState.importPreview = nil
                        uiState.importError = nil
                        StaticPopup_Show("ARCUI_MASTER_IMPORT_RELOAD")
                    else
                        print(MSG_PREFIX .. "|cffff0000Import failed:|r " .. (result or "Unknown error"))
                    end
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end,
            },
            
            clearImportBtn = {
                type = "execute",
                name = "Clear",
                order = 58,
                width = 0.5,
                func = function()
                    uiState.importString = ""
                    uiState.importPreview = nil
                    uiState.importError = nil
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end,
            },
            
            -- ═══════════════════════════════════════════════════════════════
            -- PENDING INFO
            -- ═══════════════════════════════════════════════════════════════
            pendingHeader = {
                type = "header",
                name = "Pending Profiles (Other Classes)",
                order = 70,
                hidden = function()
                    return not ns.db or not ns.db.global or not ns.db.global.masterCDMPending
                        or not next(ns.db.global.masterCDMPending or {})
                end,
            },
            
            pendingDesc = {
                type = "description",
                name = function()
                    if not ns.db or not ns.db.global or not ns.db.global.masterCDMPending then return "" end
                    local pending = ns.db.global.masterCDMPending
                    if not next(pending) then return "" end
                    
                    local lines = { "These profiles will auto-merge when you log the matching class:\n" }
                    for specKey, specEntry in pairs(pending) do
                        local displayName = GetSpecDisplayName(specKey, specEntry.specName)
                        local profileCount = 0
                        if specEntry.profiles then
                            for _ in pairs(specEntry.profiles) do profileCount = profileCount + 1 end
                        end
                        table.insert(lines, "  • " .. displayName .. " |cff888888(" .. profileCount .. " profile(s))|r")
                    end
                    return table.concat(lines, "\n")
                end,
                order = 71,
                fontSize = "medium",
                hidden = function()
                    return not ns.db or not ns.db.global or not ns.db.global.masterCDMPending
                        or not next(ns.db.global.masterCDMPending or {})
                end,
            },
            
            clearPendingBtn = {
                type = "execute",
                name = "Clear Pending",
                order = 72,
                width = 0.8,
                confirm = true,
                confirmText = "This will delete all pending profiles for other classes. Are you sure?",
                hidden = function()
                    return not ns.db or not ns.db.global or not ns.db.global.masterCDMPending
                        or not next(ns.db.global.masterCDMPending or {})
                end,
                func = function()
                    if ns.db and ns.db.global then
                        ns.db.global.masterCDMPending = nil
                    end
                    print(MSG_PREFIX .. "|cffff8800Pending profiles cleared.|r")
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end,
            },
        },
    }
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- BUILD PER-CHARACTER COLLAPSIBLE SECTIONS
    -- Uses CollapsibleHeader widget (same as CDMGroupsOptions)
    -- All collapsed by default
    -- ═══════════════════════════════════════════════════════════════════════════
    local allProfiles = ME.ScanAllProfiles()
    
    if #allProfiles == 0 then
        options.args["noProfiles"] = {
            type = "description",
            name = "|cff888888No Arc Manager profiles found across any character.|r",
            order = 13,
        }
    else
        -- Group profiles by charKey
        local charOrder = {}
        local charProfiles = {}
        
        for _, entry in ipairs(allProfiles) do
            if not charProfiles[entry.charKey] then
                charProfiles[entry.charKey] = {}
                table.insert(charOrder, entry.charKey)
            end
            table.insert(charProfiles[entry.charKey], entry)
        end
        
        -- Default all characters to collapsed
        for _, charKey in ipairs(charOrder) do
            if uiState.collapsedChars[charKey] == nil then
                uiState.collapsedChars[charKey] = true
            end
        end
        
        -- Create collapsible section per character
        local baseOrder = 13
        
        for charIdx, charKey in ipairs(charOrder) do
            local entries = charProfiles[charKey]
            local firstEntry = entries[1]
            local classInfo = CLASS_INFO[firstEntry.classID]
            local className = classInfo and classInfo.name or ("Class " .. firstEntry.classID)
            local classColor = classInfo and classInfo.color or "ffffffff"
            local charName = GetCharName(charKey)
            local cKey = charKey  -- capture for closures
            
            -- Count profiles and specs for collapsed summary
            local profileCount = #entries
            local specSet = {}
            for _, e in ipairs(entries) do specSet[e.specKey] = true end
            local specCount = 0
            for _ in pairs(specSet) do specCount = specCount + 1 end
            
            local charArgs = {}
            
            -- ── CollapsibleHeader toggle ──
            charArgs["_header"] = {
                type = "toggle",
                name = function()
                    local selCount = 0
                    for _, e in ipairs(entries) do
                        if uiState.selectedForExport[e.uniqueKey] then selCount = selCount + 1 end
                    end
                    local label = "|cffffd100" .. charName .. "|r  |c" .. classColor .. className .. "|r"
                    if uiState.collapsedChars[cKey] then
                        label = label .. "  |cff666666(" .. profileCount .. " profiles, " .. specCount .. " specs)|r"
                    end
                    if selCount > 0 then
                        label = label .. "  |cff00ff00[" .. selCount .. " selected]|r"
                    end
                    return label
                end,
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 0,
                width = "full",
                get = function() return not uiState.collapsedChars[cKey] end,
                set = function(_, v) uiState.collapsedChars[cKey] = not v end,
            }
            
            -- ── Spec headers and profile toggles (hidden when collapsed) ──
            local innerOrder = 1
            local lastSpecKey = nil
            
            for _, entry in ipairs(entries) do
                -- Spec sub-header
                if entry.specKey ~= lastSpecKey then
                    lastSpecKey = entry.specKey
                    charArgs["specHeader_" .. innerOrder] = {
                        type = "description",
                        name = "  |cff888888" .. entry.specName .. "|r",
                        order = innerOrder,
                        fontSize = "medium",
                        hidden = function() return uiState.collapsedChars[cKey] end,
                    }
                    innerOrder = innerOrder + 1
                end
                
                -- Profile toggle
                local detailStr = ""
                if entry.posCount > 0 or entry.iconSettingsCount > 0 then
                    local parts = {}
                    if entry.posCount > 0 then table.insert(parts, entry.posCount .. " icons") end
                    if entry.iconSettingsCount > 0 then table.insert(parts, entry.iconSettingsCount .. " styled") end
                    detailStr = " |cff666666[" .. table.concat(parts, ", ") .. "]|r"
                end
                
                local uKey = entry.uniqueKey
                charArgs["profile_" .. innerOrder] = {
                    type = "toggle",
                    name = "    " .. entry.profileName .. detailStr,
                    order = innerOrder,
                    width = "full",
                    hidden = function() return uiState.collapsedChars[cKey] end,
                    get = function() return uiState.selectedForExport[uKey] or false end,
                    set = function(_, val) uiState.selectedForExport[uKey] = val end,
                }
                innerOrder = innerOrder + 1
            end
            
            options.args["char_" .. charIdx] = {
                type = "group",
                name = "",
                order = baseOrder + charIdx,
                inline = true,
                args = charArgs,
            }
        end
    end
    
    return options
end

function ns.GetCDMMasterExportOptionsTable()
    return GetOptionsTable()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RELOAD POPUP
-- ═══════════════════════════════════════════════════════════════════════════

StaticPopupDialogs["ARCUI_MASTER_IMPORT_RELOAD"] = {
    text = "|cff00ccffArcUI|r Master import complete.\n\nReload UI to apply all changes?",
    button1 = "Reload Now",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT: Auto-apply pending on login
-- ═══════════════════════════════════════════════════════════════════════════

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(2, function()
            ME.AutoApplyPendingProfiles()
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SLASH COMMAND
-- ═══════════════════════════════════════════════════════════════════════════

SLASH_ARCUIMASTEREXPORT1 = "/arcmaster"
SlashCmdList["ARCUIMASTEREXPORT"] = function()
    if ns.API and ns.API.OpenOptions then
        ns.API.OpenOptions()
        C_Timer.After(0.1, function()
            local ACD = LibStub("AceConfigDialog-3.0", true)
            if ACD then
                ACD:SelectGroup("ArcUI", "masterExport")
            end
        end)
    else
        print(MSG_PREFIX .. "Options not available yet.")
    end
end