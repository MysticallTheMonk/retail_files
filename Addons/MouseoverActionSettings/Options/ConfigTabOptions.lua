local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Media = LibStub("LibSharedMedia-3.0")
local Fonts = Media:List("font")

local fontFlags = {
    [""] = L["none"],
    ["OUTLINE"] = L["outline"],
    ["THICKOUTLINE"] = L["thick_outline"],
    ["MONOCHROME"] = L["monochrome"],
    ["MONOCHROME,OUTLINE"] = L["monochrome_outline"],
    ["MONOCHROME,THICKOUTLINE"] = L["monochrome_thick_outline"],
}

local options = {
    name = "Config",
    handler = addon,
    type = "group",
    args = {
        GlobalSettings = {
            order = 1,
            name = L["global_settings_header"],
            type = "group",
            inline = true,
            args = {
                delay = {
                    order = 1,
                    name = L["delay_name"],
                    desc = L["delay_desc"],
                    type = "range",
                    get = "GetStatus",
                    set = "SetStatus",
                    min = 0,
                    softMax = 10,   
                    step = 1,   
                    width = 1.6,                    
                },
                animationSpeed_In = {
                    order = 2,
                    name = L["animation_speed_in_name"] ,
                    desc = L["animation_speed_in_desc"],
                    type = "range",
                    get = "GetStatus",
                    set = "SetStatus",
                    min = 0,
                    max = 10,   
                    step = 0.01, 
                    width = 1.6,   
                },
                animationSpeed_Out = {
                    order = 3,
                    name = L["animation_speed_out_name"] ,
                    desc = L["animation_speed_out_desc"],
                    type = "range",
                    get = "GetStatus",
                    set = "SetStatus",
                    min = 0,
                    max = 10,   
                    step = 0.01, 
                    width = 1.6,   
                },
                healthThreshold = {
                    order = 4,
                    name = L["health_threshold_name"],
                    desc = L["health_threshold_desc"],
                    type = "range",
                    get = "GetStatus",
                    set = "SetStatus",
                    min = 0,
                    max = 1,
                    isPercent = true,
                    step = 0.01, 
                    width = 1.6,                    
                },
                newline = {
                    order = 10,
                    type = "description",
                    name = "",
                },
                event_delay_timer_button = {
                    order = 10.1,
                    name = L["event_delay_timer_button_name"],
                    type  = "execute",
                    width = 1.7,
                    func = function()
                        addon:ShowEventDelayTimerFrame()
                    end,
                },
            },
        },
        ActionBarConfig = {
            order = 2,
            name = L["action_bar_settings"],
            type = "group",
            inline = true,
            args = {
                HotKeyFontSettings = {
                    order = 1,
                    name = L["hot_key_font_settings"],
                    type = "group",
                    inline = true,
                    args = {
                        font = {
                            order = 1,
                            name = L["font_name"],
                            desc = "",
                            type = "select",
                            itemControl = "DDI-Font",
                            values = Fonts,
                            get = function()
                                for i, v in next, Fonts do
                                    if v == addon.db.profile.HotKeyFontSettings.font then
                                        return i
                                    end
                                end
                            end,
                            set = function(_, value)
                                addon.db.profile.HotKeyFontSettings.font = Fonts[value]
                                addon:ReloadModule("ActionBarConfig")
                            end,
                        },
                        flags = {
                            order = 2,
                            name = L["font_flags"],
                            desc = "",
                            type = "select",
                            values = fontFlags,
                            sorting = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "MONOCHROME,OUTLINE", "MONOCHROME,THICKOUTLINE" },
                            get = function()
                                return addon.db.profile.HotKeyFontSettings.flags
                            end,
                            set = function(_, value)
                                for k, _ in next, fontFlags do
                                    if k == value then
                                        addon.db.profile.HotKeyFontSettings.flags = k
                                    end
                                end
                                addon:ReloadModule("ActionBarConfig")
                            end,
                        },
                        height = {
                            order = 3,
                            name = L["font_height"],
                            desc = "",
                            type = "range",
                            softMin = 8,
                            softMax = 16,
                            step = 1,
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                    },
                },
                CountFontSettings = {
                    order = 2,
                    name = L["count_font_settings"],
                    type = "group",
                    inline = true,
                    args = {
                        font = {
                            order = 1,
                            name = L["font_name"],
                            desc = "",
                            type = "select",
                            itemControl = "DDI-Font",
                            values = Fonts,
                            get = function()
                                for i, v in next, Fonts do
                                    if v == addon.db.profile.CountFontSettings.font then
                                        return i
                                    end
                                end
                            end,
                            set = function(_, value)
                                addon.db.profile.CountFontSettings.font = Fonts[value]
                                addon:ReloadModule("ActionBarConfig")
                            end,
                        },
                        flags = {
                            order = 2,
                            name = L["font_flags"],
                            desc = "",
                            type = "select",
                            values = fontFlags,
                            sorting = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "MONOCHROME,OUTLINE", "MONOCHROME,THICKOUTLINE" },
                            get = function()
                                return addon.db.profile.CountFontSettings.flags
                            end,
                            set = function(_, value)
                                for k, _ in next, fontFlags do
                                    if k == value then
                                        addon.db.profile.CountFontSettings.flags = k
                                    end
                                end
                                addon:ReloadModule("ActionBarConfig")
                            end,
                        },
                        height = {
                            order = 3,
                            name = L["font_height"],
                            desc = "",
                            type = "range",
                            softMin = 8,
                            softMax = 18,
                            step = 1,
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                    },
                },
                NameFontSettings = {
                    order = 3,
                    name = L["name_font_settings"],
                    type = "group",
                    inline = true,
                    args = {
                        font = {
                            order = 1,
                            name = L["font_name"],
                            desc = "",
                            type = "select",
                            itemControl = "DDI-Font",
                            values = Fonts,
                            get = function()
                                for i, v in next, Fonts do
                                    if v == addon.db.profile.NameFontSettings.font then
                                        return i
                                    end
                                end
                            end,
                            set = function(_, value)
                                addon.db.profile.NameFontSettings.font = Fonts[value]
                                addon:ReloadModule("ActionBarConfig")
                            end,
                        },
                        flags = {
                            order = 2,
                            name = L["font_flags"],
                            desc = "",
                            type = "select",
                            values = fontFlags,
                            sorting = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "MONOCHROME,OUTLINE", "MONOCHROME,THICKOUTLINE" },
                            get = function()
                                return addon.db.profile.NameFontSettings.flags
                            end,
                            set = function(_, value)
                                for k, _ in next, fontFlags do
                                    if k == value then
                                        addon.db.profile.NameFontSettings.flags = k
                                    end
                                end
                                addon:ReloadModule("ActionBarConfig")
                            end,
                        },
                        height = {
                            order = 3,
                            name = L["font_height"],
                            desc = "",
                            type = "range",
                            softMin = 8,
                            softMax = 16,
                            step = 1,
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                    },
                },
                ActionBarConfig = {
                    order = 4,
                    name = L["action_bar_config_name"],
                    type = "group",
                    inline = true,
                    args = {
                        Action = { --MainMenuBar: Buttons for that bar aren't named after parent frame
                            order = 1,
                            name = L["MainMenuBar"],
                            desc = "",
                            type = "toggle",
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                        MultiBarBottomLeft = {
                            order = 2,
                            name = L["MultiBarBottomLeft"],
                            desc = "",
                            type = "toggle",
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                        MultiBarBottomRight = {
                            order = 3,
                            name = L["MultiBarBottomRight"],
                            desc = "",
                            type = "toggle",
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                        MultiBarRight = {
                            order = 4,
                            name = L["MultiBarRight"],
                            desc = "",
                            type = "toggle",
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                        MultiBarLeft = {
                            order = 5,
                            name = L["MultiBarLeft"],
                            desc = "",
                            type = "toggle",
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                        MultiBar5 = {
                            order = 6,
                            name = L["MultiBar5"],
                            desc = "",
                            type = "toggle",
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                        MultiBar6 = {
                            order = 7,
                            name = L["MultiBar6"],
                            desc = "",
                            type = "toggle",
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                        MultiBar7 = {
                            order = 8,
                            name = L["MultiBar7"],
                            desc = "",
                            type = "toggle",
                            get = "GetStatus",
                            set = "SetStatus",
                        },
                    },
                },
                hideHotkey = {
                    order = 5,
                    name = L["hideHotkey"],
                    desc = "",
                    type = "toggle",
                    get = "GetStatus",
                    set = "SetStatus",
                },
                hideCount = {
                    order = 6,
                    name = L["hideCount"],
                    desc = "",
                    type = "toggle",
                    get = "GetStatus",
                    set = "SetStatus",
                },
                hideName = {
                    order = 7,
                    name = L["hideName"],
                    desc = "",
                    type = "toggle",
                    get = "GetStatus",
                    set = "SetStatus",
                },
            },
        },
        Hide = {
            order = 3,
            name = L["Hide"],
            type = "group",
            inline = true,
            args = {
                HideBagsBar = {
                    order = 1,
                    name = L["hide_bags_bar_name"],
                    desc = L["hide_bags_bar_desc"],
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                HideTrackingBars = {
                    order = 2,
                    name = L["hide_tracking_bars_name"],
                    desc = L["hide_tracking_bars_desc"],
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                HideMicroMenu = {
                    order = 3,
                    name = L["hide_micro_menu_name"],
                    desc = L["hide_micro_menu_desc"],
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
            },
        },
        Miscellaneous = {
            order = 4,
            name = L["Miscellaneous"],
            type = "group",
            inline = true,
            args = {
                MiniMapButton = {
                    order = 1,
                    name = L["minimap_button_name"],
                    desc = L["minimap_button_desc"],
                    type = "toggle",
                    get = "GetModuleStatus",
                    set = "SetModuleStatus",
                },
                TinkerZone = {
                    order = 2,
                    name = L["tinker_zone_name"],
                    desc = L["tinker_zone_desc"],
                    type = "toggle",
                    confirm = function(info, value)
                        if value == true then
                            return true
                        end
                        return false
                    end,
                    get = function()
                        return addon.db.global.TinkerZone
                    end,
                    set = function(info, value)
                        addon.db.global.TinkerZone = value
                        ReloadUI()
                    end,
                },
            },
        },
    },
}

function addon:GetConfigOptions()
    return options
end

