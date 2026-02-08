-- Setup the env.
local addon_name, private = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("DebuffFrame")

-- Libs & Utils.
local media = LibStub("LibSharedMedia-3.0")

-- Setup the module.
function module:OnEnable()
  local base_width

  local function on_frame_setup(cuf_frame)
    for _, v in pairs(cuf_frame.debuffFrames) do
      base_width = v:GetWidth()

    end
  end

  self:HookFunc_CUF_Filtered("DefaultCompactUnitFrameSetup", on_frame_setup)
  private.IterateRoster(on_frame_setup)

  local function on_set_debuff(debuffFrame, aura)


  end

  self:HookFunc("CompactUnitFrame_UtilSetDebuff", on_set_debuff)
end

function module:OnDisable()

end
