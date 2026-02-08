-- ============================================================================
-- PeralexEnemies - Config.lua
-- Configuration UI with PeralexDebuffs-inspired dark modern design
-- ============================================================================

local PE = _G.PeralexBG

-- Color palette (PeralexDebuffs-inspired)
local COLORS = {
    BACKGROUND_DARK = {0.05, 0.05, 0.05, 0.95},
    BACKGROUND_MEDIUM = {0.08, 0.08, 0.08, 0.9},
    BACKGROUND_LIGHT = {0.12, 0.12, 0.12, 0.85},
    BORDER_DARK = {0.15, 0.15, 0.15, 1},
    BORDER_LIGHT = {0.25, 0.25, 0.25, 1},
    ACCENT_PURPLE = {0.6, 0.2, 0.8, 1},
    ACCENT_PINK = {0.55, 0.27, 0.68, 1},
    TEXT_PRIMARY = {0.9, 0.9, 0.9, 1},
    TEXT_SECONDARY = {0.7, 0.7, 0.7, 1},
    BUTTON_NORMAL = {0.1, 0.1, 0.1, 0.9},
    BUTTON_HOVER = {0.15, 0.15, 0.15, 0.95},
    BUTTON_ACTIVE = {0.2, 0.1, 0.25, 0.9},
    SLIDER_BG = {0.08, 0.08, 0.08, 1},
    SLIDER_FILL = {0.55, 0.27, 0.68, 1},
}

local currentPanel = "General"

-- ============================================================================
-- CUSTOM SCROLLBAR STYLING
-- ============================================================================

function PE:StyleCustomScrollBar(scrollFrame)
    if not scrollFrame then return end
    
    local function ApplyStyling()
        if not scrollFrame or not scrollFrame:GetName() then return end
        
        local scrollBar = scrollFrame.ScrollBar or _G[scrollFrame:GetName().."ScrollBar"]
        if not scrollBar then return end
        
        -- Style scrollbar track
        local thumb = scrollBar:GetThumbTexture()
        if thumb then
            thumb:SetColorTexture(0.5, 0.3, 0.6, 0.8)
            thumb:SetSize(12, 30)
        end
        
        -- Get the scroll buttons
        local upButton = scrollBar.ScrollUpButton or _G[scrollFrame:GetName().."ScrollBarScrollUpButton"]
        local downButton = scrollBar.ScrollDownButton or _G[scrollFrame:GetName().."ScrollBarScrollDownButton"]
        
        if upButton then
            -- Hide Blizzard textures
            if upButton.Normal then upButton.Normal:Hide() end
            if upButton.Pushed then upButton.Pushed:Hide() end
            if upButton.Disabled then upButton.Disabled:Hide() end
            if upButton.Highlight then upButton.Highlight:Hide() end
            pcall(function() upButton:SetNormalTexture("") end)
            pcall(function() upButton:SetPushedTexture("") end)
            pcall(function() upButton:SetHighlightTexture("") end)
            pcall(function() upButton:SetDisabledTexture("") end)
            
            -- Hide all regions except our custom icon
            for _, region in pairs({upButton:GetRegions()}) do
                if region and region ~= upButton.peIcon then
                    if region.Hide then region:Hide() end
                    if region.SetAlpha then region:SetAlpha(0) end
                end
            end
            
            -- Add BackdropTemplate mixin if needed
            if not upButton.SetBackdrop then
                Mixin(upButton, BackdropTemplateMixin)
            end
            
            upButton:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            upButton:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            upButton:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            -- Create custom arrow icon only once
            if not upButton.peIcon then
                local upIcon = upButton:CreateTexture(nil, "OVERLAY")
                upIcon:SetSize(16, 16)
                upIcon:SetPoint("CENTER", 0, 0)
                upIcon:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\dropdown-arrow-purple.tga")
                upIcon:SetVertexColor(0.8, 0.8, 0.8, 1)
                upIcon:SetRotation(math.rad(180))
                upIcon:SetDrawLayer("OVERLAY", 7)
                upButton.peIcon = upIcon
                
                -- Hover effects
                upButton:HookScript("OnEnter", function(self)
                    if self.peIcon then self.peIcon:SetVertexColor(0.55, 0.27, 0.68, 1) end
                end)
                upButton:HookScript("OnLeave", function(self)
                    if self.peIcon then self.peIcon:SetVertexColor(0.8, 0.8, 0.8, 1) end
                end)
            end
            
            if upButton.peIcon then
                upButton.peIcon:Show()
                upButton.peIcon:SetAlpha(1)
            end
        end
        
        if downButton then
            -- Hide Blizzard textures
            if downButton.Normal then downButton.Normal:Hide() end
            if downButton.Pushed then downButton.Pushed:Hide() end
            if downButton.Disabled then downButton.Disabled:Hide() end
            if downButton.Highlight then downButton.Highlight:Hide() end
            pcall(function() downButton:SetNormalTexture("") end)
            pcall(function() downButton:SetPushedTexture("") end)
            pcall(function() downButton:SetHighlightTexture("") end)
            pcall(function() downButton:SetDisabledTexture("") end)
            
            -- Hide all regions except our custom icon
            for _, region in pairs({downButton:GetRegions()}) do
                if region and region ~= downButton.peIcon then
                    if region.Hide then region:Hide() end
                    if region.SetAlpha then region:SetAlpha(0) end
                end
            end
            
            -- Add BackdropTemplate mixin if needed
            if not downButton.SetBackdrop then
                Mixin(downButton, BackdropTemplateMixin)
            end
            
            downButton:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            downButton:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            downButton:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            -- Create custom arrow icon only once
            if not downButton.peIcon then
                local downIcon = downButton:CreateTexture(nil, "OVERLAY")
                downIcon:SetSize(16, 16)
                downIcon:SetPoint("CENTER", 0, 0)
                downIcon:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\dropdown-arrow-purple.tga")
                downIcon:SetVertexColor(0.8, 0.8, 0.8, 1)
                downIcon:SetDrawLayer("OVERLAY", 7)
                downButton.peIcon = downIcon
                
                -- Hover effects
                downButton:HookScript("OnEnter", function(self)
                    if self.peIcon then self.peIcon:SetVertexColor(0.55, 0.27, 0.68, 1) end
                end)
                downButton:HookScript("OnLeave", function(self)
                    if self.peIcon then self.peIcon:SetVertexColor(0.8, 0.8, 0.8, 1) end
                end)
            end
            
            if downButton.peIcon then
                downButton.peIcon:Show()
                downButton.peIcon:SetAlpha(1)
            end
        end
    end
    
    -- Apply styling immediately and with delays to catch Blizzard overrides
    ApplyStyling()
    C_Timer.After(0.05, ApplyStyling)
    C_Timer.After(0.1, ApplyStyling)
    C_Timer.After(0.25, ApplyStyling)
end

-- ============================================================================
-- MAIN CONFIG FRAME
-- ============================================================================

function PE:OpenConfig()
    if self.ConfigFrame then
        self.ConfigFrame:Show()
        return
    end
    
    self:CreateConfigFrame()
end

function PE:CreateConfigFrame()
    local frame = CreateFrame("Frame", "PeralexBGConfig", UIParent, "BackdropTemplate")
    frame:SetSize(600, 550) -- Increased height from 450 to 550
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    frame:SetBackdropColor(unpack(COLORS.BACKGROUND_DARK))
    frame:SetBackdropBorderColor(unpack(COLORS.BORDER_LIGHT))
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(s) s:StartMoving() end)
    frame:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)
    
    self.ConfigFrame = frame
    
    -- Gradient background
    local gradient = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    gradient:SetAllPoints()
    gradient:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    gradient:SetGradient("VERTICAL", CreateColor(0.08, 0.08, 0.08, 0.8), CreateColor(0.03, 0.03, 0.03, 0.9))
    
    -- Title bar
    self:CreateTitleBar(frame)
    
    -- Sidebar
    self:CreateSidebar(frame)
    
    -- Content area
    self:CreateContentArea(frame)
    
    -- Bottom bar
    self:CreateBottomBar(frame)
    
    -- Show initial panel
    self:ShowPanel("General")
    
    -- ESC to close
    tinsert(UISpecialFrames, "PeralexBGConfig")
end

-- ============================================================================
-- TITLE BAR
-- ============================================================================

function PE:CreateTitleBar(parent)
    local titleBar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    titleBar:SetSize(596, 45)
    titleBar:SetPoint("TOP", 0, -2)
    titleBar:SetFrameLevel(parent:GetFrameLevel() + 1)
    titleBar:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32})
    titleBar:SetBackdropColor(unpack(COLORS.BACKGROUND_MEDIUM))
    
    -- Purple accent line at top
    local accent = titleBar:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)
    accent:SetTexture("Interface\\Buttons\\WHITE8x8")
    accent:SetVertexColor(unpack(COLORS.ACCENT_PURPLE))
    
    -- Title
    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 18, "OUTLINE")
    title:SetPoint("CENTER", 0, 5)
    title:SetText("PERALEX BG")
    title:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
    
    -- Subtitle
    local subtitle = titleBar:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(PE:GetFont(), 11, "")
    subtitle:SetPoint("CENTER", 0, -10)
    subtitle:SetText("Battleground Enemy Frames & Tweaks")
    subtitle:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", -8, -10)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    closeBtn:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
    closeBtn:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
    
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(PE:GetFont(), 14, "OUTLINE")
    closeText:SetPoint("CENTER", 0, 1)
    closeText:SetText("X")
    closeText:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    
    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_HOVER))
        closeText:SetTextColor(1, 0.3, 0.3)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
        closeText:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    end)
    closeBtn:SetScript("OnClick", function() 
        parent:Hide() 
    end)
    
    -- Auto-exit test modes when config is closed
    parent:SetScript("OnHide", function()
        if PE.states.isTestMode then
            PE:ExitTestMode()
        end
        if PE.states.isEpicBGTestMode then
            PE:ExitEpicBGTestMode()
        end
    end)
    
    -- MIDNIGHT NOTICE button (ArenaCore style - purple with alert icon)
    local midnightBtn = CreateFrame("Button", nil, titleBar)
    midnightBtn:SetSize(130, 26)
    midnightBtn:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 10, -10)
    
    -- Background (purple gradient)
    local midnightBg = midnightBtn:CreateTexture(nil, "BACKGROUND")
    midnightBg:SetAllPoints()
    midnightBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- ArenaCore PRIMARY purple
    
    -- Border (darker for depth)
    local midnightBorder = midnightBtn:CreateTexture(nil, "BORDER")
    midnightBorder:SetPoint("TOPLEFT", 1, -1)
    midnightBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    midnightBorder:SetColorTexture(0.4, 0.2, 0.7, 1)
    
    -- Alert icon (Crosshair_Important_128)
    local alertIcon = midnightBtn:CreateTexture(nil, "OVERLAY")
    alertIcon:SetAtlas("Crosshair_Important_128")
    alertIcon:SetSize(20, 20)
    alertIcon:SetPoint("LEFT", midnightBtn, "LEFT", 6, 0)
    
    -- Text
    local midnightText = midnightBtn:CreateFontString(nil, "OVERLAY")
    midnightText:SetFont(PE:GetFont(), 9, "")
    midnightText:SetText("MIDNIGHT NOTICE")
    midnightText:SetTextColor(1, 1, 1, 1)
    midnightText:SetPoint("LEFT", alertIcon, "RIGHT", 4, 0)
    
    -- Hover effect
    midnightBtn:SetScript("OnEnter", function()
        midnightBg:SetColorTexture(0.645, 0.371, 1.000, 1) -- Lighter purple
    end)
    midnightBtn:SetScript("OnLeave", function()
        midnightBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- Original purple
    end)
    
    -- Click handler
    midnightBtn:SetScript("OnClick", function()
        PE:ShowMidnightNoticeWindow()
    end)
    
    -- CHANGELOG button (ArenaCore style - purple with info icon) - FAR RIGHT
    local changelogBtn = CreateFrame("Button", nil, titleBar)
    changelogBtn:SetSize(100, 26)
    changelogBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -40, -10)
    
    -- Background (purple gradient)
    local changelogBg = changelogBtn:CreateTexture(nil, "BACKGROUND")
    changelogBg:SetAllPoints()
    changelogBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- ArenaCore PRIMARY purple
    
    -- Border (darker for depth)
    local changelogBorder = changelogBtn:CreateTexture(nil, "BORDER")
    changelogBorder:SetPoint("TOPLEFT", 1, -1)
    changelogBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    changelogBorder:SetColorTexture(0.4, 0.2, 0.7, 1)
    
    -- Info icon (Common-Icon-Small)
    local infoIcon = changelogBtn:CreateTexture(nil, "OVERLAY")
    infoIcon:SetAtlas("Common-Icon-Small")
    infoIcon:SetSize(20, 20)
    infoIcon:SetPoint("LEFT", changelogBtn, "LEFT", 6, 0)
    
    -- Text
    local changelogText = changelogBtn:CreateFontString(nil, "OVERLAY")
    changelogText:SetFont(PE:GetFont(), 9, "")
    changelogText:SetText("Changelog")
    changelogText:SetTextColor(1, 1, 1, 1)
    changelogText:SetPoint("CENTER", changelogBtn, "CENTER", 0, 0)
    
    -- Hover effect
    changelogBtn:SetScript("OnEnter", function()
        changelogBg:SetColorTexture(0.645, 0.371, 1.000, 1) -- Lighter purple
    end)
    changelogBtn:SetScript("OnLeave", function()
        changelogBg:SetColorTexture(0.545, 0.271, 1.000, 1) -- Original purple
    end)
    
    -- Click handler
    changelogBtn:SetScript("OnClick", function()
        PE:ShowChangelogWindow()
    end)
end

-- ============================================================================
-- SIDEBAR
-- ============================================================================

function PE:CreateSidebar(parent)
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetSize(140, 440) -- Increased height from 340 to 440
    sidebar:SetPoint("TOPLEFT", 10, -55)
    sidebar:SetFrameLevel(parent:GetFrameLevel() + 1)
    sidebar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    sidebar:SetBackdropColor(unpack(COLORS.BACKGROUND_MEDIUM))
    sidebar:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
    
    self.sidebar = sidebar
    self.navButtons = {}
    
    local buttons = {
        {text = "General", panel = "General"},
        {text = "Appearance", panel = "Appearance"},
        {text = "Trinkets+More", panel = "Trinkets"},
        {text = "Position", panel = "Position"},
        {text = "Skin Mods", panel = "SkinMods"},
    }
    
    for i, data in ipairs(buttons) do
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(120, 32)
        btn:SetPoint("TOP", 0, -10 - (i * 36))
        btn:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
        btn:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
        
        -- Create 4-edge glow lines for hover effect (like Shade)
        local topGlow = btn:CreateTexture(nil, "OVERLAY", nil, 7)
        topGlow:SetHeight(1)
        topGlow:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        topGlow:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        topGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
        topGlow:SetDrawLayer("OVERLAY", 7)
        if topGlow.SetSnapToPixelGrid then
            topGlow:SetTexelSnappingBias(0)
            topGlow:SetSnapToPixelGrid(false)
        end
        topGlow:Hide()
        
        local bottomGlow = btn:CreateTexture(nil, "OVERLAY", nil, 7)
        bottomGlow:SetHeight(1)
        bottomGlow:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        bottomGlow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        bottomGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
        bottomGlow:SetDrawLayer("OVERLAY", 7)
        if bottomGlow.SetSnapToPixelGrid then
            bottomGlow:SetTexelSnappingBias(0)
            bottomGlow:SetSnapToPixelGrid(false)
        end
        bottomGlow:Hide()
        
        local leftGlow = btn:CreateTexture(nil, "OVERLAY", nil, 7)
        leftGlow:SetWidth(1)
        leftGlow:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        leftGlow:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        leftGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
        leftGlow:SetDrawLayer("OVERLAY", 7)
        if leftGlow.SetSnapToPixelGrid then
            leftGlow:SetTexelSnappingBias(0)
            leftGlow:SetSnapToPixelGrid(false)
        end
        leftGlow:Hide()
        
        local rightGlow = btn:CreateTexture(nil, "OVERLAY", nil, 7)
        rightGlow:SetWidth(1)
        rightGlow:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        rightGlow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        rightGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
        rightGlow:SetDrawLayer("OVERLAY", 7)
        if rightGlow.SetSnapToPixelGrid then
            rightGlow:SetTexelSnappingBias(0)
            rightGlow:SetSnapToPixelGrid(false)
        end
        rightGlow:Hide()
        
        btn.glowLines = {topGlow, bottomGlow, leftGlow, rightGlow}
        
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont(PE:GetFont(), 12, "")
        fs:SetPoint("CENTER", 0, 0)
        fs:SetText(data.text)
        fs:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
        
        btn.fontString = fs
        btn.panelName = data.panel
        
        btn:SetScript("OnEnter", function(self)
            if data.panel ~= currentPanel then
                self:SetBackdropColor(unpack(COLORS.BUTTON_HOVER))
                self:SetBackdropBorderColor(0.8, 0.4, 0.9, 1) -- Purple border glow
                fs:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
                -- Show glow lines
                for _, glowLine in ipairs(self.glowLines) do
                    glowLine:Show()
                end
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if data.panel ~= currentPanel then
                self:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
                self:SetBackdropBorderColor(0, 0, 0, 0) -- Remove border color
                fs:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
                -- Hide glow lines
                for _, glowLine in ipairs(self.glowLines) do
                    glowLine:Hide()
                end
            end
        end)
        btn:SetScript("OnClick", function()
            PE:ShowPanel(data.panel)
        end)
        
        self.navButtons[data.panel] = btn
    end
    
    -- Logo image below buttons
    local logo = sidebar:CreateTexture(nil, "ARTWORK")
    logo:SetSize(130, 130)
    logo:SetPoint("TOP", 0, -276) -- Position below the Skin Mods button
    logo:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\peralexbgicon.tga")
    logo:SetTexCoord(0, 1, 0, 1)
    logo:SetAlpha(0.8)
end

-- ============================================================================
-- CONTENT AREA
-- ============================================================================

function PE:CreateContentArea(parent)
    local content = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    content:SetPoint("TOPLEFT", 160, -55)
    content:SetPoint("BOTTOMRIGHT", -10, 50)
    content:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    content:SetBackdropColor(unpack(COLORS.BACKGROUND_LIGHT))
    content:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
    
    self.contentArea = content
    self.panels = {}
    
    -- Create panels
    self:CreateGeneralPanel()
    self:CreateAppearancePanel()
    self:CreateTrinketsPanel()
    self:CreatePositionPanel()
    self:CreateSkinModsPanel()
end

-- ============================================================================
-- BOTTOM BAR
-- ============================================================================

function PE:CreateBottomBar(parent)
    local bottomBar = CreateFrame("Frame", nil, parent)
    bottomBar:SetPoint("BOTTOMLEFT", 10, 10)
    bottomBar:SetPoint("BOTTOMRIGHT", -10, 10)
    bottomBar:SetHeight(35)
    
    -- Test Mode button
    local testBtn = self:CreateButton(bottomBar, "Test Mode", 85, 28)
    testBtn:SetPoint("LEFT", 0, 0)
    testBtn:SetScript("OnClick", function()
        PE:ToggleTestMode()
    end)
    
    -- Epic BG Test Mode button
    local epicTestBtn = self:CreateButton(bottomBar, "Epic BG Test", 90, 28)
    epicTestBtn:SetPoint("LEFT", testBtn, "RIGHT", 5, 0)
    epicTestBtn:SetScript("OnClick", function()
        PE:ToggleEpicBGTestMode()
    end)
    
    -- Enemy Frames Anchor button (manual toggle for testing - separate from BG-only showAnchor setting)
    local enemyAnchorBtn = self:CreateButton(bottomBar, "Show Anchor", 90, 28)
    enemyAnchorBtn:SetPoint("LEFT", epicTestBtn, "RIGHT", 5, 0)
    enemyAnchorBtn:SetScript("OnClick", function()
        local isShown = PE:ToggleEnemyAnchor()
        PE:Print("Anchor " .. (isShown and "shown" or "hidden"))
    end)
    
    -- Discord button
    local discordBtn = self:CreateButton(bottomBar, "Discord", 80, 28)
    discordBtn:SetPoint("RIGHT", 0, 0)
    discordBtn:SetScript("OnClick", function()
        PE:ShowDiscordPopup()
    end)
end

-- ============================================================================
-- PANELS
-- ============================================================================

function PE:CreateGeneralPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    panel:Hide()
    self.panels["General"] = panel
    
    -- Sub-tab system (Shade-style)
    local activeSubTab = "general"
    local subTabs = {}
    local subContentFrames = {}
    
    -- TAB BAR at the top
    local tabBar = CreateFrame("Frame", nil, panel)
    tabBar:SetSize(400, 30)
    tabBar:SetPoint("TOP", 0, -10)
    
    local tabNames = {
        {key = "general", label = "General"},
        {key = "epicbg", label = "Epic BG"},
    }
    
    -- Create tab buttons
    for i, tabInfo in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        tab:SetSize(120, 28)
        tab:SetPoint("LEFT", (i-1) * 125, 0)
        
        tab:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        
        local text = tab:CreateFontString(nil, "OVERLAY")
        text:SetFont(PE:GetFont(), 11, "")
        text:SetPoint("CENTER")
        text:SetText(tabInfo.label)
        
        tab.key = tabInfo.key
        tab.text = text
        subTabs[tabInfo.key] = tab
        
        -- Create 4-edge glow lines (purple highlight)
        local topGlow = tab:CreateTexture(nil, "OVERLAY", nil, 7)
        topGlow:SetHeight(1)
        topGlow:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
        topGlow:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 0, 0)
        topGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
        topGlow:SetDrawLayer("OVERLAY", 7)
        topGlow:Hide()
        
        local bottomGlow = tab:CreateTexture(nil, "OVERLAY", nil, 7)
        bottomGlow:SetHeight(1)
        bottomGlow:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        bottomGlow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        bottomGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
        bottomGlow:SetDrawLayer("OVERLAY", 7)
        bottomGlow:Hide()
        
        local leftGlow = tab:CreateTexture(nil, "OVERLAY", nil, 7)
        leftGlow:SetWidth(1)
        leftGlow:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
        leftGlow:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        leftGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
        leftGlow:SetDrawLayer("OVERLAY", 7)
        leftGlow:Hide()
        
        local rightGlow = tab:CreateTexture(nil, "OVERLAY", nil, 7)
        rightGlow:SetWidth(1)
        rightGlow:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 0, 0)
        rightGlow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        rightGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
        rightGlow:SetDrawLayer("OVERLAY", 7)
        rightGlow:Hide()
        
        tab.glowLines = {topGlow, bottomGlow, leftGlow, rightGlow}
        
        -- Hover effects
        tab:SetScript("OnEnter", function(self)
            if self.key == activeSubTab then return end
            self:SetBackdropColor(0.4, 0.15, 0.5, 0.8)
            self:SetBackdropBorderColor(0.8, 0.4, 0.9, 1)
            self.text:SetTextColor(1, 1, 1, 1)
            for _, glowLine in ipairs(self.glowLines) do
                glowLine:Show()
            end
        end)
        
        tab:SetScript("OnLeave", function(self)
            if self.key == activeSubTab then return end
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            self.text:SetTextColor(0.7, 0.7, 0.7, 1)
            for _, glowLine in ipairs(self.glowLines) do
                glowLine:Hide()
            end
        end)
        
        tab:SetScript("OnClick", function(self)
            activeSubTab = self.key
            
            -- Update all tab visuals
            for k, t in pairs(subTabs) do
                if k == activeSubTab then
                    t:SetBackdropColor(unpack(COLORS.BUTTON_ACTIVE))
                    t:SetBackdropBorderColor(0.8, 0.4, 0.9, 1)
                    t.text:SetTextColor(1, 1, 1, 1)
                    for _, glowLine in ipairs(t.glowLines) do
                        glowLine:Show()
                    end
                    if subContentFrames[k] then subContentFrames[k]:Show() end
                else
                    t:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
                    t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                    t.text:SetTextColor(0.7, 0.7, 0.7, 1)
                    for _, glowLine in ipairs(t.glowLines) do
                        glowLine:Hide()
                    end
                    if subContentFrames[k] then subContentFrames[k]:Hide() end
                end
            end
        end)
        
        -- Set initial state
        if i == 1 then
            tab:SetBackdropColor(unpack(COLORS.BUTTON_ACTIVE))
            tab:SetBackdropBorderColor(0.8, 0.4, 0.9, 1)
            text:SetTextColor(1, 1, 1, 1)
            for _, glowLine in ipairs(tab.glowLines) do
                glowLine:Show()
            end
        else
            tab:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            text:SetTextColor(0.7, 0.7, 0.7, 1)
        end
    end
    
    -- ============================================================================
    -- GENERAL SUB-TAB CONTENT
    -- ============================================================================
    local generalContent = CreateFrame("Frame", nil, panel)
    generalContent:SetPoint("TOPLEFT", 0, -50)
    generalContent:SetPoint("BOTTOMRIGHT", 0, 0)
    subContentFrames["general"] = generalContent
    
    local yOffset = -10
    
    -- Title
    local title = generalContent:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 14, "OUTLINE")
    title:SetPoint("TOPLEFT", 15, yOffset)
    title:SetText("General Settings")
    title:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    yOffset = yOffset - 35
    
    -- Max Frames slider
    self:CreateSlider(generalContent, "Max Enemy Frames", 15, yOffset, 1, 40, 1, 
        function() return PE.DB.frames.maxFrames end,
        function(value) PE.DB.frames.maxFrames = value end
    )
    
    yOffset = yOffset - 50
    
    -- Frame Width slider
    self:CreateSlider(generalContent, "Frame Width", 15, yOffset, 100, 300, 5,
        function() return PE.DB.frames.width end,
        function(value) 
            PE.DB.frames.width = value
            PE:UpdateFrameSizes()
        end
    )
    
    yOffset = yOffset - 50
    
    -- Frame Height slider
    self:CreateSlider(generalContent, "Frame Height", 15, yOffset, 20, 60, 2,
        function() return PE.DB.frames.height end,
        function(value)
            PE.DB.frames.height = value
            PE:UpdateFrameSizes()
        end
    )
    
    yOffset = yOffset - 50
    
    -- Spacing slider
    self:CreateSlider(generalContent, "Frame Spacing", 15, yOffset, 0, 20, 1,
        function() return PE.DB.frames.spacing end,
        function(value)
            PE.DB.frames.spacing = value
            PE:UpdateFrames()
        end
    )
    
    yOffset = yOffset - 50
    
    -- Focus Behavior Dropdown
    self:CreateDropdown(generalContent, "Right-Click Focus Behavior", 15, yOffset,
        function()
            return {"Focus + Target Player", "Focus + Restore Last Target"}
        end,
        function()
            local behavior = PE.DB.targeting.focusBehavior or "both"
            return behavior == "both" and 1 or 2
        end,
        function(index)
            PE.DB.targeting.focusBehavior = index == 1 and "both" or "restore"
            PE:UpdateAllFrameMacros()
        end
    )
    
    yOffset = yOffset - 50
    
    -- Show Minimap Icon checkbox
    self:CreateCheckbox(generalContent, "Show Minimap Icon", 15, yOffset,
        function() return not PE.DB.minimap.hide end,
        function(value)
            PE.DB.minimap.hide = not value
            if value then
                if not PE.minimapButton then
                    PE:CreateMinimapButton()
                else
                    PE.minimapButton:Show()
                end
            else
                if PE.minimapButton then
                    PE.minimapButton:Hide()
                end
            end
        end
    )
    
    -- ============================================================================
    -- EPIC BG SUB-TAB CONTENT
    -- ============================================================================
    local epicBGContent = CreateFrame("Frame", nil, panel)
    epicBGContent:SetPoint("TOPLEFT", 0, -50)
    epicBGContent:SetPoint("BOTTOMRIGHT", 0, 0)
    epicBGContent:Hide()
    subContentFrames["epicbg"] = epicBGContent
    
    -- Create scroll frame for Epic BG content
    local epicScrollFrame = CreateFrame("ScrollFrame", "PeralexBGEpicBGScrollFrame", epicBGContent, "UIPanelScrollFrameTemplate")
    epicScrollFrame:SetPoint("TOPLEFT", 5, -5)
    epicScrollFrame:SetPoint("BOTTOMRIGHT", -28, 5)
    
    self:StyleCustomScrollBar(epicScrollFrame)
    
    local epicScrollChild = CreateFrame("Frame", nil, epicScrollFrame)
    epicScrollChild:SetSize(380, 1400)
    epicScrollFrame:SetScrollChild(epicScrollChild)
    
    epicScrollFrame:EnableMouseWheel(true)
    epicScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local bar = self.ScrollBar or _G["PeralexBGEpicBGScrollFrameScrollBar"]
        if bar and bar:IsShown() then
            local current = bar:GetValue()
            local minVal, maxVal = bar:GetMinMaxValues()
            local step = (maxVal - minVal) / 10
            local newVal = current - (delta * step)
            newVal = math.max(minVal, math.min(maxVal, newVal))
            bar:SetValue(newVal)
        end
    end)
    
    local epicYOffset = -10
    
    -- Title
    local epicTitle = epicScrollChild:CreateFontString(nil, "OVERLAY")
    epicTitle:SetFont(PE:GetFont(), 14, "OUTLINE")
    epicTitle:SetPoint("TOPLEFT", 15, epicYOffset)
    epicTitle:SetText("Epic Battleground Settings")
    epicTitle:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    epicYOffset = epicYOffset - 35
    
    -- Enable Epic BG Frames checkbox
    self:CreateCheckbox(epicScrollChild, "Show Frames in Epic BGs (40-man)", 15, epicYOffset,
        function() return PE.DB.frames.enableEpicBGFrames end,
        function(value)
            PE.DB.frames.enableEpicBGFrames = value
            -- If in Epic BG test mode, update frames
            if PE.states.isEpicBGTestMode then
                if value then
                    PE:UpdateEpicBGFrames()
                else
                    PE:HideAllEpicBGFrames()
                end
            end
        end
    )
    
    epicYOffset = epicYOffset - 25
    
    -- Info text for Epic BG setting
    local epicInfo = epicScrollChild:CreateFontString(nil, "OVERLAY")
    epicInfo:SetFont(PE:GetFont(), 9, "")
    epicInfo:SetPoint("TOPLEFT", 35, epicYOffset)
    epicInfo:SetText("When disabled, enemy frames are hidden in Epic BGs.")
    epicInfo:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    epicInfo:SetJustifyH("LEFT")
    
    epicYOffset = epicYOffset - 40
    
    -- Frame Grouping section header
    local groupHeader = epicScrollChild:CreateFontString(nil, "OVERLAY")
    groupHeader:SetFont(PE:GetFont(), 12, "OUTLINE")
    groupHeader:SetPoint("TOPLEFT", 15, epicYOffset)
    groupHeader:SetText("Frame Grouping Mode")
    groupHeader:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    epicYOffset = epicYOffset - 25
    
    -- Store references for mode-specific panels
    local modeSettingsPanels = {}
    
    -- Group Mode Dropdown
    self:CreateDropdown(epicScrollChild, "Grouping Layout", 15, epicYOffset,
        function()
            return {"All 40 (Single Column)", "10 Per Group (4 Groups)", "20 Per Group (2 Groups)"}
        end,
        function()
            local mode = PE.DB.epicBG and PE.DB.epicBG.groupMode or "all"
            if mode == "ten" then return 2
            elseif mode == "twenty" then return 3
            else return 1
            end
        end,
        function(index)
            if not PE.DB.epicBG then PE.DB.epicBG = {} end
            local modes = {"all", "ten", "twenty"}
            PE.DB.epicBG.groupMode = modes[index]
            
            -- Show only the panel for the selected mode
            for modeKey, panel in pairs(modeSettingsPanels) do
                if modeKey == modes[index] then
                    panel:Show()
                else
                    panel:Hide()
                end
            end
            
            -- Regenerate Epic BG frames if in test mode (full rebuild needed for mode change)
            if PE.states.isEpicBGTestMode then
                PE:RegenerateEpicBGFrames()
            end
        end
    )
    
    epicYOffset = epicYOffset - 55
    
    -- Show Group Anchors button
    local showAnchorsBtn = self:CreateButton(epicScrollChild, "Show Anchors", 110, 28)
    showAnchorsBtn:SetPoint("TOPLEFT", 15, epicYOffset)
    showAnchorsBtn:SetScript("OnClick", function()
        PE:ShowEpicBGAnchors()
        PE:Print("Epic BG anchors shown")
    end)
    
    -- Hide Group Anchors button
    local hideAnchorsBtn = self:CreateButton(epicScrollChild, "Hide Anchors", 110, 28)
    hideAnchorsBtn:SetPoint("LEFT", showAnchorsBtn, "RIGHT", 10, 0)
    hideAnchorsBtn:SetScript("OnClick", function()
        PE:HideEpicBGAnchors()
        PE:Print("Epic BG anchors hidden")
    end)
    
    epicYOffset = epicYOffset - 45
    
    -- ============================================================================
    -- ALL 40 MODE SETTINGS PANEL
    -- ============================================================================
    local allModePanel = CreateFrame("Frame", nil, epicScrollChild, "BackdropTemplate")
    allModePanel:SetSize(360, 142)
    allModePanel:SetPoint("TOPLEFT", 10, epicYOffset)
    allModePanel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    allModePanel:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    allModePanel:SetBackdropBorderColor(0.4, 0.2, 0.6, 1)
    modeSettingsPanels["all"] = allModePanel
    
    local allTitle = allModePanel:CreateFontString(nil, "OVERLAY")
    allTitle:SetFont(PE:GetFont(), 11, "OUTLINE")
    allTitle:SetPoint("TOPLEFT", 10, -8)
    allTitle:SetText("All 40 (Single Column) Settings")
    allTitle:SetTextColor(0.8, 0.6, 0.9)
    
    local allY = -28
    
    self:CreateCompactSliderWithInput(allModePanel, "Width", 10, allY, 80, 300, 5,
        function() return PE.DB.epicBG.allMode.width or 180 end,
        function(value)
            PE.DB.epicBG.allMode.width = value
            if PE.states.isEpicBGTestMode then PE:UpdateEpicBGFrames() end
        end
    )
    allY = allY - 38
    
    self:CreateCompactSliderWithInput(allModePanel, "Height", 10, allY, 16, 60, 2,
        function() return PE.DB.epicBG.allMode.height or 32 end,
        function(value)
            PE.DB.epicBG.allMode.height = value
            if PE.states.isEpicBGTestMode then PE:UpdateEpicBGFrames() end
        end
    )
    allY = allY - 38
    
    self:CreateCompactSliderWithInput(allModePanel, "Spacing", 10, allY, 0, 10, 1,
        function() return PE.DB.epicBG.allMode.spacing or 2 end,
        function(value)
            PE.DB.epicBG.allMode.spacing = value
            if PE.states.isEpicBGTestMode then PE:UpdateEpicBGFrames() end
        end
    )
    
    -- ============================================================================
    -- 10 PER GROUP (4 GROUPS) MODE SETTINGS PANEL
    -- ============================================================================
    local tenModePanel = CreateFrame("Frame", nil, epicScrollChild, "BackdropTemplate")
    tenModePanel:SetSize(360, 530)
    tenModePanel:SetPoint("TOPLEFT", 10, epicYOffset)
    tenModePanel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    tenModePanel:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    tenModePanel:SetBackdropBorderColor(0.4, 0.2, 0.6, 1)
    tenModePanel:Hide()
    modeSettingsPanels["ten"] = tenModePanel
    
    local tenTitle = tenModePanel:CreateFontString(nil, "OVERLAY")
    tenTitle:SetFont(PE:GetFont(), 11, "OUTLINE")
    tenTitle:SetPoint("TOPLEFT", 10, -8)
    tenTitle:SetText("10 Per Group (4 Groups) Settings")
    tenTitle:SetTextColor(0.8, 0.6, 0.9)
    
    local tenY = -28
    
    -- Create settings for each of the 4 groups
    for groupIndex = 1, 4 do
        local groupLabel = tenModePanel:CreateFontString(nil, "OVERLAY")
        groupLabel:SetFont(PE:GetFont(), 10, "OUTLINE")
        groupLabel:SetPoint("TOPLEFT", 10, tenY)
        groupLabel:SetText("Peralex BG Group " .. groupIndex)
        groupLabel:SetTextColor(0.6, 0.8, 0.6)
        
        tenY = tenY - 18
        
        self:CreateCompactSliderWithInput(tenModePanel, "Width", 10, tenY, 80, 300, 5,
            function() return PE.DB.epicBG.tenMode.groups[groupIndex].width or 200 end,
            function(value)
                PE.DB.epicBG.tenMode.groups[groupIndex].width = value
                if PE.states.isEpicBGTestMode then PE:UpdateEpicBGFrames() end
            end
        )
        tenY = tenY - 34
        
        self:CreateCompactSliderWithInput(tenModePanel, "Height", 10, tenY, 16, 60, 2,
            function() return PE.DB.epicBG.tenMode.groups[groupIndex].height or 40 end,
            function(value)
                PE.DB.epicBG.tenMode.groups[groupIndex].height = value
                if PE.states.isEpicBGTestMode then PE:UpdateEpicBGFrames() end
            end
        )
        tenY = tenY - 34
        
        self:CreateCompactSliderWithInput(tenModePanel, "Spacing", 10, tenY, 0, 10, 1,
            function() return PE.DB.epicBG.tenMode.groups[groupIndex].spacing or 3 end,
            function(value)
                PE.DB.epicBG.tenMode.groups[groupIndex].spacing = value
                if PE.states.isEpicBGTestMode then PE:UpdateEpicBGFrames() end
            end
        )
        tenY = tenY - 38
    end
    
    -- ============================================================================
    -- 20 PER GROUP (2 GROUPS) MODE SETTINGS PANEL
    -- ============================================================================
    local twentyModePanel = CreateFrame("Frame", nil, epicScrollChild, "BackdropTemplate")
    twentyModePanel:SetSize(360, 272)
    twentyModePanel:SetPoint("TOPLEFT", 10, epicYOffset)
    twentyModePanel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    twentyModePanel:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    twentyModePanel:SetBackdropBorderColor(0.4, 0.2, 0.6, 1)
    twentyModePanel:Hide()
    modeSettingsPanels["twenty"] = twentyModePanel
    
    local twentyTitle = twentyModePanel:CreateFontString(nil, "OVERLAY")
    twentyTitle:SetFont(PE:GetFont(), 11, "OUTLINE")
    twentyTitle:SetPoint("TOPLEFT", 10, -8)
    twentyTitle:SetText("20 Per Group (2 Groups) Settings")
    twentyTitle:SetTextColor(0.8, 0.6, 0.9)
    
    local twentyY = -28
    
    -- Create settings for each of the 2 groups
    for groupIndex = 1, 2 do
        local groupLabel = twentyModePanel:CreateFontString(nil, "OVERLAY")
        groupLabel:SetFont(PE:GetFont(), 10, "OUTLINE")
        groupLabel:SetPoint("TOPLEFT", 10, twentyY)
        groupLabel:SetText("Peralex BG Group " .. groupIndex)
        groupLabel:SetTextColor(0.6, 0.8, 0.6)
        
        twentyY = twentyY - 18
        
        self:CreateCompactSliderWithInput(twentyModePanel, "Width", 10, twentyY, 80, 300, 5,
            function() return PE.DB.epicBG.twentyMode.groups[groupIndex].width or 200 end,
            function(value)
                PE.DB.epicBG.twentyMode.groups[groupIndex].width = value
                if PE.states.isEpicBGTestMode then PE:UpdateEpicBGFrames() end
            end
        )
        twentyY = twentyY - 34
        
        self:CreateCompactSliderWithInput(twentyModePanel, "Height", 10, twentyY, 16, 60, 2,
            function() return PE.DB.epicBG.twentyMode.groups[groupIndex].height or 40 end,
            function(value)
                PE.DB.epicBG.twentyMode.groups[groupIndex].height = value
                if PE.states.isEpicBGTestMode then PE:UpdateEpicBGFrames() end
            end
        )
        twentyY = twentyY - 34
        
        self:CreateCompactSliderWithInput(twentyModePanel, "Spacing", 10, twentyY, 0, 10, 1,
            function() return PE.DB.epicBG.twentyMode.groups[groupIndex].spacing or 3 end,
            function(value)
                PE.DB.epicBG.twentyMode.groups[groupIndex].spacing = value
                if PE.states.isEpicBGTestMode then PE:UpdateEpicBGFrames() end
            end
        )
        twentyY = twentyY - 38
    end
    
    -- Set initial visibility based on current mode
    local currentMode = PE.DB.epicBG and PE.DB.epicBG.groupMode or "all"
    for modeKey, panel in pairs(modeSettingsPanels) do
        if modeKey == currentMode then
            panel:Show()
        else
            panel:Hide()
        end
    end
end

function PE:CreateAppearancePanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    panel:Hide()
    self.panels["Appearance"] = panel
    
    -- Title (outside scroll area)
    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 14, "OUTLINE")
    title:SetPoint("TOPLEFT", 15, -10)
    title:SetText("Appearance Settings")
    title:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    -- Scroll alert
    local scrollAlert = panel:CreateFontString(nil, "OVERLAY")
    scrollAlert:SetFont(PE:GetFont(), 10, "")
    scrollAlert:SetPoint("LEFT", title, "RIGHT", 15, 0)
    scrollAlert:SetText("Scroll Down For More Settings!")
    scrollAlert:SetTextColor(1, 0.8, 0, 1)
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "PeralexBGAppearanceScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 5)
    
    -- Apply custom scrollbar styling
    self:StyleCustomScrollBar(scrollFrame)
    
    -- Create scroll child for content
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(340, 700) -- Height for all content
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Enable mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local bar = self.ScrollBar or _G["PeralexBGAppearanceScrollFrameScrollBar"]
        if bar and bar:IsShown() then
            local current = bar:GetValue()
            local minVal, maxVal = bar:GetMinMaxValues()
            local step = (maxVal - minVal) / 10
            local newVal = current - (delta * step)
            newVal = math.max(minVal, math.min(maxVal, newVal))
            bar:SetValue(newVal)
        end
    end)
    
    local yOffset = -10
    
    -- Flag settings experimental notice with alert icon
    local flagAlertIcon = scrollChild:CreateTexture(nil, "OVERLAY")
    flagAlertIcon:SetSize(16, 16)
    flagAlertIcon:SetPoint("TOPLEFT", 10, yOffset)
    flagAlertIcon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    flagAlertIcon:SetVertexColor(1, 0.8, 0)
    
    local flagNotice = scrollChild:CreateFontString(nil, "OVERLAY")
    flagNotice:SetFont(PE:GetFont(), 10, "")
    flagNotice:SetPoint("LEFT", flagAlertIcon, "RIGHT", 5, 0)
    flagNotice:SetText("Flag settings are experimental only")
    flagNotice:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 30
    
    -- Show Player Names checkbox
    self:CreateCheckbox(scrollChild, "Show Player Names", 10, yOffset,
        function() return PE.DB.appearance.showPlayerNames end,
        function(value)
            PE.DB.appearance.showPlayerNames = value
            if PE.states.isEpicBG or PE.states.isEpicBGTestMode then
                PE:RefreshEpicBGFrameAppearances()
            else
                PE:UpdateFrames()
            end
        end
    )
    
    -- Prioritize Flag Carrier checkbox (to the right) - DISABLED FOR NOW
    -- self:CreateCheckbox(scrollChild, "Prioritize Flag Carrier", 180, yOffset,
    --     function() return PE.DB.appearance.prioritizeFlagCarrier end,
    --     function(value)
    --         PE.DB.appearance.prioritizeFlagCarrier = value
    --         PE:UpdateFrames()
    --     end
    -- )
    
    yOffset = yOffset - 30
    
    -- Show Enemy Count checkbox (e.g., "15 Horde")
    self:CreateCheckbox(scrollChild, "Show Enemy Count (e.g. 15 Horde)", 10, yOffset,
        function() return PE.DB.appearance.showEnemyCount end,
        function(value)
            PE.DB.appearance.showEnemyCount = value
            PE:UpdateEnemyCountText()
        end
    )
    
    yOffset = yOffset - 30
    
    -- Show Anchor checkbox (Global - shows/hides anchor everywhere)
    self:CreateCheckbox(scrollChild, "Show Anchor Bar", 10, yOffset,
        function() return PE.DB.appearance.showAnchor end,
        function(value)
            PE.DB.appearance.showAnchor = value
            -- Update anchor visibility globally using unified function
            PE:UpdateGlobalAnchorVisibility()
        end
    )
    
    yOffset = yOffset - 30
    
    -- Show Status Text checkbox
    self:CreateCheckbox(scrollChild, "Show Status Text", 10, yOffset,
        function() return PE.DB.appearance.showStatusText end,
        function(value)
            PE.DB.appearance.showStatusText = value
            if PE.states.isEpicBG or PE.states.isEpicBGTestMode then
                PE:RefreshEpicBGFrameAppearances()
            else
                PE:UpdateFrames()
            end
        end
    )
    
    yOffset = yOffset - 30
    
    -- Use Class Color Bars checkbox
    self:CreateCheckbox(scrollChild, "Class Color Bars", 10, yOffset,
        function() return PE.DB.appearance.useClassColors end,
        function(value)
            PE.DB.appearance.useClassColors = value
            if PE.states.isEpicBG or PE.states.isEpicBGTestMode then
                PE:RefreshEpicBGFrameAppearances()
            else
                PE:UpdateFrames()
            end
        end
    )
    
    -- Use Class Color Names checkbox (to the right)
    self:CreateCheckbox(scrollChild, "Use Class Color Names", 180, yOffset,
        function() return PE.DB.appearance.useClassColorNames end,
        function(value)
            PE.DB.appearance.useClassColorNames = value
            -- Update appropriate frames based on current mode
            if PE.states.isEpicBG or PE.states.isEpicBGTestMode then
                PE:RefreshEpicBGFrameAppearances()
            else
                PE:UpdateFrames()
            end
        end
    )
    
    yOffset = yOffset - 40
    
    -- Health Bar Texture dropdown
    self:CreateDropdown(scrollChild, "Health Bar Texture", 10, yOffset,
        function()
            local names = {}
            for _, tex in ipairs(PE.TextureList) do
                table.insert(names, tex.name)
            end
            return names
        end,
        function()
            local currentPath = PE.DB.appearance.healthBarTexture
            for i, tex in ipairs(PE.TextureList) do
                if tex.path == currentPath then
                    return i
                end
            end
            return 1
        end,
        function(index)
            local tex = PE.TextureList[index]
            if tex then
                PE.DB.appearance.healthBarTexture = tex.path
                PE:UpdateFrameTextures()
            end
        end
    )
    
    yOffset = yOffset - 55
    
    -- Status Text Type dropdown
    self:CreateDropdown(scrollChild, "Status Text Type", 10, yOffset,
        function()
            return {"Damage", "Healing", "Killing Blows"}
        end,
        function()
            local statusType = PE.DB.appearance.statusTextType or "damage"
            if statusType == "damage" then return 1
            elseif statusType == "healing" then return 2
            elseif statusType == "kills" then return 3
            end
            return 1
        end,
        function(index)
            local types = {"damage", "healing", "kills"}
            PE.DB.appearance.statusTextType = types[index]
            if PE.states.isEpicBG or PE.states.isEpicBGTestMode then
                PE:RefreshEpicBGFrameAppearances()
            else
                PE:UpdateFrames()
            end
        end
    )
    
    yOffset = yOffset - 55
    
    -- Class Icon Theme dropdown
    self:CreateDropdown(scrollChild, "Class Icon Theme", 10, yOffset,
        function()
            return {"Default (ArenaCore)", "Midnight Chill"}
        end,
        function()
            local theme = PE.DB.classIcons.theme
            if theme == "coldclasses" then
                return 2 -- "Midnight Chill"
            else
                return 1 -- "Default (ArenaCore)"
            end
        end,
        function(index)
            PE.DB.classIcons.theme = (index == 2) and "coldclasses" or "default"
            PE:UpdateClassIconTheme()
        end
    )
    
    yOffset = yOffset - 55
    
    -- Sort Method dropdown
    self:CreateDropdown(scrollChild, "Sort Priority", 10, yOffset,
        function()
            return {"Standard (No Sorting)", "Top Damage", "Killing Blows", "Top Healing", "Class/Healer Sorting"}
        end,
        function()
            local sortMethod = PE.DB.appearance.sortMethod or "damage"
            if sortMethod == "standard" then return 1
            elseif sortMethod == "damage" then return 2
            elseif sortMethod == "kills" then return 3
            elseif sortMethod == "healing" then return 4
            elseif sortMethod == "class" then return 5
            end
            return 2
        end,
        function(index)
            local methods = {"standard", "damage", "kills", "healing", "class"}
            PE.DB.appearance.sortMethod = methods[index]
            PE:UpdateFrames()
        end
    )
    
    yOffset = yOffset - 60
    
    -- Spec Icon section header
    local specHeader = scrollChild:CreateFontString(nil, "OVERLAY")
    specHeader:SetFont(PE:GetFont(), 12, "OUTLINE")
    specHeader:SetPoint("TOPLEFT", 10, yOffset)
    specHeader:SetText("Spec Icon Settings")
    specHeader:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    yOffset = yOffset - 25
    
    -- Show Spec Icons checkbox
    self:CreateCheckbox(scrollChild, "Show Spec Icons", 10, yOffset,
        function() return PE.DB.specIcons.enabled end,
        function(value)
            PE.DB.specIcons.enabled = value
            if PE.states.isEpicBG or PE.states.isEpicBGTestMode then
                PE:RefreshEpicBGFrameAppearances()
            else
                PE:UpdateFrames()
            end
        end
    )
    
    yOffset = yOffset - 45
    
    -- Spec Icon Size slider
    self:CreateSlider(scrollChild, "Spec Icon Size", 10, yOffset, 12, 32, 1,
        function() return PE.DB.specIcons.size end,
        function(value)
            PE.DB.specIcons.size = value
            PE:UpdateSpecIconSizes()
        end
    )
    
    yOffset = yOffset - 45
    
    -- Spec Icon X Offset slider
    self:CreateSlider(scrollChild, "Spec Icon X Offset", 10, yOffset, -30, 10, 1,
        function() return PE.DB.specIcons.xOffset end,
        function(value)
            PE.DB.specIcons.xOffset = value
            PE:UpdateSpecIconPositions()
        end
    )
    
    yOffset = yOffset - 45
    
    -- Spec Icon Y Offset slider
    self:CreateSlider(scrollChild, "Spec Icon Y Offset", 10, yOffset, -20, 20, 1,
        function() return PE.DB.specIcons.yOffset end,
        function(value)
            PE.DB.specIcons.yOffset = value
            PE:UpdateSpecIconPositions()
        end
    )
end

function PE:CreateTrinketsPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    panel:Hide()
    self.panels["Trinkets"] = panel
    
    local yOffset = -20
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 14, "OUTLINE")
    title:SetPoint("TOPLEFT", 15, yOffset)
    title:SetText("Trinket Tracking")
    title:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    -- Experimental notice with alert icon
    local alertIcon = panel:CreateTexture(nil, "OVERLAY")
    alertIcon:SetSize(16, 16)
    alertIcon:SetPoint("LEFT", title, "RIGHT", 15, 0)
    alertIcon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    alertIcon:SetVertexColor(1, 0.8, 0)
    
    local notice = panel:CreateFontString(nil, "OVERLAY")
    notice:SetFont(PE:GetFont(), 11, "")
    notice:SetPoint("LEFT", alertIcon, "RIGHT", 5, 0)
    notice:SetText("Trinkets are Experimental/Coming Soon™")
    notice:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 35
    
    -- Enable Trinket Tracking checkbox
    self:CreateCheckbox(panel, "Enable Trinket Tracking", 15, yOffset,
        function() return PE.DB.trinkets.enabled end,
        function(value)
            PE.DB.trinkets.enabled = value
            PE:UpdateHealthBarWidth()
            PE:UpdateFrames()
        end
    )
    
    yOffset = yOffset - 30
    
    -- Show Cooldown checkbox
    self:CreateCheckbox(panel, "Show Cooldown Spiral", 15, yOffset,
        function() return PE.DB.trinkets.showCooldown end,
        function(value)
            PE.DB.trinkets.showCooldown = value
            PE:UpdateFrames()
        end
    )
    
    yOffset = yOffset - 60
    
    -- Trinket Size slider
    self:CreateSlider(panel, "Trinket Icon Size", 15, yOffset, 16, 40, 2,
        function() return PE.DB.trinkets.size end,
        function(value)
            PE.DB.trinkets.size = value
            PE:UpdateTrinketSizes()
        end
    )
    
    yOffset = yOffset - 60
    
    -- Flag Icon Size slider
    self:CreateSlider(panel, "Flag Icon Size", 15, yOffset, 16, 40, 2,
        function() return PE.DB.flags.size end,
        function(value)
            PE.DB.flags.size = value
            PE:UpdateFlagSizes()
        end
    )
    
    yOffset = yOffset - 50
    
    -- Flag Icon X Offset slider
    self:CreateSlider(panel, "Flag Icon X Offset", 15, yOffset, -100, 100, 1,
        function() return PE.DB.flags.xOffset or 2 end,
        function(value)
            PE.DB.flags.xOffset = value
            PE:UpdateFlagPositions()
        end
    )
    
    yOffset = yOffset - 60
    
    -- Healer Indicator checkbox
    self:CreateCheckbox(panel, "Enable Healer Indicator", 15, yOffset,
        function() return PE.DB.healers.enabled end,
        function(value)
            PE.DB.healers.enabled = value
            if PE.states.isEpicBG or PE.states.isEpicBGTestMode then
                PE:RefreshEpicBGFrameAppearances()
            else
                PE:UpdateFrames()
            end
        end
    )
    
    yOffset = yOffset - 30
    
    -- Healer Icon Size slider
    self:CreateSlider(panel, "Healer Icon Size", 15, yOffset, 12, 48, 2,
        function() return PE.DB.healers.size end,
        function(value)
            PE.DB.healers.size = value
            PE:UpdateHealerSizes()
        end
    )
    
    yOffset = yOffset - 50
    
    -- Healer Icon Horizontal Position slider
    self:CreateSlider(panel, "Healer Icon X Offset", 15, yOffset, -100, 100, 1,
        function() return PE.DB.healers.xOffset or 2 end,
        function(value)
            PE.DB.healers.xOffset = value
            PE:UpdateHealerPositions()
        end
    )
end


function PE:CreatePositionPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    panel:Hide()
    self.panels["Position"] = panel
    
    local yOffset = -20
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 14, "OUTLINE")
    title:SetPoint("TOPLEFT", 15, yOffset)
    title:SetText("Position Settings")
    title:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    yOffset = yOffset - 35
    
    -- Info text
    local info = panel:CreateFontString(nil, "OVERLAY")
    info:SetFont(PE:GetFont(), 11, "")
    info:SetPoint("TOPLEFT", 15, yOffset)
    info:SetText("Drag the anchor frame to reposition.\nUse Test Mode to see the frames.")
    info:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    info:SetJustifyH("LEFT")
    
    yOffset = yOffset - 50
    
    -- X Position slider
    self:CreateSlider(panel, "X Offset", 15, yOffset, -500, 500, 5,
        function() return PE.DB.position.x end,
        function(value)
            PE.DB.position.x = value
            PE:UpdateFramePositions()
        end
    )
    
    yOffset = yOffset - 50
    
    -- Y Position slider
    self:CreateSlider(panel, "Y Offset", 15, yOffset, -500, 500, 5,
        function() return PE.DB.position.y end,
        function(value)
            PE.DB.position.y = value
            PE:UpdateFramePositions()
        end
    )
    
    yOffset = yOffset - 50
    
    -- Reset Position button
    local resetBtn = self:CreateButton(panel, "Reset Position", 120, 28)
    resetBtn:SetPoint("TOPLEFT", 15, yOffset)
    resetBtn:SetScript("OnClick", function()
        PE:ResetPosition()
    end)
end

-- ============================================================================
-- SKIN MODS PANEL
-- ============================================================================

function PE:CreateSkinModsPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    panel:Hide()
    self.panels["SkinMods"] = panel
    
    local yOffset = -20
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 14, "OUTLINE")
    title:SetPoint("TOPLEFT", 15, yOffset)
    title:SetText("Skin Mods")
    title:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    yOffset = yOffset - 25
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY")
    desc:SetFont(PE:GetFont(), 10, "")
    desc:SetPoint("TOPLEFT", 15, yOffset)
    desc:SetText("Apply custom themes to supported addons.")
    desc:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    
    yOffset = yOffset - 35
    
    -- ============================================================================
    -- CAPPING BATTLEGROUNDS TIMERS SECTION
    -- ============================================================================
    
    -- Section header
    local cappingHeader = panel:CreateFontString(nil, "OVERLAY")
    cappingHeader:SetFont(PE:GetFont(), 12, "OUTLINE")
    cappingHeader:SetPoint("TOPLEFT", 15, yOffset - 8)
    cappingHeader:SetText("Capping Battleground Timers")
    cappingHeader:SetTextColor(unpack(COLORS.ACCENT_PURPLE))
    
    yOffset = yOffset - 5
    
    -- Divider line
    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", 15, yOffset)
    divider:SetSize(390, 1)
    divider:SetColorTexture(0.4, 0.2, 0.6, 0.5)
    
    yOffset = yOffset - 25
    
    -- Status text (shows if Capping is installed)
    local statusText = panel:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(PE:GetFont(), 10, "")
    statusText:SetPoint("TOPLEFT", 15, yOffset)
    statusText:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    panel.cappingStatus = statusText
    
    yOffset = yOffset - 30
    
    -- Enable Capping Skin checkbox
    local cappingCheckbox = self:CreateCheckbox(panel, "Enable Capping Skin", 15, yOffset,
        function() return PE.DB.skinMods.capping.enabled end,
        function(value)
            -- Check if Capping is installed before enabling
            local cappingLoaded = C_AddOns.IsAddOnLoaded("Capping")
            if value and not cappingLoaded then
                PE:Print("|cffFF4444Warning:|r Capping addon is not installed or enabled. Please install Capping first.")
                PE.DB.skinMods.capping.enabled = false
                -- Reset the checkbox visually
                if cappingCheckbox and cappingCheckbox.checkmark then
                    cappingCheckbox.checkmark:Hide()
                end
                return
            end
            
            PE.DB.skinMods.capping.enabled = value
            if value then
                PE:Print("Capping skin enabled. Theme will apply on next BG entry or /reload.")
                if PE.CappingSkin then
                    PE.CappingSkin:Enable()
                end
            else
                PE:Print("Capping skin disabled.")
                if PE.CappingSkin then
                    PE.CappingSkin:Disable()
                end
            end
            
            -- Show/hide disable button based on state
            if panel.disableButton then
                if value then
                    panel.disableButton:Show()
                else
                    panel.disableButton:Hide()
                end
            end
        end
    )
    panel.cappingCheckbox = cappingCheckbox
    
    yOffset = yOffset - 35 -- Add proper spacing after checkbox
    
    -- Disable Capping Skin button (only visible when enabled)
    local disableBtn = self:CreateButton(panel, "Disable Capping Skin", 150, 28)
    disableBtn:SetPoint("TOPLEFT", 15, yOffset)
    
    -- Enhanced styling for disable button
    disableBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    disableBtn:SetBackdropColor(0.3, 0.1, 0.4, 0.9) -- Purple tinted background
    disableBtn:SetBackdropBorderColor(0.8, 0.4, 0.9, 1) -- Bright purple border
    
    -- Make text more prominent
    disableBtn.fontString:SetFont(PE:GetFont(), 11, "OUTLINE")
    disableBtn.fontString:SetTextColor(1, 0.8, 1, 1) -- Light purple text
    
    -- Override hover effects for enhanced visibility
    disableBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.4, 0.15, 0.5, 0.95) -- Brighter purple on hover
        self:SetBackdropBorderColor(1, 0.6, 1, 1) -- Very bright purple border
        self.fontString:SetTextColor(1, 1, 1, 1) -- White text on hover
        -- Show glow lines
        for _, glowLine in ipairs(self.glowLines) do
            glowLine:Show()
        end
    end)
    disableBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.3, 0.1, 0.4, 0.9) -- Return to purple tinted
        self:SetBackdropBorderColor(0.8, 0.4, 0.9, 1) -- Return to bright purple
        self.fontString:SetTextColor(1, 0.8, 1, 1) -- Return to light purple
        -- Hide glow lines
        for _, glowLine in ipairs(self.glowLines) do
            glowLine:Hide()
        end
    end)
    
    disableBtn:SetScript("OnClick", function()
        PE:ShowCappingSkinReloadPopup(cappingCheckbox)
    end)
    panel.disableButton = disableBtn
    
    -- Initially hide/show based on current state
    if PE.DB.skinMods.capping.enabled then
        disableBtn:Show()
    else
        disableBtn:Hide()
    end
    
    yOffset = yOffset - 40
    
    -- Theme dropdown
    self:CreateDropdown(panel, "Theme", 15, yOffset,
        function()
            return {"No Theme", "Modern"}
        end,
        function()
            local theme = PE.DB.skinMods.capping.theme or "modern"
            if theme == "none" then return 1
            elseif theme == "modern" then return 2
            end
            return 2 -- Default to Modern
        end,
        function(index)
            local themes = {"none", "modern"}
            PE.DB.skinMods.capping.theme = themes[index]
            if PE.CappingSkin and PE.DB.skinMods.capping.enabled then
                PE.CappingSkin:ApplyTheme()
            end
        end
    )
    
    yOffset = yOffset - 55
    
    -- Use Custom Font checkbox
    local customFontCheckbox = self:CreateCheckbox(panel, "Use Custom Font", 15, yOffset,
        function() 
            local useCustomFont = PE.DB.skinMods.capping.useCustomFont
            if useCustomFont == nil then return true end -- Default to true
            return useCustomFont
        end,
        function(value)
            PE.DB.skinMods.capping.useCustomFont = value
            if value then
                PE:Print("Custom font enabled. Reload UI to see changes.")
            else
                PE:Print("Custom font disabled. Reload UI to see changes.")
            end
        end
    )
    
    -- Disable Custom Font button (only visible when custom font is enabled)
    local disableFontBtn = self:CreateButton(panel, "Disable Custom Font", 150, 28)
    disableFontBtn:SetPoint("LEFT", customFontCheckbox, "RIGHT", 120, 0)
    
    -- Enhanced styling for disable font button
    disableFontBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    disableFontBtn:SetBackdropColor(0.2, 0.1, 0.3, 0.9) -- Darker purple tint
    disableFontBtn:SetBackdropBorderColor(0.6, 0.3, 0.8, 1) -- Purple border
    
    -- Make text more prominent
    disableFontBtn.fontString:SetFont(PE:GetFont(), 11, "OUTLINE")
    disableFontBtn.fontString:SetTextColor(0.8, 0.6, 1, 1) -- Light purple text
    
    -- Override hover effects
    disableFontBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.15, 0.4, 0.95) -- Brighter purple on hover
        self:SetBackdropBorderColor(0.8, 0.4, 0.9, 1) -- Bright purple border
        self.fontString:SetTextColor(1, 0.8, 1, 1) -- White text on hover
        -- Show glow lines
        for _, glowLine in ipairs(self.glowLines) do
            glowLine:Show()
        end
    end)
    disableFontBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.1, 0.3, 0.9) -- Return to darker purple
        self:SetBackdropBorderColor(0.6, 0.3, 0.8, 1) -- Return to purple
        self.fontString:SetTextColor(0.8, 0.6, 1, 1) -- Return to light purple
        -- Hide glow lines
        for _, glowLine in ipairs(self.glowLines) do
            glowLine:Hide()
        end
    end)
    
    disableFontBtn:SetScript("OnClick", function()
        PE:ShowCustomFontReloadPopup(customFontCheckbox)
    end)
    panel.disableFontButton = disableFontBtn
    
    -- Initially hide/show based on current state
    if PE.DB.skinMods.capping.useCustomFont then
        disableFontBtn:Show()
    else
        disableFontBtn:Hide()
    end
    
    -- Update button visibility when checkbox changes
    customFontCheckbox:SetScript("OnClick", function()
        local value = not customFontCheckbox.checkmark:IsShown()
        
        PE.DB.skinMods.capping.useCustomFont = value
        if value then
            PE:Print("Custom font enabled. Reload UI to see changes.")
            disableFontBtn:Show()
        else
            PE:Print("Custom font disabled. Reload UI to see changes.")
            disableFontBtn:Hide()
        end
    end)
    
    yOffset = yOffset - 35
    
    -- Test Timer Skin button
    local testBtn = self:CreateButton(panel, "Test Skin", 100, 28)
    testBtn:SetPoint("TOPLEFT", 15, yOffset)
    testBtn:SetScript("OnClick", function()
        local cappingLoaded = C_AddOns.IsAddOnLoaded("Capping")
        if not cappingLoaded then
            PE:Print("|cffFF4444Capping addon is not installed.|r")
            return
        end
        
        if not CappingFrame or not CappingFrame.Test then
            PE:Print("|cffFF4444Capping test function not found.|r")
            return
        end
        
        -- Enable skin if not enabled
        local wasEnabled = PE.DB.skinMods.capping.enabled
        if not wasEnabled then
            PE.DB.skinMods.capping.enabled = true
            if PE.CappingSkin then
                PE.CappingSkin:Enable()
            end
        end
        
        -- Apply theme settings BEFORE creating test bars (so spacing is set)
        if PE.CappingSkin then
            PE.CappingSkin:ApplyTheme()
        end
        
        -- Call Capping's test function with locale strings
        local testLocale = {
            allianceBars = "Alliance Bar",
            hordeBars = "Horde Bar",
            queueBars = "Queue Bar",
            otherBars = "Other Bar",
        }
        CappingFrame:Test(testLocale)
        
        -- Re-apply theme after bars spawn to skin the visuals
        C_Timer.After(0.05, function()
            if PE.CappingSkin then
                PE.CappingSkin:ApplyTheme()
            end
        end)
        
        PE:Print("Capping test bars spawned with your theme applied.")
    end)
    
    yOffset = yOffset - 45
    
    -- Info box about Capping
    local infoBox = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    infoBox:SetSize(390, 80)
    infoBox:SetPoint("TOPLEFT", 15, yOffset)
    infoBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    infoBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    infoBox:SetBackdropBorderColor(0.3, 0.2, 0.4, 1)
    
    local infoIcon = infoBox:CreateTexture(nil, "OVERLAY")
    infoIcon:SetAtlas("Campaign-QuestLog-LoreBook-Back")
    infoIcon:SetSize(24, 24)
    infoIcon:SetPoint("TOPLEFT", 10, -10)
    
    local infoTitle = infoBox:CreateFontString(nil, "OVERLAY")
    infoTitle:SetFont(PE:GetFont(), 10, "OUTLINE")
    infoTitle:SetPoint("TOPLEFT", infoIcon, "TOPRIGHT", 8, -2)
    infoTitle:SetText("About Capping Skins")
    infoTitle:SetTextColor(0.8, 0.6, 1.0, 1)
    
    local infoText = infoBox:CreateFontString(nil, "OVERLAY")
    infoText:SetFont(PE:GetFont(), 9, "")
    infoText:SetPoint("TOPLEFT", 10, -40)
    infoText:SetWidth(370)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("This feature skins the Capping addon's timer bars with custom themes. Capping handles all battleground timer logic - we only change the visual appearance. Install Capping Battleground Timers from Curseforge to use this mod.")
    infoText:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    
    -- Update status on panel show
    panel:SetScript("OnShow", function()
        local cappingLoaded = C_AddOns.IsAddOnLoaded("Capping")
        if cappingLoaded then
            statusText:SetText("|cff44FF44Capping addon detected|r")
        else
            statusText:SetText("|cffFF4444Capping addon not found|r - Install Capping to use this feature")
        end
    end)
end

-- ============================================================================
-- PANEL SWITCHING
-- ============================================================================

function PE:ShowPanel(panelName)
    currentPanel = panelName
    
    -- Hide all panels
    for name, panel in pairs(self.panels) do
        panel:Hide()
    end
    
    -- Show selected panel
    if self.panels[panelName] then
        self.panels[panelName]:Show()
    end
    
    -- Update nav button states
    for name, btn in pairs(self.navButtons) do
        if name == panelName then
            btn:SetBackdropColor(unpack(COLORS.BUTTON_ACTIVE))
            btn.fontString:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
        else
            btn:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
            btn.fontString:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
            btn:SetBackdropBorderColor(0, 0, 0, 0)
            -- Hide glow lines on inactive buttons
            if btn.glowLines then
                for _, glowLine in ipairs(btn.glowLines) do
                    glowLine:Hide()
                end
            end
        end
    end
end

-- ============================================================================
-- UI HELPERS
-- ============================================================================

function PE:CreateButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    btn:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
    btn:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
    
    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFont(PE:GetFont(), 11, "")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    fs:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    btn.fontString = fs
    
    -- Create 4-edge glow lines for hover effect (like Shade)
    local topGlow = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    topGlow:SetHeight(1)
    topGlow:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    topGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
    topGlow:SetDrawLayer("OVERLAY", 7)
    if topGlow.SetSnapToPixelGrid then
        topGlow:SetTexelSnappingBias(0)
        topGlow:SetSnapToPixelGrid(false)
    end
    topGlow:Hide()
    
    local bottomGlow = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    bottomGlow:SetHeight(1)
    bottomGlow:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    bottomGlow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    bottomGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
    bottomGlow:SetDrawLayer("OVERLAY", 7)
    if bottomGlow.SetSnapToPixelGrid then
        bottomGlow:SetTexelSnappingBias(0)
        bottomGlow:SetSnapToPixelGrid(false)
    end
    bottomGlow:Hide()
    
    local leftGlow = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    leftGlow:SetWidth(1)
    leftGlow:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    leftGlow:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    leftGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
    leftGlow:SetDrawLayer("OVERLAY", 7)
    if leftGlow.SetSnapToPixelGrid then
        leftGlow:SetTexelSnappingBias(0)
        leftGlow:SetSnapToPixelGrid(false)
    end
    leftGlow:Hide()
    
    local rightGlow = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    rightGlow:SetWidth(1)
    rightGlow:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    rightGlow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    rightGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
    rightGlow:SetDrawLayer("OVERLAY", 7)
    if rightGlow.SetSnapToPixelGrid then
        rightGlow:SetTexelSnappingBias(0)
        rightGlow:SetSnapToPixelGrid(false)
    end
    rightGlow:Hide()
    
    btn.glowLines = {topGlow, bottomGlow, leftGlow, rightGlow}
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_HOVER))
        self:SetBackdropBorderColor(0.8, 0.4, 0.9, 1) -- Purple border glow
        fs:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
        -- Show glow lines
        for _, glowLine in ipairs(self.glowLines) do
            glowLine:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
        self:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
        fs:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
        -- Hide glow lines
        for _, glowLine in ipairs(self.glowLines) do
            glowLine:Hide()
        end
    end)
    
    return btn
end

function PE:CreateSlider(parent, label, x, y, minVal, maxVal, step, getValue, setValue)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(400, 40) -- Increased width from 380 to 400
    container:SetPoint("TOPLEFT", x, y)
    
    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(PE:GetFont(), 11, "")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetText(label)
    labelText:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
    
    local valueText = container:CreateFontString(nil, "OVERLAY")
    valueText:SetFont(PE:GetFont(), 11, "")
    valueText:SetPoint("TOPRIGHT", 0, 0)
    valueText:SetTextColor(unpack(COLORS.ACCENT_PINK))
    
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetSize(400, 16) -- Increased width from 380 to 400
    slider:SetPoint("TOPLEFT", 0, -18)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    slider:SetBackdropColor(unpack(COLORS.SLIDER_BG))
    slider:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
    
    -- Thumb texture
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(12, 14)
    thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
    thumb:SetVertexColor(unpack(COLORS.ACCENT_PURPLE))
    slider:SetThumbTexture(thumb)
    
    -- Initialize
    local currentValue = getValue()
    slider:SetValue(currentValue)
    valueText:SetText(tostring(currentValue))
    
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        valueText:SetText(tostring(value))
        setValue(value)
    end)
    
    return slider
end

-- Compact slider with input box for group settings
function PE:CreateCompactSliderWithInput(parent, label, x, y, minVal, maxVal, step, getValue, setValue)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(340, 40)
    container:SetPoint("TOPLEFT", x, y)
    
    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(PE:GetFont(), 10, "")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetText(label)
    labelText:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
    
    -- Input box for exact value entry
    local inputBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    inputBox:SetSize(50, 18)
    inputBox:SetPoint("TOPRIGHT", 0, 0)
    inputBox:SetAutoFocus(false)
    inputBox:SetFont(PE:GetFont(), 10, "")
    inputBox:SetTextColor(unpack(COLORS.ACCENT_PINK))
    inputBox:SetJustifyH("CENTER")
    inputBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    inputBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    inputBox:SetBackdropBorderColor(0.4, 0.2, 0.6, 1)
    
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetSize(280, 14)
    slider:SetPoint("TOPLEFT", 0, -16)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    slider:SetBackdropColor(unpack(COLORS.SLIDER_BG))
    slider:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
    
    -- Thumb texture
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(10, 12)
    thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
    thumb:SetVertexColor(unpack(COLORS.ACCENT_PURPLE))
    slider:SetThumbTexture(thumb)
    
    -- Initialize
    local currentValue = getValue()
    slider:SetValue(currentValue)
    inputBox:SetText(tostring(currentValue))
    
    -- Slider value changed
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        inputBox:SetText(tostring(value))
        setValue(value)
    end)
    
    -- Input box handlers
    inputBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        local value = tonumber(text)
        if value then
            value = math.max(minVal, math.min(maxVal, value))
            value = math.floor(value / step + 0.5) * step
            slider:SetValue(value)
            self:SetText(tostring(value))
        else
            self:SetText(tostring(slider:GetValue()))
        end
        self:ClearFocus()
    end)
    
    inputBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(slider:GetValue()))
        self:ClearFocus()
    end)
    
    return slider, inputBox
end

function PE:CreateCheckbox(parent, label, x, y, getValue, setValue)
    local checkboxFrame = CreateFrame("Frame", nil, parent)
    checkboxFrame:SetSize(300, 20)
    checkboxFrame:SetPoint("TOPLEFT", x, y)
    
    local checkbox = CreateFrame("Button", nil, checkboxFrame, "BackdropTemplate")
    checkbox:SetSize(16, 16)
    checkbox:SetPoint("LEFT", 0, 0)
    
    -- Square backdrop like Shade design
    checkbox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left=1, right=1, top=1, bottom=1 }
    })
    checkbox:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    checkbox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Custom checkbox background (unchecked state)
    local bg = checkbox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(checkbox)
    bg:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\checkbox-unchecked.tga")
    
    -- Checkmark texture (checked state)
    local checkmark = checkbox:CreateTexture(nil, "OVERLAY")
    checkmark:SetAllPoints(checkbox)
    checkmark:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\checkbox-checked.tga")
    checkmark:Hide()
    checkbox.checkmark = checkmark
    
    -- Purple overlay on hover - ADD blend mode for glow effect
    local hoverOverlay = checkbox:CreateTexture(nil, "ARTWORK")
    hoverOverlay:SetAllPoints(checkbox)
    hoverOverlay:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\checkbox-unchecked.tga")
    hoverOverlay:SetBlendMode("ADD")
    hoverOverlay:SetVertexColor(0.8, 0.4, 0.9, 0.5)
    hoverOverlay:Hide()
    
    -- Create 4-edge glow lines for hover effect
    local topGlow = checkbox:CreateTexture(nil, "OVERLAY", nil, 7)
    topGlow:SetHeight(1)
    topGlow:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", checkbox, "TOPRIGHT", 0, 0)
    topGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
    topGlow:SetDrawLayer("OVERLAY", 7)
    if topGlow.SetSnapToPixelGrid then
        topGlow:SetTexelSnappingBias(0)
        topGlow:SetSnapToPixelGrid(false)
    end
    topGlow:Hide()
    
    local bottomGlow = checkbox:CreateTexture(nil, "OVERLAY", nil, 7)
    bottomGlow:SetHeight(1)
    bottomGlow:SetPoint("BOTTOMLEFT", checkbox, "BOTTOMLEFT", 0, 0)
    bottomGlow:SetPoint("BOTTOMRIGHT", checkbox, "BOTTOMRIGHT", 0, 0)
    bottomGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
    bottomGlow:SetDrawLayer("OVERLAY", 7)
    if bottomGlow.SetSnapToPixelGrid then
        bottomGlow:SetTexelSnappingBias(0)
        bottomGlow:SetSnapToPixelGrid(false)
    end
    bottomGlow:Hide()
    
    local leftGlow = checkbox:CreateTexture(nil, "OVERLAY", nil, 7)
    leftGlow:SetWidth(1)
    leftGlow:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 0, 0)
    leftGlow:SetPoint("BOTTOMLEFT", checkbox, "BOTTOMLEFT", 0, 0)
    leftGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
    leftGlow:SetDrawLayer("OVERLAY", 7)
    if leftGlow.SetSnapToPixelGrid then
        leftGlow:SetTexelSnappingBias(0)
        leftGlow:SetSnapToPixelGrid(false)
    end
    leftGlow:Hide()
    
    local rightGlow = checkbox:CreateTexture(nil, "OVERLAY", nil, 7)
    rightGlow:SetWidth(1)
    rightGlow:SetPoint("TOPRIGHT", checkbox, "TOPRIGHT", 0, 0)
    rightGlow:SetPoint("BOTTOMRIGHT", checkbox, "BOTTOMRIGHT", 0, 0)
    rightGlow:SetColorTexture(0.8, 0.4, 0.9, 1)
    rightGlow:SetDrawLayer("OVERLAY", 7)
    if rightGlow.SetSnapToPixelGrid then
        rightGlow:SetTexelSnappingBias(0)
        rightGlow:SetSnapToPixelGrid(false)
    end
    rightGlow:Hide()
    
    checkbox.glowLines = {topGlow, bottomGlow, leftGlow, rightGlow}
    
    local labelText = checkboxFrame:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(PE:GetFont(), 11, "")
    labelText:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    labelText:SetText(label)
    labelText:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
    checkboxFrame.label = labelText
    
    -- Hover effects: purple overlay + glow lines + text highlight
    checkbox:SetScript("OnEnter", function(self)
        if self.SetBackdropColor then
            self:SetBackdropColor(0.4, 0.15, 0.5, 0.8)
        end
        hoverOverlay:Show()
        for _, glowLine in ipairs(self.glowLines) do
            glowLine:Show()
        end
        labelText:SetTextColor(1, 1, 1, 1)
    end)
    
    checkbox:SetScript("OnLeave", function(self)
        if self.SetBackdropColor then
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        end
        hoverOverlay:Hide()
        for _, glowLine in ipairs(self.glowLines) do
            glowLine:Hide()
        end
        labelText:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
    end)
    
    -- Initialize
    local isChecked = getValue()
    if isChecked then
        checkmark:Show()
        bg:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\checkbox-checked.tga")
    end
    
    checkbox:SetScript("OnClick", function(self)
        local newValue = not getValue()
        setValue(newValue)
        if newValue then
            checkmark:Show()
            bg:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\checkbox-checked.tga")
        else
            checkmark:Hide()
            bg:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\checkbox-unchecked.tga")
        end
    end)
    
    return checkbox
end

function PE:CreateDropdown(parent, label, x, y, getItems, getSelected, setSelected)
    -- Label
    local labelText = parent:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(PE:GetFont(), 11, "")
    labelText:SetPoint("TOPLEFT", x, y)
    labelText:SetText(label)
    labelText:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
    
    -- Main dropdown button - use UIPanelButtonTemplate for guaranteed click handling
    local dropdown = CreateFrame("Button", nil, parent)
    dropdown:SetSize(200, 24)
    dropdown:SetPoint("TOPLEFT", x, y - 18)
    
    -- Background
    local bg = dropdown:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(COLORS.BUTTON_NORMAL))
    dropdown.bg = bg
    
    -- Border
    local border = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0},
    })
    border:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
    
    -- Selected text
    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(PE:GetFont(), 11, "")
    selectedText:SetPoint("LEFT", 8, 0)
    selectedText:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
    
    -- Arrow
    local arrow = dropdown:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", -4, 0)
    arrow:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\dropdown-arrow.tga")
    arrow:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- Get items and selection
    local items = getItems()
    local selectedIndex = getSelected()
    selectedText:SetText(items[selectedIndex] or "Select...")
    
    -- Menu frame with scrolling support
    local itemHeight = 22
    local maxVisibleItems = 10
    local visibleItems = math.min(#items, maxVisibleItems)
    local menuHeight = visibleItems * itemHeight + 4
    local needsScroll = #items > maxVisibleItems
    
    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetSize(200, menuHeight)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(1000)
    menu:Hide()
    
    -- Menu background
    menu:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    menu:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    menu:SetBackdropBorderColor(unpack(COLORS.BORDER_LIGHT))
    
    -- Scroll frame for items
    local scrollFrame = CreateFrame("ScrollFrame", nil, menu)
    if needsScroll then
        scrollFrame:SetPoint("TOPLEFT", 2, -2)
        scrollFrame:SetPoint("BOTTOMRIGHT", -20, 2)
    else
        scrollFrame:SetPoint("TOPLEFT", 2, -2)
        scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    end
    
    -- Scroll child container
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(needsScroll and 178 or 196, #items * itemHeight)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Scrollbar (only if needed)
    local scrollBar
    if needsScroll then
        scrollBar = CreateFrame("Slider", nil, menu, "BackdropTemplate")
        scrollBar:SetPoint("TOPRIGHT", -2, -2)
        scrollBar:SetPoint("BOTTOMRIGHT", -2, 2)
        scrollBar:SetWidth(16)
        scrollBar:SetOrientation("VERTICAL")
        scrollBar:SetMinMaxValues(0, (#items - maxVisibleItems) * itemHeight)
        scrollBar:SetValueStep(itemHeight)
        scrollBar:SetValue(0)
        
        scrollBar:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1},
        })
        scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        scrollBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
        thumb:SetSize(12, 24)
        thumb:SetColorTexture(0.55, 0.27, 0.68, 0.8)
        scrollBar:SetThumbTexture(thumb)
        
        scrollBar:SetScript("OnValueChanged", function(self, value)
            scrollFrame:SetVerticalScroll(value)
        end)
        
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local current = scrollBar:GetValue()
            local minVal, maxVal = scrollBar:GetMinMaxValues()
            local newVal = current - (delta * itemHeight)
            newVal = math.max(minVal, math.min(maxVal, newVal))
            scrollBar:SetValue(newVal)
        end)
    end
    
    -- Create menu buttons
    local menuButtons = {}
    
    for i, item in ipairs(items) do
        local btn = CreateFrame("Button", nil, scrollChild)
        btn:SetSize(needsScroll and 178 or 196, itemHeight)
        btn:SetPoint("TOP", scrollChild, "TOP", 0, -(i-1) * itemHeight)
        
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetColorTexture(unpack(COLORS.BUTTON_NORMAL))
        btn.bg = btnBg
        
        local btnText = btn:CreateFontString(nil, "OVERLAY")
        btnText:SetFont(PE:GetFont(), 11, "")
        btnText:SetPoint("LEFT", 8, 0)
        btnText:SetText(item)
        btnText:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
        
        -- Checkmark
        local checkmark = btn:CreateTexture(nil, "OVERLAY")
        checkmark:SetSize(12, 12)
        checkmark:SetPoint("RIGHT", -8, 0)
        checkmark:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\checkmark-arrow.tga")
        checkmark:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        checkmark:SetShown(i == selectedIndex)
        btn.checkmark = checkmark
        
        btn:SetScript("OnEnter", function()
            btnBg:SetColorTexture(unpack(COLORS.BUTTON_HOVER))
        end)
        
        btn:SetScript("OnLeave", function()
            btnBg:SetColorTexture(unpack(COLORS.BUTTON_NORMAL))
        end)
        
        btn:SetScript("OnClick", function()
            setSelected(i)
            selectedText:SetText(item)
            menu:Hide()
            
            for j, menuBtn in ipairs(menuButtons) do
                if menuBtn.checkmark then
                    menuBtn.checkmark:SetShown(j == i)
                end
            end
        end)
        
        table.insert(menuButtons, btn)
    end
    
    -- Dropdown button click handler
    dropdown:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
        else
            -- Close any other open dropdown
            if PE._openDropdownMenu and PE._openDropdownMenu ~= menu then
                PE._openDropdownMenu:Hide()
            end
            PE._openDropdownMenu = menu
            
            -- Position menu below dropdown
            menu:ClearAllPoints()
            menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
            menu:Show()
        end
    end)
    
    -- Hover effects
    dropdown:SetScript("OnEnter", function()
        bg:SetColorTexture(unpack(COLORS.BUTTON_HOVER))
    end)
    
    dropdown:SetScript("OnLeave", function()
        bg:SetColorTexture(unpack(COLORS.BUTTON_NORMAL))
    end)
    
    -- Arrow rotation on show/hide
    menu:SetScript("OnShow", function()
        arrow:SetRotation(math.rad(180))
    end)
    
    menu:SetScript("OnHide", function()
        arrow:SetRotation(0)
        if PE._openDropdownMenu == menu then
            PE._openDropdownMenu = nil
        end
    end)
    
    dropdown.menu = menu
    return dropdown
end

-- ============================================================================
-- DISCORD POPUP
-- ============================================================================

function PE:ShowDiscordPopup()
    if self.DiscordPopup then 
        self.DiscordPopup:Show()
        return 
    end

    -- Create custom popup frame with Shade-style design
    self.DiscordPopup = CreateFrame("Frame", "PeralexBGDiscordPopup", UIParent, "BackdropTemplate")
    self.DiscordPopup:SetSize(400, 200)
    self.DiscordPopup:SetPoint("CENTER")
    self.DiscordPopup:SetFrameStrata("TOOLTIP")
    self.DiscordPopup:SetFrameLevel(2000)
    self.DiscordPopup:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    self.DiscordPopup:SetBackdropColor(unpack(COLORS.BACKGROUND_DARK))
    self.DiscordPopup:SetBackdropBorderColor(unpack(COLORS.BORDER_LIGHT))
    self.DiscordPopup:SetMovable(true)
    self.DiscordPopup:EnableMouse(true)
    self.DiscordPopup:RegisterForDrag("LeftButton")
    self.DiscordPopup:SetScript("OnDragStart", function(s) s:StartMoving() end)
    self.DiscordPopup:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)

    -- Subtle gradient
    local gradient = self.DiscordPopup:CreateTexture(nil, "BACKGROUND", nil, 1)
    gradient:SetAllPoints()
    gradient:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    gradient:SetGradient("VERTICAL", CreateColor(0.08,0.08,0.08,0.8), CreateColor(0.03,0.03,0.03,0.9))

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, self.DiscordPopup, "BackdropTemplate")
    titleBar:SetSize(396, 30)
    titleBar:SetPoint("TOP", 0, -2)
    titleBar:SetFrameLevel(self.DiscordPopup:GetFrameLevel()+1)
    titleBar:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32 })
    titleBar:SetBackdropColor(unpack(COLORS.BACKGROUND_MEDIUM))

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", 0, 2)
    title:SetText("Join Our Discord")
    title:SetTextColor(unpack(COLORS.TEXT_PRIMARY))

    -- Close button (X button style)
    local closeBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", -5, 0)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    closeBtn:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
    closeBtn:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
    
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER", 0, 0)
    closeText:SetText("X")
    closeText:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
    
    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_HOVER))
        self:SetBackdropBorderColor(0.8, 0.4, 0.9, 1)
        for _, glowLine in ipairs(self.glowLines or {}) do
            glowLine:Show()
        end
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
        self:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))
        for _, glowLine in ipairs(self.glowLines or {}) do
            glowLine:Hide()
        end
    end)
    
    closeBtn:SetScript("OnClick", function() self.DiscordPopup:Hide() end)

    -- Discord content
    local content = self.DiscordPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content:SetPoint("TOP", titleBar, "BOTTOM", 0, -20)
    content:SetText("Join the Peralex BG Discord community for:\n• Support and help\n• Feature suggestions\n• Updates and announcements\n• Share your setups")
    content:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    content:SetWidth(350)

    -- Discord link input box
    local discordLink = "https://ACdiscord.com"
    local linkInput = CreateFrame("EditBox", nil, self.DiscordPopup, "InputBoxTemplate")
    linkInput:SetSize(350, 32)
    linkInput:SetPoint("TOP", content, "BOTTOM", 0, -20)
    linkInput:SetAutoFocus(false)
    linkInput:SetText(discordLink)
    linkInput:SetFontObject("GameFontNormal")
    linkInput:SetTextColor(1, 1, 1, 1)
    linkInput:HighlightText()
    linkInput:SetFocus()

    -- Instruction text
    local instruction = self.DiscordPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    instruction:SetPoint("TOP", linkInput, "BOTTOM", 0, -10)
    instruction:SetText("Click the link above and press Ctrl+C to copy")
    instruction:SetTextColor(0.7, 0.7, 0.7, 1)

    -- Close on Escape
    self.DiscordPopup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    self.DiscordPopup:EnableKeyboard(true)

    self.DiscordPopup:Show()
end

-- ============================================================================
-- CAPPING SKIN RELOAD POPUP
-- ============================================================================

function PE:ShowCappingSkinReloadPopup(checkbox)
    -- Close existing popup if open
    if self.CappingSkinReloadPopup then 
        self.CappingSkinReloadPopup:Hide() 
    end

    -- Create custom popup frame with Discord-style design
    self.CappingSkinReloadPopup = CreateFrame("Frame", "PeralexBGCappingReloadPopup", UIParent, "BackdropTemplate")
    self.CappingSkinReloadPopup:SetSize(400, 180)
    self.CappingSkinReloadPopup:SetPoint("CENTER")
    self.CappingSkinReloadPopup:SetFrameStrata("FULLSCREEN_DIALOG")
    self.CappingSkinReloadPopup:SetFrameLevel(2000)
    self.CappingSkinReloadPopup:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    self.CappingSkinReloadPopup:SetBackdropColor(unpack(COLORS.BACKGROUND_DARK))
    self.CappingSkinReloadPopup:SetBackdropBorderColor(unpack(COLORS.BORDER_LIGHT))
    self.CappingSkinReloadPopup:SetMovable(true)
    self.CappingSkinReloadPopup:EnableMouse(true)
    self.CappingSkinReloadPopup:RegisterForDrag("LeftButton")
    self.CappingSkinReloadPopup:SetScript("OnDragStart", function(s) s:StartMoving() end)
    self.CappingSkinReloadPopup:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)

    -- Subtle gradient
    local gradient = self.CappingSkinReloadPopup:CreateTexture(nil, "BACKGROUND", nil, 1)
    gradient:SetAllPoints()
    gradient:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    gradient:SetGradient("VERTICAL", CreateColor(0.08,0.08,0.08,0.8), CreateColor(0.03,0.03,0.03,0.9))

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, self.CappingSkinReloadPopup, "BackdropTemplate")
    titleBar:SetSize(396, 30)
    titleBar:SetPoint("TOP", 0, -2)
    titleBar:SetFrameLevel(self.CappingSkinReloadPopup:GetFrameLevel()+1)
    titleBar:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32 })
    titleBar:SetBackdropColor(unpack(COLORS.BACKGROUND_MEDIUM))

    -- Purple accent line
    local accent = titleBar:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)
    accent:SetTexture("Interface\\Buttons\\WHITE8x8")
    accent:SetVertexColor(unpack(COLORS.ACCENT_PURPLE))

    -- Title
    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 14, "OUTLINE")
    title:SetPoint("CENTER", 0, 5)
    title:SetText("Reload Required")
    title:SetTextColor(unpack(COLORS.TEXT_PRIMARY))

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -8, -5)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    closeBtn:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
    closeBtn:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(PE:GetFont(), 12, "OUTLINE")
    closeText:SetPoint("CENTER", 0, 1)
    closeText:SetText("X")
    closeText:SetTextColor(unpack(COLORS.TEXT_SECONDARY))

    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_HOVER))
        closeText:SetTextColor(1, 0.3, 0.3)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
        closeText:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    end)
    
    closeBtn:SetScript("OnClick", function() 
        self.CappingSkinReloadPopup:Hide()
    end)

    -- Content
    local content = self.CappingSkinReloadPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content:SetPoint("TOP", titleBar, "BOTTOM", 0, -20)
    content:SetText("Disabling Capping Skin requires a UI reload to take effect.\n\nWould you like to reload now?")
    content:SetTextColor(unpack(COLORS.TEXT_SECONDARY))

    -- Button container
    local buttonContainer = CreateFrame("Frame", nil, self.CappingSkinReloadPopup)
    buttonContainer:SetSize(380, 40)
    buttonContainer:SetPoint("BOTTOM", 0, 15)

    -- Cancel button
    local cancelBtn = self:CreateButton(buttonContainer, "Cancel", 100, 28)
    cancelBtn:SetPoint("LEFT", 40, 0)
    cancelBtn:SetScript("OnClick", function()
        self.CappingSkinReloadPopup:Hide()
    end)

    -- Reload button
    local reloadBtn = self:CreateButton(buttonContainer, "Reload UI", 100, 28)
    reloadBtn:SetPoint("RIGHT", -40, 0)
    reloadBtn:SetScript("OnClick", function()
        self.CappingSkinReloadPopup:Hide()
        -- Actually disable the setting
        PE.DB.skinMods.capping.enabled = false
        if PE.CappingSkin then
            PE.CappingSkin:Disable()
        end
        -- Reload the UI
        C_UI.Reload()
    end)

    -- Close on Escape
    self.CappingSkinReloadPopup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    self.CappingSkinReloadPopup:EnableKeyboard(true)

    self.CappingSkinReloadPopup:Show()
end

-- ============================================================================
-- CUSTOM FONT RELOAD POPUP
-- ============================================================================

function PE:ShowCustomFontReloadPopup(checkbox)
    -- Close existing popup if open
    if self.CustomFontReloadPopup then 
        self.CustomFontReloadPopup:Hide() 
    end

    -- Create custom popup frame with Discord-style design
    self.CustomFontReloadPopup = CreateFrame("Frame", "PeralexBGCustomFontReloadPopup", UIParent, "BackdropTemplate")
    self.CustomFontReloadPopup:SetSize(400, 180)
    self.CustomFontReloadPopup:SetPoint("CENTER")
    self.CustomFontReloadPopup:SetFrameStrata("FULLSCREEN_DIALOG")
    self.CustomFontReloadPopup:SetFrameLevel(2000)
    self.CustomFontReloadPopup:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    self.CustomFontReloadPopup:SetBackdropColor(unpack(COLORS.BACKGROUND_DARK))
    self.CustomFontReloadPopup:SetBackdropBorderColor(unpack(COLORS.BORDER_LIGHT))
    self.CustomFontReloadPopup:SetMovable(true)
    self.CustomFontReloadPopup:EnableMouse(true)
    self.CustomFontReloadPopup:RegisterForDrag("LeftButton")
    self.CustomFontReloadPopup:SetScript("OnDragStart", function(s) s:StartMoving() end)
    self.CustomFontReloadPopup:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)

    -- Subtle gradient
    local gradient = self.CustomFontReloadPopup:CreateTexture(nil, "BACKGROUND", nil, 1)
    gradient:SetAllPoints()
    gradient:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    gradient:SetGradient("VERTICAL", CreateColor(0.08,0.08,0.08,0.8), CreateColor(0.03,0.03,0.03,0.9))

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, self.CustomFontReloadPopup, "BackdropTemplate")
    titleBar:SetSize(396, 30)
    titleBar:SetPoint("TOP", 0, -2)
    titleBar:SetFrameLevel(self.CustomFontReloadPopup:GetFrameLevel()+1)
    titleBar:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32 })
    titleBar:SetBackdropColor(unpack(COLORS.BACKGROUND_MEDIUM))

    -- Purple accent line
    local accent = titleBar:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(2)
    accent:SetTexture("Interface\\Buttons\\WHITE8x8")
    accent:SetVertexColor(unpack(COLORS.ACCENT_PURPLE))

    -- Title
    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 14, "OUTLINE")
    title:SetPoint("CENTER", 0, 5)
    title:SetText("Font Change Required")
    title:SetTextColor(unpack(COLORS.TEXT_PRIMARY))

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -8, -5)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    closeBtn:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
    closeBtn:SetBackdropBorderColor(unpack(COLORS.BORDER_DARK))

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(PE:GetFont(), 12, "OUTLINE")
    closeText:SetPoint("CENTER", 0, 1)
    closeText:SetText("X")
    closeText:SetTextColor(unpack(COLORS.TEXT_SECONDARY))

    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_HOVER))
        closeText:SetTextColor(1, 0.3, 0.3)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.BUTTON_NORMAL))
        closeText:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    end)
    
    closeBtn:SetScript("OnClick", function() 
        self.CustomFontReloadPopup:Hide()
    end)

    -- Content
    local content = self.CustomFontReloadPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content:SetPoint("TOP", titleBar, "BOTTOM", 0, -20)
    content:SetText("Changing font settings requires a UI reload to take effect.\n\nWould you like to reload now?")
    content:SetTextColor(unpack(COLORS.TEXT_SECONDARY))

    -- Button container
    local buttonContainer = CreateFrame("Frame", nil, self.CustomFontReloadPopup)
    buttonContainer:SetSize(380, 40)
    buttonContainer:SetPoint("BOTTOM", 0, 15)

    -- Cancel button
    local cancelBtn = self:CreateButton(buttonContainer, "Cancel", 100, 28)
    cancelBtn:SetPoint("LEFT", 40, 0)
    cancelBtn:SetScript("OnClick", function()
        self.CustomFontReloadPopup:Hide()
        -- Re-check the checkbox since user cancelled
        if checkbox and checkbox.checkmark then
            checkbox.checkmark:Show()
        end
    end)

    -- Reload button
    local reloadBtn = self:CreateButton(buttonContainer, "Reload UI", 100, 28)
    reloadBtn:SetPoint("RIGHT", -40, 0)
    reloadBtn:SetScript("OnClick", function()
        self.CustomFontReloadPopup:Hide()
        -- Reload the UI
        C_UI.Reload()
    end)

    -- Close on Escape
    self.CustomFontReloadPopup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    self.CustomFontReloadPopup:EnableKeyboard(true)

    self.CustomFontReloadPopup:Show()
end

-- ============================================================================
-- MIDNIGHT NOTICE WINDOW
-- ============================================================================

function PE:ShowMidnightNoticeWindow()
    -- Close existing window if open
    if self.MidnightNoticeWindow then
        self.MidnightNoticeWindow:Hide()
        self.MidnightNoticeWindow = nil
    end
    
    -- Create main window frame (same style as main config)
    local window = CreateFrame("Frame", "PeralexBGMidnightNotice", UIParent, "BackdropTemplate")
    window:SetSize(520, 480)
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:SetFrameStrata("FULLSCREEN_DIALOG")
    window:SetFrameLevel(300)
    window:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    window:SetBackdropColor(unpack(COLORS.BACKGROUND_DARK))
    window:SetBackdropBorderColor(unpack(COLORS.BORDER_LIGHT))
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetClampedToScreen(true)
    
    -- Gradient background
    local gradient = window:CreateTexture(nil, "BACKGROUND", nil, 1)
    gradient:SetAllPoints()
    gradient:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    gradient:SetGradient("VERTICAL", CreateColor(0.08, 0.08, 0.08, 0.8), CreateColor(0.03, 0.03, 0.03, 0.9))
    
    -- Purple accent line at top
    local accent = window:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 2, -2)
    accent:SetPoint("TOPRIGHT", -2, -2)
    accent:SetHeight(2)
    accent:SetColorTexture(0.55, 0.35, 0.65, 1)
    
    -- Alert icon
    local alertIcon = window:CreateTexture(nil, "OVERLAY")
    alertIcon:SetAtlas("Crosshair_Important_128")
    alertIcon:SetSize(36, 36)
    alertIcon:SetPoint("TOP", window, "TOP", -90, -18)
    
    -- Title
    local title = window:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 16, "OUTLINE")
    title:SetText("MIDNIGHT NOTICE")
    title:SetTextColor(0.8, 0.6, 1.0, 1)
    title:SetPoint("LEFT", alertIcon, "RIGHT", 10, 0)
    
    -- Divider line under title
    local divider1 = window:CreateTexture(nil, "ARTWORK")
    divider1:SetPoint("TOPLEFT", window, "TOPLEFT", 20, -60)
    divider1:SetPoint("TOPRIGHT", window, "TOPRIGHT", -20, -60)
    divider1:SetHeight(1)
    divider1:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- Message text
    local messageText = window:CreateFontString(nil, "OVERLAY")
    messageText:SetFont(PE:GetFont(), 11, "")
    messageText:SetJustifyH("LEFT")
    messageText:SetJustifyV("TOP")
    messageText:SetWidth(470)
    messageText:SetPoint("TOPLEFT", window, "TOPLEFT", 25, -75)
    messageText:SetSpacing(4)
    
    -- Format text with color coding
    local messageContent = [[|cffFFAA00In Midnight, they nuked anything and everything to do with Battlegrounds.|r There are NOT unit token ID's like arena has (arena 1/2/3), so we can no longer do basic things. If you feel inclined to help bring this to light, |cffFFDD44post on the WoW forums|r about this so we can get more eyes on it.

|cffFF6644Below are things I can NOT do no matter what currently|r |cffCCCCCC(subject to change in the future)|r

|cffFFAA00-|r I can not show actual health status, the "health" bars are simply a color matched class indicator and nothing more.

|cffFFAA00-|r Right now I am trying different ways to add Trinkets in and Flag carrier indicators, but it is very locked down and may never happen |cff8855FF(join the discord for updates)|r

|cffFFAA00-|r Even the right click Focus target is now locked down, right now you have two options in the General tab on how I got it to work so far, which is forcing you to add focus, but also auto target your last target, OR you can choose to add the focus target as Focus+Target, it is very silly but I am trying to see what else is possible.

|cffFF4444Please understand these are API/UI limitations, not on my end.|r Will continue to add what I can when I can.]]
    
    messageText:SetText(messageContent)
    
    -- Divider line above buttons
    local divider2 = window:CreateTexture(nil, "ARTWORK")
    divider2:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 20, 55)
    divider2:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -20, 55)
    divider2:SetHeight(1)
    divider2:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- Discord button (purple styled) - left side
    local discordBtn = CreateFrame("Button", nil, window)
    discordBtn:SetSize(120, 32)
    discordBtn:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 100, 15)
    
    -- Background (purple)
    local discordBg = discordBtn:CreateTexture(nil, "BACKGROUND")
    discordBg:SetAllPoints()
    discordBg:SetColorTexture(0.545, 0.271, 1.000, 1)
    
    -- Border (darker for depth)
    local discordBorder = discordBtn:CreateTexture(nil, "BORDER")
    discordBorder:SetPoint("TOPLEFT", 1, -1)
    discordBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    discordBorder:SetColorTexture(0.4, 0.2, 0.7, 1)
    
    -- Text
    local discordText = discordBtn:CreateFontString(nil, "OVERLAY")
    discordText:SetFont(PE:GetFont(), 11, "")
    discordText:SetText("Discord")
    discordText:SetTextColor(1, 1, 1, 1)
    discordText:SetPoint("CENTER")
    
    -- Hover effect
    discordBtn:SetScript("OnEnter", function()
        discordBg:SetColorTexture(0.645, 0.371, 1.000, 1)
    end)
    discordBtn:SetScript("OnLeave", function()
        discordBg:SetColorTexture(0.545, 0.271, 1.000, 1)
    end)
    
    -- Click handler
    discordBtn:SetScript("OnClick", function()
        print("|cff8B45FFPeralex BG:|r https://ACdiscord.com (Discord Link)")
        PE:ShowDiscordPopup()
    end)
    
    -- Close button (purple styled) - right side
    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(120, 32)
    closeBtn:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -100, 15)
    
    -- Background (purple)
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.545, 0.271, 1.000, 1)
    
    -- Border (darker for depth)
    local closeBorder = closeBtn:CreateTexture(nil, "BORDER")
    closeBorder:SetPoint("TOPLEFT", 1, -1)
    closeBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    closeBorder:SetColorTexture(0.4, 0.2, 0.7, 1)
    
    -- Text
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(PE:GetFont(), 11, "")
    closeText:SetText("Close")
    closeText:SetTextColor(1, 1, 1, 1)
    closeText:SetPoint("CENTER")
    
    -- Hover effect
    closeBtn:SetScript("OnEnter", function()
        closeBg:SetColorTexture(0.645, 0.371, 1.000, 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeBg:SetColorTexture(0.545, 0.271, 1.000, 1)
    end)
    
    -- Close handler
    closeBtn:SetScript("OnClick", function()
        window:Hide()
        PE.MidnightNoticeWindow = nil
    end)
    
    -- ESC key to close
    window:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            window:Hide()
            PE.MidnightNoticeWindow = nil
        end
    end)
    window:EnableKeyboard(true)
    
    -- Store reference and show
    self.MidnightNoticeWindow = window
    window:Show()
    
    -- Add to special frames for ESC closing
    tinsert(UISpecialFrames, "PeralexBGMidnightNotice")
end

-- ============================================================================
-- CHANGELOG WINDOW
-- ============================================================================

function PE:ShowChangelogWindow()
    -- Close existing window if open
    if self.ChangelogWindow then
        self.ChangelogWindow:Hide()
        self.ChangelogWindow = nil
    end
    
    -- Create main window frame (same style as Midnight Notice)
    local window = CreateFrame("Frame", "PeralexBGChangelog", UIParent, "BackdropTemplate")
    window:SetSize(520, 480)
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:SetFrameStrata("FULLSCREEN_DIALOG")
    window:SetFrameLevel(300)
    window:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    window:SetBackdropColor(unpack(COLORS.BACKGROUND_DARK))
    window:SetBackdropBorderColor(unpack(COLORS.BORDER_LIGHT))
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetClampedToScreen(true)
    
    -- Gradient background
    local gradient = window:CreateTexture(nil, "BACKGROUND", nil, 1)
    gradient:SetAllPoints()
    gradient:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    gradient:SetGradient("VERTICAL", CreateColor(0.08, 0.08, 0.08, 0.8), CreateColor(0.03, 0.03, 0.03, 0.9))
    
    -- Purple accent line at top
    local accent = window:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 2, -2)
    accent:SetPoint("TOPRIGHT", -2, -2)
    accent:SetHeight(2)
    accent:SetColorTexture(0.55, 0.35, 0.65, 1)
    
    -- Info icon
    local infoIcon = window:CreateTexture(nil, "OVERLAY")
    infoIcon:SetAtlas("Common-Icon-Small")
    infoIcon:SetSize(36, 36)
    infoIcon:SetPoint("TOP", window, "TOP", -70, -18)
    
    -- Title
    local title = window:CreateFontString(nil, "OVERLAY")
    title:SetFont(PE:GetFont(), 16, "OUTLINE")
    title:SetText("CHANGELOG")
    title:SetTextColor(0.8, 0.6, 1.0, 1)
    title:SetPoint("LEFT", infoIcon, "RIGHT", 10, 0)
    
    -- Divider line under title
    local divider1 = window:CreateTexture(nil, "ARTWORK")
    divider1:SetPoint("TOPLEFT", window, "TOPLEFT", 20, -60)
    divider1:SetPoint("TOPRIGHT", window, "TOPRIGHT", -20, -60)
    divider1:SetHeight(1)
    divider1:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- Version info with enhanced styling
    local versionInfo = window:CreateFontString(nil, "OVERLAY")
    versionInfo:SetFont(PE:GetFont(), 13, "OUTLINE")
    versionInfo:SetJustifyH("CENTER")
    versionInfo:SetText("|cffFFD700GAME VERSION:|r |cffFFFFFF12.0.x Midnight|r\n|cffFFD700ADDON VERSION:|r |cff00FF88v0.2.4|r\n|cffFFD700RELEASE DATE:|r |cffFFFFFF1/29/2026|r")
    versionInfo:SetTextColor(1, 1, 1, 1)
    versionInfo:SetPoint("TOP", window, "TOP", 0, -85)
    
    -- Divider line under version info
    local divider2 = window:CreateTexture(nil, "ARTWORK")
    divider2:SetPoint("TOPLEFT", window, "TOPLEFT", 20, -135)
    divider2:SetPoint("TOPRIGHT", window, "TOPRIGHT", -20, -135)
    divider2:SetHeight(1)
    divider2:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- Scrollable changelog area (same implementation as Appearance panel)
    local scrollFrame = CreateFrame("ScrollFrame", "PeralexBGChangelogScrollFrame", window, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 25, -155)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 60)
    
    -- Apply custom scrollbar styling (same as Appearance panel)
    self:StyleCustomScrollBar(scrollFrame)
    
    -- Create scroll child for content
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(440, 1) -- Height will be adjusted dynamically
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Enable mouse wheel scrolling (same as Appearance panel)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local bar = self.ScrollBar or _G["PeralexBGChangelogScrollFrameScrollBar"]
        if bar and bar:IsShown() then
            local current = bar:GetValue()
            local minVal, maxVal = bar:GetMinMaxValues()
            local newVal = current - (delta * 20)
            if newVal < minVal then newVal = minVal end
            if newVal > maxVal then newVal = maxVal end
            bar:SetValue(newVal)
        end
    end)
    
    -- Changelog text
    local changelogText = scrollChild:CreateFontString(nil, "OVERLAY")
    changelogText:SetFont(PE:GetFont(), 11, "")
    changelogText:SetJustifyH("CENTER")
    changelogText:SetJustifyV("TOP")
    changelogText:SetWidth(440)
    changelogText:SetPoint("TOP", scrollChild, "TOP", 0, 0)
    changelogText:SetSpacing(4)
    
    local changelogContent = [[|cff00FFFF======================================|r
|cffFFD700UPDATE v0.2.4|r
|cff00FFFF======================================|r

|A:Crosshair_Important_128:16:16:0:0|a |cffFF6B6BCRITICAL BUG FIXES|r
|cffFFFFFF- Fixed an issue with certain BGs having persisting frames when they leave the match|r
|cffFFFFFF- Fixed various error calls during the game that was due to combat issues|r
|cffFFFFFF- Fixed the Show Anchor toggle, anchors now hide correctly|r

|A:common-icon-checkmark:16:16:0:0|a |cff4ECDC4NEW FEATURE|r
|cffFFFFFF- Added clean tooltips on mouse over with detailed info on the enemy frames|r

|cff00FFFF======================================|r

|cffFFD700Previous v0.2.3|r
|cffFFFFFF- Fixed arena exclusion - frames no longer show in arenas|r
|cffFFFFFF- Fixed stale arena data appearing in main city after reload|r
|cffFFFFFF- Fixed enemy detection in Solo Blitz & mixed-faction BGs|r
|cffFFFFFF- Enhanced debug logging and protection systems|r

|cff00FFFF======================================|r

|cffFFD700Previous v0.2.2|r
|cffFFFFFF- Complete addon overhaul with performance improvements|r
|cffFFFFFF- Capping integration & new skins system|r
|cffFFFFFF- Enhanced settings & customization options|r
|cffFFFFFF- All-new settings panel with modern UI|r
|cffFFFFFF- Advanced customization options for BG frames|r
|cffFFFFFF- Improved user experience and accessibility|r
|cffFFFFFF- Added mini map icon for fast access and test mode|r
|cffFFFFFF- Brand new addon skinning system|r
|cffFFFFFF- Theme and customize your favorite addons|r
|cffFFFFFF- More mods coming soon in future updates|r
|cffFFFFFF- Additional tweaks and mods in development|r
|cffFFFFFF- Stay tuned for exciting new features!|r

|cff00FFFF======================================|r

|A:common-icon-undo:16:16:0:0|a |cff8855FFJoin our Discord Community!|r
|cffFFFFFF- Share suggestions & feedback|r
|cffFFFFFF- Report bugs & get support|r  
|cffFFFFFF- Get latest updates & sneak peeks|r

|cffFFDD44Thank you for using Peralex BG!|r]]

    changelogText:SetText(changelogContent)
    
    -- Calculate content height and update scroll child
    scrollChild:SetHeight(changelogText:GetStringHeight())
    
    -- Divider line above button
    local divider3 = window:CreateTexture(nil, "ARTWORK")
    divider3:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 20, 55)
    divider3:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -20, 55)
    divider3:SetHeight(1)
    divider3:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- Close button (purple styled) - center
    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(120, 32)
    closeBtn:SetPoint("BOTTOM", window, "BOTTOM", 0, 15)
    
    -- Background (purple)
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.545, 0.271, 1.000, 1)
    
    -- Border (darker for depth)
    local closeBorder = closeBtn:CreateTexture(nil, "BORDER")
    closeBorder:SetPoint("TOPLEFT", 1, -1)
    closeBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    closeBorder:SetColorTexture(0.4, 0.2, 0.7, 1)
    
    -- Text
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(PE:GetFont(), 11, "")
    closeText:SetText("Close")
    closeText:SetTextColor(1, 1, 1, 1)
    closeText:SetPoint("CENTER")
    
    -- Hover effect
    closeBtn:SetScript("OnEnter", function()
        closeBg:SetColorTexture(0.645, 0.371, 1.000, 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeBg:SetColorTexture(0.545, 0.271, 1.000, 1)
    end)
    
    -- Close handler
    closeBtn:SetScript("OnClick", function()
        window:Hide()
        PE.ChangelogWindow = nil
    end)
    
    -- ESC key to close
    window:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            window:Hide()
            PE.ChangelogWindow = nil
        end
    end)
    window:EnableKeyboard(true)
    
    -- Store reference and show
    self.ChangelogWindow = window
    window:Show()
    
    -- Add to special frames for ESC closing
    tinsert(UISpecialFrames, "PeralexBGChangelog")
end

