---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsEnumerable = addon.Collections.Enumerable
---@class UnitUtil
local M = {}
addon.WoW.Unit = M

local allPartyUnitsIds = {
    "player",
}
local allRaidUnitsIds = {}
local allEnemyUnitsIds = {}

for i = 1, wow.MEMBERS_PER_RAID_GROUP do
    allPartyUnitsIds[#allPartyUnitsIds + 1] = "party" .. i
end

for i = 1, wow.MEMBERS_PER_RAID_GROUP do
    allPartyUnitsIds[#allPartyUnitsIds + 1] = "partypet" .. i
end

for i = 1, wow.MAX_RAID_MEMBERS do
    allRaidUnitsIds[#allRaidUnitsIds + 1] = "raid" .. i
end

for i = 1, wow.MAX_RAID_MEMBERS do
    allRaidUnitsIds[#allRaidUnitsIds + 1] = "raidpet" .. i
end

for i = 1, wow.MEMBERS_PER_RAID_GROUP do
    allEnemyUnitsIds[#allEnemyUnitsIds + 1] = "arena" .. i
end

for i = 1, wow.MEMBERS_PER_RAID_GROUP do
    allEnemyUnitsIds[#allEnemyUnitsIds + 1] = "arenapet" .. i
end

local function ArenaUnitExists(token)
    -- after the gates open UnitExists will start working
    if wow.UnitExists(token) then
        return true
    end

    -- get the number from the token, e.g. "2" from "arena2"
    local idStr = string.match(token, "%d+")
    if not idStr then
        return false
    end

    -- if only 2 members load in a 3v3, then not all information is available
    -- e.g. in a 2v2, 2v3, or 3v2 inside a 3v3 environment GetNumArenaOpponentSpecs() doesn't return the right value
    -- so give it a best guess
    local enemyCount = wow.GetNumArenaOpponentSpecs()
    local allyCount = wow.GetNumGroupMembers()
    local instanceSize = math.max(enemyCount, allyCount)

    local id = tonumber(idStr)
    return id <= instanceSize
end

---Returns a table of group member unit tokens where the unit exists.
---@return string[]
function M:FriendlyUnits()
    if not wow.IsInGroup() then
        return {}
    end

    local isRaid = wow.IsInRaid()
    local units = isRaid and allRaidUnitsIds or allPartyUnitsIds

    return fsEnumerable
        :From(units)
        :Where(function(unit)
            return wow.UnitExists(unit)
        end)
        :ToTable()
end

---Returns a table of enemy unit tokens where the unit exists.
---@return string[]
function M:EnemyUnits()
    local inInstance, instanceType = wow.IsInInstance()

    if not inInstance or instanceType ~= "arena" then
        return {}
    end

    return fsEnumerable
        :From(allEnemyUnitsIds)
        :Where(function(unit)
            return ArenaUnitExists(unit)
        end)
        :ToTable()
end

---Returns true if the unit token is a pet.
---@param unit string
function M:IsPet(unit)
    return string.find(unit, "pet", nil, true) ~= nil
end

---Returns the pet unit for the specified player unit.
---@param unit string
---@return string
function M:PetFor(unit)
    if not unit or unit == "none" then
        return "none"
    end

    if unit == "player" or wow.UnitIsUnit(unit, "player") then
        return "pet"
    end

    local pet, _ = string.gsub(unit, "%a+", "%1pet")
    return pet
end
