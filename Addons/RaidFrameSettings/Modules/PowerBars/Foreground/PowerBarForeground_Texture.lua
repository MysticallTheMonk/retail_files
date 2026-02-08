-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("PowerBarForeground_Texture")

-- Libs & Utils.
local media = LibStub("LibSharedMedia-3.0")

-- Local references
local UnitGroupRolesAssigned = UnitGroupRolesAssigned

local DEFAULT_TEXTURE = "" --@TODO Find new default texture name.

-- Setup the module.
function module:OnEnable()
  local texture_name = addon.db.profile.power_bars.fg.texture
  if texture_name == DEFAULT_TEXTURE then return end
  local texture_path = media:Fetch("statusbar", texture_name)

  local function is_power_bar_shown(cuf_frame)
    if not cuf_frame.powerBar then
      return false
    end
    local options = DefaultCompactUnitFrameSetupOptions
    local display_power_bar = CompactUnitFrame_GetOptionDisplayPowerBar(cuf_frame, options)
    local display_only_healer_power_bars = CompactUnitFrame_GetOptionDisplayOnlyHealerPowerBars(cuf_frame, options)
    local role = UnitGroupRolesAssigned(cuf_frame.unit)
    return display_power_bar and (not display_only_healer_power_bars or role == "HEALER")
  end

  local function set_statusbar_texture(cuf_frame)
    if is_power_bar_shown(cuf_frame) then
      cuf_frame.powerBar:SetStatusBarTexture(texture_path)
      cuf_frame.powerBar:GetStatusBarTexture():SetDrawLayer("BORDER")
    end
  end

  self:HookFunc_CUF_Filtered("DefaultCompactUnitFrameSetup", set_statusbar_texture)
  private.IterateRoster(set_statusbar_texture)
end

function module:OnDisable()

end
