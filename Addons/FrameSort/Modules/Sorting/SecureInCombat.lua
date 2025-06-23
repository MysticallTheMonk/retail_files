---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsSorting = addon.Modules.Sorting
local fsCompare = addon.Collections.Comparer
local fsProviders = addon.Providers
local fsUnit = addon.WoW.Unit
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

-- prints a log message
secureMethods["Log"] = [[
    if not self:GetAttribute("LoggingEnabled") then return end

    local level, message = ...
    print(format("FrameSort - %s: %s", level, message))
]]

-- rounds a number to the specified decimal places
secureMethods["Round"] = [[
    local number, decimalPlaces = ...

    if number == nil then return nil end

    local mult = 10 ^ (decimalPlaces or 0)
    return math.floor(number * mult + 0.5) / mult
]]

-- returns true if in combat, otherwise false
secureMethods["InCombat"] = [[
    return SecureCmdOptionParse("[combat] true; false") == "true"
]]

-- gets the unit token from a frame
secureMethods["GetUnit"] = [[
    local framesVariable = ...
    local frame = _G[framesVariable]

    local u = frame:GetAttribute("unit")
    if u then
        return u
    end

    local name = frame:GetName()
    return name and strmatch(name, "arena%d")
]]

-- filters a set of frames to only unit frames
secureMethods["ExtractUnitFrames"] = [[
    local run = control or self
    local framesVariable, destinationVariable, visibleOnly = ...
    local children = _G[framesVariable]
    local unitFrames = newtable()

    for _, child in ipairs(children) do
        Frame = child
        local unit = run:RunAttribute("GetUnit", "Frame")
        Frame = nil

        -- in some rare cases frames can have no position, so exclude them
        local left, bottom, width, height = child:GetRect()

        if unit and
            (child:IsVisible() or not visibleOnly) and
            (left and bottom and width and height) then
            unitFrames[#unitFrames + 1] = child
        end
    end

    _G[destinationVariable] = unitFrames
    return #unitFrames > 0
]]

-- extracts a set of groups from a container
secureMethods["ExtractGroups"] = [[
    local containerTableName, destinationTableName = ...
    local container = _G[containerTableName]
    local children = newtable()

    container.Frame:GetChildList(children)
    if #children == 0 then return false end

    local groups = newtable()

    for _, child in ipairs(children) do
        local name = child:GetName()
        local left, bottom, width, height = child:GetRect()

        if child:IsVisible() and name and (left and bottom and width and height) then
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
    local fromName, toName = ...
    local from = _G[fromName]
    local to = _G[toName]

    for k, v in pairs(from) do
        to[k] = v
    end
]]

-- converts an array of frames in a chain layout to a linked list
-- where the root node is the start of the chain
-- and each subsequent node depends on the one before it
-- i.e. root -> frame1 -> frame2 -> frame3
secureMethods["FrameChain"] = [[
    local framesVariable, destinationVariable = ...
    local frames = _G[framesVariable]
    local nodesByFrame = newtable()

    for _, frame in pairs(frames) do
        local node = newtable()
        node.Value = frame

        nodesByFrame[frame] = node
    end

    local root = nil
    for _, child in pairs(nodesByFrame) do
        local _, relativeTo, _, _, _ = child.Value:GetPoint()
        local parent = nodesByFrame[relativeTo]

        if parent then
            if parent.Next then
                return false, nil
            end

            parent.Next = child
            child.Previous = parent
        else
            root = child
        end
    end

    -- assert we have a complete chain
    local count = 0
    local current = root

    while current do
        count = count + 1
        current = current.Next
    end

    if count ~= #frames then
        return false
    end

    _G[destinationVariable] = root

    return true
]]

-- bubble sort because it's easier to write
-- not going to write an nlog(n) sort algorithm in this environment
secureMethods["Sort"] = [[
    local run = control or self
    local arrayVariable, compareFunction = ...
    local array, compare = _G[arrayVariable], _G[compareFunction]

    for i = 1, #array do
        for j = 1, #array - i do
            Left, Right = array[j], array[j + 1]

            if run:RunAttribute(compareFunction, "Left", "Right") then
                array[j], array[j + 1] = array[j + 1], array[j]
            end

            Left, Right = nil, nil
        end
    end
]]

secureMethods["CompareFrameTopLeft"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...
    local x, y = _G[leftVariable], _G[rightVariable]

    local left, bottom, width, height = x:GetRect()
    local nextLeft, nextBottom, nextWidth, nextHeight = y:GetRect()

    local topFuzzy = run:RunAttribute("Round", bottom + height)
    local nextTopFuzzy = run:RunAttribute("Round", nextBottom + nextHeight)
    local leftFuzzy = run:RunAttribute("Round", left)
    local nextLeftFuzzy = run:RunAttribute("Round", nextLeft)

    return topFuzzy < nextTopFuzzy or leftFuzzy > nextLeftFuzzy
]]

secureMethods["CompareFrameTopRight"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...
    local x, y = _G[leftVariable], _G[rightVariable]

    local left, bottom, width, height = x:GetRect()
    local nextLeft, nextBottom, nextWidth, nextHeight = y:GetRect()

    local topFuzzy = run:RunAttribute("Round", bottom + height)
    local nextTopFuzzy = run:RunAttribute("Round", nextBottom + nextHeight)
    local rightFuzzy = run:RunAttribute("Round", left + width)
    local nextRightFuzzy = run:RunAttribute("Round", nextLeft + nextWidth)

    return topFuzzy < nextTopFuzzy or rightFuzzy < nextRightFuzzy
]]

secureMethods["CompareFrameBottomLeft"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...
    local x, y = _G[leftVariable], _G[rightVariable]

    local left, bottom, width, height = x:GetRect()
    local nextLeft, nextBottom, nextWidth, nextHeight = y:GetRect()

    local bottomFuzzy = run:RunAttribute("Round", bottom)
    local nextBottomFuzzy = run:RunAttribute("Round", nextBottom)
    local leftFuzzy = run:RunAttribute("Round", left)
    local nextLeftFuzzy = run:RunAttribute("Round", nextLeft)

    return bottomFuzzy > nextBottomFuzzy or leftFuzzy > nextLeftFuzzy
]]

secureMethods["ComparePointTopLeft"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...
    local x, y = _G[leftVariable], _G[rightVariable]

    local topFuzzy = run:RunAttribute("Round", x.Bottom + x.Height)
    local nextTopFuzzy = run:RunAttribute("Round", y.Bottom + y.Height)
    local leftFuzzy = run:RunAttribute("Round", x.Left)
    local nextLeftFuzzy = run:RunAttribute("Round", y.Left)

    return topFuzzy < nextTopFuzzy or leftFuzzy > nextLeftFuzzy
]]

secureMethods["ComparePointLeftTop"] = [[
    local run = control or self
    local leftVariable, rightVariable = ...
    local x, y = _G[leftVariable], _G[rightVariable]

    local topFuzzy = run:RunAttribute("Round", x.Bottom + x.Height)
    local nextTopFuzzy = run:RunAttribute("Round", y.Bottom + y.Height)
    local leftFuzzy = run:RunAttribute("Round", x.Left)
    local nextLeftFuzzy = run:RunAttribute("Round", y.Left)

    return leftFuzzy > nextLeftFuzzy or topFuzzy < nextTopFuzzy
]]

-- performs an out of place sort on an array frames by the order of the units array
secureMethods["SortFramesByUnits"] = [[
    local run = control or self
    local framesVariable, unitsVariable, destinationVariable = ...
    local frames = _G[framesVariable]
    local units = _G[unitsVariable]
    local index = 1
    local framesByUnit = newtable()
    local frameWasSorted = newtable()

    for i = 1, #frames do
        local frame = frames[i]

        Frame = frame
        local unit = run:RunAttribute("GetUnit", "Frame")
        Frame = nil

        if unit then
            framesByUnit[unit] = frame
        else
            framesWithoutUnits = frame
        end

        frameWasSorted[frame] = false
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

    -- we may not have all unit information
    -- so any frames that didn't make it we can just add on to the end
    for i = 1, #frames do
        local frame = frames[i]

        if not frameWasSorted[frame] then
            sorted[#sorted + 1] = frame
        end
    end

    _G[destinationVariable] = sorted
]]

-- adjusts the x and y offsets of a frame
secureMethods["AdjustPointsOffset"] = [[
    local framesVariable, xDelta, yDelta = ...
    local frame = _G[framesVariable]

    if xDelta == 0 and yDelta == 0 then
        return false
    end

    local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint()

    if not point or not relativeTo or not relativePoint then
        -- something weird going on with this frame
        return false
    end

    local newOffsetX = (offsetX or 0) + xDelta
    local newOffsetY = (offsetY or 0) + yDelta
    local isProtected, explicitly = (relativeTo and relativeTo:IsProtected()) or false, false
    local newRelativeTo = (isProtected and explicitly) and relativeTo or "$parent"

    frame:SetPoint(point, newRelativeTo, relativePoint, newOffsetX, newOffsetY)
    return true
]]

-- returns the spacing configuration for the specified container type
secureMethods["SpacingForContainer"] = [[
    local containerType = ...
    local spacingType = nil

    if containerType == ContainerType.Party then
        spacingType = "Party"
    elseif containerType == ContainerType.Raid then
        spacingType = "Raid"
    elseif containerType == ContainerType.EnemyArena then
        spacingType = "EnemyArena"
    else
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
    local points = _G[pointsVariable]
    local spacing = _G[spacingVariable]
    local horizontal = spacing.Horizontal or 0
    local vertical = spacing.Vertical or 0

    OrderedTopLeft = newtable()
    OrderedLeftTop = newtable()

    run:RunAttribute("CopyTable", pointsVariable, "OrderedTopLeft")
    run:RunAttribute("CopyTable", pointsVariable, "OrderedLeftTop")

    run:RunAttribute("Sort", "OrderedTopLeft", "ComparePointTopLeft")
    run:RunAttribute("Sort", "OrderedLeftTop", "ComparePointLeftTop")

    local changed = false

    for i = 2, #OrderedLeftTop do
        local point = OrderedLeftTop[i]
        local previous = OrderedLeftTop[i - 1]
        local sameRow = run:RunAttribute("Round", point.Bottom + point.Height) == run:RunAttribute("Round", previous.Bottom + previous.Height)

        if sameRow then
            local existingSpace = point.Left - (previous.Left + previous.Width)
            local xDelta = horizontal - existingSpace
            point.Left = point.Left + xDelta
            changed = changed or xDelta ~= 0
        end
    end

    for i = 2, #OrderedTopLeft do
        local point = OrderedTopLeft[i]
        local previous = OrderedTopLeft[i - 1]
        local sameColumn = run:RunAttribute("Round", point.Left) == run:RunAttribute("Round", previous.Left)

        if sameColumn then
            local existingSpace = previous.Bottom - (point.Bottom + point.Height)
            local yDelta = vertical - existingSpace
            point.Bottom = point.Bottom - yDelta
            changed = changed or yDelta ~= 0
        end
    end

    return changed
]]

-- applies spacing between raid groups
secureMethods["SpaceGroups"] = [[
    local run = control or self
    local groupsVariable, spacingVariable = ...
    local groups = _G[groupsVariable]
    local spacing = _G[spacingVariable]

    local points = newtable()
    local pointsByGroup = newtable()

    for _, group in ipairs(groups) do
        local point = newtable()
        local left, bottom, width, height = group:GetRect()

        point.Left = left
        point.Bottom = bottom
        point.Width = width
        point.Height = height

        points[#points + 1] = point
        pointsByGroup[group] = point
    end

    GroupPoints = points

    if not run:RunAttribute("ApplySpacing", "GroupPoints", spacingVariable) then
        GroupPoints = nil
        return false
    end

    GroupPoints = nil

    local movedAny = false

    for _, group in ipairs(groups) do
        local point = pointsByGroup[group]
        local left, bottom, _, _ = group:GetRect()
        local xDelta = point.Left - left
        local yDelta = point.Bottom - bottom
        local xDeltaRounded = run:RunAttribute("Round", xDelta, DecimalSanity)
        local yDeltaRounded = run:RunAttribute("Round", yDelta, DecimalSanity)

        if xDeltaRounded ~= 0 or yDeltaRounded ~= 0 then
            Group = group
            local moved = run:RunAttribute("AdjustPointsOffset", "Group", xDelta, yDelta)
            movedAny = movedAny or moved
            Group = nil
        end
    end

    return movedAny
]]

-- rearranges a set of frames by only modifying the x and y offsets
secureMethods["SoftArrange"] = [[
    local run = control or self
    local framesVariable, spacingVariable = ...
    local frames = _G[framesVariable]

    OrderedByTopLeft = newtable()

    run:RunAttribute("CopyTable", framesVariable, "OrderedByTopLeft")
    run:RunAttribute("Sort", "OrderedByTopLeft", "CompareFrameTopLeft")

    local points = newtable()
    for _, frame in ipairs(OrderedByTopLeft) do
        local point = newtable()
        local left, bottom, width, height = frame:GetRect()

        point.Left = left
        point.Bottom = bottom
        point.Width = width
        point.Height = height

        points[#points + 1] = point
    end

    if spacingVariable then
        Points = points
        run:RunAttribute("ApplySpacing", "Points", spacingVariable)
        Points = nil
    end

    Root = nil
    local isChain = run:RunAttribute("FrameChain", framesVariable, "Root")
    local root = Root
    Root = nil

    local enumerationOrder = nil

    if isChain then
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

    for i, source in ipairs(enumerationOrder) do
        local desiredIndex = -1
        for j = 1, #frames do
            if source == frames[j] then
                desiredIndex = j
                break
            end
        end

        if desiredIndex > 0 and desiredIndex <= #points then
            local left, bottom, width, height = source:GetRect()
            local destination = points[desiredIndex]
            local xDelta = destination.Left - left
            local yDelta = destination.Bottom - bottom
            local xDeltaRounded = run:RunAttribute("Round", xDelta, DecimalSanity)
            local yDeltaRounded = run:RunAttribute("Round", yDelta, DecimalSanity)

            if xDeltaRounded ~= 0 or yDeltaRounded ~= 0 then
                Frame = source
                local moved = run:RunAttribute("AdjustPointsOffset", "Frame", xDelta, yDelta)
                movedAny = movedAny or moved
                Frame = nil
            end
        else
            run:RunAttribute("Log", "Warning", "Unable to determine frame's desired index")
        end
    end

    return movedAny
]]

-- rearranges a set of frames by modifying their anchors and offsets
secureMethods["HardArrange"] = [[
    local run = control or self
    local framesVariable, containerVariable, spacingVariable, blockHeight = ...
    local frames = _G[framesVariable]
    local container = _G[containerVariable]
    local spacing = spacingVariable and _G[spacingVariable]
    local verticalSpacing = spacing and spacing.Vertical or 0
    local horizontalSpacing = spacing and spacing.Horizontal or 0
    local isHorizontalLayout = container.IsHorizontalLayout
    local _, _, firstFrameWidth, firstFrameHeight = frames[1]:GetRect()
    local offset = container.Offset or newtable()
    local blockWidth = firstFrameWidth
    blockHeight = blockHeight or firstFrameHeight

    offset.X = offset.X or 0
    offset.Y = offset.Y or 0

    local pointsByFrame = newtable()
    local row, col = 1, 1
    local xOffset = offset.X
    local yOffset = offset.Y
    local rowHeight = 0
    local currentBlockHeight = 0

    for _, frame in ipairs(frames) do
        local framePoint = newtable()
        framePoint.Point = container.AnchorPoint or "TOPLEFT"
        framePoint.RelativeTo = container.Anchor or container.Frame
        framePoint.RelativePoint = container.AnchorPoint or "TOPLEFT"
        framePoint.XOffset = xOffset
        framePoint.YOffset = yOffset
        pointsByFrame[frame] = framePoint

        local _, _, _, height = frame:GetRect()

        if isHorizontalLayout then
            col = (col + 1)
            xOffset = xOffset + blockWidth + horizontalSpacing
            -- keep track of the tallest frame within the row
            -- as the next row will be the tallest row frame + spacing
            rowHeight = max(rowHeight, height)

            -- if we've reached the end then wrap around
            if container.FramesPerLine and col > container.FramesPerLine then
                xOffset = offset.X
                yOffset = yOffset - rowHeight - verticalSpacing

                row = row + 1
                col = 1
                rowHeight = 0
            end
        else
            currentBlockHeight = currentBlockHeight + height

            -- subtract 1 for a bit of breathing room for rounding errors
            local isNewRow = currentBlockHeight >= (blockHeight - 1)

            if isNewRow then
                currentBlockHeight = 0
            end

            if isNewRow then
                yOffset = yOffset - height - verticalSpacing
                row = (row + 1)
            else
                -- don't add spacing if we're still within a block
                yOffset = yOffset - height
            end

            -- if we've reached the end then wrap around
            if container.FramesPerLine and row > container.FramesPerLine then
                row = 1
                col = col + 1
                yOffset = offset.Y
                xOffset = xOffset + blockWidth + horizontalSpacing
            end
        end
    end

    local framesToMove = newtable()

    for _, frame in ipairs(frames) do
        local to = pointsByFrame[frame]
        local point, relativeTo, relativePoint, xOffset, yOffset = frame:GetPoint()
        local different =
            point ~= to.Point or
            relativeTo ~= to.RelativeTo or
            relativePoint ~= to.RelativePoint or
            run:RunAttribute("Round", xOffset, DecimalSanity) ~= run:RunAttribute("Round", to.XOffset, DecimalSanity) or
            run:RunAttribute("Round", yOffset, DecimalSanity) ~= run:RunAttribute("Round", to.YOffset, DecimalSanity)

        if different then
            framesToMove[#framesToMove + 1] = frame
            frame:ClearAllPoints()
        end
    end

    -- now move them
    for _, frame in ipairs(framesToMove) do
        local to = pointsByFrame[frame]
        -- since 10.2.7 this broke where to.RelativeTo must be a protected frame
        -- thankfully we can use a magic string to default it to the parent even if it's not protected
        local isProtected, explicitly = (to.RelativeTo and to.RelativeTo:IsProtected()) or false, false
        local relativeTo = (isProtected and explicitly) and to.RelativeTo or "$parent"

        frame:SetPoint(to.Point, relativeTo, to.RelativePoint, to.XOffset, to.YOffset)
    end

    return #framesToMove > 0
]]

-- determines the offset to use for the ungrouped portion of the raid frames.
secureMethods["UngroupedOffset"] = [[
    local run = control or self
    local containerVariable, spacingVariable = ...
    local container = _G[containerVariable]
    local spacing = _G[spacingVariable]

    if not run:RunAttribute("ExtractGroups", containerVariable, "OffsetGroups") then
        return 0, 0
    end

    local lastGroup = nil

    for i = #OffsetGroups, 1, -1 do
        local group = OffsetGroups[i]

        if group:IsVisible() then
            lastGroup = group
            break
        end
    end

    if not lastGroup then
        OffsetGroups = nil
        return 0, 0
    end

    OffsetGroupChildren = newtable()

    lastGroup:GetChildList(OffsetGroupChildren)

    if not run:RunAttribute("ExtractUnitFrames", "OffsetGroupChildren", "OffsetGroupFrames", container.VisibleOnly) then
        OffsetGroupFrames = nil
        OffsetGroupChildren = nil
        return 0, 0
    end

    local horizontal = container.IsHorizontalLayout

    if not spacing then
        spacing = newtable()
        spacing.Horizontal = 0
        spacing.Vertical = 0
    end

    local x, y = 0, 0
    local left, bottom, width, height = container.Frame:GetRect()

    if horizontal then
        run:RunAttribute("Sort", "OffsetGroupFrames", "CompareFrameBottomLeft")

        local bottomLeftFrame = OffsetGroupFrames[1]
        local bottomFrameLeft, bottomFrameBottom, _, _ = bottomLeftFrame:GetRect()

        x = -(left - bottomFrameLeft)
        y = -((bottom + height) - bottomFrameBottom + spacing.Vertical)
    else
        run:RunAttribute("Sort", "OffsetGroupFrames", "CompareFrameTopRight")

        local topRightFrame = OffsetGroupFrames[1]
        local topFrameLeft, topFrameBottom, topFrameWidth, topFrameHeight = topRightFrame:GetRect()

        x = -(left - (topFrameLeft + topFrameWidth) - spacing.Horizontal)
        y = -((bottom + height) - (topFrameBottom + topFrameHeight))
    end

    OffsetGroupChildren = nil
    OffsetGroupFrames = nil
    OffsetGroups = nil

    return x, y
]]

secureMethods["TrySortContainerGroups"] = [[
    local run = control or self
    local containerVariable, providerVariable = ...
    local container = _G[containerVariable]
    local provider = _G[providerVariable]

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

        sorted = run:RunAttribute("TrySortContainer", "GroupContainer", providerVariable) or sorted

        GroupContainer = nil
    end

    if not container.SupportsSpacing then
        Groups = nil
        return sorted
    end

    local horizontalSpacing, verticalSpacing = run:RunAttribute("SpacingForContainer", container.Type)

    if not horizontalSpacing and not verticalSpacing or (horizontalSpacing == 0 and verticalSpacing == 0) then
        Groups = nil
        return sorted
    end

    GroupSpacing = newtable()
    GroupSpacing.Horizontal = horizontalSpacing or 0
    GroupSpacing.Vertical = verticalSpacing or 0

    sorted = run:RunAttribute("SpaceGroups", "Groups", "GroupSpacing") or sorted

    -- TODO: I think something from here onwards is very slow, investigate
    local offsetX, offsetY = run:RunAttribute("UngroupedOffset", containerVariable, "GroupSpacing")

    UngroupedChildren = newtable()
    UngroupedFrames = newtable()

    -- import into the global table for filtering
    container.Frame:GetChildList(UngroupedChildren)

    if not run:RunAttribute("ExtractUnitFrames", "UngroupedChildren", "UngroupedFrames", container.VisibleOnly) then
        UngroupedChildren = nil
        UngroupedFrames = nil
        return false
    end

    UngroupedContainer = newtable()

    -- just copy over all the attributes to make code simpler
    run:RunAttribute("CopyTable", containerVariable, "UngroupedContainer")

    -- now re-write over the top
    UngroupedContainer.Offset = newtable()
    UngroupedContainer.Offset.X = offsetX
    UngroupedContainer.Offset.Y = offsetY

    -- use the block height of a member frame as pet frames are smaller
    local blockHeight = UngroupedFrames[1]:GetHeight() * 2

    sorted = run:RunAttribute("HardArrange", "UngroupedFrames", "UngroupedContainer", "GroupSpacing", blockHeight)

    UngroupedContainer = nil
    UngroupedChildren = nil
    UngroupedFrames = nil
    GroupSpacing = nil
    Groups = nil

    return sorted
]]

-- attempts to sort the frames within the container
secureMethods["TrySortContainer"] = [[
    local run = control or self
    local friendlyEnabled = self:GetAttribute("FriendlySortEnabled")
    local enemyEnabled = self:GetAttribute("EnemySortEnabled")
    local containerVariable, providerVariable = ...
    local container = _G[containerVariable]
    local provider = _G[providerVariable]
    local units = nil

    if container.LayoutType == LayoutType.NameList then
        -- there's no way to get a unit's name in the restricted environment
        -- so we can't do anything
        return false
    end

    if container.Type == ContainerType.Party then
        units = FriendlyUnits
    elseif container.Type == ContainerType.Raid then
        units = FriendlyUnits
    elseif container.Type == ContainerType.EnemyArena then
        units = EnemyUnits
    else
        run:RunAttribute("Log", "Error", "Invalid container type: " .. (container.Type or 'nil'))
        return false
    end

    Children = newtable()
    Frames = newtable()

    if container.Frames then
        Frames = container.Frames
    else
        -- import into the global table for filtering
        container.Frame:GetChildList(Children)

        if not run:RunAttribute("ExtractUnitFrames", "Children", "Frames", container.VisibleOnly) then
            return false
        end
    end

    Units = units or newtable()

    -- sort the frames to the desired locations
    FramesInUnitOrder = nil
    run:RunAttribute("SortFramesByUnits", "Frames", "Units", "FramesInUnitOrder")

    local sorted = false

    if container.Spacing then
        Spacing = newtable()
        Spacing.Horizontal = container.SpacingHorizontal
        Spacing.Vertical = container.SpacingVertical
    elseif container.SupportsSpacing then
        local horizontalSpacing, verticalSpacing = run:RunAttribute("SpacingForContainer", container.Type)

        if (horizontalSpacing and horizontalSpacing ~= 0) or (verticalSpacing and verticalSpacing ~= 0) then
            Spacing = newtable()
            Spacing.Horizontal = horizontalSpacing
            Spacing.Vertical = verticalSpacing
        end
    end

    if container.LayoutType == LayoutType.Hard then
        sorted = run:RunAttribute("HardArrange", "FramesInUnitOrder", containerVariable, Spacing and "Spacing")
    elseif container.LayoutType == LayoutType.Soft then
        sorted = run:RunAttribute("SoftArrange", "FramesInUnitOrder", Spacing and "Spacing")
    end

    FramesInUnitOrder = nil
    Children = nil
    Frames = nil
    Spacing = nil

    return sorted
]]

-- top level perform sort routine
secureMethods["TrySort"] = [[
    local run = control or self

    if not run:RunAttribute("InCombat") then return false end

    local friendlyEnabled = self:GetAttribute("FriendlySortEnabled")
    local enemyEnabled = self:GetAttribute("EnemySortEnabled")

    if not friendlyEnabled and not enemyEnabled then return false end

    run:CallMethod("SortStarting")

    local loadedUnits = self:GetAttribute("LoadedUnits")
    if not loadedUnits then
        run:RunAttribute("LoadUnits")
        self:SetAttribute("LoadedUnits", true)
    end

    local toSort = newtable()

    for _, provider in pairs(Providers) do
        local providerEnabled = self:GetAttribute("Provider" .. provider.Name .. "Enabled")

        if providerEnabled then
            for _, container in ipairs(provider.Containers) do
                if not container.Frame:IsProtected() then
                    run:RunAttribute("Log", "Error", "Container for " .. provider.Name .. " must be protected.")
                elseif container.Frame:IsVisible() and
                       ((container.Type == ContainerType.Party or container.Type == ContainerType.Raid) and friendlyEnabled) or
                       (container.Type == ContainerType.EnemyArena and enemyEnabled) then
                    local add = newtable()
                    add.Provider = provider
                    add.Container = container

                    toSort[#toSort + 1] = add
                end
            end
        end
    end

    local sorted = false

    for _, item in ipairs(toSort) do
        Container = item.Container
        Provider = item.Provider

        if Container.IsGrouped then
            sorted = run:RunAttribute("TrySortContainerGroups", "Container", "Provider") or sorted
        else
            sorted = run:RunAttribute("TrySortContainer", "Container", "Provider") or sorted
        end

        Provider = nil
        Container = nil
    end

    run:CallMethod("SortEnding", sorted)

    return sorted
]]

secureMethods["LoadProvider"] = [[
    local name = self:GetAttribute("ProviderName")
    local provider = Providers[name]

    if not provider then
        provider = newtable()
        provider.Name = name
        Providers[name] = provider
    end

    -- replace existing containers (if any)
    provider.Containers = newtable()

    local containersCount = self:GetAttribute(name .. "ContainersCount")

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

        if framesCount then
            local frames = newtable()

            for j = 1, framesCount do
                local frame = self:GetFrameRef(prefix .. "Frame" .. j)
                frames[#frames + 1] = frame
            end

            container.Frames = frames
        end

        provider.Containers[#provider.Containers + 1] = container
    end
]]

secureMethods["LoadUnits"] = [[
    FriendlyUnits = newtable()
    EnemyUnits = newtable()

    local friendlyUnitsCount = self:GetAttribute("FriendlyUnitsCount") or 0
    local enemyUnitsCount = self:GetAttribute("EnemyUnitsCount") or 0

    for i = 1, friendlyUnitsCount do
        local unit = self:GetAttribute("FriendlyUnit" .. i)
        FriendlyUnits[#FriendlyUnits + 1] = unit
    end

    for i = 1, enemyUnitsCount do
        local unit = self:GetAttribute("EnemyUnit" .. i)
        EnemyUnits[#EnemyUnits + 1] = unit
    end
]]

secureMethods["Init"] = [[
    Providers = newtable()

    -- don't move frames if they are have minuscule position differences
    -- it's just a rounding error and makes no visual impact
    -- this helps preventing spam on our callbacks
    DecimalSanity = 2

    -- must match the enums specified in Frame.lua
    ContainerType = newtable()
    ContainerType.Party = 1
    ContainerType.Raid = 2
    ContainerType.EnemyArena = 3

    LayoutType = newtable()
    LayoutType.Soft = 1
    LayoutType.Hard = 2
    LayoutType.NameList = 3
]]

local function LoadUnits()
    assert(manager)

    -- TODO: we could transfer unit info to the restricted environment
    -- then perform the unit sort inside which would give us more control
    local friendlyUnits = fsUnit:FriendlyUnits()
    local enemyUnits = fsUnit:EnemyUnits()
    local friendlyCompare = fsCompare:SortFunction(friendlyUnits)
    local enemyCompare = fsCompare:EnemySortFunction()

    table.sort(friendlyUnits, friendlyCompare)
    table.sort(enemyUnits, enemyCompare)

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
end

local function LoadEnabled()
    assert(manager)

    local friendlyEnabled = fsCompare:FriendlySortMode()
    local enemyEnabled = fsCompare:EnemySortMode()

    manager:SetAttributeNoHandler("FriendlySortEnabled", friendlyEnabled)
    manager:SetAttributeNoHandler("EnemySortEnabled", enemyEnabled)
    manager:SetAttributeNoHandler("LoggingEnabled", addon.DB.Options.Logging.Enabled)

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

        local spacing = container.Spacing and container:Spacing()
        manager:SetAttributeNoHandler(containerPrefix .. "SpacingHorizontal", spacing and spacing.Horizontal)
        manager:SetAttributeNoHandler(containerPrefix .. "SpacingVertical", spacing and spacing.Vertical)

        if container.Frames then
            local frames = container.Frames()
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

    memberHeader:UnregisterEvent(wow.Events.GROUP_ROSTER_UPDATE)
    memberHeader:UnregisterEvent(wow.Events.UNIT_NAME_UPDATE)

    memberHeader:RegisterEvent(wow.Events.GROUP_ROSTER_UPDATE)
    memberHeader:RegisterEvent(wow.Events.UNIT_NAME_UPDATE)

    petHeader:UnregisterEvent(wow.Events.GROUP_ROSTER_UPDATE)
    petHeader:UnregisterEvent(wow.Events.UNIT_PET)
    petHeader:UnregisterEvent(wow.Events.UNIT_NAME_UPDATE)

    petHeader:RegisterEvent(wow.Events.GROUP_ROSTER_UPDATE)
    petHeader:RegisterEvent(wow.Events.UNIT_PET)
    petHeader:RegisterEvent(wow.Events.UNIT_NAME_UPDATE)
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
                    local manager = self:GetFrameRef("Manager") 
                    manager:SetAttribute("state-framesort-run", "ignore") 
                ]]
            )
            wow.SecureHandlerWrapScript(
                child,
                "OnHide",
                manager,
                [[ 
                    local manager = self:GetFrameRef("Manager") 
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

local function OnCombatStarting()
    LoadEnabled()
    LoadUnits()
    ResubscribeEvents()
    WatchVisibility()
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

    function header:UnitButtonCreated(index)
        local children = { header:GetChildren() }
        local frame = children[index]

        if not frame then
            fsLog:Error("Failed to find unit button " .. index)
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

        if Header.CallMethod then
            Header:CallMethod("UnitButtonCreated", UnitButtonsCount)
        else
            -- backwards compatibility for wotlk private
            local run = control or self
            run:RunFor(Header, [[
                control:CallMethod("UnitButtonCreated")
            ]])
        end
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

function M:Init()
    manager = wow.CreateFrame("Frame", nil, wow.UIParent, "SecureHandlerStateTemplate")

    InjectSecureHelpers(manager)

    function manager:SortStarting()
        manager.TimeStart = wow.GetTimePreciseSec()
    end

    function manager:SortEnding(sorted)
        manager.TimeStop = wow.GetTimePreciseSec()

        local ms = (manager.TimeStop - manager.TimeStart) * 1000
        fsLog:Debug(string.format("In-combat sort took %fms, result: %s.", ms, sorted and "sorted" or "not sorted"))

        if sorted then
            fsSorting:NotifySorted()
        end
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
    fsScheduler:RunWhenEnteringWorld(function()
        for _, provider in ipairs(fsProviders:Enabled()) do
            LoadProvider(provider)
        end
    end)

    LoadEnabled()
    LoadSpacing()

    fsConfig:RegisterConfigurationChangedCallback(OnConfigChanged)

    local combatStartingFrame = wow.CreateFrame("Frame", nil, wow.UIParent)
    combatStartingFrame:HookScript("OnEvent", OnCombatStarting)
    combatStartingFrame:RegisterEvent(wow.Events.PLAYER_REGEN_DISABLED)
end
