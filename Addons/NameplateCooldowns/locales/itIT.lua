-- luacheck: no max line length
-- luacheck: globals LibStub

local L = LibStub("AceLocale-3.0"):NewLocale("NameplateCooldowns", "itIT");
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
L["chat:addon-is-disabled-note"] = "Nota: questo addon è disabilitato. Puoi riattivarlo nelle opzioni o digitando /nc in chat."
L["chat:default-spell-is-added-to-ignore-list"] = "La magia di default è aggiunta alla lista ignorati: %s. Non riceverai aggiornamento sul tempo di ricarica per questa magia."
L["chat:enable-only-for-target-nameplate"] = "Il tempo di ricarica sarà mostrato solo sulla barra dell'obiettivo."
--[[Translation missing --]]
L["chat:print-updated-spells"] = "%s: your cooldown: %s sec, new cooldown: %s sec"
L["Click on icon to enable/disable tracking"] = "Clicca sull'icona per abilita/disabilitare il monitoraggio"
L["Copy"] = "Copia"
L["Copy other profile to current profile:"] = "Copia un altro profilo nel profilo corrente"
L["Current profile: [%s]"] = "Profilo selezionato: [%s]"
L["Data from '%s' has been successfully copied to '%s'"] = "I dati da '%s' sono stati copiati con successo su '%s'"
L["Delete"] = "Elimina"
L["Delete profile:"] = "Elimina profilo:"
L["Filters"] = "Filtri"
L["filters.instance-types"] = [=[Imposta la visibilità dei tempi di ricarica
in diversi tipi di luoghi]=]
L["Font:"] = "Carattere:"
L["General"] = "Generale"
L["general.sort-mode"] = "Metodologia di ordinamento:"
L["Icon size"] = "Grandezza delle icone"
L["Icon X-coord offset"] = "Coordinate di Offset X dell'icona"
L["Icon Y-coord offset"] = "Coordinate di Offset Y dell'icona"
--[[Translation missing --]]
L["icon-grow-direction:down"] = "Down"
--[[Translation missing --]]
L["icon-grow-direction:left"] = "Left"
--[[Translation missing --]]
L["icon-grow-direction:right"] = "Right"
--[[Translation missing --]]
L["icon-grow-direction:up"] = "Up"
L["instance-type:arena"] = "Arene"
L["instance-type:none"] = "Mondo Aperto"
L["instance-type:party"] = "Gruppo da 5"
L["instance-type:pvp"] = "Campi di Battaglia"
--[[Translation missing --]]
L["instance-type:pvp_bg_40ppl"] = "Epic Battlegrounds"
L["instance-type:raid"] = "Spedizioni e Scorrerie"
L["instance-type:scenario"] = "Scenario"
L["instance-type:unknown"] = "Scorreria sconosciuta (alcuni scenari legati alle quest)"
L["MISC"] = "MISC"
--[[Translation missing --]]
L["msg:question:import-existing-spells"] = [=[NameplateCooldowns
There are updated cooldowns for some of your spells. Do you want to apply update?]=]
L["New spell has been added: %s"] = "Una nuova magia è stata aggiunta: %s"
L["Options are not available in combat!"] = "Non è possibile accedere alle opzioni in combattimento!"
--[[Translation missing --]]
L["options:borders:show-blizz-borders"] = "Show Blizzard's borders around icons"
--[[Translation missing --]]
L["options:building-cache"] = [=[Loading spells info (%s%%)...
Some functions may be unavailable]=]
--[[Translation missing --]]
L["options:category:borders"] = "Borders"
--[[Translation missing --]]
L["options:category:spells"] = "Spells"
--[[Translation missing --]]
L["options:category:text"] = "Text"
--[[Translation missing --]]
L["options:general:anchor-point"] = "Anchor point"
--[[Translation missing --]]
L["options:general:anchor-point-to-parent"] = "Anchor point (to parent)"
--[[Translation missing --]]
L["options:general:enable-only-for-target-nameplate"] = "Show the cooldowns on the current target nameplate only"
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
--[[Translation missing --]]
L["options:general:space-between-icons"] = "Space between icons (px)"
--[[Translation missing --]]
L["options:general:test-mode"] = "Test mode"
--[[Translation missing --]]
L["options:profiles"] = "Profiles"
--[[Translation missing --]]
L["options:spells:add-new-spell"] = "Add new spell (name or id):"
--[[Translation missing --]]
L["options:spells:add-spell"] = "Add spell"
--[[Translation missing --]]
L["options:spells:click-to-select-spell"] = "Click to select spell"
--[[Translation missing --]]
L["options:spells:click-to-select-spell:test-mode"] = "You can't edit spells in test mode"
--[[Translation missing --]]
L["options:spells:cooldown-time"] = "Cooldown time"
--[[Translation missing --]]
L["options:spells:custom-cooldown"] = "Custom cooldown value"
--[[Translation missing --]]
L["options:spells:custom-cooldown-value"] = "Cooldown (sec)"
--[[Translation missing --]]
L["options:spells:delete-all-spells"] = "Delete all spells"
--[[Translation missing --]]
L["options:spells:delete-all-spells-confirmation"] = "Do you really want to delete ALL spells?"
--[[Translation missing --]]
L["options:spells:delete-spell"] = "Delete spell"
--[[Translation missing --]]
L["options:spells:disable-all-spells"] = "Disable all spells"
--[[Translation missing --]]
L["options:spells:enable-all-spells"] = "Enable all spells"
--[[Translation missing --]]
L["options:spells:enable-tracking-of-this-spell"] = "Enable tracking of this spell"
--[[Translation missing --]]
L["options:spells:icon-glow"] = "Icon glow is disabled"
--[[Translation missing --]]
L["options:spells:icon-glow-always"] = "Icon will glow if spell is on cooldown"
--[[Translation missing --]]
L["options:spells:icon-glow-threshold"] = "Icon will glow if remaining time is less than"
--[[Translation missing --]]
L["options:spells:please-push-once-more"] = "Please push once more"
--[[Translation missing --]]
L["options:spells:track-only-this-spellid"] = [=[Track only these spell IDs
(comma-separated)]=]
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
L["Profile '%s' has been successfully deleted"] = "Il profilo '%s' è stato creato con successo"
--[[Translation missing --]]
L["Show border around interrupts"] = "Show border around interrupts"
--[[Translation missing --]]
L["Show border around trinkets"] = "Show border around trinkets"
L["Unknown spell: %s"] = "Magia sconosciuta: %s"
L["Value must be a number"] = "Il valore deve essere un numero"

--@end-non-debug@
