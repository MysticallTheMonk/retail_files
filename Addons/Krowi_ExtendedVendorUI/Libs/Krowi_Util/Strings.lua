--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local sub, parent = KROWI_LIBMAN:NewSubmodule('Strings', 0)
if not sub or not parent then return end

local varPattern = '({([^}]+)})'

function sub.ReplaceVars(str, vars)
    -- Allow ReplaceVars{str, vars} syntax as well as ReplaceVars(str, {vars})
    if not vars then
        vars = str
        str = vars[1]
    end
    if type(vars) == 'table' then
        return (string.gsub(str, varPattern, function(whole, i)
            return vars[i] or whole
        end))
    else
        -- Non-table case: replace all placeholders with same value
        return (string.gsub(str, varPattern, function()
            return vars
        end))
    end
end
string.K_ReplaceVars = sub.ReplaceVars

local reloadSuffix
function sub.AddReloadRequired(str)
    if not reloadSuffix then
        reloadSuffix = '\n\n' .. parent.L['Requires a reload']
    end
    return str .. reloadSuffix
end
string.K_AddReloadRequired = sub.AddReloadRequired

local defaultValuePrefix, checkedText, uncheckedText
function sub.AddDefaultValueText(str, startTbl, valuePath, values)
    if not defaultValuePrefix then
        defaultValuePrefix = '\n\n' .. parent.L['Default value'] .. ': '
        checkedText = parent.L['Checked']
        uncheckedText = parent.L['Unchecked']
    end
    local value = startTbl
    local pathParts = strsplittable('.', valuePath)
    for _, part in next, pathParts do
        local numPart = tonumber(part)
        value = value[numPart or part]
    end
    if type(value) == 'boolean' then
        value = value and checkedText or uncheckedText
    end
    if values then
        value = values[value]
    end
    return str .. defaultValuePrefix .. tostring(value)
end
string.K_AddDefaultValueText = sub.AddDefaultValueText