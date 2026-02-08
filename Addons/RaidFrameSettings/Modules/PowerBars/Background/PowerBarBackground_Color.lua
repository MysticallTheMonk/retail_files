--[[
  Color options:
    3 = Static color.
    4 = Static gradient color.
    6 = Color by power type.
    7 = Color by power type gradient.
--]]

-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("PowerBarBackground_Color")

-- Speed refernce.
local UnitPowerType = UnitPowerType

local function skip_update(cuf_frame)
  if not cuf_frame.powerBar or not cuf_frame.unit then
    return true
  end
  return false
end

-- Setup the module.
function module:OnEnable()
  -- Get the data.
  local db_obj = CopyTable(addon.db.profile.power_bars.bg)
  local color_mode = db_obj.color_mode

  local update_color = function() end
  module.update_function = update_color

  local darkened_colors  = {}
  if color_mode == 6 or color_mode == 7 then
    for type, color in pairs(addon.db.profile.colors.power) do
      darkened_colors[type] = {
        normal_color = {color.normal_color[1] * db_obj.darkening_factor, color.normal_color[2] * db_obj.darkening_factor, color.normal_color[3] * db_obj.darkening_factor, 1}
      }
      if color_mode == 7 then
        local r, g, b, a = unpack(color.gradient_start)
        darkened_colors[type].gradient_start = CreateColor(r * db_obj.darkening_factor, g * db_obj.darkening_factor, b * db_obj.darkening_factor, a)
        r, g, b, a = unpack(color.gradient_end)
        darkened_colors[type].gradient_end = CreateColor(r * db_obj.darkening_factor, g * db_obj.darkening_factor, b * db_obj.darkening_factor, a)
      end
    end
  end

  if color_mode == 3 then -- Static.
    local color = db_obj.static_color
    update_color = function (cuf_frame)
      if skip_update(cuf_frame) then
        return
      end
      cuf_frame.powerBar.background:SetVertexColor(unpack(color))
    end
  elseif color_mode == 4 then -- Static gradient.
    local gradient_start = CreateColor(unpack(db_obj.gradient_start))
    local gradient_end = CreateColor(unpack(db_obj.gradient_end))
    local orientation = "HORIZONTAL" -- @TODO Add orientation based on orientation and fill style.
    update_color = function (cuf_frame)
      if skip_update(cuf_frame) then
        return
      end
      cuf_frame.powerBar.background:SetGradient(orientation, gradient_start, gradient_end)
    end
  elseif color_mode == 6 then -- Power type.
    update_color = function (cuf_frame)
      if skip_update(cuf_frame) then
        return
      end
      local power_token = select(2, UnitPowerType(cuf_frame.unit)) or "MANA"
      local color_obj = darkened_colors[power_token] or darkened_colors["MANA"]
      cuf_frame.powerBar.background:SetVertexColor(unpack(color_obj.normal_color))
    end
  elseif color_mode == 7 then -- Power type gradient.
    local orientation = "HORIZONTAL" -- @TODO Add orientation based on orientation and fill style.
    update_color = function (cuf_frame)
      if skip_update(cuf_frame) then
        return
      end
      local power_token = select(2, UnitPowerType(cuf_frame.unit)) or "MANA"
      local color_obj = darkened_colors[power_token] or darkened_colors["MANA"]
      cuf_frame.powerBar.background:SetGradient(orientation, color_obj.gradient_start, color_obj.gradient_end)
    end
  end

  self:HookFunc_CUF_Filtered("CompactUnitFrame_UpdatePowerColor", update_color)
  private.IterateRoster(update_color)
end

function module:OnDisable()

end
