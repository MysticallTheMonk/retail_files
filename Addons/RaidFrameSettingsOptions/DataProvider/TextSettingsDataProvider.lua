local addon_name, private = ...
local main_addon = _G["RaidFrameSettings"]
local data_base = main_addon.db
local L = LibStub("AceLocale-3.0"):GetLocale(addon_name)

local data_manager = {}
private.DataHandler.RegisterDataManager("text_settings", data_manager)

local color_mode_options = {
  [1] = L["class"],
  [2] = L["class_gradient"],
  [3] = L["static"],
  [4] = L["static_gradient"],
  [5] = L["health_value"],
  [6] = L["power_type"],
  [7] = L["power_type_gradient"],
}

local function generate_options_tbl()
  local options = {
    -- Name text.
    [1] = {
      title = {
        order = 1,
        type = "title",
        settings_text = L["title_name"],
      },
      font = {
        order = 2,
        type = "font_selection",
        settings_text = L["option_font"],
        db_obj = data_base.profile.fonts.name,
        associated_modules = {
          "Font_Name",
        },
      },
      player_color = {
        order = 3,
        type = "color_mode",
        settings_text = L["option_player_color"],
        associated_modules = {
          "Font_Name",
        },
        db_obj = data_base.profile.fonts.name,
        color_modes = {
          {color_mode_options[1], 1},
          {color_mode_options[3], 3},
        },
      },
      npc_color = {
        order = 4,
        type = "color",
        settings_text = L["option_npc_color"],
        db_obj = data_base.profile.fonts.name,
        db_key = "npc_color",
        associated_modules = {
          "Font_Name",
        },
      },
      anchor = {
        order = 5,
        type = "anchor",
        settings_text = L["option_anchor"],
        db_obj = data_base.profile.fonts.name,
        associated_modules = {
          "Font_Name",
        },
      },
      horizontal_justification = {
        order = 6,
        type = "dropdown",
        settings_text = L["text_horizontal_justification"],
        db_obj = data_base.profile.fonts.name,
        db_key = "horizontal_justification",
        associated_modules = {
          "Font_Name",
        },
        options = {
          {L["text_horizontal_justification_option_left"] , "LEFT"},
          {L["text_horizontal_justification_option_center"] , "CENTER"},
          {L["text_horizontal_justification_option_right"] , "RIGHT"},
        },
      },
      max_length = {
        order = 7,
        type = "slider",
        settings_text = L["max_length"],
        db_obj = data_base.profile.fonts.name,
        db_key = "max_length",
        associated_modules = {
          "Font_Name",
        },
        slider_options = {
          min_value = 0.5,
          max_value = 2,
          steps = 15,
          decimals = 1,
        },
      },
    },
    -- Status text.
    [2] = {
      title = {
        order = 1,
        type = "title",
        settings_text = L["title_status"],
      },
      font = {
        order = 2,
        type = "font_selection",
        settings_text = L["option_font"],
        db_obj = data_base.profile.fonts.status,
        associated_modules = {
          "Font_Status",
        },
      },
      player_color = {
        order = 3,
        type = "color_mode",
        settings_text = L["option_player_color"],
        associated_modules = {
          "Font_Status",
        },
        db_obj = data_base.profile.fonts.status,
        color_modes = {
          {color_mode_options[1], 1},
          {color_mode_options[3], 3},
        },
      },
      anchor = {
        order = 5,
        type = "anchor",
        settings_text = L["option_anchor"],
        db_obj = data_base.profile.fonts.status,
        associated_modules = {
          "Font_Status",
        },
      },
      horizontal_justification = {
        order = 6,
        type = "dropdown",
        settings_text = L["text_horizontal_justification"],
        db_obj = data_base.profile.fonts.status,
        db_key = "horizontal_justification",
        associated_modules = {
          "Font_Status",
        },
        options = {
          {L["text_horizontal_justification_option_left"] , "LEFT"},
          {L["text_horizontal_justification_option_center"] , "CENTER"},
          {L["text_horizontal_justification_option_right"] , "RIGHT"},
        },
      },
      max_length = {
        order = 7,
        type = "slider",
        settings_text = L["max_length"],
        db_obj = data_base.profile.fonts.status,
        db_key = "max_length",
        associated_modules = {
          "Font_Status",
        },
        slider_options = {
          min_value = 0.5,
          max_value = 2,
          steps = 15,
          decimals = 1,
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
    local count = 1
    for _, option in pairs(category) do
      if option.hide and option.hide() == true then
        -- continue
      else
        local pos = option.order * 100
        order_tbl[pos] = option
        count = count > pos and count or pos
      end
    end
    for i = 1, count do
      local option = order_tbl[i]
      if option then
        data_provider:Insert(option)
      end
    end
  end

  return data_provider
end
