-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI_CDMGroups_StateManager.lua
-- Handles spec changes, talent changes, profile activation, and restoration
-- Also provides hooks for CDM behavior analysis (future feature)
-- ═══════════════════════════════════════════════════════════════════════════

local ADDON, ns = ...

ns.CDMGroups = ns.CDMGroups or {}
ns.CDMGroups.StateManager = ns.CDMGroups.StateManager or {}

local StateManager = ns.CDMGroups.StateManager

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE FLAGS
-- Central location for all state tracking flags
-- ═══════════════════════════════════════════════════════════════════════════

-- State flags (initialized here, also initialized in main CDMGroups for safety)
local stateFlags = {
    -- Spec/Talent change flags
    specChangeInProgress = false,
    talentChangeInProgress = false,
    profileLoadInProgress = false,
    initialLoadInProgress = true,
    
    -- Pending operations
    _pendingSpecChange = nil,
    _talentCheckTimer = nil,
    
    -- Protection windows (GetTime() + duration)
    _restorationProtectionEnd = nil,
    _talentRestorationEnd = nil,
    
    -- Timestamps
    lastSpecChangeTime = nil,
    _lastProfileSwitchTime = nil,
    
    -- Grid expansion control
    blockGridExpansion = false,
}

-- Initialize state flags on ns.CDMGroups (for backward compatibility)
local function InitializeStateFlags()
    for key, defaultValue in pairs(stateFlags) do
        if ns.CDMGroups[key] == nil then
            ns.CDMGroups[key] = defaultValue
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function DebugPrint(...)
    if ns.CDMGroups and ns.CDMGroups.debugEnabled then
        print("|cff00ffff[CDMGroups.StateManager]|r", ...)
    end
end

local function PrintMsg(msg)
    if ns.CDMGroups and ns.CDMGroups.PrintMessage then
        ns.CDMGroups.PrintMessage(msg)
    else
        print("|cff00ff00ArcUI CDMGroups:|r", msg)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RESTORATION STATE CHECKING
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if we're currently in a restoration/transition state
-- Returns true if any operation is in progress that should block saves/reflows
local function IsRestoring()
    -- Check if initial load is in progress (blocks saves until first load completes)
    if ns.CDMGroups.initialLoadInProgress then return true end
    
    -- Check if spec change is currently in progress
    if ns.CDMGroups.specChangeInProgress then return true end
    if ns.CDMGroups._pendingSpecChange then return true end
    if ns.CDMGroups.talentChangeInProgress then return true end
    
    -- Check if profile load is in progress
    if ns.CDMGroups.profileLoadInProgress then return true end
    
    -- Check talent restoration protection window
    if ns.CDMGroups._talentRestorationEnd and GetTime() < ns.CDMGroups._talentRestorationEnd then
        return true
    end
    
    -- Check spec restoration protection window
    if ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd then
        return true
    end
    
    -- Check the time-based window after spec change completes
    if not ns.CDMGroups.lastSpecChangeTime then return false end
    -- Max 2 second window as fallback
    if (GetTime() - ns.CDMGroups.lastSpecChangeTime) >= 2 then return false end
    return true
end

-- Check if all saved positions have been restored (icons have valid frames)
local function IsRestorationComplete()
    if not ns.CDMGroups.savedPositions then return true end
    
    for cdID, saved in pairs(ns.CDMGroups.savedPositions) do
        -- CRITICAL: Only check cooldownIDs that are VALID for current spec/talents
        -- Saved positions for inactive talents should not block restoration
        if not ns.CDMGroups.IsCooldownIDValid or not ns.CDMGroups.IsCooldownIDValid(cdID) then
            -- Skip - this icon isn't available in current spec/talents
        elseif saved.type == "group" and saved.target then
            local group = ns.CDMGroups.groups[saved.target]
            if group and not group.members[cdID] then
                return false  -- Position exists but no member yet
            end
            if group and group.members[cdID] and not group.members[cdID].frame then
                return false  -- Member exists but no frame yet
            end
        elseif saved.type == "free" then
            if not ns.CDMGroups.freeIcons[cdID] then
                return false  -- Free icon position saved but not restored
            end
        end
    end
    return true
end

-- Check if restoration is complete and clear flags early if so
local function CheckRestorationComplete()
    if not ns.CDMGroups.lastSpecChangeTime then return end
    
    -- Don't check if spec change is actively in progress (will be handled when it completes)
    local wasSpecChanging = ns.CDMGroups.lastSpecChangeTime or ns.CDMGroups.specChangeInProgress or ns.CDMGroups._pendingSpecChange
    
    if wasSpecChanging and not ns.CDMGroups.initialLoadInProgress and IsRestorationComplete() then
        DebugPrint("|cff00ff00[StateManager]|r Restoration complete early - clearing flags")
        -- Clear restoration tracking
        ns.CDMGroups.specChangeInProgress = false
        ns.CDMGroups._pendingSpecChange = nil
        -- Keep lastSpecChangeTime set for the minimum 2s window
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROTECTION WINDOW MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

-- Set spec change protection window
local function SetSpecProtection(duration)
    duration = duration or 1.5
    ns.CDMGroups._restorationProtectionEnd = GetTime() + duration
    DebugPrint("|cff00ff00[StateManager]|r Spec protection window set:", duration, "s")
end

-- Set talent change protection window
local function SetTalentProtection(duration)
    duration = duration or 2.0
    ns.CDMGroups.talentChangeInProgress = true
    ns.CDMGroups._talentRestorationEnd = GetTime() + duration
    DebugPrint("|cff00ff00[StateManager]|r Talent protection window set:", duration, "s")
end

-- Clear talent protection
local function ClearTalentProtection()
    ns.CDMGroups.talentChangeInProgress = false
    ns.CDMGroups._talentRestorationEnd = nil
    DebugPrint("|cff00ff00[StateManager]|r Talent protection cleared")
end

-- Check if currently in spec protection window
local function IsInSpecProtection()
    return ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd
end

-- Check if currently in talent protection window
local function IsInTalentProtection()
    return ns.CDMGroups._talentRestorationEnd and GetTime() < ns.CDMGroups._talentRestorationEnd
end

-- Check if any protection window is active
local function IsInAnyProtection()
    return IsInSpecProtection() or IsInTalentProtection() 
        or ns.CDMGroups.specChangeInProgress 
        or ns.CDMGroups.talentChangeInProgress
        or ns.CDMGroups._pendingSpecChange
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CDM BEHAVIOR ANALYSIS (Future Feature)
-- Hooks to understand how CDM creates/destroys/reassigns frames
-- ═══════════════════════════════════════════════════════════════════════════

local CDMAnalysis = {
    enabled = false,
    log = {},
    maxLogEntries = 500,
    
    -- Frame tracking
    framesByAddress = {},  -- address -> { cdID, viewerName, created, destroyed }
    cdIDHistory = {},      -- cdID -> { frames = {}, reassignments = {} }
}

-- Log a CDM event for analysis
local function LogCDMEvent(eventType, data)
    if not CDMAnalysis.enabled then return end
    
    local entry = {
        time = GetTime(),
        event = eventType,
        data = data,
    }
    
    table.insert(CDMAnalysis.log, 1, entry)
    
    -- Trim log if too large
    while #CDMAnalysis.log > CDMAnalysis.maxLogEntries do
        table.remove(CDMAnalysis.log)
    end
    
    DebugPrint("|cffff00ff[CDMAnalysis]|r", eventType, data and data.cdID or "")
end

-- Track when CDM creates a new frame
local function TrackFrameCreated(frame, cdID, viewerName)
    if not CDMAnalysis.enabled then return end
    
    local addr = tostring(frame):match("0x%x+") or tostring(frame)
    
    CDMAnalysis.framesByAddress[addr] = {
        cdID = cdID,
        viewerName = viewerName,
        created = GetTime(),
        destroyed = nil,
    }
    
    -- Track cdID history
    if not CDMAnalysis.cdIDHistory[cdID] then
        CDMAnalysis.cdIDHistory[cdID] = { frames = {}, reassignments = {} }
    end
    table.insert(CDMAnalysis.cdIDHistory[cdID].frames, addr)
    
    LogCDMEvent("FRAME_CREATED", { cdID = cdID, frame = addr, viewer = viewerName })
end

-- Track when CDM destroys/hides a frame
local function TrackFrameDestroyed(frame, cdID)
    if not CDMAnalysis.enabled then return end
    
    local addr = tostring(frame):match("0x%x+") or tostring(frame)
    
    if CDMAnalysis.framesByAddress[addr] then
        CDMAnalysis.framesByAddress[addr].destroyed = GetTime()
    end
    
    LogCDMEvent("FRAME_DESTROYED", { cdID = cdID, frame = addr })
end

-- Track when CDM reassigns a frame to a different cooldownID
local function TrackFrameReassigned(frame, oldCdID, newCdID, viewerName)
    if not CDMAnalysis.enabled then return end
    
    local addr = tostring(frame):match("0x%x+") or tostring(frame)
    
    -- Update frame tracking
    if CDMAnalysis.framesByAddress[addr] then
        CDMAnalysis.framesByAddress[addr].cdID = newCdID
    end
    
    -- Track reassignment in both cdID histories
    local reassignData = {
        time = GetTime(),
        frame = addr,
        from = oldCdID,
        to = newCdID,
        viewer = viewerName,
    }
    
    if CDMAnalysis.cdIDHistory[oldCdID] then
        table.insert(CDMAnalysis.cdIDHistory[oldCdID].reassignments, reassignData)
    end
    if not CDMAnalysis.cdIDHistory[newCdID] then
        CDMAnalysis.cdIDHistory[newCdID] = { frames = {}, reassignments = {} }
    end
    table.insert(CDMAnalysis.cdIDHistory[newCdID].reassignments, reassignData)
    
    LogCDMEvent("FRAME_REASSIGNED", { 
        frame = addr, 
        oldCdID = oldCdID, 
        newCdID = newCdID, 
        viewer = viewerName 
    })
end

-- Get analysis summary
local function GetCDMAnalysisSummary()
    local summary = {
        totalFrames = 0,
        activeFrames = 0,
        destroyedFrames = 0,
        totalReassignments = 0,
        cdIDsTracked = 0,
    }
    
    for addr, data in pairs(CDMAnalysis.framesByAddress) do
        summary.totalFrames = summary.totalFrames + 1
        if data.destroyed then
            summary.destroyedFrames = summary.destroyedFrames + 1
        else
            summary.activeFrames = summary.activeFrames + 1
        end
    end
    
    for cdID, data in pairs(CDMAnalysis.cdIDHistory) do
        summary.cdIDsTracked = summary.cdIDsTracked + 1
        summary.totalReassignments = summary.totalReassignments + #data.reassignments
    end
    
    return summary
end

-- Enable/disable CDM analysis
local function SetCDMAnalysisEnabled(enabled)
    CDMAnalysis.enabled = enabled
    if not enabled then
        -- Clear data when disabled
        CDMAnalysis.log = {}
        CDMAnalysis.framesByAddress = {}
        CDMAnalysis.cdIDHistory = {}
    end
    DebugPrint("|cffff00ff[CDMAnalysis]|r", enabled and "ENABLED" or "DISABLED")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TALENT CHANGE HANDLING
-- ═══════════════════════════════════════════════════════════════════════════

-- Handle TRAIT_CONFIG_UPDATED event
local function OnTalentConfigUpdated()
    DebugPrint("|cffff00ff[TalentEvent]|r TRAIT_CONFIG_UPDATED fired")
    
    -- CRITICAL: Skip during initial load - events fire during startup
    if ns.CDMGroups.initialLoadInProgress then 
        DebugPrint("|cffff00ff[TalentEvent]|r   -> SKIPPED: Initial load in progress")
        return 
    end
    
    -- NEW: Let FrameController handle if enabled
    if _G.ARCUI_USE_FRAME_CONTROLLER and ns.FrameController then
        DebugPrint("|cff00ff00[TalentEvent]|r Delegating TRAIT_CONFIG_UPDATED to FrameController")
        -- FrameController will handle debouncing and reconciliation
        -- Don't set protection here - let FrameController manage it
        return
    end
    
    -- CRITICAL: Set protection IMMEDIATELY - CDM will reassign frames right after this event
    if not ns.CDMGroups.specChangeInProgress then
        SetTalentProtection(2.0)
    end
    
    -- Cooldown to prevent rapid profile switching
    if ns.CDMGroups._lastProfileSwitchTime and GetTime() - ns.CDMGroups._lastProfileSwitchTime < 2.0 then
        DebugPrint("|cffff00ff[TalentEvent]|r   -> BLOCKED: profile switch cooldown")
        return
    end
    
    if not ns.CDMGroups.specChangeInProgress and not ns.CDMGroups.profileLoadInProgress then
        -- Debounce: cancel any pending timer and start a new one
        if ns.CDMGroups._talentCheckTimer then
            ns.CDMGroups._talentCheckTimer:Cancel()
        end
        
        DebugPrint("|cffff00ff[TalentEvent]|r   -> Scheduling CheckAndActivateMatchingProfile in 0.5s")
        ns.CDMGroups._talentCheckTimer = C_Timer.NewTimer(0.5, function()
            ns.CDMGroups._talentCheckTimer = nil
            
            -- Double-check cooldown
            if ns.CDMGroups._lastProfileSwitchTime and GetTime() - ns.CDMGroups._lastProfileSwitchTime < 2.0 then
                DebugPrint("|cffff00ff[TalentEvent]|r     -> BLOCKED by profile switch cooldown")
                return
            end
            
            if not ns.CDMGroups.specChangeInProgress and not ns.CDMGroups.profileLoadInProgress then
                if ns.CDMGroups.CheckAndActivateMatchingProfile then
                    ns.CDMGroups.CheckAndActivateMatchingProfile()
                end
            end
        end)
    end
end

-- Handle COOLDOWN_VIEWER_DATA_LOADED event (CDM finished reassigning frames)
local function OnCooldownViewerDataLoaded()
    DebugPrint("|cffff00ff[TalentEvent]|r COOLDOWN_VIEWER_DATA_LOADED fired")
    
    -- MASTER TOGGLE: Do nothing if CDMGroups is disabled
    if ns.CDMGroups.IsCDMGroupsEnabled and not ns.CDMGroups.IsCDMGroupsEnabled() then return end
    
    -- CRITICAL: Skip during initial load - let PLAYER_ENTERING_WORLD handle initialization
    -- This event fires multiple times during startup and we don't want to extend protection
    if ns.CDMGroups.initialLoadInProgress then 
        DebugPrint("|cffff00ff[TalentEvent]|r   -> SKIPPED: Initial load in progress")
        return 
    end
    
    -- Skip if spec change is happening or pending
    if ns.CDMGroups.specChangeInProgress then return end
    if ns.CDMGroups._pendingSpecChange then return end
    
    -- Skip if actual spec differs from tracked spec
    if ns.CDMGroups.GetCurrentSpec then
        local actualSpec = ns.CDMGroups.GetCurrentSpec()
        if actualSpec ~= ns.CDMGroups.currentSpec then return end
    end
    
    -- Skip during restoration protection window
    if IsInSpecProtection() then return end
    
    -- Skip if profile load is in progress
    if ns.CDMGroups.profileLoadInProgress then return end
    
    -- Ensure talent protection is set
    if not IsInTalentProtection() then
        SetTalentProtection(1.5)
    end
    
    -- NEW: Let FrameController handle if enabled
    if _G.ARCUI_USE_FRAME_CONTROLLER and ns.FrameController then
        DebugPrint("|cff00ff00[TalentEvent]|r Delegating to FrameController")
        -- FrameController already got the event and is debouncing
        C_Timer.After(1.6, function()
            ClearTalentProtection()
        end)
        return
    end
    
    -- Wait for CDM to finish, then scan and restore
    C_Timer.After(0.15, function()
        -- Re-check conditions
        if ns.CDMGroups.specChangeInProgress then
            ClearTalentProtection()
            return
        end
        if ns.CDMGroups._pendingSpecChange then
            ClearTalentProtection()
            return
        end
        if ns.CDMGroups.profileLoadInProgress then
            ClearTalentProtection()
            return
        end
        
        -- Initial scan and layout
        if ns.CDMGroups.ScanAllViewers then
            ns.CDMGroups.ScanAllViewers()
        end
        if ns.CDMGroups.AutoAssignNewIcons then
            ns.CDMGroups.AutoAssignNewIcons()
        end
        for _, group in pairs(ns.CDMGroups.groups or {}) do
            if group.Layout then group:Layout() end
        end
        
        -- Force show all CDM icons
        if ns.CDMEnhance and ns.CDMEnhance.ForceShowAllCDMIcons then
            ns.CDMEnhance.ForceShowAllCDMIcons()
        end
        
        -- Retry scans at intervals
        C_Timer.After(0.3, function()
            if ns.CDMGroups.specChangeInProgress then return end
            if ns.CDMGroups.ScanAllViewers then ns.CDMGroups.ScanAllViewers() end
            if ns.CDMGroups.AutoAssignNewIcons then ns.CDMGroups.AutoAssignNewIcons() end
            for _, group in pairs(ns.CDMGroups.groups or {}) do
                if group.Layout then group:Layout() end
            end
        end)
        
        C_Timer.After(0.6, function()
            if ns.CDMGroups.specChangeInProgress then return end
            if ns.CDMGroups.ScanAllViewers then ns.CDMGroups.ScanAllViewers() end
            if ns.CDMGroups.AutoAssignNewIcons then ns.CDMGroups.AutoAssignNewIcons() end
            for _, group in pairs(ns.CDMGroups.groups or {}) do
                if group.Layout then group:Layout() end
            end
        end)
        
        -- Final cleanup after protection window
        C_Timer.After(1.6, function()
            ClearTalentProtection()
            
            if ns.CDMGroups.specChangeInProgress then return end
            
            -- Final scan and layout
            if ns.CDMGroups.ScanAllViewers then ns.CDMGroups.ScanAllViewers() end
            if ns.CDMGroups.AutoAssignNewIcons then ns.CDMGroups.AutoAssignNewIcons() end
            for _, group in pairs(ns.CDMGroups.groups or {}) do
                if group.Layout then group:Layout() end
            end
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- CRITICAL FIX: EnhanceFrame may have been skipped during talent change.
            -- Call EnhanceFrame on frames that were missed (_arcShowPandemic == nil).
            -- ═══════════════════════════════════════════════════════════════════════════
            local enhancedCount = 0
            
            -- Helper to determine viewerType
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
                DebugPrint("|cffff00ff[TalentEvent]|r Enhanced", enhancedCount, "frames that were skipped")
            end
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- CRITICAL: Use RefreshIconType("all") instead of RefreshAllIcons
            -- RefreshAllIcons only iterates over enhancedFrames table
            -- RefreshIconType iterates over CDMGroups.groups, freeIcons, AND enhancedFrames
            -- ═══════════════════════════════════════════════════════════════════════════
            if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
                ns.CDMEnhance.RefreshIconType("all")
                DebugPrint("|cffff00ff[TalentEvent]|r RefreshIconType('all') complete")
            elseif ns.CDMEnhance and ns.CDMEnhance.RefreshAllIcons then
                ns.CDMEnhance.RefreshAllIcons()
            end
            
            -- ═══════════════════════════════════════════════════════════════════════════
            -- CRITICAL FIX: Apply per-icon SIZE settings from GetEffectiveIconSettings
            -- RefreshIconType only applies visual styles (borders, glow)
            -- RefreshAllGroupLayouts applies size/scale via SetupFrameInContainer
            -- Without this, icons don't get their custom sizes until options panel opens!
            -- ═══════════════════════════════════════════════════════════════════════════
            if ns.CDMGroups.RefreshAllGroupLayouts then
                ns.CDMGroups.RefreshAllGroupLayouts()
                DebugPrint("|cffff00ff[TalentEvent]|r RefreshAllGroupLayouts() complete - sizes applied")
            end
            
            -- Now reflow is safe
            for _, group in pairs(ns.CDMGroups.groups or {}) do
                if group.autoReflow and group.ReflowIcons then
                    group:ReflowIcons()
                end
            end
            
            -- Resolve placeholders
            if ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.ResolvePlaceholders then
                ns.CDMGroups.Placeholders.ResolvePlaceholders()
            end
            
            -- Check profile match
            C_Timer.After(0.1, function()
                if ns.CDMGroups.CheckAndActivateMatchingProfile then
                    ns.CDMGroups.CheckAndActivateMatchingProfile()
                end
            end)
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SPEC CHANGE HANDLING
-- ═══════════════════════════════════════════════════════════════════════════

-- Handle PLAYER_SPECIALIZATION_CHANGED event
local function OnPlayerSpecializationChanged(unit)
    if unit and unit ~= "player" then return end
    
    DebugPrint("|cffff00ff[SpecChange]|r PLAYER_SPECIALIZATION_CHANGED fired")
    
    -- Mark spec change in progress immediately
    ns.CDMGroups.specChangeInProgress = true
    
    -- Get the new spec
    local newSpec = ns.CDMGroups.GetCurrentSpec and ns.CDMGroups.GetCurrentSpec() or "unknown"
    local oldSpec = ns.CDMGroups.currentSpec
    
    -- Skip if same spec
    if oldSpec == newSpec then
        ns.CDMGroups.specChangeInProgress = false
        return
    end
    
    -- Save current spec IMMEDIATELY before CDM reassigns frames
    if ns.CDMGroups.SaveSpecDataToDatabase then
        ns.CDMGroups.SaveSpecDataToDatabase(oldSpec)
    end
    
    -- Mark pending so other systems know a change is coming
    ns.CDMGroups._pendingSpecChange = newSpec
    
    -- Call the main OnSpecChange handler
    if ns.OnSpecChange then
        -- Pass skipSave=true since we already saved above
        ns.OnSpecChange(newSpec, oldSpec, true)
    end
    
    -- Clear pending flag (OnSpecChange sets specChangeInProgress = false when done)
    ns.CDMGroups._pendingSpecChange = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

-- Initialize
StateManager.Initialize = InitializeStateFlags

-- Restoration checking
StateManager.IsRestoring = IsRestoring
StateManager.IsRestorationComplete = IsRestorationComplete
StateManager.CheckRestorationComplete = CheckRestorationComplete

-- Protection windows
StateManager.SetSpecProtection = SetSpecProtection
StateManager.SetTalentProtection = SetTalentProtection
StateManager.ClearTalentProtection = ClearTalentProtection
StateManager.IsInSpecProtection = IsInSpecProtection
StateManager.IsInTalentProtection = IsInTalentProtection
StateManager.IsInAnyProtection = IsInAnyProtection

-- Event handlers
StateManager.OnTalentConfigUpdated = OnTalentConfigUpdated
StateManager.OnCooldownViewerDataLoaded = OnCooldownViewerDataLoaded
StateManager.OnPlayerSpecializationChanged = OnPlayerSpecializationChanged

-- CDM Analysis (future)
StateManager.CDMAnalysis = CDMAnalysis
StateManager.LogCDMEvent = LogCDMEvent
StateManager.TrackFrameCreated = TrackFrameCreated
StateManager.TrackFrameDestroyed = TrackFrameDestroyed
StateManager.TrackFrameReassigned = TrackFrameReassigned
StateManager.GetCDMAnalysisSummary = GetCDMAnalysisSummary
StateManager.SetCDMAnalysisEnabled = SetCDMAnalysisEnabled

-- Also export to ns.CDMGroups for backward compatibility
ns.CDMGroups.IsRestoring = IsRestoring
ns.CDMGroups.IsRestorationComplete = IsRestorationComplete
ns.CDMGroups.CheckRestorationComplete = CheckRestorationComplete

-- Debug command
SLASH_ARCUICDMSTATE1 = "/arcuicdmstate"
SlashCmdList["ARCUICDMSTATE"] = function(msg)
    print("|cff00ff00ArcUI CDMGroups State:|r")
    print("  specChangeInProgress:", tostring(ns.CDMGroups.specChangeInProgress))
    print("  talentChangeInProgress:", tostring(ns.CDMGroups.talentChangeInProgress))
    print("  profileLoadInProgress:", tostring(ns.CDMGroups.profileLoadInProgress))
    print("  _pendingSpecChange:", tostring(ns.CDMGroups._pendingSpecChange))
    print("  IsRestoring():", tostring(IsRestoring()))
    print("  IsInSpecProtection():", tostring(IsInSpecProtection()))
    print("  IsInTalentProtection():", tostring(IsInTalentProtection()))
    print("  currentSpec:", tostring(ns.CDMGroups.currentSpec))
    
    if msg == "analysis" then
        local summary = GetCDMAnalysisSummary()
        print("|cff00ff00CDM Analysis:|r")
        print("  Total frames:", summary.totalFrames)
        print("  Active frames:", summary.activeFrames)
        print("  Destroyed frames:", summary.destroyedFrames)
        print("  Total reassignments:", summary.totalReassignments)
        print("  CooldownIDs tracked:", summary.cdIDsTracked)
    elseif msg == "enable" then
        SetCDMAnalysisEnabled(true)
        print("CDM Analysis ENABLED")
    elseif msg == "disable" then
        SetCDMAnalysisEnabled(false)
        print("CDM Analysis DISABLED")
    end
end