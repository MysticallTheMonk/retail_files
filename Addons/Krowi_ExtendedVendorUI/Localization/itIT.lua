local _, addon = ...
local L = addon.Localization.NewLocale("itIT")
if not L then return end

KrowiEVU.PluginsApi:LoadPluginLocalization(L)

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-15 22-18-36 ]] --
L["Are you sure you want to hide the options button?"] = [=[Vuoi davvero nascondere il pulsante opzioni?
Il pulsante può essere mostrato di nuovo da {gameMenu} {arrow} {interface} {arrow} {addOns} {arrow} {addonName} {arrow} {general} {arrow} {options}]=]
L["Columns"] = "Colonne"
L["Columns first"] = "Prima colonne"
L["Icon Left click"] = "Per le opzioni veloci."
L["Icon Right click"] = "Per opzioni."
L["Options button"] = "Pulsante opzioni"
L["Options Desc"] = "Apri le opzioni che sono visibili dal pulsante opzioni nella finestra del mercante"
L["Plugin_CanIMogIt_Desc"] = [=[Questo plugin corregge la sovrapposizione di icone negli oggetti dei mercanti quando sono applicati diversi filtri.

Non ci sono opzioni.]=]
L["Plugin_CanIMogIt_Name"] = true
L["Rows"] = "Righe"
L["Rows first"] = "Prima righe"
L["Show options button"] = "Mostra il pulsante opzioni"
L["Show options button Desc"] = "Mostra / nascondi il pulsante opzioni nella finestra del mercante."