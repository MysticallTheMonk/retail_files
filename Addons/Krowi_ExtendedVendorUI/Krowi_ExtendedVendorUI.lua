-- [[ Namespaces ]] --
local addonName, addon = ...;

-- [[ Version data ]] --
local version = (GetBuildInfo());
local major = string.match(version, "(%d+)%.(%d+)%.(%d+)(%w?)");
addon.IsWrathClassic = major == "3";
addon.IsDragonflightRetail = major == "10";

-- [[ Ace ]] --
addon.L = LibStub(addon.Libs.AceLocale):GetLocale(addonName);

-- [[ Load addon ]] --
local loadHelper = CreateFrame("Frame");
loadHelper:RegisterEvent("ADDON_LOADED");

function loadHelper:OnEvent(event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then -- This always needs to load
            addon.Plugins:InjectOptions();
            addon.Options:Load(true);

            addon.Plugins:Load();

            addon.Gui.MerchantItemsContainer:LoadMaxNumItemSlots();

            addon.Icon:Load();

            addon.Api.Load();

            KrowiEVU_OptionsButton:ShowHide();
        end
    end
end
loadHelper:SetScript("OnEvent", loadHelper.OnEvent);

if not MerchantFrame_SetFilter then
    MerchantFrame_SetFilter = function(self, filter)
		SetMerchantFilter(filter);
		MerchantFrame.page = 1;
		MerchantFrame_Update();
	end
end