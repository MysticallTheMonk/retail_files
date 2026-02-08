--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('koKR')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-14 16-25-21 ]] --
L["1k"] = "1천"
L["1m"] = "1백만"
L["Comma"] = "쉼표"
L["Copper Label"] = "동"
L["Currency Abbreviate"] = "화폐 줄이기"
L["Currency Options"] = "화폐 옵션"
L["Gold Label"] = "골"
L["Icon"] = "아이콘"
L["Millions Suffix"] = "백만"
L["Money Abbreviate"] = "골드 줄이기"
L["Money Colored"] = "골드 색상 표시"
L["Money Gold Only"] = "골드만 표시"
L["Money Label"] = "골드 라벨"
L["Money Options"] = "골드 옵션"
L["None"] = "없음"
L["Period"] = "마침표"
L["Silver Label"] = "은"
L["Space"] = "공백"
L["Text"] = "텍스트"
L["Thousands Separator"] = "천 단위 구분자"
L["Thousands Suffix"] = "천"