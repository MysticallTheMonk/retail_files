-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("CVar_raidFramesDisplayAggroHighlight")


-- Setup the module.
function module:OnEnable()
  local cvar_value = addon.db.profile.cvars.raidFramesDisplayAggroHighlight and "1" or "0"
  if C_CVar.GetCVar("raidFramesDisplayAggroHighlight") ~= cvar_value then
    C_CVar.SetCVar("raidFramesDisplayAggroHighlight", cvar_value)
  end
end

