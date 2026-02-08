local PPF_PetPet = PPF:NewModule("PPF_PetPet")

function PPF_PetPet:OnEnable()
    local LSM = LibStub("LibSharedMedia-3.0")
    local Texture = LSM:Fetch('statusbar', PPF_DB.texture)

    -- Create Pet HealthBar
    PPF_Pet = CreateFrame("StatusBar", "PPF_Pet", UIParent)

    -- Set Frame Position & Size 
    PPF_Pet:SetSize(PPF_DB.width, 30)

    -- Create FontString for Pet Name
    PPF_Pet.name = PPF_Pet:CreateFontString(nil)
    PPF_Pet.name:SetFont(STANDARD_TEXT_FONT, 10, "")
    PPF_Pet.name:SetPoint("LEFT", PPF_Pet, "LEFT", 5, 0)
    PPF_Pet.name:SetShadowOffset(1, -1)

    -- Set Bar Texture & Color
    PPF_Pet:SetStatusBarTexture(Texture)
    PPF_Pet:GetStatusBarTexture():SetDrawLayer("ARTWORK", 5)
    if PPF_DB.classcolor then
        local _, class = UnitClass("player")
        local class_r, class_g, class_b = GetClassColor(class)
        PPF_Pet:SetStatusBarColor(class_r, class_g, class_b)
    else
        PPF_Pet:SetStatusBarColor(0, 1, 0)
    end

    -- Set Background
    PPF_Pet.background = PPF_Pet:CreateTexture()
    PPF_Pet.background:SetAllPoints(PPF_Pet)
    PPF_Pet.background:SetTexture([[Interface\RaidFrame\Raid-Bar-Hp-Bg]])
    PPF_Pet.background:SetDrawLayer("BACKGROUND", -1)
    PPF_Pet.background:SetTexCoord(0, 1, 0, 0.53125)

    -- Set Border
    PPF_Pet.border = PPF_Pet:CreateTexture()
    PPF_Pet.border:SetAllPoints(PPF_Pet)
    PPF_Pet.border:SetTexture([[Interface\RaidFrame\Raid-FrameHighlights]])
    PPF_Pet.border:SetTexCoord(0.00781250, 0.55468750, 0.28906250, 0.55468750)
    PPF_Pet.border:SetDrawLayer("ARTWORK", 7)
    PPF_Pet.border:Hide()

    -- Set MinMax Values
    PPF_Pet:SetMinMaxValues(0, UnitHealthMax("pet"))

    -- Create Button for Pet Healthbar
    PPF_PetButton = CreateFrame("Button", "PPF_PetButton", PPF_Pet, "SecureUnitButtonTemplate")

    -- Set Button Position
    PPF_PetButton:SetPoint("CENTER")
    PPF_PetButton:SetSize(PPF_DB.width, 30)

    -- Set Button Attribute
    PPF_PetButton:SetAttribute("unit", "pet")

    -- Register Button and Click Events
    RegisterUnitWatch(PPF_PetButton)
    PPF_PetButton:RegisterForClicks("AnyUp")

    -- Register Clicks
    PPF_PetButton:SetAttribute("*type1", "target") -- Target unit on left click
    PPF_PetButton:SetAttribute("*type2", "togglemenu") -- Toggle units menu on left click
    PPF_PetButton:SetAttribute("*type3", "assist") -- On middle click, target the target of the clicked unit

    -- Register Events
    PPF_Pet:RegisterEvent("UNIT_HEALTH")
    PPF_Pet:RegisterEvent("UNIT_MAXHEALTH")
    PPF_Pet:RegisterEvent("PLAYER_TARGET_CHANGED")

    PPF_Pet:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_TARGET_CHANGED" then
            PPF:ShowBorder(PPF_Pet, "pet")
        else
            PPF:UpdateHealth(PPF_Pet, "pet")
            PPF_Pet:SetMinMaxValues(0, UnitHealthMax("pet"))
        end
    end)
end