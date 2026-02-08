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

-- Speed refernce.
local UnitPowerType = UnitPowerType

-- Create a module.
local module = addon:CreateModule("PowerBarForeground_Color")

local function skip_update(cuf_frame)
  if not cuf_frame.powerBar or not cuf_frame.unit then
    return true
  end
  return false
end

-- Setup the module.
function module:OnEnable()
  -- Get the data.
  local db_obj = CopyTable(addon.db.profile.power_bars.fg)
  local color_mode = db_obj.color_mode

  local update_color = function() end
  module.update_function = update_color

  if color_mode == 3 then -- Static.
    local color = db_obj.static_color
    update_color = function (cuf_frame)
      if skip_update(cuf_frame) then
        return
      end
      cuf_frame.powerBar:SetStatusBarColor(unpack(color))
    end
  elseif color_mode == 4 then -- Static gradient.
    local gradient_start = CreateColor(unpack(db_obj.gradient_start))
    local gradient_end = CreateColor(unpack(db_obj.gradient_end))
    local orientation = "HORIZONTAL" -- @TODO Add orientation based on orientation and fill style.
    update_color = function (cuf_frame)
      if skip_update(cuf_frame) then
        return
      end
      local texture = cuf_frame.powerBar:GetStatusBarTexture()
      -- Sad but it sometimes is nil. @TODO check if still true.
      if not texture then
        print(cuf_frame.unit, " No power bar texture found.")
        return
      end
      texture:SetGradient(orientation, gradient_start, gradient_end)
    end
  elseif color_mode == 6 then -- Power type.
    update_color = function (cuf_frame)
      if skip_update(cuf_frame) then
        return
      end
      local power_token = select(2, UnitPowerType(cuf_frame.unit))
      local color_obj = addon:GetColor(power_token or "MANA")
      cuf_frame.powerBar:SetStatusBarColor(unpack(color_obj.normal_color))
    end
  elseif color_mode == 7 then -- Power type gradient.
    local orientation = "HORIZONTAL" -- @TODO Add orientation based on orientation and fill style.
    update_color = function (cuf_frame)
      if skip_update(cuf_frame) then
        return
      end
      local power_token = select(2, UnitPowerType(cuf_frame.unit))
      local color_obj = addon:GetColor(power_token or "MANA")
      local texture = cuf_frame.powerBar:GetStatusBarTexture()
      texture:SetGradient(orientation, color_obj.gradient_start, color_obj.gradient_end)
    end
  end

  self:HookFunc_CUF_Filtered("CompactUnitFrame_UpdatePowerColor", update_color)
  private.IterateRoster(update_color)
end

function module:OnDisable()

end
