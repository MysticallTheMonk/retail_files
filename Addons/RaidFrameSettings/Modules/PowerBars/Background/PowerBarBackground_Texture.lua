-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("PowerBarBackground_Texture")

-- Libs & Utils.
local media = LibStub("LibSharedMedia-3.0")

local DEFAULT_TEXTURE = "" --@TODO Find new default texture name.

-- Setup the module.
function module:OnEnable()
  local texture_name = addon.db.profile.power_bars.bg.texture
  if texture_name == DEFAULT_TEXTURE then return end
  local texture_path = media:Fetch("statusbar", texture_name)

  local function set_texture(cuf_frame)
    cuf_frame.powerBar.background:SetTexture(texture_path)
  end
  module.update_function = set_texture

  self:HookFunc_CUF_Filtered("DefaultCompactUnitFrameSetup", set_texture)
  private.IterateRoster(set_texture)
end

function module:OnDisable()

end
