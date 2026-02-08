---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local events = addon.WoW.Events
local fsSorting = addon.Modules.Sorting
local fsCompare = addon.Modules.Sorting.Comparer
local fsProviders = addon.Providers
local fsSortedUnits = addon.Modules.Sorting.SortedUnits
local fsScheduler = addon.Scheduling.Scheduler
local fsConfig = addon.Configuration
local fsEnumerable = addon.Collections.Enumerable
local fsLog = addon.Logging.Log
local fsFrame = addon.WoW.Frame
local M = {}
addon.Modules.Sorting.Secure.InCombat = M

local manager = nil
local memberHeader = nil
local petHeader = nil
local headers = {}
local secureMethods = {}

-- Findings:
-- * Calling RunAttribute has a massive overhead.
-- * RoundNative performs about 10x faster than the RunAttribute version.
-- So we want to avoid calling RunAttribute and instead inline code for tight loops.
secureMethods["OverheadTest"] = [[
    local run = control or self
    local times = 1000
    local decimalPlaces = 0

    run:CallMethod("StartTimer", "RoundMethod")
    for i = 1, times do
        local number = i + random()
        local rounded = run:RunAttribute("Round", number, decimalPlaces)
    end
    run:CallMethod("StopTimer", "RoundMethod", "RoundMethod took %fms.")

    run:CallMethod("StartTimer", "RoundNative")
    for i = 1, times do
        local number = i + random()
        local mult = 10 ^ (decimalPlaces or 0)
        local rounded = math.floor(number * mult + 0.5) / mult
    end
    run:CallMethod("StopTimer", "RoundNative", "RoundNative took %fms.")
]]

-- this method is no longer used because the overhead of calling RunAttribute is very expensive
-- and Round was being called in tight loops which caused significant time increase
-- even though overall we're only talking in milliseconds difference I still want to run as fast as possible
secureMethods["Round"] = [[
    local number, decimalPlaces = ...

    if number == nil then
        return nil
    end

    local mult = 10 ^ (decimalPlaces or 0)
    return math.floor(number * mult + 0.5) / mult
]]

-- returns true if in combat, otherwise false
secureMethods["InCombat"] = [[
    return SecureCmdOptionParse("[combat] true; false") == "true"
]]

-- gets the canonical unit token from a frame
secureMethods["GetUnit"] = [[
    local run = control or self
    local framesVariable = ...

    if not framesVariable then
        run:CallMethod("Log", format("GetUnit was passed a nil parameter, framesVariable: %s.", framesVariable or "nil"), LogLevel.Bug)
        return nil, nil
    end

    local frame = _G[framesVariable]

    if not frame then
        run:CallMethod("Log", "GetUnit was passed a nil frame.", LogLevel.Bug)
        return nil, nil
    end

    local unit = frame:GetAttribute("unit")

    if not unit then
        local name = frame:GetName()
        local arena = name and strmatch(name, "arena%d")

        if arena then
            arena = strlower(arena)
        end

        return arena, arena
    end

    unit = strlower(unit)

    -- normalise display unit (keeps pets distinct): party1pet -> partypet1, raid1pet -> raidpet1, arena1pet -> arenapet1
    local displayUnit = unit
    local n = strmatch(displayUnit, "^party(%d+)pet$")
    if n then
        displayUnit = "partypet" .. n
    else
        n = strmatch(displayUnit, "^raid(%d+)pet$")
        if n then
            displayUnit = "raidpet" .. n
        else
            n = strmatch(displayUnit, "^arena(%d+)pet$")
            if n then
                displayUnit = "arenapet" .. n
            end
        end
    end

    -- base unit for vehicle detection (strip "pet")
    local underlyingUnit = gsub(unit, "pet", "")

    -- optional: normalise underlying as well (mostly harmless)
    n = strmatch(underlyingUnit, "^party(%d+)$")
    if n then
        underlyingUnit = "party" .. n
    else
        n = strmatch(underlyingUnit, "^raid(%d+)$")
        if n then
            underlyingUnit = "raid" .. n
        else
            n = strmatch(underlyingUnit, "^arena(%d+)$")
            if n then
                underlyingUnit = "arena" .. n
            end
        end
    end

    if underlyingUnit ~= "" and UnitHasVehicleUI(underlyingUnit) then
        return underlyingUnit, displayUnit
    end

    return displayUnit, displayUnit
]]

-- filters a set of frames to only unit frames
secureMethods["ExtractUnitFrames"] = [[
    local run = control or self
    local framesVariable, destinationVariable, visibleOnly = ...
    local children = _G[framesVariable]

    if not children or not destinationVariable then
        run:CallMethod("Log", format("ExtractUnitFrames was passed a nil parameter, framesVariable: %s, destinationVariable: %s.", framesVariable or "nil", destinationVariable or "nil"), LogLevel.Bug)
        return false
    end

    if visibleOnly == nil then
        visibleOnly = true
    end

    local unitFrames = newtable()

    for _, child in ipairs(children) do
        Frame = child
        local unit = run:RunAttribute("GetUnit", "Frame")
        Frame = nil

        if child.GetRect then
            local left, bottom, width, height = child:GetRect()
            local hasSize = left and bottom and width and height

            if not hasSize then
                -- in some rare cases frames can have no position, so exclude them
                run:CallMethod("Log", format("Frame '%s' has no geometry.", child:GetName() or "nil"), LogLevel.Warning)
            end

            local isTarget = unit and strmatch(unit, "^raid%d+target")

            if unit and hasSize and
                (isTarget or (child:IsVisible() or not visibleOnly)) then
                unitFrames[#unitFrames + 1] = child
            end
        end
    end

    _G[destinationVariable] = unitFrames
    return #unitFrames > 0
]]

-- extracts a set of groups from a container
secureMethods["ExtractGroups"] = [[
    local run = control or self
    local containerTableName, destinationTableName = ...

    if not containerTableName or not destinationTableName then
        run:CallMethod("Log", format(
            "ExtractGroups was passed a nil parameter, containerTableName: %s, destinationTableName: %s.",
            containerTableName or "nil", destinationTableName or "nil"
        ), LogLevel.Bug)
        return false
    end

    local container = _G[containerTableName]

    if not container or not container.Frame then
        run:CallMethod("Log", format(
            "ExtractGroups was passed a nil container/frame, containerTableName: %s.",
            containerTableName or "nil"
        ), LogLevel.Bug)
        return false
    end

    local children = newtable()
    container.Frame:GetChildList(children)
    if #children == 0 then return false end

    local groups = newtable()

    for _, child in ipairs(children) do
        local name = child:GetName()
        local left, bottom, width, height = child:GetRect()

        if child:IsVisible() and name and left and bottom and width and height then
            if strmatch(name, "CompactRaidGroup") or strmatch(name, "CompactPartyFrame") then
                groups[#groups + 1] = child
            end
        end
    end

    _G[destinationTableName] = groups
    return #groups > 0
]]

-- copies elements from one table to another
secureMethods["CopyTable"] = [[
    local run = control or self
    local fromName, toName = ...
    local from = _G[fromName]
    local to = _G[toName]

    if not from or not to then
        run:CallMethod("Log", format("CopyTable was passed a nil value, from: %s to: %s.", fromName or "nil", toName or "nil"), LogLevel.Bug)
        return
    end

    for k, v in pairs(from) do
        to[k] = v
    end
]]

-- converts an array of frames in a chain layout to a linked list
-- where the root node is the start of the chain
-- and each subsequent node depends on the one before it
-- i.e. root -> frame1 -> frame2 -> frame3
secureMethods["FrameChain"] = [[
    local run = control or self
    local framesVariable, destinationVariable = ...

    if not framesVariable or not destinationVariable then
        run:CallMethod("Log", format(
            "FrameChain was passed a nil parameter, framesVariable: %s, destinationVariable: %s.",
            framesVariable or "nil", destinationVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local frames = _G[framesVariable]

    if not frames then
        run:CallMethod("Log", format(
            "FrameChain was passed a nil frame array, framesVariable: %s.",
            framesVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local nodesByFrame = newtable()

    for _, frame in ipairs(frames) do
        local node = newtable()
        node.Value = frame
        node.Next = nil
        node.Previous = nil
        nodesByFrame[frame] = node
    end

    local root = nil

    for i = 1, #frames do
        local frame = frames[i]
        local node = nodesByFrame[frame]

        if not node or not node.Value or not node.Value.GetPoint then
            return false
        end

        local _, relativeTo = node.Value:GetPoint()

        -- only treat relativeTo as a parent if it's a frame we know about
        local parent = (type(relativeTo) == "table") and nodesByFrame[relativeTo] or nil

        if not parent then
            if root then
                return false
            end
            root = node
        else
            if parent.Next then
                return false
            end
            parent.Next = node
            node.Previous = parent
        end
    end

    if not root then
        return false
    end

    -- assert we have a complete chain
    local count = 0
    local current = root
    local visited = newtable()

    while current do
        if visited[current] then
            -- protect against circular references
            return false
        end
        visited[current] = true
        count = count + 1
        current = current.Next
    end

    if count ~= #frames then
        return false
    end

    _G[destinationVariable] = root
    return true
]]

-- stable insertion sort
-- not going to write an nlog(n) sort algorithm in this environment
secureMethods["Sort"] = [[
    local run = control or self
    local arrayName, compareName, extraArg1 = ...

    if not arrayName or not compareName then
        run:CallMethod("Log", format("Sort was passed a nil parameter, arrayName: %s, compareName: %s.", arrayName or "nil", compareName or "nil"), LogLevel.Bug)
        return
    end

    local array = _G[arrayName]

    if not array then
        run:CallMethod("Log", format("Sort was passed a nil array, arrayName: %s, compareName: %s.", arrayName or "nil", compareName or "nil"), LogLevel.Bug)
        return
    end

    if #array <= 1 then
        return
    end

    for i = 2, #array do
        local currentValue = array[i]
        local insertPos = i - 1

        while insertPos >= 1 do
            Left  = currentValue
            Right = array[insertPos]

            -- true means Left should come before Right
            local currentBeforePrev = run:RunAttribute(compareName, "Left", "Right", extraArg1)

            if currentBeforePrev then
                array[insertPos + 1] = array[insertPos]
                insertPos = insertPos - 1
            else
                break
            end
        end

        array[insertPos + 1] = currentValue
    end

    Left, Right = nil, nil
]]

secureMethods["CompareFrameTopLeft"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...

    if not leftVariable or not rightVariable then
        run:CallMethod("Log", format("CompareFrameTopLeft was passed a nil parameter, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    local x, y = _G[leftVariable], _G[rightVariable]

    if not x or not y then
        run:CallMethod("Log", format("CompareFrameTopLeft was passed a nil value, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    local left, bottom, width, height = x:GetRect()
    local nextLeft, nextBottom, nextWidth, nextHeight = y:GetRect()

    if not left or not bottom or not height or not width then
        return false
    end

    if not nextLeft or not nextBottom or not nextHeight or not nextWidth then
        return true
    end

    local mult = 10 ^ DecimalSanity
    local topFuzzy = math.floor((bottom + height) * mult + 0.5) / mult
    local nextTopFuzzy = math.floor((nextBottom + nextHeight) * mult + 0.5) / mult

    if topFuzzy ~= nextTopFuzzy then
        return topFuzzy > nextTopFuzzy
    end

    local leftFuzzy = math.floor(left * mult + 0.5) / mult
    local nextLeftFuzzy = math.floor(nextLeft * mult + 0.5) / mult

    return leftFuzzy < nextLeftFuzzy
]]

secureMethods["CompareFrameTopRight"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...

    if not leftVariable or not rightVariable then
        run:CallMethod("Log", format("CompareFrameTopRight was passed a nil parameter, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    local x, y = _G[leftVariable], _G[rightVariable]

    if not x or not y then
        run:CallMethod("Log", format("CompareFrameTopRight was passed a nil value, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    local left, bottom, width, height = x:GetRect()
    local nextLeft, nextBottom, nextWidth, nextHeight = y:GetRect()

    if not left or not bottom or not height or not width then
        return false
    end

    if not nextLeft or not nextBottom or not nextHeight or not nextWidth then
        return true
    end

    local mult = 10 ^ DecimalSanity
    local topFuzzy = math.floor((bottom + height) * mult + 0.5) / mult
    local nextTopFuzzy = math.floor((nextBottom + nextHeight) * mult + 0.5) / mult

    if topFuzzy ~= nextTopFuzzy then
        return topFuzzy > nextTopFuzzy
    end

    local rightFuzzy = math.floor((left + width) * mult + 0.5) / mult
    local nextRightFuzzy = math.floor((nextLeft + nextWidth) * mult + 0.5) / mult

    return rightFuzzy > nextRightFuzzy
]]

secureMethods["CompareFrameBottomLeft"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...

    if not leftVariable or not rightVariable then
        run:CallMethod("Log", format("CompareFrameBottomLeft was passed a nil parameter, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    local x, y = _G[leftVariable], _G[rightVariable]

    if not x or not y then
        run:CallMethod("Log", format("CompareFrameBottomLeft was passed a nil value, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    local left, bottom, width, height = x:GetRect()
    local nextLeft, nextBottom, nextWidth, nextHeight = y:GetRect()

    if not left or not bottom or not height or not width then
        return false
    end

    if not nextLeft or not nextBottom or not nextHeight or not nextWidth then
        return true
    end

    local mult = 10 ^ DecimalSanity
    local bottomFuzzy = math.floor(bottom * mult + 0.5) / mult
    local nextBottomFuzzy = math.floor(nextBottom * mult + 0.5) / mult

    if bottomFuzzy ~= nextBottomFuzzy then
        return bottomFuzzy < nextBottomFuzzy
    end

    local leftFuzzy = math.floor(left * mult + 0.5) / mult
    local nextLeftFuzzy = math.floor(nextLeft * mult + 0.5) / mult

    return leftFuzzy < nextLeftFuzzy
]]

secureMethods["ComparePointTopLeft"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...

    if not leftVariable or not rightVariable then
        run:CallMethod("Log", format("ComparePointTopLeft was passed a nil parameter, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    local x, y = _G[leftVariable], _G[rightVariable]

    if not x or not y then
        run:CallMethod("Log", format("ComparePointTopLeft was passed a nil value, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    if not x.Bottom or not x.Height or not x.Left then
        return false
    end

    if not y.Bottom or not y.Height or not y.Left then
        return true
    end

    local mult = 10 ^ DecimalSanity
    local topFuzzy = math.floor((x.Bottom + x.Height) * mult + 0.5) / mult
    local nextTopFuzzy = math.floor((y.Bottom + y.Height) * mult + 0.5) / mult

    if topFuzzy ~= nextTopFuzzy then
        return topFuzzy > nextTopFuzzy
    end

    local leftFuzzy = math.floor(x.Left * mult + 0.5) / mult
    local nextLeftFuzzy = math.floor(y.Left * mult + 0.5) / mult

    return leftFuzzy < nextLeftFuzzy
]]

secureMethods["ComparePointLeftTop"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...

    if not leftVariable or not rightVariable then
        run:CallMethod("Log", format("ComparePointLeftTop was passed a nil parameter, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    local x, y = _G[leftVariable], _G[rightVariable]

    if not x or not y then
        run:CallMethod("Log", format("ComparePointLeftTop was passed a nil value, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    if not x.Bottom or not x.Height or not x.Left then
        return false
    end

    if not y.Bottom or not y.Height or not y.Left then
        return true
    end

    local mult = 10 ^ DecimalSanity
    local leftFuzzy = math.floor(x.Left * mult + 0.5) / mult
    local nextLeftFuzzy = math.floor(y.Left * mult + 0.5) / mult

    if leftFuzzy ~= nextLeftFuzzy then
        return leftFuzzy < nextLeftFuzzy
    end

    local topFuzzy = math.floor((x.Bottom + x.Height) * mult + 0.5) / mult
    local nextTopFuzzy = math.floor((y.Bottom + y.Height) * mult + 0.5) / mult

    return topFuzzy > nextTopFuzzy
]]

secureMethods["CompareFrameGroup"] = [[
    local run = control or self
    local leftVariable, rightVariable, playerSortMode = ...

    if not leftVariable or not rightVariable then
        run:CallMethod("Log", format("CompareFrameGroup was passed a nil parameter, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    local leftFrame = _G[leftVariable]
    local rightFrame = _G[rightVariable]

    if not leftFrame or not rightFrame then
        run:CallMethod("Log", format("CompareFrameGroup was passed a nil value, leftVariable: %s, rightVariable: %s.", leftVariable or "nil", rightVariable or "nil"), LogLevel.Bug)
        return false
    end

    -- Get their units
    Frame = leftFrame
    local leftUnit, leftToken = run:RunAttribute("GetUnit", "Frame")
    Frame = rightFrame
    local rightUnit, rightToken = run:RunAttribute("GetUnit", "Frame")
    Frame = nil

    if not leftUnit or not rightUnit then
        return false
    end

    local isLeftPet  = leftToken and strfind(leftToken, "pet") ~= nil
    local isRightPet = rightToken and strfind(rightToken, "pet") ~= nil

    if isLeftPet and not isRightPet then
        return false
    elseif not isLeftPet and isRightPet then
        return true
    end

    -- Top/Bottom is good enough, won't worry about middle in this environment
    -- if we got here we're in a fallback position anyway
    if playerSortMode and leftUnit == "player" then
        return playerSortMode == "Top"
    end

    if playerSortMode and rightUnit == "player" then
        return playerSortMode == "Bottom"
    end

    local leftIndex = tonumber(strmatch(leftUnit, "%d+")) or 0
    local rightIndex = tonumber(strmatch(rightUnit, "%d+")) or 0

    return leftIndex < rightIndex
]]

-- performs an out of place sort on an array frames by the order of the units array
secureMethods["SortFramesByUnits"] = [[
    local run = control or self
    local framesVariable, unitsVariable, destinationVariable = ...

    if not framesVariable or not unitsVariable or not destinationVariable then
        run:CallMethod("Log", format(
            "SortFramesByUnits was passed a nil parameter, framesVariable: %s, unitsVariable: %s, destinationVariable: %s.",
            framesVariable or "nil", unitsVariable or "nil", destinationVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local frames = _G[framesVariable]

    if not frames then
        run:CallMethod("Log", format("SortFramesByUnits was passed a nil frames value, framesVariable: %s, unitsVariable: %s, destinationVariable: %s.", framesVariable or "nil", unitsVariable or "nil", destinationVariable or "nil"), LogLevel.Bug)
        return false
    end

    local units = _G[unitsVariable]

    if not units then
        run:CallMethod("Log", format("SortFramesByUnits was passed a nil units value, framesVariable: %s, unitsVariable: %s, destinationVariable: %s.", framesVariable or "nil", unitsVariable or "nil", destinationVariable or "nil"), LogLevel.Bug)
        return false
    end

    local index = 1
    local framesByUnit = newtable()
    local frameWasSorted = newtable()

    for i = 1, #frames do
        local frame = frames[i]

        Frame = frame
        local unit, token = run:RunAttribute("GetUnit", "Frame") -- token is the original (may include "pet")
        Frame = nil

        if unit then
            local existing = framesByUnit[unit]

            if not existing then
                framesByUnit[unit] = frame
            else
                -- Decide which one to keep:
                -- Prefer the one whose token is NOT a pet token (more stable than height).
                Frame = existing
                local _, existingToken = run:RunAttribute("GetUnit", "Frame")
                Frame = nil

                local isPet = token and strfind(token, "pet") ~= nil
                local existingIsPet = existingToken and strfind(existingToken, "pet") ~= nil

                local keepNew = false

                if existingIsPet and not isPet then
                    -- new is better (non-pet beats pet)
                    keepNew = true
                elseif isPet and not existingIsPet then
                    -- existing is better
                    keepNew = false
                else
                    -- tie-breaker: prefer taller
                    local newH = frame.GetHeight and frame:GetHeight() or 0
                    local oldH = existing.GetHeight and existing:GetHeight() or 0
                    keepNew = newH > oldH
                end

                if keepNew then
                    framesByUnit[unit] = frame
                end
            end
        else
            run:CallMethod("Log", format("Failed to determine unit of frame: %s.", frame:GetName() or "nil"), LogLevel.Warning)
        end
    end

    local sorted = newtable()

    for i = 1, #units do
        local unit = units[i]
        local frame = framesByUnit[unit]

        if frame then
            sorted[#sorted + 1] = frame
            frameWasSorted[frame] = true
        end
    end

    -- any frames left unsorted at this point?
    local unsortedFrames = false

    for i = 1, #frames do
        local frame = frames[i]

        if not frameWasSorted[frame] and frame:IsVisible() then
            Frame = frame
            local unit, token = run:RunAttribute("GetUnit", "Frame")
            Frame = nil

            local isPet = token and strfind(token, "pet") ~= nil

            -- don't care if it's an unsorted pet, as we'll just place them at the end
            if not isPet then
                run:CallMethod("Log", format("Couldn't find destination position for frame %s with unit %s", frame:GetName() or "nil", unit or "nil"), LogLevel.Error)
                unsortedFrames = true
                break
            end
        end
    end

    -- we can't sort frames, something has changed during combat
    if unsortedFrames then
        return false
    end

    -- we may not have all pet unit information
    -- so any frames that didn't make it we can just add on to the end
    for i = 1, #frames do
        local frame = frames[i]

        if not frameWasSorted[frame] then
            sorted[#sorted + 1] = frame
        end
    end

    _G[destinationVariable] = sorted
    return true
]]

-- adjusts the x and y offsets of a frame
secureMethods["AdjustPointsOffset"] = [[
    local run = control or self
    local framesVariable, xDelta, yDelta = ...

    if not framesVariable or xDelta == nil or yDelta == nil then
        run:CallMethod("Log", format("AdjustPointsOffset was passed a nil parameter, framesVariable: %s, xDelta: %s, yDelta: %s.", framesVariable or "nil", xDelta or "nil", yDelta or "nil"), LogLevel.Bug)
        return false
    end

    local frame = _G[framesVariable]

    if not frame then
        run:CallMethod("Log", format("AdjustPointsOffset was passed a nil frame, framesVariable: %s.", framesVariable or "nil"), LogLevel.Critical)
        return nil
    end

    if xDelta == 0 and yDelta == 0 then
        return false
    end

    local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint()

    if not point or not relativePoint then
        return false
    end

    local newOffsetX = (offsetX or 0) + xDelta
    local newOffsetY = (offsetY or 0) + yDelta

    local newRelativeTo = relativeTo

    if not newRelativeTo then
        newRelativeTo = "$parent"
    else
        local isProtected, explicitly = false, false

        if type(newRelativeTo) == "table" and newRelativeTo.IsProtected then
            isProtected, explicitly = newRelativeTo:IsProtected()
        end

        if not isProtected or not explicitly then
            newRelativeTo = "$parent"
        end
    end

    frame:SetPoint(point, newRelativeTo, relativePoint, newOffsetX, newOffsetY)
    return true
]]

-- returns the spacing configuration for the specified container type
secureMethods["SpacingForContainer"] = [[
    local run = control or self
    local containerType = ...
    local spacingType = nil

    if not containerType then
        run:CallMethod("Log", format("SpacingForContainer was passed a nil parameter, containerType: %s.", containerType or "nil"), LogLevel.Bug)
        return nil, nil
    end

    if containerType == ContainerType.Party then
        spacingType = "Party"
    elseif containerType == ContainerType.Raid then
        spacingType = "Raid"
    elseif containerType == ContainerType.EnemyArena then
        spacingType = "EnemyArena"
    else
        run:CallMethod("Log", format("SpacingForContainer was passed an invalid parameter, containerType: %s.", containerType or "nil"), LogLevel.Bug)
        return nil, nil
    end

    local horizontalSpacing = self:GetAttribute(spacingType .. "SpacingHorizontal")
    local verticalSpacing = self:GetAttribute(spacingType .. "SpacingVertical")

    return horizontalSpacing, verticalSpacing
]]

-- applies spacing on a set of points
secureMethods["ApplySpacing"] = [[
    local run = control or self
    local pointsVariable, spacingVariable = ...

    if not pointsVariable or not spacingVariable then
        run:CallMethod("Log", format("ApplySpacing was passed a nil parameter, pointsVariable: %s, spacingVariable: %s.", pointsVariable or "nil", spacingVariable or "nil"), LogLevel.Bug)
        return nil
    end

    local points = _G[pointsVariable]
    local spacing = _G[spacingVariable]

    if not points or not spacing then
        run:CallMethod("Log", format("ApplySpacing was passed a nil value, pointsVariable: %s, spacingVariable: %s.", pointsVariable or "nil", spacingVariable or "nil"), LogLevel.Critical)
        return nil
    end

    local horizontal = spacing.Horizontal or 0
    local vertical = spacing.Vertical or 0

    -- Snapshot original coords so the second pass doesn't "drift" after the first mutates Left/Bottom.
    for i = 1, #points do
        local p = points[i]
        if not p or p.Left == nil or p.Bottom == nil or p.Width == nil or p.Height == nil then
            run:CallMethod("Log", "ApplySpacing was passed a point missing Left/Bottom/Width/Height.", LogLevel.Critical)
            return nil
        end
        p.OriginalLeft = p.Left
        p.OriginalBottom = p.Bottom
    end

    OrderedTopLeft = newtable()
    OrderedLeftTop = newtable()

    run:RunAttribute("CopyTable", pointsVariable, "OrderedTopLeft")
    run:RunAttribute("CopyTable", pointsVariable, "OrderedLeftTop")

    run:RunAttribute("Sort", "OrderedTopLeft", "ComparePointTopLeft")
    run:RunAttribute("Sort", "OrderedLeftTop", "ComparePointLeftTop")

    local changed = false
    local mult = 10 ^ DecimalSanity

    -- Pass 1: horizontal spacing within a row (row grouping based on ORIGINAL coords)
    for i = 2, #OrderedLeftTop do
        local point = OrderedLeftTop[i]
        local previous = OrderedLeftTop[i - 1]

        local pointTopFuzzy = math.floor((point.OriginalBottom + point.Height) * mult + 0.5) / mult
        local previousTopFuzzy = math.floor((previous.OriginalBottom + previous.Height) * mult + 0.5) / mult
        local sameRow = pointTopFuzzy == previousTopFuzzy

        if sameRow then
            local existingSpace = point.Left - (previous.Left + previous.Width)
            local xDelta = horizontal - existingSpace
            point.Left = point.Left + xDelta
            changed = changed or xDelta ~= 0
        end
    end

    -- Pass 2: vertical spacing within a column (column grouping based on ORIGINAL coords)
    for i = 2, #OrderedTopLeft do
        local point = OrderedTopLeft[i]
        local previous = OrderedTopLeft[i - 1]

        local leftFuzzy = math.floor(point.OriginalLeft * mult + 0.5) / mult
        local previousLeftFuzzy = math.floor(previous.OriginalLeft * mult + 0.5) / mult
        local sameColumn = leftFuzzy == previousLeftFuzzy

        if sameColumn then
            local existingSpace = previous.Bottom - (point.Bottom + point.Height)
            local yDelta = vertical - existingSpace
            point.Bottom = point.Bottom - yDelta
            changed = changed or yDelta ~= 0
        end
    end

    -- Cleanup snapshot fields (keeps point tables lean)
    for i = 1, #points do
        local p = points[i]
        p.OriginalLeft = nil
        p.OriginalBottom = nil
    end

    OrderedTopLeft = nil
    OrderedLeftTop = nil

    return changed
]]

-- applies spacing between raid groups
secureMethods["SpaceGroups"] = [[
    local run = control or self
    local groupsVariable, spacingVariable = ...

    if not groupsVariable or not spacingVariable then
        run:CallMethod("Log", format(
            "SpaceGroups was passed a nil parameter, groupsVariable: %s, spacingVariable: %s.",
            groupsVariable or "nil", spacingVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local groups = _G[groupsVariable]
    local spacing = _G[spacingVariable]

    if not groups or not spacing then
        run:CallMethod("Log", format(
            "SpaceGroups was passed a nil value, groupsVariable: %s, spacingVariable: %s.",
            groupsVariable or "nil", spacingVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    if #groups <= 1 then
        return false
    end

    -- Build destination slots from groups that have valid rect
    Slots = newtable()
    local validGroups = newtable()

    for _, group in ipairs(groups) do
        if group and group.GetRect then
            local left, bottom, width, height = group:GetRect()

            if left and bottom and width and height then
                local point = newtable()
                point.Left = left
                point.Bottom = bottom
                point.Width = width
                point.Height = height

                Slots[#Slots + 1] = point
                validGroups[#validGroups + 1] = group
            else
                run:CallMethod("Log", format("Group frame %s has no position.", group:GetName() or "nil"), LogLevel.Warning)
            end
        end
    end

    local slotsCount = #Slots
    if slotsCount <= 1 then
        Slots = nil
        validGroups = nil
        return false
    end

    local changed = run:RunAttribute("ApplySpacing", "Slots", spacingVariable)

    if changed == nil then
        Slots = nil
        validGroups = nil
        return false
    end

    DestByGroup = newtable()
    for i = 1, slotsCount do
        local slot = Slots[i]
        local group = validGroups[i]
        DestByGroup[group] = slot
    end

    local movedAny = false
    local mult = 10 ^ DecimalSanity

    for _, group in ipairs(validGroups) do
        if group and group.GetRect then
            local left, bottom, width, height = group:GetRect()

            if left and bottom and width and height then
                local destination = DestByGroup[group]

                if destination then
                    local xDelta = destination.Left - left
                    local yDelta = destination.Bottom - bottom

                    local xDeltaRounded = math.floor(xDelta * mult + 0.5) / mult
                    local yDeltaRounded = math.floor(yDelta * mult + 0.5) / mult

                    if xDeltaRounded ~= 0 or yDeltaRounded ~= 0 then
                        Group = group
                        local moved = run:RunAttribute("AdjustPointsOffset", "Group", xDelta, yDelta)
                        movedAny = movedAny or moved
                        Group = nil
                    end
                end
            end
        end
    end

    DestByGroup = nil
    Slots = nil
    validGroups = nil

    return movedAny
]]

-- rearranges a set of frames by only modifying the x and y offsets
secureMethods["SoftArrange"] = [[
    local run = control or self
    local framesVariable, spacingVariable = ...

    if not framesVariable then
        run:CallMethod("Log", format("SoftArrange was passed a nil parameter, framesVariable: %s.", framesVariable or "nil"), LogLevel.Bug)
        return false
    end

    local frames = _G[framesVariable]

    if not frames then
        run:CallMethod("Log", format("SoftArrange was passed a nil frames value, framesVariable: %s.", framesVariable or "nil"), LogLevel.Bug)
        return false
    end

    if #frames <= 1 then
        return false
    end

    Slots = newtable()
    ValidFrames = newtable()

    for _, frame in ipairs(frames) do
        if frame and frame.GetRect then
            local left, bottom, width, height = frame:GetRect()

            if left and bottom and width and height then
                ValidFrames[#ValidFrames + 1] = frame
            end
        end
    end

    OrderedByTopLeft = newtable()
    run:RunAttribute("CopyTable", "ValidFrames", "OrderedByTopLeft")
    run:RunAttribute("Sort", "OrderedByTopLeft", "CompareFrameTopLeft")

    for _, frame in ipairs(OrderedByTopLeft) do
        if frame and frame.GetRect then
            local left, bottom, width, height = frame:GetRect()
            if left and bottom and width and height then
                local point = newtable()
                point.Left = left
                point.Bottom = bottom
                point.Width = width
                point.Height = height

                Slots[#Slots + 1] = point
            end
        end
    end

    local slotsCount = #Slots
    if slotsCount <= 1 then
        OrderedByTopLeft = nil
        Slots = nil
        ValidFrames = nil
        return false
    end

    local spacing = spacingVariable and _G[spacingVariable]

    if spacing then
        local changed = run:RunAttribute("ApplySpacing", "Slots", spacingVariable)
        if changed == nil then
            OrderedByTopLeft = nil
            Slots = nil
            ValidFrames = nil
            return false
        end
    end

    DestByFrame = newtable()
    for i = 1, #Slots do
        local slot = Slots[i]
        local frame = ValidFrames[i]

        DestByFrame[frame] = slot
    end

    -- Enumerate in chain order if available (movement order)
    Root = nil
    local isChain = run:RunAttribute("FrameChain", "OrderedByTopLeft", "Root")
    local root = Root
    Root = nil

    local enumerationOrder
    if isChain and root then
        enumerationOrder = newtable()
        local next = root
        while next do
            enumerationOrder[#enumerationOrder + 1] = next.Value
            next = next.Next
        end
    else
        enumerationOrder = OrderedByTopLeft
    end

    OrderedByTopLeft = nil

    local movedAny = false
    local mult = 10 ^ DecimalSanity

    for _, source in ipairs(enumerationOrder) do
        if source and source.GetRect then
            local left, bottom, width, height = source:GetRect()

            if left and bottom and width and height then
                local destination = DestByFrame[source]

                if destination then
                    local xDelta = destination.Left - left
                    local yDelta = destination.Bottom - bottom

                    local xDeltaRounded = math.floor(xDelta * mult + 0.5) / mult
                    local yDeltaRounded = math.floor(yDelta * mult + 0.5) / mult

                    if xDeltaRounded ~= 0 or yDeltaRounded ~= 0 then
                        Frame = source
                        local moved = run:RunAttribute("AdjustPointsOffset", "Frame", xDelta, yDelta)
                        movedAny = movedAny or moved
                        Frame = nil
                    end
                end
            end
        end
    end

    DestByFrame = nil
    Slots = nil
    ValidFrames = nil
    enumerationOrder = nil
    return movedAny
]]

-- rearranges a set of frames by modifying their anchors and offsets
secureMethods["HardArrange"] = [[
    local run = control or self
    local framesVariable, containerVariable, spacingVariable, blockHeight = ...

    if not framesVariable or not containerVariable then
        run:CallMethod("Log", format(
            "HardArrange was passed a nil parameter, framesVariable: %s, containerVariable: %s.",
            framesVariable or "nil", containerVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local frames = _G[framesVariable]
    local container = _G[containerVariable]

    if not frames or not container then
        run:CallMethod("Log", format(
            "HardArrange was passed a nil value, framesVariable: %s, containerVariable: %s.",
            framesVariable or "nil", containerVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local spacing = spacingVariable and _G[spacingVariable]
    local verticalSpacing = spacing and spacing.Vertical or 0
    local horizontalSpacing = spacing and spacing.Horizontal or 0
    local isHorizontalLayout = container.IsHorizontalLayout == true
    local blocksPerLine = container.FramesPerLine

    local firstValid = nil

    for _, frame in ipairs(frames) do
        if frame and frame.GetHeight and frame.GetWidth then
            local h, w = frame:GetHeight(), frame:GetWidth()
            if h and h > 0 and w and w > 0 then
                firstValid = frame
                break
            end
        end
    end

    if not firstValid then
        run:CallMethod("Log", "HardArrange (in-combat): no valid frames with size.", LogLevel.Error)
        return false
    end

    local blockWidth = firstValid:GetWidth()
    blockHeight = blockHeight or firstValid:GetHeight()

    if not blockWidth or blockWidth <= 0 or not blockHeight or blockHeight <= 0 then
        run:CallMethod("Log", "HardArrange (in-combat): invalid block dimensions.", LogLevel.Error)
        return false
    end

    local offset = container.Offset or newtable()
    offset.X = offset.X or 0
    offset.Y = offset.Y or 0

    local pointsByFrame = newtable()
    local row, col = 0, 0
    local xOffset = offset.X
    local yOffset = offset.Y
    local currentBlockHeight = 0
    local mult = 10 ^ DecimalSanity

    for _, frame in ipairs(frames) do
        local height = frame and frame.GetHeight and frame:GetHeight()

        if height and height > 0 then
            local isNewBlock = currentBlockHeight > 0
                and (
                    currentBlockHeight >= (blockHeight - 1)
                    or (currentBlockHeight + height) >= (blockHeight + 1)
                )

            if isNewBlock then
                currentBlockHeight = 0

                if isHorizontalLayout then
                    col = col + 1
                else
                    row = row + 1
                end

                xOffset = col * (blockWidth + horizontalSpacing) + offset.X
                yOffset = -row * (blockHeight + verticalSpacing) + offset.Y
            end

            if isHorizontalLayout and blocksPerLine and col >= blocksPerLine then
                col = 0
                row = row + 1
                xOffset = offset.X
                yOffset = -row * (blockHeight + verticalSpacing) + offset.Y
                currentBlockHeight = 0
            elseif (not isHorizontalLayout) and blocksPerLine and row >= blocksPerLine then
                row = 0
                col = col + 1
                yOffset = offset.Y
                xOffset = col * (blockWidth + horizontalSpacing) + offset.X
                currentBlockHeight = 0
            end

            local framePoint = newtable()
            framePoint.Point = container.AnchorPoint or "TOPLEFT"
            framePoint.RelativeTo = container.Anchor or container.Frame
            framePoint.RelativePoint = container.AnchorPoint or "TOPLEFT"
            framePoint.XOffset = xOffset
            framePoint.YOffset = yOffset
            pointsByFrame[frame] = framePoint

            currentBlockHeight = currentBlockHeight + height
            yOffset = yOffset - height
        end
    end

    local framesToMove = newtable()

    for _, frame in ipairs(frames) do
        local to = frame and pointsByFrame[frame]

        if to and frame.GetPoint and frame.GetNumPoints and frame.ClearAllPoints and frame.SetPoint then
            local different = frame:GetNumPoints() ~= 1

            if not different then
                local point, relativeTo, relativePoint, xOffset, yOffset = frame:GetPoint(1)
                local xOffsetRounded = math.floor((xOffset or 0) * mult + 0.5) / mult
                local yOffsetRounded = math.floor((yOffset or 0) * mult + 0.5) / mult
                local toXOffsetRounded = math.floor((to.XOffset or 0) * mult + 0.5) / mult
                local toYOffsetRounded = math.floor((to.YOffset or 0) * mult + 0.5) / mult

                different =
                    point ~= to.Point or
                    relativeTo ~= to.RelativeTo or
                    relativePoint ~= to.RelativePoint or
                    xOffsetRounded ~= toXOffsetRounded or
                    yOffsetRounded ~= toYOffsetRounded
            end

            if different then
                framesToMove[#framesToMove + 1] = frame
            end
        end
    end

    for _, frame in ipairs(framesToMove) do
        local to = frame and pointsByFrame[frame]
        -- since 10.2.7 this broke where to.RelativeTo must be a protected frame
        -- thankfully we can use a magic string to default it to the parent even if it's not protected
        local newRelativeTo = to and to.RelativeTo

        if to and frame.ClearAllPoints and frame.SetPoint then
            if not newRelativeTo then
                newRelativeTo = "$parent"
            else
                local isProtected, explicitly = false, false
                if type(newRelativeTo) == "table" and newRelativeTo.IsProtected then
                    isProtected, explicitly = newRelativeTo:IsProtected()
                end
                if not isProtected or not explicitly then
                    newRelativeTo = "$parent"
                end
            end

            frame:ClearAllPoints()
            frame:SetPoint(to.Point, newRelativeTo, to.RelativePoint, to.XOffset or 0, to.YOffset or 0)
        end
    end

    return #framesToMove > 0
]]

-- determines the offset to use for the ungrouped portion of the raid frames.
secureMethods["UngroupedOffset"] = [[
    local run = control or self
    local containerVariable, spacingVariable = ...

    if not containerVariable then
        run:CallMethod("Log", format("UngroupedOffset was passed a nil parameter, containerVariable: %s.", containerVariable or "nil"), LogLevel.Bug)
        return 0, 0
    end

    local container = _G[containerVariable]
    local spacing = spacingVariable and _G[spacingVariable]

    if not container or not container.Frame then
        run:CallMethod("Log", format("UngroupedOffset was passed a nil container/frame, containerVariable: %s.", containerVariable or "nil"), LogLevel.Bug)
        return 0, 0
    end

    if not run:RunAttribute("ExtractGroups", containerVariable, "OffsetGroups") then
        return 0, 0
    end

    local lastGroup = nil
    for i = #OffsetGroups, 1, -1 do
        local group = OffsetGroups[i]
        if group and group.IsVisible and group:IsVisible() then
            lastGroup = group
            break
        end
    end

    if not lastGroup then
        OffsetGroups = nil
        return 0, 0
    end

    OffsetGroupChildren = newtable()
    if lastGroup.GetChildList then
        lastGroup:GetChildList(OffsetGroupChildren)
    end

    if not run:RunAttribute("ExtractUnitFrames", "OffsetGroupChildren", "OffsetGroupFrames", container.VisibleOnly) then
        OffsetGroups = nil
        OffsetGroupFrames = nil
        OffsetGroupChildren = nil
        return 0, 0
    end

    local horizontal = container.IsHorizontalLayout == true

    if not spacing then
        spacing = newtable()
        spacing.Horizontal = 0
        spacing.Vertical = 0
    end

    local x, y = 0, 0
    local left, bottom, width, height = container.Frame:GetRect()
    if not left or not bottom or not width or not height then
        OffsetGroupChildren = nil
        OffsetGroupFrames = nil
        OffsetGroups = nil
        return 0, 0
    end

    if horizontal then
        run:RunAttribute("Sort", "OffsetGroupFrames", "CompareFrameBottomLeft")

        local bottomLeftFrame = OffsetGroupFrames[1]
        if bottomLeftFrame and bottomLeftFrame.GetRect then
            local bottomFrameLeft, bottomFrameBottom = bottomLeftFrame:GetRect()
            if bottomFrameLeft and bottomFrameBottom then
                x = -(left - bottomFrameLeft)
                y = -((bottom + height) - bottomFrameBottom + (spacing.Vertical or 0))
            end
        end
    else
        run:RunAttribute("Sort", "OffsetGroupFrames", "CompareFrameTopRight")

        local topRightFrame = OffsetGroupFrames[1]
        if topRightFrame and topRightFrame.GetRect then
            local topFrameLeft, topFrameBottom, topFrameWidth, topFrameHeight = topRightFrame:GetRect()
            if topFrameLeft and topFrameBottom and topFrameWidth and topFrameHeight then
                x = -(left - (topFrameLeft + topFrameWidth) - (spacing.Horizontal or 0))
                y = -((bottom + height) - (topFrameBottom + topFrameHeight))
            end
        end
    end

    OffsetGroupChildren = nil
    OffsetGroupFrames = nil
    OffsetGroups = nil

    return x, y
]]

secureMethods["TrySortContainerGroups"] = [[
    local run = control or self
    local containerVariable, providerVariable, destinationFramesVariable = ...

    if not containerVariable or not providerVariable then
        run:CallMethod("Log", format(
            "TrySortContainerGroups was passed a nil parameter, containerVariable: %s, providerVariable: %s.",
            containerVariable or "nil", providerVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local container = _G[containerVariable]
    local provider = _G[providerVariable]

    if not container or not provider then
        run:CallMethod("Log", format(
            "TrySortContainerGroups was passed a nil value, containerVariable: %s, providerVariable: %s.",
            containerVariable or "nil", providerVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local blockHeight = nil
    local sorted = false

    Groups = nil
    if not run:RunAttribute("ExtractGroups", containerVariable, "Groups") then
        return false
    end

    for _, group in ipairs(Groups) do
        GroupContainer = newtable()
        -- just copy over all the attributes to make code simpler
        run:RunAttribute("CopyTable", containerVariable, "GroupContainer")

        -- now re-write over the top
        GroupContainer.Frame = group
        GroupContainer.Offset = newtable()

        if container.GroupOffset then
            GroupContainer.Offset.X = container.GroupOffset.X
            GroupContainer.Offset.Y = container.GroupOffset.Y
        end

        ContainerFrames = nil
        sorted = run:RunAttribute("TrySortContainer", "GroupContainer", providerVariable, "ContainerFrames") or sorted

        if not blockHeight and ContainerFrames then
            for _, f in ipairs(ContainerFrames) do
                local h = f and f.GetHeight and f:GetHeight()
                if h and h > 0 then blockHeight = h; break end
            end
        end

        ContainerFrames = nil
        GroupContainer = nil
    end

    if not container.SupportsSpacing then
        Groups = nil
        return sorted
    end

    local horizontalSpacing, verticalSpacing = run:RunAttribute("SpacingForContainer", container.Type)

    if (not horizontalSpacing and not verticalSpacing) or ((horizontalSpacing or 0) == 0 and (verticalSpacing or 0) == 0) then
        Groups = nil
        return sorted
    end

    GroupSpacing = newtable()
    GroupSpacing.Horizontal = horizontalSpacing or 0
    GroupSpacing.Vertical = verticalSpacing or 0

    sorted = run:RunAttribute("SpaceGroups", "Groups", "GroupSpacing") or sorted

    local offsetX, offsetY = run:RunAttribute("UngroupedOffset", containerVariable, "GroupSpacing")

    UngroupedChildren = newtable()
    UngroupedFrames = newtable()

    if container.Frame and container.Frame.GetChildList then
        container.Frame:GetChildList(UngroupedChildren)
    end

    if not run:RunAttribute("ExtractUnitFrames", "UngroupedChildren", "UngroupedFrames", container.VisibleOnly) then
        UngroupedChildren = nil
        UngroupedFrames = nil
        GroupSpacing = nil
        Groups = nil
        return false
    end

    UngroupedContainer = newtable()
    run:RunAttribute("CopyTable", containerVariable, "UngroupedContainer")

    UngroupedContainer.Offset = newtable()
    UngroupedContainer.Offset.X = offsetX
    UngroupedContainer.Offset.Y = offsetY

    sorted = run:RunAttribute("HardArrange", "UngroupedFrames", "UngroupedContainer", "GroupSpacing", blockHeight) or sorted

    UngroupedContainer = nil
    UngroupedChildren = nil
    UngroupedFrames = nil
    GroupSpacing = nil
    Groups = nil

    return sorted
]]

-- attempts to sort the frames within the container
secureMethods["TrySortContainer"] = [=[
    local run = control or self
    local friendlyEnabled = self:GetAttribute("FriendlySortEnabled")
    local enemyEnabled = self:GetAttribute("EnemySortEnabled")
    local friendlyPlayerMode = self:GetAttribute("FriendlyPlayerSortMode")
    local friendlyGroupMode = self:GetAttribute("FriendlyGroupSortMode")
    local enemyGroupMode = self:GetAttribute("EnemyGroupSortMode")

    local containerVariable, providerVariable, destinationFramesVariable = ...
    if not containerVariable or not providerVariable then
        run:CallMethod("Log", format(
            "TrySortContainer was passed a nil parameter, containerVariable: %s, providerVariable: %s.",
            containerVariable or "nil", providerVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local container = _G[containerVariable]
    local provider = _G[providerVariable]

    if not container or not container.Frame or not provider then
        run:CallMethod("Log", format(
            "TrySortContainer was passed a nil value, containerVariable: %s, providerVariable: %s.",
            containerVariable or "nil", providerVariable or "nil"
        ), LogLevel.Bug)
        return false
    end

    local units = nil
    local sortMode = nil
    local playerSortMode = nil

    if container.LayoutType == LayoutType.NameList then
        -- there's no way to get a unit's name in the restricted environment
        -- so we can't do anything
        return false
    end

    if container.Type == ContainerType.Party or container.Type == ContainerType.Raid then
        units = FriendlyUnits
        sortMode = friendlyGroupMode
        playerSortMode = friendlyPlayerMode
    elseif container.Type == ContainerType.EnemyArena then
        units = EnemyUnits
        sortMode = enemyGroupMode
    else
        run:CallMethod("Log", format("Invalid container type: %s", container.Type or "nil"), LogLevel.Error)
        return false
    end

    Children = newtable()
    Frames = newtable()

    if container.Frames then
        Frames = container.Frames
    else
        container.Frame:GetChildList(Children)

        if not run:RunAttribute("ExtractUnitFrames", "Children", "Frames", container.VisibleOnly) then
            Children, Frames = nil, nil
            return false
        end
    end

    if not Frames or #Frames <= 1 then
        if destinationFramesVariable then
            _G[destinationFramesVariable] = Frames
        end
        -- nothing to do
        Children, Frames = nil, nil
        return false
    end

    Units = units or newtable()

    -- sort the frames to the desired locations
    SortedFrames = nil
    local couldSort = run:RunAttribute("SortFramesByUnits", "Frames", "Units", "SortedFrames")
    local warnedAlready = self:GetAttribute("WarnedAboutUnsorted")

    if not couldSort then
        run:RunAttribute("Sort", "Frames", "CompareFrameGroup", playerSortMode)
        SortedFrames = Frames

        if sortMode ~= "Group" and not warnedAlready then
            run:CallMethod("Log",
                "Sorry, we were unable to sort your frames accurately during combat by '" .. (sortMode or "nil").. "' and there is nothing we can do about it due to Blizzard API restrictions. " ..
                "We've temporarily sorted by group until combat drops.", LogLevel.Critical)

            self:SetAttribute("WarnedAboutUnsorted", true)
        end
    end

    local sorted = false

    if (container.SpacingHorizontal and container.SpacingHorizontal ~= 0) or (container.SpacingVertical and container.SpacingVertical ~= 0) then
        Spacing = newtable()
        Spacing.Horizontal = container.SpacingHorizontal or 0
        Spacing.Vertical = container.SpacingVertical or 0
    elseif container.SupportsSpacing then
        local horizontalSpacing, verticalSpacing = run:RunAttribute("SpacingForContainer", container.Type)

        if (horizontalSpacing and horizontalSpacing ~= 0) or (verticalSpacing and verticalSpacing ~= 0) then
            Spacing = newtable()
            Spacing.Horizontal = horizontalSpacing
            Spacing.Vertical = verticalSpacing
        end
    end

    if container.LayoutType == LayoutType.Hard then
        sorted = run:RunAttribute("HardArrange", "SortedFrames", containerVariable, Spacing and "Spacing")
    elseif container.LayoutType == LayoutType.Soft then
        sorted = run:RunAttribute("SoftArrange", "SortedFrames", Spacing and "Spacing")
    end

    if destinationFramesVariable then
        _G[destinationFramesVariable] = SortedFrames
    end

    SortedFrames = nil
    Children = nil
    Frames = nil
    Spacing = nil

    return sorted
]=]

-- top level perform sort routine
secureMethods["TrySort"] = [[
    local run = control or self

    if not run:RunAttribute("InCombat") then return false end

    local friendlyEnabled = self:GetAttribute("FriendlySortEnabled")
    local enemyEnabled = self:GetAttribute("EnemySortEnabled")

    if not friendlyEnabled and not enemyEnabled then return false end

    run:CallMethod("Log", "--- Starting in-combat run. ---", LogLevel.Debug)
    run:CallMethod("StartTimer", "SecureRun")

    local loadedUnits = self:GetAttribute("LoadedUnits")
    if not loadedUnits then
        run:RunAttribute("LoadUnits")
        self:SetAttribute("LoadedUnits", true)
    end

    if not Providers then
        run:CallMethod("Log", "TrySort: Providers was nil (Init not run?).", LogLevel.Bug)
        return false
    end

    local toSort = newtable()

    for _, provider in pairs(Providers) do
        if provider and provider.Name then
            local providerEnabled = self:GetAttribute("Provider" .. provider.Name .. "Enabled")

            if providerEnabled then
                local containers = provider.Containers
                if not containers then
                    run:CallMethod("Log", format("Provider %s had nil Containers.", provider.Name), LogLevel.Bug)
                else
                    for _, container in ipairs(containers) do
                        if container and container.Frame then
                            if not container.Frame:IsProtected() then
                                run:CallMethod("Log", format("Container for %s must be protected.", provider.Name), LogLevel.Error)
                            elseif container.Frame:IsVisible() then
                                local shouldAdd = false

                                if container.EnableInBattlegrounds ~= nil and not container.EnableInBattlegrounds and self:GetAttribute("IsBattleground") then
                                    shouldAdd = false
                                elseif (container.Type == ContainerType.Party or container.Type == ContainerType.Raid) and friendlyEnabled then
                                    shouldAdd = true
                                elseif container.Type == ContainerType.EnemyArena and enemyEnabled then
                                    shouldAdd = true
                                end

                                if shouldAdd then
                                    local add = newtable()
                                    add.Provider = provider
                                    add.Container = container
                                    toSort[#toSort + 1] = add
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local sorted = false

    for _, item in ipairs(toSort) do
        Container = item.Container
        Provider = item.Provider

        run:CallMethod("StartTimer", "TrySortContainer")

        local providerSorted = false

        if Container and Container.IsGrouped then
            providerSorted = run:RunAttribute("TrySortContainerGroups", "Container", "Provider") or providerSorted
        else
            providerSorted = run:RunAttribute("TrySortContainer", "Container", "Provider") or providerSorted
        end

        local message = format("In-combat sort for %s took %sms, result: %s.", Provider and Provider.Name or "nil", "%f", providerSorted and "sorted" or "not sorted")
        run:CallMethod("StopTimer", "TrySortContainer", message)
        Provider = nil
        Container = nil

        sorted = sorted or providerSorted
    end

    if sorted then
        run:CallMethod("NotifySorted")
    end

    run:CallMethod("StopTimer", "SecureRun", "Combat run time took %fms.")
    run:CallMethod("Log", "--- Finished in-combat run. ---", LogLevel.Debug)

    return sorted
]]

secureMethods["LoadProvider"] = [[
    local run = control or self
    local name = self:GetAttribute("ProviderName")

    if not name then
        run:CallMethod("Log", "LoadProvider: ProviderName was nil.", LogLevel.Bug)
        return
    end

    Providers = Providers or newtable()

    local provider = Providers[name]
    if not provider then
        provider = newtable()
        provider.Name = name
        Providers[name] = provider
    end

    provider.Containers = newtable()

    local containersCount = self:GetAttribute(name .. "ContainersCount") or 0
    if containersCount <= 0 then
        return
    end

    for i = 1, containersCount do
        local prefix = name .. "Container" .. i
        local container = newtable()

        container.Frame = self:GetFrameRef(prefix .. "Frame")
        container.Type = self:GetAttribute(prefix .. "Type")
        container.LayoutType = self:GetAttribute(prefix .. "LayoutType")
        container.SupportsSpacing = self:GetAttribute(prefix .. "SupportsSpacing")
        container.SpacingVertical = self:GetAttribute(prefix .. "SpacingVertical")
        container.SpacingHorizontal = self:GetAttribute(prefix .. "SpacingHorizontal")
        container.VisibleOnly = self:GetAttribute(prefix .. "VisibleOnly")
        container.AnchorPoint = self:GetAttribute(prefix .. "AnchorPoint")
        container.Anchor = self:GetAttribute(prefix .. "Anchor")
        container.IsGrouped = self:GetAttribute(prefix .. "IsGrouped")
        container.IsHorizontalLayout = self:GetAttribute(prefix .. "IsHorizontalLayout")
        container.FramesPerLine = self:GetAttribute(prefix .. "FramesPerLine")
        container.EnableInBattlegrounds = self:GetAttribute(prefix .. "EnableInBattlegrounds")

        if not container.Frame then
            run:CallMethod("Log", format("LoadProvider: missing FrameRef for %s.", prefix), LogLevel.Bug)
        end

        local offsetX = self:GetAttribute(prefix .. "OffsetX")
        local offsetY = self:GetAttribute(prefix .. "OffsetY")
        if offsetX or offsetY then
            container.Offset = newtable()
            container.Offset.X = offsetX or 0
            container.Offset.Y = offsetY or 0
        end

        local groupOffsetX = self:GetAttribute(prefix .. "GroupOffsetX")
        local groupOffsetY = self:GetAttribute(prefix .. "GroupOffsetY")
        if groupOffsetX or groupOffsetY then
            container.GroupOffset = newtable()
            container.GroupOffset.X = groupOffsetX or 0
            container.GroupOffset.Y = groupOffsetY or 0
        end

        local framesCount = self:GetAttribute(prefix .. "FramesCount")
        if framesCount and framesCount > 0 then
            local frames = newtable()
            for j = 1, framesCount do
                local frame = self:GetFrameRef(prefix .. "Frame" .. j)
                if frame then
                    frames[#frames + 1] = frame
                end
            end
            container.Frames = frames
        end

        provider.Containers[#provider.Containers + 1] = container
    end
]]

secureMethods["LoadUnits"] = [[
    local run = control or self

    FriendlyUnits = newtable()
    EnemyUnits = newtable()

    local friendlyUnitsCount = self:GetAttribute("FriendlyUnitsCount") or 0
    local enemyUnitsCount = self:GetAttribute("EnemyUnitsCount") or 0

    if friendlyUnitsCount < 0 then friendlyUnitsCount = 0 end
    if enemyUnitsCount < 0 then enemyUnitsCount = 0 end

    for i = 1, friendlyUnitsCount do
        local unit = self:GetAttribute("FriendlyUnit" .. i)
        if unit then
            FriendlyUnits[#FriendlyUnits + 1] = unit
        end
    end

    for i = 1, enemyUnitsCount do
        local unit = self:GetAttribute("EnemyUnit" .. i)
        if unit then
            EnemyUnits[#EnemyUnits + 1] = unit
        end
    end
]]

secureMethods["Init"] = [[
    Providers = newtable()

    -- Must match Comparer.DecimalSanity for consistency
    DecimalSanity = 0

    -- must match the enums specified in Frame.lua
    ContainerType = newtable()
    ContainerType.Party = 1
    ContainerType.Raid = 2
    ContainerType.EnemyArena = 3

    LayoutType = newtable()
    LayoutType.Soft = 1
    LayoutType.Hard = 2
    LayoutType.NameList = 3

    LogLevel = newtable()
    LogLevel.Debug = 1
    LogLevel.Notify = 2
    LogLevel.Warning = 3
    LogLevel.Error = 4
    LogLevel.Critical = 5
    LogLevel.Bug = 6
]]

local function ResetWarnings()
    assert(manager)

    manager:SetAttributeNoHandler("WarnedAboutUnsorted", false)
end

local function LoadUnits()
    assert(manager)

    local friendlyUnits = fsSortedUnits:FriendlyUnits()
    local enemyUnits = fsSortedUnits:ArenaUnits()

    for i, unit in ipairs(friendlyUnits) do
        manager:SetAttributeNoHandler("FriendlyUnit" .. i, unit)
    end

    for i, unit in ipairs(enemyUnits) do
        manager:SetAttributeNoHandler("EnemyUnit" .. i, unit)
    end

    manager:SetAttributeNoHandler("FriendlyUnitsCount", #friendlyUnits)
    manager:SetAttributeNoHandler("EnemyUnitsCount", #enemyUnits)

    -- flag that the units need to be reloaded
    manager:SetAttributeNoHandler("LoadedUnits", false)

    fsLog:Debug("Loaded %d friendly and %d enemy units to the restricted environment.", #friendlyUnits, #enemyUnits)
end

local function LoadSortMode()
    assert(manager)

    local friendlyEnabled, friendlyPlayerMode, friendlyGroupMode = fsCompare:FriendlySortMode()
    local enemyEnabled, enemyGroupMode = fsCompare:EnemySortMode()

    manager:SetAttributeNoHandler("FriendlySortEnabled", friendlyEnabled)
    manager:SetAttributeNoHandler("FriendlyPlayerSortMode", friendlyPlayerMode)
    manager:SetAttributeNoHandler("FriendlyGroupSortMode", friendlyGroupMode)

    manager:SetAttributeNoHandler("EnemySortEnabled", enemyEnabled)
    manager:SetAttributeNoHandler("EnemyGroupSortMode", enemyGroupMode)

    for _, provider in ipairs(fsProviders.All) do
        manager:SetAttributeNoHandler("Provider" .. provider:Name() .. "Enabled", provider:Enabled())
    end
end

local function LoadSpacing()
    assert(manager)

    for type, value in pairs(addon.DB.Options.Spacing) do
        manager:SetAttributeNoHandler(type .. "SpacingHorizontal", value.Horizontal)
        manager:SetAttributeNoHandler(type .. "SpacingVertical", value.Vertical)
    end
end

---@param provider FrameProvider
local function LoadProvider(provider)
    assert(manager)

    local containers = fsEnumerable
        :From(provider:Containers())
        :Where(function(c)
            return c.InCombatSortingRequired
        end)
        :ToTable()

    if #containers == 0 then
        return
    end

    manager:SetAttributeNoHandler("ProviderName", provider:Name())

    for i, container in ipairs(containers) do
        local offset = container.FramesOffset and container:FramesOffset()
        local groupOffset = container.GroupFramesOffset and container:GroupFramesOffset()
        local containerPrefix = provider:Name() .. "Container" .. i

        manager:SetFrameRef(containerPrefix .. "Frame", container.Frame)
        manager:SetAttributeNoHandler(containerPrefix .. "Type", container.Type)
        manager:SetAttributeNoHandler(containerPrefix .. "LayoutType", container.LayoutType)
        manager:SetAttributeNoHandler(containerPrefix .. "IsHorizontalLayout", container.IsHorizontalLayout and container:IsHorizontalLayout())
        manager:SetAttributeNoHandler(containerPrefix .. "FramesPerLine", container.FramesPerLine and container:FramesPerLine())
        manager:SetAttributeNoHandler(containerPrefix .. "VisibleOnly", container.VisibleOnly or false)
        manager:SetAttributeNoHandler(containerPrefix .. "AnchorPoint", container.AnchorPoint)
        manager:SetAttributeNoHandler(containerPrefix .. "Anchor", container.Anchor)
        manager:SetAttributeNoHandler(containerPrefix .. "SupportsSpacing", container.SupportsSpacing)
        manager:SetAttributeNoHandler(containerPrefix .. "IsGrouped", container.IsGrouped and container:IsGrouped())
        manager:SetAttributeNoHandler(containerPrefix .. "OffsetX", offset and offset.X)
        manager:SetAttributeNoHandler(containerPrefix .. "OffsetY", offset and offset.Y)
        manager:SetAttributeNoHandler(containerPrefix .. "GroupOffsetX", groupOffset and groupOffset.X)
        manager:SetAttributeNoHandler(containerPrefix .. "GroupOffsetY", groupOffset and groupOffset.Y)
        manager:SetAttributeNoHandler(containerPrefix .. "EnableInBattlegrounds", container.EnableInBattlegrounds)

        local spacing = container.Spacing and container:Spacing()
        manager:SetAttributeNoHandler(containerPrefix .. "SpacingHorizontal", spacing and spacing.Horizontal)
        manager:SetAttributeNoHandler(containerPrefix .. "SpacingVertical", spacing and spacing.Vertical)

        if container.Frames then
            local frames = container:Frames()
            manager:SetAttributeNoHandler(containerPrefix .. "FramesCount", #frames)

            for j, frame in ipairs(frames) do
                manager:SetFrameRef(containerPrefix .. "Frame" .. j, frame)
            end
        end
    end

    manager:SetAttributeNoHandler(provider:Name() .. "ContainersCount", #containers)
    manager:Execute([[
        local run = control or self
        run:RunAttribute("LoadProvider")
    ]])

    for _, item in ipairs(containers) do
        -- flag as imported
        -- SetAttributeNoHandler may not exist on frames we didn't create
        -- doesn't exist in wow 3.3.5
        item.Frame:SetAttribute("FrameSortLoaded", true)
    end
end

local function InjectSecureHelpers(secureFrame)
    if not secureFrame.Execute then
        function secureFrame:Execute(body)
            return wow.SecureHandlerExecute(self, body)
        end
    end

    if not secureFrame.WrapScript then
        function secureFrame:WrapScript(frame, script, preBody, postBody)
            return wow.SecureHandlerWrapScript(frame, script, self, preBody, postBody)
        end
    end

    if not secureFrame.SetFrameRef then
        function secureFrame:SetFrameRef(label, refFrame)
            return wow.SecureHandlerSetFrameRef(self, label, refFrame)
        end
    end
end

-- TODO: I don't think this should make a difference anymore, but re-adding it for testing.
local function ResubscribeEvents()
    -- we want our sorting code to run after blizzard and other frame addons refresh their frames
    -- i.e., we want to handle GROUP_ROSTER_UPDATE/UNT_PET after frame addons have performed their update handling
    -- this is easily achieved in the insecure environment by using hooks, however in the restricted environment we have no such luxury
    -- fortunately it seems blizzard invoke event handlers roughly in the order that they were registered
    -- so if we register our events later, our code will run later
    -- of course it's not good to rely on this and we should generally treat event ordering as undefined
    -- perhaps in a future patch this implementation detail could change and our code will break
    -- however until a better solution can be found, this is our only hope

    assert(memberHeader ~= nil)
    assert(petHeader ~= nil)

    memberHeader:UnregisterEvent(events.GROUP_ROSTER_UPDATE)
    memberHeader:UnregisterEvent(events.UNIT_NAME_UPDATE)

    memberHeader:RegisterEvent(events.GROUP_ROSTER_UPDATE)
    memberHeader:RegisterEvent(events.UNIT_NAME_UPDATE)

    petHeader:UnregisterEvent(events.GROUP_ROSTER_UPDATE)
    petHeader:UnregisterEvent(events.UNIT_PET)
    petHeader:UnregisterEvent(events.UNIT_NAME_UPDATE)

    petHeader:RegisterEvent(events.GROUP_ROSTER_UPDATE)
    petHeader:RegisterEvent(events.UNIT_PET)
    petHeader:RegisterEvent(events.UNIT_NAME_UPDATE)
end

---@param container FrameContainer
local function WatchChildrenVisibility(container)
    assert(manager)

    local children = fsFrame:ExtractUnitFrames(container.Frame, false, false, false)

    for _, child in ipairs(children) do
        if not child:GetAttribute("framesort-watching-visibility") then
            wow.SecureHandlerSetFrameRef(child, "Manager", manager)

            -- not sure why, but postBody scripts don't work for OnShow/OnHide
            wow.SecureHandlerWrapScript(
                child,
                "OnShow",
                manager,
                [[
                    local manager = control
                    manager:SetAttribute("state-framesort-run", "ignore")
                ]]
            )
            wow.SecureHandlerWrapScript(
                child,
                "OnHide",
                manager,
                [[
                    local manager = control
                    manager:SetAttribute("state-framesort-run", "ignore")
                ]]
            )

            child:SetAttribute("framesort-watching-visibility", true)
        end
    end
end

local function WatchVisibility()
    local containersToSubscribe = fsEnumerable
        :From(fsProviders.All)
        :Map(function(provider)
            return provider:Containers()
        end)
        :Flatten()
        :Where(function(container)
            return container.SubscribeToVisibility
        end)
        :ToTable()

    for _, container in ipairs(containersToSubscribe) do
        WatchChildrenVisibility(container)
    end
end

local function LoadInstanceType()
    assert(manager)

    manager:SetAttributeNoHandler("IsBattleground", wowEx.IsInstanceBattleground())
end

local function OnCombatStarting()
    LoadSortMode()
    LoadUnits()
    ResubscribeEvents()
    WatchVisibility()
    LoadInstanceType()
    ResetWarnings()
end

local function OnProviderContainersChanged(provider)
    fsScheduler:RunWhenCombatEnds(function()
        LoadProvider(provider)
    end, "LoadProvider" .. provider:Name())
end

local function OnConfigChanged()
    fsScheduler:RunWhenCombatEnds(function()
        LoadSpacing()
    end, "SecureSortConfigChanged")
end

local function ConfigureHeader(header)
    InjectSecureHelpers(header)

    function header:UnitButtonCreated(id)
        if not id then
            fsLog:Bug("UnitButtonCreated called without an id.")
            return
        end

        local frame
        for _, child in ipairs({ header:GetChildren() }) do
            if child and child.GetID and child:GetID() == id then
                frame = child
                break
            end
        end

        if not frame then
            fsLog:Bug("Failed to find unit button %s.", id)
            return
        end

        fsScheduler:RunWhenCombatEnds(function()
            -- the refreshUnitChange script doesn't capture when the unit is changed to nil
            -- which can happen when someone leaves the group, or a pet ceases to exist
            -- so we're really only interested in unit changing to nil here
            frame:SetAttribute(
                "_onattributechanged",
                [[
                local manager = self:GetAttribute("Manager")
                manager:SetAttribute("state-framesort-run", "ignore")
                ]]
            )

            frame:SetAttribute("HaveSetAttributeHandler", true)
        end)
    end

    -- show as much as possible
    header:SetAttribute("showRaid", true)
    header:SetAttribute("showParty", true)
    header:SetAttribute("showPlayer", true)
    header:SetAttribute("showSolo", true)

    -- unit buttons template type
    header:SetAttribute("template", "SecureHandlerAttributeTemplate")

    -- fired when a new unit button is created
    header:SetAttribute(
        "initialConfigFunction",
        [=[
        UnitButtonsCount = (UnitButtonsCount or 0) + 1

        -- self = the newly created unit button
        self:SetWidth(0)
        self:SetHeight(0)
        self:SetID(UnitButtonsCount)
        self:SetAttribute("Manager", Manager)
        self:SetAttribute("Header", Header)

        RefreshUnitChange = [[
            -- Blizzard iterate over all the unit buttons and change their unit token so this snippet is called a lot
            -- we want to avoid spamming multiple sort attempts and only perform after all the buttons have been updated
            -- we can do this by changing our attribute to some temporary value which blizzard will change back when it re-evaluates state attributes
            local manager = self:GetAttribute("Manager")
            manager:SetAttribute("state-framesort-run", "ignore")
        ]]

        self:SetAttribute("refreshUnitChange", RefreshUnitChange)

        Header:CallMethod("UnitButtonCreated", UnitButtonsCount)
    ]=]
    )

    header:SetFrameRef("Manager", manager)

    header:Execute([[
        Header = self
        Manager = self:GetFrameRef("Manager")
    ]])

    -- must be shown for it to work
    header:SetPoint("TOPLEFT", wow.UIParent, "TOPLEFT")
    header:Show()
end

function M:RunOverheadTest()
    if wow.InCombatLockdown() or not manager then
        return
    end

    manager:Execute([[
        local run = control or self

        run:RunAttribute("OverheadTest")
    ]])
end

function M:Init()
    if manager then
        return
    end

    manager = wow.CreateFrame("Frame", nil, wow.UIParent, "SecureHandlerStateTemplate")

    InjectSecureHelpers(manager)

    function manager.StartTimer(_, name)
        if not name then
            fsLog:Bug("StartTimer called without a name.")
            return
        end

        manager[name .. "TimeStart"] = wow.GetTimePreciseSec()
    end

    function manager.StopTimer(_, name, message)
        local start = manager[name .. "TimeStart"]

        if not start then
            fsLog:Bug("StopTimer called without corresponding StartTimer for %s.", name)
            return
        end

        local stop = wow.GetTimePreciseSec()
        local ms = (stop - start) * 1000

        fsLog:Debug(message, ms)

        manager[name .. "TimeStart"] = nil
    end

    function manager.NotifySorted()
        fsSorting:NotifySorted()
    end

    function manager.Log(_, msg, level)
        fsLog:Log(msg, level)
    end

    for name, snippet in pairs(secureMethods) do
        manager:SetAttributeNoHandler(name, snippet)
    end

    manager:Execute([[
        -- wotlk 3.3.5 doesn't have the control methods on self
        -- those methods exist on the "control" global
        local run = control or self

        run:RunAttribute("Init")
    ]])

    manager:SetAttribute(
        "_onstate-framesort-run",
        [[
        if newstate == "ignore" then return end

        local run = control or self
        run:RunAttribute("TrySort")
        ]]
    )

    -- https://www.wowinterface.com/forums/showthread.php?t=58697
    -- this attribute driver is used for delaying the sorting function
    -- the actual conditional value doesn't really matter
    -- we'll change the value of this to "ignore" from group header events
    -- and then blizzard will later detect the value has changed from "pet" or "nopet" and invoke our attribute changed handler
    wow.RegisterAttributeDriver(manager, "state-framesort-run", "[pet] pet; nopet;")

    memberHeader = wow.CreateFrame("Frame", nil, wow.UIParent, "SecureGroupHeaderTemplate")
    petHeader = wow.CreateFrame("Frame", nil, wow.UIParent, "SecureGroupPetHeaderTemplate")

    headers = { memberHeader, petHeader }

    for _, header in ipairs(headers) do
        ConfigureHeader(header)
    end

    for _, provider in ipairs(fsProviders.All) do
        provider:RegisterContainersChangedCallback(OnProviderContainersChanged)
    end

    -- wait until the providers have created their frames
    fsScheduler:RunWhenEnteringWorldOnce(function()
        for _, provider in ipairs(fsProviders:EnabledNotSelfManaged()) do
            LoadProvider(provider)
        end
    end)

    LoadSortMode()
    LoadSpacing()

    fsConfig:RegisterConfigurationChangedCallback(OnConfigChanged)

    local combatStartingFrame = wow.CreateFrame("Frame", nil, wow.UIParent)
    combatStartingFrame:SetScript("OnEvent", OnCombatStarting)
    combatStartingFrame:RegisterEvent(events.PLAYER_REGEN_DISABLED)
end
