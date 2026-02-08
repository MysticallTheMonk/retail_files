-- ============================================================================
-- Peralex BG - EnemyFrame.lua (Visual Design Only)
-- Individual enemy frame template with ArenaCore-inspired styling
-- NO FUNCTIONAL LOGIC - Visual design reference only
-- ============================================================================

local PE = _G.PeralexBG

-- ============================================================================
-- COLORS (Visual Design Reference)
-- ============================================================================

local COLORS = {
    BACKGROUND = {0.05, 0.05, 0.05, 0.9},
    BORDER = {0.15, 0.15, 0.15, 1},
    BORDER_HIGHLIGHT = {0.6, 0.2, 0.8, 1},
    HEALTH_DEFAULT = {0.2, 0.8, 0.2},
    HEALTH_LOW = {0.8, 0.2, 0.2},
    RESOURCE_MANA = {0.0, 0.44, 0.87},
    RESOURCE_RAGE = {0.8, 0.2, 0.2},
    RESOURCE_ENERGY = {1.0, 0.96, 0.41},
    RESOURCE_FOCUS = {1.0, 0.5, 0.25},
    RESOURCE_RUNIC = {0.0, 0.82, 1.0},
    TEXT_PRIMARY = {0.9, 0.9, 0.9},
    TEXT_SECONDARY = {0.7, 0.7, 0.7},
    TARGET_HIGHLIGHT = {1.0, 0.84, 0.0, 0.8},
    FOCUS_HIGHLIGHT = {0.6, 0.2, 0.8, 0.8},
    DEAD = {0.3, 0.3, 0.3},
}

-- Power type colors
local POWER_COLORS = {
    [0] = COLORS.RESOURCE_MANA,      -- Mana
    [1] = COLORS.RESOURCE_RAGE,      -- Rage
    [2] = COLORS.RESOURCE_FOCUS,     -- Focus
    [3] = COLORS.RESOURCE_ENERGY,    -- Energy
    [6] = COLORS.RESOURCE_RUNIC,     -- Runic Power
}

-- ============================================================================
-- FRAME CREATION
-- SecureUnitButtonTemplate enables macro execution for targeting
-- ============================================================================

function PE:CreateEnemyFrame(index)
    local db = self.DB
    local width = db.frames.width
    local height = db.frames.height
    
    local frame = CreateFrame("Button", "PeralexEnemiesFrame" .. index, UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame:SetIgnoreParentAlpha(true)
    
    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    frame:SetBackdropColor(unpack(COLORS.BACKGROUND))
    frame:SetBackdropBorderColor(unpack(COLORS.BORDER))
    
    -- Class icon
    frame.classIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.classIcon:SetSize(height - 4, height - 4)
    frame.classIcon:SetPoint("LEFT", 2, 0)
    frame.classIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
    
    -- Spec icon (outside frame, to the left)
    frame.specIconFrame = CreateFrame("Frame", nil, frame)
    frame.specIconFrame:SetSize(db.specIcons.size or 20, db.specIcons.size or 20)
    frame.specIconFrame:SetPoint("RIGHT", frame, "LEFT", db.specIcons.xOffset or -2, db.specIcons.yOffset or 0)
    
    -- ArenaCore-style black borders for spec icon
    local specBorderThickness = 2
    local specBorderTop = frame.specIconFrame:CreateTexture(nil, "OVERLAY")
    specBorderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
    specBorderTop:SetVertexColor(0, 0, 0, 1)
    specBorderTop:SetPoint("TOPLEFT", frame.specIconFrame, "TOPLEFT", 0, 0)
    specBorderTop:SetPoint("TOPRIGHT", frame.specIconFrame, "TOPRIGHT", 0, 0)
    specBorderTop:SetHeight(specBorderThickness)
    
    local specBorderBottom = frame.specIconFrame:CreateTexture(nil, "OVERLAY")
    specBorderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    specBorderBottom:SetVertexColor(0, 0, 0, 1)
    specBorderBottom:SetPoint("BOTTOMLEFT", frame.specIconFrame, "BOTTOMLEFT", 0, 0)
    specBorderBottom:SetPoint("BOTTOMRIGHT", frame.specIconFrame, "BOTTOMRIGHT", 0, 0)
    specBorderBottom:SetHeight(specBorderThickness)
    
    local specBorderLeft = frame.specIconFrame:CreateTexture(nil, "OVERLAY")
    specBorderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
    specBorderLeft:SetVertexColor(0, 0, 0, 1)
    specBorderLeft:SetPoint("TOPLEFT", frame.specIconFrame, "TOPLEFT", 0, 0)
    specBorderLeft:SetPoint("BOTTOMLEFT", frame.specIconFrame, "BOTTOMLEFT", 0, 0)
    specBorderLeft:SetWidth(specBorderThickness)
    
    local specBorderRight = frame.specIconFrame:CreateTexture(nil, "OVERLAY")
    specBorderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
    specBorderRight:SetVertexColor(0, 0, 0, 1)
    specBorderRight:SetPoint("TOPRIGHT", frame.specIconFrame, "TOPRIGHT", 0, 0)
    specBorderRight:SetPoint("BOTTOMRIGHT", frame.specIconFrame, "BOTTOMRIGHT", 0, 0)
    specBorderRight:SetWidth(specBorderThickness)
    
    frame.specIcon = frame.specIconFrame:CreateTexture(nil, "ARTWORK")
    frame.specIcon:SetPoint("TOPLEFT", 1, -1)
    frame.specIcon:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.specIconFrame:Hide()
    
    -- Health bar container (dynamically sized based on trinket visibility)
    local healthContainer = CreateFrame("Frame", nil, frame)
    local rightOffset = db.trinkets.enabled and -28 or -2
    healthContainer:SetPoint("TOPLEFT", frame.classIcon, "TOPRIGHT", 2, 0)
    healthContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", rightOffset, 2)
    frame.healthContainer = healthContainer
    
    -- Health bar background
    frame.healthBg = healthContainer:CreateTexture(nil, "BACKGROUND")
    frame.healthBg:SetAllPoints()
    frame.healthBg:SetTexture(db.appearance.healthBarTexture)
    frame.healthBg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- Health bar
    frame.healthBar = CreateFrame("StatusBar", nil, healthContainer)
    frame.healthBar:SetAllPoints()
    frame.healthBar:SetStatusBarTexture(db.appearance.healthBarTexture)
    frame.healthBar:SetMinMaxValues(0, 100)
    frame.healthBar:SetValue(100)
    
    -- Resource bar removed (can't track in real-time in Midnight 12.0)
    
    -- Player name
    frame.nameText = frame.healthBar:CreateFontString(nil, "OVERLAY")
    frame.nameText:SetFont(self:GetFont(), 11, "OUTLINE")
    frame.nameText:SetPoint("LEFT", 4, 0)
    frame.nameText:SetTextColor(unpack(COLORS.TEXT_PRIMARY))
    frame.nameText:SetJustifyH("LEFT")
    frame.nameText:SetWidth(width - 80)
    frame.nameText:SetWordWrap(false)
    
    -- Health text
    frame.healthText = frame.healthBar:CreateFontString(nil, "OVERLAY")
    frame.healthText:SetFont(self:GetFont(), 10, "OUTLINE")
    frame.healthText:SetPoint("RIGHT", -4, 0)
    frame.healthText:SetTextColor(unpack(COLORS.TEXT_SECONDARY))
    frame.healthText:SetJustifyH("RIGHT")
    
    -- Trinket icon
    frame.trinketFrame = CreateFrame("Frame", nil, frame)
    frame.trinketFrame:SetSize(db.trinkets.size or 24, db.trinkets.size or 24)
    frame.trinketFrame:SetPoint("RIGHT", -2, 0)
    
    -- ArenaCore-style black borders for trinket
    local borderThickness = 2
    local trinketBorderTop = frame.trinketFrame:CreateTexture(nil, "OVERLAY")
    trinketBorderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
    trinketBorderTop:SetVertexColor(0, 0, 0, 1)
    trinketBorderTop:SetPoint("TOPLEFT", frame.trinketFrame, "TOPLEFT", 0, 0)
    trinketBorderTop:SetPoint("TOPRIGHT", frame.trinketFrame, "TOPRIGHT", 0, 0)
    trinketBorderTop:SetHeight(borderThickness)
    
    local trinketBorderBottom = frame.trinketFrame:CreateTexture(nil, "OVERLAY")
    trinketBorderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    trinketBorderBottom:SetVertexColor(0, 0, 0, 1)
    trinketBorderBottom:SetPoint("BOTTOMLEFT", frame.trinketFrame, "BOTTOMLEFT", 0, 0)
    trinketBorderBottom:SetPoint("BOTTOMRIGHT", frame.trinketFrame, "BOTTOMRIGHT", 0, 0)
    trinketBorderBottom:SetHeight(borderThickness)
    
    local trinketBorderLeft = frame.trinketFrame:CreateTexture(nil, "OVERLAY")
    trinketBorderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
    trinketBorderLeft:SetVertexColor(0, 0, 0, 1)
    trinketBorderLeft:SetPoint("TOPLEFT", frame.trinketFrame, "TOPLEFT", 0, 0)
    trinketBorderLeft:SetPoint("BOTTOMLEFT", frame.trinketFrame, "BOTTOMLEFT", 0, 0)
    trinketBorderLeft:SetWidth(borderThickness)
    
    local trinketBorderRight = frame.trinketFrame:CreateTexture(nil, "OVERLAY")
    trinketBorderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
    trinketBorderRight:SetVertexColor(0, 0, 0, 1)
    trinketBorderRight:SetPoint("TOPRIGHT", frame.trinketFrame, "TOPRIGHT", 0, 0)
    trinketBorderRight:SetPoint("BOTTOMRIGHT", frame.trinketFrame, "BOTTOMRIGHT", 0, 0)
    trinketBorderRight:SetWidth(borderThickness)
    
    frame.trinketIcon = frame.trinketFrame:CreateTexture(nil, "ARTWORK")
    frame.trinketIcon:SetPoint("TOPLEFT", 1, -1)
    frame.trinketIcon:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.trinketIcon:SetTexture(1322720) -- PvP Trinket icon
    
    frame.trinketCooldown = CreateFrame("Cooldown", nil, frame.trinketFrame, "CooldownFrameTemplate")
    frame.trinketCooldown:SetAllPoints(frame.trinketIcon)
    frame.trinketCooldown:SetDrawEdge(false)
    frame.trinketCooldown:SetHideCountdownNumbers(false)
    frame.trinketCooldown.noCooldownCount = true
    
    -- Flag carrier icon
    frame.flagIconFrame = CreateFrame("Frame", nil, frame)
    frame.flagIconFrame:SetSize(db.flags.size or 24, db.flags.size or 24)
    frame.flagIconFrame:SetPoint("LEFT", frame.trinketFrame, "RIGHT", 2, 0)
    
    -- ArenaCore-style black borders for flag
    local flagBorderThickness = 2
    local flagBorderTop = frame.flagIconFrame:CreateTexture(nil, "OVERLAY")
    flagBorderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
    flagBorderTop:SetVertexColor(0, 0, 0, 1)
    flagBorderTop:SetPoint("TOPLEFT", frame.flagIconFrame, "TOPLEFT", 0, 0)
    flagBorderTop:SetPoint("TOPRIGHT", frame.flagIconFrame, "TOPRIGHT", 0, 0)
    flagBorderTop:SetHeight(flagBorderThickness)
    
    local flagBorderBottom = frame.flagIconFrame:CreateTexture(nil, "OVERLAY")
    flagBorderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    flagBorderBottom:SetVertexColor(0, 0, 0, 1)
    flagBorderBottom:SetPoint("BOTTOMLEFT", frame.flagIconFrame, "BOTTOMLEFT", 0, 0)
    flagBorderBottom:SetPoint("BOTTOMRIGHT", frame.flagIconFrame, "BOTTOMRIGHT", 0, 0)
    flagBorderBottom:SetHeight(flagBorderThickness)
    
    local flagBorderLeft = frame.flagIconFrame:CreateTexture(nil, "OVERLAY")
    flagBorderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
    flagBorderLeft:SetVertexColor(0, 0, 0, 1)
    flagBorderLeft:SetPoint("TOPLEFT", frame.flagIconFrame, "TOPLEFT", 0, 0)
    flagBorderLeft:SetPoint("BOTTOMLEFT", frame.flagIconFrame, "BOTTOMLEFT", 0, 0)
    flagBorderLeft:SetWidth(flagBorderThickness)
    
    local flagBorderRight = frame.flagIconFrame:CreateTexture(nil, "OVERLAY")
    flagBorderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
    flagBorderRight:SetVertexColor(0, 0, 0, 1)
    flagBorderRight:SetPoint("TOPRIGHT", frame.flagIconFrame, "TOPRIGHT", 0, 0)
    flagBorderRight:SetPoint("BOTTOMRIGHT", frame.flagIconFrame, "BOTTOMRIGHT", 0, 0)
    flagBorderRight:SetWidth(flagBorderThickness)
    
    frame.flagIcon = frame.flagIconFrame:CreateTexture(nil, "ARTWORK")
    frame.flagIcon:SetPoint("TOPLEFT", 1, -1)
    frame.flagIcon:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.flagIcon:SetTexture(132486) -- Flag icon texture
    frame.flagIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    frame.flagIconFrame:Hide()
    
    -- Healer indicator icon
    frame.healerIconFrame = CreateFrame("Frame", nil, frame)
    frame.healerIconFrame:SetSize(db.healers.size or 16, db.healers.size or 16)
    frame.healerIconFrame:SetPoint("LEFT", frame.trinketFrame, "RIGHT", db.healers.xOffset or 2, 0)
    
    frame.healerIcon = frame.healerIconFrame:CreateTexture(nil, "ARTWORK")
    frame.healerIcon:SetPoint("TOPLEFT", 0, 0)
    frame.healerIcon:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.healerIcon:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\healericon.tga")
    frame.healerIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- ArenaCore-style black borders for healer icon
    local healerBorderThickness = 3
    local healerBorderTop = frame.healerIconFrame:CreateTexture(nil, "OVERLAY")
    healerBorderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
    healerBorderTop:SetVertexColor(0, 0, 0, 1)
    healerBorderTop:SetPoint("TOPLEFT", frame.healerIcon, "TOPLEFT", 0, 0)
    healerBorderTop:SetPoint("TOPRIGHT", frame.healerIcon, "TOPRIGHT", 0, 0)
    healerBorderTop:SetHeight(healerBorderThickness)
    
    local healerBorderBottom = frame.healerIconFrame:CreateTexture(nil, "OVERLAY")
    healerBorderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    healerBorderBottom:SetVertexColor(0, 0, 0, 1)
    healerBorderBottom:SetPoint("BOTTOMLEFT", frame.healerIcon, "BOTTOMLEFT", 0, 0)
    healerBorderBottom:SetPoint("BOTTOMRIGHT", frame.healerIcon, "BOTTOMRIGHT", 0, 0)
    healerBorderBottom:SetHeight(healerBorderThickness)
    
    local healerBorderLeft = frame.healerIconFrame:CreateTexture(nil, "OVERLAY")
    healerBorderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
    healerBorderLeft:SetVertexColor(0, 0, 0, 1)
    healerBorderLeft:SetPoint("TOPLEFT", frame.healerIcon, "TOPLEFT", 0, 0)
    healerBorderLeft:SetPoint("BOTTOMLEFT", frame.healerIcon, "BOTTOMLEFT", 0, 0)
    healerBorderLeft:SetWidth(healerBorderThickness)
    
    local healerBorderRight = frame.healerIconFrame:CreateTexture(nil, "OVERLAY")
    healerBorderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
    healerBorderRight:SetVertexColor(0, 0, 0, 1)
    healerBorderRight:SetPoint("TOPRIGHT", frame.healerIcon, "TOPRIGHT", 0, 0)
    healerBorderRight:SetPoint("BOTTOMRIGHT", frame.healerIcon, "BOTTOMRIGHT", 0, 0)
    healerBorderRight:SetWidth(healerBorderThickness)
    
    frame.healerIconFrame:Hide()
    
    -- Death indicator (ArenaCore-style with independent HIGH strata frame)
    frame.deathIconFrame = CreateFrame("Frame", nil, frame)
    frame.deathIconFrame:SetFrameStrata("HIGH")
    frame.deathIconFrame:SetFrameLevel(1000)
    frame.deathIconFrame:SetSize(50, 50)
    
    -- Create texture on the high-strata frame
    frame.deathIcon = frame.deathIconFrame:CreateTexture(nil, "ARTWORK")
    frame.deathIcon:SetTexture("Interface\\AddOns\\PeralexBG\\Media\\Textures\\ArenaCoreDead.png")
    frame.deathIcon:SetAllPoints(frame.deathIconFrame)
    frame.deathIcon:SetTexCoord(0, 1, 0, 1)
    
    frame.deathIconFrame:Hide()
    
    -- Target highlight
    frame.targetHighlight = frame:CreateTexture(nil, "OVERLAY")
    frame.targetHighlight:SetPoint("TOPLEFT", -2, 2)
    frame.targetHighlight:SetPoint("BOTTOMRIGHT", 2, -2)
    frame.targetHighlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.targetHighlight:SetVertexColor(unpack(COLORS.TARGET_HIGHLIGHT))
    frame.targetHighlight:SetBlendMode("ADD")
    frame.targetHighlight:Hide()
    
    -- Focus highlight
    frame.focusHighlight = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    frame.focusHighlight:SetPoint("TOPLEFT", -1, 1)
    frame.focusHighlight:SetPoint("BOTTOMRIGHT", 1, -1)
    frame.focusHighlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.focusHighlight:SetVertexColor(unpack(COLORS.FOCUS_HIGHLIGHT))
    frame.focusHighlight:SetBlendMode("ADD")
    frame.focusHighlight:Hide()
    
    -- Dead overlay
    frame.deadOverlay = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    frame.deadOverlay:SetAllPoints()
    frame.deadOverlay:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.deadOverlay:SetVertexColor(0, 0, 0, 0.6)
    frame.deadOverlay:Hide()
    
    frame.deadText = frame:CreateFontString(nil, "OVERLAY", nil, 3)
    frame.deadText:SetFont(self:GetFont(), 12, "OUTLINE")
    frame.deadText:SetPoint("CENTER")
    frame.deadText:SetText("DEAD")
    frame.deadText:SetTextColor(0.8, 0.2, 0.2)
    frame.deadText:Hide()
    
    -- =========================================================================
    -- SECURE CLICK TARGETING
    -- Uses macro-based targeting since BG enemies have no unit IDs
    -- Macros updated in FrameManager when enemy data changes
    -- =========================================================================
    
    frame:RegisterForClicks("AnyUp")
    frame:SetAttribute("type1", "macro")
    frame:SetAttribute("type2", "macro")
    frame:SetAttribute("macrotext1", "")
    frame:SetAttribute("macrotext2", "")
    
    -- Hover visual feedback with tooltip
    frame:SetScript("OnEnter", function(self)
        if not self.isCurrentTarget then
            self:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
        end
        
        -- Show tooltip with enemy data
        if self.enemyData then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:ClearLines()
            
            -- Player name only (no spec)
            GameTooltip:AddLine(self.enemyData.name, 1, 1, 1)
            
            -- Class name
            GameTooltip:AddLine(self.enemyData.className, 0.6, 0.6, 0.6)
            
            -- Race
            if self.enemyData.raceName and self.enemyData.raceName ~= "" then
                GameTooltip:AddLine(self.enemyData.raceName, 0.5, 0.5, 0.5)
            end
            
            -- Spec (below race)
            if self.enemyData.spec and self.enemyData.spec ~= "" then
                GameTooltip:AddLine(self.enemyData.spec, 0.8, 0.6, 1)
            end
            
            -- Stats separator
            GameTooltip:AddLine(" ", 0, 0, 0)
            
            -- Damage
            local damageText = FormatLargeNumber(self.enemyData.damageDone or 0)
            GameTooltip:AddLine("Damage: " .. damageText, 1, 0.8, 0)
            
            -- Healing
            local healingText = FormatLargeNumber(self.enemyData.healingDone or 0)
            GameTooltip:AddLine("Healing: " .. healingText, 0.2, 1, 0.2)
            
            -- Killing Blows
            GameTooltip:AddLine("Killing Blows: " .. (self.enemyData.killingBlows or 0), 1, 0.2, 0.2)
            
            -- Honor Level
            if self.enemyData.honorLevel and self.enemyData.honorLevel > 0 then
                GameTooltip:AddLine("Honor Level: " .. self.enemyData.honorLevel, 0.6, 0.4, 0.8)
            end
            
            GameTooltip:Show()
        end
    end)
    
    frame:SetScript("OnLeave", function(self)
        if self.isCurrentTarget then
            self:SetBackdropBorderColor(1, 0.5, 0, 1)
        else
            self:SetBackdropBorderColor(unpack(COLORS.BORDER))
        end
        
        -- Hide tooltip
        GameTooltip:Hide()
    end)
    
    frame.index = index
    frame:Hide()
    
    return frame
end
