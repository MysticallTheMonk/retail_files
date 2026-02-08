local _, addon = ...;

local iconSize = addon.DEFAULT_ICON_SIZE;

local function StartAnimation(icon)
    icon.FlashAnimation:Play();
	icon.ActivationAnimation:Play();
end

local function StopAnimation(icon)
    if icon.FlashAnimation:IsPlaying() then icon.FlashAnimation:Stop() end
	if icon.ActivationAnimation:IsPlaying() then icon.ActivationAnimation:Stop() end
end

local function OnCooldownTimerFinished(self)
    StopAnimation(self:GetParent());
    addon.FinishCooldownTimer(self);
end

local function SetGlowDuration(icon, startTime, duration)
    icon.duration:SetCooldown(startTime, duration);
    icon.duration.finish = startTime + duration;
end

-- Early dismissal of icon glow due to aura being dispelled, right clicking the buff, etc.
addon.ResetGlowDuration = function (icon)
    if ( not icon.duration ) then return end

    SetGlowDuration(icon, 0, 0);
    addon.OnDurationTimerFinished(icon.duration);
end

addon.RefreshGlowDuration = function (icon, duration, expirationTime)
    if ( not icon.duration ) then return end

    if ( expirationTime - GetTime() > 1 ) then -- Don't bother extending if less than 1 sec left
        SetGlowDuration(icon, expirationTime - duration, duration);
        if icon.cooldown then
            icon.cooldown:Hide(); -- Duration OnCooldownDone callback will show the cooldown timer
        end
    end
end

function CooldownTracking_OnAnimationFinished(icon)
    addon.UpdateTargetHighlight(icon);

    -- Wait for animation to finish to set used alpha
    -- Has another ability reset this icon's cooldown while animation was playing?
    if icon.started then
        addon.SetUsedIconAlpha(icon);
    end
end

-- Only put static info in this function
-- An icon for a unit + spellID is only created once per session
addon.CreateCooldownTrackingIcon = function (unit, spellID, size, showName)
    local frame = CreateFrame("Button", nil, UIParent, "CooldownTrackingButtonTemplate");
    frame.template = addon.ICON_TEMPLATE.FLASH;
    frame:SetMouseClickEnabled(false);
    frame.group = true; -- To add itself to parent group
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    local spell = addon.SpellData[spellID];
    frame.category = spell.category;

    if size then
        local scale = size / iconSize;
        frame:SetScale(scale);
    end

    frame.Name:SetShown(showName);

    -- Fill in static info here
    frame.spellInfo = spell;
    frame.priority = spell.priority;
    frame.class = spell.class;

    frame.Icon:SetTexture(addon.GetSpellTexture(spellID));
    frame.Icon:SetAllPoints();

    if spell.charges or spell.opt_charges then
        frame.Count = CreateFrame("Frame", nil, frame);
        frame.Count:SetFrameLevel(10000);
        frame.Count:SetSize(addon.CHARGE_TEXTURE_SIZE, addon.CHARGE_TEXTURE_SIZE);
        frame.Count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT");

        frame.Count.text = frame.Count:CreateFontString(nil, "OVERLAY", "NumberFontNormal");
        frame.Count.text:SetPoint("CENTER", frame.Count, "CENTER");
        frame.Count.text:SetText("");
        frame.Count.text:SetTextColor(1, 1, 1);

        frame.Count:Hide();
    end

    frame.cooldown:SetScript("OnCooldownDone", OnCooldownTimerFinished);

    if spell.duration then
        frame.duration = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
        frame.duration:SetAllPoints();
        frame.duration:SetDrawEdge(false);
        frame.duration:SetDrawBling(false);
        frame.duration:SetDrawSwipe(true);
        frame.duration:SetReverse(true);
        frame.duration.noCooldownCount = true;
        frame.duration:SetAlpha(0);

        frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionButtonSpellAlertTemplate");
        frame.spellActivationAlert:SetSize(iconSize * 1.4, iconSize * 1.4);
        frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
        frame.spellActivationAlert:Hide();

        frame.duration:SetScript("OnCooldownDone", addon.OnDurationTimerFinished);
    end

    return frame;
end

addon.StartCooldownTrackingIcon = function (icon)
    icon:SetAlpha(1); -- When starting the icon, always show it at full alpha

    local spell = icon.spellInfo; -- static spell info
    local info = icon.info; -- dynamic info for current icon
    local timers = icon.timers;

    -- Init default charge
    if #(timers) == 0 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    -- Initialize charge expire if baseline charge
    if info.charges and #(timers) < 2 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    if icon:IsShown() and icon.started then
        if spell.opt_lower_cooldown then
            info.cooldown = math.min(info.cooldown, spell.opt_lower_cooldown);
        end

        if spell.opt_charges and #(timers) < 2 then
            table.insert(timers, {start = 0, duration = 0, finish = 0});
        end
    end

    -- Always use timers[1] since it will be either off cooldown, or closet to come off cooldown
    -- Always use timers[1] since it will be either off cooldown, or closet to come off cooldown
    local now = GetTime();

    if spell.cooldown then
        -- Check which one should be used
        local index = addon.CheckTimerToStart(timers);
        --print("Use timers", index);
        timers[index].start = now;
        timers[index].duration = info.cooldown;
        timers[index].finish = timers[index].start + timers[index].duration;

        if ( index == 1 ) and timers[2] and ( now < timers[2].finish ) then
            -- If we use timers[1] while timers[2] is already on cooldown, it will suspend timers[2]'s cooldown progress until timers[1] recovers
            -- So here we set it to a positive infinity, and while default comes back, we'll resume its cooldown progress
            --print("Pause timers[2]");
            timers[2].finish = math.huge;
        elseif ( index == 2 ) then
            -- If we use 2nd charge, also set it to infinity, since it will only start recovering when default charge comes back
            --print("Pause timers[2]");
            timers[2].finish = math.huge;
        end

        addon.RefreshCooldownTimer(icon.cooldown);

        if ( icon.template == addon.ICON_TEMPLATE.FLASH ) or ( not spell.duration ) then
            StartAnimation(icon);
        end
    end

    if spell.duration and ( icon.template == addon.ICON_TEMPLATE.GLOW ) then
        -- Decide duration
        local startTime = now;
        local duration;
        if spell.duration == addon.DURATION_DYNAMIC then
            local expirationTime;
            duration, expirationTime = select(5, AuraUtil.UnpackAuraData(addon.Util_GetUnitBuff(icon.unit, icon.spellID)));
            if duration and expirationTime then
                startTime = expirationTime - duration;
            end
        else
            duration = spell.duration;
        end

        if startTime and duration then
            SetGlowDuration(icon, startTime, duration);
            if icon.cooldown then
                icon.cooldown:Hide(); -- Hide the cooldown timer until duration is over
            end
            addon.ShowOverlayGlow(icon);
        end
    end

    addon.IconGroup_Insert(icon:GetParent(), icon, icon.unit .. "-" .. icon.spellID);
    icon.started = true;
end

-- For spells with reduce_on_interrupt, set an internal cooldown so it doesn't reset cd multiple times
-- This is basically only for solar beam
addon.ResetCooldownTrackingCooldown = function (icon, amount, internalCooldown, resetTo)
    if internalCooldown then
        local now = GetTime();
        if icon.info.lastReset and ( now < icon.info.lastReset + internalCooldown ) then
            return;
        end

        icon.info.lastReset = now;
    end

    addon.ResetIconCooldown(icon, amount, resetTo);
end
