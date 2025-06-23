local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "itIT");
if not L then return end
addon.L = L;

addon.Plugins:LoadLocalization(L);

-- [[ https://legacy.curseforge.com/wow/addons/krowi-extended-vendor-ui/localization ]] --
-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2025-05-15 18-40-47 ]] --
L["Are you sure you want to hide the options button?"] = [=[Vuoi davvero nascondere il pulsante opzioni?
Il pulsante può essere mostrato di nuovo da {gameMenu} {arrow} {interface} {arrow} {addOns} {arrow} {addonName} {arrow} {general} {arrow} {options}]=]
L["Author"] = "Autore"
L["Build"] = "Versione"
L["Checked"] = "Selezionato"
L["Columns"] = "Colonne"
L["Columns first"] = "Prima colonne"
L["CurseForge"] = true
L["CurseForge Desc"] = "Apri un popup con un link alla pagina di {addonName} su {curseForge}."
L["Default value"] = "Valore di default"
L["Discord"] = true
L["Discord Desc"] = "Apri un popup con un link al server discord {serverName}. Quì potrai inserire commenti, reports, osservazioni, idee o qualsiasi altra cosa relativa all'addOn."
L["Hide"] = "Nascondi"
L["Icon Left click"] = "Per le opzioni veloci."
L["Icon Right click"] = "Per opzioni."
L["Options button"] = "Pulsante opzioni"
L["Options Desc"] = "Apri le opzioni che sono visibili dal pulsante opzioni nella finestra del mercante"
L["Right click"] = "Click destro"
L["Rows"] = "Righe"
L["Rows first"] = "Prima righe"
L["Show minimap icon"] = "Mostra l'icona nella minimappa"
L["Show minimap icon Desc"] = "Mostra / nascondi il pulsante opzioni nella minimappa."
L["Show options button"] = "Mostra il pulsante opzioni"
L["Show options button Desc"] = "Mostra / nascondi il pulsante opzioni nella finestra del mercante."
L["Unchecked"] = "Non selezionato"
L["Wago"] = "Wago "
L["Wago Desc"] = "Apri un popup con un link alla pagina di {addonName} su {wago}."
L["WoWInterface"] = "WoWInterface "
L["WoWInterface Desc"] = "Apri un popup con un link alla pagina di {addonName} su {woWInterface}."