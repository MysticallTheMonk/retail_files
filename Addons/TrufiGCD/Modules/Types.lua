---@class Namespace
---@field frameUtils FrameUtils
---@field LayoutSettings LayoutSettings
---@field UnitSettings UnitSettings
---@field utils Utils
---@field Icon Icon
---@field IconQueue IconQueue
---@field profileFrame ProfileFrame
---@field ProfileSettings ProfileSettings
---@field settings Settings
---@field innerBlockList {[string]: boolean}
---@field innerIconsBlocklist {[string]: boolean}
---@field settingsFrame SettingsFrame
---@field blocklistFrame BlocklistFrame
---@field units {[UnitType]: Unit}
---@field masqueHelper MasqueHelper
---@field locationCheck LocationCheck
---@field constants Constants

---@alias Direction "Left" | "Right" | "Up" | "Down"

---@alias Point "TOPLEFT"| "TOPRIGHT"| "BOTTOMLEFT"| "BOTTOMRIGHT"| "TOP"| "BOTTOM"| "LEFT"| "RIGHT"| "CENTER"

---@alias UnitType "player" | "party1" | "party2" | "party3" | "party4" | "arena1" | "arena2" | "arena3" | "arena4" | "arena5" | "target" | "focus"
---@alias LayoutType "player" | "party" | "arena" | "target" | "focus"

---@class UnitVariablesV1
---@field x? number
---@field y? number
---@field point? Point
---@field enable? boolean
---@field fade? Direction
---@field size? number
---@field width? number

---@class SavedVariablesEnabledIn
---@field Enable? boolean
---@field PvE? boolean
---@field Arena? boolean
---@field Bg? boolean
---@field World? boolean
---@field Raid? boolean
---@field ["Combat only"]? boolean

--TODO: Drop V1 support after 25.08.2025
---@class ProfileVariablesV1
---@field id? string
---@field name? string
---@field EnableIn? SavedVariablesEnabledIn
---@field ModScroll? boolean
---@field TooltipEnable? boolean
---@field TooltipSpellID? boolean
---@field TooltipStopMove? boolean
---@field iconClickAddsSpellToBlocklist? boolean
---@field TrGCDQueueFr? UnitVariablesV1[]
---@field TrGCDBL? number[]

---@class GlobalSavedVariablesV1
---@field version? 1
---@field profiles? { [string]: ProfileVariablesV1 }
---@field lastUsedProfileId? string

---@class CharacterSavedVariablesV1
---@field version? 1
---@field profileId? string

---@class UnitVariablesV2
---@field x? number
---@field y? number
---@field point? Point

---@class LayoutVariablesV2
---@field enable? boolean
---@field direction? Direction
---@field iconSize? number
---@field iconsNumber? number

---@class LayoutsVariablesV2
---@field player? LayoutVariablesV2
---@field party? LayoutVariablesV2
---@field arena? LayoutVariablesV2
---@field target? LayoutVariablesV2
---@field focus? LayoutVariablesV2

---@class UnitsVariablesV2
---@field player? UnitVariablesV2
---@field party1? UnitVariablesV2
---@field party2? UnitVariablesV2
---@field party3? UnitVariablesV2
---@field party4? UnitVariablesV2
---@field arena1? UnitVariablesV2
---@field arena2? UnitVariablesV2
---@field arena3? UnitVariablesV2
---@field target? UnitVariablesV2
---@field focus? UnitVariablesV2

---@class ProfileVariablesV2
---@field id? string
---@field name? string
---@field layouts? LayoutsVariablesV2
---@field units? UnitsVariablesV2
---@field EnableIn? SavedVariablesEnabledIn
---@field ModScroll? boolean
---@field TooltipEnable? boolean
---@field TooltipSpellID? boolean
---@field TooltipStopMove? boolean
---@field iconClickAddsSpellToBlocklist? boolean
---@field TrGCDBL? number[]

---@class GlobalSavedVariablesV2
---@field version? 2
---@field profiles? { [string]: ProfileVariablesV2 }
---@field lastUsedProfileId? string

---@class CharacterSavedVariablesV2
---@field version? 2
---@field profileId? string
