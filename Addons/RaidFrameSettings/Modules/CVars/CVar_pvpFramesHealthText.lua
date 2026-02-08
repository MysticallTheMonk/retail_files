-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]


-- Create a module.
local module = addon:CreateModule("CVar_pvpFramesHealthText")


-- Setup the module.
function module:OnEnable()
  local cvar_value = addon.db.profile.module_data.health_text_display_mode
  if C_CVar.GetCVar("pvpFramesHealthText") ~= cvar_value then
    C_CVar.SetCVar("pvpFramesHealthText", cvar_value)
  end
end

