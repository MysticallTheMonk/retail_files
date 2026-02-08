--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local sub = KROWI_LIBMAN:NewSubmodule('MenuItem', 0)
if not sub then return end

sub.__index = sub
function sub:New(info, hideOnClick)
    local instance = setmetatable({}, sub)
    if type(info) == 'string' then
        info = {
            Text = info,
            KeepShownOnClick = not hideOnClick
        }
    end
    for k, v in next, info do
        instance[k] = v
    end
    return instance
end

function sub:Add(item)
    if self.Children == nil then
        self.Children = {} -- By creating the children table here we reduce memory usage because not every category has children
    end
    tinsert(self.Children, item)
    return item
end

function sub:AddFull(info)
    return self:Add(self:New(info))
end

function sub:AddTitle(text)
    self:AddFull({
		Text = text,
		IsTitle = true
	})
end

function sub:AddSeparator()
    return self:AddFull({IsSeparator = true})
end