-- ============================================================================
-- Peralex BG - FrameManager.lua
-- Functional frame pool, positioning, and enemy frame management
-- ============================================================================

local PE = _G.PeralexBG

-- Frame storage
PE.framePool = {}
PE.anchorFrame = nil
PE.activeFrameCount = 0

-- Epic BG storage
PE.epicBGAnchors = {}      -- [groupIndex] = anchor frame
PE.epicBGFramePools = {}   -- [groupIndex] = {frame1, frame2, ...}
PE.epicBGActiveFrameCounts = {} -- [groupIndex] = count
PE.pendingEpicBGUpdate = nil -- Queued enemies for update after combat

-- ============================================================================
-- ANCHOR FRAME
-- ============================================================================

function PE:CreateAnchorFrame()
    if self.anchorFrame then return self.anchorFrame end
    
    local anchor = CreateFrame("Frame", "PeralexBGAnchor", UIParent, "BackdropTemplate")
    anchor:SetSize(200, 25)
    anchor:SetFrameStrata("MEDIUM")
    anchor:SetFrameLevel(100)
    anchor:SetClampedToScreen(true)
    anchor:SetMovable(true)
    anchor:EnableMouse(true)
    anchor:RegisterForDrag("LeftButton")
    
    anchor:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    anchor:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    anchor:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
    
    -- Enemy count text (above anchor title)
    local countText = anchor:CreateFontString(nil, "OVERLAY")
    countText:SetFont(self:GetFont(), 10, "OUTLINE")
    countText:SetPoint("BOTTOM", anchor, "TOP", 0, 2)
    countText:SetText("")
    countText:SetTextColor(0.9, 0.9, 0.9)
    anchor.countText = countText
    
    local title = anchor:CreateFontString(nil, "OVERLAY")
    title:SetFont(self:GetFont(), 11, "OUTLINE")
    title:SetPoint("CENTER")
    title:SetText("Peralex BG")
    title:SetTextColor(0.9, 0.9, 0.9)
    anchor.title = title
    
    anchor:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        self:StartMoving()
    end)
    anchor:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        PE.DB.position.point = point
        PE.DB.position.relativePoint = relPoint
        PE.DB.position.x = x
        PE.DB.position.y = y
    end)
    
    anchor:Hide()
    self.anchorFrame = anchor
    return anchor
end

function PE:UpdateAnchorPosition()
    -- Skip during combat (anchor becomes protected when secure frames reference it)
    if InCombatLockdown() then return end
    
    if not self.anchorFrame then self:CreateAnchorFrame() end
    
    local pos = self.DB.position
    self.anchorFrame:ClearAllPoints()
    self.anchorFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
end

function PE:UpdateGlobalAnchorVisibility()
    -- Skip during combat
    if InCombatLockdown() then return end
    
    -- Update regular anchor visibility
    if self.anchorFrame then
        if self.DB.appearance.showAnchor then
            -- Don't show in arenas
            local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
            if not isArena then
                self.anchorFrame:Show()
            else
                self.anchorFrame:Hide()
            end
        else
            self.anchorFrame:Hide()
        end
    end
    
    -- Update Epic BG anchor visibility
    if self.DB.appearance.showAnchor then
        self:ShowEpicBGAnchors()
    else
        self:HideEpicBGAnchors()
    end
end

function PE:ToggleEnemyAnchor()
    -- Can't toggle anchor during combat
    if InCombatLockdown() then
        self:Print("Cannot toggle anchor during combat")
        return nil
    end
    
    -- CRITICAL: Block anchor toggle in arenas
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if isArena then
        self:Print("Peralex BG does not work in arenas - Battlegrounds only")
        return nil
    end
    
    if not self.anchorFrame then self:CreateAnchorFrame() end
    self:UpdateAnchorPosition()
    
    if self.anchorFrame:IsShown() then
        self.anchorFrame:Hide()
        return false
    else
        -- Only show if showAnchor setting is enabled
        if self.DB.appearance.showAnchor then
            self.anchorFrame:Show()
            return true
        end
        return false
    end
end

-- ============================================================================
-- FRAME POOL MANAGEMENT
-- ============================================================================

function PE:CreateFramePool()
    local maxFrames = self.DB.frames.maxFrames or 15
    for i = 1, maxFrames do
        if not self.framePool[i] then
            self.framePool[i] = self:CreateEnemyFrame(i)
        end
    end
end

function PE:GetFrame(index)
    if not self.framePool[index] then
        self.framePool[index] = self:CreateEnemyFrame(index)
    end
    return self.framePool[index]
end

function PE:HideAllFrames()
    -- Handle frame hiding during combat lockdown using queuing system
    if InCombatLockdown() then
        -- Queue frame hiding for after combat
        self:QueueFrameHideUpdate()
        return
    end
    
    for i, frame in ipairs(self.framePool) do
        if frame then
            frame:Hide()
            frame.enemyData = nil
        end
    end
    self.activeFrameCount = 0
end

-- Queue frame visibility updates for after combat
PE.pendingFrameUpdates = {}

function PE:QueueFrameVisibilityUpdate()
    if InCombatLockdown() and not self.pendingFrameUpdates.queued then
        self.pendingFrameUpdates.queued = true
        local function ApplyUpdates()
            if not InCombatLockdown() then
                -- Apply pending visibility updates
                for i, frame in ipairs(self.framePool) do
                    if frame and frame.enemyData then
                        frame:Show()
                    else
                        frame:Hide()
                    end
                end
                self.pendingFrameUpdates.queued = false
            else
                -- Still in combat, try again later
                C_Timer.After(0.5, ApplyUpdates)
            end
        end
        C_Timer.After(0.5, ApplyUpdates)
    end
end

function PE:QueueFrameHideUpdate()
    if InCombatLockdown() and not self.pendingFrameUpdates.hideQueued then
        self.pendingFrameUpdates.hideQueued = true
        local function ApplyHideUpdates()
            if not InCombatLockdown() then
                -- Hide all frames and clear data
                for i, frame in ipairs(self.framePool) do
                    if frame then
                        frame:Hide()
                        frame.enemyData = nil
                    end
                end
                PE.activeFrameCount = 0
                self.pendingFrameUpdates.hideQueued = false
            else
                -- Still in combat, try again later
                C_Timer.After(0.5, ApplyHideUpdates)
            end
        end
        C_Timer.After(0.5, ApplyHideUpdates)
    end
end

function PE:QueueAnchorHideUpdate()
    if InCombatLockdown() and not self.pendingFrameUpdates.anchorHideQueued then
        self.pendingFrameUpdates.anchorHideQueued = true
        local function ApplyAnchorHide()
            if not InCombatLockdown() then
                if PE.anchorFrame then
                    PE.anchorFrame:Hide()
                end
                self.pendingFrameUpdates.anchorHideQueued = false
            else
                -- Still in combat, try again later
                C_Timer.After(0.5, ApplyAnchorHide)
            end
        end
        C_Timer.After(0.5, ApplyAnchorHide)
    end
end

-- ============================================================================
-- FRAME POSITIONING
-- ============================================================================

function PE:UpdateFramePositions()
    -- Skip during combat (secure frames can't be repositioned)
    if InCombatLockdown() then return end
    
    if not self.anchorFrame then self:CreateAnchorFrame() end
    self:UpdateAnchorPosition()
    
    local db = self.DB
    local spacing = db.frames.spacing or 5
    local growDirection = db.frames.growDirection or "DOWN"
    
    -- Only position active frames (shown frames), not all frames in pool
    local activeIndex = 0
    for i, frame in ipairs(self.framePool) do
        if frame and frame:IsShown() then
            activeIndex = activeIndex + 1
            frame:ClearAllPoints()
            local yOffset = (activeIndex - 1) * (db.frames.height + spacing)
            if growDirection == "DOWN" then
                yOffset = -yOffset
            end
            frame:SetPoint("TOP", self.anchorFrame, "BOTTOM", 0, yOffset - 5)
        end
    end
end

-- ============================================================================
-- FRAME CONTENT UPDATES
-- ============================================================================

function PE:UpdateFrameWithEnemy(frame, enemyData)
    if not frame or not enemyData then return end
    
    local db = self.DB
    frame.enemyData = enemyData

    local function NormalizeNameForMacro(name)
        local safe = tostring(name or ""):gsub('"', '')
        if safe:find(" ") then
            safe = '"' .. safe .. '"'
        end
        return safe
    end

    local function BuildEnemyClickMacros(name, focusMode)
        local safeName = NormalizeNameForMacro(name)
        local macro1 = string.format("/targetexact %s", safeName)

        local lines = { string.format("/targetexact %s", safeName), "/focus" }
        if focusMode == "restore" then
            lines[#lines + 1] = "/targetlasttarget"
        end
        local macro2 = table.concat(lines, "\n")
        return macro1, macro2
    end
    
    -- Name visibility and text
    local displayName = enemyData.name
    if displayName:find("-") then
        displayName = displayName:match("([^-]+)") -- Remove realm
    end
    
    if db.appearance.showPlayerNames then
        frame.nameText:SetText(displayName)
        frame.nameText:Show()
        
        -- Class color for name text
        local classColor = self.CLASS_COLORS[enemyData.classToken]
        if classColor and db.appearance.useClassColorNames then
            frame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
        else
            frame.nameText:SetTextColor(1, 1, 1) -- White
        end
    else
        frame.nameText:Hide()
    end
    
    -- Class icon - use theme-based path
    local iconPath = self:GetClassIconPath(enemyData.classToken)
    frame.classIcon:SetTexture(iconPath)
    
    -- Set texture coordinates based on theme
    local theme = db.classIcons.theme or "default"
    if theme == "default" then
        -- Default ArenaCore icons need cropping to fit properly (10% border crop)
        frame.classIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    else
        -- ColdClasses icons use full texture
        frame.classIcon:SetTexCoord(0, 1, 0, 1)
    end
    
    -- Class color on health bar
    local classColor = self.CLASS_COLORS[enemyData.classToken]
    if classColor and db.appearance.useClassColors then
        frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
    else
        frame.healthBar:SetStatusBarColor(0.2, 0.8, 0.2)
    end
    
    -- Spec icon
    if db.specIcons.enabled and enemyData.spec and enemyData.spec ~= "" then
        local specIcon = self:GetSpecIcon(enemyData.classToken, enemyData.spec)
        if specIcon then
            -- Debug: Log what icon we're setting for Evokers and Demon Hunters
            if self.DB and self.DB.debug and (enemyData.classToken == "EVOKER" or enemyData.classToken == "DEMONHUNTER") then
                self:Debug("Setting spec icon for " .. enemyData.name .. " (" .. enemyData.classToken .. ":" .. enemyData.spec .. ") -> " .. specIcon)
            end
            frame.specIcon:SetTexture(specIcon)
            frame.specIconFrame:Show()
        else
            -- Debug: Log why we're not showing the icon
            if self.DB and self.DB.debug and (enemyData.classToken == "EVOKER" or enemyData.classToken == "DEMONHUNTER") then
                self:Debug("No spec icon found for " .. enemyData.name .. " (" .. enemyData.classToken .. ":" .. enemyData.spec .. ")")
            end
            frame.specIconFrame:Hide()
        end
    else
        frame.specIconFrame:Hide()
    end
    
    -- Healer icon
    if db.healers.enabled and enemyData.isHealer then
        frame.healerIconFrame:Show()
    else
        frame.healerIconFrame:Hide()
    end
    
    -- Flag carrier icon
    if enemyData.isFlagCarrier then
        frame.flagIconFrame:Show()
    else
        frame.flagIconFrame:Hide()
    end
    
    -- Status text visibility (damage/healing/kills)
    if db.appearance.showStatusText then
        local statusType = db.appearance.statusTextType or "damage"
        local statusText = ""
        if statusType == "damage" then
            statusText = AbbreviateNumbers and AbbreviateNumbers(enemyData.damageDone) or tostring(enemyData.damageDone)
        elseif statusType == "healing" then
            statusText = AbbreviateNumbers and AbbreviateNumbers(enemyData.healingDone) or tostring(enemyData.healingDone)
        elseif statusType == "kills" then
            statusText = tostring(enemyData.killingBlows) .. " KB"
        end
        frame.healthText:SetText(statusText)
        frame.healthText:Show()
    else
        frame.healthText:Hide()
    end
    
    -- Trinket visibility
    if db.trinkets.enabled then
        frame.trinketFrame:Show()
    else
        frame.trinketFrame:Hide()
    end
    
    -- Set targeting macros (only outside combat lockdown)
    if enemyData.name and not InCombatLockdown() then
        local focusMode = self.DB.targeting.focusBehavior or "both"
        local macro1, macro2 = BuildEnemyClickMacros(enemyData.name, focusMode)
        frame:SetAttribute("macrotext1", macro1)
        frame:SetAttribute("macrotext2", macro2)
    end
    
    -- Only show frame if not in combat lockdown
    if not InCombatLockdown() then
        frame:Show()
    end
end

-- ============================================================================
-- MAIN UPDATE FUNCTION
-- ============================================================================

function PE:UpdateFrames(enemies)
    if not enemies then
        -- If in test mode, regenerate test enemies to apply new setting sorting
        if self.states.isTestMode then
            local count = self.DB.frames.maxFrames or 8
            enemies = self:GetTestModeEnemies(count)
            self.enemyCache = enemies
        else
            enemies = self:GetCachedEnemies()
        end
    end
    
    local db = self.DB
    local maxFrames = db.frames.maxFrames or 15
    local inCombat = InCombatLockdown()
    
    -- Ensure frame pool exists
    self:CreateFramePool()
    
    -- Hide all frames first (only if not in combat)
    if not inCombat then
        self:HideAllFrames()
    end
    
    -- Update frames for each enemy
    local count = 0
    for i, enemy in ipairs(enemies) do
        if i > maxFrames then break end
        
        local frame = self:GetFrame(i)
        if frame then
            self:UpdateFrameWithEnemy(frame, enemy)
            count = count + 1
        end
    end
    
    self.activeFrameCount = count
    
    -- Queue visibility updates if in combat
    if inCombat then
        self:QueueFrameVisibilityUpdate()
    end
    
    -- Update frame positions and highlights (these are safe during combat)
    self:UpdateFramePositions()
    self:UpdateEnemyCountText()
    self:UpdateTargetHighlight()
    self:UpdateFocusHighlight()
end

-- ============================================================================
-- FRAME SIZE AND TEXTURE UPDATES
-- ============================================================================

function PE:UpdateFrameSizes()
    local db = self.DB
    local width = db.frames.width or 200
    local height = db.frames.height or 40
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame then
            frame:SetSize(width, height)
            frame.classIcon:SetSize(height - 4, height - 4)
            frame.nameText:SetWidth(width - 80)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame then
                frame:SetSize(width, height)
                frame.classIcon:SetSize(height - 4, height - 4)
                frame.nameText:SetWidth(width - 80)
            end
        end
    end
end

function PE:UpdateSpecIconSizes()
    local db = self.DB
    local size = db.specIcons.size or 20
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame and frame.specIconFrame then
            frame.specIconFrame:SetSize(size, size)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame and frame.specIconFrame then
                frame.specIconFrame:SetSize(size, size)
            end
        end
    end
end
function PE:UpdateSpecIconPositions()
    local db = self.DB
    local xOffset = db.specIcons.xOffset or -2
    local yOffset = db.specIcons.yOffset or 0
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame and frame.specIconFrame then
            frame.specIconFrame:ClearAllPoints()
            frame.specIconFrame:SetPoint("RIGHT", frame, "LEFT", xOffset, yOffset)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame and frame.specIconFrame then
                frame.specIconFrame:ClearAllPoints()
                frame.specIconFrame:SetPoint("RIGHT", frame, "LEFT", xOffset, yOffset)
            end
        end
    end
end

function PE:UpdateHealerSizes()
    local db = self.DB
    local size = db.healers.size or 16
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame and frame.healerIconFrame then
            frame.healerIconFrame:SetSize(size, size)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame and frame.healerIconFrame then
                frame.healerIconFrame:SetSize(size, size)
            end
        end
    end
end

function PE:UpdateHealerPositions()
    local db = self.DB
    local xOffset = db.healers.xOffset or 2
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame and frame.healerIconFrame then
            frame.healerIconFrame:ClearAllPoints()
            frame.healerIconFrame:SetPoint("LEFT", frame.trinketFrame, "RIGHT", xOffset, 0)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame and frame.healerIconFrame then
                frame.healerIconFrame:ClearAllPoints()
                frame.healerIconFrame:SetPoint("LEFT", frame.trinketFrame, "RIGHT", xOffset, 0)
            end
        end
    end
end

function PE:UpdateTrinketSizes()
    local db = self.DB
    local size = db.trinkets.size or 24
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame and frame.trinketFrame then
            frame.trinketFrame:SetSize(size, size)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame and frame.trinketFrame then
                frame.trinketFrame:SetSize(size, size)
            end
        end
    end
end

function PE:UpdateFlagSizes()
    local db = self.DB
    local size = db.flags.size or 24
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame and frame.flagIconFrame then
            frame.flagIconFrame:SetSize(size, size)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame and frame.flagIconFrame then
                frame.flagIconFrame:SetSize(size, size)
            end
        end
    end
end

function PE:UpdateFlagPositions()
    local db = self.DB
    local xOffset = db.flags.xOffset or 2
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame and frame.flagIconFrame then
            frame.flagIconFrame:ClearAllPoints()
            frame.flagIconFrame:SetPoint("LEFT", frame.trinketFrame, "RIGHT", xOffset, 0)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame and frame.flagIconFrame then
                frame.flagIconFrame:ClearAllPoints()
                frame.flagIconFrame:SetPoint("LEFT", frame.trinketFrame, "RIGHT", xOffset, 0)
            end
        end
    end
end

function PE:UpdateFrameTextures()
    local db = self.DB
    local texture = db.appearance.healthBarTexture
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame then
            frame.healthBar:SetStatusBarTexture(texture)
            frame.healthBg:SetTexture(texture)
            -- Resource bar removed (can't track in Midnight 12.0)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame then
                frame.healthBar:SetStatusBarTexture(texture)
                frame.healthBg:SetTexture(texture)
                -- Resource bar removed (can't track in Midnight 12.0)
            end
        end
    end
end

function PE:UpdateHealthBarWidth()
    local db = self.DB
    local rightOffset = db.trinkets.enabled and -28 or -2
    
    -- Update regular frames
    for i, frame in ipairs(self.framePool) do
        if frame and frame.healthContainer then
            frame.healthContainer:ClearAllPoints()
            frame.healthContainer:SetPoint("TOPLEFT", frame.classIcon, "TOPRIGHT", 2, 0)
            frame.healthContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", rightOffset, 2)
        end
    end
    
    -- Update Epic BG frames
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame and frame.healthContainer then
                frame.healthContainer:ClearAllPoints()
                frame.healthContainer:SetPoint("TOPLEFT", frame.classIcon, "TOPRIGHT", 2, 0)
                frame.healthContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", rightOffset, 2)
            end
        end
    end
end

-- HIGHLIGHT UPDATES (disabled - causes issues with secure frame operations)
-- ============================================================================

function PE:UpdateTargetHighlight()
    -- Disabled: highlight features removed to avoid secure frame issues
end

function PE:UpdateFocusHighlight()
    -- Disabled: highlight features removed to avoid secure frame issues
end

function PE:UpdateEnemyCountText()
    if not self.anchorFrame or not self.anchorFrame.countText then return end
    
    local db = self.DB
    local count = self.activeFrameCount or 0
    
    -- Anchor title always shows "Peralex BG"
    self.anchorFrame.title:SetText("Peralex BG")
    self.anchorFrame.title:SetTextColor(0.9, 0.9, 0.9)
    
    -- If showEnemyCount is disabled or no enemies, hide count text
    if not db.appearance.showEnemyCount or count == 0 then
        self.anchorFrame.countText:SetText("")
        return
    end
    
    -- Determine enemy faction text
    local factionText = "Enemies"
    local enemyFaction = self:GetEnemyFaction()
    
    if enemyFaction == 0 then
        factionText = "Horde"
        self.anchorFrame.countText:SetTextColor(0.8, 0.2, 0.2) -- Red for Horde
    elseif enemyFaction == 1 then
        factionText = "Alliance"
        self.anchorFrame.countText:SetTextColor(0.2, 0.4, 0.8) -- Blue for Alliance
    else
        self.anchorFrame.countText:SetTextColor(0.9, 0.9, 0.9) -- White/gray for unknown
    end
    
    self.anchorFrame.countText:SetText(count .. " " .. factionText)
end

function PE:GetEnemyFaction()
    -- Check cached enemies for faction
    local enemies = self.enemyCache or {}
    if #enemies > 0 and enemies[1].faction then
        return enemies[1].faction
    end
    
    -- Fallback: opposite of player faction
    local playerFaction = self:GetPlayerFaction()
    if playerFaction == 0 then
        return 1 -- Player is Horde, enemies are Alliance
    elseif playerFaction == 1 then
        return 0 -- Player is Alliance, enemies are Horde
    end
    
    return nil
end

-- ============================================================================
-- TEST MODE
-- ============================================================================

function PE:ToggleTestMode()
    if self.states.isTestMode then
        self:ExitTestMode()
    else
        self:EnterTestMode()
    end
end

function PE:EnterTestMode()
    self.states.isTestMode = true
    
    -- Create anchor if needed
    if not self.anchorFrame then self:CreateAnchorFrame() end
    self:UpdateAnchorPosition()
    
    -- Respect global showAnchor setting
    -- CRITICAL: Don't show anchor in arenas even in test mode
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if self.DB.appearance.showAnchor and not isArena and not InCombatLockdown() then
        self.anchorFrame:Show()
    end
    
    -- Get test enemies based on settings
    local count = self.DB.frames.maxFrames or 8
    local testEnemies = self:GetTestModeEnemies(count)
    
    -- Cache test enemies for faction detection
    self.enemyCache = testEnemies
    
    -- Update frames with test data
    self:UpdateFrames(testEnemies)
    
    self:Print("Test Mode enabled - showing " .. #testEnemies .. " test frames")
end

function PE:ExitTestMode()
    self.states.isTestMode = false
    self:HideAllFrames()
    
    if self.anchorFrame then
        if InCombatLockdown() then
            -- Queue anchor hide for after combat
            self:QueueAnchorHideUpdate()
        else
            self.anchorFrame:Hide()
        end
    end
    
    self:Print("Test Mode disabled")
end

function PE:ShowTestFrames()
    self:EnterTestMode()
end

-- ============================================================================
-- EPIC BG ANCHOR FRAMES
-- ============================================================================

function PE:CreateEpicBGAnchor(groupIndex)
    if self.epicBGAnchors[groupIndex] then return self.epicBGAnchors[groupIndex] end
    
    local anchor = CreateFrame("Frame", "PeralexBGEpicAnchor"..groupIndex, UIParent, "BackdropTemplate")
    anchor:SetSize(200, 25)
    anchor:SetFrameStrata("MEDIUM")
    anchor:SetFrameLevel(100)
    anchor:SetClampedToScreen(true)
    anchor:SetMovable(true)
    anchor:EnableMouse(true)
    anchor:RegisterForDrag("LeftButton")
    
    anchor:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    anchor:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    anchor:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
    
    -- Enemy count text (above anchor title)
    local countText = anchor:CreateFontString(nil, "OVERLAY")
    countText:SetFont(self:GetFont(), 10, "OUTLINE")
    countText:SetPoint("BOTTOM", anchor, "TOP", 0, 2)
    countText:SetText("")
    countText:SetTextColor(0.9, 0.9, 0.9)
    anchor.countText = countText
    
    local title = anchor:CreateFontString(nil, "OVERLAY")
    title:SetFont(self:GetFont(), 10, "OUTLINE")
    title:SetPoint("CENTER")
    title:SetText("Peralex BG Group " .. groupIndex)
    title:SetTextColor(0.9, 0.9, 0.9)
    anchor.title = title
    anchor.groupIndex = groupIndex
    
    anchor:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        self:StartMoving()
    end)
    anchor:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        local groupIndex = self.groupIndex
        local mode = PE.DB.epicBG.groupMode
        
        -- Save position to the correct mode settings
        if mode == "all" then
            PE.DB.epicBG.allMode.position = { point = point, relativePoint = relPoint, x = x, y = y }
        elseif mode == "ten" then
            PE.DB.epicBG.tenMode.groups[groupIndex].position = { point = point, relativePoint = relPoint, x = x, y = y }
        elseif mode == "twenty" then
            PE.DB.epicBG.twentyMode.groups[groupIndex].position = { point = point, relativePoint = relPoint, x = x, y = y }
        end
    end)
    
    anchor:Hide()
    self.epicBGAnchors[groupIndex] = anchor
    return anchor
end

function PE:CreateAllEpicBGAnchors()
    -- Create anchors for all possible groups (up to 4)
    for i = 1, 4 do
        self:CreateEpicBGAnchor(i)
    end
end

function PE:UpdateEpicBGAnchorPositions()
    local db = self.DB.epicBG
    local mode = db.groupMode
    
    if mode == "all" then
        -- Single column mode - only anchor 1
        local anchor = self.epicBGAnchors[1]
        if anchor then
            local pos = db.allMode.position
            anchor:ClearAllPoints()
            anchor:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
            anchor.title:SetText("Epic BG (40)")
            
            -- Apply scale
            local scale = db.allMode.scale or 1.0
            anchor:SetScale(scale)
        end
    elseif mode == "ten" then
        -- 4 groups of 10
        for i = 1, 4 do
            local anchor = self.epicBGAnchors[i]
            if anchor and db.tenMode.groups[i] then
                local pos = db.tenMode.groups[i].position
                anchor:ClearAllPoints()
                anchor:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
                local titleText = (i == 1) and "Peralex BG (10)" or "Peralex BG Group " .. i
                anchor.title:SetText(titleText)
                
                local scale = db.tenMode.groups[i].scale or 1.0
                anchor:SetScale(scale)
            end
        end
    elseif mode == "twenty" then
        -- 2 groups of 20
        for i = 1, 2 do
            local anchor = self.epicBGAnchors[i]
            if anchor and db.twentyMode.groups[i] then
                local pos = db.twentyMode.groups[i].position
                anchor:ClearAllPoints()
                anchor:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
                local titleText = (i == 1) and "Peralex BG (20)" or "Peralex BG Group " .. i
                anchor.title:SetText(titleText)
                
                local scale = db.twentyMode.groups[i].scale or 1.0
                anchor:SetScale(scale)
            end
        end
    end
end

function PE:ShowEpicBGAnchors()
    -- Respect the showAnchor setting
    if not self.DB.appearance.showAnchor then
        return
    end
    
    -- CRITICAL: Don't show Epic BG anchors in arenas
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if isArena then
        return
    end
    
    local mode = self.DB.epicBG.groupMode
    local groupCount = mode == "all" and 1 or (mode == "ten" and 4 or 2)
    
    self:CreateAllEpicBGAnchors()
    self:UpdateEpicBGAnchorPositions()
    
    -- Show appropriate anchors
    for i = 1, 4 do
        if self.epicBGAnchors[i] then
            if i <= groupCount then
                self.epicBGAnchors[i]:Show()
            else
                self.epicBGAnchors[i]:Hide()
            end
        end
    end
end

function PE:HideEpicBGAnchors()
    for i = 1, 4 do
        if self.epicBGAnchors[i] then
            self.epicBGAnchors[i]:Hide()
        end
    end
end

function PE:ToggleEpicBGAnchors()
    local mode = self.DB.epicBG.groupMode
    local groupCount = mode == "all" and 1 or (mode == "ten" and 4 or 2)
    
    -- Check if any anchor is shown
    local anyShown = false
    for i = 1, groupCount do
        if self.epicBGAnchors[i] and self.epicBGAnchors[i]:IsShown() then
            anyShown = true
            break
        end
    end
    
    if anyShown then
        self:HideEpicBGAnchors()
        return false
    else
        self:ShowEpicBGAnchors()
        return true
    end
end

-- ============================================================================
-- EPIC BG FRAME POOLS
-- ============================================================================

function PE:CreateEpicBGFramePool(groupIndex, frameCount)
    if not self.epicBGFramePools[groupIndex] then
        self.epicBGFramePools[groupIndex] = {}
    end
    
    for i = 1, frameCount do
        if not self.epicBGFramePools[groupIndex][i] then
            self.epicBGFramePools[groupIndex][i] = self:CreateEnemyFrame(groupIndex * 100 + i)
        end
    end
end

function PE:GetEpicBGFrame(groupIndex, frameIndex)
    if not self.epicBGFramePools[groupIndex] then
        self.epicBGFramePools[groupIndex] = {}
    end
    if not self.epicBGFramePools[groupIndex][frameIndex] then
        self.epicBGFramePools[groupIndex][frameIndex] = self:CreateEnemyFrame(groupIndex * 100 + frameIndex)
    end
    return self.epicBGFramePools[groupIndex][frameIndex]
end

function PE:HideAllEpicBGFrames()
    for groupIndex, pool in pairs(self.epicBGFramePools) do
        for i, frame in ipairs(pool) do
            if frame then
                frame:Hide()
                frame.enemyData = nil
            end
        end
        self.epicBGActiveFrameCounts[groupIndex] = 0
    end
end

function PE:UpdateEpicBGFramePositions(groupIndex)
    local anchor = self.epicBGAnchors[groupIndex]
    if not anchor then return end
    
    -- Skip frame positioning during combat (protected operation)
    if InCombatLockdown() then return end
    
    local db = self.DB.epicBG
    local mode = db.groupMode
    local settings
    
    if mode == "all" then
        settings = db.allMode
    elseif mode == "ten" then
        settings = db.tenMode.groups[groupIndex]
    elseif mode == "twenty" then
        settings = db.twentyMode.groups[groupIndex]
    end
    
    if not settings then return end
    
    local spacing = settings.spacing or 3
    local height = settings.height or 40
    
    local pool = self.epicBGFramePools[groupIndex]
    if not pool then return end
    
    local activeIndex = 0
    for i, frame in ipairs(pool) do
        if frame and frame:IsShown() then
            activeIndex = activeIndex + 1
            frame:ClearAllPoints()
            local yOffset = (activeIndex - 1) * (height + spacing)
            frame:SetPoint("TOP", anchor, "BOTTOM", 0, -yOffset - 5)
        end
    end
end

function PE:UpdateEpicBGFrameSizes(groupIndex)
    -- Skip frame sizing during combat (protected operation on secure frames)
    if InCombatLockdown() then return end
    
    local db = self.DB.epicBG
    local mode = db.groupMode
    local settings
    
    if mode == "all" then
        settings = db.allMode
    elseif mode == "ten" then
        settings = db.tenMode.groups[groupIndex]
    elseif mode == "twenty" then
        settings = db.twentyMode.groups[groupIndex]
    end
    
    if not settings then return end
    
    local width = settings.width or 200
    local height = settings.height or 40
    
    local pool = self.epicBGFramePools[groupIndex]
    if not pool then return end
    
    for i, frame in ipairs(pool) do
        if frame then
            frame:SetSize(width, height)
            frame.classIcon:SetSize(height - 4, height - 4)
            frame.nameText:SetWidth(width - 80)
        end
    end
end

-- ============================================================================
-- EPIC BG TEST MODE
-- ============================================================================

function PE:ToggleEpicBGTestMode()
    if self.states.isEpicBGTestMode then
        self:ExitEpicBGTestMode()
    else
        self:EnterEpicBGTestMode()
    end
end

function PE:EnterEpicBGTestMode()
    -- Exit regular test mode if active
    if self.states.isTestMode then
        self:ExitTestMode()
    end
    
    -- CRITICAL: Don't enter Epic BG test mode in arenas
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if isArena then
        self:Print("Peralex BG does not work in arenas - Battlegrounds only")
        return
    end
    
    self.states.isEpicBGTestMode = true
    
    local db = self.DB.epicBG
    local mode = db.groupMode
    
    -- Create anchors and show them
    self:CreateAllEpicBGAnchors()
    self:UpdateEpicBGAnchorPositions()
    self:ShowEpicBGAnchors()
    
    -- Determine group count and frames per group
    local groupCount, framesPerGroup
    if mode == "all" then
        groupCount = 1
        framesPerGroup = 40
    elseif mode == "ten" then
        groupCount = 4
        framesPerGroup = 10
    else -- twenty
        groupCount = 2
        framesPerGroup = 20
    end
    
    -- Generate test enemies (40 total)
    local allEnemies = self:GetTestModeEnemies(40)
    
    -- Distribute enemies across groups
    local enemyIndex = 1
    for g = 1, groupCount do
        -- Create frame pool for this group
        self:CreateEpicBGFramePool(g, framesPerGroup)
        self:UpdateEpicBGFrameSizes(g)
        
        -- Assign enemies to frames in this group
        local count = 0
        for f = 1, framesPerGroup do
            if enemyIndex <= #allEnemies then
                local frame = self:GetEpicBGFrame(g, f)
                if frame then
                    self:UpdateFrameWithEnemy(frame, allEnemies[enemyIndex])
                    count = count + 1
                    enemyIndex = enemyIndex + 1
                end
            end
        end
        self.epicBGActiveFrameCounts[g] = count
        self:UpdateEpicBGFramePositions(g)
    end
    
    self:Print("Epic BG Test Mode enabled - " .. mode .. " layout with " .. groupCount .. " group(s)")
end

function PE:ExitEpicBGTestMode()
    self.states.isEpicBGTestMode = false
    self:HideAllEpicBGFrames()
    self:HideEpicBGAnchors()
    self:Print("Epic BG Test Mode disabled")
end

function PE:UpdateEpicBGFrames()
    if not self.states.isEpicBGTestMode then return end
    
    -- Only update sizes and positions, don't regenerate frames
    local db = self.DB.epicBG
    local mode = db.groupMode
    
    local groupCount
    if mode == "all" then
        groupCount = 1
    elseif mode == "ten" then
        groupCount = 4
    else
        groupCount = 2
    end
    
    -- Update sizes and positions for each active group
    for g = 1, groupCount do
        self:UpdateEpicBGFrameSizes(g)
        self:UpdateEpicBGFramePositions(g)
    end
end

function PE:RefreshEpicBGFrameAppearances()
    -- Refresh appearance of existing Epic BG frames without recreating them
    -- Used for settings like class color names that just need visual refresh
    if not self.epicBGFramePools then return end
    
    for g = 1, 4 do
        local pool = self.epicBGFramePools[g]
        if pool then
            for f = 1, #pool do
                local frame = pool[f]
                if frame and frame.enemyData and frame:IsShown() then
                    self:UpdateFrameWithEnemy(frame, frame.enemyData)
                end
            end
        end
    end
end

function PE:RegenerateEpicBGFrames()
    if not self.states.isEpicBGTestMode then return end
    
    -- Full regeneration (used when changing group mode)
    self:HideAllEpicBGFrames()
    
    local db = self.DB.epicBG
    local mode = db.groupMode
    
    self:UpdateEpicBGAnchorPositions()
    
    local groupCount, framesPerGroup
    if mode == "all" then
        groupCount = 1
        framesPerGroup = 40
    elseif mode == "ten" then
        groupCount = 4
        framesPerGroup = 10
    else
        groupCount = 2
        framesPerGroup = 20
    end
    
    -- Show/hide appropriate anchors
    for i = 1, 4 do
        if self.epicBGAnchors[i] then
            if i <= groupCount then
                self.epicBGAnchors[i]:Show()
            else
                self.epicBGAnchors[i]:Hide()
            end
        end
    end
    
    local allEnemies = self:GetTestModeEnemies(40)
    
    local enemyIndex = 1
    for g = 1, groupCount do
        self:CreateEpicBGFramePool(g, framesPerGroup)
        self:UpdateEpicBGFrameSizes(g)
        
        local count = 0
        for f = 1, framesPerGroup do
            if enemyIndex <= #allEnemies then
                local frame = self:GetEpicBGFrame(g, f)
                if frame then
                    self:UpdateFrameWithEnemy(frame, allEnemies[enemyIndex])
                    count = count + 1
                    enemyIndex = enemyIndex + 1
                end
            end
        end
        self.epicBGActiveFrameCounts[g] = count
        self:UpdateEpicBGFramePositions(g)
        self:UpdateEpicBGAnchorCountText(g)
    end
end

-- ============================================================================
-- EPIC BG HIGHLIGHT UPDATES (disabled - causes secret value errors in secure context)
-- ============================================================================

function PE:UpdateEpicBGTargetHighlight()
    -- Disabled: UnitGUID returns secret values during secure macro execution
    -- which cannot be compared and causes errors
end

function PE:UpdateEpicBGFocusHighlight()
    -- Disabled: UnitGUID returns secret values during secure macro execution
end

function PE:UpdateEpicBGAnchorCountText(groupIndex)
    local anchor = self.epicBGAnchors[groupIndex]
    if not anchor or not anchor.countText then return end
    
    local count = self.epicBGActiveFrameCounts[groupIndex] or 0
    
    -- If no enemies, hide count text
    if count == 0 then
        anchor.countText:SetText("")
        return
    end
    
    -- Determine enemy faction text
    local factionText = "Enemies"
    local enemyFaction = self:GetEnemyFaction()
    
    if enemyFaction == 0 then
        factionText = "Horde"
        anchor.countText:SetTextColor(0.8, 0.2, 0.2) -- Red for Horde
    elseif enemyFaction == 1 then
        factionText = "Alliance"
        anchor.countText:SetTextColor(0.2, 0.4, 0.8) -- Blue for Alliance
    else
        anchor.countText:SetTextColor(0.9, 0.9, 0.9) -- White/gray for unknown
    end
    
    anchor.countText:SetText(count .. " " .. factionText)
end

-- ============================================================================
-- EPIC BG LIVE MODE (REAL BATTLEGROUND DATA)
-- ============================================================================

function PE:UpdateEpicBGFramesWithEnemies(enemies)
    if not enemies or #enemies == 0 then return end
    
    -- CRITICAL: Don't show Epic BG frames in arenas
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if isArena then
        return
    end
    
    local db = self.DB.epicBG
    local mode = db.groupMode
    local inCombat = InCombatLockdown()
    
    -- If in combat, queue the update for later and only update non-protected elements
    if inCombat then
        self.pendingEpicBGUpdate = enemies
        -- During combat, only update highlights (safe operations)
        self:UpdateEpicBGTargetHighlight()
        self:UpdateEpicBGFocusHighlight()
        return
    end
    
    -- Clear any pending update since we're processing now
    self.pendingEpicBGUpdate = nil
    
    -- Determine group count and frames per group based on mode
    local groupCount, framesPerGroup
    if mode == "all" then
        groupCount = 1
        framesPerGroup = 40
    elseif mode == "ten" then
        groupCount = 4
        framesPerGroup = 10
    else -- twenty
        groupCount = 2
        framesPerGroup = 20
    end
    
    -- Create anchors if needed and show them
    self:CreateAllEpicBGAnchors()
    self:UpdateEpicBGAnchorPositions()
    
    -- Show appropriate anchors
    for i = 1, 4 do
        if self.epicBGAnchors[i] then
            if i <= groupCount then
                self.epicBGAnchors[i]:Show()
            else
                self.epicBGAnchors[i]:Hide()
            end
        end
    end
    
    -- Hide all frames first (only if not in combat)
    if not inCombat then
        self:HideAllEpicBGFrames()
    end
    
    -- Distribute enemies across groups
    local enemyIndex = 1
    for g = 1, groupCount do
        -- Create frame pool for this group if needed
        self:CreateEpicBGFramePool(g, framesPerGroup)
        self:UpdateEpicBGFrameSizes(g)
        
        -- Assign enemies to frames in this group
        local count = 0
        for f = 1, framesPerGroup do
            if enemyIndex <= #enemies then
                local frame = self:GetEpicBGFrame(g, f)
                if frame then
                    self:UpdateFrameWithEnemy(frame, enemies[enemyIndex])
                    count = count + 1
                    enemyIndex = enemyIndex + 1
                end
            else
                -- Hide unused frames in this group
                local frame = self.epicBGFramePools[g] and self.epicBGFramePools[g][f]
                if frame and not inCombat then
                    frame:Hide()
                    frame.enemyData = nil
                end
            end
        end
        self.epicBGActiveFrameCounts[g] = count
        self:UpdateEpicBGFramePositions(g)
        self:UpdateEpicBGAnchorCountText(g)
    end
    
    -- Update highlights
    self:UpdateEpicBGTargetHighlight()
    self:UpdateEpicBGFocusHighlight()
    
    if self.DB.debug then
        self:Print("Epic BG frames updated - " .. mode .. " mode, " .. #enemies .. " enemies across " .. groupCount .. " group(s)")
    end
end

function PE:HideAllEpicBGAnchorsAndFrames()
    self:HideAllEpicBGFrames()
    self:HideEpicBGAnchors()
end

function PE:ProcessPendingEpicBGUpdate()
    -- Called after combat ends to process queued updates
    if self.pendingEpicBGUpdate and #self.pendingEpicBGUpdate > 0 then
        if self.DB.debug then
            self:Print("Processing pending Epic BG update (" .. #self.pendingEpicBGUpdate .. " enemies)")
        end
        self:UpdateEpicBGFramesWithEnemies(self.pendingEpicBGUpdate)
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function PE:InitializeFrameManager()
    self:CreateAnchorFrame()
    self:CreateFramePool()
    self:UpdateAnchorPosition()
end
