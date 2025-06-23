local addonName, addon = ...;
local L = addon.L;

L["Direction"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION;
L["General"] = GENERAL;
L["Info"] = INFO;
L["Version"] = GAME_VERSION_LABEL;
L["Sources"] = SOURCES;
L["Icon"] = EMBLEM_SYMBOL;
L["Minimap"] = MINIMAP_LABEL;
L["Game Menu"] = MAINMENU_BUTTON;
L["Interface"] = UIOPTIONS_MENU;
L["AddOns"] = ADDONS;
L["Options"] = GAMEOPTIONS_MENU;
L["Appearances"] = WARDROBE .. " (" .. ITEMS .. ")";

local l = LibStub(addon.Libs.AceLocale):GetLocale(addonName);
L["Appearance Sets"] = WARDROBE .. " (" .. l["Ensembles"] .. ", " .. l["Arsenals"] .. ", ...)";