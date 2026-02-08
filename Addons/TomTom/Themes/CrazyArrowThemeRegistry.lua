--[[--------------------------------------------------------------------------
--  TomTom by Cladhaire <cladhaire@gmail.com>
--
--  All Rights Reserved
----------------------------------------------------------------------------]]

local addonName, addon = ...

local handler = {
    themes = {},
    active = nil,
    recent = nil,
    activeKey = nil,
}

addon.CrazyArrowThemeHandler = handler

function handler:RegisterCrazyArrowTheme(key, name, themeTbl)
    self.themes[key] = {name = name, tbl = themeTbl}
end

function handler:GetActiveTheme()
    return self.activeKey
end

function handler:SetActiveTheme(button, key, arrival)
    if self.activeKey == key then
        -- Do nothing
        return
    end

    if self.activeKey then
        -- If there was a previous theme selected, unload the current one
        self.active.tbl:RemoveTheme(button)
    end

    self.activeKey = key
    self.active = self.themes[key]
    self.active.tbl:ApplyTheme(button)

    if arrival then
        self:SwitchToArrivalArrow(button)
    end
end

function handler:CrazyArrow_RemoveTheme(button)
    self.active.tbl:RemoveTheme(button)
end

function handler:SwitchToArrivalArrow(button)
    if self.active and self.active.tbl then
        self.active.tbl:SwitchToArrivalArrow(button)
    end
end

function handler:ArrivalArrow_OnUpdate(elapsed)
    if self.active and self.active.tbl then
        self.active.tbl:ArrivalArrow_OnUpdate(elapsed)
    end
end

function handler:SwitchToNavigationArrow(button)
    if self.active and self.active.tbl then
        self.active.tbl:SwitchToNavigationArrow(button)
    end
end

function handler:NavigationArrow_OnUpdate(elapsed, angle)
    if self.active and self.active.tbl then
        self.active.tbl:NavigationArrow_OnUpdate(elapsed, angle)
    end
end

