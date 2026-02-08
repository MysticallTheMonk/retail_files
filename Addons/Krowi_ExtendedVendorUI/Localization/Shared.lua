-- [[ https://legacy.curseforge.com/wow/addons/krowi-extended-vendor-ui/localization ]] --

local _, addon = ...
local L = addon.L

L['Direction'] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION
L['Appearances'] = WARDROBE .. ' (' .. ITEMS .. ')'
L['All'] = ALL
L['Search'] = SEARCH
L['All Specs'] = ALL_SPECS
L['Bind on Equip'] = ITEM_BIND_ON_EQUIP

local l = addon.Localization.GetLocale(addon)
L['Appearance Sets'] = WARDROBE .. ' (' .. l['Ensembles'] .. ', ' .. l['Arsenals'] .. ', ...)'

addon.L = addon.Localization.GetLocale(addon)