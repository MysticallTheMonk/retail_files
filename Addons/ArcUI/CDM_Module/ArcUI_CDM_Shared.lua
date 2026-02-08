-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI CDM Shared Module
-- Common constants, helpers, and throttle management for all CDM modules
-- ═══════════════════════════════════════════════════════════════════════════

local addonName, ns = ...

-- ═══════════════════════════════════════════════════════════════════════════
-- FRAME CONTROLLER TOGGLE
-- Set to true to use new unified FrameController, false for legacy systems
-- ═══════════════════════════════════════════════════════════════════════════
_G.ARCUI_USE_FRAME_CONTROLLER = true

-- Create shared namespace (loaded before CDMEnhance and CDMGroups)
ns.CDMShared = ns.CDMShared or {}
local Shared = ns.CDMShared

-- ===================================================================
-- LIBPLEEBUG PROFILING SETUP
-- ===================================================================
local MemDebug = LibStub and LibStub("LibPleebug-1", true)
local P, TrackThis
if MemDebug then
  P, TrackThis = MemDebug:DropIn(ns.CDMShared)
end
ns.CDMShared._TrackThis = TrackThis

-- ═══════════════════════════════════════════════════════════════════════════
-- CDM STYLING MASTER TOGGLE
-- Single source of truth for enabling/disabling all CDM styling
-- ═══════════════════════════════════════════════════════════════════════════

-- Static popup for reload prompt
StaticPopupDialogs["ARCUI_CDM_STYLING_RELOAD"] = {
    text = "CDM Styling setting changed.\n\nReload UI to fully apply?",
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

-- Check if CDM styling is enabled (read from global setting)
function Shared.IsCDMStylingEnabled()
    if ns.db and ns.db.global then
        return ns.db.global.cdmStylingEnabled ~= false
    end
    return true  -- Default to enabled
end

-- Set CDM styling enabled state and prompt for reload
-- IMPORTANT: Writes to BOTH global (for toggle sync) AND char (for runtime checks in CDMEnhance)
function Shared.SetCDMStylingEnabled(val)
    -- Write to global setting (what the toggle reads)
    if ns.db and ns.db.global then
        ns.db.global.cdmStylingEnabled = val
    end
    -- ALSO write to char setting (what CDMEnhance runtime checks read)
    if ns.db and ns.db.char and ns.db.char.cdmGroups then
        ns.db.char.cdmGroups.enabled = val
    end
    -- Prompt user to reload for clean state
    StaticPopup_Show("ARCUI_CDM_STYLING_RELOAD")
    -- Refresh options panel so all toggles update
    if LibStub then
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end
end

-- Sync global and char enabled values (call at startup)
-- If global is nil (never set), initialize from char to preserve existing settings
-- Then global becomes source of truth, char is synced to match
function Shared.SyncCDMStylingEnabled()
    if not ns.db then return end
    
    -- Ensure global table exists
    if not ns.db.global then ns.db.global = {} end
    
    -- If global.cdmStylingEnabled is nil (never explicitly set), initialize from char
    -- This preserves existing user settings on first startup after this fix
    if ns.db.global.cdmStylingEnabled == nil then
        if ns.db.char and ns.db.char.cdmGroups and ns.db.char.cdmGroups.enabled ~= nil then
            -- Char has an explicit value - use it to initialize global
            ns.db.global.cdmStylingEnabled = ns.db.char.cdmGroups.enabled
        else
            -- Neither has a value - default to true
            ns.db.global.cdmStylingEnabled = true
        end
    end
    
    -- Now global is the source of truth - sync char to match
    local globalEnabled = ns.db.global.cdmStylingEnabled ~= false
    if ns.db.char and ns.db.char.cdmGroups then
        ns.db.char.cdmGroups.enabled = globalEnabled
    end
    
    -- Refresh cached state
    Shared.RefreshCachedEnabledState()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CACHED ENABLED STATE (avoid repeated DB lookups in hot paths)
-- Other modules should use IsCDMGroupsEnabledCached() instead of checking DB
-- ═══════════════════════════════════════════════════════════════════════════
local cachedCDMGroupsEnabled = true  -- Assume enabled until DB is ready
local cachedCDMStylingEnabled = true  -- Assume enabled until DB is ready

-- Refresh the cached enabled state (call on settings change or profile switch)
function Shared.RefreshCachedEnabledState()
    local db = Shared.GetCDMGroupsDB()
    cachedCDMGroupsEnabled = db and db.enabled ~= false
    
    -- Also cache styling enabled state
    if ns.db and ns.db.global then
        cachedCDMStylingEnabled = ns.db.global.cdmStylingEnabled ~= false
    else
        cachedCDMStylingEnabled = true
    end
end

-- Fast check for CDMGroups enabled (no DB lookup)
function Shared.IsCDMGroupsEnabledCached()
    return cachedCDMGroupsEnabled
end

-- Fast check for CDM styling enabled (no DB lookup)
function Shared.IsCDMStylingEnabledCached()
    return cachedCDMStylingEnabled
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CDM CATEGORY CONSTANTS
-- These match Blizzard's C_CooldownViewer category values
-- ═══════════════════════════════════════════════════════════════════════════

Shared.CATEGORY = {
    ESSENTIAL = 0,      -- Essential cooldowns (EssentialCooldownViewer)
    UTILITY = 1,        -- Utility cooldowns (UtilityCooldownViewer)
    TRACKED_BUFF = 2,   -- Tracked buffs (BuffIconCooldownViewer, BuffBarCooldownViewer)
    TRACKED_DEBUFF = 3, -- Tracked debuffs (also aura category)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- CDM VIEWER DEFINITIONS
-- Central source of truth for all CDM viewer information
-- ═══════════════════════════════════════════════════════════════════════════

Shared.CDM_VIEWERS = {
    { name = "BuffIconCooldownViewer", type = "aura", defaultGroup = "Buffs", category = 2 },
    { name = "BuffBarCooldownViewer", type = "aura", defaultGroup = "Buffs", category = 2, skipInGroups = true, isBar = true },
    { name = "EssentialCooldownViewer", type = "cooldown", defaultGroup = "Essential", category = 0 },
    { name = "UtilityCooldownViewer", type = "utility", defaultGroup = "Utility", category = 1 },
}

-- Quick lookups
Shared.VIEWER_BY_NAME = {}
Shared.VIEWER_BY_TYPE = {}
for _, v in ipairs(Shared.CDM_VIEWERS) do
    Shared.VIEWER_BY_NAME[v.name] = v
    if not Shared.VIEWER_BY_TYPE[v.type] then
        Shared.VIEWER_BY_TYPE[v.type] = v
    end
end

-- Map viewerType -> primary viewer frame name (for CDMEnhance compatibility)
Shared.VIEWER_FRAME_MAP = {
    aura = "BuffIconCooldownViewer",
    cooldown = "EssentialCooldownViewer",
    utility = "UtilityCooldownViewer",
}

-- Default group colors
Shared.GROUP_COLORS = {
    Buffs = { r = 0.3, g = 0.8, b = 0.3 },
    Essential = { r = 0.8, g = 0.6, b = 0.2 },
    Utility = { r = 0.3, g = 0.6, b = 0.9 },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- CATEGORY HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if a CDM category is an aura (buff/debuff)
-- Categories 2 and 3 are tracked buffs and debuffs
function Shared.IsAuraCategory(category)
    return category == 2 or category == 3
end

-- Check if a CDM category is a cooldown (not an aura)
function Shared.IsCooldownCategory(category)
    return category == 0 or category == 1
end

-- Get viewerType from category number
function Shared.GetViewerTypeFromCategory(category)
    if category == 0 then return "cooldown"
    elseif category == 1 then return "utility"
    elseif category == 2 or category == 3 then return "aura"
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEWER HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Get viewerType and defaultGroup from viewer name
function Shared.GetViewerTypeFromName(viewerName)
    if not viewerName then return nil, nil end
    local info = Shared.VIEWER_BY_NAME[viewerName]
    if info then
        return info.type, info.defaultGroup
    end
    return nil, nil
end

-- Get viewer info from type
function Shared.GetViewerInfoFromType(viewerType)
    return Shared.VIEWER_BY_TYPE[viewerType]
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SAFE SPELL API HELPERS
-- Handle both old and new WoW APIs gracefully
-- ═══════════════════════════════════════════════════════════════════════════

function Shared.SafeGetSpellName(spellID)
    if not spellID or spellID == 0 then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then return info.name end
    end
    if GetSpellInfo then
        return (GetSpellInfo(spellID))
    end
    return nil
end

function Shared.SafeGetSpellTexture(spellID)
    if not spellID or spellID == 0 then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    end
    if GetSpellTexture then
        return GetSpellTexture(spellID)
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ARC AURA ID HELPERS
-- Arc Auras use string IDs like "arc_trinket_13", "arc_item_12345"
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if a cooldownID is an Arc Aura (string starting with "arc_")
function Shared.IsArcAuraID(cooldownID)
    return type(cooldownID) == "string" and cooldownID:match("^arc_")
end

-- Parse "arc_trinket_13" -> "trinket", 13
function Shared.ParseArcAuraID(arcID)
    if not Shared.IsArcAuraID(arcID) then return nil, nil end
    local arcType, id = arcID:match("^arc_(%w+)_(%d+)$")
    return arcType, tonumber(id)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UNIVERSAL FRAME ID SYSTEM
-- CDM frames use frame.cooldownID (number)
-- Arc Aura frames use frame._arcAuraID (string)
-- These are mutually exclusive - a frame has one or the other, never both
-- ═══════════════════════════════════════════════════════════════════════════

-- Get the universal ID for any managed frame
-- Returns: arcID (string) for Arc Auras, cooldownID (number) for CDM frames, or nil
function Shared.GetFrameID(frame)
    if not frame then return nil end
    if frame._arcAuraID then return frame._arcAuraID end
    if frame.cooldownID then return frame.cooldownID end
    return nil
end

-- Check if a frame is a custom frame (Arc Aura, not from CDM)
-- Custom frames have _arcAuraID and NO cooldownID
function Shared.IsCustomFrame(frame)
    return frame and frame._arcAuraID ~= nil
end

-- Check if a frame is a CDM frame (from Blizzard's Cooldown Manager)
-- CDM frames have cooldownID (number) and NO _arcAuraID
function Shared.IsCDMFrame(frame)
    return frame and frame.cooldownID ~= nil and frame._arcAuraID == nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SAFE CDM API WRAPPER
-- Single entry point for C_CooldownViewer.GetCooldownViewerCooldownInfo
-- Handles: nil checks, string ID safety, API existence
-- ═══════════════════════════════════════════════════════════════════════════

-- Safe wrapper for GetCooldownViewerCooldownInfo
-- Returns cdInfo table or nil (never errors)
function Shared.SafeGetCDMInfo(cooldownID)
    -- Guard: Must be a number (CDM API only accepts numeric cooldownIDs)
    if type(cooldownID) ~= "number" then
        return nil
    end
    
    -- Guard: API must exist
    if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCooldownInfo then
        return nil
    end
    
    -- Safe to call
    return C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
end

-- Get viewerType from cooldownID (uses SafeGetCDMInfo internally)
-- Returns: viewerType, defaultGroup (or nil, nil)
function Shared.GetViewerTypeFromCooldownID(cooldownID)
    -- Handle Arc Aura string IDs - treat as cooldowns for visual/behavior purposes
    -- Note: Shared.IsArcAuraID() can still be used to detect Arc Auras specifically
    if Shared.IsArcAuraID(cooldownID) then
        return "cooldown", "Essential"
    end
    
    local cdInfo = Shared.SafeGetCDMInfo(cooldownID)
    if not cdInfo then return nil, nil end
    
    if Shared.IsAuraCategory(cdInfo.category) then
        return "aura", "Buffs"
    elseif cdInfo.category == 1 then
        return "utility", "Utility"
    else
        return "cooldown", "Essential"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- THROTTLE SYSTEM
-- Adaptive update rates based on context to save performance
-- ═══════════════════════════════════════════════════════════════════════════

-- Update intervals (in seconds)
-- Using 5Hz (0.2s) constant - hooks handle immediate CDM fighting
-- Maintainer is backup for visual state and position drift
Shared.THROTTLE = {
    FIGHTING = 0.20,    -- 5Hz - Same rate everywhere for now (testing)
    COMBAT = 0.20,      -- 5Hz
    IDLE = 0.20,        -- 5Hz
}

-- Throttle state (module-level for performance)
local currentInCombat = false
local currentCDMSettingsOpen = false
local lastCDMEventTime = 0
local CDM_EVENT_FIGHTING_DURATION = 2.0  -- Fight at high rate for 2 seconds after CDM events

-- Get the current throttle rate based on context
function Shared.GetThrottleRate()
    local now = GetTime()
    
    -- High rate if CDM settings open OR recent CDM event
    if currentCDMSettingsOpen or (now - lastCDMEventTime) < CDM_EVENT_FIGHTING_DURATION then
        return Shared.THROTTLE.FIGHTING
    end
    
    -- Medium rate in combat
    if currentInCombat then
        return Shared.THROTTLE.COMBAT
    end
    
    -- Low rate when idle
    return Shared.THROTTLE.IDLE
end

-- Signal that CDM made changes requiring high-frequency fighting
-- Call this on: COOLDOWN_VIEWER events, icon add/remove, frame reassignment
function Shared.OnCDMEvent()
    lastCDMEventTime = GetTime()
end

-- Update combat state (called from event handlers)
function Shared.SetInCombat(inCombat)
    currentInCombat = inCombat
end

-- Update CDM settings panel state
function Shared.SetCDMSettingsOpen(isOpen)
    currentCDMSettingsOpen = isOpen
end

-- Check if we're in "fighting mode" (high frequency updates needed)
function Shared.IsFightingMode()
    local now = GetTime()
    return currentCDMSettingsOpen or (now - lastCDMEventTime) < CDM_EVENT_FIGHTING_DURATION
end

-- Check current states (for debugging)
function Shared.GetThrottleState()
    return {
        inCombat = currentInCombat,
        cdmSettingsOpen = currentCDMSettingsOpen,
        lastCDMEventTime = lastCDMEventTime,
        currentRate = Shared.GetThrottleRate(),
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CHARACTER-SPECIFIC DATABASE ACCESS
-- All CDMGroups data is stored per-character (not shared across alts)
-- This is the SINGLE access point for all cdmGroups data
-- ═══════════════════════════════════════════════════════════════════════════

-- Cache for GetCDMGroupsDB to avoid repeated string concatenation and table lookups
local cachedCDMGroupsDB = nil
local cachedCharKey = nil
local dbCacheEnabled = false  -- Only enable after PLAYER_LOGIN

-- DIRECT TABLE REFERENCE: Hot paths can use Shared.db instead of GetCDMGroupsDB()
-- This is just a table lookup (nearly free) vs a function call
-- Will be nil until EnableDBCache() is called after PLAYER_LOGIN
Shared.db = nil

-- Enable caching after we're sure SavedVariables are loaded
function Shared.EnableDBCache()
    dbCacheEnabled = true
    -- Force a DB fetch to populate the cache and direct reference
    local db = Shared.GetCDMGroupsDB()
    Shared.db = db
end

-- Get the character-specific CDMGroups database
-- Automatically initializes structure if missing
-- Returns nil if ns.db not ready yet
-- BYPASS ACEDB: Access ArcUIDB directly to avoid removeDefaults stripping our data

function Shared.GetCDMGroupsDB()
    -- Return cached result if available AND caching is enabled
    if dbCacheEnabled and cachedCDMGroupsDB then
        return cachedCDMGroupsDB
    end
    
    -- CRITICAL: Access the raw SavedVariables table directly, not through AceDB
    -- AceDB's removeDefaults strips tables that "match defaults" on logout,
    -- which can cause data loss for complex nested structures like specData.
    
    -- Ensure base structure exists
    if not ArcUIDB then ArcUIDB = {} end
    if not ArcUIDB.char then ArcUIDB.char = {} end
    
    -- Get character key the same way AceDB does
    local charKey = UnitName("player") .. " - " .. GetRealmName()
    
    if not ArcUIDB.char[charKey] then ArcUIDB.char[charKey] = {} end
    
    local charDB = ArcUIDB.char[charKey]
    
    -- Initialize cdmGroups if missing
    if not charDB.cdmGroups then
        charDB.cdmGroups = {
            specData = {},
            specInheritedFrom = {},
            lastActiveSpec = nil,
            migratedOldKeys = {},
            migratedFromProfile = false,
            enabled = true,
            showBorderInEditMode = false,
            showControlButtons = true,
            disableTooltips = false,
            clickThrough = false,
            firstInitialized = time(),
        }
    end
    
    local db = charDB.cdmGroups
    
    -- Ensure sub-tables exist (defensive)
    if not db.specData then db.specData = {} end
    if not db.specInheritedFrom then db.specInheritedFrom = {} end
    if not db.migratedOldKeys then db.migratedOldKeys = {} end
    
    -- Ensure firstInitialized is set
    if not db.firstInitialized then
        db.firstInitialized = time()
    end
    
    -- Cache the result if caching is enabled (after PLAYER_LOGIN)
    if dbCacheEnabled then
        cachedCDMGroupsDB = db
        cachedCharKey = charKey
        Shared.db = db  -- Also update direct reference
    end
    
    return db
end

-- Clear cache - call when DB needs to be re-fetched (e.g. after profile change)
function Shared.ClearDBCache()
    cachedCDMGroupsDB = nil
    cachedCharKey = nil
    Shared.db = nil  -- Also clear direct reference
end

-- Alias for backward compatibility and shorter access
-- Other modules can use: local GetDB = ns.CDMShared.GetCDMGroupsDB
Shared.GetDB = Shared.GetCDMGroupsDB

-- ═══════════════════════════════════════════════════════════════════════════
-- SPEC-BASED ICON & GROUP SETTINGS
-- Per-icon visual customizations and group settings are stored per-spec
-- ═══════════════════════════════════════════════════════════════════════════

-- Get current spec key (class_X_spec_Y format)
local function GetCurrentSpecKey()
    if ns.CDMGroups and ns.CDMGroups.currentSpec then
        return ns.CDMGroups.currentSpec
    end
    -- Fallback: calculate it directly
    local specIndex = GetSpecialization and GetSpecialization() or 1
    local _, _, classID = UnitClass("player")
    classID = classID or 0
    return "class_" .. classID .. "_spec_" .. specIndex
end
Shared.GetCurrentSpecKey = GetCurrentSpecKey

-- Get spec data for current spec, creating if needed
local function GetCurrentSpecData()
    local db = Shared.GetCDMGroupsDB()
    if not db then return nil end
    
    local specKey = GetCurrentSpecKey()
    if not specKey then return nil end
    
    -- Create specData entry if missing
    if not db.specData[specKey] then
        db.specData[specKey] = {
            groups = {},
            savedPositions = {},
            freeIcons = {},
            layoutProfiles = {},
            iconSettings = {},      -- Per-icon visual customizations
            groupSettings = {       -- Group-level settings per viewer type
                aura = {},
                cooldown = {},
                utility = {},
            },
        }
    end
    
    local specData = db.specData[specKey]
    
    -- Ensure groupSettings exist (for existing specData)
    -- NOTE: iconSettings is now stored in profile.iconSettings, not specData.iconSettings
    -- See Shared.GetSpecIconSettings() for the correct way to access per-icon settings
    if not specData.groupSettings then
        specData.groupSettings = {
            aura = {},
            cooldown = {},
            utility = {},
        }
    end
    -- Ensure each viewer type has settings
    for _, vtype in ipairs({"aura", "cooldown", "utility"}) do
        if not specData.groupSettings[vtype] then
            specData.groupSettings[vtype] = {}
        end
    end
    
    return specData
end
Shared.GetCurrentSpecData = GetCurrentSpecData

-- ═══════════════════════════════════════════════════════════════════════════
-- PROFILE-BASED ICON SETTINGS (Single Source of Truth)
-- All per-icon visual settings are stored in profile.iconSettings
-- NOT in specData.iconSettings (that was legacy/duplicate storage)
-- ═══════════════════════════════════════════════════════════════════════════

-- Get the active profile for the current spec
-- Returns the profile table and profile name, or nil if not available
function Shared.GetActiveProfile()
    local specData = GetCurrentSpecData()
    if not specData then return nil, nil end
    if not specData.layoutProfiles then return nil, nil end
    
    local profileName = specData.activeProfile or "Default"
    local profile = specData.layoutProfiles[profileName]
    
    -- Fallback to Default if active profile doesn't exist
    if not profile and profileName ~= "Default" then
        profile = specData.layoutProfiles["Default"]
        profileName = "Default"
    end
    
    return profile, profileName
end

-- Get profile-based iconSettings (per-icon visual customizations)
-- Returns the iconSettings table from the ACTIVE PROFILE (single source of truth)
-- This is where all per-icon visual settings should be stored
function Shared.GetSpecIconSettings()
    local profile = Shared.GetActiveProfile()
    if not profile then return nil end
    
    -- Ensure iconSettings table exists in profile
    if not profile.iconSettings then
        profile.iconSettings = {}
    end
    
    return profile.iconSettings
end

-- Get spec-based groupSettings (group-level visual settings)
-- NOTE: groupSettings is still at specData level (not per-profile)
-- because group visual settings apply to the spec, not the layout
function Shared.GetSpecGroupSettings()
    local specData = GetCurrentSpecData()
    if not specData then return nil end
    
    -- Ensure groupSettings exists
    if not specData.groupSettings then
        specData.groupSettings = {}
    end
    
    return specData.groupSettings
end

-- Get or create icon settings for a specific cooldownID
-- Returns the settings table for that icon (creates if missing)
function Shared.GetOrCreateIconSettings(cdID)
    local iconSettings = Shared.GetSpecIconSettings()
    if not iconSettings then return nil end
    
    local key = tostring(cdID)
    if not iconSettings[key] then
        iconSettings[key] = {}
    end
    return iconSettings[key]
end

-- Get icon settings for a specific cooldownID (read-only, may return nil)
function Shared.GetIconSettings(cdID)
    local iconSettings = Shared.GetSpecIconSettings()
    if not iconSettings then return nil end
    return iconSettings[tostring(cdID)]
end

-- Clear icon settings for a specific cooldownID
function Shared.ClearIconSettings(cdID)
    local iconSettings = Shared.GetSpecIconSettings()
    if not iconSettings then return end
    iconSettings[tostring(cdID)] = nil
end

-- Get group settings for a viewer type
function Shared.GetGroupSettingsForType(viewerType)
    local groupSettings = Shared.GetSpecGroupSettings()
    if not groupSettings then return nil end
    return groupSettings[viewerType]
end

-- ═══════════════════════════════════════════════════════════════════════════
-- GROUP TEMPLATES (Account-Wide)
-- Shareable group layouts without cooldownID data
-- ═══════════════════════════════════════════════════════════════════════════

-- Get the Group Templates database (account-wide via profile)
-- Automatically initializes structure if missing
function Shared.GetGroupTemplatesDB()
    if not ns.db then return nil end
    if not ns.db.profile then ns.db.profile = {} end
    
    -- Initialize groupTemplates structure if missing
    if not ns.db.profile.groupTemplates then
        ns.db.profile.groupTemplates = {}
    end
    
    return ns.db.profile.groupTemplates
end

-- Get Group Template settings (default template, etc.)
function Shared.GetGroupTemplateSettings()
    if not ns.db then return nil end
    if not ns.db.profile then ns.db.profile = {} end
    
    -- Initialize settings structure if missing
    if not ns.db.profile.groupTemplateSettings then
        ns.db.profile.groupTemplateSettings = {
            defaultTemplate = nil,  -- nil = use hardcoded DEFAULT_GROUPS
        }
    end
    
    return ns.db.profile.groupTemplateSettings
end

-- Get the default template name (or nil if using hardcoded defaults)
function Shared.GetDefaultTemplateName()
    local settings = Shared.GetGroupTemplateSettings()
    if not settings then return nil end
    return settings.defaultTemplate
end

-- Set the default template name
function Shared.SetDefaultTemplateName(templateName)
    local settings = Shared.GetGroupTemplateSettings()
    if not settings then return end
    settings.defaultTemplate = templateName
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Shared debug buffer (both CDMEnhance and CDMGroups can write to this)
Shared.debugBuffer = {}
Shared.debugEnabled = false

function Shared.DebugLog(...)
    if not Shared.debugEnabled then return end
    local msg = string.format(...)
    table.insert(Shared.debugBuffer, msg)
    if #Shared.debugBuffer > 500 then
        table.remove(Shared.debugBuffer, 1)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Register for combat events to update throttle state
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED")
eventFrame:RegisterEvent("COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        Shared.SetInCombat(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        Shared.SetInCombat(false)
    elseif event == "COOLDOWN_VIEWER_DATA_LOADED" or event == "COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED" then
        -- CDM changed something, switch to fighting mode
        Shared.OnCDMEvent()
    elseif event == "PLAYER_LOGIN" then
        -- Enable DB caching now that SavedVariables are loaded
        C_Timer.After(0.1, function()
            Shared.EnableDBCache()
            -- NOTE: Removed auto-cleanup call (OnProfileReady) to prevent any data deletion
            -- Users can manually clean up via /arcui cleanup if needed
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CACHED OPTIONS PANEL STATE
-- Single source of truth for options panel open state
-- Cached to avoid expensive LibStub lookups on every call (was 700+ calls/sec!)
-- ═══════════════════════════════════════════════════════════════════════════

local optionsPanelOpenCache = false
local optionsPanelCacheTime = 0
local OPTIONS_PANEL_CACHE_INTERVAL = 0.25  -- Update cache every 0.25s

-- Internal: Actually check if options panel is open (expensive - uses LibStub)
local function CheckOptionsPanelOpen()
    local ACD = LibStub and LibStub("AceConfigDialog-3.0", true)
    if ACD then
        return ACD.OpenFrames and ACD.OpenFrames["ArcUI"] ~= nil
    end
    return false
end

-- Public: Get cached options panel state (cheap - just returns cached value)
function Shared.IsOptionsPanelOpen()
    return optionsPanelOpenCache
end

-- Update the cache - called by ticker
local function UpdateOptionsPanelCache()
    local newState = CheckOptionsPanelOpen()
    if newState ~= optionsPanelOpenCache then
        optionsPanelOpenCache = newState
        -- Fire callback if state changed
        if Shared.OnOptionsPanelStateChanged then
            Shared.OnOptionsPanelStateChanged(newState)
        end
    end
end

-- Ticker to update cache periodically
local optionsPanelCacheTicker = C_Timer.NewTicker(OPTIONS_PANEL_CACHE_INTERVAL, UpdateOptionsPanelCache)

-- ===================================================================
-- LIBPLEEBUG FUNCTION WRAPPING
-- Wrap hot functions for CPU profiling
-- ===================================================================
if P then
  -- DB Access (17ms @ 42/sec - most called function!)
  Shared.GetCDMGroupsDB = P:Def("GetCDMGroupsDB", Shared.GetCDMGroupsDB, "DB")
  
  -- Options Panel State (cached now but still track it)
  Shared.IsOptionsPanelOpen = P:Def("IsOptionsPanelOpen", Shared.IsOptionsPanelOpen, "State")
  Shared.IsCDMStylingEnabled = P:Def("IsCDMStylingEnabled", Shared.IsCDMStylingEnabled, "State")
end