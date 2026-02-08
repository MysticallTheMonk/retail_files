---@type string, Addon
local _, addon = ...
---@class LuaEx
local M = {}

addon.Language.LuaEx = M

---Returns the result of a property chain e.g. Something.else.a.b.c
---Otherwise nil if any of the fields are nil
---@param root table root of the property chain
---@param chain table<string> list of properties to evaluate
---@return any
function M:SafeGet(root, chain)
    if not root or not chain then
        return nil
    end

    local next = root

    for _, k in ipairs(chain) do
        next = next[k]

        if next == nil then
            return nil
        end
    end

    return next
end
