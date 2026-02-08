local _, addon = ...
addon.Gui.OptionsButton = {}
local optionsButton = addon.Gui.OptionsButton

local offsetX, offsetY
local function CreateModern(self)
    CreateFrame('DropdownButton', 'KrowiEVU_OptionsButton', MerchantFrame, 'KrowiEVU_OptionsButton_Modern_Template')
    offsetX, offsetY = -11, 0
    self:ResetPointOffset()
end

local function CreateClassic(self)
    CreateFrame('DropDownToggleButton', 'KrowiEVU_OptionsButton', MerchantFrame, 'KrowiEVU_OptionsButton_Classic_Template')
    offsetX, offsetY = -14, 0
    self:ResetPointOffset()
end

function optionsButton:Load()
	if addon.Util.IsMainline then
        CreateModern(self)
    else
        CreateClassic(self)
    end
    KrowiEVU_OptionsButton:ShowHide()
end

function optionsButton:SetPointOffset(x, y)
    KrowiEVU_OptionsButton:ClearAllPoints()
    KrowiEVU_OptionsButton:SetPoint('RIGHT', KrowiEVU_SearchBox, 'LEFT', x or offsetX or 0, y or offsetY or 0)
end

function optionsButton:ResetPointOffset()
    KrowiEVU_OptionsButton:ClearAllPoints()
    KrowiEVU_OptionsButton:SetPoint('RIGHT', KrowiEVU_SearchBox, 'LEFT', offsetX or 0, offsetY or 0)
end