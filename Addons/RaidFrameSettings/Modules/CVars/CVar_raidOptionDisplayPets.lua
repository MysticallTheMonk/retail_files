-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Libs & Utils.
local CR = private.CallbackRegistry

-- Create a module.
local module = addon:CreateModule("CVar_raidOptionDisplayPets")


-- Setup the module.
function module:OnEnable()
  C_CVar.SetCVar("raidOptionDisplayPets", addon.db.profile.cvars.raidOptionDisplayPets and "1" or "0")
end

