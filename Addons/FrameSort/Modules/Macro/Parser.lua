---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local capabilities = addon.WoW.Capabilities
local fsEnumerable = addon.Collections.Enumerable
local fsUnit = addon.WoW.Unit
local fsInspector = addon.Modules.Inspector
local fsLog = addon.Logging.Log
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
local unitToken = "([^%s,%]]+)"
local shortPattern = shortSyntax .. unitToken
local longPattern = longSyntax .. unitToken

---Returns the start and end index of the nth target selector, e.g. raid1, player, placeholder, target=player
---@param str string
---@param occurrence number? the nth occurrence to find
---@return number? start, number? end
local function NthSelector(str, occurrence)
    local unitStart, unitEnd
    local searchFrom = 1
    local n = 0

    while n < occurrence do
        n = n + 1

        local s1, e1 = string.find(str, shortPattern, searchFrom)
        local s2, e2 = string.find(str, longPattern, searchFrom)

        if s1 and (not s2 or s1 <= s2) then
            -- unit starts after '@'
            unitStart = s1 + 1
            unitEnd = e1
            searchFrom = e1 + 1
        elseif s2 then
            -- unit starts after 'target='
            unitStart = s2 + #longSyntax
            unitEnd = e2
            searchFrom = e2 + 1
        else
            return nil, nil
        end
    end

    return unitStart, unitEnd
end

---Replaces the nth occurrence of an unit token with the specified unit
---@param body string
---@param unit string
---@param occurrence number the nth selector to replace
---@return string? the new body text, or nil if invalid
local function ReplaceSelector(body, unit, occurrence)
    local startPos, endPos = NthSelector(body, occurrence)
    if not startPos or not endPos then
        return nil
    end
    if startPos < 1 or endPos > #body then
        return nil
    end

    return string.sub(body, 1, startPos - 1) .. unit .. string.sub(body, endPos + 1)
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

function M:UnitForSelector(selector, friendlyUnits, enemyUnits)
    local lowercase = string.lower(selector)

    -- tanktarget, healertarget, etc
    if string.match(lowercase, ".+target") or string.match(lowercase, ".+tg") then
        local withoutTarget = string.gsub(lowercase, "target", "")
        withoutTarget = string.gsub(withoutTarget, "tg", "")

        local unit = M:UnitForSelector(withoutTarget, friendlyUnits, enemyUnits)

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
        return fsUnit:PetFor(player, true)
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
        if not capabilities.HasRoleAssignments() then
            return "none"
        end

        return fsEnumerable:From(friendlyUnits):Nth(number or 1, function(x)
            return wow.UnitGroupRolesAssigned(x) == wowEx.Role.Dps and not wow.UnitIsUnit(x, "player")
        end) or "none"
    end

    local enemyTank = type == "enemytank" or type == "et"
    local enemyHealer = type == "enemyhealer" or type == "eh"
    local enemyDps = type == "enemydps" or type == "ed"

    -- enemy arena
    if enemyTank or enemyHealer or enemyDps then
        if not capabilities.HasSpecializations() then
            return "none"
        end

        if not enemyUnits then
            fsLog:Bug("EnemyUnits must not be nil.")
            return "none"
        end

        if #enemyUnits == 0 then
            return "none"
        end

        return fsEnumerable:From(enemyUnits):Nth(number or 1, function(x)
            local specId = fsInspector:EnemyUnitSpec(x)

            if not specId then
                return false
            end

            local _, _, _, _, role, _, _ = wow.GetSpecializationInfoByID(specId)
            return (enemyTank and role == wowEx.Role.Tank) or (enemyHealer and role == wowEx.Role.Healer) or (enemyDps and role == wowEx.Role.Dps)
        end) or "none"
    end

    -- role
    local tank = type == "tank" or type == "t"
    local healer = type == "healer" or type == "h"
    local dps = type == "dps" or type == "d"

    if tank or healer or dps then
        if not capabilities.HasRoleAssignments() then
            return "none"
        end

        return fsEnumerable:From(friendlyUnits):Nth(number or 1, function(x)
            local role = wow.UnitGroupRolesAssigned(x)
            return (tank and role == wowEx.Role.Tank) or (healer and role == wowEx.Role.Healer) or (dps and role == wowEx.Role.Dps)
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
    if not body then
        fsLog:Error("Parser:GetNewBody() - body must not be nil.")
        return nil
    end

    if not friendlyUnits then
        fsLog:Error("Parser:GetNewBody() - friendlyUnits must not be nil.")
        return body
    end

    if not enemyUnits then
        fsLog:Error("Parser:GetNewBody() - enemyUnits must not be nil.")
        return body
    end

    local newBody = body
    local selectors = GetSelectors(body)

    for i, selector in ipairs(selectors) do
        if string.lower(selector) ~= skipSelector then
            local unit = M:UnitForSelector(selector, friendlyUnits, enemyUnits)
            local tmp = ReplaceSelector(newBody, unit, i)

            if tmp then
                newBody = tmp
            end
        end
    end

    return newBody
end
