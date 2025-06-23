---@type string, Addon
local _, addon = ...
local M = addon.Modules.Sorting.Secure

function M:Init()
    M.InCombat:Init()
end

---@param provider FrameProvider?
---@return boolean
function M:TrySort(provider)
    return M.NoCombat:TrySort(provider)
end
