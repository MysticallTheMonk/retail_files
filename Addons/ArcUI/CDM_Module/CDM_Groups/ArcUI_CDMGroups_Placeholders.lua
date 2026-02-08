-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI CDMGroups Placeholders
-- Visual representations of saved positions for inactive cooldownIDs
-- Shows draggable placeholder frames when options panel is open
-- Auto-swaps with real frames when cooldowns become active
-- ═══════════════════════════════════════════════════════════════════════════

local addonName, ns = ...

-- Dependencies
local Shared = ns.CDMShared

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════════════

local isEditingMode = false
local placeholderFramePool = {}
local activePlaceholders = {}  -- cdID -> frame

-- Selection state for badge system
local selectedPlaceholderCdID = nil  -- Currently selected placeholder from badge

-- ═══════════════════════════════════════════════════════════════════════════
-- ARC AURA ID DETECTION
-- Arc Auras uses string IDs like "arc_trinket_13" or "arc_item_12345"
-- Placeholder system should ignore these (they're managed by Arc Auras)
-- ═══════════════════════════════════════════════════════════════════════════

local function IsArcAuraID(cdID)
    if type(cdID) == "string" and cdID:match("^arc_") then
        return true
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COOLDOWN INFO CACHE
-- Uses C_CooldownViewer API directly - NO panel manipulation (taint-free!)
-- Categories: 0=Essential, 1=Utility (Cooldowns), 2=TrackedBuff, 3=TrackedBar (Auras)
-- ═══════════════════════════════════════════════════════════════════════════

local panelScanCache = {
    cooldowns = {},  -- Categories 0+1 combined
    auras = {},      -- Categories 2+3 combined
}
local cacheExpiry = 0
local CACHE_DURATION = 10  -- Cache for 10 seconds

-- Get cooldown info directly from API (no panel needed)
local function GetCooldownInfo(cooldownID)
    if not C_CooldownViewer then return nil end
    if not cooldownID or type(cooldownID) ~= "number" then return nil end
    
    local info = {
        cooldownID = cooldownID,
        name = "Unknown",
        icon = 134400,
        isKnown = false,
        spellID = nil,
    }
    
    -- Get info from CDM API
    local cdInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    if cdInfo then
        info.spellID = cdInfo.overrideSpellID or cdInfo.spellID
        info.isKnown = cdInfo.isKnown or false
        info.hasCharges = cdInfo.hasCharges
        info.linkedSpellIDs = cdInfo.linkedSpellIDs
        info.flags = cdInfo.flags
        
        -- Get spell name and icon
        if info.spellID then
            info.name = C_Spell.GetSpellName(info.spellID) or info.name
            info.icon = C_Spell.GetSpellTexture(info.spellID) or info.icon
        end
    end
    
    return info
end

-- Check if cooldown already has a saved position or is managed
local function IsCooldownAlreadyManaged(cdID)
    -- Skip Arc Aura IDs - they're managed by Arc Auras, not placeholders
    if IsArcAuraID(cdID) then return true end  -- Return true to skip in picker
    
    -- Check saved positions (includes placeholders)
    if ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[cdID] then
        return true
    end
    
    -- Check if in any group
    for _, group in pairs(ns.CDMGroups.groups or {}) do
        if group.members and group.members[cdID] then
            return true
        end
    end
    
    -- Check free icons
    if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cdID] then
        return true
    end
    
    return false
end

-- API-Only scan for picker (NO panel manipulation - taint-free!)
-- Categories: 0+1 = Cooldowns (Spells tab), 2+3 = Auras (Buffs tab)
local function ScanPanelForPicker(callback)
    -- Reset cache
    panelScanCache = {
        cooldowns = {},  -- Categories 0+1 combined
        auras = {},      -- Categories 2+3 combined
    }
    
    -- Track seen IDs to avoid duplicates
    local seenIDs = {}
    
    -- Helper to process a category
    local function ProcessCategory(categoryNum, targetTable, isAura)
        local ALLOW_ALL = true
        local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(categoryNum, ALLOW_ALL)
        
        if not cooldownIDs then return end
        
        for _, cooldownID in ipairs(cooldownIDs) do
            -- Skip duplicates and already managed
            if not seenIDs[cooldownID] and not IsCooldownAlreadyManaged(cooldownID) then
                seenIDs[cooldownID] = true
                
                local info = GetCooldownInfo(cooldownID)
                if info then
                    info.categoryNum = categoryNum
                    info.isAura = isAura
                    info.tab = isAura and "auras" or "cooldowns"
                    table.insert(targetTable, info)
                end
            end
        end
    end
    
    -- Scan all 4 categories via API
    -- Cooldowns (Spells tab): Categories 0 and 1
    ProcessCategory(0, panelScanCache.cooldowns, false)  -- Essential
    ProcessCategory(1, panelScanCache.cooldowns, false)  -- Utility
    
    -- Auras (Buffs tab): Categories 2 and 3
    ProcessCategory(2, panelScanCache.auras, true)       -- TrackedBuff
    ProcessCategory(3, panelScanCache.auras, true)       -- TrackedBar
    
    -- Update cache expiry
    cacheExpiry = GetTime() + CACHE_DURATION
    
    -- Call callback immediately (no async needed since API is synchronous)
    if callback then
        callback(panelScanCache)
    end
    
    return panelScanCache
end

-- Get all possible cooldowns (for backward compatibility)
local function GetAllPossibleCooldowns()
    if GetTime() > cacheExpiry then
        ScanPanelForPicker()
    end
    
    local all = {}
    for _, item in ipairs(panelScanCache.cooldowns) do
        table.insert(all, item)
    end
    for _, item in ipairs(panelScanCache.auras) do
        table.insert(all, item)
    end
    return all
end

-- Legacy scan function (redirects to API scan)
local function ScanCDMSettingsPanel()
    return ScanPanelForPicker()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CONSOLIDATED POSITION HELPERS
-- Single source of truth for items at a slot
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if a cdID has an active real frame from CDM
local function HasRealFrame(cdID)
    -- Skip Arc Aura IDs - they're managed separately
    if IsArcAuraID(cdID) then return false end
    
    -- Check FrameRegistry first (most reliable)
    local Registry = ns.FrameRegistry
    if Registry and Registry.GetValidFrameForCooldownID then
        local frame = Registry:GetValidFrameForCooldownID(cdID)
        if frame then
            return true
        end
    end
    
    -- Check if in a group with a real frame (not placeholder)
    for _, group in pairs(ns.CDMGroups.groups or {}) do
        local member = group.members and group.members[cdID]
        if member and member.frame and not member.isPlaceholder then
            return true
        end
    end
    
    -- Check free icons
    local freeData = ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cdID]
    if freeData and freeData.frame then
        return true
    end
    
    return false
end

-- Get all items (real frames + placeholders) at a group slot
-- Returns table of {cooldownID, name, icon, spellID, isActive, isKnown, isPlaceholder}
local function GetItemsAtSlot(groupName, row, col)
    local items = {}
    local seenCdIDs = {}
    
    -- First check group.members for items at this position
    local group = ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    if group and group.members then
        for cdID, member in pairs(group.members) do
            -- Skip Arc Aura IDs - they're managed separately
            if not IsArcAuraID(cdID) and (member.row or 0) == row and (member.col or 0) == col then
                local info = GetCooldownInfo(cdID)
                table.insert(items, {
                    cooldownID = cdID,
                    name = info and info.name or ("ID: " .. tostring(cdID)),
                    icon = info and info.icon,
                    spellID = info and info.spellID,
                    isActive = not member.isPlaceholder and member.frame ~= nil,
                    isKnown = info and info.isKnown,
                    isPlaceholder = member.isPlaceholder,
                })
                seenCdIDs[cdID] = true
            end
        end
    end
    
    -- Then check savedPositions for items not in members (placeholders that might not be in members yet)
    for cdID, saved in pairs(ns.CDMGroups.savedPositions or {}) do
        -- Skip Arc Aura IDs
        if not IsArcAuraID(cdID) 
           and not seenCdIDs[cdID] 
           and saved.type == "group" 
           and saved.target == groupName
           and (saved.row or 0) == row 
           and (saved.col or 0) == col then
            local info = GetCooldownInfo(cdID)
            table.insert(items, {
                cooldownID = cdID,
                name = info and info.name or ("ID: " .. tostring(cdID)),
                icon = info and info.icon,
                spellID = info and info.spellID,
                isActive = false,
                isKnown = info and info.isKnown,
                isPlaceholder = true,
            })
        end
    end
    
    -- Sort: active frames first, then by name
    table.sort(items, function(a, b)
        if a.isActive ~= b.isActive then
            return a.isActive
        end
        return (a.name or "") < (b.name or "")
    end)
    
    return items
end

-- Get count of items at a slot
local function GetSlotStackCount(groupName, row, col)
    return #GetItemsAtSlot(groupName, row, col)
end

-- Check if there's a real frame (not placeholder) at a position
local function HasRealFrameAtPosition(groupName, row, col)
    local group = ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    if not group or not group.members then return false end
    
    for cdID, member in pairs(group.members) do
        -- Skip Arc Aura IDs
        if not IsArcAuraID(cdID)
           and not member.isPlaceholder 
           and member.frame
           and (member.row or 0) == row 
           and (member.col or 0) == col then
            return true
        end
    end
    return false
end

-- Check if a cooldownID has an active frame currently showing
local function HasActiveFrame(cdID)
    -- Skip Arc Aura IDs - they're managed separately
    if IsArcAuraID(cdID) then return false end
    
    -- Check if there's a real CDM frame for this cooldown
    if ns.CDMGroups.groups then
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.members and group.members[cdID] then
                local member = group.members[cdID]
                if member.frame and not member.isPlaceholder then
                    return true
                end
            end
        end
    end
    
    -- Check free icons
    if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cdID] then
        local entry = ns.CDMGroups.freeIcons[cdID]
        if entry.frame then
            return true
        end
    end
    
    return false
end

-- Check if a saved position should show as placeholder
-- Shows placeholder if: no real frame exists AND (explicitly a placeholder OR just inactive)
local function ShouldShowAsPlaceholder(cdID, saved)
    if not saved then return false end
    
    -- Never show placeholder for Arc Aura IDs - they're managed separately
    if IsArcAuraID(cdID) then return false end
    
    -- Never show placeholder if there's a real frame
    if HasRealFrame(cdID) then
        return false
    end
    
    -- Show placeholder if explicitly marked as placeholder
    if saved.isPlaceholder then
        return true
    end
    
    -- Also show placeholder for saved positions without real frames (inactive icons)
    -- This auto-detects saved positions that don't have active frames
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEHOLDER FRAME POOL - DEFINED EARLY FOR USE BY BADGE SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

-- Forward declarations for functions used in CreatePlaceholderFrame
local ShowSlotSelector, HideSlotSelector
local UpdatePlaceholderPosition, RemovePlaceholder
local RefreshAllPlaceholders, RefreshBadgesForGroup, PushFramesFromSlot

-- Helper to calculate what size a placeholder should be
local function GetEffectivePlaceholderSize(cdID, groupLayout)
    local DEFAULT_SIZE = 36
    
    -- Use same calculation as GetSlotDimensions for consistency
    local slotW, slotH
    if groupLayout then
        local baseScale = 36
        local iconSize = groupLayout.iconSize or 36
        local iconWidth = groupLayout.iconWidth or 36
        local iconHeight = groupLayout.iconHeight or 36
        local scale = iconSize / baseScale
        slotW = iconWidth * scale
        slotH = iconHeight * scale
    else
        slotW = DEFAULT_SIZE
        slotH = DEFAULT_SIZE
    end
    
    local effectiveW, effectiveH = slotW, slotH
    
    -- Check for per-icon size override from CDMEnhance
    if cdID and ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
        local cfg = ns.CDMEnhance.GetEffectiveIconSettings(cdID)
        if cfg and cfg.useGroupScale == false then
            local baseW = cfg.width or slotW
            local baseH = cfg.height or slotH
            local scale = cfg.scale or 1.0
            effectiveW = baseW * scale
            effectiveH = baseH * scale
        end
    end
    
    return effectiveW, effectiveH
end

-- Clear selection state on a placeholder frame
local function ClearPlaceholderSelection(frame)
    if not frame then return end
    if frame._selectionGlow then
        frame._selectionGlow:Hide()
    end
    frame.PlaceholderText:SetText(frame._savedLabelText or "RESERVED")
    frame.PlaceholderText:SetTextColor(frame._savedLabelR or 0.7, frame._savedLabelG or 0.7, frame._savedLabelB or 0.7)
end

-- Clear the global selected placeholder state
local function ClearSelectedPlaceholder()
    if selectedPlaceholderCdID then
        local frame = activePlaceholders[selectedPlaceholderCdID]
        if frame then
            ClearPlaceholderSelection(frame)
        end
        selectedPlaceholderCdID = nil
    end
end

-- Create a placeholder frame
local function CreatePlaceholderFrame()
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(36, 36)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    -- Simple dark background (no border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    
    -- Icon texture - fills the frame
    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:SetAllPoints()
    frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.Icon:SetDesaturated(true)
    frame.Icon:SetAlpha(0.6)
    
    -- "?" overlay for unlearned
    frame.UnlearnedOverlay = frame:CreateTexture(nil, "OVERLAY")
    frame.UnlearnedOverlay:SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
    frame.UnlearnedOverlay:SetSize(16, 16)
    frame.UnlearnedOverlay:SetPoint("CENTER", 0, 0)
    frame.UnlearnedOverlay:SetAlpha(0.8)
    frame.UnlearnedOverlay:Hide()
    
    -- Status text indicator (RESERVED/INACTIVE/SELECTED)
    frame.PlaceholderText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.PlaceholderText:SetPoint("BOTTOM", 0, -10)
    frame.PlaceholderText:SetText("RESERVED")
    frame.PlaceholderText:SetTextColor(0.7, 0.7, 0.7)
    frame.PlaceholderText:SetFont(frame.PlaceholderText:GetFont(), 8, "OUTLINE")
    
    -- Selection glow (created but hidden by default)
    frame._selectionGlow = frame:CreateTexture(nil, "OVERLAY")
    frame._selectionGlow:SetPoint("TOPLEFT", -3, 3)
    frame._selectionGlow:SetPoint("BOTTOMRIGHT", 3, -3)
    frame._selectionGlow:SetColorTexture(0, 1, 0.5, 0.4)
    frame._selectionGlow:Hide()
    
    -- Tooltip with cooldown info
    frame:SetScript("OnEnter", function(self)
        if self._placeholderInfo then
            local cdID = self._placeholderCdID
            local saved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[cdID]
            
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self._placeholderInfo.name or "Unknown", 1, 1, 1)
            
            if saved and saved.isPlaceholder then
                GameTooltip:AddLine("Reserved Slot", 0.8, 0.6, 0.2)
            else
                GameTooltip:AddLine("Inactive - Saved Position", 0.6, 0.6, 0.8)
            end
            
            if self._placeholderInfo.isKnown then
                GameTooltip:AddLine("Spell is learned - waiting for CDM", 0, 1, 0)
            else
                GameTooltip:AddLine("Spell not currently learned", 1, 0.5, 0)
            end
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff666666CooldownID: " .. (cdID or "?") .. "|r")
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff888888Drag to reposition|r")
            GameTooltip:AddLine("|cff888888Right-click to remove|r")
            GameTooltip:Show()
        end
    end)
    
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Drag handling
    frame:SetScript("OnDragStart", function(self)
        if not isEditingMode then return end
        self:StartMoving()
        self._isDragging = true
        self:SetFrameStrata("TOOLTIP")
        
        -- Store original position info
        self._dragStartCdID = self._placeholderCdID
        
        -- Clear selected state (we're now dragging)
        if selectedPlaceholderCdID == self._placeholderCdID then
            selectedPlaceholderCdID = nil
        end
        
        -- Set drag source info for drop indicator system
        local cdID = self._placeholderCdID
        local saved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[cdID]
        if saved and saved.type == "group" and saved.target then
            ns.CDMGroups._dragSourceGroup = ns.CDMGroups.groups[saved.target]
        else
            ns.CDMGroups._dragSourceGroup = nil
        end
    end)
    
    -- OnUpdate during drag to show drop indicators
    frame:SetScript("OnUpdate", function(self)
        if self._isDragging then
            local cx, cy = self:GetCenter()
            if cx and cy and ns.CDMGroups.UpdateDropIndicator then
                ns.CDMGroups.UpdateDropIndicator(cx, cy)
            end
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        if not self._isDragging then return end
        self:StopMovingOrSizing()
        self._isDragging = false
        self:SetFrameStrata("MEDIUM")
        
        -- Hide selection glow after drag
        ClearPlaceholderSelection(self)
        
        -- Hide drop indicators
        if ns.CDMGroups.HideDropIndicator then
            ns.CDMGroups.HideDropIndicator()
        end
        
        local cdID = self._dragStartCdID
        if not cdID then return end
        
        local cx, cy = self:GetCenter()
        if not cx or not cy then return end
        
        -- Check if dropped on a group using same logic as normal frames
        local targetGroup, targetRow, targetCol, mode, insertCol, insertRow
        if ns.CDMGroups.FindDropTarget then
            targetGroup, targetRow, targetCol, mode, insertCol, insertRow = ns.CDMGroups.FindDropTarget(cx, cy)
        end
        
        if targetGroup then
            -- Dropped on a group
            local Placeholders = ns.CDMGroups.Placeholders
            if Placeholders and Placeholders.UpdatePlaceholderPosition then
                local finalRow, finalCol = targetRow, targetCol
                
                if mode == "insert" or mode == "insert_start" or mode == "insert_end" then
                    finalCol = insertCol or targetCol
                elseif mode == "insert_row_above" or mode == "insert_row_below" then
                    finalRow = insertRow or targetRow
                    finalCol = 0
                end
                
                Placeholders.UpdatePlaceholderPosition(cdID, "group", targetGroup.name, finalRow, finalCol)
            end
        else
            -- Dropped outside groups - make it a free position
            local ux, uy = UIParent:GetCenter()
            local newX, newY = cx - ux, cy - uy
            
            local Placeholders = ns.CDMGroups.Placeholders
            if Placeholders and Placeholders.UpdatePlaceholderPosition then
                Placeholders.UpdatePlaceholderPosition(cdID, "free", nil, newX, newY)
            end
        end
        
        self._dragStartCdID = nil
        ns.CDMGroups._dragSourceGroup = nil
    end)
    
    -- Right-click to remove
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" and self._placeholderCdID then
            local Placeholders = ns.CDMGroups.Placeholders
            if Placeholders and Placeholders.RemovePlaceholder then
                Placeholders.RemovePlaceholder(self._placeholderCdID)
            end
        end
    end)
    
    frame._isPlaceholderFrame = true
    return frame
end

-- Acquire a placeholder frame from the pool
local function AcquirePlaceholderFrame()
    local frame = table.remove(placeholderFramePool)
    if not frame then
        frame = CreatePlaceholderFrame()
    end
    return frame
end

-- Release a placeholder frame back to the pool
local function ReleasePlaceholderFrame(frame)
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetParent(UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame._placeholderInfo = nil
    frame._placeholderCdID = nil
    frame._isDragging = nil
    frame._dragStartCdID = nil
    frame._savedLabelText = nil
    frame._savedLabelR = nil
    frame._savedLabelG = nil
    frame._savedLabelB = nil
    ClearPlaceholderSelection(frame)
    table.insert(placeholderFramePool, frame)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SLOT BADGE SYSTEM
-- Badges attached to group containers showing stack count at each slot
-- ═══════════════════════════════════════════════════════════════════════════

local slotBadgePool = {}
local activeSlotBadges = {}  -- [groupName] = { ["row,col"] = badge }

local function CreateSlotBadge()
    -- Simple small clickable badge
    local badge = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    badge:SetSize(18, 18)
    badge:SetFrameStrata("FULLSCREEN_DIALOG")  -- Above everything
    badge:SetFrameLevel(10000)  -- Very high to be above edit buttons
    badge:EnableMouse(true)
    badge:RegisterForClicks("AnyUp", "AnyDown")
    
    badge:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    badge:SetBackdropColor(0, 0, 0, 0.9)
    badge:SetBackdropBorderColor(1, 0.8, 0, 1)
    
    badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge.text:SetPoint("CENTER", 0, 0)
    badge.text:SetFont(badge.text:GetFont(), 11, "OUTLINE")
    badge.text:SetTextColor(1, 0.8, 0)
    
    -- Click to open slot selector
    badge:SetScript("OnMouseDown", function(self)
        if self._groupName and self._row ~= nil and self._col ~= nil then
            local items = GetItemsAtSlot(self._groupName, self._row, self._col)
            if #items > 1 and ShowSlotSelector then
                ShowSlotSelector(self, items, self._groupName, self._row, self._col)
            end
        end
    end)
    
    badge:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 1, 0.5, 1)
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Stacked Icons", 1, 0.8, 0)
        local count = self.text:GetText() or "?"
        GameTooltip:AddLine(count .. " abilities share this slot", 0.8, 0.8, 0.8)
        
        -- List items in the slot
        if self._groupName and self._row ~= nil and self._col ~= nil then
            local items = GetItemsAtSlot(self._groupName, self._row, self._col)
            if #items > 0 then
                GameTooltip:AddLine(" ")
                for _, item in ipairs(items) do
                    local prefix = item.isActive and "|cff00FF00" or "|cff888888"
                    local suffix = item.isActive and " [Active]|r" or "|r"
                    GameTooltip:AddLine("  " .. prefix .. (item.name or "Unknown") .. suffix)
                end
            end
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFFFF00Click to select ability|r")
        GameTooltip:Show()
    end)
    
    badge:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(1, 0.8, 0, 1)
        GameTooltip:Hide()
    end)
    
    badge:Hide()
    return badge
end

local function AcquireSlotBadge()
    local badge = table.remove(slotBadgePool)
    if not badge then
        badge = CreateSlotBadge()
    end
    return badge
end

local function ReleaseSlotBadge(badge)
    badge:Hide()
    badge:ClearAllPoints()
    badge:SetToplevel(false)
    badge:SetParent(UIParent)
    badge._groupName = nil
    badge._row = nil
    badge._col = nil
    badge._container = nil
    table.insert(slotBadgePool, badge)
end

-- Update slot badges for a group (call after Layout or after any placeholder change)
local function UpdateSlotBadgesForGroup(groupName, group, getSlotPosition, slotW, slotH)
    if not isEditingMode then
        -- Hide all badges for this group
        if activeSlotBadges[groupName] then
            for key, badge in pairs(activeSlotBadges[groupName]) do
                ReleaseSlotBadge(badge)
            end
            activeSlotBadges[groupName] = nil
        end
        return
    end
    
    if not group or not group.container then return end
    
    -- Initialize badge tracking for this group
    activeSlotBadges[groupName] = activeSlotBadges[groupName] or {}
    local usedKeys = {}
    
    -- Find all slots that have more than 1 item
    local maxRows = group.layout and group.layout.gridRows or 2
    local maxCols = group.layout and group.layout.gridCols or 4
    
    for row = 0, maxRows - 1 do
        for col = 0, maxCols - 1 do
            local count = GetSlotStackCount(groupName, row, col)
            local key = row .. "," .. col
            
            if count > 1 then
                -- Need a badge here
                local badge = activeSlotBadges[groupName][key]
                if not badge then
                    badge = AcquireSlotBadge()
                    activeSlotBadges[groupName][key] = badge
                end
                
                badge._groupName = groupName
                badge._row = row
                badge._col = col
                badge._container = group.container
                badge.text:SetText(tostring(count))
                
                -- Position at middle-right at the edge of the slot
                badge:SetParent(group.container)
                badge:SetFrameStrata("FULLSCREEN_DIALOG")  -- Reset strata after parenting
                badge:SetFrameLevel(10000)
                badge:SetToplevel(true)
                badge:ClearAllPoints()
                
                if getSlotPosition then
                    local slotX, slotY = getSlotPosition(row, col, group._leftOverflow or 0, group._topOverflow or 0)
                    -- Position badge centered on the right edge of slot
                    badge:SetPoint("CENTER", group.container, "TOPLEFT", slotX + slotW, slotY - (slotH / 2))
                else
                    -- Fallback positioning
                    local slotW_fb = group.layout and group.layout.iconSize or 36
                    local spacingX = group.layout and (group.layout.spacingX or group.layout.spacing) or 2
                    local spacingY = group.layout and (group.layout.spacingY or group.layout.spacing) or 2
                    local borderOffset = 6
                    local padding = group.containerPadding or 0
                    local leftOverflow = group._leftOverflow or 0
                    local topOverflow = group._topOverflow or 0
                    local slotX = borderOffset + padding + leftOverflow + col * (slotW_fb + spacingX)
                    local slotY = -(borderOffset + padding + topOverflow + row * (slotW_fb + spacingY))
                    badge:SetPoint("CENTER", group.container, "TOPLEFT", slotX + slotW_fb, slotY - (slotW_fb / 2))
                end
                badge:Show()
                badge:Raise()  -- Ensure it's on top
                
                usedKeys[key] = true
            end
        end
    end
    
    -- Release badges no longer needed
    for key, badge in pairs(activeSlotBadges[groupName]) do
        if not usedKeys[key] then
            ReleaseSlotBadge(badge)
            activeSlotBadges[groupName][key] = nil
        end
    end
end

-- Refresh badges for a specific group (standalone call without getSlotPosition)
RefreshBadgesForGroup = function(groupName)
    if not isEditingMode then return end
    local group = ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
    if not group or not group.container then return end
    
    local slotW = group.layout and group.layout.iconSize or 36
    local slotH = slotW
    
    -- Pass nil for getSlotPosition - UpdateSlotBadgesForGroup has a fallback
    UpdateSlotBadgesForGroup(groupName, group, nil, slotW, slotH)
end

-- Refresh badges for all groups
local function RefreshAllBadges()
    if not isEditingMode then return end
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
        RefreshBadgesForGroup(groupName)
    end
end

-- Hide all slot badges
local function HideAllSlotBadges()
    for groupName, badges in pairs(activeSlotBadges) do
        for key, badge in pairs(badges) do
            ReleaseSlotBadge(badge)
        end
    end
    wipe(activeSlotBadges)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SLOT SELECTOR POPUP
-- Shows when clicking on a badge - allows selecting which item to interact with
-- ═══════════════════════════════════════════════════════════════════════════

local slotSelectorFrame = nil

local function CreateSlotSelector()
    local f = CreateFrame("Frame", "ArcUI_SlotSelector", UIParent, "BackdropTemplate")
    f:SetSize(200, 100)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -8)
    f.title:SetText("Select Ability")
    f.title:SetTextColor(1, 0.8, 0)
    
    -- Close button
    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.closeBtn:SetPoint("TOPRIGHT", -2, -2)
    f.closeBtn:SetScript("OnClick", function() 
        f:Hide() 
        ClearSelectedPlaceholder()
    end)
    
    -- Content area for icons
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", 10, -30)
    f.content:SetPoint("BOTTOMRIGHT", -10, 10)
    
    -- Icon pool
    f.icons = {}
    
    f:Hide()
    return f
end

ShowSlotSelector = function(anchorFrame, items, groupName, row, col)
    if not slotSelectorFrame then
        slotSelectorFrame = CreateSlotSelector()
    end
    
    -- Clear any previous selection
    ClearSelectedPlaceholder()
    
    local f = slotSelectorFrame
    
    -- Store context
    f._groupName = groupName
    f._row = row
    f._col = col
    
    -- Hide existing icons
    for _, icon in ipairs(f.icons) do
        icon:Hide()
    end
    
    -- Calculate size
    local iconSize = 36
    local spacing = 6
    local iconsPerRow = 4
    local numItems = #items
    local numRows = math.ceil(numItems / iconsPerRow)
    local numCols = math.min(numItems, iconsPerRow)
    
    local contentW = numCols * (iconSize + spacing) - spacing
    local contentH = numRows * (iconSize + spacing + 18) - spacing
    
    f:SetSize(math.max(contentW + 24, 150), contentH + 50)
    
    -- Create/update icons
    for i, item in ipairs(items) do
        local icon = f.icons[i]
        if not icon then
            icon = CreateFrame("Button", nil, f.content)
            icon:SetSize(iconSize, iconSize)
            
            icon.tex = icon:CreateTexture(nil, "ARTWORK")
            icon.tex:SetAllPoints()
            icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            
            icon.highlight = icon:CreateTexture(nil, "HIGHLIGHT")
            icon.highlight:SetAllPoints()
            icon.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
            icon.highlight:SetBlendMode("ADD")
            
            icon.nameText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            icon.nameText:SetPoint("TOP", icon, "BOTTOM", 0, -2)
            icon.nameText:SetWidth(iconSize + 10)
            icon.nameText:SetJustifyH("CENTER")
            
            icon.activeGlow = icon:CreateTexture(nil, "OVERLAY")
            icon.activeGlow:SetPoint("TOPLEFT", -2, 2)
            icon.activeGlow:SetPoint("BOTTOMRIGHT", 2, -2)
            icon.activeGlow:SetColorTexture(0, 1, 0.5, 0.3)
            
            f.icons[i] = icon
        end
        
        local itemRow = math.floor((i - 1) / iconsPerRow)
        local itemCol = (i - 1) % iconsPerRow
        
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", f.content, "TOPLEFT", itemCol * (iconSize + spacing), -itemRow * (iconSize + spacing + 18))
        
        icon.tex:SetTexture(item.icon or 134400)
        icon.tex:SetDesaturated(false)  -- Never desaturate in selector
        icon.tex:SetAlpha(1.0)
        
        -- Truncate name if too long
        local displayName = item.name or "Unknown"
        if #displayName > 10 then
            displayName = displayName:sub(1, 8) .. ".."
        end
        icon.nameText:SetText(displayName)
        icon.nameText:SetTextColor(item.isKnown and 1 or 0.6, item.isKnown and 1 or 0.6, item.isKnown and 1 or 0.6)
        
        -- Show active glow
        if item.isActive then
            icon.activeGlow:Show()
        else
            icon.activeGlow:Hide()
        end
        
        icon._item = item
        icon._groupName = groupName
        icon._row = row
        icon._col = col
        
        icon:SetScript("OnClick", function(self)
            f:Hide()
            
            local selectedItem = self._item
            if not selectedItem then return end
            
            local cdID = selectedItem.cooldownID
            if not cdID then return end
            
            if selectedItem.isActive then
                -- Active frame - just print message, frame can be dragged directly
                print("|cff00ccffArcUI|r: Selected active frame |cff00FFFF" .. (selectedItem.name or cdID) .. "|r - drag to reposition")
            else
                -- Placeholder - ensure it's visible and mark as selected
                ClearSelectedPlaceholder()  -- Clear previous selection
                
                -- Ensure placeholder exists and is visible
                local placeholderFrame = activePlaceholders[cdID]
                if not placeholderFrame then
                    -- Need to show this placeholder (it might be hidden behind a real frame)
                    placeholderFrame = AcquirePlaceholderFrame()
                    activePlaceholders[cdID] = placeholderFrame
                    
                    local info = GetCooldownInfo(cdID)
                    if info then
                        placeholderFrame.Icon:SetTexture(info.icon or 134400)
                        placeholderFrame._placeholderInfo = info
                        placeholderFrame._placeholderCdID = cdID
                        placeholderFrame.Icon:SetDesaturated(not info.isKnown)
                        placeholderFrame.Icon:SetAlpha(info.isKnown and 0.9 or 0.6)
                    end
                end
                
                -- Position at the slot
                local group = ns.CDMGroups.groups and ns.CDMGroups.groups[self._groupName]
                if group and group.container then
                    local layout = group.layout or {}
                    local slotW = layout.iconSize or 36
                    local slotH = slotW
                    local spacingX = layout.spacingX or layout.spacing or 2
                    local spacingY = layout.spacingY or layout.spacing or 2
                    
                    local borderOffset = 6
                    local padding = group.containerPadding or 0
                    local leftOverflow = group._leftOverflow or 0
                    local topOverflow = group._topOverflow or 0
                    
                    local slotX = borderOffset + padding + leftOverflow + self._col * (slotW + spacingX)
                    local slotY = -(borderOffset + padding + topOverflow + self._row * (slotH + spacingY))
                    
                    local effectiveW, effectiveH = GetEffectivePlaceholderSize(cdID, layout)
                    local offsetX = (slotW - effectiveW) / 2
                    local offsetY = -(slotH - effectiveH) / 2
                    
                    placeholderFrame:SetSize(effectiveW, effectiveH)
                    placeholderFrame:SetParent(group.container)
                    placeholderFrame:ClearAllPoints()
                    placeholderFrame:SetPoint("TOPLEFT", group.container, "TOPLEFT", slotX + offsetX, slotY + offsetY)
                    placeholderFrame:SetFrameStrata("TOOLTIP")  -- Above real frame
                    placeholderFrame:SetFrameLevel(100)
                end
                
                -- Save current label state and show selection
                local r, g, b = placeholderFrame.PlaceholderText:GetTextColor()
                placeholderFrame._savedLabelText = placeholderFrame.PlaceholderText:GetText()
                placeholderFrame._savedLabelR = r
                placeholderFrame._savedLabelG = g
                placeholderFrame._savedLabelB = b
                
                placeholderFrame.PlaceholderText:SetText("DRAG ME")
                placeholderFrame.PlaceholderText:SetTextColor(0, 1, 0.5)
                placeholderFrame._selectionGlow:Show()
                placeholderFrame:Show()
                
                -- Track as selected
                selectedPlaceholderCdID = cdID
                
                print("|cff00ccffArcUI|r: Selected placeholder |cff00FF00" .. (selectedItem.name or cdID) .. "|r - drag to reposition")
            end
        end)
        
        icon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self._item.spellID then
                GameTooltip:SetSpellByID(self._item.spellID)
            else
                GameTooltip:AddLine(self._item.name or "Unknown", 1, 1, 1)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff888888CooldownID: " .. (self._item.cooldownID or "?") .. "|r")
            if self._item.isActive then
                GameTooltip:AddLine("|cff00FFFF[Active Frame]|r")
            else
                GameTooltip:AddLine("|cffFFAA00[Placeholder]|r")
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFFFF00Click to select for dragging|r")
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        icon:Show()
    end
    
    -- Position near anchor
    f:ClearAllPoints()
    if anchorFrame then
        f:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 5, 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    f:Show()
end

HideSlotSelector = function()
    if slotSelectorFrame then
        slotSelectorFrame:Hide()
    end
    ClearSelectedPlaceholder()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEHOLDER MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

-- Ensure placeholder member exists in group for a saved position
-- This syncs savedPositions to group.members for placeholders
local function EnsurePlaceholderMember(cdID, saved)
    if not saved or saved.type ~= "group" or not saved.target then return end
    
    local group = ns.CDMGroups.groups and ns.CDMGroups.groups[saved.target]
    if not group then return end
    
    -- Check if member already exists
    if group.members and group.members[cdID] then return end
    
    -- Create placeholder member
    local info = GetCooldownInfo(cdID)
    local effectiveW, effectiveH = GetEffectivePlaceholderSize(cdID, group.layout)
    
    group.members = group.members or {}
    group.members[cdID] = {
        frame = nil,
        entry = nil,
        row = saved.row or 0,
        col = saved.col or 0,
        isPlaceholder = true,
        placeholderInfo = info,
        _effectiveIconW = effectiveW,
        _effectiveIconH = effectiveH,
    }
end

-- Convert a real frame back to placeholder (e.g., when talent disabled)
-- This triggers compaction by shifting frames back to fill the gap
local function ConvertToPlaceholder(cdID)
    if not cdID then return false end
    
    local saved = ns.CDMGroups.savedPositions[cdID]
    if not saved or saved.type ~= "group" or not saved.target then return false end
    
    local group = ns.CDMGroups.groups[saved.target]
    if not group or not group.members then return false end
    
    local member = group.members[cdID]
    if not member then return false end
    
    -- Skip if already a placeholder
    if member.isPlaceholder then return false end
    
    local row = member.row or 0
    local col = member.col or 0
    
    -- Convert to placeholder
    member.isPlaceholder = true
    member.frame = nil
    member.entry = nil
    member.placeholderInfo = GetCooldownInfo(cdID)
    
    -- Update saved position
    saved.isPlaceholder = true
    if ns.CDMGroups.SavePositionToSpec then
        ns.CDMGroups.SavePositionToSpec(cdID, saved, true)
    end
    
    -- Clear grid slot (so reflow can compact)
    if group.grid and group.grid[row] and group.grid[row][col] == cdID then
        group.grid[row][col] = nil
    end
    
    -- PULL-BACK LOGIC: Check if any frame was pushed from this position
    -- If so, move it back now that the slot is available
    local pulled, pulledCdID = PullFrameBackToSlot(group, row, col)
    if pulled then
        -- Frame was pulled back, skip reflow since Layout was already called
        if isEditingMode then
            RefreshBadgesForGroup(saved.target)
        end
        return true
    end
    
    -- Trigger compaction if autoReflow is enabled
    if group.autoReflow and group.ReflowIcons then
        group:ReflowIcons()
    else
        -- Even without autoReflow, re-layout to update visuals
        if group.Layout then
            group:Layout()
        end
    end
    
    -- Refresh badges
    if isEditingMode then
        RefreshBadgesForGroup(saved.target)
    end
    
    return true
end

-- Create placeholder for a cdID at specific position
local function CreatePlaceholder(cdID, positionType, targetGroup, row, col, x, y)
    if not cdID then return false end
    
    -- Don't create if real frame exists
    if HasRealFrame(cdID) then return false end
    
    local info = GetCooldownInfo(cdID)
    if not info then return false end
    
    -- Build saved position data
    local posData
    if positionType == "group" then
        posData = {
            type = "group",
            target = targetGroup,
            row = row or 0,
            col = col or 0,
            isPlaceholder = true,
        }
    else
        posData = {
            type = "free",
            x = x or 0,
            y = y or 0,
            iconSize = 36,
            isPlaceholder = true,
        }
    end
    
    -- Save position using verified profile table
    local profileSavedPositions = ns.CDMGroups.GetProfileSavedPositions and ns.CDMGroups.GetProfileSavedPositions()
    if profileSavedPositions then
        profileSavedPositions[cdID] = posData
    end
    if ns.CDMGroups.SavePositionToSpec then
        ns.CDMGroups.SavePositionToSpec(cdID, posData, true)
    end
    
    -- If in a group, add as placeholder member with proper grid handling
    if positionType == "group" and targetGroup then
        local group = ns.CDMGroups.groups[targetGroup]
        if group then
            -- Ensure grid dimensions can accommodate the position
            group.layout = group.layout or {}
            group.layout.gridRows = group.layout.gridRows or 2
            group.layout.gridCols = group.layout.gridCols or 4
            
            local targetRow = row or 0
            local targetCol = col or 0
            
            -- Expand grid if needed
            if targetRow >= group.layout.gridRows then
                group.layout.gridRows = targetRow + 1
            end
            if targetCol >= group.layout.gridCols then
                group.layout.gridCols = targetCol + 1
            end
            
            -- Check if there's a real frame at this position (stacking)
            group.grid = group.grid or {}
            group.grid[targetRow] = group.grid[targetRow] or {}
            local existingCdID = group.grid[targetRow][targetCol]
            local shouldClaimGrid = true
            
            if existingCdID and existingCdID ~= cdID then
                local existingMember = group.members and group.members[existingCdID]
                if existingMember and not existingMember.isPlaceholder then
                    -- Real frame exists - check stack limit
                    local stackCount = 1
                    for otherCdID, otherSaved in pairs(ns.CDMGroups.savedPositions) do
                        if otherCdID ~= cdID and otherCdID ~= existingCdID 
                           and otherSaved.type == "group" 
                           and otherSaved.target == targetGroup
                           and otherSaved.row == targetRow and otherSaved.col == targetCol then
                            stackCount = stackCount + 1
                        end
                    end
                    
                    if stackCount >= 3 then
                        -- At max - find free slot
                        local foundFreeSlot = false
                        for r = 0, group.layout.gridRows - 1 do
                            for c = 0, group.layout.gridCols - 1 do
                                if not group.grid[r] then group.grid[r] = {} end
                                if not group.grid[r][c] then
                                    targetRow = r
                                    targetCol = c
                                    posData.row = r
                                    posData.col = c
                                    foundFreeSlot = true
                                    break
                                end
                            end
                            if foundFreeSlot then break end
                        end
                        if not foundFreeSlot then
                            local newRow = group.layout.gridRows
                            group.layout.gridRows = newRow + 1
                            targetRow = newRow
                            targetCol = 0
                            posData.row = newRow
                            posData.col = 0
                            group.grid[newRow] = {}
                        end
                    else
                        -- Under limit - stack behind real frame
                        shouldClaimGrid = false
                    end
                end
            end
            
            -- Get effective size for placeholder
            local effectiveW, effectiveH = GetEffectivePlaceholderSize(cdID, group.layout)
            
            group.members = group.members or {}
            group.members[cdID] = {
                frame = nil,
                entry = nil,
                row = targetRow,
                col = targetCol,
                isPlaceholder = true,
                placeholderInfo = info,
                _effectiveIconW = effectiveW,
                _effectiveIconH = effectiveH,
            }
            
            -- Only claim grid if not stacking behind a real frame
            if shouldClaimGrid then
                group.grid[targetRow][targetCol] = cdID
            end
            
            -- Trigger Layout
            if group.Layout then
                group:Layout()
            end
        end
    end
    
    -- Show placeholder if in editing mode
    if isEditingMode then
        local ShowPlaceholder = ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.ShowPlaceholder
        if ShowPlaceholder then
            ShowPlaceholder(cdID)
        end
    end
    
    return true
end

-- Update placeholder position (called after drag)
UpdatePlaceholderPosition = function(cdID, positionType, targetGroupName, arg1, arg2)
    if not cdID then return end
    
    -- Get verified profile savedPositions table
    local profileSavedPositions = ns.CDMGroups.GetProfileSavedPositions and ns.CDMGroups.GetProfileSavedPositions()
    local savedPositions = profileSavedPositions or ns.CDMGroups.savedPositions
    
    local oldSaved = savedPositions and savedPositions[cdID]
    local oldGroupName = oldSaved and oldSaved.type == "group" and oldSaved.target
    local oldRow = oldSaved and oldSaved.row
    local oldCol = oldSaved and oldSaved.col
    
    -- Build new position data FIRST
    local posData
    if positionType == "group" then
        local row, col = arg1, arg2
        posData = {
            type = "group",
            target = targetGroupName,
            row = row or 0,
            col = col or 0,
            isPlaceholder = oldSaved and oldSaved.isPlaceholder or true,
        }
    else
        local x, y = arg1, arg2
        posData = {
            type = "free",
            x = x or 0,
            y = y or 0,
            iconSize = 36,
            isPlaceholder = oldSaved and oldSaved.isPlaceholder or true,
        }
    end
    
    -- Update savedPositions BEFORE calling Layout (prevents re-adding from old position)
    if savedPositions then
        savedPositions[cdID] = posData
    end
    if ns.CDMGroups.SavePositionToSpec then
        ns.CDMGroups.SavePositionToSpec(cdID, posData, true)
    end
    
    -- Remove from old group if applicable
    if oldGroupName then
        local oldGroup = ns.CDMGroups.groups[oldGroupName]
        if oldGroup then
            -- Remove from members
            if oldGroup.members and oldGroup.members[cdID] then
                local member = oldGroup.members[cdID]
                -- Clear grid at member's position
                if member.row ~= nil and member.col ~= nil and oldGroup.grid and oldGroup.grid[member.row] then
                    if oldGroup.grid[member.row][member.col] == cdID then
                        oldGroup.grid[member.row][member.col] = nil
                    end
                end
                oldGroup.members[cdID] = nil
            end
            
            -- Also clear grid at old saved position
            if oldRow ~= nil and oldCol ~= nil and oldGroup.grid and oldGroup.grid[oldRow] then
                if oldGroup.grid[oldRow][oldCol] == cdID then
                    oldGroup.grid[oldRow][oldCol] = nil
                end
            end
            
            -- Update old group layout and badges
            if oldGroup.Layout then
                oldGroup:Layout()
            end
        end
    end
    
    -- Add to new group if applicable
    if positionType == "group" and targetGroupName then
        local row, col = arg1, arg2
        local group = ns.CDMGroups.groups[targetGroupName]
        if group then
            local info = GetCooldownInfo(cdID)
            
            group.layout = group.layout or {}
            group.layout.gridRows = group.layout.gridRows or 2
            group.layout.gridCols = group.layout.gridCols or 4
            
            -- Expand grid if needed
            if row >= group.layout.gridRows then
                group.layout.gridRows = row + 1
            end
            if col >= group.layout.gridCols then
                group.layout.gridCols = col + 1
            end
            
            -- Check for stacking
            group.grid = group.grid or {}
            group.grid[row] = group.grid[row] or {}
            local existingCdID = group.grid[row][col]
            local shouldClaimGrid = true
            
            if existingCdID and existingCdID ~= cdID then
                local existingMember = group.members and group.members[existingCdID]
                if existingMember and not existingMember.isPlaceholder then
                    -- Stack behind real frame (don't claim grid)
                    shouldClaimGrid = false
                end
            end
            
            local effectiveW, effectiveH = GetEffectivePlaceholderSize(cdID, group.layout)
            
            group.members = group.members or {}
            group.members[cdID] = {
                frame = nil,
                entry = nil,
                row = row,
                col = col,
                isPlaceholder = true,
                placeholderInfo = info,
                _effectiveIconW = effectiveW,
                _effectiveIconH = effectiveH,
            }
            
            if shouldClaimGrid then
                group.grid[row][col] = cdID
            end
            
            if group.Layout then
                group:Layout()
            end
        end
    end
    
    -- Refresh display and badges
    if isEditingMode then
        RefreshAllPlaceholders()
        -- Refresh badges for old and new groups
        if oldGroupName then
            RefreshBadgesForGroup(oldGroupName)
        end
        if positionType == "group" and targetGroupName then
            RefreshBadgesForGroup(targetGroupName)
        end
    end
end

-- Remove a placeholder
RemovePlaceholder = function(cdID)
    if not cdID then return end
    
    -- Clear selection if this was selected
    if selectedPlaceholderCdID == cdID then
        selectedPlaceholderCdID = nil
    end
    
    -- Get verified profile savedPositions table
    local profileSavedPositions = ns.CDMGroups.GetProfileSavedPositions and ns.CDMGroups.GetProfileSavedPositions()
    local savedPositions = profileSavedPositions or ns.CDMGroups.savedPositions
    
    local saved = savedPositions and savedPositions[cdID]
    local groupName = saved and saved.type == "group" and saved.target
    local savedRow = saved and saved.row
    local savedCol = saved and saved.col
    
    -- Hide placeholder frame FIRST
    local placeholderFrame = activePlaceholders[cdID]
    if placeholderFrame then
        ReleasePlaceholderFrame(placeholderFrame)
        activePlaceholders[cdID] = nil
    end
    
    -- Remove from group members BEFORE clearing savedPositions
    if groupName then
        local group = ns.CDMGroups.groups[groupName]
        if group then
            -- Always remove from members
            if group.members and group.members[cdID] then
                local member = group.members[cdID]
                -- Clear grid at member's position
                if member.row ~= nil and member.col ~= nil and group.grid and group.grid[member.row] then
                    if group.grid[member.row][member.col] == cdID then
                        group.grid[member.row][member.col] = nil
                    end
                end
                group.members[cdID] = nil
            end
            
            -- Also clear grid at saved position (in case member position was different)
            if savedRow ~= nil and savedCol ~= nil and group.grid and group.grid[savedRow] then
                if group.grid[savedRow][savedCol] == cdID then
                    group.grid[savedRow][savedCol] = nil
                end
            end
        end
    end
    
    -- Clear saved position from verified profile table
    if savedPositions then
        savedPositions[cdID] = nil
    end
    if ns.CDMGroups.ClearPositionFromSpec then
        ns.CDMGroups.ClearPositionFromSpec(cdID)
    end
    
    -- Now update badges - AFTER all data is cleared
    if isEditingMode and groupName then
        -- Directly check and remove badge if count is now <= 1
        if savedRow ~= nil and savedCol ~= nil then
            local key = savedRow .. "," .. savedCol
            local count = GetSlotStackCount(groupName, savedRow, savedCol)
            
            if count <= 1 then
                -- Remove this specific badge
                if activeSlotBadges[groupName] and activeSlotBadges[groupName][key] then
                    ReleaseSlotBadge(activeSlotBadges[groupName][key])
                    activeSlotBadges[groupName][key] = nil
                end
            else
                -- Update badge count
                if activeSlotBadges[groupName] and activeSlotBadges[groupName][key] then
                    activeSlotBadges[groupName][key].text:SetText(tostring(count))
                end
            end
        end
        
        -- Full refresh to be safe
        RefreshBadgesForGroup(groupName)
    end
    
    -- Trigger Layout AFTER everything else
    if groupName then
        local group = ns.CDMGroups.groups[groupName]
        if group and group.Layout then
            group:Layout()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEHOLDER DISPLAY
-- ═══════════════════════════════════════════════════════════════════════════

-- Show a single placeholder
local function ShowPlaceholder(cdID)
    if not isEditingMode then return end
    if HasRealFrame(cdID) then return end
    
    local saved = ns.CDMGroups.savedPositions[cdID]
    if not saved then return end
    
    -- Check if stacked behind a real frame - if so, don't show visually
    -- (but still track it for badge count)
    if saved.type == "group" and saved.target then
        local row = saved.row or 0
        local col = saved.col or 0
        if HasRealFrameAtPosition(saved.target, row, col) then
            -- Hide if currently showing
            local existingFrame = activePlaceholders[cdID]
            if existingFrame then
                existingFrame:Hide()
            end
            return
        end
    end
    
    local info = GetCooldownInfo(cdID)
    if not info then return end
    
    -- Get or create placeholder frame
    local placeholderFrame = activePlaceholders[cdID]
    if not placeholderFrame then
        placeholderFrame = AcquirePlaceholderFrame()
        activePlaceholders[cdID] = placeholderFrame
    end
    
    -- Configure frame
    placeholderFrame.Icon:SetTexture(info.icon or 134400)
    placeholderFrame._placeholderInfo = info
    placeholderFrame._placeholderCdID = cdID
    
    -- Determine state and styling
    local isReserved = saved.isPlaceholder
    local isLearned = info.isKnown
    
    local labelText = isReserved and "RESERVED" or "INACTIVE"
    placeholderFrame.PlaceholderText:SetText(labelText)
    
    if isLearned then
        placeholderFrame.Icon:SetDesaturated(false)
        placeholderFrame.Icon:SetAlpha(0.7)
        placeholderFrame.UnlearnedOverlay:Hide()
        placeholderFrame.PlaceholderText:SetTextColor(0.5, 0.8, 0.5)
    else
        placeholderFrame.Icon:SetDesaturated(true)
        placeholderFrame.Icon:SetAlpha(0.5)
        placeholderFrame.UnlearnedOverlay:Show()
        placeholderFrame.PlaceholderText:SetTextColor(0.8, 0.6, 0.3)
    end
    
    -- Position based on saved data
    if saved.type == "group" and saved.target then
        local group = ns.CDMGroups.groups[saved.target]
        if group and group.container then
            -- Use GetSlotDimensions for consistent sizing with real icons
            local slotW, slotH
            if ns.CDMGroups.GetSlotDimensions and group.layout then
                slotW, slotH = ns.CDMGroups.GetSlotDimensions(group.layout)
            else
                slotW = group.layout and group.layout.iconSize or 36
                slotH = slotW
            end
            local spacingX = group.layout and group.layout.spacingX or group.layout.spacing or 2
            local spacingY = group.layout and group.layout.spacingY or group.layout.spacing or 2
            
            -- For placeholders in groups, use the slot dimensions directly
            -- (GetEffectivePlaceholderSize checks per-icon overrides which placeholders shouldn't use)
            local effectiveW, effectiveH = slotW, slotH
            
            local row = saved.row or 0
            local col = saved.col or 0
            
            local borderOffset = 6
            local padding = group.containerPadding or 0
            local leftOverflow = group._leftOverflow or 0
            local topOverflow = group._topOverflow or 0
            
            local slotX = borderOffset + padding + leftOverflow + col * (slotW + spacingX)
            local slotY = -(borderOffset + padding + topOverflow + row * (slotH + spacingY))
            
            local offsetX = (slotW - effectiveW) / 2
            local offsetY = -(slotH - effectiveH) / 2
            
            placeholderFrame:SetSize(effectiveW, effectiveH)
            placeholderFrame:SetParent(group.container)
            placeholderFrame:SetFrameStrata("MEDIUM")
            placeholderFrame:SetFrameLevel(10)
            placeholderFrame:ClearAllPoints()
            placeholderFrame:SetPoint("TOPLEFT", group.container, "TOPLEFT", slotX + offsetX, slotY + offsetY)
        else
            local effectiveW, effectiveH = GetEffectivePlaceholderSize(cdID, nil)
            placeholderFrame:SetSize(effectiveW, effectiveH)
            placeholderFrame:SetParent(UIParent)
            placeholderFrame:ClearAllPoints()
            placeholderFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    elseif saved.type == "free" then
        local x = saved.x or 0
        local y = saved.y or 0
        local effectiveW, effectiveH = GetEffectivePlaceholderSize(cdID, nil)
        
        if saved.iconSize and effectiveW == 36 then
            effectiveW = saved.iconSize
            effectiveH = saved.iconSize
        end
        
        placeholderFrame:SetSize(effectiveW, effectiveH)
        placeholderFrame:SetParent(UIParent)
        placeholderFrame:SetFrameStrata("MEDIUM")
        placeholderFrame:SetFrameLevel(10)
        placeholderFrame:ClearAllPoints()
        placeholderFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    else
        local effectiveW, effectiveH = GetEffectivePlaceholderSize(cdID, nil)
        placeholderFrame:SetSize(effectiveW, effectiveH)
        placeholderFrame:SetParent(UIParent)
        placeholderFrame:ClearAllPoints()
        placeholderFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    placeholderFrame:Show()
end

-- Hide a single placeholder
local function HidePlaceholder(cdID)
    local placeholderFrame = activePlaceholders[cdID]
    if placeholderFrame then
        ReleasePlaceholderFrame(placeholderFrame)
        activePlaceholders[cdID] = nil
    end
    
    -- Clear selection if this was selected
    if selectedPlaceholderCdID == cdID then
        selectedPlaceholderCdID = nil
    end
end

-- FIX #2: Refresh all placeholders - AUTO-DETECTS all saved positions that should show as placeholders
RefreshAllPlaceholders = function()
    -- First hide all
    for cdID, frame in pairs(activePlaceholders) do
        ReleasePlaceholderFrame(frame)
    end
    wipe(activePlaceholders)
    
    -- Clear selection
    selectedPlaceholderCdID = nil
    
    if not isEditingMode then return end
    
    -- Scan ALL saved positions and show placeholders for those without real frames
    -- This auto-detects inactive saved positions (even those not explicitly marked as placeholders)
    for cdID, saved in pairs(ns.CDMGroups.savedPositions or {}) do
        if ShouldShowAsPlaceholder(cdID, saved) then
            -- Ensure member entry exists for group placeholders
            if saved.type == "group" and saved.target then
                EnsurePlaceholderMember(cdID, saved)
            end
            ShowPlaceholder(cdID)
        end
    end
    
    -- Refresh all badges
    RefreshAllBadges()
end

-- FIX #3: Position placeholders within a group (called from Layout)
-- Also handles showing placeholders when real frames move away
local function PositionPlaceholdersInGroup(groupName, group, getSlotPosition, slotW, slotH)
    if not isEditingMode then 
        if activeSlotBadges[groupName] then
            for key, badge in pairs(activeSlotBadges[groupName]) do
                ReleaseSlotBadge(badge)
            end
            activeSlotBadges[groupName] = nil
        end
        return 
    end
    if not group then return end
    
    -- First pass: Check savedPositions for ALL placeholders in this group
    -- This catches placeholders that might not be in group.members yet
    for cdID, saved in pairs(ns.CDMGroups.savedPositions or {}) do
        -- Skip Arc Aura IDs
        if not IsArcAuraID(cdID) and saved.type == "group" and saved.target == groupName and not HasRealFrame(cdID) then
            -- Ensure member entry exists
            EnsurePlaceholderMember(cdID, saved)
        end
    end
    
    -- Second pass: Position all placeholder members
    if group.members then
        for cdID, member in pairs(group.members) do
            -- Skip Arc Aura IDs
            if not IsArcAuraID(cdID) and member.isPlaceholder then
                local saved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[cdID]
                if saved and saved.type == "group" and saved.target == groupName then
                    local row = saved.row or 0
                    local col = saved.col or 0
                    
                    local hasRealFrameHere = HasRealFrameAtPosition(groupName, row, col)
                    
                    if hasRealFrameHere then
                        -- Hide this placeholder if it was showing (stacked behind real frame)
                        local existingFrame = activePlaceholders[cdID]
                        if existingFrame then
                            existingFrame:Hide()
                        end
                    else
                        -- FIX #3: Show placeholder - no real frame at this slot anymore
                        local placeholderFrame = activePlaceholders[cdID]
                        
                        if not placeholderFrame then
                            placeholderFrame = AcquirePlaceholderFrame()
                            activePlaceholders[cdID] = placeholderFrame
                        end
                        
                        local info = member.placeholderInfo or GetCooldownInfo(cdID)
                        if info then
                            placeholderFrame.Icon:SetTexture(info.icon or 134400)
                            placeholderFrame._placeholderInfo = info
                            placeholderFrame._placeholderCdID = cdID
                            
                            local isReserved = saved.isPlaceholder
                            placeholderFrame.PlaceholderText:SetText(isReserved and "RESERVED" or "INACTIVE")
                            
                            if info.isKnown then
                                placeholderFrame.Icon:SetDesaturated(false)
                                placeholderFrame.Icon:SetAlpha(0.7)
                                placeholderFrame.UnlearnedOverlay:Hide()
                                placeholderFrame.PlaceholderText:SetTextColor(0.5, 0.8, 0.5)
                            else
                                placeholderFrame.Icon:SetDesaturated(true)
                                placeholderFrame.Icon:SetAlpha(0.5)
                                placeholderFrame.UnlearnedOverlay:Show()
                                placeholderFrame.PlaceholderText:SetTextColor(0.8, 0.6, 0.3)
                            end
                        end
                        
                        local effectiveW, effectiveH = GetEffectivePlaceholderSize(cdID, group.layout)
                        local offsetX = (slotW - effectiveW) / 2
                        local offsetY = -(slotH - effectiveH) / 2
                        
                        placeholderFrame:SetSize(effectiveW, effectiveH)
                        placeholderFrame:SetParent(group.container)
                        placeholderFrame:SetFrameStrata("MEDIUM")
                        placeholderFrame:SetFrameLevel(10)
                        
                        local slotX, slotY = getSlotPosition(row, col, group._leftOverflow or 0, group._topOverflow or 0)
                        placeholderFrame:ClearAllPoints()
                        placeholderFrame:SetPoint("TOPLEFT", group.container, "TOPLEFT", slotX + offsetX, slotY + offsetY)
                        placeholderFrame:Show()
                    end
                end
            end
        end
    end
    
    -- Update slot badges
    UpdateSlotBadgesForGroup(groupName, group, getSlotPosition, slotW, slotH)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EDITING MODE
-- ═══════════════════════════════════════════════════════════════════════════

local function SetEditingMode(enabled)
    if isEditingMode == enabled then return end
    isEditingMode = enabled
    
    if enabled then
        RefreshAllPlaceholders()
    else
        -- Hide all placeholders
        for cdID, frame in pairs(activePlaceholders) do
            ReleasePlaceholderFrame(frame)
        end
        wipe(activePlaceholders)
        
        -- Clear selection
        selectedPlaceholderCdID = nil
        
        -- Hide all slot badges
        HideAllSlotBadges()
        
        -- Hide slot selector
        HideSlotSelector()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RESOLUTION - Replace placeholders with real frames
-- ═══════════════════════════════════════════════════════════════════════════

-- Helper: Get next slot position based on layout direction
local function GetNextSlot(group, row, col)
    local direction = group.layout and group.layout.direction or "HORIZONTAL"
    if direction == "VERTICAL" then
        return row + 1, col
    else
        return row, col + 1
    end
end

-- Helper: Push all real frames starting from a slot to make room
-- This cascades: if slot has frame, push it to next, recursively
-- Tracks original position so frame can be pulled back when slot becomes available
PushFramesFromSlot = function(group, row, col)
    if not group or not group.members then return end
    
    -- Find any real frame member at this SAVED position
    -- In autoReflow groups, member.row/col is visual compacted position, 
    -- but we need to check saved positions which are authoritative
    local cdIDAtSlot = nil
    local memberAtSlot = nil
    
    for cdID, member in pairs(group.members) do
        -- Skip Arc Aura IDs
        if not IsArcAuraID(cdID) and not member.isPlaceholder and member.frame then
            -- Check saved position (authoritative) not member position (visual)
            local saved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[cdID]
            local savedRow = saved and saved.row or member.row
            local savedCol = saved and saved.col or member.col
            
            if savedRow == row and savedCol == col then
                cdIDAtSlot = cdID
                memberAtSlot = member
                break
            end
        end
    end
    
    if not cdIDAtSlot or not memberAtSlot then return end  -- No real frame saved at this slot
    
    -- Calculate next slot
    local toRow, toCol = GetNextSlot(group, row, col)
    
    -- Expand grid if needed
    group.layout = group.layout or {}
    if toRow >= (group.layout.gridRows or 2) then
        group.layout.gridRows = toRow + 1
    end
    if toCol >= (group.layout.gridCols or 4) then
        group.layout.gridCols = toCol + 1
    end
    
    -- First, recursively push anything at the destination
    PushFramesFromSlot(group, toRow, toCol)
    
    -- TRACK ORIGINAL POSITION: Store where this frame was pushed from (saved position)
    -- Only set if not already pushed (preserve original origin through cascades)
    if not memberAtSlot._pushedFromRow then
        memberAtSlot._pushedFromRow = row
        memberAtSlot._pushedFromCol = col
        memberAtSlot._pushedFromGroup = group.name
    end
    
    -- Update saved position to new slot
    local saved = ns.CDMGroups.savedPositions[cdIDAtSlot]
    if saved and saved.type == "group" then
        saved.row = toRow
        saved.col = toCol
        if ns.CDMGroups.SavePositionToSpec then
            ns.CDMGroups.SavePositionToSpec(cdIDAtSlot, saved, true)
        end
    end
    
    -- Update member position too (for non-autoReflow or immediate visual update)
    memberAtSlot.row = toRow
    memberAtSlot.col = toCol
    
    -- Update grid
    group.grid = group.grid or {}
    group.grid[toRow] = group.grid[toRow] or {}
    group.grid[toRow][toCol] = cdIDAtSlot
    if group.grid[row] then
        group.grid[row][col] = nil  -- Clear old position
    end
    
    -- Trigger layout to reposition the frame visually
    if group.Layout then
        group:Layout()
    end
end

-- Helper: Pull a pushed frame back to its original position if slot is now empty
-- Called when a placeholder claims a position - check if any frame was pushed from there
local function PullFrameBackToSlot(group, row, col)
    if not group or not group.members then return false end
    
    -- Find any member that was pushed from this exact slot
    for cdID, member in pairs(group.members) do
        -- Skip Arc Aura IDs
        if not IsArcAuraID(cdID)
           and member._pushedFromGroup == group.name 
           and member._pushedFromRow == row 
           and member._pushedFromCol == col 
           and not member.isPlaceholder 
           and member.frame then
            
            -- Check if the slot is now available
            -- Look for any OTHER real frame with saved position at [row, col]
            local slotOccupied = false
            for otherCdID, otherMember in pairs(group.members) do
                -- Skip Arc Aura IDs
                if not IsArcAuraID(otherCdID)
                   and otherCdID ~= cdID 
                   and not otherMember.isPlaceholder 
                   and otherMember.frame then
                    local otherSaved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[otherCdID]
                    local otherRow = otherSaved and otherSaved.row or otherMember.row
                    local otherCol = otherSaved and otherSaved.col or otherMember.col
                    if otherRow == row and otherCol == col then
                        slotOccupied = true
                        break
                    end
                end
            end
            
            if not slotOccupied then
                -- Move frame back to original saved position
                local saved = ns.CDMGroups.savedPositions[cdID]
                if saved and saved.type == "group" then
                    -- Update saved position back to original
                    saved.row = row
                    saved.col = col
                    if ns.CDMGroups.SavePositionToSpec then
                        ns.CDMGroups.SavePositionToSpec(cdID, saved, true)
                    end
                end
                
                -- Update member position
                local oldRow, oldCol = member.row, member.col
                member.row = row
                member.col = col
                
                -- Update grid
                if group.grid then
                    if group.grid[oldRow] and group.grid[oldRow][oldCol] == cdID then
                        group.grid[oldRow][oldCol] = nil
                    end
                    group.grid[row] = group.grid[row] or {}
                    group.grid[row][col] = cdID
                end
                
                -- Clear the pushed tracking
                member._pushedFromRow = nil
                member._pushedFromCol = nil
                member._pushedFromGroup = nil
                
                -- Trigger layout to reposition
                if group.Layout then
                    group:Layout()
                end
                
                return true, cdID
            end
        end
    end
    
    return false
end

-- Helper: Displace occupant at a slot when a returning icon (from talent) needs it
-- Unlike PushFramesFromSlot, this PRESERVES the displaced icon's savedPosition
-- and uses proper priority: occupant's saved position if different, else find free slot
-- Returns: true if displacement succeeded (or slot was empty), false otherwise
local function DisplaceForReturningIcon(group, row, col, returningCdID)
    if not group or not group.members then return true end
    
    -- Check what's at this grid position
    local gridOccupant = group.grid and group.grid[row] and group.grid[row][col]
    if not gridOccupant or gridOccupant == returningCdID then
        return true  -- Slot is free or already claimed by returning icon
    end
    
    local occupantMember = group.members[gridOccupant]
    if not occupantMember then
        -- Stale grid entry, just clear it
        group.grid[row][col] = nil
        return true
    end
    
    -- Check if occupant has a valid frame
    local hasValidFrame = occupantMember.frame and 
        pcall(function() return occupantMember.frame.cooldownID end) and
        occupantMember.frame.cooldownID == gridOccupant
    
    if not hasValidFrame then
        -- Occupant has no valid frame, clear grid and member
        group.grid[row][col] = nil
        if occupantMember.entry then
            occupantMember.entry.manipulated = false
            occupantMember.entry.group = nil
        end
        group.members[gridOccupant] = nil
        return true
    end
    
    -- Occupant has a valid frame - need to displace it
    local occupantSaved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[gridOccupant]
    local targetRow, targetCol
    
    if occupantSaved and occupantSaved.type == "group" then
        local occupantSavedRow = occupantSaved.row or 0
        local occupantSavedCol = occupantSaved.col or 0
        
        if occupantSavedRow ~= row or occupantSavedCol ~= col then
            -- Occupant has DIFFERENT saved position - move it there
            targetRow, targetCol = occupantSavedRow, occupantSavedCol
        end
    end
    
    -- If no different saved position, find a free slot
    if not targetRow then
        if group.FindNextFreeSlot then
            targetRow, targetCol = group:FindNextFreeSlot(true)  -- Allow expansion
        end
    end
    
    if not targetRow then
        -- Can't find anywhere to put occupant
        return false
    end
    
    -- Track that this frame was pushed (for potential pull-back later)
    if not occupantMember._pushedFromRow then
        occupantMember._pushedFromRow = row
        occupantMember._pushedFromCol = col
        occupantMember._pushedFromGroup = group.name
    end
    
    -- Clear occupant from old position
    group.grid[row][col] = nil
    
    -- Move occupant to new position
    -- Use PlaceMemberAt if available for proper handling
    if group.PlaceMemberAt then
        group:PlaceMemberAt(gridOccupant, targetRow, targetCol)
    else
        -- Manual move
        occupantMember.row = targetRow
        occupantMember.col = targetCol
        group.grid[targetRow] = group.grid[targetRow] or {}
        group.grid[targetRow][targetCol] = gridOccupant
    end
    
    return true
end

local function ResolvePlaceholder(cdID, frame, entry)
    if not cdID or not frame then return false end
    
    local saved = ns.CDMGroups.savedPositions[cdID]
    if not saved then return false end
    
    -- Hide placeholder visual
    HidePlaceholder(cdID)
    
    if saved.type == "group" and saved.target then
        local group = ns.CDMGroups.groups[saved.target]
        if group and group.members and group.members[cdID] then
            local member = group.members[cdID]
            local row = member.row or saved.row or 0
            local col = member.col or saved.col or 0
            
            -- PUSH LOGIC: Push any real frame at this position to make room
            -- Use grid-based approach - cascade push from this slot
            PushFramesFromSlot(group, row, col)
            
            -- Convert from placeholder to real
            member.isPlaceholder = false
            member.placeholderInfo = nil
            member.frame = frame
            member.entry = entry
            member.row = row
            member.col = col
            
            -- Claim grid slot
            group.grid = group.grid or {}
            group.grid[row] = group.grid[row] or {}
            group.grid[row][col] = cdID
            
            -- Update saved position
            saved.isPlaceholder = false
            if ns.CDMGroups.SavePositionToSpec then
                ns.CDMGroups.SavePositionToSpec(cdID, saved, true)
            end
            
            -- CRITICAL: Notify DynamicLayout that placeholder was resolved
            if ns.CDMGroups.DynamicLayout and ns.CDMGroups.DynamicLayout.OnPlaceholderResolved then
                ns.CDMGroups.DynamicLayout.OnPlaceholderResolved(cdID, saved.target)
            end
            
            -- Trigger layout
            if group.Layout then
                group:Layout()
            end
            
            -- Refresh badges
            if isEditingMode then
                RefreshBadgesForGroup(saved.target)
            end
            
            return true
        end
    elseif saved.type == "free" then
        -- Update saved position
        saved.isPlaceholder = false
        if ns.CDMGroups.SavePositionToSpec then
            ns.CDMGroups.SavePositionToSpec(cdID, saved, true)
        end
        
        return true
    end
    
    return false
end

-- Resolve all placeholders that now have real frames
local function ResolveAllPlaceholders()
    local resolved = 0
    
    for cdID, saved in pairs(ns.CDMGroups.savedPositions or {}) do
        if saved.isPlaceholder and HasRealFrame(cdID) then
            -- Find the frame
            local frame, entry
            
            if saved.type == "group" and saved.target then
                local group = ns.CDMGroups.groups[saved.target]
                if group and group.members and group.members[cdID] then
                    local member = group.members[cdID]
                    frame = member.frame
                    entry = member.entry
                end
            elseif saved.type == "free" then
                local freeData = ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cdID]
                if freeData then
                    frame = freeData.frame
                    entry = freeData.entry
                end
            end
            
            if frame and ResolvePlaceholder(cdID, frame, entry) then
                resolved = resolved + 1
            end
        end
    end
    
    return resolved
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COOLDOWN PICKER UI
-- ═══════════════════════════════════════════════════════════════════════════

local pickerFrame = nil

local function CreatePickerFrame()
    local f = CreateFrame("Frame", "ArcUI_CooldownPicker", UIParent, "BackdropTemplate")
    f:SetSize(400, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("Add Placeholder")
    f.title:SetTextColor(1, 0.8, 0)
    
    -- Close button
    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.closeBtn:SetPoint("TOPRIGHT", -2, -2)
    f.closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    -- Tab buttons
    f.cooldownsTab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.cooldownsTab:SetSize(120, 24)
    f.cooldownsTab:SetPoint("TOPLEFT", 10, -35)
    f.cooldownsTab:SetText("Cooldowns")
    
    f.aurasTab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.aurasTab:SetSize(120, 24)
    f.aurasTab:SetPoint("LEFT", f.cooldownsTab, "RIGHT", 5, 0)
    f.aurasTab:SetText("Auras")
    
    -- Scroll frame
    f.scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    f.scrollFrame:SetPoint("TOPLEFT", 10, -70)
    f.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    f.scrollChild = CreateFrame("Frame", nil, f.scrollFrame)
    f.scrollChild:SetSize(f.scrollFrame:GetWidth(), 1)
    f.scrollFrame:SetScrollChild(f.scrollChild)
    
    -- Icon pool
    f.icons = {}
    
    -- Tab switching
    local function ShowTab(tabName)
        f._currentTab = tabName
        
        -- Update tab appearance
        if tabName == "cooldowns" then
            f.cooldownsTab:Disable()
            f.aurasTab:Enable()
        else
            f.cooldownsTab:Enable()
            f.aurasTab:Disable()
        end
        
        -- Populate icons
        local items = tabName == "cooldowns" and panelScanCache.cooldowns or panelScanCache.auras
        
        -- Hide all icons first
        for _, icon in ipairs(f.icons) do
            icon:Hide()
        end
        
        local iconSize = 36
        local spacing = 6
        local iconsPerRow = 8
        local yOffset = 0
        
        for i, item in ipairs(items) do
            local icon = f.icons[i]
            if not icon then
                icon = CreateFrame("Button", nil, f.scrollChild)
                icon:SetSize(iconSize, iconSize)
                
                icon.tex = icon:CreateTexture(nil, "ARTWORK")
                icon.tex:SetAllPoints()
                icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                
                icon.highlight = icon:CreateTexture(nil, "HIGHLIGHT")
                icon.highlight:SetAllPoints()
                icon.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
                icon.highlight:SetBlendMode("ADD")
                
                f.icons[i] = icon
            end
            
            local row = math.floor((i - 1) / iconsPerRow)
            local col = (i - 1) % iconsPerRow
            
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT", col * (iconSize + spacing), -row * (iconSize + spacing))
            
            icon.tex:SetTexture(item.icon or 134400)
            icon.tex:SetDesaturated(not item.isKnown)
            icon.tex:SetAlpha(item.isKnown and 1.0 or 0.5)
            
            icon._cooldownID = item.cooldownID
            icon._itemInfo = item
            
            icon:SetScript("OnClick", function(self)
                -- Create placeholder at center of screen (user can drag to position)
                local cdID = self._cooldownID
                if cdID then
                    CreatePlaceholder(cdID, "free", nil, nil, nil, 0, 0)
                    f:Hide()
                    print("|cff00ccffArcUI|r: Created placeholder for |cff00FF00" .. (self._itemInfo.name or cdID) .. "|r - drag to position")
                end
            end)
            
            icon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self._itemInfo.spellID then
                    GameTooltip:SetSpellByID(self._itemInfo.spellID)
                else
                    GameTooltip:AddLine(self._itemInfo.name or "Unknown", 1, 1, 1)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff888888CooldownID: " .. (self._cooldownID or "?") .. "|r")
                GameTooltip:AddLine("|cffFFFF00Click to create placeholder|r")
                GameTooltip:Show()
            end)
            
            icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            icon:Show()
            yOffset = (row + 1) * (iconSize + spacing)
        end
        
        f.scrollChild:SetHeight(math.max(yOffset, 100))
    end
    
    f.cooldownsTab:SetScript("OnClick", function() ShowTab("cooldowns") end)
    f.aurasTab:SetScript("OnClick", function() ShowTab("auras") end)
    
    f:SetScript("OnShow", function()
        ScanPanelForPicker()
        ShowTab("cooldowns")
    end)
    
    f:Hide()
    return f
end

local function ShowCooldownPicker()
    if not pickerFrame then
        pickerFrame = CreatePickerFrame()
    end
    
    pickerFrame:ClearAllPoints()
    pickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    pickerFrame:Show()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- OPTIONS TABLE FOR ACECONFIG
-- ═══════════════════════════════════════════════════════════════════════════

local function GetOptionsTable()
    return {
        placeholderHeader = {
            order = 100,
            type = "header",
            name = "Placeholders",
        },
        placeholderDesc = {
            order = 101,
            type = "description",
            name = "Placeholders show saved positions for cooldowns that aren't currently active. They appear when you open the options panel and can be dragged to new positions.",
        },
        addPlaceholderBtn = {
            order = 102,
            type = "execute",
            name = "Add Placeholder",
            desc = "Open the cooldown picker to create a new placeholder",
            width = 0.8,
            func = function()
                ShowCooldownPicker()
            end,
        },
        refreshPlaceholdersBtn = {
            order = 103,
            type = "execute",
            name = "Refresh",
            desc = "Refresh placeholder display",
            width = 0.6,
            func = function()
                RefreshAllPlaceholders()
            end,
        },
        placeholderInfo = {
            order = 104,
            type = "description",
            name = function()
                local count = 0
                for cdID, _ in pairs(activePlaceholders) do
                    count = count + 1
                end
                if count == 0 then
                    return "\n|cff888888No placeholders currently shown.|r"
                else
                    return string.format("\n|cff00ff00%d placeholder(s) currently shown.|r", count)
                end
            end,
        },
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LAYOUT INTEGRATION
-- ═══════════════════════════════════════════════════════════════════════════

local function ShouldTreatAsEmpty(member)
    if not member then return true end
    if not member.isPlaceholder then return false end
    return not isEditingMode
end

local function GetPlaceholderFrame(cdID)
    return activePlaceholders[cdID]
end

local function IsPlaceholder(cdID)
    local saved = ns.CDMGroups.savedPositions[cdID]
    return saved and saved.isPlaceholder
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

ns.CDMGroups = ns.CDMGroups or {}
ns.CDMGroups.Placeholders = {
    -- Core
    CreatePlaceholder = CreatePlaceholder,
    RemovePlaceholder = RemovePlaceholder,
    UpdatePlaceholderPosition = UpdatePlaceholderPosition,
    IsPlaceholder = IsPlaceholder,
    IsArcAuraID = IsArcAuraID,  -- Helper to detect Arc Aura string IDs
    HasRealFrame = HasRealFrame,
    ShouldShowAsPlaceholder = ShouldShowAsPlaceholder,
    EnsurePlaceholderMember = EnsurePlaceholderMember,
    
    -- Display
    SetEditingMode = SetEditingMode,
    RefreshAllPlaceholders = RefreshAllPlaceholders,
    ShowPlaceholder = ShowPlaceholder,
    HidePlaceholder = HidePlaceholder,
    PositionPlaceholdersInGroup = PositionPlaceholdersInGroup,
    
    -- Resolution
    ResolvePlaceholder = ResolvePlaceholder,
    ResolveAllPlaceholders = ResolveAllPlaceholders,
    ConvertToPlaceholder = ConvertToPlaceholder,
    PushFramesFromSlot = PushFramesFromSlot,
    PullFrameBackToSlot = PullFrameBackToSlot,
    DisplaceForReturningIcon = DisplaceForReturningIcon,
    
    -- Picker
    ShowCooldownPicker = ShowCooldownPicker,
    
    -- Slot Selector
    ShowSlotSelector = ShowSlotSelector,
    HideSlotSelector = HideSlotSelector,
    
    -- Data (API Scanning - taint-free)
    GetCooldownInfo = GetCooldownInfo,
    GetAllPossibleCooldowns = GetAllPossibleCooldowns,
    ScanCDMSettingsPanel = ScanCDMSettingsPanel,
    ScanPanelForPicker = ScanPanelForPicker,
    IsCooldownAlreadyManaged = IsCooldownAlreadyManaged,
    GetPanelScanCache = function() return panelScanCache end,
    
    -- Consolidated Position Helpers
    GetItemsAtSlot = GetItemsAtSlot,
    GetSlotStackCount = GetSlotStackCount,
    HasRealFrameAtPosition = HasRealFrameAtPosition,
    HasActiveFrame = HasActiveFrame,
    UpdateSlotBadgesForGroup = UpdateSlotBadgesForGroup,
    RefreshBadgesForGroup = RefreshBadgesForGroup,
    RefreshAllBadges = RefreshAllBadges,
    HideAllSlotBadges = HideAllSlotBadges,
    
    -- Selection state
    ClearSelectedPlaceholder = ClearSelectedPlaceholder,
    GetSelectedPlaceholder = function() return selectedPlaceholderCdID end,
    
    -- Layout integration
    ShouldTreatAsEmpty = ShouldTreatAsEmpty,
    GetPlaceholderFrame = GetPlaceholderFrame,
    
    -- Options
    GetOptionsTable = GetOptionsTable,
    
    -- State
    IsEditingMode = function() return isEditingMode end,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SLASH COMMAND
-- ═══════════════════════════════════════════════════════════════════════════

SLASH_ARCUIPLACEHOLDER1 = "/arcuiph"
SlashCmdList["ARCUIPLACEHOLDER"] = function(msg)
    local cmd = msg and msg:lower() or ""
    
    if cmd == "list" then
        print("|cff00ccffArcUI|r: === Reserved Placeholders ===")
        local count = 0
        for cdID, saved in pairs(ns.CDMGroups.savedPositions or {}) do
            if saved.isPlaceholder then
                count = count + 1
                local info = GetCooldownInfo(cdID)
                local status = info and info.isKnown and "|cff00ff00LEARNED|r" or "|cffff8800UNLEARNED|r"
                local pos = saved.type == "group" 
                    and string.format("Group: %s [%d,%d]", saved.target or "?", saved.row or 0, saved.col or 0)
                    or string.format("Free: %.0f, %.0f", saved.x or 0, saved.y or 0)
                print(string.format("  cdID %d: %s %s - %s", cdID, info and info.name or "Unknown", status, pos))
            end
        end
        if count == 0 then
            print("  |cff888888(none)|r")
        end
        
    elseif cmd == "inactive" then
        print("|cff00ccffArcUI|r: === Inactive Saved Positions ===")
        local count = 0
        for cdID, saved in pairs(ns.CDMGroups.savedPositions or {}) do
            if not HasRealFrame(cdID) then
                count = count + 1
                local info = GetCooldownInfo(cdID)
                local status = info and info.isKnown and "|cff00ff00LEARNED|r" or "|cffff8800UNLEARNED|r"
                local typeStr = saved.isPlaceholder and "|cffcc9900RESERVED|r" or "|cff8888ccINACTIVE|r"
                local pos = saved.type == "group" 
                    and string.format("Group: %s [%d,%d]", saved.target or "?", saved.row or 0, saved.col or 0)
                    or string.format("Free: %.0f, %.0f", saved.x or 0, saved.y or 0)
                print(string.format("  cdID %d: %s %s %s - %s", cdID, info and info.name or "Unknown", status, typeStr, pos))
            end
        end
        if count == 0 then
            print("  |cff888888(all saved positions have active frames)|r")
        end
        
    elseif cmd == "resolve" then
        local resolved = ResolveAllPlaceholders()
        print("|cff00ccffArcUI|r: Resolved", resolved, "placeholders")
        
    elseif cmd == "picker" then
        ShowCooldownPicker()
        
    elseif cmd == "edit" then
        SetEditingMode(not isEditingMode)
        print("|cff00ccffArcUI|r: Placeholder edit mode:", isEditingMode and "ON" or "OFF")
        
    else
        print("|cff00ccffArcUI|r: Placeholder Commands:")
        print("  /arcuiph list - List reserved placeholders")
        print("  /arcuiph inactive - List all inactive saved positions")
        print("  /arcuiph resolve - Resolve placeholders with real frames")
        print("  /arcuiph picker - Open cooldown picker")
        print("  /arcuiph edit - Toggle edit mode")
        print(" ")
        print("|cff00ccffColor Legend:|r")
        print("  |cff4caf50Green border|r = Reserved, spell learned")
        print("  |cffcc9900Orange border|r = Spell not learned")
        print("  |cff8888ddPurple border|r = Inactive saved position (learned)")
    end
end