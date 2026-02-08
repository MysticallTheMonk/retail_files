--[[
  Color options:
  1 = Class colored.
  3 = Static color.
--]]

-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("Font_Status")

-- Libs & Utils.
local media = LibStub("LibSharedMedia-3.0")
local UnitCache = private.UnitCache

-- Speed references.
local unpack = unpack
local UnitGUID = UnitGUID

local function treat_unit_as_player(unit_id)
  -- UnitTreatAsPlayerForDisplay return false for "player"
  return UnitIsPlayer(unit_id) or UnitTreatAsPlayerForDisplay(unit_id)
end

-- Setup the module.
function module:OnEnable()
  local db_obj = CopyTable(addon.db.profile.fonts.status)
  local font_path = media:Fetch("font", db_obj.font)
  local flags = db_obj.flags.THICK .. db_obj.flags.OUTLINE .. "," .. db_obj.flags.MONOCHROME

  local function set_font_anchors_and_color(cuf_frame)
    if not cuf_frame.unit or not treat_unit_as_player(cuf_frame.unit) then
      return
    end
    local cuf_frame_width = cuf_frame:GetWidth() or 0
    local status_text = cuf_frame.statusText
    status_text:SetJustifyH(db_obj.horizontal_justification)
    -- status_text:SetJustifyV(db_obj.vertical_justification) In this scenario it does nothing as the font strings height is alwys the font height.
    status_text:ClearAllPoints()
    status_text:SetPoint(db_obj.point, cuf_frame, db_obj.relative_point, db_obj.offset_x, db_obj.offset_y)
    status_text:SetFont(font_path, db_obj.height, flags)
    status_text:SetWidth(cuf_frame_width * db_obj.max_length)
    if db_obj.color_mode == 1 then -- class
      local guid = UnitGUID(cuf_frame.unit)
      local unit_cache = UnitCache.Get(guid)
      local color = addon:GetColor(unit_cache.class)
      status_text:SetTextColor(unpack(color.normal_color))
    else -- static
      status_text:SetTextColor(unpack(db_obj.static_color))
    end
  end

  self:HookFunc_CUF_Filtered("DefaultCompactUnitFrameSetup", set_font_anchors_and_color)
  private.IterateRoster(set_font_anchors_and_color)
end

function module:OnDisable()

end
