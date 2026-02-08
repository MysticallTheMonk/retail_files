--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local sub, parent = KROWI_LIBMAN:NewSubmodule('Metadata', 0)
if not sub or not parent then return end

local getBuildInfo = GetBuildInfo
local getAddOnMetadata = C_AddOns.GetAddOnMetadata
local buildVersionFormat = '%s.%s'
local curseForgeLinkFormat = parent.Constants.CurseForgeLinkBase .. '%s'
local wagoLinkFormat = parent.Constants.WagoIoLinkBase .. '%s'
local metadataCache = {}

function sub.GetAddOnMetadata(addonName)
    if metadataCache[addonName] then
        return metadataCache[addonName]
    end

    local build = getBuildInfo()
    local version = getAddOnMetadata(addonName, 'Version')

    metadataCache[addonName] = {
        AddonName = addonName,
        Title = getAddOnMetadata(addonName, 'Title'),
        Prefix = getAddOnMetadata(addonName, 'X-Prefix'),
        Acronym = getAddOnMetadata(addonName, 'X-Acronym'),
        Build = build,
        Version = version,
        BuildVersion = string.format(buildVersionFormat, build, version),
        Author = getAddOnMetadata(addonName, 'Author'),
        Icon = getAddOnMetadata(addonName, 'IconTexture'),
        CurseForge = string.format(curseForgeLinkFormat, getAddOnMetadata(addonName, 'X-Slug')),
        Wago = string.format(wagoLinkFormat, getAddOnMetadata(addonName, 'X-Slug'))
    }

    return metadataCache[addonName]
end