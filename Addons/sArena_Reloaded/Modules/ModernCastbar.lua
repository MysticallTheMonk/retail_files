if sArenaMixin.isMidnight then return end

local isRetail = sArenaMixin.isRetail

local CastStopEvents = {
    UNIT_SPELLCAST_STOP                = true,
    UNIT_SPELLCAST_FAILED              = true,
    UNIT_SPELLCAST_FAILED_QUIET        = true,
    UNIT_SPELLCAST_INTERRUPTED         = true,
    UNIT_SPELLCAST_CHANNEL_STOP        = true,
    UNIT_SPELLCAST_CHANNEL_INTERRUPTED = true,
}

if isRetail then
    sArenaCastingBarExtensionMixin = {}
    -- default bars
    local typeInfoTexture = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill";
    sArenaCastingBarExtensionMixin.typeInfo = {
        filling = typeInfoTexture,
        full = typeInfoTexture,
        glow = typeInfoTexture
    }

    local actionColors = {
        applyingcrafting = { 1.0, 0.7, 0.0, 1 },
        applyingtalents = { 1.0, 0.7, 0.0, 1 },
        filling = { 1.0, 0.7, 0.0, 1 },
        full = { 0.0, 1.0, 0.0, 1 },
        standard = { 1.0, 0.7, 0.0, 1 },
        empowered = { 1.0, 0.7, 0.0, 1 },
        channel = { 0.0, 1.0, 0.0, 1 },
        uninterruptable = { 0.7, 0.7, 0.7, 1 },
        interrupted = { 1.0, 0.0, 0.0, 1 }
    }


    function sArenaCastingBarExtensionMixin:GetTypeInfo(barType)
        barType = barType or "standard";

        -- Use custom colors if enabled and available, otherwise fall back to actionColors
        local colorToUse = actionColors[barType]
        local castbarColors = sArenaMixin.castbarColors

        if castbarColors and castbarColors.enabled then
            if barType == "standard" or barType == "filling" or barType == "empowered" then
                colorToUse = castbarColors.standard or colorToUse
            elseif barType == "channel" or barType == "full" then
                colorToUse = castbarColors.channel or colorToUse
            elseif barType == "uninterruptable" then
                colorToUse = castbarColors.uninterruptable or colorToUse
            end
        end

        -- Handle desaturation for modern castbars with default textures
        if sArenaMixin.keepDefaultModernTextures and castbarColors and castbarColors.enabled then
            local castTexture = self:GetStatusBarTexture()
            if castTexture then
                castTexture:SetDesaturated(true)
            end
        end

        self:SetStatusBarColor(unpack(colorToUse));

        local currentTexture = sArenaMixin.castTexture or self.typeInfo.filling
        return {
            filling = currentTexture,
            full = currentTexture,
            glow = currentTexture
        }
    end

    ----------------------------------------
    -- Helpers
    ----------------------------------------
    local function CopyAnchors(from, to)
        to:ClearAllPoints()
        for i = 1, from:GetNumPoints() do
            local pt, rel, relPt, x, y = from:GetPoint(i)
            to:SetPoint(pt, rel, relPt, x, y)
        end
    end

    local function DisableCastBar(bar)
        if not bar then return end
        bar:SetUnit(nil)
        bar:Hide()
    end

    local function EnableCastBar(bar, unit, style, simpleCastbar)
        if not bar then return end

        bar:SetUnit(unit, true, false)
        bar.empoweredFix = true
        if bar.UpdateInterruptibleState then bar:UpdateInterruptibleState() end
        if bar.UpdateDisplayedVisuals then bar:UpdateDisplayedVisuals() end
        if bar.UpdateDisplayType then bar:UpdateDisplayType() end

        if style == "modern" then
            -- Handle simple castbar styling
            if simpleCastbar then
                bar.Text:ClearAllPoints()
                bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
                if bar.TextBorder then
                    bar.TextBorder:Hide()
                end
            else
                bar.Text:ClearAllPoints()
                bar.Text:SetPoint("BOTTOM", bar, 0, -14)
                if bar.TextBorder then
                    bar.TextBorder:Show()
                end
            end
            bar:SetHeight(9)
        else
            bar.Text:ClearAllPoints()
            bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
            bar:SetHeight(16)
        end

        bar:Show()
    end

    ----------------------------------------
    -- Creation
    ----------------------------------------

    local function EnsureClassicBar(frame)
        if frame.classicCastBar and frame.classicCastBar ~= frame.CastBar then
            return frame.classicCastBar
        end
        frame.classicCastBar = frame.CastBar
        return frame.classicCastBar
    end

    local function EnsureModernBar(frame, unit, templateName)
        if frame.modernCastBar and frame.modernCastBar:IsObjectType("StatusBar") then
            return frame.modernCastBar
        end

        local old = EnsureClassicBar(frame)
        local parent = old:GetParent() or frame
        local template = templateName or "SmallCastingBarFrameTemplate"

        local newBar = CreateFrame("StatusBar", nil, parent, template)
        newBar:SetMovable(true)

        if newBar.OnLoad then
            newBar:OnLoad(nil, true, false)
        end

        if not newBar.customTextureFix then
            newBar.isClassicStyle = true
            newBar.customTextureFix = true
        end

        if not newBar.MaskTexture then
            newBar.MaskTexture = newBar:CreateMaskTexture()
        end
        newBar:SetStatusBarTexture(sArenaMixin.castTexture or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
        local castTexture = newBar:GetStatusBarTexture()
        newBar.MaskTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\RetailCastMask.tga",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        newBar.MaskTexture:SetPoint("TOPLEFT", newBar, "TOPLEFT", -1, 0)
        newBar.MaskTexture:SetPoint("BOTTOMRIGHT", newBar, "BOTTOMRIGHT", 1, 0)
        newBar.MaskTexture:Show()
        castTexture:AddMaskTexture(newBar.MaskTexture)

        newBar:HookScript("OnEvent", function(castBar, event, eventUnit)
            if CastStopEvents[event] and eventUnit == unit then
                if castBar.interruptedBy then
                    castBar:Show()
                else
                    local cast = UnitCastingInfo(unit) or UnitChannelInfo(unit)
                    if not cast then
                        castBar:Hide()
                        return
                    end
                end
            end
            sArenaMixin:CastbarOnEvent(newBar)
        end)

        hooksecurefunc(newBar, "PlayFinishAnim", function(self)
            if sArenaMixin.keepDefaultModernTextures then return end
            self:SetStatusBarTexture(sArenaMixin.castTexture)
        end)

        newBar.__modernHooked = true

        if sArenaMixin:DarkMode() then
            local darkModeColor = sArenaMixin:DarkModeColor()
            newBar.TextBorder:SetDesaturated(true)
            newBar.TextBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
            newBar.Border:SetDesaturated(true)
            newBar.Border:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
        end

        -- Copy placement & sizing
        newBar:SetSize(old:GetWidth(), old:GetHeight())
        CopyAnchors(old, newBar)
        newBar:SetFrameStrata(old:GetFrameStrata())
        newBar:SetFrameLevel(old:GetFrameLevel())
        newBar:Hide()
        newBar.Spark:SetSize(3, 16)
        newBar.Border:SetPoint("TOPLEFT", newBar, "TOPLEFT", -1.4, 1.6)
        newBar.Border:SetPoint("BOTTOMRIGHT", newBar, "BOTTOMRIGHT", 1.4, -1.6)

        frame.modernCastBar = newBar
        return newBar
    end

    ----------------------------------------
    -- Style switching (single frame)
    ----------------------------------------

    function sArenaMixin:ApplyCastbarStyle(frame, unit, modern, simpleCastbar)
        if InCombatLockdown and InCombatLockdown() then
            -- mark for later
            frame.__pendingCastbarStyle = modern and "modern" or "classic"
            frame.__pendingSimpleCastbar = simpleCastbar
            return
        end

        local classic = EnsureClassicBar(frame)
        local modernBar = EnsureModernBar(frame, unit)

        if modern then
            -- turn off classic, turn on modern
            DisableCastBar(classic)
            EnableCastBar(modernBar, unit or classic.unit, "modern", simpleCastbar)
            frame.CastBar = modernBar
        else
            -- turn off modern, turn on classic
            DisableCastBar(modernBar)
            EnableCastBar(classic, unit or modernBar.unit or classic.unit, "classic", simpleCastbar)
            frame.CastBar = classic
        end

        frame.__pendingCastbarStyle = nil
        frame.__pendingSimpleCastbar = nil
    end
else
    -- Mists of Pandaria

    local MOD_NONINT_TEX  = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable"
    local MOD_CHANNEL_TEX = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel"
    local MOD_CAST_TEX    = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard"
    local MOD_BG_TEX      = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Background.tga"
    local MOD_FRAME_TEX   = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Frame.tga"
    local MOD_TEXTBOX_TEX = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-TextBox.tga"
    local MOD_SHIELD_TEX  = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Shield.tga"

    local function EnsureModernPieces(bar)
        if bar.TextBorder and bar.Background and bar.Border then return end
        bar.TextBorder = bar.TextBorder or bar:CreateTexture(nil, "BACKGROUND", nil, 2)
        bar.Background = bar.Background or bar:CreateTexture(nil, "BACKGROUND", nil, 2)
        bar.Border     = bar.Border or bar:CreateTexture(nil, "OVERLAY", nil, 7)
    end

    local function ApplyModern(bar, simpleCastbar, frame, unit)
        EnsureModernPieces(bar)

        bar.TextBorder:SetTexture(MOD_TEXTBOX_TEX)
        bar.Background:SetTexture(MOD_BG_TEX)
        bar.Border:SetTexture(MOD_FRAME_TEX)
        bar.BorderShield:SetTexture(MOD_SHIELD_TEX)
        bar.BorderShield:SetDrawLayer("BACKGROUND", 0)

        local function _snapColor(c)
            if c and c.GetRGBA then
                local r, g, b, a = c:GetRGBA()
                return { r = r, g = g, b = b, a = a }
            end
        end

        if not bar.__origColorsSaved then
            bar.__origColors = {
                failed   = _snapColor(bar.failedCastColor),
                finished = _snapColor(bar.finishedCastColor),
                nonint   = _snapColor(bar.nonInterruptibleColor),
                start    = _snapColor(bar.startCastColor),
                channel  = _snapColor(bar.startChannelColor),
            }
            bar.__origColorsSaved = true
        end

        -- Let the event system handle coloring instead of hardcoding colors
        -- Use default cast color for finished casts (not a separate color)
        local castbarColors = sArenaMixin.castbarColors
        if castbarColors and castbarColors.enabled then
            -- Use custom colors from config
            local standardColor = castbarColors.standard or { 1.0, 0.7, 0.0, 1 }
            local channelColor = castbarColors.channel or { 0.0, 1.0, 0.0, 1 }
            local unintColor = castbarColors.uninterruptable or { 0.7, 0.7, 0.7, 1 }
            local interruptedColor = { 1.0, 0.0, 0.0, 1 }

            bar.failedCastColor       = CreateColor(interruptedColor[1], interruptedColor[2], interruptedColor[3], interruptedColor[4])
            bar.finishedCastColor     = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
            bar.nonInterruptibleColor = CreateColor(unintColor[1], unintColor[2], unintColor[3], unintColor[4])
            bar.startCastColor        = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
            bar.startChannelColor     = CreateColor(channelColor[1], channelColor[2], channelColor[3], channelColor[4])
        else
            -- Use default colors
            bar.failedCastColor       = CreateColor(1.0, 0.0, 0.0, 1)
            bar.finishedCastColor     = CreateColor(1.0, 0.7, 0.0, 1)
            bar.nonInterruptibleColor = CreateColor(0.7, 0.7, 0.7, 1)
            bar.startCastColor        = CreateColor(1.0, 0.7, 0.0, 1)
            bar.startChannelColor     = CreateColor(0.0, 1.0, 0.0, 1)
        end

        bar.Background:SetAllPoints(bar)
        bar.Background:Show()
        bar.Border:ClearAllPoints()
        bar.Border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1.5)
        bar.Border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1.5)
        bar.Border:Show()

        -- Handle simple castbar styling
        if simpleCastbar then
            bar.TextBorder:Hide()
            bar.Text:ClearAllPoints()
            bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        else
            bar.TextBorder:ClearAllPoints()
            bar.TextBorder:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, 1)
            bar.TextBorder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -1, -13.5)
            bar.TextBorder:Show()
            bar.Text:ClearAllPoints()
            bar.Text:SetPoint("BOTTOM", bar, 0, -10.5)
        end

        local ogBg = select(1, bar:GetRegions())
        if ogBg then
            ogBg:Hide()
        end

        if not bar.MaskTexture then
            bar.MaskTexture = bar:CreateMaskTexture()
        end
        local castTexture = bar:GetStatusBarTexture()
        bar.MaskTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\RetailCastMask.tga",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        bar.MaskTexture:SetAllPoints(bar)
        bar.MaskTexture:Show()
        castTexture:AddMaskTexture(bar.MaskTexture)

        bar:SetHeight(12)
        if bar.Icon then
            bar.Icon:SetSize(21, 21)
            bar.Icon:SetDrawLayer("OVERLAY", 7)
        end

        if not bar.__modernHooked then
            bar:HookScript("OnEvent", function(castBar, event, eventUnit)
                if CastStopEvents[event] and eventUnit == unit then
                    if castBar.interruptedBy then
                        castBar:Show()
                    else
                        local cast = UnitCastingInfo(unit) or UnitChannelInfo(unit)
                        if not cast then
                            castBar:Hide()
                            -- no return cuz sometimes castbar still fades idk and we need the color
                        end
                    end
                end
                sArenaMixin:CastbarOnEvent(bar)
            end)
            bar.__modernHooked = true
        end

        bar.__modernActive = true
        bar:Show()
    end

    local function RestoreClassic(bar)
        bar.Text:ClearAllPoints()
        bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        bar:SetHeight(16)
        if bar.Icon then bar.Icon:SetSize(16, 16) end

        if bar.TextBorder then bar.TextBorder:Hide() end
        if bar.Background then bar.Background:Hide() end
        if bar.Border then bar.Border:Hide() end

        -- Apply custom colors to classic castbars as well
        local castbarColors = sArenaMixin.castbarColors
        if castbarColors and castbarColors.enabled then
            -- Use custom colors from config
            local standardColor = castbarColors.standard or { 1.0, 0.7, 0.0, 1 }
            local channelColor = castbarColors.channel or { 0.0, 1.0, 0.0, 1 }
            local unintColor = castbarColors.uninterruptable or { 0.7, 0.7, 0.7, 1 }
            local interruptedColor = { 1.0, 0.0, 0.0, 1 }

            bar.failedCastColor       = CreateColor(interruptedColor[1], interruptedColor[2], interruptedColor[3], interruptedColor[4])
            bar.finishedCastColor     = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
            bar.nonInterruptibleColor = CreateColor(unintColor[1], unintColor[2], unintColor[3], unintColor[4])
            bar.startCastColor        = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
            bar.startChannelColor     = CreateColor(channelColor[1], channelColor[2], channelColor[3], channelColor[4])
        else
            -- Restore original colors
            local o = bar.__origColors
            if o then
                if o.failed then bar.failedCastColor = CreateColor(o.failed.r, o.failed.g, o.failed.b, o.failed.a) end
                if o.finished then bar.finishedCastColor = CreateColor(o.finished.r, o.finished.g, o.finished.b, o.finished
                    .a) end
                if o.nonint then bar.nonInterruptibleColor = CreateColor(o.nonint.r, o.nonint.g, o.nonint.b, o.nonint.a) end
                if o.start then bar.startCastColor = CreateColor(o.start.r, o.start.g, o.start.b, o.start.a) end
                if o.channel then bar.startChannelColor = CreateColor(o.channel.r, o.channel.g, o.channel.b, o.channel.a) end
            end
        end

        local ogBg = select(1, bar:GetRegions())
        if ogBg then
            ogBg:Show()
        end

        if bar.MaskTexture then
            bar.MaskTexture:Hide()
        end

        if bar.BorderShield then
            bar.BorderShield:SetTexture(330124)
        end

        bar.__modernActive = false
        bar:Show()
    end

    local function EnableCastBarClassicMode(bar, modern, simpleCastbar, frame, unit)
        if not bar then return end
        if modern then
            ApplyModern(bar, simpleCastbar, frame, unit)
        else
            RestoreClassic(bar)
        end
    end

    -- Helper function to update castbar colors for both modern and classic bars
    local function UpdateCastbarColorsMoP(bar)
        if not bar then return end
        
        local castbarColors = sArenaMixin.castbarColors
        if castbarColors and castbarColors.enabled then
            -- Use custom colors from config
            local standardColor = castbarColors.standard or { 1.0, 0.7, 0.0, 1 }
            local channelColor = castbarColors.channel or { 0.0, 1.0, 0.0, 1 }
            local unintColor = castbarColors.uninterruptable or { 0.7, 0.7, 0.7, 1 }
            local interruptedColor = { 1.0, 0.0, 0.0, 1 }

            bar.failedCastColor       = CreateColor(interruptedColor[1], interruptedColor[2], interruptedColor[3], interruptedColor[4])
            bar.finishedCastColor     = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
            bar.nonInterruptibleColor = CreateColor(unintColor[1], unintColor[2], unintColor[3], unintColor[4])
            bar.startCastColor        = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
            bar.startChannelColor     = CreateColor(channelColor[1], channelColor[2], channelColor[3], channelColor[4])
        else
            -- Restore original colors if available
            local o = bar.__origColors
            if o then
                if o.failed then bar.failedCastColor = CreateColor(o.failed.r, o.failed.g, o.failed.b, o.failed.a) end
                if o.finished then bar.finishedCastColor = CreateColor(o.finished.r, o.finished.g, o.finished.b, o.finished.a) end
                if o.nonint then bar.nonInterruptibleColor = CreateColor(o.nonint.r, o.nonint.g, o.nonint.b, o.nonint.a) end
                if o.start then bar.startCastColor = CreateColor(o.start.r, o.start.g, o.start.b, o.start.a) end
                if o.channel then bar.startChannelColor = CreateColor(o.channel.r, o.channel.g, o.channel.b, o.channel.a) end
            end
        end
    end

    -- Export function to update all arena castbar colors
    function sArenaMixin:UpdateMoPCastbarColors()
        for i = 1, self.maxArenaOpponents do
            local frame = self["arena" .. i]
            if frame and frame.CastBar then
                UpdateCastbarColorsMoP(frame.CastBar)
            end
        end
    end

    function sArenaMixin:ApplyCastbarStyle(frame, unit, modern, simpleCastbar)
        if InCombatLockdown and InCombatLockdown() then
            frame.__pendingCastbarStyle = modern and "modern" or "classic"
            frame.__pendingSimpleCastbar = simpleCastbar
            return
        end
        EnableCastBarClassicMode(frame.CastBar, modern, simpleCastbar, frame, unit)
        frame.__pendingCastbarStyle = nil
        frame.__pendingSimpleCastbar = nil
    end
end
