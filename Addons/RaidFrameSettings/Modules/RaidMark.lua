-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Libs & Utils
local CR = private.CallbackRegistry

-- Create a module.
local module = addon:CreateModule("RaidMark")

-- Local references
local SetRaidTargetIconTexture = SetRaidTargetIconTexture

-- Setup the module.
function module:OnEnable()
  local db_obj = CopyTable(addon.db.profile.module_data.RaidMark)

  local function update_raid_mark(cuf_frame)
    local unit = cuf_frame.unit
    if not UnitExists(unit) then
      return
    end
    local raid_target_index = GetRaidTargetIndex(unit)
    local texture = cuf_frame.RFS_FrameEnvironment.module_data.RaidMark.texture
    if raid_target_index then
      SetRaidTargetIconTexture(texture, raid_target_index)
      texture:Show()
    else
      texture:Hide()
    end
  end

  local function create_or_update_raid_marker(cuf_frame)
    local frame_env = cuf_frame.RFS_FrameEnvironment

    if not frame_env.module_data.RaidMark then
      local raid_mark_data = {}
      local frame = frame_env.frame
      local texture = frame:CreateTexture()
      texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
      texture:Hide()
      raid_mark_data.texture = texture
      frame_env.module_data.RaidMark = raid_mark_data
    end

    local texture = frame_env.module_data.RaidMark.texture
    texture:ClearAllPoints()
    texture:SetPoint(db_obj.point, cuf_frame, db_obj.relative_point, db_obj.offset_x, db_obj.offset_y)
    texture:SetSize(28, 28)
    texture:SetScale(db_obj.scale)

    update_raid_mark(cuf_frame)
  end

  self:RegisterForEvent("RAID_TARGET_UPDATE", function()
    private.IterateRoster(update_raid_mark, true)
    private.IterateMiniRoster(update_raid_mark, true)
  end)

  CR.RegisterCallback("FRAME_ENV_CREATED", create_or_update_raid_marker)
  private.IterateRoster(create_or_update_raid_marker, true)
  private.IterateMiniRoster(create_or_update_raid_marker, true)
end

function module:OnDisable()

end
