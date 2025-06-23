if not C_AddOns.IsAddOnLoaded("FrameColor") then
  return
end

local options = {
  name = "_MouseoverActionSettings",
  displayedName = "Mouseover Action Settings",
  order = 1,
  category = "AddonSkins",
  colors = {
    ["main"] = {
      name = "",
      order = 1,
      rgbaValues = {0.28, 0.28, 0.28, 1},
    },
    ["background"] = {
      name = "",
      order = 2,
      rgbaValues = {0.55, 0.55, 0.55, 1},
    },
    ["controls"] = {
      order = 4,
      name = "",
      rgbaValues = {0.5, 0.5, 0.5, 1},
    },
    ["tabs"] = {
      order = 5,
      name = "",
      rgbaValues = {0.18, 0.18, 0.18, 1},
    },
  }
}

local skin = {}

function skin:OnEnable()
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("controls"), self:GetColor("tabs"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, controlsColor, tabsColor, desaturation)
  if not MouseoverActionSettingsOptions then
    return
  end

  -- Main frame.
  self:SkinNineSliced(MouseoverActionSettingsOptions, mainColor, desaturation)

  -- Background.  
  for _, texture in pairs({
    MouseoverActionSettingsOptions.Bg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Controls.
  self:SkinBox(MouseoverActionSettingsOptions.searchBox, controlsColor, desaturation)

  -- Tabs.
  self:SkinTabs(MouseoverActionSettingsOptions, tabsColor, desaturation)
end

-- Register the Skin
FrameColor.API:RegisterSkin(skin, options)
FrameColor.API:UpdateDefaults()