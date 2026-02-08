-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI Arc Auras Options
-- Catalog-style options with embedded ItemDropBox widget for drag/drop
-- v1.2 - Added Auto-Track Equipped Slots subsection with per-slot control
-- ═══════════════════════════════════════════════════════════════════════════

local ADDON, ns = ...

local ArcAuras = ns.ArcAuras
local Options = {}
ns.ArcAurasOptions = Options

-- ═══════════════════════════════════════════════════════════════════════════
-- UI STATE
-- ═══════════════════════════════════════════════════════════════════════════

local selectedArcAura = nil
local selectedArcAuras = {}

-- Collapsible sections
local collapsedSections = {
    trackedItems = false,
    autoTrackSlots = false,
    management = true,
}

-- Cache
local cachedItemList = nil
local cacheInvalidated = true

-- Item ID input state
local pendingItemID = ""

-- ═══════════════════════════════════════════════════════════════════════════
-- CATALOG DATA
-- ═══════════════════════════════════════════════════════════════════════════

local function GetTrackedItemsList()
    if cachedItemList and not cacheInvalidated then
        return cachedItemList
    end
    
    if not ArcAuras then return {} end
    
    -- Use character-specific storage (not profile)
    local db = ns.db and ns.db.char and ns.db.char.arcAuras
    if not db or not db.trackedItems then return {} end
    
    local items = {}
    for arcID, config in pairs(db.trackedItems) do
        local name, icon = nil, nil
        local arcType, id = ArcAuras.ParseArcID(arcID)
        local itemID = nil
        
        if arcType == "trinket" then
            itemID = GetInventoryItemID("player", id)
            if itemID then
                name, icon = select(1, GetItemInfo(itemID)), select(10, GetItemInfo(itemID))
                icon = icon or GetInventoryItemTexture("player", id)
            end
            name = name or ("Trinket Slot " .. id)
        elseif arcType == "item" then
            itemID = config.itemID
            if itemID then
                name, icon = select(1, GetItemInfo(itemID)), select(10, GetItemInfo(itemID))
            end
            name = name or ("Item " .. (itemID or "?"))
        end
        
        table.insert(items, {
            arcID = arcID,
            arcType = arcType,
            itemID = itemID,
            name = name or "Unknown",
            icon = icon or 134400,
            config = config,
            enabled = config.enabled,
            isAutoTrackSlot = config.isAutoTrackSlot,
            hideWhenUnequipped = config.hideWhenUnequipped,
        })
    end
    
    table.sort(items, function(a, b)
        if a.arcType ~= b.arcType then
            return a.arcType == "trinket"
        end
        return a.name < b.name
    end)
    
    cachedItemList = items
    cacheInvalidated = false
    return items
end

local function GetItemByIndex(index)
    local items = GetTrackedItemsList()
    return items[index]
end

local function GetItemCount()
    local items = GetTrackedItemsList()
    return #items
end

local function GetSelectedItem()
    if not selectedArcAura then return nil end
    local items = GetTrackedItemsList()
    for _, item in ipairs(items) do
        if item.arcID == selectedArcAura then
            return item
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SELECTION HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function HideIfNoSelection()
    return selectedArcAura == nil and not next(selectedArcAuras)
end

local function GetSelectedCount()
    if next(selectedArcAuras) then
        local count = 0
        for _ in pairs(selectedArcAuras) do count = count + 1 end
        return count
    elseif selectedArcAura then
        return 1
    end
    return 0
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CATALOG ICON ENTRY
-- ═══════════════════════════════════════════════════════════════════════════

local function CreateCatalogIconEntry(index)
    return {
        type = "execute",
        name = function()
            local entry = GetItemByIndex(index)
            if not entry then return "" end
            
            local isSelected = selectedArcAura == entry.arcID or selectedArcAuras[entry.arcID]
            local isMulti = selectedArcAuras[entry.arcID]
            local hasCustom = ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(entry.arcID)
            
            -- Build status string
            local status = ""
            
            -- Auto-track indicator
            if entry.isAutoTrackSlot then
                status = "|cff88ff88A|r "
            -- Hide when unequipped indicator (only for non-auto-track items)
            elseif entry.hideWhenUnequipped then
                status = "|cff88aaeeH|r "
            end
            
            if isMulti then
                status = status .. (hasCustom and "|cff00ff00Multi|r |cffaa55ff*|r" or "|cff00ff00Multi|r")
            elseif isSelected then
                status = status .. (hasCustom and "|cff00ff00Edit|r |cffaa55ff*|r" or "|cff00ff00Edit|r")
            elseif not entry.enabled then
                status = status .. "|cff666666OFF|r"
            elseif hasCustom then
                status = status .. "|cffaa55ff*|r"
            end
            
            return status
        end,
        desc = function()
            local entry = GetItemByIndex(index)
            if not entry then return "" end
            
            local typeColor = entry.arcType == "trinket" and "|cff00ccff" or "|cff00ff00"
            local typeStr = entry.arcType == "trinket" and "Trinket" or "Item"
            
            local desc = "|cffffd700" .. entry.name .. "|r"
            if entry.itemID then
                desc = desc .. "\nItem ID: " .. entry.itemID
            end
            desc = desc .. "\nArc ID: " .. entry.arcID
            desc = desc .. "\nType: " .. typeColor .. typeStr .. "|r"
            
            -- Auto-track indicator
            if entry.isAutoTrackSlot then
                desc = desc .. "\n|cff88ff88Auto-Tracked Slot|r"
            end
            
            -- Hide when unequipped indicator
            if entry.hideWhenUnequipped then
                desc = desc .. "\n|cff88aaeeHides when unequipped|r"
            end
            
            if not entry.enabled then
                desc = desc .. "\n|cffff4444Disabled|r"
            end
            
            local hasCustom = ns.CDMEnhance and ns.CDMEnhance.HasPerIconSettings and ns.CDMEnhance.HasPerIconSettings(entry.arcID)
            if hasCustom then
                desc = desc .. "\n|cffaa55ffCustom settings in CDM Icons|r"
            end
            
            desc = desc .. "\n\n|cff888888Click to select  •  Shift+Click multi-select|r"
            return desc
        end,
        func = function()
            local entry = GetItemByIndex(index)
            if not entry then return end
            
            local arcID = entry.arcID
            
            if IsShiftKeyDown() then
                if selectedArcAura and not next(selectedArcAuras) then
                    selectedArcAuras[selectedArcAura] = true
                end
                
                if selectedArcAuras[arcID] then
                    selectedArcAuras[arcID] = nil
                else
                    selectedArcAuras[arcID] = true
                    if not selectedArcAura then selectedArcAura = arcID end
                end
            else
                wipe(selectedArcAuras)
                if selectedArcAura == arcID then
                    selectedArcAura = nil
                else
                    selectedArcAura = arcID
                end
            end
            
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
        image = function()
            local entry = GetItemByIndex(index)
            return entry and entry.icon or nil
        end,
        imageWidth = 32,
        imageHeight = 32,
        order = 50 + index,
        width = 0.25,
        hidden = function()
            if collapsedSections.trackedItems then return true end
            return GetItemByIndex(index) == nil
        end,
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTO-TRACK SLOT ENTRY
-- Creates a toggle for each trinket slot (full row per slot)
-- ═══════════════════════════════════════════════════════════════════════════

local function CreateAutoTrackSlotEntry(slotInfo)
    local slotID = slotInfo.slotID
    local slotName = slotInfo.name
    
    return {
        type = "toggle",
        name = function()
            local itemID = GetInventoryItemID("player", slotID)
            if itemID then
                local itemName = GetItemInfo(itemID)
                local isOnUse = ArcAuras.IsItemOnUse(itemID)
                local onUseStr = isOnUse and "|cff00ff00On-Use|r" or "|cff888888Passive|r"
                -- Format: [Icon] Slot Name: Item Name (On-Use/Passive)
                return string.format("|T%s:18|t  |cffffd700%s:|r %s (%s)", 
                    GetInventoryItemTexture("player", slotID) or 134400,
                    slotName,
                    itemName or "Loading...",
                    onUseStr)
            else
                return string.format("|TInterface\\Icons\\INV_Misc_QuestionMark:18|t  |cffffd700%s:|r |cff666666(Empty)|r", slotName)
            end
        end,
        desc = function()
            local itemID = GetInventoryItemID("player", slotID)
            local desc = slotName .. "\n"
            if itemID then
                local itemName = GetItemInfo(itemID)
                local isOnUse = ArcAuras.IsItemOnUse(itemID)
                desc = desc .. "\n|cffffd700" .. (itemName or "Loading...") .. "|r"
                desc = desc .. "\nItem ID: " .. itemID
                desc = desc .. "\n" .. (isOnUse and "|cff00ff00Has On-Use Effect|r" or "|cff888888Passive (No On-Use)|r")
            else
                desc = desc .. "\n|cff666666No trinket equipped|r"
            end
            desc = desc .. "\n\n|cff888888Toggle to enable/disable auto-tracking for this slot.|r"
            return desc
        end,
        order = slotID,
        width = "full",  -- Each slot on its own row
        get = function()
            return ArcAuras and ArcAuras.IsAutoTrackSlotEnabled(slotID)
        end,
        set = function(_, val)
            if ArcAuras and ArcAuras.SetAutoTrackSlotEnabled then
                ArcAuras.SetAutoTrackSlotEnabled(slotID, val)
                Options.InvalidateCache()
                if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                    ns.CDMEnhanceOptions.InvalidateCache()
                end
                LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            end
        end,
        hidden = function() 
            return collapsedSections.autoTrackSlots or not (ArcAuras and ArcAuras.IsAutoTrackEquippedTrinketsEnabled())
        end,
        disabled = function()
            -- Disable if on-use filter is on and trinket is passive
            if ArcAuras and ArcAuras.IsOnlyOnUseTrinketsEnabled() then
                local itemID = GetInventoryItemID("player", slotID)
                if itemID and ArcAuras.IsItemPassive(itemID) then
                    return true
                end
            end
            return false
        end,
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ACECONFIG OPTIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════

function ns.GetArcAurasOptionsTable()
    local args = {
        -- ═══════════════════════════════════════════════════════════════
        -- HEADER
        -- ═══════════════════════════════════════════════════════════════
        description = {
            type = "description",
            name = "|cff00CCFFArc Auras|r tracks item cooldowns (trinkets, potions, on-use items) that aren't covered by the Cooldown Manager.\n\nOnce added, icons appear in the |cff00ff00CDM Icons|r catalog for appearance settings.\n",
            order = 1,
            fontSize = "medium",
        },
        enabled = {
            type = "toggle",
            name = "Enable Arc Auras",
            desc = "Enable custom item cooldown tracking",
            order = 2,
            width = 1.2,
            get = function() 
                return ArcAuras and ArcAuras.IsEnabled and ArcAuras.IsEnabled() 
            end,
            set = function(_, val)
                if not ArcAuras then return end
                if val then ArcAuras.Enable() else ArcAuras.Disable() end
            end,
        },
        refreshBtn = {
            type = "execute",
            name = "Refresh",
            desc = "Show all frames at their saved positions (fixes missing icons after spec change)",
            order = 3,
            width = 0.6,
            func = function()
                if ArcAuras and ArcAuras.ForceShowAllFrames then
                    local count = ArcAuras.ForceShowAllFrames()
                    print("|cff00CCFF[Arc Auras]|r Showed " .. (count or 0) .. " frames")
                end
            end,
        },
        
        -- ═══════════════════════════════════════════════════════════════
        -- ADD ITEMS
        -- ═══════════════════════════════════════════════════════════════
        addHeader = {
            type = "header",
            name = "Add Items",
            order = 10,
        },
        addTrinketsBtn = {
            type = "execute",
            name = "|TInterface\\Icons\\INV_Trinket_80_Titan02a:16|t  Add On-Use Trinkets",
            desc = "Add frames for your currently equipped on-use trinkets.\n\n|cff88ff88These frames track the SPECIFIC ITEM|r - they won't change when you swap trinkets.\n\nUse this to add individual trinkets you want to track permanently.",
            order = 11,
            width = 1.1,
            func = function()
                if not ArcAuras then return end
                local added = ArcAuras.AutoAddTrinkets(true)
                print("|cff00CCFF[Arc Auras]|r Added " .. added .. " on-use trinket(s)")
                Options.InvalidateCache()
                if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                    ns.CDMEnhanceOptions.InvalidateCache()
                end
                LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            end,
        },
        itemIDLabel = {
            type = "description",
            name = "  |cff888888Item ID:|r",
            order = 12,
            fontSize = "small",
            width = 0.4,
        },
        itemIDInput = {
            type = "input",
            name = "",
            desc = "Enter an Item ID from Wowhead (e.g., 212456)",
            order = 13,
            width = 0.5,
            get = function() return pendingItemID end,
            set = function(_, val)
                pendingItemID = val:gsub("%D", "")  -- Remove non-digits
            end,
        },
        addByIDBtn = {
            type = "execute",
            name = "Add",
            desc = "Add the item by ID",
            order = 14,
            width = 0.35,
            disabled = function() return pendingItemID == "" end,
            func = function()
                local itemID = tonumber(pendingItemID)
                if itemID and itemID > 0 and ArcAuras then
                    local success = ArcAuras.AddTrackedItem({
                        type = "item",
                        itemID = itemID,
                        enabled = true,
                    })
                    if success then
                        local name = select(1, GetItemInfo(itemID)) or ("Item " .. itemID)
                        print("|cff00CCFF[Arc Auras]|r Added: " .. name)
                        pendingItemID = ""
                        Options.InvalidateCache()
                        if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                            ns.CDMEnhanceOptions.InvalidateCache()
                        end
                    else
                        print("|cff00CCFF[Arc Auras]|r Already tracked or invalid")
                    end
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end
            end,
        },
        
        -- Embedded drag/drop box using custom AceGUI widget
        itemDropBox = {
            type = "execute",
            name = "|cff00CCFFDrag Item to Track|r",
            dialogControl = "ItemDropBox",
            order = 15,
            width = "full",
            func = function(info)
                -- This is called when an item is dropped
                -- The actual handling is done in the widget's OnItemDropped callback
                -- We set up the callback via AceConfigDialog's widget access
            end,
        },
        
        -- ═══════════════════════════════════════════════════════════════
        -- TRACKED ITEMS CATALOG
        -- ═══════════════════════════════════════════════════════════════
        trackedItemsHeader = {
            type = "toggle",
            name = function()
                local count = GetItemCount()
                if count > 0 then
                    return "Tracked Items (" .. count .. ")"
                end
                return "Tracked Items"
            end,
            desc = "Click to expand/collapse",
            dialogControl = "CollapsibleHeader",
            get = function() return not collapsedSections.trackedItems end,
            set = function(_, v) 
                collapsedSections.trackedItems = not v 
            end,
            order = 40,
            width = "full",
        },
        catalogDesc = {
            type = "description",
            name = function()
                local count = GetItemCount()
                if count == 0 then
                    return "|cff888888No items tracked. Use buttons above to add.|r"
                end
                local sel = GetSelectedCount()
                local legendStr = "|cff888888Legend: |cff88ff88A|r=Auto-Track  |cff88aaeeH|r=Hide Unequipped  |cffaa55ff*|r=Custom Settings|r"
                if sel > 0 then
                    return string.format("|cff00ff00%d selected|r  |cff888888Click to select • Shift+Click multi-select|r\n%s", sel, legendStr)
                end
                return "|cff888888Click to select • Shift+Click multi-select|r\n" .. legendStr
            end,
            order = 41,
            fontSize = "small",
            hidden = function() return collapsedSections.trackedItems end,
        },
    }
    
    -- Add catalog icon entries (up to 30)
    for i = 1, 30 do
        args["catalogIcon" .. i] = CreateCatalogIconEntry(i)
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- SELECTED ITEM ACTIONS
    -- ═══════════════════════════════════════════════════════════════
    args.selectedHeader = {
        type = "header",
        name = function()
            local sel = GetSelectedCount()
            if sel > 1 then
                return "Selected (" .. sel .. " items)"
            end
            local item = GetSelectedItem()
            if item then
                return item.name
            end
            return "No Selection"
        end,
        order = 100,
        hidden = function() return collapsedSections.trackedItems or HideIfNoSelection() end,
    }
    args.toggleBtn = {
        type = "execute",
        name = function()
            local item = GetSelectedItem()
            if item then
                return item.enabled and "Disable" or "Enable"
            end
            return "Toggle"
        end,
        desc = "Enable or disable the selected item(s)",
        order = 101,
        width = 0.6,
        hidden = function() return collapsedSections.trackedItems or HideIfNoSelection() end,
        func = function()
            if not ArcAuras then return end
            
            local toToggle = {}
            if next(selectedArcAuras) then
                for arcID in pairs(selectedArcAuras) do
                    table.insert(toToggle, arcID)
                end
            elseif selectedArcAura then
                table.insert(toToggle, selectedArcAura)
            end
            
            for _, arcID in ipairs(toToggle) do
                local db = ns.db and ns.db.char and ns.db.char.arcAuras
                local config = db and db.trackedItems and db.trackedItems[arcID]
                if config then
                    ArcAuras.SetTrackedItemEnabled(arcID, not config.enabled)
                end
            end
            
            Options.InvalidateCache()
            if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                ns.CDMEnhanceOptions.InvalidateCache()
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
    }
    args.removeBtn = {
        type = "execute",
        name = "Remove",
        desc = "Remove the selected item(s)",
        order = 102,
        width = 0.6,
        hidden = function() return collapsedSections.trackedItems or HideIfNoSelection() end,
        confirm = true,
        confirmText = "Remove selected item(s)?",
        func = function()
            if not ArcAuras then return end
            
            local toRemove = {}
            if next(selectedArcAuras) then
                for arcID in pairs(selectedArcAuras) do
                    table.insert(toRemove, arcID)
                end
            elseif selectedArcAura then
                table.insert(toRemove, selectedArcAura)
            end
            
            for _, arcID in ipairs(toRemove) do
                ArcAuras.RemoveTrackedItem(arcID)
            end
            
            selectedArcAura = nil
            wipe(selectedArcAuras)
            Options.InvalidateCache()
            
            print("|cff00CCFF[Arc Auras]|r Removed " .. #toRemove .. " item(s)")
            if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                ns.CDMEnhanceOptions.InvalidateCache()
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
    }
    args.deselectBtn = {
        type = "execute",
        name = "Deselect",
        order = 103,
        width = 0.6,
        hidden = function() return collapsedSections.trackedItems or HideIfNoSelection() end,
        func = function()
            selectedArcAura = nil
            wipe(selectedArcAuras)
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
    }
    args.configureBtn = {
        type = "execute",
        name = "|cff00ff00Configure in CDM Icons|r",
        desc = "Open CDM Icons catalog to configure this item's appearance (Ready State glow, Cooldown State settings, etc)",
        order = 104,
        width = 1.4,
        hidden = function() 
            return collapsedSections.trackedItems or HideIfNoSelection() or GetSelectedCount() > 1 
        end,
        func = function()
            if selectedArcAura and ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
                ns.CDMEnhanceOptions.SelectIcon(selectedArcAura, false)
            end
        end,
    }
    args.hideWhenUnequippedToggle = {
        type = "toggle",
        name = "Hide When Unequipped",
        desc = "Hide this item's frame when the trinket is not equipped.\n\n|cff888888This preserves the frame's position - when you equip the trinket again, it will appear in the same spot.|r",
        order = 105,
        width = 1.2,
        hidden = function()
            if collapsedSections.trackedItems or HideIfNoSelection() or GetSelectedCount() > 1 then
                return true
            end
            -- Only show for item-based frames (not auto-track slots)
            local db = ns.db and ns.db.char and ns.db.char.arcAuras
            local config = db and db.trackedItems and selectedArcAura and db.trackedItems[selectedArcAura]
            if not config then return true end
            -- Hide for auto-track slots (they have their own hide logic)
            if config.isAutoTrackSlot then return true end
            -- Only show for item-based frames
            return config.type ~= "item"
        end,
        get = function()
            return ArcAuras and ArcAuras.IsHideWhenUnequippedEnabled and ArcAuras.IsHideWhenUnequippedEnabled(selectedArcAura)
        end,
        set = function(_, val)
            if ArcAuras and ArcAuras.SetHideWhenUnequipped and selectedArcAura then
                ArcAuras.SetHideWhenUnequipped(selectedArcAura, val)
                Options.InvalidateCache()
                LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            end
        end,
    }
    
    -- ═══════════════════════════════════════════════════════════════
    -- AUTO-TRACK EQUIPPED SLOTS
    -- ═══════════════════════════════════════════════════════════════
    args.autoTrackSlotsHeader = {
        type = "toggle",
        name = "Auto-Track Equipped Slots",
        desc = "Click to expand/collapse\n\nConfigure which equipment slots are automatically tracked. When enabled, frames automatically update when you change gear.",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.autoTrackSlots end,
        set = function(_, v) collapsedSections.autoTrackSlots = not v end,
        order = 150,
        width = "full",
    }
    args.autoTrackSlotsDesc = {
        type = "description",
        name = "|cff888888Auto-tracked slots automatically update their icon when you swap gear.\nSlots marked |cff88ff88A|r in Tracked Items above are auto-tracked.|r",
        order = 151,
        fontSize = "small",
        hidden = function() return collapsedSections.autoTrackSlots end,
    }
    args.autoTrackMasterToggle = {
        type = "toggle",
        name = "|TInterface\\Icons\\INV_Misc_Bag_10:16|t  Enable Auto-Track Equipped Trinkets",
        desc = "Master toggle for auto-tracking equipped trinkets.\n\nWhen enabled, creates 2 persistent frames that always show your equipped trinkets.\n\n|cff88ff88These frames track the SLOT|r - icons automatically update when you swap trinkets.\n\nDisabling this removes only the auto-track frames, not manually added trinkets.",
        order = 152,
        width = "full",
        get = function()
            return ArcAuras and ArcAuras.IsAutoTrackEquippedTrinketsEnabled()
        end,
        set = function(_, val)
            if ArcAuras and ArcAuras.SetAutoTrackEquippedTrinkets then
                ArcAuras.SetAutoTrackEquippedTrinkets(val)
                Options.InvalidateCache()
                if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                    ns.CDMEnhanceOptions.InvalidateCache()
                end
                LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                if val then
                    print("|cff00CCFF[Arc Auras]|r Auto-tracking equipped trinkets enabled")
                else
                    print("|cff00CCFF[Arc Auras]|r Auto-tracking equipped trinkets disabled")
                end
            end
        end,
        hidden = function() return collapsedSections.autoTrackSlots end,
    }
    args.onlyOnUseTrinkets = {
        type = "toggle",
        name = "|TInterface\\Icons\\Spell_Nature_Lightning:16|t  Only Track On-Use Trinkets",
        desc = "When enabled, passive trinkets (those without an on-use effect) will not be auto-tracked.\n\nThis helps reduce clutter if you only care about active trinket cooldowns.",
        order = 153,
        width = "full",
        get = function()
            return ArcAuras and ArcAuras.IsOnlyOnUseTrinketsEnabled()
        end,
        set = function(_, val)
            if ArcAuras and ArcAuras.SetOnlyOnUseTrinkets then
                ArcAuras.SetOnlyOnUseTrinkets(val)
                Options.InvalidateCache()
                if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                    ns.CDMEnhanceOptions.InvalidateCache()
                end
                LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            end
        end,
        hidden = function() 
            return collapsedSections.autoTrackSlots or not (ArcAuras and ArcAuras.IsAutoTrackEquippedTrinketsEnabled())
        end,
    }
    args.slotsSpacer = {
        type = "description",
        name = "",
        order = 154,
        fontSize = "small",
        hidden = function() 
            return collapsedSections.autoTrackSlots or not (ArcAuras and ArcAuras.IsAutoTrackEquippedTrinketsEnabled())
        end,
    }
    
    -- Add slot toggles for each trinket slot
    if ArcAuras and ArcAuras.GetTrinketSlots then
        local slots = ArcAuras.GetTrinketSlots()
        for i, slotInfo in ipairs(slots) do
            args["autoTrackSlot" .. slotInfo.slotID] = CreateAutoTrackSlotEntry(slotInfo)
            args["autoTrackSlot" .. slotInfo.slotID].order = 155 + i
        end
    else
        -- Fallback if ArcAuras not loaded yet
        args.autoTrackSlot13 = {
            type = "toggle",
            name = "|TInterface\\Icons\\INV_Misc_QuestionMark:18|t  |cffffd700Trinket 1:|r |cff666666(Loading...)|r",
            order = 156,
            width = "full",
            get = function() return true end,
            set = function() end,
            hidden = function() return collapsedSections.autoTrackSlots end,
        }
        args.autoTrackSlot14 = {
            type = "toggle",
            name = "|TInterface\\Icons\\INV_Misc_QuestionMark:18|t  |cffffd700Trinket 2:|r |cff666666(Loading...)|r",
            order = 157,
            width = "full",
            get = function() return true end,
            set = function() end,
            hidden = function() return collapsedSections.autoTrackSlots end,
        }
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- BULK MANAGEMENT
    -- ═══════════════════════════════════════════════════════════════
    args.managementHeader = {
        type = "toggle",
        name = "Bulk Management",
        desc = "Click to expand/collapse",
        dialogControl = "CollapsibleHeader",
        get = function() return not collapsedSections.management end,
        set = function(_, v) collapsedSections.management = not v end,
        order = 200,
        width = "full",
    }
    args.clearTrinkets = {
        type = "execute",
        name = "Clear Trinkets",
        desc = "Remove all trinkets from tracking",
        order = 201,
        width = 0.9,
        hidden = function() return collapsedSections.management end,
        confirm = true,
        confirmText = "Remove all tracked trinkets?",
        func = function()
            if not ArcAuras then return end
            local removed = 0
            local db = ns.db and ns.db.char and ns.db.char.arcAuras
            if db and db.trackedItems then
                local toRemove = {}
                for arcID in pairs(db.trackedItems) do
                    local arcType = ArcAuras.ParseArcID(arcID)
                    if arcType == "trinket" then
                        table.insert(toRemove, arcID)
                    end
                end
                for _, arcID in ipairs(toRemove) do
                    ArcAuras.RemoveTrackedItem(arcID)
                    removed = removed + 1
                end
            end
            selectedArcAura = nil
            wipe(selectedArcAuras)
            Options.InvalidateCache()
            print("|cff00CCFF[Arc Auras]|r Removed " .. removed .. " trinket(s)")
            if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                ns.CDMEnhanceOptions.InvalidateCache()
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
    }
    args.clearItems = {
        type = "execute",
        name = "Clear Custom Items",
        desc = "Remove all custom items (keeps trinkets)",
        order = 202,
        width = 1.1,
        hidden = function() return collapsedSections.management end,
        confirm = true,
        confirmText = "Remove all custom items?",
        func = function()
            if not ArcAuras then return end
            local removed = 0
            local db = ns.db and ns.db.char and ns.db.char.arcAuras
            if db and db.trackedItems then
                local toRemove = {}
                for arcID in pairs(db.trackedItems) do
                    local arcType = ArcAuras.ParseArcID(arcID)
                    if arcType == "item" then
                        table.insert(toRemove, arcID)
                    end
                end
                for _, arcID in ipairs(toRemove) do
                    ArcAuras.RemoveTrackedItem(arcID)
                    removed = removed + 1
                end
            end
            selectedArcAura = nil
            wipe(selectedArcAuras)
            Options.InvalidateCache()
            print("|cff00CCFF[Arc Auras]|r Removed " .. removed .. " item(s)")
            if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                ns.CDMEnhanceOptions.InvalidateCache()
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
    }
    args.clearAll = {
        type = "execute",
        name = "Clear All",
        desc = "Remove everything",
        order = 203,
        width = 0.7,
        hidden = function() return collapsedSections.management end,
        confirm = true,
        confirmText = "Remove ALL tracked items?",
        func = function()
            if not ArcAuras then return end
            local db = ns.db and ns.db.char and ns.db.char.arcAuras
            if db and db.trackedItems then
                local toRemove = {}
                for arcID in pairs(db.trackedItems) do
                    table.insert(toRemove, arcID)
                end
                for _, arcID in ipairs(toRemove) do
                    ArcAuras.RemoveTrackedItem(arcID)
                end
                print("|cff00CCFF[Arc Auras]|r Removed " .. #toRemove .. " item(s)")
            end
            selectedArcAura = nil
            wipe(selectedArcAuras)
            Options.InvalidateCache()
            if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                ns.CDMEnhanceOptions.InvalidateCache()
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
        end,
    }
    
    return {
        type = "group",
        name = "Arc Auras",
        order = 5,
        args = args,
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════════════════

function Options.InvalidateCache()
    cacheInvalidated = true
    cachedItemList = nil
end

function Options.Open()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory("ArcUI")
    end
end

-- Allow CDM Enhance Options to select an Arc Aura icon
function Options.SelectIcon(arcID)
    if not arcID then return end
    wipe(selectedArcAuras)
    selectedArcAura = arcID
    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT HANDLER: Refresh options when equipment changes
-- ═══════════════════════════════════════════════════════════════════════════

local optionsEventFrame = CreateFrame("Frame")
optionsEventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
optionsEventFrame:SetScript("OnEvent", function(self, event, slot)
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        -- Refresh options when trinket slots change (13 or 14)
        if slot == 13 or slot == 14 then
            -- Invalidate cache and refresh options display
            Options.InvalidateCache()
            -- Notify AceConfig to refresh the options panel
            C_Timer.After(0.1, function()
                LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
            end)
        end
    end
end)