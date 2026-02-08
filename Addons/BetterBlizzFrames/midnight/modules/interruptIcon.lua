if not BBF.isMidnight then return end
local interruptSpells = {
    1766,   -- Kick (Rogue)
    2139,   -- Counterspell (Mage)
    6552,   -- Pummel (Warrior)
    19647,  -- Spell Lock (Warlock)
    47528,  -- Mind Freeze (Death Knight)
    57994,  -- Wind Shear (Shaman)
    96231,  -- Rebuke (Paladin)
    106839, -- Skull Bash (Feral)
    115781, -- Optical Blast (Warlock)
    116705, -- Spear Hand Strike (Monk)
    132409, -- Spell Lock (Warlock)
    119910, -- Spell Lock (Warlock Pet)
    89766,  -- Axe Toss (Warlock Pet)
    171138, -- Shadow Lock (Warlock)
    147362, -- Countershot (Hunter)
    183752, -- Disrupt (Demon Hunter)
    187707, -- Muzzle (Hunter)
    212619, -- Call Felhunter (Warlock)
    351338, -- Quell (Evoker)
}

local function GetInterruptSpell()
    for _, spellID in ipairs(interruptSpells) do
        if IsSpellKnownOrOverridesKnown(spellID) or (UnitExists("pet") and IsSpellKnownOrOverridesKnown(spellID, true)) then
            return spellID
        end
    end
    return nil
end

local playerKick = GetInterruptSpell()

-- Recheck interrupt spells when lock resummons/sacrifices pet
local petSummonSpells = {
    [30146]  = true, -- Summon Demonic Tyrant (Demonology)
    [691]    = true, -- Summon Felhunter (for Spell Lock)
    [108503] = true, -- Grimoire of Sacrifice
}

BBF.interruptTrackingIcon = CreateFrame("Frame")
BBF.interruptTrackingIcon.cooldown = CreateFrame("Cooldown", nil, BBF.interruptTrackingIcon, "CooldownFrameTemplate")
BBF.interruptTrackingIcon.cooldown:HookScript("OnCooldownDone", function()
    BBF.playerKickReady = true
end)
BBF.playerKickReady = true

local function UpdateInterruptTracking()
    if not playerKick then
        playerKick = GetInterruptSpell()
    end
    if playerKick then
        local cooldownInfo = C_Spell.GetSpellCooldown(playerKick)
        if cooldownInfo then
            BBF.interruptTrackingIcon.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
            local isOnCooldown = BBF.interruptTrackingIcon.cooldown:IsShown()
            BBF.playerKickReady = not isOnCooldown
        end
    end
end

local function UpdateInterruptIcon(frame)
    if not frame then return end

    if not playerKick then
        playerKick = GetInterruptSpell()
    end

    local castBar = frame:GetParent()
    local shouldShow = false

    if BetterBlizzFramesDB.castBarInterruptIconEnabled then
        if frame == TargetFrameSpellBar.interruptIconFrame then
            shouldShow = BetterBlizzFramesDB.castBarInterruptIconTarget
        elseif frame == FocusFrameSpellBar.interruptIconFrame then
            shouldShow = BetterBlizzFramesDB.castBarInterruptIconFocus
        end
    end

    if (castBar.unit and not UnitCanAttack("player", castBar.unit)) then
        frame:Hide()
        return
    end

    if playerKick then
        local cooldownInfo = C_Spell.GetSpellCooldown(playerKick)
        if cooldownInfo then
            frame.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
            local isOnCooldown = frame.cooldown:IsShown()

            if BetterBlizzFramesDB.castBarInterruptIconShowActiveOnly and isOnCooldown then
                frame:Hide()
                return
            end

            if shouldShow then
                frame:Show()
                frame.icon:SetTexture(C_Spell.GetSpellTexture(playerKick))

                if frame.border then
                    if isOnCooldown then
                        frame.border:SetVertexColor(1, 0, 0)
                    else
                        frame.border:SetVertexColor(0, 1, 0)
                    end
                end
            else
                frame:Hide()
            end
        end
    else
        frame:Hide()
    end
end

local function OnPetEvent(self, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not petSummonSpells[spellID] then return end
    end
    C_Timer.After(0.1, function()
        playerKick = GetInterruptSpell()
        UpdateInterruptTracking()
        if TargetFrameSpellBar.interruptIconFrame then
            UpdateInterruptIcon(TargetFrameSpellBar.interruptIconFrame)
        end
        if FocusFrameSpellBar.interruptIconFrame then
            UpdateInterruptIcon(FocusFrameSpellBar.interruptIconFrame)
        end
    end)
end

local cooldownFrame = CreateFrame("Frame")
cooldownFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
cooldownFrame:SetScript("OnEvent", function(self, event, spellID)
    if spellID ~= playerKick then return end
    UpdateInterruptTracking()
    if TargetFrameSpellBar.interruptIconFrame then
        UpdateInterruptIcon(TargetFrameSpellBar.interruptIconFrame)
    end
    if FocusFrameSpellBar.interruptIconFrame then
        UpdateInterruptIcon(FocusFrameSpellBar.interruptIconFrame)
    end
end)

local interruptSpellUpdate = CreateFrame("Frame")
if select(2, UnitClass("player")) == "WARLOCK" then
    interruptSpellUpdate:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end
interruptSpellUpdate:RegisterEvent("TRAIT_CONFIG_UPDATED")
interruptSpellUpdate:RegisterEvent("PLAYER_TALENT_UPDATE")
interruptSpellUpdate:SetScript("OnEvent", OnPetEvent)

local function IsAnyFeatureEnabled()
    return BetterBlizzFramesDB.castBarInterruptIconEnabled and
           (BetterBlizzFramesDB.castBarInterruptIconTarget or
            BetterBlizzFramesDB.castBarInterruptIconFocus)
end

local function CreateInterruptIconFrame(parentFrame)
    local button = CreateFrame("Frame", nil, parentFrame)
    button:SetSize(30, 30)
    button:SetPoint("CENTER", parentFrame, BetterBlizzFramesDB.castBarInterruptIconAnchor,
                    BetterBlizzFramesDB.castBarInterruptIconXPos + 45,
                    BetterBlizzFramesDB.castBarInterruptIconYPos - 7)
    button:SetScale(BetterBlizzFramesDB.castBarInterruptIconScale)

    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

    if BetterBlizzFramesDB.interruptIconBorder then
        button.border = button:CreateTexture(nil, "OVERLAY")
        button.border:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-ActionBar-IconFrame-AddRow-Light")
        button.border:SetSize(48, 48)
        button.border:SetPoint("CENTER", button, "CENTER", 2, -2)
        button.border:SetDrawLayer("OVERLAY", 7)
        button.border:SetVertexColor(0, 1, 0)
    end

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.cooldown:HookScript("OnCooldownDone", function()
        if button.border then
            button.border:SetVertexColor(0, 1, 0)
        end
    end)

    return button
end

local function OnCastBarEvent(castBar, event)
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or
       event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        if castBar.interruptIconFrame then
            UpdateInterruptIcon(castBar.interruptIconFrame)
        end
    end
end

function BBF.ToggleCastbarInterruptIcon()
    if TargetFrameSpellBar.interruptIconFrame then
        TargetFrameSpellBar.interruptIconFrame:Hide()
        TargetFrameSpellBar.interruptIconFrame = nil
    end
    if FocusFrameSpellBar.interruptIconFrame then
        FocusFrameSpellBar.interruptIconFrame:Hide()
        FocusFrameSpellBar.interruptIconFrame = nil
    end

    if not IsAnyFeatureEnabled() then
        return
    end

    TargetFrameSpellBar.interruptIconFrame = CreateInterruptIconFrame(TargetFrameSpellBar)
    UpdateInterruptIcon(TargetFrameSpellBar.interruptIconFrame)

    if not TargetFrameSpellBar.interruptIconHooked then
        TargetFrameSpellBar:HookScript("OnEvent", OnCastBarEvent)
        TargetFrameSpellBar.interruptIconHooked = true
    end

    FocusFrameSpellBar.interruptIconFrame = CreateInterruptIconFrame(FocusFrameSpellBar)
    UpdateInterruptIcon(FocusFrameSpellBar.interruptIconFrame)

    if not FocusFrameSpellBar.interruptIconHooked then
        FocusFrameSpellBar:HookScript("OnEvent", OnCastBarEvent)
        FocusFrameSpellBar.interruptIconHooked = true
    end
end

local function UpdateSettings()
    if not IsAnyFeatureEnabled() then
        if TargetFrameSpellBar.interruptIconFrame then
            TargetFrameSpellBar.interruptIconFrame:Hide()
        end
        if FocusFrameSpellBar.interruptIconFrame then
            FocusFrameSpellBar.interruptIconFrame:Hide()
        end
        return
    end

    if TargetFrameSpellBar.interruptIconFrame then
        local frame = TargetFrameSpellBar.interruptIconFrame
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", TargetFrameSpellBar, BetterBlizzFramesDB.castBarInterruptIconAnchor,
                       BetterBlizzFramesDB.castBarInterruptIconXPos + 45,
                       BetterBlizzFramesDB.castBarInterruptIconYPos - 7)
        frame:SetScale(BetterBlizzFramesDB.castBarInterruptIconScale)
        if BetterBlizzFramesDB.castBarInterruptIconEnabled and BetterBlizzFramesDB.castBarInterruptIconTarget then
            frame:Show()
        else
            frame:Hide()
        end
    end

    if FocusFrameSpellBar.interruptIconFrame then
        local frame = FocusFrameSpellBar.interruptIconFrame
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", FocusFrameSpellBar, BetterBlizzFramesDB.castBarInterruptIconAnchor,
                       BetterBlizzFramesDB.castBarInterruptIconXPos + 45,
                       BetterBlizzFramesDB.castBarInterruptIconYPos - 7)
        frame:SetScale(BetterBlizzFramesDB.castBarInterruptIconScale)

        if BetterBlizzFramesDB.castBarInterruptIconEnabled and BetterBlizzFramesDB.castBarInterruptIconFocus then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

function BBF.UpdateInterruptIconSettings()
    UpdateSettings()
    if BetterBlizzFramesDB.castBarInterruptIconEnabled then
        if BetterBlizzFramesDB.castBarInterruptIconTarget and TargetFrameSpellBar.interruptIconFrame then
            UpdateInterruptIcon(TargetFrameSpellBar.interruptIconFrame)
        end
        if BetterBlizzFramesDB.castBarInterruptIconFocus and FocusFrameSpellBar.interruptIconFrame then
            UpdateInterruptIcon(FocusFrameSpellBar.interruptIconFrame)
        end
    end
end