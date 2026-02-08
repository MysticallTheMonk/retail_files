--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('ptBR')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-14 15-50-42 ]] --
L["Accept"] = "Aceitar"
L["Cancel"] = "Cancelar"
L["Close"] = "Fechar"
L["Copy and close"] = "Pressione Ctrl + X para copiar o site e fechar esta janela."
L["Enter a number"] = "Digite um número:"