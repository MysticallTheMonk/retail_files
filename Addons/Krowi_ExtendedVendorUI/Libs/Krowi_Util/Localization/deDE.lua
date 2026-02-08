--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('deDE')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-12 19-38-58 ]] --
L['Author'] = 'Autor'
L['Build'] = 'Version'
L['Checked'] = 'Aktivert'
L['Credits'] = true
L['CurseForge'] = true
L['CurseForge Desc'] = 'Öffnet ein Popup-Fenster mit einem Link zur Seite {addonName} {curseForge}.'
L['Default value'] = 'Vorgabewert (Standard)'
L['Deselect All'] = 'Alle abwählen'
L['Discord'] = true
L['Discord Desc'] = 'Öffnet ein Popup-Fenster mit einem Link zum {serverName} Discord-Server. Hier können Sie Kommentare, Berichte, Bemerkungen, Ideen und alles andere posten.'
L['Donations'] = 'Spenden'
L['Hide'] = 'Ausblenden'
L['Left click'] = 'Links-Klick'
L['Left-Click'] = 'Links-Klick'
L['Loaded'] = 'Geladen'
L['Loaded Desc'] = 'Zeigt an, ob das mit dem Plugin verbundene Addon geladen ist oder nicht.'
L['Localizations'] = 'Lokalisierungen'
L['Plugins'] = true
L['Profiles'] = 'Profile'
L['Requires a reload'] = 'Funktioniert erst nach einem /reload.'
L['Right click'] = 'Rechts-Klick'
L['Right-Click'] = 'Rechts-Klick'
L['Select All'] = 'Alle auswählen'
L['Show minimap icon'] = 'Zeige Minimap Icon'
L['Show minimap icon Desc'] = 'Zeige / Verstecke das Minimap Icon.'
L['Special thanks'] = 'Besonderer Dank'
L['Unchecked'] = 'Nicht aktiviert'
L['Wago'] = true
L['Wago Desc'] = 'Öffnet ein Popup-Fenster mit einem Link zur Seite {addonName} {wago}.'