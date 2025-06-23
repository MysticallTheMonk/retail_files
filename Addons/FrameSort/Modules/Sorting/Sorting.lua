---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsLog = addon.Logging.Log
local fsConfig = addon.Configuration
local callbacks = {}
local M = addon.Modules.Sorting

---Calls the post sorting callbacks.
function M:NotifySorted()
    for _, callback in ipairs(callbacks) do
        pcall(callback)
    end
end

---Register a callback to invoke after sorting has been performed.
---@param callback function
function M:RegisterPostSortCallback(callback)
    callbacks[#callbacks + 1] = callback
end

---Attempts to sort all frames.
---@return boolean sorted true if sorted, otherwise false.
---@param provider FrameProvider? optionally specify the provider to sort, otherwise sorts all providers.
function M:Run(provider)
    assert(not wow.InCombatLockdown())

    if wow.IsRetail() and wow.EditModeManagerFrame.editModeActive then
        fsLog:Debug("Not sorting while edit mode active.")
        return
    end

    local start = wow.GetTimePreciseSec()
    local sorted = false

    if addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Traditional then
        sorted = M.Traditional:TrySort()
    elseif addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Secure then
        sorted = M.Secure:TrySort(provider)
    end

    local stop = wow.GetTimePreciseSec()
    fsLog:Debug(string.format("Sort took %fms, result: %s.", (stop - start) * 1000, sorted and "sorted" or "not sorted"))

    if sorted then
        M:NotifySorted()
    end
end

---Initialises the module.
function M:Init()
    if addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Secure then
        M.Secure:Init()
    end
end
