-- CDMGroups.lua - Icon group management for CDM cooldowns (Container LITE)
-- Supports sparse grids with empty slots. Per-spec groups with independent layouts.
-- v1.2: Curve-based cooldown detection for proper desaturation
--       - Uses EvaluateRemainingPercent(curve) for hide/dim/desat
--       - SetDesaturation(number) for proper desaturation on CD
--       - Binary curve: ready=0, onCD=1 (for desaturation)
--       - BinaryInv curve: ready=1, onCD=0 (for hide/alpha)
-- v1.3: Per-icon width/height support
--       - Icons can now have custom width/height when Group Scale is off
--       - Separate effectiveW/effectiveH tracking for non-square icons
--       - Container sizing accounts for oversized icons at edges

local ADDON_NAME, ns = ...


-- CDMGroups functionality integrated into ArcUI
ns.CDMGroups = ns.CDMGroups or {}

-- Expose globally for debug tools like CDMApiTest to find
_G.ArcUI_CDMGroups_NS = ns

-- ===================================================================
-- LIBPLEEBUG PROFILING SETUP
-- ===================================================================
local MemDebug = LibStub and LibStub("LibPleebug-1", true)
local P, TrackThis
if MemDebug then
  P, TrackThis = MemDebug:DropIn(ns.CDMGroups)
end
ns.CDMGroups._TrackThis = TrackThis

-- CONSTANTS
local MSG_PREFIX = "|cff00ccffArcUI|r: "

-- ═══════════════════════════════════════════════════════════════════════════
-- SHARED HELPER FUNCTIONS - Imported from Layout.lua
-- Layout.lua loads before this file and exports these to ns.CDMGroups
-- ═══════════════════════════════════════════════════════════════════════════

-- Local aliases for frequently used helpers (avoids table lookups in hot paths)
-- Use cached versions from Shared to avoid DB lookups on every call
local Shared = ns.CDMShared

-- ═══════════════════════════════════════════════════════════════════════════
-- MODULE-LEVEL CACHED ENABLED STATE
-- Direct boolean check - NO function call overhead
-- Updated by RefreshCachedEnabledState() on settings change
-- ═══════════════════════════════════════════════════════════════════════════
local _cdmGroupsEnabled = true  -- Module-level boolean, assume enabled until init

-- Refresh the cached enabled state (call on profile change or settings toggle)
local function RefreshCachedEnabledState()
    local db = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
    _cdmGroupsEnabled = db and db.enabled ~= false
    -- Also sync Shared's cache
    if Shared and Shared.RefreshCachedEnabledState then
        Shared.RefreshCachedEnabledState()
    end
    -- Also sync DynamicLayout's cache
    if ns.CDMGroups.DynamicLayout and ns.CDMGroups.DynamicLayout.RefreshCachedEnabledState then
        ns.CDMGroups.DynamicLayout.RefreshCachedEnabledState()
    end
    -- Also sync FrameController's cache
    if ns.FrameController and ns.FrameController.RefreshCachedEnabledState then
        ns.FrameController.RefreshCachedEnabledState()
    end
end

-- Export for other modules to call when settings change
ns.CDMGroups = ns.CDMGroups or {}
ns.CDMGroups.RefreshCachedEnabledState = RefreshCachedEnabledState

local function ShouldDisableTooltips()
    return ns.CDMGroups.ShouldDisableTooltips()
end

local function ShouldMakeClickThrough()
    return ns.CDMGroups.ShouldMakeClickThrough()
end

local function ApplyClickThrough(frame, enable)
    return ns.CDMGroups.ApplyClickThrough(frame, enable)
end

-- FORWARD DECLARATION: GetProfileSavedPositions is defined later but needed early
-- Actual implementation is in the PROFILE MANAGEMENT section (~line 2343)
local GetProfileSavedPositions

-- HELPER FUNCTIONS (defined early for use throughout)

-- Clamp value between min and max
local function Clamp(val, minVal, maxVal)
    if val == nil then return minVal end
    return math.max(minVal, math.min(val, maxVal))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE MANAGEMENT - Delegated to StateManager module
-- ═══════════════════════════════════════════════════════════════════════════
-- These functions are now implemented in ArcUI_CDMGroups_StateManager.lua
-- We keep local references for backward compatibility and performance

local function IsRestoring()
    if ns.CDMGroups.StateManager and ns.CDMGroups.StateManager.IsRestoring then
        return ns.CDMGroups.StateManager.IsRestoring()
    end
    -- Fallback if StateManager not loaded yet
    return ns.CDMGroups.initialLoadInProgress 
        or ns.CDMGroups.specChangeInProgress 
        or ns.CDMGroups.talentChangeInProgress
        or ns.CDMGroups.profileLoadInProgress
end
ns.CDMGroups.IsRestoring = IsRestoring

local function IsRestorationComplete()
    if ns.CDMGroups.StateManager and ns.CDMGroups.StateManager.IsRestorationComplete then
        return ns.CDMGroups.StateManager.IsRestorationComplete()
    end
    return true  -- Fallback
end

local function CheckRestorationComplete()
    if ns.CDMGroups.StateManager and ns.CDMGroups.StateManager.CheckRestorationComplete then
        return ns.CDMGroups.StateManager.CheckRestorationComplete()
    end
end

-- Print with addon prefix
local function PrintMsg(msg)
    print(MSG_PREFIX .. msg)
end
ns.CDMGroups.PrintMessage = PrintMsg  -- Export for StateManager

-- Safely get cooldownID from a frame (returns nil on error)
-- Safely get cooldownID from a frame (returns nil on error)
local function SafeGetFrameCooldownID(frame)
    if not frame then return nil end
    local ok, cdID = pcall(function() return frame.cooldownID end)
    return ok and cdID or nil
end
ns.CDMGroups.SafeGetFrameCooldownID = SafeGetFrameCooldownID

-- Check if a member has a valid frame with matching cooldownID
local function HasValidFrame(member, cdID)
    if not member or not member.frame then return false end
    return SafeGetFrameCooldownID(member.frame) == cdID
end
ns.CDMGroups.HasValidFrame = HasValidFrame

-- Check if frame is hidden by bar tracking (with cooldownID verification)
-- Uses CDMEnhance.IsFrameHiddenByBar when available, falls back to raw flag check
local function IsFrameHiddenByBar(frame)
    if not frame then return false end
    if ns.CDMEnhance and ns.CDMEnhance.IsFrameHiddenByBar then
        return ns.CDMEnhance.IsFrameHiddenByBar(frame)
    end
    return frame._arcHiddenByBar == true
end

-- Safe wrapper for EnhanceFrame - SKIPS during restoration to prevent orphaned borders
-- Borders should only be applied AFTER frames have settled into their final positions
local function SafeEnhanceFrame(frame, cdID, viewerType, viewerName)
    -- GUARD: Skip string IDs (Arc Auras) - CDMEnhance only handles numeric cooldownIDs
    if type(cdID) ~= "number" then
        return
    end
    
    -- Use StateManager to check if we're in a protection window
    if ns.CDMGroups.StateManager and ns.CDMGroups.StateManager.IsInAnyProtection then
        if ns.CDMGroups.StateManager.IsInAnyProtection() then
            return
        end
    elseif IsRestoring() then
        -- Fallback to IsRestoring if StateManager not ready
        return
    end
    -- Call the actual EnhanceFrame
    if ns.CDMEnhance and ns.CDMEnhance.EnhanceFrame then
        ns.CDMEnhance.EnhanceFrame(frame, cdID, viewerType, viewerName)
    end
end
ns.CDMGroups.SafeEnhanceFrame = SafeEnhanceFrame

-- ═══════════════════════════════════════════════════════════════════════════
-- LAYOUT HELPERS - MOVED TO ArcUI_CDMGroups_Layout.lua
-- GetSlotDimensions, SetupFrameInContainer, RefreshIconSettings,
-- OnIconSizeChanged, RefreshAllGroupLayouts are now in Layout.lua
-- ═══════════════════════════════════════════════════════════════════════════

-- Local references to Layout.lua exports (Layout.lua loads before this file)
local GetSlotDimensions = function(layout)
    return ns.CDMGroups.GetSlotDimensions(layout)
end
local SetupFrameInContainer = function(frame, container, slotW, slotH, cooldownID)
    return ns.CDMGroups.SetupFrameInContainer(frame, container, slotW, slotH, cooldownID)
end

-- Ensure per-spec tables exist
local function EnsureSpecTables(specIndex)
    -- If specIndex is nil, try to get current spec
    if not specIndex then
        -- GetCurrentSpec may not be defined yet during early load, so inline the logic
        local specIdx = GetSpecialization() or 1
        local _, _, classID = UnitClass("player")
        classID = classID or 0
        specIndex = "class_" .. classID .. "_spec_" .. specIdx
    end
    if not ns.CDMGroups.specGroups[specIndex] then ns.CDMGroups.specGroups[specIndex] = {} end
    -- NOTE: Do NOT create empty specSavedPositions here!
    -- The profile.savedPositions table will be established by SetSpecShortcuts or Initialize
    -- Creating an empty table here would create an orphan that's not connected to the profile
    if not ns.CDMGroups.specFreeIcons[specIndex] then ns.CDMGroups.specFreeIcons[specIndex] = {} end
    return specIndex  -- Return the spec key used
end

-- Update shortcuts to point to current spec
-- CRITICAL: This must preserve the direct reference to profile.savedPositions!
local function SetSpecShortcuts(specIndex)
    ns.CDMGroups.groups = ns.CDMGroups.specGroups[specIndex]
    ns.CDMGroups.freeIcons = ns.CDMGroups.specFreeIcons[specIndex]
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL FIX: ALWAYS get savedPositions from the profile
    -- This ensures we never point to an orphan table
    -- GetProfileSavedPositions handles all the logic and syncs the reference
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.CDMGroups.GetProfileSavedPositions then
        -- This sets ns.CDMGroups.savedPositions and specSavedPositions[specIndex]
        ns.CDMGroups.GetProfileSavedPositions(specIndex)
    else
        -- Fallback for very early calls before GetProfileSavedPositions is defined
        -- Try to get the profile table directly to avoid creating orphan table
        local specData = ns.CDMGroups.GetSpecData and ns.CDMGroups.GetSpecData(specIndex)
        local profile = nil
        if specData and specData.layoutProfiles then
            local activeProfileName = specData.activeProfile or "Default"
            profile = specData.layoutProfiles[activeProfileName]
            if profile then
                if not profile.savedPositions then
                    profile.savedPositions = {}
                end
                ns.CDMGroups.specSavedPositions[specIndex] = profile.savedPositions
                ns.CDMGroups.savedPositions = profile.savedPositions
                return
            end
        end
        
        -- Last resort fallback - only if we can't get profile at all
        -- This creates an orphan table but prevents crashes
        if not ns.CDMGroups.specSavedPositions[specIndex] then
            ns.CDMGroups.specSavedPositions[specIndex] = {}
            -- Log this so we can investigate if it happens
            if ns.CDMGroups.DebugPrint then
                ns.CDMGroups.DebugPrint("|cffff0000[SetSpecShortcuts]|r WARNING: Created orphan savedPositions table!")
            end
        end
        ns.CDMGroups.savedPositions = ns.CDMGroups.specSavedPositions[specIndex]
    end
end

-- Return a frame to CDM (cleanup before removal)
local function ReturnFrameToCDM(frame, entry)
    if not frame then return end
    
    -- CRITICAL: Skip Arc Aura frames - they're our own frames, not CDM frames
    -- Returning them to CDM hides them unexpectedly
    if frame._arcAuraID or (frame.cooldownID and type(frame.cooldownID) == "string" and tostring(frame.cooldownID):match("^arc_")) then
        return
    end
    
    pcall(function()
        -- CRITICAL: Clean up all drag state and custom properties
        -- These can cause issues if CDM reuses this frame for a different cooldownID
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:RegisterForDrag()  -- Unregister drag
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
        frame:SetScript("OnUpdate", nil)
        
        -- Clean up visual elements (borders, overlays, glows)
        -- Border edges extend outside frame bounds, must hide explicitly
        if frame._arcBorderEdges then
            if frame._arcBorderEdges.top then frame._arcBorderEdges.top:Hide() end
            if frame._arcBorderEdges.bottom then frame._arcBorderEdges.bottom:Hide() end
            if frame._arcBorderEdges.left then frame._arcBorderEdges.left:Hide() end
            if frame._arcBorderEdges.right then frame._arcBorderEdges.right:Hide() end
        end
        
        -- Hide text overlay
        if frame._arcTextOverlay then
            frame._arcTextOverlay:Hide()
        end
        
        -- Stop any glow effects
        if ns.CDMEnhance and ns.CDMEnhance.StopAllGlows then
            ns.CDMEnhance.StopAllGlows(frame)
        end
        
        -- Clear all our custom properties
        frame._groupDragging = nil
        frame._sourceGroup = nil
        frame._sourceCdID = nil
        frame._cdmgTargetPoint = nil
        frame._cdmgTargetRelPoint = nil
        frame._cdmgTargetX = nil
        frame._cdmgTargetY = nil
        frame._cdmgTargetSize = nil
        frame._cdmgSlotW = nil  -- Clear GROUP's slot dimensions
        frame._cdmgSlotH = nil
        frame._cdmgSettingPosition = nil
        frame._cdmgSettingScale = nil
        frame._cdmgSettingSize = nil
        frame._cdmgIsFreeIcon = nil  -- CRITICAL: Clear free icon flag so hooks don't fight
        frame.frameLostAt = nil
        
        -- Return to original parent
        frame:SetParent(entry and entry.originalParent or UIParent)
        frame:ClearAllPoints()
        frame:Hide()
    end)
    if entry then
        entry.manipulated = false
        entry.group = nil
    end
end
ns.CDMGroups.ReturnFrameToCDM = ReturnFrameToCDM

-- Per-spec storage (indexed by specIndex)
ns.CDMGroups.specGroups = {}         -- [specKey] = { groupName = groupObject, ... }
ns.CDMGroups.specSavedPositions = {} -- [specKey] = { cdID = positionData, ... }
ns.CDMGroups.specFreeIcons = {}      -- [specKey] = { cdID = freeIconData, ... }
ns.CDMGroups.currentSpec = nil       -- Set properly on PLAYER_ENTERING_WORLD (class-based key like "class_7_spec_2")

-- Layout Profile System (per-spec named profiles with optional talent conditions)
ns.CDMGroups.activeProfile = "Default"
ns.CDMGroups.profileLoadInProgress = false

-- Debug output buffer for copyable debug
ns.CDMGroups.debugBuffer = {}
ns.CDMGroups.debugEnabled = false

local function DebugPrint(...)
    if not ns.CDMGroups.debugEnabled then return end
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        parts[i] = tostring(v)
    end
    local msg = table.concat(parts, " ")
    print(msg)
    table.insert(ns.CDMGroups.debugBuffer, msg)
    -- Keep buffer to last 200 lines
    if #ns.CDMGroups.debugBuffer > 200 then
        table.remove(ns.CDMGroups.debugBuffer, 1)
    end
end

-- Create copyable debug output frame
local function CreateDebugFrame()
    if ns.CDMGroups.debugFrame then return ns.CDMGroups.debugFrame end
    
    local frame = CreateFrame("Frame", "ArcUIProfileDebugFrame", UIParent, "BackdropTemplate")
    frame:SetSize(700, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("TOOLTIP")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff00ccffArcUI|r - Profile Debug Output")
    
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(scrollFrame:GetWidth() - 20)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scrollFrame:SetScrollChild(editBox)
    
    frame.editBox = editBox
    
    local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearBtn:SetSize(80, 22)
    clearBtn:SetPoint("BOTTOMLEFT", 15, 15)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        wipe(ns.CDMGroups.debugBuffer)
        editBox:SetText("")
    end)
    
    local refreshBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshBtn:SetSize(80, 22)
    refreshBtn:SetPoint("LEFT", clearBtn, "RIGHT", 10, 0)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        editBox:SetText(table.concat(ns.CDMGroups.debugBuffer, "\n"))
    end)
    
    local selectAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectAllBtn:SetSize(80, 22)
    selectAllBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 10, 0)
    selectAllBtn:SetText("Select All")
    selectAllBtn:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    
    frame:Hide()
    ns.CDMGroups.debugFrame = frame
    return frame
end

-- Show debug output window
function ns.CDMGroups.ShowDebugOutput()
    local frame = CreateDebugFrame()
    -- Strip color codes for cleaner copy
    local cleanBuffer = {}
    for _, line in ipairs(ns.CDMGroups.debugBuffer) do
        local clean = line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        table.insert(cleanBuffer, clean)
    end
    frame.editBox:SetText(table.concat(cleanBuffer, "\n"))
    frame:Show()
    frame:Raise()
end

-- Slash command to show debug
SLASH_ARCUIDEBUG1 = "/arcuidebug"
SlashCmdList["ARCUIDEBUG"] = function(msg)
    if msg == "clear" then
        wipe(ns.CDMGroups.debugBuffer)
        print("|cff00ccffArcUI|r: Debug buffer cleared")
    elseif msg == "off" then
        ns.CDMGroups.debugEnabled = false
        print("|cff00ccffArcUI|r: Debug output disabled")
    elseif msg == "on" then
        ns.CDMGroups.debugEnabled = true
        print("|cff00ccffArcUI|r: Debug output enabled")
    elseif msg == "profiles" then
        -- Show all profiles for all specs
        print("|cff00ccffArcUI|r: === All Saved Profiles ===")
        local db = GetCDMGroupsDB()
        if db and db.specData then
            for specKey, data in pairs(db.specData) do
                local charName = data.characterName or "Unknown"
                local isCurrent = (specKey == ns.CDMGroups.currentSpec) and " |cff00ff00(CURRENT)|r" or ""
                print("|cffffff00" .. specKey .. "|r - " .. charName .. isCurrent)
                -- Show profiles
                if data.layoutProfiles then
                    for profileName, profileData in pairs(data.layoutProfiles) do
                        local groupCount = 0
                        if profileData.groupLayouts then
                            for _ in pairs(profileData.groupLayouts) do groupCount = groupCount + 1 end
                        end
                        local hasData = groupCount > 0 and "|cff00ff00" or "|cffff0000"
                        print("    " .. hasData .. profileName .. "|r - " .. groupCount .. " groups in groupLayouts")
                    end
                else
                    print("    |cff888888No layoutProfiles table|r")
                end
            end
        else
            print("|cffff0000No spec data found|r")
        end
    elseif msg == "template" or msg == "linked" then
        -- Show linked template status
        print("|cff00ccffArcUI|r: === Linked Template Status ===")
        local specData = ns.CDMGroups.GetSpecData and ns.CDMGroups.GetSpecData()
        if specData then
            print("  Current spec: |cffffff00" .. (ns.CDMGroups.currentSpec or "nil") .. "|r")
            print("  loadedTemplateName: |cffffff00" .. (specData.loadedTemplateName or "nil") .. "|r")
            print("  linkedTemplateName: |cffffff00" .. (specData.linkedTemplateName or "nil") .. "|r")
            if specData.linkedTemplateName then
                print("  |cffff6666WARNING: Linked template is set!|r")
                print("  Use |cffffff00/arcuidebug unlink|r to remove the link")
            end
        else
            print("  |cffff0000No spec data|r")
        end
    elseif msg == "unlink" then
        -- Remove linked template
        local specData = ns.CDMGroups.GetSpecData and ns.CDMGroups.GetSpecData()
        if specData then
            if specData.linkedTemplateName then
                print("|cff00ccffArcUI|r: Removed linked template '" .. specData.linkedTemplateName .. "'")
                specData.linkedTemplateName = nil
            else
                print("|cff00ccffArcUI|r: No linked template to remove")
            end
        end
    elseif msg == "positions" or msg == "saved" then
        -- Show savedPositions
        print("|cff00ccffArcUI|r: === RUNTIME Saved Positions ===")
        local count = 0
        for cdID, pos in pairs(ns.CDMGroups.savedPositions or {}) do
            count = count + 1
            if pos.type == "group" then
                print("  " .. cdID .. " -> |cffffff00" .. pos.target .. "|r [" .. (pos.row or "?") .. "," .. (pos.col or "?") .. "]")
            elseif pos.type == "free" then
                print("  " .. cdID .. " -> |cff00ff00FREE|r (" .. math.floor(pos.x or 0) .. ", " .. math.floor(pos.y or 0) .. ")")
            end
        end
        print("  Total runtime: " .. count .. " positions")
        
        -- Also show DB savedPositions
        print("|cff00ccffArcUI|r: === DATABASE Saved Positions ===")
        local specData = ns.CDMGroups.GetSpecData and ns.CDMGroups.GetSpecData()
        if specData and specData.savedPositions then
            local dbCount = 0
            for cdID, pos in pairs(specData.savedPositions) do
                dbCount = dbCount + 1
                if dbCount <= 10 then  -- Only show first 10
                    if pos.type == "group" then
                        print("  " .. cdID .. " -> |cffffff00" .. pos.target .. "|r [" .. (pos.row or "?") .. "," .. (pos.col or "?") .. "]")
                    elseif pos.type == "free" then
                        print("  " .. cdID .. " -> |cff00ff00FREE|r")
                    end
                end
            end
            if dbCount > 10 then
                print("  ... and " .. (dbCount - 10) .. " more")
            end
            print("  Total in DB: " .. dbCount .. " positions")
        else
            print("  |cffff0000No savedPositions in DB|r")
        end
    elseif msg == "db" then
        -- Show database structure
        print("|cff00ccffArcUI|r: === Database Structure ===")
        print("  ns.db exists:", ns.db ~= nil)
        if ns.db then
            print("  ns.db.char exists:", ns.db.char ~= nil)
            if ns.db.char then
                print("  ns.db.char.cdmGroups exists:", ns.db.char.cdmGroups ~= nil)
                if ns.db.char.cdmGroups then
                    local db = ns.db.char.cdmGroups
                    print("  db.specData exists:", db.specData ~= nil)
                    if db.specData then
                        local specCount = 0
                        for specKey, data in pairs(db.specData) do
                            specCount = specCount + 1
                            local posCount = data.savedPositions and 0 or -1
                            if data.savedPositions then
                                for _ in pairs(data.savedPositions) do posCount = posCount + 1 end
                            end
                            local isCurrent = specKey == ns.CDMGroups.currentSpec and " |cff00ff00(CURRENT)|r" or ""
                            print("    " .. specKey .. ": " .. posCount .. " positions" .. isCurrent)
                        end
                        print("  Total specs:", specCount)
                    end
                end
            end
        end
    elseif msg == "dbcheck" then
        -- Detailed check of database state for debugging persistence issues
        print("|cff00ccffArcUI|r: === Database Persistence Check ===")
        
        -- Get character key
        local charKey = UnitName("player") .. " - " .. GetRealmName()
        print("|cffffff00Character Key:|r " .. charKey)
        
        -- Check ArcUIDB directly (we bypass AceDB for cdmGroups)
        print("|cffffff00Step 1:|r ArcUIDB = " .. tostring(ArcUIDB ~= nil))
        if not ArcUIDB then
            print("  |cffff0000CRITICAL: ArcUIDB is nil! SavedVariables not loaded.|r")
            return
        end
        
        print("|cffffff00Step 2:|r ArcUIDB.char = " .. tostring(ArcUIDB.char ~= nil))
        if not ArcUIDB.char then
            print("  |cffff8800WARNING: ArcUIDB.char is nil (first load?)|r")
        end
        
        print("|cffffff00Step 3:|r ArcUIDB.char[charKey] = " .. tostring(ArcUIDB.char and ArcUIDB.char[charKey] ~= nil))
        
        -- Check cdmGroups via direct access
        local dbCdmGroups = ArcUIDB.char and ArcUIDB.char[charKey] and ArcUIDB.char[charKey].cdmGroups
        print("|cffffff00Step 4:|r cdmGroups = " .. tostring(dbCdmGroups ~= nil))
        if dbCdmGroups then
            print("  firstInitialized = " .. tostring(dbCdmGroups.firstInitialized))
            print("  migratedFromProfile = " .. tostring(dbCdmGroups.migratedFromProfile))
            print("  specData = " .. tostring(dbCdmGroups.specData ~= nil))
            if dbCdmGroups.specData then
                local specCount = 0
                for k, v in pairs(dbCdmGroups.specData) do
                    specCount = specCount + 1
                    print("    |cff88ff88" .. k .. "|r = table with " .. (v.createdAt and "createdAt=" .. v.createdAt or "NO createdAt"))
                end
                print("  Total spec entries: " .. specCount)
                if specCount == 0 then
                    print("  |cffff8800WARNING: specData is empty!|r")
                end
            else
                print("  |cffff0000CRITICAL: specData is nil!|r")
            end
        else
            print("  |cffff8800cdmGroups not created yet (run GetCDMGroupsDB first)|r")
        end
        
        -- Check GetCDMGroupsDB result
        local dbFromFunc = GetCDMGroupsDB()
        print("|cffffff00Step 5:|r GetCDMGroupsDB() = " .. tostring(dbFromFunc ~= nil))
        if dbFromFunc then
            local expectedDB = ArcUIDB.char and ArcUIDB.char[charKey] and ArcUIDB.char[charKey].cdmGroups
            print("  Same as ArcUIDB.char[key].cdmGroups? " .. tostring(dbFromFunc == expectedDB))
            if dbFromFunc ~= expectedDB then
                print("  |cffff0000CRITICAL: GetCDMGroupsDB returns DIFFERENT table!|r")
            else
                print("  |cff00ff00GOOD: References match - writes will persist!|r")
            end
        end
        
        -- Check currentSpec
        print("|cffffff00Step 6:|r currentSpec = " .. tostring(ns.CDMGroups.currentSpec))
        
        -- Check if spec data exists for current spec
        if ns.CDMGroups.currentSpec and dbFromFunc and dbFromFunc.specData then
            local specData = dbFromFunc.specData[ns.CDMGroups.currentSpec]
            print("|cffffff00Step 7:|r specData[currentSpec] = " .. tostring(specData ~= nil))
            if specData then
                print("  createdAt = " .. tostring(specData.createdAt))
                print("  activeProfile = " .. tostring(specData.activeProfile))
                print("  layoutProfiles = " .. tostring(specData.layoutProfiles ~= nil))
                if specData.layoutProfiles then
                    for pName, pData in pairs(specData.layoutProfiles) do
                        local posCount = pData.savedPositions and 0 or -1
                        if pData.savedPositions then
                            for _ in pairs(pData.savedPositions) do posCount = posCount + 1 end
                        end
                        print("    |cff88ff88" .. pName .. "|r: " .. posCount .. " positions, createdAt=" .. tostring(pData.createdAt))
                    end
                end
            end
        end
        
        print("|cff00ff00=== End Database Check ===|r")
    else
        ns.CDMGroups.ShowDebugOutput()
    end
end

-- Current spec shortcuts (updated on spec change)
ns.CDMGroups.groups = {}
ns.CDMGroups.savedPositions = {}
ns.CDMGroups.freeIcons = {}

ns.CDMGroups.trackedFrames = {}
ns.CDMGroups.dragModeEnabled = false
ns.CDMGroups.cooldownCatalog = {}
ns.CDMGroups.selectedGroup = "Buffs"
ns.CDMGroups.blockGridExpansion = false
ns.CDMGroups.specChangeInProgress = false
ns.CDMGroups.talentChangeInProgress = false
ns.CDMGroups.profileLoadInProgress = false  -- Block saves during profile load
ns.CDMGroups.initialLoadInProgress = true  -- Block saves until initial load completes
ns.CDMGroups._profileNotLoaded = true  -- Profile positions not loaded yet - don't force save
ns.CDMGroups.inCombat = false  -- Track combat state for visibility
ns.CDMGroups.isMounted = false  -- Track mounted state for visibility
ns.CDMGroups.fightStats = { parent = 0, strata = 0, scale = 0, size = 0, show = 0, alpha = 0, position = 0, lastReport = 0 }

-- NOTE: Hook functions moved to ArcUI_CDMGroups_Maintain.lua
-- Access via ns.CDMGroups.HookFrame, ns.CDMGroups.HookFrameScale, etc.

-- Forward declarations for local functions used across the file
local DeepCopy, GetCurrentSpec, GetSpecData, GetDefaultSpecData, EnsureSpecData
local SavePositionToSpec, ClearPositionFromSpec, SaveFreeIconToSpec, ClearFreeIconFromSpec
local GetCDMGroupsDB  -- Helper to access character-specific CDMGroups database

local defaults = {
    char = {
        -- CHARACTER-SPECIFIC per-spec data storage
        -- Each character has their own spec layouts (not shared across alts)
        cdmGroups = {
            specData = {},              -- [specKey] = { groups, savedPositions, freeIcons, layoutProfiles }
            specInheritedFrom = {},     -- Track which specs inherited from others
            lastActiveSpec = nil,       -- Last active spec key
            migratedOldKeys = {},       -- Track migrated numeric keys
            migratedFromProfile = false, -- Track if we migrated from profile storage
            -- Settings
            enabled = true,
            showBorderInEditMode = true,  -- Show borders when options panel is open (helps users see groups)
            showControlButtons = true,
            disableTooltips = false,
            clickThrough = false,
        },
    },
    profile = {
        -- Legacy profile storage (for migration only)
        -- New data goes to char.cdmGroups
        cdmGroups = nil,  -- Will be migrated to char on first load
    },
}

-- Default group templates (used for new specs)
-- Groups are stacked vertically in the center of the screen
local function MakeDefaultGroup(x, y, borderR, borderG, borderB)
    return {
        enabled = true,
        position = { x = x, y = y },
        showBorder = false,
        showBackground = false,
        autoReflow = true,
        lockGridSize = false,
        containerPadding = -4,  -- Padding around icons in container (-4 = tight/internal, 0 = compact, 4 = classic)
        visibility = "always",  -- "always", "combat" (In Combat Only), or "ooc" (Out of Combat Only)
        borderColor = { r = borderR, g = borderG, b = borderB, a = 1 },
        bgColor = { r = 0, g = 0, b = 0, a = 0.6 },
        layout = { 
            direction = "HORIZONTAL", 
            spacing = 2, 
            spacingX = nil, 
            spacingY = nil, 
            iconSize = 36,      -- Scale factor (36 = 100%)
            iconWidth = 36,     -- Base width in pixels
            iconHeight = 36,    -- Base height in pixels
            perRow = 4, 
            gridRows = 2, 
            gridCols = 4,
        },
        members = {},
        grid = {},
    }
end

-- Default positions: stacked vertically in the center of the screen
-- Buffs at top (y=200), Essential in middle (y=100), Utility at bottom (y=0)
local DEFAULT_GROUPS = {
    Buffs = MakeDefaultGroup(0, 200, 0.3, 0.8, 0.3),
    Essential = MakeDefaultGroup(0, 100, 0.8, 0.6, 0.2),
    Utility = MakeDefaultGroup(0, 0, 0.3, 0.6, 0.9),
}

-- Export DEFAULT_GROUPS for use by ImportExport repair logic
ns.CDMGroups.DEFAULT_GROUPS = DEFAULT_GROUPS

-- Helper: Convert a DEFAULT_GROUPS template to layoutData format for profile storage
-- This ensures consistent serialization across ResetDefaultProfile, EnsureLayoutProfiles, LoadProfile
local function SerializeDefaultGroupToLayoutData(groupData)
    return {
        -- Grid settings
        gridRows = groupData.layout and groupData.layout.gridRows or 2,
        gridCols = groupData.layout and groupData.layout.gridCols or 4,
        -- Position
        position = groupData.position and { x = groupData.position.x, y = groupData.position.y },
        -- Layout settings
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
        -- Appearance
        showBorder = groupData.showBorder or false,
        showBackground = groupData.showBackground or false,
        autoReflow = groupData.autoReflow ~= false,  -- Default true, user can disable
        dynamicLayout = groupData.dynamicLayout or false,
        lockGridSize = groupData.lockGridSize or false,
        containerPadding = groupData.containerPadding or -4,
        borderColor = groupData.borderColor and DeepCopy(groupData.borderColor),
        bgColor = groupData.bgColor and DeepCopy(groupData.bgColor),
        -- Visibility
        visibility = groupData.visibility or "always",
    }
end

-- Export for use by ImportExport
ns.CDMGroups.SerializeDefaultGroupToLayoutData = SerializeDefaultGroupToLayoutData

-- Use shared CDM constants (from ArcUI_CDM_Shared.lua)
local Shared = ns.CDMShared
local CDM_VIEWERS = Shared.CDM_VIEWERS
local GROUP_COLORS = Shared.GROUP_COLORS
ns.CDMGroups.CDM_VIEWERS = CDM_VIEWERS  -- Export for external access

-- ═══════════════════════════════════════════════════════════════════════════
-- REGISTRY, SCANNING, AND CATALOG - MOVED TO CDMGroups_Registry.lua
-- The following have been extracted to a separate file:
--   - ns.FrameRegistry (frame tracking by address/cooldownID/viewer)
--   - Registry:Register, GetEntry, GetOrCreate, GetValidFrameForCooldownID
--   - Registry:GetSpellInfoForCooldownID, IsCooldownIDValidForCurrentSpec
--   - Registry:CleanupCooldownIDMappings, CleanupStaleEntries
--   - GetViewerTypeForCooldownID, GetViewerTypeFromName, IsViewerTypeEnabled
--   - ScanAllViewers, BuildCooldownCatalog
-- See: CDM_Module/CDM_Groups/ArcUI_CDMGroups_Registry.lua
-- ═══════════════════════════════════════════════════════════════════════════

-- Reference to Registry (loaded from CDMGroups_Registry.lua)
local Registry = ns.FrameRegistry

-- Local aliases for functions from Registry (for hot path performance)
local GetViewerTypeForCooldownID = function(cooldownID)
    return ns.CDMGroups.GetViewerTypeForCooldownID(cooldownID)
end

local GetViewerTypeFromName = function(viewerName)
    return ns.CDMGroups.GetViewerTypeFromName(viewerName)
end

local IsViewerTypeEnabled = function(viewerType)
    return ns.CDMGroups.IsViewerTypeEnabled(viewerType)
end


-- FREE ICONS

function ns.CDMGroups.TrackFreeIcon(cooldownID, x, y, iconSize, optionalFrame)
    -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
    if not _cdmGroupsEnabled then return end
    
    -- Try Registry first, but use optionalFrame as fallback (for Arc Auras)
    local frame, entry = Registry:GetValidFrameForCooldownID(cooldownID)
    if not frame and optionalFrame then
        frame = optionalFrame
    end
    
    -- Skip frames that are actual status bars (have Bar element) - these aren't icon-based
    if frame and frame.Bar and frame.Bar.IsObjectType and frame.Bar:IsObjectType("StatusBar") then return end
    
    iconSize = iconSize or 36
    
    -- Get viewerType before removing from group (use existing if we already have it)
    local viewerType, defaultGroup, viewerName = GetViewerTypeForCooldownID(cooldownID)
    
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.members[cooldownID] then
            -- Try to get viewerType from member before removing
            local member = group.members[cooldownID]
            if member.viewerType and not viewerType then
                viewerType = member.viewerType
                viewerName = member.originalViewerName
            end
            group:RemoveMember(cooldownID, true)
            break
        end
    end
    
    if not frame then
        if x and y then
            local posData = {
                type = "free",
                x = x,
                y = y,
                iconSize = iconSize,
            }
            -- Use GetProfileSavedPositions to ensure we write to correct table
            local profileSavedPositions = GetProfileSavedPositions()
            if profileSavedPositions then
                profileSavedPositions[cooldownID] = posData
            end
            SavePositionToSpec(cooldownID, posData)
        end
        return
    end
    
    if not entry then
        entry = Registry:GetOrCreate(frame, viewerName or "FreeIcon")
    end
    
    -- Get viewerType from entry if we still don't have it
    if not viewerType and entry and entry.viewerType then
        viewerType = entry.viewerType
        viewerName = entry.viewerName
    end
    
    entry.originalParent = entry.originalParent or frame:GetParent()
    
    if not x or not y then
        local cx, cy = frame:GetCenter()
        local ux, uy = UIParent:GetCenter()
        x = (cx or ux) - ux
        y = (cy or uy) - uy
    end
    
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    frame:SetFrameStrata("MEDIUM")
    frame:SetScale(1)
    
    -- Check for per-icon size settings: width/height as base, scale as multiplier
    -- NOTE: Free icons ALWAYS apply custom scale/width/height since they don't belong to a group
    local effectiveW = iconSize
    local effectiveH = iconSize
    if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
        local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cooldownID)
        if cfg then
            -- Use width/height as base (if set), otherwise use iconSize
            local baseW = cfg.width or iconSize
            local baseH = cfg.height or iconSize
            -- Apply scale as multiplier on top
            local scale = cfg.scale or 1.0
            effectiveW = baseW * scale
            effectiveH = baseH * scale
        end
    end
    frame:SetSize(effectiveW, effectiveH)
    
    -- CRITICAL: MUST show frame when tracking - CDMEnhance will handle inactive state LATER
    -- EXCEPT: Skip showing if frame is hidden due to hideWhenUnequipped setting
    if not frame._arcHiddenUnequipped and not IsFrameHiddenByBar(frame) then
        frame:SetAlpha(1)
        frame:Show()
    end
    frame._arcRecoveryProtection = GetTime() + 0.5
    
    ns.CDMGroups.freeIcons[cooldownID] = {
        frame = frame,
        entry = entry,
        originalParent = entry.originalParent,
        x = x,
        y = y,
        iconSize = iconSize,
        viewerType = viewerType,
        originalViewerName = viewerName,
    }
    
    -- Mark frame as free icon and store target size (for hooks)
    frame._cdmgIsFreeIcon = true
    frame._cdmgFreeTargetSize = iconSize
    
    -- CRITICAL: Notify CDMEnhance so it applies per-icon settings
    SafeEnhanceFrame(frame, cooldownID, viewerType, viewerName)
    
    -- Install hooks to fight CDM immediately (not just via maintainer)
    -- MUST be after freeIcons entry exists so hooks can find position data
    ns.CDMGroups.HookFrameScale(frame)
    ns.CDMGroups.HookFrameSize(frame, iconSize)
    ns.CDMGroups.HookFrameParent(frame)
    ns.CDMGroups.HookFrameClearAllPointsFree(frame)
    
    entry.manipulated = true
    entry.manipulationType = "free"
    
    local posData = {
        type = "free",
        x = x,
        y = y,
        iconSize = iconSize,
    }
    -- Use GetProfileSavedPositions to ensure we write to correct table
    local profileSavedPositions = GetProfileSavedPositions()
    if profileSavedPositions then
        profileSavedPositions[cooldownID] = posData
    end
    SavePositionToSpec(cooldownID, posData)
    SaveFreeIconToSpec(cooldownID, { x = x, y = y, iconSize = iconSize })
    
    -- Hide any placeholder for this cdID now that we have a real frame
    -- GUARD: Only for numeric IDs (Arc Auras use string IDs)
    if type(cooldownID) == "number" and ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.HidePlaceholder then
        ns.CDMGroups.Placeholders.HidePlaceholder(cooldownID)
    end
    
    -- Always set up handlers (for click-to-select functionality)
    ns.CDMGroups.SetupFreeIconDrag(cooldownID)
    
    -- Apply tooltip settings to free icon
    if ShouldDisableTooltips() then
        if not frame._arcOrigOnEnter then
            frame._arcOrigOnEnter = frame:GetScript("OnEnter")
        end
        if not frame._arcOrigOnLeave then
            frame._arcOrigOnLeave = frame:GetScript("OnLeave")
        end
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
    end
end

function ns.CDMGroups.SetupFreeIconDrag(cooldownID)
    local data = ns.CDMGroups.freeIcons[cooldownID]
    if not data or not data.frame then return end
    
    local frame = data.frame
    
    -- Helper to disable mouse on ALL descendants recursively
    local function DisableAllChildMouse(f)
        for _, child in pairs({f:GetChildren()}) do
            if child.EnableMouse then
                child:EnableMouse(false)
            end
            if child.SetMovable then
                child:SetMovable(false)
            end
            if child.RegisterForDrag then
                child:RegisterForDrag()
            end
            DisableAllChildMouse(child)
        end
    end
    
    -- CRITICAL: Disable mouse on ALL children FIRST
    DisableAllChildMouse(frame)
    
    -- Also explicitly disable known overlays
    if frame._arcOverlay then
        frame._arcOverlay:EnableMouse(false)
        frame._arcOverlay:SetMovable(false)
        frame._arcOverlay:RegisterForDrag()
        if frame._arcOverlay.highlight then frame._arcOverlay.highlight:Hide() end
        if frame._arcOverlay.dragText then frame._arcOverlay.dragText:Hide() end
    end
    if frame._arcTextOverlay then
        frame._arcTextOverlay:EnableMouse(false)
    end
    if frame.Applications then
        frame.Applications:EnableMouse(false)
    end
    
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    
    -- CLICK-THROUGH: Enable mouse if dragging is allowed (drag mode OR options panel open)
    if ns.CDMGroups.ShouldAllowDrag() then
        frame:EnableMouse(true)
        if frame.SetMouseClickThrough then
            frame:SetMouseClickThrough(false)
        end
    else
        ApplyClickThrough(frame, ShouldMakeClickThrough())
    end
    
    -- Create edit button if it doesn't exist (shows only when options panel is open)
    -- Small clean button at bottom
    if not frame._arcEditButton then
        local editBtn = CreateFrame("Button", nil, frame)
        editBtn:SetSize(20, 12)
        editBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, -2)
        editBtn:SetFrameLevel(frame:GetFrameLevel() + 100)
        editBtn:EnableMouse(true)  -- Ensure always clickable
        editBtn:RegisterForClicks("LeftButtonUp")  -- Register for clicks
        
        -- Dark semi-transparent background
        local bg = editBtn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.7)
        editBtn._bg = bg
        
        -- Yellow/gold text
        local editText = editBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        editText:SetPoint("CENTER", 0, 0)
        editText:SetText("Edit")
        editText:SetTextColor(1, 0.8, 0)  -- Gold text
        editText:SetFont(editText:GetFont(), 8, "OUTLINE")
        editBtn._text = editText
        
        editBtn:SetScript("OnClick", function(self)
            local cdID = frame.cooldownID
            if not cdID then return end
            
            -- Arc Auras have string IDs starting with "arc_" - treat as cooldowns
            if type(cdID) == "string" and cdID:match("^arc_") then
                if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
                    ns.CDMEnhanceOptions.SelectIcon(cdID, false)  -- false = cooldown type
                end
                return
            end
            
            -- Regular CDM icons - use API to determine type
            local iconData = ns.API and ns.API.GetCDMIcon(cdID)
            if iconData then
                local isAura = iconData.isAura
                if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
                    ns.CDMEnhanceOptions.SelectIcon(cdID, isAura)
                end
            end
        end)
        
        editBtn:SetScript("OnEnter", function(self)
            self._text:SetTextColor(1, 1, 0.3)  -- Brighter on hover
        end)
        editBtn:SetScript("OnLeave", function(self)
            self._text:SetTextColor(1, 0.8, 0)
        end)
        
        editBtn:Hide()  -- Start hidden, shown when options panel opens
        frame._arcEditButton = editBtn
        
        -- CRITICAL: If options panel is already open, show the button immediately
        -- (UpdateEditButtonVisibility cache may skip this new button)
        local ACD = LibStub("AceConfigDialog-3.0", true)
        if ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] then
            editBtn:Show()
        end
    else
        -- Edit button already exists - ensure visibility is correct
        -- (frame may have transitioned from group where button was hidden)
        ns.CDMGroups.UpdateSingleEditButton(frame)
    end
    
    -- Add click handler for icon selection
    -- OnDragStop handles drag completion separately
    frame:SetScript("OnMouseUp", function(self, button)
        local cdID = self.cooldownID
        if not cdID then return end
        
        -- If we were dragging, OnDragStop handles it - don't process as click
        if self._freeDragging then return end
        
        -- Check if options panel is open (REQUIRED for both right-click and left-click selection)
        local ACD = LibStub("AceConfigDialog-3.0", true)
        local optionsPanelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
        
        -- Only process clicks when options panel is open
        if not optionsPanelOpen then return end
        
        -- Left-click selects icon when drag mode is off
        if button == "LeftButton" and not ns.CDMGroups.dragModeEnabled then
            -- Arc Auras have string IDs starting with "arc_" - treat as cooldowns
            if type(cdID) == "string" and cdID:match("^arc_") then
                if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
                    ns.CDMEnhanceOptions.SelectIcon(cdID, false)  -- false = cooldown type
                end
                return
            end
            
            -- Regular CDM icons - use API to determine type
            local iconData = ns.API and ns.API.GetCDMIcon(cdID)
            if iconData then
                local isAura = iconData.isAura
                if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
                    ns.CDMEnhanceOptions.SelectIcon(cdID, isAura)
                end
            end
        end
    end)
    
    -- CRITICAL: Do NOT capture cooldownID in closure - read from frame at drag time
    frame:SetScript("OnDragStart", function(self)
        -- Allow drag when drag mode is on OR options panel is open
        if not ns.CDMGroups.ShouldAllowDrag() then return end
        
        -- Read cooldownID from frame at drag time
        local cdID = self.cooldownID
        if not cdID then return end
        
        -- Verify this is actually a tracked free icon
        if not ns.CDMGroups.freeIcons[cdID] or ns.CDMGroups.freeIcons[cdID].frame ~= self then
            return
        end
        
        self:StartMoving()
        self._freeDragging = true
        self._sourceCdID = cdID
        
        self:SetScript("OnUpdate", function(self)
            if self._freeDragging then
                local cx, cy = self:GetCenter()
                if cx and cy then
                    ns.CDMGroups.UpdateDropIndicator(cx, cy)
                end
            end
        end)
    end)
    
    frame:SetScript("OnDragStop", function(self)
        if self._freeDragging then
            self:StopMovingOrSizing()
            self._freeDragging = false
            self:SetScript("OnUpdate", nil)
            ns.CDMGroups.HideDropIndicator()
            
            local cx, cy = self:GetCenter()
            local ux, uy = UIParent:GetCenter()
            local newX, newY = cx - ux, cy - uy
            local cdID = self._sourceCdID
            
            -- Validate cdID
            if not cdID then
                self._sourceCdID = nil
                return
            end
            
            local targetGroup, targetRow, targetCol, mode, insertCol, insertRow = ns.CDMGroups.FindDropTarget(cx, cy)
            if targetGroup then
                -- CRITICAL: Save frame reference BEFORE ReleaseFreeIcon clears it
                -- Otherwise AddMemberAt/etc can't find the frame via Registry
                local freeData = ns.CDMGroups.freeIcons[cdID]
                local savedFrame = freeData and freeData.frame
                local savedEntry = freeData and freeData.entry
                ns.CDMGroups.ReleaseFreeIcon(cdID, true)
                if mode == "swap" then
                    -- SwapInMember calls AddMemberAt internally, which uses Registry
                    -- We need to pass frame directly, so use AddMemberAtWithFrame instead
                    -- First handle existing icon displacement (what SwapInMember does)
                    local existingCdID = targetGroup.grid[targetRow] and targetGroup.grid[targetRow][targetCol]
                    if existingCdID and existingCdID ~= cdID and targetGroup.members[existingCdID] then
                        local freeRow, freeCol = targetGroup:FindNextFreeSlot()
                        if freeRow then
                            targetGroup:PlaceMemberAt(existingCdID, freeRow, freeCol)
                        end
                    end
                    targetGroup:AddMemberAtWithFrame(cdID, targetRow, targetCol, savedFrame, savedEntry)
                elseif mode == "insert_row_above" then
                    targetGroup:InsertRowAt(insertRow)
                    targetGroup:AddMemberAtWithFrame(cdID, insertRow, targetCol, savedFrame, savedEntry)
                elseif mode == "insert_row_below" then
                    if insertRow >= targetGroup.layout.gridRows then
                        targetGroup:AddRowAtBottom()
                    else
                        targetGroup:InsertRowAt(insertRow)
                    end
                    targetGroup:AddMemberAtWithFrame(cdID, insertRow, targetCol, savedFrame, savedEntry)
                elseif mode == "insert_start" then
                    targetGroup:InsertColumnAt(0)
                    targetGroup:AddMemberAtWithFrame(cdID, targetRow, 0, savedFrame, savedEntry)
                elseif mode == "insert_end" then
                    local newCol = targetGroup.layout.gridCols
                    targetGroup:AddColumnAtEnd()
                    targetGroup:AddMemberAtWithFrame(cdID, targetRow, newCol, savedFrame, savedEntry)
                elseif mode == "insert" then
                    targetGroup:InsertMemberAtWithFrame(cdID, targetRow, insertCol, savedFrame, savedEntry)
                else
                    targetGroup:AddMemberAtWithFrame(cdID, targetRow, targetCol, savedFrame, savedEntry)
                end
            else
                self:ClearAllPoints()
                self:SetPoint("CENTER", UIParent, "CENTER", newX, newY)
                
                if ns.CDMGroups.freeIcons[cdID] then
                    ns.CDMGroups.freeIcons[cdID].x = newX
                    ns.CDMGroups.freeIcons[cdID].y = newY
                end
                local posData = {
                    type = "free",
                    x = newX,
                    y = newY,
                    iconSize = ns.CDMGroups.freeIcons[cdID] and ns.CDMGroups.freeIcons[cdID].iconSize or 36,
                }
                -- Use GetProfileSavedPositions to ensure we write to correct table
                local profileSavedPositions = GetProfileSavedPositions()
                if profileSavedPositions then
                    profileSavedPositions[cdID] = posData
                end
                SavePositionToSpec(cdID, posData)
                SaveFreeIconToSpec(cdID, { x = newX, y = newY, iconSize = ns.CDMGroups.freeIcons[cdID] and ns.CDMGroups.freeIcons[cdID].iconSize or 36 })
            end
            
            -- CRITICAL: Re-setup drag state and APPLY SIZE after move
            if cdID then
                -- Find which group now owns this cdID
                local newGroup = nil
                for _, g in pairs(ns.CDMGroups.groups) do
                    if g.members[cdID] then
                        newGroup = g
                        break
                    end
                end
                
                if newGroup and newGroup.members[cdID] then
                    local member = newGroup.members[cdID]
                    if member.frame then
                        -- CRITICAL: Apply correct size based on useGroupScale setting
                        local slotW, slotH = GetSlotDimensions(newGroup.layout)
                        local effectiveW = slotW
                        local effectiveH = slotH
                        
                        -- Check if this icon has custom scale (useGroupScale == false)
                        if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                            local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cdID)
                            if cfg and cfg.useGroupScale == false then
                                -- Custom scale: use width/height * scale
                                local baseW = cfg.width or slotW
                                local baseH = cfg.height or slotH
                                local iconScale = cfg.scale or 1.0
                                effectiveW = baseW * iconScale
                                effectiveH = baseH * iconScale
                            end
                        end
                        
                        member.frame._cdmgTargetSize = math.max(effectiveW, effectiveH)
                        member.frame._cdmgSlotW = slotW  -- Store GROUP's slot dimensions
                        member.frame._cdmgSlotH = slotH
                        member._effectiveIconW = effectiveW
                        member._effectiveIconH = effectiveH
                        member.frame._cdmgSettingSize = true
                        member.frame:SetSize(effectiveW, effectiveH)
                        member.frame._cdmgSettingSize = false
                        member.frame:SetScale(1)
                        
                        -- Trigger Masque refresh for new size
                        if ns.Masque and ns.Masque.QueueRefresh then
                            ns.Masque.QueueRefresh()
                        end
                        
                        -- Re-setup drag handlers if dragging is allowed
                        if ns.CDMGroups.ShouldAllowDrag() then
                            newGroup:SetupMemberDrag(cdID)
                        end
                    end
                elseif ns.CDMGroups.freeIcons[cdID] then
                    -- Still a free icon - setup drag if allowed
                    if ns.CDMGroups.ShouldAllowDrag() then
                        ns.CDMGroups.SetupFreeIconDrag(cdID)
                    end
                end
            end
            
            self._sourceCdID = nil
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXTERNAL FRAME REGISTRATION (for Arc Auras and other custom frames)
-- Allows external modules to register their frames for CDMGroups management
-- ═══════════════════════════════════════════════════════════════════════════

function ns.CDMGroups.RegisterExternalFrame(frameID, frame, viewerType, defaultGroup)
    -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
    if not _cdmGroupsEnabled then return false end
    
    if not frameID or not frame then return false end
    
    DebugPrint("|cff00ff00[RegisterExternalFrame]|r", frameID, viewerType, defaultGroup)
    
    -- Check if we have a saved position for this frame
    local saved = ns.CDMGroups.savedPositions[frameID]
    
    if saved then
        if saved.type == "group" and saved.target then
            -- Frame belongs to a group - add it
            local group = ns.CDMGroups.groups[saved.target]
            if group then
                local row = saved.row or 0
                local col = saved.col or 0
                
                -- Ensure within grid bounds
                if row >= group.layout.gridRows then row = group.layout.gridRows - 1 end
                if col >= group.layout.gridCols then col = group.layout.gridCols - 1 end
                
                -- Add to group
                local entry = Registry:GetOrCreate(frame, "ExternalFrame")
                entry.originalParent = entry.originalParent or frame:GetParent()
                
                -- Check if slot is available (or find free slot)
                if not group.grid[row] then group.grid[row] = {} end
                local targetRow, targetCol = row, col
                if group.grid[row][col] and group.grid[row][col] ~= frameID then
                    -- Slot occupied, find free slot
                    local found = false
                    for r = 0, group.layout.gridRows - 1 do
                        for c = 0, group.layout.gridCols - 1 do
                            if not group.grid[r] then group.grid[r] = {} end
                            if not group.grid[r][c] then
                                targetRow, targetCol = r, c
                                found = true
                                break
                            end
                        end
                        if found then break end
                    end
                    if not found then
                        -- No room, track as free instead
                        local cx, cy = frame:GetCenter()
                        local ux, uy = UIParent:GetCenter()
                        local x = (cx or ux) - ux
                        local y = (cy or uy) - uy
                        ns.CDMGroups.TrackFreeIcon(frameID, x, y, 36)
                        return true
                    end
                end
                
                -- Setup frame in container
                local slotW, slotH = GetSlotDimensions(group.layout)
                local effectiveW, effectiveH = SetupFrameInContainer(frame, group.container, slotW, slotH, frameID)
                
                -- Create member entry
                group.members[frameID] = {
                    frame = frame,
                    entry = entry,
                    row = targetRow,
                    col = targetCol,
                    viewerType = viewerType or "cooldown",
                    defaultGroup = defaultGroup or group.name,
                    _effectiveIconW = effectiveW,
                    _effectiveIconH = effectiveH,
                }
                group.grid[targetRow][targetCol] = frameID
                
                entry.manipulated = true
                entry.group = group
                
                -- Show frame
                frame:SetAlpha(1)
                frame:Show()
                
                -- Setup drag if dragging is allowed
                if ns.CDMGroups.ShouldAllowDrag() then
                    group:SetupMemberDrag(frameID)
                end
                
                -- Apply visual settings
                SafeEnhanceFrame(frame, frameID, viewerType, "ExternalFrame")
                
                -- Layout
                group:Layout()
                
                DebugPrint("|cff00ff00[RegisterExternalFrame]|r Added", frameID, "to group", saved.target, "at", targetRow, targetCol)
                return true
            end
        elseif saved.type == "free" then
            -- Track as free icon
            ns.CDMGroups.TrackFreeIcon(frameID, saved.x, saved.y, saved.iconSize or 36)
            DebugPrint("|cff00ff00[RegisterExternalFrame]|r Tracked", frameID, "as free at", saved.x, saved.y)
            return true
        end
    end
    
    -- No saved position - track as free icon at current position
    -- This gives the frame CDMGroups drag handlers so it can be dropped into groups
    local cx, cy = frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    local x = (cx or ux) - ux
    local y = (cy or uy) - uy
    local iconSize = 36
    
    -- Get size from frame if available
    local w, h = frame:GetSize()
    if w and w > 0 then
        iconSize = math.max(w, h or w)
    end
    
    DebugPrint("|cff00ff00[RegisterExternalFrame]|r", frameID, "no saved position, tracking as free icon at", x, y)
    ns.CDMGroups.TrackFreeIcon(frameID, x, y, iconSize, frame)
    return true
end

function ns.CDMGroups.UnregisterExternalFrame(frameID)
    if not frameID then return end
    
    DebugPrint("|cffff9900[UnregisterExternalFrame]|r", frameID)
    
    -- Remove from any group
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        if group.members and group.members[frameID] then
            local member = group.members[frameID]
            if member.frame and member.entry then
                ReturnFrameToCDM(member.frame, member.entry)
            end
            if group.grid[member.row] and group.grid[member.row][member.col] == frameID then
                group.grid[member.row][member.col] = nil
            end
            group.members[frameID] = nil
            group:MarkGridDirty()
            DebugPrint("|cffff9900[UnregisterExternalFrame]|r Removed", frameID, "from group", groupName)
            break
        end
    end
    
    -- Remove from free icons
    if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[frameID] then
        local data = ns.CDMGroups.freeIcons[frameID]
        if data.frame then
            data.frame._cdmgIsFreeIcon = nil
        end
        ns.CDMGroups.freeIcons[frameID] = nil
        DebugPrint("|cffff9900[UnregisterExternalFrame]|r Removed", frameID, "from free icons")
    end
    
    -- NOTE: We keep savedPositions so the position is remembered if the frame is re-added
end

-- Check if ArcUI options panel is currently open
-- Check if ANY options panel is open (ArcUI or CDM)
-- When either panel is open, we should show gaps (no reflow)
-- This is the SINGLE SOURCE OF TRUTH for all reflow decisions
function ns.CDMGroups.IsOptionsPanelOpen()
    -- Check ArcUI options panel (uses cached value from Shared - cheap!)
    local arcUIOpen = Shared.IsOptionsPanelOpen()
    
    -- Check CDM options panel (CooldownViewerSettings) - use cached value, skip expensive IsShown()
    -- The cdmOptionsPanelOpen flag is updated by hooks on Show/Hide events
    local cdmOpen = ns.CDMGroups.cdmOptionsPanelOpen
    
    -- Check Blizzard Edit Mode - when Edit Mode is open, CDM refreshes all frames
    -- which fires aura hooks and causes pixel positioning during what should be grid mode.
    -- Treating Edit Mode as "panel open" disables pixel positioning and hooks.
    local blizzEditMode = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
    
    return arcUIOpen or cdmOpen or blizzEditMode
end

-- Separate check for just ArcUI panel (for edit mode features like edit buttons)
-- NOTE: This does a DIRECT check, not cached, to avoid stale values after panel closes
function ns.CDMGroups.IsArcUIOptionsPanelOpen()
    local ACD = LibStub("AceConfigDialog-3.0", true)
    return ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] and true or false
end

-- Check if dragging should be allowed
-- Dragging is allowed when EITHER drag mode is enabled OR options panel is open
function ns.CDMGroups.ShouldAllowDrag()
    if ns.CDMGroups.dragModeEnabled then return true end
    -- Allow dragging when options panel is open (for easy icon arrangement)
    -- NOTE: Uses DIRECT check, not cached
    return ns.CDMGroups.IsArcUIOptionsPanelOpen()
end

-- Restore icons to their saved grid positions (for editing mode)
-- This bypasses alignment so user can see the actual layout with gaps
-- NOTE: When options panel is OPEN, we just restore positions directly (no Reconcile)
--       When options panel is CLOSED, we delegate to FrameController.Reconcile
function ns.CDMGroups.RestoreIconsToSavedPositions()
    -- Skip during spec changes
    if ns.CDMGroups.specChangeInProgress then return end
    if ns.CDMGroups._pendingSpecChange then return end
    -- Skip during restoration protection window
    if ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd then
        return
    end
    -- Skip during 5-second restoration period
    if IsRestoring() then return end
    
    -- CRITICAL: When options panel is OPEN, don't trigger Reconcile
    -- Just restore positions directly without any reflow scheduling
    local panelOpen = ns.CDMGroups.IsOptionsPanelOpen and ns.CDMGroups.IsOptionsPanelOpen()
    
    if panelOpen then
        -- Panel is open - just restore positions, no reflow
        for gName, group in pairs(ns.CDMGroups.groups or {}) do
            if group.RestoreToSavedPositions then
                group:RestoreToSavedPositions()
            end
            -- Layout WITHOUT reflow
            if group.Layout then
                group._reflowing = true
                group:Layout()
                group._reflowing = false
            end
        end
        return
    end
    
    -- Panel is closed - use FrameController if available
    if _G.ARCUI_USE_FRAME_CONTROLLER and ns.FrameController and ns.FrameController.Reconcile then
        ns.FrameController.Reconcile()
        return
    end
    
    -- Fallback: Direct group restore
    for gName, group in pairs(ns.CDMGroups.groups or {}) do
        if group.autoReflow and group.RestoreToSavedPositions then
            -- Use the group's RestoreToSavedPositions which properly handles grid rebuild
            group:RestoreToSavedPositions()
            
            -- Re-layout without reflow (set flag to prevent recursion)
            group._reflowing = true
            group:Layout()
            group._reflowing = false
        end
    end
end

-- Reflow all autoReflow groups (called when options panel or CDM panel closes)
function ns.CDMGroups.ReflowAllGroups()
    -- Skip during spec changes
    if ns.CDMGroups.specChangeInProgress then return end
    if ns.CDMGroups._pendingSpecChange then return end
    -- Skip during restoration protection window
    if ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd then
        return
    end
    -- Skip during 2-second restoration period
    if IsRestoring() then return end
    
    for gName, group in pairs(ns.CDMGroups.groups or {}) do
        if group.autoReflow then
            group:ReflowIcons()
        end
    end
end

-- Track panel state for open/close transitions
ns.CDMGroups._optionsPanelWasOpen = false

-- Update visibility of edit buttons on all icons
-- NOTE: State transitions (reflow on close, restore on open) are handled by FrameController
-- Cache for edit button visibility state (avoid redundant Show/Hide calls)
local lastEditButtonState = nil

-- Invalidate cache to force next UpdateEditButtonVisibility to run
-- Call this when frames transition between groups/free positions
function ns.CDMGroups.InvalidateEditButtonCache()
    lastEditButtonState = nil
end

-- Update a single frame's edit button visibility (for transitions)
function ns.CDMGroups.UpdateSingleEditButton(frame)
    if not frame or not frame._arcEditButton then return end
    
    local ACD = LibStub("AceConfigDialog-3.0", true)
    local optionsPanelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] and true or false
    
    if optionsPanelOpen then
        frame._arcEditButton:EnableMouse(true)
        frame._arcEditButton:Show()
    else
        frame._arcEditButton:Hide()
    end
end

function ns.CDMGroups.UpdateEditButtonVisibility()
    local ACD = LibStub("AceConfigDialog-3.0", true)
    local optionsPanelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] and true or false
    
    -- OPTIMIZATION: Skip if state hasn't changed
    if optionsPanelOpen == lastEditButtonState then
        return
    end
    lastEditButtonState = optionsPanelOpen
    
    -- Update group member icons - edit buttons ONLY show when ArcUI panel is open
    for gName, group in pairs(ns.CDMGroups.groups) do
        for cdID, member in pairs(group.members) do
            if member.frame and member.frame._arcEditButton then
                if optionsPanelOpen then
                    member.frame._arcEditButton:EnableMouse(true)
                    member.frame._arcEditButton:Show()
                else
                    member.frame._arcEditButton:Hide()
                end
            end
        end
    end
    
    -- Update free icons
    for cdID, data in pairs(ns.CDMGroups.freeIcons) do
        if data.frame and data.frame._arcEditButton then
            if optionsPanelOpen then
                data.frame._arcEditButton:EnableMouse(true)
                data.frame._arcEditButton:Show()
            else
                data.frame._arcEditButton:Hide()
            end
        end
    end
end

function ns.CDMGroups.ReleaseFreeIcon(cooldownID, clearSaved)
    local data = ns.CDMGroups.freeIcons[cooldownID]
    if not data then return end
    
    local frame = data.frame
    if frame then
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
        frame:SetScript("OnUpdate", nil)
        frame:RegisterForDrag()
        frame._freeDragging = nil
        frame._sourceCdID = nil
        frame._cdmgIsFreeIcon = nil  -- Clear free icon flag so hooks stop fighting
        frame._cdmgFreeTargetSize = nil
        
        -- Hide edit button
        if frame._arcEditButton then
            frame._arcEditButton:Hide()
        end
        
        if data.originalParent then
            frame:SetParent(data.originalParent)
            frame:ClearAllPoints()
        end
    end
    
    if data.entry then
        data.entry.manipulated = false
        data.entry.manipulationType = nil
    end
    
    ns.CDMGroups.freeIcons[cooldownID] = nil
    
    if clearSaved then
        -- ClearPositionFromSpec now uses GetProfileSavedPositions to ensure correct table
        ClearPositionFromSpec(cooldownID)
        ClearFreeIconFromSpec(cooldownID)
    end
end

-- Release ALL icons back to CDM control (master disable)
function ns.CDMGroups.ReleaseAllIcons()
    -- 1. Release all free icons
    for cdID, _ in pairs(ns.CDMGroups.freeIcons) do
        ns.CDMGroups.ReleaseFreeIcon(cdID, false)  -- Don't clear saved positions
    end
    
    -- 2. Release all frames from groups and fully clean up group UI elements
    for gName, group in pairs(ns.CDMGroups.groups) do
        if group.members then
            for cdID, member in pairs(group.members) do
                if member.frame then
                    ReturnFrameToCDM(member.frame, member.entry)
                end
            end
            wipe(group.members)
        end
        if group.grid then
            wipe(group.grid)
        end
        
        -- ═══════════════════════════════════════════════════════════════════
        -- COMPREHENSIVE GROUP UI CLEANUP
        -- Must fully destroy all UI elements to prevent ghost artifacts
        -- ═══════════════════════════════════════════════════════════════════
        
        -- Hide and orphan edge arrows (parented to UIParent, not container!)
        if group.edgeArrows then
            for _, arrow in pairs(group.edgeArrows) do
                if arrow then
                    arrow:ClearAllPoints()
                    arrow:Hide()
                    arrow:SetParent(nil)
                end
            end
            wipe(group.edgeArrows)
        end
        
        -- Hide and orphan drag toggle button (parented to UIParent!)
        if group.dragToggleBtn then
            group.dragToggleBtn:ClearAllPoints()
            group.dragToggleBtn:Hide()
            group.dragToggleBtn:SetParent(nil)
            group.dragToggleBtn = nil
        end
        
        -- Hide and orphan drag bar
        if group.dragBar then
            group.dragBar:ClearAllPoints()
            group.dragBar:Hide()
            group.dragBar:SetParent(nil)
            group.dragBar = nil
        end
        
        -- Hide and orphan selection highlight
        if group.selectionHighlight then
            group.selectionHighlight:ClearAllPoints()
            group.selectionHighlight:Hide()
            group.selectionHighlight:SetParent(nil)
            group.selectionHighlight = nil
        end
        
        -- Hide and orphan container last (children should be cleaned first)
        if group.container then
            group.container:ClearAllPoints()
            group.container:Hide()
            group.container:SetParent(nil)
        end
        
        -- Notify EditModeContainers to clean up wrapper for this group
        if ns.EditModeContainers and ns.EditModeContainers.OnGroupDeleted then
            ns.EditModeContainers.OnGroupDeleted(gName)
        end
    end
    
    -- 3. Clear all groups
    wipe(ns.CDMGroups.groups)
end


-- ═══════════════════════════════════════════════════════════════════════════
-- MAINTAINERS MOVED TO CDMGroups_Maintain.lua
-- The hot path code (FreeIconMaintainer, GroupIconStateMaintainer) has been
-- extracted to a separate file for easier auditing and performance tuning.
-- See: CDM_Module/CDM_Groups/ArcUI_CDMGroups_Maintain.lua
-- ═══════════════════════════════════════════════════════════════════════════

-- FRAME RECOVERY - Restore frames that return after being removed

-- Helper: Restore all saved group positions in deterministic order
local function RestoreSavedGroupPositions()
    local sorted = {}
    for cdID, saved in pairs(ns.CDMGroups.savedPositions) do
        if saved.type == "group" and saved.target then
            table.insert(sorted, { cdID = cdID, saved = saved })
        end
    end
    table.sort(sorted, function(a, b)
        if a.saved.target ~= b.saved.target then return a.saved.target < b.saved.target end
        local aRow, bRow = a.saved.row or 0, b.saved.row or 0
        if aRow ~= bRow then return aRow < bRow end
        return (a.saved.col or 0) < (b.saved.col or 0)
    end)
    for _, item in ipairs(sorted) do
        local group = ns.CDMGroups.groups[item.saved.target]
        if group and not group.members[item.cdID] then
            local row, col = item.saved.row or 0, item.saved.col or 0
            if row < group.layout.gridRows and col < group.layout.gridCols then
                group:AddMemberAt(item.cdID, row, col)
            end
        end
    end
end

-- Try to restore a single saved position with smart displacement
-- When a returning icon wants a position occupied by another icon,
-- move the occupant to ITS saved position (if different) rather than just shifting right
function ns.CDMGroups.RestoreSavedPosition(cdID, frame, _displacementDepth)
    _displacementDepth = _displacementDepth or 0
    
    -- Check if this type is enabled FIRST
    local viewerType = GetViewerTypeForCooldownID(cdID)
    if viewerType and not IsViewerTypeEnabled(viewerType) then
        return false  -- Skip - this type is disabled
    end
    
    -- Prevent infinite recursion
    if _displacementDepth > 10 then
        return false
    end
    
    local saved = ns.CDMGroups.savedPositions[cdID]
    if not saved then 
        return false 
    end
    
    -- If frame was passed, register it first
    local entry = nil
    if frame then
        entry = Registry:GetOrCreate(frame, "restored")
    end
    
    if saved.type == "group" and saved.target then
        local group = ns.CDMGroups.groups[saved.target]
        if group and not group.members[cdID] then
            local targetRow = saved.row or 0
            local targetCol = saved.col or 0
            
            -- Check if target position is occupied
            local existingCdID = group.grid[targetRow] and group.grid[targetRow][targetCol]
            if existingCdID and existingCdID ~= cdID then
                local existingMember = group.members[existingCdID]
                if existingMember and HasValidFrame(existingMember, existingCdID) then
                    -- Check if occupant has a DIFFERENT saved position
                    local occupantSaved = ns.CDMGroups.savedPositions[existingCdID]
                    if occupantSaved and occupantSaved.type == "group" and occupantSaved.target == group.name then
                        local occupantRow = occupantSaved.row or 0
                        local occupantCol = occupantSaved.col or 0
                        
                        -- Only displace if occupant's saved position is different from current
                        if occupantRow ~= targetRow or occupantCol ~= targetCol then
                            -- Move occupant to its saved position first
                            -- Clear from current position
                            group.grid[targetRow][targetCol] = nil
                            
                            -- Use PlaceMemberAt to move (it handles displacement recursively)
                            group:PlaceMemberAt(existingCdID, occupantRow, occupantCol)
                            
                            -- Position should now be free for our icon
                        else
                            -- Occupant is AT its saved position - need to shift/expand instead
                            -- Expand grid if needed to accommodate both icons
                            local maxCols = group.layout.gridCols
                            local expansionBlocked = ns.CDMGroups.blockGridExpansion or group.lockGridSize
                            if not expansionBlocked then
                                -- Find a free slot or expand
                                local freeRow, freeCol = group:FindNextFreeSlot(true)
                                if freeRow and freeCol then
                                    group:PlaceMemberAt(existingCdID, freeRow, freeCol)
                                end
                            else
                                -- Can't expand - try shifting
                                group:ShiftRowRight(targetRow, targetCol)
                            end
                        end
                    else
                        -- No saved position for occupant - try to shift or find free slot
                        if not group:ShiftRowRight(targetRow, targetCol) then
                            local freeRow, freeCol = group:FindNextFreeSlot(true)
                            if freeRow and freeCol then
                                group:PlaceMemberAt(existingCdID, freeRow, freeCol)
                            end
                        end
                    end
                end
            end
            
            -- Now insert our icon at its saved position
            if frame and entry then
                group:AddMemberAtWithFrame(cdID, targetRow, targetCol, frame, entry)
                -- Check if it actually succeeded
                if group.members[cdID] and group.members[cdID].frame then
                    return true
                end
            else
                -- Fallback to AddMemberAt (has to look up frame)
                group:AddMemberAt(cdID, targetRow, targetCol)
                if group.members[cdID] and group.members[cdID].frame then
                    return true
                end
            end
            return false
        end
    elseif saved.type == "free" then
        -- Check if freeIcon entry doesn't have a frame yet (data may exist but without frame)
        local existingEntry = ns.CDMGroups.freeIcons[cdID]
        if not existingEntry or not existingEntry.frame then
            ns.CDMGroups.TrackFreeIcon(cdID, saved.x or 0, saved.y or 0, saved.iconSize or 36)
            return true
        end
    end
    
    return false
end

-- Try to restore all saved positions (for frames that returned)
-- NOTE: Now delegates to FrameController when available
function ns.CDMGroups.RestoreAllSavedPositions()
    -- Use FrameController if available
    if _G.ARCUI_USE_FRAME_CONTROLLER and ns.FrameController and ns.FrameController.Reconcile then
        ns.FrameController.Reconcile()
        return 0
    end
    
    -- Fallback: Original logic
    local restored = 0
    
    for cdID, saved in pairs(ns.CDMGroups.savedPositions) do
        -- Check if this cdID already has a frame tracked
        local alreadyTracked = false
        
        if saved.type == "group" and saved.target then
            local group = ns.CDMGroups.groups[saved.target]
            if group and group.members[cdID] then
                -- Check if member has valid frame
                if HasValidFrame(group.members[cdID], cdID) then
                    alreadyTracked = true
                end
            end
        elseif saved.type == "free" then
            if ns.CDMGroups.freeIcons[cdID] then
                local data = ns.CDMGroups.freeIcons[cdID]
                if data.frame and SafeGetFrameCooldownID(data.frame) == cdID then
                    alreadyTracked = true
                end
            end
        end
        
        if not alreadyTracked then
            -- Try to find a frame for this cdID in CDM viewers
            local frame = nil
            for _, viewerInfo in ipairs(CDM_VIEWERS) do
                -- Skip bar viewers - we only manage icon viewers
                if not viewerInfo.skipInGroups then
                    local viewer = _G[viewerInfo.name]
                    if viewer then
                        local children = { viewer:GetChildren() }
                        for _, child in ipairs(children) do
                            if child.cooldownID == cdID then
                                frame = child
                                break
                            end
                        end
                    end
                end
                if frame then break end
            end
            
            if frame then
                -- Register the frame BEFORE restoring
                Registry:Register(frame, "recovery")
                if ns.CDMGroups.RestoreSavedPosition(cdID, frame) then
                    restored = restored + 1
                end
            end
        end
    end
    
    return restored
end

-- NOTE: Recovery is now handled by MaintenanceTimer in AutoAssignNewIcons section

-- AUTO-ASSIGN NEW ICONS - Assign untracked icons to their default groups
-- NOTE: This now delegates to FrameController.Reconcile() which handles all assignment logic
-- CRITICAL: When options panel is open, skip entirely to avoid unwanted reflows

function ns.CDMGroups.AutoAssignNewIcons()
    -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
    if not _cdmGroupsEnabled then return 0 end
    
    -- CRITICAL: Skip when options panel is open (either ArcUI or CDM)
    -- Reconcile schedules follow-up sweeps with reflow - we don't want that during editing
    local panelOpen = ns.CDMGroups.IsOptionsPanelOpen and ns.CDMGroups.IsOptionsPanelOpen()
    if panelOpen then return 0 end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- DELEGATE TO FRAMECONTROLLER
    -- FrameController.Reconcile() now handles:
    -- - PRE-PASS for savedPositions (creating placeholder members)
    -- - CDM viewer scanning
    -- - Frame assignment to groups/free
    -- - Position saving
    -- - Import mode handling
    -- ═══════════════════════════════════════════════════════════════════════════
    
    if _G.ARCUI_USE_FRAME_CONTROLLER and ns.FrameController then
        if ns.FrameController.Reconcile then
            ns.FrameController.Reconcile()
        elseif ns.FrameController.ScheduleReconcile then
            ns.FrameController.ScheduleReconcile(0.05)
        end
        return 0
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- FALLBACK: Legacy code (only runs if ARCUI_USE_FRAME_CONTROLLER = false)
    -- This code path is DEPRECATED and will be removed in a future version
    -- ═══════════════════════════════════════════════════════════════════════════
    
    PrintMsg("|cffFF0000[DEPRECATED]|r AutoAssignNewIcons fallback running - FrameController should be handling this!")
    
    local assigned = 0
    
    -- Just do a basic scan and assign to default groups
    for _, viewerInfo in ipairs(CDM_VIEWERS) do
        if viewerInfo.skipInGroups then
            -- Don't try to grab bars as icons
        elseif not IsViewerTypeEnabled(viewerInfo.type) then
            -- Skip disabled viewer types
        else
            local viewer = _G[viewerInfo.name]
            if viewer then
                local children = { viewer:GetChildren() }
                for _, child in ipairs(children) do
                    if child.cooldownID then
                        local cdID = child.cooldownID
                        local parent = child:GetParent()
                        
                        -- Only grab frames still in CDM viewer
                        if parent == viewer then
                            -- Check if already tracked anywhere
                            local isTracked = false
                            for gName, group in pairs(ns.CDMGroups.groups or {}) do
                                if group.members and group.members[cdID] then
                                    isTracked = true
                                    break
                                end
                            end
                            
                            if not isTracked and ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cdID] then
                                isTracked = true
                            end
                            
                            if not isTracked then
                                -- Check for saved position
                                local saved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[cdID]
                                if saved and saved.type == "group" and saved.target then
                                    local group = ns.CDMGroups.groups[saved.target]
                                    if group and group.AddMemberAtWithFrame then
                                        group:AddMemberAtWithFrame(cdID, saved.row or 0, saved.col or 0, child, nil)
                                        assigned = assigned + 1
                                    end
                                elseif saved and saved.type == "free" then
                                    if ns.CDMGroups.TrackFreeIcon then
                                        ns.CDMGroups.TrackFreeIcon(cdID, saved.x or 0, saved.y or 0, saved.iconSize or 36)
                                        assigned = assigned + 1
                                    end
                                else
                                    -- No saved position - add to default group
                                    local defaultGroup = viewerInfo.defaultGroup or "Essential"
                                    local group = ns.CDMGroups.groups[defaultGroup]
                                    if group and group.AddMember then
                                        if group:AddMember(cdID) then
                                            assigned = assigned + 1
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    if assigned > 0 then
        ns.CDMGroups.cooldownCatalog = ns.CDMGroups.BuildCooldownCatalog()
    end
    
    return assigned
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SCAN ALL VIEWERS - Wrapper for FrameController.ScanCDMViewers
-- Returns count of icons found
-- ═══════════════════════════════════════════════════════════════════════════
function ns.CDMGroups.ScanAllViewers()
    if ns.FrameController and ns.FrameController.ScanCDMViewers then
        local cdmState = ns.FrameController.ScanCDMViewers()
        local count = 0
        for _ in pairs(cdmState) do count = count + 1 end
        return count
    end
    return 0
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EMERGENCY RESCUE - Find orphaned frames and make them free icons
-- Use this when icons are "stuck" and not being tracked by ArcUI
-- This scans ALL CDM frames and creates free icons for any not tracked
-- ═══════════════════════════════════════════════════════════════════════════
function ns.CDMGroups.EmergencyRescue()
    local rescued = 0
    local alreadyTracked = 0
    local errors = 0
    
    PrintMsg("|cffff8800[Emergency Rescue]|r Starting scan...")
    
    -- Get all frames from CDM
    local cdmState = {}
    if ns.FrameController and ns.FrameController.ScanCDMViewers then
        cdmState = ns.FrameController.ScanCDMViewers()
    else
        PrintMsg("|cffff0000[Emergency Rescue]|r FrameController not available!")
        return 0, 0, 0
    end
    
    -- Track what we found for reporting
    local foundCdIDs = {}
    
    for cdID, cdmData in pairs(cdmState) do
        local frame = cdmData.frame
        if frame and cdID then
            table.insert(foundCdIDs, cdID)
            
            -- Check if already tracked in a group WITH VALID FRAME
            local isInGroup = false
            local groupFrameValid = false
            for groupName, group in pairs(ns.CDMGroups.groups or {}) do
                if group.members and group.members[cdID] then
                    isInGroup = true
                    -- Check if frame reference matches
                    local member = group.members[cdID]
                    if member.frame == frame then
                        groupFrameValid = true
                    end
                    break
                end
            end
            
            -- Check if already tracked as free icon WITH VALID FRAME
            local isFreeIcon = false
            local freeFrameValid = false
            if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cdID] then
                isFreeIcon = true
                -- Check if frame reference matches
                local freeData = ns.CDMGroups.freeIcons[cdID]
                if freeData.frame == frame then
                    freeFrameValid = true
                end
            end
            
            -- Properly tracked = entry exists AND frame reference is correct
            local properlyTracked = (isInGroup and groupFrameValid) or (isFreeIcon and freeFrameValid)
            
            if properlyTracked then
                alreadyTracked = alreadyTracked + 1
            elseif isInGroup and not groupFrameValid then
                -- CORRUPTED GROUP MEMBER - fix the frame reference
                local ok, err = pcall(function()
                    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
                        if group.members and group.members[cdID] then
                            local member = group.members[cdID]
                            local oldFrame = member.frame
                            member.frame = frame
                            
                            -- Re-setup in container
                            if ns.CDMGroups.SetupFrameInContainer and group.container then
                                local slotW, slotH = 36, 36
                                if ns.CDMGroups.GetSlotDimensions and group.layout then
                                    slotW, slotH = ns.CDMGroups.GetSlotDimensions(group.layout)
                                end
                                ns.CDMGroups.SetupFrameInContainer(frame, group.container, slotW, slotH, cdID)
                            end
                            
                            -- Install hooks and drag
                            if ns.FrameController and ns.FrameController.InstallFrameHooks then
                                ns.FrameController.InstallFrameHooks(frame)
                            end
                            if ns.CDMGroups.ShouldAllowDrag() and group.SetupMemberDrag then
                                group:SetupMemberDrag(cdID)
                            end
                            
                            local spellName = C_Spell.GetSpellName(cdID) or tostring(cdID)
                            PrintMsg("|cff00ffff[Fixed]|r " .. spellName .. " frame reference in " .. groupName)
                            rescued = rescued + 1
                            break
                        end
                    end
                end)
                if not ok then errors = errors + 1 end
            elseif isFreeIcon and not freeFrameValid then
                -- CORRUPTED FREE ICON - fix the frame reference
                local ok, err = pcall(function()
                    local freeData = ns.CDMGroups.freeIcons[cdID]
                    freeData.frame = frame
                    
                    -- Position the frame
                    frame:ClearAllPoints()
                    frame:SetPoint("CENTER", UIParent, "CENTER", freeData.x or 0, freeData.y or 0)
                    frame:SetParent(UIParent)
                    frame:SetFrameStrata("MEDIUM")
                    frame:SetScale(1)
                    -- Only show if not hidden due to hideWhenUnequipped setting
                    if not frame._arcHiddenUnequipped and not IsFrameHiddenByBar(frame) then
                        frame:Show()
                    end
                    
                    -- Install hooks
                    if ns.FrameController and ns.FrameController.InstallFrameHooks then
                        ns.FrameController.InstallFrameHooks(frame)
                    end
                    if ns.CDMGroups.SetupFreeIconDrag then
                        ns.CDMGroups.SetupFreeIconDrag(cdID)
                    end
                    
                    local spellName = C_Spell.GetSpellName(cdID) or tostring(cdID)
                    PrintMsg("|cff00ffff[Fixed]|r " .. spellName .. " free icon frame reference")
                    rescued = rescued + 1
                end)
                if not ok then errors = errors + 1 end
            else
                -- NOT TRACKED AT ALL - Rescue it as a free icon!
                local ok, err = pcall(function()
                    -- Calculate position based on rescue count (spread them out)
                    local baseX = 200
                    local baseY = -100 - (rescued * 50)  -- Stack vertically
                    
                    -- Create as free icon
                    ns.CDMGroups.freeIcons = ns.CDMGroups.freeIcons or {}
                    ns.CDMGroups.freeIcons[cdID] = {
                        frame = frame,
                        x = baseX,
                        y = baseY,
                        iconSize = 36,
                        viewerType = cdmData.viewerType,
                        originalViewerName = cdmData.viewerName,
                    }
                    
                    -- Save to database
                    local positionData = {
                        type = "free",
                        x = baseX,
                        y = baseY,
                        iconSize = 36,
                        viewerType = cdmData.viewerType,
                    }
                    -- Use GetProfileSavedPositions to ensure we write to correct table
                    local profileSavedPositions = GetProfileSavedPositions()
                    if profileSavedPositions then
                        profileSavedPositions[cdID] = positionData
                    end
                    
                    if ns.CDMGroups.SavePositionToSpec then
                        ns.CDMGroups.SavePositionToSpec(cdID, positionData)
                    end
                    if ns.CDMGroups.SaveFreeIconToSpec then
                        ns.CDMGroups.SaveFreeIconToSpec(cdID, { x = baseX, y = baseY, iconSize = 36 })
                    end
                    
                    -- Position the frame
                    frame:ClearAllPoints()
                    frame:SetPoint("CENTER", UIParent, "CENTER", baseX, baseY)
                    frame:SetParent(UIParent)
                    frame:SetFrameStrata("MEDIUM")
                    frame:SetScale(1)
                    -- Only show if not hidden due to hideWhenUnequipped setting
                    if not frame._arcHiddenUnequipped and not IsFrameHiddenByBar(frame) then
                        frame:Show()
                    end
                    
                    -- Install hooks
                    if ns.FrameController and ns.FrameController.InstallFrameHooks then
                        ns.FrameController.InstallFrameHooks(frame)
                    end
                    
                    -- Setup drag handlers
                    if ns.CDMGroups.SetupFreeIconDrag then
                        ns.CDMGroups.SetupFreeIconDrag(cdID)
                    end
                    
                    -- Get spell name for reporting
                    local spellName = C_Spell.GetSpellName(cdID) or tostring(cdID)
                    PrintMsg("|cff00ff00[Rescued]|r " .. spellName .. " (ID:" .. cdID .. ") -> Free Icon")
                    
                    rescued = rescued + 1
                end)
                
                if not ok then
                    errors = errors + 1
                    PrintMsg("|cffff0000[Error]|r Failed to rescue cdID " .. tostring(cdID) .. ": " .. tostring(err))
                end
            end
        end
    end
    
    -- Enable drag mode so user can reposition rescued icons
    if rescued > 0 and ns.CDMGroups.SetDragMode then
        ns.CDMGroups.SetDragMode(true)
        PrintMsg("|cffff8800[Emergency Rescue]|r Drag Mode ENABLED - reposition your rescued icons!")
    end
    
    PrintMsg("|cff00ff00[Emergency Rescue]|r Complete! Found " .. #foundCdIDs .. " total, " .. 
             alreadyTracked .. " already tracked, " .. rescued .. " rescued, " .. errors .. " errors")
    
    return rescued, alreadyTracked, errors
end

-- Periodic maintenance timer - handles recovery, auto-assign, and stale frame detection
-- Track if CDM's options panel is open
ns.CDMGroups.cdmOptionsPanelOpen = false

-- Helper to check if CDM options panel is visible
local function IsCDMOptionsPanelOpen()
    -- Check if CooldownViewerSettings frame exists and is shown
    local cdmSettings = _G["CooldownViewerSettings"]
    if cdmSettings and cdmSettings:IsShown() then
        return true
    end
    return ns.CDMGroups.cdmOptionsPanelOpen
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MAINTENANCE TIMER REMOVED - Now handled by FrameController
-- The old MaintenanceTimer OnUpdate has been replaced by:
--   - FrameController.Reconcile() for frame assignment and dirty grid processing
--   - FrameController.VisualMaintainer for position/size/visual enforcement
-- ═══════════════════════════════════════════════════════════════════════════

-- Hook CDM's CooldownViewerSettings panel to track when it opens/closes
local function HookCDMOptionsPanel()
    local cdmSettings = _G["CooldownViewerSettings"]
    if cdmSettings then
        -- Hook OnShow
        if not cdmSettings._arcuiHooked then
            cdmSettings:HookScript("OnShow", function()
                ns.CDMGroups.cdmOptionsPanelOpen = true
                
                -- CDM panel OPENED
                -- DON'T restore icons here - it can cause issues if ArcUI panel is also open
                -- or if frames aren't stable yet. The panel state is tracked so validation
                -- and reflow are skipped while CDM is open.
                
                -- Just update visibility so combat/ooc groups stay visible
                if ns.CDMGroups.UpdateGroupVisibility then
                    ns.CDMGroups.UpdateGroupVisibility()
                end
            end)
            cdmSettings:HookScript("OnHide", function()
                ns.CDMGroups.cdmOptionsPanelOpen = false
                
                -- CDM panel CLOSED - CDM may have silently reassigned frames
                -- Wait a short delay to let CDM finish its cleanup, then rescan
                if not IsRestoring() and not ns.CDMGroups.specChangeInProgress then
                    C_Timer.After(0.1, function()
                        -- Rescan to pick up any new frame assignments
                        if ns.CDMGroups.ScanAllViewers then
                            ns.CDMGroups.ScanAllViewers()
                        end
                        if ns.CDMGroups.AutoAssignNewIcons then
                            ns.CDMGroups.AutoAssignNewIcons()
                        end
                        
                        -- Check if ArcUI panel is open
                        local ACD = LibStub("AceConfigDialog-3.0", true)
                        local arcUIOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
                        
                        if arcUIOpen then
                            -- ArcUI still open - restore to saved positions (show gaps)
                            if ns.CDMGroups.RestoreIconsToSavedPositions then
                                ns.CDMGroups.RestoreIconsToSavedPositions()
                            end
                        else
                            -- ArcUI closed - reflow to close gaps
                            if ns.CDMGroups.ReflowAllGroups then
                                ns.CDMGroups.ReflowAllGroups()
                            end
                        end
                        
                        -- Update visibility
                        if ns.CDMGroups.UpdateGroupVisibility then
                            ns.CDMGroups.UpdateGroupVisibility()
                        end
                    end)
                end
            end)
            cdmSettings._arcuiHooked = true
        end
    end
end

-- Try to hook immediately and also after a delay (CDM may load later)
C_Timer.After(0, HookCDMOptionsPanel)
C_Timer.After(1, HookCDMOptionsPanel)
C_Timer.After(3, HookCDMOptionsPanel)

-- PER-SPEC DATA SYSTEM

-- Deep copy a table
DeepCopy = function(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

-- Serialize a group object to saveable data format
local function SerializeGroupToData(group, overrideLayout)
    local data = {
        enabled = true,
        position = { x = group.position.x, y = group.position.y },
        showBorder = group.showBorder,
        showBackground = group.showBackground,
        autoReflow = group.autoReflow,
        dynamicLayout = group.dynamicLayout,
        lockGridSize = group.lockGridSize,
        containerPadding = group.containerPadding,
        visibility = type(group.visibility) == "table" and DeepCopy(group.visibility) or (group.visibility or "always"),
        borderColor = DeepCopy(group.borderColor),
        bgColor = DeepCopy(group.bgColor),
        layout = overrideLayout or DeepCopy(group.layout),
        grid = {},
    }
    -- Save grid (only entries with valid members)
    for row, cols in pairs(group.grid or {}) do
        for col, cdID in pairs(cols) do
            if group.members[cdID] then
                if not data.grid[row] then data.grid[row] = {} end
                data.grid[row][col] = cdID
            end
        end
    end
    return data
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PHASE 1 REFACTOR: New helper functions for profile-based storage
-- profile.groupLayouts is the SINGLE SOURCE OF TRUTH for group settings
-- ═══════════════════════════════════════════════════════════════════════════════

-- Serialize group to LAYOUT DATA ONLY (no runtime data like grid/members)
-- This is what gets saved to profile.groupLayouts
local function SerializeGroupToLayoutData(group)
    if not group then return nil end
    return {
        -- Position
        position = group.position and { x = group.position.x, y = group.position.y },
        -- Grid settings
        gridRows = group.layout and group.layout.gridRows or 2,
        gridCols = group.layout and group.layout.gridCols or 4,
        iconSize = group.layout and group.layout.iconSize or 36,
        iconWidth = group.layout and group.layout.iconWidth or 36,
        iconHeight = group.layout and group.layout.iconHeight or 36,
        spacing = group.layout and group.layout.spacing or 2,
        spacingX = group.layout and group.layout.spacingX,
        spacingY = group.layout and group.layout.spacingY,
        separateSpacing = group.layout and group.layout.separateSpacing,
        alignment = group.layout and group.layout.alignment,
        horizontalGrowth = group.layout and group.layout.horizontalGrowth,
        verticalGrowth = group.layout and group.layout.verticalGrowth,
        -- Appearance
        showBorder = group.showBorder,
        showBackground = group.showBackground,
        autoReflow = group.autoReflow,
        dynamicLayout = group.dynamicLayout,
        lockGridSize = group.lockGridSize,
        containerPadding = group.containerPadding,
        borderColor = group.borderColor and DeepCopy(group.borderColor),
        bgColor = group.bgColor and DeepCopy(group.bgColor),
        visibility = type(group.visibility) == "table" and DeepCopy(group.visibility) or (group.visibility or "always"),
    }
    -- NOTE: Does NOT include grid, members, container - those are runtime only
end

-- Get active profile for a spec (convenience accessor)
-- NOTE: Does NOT call EnsureLayoutProfiles (defined later) - returns nil if profile doesn't exist
local function GetActiveProfile(specData)
    specData = specData or GetSpecData()
    if not specData then return nil end
    if not specData.layoutProfiles then return nil end
    
    local profileName = specData.activeProfile or "Default"
    return specData.layoutProfiles[profileName]
end

-- Save a group's layout to the active profile
-- Creates profile structure if needed
local function SaveGroupLayoutToProfile(groupName, group, specData)
    specData = specData or GetSpecData()
    if not specData then return end
    
    -- Ensure layoutProfiles structure exists
    if not specData.layoutProfiles then
        specData.layoutProfiles = {}
    end
    
    local profileName = specData.activeProfile or "Default"
    if not specData.layoutProfiles[profileName] then
        specData.layoutProfiles[profileName] = {
            savedPositions = {},
            freeIcons = {},
            groupLayouts = {},
            iconSettings = {},
        }
    end
    
    local profile = specData.layoutProfiles[profileName]
    if not profile.groupLayouts then
        profile.groupLayouts = {}
    end
    
    profile.groupLayouts[groupName] = SerializeGroupToLayoutData(group)
end

-- Get group layout from active profile (or nil if not exists)
local function GetGroupLayoutFromProfile(groupName, specData)
    local profile = GetActiveProfile(specData)
    if not profile or not profile.groupLayouts then return nil end
    return profile.groupLayouts[groupName]
end

-- Get the current spec KEY (class-specific to prevent cross-class contamination)
-- Returns a string like "class_7_spec_2" for Enhancement Shaman
GetCurrentSpec = function()
    local specIndex = GetSpecialization() or 1
    local _, _, classID = UnitClass("player")
    classID = classID or 0
    return "class_" .. classID .. "_spec_" .. specIndex
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CHARACTER-SPECIFIC DATABASE ACCESS
-- All CDMGroups data is stored per-character (not shared across alts)
-- The actual function is in ArcUI_CDM_Shared.lua (loads first)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Use the shared GetCDMGroupsDB from CDMShared
GetCDMGroupsDB = Shared.GetCDMGroupsDB

-- Export for backward compatibility
ns.CDMGroups.GetCDMGroupsDB = GetCDMGroupsDB

-- Helper to get a group's layout from PROFILE (single source of truth)
ns.CDMGroups.GetGroupDB = function(groupName)
    local specData = GetSpecData()
    if not specData then return nil end
    
    -- Read from profile.groupLayouts (the authoritative source)
    local layoutData = GetGroupLayoutFromProfile(groupName, specData)
    if layoutData then
        return layoutData
    end
    
    -- Fallback to defaults if group doesn't exist in profile
    if DEFAULT_GROUPS[groupName] then
        return DEFAULT_GROUPS[groupName]
    end
    
    return nil
end

-- Get spec data for a specific spec (or current if not specified)
GetSpecData = function(specKey)
    -- CRITICAL: Get the ACTUAL table from ns.db.char.cdmGroups (not a cached copy)
    local db = GetCDMGroupsDB()
    if not db then 
        DebugPrint("|cffff0000[GetSpecData]|r GetCDMGroupsDB returned nil!")
        return nil 
    end
    
    specKey = specKey or ns.CDMGroups.currentSpec
    -- If no spec key yet (before initialization completes), return nil
    if not specKey then return nil end
    
    -- CRITICAL: Ensure db.specData table exists
    if not db.specData then
        db.specData = {}
        DebugPrint("|cffff8800[GetSpecData]|r Created db.specData table")
    end
    
    local specData = db.specData[specKey]
    
    -- CREATE spec data if it doesn't exist (this is critical for saving!)
    if not specData then
        specData = GetDefaultSpecData()
        db.specData[specKey] = specData
    end
    
    -- Ensure all required fields exist
    -- NOTE: We no longer create specData.groups here
    -- Group layouts now live in profile.groupLayouts (inside layoutProfiles)
    -- Legacy specData.groups is only read during migration, never written to
    
    -- NOTE: We no longer create specData.savedPositions here
    -- All position data now lives in profile.savedPositions (inside layoutProfiles)
    -- Legacy specData.savedPositions is only read during migration, never written to
    
    -- NOTE: We no longer create specData.freeIcons here
    -- Free icons data now lives in profile.freeIcons (inside layoutProfiles)
    -- Legacy specData.freeIcons is only read during migration, never written to
    
    return specData
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL: GetProfileSavedPositions - ALWAYS returns the correct profile table
-- This function ensures we NEVER write to an orphan table. It:
-- 1. Gets the current spec's active profile
-- 2. Ensures profile.savedPositions exists
-- 3. Syncs ns.CDMGroups.savedPositions to point to it
-- 4. Returns the profile.savedPositions table
-- ═══════════════════════════════════════════════════════════════════════════════
GetProfileSavedPositions = function(specKey)
    specKey = specKey or ns.CDMGroups.currentSpec
    if not specKey then return nil end
    
    local specData = GetSpecData(specKey)
    if not specData then return nil end
    
    -- Ensure layoutProfiles exists
    if not specData.layoutProfiles then
        specData.layoutProfiles = {}
    end
    
    -- Get active profile name
    local activeProfileName = specData.activeProfile or "Default"
    
    -- Ensure the profile exists
    if not specData.layoutProfiles[activeProfileName] then
        specData.layoutProfiles[activeProfileName] = {
            savedPositions = {},
            freeIcons = {},
            groupLayouts = {},
            iconSettings = {},
            createdAt = time(),  -- CRITICAL: Timestamp ensures AceDB saves this
        }
        
        -- ONE-TIME MIGRATION: If legacy specData.savedPositions has data, migrate it
        if specData.savedPositions and next(specData.savedPositions) then
            for cdID, data in pairs(specData.savedPositions) do
                specData.layoutProfiles[activeProfileName].savedPositions[cdID] = DeepCopy(data)
            end
        end
    end
    
    local profile = specData.layoutProfiles[activeProfileName]
    
    -- Ensure profile.savedPositions exists
    if not profile.savedPositions then
        profile.savedPositions = {}
    end
    
    -- Ensure profile has a timestamp (for existing profiles that might be missing it)
    if not profile.createdAt then
        profile.createdAt = time()
    end
    
    -- CRITICAL: Sync the runtime reference to point to this table
    -- This ensures ns.CDMGroups.savedPositions IS profile.savedPositions
    ns.CDMGroups.savedPositions = profile.savedPositions
    ns.CDMGroups.specSavedPositions[specKey] = profile.savedPositions
    
    return profile.savedPositions
end

-- Expose for other modules
ns.CDMGroups.GetProfileSavedPositions = GetProfileSavedPositions

-- Get default spec data template
-- If a default Group Template is set, use it instead of hardcoded defaults
GetDefaultSpecData = function()
    local Shared = ns.CDMShared
    local groups = DeepCopy(DEFAULT_GROUPS)
    
    -- Check for a default Group Template
    if Shared and Shared.GetDefaultTemplateName then
        local defaultTemplateName = Shared.GetDefaultTemplateName()
        if defaultTemplateName then
            local templatesDB = Shared.GetGroupTemplatesDB()
            if templatesDB and templatesDB[defaultTemplateName] then
                local template = templatesDB[defaultTemplateName]
                if template.groups and next(template.groups) then
                    -- Build groups from template
                    groups = {}
                    for groupName, layoutData in pairs(template.groups) do
                        groups[groupName] = {
                            enabled = true,
                            position = layoutData.position and DeepCopy(layoutData.position) or { x = 0, y = 0 },
                            showBorder = layoutData.showBorder,
                            showBackground = layoutData.showBackground,
                            autoReflow = layoutData.autoReflow ~= false,
                            dynamicLayout = layoutData.dynamicLayout,
                            lockGridSize = layoutData.lockGridSize,
                            containerPadding = layoutData.containerPadding,
                            visibility = layoutData.visibility or "always",
                            borderColor = layoutData.borderColor and DeepCopy(layoutData.borderColor) or { r = 0.5, g = 0.5, b = 0.5, a = 1 },
                            bgColor = layoutData.bgColor and DeepCopy(layoutData.bgColor) or { r = 0, g = 0, b = 0, a = 0.6 },
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
                            },
                            members = {},
                            grid = {},
                        }
                    end
                    -- Debug message (silent - user just sees their template applied)
                end
            end
        end
    end
    
    return {
        -- NOTE: groups is NOT stored at spec level anymore
        -- Group layouts now live in profile.groupLayouts (inside layoutProfiles)
        -- Legacy specData.groups is only read during migration, never written to
        
        -- NOTE: freeIcons is NOT stored at spec level anymore
        -- Free icons data now lives in profile.freeIcons (inside layoutProfiles)
        -- Legacy specData.freeIcons is only read during migration, never written to
        
        -- CRITICAL: Include a creation timestamp to ensure this differs from defaults
        -- AceDB only saves data that differs from defaults - an empty specData = {} won't save
        createdAt = time(),
        
        -- Layout profiles system (Arc Manager Profiles)
        layoutProfiles = {
            ["Default"] = {
                savedPositions = {},
                freeIcons = {},
                groupLayouts = DeepCopy(groups),  -- Store groups IN the profile
                iconSettings = {},  -- Per-icon visual settings
                talentConditions = nil,  -- No conditions = always available as fallback
                matchMode = "all",
                createdAt = time(),  -- Also timestamp the profile itself
            },
        },
        activeProfile = "Default",
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- IMPORT FROM OTHER SPECS
-- Copy group structure (NOT cooldownID positions) from another spec
-- ═══════════════════════════════════════════════════════════════════════════

-- Class names for display
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

-- Get list of all specs that have saved data (excluding current spec)
-- ═══════════════════════════════════════════════════════════════════════════
-- ACCOUNT IMPORT FUNCTIONS (delegated to CDMImportExport module)
-- ═══════════════════════════════════════════════════════════════════════════

-- These functions are now implemented in ArcUI_CDM_ImportExport.lua
-- We provide wrappers here for backward compatibility

function ns.CDMGroups.GetAvailableSpecsForImport()
    if ns.CDMImportExport and ns.CDMImportExport.GetAvailableLayoutsForImport then
        return ns.CDMImportExport.GetAvailableLayoutsForImport()
    end
    return {}
end

-- Import group structure from a specific profile (replaces current groups)
-- importKey format: "sourceType:specKey:profileName" (e.g., "char:class_7_spec_2:Default" or "profile:class_7_spec_2:MyProfile")
function ns.CDMGroups.ImportFromSpec(importKey)
    if ns.CDMImportExport and ns.CDMImportExport.ImportLayoutFromAccount then
        return ns.CDMImportExport.ImportLayoutFromAccount(importKey)
    end
    PrintMsg("Import module not available")
    return false
end

-- Initialize spec data if it doesn't exist (with optional inheritance)
EnsureSpecData = function(specIndex, inheritFromSpec)
    local db = GetCDMGroupsDB()
    if not db then return nil end
    
    -- CRITICAL: Ensure db.specData table exists
    if not db.specData then
        db.specData = {}
    end
    
    if not db.specData[specIndex] then
        if inheritFromSpec and db.specData[inheritFromSpec] then
            -- Deep copy layoutProfiles from source spec (contains groupLayouts, savedPositions)
            -- This preserves the full profile structure when inheriting
            local sourceData = db.specData[inheritFromSpec]
            db.specData[specIndex] = {
                -- NOTE: groups is NOT copied at spec level anymore
                -- Group layouts now live in profile.groupLayouts (inside layoutProfiles)
                -- NOTE: freeIcons is NOT copied at spec level anymore
                -- Free icons data lives in profile.freeIcons (inside layoutProfiles)
                
                -- Copy layoutProfiles if source has them
                layoutProfiles = sourceData.layoutProfiles and DeepCopy(sourceData.layoutProfiles) or {
                    ["Default"] = {
                        savedPositions = {},
                        freeIcons = {},
                        groupLayouts = sourceData.groups and DeepCopy(sourceData.groups) or DeepCopy(DEFAULT_GROUPS),
                        iconSettings = {},
                    },
                },
                activeProfile = sourceData.activeProfile or "Default",
            }
            if not db.specInheritedFrom then
                db.specInheritedFrom = {}
            end
            db.specInheritedFrom[specIndex] = inheritFromSpec
            -- Spec inherited group structure (silent)
        else
            -- Use defaults
            db.specData[specIndex] = GetDefaultSpecData()
            -- Spec initialized with defaults (silent)
        end
    end
    
    -- Ensure all required fields exist (for migrated data)
    local specData = db.specData[specIndex]
    -- NOTE: We no longer create specData.groups here
    -- Group layouts now live in profile.groupLayouts (inside layoutProfiles)
    -- Legacy specData.groups is only read during migration, never written to
    
    -- NOTE: We no longer create specData.savedPositions here
    -- All position data now lives in profile.savedPositions (inside layoutProfiles)
    -- Legacy specData.savedPositions is only read during migration, never written to
    
    -- NOTE: We no longer create specData.freeIcons here
    -- Free icons data now lives in profile.freeIcons (inside layoutProfiles)
    -- Legacy specData.freeIcons is only read during migration, never written to
    
    -- Always update character name to current character (for import display)
    local playerName = UnitName("player")
    if playerName then
        specData.characterName = playerName
    end
    
    return specData
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LAYOUT PROFILE MANAGEMENT
-- Profiles store layouts that can be activated based on talent conditions
-- ═══════════════════════════════════════════════════════════════════════════

-- Ensure layout profiles table exists in spec data
-- Returns the active profile for convenience
local function EnsureLayoutProfiles(specData)
    if not specData then return nil end
    
    local profileCreated = false
    
    if not specData.layoutProfiles then
        profileCreated = true
        -- CRITICAL FIX: When creating Default profile, copy existing positions instead of empty tables
        -- This prevents position loss when EnsureLayoutProfiles is called before LoadProfile
        local existingPositions = {}
        local existingFreeIcons = {}
        local existingGroupLayouts = {}
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- ONE-TIME MIGRATION from legacy specData.savedPositions
        -- This only runs when layoutProfiles doesn't exist (first time or old data)
        -- ═══════════════════════════════════════════════════════════════════════════
        if specData.savedPositions and next(specData.savedPositions) then
            DebugPrint("|cff88ff88[EnsureLayoutProfiles]|r Migrating legacy specData.savedPositions")
            for cdID, data in pairs(specData.savedPositions) do
                existingPositions[cdID] = DeepCopy(data)
            end
        end
        
        -- Also check runtime savedPositions as fallback (for mid-session profile creation)
        if next(existingPositions) == nil and ns.CDMGroups.savedPositions and next(ns.CDMGroups.savedPositions) then
            for cdID, data in pairs(ns.CDMGroups.savedPositions) do
                existingPositions[cdID] = DeepCopy(data)
            end
        end
        
        -- Copy free icons from specData
        if specData.freeIcons then
            for cdID, data in pairs(specData.freeIcons) do
                existingFreeIcons[cdID] = DeepCopy(data)
            end
        end
        
        -- Also check runtime freeIcons as fallback
        if next(existingFreeIcons) == nil and ns.CDMGroups.freeIcons then
            for cdID, data in pairs(ns.CDMGroups.freeIcons) do
                existingFreeIcons[cdID] = {
                    x = data.x,
                    y = data.y,
                    iconSize = data.iconSize,
                }
            end
        end
        
        -- Copy group layouts from runtime groups OR specData.groups (for migration)
        -- Check runtime groups first (current session), then fall back to specData.groups (persisted)
        if ns.CDMGroups.groups and next(ns.CDMGroups.groups) then
            for groupName, group in pairs(ns.CDMGroups.groups) do
                if group.layout then
                    existingGroupLayouts[groupName] = {
                        gridRows = group.layout.gridRows,
                        gridCols = group.layout.gridCols,
                        position = group.position and { x = group.position.x, y = group.position.y },
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
                        showBorder = group.showBorder,
                        showBackground = group.showBackground,
                        autoReflow = group.autoReflow,
                        dynamicLayout = group.dynamicLayout,
                        lockGridSize = group.lockGridSize,
                        containerPadding = group.containerPadding,
                        borderColor = group.borderColor and DeepCopy(group.borderColor),
                        bgColor = group.bgColor and DeepCopy(group.bgColor),
                        visibility = group.visibility,
                    }
                end
            end
        end
        
        -- MIGRATION: If runtime groups empty, copy from specData.groups (old addon format)
        if next(existingGroupLayouts) == nil and specData.groups then
            for groupName, groupData in pairs(specData.groups) do
                if groupData.layout or groupData.position then
                    existingGroupLayouts[groupName] = {
                        gridRows = groupData.layout and groupData.layout.gridRows or 2,
                        gridCols = groupData.layout and groupData.layout.gridCols or 4,
                        position = groupData.position and { x = groupData.position.x, y = groupData.position.y },
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
                        autoReflow = groupData.autoReflow ~= false,
                        dynamicLayout = groupData.dynamicLayout,
                        lockGridSize = groupData.lockGridSize,
                        containerPadding = groupData.containerPadding,
                        borderColor = groupData.borderColor and DeepCopy(groupData.borderColor),
                        bgColor = groupData.bgColor and DeepCopy(groupData.bgColor),
                        visibility = groupData.visibility,
                    }
                end
            end
        end
        
        -- Copy iconSettings from specData if available (MIGRATION from legacy format)
        local existingIconSettings = {}
        if specData.iconSettings then
            for cdID, settings in pairs(specData.iconSettings) do
                existingIconSettings[cdID] = DeepCopy(settings)
            end
        end
        
        -- CRITICAL: If no group layouts were found, use DEFAULT_GROUPS
        -- This ensures new profiles always have the standard groups
        if next(existingGroupLayouts) == nil then
            PrintMsg("|cff00ff00[EnsureLayoutProfiles]|r No existing groups - creating default groups (Essential, Utility, Buffs)")
            for groupName, groupData in pairs(DEFAULT_GROUPS) do
                existingGroupLayouts[groupName] = SerializeDefaultGroupToLayoutData(groupData)
            end
        end
        
        specData.layoutProfiles = {
            ["Default"] = {
                savedPositions = existingPositions,
                freeIcons = existingFreeIcons,
                groupLayouts = existingGroupLayouts,
                iconSettings = existingIconSettings,  -- CRITICAL: Include iconSettings!
                talentConditions = nil,
                matchMode = "all",
            },
        }
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- Set up savedPositions runtime shortcuts
        -- NOTE: iconSettings is now accessed via Shared.GetSpecIconSettings() which
        -- returns profile.iconSettings directly - no reference needed at specData level
        -- ═══════════════════════════════════════════════════════════════════════════
        
        -- savedPositions direct reference (runtime shortcuts)
        -- NOTE: ns.CDMGroups.savedPositions and specSavedPositions are runtime shortcuts
        -- They need to point to the profile's savedPositions table
        if ns.CDMGroups and ns.CDMGroups.currentSpec then
            ns.CDMGroups.savedPositions = specData.layoutProfiles["Default"].savedPositions
            if ns.CDMGroups.specSavedPositions then
                ns.CDMGroups.specSavedPositions[ns.CDMGroups.currentSpec] = specData.layoutProfiles["Default"].savedPositions
            end
        end
    end
    if not specData.activeProfile then
        specData.activeProfile = "Default"
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- MIGRATION/REPAIR: Create "Recovered" profile from legacy specData
    -- This recovers data from specData level for users upgrading from old versions
    -- Instead of modifying Default, we create a separate Recovered profile
    -- ═══════════════════════════════════════════════════════════════════════════
    
    -- Check if we have legacy data that needs recovery
    local hasLegacySavedPositions = specData.savedPositions and next(specData.savedPositions)
    local hasLegacyGroups = specData.groups and next(specData.groups)
    local hasLegacyFreeIcons = specData.freeIcons and next(specData.freeIcons)
    
    -- Check if Default profile is missing critical data
    local defaultProfile = specData.layoutProfiles["Default"]
    local defaultMissingGroupLayouts = not defaultProfile or not defaultProfile.groupLayouts or not next(defaultProfile.groupLayouts)
    local defaultMissingSavedPositions = not defaultProfile or not defaultProfile.savedPositions or not next(defaultProfile.savedPositions)
    
    -- Only create Recovered profile if:
    -- 1. We have legacy data to recover from
    -- 2. Default profile is missing data
    -- 3. We haven't already created a Recovered profile
    local needsRecovery = (hasLegacyGroups and defaultMissingGroupLayouts) or 
                          (hasLegacySavedPositions and defaultMissingSavedPositions) or
                          hasLegacyFreeIcons
    local alreadyRecovered = specData.layoutProfiles["Recovered"] ~= nil
    
    if needsRecovery and not alreadyRecovered then
        -- Create Recovered profile with all legacy data
        local recoveredProfile = {
            savedPositions = {},
            freeIcons = {},
            groupLayouts = {},
            iconSettings = {},  -- Include iconSettings!
            talentConditions = nil,
            matchMode = "all",
        }
        
        -- Copy iconSettings from specData level
        if specData.iconSettings then
            for cdID, settings in pairs(specData.iconSettings) do
                recoveredProfile.iconSettings[cdID] = DeepCopy(settings)
            end
        end
        
        -- Copy savedPositions from specData level
        if hasLegacySavedPositions then
            for cdID, data in pairs(specData.savedPositions) do
                recoveredProfile.savedPositions[cdID] = DeepCopy(data)
            end
        end
        
        -- Copy freeIcons from specData level
        if hasLegacyFreeIcons then
            for cdID, data in pairs(specData.freeIcons) do
                recoveredProfile.freeIcons[cdID] = DeepCopy(data)
            end
        end
        
        -- Copy groupLayouts from specData.groups
        if hasLegacyGroups then
            for groupName, groupData in pairs(specData.groups) do
                if groupData.layout or groupData.position then
                    recoveredProfile.groupLayouts[groupName] = {
                        gridRows = groupData.layout and groupData.layout.gridRows or 2,
                        gridCols = groupData.layout and groupData.layout.gridCols or 4,
                        position = groupData.position and { x = groupData.position.x, y = groupData.position.y },
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
                        autoReflow = groupData.autoReflow ~= false,
                        dynamicLayout = groupData.dynamicLayout,
                        lockGridSize = groupData.lockGridSize,
                        containerPadding = groupData.containerPadding,
                        borderColor = groupData.borderColor and DeepCopy(groupData.borderColor),
                        bgColor = groupData.bgColor and DeepCopy(groupData.bgColor),
                        visibility = groupData.visibility,
                    }
                end
            end
        end
        
        -- Only save if we actually recovered something useful
        local hasRecoveredData = next(recoveredProfile.savedPositions) or 
                                  next(recoveredProfile.freeIcons) or 
                                  next(recoveredProfile.groupLayouts)
        
        if hasRecoveredData then
            specData.layoutProfiles["Recovered"] = recoveredProfile
            PrintMsg("|cff00ff00Created 'Recovered' profile|r with your previous icon positions and group layouts. Use Arc Manager to load it.")
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- REPAIR: Ensure ALL existing profiles have iconSettings table
    -- This fixes profiles created before iconSettings was added to the profile system
    -- ═══════════════════════════════════════════════════════════════════════════
    for profileName, profile in pairs(specData.layoutProfiles) do
        if not profile.iconSettings then
            profile.iconSettings = {}
        end
        if not profile.savedPositions then
            profile.savedPositions = {}
        end
        if not profile.groupLayouts then
            profile.groupLayouts = {}
        end
        if not profile.freeIcons then
            profile.freeIcons = {}
        end
        
        -- REPAIR: If "Default" profile has empty groupLayouts, populate from DEFAULT_GROUPS
        if profileName == "Default" and (not profile.groupLayouts or not next(profile.groupLayouts)) then
            PrintMsg("|cff00ff00[Repair]|r Populating Default profile groupLayouts from DEFAULT_GROUPS")
            for groupName, groupData in pairs(DEFAULT_GROUPS) do
                profile.groupLayouts[groupName] = SerializeDefaultGroupToLayoutData(groupData)
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- REPAIR: If active profile has empty groupLayouts, populate from runtime groups
    -- This catches cases where profiles were created before groupLayouts was properly saved
    -- ═══════════════════════════════════════════════════════════════════════════
    local activeProfileName = specData.activeProfile or "Default"
    local activeProfile = specData.layoutProfiles[activeProfileName]
    
    if activeProfile and (not activeProfile.groupLayouts or not next(activeProfile.groupLayouts)) then
        -- Check if we have runtime groups to save
        if ns.CDMGroups and ns.CDMGroups.groups and next(ns.CDMGroups.groups) then
            PrintMsg("|cff00ff00[Repair]|r Populating empty groupLayouts for profile '" .. activeProfileName .. "' from runtime groups")
            activeProfile.groupLayouts = {}
            for groupName, group in pairs(ns.CDMGroups.groups) do
                if group.layout then
                    activeProfile.groupLayouts[groupName] = SerializeGroupToLayoutData(group)
                end
            end
        end
    end
    
    -- CRITICAL FIX: Don't require currentSpec to be set - the caller will handle
    -- the specSavedPositions sync. We still sync savedPositions directly.
    if activeProfile and ns.CDMGroups then
        -- Sync savedPositions (direct reference - writes go directly to profile!)
        ns.CDMGroups.savedPositions = activeProfile.savedPositions
        
        -- Sync specSavedPositions if currentSpec is known
        if ns.CDMGroups.currentSpec and ns.CDMGroups.specSavedPositions then
            ns.CDMGroups.specSavedPositions[ns.CDMGroups.currentSpec] = activeProfile.savedPositions
        end
        
        -- NOTE: iconSettings is now accessed via Shared.GetSpecIconSettings() which
        -- returns profile.iconSettings directly - no specData.iconSettings reference needed
    end
    
    -- Return the active profile for callers that need it
    return activeProfile
end

-- Get list of profile names for current spec
function ns.CDMGroups.GetProfileNames()
    local specData = GetSpecData()
    if not specData then return { "Default" } end
    EnsureLayoutProfiles(specData)
    
    local names = {}
    for name, _ in pairs(specData.layoutProfiles) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Get current active profile name
function ns.CDMGroups.GetActiveProfileName()
    local specData = GetSpecData()
    if not specData then return "Default" end
    EnsureLayoutProfiles(specData)
    return specData.activeProfile or "Default"
end

-- Get profile data by name
function ns.CDMGroups.GetProfile(profileName)
    local specData = GetSpecData()
    if not specData then return nil end
    EnsureLayoutProfiles(specData)
    return specData.layoutProfiles[profileName]
end

-- Create a new profile from current layout
function ns.CDMGroups.CreateProfile(profileName)
    if not profileName or profileName == "" then return false end
    
    local specData = GetSpecData()
    if not specData then return false end
    EnsureLayoutProfiles(specData)
    
    if specData.layoutProfiles[profileName] then
        PrintMsg("Profile '" .. profileName .. "' already exists")
        return false
    end
    
    -- Create profile with current layout
    -- CRITICAL: Include createdAt timestamp to ensure it differs from AceDB defaults
    specData.layoutProfiles[profileName] = {
        savedPositions = DeepCopy(ns.CDMGroups.savedPositions),
        freeIcons = {},
        groupLayouts = {},
        iconSettings = {},  -- Include iconSettings from the start!
        talentConditions = nil,
        matchMode = "all",
        createdAt = time(),  -- Timestamp ensures this differs from defaults
    }
    
    -- Save free icons
    for cdID, data in pairs(ns.CDMGroups.freeIcons) do
        specData.layoutProfiles[profileName].freeIcons[cdID] = {
            x = data.x,
            y = data.y,
            iconSize = data.iconSize,
        }
    end
    
    -- Save group layouts (including all layout and appearance settings)
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.layout then
            specData.layoutProfiles[profileName].groupLayouts[groupName] = {
                -- Grid settings
                gridRows = group.layout.gridRows,
                gridCols = group.layout.gridCols,
                -- Position
                position = group.position and { x = group.position.x, y = group.position.y },
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
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Save Arc Auras state (which items are tracked and their positions)
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.db and ns.db.char and ns.db.char.arcAuras then
        local arcAuras = ns.db.char.arcAuras
        if arcAuras.trackedItems and next(arcAuras.trackedItems) then
            specData.layoutProfiles[profileName].arcAuras = {
                trackedItems = DeepCopy(arcAuras.trackedItems),
                positions = arcAuras.positions and DeepCopy(arcAuras.positions) or {},
                enabled = arcAuras.enabled,
            }
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Save iconSettings (per-icon visual customizations)
    -- NOTE: iconSettings keys are STRINGS - DO NOT validate with IsCooldownIDValid
    -- ═══════════════════════════════════════════════════════════════════════════
    local profile = specData.layoutProfiles[profileName]
    profile.iconSettings = {}
    
    -- Get iconSettings from the ACTIVE PROFILE (via Shared.GetSpecIconSettings)
    local currentIconSettings = Shared.GetSpecIconSettings()
    if currentIconSettings then
        for cdID, settings in pairs(currentIconSettings) do
            -- Save ALL iconSettings - no validation needed
            profile.iconSettings[cdID] = DeepCopy(settings)
        end
    end
    
    -- NOTE: No need to switch references - Shared.GetSpecIconSettings() 
    -- automatically returns the active profile's iconSettings based on activeProfile
    
    PrintMsg("Created profile '" .. profileName .. "'")
    return true
end

-- Delete a profile
function ns.CDMGroups.DeleteProfile(profileName)
    if not profileName or profileName == "" then return false end
    if profileName == "Default" then
        PrintMsg("Cannot delete the Default profile")
        return false
    end
    
    local specData = GetSpecData()
    if not specData then return false end
    EnsureLayoutProfiles(specData)
    
    if not specData.layoutProfiles[profileName] then
        return false
    end
    
    specData.layoutProfiles[profileName] = nil
    
    -- If deleted profile was active, switch to Default
    if specData.activeProfile == profileName then
        specData.activeProfile = "Default"
        ns.CDMGroups.activeProfile = "Default"
        ns.CDMGroups.LoadProfile("Default")
    end
    
    PrintMsg("Deleted profile '" .. profileName .. "'")
    return true
end

-- Rename a profile
function ns.CDMGroups.RenameProfile(oldName, newName)
    if not oldName or oldName == "" then return false, "No profile name specified" end
    if not newName or newName == "" then return false, "No new name specified" end
    if oldName == newName then return false, "Names are the same" end
    
    -- Sanitize new name
    newName = newName:gsub("^%s+", ""):gsub("%s+$", "")  -- Trim whitespace
    if newName == "" then return false, "Invalid name" end
    
    local specData = GetSpecData()
    if not specData then return false, "No spec data" end
    EnsureLayoutProfiles(specData)
    
    -- Check source exists
    if not specData.layoutProfiles[oldName] then
        return false, "Profile '" .. oldName .. "' not found"
    end
    
    -- Check destination doesn't exist
    if specData.layoutProfiles[newName] then
        return false, "Profile '" .. newName .. "' already exists"
    end
    
    -- Move the profile data
    specData.layoutProfiles[newName] = specData.layoutProfiles[oldName]
    specData.layoutProfiles[oldName] = nil
    
    -- Update active profile reference if needed
    if specData.activeProfile == oldName then
        specData.activeProfile = newName
        ns.CDMGroups.activeProfile = newName
    end
    
    PrintMsg("Renamed profile '" .. oldName .. "' to '" .. newName .. "'")
    return true
end

-- Reset Default profile to factory settings (fresh start)
-- Creates a clean Default profile with original default groups and no icon positions
function ns.CDMGroups.ResetDefaultProfile()
    local specData = GetSpecData()
    if not specData then return false, "No spec data" end
    EnsureLayoutProfiles(specData)
    
    PrintMsg("|cff00ff00[ResetDefault]|r Resetting Default profile to factory settings...")
    
    -- Build fresh default profile with ALL default group settings
    local freshDefault = {
        savedPositions = {},
        freeIcons = {},
        groupLayouts = {},
        iconSettings = {},
        arcAuras = nil,
        talentConditions = nil,
        matchMode = "all",
    }
    
    -- Add default group layouts using the helper function for consistency
    for groupName, groupData in pairs(DEFAULT_GROUPS) do
        freshDefault.groupLayouts[groupName] = SerializeDefaultGroupToLayoutData(groupData)
    end
    
    -- Replace Default profile
    specData.layoutProfiles["Default"] = freshDefault
    
    -- Switch to Default profile
    specData.activeProfile = "Default"
    ns.CDMGroups.activeProfile = "Default"
    
    -- Update savedPositions reference to the new empty table
    ns.CDMGroups.savedPositions = freshDefault.savedPositions
    if ns.CDMGroups.specSavedPositions and ns.CDMGroups.currentSpec then
        ns.CDMGroups.specSavedPositions[ns.CDMGroups.currentSpec] = freshDefault.savedPositions
    end
    
    -- Clear runtime freeIcons
    wipe(ns.CDMGroups.freeIcons)
    
    -- Invalidate CDMEnhance cache so it reads fresh iconSettings
    if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
        ns.CDMEnhance.InvalidateCache()
    end
    
    -- Now load the profile to apply changes immediately
    -- This will destroy old groups and create new ones from freshDefault.groupLayouts
    PrintMsg("|cff00ff00[ResetDefault]|r Loading fresh Default profile...")
    ns.CDMGroups.LoadProfile("Default")
    
    PrintMsg("|cff00ff00[ResetDefault]|r Factory reset complete! Icons will auto-assign to groups.")
    return true
end

-- Save current layout to a profile
function ns.CDMGroups.SaveCurrentToProfile(profileName)
    DebugPrint("|cff00ff00[SaveProfile]|r Saving to profile:", profileName)
    
    if not profileName or profileName == "" then return false end
    
    -- CRITICAL: Don't save during restoration/transitions
    if IsRestoring() then
        DebugPrint("|cff00ff00[SaveProfile]|r BLOCKED by IsRestoring()")
        PrintMsg("Cannot save profile during restoration - please wait")
        return false
    end
    
    -- Additional protection: block saves for a period after profile load
    if ns.CDMGroups._profileSaveBlockedUntil and GetTime() < ns.CDMGroups._profileSaveBlockedUntil then
        DebugPrint("|cff00ff00[SaveProfile]|r BLOCKED by profile save cooldown")
        return false
    end
    
    local specData = GetSpecData()
    if not specData then return false end
    EnsureLayoutProfiles(specData)
    
    if not specData.layoutProfiles[profileName] then
        return ns.CDMGroups.CreateProfile(profileName)
    end
    
    local profile = specData.layoutProfiles[profileName]
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- SAVE POSITIONS: Capture current visual state from groups and free icons
    -- We iterate actual group members + free icons, NOT ns.CDMGroups.savedPositions
    -- This ensures we capture what's ACTUALLY on screen, even if savedPositions
    -- got disconnected from the profile table
    -- ═══════════════════════════════════════════════════════════════════════════
    
    -- Ensure profile has savedPositions table (for wipe)
    if not profile.savedPositions then
        profile.savedPositions = {}
    end
    
    -- CRITICAL: Wipe and refill instead of replacing reference
    wipe(profile.savedPositions)
    local posCount = 0
    
    -- Save positions from ACTUAL group members (what's visible on screen)
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        if group.members then
            for cdID, member in pairs(group.members) do
                -- Save if it has a real frame OR is a placeholder we want to keep
                local hasFrame = member.frame ~= nil
                local isPlaceholder = member.isPlaceholder
                if hasFrame or isPlaceholder then
                    profile.savedPositions[cdID] = {
                        type = "group",
                        target = groupName,
                        row = member.row or 0,
                        col = member.col or 0,
                        viewerType = member.viewerType,
                        isPlaceholder = isPlaceholder or nil,
                    }
                    posCount = posCount + 1
                    local posInfo = groupName .. "[" .. (member.row or 0) .. "," .. (member.col or 0) .. "]"
                    DebugPrint("|cff00ff00[SaveProfile]|r   ", cdID, "->", posInfo)
                end
            end
        end
    end
    
    -- Save free icons positions from actual freeIcons state
    for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
        local hasFrame = data.frame ~= nil
        local isPlaceholder = data.isPlaceholder
        if hasFrame or isPlaceholder then
            profile.savedPositions[cdID] = {
                type = "free",
                x = data.x or 0,
                y = data.y or 0,
                iconSize = data.iconSize or 36,
                viewerType = data.viewerType,
                isPlaceholder = isPlaceholder or nil,
            }
            posCount = posCount + 1
            DebugPrint("|cff00ff00[SaveProfile]|r   freeIcon:", cdID, "x:", math.floor(data.x or 0), "y:", math.floor(data.y or 0))
        end
    end
    
    -- CRITICAL: Sync the runtime reference to this profile's table
    ns.CDMGroups.savedPositions = profile.savedPositions
    if ns.CDMGroups.specSavedPositions and ns.CDMGroups.currentSpec then
        ns.CDMGroups.specSavedPositions[ns.CDMGroups.currentSpec] = profile.savedPositions
    end
    
    -- Save free icons to separate table (for freeIcons-specific data like runtime state)
    if not profile.freeIcons then
        profile.freeIcons = {}
    end
    wipe(profile.freeIcons)
    local freeCount = 0
    for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
        if data.frame or data.isPlaceholder then
            freeCount = freeCount + 1
            profile.freeIcons[cdID] = {
                x = data.x or 0,
                y = data.y or 0,
                iconSize = data.iconSize or 36,
            }
        end
    end
    
    -- Save group layouts (including all layout and appearance settings)
    profile.groupLayouts = {}
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.layout then
            profile.groupLayouts[groupName] = {
                -- Grid settings
                gridRows = group.layout.gridRows,
                gridCols = group.layout.gridCols,
                -- Position
                position = group.position and { x = group.position.x, y = group.position.y },
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
    
    -- Save iconSettings (per-icon visual customizations) from specData
    -- NOTE: iconSettings keys are STRINGS (e.g., "14948", "arc_trinket_14")
    -- DO NOT validate with IsCooldownIDValid - that expects numeric cooldownIDs
    -- These are just visual settings and should always be preserved
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- MIGRATION: If legacy specData.iconSettings exists, migrate to profile
    -- After migration, Shared.GetSpecIconSettings() reads from profile directly
    -- ═══════════════════════════════════════════════════════════════════════════
    if specData.iconSettings and specData.iconSettings ~= profile.iconSettings then
        -- Legacy data exists and it's not the same table - migrate it
        if not profile.iconSettings then
            profile.iconSettings = {}
        end
        -- Migrate any settings not already in profile
        local migratedCount = 0
        for cdID, settings in pairs(specData.iconSettings) do
            if not profile.iconSettings[cdID] then
                profile.iconSettings[cdID] = DeepCopy(settings)
                migratedCount = migratedCount + 1
            end
        end
        -- Clean up legacy storage
        specData.iconSettings = nil
        if migratedCount > 0 then
            PrintMsg("|cff00ff00[SaveProfile]|r Migrated " .. migratedCount .. " iconSettings to profile")
        end
        PrintMsg("|cffff8800[SaveProfile]|r Cleared legacy specData.iconSettings")
    end
    
    -- NOTE: iconSettings is now accessed via Shared.GetSpecIconSettings() which
    -- returns profile.iconSettings directly - no specData.iconSettings needed
    
    local iconSettingsCount = 0
    for _ in pairs(profile.iconSettings or {}) do iconSettingsCount = iconSettingsCount + 1 end
    DebugPrint("|cff00ff00[SaveProfile]|r Profile has", iconSettingsCount, "iconSettings entries")
    
    -- NOTE: We intentionally do NOT sync back to specData.savedPositions/freeIcons
    -- The Arc Manager profile is the authoritative source. Legacy storage is
    -- only used for migration from old addon versions.
    
    -- NOTE: ns.CDMGroups.savedPositions IS profile.savedPositions (direct reference)
    -- so the profile is already updated - no need to wipe/copy
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Save Arc Auras state (which items are tracked and their positions)
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.db and ns.db.char and ns.db.char.arcAuras then
        local arcAuras = ns.db.char.arcAuras
        if arcAuras.trackedItems and next(arcAuras.trackedItems) then
            profile.arcAuras = {
                trackedItems = DeepCopy(arcAuras.trackedItems),
                positions = arcAuras.positions and DeepCopy(arcAuras.positions) or {},
                enabled = arcAuras.enabled,
            }
            local arcAurasCount = 0
            for _ in pairs(arcAuras.trackedItems) do arcAurasCount = arcAurasCount + 1 end
            DebugPrint("|cff00ff00[SaveProfile]|r Saved", arcAurasCount, "Arc Auras items")
        else
            -- Clear Arc Auras from profile if none are tracked
            profile.arcAuras = nil
        end
    end
    
    DebugPrint("|cff00ff00[SaveProfile]|r Saved", posCount, "positions,", freeCount, "freeIcons (skipped", skippedCount, "invalid)")
    PrintMsg("Saved layout to profile '" .. profileName .. "'")
    return true
end

-- Load a profile's layout
function ns.CDMGroups.LoadProfile(profileName, skipActivation)
    DebugPrint("|cffff9900[LoadProfile]|r Loading profile:", profileName)
    
    if not profileName or profileName == "" then return false end
    
    -- Prevent re-entry during load
    if ns.CDMGroups.profileLoadInProgress then
        DebugPrint("|cffff9900[LoadProfile]|r BLOCKED: Already in progress")
        return false
    end
    
    local specData = GetSpecData()
    if not specData then 
        return false 
    end
    EnsureLayoutProfiles(specData)
    
    local profile = specData.layoutProfiles[profileName]
    if not profile then
        PrintMsg("Profile '" .. profileName .. "' not found")
        return false
    end
    
    -- Show profile contents being loaded
    DebugPrint("|cffff9900[LoadProfile]|r Profile contents:")
    local savedPosCount = 0
    if profile.savedPositions then
        for cdID, pos in pairs(profile.savedPositions) do
            savedPosCount = savedPosCount + 1
            local posInfo = pos.type == "group" and (pos.target .. "[" .. (pos.row or "?") .. "," .. (pos.col or "?") .. "]") or "FREE"
            DebugPrint("|cffff9900[LoadProfile]|r   ", cdID, "->", posInfo)
        end
    end
    local freeIconCount = 0
    if profile.freeIcons then
        for cdID, data in pairs(profile.freeIcons) do
            freeIconCount = freeIconCount + 1
            DebugPrint("|cffff9900[LoadProfile]|r   freeIcon:", cdID, "x:", math.floor(data.x), "y:", math.floor(data.y))
        end
    end
    DebugPrint("|cffff9900[LoadProfile]|r Total:", savedPosCount, "positions,", freeIconCount, "freeIcons")
    
    -- Set protection flags
    ns.CDMGroups.profileLoadInProgress = true
    ns.CDMGroups.lastSpecChangeTime = GetTime()
    -- Block profile saves for 2 seconds after profile load to prevent overwrites
    ns.CDMGroups._profileSaveBlockedUntil = GetTime() + 2.0
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- SWITCH to new profile's savedPositions (DIRECT REFERENCE)
    -- ═══════════════════════════════════════════════════════════════════════════
    -- The profile's savedPositions IS the authoritative source. We switch
    -- ns.CDMGroups.savedPositions to point directly to the new profile's table.
    -- This means all future writes go directly to the profile.
    -- ═══════════════════════════════════════════════════════════════════════════
    if not profile.savedPositions then
        profile.savedPositions = {}
    end
    
    -- SWITCH the reference - savedPositions now IS the profile table
    ns.CDMGroups.savedPositions = profile.savedPositions
    ns.CDMGroups.specSavedPositions[ns.CDMGroups.currentSpec] = profile.savedPositions
    
    local savedPosCountAfter = 0
    for _ in pairs(ns.CDMGroups.savedPositions) do savedPosCountAfter = savedPosCountAfter + 1 end
    DebugPrint("|cffff9900[LoadProfile]|r Switched to profile savedPositions:", savedPosCountAfter, "positions")
    
    -- NOTE: We intentionally do NOT sync to specData.savedPositions anymore.
    -- The Arc Manager profile is the authoritative source.
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 1: COLLECT ALL FRAMES FROM MULTIPLE SOURCES
    -- We need to collect from:
    --   1. Currently managed groups (ns.CDMGroups.groups)
    --   2. Currently free icons (ns.CDMGroups.freeIcons)
    --   3. CDM viewers directly (for frames that got stuck/orphaned)
    -- ═══════════════════════════════════════════════════════════════════════════
    local allFrames = {}
    
    -- From groups
    for groupName, group in pairs(ns.CDMGroups.groups) do
        for cdID, member in pairs(group.members) do
            if member.frame then
                allFrames[cdID] = {
                    frame = member.frame,
                    entry = member.entry,
                    viewerType = member.viewerType,
                    originalViewerName = member.originalViewerName,
                }
            end
        end
    end
    
    -- From free icons
    for cdID, data in pairs(ns.CDMGroups.freeIcons) do
        if data.frame then
            allFrames[cdID] = {
                frame = data.frame,
                entry = data.entry,
                viewerType = data.viewerType,
                originalViewerName = data.originalViewerName,
            }
        end
    end
    
    -- CRITICAL: Also scan CDM viewers directly to catch any stuck/orphaned frames
    -- This is what "Scan & Assign" does - we need to do it during profile load too
    if ns.FrameController and ns.FrameController.ScanCDMViewers then
        local cdmState = ns.FrameController.ScanCDMViewers()
        for cdID, cdmData in pairs(cdmState) do
            -- Only add if not already in allFrames (groups/freeIcons take precedence)
            if not allFrames[cdID] and cdmData.frame then
                allFrames[cdID] = {
                    frame = cdmData.frame,
                    entry = nil,  -- CDM frames don't have entry data
                    viewerType = cdmData.viewerType,
                    originalViewerName = cdmData.viewerName,
                    defaultGroup = cdmData.defaultGroup,
                }
            end
        end
    end
    
    local collectedCount = 0
    for _ in pairs(allFrames) do collectedCount = collectedCount + 1 end
    DebugPrint("|cffff9900[LoadProfile]|r Collected", collectedCount, "frames before reassignment")
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 2: CLEAR TRACKING (but DON'T hide/return frames yet)
    -- ═══════════════════════════════════════════════════════════════════════════
    for groupName, group in pairs(ns.CDMGroups.groups) do
        wipe(group.members)
        wipe(group.grid)
    end
    wipe(ns.CDMGroups.freeIcons)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL: Update activeProfile BEFORE group sync
    -- This ensures CreateGroup adds new groups to the correct profile
    -- ═══════════════════════════════════════════════════════════════════════════
    if not skipActivation then
        specData.activeProfile = profileName
        ns.CDMGroups.activeProfile = profileName
        DebugPrint("|cffff9900[LoadProfile]|r Set activeProfile to:", profileName)
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Ensure profile.iconSettings exists
    -- NOTE: iconSettings is now accessed via Shared.GetSpecIconSettings() which
    -- returns profile.iconSettings directly based on activeProfile
    -- No specData.iconSettings reference needed
    -- ═══════════════════════════════════════════════════════════════════════════
    if not profile.iconSettings then
        profile.iconSettings = {}
    end
    local iconSettingsCount = 0
    for _ in pairs(profile.iconSettings) do iconSettingsCount = iconSettingsCount + 1 end
    DebugPrint("|cffff9900[LoadProfile]|r Profile has", iconSettingsCount, "iconSettings")
    
    -- Clean up legacy specData.iconSettings if it exists
    if specData.iconSettings then
        PrintMsg("|cffff8800[LoadProfile]|r Cleared legacy specData.iconSettings")
        specData.iconSettings = nil
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 2.5: SYNC GROUPS TO MATCH PROFILE
    -- Destroy groups not in profile.groupLayouts
    -- Create groups that are in profile.groupLayouts but don't exist
    -- This ensures each profile has its own set of groups
    -- CRITICAL: If profile has no groupLayouts, use DEFAULT_GROUPS
    -- ═══════════════════════════════════════════════════════════════════════════
    
    -- Build set of groups that should exist in this profile
    -- CRITICAL: Fall back to DEFAULT_GROUPS if profile has no saved groups
    local hasGroupLayouts = profile.groupLayouts and next(profile.groupLayouts)
    local sourceGroupLayouts = hasGroupLayouts and profile.groupLayouts or DEFAULT_GROUPS
    
    local profileGroups = {}
    for groupName in pairs(sourceGroupLayouts) do
        profileGroups[groupName] = true
    end
    
    -- If we're using DEFAULT_GROUPS, also save them to the profile so future loads work
    if not hasGroupLayouts then
        PrintMsg("|cff00ff00[LoadProfile]|r Profile has no groups - creating default groups (Essential, Utility, Buffs)")
        profile.groupLayouts = {}
        for groupName, groupData in pairs(DEFAULT_GROUPS) do
            -- Use helper to ensure consistent serialization (excludes runtime fields like members/grid)
            profile.groupLayouts[groupName] = SerializeDefaultGroupToLayoutData(groupData)
        end
    end
    
    -- Destroy groups NOT in the profile
    local groupsToDestroy = {}
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if not profileGroups[groupName] then
            table.insert(groupsToDestroy, groupName)
        end
    end
    
    for _, groupName in ipairs(groupsToDestroy) do
        local group = ns.CDMGroups.groups[groupName]
        if group then
            DebugPrint("|cffff9900[LoadProfile]|r Destroying group not in profile:", groupName)
            
            -- ═══════════════════════════════════════════════════════════════════
            -- COMPREHENSIVE GROUP UI CLEANUP
            -- Must fully destroy all UI elements to prevent ghost artifacts
            -- ═══════════════════════════════════════════════════════════════════
            
            -- Hide and orphan edge arrows first - they're parented to UIParent, not container!
            if group.edgeArrows then
                for _, arrow in pairs(group.edgeArrows) do
                    if arrow then
                        arrow:ClearAllPoints()
                        arrow:Hide()
                        arrow:SetParent(nil)
                    end
                end
                wipe(group.edgeArrows)
            end
            
            -- Hide and orphan drag toggle button (parented to UIParent!)
            if group.dragToggleBtn then
                group.dragToggleBtn:ClearAllPoints()
                group.dragToggleBtn:Hide()
                group.dragToggleBtn:SetParent(nil)
                group.dragToggleBtn = nil
            end
            
            -- Hide and orphan drag bar
            if group.dragBar then
                group.dragBar:ClearAllPoints()
                group.dragBar:Hide()
                group.dragBar:SetParent(nil)
                group.dragBar = nil
            end
            
            -- Hide and orphan selection highlight
            if group.selectionHighlight then
                group.selectionHighlight:ClearAllPoints()
                group.selectionHighlight:Hide()
                group.selectionHighlight:SetParent(nil)
                group.selectionHighlight = nil
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
            
            -- Remove from runtime tables
            ns.CDMGroups.groups[groupName] = nil
            ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec][groupName] = nil
            -- Also remove from specData.groups so it doesn't come back
            if specData.groups then
                specData.groups[groupName] = nil
            end
        end
    end
    
    -- Create groups that ARE in the profile but don't exist yet
    local createdCount = 0
    for groupName in pairs(profileGroups) do
        if not ns.CDMGroups.groups[groupName] then
            DebugPrint("|cffff9900[LoadProfile]|r Creating group from profile:", groupName)
            -- CreateGroup will read layout from profile.groupLayouts later
            local newGroup = ns.CDMGroups.CreateGroup(groupName)
            if newGroup then
                createdCount = createdCount + 1
                -- Pre-apply layout settings from profile so container has correct size
                local layoutData = profile.groupLayouts[groupName]
                if layoutData and newGroup.layout then
                    if layoutData.gridRows then newGroup.layout.gridRows = layoutData.gridRows end
                    if layoutData.gridCols then newGroup.layout.gridCols = layoutData.gridCols end
                    if layoutData.iconSize then newGroup.layout.iconSize = layoutData.iconSize end
                    if layoutData.iconWidth then newGroup.layout.iconWidth = layoutData.iconWidth end
                    if layoutData.iconHeight then newGroup.layout.iconHeight = layoutData.iconHeight end
                    if layoutData.spacing then newGroup.layout.spacing = layoutData.spacing end
                end
                -- Position
                if layoutData and layoutData.position and newGroup.container then
                    newGroup.position = { x = layoutData.position.x, y = layoutData.position.y }
                    newGroup.container:ClearAllPoints()
                    newGroup.container:SetPoint("CENTER", UIParent, "CENTER", layoutData.position.x, layoutData.position.y)
                end
            end
        end
    end
    
    local destroyedCount = #groupsToDestroy
    if destroyedCount > 0 or createdCount > 0 then
        DebugPrint("|cffff9900[LoadProfile]|r Group sync: destroyed", destroyedCount, ", created", createdCount)
    end
    
    -- CRITICAL: Notify FrameController that layout changed (ensures hidden frames get fixed)
    if ns.FrameController and ns.FrameController.OnLayoutChange then
        ns.FrameController.OnLayoutChange()
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 3: REASSIGN FRAMES TO NEW POSITIONS FROM PROFILE
    -- ═══════════════════════════════════════════════════════════════════════════
    local assignedToGroup = 0
    local assignedToFree = 0
    local orphaned = 0
    
    for cdID, frameData in pairs(allFrames) do
        local frame = frameData.frame
        local entry = frameData.entry
        local saved = profile.savedPositions and profile.savedPositions[cdID]
        
        -- CRITICAL FIX: Create entry if nil (for CDM-sourced frames)
        -- Without this, entry.group is never set and instant layout fails
        if not entry and frame and ns.FrameRegistry and ns.FrameRegistry.GetOrCreate then
            entry = ns.FrameRegistry:GetOrCreate(frame, frameData.originalViewerName or "LoadProfile")
            frameData.entry = entry
        end
        
        if saved and saved.type == "group" and saved.target then
            -- Assign to group at saved position
            local group = ns.CDMGroups.groups[saved.target]
            if group then
                local row = saved.row or 0
                local col = saved.col or 0
                
                -- Add to group members (INCLUDE entry reference!)
                group.members[cdID] = {
                    frame = frame,
                    entry = entry,  -- Now entry is not nil
                    row = row,
                    col = col,
                    targetParent = group.container,
                    viewerType = frameData.viewerType,
                    originalViewerName = frameData.originalViewerName,
                }
                
                -- Claim grid position
                group.grid[row] = group.grid[row] or {}
                group.grid[row][col] = cdID
                
                -- Parent to group container
                frame:SetParent(group.container)
                -- Only show if not hidden due to hideWhenUnequipped setting
                if not frame._arcHiddenUnequipped and not IsFrameHiddenByBar(frame) then
                    frame:Show()
                end
                
                -- CRITICAL FIX: Set entry.group to GROUP OBJECT, not string!
                -- This is what AddMemberAtWithFrame does, and why drag fixes the issue
                if entry then
                    entry.manipulated = true
                    entry.manipulationType = "group"
                    entry.group = group  -- GROUP OBJECT, not saved.target (string)!
                end
                
                assignedToGroup = assignedToGroup + 1
                DebugPrint("|cffff9900[LoadProfile]|r   ", cdID, "-> group", saved.target, "[", row, ",", col, "]")
            else
                -- Group doesn't exist - convert to free icon in a grid sequence
                -- Calculate position based on orphan count to avoid stacking
                local orphanSpacing = 42
                local orphanCols = 8
                local orphanCol = orphaned % orphanCols
                local orphanRow = math.floor(orphaned / orphanCols)
                local totalWidth = (orphanCols - 1) * orphanSpacing
                local orphanX = -totalWidth/2 + (orphanCol * orphanSpacing)
                local orphanY = 200 - (orphanRow * orphanSpacing)  -- Start above center
                
                frame:SetParent(UIParent)
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", orphanX, orphanY)
                frame:SetFrameStrata("MEDIUM")
                frame:SetScale(1)
                -- Only show if not hidden due to hideWhenUnequipped setting
                if not frame._arcHiddenUnequipped and not IsFrameHiddenByBar(frame) then
                    frame:SetAlpha(1)
                    frame:Show()
                end
                frame._cdmgIsFreeIcon = true
                
                ns.CDMGroups.freeIcons[cdID] = {
                    frame = frame,
                    entry = entry,
                    x = orphanX,
                    y = orphanY,
                    iconSize = 36,
                    viewerType = frameData.viewerType,
                    originalViewerName = frameData.originalViewerName,
                }
                
                if entry then
                    entry.manipulated = true
                    entry.manipulationType = "free"
                    entry.group = nil
                end
                
                -- Set up drag handlers for free icon
                if ns.CDMGroups.SetupFreeIconDrag then
                    ns.CDMGroups.SetupFreeIconDrag(cdID)
                end
                
                DebugPrint("|cffff9900[LoadProfile]|r   ", cdID, "-> group", saved.target, "NOT FOUND, converted to FREE at", math.floor(orphanX), ",", math.floor(orphanY))
                orphaned = orphaned + 1
            end
            
        elseif saved and saved.type == "free" then
            -- Assign to free position
            local x = saved.x or 0
            local y = saved.y or 0
            local iconSize = saved.iconSize or 36
            
            frame:SetParent(UIParent)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
            frame:SetFrameStrata("MEDIUM")
            frame:SetScale(1)
            -- Only show if not hidden due to hideWhenUnequipped setting
            if not frame._arcHiddenUnequipped and not IsFrameHiddenByBar(frame) then
                frame:SetAlpha(1)
                frame:Show()
            end
            frame._cdmgIsFreeIcon = true
            
            ns.CDMGroups.freeIcons[cdID] = {
                frame = frame,
                entry = entry,
                x = x,
                y = y,
                iconSize = iconSize,
                viewerType = frameData.viewerType,
                originalViewerName = frameData.originalViewerName,
            }
            
            if entry then
                entry.manipulated = true
                entry.manipulationType = "free"
                entry.group = nil
            end
            
            -- Set up drag handlers for free icon
            ns.CDMGroups.SetupFreeIconDrag(cdID)
            
            assignedToFree = assignedToFree + 1
            DebugPrint("|cffff9900[LoadProfile]|r   ", cdID, "-> FREE at", math.floor(x), ",", math.floor(y))
            
        else
            -- No saved position in new profile - make it a free icon
            -- (Don't auto-assign to groups - keep imported profile layout intact)
            local newOrphaned = orphaned
            local orphanSpacing = 42
            local orphanCols = 8
            local orphanCol = newOrphaned % orphanCols
            local orphanRow = math.floor(newOrphaned / orphanCols)
            local totalWidth = (orphanCols - 1) * orphanSpacing
            local orphanX = -totalWidth/2 + (orphanCol * orphanSpacing)
            local orphanY = 200 - (orphanRow * orphanSpacing)
            
            frame:SetParent(UIParent)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", orphanX, orphanY)
            frame:SetFrameStrata("MEDIUM")
            frame:SetScale(1)
            -- Only show if not hidden due to hideWhenUnequipped setting
            if not frame._arcHiddenUnequipped and not IsFrameHiddenByBar(frame) then
                frame:SetAlpha(1)
                frame:Show()
            end
            frame._cdmgIsFreeIcon = true
            
            ns.CDMGroups.freeIcons[cdID] = {
                frame = frame,
                entry = entry,
                x = orphanX,
                y = orphanY,
                iconSize = 36,
                viewerType = frameData.viewerType,
                originalViewerName = frameData.originalViewerName,
            }
            
            if entry then
                entry.manipulated = true
                entry.manipulationType = "free"
                entry.group = nil
            end
            
            if ns.CDMGroups.SetupFreeIconDrag then
                ns.CDMGroups.SetupFreeIconDrag(cdID)
            end
            
            DebugPrint("|cffff9900[LoadProfile]|r   ", cdID, "-> no saved position, made FREE at", math.floor(orphanX), ",", math.floor(orphanY))
            orphaned = orphaned + 1
        end
    end
    
    DebugPrint("|cffff9900[LoadProfile]|r Reassigned:", assignedToGroup, "to groups,", assignedToFree, "to free,", orphaned, "orphaned")
    
    -- Apply group layouts (all layout and appearance settings)
    if profile.groupLayouts then
        for groupName, layoutData in pairs(profile.groupLayouts) do
            local group = ns.CDMGroups.groups[groupName]
            if group and group.layout then
                -- Grid settings
                if layoutData.gridRows then
                    group.layout.gridRows = layoutData.gridRows
                end
                if layoutData.gridCols then
                    group.layout.gridCols = layoutData.gridCols
                end
                -- Layout settings - ALWAYS apply if profile has them
                if layoutData.iconSize ~= nil then
                    group.layout.iconSize = layoutData.iconSize
                end
                if layoutData.iconWidth ~= nil then
                    group.layout.iconWidth = layoutData.iconWidth
                end
                if layoutData.iconHeight ~= nil then
                    group.layout.iconHeight = layoutData.iconHeight
                end
                if layoutData.spacing ~= nil then
                    group.layout.spacing = layoutData.spacing
                end
                if layoutData.spacingX ~= nil then
                    group.layout.spacingX = layoutData.spacingX
                end
                if layoutData.spacingY ~= nil then
                    group.layout.spacingY = layoutData.spacingY
                end
                if layoutData.separateSpacing ~= nil then
                    group.layout.separateSpacing = layoutData.separateSpacing
                end
                if layoutData.alignment ~= nil then
                    group.layout.alignment = layoutData.alignment
                end
                if layoutData.horizontalGrowth ~= nil then
                    group.layout.horizontalGrowth = layoutData.horizontalGrowth
                end
                if layoutData.verticalGrowth ~= nil then
                    group.layout.verticalGrowth = layoutData.verticalGrowth
                end
                -- Appearance
                if layoutData.showBorder ~= nil then
                    group.showBorder = layoutData.showBorder
                end
                if layoutData.showBackground ~= nil then
                    group.showBackground = layoutData.showBackground
                end
                if layoutData.autoReflow ~= nil then
                    group.autoReflow = layoutData.autoReflow ~= false
                end
                if layoutData.dynamicLayout ~= nil then
                    group.dynamicLayout = layoutData.dynamicLayout
                end
                
                -- Ensure alignment has a default value when dynamicLayout is enabled
                -- The UI shows "Center" as default but if user never changed it, alignment is nil
                -- Having an explicit value ensures consistent behavior in layout calculations
                if group.dynamicLayout and not group.layout.alignment then
                    local rows = group.layout.gridRows or 1
                    local cols = group.layout.gridCols or 1
                    local gridShape = ns.CDMGroups.DetectGridShape and ns.CDMGroups.DetectGridShape(rows, cols) or "horizontal"
                    local defaultAlignment = ns.CDMGroups.GetDefaultAlignment and ns.CDMGroups.GetDefaultAlignment(gridShape) or "center"
                    group.layout.alignment = defaultAlignment
                    DebugPrint("|cffff9900[LoadProfile]|r Set default alignment for", groupName, ":", defaultAlignment)
                end
                
                if layoutData.lockGridSize ~= nil then
                    group.lockGridSize = layoutData.lockGridSize
                end
                if layoutData.containerPadding ~= nil then
                    group.containerPadding = layoutData.containerPadding
                end
                -- Visibility
                if layoutData.visibility ~= nil then
                    group.visibility = layoutData.visibility
                end
                -- Position
                if layoutData.position then
                    group.position = { x = layoutData.position.x, y = layoutData.position.y }
                    if group.container then
                        group.container:ClearAllPoints()
                        group.container:SetPoint("CENTER", UIParent, "CENTER", layoutData.position.x, layoutData.position.y)
                    end
                end
                
                -- NOTE: We no longer sync to specData.groups (legacy location)
                -- profile.groupLayouts is now the single source of truth
                -- Runtime group objects are updated above, profile is already correct
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL: Invalidate CDMEnhance settings cache after profile switch
    -- Note: iconSettings reference was already switched in STEP 2 (after activeProfile)
    -- Without this, cached settings will be stale and icons won't get new appearance
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
        ns.CDMEnhance.InvalidateCache()
        DebugPrint("|cffff9900[LoadProfile]|r Invalidated CDMEnhance settings cache")
    end
    
    -- CRITICAL: Refresh all icon styles to apply the new iconSettings
    -- InvalidateCache clears the cache, but RefreshAllStyles actually re-applies settings
    if ns.CDMEnhance and ns.CDMEnhance.RefreshAllStyles then
        C_Timer.After(0.15, function()
            ns.CDMEnhance.RefreshAllStyles()
            DebugPrint("|cffff9900[LoadProfile]|r Refreshed all icon styles")
        end)
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Restore Arc Auras tracking data (DON'T destroy frames - Step 3 already positioned them)
    -- ═══════════════════════════════════════════════════════════════════════════
    if profile.arcAuras and profile.arcAuras.trackedItems then
        -- Ensure char.arcAuras exists
        if not ns.db.char then ns.db.char = {} end
        if not ns.db.char.arcAuras then
            ns.db.char.arcAuras = {
                enabled = false,
                trackedItems = {},
                positions = {},
                globalSettings = {},
            }
        end
        
        local arcAuras = ns.db.char.arcAuras
        
        -- DON'T destroy frames - Step 3 already moved them to correct positions!
        -- Just sync the tracking data from profile
        
        -- Sync tracked items
        wipe(arcAuras.trackedItems)
        for arcID, config in pairs(profile.arcAuras.trackedItems) do
            arcAuras.trackedItems[arcID] = DeepCopy(config)
        end
        
        -- Sync positions to char DB (for backwards compat)
        if profile.arcAuras.positions then
            wipe(arcAuras.positions)
            for arcID, pos in pairs(profile.arcAuras.positions) do
                arcAuras.positions[arcID] = DeepCopy(pos)
            end
        end
        
        -- Sync enabled state
        if profile.arcAuras.enabled ~= nil then
            arcAuras.enabled = profile.arcAuras.enabled
        end
        
        local arcAurasCount = 0
        for _ in pairs(profile.arcAuras.trackedItems) do arcAurasCount = arcAurasCount + 1 end
        DebugPrint("|cffff9900[LoadProfile]|r Synced", arcAurasCount, "Arc Auras tracking data (frames already positioned)")
    end
    
    -- NOTE: activeProfile already set in STEP 2 (before group sync)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 4: LAYOUT AND FINALIZE
    -- Frames are already assigned - just need to layout groups and finalize
    -- ═══════════════════════════════════════════════════════════════════════════
    C_Timer.After(0.1, function()
        -- Layout all groups to position frames correctly
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.Layout then group:Layout() end
        end
        
        -- CRITICAL: Setup dynamic layout hooks for ALL groups with Dynamic Auras enabled
        -- This ensures instant layout works for ALL alignments after profile load
        local DL = ns.CDMGroups.DynamicLayout
        if DL and DL.SetupDynamicLayoutHooks then
            for groupName, group in pairs(ns.CDMGroups.groups) do
                if group.dynamicLayout then
                    DL.SetupDynamicLayoutHooks(group)
                end
            end
        end
        
        -- Reflow icons for groups with Fill Gaps enabled
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.autoReflow and group.ReflowIcons then
                group:ReflowIcons()
            end
        end
        
        -- Restore Arc Auras positions (external frames not in allFrames collection)
        local arcRestored, arcOrphans = ns.CDMGroups.RestoreArcAurasPositions("|cffff9900[LoadProfile]|r")
        if arcRestored > 0 or arcOrphans > 0 then
            DebugPrint("|cffff9900[LoadProfile]|r Arc Auras: restored", arcRestored, "orphans", arcOrphans)
        end
        
        -- Trigger CDMEnhance refresh if available
        if ns.CDMEnhance and ns.CDMEnhance.RefreshAllIcons then
            ns.CDMEnhance.RefreshAllIcons()
        end
        
        -- Force show all icons after profile load
        if ns.CDMEnhance and ns.CDMEnhance.ForceShowAllCDMIcons then
            ns.CDMEnhance.ForceShowAllCDMIcons()
        end
        
        -- Clear profile load flag after a short delay to let positions settle
        C_Timer.After(0.3, function()
            ns.CDMGroups.profileLoadInProgress = false
            -- Record when we last switched profiles (for cooldown)
            ns.CDMGroups._lastProfileSwitchTime = GetTime()
            
            -- Deactivate ImportRestore since profile loaded successfully
            if ns.CDMGroups.ImportRestore and ns.CDMGroups.ImportRestore.OnProfileLoaded then
                ns.CDMGroups.ImportRestore.OnProfileLoaded()
            end
            
            DebugPrint("|cffff9900[LoadProfile]|r Complete")
            
            -- Final force show to catch any stragglers
            if ns.CDMEnhance and ns.CDMEnhance.ForceShowAllCDMIcons then
                ns.CDMEnhance.ForceShowAllCDMIcons()
            end
            
            -- Update visibility based on combat state
            ns.CDMGroups.UpdateGroupVisibility()
            
            -- Ensure container click-through state is correct after profile load
            ns.CDMGroups.UpdateGroupSelectionVisuals()
        end)
    end)
    
    DebugPrint("|cffff9900[LoadProfile]|r Loaded profile '" .. profileName .. "'")
    return true
end

-- Set talent conditions for a profile
function ns.CDMGroups.SetProfileTalentConditions(profileName, conditions, matchMode)
    if not profileName or profileName == "" then return false end
    
    local specData = GetSpecData()
    if not specData then return false end
    EnsureLayoutProfiles(specData)
    
    local profile = specData.layoutProfiles[profileName]
    if not profile then return false end
    
    profile.talentConditions = conditions
    profile.matchMode = matchMode or "all"
    
    return true
end

-- Get talent conditions for a profile
function ns.CDMGroups.GetProfileTalentConditions(profileName)
    local specData = GetSpecData()
    if not specData then return nil, "all" end
    EnsureLayoutProfiles(specData)
    
    local profile = specData.layoutProfiles[profileName]
    if not profile then return nil, "all" end
    
    return profile.talentConditions, profile.matchMode or "all"
end

-- Check if a profile's talent conditions match current talents
local function CheckProfileConditions(profile)
    if not profile then return false end
    
    -- No conditions = this is a fallback profile (like Default)
    if not profile.talentConditions or #profile.talentConditions == 0 then
        return false  -- Don't auto-activate profiles without conditions
    end
    
    -- Use TalentPicker's condition checker if available
    if ns.TalentPicker and ns.TalentPicker.CheckTalentConditions then
        local result = ns.TalentPicker.CheckTalentConditions(profile.talentConditions, profile.matchMode)
        DebugPrint("|cff00ff00[ProfileDebug]|r      CheckTalentConditions result:", tostring(result))
        return result
    end
    
    -- Fallback: manual check
    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID()
    if not configID then 
        DebugPrint("|cff00ff00[ProfileDebug]|r      No configID available")
        return false 
    end
    
    local matchMode = profile.matchMode or "all"
    DebugPrint("|cff00ff00[ProfileDebug]|r      Manual check, matchMode:", matchMode, "conditions:", #profile.talentConditions)
    
    for _, condition in ipairs(profile.talentConditions) do
        local nodeID = condition.nodeID
        local required = condition.required ~= false
        
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
        
        -- For hero talents (subTreeID exists), must also check subTreeActive
        local isSelected = false
        if nodeInfo then
            local hasRank = (nodeInfo.activeRank or 0) > 0
            if nodeInfo.subTreeID then
                -- Hero talent - must have rank AND subtree active
                isSelected = hasRank and (nodeInfo.subTreeActive == true)
            else
                -- Class/spec talent
                isSelected = hasRank
            end
        end
        
        DebugPrint("|cff00ff00[ProfileDebug]|r        Node", nodeID, "required:", tostring(required), "isSelected:", tostring(isSelected))
        
        if required then
            if matchMode == "all" and not isSelected then
                return false
            elseif matchMode == "any" and isSelected then
                return true
            end
        else
            if matchMode == "all" and isSelected then
                return false
            elseif matchMode == "any" and not isSelected then
                return true
            end
        end
    end
    
    return matchMode == "all"
end

-- Find and activate the first matching profile
function ns.CDMGroups.CheckAndActivateMatchingProfile()
    -- ═══════════════════════════════════════════════════════════════════════════
    -- DISABLED: Talent-based profile switching is under construction
    -- Existing talent conditions in profiles are preserved but ignored.
    -- This prevents frames getting stuck during talent changes.
    -- ═══════════════════════════════════════════════════════════════════════════
    DebugPrint("|cff00ff00[ProfileDebug]|r CheckAndActivateMatchingProfile - DISABLED (under construction)")
    return
end

--[[ ORIGINAL IMPLEMENTATION - PRESERVED FOR FUTURE USE
function ns.CDMGroups.CheckAndActivateMatchingProfile_DISABLED()
    DebugPrint("|cff00ff00[ProfileDebug]|r CheckAndActivateMatchingProfile called")
    
    -- Don't auto-switch profiles during restoration or other transitions
    if IsRestoring() then 
        DebugPrint("|cff00ff00[ProfileDebug]|r  -> BLOCKED: IsRestoring() returned true")
        DebugPrint("|cff00ff00[ProfileDebug]|r     initialLoadInProgress:", tostring(ns.CDMGroups.initialLoadInProgress))
        DebugPrint("|cff00ff00[ProfileDebug]|r     specChangeInProgress:", tostring(ns.CDMGroups.specChangeInProgress))
        DebugPrint("|cff00ff00[ProfileDebug]|r     talentChangeInProgress:", tostring(ns.CDMGroups.talentChangeInProgress))
        DebugPrint("|cff00ff00[ProfileDebug]|r     profileLoadInProgress:", tostring(ns.CDMGroups.profileLoadInProgress))
        return 
    end
    
    local specData = GetSpecData()
    if not specData then 
        DebugPrint("|cff00ff00[ProfileDebug]|r  -> BLOCKED: No specData")
        return 
    end
    EnsureLayoutProfiles(specData)
    
    local currentProfile = specData.activeProfile or "Default"
    local matchedProfile = nil
    
    DebugPrint("|cff00ff00[ProfileDebug]|r  Current active profile:", currentProfile)
    DebugPrint("|cff00ff00[ProfileDebug]|r  Checking profiles for talent match...")
    
    -- Check all profiles with talent conditions
    for profileName, profile in pairs(specData.layoutProfiles) do
        DebugPrint("|cff00ff00[ProfileDebug]|r    Profile:", profileName, "has conditions:", profile.talentConditions and #profile.talentConditions or 0)
        if profile.talentConditions and #profile.talentConditions > 0 then
            local matches = CheckProfileConditions(profile)
            DebugPrint("|cff00ff00[ProfileDebug]|r      -> Conditions match:", tostring(matches))
            if matches then
                matchedProfile = profileName
                break
            end
        end
    end
    
    DebugPrint("|cff00ff00[ProfileDebug]|r  Matched profile:", tostring(matchedProfile))
    
    -- If no profile matched, stay on current (or fall back to Default)
    if not matchedProfile then
        -- If current profile has conditions that no longer match, fall back to Default
        local currentProfileData = specData.layoutProfiles[currentProfile]
        if currentProfileData and currentProfileData.talentConditions and #currentProfileData.talentConditions > 0 then
            if not CheckProfileConditions(currentProfileData) then
                DebugPrint("|cff00ff00[ProfileDebug]|r  Current profile conditions no longer match, falling back to Default")
                matchedProfile = "Default"
            end
        end
    end
    
    -- Activate matched profile if different from current
    if matchedProfile and matchedProfile ~= currentProfile then
        DebugPrint("|cff00ff00[ProfileDebug]|r  ACTIVATING profile:", matchedProfile)
        PrintMsg("Talents match profile '" .. matchedProfile .. "', activating...")
        ns.CDMGroups.LoadProfile(matchedProfile)
    else
        DebugPrint("|cff00ff00[ProfileDebug]|r  No profile change needed")
        -- NOTE: We intentionally do NOT auto-save here
        -- The user's saved profile layout should remain untouched
        -- Only explicit saves (button press) or icon drags should update the profile
    end
    
    DebugPrint("|cff00ff00[ProfileDebug]|r CheckAndActivateMatchingProfile done")
end
--]] -- END OF DISABLED CheckAndActivateMatchingProfile

-- ═══════════════════════════════════════════════════════════════════════════
-- VerifyDirectReference - DIAGNOSTIC FUNCTION
-- ═══════════════════════════════════════════════════════════════════════════
-- Checks if ns.CDMGroups.savedPositions is the same table as profile.savedPositions
-- If not, attempts to repair the reference.
-- Returns: isValid (boolean), errorMessage (string or nil)
-- ═══════════════════════════════════════════════════════════════════════════
local function VerifyDirectReference(autoRepair)
    local specData = GetSpecData and GetSpecData()
    if not specData then
        return false, "specData not available"
    end
    
    if not specData.layoutProfiles then
        return false, "layoutProfiles not available"
    end
    
    local activeProfileName = specData.activeProfile or "Default"
    local profile = specData.layoutProfiles[activeProfileName]
    
    if not profile then
        if autoRepair then
            -- Create the profile
            specData.layoutProfiles[activeProfileName] = {
                savedPositions = {},
                freeIcons = {},
                groupLayouts = {},
                iconSettings = {},
            }
            profile = specData.layoutProfiles[activeProfileName]
            DebugPrint("|cffff6666[VerifyDirectReference]|r Created missing profile:", activeProfileName)
        else
            return false, "Profile '" .. activeProfileName .. "' not found"
        end
    end
    
    if not profile.savedPositions then
        profile.savedPositions = {}
    end
    
    -- Check if savedPositions IS the profile table (same reference)
    if ns.CDMGroups.savedPositions ~= profile.savedPositions then
        if autoRepair then
            -- Repair: Copy any data from runtime table to profile, then establish direct reference
            local runtimeCount = 0
            local profileCount = 0
            
            for _ in pairs(ns.CDMGroups.savedPositions or {}) do runtimeCount = runtimeCount + 1 end
            for _ in pairs(profile.savedPositions) do profileCount = profileCount + 1 end
            
            DebugPrint("|cffff6666[VerifyDirectReference]|r MISMATCH DETECTED!")
            DebugPrint("  Runtime savedPositions:", runtimeCount, "entries")
            DebugPrint("  Profile savedPositions:", profileCount, "entries")
            
            -- If runtime has more data, copy to profile first
            if runtimeCount > profileCount then
                DebugPrint("  Copying runtime data to profile before establishing reference...")
                for cdID, data in pairs(ns.CDMGroups.savedPositions) do
                    if not profile.savedPositions[cdID] then
                        profile.savedPositions[cdID] = DeepCopy(data)
                    end
                end
            end
            
            -- Establish direct reference
            ns.CDMGroups.savedPositions = profile.savedPositions
            if ns.CDMGroups.specSavedPositions and ns.CDMGroups.currentSpec then
                ns.CDMGroups.specSavedPositions[ns.CDMGroups.currentSpec] = profile.savedPositions
            end
            
            DebugPrint("|cff00ff00[VerifyDirectReference]|r REPAIRED - direct reference established")
            return true, "Repaired (was mismatched)"
        else
            return false, "savedPositions is NOT the profile table (reference mismatch)"
        end
    end
    
    return true, nil
end
ns.CDMGroups.VerifyDirectReference = VerifyDirectReference

-- ═══════════════════════════════════════════════════════════════════════════
-- END LAYOUT PROFILE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- SavePositionToSpec - Save to Arc Manager Profile ONLY
-- ═══════════════════════════════════════════════════════════════════════════
-- The Arc Manager profile (layoutProfiles[activeProfile]) is the SINGLE SOURCE
-- OF TRUTH for saved positions. We no longer write to specData.savedPositions
-- (legacy storage) - it's kept only for migration from old versions.
--
-- ns.CDMGroups.savedPositions IS the profile.savedPositions table (direct ref)
-- so writing to one writes to both automatically.
-- ═══════════════════════════════════════════════════════════════════════════
SavePositionToSpec = function(cdID, positionData, forceSave)
    -- CRITICAL: Don't save positions during restoration/spec change
    -- UNLESS forceSave is true (for new icons being auto-assigned)
    if not forceSave and IsRestoring() then
        return
    end
    
    -- Don't save during profile load cooldown OR before profile is loaded
    local blockSave = ns.CDMGroups._profileSaveBlockedUntil and GetTime() < ns.CDMGroups._profileSaveBlockedUntil
    if blockSave or ns.CDMGroups._profileNotLoaded then
        return
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL FIX: Always verify we're writing to the profile table
    -- GetProfileSavedPositions ensures ns.CDMGroups.savedPositions IS profile.savedPositions
    -- ═══════════════════════════════════════════════════════════════════════════
    local profileSavedPositions = GetProfileSavedPositions()
    if profileSavedPositions then
        profileSavedPositions[cdID] = positionData
    end
end

-- Save a member's group position and persist to spec data
-- forceSave: if true, save even during restoration (for new icons without saved positions)
local function SaveGroupPosition(cdID, groupName, row, col, forceSave, sortIndex)
    -- CRITICAL: Don't save positions during restoration/spec change/reflow/reconcile
    -- UNLESS forceSave is true (for new icons being auto-assigned or user drag actions)
    if not forceSave then
        if IsRestoring() then
            return
        end
        -- Block saves during reflow/reconcile operations
        if ns.CDMGroups._blockPositionSaves then
            return
        end
        -- Block saves during spec/talent changes
        if ns.CDMGroups.specChangeInProgress or ns.CDMGroups._pendingSpecChange then
            return
        end
        if ns.CDMGroups.talentChangeInProgress then
            return
        end
        -- Block saves during restoration protection window
        if ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd then
            return
        end
        if ns.CDMGroups._talentRestorationEnd and GetTime() < ns.CDMGroups._talentRestorationEnd then
            return
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL FIX: Always get the verified profile.savedPositions table
    -- ═══════════════════════════════════════════════════════════════════════════
    local profileSavedPositions = GetProfileSavedPositions()
    if not profileSavedPositions then return end
    
    -- Calculate sortIndex from row/col if not provided
    -- This ensures backward compatibility and proper ordering
    local group = ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    local cols = (group and group.layout and group.layout.gridCols) or 4
    local computedSortIndex = sortIndex or (row * cols + col)
    
    -- Preserve viewerType if updating existing entry
    local existing = profileSavedPositions[cdID]
    local viewerType = existing and existing.viewerType
    
    -- CRITICAL: Determine isPlaceholder from the CURRENT member state, not existing savedPosition
    -- This fixes the bug where stale isPlaceholder flags were preserved forever
    local isPlaceholder = nil
    if group and group.members and group.members[cdID] then
        local member = group.members[cdID]
        -- Only set isPlaceholder if member IS a placeholder, otherwise explicitly nil
        if member.isPlaceholder then
            isPlaceholder = true
        end
        if member.viewerType then
            viewerType = member.viewerType
        end
    end
    
    local positionData = { 
        type = "group", 
        target = groupName, 
        row = row, 
        col = col,
        sortIndex = computedSortIndex,  -- NEW: Sort order for reflow
        isPlaceholder = isPlaceholder,  -- Only true if member is currently a placeholder
        viewerType = viewerType,  -- Preserve viewer type
    }
    
    -- Write to the verified profile table
    profileSavedPositions[cdID] = positionData
end
ns.CDMGroups.SaveGroupPosition = SaveGroupPosition

-- ═══════════════════════════════════════════════════════════════════════════
-- ClearPositionFromSpec - Clear from Arc Manager Profile ONLY
-- ═══════════════════════════════════════════════════════════════════════════
ClearPositionFromSpec = function(cdID)
    -- Don't modify during profile load cooldown
    local blockSave = ns.CDMGroups._profileSaveBlockedUntil and GetTime() < ns.CDMGroups._profileSaveBlockedUntil
    if blockSave then return end
    
    -- CRITICAL FIX: Use GetProfileSavedPositions to ensure we clear from the correct table
    local profileSavedPositions = GetProfileSavedPositions()
    if profileSavedPositions then
        profileSavedPositions[cdID] = nil
    end
    
    -- NOTE: We intentionally do NOT clear from specData.savedPositions anymore.
    -- That's legacy storage kept only for migration from old addon versions.
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SaveFreeIconToSpec - Save to Arc Manager Profile ONLY
-- ═══════════════════════════════════════════════════════════════════════════
-- Note: Unlike savedPositions, freeIcons runtime table has extra fields (frame,
-- entry, etc.) so we can't use a direct reference. We copy position data only.
-- ═══════════════════════════════════════════════════════════════════════════
SaveFreeIconToSpec = function(cdID, freeIconData, forceSave)
    -- CRITICAL: Don't save during restoration/spec change
    -- UNLESS forceSave is true (for new icons being auto-assigned)
    if not forceSave and IsRestoring() then
        return
    end
    
    -- Don't save during profile load cooldown
    local blockSave = ns.CDMGroups._profileSaveBlockedUntil and GetTime() < ns.CDMGroups._profileSaveBlockedUntil
    if blockSave then return end
    
    -- Don't save before profile is loaded
    if ns.CDMGroups._profileNotLoaded then return end
    
    -- Save to Arc Manager profile
    local specData = GetSpecData()
    if specData then
        EnsureLayoutProfiles(specData)
        local activeProfileName = specData.activeProfile or "Default"
        local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
        if profile then
            if not profile.freeIcons then
                profile.freeIcons = {}
            end
            -- Only save position data (not runtime fields like frame, entry)
            profile.freeIcons[cdID] = {
                x = freeIconData.x,
                y = freeIconData.y,
                iconSize = freeIconData.iconSize,
            }
        end
    end
    
    -- NOTE: We intentionally do NOT write to specData.freeIcons anymore.
    -- That's legacy storage kept only for migration from old addon versions.
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ClearFreeIconFromSpec - Clear from Arc Manager Profile ONLY
-- ═══════════════════════════════════════════════════════════════════════════
ClearFreeIconFromSpec = function(cdID)
    -- Don't modify during profile load cooldown
    local blockSave = ns.CDMGroups._profileSaveBlockedUntil and GetTime() < ns.CDMGroups._profileSaveBlockedUntil
    if blockSave then return end
    
    -- Clear from runtime freeIcons (separate from profile)
    if ns.CDMGroups.freeIcons then
        ns.CDMGroups.freeIcons[cdID] = nil
    end
    
    -- Clear from Arc Manager profile
    local specData = GetSpecData()
    if specData then
        local activeProfileName = specData.activeProfile or "Default"
        if specData.layoutProfiles and specData.layoutProfiles[activeProfileName] then
            local profile = specData.layoutProfiles[activeProfileName]
            if profile.freeIcons then
                profile.freeIcons[cdID] = nil
            end
        end
    end
    
    -- NOTE: We intentionally do NOT clear from specData.freeIcons anymore.
    -- That's legacy storage kept only for migration from old addon versions.
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ARC AURAS RESTORATION - Consolidated function for restoring Arc Auras positions
-- Called during spec change and post-protection to ensure Arc Auras are visible
-- ═══════════════════════════════════════════════════════════════════════════

-- Shared layout constants for orphan positioning
local ARC_AURAS_ORPHAN_SPACING = 50
local ARC_AURAS_ICONS_PER_ROW = 5
local ARC_AURAS_START_Y = 150

-- Restore all Arc Auras to their saved positions or create orphans
-- Returns: number of Arc Auras restored, number created as orphans
function ns.CDMGroups.RestoreArcAurasPositions(debugPrefix)
    debugPrefix = debugPrefix or "[RestoreArcAuras]"
    
    if not ns.ArcAuras or not ns.ArcAuras.frames then
        return 0, 0
    end
    
    local restoredCount = 0
    local orphanCount = 0
    local orphanIndex = 0
    
    for arcID, frame in pairs(ns.ArcAuras.frames) do
        if frame then
            -- CRITICAL: Skip frames that are hidden due to hideWhenUnequipped setting
            -- These frames should NOT be shown or positioned until the item is equipped
            if frame._arcHiddenUnequipped then
                DebugPrint(debugPrefix, "Skipping Arc Aura (hideWhenUnequipped):", arcID)
            else
                -- Check current tracking state
                local isTrackedGroup = false
                for groupName, group in pairs(ns.CDMGroups.groups or {}) do
                    if group.members and group.members[arcID] then
                        isTrackedGroup = true
                        break
                    end
                end
                
                -- For grouped Arc Auras, skip (Layout handles them)
                if isTrackedGroup then
                    DebugPrint(debugPrefix, "Arc Aura already in group:", arcID)
                else
                    -- For FREE Arc Auras: ALWAYS restore position directly on frame
                    local saved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[arcID]
                    local hasValidPosition = frame:GetNumPoints() > 0
                    
                    if saved then
                        if saved.type == "group" and saved.target then
                            -- Restore to group
                            local targetGroup = ns.CDMGroups.groups[saved.target]
                            if targetGroup then
                                DebugPrint(debugPrefix, "Restoring Arc Aura to group:", arcID, "->", saved.target)
                                ns.CDMGroups.RegisterExternalFrame(arcID, frame, "cooldown", saved.target)
                                restoredCount = restoredCount + 1
                            else
                                -- Group doesn't exist - fall back to free position
                                DebugPrint(debugPrefix, "Group", saved.target, "not found, making Arc Aura free:", arcID)
                                local col = orphanIndex % ARC_AURAS_ICONS_PER_ROW
                                local row = math.floor(orphanIndex / ARC_AURAS_ICONS_PER_ROW)
                                local x = (col - math.floor(ARC_AURAS_ICONS_PER_ROW / 2)) * ARC_AURAS_ORPHAN_SPACING
                                local y = ARC_AURAS_START_Y - (row * ARC_AURAS_ORPHAN_SPACING)
                                
                                -- Set position directly
                                frame:SetParent(UIParent)
                                frame:ClearAllPoints()
                                frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
                                frame:SetFrameStrata("MEDIUM")
                                frame:SetAlpha(1)
                                frame:Show()
                                
                                ns.CDMGroups.TrackFreeIcon(arcID, x, y, 36, frame)
                                orphanIndex = orphanIndex + 1
                                orphanCount = orphanCount + 1
                            end
                        elseif saved.type == "free" then
                            -- Restore as free icon at saved position
                            DebugPrint(debugPrefix, "Restoring Arc Aura as free:", arcID, "at", saved.x, saved.y)
                            
                            -- Set position DIRECTLY on frame (critical fix!)
                            frame:SetParent(UIParent)
                            frame:ClearAllPoints()
                            frame:SetPoint("CENTER", UIParent, "CENTER", saved.x or 0, saved.y or 0)
                            frame:SetFrameStrata("MEDIUM")
                            frame:SetAlpha(1)
                            frame:Show()
                            
                            -- Also call TrackFreeIcon to ensure tracking is set up
                            ns.CDMGroups.TrackFreeIcon(arcID, saved.x or 0, saved.y or 0, saved.iconSize or 36, frame)
                            restoredCount = restoredCount + 1
                        end
                    elseif not hasValidPosition then
                        -- NO saved position AND no valid position - create as orphan
                        local col = orphanIndex % ARC_AURAS_ICONS_PER_ROW
                        local row = math.floor(orphanIndex / ARC_AURAS_ICONS_PER_ROW)
                        local x = (col - math.floor(ARC_AURAS_ICONS_PER_ROW / 2)) * ARC_AURAS_ORPHAN_SPACING
                        local y = ARC_AURAS_START_Y - (row * ARC_AURAS_ORPHAN_SPACING)
                        
                        DebugPrint(debugPrefix, "Creating orphan Arc Aura:", arcID, "at", x, y)
                        
                        -- Set position directly
                        frame:SetParent(UIParent)
                        frame:ClearAllPoints()
                        frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
                        frame:SetFrameStrata("MEDIUM")
                        frame:SetAlpha(1)
                        frame:Show()
                        
                        ns.CDMGroups.TrackFreeIcon(arcID, x, y, 36, frame)
                        orphanIndex = orphanIndex + 1
                        orphanCount = orphanCount + 1
                    else
                        DebugPrint(debugPrefix, "Arc Aura has valid position, skipping:", arcID)
                    end
                end
            end
        end
    end
    
    return restoredCount, orphanCount
end

-- Force show all Arc Auras (used after restoration to ensure visibility)
-- NOTE: Respects _arcHiddenUnequipped flag - frames hidden due to hideWhenUnequipped setting remain hidden
function ns.CDMGroups.ForceShowAllArcAuras()
    if not ns.ArcAuras or not ns.ArcAuras.frames then return 0 end
    
    local count = 0
    for arcID, frame in pairs(ns.ArcAuras.frames) do
        if frame then
            -- Skip frames that are hidden due to hideWhenUnequipped setting
            if not frame._arcHiddenUnequipped and not IsFrameHiddenByBar(frame) then
                frame:SetAlpha(1)
                frame:Show()
                count = count + 1
            end
        end
    end
    return count
end

-- Handle spec change - show/hide groups per spec
-- skipSave: if true, skip saving old spec (already done in PLAYER_SPECIALIZATION_CHANGED)
local function OnSpecChange(newSpec, oldSpecOverride, skipSave)
    -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
    if not _cdmGroupsEnabled then return end
    
    DebugPrint("|cffff00ff[OnSpecChange]|r Starting - newSpec:", newSpec, "oldSpec:", oldSpecOverride, "skipSave:", tostring(skipSave))
    
    if not ns.db or not ns.db.profile then return end
    
    local oldSpec = oldSpecOverride or ns.CDMGroups.currentSpec
    
    -- Skip if same spec
    if oldSpec == newSpec then 
        ns.CDMGroups.specChangeInProgress = false
        return 
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL: IMMEDIATELY hide ALL free icon frames BEFORE CDM reassigns them!
    -- CDM reassigns frame.cooldownID immediately on spec change, so by the time
    -- our cleanup code runs, the frame references in specFreeIcons are stale.
    -- We must hide frames NOW while they still have _cdmgIsFreeIcon marker.
    -- ═══════════════════════════════════════════════════════════════════════════
    for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
        if data.frame then
            pcall(function()
                -- Hide frame and all overlays
                data.frame:Hide()
                if data.frame._arcBorderEdges then
                    if data.frame._arcBorderEdges.top then data.frame._arcBorderEdges.top:Hide() end
                    if data.frame._arcBorderEdges.bottom then data.frame._arcBorderEdges.bottom:Hide() end
                    if data.frame._arcBorderEdges.left then data.frame._arcBorderEdges.left:Hide() end
                    if data.frame._arcBorderEdges.right then data.frame._arcBorderEdges.right:Hide() end
                end
                if data.frame._arcTextOverlay then data.frame._arcTextOverlay:Hide() end
                if data.frame._arcOverlay then data.frame._arcOverlay:Hide() end
                if data.frame._arcIconOverlay then data.frame._arcIconOverlay:Hide() end
                -- Clear flags so hooks stop fighting
                data.frame._cdmgIsFreeIcon = nil
                data.frame._cdmgFreeTargetSize = nil
            end)
        end
    end
    
    -- Track when spec change started (for Layout behavior)
    ns.CDMGroups.lastSpecChangeTime = GetTime()
    
    PrintMsg("Switching from spec " .. oldSpec .. " to " .. newSpec)
    
    -- Step 0: SAVE old spec's runtime state TO PROFILE (single source of truth)
    if not skipSave and ns.CDMGroups.specGroups[oldSpec] and next(ns.CDMGroups.specGroups[oldSpec]) then
        local specData = EnsureSpecData(oldSpec)
        if specData then
            -- Save group LAYOUTS to profile.groupLayouts (NOT to specData.groups)
            EnsureLayoutProfiles(specData)
            local activeProfileName = specData.activeProfile or "Default"
            local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
            
            if profile then
                if not profile.groupLayouts then
                    profile.groupLayouts = {}
                end
                
                -- Save each group's layout settings (NO runtime data like grid/members)
                for groupName, group in pairs(ns.CDMGroups.specGroups[oldSpec]) do
                    profile.groupLayouts[groupName] = SerializeGroupToLayoutData(group)
                end
                
                -- Save free icons to profile
                if not profile.freeIcons then
                    profile.freeIcons = {}
                end
                for cdID, data in pairs(ns.CDMGroups.specFreeIcons[oldSpec] or {}) do
                    profile.freeIcons[cdID] = { x = data.x, y = data.y, iconSize = data.iconSize }
                end
            end
            
            -- NOTE: savedPositions IS the profile.savedPositions table (direct reference)
            -- It's already correct from SavePositionToSpec() calls - no rebuild needed
            
            PrintMsg("Saved spec " .. oldSpec .. " layout to profile")
        end
    end
    
    -- Step 1: Cancel any active drags before spec change
    -- Frames may be destroyed during spec change, so we need to clean up drag state
    for groupName, group in pairs(ns.CDMGroups.specGroups[oldSpec] or {}) do
        for cdID, member in pairs(group.members or {}) do
            if member.frame then
                if member.frame._groupDragging then
                    pcall(function() member.frame:StopMovingOrSizing() end)
                    member.frame._groupDragging = false
                    member.frame._sourceGroup = nil
                    member.frame._sourceCdID = nil
                end
            end
        end
    end
    for cdID, data in pairs(ns.CDMGroups.specFreeIcons[oldSpec] or {}) do
        if data.frame and data.frame._freeDragging then
            pcall(function() data.frame:StopMovingOrSizing() end)
            data.frame._freeDragging = false
            data.frame._sourceCdID = nil
        end
    end
    ns.CDMGroups.HideDropIndicator()
    
    -- Step 2: RETURN all frames to their original CDM viewer parents
    -- CRITICAL: Hide borders and frames - CDM will show them when ready
    if ns.CDMGroups.specGroups[oldSpec] then
        for groupName, group in pairs(ns.CDMGroups.specGroups[oldSpec]) do
            -- Return each frame to its original parent
            for cdID, member in pairs(group.members) do
                if member.frame then
                    -- CRITICAL: Hide borders FIRST before any other operations
                    pcall(function()
                        if member.frame._arcBorderEdges then
                            if member.frame._arcBorderEdges.top then member.frame._arcBorderEdges.top:Hide() end
                            if member.frame._arcBorderEdges.bottom then member.frame._arcBorderEdges.bottom:Hide() end
                            if member.frame._arcBorderEdges.left then member.frame._arcBorderEdges.left:Hide() end
                            if member.frame._arcBorderEdges.right then member.frame._arcBorderEdges.right:Hide() end
                        end
                        if member.frame._arcTextOverlay then member.frame._arcTextOverlay:Hide() end
                        if ns.CDMEnhance and ns.CDMEnhance.StopAllGlows then
                            ns.CDMEnhance.StopAllGlows(member.frame)
                        end
                    end)
                    
                    pcall(function()
                        local originalParent = member.entry and member.entry.originalParent
                        if originalParent then
                            member.frame:SetParent(originalParent)
                        else
                            -- Fallback: find the appropriate CDM viewer
                            local viewerType = member.viewerType or "aura"
                            local viewerName = "BuffIconCooldownViewer"
                            if viewerType == "cooldown" then
                                viewerName = "EssentialCooldownViewer"
                            elseif viewerType == "utility" then
                                viewerName = "UtilityCooldownViewer"
                            end
                            local viewer = _G[viewerName]
                            if viewer then
                                member.frame:SetParent(viewer)
                            end
                        end
                        member.frame:ClearAllPoints()
                        -- CRITICAL: HIDE the frame - CDM will show when ready
                        member.frame:Hide()
                    end)
                end
                if member.entry then
                    member.entry.manipulated = false
                    member.entry.group = nil
                end
            end
            -- Clear the group's member tracking (we're switching specs)
            group.members = {}
            group.grid = {}
            -- Hide the group container (OUR frame, not CDM's)
            if group.container then group.container:Hide() end
            if group.dragBar then group.dragBar:Hide() end
            if group.HideControlButtons then group.HideControlButtons() end
        end
    end
    
    -- Return free icons to their original CDM parents
    if ns.CDMGroups.specFreeIcons[oldSpec] then
        for cdID, data in pairs(ns.CDMGroups.specFreeIcons[oldSpec]) do
            if data.frame then
                -- CRITICAL: Hide borders FIRST
                pcall(function()
                    if data.frame._arcBorderEdges then
                        if data.frame._arcBorderEdges.top then data.frame._arcBorderEdges.top:Hide() end
                        if data.frame._arcBorderEdges.bottom then data.frame._arcBorderEdges.bottom:Hide() end
                        if data.frame._arcBorderEdges.left then data.frame._arcBorderEdges.left:Hide() end
                        if data.frame._arcBorderEdges.right then data.frame._arcBorderEdges.right:Hide() end
                    end
                    if data.frame._arcTextOverlay then data.frame._arcTextOverlay:Hide() end
                    if ns.CDMEnhance and ns.CDMEnhance.StopAllGlows then
                        ns.CDMEnhance.StopAllGlows(data.frame)
                    end
                end)
                
                pcall(function()
                    -- CRITICAL: Clear free icon flags BEFORE SetParent!
                    -- Otherwise the hook sees _cdmgIsFreeIcon=true and fights back!
                    data.frame._cdmgIsFreeIcon = nil
                    data.frame._cdmgFreeTargetSize = nil
                    
                    -- Find the original parent - try multiple sources
                    local originalParent = data.originalParent  -- Stored directly on data!
                        or (data.entry and data.entry.originalParent)
                    
                    -- Fallback: Find CDM viewer by type
                    if not originalParent then
                        local viewerType = data.viewerType or "aura"
                        local viewerName = data.originalViewerName or "BuffIconCooldownViewer"
                        if viewerType == "cooldown" then
                            viewerName = "EssentialCooldownViewer"
                        elseif viewerType == "utility" then
                            viewerName = "UtilityCooldownViewer"
                        end
                        originalParent = _G[viewerName]
                    end
                    
                    -- ALWAYS reparent (even if we have to use fallback)
                    if originalParent then
                        data.frame:SetParent(originalParent)
                    end
                    data.frame:ClearAllPoints()
                    -- CRITICAL: HIDE the frame
                    data.frame:Hide()
                end)
            end
            if data.entry then
                data.entry.manipulated = false
                data.entry.manipulationType = nil
            end
        end
        -- Clear free icons for old spec
        ns.CDMGroups.specFreeIcons[oldSpec] = {}
    end
    
    -- Clear registry of all manipulated entries since we're releasing everything
    for addr, entry in pairs(Registry.byAddress) do
        if entry.manipulated then
            entry.manipulated = false
            entry.group = nil
        end
    end
    
    -- Step 2: Update current spec
    ns.CDMGroups.currentSpec = newSpec
    local db = GetCDMGroupsDB()
    if db then db.lastActiveSpec = newSpec end
    
    -- Step 3: Initialize new spec storage and ALWAYS reload from DB
    if not ns.CDMGroups.specGroups[newSpec] then
        ns.CDMGroups.specGroups[newSpec] = {}
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- LOAD savedPositions FROM ARC MANAGER PROFILE (DIRECT REFERENCE)
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL FIX: Use GetProfileSavedPositions to ensure we ALWAYS get the
    -- correct profile.savedPositions table. This handles all edge cases:
    -- - Creates profile if missing
    -- - Migrates legacy data if needed
    -- - Sets up the direct reference
    -- ═══════════════════════════════════════════════════════════════════════════
    local specData = GetSpecData(newSpec)
    local posCount = 0
    
    -- GetProfileSavedPositions handles EVERYTHING: profile creation, migration, reference setup
    local profileSavedPositions = GetProfileSavedPositions(newSpec)
    if profileSavedPositions then
        for _ in pairs(profileSavedPositions) do
            posCount = posCount + 1
        end
    end
    
    -- Get the active profile for other operations
    local activeProfileName = specData.activeProfile or "Default"
    ns.CDMGroups.activeProfile = activeProfileName
    local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
    
    DebugPrint("|cffff00ff[OnSpecChange]|r Loaded", posCount, "savedPositions from Arc Manager profile for spec", newSpec)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- LOAD freeIcons FROM ARC MANAGER PROFILE (COPY - has runtime fields)
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Unlike savedPositions, freeIcons runtime table has extra fields (frame, entry)
    -- so we copy position data only, not the whole table.
    -- ═══════════════════════════════════════════════════════════════════════════
    ns.CDMGroups.specFreeIcons[newSpec] = {}
    local freeCount = 0
    
    if profile then
        if not profile.freeIcons then
            profile.freeIcons = {}
        end
        
        -- ONE-TIME MIGRATION: If legacy specData.freeIcons has data but profile is empty,
        -- migrate the legacy data into the profile
        if not next(profile.freeIcons) and specData.freeIcons and next(specData.freeIcons) then
            DebugPrint("|cffff00ff[OnSpecChange]|r Migrating legacy freeIcons to Arc Manager profile")
            for cdID, data in pairs(specData.freeIcons) do
                profile.freeIcons[cdID] = {
                    x = data.x,
                    y = data.y,
                    iconSize = data.iconSize,
                }
            end
        end
        
        -- Copy position data into runtime table (runtime adds frame, entry, etc.)
        for cdID, data in pairs(profile.freeIcons) do
            ns.CDMGroups.specFreeIcons[newSpec][cdID] = DeepCopy(data)
            freeCount = freeCount + 1
        end
    end
    DebugPrint("|cffff00ff[OnSpecChange]|r Loaded", freeCount, "freeIcons from Arc Manager profile for spec", newSpec)
    
    -- Step 4: Update shortcuts to point to new spec
    ns.CDMGroups.groups = ns.CDMGroups.specGroups[newSpec]
    -- NOTE: savedPositions was already set by GetProfileSavedPositions above
    ns.CDMGroups.freeIcons = ns.CDMGroups.specFreeIcons[newSpec]
    
    -- Step 5: DESTROY existing groups and RECREATE fresh from DB
    -- CRITICAL: Hide ALL existing containers first to prevent orphaned borders
    -- This catches containers from previous visits to this spec
    for groupName, group in pairs(ns.CDMGroups.specGroups[newSpec] or {}) do
        if group.container then
            group.container:Hide()
            -- Also explicitly clear backdrop to prevent flash of old settings
            group.container:SetBackdropBorderColor(0, 0, 0, 0)
            group.container:SetBackdropColor(0, 0, 0, 0)
        end
        if group.dragBar then group.dragBar:Hide() end
    end
    -- Also hide current groups (in case specGroups reference is different)
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        if group.container then
            group.container:Hide()
            group.container:SetBackdropBorderColor(0, 0, 0, 0)
            group.container:SetBackdropColor(0, 0, 0, 0)
        end
        if group.dragBar then group.dragBar:Hide() end
    end
    ns.CDMGroups.specGroups[newSpec] = {}
    ns.CDMGroups.groups = ns.CDMGroups.specGroups[newSpec]
    
    -- Create fresh groups from DB
    local specData = EnsureSpecData(newSpec, oldSpec)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- LINKED TEMPLATE SYNC: If this spec has a linked template, sync GROUP STRUCTURE
    -- This syncs positions, sizes, colors, grid settings - but NOT icon assignments
    -- Icon assignments (savedPositions) are per-spec and should NOT be cleared
    -- PHASE 1: Write to profile.groupLayouts (NOT specData.groups)
    -- ═══════════════════════════════════════════════════════════════════════════
    if specData.linkedTemplateName then
        local Shared = ns.CDMShared
        local templatesDB = Shared and Shared.GetGroupTemplatesDB and Shared.GetGroupTemplatesDB()
        local template = templatesDB and templatesDB[specData.linkedTemplateName]
        
        if template and template.groups and next(template.groups) then
            DebugPrint("|cff00ccff[OnSpecChange]|r Syncing GROUP STRUCTURE from linked template:", specData.linkedTemplateName)
            
            -- Sync group structure TO PROFILE.groupLayouts (NOT specData.groups)
            EnsureLayoutProfiles(specData)
            local activeProfileName = specData.activeProfile or "Default"
            local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
            
            if profile then
                if not profile.groupLayouts then
                    profile.groupLayouts = {}
                end
                
                for groupName, layoutData in pairs(template.groups) do
                    -- Create/update group layout in profile
                    profile.groupLayouts[groupName] = {
                        -- Position
                        position = layoutData.position and { x = layoutData.position.x, y = layoutData.position.y } or { x = 0, y = 0 },
                        -- Appearance
                        showBorder = layoutData.showBorder,
                        showBackground = layoutData.showBackground,
                        autoReflow = layoutData.autoReflow ~= false,
                        dynamicLayout = layoutData.dynamicLayout,
                        lockGridSize = layoutData.lockGridSize,
                        containerPadding = layoutData.containerPadding,
                        visibility = layoutData.visibility or "always",
                        borderColor = layoutData.borderColor and DeepCopy(layoutData.borderColor) or { r = 0.5, g = 0.5, b = 0.5, a = 1 },
                        bgColor = layoutData.bgColor and DeepCopy(layoutData.bgColor) or { r = 0, g = 0, b = 0, a = 0.6 },
                        -- Grid settings
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
                    }
                end
                
                -- Remove groups that are no longer in template
                for groupName in pairs(profile.groupLayouts) do
                    if not template.groups[groupName] then
                        profile.groupLayouts[groupName] = nil
                    end
                end
            end
            
            -- NOTE: We do NOT clear savedPositions - icon assignments are per-spec
            -- Each spec keeps its own icon-to-group assignments
            
            -- Update loadedTemplateName to reflect we're using the template
            specData.loadedTemplateName = specData.linkedTemplateName
            
            DebugPrint("|cff00ccff[OnSpecChange]|r Synced group structure to profile (preserved icon assignments)")
        else
            -- Template was deleted or is empty - unlink
            PrintMsg("|cffff6666Linked template '" .. specData.linkedTemplateName .. "' not found - unlinking|r")
            specData.linkedTemplateName = nil
            specData.loadedTemplateName = nil
        end
    end
    
    -- Create groups from PROFILE.groupLayouts (single source of truth)
    -- CRITICAL: Check if groupLayouts has actual content, not just exists
    -- An empty {} is truthy but should fall back to DEFAULT_GROUPS
    local profile = GetActiveProfile(specData)
    local hasGroupLayouts = profile and profile.groupLayouts and next(profile.groupLayouts)
    local groupsToCreate = hasGroupLayouts and profile.groupLayouts or DEFAULT_GROUPS
    local brokenGroups = {}
    for groupName, _ in pairs(groupsToCreate) do
        local group = ns.CDMGroups.CreateGroup(groupName)
        if not group then
            table.insert(brokenGroups, groupName)
        end
    end
    
    -- NOTE: Don't delete broken groups from specData - the data should persist!
    -- CreateGroup can fail for valid reasons (CDM not ready, combat lockdown, etc)
    -- Deleting the data causes corruption when CDM styling is toggled on/off
    if #brokenGroups > 0 then
        DebugPrint("|cffffaa00[OnSpecChange]|r " .. #brokenGroups .. " group(s) couldn't be created (data preserved)")
    end
    
    -- Step 6: Groups are now fresh from DB, just show containers
    -- DON'T call Layout() here - specChangeInProgress is still true and groups are empty anyway
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.container then group.container:Show() end
        if group.UpdateAppearance then group.UpdateAppearance() end
        if group.UpdateDragBarPosition then group.UpdateDragBarPosition() end
        if ns.CDMGroups.dragModeEnabled then
            if group.dragBar then group.dragBar:Show() end
            -- Only show control buttons for selected group
            if groupName == ns.CDMGroups.selectedGroup then
                if group.ShowControlButtons then group.ShowControlButtons() end
            end
        end
        -- Skip Layout() - specChangeInProgress blocks it and groups are empty anyway
    end
    
    -- Step 7: Scan and restore icons after a delay
    -- KEY INSIGHT: Don't pre-create members for cooldownIDs that might not exist!
    -- Instead, let AutoAssignNewIcons find frames in CDM and use savedPositions as a lookup.
    -- Use 0.8s delay to ensure CDM has finished creating frames
    DebugPrint("|cffff00ff[OnSpecChange]|r Waiting 0.8s for CDM frames...")
    C_Timer.After(0.8, function()
        DebugPrint("|cffff00ff[OnSpecChange]|r Timer fired - restoring icons")
        
        -- Block grid expansion during spec switch restoration
        ns.CDMGroups.blockGridExpansion = true
        
        -- Force show all CDM icons before scanning
        if ns.CDMEnhance and ns.CDMEnhance.ForceShowAllCDMIcons then
            ns.CDMEnhance.ForceShowAllCDMIcons()
        end
        
        -- Scan CDM viewers to register all frames
        ns.CDMGroups.ScanAllViewers()
        
        -- Now let AutoAssign do the work - it will:
        -- 1. Find all frames in CDM
        -- 2. Check if their cooldownID has a savedPosition
        -- 3. If yes -> restore to saved position
        -- 4. If no -> auto-assign to default group
        ns.CDMGroups.AutoAssignNewIcons()
        
        -- Restore free icons (these use savedPositions too)
        local specData = GetSpecData(newSpec)
        if specData and specData.freeIcons then
            for cdID, data in pairs(specData.freeIcons) do
                -- CRITICAL FIX: Check if icon is already in a group - groups take priority over free icons
                local alreadyInGroup = false
                for _, group in pairs(ns.CDMGroups.groups) do
                    if group.members and group.members[cdID] then
                        alreadyInGroup = true
                        break
                    end
                end
                
                if not alreadyInGroup and data.x and data.y and not ns.CDMGroups.freeIcons[cdID] then
                    -- Only restore if a frame exists for this cooldownID
                    local frame = Registry:GetValidFrameForCooldownID(cdID)
                    if frame then
                        ns.CDMGroups.TrackFreeIcon(cdID, data.x, data.y, data.iconSize)
                    end
                end
            end
        end
        
        -- Re-enable grid expansion after spec switch is complete
        ns.CDMGroups.blockGridExpansion = false
        
        -- Set restoration protection window (1.5s) - prevents ValidateGrid/member removal
        -- This gives CDM time to finish frame creation and prevents premature cleanup
        ns.CDMGroups._restorationProtectionEnd = GetTime() + 1.5
        
        -- CRITICAL: Clear spec change flag BEFORE final layouts
        -- Otherwise Layout() guard will block positioning
        ns.CDMGroups.specChangeInProgress = false
        
        -- NOW layout all groups (flag is cleared, layouts will run)
        -- ValidateGrid will be skipped due to restoration protection window
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.Layout then group:Layout() end
        end
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- RESTORE ALL ARC AURAS FROM SAVED POSITIONS
        -- Arc Auras are external frames not scanned by ScanAllViewers/AutoAssign.
        -- We must explicitly restore them using their saved positions.
        -- ═══════════════════════════════════════════════════════════════════════════
        local arcRestored, arcOrphans = ns.CDMGroups.RestoreArcAurasPositions("|cffff00ff[OnSpecChange]|r")
        if arcRestored > 0 or arcOrphans > 0 then
            DebugPrint("|cffff00ff[OnSpecChange]|r Arc Auras: restored", arcRestored, "orphans", arcOrphans)
        end
        
        -- Force show all Arc Auras after restoration
        ns.CDMGroups.ForceShowAllArcAuras()
        
        -- Force show after restoration
        if ns.CDMEnhance and ns.CDMEnhance.ForceShowAllCDMIcons then
            ns.CDMEnhance.ForceShowAllCDMIcons()
        end
        
        -- Helper function to count restored icons
        local function CountRestoredIcons()
            local count = 0
            for _, group in pairs(ns.CDMGroups.groups) do
                for _ in pairs(group.members or {}) do
                    count = count + 1
                end
            end
            for _ in pairs(ns.CDMGroups.freeIcons) do
                count = count + 1
            end
            return count
        end
        
        DebugPrint("|cffff00ff[OnSpecChange]|r Complete - restored", CountRestoredIcons(), "icons")
        
        -- Update visibility based on combat state and group settings
        ns.CDMGroups.UpdateGroupVisibility()
        
        -- Ensure container click-through state is correct after spec change
        ns.CDMGroups.UpdateGroupSelectionVisuals()
        
        -- Helper function for retry scan
        local function RetryRestoration(attempt)
            ns.CDMGroups.ScanAllViewers()
            ns.CDMGroups.AutoAssignNewIcons()
            for _, group in pairs(ns.CDMGroups.groups) do
                if group.Layout then group:Layout() end
            end
            local count = CountRestoredIcons()
            PrintMsg("Retry " .. attempt .. ": " .. count .. " icons restored")
            
            -- Refresh Masque after retry layouts
            if ns.Masque and ns.Masque.QueueRefresh then
                ns.Masque.QueueRefresh()
            end
            
            return count
        end
        
        -- Count and retry if needed (CDM creates frames gradually)
        local restoredCount = CountRestoredIcons()
        PrintMsg("Initial restoration: " .. restoredCount .. " icons")
        
        -- Multiple retry attempts with increasing delays
        if restoredCount < 8 then
            PrintMsg("Few icons restored, starting retry sequence...")
            C_Timer.After(0.5, function()
                local count = RetryRestoration(1)
                if count < 8 then
                    C_Timer.After(0.5, function()
                        local count2 = RetryRestoration(2)
                        if count2 < 8 then
                            C_Timer.After(1.0, function()
                                RetryRestoration(3)
                            end)
                        end
                    end)
                end
            end)
        end
        
        -- CRITICAL: Schedule a final layout AFTER the restoration protection window ends
        -- This ensures icons are properly positioned once CDM has finished reassigning frames
        -- The protection window is 1.5s, so schedule at 1.7s to be safe
        C_Timer.After(1.7, function()
            DebugPrint("|cffff00ff[OnSpecChange]|r Post-protection layout starting")
            -- Clear protection flag (should already be expired but be explicit)
            ns.CDMGroups._restorationProtectionEnd = nil
            
            -- Final scan and assignment
            ns.CDMGroups.ScanAllViewers()
            ns.CDMGroups.AutoAssignNewIcons()
            
            -- Re-restore any Arc Auras that need it (safety net)
            local arcRestored, arcOrphans = ns.CDMGroups.RestoreArcAurasPositions("|cffff00ff[OnSpecChange Post-Protection]|r")
            if arcRestored > 0 or arcOrphans > 0 then
                DebugPrint("|cffff00ff[OnSpecChange]|r Post-protection Arc Auras: restored", arcRestored, "orphans", arcOrphans)
            end
            
            -- Layout all groups to position icons
            -- NOTE: Do NOT call ReflowIcons here - IsRestoring() is still true
            -- Reflow will happen naturally after the 5-second window
            for _, group in pairs(ns.CDMGroups.groups) do
                if group.Layout then 
                    group:Layout() 
                end
            end
            
            DebugPrint("|cffff00ff[OnSpecChange]|r Post-protection layout complete - ", CountRestoredIcons(), "icons")
        end)
        
        -- ALSO schedule a reflow AFTER the full 2-second restoration window
        -- This compacts any gaps once all frames have stabilized
        C_Timer.After(2.5, function()
            DebugPrint("|cffff00ff[OnSpecChange]|r Post-restoration finalization starting")
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- CRITICAL: Clear ALL protection flags BEFORE any refresh operations
            -- Many functions check these flags and will skip or behave differently!
            -- ═══════════════════════════════════════════════════════════════════════════
            ns.CDMGroups.lastSpecChangeTime = nil
            ns.CDMGroups.specChangeInProgress = false
            ns.CDMGroups._pendingSpecChange = nil
            ns.CDMGroups._restorationProtectionEnd = nil
            ns.CDMGroups.talentChangeInProgress = false
            ns.CDMGroups._talentRestorationEnd = nil
            
            DebugPrint("|cffff00ff[OnSpecChange]|r All protection flags cleared")
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- STEP 1: EnhanceFrame for frames that were NEVER enhanced (no overlays)
            -- These are frames with _arcShowPandemic == nil - they need overlays created
            -- ═══════════════════════════════════════════════════════════════════════════
            local enhancedCount = 0
            
            -- Helper to determine viewerType from frame if not stored
            local function GetViewerTypeForFrame(frame, storedType)
                if storedType then return storedType end
                local parent = frame:GetParent()
                if parent then
                    local parentName = parent:GetName()
                    if parentName then
                        if parentName:find("BuffIcon") or parentName:find("Aura") then
                            return "aura"
                        elseif parentName:find("Essential") then
                            return "cooldown"
                        elseif parentName:find("Utility") then
                            return "utility"
                        end
                    end
                end
                return "aura"
            end
            
            -- Check group members for frames needing initial enhancement
            for groupName, group in pairs(ns.CDMGroups.groups or {}) do
                if group.members then
                    for cdID, member in pairs(group.members) do
                        if member.frame and member.frame._arcShowPandemic == nil then
                            if ns.CDMEnhance and ns.CDMEnhance.EnhanceFrame then
                                local vType = GetViewerTypeForFrame(member.frame, member.viewerType)
                                local vName = member.originalViewerName or (vType == "aura" and "BuffIconCooldownViewer" or "EssentialCooldownViewer")
                                ns.CDMEnhance.EnhanceFrame(member.frame, cdID, vType, vName)
                                enhancedCount = enhancedCount + 1
                            end
                        end
                    end
                end
            end
            
            -- Check free icons for frames needing initial enhancement
            for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
                if data.frame and data.frame._arcShowPandemic == nil then
                    if ns.CDMEnhance and ns.CDMEnhance.EnhanceFrame then
                        local vType = GetViewerTypeForFrame(data.frame, data.viewerType)
                        local vName = data.originalViewerName or (vType == "aura" and "BuffIconCooldownViewer" or "EssentialCooldownViewer")
                        ns.CDMEnhance.EnhanceFrame(data.frame, cdID, vType, vName)
                        enhancedCount = enhancedCount + 1
                    end
                end
            end
            
            if enhancedCount > 0 then
                DebugPrint("|cffff00ff[OnSpecChange]|r Created overlays for", enhancedCount, "new frames")
            end
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- STEP 2: Refresh ALL frame settings using RefreshIconType("all")
            -- This applies per-icon settings for the CURRENT spec to ALL frames,
            -- including frames that already had overlays but have STALE settings
            -- from the previous spec.
            -- 
            -- NOTE: RefreshIconType("all") is different from RefreshAllStyles:
            --   - RefreshAllStyles only iterates over enhancedFrames table
            --   - RefreshIconType iterates over CDMGroups.groups, freeIcons, AND enhancedFrames
            -- ═══════════════════════════════════════════════════════════════════════════
            if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
                ns.CDMEnhance.RefreshIconType("all")
                DebugPrint("|cffff00ff[OnSpecChange]|r RefreshIconType('all') complete - all per-icon settings refreshed")
            elseif ns.CDMEnhance and ns.CDMEnhance.RefreshAllIcons then
                -- Fallback if RefreshIconType not available
                ns.CDMEnhance.RefreshAllIcons()
                DebugPrint("|cffff00ff[OnSpecChange]|r RefreshAllIcons fallback complete")
            end
            
            -- Force a CDM scan to catch any frames we might have missed
            if ns.CDMEnhance and ns.CDMEnhance.ScanCDM then
                ns.CDMEnhance.ScanCDM()
                DebugPrint("|cffff00ff[OnSpecChange]|r Forced CDM scan complete")
            end
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- CRITICAL FIX: Apply per-icon SIZE settings from GetEffectiveIconSettings
            -- RefreshIconType only applies visual styles (borders, glow)
            -- RefreshAllGroupLayouts applies size/scale via SetupFrameInContainer
            -- ═══════════════════════════════════════════════════════════════════════════
            if ns.CDMGroups.RefreshAllGroupLayouts then
                ns.CDMGroups.RefreshAllGroupLayouts()
                DebugPrint("|cffff00ff[OnSpecChange]|r RefreshAllGroupLayouts() complete - sizes applied")
            end
            
            -- Now reflow is safe
            for _, group in pairs(ns.CDMGroups.groups) do
                if group.autoReflow and group.ReflowIcons then
                    group:ReflowIcons()
                end
            end
            DebugPrint("|cffff00ff[OnSpecChange]|r Post-restoration reflow complete")
            
            -- Try to resolve any placeholders that now have real frames
            if ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.ResolvePlaceholders then
                local resolved = ns.CDMGroups.Placeholders.ResolvePlaceholders()
                if resolved > 0 then
                    DebugPrint("|cffff00ff[OnSpecChange]|r Resolved", resolved, "placeholders")
                end
            end
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- STEP 3: Refresh Arc Auras settings and sizes before Masque refresh
            -- Per-icon scale settings need to be applied so frame sizes are correct
            -- ═══════════════════════════════════════════════════════════════════════════
            if ns.ArcAuras then
                if ns.ArcAuras.RefreshAllSettings then
                    ns.ArcAuras.RefreshAllSettings()
                    DebugPrint("|cffff00ff[OnSpecChange]|r Arc Auras settings refreshed (RefreshAllSettings)")
                elseif ns.ArcAuras.frames then
                    -- Fallback: per-frame refresh
                    for arcID, frame in pairs(ns.ArcAuras.frames) do
                        if ns.ArcAuras.RefreshFrameSettings then
                            ns.ArcAuras.RefreshFrameSettings(arcID)
                        end
                    end
                    DebugPrint("|cffff00ff[OnSpecChange]|r Arc Auras settings refreshed (per-frame)")
                end
            end
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- STEP 4: Refresh Masque skins for all frames
            -- Arc Auras and other frames need Masque re-registration after spec change
            -- This must happen AFTER all layouts and reflows are complete
            -- ═══════════════════════════════════════════════════════════════════════════
            if ns.Masque and ns.Masque.ReregisterAllFrames then
                DebugPrint("|cffff00ff[OnSpecChange]|r Refreshing Masque skins...")
                ns.Masque.ReregisterAllFrames()
            end
            
            -- Schedule a SECOND Masque refresh after a short delay
            -- This catches any frames whose sizes were set by delayed operations
            C_Timer.After(0.3, function()
                if ns.Masque and ns.Masque.ReregisterAllFrames then
                    ns.Masque.ReregisterAllFrames()
                    DebugPrint("|cffff00ff[OnSpecChange]|r Masque refresh (delayed) complete")
                end
            end)
        end)
    end)
    
    local specName = newSpec
    if GetSpecializationInfo then
        local specIndex = GetSpecialization() or 1  -- Use numeric index for API
        local _, name = GetSpecializationInfo(specIndex)
        if name then specName = name end
    end
    PrintMsg("Now using " .. specName .. " layout")
end

-- Expose functions to namespace for external access
ns.GetSpecData = GetSpecData
ns.GetCurrentSpec = GetCurrentSpec
ns.OnSpecChange = OnSpecChange
ns.DeepCopy = DeepCopy
ns.CDMGroups.GetSpecData = GetSpecData  -- Also expose via CDMGroups for Options file
ns.CDMGroups.GetCurrentSpec = GetCurrentSpec  -- For StateManager
ns.CDMGroups.SavePositionToSpec = SavePositionToSpec  -- For CDMGroups_Maintain
ns.CDMGroups.ClearPositionFromSpec = ClearPositionFromSpec  -- For CDMGroups_Maintain
ns.CDMGroups.SaveFreeIconToSpec = SaveFreeIconToSpec  -- For Arc Auras OnDragStop

-- GROUP CREATION - Sparse Grid System

function ns.CDMGroups.CreateGroup(name)
    -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
    if not _cdmGroupsEnabled then 
        PrintMsg("|cffff0000[CreateGroup]|r SKIPPED '" .. name .. "' - CDMGroups is disabled")
        return nil 
    end
    
    if ns.CDMGroups.groups[name] then
        return ns.CDMGroups.groups[name]
    end
    
    -- Get spec-specific data
    local specData = GetSpecData()
    if not specData then
        -- Fallback - shouldn't happen
        PrintMsg("|cffff8800[CreateGroup]|r No specData, calling EnsureSpecData")
        specData = EnsureSpecData(GetCurrentSpec())
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PHASE 1: Read from profile.groupLayouts (single source of truth)
    -- ═══════════════════════════════════════════════════════════════════════════
    local layoutData = GetGroupLayoutFromProfile(name, specData)
    
    if not layoutData then
        -- No profile data - create from defaults and save to profile
        local defaultTemplate = DEFAULT_GROUPS[name] or DEFAULT_GROUPS.Buffs
        layoutData = {
            position = defaultTemplate.position and DeepCopy(defaultTemplate.position) or { x = 0, y = 100 },
            showBorder = defaultTemplate.showBorder or false,
            showBackground = defaultTemplate.showBackground or false,
            autoReflow = defaultTemplate.autoReflow ~= false,
            dynamicLayout = defaultTemplate.dynamicLayout or false,
            lockGridSize = defaultTemplate.lockGridSize or false,
            containerPadding = defaultTemplate.containerPadding or -4,
            visibility = defaultTemplate.visibility or "always",
            borderColor = defaultTemplate.borderColor and DeepCopy(defaultTemplate.borderColor),
            bgColor = defaultTemplate.bgColor and DeepCopy(defaultTemplate.bgColor),
            gridRows = defaultTemplate.layout and defaultTemplate.layout.gridRows or 2,
            gridCols = defaultTemplate.layout and defaultTemplate.layout.gridCols or 4,
            iconSize = defaultTemplate.layout and defaultTemplate.layout.iconSize or 36,
            iconWidth = defaultTemplate.layout and defaultTemplate.layout.iconWidth or 36,
            iconHeight = defaultTemplate.layout and defaultTemplate.layout.iconHeight or 36,
            spacing = defaultTemplate.layout and defaultTemplate.layout.spacing or 2,
        }
        
        -- Save new group to profile immediately
        local profile = GetActiveProfile(specData)
        if profile then
            if not profile.groupLayouts then
                profile.groupLayouts = {}
            end
            profile.groupLayouts[name] = DeepCopy(layoutData)
        end
        
        DebugPrint("|cff00ff00[CreateGroup]|r Created new group '" .. name .. "' with defaults (saved to profile)")
    end
    
    -- Build layout table from layoutData
    local db = {
        layout = {
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
            gridRows = layoutData.gridRows or 2,
            gridCols = layoutData.gridCols or 4,
            direction = "HORIZONTAL",
            perRow = layoutData.gridCols or 4,
        },
        position = layoutData.position and DeepCopy(layoutData.position) or { x = 0, y = 100 },
        autoReflow = layoutData.autoReflow ~= false,
        dynamicLayout = layoutData.dynamicLayout or false,
        lockGridSize = layoutData.lockGridSize or false,
        containerPadding = layoutData.containerPadding or -4,
        showBorder = layoutData.showBorder or false,
        showBackground = layoutData.showBackground or false,
        visibility = layoutData.visibility or "always",
        borderColor = layoutData.borderColor,
        bgColor = layoutData.bgColor,
    }
    
    local color = GROUP_COLORS[name] or { r = 0.5, g = 0.5, b = 0.5 }
    
    -- Ensure borderColor and bgColor have defaults
    local borderColor = db.borderColor or { r = color.r, g = color.g, b = color.b, a = 1 }
    local bgColor = db.bgColor or { r = 0, g = 0, b = 0, a = 0.6 }
    
    local group = {
        name = name,
        members = {},
        grid = {},  -- Start empty - will be rebuilt from saved positions with valid frames
        layout = DeepCopy(db.layout),  -- Use copy to avoid shared reference issues
        position = DeepCopy(db.position),  -- Use copy
        autoReflow = db.autoReflow ~= false,
        dynamicLayout = db.dynamicLayout,
        lockGridSize = db.lockGridSize,
        containerPadding = db.containerPadding,
        visibility = db.visibility,  -- "always", "combat", or "ooc"
        showBorder = db.showBorder,
        showBackground = db.showBackground,
        borderColor = DeepCopy(borderColor),
        bgColor = DeepCopy(bgColor),
        container = nil,
        color = color,
    }
    
    -- Ensure alignment has a default value when dynamicLayout is enabled
    -- The UI shows "Center" as default but if alignment was never saved, it's nil
    -- Having an explicit value ensures consistent behavior in layout calculations
    if group.dynamicLayout and not group.layout.alignment then
        local rows = group.layout.gridRows or 1
        local cols = group.layout.gridCols or 1
        local gridShape = ns.CDMGroups.DetectGridShape and ns.CDMGroups.DetectGridShape(rows, cols) or "horizontal"
        local defaultAlignment = ns.CDMGroups.GetDefaultAlignment and ns.CDMGroups.GetDefaultAlignment(gridShape) or "center"
        group.layout.alignment = defaultAlignment
        DebugPrint("|cff00ff00[CreateGroup]|r Set default alignment for", name, ":", defaultAlignment)
    end
    
    -- Helper to safely get layout from PROFILE (single source of truth)
    -- MUST be defined before any group methods that use it
    local function getDB()
        return GetGroupLayoutFromProfile(group.name)
    end
    -- Store on group object for external access (Layout.lua methods)
    group.getDB = getDB
    
    -- NOTE: We do NOT load grid from db.grid here
    -- The grid will be rebuilt when we restore saved positions via AddMemberAt
    -- This ensures grid only contains entries with valid frames
    
    local container = CreateFrame("Frame", "CDMGroups_" .. name, UIParent, "BackdropTemplate")
    container._isCDMGContainer = true  -- Mark as our container for ClearAllPoints hook
    
    -- Calculate initial container size from layout settings
    local initPadding = (group.containerPadding or 0) * 2
    local initBorderCompensation = 12  -- Must match borderCompensation in Layout() - borderOffset 4 on each side
    local initSlotW, initSlotH = GetSlotDimensions(group.layout)
    local initSpacingX = group.layout.spacingX or group.layout.spacing or 2
    local initSpacingY = group.layout.spacingY or group.layout.spacing or 2
    local initRows = group.layout.gridRows or 2
    local initCols = group.layout.gridCols or 4
    local initW = initCols * initSlotW + (initCols - 1) * initSpacingX + initPadding + initBorderCompensation
    local initH = initRows * initSlotH + (initRows - 1) * initSpacingY + initPadding + initBorderCompensation
    container:SetSize(math.max(initSlotW, initW), math.max(initSlotH, initH))
    container:SetPoint("CENTER", UIParent, "CENTER", group.position.x, group.position.y)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    container:SetBackdropColor(0, 0, 0, 0.6)
    container:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    container:SetFrameStrata("MEDIUM")
    container:SetFrameLevel(1)
    
    -- Add click handler to select group for editing
    -- Container starts with mouse DISABLED - UpdateGroupSelectionVisuals enables when editing
    -- This makes empty slots click-through by default
    container:EnableMouse(false)
    container:SetScript("OnMouseDown", function(self, button)
        -- Check if options panel is open
        local ACD = LibStub("AceConfigDialog-3.0", true)
        local optionsPanelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
        
        if button == "LeftButton" then
            if optionsPanelOpen then
                -- Options panel open - select group and navigate to Icon Groups
                ns.CDMGroups.SelectGroupForOptions(group.name)
            elseif ns.CDMGroups.dragModeEnabled then
                -- Drag mode - just select the group
                ns.CDMGroups.selectedGroup = group.name
                ns.CDMGroups.UpdateGroupSelectionVisuals()
            end
        end
        -- Right-click removed - no longer opens options
    end)
    
    -- Selection highlight frame
    local selectionHighlight = CreateFrame("Frame", nil, container, "BackdropTemplate")
    selectionHighlight:SetAllPoints()
    selectionHighlight:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 3,
    })
    selectionHighlight:SetBackdropBorderColor(1, 1, 0, 0.8)
    selectionHighlight:SetFrameLevel(container:GetFrameLevel() + 10)
    selectionHighlight:EnableMouse(false)  -- Don't block mouse events
    selectionHighlight:Hide()
    group.selectionHighlight = selectionHighlight
    
    -- Use stored border color for title if available
    local titleColor = db.borderColor or color
    
    -- Create title as a separate frame so we can set its strata independently
    local titleFrame = CreateFrame("Frame", nil, container)
    titleFrame:SetHeight(16)
    titleFrame:SetPoint("CENTER", container, "TOP", 0, -3)  -- Overlapping the top border
    titleFrame:SetFrameStrata("HIGH")
    titleFrame:SetFrameLevel(200)
    
    -- Make titleFrame clickable and draggable
    titleFrame:EnableMouse(true)
    titleFrame:SetMovable(true)
    titleFrame:RegisterForDrag("LeftButton")
    titleFrame._groupName = name  -- Store group name for handlers
    titleFrame._titleColor = titleColor  -- Store color for restore
    titleFrame._container = container  -- Store container reference for dragging
    titleFrame._isDragging = false
    
    -- Click to open options (only if not dragging)
    titleFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and not self._isDragging then
            -- Select this group and open options panel
            if ns.CDMGroups.SelectGroupForOptions then
                ns.CDMGroups.SelectGroupForOptions(self._groupName)
            end
        end
        self._isDragging = false
    end)
    
    -- Drag to move the group
    titleFrame:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        self._isDragging = true
        local cont = self._container
        if cont then
            cont:StartMoving()
        end
    end)
    
    titleFrame:SetScript("OnDragStop", function(self)
        local cont = self._container
        if cont then
            cont:StopMovingOrSizing()
            -- Save position
            local x, y = cont:GetCenter()
            if not x or not y then return end  -- Guard: container not yet positioned
            local parentX, parentY = UIParent:GetCenter()
            local offsetX = x - parentX
            local offsetY = y - parentY
            
            -- Update group position
            local grp = ns.CDMGroups.groups[self._groupName]
            if grp and grp.SetPosition then
                grp:SetPosition(offsetX, offsetY)
            end
        end
    end)
    
    titleFrame:SetScript("OnEnter", function(self)
        -- Highlight on hover - yellow
        if self.text then
            self.text:SetTextColor(1, 1, 0.5)
        end
    end)
    
    titleFrame:SetScript("OnLeave", function(self)
        -- Restore original color (unless dragging)
        if self.text and self._titleColor and not self._isDragging then
            self.text:SetTextColor(self._titleColor.r, self._titleColor.g, self._titleColor.b)
        end
    end)
    
    local titleText = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("CENTER", titleFrame, "CENTER", 0, 0)
    titleFrame.text = titleText  -- Store reference for hover effects
    
    -- Add thick outline so title is visible against any background/border
    local font, size, flags = titleText:GetFont()
    titleText:SetFont(font, size, "OUTLINE")
    
    -- Use SetTextColor instead of embedded hex so hover effects work
    titleText:SetText(name)
    titleText:SetTextColor(titleColor.r, titleColor.g, titleColor.b)
    
    -- Auto-size titleFrame to match text width + padding
    local textWidth = titleText:GetStringWidth()
    titleFrame:SetWidth(textWidth + 12)  -- 6px padding on each side
    
    -- Store references
    container.title = titleText
    container.titleFrame = titleFrame
    titleFrame:Hide()  -- Hidden by default, shown in edit mode
    
    -- ═══════════════════════════════════════════════════════════════════
    -- DRAG TOGGLE BUTTON (draggable handle to move the group)
    -- Position is configurable via dragToggleAnchor setting
    -- ═══════════════════════════════════════════════════════════════════
    local dragToggleBtn = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    dragToggleBtn:SetSize(16, 16)
    dragToggleBtn:SetFrameStrata("HIGH")  -- Below options panel
    dragToggleBtn:SetFrameLevel(100)
    dragToggleBtn._container = container
    dragToggleBtn._groupName = name
    
    -- Function to update anchor position
    local function UpdateDragToggleAnchor(anchor)
        dragToggleBtn:ClearAllPoints()
        anchor = anchor or "TOPLEFT"
        
        if anchor == "TOPLEFT" then
            dragToggleBtn:SetPoint("TOPRIGHT", container, "TOPLEFT", -2, 0)
        elseif anchor == "TOPRIGHT" then
            dragToggleBtn:SetPoint("TOPLEFT", container, "TOPRIGHT", 2, 0)
        elseif anchor == "BOTTOMLEFT" then
            dragToggleBtn:SetPoint("BOTTOMRIGHT", container, "BOTTOMLEFT", -2, 0)
        elseif anchor == "BOTTOMRIGHT" then
            dragToggleBtn:SetPoint("BOTTOMLEFT", container, "BOTTOMRIGHT", 2, 0)
        end
    end
    
    -- Set initial position from saved setting
    local savedAnchor = db.dragToggleAnchor or "TOPLEFT"
    UpdateDragToggleAnchor(savedAnchor)
    
    dragToggleBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    
    -- Default state: inactive (gray)
    dragToggleBtn:SetBackdropColor(0.2, 0.2, 0.2, 0.85)
    dragToggleBtn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Icon - use a simple move cursor texture
    local moveIcon = dragToggleBtn:CreateTexture(nil, "OVERLAY")
    moveIcon:SetSize(12, 12)
    moveIcon:SetPoint("CENTER", dragToggleBtn, "CENTER", 0, 0)
    moveIcon:SetTexture("Interface\\CURSOR\\UI-Cursor-Move")
    moveIcon:SetVertexColor(0.8, 0.8, 0.8, 1)
    dragToggleBtn.moveIcon = moveIcon
    
    -- Track state
    dragToggleBtn._active = false
    dragToggleBtn._isDragging = false
    
    -- Update visual state
    local function UpdateDragToggleVisuals()
        if dragToggleBtn._active or dragToggleBtn._isDragging then
            -- Active/dragging: blue tint
            dragToggleBtn:SetBackdropColor(0.15, 0.4, 0.7, 0.95)
            dragToggleBtn:SetBackdropBorderColor(0.3, 0.7, 1.0, 1)
            moveIcon:SetVertexColor(1, 1, 1, 1)
        else
            -- Inactive: gray
            dragToggleBtn:SetBackdropColor(0.2, 0.2, 0.2, 0.85)
            dragToggleBtn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            moveIcon:SetVertexColor(0.8, 0.8, 0.8, 1)
        end
    end
    dragToggleBtn.UpdateVisuals = UpdateDragToggleVisuals
    
    -- Make it draggable to move the group
    dragToggleBtn:RegisterForDrag("LeftButton")
    
    dragToggleBtn:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        self._isDragging = true
        self._wasActive = self._active
        
        -- Hide the EditModeContainers overlay during drag so it doesn't get left behind
        if self._active and ns.EditModeContainers and ns.EditModeContainers.HideSingleWrapperForce then
            ns.EditModeContainers.HideSingleWrapperForce(self._groupName)
        end
        
        UpdateDragToggleVisuals()
        container:StartMoving()
    end)
    
    dragToggleBtn:SetScript("OnDragStop", function(self)
        container:StopMovingOrSizing()
        self._isDragging = false
        UpdateDragToggleVisuals()
        
        -- Save position
        local x, y = container:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        local offsetX = x - parentX
        local offsetY = y - parentY
        
        -- Update group position
        if group.SetPosition then
            group:SetPosition(offsetX, offsetY)
        end
        
        -- Re-show the overlay if it was active before dragging
        if self._wasActive and self._active and ns.EditModeContainers and ns.EditModeContainers.ShowSingleWrapper then
            C_Timer.After(0.05, function()
                ns.EditModeContainers.ShowSingleWrapper(self._groupName)
            end)
        end
    end)
    
    -- Click handler: toggle overlay for this group (only if not dragging)
    dragToggleBtn:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then return end
        if self._isDragging then return end
        if InCombatLockdown() then return end
        
        self._active = not self._active
        UpdateDragToggleVisuals()
        
        -- Toggle the overlay via EditModeContainers
        if ns.EditModeContainers then
            if self._active then
                if ns.EditModeContainers.ShowSingleWrapper then
                    ns.EditModeContainers.ShowSingleWrapper(name)
                end
            else
                if ns.EditModeContainers.HideSingleWrapperForce then
                    ns.EditModeContainers.HideSingleWrapperForce(name)
                end
            end
        end
    end)
    
    -- Hover effects
    dragToggleBtn:SetScript("OnEnter", function(self)
        if self._active or self._isDragging then
            self:SetBackdropColor(0.2, 0.5, 0.8, 1)
        else
            self:SetBackdropColor(0.3, 0.3, 0.3, 0.95)
        end
        self.moveIcon:SetVertexColor(1, 1, 1, 1)
    end)
    
    dragToggleBtn:SetScript("OnLeave", function(self)
        if not self._isDragging then
            UpdateDragToggleVisuals()
        end
    end)
    
    -- Hidden by default, shown when Edit Mode is active
    dragToggleBtn:Hide()
    
    -- Store reference and methods
    group.dragToggleBtn = dragToggleBtn
    container.dragToggleBtn = dragToggleBtn
    group.UpdateDragToggleAnchor = function(self, anchor)
        UpdateDragToggleAnchor(anchor)
    end
    
    -- Drag bar REMOVED - we now use EditModeContainers overlays for group dragging
    -- Keep nil references for backward compatibility with code that checks these
    group.dragBar = nil
    group.dragBarHighlight = nil
    
    -- No-op function for code that calls UpdateDragBarPosition
    local function UpdateDragBarPosition()
        -- No-op - drag bar removed
    end
    group.UpdateDragBarPosition = UpdateDragBarPosition
    
    container:SetMovable(true)
    
    -- BORDER/BACKGROUND VISIBILITY
    if db.showBorder == nil then db.showBorder = false end
    if db.showBackground == nil then db.showBackground = false end
    if db.visibility == nil then db.visibility = "always" end
    if not db.borderColor then db.borderColor = { r = color.r, g = color.g, b = color.b, a = 1 } end
    if not db.bgColor then db.bgColor = { r = 0, g = 0, b = 0, a = 0.6 } end
    
    group.showBorder = db.showBorder
    group.showBackground = db.showBackground
    group.visibility = db.visibility
    group.borderColor = db.borderColor
    group.bgColor = db.bgColor
    
    local function UpdateAppearance()
        if ns.CDMGroups.dragModeEnabled then
            -- Edit mode: showBorderInEditMode is a GLOBAL override
            -- When ON: show all borders/backgrounds so you can see groups while editing
            -- When OFF: hide all borders/backgrounds so you see true layout
            -- Per-group settings are IGNORED in edit mode
            local cdmDb = GetCDMGroupsDB()
            local showInEdit = cdmDb and cdmDb.showBorderInEditMode
            if showInEdit == nil then showInEdit = true end  -- Default to showing
            
            if showInEdit then
                -- Show border/background for ALL groups in edit mode
                container:SetBackdropBorderColor(group.borderColor.r, group.borderColor.g, group.borderColor.b, group.borderColor.a or 1)
                container:SetBackdropColor(group.bgColor.r, group.bgColor.g, group.bgColor.b, group.bgColor.a or 0.6)
            else
                -- Hide border/background for ALL groups in edit mode
                container:SetBackdropBorderColor(0, 0, 0, 0)
                container:SetBackdropColor(0, 0, 0, 0)
            end
        else
            -- Normal mode (not editing): respect per-group toggle settings
            if group.showBorder then
                container:SetBackdropBorderColor(group.borderColor.r, group.borderColor.g, group.borderColor.b, group.borderColor.a or 1)
            else
                container:SetBackdropBorderColor(0, 0, 0, 0)
            end
            if group.showBackground then
                container:SetBackdropColor(group.bgColor.r, group.bgColor.g, group.bgColor.b, group.bgColor.a or 0.6)
            else
                container:SetBackdropColor(0, 0, 0, 0)
            end
        end
    end
    UpdateAppearance()
    group.UpdateAppearance = UpdateAppearance
    
    -- Title frame is already hidden by default (set above)
    
    -- EDIT MODE EDGE ARROWS (Add/Remove Row/Column from edges)
    -- Green arrows point OUTWARD (add), Red arrows point INWARD (remove)
    -- No top arrows - only bottom, left, right edges
    local arrowSize = 14
    local arrowSpacing = 2  -- Space between add/remove arrows
    local edgePadding = 4   -- Distance from container edge
    
    local function CreateArrowButton(isAdd, direction)
        -- Parent to UIParent instead of container for reliable mouse events
        -- (children outside parent bounds can have click issues)
        local btn = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
        btn:SetSize(arrowSize, arrowSize)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        
        -- Green for add (pointing away from container), Red for remove (pointing toward container)
        local bgColor = isAdd and { 0.1, 0.25, 0.1 } or { 0.25, 0.1, 0.1 }
        local borderColor = isAdd and { 0.3, 0.7, 0.3 } or { 0.7, 0.3, 0.3 }
        local textColor = isAdd and "|cff44ff44" or "|cffff4444"
        
        btn:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], 0.9)
        btn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
        btn:SetFrameStrata("LOW")  -- Behind groups (MEDIUM) so arrows don't cover other groups
        btn:SetFrameLevel(100)
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonUp")  -- Only fire on mouse up, not down+up
        
        -- Directional arrows: green points away, red points toward container
        local symbol
        local fontSize = 12
        local fontOffset = 1
        if direction == "bottom" then
            symbol = isAdd and "v" or "^"  -- Add: down (away), Remove: up (toward)
            fontSize = 14  -- Bigger for bottom arrows since ^ is naturally smaller
            fontOffset = 0
        elseif direction == "left" then
            symbol = isAdd and "<" or ">"  -- Add: left (away), Remove: right (toward)
        elseif direction == "right" then
            symbol = isAdd and ">" or "<"  -- Add: right (away), Remove: left (toward)
        end
        
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER", 0, fontOffset)
        label:SetText(textColor .. symbol .. "|r")
        label:SetFont(label:GetFont(), fontSize, "OUTLINE")
        btn.label = label
        btn.isAdd = isAdd
        btn.direction = direction
        btn.bgColor = bgColor
        btn.borderColor = borderColor
        btn.textColor = textColor
        
        -- Tooltip
        local actionNames = {
            bottom = isAdd and "Add row at bottom" or "Remove bottom row",
            left = isAdd and "Add column at left" or "Remove left column",
            right = isAdd and "Add column at right" or "Remove right column"
        }
        
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(self.bgColor[1] + 0.15, self.bgColor[2] + 0.15, self.bgColor[3] + 0.15, 1)
            self:SetBackdropBorderColor(self.borderColor[1] + 0.2, self.borderColor[2] + 0.2, self.borderColor[3] + 0.2, 1)
            
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetText(actionNames[direction], 1, 1, 1)
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(self.bgColor[1], self.bgColor[2], self.bgColor[3], 0.9)
            self:SetBackdropBorderColor(self.borderColor[1], self.borderColor[2], self.borderColor[3], 1)
            GameTooltip:Hide()
        end)
        
        btn:Hide()
        return btn
    end
    
    -- Create arrow pairs for each edge (no top edge)
    -- Bottom edge: add row below, remove bottom row
    local bottomAddArrow = CreateArrowButton(true, "bottom")
    local bottomRemoveArrow = CreateArrowButton(false, "bottom")
    
    -- Left edge: add column left, remove left column  
    local leftAddArrow = CreateArrowButton(true, "left")
    local leftRemoveArrow = CreateArrowButton(false, "left")
    
    -- Right edge: add column right, remove right column
    local rightAddArrow = CreateArrowButton(true, "right")
    local rightRemoveArrow = CreateArrowButton(false, "right")
    
    -- Click handlers
    bottomAddArrow:SetScript("OnClick", function()
        group:AddRowAtBottom()
    end)
    
    bottomRemoveArrow:SetScript("OnClick", function()
        if group.layout.gridRows > 1 then
            group:RemoveRowAt(group.layout.gridRows - 1)
        end
    end)
    
    leftAddArrow:SetScript("OnClick", function()
        group:InsertColumnAt(0)
    end)
    
    leftRemoveArrow:SetScript("OnClick", function()
        if group.layout.gridCols > 1 then
            group:RemoveColumnAt(0)
        end
    end)
    
    rightAddArrow:SetScript("OnClick", function()
        group:AddColumnAtEnd()
    end)
    
    rightRemoveArrow:SetScript("OnClick", function()
        if group.layout.gridCols > 1 then
            group:RemoveColumnAt(group.layout.gridCols - 1)
        end
    end)
    
    local function UpdateEdgeArrowPositions()
        local left, bottom, width, height = container:GetRect()
        if not left or not width then return end
        
        -- Bottom edge: side by side horizontally centered
        -- [-] on left, [+] on right
        bottomRemoveArrow:ClearAllPoints()
        bottomRemoveArrow:SetPoint("TOP", container, "BOTTOM", -(arrowSize/2 + arrowSpacing/2), -edgePadding)
        
        bottomAddArrow:ClearAllPoints()
        bottomAddArrow:SetPoint("TOP", container, "BOTTOM", (arrowSize/2 + arrowSpacing/2), -edgePadding)
        
        -- Left edge: stacked vertically centered
        -- [+] on top (further out), [-] on bottom (closer in)
        leftAddArrow:ClearAllPoints()
        leftAddArrow:SetPoint("RIGHT", container, "LEFT", -edgePadding, (arrowSize/2 + arrowSpacing/2))
        
        leftRemoveArrow:ClearAllPoints()
        leftRemoveArrow:SetPoint("RIGHT", container, "LEFT", -edgePadding, -(arrowSize/2 + arrowSpacing/2))
        
        -- Right edge: stacked vertically centered  
        -- [+] on top (further out), [-] on bottom (closer in)
        rightAddArrow:ClearAllPoints()
        rightAddArrow:SetPoint("LEFT", container, "RIGHT", edgePadding, (arrowSize/2 + arrowSpacing/2))
        
        rightRemoveArrow:ClearAllPoints()
        rightRemoveArrow:SetPoint("LEFT", container, "RIGHT", edgePadding, -(arrowSize/2 + arrowSpacing/2))
    end
    
    local function ShowControlButtons()
        bottomAddArrow:Show()
        bottomRemoveArrow:Show()
        leftAddArrow:Show()
        leftRemoveArrow:Show()
        rightAddArrow:Show()
        rightRemoveArrow:Show()
        UpdateEdgeArrowPositions()
        UpdateAppearance()
    end
    
    local function HideControlButtons()
        bottomAddArrow:Hide()
        bottomRemoveArrow:Hide()
        leftAddArrow:Hide()
        leftRemoveArrow:Hide()
        rightAddArrow:Hide()
        rightRemoveArrow:Hide()
        UpdateAppearance()
    end
    
    group.edgeArrows = { 
        bottomAdd = bottomAddArrow, bottomRemove = bottomRemoveArrow,
        leftAdd = leftAddArrow, leftRemove = leftRemoveArrow,
        rightAdd = rightAddArrow, rightRemove = rightRemoveArrow
    }
    group.UpdateControlButtonPositions = UpdateEdgeArrowPositions
    group.ShowControlButtons = ShowControlButtons
    group.HideControlButtons = HideControlButtons
    
    -- Show control buttons if drag mode is already enabled
    if ns.CDMGroups.dragModeEnabled then
        -- Only show control buttons if this is the selected group
        if group.name == ns.CDMGroups.selectedGroup then
            ShowControlButtons()
        end
    end
    
    group.container = container
    
    -- Helper function to check if a member has a valid frame
    local function hasValidFrame(cdID)
        return HasValidFrame(group.members[cdID], cdID)
    end
    
    -- FIND NEXT FREE SLOT (can expand grid for new members)
    function group:FindNextFreeSlot(allowExpand)
        -- Default to true unless blocked by namespace flag OR group has locked grid size
        if allowExpand == nil then 
            allowExpand = not ns.CDMGroups.blockGridExpansion and not self.lockGridSize
        end
        
        local rows = self.layout.gridRows
        local cols = self.layout.gridCols
        
        -- Get growth direction settings (defaults: RIGHT, DOWN)
        local hGrowth = self.layout.horizontalGrowth or "RIGHT"
        local vGrowth = self.layout.verticalGrowth or "DOWN"
        
        -- Determine iteration order based on growth direction
        local rowStart, rowEnd, rowStep
        local colStart, colEnd, colStep
        
        if vGrowth == "UP" then
            -- Start from bottom, go up
            rowStart, rowEnd, rowStep = rows - 1, 0, -1
        else
            -- DOWN (default): Start from top, go down
            rowStart, rowEnd, rowStep = 0, rows - 1, 1
        end
        
        if hGrowth == "LEFT" then
            -- Start from right, go left
            colStart, colEnd, colStep = cols - 1, 0, -1
        else
            -- RIGHT (default): Start from left, go right
            colStart, colEnd, colStep = 0, cols - 1, 1
        end
        
        -- Iterate in the determined order
        local row = rowStart
        while (rowStep > 0 and row <= rowEnd) or (rowStep < 0 and row >= rowEnd) do
            local col = colStart
            while (colStep > 0 and col <= colEnd) or (colStep < 0 and col >= colEnd) do
                -- Check if slot is truly free (no grid entry OR member has no valid frame)
                local cdID = self.grid[row] and self.grid[row][col]
                if not cdID or not hasValidFrame(cdID) then
                    -- Clear stale grid entry if exists
                    if cdID then
                        self.grid[row][col] = nil
                        -- Also clean up member if it exists but has invalid frame
                        if self.members[cdID] and not hasValidFrame(cdID) then
                            local member = self.members[cdID]
                            SaveGroupPosition(cdID, self.name, row, col)
                            if member.entry then
                                member.entry.manipulated = false
                                member.entry.group = nil
                            end
                            self.members[cdID] = nil
                        end
                    end
                    return row, col
                end
                col = col + colStep
            end
            row = row + rowStep
        end
        
        -- Grid is full
        if allowExpand then
            -- Expand based on growth direction
            if hGrowth == "LEFT" then
                -- Add column on the left side - new icons should go at col -1 (becomes col 0 after shift)
                -- Actually we return the expansion slot, Layout handles the positioning
                return 0, cols  -- Still expand to the right in terms of grid size
            else
                return 0, cols
            end
        else
            -- Don't expand - return nil
            return nil, nil
        end
    end
    
    -- INSERT MEMBER AT POSITION (shifts existing icons right, wraps within grid bounds)
    function group:InsertMemberAt(cooldownID, row, insertCol)
        local maxRows = self.layout.gridRows
        local maxCols = self.layout.gridCols
        
        -- Clamp to grid bounds
        row = Clamp(row, 0, maxRows - 1)
        insertCol = Clamp(insertCol, 0, maxCols - 1)
        
        if self.members[cooldownID] then
            -- Already in group, use move instead
            self:MoveMemberTo(cooldownID, row, insertCol)
            return
        end
        
        if ns.CDMGroups.freeIcons[cooldownID] then
            ns.CDMGroups.ReleaseFreeIcon(cooldownID, true)
        end
        
        local frame, entry = Registry:GetValidFrameForCooldownID(cooldownID)
        
        -- Skip frames that are actual status bars (have Bar element) - these aren't icon-based
        if frame and frame.Bar and frame.Bar.IsObjectType and frame.Bar:IsObjectType("StatusBar") then return end
        
        if not frame then
            SaveGroupPosition(cooldownID, self.name, row, insertCol)
            return
        end
        
        if not entry then
            entry = Registry:GetOrCreate(frame, "ns.CDMGroups." .. self.name)
        end
        
        entry.originalParent = entry.originalParent or frame:GetParent()
        
        -- If target cell is occupied by a VALID member, shift icons
        local existingCdID = self.grid[row] and self.grid[row][insertCol]
        if existingCdID then
            if HasValidFrame(self.members[existingCdID], existingCdID) then
                -- Valid member at position - need to shift
                local canShift = self:ShiftRowRight(row, insertCol)
                if not canShift then
                    -- Shift failed (grid full) - ADD A COLUMN to make room
                    local db = getDB()
                    self.layout.gridCols = self.layout.gridCols + 1
                    if db then db.gridCols = self.layout.gridCols end
                    
                    -- Now shift should work
                    self:ShiftRowRight(row, insertCol)
                end
            else
                -- Stale grid entry - clear it and clean up invalid member if exists
                self.grid[row][insertCol] = nil
                if self.members[existingCdID] then
                    local member = self.members[existingCdID]
                    ReturnFrameToCDM(member.frame, member.entry)
                    SaveGroupPosition(existingCdID, self.name, row, insertCol)
                    self.members[existingCdID] = nil
                end
            end
        end
        
        -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
        -- Otherwise ClearAllPoints hooks will restore wrong centering offset
        frame._cdmgTargetX = nil
        frame._cdmgTargetY = nil
        frame._cdmgTargetPoint = nil
        frame._cdmgTargetRelPoint = nil
        
        local slotW, slotH = GetSlotDimensions(self.layout)
        local effectiveW, effectiveH = SetupFrameInContainer(frame, self.container, slotW, slotH, cooldownID)
        
        self.members[cooldownID] = {
            frame = frame,
            entry = entry,
            row = row,
            col = insertCol,
            targetParent = self.container,
            _effectiveIconW = effectiveW,
            _effectiveIconH = effectiveH,
        }
        
        if not self.grid[row] then self.grid[row] = {} end
        self.grid[row][insertCol] = cooldownID
        
        entry.manipulated = true
        entry.group = self
        
        SaveGroupPosition(cooldownID, self.name, row, insertCol)
        
        self:MarkGridDirty()
        
        -- Always set up member handlers (for click-to-select functionality)
        -- Drag handlers inside check dragModeEnabled
        self:SetupMemberDrag(cooldownID)
        
        self:Layout()  -- Don't call Layout() which triggers validation/reflow
    end
    
    -- SHIFT ROW RIGHT (make room for insertion, respects grid bounds)
    -- Returns true if shift was possible, false if grid full
    function group:ShiftRowRight(row, fromCol)
        if not self.grid[row] then 
            return true 
        end
        
        local maxCols = self.layout.gridCols
        local maxRows = self.layout.gridRows
        
        -- First, clean up any stale grid entries in this row
        local staleCdIDs = {}
        for col, cdID in pairs(self.grid[row]) do
            if not HasValidFrame(self.members[cdID], cdID) then
                table.insert(staleCdIDs, { col = col, cdID = cdID })
            end
        end
        for _, item in ipairs(staleCdIDs) do
            self.grid[row][item.col] = nil
            if self.members[item.cdID] then
                local member = self.members[item.cdID]
                ReturnFrameToCDM(member.frame, member.entry)
                SaveGroupPosition(item.cdID, self.name, row, item.col)
                self.members[item.cdID] = nil
            end
        end
        
        -- Collect all VALID icons in this row at fromCol or higher
        local toShift = {}
        for col, cdID in pairs(self.grid[row]) do
            if col >= fromCol and HasValidFrame(self.members[cdID], cdID) then
                table.insert(toShift, { col = col, cdID = cdID })
            end
        end
        
        if #toShift == 0 then return true end
        
        -- Sort by column descending (shift from right to left to avoid overwrites)
        table.sort(toShift, function(a, b) return a.col > b.col end)
        
        -- Check if rightmost icon needs to wrap to next row
        local rightmost = toShift[1].col
        local needsWrap = (rightmost + 1 >= maxCols)
        
        if needsWrap then
            -- The rightmost icon will wrap to the next row
            local wrapCdID = toShift[1].cdID
            local wrapToRow = row + 1
            local wrapToCol = 0
            
            -- If next row is beyond grid, we can't insert (grid is constrained)
            if wrapToRow >= maxRows then
                -- Grid is full in this direction, return false to signal failure
                return false
            end
            
            -- If the wrap position is occupied by a valid member, recursively shift that row first
            local wrapPosOccupied = self.grid[wrapToRow] and self.grid[wrapToRow][wrapToCol]
            if wrapPosOccupied and HasValidFrame(self.members[wrapPosOccupied], wrapPosOccupied) then
                local canShift = self:ShiftRowRight(wrapToRow, wrapToCol)
                if not canShift then
                    return false
                end
            elseif wrapPosOccupied then
                -- Stale entry at wrap position - clear it
                self.grid[wrapToRow][wrapToCol] = nil
            end
            
            -- Move the rightmost icon to the wrap position
            self.grid[row][rightmost] = nil
            if not self.grid[wrapToRow] then self.grid[wrapToRow] = {} end
            self.grid[wrapToRow][wrapToCol] = wrapCdID
            
            if self.members[wrapCdID] then
                self.members[wrapCdID].row = wrapToRow
                self.members[wrapCdID].col = wrapToCol
                SaveGroupPosition(wrapCdID, self.name, wrapToRow, wrapToCol)
            end
            
            -- Remove the wrapped icon from the shift list
            table.remove(toShift, 1)
        end
        
        -- Shift remaining icons one column to the right
        for _, item in ipairs(toShift) do
            local cdID = item.cdID
            local oldCol = item.col
            local newCol = oldCol + 1
            
            -- Clear old position
            self.grid[row][oldCol] = nil
            
            -- Set new position
            self.grid[row][newCol] = cdID
            
            -- Update member data
            if self.members[cdID] then
                self.members[cdID].col = newCol
                
                -- Update saved position
                SaveGroupPosition(cdID, self.name, row, newCol)
            end
        end
        
        return true
    end
    
    -- ADD MEMBER AT POSITION (direct placement, for loading saved or new members - CAN expand grid)
    function group:AddMemberAt(cooldownID, row, col)
        -- Hook for SaveTracker debugger
        local SaveTracker = (_G.ArcUI_NS and _G.ArcUI_NS.SaveTracker) or (_G.ArcUI and _G.ArcUI.SaveTracker) or _G.ArcUI_SaveTracker
        if SaveTracker and SaveTracker.OnAddMemberAt then
            local hadSaved = ns.CDMGroups.savedPositions[cooldownID] ~= nil
            SaveTracker.OnAddMemberAt(cooldownID, self.name, row, col, hadSaved)
        end
        
        -- Check if this type is enabled FIRST
        local viewerType = GetViewerTypeForCooldownID(cooldownID)
        if viewerType and not IsViewerTypeEnabled(viewerType) then
            return false  -- Skip - this type is disabled
        end
        
        -- Track if this icon had a saved position BEFORE we add it
        -- If not, we should force save even during restoration
        local hadSavedPosition = ns.CDMGroups.savedPositions[cooldownID] ~= nil
        
        if self.members[cooldownID] then
            -- Already in group, just move it (strict bounds)
            self:PlaceMemberAt(cooldownID, row, col)
            return true
        end
        
        -- Check if tracked in ANOTHER group - if so, don't steal it
        -- (User must explicitly drag to move between groups)
        for otherName, otherGroup in pairs(ns.CDMGroups.groups) do
            if otherName ~= self.name and otherGroup.members and otherGroup.members[cooldownID] then
                -- Icon is already tracked elsewhere - don't add here
                return false
            end
        end
        
        if ns.CDMGroups.freeIcons[cooldownID] then
            ns.CDMGroups.ReleaseFreeIcon(cooldownID, true)
        end
        
        local frame, entry = Registry:GetValidFrameForCooldownID(cooldownID)
        
        -- Skip frames that are actual status bars (have Bar element) - these aren't icon-based
        if frame and frame.Bar and frame.Bar.IsObjectType and frame.Bar:IsObjectType("StatusBar") then return end
        
        -- Check bounds BEFORE doing anything
        -- IMPORTANT: Only block placement for frameless placeholders during spec switch
        -- If we have a frame, we MUST place it and expand grid to fit
        if row >= self.layout.gridRows or col >= self.layout.gridCols then
            if ns.CDMGroups.blockGridExpansion and not frame then
                -- Only block frameless placeholder entries - save position for later restoration
                SaveGroupPosition(cooldownID, self.name, row, col)
                return false
            end
            -- If we have a frame, continue - grid will expand below
        end
        
        -- Get viewerType for this cooldown
        local viewerType, defaultGroup, viewerName = GetViewerTypeForCooldownID(cooldownID)
        
        -- Calculate effective icon dimensions for centering
        local slotW, slotH = GetSlotDimensions(self.layout)
        local effectiveW = slotW
        local effectiveH = slotH
        if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
            local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cooldownID)
            if cfg and cfg.useGroupScale == false then
                local baseW = cfg.width or slotW
                local baseH = cfg.height or slotH
                local iconScale = cfg.scale or 1.0
                effectiveW = baseW * iconScale
                effectiveH = baseH * iconScale
            end
        end
        
        -- Create member entry - even without frame
        -- This allows AutoAssignNewIcons to give us the frame later
        local member = {
            frame = nil,
            entry = nil,
            row = row,
            col = col,
            targetParent = self.container,
            viewerType = viewerType,
            defaultGroup = defaultGroup,
            originalViewerName = viewerName,
            _effectiveIconW = effectiveW,
            _effectiveIconH = effectiveH,
        }
        
        if frame then
            if not entry then
                entry = Registry:GetOrCreate(frame, viewerName or ("ns.CDMGroups." .. self.name))
            end
            entry.originalParent = entry.originalParent or frame:GetParent()
            
            -- Update member with entry info if available
            if entry.viewerType and not member.viewerType then
                member.viewerType = entry.viewerType
                member.defaultGroup = entry.defaultGroup
                member.originalViewerName = entry.viewerName
            end
            
            -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
            -- Otherwise ClearAllPoints hooks will restore wrong centering offset
            frame._cdmgTargetX = nil
            frame._cdmgTargetY = nil
            frame._cdmgTargetPoint = nil
            frame._cdmgTargetRelPoint = nil
            
            local slotW, slotH = GetSlotDimensions(self.layout)
            local effW, effH = SetupFrameInContainer(frame, self.container, slotW, slotH, cooldownID)
            
            -- Update member with actual effective dimensions from SetupFrameInContainer
            member._effectiveIconW = effW
            member._effectiveIconH = effH
            
            member.frame = frame
            member.entry = entry
            entry.manipulated = true
            entry.group = self
            
            -- CRITICAL: Notify CDMEnhance so it updates its tracking
            SafeEnhanceFrame(frame, cooldownID, member.viewerType, member.originalViewerName)
        end
        
        -- Check if something is at this position
        if self.grid[row] and self.grid[row][col] then
            local existingCdID = self.grid[row][col]
            if existingCdID ~= cooldownID then
                -- Check if the existing entry actually has a member
                if self.members[existingCdID] then
                    -- CRITICAL: During restoration, check if existing icon has saved position for this slot
                    -- If it does, it has priority - we should NOT displace it
                    local existingSaved = ns.CDMGroups.savedPositions[existingCdID]
                    local existingHasPriority = IsRestoring() and existingSaved and 
                        existingSaved.type == "group" and existingSaved.target == self.name and
                        existingSaved.row == row and existingSaved.col == col
                    
                    if existingHasPriority then
                        -- Existing icon has this slot saved - find a free slot for OUR icon instead
                        local freeRow, freeCol = self:FindNextFreeSlot()
                        if freeRow and freeCol then
                            -- Recursively place at free slot
                            row = freeRow
                            col = freeCol
                            -- Update member position
                            member.row = row
                            member.col = col
                        else
                            -- No free slot - skip this icon for now
                            return false
                        end
                    else
                        -- Normal operation OR existing icon doesn't have priority - displace it
                        local newRow, newCol = self:FindNextFreeSlot()
                        if newRow and newCol then
                            self:MoveMemberTo(existingCdID, newRow, newCol)
                        else
                            -- No free slot available - can't place this icon
                            return false
                        end
                    end
                else
                    -- Stale grid entry - just clear it
                    self.grid[row][col] = nil
                end
            end
        end
        
        self.members[cooldownID] = member
        if not self.grid[row] then self.grid[row] = {} end
        self.grid[row][col] = cooldownID
        
        -- Expand grid if needed
        -- ALWAYS expand if member has a frame - icons must never be hidden
        -- Only respect blockGridExpansion/lockGridSize for frameless placeholder entries
        local db = getDB()
        local hasFrame = member.frame ~= nil
        local expansionBlocked = ns.CDMGroups.blockGridExpansion or self.lockGridSize
        if row >= self.layout.gridRows then
            if hasFrame or not expansionBlocked then
                self.layout.gridRows = row + 1
                if db then db.gridRows = self.layout.gridRows end
            end
        end
        if col >= self.layout.gridCols then
            if hasFrame or not expansionBlocked then
                self.layout.gridCols = col + 1
                if db then db.gridCols = self.layout.gridCols end
            end
        end
        
        -- Force save if this icon didn't have a saved position (new/legacy icons)
        -- CRITICAL: ONLY force save AFTER profile loading is complete!
        -- During initial load, savedPositions might be empty just because profile hasn't loaded yet
        -- We must NOT overwrite the profile with default positions in this case
        local profileFullyLoaded = not ns.CDMGroups.initialLoadInProgress and 
                                   not ns.CDMGroups._profileNotLoaded and
                                   not IsRestoring()
        local shouldForceSave = not hadSavedPosition and profileFullyLoaded
        
        SaveGroupPosition(cooldownID, self.name, row, col, shouldForceSave)
        
        -- Save grid
        self:MarkGridDirty()
        
        -- Hide any placeholder for this cdID now that we have a real frame
        -- GUARD: Only for numeric IDs (Arc Auras use string IDs)
        if frame and type(cooldownID) == "number" and ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.HidePlaceholder then
            ns.CDMGroups.Placeholders.HidePlaceholder(cooldownID)
        end
        
        -- Clear placeholder status now that we have a real frame
        if frame then
            member.isPlaceholder = nil
            member.placeholderInfo = nil
            -- Also clear in savedPositions
            if ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[cooldownID] then
                ns.CDMGroups.savedPositions[cooldownID].isPlaceholder = nil
            end
            -- Notify DynamicLayout that placeholder was resolved
            if ns.CDMGroups.DynamicLayout and ns.CDMGroups.DynamicLayout.OnPlaceholderResolved then
                ns.CDMGroups.DynamicLayout.OnPlaceholderResolved(cooldownID, self.name)
            end
        end
        
        -- Always set up member handlers when frame exists (for click-to-select)
        if frame then
            self:SetupMemberDrag(cooldownID)
            
            -- CRITICAL: If dragging is allowed, ensure mouse is enabled AFTER all setup
            if ns.CDMGroups.ShouldAllowDrag() then
                frame:EnableMouse(true)
                if frame.SetMouseClickThrough then
                    frame:SetMouseClickThrough(false)
                end
            end
        end
        
        self:Layout()
        return true
    end
    -- ADD MEMBER (auto position - can expand grid unless blocked)
    function group:AddMember(cooldownID)
        -- Check if this type is enabled FIRST
        local viewerType = GetViewerTypeForCooldownID(cooldownID)
        if viewerType and not IsViewerTypeEnabled(viewerType) then
            return false  -- Skip - this type is disabled
        end
        
        if self.members[cooldownID] then return false end
        
        local row, col = self:FindNextFreeSlot()
        if row == nil then
            -- Grid is full and expansion blocked
            return false
        end
        self:AddMemberAt(cooldownID, row, col)
        return true
    end
    
    -- ADD MEMBER AT POSITION WITH EXISTING FRAME (for cross-group transfers)
    function group:AddMemberAtWithFrame(cooldownID, row, col, frame, entry)
        -- Check if this type is enabled FIRST
        local viewerType = GetViewerTypeForCooldownID(cooldownID)
        if viewerType and not IsViewerTypeEnabled(viewerType) then
            return  -- Skip - this type is disabled
        end
        
        -- Track if this icon had a saved position BEFORE we add it
        local hadSavedPosition = ns.CDMGroups.savedPositions[cooldownID] ~= nil
        
        -- Skip frames that are actual status bars (have Bar element) - these aren't icon-based
        if frame and frame.Bar and frame.Bar.IsObjectType and frame.Bar:IsObjectType("StatusBar") then return end
        
        if self.members[cooldownID] then
            self:PlaceMemberAt(cooldownID, row, col)
            return
        end
        
        -- If no frame provided, fall back to normal AddMemberAt
        if not frame then
            self:AddMemberAt(cooldownID, row, col)
            return
        end
        
        if ns.CDMGroups.freeIcons[cooldownID] then
            ns.CDMGroups.ReleaseFreeIcon(cooldownID, true)
        end
        
        -- Use provided frame/entry
        if not entry then
            entry = Registry:GetOrCreate(frame, "ns.CDMGroups." .. self.name)
        end
        entry.originalParent = entry.originalParent or frame:GetParent()
        
        -- Check if something is at this position
        if self.grid[row] and self.grid[row][col] then
            local existingCdID = self.grid[row][col]
            if existingCdID ~= cooldownID then
                local existingMember = self.members[existingCdID]
                if existingMember and HasValidFrame(existingMember, existingCdID) then
                    -- CRITICAL: Find a free slot, allowing expansion
                    local newRow, newCol = self:FindNextFreeSlot(true)
                    if newRow and newCol then
                        -- CRITICAL: If the new position is outside current grid, expand FIRST
                        -- Otherwise MoveMemberTo will clamp and fail to actually move
                        local db = getDB()
                        if newRow >= self.layout.gridRows then
                            self.layout.gridRows = newRow + 1
                            if db then db.gridRows = self.layout.gridRows end
                        end
                        if newCol >= self.layout.gridCols then
                            self.layout.gridCols = newCol + 1
                            if db then db.gridCols = self.layout.gridCols end
                        end
                        
                        -- Now move the existing member (grid is big enough)
                        -- Use PlaceMemberAt which handles swapping properly
                        self:PlaceMemberAt(existingCdID, newRow, newCol)
                    end
                    -- If no free slot and can't expand, the icons will overlap (fallback)
                else
                    -- Stale entry - clean it up
                    self.grid[row][col] = nil
                    if existingMember then
                        self.members[existingCdID] = nil
                    end
                end
            end
        end
        
        -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
        -- Otherwise ClearAllPoints hooks will restore wrong centering offset
        frame._cdmgTargetX = nil
        frame._cdmgTargetY = nil
        frame._cdmgTargetPoint = nil
        frame._cdmgTargetRelPoint = nil
        
        local slotW, slotH = GetSlotDimensions(self.layout)
        local effectiveW, effectiveH = SetupFrameInContainer(frame, self.container, slotW, slotH, cooldownID)
        
        self.members[cooldownID] = {
            frame = frame,
            entry = entry,
            row = row,
            col = col,
            targetParent = self.container,
            _effectiveIconW = effectiveW,
            _effectiveIconH = effectiveH,
        }
        
        if not self.grid[row] then self.grid[row] = {} end
        self.grid[row][col] = cooldownID
        
        entry.manipulated = true
        entry.group = self
        
        -- CRITICAL: Notify CDMEnhance so it updates its tracking
        local viewerType, _, viewerName = GetViewerTypeForCooldownID(cooldownID)
        SafeEnhanceFrame(frame, cooldownID, viewerType, viewerName)
        
        -- CLICK-THROUGH: Re-apply AFTER EnhanceFrame creates overlays
        -- EnhanceFrame creates _arcTextOverlay etc which need to be disabled for click-through
        if not ns.CDMGroups.ShouldAllowDrag() and ShouldMakeClickThrough() then
            ApplyClickThrough(frame, true)
        end
        
        -- Handle grid expansion - ALWAYS expand since this function always has a frame
        -- Icons with frames must never be hidden
        local db = getDB()
        if row >= self.layout.gridRows then
            self.layout.gridRows = row + 1
            if db then db.gridRows = self.layout.gridRows end
        end
        if col >= self.layout.gridCols then
            self.layout.gridCols = col + 1
            if db then db.gridCols = self.layout.gridCols end
        end
        
        -- Force save if this icon didn't have a saved position (new/legacy icons)
        SaveGroupPosition(cooldownID, self.name, row, col, not hadSavedPosition)
        
        self:MarkGridDirty()
        
        -- Hide any placeholder for this cdID now that we have a real frame
        -- GUARD: Only for numeric IDs (Arc Auras use string IDs)
        if type(cooldownID) == "number" and ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.HidePlaceholder then
            ns.CDMGroups.Placeholders.HidePlaceholder(cooldownID)
        end
        
        -- Clear placeholder flag in savedPositions since we now have a real frame
        if ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[cooldownID] then
            ns.CDMGroups.savedPositions[cooldownID].isPlaceholder = nil
        end
        
        -- Notify DynamicLayout that placeholder was resolved
        if ns.CDMGroups.DynamicLayout and ns.CDMGroups.DynamicLayout.OnPlaceholderResolved then
            ns.CDMGroups.DynamicLayout.OnPlaceholderResolved(cooldownID, self.name)
        end
        
        -- Always set up member handlers (for click-to-select functionality)
        self:SetupMemberDrag(cooldownID)
        
        self:Layout()
    end
    
    -- INSERT MEMBER AT POSITION WITH EXISTING FRAME (for cross-group transfers)
    function group:InsertMemberAtWithFrame(cooldownID, row, insertCol, frame, entry)
        -- Skip frames that are actual status bars (have Bar element) - these aren't icon-based
        if frame and frame.Bar and frame.Bar.IsObjectType and frame.Bar:IsObjectType("StatusBar") then return end
        
        if self.members[cooldownID] then
            self:MoveMemberTo(cooldownID, row, insertCol)
            return
        end
        
        if not frame then
            self:InsertMemberAt(cooldownID, row, insertCol)
            return
        end
        
        if ns.CDMGroups.freeIcons[cooldownID] then
            ns.CDMGroups.ReleaseFreeIcon(cooldownID, true)
        end
        
        if not entry then
            entry = Registry:GetOrCreate(frame, "ns.CDMGroups." .. self.name)
        end
        entry.originalParent = entry.originalParent or frame:GetParent()
        
        local maxCols = self.layout.gridCols
        row = Clamp(row, 0, self.layout.gridRows - 1)
        insertCol = Clamp(insertCol, 0, maxCols)
        
        if insertCol >= maxCols then
            self:AddMemberAtWithFrame(cooldownID, row, insertCol, frame, entry)
            return
        end
        
        -- CRITICAL: Check if position is occupied by a VALID member before shifting
        local existingCdID = self.grid[row] and self.grid[row][insertCol]
        if existingCdID and existingCdID ~= cooldownID then
            local existingMember = self.members[existingCdID]
            if existingMember and HasValidFrame(existingMember, existingCdID) then
                -- Position is occupied by a valid member - try to shift
                if not self:ShiftRowRight(row, insertCol) then
                    -- Shift failed (grid full) - ADD A COLUMN to make room
                    local db = getDB()
                    self.layout.gridCols = self.layout.gridCols + 1
                    if db then db.gridCols = self.layout.gridCols end
                    maxCols = self.layout.gridCols
                    
                    -- Now shift should work
                    self:ShiftRowRight(row, insertCol)
                end
            else
                -- Stale entry - clean it up
                self.grid[row][insertCol] = nil
                if existingMember then
                    ReturnFrameToCDM(existingMember.frame, existingMember.entry)
                    self.members[existingCdID] = nil
                end
            end
        elseif not existingCdID then
            -- Position is free, no need to shift
        end
        
        -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
        -- Otherwise ClearAllPoints hooks will restore wrong centering offset
        frame._cdmgTargetX = nil
        frame._cdmgTargetY = nil
        frame._cdmgTargetPoint = nil
        frame._cdmgTargetRelPoint = nil
        
        local slotW, slotH = GetSlotDimensions(self.layout)
        local effectiveW, effectiveH = SetupFrameInContainer(frame, self.container, slotW, slotH, cooldownID)
        
        self.members[cooldownID] = {
            frame = frame,
            entry = entry,
            row = row,
            col = insertCol,
            targetParent = self.container,
            _effectiveIconW = effectiveW,
            _effectiveIconH = effectiveH,
        }
        
        if not self.grid[row] then self.grid[row] = {} end
        self.grid[row][insertCol] = cooldownID
        
        entry.manipulated = true
        entry.group = self
        
        -- CRITICAL: Notify CDMEnhance so it updates its tracking
        local viewerType, _, viewerName = GetViewerTypeForCooldownID(cooldownID)
        SafeEnhanceFrame(frame, cooldownID, viewerType, viewerName)
        
        SaveGroupPosition(cooldownID, self.name, row, insertCol)
        
        self:MarkGridDirty()
        
        -- Always set up member handlers (for click-to-select functionality)
        self:SetupMemberDrag(cooldownID)
        
        -- CRITICAL: If dragging is allowed, ensure mouse is enabled AFTER all setup
        -- This must come after SetupMemberDrag and before Layout to prevent overwriting
        if ns.CDMGroups.ShouldAllowDrag() and frame then
            frame:EnableMouse(true)
            if frame.SetMouseClickThrough then
                frame:SetMouseClickThrough(false)
            end
        end
        
        self:Layout()
    end
    
    -- MOVE MEMBER TO POSITION (with insertion/shifting, expands grid if needed)
    function group:MoveMemberTo(cooldownID, newRow, insertCol)
        local member = self.members[cooldownID]
        if not member then return false end
        
        local maxRows = self.layout.gridRows
        local maxCols = self.layout.gridCols
        
        -- Clamp to grid bounds
        newRow = Clamp(newRow, 0, maxRows - 1)
        insertCol = Clamp(insertCol, 0, maxCols - 1)
        
        local oldRow, oldCol = member.row, member.col
        
        -- If same position, nothing to do
        if oldRow == newRow and oldCol == insertCol then return false end
        
        -- Clear old position first (leave a gap) - only if we have valid old position
        if oldRow ~= nil and oldCol ~= nil and self.grid[oldRow] then
            self.grid[oldRow][oldCol] = nil
        end
        
        -- Check if target position is occupied
        local targetOccupied = self.grid[newRow] and self.grid[newRow][insertCol]
        
        if targetOccupied then
            -- Use ShiftRowRight which handles wrapping within grid bounds
            local canShift = self:ShiftRowRight(newRow, insertCol)
            if not canShift then
                -- Shift failed (grid full) - ADD A COLUMN to make room
                local db = getDB()
                self.layout.gridCols = self.layout.gridCols + 1
                if db then db.gridCols = self.layout.gridCols end
                maxCols = self.layout.gridCols
                
                -- Now shift should work
                self:ShiftRowRight(newRow, insertCol)
            end
        end
        
        -- Place member at insert position
        member.row = newRow
        member.col = insertCol
        if not self.grid[newRow] then self.grid[newRow] = {} end
        self.grid[newRow][insertCol] = cooldownID
        
        SaveGroupPosition(cooldownID, self.name, member.row, member.col)
        
        self:MarkGridDirty()
        self:Layout()
        return true
    end
    
    -- SWAP MEMBERS (swap positions of two icons in same group)
    function group:SwapMembers(cooldownID, targetRow, targetCol)
        local member = self.members[cooldownID]
        if not member then return false end
        
        local maxRows = self.layout.gridRows
        local maxCols = self.layout.gridCols
        
        -- Clamp to grid bounds
        targetRow = Clamp(targetRow, 0, maxRows - 1)
        targetCol = Clamp(targetCol, 0, maxCols - 1)
        
        local oldRow, oldCol = member.row, member.col
        
        -- If member doesn't have valid position, can't swap
        if oldRow == nil or oldCol == nil then return false end
        
        if oldRow == targetRow and oldCol == targetCol then return false end
        
        -- Get target icon if any
        local targetCdID = self.grid[targetRow] and self.grid[targetRow][targetCol]
        
        -- Check if in edit mode (options panel open)
        local editMode = ns.CDMGroups.IsOptionsPanelOpen and ns.CDMGroups.IsOptionsPanelOpen()
        
        -- For autoReflow groups (NOT in edit mode), we need to swap sortIndex values to preserve visual order
        local srcSortIndex, destSortIndex
        if self.autoReflow and targetCdID and not editMode then
            local srcSaved = ns.CDMGroups.savedPositions[cooldownID]
            local destSaved = ns.CDMGroups.savedPositions[targetCdID]
            srcSortIndex = srcSaved and srcSaved.sortIndex
            destSortIndex = destSaved and destSaved.sortIndex
        end
        
        -- Move dragged icon to target position
        if self.grid[oldRow] then
            self.grid[oldRow][oldCol] = nil
        end
        
        if not self.grid[targetRow] then self.grid[targetRow] = {} end
        self.grid[targetRow][targetCol] = cooldownID
        member.row = targetRow
        member.col = targetCol
        
        -- For autoReflow groups (NOT in edit mode), preserve swapped sortIndex to maintain sequence
        if self.autoReflow and targetCdID and destSortIndex and not editMode then
            SaveGroupPosition(cooldownID, self.name, targetRow, targetCol, false, destSortIndex)
        else
            SaveGroupPosition(cooldownID, self.name, targetRow, targetCol)
        end
        
        -- Move target icon to old position (if there was one)
        if targetCdID and self.members[targetCdID] then
            if not self.grid[oldRow] then self.grid[oldRow] = {} end
            self.grid[oldRow][oldCol] = targetCdID
            self.members[targetCdID].row = oldRow
            self.members[targetCdID].col = oldCol
            
            -- For autoReflow groups (NOT in edit mode), preserve swapped sortIndex
            if self.autoReflow and srcSortIndex and not editMode then
                SaveGroupPosition(targetCdID, self.name, oldRow, oldCol, false, srcSortIndex)
            else
                SaveGroupPosition(targetCdID, self.name, oldRow, oldCol)
            end
        end
        
        self:MarkGridDirty()
        
        -- For autoReflow (not in edit mode), call ReflowIcons to ensure proper alignment
        -- In edit mode, just call Layout directly
        if self.autoReflow and not editMode then
            self:ReflowIcons()
        else
            self:Layout()
        end
        return true
    end
    
    -- SWAP IN MEMBER (place new icon from outside, displacing existing to next free slot)
    function group:SwapInMember(cooldownID, targetRow, targetCol)
        local maxRows = self.layout.gridRows
        local maxCols = self.layout.gridCols
        
        -- Clamp target to current grid bounds
        targetRow = Clamp(targetRow, 0, maxRows - 1)
        targetCol = Clamp(targetCol, 0, maxCols - 1)
        
        -- Get existing icon at target position
        local existingCdID = self.grid[targetRow] and self.grid[targetRow][targetCol]
        
        if existingCdID and existingCdID ~= cooldownID then
            -- Move existing icon to a free slot
            local freeRow, freeCol = self:FindNextFreeSlot()
            
            if freeRow == nil then
                -- Grid is full, cannot swap - just don't do anything
                return false
            end
            
            if self.members[existingCdID] then
                -- Clear old position
                if self.grid[targetRow] then
                    self.grid[targetRow][targetCol] = nil
                end
                
                -- Move to free slot
                self.members[existingCdID].row = freeRow
                self.members[existingCdID].col = freeCol
                if not self.grid[freeRow] then self.grid[freeRow] = {} end
                self.grid[freeRow][freeCol] = existingCdID
                
                SaveGroupPosition(existingCdID, self.name, freeRow, freeCol)
            end
        end
        
        -- Now place the new icon
        self:AddMemberAt(cooldownID, targetRow, targetCol)
    end
    
    -- PLACE MEMBER AT (direct placement, no shifting, for empty cells or same-group moves)
    function group:PlaceMemberAt(cooldownID, targetRow, targetCol)
        local member = self.members[cooldownID]
        if not member then return false end
        
        local maxRows = self.layout.gridRows
        local maxCols = self.layout.gridCols
        local db = getDB()
        
        -- If member has a valid frame, expand grid if needed instead of clamping
        -- This ensures icons are never lost due to grid being too small
        if member.frame and HasValidFrame(member, cooldownID) then
            if targetRow >= maxRows then
                self.layout.gridRows = targetRow + 1
                if db then db.gridRows = self.layout.gridRows end
                maxRows = self.layout.gridRows
            end
            if targetCol >= maxCols then
                self.layout.gridCols = targetCol + 1
                if db then db.gridCols = self.layout.gridCols end
                maxCols = self.layout.gridCols
            end
        end
        
        -- Clamp to (possibly expanded) grid bounds
        targetRow = Clamp(targetRow, 0, maxRows - 1)
        targetCol = Clamp(targetCol, 0, maxCols - 1)
        
        local oldRow, oldCol = member.row, member.col
        if oldRow == targetRow and oldCol == targetCol then return false end
        
        -- Check for collision - swap if occupied
        local existingCdID = self.grid[targetRow] and self.grid[targetRow][targetCol]
        local existingMember = existingCdID and self.members[existingCdID]
        
        -- Clear old position (only if we have valid old position)
        if oldRow ~= nil and oldCol ~= nil and self.grid[oldRow] then
            self.grid[oldRow][oldCol] = nil
        end
        
        -- Place at new position
        member.row = targetRow
        member.col = targetCol
        if not self.grid[targetRow] then self.grid[targetRow] = {} end
        self.grid[targetRow][targetCol] = cooldownID
        
        SaveGroupPosition(cooldownID, self.name, targetRow, targetCol)
        
        -- Handle collision with existing icon
        if existingCdID and existingCdID ~= cooldownID and existingMember then
            if oldRow ~= nil and oldCol ~= nil then
                -- We have a valid old position - swap the existing icon there
                if not self.grid[oldRow] then self.grid[oldRow] = {} end
                self.grid[oldRow][oldCol] = existingCdID
                existingMember.row = oldRow
                existingMember.col = oldCol
                
                SaveGroupPosition(existingCdID, self.name, oldRow, oldCol)
            else
                -- No valid old position to swap to
                -- If existing is a placeholder, remove it from members (savedPosition kept for future restore)
                -- If existing is a real icon, this shouldn't happen but handle gracefully
                if existingMember.isPlaceholder then
                    -- Placeholder can't be swapped - remove from members
                    -- Its savedPosition is preserved so it can be restored if the real icon moves away
                    self.members[existingCdID] = nil
                    -- Also clear its stale row/col from savedPosition to avoid confusion
                    local saved = ns.CDMGroups.savedPositions[existingCdID]
                    if saved then
                        saved._displacedBy = cooldownID  -- Track what displaced it
                    end
                else
                    -- Real icon with no place to go - shouldn't happen, but mark position as invalid
                    existingMember.row = nil
                    existingMember.col = nil
                end
            end
        end
        
        self:MarkGridDirty()
        self:Layout()
        return true
    end
    
    -- REORDER ICON IN SEQUENCE (for autoReflow groups)
    -- Updates the icon's position in the sorted sequence based on target grid position
    -- Then calls ReflowIcons to apply the new order with proper alignment
    function group:ReorderIconInSequence(cooldownID, targetRow, targetCol)
        local member = self.members[cooldownID]
        if not member then return false end
        
        local maxCols = self.layout.gridCols
        local maxRows = self.layout.gridRows
        
        -- Collect all icons with their current sortIndex
        local allIcons = {}
        for cdID, m in pairs(self.members) do
            if m.row ~= nil and m.col ~= nil then
                local saved = ns.CDMGroups.savedPositions[cdID]
                local sortIndex = saved and saved.sortIndex or (m.row * maxCols + m.col)
                table.insert(allIcons, { cdID = cdID, sortIndex = sortIndex })
            end
        end
        
        -- Sort by current sortIndex
        table.sort(allIcons, function(a, b) return a.sortIndex < b.sortIndex end)
        
        -- Find current position of the dragged icon in the sequence
        local currentSeqPos = 0
        for i, iconData in ipairs(allIcons) do
            if iconData.cdID == cooldownID then
                currentSeqPos = i
                break
            end
        end
        
        -- Calculate target sequence position based on grid column
        -- For a centered group, we need to map grid position to sequence position
        local gridShape = ns.CDMGroups.DetectGridShape(maxRows, maxCols)
        local alignment = self.layout.alignment or ns.CDMGroups.GetDefaultAlignment(gridShape)
        
        -- Calculate the starting column offset (where icons begin in the grid)
        local iconCount = #allIcons
        local startOffset = 0
        if gridShape == "horizontal" and alignment == "center" then
            local emptySlots = maxCols - iconCount
            if emptySlots > 0 then
                -- Use ceiling to match ReflowIcons behavior
                startOffset = math.ceil(emptySlots / 2)
            end
        elseif gridShape == "horizontal" and alignment == "right" then
            startOffset = maxCols - iconCount
        end
        
        -- Map target column to sequence position
        -- targetCol - startOffset = sequence position (0-based)
        local targetSeqPos = targetCol - startOffset + 1  -- 1-based for table.insert
        
        -- Clamp to valid range
        if targetSeqPos < 1 then targetSeqPos = 1 end
        if targetSeqPos > iconCount then targetSeqPos = iconCount end
        
        -- If same position, nothing to do
        if targetSeqPos == currentSeqPos then
            self:Layout()
            return false
        end
        
        -- Remove icon from current position
        table.remove(allIcons, currentSeqPos)
        
        -- Adjust target position if removing from before the target
        if currentSeqPos < targetSeqPos then
            targetSeqPos = targetSeqPos - 1
        end
        
        -- Insert at new position
        table.insert(allIcons, targetSeqPos, { cdID = cooldownID, sortIndex = 0 })
        
        -- Renumber sortIndex values
        for i, iconData in ipairs(allIcons) do
            local saved = ns.CDMGroups.savedPositions[iconData.cdID]
            if saved then
                saved.sortIndex = i - 1  -- 0-based
            end
        end
        
        -- Now reflow to apply new order
        self:ReflowIcons()
        return true
    end
    
    -- REMOVE MEMBER
    function group:RemoveMember(cooldownID, clearSaved, skipLayout)
        local member = self.members[cooldownID]
        if not member then return end
        
        local frame = member.frame
        local entry = member.entry
        
        -- CRITICAL: Save position BEFORE removing if not clearing
        if not clearSaved then
            SaveGroupPosition(cooldownID, self.name, member.row, member.col)
        end
        
        -- Use ReturnFrameToCDM for thorough cleanup (drag handlers, properties, etc)
        ReturnFrameToCDM(frame, entry)
        
        -- Clear from grid (only if we have valid position)
        if member.row ~= nil and member.col ~= nil and self.grid[member.row] then
            self.grid[member.row][member.col] = nil
        end
        
        self.members[cooldownID] = nil
        
        if clearSaved then
            -- ClearPositionFromSpec now uses GetProfileSavedPositions to ensure correct table
            ClearPositionFromSpec(cooldownID)
        end
        
        self:MarkGridDirty()
        
        -- Only do cleanup and layout if not skipped (prevents recursion)
        if not skipLayout then
            -- If autoReflow is enabled, reflow to fill the gap
            if self.autoReflow then
                self:ReflowIcons()
            else
                self:CleanupEmptyRowsCols()
                self:Layout()
            end
        end
    end
    
    -- REMOVE MEMBER BUT KEEP FRAME (for cross-group transfers)
    function group:RemoveMemberKeepFrame(cooldownID)
        local member = self.members[cooldownID]
        if not member then return nil, nil end
        
        local frame = member.frame
        local entry = member.entry
        
        -- Clear from grid (only if we have valid position)
        if member.row ~= nil and member.col ~= nil and self.grid[member.row] then
            self.grid[member.row][member.col] = nil
        end
        
        -- Clear saved positions (will be set by target group)
        -- ClearPositionFromSpec now uses GetProfileSavedPositions to ensure correct table
        ClearPositionFromSpec(cooldownID)
        
        -- Remove from members but DON'T return frame to CDM
        self.members[cooldownID] = nil
        
        -- Clear entry group reference (will be set by target group)
        if entry then
            entry.group = nil
            -- Keep manipulated = true since we're transferring
        end
        
        self:MarkGridDirty()
        self:CleanupEmptyRowsCols()
        
        return frame, entry
    end
    
    -- SAVE GRID TO DB
    function group:SaveGrid()
        local db = getDB()
        if not db then return end  -- Group may have been deleted or renamed
        
        db.grid = {}
        for row, cols in pairs(self.grid) do
            for col, cdID in pairs(cols) do
                -- Save if member exists (frame validity doesn't matter for position saving)
                local member = self.members[cdID]
                if member then
                    if not db.grid[tostring(row)] then
                        db.grid[tostring(row)] = {}
                    end
                    db.grid[tostring(row)][tostring(col)] = cdID
                end
            end
        end
        self._gridDirty = false
    end
    
    -- Mark grid as needing save (batched - actual save happens in ProcessDirtyGrids)
    function group:MarkGridDirty()
        self._gridDirty = true
    end
    
    -- VALIDATE GRID - Remove stale cdIDs that have no matching members
    function group:ValidateGrid()
        local cleaned = 0
        local toRemove = {}
        
        for row, cols in pairs(self.grid) do
            for col, cdID in pairs(cols) do
                local shouldRemove = false
                local reason = ""
                
                -- Check 1: Does member exist?
                if not self.members[cdID] then
                    shouldRemove = true
                    reason = "no member entry"
                end
                -- NOTE: We no longer remove members just because they lack valid frames
                -- They'll get frames when frames become available
                
                if shouldRemove then
                    table.insert(toRemove, { row = row, col = col, cdID = cdID })
                end
            end
        end
        
        -- Only remove grid entries where there's no member at all
        -- Keep grid entries for members without frames (position preserved)
        for _, info in ipairs(toRemove) do
            if self.grid[info.row] then
                self.grid[info.row][info.col] = nil
            end
            cleaned = cleaned + 1
        end
        
        if cleaned > 0 then
            self:MarkGridDirty()
        end
        return cleaned
    end
    
    -- CLEANUP EMPTY ROWS/COLUMNS (called when icons are removed)
    -- NOTE: This function NO LONGER auto-shrinks the grid
    -- The user's grid size setting is respected - use the +/- buttons to resize manually
    function group:CleanupEmptyRowsCols()
        -- Just validate grid to remove stale entries
        self:ValidateGrid()
        
        -- NOTE: Automatic grid shrinking has been disabled
        -- Previously this function would shrink empty rows/columns, but this caused issues
        -- when users wanted to maintain a specific grid size (e.g., 3 columns for future icons)
        -- Users can manually shrink the grid using the row/column buttons in edit mode
        
        return false  -- No changes made to grid size
    end
    
    -- REFLOW ICONS (redistribute icons sequentially to fill grid)
    function group:ReflowIcons()
        if self._reflowing then return end  -- Prevent recursion
        
        -- CRITICAL: Skip during spec changes - frames are being reassigned
        if ns.CDMGroups.specChangeInProgress then return end
        if ns.CDMGroups._pendingSpecChange then return end
        
        -- CRITICAL: Skip during restoration protection window
        -- Frames are still being assigned by CDM after spec change
        if ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd then
            return
        end
        
        -- CRITICAL: Skip during 2-second restoration period after spec change
        -- Even after protection flags clear, we need to let frames stabilize
        if IsRestoring() then
            return
        end
        
        -- CRITICAL: Skip while CDM options panel is open
        -- CDM silently reassigns frames - don't reflow until panel closes
        if IsCDMOptionsPanelOpen() then
            return
        end
        
        -- Skip reflow when options panel is open (user is editing layout)
        if ns.CDMGroups.IsOptionsPanelOpen and ns.CDMGroups.IsOptionsPanelOpen() then
            -- Set flag to prevent recursion, then just position at current grid positions
            self._reflowing = true
            self:Layout()
            self._reflowing = false
            return
        end
        
        self._reflowing = true
        
        -- CRITICAL: Block position saves during reflow
        -- Reflow changes member.row/col for visual compaction only
        local wasBlocked = ns.CDMGroups._blockPositionSaves
        ns.CDMGroups._blockPositionSaves = true
        
        -- ═══════════════════════════════════════════════════════════════════════
        -- DELEGATE TO DYNAMICLAYOUT MODULE
        -- DL.ReflowGroup handles:
        --   - Cooldowns + active auras compact together
        --   - Inactive auras treated as gaps (when dynamic enabled)
        --   - Alignment-aware slot ordering
        --   - Grid and member position updates
        -- ═══════════════════════════════════════════════════════════════════════
        local DL = ns.CDMGroups.DynamicLayout
        if DL and DL.ReflowGroup then
            DL.ReflowGroup(self)
        end
        
        -- NOTE: Placeholders are intentionally NOT re-added to the grid here.
        -- During reflow (options panel closed), placeholders are invisible and don't 
        -- participate in grid management. Their saved positions remain untouched.
        -- When edit mode opens, PositionPlaceholdersInGroup uses savedPositions directly.
        
        -- NOTE: Keep _reflowing = true through Layout call to prevent recursion
        -- Layout checks _reflowing to skip invalid frame detection
        self:Layout()
        self._reflowing = false  -- Clear AFTER layout completes
        
        -- Restore position saves blocking state
        ns.CDMGroups._blockPositionSaves = wasBlocked
    end
    
    -- RESTORE TO SAVED POSITIONS
    -- Restores all icons to their authoritative savedPositions
    -- Called when a new icon appears (was placeholder) to ensure savedPositions take precedence
    -- After this, ReflowIcons should be called to compact any gaps
    function group:RestoreToSavedPositions()
        local maxRows = self.layout.gridRows
        local maxCols = self.layout.gridCols
        
        -- Clear grid
        self.grid = {}
        for row = 0, maxRows - 1 do
            self.grid[row] = {}
        end
        
        -- Restore each member to their saved position
        for cdID, member in pairs(self.members) do
            -- Skip placeholders - they don't occupy grid during reflow
            if not member.isPlaceholder and HasValidFrame(member, cdID) then
                local saved = ns.CDMGroups.savedPositions[cdID]
                if saved and saved.type == "group" and saved.target == self.name then
                    local row = saved.row or 0
                    local col = saved.col or 0
                    
                    -- Clamp to grid bounds
                    row = math.min(row, maxRows - 1)
                    col = math.min(col, maxCols - 1)
                    
                    -- Update member position from saved
                    member.row = row
                    member.col = col
                    
                    -- Place in grid (if position not already taken)
                    -- If multiple icons saved at same position, first one wins
                    if not self.grid[row][col] then
                        self.grid[row][col] = cdID
                    end
                end
            end
        end
        
        self:MarkGridDirty()
    end
    
    -- LAYOUT
    function group:Layout()
        -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
        if not _cdmGroupsEnabled then return end
        
        -- CRITICAL: Skip ALL processing during spec change - frames are being reassigned
        if ns.CDMGroups.specChangeInProgress then return end
        if ns.CDMGroups._pendingSpecChange then return end
        
        -- Skip validation during restoration protection window OR during spec/talent changes
        -- ALSO skip when CDM panel is open - it may be manipulating frames
        -- (just position existing members, don't trigger reflow or remove "stale" frames)
        local skipValidation = (ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd)
            or (ns.CDMGroups._talentRestorationEnd and GetTime() < ns.CDMGroups._talentRestorationEnd)
            or ns.CDMGroups.talentChangeInProgress
            or IsCDMOptionsPanelOpen()  -- CDM panel may be moving frames around
        local skipReflow = skipValidation or ns.CDMGroups.specChangeInProgress or ns.CDMGroups._pendingSpecChange or IsRestoring()
        
        -- Calculate effective slot dimensions
        local slotW, slotH = GetSlotDimensions(self.layout)
        local spacingX = self.layout.spacingX or self.layout.spacing or 2
        local spacingY = self.layout.spacingY or self.layout.spacing or 2
        local rows = self.layout.gridRows or 2
        local cols = self.layout.gridCols or 4
        
        local padding = self.containerPadding or 0
        local borderOffset = 6  -- Inset for backdrop border (edgeSize = 2) + visual padding
        
        -- Helper function to calculate slot position
        -- NOTE: Alignment is handled in ReflowIcons by assigning icons to offset grid slots
        -- Layout just positions icons at their assigned row/col
        local function getSlotPosition(row, col, leftOverflow, topOverflow)
            -- Get cascade offset for this column/row (cumulative overflow from previous icons)
            local cascadeOffsetX = self._colCumulativeOffset and self._colCumulativeOffset[col] or 0
            local cascadeOffsetY = self._rowCumulativeOffset and self._rowCumulativeOffset[row] or 0
            
            local slotX = borderOffset + padding + (leftOverflow or 0) + col * (slotW + spacingX) + cascadeOffsetX
            local slotY = -borderOffset - padding - (topOverflow or 0) - row * (slotH + spacingY) - cascadeOffsetY
            return slotX, slotY
        end
        
        -- FIRST: Validate grid to remove stale entries (SKIP during restoration protection)
        if not skipValidation then
            local validatedCount = self:ValidateGrid()
            if validatedCount > 0 then
                -- ValidateGrid already removed the members, trigger reflow now
                if self.autoReflow and not self._reflowing and not skipReflow then
                    self:ReflowIcons()
                    return
                end
            end
            
            -- For autoReflow groups, also check if any members lost their frames
            -- This handles CDM icon removal (talent not learned, etc)
            -- CRITICAL: Exclude placeholders - they deliberately don't have frames!
            if self.autoReflow and not self._reflowing and not skipReflow then
                local hasInvalidFrames = false
                for cdID, member in pairs(self.members) do
                    -- Skip placeholders - they're intentionally frameless
                    if not member.isPlaceholder and member.row ~= nil and not HasValidFrame(member, cdID) then
                        hasInvalidFrames = true
                        break
                    end
                end
                if hasInvalidFrames then
                    -- Reflow to close visual gaps (keeps saved positions for when frames return)
                    self:ReflowIcons()
                    return
                end
            end
        end
        
        -- RESOLVE GRID CONFLICTS: Handle case where multiple members claim the same position
        -- This can happen from saved position duplicates, imports, placeholder collisions, etc.
        -- Run this before frame redistribution to ensure clean grid state
        if not skipValidation and ns.CDMGroups.ResolveGridConflicts then
            ns.CDMGroups.ResolveGridConflicts(self)
        end
        
        -- CRITICAL: During talent restoration, skip ALL frame redistribution logic
        -- CDM is actively reassigning frames - any intervention causes chaos
        -- Just position whatever frames we have at their grid positions
        if not skipValidation then
            -- Handle frame reassignments - collect ALL issues first
            local toRemove = {}
            
            -- PRE-PASS: Detect frames that CDM has reassigned to different cooldownIDs
            -- and redistribute them to the correct members BEFORE cleaning up
            local framesToRedistribute = {}  -- frame -> newCdID
            for cdID, member in pairs(self.members) do
                if member.frame then
                    local currentCdID = SafeGetFrameCooldownID(member.frame)
                    if currentCdID and currentCdID ~= cdID then
                        -- This frame now belongs to a different cooldown
                        framesToRedistribute[member.frame] = currentCdID
                        -- Clear from this member immediately
                        member.frame = nil
                        member.entry = nil
                    end
                end
            end
            
            -- Now assign redistributed frames to their correct members
            for frame, newCdID in pairs(framesToRedistribute) do
                local foundOwner = false
                -- Check if any member in THIS group needs this frame
                if self.members[newCdID] and not self.members[newCdID].frame then
                    local member = self.members[newCdID]
                    local entry = Registry:GetOrCreate(frame, "redistributed")
                    entry.originalParent = entry.originalParent or frame:GetParent()
                    
                    -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
                    frame._cdmgTargetX = nil
                    frame._cdmgTargetY = nil
                    frame._cdmgTargetPoint = nil
                    frame._cdmgTargetRelPoint = nil
                    
                    local slotW, slotH = GetSlotDimensions(self.layout)
                    local effectiveW, effectiveH = SetupFrameInContainer(frame, self.container, slotW, slotH, newCdID)
                    
                    member.frame = frame
                    member.entry = entry
                    member._effectiveIconW = effectiveW
                    member._effectiveIconH = effectiveH
                    entry.manipulated = true
                    entry.group = self
                    member.frameLostAt = nil
                    
                    -- CRITICAL: Notify CDMEnhance so it applies settings to new frame
                    SafeEnhanceFrame(frame, newCdID, member.viewerType, member.originalViewerName)
                    
                    if ns.CDMGroups.ShouldAllowDrag() then
                        self:SetupMemberDrag(newCdID)
                        frame:EnableMouse(true)
                        if frame.SetMouseClickThrough then
                            frame:SetMouseClickThrough(false)
                        end
                    end
                    foundOwner = true
                end
                
                -- Check other groups
                if not foundOwner then
                    for otherName, otherGroup in pairs(ns.CDMGroups.groups) do
                        if otherName ~= self.name and otherGroup.members[newCdID] and not otherGroup.members[newCdID].frame then
                            local member = otherGroup.members[newCdID]
                            local entry = Registry:GetOrCreate(frame, "redistributed")
                            entry.originalParent = entry.originalParent or frame:GetParent()
                            
                            -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
                            frame._cdmgTargetX = nil
                            frame._cdmgTargetY = nil
                            frame._cdmgTargetPoint = nil
                            frame._cdmgTargetRelPoint = nil
                            
                            local otherSlotW, otherSlotH = GetSlotDimensions(otherGroup.layout)
                            local effectiveW, effectiveH = SetupFrameInContainer(frame, otherGroup.container, otherSlotW, otherSlotH, newCdID)
                            
                            member.frame = frame
                            member.entry = entry
                            member._effectiveIconW = effectiveW
                            member._effectiveIconH = effectiveH
                            entry.manipulated = true
                            entry.group = otherGroup
                            member.frameLostAt = nil
                            
                            -- CRITICAL: Notify CDMEnhance so it applies settings to new frame
                            SafeEnhanceFrame(frame, newCdID, member.viewerType, member.originalViewerName)
                            
                            if ns.CDMGroups.ShouldAllowDrag() then
                                otherGroup:SetupMemberDrag(newCdID)
                                frame:EnableMouse(true)
                                if frame.SetMouseClickThrough then
                                    frame:SetMouseClickThrough(false)
                                end
                            end
                            foundOwner = true
                            break
                        end
                    end
                end
                
                -- If no member needs this frame, return it to CDM
                if not foundOwner then
                    ReturnFrameToCDM(frame, Registry:GetEntry(frame))
                end
            end
            
            -- MAIN PASS: Handle remaining frame issues
            for cdID, member in pairs(self.members) do
                local needsNewFrame = false
                local reason = ""
                
                if not member.frame then
                    needsNewFrame = true
                    reason = "nil frame"
                else
                    local currentCdID = SafeGetFrameCooldownID(member.frame)
                    if currentCdID == nil then
                        needsNewFrame = true
                        reason = "frame error"
                    elseif currentCdID ~= cdID then
                        needsNewFrame = true
                        reason = "reassigned to " .. tostring(currentCdID)
                    end
                end
                
                if needsNewFrame then
                    -- Try to find a DIFFERENT frame with this cdID (not the current one)
                    local newFrame = nil
                    
                    -- Method 0: Check if another group has a frame with this cdID - steal it
                    for otherName, otherGroup in pairs(ns.CDMGroups.groups) do
                        if otherName ~= self.name and otherGroup.members then
                            for otherCdID, otherMember in pairs(otherGroup.members) do
                                if otherMember.frame and SafeGetFrameCooldownID(otherMember.frame) == cdID then
                                    -- This other group has a frame showing our cdID - steal it
                                    newFrame = otherMember.frame
                                    -- Clear the other group's reference (don't remove member, just clear frame)
                                    otherMember.frame = nil
                                    otherMember.entry = nil
                                    break
                                end
                            end
                        end
                        if newFrame then break end
                    end
                    
                    -- Method 1: Search CDM viewers
                    for _, viewerInfo in ipairs(CDM_VIEWERS) do
                        -- Skip bar viewers - we only manage icon viewers
                        if not viewerInfo.skipInGroups then
                            local viewer = _G[viewerInfo.name]
                            if viewer then
                                local children = { viewer:GetChildren() }
                                for _, child in ipairs(children) do
                                    -- Must match cdID AND be a different frame than current
                                    if child.cooldownID == cdID and child ~= member.frame then
                                        newFrame = child
                                        Registry:Register(child, viewerInfo.name)
                                        break
                                    end
                                end
                            end
                        end
                        if newFrame then break end
                    end
                    
                    -- Method 2: Search registry for frames already reparented
                    if not newFrame then
                        for addr, entry in pairs(Registry.byAddress) do
                            if entry.frame and entry.frame.cooldownID == cdID and entry.frame ~= member.frame then
                                newFrame = entry.frame
                                break
                            end
                        end
                    end
                    
                    if newFrame then
                        -- Found a new frame - swap it in!
                        
                        -- CRITICAL: Clean up OLD frame first - return it to CDM so CDM can manage it
                        ReturnFrameToCDM(member.frame, member.entry)
                        
                        -- Set up new frame
                        local entry = Registry:GetOrCreate(newFrame, "readopted")
                        entry.originalParent = entry.originalParent or newFrame:GetParent()
                        
                        -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
                        newFrame._cdmgTargetX = nil
                        newFrame._cdmgTargetY = nil
                        newFrame._cdmgTargetPoint = nil
                        newFrame._cdmgTargetRelPoint = nil
                        
                        local slotW, slotH = GetSlotDimensions(self.layout)
                        local effectiveW, effectiveH = SetupFrameInContainer(newFrame, self.container, slotW, slotH, cdID)
                        
                        -- CRITICAL: MUST show frame after recovery
                        -- EXCEPT: Skip if frame is hidden due to hideWhenUnequipped setting
                        if not newFrame._arcHiddenUnequipped then
                            newFrame:SetAlpha(1)
                            newFrame:Show()
                        end
                        newFrame._arcRecoveryProtection = GetTime() + 0.5
                        
                        member.frame = newFrame
                        member.entry = entry
                        member._effectiveIconW = effectiveW
                        member._effectiveIconH = effectiveH
                        entry.manipulated = true
                        entry.group = self
                        
                        -- CRITICAL: Notify CDMEnhance so it applies settings to new frame
                        SafeEnhanceFrame(newFrame, cdID, member.viewerType, member.originalViewerName)
                        
                        -- Clear tracking flags - frame found!
                        member.frameLostAt = nil
                        if ns.CDMGroups.ShouldAllowDrag() then
                            self:SetupMemberDrag(cdID)
                            newFrame:EnableMouse(true)
                            if newFrame.SetMouseClickThrough then
                                newFrame:SetMouseClickThrough(false)
                            end
                        end
                    else
                        -- No frame found
                        -- BEHAVIOR DEPENDS ON CONTEXT:
                        -- - During spec switch (blockGridExpansion=true or recent spec change): Keep position, wait for frame
                        -- - Normal operation: After delay, remove and reflow (but save position for when icon returns)
                        
                        local shouldKeep = ns.CDMGroups.blockGridExpansion or IsRestoring()
                        
                        if shouldKeep then
                            -- Spec switch in progress - keep member, wait for frame
                            -- Track when frame was lost
                            if not member.frameLostAt then
                                member.frameLostAt = GetTime()
                            end
                            -- Clear frame reference but keep member
                            ReturnFrameToCDM(member.frame, member.entry)
                            member.frame = nil
                            member.entry = nil
                        else
                            -- Normal operation - check if frame has been missing long enough
                            if not member.frameLostAt then
                                member.frameLostAt = GetTime()
                            end
                            
                            local missingDuration = GetTime() - member.frameLostAt
                            if missingDuration < 0.5 then
                                -- Still waiting - maybe frame will appear
                                ReturnFrameToCDM(member.frame, member.entry)
                                member.frame = nil
                                member.entry = nil
                            else
                                -- Frame missing too long - remove from runtime tracking
                                -- NOTE: We do NOT delete savedPositions - keep for re-talent!
                                -- savedPositions already has the correct position from when icon was placed
                                
                                -- Clear frame reference and mark for removal
                                ReturnFrameToCDM(member.frame, member.entry)
                                
                                -- Mark for removal from members table
                                table.insert(toRemove, cdID)
                            end
                        end
                    end
                end
            end
            
            -- Remove frameless members and trigger reflow if needed
            if #toRemove > 0 then
                for _, cdID in ipairs(toRemove) do
                    -- Clear from grid
                    local member = self.members[cdID]
                    if member and self.grid[member.row] then
                        self.grid[member.row][member.col] = nil
                    end
                    self.members[cdID] = nil
                end
                
                if self.autoReflow then
                    self._reflowing = false  -- Reset flag
                    self:ReflowIcons()
                    return  -- ReflowIcons handles positioning
                end
            end
        end  -- end of if not skipValidation
        
        -- MEMBER_RESTORED: Rate-limited savedPositions scanning (once per second)
        -- Restores icons that return after talent changes
        local now = GetTime()
        if not self._lastSavedPosCheck or (now - self._lastSavedPosCheck) > 1.0 then
            self._lastSavedPosCheck = now
            
            -- Scan savedPositions for orphaned group icons belonging to this group
            for cdID, saved in pairs(ns.CDMGroups.savedPositions) do
                if saved.type == "group" and saved.target == self.name and not self.members[cdID] then
                    -- This savedPosition belongs to us but has no active member
                    -- Search CDM viewers for a frame with this cooldownID
                    local foundFrame = nil
                    local foundViewerType = nil
                    local foundViewerName = nil
                    
                    for _, viewerInfo in ipairs(CDM_VIEWERS) do
                        -- Skip bar viewers - we only manage icon viewers
                        if not viewerInfo.skipInGroups then
                            local viewer = _G[viewerInfo.name]
                            if viewer then
                                local ok, children = pcall(function() return { viewer:GetChildren() } end)
                                if ok and children then
                                    for _, child in ipairs(children) do
                                        local childOk, childCdID = pcall(function() return child.cooldownID end)
                                        if childOk and childCdID == cdID then
                                            -- Check frame not already used by another group
                                            local alreadyUsed = false
                                            for otherGroupName, otherGroup in pairs(ns.CDMGroups.groups) do
                                                if otherGroup.members then
                                                    for otherCdID, otherMember in pairs(otherGroup.members) do
                                                        if otherMember.frame == child then
                                                            alreadyUsed = true
                                                            break
                                                        end
                                                    end
                                                end
                                                if alreadyUsed then break end
                                            end
                                            
                                            if not alreadyUsed then
                                                foundFrame = child
                                                foundViewerType = viewerInfo.type
                                                foundViewerName = viewerInfo.name
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if foundFrame then break end
                    end
                    
                    -- ═══════════════════════════════════════════════════════════════
                    -- ALSO search Arc Auras frames (they're not in CDM viewers)
                    -- Arc Auras frames have cooldownID set to their arcID (string)
                    -- ═══════════════════════════════════════════════════════════════
                    if not foundFrame and ns.ArcAuras and ns.ArcAuras.frames then
                        local arcFrame = ns.ArcAuras.frames[cdID]
                        if arcFrame and arcFrame.cooldownID == cdID then
                            -- Check frame not already used by another group
                            local alreadyUsed = false
                            for otherGroupName, otherGroup in pairs(ns.CDMGroups.groups) do
                                if otherGroup.members then
                                    for otherCdID, otherMember in pairs(otherGroup.members) do
                                        if otherMember.frame == arcFrame then
                                            alreadyUsed = true
                                            break
                                        end
                                    end
                                end
                                if alreadyUsed then break end
                            end
                            
                            if not alreadyUsed then
                                foundFrame = arcFrame
                                foundViewerType = "cooldown"
                                foundViewerName = "ArcAurasViewer"
                            end
                        end
                    end
                    
                    if foundFrame then
                        -- Restore this icon to its saved position
                        local row = saved.row or 0
                        local col = saved.col or 0
                        local savedSortIndex = saved.sortIndex
                        
                        -- Ensure row/col are within grid bounds
                        if row >= self.layout.gridRows then row = self.layout.gridRows - 1 end
                        if col >= self.layout.gridCols then col = self.layout.gridCols - 1 end
                        
                        -- Check if slot is free
                        if not self.grid[row] then self.grid[row] = {} end
                        
                        local slotFree = not self.grid[row][col]
                        local targetRow, targetCol = row, col
                        
                        -- If slot is occupied, use Placeholders helper to displace the occupant
                        -- GUARD: Only for numeric IDs (Arc Auras use string IDs)
                        if not slotFree then
                            if type(cdID) == "number" and ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.DisplaceForReturningIcon then
                                local displaced = ns.CDMGroups.Placeholders.DisplaceForReturningIcon(self, row, col, cdID)
                                if not displaced then
                                    -- Couldn't displace, find any free slot
                                    local found = false
                                    for r = 0, self.layout.gridRows - 1 do
                                        for c = 0, self.layout.gridCols - 1 do
                                            if not self.grid[r] then self.grid[r] = {} end
                                            if not self.grid[r][c] then
                                                targetRow, targetCol = r, c
                                                found = true
                                                break
                                            end
                                        end
                                        if found then break end
                                    end
                                    if not found then
                                        targetRow, targetCol = nil, nil
                                    end
                                end
                            else
                                -- Fallback: find any free slot
                                local found = false
                                for r = 0, self.layout.gridRows - 1 do
                                    for c = 0, self.layout.gridCols - 1 do
                                        if not self.grid[r] then self.grid[r] = {} end
                                        if not self.grid[r][c] then
                                            targetRow, targetCol = r, c
                                            found = true
                                            break
                                        end
                                    end
                                    if found then break end
                                end
                                if not found then
                                    targetRow, targetCol = nil, nil
                                end
                            end
                        end
                        
                        if targetRow ~= nil and targetCol ~= nil then
                            -- Register in Registry
                            local entry = Registry:GetOrCreate(foundFrame, foundViewerName)
                            entry.originalParent = entry.originalParent or foundFrame:GetParent()
                            
                            -- Clear any free icon flag
                            foundFrame._cdmgIsFreeIcon = nil
                            
                            -- Create member entry
                            self.members[cdID] = {
                                frame = foundFrame,
                                entry = entry,
                                row = targetRow,
                                col = targetCol,
                                viewerType = foundViewerType,
                                defaultGroup = self.name,
                                originalViewerName = foundViewerName,
                            }
                            self.grid[targetRow][targetCol] = cdID
                            
                            -- Mark entry as manipulated
                            entry.manipulated = true
                            entry.group = self
                            
                            -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
                            foundFrame._cdmgTargetX = nil
                            foundFrame._cdmgTargetY = nil
                            foundFrame._cdmgTargetPoint = nil
                            foundFrame._cdmgTargetRelPoint = nil
                            
                            -- Setup frame in container
                            local effectiveW, effectiveH = SetupFrameInContainer(foundFrame, self.container, slotW, slotH, cdID)
                            
                            -- Update effective dimensions
                            self.members[cdID]._effectiveIconW = effectiveW
                            self.members[cdID]._effectiveIconH = effectiveH
                            
                            -- CRITICAL: MUST show frame after recovery
                            -- EXCEPT: Skip if frame is hidden due to hideWhenUnequipped setting
                            if not foundFrame._arcHiddenUnequipped then
                                foundFrame:SetAlpha(1)
                                foundFrame:Show()
                            end
                            foundFrame._arcRecoveryProtection = GetTime() + 0.5
                            
                            -- Enable drag if dragging is allowed
                            if ns.CDMGroups.ShouldAllowDrag() then
                                self:SetupMemberDrag(cdID)
                                foundFrame:EnableMouse(true)
                                if foundFrame.SetMouseClickThrough then
                                    foundFrame:SetMouseClickThrough(false)
                                end
                            end
                            
                            -- Update saved position with new row/col but preserve sortIndex
                            -- This ensures next reflow puts it in the right order
                            if not IsRestoring() then
                                SaveGroupPosition(cdID, self.name, targetRow, targetCol, false, savedSortIndex)
                            end
                            
                            -- If we had to move to a different slot and autoReflow is on, 
                            -- schedule a reflow to put things in proper sortIndex order
                            if self.autoReflow and (targetRow ~= row or targetCol ~= col) then
                                -- Delay reflow to let all icons restore first
                                if not self._pendingReflow then
                                    self._pendingReflow = true
                                    C_Timer.After(0.5, function()
                                        self._pendingReflow = false
                                        if not IsRestoring() then
                                            self:ReflowIcons()
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Calculate maximum effective icon size and track edge overflows
        -- ALWAYS calculate from CDMEnhance settings - don't rely on frame size
        -- (frame size may not be updated yet or may have been reset by CDM)
        -- INCLUDE placeholder members (isPlaceholder = true) for proper spacing
        local maxEffectiveSize = math.max(slotW, slotH)
        local leftOverflow = 0   -- Extra space needed on left edge
        local rightOverflow = 0  -- Extra space needed on right edge  
        local topOverflow = 0    -- Extra space needed on top edge
        local bottomOverflow = 0 -- Extra space needed on bottom edge
        local maxSlotOverflowX = 0  -- Max overflow any icon has horizontally (for spacing)
        local maxSlotOverflowY = 0  -- Max overflow any icon has vertically (for spacing)
        
        for cdID, member in pairs(self.members) do
            -- Include BOTH real frames AND placeholders in overflow calculations
            if member and member.row ~= nil and member.col ~= nil and (member.frame or member.isPlaceholder) then
                -- Calculate effective size from CDMEnhance settings
                local effectiveW = slotW
                local effectiveH = slotH
                
                -- For placeholders, use pre-calculated effective size if available
                if member.isPlaceholder and member._effectiveIconW then
                    effectiveW = member._effectiveIconW
                    effectiveH = member._effectiveIconH or effectiveW
                elseif ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                    local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cdID)
                    -- ONLY apply custom size when useGroupScale is explicitly OFF
                    if cfg and cfg.useGroupScale == false then
                        -- Per-icon override: use width/height from config
                        local baseW = cfg.width or slotW
                        local baseH = cfg.height or slotH
                        local scale = cfg.scale or 1.0
                        effectiveW = baseW * scale
                        effectiveH = baseH * scale
                    end
                    -- When useGroupScale is true (default), use group's slot dimensions (already set)
                end
                
                -- Store both dimensions for later use
                member._effectiveIconW = effectiveW
                member._effectiveIconH = effectiveH
                member._effectiveIconSize = math.max(effectiveW, effectiveH)
                if member._effectiveIconSize > maxEffectiveSize then
                    maxEffectiveSize = member._effectiveIconSize
                end
                
                -- Calculate how much this icon overflows its slot on each side
                local slotOverflowX = math.max(0, (effectiveW - slotW) / 2)
                local slotOverflowY = math.max(0, (effectiveH - slotH) / 2)
                
                -- Track maximum overflow for spacing adjustment
                if slotOverflowX > maxSlotOverflowX then
                    maxSlotOverflowX = slotOverflowX
                end
                if slotOverflowY > maxSlotOverflowY then
                    maxSlotOverflowY = slotOverflowY
                end
                
                -- Check if this icon is at an edge and needs extra container space
                local isVisualLeftEdge = (member.col == 0)
                local isVisualRightEdge = (member.col == cols - 1)
                local isVisualTopEdge = (member.row == 0)
                local isVisualBottomEdge = (member.row == rows - 1)
                
                if isVisualLeftEdge then
                    leftOverflow = math.max(leftOverflow, slotOverflowX)
                end
                if isVisualRightEdge then
                    rightOverflow = math.max(rightOverflow, slotOverflowX)
                end
                if isVisualTopEdge then
                    topOverflow = math.max(topOverflow, slotOverflowY)
                end
                if isVisualBottomEdge then
                    bottomOverflow = math.max(bottomOverflow, slotOverflowY)
                end
            end
        end
        
        -- Add extra margin to overflows for visual breathing room (borders, glows extend beyond frame)
        local overflowMargin = 4
        local effectiveLeftOverflow = leftOverflow > 0 and (leftOverflow + overflowMargin) or 0
        local effectiveRightOverflow = rightOverflow > 0 and (rightOverflow + overflowMargin) or 0
        local effectiveTopOverflow = topOverflow > 0 and (topOverflow + overflowMargin) or 0
        local effectiveBottomOverflow = bottomOverflow > 0 and (bottomOverflow + overflowMargin) or 0
        
        -- Store edge overflows for positioning calculations (use effective values)
        self._leftOverflow = effectiveLeftOverflow
        self._topOverflow = effectiveTopOverflow
        
        -- Store per-column and per-row max effective sizes for cascade positioning
        -- This allows oversized icons to push only their neighbors by the correct amount
        self._colMaxEffectiveW = {}  -- Max effective width in each column
        self._rowMaxEffectiveH = {}  -- Max effective height in each row
        
        for cdID, member in pairs(self.members) do
            if member and member.row ~= nil and member.col ~= nil then
                local effectiveW = member._effectiveIconW or slotW
                local effectiveH = member._effectiveIconH or slotH
                
                -- Track max effective size per column/row
                self._colMaxEffectiveW[member.col] = math.max(self._colMaxEffectiveW[member.col] or slotW, effectiveW)
                self._rowMaxEffectiveH[member.row] = math.max(self._rowMaxEffectiveH[member.row] or slotH, effectiveH)
            end
        end
        
        -- Calculate cumulative offsets for cascade positioning
        -- Formula: extra = (iconN_halfWidth + iconN+1_halfWidth) - slotW
        -- The spacing is already built into slot positions, so we don't subtract it here
        -- This ensures icons maintain the user's spacing setting between their EDGES
        self._colCumulativeOffset = {}
        self._rowCumulativeOffset = {}
        
        -- Column offsets: leftmost column (0) is processed first, pushes rightward
        local cumulative = 0
        for c = 0, cols - 1 do
            self._colCumulativeOffset[c] = cumulative
            if c < cols - 1 then
                local thisColHalfW = (self._colMaxEffectiveW[c] or slotW) / 2
                local nextColHalfW = (self._colMaxEffectiveW[c + 1] or slotW) / 2
                local extra = thisColHalfW + nextColHalfW - slotW
                cumulative = cumulative + math.max(0, extra)
            end
        end
        
        -- Row offsets: topmost row (0) is processed first, pushes downward
        cumulative = 0
        for r = 0, rows - 1 do
            self._rowCumulativeOffset[r] = cumulative
            if r < rows - 1 then
                local thisRowHalfH = (self._rowMaxEffectiveH[r] or slotH) / 2
                local nextRowHalfH = (self._rowMaxEffectiveH[r + 1] or slotH) / 2
                local extra = thisRowHalfH + nextRowHalfH - slotH
                cumulative = cumulative + math.max(0, extra)
            end
        end
        
        -- Total extra width/height needed is the final cumulative value
        local totalExtraWidth = 0
        local totalExtraHeight = 0
        for c = 0, cols - 1 do
            if self._colCumulativeOffset[c] and self._colCumulativeOffset[c] > totalExtraWidth then
                totalExtraWidth = self._colCumulativeOffset[c]
            end
        end
        for r = 0, rows - 1 do
            if self._rowCumulativeOffset[r] and self._rowCumulativeOffset[r] > totalExtraHeight then
                totalExtraHeight = self._rowCumulativeOffset[r]
            end
        end
        
        -- Calculate container size based on slot dimensions
        -- Add edge-specific overflows to accommodate oversized icons at borders
        -- containerPadding controls extra space around icons (0 = compact, 4 = classic with border room)
        local totalPadding = (self.containerPadding or 0) * 2
        local borderCompensation = 12  -- Space for backdrop border + visual padding (borderOffset 4 on each side)
        
        local baseWidth = cols * slotW + (cols - 1) * spacingX + totalPadding + borderCompensation + totalExtraWidth
        local baseHeight = rows * slotH + (rows - 1) * spacingY + totalPadding + borderCompensation + totalExtraHeight
        local width = baseWidth + effectiveLeftOverflow + effectiveRightOverflow
        local height = baseHeight + effectiveTopOverflow + effectiveBottomOverflow
        local targetW = math.max(slotW, width)  -- Minimum size is one slot
        local targetH = math.max(slotH, height)
        local currentW, currentH = self.container:GetSize()
        
        
        if math.abs((currentW or 0) - targetW) > 0.5 or math.abs((currentH or 0) - targetH) > 0.5 then
            self.container:SetSize(targetW, targetH)
        end
        
        -- Position icons
        -- PIXEL POSITIONING: Compute pixel positions when Dynamic Layout (autoReflow) is ON and panel closed
        -- excludeInactiveAuras: only when Dynamic Auras toggle is ON
        local DL = ns.CDMGroups.DynamicLayout
        local optionsPanelOpen = ns.CDMGroups.IsOptionsPanelOpen and ns.CDMGroups.IsOptionsPanelOpen()
        local usePixelLayout = self.autoReflow and not optionsPanelOpen
        local excludeInactiveAuras = self.dynamicLayout and usePixelLayout
        
        -- Calculate pixel positions for all active items
        -- CalculateDynamicSlots handles the panel-open check internally
        local dynamicPositions = {}  -- [cdID] = {row=, col=} (for tracking)
        local activeAuras = {}       -- [cdID] = true (items in pixel layout)
        if usePixelLayout and DL and DL.CalculateDynamicSlots then
            dynamicPositions, activeAuras = DL.CalculateDynamicSlots(self, rows, cols, excludeInactiveAuras)
        end
        
        
        -- Track occupied positions to prevent two frames from sharing the same spot
        local occupiedPositions = {}  -- ["row,col"] = cdID
        
        -- Build processing order: active items first, then inactive auras
        local usePixelPositioning = self._usePixelPositioning and true or false
        local processingOrder = (DL and DL.BuildProcessingOrder) 
            and DL.BuildProcessingOrder(self, activeAuras, usePixelPositioning)
            or {}
        
        -- Fallback if DL not available
        if #processingOrder == 0 then
            for cdID, member in pairs(self.members) do
                if member and member.frame and member.row ~= nil and member.col ~= nil then
                    table.insert(processingOrder, cdID)
                end
            end
        end
        
        -- Get alignment for collision handler
        local alignment = self.layout and self.layout.alignment or "left"
        
        for _, cdID in ipairs(processingOrder) do
            local member = self.members[cdID]
            if member and member.frame and member.row ~= nil and member.col ~= nil then
                local frame = member.frame
                
                -- Get position (pixel-positioned items use dynamicPositions for tracking)
                local row, col, usesDynamicPosition
                if DL and DL.GetMemberPosition then
                    row, col, usesDynamicPosition = DL.GetMemberPosition(member, cdID, activeAuras, dynamicPositions, usePixelPositioning)
                else
                    row, col = member.row, member.col
                    usesDynamicPosition = false
                end
                
                -- COLLISION CHECK: Ensure this position isn't already occupied
                local posKey = row .. "," .. col
                if occupiedPositions[posKey] then
                    -- Position already taken! Find next available (respects alignment)
                    local newRow, newCol, newKey
                    if DL and DL.FindAvailableSlot then
                        newRow, newCol, newKey = DL.FindAvailableSlot(occupiedPositions, rows, cols, alignment)
                    end
                    
                    if newRow then
                        row, col, posKey = newRow, newCol, newKey
                        -- Update dynamic slot if this was a dynamic aura
                        if usesDynamicPosition then
                            member._dynamicSlot = row * cols + col
                        end
                    end
                end
                occupiedPositions[posKey] = cdID
                
                -- CRITICAL: Update member.row/col to match actual rendered position
                -- This keeps member state in sync with visual layout
                -- savedPositions remain unchanged (authoritative for user's intended layout)
                member.row = row
                member.col = col
                
                -- Backfill viewerType if missing using CDM category
                if not member.viewerType then
                    local viewerType, defaultGroup = Shared.GetViewerTypeFromCooldownID(cdID)
                    if viewerType then
                        member.viewerType = viewerType
                        member.defaultGroup = defaultGroup
                    end
                end
                
                -- Fight CDM - but only change properties if they're wrong
                -- Track fights for debugging
                
                -- Fight parent
                local currentParent = frame:GetParent()
                if currentParent ~= self.container then
                    ns.CDMGroups.fightStats.parent = ns.CDMGroups.fightStats.parent + 1
                    frame:SetParent(self.container)
                    
                    -- CRITICAL (Bug #5): Pool_HideAndClearAnchors clears BOTH parent AND anchors
                    -- When parent is wrong, we must also reapply position immediately
                    local effectiveW = member._effectiveIconW or slotW
                    local effectiveH = member._effectiveIconH or slotH
                    
                    frame._cdmgSettingPosition = true
                    frame:ClearAllPoints()
                    
                    -- Use pixel-based positioning if active
                    if self._usePixelPositioning and self._pixelOffsets and self._pixelOffsets[cdID] then
                        local offset = self._pixelOffsets[cdID]
                        frame:SetPoint("CENTER", self.container, "CENTER", offset.x, offset.y)
                    else
                        -- Grid-based positioning
                        local slotX, slotY = getSlotPosition(row, col, self._leftOverflow, self._topOverflow)
                        local offsetX = (slotW - effectiveW) / 2
                        local offsetY = -(slotH - effectiveH) / 2
                        local targetX = slotX + offsetX
                        local targetY = slotY + offsetY
                        frame:SetPoint("TOPLEFT", self.container, "TOPLEFT", targetX, targetY)
                    end
                    
                    frame._cdmgSettingPosition = false
                    frame._cdmgSettingSize = true
                    frame:SetSize(effectiveW, effectiveH)
                    frame._cdmgSettingSize = false
                    
                    -- Only show if not hidden due to hideWhenUnequipped setting
                    if not frame._arcHiddenUnequipped and not IsFrameHiddenByBar(frame) then
                        frame:SetAlpha(1)
                        frame:Show()
                    end
                    
                    -- Refresh drag handlers if dragging is allowed
                    if ns.CDMGroups.ShouldAllowDrag() then
                        self:SetupMemberDrag(cdID)
                    end
                    
                    -- Set recovery protection (500ms window prevents immediate hide)
                    frame._arcRecoveryProtection = GetTime() + 0.5
                end
                
                -- Fight strata
                local currentStrata = frame:GetFrameStrata()
                if currentStrata ~= "MEDIUM" then
                    ns.CDMGroups.fightStats.strata = ns.CDMGroups.fightStats.strata + 1
                    frame:SetFrameStrata("MEDIUM")
                end
                
                -- Fight scale - force to 1 always
                local currentScale = frame:GetScale() or 1
                if math.abs(currentScale - 1) > 0.01 then
                    ns.CDMGroups.fightStats.scale = ns.CDMGroups.fightStats.scale + 1
                    frame._cdmgSettingScale = true
                    frame:SetScale(1)
                    frame._cdmgSettingScale = false
                end
                
                -- Use pre-calculated effective size (set during maxEffectiveSize calculation above)
                local effectiveW = member._effectiveIconW or slotW
                local effectiveH = member._effectiveIconH or slotH
                
                -- Fight size - force to target always
                local w, h = frame:GetSize()
                w = w or 0
                h = h or 0
                
                if math.abs(w - effectiveW) > 0.5 or math.abs(h - effectiveH) > 0.5 then
                    ns.CDMGroups.fightStats.size = ns.CDMGroups.fightStats.size + 1
                    frame._cdmgSettingSize = true
                    frame:SetSize(effectiveW, effectiveH)
                    frame._cdmgSettingSize = false
                end
                
                -- NOTE: Visual state (desat, alpha, glow) is handled by GroupIconStateMaintainer at 20Hz
                -- No need to call ApplyIconVisuals here - it would be redundant
                
                -- Only reposition if not dragging AND position actually changed
                if not frame._groupDragging then
                    local targetX, targetY
                    local targetPoint, targetRelPoint = "TOPLEFT", "TOPLEFT"
                    
                    -- ═══════════════════════════════════════════════════════════════════════
                    -- PIXEL-BASED POSITIONING
                    -- Positions icons using CENTER anchor with pixel offsets
                    -- Active for ALL groups when options panel is closed
                    -- ═══════════════════════════════════════════════════════════════════════
                    if self._usePixelPositioning and self._pixelOffsets and self._pixelOffsets[cdID] then
                        -- Position from CENTER of container using stored pixel offset
                        local offset = self._pixelOffsets[cdID]
                        local effectiveW = member._effectiveIconW or slotW
                        local effectiveH = member._effectiveIconH or slotH
                        
                        targetX = offset.x
                        targetY = offset.y
                        
                        targetPoint = "CENTER"
                        targetRelPoint = "CENTER"
                        
                        -- Store target for hooks
                        frame._cdmgTargetPoint = targetPoint
                        frame._cdmgTargetRelPoint = targetRelPoint
                        frame._cdmgTargetX = targetX
                        frame._cdmgTargetY = targetY
                        frame._cdmgTargetSize = math.max(effectiveW, effectiveH)
                        frame._cdmgSlotW = slotW
                        frame._cdmgSlotH = slotH
                        ns.CDMGroups.HookFrame(frame, math.max(effectiveW, effectiveH))
                        
                        -- Check if already at correct position
                        local needsReposition = false
                        local point, relativeTo, relativePoint, currentX, currentY = frame:GetPoint(1)
                        
                        if not point or relativeTo ~= self.container or relativePoint ~= "CENTER" or point ~= "CENTER" then
                            needsReposition = true
                        elseif currentX == nil or currentY == nil then
                            needsReposition = true
                        elseif math.abs(currentX - targetX) > 0.5 or math.abs(currentY - targetY) > 0.5 then
                            needsReposition = true
                        end
                        
                        if needsReposition then
                            ns.CDMGroups.fightStats.position = ns.CDMGroups.fightStats.position + 1
                            frame._cdmgSettingPosition = true
                            frame:ClearAllPoints()
                            frame:SetPoint("CENTER", self.container, "CENTER", targetX, targetY)
                            frame._cdmgSettingPosition = false
                            -- TRACE: Log position set
                            if ns.DynamicLayoutDebug and ns.DynamicLayoutDebug.IsAlphaTraceEnabled and ns.DynamicLayoutDebug.IsAlphaTraceEnabled() then
                                ns.DynamicLayoutDebug.AddAlphaTrace("SETPOINT_CENTER", cdID, string.format("x=%.1f y=%.1f", targetX, targetY))
                            end
                        end
                        
                        -- Clear alpha delay flag now that frame is positioned correctly
                        -- and immediately show the frame (bypass throttle)
                        if frame._arcDelayAlphaUntil then
                            -- TRACE: Log delay cleared
                            if ns.DynamicLayoutDebug and ns.DynamicLayoutDebug.IsAlphaTraceEnabled and ns.DynamicLayoutDebug.IsAlphaTraceEnabled() then
                                ns.DynamicLayoutDebug.AddAlphaTrace("DELAY_FLAG_CLEARED", cdID, "calling OptimizedApplyIconVisuals")
                            end
                            frame._arcDelayAlphaUntil = nil
                            frame._arcTargetAlpha = nil  -- Clear cached alpha so next call sets it
                            -- Trigger OptimizedApplyIconVisuals to show frame immediately
                            if ns.CDMEnhance and ns.CDMEnhance.OptimizedApplyIconVisuals then
                                frame._arcLastOptimizedCall = 0  -- Bypass throttle
                                ns.CDMEnhance.OptimizedApplyIconVisuals(frame)
                            end
                        end
                    else
                        -- ═══════════════════════════════════════════════════════════════════════
                        -- GRID-BASED POSITIONING (default)
                        -- ═══════════════════════════════════════════════════════════════════════
                        -- Base slot position (use slot dimensions for grid, larger icons can overflow)
                        -- Add leftOverflow/topOverflow to shift grid right/down when there are oversized edge icons
                        local slotX, slotY = getSlotPosition(row, col, self._leftOverflow, self._topOverflow)
                        
                        -- Center the icon within the slot
                        local effectiveW = member._effectiveIconW or slotW
                        local effectiveH = member._effectiveIconH or slotH
                        local offsetX = (slotW - effectiveW) / 2
                        local offsetY = -(slotH - effectiveH) / 2  -- Negative because Y goes down
                        
                        targetX = slotX + offsetX
                        targetY = slotY + offsetY
                        
                        -- Store target for hooks (always update)
                        frame._cdmgTargetPoint = "TOPLEFT"
                        frame._cdmgTargetRelPoint = "TOPLEFT"
                        frame._cdmgTargetX = targetX
                        frame._cdmgTargetY = targetY
                        frame._cdmgTargetSize = math.max(effectiveW, effectiveH)  -- For hook compatibility
                        frame._cdmgSlotW = slotW  -- Store GROUP's slot dimensions for useGroupScale
                        frame._cdmgSlotH = slotH
                        ns.CDMGroups.HookFrame(frame, math.max(effectiveW, effectiveH))
                        
                        -- Check if already at correct position (avoid unnecessary SetPoint calls)
                        local needsReposition = false
                        local point, relativeTo, relativePoint, currentX, currentY = frame:GetPoint(1)
                        
                        if not point or relativeTo ~= self.container or relativePoint ~= "TOPLEFT" or point ~= "TOPLEFT" then
                            needsReposition = true
                        elseif currentX == nil or currentY == nil then
                            needsReposition = true
                        elseif math.abs(currentX - targetX) > 0.5 or math.abs(currentY - targetY) > 0.5 then
                            needsReposition = true
                        end
                        
                        if needsReposition then
                            ns.CDMGroups.fightStats.position = ns.CDMGroups.fightStats.position + 1
                            frame._cdmgSettingPosition = true
                            frame:ClearAllPoints()
                            frame:SetPoint("TOPLEFT", self.container, "TOPLEFT", targetX, targetY)
                            frame._cdmgSettingPosition = false
                        end
                    end
                end
                
                -- CRITICAL: Ensure drag handlers are always set up when dragging is allowed
                -- CDM can recycle frames and clear our scripts, so verify on every layout pass
                if ns.CDMGroups.ShouldAllowDrag() then
                    local hasDragHandler = frame:GetScript("OnDragStart") ~= nil
                    if not hasDragHandler then
                        self:SetupMemberDrag(cdID)
                        frame:EnableMouse(true)
                    end
                end
            end
        end
        
        -- ═══════════════════════════════════════════════════════════════════════
        -- GRID SYNC: Rebuild grid to match actual visual positions
        -- When pixel positioning is active, sync grid from dynamicPositions
        -- This ensures grid reflects where icons actually ARE
        -- ═══════════════════════════════════════════════════════════════════════
        if usePixelPositioning then
            -- Clear grid
            self.grid = {}
            for r = 0, rows - 1 do
                self.grid[r] = {}
            end
            
            -- Rebuild from occupiedPositions (reflects actual visual layout)
            for posKey, cdID in pairs(occupiedPositions) do
                local r, c = posKey:match("(%d+),(%d+)")
                r, c = tonumber(r), tonumber(c)
                if r and c and r < rows and c < cols then
                    self.grid[r][c] = cdID
                end
            end
        end
        
        -- Position placeholder frames (only when editing)
        -- This is handled AFTER real frames so placeholders use consistent positioning
        if ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.IsEditingMode and ns.CDMGroups.Placeholders.IsEditingMode() then
            ns.CDMGroups.Placeholders.PositionPlaceholdersInGroup(self.name, self, getSlotPosition, slotW, slotH, spacingX, spacingY)
        end
    end
    
    function group:SetIconSize(size)
        self.layout.iconSize = size
        local db = getDB()
        if db then db.iconSize = size end
        -- Recalculate effective slot dimensions
        local slotW, slotH = GetSlotDimensions(self.layout)
        for cdID, member in pairs(self.members) do
            if member.frame then
                -- Check if this icon has custom scale (useGroupScale == false)
                local effectiveW = slotW
                local effectiveH = slotH
                if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                    local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cdID)
                    if cfg and cfg.useGroupScale == false then
                        local baseW = cfg.width or slotW
                        local baseH = cfg.height or slotH
                        local iconScale = cfg.scale or 1.0
                        effectiveW = baseW * iconScale
                        effectiveH = baseH * iconScale
                    end
                end
                member.frame._cdmgTargetSize = math.max(effectiveW, effectiveH)
                member.frame._cdmgSlotW = slotW  -- Store GROUP's slot dimensions
                member.frame._cdmgSlotH = slotH
                member._effectiveIconW = effectiveW
                member._effectiveIconH = effectiveH
                member.frame._cdmgSettingSize = true
                member.frame:SetSize(effectiveW, effectiveH)
                member.frame._cdmgSettingSize = false
            end
        end
        self:Layout()
        
        -- Trigger Masque refresh so skins update to new frame sizes
        if ns.Masque and ns.Masque.QueueRefresh then
            ns.Masque.QueueRefresh()
        end
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
    end
    
    function group:SetIconWidth(width)
        self.layout.iconWidth = width
        local db = getDB()
        if db then db.iconWidth = width end
        -- Recalculate effective slot dimensions
        local slotW, slotH = GetSlotDimensions(self.layout)
        for cdID, member in pairs(self.members) do
            if member.frame then
                -- Check if this icon has custom scale (useGroupScale == false)
                local effectiveW = slotW
                local effectiveH = slotH
                if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                    local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cdID)
                    if cfg and cfg.useGroupScale == false then
                        local baseW = cfg.width or slotW
                        local baseH = cfg.height or slotH
                        local iconScale = cfg.scale or 1.0
                        effectiveW = baseW * iconScale
                        effectiveH = baseH * iconScale
                    end
                end
                member.frame._cdmgTargetSize = math.max(effectiveW, effectiveH)
                member.frame._cdmgSlotW = slotW  -- Store GROUP's slot dimensions
                member.frame._cdmgSlotH = slotH
                member._effectiveIconW = effectiveW
                member._effectiveIconH = effectiveH
                member.frame._cdmgSettingSize = true
                member.frame:SetSize(effectiveW, effectiveH)
                member.frame._cdmgSettingSize = false
            end
        end
        self:Layout()
        
        -- Trigger Masque refresh so skins update to new frame sizes
        if ns.Masque and ns.Masque.QueueRefresh then
            ns.Masque.QueueRefresh()
        end
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
    end
    
    function group:SetIconHeight(height)
        self.layout.iconHeight = height
        local db = getDB()
        if db then db.iconHeight = height end
        -- Recalculate effective slot dimensions
        local slotW, slotH = GetSlotDimensions(self.layout)
        for cdID, member in pairs(self.members) do
            if member.frame then
                -- Check if this icon has custom scale (useGroupScale == false)
                local effectiveW = slotW
                local effectiveH = slotH
                if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                    local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cdID)
                    if cfg and cfg.useGroupScale == false then
                        local baseW = cfg.width or slotW
                        local baseH = cfg.height or slotH
                        local iconScale = cfg.scale or 1.0
                        effectiveW = baseW * iconScale
                        effectiveH = baseH * iconScale
                    end
                end
                member.frame._cdmgTargetSize = math.max(effectiveW, effectiveH)
                member.frame._cdmgSlotW = slotW  -- Store GROUP's slot dimensions
                member.frame._cdmgSlotH = slotH
                member._effectiveIconW = effectiveW
                member._effectiveIconH = effectiveH
                member.frame._cdmgSettingSize = true
                member.frame:SetSize(effectiveW, effectiveH)
                member.frame._cdmgSettingSize = false
            end
        end
        self:Layout()
        
        -- Trigger Masque refresh so skins update to new frame sizes
        if ns.Masque and ns.Masque.QueueRefresh then
            ns.Masque.QueueRefresh()
        end
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
    end
    
    function group:SetSpacing(sp)
        self.layout.spacing = sp
        -- Also clear X/Y overrides so the base spacing applies
        self.layout.spacingX = nil
        self.layout.spacingY = nil
        local db = getDB()
        if db then 
            db.spacing = sp
            db.spacingX = nil
            db.spacingY = nil
        end
        self:Layout()
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
    end
    
    function group:SetSpacingX(sp)
        self.layout.spacingX = sp
        local db = getDB()
        if db then db.spacingX = sp end
        self:Layout()
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
    end
    
    function group:SetSpacingY(sp)
        self.layout.spacingY = sp
        local db = getDB()
        if db then db.spacingY = sp end
        self:Layout()
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
    end
    
    function group:SetGridSize(rows, cols)
        local oldRows = self.layout.gridRows
        local oldCols = self.layout.gridCols
        
        -- Get growth direction settings
        local horizontalGrowth = self.layout.horizontalGrowth or "RIGHT"
        local verticalGrowth = self.layout.verticalGrowth or "DOWN"
        
        -- Calculate how many rows/cols are being added/removed
        local colDelta = cols - oldCols
        local rowDelta = rows - oldRows
        
        -- Calculate slot dimensions for position offset
        local slotW, slotH = GetSlotDimensions(self.layout)
        local spacingX = self.layout.spacingX or self.layout.spacing or 2
        local spacingY = self.layout.spacingY or self.layout.spacing or 2
        
        -- Update layout dimensions
        self.layout.gridRows = rows
        self.layout.gridCols = cols
        local db = getDB()
        if db then
            db.gridRows = rows
            db.gridCols = cols
        end
        
        -- Compensate container position for growth direction
        -- Container is CENTER anchored, so when it grows, it expands equally in both directions
        -- We need to offset position so it appears to grow only in the specified direction
        local posOffsetX = 0
        local posOffsetY = 0
        
        if colDelta ~= 0 then
            local widthChange = colDelta * (slotW + spacingX)
            if horizontalGrowth == "LEFT" then
                -- Growing LEFT: shift container LEFT so RIGHT edge stays fixed
                posOffsetX = -widthChange / 2
            else -- RIGHT (default)
                -- Growing RIGHT: shift container RIGHT so LEFT edge stays fixed
                posOffsetX = widthChange / 2
            end
        end
        
        if rowDelta ~= 0 then
            local heightChange = rowDelta * (slotH + spacingY)
            if verticalGrowth == "UP" then
                -- Growing UP: shift container UP so BOTTOM edge stays fixed
                posOffsetY = heightChange / 2
            else -- DOWN (default)
                -- Growing DOWN: shift container DOWN so TOP edge stays fixed
                posOffsetY = -heightChange / 2
            end
        end
        
        -- Apply position offset if needed
        if posOffsetX ~= 0 or posOffsetY ~= 0 then
            self.position.x = self.position.x + posOffsetX
            self.position.y = self.position.y + posOffsetY
            if db then
                db.position = db.position or {}
                db.position.x = self.position.x
                db.position.y = self.position.y
            end
            -- Update container position
            self.container:ClearAllPoints()
            self.container:SetPoint("CENTER", UIParent, "CENTER", self.position.x, self.position.y)
        end
        
        -- NOTE: Grid size changes do NOT trigger reflow
        -- This prevents icons from shifting unexpectedly when adding rows/cols
        -- Reflow only triggers on:
        --   1. Icon removal (to fill gaps)
        --   2. Alignment change (user explicitly wants repositioning)
        --   3. Drag operations that create gaps
        self:Layout()
        
        if self.UpdateControlButtonPositions then
            self.UpdateControlButtonPositions()
        end
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
    end
    
    -- Insert a new column at specified position, shifting existing columns right
    function group:InsertColumnAt(insertCol)
        local maxCols = self.layout.gridCols
        local maxRows = self.layout.gridRows
        local horizontalGrowth = self.layout.horizontalGrowth or "RIGHT"
        
        -- Calculate slot dimensions for position offset
        local slotW, slotH = GetSlotDimensions(self.layout)
        local spacingX = self.layout.spacingX or self.layout.spacing or 2
        
        -- Expand grid
        self.layout.gridCols = maxCols + 1
        local db = getDB()
        if db then db.gridCols = self.layout.gridCols end
        
        -- Compensate container position for growth direction
        local widthChange = slotW + spacingX
        local posOffsetX
        if horizontalGrowth == "LEFT" then
            posOffsetX = -widthChange / 2  -- Shift LEFT so RIGHT edge stays fixed
        else -- RIGHT (default)
            posOffsetX = widthChange / 2   -- Shift RIGHT so LEFT edge stays fixed
        end
        
        self.position.x = self.position.x + posOffsetX
        if db then
            db.position = db.position or {}
            db.position.x = self.position.x
        end
        self.container:ClearAllPoints()
        self.container:SetPoint("CENTER", UIParent, "CENTER", self.position.x, self.position.y)
        
        -- Shift all icons at or after insertCol one column to the right
        for row = 0, maxRows - 1 do
            if self.grid[row] then
                -- Work from right to left to avoid overwrites
                for col = maxCols - 1, insertCol, -1 do
                    local cdID = self.grid[row][col]
                    if cdID then
                        self.grid[row][col + 1] = cdID
                        self.grid[row][col] = nil
                        if self.members[cdID] then
                            self.members[cdID].col = col + 1
                            -- Update saved position
                            SaveGroupPosition(cdID, self.name, row, col + 1)
                        end
                    end
                end
            end
        end
        
        self:MarkGridDirty()
        self:Layout()
    end
    
    -- Add a column at the end of the grid
    function group:AddColumnAtEnd()
        local horizontalGrowth = self.layout.horizontalGrowth or "RIGHT"
        local slotW, slotH = GetSlotDimensions(self.layout)
        local spacingX = self.layout.spacingX or self.layout.spacing or 2
        
        self.layout.gridCols = self.layout.gridCols + 1
        local db = getDB()
        if db then db.gridCols = self.layout.gridCols end
        
        -- Compensate container position for growth direction
        local widthChange = slotW + spacingX
        local posOffsetX
        if horizontalGrowth == "LEFT" then
            posOffsetX = -widthChange / 2  -- Shift LEFT so RIGHT edge stays fixed
        else -- RIGHT (default)
            posOffsetX = widthChange / 2   -- Shift RIGHT so LEFT edge stays fixed
        end
        
        self.position.x = self.position.x + posOffsetX
        if db then
            db.position = db.position or {}
            db.position.x = self.position.x
        end
        self.container:ClearAllPoints()
        self.container:SetPoint("CENTER", UIParent, "CENTER", self.position.x, self.position.y)
        
        self:Layout()
    end
    
    -- Insert a row at the specified position, shifting rows at/below down
    function group:InsertRowAt(insertRow)
        local maxCols = self.layout.gridCols
        local maxRows = self.layout.gridRows
        local verticalGrowth = self.layout.verticalGrowth or "DOWN"
        
        -- Calculate slot dimensions for position offset
        local slotW, slotH = GetSlotDimensions(self.layout)
        local spacingY = self.layout.spacingY or self.layout.spacing or 2
        
        -- Expand grid
        self.layout.gridRows = maxRows + 1
        local db = getDB()
        if db then db.gridRows = self.layout.gridRows end
        
        -- Compensate container position for growth direction
        local heightChange = slotH + spacingY
        local posOffsetY
        if verticalGrowth == "UP" then
            posOffsetY = heightChange / 2   -- Shift UP so BOTTOM edge stays fixed
        else -- DOWN (default)
            posOffsetY = -heightChange / 2  -- Shift DOWN so TOP edge stays fixed
        end
        
        self.position.y = self.position.y + posOffsetY
        if db then
            db.position = db.position or {}
            db.position.y = self.position.y
        end
        self.container:ClearAllPoints()
        self.container:SetPoint("CENTER", UIParent, "CENTER", self.position.x, self.position.y)
        
        -- Shift all rows at or after insertRow one row down
        -- Work from bottom to top to avoid overwrites
        for row = maxRows - 1, insertRow, -1 do
            if self.grid[row] then
                -- Move entire row down
                self.grid[row + 1] = self.grid[row + 1] or {}
                for col = 0, maxCols - 1 do
                    local cdID = self.grid[row][col]
                    if cdID then
                        self.grid[row + 1][col] = cdID
                        self.grid[row][col] = nil
                        if self.members[cdID] then
                            self.members[cdID].row = row + 1
                            -- Update saved position
                            SaveGroupPosition(cdID, self.name, row + 1, col)
                        end
                    end
                end
            end
        end
        
        -- Ensure new row exists
        self.grid[insertRow] = self.grid[insertRow] or {}
        
        self:MarkGridDirty()
        self:Layout()
    end
    
    -- Add a row at the bottom of the grid
    function group:AddRowAtBottom()
        local verticalGrowth = self.layout.verticalGrowth or "DOWN"
        local slotW, slotH = GetSlotDimensions(self.layout)
        local spacingY = self.layout.spacingY or self.layout.spacing or 2
        
        self.layout.gridRows = self.layout.gridRows + 1
        local db = getDB()
        if db then db.gridRows = self.layout.gridRows end
        
        -- Compensate container position for growth direction
        local heightChange = slotH + spacingY
        local posOffsetY
        if verticalGrowth == "UP" then
            posOffsetY = heightChange / 2   -- Shift UP so BOTTOM edge stays fixed
        else -- DOWN (default)
            posOffsetY = -heightChange / 2  -- Shift DOWN so TOP edge stays fixed
        end
        
        self.position.y = self.position.y + posOffsetY
        if db then
            db.position = db.position or {}
            db.position.y = self.position.y
        end
        self.container:ClearAllPoints()
        self.container:SetPoint("CENTER", UIParent, "CENTER", self.position.x, self.position.y)
        
        self:Layout()
    end
    
    -- Remove a row at the specified position, shifting rows below up
    -- Icons in the removed row are shifted up to fill the gap
    function group:RemoveRowAt(removeRow)
        local maxCols = self.layout.gridCols
        local maxRows = self.layout.gridRows
        local verticalGrowth = self.layout.verticalGrowth or "DOWN"
        
        if maxRows <= 1 then return end  -- Can't have less than 1 row
        
        -- Calculate slot dimensions for position offset
        local slotW, slotH = GetSlotDimensions(self.layout)
        local spacingY = self.layout.spacingY or self.layout.spacing or 2
        
        -- First, handle any icons in the row being removed
        -- Move them to the nearest available slot or remove if no space
        if self.grid[removeRow] then
            for col = 0, maxCols - 1 do
                local cdID = self.grid[removeRow][col]
                if cdID then
                    -- Clear from removed row
                    self.grid[removeRow][col] = nil
                    -- Try to find a new spot for this icon
                    local member = self.members[cdID]
                    if member then
                        local foundSpot = false
                        -- Look for empty slot in remaining rows
                        for r = 0, maxRows - 2 do  -- -2 because we're removing a row
                            local actualRow = r >= removeRow and r + 1 or r
                            if self.grid[actualRow] then
                                for c = 0, maxCols - 1 do
                                    if not self.grid[actualRow][c] then
                                        -- Found empty spot - but we'll set position after shift
                                        member._pendingRow = r  -- Post-shift row
                                        member._pendingCol = c
                                        foundSpot = true
                                        break
                                    end
                                end
                            end
                            if foundSpot then break end
                        end
                        if not foundSpot then
                            -- No space - icon will be temporarily orphaned
                            member.row = nil
                            member.col = nil
                        end
                    end
                end
            end
        end
        
        -- Shift all rows below removeRow up by one
        for row = removeRow, maxRows - 2 do
            self.grid[row] = self.grid[row + 1] or {}
            -- Update member positions
            for col = 0, maxCols - 1 do
                local cdID = self.grid[row][col]
                if cdID and self.members[cdID] then
                    self.members[cdID].row = row
                    SaveGroupPosition(cdID, self.name, row, col)
                end
            end
        end
        
        -- Remove the last row (now empty)
        self.grid[maxRows - 1] = nil
        
        -- Place any pending icons
        for cdID, member in pairs(self.members) do
            if member._pendingRow then
                local r, c = member._pendingRow, member._pendingCol
                if not self.grid[r] then self.grid[r] = {} end
                self.grid[r][c] = cdID
                member.row = r
                member.col = c
                member._pendingRow = nil
                member._pendingCol = nil
                SaveGroupPosition(cdID, self.name, r, c)
            end
        end
        
        -- Shrink grid
        self.layout.gridRows = maxRows - 1
        local db = getDB()
        if db then db.gridRows = self.layout.gridRows end
        
        -- Compensate container position for growth direction (reverse of adding)
        local heightChange = slotH + spacingY
        local posOffsetY
        if verticalGrowth == "UP" then
            posOffsetY = -heightChange / 2  -- Shift DOWN (reverse of adding)
        else -- DOWN (default)
            posOffsetY = heightChange / 2   -- Shift UP (reverse of adding)
        end
        
        self.position.y = self.position.y + posOffsetY
        if db then
            db.position = db.position or {}
            db.position.y = self.position.y
        end
        self.container:ClearAllPoints()
        self.container:SetPoint("CENTER", UIParent, "CENTER", self.position.x, self.position.y)
        
        self:MarkGridDirty()
        self:Layout()
    end
    
    -- Remove a column at the specified position, shifting columns to the right left
    function group:RemoveColumnAt(removeCol)
        local maxCols = self.layout.gridCols
        local maxRows = self.layout.gridRows
        local horizontalGrowth = self.layout.horizontalGrowth or "RIGHT"
        
        if maxCols <= 1 then return end  -- Can't have less than 1 column
        
        -- Calculate slot dimensions for position offset
        local slotW, slotH = GetSlotDimensions(self.layout)
        local spacingX = self.layout.spacingX or self.layout.spacing or 2
        
        -- First, handle any icons in the column being removed
        for row = 0, maxRows - 1 do
            if self.grid[row] and self.grid[row][removeCol] then
                local cdID = self.grid[row][removeCol]
                self.grid[row][removeCol] = nil
                local member = self.members[cdID]
                if member then
                    local foundSpot = false
                    -- Look for empty slot in remaining columns
                    for c = 0, maxCols - 2 do  -- -2 because we're removing a col
                        local actualCol = c >= removeCol and c + 1 or c
                        if not self.grid[row][actualCol] then
                            member._pendingRow = row
                            member._pendingCol = c  -- Post-shift column
                            foundSpot = true
                            break
                        end
                    end
                    if not foundSpot then
                        -- Look in other rows
                        for r = 0, maxRows - 1 do
                            if r ~= row then
                                for c = 0, maxCols - 2 do
                                    local actualCol = c >= removeCol and c + 1 or c
                                    if not self.grid[r] or not self.grid[r][actualCol] then
                                        member._pendingRow = r
                                        member._pendingCol = c
                                        foundSpot = true
                                        break
                                    end
                                end
                            end
                            if foundSpot then break end
                        end
                    end
                    if not foundSpot then
                        member.row = nil
                        member.col = nil
                    end
                end
            end
        end
        
        -- Shift all columns to the right of removeCol left by one
        for row = 0, maxRows - 1 do
            if self.grid[row] then
                for col = removeCol, maxCols - 2 do
                    self.grid[row][col] = self.grid[row][col + 1]
                    local cdID = self.grid[row][col]
                    if cdID and self.members[cdID] then
                        self.members[cdID].col = col
                        SaveGroupPosition(cdID, self.name, row, col)
                    end
                end
                -- Clear the last column
                self.grid[row][maxCols - 1] = nil
            end
        end
        
        -- Place any pending icons
        for cdID, member in pairs(self.members) do
            if member._pendingRow then
                local r, c = member._pendingRow, member._pendingCol
                if not self.grid[r] then self.grid[r] = {} end
                if not self.grid[r][c] then
                    self.grid[r][c] = cdID
                    member.row = r
                    member.col = c
                    SaveGroupPosition(cdID, self.name, r, c)
                end
                member._pendingRow = nil
                member._pendingCol = nil
            end
        end
        
        -- Shrink grid
        self.layout.gridCols = maxCols - 1
        local db = getDB()
        if db then db.gridCols = self.layout.gridCols end
        
        -- Compensate container position for growth direction (reverse of adding)
        local widthChange = slotW + spacingX
        local posOffsetX
        if horizontalGrowth == "LEFT" then
            posOffsetX = widthChange / 2   -- Shift RIGHT (reverse of adding)
        else -- RIGHT (default)
            posOffsetX = -widthChange / 2  -- Shift LEFT (reverse of adding)
        end
        
        self.position.x = self.position.x + posOffsetX
        if db then
            db.position = db.position or {}
            db.position.x = self.position.x
        end
        self.container:ClearAllPoints()
        self.container:SetPoint("CENTER", UIParent, "CENTER", self.position.x, self.position.y)
        
        self:MarkGridDirty()
        self:Layout()
    end
    
    -- Remove member from grid only (not from CDM), for same-group moves
    function group:RemoveMemberFromGrid(cooldownID)
        local member = self.members[cooldownID]
        if not member then return end
        
        local row, col = member.row, member.col
        if row ~= nil and col ~= nil and self.grid[row] then
            self.grid[row][col] = nil
        end
        
        -- Keep the member in self.members but clear its grid position tracking
        member.row = nil
        member.col = nil
    end
    
    function group:SetAutoReflow(enabled)
        self.autoReflow = enabled
        local db = getDB()
        if db then db.autoReflow = enabled end
        
        -- Trigger immediate reflow when enabling to compact existing gaps
        if enabled then
            self:ReflowIcons()
        end
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then ns.CDMGroups.TriggerTemplateAutoSave() end
    end
    
    function group:SetLockGridSize(enabled)
        self.lockGridSize = enabled
        local db = getDB()
        if db then db.lockGridSize = enabled end
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then ns.CDMGroups.TriggerTemplateAutoSave() end
    end
    
    function group:SetContainerPadding(padding)
        self.containerPadding = padding or 0
        local db = getDB()
        if db then db.containerPadding = self.containerPadding end
        self:Layout()  -- Re-layout to apply new padding
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then ns.CDMGroups.TriggerTemplateAutoSave() end
    end
    
    function group:SetShowBorder(show)
        self.showBorder = show
        local db = getDB()
        if db then db.showBorder = show end
        self.UpdateAppearance()
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then ns.CDMGroups.TriggerTemplateAutoSave() end
    end
    
    function group:SetShowBackground(show)
        self.showBackground = show
        local db = getDB()
        if db then db.showBackground = show end
        self.UpdateAppearance()
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then ns.CDMGroups.TriggerTemplateAutoSave() end
    end
    
    function group:SetBorderColor(r, g, b, a)
        self.borderColor = { r = r, g = g, b = b, a = a or 1 }
        local db = getDB()
        if db then db.borderColor = self.borderColor end
        -- Update title color using SetTextColor (not embedded hex)
        self.container.title:SetText(self.name)
        self.container.title:SetTextColor(r, g, b)
        -- Also update titleFrame's stored color for hover restore
        if self.container.titleFrame then
            self.container.titleFrame._titleColor = { r = r, g = g, b = b }
            -- Update width to match text
            local textWidth = self.container.title:GetStringWidth()
            self.container.titleFrame:SetWidth(textWidth + 12)
        end
        -- Update dragBar color
        if self.dragBar then
            self.dragBar:SetBackdropColor(r * 0.6, g * 0.6, b * 0.6, 0.9)
            self.dragBar:SetBackdropBorderColor(r, g, b, 1)
        end
        self.UpdateAppearance()
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then ns.CDMGroups.TriggerTemplateAutoSave() end
    end
    
    function group:SetBgColor(r, g, b, a)
        self.bgColor = { r = r, g = g, b = b, a = a or 0.6 }
        local db = getDB()
        if db then db.bgColor = self.bgColor end
        self.UpdateAppearance()
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then ns.CDMGroups.TriggerTemplateAutoSave() end
    end
    
    function group:SetPosition(x, y)
        -- Round to 2 decimal places for cleaner display
        x = math.floor(x * 100 + 0.5) / 100
        y = math.floor(y * 100 + 0.5) / 100
        
        self.position.x = x
        self.position.y = y
        local db = getDB()
        if db then db.position = self.position end
        self.container:ClearAllPoints()
        self.container:SetPoint("CENTER", UIParent, "CENTER", x, y)
        self.UpdateDragBarPosition()
        if self.UpdateControlButtonPositions then
            self.UpdateControlButtonPositions()
        end
        -- Trigger auto-save to linked template (position changes)
        if ns.CDMGroups.TriggerTemplateAutoSave then ns.CDMGroups.TriggerTemplateAutoSave() end
        -- Notify AceConfig so options panel updates in real-time
        local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
        if AceConfigRegistry then
            AceConfigRegistry:NotifyChange("ArcUI")
        end
    end
    
    -- Get drop info at screen coordinates
    -- Returns row, col, mode, insertCol, insertRow
    -- Modes:
    --   "swap" = hovering center of occupied cell
    --   "insert" = hovering left/right edge of cell (column insert)
    --   "insert_start" = inserting column at start
    --   "insert_end" = inserting column at end
    --   "insert_row_above" = hovering top edge of cell (row insert above)
    --   "insert_row_below" = hovering bottom edge of cell (row insert below)
    --   "empty" = hovering over empty cell
    function group:GetDropInfo(screenX, screenY)
        local iconSize = self.layout.iconSize or 36
        local spacingX = self.layout.spacingX or self.layout.spacing or 2
        local spacingY = self.layout.spacingY or self.layout.spacing or 2
        local maxRows = self.layout.gridRows or 2
        local maxCols = self.layout.gridCols or 4
        local leftOverflow = self._leftOverflow or 0
        local topOverflow = self._topOverflow or 0
        
        -- Check if grid expansion is locked
        local gridLocked = self.lockGridSize
        
        local left, bottom, width, height = self.container:GetRect()
        if not left then return 0, 0, "empty", 0, 0 end
        
        -- Account for edge overflow when calculating relative position
        local relX = screenX - left - 4 - leftOverflow
        local relY = (bottom + height) - screenY - 4 - topOverflow
        
        -- Calculate cell dimensions
        local cellWidth = iconSize + spacingX
        local cellHeight = iconSize + spacingY
        
        -- Calculate row and position within row
        local rowIndex = relY / cellHeight
        local row = math.floor(rowIndex)
        local rowFraction = rowIndex - row
        
        -- Calculate column and position within cell
        local colIndex = relX / cellWidth
        local col = math.floor(colIndex)
        local cellFraction = colIndex - col
        
        -- Check if dropping above the container
        if row < 0 or (row == 0 and rowIndex < 0) then
            col = Clamp(col, 0, maxCols - 1)
            if gridLocked then
                local occupied = self.grid[0] and self.grid[0][col]
                return 0, col, occupied and "swap" or "empty", col, 0
            end
            return 0, col, "insert_row_above", col, 0
        end
        
        -- Check if dropping below the container
        if row >= maxRows then
            col = Clamp(col, 0, maxCols - 1)
            if gridLocked then
                local occupied = self.grid[maxRows - 1] and self.grid[maxRows - 1][col]
                return maxRows - 1, col, occupied and "swap" or "empty", col, maxRows - 1
            end
            return maxRows - 1, col, "insert_row_below", col, maxRows
        end
        
        -- Check if dropping left of the container
        if col < 0 or (col == 0 and colIndex < 0) then
            row = Clamp(row, 0, maxRows - 1)
            if gridLocked then
                local occupied = self.grid[row] and self.grid[row][0]
                return row, 0, occupied and "swap" or "empty", 0, row
            end
            return row, 0, "insert_start", 0, row
        end
        
        -- Check if dropping right of the container
        if col >= maxCols then
            row = Clamp(row, 0, maxRows - 1)
            if gridLocked then
                local occupied = self.grid[row] and self.grid[row][maxCols - 1]
                return row, maxCols - 1, occupied and "swap" or "empty", maxCols - 1, row
            end
            return row, maxCols - 1, "insert_end", maxCols, row
        end
        
        -- Inside the grid
        local isOccupied = self.grid[row] and self.grid[row][col]
        
        if isOccupied then
            -- Check top edge (top 20% = insert row above)
            if rowFraction < 0.2 then
                if gridLocked then
                    return row, col, "swap", col, row
                end
                if row == 0 then
                    return row, col, "insert_row_above", col, 0
                end
                return row, col, "insert_row_above", col, row
            end
            
            -- Check bottom edge (bottom 20% = insert row below)
            if rowFraction > 0.8 then
                if gridLocked then
                    return row, col, "swap", col, row
                end
                local insertRow = row + 1
                if insertRow >= maxRows then
                    return row, col, "insert_row_below", col, maxRows
                end
                return row, col, "insert_row_below", col, insertRow
            end
            
            -- Check left edge (left 20% = insert column before)
            if cellFraction < 0.2 then
                if gridLocked then
                    return row, col, "swap", col, row
                end
                return row, col, "insert", col, row
            end
            
            -- Check right edge (right 20% = insert column after)
            if cellFraction > 0.8 then
                local insertCol = col + 1
                if gridLocked then
                    return row, col, "swap", col, row
                end
                if insertCol >= maxCols then
                    return row, col, "insert_end", maxCols, row
                end
                return row, col, "insert", insertCol, row
            end
            
            -- Center = swap
            return row, col, "swap", col, row
        else
            -- Empty cell - place directly here
            return row, col, "empty", col, row
        end
    end
    
    function group:SetupMemberDrag(cooldownID)
        local member = self.members[cooldownID]
        if not member or not member.frame then return end
        
        local frame = member.frame
        
        -- Helper to disable mouse on ALL descendants recursively
        -- This is CRITICAL for aura icons which have Applications subframes at high frame levels
        local function DisableAllChildMouse(f)
            for _, child in pairs({f:GetChildren()}) do
                if child.EnableMouse then
                    child:EnableMouse(false)
                end
                if child.SetMovable then
                    child:SetMovable(false)
                end
                if child.RegisterForDrag then
                    child:RegisterForDrag()
                end
                DisableAllChildMouse(child)
            end
        end
        
        -- CRITICAL: Disable mouse on ALL children FIRST before enabling parent
        DisableAllChildMouse(frame)
        
        -- Also explicitly disable known overlays (belt and suspenders)
        if frame._arcOverlay then
            frame._arcOverlay:EnableMouse(false)
            frame._arcOverlay:SetMovable(false)
            frame._arcOverlay:RegisterForDrag()
            if frame._arcOverlay.highlight then frame._arcOverlay.highlight:Hide() end
            if frame._arcOverlay.dragText then frame._arcOverlay.dragText:Hide() end
        end
        if frame._arcTextOverlay then
            frame._arcTextOverlay:EnableMouse(false)
        end
        -- CDM's Applications frame for auras
        if frame.Applications then
            frame.Applications:EnableMouse(false)
        end
        
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        
        -- CLICK-THROUGH: Check dragModeEnabled and panel DIRECTLY, not cached
        local ACD = LibStub("AceConfigDialog-3.0", true)
        local panelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] and true or false
        local allowDrag = ns.CDMGroups.dragModeEnabled or panelOpen
        
        if allowDrag then
            frame:EnableMouse(true)
            if frame.SetMouseClickThrough then
                frame:SetMouseClickThrough(false)
            end
        else
            -- Read click-through directly from DB
            local clickThroughEnabled = false
            local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
            if db then
                clickThroughEnabled = db.clickThrough == true
            end
            ApplyClickThrough(frame, clickThroughEnabled)
        end
        
        -- Create edit button if it doesn't exist (shows only when options panel is open)
        -- Small clean button at bottom
        if not frame._arcEditButton then
            local editBtn = CreateFrame("Button", nil, frame)
            editBtn:SetSize(20, 12)
            editBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, -2)
            editBtn:SetFrameLevel(frame:GetFrameLevel() + 100)
            editBtn:EnableMouse(true)  -- Ensure always clickable
            editBtn:RegisterForClicks("LeftButtonUp")  -- Register for clicks
            
            -- Dark semi-transparent background
            local bg = editBtn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0, 0, 0, 0.7)
            editBtn._bg = bg
            
            -- Yellow/gold text
            local editText = editBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            editText:SetPoint("CENTER", 0, 0)
            editText:SetText("Edit")
            editText:SetTextColor(1, 0.8, 0)  -- Gold text
            editText:SetFont(editText:GetFont(), 8, "OUTLINE")
            editBtn._text = editText
            
            editBtn:SetScript("OnClick", function(self)
                local cdID = frame.cooldownID
                if not cdID then return end
                
                -- Arc Auras have string IDs starting with "arc_" - treat as cooldowns
                if type(cdID) == "string" and cdID:match("^arc_") then
                    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
                        ns.CDMEnhanceOptions.SelectIcon(cdID, false)  -- false = cooldown type
                    end
                    return
                end
                
                -- Regular CDM icons - use API to determine type
                local data = ns.API and ns.API.GetCDMIcon(cdID)
                if data then
                    local isAura = data.isAura
                    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
                        ns.CDMEnhanceOptions.SelectIcon(cdID, isAura)
                    end
                end
            end)
            
            editBtn:SetScript("OnEnter", function(self)
                self._text:SetTextColor(1, 1, 0.3)  -- Brighter on hover
            end)
            editBtn:SetScript("OnLeave", function(self)
                self._text:SetTextColor(1, 0.8, 0)
            end)
            
            editBtn:Hide()  -- Start hidden, shown when options panel opens
            frame._arcEditButton = editBtn
            
            -- CRITICAL: If options panel is already open, show the button immediately
            -- (UpdateEditButtonVisibility cache may skip this new button)
            local ACD = LibStub("AceConfigDialog-3.0", true)
            if ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] then
                editBtn:Show()
            end
        else
            -- Edit button already exists - ensure visibility is correct
            -- (frame may have transitioned from free position where button was hidden)
            ns.CDMGroups.UpdateSingleEditButton(frame)
        end
        
        -- Add click handler for icon selection
        -- OnDragStop handles drag completion separately
        frame:SetScript("OnMouseUp", function(self, button)
            local cdID = self.cooldownID
            if not cdID then return end
            
            -- If we were dragging, OnDragStop handles it - don't process as click
            if self._groupDragging then return end
            
            -- Check if options panel is open (REQUIRED for left-click selection)
            local ACD = LibStub("AceConfigDialog-3.0", true)
            local optionsPanelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
            
            -- Only process clicks when options panel is open
            if not optionsPanelOpen then return end
            
            -- Left-click selects icon when drag mode is off
            if button == "LeftButton" and not ns.CDMGroups.dragModeEnabled then
                -- Arc Auras have string IDs starting with "arc_" - treat as cooldowns
                if type(cdID) == "string" and cdID:match("^arc_") then
                    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
                        ns.CDMEnhanceOptions.SelectIcon(cdID, false)  -- false = cooldown type
                    end
                    return
                end
                
                -- Regular CDM icons - use API to determine type
                local data = ns.API and ns.API.GetCDMIcon(cdID)
                if data then
                    local isAura = data.isAura
                    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
                        ns.CDMEnhanceOptions.SelectIcon(cdID, isAura)
                    end
                end
            end
        end)
        
        -- CRITICAL: Do NOT capture cooldownID or sourceGroup in closures!
        -- CDM can reuse frames, so we must read cooldownID from frame.cooldownID at drag time
        -- and look up the owning group dynamically
        
        frame:SetScript("OnDragStart", function(self)
            -- Allow drag when drag mode is on OR options panel is open
            if not ns.CDMGroups.ShouldAllowDrag() then return end
            
            -- Read cooldownID from frame at drag time, NOT from closure
            local cdID = self.cooldownID
            if not cdID then return end
            
            -- Find which group actually owns this frame NOW (not captured group)
            local srcGroup = nil
            for gName, g in pairs(ns.CDMGroups.groups) do
                if g.members[cdID] and g.members[cdID].frame == self then
                    srcGroup = g
                    break
                end
            end
            
            if not srcGroup then return end
            
            self:StartMoving()
            self._groupDragging = true
            self._sourceGroup = srcGroup
            self._sourceCdID = cdID
            ns.CDMGroups._dragSourceGroup = srcGroup
            self:SetFrameStrata("TOOLTIP")
            
            self:SetScript("OnUpdate", function(self)
                if self._groupDragging then
                    local cx, cy = self:GetCenter()
                    if cx and cy then
                        ns.CDMGroups.UpdateDropIndicator(cx, cy)
                    end
                end
            end)
        end)
        
        frame:SetScript("OnDragStop", function(self)
            if self._groupDragging then
                self:StopMovingOrSizing()
                self._groupDragging = false
                self:SetFrameStrata("MEDIUM")
                self:SetScript("OnUpdate", nil)
                ns.CDMGroups.HideDropIndicator()
                ns.CDMGroups._dragSourceGroup = nil
                
                local cx, cy = self:GetCenter()
                local cdID = self._sourceCdID
                local srcGroup = self._sourceGroup
                
                -- Validate that srcGroup still has this cdID
                if not srcGroup or not srcGroup.members[cdID] then
                    -- Group no longer has this member - just reposition
                    self._sourceGroup = nil
                    self._sourceCdID = nil
                    return
                end
                
                local targetGroup, targetRow, targetCol, mode, insertCol, insertRow = ns.CDMGroups.FindDropTarget(cx, cy)
                
                -- When options panel is open, use simple placement (edit mode)
                -- Reflow will happen when panel closes
                local editMode = ns.CDMGroups.IsOptionsPanelOpen and ns.CDMGroups.IsOptionsPanelOpen()
                
                if targetGroup then
                    if mode == "swap" then
                        -- Swap positions
                        if targetGroup == srcGroup then
                            -- Check if destination is a placeholder
                            local destCdID = targetGroup.grid[targetRow] and targetGroup.grid[targetRow][targetCol]
                            local destMember = destCdID and targetGroup.members[destCdID]
                            
                            if destMember and destMember.isPlaceholder then
                                -- Destination is a placeholder - real frame takes over position
                                -- Placeholder stays in savedPositions but loses grid claim
                                srcGroup:PlaceMemberAt(cdID, targetRow, targetCol)
                                -- The placeholder's savedPosition already points to this row/col
                                -- It will be hidden since a real frame now owns the slot
                            else
                                srcGroup:SwapMembers(cdID, targetRow, targetCol)
                            end
                        else
                            -- Cross-group swap: properly swap icons between groups
                            local srcMember = srcGroup.members[cdID]
                            local srcFrame = srcMember and srcMember.frame
                            local srcEntry = srcMember and srcMember.entry
                            local srcRow = srcMember and srcMember.row or 0
                            local srcCol = srcMember and srcMember.col or 0
                            
                            -- Get the destination icon info
                            local destCdID = targetGroup.grid[targetRow] and targetGroup.grid[targetRow][targetCol]
                            local destMember = destCdID and targetGroup.members[destCdID]
                            local destFrame = destMember and destMember.frame
                            local destEntry = destMember and destMember.entry
                            
                            if destMember and destMember.isPlaceholder then
                                -- Destination is a placeholder - real frame takes over position
                                -- Remove placeholder from grid and members (position stays in savedPositions)
                                if targetGroup.grid[targetRow] then
                                    targetGroup.grid[targetRow][targetCol] = nil
                                end
                                targetGroup.members[destCdID] = nil
                                
                                -- Move real frame to destination
                                srcGroup:RemoveMemberKeepFrame(cdID)
                                targetGroup:AddMemberAtWithFrame(cdID, targetRow, targetCol, srcFrame, srcEntry)
                                
                                if srcGroup.autoReflow and not editMode then
                                    srcGroup:ReflowIcons()
                                end
                            elseif destCdID and destMember then
                                -- True cross-group swap: both icons move
                                -- Step 1: Remove both from their grids (keep frames)
                                srcGroup:RemoveMemberKeepFrame(cdID)
                                targetGroup:RemoveMemberKeepFrame(destCdID)
                                
                                -- Step 2: Add source icon to target group at destination position
                                targetGroup:AddMemberAtWithFrame(cdID, targetRow, targetCol, srcFrame, srcEntry)
                                
                                -- Step 3: Add destination icon to source group at source position
                                srcGroup:AddMemberAtWithFrame(destCdID, srcRow, srcCol, destFrame, destEntry)
                                
                                -- Step 4: EXPLICIT SIZE ENFORCEMENT for both swapped icons
                                -- Apply target group size to source icon
                                if srcFrame then
                                    local targetSlotW, targetSlotH = GetSlotDimensions(targetGroup.layout)
                                    srcFrame._cdmgTargetSize = math.max(targetSlotW, targetSlotH)
                                    srcFrame._cdmgSlotW = targetSlotW  -- Store GROUP's slot dimensions
                                    srcFrame._cdmgSlotH = targetSlotH
                                    srcFrame._cdmgSettingSize = true
                                    srcFrame:SetSize(targetSlotW, targetSlotH)
                                    srcFrame._cdmgSettingSize = false
                                    srcFrame:SetScale(1)
                                end
                                -- Apply source group size to destination icon
                                if destFrame then
                                    local srcSlotW, srcSlotH = GetSlotDimensions(srcGroup.layout)
                                    destFrame._cdmgTargetSize = math.max(srcSlotW, srcSlotH)
                                    destFrame._cdmgSlotW = srcSlotW  -- Store GROUP's slot dimensions
                                    destFrame._cdmgSlotH = srcSlotH
                                    destFrame._cdmgSettingSize = true
                                    destFrame:SetSize(srcSlotW, srcSlotH)
                                    destFrame._cdmgSettingSize = false
                                    destFrame:SetScale(1)
                                end
                                
                                -- Trigger Masque refresh for new sizes
                                if ns.Masque and ns.Masque.QueueRefresh then
                                    ns.Masque.QueueRefresh()
                                end
                                
                                -- Step 5: Ensure both groups reflow properly (not in edit mode)
                                if srcGroup.autoReflow and not editMode then
                                    srcGroup:ReflowIcons()
                                end
                                if targetGroup.autoReflow and not editMode then
                                    targetGroup:ReflowIcons()
                                end
                            else
                                -- No destination icon, just move source
                                srcGroup:RemoveMemberKeepFrame(cdID)
                                targetGroup:AddMemberAtWithFrame(cdID, targetRow, targetCol, srcFrame, srcEntry)
                                
                                if srcGroup.autoReflow and not editMode then
                                    srcGroup:ReflowIcons()
                                end
                            end
                        end
                    elseif mode == "insert_row_above" then
                        -- Insert new row at top of/above target row, place icon there
                        local frame, entry
                        if targetGroup ~= srcGroup then
                            local member = srcGroup.members[cdID]
                            frame = member and member.frame
                            entry = member and member.entry
                            srcGroup:RemoveMemberKeepFrame(cdID)
                            if srcGroup.autoReflow and not editMode then
                                srcGroup:ReflowIcons()
                            end
                        else
                            srcGroup:RemoveMemberFromGrid(cdID)
                        end
                        targetGroup:InsertRowAt(insertRow)
                        targetGroup:AddMemberAtWithFrame(cdID, insertRow, targetCol, frame, entry)
                    elseif mode == "insert_row_below" then
                        -- Insert new row below target row, place icon there
                        local frame, entry
                        if targetGroup ~= srcGroup then
                            local member = srcGroup.members[cdID]
                            frame = member and member.frame
                            entry = member and member.entry
                            srcGroup:RemoveMemberKeepFrame(cdID)
                            if srcGroup.autoReflow and not editMode then
                                srcGroup:ReflowIcons()
                            end
                        else
                            srcGroup:RemoveMemberFromGrid(cdID)
                        end
                        -- If insertRow >= maxRows, add row at bottom
                        if insertRow >= targetGroup.layout.gridRows then
                            targetGroup:AddRowAtBottom()
                        else
                            targetGroup:InsertRowAt(insertRow)
                        end
                        targetGroup:AddMemberAtWithFrame(cdID, insertRow, targetCol, frame, entry)
                    elseif mode == "insert_start" then
                        -- Insert at column 0, shift all existing icons right
                        local frame, entry
                        if targetGroup ~= srcGroup then
                            local member = srcGroup.members[cdID]
                            frame = member and member.frame
                            entry = member and member.entry
                            srcGroup:RemoveMemberKeepFrame(cdID)
                            if srcGroup.autoReflow and not editMode then
                                srcGroup:ReflowIcons()
                            end
                        else
                            srcGroup:RemoveMemberFromGrid(cdID)
                        end
                        targetGroup:InsertColumnAt(0)
                        targetGroup:AddMemberAtWithFrame(cdID, targetRow, 0, frame, entry)
                        -- Trigger reflow for same-group to fill gaps (not in edit mode)
                        if targetGroup == srcGroup and srcGroup.autoReflow and not editMode then
                            srcGroup:ReflowIcons()
                        end
                    elseif mode == "insert_end" then
                        -- Add column at end and place icon there
                        local frame, entry
                        local member = srcGroup.members[cdID]
                        frame = member and member.frame
                        entry = member and member.entry
                        
                        if targetGroup ~= srcGroup then
                            srcGroup:RemoveMemberKeepFrame(cdID)
                            if srcGroup.autoReflow and not editMode then
                                srcGroup:ReflowIcons()
                            end
                        else
                            srcGroup:RemoveMemberFromGrid(cdID)
                        end
                        local newCol = targetGroup.layout.gridCols
                        targetGroup:AddColumnAtEnd()
                        targetGroup:AddMemberAtWithFrame(cdID, targetRow, newCol, frame, entry)
                        -- Trigger reflow for same-group to fill gaps (not in edit mode)
                        if targetGroup == srcGroup and srcGroup.autoReflow and not editMode then
                            srcGroup:ReflowIcons()
                        end
                    elseif mode == "insert" then
                        -- Insert at position (shift others)
                        if targetGroup == srcGroup then
                            if srcGroup.autoReflow and not editMode then
                                -- For autoReflow groups (not in edit mode), update sequence order and reflow
                                srcGroup:ReorderIconInSequence(cdID, targetRow, insertCol)
                            else
                                srcGroup:MoveMemberTo(cdID, targetRow, insertCol)
                            end
                        else
                            local member = srcGroup.members[cdID]
                            local frame = member and member.frame
                            local entry = member and member.entry
                            srcGroup:RemoveMemberKeepFrame(cdID)
                            targetGroup:InsertMemberAtWithFrame(cdID, targetRow, insertCol, frame, entry)
                            if srcGroup.autoReflow and not editMode then
                                srcGroup:ReflowIcons()
                            end
                        end
                    else
                        -- Empty cell - place directly
                        if targetGroup == srcGroup then
                            if srcGroup.autoReflow and not editMode then
                                -- For autoReflow groups (not in edit mode), update sequence order and reflow
                                srcGroup:ReorderIconInSequence(cdID, targetRow, targetCol)
                            else
                                srcGroup:PlaceMemberAt(cdID, targetRow, targetCol)
                            end
                        else
                            local member = srcGroup.members[cdID]
                            local frame = member and member.frame
                            local entry = member and member.entry
                            srcGroup:RemoveMemberKeepFrame(cdID)
                            targetGroup:AddMemberAtWithFrame(cdID, targetRow, targetCol, frame, entry)
                            if srcGroup.autoReflow and not editMode then
                                srcGroup:ReflowIcons()
                            end
                        end
                    end
                else
                    -- Dropped outside - make free icon
                    local ux, uy = UIParent:GetCenter()
                    local newX, newY = cx - ux, cy - uy
                    local savedSize = srcGroup.layout.iconSize
                    -- CRITICAL: Save frame reference BEFORE RemoveMember clears/hides it
                    -- Otherwise TrackFreeIcon can't find the frame via Registry
                    local memberFrame = srcGroup.members[cdID] and srcGroup.members[cdID].frame
                    srcGroup:RemoveMember(cdID, true)
                    ns.CDMGroups.TrackFreeIcon(cdID, newX, newY, savedSize, memberFrame)
                end
                
                -- CRITICAL: Re-setup drag state and APPLY SIZE after move
                if cdID then
                    -- Find which group now owns this cdID
                    local newGroup = nil
                    for _, g in pairs(ns.CDMGroups.groups) do
                        if g.members[cdID] then
                            newGroup = g
                            break
                        end
                    end
                    
                    if newGroup and newGroup.members[cdID] then
                        local member = newGroup.members[cdID]
                        if member.frame then
                            -- CRITICAL: Apply correct size based on useGroupScale setting
                            local slotW, slotH = GetSlotDimensions(newGroup.layout)
                            local effectiveW = slotW
                            local effectiveH = slotH
                            
                            -- Check if this icon has custom scale (useGroupScale == false)
                            if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                                local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cdID)
                                if cfg and cfg.useGroupScale == false then
                                    -- Custom scale: use width/height * scale
                                    local baseW = cfg.width or slotW
                                    local baseH = cfg.height or slotH
                                    local iconScale = cfg.scale or 1.0
                                    effectiveW = baseW * iconScale
                                    effectiveH = baseH * iconScale
                                end
                            end
                            
                            member.frame._cdmgTargetSize = math.max(effectiveW, effectiveH)
                            member.frame._cdmgSlotW = slotW  -- Store GROUP's slot dimensions
                            member.frame._cdmgSlotH = slotH
                            member._effectiveIconW = effectiveW
                            member._effectiveIconH = effectiveH
                            member.frame._cdmgSettingSize = true
                            member.frame:SetSize(effectiveW, effectiveH)
                            member.frame._cdmgSettingSize = false
                            member.frame:SetScale(1)
                            
                            -- Trigger Masque refresh for new size
                            if ns.Masque and ns.Masque.QueueRefresh then
                                ns.Masque.QueueRefresh()
                            end
                            
                            -- Re-setup drag handlers if dragging is allowed
                            if ns.CDMGroups.ShouldAllowDrag() then
                                newGroup:SetupMemberDrag(cdID)
                            end
                        end
                    elseif ns.CDMGroups.freeIcons[cdID] then
                        -- Free icon - setup drag if allowed
                        if ns.CDMGroups.ShouldAllowDrag() then
                            ns.CDMGroups.SetupFreeIconDrag(cdID)
                        end
                    end
                end
                
                self._sourceGroup = nil
                self._sourceCdID = nil
            end
        end)
    end
    
    function group:SetMemberDragEnabled(enabled)
        for cdID, member in pairs(self.members) do
            if member.frame then
                if enabled then
                    self:SetupMemberDrag(cdID)
                    member.frame:EnableMouse(true)
                else
                    member.frame:SetScript("OnDragStart", nil)
                    member.frame:SetScript("OnDragStop", nil)
                    member.frame:SetScript("OnUpdate", nil)
                    member.frame:RegisterForDrag()
                    member.frame._groupDragging = nil
                    member.frame._sourceGroup = nil
                    member.frame._sourceCdID = nil
                    
                    -- CLICK-THROUGH: Read DB directly to avoid stale cache issues
                    -- When drag mode is disabled (panel closing), apply the saved setting
                    local clickThroughEnabled = false
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if db then
                        clickThroughEnabled = db.clickThrough == true
                    end
                    ApplyClickThrough(member.frame, clickThroughEnabled)
                    
                    -- Re-enable overlay for right-click when drag mode is disabled
                    -- Let CDMEnhance's UpdateOverlayState handle proper state
                    if member.frame._arcOverlay and ns.CDMEnhance and ns.CDMEnhance.UpdateOverlayStateForFrame then
                        -- Only update overlay if click-through is disabled
                        if not clickThroughEnabled then
                            ns.CDMEnhance.UpdateOverlayStateForFrame(member.frame)
                        end
                    end
                end
            end
        end
        if not enabled then
            ns.CDMGroups.HideDropIndicator()
        end
    end
    
    function group:Destroy()
        local toRemove = {}
        for cdID in pairs(self.members) do
            table.insert(toRemove, cdID)
        end
        for _, cdID in ipairs(toRemove) do
            self:RemoveMember(cdID, true)
        end
        
        -- Hide container (buttons auto-hide since parented to container)
        if self.container then
            self.container:Hide()
        end
        
        ns.CDMGroups.groups[name] = nil
    end
    
    -- NOTE: Container OnUpdate removed for performance
    -- It was running at 60fps for EVERY group (5 groups = 300 calls/sec!)
    -- Drag bar positioning now handled by SetDragMode and UpdateGroupSelectionVisuals
    
    -- Store in spec-specific table and ns.CDMGroups.groups shortcut
    local specKey = EnsureSpecTables(ns.CDMGroups.currentSpec)
    ns.CDMGroups.currentSpec = ns.CDMGroups.currentSpec or specKey  -- Ensure currentSpec is set
    ns.CDMGroups.specGroups[specKey][name] = group
    ns.CDMGroups.groups[name] = group
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- SYNC TO ACTIVE PROFILE: Add this group to the active profile's groupLayouts
    -- This ensures new groups are persisted per-profile, not just globally
    -- ═══════════════════════════════════════════════════════════════════════════
    local specData = GetSpecData()
    if specData and specData.layoutProfiles then
        local activeProfileName = specData.activeProfile or "Default"
        local activeProfile = specData.layoutProfiles[activeProfileName]
        if activeProfile then
            if not activeProfile.groupLayouts then
                activeProfile.groupLayouts = {}
            end
            -- Only add if not already there (avoid overwriting loaded settings)
            if not activeProfile.groupLayouts[name] then
                activeProfile.groupLayouts[name] = {
                    gridRows = group.layout.gridRows,
                    gridCols = group.layout.gridCols,
                    position = group.position and { x = group.position.x, y = group.position.y },
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
                    showBorder = group.showBorder,
                    showBackground = group.showBackground,
                    autoReflow = group.autoReflow,
                    dynamicLayout = group.dynamicLayout,
                    lockGridSize = group.lockGridSize,
                    containerPadding = group.containerPadding,
                    borderColor = group.borderColor and DeepCopy(group.borderColor),
                    bgColor = group.bgColor and DeepCopy(group.bgColor),
                    visibility = group.visibility,
                }
                DebugPrint("|cff00ff00[CreateGroup]|r Added group '" .. name .. "' to profile '" .. activeProfileName .. "' groupLayouts")
            end
        end
    end
    
    -- Notify Masque about the new custom group
    if ns.Masque and ns.Masque.OnGroupCreated then
        ns.Masque.OnGroupCreated(name)
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL: Ensure new groups are fully initialized like default groups
    -- Without these calls, user-created groups can have:
    --   - Stale container sizing (no Layout)
    --   - Incorrect visibility state (combat-only settings not applied)
    --   - Orphan frames not assigned (FrameController unaware of new group)
    -- ═══════════════════════════════════════════════════════════════════════════
    
    -- Call Layout() to ensure container is properly sized
    group:Layout()
    
    -- Update visibility based on combat/visibility settings
    if ns.CDMGroups.UpdateGroupVisibility then
        ns.CDMGroups.UpdateGroupVisibility()
    end
    
    -- Notify FrameController to check for orphan frames that could go in this group
    -- Use short debounce - group is ready, just need to scan for orphans
    if ns.FrameController and ns.FrameController.ScheduleReconcile then
        ns.FrameController.ScheduleReconcile(0.15)  -- Short debounce for group creation
    end
    
    return group
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DELETE GROUP
-- Removes a group from the current profile and runtime
-- ═══════════════════════════════════════════════════════════════════════════
function ns.CDMGroups.DeleteGroup(groupName)
    if not groupName then return false end
    
    local group = ns.CDMGroups.groups[groupName]
    if not group then
        PrintMsg("Group '" .. groupName .. "' not found")
        return false
    end
    
    -- Don't delete base groups if they have members
    local BASE_GROUPS = { Essential = true, Utility = true, Buffs = true }
    local memberCount = 0
    for _ in pairs(group.members or {}) do memberCount = memberCount + 1 end
    
    if BASE_GROUPS[groupName] and memberCount > 0 then
        PrintMsg("Cannot delete base group '" .. groupName .. "' while it has " .. memberCount .. " icons. Remove icons first.")
        return false
    end
    
    -- Return all frames to CDM
    for cdID, member in pairs(group.members or {}) do
        if member.frame then
            -- Remove saved position - use ClearPositionFromSpec for verified profile access
            ClearPositionFromSpec(cdID)
            -- Return to CDM (will be re-assigned next scan)
            member.frame:SetParent(UIParent)
            member.frame:Hide()
        end
    end
    wipe(group.members)
    wipe(group.grid)
    
    -- ═══════════════════════════════════════════════════════════════════
    -- COMPREHENSIVE GROUP UI CLEANUP
    -- Must fully destroy all UI elements to prevent ghost artifacts
    -- ═══════════════════════════════════════════════════════════════════
    
    -- Hide and orphan edge arrows first - they're parented to UIParent, not container!
    if group.edgeArrows then
        for _, arrow in pairs(group.edgeArrows) do
            if arrow then
                arrow:ClearAllPoints()
                arrow:Hide()
                arrow:SetParent(nil)
            end
        end
        wipe(group.edgeArrows)
    end
    
    -- Hide and orphan drag toggle button (parented to UIParent!)
    if group.dragToggleBtn then
        group.dragToggleBtn:ClearAllPoints()
        group.dragToggleBtn:Hide()
        group.dragToggleBtn:SetParent(nil)
        group.dragToggleBtn = nil
    end
    
    -- Hide and orphan drag bar
    if group.dragBar then
        group.dragBar:ClearAllPoints()
        group.dragBar:Hide()
        group.dragBar:SetParent(nil)
        group.dragBar = nil
    end
    
    -- Hide and orphan selection highlight
    if group.selectionHighlight then
        group.selectionHighlight:ClearAllPoints()
        group.selectionHighlight:Hide()
        group.selectionHighlight:SetParent(nil)
        group.selectionHighlight = nil
    end
    
    -- Hide and orphan container last
    if group.container then
        group.container:ClearAllPoints()
        group.container:Hide()
        group.container:SetParent(nil)
        group.container = nil
    end
    
    -- Notify EditModeContainers to clean up wrapper for this group
    if ns.EditModeContainers and ns.EditModeContainers.OnGroupDeleted then
        ns.EditModeContainers.OnGroupDeleted(groupName)
    end
    
    -- Remove from runtime tables
    ns.CDMGroups.groups[groupName] = nil
    if ns.CDMGroups.currentSpec and ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec] then
        ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec][groupName] = nil
    end
    
    -- Remove from specData.groups
    local specData = GetSpecData()
    if specData and specData.groups then
        specData.groups[groupName] = nil
    end
    
    -- Remove from active profile's groupLayouts
    if specData and specData.layoutProfiles then
        local activeProfileName = specData.activeProfile or "Default"
        local activeProfile = specData.layoutProfiles[activeProfileName]
        if activeProfile and activeProfile.groupLayouts then
            activeProfile.groupLayouts[groupName] = nil
            DebugPrint("|cffff0000[DeleteGroup]|r Removed '" .. groupName .. "' from profile '" .. activeProfileName .. "'")
        end
    end
    
    PrintMsg("Deleted group '" .. groupName .. "'")
    
    -- Notify Masque about the deleted group
    if ns.Masque and ns.Masque.OnGroupDeleted then
        ns.Masque.OnGroupDeleted(groupName)
    end
    
    -- Trigger a scan to reassign orphaned icons
    C_Timer.After(0.1, function()
        if ns.API and ns.API.ScanAllCDMIcons then
            ns.API.ScanAllCDMIcons()
        end
    end)
    
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ProcessDirtyGrids, RefreshIconLayout, RefreshAllLayouts 
-- MOVED TO ArcUI_CDMGroups_Layout.lua
-- ═══════════════════════════════════════════════════════════════════════════

-- DROP INDICATOR - Dual mode: Square for swap, Line for insert

local DropIndicator = CreateFrame("Frame", "CDMGroups_DropIndicator", UIParent, "BackdropTemplate")
DropIndicator:SetSize(36, 36)
DropIndicator:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
DropIndicator:SetBackdropColor(0, 1, 0, 0.3)
DropIndicator:SetBackdropBorderColor(0, 1, 0, 0.9)
DropIndicator:SetFrameStrata("TOOLTIP")
DropIndicator:SetFrameLevel(9999)
DropIndicator:Hide()

-- Line indicator for insert mode
local InsertLine = CreateFrame("Frame", "CDMGroups_InsertLine", UIParent, "BackdropTemplate")
InsertLine:SetSize(4, 36)
InsertLine:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
})
InsertLine:SetBackdropColor(0, 1, 0, 0.9)
InsertLine:SetFrameStrata("TOOLTIP")
InsertLine:SetFrameLevel(9999)
InsertLine:Hide()

local insertLineGlow = InsertLine:CreateTexture(nil, "BACKGROUND")
insertLineGlow:SetPoint("TOPLEFT", InsertLine, "TOPLEFT", -4, 4)
insertLineGlow:SetPoint("BOTTOMRIGHT", InsertLine, "BOTTOMRIGHT", 4, -4)
insertLineGlow:SetColorTexture(0, 1, 0, 0.3)

ns.DropIndicator = DropIndicator
ns.InsertLine = InsertLine

-- Horizontal line indicator for row insert mode
local InsertRowLine = CreateFrame("Frame", "CDMGroups_InsertRowLine", UIParent, "BackdropTemplate")
InsertRowLine:SetSize(36, 4)
InsertRowLine:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
})
InsertRowLine:SetBackdropColor(0, 1, 0, 0.9)
InsertRowLine:SetFrameStrata("TOOLTIP")
InsertRowLine:SetFrameLevel(9999)
InsertRowLine:Hide()

local insertRowLineGlow = InsertRowLine:CreateTexture(nil, "BACKGROUND")
insertRowLineGlow:SetPoint("TOPLEFT", InsertRowLine, "TOPLEFT", -4, 4)
insertRowLineGlow:SetPoint("BOTTOMRIGHT", InsertRowLine, "BOTTOMRIGHT", 4, -4)
insertRowLineGlow:SetColorTexture(0, 1, 0, 0.3)

ns.InsertRowLine = InsertRowLine

-- Returns group, row, col, mode, insertCol, insertRow
function ns.CDMGroups.FindDropTarget(screenX, screenY)
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.container and group.container:IsVisible() then
            local left, bottom, width, height = group.container:GetRect()
            if left and screenX >= left and screenX <= left + width and
               screenY >= bottom and screenY <= bottom + height then
                local row, col, mode, insertCol, insertRow = group:GetDropInfo(screenX, screenY)
                return group, row, col, mode, insertCol, insertRow
            end
        end
    end
    return nil, nil, nil, nil, nil, nil
end

function ns.CDMGroups.UpdateDropIndicator(screenX, screenY)
    local targetGroup, targetRow, targetCol, mode, insertCol, insertRow = ns.CDMGroups.FindDropTarget(screenX, screenY)
    
    if targetGroup then
        -- Use actual slot dimensions, not just iconSize
        local slotW, slotH = GetSlotDimensions(targetGroup.layout)
        local spacingX = targetGroup.layout.spacingX or targetGroup.layout.spacing or 2
        local spacingY = targetGroup.layout.spacingY or targetGroup.layout.spacing or 2
        local leftOverflow = targetGroup._leftOverflow or 0
        local topOverflow = targetGroup._topOverflow or 0
        local maxCols = targetGroup.layout.gridCols or 4
        local maxRows = targetGroup.layout.gridRows or 2
        
        -- Match the borderOffset + padding used in Layout icon positioning
        local borderOffset = 6
        local padding = targetGroup.containerPadding or 0
        local edgeInset = borderOffset + padding
        
        -- Helper to convert grid position to physical screen offset
        local function getPhysicalOffset(row, col)
            local physX = col * (slotW + spacingX)
            local physY = row * (slotH + spacingY)
            return physX, physY
        end
        
        local left, bottom, width, height = targetGroup.container:GetRect()
        if not left then
            DropIndicator:Hide()
            InsertLine:Hide()
            InsertRowLine:Hide()
            return
        end
        
        if mode == "swap" then
            -- Show square over the cell
            local physX, physY = getPhysicalOffset(targetRow, targetCol)
            local indicatorX = left + edgeInset + leftOverflow + physX
            local indicatorY = bottom + height - edgeInset - topOverflow - physY
            
            DropIndicator:SetSize(slotW, slotH)
            DropIndicator:ClearAllPoints()
            DropIndicator:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", indicatorX, indicatorY)
            
            -- Orange for swap (occupied cell)
            DropIndicator:SetBackdropColor(1, 0.5, 0, 0.3)
            DropIndicator:SetBackdropBorderColor(1, 0.5, 0, 0.9)
            DropIndicator:Show()
            InsertLine:Hide()
            InsertRowLine:Hide()
            
        elseif mode == "insert_row_above" or mode == "insert_row_below" then
            -- Show horizontal line for row insertion
            local physX, physY = getPhysicalOffset(targetRow, targetCol)
            local indicatorX = left + edgeInset + leftOverflow + physX
            local indicatorY
            
            if mode == "insert_row_above" then
                indicatorY = bottom + height - edgeInset - topOverflow - physY + spacingY/2 + 2
            else
                indicatorY = bottom + height - edgeInset - topOverflow - physY - slotH - spacingY/2 + 2
            end
            
            InsertRowLine:SetSize(slotW, 4)
            InsertRowLine:ClearAllPoints()
            InsertRowLine:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", indicatorX, indicatorY)
            
            if ns.CDMGroups._dragSourceGroup == targetGroup then
                InsertRowLine:SetBackdropColor(0, 1, 0, 0.9)
                insertRowLineGlow:SetColorTexture(0, 1, 0, 0.3)
            else
                InsertRowLine:SetBackdropColor(0, 1, 1, 0.9)
                insertRowLineGlow:SetColorTexture(0, 1, 1, 0.3)
            end
            InsertRowLine:Show()
            DropIndicator:Hide()
            InsertLine:Hide()
            
        elseif mode == "insert" or mode == "insert_start" or mode == "insert_end" then
            -- Show vertical line at column insertion point
            local physX, physY = getPhysicalOffset(targetRow, targetCol)
            local indicatorX
            local indicatorY = bottom + height - edgeInset - topOverflow - physY
            
            if mode == "insert_start" then
                -- Line at left side
                indicatorX = left + borderOffset + leftOverflow
            elseif mode == "insert_end" then
                -- Line at right side
                indicatorX = left + edgeInset + leftOverflow + maxCols * (slotW + spacingX) - spacingX/2
            else
                -- Insert between columns
                indicatorX = left + edgeInset + leftOverflow + insertCol * (slotW + spacingX) - spacingX/2 - 2
            end
            
            InsertLine:SetSize(4, slotH)
            InsertLine:ClearAllPoints()
            InsertLine:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", indicatorX, indicatorY)
            
            -- Purple for edge insert (adding column), cyan/green for normal insert
            if mode == "insert_start" or mode == "insert_end" then
                InsertLine:SetBackdropColor(0.8, 0.2, 1, 0.9)
                insertLineGlow:SetColorTexture(0.8, 0.2, 1, 0.3)
            elseif ns.CDMGroups._dragSourceGroup == targetGroup then
                InsertLine:SetBackdropColor(0, 1, 0, 0.9)
                insertLineGlow:SetColorTexture(0, 1, 0, 0.3)
            else
                InsertLine:SetBackdropColor(0, 1, 1, 0.9)
                insertLineGlow:SetColorTexture(0, 1, 1, 0.3)
            end
            InsertLine:Show()
            DropIndicator:Hide()
            InsertRowLine:Hide()
            
        else
            -- Empty cell - show green square
            local physX, physY = getPhysicalOffset(targetRow, targetCol)
            local indicatorX = left + edgeInset + leftOverflow + physX
            local indicatorY = bottom + height - edgeInset - topOverflow - physY
            
            DropIndicator:SetSize(slotW, slotH)
            DropIndicator:ClearAllPoints()
            DropIndicator:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", indicatorX, indicatorY)
            
            DropIndicator:SetBackdropColor(0, 1, 0, 0.3)
            DropIndicator:SetBackdropBorderColor(0, 1, 0, 0.9)
            DropIndicator:Show()
            InsertLine:Hide()
            InsertRowLine:Hide()
        end
    else
        DropIndicator:Hide()
        InsertLine:Hide()
        InsertRowLine:Hide()
    end
end

function ns.CDMGroups.HideDropIndicator()
    DropIndicator:Hide()
    InsertLine:Hide()
    InsertRowLine:Hide()
end

-- DRAG MODE

function ns.CDMGroups.SetDragMode(enabled)
    ns.CDMGroups.dragModeEnabled = enabled
    
    -- Show/hide EditModeContainers overlays based on edit mode state
    if ns.EditModeContainers then
        if enabled then
            -- Edit Mode enabled - show all overlays
            if ns.EditModeContainers.ShowAllWrappersForEditMode then
                ns.EditModeContainers.ShowAllWrappersForEditMode()
            end
        else
            -- Edit Mode disabled - hide overlays (unless Drag Groups toggle is on)
            if ns.EditModeContainers.HideAllWrappersForEditMode then
                ns.EditModeContainers.HideAllWrappersForEditMode()
            end
        end
    end
    
    -- Check showControlButtons setting
    local showControlBtns = true
    local cdmDb = GetCDMGroupsDB()
    if cdmDb then
        local val = cdmDb.showControlButtons
        if val ~= nil then showControlBtns = val end
    end
    
    for groupName, group in pairs(ns.CDMGroups.groups) do
        -- Drag bar removed - we use EditModeContainers overlays now
        -- Just handle control buttons based on edit mode
        if enabled then
            -- Only show control buttons for selected group (if enabled)
            if groupName == ns.CDMGroups.selectedGroup and showControlBtns then
                if group.ShowControlButtons then
                    group.ShowControlButtons()
                end
            else
                if group.HideControlButtons then
                    group.HideControlButtons()
                end
            end
        else
            -- Hide control buttons
            if group.HideControlButtons then
                group.HideControlButtons()
            end
        end
        
        if group.SetMemberDragEnabled then
            group:SetMemberDragEnabled(enabled)
        end
    end
    
    for cdID, data in pairs(ns.CDMGroups.freeIcons) do
        if data.frame then
            if enabled then
                ns.CDMGroups.SetupFreeIconDrag(cdID)
            else
                data.frame:SetScript("OnDragStart", nil)
                data.frame:SetScript("OnDragStop", nil)
                data.frame:SetScript("OnUpdate", nil)
                data.frame:RegisterForDrag()
                data.frame._freeDragging = nil
                
                -- CLICK-THROUGH: Read DB directly to avoid stale cache issues
                local clickThroughEnabled = false
                local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                if db then
                    clickThroughEnabled = db.clickThrough == true
                end
                ApplyClickThrough(data.frame, clickThroughEnabled)
                
                -- Re-enable overlay for right-click when drag mode is disabled
                if data.frame._arcOverlay and ns.CDMEnhance and ns.CDMEnhance.UpdateOverlayStateForFrame then
                    -- Only update overlay if click-through is disabled
                    if not clickThroughEnabled then
                        ns.CDMEnhance.UpdateOverlayStateForFrame(data.frame)
                    end
                end
            end
        end
    end
    
    -- Update selection visuals
    ns.CDMGroups.UpdateGroupSelectionVisuals()
    
    -- Update visibility (combat-only groups should show when editing)
    ns.CDMGroups.UpdateGroupVisibility()
end

-- Update selection visuals for all groups
function ns.CDMGroups.UpdateGroupSelectionVisuals()
    -- Check if options panel is open
    local ACD = LibStub("AceConfigDialog-3.0", true)
    local optionsPanelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
    
    -- PANEL CLOSE DETECTION: When panel transitions from open → closed, 
    -- re-apply tooltip/click-through settings based on saved DB values
    local panelWasOpen = ns.CDMGroups._optionsPanelWasOpen
    if panelWasOpen and not optionsPanelOpen then
        -- Panel just closed - apply saved settings
        if ns.CDMGroups.RefreshIconSettings then
            ns.CDMGroups.RefreshIconSettings()
        end
    end
    ns.CDMGroups._optionsPanelWasOpen = optionsPanelOpen or false
    
    -- Edit mode is ONLY active when ArcUI panel or drag mode is enabled
    -- CDM panel does NOT enable edit mode (it only affects group visibility)
    local editModeActive = ns.CDMGroups.dragModeEnabled or optionsPanelOpen
    
    -- Check showControlButtons setting
    local showControlBtns = true
    local cdmDb = GetCDMGroupsDB()
    if cdmDb then
        local val = cdmDb.showControlButtons
        if val ~= nil then showControlBtns = val end
    end
    
    for groupName, group in pairs(ns.CDMGroups.groups) do
        local isSelected = (groupName == ns.CDMGroups.selectedGroup)
        
        -- CRITICAL: Update container mouse enablement based on edit mode
        -- Container should ALWAYS be click-through when NOT in edit mode
        -- This allows clicking through empty slots while icons remain clickable
        if group.container then
            if editModeActive then
                -- Edit mode active - enable mouse for selection
                group.container:EnableMouse(true)
            else
                -- Edit mode inactive - ALWAYS disable mouse on container
                -- Icons (child frames) still receive clicks
                group.container:EnableMouse(false)
            end
        end
        
        -- Container selection highlight - always hidden (we use drag bar highlight instead)
        if group.selectionHighlight then
            group.selectionHighlight:Hide()
        end
        
        -- DragBar highlight - always used for selection indication
        if group.dragBarHighlight then
            if isSelected and editModeActive then
                group.dragBarHighlight:Show()
            else
                group.dragBarHighlight:Hide()
            end
        end
        
        -- Group title - show for ALL groups when editing
        if group.container and group.container.titleFrame then
            if editModeActive then
                group.container.titleFrame:Show()
            else
                group.container.titleFrame:Hide()
            end
        end
        
        -- Drag toggle button - show for ALL groups when editing (if enabled)
        if group.container and group.container.dragToggleBtn then
            if editModeActive then
                local showHandle = true
                local cdmDb = GetCDMGroupsDB()
                if cdmDb and cdmDb.showDragHandle == false then showHandle = false end
                if showHandle then
                    group.container.dragToggleBtn:Show()
                else
                    group.container.dragToggleBtn:Hide()
                end
            else
                -- Reset state and hide when exiting edit mode
                group.container.dragToggleBtn._active = false
                if group.container.dragToggleBtn.UpdateVisuals then
                    group.container.dragToggleBtn:UpdateVisuals()
                end
                group.container.dragToggleBtn:Hide()
            end
        end
        
        -- Control buttons - only show for selected group in edit mode (if enabled)
        if editModeActive then
            if isSelected and showControlBtns then
                if group.ShowControlButtons then
                    group.ShowControlButtons()
                end
            else
                if group.HideControlButtons then
                    group.HideControlButtons()
                end
            end
        else
            -- CRITICAL: Hide control buttons when edit mode is OFF
            if group.HideControlButtons then
                group.HideControlButtons()
            end
        end
    end
end

-- Update visibility for all groups based on combat/mounted state and options panel
function ns.CDMGroups.UpdateGroupVisibility()
    -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
    if not _cdmGroupsEnabled then return end
    
    -- Check if options panel is open (always show groups when editing)
    local ACD = LibStub("AceConfigDialog-3.0", true)
    local optionsPanelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
    
    -- ALSO check if CDM options panel is open - keep groups visible while configuring
    local cdmPanelOpen = IsCDMOptionsPanelOpen()
    local anyPanelOpen = optionsPanelOpen or cdmPanelOpen
    
    -- Always show when editing or panels open
    local forceShow = anyPanelOpen or ns.CDMGroups.dragModeEnabled
    
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.container then
            local shouldShow = true
            
            -- Handle visibility setting (supports both old string and new table format)
            local vis = group.visibility
            
            if type(vis) == "table" then
                -- NEW: Multi-select table format
                -- Each flag means "hide when this condition is true"
                if vis.hideAlways then
                    shouldShow = false
                else
                    -- Check each hide condition
                    if vis.hideOOC and not ns.CDMGroups.inCombat then
                        shouldShow = false  -- Hide when out of combat
                    end
                    if vis.hideInCombat and ns.CDMGroups.inCombat then
                        shouldShow = false  -- Hide when in combat
                    end
                    if vis.hideMounted and ns.CDMGroups.isMounted then
                        shouldShow = false  -- Hide when mounted
                    end
                end
            else
                -- OLD: String format (backwards compatibility)
                if vis == "combat" then
                    -- "In Combat Only" - hide when NOT in combat
                    shouldShow = ns.CDMGroups.inCombat
                elseif vis == "ooc" then
                    -- "Out of Combat Only" - hide when in combat
                    shouldShow = not ns.CDMGroups.inCombat
                elseif vis == "never" then
                    -- "Always Hidden"
                    shouldShow = false
                end
                -- "always" or nil - always show (shouldShow stays true)
            end
            
            -- Override: always show when editing/configuring
            if forceShow then
                shouldShow = true
            end
            
            if shouldShow then
                group.container:Show()
                -- Also show drag bar if in edit mode
                if ns.CDMGroups.dragModeEnabled and group.dragBar then
                    group.dragBar:Show()
                end
            else
                group.container:Hide()
                -- Also hide drag bar
                if group.dragBar then
                    group.dragBar:Hide()
                end
            end
        end
    end
end

function ns.CDMGroups.ToggleDragMode()
    ns.CDMGroups.SetDragMode(not ns.CDMGroups.dragModeEnabled)
end

-- FRAME WATCHER

-- NOTE: FrameWatcher removed - redundant with MaintenanceTimer + AutoAssignNewIcons

-- NOTE: Options table moved to ArcUI_CDMGroupsOptions.lua

function ns.CDMGroups.PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUI)
    -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
    if not _cdmGroupsEnabled then return end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- ZONE CHANGE OPTIMIZATION: Skip heavy restoration on regular zone changes
    -- Only do full restoration on initial login or UI reload
    -- ═══════════════════════════════════════════════════════════════════════════
    if not isInitialLogin and not isReloadingUI then
        -- Just a zone change (teleport, portal, instance entrance, etc.)
        DebugPrint("|cff00ccff[ZoneChange]|r Zone change detected")
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- CRITICAL FIX: Detect failed spec change during loading screen
        -- When entering a dungeon that auto-swaps your role (e.g., healer → dps),
        -- PLAYER_SPECIALIZATION_CHANGED fires during the loading screen while CDM
        -- viewers are being rebuilt. The spec change handler may fail to properly
        -- reload the profile because frame state is unstable during transitions.
        -- 
        -- We detect this by checking for ANY of these conditions:
        -- 1. Spec mismatch (currentSpec != actual spec)
        -- 2. Spec change flags still set (previous change didn't complete)
        -- 3. Groups exist in profile but are broken at runtime (missing containers)
        -- 4. Recent spec change with no frames assigned
        -- ═══════════════════════════════════════════════════════════════════════════
        local actualSpec = GetCurrentSpec()
        local loadedSpec = ns.CDMGroups.currentSpec
        local needsReload = false
        local reloadReason = nil
        
        -- Check 1: Spec mismatch
        if actualSpec ~= loadedSpec then
            needsReload = true
            reloadReason = "spec mismatch: loaded=" .. tostring(loadedSpec) .. " actual=" .. tostring(actualSpec)
        end
        
        -- Check 2: Spec change flags still set (previous change didn't complete)
        if not needsReload and (ns.CDMGroups.specChangeInProgress or ns.CDMGroups._pendingSpecChange) then
            needsReload = true
            reloadReason = "incomplete spec change detected (flags still set)"
        end
        
        -- Check 3: Groups exist in profile but are broken at runtime
        if not needsReload then
            local specData = GetSpecData()
            local profile = specData and GetActiveProfile(specData)
            if profile and profile.groupLayouts then
                for groupName, layoutData in pairs(profile.groupLayouts) do
                    local group = ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
                    -- Group missing entirely OR missing its container
                    if not group then
                        needsReload = true
                        reloadReason = "broken group: " .. groupName .. " (missing from runtime)"
                        break
                    elseif not group.container then
                        needsReload = true
                        reloadReason = "broken group: " .. groupName .. " (missing container)"
                        break
                    end
                end
            end
        end
        
        -- Check 4: Recent spec change time suggests we're in a failed transition
        if not needsReload and ns.CDMGroups.lastSpecChangeTime then
            local timeSinceSpecChange = GetTime() - ns.CDMGroups.lastSpecChangeTime
            -- If spec change was recent (within 5 seconds) but still has protection active
            if timeSinceSpecChange < 5.0 then
                -- Check if groups have any members with actual frames assigned
                local hasAnyFrames = false
                for _, group in pairs(ns.CDMGroups.groups or {}) do
                    for _, member in pairs(group.members or {}) do
                        if member.frame then
                            hasAnyFrames = true
                            break
                        end
                    end
                    if hasAnyFrames then break end
                end
                if not hasAnyFrames then
                    needsReload = true
                    reloadReason = "recent spec change with no frames assigned (restoration may have failed)"
                end
            end
        end
        
        if needsReload then
            -- Layout issue detected! Use the existing OnSpecChange function to fix it.
            PrintMsg("|cffff8800[ZoneChange]|r Layout issue detected: " .. (reloadReason or "unknown"))
            PrintMsg("|cff00ff00[ZoneChange]|r Triggering full spec change to reload layout...")
            
            -- Clear any stale state from the failed spec change attempt
            ns.CDMGroups.specChangeInProgress = false
            ns.CDMGroups._pendingSpecChange = nil
            ns.CDMGroups.talentChangeInProgress = false
            
            -- Just call the existing OnSpecChange function - it handles everything properly!
            -- Pass loadedSpec as oldSpec so it saves/cleans up correctly, skipSave=true to avoid
            -- overwriting good data with broken state
            if ns.OnSpecChange then
                ns.OnSpecChange(actualSpec, loadedSpec, true)  -- skipSave=true
            elseif OnSpecChange then
                OnSpecChange(actualSpec, loadedSpec, true)  -- skipSave=true
            end
            
            return  -- Don't do regular zone change handling
        end
        
        -- No layout issues detected - normal zone change handling
        DebugPrint("|cff00ccff[ZoneChange]|r Layout OK, skipping full restoration")
        
        -- Update group visibility in case of combat state changes during loading screen
        if ns.CDMGroups.UpdateGroupVisibility then
            ns.CDMGroups.UpdateGroupVisibility()
        end
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- CRITICAL FIX: Refresh all icon styles after zone change
        -- CDM may recreate or reassign frames during loading, and per-icon settings
        -- (borders, textures, colors) won't be applied unless we refresh them.
        -- This fixes the issue where some icons don't get correct settings until
        -- you open the options panel.
        -- ═══════════════════════════════════════════════════════════════════════════
        C_Timer.After(0.5, function()
            if ns.CDMEnhance and ns.CDMEnhance.RefreshAllStyles then
                DebugPrint("|cff00ccff[ZoneChange]|r Refreshing all icon styles")
                ns.CDMEnhance.RefreshAllStyles()
            end
        end)
        
        return  -- Skip all the heavy lifting below
    end
    
    DebugPrint("|cff00ccff[InitialLoad]|r Full restoration: isInitialLogin=", tostring(isInitialLogin), "isReloadingUI=", tostring(isReloadingUI))
    
    -- CRITICAL: Set lastSpecChangeTime to protect restoration period
    -- This prevents Layout() from triggering premature ReflowIcons while frames are still being assigned
    ns.CDMGroups.lastSpecChangeTime = GetTime()
    
    -- Re-check spec on login/reload - GetSpecialization may not have been ready during OnInitialize
    local actualSpec = GetCurrentSpec()  -- Use class-based key like "class_7_spec_2"
    
    if actualSpec ~= ns.CDMGroups.currentSpec then
        -- Spec corrected (silent)
        ns.CDMGroups.currentSpec = actualSpec
        
        -- Re-initialize spec storage and shortcuts
        EnsureSpecTables(actualSpec)
        SetSpecShortcuts(actualSpec)
    end
    
    -- Check if Initialize() already loaded positions
    local positionsAlreadyLoaded = not ns.CDMGroups._profileNotLoaded and next(ns.CDMGroups.savedPositions or {})
    
    -- Initialize active profile from spec data
    local specData = GetSpecData()
    if specData then
        ns.CDMGroups.activeProfile = specData.activeProfile or "Default"
        
        -- ONLY load positions if Initialize() didn't already do it
        if positionsAlreadyLoaded then
            -- Already loaded by Initialize() - skip position loading but continue with restoration
            DebugPrint("|cff00ccff[InitialLoad]|r Positions already loaded by Initialize(), skipping")
        else
            -- ═══════════════════════════════════════════════════════════════════════════
            -- CRITICAL FIX: Use GetProfileSavedPositions to load savedPositions
            -- This handles ALL edge cases: profile creation, migration, reference setup
            -- ═══════════════════════════════════════════════════════════════════════════
            local loadedCount = 0
            local profileSavedPositions = GetProfileSavedPositions()
            if profileSavedPositions then
                for cdID, data in pairs(profileSavedPositions) do
                    loadedCount = loadedCount + 1
                    -- Hook for tracker
                    local SaveTracker = (_G.ArcUI_NS and _G.ArcUI_NS.SaveTracker) or (_G.ArcUI and _G.ArcUI.SaveTracker) or _G.ArcUI_SaveTracker
                    if SaveTracker and SaveTracker.OnPositionLoad then
                        SaveTracker.OnPositionLoad(cdID, data.target, data.row, data.col, "PLAYER_ENTERING_WORLD")
                    end
                end
            end
            
            DebugPrint("|cff00ccff[InitialLoad]|r Loaded", loadedCount, "positions from PROFILE (direct reference)")
            
            -- Get profile for freeIcons and iconSettings handling
            local activeProfileName = specData.activeProfile or "Default"
            local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
            
            -- Also sync freeIcons from profile
            wipe(ns.CDMGroups.freeIcons)
            if profile and profile.freeIcons and next(profile.freeIcons) then
                for cdID, data in pairs(profile.freeIcons) do
                    ns.CDMGroups.freeIcons[cdID] = DeepCopy(data)
                end
                -- NOTE: Do NOT write to specData.freeIcons - that creates duplicate storage
                -- Data lives only in profile.freeIcons
            elseif specData.freeIcons and next(specData.freeIcons) then
                -- Legacy migration: copy from specData to runtime and profile
                for cdID, data in pairs(specData.freeIcons) do
                    ns.CDMGroups.freeIcons[cdID] = DeepCopy(data)
                end
                if profile then
                    profile.freeIcons = DeepCopy(ns.CDMGroups.freeIcons)
                end
            end
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- CRITICAL: Set up iconSettings as DIRECT REFERENCE to profile's table
            -- This ensures CDMEnhance writes go directly to the profile
            -- Same pattern as savedPositions above
            -- ═══════════════════════════════════════════════════════════════════════════
            if profile then
                -- Ensure profile has iconSettings table
                if not profile.iconSettings then
                    profile.iconSettings = {}
                end
                -- MIGRATION: Copy any existing specData.iconSettings to profile
                if specData.iconSettings and next(specData.iconSettings) then
                    local migratedCount = 0
                    for cdID, settings in pairs(specData.iconSettings) do
                        if not profile.iconSettings[cdID] then
                            profile.iconSettings[cdID] = DeepCopy(settings)
                            migratedCount = migratedCount + 1
                        end
                    end
                    -- Clean up legacy storage after migration
                    specData.iconSettings = nil
                    if migratedCount > 0 then
                        PrintMsg("|cff00ff00[InitialLoad]|r Migrated " .. migratedCount .. " iconSettings to profile")
                    end
                    PrintMsg("|cffff8800[InitialLoad]|r Cleared legacy specData.iconSettings")
                end
                -- NOTE: iconSettings is now accessed via Shared.GetSpecIconSettings()
                -- which returns profile.iconSettings directly - no reference needed
                DebugPrint("|cff00ccff[InitialLoad]|r iconSettings stored in profile.iconSettings")
            end
            
            -- CRITICAL: Mark profile as loaded - now force saves are allowed for NEW icons
            ns.CDMGroups._profileNotLoaded = false
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- VERIFY: Ensure savedPositions reference was properly established
            -- ═══════════════════════════════════════════════════════════════════════════
            if VerifyDirectReference then
                local isValid, errorMsg = VerifyDirectReference(true)  -- auto-repair if needed
                if not isValid then
                    DebugPrint("|cffff0000[InitialLoad]|r Direct reference verification failed:", errorMsg)
                end
            end
        end  -- End of position loading (else branch)
    end  -- End of if specData
    
    -- Debug: Show what we're loading on initial login (same format as LoadProfile)
    DebugPrint("|cff00ccff[InitialLoad]|r Loading spec", ns.CDMGroups.currentSpec, "profile:", ns.CDMGroups.activeProfile)
    DebugPrint("|cff00ccff[InitialLoad]|r savedPositions:")
    local posCount = 0
    for cdID, pos in pairs(ns.CDMGroups.savedPositions) do
        posCount = posCount + 1
        local posInfo = pos.type == "group" and (pos.target .. "[" .. (pos.row or "?") .. "," .. (pos.col or "?") .. "]") or "FREE"
        DebugPrint("|cff00ccff[InitialLoad]|r   ", cdID, "->", posInfo)
    end
    local freeCount = 0
    if specData and specData.freeIcons then
        for cdID, data in pairs(specData.freeIcons) do
            freeCount = freeCount + 1
            DebugPrint("|cff00ccff[InitialLoad]|r   freeIcon:", cdID, "x:", math.floor(data.x), "y:", math.floor(data.y))
        end
    end
    DebugPrint("|cff00ccff[InitialLoad]|r Total:", posCount, "positions,", freeCount, "freeIcons")
    
    -- Detect if this is a truly fresh start (no saved data at all)
    local isFreshStart = (posCount == 0 and freeCount == 0)
    
    -- Now do the normal initialization with correct spec
    C_Timer.After(0.5, function()
        -- ═══════════════════════════════════════════════════════════════════════════
        -- FRESH START vs RELOAD: Different grid expansion behavior
        -- - Fresh start (first time ever): Allow groups to expand to fit all icons
        --   This gives users a sensible default layout where each CDM viewer type
        --   (cooldowns, utility, auras) fits neatly into its respective group.
        -- - Reload/existing data: Block expansion to preserve user's saved layout.
        --   We don't want groups randomly growing when restoring positions.
        -- ═══════════════════════════════════════════════════════════════════════════
        if isFreshStart then
            DebugPrint("|cff00ccff[InitialLoad]|r Fresh start detected - allowing grid expansion")
            ns.CDMGroups.blockGridExpansion = false
        else
            DebugPrint("|cff00ccff[InitialLoad]|r Existing data found - blocking grid expansion")
            ns.CDMGroups.blockGridExpansion = true
        end
        
        -- Get spec data (creates defaults if needed)
        local specData = EnsureSpecData(ns.CDMGroups.currentSpec)
        
        -- Fallback if specData is nil (shouldn't happen)
        if not specData then
            print("|cffff0000CDMGroups|r: Error - could not get spec data")
            return
        end
        
        -- Only create groups if none exist yet
        if not next(ns.CDMGroups.groups) then
            -- Create groups from PROFILE.groupLayouts (single source of truth)
            local profile = GetActiveProfile(specData)
            local groupsToCreate = (profile and profile.groupLayouts) or DEFAULT_GROUPS
            for groupName, _ in pairs(groupsToCreate) do
                ns.CDMGroups.CreateGroup(groupName)
            end
        end
        
        ns.CDMGroups.ScanAllViewers()
        
        -- NOTE: We intentionally do NOT delete savedPositions for "invalid" cooldownIDs
        -- They may become valid again when user re-talents the ability
        -- The savedPositions persist so layout restores when ability returns
        
        -- MIGRATION: Convert old CDMEnhance free positions to CDMGroups free icons
        -- This runs once per spec - check if we've already migrated
        if not specData.migratedFromCDMEnhance then
            local migratedCount = 0
            -- Check if CDMEnhance iconSettings exist with free positions
            -- CRITICAL: Old data is at ns.db.profile.cdmEnhance.iconSettings, NOT ns.db.profile.iconSettings
            if ns.db and ns.db.profile and ns.db.profile.cdmEnhance and ns.db.profile.cdmEnhance.iconSettings then
                for key, settings in pairs(ns.db.profile.cdmEnhance.iconSettings) do
                    if settings and settings.position and settings.position.mode == "free" then
                        -- Parse cooldownID from key (it's stored as string)
                        local cdID = tonumber(key)
                        if cdID and ns.CDMGroups.IsCooldownIDValid(cdID) then
                            -- Get verified profile savedPositions table
                            local profileSavedPositions = GetProfileSavedPositions()
                            -- Check if not already tracked
                            if profileSavedPositions and not profileSavedPositions[cdID] and not ns.CDMGroups.freeIcons[cdID] then
                                local x = settings.position.freeX or 0
                                local y = settings.position.freeY or 0
                                local iconSize = settings.iconSize or 36
                                
                                -- Save as free icon in CDMGroups system
                                local posData = {
                                    type = "free",
                                    x = x,
                                    y = y,
                                    iconSize = iconSize,
                                }
                                profileSavedPositions[cdID] = posData
                                SavePositionToSpec(cdID, posData)
                                
                                -- NOTE: SavePositionToSpec already writes to profile.freeIcons
                                -- No need to also write to specData.freeIcons (legacy location)
                                
                                migratedCount = migratedCount + 1
                                PrintMsg("Migrated free icon cdID " .. cdID .. " to CDMGroups")
                            end
                        end
                    end
                end
            end
            
            -- Mark as migrated
            specData.migratedFromCDMEnhance = true
            if migratedCount > 0 then
                PrintMsg("Migrated " .. migratedCount .. " free icons from CDMEnhance")
            end
        end
        
        -- Restore saved free icons from spec data
        if specData.freeIcons then
            for cdID, data in pairs(specData.freeIcons) do
                -- Check if freeIcon entry doesn't have a frame yet (data may exist from Initialize but without frame)
                local existingEntry = ns.CDMGroups.freeIcons[cdID]
                local needsRestore = not existingEntry or not existingEntry.frame
                if data.x and data.y and needsRestore and ns.CDMGroups.IsCooldownIDValid(cdID) then
                    ns.CDMGroups.TrackFreeIcon(cdID, data.x, data.y, data.iconSize)
                end
            end
        end
        
        -- Restore saved group positions from spec data
        RestoreSavedGroupPositions()
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- CLEANUP: Remove legacy specData.groups after migration
        -- Groups are now stored in profile.groupLayouts, not at spec level
        -- We keep this cleanup here to remove redundant data from old SavedVariables
        -- ═══════════════════════════════════════════════════════════════════════════
        if specData.groups then
            PrintMsg("|cffff8800[Cleanup]|r Cleared legacy specData.groups")
            specData.groups = nil
        end
        
        -- CLEANUP: Remove specData.arcAuras if present - arcAuras is character-wide, not per-spec
        -- This was accidentally created by some migration code
        if specData.arcAuras then
            PrintMsg("|cffff8800[Cleanup]|r Cleared legacy specData.arcAuras")
            specData.arcAuras = nil
        end
        
        -- CLEANUP: Remove legacy specData.savedPositions if present
        -- All position data should be in profile.savedPositions (inside layoutProfiles), not at spec level
        if specData.savedPositions then
            PrintMsg("|cffff8800[Cleanup]|r Cleared legacy specData.savedPositions")
            specData.savedPositions = nil
        end
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- CLEANUP: Remove legacy specData.iconSettings
        -- Per-icon settings are now stored in profile.iconSettings and accessed via
        -- Shared.GetSpecIconSettings() which returns profile.iconSettings directly
        -- No specData.iconSettings reference needed
        -- ═══════════════════════════════════════════════════════════════════════════
        local activeProfileName = specData.activeProfile or "Default"
        local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
        if profile then
            -- Ensure profile.iconSettings exists
            if not profile.iconSettings then
                profile.iconSettings = {}
            end
            -- Migrate any legacy specData.iconSettings to profile
            if specData.iconSettings and specData.iconSettings ~= profile.iconSettings then
                local migratedCount = 0
                for cdID, settings in pairs(specData.iconSettings) do
                    if not profile.iconSettings[cdID] then
                        profile.iconSettings[cdID] = DeepCopy(settings)
                        migratedCount = migratedCount + 1
                    end
                end
                if migratedCount > 0 then
                    PrintMsg("|cff00ff00[Cleanup]|r Migrated " .. migratedCount .. " iconSettings to profile")
                end
            end
            -- Clean up legacy storage
            if specData.iconSettings then
                PrintMsg("|cffff8800[Cleanup]|r Cleared legacy specData.iconSettings")
                specData.iconSettings = nil
            end
        end
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- CLEANUP: Remove spec-level freeIcons - this is legacy data
        -- Runtime freeIcons are managed by ns.CDMGroups.freeIcons (not specData.freeIcons)
        -- The actual saved data lives in profile.freeIcons
        -- ═══════════════════════════════════════════════════════════════════════════
        if specData.freeIcons and specData.layoutProfiles then
            if profile and profile.freeIcons then
                PrintMsg("|cffff8800[Cleanup]|r Cleared legacy specData.freeIcons")
                specData.freeIcons = nil
            end
        end
        
        C_Timer.After(0.5, function()
            ns.CDMGroups.AutoAssignNewIcons()
            
            -- Check if restoration is complete and end protection early
            CheckRestorationComplete()
            
            -- Unblock grid expansion after restoration complete
            C_Timer.After(0.5, function()
                ns.CDMGroups.blockGridExpansion = false
                -- Final check to end protection
                CheckRestorationComplete()
                -- CRITICAL: Clear initial load flag - saves are now allowed
                ns.CDMGroups.initialLoadInProgress = false
                
                -- CRITICAL: Block profile saves for 3 seconds after initial load
                -- This prevents auto-save from overwriting profile data during restoration
                ns.CDMGroups._profileSaveBlockedUntil = GetTime() + 3.0
                
                -- Trigger CDMEnhance to apply settings to all frames
                if ns.CDMEnhance and ns.CDMEnhance.RefreshAllIcons then
                    ns.CDMEnhance.RefreshAllIcons()
                end
                
                -- Apply tooltip/click-through settings to all icons
                ns.CDMGroups.RefreshIconSettings()
                
                -- ═══════════════════════════════════════════════════════════════════════════
                -- CRITICAL FIX: Apply per-icon SIZE settings from GetEffectiveIconSettings
                -- RefreshAllIcons/RefreshIconSettings only apply visual styles (borders, glow)
                -- RefreshAllGroupLayouts applies size/scale via SetupFrameInContainer
                -- Without this, icons don't get their custom sizes until options panel opens!
                -- ═══════════════════════════════════════════════════════════════════════════
                if ns.CDMGroups.RefreshAllGroupLayouts then
                    ns.CDMGroups.RefreshAllGroupLayouts()
                end
                
                -- Final layout of all groups
                for _, group in pairs(ns.CDMGroups.groups) do
                    if group.Layout then group:Layout() end
                end
                
                -- Initialize combat and mounted state and update visibility
                ns.CDMGroups.inCombat = InCombatLockdown()
                ns.CDMGroups.isMounted = IsMounted()
                ns.CDMGroups.UpdateGroupVisibility()
                
                -- CRITICAL: Ensure container click-through state is correct on initial load
                -- This makes empty slots click-through when options panel is closed
                ns.CDMGroups.UpdateGroupSelectionVisuals()
                
                -- Debug: Show how many icons were restored
                local groupIconCount = 0
                for _, group in pairs(ns.CDMGroups.groups) do
                    for _ in pairs(group.members or {}) do groupIconCount = groupIconCount + 1 end
                end
                local freeIconCount = 0
                for _ in pairs(ns.CDMGroups.freeIcons) do freeIconCount = freeIconCount + 1 end
                DebugPrint("|cff00ccff[InitialLoad]|r Complete - restored", groupIconCount, "group icons,", freeIconCount, "free icons")
                
                -- Check if talents match a different profile
                C_Timer.After(0.2, function()
                    ns.CDMGroups.CheckAndActivateMatchingProfile()
                end)
                
                -- Schedule a reflow AFTER the restoration window completes
                -- This compacts any gaps once all frames have stabilized (same as spec change)
                C_Timer.After(2.0, function()
                    DebugPrint("|cff00ccff[InitialLoad]|r Post-restoration reflow starting")
                    -- Clear lastSpecChangeTime so IsRestoring returns false
                    ns.CDMGroups.lastSpecChangeTime = nil
                    
                    -- Now reflow is safe
                    for _, group in pairs(ns.CDMGroups.groups) do
                        if group.autoReflow and group.ReflowIcons then
                            group:ReflowIcons()
                        end
                    end
                    DebugPrint("|cff00ccff[InitialLoad]|r Post-restoration reflow complete")
                    
                    -- ═══════════════════════════════════════════════════════════════════════════
                    -- CRITICAL: First-Time Position Save for brand new profiles
                    -- Moved to AFTER reflow (t=3.0) so icons have definitely been assigned
                    -- If the profile has ZERO saved positions but we have icons in groups,
                    -- save all current positions so they persist across reloads.
                    -- ═══════════════════════════════════════════════════════════════════════════
                    local groupIconCount = 0
                    for _, group in pairs(ns.CDMGroups.groups) do
                        for _ in pairs(group.members or {}) do groupIconCount = groupIconCount + 1 end
                    end
                    local freeIconCount = 0
                    for _ in pairs(ns.CDMGroups.freeIcons) do freeIconCount = freeIconCount + 1 end
                    
                    local profileSavedPositions = GetProfileSavedPositions and GetProfileSavedPositions()
                    local hasSavedPositions = profileSavedPositions and next(profileSavedPositions)
                    local hasIconsToSave = groupIconCount > 0 or freeIconCount > 0
                    
                    -- First-time save for brand new profiles
                    if not hasSavedPositions and hasIconsToSave then
                        local savedCount = 0
                        
                        -- Save all group member positions
                        for groupName, group in pairs(ns.CDMGroups.groups) do
                            if group.members then
                                for cdID, member in pairs(group.members) do
                                    if member.frame then
                                        local positionData = {
                                            type = "group",
                                            target = groupName,
                                            row = member.row or 0,
                                            col = member.col or 0,
                                            viewerType = member.viewerType,
                                        }
                                        if profileSavedPositions then
                                            profileSavedPositions[cdID] = positionData
                                        end
                                        if SavePositionToSpec then
                                            SavePositionToSpec(cdID, positionData)
                                        end
                                        savedCount = savedCount + 1
                                    end
                                end
                            end
                        end
                        
                        -- Save all free icon positions
                        for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
                            if data.frame then
                                local positionData = {
                                    type = "free",
                                    x = data.x or 0,
                                    y = data.y or 0,
                                    iconSize = data.iconSize or 36,
                                    viewerType = data.viewerType,
                                }
                                if profileSavedPositions then
                                    profileSavedPositions[cdID] = positionData
                                end
                                if SavePositionToSpec then
                                    SavePositionToSpec(cdID, positionData)
                                end
                                savedCount = savedCount + 1
                            end
                        end
                    end
                end)
            end)
        end)
        
        -- Update last active spec
        local cdmDb = GetCDMGroupsDB()
        if cdmDb then cdmDb.lastActiveSpec = ns.CDMGroups.currentSpec end
        
        local specName = ns.CDMGroups.currentSpec
        if GetSpecializationInfo then
            local specIndex = GetSpecialization() or 1  -- Use numeric index for API
            local _, name = GetSpecializationInfo(specIndex)
            if name then specName = name end
        end
        print("|cff00ff00CDMGroups|r loaded for " .. specName .. ". /cdmg for options.")
    end)
end

function ns.CDMGroups.PLAYER_SPECIALIZATION_CHANGED()
    -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
    if not _cdmGroupsEnabled then return end
    
    -- IMMEDIATELY freeze Layout() to prevent corruption during the transition window
    ns.CDMGroups.lastSpecChangeTime = GetTime()
    ns.CDMGroups.specChangeInProgress = true
    
    local oldSpec = ns.CDMGroups.currentSpec
    local newSpec = GetCurrentSpec()
    
    DebugPrint("|cffff00ff[SpecChange]|r PLAYER_SPECIALIZATION_CHANGED:", oldSpec, "->", newSpec)
    
    -- Skip if same spec (can happen with talent changes)
    if oldSpec == newSpec then
        DebugPrint("|cffff00ff[SpecChange]|r Same spec, ignoring")
        ns.CDMGroups.specChangeInProgress = false
        return
    end
    
    -- Increment sequence number to invalidate any pending timers
    ns.CDMGroups._specChangeSeq = (ns.CDMGroups._specChangeSeq or 0) + 1
    local mySeq = ns.CDMGroups._specChangeSeq
    DebugPrint("|cffff00ff[SpecChange]|r Sequence:", mySeq)
    
    -- CRITICAL: Save old spec state TO PROFILE IMMEDIATELY, BEFORE CDM reassigns frames
    -- This must happen NOW while frames still have their correct cooldownIDs
    if ns.CDMGroups.specGroups[oldSpec] and next(ns.CDMGroups.specGroups[oldSpec]) then
        local specData = EnsureSpecData(oldSpec)
        if specData then
            -- Save group LAYOUTS to profile.groupLayouts (NOT to specData.groups)
            EnsureLayoutProfiles(specData)
            local activeProfileName = specData.activeProfile or "Default"
            local profile = specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
            
            if profile then
                if not profile.groupLayouts then
                    profile.groupLayouts = {}
                end
                
                -- Save each group's layout (NO runtime data like grid/members)
                for groupName, group in pairs(ns.CDMGroups.specGroups[oldSpec]) do
                    profile.groupLayouts[groupName] = SerializeGroupToLayoutData(group)
                end
                
                -- Save free icons to profile (NOT to specData.freeIcons)
                if not profile.freeIcons then
                    profile.freeIcons = {}
                end
                for cdID, data in pairs(ns.CDMGroups.specFreeIcons[oldSpec] or {}) do
                    profile.freeIcons[cdID] = { x = data.x, y = data.y, iconSize = data.iconSize }
                end
            end
            
            -- NOTE: savedPositions IS the profile.savedPositions (direct reference)
            -- Already correct from user drag operations - no rebuild needed
            
            DebugPrint("|cffff00ff[SpecChange]|r Saved spec", oldSpec, "state to profile immediately")
        end
    end
    
    -- CRITICAL: Release ALL frames back to CDM IMMEDIATELY
    -- CDM cannot properly reassign/destroy frames that we've reparented
    -- We must give them back so CDM can do its lifecycle management
    DebugPrint("|cffff00ff[SpecChange]|r Releasing all frames back to CDM...")
    
    local framesReleased = 0
    
    -- Release group member frames
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        for cdID, member in pairs(group.members or {}) do
            if member.frame then
                -- Return frame to original CDM viewer
                ReturnFrameToCDM(member.frame, member.entry)
                framesReleased = framesReleased + 1
            end
            -- Clear frame references but keep member positions for restoration
            member.frame = nil
            member.entry = nil
        end
    end
    
    -- Release free icon frames
    for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
        if data.frame then
            -- Return to CDM
            local originalParent = data.originalParent or (data.entry and data.entry.originalParent)
            if originalParent then
                data.frame:SetParent(originalParent)
            end
            data.frame:ClearAllPoints()
            data.frame:Show()
            framesReleased = framesReleased + 1
        end
        -- Clear frame reference
        data.frame = nil
        data.entry = nil
    end
    
    DebugPrint("|cffff00ff[SpecChange]|r Released", framesReleased, "frames back to CDM")
    
    DebugPrint("|cffff00ff[SpecChange]|r Waiting 0.8s for CDM to reassign frames...")
    
    -- Wait for CDM to finish frame reassignment, then complete the switch
    -- Use closure to capture oldSpec/newSpec/sequence to handle race conditions
    C_Timer.After(0.8, function()
        DebugPrint("|cffff00ff[SpecChange]|r Timer callback executing... seq:", mySeq, "current:", ns.CDMGroups._specChangeSeq)
        
        -- Check if this spec change was superseded by a newer one
        if ns.CDMGroups._specChangeSeq ~= mySeq then
            DebugPrint("|cffff00ff[SpecChange]|r Superseded by newer spec change, ignoring")
            return
        end
        
        DebugPrint("|cffff00ff[SpecChange]|r Timer fired, calling OnSpecChange for", oldSpec, "->", newSpec)
        OnSpecChange(newSpec, oldSpec, true)  -- skipSave = true
    end)
end

-- ===================================================================
-- PUBLIC API FOR CDMENHANCE INTEGRATION
-- ===================================================================

-- Check if a cooldownID is managed by CDMGroups (in a group or free positioned)
function ns.CDMGroups.IsManaged(cooldownID)
    if not cooldownID then return false, nil end
    
    -- Check groups
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        if group.members and group.members[cooldownID] then
            return true, "group"
        end
    end
    
    -- Check free icons
    if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cooldownID] then
        return true, "free"
    end
    
    return false, nil
end

-- Get all grouped frames (for scanner integration)
function ns.CDMGroups.GetAllGroupedFrames()
    local result = {}
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        for cdID, member in pairs(group.members or {}) do
            if member.frame then
                -- Get viewerType from entry or Registry
                local viewerType = member.viewerType
                local originalViewerName = member.originalViewerName
                
                if not viewerType and member.entry then
                    viewerType = member.entry.viewerType
                    originalViewerName = member.entry.viewerName
                end
                
                -- Fallback: determine from CDM API (safe for string IDs)
                if not viewerType then
                    local vt, _ = Shared.GetViewerTypeFromCooldownID(cdID)
                    viewerType = vt
                end
                
                result[cdID] = {
                    frame = member.frame,
                    groupName = groupName,
                    gridPosition = { row = member.row, col = member.col },
                    viewerType = viewerType or "aura",
                    originalViewerName = originalViewerName,
                }
            end
        end
    end
    return result
end

-- Get all free positioned icons (for scanner integration)
function ns.CDMGroups.GetFreeIcons()
    local result = {}
    for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
        if data.frame then
            -- Get viewerType with fallback (safe for string IDs)
            local viewerType = data.viewerType
            if not viewerType then
                local vt, _ = Shared.GetViewerTypeFromCooldownID(cdID)
                viewerType = vt
            end
            
            result[cdID] = {
                frame = data.frame,
                x = data.x,
                y = data.y,
                viewerType = viewerType or "aura",
                originalViewerName = data.originalViewerName,
            }
        end
    end
    return result
end

-- Select a group and navigate to its options panel
function ns.CDMGroups.SelectGroupForOptions(groupName)
    if not groupName then return end
    
    -- Select the group FIRST
    ns.CDMGroups.selectedGroup = groupName
    ns.CDMGroups.UpdateGroupSelectionVisuals()
    
    local ACD = LibStub("AceConfigDialog-3.0", true)
    if not ACD then return end
    
    -- Check if panel is already open
    local panelWasOpen = ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
    
    if not panelWasOpen then
        -- Panel not open - open it first
        ACD:Open("ArcUI")
    end
    
    -- Refresh the options to show updated selection
    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    
    -- Navigate to Icon Groups panel (path: Icons (CDM) -> Groups)
    ACD:SelectGroup("ArcUI", "icons", "iconGroups")
end

-- ===================================================================
-- ARCUI INTEGRATION - INITIALIZATION
-- ===================================================================

-- Create event frame for initialization
local CDMGroupsInitFrame = CreateFrame("Frame")
local cdmGroupsInitialized = false

-- CRITICAL FIX: Try to initialize as EARLY as possible
-- The old 1.5s delay caused FrameController to assign frames before profile loaded!
local function TryInitialize()
    if cdmGroupsInitialized then return end
    
    
    if ns.db then
        -- Database is ready - initialize immediately!
        ns.CDMGroups.Initialize()
        cdmGroupsInitialized = true
    else
        -- Database not ready yet - retry quickly
        C_Timer.After(0.1, TryInitialize)
    end
end

CDMGroupsInitFrame:RegisterEvent("ADDON_LOADED")
CDMGroupsInitFrame:RegisterEvent("PLAYER_LOGIN")
CDMGroupsInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
CDMGroupsInitFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
CDMGroupsInitFrame:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED")
CDMGroupsInitFrame:RegisterEvent("COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED")
CDMGroupsInitFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
CDMGroupsInitFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entering combat
CDMGroupsInitFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Leaving combat
CDMGroupsInitFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")  -- Mounting/dismounting

CDMGroupsInitFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        -- Try to initialize when ArcUI loads (ns.db should be available soon after)
        if addonName == "ArcUI" then
            -- Start trying to initialize immediately
            C_Timer.After(0, TryInitialize)  -- Next frame
            C_Timer.After(0.1, TryInitialize)  -- 100ms
            C_Timer.After(0.3, TryInitialize)  -- 300ms (fallback)
        end
    elseif event == "PLAYER_LOGIN" then
        -- Fallback: If not initialized by PLAYER_LOGIN, try again
        if not cdmGroupsInitialized then
            TryInitialize()
            -- Also schedule a few more retries just in case
            C_Timer.After(0.5, TryInitialize)
            C_Timer.After(1.0, TryInitialize)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUI = ...
        -- Only handle if already initialized (or wait for Initialize to call it)
        if cdmGroupsInitialized and ns.CDMGroups.PLAYER_ENTERING_WORLD then
            ns.CDMGroups.PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUI)
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if cdmGroupsInitialized and ns.CDMGroups.PLAYER_SPECIALIZATION_CHANGED then
            ns.CDMGroups.PLAYER_SPECIALIZATION_CHANGED(ns.CDMGroups, ...)
        end
    elseif event == "TRAIT_CONFIG_UPDATED" then
        -- Delegate to StateManager
        if cdmGroupsInitialized and ns.CDMGroups.StateManager and ns.CDMGroups.StateManager.OnTalentConfigUpdated then
            ns.CDMGroups.StateManager.OnTalentConfigUpdated()
        end
    elseif event == "COOLDOWN_VIEWER_DATA_LOADED" or event == "COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED" then
        -- Delegate to StateManager
        if cdmGroupsInitialized and ns.CDMGroups.StateManager and ns.CDMGroups.StateManager.OnCooldownViewerDataLoaded then
            ns.CDMGroups.StateManager.OnCooldownViewerDataLoaded()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        ns.CDMGroups.inCombat = true
        ns.CDMGroups.UpdateGroupVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat
        ns.CDMGroups.inCombat = false
        ns.CDMGroups.UpdateGroupVisibility()
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        -- Mounting or dismounting
        ns.CDMGroups.isMounted = IsMounted()
        ns.CDMGroups.UpdateGroupVisibility()
    end
end)

-- Main initialization function (called after database is ready)
function ns.CDMGroups.Initialize()
    
    if not ns.db then
        print("|cffff0000ArcUI CDMGroups|r: Database not ready!")
        return
    end
    
    -- CRITICAL: Sync global and char enabled states FIRST
    -- This ensures the options toggle and runtime checks use the same value
    if ns.CDMShared and ns.CDMShared.SyncCDMStylingEnabled then
        ns.CDMShared.SyncCDMStylingEnabled()
    end
    
    -- CRITICAL: Initialize cached enabled state now that DB is ready
    RefreshCachedEnabledState()
    
    -- Ensure default Group Template exists for first-time users
    if ns.CDMImportExport and ns.CDMImportExport.EnsureDefaultTemplate then
        ns.CDMImportExport.EnsureDefaultTemplate()
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- MIGRATION: Profile -> Character Storage
    -- Old data was stored in ns.db.profile.cdmGroups (shared across all characters)
    -- New data is stored in ns.db.char.cdmGroups (per-character)
    -- 
    -- IMPORTANT: Only migrate for characters that existed BEFORE per-char storage.
    -- New characters should start fresh with empty layouts.
    -- We track which characters have been "initialized" to distinguish old vs new.
    -- ═══════════════════════════════════════════════════════════════════════════
    
    -- Ensure char table exists
    if not ns.db.char then ns.db.char = {} end
    
    -- Get character identifier
    local charName = UnitName("player") or "Unknown"
    local realmName = GetRealmName() or "Unknown"
    local charKey = charName .. "-" .. realmName
    
    -- Initialize profile tracking tables if missing
    if ns.db.profile.cdmGroups then
        if not ns.db.profile.cdmGroups.initializedCharacters then
            ns.db.profile.cdmGroups.initializedCharacters = {}
        end
    end
    
    -- Check if we need to migrate from profile to char
    local hasProfileData = ns.db.profile and ns.db.profile.cdmGroups and ns.db.profile.cdmGroups.specData
    local alreadyHasCharData = ns.db.char.cdmGroups and ns.db.char.cdmGroups.migratedFromProfile
    local isKnownCharacter = hasProfileData and ns.db.profile.cdmGroups.initializedCharacters[charKey]
    
    -- Determine if this character should get migration:
    -- - If they already have char data → no action needed
    -- - If they're a "known" character (logged in before) → they already got their data
    -- - If they're a NEW character (not known) AND other characters exist → start fresh
    -- - If they're the FIRST character to log in → migrate (they're the "owner" of the old data)
    local otherCharactersExist = false
    if hasProfileData and ns.db.profile.cdmGroups.initializedCharacters then
        for _ in pairs(ns.db.profile.cdmGroups.initializedCharacters) do
            otherCharactersExist = true
            break
        end
    end
    
    local shouldMigrate = hasProfileData and not alreadyHasCharData and not isKnownCharacter and not otherCharactersExist
    
    if shouldMigrate then
        PrintMsg("Migrating CDMGroups data from profile to character storage...")
        
        -- Initialize char storage
        ns.db.char.cdmGroups = {
            specData = {},
            specInheritedFrom = {},
            lastActiveSpec = nil,
            migratedOldKeys = {},
            migratedFromProfile = true,
            -- Settings
            enabled = ns.db.profile.cdmGroups.enabled ~= false,
            showBorderInEditMode = ns.db.profile.cdmGroups.showBorderInEditMode ~= false,  -- Default to true
            showControlButtons = ns.db.profile.cdmGroups.showControlButtons ~= false,
            disableTooltips = ns.db.profile.cdmGroups.disableTooltips or false,
            clickThrough = ns.db.profile.cdmGroups.clickThrough or false,
        }
        
        -- Copy spec data for THIS character's class only
        local _, _, classID = UnitClass("player")
        classID = classID or 0
        local classPrefix = "class_" .. classID .. "_"
        
        -- FIRST: Migrate string-keyed spec data (new format: "class_7_spec_2")
        for specKey, specData in pairs(ns.db.profile.cdmGroups.specData) do
            -- Only migrate data for this character's class
            if type(specKey) == "string" and specKey:find(classPrefix) then
                ns.db.char.cdmGroups.specData[specKey] = DeepCopy(specData)
                PrintMsg("  Migrated " .. specKey)
            end
        end
        
        -- SECOND: Migrate numeric-keyed spec data (old format: 1, 2, 3, 4)
        -- These need to be converted to class-based keys
        for i = 1, 4 do
            local oldSpecData = ns.db.profile.cdmGroups.specData[i]
            if oldSpecData then
                local newKey = "class_" .. classID .. "_spec_" .. i
                -- Only migrate if target doesn't already exist
                if not ns.db.char.cdmGroups.specData[newKey] then
                    ns.db.char.cdmGroups.specData[newKey] = DeepCopy(oldSpecData)
                    PrintMsg("  Migrated spec " .. i .. " -> " .. newKey)
                    -- Mark as migrated so the later numeric key migration doesn't duplicate
                    ns.db.char.cdmGroups.migratedOldKeys[i] = newKey
                end
            end
        end
        
        -- Copy inheritance tracking for this class
        if ns.db.profile.cdmGroups.specInheritedFrom then
            for specKey, inheritedFrom in pairs(ns.db.profile.cdmGroups.specInheritedFrom) do
                if type(specKey) == "string" and specKey:find(classPrefix) then
                    ns.db.char.cdmGroups.specInheritedFrom[specKey] = inheritedFrom
                end
            end
        end
        
        PrintMsg("Migration complete! Character-specific layouts now active.")
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- CLEANUP: Remove old profile storage for this class to prevent ghost groups
        -- This ensures no stale data can be read from the old location
        -- ═══════════════════════════════════════════════════════════════════════════
        if ns.db.profile.cdmGroups.specData then
            local cleanedCount = 0
            -- Clean string keys for this class
            for specKey, _ in pairs(ns.db.profile.cdmGroups.specData) do
                if type(specKey) == "string" and specKey:find(classPrefix) then
                    ns.db.profile.cdmGroups.specData[specKey] = nil
                    cleanedCount = cleanedCount + 1
                end
            end
            -- Clean numeric keys (old format) - these belong to current character
            for i = 1, 4 do
                if ns.db.profile.cdmGroups.specData[i] then
                    ns.db.profile.cdmGroups.specData[i] = nil
                    cleanedCount = cleanedCount + 1
                end
            end
            if cleanedCount > 0 then
                PrintMsg("  Cleaned up " .. cleanedCount .. " old profile entries")
            end
        end
    elseif not alreadyHasCharData and not isKnownCharacter then
        -- New character - start fresh, no migration
        PrintMsg("New character detected - starting with fresh layout")
    end
    
    -- Mark this character as initialized (so future logins don't try to migrate)
    if hasProfileData and ns.db.profile.cdmGroups.initializedCharacters then
        ns.db.profile.cdmGroups.initializedCharacters[charKey] = true
    end
    
    -- If this character already had char data (from previous migration), make sure they're in the list
    if alreadyHasCharData and hasProfileData and ns.db.profile.cdmGroups.initializedCharacters then
        if not ns.db.profile.cdmGroups.initializedCharacters[charKey] then
            ns.db.profile.cdmGroups.initializedCharacters[charKey] = true
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- ONE-TIME CLEANUP & RESCUE: For users who already migrated but:
    -- 1. Still have stale profile data causing "ghost groups"
    -- 2. May have missed layoutProfiles during earlier migration
    -- ═══════════════════════════════════════════════════════════════════════════
    local _, _, classID = UnitClass("player")
    classID = classID or 0
    local classPrefix = "class_" .. classID .. "_"
    
    if alreadyHasCharData and hasProfileData and ns.db.profile.cdmGroups.specData then
        -- v2 cleanup: Also handles layoutProfiles rescue and numeric keys
        -- Use new flag so this runs even if old cleanup already ran
        if not ns.db.char.cdmGroups.cleanedProfileStorageV2 then
            local cleanedCount = 0
            local rescuedProfiles = 0
            
            -- RESCUE: Check if any layoutProfiles in profile storage weren't migrated
            -- This can happen if user had numeric keys that weren't migrated properly
            for i = 1, 4 do
                local oldSpecData = ns.db.profile.cdmGroups.specData[i]
                if oldSpecData and oldSpecData.layoutProfiles then
                    local newKey = "class_" .. classID .. "_spec_" .. i
                    local charSpecData = ns.db.char.cdmGroups.specData[newKey]
                    
                    -- If char has this spec but no layoutProfiles, rescue them
                    if charSpecData and (not charSpecData.layoutProfiles or not next(charSpecData.layoutProfiles)) then
                        charSpecData.layoutProfiles = DeepCopy(oldSpecData.layoutProfiles)
                        charSpecData.activeProfile = oldSpecData.activeProfile or "Default"
                        rescuedProfiles = rescuedProfiles + 1
                    end
                end
            end
            
            -- Also check string keys
            for specKey, oldSpecData in pairs(ns.db.profile.cdmGroups.specData) do
                if type(specKey) == "string" and specKey:find(classPrefix) and oldSpecData.layoutProfiles then
                    local charSpecData = ns.db.char.cdmGroups.specData[specKey]
                    if charSpecData and (not charSpecData.layoutProfiles or not next(charSpecData.layoutProfiles)) then
                        charSpecData.layoutProfiles = DeepCopy(oldSpecData.layoutProfiles)
                        charSpecData.activeProfile = oldSpecData.activeProfile or "Default"
                        rescuedProfiles = rescuedProfiles + 1
                    end
                end
            end
            
            -- CLEANUP: Remove stale profile entries
            -- Clean string keys for this class
            for specKey, _ in pairs(ns.db.profile.cdmGroups.specData) do
                if type(specKey) == "string" and specKey:find(classPrefix) then
                    ns.db.profile.cdmGroups.specData[specKey] = nil
                    cleanedCount = cleanedCount + 1
                end
            end
            -- Clean numeric keys
            for i = 1, 4 do
                if ns.db.profile.cdmGroups.specData[i] then
                    ns.db.profile.cdmGroups.specData[i] = nil
                    cleanedCount = cleanedCount + 1
                end
            end
            
            if rescuedProfiles > 0 then
                PrintMsg("Rescued " .. rescuedProfiles .. " layout profiles from old storage")
            end
            if cleanedCount > 0 then
                PrintMsg("Cleaned up " .. cleanedCount .. " stale profile entries (ghost groups fix)")
            end
            ns.db.char.cdmGroups.cleanedProfileStorageV2 = true
        end
    end
    
    -- Get/initialize character database (this handles all initialization)
    local db = GetCDMGroupsDB()
    if not db then
        print("|cffff0000ArcUI CDMGroups|r: Failed to initialize character database!")
        return
    end
    
    -- MIGRATION: Convert old numeric spec keys to new class-based keys
    -- Old format: specData[1], specData[2], etc.
    -- New format: specData["class_7_spec_2"], etc.
    local _, _, classID = UnitClass("player")
    classID = classID or 0
    local specIndex = GetSpecialization() or 1
    local newKey = "class_" .. classID .. "_spec_" .. specIndex
    
    -- Check if old numeric key exists and hasn't been migrated yet
    if db.specData then
        -- Migrate all specs for this class (1-4)
        for i = 1, 4 do
            local oldSpecData = db.specData[i]
            local migratedKey = "class_" .. classID .. "_spec_" .. i
            local existingNewData = db.specData[migratedKey]
            local alreadyMigrated = db.migratedOldKeys[i]
            
            -- Only migrate if: old data exists, new key doesn't exist, and old key hasn't been migrated
            if oldSpecData and not existingNewData and not alreadyMigrated then
                db.specData[migratedKey] = DeepCopy(oldSpecData)
                db.migratedOldKeys[i] = migratedKey  -- Mark as migrated
                PrintMsg("Migrated layout data to " .. migratedKey)
            end
        end
    end
    
    -- Call the original OnInitialize logic (without AceConfig registration)
    ns.CDMGroups.currentSpec = GetCurrentSpec()  -- Use class-based key like "class_7_spec_2"
    
    -- Initialize spec storage tables (groups and freeIcons only - savedPositions comes from profile)
    if not ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec] then
        ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec] = {}
    end
    -- NOTE: Do NOT create specSavedPositions here - let GetProfileSavedPositions handle it
    if not ns.CDMGroups.specFreeIcons[ns.CDMGroups.currentSpec] then
        ns.CDMGroups.specFreeIcons[ns.CDMGroups.currentSpec] = {}
    end
    
    -- Set shortcuts to current spec
    ns.CDMGroups.groups = ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec]
    ns.CDMGroups.freeIcons = ns.CDMGroups.specFreeIcons[ns.CDMGroups.currentSpec]
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- CRITICAL: Load ImportRestore state BEFORE loading positions
    -- This ensures unknown icons can be properly redirected to free placement
    -- ═══════════════════════════════════════════════════════════════════════
    if ns.CDMGroups.ImportRestore and ns.CDMGroups.ImportRestore.EnsureLoaded then
        ns.CDMGroups.ImportRestore.EnsureLoaded()
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL FIX: Use GetProfileSavedPositions to load savedPositions
    -- This handles ALL edge cases: profile creation, migration, reference setup
    -- ═══════════════════════════════════════════════════════════════════════════
    local posCount = 0
    local profileSavedPositions = GetProfileSavedPositions(ns.CDMGroups.currentSpec)
    if profileSavedPositions then
        for _ in pairs(profileSavedPositions) do
            posCount = posCount + 1
        end
    end
    
    -- Get specData for other operations
    local specData = GetSpecData(ns.CDMGroups.currentSpec)
    local activeProfileName = specData and specData.activeProfile or "Default"
    ns.CDMGroups.activeProfile = activeProfileName
    local profile = specData and specData.layoutProfiles and specData.layoutProfiles[activeProfileName]
    
    DebugPrint("|cff88ff88[Initialize]|r Loaded", posCount, "positions from PROFILE (direct reference)")
    
    -- Load free icons positions - prefer profile over specData (legacy)
    local freeCount = 0
    if profile and profile.freeIcons and next(profile.freeIcons) then
        for cdID, data in pairs(profile.freeIcons) do
            ns.CDMGroups.freeIcons[cdID] = DeepCopy(data)
            freeCount = freeCount + 1
        end
        -- NOTE: Do NOT write to specData.freeIcons - that creates duplicate storage
    elseif specData and specData.freeIcons then
        -- Legacy migration: copy from specData to runtime and profile
        for cdID, data in pairs(specData.freeIcons) do
            ns.CDMGroups.freeIcons[cdID] = DeepCopy(data)
            freeCount = freeCount + 1
        end
        if profile then
            profile.freeIcons = DeepCopy(ns.CDMGroups.freeIcons)
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Ensure profile.iconSettings exists and migrate any legacy data
    -- iconSettings is now accessed via Shared.GetSpecIconSettings() which
    -- returns profile.iconSettings directly - no specData.iconSettings needed
    -- ═══════════════════════════════════════════════════════════════════════════
    if profile then
        -- Ensure profile has iconSettings table
        if not profile.iconSettings then
            profile.iconSettings = {}
        end
        -- MIGRATION: Copy any existing specData.iconSettings to profile
        if specData and specData.iconSettings and next(specData.iconSettings) then
            local migratedCount = 0
            for cdID, settings in pairs(specData.iconSettings) do
                if not profile.iconSettings[cdID] then
                    profile.iconSettings[cdID] = DeepCopy(settings)
                    migratedCount = migratedCount + 1
                end
            end
            if migratedCount > 0 then
                PrintMsg("|cff00ff00[Initialize]|r Migrated " .. migratedCount .. " iconSettings to profile")
            end
        end
        -- Clean up legacy specData.iconSettings (no longer needed)
        if specData and specData.iconSettings then
            PrintMsg("|cffff8800[Initialize]|r Cleared legacy specData.iconSettings")
            specData.iconSettings = nil
        end
        DebugPrint("|cff88ff88[Initialize]|r iconSettings stored in profile.iconSettings (accessed via Shared.GetSpecIconSettings)")
    end
    
    -- CRITICAL: Mark profile as loaded BEFORE creating groups
    -- This prevents groups from force-saving default positions during creation
    ns.CDMGroups._profileNotLoaded = false
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- VERIFY: Ensure savedPositions reference was properly established
    -- ═══════════════════════════════════════════════════════════════════════════
    if VerifyDirectReference then
        local isValid, errorMsg = VerifyDirectReference(true)  -- auto-repair if needed
        if not isValid then
            DebugPrint("|cffff0000[Initialize]|r Direct reference verification failed:", errorMsg)
        end
    end
    
    -- PRE-CREATE groups from PROFILE.groupLayouts (single source of truth)
    -- This must happen BEFORE icons arrive so they have groups to go into
    local groupCount = 0
    local brokenGroups = {}
    local groupsToCreate = (profile and profile.groupLayouts) or DEFAULT_GROUPS
    
    -- Debug: What are we creating groups from?
    if profile and profile.groupLayouts and next(profile.groupLayouts) then
        PrintMsg("|cff88ccff[Init]|r Creating groups from profile.groupLayouts")
    else
        PrintMsg("|cff88ccff[Init]|r Creating groups from DEFAULT_GROUPS (profile=" .. tostring(profile ~= nil) .. ")")
    end
    
    for groupName, layoutData in pairs(groupsToCreate) do
        -- Skip disabled groups (layoutData might be from DEFAULT_GROUPS which has enabled field)
        if type(layoutData) ~= "table" or layoutData.enabled ~= false then
            -- CreateGroup will read layout from profile.groupLayouts
            local group = ns.CDMGroups.CreateGroup(groupName)
            if group then
                groupCount = groupCount + 1
            else
                -- Group failed to create - mark for cleanup
                table.insert(brokenGroups, groupName)
            end
        end
    end
    
    -- Clean up any groups that failed to create (prevents "broken groups" bug)
    -- NOTE: Don't delete from specData - just log it. Data should persist!
    -- CreateGroup can fail for valid reasons (CDM not ready, styling disabled, etc)
    if #brokenGroups > 0 then
        DebugPrint("|cffffaa00[Init]|r " .. #brokenGroups .. " group(s) couldn't be created (data preserved)")
    end
    
    PrintMsg("Initial restoration: " .. groupCount .. " groups, " .. posCount .. " positions, " .. freeCount .. " free icons")
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL: Deactivate ImportRestore after successful profile load
    -- The profile was already written during import (before reload).
    -- If we have positions loaded successfully, the import is DONE.
    -- This prevents "stuck in import mode" after reload.
    -- ═══════════════════════════════════════════════════════════════════════════
    if posCount > 0 or freeCount > 0 or groupCount > 0 then
        if ns.CDMGroups.ImportRestore and ns.CDMGroups.ImportRestore.OnProfileLoaded then
            ns.CDMGroups.ImportRestore.OnProfileLoaded()
            DebugPrint("|cff88ff88[Initialize]|r ImportRestore deactivated - profile loaded successfully")
        end
    end
    
    -- Hook ArcUI options panel to auto-enable/disable edit mode
    local ACD = LibStub("AceConfigDialog-3.0")
    hooksecurefunc(ACD, "Open", function(_, appName)
        if appName == "ArcUI" then
            C_Timer.After(0.1, function()
                local frame = ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
                if frame and frame.frame then
                    -- Auto-enable edit mode when ArcUI options opens (unless user explicitly disabled it)
                    if not ns.CDMGroups.dragModeEnabled and not ns.CDMGroups._userDisabledEditMode then
                        ns.CDMGroups.SetDragMode(true)
                    end
                    
                    -- Update visibility (show combat-only groups when options open)
                    ns.CDMGroups.UpdateGroupVisibility()
                    
                    -- Hook OnHide to disable edit mode
                    if not frame.frame._cdmgHooked then
                        frame.frame._cdmgHooked = true
                        frame.frame:HookScript("OnHide", function()
                            if ns.CDMGroups.dragModeEnabled then
                                ns.CDMGroups.SetDragMode(false)
                            end
                            -- Disable placeholder mode when panel closes
                            if ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.SetEditingMode then
                                ns.CDMGroups.Placeholders.SetEditingMode(false)
                            end
                            -- Reset user disabled flag when panel closes
                            ns.CDMGroups._userDisabledEditMode = false
                            -- Update visibility (hide combat-only groups when options close)
                            ns.CDMGroups.UpdateGroupVisibility()
                        end)
                    end
                end
            end)
        end
    end)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL: Ensure data persists on first load
    -- AceDB only saves data that differs from defaults. On fresh install, we
    -- need to ensure specData has non-default values so it gets saved.
    -- ═══════════════════════════════════════════════════════════════════════════
    C_Timer.After(1.0, function()
        local db = GetCDMGroupsDB()
        if db and db.specData then
            local specKey = ns.CDMGroups.currentSpec
            if specKey and db.specData[specKey] then
                -- Ensure the specData has a timestamp that differs from defaults
                if not db.specData[specKey].createdAt then
                    db.specData[specKey].createdAt = time()
                end
                -- Mark as initialized to ensure it persists
                if not db.specData[specKey].initialized then
                    db.specData[specKey].initialized = true
                end
                -- Also ensure the active profile has a timestamp
                local activeProfile = db.specData[specKey].activeProfile or "Default"
                if db.specData[specKey].layoutProfiles and db.specData[specKey].layoutProfiles[activeProfile] then
                    local profile = db.specData[specKey].layoutProfiles[activeProfile]
                    if not profile.createdAt then
                        profile.createdAt = time()
                    end
                end
                DebugPrint("|cff88ff88[Initialize]|r Data persistence ensured for", specKey)
            end
            -- Also ensure db-level timestamp
            if not db.firstInitialized then
                db.firstInitialized = time()
            end
        end
    end)
    
    -- NOTE: We no longer call PLAYER_ENTERING_WORLD here
    -- Initialize() already loaded positions via [INIT RESTORE]
    -- The event handler will call PLAYER_ENTERING_WORLD when the actual event fires
    -- This prevents double-loading and the duplicate [RESTORE] messages
    
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LAYOUT AUTO-SAVE
-- Triggers auto-save when groups are modified
-- Saves to: 1) Active profile's groupLayouts, 2) Linked template (if any)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Debounce timer for profile auto-save
local profileAutoSaveTimer = nil
local PROFILE_AUTO_SAVE_DELAY = 1.0  -- 1 second debounce

-- Save groupLayouts to the active profile (called after debounce)
local function SaveGroupLayoutsToActiveProfile()
    local specData = GetSpecData()
    if not specData then return end
    
    -- Don't save during restoration
    if IsRestoring() then return end
    
    -- Don't save during profile load cooldown
    if ns.CDMGroups._profileSaveBlockedUntil and GetTime() < ns.CDMGroups._profileSaveBlockedUntil then
        return
    end
    
    local activeProfileName = specData.activeProfile or "Default"
    if not specData.layoutProfiles or not specData.layoutProfiles[activeProfileName] then
        return
    end
    
    local profile = specData.layoutProfiles[activeProfileName]
    if not profile.groupLayouts then
        profile.groupLayouts = {}
    end
    
    -- Save current group layouts to profile
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.layout then
            profile.groupLayouts[groupName] = {
                -- Grid settings
                gridRows = group.layout.gridRows,
                gridCols = group.layout.gridCols,
                -- Position
                position = group.position and { x = group.position.x, y = group.position.y },
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
end

-- Trigger auto-save to profile (with debouncing)
local function TriggerProfileAutoSave()
    -- Cancel existing timer if any
    if profileAutoSaveTimer then
        profileAutoSaveTimer:Cancel()
        profileAutoSaveTimer = nil
    end
    
    -- Start new debounce timer
    profileAutoSaveTimer = C_Timer.NewTimer(PROFILE_AUTO_SAVE_DELAY, function()
        profileAutoSaveTimer = nil
        SaveGroupLayoutsToActiveProfile()
    end)
end

function ns.CDMGroups.TriggerTemplateAutoSave()
    -- 1) Always save to active profile's groupLayouts
    TriggerProfileAutoSave()
    
    -- 2) Also save to linked template (if any)
    local IE = ns.CDMImportExport
    if IE and IE.TriggerAutoSave then
        IE.TriggerAutoSave()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PHASE 1 EXPORTS: Make new helper functions available to other modules
-- ═══════════════════════════════════════════════════════════════════════════════
ns.CDMGroups.SerializeGroupToLayoutData = SerializeGroupToLayoutData
ns.CDMGroups.GetActiveProfile = GetActiveProfile
ns.CDMGroups.SaveGroupLayoutToProfile = SaveGroupLayoutToProfile
ns.CDMGroups.GetGroupLayoutFromProfile = GetGroupLayoutFromProfile

-- ===================================================================
-- LIBPLEEBUG FUNCTION WRAPPING
-- Wrap hot functions for CPU profiling
-- ===================================================================
if P then
  -- UI Updates (27ms @ 5/sec)
  ns.CDMGroups.UpdateEditButtonVisibility = P:Def("UpdateEditButtonVisibility", ns.CDMGroups.UpdateEditButtonVisibility, "UI")
  ns.CDMGroups.UpdateCachedPanelState = P:Def("UpdateCachedPanelState", ns.CDMGroups.UpdateCachedPanelState, "UI")
  ns.CDMGroups.IsOptionsPanelOpen = P:Def("IsOptionsPanelOpen", ns.CDMGroups.IsOptionsPanelOpen, "UI")
  
  -- Free Icons (5ms @ 5/sec)
  ns.CDMGroups.GetFreeIcons = P:Def("GetFreeIcons", ns.CDMGroups.GetFreeIcons, "FreeIcons")
  
  -- Layout
  ns.CDMGroups.RefreshAllLayouts = P:Def("RefreshAllLayouts", ns.CDMGroups.RefreshAllLayouts, "Layout")
  ns.CDMGroups.SavePositionToSpec = P:Def("SavePositionToSpec", ns.CDMGroups.SavePositionToSpec, "Layout")
end

-- ===================================================================
-- END OF ArcUI_CDMGroups.lua  
-- ===================================================================