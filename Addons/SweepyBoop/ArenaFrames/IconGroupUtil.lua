local _, addon = ...;

addon.CreateIconGroup = function (setPointOptions, growOptions, unit)
    local point, relativeTo, relativePoint, offsetX, offsetY =
        setPointOptions.point, setPointOptions.relativeTo, setPointOptions.relativePoint, setPointOptions.offsetX, setPointOptions.offsetY;

    local f = CreateFrame("Frame", nil, UIParent);
    f:SetSize(1, 1);

    local relativeToFrame = _G[relativeTo];
    if relativeToFrame and relativeToFrame:IsShown() then
        f:ClearAllPoints();
        f:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
    else
        f.setPointOptions = setPointOptions;
    end

    -- e.g., grow = "LEFT", growAnchor = "BOTTOMRIGHT": set icon's bottomright to group's bottom right
    f.growDirection = growOptions.direction;
    f.growAnchor = growOptions.anchor;
    f.margin = growOptions.margin;
    f.columns = growOptions.columns; -- For center alignment only
    f.growUpward = growOptions.growUpward; -- "UP" or "DOWN"

    f.unit = unit;

    f.icons = {}; -- Table, spellID -> icon
    f.active = {}; -- Array of active icons, sort by priority
    f.activeMap = {}; -- Table, spellID -> icon
    f.npcMap = {}; -- Table, npcGUID -> spellID, for processing SPELL_SUMMON / UNIT_DIED

    return f;
end

addon.UpdateIconGroupSetPointOptions = function (iconGroup, setPointOptions, growOptions)
    local point, relativeTo, relativePoint, offsetX, offsetY =
        setPointOptions.point, setPointOptions.relativeTo, setPointOptions.relativePoint, setPointOptions.offsetX, setPointOptions.offsetY;

    local relativeToFrame = _G[relativeTo];
    if relativeToFrame and relativeToFrame:IsShown() then
        iconGroup:ClearAllPoints();
        iconGroup:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
    else
        iconGroup.setPointOptions = setPointOptions;
    end

    iconGroup.growDirection = growOptions.direction;
    iconGroup.growAnchor = growOptions.anchor;
    iconGroup.margin = growOptions.margin;
    iconGroup.columns = growOptions.columns; -- For center alignment only
    iconGroup.growUpward = growOptions.growUpward; -- "UP" or "DOWN"

    -- Leave other fields untouched, we're only updating position-related settings
end


addon.IconGroup_Position = function(group)
    if ( not group ) or ( #(group.active) == 0 ) then
        return;
    end

    local baseIconSize = group.active[1]:GetWidth();

    -- Reposition icons
    local growDirection = group.growDirection;
    local anchor = group.growAnchor;
    local numActive = #(group.active);

    local count, rows = 0, 1;
    local grow = group.growUpward and 1 or -1;
    local margin = group.margin;

    for i = 1, numActive do
        group.active[i]:ClearAllPoints();
        local columns = ( group.columns and group.columns < numActive and group.columns ) or numActive;
        if ( i == 1 ) then
            if growDirection == "CENTER" then
                group.active[i]:SetPoint(anchor, group, anchor, (-baseIconSize-margin)*(columns-1)/2, 0);
            else
                group.active[i]:SetPoint(anchor, group, anchor, 0, 0);
            end
        else
            count = count + 1;

            if ( count >= columns ) then
                if growDirection == "CENTER" then
                    group.active[i]:SetPoint(anchor, group, anchor, (-baseIconSize-margin)*(columns-1)/2, (baseIconSize+margin)*rows*grow);
                else
                    group.active[i]:SetPoint(anchor, group, anchor, 0, (baseIconSize+margin)*rows*grow);
                end

                count = 0;
                rows = rows + 1;
            else
                if growDirection == "LEFT" then
                    group.active[i]:SetPoint("TOPRIGHT", group.active[i-1], "TOPLEFT", -1 * margin, 0);
                else
                    group.active[i]:SetPoint("TOPLEFT", group.active[i-1], "TOPRIGHT", margin, 0);
                end
            end
        end
    end
end

local function sortFuncArenaFrames(a, b)
    local config = SweepyBoop.db.profile.arenaFrames.spellCatPriority;
    local catPriorityA = config[tostring(a.category)];
    local catPriorityB = config[tostring(b.category)];

    if ( catPriorityA ~= catPriorityB ) then
        return catPriorityA > catPriorityB;
    end

    if ( a.priority ~= b.priority ) then
        return a.priority < b.priority;
    end

    if ( a.timeStamp ~= b.timeStamp ) then
        return a.timeStamp < b.timeStamp;
    end

    return a.spellID < b.spellID; -- If all the above are tied, sort by spellID
end

local function sortFuncStandaloneBars(a, b)
    if ( a.unit ~= b.unit ) then
        return a.unit < b.unit; -- Sort by unit first, so that all icons for the same unit are grouped together
    end

    if ( a.timeStamp ~= b.timeStamp ) then
        return a.timeStamp < b.timeStamp;
    end

    return a.spellID < b.spellID;
end

addon.IconGroup_Insert = function (group, icon, index)
    if ( not group ) then return end

    -- If already showing, do not need to add
    if icon:IsShown() then
        -- baseline icon needs to be added to activeMap if not already there
        if index then
            group.activeMap[index] = icon;
        end
        return;
    end

    -- Re-adjust positioning if this group attaches to an arena frame, since arena frames can change position
    if group.setPointOptions then
        local options = group.setPointOptions;

        -- Getting LUA errors "Couldn't find region named GladiusButtonFramearena3", is it erroring in 2v2 games?
        -- If still not visible, delay SetPoint again
        local relativeToFrame = _G[options.relativeTo];
        if relativeToFrame then
            group:ClearAllPoints();
            group:SetPoint(options.point, options.relativeTo, options.relativePoint, options.offsetX, options.offsetY);
            group.setPointOptions = nil; -- Don't need to do this again until updated by UpdateIconGroupSetPointOptions
        end
    end

    -- Give icon a timeStamp before inserting
    icon.timeStamp = GetTime();

    local active = group.active;

    -- Insert at the last position, then sort by priority
    table.insert(active, icon);
    if index then
        group.activeMap[index] = icon;
    end

    if addon.ARENA_FRAME_BARS[group.iconSetID] then
        -- Sort by category priority then time stamp
        table.sort(active, sortFuncArenaFrames);
    else
        -- Sort by timeStamp only
        table.sort(active, sortFuncStandaloneBars);
    end

    addon.IconGroup_Position(group);

    -- Reposition first, then show, to avoid new icon occluding previously shown ones.
    icon:Show();
    --print(icon:IsShown());
    --print(group:IsShown());
    --print(group:GetPoint());
end

addon.IconGroup_Remove = function (group, icon, fade)
    icon.started = nil;

    if fade then
        local alpha = addon.GetIconSetConfig(group.iconSetID).unusedIconAlpha;
        icon:SetAlpha(alpha);
        return;
    end

    -- Hide icon first, then reposition, to avoid occlusion.
    icon:Hide();

    if ( not group ) or ( #(group.active) == 0 ) then
        return;
    end

    if icon.unit and icon.spellID then
        group.activeMap[icon.unit .. "-" .. icon.spellID] = nil;
    end

    local active = group.active;

    local index;
    for key, value in pairs(active) do
        if ( value == icon ) then
            index = key;
        end
    end

    if index then
        table.remove(active, index);
        addon.IconGroup_Position(group);
    end
end

-- For arena offensive cooldown tracking, index is just spellID since we are always tracking a single unitId
-- For CooldownTracking icons, we will use unitId - spellID
addon.IconGroup_PopulateIcon = function (group, icon, index)
    icon.timers = {}; -- Reset current timers
    icon:SetParent(group);
    group.icons[index] = icon;
end

addon.IconGroup_Wipe = function (group)
    if ( not group ) then return end

    for _, icon in pairs(group.icons) do
        if icon.cooldown then
            icon.cooldown:SetCooldown(0, 0);
        end
        if icon.SpellActivationAlert then
            if icon.SpellActivationAlert.ProcStartAnim:IsPlaying() then
                icon.SpellActivationAlert.ProcStartAnim:Stop();
            end
            if icon:IsVisible() then
                icon.SpellActivationAlert:Hide();
           end
        end
        if icon.duration then
            icon.duration:SetCooldown(0, 0);
        end
        if icon.Count then -- Clear state from previous show
            icon.Count.text:SetText("");
            icon.Count:Hide();
        end
        if icon.TargetHighlight then
            icon.TargetHighlight:Hide();
        end
        icon.started = nil;
        icon:Hide();
    end

    wipe(group.icons);
    wipe(group.active);
    wipe(group.activeMap);
    wipe(group.npcMap);
    group.unitIdToGuid = {};
    group.unitGuidToId = {};

    -- For tracking special cdr
    group.apotheosisUnits = {};
    group.guardianSpiritSaved = {};
    group.premonitionUnits = {};
    group.alterTimeApplied = {};
    group.alterTimeRemoved = {};
    group.groveGuardianOwners = {};
end
