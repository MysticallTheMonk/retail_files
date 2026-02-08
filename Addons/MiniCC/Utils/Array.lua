---@type string, Addon
local _, addon = ...

---@class ArrayUtil
local M = {}

addon.Utils.Array = M

function M:Reverse(array)
	local i, j = 1, #array
	while i < j do
		array[i], array[j] = array[j], array[i]
		i = i + 1
		j = j - 1
	end
	return array
end

function M:Append(src, dst)
	for i = 1, #src do
		dst[#dst + 1] = src[i]
	end
end
