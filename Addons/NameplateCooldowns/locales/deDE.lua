-- luacheck: no max line length
-- luacheck: globals LibStub

local L = LibStub("AceLocale-3.0"):NewLocale("NameplateCooldowns", "deDE");
L = L or {} -- luacheck: ignore
--@non-debug@
L["anchor-point:bottom"] = "Unten"
L["anchor-point:bottomleft"] = "Unten links"
L["anchor-point:bottomright"] = "Unten rechts"
L["anchor-point:center"] = "Mitte"
L["anchor-point:left"] = "Links"
L["anchor-point:right"] = "Rechts"
L["anchor-point:top"] = "Oben"
L["anchor-point:topleft"] = "Oben links"
L["anchor-point:topright"] = "Oben rechts"
L["anchor-point:x-offset"] = "X-Versatz"
L["anchor-point:y-offset"] = "Y-Versatz"
L["chat:addon-is-disabled-note"] = "Bitte beachte: Dieses Addon ist deaktiviert. Du kannst es in den Optionen aktivieren (/nc) "
L["chat:default-spell-is-added-to-ignore-list"] = "Standardzauber wird zur Ignorierliste hinzugefügt: %s. Du wirst keine Aktualisierungen von Abklingzeiten für diesen Zauber erhalten."
L["chat:enable-only-for-target-nameplate"] = "Abklingzeiten werden nur auf der Namensplakette deines Ziels angezeigt"
L["chat:print-updated-spells"] = "%s: Deine Abklingzeit: %s Sek., Neue Abklingzeit: %s Sek."
L["Click on icon to enable/disable tracking"] = "Klicke auf das Symbol, um die Verfolgung ein-/auszuschalten"
L["Copy"] = "Kopieren"
L["Copy other profile to current profile:"] = "Kopiere ein anderes Profil zu dem aktuellen:"
L["Current profile: [%s]"] = "Aktuelles Profil: [%s]"
L["Data from '%s' has been successfully copied to '%s'"] = "Daten von '%s' wurden erfolgreich zu '%s' kopiert."
L["Delete"] = "Löschen"
L["Delete profile:"] = "Profil löschen:"
L["Filters"] = "Filter"
L["filters.instance-types"] = [=[Stelle die Sichtbarkeit der Abklingzeiten
abhängig von der Art der Instanzen ein.]=]
L["Font:"] = "Schriftart:"
L["General"] = "Allgemein"
L["general.sort-mode"] = "Sortieren nach:"
L["Icon size"] = "Symbolgröße "
L["Icon X-coord offset"] = "X-Position des Symbols"
L["Icon Y-coord offset"] = "Y-Position des Symbols"
L["icon-grow-direction:down"] = "Nach unten"
L["icon-grow-direction:left"] = "Nach links"
L["icon-grow-direction:right"] = "Nach rechts"
L["icon-grow-direction:up"] = "Nach oben"
L["instance-type:arena"] = "Arenen"
L["instance-type:none"] = "Offene Welt"
L["instance-type:party"] = "5-Mann-Dungeons"
L["instance-type:pvp"] = "Schlachtfelder"
--[[Translation missing --]]
L["instance-type:pvp_bg_40ppl"] = "Epic Battlegrounds"
L["instance-type:raid"] = "Schlachtzüge"
L["instance-type:scenario"] = "Szenarien"
L["instance-type:unknown"] = "Unbekannte Dungeons (Manche Questszenarien)"
L["MISC"] = "Verschiedenes"
L["msg:question:import-existing-spells"] = [=[NameplateCooldowns
Es gibt aktualisierte Abklingzeiten für manche deiner Zauber. Möchtest du sie aktualisieren?]=]
L["New spell has been added: %s"] = "Ein neuer Zauber wurde hinzugefügt: %s"
L["Options are not available in combat!"] = "Einstellungen sind nicht im Kampf verfügbar"
L["options:borders:show-blizz-borders"] = "Blizzards Rahmen um Symbole anzeigen"
--[[Translation missing --]]
L["options:building-cache"] = [=[Loading spells info (%s%%)...
Some functions may be unavailable]=]
L["options:category:borders"] = "Rahmen"
L["options:category:spells"] = "Zauber"
L["options:category:text"] = "Text"
L["options:general:anchor-point"] = "Ankerpunkt"
L["options:general:anchor-point-to-parent"] = "Ankerpunkt (am Parent)"
L["options:general:enable-only-for-target-nameplate"] = [=[Die Abklingzeit nur auf der Namensplakette 
des aktuellen Ziels anzeigen]=]
L["options:general:full-opacity-always"] = "Symbole sind immer komplett undurchsichtig"
L["options:general:full-opacity-always:tooltip"] = "Falls diese Option aktiviert ist, sin die Symbole immer komplett undurchsichtig. Falls nicht, entspricht die Transparenz die des Gesundheitsbalkens"
L["options:general:icon-grow-direction"] = "Die Wuchsrichtung der Symbole"
L["options:general:ignore-nameplate-scale"] = "Namensplakettenskalierung ignorieren"
L["options:general:ignore-nameplate-scale:tooltip"] = "Falls diese Option aktiviert ist, ist die Größe des Symbols nicht abhängig von der Skalierung der Namensplakette. (Zum Beispiel falls die Namensplakette deines Ziels größer wird.)"
L["options:general:inverse-logic"] = "Umgekehrte Logik"
L["options:general:inverse-logic:tooltip"] = "Zeigt das Symbol an, wenn der Spieler in der Lage ist, einen bestimmten Zauber zu wirken"
L["options:general:show-cd-on-allies"] = "Abklingzeiten auf Namensplaketten von Verbündeten anzeigen"
L["options:general:show-cooldown-animation"] = "Abklingzeitanimation aktivieren"
L["options:general:show-cooldown-animation:tooltip"] = "Aktiviert die rotierende Animation auf Abklingzeitsymbolen"
L["options:general:show-cooldown-tooltip"] = "Abklingzeittooltip anzeigen"
L["options:general:show-inactive-cd"] = "Inaktive Abklingzeiten anzeigen"
L["options:general:show-inactive-cd:tooltip"] = [=[Beachte: Du wirst NICHT all verfügbaren Abklingzauber sehen!
Du wirst NUR die Cooldowns sehen, die dieser Spieler bereits genutzt hat]=]
L["options:general:space-between-icons"] = "Platz zwischen Symbolen (px)"
L["options:general:test-mode"] = "Testmodus"
L["options:profiles"] = "Profile"
L["options:spells:add-new-spell"] = "Füge neuen Zauber hinzu (Name oder ID):"
L["options:spells:add-spell"] = "Zauber hinzufügen"
L["options:spells:click-to-select-spell"] = "Klicke, um einen Zauber auszuwählen"
--[[Translation missing --]]
L["options:spells:click-to-select-spell:test-mode"] = "You can't edit spells in test mode"
L["options:spells:cooldown-time"] = "Abklingzeit"
L["options:spells:custom-cooldown"] = "Benutzerdefinierter Abklingzeitwert"
L["options:spells:custom-cooldown-value"] = "Abklingzeit (Sek.)"
L["options:spells:delete-all-spells"] = "Alle Zauber entfernen"
L["options:spells:delete-all-spells-confirmation"] = "Möchtest du wirklich ALLE Zauber entfernen?"
L["options:spells:delete-spell"] = "Zauber löschen"
L["options:spells:disable-all-spells"] = "Alle Zauber deaktivieren"
L["options:spells:enable-all-spells"] = "Alle Zauber aktivieren"
L["options:spells:enable-tracking-of-this-spell"] = "Verfolgung dieses Zaubers aktivieren"
L["options:spells:icon-glow"] = "Symbolleuchten ist deaktiviert"
L["options:spells:icon-glow-always"] = "Symbol wird leuchten, falls der Zauber abklingt"
L["options:spells:icon-glow-threshold"] = [=[Symbol wird leuchten, 
falls die verbleibende Zeit weniger ist als]=]
L["options:spells:please-push-once-more"] = "Bitte drücke noch einmal"
L["options:spells:track-only-this-spellid"] = [=[Nur diese Zauber-IDs verfolgen
(kommasepariert)]=]
L["options:text:anchor-point"] = "Ankerpunkt"
L["options:text:anchor-to-icon"] = "Anker zum Symbol"
L["options:text:color"] = "Schriftfarbe"
L["options:text:font"] = "Schriftart"
L["options:text:font-scale"] = "Schriftskalierung"
L["options:text:font-size"] = "Schriftgröße"
L["options:timer-text:scale-font-size"] = [=[Schriftgröße
gemäß Symbolgröße
skalieren]=]
L["Profile '%s' has been successfully deleted"] = "Profil '%s' wurde erfolgreich gelöscht."
L["Show border around interrupts"] = "Rahmen um Unterbrechungen anzeigen"
L["Show border around trinkets"] = "Rahmen um Schmuckstücke anzeigen"
L["Unknown spell: %s"] = "Unbekannter Zauber: %s"
L["Value must be a number"] = "Der Wert muss eine Zahl sein."

--@end-non-debug@
