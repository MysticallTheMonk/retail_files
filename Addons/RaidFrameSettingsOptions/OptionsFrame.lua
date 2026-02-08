local addon_name, private = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addon_name)

-- Main Frame
local frame = CreateFrame("Frame", "RaidFrameSettingsOptions", UIParent, "PortraitFrameTemplate")

-- Icon
RaidFrameSettingsOptionsPortrait:SetTexture("Interface\\AddOns\\RaidFrameSettings\\Data\\Textures\\Icon.tga")

-- Set the title text.
frame.title = _G["RaidFrameSettingsOptionsTitleText"]
frame.title:SetText("RaidFrameSettings")

-- Inset Frame.
frame.inset_frame = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
frame.inset_frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -60)
frame.inset_frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -25, 25)

-- Scroll Box.
frame.inset_frame.scroll_box = CreateFrame("Frame", nil, frame.inset_frame, "WowScrollBoxList")
frame.inset_frame.scroll_box:SetPoint("TOPLEFT", frame.inset_frame, "TOPLEFT", 4, -4)
frame.inset_frame.scroll_box:SetPoint("BOTTOMRIGHT", frame.inset_frame, "BOTTOMRIGHT", -4, 4)

-- Scroll Bar.
frame.inset_frame.scroll_bar = CreateFrame("EventFrame", nil, frame.inset_frame, "MinimalScrollBar")
frame.inset_frame.scroll_bar:SetPoint("TOPLEFT", frame.inset_frame, "TOPRIGHT", 7, 0)
frame.inset_frame.scroll_bar:SetPoint("BOTTOMLEFT", frame.inset_frame, "BOTTOMRIGHT", 7, 0)

-- Initialize the Scroll View.
frame.scroll_view = CreateScrollBoxListTreeListView()
frame.scroll_view:SetPadding(10, 10, 10, 10, 4)
ScrollUtil.InitScrollBoxListWithScrollBar(frame.inset_frame.scroll_box, frame.inset_frame.scroll_bar, frame.scroll_view)

frame.Bg:SetColorTexture(0.1,0.1,0.1,0.95)
frame:SetFrameStrata("DIALOG") -- @TODO: Check best options.
table.insert(UISpecialFrames, frame:GetName())
frame:SetSize(925,525)
frame:SetResizeBounds(925, 400)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetMovable(true)
frame:SetResizable(true)
frame.TitleContainer:SetScript("OnMouseDown", function()
  frame:StartMoving()
  frame:SetAlpha(0.9)
end)
frame.TitleContainer:SetScript("OnMouseUp", function()
  frame:StopMovingOrSizing()
  frame:SetAlpha(1)
end)

-- Resize Handle
frame.resizeHandle = CreateFrame("Button", nil, frame)
frame.resizeHandle:SetPoint("BOTTOMRIGHT",-1,1)
frame.resizeHandle:SetSize(26, 26)
frame.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
frame.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
frame.resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
frame.resizeHandle:SetScript("OnMouseDown", function(_, button)
  if button == "LeftButton" then
    frame:StartSizing("BOTTOMRIGHT")
  end
end)
frame.resizeHandle:SetScript("OnMouseUp", function(_, button)
  if button == "LeftButton" then
    frame:StopMovingOrSizing()
  end
end)

-- Tab System.
frame.tab_system = CreateFrame("Frame", nil, frame, "TabSystemTemplate")
frame.tab_system:SetFrameStrata("DIALOG")
frame.tab_system.tabs = {}
frame.tab_system:SetTabSelectedCallback(function()end)
frame.tab_system:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 15, 2)
for k, category in pairs({
  L["general_settings"],
  L["text_settings"],
  L["profiles_settings"],
}) do
  frame.tab_system:AddTab(category)
  local tab = frame.tab_system:GetTabButton(k)
  local min_width = tab.Left:GetWidth() + tab.Middle:GetWidth() + tab.Right:GetWidth()
  local text_width = tab.Text:GetWidth() + 20
  tab:SetWidth(math.max(min_width, text_width))
  frame.tab_system.tabs[category] = tab
  frame.tab_system:SetTab(1) -- On first start show "General".
end

--
frame.tab_system.tabs[L["general_settings"]]:HookScript("OnClick", function()
  private.SetDataProvider("general_settings")
end)

-- text_settings
frame.tab_system.tabs[L["text_settings"]]:HookScript("OnClick", function()
  private.SetDataProvider("text_settings")
end)

-- profiles_settings
frame.tab_system.tabs[L["profiles_settings"]]:HookScript("OnClick", function()
  private.SetDataProvider("profiles_settings")
end)

function private.GetOptionsFrame()
  return frame
end
