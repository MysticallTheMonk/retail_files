local _, addon = ...;

local auraFilterConflict = C_AddOns.IsAddOnLoaded("flyPlateBuffs") or C_AddOns.IsAddOnLoaded("EpicPlates") or C_AddOns.IsAddOnLoaded("flyPlateBuffsFixed");

local AURA_CATEGORY = { -- Maybe apply different borders based on category?
    CROWD_CONTROL = 1,
    DEBUFF = 2,
    BUFF = 3,
};

local rowGap = 4;
local spacing = 4;

local function EnsureGlowFrame(buff)
    if not buff.CustomGlowFrame then
        buff.CustomGlowFrame = CreateFrame("Frame", nil, buff);
        if buff.CountFrame then
            buff.CountFrame:SetFrameLevel(999); -- Make sure the glow doesn't block the count
        end
    end

    return buff.CustomGlowFrame;
end

local function UpdateCrowdControlGlow(buff, show)
    if show then
        local container = EnsureGlowFrame(buff);
        if not container.CrowdControlGlow then
            container.CrowdControlGlow = container:CreateTexture(nil, "ARTWORK");
            if addon.PROJECT_MAINLINE then
                container.CrowdControlGlow:SetAtlas("newplayertutorial-drag-slotgreen");
            else
                container.CrowdControlGlow:SetAtlas("Forge-ColorSwatchSelection");
                container.CrowdControlGlow:SetScale(0.4);
            end
            container.CrowdControlGlow:SetDesaturated(true);
            container.CrowdControlGlow:SetVertexColor(1, 0.6471, 0); -- Orange
        end

        container.CrowdControlGlow:SetPoint("TOPLEFT", buff, "TOPLEFT", -9, 6);
        container.CrowdControlGlow:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", 9, -6);
        container.CrowdControlGlow:Show();
    else
        if buff.CustomGlowFrame and buff.CustomGlowFrame.CrowdControlGlow then
            buff.CustomGlowFrame.CrowdControlGlow:Hide();
        end
    end
end

local function UpdatePurgableGlow(buff, show)
    if show then
        local container = EnsureGlowFrame(buff);
        if not container.PurgableGlow then
            container.PurgableGlow = container:CreateTexture(nil, "ARTWORK");
            if addon.PROJECT_MAINLINE then
                container.PurgableGlow:SetAtlas("newplayertutorial-drag-slotblue");
            else
                container.PurgableGlow:SetAtlas("Forge-ColorSwatchSelection");
                container.PurgableGlow:SetScale(0.4);
                container.PurgableGlow:SetDesaturated(true);
                container.PurgableGlow:SetVertexColor(1, 1, 1); -- White
            end
        end

        container.PurgableGlow:SetPoint("TOPLEFT", buff, "TOPLEFT", -9, 6);
        container.PurgableGlow:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", 9, -6);
        container.PurgableGlow:Show();
    else
        if buff.CustomGlowFrame and buff.CustomGlowFrame.PurgableGlow then
            buff.CustomGlowFrame.PurgableGlow:Hide();
        end
    end
end

local function UpdateBuffGlow(buff, show)
    if show then
        local container = EnsureGlowFrame(buff);
        if not container.BuffGlow then
            container.BuffGlow = container:CreateTexture(nil, "ARTWORK");
            if addon.PROJECT_MAINLINE then
                container.BuffGlow:SetAtlas("newplayertutorial-drag-slotgreen");
            else
                container.BuffGlow:SetAtlas("Forge-ColorSwatchSelection");
                container.BuffGlow:SetScale(0.4);
            end
            container.BuffGlow:SetDesaturated(true);
            container.BuffGlow:SetVertexColor(0, 1, 0); -- Green
        end

        container.BuffGlow:SetPoint("TOPLEFT", buff, "TOPLEFT", -9, 6);
        container.BuffGlow:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", 9, -6);
        container.BuffGlow:Show();
    else
        if buff.CustomGlowFrame and buff.CustomGlowFrame.BuffGlow then
            buff.CustomGlowFrame.BuffGlow:Hide();
        end
    end
end

-- Return aura category if should be shown, nil otherwise
local function ShouldShowBuffOverride(self, aura)
    if ( not aura ) or ( not aura.spellId ) then
        return nil;
    end

    -- Debug, comment out for retail release!
    --print(aura.name, aura.spellId);

    -- Basically only show crowd controls and whitelisted debuffs applied by the player

    -- Some crowd controls are hidden by Blizzard, override the logic
    if addon.CrowdControlAuras[aura.spellId] then
        return AURA_CATEGORY.CROWD_CONTROL;
    end

    -- Parse non crowd control debuffs
    if aura.isHarmful then
        if (aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle") then
            local spellId = aura.spellId;
            if addon.AuraParent[spellId] then
                spellId = addon.AuraParent[spellId];
            end

            return SweepyBoop.db.profile.nameplatesEnemy.debuffWhiteList[tostring(spellId)] and AURA_CATEGORY.DEBUFF;
        else
            return nil;
        end
    end

    -- Parse buffs
    if aura.isHelpful then
        local spellId = aura.spellId;
        if addon.AuraParent[spellId] then
            spellId = addon.AuraParent[spellId];
        end

        return SweepyBoop.db.profile.nameplatesEnemy.buffWhiteList[tostring(spellId)] and AURA_CATEGORY.BUFF;
    end
end

local function DefaultAuraCompareClassic(a, b)
    local aFromPlayer = (a.sourceUnit ~= nil) and UnitIsUnit("player", a.sourceUnit) or false;
	local bFromPlayer = (b.sourceUnit ~= nil) and UnitIsUnit("player", b.sourceUnit) or false;
	if aFromPlayer ~= bFromPlayer then
		return aFromPlayer;
	end

	if a.canApplyAura ~= b.canApplyAura then
		return a.canApplyAura;
	end

	return a.auraInstanceID < b.auraInstanceID;
end

local DefaultAuraCompare = AuraUtil.DefaultAuraCompare or DefaultAuraCompareClassic;

local function IterateAuras(self, filter)
    for i = 1, 255 do
        local aura = C_UnitAuras.GetAuraDataByIndex(self.unit, i, filter);
        if ( not aura ) or ( not aura.name ) then
            break;
        end
        local customCategory = ShouldShowBuffOverride(self, aura);
        if customCategory then
            aura.customCategory = customCategory;
            self.auras[aura.auraInstanceID] = aura;
        end
    end
end

local function ParseAllAurasOverride(self)
    if self.auras == nil then
        self.auras = TableUtil.CreatePriorityTable(DefaultAuraCompare, TableUtil.Constants.AssociativePriorityTable);
    else
        self.auras:Clear();
    end

    local function HandleAura(aura)
        local customCategory = ShouldShowBuffOverride(self, aura);
        if customCategory then
            aura.customCategory = customCategory;
            self.auras[aura.auraInstanceID] = aura;
        end

        return false;
    end

    local batchCount = nil;
    local usePackedAura = true;
    if addon.PROJECT_MAINLINE then
        AuraUtil.ForEachAura(self.unit, "HARMFUL", batchCount, HandleAura, usePackedAura);
    else
        IterateAuras(self, "HARMFUL");
    end

    if SweepyBoop.db.profile.nameplatesEnemy.showBuffsOnEnemy then
        if addon.PROJECT_MAINLINE then
            AuraUtil.ForEachAura(self.unit, "HELPFUL", batchCount, HandleAura, usePackedAura);
        else
            IterateAuras(self, "HELPFUL");
        end
    end
end

local function LayoutRow(self, auras, verticalOffset)
    verticalOffset = verticalOffset or 0; -- buff row will set this based on the height of the debuff row
    if verticalOffset > 0 then
        verticalOffset = verticalOffset + rowGap;
    end

    local leftOffset, rightOffset, frameTopPadding, frameBottomPadding = 0, 0, 0, 0;
    local childrenWidth, childrenHeight = 0, 0;

    for i, child in ipairs(auras) do
        local childWidth, childHeight = child:GetSize();
        local leftPadding, rightPadding, topPadding, bottomPadding = 0, 0, 0, 0;
        local childScale = child:GetScale();
        childWidth = childWidth * childScale;
        childHeight = childHeight * childScale;

        childrenHeight = math.max(childrenHeight, childHeight + topPadding + bottomPadding);
        childrenWidth = childrenWidth + childWidth + leftPadding + rightPadding;
        if (i > 1) then
            childrenWidth = childrenWidth + spacing;
        end

        -- Set child position
        child:ClearAllPoints();

        leftOffset = leftOffset + leftPadding;
        local bottomOffset = frameBottomPadding + bottomPadding;
        child:SetPoint("BOTTOMLEFT", leftOffset / childScale, (bottomOffset + verticalOffset) / childScale);
        leftOffset = leftOffset + childWidth + rightPadding + spacing;
    end

    return childrenWidth, childrenHeight;
end

local function CustomLayout(self)
    -- Separate buffs and debuffs
    local buffs = {};
    local debuffs = {};
    for _, child in ipairs(self.auraFrames) do
        if not child.isActive then
            break;
        end
        if child.isBuff then
            table.insert(buffs, child)
        else
            table.insert(debuffs, child)
        end
    end

    table.sort(debuffs, function (a, b)
        if a.customCategory ~= b.customCategory then
            if ( not b.customCategory ) then
                return true;
            elseif ( not a.customCategory ) then
                return false;
            else
                return a.customCategory < b.customCategory;
            end
        end

        return DefaultAuraCompare(a, b);
    end)

    local _, debuffHeight = LayoutRow(self, debuffs);
    LayoutRow(self, buffs, debuffHeight);
end

local function UpdateBuffs(self, blizzardBuffFrame, unit, unitAuraUpdateInfo)
    if ( not SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled ) or ( not addon.UnitIsHostile(unit) ) then
        self:SetAlpha(0);
        if blizzardBuffFrame then
            blizzardBuffFrame:SetAlpha(1);
        end

        return;
    end

    local previousUnit = self.unit;
    self.unit = unit;

    local aurasChanged = false;
    if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or unit ~= previousUnit or ( not addon.PROJECT_MAINLINE ) then
        -- Note that classic does not have the unitAuraUpdateInfo optimization
        ParseAllAurasOverride(self);
        aurasChanged = true;
    else
        if unitAuraUpdateInfo.addedAuras ~= nil then
            for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
                local customCategory = ShouldShowBuffOverride(self, aura);

                if customCategory then
                    aura.customCategory = customCategory;
                    self.auras[aura.auraInstanceID] = aura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
                if self.auras[auraInstanceID] ~= nil then
                    local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, auraInstanceID);
                    if newAura then
                        newAura.customCategory = self.auras[auraInstanceID].customCategory;
                    end
                    self.auras[auraInstanceID] = newAura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
                if self.auras[auraInstanceID] ~= nil then
                    self.auras[auraInstanceID] = nil;
                    aurasChanged = true;
                end
            end
        end
    end

    if not aurasChanged then return end

    -- Hide previous auras first
    for _, buff in ipairs(self.auraFrames) do
        buff:Hide();
        buff.isActive = false;
    end

    local buffIndex = 1;
    self.auras:Iterate(function(auraInstanceID, aura)
        local buff = self.auraFrames[buffIndex];
        if ( not buff ) then
            buff = CreateFrame("Frame", nil, self, "CustomNameplateBuffButtonTemplate");
            self.auraFrames[buffIndex] = buff;
        end
        buff.auraInstanceID = auraInstanceID;
        buff.isBuff = aura.isHelpful;
        buff.layoutIndex = buffIndex;
        buff.spellID = aura.spellId;
        buff.customCategory = aura.customCategory;

        buff.Icon:SetTexture(aura.icon);
        if (aura.applications > 1) then
            buff.CountFrame.Count:SetText(aura.applications);
            buff.CountFrame.Count:Show();
        else
            buff.CountFrame.Count:Hide();
        end

        if (aura.isStealable) then
            UpdateCrowdControlGlow(buff, false);
            UpdatePurgableGlow(buff, true);
            UpdateBuffGlow(buff, false);
        elseif aura.isHelpful then
            UpdateCrowdControlGlow(buff, false);
            UpdatePurgableGlow(buff, false);
            UpdateBuffGlow(buff, true);
        elseif aura.customCategory == AURA_CATEGORY.CROWD_CONTROL then
            UpdateCrowdControlGlow(buff, true);
            UpdatePurgableGlow(buff, false);
            UpdateBuffGlow(buff, false);
        else
            UpdateCrowdControlGlow(buff, false);
            UpdatePurgableGlow(buff, false);
            UpdateBuffGlow(buff, false);
        end

        -- Issue: icons are smaller than Blizzard default
        local largeIcon = (buff.isBuff or aura.customCategory == AURA_CATEGORY.CROWD_CONTROL);
        buff:SetScale(largeIcon and 1.25 or 1);

        CooldownFrame_Set(buff.Cooldown, aura.expirationTime - aura.duration, aura.duration, aura.duration > 0, true);

        buff.isActive = true;
        buff:Show();

        buffIndex = buffIndex + 1;
        return buffIndex >= BUFF_MAX_DISPLAY;
    end);

    if blizzardBuffFrame then
        blizzardBuffFrame:SetAlpha(0);
    end
    self:SetAlpha(1);
    CustomLayout(self);
end

-- Issue: auras are filtered properly initially but as a fight goes on, auras that are supposed to be hidden show up again
-- Possibly need to override logic for isFullUpdate
addon.OnNamePlateAuraUpdate = function (frame, unit, unitAuraUpdateInfo)
    if auraFilterConflict then
        --print("auraFilterConflict detected, disabling aura filter");
        return;
    end

    if not frame.CustomBuffFrame then
        frame.CustomBuffFrame = CreateFrame("Frame", nil, frame);
        frame.CustomBuffFrame:SetMouseClickEnabled(false);
        frame.CustomBuffFrame:SetSize(200, 28); -- Blizzard sets fixed height 14 for one row, we have 2 rows
        frame.CustomBuffFrame.auraFrames = {};

        if addon.PROJECT_MAINLINE then
            frame.CustomBuffFrame:SetPoint("BOTTOMLEFT", frame.BuffFrame, "BOTTOMLEFT");
        else
            frame.CustomBuffFrame:SetPoint("BOTTOMLEFT", frame.healthBar, "TOPLEFT", 0, 18);
        end
    end

    UpdateBuffs(frame.CustomBuffFrame, frame.BuffFrame, unit, unitAuraUpdateInfo);
end
