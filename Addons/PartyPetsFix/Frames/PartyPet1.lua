local PPF_PartyPet1 = PPF:NewModule("PPF_PartyPet1")

function PPF_PartyPet1:OnEnable()
    local LSM = LibStub("LibSharedMedia-3.0")
    local Texture = LSM:Fetch('statusbar', PPF_DB.texture)

    -- Create Pet HealthBar
    PPF_P1 = CreateFrame("StatusBar", "PPF_P1", UIParent)

    -- Set Frame Size
    PPF_P1:SetSize(PPF_DB.width, 30)

    -- Create FontString for Pet Name
    PPF_P1.name = PPF_P1:CreateFontString(nil)
    PPF_P1.name:SetFont(STANDARD_TEXT_FONT, 10, "")
    PPF_P1.name:SetPoint("LEFT", PPF_P1, "LEFT", 5, 0)
    PPF_P1.name:SetShadowOffset(1,-1)

    -- Set Bar Texture & Color
    PPF_P1:SetStatusBarTexture(Texture)
    PPF_P1:GetStatusBarTexture():SetDrawLayer("ARTWORK", 5)
    if PPF_DB.classcolor then
        local _, class = UnitClass("party1")
        local class_r, class_g, class_b = GetClassColor(class)
        PPF_P1:SetStatusBarColor(class_r, class_g, class_b)
    else
        PPF_P1:SetStatusBarColor(0, 1, 0)
    end

    -- Set Background
    PPF_P1.background = PPF_P1:CreateTexture()
    PPF_P1.background:SetAllPoints(PPF_P1)
    PPF_P1.background:SetTexture([[Interface\RaidFrame\Raid-Bar-Hp-Bg]])
    PPF_P1.background:SetDrawLayer("BACKGROUND", -1)
    PPF_P1.background:SetTexCoord(0, 1, 0, 0.53125)

    -- Set Border
    PPF_P1.border = PPF_P1:CreateTexture()
    PPF_P1.border:SetAllPoints(PPF_P1)
    PPF_P1.border:SetTexture([[Interface\RaidFrame\Raid-FrameHighlights]])
    PPF_P1.border:SetTexCoord(0.00781250, 0.55468750, 0.28906250, 0.55468750)
    PPF_P1.border:SetDrawLayer("ARTWORK", 7)
    PPF_P1.border:Hide()

    -- Set MinMax Values
    PPF_P1:SetMinMaxValues(0, UnitHealthMax("partypet1"))

    -- Create Button for Pet Healthbar
    PPF_P1Button = CreateFrame("Button", "CPPFets_PlayerPetButton", PPF_P1, "SecureUnitButtonTemplate")

    -- Set Button Position
    PPF_P1Button:SetPoint("CENTER")
    PPF_P1Button:SetSize(PPF_DB.width, 30)

    -- Set Button Attribute
    PPF_P1Button:SetAttribute("unit", "partypet1")

    -- Register Button and Click Events
    RegisterUnitWatch(PPF_P1Button)
    PPF_P1Button:RegisterForClicks("AnyUp")

    -- Register Clicks
    PPF_P1Button:SetAttribute("*type1", "target") -- Target unit on left click
    PPF_P1Button:SetAttribute("*type2", "togglemenu") -- Toggle units menu on left click
    PPF_P1Button:SetAttribute("*type3", "assist") -- On middle click, target the target of the clicked unit

    -- Register Events
    PPF_P1:RegisterEvent("UNIT_HEALTH")
    PPF_P1:RegisterEvent("UNIT_MAXHEALTH")
    PPF_P1:RegisterEvent("PLAYER_TARGET_CHANGED")

    PPF_P1:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_TARGET_CHANGED" then
            PPF:ShowBorder(PPF_P1, "partypet1")
        else
            PPF:UpdateHealth(PPF_P1, "partypet1")
            PPF_P1:SetMinMaxValues(0, UnitHealthMax("partypet1"))
        end
    end)
end