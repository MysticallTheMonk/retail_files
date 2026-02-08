-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Local references
local UnitGroupRolesAssigned = UnitGroupRolesAssigned

-- Create a module.
local module = addon:CreateModule("RoleIcon")

-- Setup the module.
function module:OnEnable()
  local db_obj = CopyTable(addon.db.profile.module_data.RoleIcon)

  local function update_role_icon_position_and_visibility(cuf_frame)
    local role_icon = cuf_frame.roleIcon

    if not role_icon then
      return
    end

      -- The unit and the displayedUnit differ, for example, when a unit is in a vehicle, as in Wintergrasp BG.
    local role = UnitGroupRolesAssigned(cuf_frame.displayedUnit)
    local should_hide_icon = ( role == "DAMAGER" and not db_obj.show_for_dps ) or ( role == "HEALER" and not db_obj.show_for_heal ) or ( role == "TANK" and not db_obj.show_for_tank )

    if should_hide_icon then
      cuf_frame.roleIcon:Hide()
      return
    end

    role_icon:ClearAllPoints()
    role_icon:SetPoint(db_obj.point, cuf_frame, db_obj.relative_point, db_obj.offset_x, db_obj.offset_y)
  end
  module.update_function = update_role_icon_position_and_visibility

  self:HookFunc_CUF_Filtered("CompactUnitFrame_UpdateRoleIcon", update_role_icon_position_and_visibility)
  private.IterateRoster(update_role_icon_position_and_visibility)
end

function module:OnDisable()
  local function show_role_icon(cuf_frame)
    local role_icon = cuf_frame.roleIcon

    if not role_icon then
      return
    end

    cuf_frame.roleIcon:Show()
  end

  private.IterateRoster(show_role_icon)
end
