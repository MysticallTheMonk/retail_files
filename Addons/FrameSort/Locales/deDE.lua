local _, addon = ...
local L = addon.Locale.deDE

-- # Main Options screen #
-- used in FrameSort - 1.2.3 version header, %s is the version number
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issues that may prevent FrameSort from working correctly."] = "Es gibt einige Probleme, die möglicherweise verhindern, dass FrameSort korrekt funktioniert."
L["Please go to the Health Check panel to view more details."] = "Bitte öffne den Bereich 'Statusprüfung', um weitere Details zu sehen."
L["Role"] = "Rolle"
L["Spec"] = "Spec"
L["Group"] = "Gruppe"
L["Alphabetical"] = "Alphabetisch"
L["Arena - 2v2"] = "Arena - 2v2"
L["Arena - 3v3"] = "Arena - 3v3"
L["Arena - 3v3 & 5v5"] = "Arena - 3v3 & 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "Feindliche Arena (siehe Addons-Bereich für unterstützte Addons)"
L["Dungeon (mythics, 5-mans, delves)"] = "Dungeon (Mythisch, 5er, Tiefen)"
L["Raid (battlegrounds, raids)"] = "Raid (Schlachtfelder, Schlachtzüge)"
L["World (non-instance groups)"] = "Welt (nicht instanzierte Gruppen)"
L["Player"] = "Spieler"
L["Sort"] = "Sortieren"
L["Top"] = "Oben"
L["Middle"] = "Mitte"
L["Bottom"] = "Unten"
L["Hidden"] = "Versteckt"
L["Group"] = "Gruppe"
L["Reverse"] = "Umkehren"

-- # Sorting Method screen #
L["Sorting Method"] = "Sortiermethode"
L["Secure"] = "Sicher"
L["SortingMethod_Secure_Description"] = [[
Passt die Position jedes einzelnen Frames an und verursacht keine Bugs/Sperren/'Taint' im UI.
\n
Vorteile:
 - Kann Frames anderer Addons sortieren.
 - Kann Abstände zwischen Frames anwenden.
 - Kein Taint (technischer Begriff dafür, dass Addons den Blizzard-UI-Code stören).
\n
Nachteile:
 - Fragile Kartenhaus-Situation, um Blizzards Spaghetti-Code zu umgehen.
 - Kann durch WoW-Patches kaputtgehen und den Entwickler in den Wahnsinn treiben.
]]
L["Traditional"] = "Traditionell"
L["SortingMethod_Traditional_Description"] = [[
Dies ist der Standard-Sortiermodus, den Addons und Makros seit über 10 Jahren verwenden.
Er ersetzt die interne Blizzard-Sortiermethode durch unsere eigene.
Dies entspricht dem Skript 'SetFlowSortFunction', jedoch mit FrameSort-Konfiguration.
\n
Vorteile:
 - Stabiler/zuverlässiger, da Blizzards interne Sortiermethoden genutzt werden.
\n
Nachteile:
 - Sortiert nur die Blizzard-Gruppenframes, sonst nichts.
 - Führt zu Lua-Fehlern; das ist normal und kann ignoriert werden.
 - Kann keine Abstände zwischen Frames anwenden.
]]
L["Please reload after changing these settings."] = "Bitte nach Änderung dieser Einstellungen neu laden."
L["Reload"] = "Neu laden"

-- # Ordering screen #
L["Ordering"] = "Reihenfolge"
L["Specify the ordering you wish to use when sorting by spec."] = "Lege die Reihenfolge fest, die beim Sortieren nach Spezialisierung verwendet werden soll."
L["Tanks"] = "Tanks"
L["Healers"] = "Heiler"
L["Casters"] = "Zauberwirker"
L["Hunters"] = "Jäger"
L["Melee"] = "Nahkämpfer"

-- # Spec Priority screen # --
L["Spec Priority"] = "Spezialisierungspriorität"
L["Spec Type"] = "Spezialisierungstyp"
L["Choose a spec type, then drag and drop to control priority."] = "Wähle einen Spezialisierungstyp und passe die Priorität per Drag & Drop an."
L["Tank"] = "Tank"
L["Healer"] = "Heiler"
L["Caster"] = "Zauberwirker"
L["Hunter"] = "Jäger"
L["Melee"] = "Nahkämpfer"
L["Reset this type"] = "Diesen Typ zurücksetzen"
L["Spec query note"] = [[
Bitte beachte, dass die Spezialisierungsinformationen vom Server abgefragt werden, was pro Spieler 1–2 Sekunden dauert.
\n
Das bedeutet, dass es einen kurzen Moment dauern kann, bis wir korrekt sortieren können.
]]

-- # Auto Leader screen #
L["Auto Leader"] = "Automatischer Anführer"
L["Auto promote healers to leader in solo shuffle."] = "Heiler im Solo Shuffle automatisch zum Anführer befördern."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] =
    "Warum? Damit Heiler Zielmarkierungen konfigurieren und party1/2 nach ihren Vorlieben umsortieren können."
L["Enabled"] = "Aktiviert"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "Anvisieren"
L["Target frame 1 (top frame)"] = "Ziel Frame 1 (oberstes Frame)"
L["Target frame 2"] = "Ziel Frame 2"
L["Target frame 3"] = "Ziel Frame 3"
L["Target frame 4"] = "Ziel Frame 4"
L["Target frame 5"] = "Ziel Frame 5"
L["Target bottom frame"] = "Ziel unterstes Frame"
L["Target 1 frame above bottom"] = "Ziel 1 Frame über dem untersten"
L["Target 2 frames above bottom"] = "Ziel 2 Frames über dem untersten"
L["Target 3 frames above bottom"] = "Ziel 3 Frames über dem untersten"
L["Target 4 frames above bottom"] = "Ziel 4 Frames über dem untersten"
L["Target frame 1's pet"] = "Ziel Haustier von Frame 1"
L["Target frame 2's pet"] = "Ziel Haustier von Frame 2"
L["Target frame 3's pet"] = "Ziel Haustier von Frame 3"
L["Target frame 4's pet"] = "Ziel Haustier von Frame 4"
L["Target frame 5's pet"] = "Ziel Haustier von Frame 5"
L["Target enemy frame 1"] = "Ziel Feind-Frame 1"
L["Target enemy frame 2"] = "Ziel Feind-Frame 2"
L["Target enemy frame 3"] = "Ziel Feind-Frame 3"
L["Target enemy frame 1's pet"] = "Ziel Haustier von Feind-Frame 1"
L["Target enemy frame 2's pet"] = "Ziel Haustier von Feind-Frame 2"
L["Target enemy frame 3's pet"] = "Ziel Haustier von Feind-Frame 3"
L["Focus enemy frame 1"] = "Fokus auf Feind-Frame 1"
L["Focus enemy frame 2"] = "Fokus auf Feind-Frame 2"
L["Focus enemy frame 3"] = "Fokus auf Feind-Frame 3"
L["Target the next frame"] = "Nächstes Frame anvisieren"
L["Target the previous frame"] = "Vorheriges Frame anvisieren"
L["Cycle to the next frame"] = "Zum nächsten Frame wechseln"
L["Cycle to the previous frame"] = "Zum vorherigen Frame wechseln"
L["Cycle to the next dps"] = "Zum nächsten DPS wechseln"
L["Cycle to the previous dps"] = "Zum vorherigen DPS wechseln"

-- # Keybindings screen #
L["Keybindings"] = "Tastenbelegungen"
L["Keybindings_Description"] = [[
Du findest die FrameSort-Tastenbelegungen im normalen WoW-Bereich für Tastenbelegungen.
\n
Wofür sind die Tastenbelegungen nützlich?
Damit kannst du Spieler anhand ihrer visuellen Reihenfolge anvisieren statt nach ihrer
Gruppenposition (party1/2/3/etc.)
\n
Beispiel: Eine 5er-Dungeon-Gruppe nach Rolle sortiert könnte so aussehen:
  - Tank, party3
  - Heiler, player
  - DPS, party1
  - DPS, party4
  - DPS, party2
\n
Wie du siehst, unterscheidet sich die visuelle Darstellung von der tatsächlichen Gruppenposition, was
das Anvisieren verwirrend macht.
Wenn du /target party1 verwendest, wird der DPS-Spieler an Position 3 anvisiert statt der Tank.
\n
FrameSort-Tastenbelegungen zielen anhand der visuellen Frame-Position statt der Gruppennummer.
'Frame 1' wählt also den Tank, 'Frame 2' den Heiler, 'Frame 3' den DPS an Position 3 usw.
]]

-- # Macros screen # --
L["Macros"] = "Makros"
-- "|4macro:macros;" is a special command to pluralise the word "macro" to "macros" when %d is greater than 1
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort hat %d |4Makro:Makros; zum Verwalten gefunden."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] = 'FrameSort aktualisiert dynamisch Variablen in Makros, die die Kopfzeile "#FrameSort" enthalten.'
L["Below are some examples on how to use this."] = "Unten findest du einige Beispiele zur Verwendung."

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
L["Example %d"] = "Beispiel %d"
L["Discord Bot Blurb"] = [[
Brauchst du Hilfe beim Erstellen eines Makros?
\n
Schau auf dem FrameSort-Discord vorbei und nutze unseren KI-gestützten Macro-Bot!
\n
Schreibe einfach '@Macro Bot' mit deiner Frage im Kanal #macro-bot-channel.
]]

-- # Macro Variables screen # --
L["Macro Variables"] = "Makrovariablen"
L["The first DPS that's not you."] = "Der erste DPS, der nicht du selbst bist."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "Füge eine Zahl hinzu, um das n-te Ziel zu wählen, z. B. wählt DPS2 den 2. DPS."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] =
    "Variablen sind nicht groß-/kleinschreibungssensitiv, daher funktionieren 'fRaMe1', 'Dps', 'enemyhealer' usw."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "Du willst Zeichen im Makro sparen? Verwende Abkürzungen, um sie zu verkürzen:"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = 'Verwende "X", damit FrameSort einen @unit-Selektor ignoriert:'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Spell;]]

-- # Spacing screen #
L["Spacing"] = "Abstand"
L["Add some spacing between party, raid, and arena frames."] = "Fügt Abstände zwischen Gruppen-, Schlachtzugs- und Arena-Frames hinzu."
L["This only applies to Blizzard frames."] = "Gilt nur für Blizzard-Frames."
L["Party"] = "Gruppe"
L["Raid"] = "Schlachtzug"
L["Group"] = "Gruppe"
L["Horizontal"] = "Horizontal"
L["Vertical"] = "Vertikal"

-- # Addons screen #
L["Addons"] = "Addons"
L["Addons_Supported_Description"] = [[
FrameSort unterstützt Folgendes:
\n
  - Blizzard: Gruppe, Schlachtzug, Arena.
\n
  - ElvUI: Gruppe.
\n
  - sArena: Arena.
\n
  - Gladius: Arena.
\n
  - GladiusEx: Gruppe, Arena.
\n
  - Cell: Gruppe, Schlachtzug (nur bei kombinierten Gruppen).
\n
  - Shadowed Unit Frames: Gruppe, Arena.
\n
  - Grid2: Gruppe, Schlachtzug.
\n
  - BattleGroundEnemies: Gruppe, Arena.
\n
  - Gladdy: Arena.
\n
  - Arena Core: 0.9.1.7+.
\n
]]

-- # Api screen #
L["Api"] = "API"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "Möchtest du FrameSort in deine Addons, Skripte und WeakAuras integrieren?"
L["Here are some examples."] = "Hier sind einige Beispiele."
L["Retrieved an ordered array of party/raid unit tokens."] = "Rufe ein geordnetes Array von Gruppen-/Schlachtzug-Unit-Tokens ab."
L["Retrieved an ordered array of arena unit tokens."] = "Rufe ein geordnetes Array von Arena-Unit-Tokens ab."
L["Register a callback function to run after FrameSort sorts frames."] = "Registriere eine Callback-Funktion, die nach dem Sortieren der Frames durch FrameSort ausgeführt wird."
L["Retrieve an ordered array of party frames."] = "Rufe ein geordnetes Array von Gruppen-Frames ab."
L["Change a FrameSort setting."] = "Ändere eine FrameSort-Einstellung."
L["Get the frame number of a unit."] = "Ruft die Rahmennummer einer Einheit ab."
L["View a full listing of all API methods on GitHub."] = "Eine vollständige Auflistung aller API-Methoden findest du auf GitHub."

-- # Discord screen #
L["Discord"] = "Discord"
L["Need help with something?"] = "Brauchst du Hilfe?"
L["Talk directly with the developer on Discord."] = "Sprich direkt mit dem Entwickler auf Discord."

-- # Health Check screen -- #
L["Health Check"] = "Statusprüfung"
L["Try this"] = "Versuche dies"
L["Any known issues with configuration or conflicting addons will be shown below."] = "Alle bekannten Probleme mit der Konfiguration oder Konflikte mit Addons werden unten angezeigt."
L["N/A"] = "k. A."
L["Passed!"] = "Bestanden!"
L["Failed"] = "Fehlgeschlagen"
L["(unknown)"] = "(unbekannt)"
L["(user macro)"] = "(Benutzer-Makro)"
L["Using grouped layout for Cell raid frames"] = "Gruppiertes Layout für Cell-Schlachtzugsframes verwendet"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Bitte aktiviere die Option 'Combined Groups (Raid)' in Cell -> Layouts"
L["Can detect frames"] = "Kann Frames erkennen"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort unterstützt derzeit Frames folgender Addons: %s"
L["Using Raid-Style Party Frames"] = "Gruppen-Frames im Schlachtzugsstil werden verwendet"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "Bitte aktiviere 'Use Raid-Style Party Frames' in den Blizzard-Einstellungen"
L["Keep Groups Together setting disabled"] = "Einstellung 'Gruppen zusammenhalten' deaktiviert"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "Ändere den Schlachtzugs-Anzeigemodus im Bearbeitungsmodus auf eine der Optionen 'Combined Groups'"
L["Disable the 'Keep Groups Together' raid profile setting."] = "Deaktiviere die Schlachtzugsprofil-Einstellung 'Keep Groups Together'."
L["Only using Blizzard frames with Traditional mode"] = "Es werden nur Blizzard-Frames im traditionellen Modus verwendet"
L["Traditional mode can't sort your other frame addons: '%s'"] = "Der traditionelle Modus kann deine anderen Frame-Addons nicht sortieren: '%s'"
L["Using Secure sorting mode when spacing is being used"] = "Sicherer Sortiermodus bei Verwendung von Abständen"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] =
    "Der traditionelle Modus kann keine Abstände anwenden; entferne die Abstände oder verwende die sichere Sortiermethode"
L["Blizzard sorting functions not tampered with"] = "Blizzard-Sortierfunktionen wurden nicht verändert"
L['"%s" may cause conflicts, consider disabling it'] = '"%s" kann Konflikte verursachen; deaktiviere es ggf.'
L["No conflicting addons"] = "Keine in Konflikt stehenden Addons"

-- # Log Screen -- #
L["Log"] = "Protokoll"
L["FrameSort log to help with diagnosing issues."] = "FrameSort-Protokoll zur Unterstützung bei der Fehlerdiagnose."
L["Copy Log"] = "Protokoll kopieren"

-- # Notifications -- #
L["Can't do that during combat."] = "Das ist im Kampf nicht möglich."

-- # Nameplates screen #
L["Nameplates"] = "Namensplaketten"
L["Friendly Nameplates"] = "Freundliche Namensplaketten"
L["Enemy Nameplates"] = "Feindliche Namensplaketten"
L["NameplatesBlurb"] = [[
Ersetzt den Nameplate-Text von Blizzard und Platynator durch FrameSort-Variablen.
\n
Unterstützte Variablen:
  - $framenumber
  - $name
  - $unit
  - $spec
\n
Beispiele:
  - Frame - $framenumber
  - $framenumber - $spec
  - $name - $spec
]]

-- # Miscellaneous screen #
L["Miscellaneous"] = "Verschiedenes"
L["Various tweaks you can apply."] = "Verschiedene Anpassungen, die du vornehmen kannst."
L["Player top of role"] = "Spieler an oberster Position der Rolle"
L["Places you at the top of your corresponding role (healer/tank/dps)."] = "Platziert dich an die oberste Position deiner entsprechenden Rolle (Heiler/Tank/DPS)."

-- # Language screen #
L["Language"] = "Sprache"
L["Specify the language we use."] = "Lege die verwendete Sprache fest."
