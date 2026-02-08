-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI CDMGroups Layout - Icon sizing and positioning helpers
-- Extracted from CDMGroups.lua for maintainability
-- 
-- LOAD ORDER: After Maintain.lua, before CDMGroups.lua
-- EXPORTS: 
--   Helpers: IsCDMGroupsEnabled, ShouldDisableTooltips, ShouldMakeClickThrough, ApplyClickThrough
--   Layout: GetSlotDimensions, SetupFrameInContainer, RefreshIconSettings,
--           OnIconSizeChanged, RefreshAllGroupLayouts, ProcessDirtyGrids,
--           RefreshIconLayout, RefreshAllLayouts
-- ═══════════════════════════════════════════════════════════════════════════

local addonName, ns = ...

-- Ensure namespace exists (Maintain.lua creates it first)
ns.CDMGroups = ns.CDMGroups or {}

-- Use shared constants and helpers
local Shared = ns.CDMShared

-- ═══════════════════════════════════════════════════════════════════════════
-- SHARED HELPER FUNCTIONS
-- These are the canonical versions - other files should use ns.CDMGroups.X
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- CACHED SETTINGS (avoid GetCDMGroupsDB calls in hot paths)
-- These settings rarely change - cache them and refresh on settings change
-- ═══════════════════════════════════════════════════════════════════════════
local cachedSettings = {
    tooltipsDisabled = false,
    clickThroughEnabled = false,
    initialized = false,
}

-- Refresh cached settings from DB (call on settings change)
local function RefreshCachedLayoutSettings()
    local db = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
    if db then
        cachedSettings.tooltipsDisabled = db.disableTooltips == true
        cachedSettings.clickThroughEnabled = db.clickThrough == true
        cachedSettings.initialized = true
    end
end
ns.CDMGroups.RefreshCachedLayoutSettings = RefreshCachedLayoutSettings

-- Check if CDMGroups is enabled
local function IsCDMGroupsEnabled()
    -- Use the centralized check from CDM_Shared (reads ns.db.global.cdmStylingEnabled)
    -- This ensures consistency with the toggle
    if Shared and Shared.IsCDMStylingEnabled then
        return Shared.IsCDMStylingEnabled()
    end
    -- Fallback to char storage if Shared not available
    local db = Shared.GetCDMGroupsDB()
    if not db then return false end
    return db.enabled ~= false
end
ns.CDMGroups.IsCDMGroupsEnabled = IsCDMGroupsEnabled

-- Check if tooltips should be disabled (CACHED - no DB call)
local function ShouldDisableTooltips()
    -- Initialize on first call if needed
    if not cachedSettings.initialized then
        RefreshCachedLayoutSettings()
    end
    return cachedSettings.tooltipsDisabled
end
ns.CDMGroups.ShouldDisableTooltips = ShouldDisableTooltips

-- Check if click-through should be enabled (CACHED for DB read, live for state checks)
-- Returns false when options panel is open (to allow dragging)
local function ShouldMakeClickThrough()
    -- Initialize on first call if needed
    if not cachedSettings.initialized then
        RefreshCachedLayoutSettings()
    end
    -- These checks must be DIRECT (not cached) - state changes immediately when panel closes
    -- Don't apply click-through when options panel is open - user needs to interact with icons
    local ACD = LibStub("AceConfigDialog-3.0", true)
    local panelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] and true or false
    if panelOpen then
        return false
    end
    -- Don't apply click-through when drag mode is enabled
    if ns.CDMGroups and ns.CDMGroups.dragModeEnabled then
        return false
    end
    -- Cached DB setting
    return cachedSettings.clickThroughEnabled
end
ns.CDMGroups.ShouldMakeClickThrough = ShouldMakeClickThrough

-- Apply click-through to a frame and all its overlays
-- CDMGroups owns this - CDMEnhance should NOT handle click-through
local function ApplyClickThrough(frame, enable)
    if not frame then return end
    
    if enable then
        frame:EnableMouse(false)
        
        -- Disable ArcUI overlays
        local overlays = { frame._arcOverlay, frame._arcTextOverlay, frame._arcIconOverlay }
        for _, overlay in ipairs(overlays) do
            if overlay and overlay.EnableMouse then
                overlay:EnableMouse(false)
            end
        end
        
        -- Disable text drag overlays
        if frame._arcChargeText and frame._arcChargeText._arcDragOverlay then
            frame._arcChargeText._arcDragOverlay:EnableMouse(false)
        end
        if frame._arcCooldownText and frame._arcCooldownText._arcDragOverlay then
            frame._arcCooldownText._arcDragOverlay:EnableMouse(false)
        end
        
        -- Disable all other children
        for _, child in pairs({frame:GetChildren()}) do
            if child.EnableMouse then child:EnableMouse(false) end
        end
        
        -- Also disable children of _arcTextOverlay
        if frame._arcTextOverlay then
            for _, child in pairs({frame._arcTextOverlay:GetChildren()}) do
                if child.EnableMouse then child:EnableMouse(false) end
            end
        end
    else
        -- Re-enable mouse on frame
        frame:EnableMouse(true)
        
        -- CRITICAL: For CDMGroups-managed frames, NEVER enable overlay mouse!
        -- The overlay sits on TOP of the frame and would INTERCEPT all clicks.
        -- Only enable overlays for non-CDMGroups frames (legacy behavior).
        local parent = frame:GetParent()
        local isCDMGroupsManaged = (parent and parent._isCDMGContainer)
        
        -- Also check if it's a CDMGroups free icon
        if not isCDMGroupsManaged and ns.CDMGroups and ns.CDMGroups.freeIcons then
            local cdID = frame.cooldownID
            if cdID and ns.CDMGroups.freeIcons[cdID] then
                isCDMGroupsManaged = true
            end
        end
        
        if not isCDMGroupsManaged then
            -- Non-CDMGroups frames: re-enable overlays (legacy behavior)
            if frame._arcOverlay and frame._arcOverlay.EnableMouse then
                frame._arcOverlay:EnableMouse(true)
            end
            if frame._arcTextOverlay and frame._arcTextOverlay.EnableMouse then
                frame._arcTextOverlay:EnableMouse(true)
            end
        else
            -- CDMGroups-managed: ALWAYS keep overlays disabled
            if frame._arcOverlay and frame._arcOverlay.EnableMouse then
                frame._arcOverlay:EnableMouse(false)
            end
            if frame._arcTextOverlay and frame._arcTextOverlay.EnableMouse then
                frame._arcTextOverlay:EnableMouse(false)
            end
        end
        
        -- Re-enable text drag overlays if text drag mode is active
        local textDragMode = ns.CDMEnhance and ns.CDMEnhance.IsTextDragMode and ns.CDMEnhance.IsTextDragMode()
        if textDragMode then
            if frame._arcChargeText and frame._arcChargeText._arcDragOverlay then
                frame._arcChargeText._arcDragOverlay:EnableMouse(true)
            end
            if frame._arcCooldownText and frame._arcCooldownText._arcDragOverlay then
                frame._arcCooldownText._arcDragOverlay:EnableMouse(true)
            end
        end
    end
end
ns.CDMGroups.ApplyClickThrough = ApplyClickThrough

-- ═══════════════════════════════════════════════════════════════════════════
-- SLOT DIMENSIONS
-- Calculate effective slot dimensions from layout settings
-- iconWidth/iconHeight are base dimensions, iconSize acts as scale (36 = 100%)
-- ═══════════════════════════════════════════════════════════════════════════

local function GetSlotDimensions(layout)
    local baseScale = 36
    local iconSize = layout.iconSize or 36
    local iconWidth = layout.iconWidth or 36
    local iconHeight = layout.iconHeight or 36
    local scale = iconSize / baseScale
    return iconWidth * scale, iconHeight * scale
end
ns.CDMGroups.GetSlotDimensions = GetSlotDimensions

-- ═══════════════════════════════════════════════════════════════════════════
-- TOOLTIP HELPER
-- Apply tooltip settings to a frame (enable/disable OnEnter/OnLeave)
-- ═══════════════════════════════════════════════════════════════════════════

local function ApplyTooltipSettings(frame, disableTooltips)
    if not frame then return end
    
    -- ALWAYS store original handlers if we don't have them yet and frame has scripts
    -- This ensures we capture CDM's scripts before we ever modify them
    if not frame._arcOrigOnEnter then
        local currentOnEnter = frame:GetScript("OnEnter")
        if currentOnEnter then
            frame._arcOrigOnEnter = currentOnEnter
        end
    end
    if not frame._arcOrigOnLeave then
        local currentOnLeave = frame:GetScript("OnLeave")
        if currentOnLeave then
            frame._arcOrigOnLeave = currentOnLeave
        end
    end
    
    if disableTooltips then
        -- Disable tooltips
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
    else
        -- Restore original handlers if we have them
        if frame._arcOrigOnEnter then
            frame:SetScript("OnEnter", frame._arcOrigOnEnter)
        end
        if frame._arcOrigOnLeave then
            frame:SetScript("OnLeave", frame._arcOrigOnLeave)
        end
    end
end
ns.CDMGroups.ApplyTooltipSettings = ApplyTooltipSettings

-- ═══════════════════════════════════════════════════════════════════════════
-- SETUP FRAME IN CONTAINER
-- Setup frame properties for container placement
-- NOTE: Does NOT set alpha or visibility - CDMEnhance handles inactive state
-- ═══════════════════════════════════════════════════════════════════════════

local function SetupFrameInContainer(frame, container, slotW, slotH, cooldownID)
    if not frame then return slotW, slotH end
    
    -- CRITICAL: Clear free icon flag so parent hooks don't fight us
    frame._cdmgIsFreeIcon = nil
    frame._cdmgFreeTargetSize = nil
    
    frame:SetParent(container)
    frame:SetFrameStrata("MEDIUM")
    frame:SetScale(1)
    
    -- CRITICAL: Clear old position immediately (especially important for free icons joining groups)
    frame:ClearAllPoints()
    
    -- CRITICAL: MUST show frame initially - CDMEnhance will hide if inactive LATER
    -- EXCEPT: Skip showing if frame is hidden due to hideWhenUnequipped setting or hidden by bar tracking
    if not frame._arcHiddenUnequipped and not frame._arcHiddenByBar then
        frame:SetAlpha(1)
        frame:Show()
    end
    frame._arcRecoveryProtection = GetTime() + 0.5
    
    -- Default to slot dimensions
    local effectiveW = slotW
    local effectiveH = slotH
    
    -- Check for per-icon size override from CDMEnhance
    -- ONLY apply custom size when useGroupScale is explicitly OFF
    if cooldownID and ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
        local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cooldownID)
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
    
    -- Update target size and use flag to bypass hook
    frame._cdmgTargetSize = math.max(effectiveW, effectiveH)
    frame._cdmgSlotW = slotW  -- Store GROUP's slot dimensions for useGroupScale
    frame._cdmgSlotH = slotH
    frame._cdmgSettingSize = true
    frame:SetSize(effectiveW, effectiveH)
    frame._cdmgSettingSize = false
    
    -- Disable any CDMEnhance overlay stealing mouse events
    -- CDMGroups-managed frames should NEVER have overlay mouse enabled
    if frame._arcOverlay then
        frame._arcOverlay:EnableMouse(false)
        frame._arcOverlay:RegisterForDrag()
    end
    if frame._arcTextOverlay then
        frame._arcTextOverlay:EnableMouse(false)
    end
    
    -- CLICK-THROUGH: Apply based on DIRECT DB read and DIRECT panel check
    -- Do NOT use ShouldMakeClickThrough() or ShouldAllowDrag() - they use cached values
    -- that can be stale for 0.25s after panel closes
    if not ns.CDMGroups.dragModeEnabled then
        -- Check panel directly
        local ACD = LibStub("AceConfigDialog-3.0", true)
        local panelOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] and true or false
        
        if not panelOpen then
            -- Read click-through directly from DB
            local clickThroughEnabled = false
            local db = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
            if db then
                clickThroughEnabled = db.clickThrough == true
            end
            ApplyClickThrough(frame, clickThroughEnabled)
        end
    end
    
    -- Return effective dimensions for centering calculations
    return effectiveW, effectiveH
end

-- Export
ns.CDMGroups.SetupFrameInContainer = SetupFrameInContainer

-- ═══════════════════════════════════════════════════════════════════════════
-- REFRESH ICON SETTINGS
-- Apply tooltip/click-through settings to all managed icons
-- Called when global options are changed
-- ═══════════════════════════════════════════════════════════════════════════

-- Called when global options are changed or when options panel closes
function ns.CDMGroups.RefreshIconSettings()
    -- CRITICAL: Refresh cached settings first - DB values may have changed
    RefreshCachedLayoutSettings()
    
    local inDragMode = ns.CDMGroups.dragModeEnabled
    
    -- CRITICAL: Read click-through setting DIRECTLY from DB
    -- Do NOT use ShouldMakeClickThrough() because it checks cached panel state
    -- which may be stale (0.25s update interval) when panel just closed
    local clickThroughEnabled = false
    local db = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
    if db then
        clickThroughEnabled = db.clickThrough == true
    end
    
    -- Check if panel is ACTUALLY open right now (direct check, not cached)
    local ACD = LibStub("AceConfigDialog-3.0", true)
    local panelActuallyOpen = ACD and ACD.OpenFrames and ACD.OpenFrames["ArcUI"] and true or false
    
    -- Only apply click-through if: setting enabled AND drag mode off AND panel closed
    local clickThrough = clickThroughEnabled and not inDragMode and not panelActuallyOpen
    
    -- Re-setup all icons in groups
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        -- Container mouse: NEVER enable when not in edit mode
        -- Container sits above child frames and would intercept clicks
        -- Only enable when inDragMode or panel is open (edit mode)
        if group and group.container then
            local editModeActive = inDragMode or panelActuallyOpen
            if editModeActive then
                group.container:EnableMouse(true)
            else
                group.container:EnableMouse(false)
            end
        end
        
        -- Apply to dragBar
        if group and group.dragBar then
            if clickThrough then
                group.dragBar:EnableMouse(false)
            else
                group.dragBar:EnableMouse(inDragMode)
            end
        end
        
        -- Apply to selectionHighlight
        if group and group.selectionHighlight then
            group.selectionHighlight:EnableMouse(false)
        end
        
        -- Apply to members
        if group and group.members then
            for cdID, member in pairs(group.members) do
                if member.frame and group.container then
                    -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
                    -- Otherwise ClearAllPoints hooks will restore wrong centering offset
                    member.frame._cdmgTargetX = nil
                    member.frame._cdmgTargetY = nil
                    member.frame._cdmgTargetPoint = nil
                    member.frame._cdmgTargetRelPoint = nil
                    
                    local slotW, slotH = GetSlotDimensions(group.layout)
                    local effW, effH = SetupFrameInContainer(member.frame, group.container, slotW, slotH, cdID)
                    -- Update cached effective dimensions so Layout() calculates correct centering
                    if effW and effH then
                        member._effectiveIconW = effW
                        member._effectiveIconH = effH
                        -- Store cache version so Layout() knows this is valid
                        member._effectiveCacheVersion = ns.CDMEnhance and ns.CDMEnhance.GetCacheVersion and ns.CDMEnhance.GetCacheVersion() or 0
                    end
                    ApplyClickThrough(member.frame, clickThrough)
                end
            end
        end
    end
    
    -- Also refresh free icons
    for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
        if data.frame then
            ApplyClickThrough(data.frame, clickThrough)
        end
    end
    
    -- CRITICAL: Call Layout() on all groups to recalculate positions with new effective dimensions
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        if group and group.Layout then
            group:Layout()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ON ICON SIZE CHANGED
-- Called by CDMEnhance when an icon's size (width/height/scale) is changed
-- Triggers a group Layout() so container can expand/contract
-- ═══════════════════════════════════════════════════════════════════════════

function ns.CDMGroups.OnIconSizeChanged(cdID)
    if not IsCDMGroupsEnabled() then return end
    if not cdID then return end
    
    -- FIRST: Check if icon is actually in a group (check actual membership, not just savedPositions)
    -- This handles cases where savedPositions might be stale or wrong
    local foundGroup = nil
    local foundMember = nil
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        if group.members then
            -- Check both number and string keys (serialization can change key types)
            local member = group.members[cdID] or group.members[tostring(cdID)]
            if member then
                foundGroup = group
                foundMember = member
                break
            end
        end
    end
    
    if foundGroup and foundMember then
        if foundMember.frame and foundGroup.container then
            -- Icon is in a group - update its size
            -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
            -- Otherwise ClearAllPoints hooks will restore wrong centering offset
            foundMember.frame._cdmgTargetX = nil
            foundMember.frame._cdmgTargetY = nil
            foundMember.frame._cdmgTargetPoint = nil
            foundMember.frame._cdmgTargetRelPoint = nil
            
            local slotW, slotH = GetSlotDimensions(foundGroup.layout)
            local effW, effH = SetupFrameInContainer(foundMember.frame, foundGroup.container, slotW, slotH, cdID)
            
            -- Update cached effective dimensions so Layout() calculates correct centering
            if effW and effH then
                foundMember._effectiveIconW = effW
                foundMember._effectiveIconH = effH
                -- Store cache version so Layout() knows this is valid
                foundMember._effectiveCacheVersion = ns.CDMEnhance and ns.CDMEnhance.GetCacheVersion and ns.CDMEnhance.GetCacheVersion() or 0
            end
            
            -- Then recalculate container bounds
            if foundGroup.Layout then
                foundGroup:Layout()
            end
            return
        end
    end
    
    -- SECOND: Check if icon is a free icon (check both key types)
    local freeData = nil
    if ns.CDMGroups.freeIcons then
        freeData = ns.CDMGroups.freeIcons[cdID] or ns.CDMGroups.freeIcons[tostring(cdID)]
    end
    
    if freeData and freeData.frame then
        -- Get effective size from CDMEnhance settings
        local effectiveSize = 36  -- default
        if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
            local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cdID)
            if cfg then
                -- Free icons always use custom scale (useGroupScale doesn't apply)
                local baseW = cfg.width or 36
                local baseH = cfg.height or 36
                local scale = cfg.scale or 1.0
                effectiveSize = math.max(baseW, baseH) * scale
            end
        end
        
        -- Update free icon size
        freeData.iconSize = effectiveSize
        freeData.frame._cdmgFreeTargetSize = effectiveSize
        freeData.frame._cdmgSettingSize = true
        freeData.frame:SetSize(effectiveSize, effectiveSize)
        freeData.frame._cdmgSettingSize = false
        return
    end
    
    -- FALLBACK: Try savedPositions (legacy path) - check both key types
    local saved = ns.CDMGroups.savedPositions and (ns.CDMGroups.savedPositions[cdID] or ns.CDMGroups.savedPositions[tostring(cdID)])
    if saved and saved.type == "group" and saved.target then
        local group = ns.CDMGroups.groups and ns.CDMGroups.groups[saved.target]
        if group then
            local member = group.members and (group.members[cdID] or group.members[tostring(cdID)])
            if member and member.frame and group.container then
                -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
                member.frame._cdmgTargetX = nil
                member.frame._cdmgTargetY = nil
                member.frame._cdmgTargetPoint = nil
                member.frame._cdmgTargetRelPoint = nil
                
                local slotW, slotH = GetSlotDimensions(group.layout)
                local effW, effH = SetupFrameInContainer(member.frame, group.container, slotW, slotH, cdID)
                if effW and effH then
                    member._effectiveIconW = effW
                    member._effectiveIconH = effH
                    -- Store cache version so Layout() knows this is valid
                    member._effectiveCacheVersion = ns.CDMEnhance and ns.CDMEnhance.GetCacheVersion and ns.CDMEnhance.GetCacheVersion() or 0
                end
            end
            
            if group.Layout then
                group:Layout()
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- REFRESH ALL GROUP LAYOUTS
-- Called by CDMEnhanceOptions when icon appearance settings change
-- Refreshes all group layouts to recalculate container bounds AND update icon sizes
-- ═══════════════════════════════════════════════════════════════════════════

function ns.CDMGroups.RefreshAllGroupLayouts()
    if not IsCDMGroupsEnabled() then return end
    
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        if group then
            -- First update icon sizes via SetupFrameInContainer
            if group.members and group.container then
                local slotW, slotH = GetSlotDimensions(group.layout)
                
                for cdID, member in pairs(group.members) do
                    if member.frame then
                        -- CRITICAL: Clear stale cached position BEFORE SetupFrameInContainer
                        -- Otherwise ClearAllPoints hooks will restore wrong centering offset
                        member.frame._cdmgTargetX = nil
                        member.frame._cdmgTargetY = nil
                        member.frame._cdmgTargetPoint = nil
                        member.frame._cdmgTargetRelPoint = nil
                        
                        local effW, effH = SetupFrameInContainer(member.frame, group.container, slotW, slotH, cdID)
                        -- Update cached effective dimensions so Layout() calculates correct centering
                        if effW and effH then
                            member._effectiveIconW = effW
                            member._effectiveIconH = effH
                            -- Store cache version so Layout() knows this is valid
                            member._effectiveCacheVersion = ns.CDMEnhance and ns.CDMEnhance.GetCacheVersion and ns.CDMEnhance.GetCacheVersion() or 0
                        end
                    end
                end
            end
            
            -- Then recalculate container bounds
            if group.Layout then
                group:Layout()
            end
        end
    end
    
    -- Also refresh free icon sizes
    for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
        if data.frame then
            local effectiveW = data.iconSize or 36
            local effectiveH = data.iconSize or 36
            
            -- Check for per-icon size settings
            -- NOTE: Free icons ALWAYS apply custom scale/width/height since they don't belong to a group
            if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cdID)
                if cfg then
                    local baseW = cfg.width or data.iconSize or 36
                    local baseH = cfg.height or data.iconSize or 36
                    local scale = cfg.scale or 1.0
                    effectiveW = baseW * scale
                    effectiveH = baseH * scale
                end
            end
            
            -- Use _cdmgSettingSize flag to bypass hook
            data.frame._cdmgSettingSize = true
            data.frame:SetSize(effectiveW, effectiveH)
            data.frame._cdmgSettingSize = false
            
            -- Update stored target size for hooks
            data.frame._cdmgFreeTargetSize = math.max(effectiveW, effectiveH)
        end
    end
    
    -- Trigger Masque refresh so skins update to new frame sizes
    if ns.Masque and ns.Masque.QueueRefresh then
        ns.Masque.QueueRefresh()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROCESS DIRTY GRIDS
-- Called periodically to batch save dirty grids
-- ═══════════════════════════════════════════════════════════════════════════

function ns.CDMGroups.ProcessDirtyGrids()
    for _, group in pairs(ns.CDMGroups.groups or {}) do
        if group._gridDirty then
            group:SaveGrid()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- REFRESH ICON LAYOUT
-- Refresh layout for a specific cooldownID or all groups (immediate)
-- ═══════════════════════════════════════════════════════════════════════════

function ns.CDMGroups.RefreshIconLayout(cooldownID)
    if cooldownID then
        -- Find which group contains this icon
        for _, group in pairs(ns.CDMGroups.groups or {}) do
            if group.members and group.members[cooldownID] then
                group:Layout()
                return
            end
        end
        -- Check free icons
        if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cooldownID] then
            local data = ns.CDMGroups.freeIcons[cooldownID]
            if data.frame then
                local effectiveW = data.iconSize or 36
                local effectiveH = data.iconSize or 36
                
                -- NOTE: Free icons ALWAYS apply custom scale/width/height since they don't belong to a group
                if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                    local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cooldownID)
                    if cfg then
                        local baseW = cfg.width or data.iconSize or 36
                        local baseH = cfg.height or data.iconSize or 36
                        local scale = cfg.scale or 1.0
                        effectiveW = baseW * scale
                        effectiveH = baseH * scale
                    end
                end
                -- Use _cdmgSettingSize flag to bypass hook
                data.frame._cdmgSettingSize = true
                data.frame:SetSize(effectiveW, effectiveH)
                data.frame._cdmgSettingSize = false
                -- Update stored target size for hooks
                data.frame._cdmgFreeTargetSize = math.max(effectiveW, effectiveH)
            end
        end
    else
        -- Refresh all groups
        for _, group in pairs(ns.CDMGroups.groups or {}) do
            if group.Layout then
                group:Layout()
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- REFRESH ALL LAYOUTS
-- Alias for CDMEnhance compatibility
-- ═══════════════════════════════════════════════════════════════════════════

function ns.CDMGroups.RefreshAllLayouts()
    ns.CDMGroups.RefreshIconLayout(nil)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ALIGNMENT ANCHOR SYSTEM
-- Calculates offset to center/align icons within their available space
-- ═══════════════════════════════════════════════════════════════════════════

-- Detect grid shape and return appropriate alignment options
-- Returns: "horizontal" (1 row), "vertical" (1 col), or "multi" (N×M)
local function DetectGridShape(rows, cols)
    if rows == 1 then
        return "horizontal"  -- Single row: left/center/right
    elseif cols == 1 then
        return "vertical"    -- Single column: top/center/bottom
    else
        return "multi"       -- Multi-dimensional: top/bottom/left/right/center
    end
end
ns.CDMGroups.DetectGridShape = DetectGridShape

-- Get valid alignment options for a grid shape
local function GetAlignmentOptions(gridShape)
    if gridShape == "horizontal" then
        return { "left", "center", "right" }
    elseif gridShape == "vertical" then
        return { "top", "center", "bottom" }
    else -- multi
        return { "top", "bottom", "left", "right", "center_h", "center_v" }
    end
end
ns.CDMGroups.GetAlignmentOptions = GetAlignmentOptions

-- Get default alignment for a grid shape
-- 1D grids (single row or column) default to center for visual balance
-- Multi-dimensional grids default to top
local function GetDefaultAlignment(gridShape)
    if gridShape == "horizontal" or gridShape == "vertical" then
        return "center"
    else
        return "top"  -- Multi-dimensional defaults to top
    end
end
ns.CDMGroups.GetDefaultAlignment = GetDefaultAlignment

-- Count icons per row and per column
-- Returns: iconsPerRow[row] = count, iconsPerCol[col] = count
local function CountIconsPerRowCol(members, rows, cols)
    local iconsPerRow = {}
    local iconsPerCol = {}
    
    -- Initialize
    for r = 0, rows - 1 do iconsPerRow[r] = 0 end
    for c = 0, cols - 1 do iconsPerCol[c] = 0 end
    
    -- Count
    for cdID, member in pairs(members) do
        if member and member.row ~= nil and member.col ~= nil then
            local r, c = member.row, member.col
            if r >= 0 and r < rows then
                iconsPerRow[r] = (iconsPerRow[r] or 0) + 1
            end
            if c >= 0 and c < cols then
                iconsPerCol[c] = (iconsPerCol[c] or 0) + 1
            end
        end
    end
    
    return iconsPerRow, iconsPerCol
end
ns.CDMGroups.CountIconsPerRowCol = CountIconsPerRowCol

-- Calculate alignment offset for a specific row (horizontal alignment)
-- alignment: "left", "center", "right"
-- Returns: pixel offset to add to X position
local function CalculateRowAlignmentOffset(row, iconsPerRow, cols, slotW, spacingX, alignment)
    if not alignment or alignment == "left" then
        return 0  -- No offset for left alignment
    end
    
    local iconCount = iconsPerRow[row] or 0
    if iconCount == 0 or iconCount >= cols then
        return 0  -- No offset if empty or full
    end
    
    local emptySlots = cols - iconCount
    local slotWidth = slotW + spacingX
    
    if alignment == "center" then
        return (emptySlots / 2) * slotWidth
    elseif alignment == "right" then
        return emptySlots * slotWidth
    end
    
    return 0
end
ns.CDMGroups.CalculateRowAlignmentOffset = CalculateRowAlignmentOffset

-- Calculate alignment offset for a specific column (vertical alignment)
-- alignment: "top", "center", "bottom"
-- Returns: pixel offset to add to Y position (negative because Y goes down)
local function CalculateColAlignmentOffset(col, iconsPerCol, rows, slotH, spacingY, alignment)
    if not alignment or alignment == "top" then
        return 0  -- No offset for top alignment
    end
    
    local iconCount = iconsPerCol[col] or 0
    if iconCount == 0 or iconCount >= rows then
        return 0  -- No offset if empty or full
    end
    
    local emptySlots = rows - iconCount
    local slotHeight = slotH + spacingY
    
    if alignment == "center" then
        return -(emptySlots / 2) * slotHeight  -- Negative because Y is inverted
    elseif alignment == "bottom" then
        return -emptySlots * slotHeight
    end
    
    return 0
end
ns.CDMGroups.CalculateColAlignmentOffset = CalculateColAlignmentOffset

-- ═══════════════════════════════════════════════════════════════════════════
-- GRID CONFLICT RESOLUTION
-- Handles case where multiple members claim the same row/col position
-- ═══════════════════════════════════════════════════════════════════════════

-- Resolve grid conflicts for a group - detects and fixes duplicate positions
-- Priority: frames with valid CDM frames > placeholders > frameless members
-- Returns: number of conflicts resolved
local function ResolveGridConflicts(group)
    if not group or not group.members then return 0 end
    
    -- THROTTLE: Skip if called for same group within 200ms
    local now = GetTime()
    local lastCall = group._lastConflictResolve or 0
    if (now - lastCall) < 0.2 then
        return 0  -- Too soon, skip
    end
    group._lastConflictResolve = now
    
    -- Build map of row/col -> list of members claiming that position
    -- CRITICAL: EXCLUDE placeholders from conflict detection!
    -- Placeholders are intentional reservations that CAN coexist with real icons
    -- (e.g., talent alternatives sharing the same slot)
    local positionMap = {}  -- "row,col" -> { cdID1, cdID2, ... }
    
    for cdID, member in pairs(group.members) do
        -- Skip placeholders - they don't conflict, they're slot reservations
        if not member.isPlaceholder and member.row ~= nil and member.col ~= nil then
            local key = member.row .. "," .. member.col
            positionMap[key] = positionMap[key] or {}
            table.insert(positionMap[key], cdID)
        end
    end
    
    local conflictsResolved = 0
    
    -- Find and resolve conflicts (ONLY between non-placeholder members)
    for key, cdIDs in pairs(positionMap) do
        if #cdIDs > 1 then
            -- Multiple NON-PLACEHOLDER members at same position - resolve
            -- Sort by priority: has frame > first encountered (lower cdID)
            table.sort(cdIDs, function(a, b)
                local memberA = group.members[a]
                local memberB = group.members[b]
                
                -- Handle members that were removed during iteration (race condition)
                if not memberA and not memberB then return false end
                if not memberA then return false end  -- B wins if A is gone
                if not memberB then return true end   -- A wins if B is gone
                
                -- Priority 1: Has valid frame
                local aHasFrame = memberA.frame and memberA.frame:IsShown()
                local bHasFrame = memberB.frame and memberB.frame:IsShown()
                if aHasFrame and not bHasFrame then return true end
                if bHasFrame and not aHasFrame then return false end
                
                -- Priority 2: Compare cdIDs (handle mixed string/number types)
                local aType, bType = type(a), type(b)
                if aType ~= bType then
                    -- Numbers sort before strings
                    return aType == "number"
                end
                return a < b
            end)
            
            -- Keep the winner at current position, move others
            local winner = cdIDs[1]
            local winnerMember = group.members[winner]
            
            -- Skip if winner was removed during iteration
            if not winnerMember then
                -- Try next in list as winner
                for idx = 2, #cdIDs do
                    winnerMember = group.members[cdIDs[idx]]
                    if winnerMember then
                        winner = cdIDs[idx]
                        break
                    end
                end
            end
            
            -- Only proceed if we found a valid winner
            if winnerMember and winnerMember.row and winnerMember.col then
                local row, col = winnerMember.row, winnerMember.col
                
                -- Ensure grid reference points to winner
                if not group.grid[row] then group.grid[row] = {} end
                group.grid[row][col] = winner
                
                -- Move losers to free slots
                for i = 2, #cdIDs do
                    local loserCdID = cdIDs[i]
                    if loserCdID ~= winner then  -- Skip if this became the winner
                        local loserMember = group.members[loserCdID]
                        
                        -- Skip if loser was removed during iteration
                        if loserMember then
                            -- Find a free slot for the loser
                            local newRow, newCol
                            if group.FindNextFreeSlot then
                                newRow, newCol = group:FindNextFreeSlot(true)  -- Allow expansion
                            end
                            
                            if newRow and newCol then
                                -- Move to free slot
                                loserMember.row = newRow
                                loserMember.col = newCol
                                
                                -- Update grid
                                if not group.grid[newRow] then group.grid[newRow] = {} end
                                group.grid[newRow][newCol] = loserCdID
                                
                                -- Update saved position
                                if ns.CDMGroups.SaveGroupPosition then
                                    ns.CDMGroups.SaveGroupPosition(loserCdID, group.name, newRow, newCol)
                                else
                                    -- Fallback: Use GetProfileSavedPositions to ensure correct table
                                    local profileSavedPositions = ns.CDMGroups.GetProfileSavedPositions and ns.CDMGroups.GetProfileSavedPositions()
                                    if profileSavedPositions then
                                        profileSavedPositions[loserCdID] = {
                                            type = "group",
                                            target = group.name,
                                            row = newRow,
                                            col = newCol,
                                        }
                                    end
                                end
                                
                                conflictsResolved = conflictsResolved + 1
                            else
                                -- No slot available even with expansion - make it a free icon
                                -- Calculate position relative to the group (offset to the right)
                                local ux, uy = UIParent:GetCenter()
                                local cx, cy = 0, 0
                                if group.container and group.container:GetCenter() then
                                    cx, cy = group.container:GetCenter()
                                end
                                local containerW = group.container and group.container:GetWidth() or 100
                                
                                -- Position to the right of the group container
                                local freeX = (cx - ux) + containerW / 2 + 50 + (i - 2) * 45
                                local freeY = cy - uy
                                
                                -- Remove from group
                                group.members[loserCdID] = nil
                                
                                -- Create as free icon or update saved position
                                if loserMember.frame and ns.CDMGroups.TrackFreeIcon then
                                    ns.CDMGroups.TrackFreeIcon(loserCdID, loserMember.frame, loserMember.entry, freeX, freeY)
                                else
                                    -- Fallback: Use GetProfileSavedPositions to ensure correct table
                                    local profileSavedPositions = ns.CDMGroups.GetProfileSavedPositions and ns.CDMGroups.GetProfileSavedPositions()
                                    if profileSavedPositions then
                                        local posData = {
                                            type = "free",
                                            x = freeX,
                                            y = freeY,
                                            iconSize = group.layout and group.layout.iconSize or 36,
                                        }
                                        profileSavedPositions[loserCdID] = posData
                                        if ns.CDMGroups.SavePositionToSpec then
                                            ns.CDMGroups.SavePositionToSpec(loserCdID, posData)
                                        end
                                    end
                                end
                                
                                conflictsResolved = conflictsResolved + 1
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- AFTER resolving real conflicts, ensure grid references are correct for placeholders
    -- Placeholders can claim empty grid slots (slots not occupied by real icons)
    for cdID, member in pairs(group.members) do
        if member.isPlaceholder and member.row ~= nil and member.col ~= nil then
            local row, col = member.row, member.col
            if not group.grid[row] then group.grid[row] = {} end
            -- Only claim if slot is empty (real icons have priority)
            if not group.grid[row][col] then
                group.grid[row][col] = cdID
            end
        end
    end
    
    return conflictsResolved
end
ns.CDMGroups.ResolveGridConflicts = ResolveGridConflicts

-- Resolve grid conflicts for all groups
local function ResolveAllGridConflicts()
    local totalResolved = 0
    if ns.CDMGroups.groups then
        for gName, group in pairs(ns.CDMGroups.groups) do
            totalResolved = totalResolved + ResolveGridConflicts(group)
        end
    end
    return totalResolved
end
ns.CDMGroups.ResolveAllGridConflicts = ResolveAllGridConflicts

-- Calculate slot position with alignment support
-- This is the core positioning function used by group:Layout()
-- params table: {
--   row, col,              -- Grid position
--   rows, cols,            -- Grid dimensions
--   slotW, slotH,          -- Slot dimensions
--   spacingX, spacingY,    -- Spacing
--   padding, borderOffset, -- Container padding
--   leftOverflow, topOverflow,  -- Edge overflow for oversized icons
--   colCumulativeOffset, rowCumulativeOffset,  -- Cascade offset tables
--   alignment,             -- Alignment setting (optional)
--   iconsPerRow, iconsPerCol,  -- Icon counts (required for alignment)
--   gridShape,             -- "horizontal", "vertical", or "multi"
-- }
local function CalculateSlotPosition(params)
    local row = params.row
    local col = params.col
    local rows = params.rows
    local cols = params.cols
    local slotW = params.slotW
    local slotH = params.slotH
    local spacingX = params.spacingX
    local spacingY = params.spacingY
    local padding = params.padding or 0
    local borderOffset = params.borderOffset or 2
    local leftOverflow = params.leftOverflow or 0
    local topOverflow = params.topOverflow or 0
    local colCumulativeOffset = params.colCumulativeOffset or {}
    local rowCumulativeOffset = params.rowCumulativeOffset or {}
    local alignment = params.alignment
    local iconsPerRow = params.iconsPerRow or {}
    local iconsPerCol = params.iconsPerCol or {}
    local gridShape = params.gridShape or "multi"
    
    -- Get cascade offset for this column/row
    local cascadeOffsetX = colCumulativeOffset[col] or 0
    local cascadeOffsetY = rowCumulativeOffset[row] or 0
    
    -- Calculate alignment offset based on grid shape
    local alignmentOffsetX = 0
    local alignmentOffsetY = 0
    
    if alignment and alignment ~= "left" and alignment ~= "top" then
        if gridShape == "horizontal" then
            -- Single row: horizontal alignment applies
            alignmentOffsetX = CalculateRowAlignmentOffset(row, iconsPerRow, cols, slotW, spacingX, alignment)
        elseif gridShape == "vertical" then
            -- Single column: vertical alignment applies
            alignmentOffsetY = CalculateColAlignmentOffset(col, iconsPerCol, rows, slotH, spacingY, alignment)
        elseif gridShape == "multi" then
            -- Multi-dimensional: alignment applies to all rows or all columns
            if alignment == "right" then
                alignmentOffsetX = CalculateRowAlignmentOffset(row, iconsPerRow, cols, slotW, spacingX, alignment)
            elseif alignment == "bottom" then
                alignmentOffsetY = CalculateColAlignmentOffset(col, iconsPerCol, rows, slotH, spacingY, alignment)
            elseif alignment == "left" then
                -- Default behavior, no offset
            elseif alignment == "top" then
                -- Default behavior, no offset
            end
        end
    end
    
    -- Calculate base position (icons positioned at their logical col/row)
    -- NOTE: We no longer flip effectiveCol/effectiveRow based on growth direction
    -- Growth direction now only affects ReflowIcons fill order, not visual position
    local slotX = borderOffset + padding + leftOverflow + col * (slotW + spacingX) + cascadeOffsetX + alignmentOffsetX
    local slotY = -borderOffset - padding - topOverflow - row * (slotH + spacingY) - cascadeOffsetY + alignmentOffsetY
    
    return slotX, slotY
end
ns.CDMGroups.CalculateSlotPosition = CalculateSlotPosition