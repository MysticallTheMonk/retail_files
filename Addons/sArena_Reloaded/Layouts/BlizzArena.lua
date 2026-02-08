local layoutName = "BlizzArena"
local layout = {}
layout.name = "|cff00b4ffBlizz|r Arena"
local L = sArenaMixin.L

layout.defaultSettings = {
    posX = 330,
    posY = 130,
    scale = 1.5,
    classIconFontSize = 10,
    spacing = 20,
    growthDirection = 1,
    specIcon = {
        posX = 47,
        posY = -12,
        scale = 1,
    },
    trinket = {
        posX = -66,
        posY = -1,
        scale = 1,
        fontSize = 12,
    },
    racial = {
        posX = -90,
        posY = -1,
        scale = 1,
        fontSize = 12,
    },
    dispel = {
        posX = -114,
        posY = -1,
        scale = 1,
        fontSize = 12,
    },
    castBar = {
        posX = -148,
        posY = 0,
        scale = 1,
        width = 84,
        iconScale = 1,
        keepDefaultModernTextures = true,
        recolorCastbar = false,
    },
    dr = {
        posX = -74,
        posY = 24,
        size = 22,
        borderSize = 2.5,
        fontSize = 12,
        spacing = 6,
        growthDirection = 4,
    },
    widgets = {
        combatIndicator = {
            posX = 0,
            posY = 0,
            scale = 0.6,
        },
        targetIndicator = {
            posX = 0,
            posY = 0,
            scale = 0.9,
        },
        focusIndicator = {
            posX = 0,
            posY = 0,
            scale = 0.85,
        },
        partyTargetIndicators = {
            posX = 0,
            posY = 0,
            scale = 0.7,
        },
    },

    textures          = {
        generalStatusBarTexture       = "sArena Default",
        healStatusBarTexture          = "sArena Stripes",
        castbarStatusBarTexture       = "sArena Default",
        castbarUninterruptibleTexture = "sArena Default",
        bgTexture = "Solid",
        bgColor = {0, 0, 0, 0.6},
    },
    retextureHealerClassStackOnly = true,

    -- custom layout settings
    frameFont = "Prototype",
    cdFont  = "Prototype",
    mirrored = false,

    textSettings = {
        specNameSize = 0.65,
        nameAnchor = "LEFT",
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

    layout.optionsTable.arenaFrames.args.other.args.trinketCircleBorder = {
        order = 3,
        name = L["Option_TrinketCircleBorder"],
        desc = L["Option_TrinketCircleBorder_Desc"],
        type = "toggle",
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

    frame.ClassIcon.Cooldown:SetSwipeTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    frame.ClassIcon.Cooldown:SetUseCircularEdge(true)
    frame.ClassIcon:SetFrameStrata("LOW")
    frame.ClassIcon:SetFrameLevel(7)

    frame:SetSize(102, 32)
    frame.SpecIcon:SetSize(14, 14)
    frame.SpecIcon.Texture:AddMaskTexture(frame.SpecIcon.Mask)
    frame.Trinket:SetSize(22, 22)
    frame.Racial:SetSize(22, 22)
    frame.Dispel:SetSize(22, 22)

    local healthBar = frame.HealthBar
    healthBar:SetSize(69, 7)
    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    local powerBar = frame.PowerBar
    powerBar:SetSize(69, 8)
    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -1)
    powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    local f = frame.ClassIcon
    f:SetSize(24, 24)
    f:Show()
    f.Texture:AddMaskTexture(f.Mask)
    f.Mask:SetAllPoints(f.Texture)

    local trinket = frame.Trinket


    if self.db.trinketCircleBorder then
        sArenaMixin.showTrinketCircleBorder = true
        if not trinket.Mask then
            trinket.Mask = trinket:CreateMaskTexture()
        end
        trinket.Mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        trinket.Mask:SetAllPoints(trinket.Texture)
        trinket.Texture:AddMaskTexture(trinket.Mask)

        trinket.Cooldown:SetSwipeTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        trinket.Cooldown:SetUseCircularEdge(true)

        if not trinket.CircleBorder then
            trinket.CircleBorder = trinket:CreateTexture(nil, "ARTWORK", nil, 3)
        end

        local trinketCircleBorder = trinket.CircleBorder
        trinketCircleBorder:ClearAllPoints()
        trinketCircleBorder:SetTexture("Interface\\CHARACTERFRAME\\TotemBorder")
        trinketCircleBorder:SetPoint("TOPLEFT", trinket, "TOPLEFT", -8, 8)
        trinketCircleBorder:SetPoint("BOTTOMRIGHT", trinket, "BOTTOMRIGHT", 8, -8)
        trinketCircleBorder:SetDrawLayer("OVERLAY", 7)
        trinketCircleBorder:Show()

        if not trinket.TrinketCircleBorderHook then
            hooksecurefunc(trinket.Texture, "SetTexture", function(self, t)
                if not t or not sArenaMixin.showTrinketCircleBorder then
                    trinketCircleBorder:Hide()
                else
                    trinketCircleBorder:Show()
                end
            end)
            trinket.TrinketCircleBorderHook = true
        end
    else
        if trinket.Mask then
            trinket.Texture:RemoveMaskTexture(trinket.Mask)
        end
        if trinket.CircleBorder then
            trinket.CircleBorder:Hide()
        end

        trinket.Cooldown:SetUseCircularEdge(false)
    end


    -- Spec icon border
    if not frame.SpecIcon.Border then
        frame.SpecIcon.Border = frame.SpecIcon:CreateTexture(nil, "ARTWORK", nil, 3)
    end

    local specBorder = frame.SpecIcon.Border
    specBorder:ClearAllPoints()
    specBorder:SetTexture("Interface\\CHARACTERFRAME\\TotemBorder")
    specBorder:SetPoint("TOPLEFT", frame.SpecIcon, "TOPLEFT", -5, 5)
    specBorder:SetPoint("BOTTOMRIGHT", frame.SpecIcon, "BOTTOMRIGHT", 5, -5)
    specBorder:Show()

    f = frame.Name
    f:SetJustifyH("LEFT")
    f:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2, 2)
    f:SetPoint("BOTTOMRIGHT", healthBar, "TOPRIGHT", -2, 2)
    f:SetHeight(12)
    f:SetFont("Fonts\\FRIZQT__.TTF", 11, "")

    f = frame.CastBar
    f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "CENTER")
    f:SetSize(26, 26)

    local fn, fs, fstyle = frame.HealthText:GetFont()
    frame.HealthText:SetFont(fn, 10, "OUTLINE")
    local fn, fs, fstyle = frame.HealthText:GetFont()
    frame.PowerText:SetFont(fn, 10, "OUTLINE")
    frame.PowerText:SetAlpha(frame.parent.db.profile.hidePowerText and 0 or 1)

    local fn, fs, fstyle = frame.SpecNameText:GetFont()
    frame.SpecNameText:SetFont(fn, fs, "OUTLINE")
    frame.SpecNameText:SetTextColor(1,1,1)

    frame.AuraStacks:SetPoint("BOTTOMLEFT", frame.ClassIcon, "BOTTOMLEFT", 1, -4)
    frame.AuraStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 11, "THICKOUTLINE")

    -- Frame background texture
    local frameTexture = frame.frameTexture
    frameTexture:ClearAllPoints()
    frameTexture:SetAllPoints(frame)
    frameTexture:SetTexture("Interface\\ARENAENEMYFRAME\\UI-ArenaTargetingFrame")
    frameTexture:Show()

    self:UpdateOrientation(frame)
end

function layout:UpdateOrientation(frame)
    local frameTexture = frame.frameTexture
    local healthBar = frame.HealthBar
    local classIcon = frame.ClassIcon
    local name = frame.Name
    local specName = frame.SpecNameText
    local healthText = frame.HealthText
    local powerText = frame.PowerText
    local castbarText = frame.CastBar.Text

    if self.db.widgets then
        local w = self.db.widgets

        -- Combat Indicator
        if w.combatIndicator then
            frame.WidgetOverlay.combatIndicator:ClearAllPoints()
            frame.WidgetOverlay.combatIndicator:SetSize(18, 18)
            frame.WidgetOverlay.combatIndicator:SetScale(w.combatIndicator.scale or 1)
            frame.WidgetOverlay.combatIndicator:SetPoint("CENTER", frame.HealthBar, "CENTER",
                (w.combatIndicator.posX or 0), (w.combatIndicator.posY or 0) - 13)
        end

        -- Target Indicator
        if w.targetIndicator then
            frame.WidgetOverlay.targetIndicator:ClearAllPoints()
            frame.WidgetOverlay.targetIndicator:SetSize(34, 34)
            frame.WidgetOverlay.targetIndicator:SetScale(w.targetIndicator.scale or 1)
            frame.WidgetOverlay.targetIndicator:SetPoint("CENTER", frame.ClassIcon, "CENTER",
                (w.targetIndicator.posX or 0) - 6, (w.targetIndicator.posY or 0) + 2)
        end

        -- Focus Indicator
        if w.focusIndicator then
            frame.WidgetOverlay.focusIndicator:ClearAllPoints()
            frame.WidgetOverlay.focusIndicator:SetSize(20, 20)
            frame.WidgetOverlay.focusIndicator:SetScale(w.focusIndicator.scale or 1)
            frame.WidgetOverlay.focusIndicator:SetPoint("BOTTOMRIGHT", frame.ClassIcon, "BOTTOMRIGHT",
                (w.focusIndicator.posX or 0) - 19, (w.focusIndicator.posY or 0) + 13.5)
        end

        -- Party Target Indicators
        if w.partyTargetIndicators then
            frame.WidgetOverlay.partyTarget1:ClearAllPoints()
            frame.WidgetOverlay.partyTarget1:SetSize(15, 15)
            frame.WidgetOverlay.partyTarget1:SetScale(w.partyTargetIndicators.scale or 1)
            frame.WidgetOverlay.partyTarget1:SetPoint("TOPLEFT", frame.HealthBar, "TOPRIGHT",
                (w.partyTargetIndicators.posX or 0) - 11, (w.partyTargetIndicators.posY or 0) - 17)

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
            name:SetPoint("BOTTOMLEFT", frame.HealthBar, "TOPLEFT", 3 + (txt.nameOffsetX or 0), 3 + (txt.nameOffsetY or 0))
        elseif (txt.nameAnchor or "CENTER") == "RIGHT" then
            name:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT", -3 + (txt.nameOffsetX or 0), 3 + (txt.nameOffsetY or 0))
        else
            name:SetPoint("BOTTOM", frame.HealthBar, "TOP", (txt.nameOffsetX or 0), 3 + (txt.nameOffsetY or 0))
        end

        -- Health Text
        healthText:ClearAllPoints()
        if (txt.healthAnchor or "CENTER") == "LEFT" then
            healthText:SetPoint("LEFT", healthBar, "LEFT", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        elseif (txt.healthAnchor or "CENTER") == "RIGHT" then
            healthText:SetPoint("RIGHT", healthBar, "RIGHT", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        else
            healthText:SetPoint("CENTER", healthBar, "CENTER", (txt.healthOffsetX or 0) + 1, (txt.healthOffsetY or 0))
        end

        -- Power Text
        powerText:ClearAllPoints()
        if (txt.powerAnchor or "CENTER") == "LEFT" then
            powerText:SetPoint("LEFT", frame.PowerBar, "LEFT", 0 + (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        elseif (txt.powerAnchor or "CENTER") == "RIGHT" then
            powerText:SetPoint("RIGHT", frame.PowerBar, "RIGHT", 0 + (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        else
            powerText:SetPoint("CENTER", frame.PowerBar, "CENTER", (txt.powerOffsetX or 0) + 1, (txt.powerOffsetY or 0))
        end

        -- Spec Text
        specName:ClearAllPoints()
        if (txt.specNameAnchor or "CENTER") == "LEFT" then
            specName:SetPoint("LEFT", frame.PowerBar, "LEFT", (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
        elseif (txt.specNameAnchor or "CENTER") == "RIGHT" then
            specName:SetPoint("RIGHT", frame.PowerBar, "RIGHT", (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
        else
            specName:SetPoint("CENTER", frame.PowerBar, "CENTER", (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
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

    healthBar:ClearAllPoints()
    frame.ClassIcon:ClearAllPoints()

    if (self.db.mirrored) then
        frameTexture:SetTexCoord(0.796, 0, 0, 0.5)
        healthBar:SetPoint("TOPRIGHT", -3, -9)
        frame.ClassIcon:SetPoint("TOPLEFT", 4, -4)
    else
        frameTexture:SetTexCoord(0, 0.796, 0, 0.5)
        healthBar:SetPoint("TOPLEFT", 3, -9)
        classIcon:SetPoint("TOPRIGHT", -4, -4)
    end
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings
