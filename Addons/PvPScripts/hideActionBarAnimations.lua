
local function StyleButton(Button)
    local Name = Button:GetName()
    --[[ Unused as far as I can tell
    local AutoCastable = _G[Name].AutoCastable
    local AutoCastShine = _G[Name].AutoCastShine
    local SpellHighlightAnim = _G[Name].SpellHighlightAnim
    local SpellHighlightTexture = _G[Name].SpellHighlightTexture
    --]]
    local InterruptDisplay = _G[Name].InterruptDisplay -- Interrupted Red Flash
    local SpellCastAnimFrame = _G[Name].SpellCastAnimFrame -- Castbar on Spell
    local TargetReticleAnimFrame = _G[Name].TargetReticleAnimFrame -- Ground Reticle Spell
    local CooldownFlash = _G[Name].CooldownFlash -- End of a Cast Cooldown Flash
    -- local SpellActivation = _G[Name].SpellActivationAlert -- Golden Border Ability Procc
    -- local CooldownEdgeTexture = _G[Name].chargeCooldown -- Abilities with Charges
    for _, v in pairs ({
        InterruptDisplay,
        SpellCastAnimFrame,
        TargetReticleAnimFrame,
        CooldownFlash,
    }) do 
        hooksecurefunc(v, "Show", function(s)
            s:Hide()
        end)
        v:Show()
    end
end

for i = 1, 12 do
    StyleButton(_G["ActionButton"..i])
    StyleButton(_G["MultiBarBottomLeftButton"..i])
    StyleButton(_G["MultiBarBottomLeftButton"..i])
    StyleButton(_G["MultiBarBottomRightButton"..i])
    StyleButton(_G["MultiBarLeftButton"..i])
    StyleButton(_G["MultiBarRightButton"..i])
    StyleButton(_G["MultiBar5Button"..i])
    StyleButton(_G["MultiBar6Button"..i])
    StyleButton(_G["MultiBar7Button"..i])
end
for i = 1, 6 do
    StyleButton(_G["OverrideActionBarButton"..i])
end
--[[ Don't think these are needed
for i = 1, 10 do
    StyleButton(_G["StanceButton"..i])
    StyleButton(_G["PetActionButton"..i])
end 
for i = 1, 2 do 
    StyleButton(_G["PossessButton"..i])
end
--]]

-- Abilities with Charges
hooksecurefunc("StartChargeCooldown", function(parent, chargeStart, chargeDuration, chargeModRate)
    if parent.chargeCooldown then
        parent.chargeCooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
    end
end)

-- Golden Border Procc
hooksecurefunc("ActionButton_ShowOverlayGlow", function(button)
    if button.SpellActivationAlert.ProcStartAnim:IsPlaying() then
        --Hack to hide the animation start if we do 
        --button.SpellActivationAlert.ProcStartAnim:Stop()
        --then the texture breaks in horrendous ways
        button.SpellActivationAlert:SetAlpha(0)
        C_Timer.After(0.26, function()
            button.SpellActivationAlert:SetAlpha(1)
        end)
        -- Interface\\SpellActivationOverlay\\IconAlert
        -- Interface\\SpellActivationOverlay\\IconAlertAnts
        -- ActionButton_HideOverlayGlow(self) -- Perma Hide it?
    end
end)