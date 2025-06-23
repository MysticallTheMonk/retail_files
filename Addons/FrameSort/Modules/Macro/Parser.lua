---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsEnumerable = addon.Collections.Enumerable
local fsUnit = addon.WoW.Unit
---@class MacroParser
local M = {}
addon.Modules.Macro.Parser = M
local skipSelector = "x"
-- string split on non-alpha numberic
local splitOn = "([%w]+)"
local shortHeaderPattern = "#[Ff][Ss]"
local longHeaderPattern = "#[Ff][Rr][Aa][Mm][Ee][Ss][Oo][Rr][Tt]"
local shortSyntax = "@"
local longSyntax = "target="
local alphanumericWord = "([%w]+)"
local shortPattern = shortSyntax .. alphanumericWord
local longPattern = longSyntax .. alphanumericWord

local WowRole = {
    Tank = "TANK",
    Healer = "HEALER",
    DPS = "DAMAGER",
}

---Returns the start and end index of the nth target selector, e.g. @raid1, @player, @placeholder, target=player
---@param str string
---@param occurrence number? the nth occurrence to find
---@return number? start, number? end
local function NthSelector(str, occurrence)
    local startPos = nil
    local endPos = nil
    local n = 0

    -- find the nth "@"
    while n < occurrence do
        n = n + 1

        local shortStartPos, shortEndPos = string.find(str, shortPattern, endPos and endPos + 1 or nil)
        local longStartPos, longEndPos = string.find(str, longPattern, endPos and endPos + 1 or nil)

        -- check to see which selector comes first in the macro
        -- return the earliest
        if shortStartPos and shortStartPos <= (longStartPos or shortStartPos) then
            startPos = shortStartPos
            endPos = shortEndPos
        elseif longStartPos and longStartPos <= (shortStartPos or longStartPos) then
            -- skip past the "target=" to the unit
            longStartPos = longStartPos + string.len(longSyntax) - 1

            startPos = longStartPos
            endPos = longEndPos
        else
            return nil, nil
        end
    end

    return startPos, endPos
end

---Replaces all, or the nth occurrence of an "@unit" instance with the specified unit
---@param body string
---@param unit string
---@param occurrence number the nth selector to replace
---@return string? the new body text, or nil if invalid
local function ReplaceSelector(body, unit, occurrence)
    local startPos = nil
    local endPos = nil

    startPos, endPos = NthSelector(body, occurrence)
    if not startPos or not endPos then
        return nil
    end

    local newBody = string.sub(body, 0, startPos)
    newBody = newBody .. unit
    newBody = newBody .. string.sub(body, endPos + 1)
    return newBody
end

local function GetSelectors(body)
    local longHeader = string.match(body, longHeaderPattern .. ".-\n")
    local shortHeader = string.match(body, shortHeaderPattern .. ".-\n")
    local header = longHeader or shortHeader
    local selectors = {}

    if not header then
        return selectors
    end

    local passedHeader = false

    for match in string.gmatch(header, splitOn) do
        if passedHeader then
            selectors[#selectors + 1] = match
        end

        -- skip the "#framesort" header
        passedHeader = true
    end

    return selectors
end

local function UnitForSelector(selector, friendlyUnits, enemyUnits)
    local lowercase = string.lower(selector)

    -- tanktarget, healertarget, etc
    if string.match(lowercase, ".+target") or string.match(lowercase, ".+tg") then
        local withoutTarget = string.gsub(lowercase, "target", "")
        withoutTarget = string.gsub(withoutTarget, "tg", "")

        local unit = UnitForSelector(withoutTarget, friendlyUnits, enemyUnits)

        if unit and unit ~= "none" then
            unit = unit .. "target"
        end

        return unit
    end

    -- extract the frame number
    local number = tonumber(string.match(selector, "%d+")) or 1
    -- drop the number and make it case insensitive
    local type = string.gsub(lowercase, "%d+", "")

    -- bottom frame minus X
    if type == "bfm" then
        return friendlyUnits[#friendlyUnits - number] or "none"
    end

    -- bottom frame
    if type == "bottomframe" or type == "bf" then
        return friendlyUnits[#friendlyUnits] or "none"
    end

    -- enemy pet frame
    if type == "enemyframepet" or type == "efp" then
        local player = enemyUnits[number] or "none"
        return fsUnit:PetFor(player)
    end

    -- enemy frame
    if type == "enemyframe" or type == "ef" then
        return enemyUnits[number] or "none"
    end

    -- pet frame
    if type == "framepet" or type == "fp" then
        local player = friendlyUnits[number] or "none"
        return fsUnit:PetFor(player)
    end

    -- frame
    if type == "frame" or type == "f" then
        return friendlyUnits[number] or "none"
    end

    -- other dps
    if type == "otherdps" or type == "od" then
        return fsEnumerable:From(friendlyUnits):Nth(number or 1, function(x)
            return wow.UnitGroupRolesAssigned(x) == WowRole.DPS and not wow.UnitIsUnit(x, "player")
        end) or "none"
    end

    local enemyTank = type == "enemytank" or type == "et"
    local enemyHealer = type == "enemyhealer" or type == "eh"
    local enemyDps = type == "enemydps" or type == "ed"

    -- enemy arena
    if enemyTank or enemyHealer or enemyDps then
        if not wow.IsRetail() then
            return "none"
        end

        assert(enemyUnits)

        return fsEnumerable:From(enemyUnits):Nth(number or 1, function(x)
            local id = tonumber(string.match(x, "%d+"))

            if not id then
                return false
            end

            local specId = wow.GetArenaOpponentSpec(id)

            if not specId then
                return false
            end

            local _, _, _, _, role, _, _ = wow.GetSpecializationInfoByID(specId)
            return (enemyTank and role == WowRole.Tank) or (enemyHealer and role == WowRole.Healer) or (enemyDps and role == WowRole.DPS)
        end) or "none"
    end

    -- role
    local tank = type == "tank" or type == "t"
    local healer = type == "healer" or type == "h"
    local dps = type == "dps" or type == "d"

    if tank or healer or dps then
        return fsEnumerable:From(friendlyUnits):Nth(number or 1, function(x)
            local role = wow.UnitGroupRolesAssigned(x)
            return (tank and role == WowRole.Tank) or (healer and role == WowRole.Healer) or (dps and role == WowRole.DPS)
        end) or "none"
    end

    return selector
end

function M:IsFrameSortMacro(body)
    return body and (string.match(body, shortHeaderPattern) ~= nil or string.match(body, longHeaderPattern) ~= nil) or false
end

---Returns a copy of the macro body with the new unit inserted.
---@param body string the current macro body.
---@param friendlyUnits string[] sorted friendly unit ids.
---@param enemyUnits string[] sorted enemy unit ids.
---@return string? the new macro body, or nil if invalid
function M:GetNewBody(body, friendlyUnits, enemyUnits)
    local newBody = body
    local selectors = GetSelectors(body)

    for i, selector in ipairs(selectors) do
        if string.lower(selector) ~= skipSelector then
            local unit = UnitForSelector(selector, friendlyUnits, enemyUnits)
            local tmp = ReplaceSelector(newBody, unit, i)

            if tmp then
                newBody = tmp
            end
        end
    end

    return newBody
end
