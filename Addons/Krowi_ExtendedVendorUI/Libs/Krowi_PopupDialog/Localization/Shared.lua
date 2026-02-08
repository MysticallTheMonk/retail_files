--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

-- [[ https://legacy.curseforge.com/wow/addons/krowi-popup-dialog/localization ]] --

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib and not lib.L then return end

lib.L = lib.Localization.GetLocale(lib)