---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local capabilities = addon.WoW.Capabilities
local fsUnit = addon.WoW.Unit
local fsMath = addon.Numerics.Math
local fsEnumerable = addon.Collections.Enumerable
local fsConfig = addon.Configuration
local fsInspector = addon.Modules.Inspector
local fsSpec = addon.Configuration.Specs
local fsLog = addon.Logging.Log

---@class Comparer
local M = {
    DecimalSanity = 0,
}
addon.Modules.Sorting.Comparer = M

local cachedRoleLookup, cachedSpecLookup, cachedClassLookup

---@return { [string]: number } roleOrderLookup
---@return { [number]: number } specOrderLookup
---@return { [number]: number } classTypeOrderLookup
local function Ordering()
    if cachedRoleLookup and cachedSpecLookup and cachedClassLookup then
        return cachedRoleLookup, cachedSpecLookup, cachedClassLookup
    end

    local config = addon.DB.Options.Sorting.Ordering
    local specs = fsConfig.Specs
    local specOrdering = fsEnumerable:New()
    local roleLookup = {}
    local ordering = {}

    local tankKey = fsSpec:SpecTypeKey(fsSpec.Type.Tank)
    local healerKey = fsSpec:SpecTypeKey(fsSpec.Type.Healer)
    local castersKey = fsSpec:SpecTypeKey(fsSpec.Type.Caster)
    local huntersKey = fsSpec:SpecTypeKey(fsSpec.Type.Hunter)
    local meleeKey = fsSpec:SpecTypeKey(fsSpec.Type.Melee)

    ordering[#ordering + 1] = { Key = tankKey, Order = config.Tanks, Type = fsSpec.Type.Tank }
    ordering[#ordering + 1] = { Key = healerKey, Order = config.Healers, Type = fsSpec.Type.Healer }
    ordering[#ordering + 1] = { Key = castersKey, Order = config.Casters, Type = fsSpec.Type.Caster }
    ordering[#ordering + 1] = { Key = huntersKey, Order = config.Hunters, Type = fsSpec.Type.Hunter }
    ordering[#ordering + 1] = { Key = meleeKey, Order = config.Melee, Type = fsSpec.Type.Melee }

    local function Priority(type, key)
        local priority = addon.DB.Options.Sorting.SpecPriority and addon.DB.Options.Sorting.SpecPriority[key]

        if not priority or #priority == 0 then
            priority = fsEnumerable
                :From(specs.Specs)
                :Where(function(item)
                    return item.Type == type
                end)
                :Map(function(item)
                    return item.SpecId
                end)
                :ToTable()
        end

        return priority
    end

    table.sort(ordering, function(a, b)
        return a.Order < b.Order
    end)

    for _, item in ipairs(ordering) do
        local priority = Priority(item.Type, item.Key)
        specOrdering = specOrdering:Concat(priority)

        if item.Type == fsSpec.Type.Tank then
            roleLookup[wowEx.Role.Tank] = item.Order
        elseif item.Type == fsSpec.Type.Healer then
            roleLookup[wowEx.Role.Healer] = item.Order
        end
    end

    local specLookup = specOrdering:ToDictionary(function(item, _)
        return item
    end, function(_, index)
        return index
    end)

    local classLookup = fsEnumerable:From(specs.Specs):ToDictionary(function(item)
        return item.ClassId
    end, function(item, existingValue)
        local newValue

        if item.Type == specs.Type.Tank then
            newValue = config.Tanks
        elseif item.Type == specs.Type.Healer then
            newValue = config.Healers
        elseif item.Type == specs.Type.Hunter then
            newValue = config.Hunters
        elseif item.Type == specs.Type.Caster then
            newValue = config.Casters
        elseif item.Type == specs.Type.Melee then
            newValue = config.Melee
        else
            newValue = 99
        end

        -- if there's an existing value then use the minimum of the two
        -- e.g. if they have tanks set to 1, and we're looking at a druid which can be tank/healer/dps, then prefer the tank value
        return math.min(newValue, existingValue or 99)
    end)

    cachedRoleLookup = roleLookup
    cachedSpecLookup = specLookup
    cachedClassLookup = classLookup

    return roleLookup, specLookup, classLookup
end

local function PrecomputeGlobalMetadata()
    local meta = {}
    local roleOrderLookup, specOrderLookup, classTypeOrderLookup = Ordering()

    meta.RoleOrderLookup = roleOrderLookup
    meta.SpecOrderLookup = specOrderLookup
    meta.ClassTypeOrderLookup = classTypeOrderLookup

    return meta
end

local function PrecomputeUnitMetadata(unit, meta, isEnemy)
    local data = {}

    data.IsPet = fsUnit:IsPet(unit)
    data.IsPlayer = not data.IsPet and fsUnit:IsPlayer(unit)
    data.IsTarget = fsUnit:IsRaidTarget(unit)
    data.UnitNumber = tonumber(string.match(unit, "%d+"))

    local isRaidTarget, targetDepth = fsUnit:IsRaidTarget(unit)

    data.IsRaidTarget = isRaidTarget
    data.RaidTargetDepth = targetDepth

    if isEnemy then
        -- don't need to check for exists here, because it's a pre-condition of how the enemy unit was generated in the first place
        if not data.IsPet and not data.IsTarget then
            data.SpecId = fsInspector:EnemyUnitSpec(unit)
            data.Role = wow.GetSpecializationInfoByID and data.SpecId and select(5, wow.GetSpecializationInfoByID(data.SpecId))

            local specInfo = data.SpecId and fsSpec:GetSpecInfo(data.SpecId)
            data.ClassId = specInfo and specInfo.ClassId
        end
    else
        data.Exists = wow.UnitExists(unit)

        if not data.IsPet and not data.IsTarget and data.Exists then
            data.Name = wow.UnitName and wow.UnitName(unit)

            if capabilities.HasRoleAssignments() then
                data.Role = wow.UnitGroupRolesAssigned(unit)
            end

            data.ClassId = wow.UnitClass and select(3, wow.UnitClass(unit))
            data.SpecId = fsInspector:FriendlyUnitSpec(unit)
        end
    end

    return data
end

local function PrecomputeMetadata(units, isEnemy)
    if #units == 0 then
        return {}
    end

    local start = wow.GetTimePreciseSec()
    local meta = PrecomputeGlobalMetadata()

    for _, unit in ipairs(units) do
        local data = PrecomputeUnitMetadata(unit, meta, isEnemy)
        meta[unit] = data
    end

    local stop = wow.GetTimePreciseSec()
    fsLog:Debug("Pre-computing unit metadata took %fms for %d units.", (stop - start) * 1000, #units)

    return meta
end

local function RoleOrClassTypeOrder(role, class, meta)
    local roleOrder = role and meta.RoleOrderLookup[role]

    if roleOrder then
        return roleOrder
    end

    if class then
        local order = meta.ClassTypeOrderLookup[class]
        return order
    end

    return nil
end

local function CompareGroup(leftToken, rightToken, meta)
    local leftMeta, rightMeta = meta[leftToken], meta[rightToken]

    if not leftMeta or not rightMeta then
        return leftToken < rightToken
    end

    if leftMeta.UnitNumber and rightMeta.UnitNumber then
        return leftMeta.UnitNumber < rightMeta.UnitNumber
    end

    -- could be "player" or "pet" or their unit name if in a bg
    return leftToken < rightToken
end

local function CompareAlphabetical(leftToken, rightToken, meta)
    local leftMeta, rightMeta = meta[leftToken], meta[rightToken]

    if not leftMeta or not rightMeta then
        return leftToken < rightToken
    end

    local leftName, rightName = leftMeta.Name, rightMeta.Name

    if leftName and rightName then
        return leftName < rightName
    end

    return CompareGroup(leftToken, rightToken, meta)
end

local function CompareSpec(leftToken, rightToken, meta)
    local leftMeta, rightMeta = meta[leftToken], meta[rightToken]

    if not leftMeta or not rightMeta then
        return leftToken < rightToken
    end

    local leftSpec = leftMeta.SpecId
    local rightSpec = rightMeta.SpecId

    local leftRole = leftMeta.Role
    local rightRole = rightMeta.Role

    local leftClass = leftMeta.ClassId
    local rightClass = rightMeta.ClassId

    local leftHasRole = leftRole ~= nil and leftRole ~= wowEx.Role.None
    local rightHasRole = rightRole ~= nil and rightRole ~= wowEx.Role.None

    if leftHasRole ~= rightHasRole then
        -- prefer those with a role
        -- true means left comes first
        return leftHasRole
    end

    -- check their role first
    -- we do this before checking their spec, because in some expansions spec doesn't map to role 1:1
    -- e.g. in retail a guardian druid is always a tank, but in classic a feral druid can be tank or dps
    -- also in SoD demo warlocks can tank, and mages can heal
    -- place player in front of everyone else
    if addon.DB.Options.Sorting.Miscellaneous.PlayerRoleSort == fsConfig.PlayerSortMode.Top and leftHasRole and rightHasRole and leftRole == rightRole then
        if leftMeta.IsPlayer then
            return true
        end

        if rightMeta.IsPlayer then
            return false
        end
    end

    local leftOrder = RoleOrClassTypeOrder(leftRole, leftClass, meta)
    local rightOrder = RoleOrClassTypeOrder(rightRole, rightClass, meta)

    if leftOrder and rightOrder and leftOrder ~= rightOrder then
        return leftOrder < rightOrder
    end

    -- next check their spec
    if leftSpec and leftSpec > 0 and rightSpec and rightSpec > 0 and leftSpec ~= rightSpec then
        local leftSpecOrder = meta.SpecOrderLookup[leftSpec]
        local rightSpecOrder = meta.SpecOrderLookup[rightSpec]

        if leftSpecOrder and rightSpecOrder and leftSpecOrder ~= rightSpecOrder then
            return leftSpecOrder < rightSpecOrder
        end
    end

    -- if their role and spec are the same (or we don't have spec info), fallback to class
    if leftClass and rightClass and leftClass ~= rightClass then
        return leftClass < rightClass
    end

    -- if they are the same role, class, and spec, then fallback to group sort
    return CompareGroup(leftToken, rightToken, meta)
end

---Returns true if the specified token is ordered after the mid point of player units.
---Pet units are ignored.
---@param token string
---@param meta table
---@return boolean
local function CompareMiddle(token, meta)
    if not meta.IndexLookup then
        fsLog:ErrorOnce("Comparer:CompareMiddle() - IndexLookup must not be nil.")
        return false
    end

    if not meta.Mid then
        fsLog:ErrorOnce("Comparer:CompareMiddle() - Mid must not be nil.")
        return false
    end

    local index = meta.IndexLookup[token]

    if not index then
        return false
    end

    return index > meta.Mid
end

---Returns true if the left token should be ordered before the right token.
---@param leftToken string
---@param rightToken string
---@param playerSortMode? string
---@param groupSortMode? string
---@param reverse boolean?
---@param meta table
---@return boolean
local function Compare(leftToken, rightToken, playerSortMode, groupSortMode, reverse, meta)
    if leftToken == rightToken then
        return false
    end

    local leftMeta, rightMeta = meta[leftToken], meta[rightToken]

    if not leftMeta or not rightMeta then
        -- this is either a bug, or we're in traditional mode where we don't get a chance to precompute the units
        leftMeta = leftMeta or PrecomputeUnitMetadata(leftToken, meta, false)
        rightMeta = rightMeta or PrecomputeUnitMetadata(rightToken, meta, false)

        meta[leftToken] = leftMeta
        meta[rightToken] = rightMeta
    end

    -- used to have UnitExists() checks here
    -- but it sometimes returns false in the arena starting room
    -- it also seemed to bring some problems when a new round starts in shuffle
    -- so leaving it out for now
    -- TODO: investigate this weirdness
    if leftMeta.IsPet or rightMeta.IsPet then
        -- place players before pets
        if leftMeta.IsPet then
            return false
        end

        if rightMeta.IsPet then
            return true
        end

        -- both are pets, compare their owner's
        local leftOwner = fsUnit:PetOwner(leftToken)
        local rightOwner = fsUnit:PetOwner(rightToken)

        if not leftOwner or leftOwner == "none" then
            return false
        end

        if not rightOwner or rightOwner == "none" then
            return true
        end

        return Compare(leftOwner, rightOwner, playerSortMode, groupSortMode, reverse, meta)
    end

    if leftMeta.IsRaidTarget or rightMeta.IsRaidTarget then
        local leftRoot = fsUnit:TargetOwner(leftToken) or leftToken
        local rightRoot = fsUnit:TargetOwner(rightToken) or rightToken

        if leftRoot ~= rightRoot then
            return Compare(leftRoot, rightRoot, playerSortMode, groupSortMode, reverse, meta)
        end

        return (leftMeta.RaidTargetDepth or 0) < (rightMeta.RaidTargetDepth or 0)
    end

    if playerSortMode and playerSortMode ~= "" then
        if leftMeta.IsPlayer then
            if playerSortMode == fsConfig.PlayerSortMode.Hidden then
                return false
            elseif playerSortMode == fsConfig.PlayerSortMode.Middle then
                return CompareMiddle(rightToken, meta)
            else
                return playerSortMode == fsConfig.PlayerSortMode.Top
            end
        end

        if rightMeta.IsPlayer then
            if playerSortMode == fsConfig.PlayerSortMode.Hidden then
                return true
            elseif playerSortMode == fsConfig.PlayerSortMode.Middle then
                return not CompareMiddle(leftToken, meta)
            else
                return playerSortMode == fsConfig.PlayerSortMode.Bottom
            end
        end
    end

    if reverse then
        leftToken, rightToken = rightToken, leftToken
    end

    if groupSortMode == fsConfig.GroupSortMode.Group then
        return CompareGroup(leftToken, rightToken, meta)
    elseif groupSortMode == fsConfig.GroupSortMode.Role then
        return CompareSpec(leftToken, rightToken, meta)
    elseif groupSortMode == fsConfig.GroupSortMode.Alphabetical then
        return CompareAlphabetical(leftToken, rightToken, meta)
    end

    return leftToken < rightToken
end

---Returns true if the left token should be ordered before the right token.
---@param leftToken string
---@param rightToken string
---@param groupSortMode? string
---@param reverse boolean?
---@param meta table
---@return boolean
local function EnemyCompare(leftToken, rightToken, groupSortMode, reverse, meta)
    if leftToken == rightToken then
        return false
    end

    local leftMeta, rightMeta = meta[leftToken], meta[rightToken]

    if not leftMeta or not rightMeta then
        return leftToken < rightToken
    end

    -- used to have UnitExists() checks here
    -- but it sometimes returns false in the arena starting room
    -- it also seemed to bring some problems when a new round starts in shuffle
    -- so leaving it out for now
    -- TODO: investigate this weirdness
    if leftMeta.IsPet or rightMeta.IsPet then
        -- place player before pets
        if not leftMeta.IsPet then
            return true
        end
        if not rightMeta.IsPet then
            return false
        end

        -- both are pets, compare their owner's
        local leftOwner = fsUnit:PetOwner(leftToken)
        local rightOwner = fsUnit:PetOwner(rightToken)

        if not leftOwner or leftOwner == "none" then
            return false
        end

        if not rightOwner or rightOwner == "none" then
            return true
        end

        return EnemyCompare(leftOwner, rightOwner, groupSortMode, reverse, meta)
    end

    if reverse then
        leftToken, rightToken = rightToken, leftToken
    end

    if groupSortMode == fsConfig.GroupSortMode.Group then
        return CompareGroup(leftToken, rightToken, meta)
    elseif groupSortMode == fsConfig.GroupSortMode.Role then
        return CompareSpec(leftToken, rightToken, meta)
    end

    return leftToken < rightToken
end

function M:InvalidateCache()
    cachedClassLookup = nil
    cachedRoleLookup = nil
    cachedSpecLookup = nil
end

---Returns a function that accepts two parameters of unit tokens and returns true if the left token should be ordered before the right.
---Sorting is based on the current instance and configured options.
---@param units string[]? optional unit tokens that will be sorted. providing this upfront improves performance.
---@return function|nil sort
function M:SortFunction(units)
    local enabled, playerSortMode, groupSortMode, reverse = M:FriendlySortMode()

    if not enabled then
        return nil
    end

    units = units or fsUnit:FriendlyUnits()
    local meta = PrecomputeMetadata(units, false)

    if playerSortMode ~= fsConfig.PlayerSortMode.Middle then
        return function(x, y)
            return Compare(x, y, playerSortMode, groupSortMode, reverse, meta)
        end
    end

    -- we need to pre-sort to determine where the middle actually is
    -- making use of Enumerable:OrderBy() so we don't re-order the original array
    units = fsEnumerable
        :From(units)
        :Where(function(x)
            return not wow.UnitIsUnit(x, "player")
        end)
        :OrderBy(function(x, y)
            return Compare(x, y, fsConfig.PlayerSortMode.Top, groupSortMode, reverse, meta)
        end)
        :ToTable()

    -- prepare data used for the middle sort comparator
    local index = {}
    local notPets = {}

    for _, unit in ipairs(units) do
        local unitMeta = meta[unit]

        if not unitMeta.IsPet and unitMeta.Exists then
            notPets[#notPets + 1] = unit
            index[unit] = #notPets
        end
    end

    meta.IndexLookup = index
    meta.Mid = math.floor(#notPets / 2)

    return function(x, y)
        return Compare(x, y, playerSortMode, groupSortMode, reverse, meta)
    end
end

---Returns a function that accepts two parameters of unit tokens and returns true if the left token should be ordered before the right.
---@param units string[] the unit tokens that will be sorted. required for performance reasons.
---@return function|nil sort
function M:EnemySortFunction(units)
    local enabled, groupSortMode, reverse = M:EnemySortMode()

    if not enabled then
        return nil
    end

    units = units or fsUnit:ArenaUnits()

    local meta = PrecomputeMetadata(units, true)
    return function(x, y)
        return EnemyCompare(x, y, groupSortMode, reverse, meta)
    end
end

---Returns the sort mode from the configured options for the current instance.
---@return boolean enabled whether sorting is enabled.
---@return string? playerMode the player sort mode.
---@return string? groupMode the group sort mode.
---@return boolean? reverse whether the sorting is reversed.
function M:FriendlySortMode()
    local inInstance, instanceType = wowEx.IsInInstance()
    local config = addon.DB.Options.Sorting

    if inInstance and instanceType == "arena" then
        local instanceSize = wowEx.GroupMembersCount()
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
    if wowEx.IsInstanceArena() then
        local config = addon.DB.Options.Sorting.EnemyArena
        return config.Enabled, config.GroupSortMode, config.Reverse
    end

    return false, nil, false
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

    local leftY = leftFrame:GetTop()
    local rightY = rightFrame:GetTop()

    if not leftY then
        return false
    end
    if not rightY then
        return true
    end

    leftY = fsMath:Round(leftY, M.DecimalSanity)
    rightY = fsMath:Round(rightY, M.DecimalSanity)

    if leftY ~= rightY then
        return leftY > rightY
    end

    local leftX = leftFrame:GetLeft()
    local rightX = rightFrame:GetLeft()

    if not leftX then
        return false
    end
    if not rightX then
        return true
    end

    leftX = fsMath:Round(leftX, M.DecimalSanity)
    rightX = fsMath:Round(rightX, M.DecimalSanity)

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

    local leftX = leftFrame:GetLeft()
    local rightX = rightFrame:GetLeft()

    if not leftX then
        return false
    end
    if not rightX then
        return true
    end

    leftX = fsMath:Round(leftX, M.DecimalSanity)
    rightX = fsMath:Round(rightX, M.DecimalSanity)

    if leftX ~= rightX then
        return leftX < rightX
    end

    local leftY = leftFrame:GetTop()
    local rightY = rightFrame:GetTop()

    if not leftY then
        return false
    end
    if not rightY then
        return true
    end

    leftY = fsMath:Round(leftY, M.DecimalSanity)
    rightY = fsMath:Round(rightY, M.DecimalSanity)

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

    local leftY = leftFrame:GetTop()
    local rightY = rightFrame:GetTop()

    if not leftY then
        return false
    end
    if not rightY then
        return true
    end

    leftY = fsMath:Round(leftY, M.DecimalSanity)
    rightY = fsMath:Round(rightY, M.DecimalSanity)

    if leftY ~= rightY then
        return leftY > rightY
    end

    local leftX = leftFrame:GetLeft()
    local rightX = rightFrame:GetLeft()

    if not leftX then
        return false
    end
    if not rightX then
        return true
    end

    leftX = fsMath:Round(leftX, M.DecimalSanity)
    rightX = fsMath:Round(rightX, M.DecimalSanity)

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

    local leftY = leftFrame:GetBottom()
    local rightY = rightFrame:GetBottom()

    if not leftY then
        return false
    end
    if not rightY then
        return true
    end

    leftY = fsMath:Round(leftY, M.DecimalSanity)
    rightY = fsMath:Round(rightY, M.DecimalSanity)

    if leftY ~= rightY then
        return leftY < rightY
    end

    local leftX = leftFrame:GetLeft()
    local rightX = rightFrame:GetLeft()

    if not leftX then
        return false
    end
    if not rightX then
        return true
    end

    leftX = fsMath:Round(leftX, M.DecimalSanity)
    rightX = fsMath:Round(rightX, M.DecimalSanity)

    return leftX < rightX
end
