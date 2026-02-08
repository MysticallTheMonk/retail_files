-- [[ Namespaces ]] --
local addonName, addon = ...

-- [[ Version data ]] --
local version = (GetBuildInfo())
local major = string.match(version, '(%d+)%.(%d+)%.(%d+)(%w?)')
addon.IsWrathClassic = major == '3'
addon.IsDragonflightRetail = major == '10'

-- [[ Load addon ]] --
local loadHelper = CreateFrame('Frame')
loadHelper:RegisterEvent('ADDON_LOADED')

function loadHelper:OnEvent(event, arg1, arg2)
    if event == 'ADDON_LOADED' then
        if arg1 == addonName then -- This always needs to load
            KrowiEVU.PluginsApi:InjectPluginOptions()
            addon.Options:Load(true)

            KrowiEVU.PluginsApi:LoadPlugins()

            addon.Gui.MerchantItemsContainer:LoadMaxNumItemSlots()

            addon.Gui.FilterButton:Load()
            addon.Gui.SearchBox:Load()
            addon.Gui.OptionsButton:Load()
            -- if addon.Util.IsMainline then
                addon.Gui.TokenBanner:Load()
            -- end

            addon.Icon:Load()

            addon.Api.Load()

            if addon.Util.IsMainline then
                C_HousingCatalog.CreateCatalogSearcher() -- Pre-load the housing catalog searcher to prevent lag when first used
            end
        end
    end
end
loadHelper:SetScript('OnEvent', loadHelper.OnEvent)

if not MerchantFrame_SetFilter then
    MerchantFrame_SetFilter = function(self, filter)
		SetMerchantFilter(filter)
		MerchantFrame.page = 1
		MerchantFrame_Update()
	end
end