local layoutName = "Blizz Modern"
local layout = {}
layout.name = "|cff00b4ffBlizz|r Modern by |cffFF7C0AMalithorn|r"

layout.defaultSettings = {
    posX = 400,
    posY = 120,
    scale = 1.1,
    classIconFontSize = 16,
    spacing = 20,
    growthDirection = 1,
    specIcon = {
        posX = 60,
        posY = 28,
        scale = 0.6,
    },
    trinket = {
        posX = 80,
        posY = 23,
        scale = 1,
        fontSize = 12,
    },
    racial = {
        posX = 89,
        posY = -19,
        scale = 1,
        fontSize = 12,
    },
    castBar = {
        posX = -165,
        posY = -6,
        scale = 1,
        width = 120,
    },
    dr = {
        posX = -112,
        posY = 13,
        size = 20,
        borderSize = 1,
        fontSize = 12,
        spacing = 3,
        growthDirection = 4,
    },

    -- custom layout settings
    mirrored = false,
}

local function getSetting(info)
    return layout.db[info[#info]]
end

local function setSetting(info, val)
    layout.db[info[#info]] = val

    for i = 1, 3 do
        local frame = info.handler["arena" .. i]
        layout:UpdateOrientation(frame)
    end
end

local function setupOptionsTable(self)
    layout.optionsTable = self:GetLayoutOptionsTable(layoutName)

    layout.optionsTable.arenaFrames.args.positioning.args.mirrored = {
        order = 5,
        name = "Mirrored Frames",
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

    if (frame:GetID() == 3) then
        frame.parent:UpdateCastBarSettings(self.db.castBar)
        frame.parent:UpdateDRSettings(self.db.dr)
        frame.parent:UpdateFrameSettings(self.db)
        frame.parent:UpdateSpecIconSettings(self.db.specIcon)
        frame.parent:UpdateTrinketSettings(self.db.trinket)
        frame.parent:UpdateRacialSettings(self.db.racial)
    end

    frame:SetSize(195, 67)
	
	-- some reused variables
    local healthBar = frame.HealthBar
	local powerBar = frame.PowerBar
    local f = frame.ClassIcon

    -- text adjustments
	local healthText = frame.HealthText
    healthText:SetPoint("CENTER", healthBar)
    healthText:SetShadowOffset(0, 0)
    healthText:SetDrawLayer("OVERLAY", 4)
	
	local powerText = frame.PowerText
    powerText:SetPoint("CENTER", powerBar)
    powerText:SetShadowOffset(0, 0)
    powerText:SetDrawLayer("OVERLAY", 4)
	
	local playerName = frame.Name
    playerName:SetJustifyH("LEFT")
    playerName:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2, 2)
    playerName:SetPoint("BOTTOMRIGHT", healthBar, "TOPRIGHT", -2, 2)
    playerName:SetHeight(12)

    -- portrait icon
    frame.ClassIconCooldown:SetSwipeTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    frame.ClassIconCooldown:SetUseCircularEdge(true)
    f:SetSize(60, 60)
    f:Show()
    f:AddMaskTexture(frame.ClassIconMask)
    frame.ClassIconMask:SetAllPoints(f)
    frame.ClassIconMask:SetSize(60, 60)

    -- trinket
	local trinket = frame.Trinket
    local trinketBorder = frame.TexturePool:Acquire()
    trinket.Texture:SetMask("Interface\\masks\\circlemaskscalable")
    trinket.Cooldown:SetSwipeTexture("Interface\\masks\\circlemaskscalable")
    trinket.Cooldown:SetUseCircularEdge(true)
    trinket:SetSize(25, 25)
    trinketBorder:SetParent(trinket)
    trinketBorder:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Boss-IconRing")
    trinketBorder:SetPoint("TOPLEFT", trinket, "TOPLEFT", -4, 4)
    trinketBorder:SetPoint("BOTTOMRIGHT", trinket, "BOTTOMRIGHT", 4, -4)
    trinketBorder:SetDrawLayer("ARTWORK", 3)
    trinketBorder:Show()

    -- racial
	local racial = frame.Racial
    local racialBorder = frame.TexturePool:Acquire()
    racial.Texture:SetMask("Interface\\masks\\circlemaskscalable")
    racial.Cooldown:SetSwipeTexture("Interface\\masks\\circlemaskscalable")
    racial.Cooldown:SetUseCircularEdge(true)
    racial:SetSize(25, 25)    
    racialBorder:SetParent(racial)
    racialBorder:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Boss-IconRing")
    racialBorder:SetPoint("TOPLEFT", racial, "TOPLEFT", -4, 4)
    racialBorder:SetPoint("BOTTOMRIGHT", racial, "BOTTOMRIGHT", 4, -4)
	racialBorder:SetDrawLayer("ARTWORK", 3)
    racialBorder:Show()

    -- spec icon
	local specBorder = frame.TexturePool:Acquire()
    frame.SpecIcon:SetSize(25, 25)
    frame.SpecIcon.Texture:AddMaskTexture(frame.SpecIcon.Mask)
    specBorder:SetParent(frame.SpecIcon)
    specBorder:SetDrawLayer("ARTWORK", 3)
    specBorder:SetAtlas("UI-HUD-UnitFrame-TotemFrame")
    specBorder:SetPoint("TOPLEFT", frame.SpecIcon, "TOPLEFT", -3, 3)
    specBorder:SetPoint("BOTTOMRIGHT", frame.SpecIcon, "BOTTOMRIGHT", 6, -6)
    specBorder:Show()

	-- castbar
    local CastBarBackground = frame.TexturePool:Acquire()
    local CastBarBorder = frame.TexturePool:Acquire()
    f = frame.CastBar
    f:SetHeight(8)
    f.Text:ClearAllPoints()
    f.Text:SetPoint("BOTTOM", frame.CastBar, 0, -12)
    f.Text:SetScale(0.9)
    f.Icon:ClearAllPoints()
    f.Icon:SetPoint("LEFT", frame.CastBar, -18, -5)
    f.Icon:SetScale(1.1)
    f.BorderShield:ClearAllPoints()
    f.BorderShield:SetPoint("LEFT", f.Icon, -6, 0)
    f.BorderShield:SetScale(1.1)
    CastBarBackground:SetParent(frame.CastBar)
    CastBarBackground:SetDrawLayer("BACKGROUND", 3)
    CastBarBackground:SetAtlas("UI-CastingBar-TextBox")
    CastBarBackground:SetPoint("TOPLEFT", frame.CastBar, "TOPLEFT", 0, -6)
    CastBarBackground:SetPoint("BOTTOMRIGHT", frame.CastBar, "BOTTOMRIGHT", 0, -11)
    CastBarBackground:Show()
    CastBarBorder:SetParent(frame.CastBar)
    CastBarBorder:SetDrawLayer("OVERLAY", 3)
    CastBarBorder:SetAtlas("UI-CastingBar-Frame")
    CastBarBorder:SetPoint("TOPLEFT", frame.CastBar, "TOPLEFT", -1, 2)
    CastBarBorder:SetPoint("BOTTOMRIGHT", frame.CastBar, "BOTTOMRIGHT", 1, -2)
    CastBarBorder:Show()
    local typeInfoTexture = "ui-castingbar-tier4-empower-2x";
    f:SetStatusBarTexture(typeInfoTexture)
    f.typeInfo = {
        filling = typeInfoTexture,
        full = typeInfoTexture,
        glow = typeInfoTexture
    }

    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "CENTER")
    f:SetSize(26, 26)

    local underlay = frame.TexturePool:Acquire()
    underlay:SetDrawLayer("BACKGROUND", 1)
    underlay:SetColorTexture(0, 0, 0, 0.5)
    underlay:SetPoint("TOPLEFT", healthBar)
    underlay:SetPoint("BOTTOMRIGHT", powerBar)
    underlay:Show()

    local id = frame:GetID()
    layout["frameTexture" .. id] = frame.TexturePool:Acquire()
    local frameTexture = layout["frameTexture" .. id]
    frameTexture:SetDrawLayer("ARTWORK", 3)
    frameTexture:SetAllPoints(frame)
    frameTexture:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn")
    frameTexture:Show()

    self:UpdateOrientation(frame)
end

function layout:UpdateOrientation(frame)
    local frameTexture = layout["frameTexture" .. frame:GetID()]
    local healthBar = frame.HealthBar
	local powerBar = frame.PowerBar
    local classIcon = frame.ClassIcon

    healthBar:ClearAllPoints()
	powerBar:ClearAllPoints()
    classIcon:ClearAllPoints()

    if (self.db.mirrored) then
        frameTexture:SetTexCoord(1, 0, 0, 1)
		healthBar:SetSize(126, 19)
		healthBar:SetStatusBarTexture("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Status")
        healthBar:GetStatusBarTexture():SetDrawLayer("OVERLAY", 3)
        healthBar:SetPoint("TOPRIGHT", -3, -24)
		powerBar:SetSize(136, 9)
		powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", -8, -2)
		powerBar:SetStatusBarTexture("UI-HUD-UnitFrame-Party-PortraitOn-Bar-Mana-Status")
		powerBar:GetStatusBarTexture():SetDrawLayer("OVERLAY", 3)
		classIcon:SetPoint("TOPLEFT", 6, -2)
    else
		frameTexture:SetTexCoord(0, 1, 0, 1)
		healthBar:SetSize(128, 19)
		healthBar:SetStatusBarTexture("UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health-Status")
		healthBar:GetStatusBarTexture():SetDrawLayer("OVERLAY", 3)
        healthBar:SetPoint("TOPLEFT", 3, -24)
		powerBar:SetSize(136, 9)
		powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -2)
		powerBar:SetStatusBarTexture("UI-HUD-UnitFrame-Target-PortraitOn-Bar-Mana-Status")
		powerBar:GetStatusBarTexture():SetDrawLayer("OVERLAY", 3)
        classIcon:SetPoint("TOPRIGHT", -6, -2)
    end
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings
