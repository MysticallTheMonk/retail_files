---@type string, Addon
local _, addon = ...
local fsEnumerable = addon.Collections.Enumerable
local fsLog = addon.Logging.Log
local fsScheduler = addon.Scheduling.Scheduler
local M = addon.Providers

function M:Enabled()
    return fsEnumerable
        :From(self.All)
        :Where(function(provider)
            return provider.Enabled and provider:Enabled()
        end)
        :ToTable()
end

function M:EnabledNotSelfManaged()
    return fsEnumerable
        :From(self.All)
        :Where(function(provider)
            return not provider.IsSelfManaged and provider.Enabled and provider:Enabled()
        end)
        :ToTable()
end

function M:EnabledSelfManaged()
    return fsEnumerable
        :From(self.All)
        :Where(function(provider)
            return provider.IsSelfManaged and provider.Enabled and provider:Enabled()
        end)
        :ToTable()
end

function M:RegisterFrameProvider(provider, isExternal)
    if not provider then
        fsLog:Error("Provider:RegisterFrameProvider() - provider must not be nil.")
        return false
    end

    if type(provider.Enabled) ~= "function" then
        return false
    end

    if type(provider.Name) ~= "function" then
        return false
    end

    if type(provider.IsVisible) ~= "function" then
        return false
    end

    provider.IsExternal = isExternal or false

    self.All[#self.All + 1] = provider

    fsLog:Debug("Frame provider '%s' was registered, external = %s, enabled = %s.", tostring(provider:Name()) or "nil", tostring(isExternal or false), tostring(provider:Enabled()) or false)

    return true
end

function M:RequestSelfManagedProvidersSort()
    local selfManaged = fsEnumerable
        :From(self.All)
        :Where(function(provider)
            return provider.IsSelfManaged and provider.Enabled and provider:Enabled()
        end)
        :ToTable()

    local sorted = false

    for _, provider in ipairs(selfManaged) do
        fsLog:Debug("Requesting external provider '%s' to sort.", tostring(provider:Name()) or "nil")

        local ok, result = pcall(provider.Sort, provider)

        if not ok then
            fsLog:Error("External provider '%s' sort failed: %s.", tostring(provider:Name()) or "nil", tostring(result))
        else
            sorted = result or sorted
        end
    end

    return sorted
end

function M:Init()
    for _, provider in pairs(self.All) do
        provider:Init()
    end

    fsLog:Debug("Initialised the providers module.")

    fsScheduler:RunWhenEnteringWorldOnce(function()
        for _, provider in pairs(self.All) do
            if provider.Enabled and provider:Enabled() then
                fsLog:Debug("Detected the '%s' addon is enabled.", provider:Name())
            end
        end
    end)
end
