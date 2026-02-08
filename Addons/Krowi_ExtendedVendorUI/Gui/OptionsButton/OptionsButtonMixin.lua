-- [[ Namespaces ]] --
local _, addon = ...
local merchantItemsContainer = addon.Gui.MerchantItemsContainer

KrowiEVU_OptionsButtonMixin = {}

local menuBuilder

local function UpdateView()
	merchantItemsContainer:LoadMaxNumItemSlots()
	MerchantFrame_Update()
end

function KrowiEVU_OptionsButtonMixin:OnLoad()
	menuBuilder = addon.MenuBuilder:New({
		uniqueTag = 'KEVU_OPTIONS',
		callbacks = {
			OnRadioSelect = function(filters, keys, value)
				addon.Util.WriteNestedKeys(filters, keys, value)
				UpdateView()
			end,
			OnCheckboxSelect = function(filters, keys)
				addon.Util.WriteNestedKeys(filters, keys, not menuBuilder:KeyIsTrue(filters, keys))
				UpdateView()
			end,
		}
	})

	menuBuilder.CreateMenu = function(mb)
		self:CreateMenu(mb:GetMenu())
	end

	if addon.Util.IsMainline then
		menuBuilder:SetupMenuForModern(self)
	end
end

function KrowiEVU_OptionsButtonMixin:ShowHide()
    if addon.Options.db.profile.ShowOptionsButton then
        self:Show()
        return
    end
    self:Hide()
end

local media = 'Interface\\AddOns\\Krowi_MerchantFrameExtended\\Media\\'
local function ReplaceVarsWithMenu(str, vars)
    if not vars then
        vars = type(str) == 'table' and str or {str}
        str = vars[1]
    end
    vars['arrow'] = '|T' .. media .. 'ui-backarrow:0|t'
    vars['gameMenu'] = addon.Util.L['Game Menu']
    vars['interface'] = addon.Util.L['Interface']
    vars['addOns'] = addon.Util.L['AddOns']
    vars['addonName'] = addon.Metadata.Title
    return addon.Util.Strings.ReplaceVars(str, vars)
end
string.K_ReplaceVarsWithMenu = ReplaceVarsWithMenu

local function HideOptionsButtonCallback(self)
	addon.Options.db.profile.ShowOptionsButton = false
	self:ShowHide()
end

function KrowiEVU_OptionsButtonMixin:CreateMenu(menuObj)
	local profile = addon.Options.db.profile

	-- Direction submenu
	local direction = menuBuilder:CreateSubmenuButton(menuObj, addon.L['Direction'])
	menuBuilder:CreateRadio(direction, addon.L['Rows first'], profile, {'Direction'}, 'Rows')
	menuBuilder:CreateRadio(direction, addon.L['Columns first'], profile, {'Direction'}, 'Columns')
	menuBuilder:AddChildMenu(menuObj, direction)

	-- Rows submenu
	local rows = menuBuilder:CreateSubmenuButton(menuObj, addon.L['Rows'])
	local rowPresets = {1, 2, 5, 10}
	for _, row in ipairs(rowPresets) do
		menuBuilder:CreateRadio(rows, tostring(row), profile, {'NumRows'}, row)
	end
	local currentRows = profile.NumRows or 1
	local isCustomRows = true
	for _, row in ipairs(rowPresets) do
		if currentRows == row then
			isCustomRows = false
			break
		end
	end
	if isCustomRows then
		menuBuilder:CreateRadio(rows, string.format('%s (%d)', addon.L['Custom'], currentRows), profile, {'NumRows'}, currentRows)
	end
	menuBuilder:CreateDivider(rows)
	menuBuilder:CreateButtonAndAdd(rows, addon.L['Set custom'], function()
		local lib = LibStub('Krowi_PopupDialog_2')
		lib.ShowNumericInput({
			Text = addon.L['Enter number of rows'],
			Min = 1,
			Max = 99,
			Default = profile.NumRows or 1,
			Callback = function(value)
				profile.NumRows = value
				UpdateView()
			end
		})
	end)
	menuBuilder:AddChildMenu(menuObj, rows)

	-- Columns submenu
	local columns = menuBuilder:CreateSubmenuButton(menuObj, addon.L['Columns'])
	local columnPresets = {2, 5, 10}
	for _, column in ipairs(columnPresets) do
		menuBuilder:CreateRadio(columns, tostring(column), profile, {'NumColumns'}, column)
	end
	local currentColumns = profile.NumColumns or 2
	local isCustomColumns = true
	for _, column in ipairs(columnPresets) do
		if currentColumns == column then
			isCustomColumns = false
			break
		end
	end
	if isCustomColumns then
		menuBuilder:CreateRadio(columns, string.format('%s (%d)', addon.L['Custom'], currentColumns), profile, {'NumColumns'}, currentColumns)
	end
	menuBuilder:CreateDivider(columns)
	menuBuilder:CreateButtonAndAdd(columns, addon.L['Set custom'], function()
		local lib = LibStub('Krowi_PopupDialog_2')
		lib.ShowNumericInput(addon.L['Enter number of columns'], 2, 99, profile.NumColumns or 2, function(value)
			profile.NumColumns = value
			UpdateView()
		end)
	end)
	menuBuilder:AddChildMenu(menuObj, columns)

	menuBuilder:CreateDivider(menuObj)

	-- Remember Filter checkbox
	menuBuilder:CreateCheckbox(menuObj, addon.L['RememberFilter'], profile, {'RememberFilter'})
	menuBuilder:CreateCheckbox(menuObj, addon.L['RememberSearch'], profile, {'RememberSearch'})
	menuBuilder:CreateCheckbox(menuObj, addon.L['RememberSearchBetweenVendors'], profile, {'RememberSearchBetweenVendors'})

	if addon.Util.IsMainline then
		menuBuilder:CreateDivider(menuObj)

		-- Housing Quantity submenu
		local housingQuantity = menuBuilder:CreateSubmenuButton(menuObj, addon.L['Housing Quantity'])
		local quantities = {1, 2, 5, 10}
		for _, quantity in ipairs(quantities) do
			menuBuilder:CreateRadio(housingQuantity, tostring(quantity), addon.Filters.db.profile, {'HousingQuantity'}, quantity)
		end
		local currentValue = addon.Filters.db.profile.HousingQuantity or 1
		local isCustomValue = true
		for _, quantity in ipairs(quantities) do
			if currentValue == quantity then
				isCustomValue = false
				break
			end
		end
		if isCustomValue then
			menuBuilder:CreateRadio(housingQuantity, string.format('%s (%d)', addon.L['Custom'], currentValue), addon.Filters.db.profile, {'HousingQuantity'}, currentValue)
		end

		menuBuilder:CreateDivider(housingQuantity)
		menuBuilder:CreateButtonAndAdd(housingQuantity, addon.L['Set custom'], function()
			local lib = LibStub('Krowi_PopupDialog_2')
			lib.ShowNumericInput({
				Text = addon.L['Enter housing quantity'],
				Min = 1,
				Max = 999,
				Default = addon.Filters.db.profile.HousingQuantity or 1,
				Callback = function(value)
					addon.Filters.db.profile.HousingQuantity = value
					UpdateView()
				end
			})
		end)
		menuBuilder:AddChildMenu(menuObj, housingQuantity)
	end

	-- Add the TokenBanner options here
	menuBuilder:CreateDivider(menuObj)
	addon.Gui.TokenBanner:CreateOptionsMenu(menuObj, menuBuilder)

	-- Hide button
	if profile.ShowHideOption then
		menuBuilder:CreateDivider(menuObj)
		menuBuilder:CreateButtonAndAdd(menuObj, addon.Util.L['Hide'], function()
			if not StaticPopup_IsCustomGenericConfirmationShown('KrowiEVU_ConfirmHideOptionsButton') then
				StaticPopup_ShowCustomGenericConfirmation(
					{
						text = addon.L['Are you sure you want to hide the options button?']:K_ReplaceVarsWithMenu{
							general = addon.Util.L['General'],
							options = addon.Util.L['Options']
						},
						callback = function()
							HideOptionsButtonCallback(self)
						end,
						referenceKey = 'KrowiEVU_ConfirmHideOptionsButton'
					}
				)
			end
		end)
	end
end

function KrowiEVU_OptionsButtonMixin:ShowPopup()
	menuBuilder:ShowPopup()
end

if not addon.Util.IsMainline then
	function KrowiEVU_OptionsButtonMixin:OnMouseDown()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		UIMenuButtonStretchMixin.OnMouseDown(self)
		menuBuilder:ShowPopup()
	end
end