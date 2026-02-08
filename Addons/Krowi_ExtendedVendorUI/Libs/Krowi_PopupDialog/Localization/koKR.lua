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

-- [[ Exported at 2026-01-14 15-50-42 ]] --
L["Accept"] = "수락"
L["Cancel"] = "취소"
L["Close"] = "닫기"
L["Copy and close"] = "웹사이트를 복사하고 이 창을 닫으려면 Ctrl + X를 누르세요."
L["Enter a number"] = "숫자를 입력하세요:"