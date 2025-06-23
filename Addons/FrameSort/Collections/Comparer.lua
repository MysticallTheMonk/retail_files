---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsUnit = addon.WoW.Unit
local fsMath = addon.Numerics.Math
local fsEnumerable = addon.Collections.Enumerable
local lgist = wow.IsRetail() and LibStub and LibStub:GetLibrary("LibGroupInSpecT-1.1")
local fsConfig = addon.Configuration
local fuzzyDecimalPlaces = 0
local defaultRoleOrdering = 99

---@class Comparer
local M = {}
addon.Collections.Comparer = M

local orderingCache = {}

local function Ordering()
    local config = addon.DB.Options.Sorting.Ordering
    local cacheKey = string.format("Tanks:%d,Healers:%d,Casters:%d,Hunters:%d,Melee:%d", config.Tanks, config.Healers, config.Casters, config.Hunters, config.Melee)
    local cached = orderingCache[cacheKey]

    if cached then
        return cached.Spec, cached.Role
    end

    local ids = fsConfig.SpecIds
    local specOrdering = fsEnumerable:New()
    local roleLookup = {}
    local ordering = {}

    ordering[config.Tanks] = "Tanks"
    ordering[config.Healers] = "Healers"
    ordering[config.Casters] = "Casters"
    ordering[config.Hunters] = "Hunters"
    ordering[config.Melee] = "Melee"

    for order, spec in pairs(ordering) do
        if spec == "Tanks" then
            roleLookup["TANK"] = order
            specOrdering = specOrdering:Concat(ids.Tanks)
        elseif spec == "Healers" then
            roleLookup["HEALER"] = order
            specOrdering = specOrdering:Concat(ids.Healers)
        elseif spec == "Casters" then
            roleLookup["DAMAGER"] = math.max(order, roleLookup["DAMAGER"] or 0)
            specOrdering = specOrdering:Concat(ids.Casters)
        elseif spec == "Hunters" then
            roleLookup["DAMAGER"] = math.max(order, roleLookup["DAMAGER"] or 0)
            specOrdering = specOrdering:Concat(ids.Hunters)
        elseif spec == "Melee" then
            roleLookup["DAMAGER"] = math.max(order, roleLookup["DAMAGER"] or 0)
            specOrdering = specOrdering:Concat(ids.Melee)
        end
    end

    local specLookup = specOrdering:ToLookup(function(item, _)
        return item
    end, function(_, index)
        return index
    end)

    orderingCache[cacheKey] = {
        Spec = specLookup,
        Role = roleLookup,
    }

    return specLookup, roleLookup
end

local function EmptyCompare(x, y)
    return x < y
end

local function CompareGroup(leftToken, rightToken, isArena)
    if not wow.IsInRaid() then
        -- string comparison is ok to use as party doesn't go above 1 digit
        return leftToken < rightToken
    end

    if isArena then
        local id1 = tonumber(string.sub(leftToken, 6))
        local id2 = tonumber(string.sub(rightToken, 6))

        if id1 and id2 then
            return id1 < id2
        end
    else
        -- the same way blizzard do it in CRFSort_Group
        local id1 = tonumber(string.sub(leftToken, 5))
        local id2 = tonumber(string.sub(rightToken, 5))

        if id1 and id2 then
            return id1 < id2
        end
    end

    -- the below probably isn't needed anymore
    -- fallback to a slower but more reliable comparison
    local left = tonumber(string.match(leftToken, "%d+"))
    local right = tonumber(string.match(rightToken, "%d+"))

    if left and right then
        return left < right
    end

    return leftToken < rightToken
end

local function CompareAlphabetical(leftToken, rightToken)
    local name1, name2 = wow.UnitName(leftToken), wow.UnitName(rightToken)

    if name1 and name2 then
        return name1 < name2
    end

    return CompareGroup(leftToken, rightToken, string.match(leftToken, "arena.*"))
end

local function CompareRole(leftToken, rightToken, isArena)
    local leftRole, rightRole = nil, nil
    local leftSpec, rightSpec = nil, nil

    if isArena then
        local leftId = tonumber(string.match(leftToken, "%d+"))
        local rightId = tonumber(string.match(rightToken, "%d+"))

        if not leftId or not rightId then
            return CompareGroup(leftToken, rightToken, isArena)
        end

        leftSpec = wow.GetArenaOpponentSpec(leftId)
        rightSpec = wow.GetArenaOpponentSpec(rightId)

        if not leftSpec or not rightSpec then
            return CompareGroup(leftToken, rightToken, isArena)
        end

        leftRole = select(5, wow.GetSpecializationInfoByID(leftSpec))
        rightRole = select(5, wow.GetSpecializationInfoByID(rightSpec))
    else
        -- can be null in unit tests
        if lgist then
            local leftData = lgist:GetCachedInfo(wow.UnitGUID(leftToken))
            local rightData = lgist:GetCachedInfo(wow.UnitGUID(rightToken))

            if leftData and rightData then
                leftSpec = leftData and leftData.global_spec_id
                rightSpec = rightData and rightData.global_spec_id

                leftRole = leftData.spec_role
                rightRole = rightData.spec_role
            end
        end

        if not leftRole or not rightRole then
            leftRole = wow.UnitGroupRolesAssigned(leftToken)
            rightRole = wow.UnitGroupRolesAssigned(rightToken)
        end
    end

    local specOrdering, roleOrdering = Ordering()

    if leftSpec and leftSpec > 0 and rightSpec and rightSpec > 0 and leftSpec ~= rightSpec then
        local leftSpecOrder = specOrdering[leftSpec]
        local rightSpecOrder = specOrdering[rightSpec]

        if leftSpecOrder and rightSpecOrder and leftSpecOrder ~= rightSpecOrder then
            return leftSpecOrder < rightSpecOrder
        end
    end

    if leftRole and rightRole and leftRole ~= rightRole then
        -- role's of "NONE" or some invalid value default to 99 to be put at the end
        local leftValue, rightValue = roleOrdering[leftRole] or defaultRoleOrdering, roleOrdering[rightRole] or defaultRoleOrdering

        if leftValue ~= rightValue then
            return leftValue < rightValue
        end
    end

    return CompareGroup(leftToken, rightToken, isArena)
end

---Returns true if the specified token is ordered after the mid point of player units.
---Pet units are ignored.
---@param token string
---@param sortedUnits table
---@return boolean
local function CompareMiddle(token, sortedUnits)
    local notPets = fsEnumerable
        :From(sortedUnits)
        :Where(function(unit)
            return not fsUnit:IsPet(unit) and wow.UnitExists(unit)
        end)
        :ToTable()

    -- index of the token we are comparing with
    local index = fsEnumerable:From(notPets):IndexOf(token)

    -- most likely a non-existant unit
    if not index then
        return false
    end

    local mid = math.floor(#notPets / 2)
    return index > mid
end

---Returns true if the left token should be ordered before the right token.
---preSortedUnits is required if playerSortMode == Middle.
---@param leftToken string
---@param rightToken string
---@param playerSortMode? string
---@param groupSortMode? string
---@param reverse boolean?
---@param preSortedUnits table?
---@return boolean
local function Compare(leftToken, rightToken, playerSortMode, groupSortMode, reverse, preSortedUnits)
    -- if not in a group, we might be in test mode
    if wow.UnitExists(leftToken) and not wow.UnitExists(rightToken) then
        return true
    elseif wow.UnitExists(rightToken) and not wow.UnitExists(leftToken) then
        return false
    end

    if fsUnit:IsPet(leftToken) or fsUnit:IsPet(rightToken) then
        -- place player before pets
        if not fsUnit:IsPet(leftToken) then
            return true
        end
        if not fsUnit:IsPet(rightToken) then
            return false
        end

        -- both are pets, compare their parent
        -- remove "pet" from the token to get the parent
        local leftTokenParent = leftToken == "pet" and "player" or string.gsub(leftToken, "pet", "")
        local rightTokenParent = rightToken == "pet" and "player" or string.gsub(rightToken, "pet", "")

        return Compare(leftTokenParent, rightTokenParent, playerSortMode, groupSortMode, reverse, preSortedUnits)
    end

    if playerSortMode and playerSortMode ~= "" then
        if leftToken == "player" or wow.UnitIsUnit(leftToken, "player") then
            if playerSortMode == fsConfig.PlayerSortMode.Hidden then
                return false
            elseif playerSortMode == fsConfig.PlayerSortMode.Middle then
                assert(preSortedUnits ~= nil)
                return CompareMiddle(rightToken, preSortedUnits)
            else
                return playerSortMode == fsConfig.PlayerSortMode.Top
            end
        end

        if rightToken == "player" or wow.UnitIsUnit(rightToken, "player") then
            if playerSortMode == fsConfig.PlayerSortMode.Hidden then
                return true
            elseif playerSortMode == fsConfig.PlayerSortMode.Middle then
                assert(preSortedUnits ~= nil)
                return not CompareMiddle(leftToken, preSortedUnits)
            else
                return playerSortMode == fsConfig.PlayerSortMode.Bottom
            end
        end
    end

    if reverse then
        leftToken, rightToken = rightToken, leftToken
    end

    if groupSortMode == fsConfig.GroupSortMode.Group then
        return CompareGroup(leftToken, rightToken)
    elseif groupSortMode == fsConfig.GroupSortMode.Role then
        return CompareRole(leftToken, rightToken)
    elseif groupSortMode == fsConfig.GroupSortMode.Alphabetical then
        return CompareAlphabetical(leftToken, rightToken)
    end

    return leftToken < rightToken
end

---Returns true if the left token should be ordered before the right token.
---@param leftToken string
---@param rightToken string
---@param groupSortMode? string
---@param reverse boolean?
---@return boolean
local function EnemyCompare(leftToken, rightToken, groupSortMode, reverse)
    -- used to have UnitExists() checks here
    -- but it returns false in the starting room
    -- it also seemed to bring some problems when a new round starts in shuffle
    -- so leaving it out for now
    if fsUnit:IsPet(leftToken) or fsUnit:IsPet(rightToken) then
        -- place player before pets
        if not fsUnit:IsPet(leftToken) then
            return true
        end
        if not fsUnit:IsPet(rightToken) then
            return false
        end

        -- both are pets, compare their parent
        local leftTokenParent = string.gsub(leftToken, "pet", "")
        local rightTokenParent = string.gsub(rightToken, "pet", "")

        return EnemyCompare(leftTokenParent, rightTokenParent, groupSortMode, reverse)
    end

    if reverse then
        leftToken, rightToken = rightToken, leftToken
    end

    if groupSortMode == fsConfig.GroupSortMode.Group then
        return CompareGroup(leftToken, rightToken, true)
    end

    local inInstance, instanceType = wow.IsInInstance()

    if groupSortMode == fsConfig.GroupSortMode.Role and inInstance and instanceType == "arena" and wow.IsRetail() then
        return CompareRole(leftToken, rightToken, true)
    end

    return leftToken < rightToken
end

---Returns a function that accepts two parameters of unit tokens and returns true if the left token should be ordered before the right.
---Sorting is based on the current instance and configured options.
---@param units string[]? the set of all unit tokens, only required if the player sort mode is "Middle"
---@return function sort
function M:SortFunction(units)
    local enabled, playerSortMode, groupSortMode, reverse = M:FriendlySortMode()

    if not enabled then
        return EmptyCompare
    end

    if playerSortMode ~= fsConfig.PlayerSortMode.Middle then
        return function(x, y)
            return Compare(x, y, playerSortMode, groupSortMode, reverse)
        end
    end

    units = units or fsUnit:FriendlyUnits()

    -- we need to pre-sort to determine where the middle actually is
    -- making use of Enumerable:OrderBy() so we don't re-order the original array
    units = fsEnumerable
        :From(units)
        :Where(function(x)
            return not wow.UnitIsUnit(x, "player")
        end)
        :OrderBy(function(x, y)
            return Compare(x, y, fsConfig.PlayerSortMode.Top, groupSortMode, reverse)
        end)
        :ToTable()

    return function(x, y)
        return Compare(x, y, playerSortMode, groupSortMode, reverse, units)
    end
end

---Returns a function that accepts two parameters of unit tokens and returns true if the left token should be ordered before the right.
---@return function sort
function M:EnemySortFunction()
    local enabled, groupSortMode, reverse = M:EnemySortMode()

    if not enabled then
        return EmptyCompare
    end

    return function(x, y)
        return EnemyCompare(x, y, groupSortMode, reverse)
    end
end

---Returns the sort mode from the configured options for the current instance.
---@return boolean enabled whether sorting is enabled.
---@return string? playerMode the player sort mode.
---@return string? groupMode the group sort mode.
---@return boolean? reverse whether the sorting is reversed.
function M:FriendlySortMode()
    local inInstance, instanceType = wow.IsInInstance()
    local config = addon.DB.Options.Sorting

    if inInstance and instanceType == "arena" then
        local instanceSize = wow.GetNumGroupMembers()
        local arena = instanceSize == 2 and config.Arena.Twos or config.Arena.Default

        return arena.Enabled, arena.PlayerSortMode, arena.GroupSortMode, arena.Reverse
    elseif inInstance and (instanceType == "party" or instanceType == "scenario") then
        -- scenario = delves
        return config.Dungeon.Enabled, config.Dungeon.PlayerSortMode, config.Dungeon.GroupSortMode, config.Dungeon.Reverse
    elseif inInstance and (instanceType == "raid" or instanceType == "pvp") then
        return config.Raid.Enabled, config.Raid.PlayerSortMode, config.Raid.GroupSortMode, config.Raid.Reverse
    end

    -- default to world rules for all other instance types
    return config.World.Enabled, config.World.PlayerSortMode, config.World.GroupSortMode, config.World.Reverse
end

---Returns the sort mode from the configured options for the current instance.
---@return boolean enabled whether sorting is enabled.
---@return string? groupMode the group sort mode.
---@return boolean? reverse whether the sorting is reversed.
function M:EnemySortMode()
    local config = addon.DB.Options.Sorting.EnemyArena

    return config.Enabled, config.GroupSortMode, config.Reverse
end

---Returns true if the left frame is "earlier" than the right frame.
---Earlier = more top left
---Fuzziness provides some leeway when comparing the top and left values.
---@param leftFrame table a wow frame
---@param rightFrame table a wow frame
---@return boolean
function M:CompareTopLeftFuzzy(leftFrame, rightFrame)
    if not leftFrame then
        return false
    end
    if not rightFrame then
        return true
    end

    local leftY = fsMath:Round(leftFrame:GetTop(), fuzzyDecimalPlaces)
    local rightY = fsMath:Round(rightFrame:GetTop(), fuzzyDecimalPlaces)

    if leftY ~= rightY then
        return leftY > rightY
    end

    local leftX = fsMath:Round(leftFrame:GetLeft(), fuzzyDecimalPlaces)
    local rightX = fsMath:Round(rightFrame:GetLeft(), fuzzyDecimalPlaces)

    return leftX < rightX
end

---Returns true if the left frame is "earlier" than the right frame.
---Earlier = more left top
---Fuzziness provides some leeway when comparing the top and left values.
---@param leftFrame table a wow frame
---@param rightFrame table a wow frame
---@return boolean
function M:CompareLeftTopFuzzy(leftFrame, rightFrame)
    if not leftFrame then
        return false
    end
    if not rightFrame then
        return true
    end

    local leftX = fsMath:Round(leftFrame:GetLeft(), fuzzyDecimalPlaces)
    local rightX = fsMath:Round(rightFrame:GetLeft(), fuzzyDecimalPlaces)

    if leftX ~= rightX then
        return leftX < rightX
    end

    local leftY = fsMath:Round(leftFrame:GetTop(), fuzzyDecimalPlaces)
    local rightY = fsMath:Round(rightFrame:GetTop(), fuzzyDecimalPlaces)

    return leftY > rightY
end

---Returns true if the left frame is "earlier" than the right frame.
---Earlier = more top right
---Fuzziness provides some leeway when comparing the top and left values.
---@param leftFrame table a wow frame
---@param rightFrame table a wow frame
---@return boolean
function M:CompareTopRightFuzzy(leftFrame, rightFrame)
    if not leftFrame then
        return false
    end
    if not rightFrame then
        return true
    end

    local leftY = fsMath:Round(leftFrame:GetTop(), fuzzyDecimalPlaces)
    local rightY = fsMath:Round(rightFrame:GetTop(), fuzzyDecimalPlaces)

    if leftY ~= rightY then
        return leftY > rightY
    end

    local leftX = fsMath:Round(leftFrame:GetLeft(), fuzzyDecimalPlaces)
    local rightX = fsMath:Round(rightFrame:GetLeft(), fuzzyDecimalPlaces)

    return leftX > rightX
end

---Returns true if the left frame is "earlier" than the right frame.
---Earlier = more bottom left
---Fuzziness provides some leeway when comparing the top and left values.
---@param leftFrame table a wow frame
---@param rightFrame table a wow frame
---@return boolean
function M:CompareBottomLeftFuzzy(leftFrame, rightFrame)
    if not leftFrame then
        return false
    end
    if not rightFrame then
        return true
    end

    local leftY = fsMath:Round(leftFrame:GetBottom(), fuzzyDecimalPlaces)
    local rightY = fsMath:Round(rightFrame:GetBottom(), fuzzyDecimalPlaces)

    if leftY ~= rightY then
        return leftY < rightY
    end

    local leftX = fsMath:Round(leftFrame:GetLeft(), fuzzyDecimalPlaces)
    local rightX = fsMath:Round(rightFrame:GetLeft(), fuzzyDecimalPlaces)

    return leftX < rightX
end
