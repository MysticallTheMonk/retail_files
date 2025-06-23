local _, addon = ...;

-- Sizes are fixed, players can customize by scale
local iconSize = 40;

-- Original size is 48 * 67, scale it up a little
local arrowWidth = 48 * 1.1;
local arrowHeight = 67 * 1.1;
local highlightSize = 55;
local classicBorderSize = 64;

addon.CreateClassOrSpecIcon = function (nameplate, point, relativePoint, isFriendly)
    local classIconFrame = CreateFrame("Frame", nil, nameplate);
    classIconFrame:SetMouseClickEnabled(false);
    -- Force alpha 1 and ignore parent alpha, so that the nameplate is always super visible
    classIconFrame:SetAlpha(1);
    classIconFrame:SetIgnoreParentAlpha(true);
    classIconFrame:SetSize(iconSize, iconSize);
    classIconFrame:SetFrameStrata("HIGH");
    classIconFrame:SetPoint(point, nameplate, relativePoint);

    classIconFrame.icon = classIconFrame:CreateTexture(nil, "BORDER");
    classIconFrame.icon:SetSize(iconSize, iconSize);
    classIconFrame.icon:SetAllPoints(classIconFrame);

    classIconFrame.mask = classIconFrame:CreateMaskTexture();
    classIconFrame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
    classIconFrame.mask:SetSize(iconSize, iconSize);
    classIconFrame.mask:SetAllPoints(classIconFrame.icon);
    classIconFrame.icon:AddMaskTexture(classIconFrame.mask);

    classIconFrame.border = classIconFrame:CreateTexture(nil, "OVERLAY");
    classIconFrame.border:SetAtlas("charactercreate-ring-metallight"); -- "ui-frame-genericplayerchoice-portrait-border"
    classIconFrame.border:SetSize(classicBorderSize, classicBorderSize);
    classIconFrame.border:SetPoint("CENTER", classIconFrame); -- SetAllPoints will not work

    if isFriendly then
        classIconFrame.targetHighlight = classIconFrame:CreateTexture(nil, "OVERLAY");
        classIconFrame.targetHighlight:Hide();
        classIconFrame.targetHighlight:SetDesaturated(false);
        classIconFrame.targetHighlight:SetAtlas("charactercreate-ring-select"); -- Consider using UI-LFG-RoleIcon-Incentive for a stronger effect
        classIconFrame.targetHighlight:SetSize(highlightSize, highlightSize);
        classIconFrame.targetHighlight:SetPoint("CENTER", classIconFrame); -- SetAllPoints will not work
        classIconFrame.targetHighlight:SetDrawLayer("OVERLAY", 1);
        classIconFrame.targetHighlight:SetVertexColor(1,0.88,0);

        classIconFrame.iconCC = classIconFrame:CreateTexture(nil, "ARTWORK"); -- above icon but doesn't block border / target highlight
        classIconFrame.iconCC:SetSize(iconSize, iconSize);
        classIconFrame.iconCC:SetAllPoints(classIconFrame);
        --classIconFrame.iconCC:SetAlpha(0.5); -- So it doesn't block the original icon, less distracting

        classIconFrame.maskCC = classIconFrame:CreateMaskTexture();
        classIconFrame.maskCC:SetTexture("Interface/Masks/CircleMaskScalable");
        classIconFrame.maskCC:SetSize(iconSize, iconSize);
        classIconFrame.maskCC:SetAllPoints(classIconFrame.iconCC);
        classIconFrame.iconCC:AddMaskTexture(classIconFrame.maskCC);

        classIconFrame.cooldownCC = CreateFrame("Cooldown", nil, classIconFrame, "CooldownFrameTemplate");
        classIconFrame.cooldownCC:SetAllPoints();
        classIconFrame.cooldownCC:SetDrawEdge(true);
        if addon.PROJECT_MAINLINE then
            classIconFrame.cooldownCC:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
        end
        classIconFrame.cooldownCC:SetUseCircularEdge(true);
        classIconFrame.cooldownCC:SetReverse(true);
        classIconFrame.cooldownCC:SetSwipeTexture("Interface/Masks/CircleMaskScalable");
        classIconFrame.cooldownCC:SetSwipeColor(0, 0, 0, 0.5); -- to achieve a transparent background
        classIconFrame.cooldownCC:SetHideCountdownNumbers(true);
        classIconFrame.cooldownCC.noCooldownCount = true; -- hide OmniCC timers
    else
        classIconFrame.border:SetVertexColor(255, 0, 0); -- Red border for hostile
        classIconFrame.border:Hide(); -- Hide initially until an actual icon is set
    end

    return classIconFrame;
end

addon.CreateClassColorArrowFrame = function (nameplate)
    local classIconFrame = CreateFrame("Frame", nil, nameplate);
    classIconFrame:SetMouseClickEnabled(false);
    -- Force alpha 1 and ignore parent alpha, so that the nameplate is always super visible
    classIconFrame:SetAlpha(1);
    classIconFrame:SetIgnoreParentAlpha(true);
    classIconFrame:SetSize(arrowHeight, arrowWidth); -- Swap width and height since we are rotating the texture
    classIconFrame:SetFrameStrata("HIGH");
    classIconFrame:SetPoint("CENTER", nameplate, "CENTER");

    classIconFrame.icon = classIconFrame:CreateTexture(nil, "BORDER");
    classIconFrame.icon:SetSize(arrowWidth, arrowHeight);
    classIconFrame.icon:SetDesaturated(false);
    classIconFrame.icon:SetAtlas("covenantsanctum-renown-doublearrow-disabled"); -- original size is 67 * 48, distort to 67 * 67
    classIconFrame.icon:SetPoint("CENTER", classIconFrame, "CENTER");
    classIconFrame.icon:SetRotation(math.pi / 2); -- Counter-clockwise by 90 degrees

    classIconFrame.targetHighlight = classIconFrame:CreateTexture(nil, "OVERLAY");
    classIconFrame.targetHighlight:SetAtlas("communities-guildbanner-border"); -- Originally Capacitance-General-WorkOrderBorder which is rectangle
    classIconFrame.targetHighlight:SetVertexColor(1, 0.88, 0);
    classIconFrame.targetHighlight:SetDesaturated(false);
    classIconFrame.targetHighlight:SetSize(arrowWidth, arrowWidth);
    classIconFrame.targetHighlight:SetPoint("CENTER", classIconFrame, "CENTER", 0, -5);
    classIconFrame.targetHighlight:Hide();

    return classIconFrame;
end
