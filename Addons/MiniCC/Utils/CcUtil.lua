---@type string, Addon
local _, addon = ...
local capabilities = addon.Capabilities

---@class CcUtil
local M = {}

addon.Utils.CcUtil = M

---@param list AuraInfo[]
---@return number 0 or 1
local function CcAlphaModern(list)
	for _, info in ipairs(list) do
		if info.IsCC then
			return 1
		end
	end

	return 0
end

---@param list AuraInfo[]
---@return number 0 or 1
local function CcAlphaPrepatch(list)
	local result = 0
	local booleans = {}

	for _, info in ipairs(list) do
		booleans[#booleans + 1] = info.IsCC
	end

	-- collapse the set of secret booleans into a 1 or 0
	local ev = C_CurveUtil.EvaluateColorValueFromBoolean

	for _, b in ipairs(booleans) do
		result = ev(b, 1, result)
	end

	return result
end

---Returns a potentially secret number if any of the specified auras have CC applied.
---@param auras AuraInfo|AuraInfo[]
---@return number 0 or 1
function M:IsCcAppliedAlpha(auras)
	---@type AuraInfo[]
	local list = auras[1] ~= nil and auras or { auras }

	if capabilities:HasNewFilters() then
		return CcAlphaModern(list)
	else
		return CcAlphaPrepatch(list)
	end
end
