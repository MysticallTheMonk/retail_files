-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI Talent Picker Widget
-- A custom AceGUI widget for selecting talents as conditions
-- ═══════════════════════════════════════════════════════════════════════════

local addonName, ns = ...
ns.TalentPicker = ns.TalentPicker or {}

local AceGUI = LibStub("AceGUI-3.0")

-- ═══════════════════════════════════════════════════════════════════════════
-- CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════════

local ICON_SIZE = 32
local ICON_SPACING = 2
local TREE_PADDING = 8
local FRAME_WIDTH = 1000
local FRAME_HEIGHT = 700

-- Tree section widths
local CLASS_TREE_WIDTH = 320
local HERO_TREE_WIDTH = 200
local SPEC_TREE_WIDTH = 320
local TREE_GAP = 20

-- ═══════════════════════════════════════════════════════════════════════════
-- TALENT DATA CACHE
-- ═══════════════════════════════════════════════════════════════════════════

local talentCache = {}
local nodePositions = {}

-- Get all talent nodes for current spec
local function GetTalentTreeData()
  local configID = C_ClassTalents.GetActiveConfigID()
  if not configID then return nil end
  
  local configInfo = C_Traits.GetConfigInfo(configID)
  if not configInfo or not configInfo.treeIDs or #configInfo.treeIDs == 0 then return nil end
  
  local treeID = configInfo.treeIDs[1]
  local nodes = C_Traits.GetTreeNodes(treeID)
  
  local talentData = {
    configID = configID,
    treeID = treeID,
    nodes = {},
    classNodes = {},
    specNodes = {},
    heroNodes = {},
  }
  
  -- Track bounds for each tree section
  local classBounds = { minX = 99999, maxX = -99999, minY = 99999, maxY = -99999 }
  local specBounds = { minX = 99999, maxX = -99999, minY = 99999, maxY = -99999 }
  local heroBounds = { minX = 99999, maxX = -99999, minY = 99999, maxY = -99999 }
  
  for _, nodeID in ipairs(nodes) do
    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
    if nodeInfo and nodeInfo.ID and nodeInfo.ID ~= 0 then
      local node = {
        nodeID = nodeID,
        posX = nodeInfo.posX or 0,
        posY = nodeInfo.posY or 0,
        type = nodeInfo.type,
        maxRanks = nodeInfo.maxRanks or 1,
        currentRank = nodeInfo.currentRank or 0,
        activeRank = nodeInfo.activeRank or 0,
        isAvailable = nodeInfo.isAvailable,
        isVisible = nodeInfo.isVisible ~= false,
        isTalented = (nodeInfo.activeRank or 0) > 0,
        entryIDs = nodeInfo.entryIDs or {},
        activeEntry = nodeInfo.activeEntry,
        subTreeID = nodeInfo.subTreeID,
        subTreeActive = nodeInfo.subTreeActive,
      }
      
      -- Get spell info for the node
      if node.activeEntry and node.activeEntry.entryID then
        local entryInfo = C_Traits.GetEntryInfo(configID, node.activeEntry.entryID)
        if entryInfo and entryInfo.definitionID then
          local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
          if defInfo then
            node.spellID = defInfo.spellID
            node.name = defInfo.overrideName or (defInfo.spellID and C_Spell.GetSpellName(defInfo.spellID)) or "Unknown"
            node.icon = defInfo.overrideIcon or (defInfo.spellID and C_Spell.GetSpellTexture(defInfo.spellID)) or 134400
          end
        end
      elseif #node.entryIDs > 0 then
        local entryInfo = C_Traits.GetEntryInfo(configID, node.entryIDs[1])
        if entryInfo and entryInfo.definitionID then
          local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
          if defInfo then
            node.spellID = defInfo.spellID
            node.name = defInfo.overrideName or (defInfo.spellID and C_Spell.GetSpellName(defInfo.spellID)) or "Unknown"
            node.icon = defInfo.overrideIcon or (defInfo.spellID and C_Spell.GetSpellTexture(defInfo.spellID)) or 134400
          end
        end
      end
      
      -- Categorize node by tree type
      if node.subTreeID then
        -- Hero talent
        table.insert(talentData.heroNodes, node)
        heroBounds.minX = math.min(heroBounds.minX, node.posX)
        heroBounds.maxX = math.max(heroBounds.maxX, node.posX)
        heroBounds.minY = math.min(heroBounds.minY, node.posY)
        heroBounds.maxY = math.max(heroBounds.maxY, node.posY)
      elseif node.posX < 10000 then
        -- Class talent (lower X values)
        table.insert(talentData.classNodes, node)
        classBounds.minX = math.min(classBounds.minX, node.posX)
        classBounds.maxX = math.max(classBounds.maxX, node.posX)
        classBounds.minY = math.min(classBounds.minY, node.posY)
        classBounds.maxY = math.max(classBounds.maxY, node.posY)
      else
        -- Spec talent (higher X values)
        table.insert(talentData.specNodes, node)
        specBounds.minX = math.min(specBounds.minX, node.posX)
        specBounds.maxX = math.max(specBounds.maxX, node.posX)
        specBounds.minY = math.min(specBounds.minY, node.posY)
        specBounds.maxY = math.max(specBounds.maxY, node.posY)
      end
      
      talentData.nodes[nodeID] = node
    end
  end
  
  talentData.classBounds = classBounds
  talentData.specBounds = specBounds
  talentData.heroBounds = heroBounds
  
  return talentData
end

-- Check if a specific talent node is currently selected
local function IsTalentNodeSelected(nodeID)
  local configID = C_ClassTalents.GetActiveConfigID()
  if not configID then return false end
  
  local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
  if not nodeInfo then return false end
  
  return (nodeInfo.activeRank or 0) > 0
end

-- Get talent node info by nodeID
local function GetTalentNodeInfo(nodeID)
  local configID = C_ClassTalents.GetActiveConfigID()
  if not configID then return nil end
  
  local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
  if not nodeInfo or nodeInfo.ID == 0 then return nil end
  
  local info = {
    nodeID = nodeID,
    currentRank = nodeInfo.activeRank or 0,
    maxRanks = nodeInfo.maxRanks or 1,
    isSelected = (nodeInfo.activeRank or 0) > 0,
  }
  
  local entryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID
  if not entryID and nodeInfo.entryIDs and #nodeInfo.entryIDs > 0 then
    entryID = nodeInfo.entryIDs[1]
  end
  
  if entryID then
    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
    if entryInfo and entryInfo.definitionID then
      local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
      if defInfo then
        info.spellID = defInfo.spellID
        info.name = defInfo.overrideName or (defInfo.spellID and C_Spell.GetSpellName(defInfo.spellID)) or "Unknown"
        info.icon = defInfo.overrideIcon or (defInfo.spellID and C_Spell.GetSpellTexture(defInfo.spellID)) or 134400
      end
    end
  end
  
  return info
end

-- Expose functions to namespace
ns.TalentPicker.GetTalentTreeData = GetTalentTreeData
ns.TalentPicker.IsTalentNodeSelected = IsTalentNodeSelected
ns.TalentPicker.GetTalentNodeInfo = GetTalentNodeInfo

-- ═══════════════════════════════════════════════════════════════════════════
-- CHECK TALENT CONDITIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Helper to output debug to CDMGroups buffer if available
local function TalentDebugPrint(...)
  -- Only print if debug is explicitly enabled
  if not (ns.CDMGroups and ns.CDMGroups.debugEnabled) then return end
  
  local args = {...}
  local parts = {}
  for i, v in ipairs(args) do
    parts[i] = tostring(v)
  end
  local msg = table.concat(parts, " ")
  
  print(msg)
  if ns.CDMGroups.debugBuffer then
    table.insert(ns.CDMGroups.debugBuffer, msg)
    if #ns.CDMGroups.debugBuffer > 200 then
      table.remove(ns.CDMGroups.debugBuffer, 1)
    end
  end
end

function ns.TalentPicker.CheckTalentConditions(talentConditions, matchMode)
  if not talentConditions or #talentConditions == 0 then
    return true
  end
  
  matchMode = matchMode or "all"
  
  local configID = C_ClassTalents.GetActiveConfigID()
  if not configID then return false end
  
  TalentDebugPrint("|cff88ff88[TalentCheck]|r Checking " .. #talentConditions .. " conditions, mode: " .. matchMode)
  
  for _, condition in ipairs(talentConditions) do
    local nodeID, required
    if type(condition) == "number" then
      nodeID = condition
      required = true
    else
      nodeID = condition.nodeID
      required = condition.required ~= false
    end
    
    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
    
    -- For hero talents (subTreeID exists), must also check subTreeActive
    -- Nodes in inactive hero trees have activeRank > 0 but subTreeActive = false
    local isSelected = false
    if nodeInfo then
      local hasRank = (nodeInfo.activeRank or 0) > 0
      
      if nodeInfo.subTreeID then
        -- Hero talent - must have rank AND subtree must be active
        isSelected = hasRank and (nodeInfo.subTreeActive == true)
        TalentDebugPrint("|cff88ff88[TalentCheck]|r   Node " .. nodeID .. " isHero=true, hasRank: " .. tostring(hasRank) .. " subTreeActive: " .. tostring(nodeInfo.subTreeActive) .. " -> isSelected: " .. tostring(isSelected))
      else
        -- Class/spec talent - just check rank
        isSelected = hasRank
        TalentDebugPrint("|cff88ff88[TalentCheck]|r   Node " .. nodeID .. " isHero=false, hasRank: " .. tostring(hasRank) .. " -> isSelected: " .. tostring(isSelected))
      end
    else
      TalentDebugPrint("|cff88ff88[TalentCheck]|r   Node " .. nodeID .. " - NO NODE INFO")
    end
    
    if required then
      if matchMode == "all" and not isSelected then
        TalentDebugPrint("|cff88ff88[TalentCheck]|r   -> FAIL: required node not selected (all mode)")
        return false
      elseif matchMode == "any" and isSelected then
        TalentDebugPrint("|cff88ff88[TalentCheck]|r   -> PASS: required node selected (any mode)")
        return true
      end
    else
      if matchMode == "all" and isSelected then
        TalentDebugPrint("|cff88ff88[TalentCheck]|r   -> FAIL: excluded node is selected (all mode)")
        return false
      elseif matchMode == "any" and not isSelected then
        TalentDebugPrint("|cff88ff88[TalentCheck]|r   -> PASS: excluded node not selected (any mode)")
        return true
      end
    end
  end
  
  local result = matchMode == "all"
  TalentDebugPrint("|cff88ff88[TalentCheck]|r   -> Final result: " .. tostring(result))
  
  if matchMode == "all" then
    return true
  else
    return false
  end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TALENT PICKER POPUP FRAME
-- ═══════════════════════════════════════════════════════════════════════════

local TalentPickerFrame = nil
local selectedTalents = {}
local onSelectCallback = nil

local function CreateTalentNodeButton(parent, node)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(ICON_SIZE, ICON_SIZE)
  
  -- Background (dark square)
  button.bg = button:CreateTexture(nil, "BACKGROUND")
  button.bg:SetAllPoints()
  button.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
  
  -- Icon texture (slightly inset)
  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetPoint("TOPLEFT", 2, -2)
  button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
  button.icon:SetTexture(node.icon or 134400)
  button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  
  -- Border texture (default gray)
  button.border = button:CreateTexture(nil, "OVERLAY")
  button.border:SetPoint("TOPLEFT", -1, 1)
  button.border:SetPoint("BOTTOMRIGHT", 1, -1)
  button.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  button.border:SetTexCoord(0.15, 0.85, 0.15, 0.85)
  button.border:SetVertexColor(0.4, 0.4, 0.4, 1) -- Gray by default
  
  -- Green border for required (bigger)
  button.greenBorder = button:CreateTexture(nil, "OVERLAY", nil, 1)
  button.greenBorder:SetPoint("TOPLEFT", -6, 6)
  button.greenBorder:SetPoint("BOTTOMRIGHT", 6, -6)
  button.greenBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  button.greenBorder:SetBlendMode("ADD")
  button.greenBorder:SetVertexColor(0, 1, 0, 1)
  button.greenBorder:Hide()
  
  -- Red border for excluded (bigger)
  button.redBorder = button:CreateTexture(nil, "OVERLAY", nil, 1)
  button.redBorder:SetPoint("TOPLEFT", -6, 6)
  button.redBorder:SetPoint("BOTTOMRIGHT", 6, -6)
  button.redBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  button.redBorder:SetBlendMode("ADD")
  button.redBorder:SetVertexColor(1, 0, 0, 1)
  button.redBorder:Hide()
  
  -- Checkmark for required
  button.checkmark = button:CreateTexture(nil, "OVERLAY", nil, 3)
  button.checkmark:SetSize(14, 14)
  button.checkmark:SetPoint("BOTTOMRIGHT", 4, -4)
  button.checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
  button.checkmark:Hide()
  
  -- X mark for excluded
  button.xmark = button:CreateTexture(nil, "OVERLAY", nil, 3)
  button.xmark:SetSize(14, 14)
  button.xmark:SetPoint("BOTTOMRIGHT", 4, -4)
  button.xmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
  button.xmark:Hide()
  
  -- Start desaturated/gray - will colorize when selected as condition
  button.icon:SetDesaturated(true)
  button.icon:SetAlpha(0.6)
  
  -- Store whether this talent is actually talented (for tooltip)
  button.node = node
  button.nodeID = node.nodeID
  
  button.UpdateSelection = function(self)
    local selection = selectedTalents[self.nodeID]
    self.greenBorder:Hide()
    self.redBorder:Hide()
    self.checkmark:Hide()
    self.xmark:Hide()
    
    if selection == true then
      -- Required - show green, colorize icon
      self.greenBorder:Show()
      self.checkmark:Show()
      self.icon:SetDesaturated(false)
      self.icon:SetAlpha(1)
      self.border:SetVertexColor(0, 0.8, 0, 1)
    elseif selection == false then
      -- Excluded - show red, colorize icon
      self.redBorder:Show()
      self.xmark:Show()
      self.icon:SetDesaturated(false)
      self.icon:SetAlpha(1)
      self.border:SetVertexColor(0.8, 0, 0, 1)
    else
      -- Not part of condition - gray
      self.icon:SetDesaturated(true)
      self.icon:SetAlpha(0.6)
      self.border:SetVertexColor(0.4, 0.4, 0.4, 1)
    end
  end
  
  button:SetScript("OnClick", function(self, mouseButton)
    local current = selectedTalents[self.nodeID]
    if mouseButton == "RightButton" then
      selectedTalents[self.nodeID] = nil
    elseif current == nil then
      selectedTalents[self.nodeID] = true
    elseif current == true then
      selectedTalents[self.nodeID] = false
    else
      selectedTalents[self.nodeID] = nil
    end
    self:UpdateSelection()
    
    if TalentPickerFrame and TalentPickerFrame.UpdateSummary then
      TalentPickerFrame:UpdateSummary()
    end
  end)
  
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    -- Show spell tooltip if we have a spellID
    if self.node.spellID then
      GameTooltip:SetSpellByID(self.node.spellID)
      
      -- Add our custom info after the spell tooltip
      GameTooltip:AddLine(" ")
      
      local selection = selectedTalents[self.nodeID]
      if selection == true then
        GameTooltip:AddLine("Condition: REQUIRED", 0, 1, 0)
      elseif selection == false then
        GameTooltip:AddLine("Condition: EXCLUDED", 1, 0, 0)
      else
        GameTooltip:AddLine("Condition: None", 0.5, 0.5, 0.5)
      end
      
      if self.node.isTalented then
        GameTooltip:AddLine("Currently Talented", 0, 1, 0)
      else
        GameTooltip:AddLine("Not Talented", 0.5, 0.5, 0.5)
      end
      
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Left-Click: Cycle condition", 1, 0.82, 0)
      GameTooltip:AddLine("Right-Click: Clear", 1, 0.82, 0)
    else
      -- Fallback if no spellID
      local name = self.node.name or "Unknown Talent"
      local selection = selectedTalents[self.nodeID]
      local status = ""
      
      if selection == true then
        status = " |cff00ff00(REQUIRED)|r"
      elseif selection == false then
        status = " |cffff0000(EXCLUDED)|r"
      end
      
      GameTooltip:AddLine(name .. status, 1, 1, 1)
      
      if self.node.isTalented then
        GameTooltip:AddLine("Currently Talented", 0, 1, 0)
      else
        GameTooltip:AddLine("Not Talented", 0.5, 0.5, 0.5)
      end
      
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Left-Click: Cycle condition", 1, 0.82, 0)
      GameTooltip:AddLine("Right-Click: Clear", 1, 0.82, 0)
    end
    
    GameTooltip:Show()
  end)
  
  button:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  
  return button
end

local function CreateTreeSection(parent, title, width, height)
  local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  section:SetSize(width, height)
  section:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  section:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
  
  -- Title
  section.title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  section.title:SetPoint("TOP", 0, -5)
  section.title:SetText(title)
  section.title:SetTextColor(1, 0.82, 0)
  
  -- Content area
  section.content = CreateFrame("Frame", nil, section)
  section.content:SetPoint("TOPLEFT", 5, -20)
  section.content:SetPoint("BOTTOMRIGHT", -5, 5)
  
  return section
end

local function CreateTalentPickerFrame()
  if TalentPickerFrame then
    return TalentPickerFrame
  end
  
  local frame = CreateFrame("Frame", "ArcUITalentPickerFrame", UIParent, "BackdropTemplate")
  frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("TOOLTIP")  -- Highest strata to appear above options panel
  frame:SetFrameLevel(100)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetClampedToScreen(true)
  
  -- Ensure frame is raised when shown
  frame:SetScript("OnShow", function(self)
    self:Raise()
  end)
  
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  
  -- Title
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.title:SetPoint("TOP", 0, -20)
  frame.title:SetText("|cff00ccffArcUI|r - Talent Conditions")
  
  -- Close button
  frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  frame.closeBtn:SetPoint("TOPRIGHT", -5, -5)
  frame.closeBtn:SetScript("OnClick", function() frame:Hide() end)
  
  -- Instructions
  frame.instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.instructions:SetPoint("TOP", 0, -42)
  frame.instructions:SetText("|cffffd700Click talents to set conditions. |cff00ff00Green = Required|r, |cffff0000Red = Excluded|r")
  
  -- Tree sections container
  frame.treesContainer = CreateFrame("Frame", nil, frame)
  frame.treesContainer:SetPoint("TOPLEFT", 20, -65)
  frame.treesContainer:SetPoint("BOTTOMRIGHT", -20, 100)
  
  -- Create tree sections
  local treeHeight = FRAME_HEIGHT - 180
  frame.classSection = CreateTreeSection(frame.treesContainer, "CLASS", CLASS_TREE_WIDTH, treeHeight)
  frame.classSection:SetPoint("TOPLEFT", 0, 0)
  
  frame.heroSection = CreateTreeSection(frame.treesContainer, "HERO", HERO_TREE_WIDTH, treeHeight)
  frame.heroSection:SetPoint("LEFT", frame.classSection, "RIGHT", TREE_GAP, 0)
  
  frame.specSection = CreateTreeSection(frame.treesContainer, "SPEC", SPEC_TREE_WIDTH, treeHeight)
  frame.specSection:SetPoint("LEFT", frame.heroSection, "RIGHT", TREE_GAP, 0)
  
  -- Summary text
  frame.summary = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.summary:SetPoint("BOTTOMLEFT", 25, 70)
  frame.summary:SetWidth(600)
  frame.summary:SetJustifyH("LEFT")
  frame.summary:SetText("|cff888888No conditions set - bar will always show|r")
  
  -- Match mode
  frame.matchModeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.matchModeLabel:SetPoint("BOTTOMLEFT", 25, 42)
  frame.matchModeLabel:SetText("|cffffd700Match Mode:|r")
  
  frame.matchModeAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.matchModeAll:SetSize(70, 22)
  frame.matchModeAll:SetPoint("LEFT", frame.matchModeLabel, "RIGHT", 10, 0)
  frame.matchModeAll:SetText("ALL")
  frame.matchModeAll:SetScript("OnClick", function()
    frame.matchMode = "all"
    frame.matchModeAll:SetButtonState("PUSHED", true)
    frame.matchModeAny:SetButtonState("NORMAL")
  end)
  
  frame.matchModeAny = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.matchModeAny:SetSize(70, 22)
  frame.matchModeAny:SetPoint("LEFT", frame.matchModeAll, "RIGHT", 5, 0)
  frame.matchModeAny:SetText("ANY")
  frame.matchModeAny:SetScript("OnClick", function()
    frame.matchMode = "any"
    frame.matchModeAny:SetButtonState("PUSHED", true)
    frame.matchModeAll:SetButtonState("NORMAL")
  end)
  
  frame.matchMode = "all"
  
  -- Clear button
  frame.clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.clearBtn:SetSize(90, 25)
  frame.clearBtn:SetPoint("BOTTOMRIGHT", -130, 35)
  frame.clearBtn:SetText("Clear All")
  frame.clearBtn:SetScript("OnClick", function()
    wipe(selectedTalents)
    frame:RefreshNodes()
    frame:UpdateSummary()
  end)
  
  -- Save button
  frame.saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.saveBtn:SetSize(90, 25)
  frame.saveBtn:SetPoint("BOTTOMRIGHT", -25, 35)
  frame.saveBtn:SetText("Save")
  frame.saveBtn:SetScript("OnClick", function()
    if onSelectCallback then
      local conditions = {}
      for nodeID, required in pairs(selectedTalents) do
        table.insert(conditions, { nodeID = nodeID, required = required })
      end
      onSelectCallback(conditions, frame.matchMode)
    end
    frame:Hide()
  end)
  
  frame.nodeButtons = {}
  
  frame.UpdateSummary = function(self)
    local required = {}
    local excluded = {}
    
    for nodeID, state in pairs(selectedTalents) do
      local info = GetTalentNodeInfo(nodeID)
      local name = info and info.name or ("Node " .. nodeID)
      if state == true then
        table.insert(required, name)
      elseif state == false then
        table.insert(excluded, name)
      end
    end
    
    local text = ""
    if #required > 0 then
      text = "|cff00ff00Required:|r " .. table.concat(required, ", ")
    end
    if #excluded > 0 then
      if text ~= "" then text = text .. "  " end
      text = text .. "|cffff0000Excluded:|r " .. table.concat(excluded, ", ")
    end
    if text == "" then
      text = "|cff888888No conditions set - bar will always show|r"
    end
    
    self.summary:SetText(text)
  end
  
  frame.RefreshNodes = function(self)
    for _, button in pairs(self.nodeButtons) do
      button:UpdateSelection()
    end
  end
  
  frame.PopulateTalents = function(self)
    -- Clear existing buttons
    for _, button in pairs(self.nodeButtons) do
      button:Hide()
      button:SetParent(nil)
    end
    wipe(self.nodeButtons)
    
    local talentData = GetTalentTreeData()
    if not talentData then
      return
    end
    
    -- Helper to position nodes in a section
    local function PositionNodesInSection(nodes, bounds, container, containerWidth, containerHeight, alignTop, isHeroSection)
      if #nodes == 0 then return end
      
      local xRange = bounds.maxX - bounds.minX
      local yRange = bounds.maxY - bounds.minY
      if xRange == 0 then xRange = 1 end
      if yRange == 0 then yRange = 1 end
      
      local usableWidth = containerWidth - ICON_SIZE - (TREE_PADDING * 2)
      local usableHeight = containerHeight - ICON_SIZE - (TREE_PADDING * 2)
      
      -- Reduce top padding for better alignment
      local topPad = 5
      
      -- For hero section, stack trees vertically (one on top of the other)
      if isHeroSection then
        -- Group nodes by subTreeID
        local trees = {}
        local treeOrder = {}
        for _, node in ipairs(nodes) do
          if node.isVisible and node.icon then
            local stID = node.subTreeID or 0
            if not trees[stID] then
              trees[stID] = {}
              table.insert(treeOrder, stID)
            end
            table.insert(trees[stID], node)
          end
        end
        table.sort(treeOrder)
        
        -- Stack trees vertically
        local numTrees = #treeOrder
        local treeGap = 20  -- Gap between the two trees
        local treeHeight = (usableHeight - treeGap) / math.max(numTrees, 1)
        
        for treeIdx, stID in ipairs(treeOrder) do
          local treeNodes = trees[stID]
          
          -- Find X and Y bounds for THIS tree only
          local minX, maxX, minY, maxY = 99999, -99999, 99999, -99999
          for _, node in ipairs(treeNodes) do
            minX = math.min(minX, node.posX)
            maxX = math.max(maxX, node.posX)
            minY = math.min(minY, node.posY)
            maxY = math.max(maxY, node.posY)
          end
          
          local treeXRange = maxX - minX
          local treeYRange = maxY - minY
          if treeXRange == 0 then treeXRange = 1 end
          if treeYRange == 0 then treeYRange = 1 end
          
          -- Calculate Y offset for this tree section
          local treeStartY = topPad + ((treeIdx - 1) * (treeHeight + treeGap))
          local treeUsableHeight = treeHeight - ICON_SIZE
          
          for _, node in ipairs(treeNodes) do
            -- Normalize X and Y within this tree's range
            local normX = (node.posX - minX) / treeXRange
            local normY = (node.posY - minY) / treeYRange
            
            local x = TREE_PADDING + (normX * usableWidth)
            local y = -treeStartY - (normY * treeUsableHeight)
            
            local button = CreateTalentNodeButton(container, node)
            button:SetPoint("TOPLEFT", x, y)
            button:UpdateSelection()
            
            table.insert(self.nodeButtons, button)
          end
        end
        return
      end
      
      -- Standard positioning for class/spec trees
      for _, node in ipairs(nodes) do
        if node.isVisible and node.icon then
          local normX = (node.posX - bounds.minX) / xRange
          local normY = (node.posY - bounds.minY) / yRange
          
          local x = TREE_PADDING + (normX * usableWidth)
          local y = -topPad - (normY * usableHeight)
          
          local button = CreateTalentNodeButton(container, node)
          button:SetPoint("TOPLEFT", x, y)
          button:UpdateSelection()
          
          table.insert(self.nodeButtons, button)
        end
      end
    end
    
    -- Get container dimensions
    local classW = self.classSection.content:GetWidth() or (CLASS_TREE_WIDTH - 10)
    local classH = self.classSection.content:GetHeight() or (FRAME_HEIGHT - 200)
    local heroW = self.heroSection.content:GetWidth() or (HERO_TREE_WIDTH - 10)
    local heroH = self.heroSection.content:GetHeight() or (FRAME_HEIGHT - 200)
    local specW = self.specSection.content:GetWidth() or (SPEC_TREE_WIDTH - 10)
    local specH = self.specSection.content:GetHeight() or (FRAME_HEIGHT - 200)
    
    -- Position nodes in each section
    PositionNodesInSection(talentData.classNodes, talentData.classBounds, self.classSection.content, classW, classH, true, false)
    PositionNodesInSection(talentData.heroNodes, talentData.heroBounds, self.heroSection.content, heroW, heroH, false, true)
    PositionNodesInSection(talentData.specNodes, talentData.specBounds, self.specSection.content, specW, specH, true, false)
    
    -- Update section titles
    local _, className = UnitClass("player")
    local specID = GetSpecialization()
    local _, specName = GetSpecializationInfo(specID)
    
    self.classSection.title:SetText(className or "CLASS")
    self.specSection.title:SetText(specName or "SPEC")
  end
  
  frame:Hide()
  TalentPickerFrame = frame
  return frame
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════════════════

function ns.TalentPicker.OpenPicker(existingConditions, matchMode, callback)
  local frame = CreateTalentPickerFrame()
  
  wipe(selectedTalents)
  
  if existingConditions then
    for _, cond in ipairs(existingConditions) do
      if cond.nodeID then
        selectedTalents[cond.nodeID] = cond.required
      end
    end
  end
  
  frame.matchMode = matchMode or "all"
  if frame.matchMode == "all" then
    frame.matchModeAll:SetButtonState("PUSHED", true)
    frame.matchModeAny:SetButtonState("NORMAL")
  else
    frame.matchModeAny:SetButtonState("PUSHED", true)
    frame.matchModeAll:SetButtonState("NORMAL")
  end
  
  onSelectCallback = callback
  
  frame:PopulateTalents()
  frame:UpdateSummary()
  frame:Show()
end

function ns.TalentPicker.ClosePicker()
  if TalentPickerFrame then
    TalentPickerFrame:Hide()
  end
end

function ns.TalentPicker.GetConditionSummary(conditions, matchMode)
  if not conditions or #conditions == 0 then
    return "|cff888888No talent conditions|r"
  end
  
  local required = {}
  local excluded = {}
  
  for _, cond in ipairs(conditions) do
    local info = GetTalentNodeInfo(cond.nodeID)
    local name = info and info.name or ("Node " .. cond.nodeID)
    if cond.required ~= false then
      table.insert(required, name)
    else
      table.insert(excluded, name)
    end
  end
  
  local parts = {}
  if #required > 0 then
    table.insert(parts, "|cff00ff00Req:|r " .. table.concat(required, ", "))
  end
  if #excluded > 0 then
    table.insert(parts, "|cffff0000Not:|r " .. table.concat(excluded, ", "))
  end
  
  local modeText = matchMode == "any" and " |cffffd700(ANY)|r" or ""
  return table.concat(parts, " ") .. modeText
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
  wipe(talentCache)
  wipe(nodePositions)
  
  -- Refresh talent picker if open
  if TalentPickerFrame and TalentPickerFrame:IsShown() then
    TalentPickerFrame:PopulateTalents()
    TalentPickerFrame:RefreshNodes()
  end
  
  -- On talent change, refresh bar visibility and tracking
  -- NOTE: Core.lua already handles PLAYER_SPECIALIZATION_CHANGED with ValidateAllBarTracking
  -- We only need to refresh the options panel if open, don't touch display bars!
  C_Timer.After(0.2, function()
    -- Refresh options panel if open (to update talent-dependent UI elements)
    local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if AceConfigRegistry then
      AceConfigRegistry:NotifyChange("ArcUI")
    end
  end)
end)