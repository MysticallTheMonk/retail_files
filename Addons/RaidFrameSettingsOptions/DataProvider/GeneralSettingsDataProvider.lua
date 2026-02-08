local addon_name, private = ...
local main_addon = _G["RaidFrameSettings"]
local data_base = main_addon.db
local L = LibStub("AceLocale-3.0"):GetLocale(addon_name)

local data_manager = {}
private.DataHandler.RegisterDataManager("general_settings", data_manager)

local color_mode_options = {
  [1] = L["class"],
  [2] = L["class_gradient"],
  [3] = L["static"],
  [4] = L["static_gradient"],
  [5] = L["health_value"],
  [6] = L["power_type"],
  [7] = L["power_type_gradient"],
  [8] = L["class_to_health_value"],
}

local function generate_options_tbl()
  local options = {
    -- Colors.
    [1] = {
      title = {
        order = 1,
        type = "title",
        settings_text = L["title_colors"],
      },
      health_bar_fg = {
        order = 2,
        type = "color_mode",
        settings_text = L["health_bar_fg"],
        db_obj = data_base.profile.health_bars.fg,
        color_modes = {
          {color_mode_options[1], 1},
          {color_mode_options[2], 2},
          {color_mode_options[3], 3},
          {color_mode_options[4], 4},
          {color_mode_options[5], 5},
          {color_mode_options[8], 8},
        },
        associated_modules = {
          "HealthBarForeground_Color",
        },
      },
      health_bar_bg = {
        order = 3,
        type = "color_mode",
        settings_text = L["health_bar_bg"],
        db_obj = data_base.profile.health_bars.bg,
        color_modes = {
          {color_mode_options[1], 1},
          {color_mode_options[2], 2},
          {color_mode_options[3], 3},
          {color_mode_options[4], 4},
        },
        associated_modules = {
          "HealthBarBackground_Color"
        },
      },
      health_bar_bg_darkening_factor = {
        order = 3.1,
        type = "slider",
        settings_text = L["option_darkening_factor"],
        db_obj = data_base.profile.health_bars.bg,
        db_key = "darkening_factor",
        associated_modules = {
          "HealthBarBackground_Color",
        },
        slider_options = {
          min_value = 0.1,
          max_value = 0.9,
          steps = 8,
          decimals = 1,
        },
        hide = function()
          local color_mode = data_base.profile.health_bars.bg.color_mode
          return color_mode == 3 or color_mode == 4
        end,
      },
      power_bar_fg = {
        order = 4,
        type = "color_mode",
        settings_text = L["power_bar_fg"],
        db_obj = data_base.profile.power_bars.fg,
        color_modes = {
          {color_mode_options[3], 3},
          {color_mode_options[4], 4},
          {color_mode_options[6], 6},
          {color_mode_options[7], 7},
        },
        associated_modules = {
          "PowerBarForeground_Color",
        },
      },
      power_bar_bg = {
        order = 5,
        type = "color_mode",
        settings_text = L["power_bar_bg"],
        db_obj = data_base.profile.power_bars.bg,
        color_modes = {
          {color_mode_options[3], 3},
          {color_mode_options[4], 4},
          {color_mode_options[6], 6},
          {color_mode_options[7], 7},
        },
        associated_modules = {
          "PowerBarBackground_Color",
        },
      },
      power_bar_bg_darkening_factor = {
        order = 5.1,
        type = "slider",
        settings_text = L["option_darkening_factor"],
        db_obj = data_base.profile.power_bars.bg,
        db_key = "darkening_factor",
        associated_modules = {
          "PowerBarBackground_Color",
        },
        slider_options = {
          min_value = 0.1,
          max_value = 0.9,
          steps = 8,
          decimals = 1,
        },
        hide = function()
          local color_mode = data_base.profile.power_bars.bg.color_mode
          return color_mode == 3 or color_mode == 4
        end,
      },
      border_color = {
        order = 6,
        type = "color",
        settings_text = L["border_color"],
        db_obj = data_base.profile.module_data.UnitFrameBorder,
        db_key = "border_color",
        associated_modules = {
          "UnitFrameBorder",
        },
      },
    },
    -- Textures.
    [2] = {
      title = {
        order = 1,
        type = "title",
        settings_text = L["textures"],
      },
      health_bar_fg = {
        order = 2,
        type = "lsm_texture",
        settings_text = L["health_bar_fg"],
        db_obj = data_base.profile.health_bars.fg,
        associated_modules = {
          "HealthBarForeground_Texture"
        },
      },
      health_bar_bg = {
        order = 3,
        type = "lsm_texture",
        settings_text = L["health_bar_bg"],
        db_obj = data_base.profile.health_bars.bg,
        associated_modules = {
          "HealthBarBackground_Texture",
        },
      },
      power_bar_fg = {
        order = 4,
        type = "lsm_texture",
        settings_text = L["power_bar_fg"],
        db_obj = data_base.profile.power_bars.fg,
        associated_modules = {
          "PowerBarForeground_Texture",
        },
      },
      power_bar_bg = {
        order = 5,
        type = "lsm_texture",
        settings_text = L["power_bar_bg"],
        db_obj = data_base.profile.power_bars.bg,
        associated_modules = {
          "PowerBarBackground_Texture",
        },
      }
    },
    -- Unit Frames.
    [3] = {
      title = {
        order = 1,
        type = "title",
        settings_text = L["blizzard_settings_unit_frames"],
      },
      display_pets = {
        order = 2,
        type = "toggle",
        settings_text = L["display_pets"],
        db_obj = data_base.profile.cvars,
        db_key = "raidOptionDisplayPets",
        associated_modules = {
          "CVar_raidOptionDisplayPets"
        },
      },
      display_power_bars = {
        order = 3,
        type = "dropdown",
        settings_text = L["option_power_bars"],
        db_obj = data_base.profile.module_data,
        db_key = "power_bar_display_mode",
        options = {
          {L["option_show"] , 1},
          {L["option_healer_only"] , 2},
          {L["option_hide"] , 3},
        },
        associated_modules = {
          "CVar_raidFramesDisplayPowerBars",
          "CVar_raidFramesDisplayOnlyHealerPowerBars",
          "CVar_pvpFramesDisplayPowerBars",
          "CVar_pvpFramesDisplayOnlyHealerPowerBars",
        },
      },
      health_text_display_mode = {
        order = 4,
        type = "dropdown",
        settings_text = L["option_health_text_display_mode"],
        db_obj = data_base.profile.module_data,
        db_key = "health_text_display_mode",
        options = {
          {L["option_health_none"] , "none"},
          {L["option_health_health"] , "health"},
          {L["option_health_lost"] , "losthealth"},
          {L["option_health_perc"] , "perc"},
        },
        associated_modules = {
          "CVar_raidFramesHealthText",
          "CVar_pvpFramesHealthText",
        },
      },
      display_incoming_heals = {
        order = 4.1,
        type = "toggle",
        settings_text = L["display_incoming_heals"],
        db_obj = data_base.profile.cvars,
        db_key = "raidFramesDisplayIncomingHeals",
        associated_modules = {
          "CVar_raidFramesDisplayIncomingHeals"
        },
      },
      role_icon_pos = {
        order = 5,
        type = "anchor",
        settings_text = L["role_icon"],
        db_obj = data_base.profile.module_data.RoleIcon,
        associated_modules = {
          "RoleIcon",
        },
      },
      role_icon_slection = {
        order = 5.1,
        type = "dropdown",
        settings_text = L["role_icon_slection"],
        db_obj = data_base.profile.module_data.RoleIcon,
        is_multiple_choice = true,
        options = {
          {L["unit_group_role_tank"], "show_for_tank"},
          {L["unit_group_role_heal"], "show_for_heal"},
          {L["unit_group_role_dps"], "show_for_dps"},
        },
        associated_modules = {
          "RoleIcon",
        },
      },
      display_main_tank_and_assist = {
        order = 6,
        type = "toggle",
        settings_text = L["display_main_tank_and_assist"],
        db_obj = data_base.profile.cvars,
        db_key = "raidOptionDisplayMainTankAndAssist",
        associated_modules = {
          "CVar_raidOptionDisplayMainTankAndAssist"
        },
      },
      raid_mark_pos = {
        order = 7,
        type = "anchor",
        settings_text = L["raid_mark_pos"],
        db_obj = data_base.profile.module_data.RaidMark,
        associated_modules = {
          "RaidMark",
        },
      },
      raid_mark_scale = {
        order = 8,
        type = "slider",
        settings_text = L["raid_mark_scale"],
        db_obj = data_base.profile.module_data.RaidMark,
        db_key = "scale",
        associated_modules = {
          "RaidMark",
        },
        slider_options = {
          min_value = 0.5,
          max_value = 2,
          steps = 15,
          decimals = 1,
        },
      },
      display_aggro_highlight = {
        order = 9,
        type = "toggle",
        settings_text = L["display_aggro_highlight"],
        db_obj = data_base.profile.cvars,
        db_key = "raidFramesDisplayAggroHighlight",
        associated_modules = {
          "CVar_raidFramesDisplayAggroHighlight"
        },
      },
      center_big_defensive = {
        order = 10,
        type = "toggle",
        settings_text = L["center_big_defensive"],
        db_obj = data_base.profile.cvars,
        db_key = "raidFramesCenterBigDefensive",
        associated_modules = {
          "CVar_raidFramesCenterBigDefensive"
        },
      },
      dispellable_debuff_indicator = {
        order = 11,
        type = "dropdown",
        settings_text = L["dispellable_debuff_indicator"],
        db_obj = data_base.profile.module_data,
        db_key = "dispel_indicator_mode",
        options = {
          {L["option_disabled"] , "0"},
          {L["option_dispellable_by_me"] , "1"},
          {L["option_show_all"] , "2"},
        },
        associated_modules = {
          "CVar_raidFramesDispelIndicatorType",
          "CVar_raidFramesDispelIndicatorOverlay",
        },
      },
      dispellable_debuff_color = {
        order = 12,
        type = "toggle",
        settings_text = L["dispellable_debuff_color"],
        db_obj = data_base.profile.cvars,
        db_key = "raidFramesDispelIndicatorOverlay",
        associated_modules = {
          "CVar_raidFramesDispelIndicatorOverlay"
        },
        hide = function()
          return data_base.profile.module_data.dispel_indicator_mode == "0"
        end,
      },
      display_solo_frame = {
        order = 13,
        type = "toggle",
        settings_text = L["settings_text_solo_frame"],
        db_obj = data_base.profile.module_status,
        db_key = "SoloFrame",
        associated_modules = {
          "SoloFrame"
        },
      },
    },
  }
  return options
end



data_manager.get_data_provider = function ()
  local options = generate_options_tbl()
  local data_provider = CreateTreeDataProvider()

  for _, category in ipairs(options) do
    local order_tbl = {}

    -- Exclude hidden objects.
    for _, option in pairs(category) do
      if not (option.hide and option.hide() == true) then
        table.insert(order_tbl, option)
      end
    end

    -- Sort by order key.
    table.sort(order_tbl, function(a, b)
      return (a.order or 0) < (b.order or 0)
    end)

    -- Add them to the data provider.
    for _, option in ipairs(order_tbl) do
      data_provider:Insert(option)
    end
  end

  return data_provider
end

