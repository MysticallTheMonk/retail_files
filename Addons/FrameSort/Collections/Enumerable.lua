---@type string, Addon
local _, addon = ...

---@class Enumerable
---@field Next function
---@field State table
local M = {}
local metatable = {
    __index = M,
}

addon.Collections.Enumerable = M

---Returns an Enumerable instance from the specified items.
---@param auto table|function
---@return Enumerable
function M:From(auto)
    assert(auto ~= nil)

    local t = type(auto)
    local enumerable = {}

    if t == "function" then
        enumerable.Next = auto
    elseif t == "table" then
        if auto.Next and type(auto.Next) == "function" then
            -- wrap it to preserve 'self'
            enumerable.Next = function()
                return auto.Next(auto)
            end
        else
            local iterator, elements, index = ipairs(auto)
            enumerable.State = {
                Iterator = iterator,
                Elements = elements,
                Index = index,
            }
            enumerable.Next = function()
                if #enumerable.State.Elements == 0 then
                    return nil
                end

                local nextIndex, next = iterator(enumerable.State.Elements, enumerable.State.Index)
                enumerable.State.Index = nextIndex
                return next
            end
        end
    else
        error(string.format("Invalid type %s", t))
    end

    return setmetatable(enumerable, metatable)
end

---Returns a new Enumerable instance.
---@return Enumerable
function M:New()
    return M:From({})
end

---Maps a sequence from one type into another.
---@param apply fun(item: any): any
---@return Enumerable
function M:Map(apply)
    assert(apply ~= nil)

    local iterator = function()
        local next = self.Next()
        if next == nil then
            return nil
        end

        return apply(next)
    end

    return M:From(iterator)
end

---Flattens a sequence of arrays to a single array.
---@return Enumerable
function M:Flatten()
    local next = nil
    local index = nil

    local iterator = function()
        local item = nil

        while item == nil do
            if not index or index > #next then
                next = self.Next()
                index = 1
            end

            if next == nil then
                return nil
            end

            if type(next) ~= "table" then
                return nil
            end

            item = next[index]
            index = index + 1
        end

        return item
    end

    return M:From(iterator)
end

---Filters a sequence.
---@param predicate fun(item: any): boolean?
---@return Enumerable
function M:Where(predicate)
    assert(predicate ~= nil)

    local iterator = function()
        local next = self.Next()

        while next and not predicate(next) do
            next = self.Next()
        end

        return next
    end

    return M:From(iterator)
end

---Returns the nth instance that matches the predicate.
---@param n number
---@param predicate fun(item: any): boolean
---@return any? item, number? index
function M:Nth(n, predicate)
    assert(predicate ~= nil)

    local found = 0

    while n > found do
        local item = self.Next()

        if not item then
            return nil
        end

        if predicate(item) then
            found = found + 1

            if n == found then
                return item
            end
        end
    end

    return nil
end

---Returns the first instance that matches the predicate.
---@param predicate? fun(item: any): boolean
---@return any? item, number? index
function M:First(predicate)
    local next = self.Next()
    local index = 1

    if predicate then
        while next and not predicate(next) do
            next = self.Next()
            index = index + 1
        end
    end

    return next, next and index or nil
end

---Returns the last instance that matches the predicate.
---@param predicate? fun(item: any): boolean
---@return any? item, number? index
function M:Last(predicate)
    local next = self.Next()
    local nextIndex = 1
    local last = nil
    local lastIndex = 1

    while next do
        if not predicate or predicate(next) then
            last = next
            lastIndex = nextIndex
        end

        next = self.Next()
        nextIndex = nextIndex + 1
    end

    return last, last and lastIndex or nil
end

---Returns true if any item matches the predicate, or if no predicate is provided then returns true if any item exists.
---@param predicate? fun(item: any): boolean
---@return any? item, number? index
function M:Any(predicate)
    return self:First(predicate) ~= nil
end

---Returns true if all items match the predicate.
---@param predicate fun(item: any): boolean
---@return boolean
function M:All(predicate)
    assert(predicate ~= nil)

    local next = self.Next()

    if next == nil then
        return false
    end

    while next do
        if not predicate(next) then
            return false
        end

        next = self.Next()
    end

    return true
end

---Returns the first index that matches the predicate.
---@param item any
---@return any? number? index
function M:IndexOf(item)
    assert(item ~= nil)

    local _, index = self:First(function(x)
        return x == item
    end)

    return index
end

---Returns the last index that matches the predicate.
---@param item any
---@return any? number? index
function M:LastIndexOf(item)
    assert(item ~= nil)

    local _, index = self:Last(function(x)
        return x == item
    end)

    return index
end

---Returns the item with the minimum value.
---@param valueSelector? fun(item: any): any
---@return any? item
function M:Min(valueSelector)
    local items = self:ToTable()

    if #items == 0 then
        return nil
    end

    local minItem = items[1]
    local minValue = valueSelector and valueSelector(minItem) or minItem

    for i = 2, #items do
        local nextItem = items[i]
        local min = valueSelector and valueSelector(nextItem) or nextItem

        if min < minValue then
            minItem = nextItem
            minValue = min
        end
    end

    return minItem
end

---Returns the item with the maximum value.
---@param valueSelector? fun(item: any): any
---@return any? item
function M:Max(valueSelector)
    local items = self:ToTable()

    if #items == 0 then
        return nil
    end

    local maxItem = items[1]
    local maxValue = valueSelector and valueSelector(maxItem) or maxItem

    for i = 2, #items do
        local nextItem = items[i]
        local max = valueSelector and valueSelector(nextItem) or nextItem

        if max > maxValue then
            maxItem = nextItem
            maxValue = max
        end
    end

    return maxItem
end

---Sums a sequence.
---@param valueSelector? fun(item: any): number
---@return number
function M:Sum(valueSelector)
    local items = self:ToTable()
    local sum = 0

    for _, item in ipairs(items) do
        sum = sum + ((valueSelector and valueSelector(item)) or item)
    end

    return sum
end

---Reverses the sequence.
function M:Reverse()
    local items = self:ToTable()
    local index = #items

    local iterator = function()
        if index == 0 then
            return nil
        end

        local next = items[index]
        index = index - 1

        return next
    end

    return M:From(iterator)
end

---Evaluates the iterator function to return the results as a table.
---@return table items
function M:ToTable()
    local items = {}
    local next = self.Next()

    while next do
        items[#items + 1] = next
        next = self.Next()
    end

    return items
end

---Returns the first `count` number of items.
---@param count number
---@return Enumerable
function M:Take(count)
    if count == 0 then
        return M:From({})
    end

    local taken = 0
    local iterator = function()
        if taken == count then
            return nil
        end

        local next = self.Next()
        if next == nil then
            return nil
        end

        taken = taken + 1
        return next
    end

    return M:From(iterator)
end

---Evaluates the iterator function to return the results as a dictionary.
---@param keySelector function(item: any, index: number): any
---@param valueSelector function(item: any, index: number, existingItem: any?): any
---@return table items
function M:ToDictionary(keySelector, valueSelector)
    assert(keySelector ~= nil)
    assert(valueSelector ~= nil)

    local items = self:ToTable()
    local dict = {}

    for index, item in ipairs(items) do
        local key = keySelector(item, index)
        local existingItem = dict[key]
        local value = valueSelector(item, index, existingItem)

        dict[key] = value
    end

    return dict
end

---Orders the enumable using the specified comparison function.
---@generic T
---@param compare? fun(a: T, b: T):boolean
function M:OrderBy(compare)
    assert(compare ~= nil)

    local items = self:ToTable()
    table.sort(items, compare)

    return M:From(items)
end

---Combines two sequences together.
---@param other table|function
function M:Concat(other)
    assert(other ~= nil)

    local enumerable = M:From(other)
    local finishedFirst = false
    local iterator = function()
        if not finishedFirst then
            local item = self.Next()

            if item then
                return item
            end

            finishedFirst = true
        end

        return enumerable.Next()
    end

    return M:From(iterator)
end

---Produces a distinct set of results.
function M:Distinct()
    local seen = {}
    return self:Where(function(item)
        if seen[item] then
            return false
        end

        seen[item] = true
        return true
    end)
end
