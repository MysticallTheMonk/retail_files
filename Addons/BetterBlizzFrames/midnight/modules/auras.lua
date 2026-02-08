if not BBF.isMidnight then return end
local L = BBF.L

local TargetFrame = TargetFrame
local TargetFrameSpellBar = TargetFrameSpellBar
local FocusFrame = FocusFrame
local FocusFrameSpellBar = FocusFrameSpellBar

local playerBuffsHooked
local targetAurasHooked
local targetCastbarsHooked

local ipairs = ipairs
local math_ceil = math.ceil
local math_max = math.max

local Masque
local MasquePlayerBuffs
local MasquePlayerDebuffs
local MasqueTargetBuffs
local MasqueTargetDebuffs
local MasqueFocusBuffs
local MasqueFocusDebuffs
local MasqueOn

-- Function to add buffs and debuffs to Masque group
local function addToMasque(frame, masqueGroup)
    if frame and not frame.bbfMsq then
        masqueGroup:AddButton(frame)
        frame.bbfMsq = true
    end
end

-- How did this spaghetti start?
-- For some reason accessing the global BetterBlizzFramesDB.variable inside of the target/focus aura function caused taint error.
-- and making it local like this fixed it. Idk why idk how and idk why im still doing it like this.

local auraSpacingX = 4
local auraSpacingY = 4
local aurasPerRow = 5
local targetAndFocusAuraOffsetY = 0
local baseOffsetX = 25
local baseOffsetY = 12.5
local auraScale = 1
local auraTypeGap = 1
local targetAndFocusSmallAuraScale = 1.4
local auraFilteringOn
local shouldAdjustCastbar
local shouldAdjustCastbarFocus
local targetCastBarXPos = 0
local targetCastBarYPos = 0
local focusCastBarXPos = 0
local focusCastBarYPos = 0
local targetToTCastbarAdjustment
local targetAndFocusAuraScale = 1
local targetAndFocusVerticalGap = 4
local targetDetachCastbar
local focusToTCastbarAdjustment
local targetStaticCastbar
local playerAuraSpacingX = 0
local playerAuraSpacingY = 0
local playerBuffFilterOn
local focusStaticCastbar
local focusDetachCastbar
local targetToTAdjustmentOffsetY
local focusToTAdjustmentOffsetY
local buffsOnTopReverseCastbarMovement
local targetCastBarScale
local focusCastBarScale
local increaseAuraStrata
local sameSizeAuras
local cachedSmallAuraSize = 0
local cachedInitialOffsetX = 0
local cachedInitialOffsetY = 0
local cachedAdjustmentForBuffsOnTop = 0
local cachedTargetStaticCastBarYOffset = 0
local cachedFocusStaticCastBarYOffset = 0
local cachedTargetCastBarXOffset = 0
local cachedFocusCastBarXOffset = 0
local cachedTargetCastBarScaleAdjustment = 0
local cachedFocusCastBarScaleAdjustment = 0
local cachedDynamicTargetCastBarYPos = 0
local auraCdTextSize = 0.55
local showAuraCdText
local auraStackSize = 1

local hideTargetBuffs
local hideTargetDebuffs
local hideFocusBuffs
local hideFocusDebuffs

local function UpdateMore()
    increaseAuraStrata = BetterBlizzFramesDB.increaseAuraStrata
    sameSizeAuras = BetterBlizzFramesDB.sameSizeAuras
    TargetFrame.staticCastbar = (BetterBlizzFramesDB.targetStaticCastbar or BetterBlizzFramesDB.targetDetachCastbar) and true or false
    FocusFrame.staticCastbar = (BetterBlizzFramesDB.focusStaticCastbar or BetterBlizzFramesDB.focusDetachCastbar) and true or false
    hideTargetBuffs = BetterBlizzFramesDB.hideTargetBuffs
    hideTargetDebuffs = BetterBlizzFramesDB.hideTargetDebuffs
    hideFocusBuffs = BetterBlizzFramesDB.hideFocusBuffs
    hideFocusDebuffs = BetterBlizzFramesDB.hideFocusDebuffs
    auraCdTextSize = BetterBlizzFramesDB.auraCdTextSize
    showAuraCdText= BetterBlizzFramesDB.showAuraCdText
    auraStackSize = BetterBlizzFramesDB.auraStackSize

    -- Aura size calculations
    cachedSmallAuraSize = sameSizeAuras and 21 or 17 * targetAndFocusSmallAuraScale
    cachedInitialOffsetX = baseOffsetX / auraScale
    cachedInitialOffsetY = baseOffsetY / auraScale
    cachedAdjustmentForBuffsOnTop = -102 - targetAndFocusAuraOffsetY

    -- Castbar offset calculations
    cachedTargetStaticCastBarYOffset = -14 + targetCastBarYPos
    cachedFocusStaticCastBarYOffset = -14 + focusCastBarYPos
    cachedTargetCastBarXOffset = 43 + targetCastBarXPos
    cachedFocusCastBarXOffset = 43 + focusCastBarXPos

    -- Castbar scale adjustments
    cachedTargetCastBarScaleAdjustment = 100 / targetCastBarScale
    cachedFocusCastBarScaleAdjustment = 100 / focusCastBarScale
    cachedDynamicTargetCastBarYPos = targetCastBarYPos + (targetAndFocusAuraOffsetY * 2)
end

function BBF.UpdateUserAuraSettings()
    auraSpacingX = BetterBlizzFramesDB.targetAndFocusHorizontalGap
    auraSpacingY = BetterBlizzFramesDB.targetAndFocusVerticalGap
    aurasPerRow = BetterBlizzFramesDB.targetAndFocusAurasPerRow
    targetAndFocusAuraOffsetY = BetterBlizzFramesDB.targetAndFocusAuraOffsetY
    baseOffsetX = 25 + BetterBlizzFramesDB.targetAndFocusAuraOffsetX + (BetterBlizzFramesDB.classicFrames and 1.5 or 0)
    baseOffsetY = 25.5 + BetterBlizzFramesDB.targetAndFocusAuraOffsetY + (BetterBlizzFramesDB.classicFrames and -0.5 or 0)
    auraScale = BetterBlizzFramesDB.targetAndFocusAuraScale
    auraTypeGap = BetterBlizzFramesDB.auraTypeGap
    targetAndFocusSmallAuraScale = BetterBlizzFramesDB.targetAndFocusSmallAuraScale
    auraFilteringOn = BetterBlizzFramesDB.playerAuraFiltering
    focusStaticCastbar = BetterBlizzFramesDB.focusStaticCastbar
    focusDetachCastbar = BetterBlizzFramesDB.focusDetachCastbar
    targetStaticCastbar = BetterBlizzFramesDB.targetStaticCastbar
    targetDetachCastbar = BetterBlizzFramesDB.targetDetachCastbar
    shouldAdjustCastbar = (targetStaticCastbar or targetDetachCastbar or BetterBlizzFramesDB.playerAuraFiltering) and not BetterBlizzFramesDB.disableCastbarMovement
    shouldAdjustCastbarFocus = (focusStaticCastbar or focusDetachCastbar or BetterBlizzFramesDB.playerAuraFiltering) and not BetterBlizzFramesDB.disableCastbarMovement
    targetCastBarXPos = BetterBlizzFramesDB.targetCastBarXPos
    targetCastBarYPos = BetterBlizzFramesDB.targetCastBarYPos
    focusCastBarXPos = BetterBlizzFramesDB.focusCastBarXPos
    focusCastBarYPos = BetterBlizzFramesDB.focusCastBarYPos
    targetToTAdjustmentOffsetY = BetterBlizzFramesDB.targetToTAdjustmentOffsetY
    focusToTAdjustmentOffsetY = BetterBlizzFramesDB.focusToTAdjustmentOffsetY
    targetToTCastbarAdjustment = BetterBlizzFramesDB.targetToTCastbarAdjustment
    targetAndFocusAuraScale = BetterBlizzFramesDB.targetAndFocusAuraScale
    targetAndFocusVerticalGap = BetterBlizzFramesDB.targetAndFocusVerticalGap
    focusToTCastbarAdjustment = BetterBlizzFramesDB.focusToTCastbarAdjustment
    playerAuraSpacingX = BetterBlizzFramesDB.playerAuraSpacingX
    playerAuraSpacingY = BetterBlizzFramesDB.playerAuraSpacingY
    playerBuffFilterOn = BetterBlizzFramesDB.playerAuraFiltering and BetterBlizzFramesDB.enablePlayerBuffFiltering
    targetCastBarScale = BetterBlizzFramesDB.targetCastBarScale
    focusCastBarScale = BetterBlizzFramesDB.focusCastBarScale
    buffsOnTopReverseCastbarMovement = BetterBlizzFramesDB.buffsOnTopReverseCastbarMovement
    UpdateMore()
end

local function CalculateAuraRowsYOffset(frame, rowHeights, castBarScale)
    local totalHeight = 0
    for _, height in ipairs(rowHeights) do
        totalHeight = totalHeight + (height * targetAndFocusAuraScale) / castBarScale  -- Scaling each row height
    end
    return totalHeight + #rowHeights * targetAndFocusVerticalGap
end

local function adjustCastbar(self, frame)
    local meta = getmetatable(self).__index
    local parent = meta.GetParent(self)

    if self.bbfHiddenCastbar then
        meta.SetClampedToScreen(self, false)
        meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", 0, 9000)
        return
    end

    -- If hiding all auras, treat as if there are no auras
    local rowHeights = (parent.hidingAllAuras and {}) or parent.rowHeights or {}

    meta.ClearAllPoints(self)
    if frame == TargetFrameSpellBar then
        local buffsOnTop = parent.buffsOnTop
        local yOffset = 14 + 5
        if targetStaticCastbar then
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", cachedTargetCastBarXOffset, cachedTargetStaticCastBarYOffset);
        elseif targetDetachCastbar then
            meta.SetPoint(self, "CENTER", UIParent, "CENTER", targetCastBarXPos, targetCastBarYPos);
        elseif buffsOnTopReverseCastbarMovement and buffsOnTop then
            yOffset = yOffset + CalculateAuraRowsYOffset(parent, rowHeights, targetCastBarScale) + cachedTargetCastBarScaleAdjustment
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", cachedTargetCastBarXOffset, targetCastBarYPos + yOffset);
        else
            if not buffsOnTop then
                yOffset = yOffset - CalculateAuraRowsYOffset(parent, rowHeights, targetCastBarScale)
            end
            if targetToTCastbarAdjustment and parent.haveToT then
                local minOffset = -40
                yOffset = min(minOffset, yOffset)
                yOffset = yOffset + targetToTAdjustmentOffsetY
            end
            if buffsOnTop then
                meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", cachedTargetCastBarXOffset, targetCastBarYPos + yOffset);
            else
                meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", cachedTargetCastBarXOffset, cachedDynamicTargetCastBarYPos + yOffset);
            end
        end
    elseif frame == FocusFrameSpellBar then
        local buffsOnTop = parent.buffsOnTop
        local yOffset = 14
        if focusStaticCastbar then
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", cachedFocusCastBarXOffset, cachedFocusStaticCastBarYOffset);
        elseif focusDetachCastbar then
            meta.SetPoint(self, "CENTER", UIParent, "CENTER", focusCastBarXPos, focusCastBarYPos);
        elseif buffsOnTopReverseCastbarMovement and buffsOnTop then
            yOffset = yOffset + CalculateAuraRowsYOffset(parent, rowHeights, focusCastBarScale) + cachedFocusCastBarScaleAdjustment
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", cachedFocusCastBarXOffset, focusCastBarYPos + yOffset);
        else
            if not buffsOnTop then
                yOffset = yOffset - CalculateAuraRowsYOffset(parent, rowHeights, focusCastBarScale)
            end
            if focusToTCastbarAdjustment and parent.haveToT then
                local minOffset = -40
                yOffset = min(minOffset, yOffset)
                yOffset = yOffset + focusToTAdjustmentOffsetY
            end
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", cachedFocusCastBarXOffset, focusCastBarYPos + yOffset);
        end
    end
end

local function DefaultCastbarAdjustment(self, frame)
    local meta = getmetatable(self).__index
    local parentFrame = meta.GetParent(self)

    if self.bbfHiddenCastbar then
        meta.SetClampedToScreen(self, false)
        meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", 0, 9000)
        return
    end

    -- Determine whether to use the adjusted logic based on BetterBlizzFramesDB setting
    -- If hiding all auras, treat as if there are no auras (don't use spellbarAnchor)
    local useSpellbarAnchor = not parentFrame.hidingAllAuras and (buffsOnTopReverseCastbarMovement and
                              ((parentFrame.haveToT and parentFrame.auraRows > 2) or (not parentFrame.haveToT and parentFrame.auraRows > 0)) or
                              (not buffsOnTopReverseCastbarMovement and not parentFrame.buffsOnTop and 
                               ((parentFrame.haveToT and parentFrame.auraRows > 2) or (not parentFrame.haveToT and parentFrame.auraRows > 0))))

    local relativeKey = useSpellbarAnchor and parentFrame.spellbarAnchor or parentFrame
    local pointX = useSpellbarAnchor and 18 or (parentFrame.smallSize and 38 or 43)
    local pointY = useSpellbarAnchor and -10 or (parentFrame.smallSize and 3 or 5)

    -- Adjustments for ToT and specific frame adjustments
    if (not useSpellbarAnchor) and parentFrame.haveToT then
        local totAdjustment = ((frame == TargetFrameSpellBar and targetToTCastbarAdjustment) or (frame == FocusFrameSpellBar and focusToTCastbarAdjustment))
        if totAdjustment then
            pointY = parentFrame.smallSize and -48 or -46
            if frame == TargetFrameSpellBar then
                pointY = pointY + targetToTAdjustmentOffsetY
            elseif frame == FocusFrameSpellBar then
                pointY = pointY + focusToTAdjustmentOffsetY
            end
        end
    end

    if frame == TargetFrameSpellBar then
        pointX = pointX + targetCastBarXPos
        pointY = pointY + targetCastBarYPos
    elseif frame == FocusFrameSpellBar then
        pointX = pointX + focusCastBarXPos
        pointY = pointY + focusCastBarYPos
    end

    -- Apply setting-specific adjustment
    if buffsOnTopReverseCastbarMovement then
        meta.SetPoint(self, "TOPLEFT", relativeKey, "BOTTOMLEFT", pointX, -pointY + 50)
    else
        meta.SetPoint(self, "TOPLEFT", relativeKey, "BOTTOMLEFT", pointX, pointY)
    end
end

function BBF.CastbarAdjustCaller()
    BBF.UpdateUserAuraSettings()
    if shouldAdjustCastbar or shouldAdjustCastbarFocus then
        if shouldAdjustCastbar then
            adjustCastbar(TargetFrame.spellbar, TargetFrameSpellBar)
        end
        if shouldAdjustCastbarFocus then
            adjustCastbar(FocusFrame.spellbar, FocusFrameSpellBar)
        end
    else
        DefaultCastbarAdjustment(TargetFrame.spellbar, TargetFrameSpellBar)
        DefaultCastbarAdjustment(FocusFrame.spellbar, FocusFrameSpellBar)
    end
end

local function addMasque(frameType)
    if MasqueOn then
        if frameType == "target" then
            MasqueTargetBuffs:ReSkin(true)
            MasqueTargetDebuffs:ReSkin(true)
        else
            MasqueFocusBuffs:ReSkin(true)
            MasqueFocusDebuffs:ReSkin(true)
        end
    end
end

local function MapFramesByInstanceID(self)
    local byId = {}
    for f in self.auraPools:EnumerateActive() do
        if f.auraInstanceID then
            byId[f.auraInstanceID] = f
        end
    end
    return byId
end

local function CollectOrderedFrames(self, auraList)
    if not auraList or not auraList.Iterate then return {} end
    local frames, byId = {}, MapFramesByInstanceID(self)
    auraList:Iterate(function(auraInstanceID, aura)
        local f = byId[auraInstanceID]
        if f and f:IsShown() then
            frames[#frames+1] = f
        end
        return false
    end)
    return frames
end


local function PlaceAuraGroup(self, list, forceNewRowAtStart, rowWidths, rowHeights, currentYOffset, auraScale, cachedSmallAuraSize, aurasPerRow, cachedInitialOffsetX, auraSpacingX, auraSpacingY, auraTypeGap)
    local placed = 0

    if forceNewRowAtStart and #rowHeights > 0 then
        if self.buffsOnTop then
            currentYOffset = currentYOffset + (rowHeights[#rowHeights] or 0) + auraSpacingY
        else
            currentYOffset = currentYOffset - (rowHeights[#rowHeights] or 0) - auraSpacingY
        end
    end

    local baseRow = #rowHeights
    local i = 0
    for _, aura in ipairs(list) do
        i = i + 1
        placed = placed + 1

        aura:SetScale(auraScale)
        aura:SetAlpha(1)
        aura:EnableMouse(true)

        if showAuraCdText then
            aura.Cooldown:SetHideCountdownNumbers(false)
            local cdText = aura.Cooldown and aura.Cooldown:GetRegions()
            if cdText then
                cdText:SetScale(auraCdTextSize)
            end
        end
        local size = aura:GetWidth() > 20 and 21 or cachedSmallAuraSize
        aura:SetSize(size, size)
        aura:SetMouseClickEnabled(false)
        aura.Count:SetScale(auraStackSize)
        if increaseAuraStrata then
            aura:SetFrameStrata("FULLSCREEN")
        end

        local columnIndex = (i - 1) % aurasPerRow
        local rowIndexGroup = math_ceil(i / aurasPerRow)
        local rowNum = baseRow + rowIndexGroup

        rowWidths[rowNum] = rowWidths[rowNum] or cachedInitialOffsetX

        if columnIndex == 0 and i ~= 1 then
            if self.buffsOnTop then
                currentYOffset = currentYOffset + (rowHeights[rowNum - 1] or 0) + auraSpacingY
            else
                currentYOffset = currentYOffset - (rowHeights[rowNum - 1] or 0) - auraSpacingY
            end
        elseif columnIndex ~= 0 then
            rowWidths[rowNum] = rowWidths[rowNum] + auraSpacingX
        end

        local offsetX = rowWidths[rowNum]
        rowHeights[rowNum] = math_max(size, (rowHeights[rowNum] or 0))
        rowWidths[rowNum] = offsetX + size

        aura:ClearAllPoints()
        if self.buffsOnTop then
            aura:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", offsetX, currentYOffset)
        else
            aura:SetPoint("TOPLEFT", self, "BOTTOMLEFT", offsetX, currentYOffset)
        end
    end

    return placed, currentYOffset
end

local function AdjustAuras(self, frameType)
    self.previousAuraRows = self.previousAuraRows or 0

    local hideBuffs = false
    local hideDebuffs = false

    if frameType == "target" then
        hideBuffs = hideTargetBuffs
        hideDebuffs = hideTargetDebuffs
    elseif frameType == "focus" then
        hideBuffs = hideFocusBuffs
        hideDebuffs = hideFocusDebuffs
    end

    local buffs   = CollectOrderedFrames(self, self.activeBuffs)
    local debuffs = CollectOrderedFrames(self, self.activeDebuffs)

    if hideBuffs then
        for _, buff in ipairs(buffs) do
            buff:SetAlpha(0)
            buff:EnableMouse(false)
        end
        buffs = {}
    end

    if hideDebuffs then
        for _, debuff in ipairs(debuffs) do
            debuff:SetAlpha(0)
            debuff:EnableMouse(false)
        end
        debuffs = {}
    end

    local unit = self.unit
    local isFriend = unit and not UnitCanAttack("player", unit)

    local rowWidths, rowHeights = {}, {}
    local currentYOffset = targetAndFocusAuraOffsetY + (self.buffsOnTop and -(cachedInitialOffsetY + cachedAdjustmentForBuffsOnTop) or cachedInitialOffsetY)

    if not isFriend then
        if self.buffsOnTop then
            self.rowHeights = {}
            local _, newYOffset = PlaceAuraGroup(self, debuffs, false, rowWidths, rowHeights, currentYOffset, auraScale, cachedSmallAuraSize, aurasPerRow, cachedInitialOffsetX, auraSpacingX, auraSpacingY, auraTypeGap)
            currentYOffset = newYOffset
            local debuffRows = #rowHeights
            if #debuffs > 0 and #buffs > 0 then
                currentYOffset = currentYOffset + auraTypeGap
            end
            PlaceAuraGroup(self, buffs, #debuffs > 0, rowWidths, rowHeights, currentYOffset, auraScale, cachedSmallAuraSize, aurasPerRow, cachedInitialOffsetX, auraSpacingX, auraSpacingY, auraTypeGap)
            if #debuffs > 0 and #buffs > 0 and debuffRows > 0 then
                rowHeights[debuffRows] = rowHeights[debuffRows] + auraTypeGap
            end
        else
            self.rowHeights = {}
            local _, newYOffset = PlaceAuraGroup(self, debuffs, false, rowWidths, rowHeights, currentYOffset, auraScale, cachedSmallAuraSize, aurasPerRow, cachedInitialOffsetX, auraSpacingX, auraSpacingY, auraTypeGap)
            currentYOffset = newYOffset
            local debuffRows = #rowHeights
            if #debuffs > 0 and #buffs > 0 then
                currentYOffset = currentYOffset - auraTypeGap
            end
            PlaceAuraGroup(self, buffs, #debuffs > 0, rowWidths, rowHeights, currentYOffset, auraScale, cachedSmallAuraSize, aurasPerRow, cachedInitialOffsetX, auraSpacingX, auraSpacingY, auraTypeGap)
            if #debuffs > 0 and #buffs > 0 and debuffRows > 0 then
                rowHeights[debuffRows] = rowHeights[debuffRows] + auraTypeGap
            end
        end
    else
        if self.buffsOnTop then
            self.rowHeights = {}
            local _, newYOffset = PlaceAuraGroup(self, buffs, false, rowWidths, rowHeights, currentYOffset, auraScale, cachedSmallAuraSize, aurasPerRow, cachedInitialOffsetX, auraSpacingX, auraSpacingY, auraTypeGap)
            currentYOffset = newYOffset
            local buffRows = #rowHeights
            if #buffs > 0 and #debuffs > 0 then
                currentYOffset = currentYOffset + auraTypeGap
            end
            PlaceAuraGroup(self, debuffs, #buffs > 0, rowWidths, rowHeights, currentYOffset, auraScale, cachedSmallAuraSize, aurasPerRow, cachedInitialOffsetX, auraSpacingX, auraSpacingY, auraTypeGap)
            if #buffs > 0 and #debuffs > 0 and buffRows > 0 then
                rowHeights[buffRows] = rowHeights[buffRows] + auraTypeGap
            end
        else
            self.rowHeights = {}
            local _, newYOffset = PlaceAuraGroup(self, buffs, false, rowWidths, rowHeights, currentYOffset, auraScale, cachedSmallAuraSize, aurasPerRow, cachedInitialOffsetX, auraSpacingX, auraSpacingY, auraTypeGap)
            currentYOffset = newYOffset
            local buffRows = #rowHeights
            if #buffs > 0 and #debuffs > 0 then
                currentYOffset = currentYOffset - auraTypeGap
            end
            PlaceAuraGroup(self, debuffs, #buffs > 0, rowWidths, rowHeights, currentYOffset, auraScale, cachedSmallAuraSize, aurasPerRow, cachedInitialOffsetX, auraSpacingX, auraSpacingY, auraTypeGap)
            if #buffs > 0 and #debuffs > 0 and buffRows > 0 then
                rowHeights[buffRows] = rowHeights[buffRows] + auraTypeGap
            end
        end
    end

    self.rowHeights = rowHeights

    if not self.staticCastbar then
        if frameType == "target" then
            adjustCastbar(self.spellbar, TargetFrameSpellBar)
        elseif frameType == "focus" then
            adjustCastbar(self.spellbar, FocusFrameSpellBar)
        end
    end

    self.previousAuraRows = #self.rowHeights
end

local function HideAuras(self, frameType)
    self.previousAuraRows = 0

    for aura in self.auraPools:EnumerateActive() do
        aura:Hide()
    end

    if not self.staticCastbar then
        if frameType == "target" then
            adjustCastbar(self.spellbar, TargetFrameSpellBar)
        elseif frameType == "focus" then
            adjustCastbar(self.spellbar, FocusFrameSpellBar)
        end
    end
end


local BuffFrame = BuffFrame
local function PersonalBuffFrameFilterAndGrid()
    local isExpanded = BuffFrame.IsExpanded
    local addIconsToRight = BuffFrame.AuraContainer.addIconsToRight
    local addIconsToTop = BuffFrame.AuraContainer.addIconsToTop
    local maxAurasPerRow = BuffFrame.AuraContainer.iconStride
    local auraSpacingX = BuffFrame.AuraContainer.iconPadding - 7 + playerAuraSpacingX
    local auraSpacingY = BuffFrame.AuraContainer.iconPadding + 8 + playerAuraSpacingY
    local auraSize = 32

    local currentRow, currentCol = 1, 1
    local xOffset, yOffset = 0, 0

    if isExpanded then
        for auraIndex, auraInfo in ipairs(BuffFrame.auraInfo or {}) do
            local auraFrame = BuffFrame.auraFrames[auraIndex]
            if auraFrame and not auraFrame.isAuraAnchor then
                auraFrame:ClearAllPoints()

                if addIconsToRight then
                    if addIconsToTop then
                        auraFrame:SetPoint("BOTTOMLEFT", BuffFrame, "BOTTOMLEFT", xOffset + 15, yOffset)
                    else
                        auraFrame:SetPoint("TOPLEFT", BuffFrame, "TOPLEFT", xOffset + 15, -yOffset)
                    end
                else
                    if addIconsToTop then
                        auraFrame:SetPoint("BOTTOMRIGHT", BuffFrame, "BOTTOMRIGHT", -xOffset - 15, yOffset)
                    else
                        auraFrame:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", -xOffset - 15, -yOffset)
                    end
                end

                currentCol = currentCol + 1
                if currentCol > maxAurasPerRow then
                    currentRow = currentRow + 1
                    currentCol = 1
                end

                xOffset = (currentCol - 1) * (auraSize + auraSpacingX)
                yOffset = (currentRow - 1) * (auraSize + auraSpacingY)

            end
        end
    end
end

local DebuffFrame = DebuffFrame
local function PersonalDebuffFrameFilterAndGrid()
    local maxAurasPerRow = DebuffFrame.AuraContainer.iconStride
    local auraSpacingX = DebuffFrame.AuraContainer.iconPadding - 7 + playerAuraSpacingX
    local auraSpacingY = DebuffFrame.AuraContainer.iconPadding + 8 + playerAuraSpacingY
    local auraSize = 32;
    local addIconsToRight = DebuffFrame.AuraContainer.addIconsToRight
    local addIconsToTop = DebuffFrame.AuraContainer.addIconsToTop

    local currentRow = 1;
    local currentCol = 1;
    local xOffset = 0;
    local yOffset = 0;

    for auraIndex, auraInfo in ipairs(DebuffFrame.auraInfo or {}) do
        local auraFrame = DebuffFrame.auraFrames[auraIndex]
        if auraFrame and not auraFrame.isAuraAnchor then
            auraFrame:ClearAllPoints();
            if addIconsToRight then
                if addIconsToTop then
                    auraFrame:SetPoint("BOTTOMLEFT", DebuffFrame, "BOTTOMLEFT", xOffset, yOffset);
                else
                    auraFrame:SetPoint("TOPLEFT", DebuffFrame, "TOPLEFT", xOffset, -yOffset);
                end
            else
                if addIconsToTop then
                    auraFrame:SetPoint("BOTTOMRIGHT", DebuffFrame, "BOTTOMRIGHT", -xOffset, yOffset);
                else
                    auraFrame:SetPoint("TOPRIGHT", DebuffFrame, "TOPRIGHT", -xOffset, -yOffset);
                end
            end

            currentCol = currentCol + 1;
            if currentCol > maxAurasPerRow then
                currentRow = currentRow + 1;
                currentCol = 1;
            end

            xOffset = (currentCol - 1) * (auraSize + auraSpacingX);
            yOffset = (currentRow - 1) * (auraSize + auraSpacingY);

            auraFrame.Duration:SetParent(auraFrame)
            auraFrame:SetMouseClickEnabled(false)
        end
    end
end


function BBF.RefreshAllAuraFrames()
    BBF.UpdateUserAuraSettings()
    AdjustAuras(TargetFrame, "target")
    AdjustAuras(FocusFrame, "focus")
    if BetterBlizzFramesDB.playerAuraFiltering then
        if playerBuffFilterOn then
            PersonalBuffFrameFilterAndGrid()
            PersonalDebuffFrameFilterAndGrid()
        end
    end
end

BBF.filterOverride = false
function BBF.ToggleFilterOverride()
end

function BBF.SetupMasqueSupport()
    if not BBFMIDNIGHT then return end
    Masque = LibStub("Masque", true)
    if Masque then
        MasqueOn = true
        MasquePlayerBuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Player Buffs")
        MasquePlayerDebuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Player Debuffs")
        MasqueTargetBuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Target Buffs")
        MasqueTargetDebuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Target Debuffs")
        MasqueFocusBuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Focus Buffs")
        MasqueFocusDebuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Focus Debuffs")
        local MasqueCastbars = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Castbars")

        local function MsqSkinIcon(frame, group)
            local skinWrapper = CreateFrame("Frame")
            skinWrapper:SetParent(frame)
            skinWrapper:SetSize(30, 30)
            skinWrapper:SetAllPoints(frame.Icon)
            frame.Icon:Hide()
            frame.SkinnedIcon = skinWrapper:CreateTexture(nil, "BACKGROUND")
            frame.SkinnedIcon:SetSize(30, 30)
            frame.SkinnedIcon:SetPoint("CENTER")
            frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())
            hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
                skinWrapper:SetScale(frame.Icon:GetScale())
                frame.Icon:SetAlpha(0)
                frame.SkinnedIcon:SetTexture(tex)
            end)
            group:AddButton(skinWrapper, {
                Icon = frame.SkinnedIcon,
            })
        end
        if BetterBlizzFramesDB.playerCastBarShowIcon then
            MsqSkinIcon(PlayerCastingBarFrame, MasqueCastbars)
        end
        MsqSkinIcon(TargetFrameSpellBar, MasqueCastbars)
        MsqSkinIcon(FocusFrameSpellBar, MasqueCastbars)
        if BetterBlizzFramesDB.showPartyCastbar and BetterBlizzFramesDB.showPartyCastBarIcon then
            C_Timer.After(3, function()
                for i = 1, 5 do
                    local castbar = _G["Party"..i.."SpellBar"]
                    if castbar then
                        MsqSkinIcon(castbar, MasqueCastbars)
                    end
                end
            end)
        end

        -- Props to Masque Skinner: Blizz Buffs by Cybeloras of Aerie Peak
        local skinned = {}
        local function makeHook(group, container)
            local function updateFrames(frames)
                for i = 1, #frames do
                    local frame = frames[i]
                    if not skinned[frame] and frame.Icon.GetTexture then
                        skinned[frame] = 1

                        -- We have to make a wrapper to hold the skinnable components of the Icon
                        -- because the aura frames are not square (and so if we skinned them directly
                        -- with Masque, they'd get all distorted and weird).
                        local skinWrapper = CreateFrame("Frame")
                        skinWrapper:SetParent(frame)
                        skinWrapper:SetSize(30, 30)
                        skinWrapper:SetPoint("TOP")

                        -- Blizzard's code constantly tries to reposition the icon,
                        -- so we have to make our own icon that it won't try to move.
                        frame.Icon:Hide()
                        frame.SkinnedIcon = skinWrapper:CreateTexture(nil, "BACKGROUND")
                        frame.SkinnedIcon:SetSize(30, 30)
                        frame.SkinnedIcon:SetPoint("CENTER")
                        frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())
                        hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
                            frame.SkinnedIcon:SetTexture(tex)
                        end)

                        if frame.Count then
                            -- edit mode versions don't have stack text
                            frame.Count:SetParent(skinWrapper);
                        end
                        if frame.DebuffBorder then
                            frame.DebuffBorder:SetParent(skinWrapper);
                        end
                        if frame.TempEnchantBorder then
                            frame.TempEnchantBorder:SetParent(skinWrapper);
                            frame.TempEnchantBorder:SetVertexColor(.75, 0, 1)
                        end
                        if frame.Symbol then
                            -- Shows debuff types as text in colorblind mode (except it currently doesnt work)
                            frame.Symbol:SetParent(skinWrapper);
                        end

                        if C_AddOns.IsAddOnLoaded("SUI") then
                            local skinWrapper2 = CreateFrame("Frame")
                            skinWrapper2:SetParent(skinWrapper)
                            skinWrapper2:SetSize(30, 40)
                            skinWrapper2:SetPoint("TOP")
                            frame.Duration:SetParent(skinWrapper2)
                        end

                        local bType = frame.auraType or "Aura"

                        if bType == "DeadlyDebuff" then
                            bType = "Debuff"
                        end

                        group:AddButton(skinWrapper, {
                            Icon = frame.SkinnedIcon,
                            DebuffBorder = frame.DebuffBorder,
                            EnchantBorder = frame.TempEnchantBorder,
                            Count = frame.Count,
                            HotKey = frame.Symbol
                        }, bType)
                    end
                end
            end

            return function(self)
                updateFrames(self.auraFrames, group)
                if self.exampleAuraFrames then
                    updateFrames(self.exampleAuraFrames, group)
                end
            end
        end

        hooksecurefunc(BuffFrame, "UpdateAuraButtons", makeHook(MasquePlayerBuffs, BuffFrame))
        hooksecurefunc(BuffFrame, "OnEditModeEnter", makeHook(MasquePlayerBuffs, BuffFrame))
        hooksecurefunc(DebuffFrame, "UpdateAuraButtons", makeHook(MasquePlayerDebuffs, DebuffFrame))
        hooksecurefunc(DebuffFrame, "OnEditModeEnter", makeHook(MasquePlayerDebuffs, DebuffFrame))

        C_Timer.After(1.5, function()
            if toggleIconGlobal then
                MasquePlayerBuffs:AddButton(toggleIconGlobal)
            end
        end)

        local function hookUnitFrameAuras(frame, buffGroup, debuffGroup)
            local function updateUnitFrameAuras()
                for aura in frame.auraPools:EnumerateActive() do
                    if not skinned[aura] then
                        skinned[aura] = true
                        -- Check if the aura is a debuff
                        if aura.Border then
                            debuffGroup:AddButton(aura, {
                                Icon = aura.Icon,
                                DebuffBorder = aura.Border,
                                Cooldown = aura.Cooldown,
                            })
                        else
                            buffGroup:AddButton(aura, {
                                Icon = aura.Icon,
                                Cooldown = aura.Cooldown,
                            })
                        end
                    end
                end
                if not auraFilteringOn then
                    buffGroup:ReSkin(true)
                    debuffGroup:ReSkin(true)
                end
            end

            updateUnitFrameAuras()

            hooksecurefunc(frame, "UpdateAuras", updateUnitFrameAuras)
        end

        hookUnitFrameAuras(TargetFrame, MasqueTargetBuffs, MasqueTargetDebuffs)
        hookUnitFrameAuras(FocusFrame, MasqueFocusBuffs, MasqueFocusDebuffs)
    end
end

function BBF.HookPlayerAndTargetAuras()
    if BBF.isMidnight then
        if not targetCastbarsHooked and not BetterBlizzFramesDB.disableCastbarMovement then
            hooksecurefunc(TargetFrame.spellbar, "SetPoint", function()
                if shouldAdjustCastbar then
                    adjustCastbar(TargetFrame.spellbar, TargetFrameSpellBar)
                else
                    DefaultCastbarAdjustment(TargetFrame.spellbar, TargetFrameSpellBar)
                end
            end);
            hooksecurefunc(FocusFrame.spellbar, "SetPoint", function()
                if shouldAdjustCastbarFocus then
                    adjustCastbar(FocusFrame.spellbar, FocusFrameSpellBar)
                else
                    DefaultCastbarAdjustment(FocusFrame.spellbar, FocusFrameSpellBar)
                end
            end);
            targetCastbarsHooked = true
        end
        if BetterBlizzFramesDB.disableCastbarMovement then
            TargetFrame.staticCastbar = true
            FocusFrame.staticCastbar = true
        end
        if auraFilteringOn and not targetAurasHooked then
            if hideTargetBuffs and hideTargetDebuffs then
                hooksecurefunc(TargetFrame, "UpdateAuras", function(self) HideAuras(self, "target") end)
                TargetFrame.hidingAllAuras = true
            else
                hooksecurefunc(TargetFrame, "UpdateAuras", function(self) AdjustAuras(self, "target") end)
            end
            if hideFocusBuffs and hideFocusDebuffs then
                hooksecurefunc(FocusFrame, "UpdateAuras", function(self) HideAuras(self, "focus") end)
                FocusFrame.hidingAllAuras = true
            else
                hooksecurefunc(FocusFrame, "UpdateAuras", function(self) AdjustAuras(self, "focus") end)
            end
            targetAurasHooked = true
        end
        --return
    end
    -- --Hook Player BuffFrame
    if playerBuffFilterOn and not playerBuffsHooked then
        if BetterBlizzFramesDB.PlayerAuraFrameBuffEnable then
            hooksecurefunc(BuffFrame, "UpdateAuraButtons", PersonalBuffFrameFilterAndGrid)
            playerBuffsHooked = true
            if BBF.BuffFrameHidden then
                BuffFrame:Show()
                BBF.BuffFrameHidden = nil
            end
            hooksecurefunc(DebuffFrame, "UpdateAuraButtons", PersonalDebuffFrameFilterAndGrid)
            if BBF.DebuffFrameHidden then
                DebuffFrame:Show()
                BBF.DebuffFrameHidden = nil
            end
        else
            BuffFrame:Hide()
            BBF.BuffFrameHidden = true
        end
    end
end