-- ═══════════════════════════════════════════════════════════════════════════
-- AceGUI-3.0-ArcUI-Widgets
-- Custom AceGUI widgets for ArcUI
-- Place in: Libs/AceGUI-3.0-ArcUI-Widgets/AceGUI-3.0-ArcUI-Widgets.lua
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- ITEM DROP BOX WIDGET
-- A drag/drop target for adding items from bags
-- Can be used standalone or via AceConfig with dialogControl = "ItemDropBox"
--
-- Usage in AceConfig:
--   dropBox = {
--       type = "execute",
--       name = "Drag Item to Track",
--       dialogControl = "ItemDropBox",
--       func = function() end,  -- Required but not used
--       width = "full",
--   }
-- ═══════════════════════════════════════════════════════════════════════════

local Type, Version = "ItemDropBox", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Widget Methods
local methods = {
    ["OnAcquire"] = function(self)
        self:SetHeight(110)
        self:SetFullWidth(true)
        self.itemID = nil
        self.frame.StatusText:SetText("|cff888888Drop item from bags here|r")
        self.frame.DropBox.Icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
        self.frame.DropBox.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end,
    
    ["OnRelease"] = function(self)
        self.itemID = nil
        self:SetCallback("OnItemDropped", nil)
    end,
    
    ["SetWidth"] = function(self, width)
        self.frame:SetWidth(width)
    end,
    
    ["SetHeight"] = function(self, height)
        self.frame:SetHeight(height)
    end,
    
    -- AceConfig compatibility - SetFullWidth
    ["SetFullWidth"] = function(self, isFull)
        if isFull then
            self.frame:SetWidth(self.frame:GetParent() and self.frame:GetParent():GetWidth() - 20 or 280)
        end
    end,
    
    -- AceConfig compatibility - SetLabel (from name field)
    ["SetLabel"] = function(self, text)
        self.frame.Title:SetText(text or "|cff00CCFFDrag Item to Track|r")
    end,
    
    -- AceConfig compatibility - SetText (alias for SetLabel)
    ["SetText"] = function(self, text)
        self:SetLabel(text)
    end,
    
    -- AceConfig compatibility - for execute type
    ["SetCallback"] = function(self, name, func)
        if name == "OnClick" then
            -- AceConfig sends OnClick for execute, we use OnItemDropped
            self.callbacks = self.callbacks or {}
            self.callbacks["OnClick"] = func
        elseif name == "OnItemDropped" then
            self.callbacks = self.callbacks or {}
            self.callbacks["OnItemDropped"] = func
        end
    end,
    
    -- Fire callback
    ["Fire"] = function(self, name, ...)
        if self.callbacks and self.callbacks[name] then
            self.callbacks[name](self, name, ...)
        end
    end,
    
    ["SetStatusText"] = function(self, text)
        self.frame.StatusText:SetText(text or "")
    end,
    
    ["SetItem"] = function(self, itemID)
        self.itemID = itemID
        if itemID then
            local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
            if icon then
                self.frame.DropBox.Icon:SetTexture(icon)
                self.frame.DropBox.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            self.frame.StatusText:SetText(name and ("|cffffffff" .. name .. "|r") or ("|cff888888Item " .. itemID .. "|r"))
        else
            self.frame.DropBox.Icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
            self.frame.DropBox.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            self.frame.StatusText:SetText("|cff888888Drop item from bags here|r")
        end
    end,
    
    ["ClearItem"] = function(self)
        self:SetItem(nil)
    end,
    
    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled
        if disabled then
            self.frame:SetAlpha(0.5)
            self.frame.DropBox:EnableMouse(false)
        else
            self.frame:SetAlpha(1.0)
            self.frame.DropBox:EnableMouse(true)
        end
    end,
    
    -- AceConfig compatibility - required for execute type
    ["SetImage"] = function(self, path, ...)
        -- We use our own icon, ignore external images
    end,
    
    ["SetImageSize"] = function(self, width, height)
        -- Ignore
    end,
}

-- Constructor
local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(280, 110)
    frame:Hide()
    
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.2, 0.4, 0.6, 0.8)
    
    -- Title (centered at top)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText("|cff00CCFFDrag Item to Track|r")
    frame.Title = title
    
    -- Drop box (centered)
    local dropBox = CreateFrame("Button", nil, frame, "BackdropTemplate")
    dropBox:SetSize(64, 64)
    dropBox:SetPoint("CENTER", frame, "CENTER", 0, 2)
    dropBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    dropBox:SetBackdropColor(0.12, 0.12, 0.15, 1)
    dropBox:SetBackdropBorderColor(0.3, 0.5, 0.7, 1)
    frame.DropBox = dropBox
    
    -- Drop box icon
    local dropIcon = dropBox:CreateTexture(nil, "ARTWORK")
    dropIcon:SetPoint("TOPLEFT", 6, -6)
    dropIcon:SetPoint("BOTTOMRIGHT", -6, 6)
    dropIcon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
    dropIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    dropBox.Icon = dropIcon
    
    -- Status text (below drop box)
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)
    statusText:SetText("|cff888888Drop item from bags here|r")
    statusText:SetWidth(260)
    frame.StatusText = statusText
    
    -- Create widget object
    local widget = {
        type = Type,
        frame = frame,
        callbacks = {},
    }
    
    -- Handle item drop
    local function HandleDrop()
        if widget.disabled then return end
        local infoType, itemID = GetCursorInfo()
        if infoType == "item" then
            ClearCursor()
            widget.itemID = itemID
            
            -- Update visual
            local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
            if icon then
                dropBox.Icon:SetTexture(icon)
                dropBox.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            
            -- Try to add via ArcAuras
            local ADDON_NAME, ns = "ArcUI", _G.ArcUI_NS
            local ArcAuras = ns and ns.ArcAuras
            local ArcAurasOptions = ns and ns.ArcAurasOptions
            
            if ArcAuras and ArcAuras.AddTrackedItem then
                local success = ArcAuras.AddTrackedItem({
                    type = "item",
                    itemID = itemID,
                    enabled = true,
                })
                
                if success then
                    local displayName = name or ("Item " .. itemID)
                    print("|cff00CCFF[Arc Auras]|r Added: " .. displayName)
                    statusText:SetText("|cff00ff00Added: " .. displayName .. "|r")
                    
                    -- Invalidate caches and refresh UI
                    if ArcAurasOptions and ArcAurasOptions.InvalidateCache then
                        ArcAurasOptions.InvalidateCache()
                    end
                    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
                        ns.CDMEnhanceOptions.InvalidateCache()
                    end
                    local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
                    if AceConfigRegistry then
                        AceConfigRegistry:NotifyChange("ArcUI")
                    end
                    
                    -- Reset status after delay
                    C_Timer.After(1.5, function()
                        if frame:IsShown() then
                            statusText:SetText("|cff888888Drop another item|r")
                        end
                    end)
                else
                    statusText:SetText("|cffff4444Already tracked or invalid|r")
                    C_Timer.After(2, function()
                        if frame:IsShown() then
                            statusText:SetText("|cff888888Drop item from bags here|r")
                            widget:ClearItem()
                        end
                    end)
                end
            else
                -- No ArcAuras, just show what was dropped
                statusText:SetText(name and ("|cff00ff00" .. name .. "|r") or ("|cff00ff00Item " .. itemID .. "|r"))
            end
            
            -- Fire callbacks
            widget:Fire("OnItemDropped", itemID, name, icon)
            widget:Fire("OnClick")  -- For AceConfig compatibility
        end
    end
    
    dropBox:SetScript("OnReceiveDrag", HandleDrop)
    dropBox:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then HandleDrop() end
    end)
    
    dropBox:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.3, 0.8, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Drop Item Here", 0, 0.8, 1)
        GameTooltip:AddLine("Drag an item from your bags", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    dropBox:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.5, 0.7, 1)
        GameTooltip:Hide()
    end)
    
    -- Also accept drops on the whole frame
    frame:SetScript("OnReceiveDrag", HandleDrop)
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then HandleDrop() end
    end)
    
    -- Add methods
    for method, func in pairs(methods) do
        widget[method] = func
    end
    
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)