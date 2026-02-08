local function GetInterruptSpell()
    for spellID, _ in pairs(sArenaMixin.interruptList) do
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

sArenaMixin.interruptIcon = CreateFrame("Frame")
sArenaMixin.interruptIcon.cooldown = CreateFrame("Cooldown", nil, sArenaMixin.interruptIcon, "CooldownFrameTemplate")
sArenaMixin.interruptIcon.cooldown:HookScript("OnCooldownDone", function()
    sArenaMixin.interruptReady = true
    sArenaMixin:UpdateCastbarInterruptStatus()
end)

function sArenaMixin:UpdateCastbarInterruptStatus()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = _G["sArenaEnemyFrame" .. i]
        local castBar = frame.CastBar
        if castBar:IsShown() then
            sArenaMixin:CastbarOnEvent(castBar)
        end
    end
end

-- Function to update the interrupt icon
local function UpdateInterruptIcon(frame)
    if not playerKick then
        playerKick = GetInterruptSpell()
    end
    if playerKick then
        -- Update cooldown
        local cooldownInfo = C_Spell.GetSpellCooldown(playerKick)
        if cooldownInfo then
            frame.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
        end
    end
end

local function OnInterruptUpdate(self, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if sArenaMixin.interruptList[spellID] then
            local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
            if cooldownInfo then
                sArenaMixin.interruptIcon.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
            end
            sArenaMixin.interruptReady = false
            sArenaMixin:UpdateCastbarInterruptStatus()
            return
        end
        if not petSummonSpells[spellID] then return end
    end
    C_Timer.After(0.1, function()
        playerKick = GetInterruptSpell()
        UpdateInterruptIcon(sArenaMixin.interruptIcon)
    end)
end


local cooldownFrame = CreateFrame("Frame")
cooldownFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
cooldownFrame:SetScript("OnEvent", function(self, event, spellID)
    if spellID ~= playerKick then return end
    UpdateInterruptIcon(sArenaMixin.interruptIcon)
end)

sArenaMixin.interruptSpellUpdate = CreateFrame("Frame")
sArenaMixin.interruptSpellUpdate:SetScript("OnEvent", OnInterruptUpdate)

function sArenaMixin:RegisterInterruptEvents()
    self.interruptSpellUpdate:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    self.interruptSpellUpdate:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self.interruptSpellUpdate:RegisterEvent("PLAYER_TALENT_UPDATE")

    playerKick = GetInterruptSpell()
    UpdateInterruptIcon(self.interruptIcon)
end

function sArenaMixin:UnregisterInterruptEvents()
    self.interruptSpellUpdate:UnregisterAllEvents()
end