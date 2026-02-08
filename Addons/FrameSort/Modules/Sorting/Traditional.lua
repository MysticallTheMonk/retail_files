---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsCompare = addon.Modules.Sorting.Comparer
local fsFrame = addon.WoW.Frame
local fsLog = addon.Logging.Log
local M = {}
addon.Modules.Sorting.Traditional = M

---Attempts to sort Blizzard party frames.
---@return boolean sorted true if sorted, otherwise false.
function M:TrySort()
    local friendlyEnabled, _, _, _ = fsCompare:FriendlySortMode()

    if not friendlyEnabled then
        return false
    end

    local start = wow.GetTimePreciseSec()
    local sorted = false
    local sortFunction = fsCompare:SortFunction()

    if sortFunction == nil then
        return false
    end

    if wow.CompactRaidFrameContainer and not fsFrame:IsForbidden(wow.CompactRaidFrameContainer) and wow.CompactRaidFrameContainer:IsVisible() and wow.CompactRaidFrameContainer.SetFlowSortFunction then
        wow.CompactRaidFrameContainer:SetFlowSortFunction(sortFunction)
        sorted = true
    end

    if wow.CompactPartyFrame and not fsFrame:IsForbidden(wow.CompactPartyFrame) and wow.CompactPartyFrame:IsVisible() and wow.CompactPartyFrame.SetFlowSortFunction then
        wow.CompactPartyFrame:SetFlowSortFunction(sortFunction)
        sorted = true
    end

    if wow.CompactRaidFrameContainer and not fsFrame:IsForbidden(wow.CompactRaidFrameContainer) and wow.CompactRaidFrameContainer:IsVisible() and wow.CompactRaidFrameContainer_SetFlowSortFunction then
        wow.CompactRaidFrameContainer_SetFlowSortFunction(wow.CompactRaidFrameContainer, sortFunction)
        sorted = true
    end

    local stop = wow.GetTimePreciseSec()
    fsLog:Debug("Traditional sort took %fms, result: %s.", (stop - start) * 1000, sorted and "sorted" or "not sorted")

    return sorted
end
