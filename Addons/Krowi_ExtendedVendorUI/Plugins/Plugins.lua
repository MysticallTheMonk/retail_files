local _, addon = ...;
addon.Plugins = {};
local plugins = addon.Plugins;
plugins.Plugins = {};

plugins.LoadHelper = CreateFrame("Frame");
function plugins.LoadHelper:OnEvent(event, arg1, arg2)
    for _, plugin in next, plugins.Plugins do
        if type(plugin.OnEvent) == "function" then
            plugin:OnEvent(event, arg1, arg2);
        end
    end
end
plugins.LoadHelper:SetScript("OnEvent", plugins.LoadHelper.OnEvent);

function plugins:LoadLocalization(L)
    for _, plugin in next, self.Plugins do
        if type(plugin.LoadLocalization) == "function" then
            plugin.LoadLocalization(L);
        end
    end
end

function plugins:InjectOptions()
    for _, plugin in next, self.Plugins do
        if type(plugin.InjectOptions) == "function" then
            plugin.InjectOptions();
        end
    end
end

function plugins:Load()
    for _, plugin in next, self.Plugins do
        if type(plugin.Load) == "function" then
            plugin.Load();
        end
    end
end

function plugins:AddRightClickMenuItems(rightClickMenu, achievement)
    for _, plugin in next, self.Plugins do
        if type(plugin.AddRightClickMenuItems) == "function" then
            plugin:AddRightClickMenuItems(rightClickMenu, achievement);
        end
    end
end