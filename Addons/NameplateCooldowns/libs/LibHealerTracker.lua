-- luacheck: no max line length
-- luacheck: globals LibStub GetSpecializationInfoByID CreateFrame GetNumBattlefieldScores GetBattlefieldScore CombatLogGetCurrentEventInfo

-- (c) Gaxy-Kazzak, 2024

local LIB_NAME = "LibHealerTracker-1.0";
local lib = LibStub:NewLibrary(LIB_NAME, 1);
if (not lib) then return; end -- No upgrade needed

-- local HealerClasses = {};
-- local HealerSpecs = {};
local p_healers = {};
local p_callbacks = {};

-- =======================================================
-- ======================== SETUP ========================
-- =======================================================

-- local HEALER_SPECIALIZATION_ID = {
--     [105] = "Restoration Druid",
--     [264] = "Restoration Shaman",
--     [270] = "Mistweaver Monk",
--     [257] = "Holy Priest",
--     [65] = "Holy Paladin",
--     [256] = "Discipline Priest",
--     [1468] = "Preservation Evoker",
-- };

local HEALER_SPELL_EVENTS = {
    ["SPELL_HEAL"] = true,
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_CAST_START"] = true,
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_EMPOWER_START"] = true,
    ["SPELL_EMPOWER_END"] = true,
    ["SPELL_PERIODIC_HEAL"] = true,
}

local HEALER_SPELLS = {
    -- Holy Priest
    [2060] = "PRIEST",     -- Heal
    [14914] = "PRIEST",    -- Holy Fire
    [596] = "PRIEST",      -- Prayer of Healing
    [204883] = "PRIEST",   -- Circle of Healing
    [289666] = "PRIEST",   -- Greater Heal
    -- Discipline Priest
    [47540] = "PRIEST",  -- Penance
    [194509] = "PRIEST", -- Power Word: Radiance
    [214621] = "PRIEST", -- Schism
    [129250] = "PRIEST", -- Power Word: Solace
    [204197] = "PRIEST", -- Purge of the Wicked
    [314867] = "PRIEST",  -- Shadow Covenant
    -- Druid
    [102351] = "DRUID", -- Cnenarion Ward
    [33763] = "DRUID", -- Nourish
    [81262] = "DRUID", -- Efflorescence
    [391888] = "DRUID", -- Adaptive Swarm -- Shared with Feral
    [392160] = "DRUID", -- Invigorate
    -- Shaman
    [61295] = "SHAMAN",  -- Riptide
    [77472] = "SHAMAN",  -- Healing Wave
    [73920] = "SHAMAN",  -- Healing Rain
    [73685] = "SHAMAN",  -- Unleash Life
    [207778] = "SHAMAN", -- Downpour
    -- Paladin
    [275773] = "PALADIN", -- Judgment
    [20473] = "PALADIN", -- Holy Shock
    [82326] = "PALADIN", -- Holy Light
    [85222] = "PALADIN", -- Light of Dawn
    [223306] = "PALADIN", -- Bestow Faith
    [214202] = "PALADIN", -- Rule of Law
    [210294] = "PALADIN", -- Divine Favor
    [114165] = "PALADIN", -- Holy Prism
    [148039] = "PALADIN", -- Barrier of Faith
    -- Monk
    [124682] = "MONK", -- Envelopping Mist
    [191837] = "MONK", -- Essence Font
    [115151] = "MONK", -- Renewing Mist
    [116680] = "MONK", -- Thunder Focus Tea
    [124081] = "MONK", -- Zen Pulse
    [209584] = "MONK", -- Zen Focus Tea
    [205234] = "MONK", -- Healing Sphere
    -- Evoker - Preservation
    [364343] = "EVOKER", -- Echo
    [382614] = "EVOKER", -- Dream Breath
    [366155] = "EVOKER", -- Reversion
    [382731] = "EVOKER", -- Spiritbloom
    [373861] = "EVOKER", -- Temporal Anomaly
};

-- for specialization_id, _ in pairs(HEALER_SPECIALIZATION_ID) do
--     local _, name, _, _, _, classFile, _ =  GetSpecializationInfoByID(specialization_id);
--     HealerClasses[classFile] = true;
--     HealerSpecs[name] = true;
-- end

-- ======================================================
-- ================== INTERNAL METHODS ==================
-- ======================================================

local function MarkPlayerAsHealer(_guid)
    if (p_healers[_guid] ~= nil) then
        return;
    end

    p_healers[_guid] = true;

    for _, callback in pairs(p_callbacks) do
        callback(_guid, true);
    end
end

-- ========================================================
-- ======================== EVENTS ========================
-- ========================================================

local eventFrame = CreateFrame("Frame");
-- eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
eventFrame:SetScript("OnEvent", function(self, event, ...) self[event](...); end);

-- eventFrame.UPDATE_BATTLEFIELD_SCORE = function()
--     for i = 1, GetNumBattlefieldScores() do
--         local name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i);

--         if (HealerSpecs[talentSpec]) then
--             Healers[name] = HEALER_SPECS[talentSpec] ~= nil
--     end
--     end
-- end

eventFrame.PLAYER_ENTERING_WORLD = function()
    p_healers = {};
end

eventFrame.COMBAT_LOG_EVENT_UNFILTERED = function()
    local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo();

    if (sourceGUID and HEALER_SPELL_EVENTS[subEvent] and HEALER_SPELLS[spellId]) then
        MarkPlayerAsHealer(sourceGUID);
    end
end

-- ====================================================
-- ================== PUBLIC METHODS ==================
-- ====================================================

lib.Subscribe = function(_callback)
    if (_callback == nil) then
        return nil;
    end

    local subscriptionGuid = math.random(1000000, 9999999);
    p_callbacks[subscriptionGuid] = _callback;

    return subscriptionGuid;
end

lib.Unsubscribe = function(_subscriptionGuid)
    if (_subscriptionGuid == nil) then
        return nil;
    end

    p_callbacks[_subscriptionGuid] = nil;
end

lib.IsPlayerHealer = function(_guid)
    return p_healers[_guid] or false;
end
