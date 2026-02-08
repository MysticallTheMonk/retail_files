local _, addon = ...
local L = addon.Locale.esES

-- # Main Options screen #
-- used in FrameSort - 1.2.3 version header, %s is the version number
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issues that may prevent FrameSort from working correctly."] = "Hay algunos problemas que pueden impedir que FrameSort funcione correctamente."
L["Please go to the Health Check panel to view more details."] = "Ve al panel de Comprobación de estado para ver más detalles."
L["Role"] = "Rol"
L["Spec"] = "Spec"
L["Group"] = "Grupo"
L["Alphabetical"] = "Alfabético"
L["Arena - 2v2"] = "Arena: 2c2"
L["Arena - 3v3"] = "Arena: 3c3"
L["Arena - 3v3 & 5v5"] = "Arena: 3c3 y 5c5"
L["Enemy Arena (see addons panel for supported addons)"] = "Arena enemiga (consulta el panel de addons para ver los addons compatibles)"
L["Dungeon (mythics, 5-mans, delves)"] = "Mazmorra (míticas, grupos de 5, excavaciones)"
L["Raid (battlegrounds, raids)"] = "Banda (campos de batalla, bandas)"
L["World (non-instance groups)"] = "Mundo (grupos no instanciados)"
L["Player"] = "Jugador"
L["Sort"] = "Ordenar"
L["Top"] = "Arriba"
L["Middle"] = "Medio"
L["Bottom"] = "Abajo"
L["Hidden"] = "Oculto"
L["Group"] = "Grupo"
L["Reverse"] = "Invertir"

-- # Sorting Method screen #
L["Sorting Method"] = "Método de ordenación"
L["Secure"] = "Seguro"
L["SortingMethod_Secure_Description"] = [[
Ajusta la posición de cada marco individual y no produce errores, bloqueos ni taint en la IU.
\n
Pros:
 - Puede ordenar marcos de otros addons.
 - Puede aplicar espaciado entre marcos.
 - Sin taint (término técnico para describir addons que interfieren con el código de la IU de Blizzard).
\n
Contras:
 - Solución frágil como un castillo de naipes para sortear el espagueti de Blizzard.
 - Puede romperse con parches de WoW y llevar al desarrollador a la locura.
]]
L["Traditional"] = "Tradicional"
L["SortingMethod_Traditional_Description"] = [[
Este es el modo de ordenación estándar que los addons y macros han usado durante más de 10 años.
Sustituye el método de ordenación interno de Blizzard por el nuestro.
Es lo mismo que el script 'SetFlowSortFunction', pero con la configuración de FrameSort.
\n
Pros:
 - Más estable/fiable, ya que aprovecha los métodos de ordenación internos de Blizzard.
\n
Contras:
 - Solo ordena los marcos de grupo de Blizzard; nada más.
 - Provocará errores de Lua; es normal y se pueden ignorar.
 - No puede aplicar espaciado entre marcos.
]]
L["Please reload after changing these settings."] = "Vuelve a cargar la interfaz tras cambiar estos ajustes."
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
L["Choose a spec type, then drag and drop to control priority."] = "Elige un tipo de especialización y usa arrastrar y soltar para controlar la prioridad."
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
L["Auto promote healers to leader in solo shuffle."] = "Ascender automáticamente a líder a los sanadores en Solo Shuffle."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] =
    "¿Por qué? Para que los sanadores puedan configurar los iconos de marcadores de objetivo y reordenar party1/2 a su gusto."
L["Enabled"] = "Activado"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "Selección de objetivo"
L["Target frame 1 (top frame)"] = "Fijar objetivo del marco 1 (marco superior)"
L["Target frame 2"] = "Fijar objetivo del marco 2"
L["Target frame 3"] = "Fijar objetivo del marco 3"
L["Target frame 4"] = "Fijar objetivo del marco 4"
L["Target frame 5"] = "Fijar objetivo del marco 5"
L["Target bottom frame"] = "Fijar objetivo del marco inferior"
L["Target 1 frame above bottom"] = "Fijar objetivo del marco 1 por encima del inferior"
L["Target 2 frames above bottom"] = "Fijar objetivo del marco 2 por encima del inferior"
L["Target 3 frames above bottom"] = "Fijar objetivo del marco 3 por encima del inferior"
L["Target 4 frames above bottom"] = "Fijar objetivo del marco 4 por encima del inferior"
L["Target frame 1's pet"] = "Fijar objetivo de la mascota del marco 1"
L["Target frame 2's pet"] = "Fijar objetivo de la mascota del marco 2"
L["Target frame 3's pet"] = "Fijar objetivo de la mascota del marco 3"
L["Target frame 4's pet"] = "Fijar objetivo de la mascota del marco 4"
L["Target frame 5's pet"] = "Fijar objetivo de la mascota del marco 5"
L["Target enemy frame 1"] = "Fijar objetivo del marco enemigo 1"
L["Target enemy frame 2"] = "Fijar objetivo del marco enemigo 2"
L["Target enemy frame 3"] = "Fijar objetivo del marco enemigo 3"
L["Target enemy frame 1's pet"] = "Fijar objetivo de la mascota del marco enemigo 1"
L["Target enemy frame 2's pet"] = "Fijar objetivo de la mascota del marco enemigo 2"
L["Target enemy frame 3's pet"] = "Fijar objetivo de la mascota del marco enemigo 3"
L["Focus enemy frame 1"] = "Enfocar marco enemigo 1"
L["Focus enemy frame 2"] = "Enfocar marco enemigo 2"
L["Focus enemy frame 3"] = "Enfocar marco enemigo 3"
L["Target the next frame"] = "Fijar objetivo del siguiente marco"
L["Target the previous frame"] = "Fijar objetivo del marco anterior"
L["Cycle to the next frame"] = "Cambiar al siguiente marco"
L["Cycle to the previous frame"] = "Cambiar al marco anterior"
L["Cycle to the next dps"] = "Cambiar al siguiente DPS"
L["Cycle to the previous dps"] = "Cambiar al DPS anterior"

-- # Keybindings screen #
L["Keybindings"] = "Atajos de teclado"
L["Keybindings_Description"] = [[
Puedes encontrar los atajos de teclado de FrameSort en el área estándar de atajos de teclado de WoW.
\n
¿Para qué sirven los atajos?
Sirven para fijar objetivo a los jugadores según su representación visual ordenada en lugar de su
posición de grupo (party1/2/3/etc.).
\n
Por ejemplo, imagina un grupo de mazmorra de 5 jugadores ordenado por rol que queda así:
  - Tanque, party3
  - Sanador, player
  - DPS, party1
  - DPS, party4
  - DPS, party2
\n
Como puedes ver, su representación visual difiere de su posición real en el grupo, lo que complica fijar objetivos.
Si hicieses /target party1, apuntarías al DPS en la posición 3 en lugar del tanque.
\n
Los atajos de FrameSort apuntarán en función de la posición visual del marco en lugar del número de grupo.
Así, apuntar a 'Marco 1' seleccionará al tanque, 'Marco 2' al sanador, 'Marco 3' al DPS en la posición 3, y así sucesivamente.
]]

-- # Macros screen # --
L["Macros"] = "Macros"
-- "|4macro:macros;" is a special command to pluralise the word "macro" to "macros" when %d is greater than 1
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort ha encontrado %d |4macro:macros; para gestionar."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] =
    'FrameSort actualizará dinámicamente las variables dentro de las macros que contengan la cabecera "#FrameSort".'
L["Below are some examples on how to use this."] = "A continuación tienes algunos ejemplos de cómo usarlo."

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
Pásate por el servidor de Discord de FrameSort y usa nuestro bot de macros con IA.
\n
Simplemente menciona a '@Macro Bot' con tu pregunta en el canal #macro-bot-channel.
]]

-- # Macro Variables screen # --
L["Macro Variables"] = "Variables de macro"
L["The first DPS that's not you."] = "El primer DPS que no seas tú."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "Añade un número para elegir el enésimo objetivo; p. ej., DPS2 selecciona al segundo DPS."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] =
    "Las variables no distinguen entre mayúsculas y minúsculas; 'fRaMe1', 'Dps', 'enemyhealer', etc., funcionarán igual."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "¿Necesitas ahorrar caracteres en la macro? Usa abreviaturas para acortarlas:"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = 'Usa "X" para indicarle a FrameSort que ignore un selector @unit:'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Spell;]]

-- # Spacing screen #
L["Spacing"] = "Espaciado"
L["Add some spacing between party, raid, and arena frames."] = "Añade algo de espaciado entre los marcos de grupo, banda y arena."
L["This only applies to Blizzard frames."] = "Esto solo se aplica a los marcos de Blizzard."
L["Party"] = "Grupo"
L["Raid"] = "Banda"
L["Group"] = "Grupo"
L["Horizontal"] = "Horizontal"
L["Vertical"] = "Vertical"

-- # Addons screen #
L["Addons"] = "Addons"
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
  - Cell: grupo, banda (solo al usar grupos combinados).
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
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "¿Quieres integrar FrameSort en tus addons, scripts y WeakAuras?"
L["Here are some examples."] = "Aquí tienes algunos ejemplos."
L["Retrieved an ordered array of party/raid unit tokens."] = "Obtiene una matriz ordenada de tokens de unidad de grupo/banda."
L["Retrieved an ordered array of arena unit tokens."] = "Obtiene una matriz ordenada de tokens de unidad de arena."
L["Register a callback function to run after FrameSort sorts frames."] = "Registra una función de devolución de llamada para que se ejecute después de que FrameSort ordene los marcos."
L["Retrieve an ordered array of party frames."] = "Obtiene una matriz ordenada de marcos de grupo."
L["Change a FrameSort setting."] = "Cambia un ajuste de FrameSort."
L["Get the frame number of a unit."] = "Obtiene el número de marco de una unidad."
L["View a full listing of all API methods on GitHub."] = "Consulta un listado completo de todos los métodos de la API en GitHub."

-- # Discord screen #
L["Discord"] = "Discord"
L["Need help with something?"] = "¿Necesitas ayuda con algo?"
L["Talk directly with the developer on Discord."] = "Habla directamente con el desarrollador en Discord."

-- # Health Check screen -- #
L["Health Check"] = "Comprobación de estado"
L["Try this"] = "Prueba esto"
L["Any known issues with configuration or conflicting addons will be shown below."] = "Cualquier problema conocido de configuración o addons en conflicto se mostrará a continuación."
L["N/A"] = "N/D"
L["Passed!"] = "¡Correcto!"
L["Failed"] = "Error"
L["(unknown)"] = "(desconocido)"
L["(user macro)"] = "(macro del usuario)"
L["Using grouped layout for Cell raid frames"] = "Usando diseño agrupado para los marcos de banda de Cell"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Activa la opción 'Combined Groups (Raid)' en Cell -> Layouts"
L["Can detect frames"] = "Puede detectar marcos"
L["FrameSort currently supports frames from these addons: %s"] = "Actualmente FrameSort es compatible con marcos de estos addons: %s"
L["Using Raid-Style Party Frames"] = "Usando marcos de grupo con estilo de banda"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "Activa 'Use Raid-Style Party Frames' en la configuración de Blizzard"
L["Keep Groups Together setting disabled"] = "Ajuste 'Mantener los grupos juntos' desactivado"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "Cambia el modo de visualización de banda a una de las opciones 'Combined Groups' mediante Modo de edición"
L["Disable the 'Keep Groups Together' raid profile setting."] = "Desactiva el ajuste de perfil de banda 'Keep Groups Together'."
L["Only using Blizzard frames with Traditional mode"] = "Usando solo marcos de Blizzard con el modo Tradicional"
L["Traditional mode can't sort your other frame addons: '%s'"] = "El modo Tradicional no puede ordenar tus otros addons de marcos: '%s'"
L["Using Secure sorting mode when spacing is being used"] = "Usando el modo de ordenación Seguro cuando se está usando espaciado"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] =
    "El modo Tradicional no puede aplicar espaciado; plantéate quitar el espaciado o usar el método de ordenación Seguro"
L["Blizzard sorting functions not tampered with"] = "Funciones de ordenación de Blizzard sin modificar"
L['"%s" may cause conflicts, consider disabling it'] = '"%s" puede causar conflictos; plantéate desactivarlo'
L["No conflicting addons"] = "No hay addons en conflicto"

-- # Log Screen -- #
L["Log"] = "Registro"
L["FrameSort log to help with diagnosing issues."] = "Registro de FrameSort para ayudar a diagnosticar problemas."
L["Copy Log"] = "Copiar registro"

-- # Notifications -- #
L["Can't do that during combat."] = "No puedes hacer eso durante el combate."

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
