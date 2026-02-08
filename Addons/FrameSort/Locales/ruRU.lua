local _, addon = ...
local L = addon.Locale.ruRU

-- # Main Options screen #
-- used in FrameSort - 1.2.3 version header, %s is the version number
L["FrameSort - %s"] = "FrameSort — %s"
L["There are some issues that may prevent FrameSort from working correctly."] = "Есть проблемы, которые могут помешать корректной работе FrameSort."
L["Please go to the Health Check panel to view more details."] =
    "Перейдите на панель «Проверка работоспособности», чтобы узнать подробности."
L["Role"] = "Роль"
L["Spec"] = "Спек"
L["Group"] = "Группа"
L["Alphabetical"] = "По алфавиту"
L["Arena - 2v2"] = "Арена — 2 на 2"
L["Arena - 3v3"] = "Арена — 3 на 3"
L["Arena - 3v3 & 5v5"] = "Арена — 3 на 3 и 5 на 5"
L["Enemy Arena (see addons panel for supported addons)"] = "Вражеская арена (см. панель аддонов для поддерживаемых аддонов)"
L["Dungeon (mythics, 5-mans, delves)"] = "Подземелье (мифики, 5 игроков, делвы)"
L["Raid (battlegrounds, raids)"] = "Рейд (поля боя, рейды)"
L["World (non-instance groups)"] = "Мир (группы вне инстансов)"
L["Player"] = "Игрок"
L["Sort"] = "Сортировка"
L["Top"] = "Сверху"
L["Middle"] = "По центру"
L["Bottom"] = "Снизу"
L["Hidden"] = "Скрыто"
L["Group"] = "Группа"
L["Reverse"] = "Обратный порядок"

-- # Sorting Method screen #
L["Sorting Method"] = "Метод сортировки"
L["Secure"] = "Безопасный"
L["SortingMethod_Secure_Description"] = [[
Настраивает позицию каждой отдельной рамки и не приводит к ошибкам/блокировкам/порче интерфейса.
\n
Плюсы:
 - Может сортировать рамки из других аддонов.
 - Может применять отступы между рамками.
 - Нет «taint» (технический термин для вмешательства аддонов в код интерфейса Blizzard).
\n
Минусы:
 - Хрупкая конструкция в обход «спагетти-кода» Blizzard.
 - Может ломаться с патчами WoW и сводить разработчика с ума.
]]
L["Traditional"] = "Традиционный"
L["SortingMethod_Traditional_Description"] = [[
Это стандартный режим сортировки, который аддоны и макросы используют уже 10+ лет.
Он заменяет внутренний метод сортировки Blizzard на наш.
Это то же самое, что скрипт 'SetFlowSortFunction', но с настройками FrameSort.
\n
Плюсы:
 - Более стабильный/надежный, так как опирается на внутренние методы сортировки Blizzard.
\n
Минусы:
 - Сортирует только групповые рамки Blizzard, ничего больше.
 - Может вызывать ошибки Lua — это нормально, их можно игнорировать.
 - Невозможно применять отступы между рамками.
]]
L["Please reload after changing these settings."] = "После изменения этих настроек перезагрузите интерфейс."
L["Reload"] = "Перезагрузить"

-- # Ordering screen #
L["Ordering"] = "Порядок"
L["Specify the ordering you wish to use when sorting by spec."] =
    "Укажите порядок, который будет использоваться при сортировке по специализации."
L["Tanks"] = "Танки"
L["Healers"] = "Лекари"
L["Casters"] = "Кастеры"
L["Hunters"] = "Охотники"
L["Melee"] = "Ближний бой"

-- # Spec Priority screen # --
L["Spec Priority"] = "Приоритет специализаций"
L["Spec Type"] = "Тип специализации"
L["Choose a spec type, then drag and drop to control priority."] =
    "Выберите тип специализации и измените приоритет с помощью перетаскивания."
L["Tank"] = "Танк"
L["Healer"] = "Лекарь"
L["Caster"] = "Заклинатель"
L["Hunter"] = "Охотник"
L["Melee"] = "Ближний бой"
L["Reset this type"] = "Сбросить этот тип"
L["Spec query note"] = [[
Обратите внимание, что информация о специализации запрашивается с сервера и занимает 1–2 секунды на игрока.
\n
Это означает, что точная сортировка может быть доступна не сразу.
]]

-- # Auto Leader screen #
L["Auto Leader"] = "Автолидер"
L["Auto promote healers to leader in solo shuffle."] = "Автоматически назначать лекаря лидером в «Соло потасовке»."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] =
    "Зачем? Чтобы лекари могли ставить метки и менять порядок party1/2 по своему усмотрению."
L["Enabled"] = "Включено"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "Выбор цели"
L["Target frame 1 (top frame)"] = "Выбрать рамку 1 (верхняя)"
L["Target frame 2"] = "Выбрать рамку 2"
L["Target frame 3"] = "Выбрать рамку 3"
L["Target frame 4"] = "Выбрать рамку 4"
L["Target frame 5"] = "Выбрать рамку 5"
L["Target bottom frame"] = "Выбрать нижнюю рамку"
L["Target 1 frame above bottom"] = "Выбрать рамку на 1 выше снизу"
L["Target 2 frames above bottom"] = "Выбрать рамку на 2 выше снизу"
L["Target 3 frames above bottom"] = "Выбрать рамку на 3 выше снизу"
L["Target 4 frames above bottom"] = "Выбрать рамку на 4 выше снизу"
L["Target frame 1's pet"] = "Выбрать питомца рамки 1"
L["Target frame 2's pet"] = "Выбрать питомца рамки 2"
L["Target frame 3's pet"] = "Выбрать питомца рамки 3"
L["Target frame 4's pet"] = "Выбрать питомца рамки 4"
L["Target frame 5's pet"] = "Выбрать питомца рамки 5"
L["Target enemy frame 1"] = "Выбрать рамку врага 1"
L["Target enemy frame 2"] = "Выбрать рамку врага 2"
L["Target enemy frame 3"] = "Выбрать рамку врага 3"
L["Target enemy frame 1's pet"] = "Выбрать питомца рамки врага 1"
L["Target enemy frame 2's pet"] = "Выбрать питомца рамки врага 2"
L["Target enemy frame 3's pet"] = "Выбрать питомца рамки врага 3"
L["Focus enemy frame 1"] = "Взять в фокус рамку врага 1"
L["Focus enemy frame 2"] = "Взять в фокус рамку врага 2"
L["Focus enemy frame 3"] = "Взять в фокус рамку врага 3"
L["Target the next frame"] = "Выбрать следующую рамку"
L["Target the previous frame"] = "Выбрать предыдущую рамку"
L["Cycle to the next frame"] = "Прокрутить к следующей рамке"
L["Cycle to the previous frame"] = "Прокрутить к предыдущей рамке"
L["Cycle to the next dps"] = "Переключиться на следующего бойца"
L["Cycle to the previous dps"] = "Переключиться на предыдущего бойца"

-- # Keybindings screen #
L["Keybindings"] = "Назначения клавиш"
L["Keybindings_Description"] = [[
Вы можете найти назначения клавиш FrameSort в стандартном разделе привязок клавиш WoW.
\n
Зачем нужны назначения клавиш?
Они полезны для выбора цели по визуальному порядку рамок, а не по позиции в группе (party1/2/3 и т. д.)
\n
Например, представьте группу из 5 игроков в подземелье, отсортированную по ролям так:
  - Танк, party3
  - Лекарь, player
  - ДПС, party1
  - ДПС, party4
  - ДПС, party2
\n
Как видно, визуальное расположение отличается от фактических номеров в группе, что сбивает с толку.
Если вы выполните /target party1, это выберет ДПС на позиции 3, а не танка.
\n
Назначения клавиш FrameSort выбирают цели по визуальной позиции рамки, а не по номеру в группе.
То есть «Рамка 1» выберет танка, «Рамка 2» — лекаря, «Рамка 3» — ДПС на позиции 3 и так далее.
]]

-- # Macros screen # --
L["Macros"] = "Макросы"
-- "|4macro:macros;" is a special command to pluralise the word "macro" to "macros" when %d is greater than 1
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort обнаружил %d макрос(ов) для управления."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] =
    'FrameSort будет динамически обновлять переменные в макросах, содержащих заголовок "#FrameSort".'
L["Below are some examples on how to use this."] = "Ниже приведены примеры использования."

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
L["Example %d"] = "Пример %d"
L["Discord Bot Blurb"] = [[
Нужна помощь с созданием макроса?
\n
Зайдите на сервер Discord FrameSort и воспользуйтесь нашим ботом для макросов на базе ИИ!
\n
Просто напишите '@Macro Bot' со своим вопросом в канале #macro-bot-channel.
]]

-- # Macro Variables screen # --
L["Macro Variables"] = "Переменные макросов"
L["The first DPS that's not you."] = "Первый ДПС, не вы."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] =
    "Добавьте номер, чтобы выбрать N-ю цель, например, DPS2 выберет второго ДПС."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] =
    "Переменные не чувствительны к регистру, поэтому 'fRaMe1', 'Dps', 'enemyhealer' и т. п. будут работать."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "Нужно экономить символы в макросах? Используйте сокращения:"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = 'Используйте "X", чтобы сказать FrameSort игнорировать селектор @unit:'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Spell;]]

-- # Spacing screen #
L["Spacing"] = "Отступы"
L["Add some spacing between party, raid, and arena frames."] = "Добавляет отступы между рамками группы, рейда и арены."
L["This only applies to Blizzard frames."] = "Применяется только к рамкам Blizzard."
L["Party"] = "Группа"
L["Raid"] = "Рейд"
L["Group"] = "Группа"
L["Horizontal"] = "Горизонтально"
L["Vertical"] = "Вертикально"

-- # Addons screen #
L["Addons"] = "Аддоны"
L["Addons_Supported_Description"] = [[
FrameSort поддерживает следующее:
\n
  - Blizzard: группа, рейд, арена.
\n
  - ElvUI: группа.
\n
  - sArena: арена.
\n
  - Gladius: арена.
\n
  - GladiusEx: группа, арена.
\n
  - Cell: группа, рейд (только при использовании объединённых групп).
\n
  - Shadowed Unit Frames: группа, арена.
\n
  - Grid2: группа, рейд.
\n
  - BattleGroundEnemies: группа, арена.
\n
  - Gladdy: арена.
\n
  - Arena Core: 0.9.1.7+.
\n
]]

-- # Api screen #
L["Api"] = "API"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "Хотите интегрировать FrameSort в свои аддоны, скрипты и WeakAuras?"
L["Here are some examples."] = "Вот несколько примеров."
L["Retrieved an ordered array of party/raid unit tokens."] = "Получить упорядоченный массив токенов юнитов группы/рейда."
L["Retrieved an ordered array of arena unit tokens."] = "Получить упорядоченный массив токенов юнитов арены."
L["Register a callback function to run after FrameSort sorts frames."] =
    "Зарегистрировать функцию обратного вызова, выполняемую после сортировки рамок FrameSort."
L["Retrieve an ordered array of party frames."] = "Получить упорядоченный массив рамок группы."
L["Change a FrameSort setting."] = "Изменить настройку FrameSort."
L["Get the frame number of a unit."] = "Получает номер фрейма для юнита."
L["View a full listing of all API methods on GitHub."] = "Полный список методов API доступен на GitHub."

-- # Discord screen #
L["Discord"] = "Discord"
L["Need help with something?"] = "Нужна помощь?"
L["Talk directly with the developer on Discord."] = "Свяжитесь напрямую с разработчиком в Discord."

-- # Health Check screen -- #
L["Health Check"] = "Проверка работоспособности"
L["Try this"] = "Попробуйте это"
L["Any known issues with configuration or conflicting addons will be shown below."] =
    "Любые известные проблемы с настройкой или конфликтами аддонов будут показаны ниже."
L["N/A"] = "Н/Д"
L["Passed!"] = "Пройдено!"
L["Failed"] = "Не удалось"
L["(unknown)"] = "(неизвестно)"
L["(user macro)"] = "(пользовательский макрос)"
L["Using grouped layout for Cell raid frames"] = "Используется сгруппированный макет для рейдовых рамок Cell"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Проверьте опцию 'Combined Groups (Raid)' в Cell -> Layouts"
L["Can detect frames"] = "Рамки обнаружены"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort в настоящее время поддерживает рамки из этих аддонов: %s"
L["Using Raid-Style Party Frames"] = "Используются рамки группы в стиле рейда"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "Включите 'Use Raid-Style Party Frames' в настройках Blizzard"
L["Keep Groups Together setting disabled"] = "Настройка 'Keep Groups Together' отключена"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] =
    "Измените режим отображения рейда на один из вариантов 'Combined Groups' через Режим редактирования"
L["Disable the 'Keep Groups Together' raid profile setting."] = "Отключите параметр профиля рейда 'Keep Groups Together'."
L["Only using Blizzard frames with Traditional mode"] = "Используются только рамки Blizzard в традиционном режиме"
L["Traditional mode can't sort your other frame addons: '%s'"] = "Традиционный режим не может сортировать рамки других аддонов: '%s'"
L["Using Secure sorting mode when spacing is being used"] = "Используется безопасный режим сортировки при включённых отступах"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] =
    "Традиционный режим не может применять отступы; уберите отступы или используйте безопасный метод сортировки"
L["Blizzard sorting functions not tampered with"] = "Функции сортировки Blizzard не изменены"
L['"%s" may cause conflicts, consider disabling it'] = '"%s" может вызывать конфликты, рассмотрите возможность его отключения'
L["No conflicting addons"] = "Конфликтующих аддонов нет"

-- # Log Screen -- #
L["Log"] = "Журнал"
L["FrameSort log to help with diagnosing issues."] = "Журнал FrameSort для диагностики проблем."
L["Copy Log"] = "Копировать журнал"

-- # Notifications -- #
L["Can't do that during combat."] = "Невозможно сделать это в бою."

-- # Nameplates screen #
L["Nameplates"] = "Индикаторы здоровья"
L["Friendly Nameplates"] = "Индикаторы союзников"
L["Enemy Nameplates"] = "Индикаторы врагов"
L["NameplatesBlurb"] = [[
Заменяет текст индикаторов имён Blizzard и Platynator на переменные FrameSort.
\n
Поддерживаемые переменные:
  - $framenumber
  - $name
  - $unit
  - $spec
\n
Примеры:
  - Фрейм - $framenumber
  - $framenumber - $spec
  - $name - $spec
]]

-- # Miscellaneous screen #
L["Miscellaneous"] = "Разное"
L["Various tweaks you can apply."] = "Различные настройки, которые вы можете применить."
L["Player top of role"] = "Игрок в начале роли"
L["Places you at the top of your corresponding role (healer/tank/dps)."] = "Размещает вас в начале вашей соответствующей роли (лекарь/танк/DPS)."

-- # Language screen #
L["Language"] = "Язык"
L["Specify the language we use."] = "Укажите используемый язык."
