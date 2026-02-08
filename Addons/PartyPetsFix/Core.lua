PPF_Core = PPF:NewModule("PPF_Core")

function PPF_Core:OnEnable()
    local function IsInParty()
        return GetNumGroupMembers() > 0 and not IsInRaid()
    end

    function PPF:OnEvent()
        if InCombatLockdown() then return end

        local inInstance, instanceType = IsInInstance()
        if PPF_Disabled() then
            PPF_Pet:Hide()
            PPF_PetButton:Hide()

            PPF_P1:Hide()
            PPF_P1Button:Hide()

            PPF_P2:Hide()
            PPF_P2Button:Hide()

            PPF_P3:Hide()
            PPF_P3Button:Hide()

            PPF_P4:Hide()
            PPF_P4Button:Hide()
        elseif IsInParty() or (inInstance and instanceType == 'arena') then
            local frames = { CompactPartyFrame:GetChildren() }
            local anchor = nil

            for i, frame in ipairs(frames) do
                if frame.unit and frame:IsVisible() and (not anchor or frame:GetBottom() < anchor:GetBottom()) then
                    anchor = frame
                end
            end

            if UnitExists("pet") then

                PPF_Pet:SetPoint("LEFT", anchor, "LEFT", PPF_DB.positionx, PPF_DB.positiony)
                PPF_Pet.name:SetText(UnitName("pet"))

                -- Show frames if they got hidden earlier
                PPF_Pet:Show()
                PPF_PetButton:Show()
            elseif PPF_Pet:IsShown() and not UnitExists("pet") then
                PPF_Pet:Hide()
                PPF_PetButton:Hide()
            end

            if UnitExists("partypet1") then
                -- Set Position
                if UnitExists("pet") then
                    PPF_P1:SetPoint("LEFT", PPF_Pet, "LEFT", 0, -30.5)
                else
                    PPF_P1:SetPoint("LEFT", anchor, "LEFT", PPF_DB.positionx, PPF_DB.positiony)
                end

                -- Set Name
                PPF_P1.name:SetText(UnitName("partypet1"))

                -- Show frames if they got hidden earlier
                PPF_P1:Show()
                PPF_P1Button:Show()
            elseif PPF_P1:IsShown() and not UnitExists("partypet1") then
                PPF_P1:Hide()
                PPF_P1Button:Hide()
            end

            if UnitExists("partypet2") then
                -- Set Position
                if UnitExists("partypet1") then
                    PPF_P2:SetPoint("LEFT", PPF_P1, "LEFT", 0, -30.5)
                elseif UnitExists("pet") then
                    PPF_P2:SetPoint("LEFT", PPF_Pet, "LEFT", 0, -30.5)
                else
                    PPF_P2:SetPoint("LEFT", anchor, "LEFT", PPF_DB.positionx, PPF_DB.positiony)
                end

                -- Set Name
                PPF_P2.name:SetText(UnitName("partypet2"))

                -- Show frames if they got hidden earlier
                PPF_P2:Show()
                PPF_P2Button:Show()
            elseif PPF_P2:IsShown() and not UnitExists("partypet2") then
                PPF_P2:Hide()
                PPF_P2Button:Hide()
            end

            if UnitExists("partypet3") then
                -- Set Position
                if UnitExists("partypet2") then
                    PPF_P3:SetPoint("LEFT", PPF_P2, "LEFT", 0, -30.5)
                elseif UnitExists("partypet1") then
                    PPF_P3:SetPoint("LEFT", PPF_P1, "LEFT", 0, -30.5)
                elseif UnitExists("pet") then
                    PPF_P3:SetPoint("LEFT", PPF_Pet, "LEFT", 0, -30.5)
                else
                    PPF_P3:SetPoint("LEFT", anchor, "LEFT", PPF_DB.positionx, PPF_DB.positiony)
                end

                -- Set Name
                PPF_P3.name:SetText(UnitName("partypet3"))

                -- Show frames if they got hidden earlier
                PPF_P3:Show()
                PPF_P3Button:Show()
            elseif PPF_P3:IsShown() and not UnitExists("partypet3") then
                PPF_P3:Hide()
                PPF_P3Button:Hide()
            end

            if UnitExists("partypet4") then
                -- Set Position
                if UnitExists("partypet3") then
                    PPF_P4:SetPoint("LEFT", PPF_P3, "LEFT", 0, -30.5)
                elseif UnitExists("partypet2") then
                    PPF_P4:SetPoint("LEFT", PPF_P2, "LEFT", 0, -30.5)
                elseif UnitExists("partypet1") then
                    PPF_P4:SetPoint("LEFT", PPF_P1, "LEFT", 0, -30.5)
                elseif UnitExists("pet") then
                    PPF_P4:SetPoint("LEFT", PPF_Pet, "LEFT", 0, -30.5)
                else
                    PPF_P4:SetPoint("LEFT", anchor, "LEFT", PPF_DB.positionx, PPF_DB.positiony)
                end

                -- Set Name
                PPF_P4.name:SetText(UnitName("partypet4"))

                -- Show frames if they got hidden earlier
                PPF_P4:Show()
                PPF_P4Button:Show()
            elseif PPF_P4:IsShown() and not UnitExists("partypet4") then
                PPF_P4:Hide()
                PPF_P4Button:Hide()
            end
        else
            PPF_Pet:Hide()
            PPF_PetButton:Hide()

            PPF_P1:Hide()
            PPF_P1Button:Hide()

            PPF_P2:Hide()
            PPF_P2Button:Hide()

            PPF_P3:Hide()
            PPF_P3Button:Hide()

            PPF_P4:Hide()
            PPF_P4Button:Hide()
        end
    end

    -- Create Border

    function PPF:ShowBorder(frame, unit)
        if UnitIsUnit("target", unit) then
            frame.border:Show()
        else
            frame.border:Hide()
        end
    end

    function PPF:UpdateHealth(frame, unit)
        frame:SetValue(UnitHealth(unit))
    end

    function PPF_Disabled()
        if PPF_DB.enabled then
            return false
        else
            return true
        end
    end

    -- Register Events
    PPF:RegisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")
    PPF:RegisterEvent("UNIT_CONNECTION", "OnEvent")
    PPF:RegisterEvent("UNIT_AREA_CHANGED", "OnEvent")
    PPF:RegisterEvent("UNIT_PHASE", "OnEvent")
    PPF:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
    PPF:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
    PPF:RegisterEvent("PLAYER_LOGIN", "OnEvent")

    -- Small Delay to dodge errors
    C_Timer.After(0.5, function()
        PPF:RegisterEvent("UNIT_PET", "OnEvent")
    end)
end
