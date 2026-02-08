--[[
  Color options:
  1 = Class colored.
  3 = Static color.
--]]

-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("Font_Name")

-- Libs & Utils.
local media = LibStub("LibSharedMedia-3.0")
local UnitCache = private.UnitCache

-- Speed references.

-- Setup the module.
function module:OnEnable()
  local db_obj = CopyTable(addon.db.profile.fonts.name)
  local font_path = media:Fetch("font", db_obj.font)
  local flags = db_obj.flags.THICK .. db_obj.flags.OUTLINE .. "," .. db_obj.flags.MONOCHROME

  local is_pets_shown = C_CVar.GetCVar("raidOptionDisplayPets") == "1"
  local is_tanks_shown = C_CVar.GetCVar("raidOptionDisplayMainTankAndAssist") == "1"

  local function set_font_and_anchors(cuf_frame)
    local cuf_frame_width = cuf_frame:GetWidth() or 0
    local name_text = cuf_frame.name
    name_text:SetJustifyH(db_obj.horizontal_justification)
    -- name_text:SetJustifyV(db_obj.vertical_justification) In this scenario it does nothing as the font strings height is alwys the font height.
    name_text:ClearAllPoints()
    name_text:SetPoint(db_obj.point, cuf_frame, db_obj.relative_point, db_obj.offset_x, db_obj.offset_y)
    name_text:SetFont(font_path, db_obj.height, flags)
    name_text:SetWidth(cuf_frame_width * db_obj.max_length )
  end

  self:HookFunc_CUF_Filtered("DefaultCompactUnitFrameSetup", set_font_and_anchors)
  if is_pets_shown or is_tanks_shown then
    self:HookFunc_CUF_Filtered("DefaultCompactMiniFrameSetup", set_font_and_anchors)
  end


  local function set_name_text_color(cuf_frame)
    local is_player = UnitIsPlayer(cuf_frame.unit) or UnitInPartyIsAI(cuf_frame.unit)
    local name_text = cuf_frame.name
    if is_player then
      local guid = UnitGUID(cuf_frame.unit)
      local unit_cache = UnitCache.Get(guid)
      name_text:SetText(unit_cache.nickname) -- nickname defaults to name if not set.
      if db_obj.color_mode == 1 then -- class
        local color = addon:GetColor(unit_cache.class)
        name_text:SetTextColor(color.normal_color[1], color.normal_color[2], color.normal_color[3])
      else
        name_text:SetTextColor(db_obj.static_color[1], db_obj.static_color[2], db_obj.static_color[3])
      end
    else
      name_text:SetTextColor(db_obj.npc_color[1], db_obj.npc_color[2], db_obj.npc_color[3])
    end
  end

  self:HookFunc_CUF_Filtered("CompactUnitFrame_UpdateName", set_name_text_color)

  private.IterateRoster(function(cuf_frame)
    set_font_and_anchors(cuf_frame)
    set_name_text_color(cuf_frame)
  end)

  if is_pets_shown or is_tanks_shown then
    private.IterateMiniRoster(set_font_and_anchors)
    private.IterateMiniRoster(set_name_text_color)
  end
end

function module:OnDisable()

end
