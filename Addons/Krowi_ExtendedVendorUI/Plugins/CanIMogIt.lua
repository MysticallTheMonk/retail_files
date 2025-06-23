local _, addon = ...;
local plugins = addon.Plugins;
plugins.CanIMogIt = {};
local canIMogIt = plugins.CanIMogIt;
tinsert(plugins.Plugins, canIMogIt);

function canIMogIt.Load()
    if MerchantFrame_CIMIOnClick then
        hooksecurefunc("MerchantFrame_SetFilter", function()
            C_Timer.After(0.1, function()
                MerchantFrame_CIMIOnClick();
            end);
        end);
    end
end

function canIMogIt.InjectOptions()
    addon.InjectOptions:AddPluginTable("CanIMogIt", addon.L["Can I Mog It"], addon.L["Can I Mog It Desc"]:K_ReplaceVars(addon.L["Can I Mog It"]), function()
        return C_AddOns.IsAddOnLoaded("CanIMogIt");
    end);
end