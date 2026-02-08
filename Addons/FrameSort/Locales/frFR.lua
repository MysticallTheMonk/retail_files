local _, addon = ...
local L = addon.Locale.frFR

-- # Main Options screen #
-- used in FrameSort - 1.2.3 version header, %s is the version number
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issues that may prevent FrameSort from working correctly."] = "Certains problèmes peuvent empêcher FrameSort de fonctionner correctement."
L["Please go to the Health Check panel to view more details."] = "Veuillez consulter le panneau Diagnostic pour plus de détails."
L["Role"] = "Rôle"
L["Spec"] = "Spé"
L["Group"] = "Groupe"
L["Alphabetical"] = "Alphabétique"
L["Arena - 2v2"] = "Arène - 2v2"
L["Arena - 3v3"] = "Arène - 3v3"
L["Arena - 3v3 & 5v5"] = "Arène - 3v3 & 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "Arène ennemie (voir le panneau des addons pour les addons pris en charge)"
L["Dungeon (mythics, 5-mans, delves)"] = "Donjon (mythiques, à 5 joueurs, delves)"
L["Raid (battlegrounds, raids)"] = "Raid (champs de bataille, raids)"
L["World (non-instance groups)"] = "Monde (groupes non instanciés)"
L["Player"] = "Joueur"
L["Sort"] = "Tri"
L["Top"] = "Haut"
L["Middle"] = "Milieu"
L["Bottom"] = "Bas"
L["Hidden"] = "Masqué"
L["Group"] = "Groupe"
L["Reverse"] = "Inverser"

-- # Sorting Method screen #
L["Sorting Method"] = "Méthode de tri"
L["Secure"] = "Sécurisée"
L["SortingMethod_Secure_Description"] = [[
Ajuste la position de chaque cadre individuellement et n’entraîne pas de bugs/blocages/taint de l’interface.
\n
Avantages :
 - Peut trier les cadres d’autres addons.
 - Peut appliquer un espacement entre les cadres.
 - Aucun « taint » (terme technique pour les interférences avec le code de l’interface de Blizzard).
\n
Inconvénients :
 - Château de cartes fragile pour contourner le spaghetti de Blizzard.
 - Peut casser avec des mises à jour de WoW et rendre le développeur fou.
]]
L["Traditional"] = "Traditionnelle"
L["SortingMethod_Traditional_Description"] = [[
C’est le mode de tri standard utilisé par les addons et macros depuis plus de 10 ans.
Il remplace la méthode de tri interne de Blizzard par la nôtre.
C’est équivalent au script « SetFlowSortFunction » mais avec la configuration de FrameSort.
\n
Avantages :
 - Plus stable/fiable car il s’appuie sur les méthodes de tri internes de Blizzard.
\n
Inconvénients :
 - Trie uniquement les cadres de groupe Blizzard, rien d’autre.
 - Provoquera des erreurs Lua, ce qui est normal et peut être ignoré.
 - Ne peut pas appliquer d’espacement entre les cadres.
]]
L["Please reload after changing these settings."] = "Veuillez recharger après avoir modifié ces paramètres."
L["Reload"] = "Recharger"

-- # Ordering screen #
L["Ordering"] = "Ordre"
L["Specify the ordering you wish to use when sorting by spec."] = "Définissez l’ordre à utiliser lors du tri par spécialisation."
L["Tanks"] = "Tanks"
L["Healers"] = "Soigneurs"
L["Casters"] = "Lanceurs de sorts"
L["Hunters"] = "Chasseurs"
L["Melee"] = "Mêlée"

-- # Spec Priority screen # --
L["Spec Priority"] = "Priorité des spécialisations"
L["Spec Type"] = "Type de spécialisation"
L["Choose a spec type, then drag and drop to control priority."] = "Choisissez un type de spécialisation, puis utilisez le glisser-déposer pour définir la priorité."
L["Tank"] = "Tank"
L["Healer"] = "Soigneur"
L["Caster"] = "Lanceur de sorts"
L["Hunter"] = "Chasseur"
L["Melee"] = "Mêlée"
L["Reset this type"] = "Réinitialiser ce type"
L["Spec query note"] = [[
Veuillez noter que les informations de spécialisation sont récupérées depuis le serveur, ce qui prend 1 à 2 secondes par joueur.
\n
Cela signifie qu’un court délai peut être nécessaire avant que le tri soit précis.
]]

-- # Auto Leader screen #
L["Auto Leader"] = "Chef automatique"
L["Auto promote healers to leader in solo shuffle."] = "Promouvoir automatiquement les soigneurs au rang de chef en Solo Shuffle."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] =
    "Pourquoi ? Pour que les soigneurs puissent configurer les icônes de marqueurs de cible et réorganiser party1/2 selon leur préférence."
L["Enabled"] = "Activé"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "Ciblage"
L["Target frame 1 (top frame)"] = "Cibler le cadre 1 (cadre du haut)"
L["Target frame 2"] = "Cibler le cadre 2"
L["Target frame 3"] = "Cibler le cadre 3"
L["Target frame 4"] = "Cibler le cadre 4"
L["Target frame 5"] = "Cibler le cadre 5"
L["Target bottom frame"] = "Cibler le cadre du bas"
L["Target 1 frame above bottom"] = "Cibler le cadre 1 au-dessus du bas"
L["Target 2 frames above bottom"] = "Cibler le cadre 2 au-dessus du bas"
L["Target 3 frames above bottom"] = "Cibler le cadre 3 au-dessus du bas"
L["Target 4 frames above bottom"] = "Cibler le cadre 4 au-dessus du bas"
L["Target frame 1's pet"] = "Cibler le familier du cadre 1"
L["Target frame 2's pet"] = "Cibler le familier du cadre 2"
L["Target frame 3's pet"] = "Cibler le familier du cadre 3"
L["Target frame 4's pet"] = "Cibler le familier du cadre 4"
L["Target frame 5's pet"] = "Cibler le familier du cadre 5"
L["Target enemy frame 1"] = "Cibler le cadre ennemi 1"
L["Target enemy frame 2"] = "Cibler le cadre ennemi 2"
L["Target enemy frame 3"] = "Cibler le cadre ennemi 3"
L["Target enemy frame 1's pet"] = "Cibler le familier du cadre ennemi 1"
L["Target enemy frame 2's pet"] = "Cibler le familier du cadre ennemi 2"
L["Target enemy frame 3's pet"] = "Cibler le familier du cadre ennemi 3"
L["Focus enemy frame 1"] = "Mettre en focalisation le cadre ennemi 1"
L["Focus enemy frame 2"] = "Mettre en focalisation le cadre ennemi 2"
L["Focus enemy frame 3"] = "Mettre en focalisation le cadre ennemi 3"
L["Target the next frame"] = "Cibler le cadre suivant"
L["Target the previous frame"] = "Cibler le cadre précédent"
L["Cycle to the next frame"] = "Faire défiler jusqu’au cadre suivant"
L["Cycle to the previous frame"] = "Faire défiler jusqu’au cadre précédent"
L["Cycle to the next dps"] = "Passer au DPS suivant"
L["Cycle to the previous dps"] = "Passer au DPS précédent"

-- # Keybindings screen #
L["Keybindings"] = "Raccourcis clavier"
L["Keybindings_Description"] = [[
Vous trouverez les raccourcis FrameSort dans la zone standard des raccourcis clavier de WoW.
\n
À quoi servent ces raccourcis ?
Ils permettent de cibler les joueurs selon leur représentation visuelle plutôt que leur
position de groupe (party1/2/3/etc.).
\n
Par exemple, imaginez un groupe de donjon à 5 trié par rôle qui ressemble à ceci :
  - Tank, party3
  - Soigneur, player
  - DPS, party1
  - DPS, party4
  - DPS, party2
\n
Comme vous pouvez le voir, leur représentation visuelle diffère de leur position réelle dans le groupe, ce qui
rend le ciblage déroutant.
Si vous faites /target party1, cela ciblera le joueur DPS en position 3 plutôt que le tank.
\n
Les raccourcis FrameSort cibleront en fonction de la position visuelle des cadres plutôt que du numéro de groupe.
Ainsi, cibler « Cadre 1 » ciblera le Tank, « Cadre 2 » le soigneur, « Cadre 3 » le DPS en position 3, et ainsi de suite.
]]

-- # Macros screen # --
L["Macros"] = "Macros"
-- "|4macro:macros;" is a special command to pluralise the word "macro" to "macros" when %d is greater than 1
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort a trouvé %d |4macro:macros; à gérer."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] =
    "FrameSort mettra à jour dynamiquement les variables dans les macros qui contiennent l’en-tête « #FrameSort »."
L["Below are some examples on how to use this."] = "Voici quelques exemples d’utilisation."

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
L["Example %d"] = "Exemple %d"
L["Discord Bot Blurb"] = [[
Besoin d’aide pour créer une macro ?
\n
Rendez-vous sur le serveur Discord de FrameSort et utilisez notre bot de macros propulsé par IA !
\n
Mentionnez simplement « @Macro Bot » avec votre question dans le canal #macro-bot-channel.
]]

-- # Macro Variables screen # --
L["Macro Variables"] = "Variables de macro"
L["The first DPS that's not you."] = "Le premier DPS qui n’est pas vous."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "Ajoutez un nombre pour choisir la N-ième cible, p. ex., DPS2 sélectionne le 2e DPS."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] =
    "Les variables ne sont pas sensibles à la casse, donc « fRaMe1 », « Dps », « enemyhealer », etc., fonctionneront toutes."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "Besoin d’économiser des caractères dans vos macros ? Utilisez des abréviations pour les raccourcir :"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = "Utilisez « X » pour indiquer à FrameSort d’ignorer un sélecteur @unit :"
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Spell;]]

-- # Spacing screen #
L["Spacing"] = "Espacement"
L["Add some spacing between party, raid, and arena frames."] = "Ajoute un espacement entre les cadres de groupe, de raid et d’arène."
L["This only applies to Blizzard frames."] = "S’applique uniquement aux cadres Blizzard."
L["Party"] = "Groupe"
L["Raid"] = "Raid"
L["Group"] = "Groupe"
L["Horizontal"] = "Horizontal"
L["Vertical"] = "Vertical"

-- # Addons screen #
L["Addons"] = "Addons"
L["Addons_Supported_Description"] = [[
FrameSort prend en charge les éléments suivants :
\n
  - Blizzard : groupe, raid, arène.
\n
  - ElvUI : groupe.
\n
  - sArena : arène.
\n
  - Gladius : arène.
\n
  - GladiusEx : groupe, arène.
\n
  - Cell : groupe, raid (uniquement avec des groupes combinés).
\n
  - Shadowed Unit Frames : groupe, arène.
\n
  - Grid2 : groupe, raid.
\n
  - BattleGroundEnemies : groupe, arène.
\n
  - Gladdy : arène.
\n
  - Arena Core: 0.9.1.7+.
\n
]]

-- # Api screen #
L["Api"] = "API"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "Vous souhaitez intégrer FrameSort à vos addons, scripts et WeakAuras ?"
L["Here are some examples."] = "Voici quelques exemples."
L["Retrieved an ordered array of party/raid unit tokens."] = "Récupérer un tableau ordonné des jetons d’unités de groupe/raid."
L["Retrieved an ordered array of arena unit tokens."] = "Récupérer un tableau ordonné des jetons d’unités d’arène."
L["Register a callback function to run after FrameSort sorts frames."] = "Enregistrer une fonction de rappel à exécuter après le tri des cadres par FrameSort."
L["Retrieve an ordered array of party frames."] = "Récupérer un tableau ordonné des cadres de groupe."
L["Change a FrameSort setting."] = "Modifier un paramètre de FrameSort."
L["Get the frame number of a unit."] = "Récupère le numéro du cadre d'une unité."
L["View a full listing of all API methods on GitHub."] = "Afficher la liste complète de toutes les méthodes de l’API sur GitHub."

-- # Discord screen #
L["Discord"] = "Discord"
L["Need help with something?"] = "Besoin d’aide ?"
L["Talk directly with the developer on Discord."] = "Parlez directement avec le développeur sur Discord."

-- # Health Check screen -- #
L["Health Check"] = "Diagnostic"
L["Try this"] = "À essayer"
L["Any known issues with configuration or conflicting addons will be shown below."] = "Tout problème connu de configuration ou de conflit d’addons sera affiché ci-dessous."
L["N/A"] = "N/A"
L["Passed!"] = "Réussi !"
L["Failed"] = "Échec"
L["(unknown)"] = "(inconnu)"
L["(user macro)"] = "(macro utilisateur)"
L["Using grouped layout for Cell raid frames"] = "Disposition groupée utilisée pour les cadres de raid de Cell"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Veuillez cocher l’option « Groupes combinés (Raid) » dans Cell -> Layouts"
L["Can detect frames"] = "Peut détecter les cadres"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort prend actuellement en charge les cadres de ces addons : %s"
L["Using Raid-Style Party Frames"] = "Utilisation des cadres de groupe style raid"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "Veuillez activer « Utiliser les cadres de groupe style raid » dans les options Blizzard"
L["Keep Groups Together setting disabled"] = "Paramètre « Conserver les groupes ensemble » désactivé"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "Changez le mode d’affichage du raid pour l’une des options « Groupes combinés » via le mode Édition"
L["Disable the 'Keep Groups Together' raid profile setting."] = "Désactivez le paramètre de profil de raid « Conserver les groupes ensemble »."
L["Only using Blizzard frames with Traditional mode"] = "Utilisation uniquement des cadres Blizzard avec le mode Traditionnel"
L["Traditional mode can't sort your other frame addons: '%s'"] = "Le mode Traditionnel ne peut pas trier vos autres addons de cadres : « %s »"
L["Using Secure sorting mode when spacing is being used"] = "Mode de tri Sécurisé utilisé alors que l’espacement est activé"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] =
    "Le mode Traditionnel ne peut pas appliquer d’espacement ; envisagez de le retirer ou d’utiliser la méthode de tri Sécurisée"
L["Blizzard sorting functions not tampered with"] = "Fonctions de tri Blizzard non altérées"
L['"%s" may cause conflicts, consider disabling it'] = "« %s » peut provoquer des conflits, envisagez de le désactiver"
L["No conflicting addons"] = "Aucun addon en conflit"

-- # Log Screen -- #
L["Log"] = "Journal"
L["FrameSort log to help with diagnosing issues."] = "Journal FrameSort pour aider à diagnostiquer les problèmes."
L["Copy Log"] = "Copier le journal"

-- # Notifications -- #
L["Can't do that during combat."] = "Impossible de faire cela en combat."

-- # Nameplates screen #
L["Nameplates"] = "Barres de nom"
L["Friendly Nameplates"] = "Barres de nom amicales"
L["Enemy Nameplates"] = "Barres de nom ennemies"
L["NameplatesBlurb"] = [[
Remplace le texte des plaques de nom Blizzard et Platynator par des variables FrameSort.
\n
Variables prises en charge :
  - $framenumber
  - $name
  - $unit
  - $spec
\n
Exemples :
  - Cadre - $framenumber
  - $framenumber - $spec
  - $name - $spec
]]

-- # Miscellaneous screen #
L["Miscellaneous"] = "Divers"
L["Various tweaks you can apply."] = "Divers ajustements que vous pouvez appliquer."
L["Player top of role"] = "Joueur en tête de rôle"
L["Places you at the top of your corresponding role (healer/tank/dps)."] = "Vous place en tête de votre rôle correspondant (soigneur/tank/DPS)."

-- # Language screen #
L["Language"] = "Langue"
L["Specify the language we use."] = "Définit la langue utilisée."
