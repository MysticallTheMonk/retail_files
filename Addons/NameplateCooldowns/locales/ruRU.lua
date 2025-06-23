-- luacheck: no max line length
-- luacheck: globals LibStub

local L = LibStub("AceLocale-3.0"):NewLocale("NameplateCooldowns", "ruRU");
L = L or {} -- luacheck: ignore
--@non-debug@
L["anchor-point:bottom"] = "Снизу"
L["anchor-point:bottomleft"] = "Снизу слева"
L["anchor-point:bottomright"] = "Снизу справа"
L["anchor-point:center"] = "Центр"
L["anchor-point:left"] = "Слева"
L["anchor-point:right"] = "Справа"
L["anchor-point:top"] = "Сверху"
L["anchor-point:topleft"] = "Сверху слева"
L["anchor-point:topright"] = "Сверху справа"
L["anchor-point:x-offset"] = "Смещение по X"
L["anchor-point:y-offset"] = "Смещение по Y"
L["chat:addon-is-disabled-note"] = "Обратите внимание: этот аддон отключен. Вы можете включить его командой (/nc)"
L["chat:default-spell-is-added-to-ignore-list"] = "Заклинание добавлено в игнор-лист: %s. Вы не будете получать обновления кулдаунов для этого заклинания от разработчика."
L["chat:enable-only-for-target-nameplate"] = "КД будут показаны только на нэймплэйте цели"
L["chat:print-updated-spells"] = "%s: прошлое значение: %s сек., новое значение: %s сек."
L["Click on icon to enable/disable tracking"] = "Нажмите на иконку чтобы вкл/выкл отслеживание"
L["Copy"] = "Скопировать"
L["Copy other profile to current profile:"] = "Скопировать другой профиль в текущий:"
L["Current profile: [%s]"] = "Текущий профиль: [%s]"
L["Data from '%s' has been successfully copied to '%s'"] = "Профиль '%s' успешно скопирован в профиль '%s'"
L["Delete"] = "Удалить"
L["Delete profile:"] = "Удалить профиль:"
L["Filters"] = "Фильтры"
L["filters.instance-types"] = [=[Настроить видимость кулдаунов
в различных типах локаций]=]
L["Font:"] = "Шрифт:"
L["General"] = "Общее"
L["general.sort-mode"] = "Режим сортировки:"
L["Icon size"] = "Размер иконок"
L["Icon X-coord offset"] = "Смещение иконок по X"
L["Icon Y-coord offset"] = "Смещение иконок по Y"
L["icon-grow-direction:down"] = "Вниз"
L["icon-grow-direction:left"] = "Налево"
L["icon-grow-direction:right"] = "Направо"
L["icon-grow-direction:up"] = "Вверх"
L["instance-type:arena"] = "Арены"
L["instance-type:none"] = "Открытый мир"
L["instance-type:party"] = "Подземелья на 5 человек"
L["instance-type:pvp"] = "Поля битв"
--[[Translation missing --]]
L["instance-type:pvp_bg_40ppl"] = "Epic Battlegrounds"
L["instance-type:raid"] = "Рейдовые подземелья"
L["instance-type:scenario"] = "Сценарии"
L["instance-type:unknown"] = "Неизвестные типы подземелий"
L["MISC"] = "Другое"
L["msg:question:import-existing-spells"] = [=[NameplateCooldowns
Доступны обновленные значения кулдаунов для некоторых ваших заклинаний. Хотите применить обновление?]=]
L["New spell has been added: %s"] = "Добавлено новое заклинание: %s"
L["Options are not available in combat!"] = "Настройки недоступны, пока идет бой!"
L["options:borders:show-blizz-borders"] = "Показывать стандартные границы иконок"
--[[Translation missing --]]
L["options:building-cache"] = [=[Loading spells info (%s%%)...
Some functions may be unavailable]=]
L["options:category:borders"] = "Границы"
L["options:category:spells"] = "Заклинания"
L["options:category:text"] = "Текст"
L["options:general:anchor-point"] = "Точка привязки (якорь)"
L["options:general:anchor-point-to-parent"] = "Точка привязки (якорь) относительно родительского контейнера"
L["options:general:enable-only-for-target-nameplate"] = "Показывать КД только на нэймплэйте цели"
L["options:general:full-opacity-always"] = "Иконки всегда непрозрачны"
L["options:general:full-opacity-always:tooltip"] = "Если эта опция включена, иконки всегда будут полностью непрозрачными. Если нет, прозрачность будет соответствовать полосе здоровья"
L["options:general:icon-grow-direction"] = "Направление роста значков"
L["options:general:ignore-nameplate-scale"] = "Игнорировать масштаб неймплейта"
L["options:general:ignore-nameplate-scale:tooltip"] = "Если эта опция включена, размер иконки не будет меняться в соответствии с масштабом неймплейта (например, когда неймплейт вашей цели увеличивается)"
--[[Translation missing --]]
L["options:general:inverse-logic"] = "Inverse logic"
--[[Translation missing --]]
L["options:general:inverse-logic:tooltip"] = "Display icon if player IS ABLE to cast certain spell"
L["options:general:show-cd-on-allies"] = "Показывать КД на полосках ХП союзников"
--[[Translation missing --]]
L["options:general:show-cooldown-animation"] = "Enable cooldown animation"
--[[Translation missing --]]
L["options:general:show-cooldown-animation:tooltip"] = "Enables spin animation on cooldown icons"
--[[Translation missing --]]
L["options:general:show-cooldown-tooltip"] = "Show cooldown tooltip"
L["options:general:show-inactive-cd"] = "Показывать неактивные кулдауны"
L["options:general:show-inactive-cd:tooltip"] = [=[Обратите внимание: вы не будете видеть все доступные кулдауны!
Вы будете видеть только те кулдауны, которые противник уже использовал]=]
L["options:general:space-between-icons"] = "Расстояние между иконками (пикс.)"
--[[Translation missing --]]
L["options:general:test-mode"] = "Test mode"
--[[Translation missing --]]
L["options:profiles"] = "Profiles"
L["options:spells:add-new-spell"] = "Добавить заклинание (название или id):"
L["options:spells:add-spell"] = "Добавить"
L["options:spells:click-to-select-spell"] = "Нажмите, чтобы выбрать заклинание"
--[[Translation missing --]]
L["options:spells:click-to-select-spell:test-mode"] = "You can't edit spells in test mode"
L["options:spells:cooldown-time"] = "Значение кулдауна"
--[[Translation missing --]]
L["options:spells:custom-cooldown"] = "Custom cooldown value"
--[[Translation missing --]]
L["options:spells:custom-cooldown-value"] = "Cooldown (sec)"
L["options:spells:delete-all-spells"] = "Удалить все заклинания"
L["options:spells:delete-all-spells-confirmation"] = "Вы действительно хотите удалить ВСЕ заклинания?"
L["options:spells:delete-spell"] = "Удалить заклинание"
L["options:spells:disable-all-spells"] = "Отключить все способности"
L["options:spells:enable-all-spells"] = "Включить все способности"
L["options:spells:enable-tracking-of-this-spell"] = "Включить отслеживание этого заклинания"
L["options:spells:icon-glow"] = "Подсветка иконки выключена"
L["options:spells:icon-glow-always"] = "Подсветка иконки включена постоянно"
L["options:spells:icon-glow-threshold"] = [=[Иконка будет подсвечиваться если оставшееся
время кулдауна меньше чем]=]
L["options:spells:please-push-once-more"] = "Нажмите ещё раз"
L["options:spells:track-only-this-spellid"] = [=[Отслеживать только эти id заклинания
(разделять запятыми)]=]
L["options:text:anchor-point"] = "Точка привязки"
L["options:text:anchor-to-icon"] = "Точка привязки к иконке"
L["options:text:color"] = "Цвет текста"
L["options:text:font"] = "Шрифт"
L["options:text:font-scale"] = "Масштаб шрифта"
L["options:text:font-size"] = "Размер шрифта"
L["options:timer-text:scale-font-size"] = [=[Scale font size
according to
icon size]=]
L["Profile '%s' has been successfully deleted"] = "Профиль '%s' успешно удален"
L["Show border around interrupts"] = "Показывать контур вокруг прерываний"
L["Show border around trinkets"] = "Показывать контур вокруг тринкетов"
L["Unknown spell: %s"] = "Неизвестное заклинание: %s"
L["Value must be a number"] = "Значение должно быть числом"

--@end-non-debug@
--[==[@debug@
L = L or {} -- luacheck: ignore
L["anchor-point:bottom"] = "Снизу"
L["anchor-point:bottomleft"] = "Снизу слева"
L["anchor-point:bottomright"] = "Снизу справа"
L["anchor-point:center"] = "Центр"
L["anchor-point:left"] = "Слева"
L["anchor-point:right"] = "Справа"
L["anchor-point:top"] = "Сверху"
L["anchor-point:topleft"] = "Сверху слева"
L["anchor-point:topright"] = "Сверху справа"
L["anchor-point:x-offset"] = "Смещение по X"
L["anchor-point:y-offset"] = "Смещение по Y"
L["chat:addon-is-disabled"] = "Аддон отключен"
L["chat:addon-is-disabled-note"] = "Обратите внимание: этот аддон отключен. Вы можете включить его командой (/nc)"
L["chat:addon-is-enabled"] = "Аддон включен"
L["chat:default-spell-is-added-to-ignore-list"] = "Заклинание добавлено в игнор-лист: %s. Вы не будете получать обновления кулдаунов для этого заклинания от разработчика."
L["chat:enable-only-for-target-nameplate"] = "КД будут показаны только на нэймплэйте цели"
L["chat:print-updated-spells"] = "%s: прошлое значение: %s сек., новое значение: %s сек."
L["Click on icon to enable/disable tracking"] = "Нажмите на иконку чтобы вкл/выкл отслеживание"
L["Copy"] = "Скопировать"
L["Copy other profile to current profile:"] = "Скопировать другой профиль в текущий:"
L["Current profile: [%s]"] = "Текущий профиль: [%s]"
L["Data from '%s' has been successfully copied to '%s'"] = "Профиль '%s' успешно скопирован в профиль '%s'"
L["Delete"] = "Удалить"
L["Delete profile:"] = "Удалить профиль:"
L["Disable test mode"] = "Выключить тест"
L["Enable test mode (need at least one visible nameplate)"] = "Включить тест (нужен хотя бы 1 видимый хп бар)"
L["Filters"] = "Фильтры"
L["filters.instance-types"] = [=[Настроить видимость кулдаунов
в различных типах локаций]=]
L["Font:"] = "Шрифт:"
L["General"] = "Общее"
L["general.sort-mode"] = "Режим сортировки:"
L["Icon size"] = "Размер иконок"
L["Icon X-coord offset"] = "Смещение иконок по X"
L["Icon Y-coord offset"] = "Смещение иконок по Y"
L["icon-grow-direction:down"] = "Вниз"
L["icon-grow-direction:left"] = "Налево"
L["icon-grow-direction:right"] = "Направо"
L["icon-grow-direction:up"] = "Вверх"
L["instance-type:arena"] = "Арены"
L["instance-type:none"] = "Открытый мир"
L["instance-type:party"] = "Подземелья на 5 человек"
L["instance-type:pvp"] = "Поля битв"
L["instance-type:raid"] = "Рейдовые подземелья"
L["instance-type:scenario"] = "Сценарии"
L["instance-type:unknown"] = "Неизвестные типы подземелий"
L["MISC"] = "Другое"
L["msg:question:import-existing-spells"] = [=[NameplateCooldowns
Доступны обновленные значения кулдаунов для некоторых ваших заклинаний. Хотите применить обновление?]=]
L["New spell has been added: %s"] = "Добавлено новое заклинание: %s"
L["Options are not available in combat!"] = "Настройки недоступны, пока идет бой!"
L["options:borders:show-blizz-borders"] = "Показывать стандартные границы иконок"
L["options:category:borders"] = "Границы"
L["options:category:spells"] = "Заклинания"
L["options:category:text"] = "Текст"
L["options:general:anchor-point"] = "Точка привязки (якорь)"
L["options:general:anchor-point-to-parent"] = "Точка привязки (якорь) относительно родительского контейнера"
L["options:general:disable-addon-btn"] = "Отключить аддон"
L["options:general:enable-addon-btn"] = "Включить аддон"
L["options:general:enable-only-for-target-nameplate"] = "Показывать КД только на нэймплэйте цели"
L["options:general:full-opacity-always"] = "Иконки всегда непрозрачны"
L["options:general:full-opacity-always:tooltip"] = "Если эта опция включена, иконки всегда будут полностью непрозрачными. Если нет, прозрачность будет соответствовать полосе здоровья"
L["options:general:icon-grow-direction"] = "Направление роста значков"
L["options:general:ignore-nameplate-scale"] = "Игнорировать масштаб неймплейта"
L["options:general:ignore-nameplate-scale:tooltip"] = "Если эта опция включена, размер иконки не будет меняться в соответствии с масштабом неймплейта (например, когда неймплейт вашей цели увеличивается)"
L["options:general:show-cd-on-allies"] = "Показывать КД на полосках ХП союзников"
L["options:general:show-inactive-cd"] = "Показывать неактивные кулдауны"
L["options:general:show-inactive-cd:tooltip"] = [=[Обратите внимание: вы не будете видеть все доступные кулдауны!
Вы будете видеть только те кулдауны, которые противник уже использовал]=]
L["options:general:space-between-icons"] = "Расстояние между иконками (пикс.)"
L["options:profiles:open-profiles-dialog"] = "Открыть окно профилей"
L["options:spells:add-new-spell"] = "Добавить заклинание (название или id):"
L["options:spells:add-spell"] = "Добавить"
L["options:spells:click-to-select-spell"] = "Нажмите, чтобы выбрать заклинание"
L["options:spells:cooldown-time"] = "Значение кулдауна"
L["options:spells:delete-all-spells"] = "Удалить все заклинания"
L["options:spells:delete-all-spells-confirmation"] = "Вы действительно хотите удалить ВСЕ заклинания?"
L["options:spells:delete-spell"] = "Удалить заклинание"
L["options:spells:disable-all-spells"] = "Отключить все способности"
L["options:spells:enable-all-spells"] = "Включить все способности"
L["options:spells:enable-tracking-of-this-spell"] = "Включить отслеживание этого заклинания"
L["options:spells:icon-glow"] = "Подсветка иконки выключена"
L["options:spells:icon-glow-always"] = "Подсветка иконки включена постоянно"
L["options:spells:icon-glow-threshold"] = [=[Иконка будет подсвечиваться если оставшееся
время кулдауна меньше чем]=]
L["options:spells:please-push-once-more"] = "Нажмите ещё раз"
L["options:spells:track-only-this-spellid"] = [=[Отслеживать только эти id заклинания
(разделять запятыми)]=]
L["options:text:anchor-point"] = "Точка привязки"
L["options:text:anchor-to-icon"] = "Точка привязки к иконке"
L["options:text:color"] = "Цвет текста"
L["options:text:font"] = "Шрифт"
L["options:text:font-scale"] = "Масштаб шрифта"
L["options:text:font-size"] = "Размер шрифта"
L["options:timer-text:scale-font-size"] = [=[Scale font size
according to
icon size]=]
L["Profile '%s' has been successfully deleted"] = "Профиль '%s' успешно удален"
L["Profiles"] = "Профили"
L["Show border around interrupts"] = "Показывать контур вокруг прерываний"
L["Show border around trinkets"] = "Показывать контур вокруг тринкетов"
L["Unknown spell: %s"] = "Неизвестное заклинание: %s"
L["Value must be a number"] = "Значение должно быть числом"
--@end-debug@]==]
