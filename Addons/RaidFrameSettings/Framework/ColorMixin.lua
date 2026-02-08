local addon_name, private = ...
private.Mixins.ColorMixin = {}
local color_mixin = private.Mixins.ColorMixin

-- ColorMixin object that can be shared between modules.
local color_cache = {}

local fallback_color = {
  gradient_start = {1, 1, 1, 1},
  gradient_end   = {1, 1, 1, 1},
  normal_color   = {1, 1, 1, 1},
}

local function create_colors(key)
  local db_obj = _G[addon_name].db.profile.colors.class[key] or
                 _G[addon_name].db.profile.colors.power[key] or
                 _G[addon_name].db.profile.colors.npc[key] or
                 fallback_color
  local pres_db_obj = CopyTable(db_obj)
  color_cache[key] = {
    gradient_start = CreateColor(unpack(pres_db_obj["gradient_start"])),
    gradient_end = CreateColor(unpack(pres_db_obj["gradient_end"])),
    normal_color = pres_db_obj.normal_color,
  }
end

function color_mixin:GetColor(key)
  if not color_cache[key] then
    create_colors(key)
  end
  return color_cache[key]
end

function color_mixin:UpdateColorCache()
  for k, _ in pairs(color_cache) do
    create_colors(k)
  end
end
