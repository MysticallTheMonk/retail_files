--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('deDE')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-14 15-50-40 ]] --
L["Accept"] = "Akzeptieren"
L["Cancel"] = "Abbrechen"
L["Close"] = "Schließen"
L["Copy and close"] = "Drücke Strg + X um die Webseite zu kopieren und dieses Fenster zu schließen."
L["Enter a number"] = "Gib eine Zahl ein:"