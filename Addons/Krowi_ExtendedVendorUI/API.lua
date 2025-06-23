-- [[ Namespaces ]] --
local _, addon = ...;
addon.Api = {};
local api = addon.Api;

function api.Load()
	KrowiEVU_MerchantItemsContainer = addon.Gui.MerchantItemsContainer;
end