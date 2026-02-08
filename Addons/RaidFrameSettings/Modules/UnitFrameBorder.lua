-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("UnitFrameBorder")

-- Setup the module.
function module:OnEnable()
  local db_obj = CopyTable(addon.db.profile.module_data.UnitFrameBorder)

  local backdrop_info = {
    edgeFile = db_obj.edge_file,
    tile = db_obj.tile,
    tileEdge = db_obj.tile_edge,
    edgeSize = db_obj.edge_size,
    insets = unpack(db_obj.insets)
  }

  local border_color = db_obj.border_color

  local function set_border(cuf_frame)
    if not cuf_frame.backdropInfo then
      Mixin(cuf_frame, BackdropTemplateMixin)
      cuf_frame:SetBackdrop(backdrop_info)
      cuf_frame:ApplyBackdrop()
    end
    cuf_frame:SetBackdropBorderColor(unpack(border_color))
  end

  self:HookFunc_CUF_Filtered("DefaultCompactUnitFrameSetup", set_border)
  private.IterateRoster(set_border)
  if C_CVar.GetCVar("raidOptionDisplayPets") == "1" or C_CVar.GetCVar("raidOptionDisplayMainTankAndAssist") == "1" then
    self:HookFunc_CUF_Filtered("DefaultCompactMiniFrameSetup", set_border)
    private.IterateMiniRoster(set_border)
  end
end

function module:OnDisable()

end
