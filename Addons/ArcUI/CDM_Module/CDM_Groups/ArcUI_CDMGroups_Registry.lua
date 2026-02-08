-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI CDMGroups Registry - Frame Tracking & Lookup System
-- v2.0 - Refactored with unified lookup and extensible frame sources
-- 
-- This file ONLY tracks frames - it does NOT move or reparent them.
-- ═══════════════════════════════════════════════════════════════════════════

local addonName, ns = ...

-- Ensure ns.CDMGroups exists (this file loads before CDMGroups.lua)
ns.CDMGroups = ns.CDMGroups or {}

print("|cff00FF00[ArcUI]|r CDMGroups_Registry.lua loading...")

-- Dependencies
local Shared = ns.CDMShared
if not Shared then
    print("|cffFF0000[ArcUI]|r ERROR: ns.CDMShared not available in Registry!")
end
local CDM_VIEWERS = Shared and Shared.CDM_VIEWERS
if not CDM_VIEWERS then
    print("|cffFF0000[ArcUI]|r ERROR: Shared.CDM_VIEWERS not available in Registry!")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- REGISTRY OBJECT
-- ═══════════════════════════════════════════════════════════════════════════

ns.FrameRegistry = {
    byAddress = {},      -- tostring(frame) → entry
    byCooldownID = {},   -- cooldownID → { [frame] = true }
    byViewer = {},       -- viewerName → { [frame] = true }
}

local Registry = ns.FrameRegistry

-- ═══════════════════════════════════════════════════════════════════════════
-- FRAME SOURCES - Extensible list of where to find frames
-- Add new sources here for custom frames in the future
-- Each source has: name, getFrame(cdID) -> frame, entry, viewerType, defaultGroup, viewerName
-- ═══════════════════════════════════════════════════════════════════════════

local FrameSources = {}

-- Source 1: Group members (frames we've reparented into containers)
FrameSources[1] = {
    name = "groups",
    getFrame = function(cdID)
        local groups = ns.CDMGroups.groups
        if not groups then return nil end
        for _, group in pairs(groups) do
            if group.members and group.members[cdID] then
                local member = group.members[cdID]
                if member.frame and member.frame.cooldownID == cdID then
                    return member.frame, member.entry, member.viewerType, member.defaultGroup, member.originalViewerName
                end
            end
        end
        return nil
    end,
}

-- Source 2: Free icons (frames we've reparented to UIParent)
FrameSources[2] = {
    name = "freeIcons",
    getFrame = function(cdID)
        local freeIcons = ns.CDMGroups.freeIcons
        if not freeIcons or not freeIcons[cdID] then return nil end
        local data = freeIcons[cdID]
        if data.frame and data.frame.cooldownID == cdID then
            return data.frame, data.entry, data.viewerType, nil, data.originalViewerName
        end
        return nil
    end,
}

-- Source 3: Registry index (our tracking table)
FrameSources[3] = {
    name = "registryIndex",
    getFrame = function(cdID)
        local lookup = Registry.byCooldownID[cdID]
        if not lookup then return nil end
        for frame in pairs(lookup) do
            if frame and frame.cooldownID == cdID then
                local entry = Registry.byAddress[tostring(frame)]
                if entry then
                    return frame, entry, entry.viewerType, entry.defaultGroup, entry.viewerName
                end
            end
        end
        return nil
    end,
}

-- Source 4: CDM Viewers (scan Blizzard's frames directly)
FrameSources[4] = {
    name = "cdmViewers",
    getFrame = function(cdID)
        for _, viewerInfo in ipairs(CDM_VIEWERS) do
            -- Skip bar viewers - we only manage icon viewers
            if not viewerInfo.skipInGroups then
                local viewer = _G[viewerInfo.name]
                if viewer then
                    local children = { viewer:GetChildren() }
                    for _, child in ipairs(children) do
                        if child.cooldownID == cdID then
                            -- Auto-register when found
                            local entry = Registry:Register(child, viewerInfo.name)
                            return child, entry, viewerInfo.type, viewerInfo.defaultGroup, viewerInfo.name
                        end
                    end
                end
            end
        end
        return nil
    end,
}

-- Source 5: Custom frames (Arc Auras and future custom cooldown frames)
-- These frames use _arcAuraID instead of cooldownID
FrameSources[5] = {
    name = "customFrames",
    getFrame = function(cdID)
        -- Only check string IDs (Arc Auras use string IDs like "arc_trinket_13")
        if type(cdID) ~= "string" then return nil end
        
        -- Check Arc Auras
        if ns.ArcAuras and ns.ArcAuras.frames then
            local frame = ns.ArcAuras.frames[cdID]
            if frame and frame._arcAuraID == cdID then
                -- CRITICAL: Ensure frame is registered in Registry for future lookups
                -- This allows FrameSources[3] (registryIndex) to find it via byCooldownID
                -- The frame has both _arcAuraID and cooldownID set to the same string
                local entry = Registry.byAddress[tostring(frame)]
                if not entry then
                    -- Register it now so it's indexed in byCooldownID
                    entry = Registry:Register(frame, "ArcAurasViewer")
                end
                -- Return with viewerType "cooldown" so it's treated like a cooldown
                return frame, entry, "cooldown", "Essential", "ArcAurasViewer"
            end
        end
        
        -- Future: Add other custom frame sources here
        
        return nil
    end,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- UNIFIED LOOKUP - Single function replaces 3 redundant ones
-- ═══════════════════════════════════════════════════════════════════════════

-- Find frame by cooldownID - searches all sources in order
-- Returns: frame, entry, viewerType, defaultGroup, viewerName (or nil)
function Registry:FindByCooldownID(cooldownID)
    for _, source in ipairs(FrameSources) do
        local frame, entry, viewerType, defaultGroup, viewerName = source.getFrame(cooldownID)
        if frame then
            return frame, entry, viewerType, defaultGroup, viewerName
        end
    end
    return nil
end

-- Check if cooldownID exists in any source
-- Returns: true/false
function Registry:Exists(cooldownID)
    local frame = self:FindByCooldownID(cooldownID)
    return frame ~= nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CORE REGISTRY METHODS
-- ═══════════════════════════════════════════════════════════════════════════

-- Register a frame (or update existing entry)
function Registry:Register(frame, viewerName)
    if not frame then return nil end
    
    local addr = tostring(frame)
    local existing = self.byAddress[addr]
    
    -- CRITICAL FIX: Get viewerType from cooldownID's CDM category (authoritative source)
    -- Fall back to viewerName only if CDM lookup fails
    local viewerType, defaultGroup
    if frame.cooldownID then
        viewerType, defaultGroup = Shared.GetViewerTypeFromCooldownID(frame.cooldownID)
    end
    -- Fallback to viewerName if CDM lookup failed (rare case)
    if not viewerType and viewerName then
        viewerType, defaultGroup = Shared.GetViewerTypeFromName(viewerName)
    end
    
    if existing then
        -- Frame exists - check if cooldownID changed (CDM recycled the frame)
        if existing.cooldownID ~= frame.cooldownID then
            self:_handleFrameRecycled(existing, frame)
            -- CRITICAL: Re-determine viewerType for new cooldownID
            if frame.cooldownID then
                local newVT, newDG = Shared.GetViewerTypeFromCooldownID(frame.cooldownID)
                if newVT then
                    existing.viewerType = newVT
                    existing.defaultGroup = newDG
                end
            end
        end
        existing.cooldownID = frame.cooldownID
        existing.lastSeen = GetTime()
        -- Update viewerType if we have a better value (from CDM lookup)
        if viewerType then
            existing.viewerType = viewerType
            existing.defaultGroup = defaultGroup
        end
    else
        -- New frame
        self.byAddress[addr] = {
            frame = frame,
            address = addr,
            cooldownID = frame.cooldownID,
            viewerName = viewerName,
            viewerType = viewerType,
            defaultGroup = defaultGroup,
            originalParent = frame:GetParent(),
            firstSeen = GetTime(),
            lastSeen = GetTime(),
            manipulated = false,
        }
    end
    
    -- Update secondary indexes
    local cdID = frame.cooldownID
    if cdID then
        self.byCooldownID[cdID] = self.byCooldownID[cdID] or {}
        self.byCooldownID[cdID][frame] = true
    end
    
    if viewerName then
        self.byViewer[viewerName] = self.byViewer[viewerName] or {}
        self.byViewer[viewerName][frame] = true
    end
    
    return self.byAddress[addr]
end

-- Handle frame recycled by CDM (cooldownID changed)
function Registry:_handleFrameRecycled(existing, frame)
    local oldCdID = existing.cooldownID
    
    -- Clean old cooldownID from index
    if oldCdID and self.byCooldownID[oldCdID] then
        self.byCooldownID[oldCdID][frame] = nil
    end
    
    -- Clear stale group membership
    if oldCdID then
        for _, group in pairs(ns.CDMGroups.groups or {}) do
            if group.members and group.members[oldCdID] then
                local member = group.members[oldCdID]
                if member.frame == frame then
                    if member.row and member.col and group.grid and group.grid[member.row] then
                        group.grid[member.row][member.col] = nil
                    end
                    group.members[oldCdID] = nil
                end
            end
        end
        
        -- Clear stale free icon
        if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[oldCdID] then
            local freeData = ns.CDMGroups.freeIcons[oldCdID]
            if freeData.frame == frame then
                ns.CDMGroups.freeIcons[oldCdID] = nil
            end
        end
    end
end

-- Get entry for a frame
function Registry:GetEntry(frame)
    return self.byAddress[tostring(frame)]
end

-- Get entry or create it (replaces 11 instances of GetEntry or Register pattern)
function Registry:GetOrCreate(frame, viewerName)
    return self.byAddress[tostring(frame)] or self:Register(frame, viewerName)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LEGACY COMPATIBILITY - Wrappers for old function names
-- ═══════════════════════════════════════════════════════════════════════════

-- Legacy: GetValidFrameForCooldownID -> now calls FindByCooldownID
function Registry:GetValidFrameForCooldownID(cooldownID)
    local frame, entry = self:FindByCooldownID(cooldownID)
    return frame, entry
end

-- Legacy: IsCooldownIDValidForCurrentSpec -> now calls Exists
function Registry:IsCooldownIDValidForCurrentSpec(cooldownID)
    return self:Exists(cooldownID)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SPELL INFO LOOKUP
-- ═══════════════════════════════════════════════════════════════════════════

function Registry:GetSpellInfoForCooldownID(cooldownID)
    -- Handle Arc Aura string IDs - get actual item info
    if Shared.IsArcAuraID and Shared.IsArcAuraID(cooldownID) then
        local arcType, id = Shared.ParseArcAuraID(cooldownID)
        
        if arcType == "trinket" and id then
            -- Get equipped trinket info
            local itemID = GetInventoryItemID("player", id)
            if itemID then
                local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
                return {
                    cooldownID = cooldownID,
                    spellID = nil,
                    name = name or ("Trinket Slot " .. id),
                    icon = icon or GetInventoryItemTexture("player", id) or 134400,
                    isArcAura = true,
                    arcType = arcType,
                    slotID = id,
                    itemID = itemID,
                }
            else
                return {
                    cooldownID = cooldownID,
                    spellID = nil,
                    name = "Trinket Slot " .. id .. " (Empty)",
                    icon = 134400,
                    isArcAura = true,
                    arcType = arcType,
                    slotID = id,
                }
            end
        elseif arcType == "item" and id then
            -- Get specific item info
            local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(id)
            return {
                cooldownID = cooldownID,
                spellID = nil,
                name = name or ("Item " .. id),
                icon = icon or 134400,
                isArcAura = true,
                arcType = arcType,
                itemID = id,
            }
        elseif arcType == "spell" and id then
            -- Get spell info
            local name = Shared.SafeGetSpellName(id)
            local icon = Shared.SafeGetSpellTexture(id)
            return {
                cooldownID = cooldownID,
                spellID = id,
                name = name or ("Spell " .. id),
                icon = icon or 134400,
                isArcAura = true,
                arcType = arcType,
            }
        end
        
        -- Unknown arc type
        return {
            cooldownID = cooldownID,
            spellID = nil,
            name = "Arc Aura",
            icon = 134400,
            isArcAura = true,
        }
    end
    
    -- Use safe wrapper for CDM cooldowns (handles numeric IDs only)
    local info = Shared.SafeGetCDMInfo and Shared.SafeGetCDMInfo(cooldownID)
    
    if info then
        return {
            cooldownID = cooldownID,
            spellID = info.spellID,
            overrideSpellID = info.overrideSpellID,
            name = info.name or Shared.SafeGetSpellName(info.spellID) or Shared.SafeGetSpellName(info.overrideSpellID) or "Unknown",
            icon = info.iconID or Shared.SafeGetSpellTexture(info.spellID) or Shared.SafeGetSpellTexture(info.overrideSpellID),
        }
    end
    
    return {
        cooldownID = cooldownID,
        spellID = nil,
        name = "Unknown (cdID=" .. tostring(cooldownID) .. ")",
        icon = nil,
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

function Registry:CleanupCooldownIDMappings()
    local cleaned = 0
    for cdID, frames in pairs(self.byCooldownID) do
        local toRemove = {}
        for frame in pairs(frames) do
            if not frame or frame.cooldownID ~= cdID then
                toRemove[#toRemove + 1] = frame
            end
        end
        for _, frame in ipairs(toRemove) do
            frames[frame] = nil
            cleaned = cleaned + 1
        end
        if not next(frames) then
            self.byCooldownID[cdID] = nil
        end
    end
    return cleaned
end

function Registry:CleanupStaleEntries()
    local staleCount = 0
    local staleAddrs = {}
    
    for addr, entry in pairs(self.byAddress) do
        local frame = entry.frame
        local isValid = false
        if frame then
            local ok, result = pcall(function() return frame:IsObjectType("Frame") end)
            isValid = ok and result
        end
        
        if not isValid then
            staleAddrs[#staleAddrs + 1] = addr
            staleCount = staleCount + 1
        end
    end
    
    for _, addr in ipairs(staleAddrs) do
        local entry = self.byAddress[addr]
        if entry then
            if entry.cooldownID and self.byCooldownID[entry.cooldownID] then
                self.byCooldownID[entry.cooldownID][entry.frame] = nil
            end
            if entry.viewerName and self.byViewer[entry.viewerName] then
                self.byViewer[entry.viewerName][entry.frame] = nil
            end
        end
        self.byAddress[addr] = nil
    end
    
    return staleCount
end

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEWER TYPE LOOKUP
-- ═══════════════════════════════════════════════════════════════════════════

local function GetViewerTypeForCooldownID(cooldownID)
    local _, _, viewerType, defaultGroup, viewerName = Registry:FindByCooldownID(cooldownID)
    
    if viewerType then
        return viewerType, defaultGroup, viewerName
    end
    
    -- Last resort: Use safe wrapper (handles Arc Aura string IDs)
    local vt, dg = Shared.GetViewerTypeFromCooldownID and Shared.GetViewerTypeFromCooldownID(cooldownID)
    if vt then
        local vn
        if vt == "aura" then
            vn = "BuffIconCooldownViewer"
        elseif vt == "utility" then
            vn = "UtilityCooldownViewer"
        elseif vt == "custom" then
            vn = "ArcAurasViewer"
        else
            vn = "EssentialCooldownViewer"
        end
        return vt, dg, vn
    end
    
    return nil, nil, nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SCANNING FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

local function IsCDMGroupsEnabled()
    return ns.CDMGroups and ns.CDMGroups.IsCDMGroupsEnabled and ns.CDMGroups.IsCDMGroupsEnabled()
end

function ns.CDMGroups.ScanAllViewers()
    local totalFound = 0
    local newFound = 0
    
    Registry:CleanupStaleEntries()
    Registry:CleanupCooldownIDMappings()
    
    for _, viewerInfo in ipairs(CDM_VIEWERS) do
        if not viewerInfo.skipInGroups then
            local viewer = _G[viewerInfo.name]
            if viewer then
                local children = { viewer:GetChildren() }
                for _, child in ipairs(children) do
                    if child.cooldownID then
                        local isNew = not Registry.byAddress[tostring(child)]
                        Registry:Register(child, viewerInfo.name)
                        totalFound = totalFound + 1
                        if isNew then 
                            newFound = newFound + 1
                        end
                        
                        -- CRITICAL: Force scale to 1 on ALL CDM frames
                        -- CDM Edit Mode can set different scales per viewer type
                        -- Normalizing to 1 ensures our SetSize controls actual size
                        local currentScale = child:GetScale()
                        if currentScale and math.abs(currentScale - 1) > 0.01 then
                            child:SetScale(1)
                        end
                    end
                end
            end
        end
    end
    
    ns.CDMGroups.cooldownCatalog = ns.CDMGroups.BuildCooldownCatalog()
    return totalFound
end

function ns.CDMGroups.BuildCooldownCatalog()
    local catalog = {}
    
    local function addToCatalog(cdID, frame, viewerName, viewerType, trackingType, trackingTarget)
        if not catalog[cdID] then
            local spellInfo = Registry:GetSpellInfoForCooldownID(cdID)
            catalog[cdID] = {
                cooldownID = cdID,
                spellID = spellInfo.spellID,
                name = spellInfo.name,
                icon = spellInfo.icon,
                viewerName = viewerName,
                viewerType = viewerType,
                frame = frame,
                trackingType = trackingType,
                trackingTarget = trackingTarget,
            }
        elseif trackingType and trackingType ~= "none" then
            catalog[cdID].trackingType = trackingType
            catalog[cdID].trackingTarget = trackingTarget
            catalog[cdID].frame = frame
        end
    end
    
    for _, viewerInfo in ipairs(CDM_VIEWERS) do
        if not viewerInfo.skipInGroups then
            local viewer = _G[viewerInfo.name]
            if viewer then
                local children = { viewer:GetChildren() }
                for _, child in ipairs(children) do
                    if child.cooldownID then
                        addToCatalog(child.cooldownID, child, viewerInfo.name, viewerInfo.type, "none", nil)
                    end
                end
            end
        end
    end
    
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        if group.members then
            for cdID, member in pairs(group.members) do
                if member.frame then
                    if catalog[cdID] then
                        catalog[cdID].trackingType = "group"
                        catalog[cdID].trackingTarget = groupName
                        if member.frame.cooldownID == cdID then
                            catalog[cdID].frame = member.frame
                        end
                    else
                        addToCatalog(cdID, member.frame, "VirtualGroup", "group", "group", groupName)
                    end
                end
            end
        end
    end
    
    for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
        if data.frame then
            if catalog[cdID] then
                catalog[cdID].trackingType = "free"
                catalog[cdID].trackingTarget = nil
            else
                addToCatalog(cdID, data.frame, "FreeIcon", "free", "free", nil)
            end
        end
    end
    
    return catalog
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

local function IsViewerTypeEnabled(viewerType)
    return IsCDMGroupsEnabled()
end

local function GetViewerTypeFromName(viewerName)
    return Shared.GetViewerTypeFromName(viewerName)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

ns.CDMGroups.GetViewerTypeForCooldownID = GetViewerTypeForCooldownID
ns.CDMGroups.GetViewerTypeFromName = GetViewerTypeFromName
ns.CDMGroups.IsViewerTypeEnabled = IsViewerTypeEnabled
ns.CDMGroups.IsCooldownIDValid = function(cooldownID)
    return Registry:Exists(cooldownID)
end

-- Export FrameSources for extensibility
ns.FrameRegistry.Sources = FrameSources