local _, addon = ...
addon.Gui.SearchBox = {}
local searchBox = addon.Gui.SearchBox

local offsetX, offsetY
local function CreateModern(self)
    CreateFrame('EditBox', 'KrowiEVU_SearchBox', MerchantFrame, 'KrowiEVU_SearchBox_Template')
    offsetX, offsetY = -6, 1
    self:ResetPointOffset()
end

local function CreateClassic(self)
    CreateFrame('EditBox', 'KrowiEVU_SearchBox', MerchantFrame, 'KrowiEVU_SearchBox_Template')
    offsetX, offsetY = -10, 1
    self:ResetPointOffset()
end

function searchBox:Load()
	if addon.Util.IsMainline then
        CreateModern(self)
    else
        CreateClassic(self)
    end
end

function searchBox:SetPointOffset(x, y)
    KrowiEVU_SearchBox:ClearAllPoints()
    KrowiEVU_SearchBox:SetPoint('RIGHT', KrowiEVU_FilterButton, 'LEFT', x or offsetX or 0, y or offsetY or 0)
end

function searchBox:ResetPointOffset()
    KrowiEVU_SearchBox:ClearAllPoints()
    KrowiEVU_SearchBox:SetPoint('RIGHT', KrowiEVU_FilterButton, 'LEFT', offsetX or 0, offsetY or 0)
end

function searchBox:SetPointOffsetXY(x, y)
    offsetX, offsetY = x or offsetX, y or offsetY
    self:ResetPointOffset()
end