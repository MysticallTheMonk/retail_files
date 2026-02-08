local _, ADDON = ...

local function IsSpellKnown(spellId)
    return C_SpellBook.IsSpellInSpellBook(spellId)
end

local playerProfessions
--see https://warcraft.wiki.gg/wiki/TradeSkillLineID for all skillIds
local function playerHasProfession(skillId)

    if nil == playerProfessions then
        playerProfessions = {}
        if GetProfessions then
            local prof1, prof2 = GetProfessions()
            if prof1 then
                local prof1SkillID = select(7, GetProfessionInfo(prof1))
                if prof1SkillID then
                    playerProfessions[prof1SkillID] = true
                end
            end
            if prof2 then
                local prof2SkillID = select(7, GetProfessionInfo(prof2))
                if prof2SkillID then
                    playerProfessions[prof2SkillID] = true
                end
            end
        else
            if IsSpellKnown(2108) or IsSpellKnown(3104) or IsSpellKnown(3811) or IsSpellKnown(10662) or IsSpellKnown(32549) or IsSpellKnown(51302) then
                playerProfessions[165] = true -- Leatherworking
            end
            if IsSpellKnown(3908) or IsSpellKnown(3909) or IsSpellKnown(3910) or IsSpellKnown(12180) or IsSpellKnown(26790) or IsSpellKnown(51309) then
                playerProfessions[197] = true -- Tailoring
            end
            if IsSpellKnown(4036) or IsSpellKnown(4037) or IsSpellKnown(4038) or IsSpellKnown(12656) or IsSpellKnown(30350) or IsSpellKnown(51306) then
                playerProfessions[202] = true -- Engineering
            end
        end
    end

    return playerProfessions[skillId]
end

local playerClass
local function playerIsClass(class)
    if playerClass == nil then
        playerClass = select(2, UnitClass("player"))
    end

    return playerClass == class
end

local playerRace
-- see https://warcraft.wiki.gg/wiki/API_UnitRace for all race names
local function playerIsRace(race)
    if playerRace == nil then
        playerRace = select(2, UnitRace("player"))
    end

    return playerRace == race
end

local playerCovenant
local function playerIsCovenant(covenantId)
    if playerCovenant == nil and C_Covenants then
        playerCovenant = C_Covenants.GetActiveCovenantID()
    end

    return playerCovenant == covenantId
end

local playerFaction
-- factionID=0 for Horde
-- factionID=1 for Alliance
local function playerIsFaction(factionID)
    if playerFaction == nil then
        playerFaction = UnitFactionGroup("player")
    end

    if factionID == 1 and playerFaction == "Alliance" then
        return true
    end
    if factionID == 0 and playerFaction == "Horde" then
        return true
    end

    return false
end

local playerHasRiding
local function playerCanRide(mountId)
    if playerHasRiding == nil then
        playerHasRiding = IsSpellKnown(33388) or IsSpellKnown(33391) or IsSpellKnown(34090) or IsSpellKnown(34091) or IsSpellKnown(90265)  -- Riding skills
    end

    if playerHasRiding then
        return true
    end

    -- without riding skill you can only ride heirloom chopper and sea or riding turtle
    if mountId == 678 or mountId == 679 or mountId == 125 or mountId ~= 312 then
        return true
    end

    return false
end

local Mapping = {
    class = playerIsClass,
    race = playerIsRace,
    skill = playerHasProfession,
    covenant = playerIsCovenant,
    quest = C_QuestLog.IsQuestFlaggedCompleted,
}

function ADDON.IsPersonalMount(mountId, faction)
    if false == playerCanRide(mountId) then
        return false
    end

    if faction ~= nil and false == playerIsFaction(faction) then
        return false
    end

    local restrictions = ADDON.DB.Restrictions[mountId]
    if restrictions then
        for type, values in pairs(restrictions) do
            local checkSuccess = false
            local checkFunc = Mapping[type]
            for _, value in ipairs(values) do
                if true == checkFunc(value) then
                    checkSuccess = true
                    break
                end
            end
            if false == checkSuccess then
                return false
            end
        end
    end

    return true
end