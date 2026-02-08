---@type string, Addon
local _, addon = ...
local fsEnumerable = addon.Collections.Enumerable
local fsUnit = addon.WoW.Unit
local fsLog = addon.Logging.Log
---@class FrameUtil
local M = {
    ---@class ContainerType
    ContainerType = {
        Party = 1,
        Raid = 2,
        EnemyArena = 3,
    },
    ---@class FrameLayoutType
    LayoutType = {
        --- Arrange frames by adjusting their x/y coordinates without changing the anchor.
        Soft = 1,
        --- Arrange frames by setting their anchors.
        Hard = 2,
        -- Uses the NameList attribute of a SecureGroupHeader to order members.
        NameList = 3,
    },
}

addon.WoW.Frame = M

---@param provider FrameProvider
---@param containerType number
---@param visibleOnly boolean? override the default container visibility filter
function M:GetFrames(provider, containerType, visibleOnly)
    if not provider then
        fsLog:Error("Frame:GetFrames() - provider must not be nil.")
        return {}
    end
    if not containerType then
        fsLog:Error("Frame:GetFrames() - type must not be nil.")
        return {}
    end

    local target = M:GetContainer(provider, containerType)

    if not target then
        return {}
    end

    if visibleOnly == nil then
        visibleOnly = target.VisibleOnly
    end

    local frames = (type(target.Frames) == "function" and target:Frames()) or M:ExtractUnitFrames(target.Frame, true, visibleOnly)

    if not target.IsGrouped or not target:IsGrouped() then
        return frames
    end

    local groups = M:ExtractGroups(target.Frame, visibleOnly)
    local ungrouped = fsEnumerable
        :From(groups)
        :Map(function(group)
            return M:ExtractUnitFrames(group, true, visibleOnly)
        end)
        :Flatten()

    return fsEnumerable:From(frames):Concat(ungrouped):ToTable()
end

---Returns the frames in order of their relative positioning to each other.
---@param frames table[] frames in any particular order
---@return FrameChain root in order of parent -> child -> child -> child
function M:ToFrameChain(frames)
    local invalid = { Valid = false }

    if not frames then
        fsLog:Error("Frame:ToFrameChain() - frames must not be nil.")
        return invalid
    end

    if #frames == 0 then
        return invalid
    end

    local nodesByFrame = fsEnumerable:From(frames):ToDictionary(function(frame)
        return frame
    end, function(frame)
        return {
            Next = nil,
            Previous = nil,
            Value = frame,
        }
    end)

    local root = nil

    for i = 1, #frames do
        local frame = frames[i]
        local node = nodesByFrame[frame]

        if not node or not node.Value or not node.Value.GetPoint then
            return invalid
        end

        local _, relativeTo = node.Value:GetPoint()

        if not relativeTo then
            if root then
                return invalid
            end

            root = node
        else
            local parent = nodesByFrame[relativeTo]

            if parent then
                if parent.Next then
                    return invalid
                end

                parent.Next = node
                node.Previous = parent
            else
                if root then
                    return invalid
                end

                root = node
            end
        end
    end

    if not root then
        return invalid
    end

    -- assert we have a complete chain
    local count = 0
    local current = root
    local visited = {}

    while current do
        if visited[current] then
            -- protect against circular references
            return invalid
        end

        visited[current] = true
        count = count + 1
        current = current.Next
    end

    if count ~= #frames then
        return invalid
    end

    root.Valid = true
    return root
end

---Returns an ordered set of frames from the given chain
---@param chain FrameChain root
function M:FramesFromChain(chain)
    if not chain then
        fsLog:Error("Frame:FramesFromChain() - chain must not be nil.")
        return {}
    end

    if not chain.Valid then
        fsLog:Error("Frame:FramesFromChain() - chain must be valid.")
        return {}
    end

    local frames = {}
    local next = chain

    while next do
        frames[#frames + 1] = next.Value

        ---@diagnostic disable-next-line: cast-local-type
        next = next.Next
    end

    return frames
end

---Returns true if all the frames have the same anchor.
---@param frames table[] frames in any particular order
---@return boolean
function M:IsFlat(frames)
    if not frames then
        fsLog:Error("Frame:IsFlat() - frames must not be nil.")
        return false
    end

    if #frames == 0 then
        return false
    end

    if not frames[1] or not frames[1].GetPoint then
        return false
    end

    local _, anchor, _, _, _ = frames[1]:GetPoint()

    if anchor == nil then
        return false
    end

    for i = 2, #frames do
        if not frames[i].GetPoint then
            return false
        end

        local _, relativeTo, _, _, _ = frames[i]:GetPoint()

        if relativeTo ~= anchor then
            return false
        end
    end

    return true
end

--- Returns the normalised/canonical unit token from a frame.
---@param frame table
---@return string|nil
function M:GetFrameUnit(frame)
    if not frame then
        fsLog:Error("Frame:GetFrameUnit() - frame must not be nil.")
        return nil
    end

    if M:IsForbidden(frame) then
        return nil
    end

    -- note frame.unit can differ from the "unit" attribute
    -- as the unit attribute can be the displayUnit
    -- e.g. when the player is in a vehicle:
    -- frame.unit = "raid13"
    -- frame:GetAttribute("unit") = "raid13pet"
    -- where possible we want the underlying unit
    if frame.unit then
        return fsUnit:NormaliseUnit(frame.unit) or frame.unit
    end

    if frame.GetAttribute then
        local unit = frame:GetAttribute("unit")

        if unit then
            return fsUnit:NormaliseUnit(unit) or unit
        end
    end

    local name = frame.GetName and frame:GetName() or ""
    local arena = string.match(name, "arena%d")
    return arena and (fsUnit:NormaliseUnit(arena) or arena) or nil
end

---Returns a collection of unit frames from the specified container.
---@param container table the container frame
---@param containerVisible boolean?: if true, skip if container isn't visible
---@param visibleOnly boolean?: if true, only include visible child frames
---@param requireUnit boolean?: if true, require GetFrameUnit(frame) ~= nil
---@param includeTarget boolean?: if true (default = true), include target frames regardless of if they are visible or not.
---@return table
function M:ExtractUnitFrames(container, containerVisible, visibleOnly, requireUnit, includeTarget)
    if not container then
        fsLog:Error("Frame:ExtractUnitFrames() - container must not be nil.")
        return {}
    end

    if requireUnit == nil then
        requireUnit = true
    end

    if visibleOnly == nil then
        visibleOnly = true
    end

    if containerVisible == nil then
        containerVisible = true
    end

    if includeTarget == nil then
        includeTarget = true
    end

    if containerVisible then
        if type(container.IsVisible) ~= "function" or not container:IsVisible() then
            return {}
        end
    end

    if type(container.GetChildren) ~= "function" then
        return {}
    end

    return fsEnumerable
        :From({ container:GetChildren() })
        :Where(function(frame)
            if M:IsForbidden(frame) then
                return false
            end

            local unit = M:GetFrameUnit(frame)

            if requireUnit then
                if not unit then
                    return false
                end
            else
                local name = frame.GetName and frame:GetName()

                if not name then
                    return false
                end

                -- without a unit check, we can end up with a lot of unrelated frames
                -- so checking their name is a decent filter
                if not string.match(name, "Member") and not string.match(name, "Pet") then
                    return false
                end
            end

            if not frame.GetTop or not frame.GetLeft then
                return false
            end

            if frame:GetTop() == nil or frame:GetLeft() == nil then
                -- this can happen for example with ElvUI for frames without a unit
                -- so don't log this as a warning to prevent spam
                return false
            end

            if unit and includeTarget and fsUnit:IsRaidTarget(unit) then
                return true
            end

            if visibleOnly and (not frame.IsVisible or not frame:IsVisible()) then
                return false
            end

            return true
        end)
        :ToTable()
end

---Returns a collection of groups from the specified container.
---@param container table
---@param visibleOnly boolean?
---@return table
function M:ExtractGroups(container, visibleOnly)
    if not container then
        fsLog:Error("Frame:ExtractGroups() - container must not be nil.")
        return {}
    end

    if M:IsForbidden(container) then
        return {}
    end

    if type(container.GetChildren) ~= "function" or type(container.IsVisible) ~= "function" then
        return {}
    end

    if not container:IsVisible() then
        return {}
    end

    return fsEnumerable
        :From({ container:GetChildren() })
        :Where(function(frame)
            if M:IsForbidden(frame) then
                return false
            end

            local name = frame.GetName and frame:GetName()

            if not name then
                return false
            end

            -- wotlk with 1 group uses the party frame
            -- only supports blizzard groups atm
            if not string.match(name, "CompactPartyFrame") and not string.match(name, "CompactRaidGroup") then
                return false
            end

            if not frame.GetTop or not frame.GetLeft then
                return false
            end

            if frame:GetTop() == nil or frame:GetLeft() == nil then
                fsLog:Warning("Group frame '%s' has no position.", name or "nil")
                return false
            end

            if visibleOnly and (not frame.IsVisible or not frame:IsVisible()) then
                return false
            end

            return true
        end)
        :ToTable()
end

---@param provider FrameProvider
---@param containerType number
---@return FrameContainer?
function M:GetContainer(provider, containerType)
    if not provider then
        fsLog:Error("Frame:GetContainer() - provider must not be nil.")
        return nil
    end

    if not containerType then
        fsLog:Error("Frame:GetContainer() - type must not be nil.")
        return nil
    end

    if provider.IsExternal then
        fsLog:Error("Frame:GetContainer() - can't retrieve frames of an external provider.")
        return nil
    end

    local containers = type(provider.Containers) == "function" and provider:Containers()

    if type(containers) ~= "table" then
        return nil
    end

    for _, container in ipairs(containers) do
        if container.Type == containerType then
            return container
        end
    end

    return nil
end

---Returns the party frames of the specified provider.
---@param provider FrameProvider
---@return table[]
function M:PartyFrames(provider, visibleOnly)
    return M:GetFrames(provider, M.ContainerType.Party, visibleOnly)
end

---Returns the raid frames of the specified provider.
---@param provider FrameProvider
---@return table[]
function M:RaidFrames(provider, visibleOnly)
    return M:GetFrames(provider, M.ContainerType.Raid, visibleOnly)
end

---Returns the enemy arena frames of the specified provider.
---@param provider FrameProvider
---@return table[]
function M:ArenaFrames(provider, visibleOnly)
    return M:GetFrames(provider, M.ContainerType.EnemyArena, visibleOnly)
end

function M:IsForbidden(frame)
    if not frame then
        fsLog:Error("Frame:IsForbidden() - frame must not be nil.")
        return false
    end

    -- wotlk 3.3.5 doesn't have this function
    if not frame.IsForbidden then
        return false
    end

    local forbidden = frame:IsForbidden()

    if forbidden then
        -- (Get/Set)Attribute is allowed on forbidden frames
        local unit = frame:GetAttribute("unit")
        fsLog:Warning("Detected forbidden frame, unit: %s.", unit or "unknown")
    end

    return forbidden
end
