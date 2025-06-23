local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "frFR");
if not L then return end
addon.L = L;

addon.Plugins:LoadLocalization(L);

-- [[ https://legacy.curseforge.com/wow/addons/krowi-extended-vendor-ui/localization ]] --
-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2025-05-15 18-40-47 ]] --
L["Are you sure you want to hide the options button?"] = "Êtes-vous sûr de vouloir cacher le bouton des options ?"
L["Author"] = "Auteur"
L["Build"] = "Version"
L["Checked"] = "Coché"
L["Columns"] = "Colonnes"
L["Columns first"] = "Colonnes d'abord"
L["CurseForge"] = true
L["CurseForge Desc"] = "Ouvre une fenêtre avec un lien vers la page {addonName} {curseForge}."
L["Custom"] = "Personnalisé"
L["Default filters"] = "Filtres par défaut"
L["Default value"] = "Valeur par défaut"
L["Deselect All"] = "Tout désélectionner"
L["Discord"] = true
L["Discord Desc"] = "Ouvre une fenêtre avec un lien vers le serveur Discord {serverName}. Sur ce serveur vous pourrez poster des commentaires, des rapports, des remarques, des idées et toute autre chose."
L["Filters"] = "Filtres"
L["Hide"] = "Cacher"
L["Hide collected"] = "Masquer les collectés"
L["Icon Left click"] = "pour ouvrir la fenêtre des hauts faits"
L["Icon Right click"] = "pour les options."
L["Left click"] = "Clic gauche"
L["Mounts"] = "Montures"
L["Only show"] = "Afficher uniquement"
L["Other"] = "Autre"
L["Pets"] = "Mascottes"
L["Right click"] = "Clic droit"
L["Rows"] = "Lignes"
L["Rows first"] = "Lignes d'abord"
L["Select All"] = "Tout sélectionner"
L["Show minimap icon"] = "Afficher l'icone sur la mini-map"
L["Show minimap icon Desc"] = "Afficher ou masquer l'icône sur la mini-map."
L["Toys"] = "Jouets"
L["Unchecked"] = "Non coché"
L["Wago"] = true
L["Wago Desc"] = "Ouvre une fenêtre avec un lien vers la page {addonName} {wago}."
L["WoWInterface"] = true
L["WoWInterface Desc"] = "Ouvre une fenêtre avec un lien vers la page {addonName} {woWInterface}."