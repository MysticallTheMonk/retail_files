--[[Created by Slothpala]]--
local addon_name, private = ...
local addon = _G[addon_name]

local class_id = select(3, UnitClass("player"))
-- The data for spec_id and spec_name is sometimes not available at login, so we request it on PLAYER_ENTERING_WORLD.
local spec_id
local spec_name
local current_spec

local group_type = ""

local group_profiles = {
  ["party"] = "party_profile",
  ["raid"] = "raid_profile",
  ["arena"] = "arena_profile",
  ["battleground"] = "battleground_profile",
}

local function check_group_profile()
  local new_group_type = addon.GetGroupType()
  if new_group_type == group_type then
    return
  end
  local new_profile = addon.db.global.profiles[spec_id][group_profiles[new_group_type]]
  local current_profile = addon.db:GetCurrentProfile()
  if current_profile == new_profile then
    return
  end
  addon.db:SetProfile(new_profile)
  group_type = new_group_type
end

local event_frame = CreateFrame("Frame")
event_frame:RegisterEvent("GROUP_ROSTER_UPDATE")
event_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
event_frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
event_frame:SetScript("OnEvent", function(_, event, arg1, arg2)
  if event == "PLAYER_ENTERING_WORLD" and ( arg1 or arg2 ) then -- arg1 = initial login, arg2 = reloading. Both can be false when zoning out of instance for example.
    current_spec = GetSpecialization()
    spec_name = select(2, GetSpecializationInfoForClassID(class_id, current_spec))
    spec_id = spec_name .. class_id
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    current_spec = GetSpecialization()
    spec_name = select(2, GetSpecializationInfoForClassID(class_id, current_spec))
    spec_id = spec_name .. class_id
    group_type = "" -- This is done to bypass the check.
  end
  check_group_profile()
end)

function addon:LoadGroupProfile()
  group_type = self.GetGroupType()
  local profile = self.db.global.profiles[spec_id][group_profiles[group_type]]
  self.db:SetProfile(profile)
end
