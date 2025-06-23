---@type string, Namespace
local _, ns = ...

local Masque = LibStub('Masque', true)

local icons = nil

---@class MasqueHelper
local masqueHelper = {}
ns.masqueHelper = masqueHelper

if Masque then
    icons = Masque:Group("TrufiGCD", "All Icons")
end

function masqueHelper.addIcon(frame, texture)
    if icons then
        icons:AddButton(frame, {Icon = texture})
    end
end

function masqueHelper.reskinIcons()
    if icons then
        icons:ReSkin()
    end
end
