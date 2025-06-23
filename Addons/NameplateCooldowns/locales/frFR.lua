-- luacheck: no max line length
-- luacheck: globals LibStub

local L = LibStub("AceLocale-3.0"):NewLocale("NameplateCooldowns", "frFR");
L = L or {} -- luacheck: ignore
--@non-debug@
--[[Translation missing --]]
L["anchor-point:bottom"] = "Bottom"
--[[Translation missing --]]
L["anchor-point:bottomleft"] = "Bottom left"
--[[Translation missing --]]
L["anchor-point:bottomright"] = "Bottom right"
--[[Translation missing --]]
L["anchor-point:center"] = "Center"
--[[Translation missing --]]
L["anchor-point:left"] = "Left"
--[[Translation missing --]]
L["anchor-point:right"] = "Right"
--[[Translation missing --]]
L["anchor-point:top"] = "Top"
--[[Translation missing --]]
L["anchor-point:topleft"] = "Top left"
--[[Translation missing --]]
L["anchor-point:topright"] = "Top right"
--[[Translation missing --]]
L["anchor-point:x-offset"] = "X offset"
--[[Translation missing --]]
L["anchor-point:y-offset"] = "Y offset"
L["chat:addon-is-disabled-note"] = "Remarque: cet addon est désactivé. Vous pouvez l'activer dans la fenêtre d'options (/nc)"
L["chat:default-spell-is-added-to-ignore-list"] = "Le sort par défaut est ajoutée à la liste des ignorées : %s. Vous ne recevrez plus de mise à jour sur le temp de recharge pour ce sort."
L["chat:enable-only-for-target-nameplate"] = "Les temps de recharge ne seront visibles que sur la barre de vie de la cible"
L["chat:print-updated-spells"] = "%s: votre temps de recharge: %s sec, nouveau temps de recharge: %s sec"
L["Click on icon to enable/disable tracking"] = "Cliquez sur l'icone pour activer/désactiver le suivi"
L["Copy"] = "Copier"
L["Copy other profile to current profile:"] = "Copier un profil vers le profil actuel"
L["Current profile: [%s]"] = "Profil actuel: [%s]"
L["Data from '%s' has been successfully copied to '%s'"] = "Les données de '%s' ont été copiées vers '%s'"
L["Delete"] = "Effacer"
L["Delete profile:"] = "Effacer le profile :"
L["Filters"] = "Filtres"
L["filters.instance-types"] = [=[Définir la visibilité des temps de recharges dans
des types de lieux différents]=]
L["Font:"] = "Police:"
L["General"] = "Général"
L["general.sort-mode"] = "Sort mode:"
L["Icon size"] = "Taille de l'icone"
L["Icon X-coord offset"] = "Décalage de l'icône : X-coord"
L["Icon Y-coord offset"] = "Décalage de l'icône : Y-coord"
--[[Translation missing --]]
L["icon-grow-direction:down"] = "Down"
--[[Translation missing --]]
L["icon-grow-direction:left"] = "Left"
--[[Translation missing --]]
L["icon-grow-direction:right"] = "Right"
--[[Translation missing --]]
L["icon-grow-direction:up"] = "Up"
L["instance-type:arena"] = "Arènes"
L["instance-type:none"] = "Extérieur"
L["instance-type:party"] = "Donjons à 5"
L["instance-type:pvp"] = "Champs de bataille"
--[[Translation missing --]]
L["instance-type:pvp_bg_40ppl"] = "Epic Battlegrounds"
L["instance-type:raid"] = "Raid"
L["instance-type:scenario"] = "Scénarios "
L["instance-type:unknown"] = "Donjons inconnus (quêtes scénarisées et zones instanciés)"
L["MISC"] = "Divers"
L["msg:question:import-existing-spells"] = "NameplateCooldowns Des mises à jours pour les temps de recharge de certains de vos sorts sont disponibles. Voulez-vous effectuer la mise à jour ?"
L["New spell has been added: %s"] = "Un nouveau sort a été ajouté : %s"
L["Options are not available in combat!"] = "Les options sont indisponibles durant un combat"
--[[Translation missing --]]
L["options:borders:show-blizz-borders"] = "Show Blizzard's borders around icons"
--[[Translation missing --]]
L["options:building-cache"] = [=[Loading spells info (%s%%)...
Some functions may be unavailable]=]
--[[Translation missing --]]
L["options:category:borders"] = "Borders"
L["options:category:spells"] = "Sorts."
--[[Translation missing --]]
L["options:category:text"] = "Text"
--[[Translation missing --]]
L["options:general:anchor-point"] = "Anchor point"
--[[Translation missing --]]
L["options:general:anchor-point-to-parent"] = "Anchor point (to parent)"
L["options:general:enable-only-for-target-nameplate"] = [=[Montrer les temps de recharge sur la barre de vie de la cible
actuelle uniquement]=]
--[[Translation missing --]]
L["options:general:full-opacity-always"] = "Icons are always completely opaque"
--[[Translation missing --]]
L["options:general:full-opacity-always:tooltip"] = "If this option is enabled, the icons will always be completely opaque. If not, the opacity will be the same as the health bar"
--[[Translation missing --]]
L["options:general:icon-grow-direction"] = "Icons' growth direction"
--[[Translation missing --]]
L["options:general:ignore-nameplate-scale"] = "Ignore nameplate scale"
--[[Translation missing --]]
L["options:general:ignore-nameplate-scale:tooltip"] = [=[If this option is checked, icon size will not
change accordingly to nameplate scale
(for example, if nameplate of your target becomes bigger)]=]
--[[Translation missing --]]
L["options:general:inverse-logic"] = "Inverse logic"
--[[Translation missing --]]
L["options:general:inverse-logic:tooltip"] = "Display icon if player IS ABLE to cast certain spell"
--[[Translation missing --]]
L["options:general:show-cd-on-allies"] = "Show cooldowns on nameplates of allies"
--[[Translation missing --]]
L["options:general:show-cooldown-animation"] = "Enable cooldown animation"
--[[Translation missing --]]
L["options:general:show-cooldown-animation:tooltip"] = "Enables spin animation on cooldown icons"
--[[Translation missing --]]
L["options:general:show-cooldown-tooltip"] = "Show cooldown tooltip"
--[[Translation missing --]]
L["options:general:show-inactive-cd"] = "Show inactive cooldowns"
--[[Translation missing --]]
L["options:general:show-inactive-cd:tooltip"] = [=[Pay attention: you will NOT be able to see all available cooldowns!
You will see ONLY those cooldowns that foe has already used]=]
L["options:general:space-between-icons"] = "Espace entre les icônes (px)"
--[[Translation missing --]]
L["options:general:test-mode"] = "Test mode"
--[[Translation missing --]]
L["options:profiles"] = "Profiles"
L["options:spells:add-new-spell"] = "Ajouter nouveau sort (nom ou id):"
L["options:spells:add-spell"] = "Ajouter sort "
L["options:spells:click-to-select-spell"] = "Cliquer pour sélectionner le sort"
--[[Translation missing --]]
L["options:spells:click-to-select-spell:test-mode"] = "You can't edit spells in test mode"
L["options:spells:cooldown-time"] = "Temps de recharge "
--[[Translation missing --]]
L["options:spells:custom-cooldown"] = "Custom cooldown value"
--[[Translation missing --]]
L["options:spells:custom-cooldown-value"] = "Cooldown (sec)"
L["options:spells:delete-all-spells"] = "Supprimer tout les sorts "
L["options:spells:delete-all-spells-confirmation"] = "Êtes-vous sûr de vouloir supprimer TOUT les sorts ?"
L["options:spells:delete-spell"] = "Supprimer sort"
L["options:spells:disable-all-spells"] = "Désactiver tout les sorts "
L["options:spells:enable-all-spells"] = "Activer tout les sorts "
L["options:spells:enable-tracking-of-this-spell"] = "Activer le suivi de ce sort "
L["options:spells:icon-glow"] = "Surbrillance de l'icône désactivée"
L["options:spells:icon-glow-always"] = [=[L'icône sera en surbrillance si le sort est en
rechargement]=]
L["options:spells:icon-glow-threshold"] = [=[l'icône sera en surbrillance uniquement si le temps
restant est inférieur à]=]
L["options:spells:please-push-once-more"] = "Merci d'appuyer une fois de plus"
L["options:spells:track-only-this-spellid"] = "Suivre uniquement l'ID de ces sort"
--[[Translation missing --]]
L["options:text:anchor-point"] = "Anchor point"
--[[Translation missing --]]
L["options:text:anchor-to-icon"] = "Anchor to icon"
--[[Translation missing --]]
L["options:text:color"] = "Text color"
--[[Translation missing --]]
L["options:text:font"] = "Font"
--[[Translation missing --]]
L["options:text:font-scale"] = "Font scale"
--[[Translation missing --]]
L["options:text:font-size"] = "Font size"
--[[Translation missing --]]
L["options:timer-text:scale-font-size"] = [=[Scale font size
according to
icon size]=]
L["Profile '%s' has been successfully deleted"] = "Le profile '%s' a été effacé."
L["Show border around interrupts"] = "Afficher une bordure autour des interruptions"
L["Show border around trinkets"] = "Afficher une bordure autour des bijoux"
L["Unknown spell: %s"] = "Sort inconnu : %s"
L["Value must be a number"] = "La valeur doit être un nombre"

--@end-non-debug@
