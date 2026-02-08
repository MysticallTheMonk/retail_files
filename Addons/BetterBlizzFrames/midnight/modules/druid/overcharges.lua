if not BBF.isMidnight then return end

function BBF.DruidAlwaysShowCombos()
    if not BetterBlizzFramesDB.druidAlwaysShowCombos then return end
    if select(2, UnitClass("player")) ~= "DRUID" then return end
    if BBF.DruidAlwaysShowCombosActive then return end
    local frame = DruidComboPointBarFrame

    local function TagCombos(comboPointFrame)
        if not comboPointFrame then return end
        if comboPointFrame.taggedCombos then return end

        local comboPoints = {}
        local visibleComboPoints = 0

        -- Loop through the combo point children and gather visible ones
        for i = 1, comboPointFrame:GetNumChildren() do
            local child = select(i, comboPointFrame:GetChildren())

            -- Only consider shown combo points
            if child:IsShown() then
                visibleComboPoints = visibleComboPoints + 1
                table.insert(comboPoints, child)
            end
        end

        -- Sort the combo points by their layoutIndex
        table.sort(comboPoints, function(a, b)
            return (a.layoutIndex or 0) < (b.layoutIndex or 0)
        end)

        -- Apply textures to the first three combo points
        for i = 1, 5 do
            if comboPoints[i] then
                local comboPoint = comboPoints[i]
                comboPointFrame["ComboPoint" .. i] = comboPoint
            end
        end

        -- Mark as overcharge points if all points are visible
        if visibleComboPoints == 5 then
            comboPointFrame.taggedCombos = true
        end
    end

    TagCombos(frame)

    local function UpdateDruidComboPoints(self)
        if not self then return end
        TagCombos(frame)
        if not self.ComboPoint1 then return end
        local form = GetShapeshiftFormID()
        if form == 1 then return end

        local comboPoints = UnitPower("player", self.powerType)

        if comboPoints > 0 then
            self:Show()
        else
            self:Hide()
        end

        for i, point in ipairs(self.classResourceButtonTable) do
            local isFull = i <= comboPoints

            point.Point_Icon:SetAlpha(isFull and 1 or 0)
            point.BG_Active:SetAlpha(isFull and 1 or 0)
            point.BG_Inactive:SetAlpha(isFull and 0 or 1)
            point.Point_Deplete:SetAlpha(0)
        end
    end

    frame:HookScript("OnHide", function(self)
        TagCombos(frame)
        if not self.ComboPoint1 then return end
        local comboPoints = UnitPower("player", DruidComboPointBarFrame.powerType)
        if comboPoints > 0 then
            self:Show()
        end
    end)

    local listener = CreateFrame("Frame")
    listener:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    listener:SetScript("OnEvent", function(_, _, _, powerType)
        if powerType == "COMBO_POINTS" then
            UpdateDruidComboPoints(frame)
        end
    end)
    BBF.DruidAlwaysShowCombosActive = true
end

local moveComboInForm = {
    [1] = true,
    [5] = true,
    -- [31] = true,
    -- [32] = true,
    -- [33] = true,
    -- [34] = true,
    -- [35] = true,
}

local function UpdateAltManaBar(updateCombos, cf)
    local bar = PlayerFrame.AltManaBarBBF
    if not bar then return end

    local form = GetShapeshiftFormID()
    local inNoManaForm = moveComboInForm[form]
    if inNoManaForm then
        local percent = 100--math.floor((mana / maxMana) * 100 + 0.5)

        bar:SetMinMaxValues(0, UnitPowerMax("player", Enum.PowerType.Mana))
        bar:SetValue(UnitPower("player", Enum.PowerType.Mana))

        local display = GetCVar("statusTextDisplay")

        if display == "NONE" then
            bar.TextString:SetText("")
        elseif display == "NUMERIC" then
            bar.TextString:SetText(AbbreviateNumbers(UnitPower("player", Enum.PowerType.Mana)))
        elseif display == "PERCENT" then
            bar.TextString:SetText(percent .. "%")
        elseif display == "BOTH" and bar.LeftText and bar.RightText then
            bar.TextString:SetText("")
            bar.LeftText:SetText(percent .. "%")
            bar.RightText:SetText(AbbreviateNumbers(UnitPower("player", Enum.PowerType.Mana)))
        end

        bar:Show()
        if not cf then
            PlayerFrame.PlayerFrameContainer.FrameTexture:Hide()
            PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:Show()
        end
        if BetterBlizzFramesDB.noPortraitModes then
            PlayerFrame.noPortraitMode.Texture:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large-Alt.tga")
        end
        if updateCombos then
            if not bar.originalComboPos then
                bar.originalComboPos = {}
                local pts = bar.originalComboPos
                pts.a, pts.b, pts.c, pts.d, pts.e = PlayerFrameBottomManagedFramesContainer:GetPoint()
            end
            local pts = bar.originalComboPos
            --PlayerFrameBottomManagedFramesContainer:ClearAllPoints()
            PlayerFrameBottomManagedFramesContainer:SetPoint(pts.a, pts.b, pts.c, pts.d, pts.e-9)
        end
    elseif bar:IsShown() then
        C_Timer.After(0.2, function()
            if updateCombos then
                local pts = bar.originalComboPos
                if pts then
                    --PlayerFrameBottomManagedFramesContainer:ClearAllPoints()
                    PlayerFrameBottomManagedFramesContainer:SetPoint(pts.a, pts.b, pts.c, pts.d, pts.e)
                end
            end
            if not cf and not AlternatePowerBar:IsShown() then
                PlayerFrame.PlayerFrameContainer.FrameTexture:Show()
                PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:Hide()
            end
            if BetterBlizzFramesDB.noPortraitModes then
                if PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:IsShown() then
                    PlayerFrame.noPortraitMode.Texture:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large-Alt.tga")
                else
                    PlayerFrame.noPortraitMode.Texture:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga")
                end
            end
            bar:Hide()
        end)
    end
end



function BBF.CreateAltManaBar()
    if PlayerFrame.AltManaBarBBF then return end -- already created
    if not BetterBlizzFramesDB.createAltManaBarDruid then return end
    if (BetterBlizzFramesDB.noPortraitPixelBorder or BetterBlizzFramesDB.noPortraitModes) and (BetterBlizzFramesDB.hideUnitFramePlayerMana or BetterBlizzFramesDB.hideUnitFramePlayerSecondResource) then return end
    local db = BetterBlizzFramesDB
    if db.useMiniPlayerFrame then return end
    local cf = db.classicFrames
    local noPortrait = db.noPortraitModes

    local specID = GetSpecialization() and GetSpecializationInfo(GetSpecialization())
    if specID ~= 105 then
        -- Set up a listener that creates the bar when spec becomes 105 (Restoration)
        if not BBF.AltManaSpecWatcher then
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            f:SetScript("OnEvent", function()
                local specID = GetSpecialization() and GetSpecializationInfo(GetSpecialization())
                if specID == 105 then
                    BBF.CreateAltManaBar()
                    f:UnregisterAllEvents()
                    f:SetScript("OnEvent", nil)
                    BBF.AltManaSpecWatcher = nil
                end
            end)
            BBF.AltManaSpecWatcher = f
        end
        return
    end

    local bar = CreateFrame("StatusBar", "AltManaBarBBF", PlayerFrame)
    if cf then
        bar:SetSize(104, 12)
        bar:SetPoint("BOTTOMLEFT", PlayerFrame, "BOTTOMLEFT", 95, 17)
    elseif db.noPortrait then
        bar:SetSize(124, 10)
        bar:SetPoint("BOTTOMLEFT", PlayerFrame, "BOTTOMLEFT", 85, 17.5)
    else
        bar:SetSize(124, 10)
        bar:SetPoint("BOTTOMLEFT", PlayerFrame, "BOTTOMLEFT", 85, 18.5)
    end
    if db.changeUnitFrameManabarTexture then
        bar:SetStatusBarTexture(BBF.manaTexture)
        bar:SetStatusBarColor(0, 0, 1)
    else
        bar:SetStatusBarTexture("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana")
        bar:SetStatusBarColor(1, 1, 1)
    end
    bar:SetMinMaxValues(0, 100)
    bar:Hide()

    bar.overlay = CreateFrame("Frame", nil, bar)
    bar.overlay:SetFrameStrata("DIALOG")

    if cf then
        bar.Background = bar:CreateTexture(nil, "BACKGROUND")
        bar.Background:SetAllPoints()
        bar.Background:SetColorTexture(0, 0, 0, 0.5)

        bar.Border = bar:CreateTexture(nil, "OVERLAY")
        bar.Border:SetSize(0, 16)
        bar.Border:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
        bar.Border:SetTexCoord(0.125, 0.250, 1, 0)
        bar.Border:SetPoint("TOPLEFT", 4, 0)
        bar.Border:SetPoint("TOPRIGHT", -4, 0)

        bar.LeftBorder = bar:CreateTexture(nil, "OVERLAY")
        bar.LeftBorder:SetSize(16, 16)
        bar.LeftBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
        bar.LeftBorder:SetTexCoord(0, 0.125, 1, 0)
        bar.LeftBorder:SetPoint("RIGHT", bar.Border, "LEFT")

        bar.RightBorder = bar:CreateTexture(nil, "OVERLAY")
        bar.RightBorder:SetSize(16, 16)
        bar.RightBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
        bar.RightBorder:SetTexCoord(0.125, 0, 1, 0)
        bar.RightBorder:SetPoint("LEFT", bar.Border, "RIGHT")
    elseif noPortrait then
        bar.Background = bar:CreateTexture(nil, "BACKGROUND")
        bar.Background:SetAllPoints()
        bar.Background:SetColorTexture(0, 0, 0, 0.5)
    end

    local display = GetCVar("statusTextDisplay")

    -- Center text like ManaBarText
    local xtraOffset = noPortrait and 0 or cf and -1 or -0.5
    local extraXOffset = noPortrait and 0.5 or 0
    bar.TextString = bar.overlay:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
    local f,s,o = AlternatePowerBar.TextString:GetFont()
    bar.TextString:SetFont(f,s,o)
    bar.TextString:ClearAllPoints()
    bar.TextString:SetPoint("CENTER",bar,"CENTER",2+extraXOffset,xtraOffset)

    C_Timer.After(0.5, function()
        local f,s,o = AlternatePowerBar.TextString:GetFont()
        bar.TextString:SetFont(f,s,o)
    end)

    -- Left and Right (only created if BOTH is set)
    if display == "BOTH" then
        bar.LeftText = bar.overlay:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        local f,s,o = AlternatePowerBar.LeftText:GetFont()
        bar.LeftText:SetFont(f,s,o)
        bar.LeftText:SetPoint("LEFT",bar,"LEFT",noPortrait and 2 or 0,xtraOffset)

        bar.RightText = bar.overlay:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        local f,s,o = AlternatePowerBar.RightText:GetFont()
        bar.RightText:SetFont(f,s,o)
        bar.RightText:SetPoint("RIGHT",bar,"RIGHT",0,xtraOffset)

        C_Timer.After(0.5, function()
            local f, s, o = AlternatePowerBar.LeftText:GetFont()
            bar.LeftText:SetFont(f, s, o)
            local f, s, o = AlternatePowerBar.RightText:GetFont()
            bar.RightText:SetFont(f, s, o)
        end)
    end

    local updateCombos = not (
        (db.moveResource and db.moveResourceStackPos and db.moveResourceStackPos["DRUID"]) or
        (db.moveResourceToTarget and db.moveResourceToTargetDruid)
    )
    local f = CreateFrame("Frame")
    f:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    f:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, evt, unit, ptype)
        if evt == "UNIT_POWER_UPDATE" and ptype ~= "MANA" then return end
        UpdateAltManaBar(updateCombos, cf)
    end)

    if display == "NONE" then
        bar:EnableMouse(true)
        bar:SetScript("OnEnter", function(self)
            local mana = UnitPower("player", Enum.PowerType.Mana)
            local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)
            self.TextString:SetText(BreakUpLargeNumbers(mana) .. " / " .. BreakUpLargeNumbers(maxMana))
        end)

        bar:SetScript("OnLeave", function(self)
            self.TextString:SetText("")
        end)
    end
    PlayerFrame.AltManaBarBBF = bar
    UpdateAltManaBar(updateCombos, cf)
end