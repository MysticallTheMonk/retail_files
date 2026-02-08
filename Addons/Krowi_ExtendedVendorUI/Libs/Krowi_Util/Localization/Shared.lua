--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

-- [[ https://legacy.curseforge.com/wow/addons/krowi-util/localization ]] --

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib and not lib.L then return end

local L = lib.L

L['General'] = GENERAL
L['Info'] = INFO
L['Version'] = GAME_VERSION_LABEL
L['Sources'] = SOURCES
L['Icon'] = EMBLEM_SYMBOL
L['Minimap'] = MINIMAP_LABEL
L['Game Menu'] = MAINMENU_BUTTON
L['Interface'] = UIOPTIONS_MENU
L['AddOns'] = ADDONS
L['Options'] = GAMEOPTIONS_MENU

local l = lib.Localization.GetLocale(lib)
L['Requires a reload'] = l['Requires a reload']:SetColorOrange()

lib.L = lib.Localization.GetLocale(lib)