--[[
  Color options:
  1 = Class colored.
  2 = Gradient class colored.
  3 = Static color.
  4 = Static gradient color.
--]]

-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("HealthBarBackground_Color")

-- Libs & Utils.
local UnitCache = private.UnitCache

local function treat_unit_as_player(unit_id)
  -- UnitTreatAsPlayerForDisplay return false for "player"
  return UnitIsPlayer(unit_id) or UnitTreatAsPlayerForDisplay(unit_id)
end

-- Setup the module.
function module:OnEnable()
  -- Get the data.
  local db_obj = CopyTable(addon.db.profile.health_bars.bg)
  local color_mode = db_obj.color_mode

  local update_color = function() end
  module.update_function = update_color

  local darkened_colors  = {}
  if color_mode == 1 or color_mode == 2 then
    for _, color_type in pairs({
      "class",
      "npc",
    }) do
      for type, color in pairs(addon.db.profile.colors[color_type]) do
        darkened_colors[type] = {
          normal_color = {color.normal_color[1] * db_obj.darkening_factor, color.normal_color[2] * db_obj.darkening_factor, color.normal_color[3] * db_obj.darkening_factor, 1}
        }
        if color_mode == 2 then
          local r, g, b, a = unpack(color.gradient_start)
          darkened_colors[type].gradient_start = CreateColor(r * db_obj.darkening_factor, g * db_obj.darkening_factor, b * db_obj.darkening_factor, a)
          r, g, b, a = unpack(color.gradient_end)
          darkened_colors[type].gradient_end = CreateColor(r * db_obj.darkening_factor, g * db_obj.darkening_factor, b * db_obj.darkening_factor, a)
        end
      end
    end
  end

  if color_mode == 1 then -- Class
    update_color = function (cuf_frame)
      if not cuf_frame.unit then
        return true
      end
      local color
      local unit_is_player = treat_unit_as_player(cuf_frame.unit) or treat_unit_as_player(cuf_frame.displayedUnit)
      if unit_is_player then
        local guid = UnitGUID(cuf_frame.unit)
        local unit_cache = UnitCache.Get(guid)
        color = darkened_colors[unit_cache.class]
      else
        if UnitIsEnemy("player", cuf_frame.unit) then
          color = darkened_colors["HOSTILE"]
        else
          color = darkened_colors["FRIENDLY"]
        end
      end
      cuf_frame.background:SetVertexColor(unpack(color.normal_color))
    end
  elseif color_mode == 2 then -- Class Gradient
    local orientation = "HORIZONTAL" -- @TODO Add orientation based on orientation and fill style.
    update_color = function (cuf_frame)
      if not cuf_frame.unit then
        return true
      end
      local color
      local unit_is_player = treat_unit_as_player(cuf_frame.unit) or treat_unit_as_player(cuf_frame.displayedUnit)
      if unit_is_player then
        local guid = UnitGUID(cuf_frame.unit)
        local unit_cache = UnitCache.Get(guid)
        color = darkened_colors[unit_cache.class]
      else
        if UnitIsEnemy("player", cuf_frame.unit) then
          color = darkened_colors["HOSTILE"]
        else
          color = darkened_colors["FRIENDLY"]
        end
      end
      cuf_frame.background:SetGradient(orientation, color.gradient_start, color.gradient_end)
    end
  elseif color_mode == 3 then -- Static
    local color = db_obj.static_color
    update_color = function (cuf_frame)
      cuf_frame.background:SetVertexColor(unpack(color))
    end
  elseif color_mode == 4 then -- Static Gradient
    local gradient_start = CreateColor(unpack(db_obj.gradient_start))
    local gradient_end = CreateColor(unpack(db_obj.gradient_end))
    local orientation = "HORIZONTAL" -- @TODO Add orientation based on orientation and fill style.
    update_color = function (cuf_frame)
      cuf_frame.background:SetGradient(orientation, gradient_start, gradient_end)
    end
  end

  -- Apply the changes.
  self:HookFunc_CUF_Filtered("CompactUnitFrame_UpdateHealthColor", update_color)
  private.IterateRoster(update_color)
  private.IterateMiniRoster(update_color)
end

function module:OnDisable()

end
