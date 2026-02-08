local addon_name, private = ...
local main_addon = _G["RaidFrameSettings"]
local data_base = main_addon.db
local L = LibStub("AceLocale-3.0"):GetLocale(addon_name)

local data_manager = {}
private.DataHandler.RegisterDataManager("profiles_settings", data_manager)

local class_id = select(3, UnitClass("player"))
local highlight_color_hex = "cff4A90E2"

local profiles = {}

local function get_profile_tbl(no_current)
  local current_profile = data_base:GetCurrentProfile()
  local profile_list = {}

  for k, v in pairs(data_base:GetProfiles(profiles)) do
    if no_current and v == current_profile then
      -- skip
    else
      table.insert(profile_list, {v, v})
    end
  end

  return profile_list
end

local function generate_options_tbl()
  -- Used to store the delete or copy key.
  local copy_delete_tbl = {
    ["profile_name"] = ""
  }

  local options = {
    [1] = {
      profile_management = {
        order = 1,
        type = "title",
        settings_text = L["profiles_header_1"] .. " ( |" .. highlight_color_hex .. main_addon.db:GetCurrentProfile() .. "|r )",
      },
      create_profile = {
        order = 2,
        type = "input_with_button",
        settings_text = L["create_profile"],
        button_text = L["label_create"],
        button_callback = function(input)
          -- Create the new profile or set if it already exists.
          data_base:SetProfile(input)
          -- Set the current group type profile to the newly created profile
          local current_spec = GetSpecialization()
          local current_spec_name = select(2, GetSpecializationInfoForClassID(class_id, current_spec))
          local current_spec_id = current_spec_name .. class_id
          local group_type = main_addon.GetGroupType()
          main_addon.db.global.profiles[current_spec_id][group_type .. "_profile"] = input
        end,
      },
      reset_profile = {
        order = 3,
        type = "button",
        settings_text = L["reset_profile"],
        button_text = L["label_reset"],
        button_callback = function ()
          data_base:ResetProfile()
        end
      },
      delete_profile = {
        order = 4,
        type = "dropdown",
        settings_text = L["delete_profile"],
        db_obj = copy_delete_tbl,
        db_key = "profile_name",
        options = get_profile_tbl(true),
        associated_modules = function ()
          data_base:DeleteProfile(copy_delete_tbl.profile_name)
        end
      },
      copy_profile = {
        order = 5,
        type = "dropdown",
        settings_text = L["copy_profile"],
        db_obj = copy_delete_tbl,
        db_key = "profile_name",
        options = get_profile_tbl(true),
        associated_modules = function ()
          data_base:CopyProfile(copy_delete_tbl.profile_name)
        end
      },
    },
  }

  -- Create entries for all specs.
  local current_spec = GetSpecialization()
  local current_group_type = main_addon.GetGroupType()
  local num_specs = C_SpecializationInfo.GetNumSpecializationsForClassID(class_id)
  for i=1, num_specs do
    local _, spec_name, _, spec_icon = GetSpecializationInfoForClassID(class_id, i) --@todo add header with icon and add spec icon.
    local spec_id = spec_name .. class_id

    options[1][spec_id] = {
      order = i * 100,
      type = "title",
      settings_text = current_spec == i and "|" .. highlight_color_hex .. spec_name .. "|r" or spec_name,
    }

    for k, group_type_profile in pairs({
      "party_profile",
      "raid_profile",
      "arena_profile",
      "battleground_profile",
    }) do
      options[1][spec_id .. group_type_profile] = {
        order = i * 100 + k,
        type = "dropdown",
        settings_text = current_spec == i and current_group_type .."_profile" == group_type_profile and "|" .. highlight_color_hex .. L[group_type_profile] .. "|r" or L[group_type_profile],
        db_obj = data_base.global.profiles[spec_id],
        db_key = group_type_profile,
        options = get_profile_tbl(),
        associated_modules = function()
          if current_spec == i and current_group_type .."_profile" == group_type_profile then
            data_base:SetProfile(data_base.global.profiles[spec_id][group_type_profile])
          end
        end
      }
    end
  end

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
