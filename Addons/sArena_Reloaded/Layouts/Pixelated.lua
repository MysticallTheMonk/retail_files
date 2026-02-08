local layoutName = "Pixelated"
local layout = {}
layout.name = "Pixelated |A:NewCharacter-Alliance:38:65|a"
local L = sArenaMixin.L

layout.defaultSettings = {
    posX = 433,
    posY = 143,
    scale = 1.05,
    classIconFontSize = 14,
    spacing = 35,
    growthDirection = 1,
    classIcon = {
        posX = 0,
        posY = 0,
        scale = 1,
    },
    specIcon = {
        posX = -21,
        posY = -2,
        scale = 1,
    },
    trinket = {
        posX = 105,
        posY = 0,
        scale = 1.049,
        fontSize = 14,
    },
    racial = {
        posX = 147,
        posY = 0,
        scale = 1.049,
        fontSize = 14,
    },
    dispel = {
        posX = 189,
        posY = 0,
        scale = 1.049,
        fontSize = 14,
    },
    castBar = {
        posX = -125,
        posY = -8.2,
        scale = 1.33,
        width = 115,
        iconScale = 1,
        iconPosX = 4,
        keepDefaultModernTextures = true,
        recolorCastbar = false,
    },
    dr = {
        posX = -110,
        posY = 22,
        size = 31,
        borderSize = 1,
        fontSize = 12,
        spacing = 7,
        growthDirection = 4,
        thickPixelBorder = true,
    },
    widgets = {
        combatIndicator = {
            posX = 0,
            posY = 0,
            scale = 1,
        },
        targetIndicator = {
            enabled = true,
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
    statusText = {
        usePercentage = true,
        alwaysShow = true,
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
    changeFont = true,
    frameFont = "Prototype",
    cdFont  = "Prototype",
    width = 177,
    height = 47,
    powerBarHeight = 9,
    pixelBorderSize = 1,
    drPixelBorderSize = 2,
    mirrored = true,
    classicBars = false,
    replaceClassIcon = true,
    showSpecManaText = true,
    cropIcons = true,

    textSettings = {
        nameAnchor = "LEFT",
        healthAnchor = "RIGHT",
        powerAnchor = "RIGHT",
        specNameAnchor = "LEFT",
    },
}

local function CreatePixelTextureBorder(parent, target, key, size, offset)
    offset = offset or 0
    size = size or 1

    if not parent[key] then
        local holder = CreateFrame("Frame", nil, parent)
        if key == "classIcon" then
            holder:SetFrameLevel(parent:GetFrameLevel() + 8)
        else
            holder:SetFrameLevel(parent:GetFrameLevel() + 1)
        end
        holder:SetIgnoreParentScale(true)
        parent[key] = holder

        local edges = {}
        for i = 1, 4 do
            local tex = holder:CreateTexture(nil, key == "classIcon" and "OVERLAY" or "BORDER", nil, 7)
            tex:SetColorTexture(0,0,0,1)
            tex:SetIgnoreParentScale(true)
            edges[i] = tex
        end
        holder.edges = edges

        function holder:SetVertexColor(r, g, b, a)
            for _, tex in ipairs(self.edges) do
                tex:SetColorTexture(r, g, b, a or 1)
            end
        end
    end

    local holder = parent[key]
    local edges = holder.edges

    local spacing = offset

    holder:ClearAllPoints()
    holder:SetPoint("TOPLEFT", target, "TOPLEFT", -spacing - size, spacing + size)
    holder:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", spacing + size, -spacing - size)

    -- Top
    edges[1]:ClearAllPoints()
    edges[1]:SetPoint("TOPLEFT", holder, "TOPLEFT")
    edges[1]:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    edges[1]:SetHeight(size)

    -- Right
    edges[2]:ClearAllPoints()
    edges[2]:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    edges[2]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT")
    edges[2]:SetWidth(size)

    -- Bottom
    edges[3]:ClearAllPoints()
    edges[3]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
    edges[3]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT")
    edges[3]:SetHeight(size)

    -- Left
    edges[4]:ClearAllPoints()
    edges[4]:SetPoint("TOPLEFT", holder, "TOPLEFT")
    edges[4]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
    edges[4]:SetWidth(size)

    holder:Show()
end


function sArenaFrameMixin:AddPixelBorderToFrame()
    local size = self.parent.db.profile.layoutSettings[layoutName].pixelBorderSize or 1.5
    local drSize = self.parent.db.profile.layoutSettings[layoutName].drPixelBorderSize or 1.5
    local offset = self.parent.db.profile.layoutSettings[layoutName].pixelBorderOffset or 0

    if not self.PixelBorders then
        self.PixelBorders = CreateFrame("Frame", nil, self)
        self.PixelBorders:SetAllPoints()
        self.PixelBorders:SetFrameLevel(self:GetFrameLevel() - 1)
    end

    local borders = self.PixelBorders
    self.PixelBorders.hide = nil

    if self.HealthBar and self.PowerBar then
        local wrapper = borders.mainWrapper
        if not wrapper then
            wrapper = CreateFrame("Frame", nil, borders)
            borders.mainWrapper = wrapper
        end
        wrapper:ClearAllPoints()
        wrapper:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT")
        wrapper:SetPoint("BOTTOMRIGHT", self.PowerBar, "BOTTOMRIGHT")
        CreatePixelTextureBorder(borders, wrapper, "main", size, offset)
    end

    CreatePixelTextureBorder(borders, self.ClassIcon, "classIcon", size, offset)
    CreatePixelTextureBorder(borders, self.Trinket, "trinket", size, offset)
    CreatePixelTextureBorder(borders, self.Racial, "racial", size, offset)
    CreatePixelTextureBorder(borders, self.Dispel, "dispel", size, offset)

    if not self.parent.db.profile.showDispels then
        borders.dispel:Hide()
    end

    CreatePixelTextureBorder(self.SpecIcon, self.SpecIcon, "specIcon", size, offset)
    CreatePixelTextureBorder(self.CastBar, self.CastBar, "castBar", size, offset)
    CreatePixelTextureBorder(self.CastBar, self.CastBar.Icon, "castBarIcon", size, offset)
    self:SetTextureCrop(self.CastBar.Icon, true)

    borders:Show()
end

function sArenaMixin:RemovePixelBorders()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not frame.PixelBorders then
            return
        end

        if frame.PixelBorders then
            frame.PixelBorders:Hide()
            frame.PixelBorders.hide = true
        end

        -- Hide individual borders
        local function hideBorder(parent, key)
            if parent and parent[key] then
                parent[key]:Hide()
            end
        end

        local borders = frame.PixelBorders
        if borders and borders.mainWrapper then
            hideBorder(borders, "main")
        end

        hideBorder(borders, "classIcon")
        hideBorder(borders, "trinket")
        hideBorder(borders, "dispel")
        hideBorder(borders, "racial")
        hideBorder(frame.SpecIcon, "specIcon")
        hideBorder(frame.CastBar, "castBar")
        hideBorder(frame.CastBar, "castBarIcon")

        -- Reset ClassIcon scale
        frame.ClassIcon:SetScale(1)

        -- Reset cast bar icon position
        frame.CastBar.Icon:ClearAllPoints()
        frame.CastBar.Icon:SetPoint("RIGHT", frame.CastBar, "LEFT", -5, 0)
        local newLayout = self.db and self.db.profile and self.db.profile.currentLayout
        local newLayoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[newLayout]
        local newCropIcons = newLayoutSettings and newLayoutSettings.cropIcons or false
        frame:SetTextureCrop(frame.CastBar.Icon, newCropIcons)

        for n = 1, #self.drCategories do
            local drFrame = frame[self.drCategories[n]]
            if drFrame and drFrame.PixelBorder then
                drFrame.PixelBorder:Hide()
                if drFrame.Border then
                    drFrame.Border:Show()
                end
            end
        end
    end

    if self.UpdateCastBarPixelBorders then
        self:UpdateCastBarPixelBorders()
    end
end


local function getSetting(info)
    return layout.db[info[#info]]
end

local function setSetting(info, val)
    layout.db[info[#info]] = val

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        frame:SetSize(layout.db.width, layout.db.height)
        local baseSize = layout.db.height - 4
        frame.ClassIcon:SetSize(baseSize, baseSize)
        local classIconScale = layout.db.classIcon and layout.db.classIcon.scale or 1
        frame.ClassIcon:SetScale(classIconScale)
        frame.DeathIcon:SetSize(layout.db.height * 0.8, layout.db.height * 0.8)
        frame.PowerBar:SetHeight(layout.db.powerBarHeight)
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
        width = "full",
        get = getSetting,
        set = setSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.pixelBorderSize = {
        order = 6,
        name = L["Option_PixelBorderSize"],
        type = "range",
        min = 0.5,
        max = 3,
        step = 0.5,
        get = getSetting,
        set = setSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.pixelBorderOffset = {
        order = 7,
        name = L["Option_PixelBorderOffset"],
        type = "range",
        min = -3,
        max = 3,
        step = 0.5,
        get = getSetting,
        set = setSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.drPixelBorderSize = {
        order = 8,
        name = L["Option_DRPixelBorderSize"],
        type = "range",
        min = 0.5,
        max = 3,
        step = 0.5,
        get = getSetting,
        set = setSetting,
    }

    -- Add classIcon settings specific to Pixelated layout
    layout.optionsTable.classIcon = {
        order = 1.5,
        name = L["Category_ClassIcon"],
        type = "group",
        get = function(info) 
            return layout.db.classIcon[info[#info]] 
        end,
        set = function(info, val)
            layout.db.classIcon[info[#info]] = val
            
            for i = 1, sArenaMixin.maxArenaOpponents do
                local frame = info.handler["arena" .. i]
                layout:UpdateOrientation(frame)
            end
            
            --sArenaMixin:RefreshConfig()
        end,
        args = {
            positioning = {
                order = 1,
                name = L["Positioning"],
                type = "group",
                inline = true,
                args = {
                    posX = {
                        order = 1,
                        name = L["Horizontal"],
                        type = "range",
                        min = -700,
                        max = 700,
                        softMin = -350,
                        softMax = 350,
                        step = 0.1,
                        bigStep = 1,
                    },
                    posY = {
                        order = 2,
                        name = L["Vertical"],
                        type = "range",
                        min = -700,
                        max = 700,
                        softMin = -350,
                        softMax = 350,
                        step = 0.1,
                        bigStep = 1,
                    },
                },
            },
            sizing = {
                order = 2,
                name = L["Sizing"],
                type = "group",
                inline = true,
                args = {
                    scale = {
                        order = 1,
                        name = L["Scale"],
                        type = "range",
                        min = 0.1,
                        max = 5.0,
                        softMin = 0.5,
                        softMax = 2.0,
                        step = 0.01,
                        isPercent = true,
                    },
                },
            },
        },
    }
end

function layout:Initialize(frame)
    self.db = frame.parent.db.profile.layoutSettings[layoutName]
    sArenaMixin.useSpecClassIcon = true

    if (not self.optionsTable) then
        setupOptionsTable(frame.parent)
    end

    frame:AddPixelBorderToFrame()

    if (frame:GetID() == sArenaMixin.maxArenaOpponents) then
        frame.parent:UpdateCastBarSettings(self.db.castBar)
        frame.parent:UpdateDRSettings(self.db.dr)
        frame.parent:UpdateFrameSettings(self.db)
        frame.parent:UpdateSpecIconSettings(self.db.specIcon)
        frame.parent:UpdateTrinketSettings(self.db.trinket)
        frame.parent:UpdateRacialSettings(self.db.racial)
        frame.parent:UpdateDispelSettings(self.db.dispel)
        frame.parent:UpdateWidgetSettings(self.db.widgets)

        for n = 1, #sArenaMixin.drCategories do
            local drFrame = frame[sArenaMixin.drCategories[n]]
            if drFrame and not drFrame.PixelBorder then
                if not drFrame.Border:GetTexture() then
                    drFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress", true)
                end
            end
        end
    end

     --0,0,0,1,1,0,1,1

    frame:SetSize(self.db.width, self.db.height)
    frame.SpecIcon:SetSize(22, 22)
    frame.Trinket:SetSize(41, 41)
    frame.Racial:SetSize(41, 41)
    frame.Dispel:SetSize(41, 41)
    frame.Name:SetTextColor(1,1,1)
    frame.SpecNameText:SetTextColor(1,1,1)
    frame.ClassIcon.Cooldown:SetUseCircularEdge(false)
    frame.ClassIcon.Cooldown:SetSwipeTexture(1)

    frame.Trinket.Cooldown:SetSwipeTexture(1)
    frame.Trinket.Cooldown:SetSwipeColor(0, 0, 0, 0.55)
    frame.Trinket.Cooldown:SetUseCircularEdge(false)

    frame.Racial.Cooldown:SetSwipeTexture(1)
    frame.Racial.Cooldown:SetSwipeColor(0, 0, 0, 0.55)
    frame.Racial.Cooldown:SetUseCircularEdge(false)

    if not frame.Trinket.TrinketPixelBorderHook then
        hooksecurefunc(frame.Trinket.Texture, "SetTexture", function(self, t)
            if not sArenaMixin.showPixelBorder then
                frame.PixelBorders.trinket:Hide()
                return
            end

            if frame.parent.db.profile.colorTrinket then
                if frame.Trinket.spellID == nil then
                    frame.PixelBorders.trinket:Hide()
                    return
                end
                return
            end

            if not t then
                frame.PixelBorders.trinket:Hide()
            else
                frame.PixelBorders.trinket:Show()
            end
        end)

        hooksecurefunc(frame.Trinket.Texture, "SetColorTexture", function(self, r, g, b, a)
            if not sArenaMixin.showPixelBorder then
                frame.PixelBorders.trinket:Hide()
                return
            end

            if not frame.parent.db.profile.colorTrinket then
                return
            end

            if r ~= nil and g ~= nil and b ~= nil then
                if (r == 1 and g == 0 and b == 0) or (r == 0 and g == 1 and b == 0) then
                    frame.PixelBorders.trinket:Show()
                else
                    frame.PixelBorders.trinket:Hide()
                end
            else
                frame.PixelBorders.trinket:Hide()
            end
        end)

        frame.Trinket.TrinketPixelBorderHook = true
    end

    if not frame.Racial.RacialPixelBorderHook then
        hooksecurefunc(frame.Racial.Texture, "SetTexture", function(self, t)
            if not t or not sArenaMixin.showPixelBorder then
                frame.PixelBorders.racial:Hide()
            else
                frame.PixelBorders.racial:Show()
            end
        end)
        frame.Racial.RacialPixelBorderHook = true
    end

    if not frame.Dispel.DispelPixelBorderHook then
        hooksecurefunc(frame.Dispel.Texture, "SetTexture", function(self, t)
            if not frame.parent.db.profile.showDispels or not t or not sArenaMixin.showPixelBorder then
                frame.PixelBorders.dispel:Hide()
            else
                frame.PixelBorders.dispel:Show()
            end
        end)
        hooksecurefunc(frame.Dispel, "Hide", function()
            frame.PixelBorders.dispel:Hide()
        end)
        frame.Dispel.DispelPixelBorderHook = true
    end

    if not frame.parent.db.profile.showDispels then
        frame.PixelBorders.dispel:Hide()
    end

    if not frame.ClassIcon.ClassIconPixelBorderHook then
        hooksecurefunc(frame.ClassIcon.Texture, "SetTexture", function(self, t)
            if not t or not sArenaMixin.showPixelBorder then
                frame.PixelBorders.classIcon:Hide()
            else
                frame.PixelBorders.classIcon:Show()
            end
        end)
        frame.ClassIcon.ClassIconPixelBorderHook = true
    end

    frame.PowerBar:SetHeight(self.db.powerBarHeight)

    local baseSize = self.db.height - 4
    frame.ClassIcon:SetSize(baseSize, baseSize)
    local classIconScale = self.db.classIcon and self.db.classIcon.scale or 1
    frame.ClassIcon:SetScale(classIconScale)
    frame.ClassIcon:Show()

    local f = frame.Name
    f:SetJustifyH("LEFT")
    --f:SetPoint("LEFT", frame.HealthBar, "LEFT", 3, -1)
    f:SetHeight(12)



    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "CENTER", 0, -1)
    f:SetSize(self.db.height * 0.8, self.db.height * 0.8)

    frame.PowerText:SetAlpha(frame.parent.db.profile.hidePowerText and 0 or 1)

    frame.SpecNameText:SetPoint("LEFT", frame.PowerBar, "LEFT", 3, 0)

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
                (w.combatIndicator.posX or 0), (w.combatIndicator.posY or 0))
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
            name:SetPoint("LEFT", frame.HealthBar, "LEFT", 3 + (txt.nameOffsetX or 0), -1 + (txt.nameOffsetY or 0))
        elseif (txt.nameAnchor or "CENTER") == "RIGHT" then
            name:SetPoint("RIGHT", frame.HealthBar, "RIGHT", -3 + (txt.nameOffsetX or 0), -1 + (txt.nameOffsetY or 0))
        else
            name:SetPoint("CENTER", frame.HealthBar, "CENTER", (txt.nameOffsetX or 0), -1 + (txt.nameOffsetY or 0))
        end

        -- Health Text
        healthText:ClearAllPoints()
        if (txt.healthAnchor or "CENTER") == "LEFT" then
            healthText:SetPoint("LEFT", healthBar, "LEFT", 0 + (txt.healthOffsetX or 0), 1 + (txt.healthOffsetY or 0))
        elseif (txt.healthAnchor or "CENTER") == "RIGHT" then
            healthText:SetPoint("RIGHT", healthBar, "RIGHT", 0 + (txt.healthOffsetX or 0), -1 + (txt.healthOffsetY or 0))
        else
            healthText:SetPoint("CENTER", healthBar, "CENTER", (txt.healthOffsetX or 0), -1 + (txt.healthOffsetY or 0))
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
            specName:SetPoint("LEFT", frame.PowerBar, "LEFT", 3 + (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
        elseif (txt.specNameAnchor or "CENTER") == "RIGHT" then
            specName:SetPoint("RIGHT", frame.PowerBar, "RIGHT", -3 + (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
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

    -- Apply classIcon settings
    local classIconSettings = self.db.classIcon or { posX = 0, posY = 0, scale = 1 }
    local baseSize = self.db.height - 4
    frame.ClassIcon:SetSize(baseSize, baseSize)
    frame.ClassIcon:SetScale(classIconSettings.scale or 1)

    if (self.db.mirrored) then
        healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -2)
        healthBar:SetPoint("BOTTOMLEFT", powerBar, "TOPLEFT")
        powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 2)
        powerBar:SetPoint("LEFT", frame, "LEFT", baseSize, 0)

        classIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", (classIconSettings.posX or 0), -2 + (classIconSettings.posY or 0))
    else
        healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
        healthBar:SetPoint("BOTTOMRIGHT", powerBar, "TOPRIGHT")

        powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 2)
        powerBar:SetPoint("RIGHT", frame, "RIGHT", -baseSize, 0)

        classIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", (classIconSettings.posX or 0), -2 + (classIconSettings.posY or 0))
    end
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings