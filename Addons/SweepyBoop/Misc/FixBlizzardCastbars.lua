local _, addon = ...;

-- https://github.com/Sammers21/sArena_Updated2_by_sammers/blob/master/sArena.lua
-- sArena should have the correct texture and color already, we just need to hide the charge tiers
--[[
-- default bars, will get overwritten from layouts
local typeInfoTexture = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill";
sArenaCastingBarExtensionMixin.typeInfo = {
    filling = typeInfoTexture,
    full = typeInfoTexture,
    glow = typeInfoTexture
}

local actionColors = {
    applyingcrafting = { 1.0, 0.7, 0.0, 1 },
    applyingtalents = { 1.0, 0.7, 0.0, 1 },
    filling = { 1.0, 0.7, 0.0, 1 },
    full = { 0.0, 1.0, 0.0, 1 },
    standard = { 1.0, 0.7, 0.0, 1 },
    empowered = { 1.0, 0.7, 0.0, 1 },
    channel = { 0.0, 1.0, 0.0, 1 },
    uninterruptable = { 0.7, 0.7, 0.7, 1 },
    interrupted = { 1.0, 0.0, 0.0, 1 }
}
--]]

-- This needs to be called once only per cast bar
local function FixBlizzardCastBar(self)
    if self.blizzardCastBarFixed then return end

    self:HookScript("OnEvent", function(frame)
        if frame:IsForbidden() or ( not SweepyBoop.db.profile.misc.fixEvokerCastBars ) then return end
        local hideChargeTiers;
        if ( frame.barType == "uninterruptible" ) then
            if ( not frame.sArenaCastBar ) then
                frame:SetStatusBarTexture("ui-castingbar-uninterruptable");
            end
            hideChargeTiers = true;
        elseif ( frame.barType == "empowered" ) then
            if ( not frame.sArenaCastBar ) then
                frame:SetStatusBarTexture("ui-castingbar-filling-standard");
            end
            hideChargeTiers = true;
        end

        -- https://github.com/tomrus88/BlizzardInterfaceCode/blob/25276211effd4b92effa1c2c6671b5e68db85e84/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/CastingBarFrame.lua#L908
        if hideChargeTiers then
            local numStages = self.NumStages or 5;
            for i = 1,numStages-1,1 do
                if self["ChargeTier"..i] then
                    self["ChargeTier"..i]:Hide();
                end
            end
        end
    end);

    self.blizzardCastBarFixed = true;
end

local function FixNamePlateCastBar(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit);
    local unitFrame = nameplate and nameplate.UnitFrame;
    if unitFrame and unitFrame.castBar then
        FixBlizzardCastBar(unitFrame.castBar);
    end
end

local eventFrame;
function SweepyBoop:SetupFixBlizzardCastbars()
    if ( not eventFrame ) then
        eventFrame = CreateFrame("Frame");
        eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED);
        eventFrame:SetScript("OnEvent", function(self, event, ...)
            if ( event == addon.NAME_PLATE_UNIT_ADDED ) then
                local unit = ...;
                FixNamePlateCastBar(unit);
            end
        end)

        local castBars = {
            TargetFrameSpellBar,
            FocusFrameSpellBar,
        };
        if sArena then -- We load after sArena, so no need to worry about if sArena has been loaded here, what if we need to fix another addon that's loaded after us?
            for i = 1, addon.MAX_ARENA_SIZE do
                local frame = _G["sArenaEnemyFrame"..i];
                if frame and frame.CastBar then
                    frame.CastBar.sArenaCastBar = true;
                    tinsert(castBars, frame.CastBar);
                end
            end
        end
        for _, castBar in ipairs(castBars) do
            FixBlizzardCastBar(castBar);
        end
    end
end
