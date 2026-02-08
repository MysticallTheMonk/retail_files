local _, ADDON = ...

local locale = GetLocale()

ADDON.isMetric = (locale ~= "enUS") -- is the metric or imperial unit system used?
ADDON.L = {}
local L = ADDON.L

L["AUTO_ROTATE"] = "Rotate automatically"
L["Black Market"] = "Black Market"
L["COMPARTMENT_TOOLTIP"] = "|cffeda55fLeft-Click|r to toggle showing the mount collection.\n|cffeda55fRight-Click|r to open addon options."
L["DRESSUP_LABEL"] = "Journal"
L["FAVOR_DISPLAYED"] = "All Displayed"
L["FILTER_ONLY_LATEST"] = "Only latest additions"
L["FILTER_PROFILE"] = "Profile"
L["FILTER_PROFILE_TOOLTIP_TITLE"] = "Filter Profiles"
L["FILTER_PROFILE_TOOLTIP_TEXT"] = "Quickly load your predefined filter and search settings.|n|cffeda55fLeft-Click|r to load filter profile.|n|cffeda55fRight-Click|r to save filter profile."
L["FILTER_SECRET"] = "Hidden by the game"
L["FILTER_RETIRED"] = "No longer available"
L["Family"] = "Family"
L["Hidden"] = "Hidden"
L["Only tradable"] = "Only tradable"
L["Only usable"] = "Only usable"
L["Passenger"] = "Passenger"
L["PET_ASSIGNMENT_TITLE"] = "Assign Pet to Mount"
L["PET_ASSIGNMENT_NONE"] = "No Pet"
L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "Current assigned Pet:"
L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55fLeft click|r to open pet assignment."
L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55fRight click|r to assign active pet to mount."
L["PET_ASSIGNMENT_INFO"] = "You can assign a pet to this mount. It's going to be summoned as well, when you mount up.|n|n"
        .. "All assignments are shared with all your characters.|n|n"
        .. "You can use right-click on a pet entry to summon it manually.|n|n"
        .. "Please be aware that most ground pets won't fly with you and just disappear when you take off. Also, flying pets are usually slower than you. So they might need some time to catch up to you.|n|n"
        .. "Auto summoning pets is only active in world content."
L["ROTATE_DOWN"] = "Rotate Down"
L["ROTATE_UP"] = "Rotate Up"
L["Reset filters"] = "Reset filters"
L["SORT_BY_FAMILY"] = STABLE_SORT_TYPE_LABEL or "Family"
L["SORT_BY_LAST_USAGE"] = "Last usage"
L["SORT_BY_LEARNED_DATE"] = "Date of receipt"
L["SORT_BY_TRAVEL_DISTANCE"] = "Travelled distance"
L["SORT_BY_TRAVEL_DURATION"] = "Travelled duration"
L["SORT_BY_USAGE_COUNT"] = "Count of usage"
L["SORT_FAVORITES_FIRST"] = "Favorites First"
L["SORT_REVERSE"] = "Reverse Sort"
L["SORT_UNOWNED_BOTTOM"] = "Unowned at Bottom"
L["SORT_UNUSABLE_BOTTOM"] = "Unusable after Usable"
L["SPECIAL_TIP"] = "Starts the special animation of your mount in game."
L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "Count of collected customization options"
L["STATS_TIP_LEARNED_DATE_HEAD"] = "Possession date"
L["STATS_TIP_RARITY_HEAD"] = RARITY
L["STATS_TIP_RARITY_DESCRIPTION"] = "% of characters who own this mount"
L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "Travel distance"
L["STATS_TIP_TRAVEL_TIME_HEAD"] = "Travel time"
L["STATS_TIP_TRAVEL_TIME_TEXT"] = "in hours:minutes:seconds"
L["STATS_TIP_TRAVEL_TIME_DAYS"] = "in days"
L["STATS_TIP_USAGE_COUNT_HEAD"] = "Usage count"
L["TOGGLE_COLOR"] = "Show next color variation"
L["Transform"] = "Transform"
L["ANIMATION_STAND"] = "Stand"
L["ANIMATION_WALK"] = "Walk"
L["ANIMATION_WALK_BACK"] = "Walk Backwards"
L["ANIMATION_RUN"] = "Run"
L["ANIMATION_FLY"] = "Fly"
L["ANIMATION_FLY_IDLE"] = "Fly Idle"
L["FILTER_ONLY"] = "only"
L["LINK_WOWHEAD"] = "Link to Wowhead"
L["CLICK_TO_SHOW_LINK"] = "Click to Show Link"
L["SYNC_TARGET_TIP_TITLE"] = "Sync Journal with Target"
L["SYNC_TARGET_TIP_TEXT"] = "Automatically select the mount of your current target."
L["SYNC_TARGET_TIP_FLAVOR"] = "Get ready for a mount off!"
L["FAVORITE_PROFILE"] = "Profile"
L["FAVORITE_ACCOUNT_PROFILE"] = "Account"
L["ASK_FAVORITE_PROFILE_NAME"] = "Enter Profile Name:"
L["CONFIRM_FAVORITE_PROFILE_DELETION"] = "Are you sure you want to delete the profile \"%s\"?\nAll current character assignments will be reset to the default profile \"%s\"."
L["FAVOR_AUTO"] = "Add new mounts automatically"
L["LDB_TIP_NO_FAVORITES_TITLE"] = "You have not selected any mount as favorite yet."
L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "|cffeda55fLeft click|r to open Mount Collection."
L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "|cffeda55fRight click|r to select different Favorite Profile."
L["EVENT_PLUNDERSTORM"] = "Plunderstorm"
L["EVENT_SCARAB"] = "Call of the Scarab"
L["EVENT_SECRETS"] = "Secrets of Azeroth"

-- Settings
L["DISPLAY_ALL_SETTINGS"] = "Display all settings"
L["RESET_WINDOW_SIZE"] = "Reset journal size"
L["SETTING_ABOUT_AUTHOR"] = "Author"
L["SETTING_ACHIEVEMENT_POINTS"] = "Show achievement points"
L["SETTING_COLOR_NAMES"] = "Colorize names in list based on rarity"
L["SETTING_COMPACT_LIST"] = "Compact mount list"
L["SETTING_CURSOR_KEYS"] = "Enable Up&Down keys to browse mounts"
L["SETTING_DISPLAY_BACKGROUND"] = "Change background color in display"
L["SETTING_HEAD_ABOUT"] = "About"
L["SETTING_HEAD_BEHAVIOUR"] = "Behavior"
L["SETTING_MOUNT_COUNT"] = "Show personal mount count"
L["SETTING_MOUNTSPECIAL_BUTTON"] = "Show /mountspecial button"
L["SETTING_PERSONAL_FILTER"] = "Apply filters only to this character"
L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "Apply hidden mounts only to this character"
L["SETTING_PERSONAL_UI"] = "Apply Interface settings only to this character"
L["SETTING_PREVIEW_LINK"] = "Show Collection button in mount preview"
L["SETTING_SEARCH_MORE"] = "Search also in description text"
L["SETTING_SEARCH_FAMILY_NAME"] = "Search also by family name"
L["SETTING_SEARCH_NOTES"] = "Search also in own notes"
L["SETTING_SHOW_RESIZE_EDGE"] = "Activate edge in bottom corner to resize window"
L["SETTING_SHOW_DATA"] = "Show mount data in display"
L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "Show toolbar buttons"
L["SETTING_SUMMONPREVIOUSPET"] = "Summon previous active pet again when dismounting."
L["SETTING_TRACK_USAGE"] = "Track mount usage behavior on all characters"
L["SETTING_YCAMERA"] = "Unlock Y rotation with mouse in display"
L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "Show filter profiles in filter menu."

-- Families
-- Families
L["Airplanes"] = "Airplanes"
L["Airships"] = "Airships"
L["Albatross"] = "Albatross"
L["Alpacas"] = "Alpacas"
L["Amphibian"] = "Amphibian"
L["Animite"] = "Animite"
L["Aqir Flyers"] = "Aqir Flyers"
L["Arachnids"] = "Arachnids"
L["Armoredon"] = "Armoredon"
L["Basilisks"] = "Basilisks"
L["Bats"] = "Bats"
L["Bears"] = "Bears"
L["Beetle"] = "Beetle"
L["Bipedal Cat"] = "Bipedal Cat"
L["Birds"] = "Birds"
L["Boars"] = "Boars"
L["Bovids"] = "Bovids"
L["Broom"] = "Broom"
L["Brutosaurs"] = "Brutosaurs"
L["Camels"] = "Camels"
L["Carnivorans"] = "Carnivorans"
L["Carpets"] = "Carpets"
L["Carrion"] = "Carrion"
L["Cats"] = "Cats"
L["Cervid"] = "Cervid"
L["Chargers"] = "Chargers"
L["Chickens"] = "Chickens"
L["Clefthooves"] = "Clefthooves"
L["Cloud Serpents"] = "Cloud Serpents"
L["Core Hounds"] = "Core Hounds"
L["Crabs"] = "Crabs"
L["Cranes"] = "Cranes"
L["Crawgs"] = "Crawgs"
L["Crocolisks"] = "Crocolisks"
L["Crows"] = "Crows"
L["Demonic Hounds"] = "Demonic Hounds"
L["Demonic Steeds"] = "Demonic Steeds"
L["Demons"] = "Demons"
L["Devourer"] = "Devourer"
L["Dinosaurs"] = "Dinosaurs"
L["Dire Wolves"] = "Dire Wolves"
L["Direhorns"] = "Direhorns"
L["Discs"] = "Discs"
L["Dragonhawks"] = "Dragonhawks"
L["Drakes"] = "Drakes"
L["Dreamsaber"] = "Dreamsaber"
L["Eagle"] = "Eagle"
L["Elekks"] = "Elekks"
L["Elementals"] = "Elementals"
L["Falcosaurs"] = "Falcosaurs"
L["Fathom Rays"] = "Fathom Rays"
L["Feathermanes"] = "Feathermanes"
L["Felbat"] = "Felbat"
L["Felsabers"] = "Felsabers"
L["Fish"] = "Fish"
L["Flies"] = "Flies"
L["Flying Steeds"] = "Flying Steeds"
L["Foxes"] = "Foxes"
L["Gargon"] = "Gargon"
L["Gargoyle"] = "Gargoyle"
L["Goats"] = "Goats"
L["Gorger"] = "Gorger"
L["Gorm"] = "Gorm"
L["Grand Drakes"] = "Grand Drakes"
L["Gronnlings"] = "Gronnlings"
L["Gryphons"] = "Gryphons"
L["Gyrocopters"] = "Gyrocopters"
L["Hands"] = "Hands"
L["Harrower"] = "Harrower"
L["Hawkstriders"] = "Hawkstriders"
L["Hedgehog"] = "Hedgehog"
L["Hippogryphs"] = "Hippogryphs"
L["Horned Steeds"] = "Horned Steeds"
L["Horses"] = "Horses"
L["Hounds"] = "Hounds"
L["Hover Board"] = "Hover Board"
L["Humanoids"] = "Humanoids"
L["Hyenas"] = "Hyenas"
L["Infernals"] = "Infernals"
L["Insects"] = "Insects"
L["Jellyfish"] = "Jellyfish"
L["Jet Aerial Units"] = "Jet Aerial Units"
L["Kites"] = "Kites"
L["Kodos"] = "Kodos"
L["Krolusks"] = "Krolusks"
L["Larion"] = "Larion"
L["Lions"] = "Lions"
L["Lupine"] = "Lupine"
L["Lynx"] = "Lynx"
L["Mammoths"] = "Mammoths"
L["Mana Rays"] = "Mana Rays"
L["Mana Wyrm"] = "Mana Wyrm"
L["Manasabers"] = "Manasabers"
L["Mauler"] = "Mauler"
L["Mechanical Animals"] = "Mechanical Animals"
L["Mechanical Birds"] = "Mechanical Birds"
L["Mechanical Cats"] = "Mechanical Cats"
L["Mechanical Steeds"] = "Mechanical Steeds"
L["Mechanostriders"] = "Mechanostriders"
L["Mecha-suits"] = "Mecha-suits"
L["Meeksi"] = "Meeksi"
L["Mite"] = "Mite"
L["Mole"] = "Mole"
L["Mollusc"] = "Mollusc"
L["Moose"] = "Moose"
L["Moth"] = "Moth"
L["Motorcycles"] = "Motorcycles"
L["Mountain Horses"] = "Mountain Horses"
L["Murloc"] = "Murloc"
L["Mushan"] = "Mushan"
L["Nether Drakes"] = "Nether Drakes"
L["Nether Rays"] = "Nether Rays"
L["N'Zoth Serpents"] = "N'Zoth Serpents"
L["Others"] = "Others"
L["Ottuk"] = "Ottuk"
L["Owl"] = "Owl"
L["Owlbear"] = "Owlbear"
L["Ox"] = "Ox"
L["Pandaren Phoenixes"] = "Pandaren Phoenixes"
L["Pangolin"] = "Pangolin"
L["Parrots"] = "Parrots"
L["Peafowl"] = "Peafowl"
L["Petalwing"] = "Petalwing"
L["Phoenixes"] = "Phoenixes"
L["Plant"] = "Plant"
L["Proto-Drakes"] = "Proto-Drakes"
L["Pterrordaxes"] = "Pterrordaxes"
L["Quilen"] = "Quilen"
L["Rabbit"] = "Rabbit"
L["Rams"] = "Rams"
L["Raptora"] = "Raptora"
L["Raptors"] = "Raptors"
L["Rats"] = "Rats"
L["Raven"] = "Raven"
L["Rays"] = "Rays"
L["Razorwing"] = "Razorwing"
L["Reptiles"] = "Reptiles"
L["Rhinos"] = "Rhinos"
L["Riverbeasts"] = "Riverbeasts"
L["Roc"] = "Roc"
L["Rockets"] = "Rockets"
L["Rodent"] = "Rodent"
L["Ruinstriders"] = "Ruinstriders"
L["Rylaks"] = "Rylaks"
L["Sabers"] = "Sabers"
L["Scorpions"] = "Scorpions"
L["Sea Serpents"] = "Sea Serpents"
L["Seahorses"] = "Seahorses"
L["Shalewing"] = "Shalewing"
L["Shardhides"] = "Shardhides"
L["Silithids"] = "Silithids"
L["Skyrazor"] = "Skyrazor"
L["Slateback"] = "Slateback"
L["Slug"] = "Slug"
L["Snail"] = "Snail"
L["Snapdragons"] = "Snapdragons"
L["Spider Tanks"] = "Spider Tanks"
L["Spiders"] = "Spiders"
L["Sporebat"] = "Sporebat"
L["Stag"] = "Stag"
L["Steeds"] = "Steeds"
L["Stingrays"] = "Stingrays"
L["Stone Cats"] = "Stone Cats"
L["Stone Drakes"] = "Stone Drakes"
L["Talbuks"] = "Talbuks"
L["Tallstriders"] = "Tallstriders"
L["Talonbirds"] = "Talonbirds"
L["Tauralus"] = "Tauralus"
L["Thunder Lizard"] = "Thunder Lizard"
L["Tigers"] = "Tigers"
L["Toads"] = "Toads"
L["Turkey"] = "Turkey"
L["Turtles"] = "Turtles"
L["Undead Drakes"] = "Undead Drakes"
L["Undead Steeds"] = "Undead Steeds"
L["Undead Wolves"] = "Undead Wolves"
L["Ungulates"] = "Ungulates"
L["Ur'zul"] = "Ur'zul"
L["Vehicles"] = "Vehicles"
L["Void Creeper"] = "Void Creeper"
L["Void Flyer"] = "Void Flyer"
L["Vombata"] = "Vombata"
L["Vulpin"] = "Vulpin"
L["Vultures"] = "Vultures"
L["War Wolves"] = "War Wolves"
L["Wasp"] = "Wasp"
L["Water Striders"] = "Water Striders"
L["Wilderlings"] = "Wilderlings"
L["Wind Drakes"] = "Wind Drakes"
L["Wolfhawks"] = "Wolfhawks"
L["Wolves"] = "Wolves"
L["Worm"] = "Worm"
L["Wyverns"] = "Wyverns"
L["Yaks"] = "Yaks"
L["Yetis"] = "Yetis"


if locale == "deDE" then
    L["ANIMATION_FLY"] = "Flug"
L["ANIMATION_FLY_IDLE"] = "Standflug"
L["ANIMATION_RUN"] = "Rennen"
L["ANIMATION_STAND"] = "Stehen"
L["ANIMATION_WALK"] = "Gehen"
L["ANIMATION_WALK_BACK"] = "Rückwärts Gehen"
L["ASK_FAVORITE_PROFILE_NAME"] = "Name des Profiles eingeben:"
L["AUTO_ROTATE"] = "Automatisch rotieren"
L["Black Market"] = "Schwarzmarkt"
L["CLICK_TO_SHOW_LINK"] = "Klicken um Link zu Zeigen"
L["COMPARTMENT_TOOLTIP"] = [=[cffeda55fLinksklick|r um Reittiersammlung anzuzeigen.
|cffeda55fRechtsklick|r um Addon-Optionen zu öffnen.]=]
L["CONFIRM_FAVORITE_PROFILE_DELETION"] = [=[Möchtest du wirklich das Profil "%s" entfernen?
Alle bisherigen zugewiesenen Charaktere werden auf das Standardprofil "%s" zurückgesetzt.]=]
L["DRESSUP_LABEL"] = "Sammlung"
L["EVENT_PLUNDERSTORM"] = "Plunderstorm"
L["EVENT_SCARAB"] = "Ruf des Skarabäus"
L["EVENT_SECRETS"] = "Geheimnisse von Azeroth"
L["Family"] = "Familie"
L["FAVOR_AUTO"] = "Neue Reittiere automatisch hinzufügen"
L["FAVOR_DISPLAYED"] = "Alle Angezeigten Wählen"
L["FAVORITE_ACCOUNT_PROFILE"] = "Account"
L["FAVORITE_PROFILE"] = "Profil"
L["FILTER_ONLY"] = "nur"
L["FILTER_ONLY_LATEST"] = "Nur Neuzugänge"
L["FILTER_PROFILE"] = "Profil"
L["FILTER_PROFILE_TOOLTIP_TEXT"] = "Lade deine eigenen vordefinierten Filter- und Sucheinstellungen aus einem Profil.|n|cffeda55fLinksklick|r um Profil zu laden.|n|cffeda55fRechtsklick|r um Profil zu speichern."
L["FILTER_PROFILE_TOOLTIP_TITLE"] = "Filterprofile"
L["FILTER_RETIRED"] = "nicht mehr erhältlich"
L["FILTER_SECRET"] = "vom Spiel versteckt"
L["Hidden"] = "Ausgeblendete"
L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "|cffeda55fLinksklick|r um Reittiersammlung zu öffnen."
L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "|cffeda55fRechtsklick|r um Profil zu wechseln."
L["LDB_TIP_NO_FAVORITES_TITLE"] = "Du hast noch keine Favoriten ausgewählt."
L["LINK_WOWHEAD"] = "Link zu Wowhead"
L["Mite"] = "Milbe"
L["Only tradable"] = "Nur handelbare"
L["Passenger"] = "Passagier"
L["PET_ASSIGNMENT_INFO"] = "Hiermit kannst du ein Haustier diesem Reittier zuweisen. Dieses wird beim Aufsitzen ebenfalls beschworen.|n|nAlle Zuweisungen zählen übergreifend für all deine Charaktere.|n|nDu kannst mittels Rechtsklick auf einen Eintrag das Haustier direkt beschwören.|n|nBitte bedenke, dass viele Haustiere am Boden bleiben und nicht mit dir mitfliegen. Außerdem sind fliegende Haustiere auch langsamer als du. Sie brauchen dann nur ein wenig um dich einzuholen.|n|nDie automatische Haustierbeschwörung ist nur in der offenen Welt aktiv."
L["PET_ASSIGNMENT_NONE"] = "Kein Haustier"
L["PET_ASSIGNMENT_TITLE"] = "Haus- zu Reittier zuweisen"
L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "Zugewiesenes Haustier:"
L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55fLinksklick|r um Haustierauswahl zu öffnen."
L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55fRechtsklick|r um aktives Haustier mit Reittier zu verknüpfen."
L["Reset filters"] = "Filter zurücksetzen"
L["ROTATE_DOWN"] = "Abwärtsdrehung"
L["ROTATE_UP"] = "Aufwärtsdrehung"
L["SORT_BY_FAMILY"] = "Familie"
L["SORT_BY_LAST_USAGE"] = "Letzter Benutzung"
L["SORT_BY_LEARNED_DATE"] = "Datum des Erhalts"
L["SORT_BY_TRAVEL_DISTANCE"] = "Gereiste Entfernung"
L["SORT_BY_TRAVEL_DURATION"] = "Reisedauer"
L["SORT_BY_USAGE_COUNT"] = "Nutzungshäufigkeit"
L["SORT_FAVORITES_FIRST"] = "Favoriten zuerst"
L["SORT_REVERSE"] = "Sortierung umkehren"
L["SORT_UNOWNED_BOTTOM"] = "Nicht gesammelt nach unten"
L["SORT_UNUSABLE_BOTTOM"] = "Nicht nutzbare nach nutzbaren"
L["SPECIAL_TIP"] = "Startet die Spezialanimation deines Reittieres im Spiel."
L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "Anzahl gesammelter Anpassungsoptionen"
L["STATS_TIP_LEARNED_DATE_HEAD"] = "Besitzdatum"
L["STATS_TIP_RARITY_DESCRIPTION"] = "% an Charakteren die dieses Reittier besitzen."
L["STATS_TIP_RARITY_HEAD"] = "Seltenheit"
L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "Reisedistanz"
L["STATS_TIP_TRAVEL_TIME_DAYS"] = "in Tagen"
L["STATS_TIP_TRAVEL_TIME_HEAD"] = "Reisedauer"
L["STATS_TIP_TRAVEL_TIME_TEXT"] = "als Stunden:Minuten:Sekunden"
L["STATS_TIP_USAGE_COUNT_HEAD"] = "Anzahl der Einsätze"
L["SYNC_TARGET_TIP_FLAVOR"] = "Sei bereit zum Mount Off!"
L["SYNC_TARGET_TIP_TEXT"] = "Zeige automatisch das Reittier deines aktuellen Ziels."
L["SYNC_TARGET_TIP_TITLE"] = "Verknüpfe Journal mit Ziel"
L["TOGGLE_COLOR"] = "Zeige nächste Farbvariante"
L["Transform"] = "Verwandlung"

    -- Settings
L["DISPLAY_ALL_SETTINGS"] = "Zeige alle Einstellungen"
L[ [=[RESET_WINDOW_SIZE
]=] ] = "Journalgröße zurücksetzen"
L["SETTING_ABOUT_AUTHOR"] = "Autor"
L["SETTING_ACHIEVEMENT_POINTS"] = "Zeige Erfolgspunkte"
L["SETTING_COLOR_NAMES"] = "Namen in der Liste nach Seltenheit einfärben"
L["SETTING_COMPACT_LIST"] = "Kompakte Mount-Liste"
L["SETTING_CURSOR_KEYS"] = "Aktiviere Aufwärts- und Abwärtspfeiltaste zum Durchblättern"
L["SETTING_DISPLAY_BACKGROUND"] = "Wechsle Anzeigehintergrund"
L["SETTING_HEAD_ABOUT"] = "Über"
L["SETTING_HEAD_BEHAVIOUR"] = "Verhalten"
L["SETTING_MOUNT_COUNT"] = "Zeige Reittieranzahl diesen Charakters"
L["SETTING_MOUNTSPECIAL_BUTTON"] = "Zeige Knopf für /mountspecial"
L["SETTING_PERSONAL_FILTER"] = "Wende Filter-Einstellungen nur bei diesem Charakter an"
L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "Benutze versteckte Reittiere nur bei diesem Charakter"
L["SETTING_PERSONAL_UI"] = "Benutze Interface-Einstellungen nur bei diesem Charakter"
L["SETTING_PREVIEW_LINK"] = "Zeige Knopf zur Sammlung in Anprobe"
L["SETTING_SEARCH_FAMILY_NAME"] = "Suche auch anhand des Familiennamen"
L["SETTING_SEARCH_MORE"] = "Suche auch im Beschreibungstext"
L["SETTING_SEARCH_NOTES"] = "Suche auch in eigenen Notizen"
L["SETTING_SHOW_DATA"] = "Zeige Informationen in Modellanzeige"
L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "Zeige Filterprofile im Menü."
L["SETTING_SHOW_RESIZE_EDGE"] = "Zeige untere Ecke um die Fenstergröße zu ändern"
L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "Zeige Schalter in Symbolleiste"
L["SETTING_SUMMONPREVIOUSPET"] = "Zuvor aktives Haustier wird beim Absteigen wieder ausgepackt."
L["SETTING_TRACK_USAGE"] = "Verfolge Reittier Nutzungsverhalten bei allen Charakteren"
L["SETTING_YCAMERA"] = "Aktiviere Y-Rotation via Maus in Modellanzeige"

    -- Families
L["Airplanes"] = "Flugzeuge"
L["Airships"] = "Luftschiffe"
L["Albatross"] = "Albatros"
L["Alpacas"] = "Alpakas"
L["Amphibian"] = "Amphibien"
L["Animite"] = "Animilbe"
L["Aqir Flyers"] = "Aqir-Flieger"
L["Arachnids"] = "Spinnentiere"
L["Armoredon"] = "Panzerdon"
L["Basilisks"] = "Basilisken"
L["Bats"] = "Fledermäuse"
L["Bears"] = "Bären"
L["Beetle"] = "Käfer"
L["Bipedal Cat"] = "Zweibeinige Katze"
L["Birds"] = "Vögel"
L["Boars"] = "Eber"
L["Bovids"] = "Hornträger"
L["Broom"] = "Besen"
L["Brutosaurs"] = "Brutosaurier"
L["Camels"] = "Kamele"
L["Carnivorans"] = "Raubtiere"
L["Carpets"] = "Teppiche"
L["Carrion"] = "Aasvogel"
L["Cats"] = "Katzen"
L["Cervid"] = "Cervid"
L["Chargers"] = "Streitrosse"
L["Chickens"] = "Hühner"
L["Clefthooves"] = "Spalthufe"
L["Cloud Serpents"] = "Wolkenschlangen"
L["Core Hounds"] = "Kernhunde"
L["Crabs"] = "Krabben"
L["Cranes"] = "Kraniche"
L["Crawgs"] = "Kroggs"
L["Crocolisks"] = "Krokilisk"
L["Crows"] = "Krähen"
L["Demonic Hounds"] = "Dämonische Hunde"
L["Demonic Steeds"] = "Dämonische Pferde"
L["Demons"] = "Dämonen"
L["Devourer"] = "Verschlinger"
L["Dinosaurs"] = "Dinosaurier"
L["Dire Wolves"] = "Terrorwölfe"
L["Direhorns"] = "Terrorhörner"
L["Discs"] = "Flugscheiben"
L["Dragonhawks"] = "Drachenfalken"
L["Drakes"] = "Drachen"
L["Dreamsaber"] = "Traumsäbler"
L["Eagle"] = "Adler"
L["Elekks"] = "Elekks"
L["Elementals"] = "Elementare"
L["Falcosaurs"] = "Falkosaurier"
L["Fathom Rays"] = "Tiefenrochen"
L["Feathermanes"] = "Federmähnen"
L["Felbat"] = "Teufelsfledermaus"
L["Felsabers"] = "Teufelssäbler"
L["Fish"] = "Fische"
L["Flies"] = "Fliegen"
L["Flying Steeds"] = "Fliegende Pferde"
L["Foxes"] = "Füchse"
L["Gargon"] = "Gargon"
L["Gargoyle"] = "Gargoyle"
L["Goats"] = "Ziegen"
L["Gorger"] = "Verschlinger"
L["Gorm"] = "Gorm"
L["Grand Drakes"] = "Großdrachen"
L["Gronnlings"] = "Gronnlinge"
L["Gryphons"] = "Greifen"
L["Gyrocopters"] = "Gyrokopter"
L["Hands"] = "Hände"
L["Harrower"] = "Plager"
L["Hawkstriders"] = "Falkenschreiter"
L["Hedgehog"] = "Igel"
L["Hippogryphs"] = "Hippogryphen"
L["Horned Steeds"] = "Behornte Pferde"
L["Horses"] = "Pferde"
L["Hounds"] = "Hunde"
L["Hover Board"] = "Ho­ver­board"
L["Humanoids"] = "Humanoide"
L["Hyenas"] = "Hyänen"
L["Infernals"] = "Höllenbestien"
L["Insects"] = "Insekten"
L["Jellyfish"] = "Quallen"
L["Jet Aerial Units"] = "Lufteinheiten"
L["Kites"] = "Flugdrachen"
L["Kodos"] = "Kodos"
L["Krolusks"] = "Krolusk"
L["Larion"] = "Larion"
L["Lions"] = "Löwen"
L["Lupine"] = "Lupin"
L["Lynx"] = "Luchs"
L["Mammoths"] = "Mammuts"
L["Mana Rays"] = "Manarochen"
L["Mana Wyrm"] = "Manawyrm"
L["Manasabers"] = "Manasäbler"
L["Mauler"] = "Zerfleischer"
L["Mechanical Animals"] = "Mechanische Tiere"
L["Mechanical Birds"] = "Mechanische Vögel"
L["Mechanical Cats"] = "Mechanische Katzen"
L["Mechanical Steeds"] = "Mechanische Pferde"
L["Mechanostriders"] = "Roboschreiter"
L["Mecha-suits"] = "Mecha"
L["Meeksi"] = "Meeksi"
L["Mite"] = "Milbe"
L["Mole"] = "Maulwurf"
L["Mollusc"] = "Weichtiere"
L["Moose"] = "Elche"
L["Moth"] = "Motte"
L["Motorcycles"] = "Motorräder"
L["Mountain Horses"] = "Bergpferde"
L["Murloc"] = "Murloc"
L["Mushan"] = "Mushans"
L["Nether Drakes"] = "Netherdrachen"
L["Nether Rays"] = "Netherrochen"
L["N'Zoth Serpents"] = "N'Zoth-Schlangen"
L["Others"] = "Andere"
L["Ottuk"] = "Ottuk"
L["Owl"] = "Eule"
L["Owlbear"] = "Eulenbär"
L["Ox"] = "Ochse"
L["Pandaren Phoenixes"] = "Pandarenphönixe"
L["Pangolin"] = "Schuppentier"
L["Parrots"] = "Papageien"
L["Peafowl"] = "Pfau"
--[[Translation missing --]]
--[[ L["Petalwing"] = "Petalwing"--]] 
L["Phoenixes"] = "Phönixe"
L["Plant"] = "Pflanze"
L["Proto-Drakes"] = "Protodrachen"
L["Pterrordaxes"] = "Pterrordaxe"
L["Quilen"] = "Qilen"
L["Rabbit"] = "Hase"
L["Rams"] = "Widder"
L["Raptora"] = "Raptora"
L["Raptors"] = "Raptoren"
L["Rats"] = "Ratten"
L["Raven"] = "Rabe"
L["Rays"] = "Rochen"
L["Razorwing"] = "Klingenschwinge"
L["Reptiles"] = "Reptilien"
L["Rhinos"] = "Rhinozerosse"
L["Riverbeasts"] = "Flussbestien"
L["Roc"] = "Roc"
L["Rockets"] = "Raketen"
L["Rodent"] = "Nagetier"
L["Ruinstriders"] = "Ruinprescher"
L["Rylaks"] = "Rylaks"
L["Sabers"] = "Säbler"
L["Scorpions"] = "Skorpione"
L["Sea Serpents"] = "Seeschlangen"
L["Seahorses"] = "Seepferde"
L["Shalewing"] = "Schieferschwinge"
L["Shardhides"] = "Splitterfell"
L["Silithids"] = "Qirajipanzerdrohnen"
L["Skyrazor"] = "Himmelsreißer"
L["Slateback"] = "Schieferrücken"
L["Slug"] = "Nacktschnecke"
L["Snail"] = "Schnecke"
L["Snapdragons"] = "Schnappdrachen"
L["Spider Tanks"] = "Mechaspinnen"
L["Spiders"] = "Spinnen"
L["Sporebat"] = "Sporensegler"
L["Stag"] = "Hirsch"
L["Steeds"] = "Pferde"
L["Stingrays"] = "Stachelrochen"
L["Stone Cats"] = "Steinkatzen"
L["Stone Drakes"] = "Steindrachen"
L["Talbuks"] = "Talbuks"
L["Tallstriders"] = "Schreiter"
L["Talonbirds"] = "Raben"
L["Tauralus"] = "Tauralus"
L["Thunder Lizard"] = "Donnerechse"
L["Tigers"] = "Tiger"
L["Toads"] = "Kröten"
L["Turkey"] = "Truthahn"
L["Turtles"] = "Schildkröten"
L["Undead Drakes"] = "Untote Drachen"
L["Undead Steeds"] = "Untote Pferde"
L["Undead Wolves"] = "Untote Wölfe"
L["Ungulates"] = "Huftiere"
L["Ur'zul"] = "Ur'zul"
L["Vehicles"] = "Fahrzeuge"
L["Void Creeper"] = "Leerenkrabbler"
L["Void Flyer"] = "Leerenflieger"
L["Vombata"] = "Vombata"
L["Vulpin"] = "Vulpin"
L["Vultures"] = "Geier"
L["War Wolves"] = "Kriegswölfe"
L["Wasp"] = "Wespe"
L["Water Striders"] = "Wasserschreiter"
L["Wilderlings"] = "Wildling"
L["Wind Drakes"] = "Winddrachen"
L["Wolfhawks"] = "Wolfsfalken"
L["Wolves"] = "Wölfe"
L["Worm"] = "Wurm"
L["Wyverns"] = "Wyvern"
L["Yaks"] = "Yaks"
L["Yetis"] = "Yetis"


elseif locale == "esES" then
    L["ANIMATION_FLY"] = "Volar"
L["ANIMATION_FLY_IDLE"] = "Volar quieto"
L["ANIMATION_RUN"] = "Correr"
L["ANIMATION_STAND"] = "Quieto"
L["ANIMATION_WALK"] = "Caminar"
L["ANIMATION_WALK_BACK"] = "Caminar para atrás"
L["ASK_FAVORITE_PROFILE_NAME"] = "Introduce el nombre del perfil:"
L["AUTO_ROTATE"] = "Girar automáticamente"
L["Black Market"] = "Mercado Negro"
L["CLICK_TO_SHOW_LINK"] = "Haz click para mostrar el enlace"
L["COMPARTMENT_TOOLTIP"] = [=[|cffeda55fClick-Izquierdo|r para ver/ocultar la colección de monturas.
|cffeda55fClick-Derecho|r para abrir las opciones del addon.]=]
L["CONFIRM_FAVORITE_PROFILE_DELETION"] = [=[¿Estás seguro de que quieres borrar el perfil favorito "%s"?
Todas las asignaciones de los personajes con el perfil actual se resetearán a las del perfil por defecto "%s".]=]
L["DRESSUP_LABEL"] = "Diario"
L["EVENT_PLUNDERSTORM"] = "Plunderstorm"
L["EVENT_SCARAB"] = "Llamada del Escarabajo"
L["EVENT_SECRETS"] = "Secretos de Azeroth"
L["Family"] = "Familia"
L["FAVOR_AUTO"] = "Añadir nuevas monturas automáticamente"
L["FAVOR_DISPLAYED"] = "Mostrar todas"
L["FAVORITE_ACCOUNT_PROFILE"] = "Cuenta"
L["FAVORITE_PROFILE"] = "Perfil"
L["FILTER_ONLY"] = "sólo"
L["FILTER_ONLY_LATEST"] = "Sólo las últimas añadidas"
L["FILTER_PROFILE"] = "Perfil"
L["FILTER_PROFILE_TOOLTIP_TEXT"] = "Carga rápidamente tu filtro predeterminado y la configuración de búsqueda.|n|cffeda55fClick-Izquierdo|r para cargar el perfil del filtro.|n|cffeda55fClick Derecho|r para guardar el perfil del filtro."
L["FILTER_PROFILE_TOOLTIP_TITLE"] = "Perfiles de filtros"
L["FILTER_RETIRED"] = "Ya no está disponible"
L["FILTER_SECRET"] = "Oculto por el juego"
L["Hidden"] = "Oculto"
L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "|cffeda55fClick izquierdo|r para abrir la Colección de monturas."
L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "|cffeda55fClick derecho|r para seleccionar un Perfil favorito diferente."
L["LDB_TIP_NO_FAVORITES_TITLE"] = "Todavía no has seleccionado ninguna montura como favorita."
L["LINK_WOWHEAD"] = "Enlace a Wowhead"
L["Mite"] = "Ácaros"
L["Only tradable"] = "Sólo comerciable"
L["Passenger"] = "Pasajeros"
L["PET_ASSIGNMENT_INFO"] = "Puedes seleccionar una mascota a esta montura. También será invocada cuando montes.|n|nTodas las selecciones se comparten con todos tus personajes.|n|nPuedes hacer click derecho en la entrada de una mascota para invocarla manualmente.|n|nPor favor, ten en cuenta que la mayoría de las mascotas terrestres no volarán contigo y simplemente desaparecerán cuando te eleves. Además, las mascotas voladoras suelen ser más lentas que tú. Por lo tanto, es posible que necesiten algo de tiempo para alcanzarte.|n|nLa invocación automática de mascotas solo está activa en el contenido del mundo."
L["PET_ASSIGNMENT_NONE"] = "Sin mascota"
L["PET_ASSIGNMENT_TITLE"] = "Seleccionar mascota para la montura"
L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "Mascota seleccionada actualmente:"
L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55fClick izquierdo|r para abrir el seleccionador de mascota."
L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55fClick derecho|r para seleccionar la mascota activa a la montura."
L["Reset filters"] = "Restablecer los filtros"
L["ROTATE_DOWN"] = "Girar hacia abajo"
L["ROTATE_UP"] = "Girar hacia arriba"
L["SORT_BY_FAMILY"] = "Familia"
L["SORT_BY_LAST_USAGE"] = "Usada recientemente"
L["SORT_BY_LEARNED_DATE"] = "Fecha de aprendizaje"
L["SORT_BY_TRAVEL_DISTANCE"] = "Distancia recorrida"
L["SORT_BY_TRAVEL_DURATION"] = "Duración de los viajes"
L["SORT_BY_USAGE_COUNT"] = "Recuento de uso"
L["SORT_FAVORITES_FIRST"] = "Favoritas primero"
L["SORT_REVERSE"] = "Ordenación inversa"
L["SORT_UNOWNED_BOTTOM"] = "Faltantes al final"
L["SORT_UNUSABLE_BOTTOM"] = "Inutilizables después de las Usables"
L["SPECIAL_TIP"] = "Comienza la animación especial de tu montura en el juego."
L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "Número de opciones de personalización coleccionadas"
L["STATS_TIP_LEARNED_DATE_HEAD"] = "Fecha de posesión"
L["STATS_TIP_RARITY_DESCRIPTION"] = "% de personajes que tienen esta montura"
L["STATS_TIP_RARITY_HEAD"] = "Rareza"
L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "Distancia de viaje"
L["STATS_TIP_TRAVEL_TIME_DAYS"] = "en días"
L["STATS_TIP_TRAVEL_TIME_HEAD"] = "Duración del viaje"
L["STATS_TIP_TRAVEL_TIME_TEXT"] = "en horas:minutos:segundos"
L["STATS_TIP_USAGE_COUNT_HEAD"] = "Contador de usos"
L["SYNC_TARGET_TIP_FLAVOR"] = "¡Prepárate para montar!"
L["SYNC_TARGET_TIP_TEXT"] = "Selecciona automáticamente la montura de tu objetivo actual."
L["SYNC_TARGET_TIP_TITLE"] = "Sincroniza el diario con el objetivo"
L["TOGGLE_COLOR"] = "Muestra las variaciones de colores"
L["Transform"] = "Transformaciones"

    -- Settings
L["DISPLAY_ALL_SETTINGS"] = "Mostrar todos los ajustes"
L[ [=[RESET_WINDOW_SIZE
]=] ] = "Restablecer el tamaño del diario"
L["SETTING_ABOUT_AUTHOR"] = "Autor"
L["SETTING_ACHIEVEMENT_POINTS"] = "Mostrar los puntos de logros"
L["SETTING_COLOR_NAMES"] = "Colorear los nombres de la lista según la rareza"
L["SETTING_COMPACT_LIST"] = "Compactar la lista de monturas"
L["SETTING_CURSOR_KEYS"] = "Habilitar las teclas Arriba y Abajo para explorar las monturas"
L["SETTING_DISPLAY_BACKGROUND"] = "Cambiar el color de fondo en la pantalla"
L["SETTING_HEAD_ABOUT"] = "Sobre"
L["SETTING_HEAD_BEHAVIOUR"] = "Comportamiento"
L["SETTING_MOUNT_COUNT"] = "Mostrar el número personal de monturas"
L["SETTING_MOUNTSPECIAL_BUTTON"] = "Mostrar el botón /monturaespecial"
L["SETTING_PERSONAL_FILTER"] = "Aplicar los filtros sólo para este personaje"
L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "Poner las monturas ocultas sólo para este personaje"
L["SETTING_PERSONAL_UI"] = "Aplicar las opciones de interfaz sólo para este personaje"
L["SETTING_PREVIEW_LINK"] = "Mostrar el botón Colección en la vista previa de la montura"
L["SETTING_SEARCH_FAMILY_NAME"] = "Busca también por nombre de familia"
L["SETTING_SEARCH_MORE"] = "Buscar también en la descripción del texto"
L["SETTING_SEARCH_NOTES"] = "Buscar también en las notas propias"
L["SETTING_SHOW_DATA"] = "Muestra la información de la montura en la pantalla"
L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "Mostrar perfiles de filtros en el menú de filtro."
L["SETTING_SHOW_RESIZE_EDGE"] = "Activa el borde en la esquina inferior para cambiar el tamaño de la ventana"
L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "Mostrar botones de la barra de herramientas"
L["SETTING_SUMMONPREVIOUSPET"] = "Invocar de nuevo la mascota activa previamente al desmontar"
L["SETTING_TRACK_USAGE"] = "Seguimiento del comportamiento de uso de las monturas en todos los personajes"
L["SETTING_YCAMERA"] = "Desbloquear la rotación Y del ratón en la pantalla"

    -- Families
L["Airplanes"] = "Aviones"
L["Airships"] = "Naves de Guerra"
L["Albatross"] = "Albatros"
L["Alpacas"] = "Alpacas"
L["Amphibian"] = "Anfibios"
L["Animite"] = "Animácaros"
L["Aqir Flyers"] = "Voladores Aqir"
L["Arachnids"] = "Arácnidos"
L["Armoredon"] = "Rinoceronte Blindado"
L["Basilisks"] = "Basiliscos"
L["Bats"] = "Murciélagos"
L["Bears"] = "Osos"
L["Beetle"] = "Escarabajos"
L["Bipedal Cat"] = "Raptors dientes de sable"
L["Birds"] = "Pájaros"
L["Boars"] = "Jabalies"
L["Bovids"] = "Bóvidos"
L["Broom"] = "Escobas"
L["Brutosaurs"] = "Brutosaurios"
L["Camels"] = "Camellos"
L["Carnivorans"] = "Carnívoros"
L["Carpets"] = "Alfombras"
L["Carrion"] = "Carroña"
L["Cats"] = "Gatos"
L["Cervid"] = "Cérvidos"
L["Chargers"] = "Destreros"
L["Chickens"] = "Pollos"
L["Clefthooves"] = "Uñagrietas"
L["Cloud Serpents"] = "Dragones Nimbo"
L["Core Hounds"] = "Canes del Núcleo"
L["Crabs"] = "Cangrejos"
L["Cranes"] = "Grullas"
L["Crawgs"] = "Tragadones"
L["Crocolisks"] = "Crocoliscos"
L["Crows"] = "Cuervos"
L["Demonic Hounds"] = "Acechadores Viles"
L["Demonic Steeds"] = "Corceles Demoníacos"
L["Demons"] = "Demonios"
L["Devourer"] = "Devoradores"
L["Dinosaurs"] = "Dinosaurios"
L["Dire Wolves"] = "Lobos Temibles"
L["Direhorns"] = "Cuernoatroces"
L["Discs"] = "Discos"
L["Dragonhawks"] = "Dracohalcones"
L["Drakes"] = "Dracos"
L["Dreamsaber"] = "Dientes de Sable de Ensueño"
L["Eagle"] = "Águilas"
L["Elekks"] = "Elekks"
L["Elementals"] = "Elementales"
L["Falcosaurs"] = "Falcosaurios"
L["Fathom Rays"] = "Rayas de las Profundidades"
L["Feathermanes"] = "Crinplumas"
L["Felbat"] = "Murciélago vil"
L["Felsabers"] = "Sablesviles"
L["Fish"] = "Peces"
L["Flies"] = "Moscas"
L["Flying Steeds"] = "Corceles Voladores"
L["Foxes"] = "Zorros"
L["Gargon"] = "Gargones"
L["Gargoyle"] = "Gárgolas"
L["Goats"] = "Cabras"
L["Gorger"] = "Engullidores"
L["Gorm"] = "Gorms"
L["Grand Drakes"] = "Dracos Grandes"
L["Gronnlings"] = "Gronnitos"
L["Gryphons"] = "Grifos"
L["Gyrocopters"] = "Helicópteros"
L["Hands"] = "Manos"
L["Harrower"] = "Lacerante"
L["Hawkstriders"] = "Halcones Zancudos"
L["Hedgehog"] = "Erizos"
L["Hippogryphs"] = "Hipogrifos"
L["Horned Steeds"] = "Corceles Cornudos"
L["Horses"] = "Caballos"
L["Hounds"] = "Canes"
L["Hover Board"] = "Tabla Flotante"
L["Humanoids"] = "Humanoides"
L["Hyenas"] = "Hienas"
L["Infernals"] = "Infernales"
L["Insects"] = "Insectos"
L["Jellyfish"] = "Medusas"
L["Jet Aerial Units"] = "Unidades Aéreas Propulsadas"
L["Kites"] = "Cometas"
L["Kodos"] = "Kodos"
L["Krolusks"] = "Croluscos"
L["Larion"] = "Lariones"
L["Lions"] = "Leones"
L["Lupine"] = "Lupinos"
L["Lynx"] = "Linces"
L["Mammoths"] = "Mamuts"
L["Mana Rays"] = "Rayas de Maná"
L["Mana Wyrm"] = "Vermis de maná"
L["Manasabers"] = "Sables de Maná"
L["Mauler"] = "Aplastadores"
L["Mechanical Animals"] = "Animales Mecánicos"
L["Mechanical Birds"] = "Pájaros Mecánicos"
L["Mechanical Cats"] = "Gatos Mecánicos"
L["Mechanical Steeds"] = "Corceles Mecánicos"
L["Mechanostriders"] = "Mecazancudos"
L["Mecha-suits"] = "Trajes Mecánicos"
L["Meeksi"] = "Meeksi"
L["Mite"] = "Ácaros"
L["Mole"] = "Topos"
L["Mollusc"] = "Moluscos"
L["Moose"] = "Alces"
L["Moth"] = "Polillas"
L["Motorcycles"] = "Motos"
L["Mountain Horses"] = "Caballos de Montaña"
L["Murloc"] = "Múrlocs"
L["Mushan"] = "Mushans"
L["Nether Drakes"] = "Dracos Abisales"
L["Nether Rays"] = "Rayas Abisales"
L["N'Zoth Serpents"] = "Serpientes de N'Zoth"
L["Others"] = "Otros"
L["Ottuk"] = "Nutriones"
L["Owl"] = "Búhos"
L["Owlbear"] = "Lechúcicos"
L["Ox"] = "Ox"
L["Pandaren Phoenixes"] = "Fénix Pandaren"
L["Pangolin"] = "Pangolín"
L["Parrots"] = "Loros"
L["Peafowl"] = "Pavo real"
L["Petalwing"] = "Alapétalo"
L["Phoenixes"] = "Fénix"
L["Plant"] = "Planta"
L["Proto-Drakes"] = "Protodracos"
L["Pterrordaxes"] = "Pterrordáctilos"
L["Quilen"] = "Quilens"
L["Rabbit"] = "Conejos"
L["Rams"] = "Carneros"
L["Raptora"] = "Accipítridos"
L["Raptors"] = "Raptores"
L["Rats"] = "Ratas"
L["Raven"] = "Cuervos"
L["Rays"] = "Rayas"
L["Razorwing"] = "Alafiladas"
L["Reptiles"] = "Reptiles"
L["Rhinos"] = "Rinocerontes"
L["Riverbeasts"] = "Bestias Fluviales"
L["Roc"] = "Rocs"
L["Rockets"] = "Cohetes"
L["Rodent"] = "Roedores"
L["Ruinstriders"] = "Vagarruinas"
L["Rylaks"] = "Rylaks"
L["Sabers"] = "Sables"
L["Scorpions"] = "Escorpiones"
L["Sea Serpents"] = "Serpientes de Mar"
L["Seahorses"] = "Caballitos de Mar"
L["Shalewing"] = "Alaesquistos"
L["Shardhides"] = "Pellejosquirlas"
L["Silithids"] = "Silítidos"
L["Skyrazor"] = "Cuchilla del Cielo"
L["Slateback"] = "Lomopizarra"
L["Slug"] = "Limacos"
L["Snail"] = "Caracoles"
L["Snapdragons"] = "Bocadragones"
L["Spider Tanks"] = "Arañas Mecánicas"
L["Spiders"] = "Arañas"
L["Sporebat"] = "Esporiélagos"
L["Stag"] = "Venados"
L["Steeds"] = "Corceles"
L["Stingrays"] = "Rayas Manta"
L["Stone Cats"] = "Gatos de Piedra"
L["Stone Drakes"] = "Dracos de Piedra"
L["Talbuks"] = "Talbuks"
L["Tallstriders"] = "Zancudos"
L["Talonbirds"] = "Pájaros Garra"
L["Tauralus"] = "Tauralus"
L["Thunder Lizard"] = "Truenagartos"
L["Tigers"] = "Tigres"
L["Toads"] = "Sapos"
L["Turkey"] = "Pavos"
L["Turtles"] = "Tortugas"
L["Undead Drakes"] = "Dracos no Muertos"
L["Undead Steeds"] = "Corceles no Muertos"
L["Undead Wolves"] = "Lobos no Muertos"
L["Ungulates"] = "Ungulados"
L["Ur'zul"] = "Ur'zul"
L["Vehicles"] = "Vehículos"
L["Void Creeper"] = "Trepador del Vacío"
L["Void Flyer"] = "Volador del Vacío"
L["Vombata"] = "Vombatas"
L["Vulpin"] = "Vulpinos"
L["Vultures"] = "Buitres"
L["War Wolves"] = "Lobos de Guerra"
L["Wasp"] = "Avispas"
L["Water Striders"] = "Záncudos Acuáticos"
L["Wilderlings"] = "Salvajizos"
L["Wind Drakes"] = "Dracos del Viento"
L["Wolfhawks"] = "Lobohalcones"
L["Wolves"] = "Lobos"
L["Worm"] = "Gusanos"
L["Wyverns"] = "Dracoleones"
L["Yaks"] = "Yaks"
L["Yetis"] = "Yetis"


elseif locale == "esMX" then
    --[[Translation missing --]]
--[[ L["ANIMATION_FLY"] = "Fly"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_FLY_IDLE"] = "Fly Idle"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_RUN"] = "Run"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_STAND"] = "Stand"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_WALK"] = "ANIMATION_WALK"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_WALK_BACK"] = "Walk Backwards"--]] 
--[[Translation missing --]]
--[[ L["ASK_FAVORITE_PROFILE_NAME"] = "Enter Profile Name:"--]] 
--[[Translation missing --]]
--[[ L["AUTO_ROTATE"] = "Rotate automatically"--]] 
--[[Translation missing --]]
--[[ L["Black Market"] = "Black Market"--]] 
--[[Translation missing --]]
--[[ L["CLICK_TO_SHOW_LINK"] = "Click to Show Link"--]] 
--[[Translation missing --]]
--[[ L["COMPARTMENT_TOOLTIP"] = [=[|cffeda55fLeft-Click|r to toggle showing the mount collection.
|cffeda55fRight-Click|r to open addon options.]=]--]] 
--[[Translation missing --]]
--[[ L["CONFIRM_FAVORITE_PROFILE_DELETION"] = [=[Are you sure you want to delete the profile "%s"?
All current character assignments will be reset to the default profile "%s".]=]--]] 
--[[Translation missing --]]
--[[ L["DRESSUP_LABEL"] = "Journal"--]] 
--[[Translation missing --]]
--[[ L["EVENT_PLUNDERSTORM"] = "Plunderstorm"--]] 
--[[Translation missing --]]
--[[ L["EVENT_SCARAB"] = "Call of the Scarab"--]] 
--[[Translation missing --]]
--[[ L["EVENT_SECRETS"] = "Secrets of Azeroth"--]] 
--[[Translation missing --]]
--[[ L["Family"] = "Family"--]] 
--[[Translation missing --]]
--[[ L["FAVOR_AUTO"] = "Add new mounts automatically"--]] 
--[[Translation missing --]]
--[[ L["FAVOR_DISPLAYED"] = "All Displayed"--]] 
--[[Translation missing --]]
--[[ L["FAVORITE_ACCOUNT_PROFILE"] = "Account"--]] 
--[[Translation missing --]]
--[[ L["FAVORITE_PROFILE"] = "Profile"--]] 
--[[Translation missing --]]
--[[ L["FILTER_ONLY"] = "only"--]] 
--[[Translation missing --]]
--[[ L["FILTER_ONLY_LATEST"] = "Only latest additions"--]] 
--[[Translation missing --]]
--[[ L["FILTER_PROFILE"] = "Profile"--]] 
--[[Translation missing --]]
--[[ L["FILTER_PROFILE_TOOLTIP_TEXT"] = "Quickly load your predefined filter and search settings.|n|cffeda55fLeft-Click|r to load filter profile.|n|cffeda55fRight-Click|r to save filter profile."--]] 
--[[Translation missing --]]
--[[ L["FILTER_PROFILE_TOOLTIP_TITLE"] = "Filter Profiles"--]] 
--[[Translation missing --]]
--[[ L["FILTER_RETIRED"] = "No longer available"--]] 
--[[Translation missing --]]
--[[ L["FILTER_SECRET"] = "Hidden by the game"--]] 
--[[Translation missing --]]
--[[ L["Hidden"] = "Hidden"--]] 
--[[Translation missing --]]
--[[ L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "|cffeda55fLeft click|r to open Mount Collection."--]] 
--[[Translation missing --]]
--[[ L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "|cffeda55fRight click|r to select different Favorite Profile."--]] 
--[[Translation missing --]]
--[[ L["LDB_TIP_NO_FAVORITES_TITLE"] = "You have not selected any mount as favorite yet."--]] 
--[[Translation missing --]]
--[[ L["LINK_WOWHEAD"] = "Link to Wowhead"--]] 
--[[Translation missing --]]
--[[ L["Mite"] = "Mite"--]] 
--[[Translation missing --]]
--[[ L["Only tradable"] = "Only tradable"--]] 
--[[Translation missing --]]
--[[ L["Passenger"] = "Passenger"--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_INFO"] = "You can assign a pet to this mount. It's going to be summoned as well, when you mount up.|n|nAll assignments are shared with all your characters.|n|nYou can use right-click on a pet entry to summon it manually.|n|nPlease be aware that most ground pets won't fly with you and just disappear when you take off. Also, flying pets are usually slower than you. So they might need some time to catch up to you.|n|nAuto summoning pets is only active in world content."--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_NONE"] = "No Pet"--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_TITLE"] = "Assign Pet to Mount"--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "Current assigned Pet:"--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55fLeft click|r to open pet assignment."--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55fRight click|r to assign active pet to mount."--]] 
--[[Translation missing --]]
--[[ L["Reset filters"] = "Reset filters"--]] 
--[[Translation missing --]]
--[[ L["ROTATE_DOWN"] = "Rotate Down"--]] 
--[[Translation missing --]]
--[[ L["ROTATE_UP"] = "Rotate Up"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_FAMILY"] = "Family"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_LAST_USAGE"] = "Last usage"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_LEARNED_DATE"] = "Date of receipt"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_TRAVEL_DISTANCE"] = "Travelled distance"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_TRAVEL_DURATION"] = "Travelled duration"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_USAGE_COUNT"] = "Count of usage"--]] 
--[[Translation missing --]]
--[[ L["SORT_FAVORITES_FIRST"] = "Favorites First"--]] 
--[[Translation missing --]]
--[[ L["SORT_REVERSE"] = "Reverse Sort"--]] 
--[[Translation missing --]]
--[[ L["SORT_UNOWNED_BOTTOM"] = "Unowned at Bottom"--]] 
--[[Translation missing --]]
--[[ L["SORT_UNUSABLE_BOTTOM"] = "Unusable after Usable"--]] 
--[[Translation missing --]]
--[[ L["SPECIAL_TIP"] = "Starts the special animation of your mount in game."--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "Count of collected customization options"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_LEARNED_DATE_HEAD"] = "Possession date"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_RARITY_DESCRIPTION"] = "% of characters who own this mount"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_RARITY_HEAD"] = "Rarity"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "Travel distance"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_TIME_DAYS"] = "in days"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_TIME_HEAD"] = "Travel time"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_TIME_TEXT"] = "in hours:minutes:seconds"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_USAGE_COUNT_HEAD"] = "Usage count"--]] 
--[[Translation missing --]]
--[[ L["SYNC_TARGET_TIP_FLAVOR"] = "Get ready for a mount off!"--]] 
--[[Translation missing --]]
--[[ L["SYNC_TARGET_TIP_TEXT"] = "Automatically select the mount of your current target."--]] 
--[[Translation missing --]]
--[[ L["SYNC_TARGET_TIP_TITLE"] = "Sync Journal with Target"--]] 
--[[Translation missing --]]
--[[ L["TOGGLE_COLOR"] = "Show next color variation"--]] 
--[[Translation missing --]]
--[[ L["Transform"] = "Transform"--]] 

    -- Settings
--[[Translation missing --]]
--[[ L["DISPLAY_ALL_SETTINGS"] = "Display all settings"--]] 
--[[Translation missing --]]
--[[ L[ [=[RESET_WINDOW_SIZE
]=] ] = "Reset journal size"--]] 
--[[Translation missing --]]
--[[ L["SETTING_ABOUT_AUTHOR"] = "Author"--]] 
--[[Translation missing --]]
--[[ L["SETTING_ACHIEVEMENT_POINTS"] = "Show achievement points"--]] 
--[[Translation missing --]]
--[[ L["SETTING_COLOR_NAMES"] = "Colorize names in list based on rarity"--]] 
--[[Translation missing --]]
--[[ L["SETTING_COMPACT_LIST"] = "Compact mount list"--]] 
--[[Translation missing --]]
--[[ L["SETTING_CURSOR_KEYS"] = "Enable Up&Down keys to browse mounts"--]] 
--[[Translation missing --]]
--[[ L["SETTING_DISPLAY_BACKGROUND"] = "Change background color in display"--]] 
--[[Translation missing --]]
--[[ L["SETTING_HEAD_ABOUT"] = "About"--]] 
--[[Translation missing --]]
--[[ L["SETTING_HEAD_BEHAVIOUR"] = "Behavior"--]] 
--[[Translation missing --]]
--[[ L["SETTING_MOUNT_COUNT"] = "Show personal mount count"--]] 
--[[Translation missing --]]
--[[ L["SETTING_MOUNTSPECIAL_BUTTON"] = "Show /mountspecial button"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PERSONAL_FILTER"] = "Apply filters only to this character"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "Apply hidden mounts only to this character"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PERSONAL_UI"] = "Apply Interface settings only to this character"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PREVIEW_LINK"] = "Show Collection button in mount preview"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SEARCH_FAMILY_NAME"] = "Search also by family name"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SEARCH_MORE"] = "Search also in description text"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SEARCH_NOTES"] = "Search also in own notes"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_DATA"] = "Show mount data in display"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "Show filter profiles in filter menu."--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_RESIZE_EDGE"] = "Activate edge in bottom corner to resize window"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "Show toolbar buttons"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SUMMONPREVIOUSPET"] = "Summon previous active pet again when dismounting."--]] 
--[[Translation missing --]]
--[[ L["SETTING_TRACK_USAGE"] = "Track mount usage behavior on all characters"--]] 
--[[Translation missing --]]
--[[ L["SETTING_YCAMERA"] = "Unlock Y rotation with mouse in display"--]] 

    -- Families
--[[Translation missing --]]
--[[ L["Airplanes"] = "Airplanes"--]] 
--[[Translation missing --]]
--[[ L["Airships"] = "Airships"--]] 
--[[Translation missing --]]
--[[ L["Albatross"] = "Albatross"--]] 
--[[Translation missing --]]
--[[ L["Alpacas"] = "Alpacas"--]] 
--[[Translation missing --]]
--[[ L["Amphibian"] = "Amphibian"--]] 
--[[Translation missing --]]
--[[ L["Animite"] = "Animite"--]] 
--[[Translation missing --]]
--[[ L["Aqir Flyers"] = "Aqir Flyers"--]] 
--[[Translation missing --]]
--[[ L["Arachnids"] = "Arachnids"--]] 
--[[Translation missing --]]
--[[ L["Armoredon"] = "Armoredon"--]] 
--[[Translation missing --]]
--[[ L["Basilisks"] = "Basilisks"--]] 
--[[Translation missing --]]
--[[ L["Bats"] = "Bats"--]] 
--[[Translation missing --]]
--[[ L["Bears"] = "Bears"--]] 
--[[Translation missing --]]
--[[ L["Beetle"] = "Beetle"--]] 
--[[Translation missing --]]
--[[ L["Bipedal Cat"] = "Bipedal Cat"--]] 
--[[Translation missing --]]
--[[ L["Birds"] = "Birds"--]] 
--[[Translation missing --]]
--[[ L["Boars"] = "Boars"--]] 
--[[Translation missing --]]
--[[ L["Bovids"] = "Bovids"--]] 
--[[Translation missing --]]
--[[ L["Broom"] = "Broom"--]] 
--[[Translation missing --]]
--[[ L["Brutosaurs"] = "Brutosaurs"--]] 
--[[Translation missing --]]
--[[ L["Camels"] = "Camels"--]] 
--[[Translation missing --]]
--[[ L["Carnivorans"] = "Carnivorans"--]] 
--[[Translation missing --]]
--[[ L["Carpets"] = "Carpets"--]] 
--[[Translation missing --]]
--[[ L["Carrion"] = "Carrion"--]] 
--[[Translation missing --]]
--[[ L["Cats"] = "Cats"--]] 
--[[Translation missing --]]
--[[ L["Cervid"] = "Cervid"--]] 
--[[Translation missing --]]
--[[ L["Chargers"] = "Chargers"--]] 
--[[Translation missing --]]
--[[ L["Chickens"] = "Chickens"--]] 
--[[Translation missing --]]
--[[ L["Clefthooves"] = "Clefthooves"--]] 
--[[Translation missing --]]
--[[ L["Cloud Serpents"] = "Cloud Serpents"--]] 
--[[Translation missing --]]
--[[ L["Core Hounds"] = "Core Hounds"--]] 
--[[Translation missing --]]
--[[ L["Crabs"] = "Crabs"--]] 
--[[Translation missing --]]
--[[ L["Cranes"] = "Cranes"--]] 
--[[Translation missing --]]
--[[ L["Crawgs"] = "Crawgs"--]] 
--[[Translation missing --]]
--[[ L["Crocolisks"] = "Crocolisks"--]] 
--[[Translation missing --]]
--[[ L["Crows"] = "Crows"--]] 
--[[Translation missing --]]
--[[ L["Demonic Hounds"] = "Demonic Hounds"--]] 
--[[Translation missing --]]
--[[ L["Demonic Steeds"] = "Demonic Steeds"--]] 
--[[Translation missing --]]
--[[ L["Demons"] = "Demons"--]] 
--[[Translation missing --]]
--[[ L["Devourer"] = "Devourer"--]] 
--[[Translation missing --]]
--[[ L["Dinosaurs"] = "Dinosaurs"--]] 
--[[Translation missing --]]
--[[ L["Dire Wolves"] = "Dire Wolves"--]] 
--[[Translation missing --]]
--[[ L["Direhorns"] = "Direhorns"--]] 
--[[Translation missing --]]
--[[ L["Discs"] = "Discs"--]] 
--[[Translation missing --]]
--[[ L["Dragonhawks"] = "Dragonhawks"--]] 
--[[Translation missing --]]
--[[ L["Drakes"] = "Drakes"--]] 
--[[Translation missing --]]
--[[ L["Dreamsaber"] = "Dreamsaber"--]] 
--[[Translation missing --]]
--[[ L["Eagle"] = "Eagle"--]] 
--[[Translation missing --]]
--[[ L["Elekks"] = "Elekks"--]] 
--[[Translation missing --]]
--[[ L["Elementals"] = "Elementals"--]] 
--[[Translation missing --]]
--[[ L["Falcosaurs"] = "Falcosaurs"--]] 
--[[Translation missing --]]
--[[ L["Fathom Rays"] = "Fathom Rays"--]] 
--[[Translation missing --]]
--[[ L["Feathermanes"] = "Feathermanes"--]] 
--[[Translation missing --]]
--[[ L["Felbat"] = "Felbat"--]] 
--[[Translation missing --]]
--[[ L["Felsabers"] = "Felsabers"--]] 
--[[Translation missing --]]
--[[ L["Fish"] = "Fish"--]] 
--[[Translation missing --]]
--[[ L["Flies"] = "Flies"--]] 
--[[Translation missing --]]
--[[ L["Flying Steeds"] = "Flying Steeds"--]] 
--[[Translation missing --]]
--[[ L["Foxes"] = "Foxes"--]] 
--[[Translation missing --]]
--[[ L["Gargon"] = "Gargon"--]] 
--[[Translation missing --]]
--[[ L["Gargoyle"] = "Gargoyle"--]] 
--[[Translation missing --]]
--[[ L["Goats"] = "Goats"--]] 
--[[Translation missing --]]
--[[ L["Gorger"] = "Gorger"--]] 
--[[Translation missing --]]
--[[ L["Gorm"] = "Gorm"--]] 
--[[Translation missing --]]
--[[ L["Grand Drakes"] = "Grand Drakes"--]] 
--[[Translation missing --]]
--[[ L["Gronnlings"] = "Gronnlings"--]] 
--[[Translation missing --]]
--[[ L["Gryphons"] = "Gryphons"--]] 
--[[Translation missing --]]
--[[ L["Gyrocopters"] = "Gyrocopters"--]] 
--[[Translation missing --]]
--[[ L["Hands"] = "Hands"--]] 
--[[Translation missing --]]
--[[ L["Harrower"] = "Harrower"--]] 
--[[Translation missing --]]
--[[ L["Hawkstriders"] = "Hawkstriders"--]] 
--[[Translation missing --]]
--[[ L["Hedgehog"] = "Hedgehog"--]] 
--[[Translation missing --]]
--[[ L["Hippogryphs"] = "Hippogryphs"--]] 
--[[Translation missing --]]
--[[ L["Horned Steeds"] = "Horned Steeds"--]] 
--[[Translation missing --]]
--[[ L["Horses"] = "Horses"--]] 
--[[Translation missing --]]
--[[ L["Hounds"] = "Hounds"--]] 
--[[Translation missing --]]
--[[ L["Hover Board"] = "Hover Board"--]] 
--[[Translation missing --]]
--[[ L["Humanoids"] = "Humanoids"--]] 
--[[Translation missing --]]
--[[ L["Hyenas"] = "Hyenas"--]] 
--[[Translation missing --]]
--[[ L["Infernals"] = "Infernals"--]] 
--[[Translation missing --]]
--[[ L["Insects"] = "Insects"--]] 
--[[Translation missing --]]
--[[ L["Jellyfish"] = "Jellyfish"--]] 
--[[Translation missing --]]
--[[ L["Jet Aerial Units"] = "Jet Aerial Units"--]] 
--[[Translation missing --]]
--[[ L["Kites"] = "Kites"--]] 
--[[Translation missing --]]
--[[ L["Kodos"] = "Kodos"--]] 
--[[Translation missing --]]
--[[ L["Krolusks"] = "Krolusks"--]] 
--[[Translation missing --]]
--[[ L["Larion"] = "Larion"--]] 
--[[Translation missing --]]
--[[ L["Lions"] = "Lions"--]] 
--[[Translation missing --]]
--[[ L["Lupine"] = "Lupine"--]] 
L["Lynx"] = "Lince"
--[[Translation missing --]]
--[[ L["Mammoths"] = "Mammoths"--]] 
--[[Translation missing --]]
--[[ L["Mana Rays"] = "Mana Rays"--]] 
--[[Translation missing --]]
--[[ L["Mana Wyrm"] = "Mana Wyrm"--]] 
--[[Translation missing --]]
--[[ L["Manasabers"] = "Manasabers"--]] 
--[[Translation missing --]]
--[[ L["Mauler"] = "Mauler"--]] 
--[[Translation missing --]]
--[[ L["Mechanical Animals"] = "Mechanical Animals"--]] 
--[[Translation missing --]]
--[[ L["Mechanical Birds"] = "Mechanical Birds"--]] 
--[[Translation missing --]]
--[[ L["Mechanical Cats"] = "Mechanical Cats"--]] 
--[[Translation missing --]]
--[[ L["Mechanical Steeds"] = "Mechanical Steeds"--]] 
--[[Translation missing --]]
--[[ L["Mechanostriders"] = "Mechanostriders"--]] 
--[[Translation missing --]]
--[[ L["Mecha-suits"] = "Mecha-suits"--]] 
--[[Translation missing --]]
--[[ L["Meeksi"] = "Meeksi"--]] 
--[[Translation missing --]]
--[[ L["Mite"] = "Mite"--]] 
--[[Translation missing --]]
--[[ L["Mole"] = "Mole"--]] 
--[[Translation missing --]]
--[[ L["Mollusc"] = "Mollusc"--]] 
--[[Translation missing --]]
--[[ L["Moose"] = "Moose"--]] 
--[[Translation missing --]]
--[[ L["Moth"] = "Moth"--]] 
--[[Translation missing --]]
--[[ L["Motorcycles"] = "Motorcycles"--]] 
--[[Translation missing --]]
--[[ L["Mountain Horses"] = "Mountain Horses"--]] 
--[[Translation missing --]]
--[[ L["Murloc"] = "Murloc"--]] 
--[[Translation missing --]]
--[[ L["Mushan"] = "Mushan"--]] 
--[[Translation missing --]]
--[[ L["Nether Drakes"] = "Nether Drakes"--]] 
--[[Translation missing --]]
--[[ L["Nether Rays"] = "Nether Rays"--]] 
--[[Translation missing --]]
--[[ L["N'Zoth Serpents"] = "N'Zoth Serpents"--]] 
--[[Translation missing --]]
--[[ L["Others"] = "Others"--]] 
--[[Translation missing --]]
--[[ L["Ottuk"] = "Ottuk"--]] 
--[[Translation missing --]]
--[[ L["Owl"] = "Owl"--]] 
--[[Translation missing --]]
--[[ L["Owlbear"] = "Owlbear"--]] 
--[[Translation missing --]]
--[[ L["Ox"] = "Ox"--]] 
--[[Translation missing --]]
--[[ L["Pandaren Phoenixes"] = "Pandaren Phoenixes"--]] 
--[[Translation missing --]]
--[[ L["Pangolin"] = "Pangolin"--]] 
--[[Translation missing --]]
--[[ L["Parrots"] = "Parrots"--]] 
--[[Translation missing --]]
--[[ L["Peafowl"] = "Peafowl"--]] 
--[[Translation missing --]]
--[[ L["Petalwing"] = "Petalwing"--]] 
--[[Translation missing --]]
--[[ L["Phoenixes"] = "Phoenixes"--]] 
--[[Translation missing --]]
--[[ L["Plant"] = "Plant"--]] 
--[[Translation missing --]]
--[[ L["Proto-Drakes"] = "Proto-Drakes"--]] 
--[[Translation missing --]]
--[[ L["Pterrordaxes"] = "Pterrordaxes"--]] 
--[[Translation missing --]]
--[[ L["Quilen"] = "Quilen"--]] 
--[[Translation missing --]]
--[[ L["Rabbit"] = "Rabbit"--]] 
--[[Translation missing --]]
--[[ L["Rams"] = "Rams"--]] 
--[[Translation missing --]]
--[[ L["Raptora"] = "Raptora"--]] 
--[[Translation missing --]]
--[[ L["Raptors"] = "Raptors"--]] 
--[[Translation missing --]]
--[[ L["Rats"] = "Rats"--]] 
--[[Translation missing --]]
--[[ L["Raven"] = "Raven"--]] 
--[[Translation missing --]]
--[[ L["Rays"] = "Rays"--]] 
--[[Translation missing --]]
--[[ L["Razorwing"] = "Razorwing"--]] 
--[[Translation missing --]]
--[[ L["Reptiles"] = "Reptiles"--]] 
--[[Translation missing --]]
--[[ L["Rhinos"] = "Rhinos"--]] 
--[[Translation missing --]]
--[[ L["Riverbeasts"] = "Riverbeasts"--]] 
--[[Translation missing --]]
--[[ L["Roc"] = "Roc"--]] 
--[[Translation missing --]]
--[[ L["Rockets"] = "Rockets"--]] 
--[[Translation missing --]]
--[[ L["Rodent"] = "Rodent"--]] 
--[[Translation missing --]]
--[[ L["Ruinstriders"] = "Ruinstriders"--]] 
--[[Translation missing --]]
--[[ L["Rylaks"] = "Rylaks"--]] 
--[[Translation missing --]]
--[[ L["Sabers"] = "Sabers"--]] 
--[[Translation missing --]]
--[[ L["Scorpions"] = "Scorpions"--]] 
--[[Translation missing --]]
--[[ L["Sea Serpents"] = "Sea Serpents"--]] 
--[[Translation missing --]]
--[[ L["Seahorses"] = "Seahorses"--]] 
--[[Translation missing --]]
--[[ L["Shalewing"] = "Shalewing"--]] 
--[[Translation missing --]]
--[[ L["Shardhides"] = "Shardhides"--]] 
--[[Translation missing --]]
--[[ L["Silithids"] = "Silithids"--]] 
--[[Translation missing --]]
--[[ L["Skyrazor"] = "Skyrazor"--]] 
--[[Translation missing --]]
--[[ L["Slateback"] = "Slateback"--]] 
--[[Translation missing --]]
--[[ L["Slug"] = "Slug"--]] 
--[[Translation missing --]]
--[[ L["Snail"] = "Snail"--]] 
--[[Translation missing --]]
--[[ L["Snapdragons"] = "Snapdragons"--]] 
--[[Translation missing --]]
--[[ L["Spider Tanks"] = "Spider Tanks"--]] 
--[[Translation missing --]]
--[[ L["Spiders"] = "Spiders"--]] 
--[[Translation missing --]]
--[[ L["Sporebat"] = "Sporebat"--]] 
--[[Translation missing --]]
--[[ L["Stag"] = "Stag"--]] 
--[[Translation missing --]]
--[[ L["Steeds"] = "Steeds"--]] 
--[[Translation missing --]]
--[[ L["Stingrays"] = "Stingrays"--]] 
--[[Translation missing --]]
--[[ L["Stone Cats"] = "Stone Cats"--]] 
--[[Translation missing --]]
--[[ L["Stone Drakes"] = "Stone Drakes"--]] 
--[[Translation missing --]]
--[[ L["Talbuks"] = "Talbuks"--]] 
--[[Translation missing --]]
--[[ L["Tallstriders"] = "Tallstriders"--]] 
--[[Translation missing --]]
--[[ L["Talonbirds"] = "Talonbirds"--]] 
--[[Translation missing --]]
--[[ L["Tauralus"] = "Tauralus"--]] 
--[[Translation missing --]]
--[[ L["Thunder Lizard"] = "Thunder Lizard"--]] 
--[[Translation missing --]]
--[[ L["Tigers"] = "Tigers"--]] 
--[[Translation missing --]]
--[[ L["Toads"] = "Toads"--]] 
--[[Translation missing --]]
--[[ L["Turkey"] = "Turkey"--]] 
--[[Translation missing --]]
--[[ L["Turtles"] = "Turtles"--]] 
--[[Translation missing --]]
--[[ L["Undead Drakes"] = "Undead Drakes"--]] 
--[[Translation missing --]]
--[[ L["Undead Steeds"] = "Undead Steeds"--]] 
--[[Translation missing --]]
--[[ L["Undead Wolves"] = "Undead Wolves"--]] 
--[[Translation missing --]]
--[[ L["Ungulates"] = "Ungulates"--]] 
--[[Translation missing --]]
--[[ L["Ur'zul"] = "Ur'zul"--]] 
--[[Translation missing --]]
--[[ L["Vehicles"] = "Vehicles"--]] 
--[[Translation missing --]]
--[[ L["Void Creeper"] = "Void Creeper"--]] 
--[[Translation missing --]]
--[[ L["Void Flyer"] = "Void Flyer"--]] 
--[[Translation missing --]]
--[[ L["Vombata"] = "Vombata"--]] 
--[[Translation missing --]]
--[[ L["Vulpin"] = "Vulpin"--]] 
--[[Translation missing --]]
--[[ L["Vultures"] = "Vultures"--]] 
--[[Translation missing --]]
--[[ L["War Wolves"] = "War Wolves"--]] 
--[[Translation missing --]]
--[[ L["Wasp"] = "Wasp"--]] 
--[[Translation missing --]]
--[[ L["Water Striders"] = "Water Striders"--]] 
--[[Translation missing --]]
--[[ L["Wilderlings"] = "Wilderlings"--]] 
--[[Translation missing --]]
--[[ L["Wind Drakes"] = "Wind Drakes"--]] 
--[[Translation missing --]]
--[[ L["Wolfhawks"] = "Wolfhawks"--]] 
--[[Translation missing --]]
--[[ L["Wolves"] = "Wolves"--]] 
--[[Translation missing --]]
--[[ L["Worm"] = "Worm"--]] 
--[[Translation missing --]]
--[[ L["Wyverns"] = "Wyverns"--]] 
--[[Translation missing --]]
--[[ L["Yaks"] = "Yaks"--]] 
--[[Translation missing --]]
--[[ L["Yetis"] = "Yetis"--]] 


elseif locale == "frFR" then
    L["ANIMATION_FLY"] = "Vol"
L["ANIMATION_FLY_IDLE"] = "Vol stationnaire"
L["ANIMATION_RUN"] = "Course"
L["ANIMATION_STAND"] = "Debout"
L["ANIMATION_WALK"] = "Marche"
L["ANIMATION_WALK_BACK"] = "Marche à reculons"
L["ASK_FAVORITE_PROFILE_NAME"] = "Saisir le nom du profil :"
L["AUTO_ROTATE"] = "Rotation automatique"
L["Black Market"] = "Marché Noir"
L["CLICK_TO_SHOW_LINK"] = "Cliquez pour afficher le lien"
L["COMPARTMENT_TOOLTIP"] = [=[|cffeda55fClic gauche|r pour afficher la collection de montures. 
|cffeda55fClic droit|r pour ouvrir les options de l'addon.]=]
L["CONFIRM_FAVORITE_PROFILE_DELETION"] = "Êtes-vous sûr de vouloir supprimer le profil \"%s\" ? Toutes les caractéristiques liées au personnage actuel seront réinitialisées au profil par défaut \"%s\"."
L["DRESSUP_LABEL"] = "Collection"
L["EVENT_PLUNDERSTORM"] = "Plunderstorm"
L["EVENT_SCARAB"] = "Appel du Scarabée"
L["EVENT_SECRETS"] = "Secrets d’Azeroth"
L["Family"] = "Famille"
L["FAVOR_AUTO"] = "Ajouter les nouvelles montures automatiquement"
L["FAVOR_DISPLAYED"] = "Toutes affichées"
L["FAVORITE_ACCOUNT_PROFILE"] = "Compte"
L["FAVORITE_PROFILE"] = "Profil"
L["FILTER_ONLY"] = "uniquement"
L["FILTER_ONLY_LATEST"] = "Uniquement les dernières ajoutées"
L["FILTER_PROFILE"] = "Profils"
L["FILTER_PROFILE_TOOLTIP_TEXT"] = "Chargez rapidement vos paramètres de filtre et de recherche prédéfinis.|n|cffeda55fClic gauche|r pour charger le profil de filtre.|n|cffeda55fClic droit|r pour enregistrer le profil de filtre."
L["FILTER_PROFILE_TOOLTIP_TITLE"] = [=[Profils de filtre
]=]
L["FILTER_RETIRED"] = "Indisponible"
L["FILTER_SECRET"] = "Cachées par le jeu"
L["Hidden"] = "Cachées"
L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "Faites un |cffeda55fClic gauche|r pour ouvrir la Collection des montures."
L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "Faites un |cffeda55fClic droit|r pour sélectionner un Profil favori différent."
L["LDB_TIP_NO_FAVORITES_TITLE"] = "Vous n'avez pas encore sélectionné de monture comme favorite."
L["LINK_WOWHEAD"] = "Lien vers Wowhead"
L["Mite"] = "Mite"
L["Only tradable"] = "Uniquement échangeable"
L["Passenger"] = "Passagers"
L["PET_ASSIGNMENT_INFO"] = "Vous pouvez assigner une mascotte à cette monture. Elle sera également invoquée lorsque vous monterez sur la monture.|n|nToutes les assignations sont partagées avec chacun de vos personnages.|n|nVous pouvez faire un clic droit sur la ligne d'une mascotte pour l'invoquer manuellement.|n|nNotez que la plupart des mascottes terrestres ne voleront pas avec vous et disparaîtront dès que vous décollerez. De plus, les mascottes volantes sont généralement plus lentes que vous. Elles peuvent donc avoir besoin d'un peu de temps pour vous rattraper.|n|nL'invocation automatique des mascottes n'est active que pour le contenu hors-instances."
L["PET_ASSIGNMENT_NONE"] = "Pas de mascotte"
L["PET_ASSIGNMENT_TITLE"] = "Assigner la mascotte à la monture"
L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "Mascotte assignée actuellement :"
L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "Faites un |cffeda55fClic gauche|r pour ouvrir l'assignation de mascottes."
L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "Faites un |cffeda55fClic droit|r pour assigner la mascotte active à la monture."
L["Reset filters"] = "Réinitialiser les filtres"
L["ROTATE_DOWN"] = "Pivoter vers le bas"
L["ROTATE_UP"] = "Pivoter vers le haut"
L["SORT_BY_FAMILY"] = "Famille"
L["SORT_BY_LAST_USAGE"] = "Dernière utilisation"
L["SORT_BY_LEARNED_DATE"] = "Date d’obtention"
L["SORT_BY_TRAVEL_DISTANCE"] = "Distance des trajets"
L["SORT_BY_TRAVEL_DURATION"] = "Temps des trajets"
L["SORT_BY_USAGE_COUNT"] = "Nombre d’utilisations"
L["SORT_FAVORITES_FIRST"] = "Favorites en premier"
L["SORT_REVERSE"] = "Tri inversé"
L["SORT_UNOWNED_BOTTOM"] = "Non possédées en bas"
L["SORT_UNUSABLE_BOTTOM"] = "Inutilisable après Utilisable"
L["SPECIAL_TIP"] = "Lance l’animation spéciale de votre monture en jeu."
L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "Nombre d’options de personnalisation récupérées"
L["STATS_TIP_LEARNED_DATE_HEAD"] = "Date d’obtention"
L["STATS_TIP_RARITY_DESCRIPTION"] = "% de personnages qui possèdent cette monture"
L["STATS_TIP_RARITY_HEAD"] = "Rareté"
L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "Longueur des trajets"
L["STATS_TIP_TRAVEL_TIME_DAYS"] = "en jours"
L["STATS_TIP_TRAVEL_TIME_HEAD"] = "Durée des trajets"
L["STATS_TIP_TRAVEL_TIME_TEXT"] = "en heures:minutes:secondes"
L["STATS_TIP_USAGE_COUNT_HEAD"] = "Nombre d’utilisations"
L["SYNC_TARGET_TIP_FLAVOR"] = "Préparez-vous à une compétition de montures !"
L["SYNC_TARGET_TIP_TEXT"] = "Sélectionne automatiquement la même monture que la cible."
L["SYNC_TARGET_TIP_TITLE"] = "Synchroniser avec la cible"
L["TOGGLE_COLOR"] = "Afficher la variante de couleur suivante"
L["Transform"] = "Transformation"

    -- Settings
L["DISPLAY_ALL_SETTINGS"] = "Afficher tous les paramètres"
L[ [=[RESET_WINDOW_SIZE
]=] ] = "Réinitialiser la taille de la fenêtre du journal"
L["SETTING_ABOUT_AUTHOR"] = "Auteur"
L["SETTING_ACHIEVEMENT_POINTS"] = "Afficher les points de hauts faits"
L["SETTING_COLOR_NAMES"] = "Coloriser les noms de la liste en fonction de la rareté"
L["SETTING_COMPACT_LIST"] = "Liste des montures compacte"
L["SETTING_CURSOR_KEYS"] = "Activer les touches Haut et Bas pour parcourir les montures"
L["SETTING_DISPLAY_BACKGROUND"] = "Modifier la couleur d’arrière-plan de la fenêtre d’affichage"
L["SETTING_HEAD_ABOUT"] = "À propos"
L["SETTING_HEAD_BEHAVIOUR"] = "Comportement"
L["SETTING_MOUNT_COUNT"] = "Afficher le nombre personnel de montures"
L["SETTING_MOUNTSPECIAL_BUTTON"] = "Afficher le bouton pour le /mountspecial"
L["SETTING_PERSONAL_FILTER"] = "Appliquer des filtres uniquement à ce personnage"
L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "Appliquer les montures cachées uniquement à ce personnage"
L["SETTING_PERSONAL_UI"] = "Appliquer les paramètres d’interface uniquement à ce personnage"
L["SETTING_PREVIEW_LINK"] = "Afficher le bouton de la Collection dans l’aperçu de la monture"
L["SETTING_SEARCH_FAMILY_NAME"] = "Rechercher également avec le nom des familles"
L["SETTING_SEARCH_MORE"] = "Rechercher également dans le texte de la description"
L["SETTING_SEARCH_NOTES"] = "Rechercher également dans vos propres notes"
L["SETTING_SHOW_DATA"] = "Afficher les données des montures dans le journal"
L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "Afficher les profils de filtre dans le menu de filtre."
L["SETTING_SHOW_RESIZE_EDGE"] = "Activer la marge dans le coin inférieur pour redimensionner la fenêtre"
L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "Afficher les boutons de la barre d'outils"
L["SETTING_SUMMONPREVIOUSPET"] = "Invoquer à nouveau la mascotte active précédemment lorsque vous descendez de monture."
L["SETTING_TRACK_USAGE"] = "Suivre le comportement d’utilisation des montures sur tous les personnages"
L["SETTING_YCAMERA"] = "Débloquer la rotation sur l’axe Y avec la souris dans la fenêtre d’affichage"

    -- Families
L["Airplanes"] = "Avions"
L["Airships"] = "Dirigeables"
L["Albatross"] = "Albatros"
L["Alpacas"] = "Alpagas"
L["Amphibian"] = "Amphibien"
L["Animite"] = "Animacarus"
L["Aqir Flyers"] = "Mouches Aqir"
L["Arachnids"] = "Arachnides"
L["Armoredon"] = "Armoredon"
L["Basilisks"] = "Basilics"
L["Bats"] = "Chauves-souris"
L["Bears"] = "Ours"
L["Beetle"] = "Scarabées"
L["Bipedal Cat"] = "Chats bipèdes"
L["Birds"] = "Oiseaux"
L["Boars"] = "Sangliers"
L["Bovids"] = "Bovidés"
L["Broom"] = "Balai"
L["Brutosaurs"] = "Brutosaures"
L["Camels"] = "Dromadaires"
L["Carnivorans"] = "Carnivores"
L["Carpets"] = "Tapis"
--[[Translation missing --]]
--[[ L["Carrion"] = "Carrion"--]] 
L["Cats"] = "Félins"
L["Cervid"] = "Cervidés"
L["Chargers"] = "Destriers"
L["Chickens"] = "Poulets"
L["Clefthooves"] = "Sabot-fourchus"
L["Cloud Serpents"] = "Serpents-nuage"
L["Core Hounds"] = "Chien du magma"
L["Crabs"] = "Crabes"
L["Cranes"] = "Grues"
L["Crawgs"] = "Croggs"
L["Crocolisks"] = "Crocilisques"
L["Crows"] = "Corbeaux"
L["Demonic Hounds"] = "Molosses démoniaques"
L["Demonic Steeds"] = "Palefrois démoniaques"
L["Demons"] = "Démons"
L["Devourer"] = "Dévoreurs"
L["Dinosaurs"] = "Dinosaures"
L["Dire Wolves"] = "Loups redoutables"
L["Direhorns"] = "Navrecornes"
L["Discs"] = "Disques"
L["Dragonhawks"] = "Faucon-dragons"
L["Drakes"] = "Drakes"
L["Dreamsaber"] = "Sabres de rêve"
L["Eagle"] = "Aigles"
L["Elekks"] = "Elekks"
L["Elementals"] = "Élémentaires"
L["Falcosaurs"] = "Falcosaures"
L["Fathom Rays"] = "Raies pélagiques"
L["Feathermanes"] = "Crins-de-plume"
L["Felbat"] = "Gangroptère"
L["Felsabers"] = "Gangresabres"
L["Fish"] = "Poissons"
L["Flies"] = "Mouches"
L["Flying Steeds"] = "Palefrois volants"
L["Foxes"] = "Renards"
L["Gargon"] = "Gargon"
L["Gargoyle"] = "Gargouilles"
L["Goats"] = "Chèvres"
L["Gorger"] = "Goinfre"
L["Gorm"] = "Gorm"
L["Grand Drakes"] = "Grands drakes"
L["Gronnlings"] = "Gronnlins"
L["Gryphons"] = "Griffons"
L["Gyrocopters"] = "Gyrocoptère"
L["Hands"] = "Mains"
--[[Translation missing --]]
--[[ L["Harrower"] = "Harrower"--]] 
L["Hawkstriders"] = "Faucon-pérégrins"
L["Hedgehog"] = "Hérisson"
L["Hippogryphs"] = "Hippogriffes"
L["Horned Steeds"] = "Palefrois à cornes"
L["Horses"] = "Chevaux"
L["Hounds"] = "Molosses"
L["Hover Board"] = "Hover Board"
L["Humanoids"] = "Humanoïdes"
L["Hyenas"] = "Hyènes"
L["Infernals"] = "Infernaux"
L["Insects"] = "Insectes"
L["Jellyfish"] = "Méduses"
L["Jet Aerial Units"] = "Unités aériennes à réaction"
L["Kites"] = "Cerfs-volants"
L["Kodos"] = "Kodos"
L["Krolusks"] = "Krolusks"
L["Larion"] = "Volion"
L["Lions"] = "Lions"
L["Lupine"] = "Lupins"
L["Lynx"] = "Lynx"
L["Mammoths"] = "Mammouths"
L["Mana Rays"] = "Raies de mana"
L["Mana Wyrm"] = "Wyrm de mana"
L["Manasabers"] = "Sabres-de-mana"
L["Mauler"] = "Marteleurs"
L["Mechanical Animals"] = "Animaux mécaniques"
L["Mechanical Birds"] = "Oiseaux mécaniques"
L["Mechanical Cats"] = "Félins mécaniques"
L["Mechanical Steeds"] = "Palefrois mécaniques"
L["Mechanostriders"] = "Mécanotrotteurs"
L["Mecha-suits"] = "Armures mécaniques"
L["Meeksi"] = "Meeksi"
L["Mite"] = "Acarus"
L["Mole"] = "Taupe"
L["Mollusc"] = "Mollusques"
L["Moose"] = "Élans"
L["Moth"] = "Phalènes"
L["Motorcycles"] = "Motos"
L["Mountain Horses"] = "Chevaux des montagnes"
L["Murloc"] = "Murloc"
L["Mushan"] = "Mushans"
L["Nether Drakes"] = "Drakes du Néant"
L["Nether Rays"] = "Raies du Néant"
L["N'Zoth Serpents"] = "Serpents de N'Zoth"
L["Others"] = "Autres"
L["Ottuk"] = "Loutrèkes"
L["Owl"] = "Chouettes"
L["Owlbear"] = "Chouettes-ours"
L["Ox"] = "Buffle"
L["Pandaren Phoenixes"] = "Phénix pandarens"
L["Pangolin"] = "Pangolin"
L["Parrots"] = "Psittaciformes"
L["Peafowl"] = "Paon"
--[[Translation missing --]]
--[[ L["Petalwing"] = "Petalwing"--]] 
L["Phoenixes"] = "Phénix"
--[[Translation missing --]]
--[[ L["Plant"] = "Plant"--]] 
L["Proto-Drakes"] = "Proto-drakes"
L["Pterrordaxes"] = "Pterreurdactyles"
L["Quilen"] = "Quilens"
L["Rabbit"] = "Lapins"
L["Rams"] = "Béliers"
L["Raptora"] = "Raptoras"
L["Raptors"] = "Raptors"
L["Rats"] = "Rats"
L["Raven"] = "Corbeau"
L["Rays"] = "Raies"
L["Razorwing"] = "Rasailes"
L["Reptiles"] = "Reptiles"
L["Rhinos"] = "Rhinocéros"
L["Riverbeasts"] = "Potamodontes"
L["Roc"] = "Rocs"
L["Rockets"] = "Fusées"
L["Rodent"] = "Rongeurs"
L["Ruinstriders"] = "Foules-ruines"
L["Rylaks"] = "Rylaks"
L["Sabers"] = "Smilodons"
L["Scorpions"] = "Scorpides"
L["Sea Serpents"] = "Serpents de mer"
L["Seahorses"] = "Hippocampes"
L["Shalewing"] = "Aile-de-schiste"
L["Shardhides"] = "Сuirasaure"
L["Silithids"] = "Silithides"
L["Skyrazor"] = "Rasoir-céleste"
L["Slateback"] = "Ardospine"
L["Slug"] = "Limaces"
L["Snail"] = "Escargots"
L["Snapdragons"] = "Mordragons"
L["Spider Tanks"] = "Chars araignée"
L["Spiders"] = "Araignées"
L["Sporebat"] = "Sporoptères"
L["Stag"] = "Cerfs"
L["Steeds"] = "Palefrois"
L["Stingrays"] = "Pastenagues"
L["Stone Cats"] = "Chats de pierre"
L["Stone Drakes"] = "Drakes de pierre"
L["Talbuks"] = "Talbuks"
L["Tallstriders"] = "Trotteurs"
L["Talonbirds"] = "Rapaces"
L["Tauralus"] = "Tauralus"
L["Thunder Lizard"] = "Lézard-tonnerre"
L["Tigers"] = "Tigres"
L["Toads"] = "Crapauds"
L["Turkey"] = "Dinde"
L["Turtles"] = "Tortues"
L["Undead Drakes"] = "Drakes morts-vivants"
L["Undead Steeds"] = "Palefrois morts-vivants"
L["Undead Wolves"] = "Loups morts-vivants"
L["Ungulates"] = "Ongulés"
L["Ur'zul"] = "Ur'zul"
L["Vehicles"] = "Véhicules"
L["Void Creeper"] = "Rampant du Vide"
L["Void Flyer"] = "Voltigeur du Vide"
L["Vombata"] = "Vombata"
L["Vulpin"] = "Vulpins"
L["Vultures"] = "Vautours"
L["War Wolves"] = "Loups de guerre"
L["Wasp"] = "Guêpes"
L["Water Striders"] = "Trotteurs aquatiques"
L["Wilderlings"] = "Lycodracs"
L["Wind Drakes"] = "Drakes des vents"
L["Wolfhawks"] = "Loups-faucons"
L["Wolves"] = "Loups"
L["Worm"] = "Ver"
L["Wyverns"] = "Wyvernes"
L["Yaks"] = "Yacks"
L["Yetis"] = "Yétis"


elseif locale == "itIT" then
    L["ANIMATION_FLY"] = "Volare"
L["ANIMATION_FLY_IDLE"] = "Volare inattivo"
L["ANIMATION_RUN"] = "Correre"
L["ANIMATION_STAND"] = "In piedi"
L["ANIMATION_WALK"] = "ANIMATION_WALK"
L["ANIMATION_WALK_BACK"] = "Camminare all'indietro"
L["ASK_FAVORITE_PROFILE_NAME"] = "Inserisci il nome del profilo:"
L["AUTO_ROTATE"] = "Ruota automaticamente"
L["Black Market"] = "Mercato nero"
L["CLICK_TO_SHOW_LINK"] = "Clicca per mostrare il collegamento"
L["COMPARTMENT_TOOLTIP"] = "|cffeda55fClic sinistro|r per attivare/disattivare la visualizzazione della raccolta di mount. |cffeda55fClic destro|r per aprire le opzioni del componente aggiuntivo."
L["CONFIRM_FAVORITE_PROFILE_DELETION"] = "Vuoi davvero eliminare il profilo \"%s\"? Tutte le assegnazioni dei personaggi attuali verranno ripristinate al profilo predefinito \"%s\"."
L["DRESSUP_LABEL"] = "Giornale"
--[[Translation missing --]]
--[[ L["EVENT_PLUNDERSTORM"] = "Plunderstorm"--]] 
L["EVENT_SCARAB"] = "Richiamo dello Scarabeo"
L["EVENT_SECRETS"] = "Secrets of Azeroth"
--[[Translation missing --]]
--[[ L["Family"] = "Family"--]] 
--[[Translation missing --]]
--[[ L["FAVOR_AUTO"] = "Add new mounts automatically"--]] 
--[[Translation missing --]]
--[[ L["FAVOR_DISPLAYED"] = "All Displayed"--]] 
L["FAVORITE_ACCOUNT_PROFILE"] = "Account"
L["FAVORITE_PROFILE"] = "Profilo"
L["FILTER_ONLY"] = "soltanto"
--[[Translation missing --]]
--[[ L["FILTER_ONLY_LATEST"] = "Only latest additions"--]] 
L["FILTER_PROFILE"] = "Profili"
L["FILTER_PROFILE_TOOLTIP_TEXT"] = "Carica rapidamente le impostazioni predefinite di filtro e ricerca.|n|cffeda55fFai clic con il tasto sinistro|r per caricare il profilo del filtro.|n|cffeda55fFai clic con il tasto destro|r per salvare il profilo del filtro."
L["FILTER_PROFILE_TOOLTIP_TITLE"] = "Profili filtro"
L["FILTER_RETIRED"] = "Non più disponibile"
L["FILTER_SECRET"] = "Nascosto dal gioco"
L["Hidden"] = "Nascosta"
L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "|cffeda55fFare clic con il tasto sinistro|r per aprire la raccolta di supporti."
L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "|cffeda55fFai clic con il tasto destro del mouse|r per selezionare un profilo preferito diverso."
L["LDB_TIP_NO_FAVORITES_TITLE"] = "Non hai ancora selezionato nessuna cavalcatura come preferita."
L["LINK_WOWHEAD"] = "Collegamento al Wowhead"
L["Mite"] = "Acaro"
--[[Translation missing --]]
--[[ L["Only tradable"] = "Only tradable"--]] 
L["Passenger"] = "Passeggero"
L["PET_ASSIGNMENT_INFO"] = "Puoi assegnare un animale domestico a questa cavalcatura. Verrà evocato anche lui quando salirai in sella.|n|nTutti gli incarichi sono condivisi con tutti i tuoi personaggi.|n|nPuoi usare il tasto destro del mouse sulla voce di un animale domestico per evocarlo manualmente.|n|nTieni presente che la maggior parte degli animali domestici terrestri non volerà con te e scomparirà quando decollerai. Inoltre, gli animali domestici volanti sono solitamente più lenti di te. Quindi potrebbero aver bisogno di un po' di tempo per raggiungerti.|n|nL'evocazione automatica degli animali domestici è attiva solo nei contenuti del mondo."
L["PET_ASSIGNMENT_NONE"] = "Nessun animale domestico"
L["PET_ASSIGNMENT_TITLE"] = "Assegna l'animale domestico alla cavalcatura"
L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "Animale domestico attualmente assegnato:"
L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55fFai clic con il tasto sinistro|r per aprire l'assegnazione dell'animale domestico."
L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55fFai clic con il tasto destro|r per assegnare l'animale domestico attivo alla cavalcatura."
L["Reset filters"] = "Reimposta i filtri"
--[[Translation missing --]]
--[[ L["ROTATE_DOWN"] = "Rotate Down"--]] 
--[[Translation missing --]]
--[[ L["ROTATE_UP"] = "Rotate Up"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_FAMILY"] = "Family"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_LAST_USAGE"] = "Last usage"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_LEARNED_DATE"] = "Date of receipt"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_TRAVEL_DISTANCE"] = "Travelled distance"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_TRAVEL_DURATION"] = "Travelled duration"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_USAGE_COUNT"] = "Count of usage"--]] 
--[[Translation missing --]]
--[[ L["SORT_FAVORITES_FIRST"] = "Favorites First"--]] 
--[[Translation missing --]]
--[[ L["SORT_REVERSE"] = "Reverse Sort"--]] 
--[[Translation missing --]]
--[[ L["SORT_UNOWNED_BOTTOM"] = "Unowned at Bottom"--]] 
--[[Translation missing --]]
--[[ L["SORT_UNUSABLE_BOTTOM"] = "Unusable after Usable"--]] 
--[[Translation missing --]]
--[[ L["SPECIAL_TIP"] = "Starts the special animation of your mount in game."--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "Count of collected customization options"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_LEARNED_DATE_HEAD"] = "Possession date"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_RARITY_DESCRIPTION"] = "% of characters who own this mount"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_RARITY_HEAD"] = "Rarity"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "Travel distance"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_TIME_DAYS"] = "in days"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_TIME_HEAD"] = "Travel time"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_TIME_TEXT"] = "in hours:minutes:seconds"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_USAGE_COUNT_HEAD"] = "Usage count"--]] 
--[[Translation missing --]]
--[[ L["SYNC_TARGET_TIP_FLAVOR"] = "Get ready for a mount off!"--]] 
L["SYNC_TARGET_TIP_TEXT"] = "Seleziona automaticamente la cavalcatura del tuo bersaglio attuale."
L["SYNC_TARGET_TIP_TITLE"] = "Sincronizza il diario con la destinazione"
--[[Translation missing --]]
--[[ L["TOGGLE_COLOR"] = "Show next color variation"--]] 
L["Transform"] = "Trasformare"

    -- Settings
L["DISPLAY_ALL_SETTINGS"] = "Visualizza tutte le impostazioni"
--[[Translation missing --]]
--[[ L[ [=[RESET_WINDOW_SIZE
]=] ] = "Reset journal size"--]] 
--[[Translation missing --]]
--[[ L["SETTING_ABOUT_AUTHOR"] = "Author"--]] 
--[[Translation missing --]]
--[[ L["SETTING_ACHIEVEMENT_POINTS"] = "Show achievement points"--]] 
--[[Translation missing --]]
--[[ L["SETTING_COLOR_NAMES"] = "Colorize names in list based on rarity"--]] 
--[[Translation missing --]]
--[[ L["SETTING_COMPACT_LIST"] = "Compact mount list"--]] 
--[[Translation missing --]]
--[[ L["SETTING_CURSOR_KEYS"] = "Enable Up&Down keys to browse mounts"--]] 
--[[Translation missing --]]
--[[ L["SETTING_DISPLAY_BACKGROUND"] = "Change background color in display"--]] 
--[[Translation missing --]]
--[[ L["SETTING_HEAD_ABOUT"] = "About"--]] 
--[[Translation missing --]]
--[[ L["SETTING_HEAD_BEHAVIOUR"] = "Behavior"--]] 
--[[Translation missing --]]
--[[ L["SETTING_MOUNT_COUNT"] = "Show personal mount count"--]] 
--[[Translation missing --]]
--[[ L["SETTING_MOUNTSPECIAL_BUTTON"] = "Show /mountspecial button"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PERSONAL_FILTER"] = "Apply filters only to this character"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "Apply hidden mounts only to this character"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PERSONAL_UI"] = "Apply Interface settings only to this character"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PREVIEW_LINK"] = "Show Collection button in mount preview"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SEARCH_FAMILY_NAME"] = "Search also by family name"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SEARCH_MORE"] = "Search also in description text"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SEARCH_NOTES"] = "Search also in own notes"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_DATA"] = "Show mount data in display"--]] 
L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "Mostra i profili dei filtri nel menu dei filtri."
--[[Translation missing --]]
--[[ L["SETTING_SHOW_RESIZE_EDGE"] = "Activate edge in bottom corner to resize window"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "Show toolbar buttons"--]] 
L["SETTING_SUMMONPREVIOUSPET"] = "Evoca nuovamente l'animale domestico attivo precedente quando scendi."
--[[Translation missing --]]
--[[ L["SETTING_TRACK_USAGE"] = "Track mount usage behavior on all characters"--]] 
--[[Translation missing --]]
--[[ L["SETTING_YCAMERA"] = "Unlock Y rotation with mouse in display"--]] 

    -- Families
L["Airplanes"] = "Aerei"
L["Airships"] = "Dirigibili"
L["Albatross"] = "Albatros"
L["Alpacas"] = "Alpacas"
L["Amphibian"] = "Anfibia"
L["Animite"] = "Acaro dell'Animum"
L["Aqir Flyers"] = "Aqir Volantini"
L["Arachnids"] = "Aracnidi"
L["Armoredon"] = "Coraceronte"
L["Basilisks"] = "Basilischi"
L["Bats"] = "Pipistrelli"
L["Bears"] = "Orso"
L["Beetle"] = "Scarabeo"
L["Bipedal Cat"] = "Sognartigli"
L["Birds"] = "Uccelli"
L["Boars"] = "Cinghiali"
L["Bovids"] = "Bovidi"
L["Broom"] = "Scopa"
L["Brutosaurs"] = "Brutosauro"
L["Camels"] = "Cammelli"
L["Carnivorans"] = "Carnivori"
L["Carpets"] = "Tappeti"
--[[Translation missing --]]
--[[ L["Carrion"] = "Carrion"--]] 
L["Cats"] = "Gattini"
L["Cervid"] = "Cervide"
L["Chargers"] = "Destriero"
L["Chickens"] = "Polli"
L["Clefthooves"] = "Mammuceronte"
L["Cloud Serpents"] = "Serpenti delle nuvole"
L["Core Hounds"] = "Segugi del nucleo"
L["Crabs"] = "Granchi"
L["Cranes"] = "Gru"
L["Crawgs"] = "Crawgs"
L["Crocolisks"] = "Crocolisco"
L["Crows"] = "Corvi"
L["Demonic Hounds"] = "Segugi demoniaci"
L["Demonic Steeds"] = "Destrieri demoniaci"
L["Demons"] = "Demoni"
L["Devourer"] = "Divoratore"
L["Dinosaurs"] = "Dinosauri"
--[[Translation missing --]]
--[[ L["Dire Wolves"] = "Dire Wolves"--]] 
L["Direhorns"] = "Cornofurente"
L["Discs"] = "Disco"
L["Dragonhawks"] = "Dragofalco"
L["Drakes"] = "Draghi"
L["Dreamsaber"] = "Fieronirica"
L["Eagle"] = "Aquila"
L["Elekks"] = "Elekk"
L["Elementals"] = "Elemental"
L["Falcosaurs"] = "Falcosauro"
L["Fathom Rays"] = "Manta delle Profondità"
L["Feathermanes"] = "Piumanto"
L["Felbat"] = "Vilpipistrello"
L["Felsabers"] = "Vilfiera"
L["Fish"] = "Pescare"
L["Flies"] = "Volare"
--[[Translation missing --]]
--[[ L["Flying Steeds"] = "Flying Steeds"--]] 
L["Foxes"] = "Volpi"
L["Gargon"] = "Gargon"
L["Gargoyle"] = "Gargoyle"
L["Goats"] = "Capre"
L["Gorger"] = "Divoratore"
L["Gorm"] = "Gorm"
--[[Translation missing --]]
--[[ L["Grand Drakes"] = "Grand Drakes"--]] 
L["Gronnlings"] = "Protogronn"
L["Gryphons"] = "Grifoni"
L["Gyrocopters"] = "Girocottero"
L["Hands"] = "Mani"
--[[Translation missing --]]
--[[ L["Harrower"] = "Harrower"--]] 
L["Hawkstriders"] = "Zampalesta"
L["Hedgehog"] = "Riccio"
L["Hippogryphs"] = "Ippogrifi"
--[[Translation missing --]]
--[[ L["Horned Steeds"] = "Horned Steeds"--]] 
L["Horses"] = "Cavalle"
L["Hounds"] = "Segugi"
L["Hover Board"] = "Hoverboard"
L["Humanoids"] = "Umanoidi"
L["Hyenas"] = "Lene"
L["Infernals"] = "Infernali"
L["Insects"] = "Insetti"
L["Jellyfish"] = "Medusa"
--[[Translation missing --]]
--[[ L["Jet Aerial Units"] = "Jet Aerial Units"--]] 
L["Kites"] = "Aquiloni"
L["Kodos"] = "Kodo"
L["Krolusks"] = "Krolusk"
L["Larion"] = "Larion"
L["Lions"] = "Leoni"
L["Lupine"] = "Lupino"
L["Lynx"] = "Lince"
L["Mammoths"] = "Mammut"
L["Mana Rays"] = "Manta del Mana"
L["Mana Wyrm"] = "Dragone di Mana"
L["Manasabers"] = "Manafiera"
L["Mauler"] = "Mazzuolatore"
L["Mechanical Animals"] = "Animali meccanici"
L["Mechanical Birds"] = "Uccelli meccanici"
L["Mechanical Cats"] = "Gatti meccanici"
L["Mechanical Steeds"] = "Destrieri meccanici"
L["Mechanostriders"] = "Tecnostruzzo"
--[[Translation missing --]]
--[[ L["Mecha-suits"] = "Mecha-suits"--]] 
L["Meeksi"] = "Meeksi"
L["Mite"] = "Acaro"
L["Mole"] = "Talpa"
L["Mollusc"] = "Molluschi"
L["Moose"] = "Alce"
L["Moth"] = "Falena"
L["Motorcycles"] = "Motociclette"
L["Mountain Horses"] = "Cavalli di montagna"
L["Murloc"] = "Murloc"
L["Mushan"] = "Mushan"
L["Nether Drakes"] = "Draco Fatuo"
L["Nether Rays"] = "Manta Fatua"
--[[Translation missing --]]
--[[ L["N'Zoth Serpents"] = "N'Zoth Serpents"--]] 
L["Others"] = "Altri"
L["Ottuk"] = "Lontruk"
L["Owl"] = "Gufo"
L["Owlbear"] = "dell'Orsogufo"
L["Ox"] = "Bue"
--[[Translation missing --]]
--[[ L["Pandaren Phoenixes"] = "Pandaren Phoenixes"--]] 
L["Pangolin"] = "Armadillo"
L["Parrots"] = "Pappagalli"
L["Peafowl"] = "Pavone"
--[[Translation missing --]]
--[[ L["Petalwing"] = "Petalwing"--]] 
--[[Translation missing --]]
--[[ L["Phoenixes"] = "Phoenixes"--]] 
--[[Translation missing --]]
--[[ L["Plant"] = "Plant"--]] 
L["Proto-Drakes"] = "Proto-Draco"
L["Pterrordaxes"] = "Pterrordattilo"
L["Quilen"] = "Quilen"
L["Rabbit"] = "Coniglio"
L["Rams"] = "Arieti"
--[[Translation missing --]]
--[[ L["Raptora"] = "Raptora"--]] 
L["Raptors"] = "Rapaci"
L["Rats"] = "Ratti"
L["Raven"] = "Corvo"
L["Rays"] = "Pastinaca"
L["Razorwing"] = "Alafina"
L["Reptiles"] = "Rettili"
L["Rhinos"] = "Rinoceronti"
L["Riverbeasts"] = "Bestia dei Fiumi"
--[[Translation missing --]]
--[[ L["Roc"] = "Roc"--]] 
L["Rockets"] = "Razzi"
L["Rodent"] = " Roditore"
L["Ruinstriders"] = "Calcarovina"
L["Rylaks"] = "Rylak"
L["Sabers"] = "Denti a sciabola"
L["Scorpions"] = "Scorpioni"
L["Sea Serpents"] = "Serpe di Mare"
L["Seahorses"] = "Cavallucci marini"
L["Shalewing"] = "Alaroccia"
L["Shardhides"] = "Pellescheggia"
L["Silithids"] = "Silitide"
L["Skyrazor"] = "Sferzacieli"
L["Slateback"] = "Scistodorso"
L["Slug"] = "Una lumaca senza guscio"
L["Snail"] = "Lumaca"
L["Snapdragons"] = "Drago Carnivoro"
L["Spider Tanks"] = "Carroragno"
L["Spiders"] = "Ragni"
L["Sporebat"] = "Sporofago"
L["Stag"] = "Cervo"
--[[Translation missing --]]
--[[ L["Steeds"] = "Steeds"--]] 
L["Stingrays"] = "Razze"
L["Stone Cats"] = "Gatto di pietra"
L["Stone Drakes"] = "Draco di Pietra"
L["Talbuks"] = "Talbuk"
L["Tallstriders"] = "Zampalunga"
--[[Translation missing --]]
--[[ L["Talonbirds"] = "Talonbirds"--]] 
L["Tauralus"] = "Tauralus"
L["Thunder Lizard"] = "Sauro del Tuono"
L["Tigers"] = "Tigri"
L["Toads"] = "Rospi"
L["Turkey"] = "Tacchino"
L["Turtles"] = "Tartarughe"
--[[Translation missing --]]
--[[ L["Undead Drakes"] = "Undead Drakes"--]] 
--[[Translation missing --]]
--[[ L["Undead Steeds"] = "Undead Steeds"--]] 
--[[Translation missing --]]
--[[ L["Undead Wolves"] = "Undead Wolves"--]] 
L["Ungulates"] = "Ungulati"
L["Ur'zul"] = "Ur'zul"
L["Vehicles"] = "Veicoli"
L["Void Creeper"] = "Strisciante del Vuoto"
L["Void Flyer"] = "Volatile del Vuoto"
L["Vombata"] = "Vombatide"
L["Vulpin"] = "Volpino"
L["Vultures"] = "Avvoltoi"
--[[Translation missing --]]
--[[ L["War Wolves"] = "War Wolves"--]] 
L["Wasp"] = "Vespa"
L["Water Striders"] = "Gerride"
L["Wilderlings"] = "Selvante"
L["Wind Drakes"] = " Draco del Vento"
L["Wolfhawks"] = "Falcolupo"
L["Wolves"] = "Lupi"
L["Worm"] = "Verme"
L["Wyverns"] = "Viverne"
L["Yaks"] = "Yak"
L["Yetis"] = "Yeti"


elseif locale == "koKR" then
    L["ANIMATION_FLY"] = "파리"
L["ANIMATION_FLY_IDLE"] = "제자리에서 비행하다"
L["ANIMATION_RUN"] = "달리다"
L["ANIMATION_STAND"] = "서다"
L["ANIMATION_WALK"] = "가다"
L["ANIMATION_WALK_BACK"] = "뒤로 물러나다"
L["ASK_FAVORITE_PROFILE_NAME"] = "프로필 이름을 입력하세요:"
L["AUTO_ROTATE"] = "자동으로 회전"
L["Black Market"] = "암시장"
L["CLICK_TO_SHOW_LINK"] = "링크를 표시하려면 클릭하세요"
L["COMPARTMENT_TOOLTIP"] = "|cffeda55f마운트 컬렉션을 표시하려면 왼쪽 클릭|r을 누르세요. |cffeda55f마우스 오른쪽 클릭|r을 눌러 애드온 옵션을 여세요."
L["CONFIRM_FAVORITE_PROFILE_DELETION"] = "\"%s\" 프로필을 삭제하시겠습니까? 현재 모든 캐릭터 할당이 기본 프로필 \"%s\"로 재설정됩니다."
L["DRESSUP_LABEL"] = "도감"
L["EVENT_PLUNDERSTORM"] = "약탈폭풍"
L["EVENT_SCARAB"] = "스카라베의 부름"
L["EVENT_SECRETS"] = "아제로스의 비밀"
L["Family"] = "종류"
L["FAVOR_AUTO"] = "새로운 마운트를 자동으로 추가합니다"
L["FAVOR_DISPLAYED"] = "모두 표시"
L["FAVORITE_ACCOUNT_PROFILE"] = "계정"
L["FAVORITE_PROFILE"] = "윤곽"
L["FILTER_ONLY"] = "오직"
L["FILTER_ONLY_LATEST"] = "최신 추가 사항만"
L["FILTER_PROFILE"] = "프로필"
L["FILTER_PROFILE_TOOLTIP_TEXT"] = "미리 정의된 필터와 검색 설정을 빠르게 불러옵니다.|n|cffeda55f필터 프로필을 불러오려면 왼쪽 클릭|r을 클릭하세요.|n|cffeda55f필터 프로필을 저장하려면 오른쪽 클릭|r을 클릭하세요."
L["FILTER_PROFILE_TOOLTIP_TITLE"] = "필터 프로필."
L["FILTER_RETIRED"] = "더 이상 사용할 수 없습니다"
L["FILTER_SECRET"] = "게임에 의해 숨겨짐"
L["Hidden"] = "숨김"
L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "|cffeda55f마운트 컬렉션을 열려면 왼쪽 클릭|r을 클릭하세요."
L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "|cffeda55f마우스 오른쪽 버튼을 클릭|r하여 다른 즐겨찾는 프로필을 선택하세요."
L["LDB_TIP_NO_FAVORITES_TITLE"] = "아직 즐겨찾기에 등록한 마운트가 없습니다."
L["LINK_WOWHEAD"] = "링크로 Wowhead"
L["Mite"] = "매우 조그만 것"
L["Only tradable"] = "교환가능"
L["Passenger"] = "승객"
L["PET_ASSIGNMENT_INFO"] = "이 탈것에 애완동물을 배정할 수 있습니다. 탑승 시 애완동물도 소환됩니다.|n|n모든 배정은 모든 캐릭터와 공유됩니다.|n|n펫 항목을 마우스 오른쪽 버튼으로 클릭하여 수동으로 소환할 수 있습니다.|n|n대부분의 지상 애완동물은 플레이어와 함께 날지 않고, 플레이어가 이륙하면 사라집니다. 또한, 비행 애완동물은 일반적으로 플레이어보다 느리기 때문에 플레이어를 따라잡는 데 시간이 걸릴 수 있습니다.|n|n펫 자동 소환은 월드 콘텐츠에서만 활성화됩니다."
L["PET_ASSIGNMENT_NONE"] = "애완동물이 없는"
L["PET_ASSIGNMENT_TITLE"] = "애완동물을 마운트에 할당하세요"
L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "현재 배정된 반려동물:"
L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55f반려동물 과제를 열려면 왼쪽 클릭|r을 클릭하세요."
L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55f마우스 오른쪽 버튼 클릭|r을 눌러 활성화된 애완동물을 탈것에 할당하세요."
L["Reset filters"] = "필터 초기화"
L["ROTATE_DOWN"] = "아래로 회전"
L["ROTATE_UP"] = "위로 회전"
L["SORT_BY_FAMILY"] = "종류"
L["SORT_BY_LAST_USAGE"] = "마지막 사용"
L["SORT_BY_LEARNED_DATE"] = "수령일"
L["SORT_BY_TRAVEL_DISTANCE"] = "이동 거리"
L["SORT_BY_TRAVEL_DURATION"] = "이동 시간"
L["SORT_BY_USAGE_COUNT"] = "사용 횟수"
L["SORT_FAVORITES_FIRST"] = "즐겨찾기 먼저"
L["SORT_REVERSE"] = "역순 정렬"
L["SORT_UNOWNED_BOTTOM"] = "아래에서 수신되지 않음"
L["SORT_UNUSABLE_BOTTOM"] = "사용 가능 후 사용 불가능"
L["SPECIAL_TIP"] = "게임에서 탈것의 특별 애니메이션을 시작합니다."
L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "수집된 사용자 정의 옵션 수"
L["STATS_TIP_LEARNED_DATE_HEAD"] = "보유일"
L["STATS_TIP_RARITY_DESCRIPTION"] = "이 마운트를 소유한 캐릭터의 %"
L["STATS_TIP_RARITY_HEAD"] = "품질"
L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "이동 거리"
L["STATS_TIP_TRAVEL_TIME_DAYS"] = "일 단위로 "
L["STATS_TIP_TRAVEL_TIME_HEAD"] = "이동 시간"
L["STATS_TIP_TRAVEL_TIME_TEXT"] = "시간:분:초"
L["STATS_TIP_USAGE_COUNT_HEAD"] = "사용 횟수"
L["SYNC_TARGET_TIP_FLAVOR"] = "여러분의 마운트를 자랑할 준비를 하세요!"
L["SYNC_TARGET_TIP_TEXT"] = "현재 대상의 마운트를 자동으로 선택합니다."
L["SYNC_TARGET_TIP_TITLE"] = "대상과 저널 동기화"
L["TOGGLE_COLOR"] = "다음 색상 변형 표시"
L["Transform"] = "변환"

    -- Settings
L["DISPLAY_ALL_SETTINGS"] = "모든 설정 표시"
L[ [=[RESET_WINDOW_SIZE
]=] ] = "저널 크기 재설정"
L["SETTING_ABOUT_AUTHOR"] = "작가"
L["SETTING_ACHIEVEMENT_POINTS"] = "업적 점수 표시"
L["SETTING_COLOR_NAMES"] = "희귀도에 따라 목록의 이름에 색상 지정"
L["SETTING_COMPACT_LIST"] = "간소한 목록"
L["SETTING_CURSOR_KEYS"] = "위 아래 화살표 키로 목록 탐색하기"
L["SETTING_DISPLAY_BACKGROUND"] = "디스플레이의 배경색 변경"
L["SETTING_HEAD_ABOUT"] = "정보"
L["SETTING_HEAD_BEHAVIOUR"] = "행동"
L["SETTING_MOUNT_COUNT"] = "개인 탈것 수 표시"
L["SETTING_MOUNTSPECIAL_BUTTON"] = "/mountspecial 버튼 표시"
L["SETTING_PERSONAL_FILTER"] = "이 캐릭터에만 필터 적용"
L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "숨겨진 마운트를 이 캐릭터에만 적용합니다."
L["SETTING_PERSONAL_UI"] = "이 캐릭터에게만 인터페이스 설정 적용"
L["SETTING_PREVIEW_LINK"] = "탈것 미리보기에 수집품 버튼 표시"
L["SETTING_SEARCH_FAMILY_NAME"] = "가족으로도 검색하세요"
L["SETTING_SEARCH_MORE"] = "설명 텍스트에서도 검색"
L["SETTING_SEARCH_NOTES"] = "자신의 노트에서도 검색"
L["SETTING_SHOW_DATA"] = "디스플레이에 마운트 데이터 표시"
L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "필터 메뉴에서 필터 프로필을 표시합니다."
L["SETTING_SHOW_RESIZE_EDGE"] = "창 크기를 조정하려면 하단 모서리의 가장자리를 활성화하세요."
L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "툴바 버튼 표시"
L["SETTING_SUMMONPREVIOUSPET"] = "내릴 때 이전에 활성화되어 있던 애완동물을 다시 소환합니다."
L["SETTING_TRACK_USAGE"] = "모든 캐릭터의 마운트 사용 동작 추적"
L["SETTING_YCAMERA"] = "표시 화면에서 마우스로 Y 축 회전 잠금 해제"

    -- Families
L["Airplanes"] = "비행기"
L["Airships"] = "비행선"
L["Albatross"] = "알바트로스"
L["Alpacas"] = "알파카"
L["Amphibian"] = "양서류"
L["Animite"] = "령진드기"
L["Aqir Flyers"] = "아퀴르 날벌레"
L["Arachnids"] = "거미"
L["Armoredon"] = "장갑무소"
L["Basilisks"] = "바실리스크"
L["Bats"] = "박쥐"
L["Bears"] = "곰"
L["Beetle"] = "딱정벌레"
L["Bipedal Cat"] = "꿈갈퀴"
L["Birds"] = "새"
L["Boars"] = "멧돼지"
L["Bovids"] = "노루"
L["Broom"] = "빗자루"
L["Brutosaurs"] = "브루토사우루스"
L["Camels"] = "낙타"
L["Carnivorans"] = "육식동물"
L["Carpets"] = "카페트"
--[[Translation missing --]]
--[[ L["Carrion"] = "Carrion"--]] 
L["Cats"] = "고양이과"
L["Cervid"] = "원시사슴"
L["Chargers"] = "군마"
L["Chickens"] = "닭"
L["Clefthooves"] = "갈래발굽"
L["Cloud Serpents"] = "운룡"
L["Core Hounds"] = "심장부사냥개"
L["Crabs"] = "게"
L["Cranes"] = "학"
L["Crawgs"] = "크로그"
L["Crocolisks"] = "크로코리스크"
L["Crows"] = "까마귀"
L["Demonic Hounds"] = "지옥사냥개"
L["Demonic Steeds"] = "지옥군마"
L["Demons"] = "악마"
L["Devourer"] = "포식자"
L["Dinosaurs"] = "공룡"
L["Dire Wolves"] = "다이어울프"
L["Direhorns"] = "다이어혼"
L["Discs"] = "원반"
L["Dragonhawks"] = "용매"
L["Drakes"] = "비룡"
L["Dreamsaber"] = "꿈표범"
L["Eagle"] = "독수리"
L["Elekks"] = "엘레크"
L["Elementals"] = "정령"
L["Falcosaurs"] = "팔코사우루스"
L["Fathom Rays"] = "심해 가오리"
L["Feathermanes"] = "뾰족갈기"
L["Felbat"] = "지옥 박쥐"
L["Felsabers"] = "지옥표범"
L["Fish"] = "물고기"
L["Flies"] = "파리"
L["Flying Steeds"] = "비행군마"
L["Foxes"] = "여우"
L["Gargon"] = "가르곤"
L["Gargoyle"] = "가고일"
L["Goats"] = "염소"
L["Gorger"] = "먹보"
L["Gorm"] = "게걸충"
L["Grand Drakes"] = "거대 비룡"
L["Gronnlings"] = "그론링"
L["Gryphons"] = "그리폰"
L["Gyrocopters"] = "자이로콥터"
L["Hands"] = "손"
--[[Translation missing --]]
--[[ L["Harrower"] = "Harrower"--]] 
L["Hawkstriders"] = "매타조"
L["Hedgehog"] = "고슴도치"
L["Hippogryphs"] = "히포그리프"
L["Horned Steeds"] = "뿔 군마"
L["Horses"] = "말"
L["Hounds"] = "사냥개"
L["Hover Board"] = "호버보드"
L["Humanoids"] = "휴머노이드"
L["Hyenas"] = "하이에나"
L["Infernals"] = "지옥불정령"
L["Insects"] = "곤충"
L["Jellyfish"] = "해파리"
L["Jet Aerial Units"] = "제트 비행기"
L["Kites"] = "연"
L["Kodos"] = "코도"
L["Krolusks"] = "크롤러스크"
L["Larion"] = "깃사자"
L["Lions"] = "사자"
L["Lupine"] = "원시늑대"
L["Lynx"] = "스라소니"
L["Mammoths"] = "매머드"
L["Mana Rays"] = "마나 가오리"
L["Mana Wyrm"] = "마나 지룡"
L["Manasabers"] = "마나호랑이"
L["Mauler"] = "싸움꾼"
L["Mechanical Animals"] = "기계형 야수"
L["Mechanical Birds"] = "기계형 새"
L["Mechanical Cats"] = "기계형 고양이"
L["Mechanical Steeds"] = "기계형 군마"
L["Mechanostriders"] = "기계타조"
L["Mecha-suits"] = "메카수트"
L["Meeksi"] = "미크시"
L["Mite"] = "진드기"
L["Mole"] = "두더지"
L["Mollusc"] = "연체동물"
L["Moose"] = "엘크"
L["Moth"] = "나방"
L["Motorcycles"] = "오토바이"
L["Mountain Horses"] = "산악마"
L["Murloc"] = "멀록"
L["Mushan"] = "무샨"
L["Nether Drakes"] = "황천의 비룡"
L["Nether Rays"] = "황천 가오리"
L["N'Zoth Serpents"] = "느조스 뱀"
L["Others"] = "기타"
L["Ottuk"] = "오투크"
L["Owl"] = "올빼미"
L["Owlbear"] = "올빼미곰의"
L["Ox"] = "황소"
L["Pandaren Phoenixes"] = "판다렌 불사조"
L["Pangolin"] = "천산갑"
L["Parrots"] = "앵무새"
L["Peafowl"] = "공작새"
--[[Translation missing --]]
--[[ L["Petalwing"] = "Petalwing"--]] 
L["Phoenixes"] = "불사조"
--[[Translation missing --]]
--[[ L["Plant"] = "Plant"--]] 
L["Proto-Drakes"] = "원시 비룡"
L["Pterrordaxes"] = "테러닥스"
L["Quilen"] = "기렌"
L["Rabbit"] = "토끼"
L["Rams"] = "산양"
L["Raptora"] = "육식조"
L["Raptors"] = "랩터"
L["Rats"] = "쥐"
L["Raven"] = "갈가마귀"
L["Rays"] = "가오리"
L["Razorwing"] = "칼날날개"
L["Reptiles"] = "파충류"
L["Rhinos"] = "코뿔소"
L["Riverbeasts"] = "강물하마"
L["Roc"] = "로크"
L["Rockets"] = "로켓"
L["Rodent"] = "설치류"
L["Ruinstriders"] = "파멸발굽"
L["Rylaks"] = "라일라크"
L["Sabers"] = "표범"
L["Scorpions"] = "전갈"
L["Sea Serpents"] = "바다뱀"
L["Seahorses"] = "해마"
L["Shalewing"] = "혈암날개"
L["Shardhides"] = "파편가죽"
L["Silithids"] = "실리시드"
L["Skyrazor"] = "하늘발톱"
L["Slateback"] = "점판등"
L["Slug"] = "민달팽이"
L["Snail"] = "달팽이"
L["Snapdragons"] = "치악룡"
L["Spider Tanks"] = "거미 전차"
L["Spiders"] = "거미"
L["Sporebat"] = "포자박쥐"
L["Stag"] = "순록"
L["Steeds"] = "군마"
L["Stingrays"] = "독침가오리"
L["Stone Cats"] = "고양이 석상"
L["Stone Drakes"] = "비룡 석상"
L["Talbuks"] = "탈부크"
L["Tallstriders"] = "타조"
L["Talonbirds"] = "탈론 버드"
L["Tauralus"] = "타우랄러스"
L["Thunder Lizard"] = "천둥도마뱀"
L["Tigers"] = "호랑이"
L["Toads"] = "두꺼비"
L["Turkey"] = "칠면조"
L["Turtles"] = "거북이"
L["Undead Drakes"] = "언데드 비룡"
L["Undead Steeds"] = "언데드 군마"
L["Undead Wolves"] = "언데드 늑대"
L["Ungulates"] = "유제류"
L["Ur'zul"] = "우르줄"
L["Vehicles"] = "차량"
L["Void Creeper"] = "공허 살금벌레"
L["Void Flyer"] = "공허 비행수"
L["Vombata"] = "봄바타"
L["Vulpin"] = "여우"
L["Vultures"] = "독수리"
L["War Wolves"] = "전투 늑대"
L["Wasp"] = "말벌"
L["Water Striders"] = "소금쟁이"
L["Wilderlings"] = "야생룡"
L["Wind Drakes"] = "바람 비룡"
L["Wolfhawks"] = "늑대매"
L["Wolves"] = "늑대"
L["Worm"] = "벌레"
L["Wyverns"] = "와이번"
L["Yaks"] = "야크"
L["Yetis"] = "예티"


elseif locale == "ptBR" then
    L["ANIMATION_FLY"] = "Voar"
L["ANIMATION_FLY_IDLE"] = "Voar parado"
L["ANIMATION_RUN"] = "Correr"
L["ANIMATION_STAND"] = "Parado"
L["ANIMATION_WALK"] = "ANIMAÇÂO_DE_CAMINHADA"
L["ANIMATION_WALK_BACK"] = "Andar pra trás"
L["ASK_FAVORITE_PROFILE_NAME"] = "Digite o nome do perfil:"
L["AUTO_ROTATE"] = "Girar automaticamente"
L["Black Market"] = "Mercado Negro"
L["CLICK_TO_SHOW_LINK"] = "Clique para mostrar o link"
L["COMPARTMENT_TOOLTIP"] = "|cffeda55fClique esquerdo|r para alternar a exibição da coleção de montarias. |cffeda55fClique direito|r para abrir opções de addons."
L["CONFIRM_FAVORITE_PROFILE_DELETION"] = "Tem certeza de que deseja excluir o perfil \"%s\"? Todas as atribuições de personagens atuais serão redefinidas para o perfil padrão \"%s\"."
L["DRESSUP_LABEL"] = "Diário"
L["EVENT_PLUNDERSTORM"] = "Plunderstorm"
L["EVENT_SCARAB"] = "Chamado do Escaravelho"
L["EVENT_SECRETS"] = "Segredos de Azeroth"
L["Family"] = "Família"
L["FAVOR_AUTO"] = "Adicionar novas montarias automaticamente"
L["FAVOR_DISPLAYED"] = "Exibir todos"
L["FAVORITE_ACCOUNT_PROFILE"] = "Conta"
L["FAVORITE_PROFILE"] = "Perfil"
L["FILTER_ONLY"] = "só esse"
L["FILTER_ONLY_LATEST"] = "Apenas adições mais recentes"
L["FILTER_PROFILE"] = "Perfis"
L["FILTER_PROFILE_TOOLTIP_TEXT"] = "Carregue rapidamente seu filtro predefinido e configurações de pesquisa.|n|cffeda55fClique com o botão esquerdo|r para carregar o perfil do filtro.|n|cffeda55fClique com o botão direito|r para salvar o perfil do filtro."
L["FILTER_PROFILE_TOOLTIP_TITLE"] = "Perfis de filtro"
L["FILTER_RETIRED"] = "Indisponível"
L["FILTER_SECRET"] = "Oculto pelo jogo"
L["Hidden"] = "Oculto"
L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "|cffeda55fClique Esq.|r para abrir a Coleção de Montarias."
L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "|cffeda55fClique Direito|r para selecionar um Perfil Favorito diferente."
L["LDB_TIP_NO_FAVORITES_TITLE"] = "Você ainda não selecionou nenhuma montaria como favorita."
L["LINK_WOWHEAD"] = "Link pro Wowhead"
L["Mite"] = "Ácaros"
L["Only tradable"] = "Apenas negociável"
L["Passenger"] = "Passageiro"
L["PET_ASSIGNMENT_INFO"] = "Você pode atribuir um mascote à esta montaria. Ele também será invocado quando você montar.|n|nTodas as atribuições são compartilhadas com todos os seus personagens.|n|nVocê pode clicar com o botão direito do mouse em um mascote para invocá-lo manualmente.|n|nLembre-se de que a maioria dos mascotes terrestres não voam com você e simplesmente desaparecem quando você voar. Além disso, mascotes voadores geralmente são mais lentos que você. Portanto, eles podem precisar de um tempo para alcançá-lo.|n|nA invocação automática de mascotes só está ativa em conteúdo no mundo."
L["PET_ASSIGNMENT_NONE"] = "Nenhum Mascote"
L["PET_ASSIGNMENT_TITLE"] = "Atribuir mascote à montaria"
L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "Mascote atualmente atribuído:"
L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55fClique Esq.|r para abrir a atribuição de mascotes."
L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55fClique Direito|r para atribuir o mascote ativo à montaria."
L["Reset filters"] = "Resetar filtros "
L["ROTATE_DOWN"] = "Girar para Baixo"
L["ROTATE_UP"] = "Girar para Cima"
L["SORT_BY_FAMILY"] = "Família"
L["SORT_BY_LAST_USAGE"] = "Último uso"
L["SORT_BY_LEARNED_DATE"] = "Data da recebimento"
L["SORT_BY_TRAVEL_DISTANCE"] = "Distância percorrida"
L["SORT_BY_TRAVEL_DURATION"] = "Duração de viagem"
L["SORT_BY_USAGE_COUNT"] = "Contagem de uso"
L["SORT_FAVORITES_FIRST"] = "Favoritos Primeiro"
L["SORT_REVERSE"] = "Ordem Inversa"
L["SORT_UNOWNED_BOTTOM"] = "Não aprendidos por último"
L["SORT_UNUSABLE_BOTTOM"] = "Inutilizável depois de utilizável"
L["SPECIAL_TIP"] = "Inicia a animação especial da sua montaria no jogo."
L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "Contagem de opções de personalização coletadas"
L["STATS_TIP_LEARNED_DATE_HEAD"] = "Data de obtenção"
L["STATS_TIP_RARITY_DESCRIPTION"] = "% de personagens que possuem essa montaria"
L["STATS_TIP_RARITY_HEAD"] = "Raridade"
L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "Distância percorrida"
L["STATS_TIP_TRAVEL_TIME_DAYS"] = "em dias"
L["STATS_TIP_TRAVEL_TIME_HEAD"] = "Tempo percorrido"
L["STATS_TIP_TRAVEL_TIME_TEXT"] = "em horas:minutos:segundos"
L["STATS_TIP_USAGE_COUNT_HEAD"] = "Contagem de uso"
L["SYNC_TARGET_TIP_FLAVOR"] = "É hora do duelo de montarias!"
L["SYNC_TARGET_TIP_TEXT"] = "Selecionar automaticamente a mesma montaria do seu alvo atual."
L["SYNC_TARGET_TIP_TITLE"] = "Sincronizar diário com o alvo"
L["TOGGLE_COLOR"] = "Mostrar próxima variação de cor"
L["Transform"] = "Transformar"

    -- Settings
L["DISPLAY_ALL_SETTINGS"] = "Exibir todas as configurações"
L[ [=[RESET_WINDOW_SIZE
]=] ] = "Redefinir tamanho do diário"
L["SETTING_ABOUT_AUTHOR"] = "Autor"
L["SETTING_ACHIEVEMENT_POINTS"] = "Mostrar Pontos de Conquista"
L["SETTING_COLOR_NAMES"] = "Colorir nomes na lista com base na raridade"
L["SETTING_COMPACT_LIST"] = "Lista de Montarias Compacta"
L["SETTING_CURSOR_KEYS"] = "Ativar as teclas para cima e para baixo para navegar pelas montarias"
L["SETTING_DISPLAY_BACKGROUND"] = "Mudar a cor de fundo em exibição"
L["SETTING_HEAD_ABOUT"] = "Sobre"
L["SETTING_HEAD_BEHAVIOUR"] = "Comportamento"
L["SETTING_MOUNT_COUNT"] = "Mostrar contagem de montaria pessoal"
L["SETTING_MOUNTSPECIAL_BUTTON"] = "Mostrar botão de /mountspecial"
L["SETTING_PERSONAL_FILTER"] = "Aplicar filtros apenas para este personagem"
L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "Aplicar montarias ocultas apenas para este personagem"
L["SETTING_PERSONAL_UI"] = "Aplicar configurações de inferface apenas para este personagem"
L["SETTING_PREVIEW_LINK"] = "Mostrar Botão de Coleção na pré-visualização de montaria"
L["SETTING_SEARCH_FAMILY_NAME"] = "Pesquisar também por família"
L["SETTING_SEARCH_MORE"] = "Pesquisar também no texto de descrição"
L["SETTING_SEARCH_NOTES"] = "Pesquisar também nas próprias notas"
L["SETTING_SHOW_DATA"] = "Exibir dados da montaria"
L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = [=[Mostrar perfis de filtro no menu de filtros.
]=]
L["SETTING_SHOW_RESIZE_EDGE"] = "Ativar a borda no canto inferior para redimensionar a janela"
L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "Exibir botões da barra de ferramentas"
L["SETTING_SUMMONPREVIOUSPET"] = "Invoca o mascote ativo anterior novamente ao desmontar."
L["SETTING_TRACK_USAGE"] = "Rastreie o comportamento de uso da montaria em todos os personagens"
L["SETTING_YCAMERA"] = "Desbloquear rotação vertical com o mouse na tela"

    -- Families
L["Airplanes"] = "Aviões"
L["Airships"] = "Dirigíveis"
L["Albatross"] = "Albatroz"
L["Alpacas"] = "Alpacas"
L["Amphibian"] = "Anfíbios"
L["Animite"] = "Animácaros"
L["Aqir Flyers"] = "Aqir Voadores "
L["Arachnids"] = "Aracnídeos"
L["Armoredon"] = "Armadurados"
L["Basilisks"] = "Basiliscos"
L["Bats"] = "Morcegos"
L["Bears"] = "Ursos"
L["Beetle"] = "Besouros"
L["Bipedal Cat"] = "Gatos Bípedes"
L["Birds"] = "Aves"
L["Boars"] = "Javalis"
L["Bovids"] = "Bovídeos"
L["Broom"] = "Vassouras"
L["Brutosaurs"] = "Brutossauros"
L["Camels"] = "Camelos"
L["Carnivorans"] = "Carnívoros"
L["Carpets"] = "Tapetes"
--[[Translation missing --]]
--[[ L["Carrion"] = "Carrion"--]] 
L["Cats"] = "Gatos"
L["Cervid"] = "Cervídeos"
L["Chargers"] = "Corcéis"
L["Chickens"] = "Galinhas"
L["Clefthooves"] = "Fenocerontes"
L["Cloud Serpents"] = "Serpentes das Nuvens"
L["Core Hounds"] = "Cães-Magma"
L["Crabs"] = "Caranguejos"
L["Cranes"] = "Garças"
L["Crawgs"] = "Crorgs"
L["Crocolisks"] = "Crocoliscos"
L["Crows"] = "Corvos"
L["Demonic Hounds"] = "Cães Demoníacos"
L["Demonic Steeds"] = "Corcéis Demoníacos"
L["Demons"] = "Demônios"
L["Devourer"] = "Devoradores"
L["Dinosaurs"] = "Dinossauros"
L["Dire Wolves"] = "Lobos Hediondos"
L["Direhorns"] = "Escornantes"
L["Discs"] = "Discos"
L["Dragonhawks"] = "Falcodragos"
L["Drakes"] = "Dracos"
L["Dreamsaber"] = "Sabres-do-sonho"
L["Eagle"] = "Águias"
L["Elekks"] = "Elekks"
L["Elementals"] = "Elementais"
L["Falcosaurs"] = "Falcossauros"
L["Fathom Rays"] = "Raias-Profundas"
L["Feathermanes"] = "Aquifélix"
L["Felbat"] = "Morcevil"
L["Felsabers"] = "Sabrevis"
L["Fish"] = "Peixes"
L["Flies"] = "Moscas"
L["Flying Steeds"] = "Corcéis Voadores"
L["Foxes"] = "Raposas"
L["Gargon"] = "Gargonos"
L["Gargoyle"] = "Gárgulas"
L["Goats"] = "Bodes"
L["Gorger"] = "Engolidores"
L["Gorm"] = "Gorm"
L["Grand Drakes"] = "Dracos Grandes"
L["Gronnlings"] = "Gronnídeos"
L["Gryphons"] = "Grifos"
L["Gyrocopters"] = "Girocópteros"
L["Hands"] = "Mãos"
--[[Translation missing --]]
--[[ L["Harrower"] = "Harrower"--]] 
L["Hawkstriders"] = "Falcostruzes"
L["Hedgehog"] = "Ouriços"
L["Hippogryphs"] = "Hipogrifos"
L["Horned Steeds"] = "Corcéis com Chifres"
L["Horses"] = "Cavalos"
L["Hounds"] = "Cães"
L["Hover Board"] = "Hoverboards"
L["Humanoids"] = "Humanoides"
L["Hyenas"] = "Hienas"
L["Infernals"] = "Infernais"
L["Insects"] = "Insetos"
L["Jellyfish"] = "Águas-vivas"
L["Jet Aerial Units"] = "Unidades Aéreas a Jato"
L["Kites"] = "Pipas"
L["Kodos"] = "Kodos"
L["Krolusks"] = "Croluscos"
L["Larion"] = "Lariões"
L["Lions"] = "Leões"
L["Lupine"] = "Lupinos"
L["Lynx"] = "Linces"
L["Mammoths"] = "Mamutes"
L["Mana Rays"] = "Arraias de Mana"
L["Mana Wyrm"] = "Moreia de Mana"
L["Manasabers"] = "Manassabres"
L["Mauler"] = "Espancadores"
L["Mechanical Animals"] = "Animais Mecânicos"
L["Mechanical Birds"] = "Pássaros Mecânicos"
L["Mechanical Cats"] = "Gatos Mecânicos"
L["Mechanical Steeds"] = "Corcéis Mecânicos"
L["Mechanostriders"] = "Mecanostruzes"
L["Mecha-suits"] = "Mecatrajes"
L["Meeksi"] = "Miksi"
L["Mite"] = "Ácaro"
L["Mole"] = "Toupeiras"
L["Mollusc"] = "Moluscos"
L["Moose"] = "Alces"
L["Moth"] = "Mariposas"
L["Motorcycles"] = "Motocicletas"
L["Mountain Horses"] = "Cavalos da Montanha"
L["Murloc"] = "Murlocs"
L["Mushan"] = "Mushans"
L["Nether Drakes"] = "Dracos Etéreos"
L["Nether Rays"] = "Arraias Etéreas "
L["N'Zoth Serpents"] = "Serpentes de N'Zoth"
L["Others"] = "Outros"
L["Ottuk"] = "Lontruks"
L["Owl"] = "Corujas"
L["Owlbear"] = "Ursos-Coruja"
L["Ox"] = "Bois"
L["Pandaren Phoenixes"] = "Fênix Pandarênicas"
L["Pangolin"] = "Pangolin"
L["Parrots"] = "Papagaios"
L["Peafowl"] = "Pavões"
--[[Translation missing --]]
--[[ L["Petalwing"] = "Petalwing"--]] 
L["Phoenixes"] = "Fênix"
--[[Translation missing --]]
--[[ L["Plant"] = "Plant"--]] 
L["Proto-Drakes"] = "Protodracos"
L["Pterrordaxes"] = "Pterrordaxes"
L["Quilen"] = "Quílen"
L["Rabbit"] = "Coelhos"
L["Rams"] = "Carneiros"
L["Raptora"] = "Raptora"
L["Raptors"] = "Raptores"
L["Rats"] = "Ratos"
L["Raven"] = "Corvos"
L["Rays"] = "Arraias"
L["Razorwing"] = "Talhasas"
L["Reptiles"] = "Répteis"
L["Rhinos"] = "Rinocerontes"
L["Riverbeasts"] = "Feras-do-rio"
L["Roc"] = "Rocas"
L["Rockets"] = "Foguetes"
L["Rodent"] = "Roedores"
L["Ruinstriders"] = "Andarilhos das Ruínas"
L["Rylaks"] = "Rylaks"
L["Sabers"] = "Sabres"
L["Scorpions"] = "Escorpiões"
L["Sea Serpents"] = "Serpentes Marinhas"
L["Seahorses"] = "Cavalos-marinhos"
L["Shalewing"] = "Asesquisto"
L["Shardhides"] = "Couraça-de-cristal"
L["Silithids"] = "Silitídeos"
L["Skyrazor"] = "Cindecéus"
L["Slateback"] = "Costadura"
L["Slug"] = "Lesmas"
L["Snail"] = "Caracóis"
L["Snapdragons"] = "Dracoliscos"
L["Spider Tanks"] = "Tanques Aranha"
L["Spiders"] = "Aranhas"
L["Sporebat"] = "Quirósporos"
L["Stag"] = "Cervos"
L["Steeds"] = "Corcéis"
L["Stingrays"] = "Arraias Aguilhantes"
L["Stone Cats"] = "Gatos de Pedra"
L["Stone Drakes"] = "Dracos de Pedra"
L["Talbuks"] = "Talbulques"
L["Tallstriders"] = "Moas"
L["Talonbirds"] = "Pássaros-garra"
L["Tauralus"] = "Tauralus"
L["Thunder Lizard"] = "Lagartos Trovejantes"
L["Tigers"] = "Tigres"
L["Toads"] = "Sapos"
L["Turkey"] = "Peru"
L["Turtles"] = "Tartarugas"
L["Undead Drakes"] = "Dracos Mortos-vivos"
L["Undead Steeds"] = "Corcéis Mortos-vivos"
L["Undead Wolves"] = "Lobos Mortos-vivos"
L["Ungulates"] = "Ungulados"
L["Ur'zul"] = "Ur'zul"
L["Vehicles"] = "Veículos"
L["Void Creeper"] = "Rastejante do Caos"
L["Void Flyer"] = "Voador do Caos"
L["Vombata"] = "Vombates"
L["Vulpin"] = "Vulpinos"
L["Vultures"] = "Abutres"
L["War Wolves"] = "Lobos de Guerra"
L["Wasp"] = "Vespas"
L["Water Striders"] = "Caminhantes das Águas "
L["Wilderlings"] = "Silvestritos"
L["Wind Drakes"] = "Dracos do Vento"
L["Wolfhawks"] = "Falcolobos"
L["Wolves"] = "Lobos"
L["Worm"] = "Minhocas"
L["Wyverns"] = "Mantícoras"
L["Yaks"] = "Iaques"
L["Yetis"] = "Yetis"


elseif locale == "ruRU" then
    L["ANIMATION_FLY"] = "Полет"
L["ANIMATION_FLY_IDLE"] = "Полет на месте"
L["ANIMATION_RUN"] = "Бег"
L["ANIMATION_STAND"] = "Стойка"
L["ANIMATION_WALK"] = "ANIMATION_WALK"
L["ANIMATION_WALK_BACK"] = "Ходьба назад"
L["ASK_FAVORITE_PROFILE_NAME"] = "Введите имя профиля:"
L["AUTO_ROTATE"] = "Вращать автоматически"
L["Black Market"] = "Черный рынок"
L["CLICK_TO_SHOW_LINK"] = "Нажмите, чтобы показать ссылку"
L["COMPARTMENT_TOOLTIP"] = "|cffeda55fЩелкните левой кнопкой мыши|r чтобы включить отображение коллекции средств передвижения. |cffeda55fЩелкните правой кнопкой мыши|r чтобы открыть опции аддона."
L["CONFIRM_FAVORITE_PROFILE_DELETION"] = "Вы уверены, что хотите удалить профиль «%s»? Все текущие назначения для персонажей будут сброшены по умолчанию «%s»."
L["DRESSUP_LABEL"] = "Журнал"
L["EVENT_PLUNDERSTORM"] = "Пиратская Буря"
L["EVENT_SCARAB"] = "Зов скарабея"
L["EVENT_SECRETS"] = "Тайны Азерота"
L["Family"] = "Семейства"
L["FAVOR_AUTO"] = "Добавлять автоматически новые средства передвижения "
L["FAVOR_DISPLAYED"] = "Показать всех"
L["FAVORITE_ACCOUNT_PROFILE"] = "Аккаунт"
L["FAVORITE_PROFILE"] = "Профиль"
L["FILTER_ONLY"] = "только"
L["FILTER_ONLY_LATEST"] = "Только последний патч"
L["FILTER_PROFILE"] = "Профиль"
L["FILTER_PROFILE_TOOLTIP_TEXT"] = "Быстрая загрузка предопределенных фильтров и настроек поиска.|n|cffeda55fЩелкните левой кнопкой мыши|r, чтобы загрузить профиль фильтра.|n|cffeda55fЩелкните правой кнопкой мыши|r, чтобы сохранить профиль фильтра."
L["FILTER_PROFILE_TOOLTIP_TITLE"] = "Фильтрация Профилей"
L["FILTER_RETIRED"] = "Более не доступно"
L["FILTER_SECRET"] = "Скрытые игрой"
L["Hidden"] = "Скрытые"
L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "Щелкните |cffeda55fлевой кнопкой мыши|r, чтобы открыть коллекцию средств передвижения."
L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "Щелкните |cffeda55fправой кнопкой мыши|r, чтобы выбрать другой профиль избранного."
L["LDB_TIP_NO_FAVORITES_TITLE"] = "Вы пока что не выбрали ни одно средство передвижения в качестве избранного."
L["LINK_WOWHEAD"] = "Ссылка на Wowhead"
L["Mite"] = "Клещи"
L["Only tradable"] = "Только передающиеся"
L["Passenger"] = "Пассажирские"
L["PET_ASSIGNMENT_INFO"] = "Вы можете назначить питомца для этого средства передвижения. Он также будет призван, когда вы призовете средство передвижения.|n|nВсе назначения общие для всех ваших персонажей.|n|nВы можете щёлкнуть правой кнопкой мыши по названию питомца, чтобы призвать его вручную.|n|nОбратите внимание, что большинство наземных питомцев не будут летать вместе с вами и просто исчезнут, когда вы взлетите. Кроме того, летающие питомцы обычно медленнее вас. Поэтому им может потребоваться некоторое время, чтобы догнать вас.|n|nАвтоматический призыв питомцев активен только в мировом контенте."
L["PET_ASSIGNMENT_NONE"] = "Без питомца"
L["PET_ASSIGNMENT_TITLE"] = "Назначить питомца для средства передвижения"
L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "Текущий назначенный питомец:"
L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55fЩелкните левой кнопкой мыши|r, чтобы открыть назначение питомца."
L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55fЩелкните правой кнопкой мыши|r, чтобы назначить активного питомца для средства передвижения."
L["Reset filters"] = "Сбросить фильтры"
L["ROTATE_DOWN"] = "Вращение вниз"
L["ROTATE_UP"] = "Вращение вверх"
L["SORT_BY_FAMILY"] = "Семейство"
L["SORT_BY_LAST_USAGE"] = "Последнее использование"
L["SORT_BY_LEARNED_DATE"] = "Дата получения"
L["SORT_BY_TRAVEL_DISTANCE"] = "Преодоленное расстояние"
L["SORT_BY_TRAVEL_DURATION"] = "Продолжительность поездки"
L["SORT_BY_USAGE_COUNT"] = "Количество использований"
L["SORT_FAVORITES_FIRST"] = "Избранные первыми"
L["SORT_REVERSE"] = "Обратная сортировка"
L["SORT_UNOWNED_BOTTOM"] = "Не полученные в конце списка"
L["SORT_UNUSABLE_BOTTOM"] = "Не используемые после используемых"
L["SPECIAL_TIP"] = "Показать специальную анимацию средства передвижения в игре."
L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "Количество собранных опций кастомизации"
L["STATS_TIP_LEARNED_DATE_HEAD"] = "Дата получения"
L["STATS_TIP_RARITY_DESCRIPTION"] = "% персонажей у которых есть это средство передвижения"
L["STATS_TIP_RARITY_HEAD"] = "Редкость"
L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "Преодоленное расстояние"
L["STATS_TIP_TRAVEL_TIME_DAYS"] = "в днях"
L["STATS_TIP_TRAVEL_TIME_HEAD"] = "Продолжительность поездки"
L["STATS_TIP_TRAVEL_TIME_TEXT"] = "В часах:минутах:секундах"
L["STATS_TIP_USAGE_COUNT_HEAD"] = "Количество использований"
L["SYNC_TARGET_TIP_FLAVOR"] = "Приготовься к демонстрации средств передвижения!"
L["SYNC_TARGET_TIP_TEXT"] = "Автоматически выбирать средство передвижения как у вашей текущей цели."
L["SYNC_TARGET_TIP_TITLE"] = "Синхронизировать журнал с целью"
L["TOGGLE_COLOR"] = "Показать следующую вариацию цвета"
L["Transform"] = "Трансформация"

    -- Settings
L["DISPLAY_ALL_SETTINGS"] = "Показать все настройки"
L[ [=[RESET_WINDOW_SIZE
]=] ] = "Сбросить настройки журнала"
L["SETTING_ABOUT_AUTHOR"] = "Автор"
L["SETTING_ACHIEVEMENT_POINTS"] = "Показать достижения"
L["SETTING_COLOR_NAMES"] = "Окрасить имена в списке в зависимости от редкости"
L["SETTING_COMPACT_LIST"] = "Компактный список транспорта"
L["SETTING_CURSOR_KEYS"] = "Включить Клавиши \"Вверх\" и \"Вниз\" для навигации по списку транспорта"
L["SETTING_DISPLAY_BACKGROUND"] = "Изменить цвет фона окна обзора"
L["SETTING_HEAD_ABOUT"] = "О моде"
L["SETTING_HEAD_BEHAVIOUR"] = "Поведение"
L["SETTING_MOUNT_COUNT"] = "Показать персональный счетчик транспорта"
L["SETTING_MOUNTSPECIAL_BUTTON"] = "Отобразить кнопку \"/mountspecial\" или \"/трюк\""
L["SETTING_PERSONAL_FILTER"] = "Применить фильтры только для этого персонажа"
L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "Применить скрытый транспорт только для этого персонажа"
L["SETTING_PERSONAL_UI"] = "Применить настройки интерфейса только для этого персонажа"
L["SETTING_PREVIEW_LINK"] = "Показать кнопку коллекции на экрана обзора транспорта"
L["SETTING_SEARCH_FAMILY_NAME"] = "Искать так же по названию семейства"
L["SETTING_SEARCH_MORE"] = "Искать также в описании транспорта"
L["SETTING_SEARCH_NOTES"] = "Искать также в собственных заметках"
L["SETTING_SHOW_DATA"] = "Показывать информацию о средстве передвижения на экране"
L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "Показывать фильтрацию профилей в меню фильтров."
L["SETTING_SHOW_RESIZE_EDGE"] = "Активация края в нижнем углу, чтобы изменять размер окна"
L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "Показать кнопки панели инструментов"
L["SETTING_SUMMONPREVIOUSPET"] = "Призывать при спешивании предыдущего активного питомца."
L["SETTING_TRACK_USAGE"] = "Отслеживание использования транспорта для всех персонажей"
L["SETTING_YCAMERA"] = "Разблокировать вертикальное вращение транспорта с помощью мыши"

    -- Families
L["Airplanes"] = "Самолеты"
L["Airships"] = "Воздушные Судна"
L["Albatross"] = "Альбатросы"
L["Alpacas"] = "Альпаки"
L["Amphibian"] = "Амфибии"
L["Animite"] = "Анимаклещи"
L["Aqir Flyers"] = "Акиры Летуны"
L["Arachnids"] = "Арахниды"
L["Armoredon"] = "Бронедоны"
L["Basilisks"] = "Василиски"
L["Bats"] = "Летучие мыши"
L["Bears"] = "Медведи"
L["Beetle"] = "Жуки"
L["Bipedal Cat"] = "Ящеры из Сна"
L["Birds"] = "Птицы"
L["Boars"] = "Кабаны"
L["Bovids"] = "Полорогие"
L["Broom"] = "Метлы"
L["Brutosaurs"] = "Брутозавры"
L["Camels"] = "Верблюды"
L["Carnivorans"] = "Плотоядные"
L["Carpets"] = "Ковры"
--[[Translation missing --]]
--[[ L["Carrion"] = "Carrion"--]] 
L["Cats"] = "Кошки"
L["Cervid"] = "Сервиды"
L["Chargers"] = "Скакуны"
L["Chickens"] = "Курицы"
L["Clefthooves"] = "Копытни"
L["Cloud Serpents"] = "Облачные Змеи"
L["Core Hounds"] = "Гончие Недр"
L["Crabs"] = "Крабы"
L["Cranes"] = "Журавли"
L["Crawgs"] = "Кроги"
L["Crocolisks"] = "Кроколиски"
L["Crows"] = "Вороны"
L["Demonic Hounds"] = "Демонические Гончие"
L["Demonic Steeds"] = "Демонические Скакуны"
L["Demons"] = "Демонические"
L["Devourer"] = "Пожиратели"
L["Dinosaurs"] = "Динозавры"
L["Dire Wolves"] = "Лютоволки"
L["Direhorns"] = "Дикороги"
L["Discs"] = "Диски"
L["Dragonhawks"] = "Дракондоры"
L["Drakes"] = "Драконы"
L["Dreamsaber"] = "Саблезубы из Сна"
L["Eagle"] = "Орлы"
L["Elekks"] = "Элекки"
L["Elementals"] = "Элементали"
L["Falcosaurs"] = "Грифозавры"
L["Fathom Rays"] = "Глубинные Скаты"
L["Feathermanes"] = "Пернатые"
L["Felbat"] = "Сквернотопыри"
L["Felsabers"] = "Саблезубы"
L["Fish"] = "Рыбы"
L["Flies"] = "Мухи"
L["Flying Steeds"] = "Летающие Скакуны"
L["Foxes"] = "Лисы"
L["Gargon"] = "Гаргоны"
L["Gargoyle"] = "Гаргульи"
L["Goats"] = "Козлы"
L["Gorger"] = "Поглотители"
L["Gorm"] = "Гормы"
L["Grand Drakes"] = "Великие Драконы"
L["Gronnlings"] = "Малые гронны"
L["Gryphons"] = "Грифоны"
L["Gyrocopters"] = "Гирокоптеры"
L["Hands"] = "Руки"
--[[Translation missing --]]
--[[ L["Harrower"] = "Harrower"--]] 
L["Hawkstriders"] = "Крылобеги"
L["Hedgehog"] = "Ежики"
L["Hippogryphs"] = "Гиппогрифы"
L["Horned Steeds"] = "Рогатые Скакуны"
L["Horses"] = "Скакуны"
L["Hounds"] = "Гончие"
L["Hover Board"] = "Ховерборды"
L["Humanoids"] = "Гуманоиды"
L["Hyenas"] = "Гиены"
L["Infernals"] = "Инферналы"
L["Insects"] = "Насекомые"
L["Jellyfish"] = "Медузы"
L["Jet Aerial Units"] = "Реактивные Воздушные"
L["Kites"] = "Воздушные Змеи"
L["Kodos"] = "Кодо"
L["Krolusks"] = "Кролуски"
L["Larion"] = "Ларионы"
L["Lions"] = "Львы"
L["Lupine"] = "Люпины"
L["Lynx"] = "Рыси"
L["Mammoths"] = "Мамонты"
L["Mana Rays"] = "Манаскаты"
L["Mana Wyrm"] = "Маназмеи"
L["Manasabers"] = "Манапарды"
L["Mauler"] = "Терзатели"
L["Mechanical Animals"] = "Механические Животные"
L["Mechanical Birds"] = "Механические Птицы"
L["Mechanical Cats"] = "Механические Кошки"
L["Mechanical Steeds"] = "Механические Скакуны"
L["Mechanostriders"] = "Механодолгоноги"
L["Mecha-suits"] = "Мехакостюмы"
L["Meeksi"] = "Микси"
L["Mite"] = "Клещи"
L["Mole"] = "Кроты"
L["Mollusc"] = "Моллюски"
L["Moose"] = "Лоси"
L["Moth"] = "Мотыльки"
L["Motorcycles"] = "Мотоциклы"
L["Mountain Horses"] = "Горные Скакуны"
L["Murloc"] = "Мурлоки"
L["Mushan"] = "Мушаны"
L["Nether Drakes"] = "Драконы Пустоты"
L["Nether Rays"] = "Скаты Пустоты"
L["N'Zoth Serpents"] = "Черви Н'Зота"
L["Others"] = "Прочие"
L["Ottuk"] = "Выдреки"
L["Owl"] = "Совы"
L["Owlbear"] = "Совомедведи"
L["Ox"] = "Волы"
L["Pandaren Phoenixes"] = "Пандаренские Фениксы"
L["Pangolin"] = "Панголины"
L["Parrots"] = "Попугаи"
L["Peafowl"] = "Павлины"
--[[Translation missing --]]
--[[ L["Petalwing"] = "Petalwing"--]] 
L["Phoenixes"] = "Фениксы"
--[[Translation missing --]]
--[[ L["Plant"] = "Plant"--]] 
L["Proto-Drakes"] = "Протодраконы"
L["Pterrordaxes"] = "Терродактили"
L["Quilen"] = "Цийлини"
L["Rabbit"] = "Кролики"
L["Rams"] = "Бараны"
L["Raptora"] = "Рапторы"
L["Raptors"] = "Ящеры"
L["Rats"] = "Крысы"
L["Raven"] = "Вороны"
L["Rays"] = "Скаты"
L["Razorwing"] = "Острокрылы"
L["Reptiles"] = "Рептилии"
L["Rhinos"] = "Носороги"
L["Riverbeasts"] = "Речные чудовища"
L["Roc"] = "Рухи"
L["Rockets"] = "Ракеты"
L["Rodent"] = "Грызуны"
L["Ruinstriders"] = "Скитальцы"
L["Rylaks"] = "Рилаки"
L["Sabers"] = "Саблезубы"
L["Scorpions"] = "Скорпионы"
L["Sea Serpents"] = "Морские Змеи"
L["Seahorses"] = "Морские коньки"
L["Shalewing"] = "Глинокрылы"
L["Shardhides"] = "Сланцевики"
L["Silithids"] = "Силитиды"
L["Skyrazor"] = "Рассекатели небес"
L["Slateback"] = "Сланцеспин"
L["Slug"] = "Слизняки"
L["Snail"] = "Улитки"
L["Snapdragons"] = "Вараны"
L["Spider Tanks"] = "Механопауки"
L["Spiders"] = "Пауки"
L["Sporebat"] = "Спороскат"
L["Stag"] = "Олени"
L["Steeds"] = "Кони"
L["Stingrays"] = "Жалохвосты"
L["Stone Cats"] = "Каменные Кошки"
L["Stone Drakes"] = "Каменные Драконы"
L["Talbuks"] = "Талбуки"
L["Tallstriders"] = "Долгоноги"
L["Talonbirds"] = "Когти"
L["Tauralus"] = "Тауралы"
L["Thunder Lizard"] = "Громоспины"
L["Tigers"] = "Тигры"
L["Toads"] = "Жабы"
L["Turkey"] = "Индюшки"
L["Turtles"] = "Черепахи"
L["Undead Drakes"] = "Драконы Нежить"
L["Undead Steeds"] = "Скакуны Нежить"
L["Undead Wolves"] = "Волки Нежить"
L["Ungulates"] = "Копытные"
L["Ur'zul"] = "Ур'зул"
L["Vehicles"] = "Транспортные средства"
L["Void Creeper"] = "Шаркун Бездны"
L["Void Flyer"] = "Летун Бездны"
L["Vombata"] = "Вомбаты"
L["Vulpin"] = "Лисохвосты"
L["Vultures"] = "Падальщики"
L["War Wolves"] = "Боевые Волки"
L["Wasp"] = "Осы"
L["Water Striders"] = "Водные долгоноги"
L["Wilderlings"] = "Чащобники"
L["Wind Drakes"] = "Драконы Ветра"
L["Wolfhawks"] = "Звероястребы"
L["Wolves"] = "Волки"
L["Worm"] = "Черви"
L["Wyverns"] = "Виверны"
L["Yaks"] = "Яки"
L["Yetis"] = "Йети"


elseif locale == "zhCN" then
    L["ANIMATION_FLY"] = "飞行"
L["ANIMATION_FLY_IDLE"] = "飞行悬停"
L["ANIMATION_RUN"] = "跑"
L["ANIMATION_STAND"] = "站立"
L["ANIMATION_WALK"] = "走"
L["ANIMATION_WALK_BACK"] = "倒退走"
L["ASK_FAVORITE_PROFILE_NAME"] = "输入配置文件名称："
L["AUTO_ROTATE"] = "自动旋转"
L["Black Market"] = "黑市"
L["CLICK_TO_SHOW_LINK"] = "点击显示链接"
L["COMPARTMENT_TOOLTIP"] = "|cffeda55f左键点击|r切换显示坐骑收藏。|cffeda55f右键点击|r打开插件选项。"
L["CONFIRM_FAVORITE_PROFILE_DELETION"] = "确定要删除配置文件“%s”吗？所有当前的角色分配都将重置为默认配置文件“%s”。"
L["DRESSUP_LABEL"] = "日志"
L["EVENT_PLUNDERSTORM"] = "霸业风暴"
L["EVENT_SCARAB"] = "甲虫的召唤"
L["EVENT_SECRETS"] = "艾泽拉斯之秘"
L["Family"] = "系列"
L["FAVOR_AUTO"] = "自动添加新坐骑"
L["FAVOR_DISPLAYED"] = "全部显示"
L["FAVORITE_ACCOUNT_PROFILE"] = "账号"
L["FAVORITE_PROFILE"] = "配置文件"
L["FILTER_ONLY"] = "仅"
L["FILTER_ONLY_LATEST"] = "仅有最新添加的内容"
L["FILTER_PROFILE"] = "配置文件"
L["FILTER_PROFILE_TOOLTIP_TEXT"] = "快速载入预设的筛选与搜索设置。|n|cffeda55f点击|r 载入筛选配置。|n|cffeda55f右击|r 保存筛选配置"
L["FILTER_PROFILE_TOOLTIP_TITLE"] = "过滤配置文件"
L["FILTER_RETIRED"] = "不再可用"
L["FILTER_SECRET"] = "被游戏隐藏的"
L["Hidden"] = "隐藏"
L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "|cffeda55f左键点击|r打开坐骑收藏。"
L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "|cffeda55f右键点击|r选择不同的收藏配置文件。"
L["LDB_TIP_NO_FAVORITES_TITLE"] = "您还未选择任何坐骑作为偏好。"
L["LINK_WOWHEAD"] = "Wowhead 链接"
L["Mite"] = "螨"
L["Only tradable"] = "仅可交易"
L["Passenger"] = "载客"
L["PET_ASSIGNMENT_INFO"] = "你可以为该坐骑分配一只小宠物。它也会随坐骑一起被召唤出来。|n|n所有分配都会与您的所有角色共享。|n|n您可以右键单击宠物条目来手动召唤它。|n|n请注意，大多数地面宠物不会随您飞行，而是在您起飞时消失。此外，飞行宠物的速度通常比您慢。|n|n自动召唤宠物只在世界内容中有效。"
L["PET_ASSIGNMENT_NONE"] = "无小宠物"
L["PET_ASSIGNMENT_TITLE"] = "为坐骑分配宠物"
L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "当前分配的小宠物："
L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55f左键点击|r打开宠物分配。"
L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55f右键点击|r将当前激活宠物分配到坐骑。"
L["Reset filters"] = "重置过滤器"
L["ROTATE_DOWN"] = "向下旋转"
L["ROTATE_UP"] = "向上旋转"
L["SORT_BY_FAMILY"] = "系列"
L["SORT_BY_LAST_USAGE"] = "上次使用"
L["SORT_BY_LEARNED_DATE"] = "获取日期"
L["SORT_BY_TRAVEL_DISTANCE"] = "旅行距离"
L["SORT_BY_TRAVEL_DURATION"] = "旅行时长"
L["SORT_BY_USAGE_COUNT"] = "使用次数"
L["SORT_FAVORITES_FIRST"] = "偏好优先"
L["SORT_REVERSE"] = "反向排序"
L["SORT_UNOWNED_BOTTOM"] = "未收集在底部"
L["SORT_UNUSABLE_BOTTOM"] = "不可用在可用之后"
L["SPECIAL_TIP"] = "播放坐骑的特殊动画。"
L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "已收集的自定义选项数量"
L["STATS_TIP_LEARNED_DATE_HEAD"] = "拥有日期"
L["STATS_TIP_RARITY_DESCRIPTION"] = "拥有该坐骑的角色百分比"
L["STATS_TIP_RARITY_HEAD"] = "稀有度"
L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "旅行距离"
L["STATS_TIP_TRAVEL_TIME_DAYS"] = "以天计"
L["STATS_TIP_TRAVEL_TIME_HEAD"] = "旅行时间"
L["STATS_TIP_TRAVEL_TIME_TEXT"] = "以 时:分:秒 显示"
L["STATS_TIP_USAGE_COUNT_HEAD"] = "使用次数"
L["SYNC_TARGET_TIP_FLAVOR"] = "准备上马！"
L["SYNC_TARGET_TIP_TEXT"] = "自动选择当前目标的坐标。"
L["SYNC_TARGET_TIP_TITLE"] = "将日志与目标同步"
L["TOGGLE_COLOR"] = "显示下一个颜色变体"
L["Transform"] = "变形"

    -- Settings
L["DISPLAY_ALL_SETTINGS"] = "显示所有设置"
L[ [=[RESET_WINDOW_SIZE
]=] ] = "重置日志尺寸"
L["SETTING_ABOUT_AUTHOR"] = "作者"
L["SETTING_ACHIEVEMENT_POINTS"] = "显示成就点"
L["SETTING_COLOR_NAMES"] = "根据稀有度为列表中的名称着色"
L["SETTING_COMPACT_LIST"] = "紧凑坐骑列表"
L["SETTING_CURSOR_KEYS"] = "启用上下键浏览坐骑"
L["SETTING_DISPLAY_BACKGROUND"] = "更改显示的背景颜色"
L["SETTING_HEAD_ABOUT"] = "关于"
L["SETTING_HEAD_BEHAVIOUR"] = "行为"
L["SETTING_MOUNT_COUNT"] = "显示个人坐骑数量"
L["SETTING_MOUNTSPECIAL_BUTTON"] = "显示“/mountspecial”（展示特殊动作）按钮"
L["SETTING_PERSONAL_FILTER"] = "仅对这个角色应用过滤器"
L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "仅对这个角色应用坐骑隐藏"
L["SETTING_PERSONAL_UI"] = "仅对这个角色应用界面设置"
L["SETTING_PREVIEW_LINK"] = "在坐骑预览中显示藏品按钮"
L["SETTING_SEARCH_FAMILY_NAME"] = "也可以搜索系列名"
L["SETTING_SEARCH_MORE"] = "也同时在描述文本中搜索"
L["SETTING_SEARCH_NOTES"] = "也同时在自己的笔记中搜索"
L["SETTING_SHOW_DATA"] = "在屏幕上显示坐骑数据"
L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "再过滤菜单显示过滤配置文件。"
L["SETTING_SHOW_RESIZE_EDGE"] = "激活底角边缘以调整窗口尺寸"
L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "显示工具栏按钮"
L["SETTING_SUMMONPREVIOUSPET"] = "下马时再次召唤前一只宠物。"
L["SETTING_TRACK_USAGE"] = "跟踪所有角色的坐骑使用行为"
L["SETTING_YCAMERA"] = "展示窗解锁鼠标Y轴旋转"

    -- Families
L["Airplanes"] = "飞行器"
L["Airships"] = "飞艇"
L["Albatross"] = "信天翁"
L["Alpacas"] = "羊驼"
L["Amphibian"] = "两栖"
L["Animite"] = "心蛛"
L["Aqir Flyers"] = "亚基飞虫"
L["Arachnids"] = "蛛类"
L["Armoredon"] = "厚甲龙"
L["Basilisks"] = "蜥蜴"
L["Bats"] = "蝙蝠"
L["Bears"] = "熊"
L["Beetle"] = "甲虫"
L["Bipedal Cat"] = "梦爪獍"
L["Birds"] = "鸟类"
L["Boars"] = "野猪"
L["Bovids"] = "牛"
L["Broom"] = "扫帚"
L["Brutosaurs"] = "雷龙"
L["Camels"] = "骆驼"
L["Carnivorans"] = "食肉动物"
L["Carpets"] = "飞毯"
--[[Translation missing --]]
--[[ L["Carrion"] = "Carrion"--]] 
L["Cats"] = "猫科"
L["Cervid"] = "元鹿"
L["Chargers"] = "战马"
L["Chickens"] = "鸡"
L["Clefthooves"] = "裂蹄牛"
L["Cloud Serpents"] = "云端翔龙"
L["Core Hounds"] = "熔火恶犬"
L["Crabs"] = "蟹"
L["Cranes"] = "仙鹤"
L["Crawgs"] = "抱齿兽"
L["Crocolisks"] = "鳄鱼"
L["Crows"] = "乌鸦"
L["Demonic Hounds"] = "恶魔犬"
L["Demonic Steeds"] = "恶魔马"
L["Demons"] = "恶魔"
L["Devourer"] = "吞噬者"
L["Dinosaurs"] = "恐龙"
L["Dire Wolves"] = "恐狼"
L["Direhorns"] = "恐角龙"
L["Discs"] = "飞碟"
L["Dragonhawks"] = "龙鹰"
L["Drakes"] = "幼龙"
L["Dreamsaber"] = "梦刃豹"
L["Eagle"] = "雄鹰"
L["Elekks"] = "雷象"
L["Elementals"] = "元素"
L["Falcosaurs"] = "猎龙"
L["Fathom Rays"] = "深水鳐"
L["Feathermanes"] = "羽鬃兽"
L["Felbat"] = "魔蝠"
L["Felsabers"] = "邪刃豹"
L["Fish"] = "鱼"
L["Flies"] = "苍蝇"
L["Flying Steeds"] = "天马"
L["Foxes"] = "狐"
L["Gargon"] = "加尔贡"
L["Gargoyle"] = "石像鬼"
L["Goats"] = "山羊"
L["Gorger"] = "饕餮者"
L["Gorm"] = "戈姆"
L["Grand Drakes"] = "巨龙"
L["Gronnlings"] = "小戈隆"
L["Gryphons"] = "狮鹫"
L["Gyrocopters"] = "旋翼"
L["Hands"] = "手"
--[[Translation missing --]]
--[[ L["Harrower"] = "Harrower"--]] 
L["Hawkstriders"] = "陆行鸟"
L["Hedgehog"] = "刺猬"
L["Hippogryphs"] = "角鹰"
L["Horned Steeds"] = "角马"
L["Horses"] = "马"
L["Hounds"] = "犬"
L["Hover Board"] = "悬浮滑板"
L["Humanoids"] = "人型"
L["Hyenas"] = "狼"
L["Infernals"] = "地狱火"
L["Insects"] = "昆虫"
L["Jellyfish"] = "水母"
L["Jet Aerial Units"] = "空中单位"
L["Kites"] = "风筝"
L["Kodos"] = "科多兽"
L["Krolusks"] = "三叶虫"
L["Larion"] = "翼狮"
L["Lions"] = "狮"
L["Lupine"] = "元狼"
L["Lynx"] = "山猫"
L["Mammoths"] = "猛犸象"
L["Mana Rays"] = "法力鳐"
L["Mana Wyrm"] = "法力浮龙"
L["Manasabers"] = "魔刃豹"
L["Mauler"] = "重殴者"
L["Mechanical Animals"] = "机械生物"
L["Mechanical Birds"] = "机械鸟"
L["Mechanical Cats"] = "机械猫"
L["Mechanical Steeds"] = "机械马"
L["Mechanostriders"] = "机械陆行鸟"
L["Mecha-suits"] = "机甲"
L["Meeksi"] = "米克西"
L["Mite"] = "的幼虫"
L["Mole"] = "鼹鼠"
L["Mollusc"] = "软体动物"
L["Moose"] = "驼鹿"
L["Moth"] = "蛾"
L["Motorcycles"] = "摩托车"
L["Mountain Horses"] = "山地马"
L["Murloc"] = "鱼人"
L["Mushan"] = "穆山兽"
L["Nether Drakes"] = "灵翼幼龙"
L["Nether Rays"] = "虚空鳐"
L["N'Zoth Serpents"] = "恩佐斯蛇"
L["Others"] = "其他"
L["Ottuk"] = "奥獭"
L["Owl"] = "猫头鹰"
L["Owlbear"] = "月兽"
L["Ox"] = "公牛"
L["Pandaren Phoenixes"] = "熊猫人凤凰"
L["Pangolin"] = "穿山甲"
L["Parrots"] = "鹦鹉"
L["Peafowl"] = "孔雀"
--[[Translation missing --]]
--[[ L["Petalwing"] = "Petalwing"--]] 
L["Phoenixes"] = "凤凰"
--[[Translation missing --]]
--[[ L["Plant"] = "Plant"--]] 
L["Proto-Drakes"] = "始祖幼龙"
L["Pterrordaxes"] = "啸天龙"
L["Quilen"] = "魁麟"
L["Rabbit"] = "兔子"
L["Rams"] = "公羊"
L["Raptora"] = "元鹰"
L["Raptors"] = "迅猛龙"
L["Rats"] = "鼠"
L["Raven"] = "乌鸦"
L["Rays"] = "鳐"
L["Razorwing"] = "刀翼兽"
L["Reptiles"] = "爬虫"
L["Rhinos"] = "犀牛"
L["Riverbeasts"] = "淡水兽"
L["Roc"] = "大鹏"
L["Rockets"] = "火箭"
L["Rodent"] = "啮齿动物"
L["Ruinstriders"] = "游荡者"
L["Rylaks"] = "魔龙"
L["Sabers"] = "刃豹"
L["Scorpions"] = "蝎子"
L["Sea Serpents"] = "海蛇"
L["Seahorses"] = "海马"
L["Shalewing"] = [=[岩翼
]=]
L["Shardhides"] = "碎皮雄兽"
L["Silithids"] = "异种蝎"
L["Skyrazor"] = "剃天者"
L["Slateback"] = "岩背兽"
L["Slug"] = "蛞蝓"
L["Snail"] = "蜗牛"
L["Snapdragons"] = "毒鳍龙"
L["Spider Tanks"] = "蜘蛛坦克"
L["Spiders"] = "蜘蛛"
L["Sporebat"] = "孢子蝠"
L["Stag"] = "牡鹿"
L["Steeds"] = "马"
L["Stingrays"] = "鳐鱼"
L["Stone Cats"] = "石猎豹"
L["Stone Drakes"] = "石幼龙"
L["Talbuks"] = "塔布羊"
L["Tallstriders"] = "蛇鸟"
L["Talonbirds"] = "鸦神"
L["Tauralus"] = "荒牛"
L["Thunder Lizard"] = "雷霆蜥蜴"
L["Tigers"] = "虎"
L["Toads"] = "蟾蜍"
L["Turkey"] = "火鸡"
L["Turtles"] = "龟"
L["Undead Drakes"] = "不死幼龙"
L["Undead Steeds"] = "不死战马"
L["Undead Wolves"] = "不死战狼"
L["Ungulates"] = "有蹄类"
L["Ur'zul"] = "乌祖尔"
L["Vehicles"] = "载具"
L["Void Creeper"] = "虚空蠕行者"
L["Void Flyer"] = "虚空飞镰虫"
L["Vombata"] = "元袋熊"
L["Vulpin"] = "狡狐"
L["Vultures"] = "秃鹫"
L["War Wolves"] = "战狼"
L["Wasp"] = "巨蜂"
L["Water Striders"] = "水黾"
L["Wilderlings"] = "荒蚺"
L["Wind Drakes"] = "风幼龙"
L["Wolfhawks"] = "狼鹰"
L["Wolves"] = "狼"
L["Worm"] = "蠕虫"
L["Wyverns"] = "双足飞龙"
L["Yaks"] = "牦牛"
L["Yetis"] = "雪人"


elseif locale == "zhTW" then
    --[[Translation missing --]]
--[[ L["ANIMATION_FLY"] = "Fly"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_FLY_IDLE"] = "Fly Idle"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_RUN"] = "Run"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_STAND"] = "Stand"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_WALK"] = "ANIMATION_WALK"--]] 
--[[Translation missing --]]
--[[ L["ANIMATION_WALK_BACK"] = "Walk Backwards"--]] 
--[[Translation missing --]]
--[[ L["ASK_FAVORITE_PROFILE_NAME"] = "Enter Profile Name:"--]] 
--[[Translation missing --]]
--[[ L["AUTO_ROTATE"] = "Rotate automatically"--]] 
--[[Translation missing --]]
--[[ L["Black Market"] = "Black Market"--]] 
--[[Translation missing --]]
--[[ L["CLICK_TO_SHOW_LINK"] = "Click to Show Link"--]] 
--[[Translation missing --]]
--[[ L["COMPARTMENT_TOOLTIP"] = [=[|cffeda55fLeft-Click|r to toggle showing the mount collection.
|cffeda55fRight-Click|r to open addon options.]=]--]] 
--[[Translation missing --]]
--[[ L["CONFIRM_FAVORITE_PROFILE_DELETION"] = [=[Are you sure you want to delete the profile "%s"?
All current character assignments will be reset to the default profile "%s".]=]--]] 
--[[Translation missing --]]
--[[ L["DRESSUP_LABEL"] = "Journal"--]] 
--[[Translation missing --]]
--[[ L["EVENT_PLUNDERSTORM"] = "Plunderstorm"--]] 
--[[Translation missing --]]
--[[ L["EVENT_SCARAB"] = "Call of the Scarab"--]] 
--[[Translation missing --]]
--[[ L["EVENT_SECRETS"] = "Secrets of Azeroth"--]] 
--[[Translation missing --]]
--[[ L["Family"] = "Family"--]] 
--[[Translation missing --]]
--[[ L["FAVOR_AUTO"] = "Add new mounts automatically"--]] 
--[[Translation missing --]]
--[[ L["FAVOR_DISPLAYED"] = "All Displayed"--]] 
--[[Translation missing --]]
--[[ L["FAVORITE_ACCOUNT_PROFILE"] = "Account"--]] 
--[[Translation missing --]]
--[[ L["FAVORITE_PROFILE"] = "Profile"--]] 
--[[Translation missing --]]
--[[ L["FILTER_ONLY"] = "only"--]] 
--[[Translation missing --]]
--[[ L["FILTER_ONLY_LATEST"] = "Only latest additions"--]] 
--[[Translation missing --]]
--[[ L["FILTER_PROFILE"] = "Profile"--]] 
--[[Translation missing --]]
--[[ L["FILTER_PROFILE_TOOLTIP_TEXT"] = "Quickly load your predefined filter and search settings.|n|cffeda55fLeft-Click|r to load filter profile.|n|cffeda55fRight-Click|r to save filter profile."--]] 
--[[Translation missing --]]
--[[ L["FILTER_PROFILE_TOOLTIP_TITLE"] = "Filter Profiles"--]] 
--[[Translation missing --]]
--[[ L["FILTER_RETIRED"] = "No longer available"--]] 
--[[Translation missing --]]
--[[ L["FILTER_SECRET"] = "Hidden by the game"--]] 
--[[Translation missing --]]
--[[ L["Hidden"] = "Hidden"--]] 
--[[Translation missing --]]
--[[ L["LDB_TIP_NO_FAVORITES_LEFT_CLICK"] = "|cffeda55fLeft click|r to open Mount Collection."--]] 
--[[Translation missing --]]
--[[ L["LDB_TIP_NO_FAVORITES_RIGHT_CLICK"] = "|cffeda55fRight click|r to select different Favorite Profile."--]] 
--[[Translation missing --]]
--[[ L["LDB_TIP_NO_FAVORITES_TITLE"] = "You have not selected any mount as favorite yet."--]] 
--[[Translation missing --]]
--[[ L["LINK_WOWHEAD"] = "Link to Wowhead"--]] 
--[[Translation missing --]]
--[[ L["Mite"] = "Mite"--]] 
--[[Translation missing --]]
--[[ L["Only tradable"] = "Only tradable"--]] 
--[[Translation missing --]]
--[[ L["Passenger"] = "Passenger"--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_INFO"] = "You can assign a pet to this mount. It's going to be summoned as well, when you mount up.|n|nAll assignments are shared with all your characters.|n|nYou can use right-click on a pet entry to summon it manually.|n|nPlease be aware that most ground pets won't fly with you and just disappear when you take off. Also, flying pets are usually slower than you. So they might need some time to catch up to you.|n|nAuto summoning pets is only active in world content."--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_NONE"] = "No Pet"--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_TITLE"] = "Assign Pet to Mount"--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_TOOLTIP_CURRENT"] = "Current assigned Pet:"--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_TOOLTIP_LEFT"] = "|cffeda55fLeft click|r to open pet assignment."--]] 
--[[Translation missing --]]
--[[ L["PET_ASSIGNMENT_TOOLTIP_RIGHT"] = "|cffeda55fRight click|r to assign active pet to mount."--]] 
--[[Translation missing --]]
--[[ L["Reset filters"] = "Reset filters"--]] 
--[[Translation missing --]]
--[[ L["ROTATE_DOWN"] = "Rotate Down"--]] 
--[[Translation missing --]]
--[[ L["ROTATE_UP"] = "Rotate Up"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_FAMILY"] = "Family"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_LAST_USAGE"] = "Last usage"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_LEARNED_DATE"] = "Date of receipt"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_TRAVEL_DISTANCE"] = "Travelled distance"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_TRAVEL_DURATION"] = "Travelled duration"--]] 
--[[Translation missing --]]
--[[ L["SORT_BY_USAGE_COUNT"] = "Count of usage"--]] 
--[[Translation missing --]]
--[[ L["SORT_FAVORITES_FIRST"] = "Favorites First"--]] 
--[[Translation missing --]]
--[[ L["SORT_REVERSE"] = "Reverse Sort"--]] 
--[[Translation missing --]]
--[[ L["SORT_UNOWNED_BOTTOM"] = "Unowned at Bottom"--]] 
--[[Translation missing --]]
--[[ L["SORT_UNUSABLE_BOTTOM"] = "Unusable after Usable"--]] 
--[[Translation missing --]]
--[[ L["SPECIAL_TIP"] = "Starts the special animation of your mount in game."--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"] = "Count of collected customization options"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_LEARNED_DATE_HEAD"] = "Possession date"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_RARITY_DESCRIPTION"] = "% of characters who own this mount"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_RARITY_HEAD"] = "Rarity"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_DISTANCE_HEAD"] = "Travel distance"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_TIME_DAYS"] = "in days"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_TIME_HEAD"] = "Travel time"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_TRAVEL_TIME_TEXT"] = "in hours:minutes:seconds"--]] 
--[[Translation missing --]]
--[[ L["STATS_TIP_USAGE_COUNT_HEAD"] = "Usage count"--]] 
--[[Translation missing --]]
--[[ L["SYNC_TARGET_TIP_FLAVOR"] = "Get ready for a mount off!"--]] 
--[[Translation missing --]]
--[[ L["SYNC_TARGET_TIP_TEXT"] = "Automatically select the mount of your current target."--]] 
--[[Translation missing --]]
--[[ L["SYNC_TARGET_TIP_TITLE"] = "Sync Journal with Target"--]] 
--[[Translation missing --]]
--[[ L["TOGGLE_COLOR"] = "Show next color variation"--]] 
--[[Translation missing --]]
--[[ L["Transform"] = "Transform"--]] 

    -- Settings
--[[Translation missing --]]
--[[ L["DISPLAY_ALL_SETTINGS"] = "Display all settings"--]] 
--[[Translation missing --]]
--[[ L[ [=[RESET_WINDOW_SIZE
]=] ] = "Reset journal size"--]] 
--[[Translation missing --]]
--[[ L["SETTING_ABOUT_AUTHOR"] = "Author"--]] 
--[[Translation missing --]]
--[[ L["SETTING_ACHIEVEMENT_POINTS"] = "Show achievement points"--]] 
--[[Translation missing --]]
--[[ L["SETTING_COLOR_NAMES"] = "Colorize names in list based on rarity"--]] 
--[[Translation missing --]]
--[[ L["SETTING_COMPACT_LIST"] = "Compact mount list"--]] 
--[[Translation missing --]]
--[[ L["SETTING_CURSOR_KEYS"] = "Enable Up&Down keys to browse mounts"--]] 
--[[Translation missing --]]
--[[ L["SETTING_DISPLAY_BACKGROUND"] = "Change background color in display"--]] 
--[[Translation missing --]]
--[[ L["SETTING_HEAD_ABOUT"] = "About"--]] 
--[[Translation missing --]]
--[[ L["SETTING_HEAD_BEHAVIOUR"] = "Behavior"--]] 
--[[Translation missing --]]
--[[ L["SETTING_MOUNT_COUNT"] = "Show personal mount count"--]] 
--[[Translation missing --]]
--[[ L["SETTING_MOUNTSPECIAL_BUTTON"] = "Show /mountspecial button"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PERSONAL_FILTER"] = "Apply filters only to this character"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PERSONAL_HIDDEN_MOUNTS"] = "Apply hidden mounts only to this character"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PERSONAL_UI"] = "Apply Interface settings only to this character"--]] 
--[[Translation missing --]]
--[[ L["SETTING_PREVIEW_LINK"] = "Show Collection button in mount preview"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SEARCH_FAMILY_NAME"] = "Search also by family name"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SEARCH_MORE"] = "Search also in description text"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SEARCH_NOTES"] = "Search also in own notes"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_DATA"] = "Show mount data in display"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_FILTER_PROFILES_IN_MENU"] = "Show filter profiles in filter menu."--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_RESIZE_EDGE"] = "Activate edge in bottom corner to resize window"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SHOW_TOOLBAR_BUTTONS"] = "Show toolbar buttons"--]] 
--[[Translation missing --]]
--[[ L["SETTING_SUMMONPREVIOUSPET"] = "Summon previous active pet again when dismounting."--]] 
--[[Translation missing --]]
--[[ L["SETTING_TRACK_USAGE"] = "Track mount usage behavior on all characters"--]] 
--[[Translation missing --]]
--[[ L["SETTING_YCAMERA"] = "Unlock Y rotation with mouse in display"--]] 

    -- Families
--[[Translation missing --]]
--[[ L["Airplanes"] = "Airplanes"--]] 
--[[Translation missing --]]
--[[ L["Airships"] = "Airships"--]] 
--[[Translation missing --]]
--[[ L["Albatross"] = "Albatross"--]] 
--[[Translation missing --]]
--[[ L["Alpacas"] = "Alpacas"--]] 
--[[Translation missing --]]
--[[ L["Amphibian"] = "Amphibian"--]] 
--[[Translation missing --]]
--[[ L["Animite"] = "Animite"--]] 
--[[Translation missing --]]
--[[ L["Aqir Flyers"] = "Aqir Flyers"--]] 
--[[Translation missing --]]
--[[ L["Arachnids"] = "Arachnids"--]] 
--[[Translation missing --]]
--[[ L["Armoredon"] = "Armoredon"--]] 
--[[Translation missing --]]
--[[ L["Basilisks"] = "Basilisks"--]] 
--[[Translation missing --]]
--[[ L["Bats"] = "Bats"--]] 
--[[Translation missing --]]
--[[ L["Bears"] = "Bears"--]] 
--[[Translation missing --]]
--[[ L["Beetle"] = "Beetle"--]] 
--[[Translation missing --]]
--[[ L["Bipedal Cat"] = "Bipedal Cat"--]] 
--[[Translation missing --]]
--[[ L["Birds"] = "Birds"--]] 
--[[Translation missing --]]
--[[ L["Boars"] = "Boars"--]] 
--[[Translation missing --]]
--[[ L["Bovids"] = "Bovids"--]] 
--[[Translation missing --]]
--[[ L["Broom"] = "Broom"--]] 
--[[Translation missing --]]
--[[ L["Brutosaurs"] = "Brutosaurs"--]] 
--[[Translation missing --]]
--[[ L["Camels"] = "Camels"--]] 
--[[Translation missing --]]
--[[ L["Carnivorans"] = "Carnivorans"--]] 
--[[Translation missing --]]
--[[ L["Carpets"] = "Carpets"--]] 
--[[Translation missing --]]
--[[ L["Carrion"] = "Carrion"--]] 
--[[Translation missing --]]
--[[ L["Cats"] = "Cats"--]] 
--[[Translation missing --]]
--[[ L["Cervid"] = "Cervid"--]] 
--[[Translation missing --]]
--[[ L["Chargers"] = "Chargers"--]] 
--[[Translation missing --]]
--[[ L["Chickens"] = "Chickens"--]] 
--[[Translation missing --]]
--[[ L["Clefthooves"] = "Clefthooves"--]] 
--[[Translation missing --]]
--[[ L["Cloud Serpents"] = "Cloud Serpents"--]] 
--[[Translation missing --]]
--[[ L["Core Hounds"] = "Core Hounds"--]] 
--[[Translation missing --]]
--[[ L["Crabs"] = "Crabs"--]] 
--[[Translation missing --]]
--[[ L["Cranes"] = "Cranes"--]] 
--[[Translation missing --]]
--[[ L["Crawgs"] = "Crawgs"--]] 
--[[Translation missing --]]
--[[ L["Crocolisks"] = "Crocolisks"--]] 
--[[Translation missing --]]
--[[ L["Crows"] = "Crows"--]] 
--[[Translation missing --]]
--[[ L["Demonic Hounds"] = "Demonic Hounds"--]] 
--[[Translation missing --]]
--[[ L["Demonic Steeds"] = "Demonic Steeds"--]] 
--[[Translation missing --]]
--[[ L["Demons"] = "Demons"--]] 
--[[Translation missing --]]
--[[ L["Devourer"] = "Devourer"--]] 
--[[Translation missing --]]
--[[ L["Dinosaurs"] = "Dinosaurs"--]] 
--[[Translation missing --]]
--[[ L["Dire Wolves"] = "Dire Wolves"--]] 
--[[Translation missing --]]
--[[ L["Direhorns"] = "Direhorns"--]] 
--[[Translation missing --]]
--[[ L["Discs"] = "Discs"--]] 
--[[Translation missing --]]
--[[ L["Dragonhawks"] = "Dragonhawks"--]] 
--[[Translation missing --]]
--[[ L["Drakes"] = "Drakes"--]] 
--[[Translation missing --]]
--[[ L["Dreamsaber"] = "Dreamsaber"--]] 
--[[Translation missing --]]
--[[ L["Eagle"] = "Eagle"--]] 
--[[Translation missing --]]
--[[ L["Elekks"] = "Elekks"--]] 
--[[Translation missing --]]
--[[ L["Elementals"] = "Elementals"--]] 
--[[Translation missing --]]
--[[ L["Falcosaurs"] = "Falcosaurs"--]] 
--[[Translation missing --]]
--[[ L["Fathom Rays"] = "Fathom Rays"--]] 
--[[Translation missing --]]
--[[ L["Feathermanes"] = "Feathermanes"--]] 
--[[Translation missing --]]
--[[ L["Felbat"] = "Felbat"--]] 
--[[Translation missing --]]
--[[ L["Felsabers"] = "Felsabers"--]] 
--[[Translation missing --]]
--[[ L["Fish"] = "Fish"--]] 
--[[Translation missing --]]
--[[ L["Flies"] = "Flies"--]] 
--[[Translation missing --]]
--[[ L["Flying Steeds"] = "Flying Steeds"--]] 
--[[Translation missing --]]
--[[ L["Foxes"] = "Foxes"--]] 
--[[Translation missing --]]
--[[ L["Gargon"] = "Gargon"--]] 
--[[Translation missing --]]
--[[ L["Gargoyle"] = "Gargoyle"--]] 
--[[Translation missing --]]
--[[ L["Goats"] = "Goats"--]] 
--[[Translation missing --]]
--[[ L["Gorger"] = "Gorger"--]] 
--[[Translation missing --]]
--[[ L["Gorm"] = "Gorm"--]] 
--[[Translation missing --]]
--[[ L["Grand Drakes"] = "Grand Drakes"--]] 
--[[Translation missing --]]
--[[ L["Gronnlings"] = "Gronnlings"--]] 
--[[Translation missing --]]
--[[ L["Gryphons"] = "Gryphons"--]] 
--[[Translation missing --]]
--[[ L["Gyrocopters"] = "Gyrocopters"--]] 
--[[Translation missing --]]
--[[ L["Hands"] = "Hands"--]] 
--[[Translation missing --]]
--[[ L["Harrower"] = "Harrower"--]] 
--[[Translation missing --]]
--[[ L["Hawkstriders"] = "Hawkstriders"--]] 
--[[Translation missing --]]
--[[ L["Hedgehog"] = "Hedgehog"--]] 
--[[Translation missing --]]
--[[ L["Hippogryphs"] = "Hippogryphs"--]] 
--[[Translation missing --]]
--[[ L["Horned Steeds"] = "Horned Steeds"--]] 
--[[Translation missing --]]
--[[ L["Horses"] = "Horses"--]] 
--[[Translation missing --]]
--[[ L["Hounds"] = "Hounds"--]] 
--[[Translation missing --]]
--[[ L["Hover Board"] = "Hover Board"--]] 
--[[Translation missing --]]
--[[ L["Humanoids"] = "Humanoids"--]] 
--[[Translation missing --]]
--[[ L["Hyenas"] = "Hyenas"--]] 
--[[Translation missing --]]
--[[ L["Infernals"] = "Infernals"--]] 
--[[Translation missing --]]
--[[ L["Insects"] = "Insects"--]] 
--[[Translation missing --]]
--[[ L["Jellyfish"] = "Jellyfish"--]] 
--[[Translation missing --]]
--[[ L["Jet Aerial Units"] = "Jet Aerial Units"--]] 
--[[Translation missing --]]
--[[ L["Kites"] = "Kites"--]] 
--[[Translation missing --]]
--[[ L["Kodos"] = "Kodos"--]] 
--[[Translation missing --]]
--[[ L["Krolusks"] = "Krolusks"--]] 
--[[Translation missing --]]
--[[ L["Larion"] = "Larion"--]] 
--[[Translation missing --]]
--[[ L["Lions"] = "Lions"--]] 
--[[Translation missing --]]
--[[ L["Lupine"] = "Lupine"--]] 
--[[Translation missing --]]
--[[ L["Lynx"] = "Lynx"--]] 
--[[Translation missing --]]
--[[ L["Mammoths"] = "Mammoths"--]] 
--[[Translation missing --]]
--[[ L["Mana Rays"] = "Mana Rays"--]] 
--[[Translation missing --]]
--[[ L["Mana Wyrm"] = "Mana Wyrm"--]] 
--[[Translation missing --]]
--[[ L["Manasabers"] = "Manasabers"--]] 
--[[Translation missing --]]
--[[ L["Mauler"] = "Mauler"--]] 
--[[Translation missing --]]
--[[ L["Mechanical Animals"] = "Mechanical Animals"--]] 
--[[Translation missing --]]
--[[ L["Mechanical Birds"] = "Mechanical Birds"--]] 
--[[Translation missing --]]
--[[ L["Mechanical Cats"] = "Mechanical Cats"--]] 
--[[Translation missing --]]
--[[ L["Mechanical Steeds"] = "Mechanical Steeds"--]] 
--[[Translation missing --]]
--[[ L["Mechanostriders"] = "Mechanostriders"--]] 
--[[Translation missing --]]
--[[ L["Mecha-suits"] = "Mecha-suits"--]] 
--[[Translation missing --]]
--[[ L["Meeksi"] = "Meeksi"--]] 
--[[Translation missing --]]
--[[ L["Mite"] = "Mite"--]] 
--[[Translation missing --]]
--[[ L["Mole"] = "Mole"--]] 
--[[Translation missing --]]
--[[ L["Mollusc"] = "Mollusc"--]] 
--[[Translation missing --]]
--[[ L["Moose"] = "Moose"--]] 
--[[Translation missing --]]
--[[ L["Moth"] = "Moth"--]] 
--[[Translation missing --]]
--[[ L["Motorcycles"] = "Motorcycles"--]] 
--[[Translation missing --]]
--[[ L["Mountain Horses"] = "Mountain Horses"--]] 
--[[Translation missing --]]
--[[ L["Murloc"] = "Murloc"--]] 
--[[Translation missing --]]
--[[ L["Mushan"] = "Mushan"--]] 
--[[Translation missing --]]
--[[ L["Nether Drakes"] = "Nether Drakes"--]] 
--[[Translation missing --]]
--[[ L["Nether Rays"] = "Nether Rays"--]] 
--[[Translation missing --]]
--[[ L["N'Zoth Serpents"] = "N'Zoth Serpents"--]] 
--[[Translation missing --]]
--[[ L["Others"] = "Others"--]] 
--[[Translation missing --]]
--[[ L["Ottuk"] = "Ottuk"--]] 
--[[Translation missing --]]
--[[ L["Owl"] = "Owl"--]] 
--[[Translation missing --]]
--[[ L["Owlbear"] = "Owlbear"--]] 
--[[Translation missing --]]
--[[ L["Ox"] = "Ox"--]] 
--[[Translation missing --]]
--[[ L["Pandaren Phoenixes"] = "Pandaren Phoenixes"--]] 
--[[Translation missing --]]
--[[ L["Pangolin"] = "Pangolin"--]] 
--[[Translation missing --]]
--[[ L["Parrots"] = "Parrots"--]] 
--[[Translation missing --]]
--[[ L["Peafowl"] = "Peafowl"--]] 
--[[Translation missing --]]
--[[ L["Petalwing"] = "Petalwing"--]] 
--[[Translation missing --]]
--[[ L["Phoenixes"] = "Phoenixes"--]] 
--[[Translation missing --]]
--[[ L["Plant"] = "Plant"--]] 
--[[Translation missing --]]
--[[ L["Proto-Drakes"] = "Proto-Drakes"--]] 
--[[Translation missing --]]
--[[ L["Pterrordaxes"] = "Pterrordaxes"--]] 
--[[Translation missing --]]
--[[ L["Quilen"] = "Quilen"--]] 
--[[Translation missing --]]
--[[ L["Rabbit"] = "Rabbit"--]] 
--[[Translation missing --]]
--[[ L["Rams"] = "Rams"--]] 
--[[Translation missing --]]
--[[ L["Raptora"] = "Raptora"--]] 
--[[Translation missing --]]
--[[ L["Raptors"] = "Raptors"--]] 
--[[Translation missing --]]
--[[ L["Rats"] = "Rats"--]] 
--[[Translation missing --]]
--[[ L["Raven"] = "Raven"--]] 
--[[Translation missing --]]
--[[ L["Rays"] = "Rays"--]] 
--[[Translation missing --]]
--[[ L["Razorwing"] = "Razorwing"--]] 
--[[Translation missing --]]
--[[ L["Reptiles"] = "Reptiles"--]] 
--[[Translation missing --]]
--[[ L["Rhinos"] = "Rhinos"--]] 
--[[Translation missing --]]
--[[ L["Riverbeasts"] = "Riverbeasts"--]] 
--[[Translation missing --]]
--[[ L["Roc"] = "Roc"--]] 
--[[Translation missing --]]
--[[ L["Rockets"] = "Rockets"--]] 
--[[Translation missing --]]
--[[ L["Rodent"] = "Rodent"--]] 
--[[Translation missing --]]
--[[ L["Ruinstriders"] = "Ruinstriders"--]] 
--[[Translation missing --]]
--[[ L["Rylaks"] = "Rylaks"--]] 
--[[Translation missing --]]
--[[ L["Sabers"] = "Sabers"--]] 
--[[Translation missing --]]
--[[ L["Scorpions"] = "Scorpions"--]] 
--[[Translation missing --]]
--[[ L["Sea Serpents"] = "Sea Serpents"--]] 
--[[Translation missing --]]
--[[ L["Seahorses"] = "Seahorses"--]] 
--[[Translation missing --]]
--[[ L["Shalewing"] = "Shalewing"--]] 
--[[Translation missing --]]
--[[ L["Shardhides"] = "Shardhides"--]] 
--[[Translation missing --]]
--[[ L["Silithids"] = "Silithids"--]] 
--[[Translation missing --]]
--[[ L["Skyrazor"] = "Skyrazor"--]] 
--[[Translation missing --]]
--[[ L["Slateback"] = "Slateback"--]] 
--[[Translation missing --]]
--[[ L["Slug"] = "Slug"--]] 
--[[Translation missing --]]
--[[ L["Snail"] = "Snail"--]] 
--[[Translation missing --]]
--[[ L["Snapdragons"] = "Snapdragons"--]] 
--[[Translation missing --]]
--[[ L["Spider Tanks"] = "Spider Tanks"--]] 
--[[Translation missing --]]
--[[ L["Spiders"] = "Spiders"--]] 
--[[Translation missing --]]
--[[ L["Sporebat"] = "Sporebat"--]] 
--[[Translation missing --]]
--[[ L["Stag"] = "Stag"--]] 
--[[Translation missing --]]
--[[ L["Steeds"] = "Steeds"--]] 
--[[Translation missing --]]
--[[ L["Stingrays"] = "Stingrays"--]] 
--[[Translation missing --]]
--[[ L["Stone Cats"] = "Stone Cats"--]] 
--[[Translation missing --]]
--[[ L["Stone Drakes"] = "Stone Drakes"--]] 
--[[Translation missing --]]
--[[ L["Talbuks"] = "Talbuks"--]] 
--[[Translation missing --]]
--[[ L["Tallstriders"] = "Tallstriders"--]] 
--[[Translation missing --]]
--[[ L["Talonbirds"] = "Talonbirds"--]] 
--[[Translation missing --]]
--[[ L["Tauralus"] = "Tauralus"--]] 
--[[Translation missing --]]
--[[ L["Thunder Lizard"] = "Thunder Lizard"--]] 
--[[Translation missing --]]
--[[ L["Tigers"] = "Tigers"--]] 
--[[Translation missing --]]
--[[ L["Toads"] = "Toads"--]] 
--[[Translation missing --]]
--[[ L["Turkey"] = "Turkey"--]] 
--[[Translation missing --]]
--[[ L["Turtles"] = "Turtles"--]] 
--[[Translation missing --]]
--[[ L["Undead Drakes"] = "Undead Drakes"--]] 
--[[Translation missing --]]
--[[ L["Undead Steeds"] = "Undead Steeds"--]] 
--[[Translation missing --]]
--[[ L["Undead Wolves"] = "Undead Wolves"--]] 
--[[Translation missing --]]
--[[ L["Ungulates"] = "Ungulates"--]] 
--[[Translation missing --]]
--[[ L["Ur'zul"] = "Ur'zul"--]] 
--[[Translation missing --]]
--[[ L["Vehicles"] = "Vehicles"--]] 
--[[Translation missing --]]
--[[ L["Void Creeper"] = "Void Creeper"--]] 
--[[Translation missing --]]
--[[ L["Void Flyer"] = "Void Flyer"--]] 
--[[Translation missing --]]
--[[ L["Vombata"] = "Vombata"--]] 
--[[Translation missing --]]
--[[ L["Vulpin"] = "Vulpin"--]] 
--[[Translation missing --]]
--[[ L["Vultures"] = "Vultures"--]] 
--[[Translation missing --]]
--[[ L["War Wolves"] = "War Wolves"--]] 
--[[Translation missing --]]
--[[ L["Wasp"] = "Wasp"--]] 
--[[Translation missing --]]
--[[ L["Water Striders"] = "Water Striders"--]] 
--[[Translation missing --]]
--[[ L["Wilderlings"] = "Wilderlings"--]] 
--[[Translation missing --]]
--[[ L["Wind Drakes"] = "Wind Drakes"--]] 
--[[Translation missing --]]
--[[ L["Wolfhawks"] = "Wolfhawks"--]] 
--[[Translation missing --]]
--[[ L["Wolves"] = "Wolves"--]] 
--[[Translation missing --]]
--[[ L["Worm"] = "Worm"--]] 
--[[Translation missing --]]
--[[ L["Wyverns"] = "Wyverns"--]] 
--[[Translation missing --]]
--[[ L["Yaks"] = "Yaks"--]] 
--[[Translation missing --]]
--[[ L["Yetis"] = "Yetis"--]] 

end

-- update labels for keyboard bindings (see: Bindings.xml)
BINDING_NAME_MJE_RANDOM_MOUNT = MOUNT_JOURNAL_SUMMON_RANDOM_FAVORITE_MOUNT