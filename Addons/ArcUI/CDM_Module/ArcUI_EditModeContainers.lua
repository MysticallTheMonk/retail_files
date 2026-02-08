-- ArcUI_EditModeContainers.lua
-- v1.0.0 - LibEQOL-based Edit Mode integration
--
-- Creates wrapper containers registered with LibEQOL for Edit Mode.
-- Bidirectional sync between wrappers and ArcUI group containers.
-- No CDM viewer interaction = no combat taint ever.
--
-- ARCHITECTURE:
--   ArcUI Wrapper Container (LibEQOL/Edit Mode visible)
--            ↕ bidirectional sync ↕
--   ArcUI Group Container (holds icons)
--
-- Moving either frame moves the other. LibEQOL handles:
--   - Edit Mode selection boxes
--   - Per-layout position saving
--   - Magnetism/snapping to other frames
--   - Settings panel integration

local ADDON_NAME, ns = ...

ns.EditModeContainers = ns.EditModeContainers or {}

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════
local DEBUG = false  -- Set to true for troubleshooting

-- No hardcoded groups - all groups get wrappers dynamically
-- Frame naming: "ArcUI_[GroupName]Container" (no spaces for frame name)
-- Display naming: "ArcUI [GroupName]" (spaces for Edit Mode label)

-- ═══════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════
local wrappers = {}              -- [groupName] = wrapper frame
local enabled = {}               -- [groupName] = true/false (wrapper exists)
local overlaysEnabled = false    -- Master toggle for showing overlays (separate from Edit Mode)
local pushing = false            -- True while syncing to prevent loops
local libEQOL = nil              -- LibEQOL reference (cached)
local blizzEditModeActive = false -- Cached Blizzard Edit Mode state (updated by callbacks only)
local initialized = false

-- Blizzard CDM viewer size override for Edit Mode (makes selection easier)
local cdmViewerOriginalSizes = {}  -- [viewerName] = {width, height} stored when Edit Mode opens

-- Forward declarations for functions used before they're defined
local ShowSingleWrapper, HideSingleWrapper, HideSingleWrapperForce, SyncGroupToWrapper

-- ═══════════════════════════════════════════════════════════════════
-- DYNAMIC NAMING HELPERS
-- ═══════════════════════════════════════════════════════════════════
-- Generate global frame name (no spaces, valid Lua identifier)
local function GetWrapperFrameName(groupName)
    -- Remove spaces and special chars for valid frame name
    local safeName = groupName:gsub("[^%w]", "")
    return "ArcUI_" .. safeName .. "Container"
end

-- Generate display name for Edit Mode (human readable)
local function GetWrapperDisplayName(groupName)
    return "ArcUI " .. groupName
end

-- ═══════════════════════════════════════════════════════════════════
-- DEBUG
-- ═══════════════════════════════════════════════════════════════════
local function DebugPrint(...)
    if DEBUG then
        print("|cff00ccff[EditMode]|r", ...)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- LIBEQOL ACCESS
-- ═══════════════════════════════════════════════════════════════════
local function GetLibEQOL()
    if libEQOL then return libEQOL end
    if LibStub then
        -- Try the EditMode module specifically
        local success, lib = pcall(function() 
            return LibStub("LibEQOLEditMode-1.0") 
        end)
        if success and lib then
            libEQOL = lib
            return libEQOL
        end
        -- Fallback to umbrella
        success, lib = pcall(function()
            local umbrella = LibStub("LibEQOL-1.0")
            return umbrella and umbrella.EditMode
        end)
        if success and lib then
            libEQOL = lib
            return libEQOL
        end
    end
    return nil
end

-- Use cached state instead of querying LibEQOL every time (performance optimization)
local function IsBlizzEditModeActive()
    return blizzEditModeActive
end

-- Called by LibEQOL callbacks to update cached state
local function SetBlizzEditModeActive(active)
    blizzEditModeActive = active
end

-- ═══════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════
local function IsInEditMode()
    local blizzardEditMode = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
    local arcuiDragMode = ns.CDMGroups and ns.CDMGroups.dragModeEnabled
    return blizzardEditMode or arcuiDragMode
end

local function GetGroupContainer(groupName)
    local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    return group and group.container
end

local function GetGroupPosition(groupName)
    local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    if group and group.position then
        return group.position.x or 0, group.position.y or 0
    end
    return 0, 0  -- Default center position
end

local function GetGroupSize(groupName)
    local container = GetGroupContainer(groupName)
    if container then
        local w, h = container:GetSize()
        if w and w > 1 and h and h > 1 then
            return w, h
        end
    end
    return 100, 40  -- Default size
end

-- ═══════════════════════════════════════════════════════════════════
-- SYNC: Wrapper → Group (user dragged wrapper in Edit Mode)
-- ═══════════════════════════════════════════════════════════════════
local function SyncWrapperToGroup(groupName)
    if pushing then return end
    if not enabled[groupName] then return end
    
    local wrapper = wrappers[groupName]
    local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    
    if not wrapper or not group or not group.container then 
        return 
    end
    
    -- Get wrapper center position relative to UIParent center
    local wx, wy = wrapper:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not wx or not wy or not ux or not uy then 
        return 
    end
    
    local offsetX = wx - ux
    local offsetY = wy - uy
    
    -- Check if position actually changed
    local oldX = group.position and group.position.x or 0
    local oldY = group.position and group.position.y or 0
    if math.abs(offsetX - oldX) < 1 and math.abs(offsetY - oldY) < 1 then
        return  -- No meaningful change
    end
    
    pushing = true
    
    -- Update group position (same pattern as drag bar in CDMGroups)
    group.position = group.position or {}
    group.position.x = offsetX
    group.position.y = offsetY
    
    -- Move group container
    group.container:ClearAllPoints()
    group.container:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    
    pushing = false
    
    -- Update drag bar if exists
    if group.UpdateDragBarPosition then
        group.UpdateDragBarPosition()
    end
    
    -- Save to database using same pattern as CDMGroups drag bar
    -- Use group.getDB() if available (same path as drag bar uses)
    if group.getDB then
        local db = group.getDB()
        if db then
            db.position = group.position  -- Assign reference like drag bar does
        end
    else
        -- Fallback: direct path to specData
        if ns.db and ns.db.profile and ns.db.profile.cdmGroups and ns.CDMGroups.currentSpec then
            local specData = ns.db.profile.cdmGroups.specData
            if specData and specData[ns.CDMGroups.currentSpec] then
                local groupDB = specData[ns.CDMGroups.currentSpec].groups
                if groupDB then
                    -- Ensure group entry exists
                    if not groupDB[groupName] then
                        groupDB[groupName] = { enabled = true }
                    end
                    groupDB[groupName].position = group.position  -- Assign reference
                end
            end
        end
    end
    
    -- Trigger auto-save to linked template
    if ns.CDMGroups and ns.CDMGroups.TriggerTemplateAutoSave then
        ns.CDMGroups.TriggerTemplateAutoSave()
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- SYNC: Group → Wrapper (user dragged group via drag bar)
-- ═══════════════════════════════════════════════════════════════════
SyncGroupToWrapper = function(groupName)
    if pushing then return end
    if not enabled[groupName] then return end
    
    local wrapper = wrappers[groupName]
    local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    
    if not wrapper or not group then
        return
    end
    
    local posX, posY = GetGroupPosition(groupName)
    local w, h = GetGroupSize(groupName)
    
    pushing = true
    
    -- Move and size wrapper to match group
    wrapper:ClearAllPoints()
    wrapper:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    wrapper:SetSize(w, h)
    
    pushing = false
end

-- ═══════════════════════════════════════════════════════════════════
-- SINGLE WRAPPER SHOW/HIDE (for hover behavior)
-- Must be defined before CreateWrapper since CreateWrapper uses them
-- ═══════════════════════════════════════════════════════════════════
ShowSingleWrapper = function(groupName)
    local wrapper = wrappers[groupName]
    if not wrapper then return end
    
    -- Sync position/size from group
    SyncGroupToWrapper(groupName)
    
    -- Check if Blizzard Edit Mode is active - if so, don't enable mouse (LibEQOL handles it)
    if IsBlizzEditModeActive() then
        wrapper:EnableMouse(false)
    else
        wrapper:EnableMouse(true)
    end
    wrapper:Show()
end

HideSingleWrapper = function(groupName)
    local wrapper = wrappers[groupName]
    if not wrapper then return end
    
    -- Don't hide if Drag Groups toggle is on
    if overlaysEnabled then return end
    
    -- Don't hide if Blizzard Edit Mode is on (LibEQOL needs wrappers)
    if IsBlizzEditModeActive() then return end
    
    wrapper:Hide()
    wrapper:EnableMouse(false)
    wrapper._isDragging = false
    wrapper:SetScript("OnUpdate", nil)
end

-- Force hide - bypasses checks EXCEPT Blizzard Edit Mode (used by drag toggle button)
HideSingleWrapperForce = function(groupName)
    local wrapper = wrappers[groupName]
    if not wrapper then return end
    
    -- Don't hide if Blizzard Edit Mode is on - LibEQOL needs the wrapper visible
    if IsBlizzEditModeActive() then
        -- Just disable our mouse handler, don't hide
        wrapper:EnableMouse(false)
        return
    end
    
    wrapper:Hide()
    wrapper:EnableMouse(false)
    wrapper._isDragging = false
    wrapper:SetScript("OnUpdate", nil)
end

-- ═══════════════════════════════════════════════════════════════════
-- WRAPPER CREATION
-- ═══════════════════════════════════════════════════════════════════
local function CreateWrapper(groupName)
    if not groupName or groupName == "" then 
        return nil 
    end
    
    -- Check if already exists
    if wrappers[groupName] then
        return wrappers[groupName]
    end
    
    local frameName = GetWrapperFrameName(groupName)
    local displayName = GetWrapperDisplayName(groupName)
    
    -- Get initial position from group if it exists
    local posX, posY = GetGroupPosition(groupName)
    local w, h = GetGroupSize(groupName)
    
    -- Create the wrapper frame as a drag overlay
    local wrapper = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    wrapper:SetSize(w, h)
    wrapper:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    wrapper:SetFrameStrata("HIGH")  -- Above the group container
    wrapper:SetFrameLevel(200)
    wrapper:SetClampedToScreen(true)
    
    -- Visual overlay (semi-transparent when shown)
    wrapper:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    wrapper:SetBackdropColor(0.1, 0.4, 0.8, 0.35)  -- More visible blue tint
    wrapper:SetBackdropBorderColor(0.3, 0.7, 1.0, 0.9)  -- Blue border
    
    -- "DRAG" text on overlay
    local dragText = wrapper:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dragText:SetPoint("CENTER", wrapper, "CENTER", 0, 0)
    dragText:SetText("DRAG")
    dragText:SetTextColor(1, 1, 1, 0.9)
    wrapper._dragText = dragText
    
    -- Mouse setup - start DISABLED since wrapper starts hidden
    -- EnableMouse(true) is called by ShowAllWrappers when drag mode is enabled
    wrapper:EnableMouse(false)
    wrapper:SetMovable(true)
    wrapper:RegisterForDrag("LeftButton")
    
    -- Drag state
    wrapper._isDragging = false
    
    -- Start drag: move the GROUP CONTAINER, wrapper follows
    wrapper:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        
        -- Allow dragging when:
        -- 1. Drag Groups toggle is ON (overlaysEnabled)
        -- 2. Edit Mode toggle is ON (ns.CDMGroups.dragModeEnabled)
        local editModeOn = ns.CDMGroups and ns.CDMGroups.dragModeEnabled
        if not overlaysEnabled and not editModeOn then return end
        
        local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
        if not group or not group.container then return end
        
        -- Select this group (if CDMGroups supports it)
        if ns.CDMGroups.selectedGroup ~= nil then
            ns.CDMGroups.selectedGroup = groupName
            if ns.CDMGroups.UpdateGroupSelectionVisuals then
                ns.CDMGroups.UpdateGroupSelectionVisuals()
            end
        end
        
        -- Ensure container is movable and start moving
        group.container:SetMovable(true)
        group.container:StartMoving()
        self._isDragging = true
        
        -- OnUpdate: sync wrapper to follow container during drag
        self:SetScript("OnUpdate", function()
            if not self._isDragging then return end
            
            local container = group.container
            if not container then return end
            
            -- Get container position and sync wrapper to it
            local cx, cy = container:GetCenter()
            local ux, uy = UIParent:GetCenter()
            if cx and cy and ux and uy then
                local offsetX = cx - ux
                local offsetY = cy - uy
                
                -- Update wrapper to match container
                pushing = true
                self:ClearAllPoints()
                self:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
                pushing = false
            end
            
            -- Update wrapper size to match container
            local cw, ch = container:GetSize()
            if cw and ch and cw > 1 and ch > 1 then
                self:SetSize(cw, ch)
            end
        end)
    end)
    
    -- Stop drag: save position
    wrapper:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" or not self._isDragging then return end
        
        local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
        if not group or not group.container then return end
        
        -- Stop moving
        group.container:StopMovingOrSizing()
        self._isDragging = false
        self:SetScript("OnUpdate", nil)
        
        -- Get final position from container
        local x, y = group.container:GetCenter()
        local ux, uy = UIParent:GetCenter()
        if not x or not y or not ux or not uy then return end
        
        local offsetX = x - ux
        local offsetY = y - uy
        
        -- Update group position
        group.position = group.position or {}
        group.position.x = offsetX
        group.position.y = offsetY
        
        -- Re-anchor container cleanly
        group.container:ClearAllPoints()
        group.container:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
        
        -- Final wrapper sync
        pushing = true
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
        pushing = false
        
        -- Update drag bar position if it exists (for compatibility)
        if group.UpdateDragBarPosition then
            group.UpdateDragBarPosition()
        end
        
        -- Save to DB
        if group.getDB then
            local db = group.getDB()
            if db then
                db.position = group.position
            end
        end
        
        -- Trigger auto-save
        if ns.CDMGroups and ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
    end)
    
    -- Also handle drag stop (backup)
    wrapper:SetScript("OnDragStop", function(self)
        if self._isDragging then
            local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
            if group and group.container then
                group.container:StopMovingOrSizing()
            end
            -- Trigger OnMouseUp logic
            self:GetScript("OnMouseUp")(self, "LeftButton")
        end
    end)
    
    -- Hover effects
    wrapper:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.5, 0.9, 0.5)  -- Brighter on hover
        self:SetBackdropBorderColor(0.5, 0.9, 1.0, 1.0)
        if self._dragText then
            self._dragText:SetTextColor(1, 1, 1, 1)
        end
    end)
    
    wrapper:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.4, 0.8, 0.35)
        self:SetBackdropBorderColor(0.3, 0.7, 1.0, 0.9)
        if self._dragText then
            self._dragText:SetTextColor(1, 1, 1, 0.9)
        end
    end)
    
    -- Start hidden - shown when Edit Mode is active
    wrapper:Hide()
    
    -- Store reference and metadata
    wrapper.groupName = groupName
    wrapper.editModeName = displayName
    wrappers[groupName] = wrapper
    
    -- Make globally accessible
    _G[frameName] = wrapper
    
    return wrapper
end

local function RegisterWrapperWithLibEQOL(groupName)
    local lib = GetLibEQOL()
    if not lib then
        return false
    end
    
    local wrapper = wrappers[groupName]
    if not wrapper then 
        return false 
    end
    
    -- Ensure display name is set
    wrapper.editModeName = GetWrapperDisplayName(groupName)
    
    -- Get current position for default
    local posX, posY = GetGroupPosition(groupName)
    
    -- Register with LibEQOL
    -- Callback signature: function(frame, layoutName, point, x, y)
    -- This fires when user drags in Edit Mode or layout changes
    lib:AddFrame(wrapper, function(frame, layoutName, point, x, y)
        -- Apply the position LibEQOL gives us
        if point and x and y then
            pushing = true
            frame:ClearAllPoints()
            frame:SetPoint(point, UIParent, point, x, y)
            pushing = false
        end
        
        -- Sync wrapper position to group
        C_Timer.After(0, function()
            SyncWrapperToGroup(groupName)
        end)
    end, {
        -- Default position (LibEQOL format)
        point = "CENTER",
        x = posX,
        y = posY,
        -- Options
        enableOverlayToggle = true,
        dragEnabled = true,
    })
    
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- GROUP HOOKS (detect group container changes)
-- ═══════════════════════════════════════════════════════════════════
local groupHooksInstalled = {}

local function SetupGroupHooks(groupName)
    if groupHooksInstalled[groupName] then return end
    
    local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    if not group or not group.container then return end
    
    groupHooksInstalled[groupName] = true
    
    -- SetSize hook - sync size to wrapper
    hooksecurefunc(group.container, "SetSize", function()
        if enabled[groupName] and not pushing then
            C_Timer.After(0.05, function()
                SyncGroupToWrapper(groupName)
            end)
        end
    end)
    
    -- SetPoint hook - detect drag bar movement
    hooksecurefunc(group.container, "SetPoint", function()
        if not enabled[groupName] then return end
        if pushing then return end
        if not IsInEditMode() then return end
        
        -- Only sync if mouse is down (user dragging)
        if IsMouseButtonDown("LeftButton") then
            C_Timer.After(0.05, function()
                SyncGroupToWrapper(groupName)
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- WRAPPER HOOKS (detect Edit Mode dragging)
-- ═══════════════════════════════════════════════════════════════════
local wrapperHooksInstalled = {}

local function SetupWrapperHooks(groupName)
    if wrapperHooksInstalled[groupName] then return end
    
    local wrapper = wrappers[groupName]
    if not wrapper then return end
    
    wrapperHooksInstalled[groupName] = true
    
    -- SetPoint hook - detect Edit Mode movement
    hooksecurefunc(wrapper, "SetPoint", function()
        if not enabled[groupName] then return end
        if pushing then return end
        
        -- Sync to group
        C_Timer.After(0.05, function()
            SyncWrapperToGroup(groupName)
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- EDIT MODE HOOKS
-- ═══════════════════════════════════════════════════════════════════
local function ShowAllWrappers()
    -- Use cached Blizzard Edit Mode state (no function call overhead)
    local blizzEditModeOn = IsBlizzEditModeActive()
    
    for groupName, isGroupEnabled in pairs(enabled) do
        if isGroupEnabled then
            local wrapper = wrappers[groupName]
            if wrapper then
                -- Sync position/size from group before showing
                SyncGroupToWrapper(groupName)
                -- If Blizzard Edit Mode is active, don't enable mouse (LibEQOL handles it)
                if blizzEditModeOn then
                    wrapper:EnableMouse(false)
                else
                    wrapper:EnableMouse(true)
                end
                wrapper:Show()
            end
        end
    end
end

local function HideAllWrappers()
    for groupName, wrapper in pairs(wrappers) do
        if wrapper then
            wrapper:Hide()
            wrapper:EnableMouse(false)  -- Disable mouse so clicks go through
            wrapper._isDragging = false
            wrapper:SetScript("OnUpdate", nil)
        end
    end
    
    -- Reset all drag toggle buttons in CDMGroups containers
    if ns.CDMGroups and ns.CDMGroups.groups then
        for groupName, group in pairs(ns.CDMGroups.groups) do
            if group.container and group.container.dragToggleBtn then
                group.container.dragToggleBtn._active = false
                if group.container.dragToggleBtn.UpdateVisuals then
                    group.container.dragToggleBtn:UpdateVisuals()
                end
            end
        end
    end
end

local function OnEditModeEnter()
    -- Update cached state immediately (performance optimization)
    SetBlizzEditModeActive(true)
    
    -- Resize Blizzard CDM viewers to 200x50 for easier selection (out of combat only)
    if not InCombatLockdown() then
        local viewers = {
            "EssentialCooldownViewer",
            "UtilityCooldownViewer",
            "BuffIconCooldownViewer",
        }
        for _, viewerName in ipairs(viewers) do
            local viewer = _G[viewerName]
            if viewer then
                local w, h = viewer:GetSize()
                if w and h and (w < 200 or h < 50) then
                    cdmViewerOriginalSizes[viewerName] = {width = w, height = h}
                    viewer:SetSize(200, 50)
                end
            end
        end
    end
    
    -- Blizzard Edit Mode enter - show wrappers but DON'T enable mouse
    -- LibEQOL's selection overlay (child of wrapper) will handle all interactions
    C_Timer.After(0.1, function()
        for groupName, isGroupEnabled in pairs(enabled) do
            if isGroupEnabled then
                local wrapper = wrappers[groupName]
                if wrapper then
                    SyncGroupToWrapper(groupName)
                    -- DON'T enable mouse - let LibEQOL selection handle clicks
                    wrapper:EnableMouse(false)
                    wrapper:Show()
                end
            end
        end
    end)
end

local function OnEditModeExit()
    -- Update cached state immediately (performance optimization)
    SetBlizzEditModeActive(false)
    
    -- Restore all Blizzard CDM viewers to original sizes (out of combat only)
    if not InCombatLockdown() then
        for viewerName, originalSize in pairs(cdmViewerOriginalSizes) do
            local viewer = _G[viewerName]
            if viewer and originalSize then
                viewer:SetSize(originalSize.width, originalSize.height)
            end
        end
        wipe(cdmViewerOriginalSizes)
    end
    
    -- Blizzard Edit Mode exit - sync positions
    C_Timer.After(0.2, function()
        -- Sync positions for any visible wrappers
        for groupName, isGroupEnabled in pairs(enabled) do
            if isGroupEnabled then
                local wrapper = wrappers[groupName]
                if wrapper and wrapper:IsShown() then
                    SyncWrapperToGroup(groupName)
                end
            end
        end
        
        -- Check if Drag Groups toggle is still on
        -- NOTE: ArcUI Edit Mode alone does NOT keep overlays visible
        if overlaysEnabled then
            -- Drag Groups toggle is on - re-enable mouse on wrappers for our drag handling
            for groupName, isGroupEnabled in pairs(enabled) do
                if isGroupEnabled then
                    local wrapper = wrappers[groupName]
                    if wrapper then
                        wrapper:EnableMouse(true)
                    end
                end
            end
        else
            -- Drag Groups toggle is off - hide wrappers
            HideAllWrappers()
        end
        
        -- Trigger template auto-save
        C_Timer.After(0.1, function()
            if ns.CDMGroups and ns.CDMGroups.TriggerTemplateAutoSave then
                ns.CDMGroups.TriggerTemplateAutoSave()
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- OVERLAY TOGGLE (separate from Edit Mode)
-- ═══════════════════════════════════════════════════════════════════
-- SetOverlaysEnabled controls the "Drag Groups" toggle
-- This is SEPARATE from ns.CDMGroups.dragModeEnabled (Edit Mode)
local function SetOverlaysEnabledInternal(isEnabled)
    overlaysEnabled = isEnabled
    
    if isEnabled then
        ShowAllWrappers()
    else
        -- Sync positions before hiding
        for groupName, isGroupEnabled in pairs(enabled) do
            if isGroupEnabled then
                SyncWrapperToGroup(groupName)
            end
        end
        
        -- Check if Blizzard Edit Mode is on - if so, keep wrappers visible but disable our mouse
        if IsBlizzEditModeActive() then
            -- Blizzard Edit Mode is on - keep wrappers visible for LibEQOL but disable mouse
            for groupName, wrapper in pairs(wrappers) do
                if wrapper then
                    wrapper:EnableMouse(false)
                end
            end
        else
            -- No Blizzard Edit Mode - actually hide the wrappers
            HideAllWrappers()
        end
        
        -- Trigger auto-save
        if ns.CDMGroups and ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════════
function ns.EditModeContainers.SetEnabled(groupName, isGroupEnabled)
    enabled[groupName] = isGroupEnabled
    
    if isGroupEnabled then
        -- Create wrapper if needed
        local wrapper = wrappers[groupName]
        if not wrapper then
            wrapper = CreateWrapper(groupName)
            if not wrapper then
                return
            end
        end
        
        -- Register with LibEQOL (optional - for Edit Mode frame selection UI)
        RegisterWrapperWithLibEQOL(groupName)
        
        -- Setup hooks for external position changes
        SetupGroupHooks(groupName)
        SetupWrapperHooks(groupName)
        
        -- Initial sync: group → wrapper
        C_Timer.After(0.1, function()
            SyncGroupToWrapper(groupName)
            
            -- Use cached Blizzard Edit Mode state
            local blizzEditModeOn = IsBlizzEditModeActive()
            
            -- Show wrapper only if Drag Groups toggle is ON or Blizzard Edit Mode is active
            -- ArcUI Edit Mode alone does NOT auto-show overlays
            if overlaysEnabled or blizzEditModeOn then
                -- If Blizzard Edit Mode is active, don't enable mouse (LibEQOL handles it)
                if blizzEditModeOn then
                    wrapper:EnableMouse(false)
                else
                    wrapper:EnableMouse(true)
                end
                wrapper:Show()
            end
        end)
    else
        -- Hide wrapper when disabled
        if wrappers[groupName] then
            wrappers[groupName]:Hide()
            wrappers[groupName]:EnableMouse(false)
        end
    end
end

function ns.EditModeContainers.IsEnabled(groupName)
    return enabled[groupName] == true
end

function ns.EditModeContainers.SyncAll()
    for groupName, isEnabled in pairs(enabled) do
        if isEnabled then
            SyncGroupToWrapper(groupName)
        end
    end
end

function ns.EditModeContainers.RefreshFromContainers()
    ns.EditModeContainers.SyncAll()
end

function ns.EditModeContainers.GetWrapperForGroup(groupName)
    return wrappers[groupName]
end

function ns.EditModeContainers.GetWrapperName(groupName)
    return GetWrapperFrameName(groupName)
end

function ns.EditModeContainers.GetWrapperDisplayName(groupName)
    return GetWrapperDisplayName(groupName)
end

-- Get all currently enabled group names
function ns.EditModeContainers.GetEnabledGroups()
    local groups = {}
    for groupName, isEnabled in pairs(enabled) do
        if isEnabled then
            groups[#groups + 1] = groupName
        end
    end
    return groups
end

-- Enable wrappers for ALL existing groups
function ns.EditModeContainers.EnableAllGroups()
    if not ns.CDMGroups or not ns.CDMGroups.groups then
        return 0
    end
    
    local count = 0
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group and group.container then
            ns.EditModeContainers.SetEnabled(groupName, true)
            count = count + 1
        end
    end
    
    -- Only show wrappers if Drag Groups toggle is ON or Blizzard Edit Mode is active
    -- ArcUI Edit Mode alone does NOT auto-show overlays
    local blizzEditModeOn = IsBlizzEditModeActive()
    
    if overlaysEnabled or blizzEditModeOn then
        C_Timer.After(0.1, function()
            -- If Blizzard Edit Mode is on, show wrappers but don't enable mouse
            if blizzEditModeOn then
                for groupName, isGroupEnabled in pairs(enabled) do
                    if isGroupEnabled then
                        local wrapper = wrappers[groupName]
                        if wrapper then
                            SyncGroupToWrapper(groupName)
                            wrapper:EnableMouse(false)
                            wrapper:Show()
                        end
                    end
                end
            else
                -- Drag Groups toggle is on - show with mouse enabled
                ShowAllWrappers()
            end
        end)
    end
    
    return count
end

-- Show all enabled wrappers (called when entering edit/drag mode)
function ns.EditModeContainers.ShowWrappers()
    ShowAllWrappers()
end

-- Hide all wrappers (called when exiting edit/drag mode)
function ns.EditModeContainers.HideWrappers()
    HideAllWrappers()
end

-- Check if wrappers are currently visible
function ns.EditModeContainers.AreWrappersVisible()
    for groupName, wrapper in pairs(wrappers) do
        if wrapper and wrapper:IsShown() then
            return true
        end
    end
    return false
end

-- Master toggle for overlay visibility ("Drag Groups" toggle in options)
function ns.EditModeContainers.SetOverlaysEnabled(isEnabled)
    SetOverlaysEnabledInternal(isEnabled)
end

function ns.EditModeContainers.IsOverlaysEnabled()
    return overlaysEnabled
end

-- Single wrapper show/hide (for drag toggle button in container)
function ns.EditModeContainers.ShowSingleWrapper(groupName)
    ShowSingleWrapper(groupName)
end

function ns.EditModeContainers.HideSingleWrapperForce(groupName)
    HideSingleWrapperForce(groupName)
end

-- Called directly from CDMGroups.SetDragMode when Edit Mode is enabled
-- NOTE: This does NOT auto-show overlays. Overlays are only shown when:
--   1. Drag Groups toggle is ON
--   2. Blizzard Edit Mode is active
--   3. Individual drag toggle button is clicked
function ns.EditModeContainers.ShowAllWrappersForEditMode()
    -- Only show overlays if Drag Groups toggle is already ON
    -- ArcUI Edit Mode alone does NOT show overlays (user must enable Drag Groups toggle)
    if not overlaysEnabled then return end
    
    -- Use cached Blizzard Edit Mode state
    local blizzEditModeOn = IsBlizzEditModeActive()
    
    for groupName, isGroupEnabled in pairs(enabled) do
        if isGroupEnabled then
            local wrapper = wrappers[groupName]
            if wrapper then
                SyncGroupToWrapper(groupName)
                -- If Blizzard Edit Mode is active, don't enable mouse (LibEQOL handles it)
                if blizzEditModeOn then
                    wrapper:EnableMouse(false)
                else
                    wrapper:EnableMouse(true)
                end
                wrapper:Show()
            end
        end
    end
end

-- Called directly from CDMGroups.SetDragMode when Edit Mode is disabled
function ns.EditModeContainers.HideAllWrappersForEditMode()
    -- Don't hide if Drag Groups toggle is still on
    if overlaysEnabled then return end
    
    -- Don't hide if Blizzard Edit Mode is still on (LibEQOL needs wrappers visible)
    if IsBlizzEditModeActive() then return end
    
    -- Hide all wrappers and reset drag toggle buttons
    HideAllWrappers()
end

-- ═══════════════════════════════════════════════════════════════════
-- BACKWARD COMPATIBILITY - Mirror CDMContainerSync API
-- ═══════════════════════════════════════════════════════════════════
-- This allows existing code that calls ns.CDMContainerSync to work
ns.CDMContainerSync = ns.CDMContainerSync or {}

ns.CDMContainerSync.SetEnabled = function(groupName, isEnabled)
    return ns.EditModeContainers.SetEnabled(groupName, isEnabled)
end

ns.CDMContainerSync.IsEnabled = function(groupName)
    return ns.EditModeContainers.IsEnabled(groupName)
end

ns.CDMContainerSync.SyncAll = function()
    return ns.EditModeContainers.SyncAll()
end

ns.CDMContainerSync.RefreshFromContainers = function()
    return ns.EditModeContainers.RefreshFromContainers()
end

-- These return nil now (no CDM viewer involvement)
ns.CDMContainerSync.GetViewerForGroup = function(groupName)
    return nil
end

ns.CDMContainerSync.GetGroupForViewer = function(viewerName)
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- SLASH COMMAND
-- ═══════════════════════════════════════════════════════════════════
SLASH_EDITMODECONT1 = "/editmodecont"
SLASH_EDITMODECONT2 = "/emc"
SlashCmdList["EDITMODECONT"] = function(msg)
    if msg == "debug on" then
        DEBUG = true
        print("|cff00ccff[EditMode]|r Debug ON")
    elseif msg == "debug off" then
        DEBUG = false
        print("|cff00ccff[EditMode]|r Debug OFF")
    elseif msg == "test" then
        -- Test sync and show what would be saved
        print("|cff00ccff[EditMode]|r Testing sync for all enabled groups:")
        for groupName, isEnabled in pairs(enabled) do
            if isEnabled then
                local wrapper = wrappers[groupName]
                local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
                
                if wrapper and group then
                    local wx, wy = wrapper:GetCenter()
                    local ux, uy = UIParent:GetCenter()
                    local wrapperX = wx and ux and (wx - ux) or 0
                    local wrapperY = wy and uy and (wy - uy) or 0
                    
                    local groupX = group.position and group.position.x or 0
                    local groupY = group.position and group.position.y or 0
                    
                    print("  " .. groupName .. ":")
                    print("    Wrapper pos: " .. math.floor(wrapperX) .. ", " .. math.floor(wrapperY))
                    print("    Group pos:   " .. math.floor(groupX) .. ", " .. math.floor(groupY))
                    
                    if group.getDB then
                        local db = group.getDB()
                        if db and db.position then
                            print("    DB pos:      " .. math.floor(db.position.x or 0) .. ", " .. math.floor(db.position.y or 0))
                        else
                            print("    DB pos:      (no db entry)")
                        end
                    end
                    
                    local delta = math.abs(wrapperX - groupX) + math.abs(wrapperY - groupY)
                    if delta > 2 then
                        print("    |cffff0000MISMATCH!|r Delta: " .. math.floor(delta))
                    else
                        print("    |cff00ff00SYNCED|r")
                    end
                end
            end
        end
    elseif msg == "save" then
        -- Force save all positions
        print("|cff00ccff[EditMode]|r Force saving all positions...")
        for groupName, isEnabled in pairs(enabled) do
            if isEnabled then
                SyncWrapperToGroup(groupName)
            end
        end
        if ns.CDMGroups and ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
        print("|cff00ccff[EditMode]|r Done!")
    elseif msg == "show" then
        -- Enable and show all wrappers
        SetOverlaysEnabledInternal(true)
        print("|cff00ccff[EditMode]|r Drag Groups overlays ENABLED")
    elseif msg == "hide" then
        -- Disable and hide all wrappers
        SetOverlaysEnabledInternal(false)
        print("|cff00ccff[EditMode]|r Drag Groups overlays DISABLED")
    elseif msg == "status" then
        print("|cff00ccff[EditMode]|r Status:")
        print("  Drag Groups (overlays):", overlaysEnabled and "|cff00ff00ENABLED|r" or "|cffff0000disabled|r")
        print("  Edit Mode (icons):", ns.CDMGroups and ns.CDMGroups.dragModeEnabled and "|cff00ff00ENABLED|r" or "|cffff0000disabled|r")
        
        local lib = GetLibEQOL()
        print("  LibEQOL:", lib and "LOADED" or "not found")
        if lib then
            if lib.IsInEditMode then
                print("    In Edit Mode:", lib:IsInEditMode() and "yes" or "no")
            end
            if lib.GetActiveLayoutName then
                print("    Layout:", lib:GetActiveLayoutName() or "unknown")
            end
        end
        
        -- Count available groups
        local availableGroups = {}
        if ns.CDMGroups and ns.CDMGroups.groups then
            for groupName, group in pairs(ns.CDMGroups.groups) do
                if group and group.container then
                    availableGroups[groupName] = true
                end
            end
        end
        
        print("  Available groups:")
        for groupName in pairs(availableGroups) do
            local isEnabled = enabled[groupName]
            local wrapper = wrappers[groupName]
            local group = ns.CDMGroups.groups[groupName]
            print("    ", groupName, ":", isEnabled and "ON" or "off")
            if wrapper then
                local w, h = wrapper:GetSize()
                local x, y = 0, 0
                local cx, cy = wrapper:GetCenter()
                local ux, uy = UIParent:GetCenter()
                if cx and cy and ux and uy then
                    x, y = cx - ux, cy - uy
                end
                print("      wrapper:", GetWrapperFrameName(groupName))
                print("      display:", GetWrapperDisplayName(groupName))
                print("      pos:", math.floor(x), ",", math.floor(y), "size:", math.floor(w), "x", math.floor(h), wrapper:IsShown() and "(visible)" or "(hidden)")
            else
                print("      wrapper: NOT CREATED")
            end
            if group and group.container then
                local gx, gy = 0, 0
                local gcx, gcy = group.container:GetCenter()
                local ux, uy = UIParent:GetCenter()
                if gcx and gcy and ux and uy then
                    gx, gy = gcx - ux, gcy - uy
                end
                local gw, gh = group.container:GetSize()
                print("      group pos:", math.floor(gx), ",", math.floor(gy), "size:", math.floor(gw or 0), "x", math.floor(gh or 0))
            end
        end
        
        local blizzardEM = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
        print("  Blizzard Edit Mode:", blizzardEM and "ACTIVE" or "inactive")
    elseif msg == "sync" then
        ns.EditModeContainers.SyncAll()
        print("|cff00ccff[EditMode]|r Synced")
    elseif msg == "enable" then
        -- Enable all groups
        local count = ns.EditModeContainers.EnableAllGroups()
        print("|cff00ccff[EditMode]|r Enabled", count or 0, "groups")
    elseif msg == "disable" then
        -- Disable all groups
        for groupName in pairs(enabled) do
            ns.EditModeContainers.SetEnabled(groupName, false)
        end
        print("|cff00ccff[EditMode]|r Disabled all groups")
    else
        print("|cff00ccff[EditMode]|r Commands:")
        print("  debug on/off - Toggle debug output")
        print("  status - Show toggles, groups, and positions")
        print("  show - Enable Drag Groups (show overlays)")
        print("  hide - Disable Drag Groups (hide overlays)")
        print("  sync - Force sync all (group→wrapper)")
        print("  save - Force save all (wrapper→group+DB)")
        print("  test - Show sync status for all groups")
        print("  enable - Create wrappers for ALL groups")
        print("  disable - Remove all wrappers")
    end
end

-- Also keep old slash command working
SLASH_CDMSYNC1 = "/cdmsync"
SlashCmdList["CDMSYNC"] = SlashCmdList["EDITMODECONT"]

-- ═══════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════
function ns.EditModeContainers.Initialize()
    if initialized then return end
    initialized = true
    
    -- Hook Edit Mode enter/exit (for Blizzard Edit Mode sync)
    if EditModeManagerFrame then
        hooksecurefunc(EditModeManagerFrame, "EnterEditMode", OnEditModeEnter)
        hooksecurefunc(EditModeManagerFrame, "ExitEditMode", OnEditModeExit)
    end
    
    -- Register with LibEQOL's callback system for Edit Mode detection
    -- Valid events: "enter", "exit", "layout", "layoutadded", "layoutdeleted", "layoutrenamed", "spec", "layoutduplicate"
    local lib = GetLibEQOL()
    if lib and lib.RegisterCallback then
        lib:RegisterCallback("enter", function()
            -- Update cached state FIRST (performance optimization)
            SetBlizzEditModeActive(true)
            
            -- Blizzard Edit Mode entered - show wrappers but DON'T enable mouse
            -- LibEQOL's selection overlay handles all interactions in Blizzard Edit Mode
            for groupName, isGroupEnabled in pairs(enabled) do
                if isGroupEnabled then
                    local wrapper = wrappers[groupName]
                    if wrapper then
                        SyncGroupToWrapper(groupName)
                        wrapper:EnableMouse(false)  -- Let LibEQOL selection handle clicks
                        wrapper:Show()
                    end
                end
            end
        end)
        
        lib:RegisterCallback("exit", function()
            -- Update cached state FIRST (performance optimization)
            SetBlizzEditModeActive(false)
            
            -- Blizzard Edit Mode exited - check if Drag Groups toggle is still on
            -- NOTE: ArcUI Edit Mode alone does NOT keep overlays visible
            
            if overlaysEnabled then
                -- Drag Groups toggle is on - re-enable mouse on wrappers
                for groupName, isGroupEnabled in pairs(enabled) do
                    if isGroupEnabled then
                        local wrapper = wrappers[groupName]
                        if wrapper then
                            wrapper:EnableMouse(true)
                        end
                    end
                end
            else
                -- Drag Groups toggle is off - hide wrappers
                HideAllWrappers()
            end
        end)
        
        -- Initialize cached state from LibEQOL's current state
        if lib.isEditing then
            SetBlizzEditModeActive(true)
        end
    end
    
    -- Note: CDMGroups.SetDragMode now calls ns.EditModeContainers.ShowAllWrappersForEditMode()
    -- and ns.EditModeContainers.HideAllWrappersForEditMode() directly, so no hook needed here
    
    -- Check if Blizzard Edit Mode is already on when we initialize
    -- NOTE: ArcUI Edit Mode does NOT auto-show overlays - only Drag Groups toggle does
    C_Timer.After(0.1, function()
        -- Use cached state (already set by callback registration above)
        if IsBlizzEditModeActive() then
            -- Blizzard Edit Mode is on - show wrappers but DON'T enable mouse
            -- LibEQOL selection handles everything
            for groupName, isGroupEnabled in pairs(enabled) do
                if isGroupEnabled then
                    local wrapper = wrappers[groupName]
                    if wrapper then
                        SyncGroupToWrapper(groupName)
                        wrapper:EnableMouse(false)
                        wrapper:Show()
                    end
                end
            end
        end
    end)
    
    -- Auto-enable wrappers for ALL existing groups (creates wrappers, doesn't show them)
    C_Timer.After(0.5, function()
        ns.EditModeContainers.EnableAllGroups()
    end)
    
    -- Hook into CDMGroups.CreateGroup to auto-create wrappers for new groups
    if ns.CDMGroups and ns.CDMGroups.CreateGroup then
        local originalCreateGroup = ns.CDMGroups.CreateGroup
        ns.CDMGroups.CreateGroup = function(groupName, ...)
            local result = originalCreateGroup(groupName, ...)
            
            -- Auto-enable wrapper for newly created group
            if result then
                C_Timer.After(0.2, function()
                    ns.EditModeContainers.SetEnabled(groupName, true)
                end)
            end
            
            return result
        end
    end
end

-- Initialize alias for backward compatibility
ns.CDMContainerSync.Initialize = function()
    return ns.EditModeContainers.Initialize()
end

-- Auto-initialize on load
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    C_Timer.After(3, function()
        if ns.CDMGroups and ns.db then
            ns.EditModeContainers.Initialize()
            
            -- Hook into AceConfigDialog to detect when options panel closes
            local ACD = LibStub("AceConfigDialog-3.0", true)
            if ACD then
                -- Create a frame to check periodically if options panel closed
                local optionsPanelChecker = CreateFrame("Frame")
                local wasOpen = false
                optionsPanelChecker:SetScript("OnUpdate", function(self, elapsed)
                    self.elapsed = (self.elapsed or 0) + elapsed
                    if self.elapsed < 0.2 then return end
                    self.elapsed = 0
                    
                    local isOpen = ACD.OpenFrames and ACD.OpenFrames["ArcUI"]
                    
                    if wasOpen and not isOpen then
                        -- Options panel just closed - disable Drag Groups toggle
                        if overlaysEnabled then
                            ns.EditModeContainers.SetOverlaysEnabled(false)
                        end
                    end
                    
                    wasOpen = isOpen
                end)
            end
        end
    end)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

-- ═══════════════════════════════════════════════════════════════════
-- CALLBACK FOR GROUP DELETION
-- Other modules can call this when a group is deleted
-- ═══════════════════════════════════════════════════════════════════
function ns.EditModeContainers.OnGroupDeleted(groupName)
    -- Disable and clean up wrapper
    enabled[groupName] = false
    
    local wrapper = wrappers[groupName]
    if wrapper then
        wrapper:Hide()
        wrapper:SetParent(nil)
        
        -- Remove from global
        local frameName = GetWrapperFrameName(groupName)
        if _G[frameName] == wrapper then
            _G[frameName] = nil
        end
        
        wrappers[groupName] = nil
    end
end