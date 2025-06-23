-- https://www.curseforge.com/wow/addons/sortgroup
-- https://github.com/Verubato/frame-sort

-- Tried both ways, still getting taint when players join/leave, or pet dies during combat

-- Try leveraging SetPoint to modify the positions of CompactPartyFrames

local _, addon = ...;

local function Compare_Top(left, right)
    local leftToken, rightToken = left.unit, right.unit;

    if ( not UnitExists(leftToken) ) then return false
    elseif ( not UnitExists(rightToken) ) then return true

    elseif (leftToken == "player") then return true
    elseif (rightToken == "player") then return false
    else
        return leftToken < rightToken;
    end
end

local function Compare_Bottom(left, right)
    local leftToken, rightToken = left.unit, right.unit;
    if ( not UnitExists(leftToken) ) then return false
    elseif ( not UnitExists(rightToken) ) then return true

    elseif (leftToken == "player") then return false
    elseif (rightToken == "player") then return true
    else
        return leftToken < rightToken;
    end
end

local function Compare_Mid(left, right)
    local leftToken, rightToken = left.unit, right.unit;

    if ( not UnitExists(leftToken) ) then return false
    elseif ( not UnitExists(rightToken) ) then return true

    elseif ( leftToken == "party1" ) then return true
    elseif ( rightToken == "party1" ) then return false
    elseif ( leftToken == "player" ) then return true
    elseif ( rightToken == "player" ) then return false
    else
        return leftToken < rightToken;
    end
end

local sortFunctions = {
    [addon.RAID_FRAME_SORT_ORDER.PLAYER_TOP] = Compare_Top,
    [addon.RAID_FRAME_SORT_ORDER.PLAYER_BOTTOM] = Compare_Bottom,
    [addon.RAID_FRAME_SORT_ORDER.PLAYER_MID] = Compare_Mid,
};

local function GetPartyUnitId(unitId)
    if UnitIsUnit(unitId, "player") then
        return "player";
    else
        for i = 1, (MEMBERS_PER_RAID_GROUP - 1) do
            if UnitIsUnit(unitId, "party" .. i) then
                return "party" .. i;
            end
        end
    end

    return unitId;
end

local sortPending = false;

local function TrySort()
    if InCombatLockdown() then
        sortPending = true;
        return;
    end

    local frames = {};
    for i = 1, MEMBERS_PER_RAID_GROUP do
        local frame = _G["CompactPartyFrameMember"..i];
        local unit = GetPartyUnitId(frame.unit);
        frames[i] = { unit = unit, frame = frame };
    end

    table.sort(frames, sortFunctions[SweepyBoop.db.profile.raidFrames.arenaRaidFrameSortOrder]);

    local prevFrame;
    for _, value in ipairs(frames) do
        local frame = value.frame;
        frame:ClearAllPoints();
        if ( not prevFrame ) then
            frame:SetPoint("TOP", CompactPartyFrameTitle, "BOTTOM");
        else
            frame:SetPoint("TOP", prevFrame, "BOTTOM");
        end

        prevFrame = frame;
    end

    sortPending = false;
end

local function OnEvent(_, event)
    if (SweepyBoop.db.profile.raidFrames.arenaRaidFrameSortOrder == addon.RAID_FRAME_SORT_ORDER.DISABLED) then return end
    if ( not IsActiveBattlefieldArena() ) then return end -- only sort in arena
    if ( not IsInGroup() ) then return end

    -- Do we need to skip when EditModeManagerFrame.editModeActive is true?
    if (event == addon.PLAYER_REGEN_ENABLED) and sortPending then
        TrySort();
    else
        TrySort();
    end
end

local eventFrame = CreateFrame("Frame");
eventFrame:HookScript("OnEvent", OnEvent);
eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
eventFrame:RegisterEvent(addon.UNIT_PET);
eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
