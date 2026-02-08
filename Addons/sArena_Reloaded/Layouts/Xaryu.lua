local layoutName = "Xaryu"
local layout = {}
local L = sArenaMixin.L

layout.defaultSettings = {
    posX = 410,
    posY = 120,
    scale = 1.1,
    classIconFontSize = 14,
    spacing = 35,
    growthDirection = 1,
    specIcon = {
        posX = -21,
        posY = -2,
        scale = 1,
    },
    trinket = {
        posX = 101,
        posY = 0,
        scale = 1,
        fontSize = 14,
    },
    racial = {
        posX = 200,
        posY = 0,
        scale = 0.7,
        fontSize = 14,
    },
    dispel = {
        posX = 247,
        posY = 0,
        scale = 0.7,
        fontSize = 14,
    },
    castBar = {
        posX = 12,
        posY = -27,
        scale = 1.25,
        width = 98,
        iconScale = 1,
        keepDefaultModernTextures = true,
        recolorCastbar = false,
    },
    dr = {
        posX = -95,
        posY = 0,
        size = 28,
        borderSize = 2.5,
        fontSize = 12,
        spacing = 6,
        growthDirection = 4,
    },
    widgets = {
        combatIndicator = {
            posX = 0,
            posY = 0,
            scale = 0.9,
        },
        targetIndicator = {
            posX = 0,
            posY = 0,
            scale = 1,
        },
        focusIndicator = {
            posX = 0,
            posY = 0,
            scale = 1,
        },
        partyTargetIndicators = {
            posX = 0,
            posY = 0,
            scale = 1,
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
    width = 152,
    height = 44,
    powerBarHeight = 9,
    mirrored = true,
    classicBars = false,

    textSettings = {
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
        frame:SetSize(layout.db.width, layout.db.height)
        frame.ClassIcon:SetSize(layout.db.height, layout.db.height)
        frame.DeathIcon:SetSize(layout.db.height * 0.8, layout.db.height * 0.8)
        frame.PowerBar:SetHeight(layout.db.powerBarHeight)
        layout:UpdateOrientation(frame)
    end
    local setting = info[#info]
    if (setting ~= "width" and setting ~= "height" and setting ~= "powerBarHeight") then
        sArenaMixin:RefreshConfig()
    end
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

    layout.optionsTable.arenaFrames.args.sizing.args.width = {
        order = 3,
        name = L["Width"],
        type = "range",
        min = 40,
        max = 400,
        step = 1,
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.sizing.args.height = {
        order = 4,
        name = L["Height"],
        type = "range",
        min = 2,
        max = 100,
        step = 1,
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.sizing.args.powerBarHeight = {
        order = 5,
        name = L["Option_PowerBarHeight"],
        type = "range",
        min = 1,
        max = 50,
        step = 1,
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.other.args.cropIcons = {
        order = 5,
        name = L["Option_CropIcons"],
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

    frame:SetSize(self.db.width, self.db.height)
    frame.SpecIcon:SetSize(18, 18)
    frame.Trinket:SetSize(44, 44)
    frame.Racial:SetSize(44, 44)
    frame.Dispel:SetSize(44, 44)

    frame.PowerBar:SetHeight(self.db.powerBarHeight)

    frame.ClassIcon:SetSize(self.db.height, self.db.height)
    frame.ClassIcon:Show()

    local f = frame.Name
    f:SetJustifyH("LEFT")
    f:SetJustifyV("BOTTOM")
    f:SetFontObject("SystemFont_Shadow_Med3")
    f:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    f:SetHeight(12)

    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "CENTER")
    f:SetSize(self.db.height * 0.8, self.db.height * 0.8)

    frame.PowerText:SetPoint("CENTER", frame.PowerBar)
    local fn, fs, fstyle = frame.HealthText:GetFont()
    frame.HealthText:SetFont(fn, 10, "OUTLINE")
    local fn, fs, fstyle = frame.HealthText:GetFont()
    frame.PowerText:SetFont(fn, 10, "OUTLINE")
    frame.PowerText:SetShadowOffset(0, 0)
    frame.HealthText:SetShadowOffset(0, 0)

    self:UpdateOrientation(frame)
end

function layout:UpdateOrientation(frame)
    local healthBar = frame.HealthBar
    local powerBar = frame.PowerBar
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
                (w.combatIndicator.posX or 0), (w.combatIndicator.posY or 0) - 20)
        end

        -- Target Indicator
        if w.targetIndicator then
            frame.WidgetOverlay.targetIndicator:ClearAllPoints()
            frame.WidgetOverlay.targetIndicator:SetSize(34, 34)
            frame.WidgetOverlay.targetIndicator:SetScale(w.targetIndicator.scale or 1)
            frame.WidgetOverlay.targetIndicator:SetPoint("TOPLEFT", frame.ClassIcon, "BOTTOMRIGHT",
                -16 + (w.targetIndicator.posX or 0), 15 + (w.targetIndicator.posY or 0))
        end

        -- Focus Indicator
        if w.focusIndicator then
            frame.WidgetOverlay.focusIndicator:ClearAllPoints()
            frame.WidgetOverlay.focusIndicator:SetSize(20, 20)
            frame.WidgetOverlay.focusIndicator:SetScale(w.focusIndicator.scale or 1)
            frame.WidgetOverlay.focusIndicator:SetPoint("BOTTOMRIGHT", frame.ClassIcon, "BOTTOMRIGHT",
                4 + (w.focusIndicator.posX or 0), -5 + (w.focusIndicator.posY or 0))
        end

        -- Party Target Indicators
        if w.partyTargetIndicators then
            frame.WidgetOverlay.partyTarget1:ClearAllPoints()
            frame.WidgetOverlay.partyTarget1:SetSize(15, 15)
            frame.WidgetOverlay.partyTarget1:SetScale(w.partyTargetIndicators.scale or 1)
            frame.WidgetOverlay.partyTarget1:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT",
                2 + (w.partyTargetIndicators.posX or 0), (w.partyTargetIndicators.posY or 0) - 4)

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
            name:SetPoint("BOTTOMLEFT", frame.HealthBar, "TOPLEFT", (txt.nameOffsetX or 0), (txt.nameOffsetY or 0))
        elseif (txt.nameAnchor or "CENTER") == "RIGHT" then
            name:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT", (txt.nameOffsetX or 0), (txt.nameOffsetY or 0))
        else
            name:SetPoint("BOTTOM", frame.HealthBar, "TOP", (txt.nameOffsetX or 0), (txt.nameOffsetY or 0))
        end

        -- Health Text
        healthText:ClearAllPoints()
        if (txt.healthAnchor or "CENTER") == "LEFT" then
            healthText:SetPoint("LEFT", healthBar, "LEFT", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        elseif (txt.healthAnchor or "CENTER") == "RIGHT" then
            healthText:SetPoint("RIGHT", healthBar, "RIGHT", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        else
            healthText:SetPoint("CENTER", healthBar, "CENTER", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
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
    powerBar:ClearAllPoints()
    frame.ClassIcon:ClearAllPoints()

    if (self.db.mirrored) then
        healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -2)
        healthBar:SetPoint("BOTTOMLEFT", powerBar, "TOPLEFT")

        powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 2)
        powerBar:SetPoint("LEFT", classIcon, "RIGHT", 2, 0)

        frame.ClassIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    else
        healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
        healthBar:SetPoint("BOTTOMRIGHT", powerBar, "TOPRIGHT")

        powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 2)
        powerBar:SetPoint("RIGHT", classIcon, "LEFT", -2, 0)

        frame.ClassIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    end
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings