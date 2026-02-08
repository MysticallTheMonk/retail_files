-- Setup the env.
local addon_name = ...
local addon = _G[addon_name]

-- Create a module.
local module = addon:CreateModule("SoloFrame")

-- WoW Api
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup


function module:OnEnable()
  local function on_update_party_frame_visibility()
    if IsInGroup() then
      return
    end
    if InCombatLockdown() then
      self:RegisterForEvent("PLAYER_REGEN_ENABLED", on_update_party_frame_visibility)
      return
    else
      self:UnregisterFromEvent("PLAYER_REGEN_ENABLED")
    end
    CompactPartyFrame:SetShown(true)
    local cuf_frame = _G["CompactPartyFrameMember1HealthBar"]:GetParent()
    if cuf_frame and cuf_frame.RFS_FrameEnvironment then
      cuf_frame.RFS_FrameEnvironment:Start()
    end
  end

  self:HookFunc(CompactPartyFrame, "UpdateVisibility", on_update_party_frame_visibility)
  on_update_party_frame_visibility()
  PartyFrame:UpdatePaddingAndLayout()
end

function module:OnDisable()
  self:DisableHooks()
  if IsInGroup() then
    return
  end
  CompactPartyFrame:SetShown(false)
  PartyFrame:UpdatePaddingAndLayout()
end
