---@type string, Addon
local _, addon = ...
local fsEnumerable = addon.Collections.Enumerable
local fsProviders = addon.Providers

function fsProviders:Enabled()
    return fsEnumerable
        :From(fsProviders.All)
        :Where(function(provider)
            return provider:Enabled()
        end)
        :ToTable()
end

function fsProviders:Init()
    for _, provider in pairs(fsProviders.All) do
        provider:Init()
    end
end
