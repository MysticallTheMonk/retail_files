--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('itIT')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-14 15-50-41 ]] --
L["Accept"] = "Accetta"
L["Cancel"] = "Annulla"
L["Close"] = "Chiudi"
L["Copy and close"] = "Premi Ctrl + X per copiare il sito web e chiudere questa finestra."
L["Enter a number"] = "Inserisci un numero:"