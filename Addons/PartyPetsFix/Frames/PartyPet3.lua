local PPF_PartyPet3 = PPF:NewModule("PPF_PartyPet3")

function PPF_PartyPet3:OnEnable()
    local LSM = LibStub("LibSharedMedia-3.0")
    local Texture = LSM:Fetch('statusbar', PPF_DB.texture)

    -- Create Pet HealthBar
    PPF_P3 = CreateFrame("StatusBar", "PPF_P3", UIParent)

    -- Set Frame Size
    PPF_P3:SetSize(PPF_DB.width, 30)

    -- Create FontString for Pet Name
    PPF_P3.name = PPF_P3:CreateFontString(nil)
    PPF_P3.name:SetFont(STANDARD_TEXT_FONT, 10, "")
    PPF_P3.name:SetPoint("LEFT", PPF_P3, "LEFT", 5, 0)
    PPF_P3.name:SetShadowOffset(1,-1)

    -- Set Bar Texture & Color
    PPF_P3:SetStatusBarTexture(Texture)
    PPF_P3:GetStatusBarTexture():SetDrawLayer("ARTWORK", 5)
    if PPF_DB.classcolor then
        local _, class = UnitClass("party3")
        local class_r, class_g, class_b = GetClassColor(class)
        PPF_P3:SetStatusBarColor(class_r, class_g, class_b)
    else
        PPF_P3:SetStatusBarColor(0, 1, 0)
    end

    -- Set Background
    PPF_P3.background = PPF_P3:CreateTexture()
    PPF_P3.background:SetAllPoints(PPF_P3)
    PPF_P3.background:SetTexture([[Interface\RaidFrame\Raid-Bar-Hp-Bg]])
    PPF_P3.background:SetDrawLayer("BACKGROUND", -1)
    PPF_P3.background:SetTexCoord(0, 1, 0, 0.53125)

    -- Set Border
    PPF_P3.border = PPF_P3:CreateTexture()
    PPF_P3.border:SetAllPoints(PPF_P3)
    PPF_P3.border:SetTexture([[Interface\RaidFrame\Raid-FrameHighlights]])
    PPF_P3.border:SetTexCoord(0.00781250, 0.55468750, 0.28906250, 0.55468750)
    PPF_P3.border:SetDrawLayer("ARTWORK", 7)
    PPF_P3.border:Hide()

    -- Set MinMax Values
    PPF_P3:SetMinMaxValues(0, UnitHealthMax("partypet3"))

    -- Create Button for Pet Healthbar
    PPF_P3Button = CreateFrame("Button", "CPPFets_PlayerPetButton", PPF_P3, "SecureUnitButtonTemplate")

    -- Set Button Position
    PPF_P3Button:SetPoint("CENTER")
    PPF_P3Button:SetSize(PPF_DB.width, 30)

    -- Set Button Attribute
    PPF_P3Button:SetAttribute("unit", "partypet3")

    -- Register Button and Click Events
    RegisterUnitWatch(PPF_P3Button)
    PPF_P3Button:RegisterForClicks("AnyUp")

    -- Register Clicks
    PPF_P3Button:SetAttribute("*type1", "target") -- Target unit on left click
    PPF_P3Button:SetAttribute("*type2", "togglemenu") -- Toggle units menu on left click
    PPF_P3Button:SetAttribute("*type3", "assist") -- On middle click, target the target of the clicked unit

    -- Register Events
    PPF_P3:RegisterEvent("UNIT_HEALTH")
    PPF_P3:RegisterEvent("UNIT_MAXHEALTH")
    PPF_P3:RegisterEvent("PLAYER_TARGET_CHANGED")

    PPF_P3:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_TARGET_CHANGED" then
            PPF:ShowBorder(PPF_P3, "partypet3")
        else
            PPF:UpdateHealth(PPF_P3, "partypet3")
            PPF_P3:SetMinMaxValues(0, UnitHealthMax("partypet3"))
        end
    end)
end