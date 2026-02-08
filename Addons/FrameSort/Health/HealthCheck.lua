---@type string, Addon
local addonName, addon = ...
local wow = addon.WoW.Api
local capabilities = addon.WoW.Capabilities
local fsEnumerable = addon.Collections.Enumerable
local fsProviders = addon.Providers
local fsConfig = addon.Configuration
local fsFrame = addon.WoW.Frame
local fsLuaEx = addon.Language.LuaEx
local L = addon.Locale.Current
---@class HealthChecker
local M = {}
addon.Health.HealthCheck = M

local function AddonFriendlyName(name)
    if not name then
        return L["(unknown)"]
    elseif name == "" then
        return L["(user macro)"]
    elseif name == "*** ForceTaint_Strong ***" then
        return L["(user macro)"]
    else
        return name
    end
end

local function IsSafeAddon(name)
    return name == addonName
        -- wotlk uses a backport addon for raid frames
        or name == "CompactRaidFrame"
end

local function CheckSortingFunctionsTampered()
    local functions = {
        "CRFSort_Group",
        "CRFSort_Role",
        "CRFSort_Alphabetical",
    }

    local isTampered, tamperedAddonName = nil, nil

    for _, f in ipairs(functions) do
        local issecure, taintedAddon = wow.issecurevariable(f)

        if not issecure and not IsSafeAddon(taintedAddon) then
            isTampered = true
            tamperedAddonName = AddonFriendlyName(taintedAddon)
            break
        end
    end

    return {
        Applicable = addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Traditional,
        Passed = not isTampered,
        Description = L["Blizzard sorting functions not tampered with"],
        Help = string.format(L['"%s" may cause conflicts, consider disabling it'], tamperedAddonName or L["(unknown)"]),
    }
end

local function ConflictingAddons()
    if not fsProviders.Blizzard:Enabled() then
        return nil
    end

    if wow.CompactRaidFrameContainer then
        local issecure, taintedAddon = wow.issecurevariable("CompactRaidFrameContainer")
        if not issecure and not IsSafeAddon(taintedAddon) then
            return AddonFriendlyName(taintedAddon)
        end

        issecure, taintedAddon = wow.issecurevariable(wow.CompactRaidFrameContainer, "flowSortFunc")
        if not issecure and not IsSafeAddon(taintedAddon) then
            return AddonFriendlyName(taintedAddon)
        end
    end

    if wow.CompactPartyFrame then
        local issecure, taintedAddon = wow.issecurevariable("CompactPartyFrame")
        if not issecure and not IsSafeAddon(taintedAddon) then
            return AddonFriendlyName(taintedAddon)
        end

        issecure, taintedAddon = wow.issecurevariable(wow.CompactPartyFrame, "flowSortFunc")
        if not issecure and not IsSafeAddon(taintedAddon) then
            return AddonFriendlyName(taintedAddon)
        end
    end

    -- running both at the same time would cause issues
    if wow.GetAddOnEnableState("SortGroup") ~= 0 then
        return "SortGroup"
    end

    return nil
end

local function CheckConflictingAddons()
    local conflictingAddon = ConflictingAddons()

    return {
        Applicable = true,
        Passed = conflictingAddon == nil,
        Description = L["No conflicting addons"],
        Help = string.format(L['"%s" may cause conflicts, consider disabling it'], conflictingAddon or L["(unknown)"]),
    }
end

local function CanSeeFrames()
    if not wow.IsInGroup() then
        return true
    end

    for _, provider in pairs(fsProviders:EnabledNotSelfManaged()) do
        local containers = provider:Containers()

        for _, container in ipairs(containers) do
            local frames = (container.Frames and container:Frames()) or fsFrame:ExtractUnitFrames(container.Frame)
            local anyVisible = fsEnumerable:From(frames):Any(function(frame)
                return frame:IsVisible()
            end)

            if anyVisible then
                return true
            end

            if container.IsGrouped and container:IsGrouped() then
                local groups = fsFrame:ExtractGroups(container.Frame)
                local anyVisibleInGroup = fsEnumerable
                    :From(groups)
                    :Map(function(group)
                        return fsFrame:ExtractUnitFrames(group)
                    end)
                    :Flatten()
                    :Any(function(frame)
                        return frame:IsVisible()
                    end)

                if anyVisibleInGroup then
                    return true
                end
            end
        end
    end

    for _, provider in pairs(fsProviders:EnabledSelfManaged()) do
        if provider:IsVisible() then
            return true
        end
    end

    return false
end

local function CheckCanSeeFrames()
    local allProviderNames = fsEnumerable
        :From(fsProviders.All)
        :Map(function(provider)
            return provider:Name()
        end)
        :ToTable()

    local allProvidersString = table.concat(allProviderNames, ", ")

    return {
        Applicable = wow.IsInGroup(),
        Passed = CanSeeFrames(),
        Description = L["Can detect frames"],
        Help = string.format(L["FrameSort currently supports frames from these addons: %s"], allProvidersString),
    }
end

local function CheckOnlyUsingBlizzard()
    local anyOtherProviderEnabled = false

    for _, provider in pairs(fsProviders.All) do
        if provider ~= fsProviders.Blizzard and provider:Enabled() then
            anyOtherProviderEnabled = true
            break
        end
    end

    local enabledNonBlizzardNames = fsEnumerable
        :From(fsProviders:EnabledNotSelfManaged())
        :Where(function(p)
            return p ~= fsProviders.Blizzard
        end)
        :Map(function(provider)
            return provider:Name()
        end)
        :ToTable()

    local enabledNonBlizzardString = table.concat(enabledNonBlizzardNames, ", ")

    return {
        Applicable = addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Traditional,
        Passed = not anyOtherProviderEnabled and fsProviders.Blizzard:Enabled(),
        Description = L["Only using Blizzard frames with Traditional mode"],
        Help = string.format(L["Traditional mode can't sort your other frame addons: '%s'"], enabledNonBlizzardString),
    }
end

local function CheckUsingSpacing()
    local options = addon.DB.Options
    local spacings = {}

    if options.Sorting.World.Enabled then
        spacings[#spacings + 1] = options.Spacing.Party
    end

    if options.Sorting.Raid.Enabled then
        spacings[#spacings + 1] = options.Spacing.Raid
    end

    if options.Sorting.EnemyArena.Enabled then
        spacings[#spacings + 1] = options.Spacing.EnemyArena
    end

    local usingSpacing = fsEnumerable:From(spacings):Any(function(spacing)
        return spacing.Vertical ~= 0 or spacing.Horizontal ~= 0
    end)

    return {
        Applicable = true,
        Passed = not usingSpacing or addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Secure,
        Description = L["Using Secure sorting mode when spacing is being used"],
        Help = L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"],
    }
end

local function CheckKeepGroupTogether()
    local keepGroupTogether = false

    if capabilities.HasEditMode() then
        local raidGroupDisplayType =
            wow.EditModeManagerFrame:GetSettingValue(wow.Enum.EditModeSystem.UnitFrame, wow.Enum.EditModeUnitFrameSystemIndices.Raid, wow.Enum.EditModeUnitFrameSetting.RaidGroupDisplayType)
        keepGroupTogether = raidGroupDisplayType == wow.Enum.RaidGroupDisplayType.SeparateGroupsVertical or raidGroupDisplayType == wow.Enum.RaidGroupDisplayType.SeparateGroupsHorizontal
    elseif wow.CompactRaidFrameManager_GetSetting then
        keepGroupTogether = wow.CompactRaidFrameManager_GetSetting("KeepGroupsTogether")
    end

    return {
        Applicable = addon.DB.Options.Sorting.Method == fsConfig.SortingMethod.Traditional,
        Passed = not keepGroupTogether,
        Description = L["Keep Groups Together setting disabled"],
        Help = capabilities.HasEditMode() and L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] or L["Disable the 'Keep Groups Together' raid profile setting"],
    }
end

local function CheckCell()
    local passed = false
    local applicable = false

    if Cell and CellDB then
        applicable = true

        local selectedLayout = fsLuaEx:SafeGet(Cell, { "vars", "currentLayout" }) or "default"
        -- when using combined layout, the group filter will show all groups
        passed = fsLuaEx:SafeGet(CellDB, { "layouts", selectedLayout, "main", "combineGroups" }) == true
    end

    return {
        Applicable = applicable,
        Passed = passed,
        Description = L["Using grouped layout for Cell raid frames"],
        Help = L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"],
    }
end

---Returns true if the environment/settings is in a good state, otherwise false.
---@return boolean healthy,HealthCheckResult[] results
function M:IsHealthy()
    local results = {}

    results[#results + 1] = CheckCanSeeFrames()
    results[#results + 1] = CheckKeepGroupTogether()
    results[#results + 1] = CheckOnlyUsingBlizzard()
    results[#results + 1] = CheckUsingSpacing()
    results[#results + 1] = CheckSortingFunctionsTampered()
    results[#results + 1] = CheckConflictingAddons()
    results[#results + 1] = CheckCell()

    local healthy = fsEnumerable:From(results):All(function(x)
        return not x.Applicable or x.Passed
    end)

    return healthy, results
end
