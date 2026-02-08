--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global
---@diagnostic disable: duplicate-set-field

-- ONLY USED BY KROWIS ACHIEVEMENT FILTER, REFACTOR AND REMOVE THIS FILE LATER

local sub, parent = KROWI_LIBMAN:NewSubmodule('MenuUtil', 0)
if not sub or not parent then return end

do -- Modern
    function sub:CreateTitle(menu, text)
        menu:CreateTitle(text)
    end

    function sub:CreateButton(menu, text, func, isEnabled)
        local button = menu:CreateButton(text, func)
        if isEnabled == false then
            button:SetEnabled(false)
        end
        return button
    end

    function sub:CreateDivider(menu)
        menu:CreateDivider()
    end

    function sub:AddChildMenu(menu, child)

    end

    function sub:CreateButtonAndAdd(menu, text, func, isEnabled)
        return self:CreateButton(menu, text, func, isEnabled)
    end
end

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    return
end

do -- Classic
    function sub:CreateTitle(menu, text)
        menu:AddTitle(text)
    end

    function sub:CreateButton(menu, text, func, isEnabled)
        return parent.MenuItem:New({
            Text = text,
            Func = func,
            Disabled = isEnabled == false
        })
    end

    function sub:CreateDivider(menu)
        menu:AddSeparator()
    end

    function sub:AddChildMenu(menu, child)
        if not menu or not child then
            return
        end
        menu:Add(child)
    end

    function sub:CreateButtonAndAdd(menu, text, func, isEnabled)
        self:AddChildMenu(menu, self:CreateButton(nil, text, func, isEnabled))
    end
end