local _, addon = ...

local isModern = addon.Util.IsMainline

KrowiEVU_FilterButtonMixin = {}

-- Lookup table for loot filter text labels
local lootFilterTextMap = {}

local function InitializeLootFilterTextMap()
	lootFilterTextMap[LE_LOOT_FILTER_ALL] = addon.L['All']
	lootFilterTextMap[LE_LOOT_FILTER_BOE] = addon.L['Bind on Equip']
	lootFilterTextMap[LE_LOOT_FILTER_CLASS] = addon.L['All Specs']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH']] = addon.L['Search']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_PETS']] = addon.L['Pets']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_MOUNTS']] = addon.L['Mounts']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TOYS']] = addon.L['Toys']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TRANSMOG']] = addon.L['Appearances']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TRANSMOG_SETS']] = addon.L['Appearance Sets']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_ILLUSIONS']] = addon.L['Illusions']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_RECIPES']] = addon.L['Recipes']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_HOUSING']] = addon.L['Housing']
	lootFilterTextMap[_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_CUSTOM']] = addon.L['Custom']
end

local function GetLootFilterText(lootFilter)
	if not next(lootFilterTextMap) then
		InitializeLootFilterTextMap()
	end
	return lootFilterTextMap[lootFilter]
end

-- Mixin Implementation

function KrowiEVU_FilterButtonMixin:OnLoad()
	-- Call parent mixin OnLoad if Modern
	if isModern then
		WowStyle1DropdownMixin.OnLoad(self)
	end

	self:SetFrameLevel(self:GetParent():GetFrameLevel() + 7)

	local config = {
		uniqueTag = 'KEVU_FILTERS',
		callbacks = addon.MenuBuilder.BindCallbacks(self, {
			OnCheckboxSelect = 'OnCheckboxSelect',
			KeyEqualsText = 'KeyEqualsText',
			OnRadioSelect = 'OnRadioSelect',
			OnAllSelect = 'OnAllSelect',
		}),
		translations = addon.Util.L
	}

	-- Initialize MenuBuilder
	local menuBuilder = addon.MenuBuilder:New(config)
	self.menuBuilder = menuBuilder

	-- Set CreateMenu function directly on the instance
	menuBuilder.CreateMenu = function(mb)
		self:CreateMenu(mb:GetMenu())
	end

	-- Modern needs SetupMenuForModern
	if isModern then
		menuBuilder:SetupMenuForModern(self)
		self:OverrideText(GetLootFilterText(GetMerchantFilter()))
	end
end

function KrowiEVU_FilterButtonMixin:OnMouseDown()
	if isModern then
		WowStyle1DropdownMixin.OnMouseDown(self)
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		UIMenuButtonStretchMixin.OnMouseDown(self)
		-- Show menu with horizontal and vertical offset
		self.menuBuilder:Show(self, 96, 15)
	end
end

function KrowiEVU_FilterButtonMixin:SetFilter(value)
	MerchantFrame_SetFilter(nil, value)
	if isModern then
		self:OverrideText(GetLootFilterText(value))
	else
		self:SetText(GetLootFilterText(value))
	end
end

-- Callbacks

function KrowiEVU_FilterButtonMixin:OnCheckboxSelect(filters, keys)
	addon.Util.WriteNestedKeys(filters, keys, not addon.Util.ReadNestedKeys(filters, keys))
	MerchantFrame_SetFilter(nil, GetMerchantFilter())
end

function KrowiEVU_FilterButtonMixin:KeyEqualsText(filters, keys, value)
	return GetMerchantFilter() == value
end

function KrowiEVU_FilterButtonMixin:OnRadioSelect(filters, keys, value)
	self:SetFilter(value)
end

function KrowiEVU_FilterButtonMixin:OnAllSelect(filters, keys, value)
	for index, _ in next, addon.Filters[keys .. 'Types'] do
		addon.Util.WriteNestedKeys(filters, {keys, index}, value)
	end
	MerchantFrame_SetFilter(nil, GetMerchantFilter())
end

-- Menu Helpers

function KrowiEVU_FilterButtonMixin:CreateRadio(menu, text, filter)
	self.menuBuilder:CreateRadio(menu, text, _, _, filter)
end

function KrowiEVU_FilterButtonMixin:CreateSubmenuRadio(menu, text, filter)
	return self.menuBuilder:CreateSubmenuRadio(
		menu,
		text,
		function() return self.menuBuilder:KeyEqualsText(_, _, filter) end,
		function() self.menuBuilder:OnRadioSelect(_, _, filter) end
	)
end

function KrowiEVU_FilterButtonMixin:CreateCheckbox(menu, text, keys)
	self.menuBuilder:CreateCheckbox(menu, text, addon.Filters.db.profile, keys)
end

function KrowiEVU_FilterButtonMixin:CreateSelectDeselectAllButtons(menu, filters, filterType)
	self.menuBuilder:CreateSelectDeselectAllButtons(menu, filters, filterType)
end

-- Menu Creation

function KrowiEVU_FilterButtonMixin:CreateMenu(menu)
	local mb = self.menuBuilder

	mb:CreateTitle(menu, addon.L['Default filters'])

	-- Class/Spec filters (Mainline only)
	if isModern then
		local className = UnitClass('player')
		local classButton = mb:CreateSubmenuButton(menu, className)
		local sex = UnitSex('player')
		local numSpecs = GetNumSpecializations()

		for i = 1, numSpecs do
			local _, name = GetSpecializationInfo(i, nil, nil, nil, sex)
			local filter = LE_LOOT_FILTER_SPEC1 + i - 1
			self:CreateRadio(classButton, name, filter)
		end
		self:CreateRadio(classButton, addon.L['All Specs'], LE_LOOT_FILTER_CLASS)
		mb:AddChildMenu(menu, classButton)

		self:CreateRadio(menu, addon.L['Bind on Equip'], LE_LOOT_FILTER_BOE)
	end

	self:CreateRadio(menu, addon.L['All'], LE_LOOT_FILTER_ALL)

	mb:CreateDivider(menu)

	self:CreateRadio(menu, addon.L['Search'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'])

	mb:CreateDivider(menu)

	-- Only show section
	mb:CreateTitle(menu, addon.L['Only show'])

	if isModern then
		self:CreateRadio(menu, addon.L['Pets'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_PETS'])
	end
	self:CreateRadio(menu, addon.L['Mounts'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_MOUNTS'])
	self:CreateRadio(menu, addon.L['Toys'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TOYS'])

	-- Appearances submenu with armor/weapon filters
	local appearances = self:CreateSubmenuRadio(menu, addon.L['Appearances'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TRANSMOG'])
	mb:CreateTitle(appearances, C_Item.GetItemClassInfo(4)) -- Armor
	for _, index in ipairs(addon.Filters.ArmorIndices) do
		local text = C_Item.GetItemSubClassInfo(4, index)
		self:CreateCheckbox(appearances, text, {'OnlyShow', 'Armor', index})
	end
	mb:CreateDivider(appearances)
	self:CreateSelectDeselectAllButtons(appearances, addon.Filters.db.profile.OnlyShow, 'Armor')
	mb:CreateDivider(appearances)
	mb:CreateTitle(appearances, C_Item.GetItemClassInfo(2)) -- Weapons
	for _, index in ipairs(addon.Filters.WeaponIndices) do
		local text = C_Item.GetItemSubClassInfo(2, index)
		self:CreateCheckbox(appearances, text, {'OnlyShow', 'Weapon', index})
	end
	mb:CreateDivider(appearances)
	self:CreateSelectDeselectAllButtons(appearances, addon.Filters.db.profile.OnlyShow, 'Weapon')
	mb:AddChildMenu(menu, appearances)

	if isModern then
		self:CreateRadio(menu, addon.L['Appearance Sets'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TRANSMOG_SETS'])
		self:CreateRadio(menu, addon.L['Illusions'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_ILLUSIONS'])
		self:CreateRadio(menu, addon.L['Recipes'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_RECIPES'])
		self:CreateRadio(menu, addon.L['Housing'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_HOUSING'])
	end

	-- Custom filter section
	local custom = self:CreateSubmenuRadio(menu, addon.L['Custom'], _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_CUSTOM'])
	if isModern then
		self:CreateCheckbox(custom, addon.L['Pets'], {'Custom', 'Pets'})
	end
	self:CreateCheckbox(custom, addon.L['Mounts'], {'Custom', 'Mounts'})
	self:CreateCheckbox(custom, addon.L['Toys'], {'Custom', 'Toys'})

	-- Custom Appearances submenu
	local customAppearances = mb:CreateSubmenuButton(custom, addon.L['Appearances'])
	mb:CreateTitle(customAppearances, C_Item.GetItemClassInfo(4)) -- Armor
	for _, index in ipairs(addon.Filters.ArmorIndices) do
		local text = C_Item.GetItemSubClassInfo(4, index)
		self:CreateCheckbox(customAppearances, text, {'Custom', 'Armor', index})
	end
	mb:CreateDivider(customAppearances)
	self:CreateSelectDeselectAllButtons(customAppearances, addon.Filters.db.profile.Custom, 'Armor')
	mb:CreateDivider(customAppearances)
	mb:CreateTitle(customAppearances, C_Item.GetItemClassInfo(2)) -- Weapons
	for _, index in ipairs(addon.Filters.WeaponIndices) do
		local text = C_Item.GetItemSubClassInfo(2, index)
		self:CreateCheckbox(customAppearances, text, {'Custom', 'Weapon', index})
	end
	mb:CreateDivider(customAppearances)
	self:CreateSelectDeselectAllButtons(customAppearances, addon.Filters.db.profile.Custom, 'Weapon')
	mb:AddChildMenu(custom, customAppearances)

	if isModern then
		self:CreateCheckbox(custom, addon.L['Appearance Sets'], {'Custom', 'TransmogSets'})
		self:CreateCheckbox(custom, addon.L['Illusions'], {'Custom', 'Illusions'})
		self:CreateCheckbox(custom, addon.L['Recipes'], {'Custom', 'Recipes'})
		self:CreateCheckbox(custom, addon.L['Housing'], {'Custom', 'Housing'})
	end
	self:CreateCheckbox(custom, addon.L['Other'], {'Custom', 'Other'})
	mb:AddChildMenu(menu, custom)

	mb:CreateDivider(menu)

	-- Hide collected section
	mb:CreateTitle(menu, addon.L['Hide collected'])
	if isModern then
		self:CreateCheckbox(menu, addon.L['Pets'], {'HideCollected', 'Pets'})
	end
	self:CreateCheckbox(menu, addon.L['Mounts'], {'HideCollected', 'Mounts'})
	self:CreateCheckbox(menu, addon.L['Toys'], {'HideCollected', 'Toys'})
	self:CreateCheckbox(menu, addon.L['Appearances'], {'HideCollected', 'Transmog'})
	if isModern then
		self:CreateCheckbox(menu, addon.L['Appearance Sets'], {'HideCollected', 'TransmogSets'})
		self:CreateCheckbox(menu, addon.L['Illusions'], {'HideCollected', 'Illusions'})
		self:CreateCheckbox(menu, addon.L['Recipes'], {'HideCollected', 'Recipes'})
		self:CreateCheckbox(menu, addon.L['Housing'], {'HideCollected', 'Housing'})
	end
end

-- Hooks

hooksecurefunc('MerchantFrame_SetFilter', function(self, filter)
	if not filter then
		return
	end
	KrowiEVU_Filters = KrowiEVU_Filters or {}
	KrowiEVU_Filters.LastFilter = filter
end)

if isModern then
	hooksecurefunc('ResetSetMerchantFilter', function(self)
		if addon.Options.db.profile.RememberFilter and KrowiEVU_Filters.LastFilter then
			MerchantFrame_SetFilter(nil, KrowiEVU_Filters.LastFilter)
		end
		KrowiEVU_FilterButton:OverrideText(GetLootFilterText(GetMerchantFilter()))
	end)
else
	MerchantFrame:HookScript('OnShow', function(self)
		if addon.Options.db.profile.RememberFilter and KrowiEVU_Filters and KrowiEVU_Filters.LastFilter then
			MerchantFrame_SetFilter(nil, KrowiEVU_Filters.LastFilter)
		else
			MerchantFrame_SetFilter(nil, LE_LOOT_FILTER_ALL)
		end
		KrowiEVU_FilterButton:SetText(GetLootFilterText(GetMerchantFilter()))
	end)
end