-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Libs & Utils.
local CR = private.CallbackRegistry

-- Create a module.
local module = addon:CreateModule("CVar_raidFramesDisplayOnlyHealerPowerBars")


-- Setup the module.
function module:OnEnable()
  local power_bar_display_mode = addon.db.profile.module_data.power_bar_display_mode
  local cvar_value = power_bar_display_mode == 2 and "1" or "0"
  if C_CVar.GetCVar("raidFramesDisplayOnlyHealerPowerBars") ~= cvar_value then
    C_CVar.SetCVar("raidFramesDisplayOnlyHealerPowerBars", cvar_value)
  end
end


