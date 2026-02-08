local _, addon = ...

KrowiEVU_SearchBoxMixin = {}

local previousFilter, previousUnitName

local function RestorePreviousFilter()
    KrowiEVU_FilterButton:SetFilter(previousFilter)
end

function KrowiEVU_SearchBoxMixin:OnLoad()
    self.clearButton:SetScript('OnClick', function(selfFunc)
        SearchBoxTemplateClearButton_OnClick(selfFunc)
        if GetMerchantFilter() == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'] then
            RestorePreviousFilter()
        end
    end)
end

function KrowiEVU_SearchBoxMixin:OnTextChanged()
	SearchBoxTemplate_OnTextChanged(self)

	if self:HasFocus() then
        KrowiEVU_FilterButton:SetFilter(_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'])
	end
end

function KrowiEVU_SearchBoxMixin:ClearSearchBox()
    SearchBoxTemplate_ClearText(self)
end

function KrowiEVU_SearchBoxMixin:OnEditFocusGained()
    if self:GetText() ~= '' then
        return
    end
    previousFilter = GetMerchantFilter()
end

hooksecurefunc('MerchantFrame_SetFilter', function(self, filter)
	if not filter then
		return
	end
	if filter ~= _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'] then
        KrowiEVU_SearchBox:ClearSearchBox()
    end
end)

MerchantFrame:HookScript('OnShow', function(self)
    local currentNpcName = UnitName('npc')

    -- Scenario 1: RememberSearch=true AND RememberSearchBetweenVendors=true → keep search across all vendors
    if addon.Options.db.profile.RememberSearch and addon.Options.db.profile.RememberSearchBetweenVendors then
        previousUnitName = currentNpcName
        return
    end

    -- Scenario 2: RememberSearch=true AND RememberSearchBetweenVendors=false AND same NPC → keep search
    if addon.Options.db.profile.RememberSearch and not addon.Options.db.profile.RememberSearchBetweenVendors
    and previousUnitName == currentNpcName then
        return
    end

    -- Scenario 3: RememberSearch=true AND RememberSearchBetweenVendors=false AND different NPC AND has search → clear
    -- Scenario 4: RememberSearch=false → always clear
    previousUnitName = currentNpcName
    if KrowiEVU_SearchBox:GetText() ~= '' then
        KrowiEVU_SearchBox:ClearSearchBox()
        if GetMerchantFilter() == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'] then
            RestorePreviousFilter()
        end
    end
end)

-- MerchantFrame:HookScript('OnHide', function(self)
--     if addon.Options.db.profile.RememberSearch then
--         return
--     end
--     KrowiEVU_SearchBox:ClearSearchBox()
--     if GetMerchantFilter() == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'] then
--         RestorePreviousFilter()
--     end
-- end)