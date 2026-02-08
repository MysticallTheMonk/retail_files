local _, addon = ...
local merchantItemsContainer = addon.Gui.MerchantItemsContainer
local originalWidth, originalHeight = MerchantFrame:GetSize()
originalHeight = originalHeight + 12
originalWidth = originalWidth + 12

addon.Gui.MerchantFrame = {}
local merchantFrame = addon.Gui.MerchantFrame

do
	MerchantMoneyInset:ClearAllPoints()
	MerchantMoneyInset:SetPoint('BOTTOMRIGHT', MerchantFrame, -6, 8)
	MerchantMoneyInset:SetPoint('LEFT', MerchantFrame, 4, 0)
	MerchantMoneyInset:SetHeight(22)

	local buttonsInset = CreateFrame('Frame', 'KrowiEVU_MerchantButtonsInset', MerchantFrame, 'InsetFrameTemplate')
	buttonsInset:SetPoint('BOTTOMLEFT', MerchantMoneyInset, 'TOPLEFT', 0, 4)
	buttonsInset:SetSize(185, 52)
	local buybackInset = CreateFrame('Frame', 'KrowiEVU_MerchantBuybackInset', MerchantFrame, 'InsetFrameTemplate')
	buybackInset:SetPoint('TOPLEFT', buttonsInset, 'TOPRIGHT', 4, 0)
	buybackInset:SetPoint('BOTTOMLEFT', buttonsInset, 'BOTTOMRIGHT', 4, 0)
	buybackInset:SetWidth(149)
	local emptyInset = CreateFrame('Frame', 'KrowiEVU_MerchantEmptyInset', MerchantFrame, 'InsetFrameTemplate')
	emptyInset:SetPoint('TOPLEFT', buybackInset, 'TOPRIGHT', 4, 0)
	emptyInset:SetPoint('BOTTOMLEFT', buybackInset, 'BOTTOMRIGHT', 4, 0)
	emptyInset:SetPoint('RIGHT', MerchantMoneyInset)

	local function UpdateRepairButtons()
		MerchantRepairItemButton:ClearAllPoints()
		MerchantRepairItemButton:SetPoint('RIGHT', MerchantRepairAllButton, 'LEFT', -8, 0)
		MerchantRepairAllButton:ClearAllPoints()
		MerchantRepairAllButton:SetPoint('LEFT', buttonsInset, 52, -1) -- Start with this to not trigger Default Blizzard errors
		MerchantGuildBankRepairButton:ClearAllPoints()
		MerchantGuildBankRepairButton:SetPoint('LEFT', MerchantRepairAllButton, 'RIGHT', 8, 0)
		if addon.Util.IsMainline then
			MerchantSellAllJunkButton:ClearAllPoints()
			MerchantSellAllJunkButton:SetPoint('LEFT', MerchantGuildBankRepairButton, 'RIGHT', 8, 0)
		else
			MerchantRepairText:Hide()
		end
	end
	merchantFrame.UpdateRepairButtons = UpdateRepairButtons -- Makes placing them correctly possible via plugins like ElvUI
	hooksecurefunc('MerchantFrame_UpdateRepairButtons', UpdateRepairButtons)

	MerchantFrameInset:ClearPoint('BOTTOMRIGHT')
	MerchantFrameInset:SetPoint('RIGHT', MerchantFrame, 'RIGHT', -6, 0)
	MerchantFrameInset:SetPoint('BOTTOM', buttonsInset, 'TOP', 0, 4)

	MerchantPrevPageButton:ClearAllPoints()
	MerchantPrevPageButton:SetPoint('BOTTOMLEFT', MerchantFrameInset, 5, 2)
	MerchantNextPageButton:ClearAllPoints()
	MerchantNextPageButton:SetPoint('BOTTOMRIGHT', MerchantFrameInset, -3, 2)
	MerchantPageText:SetPoint('CENTER', MerchantFrameInset)
	MerchantPageText:SetPoint('BOTTOM', buttonsInset, 'TOP', 0, 17)

	BuybackBG:SetPoint('TOPLEFT', MerchantFrameInset)
	BuybackBG:SetPoint('BOTTOMRIGHT', MerchantFrameInset)

	if not addon.Util.IsMainline then
		MerchantFrameBtnCornerLeft:Hide()
		MerchantFrameBtnCornerRight:Hide()

		MerchantBuyBackItemNameFrame:SetWidth(112)
		MerchantBuyBackItemNameFrame:SetPoint('LEFT', MerchantBuyBackItemSlotTexture, 'RIGHT', -9, -11)
	end
end

function merchantFrame.SetMerchantFrameSize()
	if MerchantFrame.selectedTab == 1 then
		local numExtraColumns = addon.Options.db.profile.NumColumns - merchantItemsContainer.DefaultMerchantInfoNumColumns
		local numExtraRows = addon.Options.db.profile.NumRows - merchantItemsContainer.DefaultMerchantInfoNumRows
		local itemWidth = merchantItemsContainer.OffsetX + merchantItemsContainer.ItemWidth
		local itemHeight = merchantItemsContainer.OffsetMerchantInfoY + merchantItemsContainer.ItemHeight
		local width = originalWidth + numExtraColumns * itemWidth
		local height = originalHeight + numExtraRows * itemHeight + MerchantMoneyInset:GetHeight() - 23
		if not MerchantPageText:IsShown() then
			height = height - 36
		end
		MerchantFrame:SetSize(width, height)
	elseif MerchantFrame.selectedTab == 2 then
		MerchantFrame:SetSize(originalWidth, originalHeight)
	end
end

hooksecurefunc('MerchantFrame_UpdateMerchantInfo', function()
	merchantFrame.SetMerchantFrameSize()
	if addon.Util.IsMainline then
		MerchantFrame.FilterDropdown:Hide()
	end
	KrowiEVU_FilterButton:Show()
	KrowiEVU_SearchBox:Show()
	KrowiEVU_OptionsButton:ShowHide()
	local numExtraColumns = addon.Options.db.profile.NumColumns - merchantItemsContainer.DefaultMerchantInfoNumColumns
	if numExtraColumns > 0 then
		addon.Gui.OptionsButton:ResetPointOffset()
		addon.Gui.SearchBox:ResetPointOffset()
		KrowiEVU_SearchBox:SetWidth(144)
		KrowiEVU_MerchantEmptyInset:Show()
	else
		addon.Gui.OptionsButton:SetPointOffset(-7)
		addon.Gui.SearchBox:SetPointOffset(-2)
		KrowiEVU_SearchBox:SetWidth(90)
		KrowiEVU_MerchantEmptyInset:Hide()
	end
	MerchantFrameInset:SetPoint('BOTTOM', KrowiEVU_MerchantButtonsInset, 'TOP', 0, 4)
	KrowiEVU_MerchantButtonsInset:Show()
	KrowiEVU_MerchantBuybackInset:Show()
	if not addon.Util.IsMainline then
		MerchantFrameBottomRightBorder:Hide()
	end
	if MerchantToken4 then
		MerchantToken4:ClearAllPoints()
		MerchantToken4:SetPoint('BOTTOMRIGHT', -185, 8)
	end
	MerchantFrameBottomLeftBorder:Hide()
end)

hooksecurefunc('MerchantFrame_UpdateBuybackInfo', function()
	merchantFrame.SetMerchantFrameSize()
	if addon.Util.IsMainline then
		MerchantFrame.FilterDropdown:Hide()
	end
	KrowiEVU_OptionsButton:Hide()
	KrowiEVU_SearchBox:Hide()
	KrowiEVU_FilterButton:Hide()
	MerchantFrameInset:SetPoint('BOTTOM', MerchantMoneyInset, 'TOP', 0, 3)
	KrowiEVU_MerchantButtonsInset:Hide()
	KrowiEVU_MerchantBuybackInset:Hide()
	KrowiEVU_MerchantEmptyInset:Hide()
end)

addon.CachedItemIndices = {}

local function GetCachedIndex(index)
	return addon.CachedItemIndices[index] or 0
end

hooksecurefunc('MerchantFrame_UpdateAltCurrency', function(index, indexOnPage, canAfford)
	local itemCount = GetMerchantItemCostInfo(index)
	if itemCount <= 0 then
		return
	end

	local frameName = 'MerchantItem' .. indexOnPage .. 'AltCurrencyFrame'
	local usedCurrencies = 0
	for i = 1, MAX_ITEM_COST do
		local itemTexture = GetMerchantItemCostItem(index, i)
		if itemTexture then
			usedCurrencies = usedCurrencies + 1
			local button = _G[frameName..'Item'..usedCurrencies]
			button.index = GetCachedIndex(index)
		end
	end
end)

if not addon.Util.IsMainline then
	local origGetMerchantItemInfo = GetMerchantItemInfo
	GetMerchantItemInfo = function(index)
		return origGetMerchantItemInfo(GetCachedIndex(index))
	end
	C_MerchantFrame = C_MerchantFrame or {}
	C_MerchantFrame.GetItemInfo = function(index)
		local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID = GetMerchantItemInfo(index)
		return {
            name = name,
            texture = texture,
            price = price,
            stackCount = quantity,
            numAvailable = numAvailable,
            isPurchasable = isPurchasable,
            isUsable = isUsable,
            hasExtendedCost = extendedCost,
            currencyID = currencyID,
            spellID = spellID,
            isQuestStartItem = false -- This info isn't available in the old API
        }
	end
end

local origCanAffordMerchantItem = CanAffordMerchantItem
CanAffordMerchantItem = function(index)
	return origCanAffordMerchantItem(GetCachedIndex(index))
end

local origGetMerchantItemLink = GetMerchantItemLink
GetMerchantItemLink = function(index)
	return origGetMerchantItemLink(GetCachedIndex(index))
end

local origGetMerchantItemID = GetMerchantItemID
GetMerchantItemID = function(index)
	return origGetMerchantItemID(GetCachedIndex(index))
end

local origGetMerchantItemCostInfo = GetMerchantItemCostInfo
GetMerchantItemCostInfo = function(index)
	return origGetMerchantItemCostInfo(GetCachedIndex(index))
end

local origGetMerchantItemCostItem = GetMerchantItemCostItem
GetMerchantItemCostItem = function(index, itemIndex)
	return origGetMerchantItemCostItem(GetCachedIndex(index), itemIndex)
end

local origGetMerchantNumItems = GetMerchantNumItems
GetMerchantNumItems = function()
	wipe(addon.CachedItemIndices)

	local lootFilter = GetMerchantFilter()
	local numMerchantItems = origGetMerchantNumItems()
	for i = 1, numMerchantItems, 1 do
		local itemId = origGetMerchantItemID(i)
		if itemId == nil or addon.Filters:Validate(lootFilter, itemId) then
			tinsert(addon.CachedItemIndices, i)
		end
	end
	return #addon.CachedItemIndices
end

local origBuyMerchantItem = BuyMerchantItem
BuyMerchantItem = function(index, quantity)
	origBuyMerchantItem(GetCachedIndex(index), quantity)
end

local origPickupMerchantItem = PickupMerchantItem
PickupMerchantItem = function(index)
	if index == 0 then
		origPickupMerchantItem(0)
		return
	end
	origPickupMerchantItem(GetCachedIndex(index))
end

local origGetMerchantItemMaxStack = GetMerchantItemMaxStack
GetMerchantItemMaxStack = function(index)
	return origGetMerchantItemMaxStack(GetCachedIndex(index))
end

local origMerchantFrame_GetProductInfo = MerchantFrame_GetProductInfo
function MerchantFrame_GetProductInfo(itemButton)
	local productInfo, specs = origMerchantFrame_GetProductInfo(itemButton)
	productInfo.index = addon.CachedItemIndices[itemButton:GetID()]
	return productInfo, specs
end

StaticPopupDialogs['CONFIRM_PURCHASE_TOKEN_ITEM'].OnAccept = function()
	BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count)
end

StaticPopupDialogs['CONFIRM_PURCHASE_NONREFUNDABLE_ITEM'].OnAccept = function()
	BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count)
end

if addon.Util.IsMainline then
	StaticPopupDialogs['CONFIRM_PURCHASE_ITEM_DELAYED'].OnAccept = function()
		BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count)
	end
end

StaticPopupDialogs['CONFIRM_HIGH_COST_ITEM'].OnAccept = function()
	BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count)
end

-- 11.0.5 API changes
local origC_MerchantFrame_GetItemInfo = C_MerchantFrame.GetItemInfo
C_MerchantFrame.GetItemInfo = function(index)
	return origC_MerchantFrame_GetItemInfo(GetCachedIndex(index))
end