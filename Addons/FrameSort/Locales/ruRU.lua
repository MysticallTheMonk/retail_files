local _, addon = ...
local L = addon.Locale
local wow = addon.WoW.Api

if wow.GetLocale() ~= "ruRU" then
    return
end

-- # Main Options screen #
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issuse that may prevent FrameSort from working correctly."] = "Существуют некоторые проблемы, которые могут помешать правильной работе FrameSort."
L["Please go to the Health Check panel to view more details."] = "Пожалуйста, перейдите на панель проверки здоровья для получения дополнительной информации."
L["Role/spec"] = "Роль/Спецификация"
L["Group"] = "Группа"
L["Alphabetical"] = "Алфавитный"
L["Arena - 2v2"] = "Арена - 2 на 2"
L["Arena - 3v3"] = "Арена - 3 на 3"
L["Arena - 3v3 & 5v5"] = "Арена - 3 на 3 и 5 на 5"
L["Enemy Arena (see addons panel for supported addons)"] = "Враждебная арена (смотрите панель дополнений для поддерживаемых дополнений)"
L["Dungeon (mythics, 5-mans, delves)"] = "Подземелье (мифики, 5-игроков, исследование)"
L["Raid (battlegrounds, raids)"] = "Рейд (полевые сражения, рейды)"
L["World (non-instance groups)"] = "Мир (группы вне подземелий)"
L["Player"] = "Игрок"
L["Sort"] = "Сортировать"
L["Top"] = "Верх"
L["Middle"] = "Середина"
L["Bottom"] = "Низ"
L["Hidden"] = "Скрытый"
L["Group"] = "Группа"
L["Reverse"] = "Обратный"

-- # Sorting Method screen #
L["Sorting Method"] = "Метод сортировки"
L["Secure"] = "Безопасный"
L["SortingMethod_Secure_Description"] = [[
Настраивает позицию каждого отдельного фрейма и не вызывает проблем с UI (интерфейсом).
\n
Преимущества:
 - Может сортировать фреймы от других дополнений.
 - Может применять промежутки между фреймами.
 - Нет проблем с вмешательством (технический термин для дополнений, мешающих коду UI Blizzard).
\n
Недостатки:
 - Хрупкая ситуация, чтобы обойти хаос Blizzard.
 - Может сломаться с патчами WoW и свести разработчика с ума.
]]
L["Traditional"] = "Традиционный"
L["SortingMethod_Traditional_Description"] = [[
Это стандартный режим сортировки, который использовался дополнениями и макросами более 10 лет.
Он заменяет внутренний метод сортировки Blizzard на наш.
Это то же самое, что скрипт 'SetFlowSortFunction', но с конфигурацией FrameSort.
\n
Преимущества:
 - Более стабильный/надежный, так как использует внутренние методы сортировки Blizzard.
\n
Недостатки:
 - Сортирует только фреймы группы Blizzard, ничего другого.
 - Будет вызывать ошибки Lua, что нормально и может быть проигнорировано.
 - Не может применять промежутки между фреймами.
]]
L["Please reload after changing these settings."] = "Пожалуйста, перезагрузите после изменения этих настроек."
L["Reload"] = "Перезагрузить"

-- # Ordering screen #
L["Ordering"] = "Порядок"
L["Specify the ordering you wish to use when sorting by role."] = "Укажите порядок, который вы хотите использовать при сортировке по роли."
L["Tanks"] = "Танки"
L["Healers"] = "Исцелители"
L["Casters"] = "Кастеры"
L["Hunters"] = "Охотники"
L["Melee"] = "Ближний бой"

-- # Auto Leader screen #
L["Auto Leader"] = "Авто Лидер"
L["Auto promote healers to leader in solo shuffle."] = "Автоматически повышать исцелителей до лидеров в одиночном перемешивании."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] = "Почему? Чтобы исцелители могли настраивать значки маркера цели и переупорядочивать party1/2 по своему вкусу."
L["Enabled"] = "Включено"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "Целеполагание"
L["Target frame 1 (top frame)"] = "Целевой фрейм 1 (верхний фрейм)"
L["Target frame 2"] = "Целевой фрейм 2"
L["Target frame 3"] = "Целевой фрейм 3"
L["Target frame 4"] = "Целевой фрейм 4"
L["Target frame 5"] = "Целевой фрейм 5"
L["Target bottom frame"] = "Целевой нижний фрейм"
L["Target 1 frame above bottom"] = "Выбрать 1 кадр выше снизу"
L["Target 2 frames above bottom"] = "Выбрать 2 кадра выше снизу"
L["Target 3 frames above bottom"] = "Выбрать 3 кадра выше снизу"
L["Target 4 frames above bottom"] = "Выбрать 4 кадра выше снизу"
L["Target frame 1's pet"] = "Цель питомца фрейма 1"
L["Target frame 2's pet"] = "Цель питомца фрейма 2"
L["Target frame 3's pet"] = "Цель питомца фрейма 3"
L["Target frame 4's pet"] = "Цель питомца фрейма 4"
L["Target frame 5's pet"] = "Цель питомца фрейма 5"
L["Target enemy frame 1"] = "Целевой враждебный фрейм 1"
L["Target enemy frame 2"] = "Целевой враждебный фрейм 2"
L["Target enemy frame 3"] = "Целевой враждебный фрейм 3"
L["Target enemy frame 1's pet"] = "Цель питомца враждебного фрейма 1"
L["Target enemy frame 2's pet"] = "Цель питомца враждебного фрейма 2"
L["Target enemy frame 3's pet"] = "Цель питомца враждебного фрейма 3"
L["Focus enemy frame 1"] = "Фокус на враждебный фрейм 1"
L["Focus enemy frame 2"] = "Фокус на враждебный фрейм 2"
L["Focus enemy frame 3"] = "Фокус на враждебный фрейм 3"
L["Cycle to the next frame"] = "Сменить на следующий фрейм"
L["Cycle to the previous frame"] = "Сменить на предыдущий фрейм"
L["Target the next frame"] = "Цель на следующий фрейм"
L["Target the previous frame"] = "Цель на предыдущий фрейм"

-- # Keybindings screen #
L["Keybindings"] = "Горячие клавиши"
L["Keybindings_Description"] = [[
Вы можете найти горячие клавиши FrameSort в стандартной области горячих клавиш WoW.
\n
Для чего нужны горячие клавиши?
Они полезны для целеполагания на игроков по их визуально упорядоченному представлению, а не по их
позиции в группе (party1/2/3 и т.д.)
\n
Например, представьте группу из 5 человек в подземелье, отсортированную по ролям, которая выглядит так:
  - Танки, party3
  - Исцелитель, игрок
  - ДД, party1
  - ДД, party4
  - ДД, party2
\n
Как видите, их визуальное представление отличается от их фактической позиции в группе, что
делает целеполагание запутающим.
Если вы будете /target party1, то это будет цель на ДД игрока, занимающего третье место, вместо танка.
\n
Горячие клавиши FrameSort будут целить на основе их визуальной позиции фрейма, а не по номеру группы.
Так что целевая "Фрейм 1" будет целиться на танка, "Фрейм 2" на исцелителя, "Фрейм 3" на ДД на третьем месте и так далее.
]]

-- # Macros screen # --
L["Macros"] = "Макросы"
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort нашёл %d |4макрос:макроса; для управления."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] = 'FrameSort динамически обновит переменные внутри макросов, содержащих заголовок "#FrameSort".'
L["Below are some examples on how to use this."] = "Ниже приведены примеры использования этого."

L["Macro_Example1"] = [[#showtooltip
#FrameSort Mouseover, Target, Healer
/cast [@mouseover,help][@target,help][@healer,exists] Благословение убежища]]

L["Macro_Example2"] = [[#showtooltip
#FrameSort Frame1, Frame2, Player
/cast [mod:ctrl,@frame1][mod:shift,@frame2][mod:alt,@player][] Рассеивание]]

L["Macro_Example3"] = [[#FrameSort EnemyHealer, EnemyHealer
/cast [@doesntmatter] Шаг в тень;
/cast [@placeholder] Удар;]]

L["Example %d"] = "Пример %d"
L["Supported variables:"] = "Поддерживаемые переменные:"
L["The first DPS that's not you."] = "Первый ДД, который не вы."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "Добавьте номер, чтобы выбрать N-ную цель, например, DPS2 выбирает второго ДД."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] = "Переменные нечувствительны к регистру, поэтому 'fRaMe1', 'Dps', 'enemyhealer' и т.д. будут работать."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "Нужно сэкономить на символах макросов? Используйте сокращения для их укорочения:"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = 'Используйте "X", чтобы сказать FrameSort игнорировать селектор @unit:'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Заклинание;]]

-- # Spacing screen #
L["Spacing"] = "Промежутки"
L["Add some spacing between party, raid, and arena frames."] = "Добавьте промежутки между фреймами группы/рейда."
L["This only applies to Blizzard frames."] = "Это применимо только к фреймам Blizzard."
L["Party"] = "Группа"
L["Raid"] = "Рейд"
L["Group"] = "Группа"
L["Horizontal"] = "Горизонтальный"
L["Vertical"] = "Вертикальный"

-- # Addons screen #
L["Addons"] = "Дополнения"
L["Addons_Supported_Description"] = [[
FrameSort поддерживает следующее:
\n
Blizzard
 - Группа: да
 - Рейд: да
 - Арена: да
\n
ElvUI
 - Группа: да
 - Рейд: нет
 - Арена: нет
\n
sArena
 - Арена: да
\n
Gladius
 - Арена: да
 - Версия Bicmex: да
\n
GladiusEx
 - Группа: да
 - Арена: да
\n
Cell
 - Группа: да
 - Рейд: да, только при использовании объединённых групп.
\n
Shadowed Unit Frames
 - Группа: да
 - Арена: да
\n
Grid2
 - Группа/рейд: да
\n
]]

-- # Api screen #
L["Api"] = "Api"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "Хотите интегрировать FrameSort в свои дополнения, скрипты и Weak Auras?"
L["Here are some examples."] = "Вот некоторые примеры."
L["Retrieved an ordered array of party/raid unit tokens."] = "Получен упорядоченный массив токенов группы/рейда."
L["Retrieved an ordered array of arena unit tokens."] = "Получен упорядоченный массив токенов арены."
L["Register a callback function to run after FrameSort sorts frames."] = "Зарегистрируйте функцию обратного вызова, которая будет выполняться после сортировки фреймов FrameSort."
L["Retrieve an ordered array of party frames."] = "Получить упорядоченный массив фреймов группы."
L["Change a FrameSort setting."] = "Изменить настройку FrameSort."
L["View a full listing of all API methods on GitHub."] = "Посмотреть полный список всех методов API на GitHub."

-- # Help screen #
L["Help"] = "Помощь"
L["Discord"] = "Дискорд"
L["Need help with something?"] = "Нужна помощь с чем-то?"
L["Talk directly with the developer on Discord."] = "Обсудите напрямую с разработчиком в Дискорде."

-- # Health Check screen -- #
L["Health Check"] = "Проверка состояния"
L["Try this"] = "Попробуйте это"
L["Any known issues with configuration or conflicting addons will be shown below."] = "Все известные проблемы с конфигурацией или конфликтующими дополнениями будут показаны ниже."
L["N/A"] = "Не применимо"
L["Passed!"] = "Пройдено!"
L["Failed"] = "Не удалось"
L["(unknown)"] = "(неизвестно)"
L["(user macro)"] = "(пользовательский макрос)"
L["Using grouped layout for Cell raid frames"] = "Используется сгруппированная компоновка для рейдовых фреймов Cell"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Пожалуйста, проверьте параметр 'Объединённые группы (рейд)' в Cell -> Компоновки"
L["Can detect frames"] = "Может обнаружить фреймы"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort в настоящее время поддерживает фреймы из этих дополнений: %s"
L["Using Raid-Style Party Frames"] = "Использование рейдового стиля для фреймов группы"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "Пожалуйста, включите 'Использовать рейдовые фреймы группы' в настройках Blizzard"
L["Keep Groups Together setting disabled"] = "Настройка 'Держать группы вместе' отключена"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "Измените режим отображения рейда на один из вариантов 'Объединённые группы' через Режим редактирования"
L["Disable the 'Keep Groups Together' raid profile setting."] = "Отключите настройку профиля рейда 'Держать группы вместе'."
L["Only using Blizzard frames with Traditional mode"] = "Используются только фреймы Blizzard в традиционном режиме"
L["Traditional mode can't sort your other frame addons: '%s'"] = "Традиционный режим не может сортировать ваши другие дополнения для фреймов: '%s'"
L["Using Secure sorting mode when spacing is being used"] = "Используется безопасный режим сортировки, когда используются промежутки."
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] = "Традиционный режим не может применять промежутки, рассмотрите возможность их удаления или использования безопасного метода сортировки"
L["Blizzard sorting functions not tampered with"] = "Функции сортировки Blizzard не изменены"
L['"%s" may cause conflicts, consider disabling it'] = '"%s" может вызвать конфликты, рассмотрите возможность его отключения'
L["No conflicting addons"] = "Нет конфликтующих дополнений"
L["Main tank and assist setting disabled"] = "Настройка основного танка и ассистента отключена"
L["Please disable the 'Display Main Tank and Assist' option in Options -> Interface -> Raid Frames"] = "Пожалуйста, отключите опцию 'Отображать основного танка и ассистента' в Настройки -> Интерфейс -> Рейдовые фреймы"
