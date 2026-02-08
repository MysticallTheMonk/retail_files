--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('esES')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-14 15-50-40 ]] --
L["Accept"] = "Aceptar"
L["Cancel"] = "Cancelar"
L["Close"] = "Cerrar"
L["Copy and close"] = "Pulsa Ctrl + X para copiar el sitio web y cerrar esta ventana."
L["Enter a number"] = "Introduce un número:"