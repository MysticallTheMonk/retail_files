-- ============================================================================
-- PeralexBG - CappingSkin.lua
-- Applies custom themes to the Capping addon's timer bars
-- We do NOT modify Capping's logic - only visual skinning
-- ============================================================================

local PE = _G.PeralexBG
if not PE then return end

local CappingSkin = {}
PE.CappingSkin = CappingSkin

local isEnabled = false
local isHooked = false
local skinnedBars = {}
local fontEnforcerTimer = nil

-- ============================================================================
-- THEME DEFINITIONS
-- ============================================================================

local themes = {
    -- Default: No skinning, let Capping use its own appearance
    default = nil,
    
    -- Modern: Dark sleek design inspired by OLDBGAddon/CapTimers
    modern = {
        backdrop = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1},
        },
        backdropColor = {0.05, 0.05, 0.05, 0.9},
        backdropBorderColor = {0.15, 0.15, 0.15, 1},
        barTexture = "Interface\\Buttons\\WHITE8x8",
        barBackgroundColor = {0.1, 0.1, 0.1, 0.5},
        fontOutline = "OUTLINE",
        fontSize = 11,
        labelColor = {0.9, 0.9, 0.9, 1},
        timeColor = {0.9, 0.9, 0.9, 1},
        -- Custom colors from OLDBGAddon
        colors = {
            colorAlliance = {0.0, 0.44, 0.87, 1},
            colorHorde = {0.8, 0.2, 0.2, 1},
            colorOther = {0.6, 0.2, 0.8, 1},
            colorQueue = {0.55, 0.27, 0.68, 1},
            -- Additional Capping color types to ensure complete coverage
            colorText = {0.9, 0.9, 0.9, 1}, -- Maps to our labelColor/timeColor
            colorBarBackground = {0.1, 0.1, 0.1, 0.5}, -- Maps to our barBackgroundColor
        },
        iconBackdrop = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1},
        },
        iconBackdropColor = {0.05, 0.05, 0.05, 0.9},
        iconBackdropBorderColor = {0.2, 0.2, 0.2, 1},
        barSpacing = 2, -- Extra spacing between bars
        iconScale = 0.95, -- Scale down icons slightly
        iconGap = 4, -- Extra space between icon and bar (extends backdrop left)
    },
}

-- ============================================================================
-- BAR SKINNING
-- ============================================================================

local function SkinBar(bar)
    if not bar or skinnedBars[bar] then return end
    if not PE.DB or not PE.DB.skinMods or not PE.DB.skinMods.capping then return end
    
    local themeName = PE.DB.skinMods.capping.theme or "default"
    local theme = themes[themeName]
    
    -- If default theme or no theme, don't skin
    if not theme then return end
    
    -- Store original values for potential unskinning
    if not bar._peOriginal then
        bar._peOriginal = {
            backdrop = bar.GetBackdrop and bar:GetBackdrop(),
        }
    end
    
    -- ========================================================================
    -- OLDBGAddon STYLE: One unified dark backdrop wrapping icon + status bar
    -- The icon and bar sit INSIDE this dark frame with padding
    -- ========================================================================
    
    -- Store original icon size and position BEFORE any modifications
    if not bar._peOriginalIconSize and bar.candyBarIconFrame then
        bar._peOriginalIconSize = {bar.candyBarIconFrame:GetSize()}
        local point, relativeTo, relativePoint, xOfs, yOfs = bar.candyBarIconFrame:GetPoint(1)
        bar._peOriginalIconPoint = {point, relativeTo, relativePoint, xOfs, yOfs}
    end
    
    -- Create unified backdrop border (outermost dark edge)
    if not bar._peUnifiedBorder then
        local border = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
        bar._peUnifiedBorder = border
    end
    
    -- Create unified backdrop background (dark fill)
    if not bar._peUnifiedBg then
        local bg = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
        bar._peUnifiedBg = bg
    end
    
    -- Calculate gap offset (extends backdrop left, moves icon left)
    local iconGap = theme.iconGap or 0
    
    -- Position unified backdrop - use original icon size for consistent backdrop
    if bar._peUnifiedBorder and bar.candyBarIconFrame and bar._peOriginalIconSize then
        bar._peUnifiedBorder:ClearAllPoints()
        bar._peUnifiedBorder:SetPoint("TOPLEFT", bar.candyBarIconFrame, "TOPLEFT", -2 - iconGap, 2)
        bar._peUnifiedBorder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -2)
        bar._peUnifiedBorder:SetColorTexture(0.15, 0.15, 0.15, 1)
        bar._peUnifiedBorder:Show()
    end
    
    if bar._peUnifiedBg and bar.candyBarIconFrame and bar._peOriginalIconSize then
        bar._peUnifiedBg:ClearAllPoints()
        bar._peUnifiedBg:SetPoint("TOPLEFT", bar.candyBarIconFrame, "TOPLEFT", -1 - iconGap, 1)
        bar._peUnifiedBg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, -1)
        bar._peUnifiedBg:SetColorTexture(0.05, 0.05, 0.05, 0.9)
        bar._peUnifiedBg:Show()
    end
    
    -- Scale and reposition icon (but DO NOT modify tex coords)
    if theme.iconScale and bar.candyBarIconFrame and bar._peOriginalIconSize then
        local origW, origH = unpack(bar._peOriginalIconSize)
        local newWidth = origW * theme.iconScale
        local newHeight = origH * theme.iconScale
        
        -- Store original icon position
        if not bar._peOriginalIconPoints then
            bar._peOriginalIconPoints = {}
            for i = 1, bar.candyBarIconFrame:GetNumPoints() do
                bar._peOriginalIconPoints[i] = {bar.candyBarIconFrame:GetPoint(i)}
            end
        end
        
        -- Store original status bar position
        if not bar._peOriginalBarPoints then
            bar._peOriginalBarPoints = {}
            for i = 1, bar.candyBarBar:GetNumPoints() do
                bar._peOriginalBarPoints[i] = {bar.candyBarBar:GetPoint(i)}
            end
        end
        
        -- Resize icon maintaining original aspect ratio
        bar.candyBarIconFrame:SetSize(newWidth, newHeight)
        
        -- DO NOT modify tex coords - Capping handles all icon setup correctly
        -- Modifying tex coords breaks Horde banners, Shrine icons, etc.
        
        -- Calculate how much to move icon left to create gap
        local leftOffset = math.min(iconGap, 2) -- Cap at 2 pixels to prevent hiding icons
        
        -- Reposition icon to create gap and center it
        bar.candyBarIconFrame:ClearAllPoints()
        bar.candyBarIconFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", -leftOffset, 0)
        bar.candyBarIconFrame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", -leftOffset, 0)
        
        -- Reposition status bar to start after the gap
        bar.candyBarBar:ClearAllPoints()
        bar.candyBarBar:SetPoint("TOPLEFT", bar.candyBarIconFrame, "TOPRIGHT", iconGap, 0)
        bar.candyBarBar:SetPoint("BOTTOMLEFT", bar.candyBarIconFrame, "BOTTOMRIGHT", iconGap, 0)
        bar.candyBarBar:SetPoint("TOPRIGHT", bar)
        bar.candyBarBar:SetPoint("BOTTOMRIGHT", bar)
    end
    
    -- Skin the status bar texture with flat texture
    if bar.candyBarBar then
        bar.candyBarBar:SetStatusBarTexture(theme.barTexture)
        
        -- Apply custom color based on the bar's colorid
        local colorId = bar.Get and bar:Get("capping:colorid")
        if colorId and theme.colors and theme.colors[colorId] then
            bar.candyBarBar:SetStatusBarColor(unpack(theme.colors[colorId]))
        end
    end
    
    -- Skin background with flat texture and appropriate color
    if bar.candyBarBackground then
        bar.candyBarBackground:SetTexture(theme.barTexture)
        
        -- Check for colorBarBackground mapping first, then fallback to theme default
        local colorId = bar.Get and bar:Get("capping:colorid")
        if colorId == "colorBarBackground" and theme.colors and theme.colors[colorId] then
            bar.candyBarBackground:SetVertexColor(unpack(theme.colors[colorId]))
        else
            bar.candyBarBackground:SetVertexColor(unpack(theme.barBackgroundColor))
        end
    end
    
    -- Skin label font (only if useCustomFont is enabled)
    if bar.candyBarLabel then
        local useCustomFont = PE.DB.skinMods.capping.useCustomFont
        if useCustomFont == nil then useCustomFont = true end -- Default to true
        
        if useCustomFont then
            local fontPath = PE:GetFont()
            bar.candyBarLabel:SetFont(fontPath, theme.fontSize, theme.fontOutline)
        end
        
        -- Check for colorText mapping first, then fallback to theme default
        local colorId = bar.Get and bar:Get("capping:colorid")
        if colorId == "colorText" and theme.colors and theme.colors[colorId] then
            bar.candyBarLabel:SetTextColor(unpack(theme.colors[colorId]))
        else
            bar.candyBarLabel:SetTextColor(unpack(theme.labelColor))
        end
        bar.candyBarLabel:SetShadowOffset(1, -1)
        bar.candyBarLabel:SetShadowColor(0, 0, 0, 0.8)
    end
    
    -- Skin duration font (only if useCustomFont is enabled)
    if bar.candyBarDuration then
        local useCustomFont = PE.DB.skinMods.capping.useCustomFont
        if useCustomFont == nil then useCustomFont = true end -- Default to true
        
        if useCustomFont then
            local fontPath = PE:GetFont()
            bar.candyBarDuration:SetFont(fontPath, theme.fontSize, theme.fontOutline)
        end
        
        -- Check for colorText mapping first, then fallback to theme default
        local colorId = bar.Get and bar:Get("capping:colorid")
        if colorId == "colorText" and theme.colors and theme.colors[colorId] then
            bar.candyBarDuration:SetTextColor(unpack(theme.colors[colorId]))
        else
            bar.candyBarDuration:SetTextColor(unpack(theme.timeColor))
        end
        bar.candyBarDuration:SetShadowOffset(1, -1)
        bar.candyBarDuration:SetShadowColor(0, 0, 0, 0.8)
    end
    
    skinnedBars[bar] = true
end

local function UnskinBar(bar)
    if not bar or not skinnedBars[bar] then return end
    
    -- Hide unified backdrop textures
    if bar._peUnifiedBorder then
        bar._peUnifiedBorder:Hide()
        bar._peUnifiedBorder = nil
    end
    
    if bar._peUnifiedBg then
        bar._peUnifiedBg:Hide()
        bar._peUnifiedBg = nil
    end
    
    if bar._peIconGapTexture then
        bar._peIconGapTexture:Hide()
        bar._peIconGapTexture = nil
    end
    
    -- Restore original icon and bar positions
    if bar._peOriginalIconPoints and bar.candyBarIconFrame then
        bar.candyBarIconFrame:ClearAllPoints()
        for i, point in ipairs(bar._peOriginalIconPoints) do
            bar.candyBarIconFrame:SetPoint(point[1], point[2], point[3], point[4], point[5])
        end
        bar._peOriginalIconPoints = nil
    end
    
    if bar._peOriginalBarPoints and bar.candyBarBar then
        bar.candyBarBar:ClearAllPoints()
        for i, point in ipairs(bar._peOriginalBarPoints) do
            bar.candyBarBar:SetPoint(point[1], point[2], point[3], point[4], point[5])
        end
        bar._peOriginalBarPoints = nil
    end
    
    -- Restore original icon size
    if bar._peOriginalIconSize and bar.candyBarIconFrame then
        bar.candyBarIconFrame:SetSize(unpack(bar._peOriginalIconSize))
        bar._peOriginalIconSize = nil
    end
    
    -- We no longer modify tex coords, so no need to restore them
    -- This prevents breaking Horde banners, Shrine icons, etc.
    
    if bar._peOriginalIconPoint and bar.candyBarIconFrame then
        bar.candyBarIconFrame:ClearAllPoints()
        local point, relativeTo, relativePoint, xOfs, yOfs = unpack(bar._peOriginalIconPoint)
        bar.candyBarIconFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        bar._peOriginalIconPoint = nil
    end
    
    -- Restore original if we have it
    if bar._peOriginal then
        bar._peOriginal = nil
    end
    
    skinnedBars[bar] = nil
end

-- ============================================================================
-- CAPPING LOCK ANCHOR SKINNING
-- ============================================================================

-- Capping's default anchor colors (from Core.lua line 790)
local CAPPING_DEFAULT_BG_COLOR = {0, 1, 0, 0.3} -- Green

local anchorSkinTicker = nil

local function SkinCappingLockAnchor()
    if not CappingFrame then return false end
    if not PE.DB or not PE.DB.skinMods or not PE.DB.skinMods.capping then return false end
    
    -- If header doesn't exist yet, return false to signal retry needed
    if not CappingFrame.header then
        return false
    end
    
    -- Store original anchor appearance (only header font, bg color is known)
    if not CappingFrame._peOriginalAnchor then
        CappingFrame._peOriginalAnchor = {}
        
        -- Store original header font/color
        local font, size, flags = CappingFrame.header:GetFont()
        CappingFrame._peOriginalAnchor.headerFont = font
        CappingFrame._peOriginalAnchor.headerSize = size
        CappingFrame._peOriginalAnchor.headerFlags = flags
        CappingFrame._peOriginalAnchor.headerColor = {CappingFrame.header:GetTextColor()}
    end
    
    -- Apply dark theme to anchor
    if CappingFrame.bg then
        CappingFrame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.9)
    end
    
    local useCustomFont = PE.DB.skinMods.capping.useCustomFont
    if useCustomFont == nil then useCustomFont = true end
    
    if useCustomFont then
        local fontPath = PE:GetFont()
        CappingFrame.header:SetFont(fontPath, 11, "OUTLINE")
    end
    CappingFrame.header:SetTextColor(0.6, 0.2, 0.8, 1) -- Purple accent
    CappingFrame.header:SetText("Capping")
    
    PE:Debug("CappingSkin: Anchor skinned")
    return true
end

local function StartAnchorSkinRetry()
    -- Stop any existing ticker
    if anchorSkinTicker then
        anchorSkinTicker:Cancel()
        anchorSkinTicker = nil
    end
    
    -- Try immediately
    if SkinCappingLockAnchor() then return end
    
    -- Poll every 0.5s for up to 10 seconds waiting for header to exist
    local attempts = 0
    anchorSkinTicker = C_Timer.NewTicker(0.5, function()
        attempts = attempts + 1
        if SkinCappingLockAnchor() or attempts >= 20 then
            if anchorSkinTicker then
                anchorSkinTicker:Cancel()
                anchorSkinTicker = nil
            end
            if attempts >= 20 then
                PE:Debug("CappingSkin: Anchor skin retry timed out")
            end
        end
    end)
end

local function UnskinCappingLockAnchor()
    if not CappingFrame then return end
    
    -- Restore original bg color (always use Capping's default green)
    if CappingFrame.bg then
        CappingFrame.bg:SetColorTexture(unpack(CAPPING_DEFAULT_BG_COLOR))
    end
    
    -- Restore original header font/color
    if CappingFrame.header and CappingFrame._peOriginalAnchor then
        if CappingFrame._peOriginalAnchor.headerFont then
            CappingFrame.header:SetFont(
                CappingFrame._peOriginalAnchor.headerFont,
                CappingFrame._peOriginalAnchor.headerSize,
                CappingFrame._peOriginalAnchor.headerFlags
            )
        end
        if CappingFrame._peOriginalAnchor.headerColor then
            CappingFrame.header:SetTextColor(unpack(CappingFrame._peOriginalAnchor.headerColor))
        end
    end
    
    CappingFrame._peOriginalAnchor = nil
    PE:Debug("CappingSkin: Anchor unskinned")
end

-- ============================================================================
-- FONT ENFORCER (Aggressive queue bar font override)
-- ============================================================================

local function EnforceQueueBarFonts()
    if not isEnabled or not CappingFrame or not CappingFrame.bars then return end
    
    local useCustomFont = PE.DB.skinMods.capping.useCustomFont
    if useCustomFont == nil then useCustomFont = true end
    if not useCustomFont then return end
    
    local themeName = PE.DB.skinMods.capping.theme or "modern"
    local theme = themes[themeName]
    if not theme then return end
    
    local fontPath = PE:GetFont()
    local queueBarsFound = 0
    
    for bar in pairs(CappingFrame.bars) do
        if bar and bar:IsVisible() then
            local colorId = bar:Get("capping:colorid")
            -- Target queue bars (colorQueue), battle begins bars (colorOther), and final score bars (colorHorde/colorAlliance)
            if colorId == "colorQueue" or colorId == "colorOther" or colorId == "colorHorde" or colorId == "colorAlliance" then
                queueBarsFound = queueBarsFound + 1
                
                -- Apply full skinning if not already skinned
                if not skinnedBars[bar] then
                    SkinBar(bar)
                    PE:Debug("CappingSkin: Applied full skin to unskinned bar: " .. (bar.candyBarLabel:GetText() or "Unknown") .. " (" .. colorId .. ")")
                end
                
                -- Also enforce font specifically
                local labelFont, labelSize, labelFlags = bar.candyBarLabel:GetFont()
                local durationFont, durationSize, durationFlags = bar.candyBarDuration:GetFont()
                
                -- Check if font is not our custom font, then fix it
                if labelFont ~= fontPath or durationFont ~= fontPath then
                    if bar.candyBarLabel then
                        bar.candyBarLabel:SetFont(fontPath, theme.fontSize, theme.fontOutline)
                    end
                    if bar.candyBarDuration then
                        bar.candyBarDuration:SetFont(fontPath, theme.fontSize, theme.fontOutline)
                    end
                    local barText = bar.candyBarLabel:GetText() or "Unknown"
                    PE:Debug("CappingSkin: Fixed custom font to bar: " .. barText .. " (" .. colorId .. ")")
                end
            end
        end
    end
    
    -- If no queue bars found for 10 seconds, reduce timer frequency
    if queueBarsFound == 0 then
        if fontEnforcerTimer then
            fontEnforcerTimer.cooldown = 1.0 -- Check every 1 second when no queue bars
        end
    else
        if fontEnforcerTimer then
            fontEnforcerTimer.cooldown = 0.25 -- Check frequently when queue bars exist
        end
    end
end

-- ============================================================================
-- CAPPING HOOKS
-- ============================================================================

local function HookCapping()
    if isHooked then return end
    
    -- Check if Capping is loaded
    if not CappingFrame then
        PE:Debug("CappingSkin: CappingFrame not found")
        return false
    end
    
    -- Hook into Capping's AceDB profile change events
    if CappingFrame.db and CappingFrame.db.RegisterCallback then
        -- Capping calls ReloadUI() on these events, so we need to re-apply after reload
        CappingFrame.db.RegisterCallback(CappingSkin, "OnProfileChanged", function()
            PE:Debug("CappingSkin: Capping profile changed - will re-apply after reload")
        end)
        CappingFrame.db.RegisterCallback(CappingSkin, "OnProfileCopied", function()
            PE:Debug("CappingSkin: Capping profile copied - will re-apply after reload")
        end)
        CappingFrame.db.RegisterCallback(CappingSkin, "OnProfileReset", function()
            PE:Debug("CappingSkin: Capping profile reset - will re-apply after reload")
        end)
        PE:Debug("CappingSkin: Hooked Capping AceDB profile events")
    end
    
    -- Hook into LibCandyBar callbacks if available
    local candy = LibStub and LibStub("LibCandyBar-3.0", true)
    if candy then
        -- Hook the bar creation/start
        candy.RegisterCallback(CappingSkin, "LibCandyBar_Start", function(_, bar)
            if isEnabled and bar then
                -- Delay slightly to let Capping finish setting up the bar
                C_Timer.After(0.01, function()
                    if bar and bar:IsVisible() then
                        -- Apply full skinning to all bars (regardless of color type)
                        SkinBar(bar)
                        
                        -- Force font override again after a short delay to ensure it sticks
                        C_Timer.After(0.05, function()
                            if bar and bar:IsVisible() then
                                local useCustomFont = PE.DB.skinMods.capping.useCustomFont
                                if useCustomFont == nil then useCustomFont = true end
                                if useCustomFont then
                                    local themeName = PE.DB.skinMods.capping.theme or "modern"
                                    local theme = themes[themeName]
                                    if theme then
                                        local fontPath = PE:GetFont()
                                        if bar.candyBarLabel then
                                            bar.candyBarLabel:SetFont(fontPath, theme.fontSize, theme.fontOutline)
                                        end
                                        if bar.candyBarDuration then
                                            bar.candyBarDuration:SetFont(fontPath, theme.fontSize, theme.fontOutline)
                                        end
                                    end
                                end
                            end
                        end)
                        -- Additional font override specifically for queue bars (colorQueue), battle begins bars (colorOther), and final score bars (colorHorde/colorAlliance)
                        C_Timer.After(0.1, function()
                            if bar and bar:IsVisible() then
                                local colorId = bar:Get("capping:colorid")
                                if colorId == "colorQueue" or colorId == "colorOther" or colorId == "colorHorde" or colorId == "colorAlliance" then
                                    local useCustomFont = PE.DB.skinMods.capping.useCustomFont
                                    if useCustomFont == nil then useCustomFont = true end
                                    if useCustomFont then
                                        local themeName = PE.DB.skinMods.capping.theme or "modern"
                                        local theme = themes[themeName]
                                        if theme then
                                            local fontPath = PE:GetFont()
                                            if bar.candyBarLabel then
                                                bar.candyBarLabel:SetFont(fontPath, theme.fontSize, theme.fontOutline)
                                            end
                                            if bar.candyBarDuration then
                                                bar.candyBarDuration:SetFont(fontPath, theme.fontSize, theme.fontOutline)
                                            end
                                            local barText = bar.candyBarLabel:GetText() or "Unknown"
                                            PE:Debug("CappingSkin: Applied custom font to bar: " .. barText .. " (" .. colorId .. ")")
                                        end
                                    end
                                end
                            end
                        end)
                    end
                end)
            end
        end)
        
        candy.RegisterCallback(CappingSkin, "LibCandyBar_Stop", function(_, bar)
            if bar then
                skinnedBars[bar] = nil
            end
        end)
        
        PE:Debug("CappingSkin: Hooked LibCandyBar callbacks")
    end
    
    -- Direct hook into Capping's StartBar function for immediate skinning
    if CappingFrame.StartBar and not CappingFrame._peStartBarHooked then
        local originalStartBar = CappingFrame.StartBar
        CappingFrame.StartBar = function(self, name, remaining, icon, colorid, priority, maxBarTime)
            -- Call original function first
            local bar = originalStartBar(self, name, remaining, icon, colorid, priority, maxBarTime)
            
            -- Immediately skin the returned bar if enabled
            if isEnabled and bar then
                C_Timer.After(0.01, function()
                    if bar and bar:IsVisible() then
                        -- Apply full skinning to all bars
                        SkinBar(bar)
                        PE:Debug("CappingSkin: Immediately skinned bar from StartBar hook: " .. (name or "Unknown") .. " (" .. (colorid or "Unknown") .. ")")
                    end
                end)
            end
            
            return bar
        end
        CappingFrame._peStartBarHooked = true
        PE:Debug("CappingSkin: Hooked Capping StartBar function")
    end
    
    -- Also hook the Capping frame's bar table to catch existing bars
    if CappingFrame.bars then
        -- Skin any existing bars
        for bar in pairs(CappingFrame.bars) do
            if isEnabled then
                SkinBar(bar)
            end
        end
    end
    
    -- Hook Capping's RearrangeBars to catch bars after rearrangement and add spacing
    if CappingFrame.RearrangeBars then
        hooksecurefunc(CappingFrame, "RearrangeBars", function()
            if isEnabled and CappingFrame.bars then
                local themeName = PE.DB and PE.DB.skinMods and PE.DB.skinMods.capping and PE.DB.skinMods.capping.theme or "default"
                local theme = themes[themeName]
                
                for bar in pairs(CappingFrame.bars) do
                    SkinBar(bar)
                    
                    -- Add extra spacing offset for modern theme
                    if theme and theme.barSpacing then
                        local point, relativeTo, relativePoint, xOfs, yOfs = bar:GetPoint(1)
                        if point and relativeTo and yOfs then
                            -- Adjust vertical offset for spacing
                            local extraSpacing = theme.barSpacing
                            if point == "TOPLEFT" or point == "TOP" or point == "TOPRIGHT" then
                                bar:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs - extraSpacing)
                            elseif point == "BOTTOMLEFT" or point == "BOTTOM" or point == "BOTTOMRIGHT" then
                                bar:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs + extraSpacing)
                            end
                        end
                    end
                    
                    -- Force font override for queue bars (colorQueue), battle begins bars (colorOther), and final score bars (colorHorde/colorAlliance) after rearrangement
                    local colorId = bar:Get("capping:colorid")
                    if colorId == "colorQueue" or colorId == "colorOther" or colorId == "colorHorde" or colorId == "colorAlliance" then
                        local useCustomFont = PE.DB.skinMods.capping.useCustomFont
                        if useCustomFont == nil then useCustomFont = true end
                        if useCustomFont and theme then
                            local fontPath = PE:GetFont()
                            if bar.candyBarLabel then
                                bar.candyBarLabel:SetFont(fontPath, theme.fontSize, theme.fontOutline)
                            end
                            if bar.candyBarDuration then
                                bar.candyBarDuration:SetFont(fontPath, theme.fontSize, theme.fontOutline)
                            end
                        end
                    end
                end
            end
        end)
        PE:Debug("CappingSkin: Hooked RearrangeBars")
    end
    
    isHooked = true
    return true
end

-- ============================================================================
-- CAPPING SETTINGS MANAGEMENT
-- ============================================================================

-- Capping's exact default values from Core.lua lines 744-775
local CAPPING_DEFAULTS = {
    spacing = 0,
    outline = "NONE",
    barTexture = "Blizzard Raid Bar",
    font = "Friz Quadrata TT",
    fontSize = 10,
    colorText = {1, 1, 1, 1},           -- white
    colorAlliance = {0, 0, 1, 1},       -- blue
    colorHorde = {1, 0, 0, 1},          -- red
    colorQueue = {0.6, 0.6, 0.6, 1},    -- gray
    colorOther = {1, 1, 0, 1},          -- yellow
    colorBarBackground = {0, 0, 0, 0.75}, -- black
}

-- Settings we override for Modern theme
local modernCappingSettings = {
    spacing = 3,
    outline = "OUTLINE",
    barTexture = "Blizzard",
    font = "Friz Quadrata TT",
    fontSize = 10,
    colorBarBackground = {0.1, 0.1, 0.1, 0.5},
    colorText = {0.9, 0.9, 0.9, 1},
    colorAlliance = {0.0, 0.44, 0.87, 1},
    colorHorde = {0.8, 0.2, 0.2, 1},
    colorOther = {0.6, 0.2, 0.8, 1},
    colorQueue = {0.55, 0.27, 0.68, 1},
}

local function ApplyCappingSettings(settings)
    if not CappingFrame or not CappingFrame.db or not CappingFrame.db.profile then return end
    
    local profile = CappingFrame.db.profile
    for key, value in pairs(settings) do
        if value ~= nil then
            -- Deep copy tables (colors)
            if type(value) == "table" then
                profile[key] = {unpack(value)}
            else
                profile[key] = value
            end
        end
    end
    
    -- Trigger Capping to rearrange bars with new settings
    if CappingFrame.RearrangeBars then
        CappingFrame:RearrangeBars()
    end
end

local function RestoreCappingSettings()
    if not CappingFrame or not CappingFrame.db or not CappingFrame.db.profile then 
        PE:Debug("CappingSkin: CappingFrame.db.profile not available for restore")
        return 
    end
    
    PE:Debug("CappingSkin: Restoring to Capping defaults...")
    ApplyCappingSettings(CAPPING_DEFAULTS)
    PE:Debug("CappingSkin: Restored Capping settings to defaults")
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function CappingSkin:Enable()
    if not PE.DB or not PE.DB.skinMods or not PE.DB.skinMods.capping then return end
    
    local cappingLoaded = C_AddOns.IsAddOnLoaded("Capping")
    if not cappingLoaded then
        PE:Debug("CappingSkin: Capping not loaded, cannot enable")
        return
    end
    
    -- Hook into Capping
    HookCapping()
    
    -- Set enabled flag
    isEnabled = true
    
    -- Start font enforcer timer for queue bars
    if not fontEnforcerTimer then
        fontEnforcerTimer = CreateFrame("Frame", "PeralexBGFontEnforcer")
        fontEnforcerTimer.cooldown = 0
        fontEnforcerTimer:SetScript("OnUpdate", function(self, elapsed)
            self.cooldown = self.cooldown - elapsed
            if self.cooldown <= 0 then
                EnforceQueueBarFonts()
                self.cooldown = 0.5 -- Check every 0.5 seconds initially
            end
        end)
        PE:Debug("CappingSkin: Font enforcer timer started")
    end
    
    -- Apply theme settings
    self:ApplyTheme()
    
    -- Skin Capping lock anchor (with retry for fresh login)
    StartAnchorSkinRetry()
    
    -- Skin existing bars
    if CappingFrame and CappingFrame.bars then
        for bar in next, CappingFrame.bars do
            SkinBar(bar)
        end
    end
    
    PE:Debug("CappingSkin: Enabled")
end

function CappingSkin:Disable()
    isEnabled = false
    
    -- Stop font enforcer timer
    if fontEnforcerTimer then
        fontEnforcerTimer:SetScript("OnUpdate", nil)
        fontEnforcerTimer:Hide()
        fontEnforcerTimer = nil
        PE:Debug("CappingSkin: Font enforcer timer stopped")
    end
    
    -- Unskin all bars FIRST (before restoring settings)
    for bar in pairs(skinnedBars) do
        UnskinBar(bar)
    end
    
    -- Unskin Capping lock anchor
    UnskinCappingLockAnchor()
    
    -- Restore original Capping settings
    RestoreCappingSettings()
    
    PE:Debug("CappingSkin: Disabled")
end


function CappingSkin:ApplyTheme()
    if not isEnabled then return end
    if not CappingFrame or not CappingFrame.db or not CappingFrame.db.profile then return end
    
    local themeName = PE.DB.skinMods.capping.theme or "default"
    PE:Debug("CappingSkin: Applying theme - " .. themeName)
    
    if themeName == "modern" then
        -- Apply modern theme settings to Capping
        ApplyCappingSettings(modernCappingSettings)
    elseif themeName == "default" then
        -- Restore to Capping defaults
        RestoreCappingSettings()
    end
    
    -- Force clear skinned bars cache to ensure fresh skinning
    for bar in pairs(skinnedBars) do
        skinnedBars[bar] = nil
    end
    
    -- Re-skin all active Capping bars with multiple attempts
    local function SkinAllBars(attempt)
        attempt = attempt or 1
        local barsSkinned = 0
        
        if CappingFrame.bars then
            for bar in pairs(CappingFrame.bars) do
                if bar and not skinnedBars[bar] then
                    SkinBar(bar)
                    barsSkinned = barsSkinned + 1
                end
            end
        end
        
        PE:Debug("CappingSkin: Skinned " .. barsSkinned .. " bars (attempt " .. attempt .. ")")
        
        -- If we found new bars, try again to catch any that might have been created
        if barsSkinned > 0 and attempt < 3 then
            C_Timer.After(0.1, function()
                SkinAllBars(attempt + 1)
            end)
        end
    end
    
    -- Start the aggressive skinning process
    SkinAllBars()
    
    -- Also skin the anchor (with retry for fresh login)
    StartAnchorSkinRetry()
    
    PE:Debug("CappingSkin: Theme applied - " .. themeName)
end

function CappingSkin:Initialize()
    if not PE.DB or not PE.DB.skinMods or not PE.DB.skinMods.capping then return end
    
    -- Try to enable if setting is on
    local function TryEnable()
        if not PE.DB.skinMods.capping.enabled then return end
        
        local cappingLoaded = C_AddOns.IsAddOnLoaded("Capping")
        if cappingLoaded and CappingFrame then
            self:Enable()
            return true
        end
        return false
    end
    
    -- Try immediately
    if TryEnable() then return end
    
    -- Try after 1 second (Capping might load late)
    C_Timer.After(1, function()
        if TryEnable() then return end
        
        -- Try again after 3 seconds as final fallback
        C_Timer.After(2, TryEnable)
    end)
    
    -- Also re-apply when entering a battleground (Capping creates bars then)
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    eventFrame:SetScript("OnEvent", function(self, event)
        if PE.DB.skinMods.capping.enabled then
            PE:Debug("CappingSkin: Event triggered - " .. event)
            
            -- Always try to enable first (in case it's not enabled yet)
            if not isEnabled then
                local cappingLoaded = C_AddOns.IsAddOnLoaded("Capping")
                if cappingLoaded and CappingFrame then
                    self:Enable()
                end
            end
            
            -- Re-apply settings with multiple delays to catch all bar creation timings
            C_Timer.After(0.5, function()
                if isEnabled then
                    self:ApplyTheme()
                    PE:Debug("CappingSkin: Re-applied theme (0.5s delay)")
                end
            end)
            
            C_Timer.After(1.0, function()
                if isEnabled then
                    self:ApplyTheme()
                    PE:Debug("CappingSkin: Re-applied theme (1.0s delay)")
                end
            end)
            
            C_Timer.After(2.0, function()
                if isEnabled then
                    self:ApplyTheme()
                    PE:Debug("CappingSkin: Re-applied theme (2.0s delay)")
                end
            end)
        end
    end)
end

-- ============================================================================
-- ANCHOR SKINNING (Optional - skin the Capping anchor frame)
-- ============================================================================

function CappingSkin:SkinAnchor()
    if not CappingFrame then return end
    if not PE.DB or not PE.DB.skinMods or not PE.DB.skinMods.capping then return end
    
    local themeName = PE.DB.skinMods.capping.theme or "default"
    local theme = themes[themeName]
    
    if not theme then return end
    
    -- Skin the anchor frame background
    if CappingFrame.bg then
        CappingFrame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.8)
    end
    
    -- Skin the anchor header text
    if CappingFrame.header then
        local fontPath = PE:GetFont()
        CappingFrame.header:SetFont(fontPath, 10, "OUTLINE")
        CappingFrame.header:SetTextColor(0.6, 0.2, 0.8, 1)
    end
end
