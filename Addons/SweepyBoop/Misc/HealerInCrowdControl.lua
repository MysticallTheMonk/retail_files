local _, addon = ...;
local LCG = LibStub("LibCustomGlow-1.0");

local iconSize = addon.DEFAULT_ICON_SIZE;
local borderSize = iconSize * 1.25;

local containerFrame;
local isInTest = false;

local function HideIcon(frame)
    if ( not frame ) then return end

    frame.cooldown:SetCooldown(0, 0);
    frame.text:SetText("");
    frame:Hide();
    isInTest = false;
end

local function CreateContainerFrame()
    local frame = CreateFrame("Frame");
    frame:SetMouseClickEnabled(false);
    frame:SetFrameStrata("HIGH");
    frame:SetSize(iconSize, iconSize);

    frame.icon = frame:CreateTexture(nil, "BORDER");
    frame.icon:SetSize(iconSize, iconSize);
    frame.icon:SetAllPoints(frame);

    frame.breakericon = CreateFrame("Frame", nil, frame);
    frame.breakericon:SetSize(iconSize / 1.5, iconSize / 1.5);
    frame.breakericon:SetPoint("LEFT", frame.icon, "RIGHT");
    frame.breakericonTexture = frame.breakericon:CreateTexture(nil, "BORDER");
    frame.breakericonTexture:SetAllPoints();

    frame.mask = frame:CreateMaskTexture();
    frame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
    frame.mask:SetSize(iconSize, iconSize);
    frame.mask:SetAllPoints(frame.icon);
    frame.icon:AddMaskTexture(frame.mask);

    frame.border = frame:CreateTexture(nil, "OVERLAY");
    frame.border:SetAtlas("talents-warmode-ring");
    frame.border:SetSize(borderSize, borderSize);
    frame.border:SetPoint("CENTER", frame);

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    frame.cooldown:SetAllPoints();
    frame.cooldown:SetDrawEdge(true);
    frame.cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    frame.cooldown:SetUseCircularEdge(true);
    frame.cooldown:SetReverse(true);
    frame.cooldown:SetSwipeTexture("Interface/Masks/CircleMaskScalable");
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.5); -- to achieve a transparent background
    frame.cooldown:SetHideCountdownNumbers(true);
    frame.cooldown.noCooldownCount = true; -- hide OmniCC timers
    frame.cooldown:SetScript("OnCooldownDone", function (self)
        local parent = self:GetParent();
        if parent:IsShown() then
            HideIcon(parent);
        end
    end)

    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameTooltipText");
    frame.text:SetPoint("TOP", frame, "BOTTOM", 0, -5);
    frame.text:SetText("");

    frame.timer = 0;
    frame:SetScript("OnUpdate", function (self, elapsed)
        self.timer = self.timer + elapsed;
        if self.timer > 0.025 then -- Update every 0.025s
            local start, duration = self.cooldown:GetCooldownTimes();

            if start and duration then
                local remainingMs = start + duration - GetTime() * 1000;
                if remainingMs > 0 then
                    self.text:SetText(string.format("%.1f Sec", remainingMs / 1000));
                else
                    self.text:SetText("");
                end
            else
                self.text:SetText("");
            end

            self.timer = 0;
        end
    end)

    frame:Hide(); -- Hide initially
    return frame;
end

local function ShowIcon(spellID, startTime, duration)
    containerFrame = containerFrame or CreateContainerFrame();
    local iconID = C_Spell.GetSpellTexture(spellID);

    local config = SweepyBoop.db.profile.misc;

    if ( containerFrame.lastModified ~= config.lastModified ) then
        local scale = config.healerInCrowdControlSize / iconSize;
        containerFrame:SetScale(scale);
        containerFrame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX / scale, config.healerInCrowdControlOffsetY / scale);

        containerFrame.lastModified = config.lastModified;
    end

    containerFrame.icon:SetTexture(iconID);
    if duration then
        containerFrame.cooldown:SetCooldown(startTime, duration);
        containerFrame.cooldown:Show();
    else
        containerFrame.cooldown:SetCooldown(0, 0);
        containerFrame.cooldown:Hide();
    end

    local breakerSpellID;
    local breakers = addon.CrowdControlBreakers[spellID];
    if breakers then
        for candidate, _ in pairs(breakers) do
            if IsSpellKnown(candidate) or IsSpellKnown(candidate, true) then
                local cooldown = C_Spell.GetSpellCooldown(candidate);
                if cooldown and cooldown.duration == 0 then
                    breakerSpellID = candidate;
                    break;
                end
            end
        end
    end
    if breakerSpellID then
        local breakerIconID = C_Spell.GetSpellTexture(breakerSpellID);
        containerFrame.breakericonTexture:SetTexture(breakerIconID);
        LCG.ButtonGlow_Start(containerFrame.breakericon);
        containerFrame.breakericon:Show();
    else
        LCG.ButtonGlow_Stop(containerFrame.breakericon);
        containerFrame.breakericon:Hide();
    end

    if ( not containerFrame:IsShown() ) and config.healerInCrowdControlSound then
        PlaySoundFile(569006, "master"); -- spell_uni_sonarping_01
    end

    containerFrame:Show();
end

local class = addon.GetUnitClass("player");
local testIcons = {
    [addon.DRUID] = 51514, -- Hex
    [addon.EVOKER] = 51514, -- Hex
    [addon.HUNTER] = 605, -- Mind Control
    [addon.MAGE] = 51514, -- Hex
    [addon.MONK] = 356727, -- Spider Venom
    [addon.PALADIN] = 356727, -- Spider Venom
    [addon.PRIEST] = 605, -- Mind Control
    [addon.SHAMAN] = 8122, -- Psychic Scream
};
local testSpellID = testIcons[class] or 118; -- Polymorph

function SweepyBoop:TestHealerInCrowdControl()
    if IsInInstance() then
        addon.PRINT("Cannot run textest mode inside an instance");
        return;
    end

    ShowIcon(testSpellID, GetTime(), 8);
    isInTest = true;
end

function SweepyBoop:UpdateHealerInCrowdControl()
    if containerFrame and containerFrame:IsShown() then
        if ( containerFrame.lastModified ~= SweepyBoop.db.profile.misc.lastModified ) then
            local config = SweepyBoop.db.profile.misc;
            local scale = config.healerInCrowdControlSize / iconSize;
            containerFrame:SetScale(scale);
            containerFrame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX / scale, config.healerInCrowdControlOffsetY / scale);

            containerFrame.lastModified = SweepyBoop.db.profile.misc.lastModified;
        end
    end
end

function SweepyBoop:HideTestHealerInCrowdControl()
    HideIcon(containerFrame);
end

local crowdControlPriority = { -- sort by remaining time, then priority
    ["stun"] = 100,
    ["silence"] = 90,
    ["disorient"] = 80,
    ["incapacitate"] = 80,
};

local updateFrame;

function SweepyBoop:SetupHealerInCrowdControl()
    if ( not updateFrame ) then
        updateFrame = CreateFrame("Frame"); -- When a frame is hidden it might not receive event, so we create a frame to catch events
        updateFrame:SetScript("OnEvent", function (self, event, unitTarget)
            if ( event ~= addon.UNIT_AURA ) then -- Hide when switching map or entering new round of solo shuffle
                HideIcon(containerFrame);
                return;
            end

            if ( not IsActiveBattlefieldArena() ) and ( not isInTest ) and ( not addon.TEST_MODE ) then
                HideIcon(containerFrame);
                return;
            end

            local isFriendly = unitTarget and ( UnitIsUnit(unitTarget, "party1") or UnitIsUnit(unitTarget, "party2") );
            local isFriendlyHealer = ( UnitGroupRolesAssigned(unitTarget) == "HEALER" and isFriendly ) or ( addon.TEST_MODE and unitTarget == "target" );
            if isFriendlyHealer then
                local spellID;
                local priority = 0; -- init with a low priority
                local duration;
                local expirationTime;

                for i = 1, 40 do
                    local auraData = C_UnitAuras.GetDebuffDataByIndex(unitTarget, i);
                    if ( not auraData ) or ( not auraData.spellId ) then break end -- No more auras
                    if addon.DRList[auraData.spellId] then
                        local category = addon.DRList[auraData.spellId];
                        local update = false;
                        if crowdControlPriority[category] then -- Found a CC that should be shown
                            -- No expirationTime means this aura never expires, so it should be prioritized
                            if ( not auraData.expirationTime ) or ( expirationTime and auraData.expirationTime and auraData.expirationTime < expirationTime ) then
                                update = true;
                            elseif crowdControlPriority[category] > priority then -- same expirationTime, use priority as tie breaker
                                update = true;
                            end

                            if update then
                                priority = crowdControlPriority[category];
                                duration = auraData.duration;
                                expirationTime = auraData.expirationTime;
                                spellID = auraData.spellId;
                            end
                        end
                    end
                end

                if ( not spellID ) then -- No CC found, hide
                    HideIcon(containerFrame);
                else
                    ShowIcon(spellID, duration and (expirationTime - duration), duration);
                end
            end
        end)
    end

    updateFrame:UnregisterAllEvents();
    if SweepyBoop.db.profile.misc.healerInCrowdControl then
        updateFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        updateFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        updateFrame:RegisterEvent(addon.UNIT_AURA);
    else
        HideIcon(containerFrame);
    end
end
