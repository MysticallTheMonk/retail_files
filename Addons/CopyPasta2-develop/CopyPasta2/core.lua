local addonName, vars = ...
local L = vars.L
Paste = LibStub("AceAddon-3.0"):NewAddon(addonName)
local addon = Paste 
local AceGUI = LibStub("AceGUI-3.0")
vars.svnrev = vars.svnrev or {}
local svnrev = vars.svnrev
svnrev["core.lua"] = tonumber(("$Revision: 54 $"):match("%d+"))

local defaults = {
  profile = {
    debug = false, -- for addon debugging
    minimap = {
        hide = false,
    },
    stripempty = true,
    trimwhitespace = false,
    windowscale = 1.0,
    editscale = 1.0,
    shiftenter = false,
  }
}

local settings = defaults.profile
local optionsFrame
local charName
local hiddenFrame = CreateFrame("Button", addonName.."HiddenFrame", UIParent)
local revision = tonumber(("$Revision: 54 $"):match("%d+"))
local minimapIcon = LibStub("LibDBIcon-1.0")
local LDB, LDBo
local linelimit = 254

local function chatMsg(msg)
     DEFAULT_CHAT_FRAME:AddMessage(addonName..": "..msg)
end
local function debug(msg)
  if addon.db.profile.debug then
     chatMsg(msg)
  end
end

function addon:myOptions() 
return {
  type = "group",
  set = function(info,val)
          local s = settings ; for i = 2,#info-1 do s = s[info[i]] end
          s[info[#info]] = val; debug(info[#info].." set to: "..tostring(val))
          addon:Update()
        end,
  get = function(info)
          local s = settings ; for i = 2,#info-1 do s = s[info[i]] end
          return s[info[#info]] end,
  args = {
   general = {
    type = "group",
    inline = true,
    name = L["General"],
    args = {
      debug = {
        name = L["Debug"],
        desc = L["Toggle debugging output"],
        type = "toggle",
        guiHidden = true,
      },
      config = {
        name = L["Config"],
        desc = L["Open the configuration GUI"],
        type = "execute",
        guiHidden = true,
        func = function() addon:Config() end,
      },
      show = {
        name = L["Show"],
        desc = L["Show/Hide the Paste window"],
        type = "execute",
        guiHidden = true,
        func = function() addon:ToggleWindow() end,
      },
      minimap = {
        order = 15,
        name = L["Minimap Icon"],
        desc = L["Display minimap icon"],
        type = "toggle",
        set = function(info,val)
          settings.minimap.hide = not val
          addon:Update()
	end,
        get = function() return not settings.minimap.hide end,
      },
      stripempty = {
        order = 17,
        name = L["Strip Empty Lines"],
        desc = L["Strip empty lines (those containing only whitespace) from the output. Note some channels automatically drop fully empty lines."],
        type = "toggle",
      },
      trimwhitespace = {
        order = 18,
        name = L["Trim Whitespace"],
        desc = L["Trim whitespace from the beginning and end of lines in the output."],
        type = "toggle",
      },
      aheader = {
        name = APPEARANCE_LABEL,
        type = "header",
        cmdHidden = true,
        order = 300,
      },
      windowscale = {
        order = 310,
	type = 'range',
	name = L["Window Scale"],
	desc = L["Scale the Paste window and all its contents"],
	min = 0.1,
	max = 5,
	step = 0.1,
	bigStep = 0.1,
	isPercent = true,
      },
      editscale = {
        order = 320,
	type = 'range',
	name = L["Edit font scale"],
	desc = L["Scale the text font used in the Paste edit box"],
	min = 0.1,
	max = 5,
	step = 0.1,
	bigStep = 0.1,
	isPercent = true,
      },
      bheader = {
        name = KEY_BINDINGS,
        type = "header",
        cmdHidden = true,
        order = 900,
      },
      shiftenter = {
        order = 905,
        name = L["Shift-Enter to Paste"],
        desc = L["Shift-Enter hotkey while typing in the edit box will Paste and Close"],
        type = "toggle",
      },
      togglebind = {
        desc = L["Bind a key to toggle the Paste window"],
        type = "keybinding",
        name = L["Show/Hide the Paste window"],
        cmdHidden = true,
        order = 910,
        width = "double",
        set = function(info,val)
           local b1, b2 = GetBindingKey("PASTE")
           if b1 then SetBinding(b1) end
           if b2 then SetBinding(b2) end
           SetBinding(val, "PASTE")
           SaveBindings(GetCurrentBindingSet())
        end,
        get = function(info) return GetBindingKey("PASTE") end,
     },
     },
    },
  }
} 
end

BINDING_NAME_PASTE = L["Show/Hide the Paste window"]
BINDING_HEADER_PASTE = addonName

local function table_clone(t)
  if not t then return nil
  elseif type(t) == "table" then
    local res = {}
    for k,v in pairs(t) do
      res[table_clone(k)] = table_clone(v)
    end
    return res
  else
    return t
  end
end

function addon:RefreshConfig()
  -- things to do after load or settings are reset
  debug("RefreshConfig")
  settings = addon.db.profile
  addon.settings = settings
  charName = UnitName("player")
  for k,v in pairs(defaults.profile) do
     if settings[k] == nil then
       settings[k] = table_clone(v)
     end
  end
  settings.loaded = true
  addon:Update()
end

function addon:Update()
  -- things to do when settings change
  if LDBo then
    minimapIcon:Refresh(addonName)
  end
  addon:UpdateCount()
  if addon.gui then -- scale the window
    local frame = addon.gui.frame
    local old = frame:GetScale()
    local new = settings.windowscale
    if old ~= new then
      local top, left = frame:GetTop(), frame:GetLeft()
      frame:ClearAllPoints()
      frame:SetScale(new)
      left = left * old / new
      top = top * old / new 
      frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end
    local file, oldpt, flags = addon.editfont:GetFont()
    local newpt = addon.editfontnorm * settings.editscale
    if math.abs(oldpt - newpt) > 0.25 then
      addon.editfont:SetFont(file, newpt, flags)
    end
  end
end

function addon:SetupVersion()
   local svnrev = 0
   local files = vars.svnrev
   files["X-Build"] = tonumber((GetAddOnMetadata(addonName, "X-Build") or ""):match("%d+"))
   files["X-Revision"] = tonumber((GetAddOnMetadata(addonName, "X-Revision") or ""):match("%d+"))
   for _,v in pairs(files) do -- determine highest file revision
     if v and v > svnrev then
       svnrev = v
     end
   end
   addon.revision = svnrev

   files["X-Curse-Packaged-Version"] = GetAddOnMetadata(addonName, "X-Curse-Packaged-Version")
   files["Version"] = GetAddOnMetadata(addonName, "Version")
   addon.version = files["X-Curse-Packaged-Version"] or files["Version"] or "@"
   if string.find(addon.version, "@") then -- dev copy uses "@.project-version.@"
      addon.version = "r"..svnrev
   end
end


function addon:OnInitialize()
  addon.db = LibStub("AceDB-3.0"):New("PasteDB", defaults)
  addon:SetupVersion()
  addon:RefreshConfig()
  local options = addon:myOptions()
  LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(options, addonName)
  LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options, {"paste"})
  optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName, nil, "general")
  optionsFrame.default = function()
       for k,v in pairs(defaults.profile) do settings[k] = table_clone(v) end
       addon:RefreshConfig()
       if InterfaceOptionsFrame:IsShown() then
         addon:Config(); addon:Config()
       end
  end
  options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, L["Profiles"], addonName, "profiles")

  debug("OnInitialize")

  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
  self.db.RegisterCallback(self, "OnDatabaseReset", "RefreshConfig")
end

function addon:Config()
  if optionsFrame then
    if ( InterfaceOptionsFrame:IsShown() ) then
      InterfaceOptionsFrame:Hide();
    else
      InterfaceOptionsFrame_OpenToCategory(optionsFrame)
    end
  end
end

function addon:OnEnable()
  debug("OnEnable")
  --self:RegisterEvent("READY_CHECK")
 
  if LDB then
    return
  end
  if AceLibrary and AceLibrary:HasInstance("LibDataBroker-1.1") then
    LDB = AceLibrary("LibDataBroker-1.1")
  elseif LibStub then
    LDB = LibStub:GetLibrary("LibDataBroker-1.1",true)
  end
  if LDB then
    LDBo = LDB:NewDataObject(addonName, {
        type = "launcher",
        label = addonName,
        icon = "Interface\\Icons\\inv_scroll_08",
        OnClick = function(self, button)
                if button == "RightButton" then
                        addon:Config()
                else
                        addon:ToggleWindow()
                end
        end,
        OnTooltipShow = function(tooltip)
                if tooltip and tooltip.AddLine then
                        tooltip:SetText(addonName)
                        tooltip:AddLine("|cffff8040"..L["Left Click"].."|r "..L["to toggle window"])
                        tooltip:AddLine("|cffff8040"..L["Right Click"].."|r "..L["for options"])
                        tooltip:Show()
                end
        end,
     })
  end 

  if LDBo then
    minimapIcon:Register(addonName, LDBo, settings.minimap)
  end
  addon:Update()
end

function addon:ToggleWindow(keystate)
  if keystate == "down" then return end -- ensure keybind doesnt end up in the text box
  debug("ToggleWindow")

  if not addon.gui then
    addon:CreateWindow()
  end
  
  if addon.gui:IsShown() then
    addon.gui:Hide()
  else
    addon.gui:Show()  
    addon.edit:SetFocus()
    addon:Update()
  end
end

function addon:CreateWindow()
  if addon.gui then
    return
  end
  local f = AceGUI:Create("Frame")
  f.frame:SetFrameStrata("MEDIUM")
  f.frame:Raise()
  f.content:SetFrameStrata("MEDIUM")
  f.content:Raise()
  f:Hide()
  addon.gui = f
  f:SetTitle(addonName.."     "..addon.version)
  --addon:fixTitle()
  f:SetCallback("OnClose", OnClose)
  f:SetLayout("Fill")
  f.frame:SetClampedToScreen(true)
  settings.pos = settings.pos or {}
  f:SetStatusTable(settings.pos)
  addon.minwidth = 500
  addon.minheight = 320
  f:SetWidth(addon.minwidth)
  f:SetHeight(addon.minheight)
  f:SetAutoAdjustHeight(true)
  addon:setEscapeHandler(f, function() addon:ToggleWindow() end)

  local c = AceGUI:Create("SimpleGroup")
  c:SetLayout("List")
  c:SetFullWidth(true)
  c:SetFullHeight(true)
  f:AddChild(c)
  
  local edit = AceGUI:Create("MultiLineEditBox")
  c:AddChild(edit)
  edit:SetMaxLetters(0)
  local shortcut = L["Control-V"]
  if IsMacClient() then
    shortcut = L["Command-V"]
  end
  edit:SetLabel(string.format(L["Use %s to paste the clipboard into this box"], shortcut))
  edit:SetNumLines(10)
  edit:SetHeight(170)
  edit:DisableButton(true)
  edit:SetFullWidth(true)
  edit:SetCallback("OnTextChanged", function(widget, t) addon:UpdateCount() end)
  edit:SetText("")
  addon.edit = edit
  addon.editfont = CreateFont("PasteEditFont")
  addon.editfont:CopyFontObject(ChatFontNormal)
  edit.editBox:SetFontObject(addon.editfont)
  addon.editfontnorm = select(2, addon.editfont:GetFont())

  -- AceGUI fails at enforcing minimum Frame resize for a container, so fix it
  hooksecurefunc(f,"OnHeightSet", function(widget, height) 
    if (widget ~= addon.gui) then return end 
    if (height < addon.minheight) then
      f:SetHeight(addon.minheight)
    else
      edit:SetHeight(height - addon.minheight + 170)
    end
  end)
  hooksecurefunc(f,"OnWidthSet", function(widget, width) 
    if (widget ~= addon.gui) then return end 
    if (width < addon.minwidth) then
      f:SetWidth(addon.minwidth)
    end
  end)

  local oldhandler = edit.editBox:GetScript("OnEnterPressed")
  edit.editBox:SetScript("OnEnterPressed", function(self)
    if settings.shiftenter and IsShiftKeyDown() then
      f:Hide()
      addon:PasteText(edit:GetText()) 
    elseif oldhandler then
      oldhandler(self)
    else
      edit.editBox:Insert("\n")
    end
  end)

  local w = AceGUI:Create("SimpleGroup")
  w:SetLayout("Flow")
  w:SetFullWidth(true)
  c:AddChild(w)

  local target = AceGUI:Create("EditBox")
  settings.whispertarget = settings.whispertarget or ""
  target:SetText(settings.whispertarget)
  target:SetMaxLetters(30)
  target:SetWidth(200)
  target:SetCallback("OnTextChanged",function(widget, text)
    settings.whispertarget = target:GetText()
  end)
  target:SetCallback("OnEnterPressed",function(widget)
    target:ClearFocus()
  end)

  local where = AceGUI:Create("Dropdown")
  addon.wherewidget = where
  where:SetMultiselect(false)
  where:SetLabel(L["Paste to:"])
  where:SetWidth(200)
  where:SetCallback("OnEnter",addon.UpdateWhere)
  where:SetCallback("OnValueChanged",function(widget, event, key) 
     settings.where = key 
     if key == CHAT_MSG_WHISPER_INFORM or key == BN_WHISPER then
       target:SetDisabled(false)
       target:SetFocus()
     else
       target:SetDisabled(true)
     end
  end)
  settings.where = settings.where or CHAT_DEFAULT
  addon.UpdateWhere()
  where:SetValue(settings.where)
  target:SetDisabled(settings.where ~= CHAT_MSG_WHISPER_INFORM and settings.where ~= BN_WHISPER)
  w:AddChild(where)  
  w:AddChild(target)

  local b = AceGUI:Create("SimpleGroup")
  b:SetLayout("Flow")
  b:SetFullWidth(true)
  c:AddChild(b)

  local bwidth = 150
  local pcbutton = AceGUI:Create("Button")
  pcbutton:SetText(L["Paste and Close"])
  pcbutton:SetWidth(bwidth)
  pcbutton:SetCallback("OnClick", function(widget, button) 
     f:Hide()
     addon:PasteText(edit:GetText()) 
  end)
  b:AddChild(pcbutton)  
  
  local pbutton = AceGUI:Create("Button")
  pbutton:SetText(L["Paste"])
  pbutton:SetWidth(bwidth)
  pbutton:SetCallback("OnClick", function(widget, button) 
     addon:PasteText(edit:GetText())      
  end)
  b:AddChild(pbutton)  
  
  local clear = AceGUI:Create("Button")
  clear:SetText(L["Clear"])
  clear:SetWidth(bwidth)
  clear:SetCallback("OnClick", function(widget, button) 
     edit:SetText("")
     addon:UpdateCount()
     edit:SetFocus()
  end)
  b:AddChild(clear)  
  
end

addon.wherefn = {
  [CHAT_MSG_SAY] = function(str) SendChatMessage(str, "SAY") end,
  [CHAT_MSG_YELL] = function(str) SendChatMessage(str, "YELL") end,
  [CHAT_MSG_PARTY] = function(str) SendChatMessage(str, "PARTY") end,
  [CHAT_MSG_RAID] = function(str) SendChatMessage(str, "RAID") end,
  [INSTANCE_CHAT] = function(str) SendChatMessage(str, "INSTANCE_CHAT") end,
  [CHAT_MSG_GUILD] = function(str) SendChatMessage(str, "GUILD") end,
  [CHAT_MSG_OFFICER] = function(str) SendChatMessage(str, "OFFICER") end,
  [CHAT_MSG_WHISPER_INFORM] = function(str) 
     local t = settings.whispertarget
     if not t then
       chatMsg(L["You must select a whisper target!"])
       return
     end
     SendChatMessage(str, "WHISPER", nil, t) 
  end,
  [BN_WHISPER] = function(str) 
     local t = settings.whispertarget
     if not t then
       chatMsg(L["You must select a whisper target!"])
       return
     end
     local pID = BNet_GetBNetIDAccount(t)
     if pID then
       BNSendWhisper(pID, str)
       return
     end
     chatMsg(ERR_FRIEND_NOT_FOUND)
  end,
  [CHAT_DEFAULT] = function(str) 
    ChatFrame_OpenChat("")
    local edit = ChatEdit_GetActiveWindow();
    edit:SetText(str)
    ChatEdit_SendText(edit,1)
    ChatEdit_DeactivateChat(edit)
  end,
}

function addon.UpdateWhere() 
  addon.wherelist = addon.wherelist or {}
  wipe(addon.wherelist)
  local w = addon.wherelist
  w[CHAT_DEFAULT] = CHAT_DEFAULT
  w[CHAT_MSG_SAY] = CHAT_MSG_SAY
  w[CHAT_MSG_YELL] = CHAT_MSG_YELL
  w[CHAT_MSG_WHISPER_INFORM] = CHAT_MSG_WHISPER_INFORM
  if BNFeaturesEnabledAndConnected() then
    w[BN_WHISPER] = BN_WHISPER
  end
  if GetNumGroupMembers() > 0 then
    w[CHAT_MSG_PARTY] = CHAT_MSG_PARTY
  end
  if IsInRaid() then
    w[CHAT_MSG_RAID] = CHAT_MSG_RAID
  end
  if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
    w[INSTANCE_CHAT] = INSTANCE_CHAT
  end
  if IsInGuild() then
    w[CHAT_MSG_GUILD] = CHAT_MSG_GUILD
    w[CHAT_MSG_OFFICER] = CHAT_MSG_OFFICER
  end
  local widget = addon.wherewidget
  if widget and not widget.open then
    widget:SetList(addon.wherelist)
    if not addon.wherelist[settings.where] then
      settings.where = CHAT_DEFAULT
      widget:SetValue(settings.where)
    end
  end
end

function addon:UpdateCount()
    if not addon.edit then return end
    local text = addon.edit:GetText()
    if not text then return end
    text = addon:normalizeText(text)
    local lines = 1
    local chars = #text - lines + 1
    for _ in text:gmatch("\n") do lines = lines + 1 end
    addon.gui:SetStatusText(lines.." "..L["lines"]..", "..chars.." "..L["characters"])
end

function addon:normalizeText(text)
  if not text then return nil end
  text = text:gsub("\r\n","\n")
  text = text:gsub("\r","\n")  
  if settings.stripempty then
    text = text:gsub("\n%s*\n","\n")  
    text = text:gsub("^%s*\n","\n")  
    text = text:gsub("\n%s*$","\n")  
  end
  if settings.trimwhitespace then
    text = text:gsub("\n%s*","\n")  
    text = text:gsub("%s*\n","\n")  
    text = text:gsub("^%s*","")  
    text = text:gsub("%s*$","")  
  end
  text = strtrim(text)
  return text
end

function addon:PasteText(text)
  addon.UpdateWhere()
  local where = settings.where
  local sendfn = addon.wherelist[where] and addon.wherefn[where]
  if not sendfn then return end
  text = addon:normalizeText(text)
  if where ~= CHAT_DEFAULT and not addon.slashwarned and
     (text:find("^/%w") or text:find("\n/%w")) then
     StaticPopup_Show("PASTE_SLASHWARN")
     addon.slashwarned = text
     return
  end
  local lines = { strsplit("\n", text) }
  for idx, line in ipairs(lines) do
    while line and #line > 0 do
      local curr = line
      if #curr > linelimit then -- break long lines
        local bpt = linelimit
        for i = linelimit, linelimit-30, -1 do -- look for break characters near the end
	  if string.match(string.sub(curr,i), "^[%p%s]") then
	    bpt = i
	    break
          end
	end
        line = curr:sub(bpt+1)
	curr = curr:sub(1,bpt)
      else
        line = ""
      end
      sendfn(curr)
    end
  end
end

StaticPopupDialogs["PASTE_SLASHWARN"] = {
  preferredIndex = 3, -- reduce the chance of UI taint
  text = L["It looks like you're pasting some slash commands to a chat channel. Would you like to execute them instead?"],
  button1 = YES,
  button2 = NO,
  button3 = CANCEL,
  OnAccept = function() 
	settings.where = CHAT_DEFAULT
        addon.wherewidget:SetValue(CHAT_DEFAULT)
	addon:PasteText(addon.slashwarned)
  end,
  OnCancel = function() addon:PasteText(addon.slashwarned) end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  enterClicksFirstButton = false,
  showAlert = true,
}
----------------------------------------------------------------------------------
-- AceGUI hacks --

-- hack to hook the escape key for closing the window
function addon:setEscapeHandler(widget, fn)
  widget.origOnKeyDown = widget.frame:GetScript("OnKeyDown")
  widget.frame:SetScript("OnKeyDown", function(self,key)
        widget.frame:SetPropagateKeyboardInput(true)
        if key == "ESCAPE" then
           widget.frame:SetPropagateKeyboardInput(false)
           fn()
        elseif widget.origOnKeyDown then
           widget.origOnKeyDown(self,key)
        end
     end)
  widget.frame:EnableKeyboard(true)
  widget.frame:SetPropagateKeyboardInput(true)
end

