---@typ string, Addon
local _, addon = ...
---@class Math
local M = {}
addon.Numerics.Math = M

---Rounds a number to the specified number of decimal places
---@param number number the number to round
---@param decimalPlaces number? the number of decimal places
---@return number
function M:Round(number, decimalPlaces)
    local mult = 10 ^ (decimalPlaces or 0)
    return math.floor(number * mult + 0.5) / mult
end
