local _, addon = ...;

local function GetHealerIndex()
    if addon.TEST_MODE then
        return 1;
    end

    if IsActiveBattlefieldArena() then
        for i = 1, addon.MAX_ARENA_SIZE do
            local spec = GetArenaOpponentSpec(i);
            if spec then
                local role = select(5, GetSpecializationInfoByID(spec));
                if ( role == "HEALER" ) then
                    return i;
                end
            end
        end
    end
end

local healerIndicator; -- Create on first usage
local function EnsureHealerIndicator()
    if ( not healerIndicator ) then
        healerIndicator = CreateFrame("Frame");
        healerIndicator:SetFrameLevel(9999);
        healerIndicator:SetMouseClickEnabled(false);
        healerIndicator.icon = healerIndicator:CreateTexture();
        healerIndicator.icon:SetAtlas("Icon-Healer");
        healerIndicator.icon:SetAllPoints(healerIndicator);
    end
end

local function HideHealerIndicator()
    if healerIndicator then
        healerIndicator:Hide();
    end
end

local function UpdateHealerIndicator()
    local healerIndex = GetHealerIndex();
    if ( not healerIndex ) then
        HideHealerIndicator();
        return;
    end

    EnsureHealerIndicator(); -- Created but size / scale not set

    -- Update size in case the player adjusted Gladius / sArena settings
    -- Require a reload when settings are changed during an arena session
    local size;
    if Gladius then
        size = GladiusClassIconFramearena1 and GladiusClassIconFramearena1:GetSize();
    elseif sArena then
        size = sArenaEnemyFrame1 and sArenaEnemyFrame1.ClassIcon and sArenaEnemyFrame1.ClassIcon:GetSize();
    end
    if ( not size ) then
        HideHealerIndicator();
        return;
    end

    local scale;
    if Gladius then
        scale = GladiusButtonFramearena1 and GladiusButtonFramearena1:GetScale();
    elseif sArena then
        scale = sArena:GetScale();
    end
    if ( not scale ) then
        HideHealerIndicator();
        return;
    end

    local frame;
    if Gladius then
        frame = _G["GladiusClassIconFramearena" .. healerIndex];
    elseif sArena then
        frame = _G["sArenaEnemyFrame" .. healerIndex] and _G["sArenaEnemyFrame" .. healerIndex].ClassIcon;
    end
    if ( not frame ) then
        HideHealerIndicator();
        return;
    end

    size = size / 2;
    healerIndicator:SetSize(size, size);
    healerIndicator.icon:SetSize(size, size);
    healerIndicator:SetScale(scale);
    healerIndicator:SetPoint("CENTER", frame, "RIGHT");
    healerIndicator:Show();
end

function SweepyBoop:SetupHealerIndicator()
    local frame = CreateFrame("Frame");
    frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    frame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    frame:SetScript("OnEvent", function ()
        if ( not SweepyBoop.db.profile.misc.healerIndicator ) or ( not ( Gladius or sArena ) ) then -- take away the option, always enabled
            HideHealerIndicator();
            return;
        end

        UpdateHealerIndicator();
    end)
end
