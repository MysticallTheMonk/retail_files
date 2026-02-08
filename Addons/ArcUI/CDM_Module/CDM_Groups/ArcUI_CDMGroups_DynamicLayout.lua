-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI_CDMGroups_DynamicLayout.lua
-- DYNAMIC AURAS: Compacts aura icons based on active aura state
-- 
-- TWO MODES OF OPERATION:
--
-- 1. REFLOW MODE (DL.ReflowGroup, called by group:ReflowIcons):
--    - Cooldowns MOVE to fill gaps
--    - Active auras MOVE to fill gaps
--    - Inactive auras = empty spaces (gaps) when dynamic ON
--    - Result: Compact layout with CDs and active auras together
--
-- 2. DYNAMIC POSITIONING MODE (CalculateDynamicSlots, used by Layout):
--    - Cooldowns = WALLS (stay at their REFLOWED position)
--    - Active auras = flow dynamically around CD walls
--    - Inactive auras = hidden at saved positions
--    - CDs don't move when auras come/go - only auras animate
--
-- When enabled on a group:
--   - CDMEnhance handles actual visibility/alpha separately
--   - Only active when options panel is CLOSED
--
-- v1.5: Moved reflow logic from CDMGroups.lua to DL.ReflowGroup()
--       Clear separation between reflow mode and dynamic positioning
--
-- LOAD ORDER: After CDMGroups.lua main body
-- ═══════════════════════════════════════════════════════════════════════════

local ADDON, ns = ...

ns.CDMGroups = ns.CDMGroups or {}
ns.CDMGroups.DynamicLayout = ns.CDMGroups.DynamicLayout or {}

local DL = ns.CDMGroups.DynamicLayout

-- Shared helper for DB access
local Shared = ns.CDMShared

-- ═══════════════════════════════════════════════════════════════════════════
-- MODULE-LEVEL CACHED ENABLED STATE
-- Direct boolean check - NO function call overhead in OnUpdate
-- ═══════════════════════════════════════════════════════════════════════════
local _cdmGroupsEnabled = true  -- Assume enabled until refreshed

local function RefreshCachedEnabledState()
    local db = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
    _cdmGroupsEnabled = db and db.enabled ~= false
end

-- Export for other modules to call when settings change
DL.RefreshCachedEnabledState = RefreshCachedEnabledState

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════

local CONFIG = {
    -- How often to check for visibility changes (seconds)
    CHECK_INTERVAL = 0.5,  -- 2Hz (was 0.25 = 4Hz) - cut in half
    
    -- How often to check for grid mismatches (more expensive, do less often)
    MISMATCH_CHECK_INTERVAL = 2.0,  -- 0.5Hz (was 1Hz) - cut in half
    
    -- Threshold: alpha at or below this is considered "invisible"
    INVISIBLE_THRESHOLD = 0.01,
    
    -- Delay after talent change before resuming normal operation
    POST_TALENT_DELAY = 0.3,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════════════

local state = {
    -- Track visibility state per icon to detect changes
    -- [cdID] = isVisible (boolean)
    iconVisibility = {},
    
    -- Groups pending reflow (batch changes)
    pendingReflows = {},
    
    -- Debug tracking (accessible by debugger)
    lastReflowTime = {},     -- [groupName] = GetTime() of last reflow
    reflowCount = {},        -- [groupName] = count of reflows triggered
    lastMismatchDetected = {},  -- [groupName] = GetTime() when mismatch was detected
    
    -- Event log (circular buffer, max 50 entries)
    eventLog = {},
    eventLogMax = 50,
    
    -- Talent change tracking
    talentChangeTime = 0,         -- GetTime() when last talent change detected
    pendingPostTalentRefresh = false,
    
    -- Options panel state tracking for center-align restore
    optionsPanelWasOpen = false,
    
    -- PERFORMANCE: Per-tick cache for IsIconInvisible results
    -- Cleared at start of each tick, avoids duplicate API calls
    tickInvisibleCache = {},  -- [cdID] = result (true/false/nil)
    
    -- PERFORMANCE: Throttle HasGridMismatch checks (expensive)
    lastMismatchCheckTime = 0,  -- GetTime() of last mismatch check
}

-- Add event to log
local function LogEvent(eventType, groupName, details)
    local entry = {
        time = GetTime(),
        type = eventType,
        group = groupName or "?",
        details = details or "",
    }
    table.insert(state.eventLog, entry)
    -- Keep only last N entries
    while #state.eventLog > state.eventLogMax do
        table.remove(state.eventLog, 1)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CENTER ALIGNMENT: IMMEDIATE LAYOUT TRIGGER
-- For center-aligned groups, we need instant response when auras change.
-- This hooks aura event methods to trigger immediate Layout().
-- ═══════════════════════════════════════════════════════════════════════════

-- Track which frames we've hooked for center alignment
local dynamicLayoutHookedFrames = {}

-- Check if options panel is open (defined here so it's available for TriggerDynamicLayout)
local function IsOptionsPanelOpen()
    if ns.CDMGroups.IsOptionsPanelOpen then
        return ns.CDMGroups.IsOptionsPanelOpen()
    end
    local ACD = LibStub("AceConfigDialog-3.0", true)
    return ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
end

-- Trigger immediate layout for a center-aligned group
-- Helper to add trace if debugger is available
local function Trace(event, cdID, details, groupName)
    -- Try multiple ways to access the debugger
    local debugger = ns.DynamicLayoutDebug or (ArcUI_NS and ArcUI_NS.DynamicLayoutDebug)
    if debugger then
        -- Send to Center Align Trace (if enabled)
        if debugger.IsPixelTraceEnabled and debugger.IsPixelTraceEnabled() then
            debugger.AddPixelTrace(event, cdID, details)
        end
        -- ALSO send to CDM Event Monitor (if enabled)
        if debugger.AddDynamicLayoutTrace then
            debugger.AddDynamicLayoutTrace(event, cdID, details, groupName)
        end
    end
end

local function TriggerDynamicLayout(group, reason, triggerFrame)
    local cdID = triggerFrame and triggerFrame.cooldownID
    local groupName = group and group.name or nil
    
    if not group or not group.Layout then 
        Trace("LAYOUT_SKIP", cdID, "no group or no Layout method", groupName)
        return 
    end
    
    local now = GetTime()
    
    -- TRACE: Hook triggered
    Trace("HOOK_" .. (reason or "UNKNOWN"), cdID, string.format("group=%s frame=%s", groupName or "?", triggerFrame and "yes" or "no"), groupName)
    
    -- Guard against recursive calls (Layout calling CalculateDynamicSlots calling hooks)
    if group._pixelLayoutInProgress then 
        Trace("LAYOUT_BLOCKED", cdID, "recursive guard", groupName)
        return 
    end
    
    -- Check if icon is actually visible/active (has aura)
    -- EXCEPTION: SetAuraInstanceInfo means the aura data IS now present, so don't skip
    
    -- CRITICAL: Only trigger layout for CONFIRMED aura frames.
    -- Cooldown frames have aura methods (CDM reuses BuffIcon templates) but
    -- cooldowns are ALWAYS active - their state never changes layout.
    -- During Edit Mode transitions, members can be nil (frame recycling) - skip those too.
    if triggerFrame and cdID then
        local member = group.members and group.members[cdID]
        if not member or not DL.IsAuraFrame(member) then
            Trace("LAYOUT_SKIP", cdID, "not a confirmed aura frame - skipping", groupName)
            return
        end
    end
    
    if triggerFrame and reason ~= "SetAuraInstanceInfo" then
        local auraInstanceID = triggerFrame.auraInstanceID
        if reason == "OnUnitAuraAddedEvent" then
            -- For aura added, check if frame has aura data yet
            -- NOTE: We only check auraInstanceID (non-secret), NOT isActive (secret in combat)
            if not auraInstanceID then
                Trace("LAYOUT_SKIP", cdID, "aura not yet active (no auraInstanceID)", groupName)
                return
            end
        end
    end
    
    -- Check if options panel is open
    local optionsPanelOpen = IsOptionsPanelOpen()
    
    -- If options panel is open, clear pixel positioning and restore grid
    if optionsPanelOpen then
        Trace("LAYOUT_BLOCKED", cdID, "options panel open", groupName)
        if group._usePixelPositioning then
            -- Clear pixel flags so Layout uses grid positions
            group._usePixelPositioning = nil
            group._pixelOffsets = nil
            group._activeOrder = nil
            
            -- Restore member.row/col to saved positions
            local savedPositions = ns.CDMGroups and ns.CDMGroups.savedPositions or {}
            if group.members then
                for memberCdID, member in pairs(group.members) do
                    local saved = savedPositions[memberCdID]
                    if saved and saved.type == "group" and saved.target == groupName then
                        if saved.row ~= nil and saved.col ~= nil then
                            member.row = saved.row
                            member.col = saved.col
                        end
                    end
                end
            end
            
            -- Trigger one layout to restore grid positions
            group._pixelLayoutInProgress = true
            group:Layout()
            group._pixelLayoutInProgress = nil
        end
        return
    end
    
    -- Call Layout() to reposition all frames
    -- NOTE: DynamicLayout ONLY handles positioning - CDMEnhance handles all visibility/alpha
    Trace("LAYOUT_START", cdID, "calling group:Layout()", groupName)
    local layoutStart = GetTime()
    group._pixelLayoutInProgress = true
    group:Layout()
    group._pixelLayoutInProgress = nil
    local layoutEnd = GetTime()
    Trace("LAYOUT_END", cdID, string.format("took=%.1fms", (layoutEnd - layoutStart) * 1000), groupName)
    
    -- Total time for this trigger
    local totalTime = GetTime() - now
    Trace("TRIGGER_COMPLETE", cdID, string.format("total=%.1fms", totalTime * 1000), groupName)
end

-- Hook a frame's aura events for center alignment immediate response
-- NOTE: We do NOT capture 'group' in the closure because frames can move between groups.
-- Instead, we look up the frame's current group dynamically via the Registry.
local function HookFrameForDynamicLayout(frame, group)
    if not frame or dynamicLayoutHookedFrames[frame] then return end
    
    -- Helper to get frame's CURRENT group (not the one captured at hook time)
    local function GetFrameCurrentGroup(f)
        local Registry = ns.FrameRegistry
        local entry = nil
        
        -- Method 1: Try Registry.byAddress
        if Registry and Registry.byAddress then
            entry = Registry.byAddress[tostring(f)]
            if entry and entry.group then
                local entryGroup = entry.group
                -- entry.group can be either a group object or a group name string
                if type(entryGroup) == "table" then
                    return entryGroup
                elseif type(entryGroup) == "string" then
                    local groups = ns.CDMGroups and ns.CDMGroups.groups
                    if groups and groups[entryGroup] then
                        -- FIX: Upgrade string to object for future calls
                        entry.group = groups[entryGroup]
                        return groups[entryGroup]
                    end
                end
            end
        end
        
        -- Method 2: Fallback - search through groups to find frame's parent
        local groups = ns.CDMGroups and ns.CDMGroups.groups
        if groups then
            local cdID = f.cooldownID
            if cdID then
                for _, g in pairs(groups) do
                    if g.members and g.members[cdID] then
                        local member = g.members[cdID]
                        if member.frame == f then
                            -- FIX: Set entry.group so future lookups are fast
                            if entry then
                                entry.group = g
                            elseif Registry and Registry.GetOrCreate then
                                -- Create entry if it doesn't exist
                                local newEntry = Registry:GetOrCreate(f, "DynamicLayout")
                                if newEntry then
                                    newEntry.group = g
                                    newEntry.manipulated = true
                                    newEntry.manipulationType = "group"
                                end
                            end
                            return g
                        end
                    end
                end
            end
        end
        
        return nil
    end
    
    -- Helper to check if a group should trigger instant layout
    -- ONLY triggers for CONFIRMED aura frames in groups with Dynamic Auras enabled.
    -- Cooldown frames also have aura methods (CDM reuses BuffIcon templates) but
    -- their state never changes which icons participate in layout.
    -- During Edit Mode/frame recycling, members may be nil - skip those too.
    local function ShouldTriggerDynamicLayout(g, triggerFrame)
        if not g then return false end
        -- CRITICAL: Check BOTH autoReflow (master toggle) AND dynamicLayout (aura behavior)
        -- dynamicLayout is meaningless without autoReflow - it's a sub-feature
        if not g.autoReflow then return false end
        if not g.dynamicLayout then return false end
        -- Require positive confirmation: frame must be a KNOWN aura
        if triggerFrame then
            local cdID = triggerFrame.cooldownID
            if cdID and g.members then
                local member = g.members[cdID]
                -- Only trigger if member exists AND is confirmed aura frame
                -- nil member (frame recycling) or cooldown frame → skip
                if not member or not DL.IsAuraFrame(member) then
                    return false
                end
            else
                -- No cdID or no members table → can't confirm aura, skip
                return false
            end
        end
        return true
    end
    
    -- Only hook BuffIcon frames (they have these methods)
    if frame.OnActiveStateChanged then
        hooksecurefunc(frame, "OnActiveStateChanged", function(self)
            local currentGroup = GetFrameCurrentGroup(self)
            if ShouldTriggerDynamicLayout(currentGroup, self) then
                TriggerDynamicLayout(currentGroup, "OnActiveStateChanged", self)
            end
        end)
    end
    if frame.OnUnitAuraAddedEvent then
        hooksecurefunc(frame, "OnUnitAuraAddedEvent", function(self)
            local currentGroup = GetFrameCurrentGroup(self)
            if ShouldTriggerDynamicLayout(currentGroup, self) then
                TriggerDynamicLayout(currentGroup, "OnUnitAuraAddedEvent", self)
            end
        end)
    end
    if frame.OnUnitAuraRemovedEvent then
        hooksecurefunc(frame, "OnUnitAuraRemovedEvent", function(self)
            local currentGroup = GetFrameCurrentGroup(self)
            if ShouldTriggerDynamicLayout(currentGroup, self) then
                TriggerDynamicLayout(currentGroup, "OnUnitAuraRemovedEvent", self)
            end
        end)
    end
    
    -- CRITICAL: Hook SetAuraInstanceInfo - this fires when CDM actually has the aura data
    -- This is often delayed from OnUnitAuraAddedEvent due to secret value processing
    if frame.SetAuraInstanceInfo then
        hooksecurefunc(frame, "SetAuraInstanceInfo", function(self, auraData)
            local currentGroup = GetFrameCurrentGroup(self)
            if ShouldTriggerDynamicLayout(currentGroup, self) then
                TriggerDynamicLayout(currentGroup, "SetAuraInstanceInfo", self)
            end
        end)
    end
    
    dynamicLayoutHookedFrames[frame] = true
end

-- Hook all frames in a group with dynamic layout for immediate response
-- Works for ALL alignments (center, left, right, top, bottom) when Dynamic Auras is enabled
function DL.SetupDynamicLayoutHooks(group)
    if not group or not group.members then return end
    
    -- CRITICAL: Check BOTH autoReflow (master toggle) AND dynamicLayout (aura behavior)
    -- dynamicLayout is meaningless without autoReflow - it's a sub-feature
    if not group.autoReflow then return end
    if not group.dynamicLayout then return end
    
    -- Hook ALL frames in this group that have aura methods
    -- We removed IsAuraFrame check because it fails during profile load
    -- when member.viewerType isn't cached yet. HookFrameForDynamicLayout 
    -- already checks if the frame has the required methods.
    for cdID, member in pairs(group.members) do
        if member and member.frame then
            HookFrameForDynamicLayout(member.frame, group)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Export IsOptionsPanelOpen to module (defined above in CENTER ALIGNMENT section)
DL.IsOptionsPanelOpen = IsOptionsPanelOpen

-- Get the effective alpha for "aura missing" state from the frame's cached CDMEnhance settings
-- Reads frame._arcCfg (cached by CDMEnhance, no API call needed)
-- Returns: alpha value (0-1), defaults to 1.0 if no settings found
function DL.GetFrameMissingAlpha(frame)
    if not frame then return 1.0 end
    
    -- Fast path: read directly from frame's cached CDMEnhance settings
    local cfg = frame._arcCfg
    if cfg and cfg.cooldownStateVisuals then
        local cs = cfg.cooldownStateVisuals.cooldownState
        if cs and cs.alpha ~= nil then
            return cs.alpha
        end
    end
    
    -- Fallback: try CDMEnhance.GetIconSettings if frame cache isn't populated yet
    local cdID = frame.cooldownID
    if cdID and ns.CDMEnhance and ns.CDMEnhance.GetIconSettings then
        local settings = ns.CDMEnhance.GetIconSettings(cdID)
        if settings and settings.cooldownStateVisuals then
            local cs = settings.cooldownStateVisuals.cooldownState
            if cs and cs.alpha ~= nil then
                return cs.alpha
            end
        end
    end
    
    -- No settings at all → default is 1.0 (fully visible)
    return 1.0
end

-- Check if an icon should be treated as invisible for dynamic layout
-- Only handles AURA icons (including totems) - cooldowns are excluded
-- Returns true if should be treated as a gap (aura missing AND frame would be hidden)
-- Returns false if aura active, OR aura missing but frame stays visible (alpha > 0)
-- Returns nil for non-aura icons (exclude from dynamic layout processing)
--
-- VISIBILITY-AWARE: Reads the frame's cached CDMEnhance settings (frame._arcCfg)
-- to check cooldownStateVisuals.cooldownState.alpha. If the user hasn't set
-- the "aura missing" alpha to ~0, the frame stays visible → NOT a gap.
function DL.IsIconInvisible(member)
    if not member or not member.frame then
        return nil  -- No frame = can't determine, exclude from dynamic layout
    end
    
    -- Hidden by bar tracking = always treat as invisible gap
    if member.frame._arcHiddenByBar then
        local cdID = member.cdID or member.frame.cooldownID
        if cdID then state.tickInvisibleCache[cdID] = true end
        return true
    end
    
    -- PER-TICK CACHE: Avoid duplicate API lookups within same tick
    -- Cache key is cdID (stable identifier)
    local cdID = member.cdID or (member.frame and member.frame.cooldownID)
    if cdID and state.tickInvisibleCache[cdID] ~= nil then
        return state.tickInvisibleCache[cdID]
    end
    
    -- Use robust aura check (falls back to CDM category lookup)
    if not DL.IsAuraFrame(member) then
        if cdID then state.tickInvisibleCache[cdID] = nil end  -- Cache: not an aura
        return nil  -- Not an aura = exclude from dynamic layout (cooldowns not affected)
    end
    
    local frame = member.frame
    local result
    
    -- WoW 12.0: totemData ONLY EXISTS when totem is active (it's a secret table)
    -- When totem expires, totemData becomes nil
    -- We can check existence (nil vs not-nil) without triggering secret comparison
    -- preferredTotemUpdateSlot persists even after totem expires, so don't use it!
    if frame.totemData ~= nil then
        result = false  -- totemData exists = totem active = visible
    elseif frame.auraInstanceID and frame.auraInstanceID > 0 then
        result = false  -- has aura = visible
    else
        -- Aura is inactive — check if CDMEnhance would actually hide this frame
        -- Read the cached effective settings directly from the frame (no API call)
        -- cooldownStateVisuals.cooldownState.alpha controls "aura missing" opacity
        -- Default is 1.0 (fully visible), only compact when user has set it to ~0
        local missingAlpha = DL.GetFrameMissingAlpha(frame)
        if missingAlpha <= CONFIG.INVISIBLE_THRESHOLD then
            result = true   -- Alpha ≈ 0 → frame will be hidden → gap
        else
            result = false  -- Frame stays visible when inactive → NOT a gap
        end
    end
    
    -- Cache result for this tick
    if cdID then state.tickInvisibleCache[cdID] = result end
    return result
end

-- Check if a member should be included in reflow for a dynamic layout group
-- Returns true if icon should take up space, false if treated as gap
-- Non-aura icons always return true (included, not affected by dynamic layout)
function DL.ShouldIncludeInReflow(member, cdID, group)
    -- If dynamic layout is disabled, include everything
    if not group or not group.dynamicLayout then
        return true
    end
    
    -- When options panel is open, include all (show saved positions)
    if IsOptionsPanelOpen() then
        return true
    end
    
    -- Placeholders always included
    if member and member.isPlaceholder then
        return true
    end
    
    -- Check if this is an aura and if it's invisible
    local isInvisible = DL.IsIconInvisible(member)
    
    -- nil means not an aura - always include (cooldowns not affected)
    if isInvisible == nil then
        return true
    end
    
    return not isInvisible
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CORE SLOT CALCULATION (Moved from CDMGroups.lua Layout())
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if a member's aura is active (has auraInstanceID or is active totem)
-- Returns: isActive (boolean), reason (string for debugging)
function DL.IsAuraActive(member)
    if not member or not member.frame then
        return false, "no_frame"
    end
    
    -- Use robust check for aura type
    if not DL.IsAuraFrame(member) then
        return false, "not_aura"
    end
    
    local frame = member.frame
    
    -- WoW 12.0: totemData ONLY EXISTS when totem is active (it's a secret table)
    -- When totem expires, totemData becomes nil
    -- preferredTotemUpdateSlot persists after totem expires, so don't use it!
    if frame.totemData ~= nil then
        return true, "totem_active"
    end
    
    -- Regular aura - check auraInstanceID
    if frame.auraInstanceID and frame.auraInstanceID > 0 then
        return true, "has_auraInstanceID"
    end
    
    return false, "no_auraInstanceID"
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ROBUST FRAME TYPE DETECTION
-- viewerType may not be set correctly, so we fall back to CDM category lookup
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if a member is an AURA frame (vs cooldown/utility)
-- Returns true for auras, false for cooldowns/utilities
-- ALWAYS verifies against CDM category lookup (authoritative source)
-- Only falls back to viewerType if CDM lookup fails
function DL.IsAuraFrame(member)
    if not member then return false end
    
    -- FIRST: Use cached viewerType (fast path - no API call)
    if member.viewerType then
        return member.viewerType == "aura"
    end
    
    -- SECOND: Try CDM category lookup only if cache is missing
    local Shared = ns.CDMShared
    local cdID = member.cdID or (member.frame and member.frame.cooldownID)
    if cdID and Shared and Shared.GetViewerTypeFromCooldownID then
        local viewerType = Shared.GetViewerTypeFromCooldownID(cdID)
        if viewerType then
            -- Cache for future calls
            member.viewerType = viewerType
            return viewerType == "aura"
        end
    end
    
    -- Default: assume NOT an aura (safer - treats as wall)
    return false
end

-- Check if a member is a COOLDOWN frame (not aura, not utility - Essential Cooldowns)
function DL.IsCooldownFrame(member)
    if not member then return false end
    
    -- FIRST: Use cached viewerType (fast path - no API call)
    if member.viewerType then
        return member.viewerType == "cooldown"
    end
    
    -- SECOND: Try CDM category lookup only if cache is missing
    local Shared = ns.CDMShared
    local cdID = member.cdID or (member.frame and member.frame.cooldownID)
    if cdID and Shared and Shared.GetViewerTypeFromCooldownID then
        local viewerType = Shared.GetViewerTypeFromCooldownID(cdID)
        if viewerType then
            -- Cache for future calls
            member.viewerType = viewerType
            return viewerType == "cooldown"
        end
    end
    
    return false
end

-- Build list of available slots in alignment order
-- Returns: availableSlots table (ordered list of slot indices)
function DL.BuildAvailableSlots(rows, cols, alignment, blockedSlots)
    local maxSlots = rows * cols
    local availableSlots = {}
    
    if alignment == "right" then
        -- Fill from right to left (last slot first)
        for i = maxSlots - 1, 0, -1 do
            if not blockedSlots[i] then
                table.insert(availableSlots, i)
            end
        end
    elseif alignment == "bottom" then
        -- Fill from bottom to top (last row first)
        for r = rows - 1, 0, -1 do
            for c = 0, cols - 1 do
                local i = r * cols + c
                if not blockedSlots[i] then
                    table.insert(availableSlots, i)
                end
            end
        end
    elseif alignment == "center" then
        -- Fill from center outward (alternating left/right)
        local centerCol = math.floor((cols - 1) / 2)
        local addedCols = {}
        for offset = 0, cols - 1 do
            local targetCol = (offset % 2 == 0) and centerCol - math.floor(offset / 2) or centerCol + math.ceil(offset / 2)
            if targetCol >= 0 and targetCol < cols and not addedCols[targetCol] then
                addedCols[targetCol] = true
                for r = 0, rows - 1 do
                    local i = r * cols + targetCol
                    if not blockedSlots[i] then
                        table.insert(availableSlots, i)
                    end
                end
            end
        end
    else
        -- Default: left/top - fill from first slot (0) forward
        for i = 0, maxSlots - 1 do
            if not blockedSlots[i] then
                table.insert(availableSlots, i)
            end
        end
    end
    
    return availableSlots
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UNIFIED PIXEL POSITIONING (v2.0)
-- Computes pixel {x,y} offsets from container CENTER for ALL alignments.
-- Replaces the old grid-slot system (Fill Gaps) and the center-only pixel system.
-- 
-- ALL groups always use pixel positioning when options panel is closed.
-- The excludeInactiveAuras parameter controls whether inactive auras are gaps.
--
-- When options panel is open: returns empty, Layout() uses grid positions.
-- When options panel is closed: returns pixel positions for all active items.
-- ═══════════════════════════════════════════════════════════════════════════
function DL.CalculateDynamicSlots(group, rows, cols, excludeInactiveAuras)
    local dynamicPositions = {}  -- [cdID] = {row=, col=} (for tracking/grid sync)
    local activeAuras = {}       -- [cdID] = true (items participating in layout)
    
    if not group or not group.members then
        return dynamicPositions, activeAuras
    end
    
    -- Setup instant layout hooks for all frames in this group
    DL.SetupDynamicLayoutHooks(group)
    
    -- Skip pixel positioning when options panel is open - show all icons at saved grid positions
    if IsOptionsPanelOpen() then
        group._usePixelPositioning = nil
        group._pixelOffsets = nil
        group._activeOrder = nil
        
        -- Restore member.row/col to saved positions for grid-based editing
        local savedPositions = ns.CDMGroups and ns.CDMGroups.savedPositions or {}
        local groupName = group.name
        if group.members then
            for cdID, member in pairs(group.members) do
                local saved = savedPositions[cdID]
                if saved and saved.type == "group" and saved.target == groupName then
                    if saved.row ~= nil and saved.col ~= nil then
                        member.row = saved.row
                        member.col = saved.col
                    end
                end
            end
        end
        
        return dynamicPositions, activeAuras
    end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- COLLECT ACTIVE ITEMS
    -- Cooldowns = always active. Auras = check state when excludeInactiveAuras.
    -- VISIBILITY-AWARE: Inactive auras whose CDMEnhance "aura missing" alpha
    -- is > 0 are treated as active (like cooldowns) to prevent clumping.
    -- Only auras with alpha ≈ 0 are excluded from layout.
    -- ═══════════════════════════════════════════════════════════════════════
    local allActiveItems = {}
    
    for cdID, member in pairs(group.members) do
        if member and member.frame and not member.isPlaceholder then
            member.cdID = cdID
            
            -- Hidden by bar tracking = always treat as gap (empty space)
            -- This applies to ALL icon types (auras AND cooldowns)
            if member.frame._arcHiddenByBar then
                member._dynamicSlot = nil
                -- Skip to next member (don't add to allActiveItems)
            else
                local isAura = DL.IsAuraFrame(member)
                local isActive = true
                
                -- ONLY exclude inactive auras when BOTH the parameter AND the group toggle agree
                -- When Dynamic Auras is OFF, auras are treated identically to cooldowns (always active)
                if isAura and excludeInactiveAuras and group.dynamicLayout then
                    isActive = DL.IsAuraActive(member)
                    
                    -- If aura is inactive, check if CDMEnhance would actually hide it
                    -- Read frame._arcCfg.cooldownStateVisuals.cooldownState.alpha
                    -- If alpha > 0, frame stays visible → treat as active for layout
                    if not isActive then
                        local missingAlpha = DL.GetFrameMissingAlpha(member.frame)
                        if missingAlpha > CONFIG.INVISIBLE_THRESHOLD then
                            isActive = true  -- Frame stays visible → keep in layout
                        end
                    end
                end
                
                if isActive then
                    activeAuras[cdID] = true
                    table.insert(allActiveItems, { cdID = cdID, member = member, isAura = isAura })
                else
                    -- Inactive aura with alpha ≈ 0 - clear dynamic slot (it's a real gap)
                    member._dynamicSlot = nil
                end
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- SORT BY SAVED POSITION ORDER
    -- The saved grid position defines the user's intended icon ORDER.
    -- ═══════════════════════════════════════════════════════════════════════
    local savedPositions = ns.CDMGroups and ns.CDMGroups.savedPositions or {}
    local groupName = group.name
    local gridShape = ns.CDMGroups.DetectGridShape and ns.CDMGroups.DetectGridShape(rows, cols) or "multi"
    local alignment = group.layout and group.layout.alignment
    if alignment == nil then
        alignment = ns.CDMGroups.GetDefaultAlignment and ns.CDMGroups.GetDefaultAlignment(gridShape) or "left"
    end
    
    -- NOTE: Growth direction no longer affects sort order.
    -- Layout positions icons at their logical row/col without flipping.
    -- Growth direction only affects where NEW icons are placed (FindNextSlot).
    
    local function getSavedOrder(cdID)
        local saved = savedPositions[cdID]
        if saved and saved.type == "group" and saved.target == groupName then
            if saved.sortIndex then
                return saved.sortIndex
            end
            if saved.row ~= nil and saved.col ~= nil then
                if gridShape == "vertical" then
                    return saved.col * rows + saved.row
                end
                return saved.row * cols + saved.col
            end
        end
        return 9999
    end
    
    table.sort(allActiveItems, function(a, b)
        local aOrder = getSavedOrder(a.cdID)
        local bOrder = getSavedOrder(b.cdID)
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end
        -- Tiebreaker: cdID for stability
        local aCdID, bCdID = a.cdID, b.cdID
        local aType, bType = type(aCdID), type(bCdID)
        if aType ~= bType then return aType == "number" end
        return aCdID < bCdID
    end)
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- LAYOUT SETTINGS
    -- ═══════════════════════════════════════════════════════════════════════
    local slotW, slotH
    if ns.CDMGroups.GetSlotDimensions and group.layout then
        slotW, slotH = ns.CDMGroups.GetSlotDimensions(group.layout)
    else
        slotW = 36
        slotH = 36
    end
    local spacingX = group.layout and group.layout.spacingX or group.layout and group.layout.spacing or 2
    local spacingY = group.layout and group.layout.spacingY or group.layout and group.layout.spacing or 2
    local activeCount = #allActiveItems
    
    -- Content area dimensions (full grid capacity)
    local contentW = cols * slotW + (cols - 1) * spacingX
    local contentH = rows * slotH + (rows - 1) * spacingY
    
    -- Initialize pixel offset storage
    group._pixelOffsets = {}
    group._activeOrder = {}
    group._usePixelPositioning = true
    
    if activeCount == 0 then
        return dynamicPositions, activeAuras
    end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- HORIZONTAL: Single row - compute X pixel offsets
    -- ═══════════════════════════════════════════════════════════════════════
    if gridShape == "horizontal" or rows == 1 then
        -- Compute total width of active icons
        local iconWidths = {}
        local totalWidth = 0
        for i, data in ipairs(allActiveItems) do
            local effectiveW = data.member._effectiveIconW or slotW
            iconWidths[i] = effectiveW
            totalWidth = totalWidth + effectiveW
        end
        if activeCount > 1 then
            totalWidth = totalWidth + (activeCount - 1) * spacingX
        end
        
        -- Start X based on alignment (relative to container CENTER)
        local currentX
        if alignment == "center" then
            currentX = -totalWidth / 2
        elseif alignment == "right" then
            currentX = contentW / 2 - totalWidth
        else -- left (default)
            currentX = -contentW / 2
        end
        
        -- Assign pixel positions
        for i, data in ipairs(allActiveItems) do
            local iconW = iconWidths[i]
            local centerX = currentX + iconW / 2
            
            group._pixelOffsets[data.cdID] = { x = centerX, y = 0 }
            group._activeOrder[i] = data.cdID
            
            currentX = currentX + iconW + spacingX
            
            dynamicPositions[data.cdID] = { row = 0, col = i - 1 }
            data.member._dynamicSlot = i - 1
        end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- VERTICAL: Single column - compute Y pixel offsets
    -- ═══════════════════════════════════════════════════════════════════════
    elseif gridShape == "vertical" or cols == 1 then
        -- Compute total height of active icons
        local iconHeights = {}
        local totalHeight = 0
        for i, data in ipairs(allActiveItems) do
            local effectiveH = data.member._effectiveIconH or slotH
            iconHeights[i] = effectiveH
            totalHeight = totalHeight + effectiveH
        end
        if activeCount > 1 then
            totalHeight = totalHeight + (activeCount - 1) * spacingY
        end
        
        -- Start Y based on alignment (Y is positive upward from center)
        local currentY
        if alignment == "center" then
            currentY = totalHeight / 2
        elseif alignment == "bottom" then
            currentY = -(contentH / 2) + totalHeight
        else -- top (default)
            currentY = contentH / 2
        end
        
        -- Assign pixel positions
        for i, data in ipairs(allActiveItems) do
            local iconH = iconHeights[i]
            local centerY = currentY - iconH / 2
            
            group._pixelOffsets[data.cdID] = { x = 0, y = centerY }
            group._activeOrder[i] = data.cdID
            
            currentY = currentY - iconH - spacingY
            
            dynamicPositions[data.cdID] = { row = i - 1, col = 0 }
            data.member._dynamicSlot = i - 1
        end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- MULTI-DIMENSIONAL GRAVITY
    --
    -- Icons are placed at their saved grid positions, then gravity compacts:
    --   top    → column gravity UP (icons keep column, compact toward row 0)
    --   bottom → column gravity DOWN (icons keep column, compact toward last row)
    --   left   → row gravity LEFT (icons keep row, pixel-pack from left)
    --   right  → row gravity RIGHT (icons keep row, pixel-pack from right)
    --   center → row gravity + pixel-center each row horizontally
    -- ═══════════════════════════════════════════════════════════════════════
    else
        -- Step 1: Build 2D grid from saved positions
        local grid = {}
        for r = 0, rows - 1 do grid[r] = {} end
        local unplaced = {}
        
        for _, data in ipairs(allActiveItems) do
            local saved = savedPositions[data.cdID]
            local sRow, sCol
            if saved and saved.type == "group" and saved.target == groupName then
                sRow, sCol = saved.row, saved.col
            end
            if sRow and sCol and sRow >= 0 and sRow < rows and sCol >= 0 and sCol < cols and not grid[sRow][sCol] then
                grid[sRow][sCol] = data
            else
                table.insert(unplaced, data)
            end
        end
        
        -- Step 2: Apply gravity
        if alignment == "top" or alignment == "bottom" or alignment == "center_v" then
            -- COLUMN GRAVITY: for each column, collect icons and compact vertically
            for c = 0, cols - 1 do
                local colItems = {}
                for r = 0, rows - 1 do
                    if grid[r][c] then
                        table.insert(colItems, grid[r][c])
                        grid[r][c] = nil
                    end
                end
                if alignment == "top" then
                    for i, d in ipairs(colItems) do grid[i - 1][c] = d end
                elseif alignment == "bottom" then
                    local startRow = rows - #colItems
                    for i, d in ipairs(colItems) do grid[startRow + i - 1][c] = d end
                else -- center_v: center within column
                    local startRow = math.floor((rows - #colItems) / 2)
                    for i, d in ipairs(colItems) do grid[startRow + i - 1][c] = d end
                end
            end
        else -- left, right, center_h
            -- ROW GRAVITY: for each row, collect icons and compact horizontally
            for r = 0, rows - 1 do
                local rowItems = {}
                for c = 0, cols - 1 do
                    if grid[r][c] then
                        table.insert(rowItems, grid[r][c])
                        grid[r][c] = nil
                    end
                end
                if alignment == "right" then
                    local startCol = cols - #rowItems
                    for i, d in ipairs(rowItems) do grid[r][startCol + i - 1] = d end
                else -- left, center_h (center_h grid positions are temporary, pixel step handles actual X)
                    for i, d in ipairs(rowItems) do grid[r][i - 1] = d end
                end
            end
        end
        
        -- Step 3: Place unplaced items in first available slot
        for _, data in ipairs(unplaced) do
            local placed = false
            for r = 0, rows - 1 do
                for c = 0, cols - 1 do
                    if not grid[r][c] then
                        grid[r][c] = data
                        placed = true
                        break
                    end
                end
                if placed then break end
            end
        end
        
        -- Step 4: Convert grid to pixel offsets from container CENTER
        local orderIdx = 1
        for r = 0, rows - 1 do
            -- Y position for this row (from container center, Y+ is up)
            local rowCenterY = contentH / 2 - r * (slotH + spacingY) - slotH / 2
            
            -- Collect items in this row (left-to-right order)
            local rowItems = {}
            for c = 0, cols - 1 do
                if grid[r][c] then
                    table.insert(rowItems, { data = grid[r][c], col = c })
                end
            end
            
            if #rowItems > 0 then
                if alignment == "top" or alignment == "bottom" then
                    -- Column gravity: icons keep their column position
                    -- X = grid-slot center based on column index
                    for _, item in ipairs(rowItems) do
                        local colCenterX = -contentW / 2 + item.col * (slotW + spacingX) + slotW / 2
                        
                        group._pixelOffsets[item.data.cdID] = { x = colCenterX, y = rowCenterY }
                        group._activeOrder[orderIdx] = item.data.cdID
                        orderIdx = orderIdx + 1
                        dynamicPositions[item.data.cdID] = { row = r, col = item.col }
                        item.data.member._dynamicSlot = r * cols + item.col
                    end
                    
                elseif alignment == "center_v" then
                    -- Column gravity + vertical centering: icons keep their column X position
                    -- Y was already set by centered gravity in Step 2
                    for _, item in ipairs(rowItems) do
                        local colCenterX = -contentW / 2 + item.col * (slotW + spacingX) + slotW / 2
                        
                        group._pixelOffsets[item.data.cdID] = { x = colCenterX, y = rowCenterY }
                        group._activeOrder[orderIdx] = item.data.cdID
                        orderIdx = orderIdx + 1
                        dynamicPositions[item.data.cdID] = { row = r, col = item.col }
                        item.data.member._dynamicSlot = r * cols + item.col
                    end
                    
                elseif alignment == "center_h" then
                    -- Row gravity + pixel-center: center this row's icons horizontally
                    local rowTotalW = 0
                    local widths = {}
                    for i, item in ipairs(rowItems) do
                        local w = item.data.member._effectiveIconW or slotW
                        widths[i] = w
                        rowTotalW = rowTotalW + w
                    end
                    if #rowItems > 1 then
                        rowTotalW = rowTotalW + (#rowItems - 1) * spacingX
                    end
                    
                    local currentX = -rowTotalW / 2
                    for i, item in ipairs(rowItems) do
                        local iconW = widths[i]
                        local centerX = currentX + iconW / 2
                        
                        group._pixelOffsets[item.data.cdID] = { x = centerX, y = rowCenterY }
                        group._activeOrder[orderIdx] = item.data.cdID
                        orderIdx = orderIdx + 1
                        dynamicPositions[item.data.cdID] = { row = r, col = i - 1 }
                        item.data.member._dynamicSlot = r * cols + (i - 1)
                        
                        currentX = currentX + iconW + spacingX
                    end
                    
                elseif alignment == "left" then
                    -- Row gravity: pixel-pack from left edge
                    local currentX = -contentW / 2
                    for i, item in ipairs(rowItems) do
                        local iconW = item.data.member._effectiveIconW or slotW
                        local centerX = currentX + iconW / 2
                        
                        group._pixelOffsets[item.data.cdID] = { x = centerX, y = rowCenterY }
                        group._activeOrder[orderIdx] = item.data.cdID
                        orderIdx = orderIdx + 1
                        dynamicPositions[item.data.cdID] = { row = r, col = i - 1 }
                        item.data.member._dynamicSlot = r * cols + (i - 1)
                        
                        currentX = currentX + iconW + spacingX
                    end
                    
                else -- right
                    -- Row gravity: pixel-pack from right edge
                    local currentX = contentW / 2
                    for i = #rowItems, 1, -1 do
                        local item = rowItems[i]
                        local iconW = item.data.member._effectiveIconW or slotW
                        local centerX = currentX - iconW / 2
                        
                        group._pixelOffsets[item.data.cdID] = { x = centerX, y = rowCenterY }
                        group._activeOrder[orderIdx] = item.data.cdID
                        orderIdx = orderIdx + 1
                        dynamicPositions[item.data.cdID] = { row = r, col = cols - (#rowItems - i + 1) }
                        item.data.member._dynamicSlot = r * cols + cols - (#rowItems - i + 1)
                        
                        currentX = currentX - iconW - spacingX
                    end
                end
            end
        end
    end
    
    return dynamicPositions, activeAuras
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LAYOUT HELPERS (Used by CDMGroups.lua Layout())
-- ═══════════════════════════════════════════════════════════════════════════

-- Build processing order for members: active items first, then inactive auras
-- Since cooldowns are now treated as "always active" in dynamic layout,
-- they are included in activeAuras and processed with other active items.
-- Returns: ordered list of cdIDs
function DL.BuildProcessingOrder(group, activeAuras, dynEnabled)
    local processingOrder = {}
    
    if not group or not group.members then
        return processingOrder
    end
    
    -- When options panel is open, include bar-hidden frames so they get
    -- repositioned to their saved grid positions (shown with red overlay).
    -- When closed, bar-hidden frames are empty spaces for dynamic compaction.
    local optionsOpen = IsOptionsPanelOpen()
    
    if dynEnabled then
        local activeList = {}     -- Active items (cooldowns + active auras)
        local inactiveList = {}   -- Inactive auras get whatever's left
        
        for cdID, member in pairs(group.members) do
            if member and member.frame and member.row ~= nil and member.col ~= nil then
                -- Hidden by bar tracking = exclude during runtime (treat as gap)
                -- Include when options panel is open (user needs to see saved positions)
                if member.frame._arcHiddenByBar and not optionsOpen then
                    -- Don't position bar-hidden frames at all
                else
                    -- Store cdID on member for fallback lookup
                    member.cdID = cdID
                    
                    -- Check if this item is active (in activeAuras table)
                    -- Cooldowns are now marked as active in CalculateDynamicSlots
                    if activeAuras[cdID] then
                        table.insert(activeList, cdID)
                    else
                        table.insert(inactiveList, cdID)
                    end
                end
            end
        end
        
        -- Combine in priority order: active items first, then inactive
        for _, cdID in ipairs(activeList) do table.insert(processingOrder, cdID) end
        for _, cdID in ipairs(inactiveList) do table.insert(processingOrder, cdID) end
    else
        -- No dynamic layout - process in any order
        for cdID, member in pairs(group.members) do
            if member and member.frame and member.row ~= nil and member.col ~= nil
               and (optionsOpen or not member.frame._arcHiddenByBar) then
                table.insert(processingOrder, cdID)
            end
        end
    end
    
    return processingOrder
end

-- Get the position a member should use (dynamic or saved)
-- Returns: row, col, usesDynamicPosition
function DL.GetMemberPosition(member, cdID, activeAuras, dynamicPositions, dynEnabled)
    -- Store cdID for fallback lookup
    if member then member.cdID = cdID end
    
    local usesDynamicPosition = false
    local row, col
    
    if dynEnabled and dynamicPositions[cdID] then
        -- Has dynamic position (cooldowns OR active auras)
        usesDynamicPosition = true
        row = dynamicPositions[cdID].row
        col = dynamicPositions[cdID].col
    else
        -- Inactive auras: use member position
        row = member.row
        col = member.col
    end
    
    return row, col, usesDynamicPosition
end

-- Find next available slot when collision occurs
-- Respects alignment direction for natural-looking fallback
-- Returns: row, col, posKey (or nil if no slot found)
function DL.FindAvailableSlot(occupiedPositions, rows, cols, alignment)
    if alignment == "right" then
        -- Right alignment: search right-to-left
        for r = 0, rows - 1 do
            for c = cols - 1, 0, -1 do
                local checkKey = r .. "," .. c
                if not occupiedPositions[checkKey] then
                    return r, c, checkKey
                end
            end
        end
    elseif alignment == "bottom" then
        -- Bottom alignment: search bottom-to-top
        for r = rows - 1, 0, -1 do
            for c = 0, cols - 1 do
                local checkKey = r .. "," .. c
                if not occupiedPositions[checkKey] then
                    return r, c, checkKey
                end
            end
        end
    else
        -- Left/center alignment: search left-to-right (default)
        for r = 0, rows - 1 do
            for c = 0, cols - 1 do
                local checkKey = r .. "," .. c
                if not occupiedPositions[checkKey] then
                    return r, c, checkKey
                end
            end
        end
    end
    
    return nil, nil, nil  -- No slot found
end

-- ═══════════════════════════════════════════════════════════════════════════
-- VISIBILITY CHANGE DETECTION
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if the grid state has issues that need correction
-- With stable slot assignment, we DON'T force contiguity - only check for actual issues
-- Returns true ONLY if:
--   1. A hidden aura is still occupying a grid slot (needs removal)
--   2. An active aura has no _dynamicSlot assigned (needs slot)
-- Does NOT check contiguity - with stable assignment, non-contiguous is OK
local function HasGridMismatch(group)
    if not group or not group.members or not group.grid then return false end
    
    -- Check 1: Hidden auras should not occupy grid slots
    for cdID, member in pairs(group.members) do
        if not member.isPlaceholder and member.frame then
            local isHidden = DL.IsIconInvisible(member)
            
            -- nil means not an aura - skip
            if isHidden == true and member.row ~= nil and member.col ~= nil then
                -- Hidden aura - check if it's still in the grid
                local gridEntry = group.grid[member.row] and group.grid[member.row][member.col]
                if gridEntry == cdID then
                    -- Hidden aura is in grid - this needs fixing
                    return true
                end
            end
        end
    end
    
    -- Check 2: Active auras should have a _dynamicSlot
    -- (This catches new auras that appeared and need slot assignment)
    for cdID, member in pairs(group.members) do
        if not member.isPlaceholder and member.frame then
            if member.viewerType == "aura" then
                local isHidden = DL.IsIconInvisible(member)
                if isHidden == false and member._dynamicSlot == nil then
                    -- Active aura without a dynamic slot - needs assignment
                    return true
                end
            end
        end
    end
    
    -- NOTE: We do NOT check for contiguity anymore!
    -- With stable slot assignment, slots can be non-contiguous and that's OK.
    -- Layout() will compact when an aura becomes inactive (creating a gap),
    -- but we don't force compaction just because slots aren't sequential.
    
    return false
end

-- Check a group for visibility changes
-- Returns true if any change detected OR if grid state is mismatched
-- NOTE: Caller (OnUpdate) has already verified IsOptionsPanelOpen() == false
-- shouldCheckMismatch: Only check for grid mismatches when true (expensive, throttled by caller)
local function CheckGroupForChanges(group, shouldCheckMismatch)
    if not group or not group.members then return false end
    if not group.dynamicLayout then return false end
    -- REMOVED: IsOptionsPanelOpen() check - caller already verified this
    
    local groupName = group.name or "unknown"
    local anyChanged = false
    local changedIcons = {}
    
    for cdID, member in pairs(group.members) do
        if not member.isPlaceholder and member.frame then
            local isVisible = not DL.IsIconInvisible(member)
            local wasVisible = state.iconVisibility[cdID]
            
            -- First check - just record state
            if wasVisible == nil then
                state.iconVisibility[cdID] = isVisible
                LogEvent("INIT", groupName, string.format("cdID %d initial state: %s", cdID, isVisible and "visible" or "hidden"))
            elseif wasVisible ~= isVisible then
                -- Visibility changed!
                state.iconVisibility[cdID] = isVisible
                anyChanged = true
                table.insert(changedIcons, string.format("%d: %s->%s", cdID, wasVisible and "V" or "H", isVisible and "V" or "H"))
            end
        end
    end
    
    if #changedIcons > 0 then
        LogEvent("VIS_CHANGE", groupName, table.concat(changedIcons, ", "))
    end
    
    -- PERFORMANCE: Only check for grid mismatches when explicitly requested (throttled by caller)
    -- This is expensive because it loops through all members again
    if not anyChanged and shouldCheckMismatch and HasGridMismatch(group) then
        state.lastMismatchDetected[groupName] = GetTime()
        LogEvent("MISMATCH", groupName, "Grid mismatch detected, queuing reflow")
        anyChanged = true
    end
    
    return anyChanged
end

-- Process pending reflows
local function ProcessPendingReflows()
    for groupName, group in pairs(state.pendingReflows) do
        if group and group.ReflowIcons then
            state.reflowCount[groupName] = (state.reflowCount[groupName] or 0) + 1
            state.lastReflowTime[groupName] = GetTime()
            LogEvent("REFLOW_START", groupName, string.format("Calling ReflowIcons (count: %d)", state.reflowCount[groupName]))
            group:ReflowIcons()
            LogEvent("REFLOW_END", groupName, "ReflowIcons returned")
        end
    end
    wipe(state.pendingReflows)
end

-- Expose state for debugger
DL.GetDebugState = function()
    return state
end

-- Get event log (for debugger)
DL.GetEventLog = function()
    return state.eventLog
end

-- Clear event log
DL.ClearEventLog = function()
    wipe(state.eventLog)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TALENT/SPEC CHANGE INTEGRATION
-- Called by FrameController after reconcile completes
-- ═══════════════════════════════════════════════════════════════════════════

-- Notify DynamicLayout that a talent/spec change is starting
-- This clears stale visibility state that could cause incorrect reflows
function DL.OnTalentChangeStart()
    LogEvent("TALENT", "START", "Clearing visibility tracking for talent change")
    
    -- Clear all visibility tracking - it's now stale
    wipe(state.iconVisibility)
    wipe(state.pendingReflows)
    
    -- Record when this happened
    state.talentChangeTime = GetTime()
    state.pendingPostTalentRefresh = true
end

-- Notify DynamicLayout that reconcile is complete and frames are stable
-- This triggers a full refresh to rebuild visibility tracking
function DL.OnReconcileComplete()
    if not state.pendingPostTalentRefresh then return end
    
    LogEvent("TALENT", "RECONCILE_DONE", "Scheduling post-talent refresh")
    
    -- Schedule refresh after a short delay to let frames fully settle
    C_Timer.After(CONFIG.POST_TALENT_DELAY, function()
        if IsOptionsPanelOpen() then
            state.pendingPostTalentRefresh = false
            return
        end
        
        LogEvent("TALENT", "POST_REFRESH", "Running post-talent reflow on all dynamic groups")
        
        -- Clear and rebuild visibility tracking
        wipe(state.iconVisibility)
        
        -- Force reflow all dynamic groups
        -- CRITICAL: Check BOTH autoReflow (master toggle) AND dynamicLayout (aura behavior)
        -- dynamicLayout is meaningless without autoReflow - it's a sub-feature
        if ns.CDMGroups.groups then
            for groupName, group in pairs(ns.CDMGroups.groups) do
                if group.autoReflow and group.dynamicLayout and group.ReflowIcons then
                    -- Re-initialize visibility tracking for this group
                    if group.members then
                        for cdID, member in pairs(group.members) do
                            if not member.isPlaceholder and member.frame then
                                local isVisible = not DL.IsIconInvisible(member)
                                state.iconVisibility[cdID] = isVisible
                            end
                        end
                    end
                    
                    LogEvent("REFLOW_START", groupName, "Post-talent ReflowIcons")
                    group:ReflowIcons()
                    LogEvent("REFLOW_END", groupName, "Post-talent ReflowIcons done")
                end
            end
        end
        
        state.pendingPostTalentRefresh = false
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MAINTAINER
-- ═══════════════════════════════════════════════════════════════════════════

local DynamicMaintainer = CreateFrame("Frame")
local elapsed = 0

DynamicMaintainer:SetScript("OnUpdate", function(self, dt)
    -- Skip if CDMGroups not enabled (direct boolean check - no function call)
    if not _cdmGroupsEnabled then
        return
    end
    
    -- Track options panel state BEFORE throttle (so we don't miss open/close)
    local optionsPanelOpen = IsOptionsPanelOpen()
    local wasOpen = state.optionsPanelWasOpen
    state.optionsPanelWasOpen = optionsPanelOpen
    
    -- When options panel JUST OPENED, reset ALL groups to grid positions
    -- Pixel positioning is cleared so users can freely edit icon positions
    if optionsPanelOpen and not wasOpen then
        if ns.CDMGroups.groups then
            local savedPositions = ns.CDMGroups.savedPositions or {}
            for groupName, group in pairs(ns.CDMGroups.groups) do
                if group._usePixelPositioning then
                    -- Clear pixel positioning flags
                    group._usePixelPositioning = nil
                    group._pixelOffsets = nil
                    group._activeOrder = nil
                    
                    -- Restore member.row/col to saved positions for grid editing
                    if group.members then
                        for cdID, member in pairs(group.members) do
                            local saved = savedPositions[cdID]
                            if saved and saved.type == "group" and saved.target == groupName then
                                if saved.row ~= nil and saved.col ~= nil then
                                    member.row = saved.row
                                    member.col = saved.col
                                end
                            end
                        end
                    end
                    
                    -- Trigger layout to reposition icons to grid
                    if group.Layout then
                        group:Layout()
                    end
                end
            end
        end
    end
    
    -- When options panel JUST CLOSED, trigger layout to restore pixel positioning
    if not optionsPanelOpen and wasOpen then
        if ns.CDMGroups.groups then
            for groupName, group in pairs(ns.CDMGroups.groups) do
                -- All groups get Layout() to re-enable pixel positioning
                -- For groups with Dynamic Auras, this also handles aura compaction
                if group.Layout then
                    if group.autoReflow and group.ReflowIcons then
                        group:ReflowIcons()
                    else
                        group:Layout()
                    end
                end
            end
        end
    end
    
    -- Skip all processing when options panel is open
    if optionsPanelOpen then return end
    
    -- Throttle
    elapsed = elapsed + dt
    if elapsed < CONFIG.CHECK_INTERVAL then return end
    elapsed = 0
    
    -- PERFORMANCE: Clear per-tick cache at start of each check cycle
    wipe(state.tickInvisibleCache)
    
    -- Skip during spec changes
    if ns.CDMGroups.specChangeInProgress then return end
    if ns.CDMGroups._pendingSpecChange then return end
    
    -- Skip during restoration
    if ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd then
        return
    end
    
    -- Skip if waiting for post-talent refresh (handled by OnReconcileComplete)
    if state.pendingPostTalentRefresh then return end
    
    -- Check all groups with dynamic layout enabled
    if not ns.CDMGroups.groups then return end
    
    -- PERFORMANCE: Only run expensive HasGridMismatch check periodically
    local now = GetTime()
    local shouldCheckMismatch = (now - state.lastMismatchCheckTime) >= CONFIG.MISMATCH_CHECK_INTERVAL
    
    for groupName, group in pairs(ns.CDMGroups.groups) do
        -- CRITICAL: Check BOTH autoReflow (master toggle) AND dynamicLayout (aura behavior)
        -- dynamicLayout is meaningless without autoReflow - it's a sub-feature
        if group.autoReflow and group.dynamicLayout then
            local changed = CheckGroupForChanges(group, shouldCheckMismatch)
            if changed then
                state.pendingReflows[groupName] = group
            end
        end
    end
    
    -- Update mismatch check timestamp if we did check
    if shouldCheckMismatch then
        state.lastMismatchCheckTime = now
    end
    
    -- Process reflows
    if next(state.pendingReflows) then
        ProcessPendingReflows()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- GROUP MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

-- Set dynamic layout on/off for a group
function DL.SetEnabled(group, enabled)
    if not group then return end
    
    group.dynamicLayout = enabled
    
    -- Ensure alignment has a default value when enabling dynamicLayout
    -- The UI shows "Center" as default but if alignment was never changed, it's nil
    -- Having an explicit alignment value ensures consistent behavior across all code paths
    if enabled and group.layout and not group.layout.alignment then
        local rows = group.layout.gridRows or 1
        local cols = group.layout.gridCols or 1
        local gridShape = ns.CDMGroups and ns.CDMGroups.DetectGridShape and ns.CDMGroups.DetectGridShape(rows, cols) or "horizontal"
        local defaultAlignment = ns.CDMGroups and ns.CDMGroups.GetDefaultAlignment and ns.CDMGroups.GetDefaultAlignment(gridShape) or "center"
        group.layout.alignment = defaultAlignment
        -- Also save to DB
        local db = group.getDB and group.getDB()
        if db then
            db.alignment = defaultAlignment
        end
    end
    
    -- Clear visibility tracking for this group
    if group.members then
        for cdID, _ in pairs(group.members) do
            state.iconVisibility[cdID] = nil
        end
    end
    
    -- Clear any pending reflows for this group
    if group.name then
        state.pendingReflows[group.name] = nil
    end
    
    if enabled then
        -- If enabling, trigger immediate reflow
        if not IsOptionsPanelOpen() then
            if group.ReflowIcons then
                C_Timer.After(0.1, function()
                    if group.ReflowIcons and not IsOptionsPanelOpen() then
                        group:ReflowIcons()
                    end
                end)
            end
        end
    else
        -- If DISABLING, clear pixel positioning state so it doesn't persist
        -- This prevents "ghost" dynamic layout behavior after toggle off
        group._usePixelPositioning = nil
        group._pixelOffsets = nil
        group._activeOrder = nil
        
        -- Trigger layout to restore grid-based positions
        if group.Layout and not IsOptionsPanelOpen() then
            C_Timer.After(0.1, function()
                if group.Layout and not IsOptionsPanelOpen() then
                    group:Layout()
                end
            end)
        end
    end
end

-- Check if dynamic layout is enabled
function DL.IsEnabled(group)
    return group and group.dynamicLayout == true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- REFLOW GROUP - Unified reflow logic (moved from CDMGroups.lua)
-- 
-- REFLOW MODE (this function):
--   - Cooldowns MOVE to fill gaps
--   - Active auras MOVE to fill gaps  
--   - Inactive auras = empty spaces (gaps) - skipped
--   - Result: Compact layout with no visual holes
--
-- DYNAMIC POSITIONING MODE (CalculateDynamicSlots, used by Layout):
--   - Cooldowns = WALLS (stay at reflowed positions)
--   - Active auras = flow dynamically around cooldowns
--   - Inactive auras = hidden at saved positions
-- ═══════════════════════════════════════════════════════════════════════════

-- Helper: Check if member has a valid frame
local function HasValidFrame(member, cdID)
    if not member or not member.frame then return false end
    local frame = member.frame
    if not frame.IsShown then return false end
    
    -- Check cooldownID matches
    local frameCdID = frame.cooldownID
    if frameCdID ~= cdID then return false end
    
    return true
end

-- Helper: Get saved position info
local function GetSavedPosition(cdID, groupName)
    local saved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[cdID]
    if saved and saved.type == "group" and saved.target == groupName then
        return saved
    end
    return nil
end

-- Helper: Save position to savedPositions
-- NOTE: ns.CDMGroups.savedPositions IS profile.savedPositions (direct reference)
-- so writing here writes directly to the Arc Manager profile
local function SavePosition(cdID, groupName, row, col, sortIndex)
    if not ns.CDMGroups.savedPositions then
        -- savedPositions should always be initialized by OnSpecChange
        -- If it's nil, something is wrong - don't create a disconnected table
        return
    end
    ns.CDMGroups.savedPositions[cdID] = {
        type = "group",
        target = groupName,
        row = row,
        col = col,
        sortIndex = sortIndex or (row * 100 + col),
    }
end

-- Collect and categorize group members for reflow
-- Returns: { toReflow = {}, toSkip = {}, toRemove = {} }
--
-- REFLOW MODE (this function feeds ReflowGroup):
--   - Cooldowns -> toReflow (they MOVE to fill gaps)
--   - Active auras -> toReflow (they MOVE to fill gaps)
--   - Inactive auras -> toSkip (treated as gaps, when dynamic ON)
--
-- Note: "Walls" concept only applies in Layout's CalculateDynamicSlots,
-- where CDs stay at their REFLOWED position while auras animate around them.
function DL.CollectMembersForReflow(group)
    local result = {
        toReflow = {},   -- Icons that will be reflowed (cooldowns + active auras)
        toSkip = {},     -- Icons to skip (inactive auras when dynamic ON)
        toRemove = {},   -- Members without valid frames (cleanup)
    }
    
    if not group or not group.members then
        return result
    end
    
    local maxCols = group.layout and group.layout.gridCols or 4
    local dynEnabled = group.dynamicLayout and group.autoReflow
    
    for cdID, member in pairs(group.members) do
        -- Store cdID on member for type detection
        member.cdID = cdID
        
        -- Skip placeholders entirely
        if member.isPlaceholder then
            -- Placeholders don't participate in reflow
        elseif not HasValidFrame(member, cdID) then
            -- No valid frame - mark for removal (but save position first)
            table.insert(result.toRemove, {
                cdID = cdID,
                member = member,
            })
        else
            -- Has valid frame - categorize
            local isAura = DL.IsAuraFrame(member)
            local isActive = true
            
            -- Hidden by bar tracking = always treat as inactive gap
            if member.frame and member.frame._arcHiddenByBar then
                isActive = false
            -- Only check aura active state when dynamic layout is enabled
            -- When Dynamic Auras is OFF, auras are always "active" (same as cooldowns)
            elseif dynEnabled and isAura then
                isActive = DL.IsAuraActive(member)
            end
            
            -- Always compute sortIndex from current row/col position
            -- Don't use saved.sortIndex as it may be stale from old growth-direction-reversal logic
            -- The current row/col already reflects the user's intended order
            local sortIndex
            if member.row ~= nil and member.col ~= nil then
                sortIndex = member.row * maxCols + member.col
            else
                -- Fallback to saved position if member has no row/col yet
                local saved = GetSavedPosition(cdID, group.name)
                if saved and saved.row ~= nil and saved.col ~= nil then
                    sortIndex = saved.row * maxCols + saved.col
                else
                    sortIndex = 9999
                end
            end
            
            local iconData = {
                cdID = cdID,
                member = member,
                isAura = isAura,
                isActive = isActive,
                sortIndex = sortIndex,
                row = member.row,
                col = member.col,
            }
            
            -- When dynamic is ON: inactive auras and bar-hidden frames are gaps
            -- When dynamic is OFF: everything reflows (except bar-hidden)
            local isBarHidden = member.frame and member.frame._arcHiddenByBar
            if isBarHidden or (dynEnabled and isAura and not isActive) then
                -- Inactive/hidden = skip (treat as gap)
                table.insert(result.toSkip, iconData)
            else
                -- Cooldown OR active aura = include in reflow
                -- CDs always move during reflow!
                table.insert(result.toReflow, iconData)
            end
        end
    end
    
    -- Sort toReflow by sortIndex (preserves user order)
    table.sort(result.toReflow, function(a, b)
        if a.sortIndex ~= b.sortIndex then
            return a.sortIndex < b.sortIndex
        end
        -- Tiebreaker: cdID for stability
        -- Handle mixed types (string Arc Auras vs numeric CDM IDs)
        local aType, bType = type(a.cdID), type(b.cdID)
        if aType ~= bType then
            -- Numbers sort before strings
            return aType == "number"
        end
        return a.cdID < b.cdID
    end)
    
    return result
end

-- Calculate slot positions for reflow based on grid shape and alignment
-- Returns: list of {row, col} positions in fill order
function DL.BuildReflowSlotOrder(group, count, blockedSlots)
    blockedSlots = blockedSlots or {}
    local maxRows = group.layout and group.layout.gridRows or 2
    local maxCols = group.layout and group.layout.gridCols or 4
    local alignment = group.layout and group.layout.alignment
    
    local gridShape = ns.CDMGroups.DetectGridShape and ns.CDMGroups.DetectGridShape(maxRows, maxCols) or "multi"
    if not alignment then
        alignment = ns.CDMGroups.GetDefaultAlignment and ns.CDMGroups.GetDefaultAlignment(gridShape) or "left"
    end
    
    local slots = {}
    
    if gridShape == "horizontal" then
        -- Single row: collect available (non-blocked) columns
        local availCols = {}
        for col = 0, maxCols - 1 do
            if not blockedSlots[col] then  -- row 0, so linear index = col
                table.insert(availCols, col)
            end
        end
        
        local numAvail = #availCols
        local startIdx = 1  -- 1-indexed into availCols
        local emptySlots = numAvail - count
        if emptySlots > 0 then
            if alignment == "center" then
                startIdx = math.floor(emptySlots / 2) + 1
            elseif alignment == "right" then
                startIdx = emptySlots + 1
            end
        end
        
        for i = 0, count - 1 do
            local idx = startIdx + i
            if availCols[idx] then
                table.insert(slots, { row = 0, col = availCols[idx] })
            end
        end
        
    elseif gridShape == "vertical" then
        -- Single column: collect available (non-blocked) rows
        local availRows = {}
        for row = 0, maxRows - 1 do
            local linearIdx = row * maxCols  -- col 0
            if not blockedSlots[linearIdx] then
                table.insert(availRows, row)
            end
        end
        
        local numAvail = #availRows
        local startIdx = 1
        local emptySlots = numAvail - count
        if emptySlots > 0 then
            if alignment == "center" then
                startIdx = math.floor(emptySlots / 2) + 1
            elseif alignment == "bottom" then
                startIdx = emptySlots + 1
            end
        end
        
        for i = 0, count - 1 do
            local idx = startIdx + i
            if availRows[idx] then
                table.insert(slots, { row = availRows[idx], col = 0 })
            end
        end
        
    else
        -- Multi-dimensional: linear fill skipping blocked slots
        if alignment == "right" then
            -- Collect available slots per row, fill from right
            local placed = 0
            for row = 0, maxRows - 1 do
                local rowAvail = {}
                for col = 0, maxCols - 1 do
                    local linearIdx = row * maxCols + col
                    if not blockedSlots[linearIdx] then
                        table.insert(rowAvail, col)
                    end
                end
                -- Fill from right side of available slots
                local needed = math.min(count - placed, #rowAvail)
                local start = #rowAvail - needed + 1
                for i = start, #rowAvail do
                    if placed < count then
                        table.insert(slots, { row = row, col = rowAvail[i] })
                        placed = placed + 1
                    end
                end
            end
        elseif alignment == "bottom" then
            -- Collect all available slots, fill from bottom
            local allAvail = {}
            for row = 0, maxRows - 1 do
                for col = 0, maxCols - 1 do
                    local linearIdx = row * maxCols + col
                    if not blockedSlots[linearIdx] then
                        table.insert(allAvail, { row = row, col = col })
                    end
                end
            end
            local startIdx = math.max(1, #allAvail - count + 1)
            for i = startIdx, #allAvail do
                table.insert(slots, allAvail[i])
            end
        else
            -- Default: left/top alignment (linear fill, skip blocked)
            local placed = 0
            for row = 0, maxRows - 1 do
                for col = 0, maxCols - 1 do
                    if placed >= count then break end
                    local linearIdx = row * maxCols + col
                    if not blockedSlots[linearIdx] then
                        table.insert(slots, { row = row, col = col })
                        placed = placed + 1
                    end
                end
                if placed >= count then break end
            end
        end
    end
    
    return slots
end

-- Main reflow function - call this instead of group:ReflowIcons() body
-- Handles: compacting cooldowns + active auras together, inactive auras as gaps
-- After reflow, CDs stay at their new positions while auras animate around them
function DL.ReflowGroup(group)
    if not group then return end
    
    local maxRows = group.layout and group.layout.gridRows or 2
    local maxCols = group.layout and group.layout.gridCols or 4
    
    -- Collect and categorize members
    local members = DL.CollectMembersForReflow(group)
    
    -- Handle removals (save position first)
    for _, data in ipairs(members.toRemove) do
        local cdID = data.cdID
        local member = data.member
        
        -- Ensure position is saved before removing
        if not GetSavedPosition(cdID, group.name) then
            local sortIdx = (member.row or 0) * maxCols + (member.col or 0)
            SavePosition(cdID, group.name, member.row or 0, member.col or 0, sortIdx)
        end
        
        -- Clear from grid
        if member.row and member.col and group.grid and group.grid[member.row] then
            group.grid[member.row][member.col] = nil
        end
        
        -- Remove from members
        group.members[cdID] = nil
    end
    
    -- Clear grid
    group.grid = {}
    for row = 0, maxRows - 1 do
        group.grid[row] = {}
    end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- CRITICAL FIX: Reserve toSkip members' positions BEFORE building slots
    -- Bar-hidden and inactive aura members stay at their current positions.
    -- Their slots must be blocked so toReflow members don't land on top.
    -- ═══════════════════════════════════════════════════════════════════════
    local blockedSlots = {}
    for _, iconData in ipairs(members.toSkip) do
        local member = iconData.member
        if member.row and member.col and member.row >= 0 and member.col >= 0
           and member.row < maxRows and member.col < maxCols then
            local linearIdx = member.row * maxCols + member.col
            blockedSlots[linearIdx] = true
            -- Place in grid to reserve the slot
            group.grid[member.row][member.col] = iconData.cdID
        end
    end
    
    -- Get slot order for reflow (respects blocked slots from toSkip members)
    local slots = DL.BuildReflowSlotOrder(group, #members.toReflow, blockedSlots)
    
    -- Place icons into slots
    for i, iconData in ipairs(members.toReflow) do
        local slot = slots[i]
        if slot then
            local cdID = iconData.cdID
            local member = iconData.member
            
            -- Update member position
            member.row = slot.row
            member.col = slot.col
            
            -- Update grid
            group.grid[slot.row][slot.col] = cdID
        end
    end
    
    -- Mark grid dirty
    if group.MarkGridDirty then
        group:MarkGridDirty()
    end
    
    -- Log reflow
    state.lastReflowTime[group.name] = GetTime()
    state.reflowCount[group.name] = (state.reflowCount[group.name] or 0) + 1
    
    return #members.toReflow, #members.toSkip, #members.toRemove
end

-- Clear all visibility tracking (call on spec change, profile switch, etc.)
function DL.ClearTracking()
    wipe(state.iconVisibility)
    wipe(state.pendingReflows)
    wipe(state.lastReflowTime)
    wipe(state.reflowCount)
    wipe(state.lastMismatchDetected)
    wipe(state.eventLog)
    state.talentChangeTime = 0
    state.pendingPostTalentRefresh = false
end

-- Force refresh all dynamic groups
function DL.RefreshAll()
    if IsOptionsPanelOpen() then return end
    if not ns.CDMGroups.groups then return end
    
    -- Clear and rebuild visibility tracking
    wipe(state.iconVisibility)
    
    for groupName, group in pairs(ns.CDMGroups.groups) do
        -- CRITICAL: Check BOTH autoReflow (master toggle) AND dynamicLayout (aura behavior)
        -- dynamicLayout is meaningless without autoReflow - it's a sub-feature
        if group.autoReflow and group.dynamicLayout then
            -- Re-initialize visibility tracking
            if group.members then
                for cdID, member in pairs(group.members) do
                    if not member.isPlaceholder and member.frame then
                        local isVisible = not DL.IsIconInvisible(member)
                        state.iconVisibility[cdID] = isVisible
                    end
                end
            end
            
            if group.ReflowIcons then
                group:ReflowIcons()
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEHOLDER RESOLUTION NOTIFICATION
-- Called when a placeholder becomes a real frame, so visibility tracking can update
-- ═══════════════════════════════════════════════════════════════════════════

-- Notify that a placeholder was resolved to a real frame
-- This clears stale visibility tracking so the next check will re-evaluate
function DL.OnPlaceholderResolved(cdID, groupName)
    if not cdID then return end
    
    -- Clear visibility tracking for this cdID
    -- Next CheckGroupForChanges will re-evaluate and see the real frame
    state.iconVisibility[cdID] = nil
    
    -- If we know the group, queue it for potential reflow
    if groupName and ns.CDMGroups.groups then
        local group = ns.CDMGroups.groups[groupName]
        -- CRITICAL: Check BOTH autoReflow (master toggle) AND dynamicLayout (aura behavior)
        -- dynamicLayout is meaningless without autoReflow - it's a sub-feature
        if group and group.autoReflow and group.dynamicLayout then
            state.pendingReflows[groupName] = group
            LogEvent("PLACEHOLDER_RESOLVED", groupName, string.format("cdID %s resolved, queued reflow", tostring(cdID)))
        end
    end
end

-- Notify that a placeholder was created from a real frame
-- This also clears visibility tracking
function DL.OnPlaceholderCreated(cdID, groupName)
    if not cdID then return end
    
    -- Clear visibility tracking
    state.iconVisibility[cdID] = nil
    
    LogEvent("PLACEHOLDER_CREATED", groupName or "unknown", string.format("cdID %s became placeholder", tostring(cdID)))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

ns.CDMGroups.DynamicLayout = DL