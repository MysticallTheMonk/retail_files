-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local cvar = "raidFramesCenterBigDefensive"
local module = addon:CreateModule("CVar_" .. cvar)


-- Setup the module.
function module:OnEnable()
  local cvar_value = addon.db.profile.cvars[cvar] and "1" or "0"
  if C_CVar.GetCVar(cvar) ~= cvar_value then
    C_CVar.SetCVar(cvar, cvar_value)
  end
end


