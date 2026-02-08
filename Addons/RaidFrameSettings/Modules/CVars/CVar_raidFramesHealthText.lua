-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]


-- Create a module.
local module = addon:CreateModule("CVar_raidFramesHealthText")


-- Setup the module.
function module:OnEnable()
  local cvar_value = addon.db.profile.module_data.health_text_display_mode
  if C_CVar.GetCVar("raidFramesHealthText") ~= cvar_value then
    C_CVar.SetCVar("raidFramesHealthText", cvar_value)
  end
end

