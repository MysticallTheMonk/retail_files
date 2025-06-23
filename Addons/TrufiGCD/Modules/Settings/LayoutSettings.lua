---@type string, Namespace
local _, ns = ...

---@class LayoutSettings
---@field enable boolean
---@field direction Direction
---@field iconSize number Icon size
---@field iconsNumber number Unit frame width in icons number
local LayoutSettings = {}
LayoutSettings.__index = LayoutSettings
ns.LayoutSettings = LayoutSettings

function LayoutSettings:New()
    ---@class LayoutSettings
    local obj = setmetatable({}, LayoutSettings)
    obj.enable = false
    obj.direction = "Left"
    obj.iconSize = 30
    obj.iconsNumber = 3
    return obj
end

function LayoutSettings:GetSavedVariables()
    ---@type LayoutVariablesV2
    local layoutSaves = {}
    layoutSaves.enable = self.enable
    layoutSaves.direction = self.direction
    layoutSaves.iconSize = self.iconSize
    layoutSaves.iconsNumber = self.iconsNumber
    return layoutSaves
end

---@param savedVariables UnitVariablesV1 | LayoutVariablesV2
function LayoutSettings:SetFromSavedVariables(savedVariables)
    if type(savedVariables.enable) == "boolean" then
        self.enable = savedVariables.enable
    end
    if type(savedVariables.direction) == "string" then
        self.direction = savedVariables.direction
    end
    if type(savedVariables.iconSize) == "number" then
        self.iconSize = savedVariables.iconSize
    end
    if type(savedVariables.iconsNumber) == "number" then
        self.iconsNumber = savedVariables.iconsNumber
    end

    -- Suppoort for V1 variables
    if type(savedVariables.fade) == "string" then
        self.direction = savedVariables.fade
    end
    if type(savedVariables.size) == "number" then
        self.iconSize = savedVariables.size
    end
    if type(savedVariables.width) == "number" then
        self.iconsNumber = savedVariables.width
    end
end
