-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI CDMGroups Maintain - HOT PATH
-- All timer-based maintenance code consolidated here for easy auditing
-- This file runs at the throttle rate (default 5Hz) set in CDM_Shared
-- ═══════════════════════════════════════════════════════════════════════════

local addonName, ns = ...

-- Dependencies from other modules
local Shared = ns.CDMShared
local Registry = ns.FrameRegistry

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Set this to true to re-enable backup fighting in maintainer
-- (Hooks should handle this, but enable if you see flicker)
local MAINTAINER_BACKUP_ENABLED = _G.ARCUI_MAINTAINER_BACKUP or false

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER: Check if CDMGroups is enabled
-- ═══════════════════════════════════════════════════════════════════════════
local function IsCDMGroupsEnabled()
    return ns.CDMGroups and ns.CDMGroups.IsCDMGroupsEnabled and ns.CDMGroups.IsCDMGroupsEnabled()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FRAME HOOKS - Primary CDM fighting mechanism
-- These hooks fire INSTANTLY when CDM tries to modify our managed frames
-- Maintainers below are BACKUP (catch anything hooks miss)
-- ═══════════════════════════════════════════════════════════════════════════

-- Hook ClearAllPoints - restore position immediately for grouped icons
local function HookFrameClearAllPoints(frame)
    if frame._cdmgClearPointsHooked then return end
    
    hooksecurefunc(frame, "ClearAllPoints", function(self)
        if self._cdmgSettingPosition then return end
        if self._freeDragging or self._groupDragging then return end
        
        local parent = self:GetParent()
        if not parent or not parent._isCDMGContainer then return end
        
        if self._cdmgTargetPoint then
            self._cdmgSettingPosition = true
            self:SetPoint(
                self._cdmgTargetPoint,
                parent,
                self._cdmgTargetRelPoint or "TOPLEFT",
                self._cdmgTargetX or 0,
                self._cdmgTargetY or 0
            )
            self._cdmgSettingPosition = false
            ns.CDMGroups.fightStats.position = ns.CDMGroups.fightStats.position + 1
        end
    end)
    
    frame._cdmgClearPointsHooked = true
end

-- Hook SetScale - force scale back to 1
local function HookFrameScale(frame)
    if frame._cdmgScaleHooked then return end
    
    hooksecurefunc(frame, "SetScale", function(self, scale)
        if self._cdmgSettingScale then return end
        
        -- Skip Arc Aura frames - they manage their own scale via ArcAuras.ApplySettingsToFrame
        if self._arcAuraID then return end
        
        local parent = self:GetParent()
        -- Check if in container OR if it's a free icon (check frame flag directly, not cdID lookup)
        local isInContainer = parent and parent._isCDMGContainer
        local isFreeIcon = self._cdmgIsFreeIcon
        
        if not isInContainer and not isFreeIcon then return end
        
        -- Force scale to 1 (both container and free icons)
        if math.abs((scale or 1) - 1) > 0.01 then
            self._cdmgSettingScale = true
            self:SetScale(1)
            self._cdmgSettingScale = false
            ns.CDMGroups.fightStats.scale = ns.CDMGroups.fightStats.scale + 1
        end
    end)
    
    frame._cdmgScaleHooked = true
end

-- Hook SetSize - force size back to target
local function HookFrameSize(frame, targetSize)
    if frame._cdmgSizeHooked then return end
    
    hooksecurefunc(frame, "SetSize", function(self, w, h)
        if self._cdmgSettingSize then return end
        
        local parent = self:GetParent()
        -- Check if in container OR if it's a free icon (check frame flag directly)
        local isInContainer = parent and parent._isCDMGContainer
        local isFreeIcon = self._cdmgIsFreeIcon
        
        -- Arc Aura frames: Only enforce size if they're in a group container
        -- Free Arc Auras manage their own size via ArcAuras.ApplySettingsToFrame
        if self._arcAuraID and not isInContainer then return end
        
        if not isInContainer and not isFreeIcon then return end
        
        -- Get target size - for free icons, get from freeIcons table using frame ID
        local targetW, targetH
        if isFreeIcon then
            -- Use GetFrameID to support both cooldownID (CDM) and _arcAuraID (custom)
            local frameID = Shared.GetFrameID and Shared.GetFrameID(self) or self.cooldownID
            local freeData = frameID and ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[frameID]
            if freeData then
                -- Calculate effective size: width/height as base, scale as multiplier
                -- NOTE: Free icons ALWAYS apply custom scale/width/height since they don't belong to a group
                local baseSize = freeData.iconSize or 36
                targetW = baseSize
                targetH = baseSize
                if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                    local cfg = ns.CDMEnhance.GetEffectiveIconSettings(frameID)
                    if cfg then
                        -- Use width/height as base (if set), otherwise use iconSize
                        local baseW = cfg.width or baseSize
                        local baseH = cfg.height or baseSize
                        -- Apply scale as multiplier on top
                        local scale = cfg.scale or 1.0
                        targetW = baseW * scale
                        targetH = baseH * scale
                    end
                end
            else
                -- Fallback to stored target size
                local fallback = self._cdmgFreeTargetSize or 36
                targetW = fallback
                targetH = fallback
            end
        else
            -- GROUPED ICON: Use group's slot dimensions OR custom size
            -- Use GetFrameID to support both cooldownID and _arcAuraID
            local frameID = Shared.GetFrameID and Shared.GetFrameID(self) or self.cooldownID
            
            -- CRITICAL FIX: Use stored slot dimensions as the default
            -- These are set by Layout() and represent the GROUP's size
            local slotW = self._cdmgSlotW or self._cdmgTargetSize or 36
            local slotH = self._cdmgSlotH or self._cdmgTargetSize or 36
            targetW = slotW
            targetH = slotH
            
            if frameID and ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
                local cfg = ns.CDMEnhance.GetEffectiveIconSettings(frameID)
                -- ONLY apply custom size when useGroupScale is explicitly OFF
                if cfg and cfg.useGroupScale == false then
                    -- Use width/height as base (if set), otherwise use slot size
                    local baseW = cfg.width or slotW
                    local baseH = cfg.height or slotH
                    -- Apply scale as multiplier on top
                    local scale = cfg.scale or 1.0
                    targetW = baseW * scale
                    targetH = baseH * scale
                end
                -- When useGroupScale is true (default), use group's slot dimensions (already set above)
            end
        end
        
        -- Use 0.5 pixel tolerance (tight like reference CDMGroups)
        if math.abs((w or 0) - targetW) > 0.5 or math.abs((h or 0) - targetH) > 0.5 then
            self._cdmgSettingSize = true
            self:SetSize(targetW, targetH)
            self._cdmgSettingSize = false
            ns.CDMGroups.fightStats.size = ns.CDMGroups.fightStats.size + 1
        end
    end)
    
    frame._cdmgSizeHooked = true
end

-- Hook SetFrameStrata - force strata back to MEDIUM
local function HookFrameStrata(frame)
    if frame._cdmgStrataHooked then return end
    
    hooksecurefunc(frame, "SetFrameStrata", function(self, strata)
        if self._cdmgSettingStrata then return end
        
        local parent = self:GetParent()
        -- Check if in container OR if it's a free icon
        local isInContainer = parent and parent._isCDMGContainer
        local isFreeIcon = self._cdmgIsFreeIcon
        
        if not isInContainer and not isFreeIcon then return end
        
        -- Force strata to MEDIUM
        if strata ~= "MEDIUM" then
            self._cdmgSettingStrata = true
            self:SetFrameStrata("MEDIUM")
            self._cdmgSettingStrata = false
            ns.CDMGroups.fightStats.strata = ns.CDMGroups.fightStats.strata + 1
        end
    end)
    
    frame._cdmgStrataHooked = true
end

-- Hook SetParent - fight CDM trying to reparent free icons
local function HookFrameParent(frame)
    if frame._cdmgParentHooked then return end
    
    hooksecurefunc(frame, "SetParent", function(self, newParent)
        if self._cdmgSettingParent then return end
        
        -- Only fight for free icons
        if not self._cdmgIsFreeIcon then return end
        
        -- Free icons must stay parented to UIParent
        if newParent ~= UIParent then
            self._cdmgSettingParent = true
            self:SetParent(UIParent)
            self._cdmgSettingParent = false
        end
    end)
    
    frame._cdmgParentHooked = true
end

-- Hook ClearAllPoints - restore position immediately for free icons
local function HookFrameClearAllPointsFree(frame)
    if frame._cdmgClearPointsFreeHooked then return end
    
    hooksecurefunc(frame, "ClearAllPoints", function(self)
        if self._cdmgSettingPosition then return end
        if self._freeDragging then return end
        
        -- Only fight for free icons
        if not self._cdmgIsFreeIcon then return end
        
        -- Restore position from freeIcons data
        -- Use GetFrameID to support both cooldownID (CDM) and _arcAuraID (custom)
        local frameID = Shared.GetFrameID and Shared.GetFrameID(self) or self.cooldownID
        local freeData = frameID and ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[frameID]
        if freeData then
            self._cdmgSettingPosition = true
            self:SetPoint("CENTER", UIParent, "CENTER", freeData.x, freeData.y)
            self._cdmgSettingPosition = false
        end
    end)
    
    frame._cdmgClearPointsFreeHooked = true
end

-- Apply all hooks to a grouped frame
local function HookFrame(frame, targetSize)
    HookFrameClearAllPoints(frame)
    HookFrameScale(frame)
    HookFrameSize(frame, targetSize)
    HookFrameStrata(frame)
    frame._cdmgTargetSize = targetSize
end

-- Apply all hooks to a free icon frame
local function HookFreeIcon(frame, iconSize)
    HookFrameScale(frame)
    HookFrameSize(frame, iconSize)
    HookFrameParent(frame)
    HookFrameClearAllPointsFree(frame)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HOOK EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════
ns.CDMGroups = ns.CDMGroups or {}
ns.CDMGroups.HookFrameClearAllPoints = HookFrameClearAllPoints
ns.CDMGroups.HookFrameScale = HookFrameScale
ns.CDMGroups.HookFrameSize = HookFrameSize
ns.CDMGroups.HookFrameStrata = HookFrameStrata
ns.CDMGroups.HookFrame = HookFrame
ns.CDMGroups.HookFrameParent = HookFrameParent
ns.CDMGroups.HookFrameClearAllPointsFree = HookFrameClearAllPointsFree
ns.CDMGroups.HookFreeIcon = HookFreeIcon

-- ═══════════════════════════════════════════════════════════════════════════
-- SHARED HELPER: Find a frame by cooldownID in CDM viewers
-- Returns frame, viewerType, viewerName or nil
-- ═══════════════════════════════════════════════════════════════════════════
local function FindFrameInViewers(cdID)
    for _, viewerInfo in ipairs(Shared.CDM_VIEWERS) do
        local viewer = _G[viewerInfo.name]
        if viewer then
            local children = { viewer:GetChildren() }
            for _, child in ipairs(children) do
                if child.cooldownID == cdID then
                    return child, viewerInfo.type, viewerInfo.name
                end
            end
        end
    end
    return nil, nil, nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SHARED HELPER: Setup a frame as a free icon
-- Used by both reassignment handling and savedPositions restoration
-- Returns true if setup succeeded, false otherwise
-- ═══════════════════════════════════════════════════════════════════════════
local function SetupFreeIconFrame(cdID, frame, x, y, iconSize, viewerType, viewerName, existingData)
    if not frame or not cdID then return false end
    
    -- Setup frame properties
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    frame:SetFrameStrata("MEDIUM")
    frame:SetScale(1)
    frame:SetSize(iconSize, iconSize)
    
    -- Only show if not hidden due to hideWhenUnequipped setting
    if not frame._arcHiddenUnequipped then
        frame:Show()
    end
    
    -- Create or update freeIcons entry
    if existingData then
        -- Update existing entry
        existingData.frame = frame
        existingData.viewerType = viewerType
        existingData.originalViewerName = viewerName
    else
        -- Create new entry
        ns.CDMGroups.freeIcons[cdID] = {
            frame = frame,
            entry = Registry.byAddress[tostring(frame)],
            x = x,
            y = y,
            iconSize = iconSize,
            viewerType = viewerType,
            originalViewerName = viewerName,
        }
    end
    
    -- Install hooks
    frame._cdmgIsFreeIcon = true
    frame._cdmgFreeTargetSize = iconSize
    HookFrameScale(frame)
    HookFrameSize(frame, iconSize)
    HookFrameParent(frame)
    HookFrameStrata(frame)
    HookFrameClearAllPointsFree(frame)
    
    -- Update registry
    local entry = Registry.byAddress[tostring(frame)]
    if entry then
        entry.manipulated = true
        entry.manipulationType = "free"
    end
    
    -- Set recovery protection
    frame._arcRecoveryProtection = GetTime() + 0.5
    
    -- Re-enhance if this is a reassignment (existingData means we're updating)
    if existingData and ns.CDMEnhance and ns.CDMEnhance.EnhanceFrame then
        ns.CDMEnhance.EnhanceFrame(frame, cdID, viewerType)
    end
    
    -- Setup drag if in edit mode
    if ns.CDMGroups.dragModeEnabled and ns.CDMGroups.SetupFreeIconDrag then
        ns.CDMGroups.SetupFreeIconDrag(cdID)
    end
    
    return true
end

-- Export helpers
ns.CDMGroups.FindFrameInViewers = FindFrameInViewers
ns.CDMGroups.SetupFreeIconFrame = SetupFreeIconFrame


-- ═══════════════════════════════════════════════════════════════════════════
-- MAINTAINERS REMOVED - Now handled by FrameController
-- ═══════════════════════════════════════════════════════════════════════════
-- The following have been moved to ArcUI_FrameController.lua:
--
-- FreeIconMaintainer (was ~280 lines):
--   - Position enforcement → FrameController.VisualMaintainer
--   - Size enforcement → FrameController.VisualMaintainer
--   - Visual updates (ApplyIconVisuals) → FrameController.VisualMaintainer
--   - Edit button updates → FrameController.VisualMaintainer
--   - Frame recovery → FrameController.Reconcile + DoFollowupSweep
--
-- GroupIconStateMaintainer (was ~120 lines):
--   - Group icon visuals → FrameController.VisualMaintainer
--   - Options panel state tracking → FrameController.VisualMaintainer
--   - Placeholder editing mode → FrameController.VisualMaintainer
--   - Group Layout triggers → FrameController.Reconcile
--
-- The hook functions above (HookFrameScale, HookFrameSize, etc.) are kept
-- as they're still called by CDMGroups.TrackFreeIcon and SetupFrameInSlot.
-- FrameController also installs its own hooks via InstallFrameHooks().
-- ═══════════════════════════════════════════════════════════════════════════