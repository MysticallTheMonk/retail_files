-- luacheck: no max line length
-- luacheck: globals LibStub

local L = LibStub("AceLocale-3.0"):NewLocale("NameplateCooldowns", "esES");
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
L["chat:addon-is-disabled-note"] = "Tenga en cuenta que este addon está deshabilitado. Puede habilitarlo en la opción de diálogo (/nc)"
L["chat:default-spell-is-added-to-ignore-list"] = "Por defecto, este hechizo está en la lista de ignorados: %s. No verás ninguna actualización relativa a la reutilización de este hechizo."
L["chat:enable-only-for-target-nameplate"] = "Los CSs (tiempo de reutilización) se mostrarán únicamente en las barras de nombre."
L["chat:print-updated-spells"] = "%s: Reutilización: %s segundos, nuevo: %s s."
L["Click on icon to enable/disable tracking"] = "Haz click en el icono para activar/desactivar seguimiento."
L["Copy"] = "Copiar"
L["Copy other profile to current profile:"] = "Copiar otro perfil al perfil actual:"
L["Current profile: [%s]"] = "Perfil actual: [%s]"
L["Data from '%s' has been successfully copied to '%s'"] = "Los datos de '%s' han sido copiados correctamente a '%s'"
L["Delete"] = "Borrar"
L["Delete profile:"] = "Borrar perfil:"
L["Filters"] = "Filtros"
L["filters.instance-types"] = [=[Asigna la visibilidad de los cooldowns en distintos tipos
de entornos (grupo de mazmorra, grupo de raid, arena...)]=]
L["Font:"] = "Fuente"
L["General"] = "General"
L["general.sort-mode"] = "Ordenar:"
L["Icon size"] = "Tamaño del icono"
L["Icon X-coord offset"] = "Coordenada X del icono"
L["Icon Y-coord offset"] = "Coordenada Y del icono"
--[[Translation missing --]]
L["icon-grow-direction:down"] = "Down"
--[[Translation missing --]]
L["icon-grow-direction:left"] = "Left"
--[[Translation missing --]]
L["icon-grow-direction:right"] = "Right"
--[[Translation missing --]]
L["icon-grow-direction:up"] = "Up"
L["instance-type:arena"] = "Arenas"
L["instance-type:none"] = "Mundo"
L["instance-type:party"] = "Grupo de mazmorra"
L["instance-type:pvp"] = "Campos de batalla"
--[[Translation missing --]]
L["instance-type:pvp_bg_40ppl"] = "Epic Battlegrounds"
L["instance-type:raid"] = "Grupo de Banda"
L["instance-type:scenario"] = "Escenarios"
L["instance-type:unknown"] = "Mazmorras desconocidas (gestas, escenarios...)"
L["MISC"] = "Miscelánea"
L["msg:question:import-existing-spells"] = [=[NameplateCooldowns
Ha habido cambios en algunos de tus hechizos y sus reutilizaciones. ¿Quieres comprobar si hay actualizaciones?]=]
L["New spell has been added: %s"] = "Añadido un nuevo hechizo: %s"
L["Options are not available in combat!"] = "Las opciones no estan disponibles en combate!"
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
L["options:general:enable-only-for-target-nameplate"] = [=[Mostrar los cooldowns sólamente
en la barra de vida del objetivo]=]
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
L["options:general:space-between-icons"] = "Espacio entre los iconos (píxeles)"
--[[Translation missing --]]
L["options:general:test-mode"] = "Test mode"
--[[Translation missing --]]
L["options:profiles"] = "Profiles"
L["options:spells:add-new-spell"] = "Añade un nuevo hechizo (nombre o ID)"
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
L["options:spells:delete-all-spells-confirmation"] = "¿De verdad quieres borrar TODOS los hechizos?"
L["options:spells:delete-spell"] = "Borrar hechizo"
L["options:spells:disable-all-spells"] = "Deshabilitar todos los hechizos"
L["options:spells:enable-all-spells"] = "Habilitar todos los hechizos"
L["options:spells:enable-tracking-of-this-spell"] = "Habilitar seguimiento de este hechizo"
L["options:spells:icon-glow"] = "El brillo del icono está desactivado."
L["options:spells:icon-glow-always"] = "El icono siempre brilla si el hechizo está en cooldown"
L["options:spells:icon-glow-threshold"] = [=[El hechizo brillará solamente si el tiempo
 de reutilización es menor que]=]
L["options:spells:please-push-once-more"] = "Por favor presione una vez más"
L["options:spells:track-only-this-spellid"] = "Seguir solamente estos hechizos (ID de los hechizos separadas por coma)"
L["options:text:anchor-point"] = "Punto de anclaje"
L["options:text:anchor-to-icon"] = "Anclar al ícono"
L["options:text:color"] = "Color de texto"
L["options:text:font"] = "Fuente"
L["options:text:font-scale"] = "Escala de la fuente"
L["options:text:font-size"] = "Tamaño de fuente"
L["options:timer-text:scale-font-size"] = [=[Escalar fuente de acuerdo
al tamaño del ícono]=]
L["Profile '%s' has been successfully deleted"] = "Perfil \"%s\" ha sido borrado con exito"
L["Show border around interrupts"] = "Mostrar bordes alrededor de interrupciones"
L["Show border around trinkets"] = "Mostrar bordes alrededor de abalorios"
L["Unknown spell: %s"] = "Hechizo desconocido: %s"
L["Value must be a number"] = "El valor debe ser numerico"

--@end-non-debug@
