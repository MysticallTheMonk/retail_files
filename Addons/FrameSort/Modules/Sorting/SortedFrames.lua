---@type string, Addon
local _, addon = ...
local fsProviders = addon.Providers
local fsEnumerable = addon.Collections.Enumerable
local fsCompare = addon.Modules.Sorting.Comparer
local fsFrame = addon.WoW.Frame

---@class SortedFrames
local M = {}
addon.Modules.Sorting.SortedFrames = M

local function VisualOrder(frames)
    return fsEnumerable
        :From(frames)
        :Where(function(x)
            return x.IsVisible and x:IsVisible()
        end)
        :OrderBy(function(x, y)
            return fsCompare:CompareTopLeftFuzzy(x, y)
        end)
        :ToTable()
end

---Returns an array of friendly frames sorted by their visual order.
---Prefers blizzard frames over other providers.
---@return table
function M:FriendlyFrames(sort)
    if sort == nil then
        sort = true
    end

    local frames

    -- prefer Blizzard frames
    if fsProviders.Blizzard:Enabled() then
        frames = fsFrame:RaidFrames(fsProviders.Blizzard, true)

        if not frames or #frames == 0 then
            frames = fsFrame:PartyFrames(fsProviders.Blizzard, true)
        end

        if frames and #frames > 0 then
            return sort and VisualOrder(frames) or frames
        end
    end

    ---@type FrameProvider[]
    local nonBlizzard = fsEnumerable
        :From(fsProviders:EnabledNotSelfManaged())
        :Where(function(provider)
            return provider ~= fsProviders.Blizzard
        end)
        :ToTable()

    for _, provider in ipairs(nonBlizzard) do
        local containers = provider.Containers and provider:Containers() or {}
        local raidContainers = fsEnumerable
            :From(containers)
            :Where(function(container)
                -- important: don't use namelists, because they will have been filtered
                return container.LayoutType ~= fsFrame.LayoutType.NameList and container.Type == fsFrame.ContainerType.Raid
            end)
            :ToTable()

        for _, raid in ipairs(raidContainers) do
            frames = fsFrame:ExtractUnitFrames(raid.Frame, true, true, true, true)

            if frames and #frames > 0 then
                return sort and VisualOrder(frames) or frames
            end
        end

        local partyContainers = fsEnumerable
            :From(containers)
            :Where(function(container)
                return container.LayoutType ~= fsFrame.LayoutType.NameList and container.Type == fsFrame.ContainerType.Party
            end)
            :ToTable()

        for _, party in ipairs(partyContainers) do
            frames = fsFrame:ExtractUnitFrames(party.Frame, true, true, true, true)

            if frames and #frames > 0 then
                return sort and VisualOrder(frames) or frames
            end
        end
    end

    return {}
end

---Returns an array of arena frames sorted by their visual order.
---Prefers blizzard frames over other providers.
---@return table
function M:ArenaFrames()
    -- in bgs we get rubbish unit ids like "raid4target" and "nameplate1" from some frame providers
    -- so only get arena frames if we're actually in arena
    local enabled = fsCompare:EnemySortMode()

    if not enabled then
        return {}
    end

    local frames = nil

    -- prefer Blizzard frames
    if fsProviders.Blizzard:Enabled() then
        frames = fsFrame:ArenaFrames(fsProviders.Blizzard, true)
    end

    if not frames or #frames == 0 then
        local nonBlizzard = fsEnumerable
            :From(fsProviders:EnabledNotSelfManaged())
            :Where(function(provider)
                return provider ~= fsProviders.Blizzard
            end)
            :ToTable()

        for _, provider in ipairs(nonBlizzard) do
            frames = fsFrame:ArenaFrames(provider, true)

            if #frames > 0 then
                break
            end
        end
    end

    if not frames or #frames == 0 then
        return {}
    end

    return VisualOrder(frames)
end
