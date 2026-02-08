local _, addon = ...
local elv = {}
local pluginName = 'ElvUI'
local L_Prefix = 'Plugin_' .. pluginName .. '_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, elv)

local function IsLoaded()
    return ElvUI ~= nil
end

local doSkin, engine, skins
local isModern = addon.Util.IsMainline

local function QuestIcon_SetTexture(iconQuest, texture)
	if texture == QUEST_ICON then
		iconQuest:SetTexture(engine.Media.Textures.BagQuestIcon)
	end
end

local function SkinModernMerchantItemButtons()
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local item = _G['MerchantItem'..i]
		item:Size(155, 45)
		item:StripTextures(true)
		item:CreateBackdrop('Transparent')
		item.backdrop:Point('TOPLEFT', -3, 2)
		item.backdrop:Point('BOTTOMRIGHT', 2, -3)

		local slot = _G['MerchantItem'..i..'SlotTexture']
		item.Name:Point('LEFT', slot, 'RIGHT', -5, 5)
		item.Name:Size(110, 30)

		local button = _G['MerchantItem'..i..'ItemButton']
		button:StripTextures()
		button:StyleButton()
		button:SetTemplate(nil, true)
		button:Point('TOPLEFT', item, 'TOPLEFT', 4, -4)

		local icon = button.icon
		icon:SetTexCoords()
		icon:ClearAllPoints()
		icon:Point('TOPLEFT', 1, -1)
		icon:Point('BOTTOMRIGHT', -1, 1)

		local questIcon = button.IconQuestTexture
		questIcon:SetTexCoord(0, 1, 0, 1)
		questIcon:SetInside()

		hooksecurefunc(questIcon, 'SetTexture', QuestIcon_SetTexture)

		skins:HandleIconBorder(button.IconBorder)
	end
end

local function SkinClassicMerchantItemButtons()
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local item = _G['MerchantItem'..i]
		local button = _G['MerchantItem'..i..'ItemButton']
		local icon = _G['MerchantItem'..i..'ItemButtonIconTexture']
		local money = _G['MerchantItem'..i..'MoneyFrame']
		local nameFrame = _G['MerchantItem'..i..'NameFrame']
		local name = _G['MerchantItem'..i..'Name']
		local slot = _G['MerchantItem'..i..'SlotTexture']

		item:StripTextures(true)
		item:CreateBackdrop('Transparent')
		item.backdrop:Point('TOPLEFT', -1, 3)
		item.backdrop:Point('BOTTOMRIGHT', 2, -3)

		button:StripTextures()
		button:StyleButton()
		button:SetTemplate(nil, true)
		button:Size(40)
		button:Point('TOPLEFT', item, 'TOPLEFT', 4, -2)

		icon:SetTexCoords()
		icon:SetInside()

		nameFrame:Point('LEFT', slot, 'RIGHT', -6, -17)

		name:Point('LEFT', slot, 'RIGHT', -4, 5)

		money:ClearAllPoints()
		money:Point('BOTTOMLEFT', button, 'BOTTOMRIGHT', 3, 0)
	end
end

local function SkinMerchantItemButtons()
    if isModern then
        SkinModernMerchantItemButtons()
    else
        SkinClassicMerchantItemButtons()
    end
end

local function AddInfo(localizationName, getFunction, hidden)
    return {
        order = KrowiEVU.UtilApi.InjectOptions.AutoOrderPlusPlus(), type = 'toggle', width = 'full',
        name = addon.L[L_Prefix .. localizationName],
        desc = addon.L[L_Prefix .. localizationName .. '_Desc'],
        descStyle = 'inline',
        get = getFunction,
        disabled = true,
        hidden = hidden
    }
end

function elv:InjectOptions()
    local pluginTable = KrowiEVU.UtilApi.InjectOptions:AddPluginTable(
        'ElvUI',
        addon.L[L_Prefix .. 'Name'],
        addon.L[L_Prefix .. 'Desc'],
        function()
            return IsLoaded()
        end
    )
    KrowiEVU.UtilApi.InjectOptions:AddTable(pluginTable, 'SkinMerchant', AddInfo('SkinMerchant', function() return doSkin.Merchant end))
    KrowiEVU.UtilApi.InjectOptions:AddTable(pluginTable, 'SkinMiscFrames', AddInfo('SkinMiscFrames', function() return doSkin.MiscFrames end))
    KrowiEVU.UtilApi.InjectOptions:AddTable(pluginTable, 'SkinTooltip', AddInfo('SkinTooltip', function() return doSkin.Tooltip end))

end

-- function elv:LoadLocalization(L)
--     L['ElvUI Skin Merchant'] = 'Skin Merchant'
--     L['ElvUI Skin Merchant Desc'] = [=[Applies the ElvUI skin to the Merchant Frame.
-- -> Blizzard + Merchant Frame]=]
--     L['ElvUI Skin Misc Frames'] = 'Skin Misc Frames'
--     L['ElvUI Skin Misc Frames Desc'] = [=[Applies the ElvUI skin to the Filter Menu, Right Click Menu and Popup Dialog.
-- -> Blizzard + Misc Frames]=]
--     L['ElvUI Skin Tooltip'] = 'Skin Tooltip'
--     L['ElvUI Skin Tooltip Desc'] = [=[Applies the ElvUI skin to the Tooltips.
-- -> Blizzard + Tooltip]=]
-- end

function elv:Load()
    doSkin = {}

    if not IsLoaded() then
        return
    end

    engine = unpack(ElvUI)
    skins = engine:GetModule('Skins')
    local privateSkins = engine.private.skins
    local blizzardSkins = privateSkins.blizzard

    doSkin.Merchant = blizzardSkins.enable and blizzardSkins.merchant
    doSkin.MiscFrames = blizzardSkins.enable and blizzardSkins.misc
    doSkin.Tooltip = blizzardSkins.enable and blizzardSkins.tooltip

    for i = 1, 12, 1 do
        _G['MerchantItem' .. i].PointXY = function() end
    end

    if not doSkin.Merchant then
        return
    end

    hooksecurefunc(addon.Gui.MerchantItemsContainer, 'LoadMaxNumItemSlots', function()
        SkinMerchantItemButtons()
        SkinMerchantItemButtons = function() end -- No need to run again
    end)

    hooksecurefunc(addon.Gui.FilterButton, 'Load', function()
        skins:HandleDropDownBox(KrowiEVU_FilterButton)
    end)

    hooksecurefunc(addon.Gui.SearchBox, 'Load', function()
        skins:HandleEditBox(KrowiEVU_SearchBox)
        KrowiEVU_SearchBox:SetHeight(22)
        addon.Gui.SearchBox:SetPointOffsetXY(nil, 0)
    end)

    if not isModern then
        hooksecurefunc(addon.Gui.OptionsButton, 'Load', function()
            skins:HandleButton(KrowiEVU_OptionsButton)
        end)
    end

    hooksecurefunc('MerchantFrame_Update', function()
        addon.Gui.MerchantFrame.UpdateRepairButtons()
    end)

    KrowiEVU_MerchantButtonsInset:StripTextures()
    KrowiEVU_MerchantButtonsInset:CreateBackdrop('Transparent')
	KrowiEVU_MerchantButtonsInset.backdrop:Point('TOPLEFT', 2, -2)
	KrowiEVU_MerchantButtonsInset.backdrop:Point('BOTTOMRIGHT', -2, 2)
    KrowiEVU_MerchantBuybackInset:StripTextures()
    KrowiEVU_MerchantEmptyInset:StripTextures()

    hooksecurefunc(addon.Gui.TokenBanner, 'Load', function()
        KrowiEVU_TokenBanner:StripTextures()
        KrowiEVU_TokenBanner:CreateBackdrop('Transparent')
    end)
end