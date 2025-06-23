-- [[ Namespaces ]] --
local _, addon = ...;

KrowiEVU_SearchBoxMixin = {};

local previousFilter;
local function StorePreviousFilter()
    local currentFilter = GetMerchantFilter();
    if currentFilter == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_SEARCH"] then
        return;
    end
    previousFilter = currentFilter;
end

local function RestorePreviousFilter()
    MerchantFrame_SetFilter(nil, previousFilter);
end

function KrowiEVU_SearchBoxMixin:OnLoad()
    self.clearButton:SetScript("OnClick", function(selfFunc)
        SearchBoxTemplateClearButton_OnClick(selfFunc);
        RestorePreviousFilter();
    end);
end

function KrowiEVU_SearchBoxMixin:OnShow()
    local clearSearchBox = self.clearButton:GetScript("OnClick");
    clearSearchBox(self.clearButton);
end

function KrowiEVU_SearchBoxMixin:OnTextChanged()
	SearchBoxTemplate_OnTextChanged(self);

	if self:HasFocus() then
        StorePreviousFilter();
		MerchantFrame_SetFilter(nil, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_SEARCH"]);
	end
end