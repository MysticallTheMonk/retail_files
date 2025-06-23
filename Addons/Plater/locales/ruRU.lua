do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "ruRU")
    local L = languageTable

------------------------------------------------------------
L["A /reload may be required to take effect."] = "Может потребоваться /reload для применения изменений."
L["CVar, saved within Plater profile and restored when loading the profile."] = "CVar, сохраняется в профиле Plater и восстанавливается при загрузке профиля."
L["EXPORT"] = "Экспорт"
L["EXPORT_CAST_COLORS"] = "Поделиться Цветами"
L["EXPORT_CAST_SOUNDS"] = "Поделиться Звуками"
L["HIGHLIGHT_HOVEROVER"] = "Подсвечивание при наведении курсора"
L["HIGHLIGHT_HOVEROVER_ALPHA"] = "Степень подсвечивания при наведении курсора"
L["HIGHLIGHT_HOVEROVER_DESC"] = "Эффект подсвечивания при наведении курсора мыши над индикаторами здоровья"
--[[Translation missing --]]
L["Hold Shift to change the sound of all casts with the audio %s to %s"] = "Hold Shift to change the sound of all casts with the audio %s to %s"
L["IMPORT"] = "Импорт"
L["IMPORT_CAST_COLORS"] = "Импортировать Цвета"
L["IMPORT_CAST_SOUNDS"] = "Импортировать Звуки"
L["OPTIONS_ALPHA"] = "Прозрачность"
L["OPTIONS_ALPHABYFRAME_ALPHAMULTIPLIER"] = "Множитель прозрачности."
L["OPTIONS_ALPHABYFRAME_DEFAULT"] = "Прозрачность по умолчанию"
--[[Translation missing --]]
L["OPTIONS_ALPHABYFRAME_DEFAULT_DESC"] = "Amount of transparency applyed to all the components of a single nameplate."
L["OPTIONS_ALPHABYFRAME_ENABLE_ENEMIES"] = "Включить для врагов"
L["OPTIONS_ALPHABYFRAME_ENABLE_ENEMIES_DESC"] = "Применять настройки прозрачности для враждебных юнитов."
L["OPTIONS_ALPHABYFRAME_ENABLE_FRIENDLY"] = "Включить для союзников"
L["OPTIONS_ALPHABYFRAME_ENABLE_FRIENDLY_DESC"] = "Применять настройки прозрачности для союзных юнитов."
--[[Translation missing --]]
L["OPTIONS_ALPHABYFRAME_TARGET_INRANGE"] = "Target Alpha/In-Range"
L["OPTIONS_ALPHABYFRAME_TARGET_INRANGE_DESC"] = "Прозрачность для целей или находящихся в радиусе действия юнитов."
--[[Translation missing --]]
L["OPTIONS_ALPHABYFRAME_TITLE_ENEMIES"] = "Transparency Amount Per Frame (enemies)"
--[[Translation missing --]]
L["OPTIONS_ALPHABYFRAME_TITLE_FRIENDLY"] = "Transparency Amount Per Frame (friendly)"
L["OPTIONS_AMOUNT"] = "Значение"
L["OPTIONS_ANCHOR"] = "Крепление"
L["OPTIONS_ANCHOR_BOTTOM"] = "Снизу"
L["OPTIONS_ANCHOR_BOTTOMLEFT"] = "Внизу слева"
L["OPTIONS_ANCHOR_BOTTOMRIGHT"] = "Внизу справа"
L["OPTIONS_ANCHOR_CENTER"] = "Центр"
L["OPTIONS_ANCHOR_INNERBOTTOM"] = "Внутри снизу"
L["OPTIONS_ANCHOR_INNERLEFT"] = "Внутри слева"
L["OPTIONS_ANCHOR_INNERRIGHT"] = "Внутри справа"
L["OPTIONS_ANCHOR_INNERTOP"] = "Внутри сверху"
L["OPTIONS_ANCHOR_LEFT"] = "Слева"
L["OPTIONS_ANCHOR_RIGHT"] = "Справа"
L["OPTIONS_ANCHOR_TARGET_SIDE"] = "К какой стороне прикрепить."
L["OPTIONS_ANCHOR_TOP"] = "Сверху"
L["OPTIONS_ANCHOR_TOPLEFT"] = "Сверху слева"
L["OPTIONS_ANCHOR_TOPRIGHT"] = "Сверху cправо"
--[[Translation missing --]]
L["OPTIONS_AUDIOCUE_COOLDOWN"] = "Audio Cooldown"
--[[Translation missing --]]
L["OPTIONS_AUDIOCUE_COOLDOWN_DESC"] = [=[Amount of time in milliseconds to wait before playing the SAME audio again.

Prevents loud sounds from playing when two or more casts are happening at the same time.

Set to 0 to disable this feature.]=]
L["OPTIONS_AURA_DEBUFF_HEIGHT"] = "Высота иконки дебаффов."
L["OPTIONS_AURA_DEBUFF_WITH"] = "Ширина иконки дебаффов."
L["OPTIONS_AURA_HEIGHT"] = "Высота иконки дебаффов."
L["OPTIONS_AURA_SHOW_BUFFS"] = "Показывать Баффы"
L["OPTIONS_AURA_SHOW_BUFFS_DESC"] = "Показать ваши баффы на Личной полосе"
L["OPTIONS_AURA_SHOW_DEBUFFS"] = "Показывать Дебаффы"
L["OPTIONS_AURA_SHOW_DEBUFFS_DESC"] = "Показать ваши дебаффы на Личной полосе"
L["OPTIONS_AURA_WIDTH"] = "Ширина иконки дебаффов."
L["OPTIONS_AURAS_ENABLETEST"] = "Включите данную настройку, чтобы скрыть тестовые ауры, когда производите изменения на этой вкладке."
L["OPTIONS_AURAS_SORT"] = "Сортировать Ауры"
L["OPTIONS_AURAS_SORT_DESC"] = "Ауры от сортируются по оставшемуся времени действия (по умолчанию)"
L["OPTIONS_BACKGROUND_ALWAYSSHOW"] = "Всегда показывать фон"
L["OPTIONS_BACKGROUND_ALWAYSSHOW_DESC"] = "Включить отображение фона кликабельной зоны фрейма."
L["OPTIONS_BORDER_COLOR"] = "Цвет границы"
L["OPTIONS_BORDER_THICKNESS"] = "Толщина границы"
L["OPTIONS_BUFFFRAMES"] = "Рамки баффов"
L["OPTIONS_CANCEL"] = "Отмена"
L["OPTIONS_CAST_COLOR_CHANNELING"] = "Потоковое"
L["OPTIONS_CAST_COLOR_INTERRUPTED"] = "Прерываемое"
L["OPTIONS_CAST_COLOR_REGULAR"] = "Обычное"
L["OPTIONS_CAST_COLOR_SUCCESS"] = "Успешное"
L["OPTIONS_CAST_COLOR_UNINTERRUPTIBLE"] = "Непрерываемое"
L["OPTIONS_CAST_SHOW_TARGETNAME"] = "Показывать имя цели"
L["OPTIONS_CAST_SHOW_TARGETNAME_DESC"] = "Показывать цель к которой применяется заклинание (если она есть)"
L["OPTIONS_CAST_SHOW_TARGETNAME_TANK"] = "[ТАНК] Не показывать свое имя"
L["OPTIONS_CAST_SHOW_TARGETNAME_TANK_DESC"] = "Если вы танк, то при применении заклинания к вам ваше имя отображаться не будет"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_APPEARANCE"] = "Cast Bar Appearance"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_BLIZZCASTBAR"] = "Blizzard Cast Bar"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_COLORS"] = "Cast Bar Colors"
L["OPTIONS_CASTBAR_FADE_ANIM_ENABLED"] = "Включить анимации затухания"
L["OPTIONS_CASTBAR_FADE_ANIM_ENABLED_DESC"] = "Включить анимации затухания на старте и окончании произнесения заклинаний."
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_END"] = "На окончании"
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_END_DESC"] = "Когда каст заканчивается, это время, которое требуется полосе каста, чтобы перейти от прозрачности 100% к полной невидимости."
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_START"] = "На старте"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_START_DESC"] = "When a cast starts, this is the amount of time the cast bar takes to go from zero transparency to full opaque."
L["OPTIONS_CASTBAR_HEIGHT"] = "Высота полосы заклинаний"
L["OPTIONS_CASTBAR_HIDE_ENEMY"] = "Скрыть полосу заклинаний врага"
L["OPTIONS_CASTBAR_HIDE_FRIENDLY"] = "Скрыть полосу заклинаний союзников"
L["OPTIONS_CASTBAR_HIDEBLIZZARD"] = "Скрыть полосу заклинаний игрока от Blizzard"
L["OPTIONS_CASTBAR_ICON_CUSTOM_ENABLE"] = "Включить видоизменение иконки"
L["OPTIONS_CASTBAR_ICON_CUSTOM_ENABLE_DESC"] = "Если данный параметр отключен, Plater не будет видоизменять иконку заклинаний, оставляя эту возможность скриптам."
L["OPTIONS_CASTBAR_NO_SPELLNAME_LIMIT"] = "Не сокращать наименование заклинаний"
L["OPTIONS_CASTBAR_NO_SPELLNAME_LIMIT_DESC"] = "Наименование заклинания не будет обрезаться по ширине полосы заклинаний."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_QUICKHIDE"] = "Quick Hide Cast Bar"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_QUICKHIDE_DESC"] = "After the cast finishes, immediately hide the cast bar."
L["OPTIONS_CASTBAR_SPARK_HALF"] = "Половина искры"
L["OPTIONS_CASTBAR_SPARK_HALF_DESC"] = "Показывать только половину текстуры искры."
L["OPTIONS_CASTBAR_SPARK_HIDE_INTERRUPT"] = "Скрыть искру при прерывании"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_SPARK_SETTINGS"] = "Spark Settings"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_SPELLICON"] = "Spell Icon"
L["OPTIONS_CASTBAR_TOGGLE_TEST"] = "Тест полосы заклинаний"
L["OPTIONS_CASTBAR_TOGGLE_TEST_DESC"] = "Активировать тестовую полосу заклинаний, нажмите снова для остановки теста"
L["OPTIONS_CASTBAR_WIDTH"] = "Ширина полосы заклинаний."
--[[Translation missing --]]
L["OPTIONS_CASTCOLORS_DISABLE_SOUNDS"] = "Remove All Sounds"
--[[Translation missing --]]
L["OPTIONS_CASTCOLORS_DISABLE_SOUNDS_CONFIRM"] = "Are you sure you want to remove all configured cast sounds?"
--[[Translation missing --]]
L["OPTIONS_CASTCOLORS_DISABLECOLORS"] = "Disable All Colors"
--[[Translation missing --]]
L["OPTIONS_CASTCOLORS_DISABLECOLORS_CONFIRM"] = "Confirm disable all cast colors?"
L["OPTIONS_CLICK_SPACE_HEIGHT"] = "Высота области допустимая при выборе цели кликом мышью."
L["OPTIONS_CLICK_SPACE_WIDTH"] = "Ширина области допустимая при выборе цели кликом мышью."
L["OPTIONS_COLOR"] = "Цвет"
L["OPTIONS_COLOR_BACKGROUND"] = "Цвет фона"
L["OPTIONS_CVAR_ENABLE_PERSONAL_BAR"] = "Личные полосы здоровья и маны|cFFFF7700*|r"
L["OPTIONS_CVAR_ENABLE_PERSONAL_BAR_DESC"] = [=[Показывать миниатюрную полосу здоровья и маны над вашим персонажем.
|cFFFF7700[*]|r |cFFa0a0a0CVar, сохраняются в профиле Plater'а и восстанавливаются при его загрузке.|r]=]
L["OPTIONS_CVAR_NAMEPLATES_ALWAYSSHOW"] = "Всегда показывать полосы здоровья|cFFFF7700*|r"
L["OPTIONS_CVAR_NAMEPLATES_ALWAYSSHOW_DESC"] = "Показывать полосы здоровья для всех юнитов поблизости. В отключённом режиме показывает только юнитов в бою. |cFFFF7700[*]|r |cFFa0a0a0CVar, сохраняется в Plater профиле и загружается с профилем.|r"
L["OPTIONS_ENABLED"] = "Включить"
L["OPTIONS_ERROR_CVARMODIFY"] = "консольные настройки нельзя изменять в бою."
L["OPTIONS_ERROR_EXPORTSTRINGERROR"] = "не удалось экспортировать"
--[[Translation missing --]]
L["OPTIONS_EXECUTERANGE"] = "Execute Range"
--[[Translation missing --]]
L["OPTIONS_EXECUTERANGE_DESC"] = [=[Show an indicator when the target unit is in 'execute' range.

If the detection does not work after a patch, communicate at Discord.]=]
--[[Translation missing --]]
L["OPTIONS_EXECUTERANGE_HIGH_HEALTH"] = "Execute Range (high heal)"
--[[Translation missing --]]
L["OPTIONS_EXECUTERANGE_HIGH_HEALTH_DESC"] = [=[Show the execute indicator for the high portion of the health.

If the detection does not work after a patch, communicate at Discord.]=]
L["OPTIONS_FONT"] = "Шрифт"
L["OPTIONS_FORMAT_NUMBER"] = "Формат цифр"
L["OPTIONS_FRIENDLY"] = "Дружественные"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_ANCHOR_TITLE"] = "Внешний вид полосы здоровья"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_BGCOLOR"] = "Цвет фона полосы здоровья и прозрачности"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_BGTEXTURE"] = "Текстура фона полосы здоровья"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_TEXTURE"] = "Текстура полосы здоровья"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_ANCHOR_TITLE"] = "Контроль прозрачности"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_RANGECHECK"] = "Проверка дальности"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_RANGECHECK_ALPHA"] = "Величина прозрачности"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_RANGECHECK_SPEC_DESC"] = "Заклинание для проверки дальности на эту специализацию."
L["OPTIONS_HEALTHBAR"] = "Полоса Здоровья"
L["OPTIONS_HEALTHBAR_HEIGHT"] = "Высота полосы здоровья"
--[[Translation missing --]]
L["OPTIONS_HEALTHBAR_SIZE_GLOBAL_DESC"] = [=[Change the size of Enemy and Friendly nameplates for players and npcs in combat and out of combat.

Each one of these options can be changed individually on Enemy Npc, Enemy Player tabs.]=]
L["OPTIONS_HEALTHBAR_WIDTH"] = "Ширина полосы здоровья"
L["OPTIONS_HEIGHT"] = "Высота"
L["OPTIONS_HOSTILE"] = "Враждебные"
L["OPTIONS_ICON_ELITE"] = "Иконка Элиты"
L["OPTIONS_ICON_ENEMYCLASS"] = "Иконка Класса врага"
L["OPTIONS_ICON_ENEMYFACTION"] = "Иконка Фракции врага"
L["OPTIONS_ICON_ENEMYSPEC"] = "Иконка Специализации врага"
L["OPTIONS_ICON_FRIENDLY_SPEC"] = "Иконка Специализации союзника"
L["OPTIONS_ICON_FRIENDLYCLASS"] = "Дружественный Класс"
L["OPTIONS_ICON_FRIENDLYFACTION"] = "Иконка Фракции союзника"
L["OPTIONS_ICON_PET"] = "Иконка Питомца"
L["OPTIONS_ICON_QUEST"] = "Иконка Квеста"
L["OPTIONS_ICON_RARE"] = "Иконка Рарника"
L["OPTIONS_ICON_SHOW"] = "Показать иконку"
L["OPTIONS_ICON_SIDE"] = "Сторона отображения"
L["OPTIONS_ICON_SIZE"] = "Размер отображения"
L["OPTIONS_ICON_WORLDBOSS"] = "Иконка Мирового Босса"
--[[Translation missing --]]
L["OPTIONS_ICONROWSPACING"] = "Icon Row Spacing"
L["OPTIONS_ICONSPACING"] = "Пробел между иконками"
L["OPTIONS_INDICATORS"] = "Индикаторы"
--[[Translation missing --]]
L["OPTIONS_INTERACT_OBJECT_NAME_COLOR"] = "Game object name color"
--[[Translation missing --]]
L["OPTIONS_INTERACT_OBJECT_NAME_COLOR_DESC"] = "Names on objects will get this color."
L["OPTIONS_INTERRUPT_FILLBAR"] = "Заполнять полосу заклинания при прерывании"
--[[Translation missing --]]
L["OPTIONS_INTERRUPT_SHOW_ANIM"] = "Play Interrupt Animation"
L["OPTIONS_INTERRUPT_SHOW_AUTHOR"] = "Показывать кто прервал"
--[[Translation missing --]]
L["OPTIONS_MINOR_SCALE_DESC"] = "Slightly adjust the size of nameplates when showing a minor unit (these units has a smaller nameplate by default)."
--[[Translation missing --]]
L["OPTIONS_MINOR_SCALE_HEIGHT"] = "Minor Unit Height Scale"
--[[Translation missing --]]
L["OPTIONS_MINOR_SCALE_WIDTH"] = "Minor Unit Width Scale"
L["OPTIONS_MOVE_HORIZONTAL"] = "Переместить по горизонтали."
L["OPTIONS_MOVE_VERTICAL"] = "Переместить по вертикали."
L["OPTIONS_NAMEPLATE_HIDE_FRIENDLY_HEALTH"] = "Скрыть полосы здоровья Blizzard|cFFFF7700*|r"
L["OPTIONS_NAMEPLATE_HIDE_FRIENDLY_HEALTH_DESC"] = "Пока в подземельях или рейдах, если дружественные полосы здоровья включены, будет показываться только имя игрока. Если любой из модулей Plater отключён, эта настройка будет так же влиять на эти полосы.|cFFFF7700[*]|r |cFFa0a0a0CVar, сохраняется в профиле Plater и загружается с профилем. |r |cFFFF2200[*]|r |cFFa0a0a0A /reload может понадобиться, что бы начало работать.|r"
L["OPTIONS_NAMEPLATE_OFFSET"] = "Слегка изменить всю полосу здоровья"
L["OPTIONS_NAMEPLATE_SHOW_ENEMY"] = "Показывать индикаторы здоровья врагов|cFFFF7700*|r"
L["OPTIONS_NAMEPLATE_SHOW_ENEMY_DESC"] = "Показывать полосы здоровья для врагов и нейтральных юнитов. |cFFFF7700[*]|r |cFFa0a0a0CVar, сохраняется в профиле Plater и загружается с ним.|r"
L["OPTIONS_NAMEPLATE_SHOW_FRIENDLY"] = "Показывать индикаторы здоровья союзников|cFFFF7700*|r"
L["OPTIONS_NAMEPLATE_SHOW_FRIENDLY_DESC"] = "Показывать полосы здоровья для дружественных игроков.  |cFFFF7700[*]|r |cFFa0a0a0CVar, сохраняется в профиле Plater и загружается с ним.|r"
--[[Translation missing --]]
L["OPTIONS_NAMEPLATES_OVERLAP"] = "Nameplate Overlap (V)|cFFFF7700*|r"
--[[Translation missing --]]
L["OPTIONS_NAMEPLATES_OVERLAP_DESC"] = [=[The space between each nameplate vertically when stacking is enabled.

|cFFFFFFFFDefault: 1.10|r

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r

|cFFFFFF00Important |r: if you find issues with this setting, use:
|cFFFFFFFF/run SetCVar ('nameplateOverlapV', '1.6')|r]=]
L["OPTIONS_NAMEPLATES_STACKING"] = "Наложение индикаторов здоровья|cFFFF7700*|r"
L["OPTIONS_NAMEPLATES_STACKING_DESC"] = [=[Если включено, то индикаторы здоровья не будут накладываться друг на друга.

|cFFFF7700[*]|r |cFFa0a0a0CVar, сохраняются в профиле Plater'а и восстанавливаются при его загрузке.|r

|cFFFFFF00Важно |r: для настройки расстояния между индикаторами посмотрите настройку ниже '|cFFFFFFFFNameplate Overlap|r'. Пожалуйста, проверьте вкладку настроек "Автоматизация", чтобы настроить автоматическое переключение данной настройки при заданных условиях.]=]
L["OPTIONS_NEUTRAL"] = "Нейтральные"
--[[Translation missing --]]
L["OPTIONS_NOCOMBATALPHA_AMOUNT_DESC"] = "Amount of transparency for 'No Combat Alpha'."
--[[Translation missing --]]
L["OPTIONS_NOCOMBATALPHA_ENABLED"] = "Use No Combat Alpha"
--[[Translation missing --]]
L["OPTIONS_NOCOMBATALPHA_ENABLED_DESC"] = [=[Changes the nameplate alpha when you are in combat and the unit isn't.

|cFFFFFF00 Important |r:If the unit isn't in combat, it overrides the alpha from the range check.]=]
--[[Translation missing --]]
L["OPTIONS_NOESSENTIAL_DESC"] = [=[On updating Plater, it is common for the new version to also update scripts from the scripts tab.
This may sometimes overwrite changes made by the creator of the profile. The option below prevents Plater from modifying scripts when the addon receives an update.

Note: During major patches and bug fixes, Plater may still update scripts.]=]
--[[Translation missing --]]
L["OPTIONS_NOESSENTIAL_NAME"] = "Disable non-essential script updates during Plater version upgrades."
--[[Translation missing --]]
L["OPTIONS_NOESSENTIAL_SKIP_ALERT"] = "Skipped non-essential patch:"
--[[Translation missing --]]
L["OPTIONS_NOESSENTIAL_TITLE"] = "Skip Non Essential Script Patches"
--[[Translation missing --]]
L["OPTIONS_NOTHING_TO_EXPORT"] = "There's nothing to export."
L["OPTIONS_OKAY"] = "Ок"
L["OPTIONS_OUTLINE"] = "Контур"
L["OPTIONS_PERSONAL_HEALTHBAR_HEIGHT"] = "Высота полосы здоровья."
L["OPTIONS_PERSONAL_HEALTHBAR_WIDTH"] = "Ширина полосы здоровья."
L["OPTIONS_PERSONAL_SHOW_HEALTHBAR"] = "Показывать полосу здоровья."
--[[Translation missing --]]
L["OPTIONS_PET_SCALE_DESC"] = "Slightly adjust the size of nameplates when showing a pet"
L["OPTIONS_PET_SCALE_HEIGHT"] = "Высота шкалы питомца"
L["OPTIONS_PET_SCALE_WIDTH"] = "Ширина шкалы питомца"
L["OPTIONS_PLEASEWAIT"] = "Подождите несколько секунд"
L["OPTIONS_POWERBAR"] = "Полоса ресурса"
L["OPTIONS_POWERBAR_HEIGHT"] = "Высота полосы ресурса"
L["OPTIONS_POWERBAR_WIDTH"] = "Ширина полосы ресурса"
L["OPTIONS_PROFILE_CONFIG_EXPORTINGTASK"] = "Plater экспортирует текущий профиль"
L["OPTIONS_PROFILE_CONFIG_EXPORTPROFILE"] = "Экспорт профиля"
L["OPTIONS_PROFILE_CONFIG_IMPORTPROFILE"] = "Импорт профиля"
L["OPTIONS_PROFILE_CONFIG_MOREPROFILES"] = "Еще больше профилей на Wago.io"
L["OPTIONS_PROFILE_CONFIG_OPENSETTINGS"] = "Открыть настройки профиля"
L["OPTIONS_PROFILE_CONFIG_PROFILENAME"] = "Новое имя профиля"
L["OPTIONS_PROFILE_CONFIG_PROFILENAME_DESC"] = [=[С импортированной строкой создается новый профиль.

Если ввести имя профиля, который сейчас работает, тогда он перезаписаться.]=]
L["OPTIONS_PROFILE_ERROR_PROFILENAME"] = "Неверное имя профиля"
L["OPTIONS_PROFILE_ERROR_STRINGINVALID"] = "Неверный файл профиля."
L["OPTIONS_PROFILE_ERROR_WRONGTAB"] = [=[Неверный файл профиля.

Импорт 'Своего кода' или 'Улучшение Platera' можно найти в меню.]=]
L["OPTIONS_PROFILE_IMPORT_OVERWRITE"] = "Профиль '%s' уже существует, перезаписать его?"
L["OPTIONS_RANGECHECK_NONE"] = "Отсутствует"
L["OPTIONS_RANGECHECK_NONE_DESC"] = "Настройки прозрачности не применяются."
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_NOTMYTARGET"] = "Units Which Isn't Your Target"
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_NOTMYTARGET_DESC"] = "When a nameplate isn't your current target, alpha is reduced."
L["OPTIONS_RANGECHECK_NOTMYTARGETOUTOFRANGE"] = "Вне радиуса + Не моя цель"
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_NOTMYTARGETOUTOFRANGE_DESC"] = [=[Reduces the alpha of units which isn't your target.
Reduces even more if the unit is out of range.]=]
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_OUTOFRANGE"] = "Units Out of Your Range"
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_OUTOFRANGE_DESC"] = "When a nameplate is out of range, alpha is reduced."
L["OPTIONS_RESOURCES_TARGET"] = "Показывать ресурсы на Цели"
--[[Translation missing --]]
L["OPTIONS_RESOURCES_TARGET_DESC"] = [=[Shows your resource such as combo points above your current target.
Uses Blizzard default resources and disables Platers own resources.

Character specific setting!]=]
L["OPTIONS_SCALE"] = "Масштаб"
--[[Translation missing --]]
L["OPTIONS_SCRIPTING_ADDOPTION"] = "Select which option to add"
L["OPTIONS_SCRIPTING_REAPPLY"] = "Применить значения по умолчанию"
L["OPTIONS_SETTINGS_COPIED"] = "настройки скопированы."
L["OPTIONS_SETTINGS_FAIL_COPIED"] = "не удалось получить настройки для текущей выбранной вкладки."
L["OPTIONS_SHADOWCOLOR"] = "Цвет тени"
L["OPTIONS_SHIELD_BAR"] = "Полоса Щита"
L["OPTIONS_SHOW_CASTBAR"] = "Показывать полосу заклинаний"
--[[Translation missing --]]
L["OPTIONS_SHOW_POWERBAR"] = "Show power bar"
L["OPTIONS_SHOWOPTIONS"] = "Показать Настройки"
L["OPTIONS_SHOWSCRIPTS"] = "Показать Скрипты"
L["OPTIONS_SHOWTOOLTIP"] = "Показывать описание"
--[[Translation missing --]]
L["OPTIONS_SHOWTOOLTIP_DESC"] = "Show tooltip when hovering over the aura icon."
L["OPTIONS_SIZE"] = "Размер"
--[[Translation missing --]]
L["OPTIONS_STACK_AURATIME"] = "Show shortest time of stacked auras"
--[[Translation missing --]]
L["OPTIONS_STACK_AURATIME_DESC"] = "Show shortest time of stacked auras or the longes time, when disabled."
--[[Translation missing --]]
L["OPTIONS_STACK_SIMILAR_AURAS"] = "Stack Similar Auras"
--[[Translation missing --]]
L["OPTIONS_STACK_SIMILAR_AURAS_DESC"] = "Auras with the same name (e.g. warlock's unstable affliction debuff) get stacked together."
L["OPTIONS_STATUSBAR_TEXT"] = "Теперь можно импортировать профили, моды, скрипты, анимации и таблицы цветов на |cFFFFAA00http://wago.io|r"
L["OPTIONS_TABNAME_ADVANCED"] = "Дополнительные"
L["OPTIONS_TABNAME_ANIMATIONS"] = "Анимации"
L["OPTIONS_TABNAME_AUTO"] = "Автоматизация"
L["OPTIONS_TABNAME_BUFF_LIST"] = "Список заклинаний"
L["OPTIONS_TABNAME_BUFF_SETTINGS"] = "Настройки баффов"
L["OPTIONS_TABNAME_BUFF_SPECIAL"] = "Особые баффы"
L["OPTIONS_TABNAME_BUFF_TRACKING"] = "Отслеж.баффов"
L["OPTIONS_TABNAME_CASTBAR"] = "Полоса заклинаний"
L["OPTIONS_TABNAME_CASTCOLORS"] = [=[Цвета и Наимен.
Полос заклинаний]=]
L["OPTIONS_TABNAME_COMBOPOINTS"] = "Комбо Очки"
L["OPTIONS_TABNAME_GENERALSETTINGS"] = "Общие настройки"
L["OPTIONS_TABNAME_MODDING"] = "Моды"
L["OPTIONS_TABNAME_NPC_COLORNAME"] = [=[Цвета и Имена
NPC]=]
L["OPTIONS_TABNAME_NPCENEMY"] = "Вражеские NPC"
L["OPTIONS_TABNAME_NPCFRIENDLY"] = "Союзные NPC"
L["OPTIONS_TABNAME_PERSONAL"] = "Личная полоса"
L["OPTIONS_TABNAME_PLAYERENEMY"] = "Вражеские игроки"
L["OPTIONS_TABNAME_PLAYERFRIENDLY"] = "Союзные игроки"
L["OPTIONS_TABNAME_PROFILES"] = "Профили"
L["OPTIONS_TABNAME_SCRIPTING"] = "Скрипты"
L["OPTIONS_TABNAME_SEARCH"] = "Поиск"
L["OPTIONS_TABNAME_STRATA"] = "Уровень и слой"
L["OPTIONS_TABNAME_TARGET"] = "Цель"
L["OPTIONS_TABNAME_THREAT"] = [=[Настройка цвета
АГГРО]=]
L["OPTIONS_TEXT_COLOR"] = "Цвет текста."
L["OPTIONS_TEXT_FONT"] = "Шрифт текста."
L["OPTIONS_TEXT_SIZE"] = "Размер текста"
L["OPTIONS_TEXTURE"] = "Текстура"
L["OPTIONS_TEXTURE_BACKGROUND"] = "Текстура фона"
L["OPTIONS_THREAT_AGGROSTATE_ANOTHERTANK"] = "Угроза на другом танке"
L["OPTIONS_THREAT_AGGROSTATE_HIGHTHREAT"] = "Высокая угроза"
L["OPTIONS_THREAT_AGGROSTATE_NOAGGRO"] = "Отсутствует угроза"
L["OPTIONS_THREAT_AGGROSTATE_NOTANK"] = "Отсутствует угроза от танка"
L["OPTIONS_THREAT_AGGROSTATE_NOTINCOMBAT"] = "Юнит не в бою"
L["OPTIONS_THREAT_AGGROSTATE_ONYOU_LOWAGGRO"] = "Аггро на вас, но оно слабое"
L["OPTIONS_THREAT_AGGROSTATE_ONYOU_LOWAGGRO_DESC"] = "Юниты атакуют вас, но другие срывают аггро."
L["OPTIONS_THREAT_AGGROSTATE_ONYOU_SOLID"] = "Аггро на вас"
L["OPTIONS_THREAT_AGGROSTATE_TAPPED"] = "Перехваченный юнит"
L["OPTIONS_THREAT_CLASSIC_USE_TANK_COLORS"] = "Использовать танковские цвета угрозы"
L["OPTIONS_THREAT_COLOR_DPS_ANCHOR_TITLE"] = "Окрас при игре за БОЙЦА или ЛЕКАРЯ"
L["OPTIONS_THREAT_COLOR_DPS_HIGHTHREAT_DESC"] = "Юнит начинает атаковать вас."
L["OPTIONS_THREAT_COLOR_DPS_NOAGGRO_DESC"] = "Юнит не атакует вас."
L["OPTIONS_THREAT_COLOR_DPS_NOTANK_DESC"] = "Юнит атакует не вас или танка, а скорее всего атакует других лекаря или бойца из вашей группы."
L["OPTIONS_THREAT_COLOR_DPS_ONYOU_SOLID_DESC"] = "Юнит атакует вас."
L["OPTIONS_THREAT_COLOR_OVERRIDE_ANCHOR_TITLE"] = "Переопределить цвета по умолчанию"
L["OPTIONS_THREAT_COLOR_OVERRIDE_DESC"] = [=[Измените стандартные цветовые настройки для нейтральных, враждебных и дружелюбных юнитов.

Во время боя эти цвета также будут переопределены, если разрешено изменять цвет полосы здоровья в зависимости от уровня угрозы.]=]
L["OPTIONS_THREAT_COLOR_TANK_ANCHOR_TITLE"] = "Окрашивать при игре в качестве танка"
L["OPTIONS_THREAT_COLOR_TANK_ANOTHERTANK_DESC"] = "Моба танкует другой танк из вашей группы."
L["OPTIONS_THREAT_COLOR_TANK_NOAGGRO_DESC"] = "У моба нет угрозы на вас."
L["OPTIONS_THREAT_COLOR_TANK_NOTINCOMBAT_DESC"] = "Моб не в бою."
L["OPTIONS_THREAT_COLOR_TANK_ONYOU_SOLID_DESC"] = "Моб атакует вас, и на вас сильная угроза."
L["OPTIONS_THREAT_COLOR_TAPPED_DESC"] = "Когда кто-то нанес большой урон или вы, не в той группе (когда вы не получаете опыт или добычу за его убийство)."
L["OPTIONS_THREAT_DPS_CANCHECKNOTANK"] = "Проверка на отсутствие угрозы от танка"
L["OPTIONS_THREAT_DPS_CANCHECKNOTANK_DESC"] = "Если на вас нет угрозы в качестве целителя или бойца, проверка, атакует ли враг другую пати, в который нет танка."
L["OPTIONS_THREAT_MODIFIERS_ANCHOR_TITLE"] = "Изменение угрозы"
L["OPTIONS_THREAT_MODIFIERS_BORDERCOLOR"] = "Цветная граница"
L["OPTIONS_THREAT_MODIFIERS_HEALTHBARCOLOR"] = "Цвет полосы здоровья"
L["OPTIONS_THREAT_MODIFIERS_NAMECOLOR"] = "Окрашивать имена"
--[[Translation missing --]]
L["OPTIONS_THREAT_PULL_FROM_ANOTHER_TANK"] = "Pulling From Another Tank"
L["OPTIONS_THREAT_PULL_FROM_ANOTHER_TANK_TANK"] = "У юнита есть агро на другом танке, и вы собираетесь его перетянуть."
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_AGGRO_FLASH"] = "Enable aggro flash"
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_AGGRO_FLASH_DESC"] = "Enables the -AGGRO- flash animation on the nameplates when gaining aggro as dps."
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_AGGRO_GLOW"] = "Enable aggro glow"
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_AGGRO_GLOW_DESC"] = "Enables the healthbar glow on the nameplates when gaining aggro as dps or losing aggro as tank."
L["OPTIONS_THREAT_USE_SOLO_COLOR"] = "\"Соло\" цвет"
L["OPTIONS_THREAT_USE_SOLO_COLOR_DESC"] = "Использовать \"Соло\" цвет при одиночной игре (вне группы)."
L["OPTIONS_THREAT_USE_SOLO_COLOR_ENABLE"] = "Использовать \"Соло\" цвет"
L["OPTIONS_TOGGLE_TO_CHANGE"] = "|cFFFFFF00 Important |r: скрыть и показать индикаторы здоровья для просмотра изменений."
L["OPTIONS_WIDTH"] = "Ширина"
L["OPTIONS_XOFFSET"] = "Cмещ X"
L["OPTIONS_XOFFSET_DESC"] = [=[Регулировка положения по оси X.
*щелкните правой кнопкой мыши, чтобы ввести значение.]=]
L["OPTIONS_YOFFSET"] = "Смещ Y"
L["OPTIONS_YOFFSET_DESC"] = [=[Регулировка положения по оси Y.
*щелкните правой кнопкой мыши, чтобы ввести значение.]=]
--[[Translation missing --]]
L[ [=[Show nameplate for friendly npcs.

|cFFFFFF00 Important |r: This option is dependent on the client`s nameplate state (on/off).

|cFFFFFF00 Important |r: when disabled but enabled on the client through (%s), the healthbar isn't visible but the nameplate is still clickable.]=] ] = [=[Show nameplate for friendly npcs.

|cFFFFFF00 Important |r: This option is dependent on the client`s nameplate state (on/off).

|cFFFFFF00 Important |r: when disabled but enabled on the client through (%s), the healthbar isn't visible but the nameplate is still clickable.]=]
L["TARGET_CVAR_ALWAYSONSCREEN"] = "Цель ВСЕГДА на экране|cFFFF7700*|r"
--[[Translation missing --]]
L["TARGET_CVAR_ALWAYSONSCREEN_DESC"] = [=[When enabled, the nameplate of your target is always shown even when the enemy isn't in the screen.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r]=]
L["TARGET_CVAR_LOCKTOSCREEN"] = "Прикрепить к экрану (в верхней части)|cFFFF7700*|r"
--[[Translation missing --]]
L["TARGET_CVAR_LOCKTOSCREEN_DESC"] = [=[Min space between the nameplate and the top of the screen. Increase this if some part of the nameplate are going out of the screen.

|cFFFFFFFFDefault: 0.065|r

|cFFFFFF00 Important |r: if you're having issue, manually set using these macros:
/run SetCVar ('nameplateOtherTopInset', '0.065')
/run SetCVar ('nameplateLargeTopInset', '0.065')

|cFFFFFF00 Important |r: setting to 0 disables this feature.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r]=]
L["TARGET_HIGHLIGHT"] = "Подсвечивание цели"
L["TARGET_HIGHLIGHT_ALPHA"] = "Прозрачность текстуры подсвечивания цели"
L["TARGET_HIGHLIGHT_COLOR"] = "Цвет подсвечивания цели"
L["TARGET_HIGHLIGHT_DESC"] = "Эффект подсвечивания индикатора полосы здоровья вашей текущей цели."
L["TARGET_HIGHLIGHT_SIZE"] = "Размер текстуры подсвечивания цели"
L["TARGET_HIGHLIGHT_TEXTURE"] = "Текстура подсвечивания цели"
L["TARGET_OVERLAY_ALPHA"] = "Прозрачность текстуры оверлея цели"
L["TARGET_OVERLAY_TEXTURE"] = "Текстура оверлея цели"
L["TARGET_OVERLAY_TEXTURE_DESC"] = "Используется поверх полосы здоровья к текущей выбранной цели."

end