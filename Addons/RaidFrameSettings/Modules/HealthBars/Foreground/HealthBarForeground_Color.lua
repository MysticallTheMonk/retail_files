--[[
  Color options:
  1 = Class colored.
  2 = Gradient class colored.
  3 = Static color.
  4 = Static gradient color.
  5 = Health value color.
  8 = Class to HP Value.
--]]

-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

--
local UnitGUID = UnitGUID
local C_CurveUtil_CreateColorCurve = C_CurveUtil.CreateColorCurve
local UnitHealthPercent = UnitHealthPercent
local UnitIsPlayer = UnitIsPlayer
local UnitTreatAsPlayerForDisplay = UnitTreatAsPlayerForDisplay

-- Create a module.
local module = addon:CreateModule("HealthBarForeground_Color")

-- Libs & Utils.
local UnitCache = private.UnitCache

-- We just do the same checks blizzard does and only overwrite it if needed.
local function should_skip_update(cuf_frame)
  if not cuf_frame.unit then
    return true
  end
  --print(cuf_frame.unit)
	local unit_is_connected = UnitIsConnected(cuf_frame.unit)
	local unit_is_dead = unit_is_connected and UnitIsDead(cuf_frame.unit)
  if not unit_is_connected or unit_is_dead then
    return true
  end
  return false
end

local function treat_unit_as_player(unit_id)
  -- UnitTreatAsPlayerForDisplay return false for "player"
  return UnitIsPlayer(unit_id) or UnitTreatAsPlayerForDisplay(unit_id)
end

-- Setup the module.
function module:OnEnable()
  -- Get the data.
  local db_obj = CopyTable(addon.db.profile.health_bars.fg)
  local color_mode = db_obj.color_mode

  local update_color = function() end
  module.update_function = update_color

  if color_mode == 1 then -- Class.
    update_color = function (cuf_frame)
      if should_skip_update(cuf_frame) then
        return
      end
      local color
      local unit_is_player = treat_unit_as_player(cuf_frame.unit) or treat_unit_as_player(cuf_frame.displayedUnit)
      if unit_is_player then
        local guid = UnitGUID(cuf_frame.unit)
        local unit_cache = UnitCache.Get(guid)
        color = addon:GetColor(unit_cache.class)
      else
        if UnitIsEnemy("player", cuf_frame.unit) then
          color = addon:GetColor("HOSTILE")
        else
          color = addon:GetColor("FRIENDLY")
        end
      end
      cuf_frame.healthBar:SetStatusBarColor(unpack(color.normal_color))
    end
  elseif color_mode == 2 then -- Class Gradient.
    local orientation = "HORIZONTAL" -- @TODO Add orientation based on orientation and fill style.
    update_color = function (cuf_frame)
      if should_skip_update(cuf_frame) then
        return
      end
      local color
      local unit_is_player = treat_unit_as_player(cuf_frame.unit) or treat_unit_as_player(cuf_frame.displayedUnit)
      if unit_is_player then
        local guid = UnitGUID(cuf_frame.unit)
        local unit_cache = UnitCache.Get(guid)
        color = addon:GetColor(unit_cache.class)
      else
        if UnitIsEnemy("player", cuf_frame.unit) then
          color = addon:GetColor("HOSTILE")
        else
          color = addon:GetColor("FRIENDLY")
        end
      end
      local texture = cuf_frame.healthBar:GetStatusBarTexture()
      texture:SetGradient(orientation, color.gradient_start, color.gradient_end)
    end
  elseif color_mode == 3 then -- Static.
    local color = db_obj.static_color
    update_color = function (cuf_frame)
      if should_skip_update(cuf_frame) then
        return
      end
      cuf_frame.healthBar:SetStatusBarColor(unpack(color))
    end
  elseif color_mode == 4 then -- Static Gradient.
    local gradient_start = CreateColor(unpack(db_obj.gradient_start))
    local gradient_end = CreateColor(unpack(db_obj.gradient_end))
    local orientation = "HORIZONTAL" -- @TODO Add orientation based on orientation and fill style.
    update_color = function (cuf_frame)
      if should_skip_update(cuf_frame) then
        return
      end
      local texture = cuf_frame.healthBar:GetStatusBarTexture()
      texture:SetGradient(orientation, gradient_start, gradient_end)
    end
  elseif color_mode == 5 then -- HP Value.
    -- Why does this work ?
    -- CompactUnitFrame_UpdateHealthColor always gets called after CompactUnitFrame_UpdateHealth which gets called once per frame by CompactUnitFrame_OnUpdate due to UNIT_HEALTH calling CompactUnitFrame_SetHealthDirty.
    local health_value_colors = addon.db.profile.health_bars.health_value_colors
    local curve = C_CurveUtil_CreateColorCurve()
    curve:ClearPoints()
    curve:AddPoint(0.3, CreateColor(unpack(health_value_colors.low_health)))
    curve:AddPoint(0.7, CreateColor(unpack(health_value_colors.mid_health)))
    curve:AddPoint(1.0, CreateColor(unpack(health_value_colors.max_health)))

    update_color = function (cuf_frame)
      if should_skip_update(cuf_frame) then
        return
      end
      local color = UnitHealthPercent(cuf_frame.unit, true, curve)
      local texture = cuf_frame.healthBar:GetStatusBarTexture()
      texture:SetVertexColor(color:GetRGB())
      --cuf_frame.healthBar:SetStatusBarColor(color:GetRGB()) -- For whatever reason SetStatusBarColor does not accept secret values.
    end
  elseif color_mode == 8 then -- Class -> HP Value
    local color_curves = {}
    local class_colors = addon.db.profile.colors.class
    local health_value_colors = addon.db.profile.health_bars.health_value_colors

    -- Create the class color curves.
    for class, color_obj in pairs(class_colors) do
      local curve = C_CurveUtil_CreateColorCurve()
      curve:ClearPoints()
      curve:AddPoint(0.3, CreateColor(unpack(health_value_colors.low_health)))
      curve:AddPoint(0.7, CreateColor(unpack(health_value_colors.mid_health)))
      curve:AddPoint(1.0, CreateColor(unpack(color_obj.normal_color)))
      color_curves[class] = curve
    end

    -- Create a fall back curve for non player units.
    local fallback_curve = C_CurveUtil_CreateColorCurve()
    fallback_curve:ClearPoints()
    fallback_curve:AddPoint(0.3, CreateColor(unpack(health_value_colors.low_health)))
    fallback_curve:AddPoint(0.7, CreateColor(unpack(health_value_colors.mid_health)))
    fallback_curve:AddPoint(1.0, CreateColor(unpack(health_value_colors.max_health)))

    update_color = function (cuf_frame)
      if should_skip_update(cuf_frame) then
        return
      end

      local curve
      local unit_is_player = treat_unit_as_player(cuf_frame.unit) or treat_unit_as_player(cuf_frame.displayedUnit)
      if unit_is_player then
        local guid = UnitGUID(cuf_frame.unit)
        local unit_cache = UnitCache.Get(guid)
        curve = color_curves[unit_cache.class]
      else
        curve = fallback_curve
      end

      local color = UnitHealthPercent(cuf_frame.unit, true, curve)
      local texture = cuf_frame.healthBar:GetStatusBarTexture()
      texture:SetVertexColor(color:GetRGB())
    end
  end
  self:HookFunc_CUF_Filtered("CompactUnitFrame_UpdateHealthColor", update_color)
  private.IterateRoster(update_color)
  private.IterateMiniRoster(update_color)
end

function module:OnDisable()

end
