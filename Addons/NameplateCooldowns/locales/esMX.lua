-- luacheck: no max line length
-- luacheck: globals LibStub

local L = LibStub("AceLocale-3.0"):NewLocale("NameplateCooldowns", "esMX");
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
L["chat:addon-is-disabled-note"] = "Tenga en cuenta: Este addon esta desactivado. Puedes activarlo en la options de dialogo (/nc)"
L["chat:default-spell-is-added-to-ignore-list"] = "Hechizo por defecto a sido añadido a la lista de ignorado: %s. No recibirás actualizaciones de tiempo de reutilización para este hechizo."
L["chat:enable-only-for-target-nameplate"] = "Las reutilizaciones se mostrarán solamente en el objetivo."
L["chat:print-updated-spells"] = "%s: Tu reutilización: %s seg, nueva reutilización: %s seg"
L["Click on icon to enable/disable tracking"] = "Click sobre el icono para habilitar/desactivar el hechizo."
L["Copy"] = "Copiar"
L["Copy other profile to current profile:"] = "Copiar otro perfil al actual:"
L["Current profile: [%s]"] = "Perfil actual: [%s]"
L["Data from '%s' has been successfully copied to '%s'"] = "Los datos de '%s' se han copiado a '%s'"
L["Delete"] = "Borrar"
L["Delete profile:"] = "Borrar perfil:"
L["Filters"] = "Filtros"
L["filters.instance-types"] = [=[Establecer la visibilidad de las reutilizaciones
en diferentes tipos de locaciones]=]
L["Font:"] = "Fuente"
L["General"] = "General"
L["general.sort-mode"] = "Modo de clasificación:"
L["Icon size"] = "Tamaño del icono"
L["Icon X-coord offset"] = "Coordenada X de los iconos"
L["Icon Y-coord offset"] = "Coordenada Y de los iconos"
--[[Translation missing --]]
L["icon-grow-direction:down"] = "Down"
--[[Translation missing --]]
L["icon-grow-direction:left"] = "Left"
--[[Translation missing --]]
L["icon-grow-direction:right"] = "Right"
--[[Translation missing --]]
L["icon-grow-direction:up"] = "Up"
L["instance-type:arena"] = "Arenas"
L["instance-type:none"] = "Mundo abierto"
L["instance-type:party"] = "Calabozos de 5 personas"
L["instance-type:pvp"] = "Campos de batalla"
--[[Translation missing --]]
L["instance-type:pvp_bg_40ppl"] = "Epic Battlegrounds"
L["instance-type:raid"] = "Mazmorras de incursion"
L["instance-type:scenario"] = [=[Escenarios
]=]
L["instance-type:unknown"] = "Calabozos desconocidos (Algunos escenarios de misiones)"
L["MISC"] = "Varios "
L["msg:question:import-existing-spells"] = [=[NameplateCooldowns
Hay reutilizaciones actualizadas para algunas de tus habilidades. Quieres aplicar la actualización?]=]
L["New spell has been added: %s"] = "Se ha agregado un nuevo hechizo: %s"
L["Options are not available in combat!"] = "Configuración no disponible durante el combate!"
--[[Translation missing --]]
L["options:borders:show-blizz-borders"] = "Show Blizzard's borders around icons"
--[[Translation missing --]]
L["options:building-cache"] = [=[Loading spells info (%s%%)...
Some functions may be unavailable]=]
--[[Translation missing --]]
L["options:category:borders"] = "Borders"
L["options:category:spells"] = "Hechizos"
--[[Translation missing --]]
L["options:category:text"] = "Text"
--[[Translation missing --]]
L["options:general:anchor-point"] = "Anchor point"
--[[Translation missing --]]
L["options:general:anchor-point-to-parent"] = "Anchor point (to parent)"
L["options:general:enable-only-for-target-nameplate"] = [=[Mostrar las reutilizaciones solo en la placa
de nombre del objetivo actual]=]
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
L["options:general:space-between-icons"] = "Espacio entre iconos (pixeles)"
--[[Translation missing --]]
L["options:general:test-mode"] = "Test mode"
--[[Translation missing --]]
L["options:profiles"] = "Profiles"
L["options:spells:add-new-spell"] = "Añadir nuevo hechizo (nombre o id):"
L["options:spells:add-spell"] = "Añadir hechizo"
L["options:spells:click-to-select-spell"] = "Click para seleccionar un hechizo"
--[[Translation missing --]]
L["options:spells:click-to-select-spell:test-mode"] = "You can't edit spells in test mode"
L["options:spells:cooldown-time"] = "Tiempo de reutilización"
--[[Translation missing --]]
L["options:spells:custom-cooldown"] = "Custom cooldown value"
--[[Translation missing --]]
L["options:spells:custom-cooldown-value"] = "Cooldown (sec)"
L["options:spells:delete-all-spells"] = "Borrar todos los hechizos"
L["options:spells:delete-all-spells-confirmation"] = "Realmente quieres eliminar todos los hechizos?"
L["options:spells:delete-spell"] = "Borrar hechizo"
--[[Translation missing --]]
L["options:spells:disable-all-spells"] = "Disable all spells"
--[[Translation missing --]]
L["options:spells:enable-all-spells"] = "Enable all spells"
L["options:spells:enable-tracking-of-this-spell"] = "Activar rastreo de este hechizo"
L["options:spells:icon-glow"] = "Resplandor de ícono esta desactivado"
L["options:spells:icon-glow-always"] = [=[El ícono se iluminará si el hechizo esta
en cuenta regresiva]=]
L["options:spells:icon-glow-threshold"] = [=[El ícono se iluminará si el tiempo que queda 
es menos que]=]
--[[Translation missing --]]
L["options:spells:please-push-once-more"] = "Please push once more"
L["options:spells:track-only-this-spellid"] = [=[Rastrear solo IDs de estos Hechizos
(separar con comas)]=]
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
L["Profile '%s' has been successfully deleted"] = "El perfil '%s' ha sido eliminado."
L["Show border around interrupts"] = "Mostrar borde en interrupciones "
L["Show border around trinkets"] = "Mostrar borde en albalorios"
L["Unknown spell: %s"] = "Hechizo desconocido: %s"
L["Value must be a number"] = "El valor debe ser un numero"

--@end-non-debug@
