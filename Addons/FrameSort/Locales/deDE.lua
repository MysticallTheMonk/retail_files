local _, addon = ...
local L = addon.Locale
local wow = addon.WoW.Api

if wow.GetLocale() ~= "deDE" then
    return
end

-- # Main Options screen #
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issuse that may prevent FrameSort from working correctly."] = "Es gibt einige Probleme, die verhindern können, dass FrameSort korrekt funktioniert."
L["Please go to the Health Check panel to view more details."] = "Bitte gehen Sie zum Gesundheitsprüfungsbereich, um weitere Details zu sehen."
L["Role/spec"] = "Rolle/Spezialisierung"
L["Group"] = "Gruppe"
L["Alphabetical"] = "Alphabetisch"
L["Arena - 2v2"] = "Arena - 2v2"
L["Arena - 3v3"] = "Arena - 3v3"
L["Arena - 3v3 & 5v5"] = "Arena - 3v3 & 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "Gegnerische Arena (siehe Addons-Bereich für unterstützte Addons)"
L["Dungeon (mythics, 5-mans, delves)"] = "Dungeon (mythische Dungeons, 5-Spieler, Erkundungen)"
L["Raid (battlegrounds, raids)"] = "Schlachtzug (Schlachtfelder, Raids)"
L["World (non-instance groups)"] = "Welt (nicht-instanzielle Gruppen)"
L["Player"] = "Spieler"
L["Sort"] = "Sortieren"
L["Top"] = "Oben"
L["Middle"] = "Mitte"
L["Bottom"] = "Unten"
L["Hidden"] = "Hidden"
L["Group"] = "Gruppe"
L["Reverse"] = "Umkehren"

-- # Sorting Method screen #
L["Sorting Method"] = "Sortiermethode"
L["Secure"] = "Sicher"
L["SortingMethod_Secure_Description"] = [[
Passt die Position jedes einzelnen Rahmens an und verursacht keine Fehler/Einfrierungen des UIs.
\n
Vorteile:
 - Kann Rahmen von anderen Addons sortieren.
 - Kann Rahmenabstände anwenden.
 - Kein Taint (technischer Begriff für Addons, die mit Blizzards UI-Code interferieren).
\n
Nachteile:
 - Fragile Kartenhaus-Situation, um die Spaghetti von Blizzard zu umgehen.
 - Kann bei WoW-Patches brechen und den Entwickler verrückt machen.
]]
L["Traditional"] = "Traditionell"
L["SortingMethod_Traditional_Description"] = [[
Dies ist der Standard-Sortiermodus, den Addons und Makros seit über 10 Jahren verwenden.
Es ersetzt die interne Blizzard-Sortiermethode durch unsere eigene.
Dies ist dasselbe wie das Skript 'SetFlowSortFunction', aber mit FrameSort-Konfiguration.
\n
Vorteile:
 - Stabiler/zuverlässiger, da es Blizzards interne Sortiermethoden nutzt.
\n
Nachteile:
 - Sortiert nur Blizzards Gruppensrahmen, sonst nichts.
 - Verursacht Lua-Fehler, was normal ist und ignoriert werden kann.
 - Kann keine Rahmenabstände anwenden.
]]
L["Please reload after changing these settings."] = "Bitte laden Sie die Einstellungen neu, nachdem Sie diese geändert haben."
L["Reload"] = "Neu laden"

-- # Ordering screen #
L["Ordering"] = "Bestellung"
L["Specify the ordering you wish to use when sorting by role."] = "Geben Sie die Reihenfolge an, die Sie beim Sortieren nach Rolle verwenden möchten."
L["Tanks"] = "Tank"
L["Healers"] = "Heiler"
L["Casters"] = "Zauberer"
L["Hunters"] = "Jäger"
L["Melee"] = "Nahkämpfer"

-- # Auto Leader screen #
L["Auto Leader"] = "Auto-Leiter"
L["Auto promote healers to leader in solo shuffle."] = "Heiler automatisch zum Leiter im Solo-Shuffle befördern."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] = "Warum? Damit Heiler Zielmarkierungsikonen konfigurieren und die Gruppenpositionen nach ihren Wünschen anpassen können."
L["Enabled"] = "Aktiviert"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "Zielauswahl"
L["Target frame 1 (top frame)"] = "Zielrahmen 1 (oberer Rahmen)"
L["Target frame 2"] = "Zielrahmen 2"
L["Target frame 3"] = "Zielrahmen 3"
L["Target frame 4"] = "Zielrahmen 4"
L["Target frame 5"] = "Zielrahmen 5"
L["Target bottom frame"] = "Ziel unterer Rahmen"
L["Target 1 frame above bottom"] = "Ziele 1 Rahmen über dem unteren"
L["Target 2 frames above bottom"] = "Ziele 2 Rahmen über dem unteren"
L["Target 3 frames above bottom"] = "Ziele 3 Rahmen über dem unteren"
L["Target 4 frames above bottom"] = "Ziele 4 Rahmen über dem unteren"
L["Target frame 1's pet"] = "Ziel des Haustiers von Rahmen 1"
L["Target frame 2's pet"] = "Ziel des Haustiers von Rahmen 2"
L["Target frame 3's pet"] = "Ziel des Haustiers von Rahmen 3"
L["Target frame 4's pet"] = "Ziel des Haustiers von Rahmen 4"
L["Target frame 5's pet"] = "Ziel des Haustiers von Rahmen 5"
L["Target enemy frame 1"] = "Ziel feindlicher Rahmen 1"
L["Target enemy frame 2"] = "Ziel feindlicher Rahmen 2"
L["Target enemy frame 3"] = "Ziel feindlicher Rahmen 3"
L["Target enemy frame 1's pet"] = "Ziel des Haustiers von feindlichem Rahmen 1"
L["Target enemy frame 2's pet"] = "Ziel des Haustiers von feindlichem Rahmen 2"
L["Target enemy frame 3's pet"] = "Ziel des Haustiers von feindlichem Rahmen 3"
L["Focus enemy frame 1"] = "Fokus auf feindlichen Rahmen 1"
L["Focus enemy frame 2"] = "Fokus auf feindlichen Rahmen 2"
L["Focus enemy frame 3"] = "Fokus auf feindlichen Rahmen 3"
L["Cycle to the next frame"] = "Wechseln zum nächsten Rahmen"
L["Cycle to the previous frame"] = "Wechseln zum vorherigen Rahmen"
L["Target the next frame"] = "Ziel den nächsten Rahmen"
L["Target the previous frame"] = "Ziel den vorherigen Rahmen"

-- # Keybindings screen #
L["Keybindings"] = "Tastenbelegung"
L["Keybindings_Description"] = [[
Sie finden die FrameSort-Tastenbelegungen im Standard-WoW-Bereich für Tastenbelegungen.
\n
Wozu sind die Tastenbelegungen nützlich?
Sie sind nützlich, um Spieler anhand ihrer visuell angeordneten Darstellung zu zielen, anstatt ihrer
Gruppenposition (party1/2/3/etc.).
\n
Zum Beispiel, stellen Sie sich eine Gruppe von 5 Spielern vor, sortiert nach Rolle, die wie folgt aussieht:
  - Tank, party3
  - Heiler, Spieler
  - DPS, party1
  - DPS, party4
  - DPS, party2
\n
Wie Sie sehen können, unterscheidet sich ihre visuelle Darstellung von ihrer tatsächlichen Gruppenposition, was
das Zielen verwirrend macht.
Wenn Sie /target party1 eingeben würden, würde es den DPS-Spieler in Position 3 zielen, anstatt den Tank.
\n
FrameSort-Tastenbelegungen zielen basierend auf ihrer visuellen Rahmenposition anstelle der Gruppennummer.
Das bedeutet, dass das Zielen auf 'Rahmen 1' den Tank zielt, 'Rahmen 2' den Heiler, 'Rahmen 3' den DPS in Position 3, und so weiter.
]]

-- # Macros screen # --
L["Macros"] = "Makros"
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort hat %d |4Makro:Makros; gefunden, die verwaltet werden müssen."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] = "FrameSort wird Variablen innerhalb von Makros, die den Kopfzeilen '#FrameSort' enthalten, dynamisch aktualisieren."
L["Below are some examples on how to use this."] = "Im Folgenden sind einige Beispiele, wie man dies nutzt."

L["Macro_Example1"] = [[#showtooltip
#FrameSort Mouseover, Target, Heaker
/cast [@mouseover,help][@target,help][@healer,exists] Segen der Zuflucht]]

L["Macro_Example2"] = [[#showtooltip
#FrameSort Frame1, Frame2, Player
/cast [mod:ctrl,@frame1][mod:shift,@frame2][mod:alt,@player][] Entzaubern]]

L["Macro_Example3"] = [[#FrameSort EnemyHealer, EnemyHealer
/cast [@doesntmatter] Schattenhieb;
/cast [@placeholder] Unterbrecher;]]

L["Example %d"] = "Beispiel %d"
L["Supported variables:"] = "Unterstützte Variablen:"
L["The first DPS that's not you."] = "Der erste DPS, der nicht Sie sind."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "Fügen Sie eine Zahl hinzu, um das Nth-Ziel auszuwählen, z.B. DPS2 wählt den 2. DPS."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] = "Variablen sind nicht case-sensitiv, also 'fRaMe1', 'Dps', 'enemyhealer' usw. funktionieren alle."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "Müssen Sie Platz bei den Makrozeichen sparen? Verwenden Sie Abkürzungen, um sie zu verkürzen:"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = 'Benutzen Sie "X", um FrameSort zu sagen, einen @unit-Wähler zu ignorieren:'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@gegnerheiler,exists][] Zauber;]]

-- # Spacing screen #
L["Spacing"] = "Abstände"
L["Add some spacing between party, raid, and arena frames."] = "Fügen Sie einige Abstände zwischen Gruppen-/Schlachtzugsrahmen hinzu."
L["This only applies to Blizzard frames."] = "Dies gilt nur für Blizzard-Rahmen."
L["Party"] = "Gruppe"
L["Raid"] = "Schlachtzug"
L["Group"] = "Gruppe"
L["Horizontal"] = "Horizontal"
L["Vertical"] = "Vertikal"

-- # Addons screen #
L["Addons"] = "Addons"
L["Addons_Supported_Description"] = [[
FrameSort unterstützt die folgenden:
\n
Blizzard
 - Gruppe: ja
 - Schlachtzug: ja
 - Arena: ja
\n
ElvUI
 - Gruppe: ja
 - Schlachtzug: nein
 - Arena: nein
\n
sArena
 - Arena: ja
\n
Gladius
 - Arena: ja
 - Bicmex-Version: ja
\n
GladiusEx
 - Gruppe: ja
 - Arena: ja
\n
Cell
 - Gruppe: ja
 - Schlachtzug: ja, nur wenn kombinierte Gruppen verwendet werden.
\n
Shadowed Unit Frames
 - Gruppe: ja
 - Arena: ja
\n
Grid2
 - Gruppe/Schlachtzug: ja
\n
]]

-- # Api screen #
L["Api"] = "Api"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "Möchten Sie FrameSort in Ihre Addons, Skripte und Weak Auras integrieren?"
L["Here are some examples."] = "Hier sind einige Beispiele."
L["Retrieved an ordered array of party/raid unit tokens."] = "Abgerufen wurde ein geordnetes Array von Gruppen-/Schlachtzugs-Unit-Token."
L["Retrieved an ordered array of arena unit tokens."] = "Abgerufen wurde ein geordnetes Array von Arena-Unit-Tokens."
L["Register a callback function to run after FrameSort sorts frames."] = "Registrieren Sie eine Rückruffunktion, die ausgeführt wird, nachdem FrameSort die Rahmen sortiert hat."
L["Retrieve an ordered array of party frames."] = "Ein geordnetes Array von Gruppenrahmen abrufen."
L["Change a FrameSort setting."] = "Eine FrameSort-Einstellung ändern."
L["View a full listing of all API methods on GitHub."] = "Sehen Sie sich eine vollständige Liste aller API-Methoden auf GitHub an."

-- # Help screen #
L["Help"] = "Hilfe"
L["Discord"] = "Discord"
L["Need help with something?"] = "Brauchen Sie Hilfe bei etwas?"
L["Talk directly with the developer on Discord."] = "Sprechen Sie direkt mit dem Entwickler auf Discord."

-- # Health Check screen -- #
L["Health Check"] = "Gesundheitsprüfung"
L["Try this"] = "Versuchen Sie dies"
L["Any known issues with configuration or conflicting addons will be shown below."] = "Alle bekannten Probleme mit der Konfiguration oder konfliktierenden Addons werden unten angezeigt."
L["N/A"] = "Nicht verfügbar"
L["Passed!"] = "Bestanden!"
L["Failed"] = "Fehlgeschlagen"
L["(unknown)"] = "(unbekannt)"
L["(user macro)"] = "(Benutzermakro)"
L["Using grouped layout for Cell raid frames"] = "Verwende gruppiertes Layout für Cell-Schlachtzugsrahmen"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Bitte aktivieren Sie die Option 'Kombinierte Gruppen (Raid)' in Cell ->Layouts"
L["Can detect frames"] = "Kann Rahmen erkennen"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort unterstützt derzeit Rahmen von diesen Addons: %s"
L["Using Raid-Style Party Frames"] = "Verwenden von Raid-Stil Gruppenrahmen"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "Bitte aktivieren Sie 'Raid-Stil Gruppenrahmen verwenden' in den Blizzard-Einstellungen"
L["Keep Groups Together setting disabled"] = "Die Einstellung 'Gruppen zusammenhalten' ist deaktiviert"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "Ändern Sie den Anzeige-Modus für Raids auf eine der Optionen 'Kombinierte Gruppen' im Bearbeitungsmodus"
L["Disable the 'Keep Groups Together' raid profile setting."] = "Deaktivieren Sie die 'Gruppen zusammenhalten' Schlachtzugsprofileinstellung."
L["Only using Blizzard frames with Traditional mode"] = "Verwenden nur Blizzard-Rahmen im traditionellen Modus"
L["Traditional mode can't sort your other frame addons: '%s'"] = "Der traditionelle Modus kann Ihre anderen Rahmen-Addons nicht sortieren: '%s'"
L["Using Secure sorting mode when spacing is being used"] = "Verwenden Sie den sicheren Sortiermodus, wenn Abstände verwendet werden."
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] = "Der traditionelle Modus kann keine Abstände anwenden. Erwägen Sie, Abstände zu entfernen oder die sichere Sortiermethode zu verwenden."
L["Blizzard sorting functions not tampered with"] = "Blizzard-Sortierfunktionen nicht manipuliert"
L['"%s" may cause conflicts, consider disabling it'] = '"%s" kann Konflikte verursachen, erwägen Sie, es zu deaktivieren'
L["No conflicting addons"] = "Keine konfliktierenden Addons"
L["Main tank and assist setting disabled"] = "Einstellung für Haupttank und Unterstützung deaktiviert"
L["Please disable the 'Display Main Tank and Assist' option in Options -> Interface -> Raid Frames"] = "Bitte deaktivieren Sie die Option 'Haupttank und Unterstützung anzeigen' in Optionen -> Benutzeroberfläche -> Raid-Rahmen"
