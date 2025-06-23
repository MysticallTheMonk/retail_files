local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "ruRU");
if not L then return end
addon.L = L;

addon.Plugins:LoadLocalization(L);

-- [[ https://legacy.curseforge.com/wow/addons/krowi-extended-vendor-ui/localization ]] --
-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2025-05-15 18-40-48 ]] --
L["Are you sure you want to hide the options button?"] = "Вы уверены, что хотите скрыть кнопку настроек? Кнопку настроек можно заново вкоючить через {gameMenu} {arrow} {interface} {arrow} {addOns} {arrow} {addonName} {arrow} {general} {arrow} {options}"
L["Arsenals"] = "Арсеналы"
L["Author"] = "Автор"
L["Build"] = "Сборка"
L["Checked"] = "Выделено"
L["Columns"] = "Столбцы"
L["Columns first"] = "Сначала столбцы"
L["CurseForge"] = true
L["CurseForge Desc"] = "Открыть всплывающее окно с ссылкой на {addonName} {curseForge}"
L["Custom"] = "Разное"
L["Default filters"] = "Фильтры по-умолчанию"
L["Default value"] = "Значение по умолчанию"
L["Deselect All"] = "Оратить всё выделение "
L["Discord"] = true
L["Discord Desc"] = "Открывает всплывающее окно с ссылкой на  {serverName} дискорд сервер. Там вы можете написать комментарий, отчёты, правки, идеи и всяко разное."
L["Ensembles"] = "Множество"
L["Filters"] = "Фильтры"
L["Hide"] = "Спрятать"
L["Hide collected"] = "Спрятать собранные"
L["Icon Left click"] = "для быстрой настройки слоёв"
L["Icon Right click"] = "для Настроек"
L["Illusions"] = "Иллюзии (а надо?)"
L["Left click"] = "Щелчок Левой"
L["Mounts"] = "Средства передвижения"
L["Only show"] = "Показ только"
L["Options button"] = "кнопка настройки"
L["Options Desc"] = "Открыть настройки, также доступны по кнопке настроек из меню торговца."
L["Other"] = "Другое"
L["Pets"] = "Питомцы"
L["Plugins"] = "Плагины"
L["Recipes"] = "Рецепты"
L["Right click"] = "Щелчек ПКМ"
L["Rows"] = "Ряды"
L["Rows first"] = "Сначала Ряды"
L["Select All"] = "Выделить все"
L["Show Hide option"] = "Показ '{hide}' настроек"
L["Show Hide option Desc"] = "Показ '{hide}'  настроек в {optionsButton} выпадающим вниз."
L["Show minimap icon"] = "Показать иконку у миникарты"
L["Show minimap icon Desc"] = "Показать / спрятать иконку у миникарты"
L["Show options button"] = "Показ кнопки настроек"
L["Show options button Desc"] = "Показ / скрыть мнопку настроек в меню продавца."
L["Toys"] = "Игрушки"
L["Unchecked"] = "Невыделено"
L["Wago"] = true
L["Wago Desc"] = "Открыть всплывающее окно с ссылкой на страницу {addonName} {wago}"
L["WoWInterface"] = true
L["WoWInterface Desc"] = "Открыть всплывающее окно с ссылкой на страницу {addonName} {woWInterface}"