if not BBF.isMidnight then return end
local L = BBF.L
local spellBars = {}
local castBarsCreated = false
local petCastbarCreated = false

local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local classicCastbarTexture = 137012
function BBF.UpdateClassicCastbarTexture(texture)
    classicCastbarTexture = BetterBlizzFramesDB.changeUnitFrameCastbarTexture and texture or 137012
end

local targetSpellBarTexture = TargetFrameSpellBar:GetStatusBarTexture()
local focusSpellBarTexture = FocusFrameSpellBar:GetStatusBarTexture()
local highlightStartTime = BetterBlizzFramesDB.castBarInterruptHighlighterStartTime
local highlightEndTime = BetterBlizzFramesDB.castBarInterruptHighlighterEndTime
local edgeColor = BetterBlizzFramesDB.castBarInterruptHighlighterInterruptRGB
local middleColor = BetterBlizzFramesDB.castBarInterruptHighlighterDontInterruptRGB
local colorMiddle = BetterBlizzFramesDB.castBarInterruptHighlighterColorDontInterrupt
local castBarNoInterruptColor = BetterBlizzFramesDB.castBarNoInterruptColor
local castBarDelayedInterruptColor = BetterBlizzFramesDB.castBarDelayedInterruptColor
local castBarRecolorInterrupt = BetterBlizzFramesDB.castBarRecolorInterrupt
local castBarInterruptHighlighter = BetterBlizzFramesDB.castBarInterruptHighlighter
local targetCastbarEdgeHighlight = BetterBlizzFramesDB.targetCastbarEdgeHighlight
local focusCastbarEdgeHighlight = BetterBlizzFramesDB.focusCastbarEdgeHighlight
local recolorCastbars = BetterBlizzFramesDB.recolorCastbars
local castbarColors = {
    standard        = BetterBlizzFramesDB.castbarCastColor,
    interrupted     = { 1, 0, 0 },
    channel       = BetterBlizzFramesDB.castbarChannelColor,
    uninterruptable = BetterBlizzFramesDB.castbarUninterruptableColor,
}
local defaultCastbarColors = {
    standard        = { 1, 0.7, 0 },
    interrupted     = { 1, 0, 0 },
    channel       = { 0, 1, 0 },
    uninterruptable = { 0.7, 0.7, 0.7 },
}

local function CreateBorder(frame, r, g, b, a)
    local border
    if frame.CreateTexture then
        border = frame:CreateTexture(nil, "OVERLAY", nil, -1)
    else
        border = frame:GetParent():CreateTexture(nil, "OVERLAY", nil, -1)
    end
    border:SetColorTexture(r, g, b, a)
    border:SetIgnoreParentScale(true)
    return border
end

function BBF.SetupBorderOnFrame(frame)
    if frame.newBorder then return end

    --frame:EnableMouse(true)

    if frame.TextBorder then
        frame.TextBorder:SetParent(BBF.hiddenFrame)
    end

    if frame.Flash then
        frame.Flash:SetParent(BBF.hiddenFrame)
    end

    if frame.ChargeFlash then
        frame.ChargeFlash:SetParent(BBF.hiddenFrame)
    end

    if frame.StandardGlow then
        frame.StandardGlow:SetParent(BBF.hiddenFrame)
    end

    if frame.CraftGlow then
        frame.CraftGlow:SetParent(BBF.hiddenFrame)
    end

    if frame.MaskTexture then
        frame.MaskTexture:Hide()
        frame.MaskTexture:SetParent(BBF.hiddenFrame)
        frame.MaskTexture:SetTexture(nil)
    end

    if frame.BorderMask then
        frame.BorderMask:Hide()
        frame.BorderMask:SetParent(BBF.hiddenFrame)
        frame.BorderMask:SetTexture(nil)
    end

    if frame.Text then
        if BetterBlizzFramesDB.castbarPixelBorderTextInside then
            frame.Text:ClearAllPoints()
            frame.Text:SetPoint("CENTER", frame, "CENTER", 0, 0)
        end
        if not frame.ogText then
            local font, size, flags = frame.Text:GetFont()
            frame.ogText = {font, size, flags}
            frame.Text:SetFont(font, size, "OUTLINE")
        end
    end

    if frame.Border then
        frame.Border:SetParent(BBF.hiddenFrame)
    end

    if frame.Background then
        frame.Background:SetColorTexture(0, 0, 0, 0.7)
    end

    -- Create borders
    local borderTop = CreateBorder(frame, 0, 0, 0, 1)
    local borderBottom = CreateBorder(frame, 0, 0, 0, 1)
    local borderLeft = CreateBorder(frame, 0, 0, 0, 1)
    local borderRight = CreateBorder(frame, 0, 0, 0, 1)

    frame["borders"] = {borderTop, borderBottom, borderLeft, borderRight}

    local borderThickness = 1
    local minPixels = 1


    local function SizeBorders(borderThickness)
        PixelUtil.SetHeight(borderTop, borderThickness, minPixels)
        PixelUtil.SetHeight(borderBottom, borderThickness, minPixels)
        PixelUtil.SetWidth(borderLeft, borderThickness, minPixels)
        PixelUtil.SetWidth(borderRight, borderThickness, minPixels)

        borderTop:ClearAllPoints()
        PixelUtil.SetPoint(borderTop, "BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
        PixelUtil.SetPoint(borderTop, "BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0)

        borderBottom:ClearAllPoints()
        PixelUtil.SetPoint(borderBottom, "TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
        PixelUtil.SetPoint(borderBottom, "TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0)

        borderLeft:ClearAllPoints()
        PixelUtil.SetPoint(borderLeft, "TOPLEFT", frame, "TOPLEFT", -borderThickness, borderThickness)
        PixelUtil.SetPoint(borderLeft, "BOTTOMLEFT", frame, "BOTTOMLEFT", -borderThickness, -borderThickness)

        borderRight:ClearAllPoints()
        PixelUtil.SetPoint(borderRight, "TOPRIGHT", frame, "TOPRIGHT", borderThickness, borderThickness)
        PixelUtil.SetPoint(borderRight, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderThickness, -borderThickness)
    end

    SizeBorders(borderThickness)

    function frame:SetBorderColor(r, g, b, a)
        for _, border in ipairs(self.borders) do
            border:SetColorTexture(r, g, b, a)
        end
    end

    function frame:SetBorderSize(size)
        SizeBorders(size)
    end

    if frame.Icon then
        local iconBorderTop = CreateBorder(frame.Icon, 0, 0, 0, 1)
        local iconBorderBottom = CreateBorder(frame.Icon, 0, 0, 0, 1)
        local iconBorderLeft = CreateBorder(frame.Icon, 0, 0, 0, 1)
        local iconBorderRight = CreateBorder(frame.Icon, 0, 0, 0, 1)

        frame.Icon["borders"] = {iconBorderTop, iconBorderBottom, iconBorderLeft, iconBorderRight}

        local iconBorderThickness = 1
        local minPixels = 1

        local function SizeIconBorders(borderThickness)
            PixelUtil.SetHeight(iconBorderTop, borderThickness, minPixels)
            PixelUtil.SetHeight(iconBorderBottom, borderThickness, minPixels)
            PixelUtil.SetWidth(iconBorderLeft, borderThickness, minPixels)
            PixelUtil.SetWidth(iconBorderRight, borderThickness, minPixels)

            iconBorderTop:ClearAllPoints()
            PixelUtil.SetPoint(iconBorderTop, "BOTTOMLEFT", frame.Icon, "TOPLEFT", 0, 0)
            PixelUtil.SetPoint(iconBorderTop, "BOTTOMRIGHT", frame.Icon, "TOPRIGHT", 0, 0)

            iconBorderBottom:ClearAllPoints()
            PixelUtil.SetPoint(iconBorderBottom, "TOPLEFT", frame.Icon, "BOTTOMLEFT", 0, 0)
            PixelUtil.SetPoint(iconBorderBottom, "TOPRIGHT", frame.Icon, "BOTTOMRIGHT", 0, 0)

            iconBorderLeft:ClearAllPoints()
            PixelUtil.SetPoint(iconBorderLeft, "TOPLEFT", frame.Icon, "TOPLEFT", -borderThickness, borderThickness)
            PixelUtil.SetPoint(iconBorderLeft, "BOTTOMLEFT", frame.Icon, "BOTTOMLEFT", -borderThickness, -borderThickness)

            iconBorderRight:ClearAllPoints()
            PixelUtil.SetPoint(iconBorderRight, "TOPRIGHT", frame.Icon, "TOPRIGHT", borderThickness, borderThickness)
            PixelUtil.SetPoint(iconBorderRight, "BOTTOMRIGHT", frame.Icon, "BOTTOMRIGHT", borderThickness, -borderThickness)
        end

        SizeIconBorders(iconBorderThickness)

        function frame.Icon:SetBorderColor(r, g, b, a)
            for _, border in ipairs(self.borders) do
                border:SetColorTexture(r, g, b, a)
            end
        end

        function frame.Icon:SetBorderSize(size)
            SizeIconBorders(size)
        end

        hooksecurefunc(frame.Icon, "Show", function(self)
            self:SetBorderColor(0, 0, 0, 1)
        end)

        hooksecurefunc(frame.Icon, "Hide", function(self)
            self:SetBorderColor(0, 0, 0, 0)
        end)

        hooksecurefunc(frame.Icon, "SetShown", function(self, shown)
            if shown then
                self:SetBorderColor(0, 0, 0, 1)
            else
                self:SetBorderColor(0, 0, 0, 0)
            end
        end)

        frame.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end

    frame.newBorder = true
end

local function UpdateCastTimer(self)
    if not BBFMIDNIGHT then return end
    local remainingTime
    if self.casting or self.reverseChanneling then
        -- For a cast, we calculate how much time is left until the cast completes
        remainingTime = self.maxValue - self.value
    elseif self.channeling then
        -- For a channel, the remaining time is directly related to the current value
        remainingTime = self.value
    end

    -- If the remaining time is zero or somehow negative, clear the timer
    if remainingTime then
        if remainingTime <= 0 then
            self.Timer:SetText("")
            return
        end
        self.Timer:SetFormattedText("%.1f", remainingTime)
    else
        self.Timer:SetText("")
    end
end

local function UpdateSparkPosition(castBar)
    if not BBFMIDNIGHT then return end
    local val = castBar:GetValue()
    local minVal, maxVal = castBar:GetMinMaxValues()
    --local progressPercent = castBar.value / castBar.maxValue
    if maxVal == 0 then return end
    local progressPercent = val / maxVal
    local newX = castBar:GetWidth() * progressPercent
    castBar.Spark:ClearAllPoints()
    castBar.Spark:SetPoint("CENTER", castBar, "LEFT", newX, 0)
end

local function HideChargeTiers(castBar)
    if not BBFMIDNIGHT then return end
    castBar.ChargeTier1:Hide()
    castBar.ChargeTier2:Hide()
    castBar.ChargeTier3:Hide()
    if castBar.ChargeTier4 then
        castBar.ChargeTier4:Hide()
    end
end

local function AdjustBorderSize(castBar)
    -- Only calculate scaling factors once based on initial castBar dimensions
    --if not castBar.borderAdjusted then
        local baseWidth, baseHeight = 150, 10       -- Original castBar dimensions
        local baseBorderWidth, baseBorderHeight = 200, 54.5 -- Original border dimensions

        -- Calculate scaling factors based on castBar's current size
        local widthScale = castBar:GetWidth() / baseWidth
        local heightScale = castBar:GetHeight() / baseHeight

        -- Apply scaled size to the border
        castBar.Border:SetTexture(130873)
        castBar.Border:SetSize(baseBorderWidth * widthScale, baseBorderHeight * heightScale)
        castBar.Border:ClearAllPoints()
        castBar.Border:SetPoint("CENTER", castBar, "CENTER", 0, 0)

        -- Mark as adjusted to prevent re-running this calculation
        --castBar.borderAdjusted = true
    --end
end

local function AdjustBorderShieldSize(castBar)
    -- Only calculate scaling factors once based on initial castBar dimensions
    --if not castBar.borderShieldAdjusted then
        local baseWidth, baseHeight = 150, 10       -- Original castBar dimensions
        local baseBorderWidth, baseBorderHeight = 196, 54.5 -- Original BorderShield dimensions
        local baseXOffset, baseYOffset = -28, 23    -- Original anchor offsets
        local baseIconSize = 18
        local baseIconYOffset = 1


        -- Calculate scaling factors based on castBar's current size
        local widthScale = castBar:GetWidth() / baseWidth
        local heightScale = castBar:GetHeight() / baseHeight

        -- Apply scaled size to the border
        castBar.BorderShield:SetTexture(311862)
        castBar.BorderShield:SetSize(baseBorderWidth * widthScale, baseBorderHeight * heightScale)
        castBar.BorderShield:SetDrawLayer("OVERLAY")
        castBar.BorderShield:SetScale(1)
        castBar.BorderShield:ClearAllPoints()

        castBar.uninterruptibleIconSize = baseIconSize * ((widthScale + heightScale) / 2)
        castBar.adjustedIconYOffset = baseIconYOffset * heightScale

        -- Adjust the anchor position based on scale
        castBar.BorderShield:SetPoint(
            "TOPLEFT", castBar, "TOPLEFT",
            baseXOffset * widthScale,
            baseYOffset * heightScale
        )

        -- Mark as adjusted to prevent re-running this calculation
        --castBar.borderShieldAdjusted = true
    --end
end

local function AdjustFlash(castBar)
    local baseWidth, baseHeight = 208, 11
    local baseOffsetX = 33
    local baseOffsetYTop = 23
    local baseOffsetYBottom = -23

    -- Calculate scaling factors based on the current dimensions of the cast bar
    local widthScale = castBar:GetWidth() / baseWidth
    local heightScale = castBar:GetHeight() / baseHeight

    -- Adjust the offsets based on the scaling factors
    local offsetX = baseOffsetX * widthScale
    local offsetYTop = baseOffsetYTop * heightScale
    local offsetYBottom = baseOffsetYBottom * heightScale

    castBar.Flash:SetTexture(BetterBlizzFramesDB.classicCastbarsPlayerBorder and 130876 or 130875)
    castBar.Flash:ClearAllPoints()
    castBar.Flash:SetPoint("TOPLEFT", castBar, "TOPLEFT", -offsetX, offsetYTop)
    castBar.Flash:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", offsetX, offsetYBottom)

    castBar.Flash:SetVertexColor(1, 0.702, 0, 1)
end


function BBF.CastbarShakeAnimationCancel()
    if BBF.castbarShakeAnimationCancel then return end
    hooksecurefunc(PlayerCastingBarFrame.InterruptShakeAnim, "Play", function(self)
        self:Stop()
    end)
    BBF.castbarShakeAnimationCancel = true
end


function BBF.ClassicCastbar(castBar, unitType)
    local isParty = unitType == "party"
    local isPlayer = unitType == "player"
    local isTargets = unitType == "target" or unitType == "focus"

    local textOffset
    if isPlayer then
        textOffset = BetterBlizzFramesDB.classicCastbarsPlayerBorder and 0 or 0.5
    else
        textOffset = 0.5
    end

    castBar.Text:ClearAllPoints()
    castBar.Text:SetPoint("CENTER", castBar, "CENTER", 0, textOffset)


    castBar.Spark:SetBlendMode("ADD")
    castBar.Spark:SetDrawLayer("OVERLAY", 2)
    castBar.Icon:SetDrawLayer("OVERLAY", 2)

    if castBar.StandardGlow then
        castBar.StandardGlow:SetAtlas(nil)
        castBar.EnergyGlow:SetAtlas(nil)
        castBar.EnergyMask:SetAtlas(nil)
        castBar.ChargeFlash:SetAtlas(nil)
        castBar.ChannelShadow:SetAtlas(nil)
        castBar.BaseGlow:SetAtlas(nil)
        castBar.WispGlow:SetAtlas(nil)
        castBar.WispMask:SetAtlas(nil)
        castBar.Shine:SetAtlas(nil)
        castBar.CraftGlow:SetAtlas(nil)

        for i = 1,3 do
            castBar["Flakes0"..i]:SetAtlas(nil)
        end

        for i = 1,2 do
            castBar["Sparkles0"..i]:SetAtlas(nil)
        end
    end

    if isPlayer then
        BBF.CastbarShakeAnimationCancel()
    end


    -- castBar.BorderShield:SetTexture(311862)
    -- castBar.BorderShield:SetSize(196, 56)

    if not isParty then
        castBar.iconXPos = BetterBlizzFramesDB[castBar.unit.."CastbarIconXPos"]
        castBar.iconYPos = BetterBlizzFramesDB[castBar.unit.."CastbarIconYPos"]
    else
        castBar.iconXPos = BetterBlizzFramesDB["partyCastbarIconXPos"]
        castBar.iconYPos = BetterBlizzFramesDB["partyCastbarIconYPos"]
    end

    castBar.Icon:ClearAllPoints()
    --self.Icon:SetPoint("RIGHT", castBar, "LEFT", -5, -0.5)
    castBar.Icon:SetPoint("RIGHT", castBar, "LEFT", -5 + castBar.iconXPos, -0.5 + castBar.iconYPos)
    castBar.Icon:SetSize(18,18)

    AdjustBorderSize(castBar)
    AdjustBorderShieldSize(castBar)

    if not castBar.isClassicStyle then
        castBar:HookScript("OnEvent", function(self)
            self:SetStatusBarTexture(classicCastbarTexture)
            castBar.TextBorder:SetAlpha(0)
            if castBar == PlayerCastingBarFrame then
                castBar.Text:ClearAllPoints()
                castBar.Text:SetPoint("CENTER", castBar, "CENTER", 0, textOffset)
                AdjustFlash(castBar)
            else
                castBar.Flash:SetAlpha(0)
            end

            self.Background:SetTexture(classicCastbarTexture)
            self.Background:SetVertexColor(0, 0, 0, 0.6)

            self.Border:SetAlpha(1)

            --AdjustBorderSize(self)

            self.Icon:ClearAllPoints()
            --self.Icon:SetPoint("RIGHT", castBar, "LEFT", -5, -0.5)
            self.Icon:SetPoint("RIGHT", self, "LEFT", -5 + castBar.iconXPos, -0.5 + castBar.iconYPos)
            self.Icon:SetSize(18,18)

            -- if self.BorderShield:IsShown() then
            --     AdjustBorderShieldSize(self)
            --     --self.Icon:SetPoint("RIGHT", castBar, "LEFT", -3.5, castBar.adjustedIconYOffset)
            --     self.Icon:SetPoint("RIGHT", self, "LEFT", -3.5 + castBar.iconXPos, castBar.adjustedIconYOffset + castBar.iconYPos)
            --     self.Icon:SetSize(castBar.uninterruptibleIconSize, castBar.uninterruptibleIconSize)
            --     self.Border:SetAlpha(0)

            --     if self.ChargeTier1 and castBar ~= PlayerCastingBarFrame then
            --         HideChargeTiers(self)
            --     end
            -- elseif self.barType == "empowered" then
            --     if castBar ~= PlayerCastingBarFrame then
            --         HideChargeTiers(self)
            --     end
            -- end

            AdjustBorderShieldSize(self)
            self.Border:SetAlphaFromBoolean(self.BorderShield:IsShown(), 0, 1)

            -- if self.barType == "uninterruptable" then
            --     if isTargets then
            --         castBar.Text:ClearAllPoints()
            --         castBar.Text:SetPoint("CENTER", castBar, "CENTER", 0, 1)
            --     end
            --     -- self.BorderShield:Show()
            --     -- self.Border:SetAlpha(0)
            --     -- AdjustBorderShieldSize(self)
            -- end
            if recolorCastbars then
                local type = self.channeling and "channel"
                local c = castbarColors[type] or castbarColors.standard
                local r, g, b = c[1], c[2], c[3]

                self:SetStatusBarColor(r, g, b)
                --self.Spark:SetVertexColor(r, g, b)
            else
                local type = self.channeling and "channel"
                local c = defaultCastbarColors[type] or defaultCastbarColors.standard
                local r, g, b = c[1], c[2], c[3]

                self:SetStatusBarColor(r, g, b)
                --self.Spark:SetVertexColor(r, g, b)
            end
        end)

        hooksecurefunc(castBar.BorderShield, "Show", function()
            AdjustBorderShieldSize(castBar)
        end)

        hooksecurefunc(castBar, "PlayFinishAnim", function(self)
            self:SetStatusBarTexture(classicCastbarTexture)
            --self:SetStatusBarColor(0, 1, 0, 1)
            if castBar == PlayerCastingBarFrame then
                AdjustFlash(castBar)
            else
                castBar.Flash:SetAlpha(0)
            end
        end)

        if BetterBlizzFramesDB.classicCastbarsModernSpark then
            castBar:HookScript("OnUpdate", function(self)
                self.Spark:SetAtlas("UI-CastingBar-Pip")
                self.Spark:SetSize(6, 16)
                UpdateSparkPosition(castBar)
            end)
        else
            castBar:HookScript("OnUpdate", function(self)
                self.Spark:SetTexture(130877)
                self.Spark:SetSize(36,36)
                UpdateSparkPosition(castBar)
            end)
        end



        castBar.textureChangedNeedsColor = true
        castBar.isClassicStyle = true
    end
end

function BBF.UpdateCastbars()
    if not MIDNIGHTRDY then return end
    local numGroupMembers = GetNumGroupMembers()
    local compactFrame = (_G["PartyFrame"]["MemberFrame1"] and _G["PartyFrame"]["MemberFrame1"]:IsShown() and _G["PartyFrame"]["MemberFrame1"])
                         or (_G["CompactPartyFrameMember1"] and _G["CompactPartyFrameMember1"]:IsShown() and _G["CompactPartyFrameMember1"])
                         --or (_G["CompactRaidFrame1"] and _G["CompactRaidFrame1"]:IsShown() and _G["CompactRaidFrame1"])

    if BetterBlizzFramesDB.showPartyCastbar or BetterBlizzFramesDB.partyCastBarTestMode then
        for i = 1, 5 do
            local spellbar = spellBars[i]
            if spellbar then
                spellbar:SetUnit(BetterBlizzFramesDB.partyCastBarTestMode and "player" or nil)
            end
        end
        if compactFrame and compactFrame:IsShown() and numGroupMembers <= 5 then
            local defaultPartyFrame
            if compactFrame:GetName() == nil then
                defaultPartyFrame = true
                numGroupMembers = numGroupMembers - 1
            end
            for i = 1, 5 do
                local spellbar = spellBars[i]
                if spellbar then
                    if not BetterBlizzFramesDB.partyCastBarTestMode then
                        spellbar:SetUnit(nil)
                    end
                    --spellbar:SetParent(UIParent)
                    spellbar:SetIgnoreParentAlpha(true)
                    spellbar:SetScale(BetterBlizzFramesDB.partyCastBarScale)
                    spellbar:SetWidth(BetterBlizzFramesDB.partyCastBarWidth)
                    spellbar:SetHeight(BetterBlizzFramesDB.partyCastBarHeight)
                    -- spellbar.Icon:SetDrawLayer("OVERLAY")
                    -- spellbar.Text:ClearAllPoints()
                    -- spellbar.Text:SetPoint("CENTER", spellbar, "CENTER", 0, 0)

                    -- spellbar.Text:SetAlpha(BetterBlizzFramesDB.partyCastbarShowText and 1 or 0)
                    -- spellbar.Border:SetAlpha(BetterBlizzFramesDB.partyCastbarShowBorder and 1 or 0)
                    -- spellbar.BorderShield:SetAlpha(BetterBlizzFramesDB.partyCastbarShowBorder and 1 or 0)
                    -- spellbar.Flash:SetParent(BetterBlizzFramesDB.partyCastbarShowBorder and spellbar or hiddenFrame)

                    if not BetterBlizzFramesDB.showPartyCastBarIcon then
                        spellbar.Icon:SetAlpha(0)
                        spellbar.BorderShield:SetAlpha(0)
                    else
                        spellbar.Icon:ClearAllPoints()
                        spellbar.Icon:SetPoint("RIGHT", spellbar, "LEFT", -4 + BetterBlizzFramesDB.partyCastbarIconXPos, -5 + BetterBlizzFramesDB.partyCastbarIconYPos)
                        spellbar.Icon:SetScale(BetterBlizzFramesDB.partyCastBarIconScale)
                        spellbar.Icon:SetAlpha(1)
                        spellbar.BorderShield:ClearAllPoints()
                        spellbar.BorderShield:SetPoint("CENTER", spellbar.Icon, "CENTER", 0, 0)
                    end

                    if BetterBlizzFramesDB.classicCastbarsParty then
                        BBF.ClassicCastbar(spellbar, "party")
                        if BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeCastbars then
                            local vertexColor = BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeColor or 1
                            local castbarBorder = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.1) or 1
                            spellbar.Border:SetVertexColor(castbarBorder,castbarBorder,castbarBorder)
                        end
                        spellbar.Text:SetWidth(spellbar:GetWidth())
                        spellbar.Text:SetScale(0.9)
                        spellbar.TextBorder:SetAlpha(0)

                        if BetterBlizzFramesDB.partyCastBarTestMode then
                            spellbar:SetStatusBarTexture(137012)
                            if recolorCastbars then
                                spellbar:SetStatusBarColor(castbarColors.standard[1], castbarColors.standard[2], castbarColors.standard[3], 1)
                            else
                                spellbar:SetStatusBarColor(1, 0.7, 0, 1)
                            end
                            spellbar.Background:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
                            spellbar.Background:SetVertexColor(0, 0, 0, 0.6)
                        end
                    else
                        spellbar.Text:ClearAllPoints()
                        if BetterBlizzFramesDB.unitframeCastBarNoTextBorder or (BetterBlizzFramesDB.castbarPixelBorder and BetterBlizzFramesDB.castbarPixelBorderTextInside) then
                            if not spellbar.TextBorderHidden then
                                spellbar.TextBorderHidden = spellbar.TextBorder:GetParent()
                            end
                            spellbar.TextBorder:SetParent(BBF.hiddenFrame)
                            spellbar.Text:SetPoint("CENTER", spellbar, "CENTER", 0, 0)
                            if not spellbar.ogText then
                                local font, size, flags = spellbar.Text:GetFont()
                                spellbar.ogText = {font, size, flags}
                                spellbar.Text:SetFont(font, size, "OUTLINE")
                            end
                        else
                            if spellbar.TextBorderHidden then
                                spellbar.TextBorder:SetParent(spellbar.TextBorderHidden)
                                spellbar.TextBorderHidden = nil
                            end
                            if spellbar.ogText then
                                spellbar.Text:SetFont(unpack(spellbar.ogText))
                                spellbar.ogText = nil
                            end
                            spellbar.Text:SetPoint("CENTER", spellbar, "BOTTOM", 0, -5.5)
                        end
                    end

                    local partyFrame = nil

                    if _G["PartyFrame"]["MemberFrame"..i] and _G["PartyFrame"]["MemberFrame"..i]:IsShown() then
                        partyFrame = _G["PartyFrame"]["MemberFrame"..i]
                    elseif _G["CompactPartyFrameMember"..i] and _G["CompactPartyFrameMember"..i]:IsVisible() then
                        partyFrame = _G["CompactPartyFrameMember"..i]
                    -- elseif _G["CompactRaidFrame"..i] and _G["CompactRaidFrame"..i]:IsShown() then
                    --     partyFrame = _G["CompactRaidFrame"..i]
                    end

                    if partyFrame and partyFrame:IsShown() and partyFrame:IsVisible() then
                        local xPos = BetterBlizzFramesDB.partyCastBarXPos + 13
                        local yPos = BetterBlizzFramesDB.partyCastBarYPos + 3
                        if defaultPartyFrame then
                            xPos = xPos + 15
                            yPos = yPos - 20
                        end

                        local unitId = partyFrame.displayedUnit or partyFrame.unit

                        if (unitId and unitId:match("^partypet%d$")) then
                            spellbar:SetUnit(nil)
                        elseif UnitIsUnit(unitId, "player") and (not BetterBlizzFramesDB.partyCastbarSelf and not BetterBlizzFramesDB.partyCastBarTestMode) then
                            spellbar:SetUnit(nil)
                        else
                            spellbar:SetUnit(unitId, true, true)
                            spellbar:SetFrameStrata("MEDIUM")
                        end

                        spellbar:ClearAllPoints()
                        spellbar:SetPoint("CENTER", partyFrame, "CENTER", BetterBlizzFramesDB.partyCastBarXPos + 13, BetterBlizzFramesDB.partyCastBarYPos + 3)
                    else
                        spellbar:SetUnit(nil)
                    end
                else
                    BBF.CreateCastbars()
                end
            end
        else
            for i = 1, 5 do
                local spellbar = spellBars[i]
                if spellbar then
                    spellbar:SetUnit(nil)
                end
            end
        end
    else
        for i = 1, 5 do
            local spellbar = spellBars[i]
            if spellbar then
                spellbar:SetUnit(nil)
            end
        end
    end
end

function BBF.UpdatePetCastbar()
    local petSpellBar = spellBars["pet"]
    if petSpellBar then
        local xPos = BetterBlizzFramesDB.petCastBarXPos
        local yPos = BetterBlizzFramesDB.petCastBarYPos
        local castbarScale = BetterBlizzFramesDB.petCastBarScale
        local iconScale = BetterBlizzFramesDB.petCastBarIconScale
        local width = BetterBlizzFramesDB.petCastBarWidth
        local height = BetterBlizzFramesDB.petCastBarHeight

        petSpellBar:SetParent(UIParent)
        petSpellBar:SetIgnoreParentAlpha(true)
        if not BetterBlizzFramesDB.showPetCastBarIcon then
            petSpellBar.Icon:SetAlpha(0)
            petSpellBar.BorderShield:SetAlpha(0)
        else
            petSpellBar.Icon:ClearAllPoints()
            petSpellBar.Icon:SetPoint("RIGHT", petSpellBar, "LEFT", -4 + 0, -5 + 0)
            petSpellBar.Icon:SetScale(iconScale)
            petSpellBar.Icon:SetAlpha(1)
            petSpellBar.BorderShield:ClearAllPoints()
            petSpellBar.BorderShield:SetPoint("RIGHT", petSpellBar, "LEFT", -1 + 0, -7 + 0)
            petSpellBar.BorderShield:SetScale(iconScale)
            petSpellBar.BorderShield:SetAlpha(1)
        end
        petSpellBar:SetScale(castbarScale)
        petSpellBar:SetWidth(width)
        petSpellBar:SetHeight(height)
        petSpellBar.Text:ClearAllPoints()
        if BetterBlizzFramesDB.unitframeCastBarNoTextBorder or (BetterBlizzFramesDB.castbarPixelBorder and BetterBlizzFramesDB.castbarPixelBorderTextInside) then
            if not petSpellBar.TextBorderHidden then
                petSpellBar.TextBorderHidden = petSpellBar.TextBorder:GetParent()
            end
            petSpellBar.TextBorder:SetParent(BBF.hiddenFrame)
            petSpellBar.Text:SetPoint("CENTER", petSpellBar, "CENTER", 0, 0)
            if not petSpellBar.ogText then
                local font, size, flags = petSpellBar.Text:GetFont()
                petSpellBar.ogText = {font, size, flags}
                petSpellBar.Text:SetFont(font, size, "OUTLINE")
            end
        else
            if petSpellBar.TextBorderHidden then
                petSpellBar.TextBorder:SetParent(petSpellBar.TextBorderHidden)
                petSpellBar.TextBorderHidden = nil
            end
            if petSpellBar.ogText then
                petSpellBar.Text:SetFont(unpack(petSpellBar.ogText))
                petSpellBar.ogText = nil
            end
            petSpellBar.Text:SetPoint("CENTER", petSpellBar, "BOTTOM", 0, -5.5)
        end

        local petFrame = PetFrame
        if petFrame then
            local petDetachCastbar = BetterBlizzFramesDB.petDetachCastbar
            petSpellBar:ClearAllPoints()
            if petDetachCastbar then
                petSpellBar:SetPoint("CENTER", UIParent, "CENTER", xPos, yPos)
            else
                petSpellBar:SetPoint("CENTER", petFrame, "CENTER", xPos + 4, yPos - 27)
            end
            petSpellBar:SetFrameStrata("MEDIUM")
            petSpellBar:SetUnit("pet", true, true)
        else
            petSpellBar:SetUnit(nil)
        end
    else
        BBF.CreateCastbars()
    end
end


function BBF.CreateCastbars()
    if not MIDNIGHTRDY then return end
    if not castBarsCreated and (BetterBlizzFramesDB.showPartyCastbar or BetterBlizzFramesDB.partyCastBarTestMode) then
        for i = 1, 5 do
            local spellbar = CreateFrame("StatusBar", "Party"..i.."SpellBar", UIParent, "SmallCastingBarFrameTemplate")
            spellbar:SetScale(1)

            spellbar:SetUnit("party"..i, true, true)
            spellbar.Text:ClearAllPoints()
            spellbar.Text:SetPoint("CENTER", spellbar, "BOTTOM", 0, -5.5)
            spellbar.Text:SetFontObject("SystemFont_Shadow_Med1_Outline")
            spellbar.Text:SetWidth(spellbar:GetWidth()+40)
            spellbar.Icon:ClearAllPoints()
            spellbar.Icon:SetPoint("RIGHT", spellbar, "LEFT", -4, -5)
            spellbar.Icon:SetSize(22,22)
            spellbar.Icon:SetScale(BetterBlizzFramesDB.partyCastBarIconScale)
            if not BetterBlizzFramesDB.classicCastbarsParty  then
                spellbar.BorderShield:ClearAllPoints()
                spellbar.BorderShield:SetPoint("RIGHT", spellbar, "LEFT", -1, -7)
                spellbar.BorderShield:SetSize(29,33)
                spellbar.BorderShield:SetScale(BetterBlizzFramesDB.partyCastBarIconScale)
                if BetterBlizzFramesDB.unitframeCastBarNoTextBorder or (BetterBlizzFramesDB.castbarPixelBorder and BetterBlizzFramesDB.castbarPixelBorderTextInside) then
                    spellbar.Text:ClearAllPoints()
                    spellbar.Text:SetPoint("CENTER", spellbar, "CENTER", 0, 0)
                    spellbar.TextBorder:SetParent(BBF.hiddenFrame)
                    local font, size, flags = spellbar.Text:GetFont()
                    spellbar.Text:SetFont(font, size, "OUTLINE")
                end
            else
                spellbar.TextBorder:SetAlpha(0)
            end
            spellbar:SetScale(BetterBlizzFramesDB.partyCastBarScale)
            spellbar:SetWidth(BetterBlizzFramesDB.partyCastBarWidth)
            spellbar:SetHeight(BetterBlizzFramesDB.partyCastBarHeight)

            spellbar.Timer = spellbar:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med1_Outline")
            spellbar.Timer:SetPoint("LEFT", spellbar, "RIGHT", 3, 0)
            spellbar.Timer:SetTextColor(1, 1, 1, 1)

            spellbar.FakeTimer = spellbar:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med1_Outline")
            spellbar.FakeTimer:SetPoint("LEFT", spellbar, "RIGHT", 3, 0)
            spellbar.FakeTimer:SetTextColor(1, 1, 1, 1)
            spellbar.FakeTimer:SetText("1.8")
            spellbar.FakeTimer:Hide()

            Mixin(spellbar, SmoothStatusBarMixin)
            spellbar:SetMinMaxSmoothedValue(0, 100)
            -- Add hooks for updating the cast timer.
            if BetterBlizzFramesDB.partyCastBarTimer then
                spellbar:HookScript("OnUpdate", function(self, elapsed)
                    UpdateCastTimer(self, elapsed)
                end)
            end

            spellbar:Hide()

            spellBars[i] = spellbar
        end
        BBF.UpdateCastbars()
        BBF.DarkModeCastbars()
        castBarsCreated = true
    end
    if not petCastbarCreated and (BetterBlizzFramesDB.petCastbar or BetterBlizzFramesDB.petCastBarTestMode) then
        local petSpellBar = CreateFrame("StatusBar", "PetSpellBar", UIParent, "SmallCastingBarFrameTemplate")
        petSpellBar:SetScale(1)

        petSpellBar:SetUnit("pet", true, true)
        petSpellBar.Text:ClearAllPoints()
        petSpellBar.Text:SetPoint("CENTER", petSpellBar, "BOTTOM", 0, -5.5)
        petSpellBar.Text:SetFontObject("SystemFont_Shadow_Med1_Outline")
        petSpellBar.Icon:ClearAllPoints()
        petSpellBar.Icon:SetPoint("RIGHT", petSpellBar, "LEFT", -4, -5)
        petSpellBar.Icon:SetSize(22,22)
        petSpellBar.Icon:SetScale(BetterBlizzFramesDB.petCastBarIconScale)
        petSpellBar.BorderShield:ClearAllPoints()
        petSpellBar.BorderShield:SetPoint("RIGHT", petSpellBar, "LEFT", -1, -7)
        petSpellBar.BorderShield:SetSize(29,33)
        petSpellBar.BorderShield:SetScale(BetterBlizzFramesDB.petCastBarIconScale)
        petSpellBar:SetScale(BetterBlizzFramesDB.petCastBarScale)
        petSpellBar:SetWidth(BetterBlizzFramesDB.petCastBarWidth)
        petSpellBar:SetHeight(BetterBlizzFramesDB.petCastBarHeight)

        -- Handle unitframeCastBarNoTextBorder setting for pet castbar
        if BetterBlizzFramesDB.unitframeCastBarNoTextBorder or (BetterBlizzFramesDB.castbarPixelBorder and BetterBlizzFramesDB.castbarPixelBorderTextInside) then
            petSpellBar.Text:ClearAllPoints()
            petSpellBar.Text:SetPoint("CENTER", petSpellBar, "CENTER", 0, 0)
            petSpellBar.TextBorder:SetParent(BBF.hiddenFrame)
            local font, size, flags = petSpellBar.Text:GetFont()
            petSpellBar.Text:SetFont(font, size, "OUTLINE")
        end

        Mixin(petSpellBar, SmoothStatusBarMixin)
        petSpellBar:SetMinMaxSmoothedValue(0, 100)

        petSpellBar.Timer = petSpellBar:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med1_Outline")
        petSpellBar.Timer:SetPoint("LEFT", petSpellBar, "RIGHT", 3, 0)
        petSpellBar.Timer:SetTextColor(1, 1, 1, 1)

        petSpellBar.FakeTimer = petSpellBar:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med1_Outline")
        petSpellBar.FakeTimer:SetPoint("LEFT", petSpellBar, "RIGHT", 3, 0)
        petSpellBar.FakeTimer:SetTextColor(1, 1, 1, 1)
        petSpellBar.FakeTimer:SetText("1.8")
        petSpellBar.FakeTimer:Hide()

        if BetterBlizzFramesDB.petCastBarTimer then
            petSpellBar:HookScript("OnUpdate", function(self, elapsed)
                UpdateCastTimer(self, elapsed)
            end)
        end

        petSpellBar:Hide()

        spellBars["pet"] = petSpellBar
        petCastbarCreated = true
        BBF.UpdatePetCastbar()
        BBF.DarkModeCastbars()
    end
end

function BBF.partyCastBarTestMode()
    BBF.CreateCastbars()
    BBF.UpdateCastbars()

    for i = 1, 5 do
        local spellbar = spellBars[i]
        if spellbar and BetterBlizzFramesDB.partyCastBarTestMode then
            --spellbar:SetParent(UIParent)
            spellbar:SetIgnoreParentAlpha(true)
            spellbar:Show()
            spellbar:SetAlpha(1)

            local minValue, maxValue = 0, 100
            local duration = 2 -- in seconds
            local stepsPerSecond = 50 -- adjust for smoothness
            local totalSteps = duration * stepsPerSecond
            local stepValue = (maxValue - minValue) / totalSteps
            local currentValue = minValue

            spellbar:SetMinMaxValues(minValue, maxValue)
            spellbar:SetValue(currentValue)
            spellbar.Text:SetText(L["Label_Frostbolt"])

            -- Cancel any existing timer before creating a new one
            if spellbar.tickTimer then
                spellbar.tickTimer:Cancel()
            end

            -- Create a timer for smooth cast progress
            spellbar.tickTimer = C_Timer.NewTicker(1 / stepsPerSecond, function()
                currentValue = currentValue + stepValue
                if currentValue >= maxValue then
                    currentValue = minValue
                end
                spellbar:SetValue(currentValue)
            end)

            if not BetterBlizzFramesDB.showPartyCastBarIcon then
                spellbar.Icon:Hide()
            else
                spellbar.Icon:Show()
                spellbar.Icon:SetTexture(C_Spell.GetSpellTexture(116))
            end
            if BetterBlizzFramesDB.partyCastBarTimer then
                if not spellbar.FakeTimer then
                    spellbar.FakeTimer = spellbar:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med1_Outline")
                    spellbar.FakeTimer:SetPoint("LEFT", spellbar, "RIGHT", 3, 0)
                    spellbar.FakeTimer:SetTextColor(1, 1, 1, 1)
                end
                spellbar.FakeTimer:Show()
            else
                if spellbar.FakeTimer then
                    spellbar.FakeTimer:Hide()
                end
            end
            spellbar:StopFinishAnims()
        elseif spellbar then
            -- Stop the timer when exiting test mode
            if spellbar.tickTimer then
                spellbar.tickTimer:Cancel()
                spellbar.tickTimer = nil
            end
            spellbar:SetAlpha(0)
            if spellbar.FakeTimer then
                spellbar.FakeTimer:Hide()
            end
            spellbar:StopFinishAnims()
        end
    end
end


function BBF.petCastBarTestMode()
    BBF.CreateCastbars()
    BBF.UpdatePetCastbar()
    if BetterBlizzFramesDB.petCastBarTestMode then
        spellBars["pet"]:Show()
        spellBars["pet"]:SetAlpha(1)
        spellBars["pet"]:SetSmoothedValue(math.random(100))

        -- Create a timer for random ticks
        if not spellBars["pet"].tickTimer then
            spellBars["pet"].tickTimer = C_Timer.NewTicker(0.7, function()
                spellBars["pet"]:SetSmoothedValue(math.random(100))
            end)
        end
        if not BetterBlizzFramesDB.showPetCastBarIcon then
            spellBars["pet"].Icon:Hide()
        else
            spellBars["pet"].Icon:Show()
            spellBars["pet"].Icon:SetTexture(C_Spell.GetSpellTexture(6358))
        end
        spellBars["pet"].Text:SetText(L["Label_Seduction"])
        if BetterBlizzFramesDB.petCastBarTimer then
            spellBars["pet"].FakeTimer:Show()
        else
            spellBars["pet"].FakeTimer:Hide()
        end
    else
        -- Stop the timer when exiting test mode
        if spellBars and spellBars["pet"] then
            if spellBars["pet"].tickTimer then
                spellBars["pet"].tickTimer:Cancel()
                spellBars["pet"].tickTimer = nil
            end
            spellBars["pet"]:SetAlpha(0)
            spellBars["pet"].FakeTimer:Hide()
        end
    end
end




local CastBarFrame = CreateFrame("Frame")
CastBarFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
CastBarFrame:SetScript("OnEvent", function(self, event, ...)
    if BetterBlizzFramesDB.showPartyCastbar then
        BBF.UpdateCastbars()
        BBF.CreateCastbars()
    end
end)

-- Hook into the OnUpdate, OnShow, and OnHide scripts for the spell bar
local function CastBarTimer(bar)
    local castBarSetting = nil
    if bar == PlayerCastingBarFrame then
        castBarSetting = BetterBlizzFramesDB.playerCastBarTimer
    elseif bar == TargetFrameSpellBar then
        castBarSetting = BetterBlizzFramesDB.targetCastBarTimer
    elseif bar == FocusFrameSpellBar then
        castBarSetting = BetterBlizzFramesDB.focusCastBarTimer
    end
    if castBarSetting and not bar.Timer then
        bar.Timer = bar:CreateFontString(nil, "OVERLAY")
        bar.Timer:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    end
    if not bar.Timer then return end
    bar.Timer:ClearAllPoints()
    if bar == PlayerCastingBarFrame then
        if BetterBlizzFramesDB.playerCastBarTimerCentered then
            bar.Timer:SetPoint("CENTER", bar, "CENTER", 0, 0)
        else
            bar.Timer:SetPoint("LEFT", bar, "RIGHT", 3, -0)
        end
    else
        bar.Timer:SetPoint("LEFT", bar, "RIGHT", 3, -0)
    end
    if not castBarSetting then
        bar.Timer:Hide()
    else
        bar.Timer:Show()
    end
    if bar.isHooked then return end
    bar:HookScript("OnUpdate", function(self, elapsed)
        UpdateCastTimer(self, elapsed)
    end)
    bar.isHooked = true
end

function BBF.CastBarTimerCaller()
    CastBarTimer(PlayerCastingBarFrame)
    CastBarTimer(TargetFrameSpellBar)
    CastBarTimer(FocusFrameSpellBar)
end


local interruptSpells = {
    1766,  -- Kick (Rogue)
    2139,  -- Counterspell (Mage)
    6552,  -- Pummel (Warrior)
    19647, -- Spell Lock (Warlock)
    47528, -- Mind Freeze (Death Knight)
    57994, -- Wind Shear (Shaman)
    --91802, -- Shambling Rush (Death Knight)
    96231, -- Rebuke (Paladin)
    106839,-- Skull Bash (Feral)
    115781,-- Optical Blast (Warlock)
    116705,-- Spear Hand Strike (Monk)
    132409,-- Spell Lock (Warlock)
    119910,-- Spell Lock (Warlock Pet)
    89766, -- Axe Toss (Warlock Pet)
    171138,-- Shadow Lock (Warlock)
    147362,-- Countershot (Hunter)
    183752,-- Disrupt (Demon Hunter)
    187707,-- Muzzle (Hunter)
    212619,-- Call Felhunter (Warlock)
    --231665,-- Avengers Shield (Paladin)
    351338,-- Quell (Evoker)
    97547, -- Solar Beam
    78675, -- Solar Beam
    15487, -- Silence
    --47482, -- Leap (DK Transform)
}

-- Local variable to store the known interrupt spell ID
local knownInterruptSpellID = nil

-- Function to find and return the interrupt spell the player knows
local function GetInterruptSpell()
    for _, spellID in ipairs(interruptSpells) do
        if IsSpellKnownOrOverridesKnown(spellID) or (UnitExists("pet") and IsSpellKnownOrOverridesKnown(spellID, true)) then
            knownInterruptSpellID = spellID
            return spellID
        end
    end
    knownInterruptSpellID = nil
end
-- Recheck interrupt spells when lock resummons/sacrifices pet
local petSummonSpells = {
    [30146] = true,  -- Summon Demonic Tyrant (Demonology)
    [691]    = true,  -- Summon Felhunter (for Spell Lock)
    [108503] = true,  -- Grimoire of Sacrifice
}

local function OnEvent(self, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then -- BBFMIDNIGHT i think this should be freed up from secrets soonTM, currently errors.
        if not petSummonSpells[spellID] then return end
    end
    C_Timer.After(0.1, GetInterruptSpell)
end

local interruptSpellUpdate = CreateFrame("Frame")
if select(2, UnitClass("player")) == "WARLOCK" then
    --interruptSpellUpdate:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end
interruptSpellUpdate:RegisterEvent("TRAIT_CONFIG_UPDATED")
interruptSpellUpdate:RegisterEvent("PLAYER_TALENT_UPDATE")
interruptSpellUpdate:SetScript("OnEvent", OnEvent)


local function HideChargeTiers(castBar)
    if not castBar.ChargeTier1 then return end
    castBar.ChargeTier1:Hide()
    castBar.ChargeTier2:Hide()
    castBar.ChargeTier3:Hide()
    if castBar.ChargeTier4 then
        castBar.ChargeTier4:Hide()
    end
end

local function ColorOldCastbar(castBar)
    castBar:SetStatusBarColor(1, 0.7, 0, 1)
    if castBar.barType == "channel" then
        castBar:SetStatusBarColor(0, 1, 0, 1)
    elseif castBar.barType == "interrupted" then
        castBar:SetStatusBarColor(1, 0, 0, 1)
    elseif castBar.barType == "uninterruptable" then
        castBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
        HideChargeTiers(castBar)
    elseif castBar.barType == "empowered" then
        castBar:SetStatusBarColor(1, 0.7, 0, 1)
        HideChargeTiers(castBar)
    end
end


function BBF.CastbarRecolorWidgets()
    local classicFrames = C_AddOns.IsAddOnLoaded("ClassicFrames")
    if (BetterBlizzFramesDB.castBarRecolorInterrupt or BetterBlizzFramesDB.recolorCastbars) and not BBF.RecolorCastbarHooked then
        BBF.CastbarColorHooks()
        BBF.RecolorCastbarHooked = true
    end
end

function BBF.ShowPlayerCastBarIcon()
    if PlayerCastingBarFrame then
        if BetterBlizzFramesDB.playerCastBarShowIcon then
            PlayerCastingBarFrame.Icon:Show()
            --PlayerCastingBarFrame.showShield = true
        else
            PlayerCastingBarFrame.Icon:Hide()
            --PlayerCastingBarFrame.showShield = false
        end
    else
        C_Timer.After(1, BBF.ShowPlayerCastBarIcon)
    end
end


local function PlayerCastingBarFrameMiscAdjustments()
    PlayerCastingBarFrame:SetScale(BetterBlizzFramesDB.playerCastBarScale or 1)
    local w = BetterBlizzFramesDB.playerCastBarWidth
    local maskRatio = 256 / 208

    PlayerCastingBarFrame:SetHeight(BetterBlizzFramesDB.playerCastBarHeight)
    PlayerCastingBarFrame.Text:ClearAllPoints()
    if BetterBlizzFramesDB.playerCastBarNoTextBorder or PlayerCastingBarFrame.attachedToPlayerFrame or (BetterBlizzFramesDB.castbarPixelBorder and BetterBlizzFramesDB.castbarPixelBorderTextInside) then
        if not PlayerCastingBarFrame.TextBorderHidden then
            PlayerCastingBarFrame.TextBorderHidden = PlayerCastingBarFrame.TextBorder:GetParent()
        end
        PlayerCastingBarFrame.TextBorder:SetParent(BBF.hiddenFrame)
        PlayerCastingBarFrame.Text:SetPoint("CENTER", PlayerCastingBarFrame, "CENTER", 0, 0)
        if not PlayerCastingBarFrame.ogText then
            local font, size, flags = PlayerCastingBarFrame.Text:GetFont()
            PlayerCastingBarFrame.ogText = {font, size, flags}
            PlayerCastingBarFrame.Text:SetFont(font, size, "OUTLINE")
        end

        if PlayerCastingBarFrame.attachedToPlayerFrame then
            maskRatio = 256 / 150
            w = BetterBlizzFramesDB.playerCastBarWidth - 58
        end
    else
        if PlayerCastingBarFrame.TextBorderHidden then
            PlayerCastingBarFrame.TextBorder:SetParent(PlayerCastingBarFrame.TextBorderHidden)
            PlayerCastingBarFrame.TextBorderHidden = nil
        end
        if PlayerCastingBarFrame.ogText then
            PlayerCastingBarFrame.Text:SetFont(unpack(PlayerCastingBarFrame.ogText))
            PlayerCastingBarFrame.ogText = nil
        end
        PlayerCastingBarFrame.Text:SetPoint("BOTTOM", PlayerCastingBarFrame, "BOTTOM", 0, -14)
    end
    PlayerCastingBarFrame:SetWidth(w)
    PlayerCastingBarFrame.BorderMask:SetWidth(w * maskRatio)
    PlayerCastingBarFrame.Text:SetWidth(BetterBlizzFramesDB.playerCastBarWidth)
    PlayerCastingBarFrame.Icon:SetSize(22,22)
    PlayerCastingBarFrame.Icon:ClearAllPoints()
    local playerIconYOffset = BetterBlizzFramesDB.hidePlayerCastbarIcon and -6969 or ((BetterBlizzFramesDB.playerCastBarNoTextBorder and 0 or -5) + BetterBlizzFramesDB.playerCastbarIconYPos)
    PlayerCastingBarFrame.Icon:SetPoint("RIGHT", PlayerCastingBarFrame, "LEFT", -5 + BetterBlizzFramesDB.playerCastbarIconXPos, playerIconYOffset)
    PlayerCastingBarFrame.Icon:SetScale(BetterBlizzFramesDB.playerCastBarIconScale)
    PlayerCastingBarFrame.BorderShield:SetSize(30,36)
    PlayerCastingBarFrame.BorderShield:ClearAllPoints()
    local playerShieldYOffset = BetterBlizzFramesDB.hidePlayerCastbarIcon and -6969 or (-7 + BetterBlizzFramesDB.playerCastbarIconYPos)
    PlayerCastingBarFrame.BorderShield:SetPoint("RIGHT", PlayerCastingBarFrame, "LEFT", -1.5 + BetterBlizzFramesDB.playerCastbarIconXPos, playerShieldYOffset)
    PlayerCastingBarFrame.BorderShield:SetScale(BetterBlizzFramesDB.playerCastBarIconScale)
    PlayerCastingBarFrame.BorderShield:SetDrawLayer("BORDER")
    PlayerCastingBarFrame.Icon:SetDrawLayer("ARTWORK")
    -- InterruptGlow
    local baseWidthRatio = 444 / 208
    local baseHeightRatio = 50 / 11
    local newInterruptGlowWidth = baseWidthRatio * BetterBlizzFramesDB.playerCastBarWidth
    local newInterruptGlowHeight
    if BetterBlizzFramesDB.playerCastBarHeight > 14 and BetterBlizzFramesDB.playerCastBarHeight < 30 then
        newInterruptGlowHeight = baseHeightRatio * BetterBlizzFramesDB.playerCastBarHeight * 0.78
    else
        newInterruptGlowHeight = baseHeightRatio * BetterBlizzFramesDB.playerCastBarHeight
    end
    PlayerCastingBarFrame.InterruptGlow:SetSize(newInterruptGlowWidth, newInterruptGlowHeight)

    PlayerCastingBarFrame.Spark:SetSize(8, BetterBlizzFramesDB.playerCastBarHeight + 9)
    --PlayerCastingBarFrame.StandardGlow:SetSize(37, BetterBlizzFramesDB.playerCastBarHeight + 1)
end

function BBF.ChangeCastbarSizes()
    BBF.UpdateUserAuraSettings()
    local classicFrames = C_AddOns.IsAddOnLoaded("ClassicFrames")
    local xClassicAdjustment = classicFrames and -1 or 0
    local yClassicAdjustment = classicFrames and 6 or 0
    --Player
    if not BetterBlizzFramesDB.playerCastBarScale then
        BetterBlizzFramesDB.playerCastBarScale = PlayerCastingBarFrame:GetScale()
    end
    --
    PlayerCastingBarFrameMiscAdjustments()

    TargetFrameSpellBar.bbfHiddenCastbar = BetterBlizzFramesDB.hideTargetCastbar
    FocusFrameSpellBar.bbfHiddenCastbar = BetterBlizzFramesDB.hideFocusCastbar

    if BetterBlizzFramesDB.hidePlayerCastbar then
        PlayerCastingBarFrame:UnregisterAllEvents()
    end



    --Target & Focus XY in auras.lua
    --Target
    TargetFrameSpellBar:SetScale(BetterBlizzFramesDB.targetCastBarScale)
    TargetFrameSpellBar:SetWidth(BetterBlizzFramesDB.targetCastBarWidth)
    TargetFrameSpellBar:SetHeight(BetterBlizzFramesDB.targetCastBarHeight)
    TargetFrameSpellBar.Icon:SetScale(BetterBlizzFramesDB.targetCastBarIconScale)
    TargetFrameSpellBar.Icon:ClearAllPoints()
    local targetIconYOffset = BetterBlizzFramesDB.hideTargetCastbarIcon and -6969 or (-5 + BetterBlizzFramesDB.targetCastbarIconYPos + yClassicAdjustment)
    TargetFrameSpellBar.Icon:SetPoint("RIGHT", TargetFrameSpellBar, "LEFT", -2 + BetterBlizzFramesDB.targetCastbarIconXPos + xClassicAdjustment, targetIconYOffset)

    if not classicFrames then
        TargetFrameSpellBar.BorderShield:ClearAllPoints()
        TargetFrameSpellBar.BorderShield:SetPoint("CENTER", TargetFrameSpellBar.Icon, "CENTER", 0, -1.5)
        TargetFrameSpellBar.BorderShield:SetScale(BetterBlizzFramesDB.targetCastBarIconScale)
        TargetFrameSpellBar.Text:ClearAllPoints()
        if BetterBlizzFramesDB.unitframeCastBarNoTextBorder or (BetterBlizzFramesDB.castbarPixelBorder and BetterBlizzFramesDB.castbarPixelBorderTextInside) then
            if not TargetFrameSpellBar.TextBorderHidden then
                TargetFrameSpellBar.TextBorderHidden = TargetFrameSpellBar.TextBorder:GetParent()
            end
            TargetFrameSpellBar.TextBorder:SetParent(BBF.hiddenFrame)
            TargetFrameSpellBar.Text:SetPoint("CENTER", TargetFrameSpellBar, "CENTER", 0, 0)
            if not TargetFrameSpellBar.ogText then
                local font, size, flags = TargetFrameSpellBar.Text:GetFont()
                TargetFrameSpellBar.ogText = {font, size, flags}
                TargetFrameSpellBar.Text:SetFont(font, size, "OUTLINE")
            end
        else
            if TargetFrameSpellBar.TextBorderHidden then
                TargetFrameSpellBar.TextBorder:SetParent(TargetFrameSpellBar.TextBorderHidden)
                TargetFrameSpellBar.TextBorderHidden = nil
            end
            if TargetFrameSpellBar.ogText then
                TargetFrameSpellBar.Text:SetFont(unpack(TargetFrameSpellBar.ogText))
                TargetFrameSpellBar.ogText = nil
            end
            TargetFrameSpellBar.Text:SetPoint("BOTTOM", TargetFrameSpellBar, "BOTTOM", 0, -14)
        end
    end
    TargetFrameSpellBar.Text:SetWidth(BetterBlizzFramesDB.targetCastBarWidth)

    --Focus
    FocusFrameSpellBar:SetScale(BetterBlizzFramesDB.focusCastBarScale)
    FocusFrameSpellBar:SetWidth(BetterBlizzFramesDB.focusCastBarWidth)
    FocusFrameSpellBar:SetHeight(BetterBlizzFramesDB.focusCastBarHeight)
    FocusFrameSpellBar.Icon:ClearAllPoints()
    local focusIconYOffset = BetterBlizzFramesDB.hideFocusCastbarIcon and -6969 or (-5 + BetterBlizzFramesDB.focusCastbarIconYPos + yClassicAdjustment)
    FocusFrameSpellBar.Icon:SetPoint("RIGHT", FocusFrameSpellBar, "LEFT", -2 + BetterBlizzFramesDB.focusCastbarIconXPos + xClassicAdjustment, focusIconYOffset)
    FocusFrameSpellBar.Icon:SetScale(BetterBlizzFramesDB.focusCastBarIconScale)

    if not classicFrames then
        FocusFrameSpellBar.BorderShield:ClearAllPoints()
        FocusFrameSpellBar.BorderShield:SetPoint("CENTER", FocusFrameSpellBar.Icon, "CENTER", 0, -1.5)
        FocusFrameSpellBar.BorderShield:SetScale(BetterBlizzFramesDB.focusCastBarIconScale)
        FocusFrameSpellBar.Text:ClearAllPoints()
        if BetterBlizzFramesDB.unitframeCastBarNoTextBorder or (BetterBlizzFramesDB.castbarPixelBorder and BetterBlizzFramesDB.castbarPixelBorderTextInside) then
            if not FocusFrameSpellBar.TextBorderHidden then
                FocusFrameSpellBar.TextBorderHidden = FocusFrameSpellBar.TextBorder:GetParent()
            end
            FocusFrameSpellBar.TextBorder:SetParent(BBF.hiddenFrame)
            FocusFrameSpellBar.Text:SetPoint("CENTER", FocusFrameSpellBar, "CENTER", 0, 0)
            if not FocusFrameSpellBar.ogText then
                local font, size, flags = FocusFrameSpellBar.Text:GetFont()
                FocusFrameSpellBar.ogText = {font, size, flags}
                FocusFrameSpellBar.Text:SetFont(font, size, "OUTLINE")
            end
        else
            if FocusFrameSpellBar.TextBorderHidden then
                FocusFrameSpellBar.TextBorder:SetParent(FocusFrameSpellBar.TextBorderHidden)
                FocusFrameSpellBar.TextBorderHidden = nil
            end
            if FocusFrameSpellBar.ogText then
                FocusFrameSpellBar.Text:SetFont(unpack(FocusFrameSpellBar.ogText))
                FocusFrameSpellBar.ogText = nil
            end
            FocusFrameSpellBar.Text:SetPoint("BOTTOM", FocusFrameSpellBar, "BOTTOM", 0, -14)
        end
    end
    FocusFrameSpellBar.Text:SetWidth(BetterBlizzFramesDB.focusCastBarWidth)

    if BetterBlizzFramesDB.changeUnitFrameFont then
        local fontName = BetterBlizzFramesDB.unitFrameFont
        local fontPath = BBF.LSM:Fetch(BBF.LSM.MediaType.FONT, fontName)
        local outline = BetterBlizzFramesDB.unitFrameFontOutline or "THINOUTLINE"
        local _, size, _ = TargetFrameSpellBar.Text:GetFont()
        TargetFrameSpellBar.Text:SetFont(fontPath, size, outline)
        FocusFrameSpellBar.Text:SetFont(fontPath, size, outline)
        local _, size, _ = PlayerCastingBarFrame.Text:GetFont()
        PlayerCastingBarFrame.Text:SetFont(fontPath, size, outline)
    end

    if BetterBlizzFramesDB.classicCastbars then
        BBF.ClassicCastbar(TargetFrameSpellBar, "target")
        BBF.ClassicCastbar(FocusFrameSpellBar, "focus")
    end
    if BetterBlizzFramesDB.classicCastbarsPlayer then
        BBF.ClassicCastbar(PlayerCastingBarFrame, "player")
        PlayerCastingBarFrame.Border:SetTexture(BetterBlizzFramesDB.classicCastbarsPlayerBorder and 130874 or 130873)
    end
end

PlayerCastingBarFrame:HookScript("OnEvent", function()
    local showIcon = BetterBlizzFramesDB.playerCastBarShowIcon
    if showIcon then
        local playerCastBarIconScale = BetterBlizzFramesDB.playerCastBarIconScale
        PlayerCastingBarFrame.Icon:Show()
        --PlayerCastingBarFrame.showShield = true --taint concern TODO: add non-taint method
        PlayerCastingBarFrame.BorderShield:SetSize(30,36)
        PlayerCastingBarFrame.BorderShield:ClearAllPoints()
        PlayerCastingBarFrame.BorderShield:SetPoint("CENTER", PlayerCastingBarFrame.Icon, "CENTER", 0, -1.5)
        PlayerCastingBarFrame.BorderShield:SetScale(playerCastBarIconScale)
        PlayerCastingBarFrame.BorderShield:SetDrawLayer("BORDER")
    end
end)

local function PlayerCastingBarUpdateNextFrame()
    if PlayerCastingBarFrame.isUpdating then return end
    C_Timer.After(0, function()
        if EditModeSystemSettingsDialog and EditModeSystemSettingsDialog.attachedToSystem and EditModeSystemSettingsDialog.attachedToSystem:GetName() == "PlayerCastingBarFrame" then
            BetterBlizzFramesDB.playerCastBarScale = PlayerCastingBarFrame:GetScale()
        end
        PlayerCastingBarFrame.isUpdating = true
        PlayerCastingBarFrameMiscAdjustments()
        PlayerCastingBarFrame.isUpdating = false
    end)
end
hooksecurefunc(PlayerCastingBarFrame, "SetScale", PlayerCastingBarUpdateNextFrame)

local evokerCastbarsHooked
function BBF.HookCastbarsForEvoker()
    if not BBFMIDNIGHT then return end
    if (not evokerCastbarsHooked and BetterBlizzFramesDB.normalCastbarForEmpoweredCasts) then
        local castBars = {}

        if BetterBlizzPlatesDB and not BetterBlizzPlatesDB.normalCastbarForEmpoweredCasts then
            BetterBlizzPlatesDB.normalCastbarForEmpoweredCasts = true
        end

        if not BetterBlizzFramesDB.classicCastbars then
            table.insert(castBars, TargetFrameSpellBar)
            table.insert(castBars, FocusFrameSpellBar)
        end

        local function NormalEvokerCastbar(castBar)
            if castBar.empoweredFix then return end

            castBar:HookScript("OnEvent", function(self)
                if self:IsForbidden() then return end
                if self.barType == "uninterruptable" then
                    if self.ChargeTier1 then
                        if self.isSArena then
                            self.SetStatusBarTexture((sArenaMixin and (sArenaMixin.castTexture or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")) or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
                            if recolorCastbars then
                                local c = castbarColors[self.barType] or castbarColors.standard
                                local r, g, b = c[1], c[2], c[3]

                                self:SetStatusBarColor(r, g, b)
                            else
                                local c = defaultCastbarColors[self.barType] or defaultCastbarColors.standard
                                local r, g, b = c[1], c[2], c[3]

                                self:SetStatusBarColor(r, g, b)
                            end
                        else
                            self:SetStatusBarTexture("UI-CastingBar-Uninterruptable")
                        end
                        HideChargeTiers(self)
                    end
                elseif self.barType == "empowered" then
                    if self.isSArena then
                        self.SetStatusBarTexture((sArenaMixin and (sArenaMixin.castTexture or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")) or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
                        if recolorCastbars then
                            local c = castbarColors[self.barType] or castbarColors.standard
                            local r, g, b = c[1], c[2], c[3]
                            self:SetStatusBarColor(r, g, b)
                        else
                            local c = defaultCastbarColors[self.barType] or defaultCastbarColors.standard
                            local r, g, b = c[1], c[2], c[3]
                            self:SetStatusBarColor(r, g, b)
                        end
                    else
                        self:SetStatusBarTexture("ui-castingbar-filling-standard")
                    end
                    HideChargeTiers(self)
                end
            end)

            local sparkWidth = castBar.isSArena and 2 or 6
            castBar:HookScript("OnUpdate", function(self)
                if self:IsForbidden() then return end
                if self.barType == "uninterruptable" then
                    if self.ChargeTier1 then
                        self.Spark:SetAtlas("UI-CastingBar-Pip")
                        self.Spark:SetSize(sparkWidth,16)
                        UpdateSparkPosition(castBar)
                    end
                elseif self.barType == "empowered" then
                    self.Spark:SetAtlas("UI-CastingBar-Pip")
                    self.Spark:SetSize(sparkWidth,16)
                    UpdateSparkPosition(castBar)
                end
            end)

            castBar.empoweredFix = true
        end

        if sArena then
            for i = 1, 3 do
                local arenaFrame = sArena["arena" .. i]
                if arenaFrame and arenaFrame.CastBar then
                    -- Mark the cast bars as belonging to sArena
                    arenaFrame.CastBar.isSArena = true
                    table.insert(castBars, arenaFrame.CastBar)
                end
            end
        end

        for _, castBar in ipairs(castBars) do
            NormalEvokerCastbar(castBar)
        end

        evokerCastbarsHooked = true
    end
end

function BBF.HookCastbars()
    if BetterBlizzFramesDB.quickHideCastbars then
        local hideEvents = {
            ["UNIT_SPELLCAST_STOP"] = true,
            ["UNIT_SPELLCAST_CHANNEL_STOP"] = true,
            ["UNIT_SPELLCAST_INTERRUPTED"] = true,
            ["UNIT_SPELLCAST_EMPOWER_STOP"] = true,
        }
        TargetFrameSpellBar:HookScript("OnEvent", function(self, event, ...)
            if hideEvents[event] then
                self:Hide()
            end
        end)
        FocusFrameSpellBar:HookScript("OnEvent", function(self, event, ...)
            if hideEvents[event] then
                self:Hide()
            end
        end)

        for i = 1, 3 do
            local sArenaFrame = _G["sArenaEnemyFrame"..i]
            if sArenaFrame then
                local spellBar = sArenaFrame.CastBar
                spellBar:HookScript("OnEvent", function(self, event, ...)
                    if hideEvents[event] then
                        self:Hide()
                    end
                end)
            end

            local bArenaFrame = _G["bArenaEnemyFrame"..i]
            if bArenaFrame then
                local spellBar = bArenaFrame.CastBar
                spellBar:HookScript("OnEvent", function(self, event, ...)
                    if hideEvents[event] then
                        self:Hide()
                    end
                end)
            end
        end
    end

    if BetterBlizzFramesDB.petCastbar then
        local petUpdate = CreateFrame("Frame")
        petUpdate:RegisterEvent("UNIT_PET")
        petUpdate:SetScript("OnEvent", function(self, event, ...)
            BBF.UpdatePetCastbar()
        end)
    end
end

local function CastbarOnEvent(self)
    local colors = castbarColors
    if not self.textureChangedNeedsColor then
        if false then     -- custom texture
            local textureToUse = classicCastbarTexture
            if self.barType == "uninterruptable" and sArenaMixin.castUninterruptibleTexture then
                textureToUse = sArenaMixin.castUninterruptibleTexture
            end
            if textureToUse then
                self:SetStatusBarTexture(textureToUse)
            end
            if colors.enabled then
                if self.barType == "uninterruptable" then
                    self:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                elseif castBarRecolorInterrupt and not BBF.playerKickReady then
                    self:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif self.barType == "channel" then
                    self:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                elseif self.barType == "interrupted" then
                    self:SetStatusBarColor(1, 0, 0)
                else
                    self:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                end
            else
                if self.barType == "uninterruptable" then
                    self:SetStatusBarColor(0.7, 0.7, 0.7)
                elseif castBarRecolorInterrupt and not BBF.playerKickReady then
                    self:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif self.barType == "channel" then
                    self:SetStatusBarColor(0, 1, 0)
                elseif self.barType == "interrupted" then
                    self:SetStatusBarColor(1, 0, 0)
                else
                    self:SetStatusBarColor(1, 0.7, 0)
                end
            end
            self.changedBarColor = true
        elseif colors.enabled then
            local castTexture = self:GetStatusBarTexture()
            if castTexture then
                castTexture:SetDesaturated(true)
            end
            -- if self.barType == "uninterruptable" then
            --     self:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
            if castBarRecolorInterrupt and not BBF.playerKickReady then
                self:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
            elseif self.channeling then--elseif self.barType == "channel" then
                self:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
            -- elseif self.barType == "interrupted" then
            --     self:SetStatusBarDesaturated(false)
            --     self:SetStatusBarColor(1, 1, 1)
            --     --self:SetStatusBarColor(1, 0, 0)
            else
                self:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
            end
            self.changedBarColor = true
        elseif castBarRecolorInterrupt and not BBF.playerKickReady then
            local castTexture = self:GetStatusBarTexture()
            if castTexture then
                castTexture:SetDesaturated(true)
            end
            self:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
            self.changedBarColor = true
        elseif self.changedBarColor then
            local castTexture = self:GetStatusBarTexture()
            if castTexture then
                castTexture:SetDesaturated(false)
            end
            self:SetStatusBarColor(1, 1, 1)
            self.changedBarColor = nil
        end
    else
        self:SetStatusBarTexture(classicCastbarTexture)
        if colors.enabled then
            -- if self.barType == "uninterruptable" then
            --     self:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
            if castBarRecolorInterrupt and not BBF.playerKickReady then
                self:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
            elseif self.channeling then --elseif self.barType == "channel" then
                self:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
            -- elseif self.barType == "interrupted" then
            --     self:SetStatusBarColor(1, 0, 0)
            else
                self:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
            end
        else
            -- if self.barType == "uninterruptable" then
            --     self:SetStatusBarColor(0.7, 0.7, 0.7)
            if castBarRecolorInterrupt and not BBF.playerKickReady then
                self:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
            elseif self.channeling then
                self:SetStatusBarColor(0, 1, 0)
            -- elseif self.barType == "interrupted" then
            --     self:SetStatusBarColor(1, 0, 0)
            else
                self:SetStatusBarColor(1, 0.7, 0)
            end
        end
    end
end

function BBF.ColorCastbar(castBar)
    if castBar.castbarLookTweaks then return end
    CastbarOnEvent(castBar)
end

function BBF.CastbarColorHooks()
    castBarNoInterruptColor = BetterBlizzFramesDB.castBarNoInterruptColor
    castBarDelayedInterruptColor = BetterBlizzFramesDB.castBarDelayedInterruptColor
    castBarRecolorInterrupt = BetterBlizzFramesDB.castBarRecolorInterrupt
    recolorCastbars = BetterBlizzFramesDB.recolorCastbars
    if recolorCastbars then
        castbarColors = {
            enabled         = true,
            standard        = BetterBlizzFramesDB.castbarCastColor,
            interruptNotReady = castBarNoInterruptColor,
            interrupted     = { 1, 0, 0 },
            channel         = BetterBlizzFramesDB.castbarChannelColor,
            uninterruptable = BetterBlizzFramesDB.castbarUninterruptableColor,
        }
    else
        castbarColors = {
            enabled         = false,
            full            = { 0.0, 1.0, 0.0, 1 },
            standard        = { 1.0, 0.7, 0.0, 1 },
            channel         = { 0.0, 1.0, 0.0, 1 },
            uninterruptable = { 0.7, 0.7, 0.7, 1 },
            interrupted     = { 1.0, 0.0, 0.0, 1 },
            interruptNotReady = castBarNoInterruptColor,
        }
    end

    local playerCastBarTexture = PlayerCastingBarFrame:GetStatusBarTexture()
    PlayerCastingBarFrame:HookScript("OnEvent", function(self)
        if recolorCastbars or self.textureChangedNeedsColor then
            -- if self.barType == "interrupted" and not self.textureChangedNeedsColor then
            --     playerCastBarTexture:SetDesaturated(false)
            --     self:SetStatusBarColor(1, 1, 1)
            -- else
                local type = self.channeling and "channel"
                local c = castbarColors[type] or castbarColors.standard
                local r, g, b = c[1], c[2], c[3]
                playerCastBarTexture:SetDesaturated(true)
                self:SetStatusBarColor(r, g, b)
            --end
        end
    end)
    TargetFrameSpellBar:HookScript("OnEvent", CastbarOnEvent)
    FocusFrameSpellBar:HookScript("OnEvent", CastbarOnEvent)
end




