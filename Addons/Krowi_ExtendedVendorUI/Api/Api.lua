local _, addon = ...
KrowiEVU = {}

addon.Api = {}
local api = addon.Api

function api.Load()
	KrowiEVU_MerchantItemsContainer = addon.Gui.MerchantItemsContainer -- Vendorer uses this
end