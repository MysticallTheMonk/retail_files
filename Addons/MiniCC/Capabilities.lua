---@type string, Addon
local _, addon = ...

---@class Capabilities
local M = {}

addon.Capabilities = M

local hasNewFilters

function M:HasNewFilters()
	return hasNewFilters
end

local _, _, _, build = GetBuildInfo()
hasNewFilters = build >= 120001
