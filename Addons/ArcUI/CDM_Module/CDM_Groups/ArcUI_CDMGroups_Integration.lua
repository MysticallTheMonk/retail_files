-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI CDMGroups Integration
-- Clean interface for external frames (Arc Auras, etc.) to integrate with CDMGroups
-- 
-- This module now uses FrameController for all frame assignment operations.
-- External frames call RegisterExternalFrame() and FrameController handles:
-- - Checking saved positions
-- - Adding to groups or making free icons
-- - Setting up drag
-- - Position saving
-- ═══════════════════════════════════════════════════════════════════════════

local ADDON, ns = ...

-- Ensure namespaces exist
ns.CDMGroups = ns.CDMGroups or {}
ns.CDMGroups.Integration = ns.CDMGroups.Integration or {}

local Integration = ns.CDMGroups.Integration
local Shared = ns.CDMShared
local Registry = ns.FrameRegistry

-- ═══════════════════════════════════════════════════════════════════════════
-- REGISTER EXTERNAL FRAME
-- Main entry point for external modules to register frames with CDMGroups
--
-- Parameters:
--   id          - Unique identifier (string for Arc Auras like "arc_trinket_13")
--   frame       - The frame to manage
--   viewerType  - "cooldown", "aura", or "utility" (default: "cooldown")
--   defaultGroup - Group to add to if no saved position (default: "Essential")
--
-- Returns: true if registered, false if failed
-- ═══════════════════════════════════════════════════════════════════════════

function Integration.RegisterExternalFrame(id, frame, viewerType, defaultGroup)
    if not id or not frame then
        return false
    end
    
    -- Defaults
    viewerType = viewerType or "cooldown"
    defaultGroup = defaultGroup or "Essential"
    
    -- Validate CDMGroups is ready with actual groups
    if not ns.CDMGroups.groups or not next(ns.CDMGroups.groups) then
        -- CDMGroups not initialized yet, defer
        C_Timer.After(1.0, function()
            Integration.RegisterExternalFrame(id, frame, viewerType, defaultGroup)
        end)
        return false
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CHECK FOR SAVED POSITION FIRST
    -- ═══════════════════════════════════════════════════════════════════════════
    local saved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[id]
    
    if saved then
        -- Use FrameController if available
        local Controller = ns.FrameController
        if Controller and Controller.AssignFrameToOwner then
            local cdmData = {
                frame = frame,
                viewerType = viewerType,
                viewerName = "ArcAurasViewer",
                defaultGroup = defaultGroup,
            }
            return Controller.AssignFrameToOwner(id, cdmData)
        end
        
        -- Fallback: Direct assignment to saved position
        if saved.type == "group" and saved.target then
            return Integration.AssignToGroup(id, frame, saved.target, saved.row, saved.col, viewerType)
        elseif saved.type == "free" then
            return Integration.AssignAsFreeIcon(id, frame, saved.x, saved.y, saved.iconSize, viewerType)
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- NO SAVED POSITION: Spawn as free icon in horizontal line
    -- Count existing Arc Aura free icons to calculate offset
    -- ═══════════════════════════════════════════════════════════════════════════
    local SPACING = 50  -- Horizontal spacing between icons
    local START_X = -50   -- Slightly left of center
    local START_Y = 150   -- Above center
    
    -- Count existing Arc Aura free icons
    local arcAuraCount = 0
    if ns.CDMGroups.freeIcons then
        for freeID, _ in pairs(ns.CDMGroups.freeIcons) do
            -- Check if it's an Arc Aura ID (starts with "arc_")
            if type(freeID) == "string" and freeID:find("^arc_") then
                arcAuraCount = arcAuraCount + 1
            end
        end
    end
    
    -- Also count Arc Aura frames that might not be in freeIcons yet
    if ns.ArcAuras and ns.ArcAuras.frames then
        for frameID, _ in pairs(ns.ArcAuras.frames) do
            if frameID ~= id then  -- Don't count the one we're adding
                -- Check if it's already a free icon (don't double count)
                local isAlreadyCounted = ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[frameID]
                if not isAlreadyCounted then
                    arcAuraCount = arcAuraCount + 1
                end
            end
        end
    end
    
    local offsetX = START_X + (arcAuraCount * SPACING)
    local offsetY = START_Y
    
    return Integration.AssignAsFreeIcon(id, frame, offsetX, offsetY, 36, viewerType)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ASSIGN TO GROUP
-- Places frame in a specific group at specific position
-- Now delegates to FrameController when available
-- ═══════════════════════════════════════════════════════════════════════════

function Integration.AssignToGroup(id, frame, groupName, row, col, viewerType)
    -- Try FrameController first
    local Controller = ns.FrameController
    if Controller and Controller.AssignFrameToGroup then
        return Controller.AssignFrameToGroup(id, frame, groupName, row, col, viewerType, "ArcAurasViewer")
    end
    
    -- Fallback: Direct group assignment
    local group = ns.CDMGroups.groups[groupName]
    if not group then
        return Integration.AssignToDefaultGroup(id, frame, viewerType, "Essential")
    end
    
    row = row or 0
    col = col or 0
    
    -- Use group's AddMemberAtWithFrame if available
    if group.AddMemberAtWithFrame then
        group:AddMemberAtWithFrame(id, row, col, frame, nil)
        frame:Show()
        Integration.SavePosition(id, "group", groupName, row, col, nil, nil, nil, viewerType)
        return true
    end
    
    -- Fallback: Use AddMemberAt then attach frame
    if group.AddMemberAt then
        group:AddMemberAt(id, row, col)
        local member = group.members and group.members[id]
        if member then
            member.frame = frame
            member.viewerType = viewerType
            member.originalViewerName = "ArcAurasViewer"
            member.isExternal = true
            
            if group.Layout then
                group:Layout()
            end
            if group.SetupMemberDrag then
                group:SetupMemberDrag(id)
            end
            
            Integration.SavePosition(id, "group", groupName, row, col, nil, nil, nil, viewerType)
            return true
        end
    end
    
    return Integration.AssignAsFreeIcon(id, frame, 0, 0, 36, viewerType)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ASSIGN TO DEFAULT GROUP
-- Finds next free slot in default group and adds frame there
-- ═══════════════════════════════════════════════════════════════════════════

function Integration.AssignToDefaultGroup(id, frame, viewerType, defaultGroup)
    local group = ns.CDMGroups.groups[defaultGroup]
    
    -- If default group doesn't exist, try to find another
    if not group then
        local fallbacks = { "Essential", "Utility", "Buffs" }
        for _, name in ipairs(fallbacks) do
            if ns.CDMGroups.groups[name] then
                group = ns.CDMGroups.groups[name]
                break
            end
        end
    end
    
    if not group then
        return Integration.AssignAsFreeIcon(id, frame, 0, 0, 36, viewerType)
    end
    
    -- Find next free slot
    local row, col = 0, 0
    if group.FindNextFreeSlot then
        local r, c = group:FindNextFreeSlot()
        if r then
            row, col = r, c
        end
    end
    
    return Integration.AssignToGroup(id, frame, group.name, row, col, viewerType)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ASSIGN AS FREE ICON
-- Makes frame a free-floating icon that can be dragged anywhere
-- Now delegates to FrameController when available
-- ═══════════════════════════════════════════════════════════════════════════

function Integration.AssignAsFreeIcon(id, frame, x, y, iconSize, viewerType)
    x = x or 0
    y = y or 0
    iconSize = iconSize or 36
    
    -- Try FrameController first
    local Controller = ns.FrameController
    if Controller and Controller.AssignFrameToFree then
        return Controller.AssignFrameToFree(id, frame, x, y, iconSize, viewerType, "ArcAurasViewer")
    end
    
    -- Fallback: Use CDMGroups.TrackFreeIcon which does proper setup
    if ns.CDMGroups.TrackFreeIcon then
        ns.CDMGroups.TrackFreeIcon(id, x, y, iconSize)
        return true
    end
    
    -- Last resort: Manual setup
    ns.CDMGroups.freeIcons = ns.CDMGroups.freeIcons or {}
    ns.CDMGroups.freeIcons[id] = {
        frame = frame,
        x = x,
        y = y,
        iconSize = iconSize,
        viewerType = viewerType,
        originalViewerName = "ArcAurasViewer",
        isExternal = true,
    }
    
    frame:SetParent(UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetScale(1)
    frame:SetSize(iconSize, iconSize)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    frame:SetAlpha(1)
    frame:Show()
    
    frame._cdmgIsFreeIcon = true
    frame._cdmgFreeTargetSize = iconSize
    
    if ns.CDMGroups.SetupFreeIconDrag then
        ns.CDMGroups.SetupFreeIconDrag(id)
    end
    
    Integration.SavePosition(id, "free", nil, nil, nil, x, y, iconSize, viewerType)
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SAVE POSITION
-- Saves position to savedPositions and spec data
-- ═══════════════════════════════════════════════════════════════════════════

function Integration.SavePosition(id, posType, groupName, row, col, x, y, iconSize, viewerType)
    ns.CDMGroups.savedPositions = ns.CDMGroups.savedPositions or {}
    
    local positionData
    if posType == "group" then
        positionData = {
            type = "group",
            target = groupName,
            row = row,
            col = col,
            viewerType = viewerType or "cooldown",
        }
    else
        positionData = {
            type = "free",
            x = x or 0,
            y = y or 0,
            iconSize = iconSize or 36,
            viewerType = viewerType or "cooldown",
        }
    end
    
    ns.CDMGroups.savedPositions[id] = positionData
    
    -- Save to spec data if function exists
    if ns.CDMGroups.SavePositionToSpec then
        ns.CDMGroups.SavePositionToSpec(id, positionData)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UNREGISTER EXTERNAL FRAME
-- Removes frame from CDMGroups management
-- ═══════════════════════════════════════════════════════════════════════════

function Integration.UnregisterExternalFrame(id)
    if not id then return false end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 1: Remove from groups (with clearSaved=true to also clear savedPositions)
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.CDMGroups.groups then
        for groupName, group in pairs(ns.CDMGroups.groups) do
            if group.members and group.members[id] then
                -- Use RemoveMember with clearSaved=true to fully clean up
                if group.RemoveMember then
                    group:RemoveMember(id, true)  -- clearSaved=true removes from savedPositions
                else
                    -- Manual cleanup if RemoveMember not available
                    local member = group.members[id]
                    if member then
                        -- Clear from grid
                        if member.row ~= nil and member.col ~= nil and group.grid and group.grid[member.row] then
                            group.grid[member.row][member.col] = nil
                        end
                    end
                    group.members[id] = nil
                end
                break
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 2: Remove from free icons
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[id] then
        ns.CDMGroups.freeIcons[id] = nil
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 3: Clear saved positions (ensures no resurrection on reload)
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.CDMGroups.savedPositions then
        ns.CDMGroups.savedPositions[id] = nil
    end
    
    -- Also clear from spec-specific storage
    if ns.CDMGroups.ClearPositionFromSpec then
        ns.CDMGroups.ClearPositionFromSpec(id)
    elseif ns.CDMGroups.specSavedPositions then
        -- Manual clear from all specs
        for specKey, specData in pairs(ns.CDMGroups.specSavedPositions) do
            if specData[id] then
                specData[id] = nil
            end
        end
    end
    
    -- Clear from spec free icons
    if ns.CDMGroups.specFreeIcons then
        for specKey, specData in pairs(ns.CDMGroups.specFreeIcons) do
            if specData[id] then
                specData[id] = nil
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 4: Clear from FrameController if available
    -- ═══════════════════════════════════════════════════════════════════════════
    local Controller = ns.FrameController
    if Controller then
        -- Clear from owned frames
        if Controller.ownedFrames then
            Controller.ownedFrames[id] = nil
        end
        -- Clear from pending assignments
        if Controller.pendingAssignments then
            Controller.pendingAssignments[id] = nil
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 5: Clear from FrameRegistry if available
    -- ═══════════════════════════════════════════════════════════════════════════
    local Registry = ns.FrameRegistry
    if Registry and Registry.byCooldownID then
        Registry.byCooldownID[id] = nil
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

-- Main API function
ns.CDMGroups.RegisterExternalFrame = Integration.RegisterExternalFrame
ns.CDMGroups.UnregisterExternalFrame = Integration.UnregisterExternalFrame

-- Debug command
SLASH_ARCINTEGRATION1 = "/arcint"
SlashCmdList["ARCINTEGRATION"] = function(msg)
    print("|cff00FFFF[Integration]|r Debug info:")
    print("  FrameController available:", ns.FrameController ~= nil)
    print("  CDMGroups.groups exists:", ns.CDMGroups.groups ~= nil)
    if ns.CDMGroups.groups then
        local count = 0
        for name in pairs(ns.CDMGroups.groups) do
            count = count + 1
            print("    Group:", name)
        end
        print("  Total groups:", count)
    end
    print("  savedPositions exists:", ns.CDMGroups.savedPositions ~= nil)
    if ns.ArcAuras and ns.ArcAuras.frames then
        print("  ArcAuras frames:")
        for id, frame in pairs(ns.ArcAuras.frames) do
            print("    ", id, "visible:", frame:IsShown(), "parent:", frame:GetParent() and frame:GetParent():GetName() or "nil")
        end
    end
end