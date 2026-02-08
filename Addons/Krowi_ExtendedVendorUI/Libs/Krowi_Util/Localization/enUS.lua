--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewDefaultLocale()
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-12 19-38-31 ]] --
L['Author'] = true
L['Build'] = true
L['Checked'] = true
L['Credits'] = true
L['CurseForge'] = true
L['CurseForge Desc'] = 'Open a popup dialog with a link to the {addonName} {curseForge} page.'
L['Default value'] = true
L['Deselect All'] = true
L['Discord'] = true
L['Discord Desc'] = 'Open a popup dialog with a link to the {serverName} Discord server. Here you can post comments, reports, remarks, ideas or anything else related.'
L['Donations'] = true
L['Hide'] = true
L['Left click'] = true
L['Left-Click'] = true
L['Loaded'] = true
L['Loaded Desc'] = 'Indicates if the addon related to the plugin is loaded or not.'
L['Localizations'] = true
L['Plugins'] = true
L['Profiles'] = true
L['Requires a reload'] = 'Requires a reload to take full effect.'
L['Right click'] = true
L['Right-Click'] = true
L['Select All'] = true
L['Show minimap icon'] = true
L['Show minimap icon Desc'] = 'Show / hide the minimap icon.'
L['Special thanks'] = true
L['Unchecked'] = true
L['Wago'] = true
L['Wago Desc'] = 'Open a popup dialog with a link to the {addonName} {wago} page.'