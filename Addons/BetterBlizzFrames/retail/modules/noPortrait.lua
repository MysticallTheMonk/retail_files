--if not BBF.isMidnight then return end
local function SetXYPoint(frame, xOffset, yOffset)
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    frame:SetPoint(point, relativeTo, relativePoint, xOffset or xOfs, yOffset or yOfs)
end

local class = select(2, UnitClass("player"))

local playerDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local playerAltTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large-Alt.tga"
local targetDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local focusDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local partyDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local petDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"

local playerFlashTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local targetFlashTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local focusFlashTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local petFlashTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"

local playerFlashNoLvl = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local targetFlashNoLvl = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local focusFlashNoLvl = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
local petFlashNoLvl = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"

local minusTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga"


local function UpdateTextureVariables()
    local db = BetterBlizzFramesDB

    if db.noPortraitPixelBorder then
        playerDefaultTex = nil
        playerAltTex = nil
        targetDefaultTex = nil
        focusDefaultTex = nil
        partyDefaultTex = nil
        petDefaultTex = nil
        playerFlashTex = nil
        targetFlashTex = nil
        focusFlashTex = nil
        petFlashTex = nil
        playerFlashNoLvl = nil
        targetFlashNoLvl = nil
        focusFlashNoLvl = nil
        petFlashNoLvl = nil
        minusTex = nil
        return
    end
    if db.hideUnitFramePlayerMana and db.hideUnitFramePlayerSecondResource then
        playerAltTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga"
        playerDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga"
    elseif db.hideUnitFramePlayerSecondResource then
        playerAltTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
        playerDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
    elseif db.hideUnitFramePlayerMana then
        local altBarShown = PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:IsShown()
        if altBarShown then
            playerAltTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
            playerDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
        else
            playerAltTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga"
            playerDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga"
        end
    else
        playerAltTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large-Alt.tga"
        playerDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
    end

    if db.hideUnitFrameTargetMana then
        targetDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga"
    else
        targetDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
    end

    if db.hideUnitFrameFocusMana then
        focusDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga"
    else
        focusDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
    end

    if db.hideUnitFramePlayerMana then
        petDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga"
    else
        petDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
    end

    if db.hideDefaultPartyFramesMana then
        partyDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga"
    else
        partyDefaultTex = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga"
    end

    -- Set flash textures to match the corresponding default textures
    playerFlashTex = playerDefaultTex
    playerFlashNoLvl = playerDefaultTex
    targetFlashTex = targetDefaultTex
    targetFlashNoLvl = targetDefaultTex
    focusFlashTex = focusDefaultTex
    focusFlashNoLvl = focusDefaultTex
    petFlashTex = petDefaultTex
    petFlashNoLvl = petDefaultTex
end

local function GetPlayerBackgroundYOffset()
    local db = BetterBlizzFramesDB
    if not db then return -11 end

    if db.hideUnitFramePlayerMana and db.hideUnitFramePlayerSecondResource then
        return 0  -- Both hidden
    elseif db.hideUnitFramePlayerSecondResource then
        return -11  -- Only 2nd resource hidden
    elseif db.hideUnitFramePlayerMana then
        -- Only mana hidden: check if alt bar is shown, use 0 (minus texture offset) if not
        local altBarShown = PlayerFrame and PlayerFrame.PlayerFrameContainer and PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture and PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:IsShown()
        return altBarShown and -11 or 0
    else
        -- Both shown - but only use -21 if alt bar is actually visible
        local altBarShown = PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:IsShown()
        return altBarShown and -21 or -11
    end
end

local function BlackBorder(bar, width, height, startX, startY, tot)
    if not bar then return end

    width = width or 0
    height = height or 0
    startX = startX or 0
    startY = startY or 0

    if not bar.BBFPositionFrame then
        local posFrame = CreateFrame("Frame", nil, bar)
        if tot then
            posFrame:SetFrameStrata("FULLSCREEN")
        else
            posFrame:SetFrameStrata("MEDIUM")
        end
        posFrame:SetFrameLevel(bar:GetFrameLevel() + 1)
        bar.BBFPositionFrame = posFrame
    end

    local posFrame = bar.BBFPositionFrame
    posFrame:ClearAllPoints()
    posFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", startX, startY)
    posFrame:SetSize(width, height)

    if not posFrame.BBFPixelBorder then
        local borderFrame = CreateFrame("Frame", nil, posFrame)
        borderFrame:SetAllPoints(posFrame)
        if tot then
            borderFrame:SetFrameStrata("FULLSCREEN")
        else
            borderFrame:SetFrameStrata("MEDIUM")
        end
        borderFrame:SetFrameLevel(posFrame:GetFrameLevel() + 1)

        local edges = {}
        for i = 1, 4 do
            local tex = borderFrame:CreateTexture(nil, "BORDER", nil, 4)
            tex:SetColorTexture(0, 0, 0, 1)
            tex:SetIgnoreParentScale(true)
            edges[i] = tex
        end

        borderFrame.edges = edges
        posFrame.BBFPixelBorder = borderFrame

        bar.BBFPixelBorder = borderFrame
        bar.BBFBlackBorder = edges
    end

    local borderFrame = posFrame.BBFPixelBorder
    local borders = borderFrame.edges
    local top    = borders[1]
    local right  = borders[2]
    local bottom = borders[3]
    local left   = borders[4]

    local thickness = 1
    local minPixels = 1
    local UsePixelUtil = PixelUtil and PixelUtil.SetHeight

    if UsePixelUtil then
        PixelUtil.SetHeight(top,    thickness, minPixels)
        PixelUtil.SetHeight(bottom, thickness, minPixels)
        PixelUtil.SetWidth(left,    thickness, minPixels)
        PixelUtil.SetWidth(right,   thickness, minPixels)

        top:ClearAllPoints()
        PixelUtil.SetPoint(top, "BOTTOMLEFT",  posFrame, "TOPLEFT",  -1, 0)
        PixelUtil.SetPoint(top, "BOTTOMRIGHT", posFrame, "TOPRIGHT", 1, 0)

        bottom:ClearAllPoints()
        PixelUtil.SetPoint(bottom, "TOPLEFT",  posFrame, "BOTTOMLEFT",  -1, 0)
        PixelUtil.SetPoint(bottom, "TOPRIGHT", posFrame, "BOTTOMRIGHT", 1, 0)

        left:ClearAllPoints()
        PixelUtil.SetPoint(left, "TOPRIGHT",    posFrame, "TOPLEFT",    0, 1)
        PixelUtil.SetPoint(left, "BOTTOMRIGHT", posFrame, "BOTTOMLEFT", 0, -1)

        right:ClearAllPoints()
        PixelUtil.SetPoint(right, "TOPLEFT",    posFrame, "TOPRIGHT",    0, 1)
        PixelUtil.SetPoint(right, "BOTTOMLEFT", posFrame, "BOTTOMRIGHT", 0, -1)
    end

    if not bar.pixelBorderBackground then
        bar.pixelBorderBackground = bar:CreateTexture(nil, "BACKGROUND")
        bar.pixelBorderBackground:SetColorTexture(0, 0, 0, 0.45)
    end

    bar.pixelBorderBackground:ClearAllPoints()
    local scale = bar:GetEffectiveScale() or 1
    local inset = (scale < 1) and (1 / scale) * 0.5 or 0
    bar.pixelBorderBackground:SetPoint("TOPLEFT", top, "TOPLEFT", inset, -inset)
    bar.pixelBorderBackground:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMRIGHT", -inset, inset)

    borderFrame:Show()
    for _, tex in ipairs(borders) do
        tex:Show()
    end
end

local function SetBarMask(bar, maskTexture, pixelBorderMode, tot)
    if not bar or not maskTexture then return end

    if pixelBorderMode then
        maskTexture:SetTexture("interface\\masks\\squaremask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        maskTexture:SetTexCoord(0.05, 0.95, 0.01, 0.99)
        maskTexture:ClearAllPoints()

        if bar.BBFPositionFrame then
            local posFrame = bar.BBFPositionFrame
            maskTexture:SetPoint("TOPLEFT", bar.pixelBorderBackground, "TOPLEFT", ((tot and 1) or -0.5), -0.5)
            maskTexture:SetPoint("BOTTOMRIGHT", bar.pixelBorderBackground, "BOTTOMRIGHT", -0.75, tot and 0.5 or 0)
            if class == "EVOKER" and not maskTexture.bbfTexHook then
                hooksecurefunc(maskTexture, "SetAtlas", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:SetTexture("interface\\masks\\squaremask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                    self:SetTexCoord(0.05, 0.95, 0.01, 0.99)
                    self:ClearAllPoints()
                    maskTexture:SetPoint("TOPLEFT", posFrame, "TOPLEFT", -0.5, 0.5)
                    maskTexture:SetPoint("BOTTOMRIGHT", posFrame, "BOTTOMRIGHT", 0.5, -0.5)
                    self.changing = false
                end)
                maskTexture.bbfTexHook = true
            end
        elseif bar.BBFPixelBorder and bar.BBFPixelBorder.edges then
            local borders = bar.BBFPixelBorder.edges
            local top    = borders[1]
            local right  = borders[2]

            local scale = bar:GetEffectiveScale() or 1
            local halfPixel = 0.5 / scale

            maskTexture:SetPoint("TOPLEFT", top, "BOTTOMLEFT", -halfPixel, halfPixel)
            maskTexture:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", halfPixel, -halfPixel)
        else
            maskTexture:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
            maskTexture:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        end
    end
end

local BorderPositions = {
    target = {
        health   = { width = 123, height = 19, startX = 0, startY = -1 },
        mana     = { width = 123, height = 8, startX = 0, startY = -2 },
        totHealth= { width = 63, height = 12, startX = 0, startY = 0 },
        totMana  = { width = 63, height = 4, startX = 3, startY = 0 },
    },
    focus = {
        health   = { width = 123, height = 19, startX = 0, startY = -1 },
        mana     = { width = 123, height = 8, startX = 0, startY = -2 },
        totHealth= { width = 63, height = 12, startX = 0, startY = 0 },
        totMana  = { width = 63, height = 4, startX = 3, startY = 0 },
    },
    player = {
        health = { width = 123, height = 19, startX = 0, startY = 0 },
        mana   = { width = 123, height = 8, startX = 0, startY = -2 },
        alt    = { width = 123, height = 8, startX = 0, startY = 0 },
    },
    pet = {
        health = { width = 64, height = 14, startX = 1, startY = 0 },
        mana   = { width = 64, height = 5, startX = 1, startY = 0 },
    },
    party = {
        health = { width = 76, height = 15, startX = 0, startY = 0 },
        mana   = { width = 76, height = 5, startX = 0, startY = 0 },
    },
}

function BBF.UpdateNoPortraitText(frame, frameType)
    local db = BetterBlizzFramesDB
    local thickOutline = db.changeUnitFrameValueFont and db.unitFrameValueFontOutline == "THICKOUTLINE"
    local defaultFont = not db.changeUnitFrameValueFont
    local manaTextYOffset = thickOutline and -5.5 or defaultFont and -5 or -4.5
    local hpTextYOffset = thickOutline and 9.5 or 10.5
    local leftTextXOffset = db.changeUnitFrameValueFont and 68 or 67
    local pixel = db.noPortraitPixelBorder

    if db.noPortraitPixelBorder then
        manaTextYOffset = manaTextYOffset - (thickOutline and 1 or 2)
        if defaultFont then
            manaTextYOffset = manaTextYOffset + 0.5
        end
    end

    manaTextYOffset = manaTextYOffset + (BetterBlizzFramesDB.tempManaYOffset or 0)
    hpTextYOffset = hpTextYOffset + (BetterBlizzFramesDB.tempHpYOffset or 0)

    if frameType == "target" or frameType == "focus" then
        local content = frame.TargetFrameContent
        local contentMain = content.TargetFrameContentMain
        local hpContainer = contentMain.HealthBarsContainer
        local manaBar = contentMain.ManaBar
        local healthTextParent = frame.BBFHealthTextFrame or frame
        local manaTextParent = frame.BBFManaTextFrame or frame

        hpContainer.LeftText:SetParent(healthTextParent)
        hpContainer.LeftText:ClearAllPoints()
        hpContainer.LeftText:SetPoint("LEFT", frame.noPortraitMode.Texture, "LEFT", leftTextXOffset, hpTextYOffset)
        hpContainer.RightText:SetParent(healthTextParent)
        hpContainer.RightText:ClearAllPoints()
        hpContainer.RightText:SetPoint("RIGHT", frame.noPortraitMode.Texture, "RIGHT", -67, hpTextYOffset)
        hpContainer.HealthBarText:SetParent(healthTextParent)
        hpContainer.HealthBarText:ClearAllPoints()
        hpContainer.HealthBarText:SetPoint("CENTER", frame.noPortraitMode.Texture, "CENTER", 2, hpTextYOffset)
        hpContainer.DeadText:SetParent(healthTextParent)
        hpContainer.DeadText:ClearAllPoints()
        hpContainer.DeadText:SetPoint("CENTER", frame.noPortraitMode.Texture, "CENTER", -1, hpTextYOffset)

        manaBar.LeftText:SetParent(manaTextParent)
        manaBar.LeftText:ClearAllPoints()
        manaBar.LeftText:SetPoint("LEFT", frame.noPortraitMode.Texture, "LEFT", leftTextXOffset, manaTextYOffset)
        manaBar.RightText:SetParent(manaTextParent)
        manaBar.RightText:ClearAllPoints()
        manaBar.RightText:SetPoint("RIGHT", frame.noPortraitMode.Texture, "RIGHT", -67, manaTextYOffset)
        manaBar.ManaBarText:SetParent(manaTextParent)
        manaBar.ManaBarText:ClearAllPoints()
        manaBar.ManaBarText:SetPoint("CENTER", frame.noPortraitMode.Texture, "CENTER", 2, manaTextYOffset)

    elseif frameType == "player" then
        local content = frame.PlayerFrameContent
        local contentMain = content.PlayerFrameContentMain
        local hpContainer = contentMain.HealthBarsContainer
        local manaBar = contentMain.ManaBarArea.ManaBar
        local healthTextParent = frame.BBFHealthTextFrame or frame
        local manaTextParent = frame.BBFManaTextFrame or frame

        hpContainer.LeftText:SetParent(healthTextParent)
        hpContainer.LeftText:ClearAllPoints()
        hpContainer.LeftText:SetPoint("LEFT", frame.noPortraitMode.Texture, "LEFT", leftTextXOffset, hpTextYOffset)
        hpContainer.RightText:SetParent(healthTextParent)
        hpContainer.RightText:ClearAllPoints()
        hpContainer.RightText:SetPoint("RIGHT", frame.noPortraitMode.Texture, "RIGHT", -67, hpTextYOffset)
        hpContainer.HealthBarText:SetParent(healthTextParent)
        hpContainer.HealthBarText:ClearAllPoints()
        hpContainer.HealthBarText:SetPoint("CENTER", frame.noPortraitMode.Texture, "CENTER", 2, hpTextYOffset)

        manaBar.LeftText:SetParent(manaTextParent)
        manaBar.LeftText:ClearAllPoints()
        manaBar.LeftText:SetPoint("LEFT", frame.noPortraitMode.Texture, "LEFT", leftTextXOffset, manaTextYOffset)
        manaBar.RightText:SetParent(manaTextParent)
        manaBar.RightText:ClearAllPoints()
        manaBar.RightText:SetPoint("RIGHT", frame.noPortraitMode.Texture, "RIGHT", -67, manaTextYOffset)
        manaBar.ManaBarText:SetParent(manaTextParent)
        manaBar.ManaBarText:ClearAllPoints()
        manaBar.ManaBarText:SetPoint("CENTER", frame.noPortraitMode.Texture, "CENTER", 2, manaTextYOffset)

    elseif frameType == "pet" then
        local petHpTextYOffset = db.noPortraitPixelBorder and -17.5 or (db.changeUnitFrameValueFont and db.unitFrameValueFontOutline and -19) or -18
        local petManaTextYOffset = db.noPortraitPixelBorder and -30 or (db.changeUnitFrameValueFont and db.unitFrameValueFontOutline and -29) or -28
        local centerTextXOffset = db.noPortraitPixelBorder and 70 or 71.5

        PetFrameHealthBarText:ClearAllPoints()
        PetFrameHealthBarText:SetPoint("CENTER", PetFrame, "TOPLEFT", centerTextXOffset, petHpTextYOffset)
        PetFrameHealthBarTextLeft:ClearAllPoints()
        PetFrameHealthBarTextLeft:SetPoint("LEFT", PetFrame, "TOPLEFT", 38, petHpTextYOffset)
        PetFrameHealthBarTextRight:ClearAllPoints()
        PetFrameHealthBarTextRight:SetPoint("RIGHT", PetFrame, "TOPLEFT", 100, petHpTextYOffset)
        PetFrameManaBarText:ClearAllPoints()
        PetFrameManaBarText:SetPoint("CENTER", PetFrame, "TOPLEFT", centerTextXOffset, petManaTextYOffset)
        PetFrameManaBarTextLeft:ClearAllPoints()
        PetFrameManaBarTextLeft:SetPoint("LEFT", PetFrame, "TOPLEFT", 38, petManaTextYOffset)
        PetFrameManaBarTextRight:ClearAllPoints()
        PetFrameManaBarTextRight:SetPoint("RIGHT", PetFrame, "TOPLEFT", 100, petManaTextYOffset)

    elseif frameType == "tot" then
        local totFrame = frame.totFrame
        local textParent = totFrame.BBFTextFrame or totFrame

        totFrame.HealthBar.DeadText:SetParent(textParent)
        totFrame.HealthBar.DeadText:ClearAllPoints()
        totFrame.HealthBar.DeadText:SetPoint("LEFT", 48, 3)
        totFrame.HealthBar.UnconsciousText:SetParent(textParent)
        totFrame.HealthBar.UnconsciousText:ClearAllPoints()
        totFrame.HealthBar.UnconsciousText:SetPoint("LEFT", 48, 3)

    elseif frameType == "party" then
        for partyFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            local hpContainer = partyFrame.HealthBarContainer
            local manaBar = partyFrame.ManaBar

            local manaYOffset = db.noPortraitPixelBorder and -9 or (db.changeUnitFrameValueFont and db.unitFrameValueFontOutline and -5.5) or -4.5

            hpContainer.CenterText:ClearAllPoints()
            hpContainer.CenterText:SetPoint("CENTER", partyFrame.Texture, "CENTER", 2, 10)
            hpContainer.LeftText:ClearAllPoints()
            hpContainer.LeftText:SetPoint("LEFT", partyFrame.Texture, "LEFT", 57, 10.5)
            hpContainer.RightText:ClearAllPoints()
            hpContainer.RightText:SetPoint("RIGHT", partyFrame.Texture, "RIGHT", -57, 10.5)
            manaBar.TextString:ClearAllPoints()
            manaBar.TextString:SetPoint("CENTER", partyFrame.Texture, "CENTER", 2, manaYOffset)
            manaBar.LeftText:ClearAllPoints()
            manaBar.LeftText:SetPoint("LEFT", partyFrame.Texture, "LEFT", 57, manaYOffset)
            manaBar.RightText:ClearAllPoints()
            manaBar.RightText:SetPoint("RIGHT", partyFrame.Texture, "RIGHT", -57, manaYOffset)
        end
    end
end

local function MakeNoPortraitMode(frame)
    local db = BetterBlizzFramesDB
    local hideLvl = db.hideLevelText
    local alwaysHideLvl = hideLvl and db.hideLevelTextAlways
    local hideDragon = db.hideRareDragonTexture

    local ClassResourceFrames = {
        ROGUE      = RogueComboPointBarFrame,
        DRUID      = DruidComboPointBarFrame,
        WARLOCK    = WarlockPowerFrame,
        MAGE       = MageArcaneChargesFrame,
        MONK       = MonkHarmonyBarFrame,
        EVOKER     = EssencePlayerFrame,
        PALADIN    = PaladinPowerBarFrame,
        DEATHKNIGHT = RuneFrame,
    }
    local classFrame = ClassResourceFrames[class]

    if frame == TargetFrame or frame == FocusFrame then
        -- Frame
        local content = frame.TargetFrameContent
        local frameContainer = frame.TargetFrameContainer
        local contentMain = content.TargetFrameContentMain
        local contentContext = content.TargetFrameContentContextual

        -- Status
        local hpContainer = contentMain.HealthBarsContainer
        local manaBar = contentMain.ManaBar

        contentMain.ReputationColor:SetParent(BBF.hiddenFrame)

        frameContainer:SetAlpha(0)
        --frameContainer:SetParent(BBF.hiddenFrame)
        manaBar.ManaBarMask:SetTexture("interface/hud/uipartyframeportraitoffmanamask")

        frame.noPortraitMode = CreateFrame("Frame")
        frame.noPortraitMode:SetParent(frame)
        frame.noPortraitMode:SetFrameStrata("HIGH")
        frame.noPortraitMode:SetAllPoints(frame)
        frame.noPortraitMode.Texture = frame.noPortraitMode:CreateTexture(nil, "OVERLAY")
        frame.noPortraitMode.Texture:SetParent(frame.noPortraitMode)
        frame.noPortraitMode.Texture:SetSize(254, 46)
        frame.noPortraitMode.Texture:SetTexCoord(1, 0, 0, 1)
        frame.noPortraitMode.Texture:SetPoint("TOPLEFT", -42, -38)

        frame.bbfName:SetParent(frame.noPortraitMode)

        frame.noPortraitMode.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.noPortraitMode.Background:SetColorTexture(0,0,0,0.45)
        frame.noPortraitMode.Background:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", 0, 0)
        frame.noPortraitMode.BgMask = frame.noPortraitMode:CreateMaskTexture()
        frame.noPortraitMode.BgMask:SetAllPoints(frame.noPortraitMode.Background)
        frame.noPortraitMode.BgMask:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\frameMask.tga", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frame.noPortraitMode.Background:AddMaskTexture(frame.noPortraitMode.BgMask)

        local function GetFrameColor()
            local r,g,b = frameContainer.FrameTexture:GetVertexColor()
            frame.noPortraitMode.Texture:SetVertexColor(r,g,b)
        end
        GetFrameColor()
        hooksecurefunc(frameContainer.FrameTexture, "SetVertexColor", GetFrameColor)

        BBF.UpdateNoPortraitText(frame, frame.unit)
        --AdjustFramePoint(hpContainer.HealthBar.OverAbsorbGlow, -7)
        hpContainer.HealthBar.OverAbsorbGlow:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPRIGHT", -10, 0)

        local pixelBorderMode = db.noPortraitPixelBorder

        contentContext:SetParent(frame.noPortraitMode)
        contentContext.HighLevelTexture:ClearAllPoints()
        contentContext.HighLevelTexture:SetPoint("CENTER", frame, "RIGHT", -91, 17)
        contentContext.PetBattleIcon:ClearAllPoints()
        contentContext.PetBattleIcon:SetPoint("CENTER", frame, "BOTTOMRIGHT", -35, 25)
        contentContext.PrestigePortrait:SetScale(0.85)
        contentContext.PrestigeBadge:SetScale(0.85)
        contentContext.PrestigePortrait:ClearAllPoints()
        contentContext.PrestigePortrait:SetPoint("TOPRIGHT", 5, -17)
        contentContext.LeaderIcon:ClearAllPoints()
        contentContext.LeaderIcon:SetPoint("TOPRIGHT", -86, -24.5)
        contentContext.GuideIcon:ClearAllPoints()
        contentContext.GuideIcon:SetPoint("TOPRIGHT", -86, -24.5)
        contentContext.QuestIcon:ClearAllPoints()
        contentContext.QuestIcon:SetPoint("TOPRIGHT", -65, pixelBorderMode and -40 or -45)
        contentContext.BossIcon:ClearAllPoints()
        contentContext.BossIcon:SetPoint("TOPRIGHT", -65, pixelBorderMode and -40 or -45)
        contentContext.PetBattleIcon:SetSize(20,20)
        contentContext.PetBattleIcon:ClearAllPoints()
        contentContext.PetBattleIcon:SetPoint("TOPRIGHT", -65, pixelBorderMode and -41 or -47)
        contentContext.RaidTargetIcon:ClearAllPoints()
        contentContext.RaidTargetIcon:SetPoint("TOPRIGHT", pixelBorderMode and -63 or -56, pixelBorderMode and -40 or -42)
        if pixelBorderMode then
            contentContext.RaidTargetIcon:SetSize(20,20)
        end

        --AdjustFramePoint(frameContainer.Portrait, nil, -4)
        frameContainer.Portrait:SetPoint("TOPRIGHT", frameContainer, "TOPRIGHT", -26, -19)

        contentMain.LevelText:SetParent(frame.noPortraitMode)
        contentMain.LevelText:ClearAllPoints()
        contentMain.LevelText:SetPoint("RIGHT", frame, "RIGHT", -196, 17)
        contentMain.ReputationColor:SetParent(BBF.hiddenFrame)

        frameContainer.Flash:SetDrawLayer("BACKGROUND")
        frameContainer.Flash:SetParent((db.hideCombatGlow or db.noPortraitPixelBorder) and BBF.hiddenFrame or frame)
        frameContainer.Portrait:SetSize(62,62)
        frameContainer.Portrait:ClearAllPoints()
        frameContainer.Portrait:SetPoint("TOPRIGHT", -23, -22)
        frameContainer.PortraitMask:SetSize(61,61)
        frameContainer.PortraitMask:ClearAllPoints()
        frameContainer.PortraitMask:SetPoint("CENTER", frameContainer.Portrait, "CENTER", 0, 0)
        frameContainer.BossPortraitFrameTexture:SetParent(db.hideRareDragonTexture and BBF.hiddenFrame or frame.noPortraitMode)
        frameContainer.BossPortraitFrameTexture:SetAtlas("nameplates-icon-elite-gold")
        frameContainer.BossPortraitFrameTexture:SetSize(15, 15)
        frameContainer.BossPortraitFrameTexture:ClearAllPoints()
        frameContainer.BossPortraitFrameTexture:SetPoint("CENTER", hpContainer, "TOPRIGHT", -3.5, -1)
        frameContainer.BossPortraitFrameTexture:SetDrawLayer("OVERLAY", 7)


        -- frameContainer.PlayerPortrait:SetSize(62, 62)
        -- frameContainer.PlayerPortrait:ClearAllPoints()
        -- frameContainer.PlayerPortrait:SetPoint("TOPLEFT", 25, -22)
        -- frameContainer.PlayerPortraitMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        -- frameContainer.PlayerPortraitMask:ClearAllPoints()
        -- frameContainer.PlayerPortraitMask:SetPoint("CENTER", frameContainer.PlayerPortrait, "CENTER", 0, 0)



        --------- these might need updates / different method
        local totFrame = frame.totFrame
        local totHpBar = totFrame.HealthBar
        local totManaBar = totFrame.ManaBar
        totFrame:SetFrameStrata("DIALOG")
        totHpBar:SetStatusBarColor(0, 1, 0)
        totHpBar:SetSize(65, 16)
        totHpBar:ClearAllPoints()
        totHpBar:SetPoint("TOPRIGHT", -19, -10)
        totHpBar:SetFrameLevel(1)
        totManaBar:SetSize(67, 8)
        totManaBar:ClearAllPoints()
        totManaBar:SetPoint("TOPRIGHT", -20, -25)
        totManaBar:SetFrameLevel(1)
        totFrame.Portrait:SetParent(BBF.hiddenFrame)

        local hideToTMana = (frame == TargetFrame and db.hideUnitFrameTargetMana) or (frame == FocusFrame and db.hideUnitFrameFocusMana)
        totFrame.Background = totFrame.HealthBar:CreateTexture(nil, "BACKGROUND")
        totFrame.Background:SetColorTexture(0,0,0,0.45)
        totFrame.Background:SetPoint("TOPLEFT", totFrame.HealthBar, "TOPLEFT", 1, -1)
        if hideToTMana then
            totFrame.Background:SetPoint("BOTTOMRIGHT", totFrame.HealthBar, "BOTTOMRIGHT", -1, 1)
        else
            totFrame.Background:SetPoint("BOTTOMRIGHT", totFrame.manabar, "BOTTOMRIGHT", -1, 1)
        end
        totFrame.FrameTexture:SetSize(130, 33)
        local totTexture = (frame == TargetFrame) and targetDefaultTex or focusDefaultTex
        totFrame.FrameTexture:SetTexture(totTexture)
        totFrame.FrameTexture:SetTexCoord(0, 1, 0, 1)
        totFrame.FrameTexture:ClearAllPoints()
        totFrame.FrameTexture:SetPoint("TOPLEFT", 3, -9)

        if not db.noPortraitPixelBorder then
            totHpBar.HealthBarMask:SetSize(98, 22)
            totHpBar.HealthBarMask:SetTexture("interface/hud/uipartyframeportraitoffhealthmask")
            SetXYPoint(totHpBar.HealthBarMask, -17, 3.5)

            totManaBar.ManaBarMask:SetSize(96, 16)
            totManaBar.ManaBarMask:SetTexture("interface/hud/uipartyframeportraitoffmanamask")
            SetXYPoint(totManaBar.ManaBarMask, -13, 4)
        end

        if not totFrame.BBFTextFrame then
            totFrame.BBFTextFrame = CreateFrame("Frame", nil, totFrame)
            totFrame.BBFTextFrame:SetAllPoints(totFrame)
        end

        totFrame.HealthBar.DeadText:SetParent(totFrame.BBFTextFrame)
        totFrame.HealthBar.UnconsciousText:SetParent(totFrame.BBFTextFrame)

        if db.noPortraitPixelBorder then
            totFrame.FrameTexture:SetAlpha(0)
            totFrame.Background:SetAlpha(0)

            if frame == TargetFrame then
                local cfg = BorderPositions.target.totHealth
                BlackBorder(totHpBar, cfg.width, cfg.height, cfg.startX, cfg.startY, true)
                cfg = BorderPositions.target.totMana
                BlackBorder(totManaBar, cfg.width, cfg.height, cfg.startX, cfg.startY, true)
                SetBarMask(totHpBar, totHpBar.HealthBarMask, true)
                SetBarMask(totManaBar, totManaBar.ManaBarMask, true, true)

                if totHpBar.pixelBorderBackground then
                    totHpBar.pixelBorderBackground:SetAlpha(1)
                end
                if totManaBar.pixelBorderBackground then
                    totManaBar.pixelBorderBackground:SetAlpha(1)
                end
            elseif frame == FocusFrame then
                local cfg = BorderPositions.focus.totHealth
                BlackBorder(totHpBar, cfg.width, cfg.height, cfg.startX, cfg.startY, true)
                cfg = BorderPositions.focus.totMana
                BlackBorder(totManaBar, cfg.width, cfg.height, cfg.startX, cfg.startY, true)
                SetBarMask(totHpBar, totHpBar.HealthBarMask, true)
                SetBarMask(totManaBar, totManaBar.ManaBarMask, true, true)

                if totHpBar.pixelBorderBackground then
                    totHpBar.pixelBorderBackground:SetAlpha(1)
                end
                if totManaBar.pixelBorderBackground then
                    totManaBar.pixelBorderBackground:SetAlpha(1)
                end
            end

            if not totManaBar.BBFVisibilityHooked then
                totManaBar.BBFVisibilityHooked = true
                hooksecurefunc(totManaBar, "Hide", function()
                    if totManaBar.BBFPixelBorder then
                        totManaBar.BBFPixelBorder:Hide()
                    end
                    if totManaBar.pixelBorderBackground then
                        totManaBar.pixelBorderBackground:SetAlpha(0)
                    end
                end)
                hooksecurefunc(totManaBar, "Show", function()
                    if db.noPortraitPixelBorder and totManaBar.BBFPixelBorder then
                        totManaBar.BBFPixelBorder:Show()
                    end
                    if db.noPortraitPixelBorder and totManaBar.pixelBorderBackground then
                        totManaBar.pixelBorderBackground:SetAlpha(1)
                    end
                end)
            end

            local maxBorderLevel = 0
            if totHpBar.BBFPixelBorder then
                maxBorderLevel = math.max(maxBorderLevel, totHpBar.BBFPixelBorder:GetFrameLevel())
            end
            if totManaBar.BBFPixelBorder then
                maxBorderLevel = math.max(maxBorderLevel, totManaBar.BBFPixelBorder:GetFrameLevel())
            end
            if totFrame.BBFTextFrame and maxBorderLevel > 0 then
                totFrame.BBFTextFrame:SetFrameLevel(maxBorderLevel + 1)
            end
        else

            if totFrame.BBFTextFrame then
                local maxBarLevel = math.max(totHpBar:GetFrameLevel(), totManaBar:GetFrameLevel())
                totFrame.BBFTextFrame:SetFrameLevel(maxBarLevel + 10)
            end

            totFrame.FrameTexture:SetAlpha(1)
            totFrame.Background:SetAlpha(1)

            if totHpBar.pixelBorderBackground then
                totHpBar.pixelBorderBackground:SetAlpha(0)
            end
            if totManaBar.pixelBorderBackground then
                totManaBar.pixelBorderBackground:SetAlpha(0)
            end
        end

        if not totFrame.FrameTexture.noPortraitMode then
            totFrame.FrameTexture.noPortraitMode = true
            hooksecurefunc(totFrame.FrameTexture, "SetTexture", function(self)
                if self.changing then return end
                self.changing = true
                local totTexture = (frame == TargetFrame) and targetDefaultTex or focusDefaultTex
                totFrame.FrameTexture:SetTexture(totTexture)
                totFrame.FrameTexture:SetTexCoord(0, 1, 0, 1)
                self.changing = false
            end)
        end
        totFrame.Portrait:SetSize(37, 37)
        totFrame.Portrait:ClearAllPoints()
        totFrame.Portrait:SetPoint("TOPLEFT", 4, -5)
        BBF.UpdateNoPortraitText(frame, "tot")

        frameContainer.Flash:SetParent((db.hideCombatGlow or db.noPortraitPixelBorder) and BBF.hiddenFrame or frame.noPortraitMode)

        local hideToTDebuffs = (frame == TargetFrame and db.hideTargetToTDebuffs) or (frame == FocusFrame and db.hideFocusToTDebuffs)
        if not hideToTDebuffs then
            local debuffFrameName = totFrame:GetName().."Debuff"
            for i = 1, 4 do
                local debuffFrame = _G[debuffFrameName..i]
                debuffFrame:ClearAllPoints()
                if i == 1 then
                    debuffFrame:SetPoint("TOPLEFT", totFrame, "TOPRIGHT", -18, -9)
                elseif i == 2 then
                    debuffFrame:SetPoint("TOPLEFT", totFrame, "TOPRIGHT", -5, -9)
                elseif i== 3 then
                    debuffFrame:SetPoint("TOPLEFT", totFrame, "TOPRIGHT", -18, -22)
                elseif  i==4  then
                    debuffFrame:SetPoint("TOPLEFT", totFrame, "TOPRIGHT", -5, -22)
                end
            end
        end

        local function FrameAdjustments(container, minus, normal)
            if minus then
                container.FrameTexture:ClearAllPoints()
                container.FrameTexture:SetPoint("TOPLEFT", 20, -4)
                container.Flash:SetTexture(minusTex)
                container.Flash:SetTexCoord(1, 0, 0, 1)
                container.Flash:ClearAllPoints()
                container.Flash:SetAllPoints(frame.noPortraitMode.Texture)
                contentMain.LevelText:SetAlpha(1)
                hpContainer.HealthBarMask:SetHeight(30)
            else
                container.FrameTexture:ClearAllPoints()
                container.FrameTexture:SetPoint("TOPLEFT", 20.5, -18)
                container.Flash:SetTexture((frame == TargetFrame) and targetFlashTex or focusFlashTex)
                container.Flash:SetTexCoord(1, 0, 0, 1)
                container.Flash:ClearAllPoints()
                container.Flash:SetAllPoints(frame.noPortraitMode.Texture)
                container.Flash:SetDrawLayer("OVERLAY", 1)
                contentMain.LevelText:SetAlpha(1)
                hpContainer.HealthBarMask:SetHeight(30)
            end
        end

        hooksecurefunc(frame, "CheckClassification", function(self)
            local classification = UnitClassification(self.unit)

            -- Frame
            local content = self.TargetFrameContent
            local frameContainer = frameContainer
            local contentMain = content.TargetFrameContentMain
            -- Status
            local hpContainer = contentMain.HealthBarsContainer
            local manaBar = contentMain.ManaBar

            frame.noPortraitMode.Background:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", 0, 0)
            frameContainer.FrameTexture:SetAlpha(0)

            if db.noPortraitPixelBorder then
                SetBarMask(hpContainer.HealthBar, hpContainer.HealthBarMask, true)
                SetBarMask(manaBar, manaBar.ManaBarMask, true)

                local hideMana = (frame == TargetFrame and db.hideUnitFrameTargetMana) or (frame == FocusFrame and db.hideUnitFrameFocusMana)

                if not manaBar:IsShown() then
                    if not hideMana then
                        if manaBar.BBFPositionFrame then
                            manaBar.BBFPositionFrame:Show()
                            manaBar.BBFPositionFrame:SetParent(frame.noPortraitMode)
                            manaBar.BBFPositionFrame:SetAlpha(1)
                        end
                        if manaBar.BBFPixelBorder then
                            manaBar.BBFPixelBorder:Show()
                        end
                        if manaBar.pixelBorderBackground then
                            manaBar.pixelBorderBackground:Show()
                            manaBar.pixelBorderBackground:SetParent(frame.noPortraitMode)
                            manaBar.pixelBorderBackground:SetAlpha(1)
                        end
                    end
                else
                    if manaBar.BBFPositionFrame then
                        manaBar.BBFPositionFrame:SetParent(manaBar)
                    end
                    if manaBar.pixelBorderBackground then
                        manaBar.pixelBorderBackground:SetParent(manaBar)
                    end
                end
            else
                hpContainer.HealthBarMask:SetTexture("interface/hud/uipartyframeportraitoffhealthmask")
                SetXYPoint(hpContainer.HealthBarMask, -35, 5)
                hpContainer.HealthBarMask:SetSize(193, 30)

                manaBar.ManaBarMask:SetSize(190, 28)
                manaBar.ManaBarMask:SetTexture("interface/hud/uipartyframeportraitoffmanamask")
                SetXYPoint(manaBar.ManaBarMask, -33, 8)
            end

            frame.noPortraitMode.Texture:ClearAllPoints()
            frame.noPortraitMode.Texture:SetPoint("TOPLEFT", -42, -38)

            local hideMana = (frame == TargetFrame and db.hideUnitFrameTargetMana) or (frame == FocusFrame and db.hideUnitFrameFocusMana)

            if ( classification == "rareelite" ) then
                FrameAdjustments(frameContainer)
            elseif ( classification == "worldboss" or classification == "elite" ) then
                FrameAdjustments(frameContainer)
            elseif ( classification == "rare" ) then
                FrameAdjustments(frameContainer)
            elseif ( classification == "minus" ) then
                FrameAdjustments(frameContainer, true)
            else
                FrameAdjustments(frameContainer)
            end

            frameContainer.BossPortraitFrameTexture:SetAtlas("nameplates-icon-elite-gold")
            frameContainer.BossPortraitFrameTexture:SetSize(15, 15)
            frameContainer.BossPortraitFrameTexture:ClearAllPoints()
            frameContainer.BossPortraitFrameTexture:SetPoint("CENTER", hpContainer, "TOPRIGHT", -3.5, -1)
            frameContainer.BossPortraitFrameTexture:SetDrawLayer("OVERLAY", 7)

            local textureToUse
            local bgYOffset
            if hideMana or classification == "minus" then
                textureToUse = minusTex
                bgYOffset = classification == "minus" and 0 or 11
            else
                textureToUse = (frame == TargetFrame) and targetDefaultTex or focusDefaultTex
                bgYOffset = 0
            end

            frame.noPortraitMode.Texture:SetTexture(textureToUse)
            frame.noPortraitMode.Background:SetPoint("BOTTOMRIGHT", contentMain.ManaBar, "BOTTOMRIGHT", -10, bgYOffset)

            local hideToTMana = (frame == TargetFrame and db.hideUnitFrameTargetMana) or (frame == FocusFrame and db.hideUnitFrameFocusMana)
            if frame.totFrame and frame.totFrame.Background then
                frame.totFrame.Background:ClearAllPoints()
                frame.totFrame.Background:SetPoint("TOPLEFT", frame.totFrame.HealthBar, "TOPLEFT", 1, -1)
                if hideToTMana then
                    frame.totFrame.Background:SetPoint("BOTTOMRIGHT", frame.totFrame.HealthBar, "BOTTOMRIGHT", -1, 1)
                else
                    frame.totFrame.Background:SetPoint("BOTTOMRIGHT", frame.totFrame.manabar, "BOTTOMRIGHT", -1, 1)
                end
            end
        end)

        hooksecurefunc(frame, "CheckFaction", function(self)
            if (self.showPVP) then
                local factionGroup = UnitFactionGroup(self.unit)
                if (factionGroup == "Alliance") then
                    contentContext.PvpIcon:ClearAllPoints()
                    contentContext.PvpIcon:SetPoint("TOPRIGHT", -4, -24)
                elseif (factionGroup == "Horde") then
                    contentContext.PvpIcon:ClearAllPoints()
                    contentContext.PvpIcon:SetPoint("TOPRIGHT", 3, -22)
                end
                contentContext.PrestigePortrait:ClearAllPoints()
                contentContext.PrestigePortrait:SetPoint("TOPRIGHT", -48, -40)
            end
        end)
        contentContext.PvpIcon:SetParent(BBF.hiddenFrame)

        if db.noPortraitModesDesaturated or db.classColorFrameTexture then
            frame.noPortraitMode.Texture:SetDesaturated(true)
            totFrame.FrameTexture:SetDesaturated(true)
        end

        if db.noPortraitPixelBorder then
            frame.noPortraitMode.Texture:SetAlpha(0)
            frame.noPortraitMode.Background:SetAlpha(0)

            if frame == TargetFrame then
                local cfg = BorderPositions.target.health
                BlackBorder(hpContainer.HealthBar, cfg.width, cfg.height, cfg.startX, cfg.startY)
                cfg = BorderPositions.target.mana
                BlackBorder(manaBar, cfg.width, cfg.height, cfg.startX, cfg.startY)
                SetBarMask(hpContainer.HealthBar, hpContainer.HealthBarMask, true)
                SetBarMask(manaBar, manaBar.ManaBarMask, true)

                if hpContainer.HealthBar.pixelBorderBackground then
                    hpContainer.HealthBar.pixelBorderBackground:SetAlpha(1)
                end
                if manaBar.pixelBorderBackground then
                    manaBar.pixelBorderBackground:SetAlpha(1)
                end
            elseif frame == FocusFrame then
                local cfg = BorderPositions.focus.health
                BlackBorder(hpContainer.HealthBar, cfg.width, cfg.height, cfg.startX, cfg.startY)
                cfg = BorderPositions.focus.mana
                BlackBorder(manaBar, cfg.width, cfg.height, cfg.startX, cfg.startY)
                SetBarMask(hpContainer.HealthBar, hpContainer.HealthBarMask, true)
                SetBarMask(manaBar, manaBar.ManaBarMask, true)

                if hpContainer.HealthBar.pixelBorderBackground then
                    hpContainer.HealthBar.pixelBorderBackground:SetAlpha(1)
                end
                if manaBar.pixelBorderBackground then
                    manaBar.pixelBorderBackground:SetAlpha(1)
                end
            end

            if not manaBar.BBFVisibilityHooked then
                manaBar.BBFVisibilityHooked = true
                hooksecurefunc(manaBar, "Hide", function()
                    if manaBar.BBFPixelBorder then
                        manaBar.BBFPixelBorder:Hide()
                    end
                    if manaBar.pixelBorderBackground then
                        manaBar.pixelBorderBackground:SetAlpha(0)
                    end
                end)
                hooksecurefunc(manaBar, "Show", function()
                    if db.noPortraitPixelBorder and manaBar.BBFPixelBorder then
                        manaBar.BBFPixelBorder:Show()
                    end
                    if db.noPortraitPixelBorder and manaBar.pixelBorderBackground then
                        manaBar.pixelBorderBackground:SetAlpha(1)
                    end
                end)
            end

            if not frame.BBFHealthTextFrame then
                frame.BBFHealthTextFrame = CreateFrame("Frame", nil, hpContainer.HealthBar)
                frame.BBFHealthTextFrame:SetAllPoints(frame)
                frame.BBFHealthTextFrame:SetFrameStrata("HIGH")
            end

            if not frame.BBFManaTextFrame then
                frame.BBFManaTextFrame = CreateFrame("Frame", nil, manaBar)
                frame.BBFManaTextFrame:SetAllPoints(frame)
                frame.BBFManaTextFrame:SetFrameStrata("HIGH")
            end

            if hpContainer.HealthBar.BBFPixelBorder and frame.BBFHealthTextFrame then
                frame.BBFHealthTextFrame:SetFrameLevel(hpContainer.HealthBar.BBFPixelBorder:GetFrameLevel() + 1)
            end

            if manaBar.BBFPixelBorder and frame.BBFManaTextFrame then
                frame.BBFManaTextFrame:SetFrameLevel(manaBar.BBFPixelBorder:GetFrameLevel() + 1)
            end
        else

            if not frame.BBFHealthTextFrame then
                frame.BBFHealthTextFrame = CreateFrame("Frame", nil, hpContainer.HealthBar)
                frame.BBFHealthTextFrame:SetAllPoints(frame)
                frame.BBFHealthTextFrame:SetFrameStrata("HIGH")
            end

            if not frame.BBFManaTextFrame then
                frame.BBFManaTextFrame = CreateFrame("Frame", nil, manaBar)
                frame.BBFManaTextFrame:SetAllPoints(frame)
                frame.BBFManaTextFrame:SetFrameStrata("HIGH")
            end

            if frame.BBFHealthTextFrame then
                frame.BBFHealthTextFrame:SetFrameLevel(hpContainer.HealthBar:GetFrameLevel() + 10)
            end

            if frame.BBFManaTextFrame then
                frame.BBFManaTextFrame:SetFrameLevel(manaBar:GetFrameLevel() + 10)
            end

            frame.noPortraitMode.Texture:SetAlpha(1)
            frame.noPortraitMode.Background:SetAlpha(1)

            if hpContainer.HealthBar.pixelBorderBackground then
                hpContainer.HealthBar.pixelBorderBackground:SetAlpha(0)
            end
            if manaBar.pixelBorderBackground then
                manaBar.pixelBorderBackground:SetAlpha(0)
            end
        end

    elseif frame == PlayerFrame then
        -- PlayerFrame
        -- Frame
        local content = frame.PlayerFrameContent
        local frameContainer = frame.PlayerFrameContainer
        local contentMain = content.PlayerFrameContentMain
        local contentContext = content.PlayerFrameContentContextual
        -- Status
        local hpContainer = contentMain.HealthBarsContainer
        local manaBar = contentMain.ManaBarArea.ManaBar

        --contentMain.ReputationColor:SetParent(BBF.hiddenFrame) fix

        frame.noPortraitMode = CreateFrame("Frame")
        frame.noPortraitMode:SetParent(frame)
        frame.noPortraitMode:SetFrameStrata("HIGH")
        frame.noPortraitMode:SetAllPoints(frame)
        frame.noPortraitMode.Texture = frame.noPortraitMode:CreateTexture(nil, "OVERLAY")
        frame.noPortraitMode.bbfVehicleTexture = frame.noPortraitMode:CreateTexture(nil, "OVERLAY", nil, 7)
        frame.noPortraitMode.bbfVehicleTexture:SetSize(18, 18)
        frame.noPortraitMode.bbfVehicleTexture:ClearAllPoints()
        frame.noPortraitMode.bbfVehicleTexture:SetPoint("TOPLEFT", 76, -47)
        frame.noPortraitMode.bbfVehicleTexture:Hide()
        frame.noPortraitMode.bbfVehicleTexture:SetAtlas("Taxi_Frame_Gray")
        contentContext.GroupIndicator:SetAlpha(0)

        if class == "PRIEST" then
            hooksecurefunc(ClassPowerBar, "Setup", function()
                if frame.bbfClassPowerBarHidden then return end
                if frame.classPowerBar then
                    frame.classPowerBar:SetAlpha(0)
                    frame.bbfClassPowerBarHidden = true
                end
            end)
        end

        if db.noPortraitPixelBorder then
            local cfg = BorderPositions.player.health
            BlackBorder(hpContainer.HealthBar, cfg.width, cfg.height, cfg.startX, cfg.startY)
            cfg = BorderPositions.player.mana
            BlackBorder(manaBar, cfg.width, cfg.height, cfg.startX, cfg.startY)

            if not frame.BBFHealthTextFrame then
                frame.BBFHealthTextFrame = CreateFrame("Frame", nil, hpContainer.HealthBar)
                frame.BBFHealthTextFrame:SetAllPoints(frame)
                frame.BBFHealthTextFrame:SetFrameStrata("HIGH")
            end

            if not frame.BBFManaTextFrame then
                frame.BBFManaTextFrame = CreateFrame("Frame", nil, manaBar)
                frame.BBFManaTextFrame:SetAllPoints(frame)
                frame.BBFManaTextFrame:SetFrameStrata("HIGH")
            end

            if hpContainer.HealthBar.BBFPixelBorder and frame.BBFHealthTextFrame then
                frame.BBFHealthTextFrame:SetFrameLevel(hpContainer.HealthBar.BBFPixelBorder:GetFrameLevel() + 1)
            end

            if manaBar.BBFPixelBorder and frame.BBFManaTextFrame then
                frame.BBFManaTextFrame:SetFrameLevel(manaBar.BBFPixelBorder:GetFrameLevel() + 1)
            end
        else

            if not frame.BBFHealthTextFrame then
                frame.BBFHealthTextFrame = CreateFrame("Frame", nil, hpContainer.HealthBar)
                frame.BBFHealthTextFrame:SetAllPoints(frame)
                frame.BBFHealthTextFrame:SetFrameStrata("HIGH")
            end

            if not frame.BBFManaTextFrame then
                frame.BBFManaTextFrame = CreateFrame("Frame", nil, manaBar)
                frame.BBFManaTextFrame:SetAllPoints(frame)
                frame.BBFManaTextFrame:SetFrameStrata("HIGH")
            end

            if frame.BBFHealthTextFrame then
                frame.BBFHealthTextFrame:SetFrameLevel(hpContainer.HealthBar:GetFrameLevel() + 10)
            end

            if frame.BBFManaTextFrame then
                frame.BBFManaTextFrame:SetFrameLevel(manaBar:GetFrameLevel() + 10)
            end
        end

        --frame.bbfVehicleTexture:SetParent(frame.noPortraitMode)
        --frameContainer:SetAlpha(0)
        frameContainer:SetParent(BBF.hiddenFrame)

        manaBar.FullPowerFrame:SetParent(frame.noPortraitMode)

        contentMain.HitIndicator.HitText:ClearAllPoints()
        contentMain.HitIndicator.HitText:SetPoint("CENTER", frameContainer.PlayerPortrait)
        contentMain.HitIndicator.HitText:SetScale(0.85)
        contentMain.HitIndicator:SetParent(BBF.hiddenFrame)--PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)

        contentContext:SetParent(frame.noPortraitMode)
        frame.bbfName:SetParent(frame.noPortraitMode)

        contentContext.AttackIcon:ClearAllPoints()
        contentContext.AttackIcon:SetPoint("CENTER", -40, 0)
        contentContext.AttackIcon:SetSize(14, 15)
        contentContext.AttackIcon:SetDrawLayer("OVERLAY", 7)
        contentContext.AttackIcon:SetAtlas("questlog-questtypeicon-pvp")
        contentContext.PVPIcon:ClearAllPoints()
        contentContext.PVPIcon:SetPoint("TOPLEFT", 139, -81)
        contentContext.PVPIcon:SetScale(0.5)
        --contentContext.AttackIcon:SetParent(BBF.hiddenFrame)
        contentContext.PlayerPortraitCornerIcon:SetAtlas(nil)
        contentContext.PrestigePortrait:ClearAllPoints()
        contentContext.PrestigePortrait:SetPoint("TOPLEFT", 50, -41)
        contentContext.PrestigePortrait:SetScale(0.85)
        contentContext.PrestigeBadge:SetScale(0.85)
        contentContext.LeaderIcon:ClearAllPoints()
        contentContext.LeaderIcon:SetPoint("TOPLEFT", 86, -24)
        contentContext.GuideIcon:ClearAllPoints()
        contentContext.GuideIcon:SetPoint("TOPLEFT", 86, -22)
        contentContext.RoleIcon:SetSize(13, 13)
        contentContext.RoleIcon:ClearAllPoints()
        contentContext.RoleIcon:SetPoint("TOPLEFT", 81, -36)
        contentContext.PlayerRestLoop:ClearAllPoints()
        contentContext.PlayerRestLoop:SetPoint("TOPRIGHT", -35, -32)
        contentContext.PlayerRestLoop:SetScale(0.7)


        --AdjustFramePoint(contentContext.GroupIndicator, nil, -3)

        frameContainer.PlayerPortrait:SetSize(62, 62)
        frameContainer.PlayerPortraitMask:SetSize(62, 62)
        frameContainer.PlayerPortraitMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frameContainer.PlayerPortraitMask:ClearAllPoints()
        frameContainer.PlayerPortraitMask:SetPoint("CENTER", frameContainer.PlayerPortrait, "CENTER", 0, 0)

        frame.noPortraitMode.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.noPortraitMode.Background:SetColorTexture(0,0,0,0.45)
        frame.noPortraitMode.Background:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", 0, 0)
        frame.noPortraitMode.Background:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", 0, 0)
        frame.noPortraitMode.BgMask = frame.noPortraitMode:CreateMaskTexture()
        frame.noPortraitMode.BgMask:SetAllPoints(frame.noPortraitMode.Background)
        frame.noPortraitMode.BgMask:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\frameMask.tga", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frame.noPortraitMode.Background:AddMaskTexture(frame.noPortraitMode.BgMask)

        C_Timer.After(1, function()
            local bd = BigDebuffsplayerUnitFrame
            local oa = C_AddOns.IsAddOnLoaded("OmniAuras")
            if bd then
                if bd.mask then
                    bd.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                elseif bd.icon then
                    bd.mask = bd:CreateMaskTexture()
                    bd.mask:SetAllPoints(bd.icon)
                    bd.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                    bd.icon:AddMaskTexture(bd.mask)
                end
            end
            if oa then
                for _, child in ipairs({PlayerFrame.PlayerFrameContainer:GetChildren()}) do
                    if child:IsObjectType("Button") then
                        local mask = child.mask
                        if mask and mask.SetTexture then
                            mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                            break
                        end
                    end
                end
            end
        end)

        --AdjustFramePoint(hpContainer.HealthBar.OverAbsorbGlow,-3)
        hpContainer.HealthBar.OverAbsorbGlow:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPRIGHT", -7, 0)

        if C_CVar.GetCVar("comboPointLocation") == "1" and ComboFrame then
            ComboFrame:SetParent(TargetFrame)
            ComboFrame:SetFrameStrata("HIGH")
            BBF.UpdateLegacyComboPosition()
        end

        local function UpdateLevelDetails()
            PlayerLevelText:SetParent(frame.noPortraitMode)
            PlayerLevelText:SetDrawLayer("OVERLAY", 7)
            PlayerLevelText:Show()
            PlayerLevelText:ClearAllPoints()
            PlayerLevelText:SetPoint("LEFT", 194, 17)
        end

        local function UpdateLevel()
            if not db.playerEliteFrame then
                if alwaysHideLvl then
                    PlayerLevelText:SetParent(BBF.hiddenFrame)
                    PlayerLevelText:ClearAllPoints()
                    PlayerLevelText:SetPoint("LEFT", 194, 17)
                elseif hideLvl then
                    if UnitLevel("player") == (BBF.isMidnight and 90 or 80) then
                        PlayerLevelText:SetParent(BBF.hiddenFrame)
                        PlayerLevelText:ClearAllPoints()
                        PlayerLevelText:SetPoint("LEFT", 194, 17)
                    else
                        UpdateLevelDetails()
                    end
                else
                    UpdateLevelDetails()
                end
            else
                -- When playerEliteFrame is enabled, handle level text based on mode
                local mode = BetterBlizzFramesDB.playerEliteFrameMode
                if mode > 3 then
                    -- Always hide level text for mode > 3 (using UI-FocusFrame-Large texture)
                    PlayerLevelText:SetParent(BBF.hiddenFrame)
                elseif alwaysHideLvl or (hideLvl and UnitLevel("player") == (BBF.isMidnight and 90 or 80)) then
                    -- Hide level text based on hideLvl settings for mode <= 3
                    PlayerLevelText:SetParent(BBF.hiddenFrame)
                else
                    -- Show level text for other cases
                    UpdateLevelDetails()
                end
            end
        end
        hooksecurefunc("PlayerFrame_UpdateLevel", function()
            UpdateLevel()
        end)
        UpdateLevel()

        hooksecurefunc("PlayerFrame_UpdateRolesAssigned", function()
            contentContext.RoleIcon:ClearAllPoints()
            contentContext.RoleIcon:SetPoint("TOPLEFT", 81, -36)
            PlayerLevelText:SetShown(not UnitHasVehiclePlayerFrameUI("player"))
        end)

        if not db.hidePvpTimerText then
            hooksecurefunc("PlayerFrame_UpdatePvPStatus", function()
                contentContext.PvpTimerText:ClearAllPoints()
                contentContext.PvpTimerText:SetPoint("BOTTOMLEFT", 8, 8)
            end)
        end

        local function GetFrameColor()
            local r, g, b = frameContainer.FrameTexture:GetVertexColor()
            frame.noPortraitMode.Texture:SetVertexColor(r, g, b)

            if not db.skipFrameColorCombo then
                -- Warlock: Soul Shards
                local soulShards = _G.WarlockPowerFrame
                if soulShards and class == "WARLOCK" then
                    for _, v in pairs({ soulShards:GetChildren() }) do
                        if v.Background then
                            v.Background:SetVertexColor(
                                math.max(r - 0.35, 0),
                                math.max(g - 0.35, 0),
                                math.max(b - 0.35, 0)
                            )
                        end
                    end
                end

                if PaladinPowerBarFrame and class == "PALADIN" then
                    if PaladinPowerBarFrame.Background then
                        PaladinPowerBarFrame.Background:SetDesaturated(true)
                        PaladinPowerBarFrame.Background:SetVertexColor(
                            math.max(r - 0.05, 0),
                            math.max(g - 0.05, 0),
                            math.max(b - 0.05, 0)
                        )
                    end
                    if PaladinPowerBarFrame.ActiveTexture then
                        PaladinPowerBarFrame.ActiveTexture:SetDesaturated(true)
                        PaladinPowerBarFrame.ActiveTexture:SetVertexColor(
                            math.max(r - 0.05, 0),
                            math.max(g - 0.05, 0),
                            math.max(b - 0.05, 0)
                        )
                    end
                end

                -- Monk: Chi points
                local monkChiPoints = _G.MonkHarmonyBarFrame
                if monkChiPoints then
                    local r, g, b = frameContainer.FrameTexture:GetVertexColor()

                    local function ColorMonkChi(tex, mul)
                        if not tex then return end
                        tex:SetVertexColor(
                            math.min(math.max(r * mul, 0), 1),
                            math.min(math.max(g * mul, 0), 1),
                            math.min(math.max(b * mul, 0), 1)
                        )
                    end

                    for _, v in pairs({ monkChiPoints:GetChildren() }) do
                        if v.Chi_BG then
                            ColorMonkChi(v.Chi_BG, 1.1)
                        end
                        if v.Chi_BG_Active then
                            ColorMonkChi(v.Chi_BG_Active, 0.85)
                        end
                    end
                end

                -- Evoker: Essence charges
                local evokerEssencePoints = _G.EssencePlayerFrame
                if evokerEssencePoints and class == "EVOKER" then
                    local function ColorEssence(tex, mul)
                        if not tex then return end
                        tex:SetVertexColor(
                            math.min(math.max(r * mul, 0), 1),
                            math.min(math.max(g * mul, 0), 1),
                            math.min(math.max(b * mul, 0), 1)
                        )
                    end

                    for _, v in pairs({ evokerEssencePoints:GetChildren() }) do
                        if v.EssenceFillDone and v.EssenceFillDone.CircBG then
                            ColorEssence(v.EssenceFillDone.CircBG, 1.05)
                        end
                        if v.EssenceFilling and v.EssenceFilling.EssenceBG then
                            ColorEssence(v.EssenceFilling.EssenceBG, 1.0)
                        end
                        if v.EssenceEmpty and v.EssenceEmpty.EssenceBG then
                            ColorEssence(v.EssenceEmpty.EssenceBG, 0.7)
                        end
                        if v.EssenceFillDone and v.EssenceFillDone.CircBGActive then
                            ColorEssence(v.EssenceFillDone.CircBGActive, 0.9)
                        end
                        if v.EssenceDepleting and v.EssenceDepleting.EssenceBG then
                            ColorEssence(v.EssenceDepleting.EssenceBG, 0.9)
                        end
                        if v.EssenceDepleting and v.EssenceDepleting.CircBGActive then
                            ColorEssence(v.EssenceDepleting.CircBGActive, 0.9)
                        end
                        if v.EssenceFillDone and v.EssenceFillDone.RimGlow then
                            ColorEssence(v.EssenceFillDone.RimGlow, 1.2)
                        end
                        if v.EssenceDepleting and v.EssenceDepleting.RimGlow then
                            ColorEssence(v.EssenceDepleting.RimGlow, 1.1)
                        end
                    end
                end

                if class == "DRUID" then
                    local function updateComboPointTextures()
                        local druidComboPoints = _G.DruidComboPointBarFrame
                        if not druidComboPoints then return end

                        local r, g, b = frameContainer.FrameTexture:GetVertexColor()

                        local function ColorDruidCP(tex, mul)
                            if not tex then return end
                            tex:SetVertexColor(
                                math.min(math.max(r * mul, 0), 1),
                                math.min(math.max(g * mul, 0), 1),
                                math.min(math.max(b * mul, 0), 1)
                            )
                        end

                        for _, v in pairs({ druidComboPoints:GetChildren() }) do
                            if v.BG_Inactive then
                                ColorDruidCP(v.BG_Inactive, 1.1)
                            end
                            if v.BG_Active then
                                ColorDruidCP(v.BG_Active, 1.03)
                            end
                            if BetterBlizzFramesDB.druidOverstacks and v.ChargedFrameActive then
                                ColorDruidCP(v.ChargedFrameActive, 1.06)
                            end
                        end
                    end

                    if GetShapeshiftFormID() == 1 then
                        -- Already in Cat Form, run immediately
                        updateComboPointTextures()
                    else
                        -- Not in Cat Form, wait for it
                        if not BBF.CatFormWatcher then
                            local f = CreateFrame("Frame")
                            f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
                            f:SetScript("OnEvent", function(self)
                                if GetShapeshiftFormID() == 1 then
                                    updateComboPointTextures()
                                    self:UnregisterAllEvents()
                                    self:SetScript("OnEvent", nil)
                                end
                            end)
                            BBF.CatFormWatcher = f
                        end
                    end
                end
            end
        end

        GetFrameColor()
        hooksecurefunc(frameContainer.FrameTexture, "SetVertexColor", GetFrameColor)

        local DEFAULT_X, DEFAULT_Y = 29, 28.5
        local DEFAULT_POINT, DEFAULT_RELATIVE_POINT = "TOP", "BOTTOM"

        local CLASS_RESOURCE_TYPES = {
            ROGUE = Enum.PowerType.ComboPoints,
            MONK  = Enum.PowerType.Chi,
        }

        local resourceFramePositions = {
            EVOKER = {
                x = 29, y = 32, scale = 1.05, point = "TOP", relativePoint = "BOTTOM",
                specs = {
                    -- Augmentation Evoker
                    [1473] = { x = 29, y = 22, scale = 1.05 },
                },
            },
            WARRIOR = { x = 28, y = 30 },
            ROGUE = {
                x = 48, y = 38, scale = 0.85,
                resourceByMax = {
                    [5] = { x = 33.5, y = 37, scale = 0.95 },
                    [6] = { x = 47,   y = 40,},
                    [7] = { x = 61,   y = 43.5, scale = 0.75},
                },
            },
            MAGE = { x = 33, y = 34, scale = 0.95 },
            PALADIN = { x = 31.5, y = 31, scale = 0.91 },
            DEATHKNIGHT = { x = 38, y = 36, scale = 0.90 },
            WARLOCK = { x = 32, y = 32.5, scale = 0.9 },
            DRUID = {
                x = 35, y = 34, scale = 0.90,
            },
            MONK = {
                x = 29.5, y = 31, scale = 0.96,
                resourceByMax = {
                    [5] = { x = 32, y = 32, scale = 1 },
                    [6] = { x = 34, y = 34, scale = 0.92 },
                },
            },
        }

        local function GetPlayerClassAndSpecPosition(maxResource)
            local specIndex = GetSpecialization()
            local specID = specIndex and GetSpecializationInfo(specIndex)
            local cfg = resourceFramePositions[class]

            local point = DEFAULT_POINT
            local relativePoint = DEFAULT_RELATIVE_POINT
            local x = DEFAULT_X
            local y = DEFAULT_Y
            local scale = 1

            if cfg then
                point = cfg.point or point
                relativePoint = cfg.relativePoint or relativePoint
                x = cfg.x or x
                y = cfg.y or y
                scale = cfg.scale or scale

                -- Spec-specific overrides
                if cfg.specs and specID and cfg.specs[specID] then
                    local s = cfg.specs[specID]
                    point = s.point or point
                    relativePoint = s.relativePoint or relativePoint
                    x = s.x or x
                    y = s.y or y
                    scale = s.scale or scale
                end

                -- Max-resource-specific overrides (Rogue combo points, Monk chi, etc.)
                if maxResource and cfg.resourceByMax and cfg.resourceByMax[maxResource] then
                    local r = cfg.resourceByMax[maxResource]
                    point = r.point or point
                    relativePoint = r.relativePoint or relativePoint
                    x = r.x or x
                    y = r.y or y
                    scale = r.scale or scale
                end
            end

            if playerDefaultTex == "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOff-Minus.tga" then
                y = y + 15
            end

            return point, relativePoint, x, y, scale
        end

        local classConflicts = {
            ROGUE       = db.moveResourceToTargetRogue,
            DRUID       = db.moveResourceToTargetDruid,
            WARLOCK     = db.moveResourceToTargetWarlock,
            MAGE        = db.moveResourceToTargetMage,
            MONK        = db.moveResourceToTargetMonk,
            EVOKER      = db.moveResourceToTargetEvoker,
            PALADIN     = db.moveResourceToTargetPaladin,
            DEATHKNIGHT = db.moveResourceToTargetDK,
        }

        local function UpdateResourcePosition(inVehicle)
            if db.moveResource or (db.moveResourceToTarget and classConflicts[class]) then
                return
            end

            -- Get max resource if this class uses resource-based overrides
            local maxResource
            local powerType = CLASS_RESOURCE_TYPES[class]
            if powerType then
                maxResource = UnitPowerMax("player", powerType)
            end

            if not InCombatLockdown() then
                PlayerFrameBottomManagedFramesContainer:ClearAllPoints()

                local point, relativePoint, xOffset, yOffset, scale = GetPlayerClassAndSpecPosition(maxResource)
                local relativeFrame = PlayerFrame

                if inVehicle then
                    xOffset = xOffset + 2
                    yOffset = yOffset + 0
                end

                PlayerFrameBottomManagedFramesContainer:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset)
                PlayerFrameBottomManagedFramesContainer:SetScale(scale)
                PlayerFrameBottomManagedFramesContainer:SetFrameStrata("HIGH")
            else
                BBF.RunAfterCombat(function()
                    UpdateResourcePosition()
                end)
            end
        end

        BBF.UpdateResourcePositionNoPortrait = UpdateResourcePosition

        local vehicleWatcher = CreateFrame("Frame")
        vehicleWatcher:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
        --vehicleWatcher:RegisterEvent("UNIT_EXITED_VEHICLE")
        vehicleWatcher:SetScript("OnEvent", function(_, _, unit)
            UpdateResourcePosition(true)
        end)

        -- Watcher for classes whose layout depends on max resource (Rogue combos, Monk chi, etc.)
        if CLASS_RESOURCE_TYPES[class] then
            local watcher = CreateFrame("Frame")
            watcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            watcher:RegisterEvent("TRAIT_CONFIG_UPDATED")
            watcher:RegisterEvent("UNIT_MAXPOWER")
            watcher:SetScript("OnEvent", function(self, event, unit)
                if event == "UNIT_MAXPOWER" and unit ~= "player" then
                    return
                end
                UpdateResourcePosition()
            end)
        end

        local function PlayerEliteFrame()
            local playerElite = frame.noPortraitMode.Texture
            local mode = BetterBlizzFramesDB.playerEliteFrameMode
            local hideLvl = BetterBlizzFramesDB.hideLevelText
            local alwaysHideLvl = hideLvl and BetterBlizzFramesDB.hideLevelTextAlways

            -- Set Elite style according to value
            if mode == 1 then -- Rare (Silver)
                playerElite:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare")
                playerElite:SetDesaturated(true)
            elseif mode == 2 then -- Boss (Silver Winged)
                playerElite:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite")
                playerElite:SetDesaturated(true)
            elseif mode == 3 then -- Boss (Gold Winged)
                playerElite:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite")
                playerElite:SetDesaturated(false)
            elseif mode > 3 then -- For modes > 3, always use UI-FocusFrame-Large regardless of hideLvl
                playerElite:SetTexture("Interface\\TargetingFrame\\UI-FocusFrame-Large")
                playerElite:SetDesaturated(false)
            else
                frame.noPortraitMode.Texture:SetTexture(playerDefaultTex)
                frameContainer.FrameFlash:SetTexture(playerFlashTex)
                frameContainer.FrameFlash:SetTexCoord(0, 1, 0, 1)
                contentMain.StatusTexture:SetTexture(playerFlashTex)
            -- elseif mode == 4 then -- Only 3 available for classic
            --     db.playerEliteFrameMode = 3
            --     playerElite:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite")
            --     playerElite:SetDesaturated(false)
            end
        end

        local function ToggleNoLevelFrame(noLvl)
            if noLvl then
                frame.noPortraitMode.Texture:SetTexture(playerDefaultTex)
                frameContainer.FrameFlash:SetTexture(playerFlashNoLvl)
                frameContainer.FrameFlash:SetTexCoord(0, 1, 0, 1)
                contentMain.StatusTexture:SetTexture(playerFlashTex)
            else
                frame.noPortraitMode.Texture:SetTexture(playerDefaultTex)
                frameContainer.FrameFlash:SetTexture(playerFlashTex)
                frameContainer.FrameFlash:SetTexCoord(0, 1, 0, 1)
                contentMain.StatusTexture:SetTexture(playerFlashTex)
            end
        end

        local function ToPlayerArt()
            UpdateResourcePosition()

            if db.noPortraitPixelBorder then
                SetBarMask(hpContainer.HealthBar, hpContainer.HealthBarMask, true)
                SetBarMask(manaBar, manaBar.ManaBarMask, true)


                frame.noPortraitMode.Texture:SetAlpha(0)
                frame.noPortraitMode.Background:SetAlpha(0)
                if hpContainer.HealthBar.pixelBorderBackground then
                    hpContainer.HealthBar.pixelBorderBackground:SetAlpha(1)
                end
                if manaBar.pixelBorderBackground then
                    manaBar.pixelBorderBackground:SetAlpha(1)
                end
            else
                hpContainer.HealthBarMask:SetTexture("interface/hud/uipartyframeportraitoffhealthmask")
                hpContainer.HealthBarMask:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", -33, 9)
                hpContainer.HealthBarMask:SetSize(190, 34)

                manaBar.ManaBarMask:SetTexture("interface/hud/uipartyframeportraitoffmanamask")
                manaBar.ManaBarMask:SetSize(192, 25)
                manaBar.ManaBarMask:SetPoint("TOPLEFT", manaBar, "TOPLEFT", -34, 7)

                frame.noPortraitMode.Texture:SetAlpha(1)
                frame.noPortraitMode.Background:SetAlpha(1)
                if hpContainer.HealthBar.pixelBorderBackground then
                    hpContainer.HealthBar.pixelBorderBackground:SetAlpha(0)
                end
                if manaBar.pixelBorderBackground then
                    manaBar.pixelBorderBackground:SetAlpha(0)
                end
            end

            frame.noPortraitMode.Texture:Hide()

            frame.noPortraitMode.bbfVehicleTexture:Hide()

            frameContainer.FrameTexture:ClearAllPoints()
            frameContainer.FrameTexture:SetPoint("TOPLEFT", -19, 7)
            frameContainer.FrameTexture:SetAlpha(0)

            contentContext.RoleIcon:ClearAllPoints()
            contentContext.RoleIcon:SetPoint("TOPLEFT", 81, -36)

            contentContext.GroupIndicator:ClearAllPoints()
            contentContext.GroupIndicator:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -21, -33.5)
            PlayerFrameGroupIndicatorText:ClearAllPoints()
            PlayerFrameGroupIndicatorText:SetPoint("LEFT", contentContext.GroupIndicator.GroupIndicatorLeft, "LEFT", 20, 2.5)

            frame.noPortraitMode.Texture:SetSize(254, 46)
            if db.playerEliteFrame then
                PlayerEliteFrame()
                frameContainer.FrameFlash:SetTexture(playerFlashTex)
                frameContainer.FrameFlash:SetTexCoord(0, 1, 0, 1)
                contentMain.StatusTexture:SetTexture(playerFlashTex)
                -- Handle level text for playerEliteFrame
                local mode = BetterBlizzFramesDB.playerEliteFrameMode
                if mode > 3 and (alwaysHideLvl or (hideLvl and UnitLevel("player") == (BBF.isMidnight and 90 or 80))) then
                    -- Ensure level text is hidden when using UI-FocusFrame-Large
                    PlayerLevelText:SetParent(BBF.hiddenFrame)
                end
            else
                if alwaysHideLvl then
                    ToggleNoLevelFrame(true)
                elseif hideLvl then
                    if UnitLevel("player") == (BBF.isMidnight and 90 or 80) then
                        ToggleNoLevelFrame(true)
                    else
                        ToggleNoLevelFrame(false)
                    end
                else
                    ToggleNoLevelFrame(false)
                end
            end
            frame.noPortraitMode.Texture:SetTexCoord(0, 1, 0, 1)
            frame.noPortraitMode.Texture:ClearAllPoints()
            frame.noPortraitMode.Texture:SetPoint("TOPLEFT", 20, -38)
            frame.noPortraitMode.Texture:SetDrawLayer("BORDER")

            frameContainer.AlternatePowerFrameTexture:ClearAllPoints()
            frameContainer.AlternatePowerFrameTexture:SetPoint("TOPLEFT", -9, -8)
            frameContainer.AlternatePowerFrameTexture:SetAlpha(0)

            frameContainer.FrameFlash:SetParent((db.hideCombatGlow or db.noPortraitPixelBorder) and BBF.hiddenFrame or frame.noPortraitMode)
            frameContainer.FrameFlash:SetSize(255, 45)
            --frameContainer.FrameFlash:SetTexture(flashTex)
            --frameContainer.FrameFlash:SetTexCoord(0.9453125, 0, 0, 0.181640625)
            frameContainer.FrameFlash:ClearAllPoints()
            frameContainer.FrameFlash:SetAllPoints(frame.noPortraitMode.Texture)
            frameContainer.FrameFlash:SetDrawLayer("BORDER", 4)

            contentMain.StatusTexture:SetTexCoord(0, 1, 0, 1)
            contentMain.StatusTexture:ClearAllPoints()
            contentMain.StatusTexture:SetAllPoints(frame.noPortraitMode.Texture)
            contentMain.StatusTexture:SetParent((db.hidePlayerRestGlow or db.noPortraitPixelBorder) and BBF.hiddenFrame or frame.noPortraitMode)
            contentMain.StatusTexture:SetDrawLayer("BORDER", 4)
            contentMain.StatusTexture:SetBlendMode("ADD")

            BBF.UpdateNoPortraitText(frame, "player")

            frameContainer.PlayerPortrait:ClearAllPoints()
            frameContainer.PlayerPortrait:SetPoint("TOPLEFT", 26, -23)
            frame.noPortraitMode.Texture:Show()

            local altbar = PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:IsShown()
            if altbar then
                frame.noPortraitMode.Texture:SetTexture(playerAltTex)
                if not db.noPortraitPixelBorder then
                    local bgYOffset = GetPlayerBackgroundYOffset()
                    frame.noPortraitMode.Background:SetPoint("BOTTOMRIGHT", contentMain.HealthBarsContainer, "BOTTOMRIGHT", -1, bgYOffset)
                end
            else
                frame.noPortraitMode.Texture:SetTexture(playerDefaultTex)
                if not db.noPortraitPixelBorder then
                    local bgYOffset = GetPlayerBackgroundYOffset()
                    frame.noPortraitMode.Background:SetPoint("BOTTOMRIGHT", contentMain.HealthBarsContainer, "BOTTOMRIGHT", 0, bgYOffset)
                end
            end
            if not db.noPortraitPixelBorder then
                frame.noPortraitMode.Background:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", 0, 0)
            end
        end

        hooksecurefunc("PlayerFrame_ToPlayerArt", function()
            ToPlayerArt()
        end)
        ToPlayerArt()

        local function ToVehicleArt()
            frameContainer.VehicleFrameTexture:ClearAllPoints()
            frameContainer.VehicleFrameTexture:SetPoint("TOPLEFT", 23, -20)
            frameContainer.VehicleFrameTexture:SetAlpha(0)

            frame.noPortraitMode.bbfVehicleTexture:Show()

            frame.noPortraitMode.Texture:SetSize(247, 45)
            frame.noPortraitMode.Texture:SetTexture(playerDefaultTex)
            frame.noPortraitMode.Texture:ClearAllPoints()
            frame.noPortraitMode.Texture:SetPoint("TOPLEFT", 26.5, -39)
            frame.noPortraitMode.Texture:SetTexCoord(0, 1, 0, 1)

            hpContainer.HealthBarMask:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", -34, 5)
            hpContainer.HealthBarMask:SetSize(185, 34)

            --hpContainer.HealthBarMask:SetSize(120, 32)

            frameContainer.FrameFlash:SetParent(frame)
            frameContainer.FrameFlash:SetSize(255, 45)
            frameContainer.FrameFlash:SetTexture(playerFlashTex)
            frameContainer.FrameFlash:SetTexCoord(0, 1, 0, 1)
            frameContainer.FrameFlash:ClearAllPoints()
            frameContainer.FrameFlash:SetAllPoints(frame.noPortraitMode.Texture)
            frameContainer.FrameFlash:SetDrawLayer("BACKGROUND")

            contentContext.RoleIcon:ClearAllPoints()
            contentContext.RoleIcon:SetPoint("TOPLEFT", 81, -36)

            contentMain.StatusTexture:SetTexture(playerFlashTex)
            contentMain.StatusTexture:SetTexCoord(0, 1, 0, 1)
            contentMain.StatusTexture:ClearAllPoints()
            contentMain.StatusTexture:SetAllPoints(frame.noPortraitMode.Texture)
            contentMain.StatusTexture:SetDrawLayer("BACKGROUND")

            if not db.noPortraitPixelBorder then
                local bgYOffset = GetPlayerBackgroundYOffset()
                frame.noPortraitMode.Background:SetPoint("BOTTOMRIGHT", contentMain.HealthBarsContainer, "BOTTOMRIGHT", 2, bgYOffset)
            end

            -- hpContainer.LeftText:SetParent(frame.noPortraitMode)
            -- hpContainer.LeftText:ClearAllPoints()
            -- hpContainer.LeftText:SetPoint("LEFT", frame.noPortraitMode.Texture, "LEFT", 101, 3)
            -- hpContainer.RightText:SetParent(frame.noPortraitMode)
            -- hpContainer.RightText:ClearAllPoints()
            -- hpContainer.RightText:SetPoint("RIGHT", frame.noPortraitMode.Texture, "RIGHT", -38, 3)
            -- hpContainer.HealthBarText:SetParent(frame.noPortraitMode)
            -- hpContainer.HealthBarText:ClearAllPoints()
            -- hpContainer.HealthBarText:SetPoint("CENTER", frame.noPortraitMode.Texture, "CENTER", 34, 3)

            -- manaBar.LeftText:SetParent(frame.noPortraitMode)
            -- manaBar.LeftText:ClearAllPoints()
            -- manaBar.LeftText:SetPoint("LEFT", frame.noPortraitMode.Texture, "LEFT", 101, -9)
            -- manaBar.RightText:SetParent(frame.noPortraitMode)
            -- manaBar.RightText:ClearAllPoints()
            -- manaBar.RightText:SetPoint("RIGHT", frame.noPortraitMode.Texture, "RIGHT", -7, -9)
            -- manaBar.ManaBarText:SetParent(frame.noPortraitMode)
            -- manaBar.ManaBarText:ClearAllPoints()
            -- manaBar.ManaBarText:SetPoint("CENTER", frame.noPortraitMode.Texture, "CENTER", 52, -9)

            frameContainer.PlayerPortrait:ClearAllPoints()
            frameContainer.PlayerPortrait:SetPoint("TOPLEFT", 23, -17)
        end

        hooksecurefunc("PlayerFrame_ToVehicleArt", function(self)
            ToVehicleArt()
        end)

        hooksecurefunc(TotemFrame, "Update", function(self)
            for child in self.totemPool:EnumerateActive() do
                child.Border:SetSize(39, 39)
                child.Border:SetTexture("Interface\\CharacterFrame\\TotemBorder")
                child.Border:ClearAllPoints()
                child.Border:SetPoint("CENTER")
            end
        end)

        TotemFrame:SetScale(0.85)
        hooksecurefunc(TotemFrame, "SetPoint", function(self)
            if self.changing then return end
            if classFrame and classFrame:IsShown() then return end
            self.changing = true
            local a, b, c, d, e = self:GetPoint()
            self:ClearAllPoints()
            self:SetPoint(a, b, c, d, e - 5)
            self.changing = false
        end)

        if db.noPortraitModesDesaturated or db.classColorFrameTexture then
            frame.noPortraitMode.Texture:SetDesaturated(true)
        end

    elseif frame == PetFrame then
        PetFrame:SetSize(120, 49)
        PetPortrait:ClearAllPoints()
        PetPortrait:SetPoint("TOPLEFT", 7, -6)
        PetPortrait:SetAlpha(0)

        PetFrameTexture:SetSize(130, 33)
        PetFrameTexture:SetTexture(petDefaultTex)
        hooksecurefunc(PetFrameTexture, "SetTexture", function(self)
            if self.changing then return end
            self.changing = true
            self:SetTexture(petDefaultTex)
            self.changing = false
        end)
        PetFrameTexture:ClearAllPoints()
        PetFrameTexture:SetPoint("TOPLEFT", 3, -9)

        PetFrameFlash:SetSize(130, 33)
        PetFrameFlash:SetTexture(petDefaultTex)
        PetFrameFlash:SetPoint("TOPLEFT", 3, -9)
        PetFrameFlash:SetTexCoord(0, 1, 0, 1)
        PetFrameFlash:SetParent(frame.noPortraitMode)
        PetFrameFlash:SetDrawLayer("BORDER", 4)

        PetFrameHealthBar:SetSize(65, db.noPortraitPixelBorder and 14 or 16)
        PetFrameHealthBar:SetStatusBarColor(0, 1, 0)
        PetFrameHealthBar:ClearAllPoints()
        PetFrameHealthBar:SetPoint("TOPRIGHT", -19, -10)
        PetFrameHealthBar:SetFrameLevel(1)


        PetFrameManaBar:SetFrameLevel(1)
        PetFrame.Background = PetFrameHealthBar:CreateTexture(nil, "BACKGROUND")
        PetFrame.Background:SetColorTexture(0,0,0,0.45)
        PetFrame.Background:SetPoint("TOPLEFT", PetFrameHealthBar, "TOPLEFT", 1, -1)
        if db.hideUnitFramePlayerMana then
            PetFrame.Background:SetPoint("BOTTOMRIGHT", PetFrameHealthBar, "BOTTOMRIGHT", -1, 1)
        else
            PetFrame.Background:SetPoint("BOTTOMRIGHT", PetFrameManaBar, "BOTTOMRIGHT", -1, 1)
        end

        if db.noPortraitPixelBorder then
            PetFrameManaBar:SetSize(65, 5)
            PetFrameManaBar:ClearAllPoints()
            PetFrameManaBar:SetPoint("TOPRIGHT", -19, -27)
            SetBarMask(PetFrameHealthBar, PetFrameHealthBarMask, true)
            SetBarMask(PetFrameManaBar, PetFrameManaBarMask, true)
        else
            PetFrameManaBar:SetSize(67, 8)
            PetFrameManaBar:ClearAllPoints()
            PetFrameManaBar:SetPoint("TOPRIGHT", -20, -25)
            PetFrameHealthBarMask:SetTexture("interface/hud/uipartyframeportraitoffhealthmask")
            PetFrameHealthBarMask:SetSize(97, 22)
            SetXYPoint(PetFrameHealthBarMask, -17, 3)

            PetFrameManaBarMask:SetTexture("interface/hud/uipartyframeportraitoffmanamask")
            PetFrameManaBarMask:SetSize(96, 16)
            SetXYPoint(PetFrameManaBarMask, -13, 4)
        end

        -- Create text wrapper frame for proper layering above pixel borders
        if not PetFrame.BBFTextFrame then
            PetFrame.BBFTextFrame = CreateFrame("Frame", nil, PetFrame)
            PetFrame.BBFTextFrame:SetAllPoints(PetFrame)
        end

        PetFrameHealthBarText:SetParent(PetFrame.BBFTextFrame)
        PetFrameHealthBarTextLeft:SetParent(PetFrame.BBFTextFrame)
        PetFrameHealthBarTextRight:SetParent(PetFrame.BBFTextFrame)
        PetFrameManaBarText:SetParent(PetFrame.BBFTextFrame)
        PetFrameManaBarTextLeft:SetParent(PetFrame.BBFTextFrame)
        PetFrameManaBarTextRight:SetParent(PetFrame.BBFTextFrame)

        BBF.UpdateNoPortraitText(PetFrame, "pet")
        PetFrameOverAbsorbGlow:SetParent(PetFrame)
        PetFrameOverAbsorbGlow:SetDrawLayer("ARTWORK", 7)

        PetAttackModeTexture:SetParent(BBF.hiddenFrame)

        PetHitIndicator:ClearAllPoints()
        PetHitIndicator:SetPoint("CENTER", PetFrame, "TOPLEFT", 28, -27)
        PetHitIndicator:SetParent(BBF.hiddenFrame)

        if db.noPortraitPixelBorder then
            PetFrameTexture:SetAlpha(0)
            PetFrame.Background:SetAlpha(0)

            local cfg = BorderPositions.pet.health
            BlackBorder(PetFrameHealthBar, cfg.width, cfg.height, cfg.startX, cfg.startY)
            cfg = BorderPositions.pet.mana
            BlackBorder(PetFrameManaBar, cfg.width, cfg.height, cfg.startX, cfg.startY)

            if PetFrameHealthBar.pixelBorderBackground then
                PetFrameHealthBar.pixelBorderBackground:SetAlpha(1)
            end
            if PetFrameManaBar.pixelBorderBackground then
                PetFrameManaBar.pixelBorderBackground:SetAlpha(1)
            end

            if not PetFrameManaBar.BBFVisibilityHooked then
                PetFrameManaBar.BBFVisibilityHooked = true
                hooksecurefunc(PetFrameManaBar, "Hide", function()
                    if PetFrameManaBar.BBFPixelBorder then
                        PetFrameManaBar.BBFPixelBorder:Hide()
                    end
                    if PetFrameManaBar.pixelBorderBackground then
                        PetFrameManaBar.pixelBorderBackground:SetAlpha(0)
                    end
                end)
                hooksecurefunc(PetFrameManaBar, "Show", function()
                    if db.noPortraitPixelBorder and PetFrameManaBar.BBFPixelBorder then
                        PetFrameManaBar.BBFPixelBorder:Show()
                    end
                    if db.noPortraitPixelBorder and PetFrameManaBar.pixelBorderBackground then
                        PetFrameManaBar.pixelBorderBackground:SetAlpha(1)
                    end
                end)
            end

            local maxBorderLevel = 0
            if PetFrameHealthBar.BBFPixelBorder then
                maxBorderLevel = math.max(maxBorderLevel, PetFrameHealthBar.BBFPixelBorder:GetFrameLevel())
            end
            if PetFrameManaBar.BBFPixelBorder then
                maxBorderLevel = math.max(maxBorderLevel, PetFrameManaBar.BBFPixelBorder:GetFrameLevel())
            end
            if PetFrame.BBFTextFrame and maxBorderLevel > 0 then
                PetFrame.BBFTextFrame:SetFrameLevel(maxBorderLevel + 1)
            end
        else
            PetFrameTexture:SetAlpha(1)
            PetFrame.Background:SetAlpha(1)

            if PetFrameHealthBar.pixelBorderBackground then
                PetFrameHealthBar.pixelBorderBackground:SetAlpha(0)
            end
            if PetFrameManaBar.pixelBorderBackground then
                PetFrameManaBar.pixelBorderBackground:SetAlpha(0)
            end
        end

        if db.noPortraitModesDesaturated then
            PetFrameTexture:SetDesaturated(true)
        end
    end
end

local fancyManas = {
    ["INSANITY"] = true,
    ["MAELSTROM"] = true,
    ["FURY"] = true,
    ["LUNAR_POWER"] = true,
    ["SOUL_FRAGMENTS"] = true, -- alt mana, powerName (as opposed to powerType)
}

local function AdjustAlternateBars()
    local db = BetterBlizzFramesDB
    local function SetupAltStyleBar(bar, centerText, leftText, rightText)
        if not bar then return end

        -- Check if only mana is hidden but not the alt bar itself
        local shouldMoveUp = db.hideUnitFramePlayerMana and not db.hideUnitFramePlayerSecondResource
        local yOffset = shouldMoveUp and 11 or 0

        if db.noPortraitPixelBorder then
            BBF.RunAfterCombat(function()
                bar:SetSize(124, 10)
                bar:ClearAllPoints()
                bar:SetPoint("BOTTOMLEFT", 85, 16 + yOffset)
            end)

            local cfg = BorderPositions.player.alt
            BlackBorder(bar, cfg.width, cfg.height, cfg.startX, cfg.startY)

            if bar.PowerBarMask then
                bar.PowerBarMask:SetTexture("interface\\masks\\squaremask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                bar.PowerBarMask:SetTexCoord(0.05, 0.95, 0.01, 0.99)
                bar.PowerBarMask:ClearAllPoints()
                if bar.BBFPositionFrame then
                    bar.PowerBarMask:SetAllPoints(bar.BBFPositionFrame)
                end
            end
        else
            BBF.RunAfterCombat(function()
                bar:SetSize(126, 9)
                bar:ClearAllPoints()
                bar:SetPoint("BOTTOMLEFT", 86, 19.2 + yOffset)
            end)

            if bar.PowerBarMask then
                bar.PowerBarMask:ClearAllPoints()
                bar.PowerBarMask:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 3)
            end
        end

        if not bar.s then
            bar.s = CreateFrame("Frame", nil, bar)
            bar.s:SetFrameStrata("HIGH")
            bar.s:SetAllPoints(bar)
        end

        -- Set frame level above pixel borders if they exist
        if db.noPortraitPixelBorder and bar.BBFPixelBorder then
            bar.s:SetFrameLevel(bar.BBFPixelBorder:GetFrameLevel() + 1)
        else
            bar.s:SetFrameLevel(bar:GetFrameLevel() + 10)
        end

        if centerText then
            centerText:SetParent(bar.s)
            centerText:ClearAllPoints()
            centerText:SetPoint("CENTER", bar.s, "CENTER", 0, -0.5)
            centerText:Show()
        end

        if leftText then
            leftText:SetParent(bar.s)
            leftText:ClearAllPoints()
            leftText:SetPoint("LEFT", bar.s, "LEFT", 0, -0.5)
            leftText:Show()
        end

        if rightText then
            rightText:SetParent(bar.s)
            rightText:ClearAllPoints()
            rightText:SetPoint("RIGHT", bar.s, "RIGHT", -4, -0.5)
            rightText:Show()
        end

        if BetterBlizzFramesDB.changeUnitFrameManabarTexture then
            if not bar.bbfAltHooked then
                bar.bbfAltHooked = true
                local color = PowerBarColor[bar.powerType]
                if not color then
                    color = bar.powerName == ("SOUL_FRAGMENTS" and { r = 0.11, g = 0.34, b = 0.71 }) or
                    PowerBarColor["MANA"]
                end

                bar.keepFancyManas = BetterBlizzFramesDB.changeUnitFrameManaBarTextureKeepFancy
                bar.bbfPowerToken = bar.powerToken or bar.powerName

                local r, g, b = color.r, color.g, color.b

                if bar.powerName == "SOUL_FRAGMENTS" then
                    hooksecurefunc(bar, "EvaluateUnit", function(self)
                        if bar.keepFancyManas and fancyManas[bar.bbfPowerToken] then return end
                        if self.inVoidMetamorphosis then
                            r, g, b = 0.35, 0.25, 0.73
                        else
                            r, g, b = 0.11, 0.34, 0.71
                        end

                        -- Check for custom power colors if enabled
                        if BetterBlizzFramesDB.customHealthbarColors and BetterBlizzFramesDB.customPowerColors and BetterBlizzFramesDB.customColorsUnitFrames then
                            local powerToken = self.powerToken or self.powerName
                            if powerToken and BBF.GetCustomPowerColor then
                                local customR, customG, customB = BBF.GetCustomPowerColor(powerToken)
                                if customR then
                                    r, g, b = customR, customG, customB
                                end
                            end
                        end

                        self:SetStatusBarTexture(BBF.manaTexture)
                        self:SetStatusBarColor(r, g, b)
                    end)
                else
                    hooksecurefunc(bar, "EvaluateUnit", function(self)
                        if bar.keepFancyManas and fancyManas[bar.bbfPowerToken] then return end

                        -- Check for custom power colors if enabled
                        if BetterBlizzFramesDB.customHealthbarColors and BetterBlizzFramesDB.customPowerColors and BetterBlizzFramesDB.customColorsUnitFrames then
                            local powerToken = self.powerToken or self.powerName
                            if powerToken and BBF.GetCustomPowerColor then
                                local customR, customG, customB = BBF.GetCustomPowerColor(powerToken)
                                if customR then
                                    r, g, b = customR, customG, customB
                                end
                            end
                        end

                        self:SetStatusBarTexture(BBF.manaTexture)
                        self:SetStatusBarColor(r, g, b)
                    end)
                end
            end
        end
    end

    SetupAltStyleBar(
        AlternatePowerBar,
        AlternatePowerBarText,
        AlternatePowerBar.LeftText,
        AlternatePowerBar.RightText
    )

    if class == "MONK" then
        SetupAltStyleBar(
            MonkStaggerBar,
            MonkStaggerBarText,
            MonkStaggerBar.LeftText,
            MonkStaggerBar.RightText
        )
    end

    if class == "EVOKER" then
        SetupAltStyleBar(
            EvokerEbonMightBar,
            EvokerEbonMightBarText,
            EvokerEbonMightBar.LeftText,
            EvokerEbonMightBar.RightText
        )
    end

    if class == "DEMONHUNTER" and DemonHunterSoulFragmentsBar then
        SetupAltStyleBar(
            DemonHunterSoulFragmentsBar,
            DemonHunterSoulFragmentsBar.TextString,
            DemonHunterSoulFragmentsBar.LeftText,
            DemonHunterSoulFragmentsBar.RightText
        )
    end

    local noPortraitModeColorTargets = {
        AlternatePowerBar.Border,
        AlternatePowerBar.LeftBorder,
        AlternatePowerBar.RightBorder,
    }

    local function GetFrameColor()
        local r, g, b = PlayerFrame.PlayerFrameContainer.FrameTexture:GetVertexColor()
        for _, frame in pairs(noPortraitModeColorTargets) do
            if frame then
                frame:SetVertexColor(r, g, b)
            end
        end
    end

    GetFrameColor()
    hooksecurefunc(PlayerFrame.PlayerFrameContainer.FrameTexture, "SetVertexColor", GetFrameColor)
end

local function MakeClassicPartyFrame()
    for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
        local overlay = frame.PartyMemberOverlay
        local hpContainer = frame.HealthBarContainer
        local manaBar = frame.ManaBar
        local auras = frame.AuraFrameContainer

        overlay:SetFrameStrata("MEDIUM")
        overlay:SetFrameLevel(750)
        frame.Texture:SetSize(152, 34)
        frame.Texture:SetTexture(partyDefaultTex)
        frame.Texture:SetTexCoord(0, 1, 0, 1)
        frame.Texture:ClearAllPoints()
        frame.Texture:SetPoint("TOPLEFT", 4, -11)
        frame.Texture:SetDrawLayer("ARTWORK", 7)
        frame.Texture:SetParent(hpContainer)

        frame.Portrait:SetAlpha(0)
        frame.Portrait:SetParent(BBF.hiddenFrame)

        frame.Flash:SetSize(152, 34)
        frame.Flash:SetTexture(partyDefaultTex)
        frame.Flash:SetTexCoord(0, 1, 0, 1)
        frame.Flash:ClearAllPoints()
        frame.Flash:SetAllPoints(frame.Texture)

        overlay.Status:SetTexture(partyDefaultTex)
        overlay.Status:SetTexCoord(0, 1, 0, 1)
        overlay.Status:ClearAllPoints()
        overlay.Status:SetAllPoints(frame.Texture)
        overlay.Status:SetDrawLayer("BORDER", 4)
        overlay.Disconnect:SetSize(25, 25)
        overlay.Disconnect:ClearAllPoints()
        overlay.Disconnect:SetPoint("LEFT", overlay, "LEFT", 32, 13)


        overlay.LeaderIcon:SetSize(14,14)
        --AdjustFramePoint(overlay.LeaderIcon, nil, -6)
        overlay.LeaderIcon:ClearAllPoints()
        overlay.LeaderIcon:SetPoint("BOTTOM", overlay, "TOP", -12.5, -13)
        overlay.GuideIcon:ClearAllPoints()
        overlay.GuideIcon:SetPoint("BOTTOM", overlay, "TOP", -12.5, -13)
        overlay.RoleIcon:SetSize(9, 9)
        overlay.RoleIcon:ClearAllPoints()
        overlay.RoleIcon:SetPoint("BOTTOMLEFT", 38.5, 35.5)
        overlay.PVPIcon:SetParent(BBF.hiddenFrame)

        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetColorTexture(0,0,0,0.45)
        frame.Background:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", 0, 0)
        frame.Background:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", 0, 0)
        frame.BgMask = frame:CreateMaskTexture()
        frame.BgMask:SetAllPoints(frame.Background)
        frame.BgMask:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\frameMask.tga", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frame.Background:AddMaskTexture(frame.BgMask)



        frame.bbfName:ClearAllPoints()
        frame.bbfName:SetPoint("BOTTOM", frame.Texture, "TOP", 0, 0)
        frame.bbfName:SetWidth(76)
        frame.bbfName:SetScale(0.85)
        frame.bbfName:SetJustifyH("CENTER")

        -- Create text wrapper frame for proper layering above pixel borders
        if not frame.BBFTextFrame then
            frame.BBFTextFrame = CreateFrame("Frame", nil, frame)
            frame.BBFTextFrame:SetAllPoints(frame)
            frame.BBFTextFrame:SetFrameStrata("MEDIUM")
            frame.BBFTextFrame:SetFrameLevel(600)
        end

        hpContainer.LeftText:SetParent(frame.BBFTextFrame)
        hpContainer.LeftText:SetScale(0.72)
        hpContainer.RightText:SetParent(frame.BBFTextFrame)
        hpContainer.RightText:SetScale(0.72)
        hpContainer.CenterText:SetParent(frame.BBFTextFrame)
        hpContainer.CenterText:SetScale(0.72)
        manaBar.TextString:SetParent(frame.BBFTextFrame)
        manaBar.TextString:SetScale(0.72)
        manaBar.LeftText:SetParent(frame.BBFTextFrame)
        manaBar.LeftText:SetScale(0.72)
        manaBar.RightText:SetParent(frame.BBFTextFrame)
        manaBar.RightText:SetScale(0.72)


        local db = BetterBlizzFramesDB
        if db.noPortraitPixelBorder then
            frame.Texture:SetAlpha(0)
            frame.Background:SetAlpha(0)

            local cfg = BorderPositions.party.health
            BlackBorder(hpContainer.HealthBar, cfg.width, cfg.height, cfg.startX, cfg.startY)
            cfg = BorderPositions.party.mana
            BlackBorder(manaBar, cfg.width, cfg.height, cfg.startX, cfg.startY)

            if hpContainer.HealthBar.pixelBorderBackground then
                hpContainer.HealthBar.pixelBorderBackground:SetAlpha(1)
            end
            if manaBar.pixelBorderBackground then
                manaBar.pixelBorderBackground:SetAlpha(1)
            end

            overlay.Status:SetParent(BBF.hiddenFrame)
            frame.Flash:SetParent(BBF.hiddenFrame)
            -- local function ColorBorder(bar, r, g, b, a)
            --     if not bar or not bar.BBFBlackBorder then return end
            --     for _, edge in ipairs(bar.BBFBlackBorder) do
            --         edge:SetColorTexture(r, g, b, a or 1)
            --     end
            -- end
            -- hooksecurefunc(overlay.Status, "SetVertexColor", function(_, r, g, b, a)
            --     if not (r and g and b) then
            --         return
            --     end

            --     if r == g and g == b then
            --         r, g, b = 0, 0, 0
            --     end

            --     ColorBorder(hpContainer.HealthBar, r, g, b, a)
            --     ColorBorder(manaBar, r, g, b, a)
            -- end)

            if not manaBar.BBFVisibilityHooked then
                manaBar.BBFVisibilityHooked = true
                hooksecurefunc(manaBar, "Hide", function()
                    if manaBar.BBFPixelBorder then
                        manaBar.BBFPixelBorder:Hide()
                    end
                    if manaBar.pixelBorderBackground then
                        manaBar.pixelBorderBackground:SetAlpha(0)
                    end
                end)
                hooksecurefunc(manaBar, "Show", function()
                    if db.noPortraitPixelBorder and manaBar.BBFPixelBorder then
                        manaBar.BBFPixelBorder:Show()
                    end
                    if db.noPortraitPixelBorder and manaBar.pixelBorderBackground then
                        manaBar.pixelBorderBackground:SetAlpha(1)
                    end
                end)
            end

            local maxBorderLevel = 0
            if hpContainer.HealthBar.BBFPixelBorder then
                maxBorderLevel = math.max(maxBorderLevel, hpContainer.HealthBar.BBFPixelBorder:GetFrameLevel())
            end
            if manaBar.BBFPixelBorder then
                maxBorderLevel = math.max(maxBorderLevel, manaBar.BBFPixelBorder:GetFrameLevel())
            end
            if frame.BBFTextFrame and maxBorderLevel > 0 then
                frame.BBFTextFrame:SetFrameLevel(maxBorderLevel + 1)
            end
        else
            frame.Texture:SetAlpha(1)
            frame.Background:SetAlpha(1)

            if hpContainer.HealthBar.pixelBorderBackground then
                hpContainer.HealthBar.pixelBorderBackground:SetAlpha(0)
            end
            if manaBar.pixelBorderBackground then
                manaBar.pixelBorderBackground:SetAlpha(0)
            end
        end

        local function hbAdjust()
            frame.bbfName:SetWidth(76)
            local needsCombatUpdate = false

            if db.noPortraitPixelBorder then
                SetBarMask(hpContainer.HealthBar, hpContainer.HealthBarMask, true)
                SetBarMask(manaBar, manaBar.ManaBarMask, true)

                if not InCombatLockdown() then
                    hpContainer.HealthBar:ClearAllPoints()
                    hpContainer.HealthBar:SetPoint("TOPLEFT", hpContainer, "TOPLEFT", -2, 6)
                    hpContainer.HealthBar:SetSize(76, 18)
                    manaBar:ClearAllPoints()
                    manaBar:SetPoint("TOPLEFT", hpContainer, "TOPLEFT", -2, -13)
                    manaBar:SetSize(76, 5)
                else
                    needsCombatUpdate = true
                end

                auras:ClearAllPoints()
                auras:SetScale(1.1)
                auras:SetPoint("TOPLEFT", manaBar, "BOTTOMLEFT", 0, -3)

            else
                if not InCombatLockdown() then
                    hpContainer.HealthBar:ClearAllPoints()
                    hpContainer.HealthBar:SetPoint("TOPLEFT", hpContainer, "TOPLEFT", -2, 8)
                    hpContainer.HealthBar:SetSize(76, 18)
                    manaBar:ClearAllPoints()
                    manaBar:SetPoint("TOPLEFT", hpContainer, "TOPLEFT", -5, -8)
                    manaBar:SetSize(78, 9)
                else
                    needsCombatUpdate = true
                end

                hpContainer.HealthBarMask:SetSize(134, 24)
                hpContainer.HealthBarMask:ClearAllPoints()
                hpContainer.HealthBarMask:SetPoint("TOPLEFT", hpContainer, "TOPLEFT", -31.5, 11)

                manaBar.ManaBarMask:SetTexture("interface/hud/uipartyframeportraitoffmanamask")
                manaBar.ManaBarMask:SetSize(114, 16)
                manaBar.ManaBarMask:ClearAllPoints()
                manaBar.ManaBarMask:SetPoint("TOPLEFT", frame, "TOPLEFT", 23, -24)
            end

            overlay.LeaderIcon:ClearAllPoints()
            overlay.LeaderIcon:SetPoint("BOTTOM", overlay, "TOP", -12.5, -13)
            overlay.GuideIcon:ClearAllPoints()
            overlay.GuideIcon:SetPoint("BOTTOM", overlay, "TOP", -12.5, -13)
            overlay.RoleIcon:ClearAllPoints()
            overlay.RoleIcon:SetPoint("BOTTOMLEFT", 38.5, 35.5)

            BBF.UpdateNoPortraitText(nil, "party")

            if needsCombatUpdate then
                if not frame.bbfPartyCombatUpdate:IsEventRegistered("PLAYER_REGEN_ENABLED") then
                    frame.bbfPartyCombatUpdate:RegisterEvent("PLAYER_REGEN_ENABLED")
                end
            end
        end

        if not frame.bbfPartyCombatUpdate then
            frame.bbfPartyCombatUpdate = CreateFrame("Frame")
            frame.bbfPartyCombatUpdate:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                --hbAdjust()
            end)
        end

        hbAdjust()


        hooksecurefunc(frame, "ToPlayerArt", function(self)
            self.Texture:SetTexture(partyDefaultTex)

            hbAdjust()


            --AdjustFramePoint(frame.HealthBarContainer.HealthBarMask, nil, -3)
            --hpContainer.HealthBarMask:SetPoint("TOPLEFT", frame.HealthBarContainer.HealthBar, "TOPLEFT", -29, 0)

            BBF.UpdateNoPortraitText(nil, "party")

            frame.Flash:SetTexture(partyDefaultTex)
            frame.Flash:SetTexCoord(0, 1, 0, 1)
            frame.Flash:ClearAllPoints()
            frame.Flash:SetAllPoints(frame.Texture)

            overlay.Status:SetTexture(partyDefaultTex)
            overlay.Status:SetTexCoord(0, 1, 0, 1)
            overlay.Status:ClearAllPoints()
            overlay.Status:SetAllPoints(frame.Texture)
        end)
    end

    -- Ty Verz for this bit
    for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
        -- store frame references for the restricted environment to retrieve later on
        SecureHandlerSetFrameRef(frame, "HealthBarContainer", frame.HealthBarContainer)
        SecureHandlerSetFrameRef(frame, "HealthBar", frame.HealthBarContainer.HealthBar)
        SecureHandlerSetFrameRef(frame, "ManaBar", frame.ManaBar)

        -- we are extremely lucky in that ToPlayerArt() calls UnitFrame_SetUnit() which calls :SetAttribute()
        -- so we can hook OnAttributeChanged in the restricted environment and make our changes there
        -- this allows us to run code during combat

        if BetterBlizzFramesDB.noPortraitPixelBorder then
            SecureHandlerWrapScript(frame, "OnAttributeChanged", frame, [[
                local hpContainer = self:GetFrameRef("HealthBarContainer")
                local healthBar = self:GetFrameRef("HealthBar") 
                local manaBar = self:GetFrameRef("ManaBar") 

                healthBar:ClearAllPoints()
                healthBar:SetPoint("TOPLEFT", hpContainer, "TOPLEFT", -2, 6)
                healthBar:SetPoint("BOTTOMRIGHT", hpContainer, "TOPLEFT", 74, -10)
                healthBar:SetWidth(76)
                healthBar:SetHeight(18)

                manaBar:ClearAllPoints()
                manaBar:SetPoint("TOPLEFT", hpContainer, "TOPLEFT", -2, -13)
                manaBar:SetWidth(76)
                manaBar:SetHeight(5)
            ]])
        else
            SecureHandlerWrapScript(frame, "OnAttributeChanged", frame, [[
                local hpContainer = self:GetFrameRef("HealthBarContainer")
                local healthBar = self:GetFrameRef("HealthBar") 
                local manaBar = self:GetFrameRef("ManaBar") 

                healthBar:ClearAllPoints()
                healthBar:SetPoint("TOPLEFT", hpContainer, "TOPLEFT", -2, 8)
                healthBar:SetPoint("BOTTOMRIGHT", hpContainer, "TOPLEFT", 74, -10)
                healthBar:SetWidth(76)
                healthBar:SetHeight(18)

                manaBar:ClearAllPoints()
                manaBar:SetPoint("TOPLEFT", hpContainer, "TOPLEFT", -5, -8)
                manaBar:SetWidth(78)
                manaBar:SetHeight(9)
            ]])
        end
    end
end


function BBF.UpdateNoPortraitManaVisibility()
    local db = BetterBlizzFramesDB
    if db.classicFrames then
        if db.hideUnitFramePlayerSecondResource then
            if AlternatePowerBar then
                AlternatePowerBar:SetAlpha(0)
            end
            if MonkStaggerBar then
                MonkStaggerBar:SetAlpha(0)
            end
            if EvokerEbonMightBar then
                EvokerEbonMightBar:SetAlpha(0)
            end
            if DemonHunterSoulFragmentsBar then
                DemonHunterSoulFragmentsBar:SetAlpha(0)
            end
            BBF.changedSecondResourceAlpha = true
        else
            if BBF.changedSecondResourceAlpha then
                if AlternatePowerBar then
                    AlternatePowerBar:SetAlpha(1)
                end
                if MonkStaggerBar then
                    MonkStaggerBar:SetAlpha(1)
                end
                if EvokerEbonMightBar then
                    EvokerEbonMightBar:SetAlpha(1)
                end
                if DemonHunterSoulFragmentsBar then
                    DemonHunterSoulFragmentsBar:SetAlpha(1)
                end
            end
            BBF.changedSecondResourceAlpha = nil
        end
        return
    end
    if not db.noPortraitModes then return end
    UpdateTextureVariables()

    -- Hide PlayerFrame Mana
    if db.hideUnitFramePlayerMana then
        local manaBarArea = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea
        local petMana = PetFrameManaBar
        if manaBarArea then
            manaBarArea:SetAlpha(0)
        end
        if petMana then
            petMana:SetAlpha(0)
            petMana.TextString:SetAlpha(0)
            petMana.LeftText:SetAlpha(0)
            petMana.RightText:SetAlpha(0)
        end
        if not db.noPortraitPixelBorder and PetFrameTexture then
            PetFrameTexture:SetTexture(petDefaultTex)
            PetFrameFlash:SetTexture(petDefaultTex)
        end
        if PetFrame.Background then
            PetFrame.Background:ClearAllPoints()
            PetFrame.Background:SetPoint("TOPLEFT", PetFrameHealthBar, "TOPLEFT", 1, -1)
            PetFrame.Background:SetPoint("BOTTOMRIGHT", PetFrameHealthBar, "BOTTOMRIGHT", -1, 1)
        end
    else
        local manaBarArea = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea
        local petMana = PetFrameManaBar
        if manaBarArea then
            manaBarArea:SetAlpha(1)
        end
        if petMana then
            petMana:SetAlpha(1)
            if not db.hidePetText then
                petMana.TextString:SetAlpha(1)
                petMana.LeftText:SetAlpha(1)
                petMana.RightText:SetAlpha(1)
            end
        end
        if not db.noPortraitPixelBorder and PetFrameTexture then
            PetFrameTexture:SetTexture(petDefaultTex)
            PetFrameFlash:SetTexture(petDefaultTex)
        end
        if PetFrame.Background then
            PetFrame.Background:ClearAllPoints()
            PetFrame.Background:SetPoint("TOPLEFT", PetFrameHealthBar, "TOPLEFT", 1, -1)
            PetFrame.Background:SetPoint("BOTTOMRIGHT", PetFrameManaBar, "BOTTOMRIGHT", -1, 1)
        end
    end

    -- Hide PlayerFrame Second Resource (AlternatePowerBar)
    if db.hideUnitFramePlayerSecondResource then
        if AlternatePowerBar then
            AlternatePowerBar:SetAlpha(0)
            if AlternatePowerBar.BBFPixelBorder then
                AlternatePowerBar.BBFPixelBorder:Hide()
            end
            if AlternatePowerBar.pixelBorderBackground then
                AlternatePowerBar.pixelBorderBackground:SetAlpha(0)
            end
        end
        if MonkStaggerBar then
            MonkStaggerBar:SetAlpha(0)
            if MonkStaggerBar.BBFPixelBorder then
                MonkStaggerBar.BBFPixelBorder:Hide()
            end
            if MonkStaggerBar.pixelBorderBackground then
                MonkStaggerBar.pixelBorderBackground:SetAlpha(0)
            end
        end
        if EvokerEbonMightBar then
            EvokerEbonMightBar:SetAlpha(0)
            if EvokerEbonMightBar.BBFPixelBorder then
                EvokerEbonMightBar.BBFPixelBorder:Hide()
            end
            if EvokerEbonMightBar.pixelBorderBackground then
                EvokerEbonMightBar.pixelBorderBackground:SetAlpha(0)
            end
        end
        if DemonHunterSoulFragmentsBar then
            DemonHunterSoulFragmentsBar:SetAlpha(0)
            if DemonHunterSoulFragmentsBar.BBFPixelBorder then
                DemonHunterSoulFragmentsBar.BBFPixelBorder:Hide()
            end
            if DemonHunterSoulFragmentsBar.pixelBorderBackground then
                DemonHunterSoulFragmentsBar.pixelBorderBackground:SetAlpha(0)
            end
        end
    else
        if AlternatePowerBar then
            AlternatePowerBar:SetAlpha(1)
            if AlternatePowerBar.BBFPixelBorder then
                AlternatePowerBar.BBFPixelBorder:Show()
            end
            if AlternatePowerBar.pixelBorderBackground then
                AlternatePowerBar.pixelBorderBackground:SetAlpha(1)
            end
        end
        if MonkStaggerBar then
            MonkStaggerBar:SetAlpha(1)
            if MonkStaggerBar.BBFPixelBorder then
                MonkStaggerBar.BBFPixelBorder:Show()
            end
            if MonkStaggerBar.pixelBorderBackground then
                MonkStaggerBar.pixelBorderBackground:SetAlpha(1)
            end
        end
        if EvokerEbonMightBar then
            EvokerEbonMightBar:SetAlpha(1)
            if EvokerEbonMightBar.BBFPixelBorder then
                EvokerEbonMightBar.BBFPixelBorder:Show()
            end
            if EvokerEbonMightBar.pixelBorderBackground then
                EvokerEbonMightBar.pixelBorderBackground:SetAlpha(1)
            end
        end
        if DemonHunterSoulFragmentsBar then
            DemonHunterSoulFragmentsBar:SetAlpha(1)
            if DemonHunterSoulFragmentsBar.BBFPixelBorder then
                DemonHunterSoulFragmentsBar.BBFPixelBorder:Show()
            end
            if DemonHunterSoulFragmentsBar.pixelBorderBackground then
                DemonHunterSoulFragmentsBar.pixelBorderBackground:SetAlpha(1)
            end
        end
    end

    -- Hide TargetFrame Mana
    if db.hideUnitFrameTargetMana and TargetFrame and TargetFrame.TargetFrameContent then
        local manaBar = TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar
        if manaBar then
            manaBar:SetAlpha(0)
        end
        if TargetFrame.totFrame and TargetFrame.totFrame.ManaBar then
            TargetFrame.totFrame.ManaBar:SetAlpha(0)
        end
    elseif TargetFrame and TargetFrame.TargetFrameContent then
        local manaBar = TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar
        if manaBar then
            manaBar:SetAlpha(1)
        end
        if TargetFrame.totFrame and TargetFrame.totFrame.ManaBar then
            TargetFrame.totFrame.ManaBar:SetAlpha(1)
        end
    end

    -- Hide FocusFrame Mana
    if db.hideUnitFrameFocusMana then
        local manaBar = FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar
        if manaBar then
            manaBar:SetAlpha(0)
        end
        if FocusFrame.totFrame and FocusFrame.totFrame.ManaBar then
            FocusFrame.totFrame.ManaBar:SetAlpha(0)
        end
    else
        local manaBar = FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar
        if manaBar then
            manaBar:SetAlpha(1)
        end
        if FocusFrame.totFrame and FocusFrame.totFrame.ManaBar then
            FocusFrame.totFrame.ManaBar:SetAlpha(1)
        end
    end

    -- PlayerFrame
    if PlayerFrame.noPortraitMode and PlayerFrame.noPortraitMode.Texture then
        local altbar = PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:IsShown()
        local contentMain = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
        if altbar then
            PlayerFrame.noPortraitMode.Texture:SetTexture(playerAltTex)
            local bgYOffset = GetPlayerBackgroundYOffset()
            PlayerFrame.noPortraitMode.Background:SetPoint("BOTTOMRIGHT", contentMain.HealthBarsContainer, "BOTTOMRIGHT", -1, bgYOffset)
        else
            PlayerFrame.noPortraitMode.Texture:SetTexture(playerDefaultTex)
            local bgYOffset = GetPlayerBackgroundYOffset()
            PlayerFrame.noPortraitMode.Background:SetPoint("BOTTOMRIGHT", contentMain.HealthBarsContainer, "BOTTOMRIGHT", 0, bgYOffset)
        end
    end

    -- TargetFrame
    if TargetFrame.noPortraitMode and TargetFrame.noPortraitMode.Texture then
        local classification = UnitClassification("target")
        local hideMana = db.hideUnitFrameTargetMana
        local textureToUse, bgYOffset

        if hideMana or classification == "minus" then
            textureToUse = minusTex
            bgYOffset = 11
        else
            textureToUse = targetDefaultTex
            bgYOffset = 0
        end

        TargetFrame.noPortraitMode.Texture:SetTexture(textureToUse)
        local contentMain = TargetFrame.TargetFrameContent.TargetFrameContentMain
        TargetFrame.noPortraitMode.Background:SetPoint("BOTTOMRIGHT", contentMain.ManaBar, "BOTTOMRIGHT", -10, bgYOffset)
    end
    if TargetFrame.totFrame and TargetFrame.totFrame.FrameTexture then
        TargetFrame.totFrame.FrameTexture:SetTexture(targetDefaultTex)
    end

    -- FocusFrame
    if FocusFrame.noPortraitMode and FocusFrame.noPortraitMode.Texture then
        local classification = UnitClassification("focus")
        local hideMana = db.hideUnitFrameFocusMana
        local textureToUse, bgYOffset

        if hideMana or classification == "minus" then
            textureToUse = minusTex
            bgYOffset = 11
        else
            textureToUse = focusDefaultTex
            bgYOffset = 0
        end

        FocusFrame.noPortraitMode.Texture:SetTexture(textureToUse)
        local contentMain = FocusFrame.TargetFrameContent.TargetFrameContentMain
        FocusFrame.noPortraitMode.Background:SetPoint("BOTTOMRIGHT", contentMain.ManaBar, "BOTTOMRIGHT", -10, bgYOffset)
    end
    if FocusFrame.totFrame and FocusFrame.totFrame.FrameTexture then
        FocusFrame.totFrame.FrameTexture:SetTexture(focusDefaultTex)
    end

    -- PartyFrames
    if PartyFrame and PartyFrame.PartyMemberFramePool then
        for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            local manaBar = frame.ManaBar
            if manaBar then
                if db.hideDefaultPartyFramesMana then
                    manaBar:SetAlpha(0)
                    if manaBar.TextString then
                        manaBar.TextString:SetAlpha(0)
                    end
                    if manaBar.LeftText then
                        manaBar.LeftText:SetAlpha(0)
                    end
                    if manaBar.RightText then
                        manaBar.RightText:SetAlpha(0)
                    end
                    if manaBar.BBFPixelBorder then
                        manaBar.BBFPixelBorder:Hide()
                    end
                    if manaBar.pixelBorderBackground then
                        manaBar.pixelBorderBackground:SetAlpha(0)
                    end
                    if frame.Background then
                        frame.Background:ClearAllPoints()
                        frame.Background:SetPoint("TOPLEFT", frame.HealthBarContainer.HealthBar, "TOPLEFT", 0, -1)
                        frame.Background:SetPoint("BOTTOMRIGHT", frame.HealthBarContainer.HealthBar, "BOTTOMRIGHT", -2, 1)
                    end
                else
                    manaBar:SetAlpha(1)
                    if manaBar.TextString then
                        manaBar.TextString:SetAlpha(1)
                    end
                    if manaBar.LeftText then
                        manaBar.LeftText:SetAlpha(1)
                    end
                    if manaBar.RightText then
                        manaBar.RightText:SetAlpha(1)
                    end
                    if db.noPortraitPixelBorder and manaBar.BBFPixelBorder then
                        manaBar.BBFPixelBorder:Show()
                    end
                    if db.noPortraitPixelBorder and manaBar.pixelBorderBackground then
                        manaBar.pixelBorderBackground:SetAlpha(1)
                    end
                    if frame.Background then
                        frame.Background:ClearAllPoints()
                        frame.Background:SetPoint("TOPLEFT", frame.HealthBarContainer.HealthBar, "TOPLEFT", 0, -1)
                        frame.Background:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", -2, 1)
                    end
                end
                if not db.noPortraitPixelBorder then
                    if frame.Texture then
                        frame.Texture:SetTexture(partyDefaultTex)
                    end
                    if frame.Flash then
                        frame.Flash:SetTexture(partyDefaultTex)
                    end
                    if frame.PartyMemberOverlay and frame.PartyMemberOverlay.Status then
                        frame.PartyMemberOverlay.Status:SetTexture(partyDefaultTex)
                    end
                end
            end
        end
    end

    AdjustAlternateBars()
    BBF.UpdateResourcePositionNoPortrait()
end

function BBF.noPortraitModes()
    if not BetterBlizzFramesDB.noPortraitModes and not BetterBlizzFramesDB.noPortraitPixelBorder then return end
    UpdateTextureVariables()
    if not BetterBlizzFramesDB.noPortraitSkipTarget then
        MakeNoPortraitMode(TargetFrame)
    end
    if not BetterBlizzFramesDB.noPortraitSkipFocus then
        MakeNoPortraitMode(FocusFrame)
    end
    if not BetterBlizzFramesDB.noPortraitSkipPlayer then
        MakeNoPortraitMode(PlayerFrame)
    end
    if not BetterBlizzFramesDB.noPortraitSkipPet then
        MakeNoPortraitMode(PetFrame)
    end

    MakeClassicPartyFrame()

    AdjustAlternateBars()

    C_Timer.After(0.5,function()
        for _, child in ipairs({ PlayerFrame.PlayerFrameContent.PlayerFrameContentMain:GetRegions() }) do
            if child:IsObjectType("Texture") then
                local atlas = child:GetAtlas()
                if atlas == "UI-HUD-UnitFrame-Target-PortraitOn-Type" then
                    child:SetParent(BBF.hiddenFrame)
                end
            end
        end
    end)

    PlayerFrame:SetHitRectInsets(66, 12, 21, 18)
    TargetFrame:SetHitRectInsets(5, 70, 21, 18)
    PetFrame:SetHitRectInsets(25, 12, -6, 8)
    TargetFrameToT:SetHitRectInsets(25, 12, -6, 8)
    FocusFrameToT:SetHitRectInsets(25, 12, -6, 8)

    local txt = PlayerFrameGroupIndicatorText
    local wt_p = PlayerFrameGroupIndicatorText:GetParent()
    local regions = {wt_p:GetRegions()}
    for _, region in ipairs(regions) do
        if region ~= txt then
            region:Hide()
        end
    end

    for i = 1, 4 do
        local partyMemberFrame = PartyFrame["MemberFrame"..i]
        partyMemberFrame:SetHitRectInsets(29, -8, -6, 8)
    end

    local function FixSelectionHighlight()
        local frames = {PlayerFrame, PetFrame, TargetFrame, FocusFrame, TargetFrameToT, FocusFrameToT, PartyFrame}

        for _, frame in pairs(frames) do
            if frame.Selection and frame.Selection.TopLeftCorner and not frame.Selection.bbfRepositioned then
                local xOffsetLeft = (frame == PartyFrame) and 43 or 0
                local xOffsetRight = (frame == PartyFrame) and -3 or 0
                local yOffsetBottom = (frame == PartyFrame) and 20 or 0
                local yOffsetTop = (frame ~= PartyFrame and frame ~= PetFrame) and 6 or 0
                frame.Selection.TopLeftCorner:ClearAllPoints()
                frame.Selection.TopLeftCorner:SetPoint("TOPLEFT", (frame.healthBar or frame.HealthBar or frame.healthbar or PartyFrame), "TOPLEFT", -16 + xOffsetLeft, 15 + yOffsetTop)
                frame.Selection.TopRightCorner:ClearAllPoints()
                frame.Selection.TopRightCorner:SetPoint("TOPRIGHT", (frame.healthBar or frame.HealthBar or frame.healthbar or PartyFrame), "TOPRIGHT", 15 + xOffsetRight, 15 + yOffsetTop)
                frame.Selection.BottomLeftCorner:ClearAllPoints()
                frame.Selection.BottomLeftCorner:SetPoint("BOTTOMLEFT", (frame.healthBar or frame.HealthBar or frame.healthbar or PartyFrame), "BOTTOMLEFT", -16 + xOffsetLeft, -25 + yOffsetBottom)
                frame.Selection.BottomRightCorner:ClearAllPoints()
                frame.Selection.BottomRightCorner:SetPoint("BOTTOMRIGHT", (frame.healthBar or frame.HealthBar or frame.healthbar or PartyFrame), "BOTTOMRIGHT", 15 + xOffsetRight, -25 + yOffsetBottom)
                frame.Selection.MouseOverHighlight:ClearAllPoints()
                frame.Selection.MouseOverHighlight:SetPoint("TOPLEFT", frame.Selection.TopLeftCorner, "TOPLEFT", 8, -8)
                frame.Selection.MouseOverHighlight:SetPoint("BOTTOMRIGHT", frame.Selection.BottomRightCorner, "BOTTOMRIGHT", -8, 8)
                if frame.Selection.HorizontalLabel then
                    frame.Selection.HorizontalLabel:ClearAllPoints()
                    frame.Selection.HorizontalLabel:SetPoint("CENTER", frame.Selection.MouseOverHighlight, "CENTER", 0, 0)
                end
                frame.Selection.bbfRepositioned = true

                hooksecurefunc(frame.Selection.TopLeftCorner, "SetPoint", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:ClearAllPoints()
                    self:SetPoint("TOPLEFT", (frame.healthBar or frame.HealthBar or frame.healthbar or PartyFrame), "TOPLEFT", -16 + xOffsetLeft, 15 + yOffsetTop)
                    self.changing = false
                end)

                hooksecurefunc(frame.Selection.TopRightCorner, "SetPoint", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:ClearAllPoints()
                    self:SetPoint("TOPRIGHT", (frame.healthBar or frame.HealthBar or frame.healthbar or PartyFrame), "TOPRIGHT", 15 + xOffsetRight, 15 + yOffsetTop)
                    self.changing = false
                end)

                hooksecurefunc(frame.Selection.BottomLeftCorner, "SetPoint", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:ClearAllPoints()
                    self:SetPoint("BOTTOMLEFT", (frame.healthBar or frame.HealthBar or frame.healthbar or PartyFrame), "BOTTOMLEFT", -16 + xOffsetLeft, -25 + yOffsetBottom)
                    self.changing = false
                end)

                hooksecurefunc(frame.Selection.BottomRightCorner, "SetPoint", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:ClearAllPoints()
                    self:SetPoint("BOTTOMRIGHT", (frame.healthBar or frame.HealthBar or frame.healthbar or PartyFrame), "BOTTOMRIGHT", 15 + xOffsetRight, -25 + yOffsetBottom)
                    self.changing = false
                end)

                hooksecurefunc(frame.Selection.MouseOverHighlight, "SetPoint", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:ClearAllPoints()
                    self:SetPoint("TOPLEFT", frame.Selection.TopLeftCorner, "TOPLEFT", 8, -8)
                    self:SetPoint("BOTTOMRIGHT", frame.Selection.BottomRightCorner, "BOTTOMRIGHT", -8, 8)
                    self.changing = false
                end)
            end

        end
    end

    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
        if InCombatLockdown() then return end
        FixSelectionHighlight()
    end)

    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        if InCombatLockdown() then return end
        FixSelectionHighlight()
    end)

    C_Timer.After(0.5, function()
        BBF.UpdateNoPortraitManaVisibility()
    end)
end