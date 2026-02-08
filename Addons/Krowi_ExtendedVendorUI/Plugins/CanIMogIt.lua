local _, addon = ...
local canIMogIt = {}
local pluginName = 'CanIMogIt'
local L_Prefix = 'Plugin_' .. pluginName .. '_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, canIMogIt)

function canIMogIt:InjectOptions()
    addon.InjectOptions:AddPluginTable(pluginName, addon.L[L_Prefix .. 'Name'], addon.L[L_Prefix .. 'Desc']:K_ReplaceVars(addon.L[L_Prefix .. 'Name']), function()
        return C_AddOns.IsAddOnLoaded(pluginName)
    end)
end

function canIMogIt:Load()
    if MerchantFrame_CIMIOnClick then
        hooksecurefunc('MerchantFrame_SetFilter', function()
            C_Timer.After(0.1, function()
                MerchantFrame_CIMIOnClick()
            end)
        end)
    end
end