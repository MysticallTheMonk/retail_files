--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('frFR')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-12 19-39-11 ]] --
L['Author'] = 'Auteur'
L['Build'] = 'Version'
L['Checked'] = 'Coché'
L['Credits'] = 'Crédits'
L['CurseForge'] = true
L['CurseForge Desc'] = 'Ouvre une fenêtre avec un lien vers la page {addonName} {curseForge}.'
L['Default value'] = 'Valeur par défaut'
L['Deselect All'] = 'Tout désélectionner'
L['Discord'] = true
L['Discord Desc'] = 'Ouvre une fenêtre avec un lien vers le serveur Discord {serverName}. Sur ce serveur vous pourrez poster des commentaires, des rapports, des remarques, des idées et toute autre chose.'
L['Donations'] = 'Dons'
L['Hide'] = 'Cacher'
L['Left click'] = 'Clic gauche'
L['Left-Click'] = 'Clic gauche'
L['Loaded'] = 'Chargé'
L['Loaded Desc'] = "Indique si l'addon associé au plugin est chargé ou non."
L['Localizations'] = 'Localisations'
L['Plugins'] = true
L['Profiles'] = 'Profils'
L['Requires a reload'] = 'Nécessite un /reload'
L['Right click'] = 'Clic droit'
L['Right-Click'] = 'Clic droit'
L['Select All'] = 'Tout sélectionner'
L['Show minimap icon'] = "Afficher l'icone sur la mini-map"
L['Show minimap icon Desc'] = "Afficher ou masquer l'icône sur la mini-map."
L['Special thanks'] = 'Remerciements spéciaux'
L['Unchecked'] = 'Non coché'
L['Wago'] = true
L['Wago Desc'] = 'Ouvre une fenêtre avec un lien vers la page {addonName} {wago}.'