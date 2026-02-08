---@type string, Addon
local _, addon = ...
local fsProviders = addon.Providers
local fsCompare = addon.Modules.Sorting.Comparer
local fsFrame = addon.WoW.Frame
local fsUnit = addon.WoW.Unit
local fsSortedUnits = addon.Modules.Sorting.SortedUnits
local fsEnumerable = addon.Collections.Enumerable
local fsMath = addon.Numerics.Math
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local M = {}
addon.Modules.Sorting.Secure.NoCombat = M

local function SafeAdjustPointsOffset(frame, xDelta, yDelta)
    xDelta = xDelta or 0
    yDelta = yDelta or 0

    if not frame or (xDelta == 0 and yDelta == 0) then
        return false
    end

    if fsFrame:IsForbidden(frame) then
        return false
    end

    if not frame.AdjustPointsOffset then
        return false
    end

    frame:AdjustPointsOffset(xDelta, yDelta)
    return true
end

local function FrameSortKey(frame, unitsToIndex)
    -- not sure why sometimes we get null arguments here, but it does happen on very rare occasions
    -- https://github.com/Verubato/framesort/issues/33
    if not frame then
        return 1e9, nil
    end

    if fsFrame:IsForbidden(frame) then
        return 1e9 - 1, nil
    end

    local unit = fsFrame:GetFrameUnit(frame)

    if not unit then
        return 1e9 - 2, nil
    end

    local idx = unitsToIndex[unit]

    if idx == nil then
        return 1e9 - 3, unit
    end

    return idx, unit
end

--- Sorts frames in-place by matching their units to the sorted units list.
--- @param frames table[] Array of frames to sort (modified in-place)
--- @param sortedUnits string[] Ordered list of unit tokens
--- @return nil
local function SortFramesByUnits(frames, sortedUnits)
    local unitsToIndex = {}
    for index, unit in ipairs(sortedUnits) do
        local normalised = fsUnit:NormaliseUnit(unit) or unit
        unitsToIndex[normalised] = index
    end

    table.sort(frames, function(leftFrame, rightFrame)
        local leftKey, leftUnit = FrameSortKey(leftFrame, unitsToIndex)
        local rightKey, rightUnit = FrameSortKey(rightFrame, unitsToIndex)

        if leftKey ~= rightKey then
            return leftKey < rightKey
        end

        -- if one of the unit exists, prefer it
        if leftUnit ~= nil and rightUnit == nil then
            return true
        elseif leftUnit == nil and rightUnit ~= nil then
            return false
        end

        -- if both exist, sort by alphabetical
        if leftUnit and rightUnit and leftUnit ~= rightUnit then
            return leftUnit < rightUnit
        end

        -- if both frames exist and are safe, use visibility + name as further tie-breakers
        if leftFrame and rightFrame and not fsFrame:IsForbidden(leftFrame) and not fsFrame:IsForbidden(rightFrame) then
            if leftFrame.IsVisible and rightFrame.IsVisible then
                local lv, rv = leftFrame:IsVisible(), rightFrame:IsVisible()
                if lv ~= rv then
                    return lv and not rv
                end
            end

            if leftFrame.GetName and rightFrame.GetName then
                local ln, rn = leftFrame:GetName(), rightFrame:GetName()
                if ln and rn and ln ~= rn then
                    return ln < rn
                end
            end
        end

        -- final deterministic fallback
        return tostring(leftFrame) < tostring(rightFrame)
    end)
end

---@return boolean sorted
---@return number countMoved
---@param frames table[]
---@param points table<table, Point>
local function Move(frames, points)
    local framesToMove = {}

    local function round(v)
        return fsMath:Round(v or 0, fsCompare.DecimalSanity)
    end

    for _, frame in ipairs(frames) do
        local to = frame and points[frame]

        if to and frame.GetPoint and frame.GetNumPoints and frame.ClearAllPoints and frame.SetPoint then
            local different = frame:GetNumPoints() ~= 1

            if not different then
                local point, relativeTo, relativePoint, xOffset, yOffset = frame:GetPoint(1)
                different = point ~= to.Point
                    or relativeTo ~= to.RelativeTo
                    or relativePoint ~= to.RelativePoint
                    -- don't move frames if they are have minuscule position differences
                    -- it's just a rounding error and makes no visual impact
                    -- this helps preventing spam on our callbacks
                    or round(xOffset) ~= round(to.XOffset)
                    or round(yOffset) ~= round(to.YOffset)
            end

            if different then
                framesToMove[#framesToMove + 1] = frame
            end
        end
    end

    local moved = #framesToMove

    if moved == 0 then
        return false, 0
    end

    for _, frame in ipairs(framesToMove) do
        local to = points[frame]

        if to then
            frame:ClearAllPoints()
            frame:SetPoint(to.Point, to.RelativeTo, to.RelativePoint, to.XOffset or 0, to.YOffset or 0)
        end
    end

    return moved > 0, moved
end

---Applies spacing on a set of points (slots) in-place.
---@param points table[]
---@param spacing Spacing
local function ApplySpacing(points, spacing)
    if not points or #points <= 1 or not spacing then
        return
    end

    local horizontalSpacing = spacing.Horizontal or 0
    local verticalSpacing = spacing.Vertical or 0
    local sanity = fsCompare.DecimalSanity or 0

    -- Snapshot coords for stable row/column grouping + stable sorting
    for i = 1, #points do
        local p = points[i]
        p.OriginalLeft = p.Left
        p.OriginalTop = p.Top
    end

    local function Round(n)
        return fsMath:Round(n or 0, sanity)
    end

    -- Pass 1: horizontal spacing within a row (sort by OriginalTop desc, OriginalLeft asc)
    table.sort(points, function(a, b)
        local aTop, bTop = Round(a.OriginalTop), Round(b.OriginalTop)

        if aTop ~= bTop then
            return aTop > bTop
        end

        return Round(a.OriginalLeft) < Round(b.OriginalLeft)
    end)

    for i = 2, #points do
        local p = points[i]
        local prev = points[i - 1]

        local sameRow = Round(p.OriginalTop) == Round(prev.OriginalTop)
        if sameRow then
            local prevRight = prev.Left + (prev.Width or 0)
            local existingSpace = p.Left - prevRight
            local xDelta = horizontalSpacing - existingSpace

            if xDelta ~= 0 then
                p.Left = p.Left + xDelta
            end
        end
    end

    -- Pass 2: vertical spacing within a column (sort by OriginalLeft asc, OriginalTop desc)
    table.sort(points, function(a, b)
        local aLeft, bLeft = Round(a.OriginalLeft), Round(b.OriginalLeft)

        if aLeft ~= bLeft then
            return aLeft < bLeft
        end

        return Round(a.OriginalTop) > Round(b.OriginalTop)
    end)

    for i = 2, #points do
        local p = points[i]
        local prev = points[i - 1]

        local sameColumn = Round(p.OriginalLeft) == Round(prev.OriginalLeft)
        if sameColumn then
            local prevBottom = prev.Top - (prev.Height or 0)
            local existingSpace = prevBottom - p.Top
            local yDelta = verticalSpacing - existingSpace

            if yDelta ~= 0 then
                p.Top = p.Top - yDelta
            end
        end
    end

    -- Cleanup snapshot fields
    for i = 1, #points do
        local p = points[i]
        p.OriginalLeft = nil
        p.OriginalTop = nil
    end
end

---Applies spacing to a set of groups that contain frames.
---@param groups table[]  -- group frames
---@param spacing Spacing
---@return boolean movedAny
local function SpaceGroups(groups, spacing)
    if not groups or #groups <= 1 or not spacing then
        return false
    end

    -- Build slots from groups with valid geometry
    local points = {}
    local validGroups = {}

    for _, group in ipairs(groups) do
        if group and group.GetRect then
            local left, bottom, width, height = group:GetRect()

            if left and bottom and width and height then
                points[#points + 1] = {
                    Left = left,
                    Top = bottom + height,
                    Width = width,
                    Height = height,
                }

                validGroups[#validGroups + 1] = group
            end
        end
    end

    if #points <= 1 then
        return false
    end

    -- Mutate slot coords in-place
    ApplySpacing(points, spacing)

    local destByGroup = {}
    for i = 1, #points do
        local point = points[i]
        local group = validGroups[i]

        destByGroup[group] = point
    end

    local movedAny = false

    for _, group in ipairs(validGroups) do
        local dest = group and destByGroup[group]

        if dest and group and group.GetLeft and group.GetTop then
            local left, top = group:GetLeft(), group:GetTop()

            if left ~= nil and top ~= nil then
                local xDelta = dest.Left - left
                local yDelta = dest.Top - top

                local xDeltaRounded = fsMath:Round(xDelta, fsCompare.DecimalSanity)
                local yDeltaRounded = fsMath:Round(yDelta, fsCompare.DecimalSanity)

                -- ignore noise in point differences
                if xDeltaRounded ~= 0 or yDeltaRounded ~= 0 then
                    movedAny = SafeAdjustPointsOffset(group, xDelta, yDelta) or movedAny
                end
            end
        end
    end

    return movedAny
end

---Rearranges frames by only modifying X/Y offsets (keeps anchors).
---@param frames table[]
---@param spacing Spacing? -- spacing object
---@return boolean movedAny
local function SoftArrange(frames, spacing)
    if not frames or #frames <= 1 then
        return false
    end

    local slots = {}
    local validFrames = {}

    for _, frame in ipairs(frames) do
        if frame and frame.GetRect then
            local left, bottom, width, height = frame:GetRect()

            if left and bottom and width and height then
                validFrames[#validFrames + 1] = frame
            end
        end
    end

    local orderedByTopLeft = fsEnumerable
        :From(validFrames)
        :OrderBy(function(a, b)
            return fsCompare:CompareTopLeftFuzzy(a, b)
        end)
        :ToTable()

    for _, frame in ipairs(orderedByTopLeft) do
        if frame and frame.GetRect then
            local left, bottom, width, height = frame:GetRect()

            if left and bottom and width and height then
                slots[#slots + 1] = {
                    Left = left,
                    Top = bottom + height,
                    Width = width,
                    Height = height,
                }
            end
        end
    end

    local slotsCount = #slots
    if slotsCount <= 1 then
        return false
    end

    if spacing then
        ApplySpacing(slots, spacing)
    end

    -- Enumerate in chain order if available (movement order)
    local enumerationOrder = frames
    local chain = fsFrame:ToFrameChain(frames)

    if chain.Valid then
        enumerationOrder = fsFrame:FramesFromChain(chain)
    end

    -- assign each frame a slot
    local destByFrame = {}

    for i = 1, slotsCount do
        local slot = slots[i]
        local frame = validFrames[i]

        destByFrame[frame] = slot
    end

    local movedAny = false

    for _, source in ipairs(enumerationOrder) do
        local dest = source and destByFrame[source]

        if dest and source and source.GetLeft and source.GetTop then
            local left, top = source:GetLeft(), source:GetTop()

            if left ~= nil and top ~= nil then
                local xDelta = dest.Left - left
                local yDelta = dest.Top - top

                local xDeltaRounded = fsMath:Round(xDelta, fsCompare.DecimalSanity)
                local yDeltaRounded = fsMath:Round(yDelta, fsCompare.DecimalSanity)

                if xDeltaRounded ~= 0 or yDeltaRounded ~= 0 then
                    movedAny = SafeAdjustPointsOffset(source, xDelta, yDelta) or movedAny
                end
            end
        end
    end

    return movedAny
end

local function FirstValidFrame(frames)
    for _, frame in ipairs(frames) do
        if frame and frame.GetHeight and frame.GetWidth then
            local height, width = frame:GetHeight(), frame:GetWidth()

            if height and height > 0 and width and width > 0 then
                return frame
            end
        end
    end

    return nil
end

---Rearranges frames by modifying their entire anchor point.
---@param container FrameContainer
---@param frames table[]
---@param spacing Spacing?
---@param offset Offset?
---@param blockHeight number?
---@return boolean sorted
local function HardArrange(container, frames, spacing, offset, blockHeight)
    if #frames == 0 then
        return false
    end

    local start = wow.GetTimePreciseSec()
    local relativeTo = container.Anchor or container.Frame

    if not relativeTo then
        fsLog:Error("HardArrange: missing anchor.")
        return false
    end

    local isHorizontalLayout = container.IsHorizontalLayout and container:IsHorizontalLayout() or false
    local blocksPerLine = type(container.FramesPerLine) == "function" and container:FramesPerLine()
    local anchorPoint = container.AnchorPoint or "TOPLEFT"

    if blocksPerLine and blocksPerLine <= 0 then
        blocksPerLine = nil
    end

    if not offset and type(container.FramesOffset) == "function" then
        offset = container:FramesOffset()
    end

    local firstValid = FirstValidFrame(frames)

    if not firstValid then
        fsLog:Error("HardArrange: no valid frames with size.")
        return false
    end

    -- the block size is the largest height and width combination
    -- this is only useful when we have frames of different sizes
    -- which is the case of pet frames, where 2 pet frames can fit into 1 player frame
    -- we could find max height/width, but this should almost certaintly be equal to the first frame in the array
    -- so save the cpu cycles and just use the first valid frame
    local blockWidth = firstValid:GetWidth()
    blockHeight = blockHeight or firstValid:GetHeight()

    offset = offset or {
        X = 0,
        Y = 0,
    }

    spacing = spacing or {
        Vertical = 0,
        Horizontal = 0,
    }

    ---@type table<table, Point>
    local pointsByFrame = {}
    local row, col = 0, 0
    local xOffset = offset.X
    local yOffset = offset.Y
    local currentBlockHeight = 0

    for _, frame in ipairs(frames) do
        local height = frame and frame.GetHeight and frame:GetHeight() or 0

        if height > 0 then
            local isNewBlock = currentBlockHeight > 0
                -- add/subtract 1 for a bit of breathing room for rounding errors
                and (currentBlockHeight >= (blockHeight - 1) or (currentBlockHeight + height) >= (blockHeight + 1))

            if isNewBlock then
                currentBlockHeight = 0

                if isHorizontalLayout then
                    col = col + 1
                else
                    row = row + 1
                end

                xOffset = col * (blockWidth + spacing.Horizontal) + offset.X
                yOffset = -row * (blockHeight + spacing.Vertical) + offset.Y
            end

            -- if we've reached the end then wrap around
            if isHorizontalLayout and blocksPerLine and col >= blocksPerLine then
                col = 0
                row = row + 1

                xOffset = offset.X
                yOffset = -row * (blockHeight + spacing.Vertical) + offset.Y
                currentBlockHeight = 0
            elseif not isHorizontalLayout and blocksPerLine and row >= blocksPerLine then
                row = 0
                col = col + 1

                yOffset = offset.Y
                xOffset = col * (blockWidth + spacing.Horizontal) + offset.X
                currentBlockHeight = 0
            end

            pointsByFrame[frame] = {
                Point = anchorPoint,
                RelativeTo = relativeTo,
                RelativePoint = anchorPoint,
                XOffset = xOffset,
                YOffset = yOffset,
            }

            currentBlockHeight = currentBlockHeight + height
            yOffset = yOffset - height
        else
            fsLog:Error("Skipping frame '%s' that has no height.", frame and frame.GetName and frame:GetName() or "nil")
        end
    end

    local moved, framesMoved = Move(frames, pointsByFrame)
    local stop = wow.GetTimePreciseSec()
    local containerName = (container.Frame and container.Frame.GetName and container.Frame:GetName()) or "nil"
    fsLog:Debug("Moving %d/%d frames for container %s took %fms.", framesMoved, #frames, containerName, (stop - start) * 1000)

    return moved
end

---@param container FrameContainer
---@return boolean
local function SetNameList(container)
    local isFriendly = container.Type == fsFrame.ContainerType.Party or container.Type == fsFrame.ContainerType.Raid
    local units = isFriendly and fsSortedUnits:FriendlyUnits() or fsSortedUnits:ArenaUnits()

    if isFriendly and #units == 0 then
        -- ensure player always exists for friendly units
        -- as they might be showing party frames even when not in a party in order to shown their own frame
        units = { "player" }
    end

    -- namelists don't like target units
    units = fsEnumerable
        :From(units)
        :Where(function(unit)
            return not fsUnit:IsRaidTarget(unit)
        end)
        :ToTable()

    if container.ShowUnit then
        units = fsEnumerable
            :From(units)
            :Where(function(unit)
                return container:ShowUnit(unit)
            end)
            :ToTable()
    end

    local previousSortMethod = container.Frame:GetAttribute("sortMethod")
    local previousGroupFilter = container.Frame:GetAttribute("groupFilter")

    container.Frame:SetAttribute("FrameSortHasSorted", true)
    container.Frame:SetAttribute("FrameSortPreviousSortMethod", previousSortMethod)
    container.Frame:SetAttribute("FrameSortPreviousGroupFilter", previousGroupFilter)

    -- groupFilter must be set to nil for nameList to be used
    container.Frame:SetAttribute("groupFilter", nil)
    container.Frame:SetAttribute("sortMethod", "NAMELIST")

    local unitNames = fsEnumerable
        :From(units)
        :Map(function(unit)
            return wow.GetUnitName(unit, true)
        end)
        :Where(function(name)
            return name and name ~= ""
        end)
        :Distinct()
        :ToTable()

    local names = table.concat(unitNames, ",")
    local existingNameList = container.Frame:GetAttribute("nameList")

    if existingNameList == names then
        return false
    end

    container.Frame:SetAttribute("nameList", names)
    return true
end

---Determines the offset to use for the ungrouped portion of the raid frames.
---@param container FrameContainer
---@return Offset
local function UngroupedOffset(container, spacing)
    local offset = {
        X = 0,
        Y = 0,
    }

    local groups = fsFrame:ExtractGroups(container.Frame) or {}
    local horizontal = container.IsHorizontalLayout and container:IsHorizontalLayout()

    spacing = spacing or {
        Horizontal = 0,
        Vertical = 0,
    }

    local lastGroup = fsEnumerable:From(groups):Reverse():First(function(x)
        return x:IsVisible()
    end)

    if not lastGroup then
        return offset
    end

    local frames = fsFrame:ExtractUnitFrames(lastGroup, true, container.VisibleOnly, container.ExistsOnly) or {}

    if #frames == 0 then
        return offset
    end

    if horizontal then
        local bottomLeftFrame = fsEnumerable
            :From(frames)
            :OrderBy(function(x, y)
                return fsCompare:CompareBottomLeftFuzzy(x, y)
            end)
            :First()

        if bottomLeftFrame then
            local containerTop = container.Frame:GetTop()
            local containerLeft = container.Frame:GetLeft()
            local bottom = bottomLeftFrame:GetBottom()
            local left = bottomLeftFrame:GetLeft()

            if containerTop and containerLeft and bottom and left then
                offset.Y = -(containerTop - bottom + spacing.Vertical)
                offset.X = -(containerLeft - left)
            end
        end
    else
        local topRightFrame = fsEnumerable
            :From(frames)
            :OrderBy(function(x, y)
                return fsCompare:CompareTopRightFuzzy(x, y)
            end)
            :First()

        if topRightFrame then
            local containerLeft = container.Frame:GetLeft()
            local containerTop = container.Frame:GetTop()
            local right = topRightFrame:GetRight()
            local top = topRightFrame:GetTop()

            if containerLeft and containerTop and right and top then
                offset.X = -(containerLeft - right - spacing.Horizontal)
                offset.Y = -(containerTop - top)
            end
        end
    end

    return offset
end

---@param container FrameContainer
---@return boolean sorted, table[] frames the sorted frames
local function TrySortContainer(container)
    if container.LayoutType == fsFrame.LayoutType.NameList then
        return SetNameList(container), {}
    end

    local frames = container.Frames and container:Frames()

    if not frames and container.Frame then
        frames = fsFrame:ExtractUnitFrames(container.Frame, true, container.VisibleOnly, container.ExistsOnly)
    end

    frames = frames or {}

    if #frames == 0 then
        local containerName = (container.Frame and container.Frame.GetName and container.Frame:GetName()) or "nil"
        fsLog:Debug("Container %s has no frames to sort.", containerName)
        return false, frames
    end

    if #frames <= 1 then
        return false, frames
    end

    -- important: don't use fsSortedUnits:FriendlyUnits() here as it contains a cached view
    -- and frames may have changed, so get the units from the actual frames we're sorting
    local units = {}
    for _, frame in ipairs(frames) do
        local unit = fsFrame:GetFrameUnit(frame)

        if unit then
            units[#units + 1] = unit
        end
    end

    local isFriendly
    if container.Type == fsFrame.ContainerType.Party or container.Type == fsFrame.ContainerType.Raid then
        isFriendly = true
    elseif container.Type == fsFrame.ContainerType.EnemyArena then
        isFriendly = false
    else
        fsLog:Bug("Unknown container type: %s.", container.Type or "nil")
        return false, frames
    end

    fsSortedUnits:Sort(units, isFriendly)

    SortFramesByUnits(frames, units)

    local spacing = nil

    if container.Spacing then
        spacing = container:Spacing()
    elseif container.SupportsSpacing then
        local config = addon.DB.Options.Spacing
        if container.Type == fsFrame.ContainerType.Party then
            spacing = config.Party
        elseif container.Type == fsFrame.ContainerType.Raid then
            spacing = config.Raid
        elseif container.Type == fsFrame.ContainerType.EnemyArena then
            spacing = config.EnemyArena
        end
    end

    local sorted

    if container.LayoutType == fsFrame.LayoutType.Soft then
        sorted = SoftArrange(frames, spacing)
    elseif container.LayoutType == fsFrame.LayoutType.Hard then
        sorted = HardArrange(container, frames, spacing)
    else
        fsLog:Bug("Unknown layout type: %s.", container.LayoutType or "nil")
        return false, frames
    end

    if sorted and container.PostSort then
        container:PostSort()
    end

    return sorted, frames
end

---@param container FrameContainer
---@return boolean
local function TrySortContainerGroups(container)
    local sorted = false
    local groups = fsFrame:ExtractGroups(container.Frame, container.VisibleOnly) or {}

    if #groups == 0 then
        return false
    end

    local isHorizontalLayout = container.IsHorizontalLayout and container:IsHorizontalLayout() or false
    local blockHeight = nil

    for _, group in ipairs(groups) do
        ---@type FrameContainer
        local groupContainer = {
            Frame = group,
            Type = container.Type,
            IsHorizontalLayout = function()
                return isHorizontalLayout
            end,
            VisibleOnly = container.VisibleOnly,
            LayoutType = container.LayoutType,
            SupportsSpacing = container.SupportsSpacing,
            FramesPerLine = container.FramesPerLine,
            -- we want to use the group frames offset here
            FramesOffset = container.GroupFramesOffset,
            IsGrouped = function()
                return false
            end,
        }

        local containerSorted, frames = TrySortContainer(groupContainer)

        -- calculate the block height of the player frames to use later for ungrouped frames
        if not blockHeight and frames and #frames > 0 then
            local firstValid = FirstValidFrame(frames)

            if firstValid then
                blockHeight = firstValid:GetHeight()
            end
        end

        sorted = sorted or containerSorted
    end

    if not container.SupportsSpacing then
        -- to avoid issues with main tank and assist frames don't move ungrouped frames if we don't need to
        return sorted
    end

    local spacing = nil
    local config = addon.DB.Options.Spacing

    if container.Type == fsFrame.ContainerType.Party then
        spacing = config.Party
    elseif container.Type == fsFrame.ContainerType.Raid then
        spacing = config.Raid
    elseif container.Type == fsFrame.ContainerType.EnemyArena then
        spacing = config.EnemyArena
    end

    if not spacing or (spacing.Horizontal == 0 and spacing.Vertical == 0) then
        return sorted
    end

    sorted = SpaceGroups(groups, spacing) or sorted

    -- ungrouped frames include pets, vehicles, and main tank/assist frames
    local ungroupedFrames = fsFrame:ExtractUnitFrames(container.Frame, true, container.VisibleOnly, container.ExistsOnly) or {}

    if #ungroupedFrames == 0 then
        return sorted
    end

    local ungroupedOffset = UngroupedOffset(container, spacing)

    sorted = HardArrange(container, ungroupedFrames, spacing, ungroupedOffset, blockHeight) or sorted

    return sorted
end

local function ClearSorting(providers, friendlyEnabled, enemyEnabled)
    ---@type FrameContainer
    local nameListContainers = fsEnumerable
        :From(providers)
        :Map(function(provider)
            return (provider.Containers and provider:Containers()) or {}
        end)
        :Flatten()
        :Where(function(container)
            if (container.Type == fsFrame.ContainerType.Party or container.Type == fsFrame.ContainerType.Raid) and friendlyEnabled then
                return false
            end

            if container.Type == fsFrame.ContainerType.EnemyArena and enemyEnabled then
                return false
            end

            -- after exiting an arena, elvui retains the nameList property
            -- so we want to clear it if they've disabled sorting in the world
            if container.LayoutType ~= fsFrame.LayoutType.NameList then
                return false
            end

            if not container.Frame then
                return false
            end

            local hasTouched = container.Frame:GetAttribute("FrameSortHasSorted") or false
            return hasTouched
        end)
        :ToTable()

    for _, container in ipairs(nameListContainers) do
        if container.Frame then
            local previousSortMethod = container.Frame:GetAttribute("FrameSortPreviousSortMethod") or "INDEX"
            local previousGroupFilter = container.Frame:GetAttribute("FrameSortPreviousGroupFilter")

            container.Frame:SetAttribute("nameList", nil)
            container.Frame:SetAttribute("sortMethod", previousSortMethod)
            container.Frame:SetAttribute("groupFilter", previousGroupFilter)

            fsLog:Debug("Cleared sorting on container %s.", container.Frame:GetName() or "")
        end
    end

    return #nameListContainers > 0
end

---@param provider FrameProvider?
---@return boolean
function M:TrySort(provider)
    if wow.InCombatLockdown() then
        fsLog:Error("Cannot run non-combat sorting module during combat.")
        return false
    end

    local sorted = false
    local friendlyEnabled, _, _, _ = fsCompare:FriendlySortMode()
    local enemyEnabled, _, _ = fsCompare:EnemySortMode()
    local providers = (provider and { provider }) or fsProviders:EnabledNotSelfManaged() or {}

    if not friendlyEnabled or not enemyEnabled then
        sorted = ClearSorting(providers, friendlyEnabled, enemyEnabled)
    end

    if not friendlyEnabled and not enemyEnabled then
        return sorted
    end

    for _, p in ipairs(providers) do
        local start = wow.GetTimePreciseSec()

        local providerContainers = p.Containers and p:Containers() or nil
        providerContainers = providerContainers or {}

        local containers = fsEnumerable
            :From(providerContainers)
            :Where(function(container)
                if not container.Frame then
                    return false
                end

                if (container.Type == fsFrame.ContainerType.Party or container.Type == fsFrame.ContainerType.Raid) and not friendlyEnabled then
                    return false
                end

                if container.Type == fsFrame.ContainerType.EnemyArena and not enemyEnabled then
                    return false
                end

                if container.EnableInBattlegrounds ~= nil and not container.EnableInBattlegrounds and wowEx.IsInstanceBattleground() then
                    return false
                end

                if type(container.Frame.IsVisible) ~= "function" then
                    fsLog:WarnOnce("Invalid container frame for provider %s.", p:Name() or "nil")
                    return false
                end

                if not container.Frame:IsVisible() then
                    fsLog:Debug("Container %s is not visible so not sorting it.", container.Frame:GetName() or "nil")
                    return false
                end

                return true
            end)
            :ToTable()

        local providerSorted = false
        for _, container in ipairs(containers) do
            local containerSorted

            if container.IsGrouped and container:IsGrouped() then
                containerSorted = TrySortContainerGroups(container)
            else
                containerSorted = TrySortContainer(container)
            end

            providerSorted = providerSorted or containerSorted

            fsLog:Debug("Container %s for provider %s was %s.", container.Frame:GetName() or "nil", p:Name(), containerSorted and "sorted" or "not sorted")
        end

        sorted = sorted or providerSorted

        local stop = wow.GetTimePreciseSec()
        if #containers > 0 then
            fsLog:Debug("Sort for %s took %fms, result: %s.", p:Name(), (stop - start) * 1000, providerSorted and "sorted" or "not sorted")
        end
    end

    return sorted
end
