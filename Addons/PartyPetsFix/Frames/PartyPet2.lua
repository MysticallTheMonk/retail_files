local PPF_PartyPet2 = PPF:NewModule("PPF_PartyPet2")

function PPF_PartyPet2:OnEnable()
    local LSM = LibStub("LibSharedMedia-3.0")
    local Texture = LSM:Fetch('statusbar', PPF_DB.texture)

    -- Create Pet HealthBar
    PPF_P2 = CreateFrame("StatusBar", "PPF_P2", UIParent)

    -- Set Frame Size
    PPF_P2:SetSize(PPF_DB.width, 30)

    -- Create FontString for Pet Name
    PPF_P2.name = PPF_P2:CreateFontString(nil)
    PPF_P2.name:SetFont(STANDARD_TEXT_FONT, 10, "")
    PPF_P2.name:SetPoint("LEFT", PPF_P2, "LEFT", 5, 0)
    PPF_P2.name:SetShadowOffset(1,-1)

    -- Set Bar Texture & Color
    PPF_P2:SetStatusBarTexture(Texture)
    PPF_P2:GetStatusBarTexture():SetDrawLayer("ARTWORK", 5)
    if PPF_DB.classcolor then
        local _, class = UnitClass("party2")
        local class_r, class_g, class_b = GetClassColor(class)
        PPF_P2:SetStatusBarColor(class_r, class_g, class_b)
    else
        PPF_P2:SetStatusBarColor(0, 1, 0)
    end

    -- Set Background
    PPF_P2.background = PPF_P2:CreateTexture()
    PPF_P2.background:SetAllPoints(PPF_P2)
    PPF_P2.background:SetTexture([[Interface\RaidFrame\Raid-Bar-Hp-Bg]])
    PPF_P2.background:SetDrawLayer("BACKGROUND", -1)
    PPF_P2.background:SetTexCoord(0, 1, 0, 0.53125)

    -- Set Border
    PPF_P2.border = PPF_P2:CreateTexture()
    PPF_P2.border:SetAllPoints(PPF_P2)
    PPF_P2.border:SetTexture([[Interface\RaidFrame\Raid-FrameHighlights]])
    PPF_P2.border:SetTexCoord(0.00781250, 0.55468750, 0.28906250, 0.55468750)
    PPF_P2.border:SetDrawLayer("ARTWORK", 7)
    PPF_P2.border:Hide()

    -- Set MinMax Values
    PPF_P2:SetMinMaxValues(0, UnitHealthMax("partypet2"))

    -- Create Button for Pet Healthbar
    PPF_P2Button = CreateFrame("Button", "CPPFets_PlayerPetButton", PPF_P2, "SecureUnitButtonTemplate")

    -- Set Button Position
    PPF_P2Button:SetPoint("CENTER")
    PPF_P2Button:SetSize(PPF_DB.width, 30)

    -- Set Button Attribute
    PPF_P2Button:SetAttribute("unit", "partypet2")

    -- Register Button and Click Events
    RegisterUnitWatch(PPF_P2Button)
    PPF_P2Button:RegisterForClicks("AnyUp")

    -- Register Clicks
    PPF_P2Button:SetAttribute("*type1", "target") -- Target unit on left click
    PPF_P2Button:SetAttribute("*type2", "togglemenu") -- Toggle units menu on left click
    PPF_P2Button:SetAttribute("*type3", "assist") -- On middle click, target the target of the clicked unit

    -- Register Events
    PPF_P2:RegisterEvent("UNIT_HEALTH")
    PPF_P2:RegisterEvent("UNIT_MAXHEALTH")
    PPF_P2:RegisterEvent("PLAYER_TARGET_CHANGED")

    PPF_P2:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_TARGET_CHANGED" then
            PPF:ShowBorder(PPF_P2, "partypet2")
        else
            PPF:UpdateHealth(PPF_P2, "partypet2")
            PPF_P2:SetMinMaxValues(0, UnitHealthMax("partypet2"))
        end
    end)
end