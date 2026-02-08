--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('itIT')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-12 19-40-14 ]] --
L['Author'] = 'Autore'
L['Build'] = 'Versione'
L['Checked'] = 'Selezionato'
L['CurseForge'] = true
L['CurseForge Desc'] = 'Apri un popup con un link alla pagina di {addonName} su {curseForge}.'
L['Default value'] = 'Valore di default'
L['Discord'] = true
L['Discord Desc'] = "Apri un popup con un link al server discord {serverName}. Quì potrai inserire commenti, reports, osservazioni, idee o qualsiasi altra cosa relativa all'addOn."
L['Hide'] = 'Nascondi'
L['Right click'] = 'Click destro'
L['Show minimap icon'] = "Mostra l'icona nella minimappa"
L['Show minimap icon Desc'] = 'Mostra / nascondi il pulsante opzioni nella minimappa.'
L['Unchecked'] = 'Non selezionato'
L['Wago'] = true