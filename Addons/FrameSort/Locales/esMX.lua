local _, addon = ...
local L = addon.Locale.esMX

-- # Main Options screen #
-- used in FrameSort - 1.2.3 version header, %s is the version number
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issues that may prevent FrameSort from working correctly."] = "Hay algunos problemas que pueden impedir que FrameSort funcione correctamente."
L["Please go to the Health Check panel to view more details."] = "Ve al panel Revisión de estado para ver más detalles."
L["Role"] = "Rol"
L["Spec"] = "Spec"
L["Group"] = "Grupo"
L["Alphabetical"] = "Alfabético"
L["Arena - 2v2"] = "Arena - 2v2"
L["Arena - 3v3"] = "Arena - 3v3"
L["Arena - 3v3 & 5v5"] = "Arena - 3v3 y 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "Arena enemiga (consulta el panel de complementos para los complementos compatibles)"
L["Dungeon (mythics, 5-mans, delves)"] = "Mazmorra (míticas, grupos de 5, excavaciones)"
L["Raid (battlegrounds, raids)"] = "Banda (campos de batalla, bandas)"
L["World (non-instance groups)"] = "Mundo (grupos fuera de instancia)"
L["Player"] = "Jugador"
L["Sort"] = "Ordenar"
L["Top"] = "Arriba"
L["Middle"] = "Medio"
L["Bottom"] = "Abajo"
L["Hidden"] = "Oculto"
L["Group"] = "Grupo"
L["Reverse"] = "Invertir"

-- # Sorting Method screen #
L["Sorting Method"] = "Método de ordenamiento"
L["Secure"] = "Seguro"
L["SortingMethod_Secure_Description"] = [[
Ajusta la posición de cada marco individual y no produce errores/bloqueos/taint en la IU.
\n
Ventajas:
 - Puede ordenar marcos de otros complementos.
 - Puede aplicar espaciado entre marcos.
 - Sin taint (término técnico para cuando los complementos interfieren con el código de la IU de Blizzard).
\n
Desventajas:
 - Es una frágil casa de naipes para esquivar el espagueti de Blizzard.
 - Puede romperse con parches de WoW y hacer que el desarrollador enloquezca.
]]
L["Traditional"] = "Tradicional"
L["SortingMethod_Traditional_Description"] = [[
Este es el modo de ordenamiento estándar que los complementos y macros han usado por más de 10 años.
Reemplaza el método de ordenamiento interno de Blizzard por el nuestro.
Es lo mismo que el script 'SetFlowSortFunction' pero con la configuración de FrameSort.
\n
Ventajas:
 - Más estable/confiable ya que aprovecha los métodos internos de ordenamiento de Blizzard.
\n
Desventajas:
 - Solo ordena los marcos de grupo de Blizzard, nada más.
 - Provocará errores de Lua, lo cual es normal y puede ignorarse.
 - No puede aplicar espaciado entre marcos.
]]
L["Please reload after changing these settings."] = "Vuelve a cargar después de cambiar estas opciones."
L["Reload"] = "Recargar"

-- # Ordering screen #
L["Ordering"] = "Orden"
L["Specify the ordering you wish to use when sorting by spec."] = "Especifica el orden que deseas usar al ordenar por especialización."
L["Tanks"] = "Tanques"
L["Healers"] = "Sanadores"
L["Casters"] = "Lanzadores"
L["Hunters"] = "Cazadores"
L["Melee"] = "Cuerpo a cuerpo"

-- # Spec Priority screen # --
L["Spec Priority"] = "Prioridad de especialización"
L["Spec Type"] = "Tipo de especialización"
L["Choose a spec type, then drag and drop to control priority."] = "Elige un tipo de especialización y arrastra y suelta para controlar la prioridad."
L["Tank"] = "Tanque"
L["Healer"] = "Sanador"
L["Caster"] = "Lanzador"
L["Hunter"] = "Cazador"
L["Melee"] = "Cuerpo a cuerpo"
L["Reset this type"] = "Restablecer este tipo"
L["Spec query note"] = [[
Ten en cuenta que la información de especialización se consulta desde el servidor, lo que tarda entre 1 y 2 segundos por jugador.
\n
Esto significa que puede tardar un poco antes de que podamos ordenar correctamente.
]]

-- # Auto Leader screen #
L["Auto Leader"] = "Líder automático"
L["Auto promote healers to leader in solo shuffle."] = "Ascender automáticamente a los sanadores a líder en Solo Shuffle."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] =
    "¿Por qué? Para que los sanadores puedan configurar los iconos de marcadores de objetivo y reordenar party1/2 a su preferencia."
L["Enabled"] = "Activado"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "Seleccionar objetivo"
L["Target frame 1 (top frame)"] = "Apuntar al marco 1 (marco superior)"
L["Target frame 2"] = "Apuntar al marco 2"
L["Target frame 3"] = "Apuntar al marco 3"
L["Target frame 4"] = "Apuntar al marco 4"
L["Target frame 5"] = "Apuntar al marco 5"
L["Target bottom frame"] = "Apuntar al marco inferior"
L["Target 1 frame above bottom"] = "Apuntar al 1er marco por encima del inferior"
L["Target 2 frames above bottom"] = "Apuntar al 2.º marco por encima del inferior"
L["Target 3 frames above bottom"] = "Apuntar al 3.er marco por encima del inferior"
L["Target 4 frames above bottom"] = "Apuntar al 4.º marco por encima del inferior"
L["Target frame 1's pet"] = "Apuntar a la mascota del marco 1"
L["Target frame 2's pet"] = "Apuntar a la mascota del marco 2"
L["Target frame 3's pet"] = "Apuntar a la mascota del marco 3"
L["Target frame 4's pet"] = "Apuntar a la mascota del marco 4"
L["Target frame 5's pet"] = "Apuntar a la mascota del marco 5"
L["Target enemy frame 1"] = "Apuntar al marco de enemigo 1"
L["Target enemy frame 2"] = "Apuntar al marco de enemigo 2"
L["Target enemy frame 3"] = "Apuntar al marco de enemigo 3"
L["Target enemy frame 1's pet"] = "Apuntar a la mascota del marco de enemigo 1"
L["Target enemy frame 2's pet"] = "Apuntar a la mascota del marco de enemigo 2"
L["Target enemy frame 3's pet"] = "Apuntar a la mascota del marco de enemigo 3"
L["Focus enemy frame 1"] = "Enfocar al marco de enemigo 1"
L["Focus enemy frame 2"] = "Enfocar al marco de enemigo 2"
L["Focus enemy frame 3"] = "Enfocar al marco de enemigo 3"
L["Target the next frame"] = "Apuntar al siguiente marco"
L["Target the previous frame"] = "Apuntar al marco anterior"
L["Cycle to the next frame"] = "Desplazarse al siguiente marco"
L["Cycle to the previous frame"] = "Desplazarse al marco anterior"
L["Cycle to the next dps"] = "Cambiar al siguiente DPS"
L["Cycle to the previous dps"] = "Cambiar al DPS anterior"

-- # Keybindings screen #
L["Keybindings"] = "Atajos de teclado"
L["Keybindings_Description"] = [[
Puedes encontrar los atajos de teclado de FrameSort en el área estándar de atajos de teclado de WoW.
\n
¿Para qué sirven los atajos?
Sirven para apuntar a los jugadores por su representación visual ordenada en lugar de su
posición en el grupo (party1/2/3/etc.).
\n
Por ejemplo, imagina un grupo de mazmorra de 5 jugadores ordenado por rol que se ve así:
  - Tanque, party3
  - Sanador, jugador
  - DPS, party1
  - DPS, party4
  - DPS, party2
\n
Como puedes ver, su representación visual difiere de su posición real en el grupo, lo que
vuelve confuso apuntar.
Si hicieras /target party1, apuntaría al DPS en la posición 3 en lugar del tanque.
\n
Los atajos de FrameSort apuntarán según la posición visual del marco en lugar del número de grupo.
Así, apuntar al 'Marco 1' apuntará al Tanque, al 'Marco 2' al Sanador, al 'Marco 3' al DPS en el lugar 3, y así sucesivamente.
]]

-- # Macros screen # --
L["Macros"] = "Macros"
-- "|4macro:macros;" is a special command to pluralise the word "macro" to "macros" when %d is greater than 1
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort ha encontrado %d |4macro:macros; para administrar."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] =
    'FrameSort actualizará dinámicamente las variables dentro de las macros que contengan el encabezado "#FrameSort".'
L["Below are some examples on how to use this."] = "A continuación hay algunos ejemplos de cómo usar esto."

L["Macro_Example1"] = [[#showtooltip
#FrameSort Mouseover, Target, Healer
/cast [@mouseover,help][@target,help][@healer,exists] Blessing of Sanctuary]]

L["Macro_Example2"] = [[#showtooltip
#FrameSort Frame1, Frame2, Player
/cast [mod:ctrl,@frame1][mod:shift,@frame2][mod:alt,@player][] Dispel]]

L["Macro_Example3"] = [[#FrameSort EnemyHealer, EnemyHealer
/cast [@doesntmatter] Shadowstep;
/cast [@placeholder] Kick;]]

-- %d is the number for example 1/2/3
L["Example %d"] = "Ejemplo %d"
L["Discord Bot Blurb"] = [[
¿Necesitas ayuda para crear una macro?
\n
¡Ve al servidor de Discord de FrameSort y usa nuestro bot de macros con IA!
\n
Simplemente escribe '@Macro Bot' con tu pregunta en el canal #macro-bot-channel.
]]

-- # Macro Variables screen # --
L["Macro Variables"] = "Variables de macro"
L["The first DPS that's not you."] = "El primer DPS que no seas tú."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "Agrega un número para elegir el enésimo objetivo; p. ej., DPS2 selecciona el 2.º DPS."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] =
    "Las variables no distinguen mayúsculas/minúsculas, así que 'fRaMe1', 'Dps', 'enemyhealer', etc., funcionarán."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "¿Necesitas ahorrar caracteres en la macro? Usa abreviaturas para acortarlas:"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = 'Usa "X" para indicarle a FrameSort que ignore un selector @unit:'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Spell;]]

-- # Spacing screen #
L["Spacing"] = "Espaciado"
L["Add some spacing between party, raid, and arena frames."] = "Añade algo de espacio entre los marcos de grupo, banda y arena."
L["This only applies to Blizzard frames."] = "Esto solo se aplica a los marcos de Blizzard."
L["Party"] = "Grupo"
L["Raid"] = "Banda"
L["Group"] = "Grupo"
L["Horizontal"] = "Horizontal"
L["Vertical"] = "Vertical"

-- # Addons screen #
L["Addons"] = "Complementos"
L["Addons_Supported_Description"] = [[
FrameSort es compatible con lo siguiente:
\n
  - Blizzard: grupo, banda, arena.
\n
  - ElvUI: grupo.
\n
  - sArena: arena.
\n
  - Gladius: arena.
\n
  - GladiusEx: grupo, arena.
\n
  - Cell: grupo, banda (solo cuando se usan grupos combinados).
\n
  - Shadowed Unit Frames: grupo, arena.
\n
  - Grid2: grupo, banda.
\n
  - BattleGroundEnemies: grupo, arena.
\n
  - Gladdy: arena.
\n
  - Arena Core: 0.9.1.7+.
\n
]]

-- # Api screen #
L["Api"] = "API"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "¿Quieres integrar FrameSort en tus complementos, scripts y WeakAuras?"
L["Here are some examples."] = "Aquí hay algunos ejemplos."
L["Retrieved an ordered array of party/raid unit tokens."] = "Obtener un arreglo ordenado de tokens de unidad de grupo/banda."
L["Retrieved an ordered array of arena unit tokens."] = "Obtener un arreglo ordenado de tokens de unidad de arena."
L["Register a callback function to run after FrameSort sorts frames."] = "Registrar una función de devolución de llamada para ejecutar después de que FrameSort ordene los marcos."
L["Retrieve an ordered array of party frames."] = "Obtener un arreglo ordenado de marcos de grupo."
L["Change a FrameSort setting."] = "Cambiar una configuración de FrameSort."
L["Get the frame number of a unit."] = "Obtiene el número de marco de una unidad."
L["View a full listing of all API methods on GitHub."] = "Ver un listado completo de todos los métodos de la API en GitHub."

-- # Discord screen #
L["Discord"] = "Discord"
L["Need help with something?"] = "¿Necesitas ayuda con algo?"
L["Talk directly with the developer on Discord."] = "Habla directamente con el desarrollador en Discord."

-- # Health Check screen -- #
L["Health Check"] = "Revisión de estado"
L["Try this"] = "Prueba esto"
L["Any known issues with configuration or conflicting addons will be shown below."] = "Cualquier problema conocido con la configuración o complementos en conflicto se mostrará abajo."
L["N/A"] = "N/A"
L["Passed!"] = "¡Aprobado!"
L["Failed"] = "Falló"
L["(unknown)"] = "(desconocido)"
L["(user macro)"] = "(macro del usuario)"
L["Using grouped layout for Cell raid frames"] = "Usando diseño agrupado para los marcos de banda de Cell"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Marca la opción 'Combined Groups (Raid)' en Cell -> Layouts"
L["Can detect frames"] = "Puede detectar marcos"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort actualmente admite marcos de estos complementos: %s"
L["Using Raid-Style Party Frames"] = "Usando marcos de grupo con estilo de banda"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "Activa 'Use Raid-Style Party Frames' en la configuración de Blizzard"
L["Keep Groups Together setting disabled"] = "Ajuste 'Keep Groups Together' desactivado"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] =
    "Cambia el modo de visualización de banda a una de las opciones 'Combined Groups' mediante el Modo de edición"
L["Disable the 'Keep Groups Together' raid profile setting."] = "Desactiva la configuración de perfil de banda 'Keep Groups Together'."
L["Only using Blizzard frames with Traditional mode"] = "Solo se usan marcos de Blizzard con el modo Tradicional"
L["Traditional mode can't sort your other frame addons: '%s'"] = "El modo Tradicional no puede ordenar tus otros complementos de marcos: '%s'"
L["Using Secure sorting mode when spacing is being used"] = "Se usa el modo de ordenamiento Seguro cuando se está usando espaciado"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] =
    "El modo Tradicional no puede aplicar espaciado; considera quitar el espaciado o usar el método de ordenamiento Seguro"
L["Blizzard sorting functions not tampered with"] = "Funciones de ordenamiento de Blizzard sin alteraciones"
L['"%s" may cause conflicts, consider disabling it'] = '"%s" puede causar conflictos; considera desactivarlo'
L["No conflicting addons"] = "Sin complementos en conflicto"

-- # Log Screen -- #
L["Log"] = "Registro"
L["FrameSort log to help with diagnosing issues."] = "Registro de FrameSort para ayudar a diagnosticar problemas."
L["Copy Log"] = "Copiar registro"

-- # Notifications -- #
L["Can't do that during combat."] = "No se puede hacer eso durante el combate."

-- # Nameplates screen #
L["Nameplates"] = "Placas de nombre"
L["Friendly Nameplates"] = "Placas de nombre amistosas"
L["Enemy Nameplates"] = "Placas de nombre enemigas"
L["NameplatesBlurb"] = [[
Reemplaza el texto de las placas de nombre de Blizzard y Platynator con variables de FrameSort.
\n
Variables compatibles:
  - $framenumber
  - $name
  - $unit
  - $spec
\n
Ejemplos:
  - Marco - $framenumber
  - $framenumber - $spec
  - $name - $spec
]]

-- # Miscellaneous screen #
L["Miscellaneous"] = "Miscelánea"
L["Various tweaks you can apply."] = "Varios ajustes que puedes aplicar."
L["Player top of role"] = "Jugador en la parte superior del rol"
L["Places you at the top of your corresponding role (healer/tank/dps)."] = "Te coloca en la parte superior de tu rol correspondiente (sanador/tanque/DPS)."

-- # Language screen #
L["Language"] = "Idioma"
L["Specify the language we use."] = "Especifica el idioma que usamos."
