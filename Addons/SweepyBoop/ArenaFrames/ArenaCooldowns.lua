local _, addon = ...;

local spellData = addon.SpellData;
local spellResets = addon.SpellResets;

-- This should never change, thus caching it to avoid more calls to game API
local cachedSpellPowerCost = {};
local function GetSpellPowerCost(spellId, powerType)
    cachedSpellPowerCost[spellId] = cachedSpellPowerCost[spellId] or {};

    if ( cachedSpellPowerCost[spellId][powerType] == nil ) then
        local cost = C_Spell.GetSpellPowerCost(spellId);
        if cost and cost[1] and ( cost[1].type == powerType ) then
            cachedSpellPowerCost[spellId][powerType] = cost[1].cost;
        else
            cachedSpellPowerCost[spellId][powerType] = 0; -- set to 0 so we don't call C_Spell.GetSpellPowerCost again
        end
    end

    return cachedSpellPowerCost[spellId][powerType];
end

local interruptToSpellID, resetByPower, resetByCrit;
if addon.PROJECT_MAINLINE then
    interruptToSpellID = {
        [97547] = 78675, -- Solar Beam
    };

    resetByPower = {
        -- 137639, -- Storm, Earth, and Fire (rarely picked)
        1719, -- Recklessness
        262161, -- Warbreaker
        167105, -- Colossus Smash
        227847, -- Bladestorm
        446035, -- Bladestorm (Slayer)
    };
    resetByCrit = {
        190319, -- Combustion
    };
else
    interruptToSpellID = {};
    resetByPower = {};
    resetByCrit = {};
end

local petUnitIdToOwnerId = {
    ["pet"] = "player",
    ["arenapet1"] = "arena1",
    ["arenapet2"] = "arena2",
    ["arenapet3"] = "arena3",
};

local ICON_SET_ID = addon.ICON_SET_ID;
local ARENA_FRAME_BARS = addon.ARENA_FRAME_BARS;

for spellID, spell in pairs(spellData) do
    -- Fill default priority
    spell.priority = spell.index or addon.SPELLPRIORITY.DEFAULT;

    if ( not spell.class ) or ( not C_Spell.GetSpellName(spellID) ) then
        print("Invalid spellID:", spellID);
    end

    if ( not spell.cooldown ) then
        print("Spell missing cooldown:", spellID);
    end

    -- Class should be a string of capital letters
    if spell.class and ( type(spell.class) ~= "string" ) then
        print("Invalid class for spellID:", spellID);
    end

    -- Should we allow entries without class specified?
end

-- iconPool[iconSetID][unitID-spellID]
-- For test icons, iconPool[iconSetID][unitID-spellID-test]
local iconPool = {};

-- Arena frame bars and standalone bars have different names for some config
-- Ideally we want to keep them the same but it's disruptive to change config name since it would mess up players' current settings
local function GetIconSize(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    if ( iconSetID == addon.ICON_SET_ID.ARENA_MAIN ) then
        return config.arenaCooldownTrackerIconSize;
    elseif ( iconSetID == addon.ICON_SET_ID.ARENA_SECONDARY ) then
        return config.arenaCooldownTrackerIconSizeSecondary;
    else
        return config.standaloneBars[iconSetID].iconSize;
    end
end

local function GetIconGlow(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    if ( iconSetID == addon.ICON_SET_ID.ARENA_MAIN ) then
        return config.arenaCooldownTrackerGlow;
    elseif ( iconSetID == addon.ICON_SET_ID.ARENA_SECONDARY ) then
        return config.arenaCooldownTrackerGlowSecondary;
    else
        return config.standaloneBars[iconSetID].glow;
    end
end

addon.GetSpellListConfig = function (iconSetID)
    local spellList;
    if ( iconSetID == ICON_SET_ID.ARENA_MAIN ) then
        spellList = SweepyBoop.db.profile.arenaFrames.spellList;
    elseif ( iconSetID == ICON_SET_ID.ARENA_SECONDARY ) then
        spellList = SweepyBoop.db.profile.arenaFrames.spellList2;
    else
        spellList = SweepyBoop.db.profile.arenaFrames.standaloneBars[iconSetID].spellList;
    end
    return spellList;
end

-- all the other configs that have the same name b/w arena frame bars and standalone bars
addon.GetIconSetConfig = function(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    local iconSetConfig;
    if ARENA_FRAME_BARS[iconSetID] then
        iconSetConfig = config;
    else
        iconSetConfig = config.standaloneBars[iconSetID];
    end
    return iconSetConfig;
end

local function GetIcon(iconSetID, unitID, spellID, test)
    iconPool[iconSetID] = iconPool[iconSetID] or {};
    local iconID = unitID .. "-" .. spellID;
    if test then
        iconID = spellID .. "-test";
    end

    local config = SweepyBoop.db.profile.arenaFrames;
    local iconSetConfig = addon.GetIconSetConfig(iconSetID);

    if ( not iconPool[iconSetID][iconID] ) then
        local size = GetIconSize(iconSetID);
        local glow = GetIconGlow(iconSetID);
        local showName = iconSetConfig.showName and ( not addon.ARENA_FRAME_BARS[iconSetID] );
        iconPool[iconSetID][iconID] = addon.CreateCooldownTrackingIcon(unitID, spellID, size, showName);
        iconPool[iconSetID][iconID].template = ( glow and addon.ICON_TEMPLATE.GLOW ) or addon.ICON_TEMPLATE.FLASH;

        -- https://warcraft.wiki.gg/wiki/API_TextureBase_SetTexCoord
        if iconSetConfig.hideBorder then
            iconPool[iconSetID][iconID].Icon:SetTexCoord(0.078125, 0.921875, 0.078125, 0.921875); -- values copied from Blizzard Interface code
        else
            iconPool[iconSetID][iconID].Icon:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1); -- topleft, bottomleft, topright, bottomright
        end

        if iconPool[iconSetID][iconID].TargetHighlight then
            iconPool[iconSetID][iconID].TargetHighlight:SetVertexColor(0.6745, 0.2902, 0.8392, 1); -- purple
        end

        local classColorName = iconSetConfig.classColorName and ( not addon.ARENA_FRAME_BARS[iconSetID] );
        if ( not classColorName ) or ( not iconPool[iconSetID][iconID].class ) then
            iconPool[iconSetID][iconID].Name:SetTextColor(1, 1, 1);
        else
            local color = RAID_CLASS_COLORS[iconPool[iconSetID][iconID].class];
            iconPool[iconSetID][iconID].Name:SetTextColor(color.r, color.g, color.b);
        end

        addon.SetHideCountdownNumbers(iconPool[iconSetID][iconID], iconSetConfig.hideCountDownNumbers);
        iconPool[iconSetID][iconID].iconSetID = iconSetID;
        iconPool[iconSetID][iconID].isTestGroup = test;
        iconPool[iconSetID][iconID].lastModified = config.lastModified;

        addon.MasqueAddIcon(iconPool[iconSetID][iconID], iconPool[iconSetID][iconID].Icon);
    end

    if ( iconPool[iconSetID][iconID].lastModified ~= config.lastModified ) then
        local size = GetIconSize(iconSetID);
        iconPool[iconSetID][iconID]:SetScale(size / addon.DEFAULT_ICON_SIZE);
        local glow = GetIconGlow(iconSetID);
        iconPool[iconSetID][iconID].template = ( glow and addon.ICON_TEMPLATE.GLOW ) or addon.ICON_TEMPLATE.FLASH;
        local showName = iconSetConfig.showName and ( not addon.ARENA_FRAME_BARS[iconSetID] );
        local classColorName = iconSetConfig.classColorName and ( not addon.ARENA_FRAME_BARS[iconSetID] );
        if ( not classColorName ) or ( not iconPool[iconSetID][iconID].class ) then
            iconPool[iconSetID][iconID].Name:SetTextColor(1, 1, 1);
        else
            local color = RAID_CLASS_COLORS[iconPool[iconSetID][iconID].class];
            iconPool[iconSetID][iconID].Name:SetTextColor(color.r, color.g, color.b);
        end
        iconPool[iconSetID][iconID].Name:SetShown(showName);

        if iconSetConfig.hideBorder then
            iconPool[iconSetID][iconID].Icon:SetTexCoord(0.078125, 0.921875, 0.078125, 0.921875);
        else
            iconPool[iconSetID][iconID].Icon:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1);
        end

        addon.SetHideCountdownNumbers(iconPool[iconSetID][iconID], iconSetConfig.hideCountDownNumbers);

        iconPool[iconSetID][iconID].lastModified = config.lastModified;

        addon.MasqueReskinIcon();
    end

    return iconPool[iconSetID][iconID];
end

-- iconGroups[iconSetID] if tracking all units, otherwise iconGroups[iconSetID-unitID]
-- Append "-test" if it's a test group
local iconGroups = {};

-- Find the first arena frame (addon) to use for anchors
local LARGE_COLUMN = 100; -- Don't break line for each bar
local arenaFrameGrowOptions = {
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT] = {
        direction = "RIGHT",
        anchor = "LEFT",
        columns = LARGE_COLUMN,
        growUpward = false,
    },
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT] = {
        direction = "LEFT",
        anchor = "RIGHT",
        columns = LARGE_COLUMN,
        growUpward = false,
    },
};
local standaloneBarGrowOptions = {
    [addon.STANDALONE_GROW_DIRECTION.CENTER] = {
        direction = "CENTER",
        anchor = "CENTER",
    },
    [addon.STANDALONE_GROW_DIRECTION.LEFT] = {
        direction = "LEFT",
        anchor = "RIGHT",
    },
    [addon.STANDALONE_GROW_DIRECTION.RIGHT] = {
        direction = "RIGHT",
        anchor = "LEFT",
    },
};

local function GetSetPointOptions(iconSetID, unitID)
    local config = SweepyBoop.db.profile.arenaFrames;

    local offsetX;
    if iconSetID == ICON_SET_ID.ARENA_MAIN then
        offsetX = config.arenaCooldownOffsetX;
    elseif iconSetID == ICON_SET_ID.ARENA_SECONDARY then
        offsetX = config.arenaCooldownOffsetXSecondary;
    else
        offsetX = config.standaloneBars[iconSetID].offsetX;
    end

    local offsetY;
    if iconSetID == ICON_SET_ID.ARENA_MAIN then
        offsetY = config.arenaCooldownOffsetY;
    elseif iconSetID == ICON_SET_ID.ARENA_SECONDARY then
        offsetY = config.arenaCooldownOffsetYSecondary;
    else
        offsetY = config.standaloneBars[iconSetID].offsetY;
    end

    local setPointOptions;
    if ARENA_FRAME_BARS[iconSetID] then
        local unitIndex = "1";
        if unitID and unitID ~= "player" then -- arena 1/2/3
            unitIndex = string.sub(unitID, -1);
        end

        local framePrefix = addon.GET_ARENA_FRAME_PREFIX();

        setPointOptions = {
            point = "LEFT",
            relativeTo = framePrefix .. unitIndex,
            relativePoint = "RIGHT",
            offsetX = offsetX,
            offsetY = offsetY;
        };
    else
        setPointOptions = {
            point = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            offsetX = offsetX,
            offsetY = offsetY;
        };
    end

    return setPointOptions;
end

local function GetGrowOptions(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    local growOptions;

    if ( iconSetID == ICON_SET_ID.ARENA_MAIN ) then
        growOptions = arenaFrameGrowOptions[config.arenaCooldownGrowDirection];
        growOptions.margin = config.arenaCooldownTrackerIconPadding;
    elseif ( iconSetID == ICON_SET_ID.ARENA_SECONDARY ) then
        growOptions = arenaFrameGrowOptions[config.arenaCooldownGrowDirectionSecondary];
        growOptions.margin = config.arenaCooldownTrackerIconPaddingSecondary;
    else
        local growDirection = config.standaloneBars[iconSetID].growDirection;
        growOptions = standaloneBarGrowOptions[growDirection];
        growOptions.margin = config.standaloneBars[iconSetID].iconPadding;
        growOptions.columns = config.standaloneBars[iconSetID].columns;
        growOptions.growUpward = config.standaloneBars[iconSetID].growUpward;
    end

    return growOptions;
end

-- Specify unitID for arena frame bars (per unit)
local function GetIconGroup(iconSetID, unitID, isTestGroup)
    local iconGroupID = iconSetID;
    if unitID then
        iconGroupID = iconSetID .. "-" .. unitID;
    end
    if isTestGroup then
        iconGroupID = iconGroupID .. "-test";
    end

    local config = SweepyBoop.db.profile.arenaFrames;
    if ( not iconGroups[iconGroupID] ) then
        local setPointOptions = GetSetPointOptions(iconSetID, unitID);
        local growOptions = GetGrowOptions(iconSetID);
        iconGroups[iconGroupID] = addon.CreateIconGroup(setPointOptions, growOptions, unitID);
        iconGroups[iconGroupID].iconSetID = iconSetID;
        iconGroups[iconGroupID].isTestGroup = isTestGroup;
        -- Have to cache this per group so that they don't interfere with each other
        iconGroups[iconGroupID].guardianSpiritSaved = {};
        iconGroups[iconGroupID].apotheosisUnits = {};
        iconGroups[iconGroupID].combustionUnits = {};
        iconGroups[iconGroupID].premonitionUnits = {};
        iconGroups[iconGroupID].alterTimeApplied = {};
        iconGroups[iconGroupID].alterTimeRemoved = {};
        iconGroups[iconGroupID].groveGuardianOwner = {}; -- Map destGUID to owner unitID
        iconGroups[iconGroupID].lastModified = config.lastModified;
    end

    if ( iconGroups[iconGroupID].lastModified ~= config.lastModified ) then
        local setPointOptions = GetSetPointOptions(iconSetID, unitID);
        local growOptions = GetGrowOptions(iconSetID);
        addon.UpdateIconGroupSetPointOptions(iconGroups[iconGroupID], setPointOptions, growOptions);
        iconGroups[iconGroupID].lastModified = config.lastModified;
    end

    return iconGroups[iconGroupID];
end

local function GetSpecOverrides(spell, spec)
    local overrides = {};

    overrides.spec = spec;

    if ( type(spell.cooldown) == "table" ) and spec then
        overrides.cooldown = spell.cooldown[spec] or spell.cooldown.default;
    else
        overrides.cooldown = spell.cooldown;
    end

    if ( type(spell.charges) == "table" ) and spec then
        overrides.charges = spell.charges[spec];
    else
        overrides.charges = spell.charges;
    end

    return overrides;
end

-- Don't call IconGroup_Wipe here
-- Since for standalone bars we are using one group for all units and don't want to lose icons between setting up arena1 and arena2
-- Callers of this function should make sure to IconGroup_Wipe properly
local function SetupIconGroup(group, unit)
    local iconSetID, isTestGroup = group.iconSetID, group.isTestGroup;
    local config = SweepyBoop.db.profile.arenaFrames;
    local spellList = addon.GetSpellListConfig(iconSetID);
    local iconSetConfig = addon.GetIconSetConfig(iconSetID);

    local class = addon.GetClassForPlayerOrArena(unit);
    local spec;
    if ( not addon.PROJECT_TBC ) then
        spec = addon.GetSpecForPlayerOrArena(unit);
    end
    local remainingTest = 32;
    for spellID, spell in pairs(spellData) do
        if ( not spell.use_parent_icon ) then
            local enabled = false;
            local skipSpellListCheck = false;

            -- For arena frame bars test groups, show disc priest abilities
            if isTestGroup and ARENA_FRAME_BARS[iconSetID] then
                if spell.class == addon.PRIEST then
                    local specEnabled = false;
                    if ( not spell.spec ) then
                        specEnabled = true;
                    else
                        for i = 1, #(spell.spec) do
                            if ( spell.spec[i] == addon.SPECID.DISCIPLINE ) then
                                specEnabled = true;
                                break;
                            end
                        end
                    end

                    if specEnabled then
                        if ( iconSetID == ICON_SET_ID.ARENA_MAIN ) then
                            if config.arenaCooldownSecondaryBar then
                                enabled = ( spell.category ~= addon.SPELLCATEGORY.DEFENSIVE );
                            else
                                enabled = true;
                            end
                        else
                            enabled = (spell.category == addon.SPELLCATEGORY.DEFENSIVE );
                        end
                    end

                    skipSpellListCheck = true;
                end
            else
                -- Fill enabled abilities, but for test groups, show 32 at most
                if isTestGroup then -- a test group need to populate all icons toggled for all classes
                    if ( remainingTest > 0 ) and spellList[tostring(spellID)] then
                        enabled = true;
                        remainingTest = remainingTest - 1;
                    else
                        enabled = false;
                    end
                elseif ( not spell.class ) or ( spell.class == class ) then
                    enabled = true;

                    if spell.spec then
                        local specEnabled = false;

                        if ( not spec ) then
                            specEnabled = true;
                        else
                            for i = 1, #(spell.spec) do
                                if ( spec == spell.spec[i] ) then
                                    specEnabled = true;
                                    break;
                                end
                            end
                        end

                        enabled = specEnabled;
                    end
                end
            end

            if enabled then
                local icon = GetIcon(iconSetID, unit, spellID, isTestGroup);
                icon.info = GetSpecOverrides(spell, spec);
                -- The texture might have been set by use_parent_icon icons
                icon.Icon:SetTexture(addon.GetSpellTexture(spellID));
                if isTestGroup then
                    icon.Name:SetText("SweepyBoop"); -- When hiding test icons then showing again, the test name is not showing up
                end
                addon.IconGroup_PopulateIcon(group, icon, unit .. "-" .. spellID);
                --print("Populated icon", iconSetID, unit, spellID);

                local configSpellID = spell.parent or spellID;
                if spell.baseline and iconSetConfig.showUnusedIcons and ( skipSpellListCheck or spellList[tostring(configSpellID)] ) then
                    icon:SetAlpha(iconSetConfig.unusedIconAlpha);
                    if icon.info.charges and icon.Count then -- If charges baseline, show the charge icon to start with
                        icon.Count.text:SetText("2");
                        icon.Count:Show();
                    end
                    addon.IconGroup_Insert(group, icon);
                end
            end
        end
    end
end

local function GetIconGroupEnabled(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    if ( iconSetID == ICON_SET_ID.ARENA_MAIN ) then
        return config.arenaCooldownTrackerEnabled and addon.ARENA_FRAME_BARS_SUPPORTED();
    elseif ( iconSetID == ICON_SET_ID.ARENA_SECONDARY ) then -- secondary bar depends on main bar being enabled
        return config.arenaCooldownTrackerEnabled and config.arenaCooldownSecondaryBar and addon.ARENA_FRAME_BARS_SUPPORTED();
    else
        return config.standaloneBars[iconSetID].enabled;
    end
end

local function ClearAllIconGroups()
    for _, iconGroup in pairs(iconGroups) do
        addon.IconGroup_Wipe(iconGroup); -- null check is included in IconGroup_Wipe
    end
end

local function SetupAllIconGroups()
    for _, iconSetID in pairs(ICON_SET_ID) do
        if GetIconGroupEnabled(iconSetID) then
            if addon.TEST_MODE then -- debug mode only tracks player
                local unit = "player";
                SetupIconGroup(GetIconGroup(iconSetID, unit), unit);
            else
                if ARENA_FRAME_BARS[iconSetID] then -- one group, one unit
                    for unitIndex = 1, addon.MAX_ARENA_SIZE do
                        local unit = "arena" .. unitIndex;
                        SetupIconGroup(GetIconGroup(iconSetID, unit), unit);
                    end
                else -- one group for all units
                    local group = GetIconGroup(iconSetID);
                    for unitIndex = 1, addon.MAX_ARENA_SIZE do
                        local unit = "arena" .. unitIndex;
                        SetupIconGroup(group, unit);
                    end
                end
            end
        end
    end
end

local function ValidateUnit(self)
    self.unitIdToGuid = self.unitIdToGuid or {};

    if self.unit then
        if ( not self.unitIdToGuid[self.unit] ) then
            self.unitIdToGuid[self.unit] = UnitGUID(self.unit);
        end
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena" .. i;
            if ( not self.unitIdToGuid[unitId] ) then
                self.unitIdToGuid[unitId] = UnitGUID(unitId);
            end
        end
    end

    self.unitGuidToId = self.unitGuidToId or {};

    for unit, guid in pairs(self.unitIdToGuid) do
        if ( not self.unitGuidToId[guid] ) then
            self.unitGuidToId[guid] = unit;
        end
    end

    return self.unitGuidToId;
end

-- Given a pet guid, return the owner unitId
local function IsCastByPet(guid)
    if UnitGUID("pet") == guid then
        return "player";
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        if UnitGUID("arenapet" .. i) == guid then
            return "arena" .. i;
        end
    end
end

local function ResetCooldown(icon, amount, internalCooldown, resetTo) -- if resetTo is set, reset duration to amount, instead of reduce by amount
    if ( not icon.started ) then return end

    if ( icon.template == addon.ICON_TEMPLATE.GLOW ) then
        addon.ResetIconCooldown(icon, amount, resetTo);

        -- Duration has more than 1s left, hide cooldown
        -- Duration frame's finish event handler will show the cooldown
        if icon.duration and icon.duration.finish and ( GetTime() < icon.duration.finish - 1 ) then
            icon.cooldown:Hide();
        end
    else
        addon.ResetCooldownTrackingCooldown(icon, amount, internalCooldown, resetTo);
    end
end

local function ProcessCooldownReductionFromGroveGuardian(group, destGUID)
    local unit = group.groveGuardianOwner[destGUID]; -- If Grove Guardian is killed before expiring, this will be set to nil by UNIT_DIED event processor
    if unit then
        if group.activeMap[unit .. "-" .. 33891] then
            ResetCooldown(group.activeMap[unit .. "-" .. 33891], 5);
        elseif group.activeMap[unit .. "-" .. 473909] then
            ResetCooldown(group.activeMap[unit .. "-" .. 473909], 2.5); -- reduced by half for Ancient of Lore?
        end

        group.groveGuardianOwner[destGUID] = nil;
    end
end

local function ProcessCombatLogEvent(self, subEvent, sourceGUID, destGUID, spellId, spellName, critical, isTestGroup)
    local unitGuidToId = ValidateUnit(self);
    -- If units don't exist, unitGuidToId will be empty
    if next(unitGuidToId) == nil then return end

    if addon.PROJECT_MAINLINE then

        -- Apotheosis
        if ( spellId == 200183 ) and ( subEvent == addon.SPELL_AURA_APPLIED or subEvent == addon.SPELL_AURA_REMOVED ) then
            local unit = unitGuidToId[sourceGUID];
            if unit then
                if subEvent == addon.SPELL_AURA_APPLIED then
                    self.apotheosisUnits[unit] = true;
                else
                    self.apotheosisUnits[unit] = nil;
                end
            end
        end

        -- Premonition of Insight
        if ( spellId == 428933 ) and ( subEvent == addon.SPELL_AURA_APPLIED or subEvent == addon.SPELL_AURA_REMOVED ) then
            local unit = unitGuidToId[sourceGUID];
            if unit then
                if subEvent == addon.SPELL_AURA_APPLIED then -- We probably don't need the 20s timer for apotheosis either
                    self.premonitionUnits[unit] = true;
                else
                    self.premonitionUnits[unit] = nil;
                end
            end
        end

        -- Combustion
        if ( spellId == 190319 ) and ( subEvent == addon.SPELL_AURA_APPLIED or subEvent == addon.SPELL_AURA_REMOVED ) then
            local unit = unitGuidToId[sourceGUID];
            if unit then
                if subEvent == addon.SPELL_AURA_APPLIED then
                    self.combustionUnits[unit] = true;
                else
                    self.combustionUnits[unit] = nil;
                end
            end
        end

        -- Guardian Spirit saved their teammate thus should be put on a longer cooldown (+120s)
        if ( spellId == 48153 ) and ( subEvent == addon.SPELL_HEAL ) then
            local unit = unitGuidToId[sourceGUID];
            if unit then
                self.guardianSpiritSaved[unit] = true;
            end

            return;
        end
        -- Now check if we need to reduce Guardian Spirit cooldown
        -- SPELL_AURA_REMOVED is fired twice, causing GS to be reset even if the healing proc
        -- Workaround by checking timestamp now vs. last aura removed
        if ( spellId == 47788 ) and ( subEvent == addon.SPELL_AURA_REMOVED ) then
            local unit = unitGuidToId[sourceGUID];
            if unit then
                if self.guardianSpiritSaved[unit] then
                    self.guardianSpiritSaved[unit] = nil;
                else
                    local icon = self.activeMap[unit .. "-" .. spellId];
                    if icon then
                        ResetCooldown(icon, 60, nil, true); -- reduce CD to 1 min starting from now, not reducing by a fixed amount
                    end
                end
            end

            return;
        end

        -- Blink / Shimmer reset by Alter Time
        -- Order of events on 1st press: SPELL_AURA_APPLIED, SPELL_CAST_SUCCESS, SPELL_SUMMON
        -- Order of events on 2nd press: SPELL_AURA_REMOVED, SPELL_CAST_SUCCESS
        -- Order of events on Alter Time being purged: SPELL_AURA_REMOVED, SPELL_DISPEL
        -- Track time of Alter Time buff applied / removed -> if it's full duration 10s, then it naturally expired hence it's a reset
        -- If it expires prematurely, track buff removed time, and check following event (if SPELL_CAST_SUCCESS then reset; otherwise don't, including right click cancel case)
        if ( spellId == 342246 ) and ( subEvent == addon.SPELL_AURA_APPLIED or subEvent == addon.SPELL_AURA_REMOVED ) then
            local unit = unitGuidToId[sourceGUID];
            if unit then
                self.alterTimeRemoved[unit] = nil;
                if subEvent == addon.SPELL_AURA_APPLIED then
                    self.alterTimeApplied[unit] = GetTime();
                else
                    if self.alterTimeApplied[unit] then
                        local now = GetTime();
                        if ( now - self.alterTimeApplied[unit] ) > 9.99 then -- If Alter Time buff expired naturally (i.e., full 10s duration), reset Blink / Shimmer
                            local icon = self.activeMap[unit .. "-" .. 1953] or self.activeMap[unit .. "-" .. 212653];
                            if icon then
                                ResetCooldown(icon, 25); -- It's granting a charge of 25s (not the 21s after taking Flow of Time)
                            end
                        else
                            self.alterTimeRemoved[unit] = now; -- Track time of buff removed, and do reset if followed by a SPELL_CAST_SUCCESS event
                        end
                    end

                    self.alterTimeApplied[unit] = nil;
                end
            end
        elseif ( spellId == 342247 ) and ( subEvent == addon.SPELL_CAST_SUCCESS ) then -- Second Alter Time press
            local unit = unitGuidToId[sourceGUID];
            if unit then
                if self.alterTimeRemoved[unit] then
                    local now = GetTime();
                    if ( now - self.alterTimeRemoved[unit] ) < 1 then -- If this event happens within 1s after Alter Time buff removed, reset Blink / Shimmer
                        local icon = self.activeMap[unit .. "-" .. 1953] or self.activeMap[unit .. "-" .. 212653];
                        if icon then
                            ResetCooldown(icon, 25); -- It's granting a charge of 25s (not the 21s after taking Flow of Time)
                        end
                    end

                    self.alterTimeRemoved[unit] = nil;
                end
            end
        end

        -- Cooldown reduction from Grove Guardians
        if ( spellId == 102693 ) and ( subEvent == addon.SPELL_SUMMON ) then
            local unit = unitGuidToId[sourceGUID];
            if unit then
                self.groveGuardianOwner[destGUID] = unit;
                C_Timer.After(15, function()
                    ProcessCooldownReductionFromGroveGuardian(self, destGUID);
                end);
            end

            return;
        -- elseif ( spellId == 102693 ) and ( subEvent == addon.UNIT_DIED ) then
        --     -- Grove Guardian being killed doesn't fire this event, so this is not actually working
        --     local unit = self.groveGuardianOwner[destGUID];
        --     if unit then
        --         if self.activeMap[unit .. "-" .. 33891] then
        --             ResetCooldown(self.activeMap[unit .. "-" .. 33891], 5);
        --         elseif self.activeMap[unit .. "-" .. 473909] then
        --             ResetCooldown(self.activeMap[unit .. "-" .. 473909], 2.5); -- reduced by half for Ancient of Lore?
        --         end
        --     end

        --     self.groveGuardianOwner[destGUID] = nil;
        --     return;
        end

    end

    -- Check resets by spell cast
    if ( subEvent == addon.SPELL_CAST_SUCCESS ) and unitGuidToId[sourceGUID] then
        local unit = unitGuidToId[sourceGUID];
        -- Check reset by power
        for i = 1, #resetByPower do
            local spellToReset = resetByPower[i];
            local icon = self.activeMap[unit .. "-" .. spellToReset];
            if icon and icon.started then -- ResetCooldown has started check, but here we check to skip the power calculation, which could be costly
                local cost = GetSpellPowerCost(spellId, spellData[spellToReset].reduce_power_type);
                if cost > 0 then
                    local amount = spellData[spellToReset].reduce_amount * cost;
                    --print("Resetting cooldown for", spellToReset, "by", amount, "for", spellId);
                    ResetCooldown(icon, amount);
                end
            end
        end

        -- Check regular resets
        if spellResets[spellId] then
            for i = 1, #(spellResets[spellId]) do
                local reset = spellResets[spellId][i];

                local spellToReset;
                local amount;
                if type(reset) == "table" and reset.amount then
                    spellToReset = reset.spellID;
                    amount = reset.amount;
                else
                    if type(reset) == "table" then
                        spellToReset = reset.spellID;
                    else
                        spellToReset = reset;
                    end
                end

                if addon.SpellResetsAffectedByApotheosis[spellId] then
                    local modifier = ( self.apotheosisUnits[unit] and addon.SpellResetsAffectedByApotheosis[spellId] ) or 1;
                    amount = amount * modifier;
                end

                local icon = self.activeMap[unit .. "-" .. spellToReset];
                if icon then
                    --print("Icon cooldown before reduction:", icon.timers[1].duration);
                    ResetCooldown(icon, amount);
                    --print("Icon cooldown after reduction:", icon.timers[1].duration);
                end
            end
        end
    end

    -- Check resets by crit damage (e.g., combustion)
    if unitGuidToId[sourceGUID] then
        local unit = unitGuidToId[sourceGUID];
        for i = 1, #resetByCrit do
            local spellToReset = resetByCrit[i];
            local icon = self.activeMap[unit .. "-" .. spellToReset];
            if icon and icon.started and spellData[spellToReset].critResets and spellData[spellToReset].critResets[spellId] then
                if ( subEvent == addon.SPELL_DAMAGE ) and critical then
                    ResetCooldown(icon, spellData[spellToReset].critResets[spellId]);
                end

                -- Extra CDR if Combustion is currently active (Unleashed Inferno)
                if self.combustionUnits[unit] and ( subEvent == addon.SPELL_CAST_SUCCESS ) then
                    ResetCooldown(icon, 1.25);
                end

                return;
            end
        end
    end

    -- Check reset by interrupts, Counterspell, solar Beam
    -- Solar Beam only reduces 15s when interrupting main target, how do we detect it? Cache last reduce time?
    if ( subEvent == addon.SPELL_INTERRUPT ) and unitGuidToId[sourceGUID] then
        local unit = unitGuidToId[sourceGUID];
        local spellIdOveride = interruptToSpellID[spellId] or spellId;
        local icon = self.activeMap[unit .. "-" .. spellIdOveride];
        local amount = icon and icon.spellInfo.reduce_on_interrupt;
        if icon and amount then
            ResetCooldown(icon, amount, amount);
        end
    end

    -- Validate spell
    if ( not spellData[spellId] ) then return end
    local spell = spellData[spellId];

    -- Validate unit
    local unit;
    local spellGUID = ( spell.trackDest and destGUID ) or sourceGUID;
    if spell.trackPet then
        unit = IsCastByPet(spellGUID) or unitGuidToId[spellGUID];
    else
        unit = unitGuidToId[spellGUID];
    end
    if ( not unit ) then return end

    -- Check spell dismiss (check by sourceGUID unless trackDest is specified)
    if ( subEvent == addon.SPELL_AURA_REMOVED ) and unitGuidToId[sourceGUID] then
        local icon = self.activeMap[unitGuidToId[sourceGUID] .. "-" .. spellId];
        if icon and ( icon.template == addon.ICON_TEMPLATE.GLOW ) then
            addon.ResetGlowDuration(icon);
            return;
        end
    end

    -- Validate subEvent
    local validateSubEvent;
    if spell.trackEvent then
        validateSubEvent = ( subEvent == spell.trackEvent );
    else
        validateSubEvent = ( subEvent == addon.SPELL_CAST_SUCCESS );
    end
    if ( not validateSubEvent ) then return end

    -- Find the icon to use (check parent too)
    -- Config only shows parent ID, so check parent if applicable
    local spellList = addon.GetSpellListConfig(self.iconSetID);
    local configSpellId = spell.parent or spellId;
    local iconSpellId = ( spell.use_parent_icon and spell.parent ) or spellId;
    local iconID = unit .. "-" .. iconSpellId;
    if self.icons[iconID] and ( isTestGroup or spellList[tostring(configSpellId)] ) then
        if ( iconSpellId ~= spellId ) then
            if spell.replace_parent_icon then
                -- if icon texture is different
                -- for some spells, we intentionally don't replace the texture, e.g., Skull Bash (Bear Form)
                self.icons[iconID].Icon:SetTexture(addon.GetSpellTexture(spellId));
            end

            if self.icons[iconID].info then -- e.g., Anti-Magic Shell (Spellwarden) modifies cooldown as well
                self.icons[iconID].info.cooldown = spell.cooldown;
            end
        end

        addon.StartCooldownTrackingIcon(self.icons[iconID]);

        -- Premonition cooldown reduction
        -- This can be implemented reliably SPELL_AURA_REMOVED arrives after SPELL_CAST_SUCCESS, and we don't reset preminitionUnits here
        -- Ensure this doesn't affect the wrong units - iconID is built with unit, and we are checking premonitionUnits[unit]
        if self.premonitionUnits[unit] then
            ResetCooldown(self.icons[iconID], 7);
        end
    end
end

local function ProcessUnitSpellCast(self, event, ...)
    ValidateUnit(self);
    if next(self.unitIdToGuid) == nil then return end

    local unitTarget, _, spellID = ...;
    if ( not unitTarget ) then return end
    local spell = spellData[spellID];
    if ( not spell ) or ( spell.trackEvent ~= addon.UNIT_SPELLCAST_SUCCEEDED ) then return end
    if spell.trackPet then
        unitTarget = petUnitIdToOwnerId[unitTarget] or unitTarget;
    end
    if ( not self.unitIdToGuid[unitTarget] ) then return end

    local iconSpellID = ( spell.use_parent_icon and spell.parent ) or spellID;
    local iconID = unitTarget .. "-" .. iconSpellID;
    if self.icons[iconID] then
        local spellList = addon.GetSpellListConfig(self.iconSetID);

        local configSpellID = spell.parent or spellID;
        if spellList[tostring(configSpellID)] then
            addon.StartCooldownTrackingIcon(self.icons[iconID]);
        end
    end
end

local function ProcessUnitAura(self, event, ...)
    ValidateUnit(self);
    if next(self.unitIdToGuid) == nil then return end

    local unitTarget, updateAuras = ...;
    if ( not unitTarget ) or ( not self.unitIdToGuid[unitTarget] ) then return end

    -- Only use UNIT_AURA to extend aura
    if updateAuras and updateAuras.updatedAuraInstanceIDs then
        for _, instanceID in ipairs(updateAuras.updatedAuraInstanceIDs) do
            local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, instanceID);
            if auraData then
                local spellID = auraData.spellId;
                local spell = spellData[spellID];
                if spell and spell.extend then
                    local iconSpellID = ( spell.use_parent_icon and spell.parent ) or spellID;
                    local iconID = unitTarget .. "-" .. iconSpellID;
                    if self.activeMap[iconID] then
                        addon.RefreshGlowDuration(self.activeMap[iconID], auraData.duration, auraData.expirationTime);
                    end
                end
            end
        end
    end
end

local function ProcessUnitEvent(group, event, ...)
    if ( event == addon.UNIT_SPELLCAST_SUCCEEDED ) then
        ProcessUnitSpellCast(group, event, ...);
    elseif ( event == addon.UNIT_AURA ) then
        ProcessUnitAura(group, event, ...);
    end
end

local function UpdateAllHighlights(group)
    for i = 1, #(group.active) do
        addon.UpdateTargetHighlight(group.active[i]);
    end
end

local unitNames = {};

local function UpdateUnitNames(group)
    for _, icon in pairs(group.icons) do
        local unit = icon.unit;
        if unit then
            local name = unitNames[unit] or "";
            icon.Name:SetText(name);
        end
    end
end

function SweepyBoop:TestArenaCooldownTracker()
    local secondaryBarEnabled = SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar;

    local mainBarID = ICON_SET_ID.ARENA_MAIN .. "-player-test";
    local secondaryBarID = ICON_SET_ID.ARENA_SECONDARY .. "-player-test";

    addon.IconGroup_Wipe(iconGroups[mainBarID]);
    addon.IconGroup_Wipe(iconGroups[secondaryBarID]); -- Secondary bar

    SetupIconGroup(GetIconGroup(ICON_SET_ID.ARENA_MAIN, "player", true), "player");
    if secondaryBarEnabled then
        SetupIconGroup(GetIconGroup(ICON_SET_ID.ARENA_SECONDARY, "player", true), "player");
    end

    local subEvent = addon.SPELL_CAST_SUCCESS;
    local sourceGUID = UnitGUID("player");
    local destGUID = UnitGUID("player");
    local spellId = 10060; -- Power Infusion
    ProcessCombatLogEvent(iconGroups[mainBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 8122; -- Psychic Scream
    ProcessCombatLogEvent(iconGroups[mainBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 33206; -- Pain Suppression
    ProcessCombatLogEvent(iconGroups[mainBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);
    if secondaryBarEnabled then
        ProcessCombatLogEvent(iconGroups[secondaryBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);
    end

    spellId = 62618; -- Power Word: Barrier
    ProcessCombatLogEvent(iconGroups[mainBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);
    if secondaryBarEnabled then
        ProcessCombatLogEvent(iconGroups[secondaryBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);
    end

    iconGroups[mainBarID]:Show();
    if SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar then
        iconGroups[secondaryBarID]:Show();
    end
end

function SweepyBoop:HideTestArenaCooldownTracker()
    local mainBar = iconGroups[ICON_SET_ID.ARENA_MAIN .. "-player-test"];
    local secondaryBar = iconGroups[ICON_SET_ID.ARENA_SECONDARY .. "-player-test"]; -- Secondary bar

    addon.IconGroup_Wipe(mainBar);
    addon.IconGroup_Wipe(secondaryBar);
    if mainBar then
        mainBar:Hide();
    end
    if secondaryBar then
        secondaryBar:Hide();
    end
end

local function RepositionExternalTestGroup(iconGroupID, unitID)
    if ( not iconGroups[iconGroupID] ) or ( not iconGroups[iconGroupID]:IsShown() ) then return end

    local growOptions = GetGrowOptions(iconGroups[iconGroupID].iconSetID);
    local setPointOptions = GetSetPointOptions(iconGroups[iconGroupID].iconSetID, unitID);
    addon.UpdateIconGroupSetPointOptions(iconGroups[iconGroupID], setPointOptions, growOptions);
end

function SweepyBoop:RepositionArenaCooldownTracker(layoutIcons)
    RepositionExternalTestGroup(ICON_SET_ID.ARENA_MAIN .. "-player-test", "player");
    RepositionExternalTestGroup(ICON_SET_ID.ARENA_SECONDARY .. "-player-test", "player");

    if layoutIcons then
        addon.IconGroup_Position(iconGroups[ICON_SET_ID.ARENA_MAIN .. "-player-test"]);
        addon.IconGroup_Position(iconGroups[ICON_SET_ID.ARENA_SECONDARY .. "-player-test"]);
    end
end

function SweepyBoop:RepositionArenaStandaloneBar(groupName, layoutIcons)
    local iconGroupID = groupName .. "-player-test";
    RepositionExternalTestGroup(iconGroupID);
    if layoutIcons then
        addon.IconGroup_Position(iconGroups[iconGroupID]);
    end
end

function SweepyBoop:TestArenaStandaloneBars()
    for i = 1, 6 do
        local iconSetID = "Bar " .. i;
        local iconGroupID = iconSetID .. "-player-test";
        addon.IconGroup_Wipe(iconGroups[iconGroupID]);

        if GetIconGroupEnabled(iconSetID) then
            local iconGroup = GetIconGroup(iconSetID, "player", true);
            SetupIconGroup(iconGroup, "player");

            -- Fire an event with every spellID in that group
            local sourceGUID = UnitGUID("player");
            local destGUID = UnitGUID("player");
            for _, icon in pairs(iconGroup.icons) do
                local subEvent = icon.spellInfo.trackEvent or addon.SPELL_CAST_SUCCESS;
                ProcessCombatLogEvent(iconGroup, subEvent, sourceGUID, destGUID, icon.spellID, nil, nil, true);
            end

            iconGroup:Show();
        end
    end
end

function SweepyBoop:HideTestArenaStandaloneBars()
    for i = 1, 6 do
        local iconGroup = iconGroups["Bar " .. i .. "-player-test"];
        if iconGroup then
            addon.IconGroup_Wipe(iconGroup);
            iconGroup:Hide();
        end
    end
end

local eventFrame;

function SweepyBoop:SetupArenaCooldownTracker()
    -- Refresh icon groups when zone changes, or during test mode when player switches spec
    if ( not eventFrame ) then
        eventFrame = CreateFrame("Frame");
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        if addon.PROJECT_TBC then
            eventFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
        else
            eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        end
        eventFrame:RegisterEvent(addon.PLAYER_SPECIALIZATION_CHANGED);
        eventFrame:RegisterEvent(addon.COMBAT_LOG_EVENT_UNFILTERED);
        eventFrame:RegisterEvent(addon.UNIT_AURA);
        eventFrame:RegisterEvent(addon.UNIT_SPELLCAST_SUCCEEDED);
        eventFrame:RegisterEvent(addon.PLAYER_TARGET_CHANGED);
        eventFrame:SetScript("OnEvent", function (frame, event, ...)
            local config = SweepyBoop.db.profile.arenaFrames;
            if ( event == addon.PLAYER_ENTERING_WORLD ) or ( event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS ) or ( event == addon.ARENA_OPPONENT_UPDATE ) or ( event == addon.PLAYER_SPECIALIZATION_CHANGED and addon.TEST_MODE and addon.PROJECT_MAINLINE ) then
                if ( event == addon.ARENA_OPPONENT_UPDATE ) then
                    local unit, reason = ...;
                    if ( reason ~= "cleared" ) then
                        return;
                    end
                end

                -- PLAYER_SPECIALIZATION_CHANGED is triggered for all players, so we only process it when TEST_MODE is on
                -- PLAYER_SPECIALIZATION_CHANGED is triggered by Stampede in MoP, we should only process it for retail...

                -- Hide the external "Toggle Test Mode" group
                SweepyBoop:HideTestArenaCooldownTracker();
                SweepyBoop:HideTestArenaStandaloneBars();

                unitNames = {};
                ClearAllIconGroups();

                local shouldSetup = false;
                if addon.TEST_MODE then
                    shouldSetup = true;
                elseif ( event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS ) then
                    shouldSetup = true;
                elseif ( event == addon.PLAYER_ENTERING_WORLD ) then
                    if addon.PROJECT_MAINLINE then
                        shouldSetup = IsActiveBattlefieldArena() and ( C_PvP.GetActiveMatchState() < Enum.PvPMatchState.Engaged );
                    else
                        -- Classic doesn't have C_PvP.GetActiveMatchState, the Preparation buff is also missing in MoP
                        -- Just refresh icons for now since there lacks a reliable way to check if we are in prep stage
                        -- if IsActiveBattlefieldArena() then
                        --     local auraData = C_UnitAuras.GetPlayerAuraBySpellID(44521);
                        --     shouldSetup = auraData and auraData.name;
                        -- end
                        shouldSetup = IsActiveBattlefieldArena();
                    end
                end
                if shouldSetup then
                    SetupAllIconGroups();
                end
            elseif ( event == addon.COMBAT_LOG_EVENT_UNFILTERED ) then
                if ( not IsActiveBattlefieldArena() ) and ( not addon.TEST_MODE ) then return end
                local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName, _, _, _, _, _, _, _, critical = CombatLogGetCurrentEventInfo();

                -- Process arena frame bars if enabled
                if addon.TEST_MODE then
                    local arenaMain = iconGroups[ICON_SET_ID.ARENA_MAIN .. "-player"];
                    if arenaMain and GetIconGroupEnabled(ICON_SET_ID.ARENA_MAIN) then
                        ProcessCombatLogEvent(arenaMain, subEvent, sourceGUID, destGUID, spellId, spellName, critical);
                    end

                    local arenaSecondary = iconGroups[ICON_SET_ID.ARENA_SECONDARY .. "-player"];
                    if arenaSecondary and GetIconGroupEnabled(ICON_SET_ID.ARENA_SECONDARY) then
                        ProcessCombatLogEvent(arenaSecondary, subEvent, sourceGUID, destGUID, spellId, spellName, critical);
                    end
                else
                    local arenaMainEnabled = GetIconGroupEnabled(ICON_SET_ID.ARENA_MAIN);
                    local arenaSecondaryEnabled = GetIconGroupEnabled(ICON_SET_ID.ARENA_SECONDARY);

                    for i = 1, addon.MAX_ARENA_SIZE do
                        local unit = "arena" .. i;
                        local iconGroupID = ICON_SET_ID.ARENA_MAIN .. "-" .. unit;
                        local iconGroup = iconGroups[iconGroupID];
                        if iconGroup and arenaMainEnabled then
                            ProcessCombatLogEvent(iconGroup, subEvent, sourceGUID, destGUID, spellId, spellName, critical);
                        end

                        iconGroupID = ICON_SET_ID.ARENA_SECONDARY .. "-" .. unit;
                        iconGroup = iconGroups[iconGroupID];
                        if iconGroup and arenaSecondaryEnabled then
                            ProcessCombatLogEvent(iconGroup, subEvent, sourceGUID, destGUID, spellId, spellName, critical);
                        end
                    end
                end

                for i = 1, 6 do
                    local iconSetID = "Bar " .. i;
                    if GetIconGroupEnabled(iconSetID) then
                        local iconGroupID = iconSetID;
                        if addon.TEST_MODE then
                            iconGroupID = iconGroupID .. "-player";
                        end
                        local iconGroup = iconGroups[iconGroupID];
                        if iconGroup then
                            ProcessCombatLogEvent(iconGroup, subEvent, sourceGUID, destGUID, spellId, spellName, critical);
                        end
                    end
                end
            elseif ( event == addon.UNIT_AURA ) or ( event == addon.UNIT_SPELLCAST_SUCCEEDED ) then
                if ( not IsActiveBattlefieldArena() ) and ( not addon.TEST_MODE ) then return end

                local nameUpdated = false;
                local unitTarget = ...;
                if ( not unitNames[unitTarget] ) then
                    unitNames[unitTarget] = UnitName(unitTarget);
                    if unitNames[unitTarget] then
                        nameUpdated = true;
                    end
                end

                -- Process arena frame bars if enabled
                if addon.TEST_MODE then
                    local arenaMain = iconGroups[ICON_SET_ID.ARENA_MAIN .. "-player"];
                    if arenaMain and GetIconGroupEnabled(ICON_SET_ID.ARENA_MAIN) then
                        ProcessUnitEvent(arenaMain, event, ...);
                    end

                    local arenaSecondary = iconGroups[ICON_SET_ID.ARENA_SECONDARY .. "-player"];
                    if arenaSecondary and GetIconGroupEnabled(ICON_SET_ID.ARENA_SECONDARY) then
                        ProcessUnitEvent(arenaSecondary, event, ...);
                    end
                else
                    local arenaMainEnabled = GetIconGroupEnabled(ICON_SET_ID.ARENA_MAIN);
                    local arenaSecondaryEnabled = GetIconGroupEnabled(ICON_SET_ID.ARENA_SECONDARY);

                    for i = 1, addon.MAX_ARENA_SIZE do
                        local unit = "arena" .. i;
                        local iconGroupID = ICON_SET_ID.ARENA_MAIN .. "-" .. unit;
                        local iconGroup = iconGroups[iconGroupID];
                        if iconGroup and arenaMainEnabled then
                            ProcessUnitEvent(iconGroup, event, ...);
                        end

                        iconGroupID = ICON_SET_ID.ARENA_SECONDARY .. "-" .. unit;
                        iconGroup = iconGroups[iconGroupID];
                        if iconGroup and arenaSecondaryEnabled then
                            ProcessUnitEvent(iconGroup, event, ...);
                        end
                    end
                end

                for i = 1, 6 do
                    local iconSetID = "Bar " .. i;
                    if GetIconGroupEnabled(iconSetID) then
                        local iconGroupID = iconSetID;
                        if addon.TEST_MODE then
                            iconGroupID = iconGroupID .. "-player";
                        end
                        local iconGroup = iconGroups[iconGroupID];
                        if iconGroup then
                            if nameUpdated then
                                UpdateUnitNames(iconGroup);
                            end
                            ProcessUnitEvent(iconGroup, event, ...);
                        end
                    end
                end
            elseif ( event == addon.PLAYER_TARGET_CHANGED ) then
                local isArena = IsActiveBattlefieldArena() or addon.TEST_MODE;

                for i = 1, 6 do
                    local iconSetID = "Bar " .. i;
                    if GetIconGroupEnabled(iconSetID) then
                        if isArena then
                            local iconGroupID = iconSetID;
                            if addon.TEST_MODE then
                                iconGroupID = iconGroupID .. "-player";
                            end
                            local iconGroup = iconGroups[iconGroupID];
                            if iconGroup then
                                UpdateAllHighlights(iconGroup);
                            end
                        else
                            local testGroup = iconGroups[iconSetID .. "-player-test"];
                            if testGroup then
                                UpdateAllHighlights(testGroup);
                            end
                        end
                    end
                end
            end
        end)
    end
end
