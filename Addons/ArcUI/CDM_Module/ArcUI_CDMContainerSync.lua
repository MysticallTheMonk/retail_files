-- ArcUI_CDMContainerSync.lua
-- v5.7.0 - Simple global drag detection for Edit Mode overlay sync
--
-- LOGIC:
--   1. Edit Mode opens → Push our positions to viewers (after settle)
--   2. In Edit Mode + mouse down + GROUP CONTAINER position changed → Push to viewer (overlay drag)
--   3. In Edit Mode + mouse down + VIEWER position changed → Pull to group (Edit Mode drag)
--   4. Size always enforced

local ADDON_NAME, ns = ...

ns.CDMContainerSync = ns.CDMContainerSync or {}

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════
local DEBUG = false

local GROUP_TO_VIEWER = {
    ["Buffs"] = "BuffIconCooldownViewer",
    ["Essential"] = "EssentialCooldownViewer",
    ["Utility"] = "UtilityCooldownViewer",
}

local VIEWER_TO_GROUP = {
    ["BuffIconCooldownViewer"] = "Buffs",
    ["EssentialCooldownViewer"] = "Essential",
    ["UtilityCooldownViewer"] = "Utility",
}

-- ═══════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════
local enabled = {}               -- [groupName] = true/false
local hooksInstalled = {}        -- [key] = true
local sizeOverride = {}          -- [viewerName] = {w, h}
local positionOverride = {}      -- [viewerName] = {x, y} - what we last pushed
local pushing = false            -- True while we're setting things
local editModeSettling = false   -- True during Edit Mode transition
local libEMO = nil               -- LibEditModeOverride reference

-- ═══════════════════════════════════════════════════════════════════
-- DEBUG
-- ═══════════════════════════════════════════════════════════════════
local function DebugPrint(...)
    if DEBUG then
        print("|cff00ff00[CDMSync]|r", ...)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════
local function IsInEditMode()
    -- Check Blizzard's Edit Mode OR ArcUI's drag mode
    local blizzardEditMode = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
    local arcuiDragMode = ns.CDMGroups and ns.CDMGroups.dragModeEnabled
    return blizzardEditMode or arcuiDragMode
end

local function GetLibEMO()
    if libEMO then return libEMO end
    if LibStub then
        local success, lib = pcall(function() return LibStub("LibEditModeOverride-1.0") end)
        if success and lib then
            libEMO = lib
            return libEMO
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- PUSH: ArcUI Group → CDM Viewer (position + size)
-- skipLayoutSave: true during active drag for performance
-- ═══════════════════════════════════════════════════════════════════
local function PushToViewer(groupName, skipLayoutSave)
    if not enabled[groupName] then return end
    
    local viewerName = GROUP_TO_VIEWER[groupName]
    if not viewerName then return end
    
    local viewer = _G[viewerName]
    local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    
    if not viewer or not group or not group.container then return end
    
    local posX = group.position and group.position.x or 0
    local posY = group.position and group.position.y or 0
    local w, h = group.container:GetSize()
    
    if not w or w < 1 then return end
    
    DebugPrint("PUSH:", groupName, "pos:", math.floor(posX), math.floor(posY), "size:", math.floor(w), "x", math.floor(h), skipLayoutSave and "(no save)" or "")
    
    pushing = true
    
    -- Store what we're pushing (to detect user changes later)
    positionOverride[viewerName] = { x = posX, y = posY }
    sizeOverride[viewerName] = { w = w, h = h }
    
    -- Try to save to Edit Mode's layout via LibEditModeOverride (skip during active drag)
    if not skipLayoutSave then
        local lib = GetLibEMO()
        if lib and lib:IsReady() then
            pcall(function()
                lib:LoadLayouts()
                if lib:CanEditActiveLayout() then
                    lib:ReanchorFrame(viewer, "CENTER", UIParent, "CENTER", posX, posY)
                    lib:SaveOnly()
                    DebugPrint("Saved to Edit Mode layout")
                end
            end)
        end
    end
    
    -- ALWAYS move the frame visually
    viewer:ClearAllPoints()
    viewer:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    viewer:SetSize(w, h)
    
    pushing = false
end

-- ═══════════════════════════════════════════════════════════════════
-- PULL: CDM Viewer → ArcUI Group (position only)
-- ═══════════════════════════════════════════════════════════════════
local function PullFromViewer(viewerName)
    local groupName = VIEWER_TO_GROUP[viewerName]
    if not groupName or not enabled[groupName] then return end
    
    local viewer = _G[viewerName]
    local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    
    if not viewer or not group or not group.container then return end
    
    local vx, vy = viewer:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not vx or not vy or not ux or not uy then return end
    
    local offsetX = vx - ux
    local offsetY = vy - uy
    
    DebugPrint("PULL:", groupName, "pos:", math.floor(offsetX), math.floor(offsetY))
    
    -- Update our stored override to match
    positionOverride[viewerName] = { x = offsetX, y = offsetY }
    
    -- Update group
    group.position = group.position or {}
    group.position.x = offsetX
    group.position.y = offsetY
    
    -- Move container
    pushing = true
    group.container:ClearAllPoints()
    group.container:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    pushing = false
    
    -- Update drag bar
    if group.UpdateDragBarPosition then
        group.UpdateDragBarPosition()
    end
    
    -- Save to database
    if ns.db and ns.db.profile and ns.db.profile.cdmGroups and ns.CDMGroups.currentSpec then
        local specData = ns.db.profile.cdmGroups.specData
        if specData and specData[ns.CDMGroups.currentSpec] then
            local groupDB = specData[ns.CDMGroups.currentSpec].groups
            if groupDB and groupDB[groupName] then
                groupDB[groupName].position = { x = offsetX, y = offsetY }
            end
        end
    end
    
    -- Trigger auto-save to linked template
    if ns.CDMGroups and ns.CDMGroups.TriggerTemplateAutoSave then
        ns.CDMGroups.TriggerTemplateAutoSave()
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- VIEWER HOOKS (detect Edit Mode UI dragging the viewer)
-- ═══════════════════════════════════════════════════════════════════
local function SetupViewerHooks(viewerName)
    if hooksInstalled["v_" .. viewerName] then return end
    
    local viewer = _G[viewerName]
    if not viewer then return end
    
    hooksInstalled["v_" .. viewerName] = true
    DebugPrint("Viewer hooks installed:", viewerName)
    
    -- SetPoint hook - detect position changes from Edit Mode drag
    hooksecurefunc(viewer, "SetPoint", function(self)
        if pushing then return end
        if editModeSettling then return end
        
        -- Only respond in Blizzard Edit Mode (not ArcUI drag mode)
        local inBlizzardEditMode = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
        if not inBlizzardEditMode then return end
        
        -- Get current position
        local vx, vy = self:GetCenter()
        local ux, uy = UIParent:GetCenter()
        if not vx or not vy or not ux or not uy then return end
        
        local currentX = vx - ux
        local currentY = vy - uy
        
        -- Check if position differs from what we pushed
        local ovr = positionOverride[viewerName]
        if ovr then
            local dx = math.abs(currentX - ovr.x)
            local dy = math.abs(currentY - ovr.y)
            
            -- If position changed significantly, Edit Mode moved the viewer
            if dx > 2 or dy > 2 then
                DebugPrint("Edit Mode drag detected:", viewerName, "delta:", math.floor(dx), math.floor(dy))
                PullFromViewer(viewerName)
            end
        end
    end)
    
    -- SetSize hook - enforce our size
    hooksecurefunc(viewer, "SetSize", function(self, newW, newH)
        if pushing then return end
        if editModeSettling then return end
        
        local ovr = sizeOverride[viewerName]
        if ovr and ovr.w and ovr.h then
            if math.abs(newW - ovr.w) > 1 or math.abs(newH - ovr.h) > 1 then
                DebugPrint("Size enforced:", viewerName, ovr.w, "x", ovr.h)
                C_Timer.After(0, function()
                    if not pushing and sizeOverride[viewerName] then
                        pushing = true
                        self:SetSize(ovr.w, ovr.h)
                        pushing = false
                    end
                end)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- GROUP HOOKS (detect overlay drag → push to viewer)
-- ═══════════════════════════════════════════════════════════════════
local function SetupGroupHooks(groupName)
    if hooksInstalled["g_" .. groupName] then return end
    
    local group = ns.CDMGroups and ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    if not group or not group.container then return end
    
    hooksInstalled["g_" .. groupName] = true
    DebugPrint("Group hooks installed:", groupName)
    
    -- SetSize hook - sync size changes to viewer
    hooksecurefunc(group.container, "SetSize", function()
        if enabled[groupName] and not pushing then
            C_Timer.After(0.1, function() PushToViewer(groupName) end)
        end
    end)
    
    -- SetPoint hook - detect overlay drag in Edit Mode (global mouse down detection)
    hooksecurefunc(group.container, "SetPoint", function()
        if not enabled[groupName] then return end
        if pushing then return end
        if editModeSettling then return end
        if not IsInEditMode() then return end
        
        -- Global drag detection: mouse button is down = user is dragging
        if not IsMouseButtonDown("LeftButton") then return end
        
        DebugPrint("Overlay drag detected:", groupName)
        -- Push to viewer with skipLayoutSave=true during drag for performance
        PushToViewer(groupName, true)
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- EDIT MODE HOOKS
-- ═══════════════════════════════════════════════════════════════════
if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
        DebugPrint("Edit Mode ENTER")
        editModeSettling = true
        pushing = true
        
        -- Wait for Edit Mode to fully settle
        C_Timer.After(0.8, function()
            pushing = false
            DebugPrint("Pushing positions...")
            
            for groupName, isEnabled in pairs(enabled) do
                if isEnabled then
                    PushToViewer(groupName)
                end
            end
            
            C_Timer.After(0.2, function()
                editModeSettling = false
                DebugPrint("Ready for user drags")
            end)
        end)
    end)
    
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        DebugPrint("Edit Mode EXIT")
        editModeSettling = true
        pushing = true
        
        C_Timer.After(0.3, function()
            pushing = false
            for groupName, isEnabled in pairs(enabled) do
                if isEnabled then
                    PushToViewer(groupName)
                end
            end
            editModeSettling = false
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════════
function ns.CDMContainerSync.SetEnabled(groupName, isEnabled)
    DebugPrint("SetEnabled:", groupName, isEnabled)
    enabled[groupName] = isEnabled
    
    if isEnabled then
        local viewerName = GROUP_TO_VIEWER[groupName]
        if viewerName then
            SetupViewerHooks(viewerName)
        end
        SetupGroupHooks(groupName)
        PushToViewer(groupName)
    else
        local viewerName = GROUP_TO_VIEWER[groupName]
        if viewerName then
            sizeOverride[viewerName] = nil
            positionOverride[viewerName] = nil
        end
    end
    
    -- Save
    if ns.db and ns.db.profile then
        ns.db.profile.cdmGroups = ns.db.profile.cdmGroups or {}
        ns.db.profile.cdmGroups.containerSync = ns.db.profile.cdmGroups.containerSync or {}
        ns.db.profile.cdmGroups.containerSync[groupName] = isEnabled
    end
end

function ns.CDMContainerSync.IsEnabled(groupName)
    return enabled[groupName] == true
end

function ns.CDMContainerSync.SyncAll()
    for groupName, isEnabled in pairs(enabled) do
        if isEnabled then
            PushToViewer(groupName)
        end
    end
end

function ns.CDMContainerSync.RefreshFromContainers()
    DebugPrint("RefreshFromContainers")
    ns.CDMContainerSync.SyncAll()
    
    if ns.CDMGroups and ns.CDMGroups.groups then
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.UpdateDragBarPosition then
                group.UpdateDragBarPosition()
            end
        end
    end
end

function ns.CDMContainerSync.GetViewerForGroup(groupName)
    return GROUP_TO_VIEWER[groupName]
end

function ns.CDMContainerSync.GetGroupForViewer(viewerName)
    return VIEWER_TO_GROUP[viewerName]
end

-- ═══════════════════════════════════════════════════════════════════
-- SLASH COMMAND
-- ═══════════════════════════════════════════════════════════════════
SLASH_CDMSYNC1 = "/cdmsync"
SlashCmdList["CDMSYNC"] = function(msg)
    if msg == "debug on" then
        DEBUG = true
        print("|cff00ff00[CDMSync]|r Debug ON")
    elseif msg == "debug off" then
        DEBUG = false
        print("|cff00ff00[CDMSync]|r Debug OFF")
    elseif msg == "status" then
        print("|cff00ff00[CDMSync]|r Status:")
        local lib = GetLibEMO()
        print("  LibEditModeOverride:", lib and "LOADED" or "not found")
        if lib and lib:IsReady() then
            pcall(function()
                lib:LoadLayouts()
                print("    Layout:", lib:GetActiveLayout())
                print("    Editable:", lib:CanEditActiveLayout() and "yes" or "no")
            end)
        end
        for groupName, isEnabled in pairs(enabled) do
            local viewerName = GROUP_TO_VIEWER[groupName]
            local posOvr = viewerName and positionOverride[viewerName]
            local sizeOvr = viewerName and sizeOverride[viewerName]
            print("  ", groupName, ":", isEnabled and "ON" or "off")
            if posOvr then print("    pos:", math.floor(posOvr.x), math.floor(posOvr.y)) end
            if sizeOvr then print("    size:", math.floor(sizeOvr.w), "x", math.floor(sizeOvr.h)) end
        end
        local blizzardEM = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
        local arcuiDM = ns.CDMGroups and ns.CDMGroups.dragModeEnabled
        print("  Blizzard Edit Mode:", blizzardEM and "ACTIVE" or "inactive")
        print("  ArcUI Drag Mode:", arcuiDM and "ACTIVE" or "inactive")
        print("  Settling:", editModeSettling and "YES" or "no")
    elseif msg == "sync" then
        ns.CDMContainerSync.SyncAll()
        print("|cff00ff00[CDMSync]|r Synced")
    else
        print("|cff00ff00[CDMSync]|r Commands: debug on/off, status, sync")
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════
function ns.CDMContainerSync.Initialize()
    DebugPrint("Initialize")
    
    if ns.db and ns.db.profile and ns.db.profile.cdmGroups and ns.db.profile.cdmGroups.containerSync then
        for groupName, isEnabled in pairs(ns.db.profile.cdmGroups.containerSync) do
            if isEnabled then
                ns.CDMContainerSync.SetEnabled(groupName, true)
            end
        end
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    C_Timer.After(3, function()
        if ns.CDMGroups and ns.db then
            ns.CDMContainerSync.Initialize()
        end
    end)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)