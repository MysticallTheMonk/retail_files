local AddonName, Data = ...

Data.Mixins = Data.Mixins or {}

local SelectedIconButtonMixin = {};

function SelectedIconButtonMixin:SetIconTexture(iconTexture)
	self.Icon:SetTexture(iconTexture);
end

function SelectedIconButtonMixin:GetIconTexture()
	return self.Icon:GetTexture();
end

function SelectedIconButtonMixin:OnClick()
	if ( self:GetIconSelectorPopupFrame():GetSelectedIndex() == nil ) then
		return;
	end

	self:GetIconSelectorPopupFrame().IconSelector:ScrollToSelectedIndex();
end

function SelectedIconButtonMixin:GetIconSelectorPopupFrame()
	return self.selectedIconButtonIconSelector;
end

function SelectedIconButtonMixin:SetIconSelector(iconSelector)
	self.selectedIconButtonIconSelector = iconSelector;
end

Data.Mixins.BackportedSelectedIconButtonMixin = SelectedIconButtonMixin