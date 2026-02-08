--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('frFR')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-14 15-50-41 ]] --
L["Accept"] = "Accepter"
L["Cancel"] = "Annuler"
L["Close"] = "Fermer"
L["Copy and close"] = "Appuyez sur Ctrl + X pour copier le site web et fermer cette fenêtre."
L["Enter a number"] = "Entrez un nombre :"