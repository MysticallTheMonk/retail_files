local layoutName = "BlizzCompact"
local layout = {}
layout.name = "|cff00b4ffBlizz|r Compact |A:NewCharacter-Alliance:38:65|a"
local L = sArenaMixin.L

layout.defaultSettings = {
    posX = 400,
    posY = 120,
    scale = 1.05,
    classIconFontSize = 21,
    spacing = 20,
    growthDirection = 1,
    specIcon = {
        posX = -47.5,
        posY = -26.5,
        scale = 0.9,
    },
    trinket = {
        posX = 121,
        posY = -2.3,
        scale = 1,
        fontSize = 15,
    },
    racial = {
        posX = 203,
        posY = -3,
        scale = 0.8,
        fontSize = 15,
    },
    dispel = {
        posX = 250,
        posY = -3,
        scale = 0.8,
        fontSize = 15,
    },
    castBar = {
        posX = 29.5,
        posY = -14.5,
        scale = 1.17,
        width = 101,
        iconScale = 0.5,
        iconPosX = 7,
        iconPosY = 4.5,
        useModernCastbars = true,
        keepDefaultModernTextures = true,
        simpleCastbar = true,
        --hideCastbarIcon = true,
        recolorCastbar = false,
    },
    dr = {
        posX = -105,
        posY = -2,
        size = 31,
        borderSize = 1,
        fontSize = 12,
        spacing = 5,
        growthDirection = 4,
        brightDRBorder = true,
        showDRText = true,
    },
    widgets = {
        combatIndicator = {
            posX = 0,
            posY = 0,
            scale = 1.1,
        },
        targetIndicator = {
            enabled = true,
            posX = 0,
            posY = 0,
            scale = 1.2,
        },
        focusIndicator = {
            posX = 0,
            posY = 0,
            scale = 1.2,
        },
        partyTargetIndicators = {
            enabled = true,
            posX = 0,
            posY = 0,
            scale = 1,
        },
    },

    textures          = {
        generalStatusBarTexture       = "Blizzard RetailBar",
        healStatusBarTexture          = "sArena Stripes 2",
        castbarStatusBarTexture       = "sArena Default",
        castbarUninterruptibleTexture = "sArena Default",
        bgTexture = "Solid",
        bgColor = {0, 0, 0, 0.6},
    },
    retextureHealerClassStackOnly = true,

    -- custom layout settings
    frameFont = "PT Sans Narrow Bold",
    cdFont  = "PT Sans Narrow Bold",
    changeFont = true,
    mirrored = true,
    showSpecManaText = true,
    replaceClassIcon = true,

    textSettings = {
        specNameSize = 0.85,
        castbarSize = 0.95,
        powerAnchor = "RIGHT",
    },
}

local function getSetting(info)
    return layout.db[info[#info]]
end

local function setSetting(info, val)
    layout.db[info[#info]] = val

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        layout:UpdateOrientation(frame)
    end

    if info[#info] == "mirrored" then
        local expectedPosX = val and (layout.defaultSettings.castBar.posX - 41) or layout.defaultSettings.castBar.posX
        if layout.db.castBar.posX == expectedPosX then
            if val then
                layout.db.castBar.posX = layout.db.castBar.posX + 41
            else
                layout.db.castBar.posX = layout.db.castBar.posX - 41
            end
            info.handler:UpdateCastBarSettings(layout.db.castBar)
        end
    end

    sArenaMixin:RefreshConfig()
end

local function setupOptionsTable(self)
    layout.optionsTable = self:GetLayoutOptionsTable(layoutName)

    layout.optionsTable.arenaFrames.args.positioning.args.mirrored = {
        order = 5,
        name = L["Option_MirroredFrames"],
        type = "toggle",
        width = "full",
        get = getSetting,
        set = setSetting,
    }
end

function layout:Initialize(frame)
    self.db = frame.parent.db.profile.layoutSettings[layoutName]

    if (not self.optionsTable) then
        setupOptionsTable(frame.parent)
    end

    if (frame:GetID() == sArenaMixin.maxArenaOpponents) then
        frame.parent:UpdateCastBarSettings(self.db.castBar)
        frame.parent:UpdateDRSettings(self.db.dr)
        frame.parent:UpdateFrameSettings(self.db)
        frame.parent:UpdateSpecIconSettings(self.db.specIcon)
        frame.parent:UpdateTrinketSettings(self.db.trinket)
        frame.parent:UpdateRacialSettings(self.db.racial)
        frame.parent:UpdateDispelSettings(self.db.dispel)
        frame.parent:UpdateWidgetSettings(self.db.widgets)
    end

    frame:SetSize(195, 67)

    -- some reused variables
    local healthBar = frame.HealthBar
    local powerBar = frame.PowerBar
    local f = frame.ClassIcon

    -- text adjustments
    local healthText = frame.HealthText
    healthText:SetJustifyH("CENTER")
    healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
    healthText:SetDrawLayer("OVERLAY", 4)

    local powerText = frame.PowerText
    powerText:SetDrawLayer("OVERLAY", 4)

    local playerName = frame.Name
    playerName:SetJustifyH("CENTER")
    playerName:SetHeight(12)
    playerName:SetDrawLayer("OVERLAY", 6)

    local classIcon = frame.ClassIcon
    frame.ClassIcon:SetSize(42.5, 42.5)
    frame.ClassIcon:Show()
    frame.ClassIcon:SetFrameStrata("LOW")
    frame.ClassIcon.Texture:SetTexCoord(0.05, 0.95, 0.1, 0.9)
    if not classIcon.Texture.Border then
        classIcon.Texture.Border = frame:CreateTexture(nil, "ARTWORK", nil, 3)
    end
    local classIconBorder = classIcon.Texture.Border
    frame.ClassIcon.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    frame.ClassIcon.Mask:SetAllPoints(classIcon.Texture)
    classIcon.Texture:AddMaskTexture(frame.ClassIcon.Mask)
    frame.ClassIcon.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
    if not classIcon.Texture.BorderParent then
        classIcon.Texture.BorderParent = CreateFrame("Frame", nil, frame)
        classIcon.Texture.BorderParent:SetFrameStrata("MEDIUM")
        classIcon.Texture.BorderParent:SetFrameLevel(8)
    end
    classIconBorder:SetParent(classIcon.Texture.BorderParent)
    classIconBorder:SetAtlas("plunderstorm-actionbar-slot-border")
    classIconBorder:SetPoint("TOPLEFT", classIcon.Texture, "TOPLEFT", -8, 8)
    classIconBorder:SetPoint("BOTTOMRIGHT", classIcon.Texture, "BOTTOMRIGHT", 8, -8)
    classIconBorder:SetDrawLayer("OVERLAY", 3)
    classIconBorder:Show()
    classIcon.Texture.Border = classIconBorder
    classIcon.Texture.useModernBorder = true

    if not classIcon.Texture.ClassIconBorderHook then
        hooksecurefunc(classIcon.Texture, "SetTexture", function(self, t)
            if not t or not self.useModernBorder then
                classIconBorder:Hide()
            else
                classIconBorder:Hide()
                classIconBorder:Show()
            end
        end)
        classIcon.Texture.ClassIconBorderHook = true
    end

    local trinket = frame.Trinket
    if not trinket.Border then
        trinket.Border = frame:CreateTexture(nil, "ARTWORK", nil, 3)
    end
    local trinketBorder = trinket.Border
    if not trinket.Mask then
        trinket.Mask = trinket:CreateMaskTexture()
    end
    trinket.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    trinket.Mask:SetAllPoints(trinket.Texture)
    trinket.Texture:AddMaskTexture(trinket.Mask)
    trinket.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
    trinket.Border = trinketBorder
    trinket:SetSize(42.5, 42.5)
    if not trinket.BorderParent then
        trinket.BorderParent = CreateFrame("Frame", nil, trinket)
        trinket.BorderParent:SetFrameStrata("MEDIUM")
        trinket.BorderParent:SetFrameLevel(8)
    end
    trinketBorder:SetParent(trinket.BorderParent)
    trinketBorder:SetAtlas("plunderstorm-actionbar-slot-border")
    trinketBorder:SetPoint("TOPLEFT", trinket, "TOPLEFT", -8, 8)
    trinketBorder:SetPoint("BOTTOMRIGHT", trinket, "BOTTOMRIGHT", 8, -8)
    trinketBorder:SetDrawLayer("OVERLAY", 3)
    trinketBorder:Show()
    trinket.Border = trinketBorder
    trinket.useModernBorder = true

    if not trinket.TrinketBorderHook then
        hooksecurefunc(trinket.Texture, "SetTexture", function(self, t)
            if not t or not trinket.useModernBorder then
                trinketBorder:Hide()
            else
                trinketBorder:Hide()
                trinketBorder:Show()
            end
        end)
        trinket.TrinketBorderHook = true
    end

    -- racial
    local racial = frame.Racial
    if not racial.Border then
        racial.Border = frame:CreateTexture(nil, "ARTWORK", nil, 3)
    end
    local racialBorder = racial.Border
    if not racial.Mask then
        racial.Mask = racial:CreateMaskTexture()
    end
    racial.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    racial.Mask:SetAllPoints(racial.Texture)
    racial.Texture:SetTexCoord(0.03, 0.93, 0.03, 0.93)
    racial.Texture:AddMaskTexture(racial.Mask)
    racial.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
    racial:SetSize(42.5, 42.5)
    if not racial.BorderParent then
        racial.BorderParent = CreateFrame("Frame", nil, racial)
        racial.BorderParent:SetFrameStrata("MEDIUM")
        racial.BorderParent:SetFrameLevel(8)
    end
    racialBorder:SetParent(racial.BorderParent)
    racialBorder:SetAtlas("plunderstorm-actionbar-slot-border")
    racialBorder:SetPoint("TOPLEFT", racial, "TOPLEFT", -8, 8)
    racialBorder:SetPoint("BOTTOMRIGHT", racial, "BOTTOMRIGHT", 8, -8)
    racialBorder:SetDrawLayer("OVERLAY", 3)
    racialBorder:Show()
    racial.Border = racialBorder
    racial.useModernBorder = true

    if not racial.RacialBorderHook then
        hooksecurefunc(racial.Texture, "SetTexture", function(self, t)
            if not t or not racial.useModernBorder then
                racialBorder:Hide()
            else
                racialBorder:Hide()
                racialBorder:Show()
            end
        end)
        racial.RacialBorderHook = true
    end

    -- dispel
    local dispel = frame.Dispel
    if not dispel.Border then
        dispel.Border = frame:CreateTexture(nil, "ARTWORK", nil, 3)
    end
    local dispelBorder = dispel.Border
    if not dispel.Mask then
        dispel.Mask = dispel:CreateMaskTexture()
    end
    dispel.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    dispel.Mask:SetAllPoints(dispel.Texture)

    -- Apply the mask
    dispel.Texture:AddMaskTexture(dispel.Mask)

    dispel.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
    dispel:SetSize(42.5, 42.5)
    if not dispel.BorderParent then
        dispel.BorderParent = CreateFrame("Frame", nil, dispel)
        dispel.BorderParent:SetFrameStrata("MEDIUM")
        dispel.BorderParent:SetFrameLevel(8)
    end
    dispelBorder:SetParent(dispel.BorderParent)
    dispelBorder:SetAtlas("plunderstorm-actionbar-slot-border")
    dispelBorder:SetPoint("TOPLEFT", dispel, "TOPLEFT", -8, 8)
    dispelBorder:SetPoint("BOTTOMRIGHT", dispel, "BOTTOMRIGHT", 8, -8)
    dispelBorder:SetDrawLayer("OVERLAY", 3)
    dispelBorder:Show()
    dispel.Border = dispelBorder
    dispel.useModernBorder = true

    if not dispel.DispelBorderHook then
        hooksecurefunc(dispel.Texture, "SetTexture", function(self, t)
            if not t or not dispel.useModernBorder then
                dispelBorder:Hide()
            else
                dispelBorder:Hide()
                dispelBorder:Show()
            end
        end)
        hooksecurefunc(dispel, "Hide", function()
            dispelBorder:Hide()
        end)
        dispel.DispelBorderHook = true
    end

    -- spec icon
    if not frame.SpecIcon.Border then
        frame.SpecIcon.Border = frame.SpecIcon:CreateTexture(nil, "ARTWORK", nil, 3)
    end

    local specBorder = frame.SpecIcon.Border

    frame.SpecIcon:SetSize(20, 20)
    frame.SpecIcon.Texture:AddMaskTexture(frame.SpecIcon.Mask)
    frame.SpecIcon.Texture:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    specBorder:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\Map_Faction_Ring.tga")
    specBorder:SetPoint("TOPLEFT", frame.SpecIcon, "TOPLEFT", -8.5, 8.5)
    specBorder:SetPoint("BOTTOMRIGHT", frame.SpecIcon, "BOTTOMRIGHT", 8, -8)
    specBorder:SetDrawLayer("OVERLAY", 7)
    specBorder:SetDesaturated(true)
    frame.SpecIcon.Texture:SetDrawLayer("OVERLAY", 6)
    --specBorder:Hide()

    frame.SpecNameText:SetTextColor(1,1,1)
    frame.PowerText:SetAlpha(frame.parent.db.profile.hidePowerText and 0 or 1)

    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "CENTER", -1, -5)
    f:SetSize(42, 42)
    f:SetDrawLayer("OVERLAY", 7)

    local frameTexture = frame.frameTexture
    frameTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-UnitFrame-Player-PortraitOff-Large.tga")
    frameTexture:SetDrawLayer("OVERLAY", 5)
    frameTexture:SetTexCoord(0, 1, 0, 1)
    frameTexture:Show()

    if not sArenaMixin.isRetail then
        trinket.Cooldown:SetUseCircularEdge(true)
        racial.Cooldown:SetUseCircularEdge(true)
        frame.ClassIcon.Cooldown:SetUseCircularEdge(true)
        dispel.Cooldown:SetUseCircularEdge(true)
    end

    self:UpdateOrientation(frame)
end

function layout:UpdateOrientation(frame)
    local frameTexture = frame.frameTexture
    local healthBar = frame.HealthBar
    local powerBar = frame.PowerBar
    local classIcon = frame.ClassIcon
    local name = frame.Name
    local specName = frame.SpecNameText
    local healthText = frame.HealthText
    local powerText = frame.PowerText
    local castbarText = frame.CastBar.Text

    name:ClearAllPoints()
    healthBar:ClearAllPoints()
    powerBar:ClearAllPoints()
    frame.ClassIcon:ClearAllPoints()
    specName:ClearAllPoints()
    frameTexture:ClearAllPoints()

    if self.db.widgets then
        local w = self.db.widgets

        -- Combat Indicator
        if w.combatIndicator then
            frame.WidgetOverlay.combatIndicator:ClearAllPoints()
            frame.WidgetOverlay.combatIndicator:SetSize(18, 18)
            frame.WidgetOverlay.combatIndicator:SetScale(w.combatIndicator.scale or 1)
            frame.WidgetOverlay.combatIndicator:SetPoint("CENTER", frame.ClassIcon, "BOTTOM",
                (w.combatIndicator.posX or 0) + 0, (w.combatIndicator.posY or 0) + 0)
        end

        -- Target Indicator
        if w.targetIndicator then
            frame.WidgetOverlay.targetIndicator:ClearAllPoints()
            frame.WidgetOverlay.targetIndicator:SetSize(34, 34)
            frame.WidgetOverlay.targetIndicator:SetScale(w.targetIndicator.scale or 1)
            frame.WidgetOverlay.targetIndicator:SetPoint("CENTER", healthBar, "TOPLEFT",
                (w.targetIndicator.posX or 0) + 6.5, (w.targetIndicator.posY or 0) - 6.5)
        end

        -- Focus Indicator
        if w.focusIndicator then
            frame.WidgetOverlay.focusIndicator:ClearAllPoints()
            frame.WidgetOverlay.focusIndicator:SetSize(20, 20)
            frame.WidgetOverlay.focusIndicator:SetScale(w.focusIndicator.scale or 1)
            frame.WidgetOverlay.focusIndicator:SetPoint("CENTER", healthBar, "TOPLEFT",
                (w.focusIndicator.posX or 0) - 0.5, (w.focusIndicator.posY or 0) + 0)
        end

        -- Party Target Indicators
        if w.partyTargetIndicators then
            frame.WidgetOverlay.partyTarget1:ClearAllPoints()
            frame.WidgetOverlay.partyTarget1:SetSize(15, 15)
            frame.WidgetOverlay.partyTarget1:SetScale(w.partyTargetIndicators.scale or 1)
            frame.WidgetOverlay.partyTarget1:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT",
                (w.partyTargetIndicators.posX or 0) + 2, (w.partyTargetIndicators.posY or 0) - 2)

            frame.WidgetOverlay.partyTarget2:ClearAllPoints()
            frame.WidgetOverlay.partyTarget2:SetSize(15, 15)
            frame.WidgetOverlay.partyTarget2:SetScale(w.partyTargetIndicators.scale or 1)
            frame.WidgetOverlay.partyTarget2:SetPoint("RIGHT", frame.WidgetOverlay.partyTarget1, "LEFT", 3, 0)
        end
    end

    if self.db.textSettings then
        local txt = self.db.textSettings
        local modernCastbar = self.db.castBar.useModernCastbars

        name:SetScale(txt.nameSize or 1)
        healthText:SetScale(txt.healthSize or 1)
        specName:SetScale(txt.specNameSize or 1)
        castbarText:SetScale(txt.castbarSize or 1)
        powerText:SetScale(txt.powerSize or 1)

        -- Name
        name:ClearAllPoints()
        if (txt.nameAnchor or "CENTER") == "LEFT" then
            name:SetPoint("BOTTOMLEFT", frame.HealthBar, "TOPLEFT", 3 + (txt.nameOffsetX or 0), 1.5 + (txt.nameOffsetY or 0))
        elseif (txt.nameAnchor or "CENTER") == "RIGHT" then
            name:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT", -3 + (txt.nameOffsetX or 0), 1.5 + (txt.nameOffsetY or 0))
        else
            name:SetPoint("BOTTOM", frame.HealthBar, "TOP", -1 + (txt.nameOffsetX or 0), 1.5 + (txt.nameOffsetY or 0))
        end

        -- Health Text
        healthText:ClearAllPoints()
        if (txt.healthAnchor or "CENTER") == "LEFT" then
            healthText:SetPoint("LEFT", healthBar, "LEFT", 4 + (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        elseif (txt.healthAnchor or "CENTER") == "RIGHT" then
            healthText:SetPoint("RIGHT", healthBar, "RIGHT", -3 + (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        else
            healthText:SetPoint("CENTER", healthBar, "CENTER", -1 + (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        end

        -- Power Text
        powerText:ClearAllPoints()
        if (txt.powerAnchor or "CENTER") == "LEFT" then
            powerText:SetPoint("LEFT", frame.PowerBar, "LEFT", 0 + (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        elseif (txt.powerAnchor or "CENTER") == "RIGHT" then
            powerText:SetPoint("RIGHT", frame.PowerBar, "RIGHT", 0 + (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        else
            powerText:SetPoint("CENTER", frame.PowerBar, "CENTER", (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        end

        -- Spec Text
        specName:ClearAllPoints()
        if (txt.specNameAnchor or "CENTER") == "LEFT" then
            specName:SetPoint("LEFT", healthBar, "LEFT", 4 + (txt.specNameOffsetX or 0), -23 + (txt.specNameOffsetY or 0))
        elseif (txt.specNameAnchor or "CENTER") == "RIGHT" then
            specName:SetPoint("RIGHT", healthBar, "RIGHT", -3 + (txt.specNameOffsetX or 0), -23 + (txt.specNameOffsetY or 0))
        else
            specName:SetPoint("CENTER", healthBar, "CENTER", -1 + (txt.specNameOffsetX or 0), -23 + (txt.specNameOffsetY or 0))
        end

        -- Castbar Text
        castbarText:ClearAllPoints()
        local simpleCastbar = self.db.castBar.simpleCastbar and modernCastbar
        if (txt.castbarAnchor or "CENTER") == "LEFT" then
            castbarText:SetPoint("LEFT", frame.CastBar, "LEFT", 3 + (txt.castbarOffsetX or 0), (modernCastbar and (simpleCastbar and 0 or -11) or 0) + (txt.castbarOffsetY or 0))
        elseif (txt.castbarAnchor or "CENTER") == "RIGHT" then
            castbarText:SetPoint("RIGHT", frame.CastBar, "RIGHT", -3 + (txt.castbarOffsetX or 0), (modernCastbar and (simpleCastbar and 0 or -11) or 0) + (txt.castbarOffsetY or 0))
        else
            castbarText:SetPoint("CENTER", frame.CastBar, "CENTER", (txt.castbarOffsetX or 0), (modernCastbar and (simpleCastbar and 0 or -11) or 0) + (txt.castbarOffsetY or 0))
        end
    end

    if (self.db.mirrored) then
        frameTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -3)
        frameTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 68, 3)
        healthBar:SetSize(127, 30)
    	healthBar:GetStatusBarTexture():SetDrawLayer("BORDER", 1)
    	healthBar:SetPoint("TOPRIGHT", -4, -16)
        powerBar:SetSize(127, 10.5)
        powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, 1.5)
        frame.ClassIcon:SetPoint("TOPLEFT", 15, -14.5)
    else
    	frameTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", -48, -3)
        frameTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 20, 3)
    	healthBar:SetSize(127, 30)
    	healthBar:GetStatusBarTexture():SetDrawLayer("BORDER", 1)
    	healthBar:SetPoint("TOPLEFT", 16, -16)
    	powerBar:SetSize(127, 10.5)
    	powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, 1.5)
    	frame.ClassIcon:SetPoint("TOPRIGHT", -3, -14.5)
    end
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings
