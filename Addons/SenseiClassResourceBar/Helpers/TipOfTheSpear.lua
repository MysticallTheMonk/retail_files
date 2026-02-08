local _, addonTable = ...

local TipOfTheSpear = {}

local tipStacks = 0
local tipExpiresAt = nil
TipOfTheSpear.TIP_MAX_STACKS = 3
local TIP_DURATION = 10

local TIP_OF_THE_SPEAR_ID = 260285
local KILL_COMMAND_ID = 259489
local TWIN_FANG_ID = 1272139
local TAKEDOWN_ID = 1250646
local PRIMAL_SURGE_ID = 1272154

-- Abilities that consume Tip of the Spear stacks
local SPENDER_IDS = {
    [186270] = true,  -- Raptor Strike
    [1262293] = true, -- Raptor Swipe
    [1261193] = true, -- Boomstick
    [1253859] = true, -- Takedown
    [259495] = true,  -- Wildfire Bomb
    [193265] = true,  -- Hatchet Toss
    [1264949] = true, -- Chakram
    [1262343] = true, -- Ranged Raptor Swipe
    [265189] = true,  -- Ranged Raptor Strike
    [1251592] = true, -- Flamefang Pitch
}

function TipOfTheSpear:OnLoad(powerBar)
    local playerClass = select(2, UnitClass("player"))

    if playerClass == "HUNTER" then
        powerBar.Frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        powerBar.Frame:RegisterEvent("PLAYER_DEAD")
        powerBar.Frame:RegisterEvent("PLAYER_ALIVE")
    end
end

function TipOfTheSpear:OnEvent(_, event, ...)
    -- Handle Death and Resurrection Reset
    if event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" then
        tipStacks = 0
        tipExpiresAt = nil
        return
    end

    local unit, _, spellID = ...
    if unit ~= "player" then return end
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" then return end
    if not C_SpellBook.IsSpellKnown(TIP_OF_THE_SPEAR_ID) then return end

    -- Gain 1/2 stacks from Kill Command
    if spellID == KILL_COMMAND_ID then
        tipStacks = math.min(self.TIP_MAX_STACKS, tipStacks + (C_SpellBook.IsSpellKnown(PRIMAL_SURGE_ID) and 2 or 1))
        tipExpiresAt = GetTime() + TIP_DURATION
        return
    end

    -- Gain 2 stacks from Takedown
    if spellID == TAKEDOWN_ID and C_SpellBook.IsSpellKnown(TWIN_FANG_ID) then
        tipStacks = math.min(self.TIP_MAX_STACKS, tipStacks + 2) -- Takedown auto consumes a stack it seems ?
        tipExpiresAt = GetTime() + TIP_DURATION
        return
    end

    -- Consume stack from spenders
    if SPENDER_IDS[spellID] then
        if tipStacks > 0 then
            tipStacks = tipStacks - 1
            if tipStacks == 0 then
                tipExpiresAt = nil
            end
            return
        end
    end
end

function TipOfTheSpear:GetStacks()
    -- Check if stacks have expired
    if tipExpiresAt and GetTime() >= tipExpiresAt then
        tipStacks = 0
        tipExpiresAt = nil
    end

    return self.TIP_MAX_STACKS, tipStacks
end

addonTable.TipOfTheSpear = TipOfTheSpear