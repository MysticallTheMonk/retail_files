local PPF_PartyPet4 = PPF:NewModule("PPF_PartyPet4")

function PPF_PartyPet4:OnEnable()
    local LSM = LibStub("LibSharedMedia-3.0")
    local Texture = LSM:Fetch('statusbar', PPF_DB.texture)

    -- Create Pet HealthBar
    PPF_P4 = CreateFrame("StatusBar", "PPF_P4", UIParent)

    -- Set Frame Size
    PPF_P4:SetSize(PPF_DB.width, 30)

    -- Create FontString for Pet Name
    PPF_P4.name = PPF_P4:CreateFontString(nil)
    PPF_P4.name:SetFont(STANDARD_TEXT_FONT, 10, "")
    PPF_P4.name:SetPoint("LEFT", PPF_P4, "LEFT", 5, 0)
    PPF_P4.name:SetShadowOffset(1,-1)

    -- Set Bar Texture & Color
    PPF_P4:SetStatusBarTexture(Texture)
    PPF_P4:GetStatusBarTexture():SetDrawLayer("ARTWORK", 5)
    if PPF_DB.classcolor then
        local _, class = UnitClass("party4")
        local class_r, class_g, class_b = GetClassColor(class)
        PPF_P4:SetStatusBarColor(class_r, class_g, class_b)
    else
        PPF_P4:SetStatusBarColor(0, 1, 0)
    end

    -- Set Background
    PPF_P4.background = PPF_P4:CreateTexture()
    PPF_P4.background:SetAllPoints(PPF_P4)
    PPF_P4.background:SetTexture([[Interface\RaidFrame\Raid-Bar-Hp-Bg]])
    PPF_P4.background:SetDrawLayer("BACKGROUND", -1)
    PPF_P4.background:SetTexCoord(0, 1, 0, 0.53125)

    -- Set Border
    PPF_P4.border = PPF_P4:CreateTexture()
    PPF_P4.border:SetAllPoints(PPF_P4)
    PPF_P4.border:SetTexture([[Interface\RaidFrame\Raid-FrameHighlights]])
    PPF_P4.border:SetTexCoord(0.00781250, 0.55468750, 0.28906250, 0.55468750)
    PPF_P4.border:SetDrawLayer("ARTWORK", 7)
    PPF_P4.border:Hide()

    -- Set MinMax Values
    PPF_P4:SetMinMaxValues(0, UnitHealthMax("partypet4"))

    -- Create Button for Pet Healthbar
    PPF_P4Button = CreateFrame("Button", "CPPFets_PlayerPetButton", PPF_P4, "SecureUnitButtonTemplate")

    -- Set Button Position
    PPF_P4Button:SetPoint("CENTER")
    PPF_P4Button:SetSize(PPF_DB.width, 30)

    -- Set Button Attribute
    PPF_P4Button:SetAttribute("unit", "partypet4")

    -- Register Button and Click Events
    RegisterUnitWatch(PPF_P4Button)
    PPF_P4Button:RegisterForClicks("AnyUp")

    -- Register Clicks
    PPF_P4Button:SetAttribute("*type1", "target") -- Target unit on left click
    PPF_P4Button:SetAttribute("*type2", "togglemenu") -- Toggle units menu on left click
    PPF_P4Button:SetAttribute("*type3", "assist") -- On middle click, target the target of the clicked unit

    -- Register Events
    PPF_P4:RegisterEvent("UNIT_HEALTH")
    PPF_P4:RegisterEvent("UNIT_MAXHEALTH")
    PPF_P4:RegisterEvent("PLAYER_TARGET_CHANGED")

    PPF_P4:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_TARGET_CHANGED" then
            PPF:ShowBorder(PPF_P4, "partypet4")
        else
            PPF:UpdateHealth(PPF_P4, "partypet4")
            PPF_P4:SetMinMaxValues(0, UnitHealthMax("partypet4"))
        end
    end)
end