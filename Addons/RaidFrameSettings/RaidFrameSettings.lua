local addon_name, private = ...
local addon = _G[addon_name]
local L = LibStub("AceLocale-3.0"):GetLocale(addon_name)

local function init_addon()
  -- Init Database
  private:InitDatabase()
end

local function load_addon()
  private.CreateOrUpdateFrameEnv()
  for _, module in addon:IterateModules() do
    if addon.db.profile.module_status[module:GetName()] == true then
      module:Enable()
    end
  end
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")

frame:SetScript("OnEvent", function(self, event, name)
  if event == "GROUP_ROSTER_UPDATE" then
    private.CreateOrUpdateFrameEnv()
  elseif event == "ADDON_LOADED" and name == addon_name then
    init_addon()
  elseif event == "PLAYER_ENTERING_WORLD" then
    load_addon()
  end
end)

-- Also used by addon compartment.
function RaidFrameSettings_OpenSettings()

  if InCombatLockdown() then
    addon:Print(L["combat_lockdown_msg"])
    return
  end

  local guid = UnitGUID("player")
  local rfs_options_state = C_AddOns.GetAddOnEnableState("RaidFrameSettingsOptions", guid)
  if rfs_options_state ~= 2 then
    addon:Print(L["rfs_option_not_enabled_msg"])
    --C_AddOns.EnableAddOn("RaidFrameSettingsOptions")
    return
  end

  if not C_AddOns.IsAddOnLoaded("RaidFrameSettingsOptions") then
    C_AddOns.LoadAddOn("RaidFrameSettingsOptions")
  end

  RaidFrameSettingsOptions:Show()

end

-- Register slash commands.
SLASH_RAID_FRAME_SETTINGS1 = "/rfs"
SlashCmdList.RAID_FRAME_SETTINGS = RaidFrameSettings_OpenSettings
