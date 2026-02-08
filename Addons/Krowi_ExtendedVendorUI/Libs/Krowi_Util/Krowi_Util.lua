--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:NewLibrary('Krowi_Util_2', 1, {
    SetCurrent = true,
    -- InitLocalization = true, -- Handled in LocalizationHelper sub module
})
if not lib then	return end

KROWI_LIBMAN:SetUtil(lib)

local version = (GetBuildInfo())
local majorVersion = string.match(version, '(%d+)%.(%d+)%.(%d+)(%w?)')
lib.IsMistsClassic = majorVersion == '5'
lib.IsClassicWithAchievements = lib.IsMistsClassic
lib.IsTheWarWithin = majorVersion == '11'
lib.IsMidnight = majorVersion == '12'
lib.IsMainline = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

function lib.ConcatTables(t1, t2)
    if t2 then
        for _, e in next, t2 do
            tinsert(t1, e)
        end
    end
    return t1
end

function lib.InjectMetatable(tbl, meta)
    return setmetatable(tbl, setmetatable(meta, getmetatable(tbl)))
end

function lib.DeepCopyTable(src, dest)
	for index, value in pairs(src) do
		if type(value) == 'table' then
			dest[index] = {}
			lib.DeepCopyTable(value, dest[index])
		else
			dest[index] = value
		end
	end
end

function lib.ReadNestedKeys(tbl, keys)
    for _, k in ipairs(keys) do
       tbl = tbl[k]
       if tbl == nil then
          break
       end
    end
    return tbl
 end

function lib.WriteNestedKeys(tbl, keys, value)
    local prev_tbl, last_k
    for _, k in ipairs(keys) do
       last_k, prev_tbl, tbl = k, tbl, tbl[k]
       if tbl == nil then
          tbl = {}
          prev_tbl[k] = tbl
       end
    end
    prev_tbl[last_k] = value
 end

function lib.Enum(table)
    for i, element in next, table do
        local tmp = element
        table[tmp] = i
    end
    return table
end

function lib.Enum2(table)
    local tbl = {}
    for i, element in next, table do
        local tmp = element
        tbl[tmp] = i
    end
    return tbl
end

function lib.StringSplitTable(delimiter, str)
    local chunks = {}
    for s in string.gmatch(str, '([^' .. delimiter .. ']+)') do
        tinsert(chunks, s)
    end
    return chunks
end

lib.DelayObjects = {}
function lib.DelayFunction(delayObjectName, delayTime, func, ...)
    if lib.DelayObjects[delayObjectName] ~= nil then
        return
    end
    local args = {...}
    lib.DelayObjects[delayObjectName] = C_Timer.NewTimer(delayTime, function()
        func(unpack(args))
        lib.DelayObjects[delayObjectName] = nil
    end)
end

function lib.TableRemoveByValue(table, value)
    for key, _value in pairs(table) do
        if _value == value then
            tremove(table, key)
            return true
        end
    end
    return false
end

function lib.TableFindKeyByValue(table, value)
    for key, _value in next, table do
        if _value == value then
            return key
        end
    end
end

function lib.SafeGet(source, path)
    local current = source
    for _, key in next, path do
        current = current[key]
        if current == nil then
            return nil
        end
    end
    return current
end

function lib.IsType(value, _type)
    return type(value) == _type
end

function lib.IsNil(value)
    return lib.IsType(value, 'nil')
end

function lib.IsNumber(value)
    return lib.IsType(value, 'number')
end

function lib.IsString(value)
    return lib.IsType(value, 'string')
end

function lib.IsBoolean(value)
    return lib.IsType(value, 'boolean')
end

function lib.IsTable(value)
    return lib.IsType(value, 'table')
end

function lib.IsFunction(value)
    return lib.IsType(value, 'function')
end

function lib.IsThread(value)
    return lib.IsType(value, 'thread')
end

function lib.IsUserData(value)
    return lib.IsType(value, 'userdata')
end