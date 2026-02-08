-- ============================================================================
-- Peralex BG - MinimapButton.lua
-- Minimap button for easy access to config
-- ============================================================================

local PE = _G.PeralexBG

function PE:CreateMinimapButton()
    if self.minimapButton then return end
    
    -- Create the button
    local button = CreateFrame("Button", "PeralexBGMinimapButton", Minimap, "BackdropTemplate")
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    
    -- Circular border (like other addon minimap buttons)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border = border
    
    -- Background circle
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("CENTER", 1, -1)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0, 0, 0, 0.8)
    button.bg = bg
    
    -- Icon
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\peralexbgicon.tga")
    button.icon = icon
    
    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(20, 20)
    highlight:SetPoint("CENTER", 0, 0)
    highlight:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\peralexbgicon.tga")
    highlight:SetAlpha(0.5)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Peralex BG", 1, 1, 1)
        GameTooltip:AddLine("Left-click: Open settings", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Toggle test mode", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag: Move button", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Click handlers
    button:SetScript("OnClick", function(self, btn)
        if btn == "LeftButton" then
            PE:OpenConfig()
        elseif btn == "RightButton" then
            PE:ToggleTestMode()
        end
    end)
    
    -- Drag handlers
    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", PE.UpdateMinimapButtonDrag)
    end)
    
    button:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
        PE:SaveMinimapButtonPosition()
    end)
    
    self.minimapButton = button
    self:UpdateMinimapButtonPosition()
end

function PE:UpdateMinimapButtonPosition()
    local button = PE.minimapButton
    if not button then return end
    
    local angle = PE.DB.minimap.angle or 225
    local radius = 90 -- Distance from minimap center (outer edge)
    
    local x = radius * math.cos(math.rad(angle))
    local y = radius * math.sin(math.rad(angle))
    
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function PE.UpdateMinimapButtonDrag()
    local button = PE.minimapButton
    if not button then return end
    
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    
    px, py = px / scale, py / scale
    
    local angle = math.deg(math.atan2(py - my, px - mx))
    
    PE.DB.minimap.angle = angle
    PE:UpdateMinimapButtonPosition()
end

function PE:SaveMinimapButtonPosition()
    -- Position is saved in DB during drag
end

function PE:ShowMinimapButton()
    if not self.minimapButton then
        self:CreateMinimapButton()
    end
    self.minimapButton:Show()
end

function PE:HideMinimapButton()
    if self.minimapButton then
        self.minimapButton:Hide()
    end
end

function PE:ToggleMinimapButton()
    if not self.minimapButton then
        self:CreateMinimapButton()
    end
    
    if self.minimapButton:IsShown() then
        self:HideMinimapButton()
        PE.DB.minimap.hide = true
    else
        self:ShowMinimapButton()
        PE.DB.minimap.hide = false
    end
end
