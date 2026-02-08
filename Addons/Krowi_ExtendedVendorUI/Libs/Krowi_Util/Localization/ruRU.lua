--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('ruRU')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-12 19-40-14 ]] --
L['Author'] = 'Автор'
L['Build'] = 'Сборка'
L['Checked'] = 'Выделено'
L['CurseForge'] = true
L['CurseForge Desc'] = 'Открыть всплывающее окно с ссылкой на {addonName} {curseForge}'
L['Default value'] = 'Значение по умолчанию'
L['Deselect All'] = 'Оратить всё выделение '
L['Discord'] = true
L['Discord Desc'] = 'Открывает всплывающее окно с ссылкой на  {serverName} дискорд сервер. Там вы можете написать комментарий, отчёты, правки, идеи и всяко разное.'
L['Hide'] = 'Спрятать'
L['Left click'] = 'Щелчок Левой'
L['Plugins'] = 'Плагины'
L['Right click'] = 'Щелчек ПКМ'
L['Select All'] = 'Выделить все'
L['Show minimap icon'] = 'Показать иконку у миникарты'
L['Show minimap icon Desc'] = 'Показать / спрятать иконку у миникарты'
L['Unchecked'] = 'Невыделено'
L['Wago'] = true