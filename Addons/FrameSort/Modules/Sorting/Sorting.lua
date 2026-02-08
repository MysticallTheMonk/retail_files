---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local capabilities = addon.WoW.Capabilities
local fsLog = addon.Logging.Log
local fsConfig = addon.Configuration
local fsProviders = addon.Providers
local callbacks = {}
local M = addon.Modules.Sorting

---Calls the post sorting callbacks.
function M:NotifySorted()
    for _, callback in ipairs(callbacks) do
        local ok, err = pcall(callback)
        if not ok then
            fsLog:Error("NotifySorted callback failed: %s.", tostring(err))
        end
    end
end

---Register a callback to invoke after sorting has been performed.
---@param callback function
function M:RegisterPostSortCallback(callback)
    if not callback then
        fsLog:Error("Sorting:RegisterPostSortCallback() - callback must not be nil.")
        return
    end

    callbacks[#callbacks + 1] = callback
end

---Attempts to sort all frames.
---@return boolean sorted true if sorted, otherwise false.
---@param provider FrameProvider? optionally specify the provider to sort, otherwise sorts all providers.
function M:Run(provider)
    if wow.InCombatLockdown() then
        fsLog:Error("Cannot run non-combat sorting module during combat.")
        return
    end

    if capabilities.HasEditMode() and wow.EditModeManagerFrame and wow.EditModeManagerFrame.editModeActive then
        fsLog:Debug("Not sorting while edit mode active.")
        return
    end

    local sorted = false

    if addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Traditional then
        sorted = M.Traditional:TrySort()
    elseif addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Secure then
        sorted = M.Secure:TrySort(provider)
    end

    sorted = fsProviders:RequestSelfManagedProvidersSort() or sorted

    if sorted then
        M:NotifySorted()
    end
end

---Initialises the module.
function M:Init()
    if addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Secure then
        M.Secure:Init()
        fsLog:Debug("Initialised the secure sorting module.")
    else
        fsLog:Debug("Initialised the traditional sorting module.")
    end
end
