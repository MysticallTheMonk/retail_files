local _, addon = ...
local L = addon.Locale
local wow = addon.WoW.Api

if wow.GetLocale() ~= "esES" then
    return
end

-- # Main Options screen #
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issuse that may prevent FrameSort from working correctly."] = "Hay algunos problemas que pueden impedir que FrameSort funcione correctamente."
L["Please go to the Health Check panel to view more details."] = "Por favor, dirígete al panel de Verificación de Salud para ver más detalles."
L["Role/spec"] = "Rol/especialización"
L["Group"] = "Grupo"
L["Alphabetical"] = "Alfabético"
L["Arena - 2v2"] = "Arena - 2v2"
L["Arena - 3v3"] = "Arena - 3v3"
L["Arena - 3v3 & 5v5"] = "Arena - 3v3 y 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "Arena Enemiga (ver panel de addons para addons soportados)"
L["Dungeon (mythics, 5-mans, delves)"] = "Mazmorras (míticas, 5 jugadores, exploraciones)"
L["Raid (battlegrounds, raids)"] = "Banda (campos de batalla, bandas)"
L["World (non-instance groups)"] = "Mundo (grupos no instanciados)"
L["Player"] = "Jugador"
L["Sort"] = "Ordenar"
L["Top"] = "Arriba"
L["Middle"] = "Medio"
L["Bottom"] = "Abajo"
L["Hidden"] = "Oculto"
L["Group"] = "Grupo"
L["Reverse"] = "Inverso"

-- # Sorting Method screen #
L["Sorting Method"] = "Método de Ordenación"
L["Secure"] = "Seguro"
L["SortingMethod_Secure_Description"] = [[
Ajusta la posición de cada marco individual y no buguea/bloquea/contamina la interfaz de usuario.
\n
Pros:
 - Puede ordenar marcos de otros addons.
 - Puede aplicar espaciado entre marcos.
 - Sin contaminación (término técnico para addons que interfieren con el código UI de Blizzard).
\n
Contras:
 - Situación frágil de cartas en casa para sortear el espagueti de Blizzard.
 - Puede romperse con los parches de WoW y causar que el desarrollador enloquezca.
]]
L["Traditional"] = "Tradicional"
L["SortingMethod_Traditional_Description"] = [[
Este es el modo de ordenación estándar que los addons y macros han utilizado durante más de 10 años.
Reemplaza el método interno de ordenación de Blizzard con el nuestro.
Esto es lo mismo que el script 'SetFlowSortFunction', pero con la configuración de FrameSort.
\n
Pros:
 - Más estable/fiable ya que aprovecha los métodos de ordenación internos de Blizzard.
\n
Contras:
 - Solo ordena los marcos de grupo de Blizzard, nada más.
 - Causará errores de Lua, lo cual es normal y se puede ignorar.
 - No se puede aplicar el espaciado entre marcos.
]]
L["Please reload after changing these settings."] = "Por favor, recarga después de cambiar estas configuraciones."
L["Reload"] = "Recargar"

-- # Ordering screen #
L["Ordering"] = "Orden"
L["Specify the ordering you wish to use when sorting by role."] = "Especifica el orden que deseas usar al ordenar por rol."
L["Tanks"] = "Tanques"
L["Healers"] = "Sanadores"
L["Casters"] = "Hechiceros"
L["Hunters"] = "Cazadores"
L["Melee"] = "Cuerpo a cuerpo"

-- # Auto Leader screen #
L["Auto Leader"] = "Líder Automático"
L["Auto promote healers to leader in solo shuffle."] = "Promover automáticamente a los sanadores como líder en el emparejamiento en solitario."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] = "¿Por qué? Para que los sanadores puedan configurar los íconos de marcadores de objetivo y reordenar party1/2 a su preferencia."
L["Enabled"] = "Habilitado"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "Apuntando"
L["Target frame 1 (top frame)"] = "Marco objetivo 1 (marco superior)"
L["Target frame 2"] = "Marco objetivo 2"
L["Target frame 3"] = "Marco objetivo 3"
L["Target frame 4"] = "Marco objetivo 4"
L["Target frame 5"] = "Marco objetivo 5"
L["Target bottom frame"] = "Marco inferior objetivo"
L["Target 1 frame above bottom"] = "Apunta al marco 1 sobre el inferior"
L["Target 2 frames above bottom"] = "Apunta a 2 marcos sobre el inferior"
L["Target 3 frames above bottom"] = "Apunta a 3 marcos sobre el inferior"
L["Target 4 frames above bottom"] = "Apunta a 4 marcos sobre el inferior"
L["Target frame 1's pet"] = "Mascota del marco 1 objetivo"
L["Target frame 2's pet"] = "Mascota del marco 2 objetivo"
L["Target frame 3's pet"] = "Mascota del marco 3 objetivo"
L["Target frame 4's pet"] = "Mascota del marco 4 objetivo"
L["Target frame 5's pet"] = "Mascota del marco 5 objetivo"
L["Target enemy frame 1"] = "Marco enemigo 1 objetivo"
L["Target enemy frame 2"] = "Marco enemigo 2 objetivo"
L["Target enemy frame 3"] = "Marco enemigo 3 objetivo"
L["Target enemy frame 1's pet"] = "Mascota del marco enemigo 1 objetivo"
L["Target enemy frame 2's pet"] = "Mascota del marco enemigo 2 objetivo"
L["Target enemy frame 3's pet"] = "Mascota del marco enemigo 3 objetivo"
L["Focus enemy frame 1"] = "Enfocar marco enemigo 1"
L["Focus enemy frame 2"] = "Enfocar marco enemigo 2"
L["Focus enemy frame 3"] = "Enfocar marco enemigo 3"
L["Cycle to the next frame"] = "Ciclo al siguiente marco"
L["Cycle to the previous frame"] = "Ciclo al marco anterior"
L["Target the next frame"] = "Apuntar al siguiente marco"
L["Target the previous frame"] = "Apuntar al marco anterior"

-- # Keybindings screen #
L["Keybindings"] = "Atajos"
L["Keybindings_Description"] = [[
Puedes encontrar los atajos de FrameSort en el área estándar de atajos de WoW.
\n
¿Para qué son útiles los atajos?
Son útiles para apuntar a los jugadores por su representación visual ordenada en lugar de por su
posición en el grupo (party1/2/3/etc.)
\n
Por ejemplo, imagina un grupo de mazmorras de 5 jugadores ordenado por rol que se ve como sigue:
  - Tanque, party3
  - Sanador, jugador
  - DPS, party1
  - DPS, party4
  - DPS, party2
\n
Como puedes ver, su representación visual difiere de su posición real en el grupo, lo que
hace que apuntar sea confuso.
Si fueras a /target party1, apuntaría al jugador DPS en la posición 3 en lugar del tanque.
\n
Los atajos de FrameSort apuntarán en función de su posición visual del marco en lugar del número de grupo.
Así que apuntar a 'Marco 1' apuntará al Tanque, 'Marco 2' al sanador, 'Marco 3' al DPS en la posición 3, y así sucesivamente.
]]

-- # Macros screen # --
L["Macros"] = "Macros"
-- "|4macro:macros;" es un comando especial para pluralizar la palabra "macro" a "macros" cuando %d es mayor que 1
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort ha encontrado %d |4macro:macros; para gestionar."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] = "FrameSort actualizará dinámicamente las variables dentro de los macros que contengan el encabezado '#FrameSort'."
L["Below are some examples on how to use this."] = "A continuación se presentan algunos ejemplos sobre cómo usar esto."

L["Macro_Example1"] = [[#showtooltip
#FrameSort Mouseover, Target, Healer
/cast [@mouseover,help][@target,help][@healer,exists] Bendición de Santuario]]

L["Macro_Example2"] = [[#showtooltip
#FrameSort Frame1, Frame2, Player
/cast [mod:ctrl,@frame1][mod:shift,@frame2][mod:alt,@player][] Dispersar]]

L["Macro_Example3"] = [[#FrameSort EnemyHealer, EnemyHealer
/cast [@doesntmatter] Paso de Sombras;
/cast [@placeholder] Patada;]]

-- %d es el número por ejemplo 1/2/3
L["Example %d"] = "Ejemplo %d"
L["Supported variables:"] = "Variables soportadas:"
L["The first DPS that's not you."] = "El primer DPS que no eres tú."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "Agrega un número para elegir el N objetivo, por ejemplo, DPS2 selecciona el segundo DPS."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] = "Las variables no son sensibles a mayúsculas, así que 'fRaMe1', 'Dps', 'enemyhealer', etc., funcionarán."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "¿Necesitas ahorrar en caracteres de macros? Usa abreviaturas para acortarlos:"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = 'Usa "X" para indicar a FrameSort que ignore un selector @unit:'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Hechizo;]]

-- # Spacing screen #
L["Spacing"] = "Espaciado"
L["Add some spacing between party, raid, and arena frames."] = "Añade un poco de espaciado entre los marcos de grupo/banda."
L["This only applies to Blizzard frames."] = "Esto solo se aplica a los marcos de Blizzard."
L["Party"] = "Grupo"
L["Raid"] = "Banda"
L["Group"] = "Grupo"
L["Horizontal"] = "Horizontal"
L["Vertical"] = "Vertical"

-- # Addons screen #
L["Addons"] = "Addons"
L["Addons_Supported_Description"] = [[
FrameSort soporta lo siguiente:
\n
Blizzard
 - Grupo: sí
 - Banda: sí
 - Arena: sí
\n
ElvUI
 - Grupo: sí
 - Banda: no
 - Arena: no
\n
sArena
 - Arena: sí
\n
Gladius
 - Arena: sí
 - versión Bicmex: sí
\n
GladiusEx
 - Grupo: sí
 - Arena: sí
\n
Cell
 - Grupo: sí
 - Banda: sí, solo cuando se usan grupos combinados.
\n
Shadowed Unit Frames
 - Grupo: sí
 - Arena: sí
\n
Grid2
 - Grupo/banda: sí
\n
]]

-- # Api screen #
L["Api"] = "Api"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "¿Quieres integrar FrameSort en tus addons, scripts y Auras Débiles?"
L["Here are some examples."] = "Aquí hay algunos ejemplos."
L["Retrieved an ordered array of party/raid unit tokens."] = "Recuperado un arreglo ordenado de tokens de unidad de grupo/banda."
L["Retrieved an ordered array of arena unit tokens."] = "Recuperado un arreglo ordenado de tokens de unidad de arena."
L["Register a callback function to run after FrameSort sorts frames."] = "Registra una función de callback para ejecutarse después de que FrameSort ordene los marcos."
L["Retrieve an ordered array of party frames."] = "Recuperar un arreglo ordenado de marcos de grupo."
L["Change a FrameSort setting."] = "Cambiar una configuración de FrameSort."
L["View a full listing of all API methods on GitHub."] = "Ver una lista completa de todos los métodos de la API en GitHub."

-- # Help screen #
L["Help"] = "Ayuda"
L["Discord"] = "Discord"
L["Need help with something?"] = "¿Necesitas ayuda con algo?"
L["Talk directly with the developer on Discord."] = "Habla directamente con el desarrollador en Discord."

-- # Health Check screen -- #
L["Health Check"] = "Verificación de Salud"
L["Try this"] = "Prueba esto"
L["Any known issues with configuration or conflicting addons will be shown below."] = "Cualquier problema conocido con la configuración o addons en conflicto se mostrará a continuación."
L["N/A"] = "No disponible"
L["Passed!"] = "¡Aprobado!"
L["Failed"] = "Fallido"
L["(unknown)"] = "(desconocido)"
L["(user macro)"] = "(macro de usuario)"
L["Using grouped layout for Cell raid frames"] = "Usando disposición agrupada para marcos de banda de Cell"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Por favor, verifica la opción 'Grupos Combinados (Banda)' en Cell -> Disposiciones"
L["Can detect frames"] = "Puede detectar marcos"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort actualmente soporta marcos de estos addons: %s"
L["Using Raid-Style Party Frames"] = "Usando Marcos de Grupo de Estilo Banda"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "Por favor, habilita 'Usar Marcos de Grupo de Estilo Banda' en las configuraciones de Blizzard"
L["Keep Groups Together setting disabled"] = "Configuración 'Mantener Grupos Juntos' deshabilitada"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "Cambia el modo de visualización de la banda a una de las opciones de 'Grupos Combinados' a través del Modo de Edición"
L["Disable the 'Keep Groups Together' raid profile setting."] = "Deshabilita la configuración del perfil de banda 'Mantener Grupos Juntos'."
L["Only using Blizzard frames with Traditional mode"] = "Solo usando marcos de Blizzard con el modo Tradicional"
L["Traditional mode can't sort your other frame addons: '%s'"] = "El modo Tradicional no puede ordenar tus otros addons de marcos: '%s'"
L["Using Secure sorting mode when spacing is being used"] = "Usando modo de ordenación Seguro cuando se usa espaciado."
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] = "El modo Tradicional no puede aplicar espaciado, considera eliminar el espaciado o usar el método de ordenación Seguro."
L["Blizzard sorting functions not tampered with"] = "Funciones de ordenación de Blizzard no alteradas"
L['"%s" may cause conflicts, consider disabling it'] = '"%s" puede causar conflictos, considera deshabilitarlo'
L["No conflicting addons"] = "No hay addons en conflicto"
L["Main tank and assist setting disabled"] = "Configuración de tanque principal y asistente deshabilitada"
L["Please disable the 'Display Main Tank and Assist' option in Options -> Interface -> Raid Frames"] = "Por favor, deshabilita la opción 'Mostrar Tanque Principal y Asistente' en Opciones -> Interfaz -> Marcos de Banda"
