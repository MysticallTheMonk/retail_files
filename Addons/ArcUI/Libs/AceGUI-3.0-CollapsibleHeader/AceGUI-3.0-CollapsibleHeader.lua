--[[
  AceGUI-3.0-CollapsibleHeader
  A clickable header that toggles between expanded/collapsed states
  Shows an arrow icon and text - clicking anywhere on it toggles state
  
  Usage in AceConfig options table:
    myHeader = {
      type = "toggle",
      name = "Section Name",
      dialogControl = "CollapsibleHeader",
      get = function() return not collapsed end,
      set = function(info, value) collapsed = not value end,
    }
    
  For indented subsections, prefix the name with spaces:
    mySubHeader = {
      type = "toggle",
      name = "    Subsection Name",  -- 4 spaces = 1 indent level
      dialogControl = "CollapsibleHeader",
      ...
    }
]]

local Type = "CollapsibleHeader"
local Version = 9  -- Bumped version for reduced indent

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs
local string_match = string.match
local string_gsub = string.gsub

-- WoW APIs
local CreateFrame = CreateFrame

-- Constants
local INDENT_PER_LEVEL = 12  -- Pixels per indent level (4 spaces = 1 level)
local SPACES_PER_INDENT = 4  -- Number of spaces that equal one indent level

--[[
  Callbacks:
    OnValueChanged(widget, event, value) - fired when header is clicked
]]

local function Control_OnEnter(frame)
  frame.obj.highlight:Show()
  
  -- Show tooltip if desc exists
  if frame.obj.desc then
    GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText(frame.obj.desc, 1, 1, 1, 1, true)
    GameTooltip:Show()
  end
end

local function Control_OnLeave(frame)
  frame.obj.highlight:Hide()
  GameTooltip:Hide()
end

local function Control_OnMouseDown(frame)
  -- Visual feedback on click
  local self = frame.obj
  local indent = self.indent or 0
  self.arrow:ClearAllPoints()
  self.arrow:SetPoint("LEFT", frame, "LEFT", 5 + indent, -1)
end

local function Control_OnMouseUp(frame)
  -- Reset position
  local self = frame.obj
  local indent = self.indent or 0
  self.arrow:ClearAllPoints()
  self.arrow:SetPoint("LEFT", frame, "LEFT", 4 + indent, 0)
end

local function Control_OnClick(frame, button)
  if button == "LeftButton" then
    local self = frame.obj
    local newValue = not self.checked
    self:SetValue(newValue)
    self:Fire("OnValueChanged", newValue)
  end
end

local methods = {
  ["OnAcquire"] = function(self)
    self:SetHeight(24)
    self:SetFullWidth(true)
    self.checked = true -- expanded by default
    self.indent = 0
    self:UpdateArrow()
  end,

  ["OnRelease"] = function(self)
    self.frame:ClearAllPoints()
    self.frame:Hide()
    self.checked = true
    self.desc = nil
    self.indent = 0
  end,

  ["SetValue"] = function(self, value)
    self.checked = value
    self:UpdateArrow()
  end,
  
  ["GetValue"] = function(self)
    return self.checked
  end,

  ["SetLabel"] = function(self, label)
    if not label then
      self.text:SetText("")
      self.indent = 0
      self:UpdateIndent()
      return
    end
    
    -- Count leading spaces to determine indent level
    local leadingSpaces = string_match(label, "^(%s*)")
    local spaceCount = leadingSpaces and #leadingSpaces or 0
    local indentLevel = math.floor(spaceCount / SPACES_PER_INDENT)
    
    -- Store indent in pixels
    self.indent = indentLevel * INDENT_PER_LEVEL
    
    -- Strip leading spaces from display text (arrow provides the indent)
    local displayText = string_gsub(label, "^%s+", "")
    self.text:SetText(displayText)
    
    -- Update positions with new indent
    self:UpdateIndent()
  end,

  ["SetDescription"] = function(self, desc)
    self.desc = desc
  end,

  -- Required by AceConfigDialog for toggle type
  ["SetTriState"] = function(self, enabled)
    -- We don't support tri-state, just ignore
  end,

  -- Required by AceConfigDialog for toggle type  
  ["SetType"] = function(self, type)
    -- We only have one type, ignore
  end,

  -- Required by AceConfigDialog
  ["SetImage"] = function(self, path, ...)
    -- We use our own arrow, ignore external images
  end,

  ["SetDisabled"] = function(self, disabled)
    self.disabled = disabled
    if disabled then
      self.text:SetTextColor(0.5, 0.5, 0.5)
      self.arrow:SetDesaturated(true)
      self.arrow:SetAlpha(0.5)
      self.frame:EnableMouse(false)
    else
      self.text:SetTextColor(1, 0.82, 0) -- Gold color
      self.arrow:SetDesaturated(false)
      self.arrow:SetAlpha(1)
      self.frame:EnableMouse(true)
    end
  end,

  ["UpdateIndent"] = function(self)
    local indent = self.indent or 0
    
    -- Reposition arrow with indent
    self.arrow:ClearAllPoints()
    self.arrow:SetPoint("LEFT", self.frame, "LEFT", 4 + indent, 0)
    
    -- Reposition text relative to arrow (stays the same offset from arrow)
    self.text:ClearAllPoints()
    self.text:SetPoint("LEFT", self.arrow, "RIGHT", 6, 0)
    self.text:SetPoint("RIGHT", self.frame, "RIGHT", -4, 0)
    
    -- Update top line to also be indented for visual consistency
    self.topLine:ClearAllPoints()
    self.topLine:SetPoint("TOPLEFT", indent, 0)
    self.topLine:SetPoint("TOPRIGHT", 0, 0)
  end,

  ["UpdateArrow"] = function(self)
    -- bag-arrow appears to point LEFT by default
    -- checked = true means OPEN (show content), arrow should point DOWN
    -- checked = false means CLOSED (hide content), arrow should point RIGHT
    if self.checked then
      -- Open/Expanded - arrow pointing DOWN toward content below
      self.arrow:SetRotation(math.rad(90))
    else
      -- Closed/Collapsed - arrow pointing RIGHT toward the title
      self.arrow:SetRotation(math.rad(180))
    end
  end,
}

local function Constructor()
  local frame = CreateFrame("Button", nil, UIParent)
  frame:Hide()
  frame:EnableMouse(true)
  frame:SetScript("OnClick", Control_OnClick)
  frame:SetScript("OnEnter", Control_OnEnter)
  frame:SetScript("OnLeave", Control_OnLeave)
  frame:SetScript("OnMouseDown", Control_OnMouseDown)
  frame:SetScript("OnMouseUp", Control_OnMouseUp)

  -- Arrow icon using Atlas
  local arrow = frame:CreateTexture(nil, "ARTWORK")
  arrow:SetAtlas("bag-arrow")
  arrow:SetSize(14, 14)
  arrow:SetPoint("LEFT", frame, "LEFT", 4, 0)

  -- Label text
  local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("LEFT", arrow, "RIGHT", 6, 0)
  text:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
  text:SetTextColor(1, 0.82, 0) -- Gold color
  text:SetJustifyH("LEFT")

  -- Highlight texture (shows on hover)
  local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(1, 1, 1, 0.08)
  highlight:Hide()

  -- Top border line only (no bottom line for cleaner look)
  local topLine = frame:CreateTexture(nil, "ARTWORK")
  topLine:SetHeight(1)
  topLine:SetColorTexture(0.6, 0.6, 0.6, 0.8) -- Brighter gray line
  topLine:SetPoint("TOPLEFT", 0, 0)
  topLine:SetPoint("TOPRIGHT", 0, 0)

  -- Widget object
  local widget = {
    type = Type,
    frame = frame,
    arrow = arrow,
    text = text,
    highlight = highlight,
    topLine = topLine,
    checked = true,
    desc = nil,
    indent = 0,
  }

  for method, func in pairs(methods) do
    widget[method] = func
  end

  frame.obj = widget

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)