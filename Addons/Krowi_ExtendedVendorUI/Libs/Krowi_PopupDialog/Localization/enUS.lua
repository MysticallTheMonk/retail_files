--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewDefaultLocale()
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-14 15-50-39 ]] --
L["Accept"] = true
L["Cancel"] = true
L["Close"] = true
L["Copy and close"] = "Press Ctrl + X to copy the website and close this window."
L["Enter a number"] = "Enter a number:"