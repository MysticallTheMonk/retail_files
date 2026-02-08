local addon_name, private = ...

local defaults = {
  profile = {
    ["*"] = {
      enabled = true,
      ["*"] = {
        gradient_start = {0, 0, 0, 1},
        gradient_end = {1, 1, 1, 1},
        normal_color   = {0, 0, 0, 1},
      },
    },
    module_status = {
      ["*"] = true,
      SoloFrame = false,
    },
    module_data = {
      UnitFrameBorder = {
        border_color = {0.2, 0.2, 0.2, 0.8},
        edge_file = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tile_edge = true,
        edge_size = 1, -- Has to be at least 1 or the background will show through.
        insets = { left = 1, right = 1, top = 1, bottom = 1},
      },
      RoleIcon = {
        point = "TOPRIGHT",
        relative_point = "TOPRIGHT",
        offset_x = -3,
        offset_y = -3,
        show_for_tank = true,
        show_for_heal = true,
        show_for_dps = false,
      },
      RaidMark = {
        point = "TOP",
        relative_point = "TOP",
        offset_x = 0,
        offset_y = -3,
        scale = 0.8,
      },
      power_bar_display_mode = 2, -- 1 Show, 2 = Healer only, 3 = hide,
      health_text_display_mode = "none",
      dispel_indicator_mode = "1" -- 0 = Disabled, 1 = Dispellable By Me, 2 = Show All
    },
    health_bars = {
      health_value_colors = {
        max_health   = {0, 1, 0, 1},
        mid_health   = {1, 1, 0, 1},
        low_health   = {1, 0, 0, 1},
      },
      fg = {
        color_mode = 8,
        static_color = {0, 0, 0, 1},
        gradient_start = {0, 0, 0, 1},
        gradient_end = {1, 1, 1, 1},
        texture = "RFS StatusBar",
      },
      bg = {
        color_mode = 1,
        darkening_factor = 0.3,
        static_color = {0, 0, 0, 1},
        gradient_start = {0, 0, 0, 1},
        gradient_end = {1, 1, 1, 1},
        texture = "RFS StatusBar",
      },
    },
    power_bars = {
      fg = {
        color_mode = 6,
        static_color = {0, 0, 0, 1},
        gradient_start = {0, 0, 0, 1},
        gradient_end = {1,1,1,1},
        texture = "RFS StatusBar",
      },
      bg = {
        color_mode = 6,
        darkening_factor = 0.3,
        static_color = {0, 0, 0, 1},
        gradient_start = {0, 0, 0, 1},
        gradient_end = {1, 1, 1, 1},
        texture = "RFS StatusBar",
      },
    },
    fonts = {
      name = {
        color_mode = 3,
        static_color = {1, 1, 1, 1},
        npc_color = {1, 1, 1, 1},
        font = "2002",
        height = 12,
        flags = {
          OUTLINE = "OUTLINE",
          THICK = "", -- THICK
          MONOCHROME = "", -- MONOCHROME
        },
        point = "TOPLEFT",
        relative_point = "TOPLEFT",
        offset_x = 3,
        offset_y = -3,
        horizontal_justification = "LEFT", -- LEFT, CENTER, RIGHT
        vertical_justification = "MIDDLE",-- TOP, MIDDLE, BOTTOM
        max_length = 0.8,
      },
      status = {
        color_mode = 3,
        static_color = {1, 1, 1, 1},
        npc_color = {1, 1, 1, 1},
        font = "2002",
        height = 12,
        flags = {
          OUTLINE = "OUTLINE",
          THICK = "", -- THICK
          MONOCHROME = "", -- MONOCHROME
        },
        point = "CENTER",
        relative_point = "CENTER",
        offset_x = 0,
        offset_y = -5,
        horizontal_justification = "CENTER", -- LEFT, CENTER, RIGHT
        vertical_justification = "MIDDLE",-- TOP, MIDDLE, BOTTOM
        max_length = 1,
      },
    },
    cvars = {
      raidOptionDisplayPets = false,
      raidFramesDisplayAggroHighlight = true,
      raidFramesCenterBigDefensive = true,
      raidFramesDispelIndicatorOverlay = true,
      raidFramesDisplayIncomingHeals = true,
      raidOptionDisplayMainTankAndAssist = true,
    },
    colors = {
      class = {
        DEATHKNIGHT = {
          gradient_start = {0.77, 0.12, 0.23},
          gradient_end   = {0.616, 0.096, 0.184},
          normal_color   = {0.77, 0.12, 0.23},
        },
        DEMONHUNTER = {
          gradient_start = {0.64, 0.19, 0.79},
          gradient_end   = {0.512, 0.152, 0.632},
          normal_color   = {0.64, 0.19, 0.79},
        },
        DRUID = {
          gradient_start = {1, 0.49, 0.04},
          gradient_end   = {0.8, 0.392, 0.032},
          normal_color   = {1, 0.49, 0.04},
        },
        EVOKER = {
          gradient_start = {0.2, 0.58, 0.50},
          gradient_end   = {0.16, 0.464, 0.40},
          normal_color   = {0.2, 0.58, 0.50},
        },
        HUNTER = {
          gradient_start = {0.67, 0.83, 0.45},
          gradient_end   = {0.536, 0.664, 0.36},
          normal_color   = {0.67, 0.83, 0.45},
        },
        MAGE = {
          gradient_start = {0.25, 0.78, 0.92},
          gradient_end   = {0.20, 0.624, 0.736},
          normal_color   = {0.25, 0.78, 0.92},
        },
        MONK = {
          gradient_start = {0, 1, 0.60},
          gradient_end   = {0, 0.8, 0.48},
          normal_color   = {0, 1, 0.60},
        },
        PALADIN = {
          gradient_start = {0.96, 0.55, 0.73},
          gradient_end   = {0.768, 0.44, 0.584},
          normal_color   = {0.96, 0.55, 0.73},
        },
        PRIEST = {
          gradient_start = {1, 1, 1},
          gradient_end   = {0.8, 0.8, 0.8},
          normal_color   = {1, 1, 1},
        },
        ROGUE = {
          gradient_start = {1, 0.96, 0.41},
          gradient_end   = {0.8, 0.768, 0.328},
          normal_color   = {1, 0.96, 0.41},
        },
        SHAMAN = {
          gradient_start = {0, 0.44, 0.87},
          gradient_end   = {0, 0.352, 0.696},
          normal_color   = {0, 0.44, 0.87},
        },
        WARLOCK = {
          gradient_start = {0.53, 0.53, 0.93},
          gradient_end   = {0.424, 0.424, 0.744},
          normal_color   = {0.53, 0.53, 0.93},
        },
        WARRIOR = {
          gradient_start = {0.78, 0.61, 0.43},
          gradient_end   = {0.624, 0.488, 0.344},
          normal_color   = {0.78, 0.61, 0.43},
        },
      },
      power = {
        MANA = {
          gradient_start = {0, 0, 1, 1},
          gradient_end   = {0, 0, 0.7, 1},
          normal_color   = {0, 0, 1, 1},
        },
        RAGE = {
          gradient_start = {1, 0, 0, 1},
          gradient_end   = {0.7, 0, 0, 1},
          normal_color   = {1, 0, 0, 1},
        },
        FOCUS = {
          gradient_start = {1, 0.5, 0.25, 1},
          gradient_end   = {0.7, 0.35, 0.175, 1},
          normal_color   = {1, 0.5, 0.25, 1},
        },
        ENERGY = {
          gradient_start = {1, 1, 0, 1},
          gradient_end   = {0.7, 0.7, 0, 1},
          normal_color   = {1, 1, 0, 1},
        },
        RUNIC_POWER = {
          gradient_start = {0, 0.82, 1, 1},
          gradient_end   = {0, 0.574, 0.7, 1},
          normal_color   = {0, 0.82, 1, 1},
        },
        LUNAR_POWER = {
          gradient_start = {0.3, 0.52, 0.9, 1},
          gradient_end   = {0.21, 0.364, 0.63, 1},
          normal_color   = {0.3, 0.52, 0.9, 1},
        },
        MAELSTROM = {
          gradient_start = {0, 0.5, 1, 1},
          gradient_end   = {0, 0.35, 0.7, 1},
          normal_color   = {0, 0.5, 1, 1},
        },
        FURY = {
          gradient_start = {0.788, 0.259, 0.992, 1},
          gradient_end   = {0.5516, 0.1813, 0.6944, 1},
          normal_color   = {0.788, 0.259, 0.992, 1},
        },
        INSANITY = {
          gradient_start = {0.4, 0, 0.8, 1},
          gradient_end   = {0.28, 0, 0.56, 1},
          normal_color   = {0.4, 0, 0.8, 1},
        },
      },
      npc = {
        HOSTILE = {
          gradient_start = {1, 0, 0},
          gradient_end   = {0.9, 0, 0},
          normal_color   = {1, 0, 0},
        },
        FRIENDLY = {
          gradient_start = {0, 1, 0},
          gradient_end   = {0, 0.9, 0},
          normal_color   = {0, 1, 0},
        },
      }
    },
  },
  global = {
    profiles = {
      ["**"] = {
        party_profile = "Default",
        raid_profile = "Default",
        arena_profile = "Default",
        battleground_profile = "Default",
      },
    },
  },
}

function private:InitDatabase()
  local addon = _G[addon_name]
  addon.db = LibStub("AceDB-3.0"):New(addon_name .. "DB", defaults, true)
  addon.db.RegisterCallback(addon, "OnProfileChanged", "ReloadAllModules")
  addon.db.RegisterCallback(addon, "OnProfileCopied", "ReloadAllModules")
  addon.db.RegisterCallback(addon, "OnProfileReset", "ReloadAllModules")
end

