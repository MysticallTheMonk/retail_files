local _, addon = ...;

local animationScale = 1.05;
local animationDuration = 0.25;
local iconSize = 30;
local offsetMultiplier = 0.41;

local function SetupAnimation(frameWithAnimations)
    local animationGroup = frameWithAnimations:CreateAnimationGroup();

    local grow = animationGroup:CreateAnimation("Scale");
    grow:SetOrder(1);
    grow:SetScale(animationScale, animationScale);
    grow:SetDuration(animationDuration);

    local shrink = animationGroup:CreateAnimation("Scale");
    shrink:SetOrder(2);
    shrink:SetScale(1 / animationScale, 1 / animationScale);
    shrink:SetDuration(animationDuration);

    animationGroup:SetLooping("REPEAT");

    return animationGroup;
end

local function EnsureNpcHighlight(nameplate)
    local config = SweepyBoop.db.profile.nameplatesEnemy;

    if ( not nameplate.npcHighlight ) then
        nameplate.npcHighlight = CreateFrame("Frame", nil, nameplate);
        nameplate.npcHighlight:SetMouseClickEnabled(false);
        nameplate.npcHighlight:SetSize(iconSize, iconSize);
        nameplate.npcHighlight:SetFrameStrata("HIGH");
        nameplate.npcHighlight:SetPoint("BOTTOM", nameplate, "TOP", 0, config.npcHighlightOffset);

        nameplate.npcHighlight.customIcon = nameplate.npcHighlight:CreateTexture(nil, "OVERLAY");
        nameplate.npcHighlight.customIcon:SetAllPoints(nameplate.npcHighlight);

        local widthOffset = iconSize * offsetMultiplier;
        local heightOffset = iconSize * offsetMultiplier;
        nameplate.npcHighlight.glowTexture = nameplate.npcHighlight:CreateTexture(nil, "OVERLAY");
        nameplate.npcHighlight.glowTexture:SetBlendMode("ADD");
        if addon.PROJECT_MAINLINE then
            nameplate.npcHighlight.glowTexture:SetAtlas("clickcast-highlight-spellbook");
        else
            nameplate.npcHighlight.glowTexture:SetAtlas("Forge-ColorSwatchSelection");
            nameplate.npcHighlight.glowTexture:SetScale(0.4);
        end
        nameplate.npcHighlight.glowTexture:SetDesaturated(true);
        nameplate.npcHighlight.glowTexture:SetPoint('TOPLEFT', nameplate.npcHighlight, 'TOPLEFT', -widthOffset, heightOffset);
        nameplate.npcHighlight.glowTexture:SetPoint('BOTTOMRIGHT', nameplate.npcHighlight, 'BOTTOMRIGHT', widthOffset, -heightOffset);
        nameplate.npcHighlight.glowTexture:SetVertexColor(128, 0, 128); -- Purple

        nameplate.npcHighlight.animationGroup = SetupAnimation(nameplate.npcHighlight);

        nameplate.npcHighlight:Hide();
    end

    if ( nameplate.npcHighlight.lastModified ~= config.lastModified ) then
        nameplate.npcHighlight:SetScale(config.npcHighlightScale);
        nameplate.npcHighlight:SetPoint("BOTTOM", nameplate, "TOP", 0, config.npcHighlightOffset);
        nameplate.npcHighlight.lastModified = config.lastModified;
    end

    return nameplate.npcHighlight;
end

addon.UpdateNpcHighlight = function(nameplate)
    -- Parented to UnitFrame to inherit the visibility
    local highlight = EnsureNpcHighlight(nameplate);
    local unitGUID = UnitGUID(nameplate.UnitFrame.unit);
    if ( highlight.currentGuid ~= unitGUID ) then
        local npcID = select(6, strsplit("-", unitGUID));
        highlight.customIcon:SetTexture(addon.iconTexture[npcID]); -- nil if no texture found
        highlight.currentGuid = unitGUID;
    end
end

addon.ShowNpcHighlight = function(nameplate, animation)
    addon.UpdateNpcHighlight(nameplate);
    local highlight = nameplate.npcHighlight;

    if highlight then
        highlight.customIcon:Show();
        if animation then
            highlight.glowTexture:Show();
            highlight.animationGroup:Play();
        else
            highlight.glowTexture:Hide();
            if highlight.animationGroup:IsPlaying() then
                highlight.animationGroup:Stop();
            end
        end
        highlight:Show();
    end
end

addon.HideNpcHighlight = function(nameplate)
    local highlight = nameplate.npcHighlight;
    if highlight then
        if highlight.animationGroup:IsPlaying() then
            highlight.animationGroup:Stop();
        end
        highlight.glowTexture:Hide();
        highlight.customIcon:Hide();
        highlight:Hide();
    end
end

local scaleFactor = 0.5; -- Smaller icons for critters

local function EnsureIcon(nameplate)
    if ( not nameplate.EnemyCritterIcon ) then
        nameplate.EnemyCritterIcon = addon.CreateClassOrSpecIcon(nameplate, "CENTER", "CENTER", false);
        nameplate.EnemyCritterIcon.icon:SetAtlas(addon.ICON_CRITTER);
        nameplate.EnemyCritterIcon:Hide();
    end

    return nameplate.EnemyCritterIcon;
end

addon.UpdateCritterIcon = function(nameplate)
    -- Only update if config changes (we have separated out pet icon from class / healer / flag carrier icons, and pet icon has fixed texture)
    local iconFrame = EnsureIcon(nameplate);
    local lastModifiedEnemy = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
    if ( iconFrame.lastModifiedEnemy ~= lastModifiedEnemy ) then
        iconFrame:SetScale(SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100 * scaleFactor);
        iconFrame.lastModifiedEnemy = lastModifiedEnemy;
    end
end

addon.ShowCritterIcon = function (nameplate)
    addon.UpdateCritterIcon(nameplate);
    if nameplate.EnemyCritterIcon then
        nameplate.EnemyCritterIcon:Show();
    end
end

addon.HideCritterIcon = function(nameplate)
    if nameplate.EnemyCritterIcon then
        nameplate.EnemyCritterIcon:Hide();
    end
end
