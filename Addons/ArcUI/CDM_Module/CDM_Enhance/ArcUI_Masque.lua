-- ===================================================================
-- ArcUI_Masque.lua
-- Masque Integration - Register ArcUI groups directly with Masque
-- 
-- This allows users to skin CDM icons without needing MasqueBlizzBars.
-- We register our own groups and add frames as they're enhanced.
-- Supports: CDM viewers, custom groups, and free position icons.
-- ===================================================================

local ADDON_NAME, ns = ...

ns.Masque = ns.Masque or {}

-- ===================================================================
-- MASQUE GROUP REGISTRATION
-- ===================================================================

local ARCUI_GROUP_NAME = "ArcUI"

-- Special group for free positioned icons (not in any CDMGroups group)
local FREE_POSITION_GROUP_KEY = "_FreePosition"
local FREE_POSITION_TITLE = "Free Position"

-- Store registered groups (free position + custom CDMGroups groups)
local registeredGroups = {}
local customGroups = {}  -- [groupName] = Masque group
local Masque = nil
local masqueInitialized = false

-- ===================================================================
-- ALPHA TAINT GUARD - Fix Masque secret value errors
-- Masque's Skin_Icon (Icon.lua:179) compares GetAlpha() == 0 which
-- errors when alpha is a secret value (WoW 12.0+). ArcUI's frame
-- manipulation during combat can taint Icon alpha, and this persists
-- until reload. MasqueBlizzBars doesn't have this issue because it
-- doesn't manipulate alpha on its frames.
--
-- Fix: Wrap GetAlpha on each Icon texture we register with Masque.
-- WoW widgets let user-set keys shadow C API methods, so setting
-- Icon.GetAlpha = wrappedFunc makes ALL callers (including Masque's
-- internal Skin_Icon) get a non-secret value. This is completely
-- transparent and doesn't require hooking Masque's internals at all.
-- ===================================================================

--- Wrap GetAlpha on a frame's Icon texture to defuse secret values.
--- After this, any code calling Icon:GetAlpha() gets a non-secret result.
--- Idempotent - safe to call multiple times on the same icon.
local function WrapIconGetAlpha(frame)
    if not frame or not frame.Icon then return end
    if not issecretvalue then return end  -- Pre-12.0, no taint possible
    if frame.Icon._arcGetAlphaWrapped then return end
    
    local icon = frame.Icon
    -- Store the original C API GetAlpha (from __index metatable)
    local origGetAlpha = icon.GetAlpha
    if not origGetAlpha then return end
    
    -- Shadow the C method with our wrapper on the object itself
    icon.GetAlpha = function(self)
        local alpha = origGetAlpha(self)
        if issecretvalue(alpha) then
            -- Return 1 (non-secret) - the icon is visible, Masque just needs
            -- to know it's not hidden (the == 0 check). The actual alpha
            -- doesn't matter for Masque's skinning logic.
            return 1
        end
        return alpha
    end
    
    icon._arcGetAlphaWrapped = true
end

-- ===================================================================
-- SETTINGS - What Masque controls vs ArcUI
-- Stored in db.masqueSettings
-- ===================================================================

-- Forward declarations for functions defined later
local InitMasque

local DEFAULT_SETTINGS = {
    enabled = false,  -- Masque skinning enabled (default OFF - user must manually enable)
    useMasqueCooldowns = false,  -- Let Masque control cooldown animations (swipe, edge, bling)
}

--- Get settings from DB
local function GetMasqueSettings()
    local Shared = ns.CDMShared
    if not Shared or not Shared.GetCDMGroupsDB then
        return DEFAULT_SETTINGS
    end
    
    local db = Shared.GetCDMGroupsDB()
    if not db then return DEFAULT_SETTINGS end
    
    if not db.masqueSettings then
        db.masqueSettings = {}
    end
    
    return {
        enabled = db.masqueSettings.enabled == true,  -- default false, must explicitly enable
        useMasqueCooldowns = db.masqueSettings.useMasqueCooldowns == true,  -- default false
    }
end

--- Check if Masque skinning is enabled
--- Returns true ONLY if:
--- 1. Masque addon is installed (LibStub available)
--- 2. Our masqueSettings.enabled toggle is ON
function ns.Masque.IsEnabled()
    -- First check if our toggle is enabled
    local settings = GetMasqueSettings()
    if not settings.enabled then
        return false
    end
    
    -- Also verify Masque addon is actually installed
    local MasqueLib = LibStub and LibStub("Masque", true)
    if not MasqueLib then
        return false
    end
    
    return true
end

--- Check if Masque should control cooldown animations (swipe, edge, bling)
--- Returns true ONLY if:
--- 1. Masque skinning is enabled (IsEnabled() = true)
--- 2. useMasqueCooldowns setting is ON
function ns.Masque.ShouldMasqueControlCooldowns()
    -- First check if Masque skinning is enabled at all
    if not ns.Masque.IsEnabled() then
        return false
    end
    
    -- Then check if user wants Masque to handle cooldowns
    local settings = GetMasqueSettings()
    return settings.useMasqueCooldowns == true
end

--- Get a setting value
function ns.Masque.GetSetting(key)
    local settings = GetMasqueSettings()
    return settings[key]
end

--- Set a setting value
function ns.Masque.SetSetting(key, value)
    local Shared = ns.CDMShared
    if not Shared or not Shared.GetCDMGroupsDB then 
        print("|cffFF0000[ArcUI Masque]|r Failed to save setting - database not available")
        return 
    end
    
    local db = Shared.GetCDMGroupsDB()
    if not db then 
        print("|cffFF0000[ArcUI Masque]|r Failed to save setting - database not available")
        return 
    end
    
    if not db.masqueSettings then
        db.masqueSettings = {}
    end
    
    db.masqueSettings[key] = value
    
    -- When toggling enabled or useMasqueCooldowns, invalidate CDMEnhance cache IMMEDIATELY
    -- This ensures any code that runs before RefreshAllStyles gets the correct values
    if key == "enabled" or key == "useMasqueCooldowns" then
        if ns.CDMEnhance and ns.CDMEnhance.InvalidateCache then
            ns.CDMEnhance.InvalidateCache()
        end
    end
    
    -- Re-register all frames with new settings
    -- For 'enabled' toggle: frames are added/removed from Masque
    -- For 'useMasqueCooldowns' toggle: frames need re-registration to include/exclude Cooldown region
    if key == "enabled" or key == "useMasqueCooldowns" then
        -- Force full re-registration by removing all frames first
        if key == "useMasqueCooldowns" then
            ns.Masque.RemoveAllFrames()
        end
        ns.Masque.ReregisterAllFrames()
    end
    
    -- When toggling enabled or useMasqueCooldowns, do extra cleanup and refresh
    if key == "enabled" or key == "useMasqueCooldowns" then
        C_Timer.After(0.05, function()
            -- Refresh all Masque groups
            ns.Masque.RefreshAllGroups()
            
            -- Refresh ArcUI styles to reapply zoom/padding/aspectRatio
            -- This must happen BEFORE CDMGroups layout refresh so GetEffectiveIconSettings
            -- returns the correct values (aspectRatio=1 when Masque enabled)
            if ns.CDMEnhance and ns.CDMEnhance.RefreshAllStyles then
                C_Timer.After(0.05, function()
                    ns.CDMEnhance.RefreshAllStyles()
                    
                    -- Refresh CDMGroups layouts AFTER cache is invalidated
                    -- This ensures frame sizing uses the new aspectRatio value
                    C_Timer.After(0.05, function()
                        if ns.CDMGroups and ns.CDMGroups.RefreshAllGroupLayouts then
                            ns.CDMGroups.RefreshAllGroupLayouts()
                        end
                    end)
                end)
            end
            
            -- Refresh Arc Auras to apply/remove Masque skinning
            if ns.ArcAuras and ns.ArcAuras.RefreshMasqueState then
                C_Timer.After(0.1, function()
                    ns.ArcAuras.RefreshMasqueState()
                end)
            end
        end)
    end
    
    -- Notify UI to refresh
    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
    end
end

--- Re-register all frames with current settings
function ns.Masque.ReregisterAllFrames()
    InitMasque()
    if not Masque then return end
    
    -- Skip if Masque skinning is disabled
    local settings = GetMasqueSettings()
    if not settings.enabled then return end
    
    -- 1. Re-register all CDMGroups group members
    if ns.CDMGroups and ns.CDMGroups.groups then
        for groupName, group in pairs(ns.CDMGroups.groups) do
            if group.members then
                for cdID, member in pairs(group.members) do
                    if member.frame then
                        ns.Masque.RemoveFrame(member.frame)
                        -- Determine viewer type from entry
                        local viewerName = member.entry and member.entry.viewerName or "BuffIconCooldownViewer"
                        ns.Masque.AddFrame(member.frame, viewerName, cdID)
                    end
                end
            end
        end
    end
    
    -- 2. Re-register all free position icons
    if ns.CDMGroups and ns.CDMGroups.freeIcons then
        for cdID, data in pairs(ns.CDMGroups.freeIcons) do
            if data.frame then
                ns.Masque.RemoveFrame(data.frame)
                local viewerName = data.entry and data.entry.viewerName or "BuffIconCooldownViewer"
                ns.Masque.AddFrame(data.frame, viewerName, cdID)
            end
        end
    end
    
    -- 3. Re-register Arc Auras frames
    if ns.ArcAuras and ns.ArcAuras.frames then
        for arcID, frame in pairs(ns.ArcAuras.frames) do
            if frame then
                ns.Masque.RemoveFrame(frame)
                ns.Masque.AddFrame(frame, "ArcAuras", arcID)
            end
        end
    end
    
    -- Force all groups to re-skin after a short delay
    C_Timer.After(0.05, function()
        -- Refresh all groups (pcall for secret value safety)
        for viewerName, group in pairs(registeredGroups) do
            if group and group.ReSkin then
                pcall(function() group:ReSkin() end)
            end
        end
        for groupName, group in pairs(customGroups) do
            if group and group.ReSkin then
                pcall(function() group:ReSkin() end)
            end
        end
        
        -- Re-apply our cooldown positioning after Masque
        C_Timer.After(0.02, function()
            ns.Masque.ReapplyCooldownPositioning()
        end)
    end)
end

-- ===================================================================
-- INITIALIZATION
-- ===================================================================

-- Callback handler when Masque disables/enables our groups from their UI
local function OnMasqueGroupStateChanged(group, option, value)
    if option == "Disabled" then
        local groupName = group.Group or group.ID or "Unknown"
        
        if value then
            -- Group was DISABLED in Masque's settings
            print("|cff00CCFF[ArcUI Masque]|r Group '" .. groupName .. "' disabled in Masque settings")
            
            -- Notify CDMEnhance to refresh styles (will show ArcUI borders instead of Masque)
            if ns.CDMEnhance and ns.CDMEnhance.RefreshAllStyles then
                C_Timer.After(0.1, function()
                    ns.CDMEnhance.RefreshAllStyles()
                end)
            end
            
            -- Refresh Arc Auras if present
            if ns.ArcAuras and ns.ArcAuras.RefreshAllSettings then
                C_Timer.After(0.15, function()
                    ns.ArcAuras.RefreshAllSettings()
                end)
            end
        else
            -- Group was ENABLED in Masque's settings
            print("|cff00CCFF[ArcUI Masque]|r Group '" .. groupName .. "' enabled in Masque settings")
            
            -- Re-register frames and refresh
            if ns.Masque.ReregisterAllFrames then
                C_Timer.After(0.1, function()
                    ns.Masque.ReregisterAllFrames()
                end)
            end
        end
    end
end

InitMasque = function()
    if masqueInitialized then return end
    
    Masque = LibStub and LibStub("Masque", true)
    if not Masque then return end
    
    masqueInitialized = true
    
    -- Register Free Position group (for icons not in any CDMGroups group)
    local freeGroupID = ARCUI_GROUP_NAME .. "_" .. FREE_POSITION_GROUP_KEY
    registeredGroups[FREE_POSITION_GROUP_KEY] = Masque:Group(ARCUI_GROUP_NAME, FREE_POSITION_TITLE, freeGroupID)
    
    -- Register callback for when Masque disables/enables this group from their UI
    if registeredGroups[FREE_POSITION_GROUP_KEY].RegisterCallback then
        registeredGroups[FREE_POSITION_GROUP_KEY]:RegisterCallback(OnMasqueGroupStateChanged, "Disabled")
    end
    
    -- Note: CDMGroups groups (like "Buffs", "Essential", "Utility", "Group1", etc.)
    -- are registered dynamically via RegisterCustomGroup when icons are added
end

--- Dynamically register a custom group with Masque
local function RegisterCustomGroup(groupName)
    if not Masque then return nil end
    if customGroups[groupName] then return customGroups[groupName] end
    
    -- Create a unique group ID
    local groupID = ARCUI_GROUP_NAME .. "_Custom_" .. groupName
    local group = Masque:Group(ARCUI_GROUP_NAME, groupName, groupID)
    customGroups[groupName] = group
    
    -- Register callback for when Masque disables/enables this group from their UI
    if group.RegisterCallback then
        group:RegisterCallback(OnMasqueGroupStateChanged, "Disabled")
    end
    
    return group
end

-- ===================================================================
-- GROUP LOOKUP
-- ===================================================================

--- Find which CDMGroups group a cdID belongs to (returns group name or nil)
local function FindIconGroupName(cdID)
    if not ns.CDMGroups or not ns.CDMGroups.groups then return nil end
    
    for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.members and group.members[cdID] then
            return groupName
        end
    end
    
    return nil
end

--- Check if an icon is free positioned
local function IsIconFreePositioned(cdID)
    return ns.CDMGroups and ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cdID] ~= nil
end

--- Get the appropriate Masque group for a frame
local function GetMasqueGroupForFrame(cdID, viewerName)
    InitMasque()
    if not Masque then return nil, nil end
    
    -- 1. Check if free positioned
    if IsIconFreePositioned(cdID) then
        return registeredGroups[FREE_POSITION_GROUP_KEY], FREE_POSITION_GROUP_KEY
    end
    
    -- 2. Check if in a CDMGroups group (Buffs, Essential, Utility, Group1, etc.)
    local customGroupName = FindIconGroupName(cdID)
    if customGroupName then
        -- Dynamically register the group if needed
        local group = customGroups[customGroupName] or RegisterCustomGroup(customGroupName)
        return group, "Custom_" .. customGroupName
    end
    
    -- 3. Fall back to Free Position group for unassigned icons
    return registeredGroups[FREE_POSITION_GROUP_KEY], FREE_POSITION_GROUP_KEY
end

-- ===================================================================
-- CORE FUNCTIONS
-- ===================================================================

function ns.Masque.IsMasqueActive()
    InitMasque()
    if not Masque then return false end
    
    -- Check if we have the Free Position group registered
    if registeredGroups[FREE_POSITION_GROUP_KEY] then
        return true
    end
    
    -- Check if we have any custom groups
    for _ in pairs(customGroups) do
        return true
    end
    
    return false
end

function ns.Masque.IsMasqueActiveForViewer(viewerName)
    -- Simplified - just check if Masque is available and enabled
    InitMasque()
    return Masque ~= nil and ns.Masque.IsEnabled()
end

function ns.Masque.IsMasqueActiveForType(viewerType)
    -- Simplified - just check if Masque is available and enabled
    -- viewerType is ignored since we use a single enabled toggle
    InitMasque()
    return Masque ~= nil and ns.Masque.IsEnabled()
end

--- Check if Masque should control icon skinning for CDMEnhance
--- Returns true only if:
--- 1. Masque addon is installed
--- 2. Masque skinning is enabled in ArcUI settings
function ns.Masque.ShouldMasqueControlIcon(viewerType)
    -- Check if Masque skinning is enabled
    local settings = GetMasqueSettings()
    if not settings.enabled then
        return false
    end
    
    -- Check if Masque is available
    InitMasque()
    return Masque ~= nil
end

function ns.Masque.IsAnyGroupEnabled()
    InitMasque()
    if not Masque then return false end
    
    -- Check free position group
    local freeGroup = registeredGroups[FREE_POSITION_GROUP_KEY]
    if freeGroup and not (freeGroup.db and freeGroup.db.Disabled) then
        return true
    end
    
    -- Check custom groups (Buffs, Essential, Utility, Group1, etc.)
    for _, group in pairs(customGroups) do
        if group and not (group.db and group.db.Disabled) then
            return true
        end
    end
    
    return false
end

--- Add a frame to the appropriate Masque group
function ns.Masque.AddFrame(frame, viewerName, cdID)
    InitMasque()
    if not Masque then return end
    if not frame then return end
    
    -- Get cdID if not provided
    cdID = cdID or frame.cooldownID or frame._arcCDID
    if not cdID then return end
    
    -- Check if Masque skinning is enabled
    local settings = GetMasqueSettings()
    
    -- If Masque skinning is disabled, remove frame from Masque but DON'T reset texcoords
    -- The correct texcoords (including aspectRatio) are applied by UpdateIconAppearance
    if not settings.enabled then
        if frame._arcMasqueAdded then
            ns.Masque.RemoveFrame(frame)
        end
        -- DO NOT reset icon texcoords here!
        -- UpdateIconAppearance will apply the correct texcoords based on user's aspectRatio setting
        return
    end
    
    -- Find the right group FIRST (before any remove/add decisions)
    local group, groupKey = GetMasqueGroupForFrame(cdID, viewerName)
    if not group then return end
    
    -- CRITICAL: If already registered in the correct group, skip entirely.
    -- Re-registering triggers Masque's SkinButton which resets Icon dimensions
    -- from the skin's intended inset size (e.g. 44.2x44.2) to full frame size (45x45),
    -- causing icon textures to bleed under Masque border artwork.
    if frame._arcMasqueAdded and frame._arcMasqueGroupKey == groupKey then
        return
    end
    
    -- Wrap GetAlpha on Icon to defuse secret values for Masque (idempotent)
    WrapIconGetAlpha(frame)
    
    -- Remove from old group if switching to a different group
    if frame._arcMasqueAdded and frame._arcMasqueGroupKey then
        ns.Masque.RemoveFrame(frame)
    end
    
    -- Build regions table - ONLY include Icon by default
    -- By not including other regions at all, Masque won't try to manage them
    -- Previously we set regions to false which could cause Masque to hide them
    local regions = {}
    
    if frame.Icon then
        regions.Icon = frame.Icon
    end
    
    -- Include Cooldown region ONLY if useMasqueCooldowns is enabled
    -- When enabled, Masque will control the cooldown swipe appearance (texture, color)
    if settings.useMasqueCooldowns and frame.Cooldown then
        regions.Cooldown = frame.Cooldown
    end
    
    -- NOTE: We intentionally do NOT include other regions (like Count) in the table
    -- Setting regions.Count = false was causing Masque to hide application stacks
    -- By omitting them entirely, Masque will leave them alone
    
    -- Only add if we have an Icon region
    if regions.Icon then
        -- Button type - use "Action" for most CDM icons
        local buttonType = "Action"
        
        -- Add to group - wrap in pcall for secret value safety
        local ok, err = pcall(function()
            group:AddButton(frame, regions, buttonType)
        end)
        
        if ok then
            frame._arcMasqueAdded = true
            frame._arcMasqueGroupKey = groupKey
            frame._arcMasqueCdID = cdID
        else
            -- Masque errored (likely secret value comparison in WoW 12.0)
            if ArcUI_DEBUG_MASQUE then
                print("|cffFFAA00[ArcUI Masque]|r AddButton error:", err)
            end
            frame._arcMasqueAdded = nil
            frame._arcMasqueGroupKey = nil
            frame._arcMasqueCdID = nil
        end
    else
        -- No Icon region - mark as not added
        frame._arcMasqueAdded = nil
        frame._arcMasqueGroupKey = nil
        frame._arcMasqueCdID = nil
    end
end

--- Remove a frame from its Masque group
function ns.Masque.RemoveFrame(frame)
    if not Masque then return end
    if not frame or not frame._arcMasqueAdded then return end
    
    local groupKey = frame._arcMasqueGroupKey
    if not groupKey then return end
    
    -- Find the group
    local group = registeredGroups[groupKey] or customGroups[groupKey:gsub("^Custom_", "")]
    
    if group and group.RemoveButton then
        -- Wrap in pcall for safety
        local ok, err = pcall(function()
            group:RemoveButton(frame)
        end)
        if not ok and ArcUI_DEBUG_MASQUE then
            print("|cffFFAA00[ArcUI Masque]|r RemoveButton error:", err)
        end
    end
    
    frame._arcMasqueAdded = nil
    frame._arcMasqueGroupKey = nil
    frame._arcMasqueCdID = nil
end

--- Remove all frames from Masque (used when settings change that require re-registration)
function ns.Masque.RemoveAllFrames()
    InitMasque()
    if not Masque then return end
    
    -- Remove all CDMGroups group members
    if ns.CDMGroups and ns.CDMGroups.groups then
        for groupName, group in pairs(ns.CDMGroups.groups) do
            if group.members then
                for cdID, member in pairs(group.members) do
                    if member.frame and member.frame._arcMasqueAdded then
                        ns.Masque.RemoveFrame(member.frame)
                    end
                end
            end
        end
    end
    
    -- Remove all free position icons
    if ns.CDMGroups and ns.CDMGroups.freeIcons then
        for cdID, data in pairs(ns.CDMGroups.freeIcons) do
            if data.frame and data.frame._arcMasqueAdded then
                ns.Masque.RemoveFrame(data.frame)
            end
        end
    end
    
    -- Remove all Arc Auras frames
    if ns.ArcAuras and ns.ArcAuras.frames then
        for arcID, frame in pairs(ns.ArcAuras.frames) do
            if frame and frame._arcMasqueAdded then
                ns.Masque.RemoveFrame(frame)
            end
        end
    end
end

--- Update a frame's group (when it moves between groups or to/from free position)
function ns.Masque.UpdateFrameGroup(frame, viewerName, cdID)
    ns.Masque.AddFrame(frame, viewerName, cdID)
end

--- Refresh all Masque groups
function ns.Masque.RefreshAllGroups()
    InitMasque()
    if not Masque then return end
    
    -- Refresh built-in groups (pcall for secret value safety)
    for viewerName, group in pairs(registeredGroups) do
        if group and group.ReSkin then
            pcall(function() group:ReSkin() end)
        end
    end
    
    -- Refresh custom groups
    for groupName, group in pairs(customGroups) do
        if group and group.ReSkin then
            pcall(function() group:ReSkin() end)
        end
    end
    
    -- Re-apply our cooldown positioning after Masque
    C_Timer.After(0.02, function()
        ns.Masque.ReapplyCooldownPositioning()
    end)
end

function ns.Masque.ReapplyCooldownPositioning()
    -- Only re-apply if ArcUI controls cooldown (not Masque)
    local settings = GetMasqueSettings()
    if settings.useMasqueCooldowns then
        return  -- Masque controls cooldown, don't override
    end
    
    if not ns.CDMEnhance then return end
    
    local enhancedFrames = ns.CDMEnhance.GetEnhancedFrames and ns.CDMEnhance.GetEnhancedFrames()
    if not enhancedFrames then return end
    
    for cdID, data in pairs(enhancedFrames) do
        local frame = data.frame
        if frame and frame.Cooldown then
            -- If Masque is actively skinning this frame, don't apply inset positioning.
            -- CDMEnhance already set SetAllPoints correctly - don't overwrite with TOPLEFT/BOTTOMRIGHT.
            if frame.Cooldown._arcMasqueActive then
                -- Just ensure it fills the frame (Masque-compatible)
                frame.Cooldown:ClearAllPoints()
                frame.Cooldown:SetAllPoints(frame)
            else
                local padX = frame.Cooldown._arcPaddingX or 0
                local padY = frame.Cooldown._arcPaddingY or 0
                
                frame.Cooldown:ClearAllPoints()
                frame.Cooldown:SetPoint("TOPLEFT", frame, "TOPLEFT", padX, -padY)
                frame.Cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padX, padY)
                
                if frame._arcTexCoords and frame.Cooldown.SetTexCoordRange then
                    local tc = frame._arcTexCoords
                    local lowVec = CreateVector2D(tc.left, tc.top)
                    local highVec = CreateVector2D(tc.right, tc.bottom)
                    frame.Cooldown:SetTexCoordRange(lowVec, highVec)
                end
            end
        end
    end
    
    -- Also handle Arc Auras frames
    if ns.ArcAuras and ns.ArcAuras.frames then
        for arcID, frame in pairs(ns.ArcAuras.frames) do
            if frame and frame.Cooldown then
                -- Same check for Arc Auras
                if frame.Cooldown._arcMasqueActive then
                    frame.Cooldown:ClearAllPoints()
                    frame.Cooldown:SetAllPoints(frame)
                else
                    local padX = frame.Cooldown._arcPaddingX or 0
                    local padY = frame.Cooldown._arcPaddingY or 0
                    
                    frame.Cooldown:ClearAllPoints()
                    frame.Cooldown:SetPoint("TOPLEFT", frame, "TOPLEFT", padX, -padY)
                    frame.Cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padX, padY)
                    
                    if frame._arcTexCoords and frame.Cooldown.SetTexCoordRange then
                        local tc = frame._arcTexCoords
                        local lowVec = CreateVector2D(tc.left, tc.top)
                        local highVec = CreateVector2D(tc.right, tc.bottom)
                        frame.Cooldown:SetTexCoordRange(lowVec, highVec)
                    end
                end
            end
        end
    end
end

local refreshPending = false
function ns.Masque.QueueRefresh()
    if refreshPending then return end
    if not ns.Masque.IsMasqueActive() then return end
    
    refreshPending = true
    C_Timer.After(0.1, function()
        refreshPending = false
        -- Use ReregisterAllFrames instead of RefreshAllGroups
        -- This ensures Masque properly updates borders when frame sizes change
        ns.Masque.ReregisterAllFrames()
    end)
end

-- ===================================================================
-- SLASH COMMAND
-- ===================================================================

SLASH_ARCMASQUE1 = "/arcmasque"
SlashCmdList["ARCMASQUE"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    
    if msg == "refresh" or msg == "reregister" then
        -- Full re-registration - removes and re-adds all frames to Masque
        if ns.Masque.IsMasqueActive() then
            print("|cff00CCFF[ArcUI]|r Re-registering all frames with Masque...")
            ns.Masque.ReregisterAllFrames()
            print("|cff00FF00[ArcUI]|r Masque frames re-registered")
        else
            print("|cffFFAA00[ArcUI]|r Masque not active")
        end
    elseif msg == "reskin" then
        -- Lighter refresh - just calls ReSkin on existing groups
        if ns.Masque.IsMasqueActive() then
            ns.Masque.RefreshAllGroups()
            print("|cff00FF00[ArcUI]|r Masque groups re-skinned")
        else
            print("|cffFFAA00[ArcUI]|r Masque not active")
        end
    elseif msg == "disablembb" or msg == "fixmbb" then
        -- Disable MasqueBlizzBars CDM groups
        ns.Masque.DisableMasqueBlizzBarsCDM()
    elseif msg == "checkmbb" then
        -- Check MasqueBlizzBars status
        local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("MasqueBlizzBars")
        print("|cff00FFFF[ArcUI Masque]|r MasqueBlizzBars Status:")
        print("  Addon loaded:", loaded and "|cffFFAA00Yes|r" or "|cff00FF00No|r")
        if loaded then
            local cdmEnabled = ns.Masque.IsMasqueBlizzBarsCDMEnabled()
            print("  CDM groups enabled:", cdmEnabled and "|cffFF0000Yes (conflict!)|r" or "|cff00FF00No|r")
            if cdmEnabled then
                print("  |cffFFFF00Use /arcmasque disablembb to disable their CDM groups|r")
            end
        end
    elseif msg == "resetwarning" then
        ns.Masque.ResetConflictWarning()
    elseif msg == "status" then
        InitMasque()
        print("|cff00FFFF[ArcUI Masque]|r Status:")
        print("  Masque installed:", Masque and "|cff00FF00Yes|r" or "|cffFF0000No|r")
        
        -- Show enabled setting
        local settings = GetMasqueSettings()
        print("  Masque Skinning:", settings.enabled and "|cff00FF00Enabled|r" or "|cff888888Disabled|r")
        
        if settings.enabled then
            print("  |cff888888(Masque controls icon borders, ArcUI controls swipe & charge text)|r")
        else
            print("  |cff888888(ArcUI controls everything)|r")
        end
        
        -- Check for MasqueBlizzBars conflict
        local mbbLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("MasqueBlizzBars")
        if mbbLoaded then
            local cdmEnabled = ns.Masque.IsMasqueBlizzBarsCDMEnabled()
            if cdmEnabled then
                print("  |cffFF0000WARNING: MasqueBlizzBars CDM groups enabled - potential conflict!|r")
                print("    |cffFFFF00Use /arcmasque disablembb to fix|r")
            else
                print("  MasqueBlizzBars: |cff00FF00CDM groups disabled (no conflict)|r")
            end
        end
        
        -- Count registered frames
        local freeCount = 0
        local groupCount = 0
        if ns.CDMGroups then
            if ns.CDMGroups.freeIcons then
                for _ in pairs(ns.CDMGroups.freeIcons) do freeCount = freeCount + 1 end
            end
            if ns.CDMGroups.groups then
                for _, group in pairs(ns.CDMGroups.groups) do
                    if group.members then
                        for _ in pairs(group.members) do groupCount = groupCount + 1 end
                    end
                end
            end
        end
        print("  Free position icons:", freeCount)
        print("  Group member icons:", groupCount)
        
        -- Free position
        local freeGroup = registeredGroups[FREE_POSITION_GROUP_KEY]
        local freeStatus = freeGroup and (freeGroup.db and freeGroup.db.Disabled and "|cff888888Disabled|r" or "|cff00FF00Active|r") or "|cffFF0000Not registered|r"
        print("  |cff888888Groups:|r")
        print("    " .. FREE_POSITION_TITLE .. ":", freeStatus)
        
        -- Custom groups (Buffs, Essential, Utility, Group1, etc.)
        for groupName, group in pairs(customGroups) do
            local status = group.db and group.db.Disabled and "|cff888888Disabled|r" or "|cff00FF00Active|r"
            print("    " .. groupName .. ":", status)
        end
    else
        print("|cff00FFFF[ArcUI Masque]|r")
        print("  /arcmasque status - Show group status and frame counts")
        print("  /arcmasque refresh - Full re-register all frames with Masque")
        print("  /arcmasque reskin - Lighter refresh (just re-skin existing)")
        print("  /arcmasque checkmbb - Check MasqueBlizzBars conflict status")
        print("  /arcmasque disablembb - Disable MasqueBlizzBars CDM groups")
        print("  /arcmasque resetwarning - Show conflict warning again")
    end
end

-- ===================================================================
-- CALLBACKS FOR CDMGROUPS
-- Called when custom groups are created/deleted
-- ===================================================================

--- Called when a custom group is created in CDMGroups
function ns.Masque.OnGroupCreated(groupName)
    if not groupName then return end
    InitMasque()
    if not Masque then return end
    
    -- Skip built-in groups (they're already registered)
    if groupName == "Essential" or groupName == "Utility" or groupName == "Buffs" then
        return
    end
    
    -- Register the custom group immediately
    if not customGroups[groupName] then
        RegisterCustomGroup(groupName)
    end
end

--- Called when a custom group is deleted in CDMGroups
function ns.Masque.OnGroupDeleted(groupName)
    if not groupName then return end
    if not Masque then return end
    
    -- Skip built-in groups
    if groupName == "Essential" or groupName == "Utility" or groupName == "Buffs" then
        return
    end
    
    local group = customGroups[groupName]
    if group then
        -- Note: Masque doesn't have a way to fully unregister a group,
        -- but we can remove all buttons from it
        if group.Delete then
            group:Delete()
        end
        customGroups[groupName] = nil
    end
end

--- Sync all custom groups from CDMGroups (call on login/spec change)
function ns.Masque.SyncCustomGroups()
    InitMasque()
    if not Masque then return end
    if not ns.CDMGroups or not ns.CDMGroups.groups then return end
    
    -- Built-in group names to skip
    local BUILTIN = { Essential = true, Utility = true, Buffs = true }
    
    -- Register any custom groups that exist in CDMGroups but not in Masque
    for groupName, _ in pairs(ns.CDMGroups.groups) do
        if not BUILTIN[groupName] and not customGroups[groupName] then
            RegisterCustomGroup(groupName)
        end
    end
end

-- ===================================================================
-- INIT
-- ===================================================================

-- Check for conflicting addons that also try to skin CDM icons
local function CheckForConflictingAddons()
    -- Check if MasqueBlizzBars is loaded - it also skins CDM viewers
    local masqueBlizzBarsLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("MasqueBlizzBars")
    
    if masqueBlizzBarsLoaded then
        -- Only warn if ArcUI Masque is enabled
        if ns.Masque.IsEnabled and ns.Masque.IsEnabled() then
            -- Check if we've already warned this session (use db to persist)
            local Shared = ns.CDMShared
            local db = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
            
            -- Only show popup once per profile (user can dismiss and not see again)
            if db and not db._masqueBlizzBarsWarningShown then
                -- Create a static popup for the warning
                StaticPopupDialogs["ARCUI_MASQUE_CONFLICT"] = {
                    text = "|cffFF6600[ArcUI]|r\n\n|cffFFFFFFMasque Blizzard Bars|r addon detected!\n\nThis addon also skins Cooldown Manager icons, which may conflict with ArcUI's Masque integration.\n\n|cffFFFF00Options:|r\n1. Click |cff00FF00'Disable MBB CDM'|r to automatically disable conflicting groups\n2. Or manually disable in Masque settings:\n   • Tracked Buffs\n   • Essential Cooldowns\n   • Utility Cooldowns",
                    button1 = "Disable MBB CDM",
                    button2 = "Don't Show Again",
                    button3 = "Remind Later",
                    OnAccept = function()
                        -- Try to disable MasqueBlizzBars CDM groups
                        ns.Masque.DisableMasqueBlizzBarsCDM()
                        -- Mark as shown
                        local db2 = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
                        if db2 then
                            db2._masqueBlizzBarsWarningShown = true
                        end
                    end,
                    OnCancel = function()
                        -- "Don't Show Again" button
                        local db2 = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
                        if db2 then
                            db2._masqueBlizzBarsWarningShown = true
                        end
                    end,
                    OnAlt = function()
                        -- "Remind Later" - do nothing, will show again next session
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("ARCUI_MASQUE_CONFLICT")
            end
            
            -- Always print to chat (brief reminder)
            print("|cffFF6600[ArcUI]|r Note: |cffFFFFFFMasque Blizzard Bars|r also skins CDM icons - may conflict with ArcUI's Masque integration.")
        end
    end
end

-- Disable MasqueBlizzBars CDM viewer groups
-- This accesses their Masque groups and disables them
function ns.Masque.DisableMasqueBlizzBarsCDM()
    InitMasque()
    if not Masque then
        print("|cffFF0000[ArcUI]|r Masque not available")
        return false
    end
    
    -- MasqueBlizzBars registers groups under "Blizzard Action Bars" parent
    -- Group IDs are: BuffIconCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer
    local groupsToDisable = {
        { id = "BuffIconCooldownViewer", title = "Tracked Buffs" },
        { id = "EssentialCooldownViewer", title = "Essential Cooldowns" },
        { id = "UtilityCooldownViewer", title = "Utility Cooldowns" },
    }
    
    local disabledCount = 0
    for _, groupInfo in ipairs(groupsToDisable) do
        -- Try to get reference to their group
        -- Masque:Group() returns existing group if it exists
        local ok, group = pcall(function()
            return Masque:Group("Blizzard Action Bars", groupInfo.title, groupInfo.id)
        end)
        
        if ok and group then
            -- Check if group has db (Masque stores settings there)
            if group.db then
                -- Disable the group
                group.db.Disabled = true
                disabledCount = disabledCount + 1
                
                -- Reset the group so it stops skinning
                if group.Reset then
                    pcall(function() group:Reset() end)
                end
                
                print("|cff00FF00[ArcUI]|r Disabled MasqueBlizzBars group: " .. groupInfo.title)
            end
        end
    end
    
    if disabledCount > 0 then
        print("|cff00FF00[ArcUI]|r Disabled " .. disabledCount .. " MasqueBlizzBars CDM groups. Reload UI for full effect.")
        -- Offer to reload
        StaticPopupDialogs["ARCUI_MASQUE_RELOAD"] = {
            text = "|cffFF6600[ArcUI]|r\n\nDisabled MasqueBlizzBars CDM groups.\n\nReload UI for changes to take full effect?",
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
        StaticPopup_Show("ARCUI_MASQUE_RELOAD")
        return true
    else
        print("|cffFFAA00[ArcUI]|r Could not find MasqueBlizzBars CDM groups to disable")
        return false
    end
end

-- Check if MasqueBlizzBars CDM groups are enabled (for status reporting)
function ns.Masque.IsMasqueBlizzBarsCDMEnabled()
    InitMasque()
    if not Masque then return false end
    
    local groupsToCheck = {
        { id = "BuffIconCooldownViewer", title = "Tracked Buffs" },
        { id = "EssentialCooldownViewer", title = "Essential Cooldowns" },
        { id = "UtilityCooldownViewer", title = "Utility Cooldowns" },
    }
    
    for _, groupInfo in ipairs(groupsToCheck) do
        local ok, group = pcall(function()
            return Masque:Group("Blizzard Action Bars", groupInfo.title, groupInfo.id)
        end)
        
        if ok and group and group.db and not group.db.Disabled then
            return true  -- At least one is enabled
        end
    end
    
    return false
end

-- Expose conflict check for external use
ns.Masque.CheckForConflictingAddons = CheckForConflictingAddons

-- Reset the warning flag (can be called if user wants to see it again)
ns.Masque.ResetConflictWarning = function()
    local Shared = ns.CDMShared
    local db = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
    if db then
        db._masqueBlizzBarsWarningShown = nil
        print("|cff00CCFF[ArcUI]|r Masque conflict warning will show again on next login.")
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
initFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitMasque()
        
        -- Check for conflicting addons after a short delay
        C_Timer.After(1, function()
            CheckForConflictingAddons()
        end)
        
        -- Sync custom groups from CDMGroups
        C_Timer.After(0.3, function()
            ns.Masque.SyncCustomGroups()
        end)
        
        C_Timer.After(0.5, function()
            if ns.Masque.IsMasqueActive() then
                ns.Masque.RefreshAllGroups()
            end
        end)
        C_Timer.After(1.2, function()
            if ns.Masque.IsMasqueActive() then
                ns.Masque.RefreshAllGroups()
            end
        end)
        C_Timer.After(2.0, function()
            if ns.Masque.IsMasqueActive() then
                ns.Masque.SyncCustomGroups()
                ns.Masque.RefreshAllGroups()
            end
        end)
        
        self:UnregisterEvent("PLAYER_LOGIN")
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        
        -- Re-register and refresh after entering world (loading screens, portals, etc.)
        -- Skip if not masque enabled
        if not ns.Masque.IsEnabled or not ns.Masque.IsEnabled() then return end
        
        -- Delay to let CDM settle frames
        C_Timer.After(0.5, function()
            if ns.Masque.IsMasqueActive() then
                ns.Masque.ReregisterAllFrames()
            end
        end)
        
        -- Second pass for any stragglers
        C_Timer.After(1.5, function()
            if ns.Masque.IsMasqueActive() then
                ns.Masque.RefreshAllGroups()
            end
        end)
        
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- Re-register frames when entering a new zone
        if not ns.Masque.IsEnabled or not ns.Masque.IsEnabled() then return end
        
        -- Delay to let CDM settle
        C_Timer.After(0.3, function()
            if ns.Masque.IsMasqueActive() then
                ns.Masque.ReregisterAllFrames()
            end
        end)
    end
end)