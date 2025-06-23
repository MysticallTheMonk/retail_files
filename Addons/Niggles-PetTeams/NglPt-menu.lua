-------------------------------------------------------------------------------
--                L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

local MENU_FLAG_LABEL   = 0x01;
local MENU_FLAG_CHECK   = 0x02;
local MENU_FLAG_EXPAND  = 0x04;
local MENU_FLAG_DIVIDER = 0x08;
local MENU_FLAG_ENABLED = 0x10;
local MENU_FLAG_NORMAL  = 0x20;

local MENU_CHECK_WIDTH  = 16;
local MENU_EXPAND_WIDTH = 16;
local MENU_MAX_WIDTH    = 256;

-------------------------------------------------------------------------------
--                L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--               G  L  O  B  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--               G  L  O  B  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                 G  L  O  B  A  L     C  L  A  S  S  E  S
-------------------------------------------------------------------------------

--
-- Class to provide a menu
--
NigglesPetTeamsMenuClass =
{
  -- Class Variables
  backdropStyles =
  {
    menu =
    {
      bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
      bgColor  = {r = 0.09, g = 0.09, b = 0.19, a = 1.0},
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile     = true,
      tileSize = 16,
      edgeSize = 16,
      insets   = {left =  4, right =  4, top =  4, bottom =  4},
      padding  = {left = 10, right =  6, top = 10, bottom = 10},
    },
    dialog =
    {
      bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile     = true,
      tileSize = 32,
      edgeSize = 32,
      insets   = {left = 11, right = 11, top = 11, bottom =  9},
      padding  = {left = 16, right = 16, top = 15, bottom = 14},
    }
  };
  buttonTypes =
  {
    button      = MENU_FLAG_LABEL+MENU_FLAG_ENABLED,
    checkbutton = MENU_FLAG_LABEL+MENU_FLAG_CHECK+MENU_FLAG_ENABLED,
    divider     = MENU_FLAG_DIVIDER,
    label       = MENU_FLAG_LABEL+MENU_FLAG_NORMAL,
    radiobutton = MENU_FLAG_LABEL+MENU_FLAG_CHECK+MENU_FLAG_ENABLED,
    submenu     = MENU_FLAG_LABEL+MENU_FLAG_EXPAND+MENU_FLAG_ENABLED,
  };
  buttonComponents =
  {
    text    = MENU_FLAG_LABEL,
    check   = MENU_FLAG_CHECK,
    expand  = MENU_FLAG_EXPAND,
    divider = MENU_FLAG_DIVIDER,
  };
  classObjs = 0;

  --
  -- Method to set check state of a menu button
  --
  ButtonSetCheck = function(button, isChecked)
    -- Local Variables
    local group;

    -- Save the button's new check state
    button.isChecked = isChecked;

    -- Process the state change, if required
    if (button.type == "checkbutton") then
      -- Update the texture of the button's check
      button.check:SetTexCoord((isChecked and 0.0 or 0.5),
        (isChecked and 0.5 or 1.0), 0.0, 0.5);
    elseif (button.type == "radiobutton") then
      -- Update the texture of the button's check
      button.check:SetTexCoord((isChecked and 0.0 or 0.5),
        (isChecked and 0.5 or 1.0), 0.5, 1.0);

      -- If the button is checked...
      if (isChecked) then
        -- ...uncheck any other radio buttons in the same group
        group = button.group;
        for _, current in ipairs(button.object.buttons) do
          if ((current ~= button) and
              (current.type == "radiobutton") and
              (current.group == group) and
              (current.isChecked) and
              (current:IsShown())) then
            current.check:SetTexCoord(0.5, 1.0, 0.5, 1.0);
            current.isChecked = false;
          end
        end
      end
    end

    return;
  end;

  --
  -- Method to get various info about the menu
  --
  GetAnchor = function(self) return self.anchor; end;
  GetData   = function(self) return self.data; end;
  GetItems  = function(self) return self.items; end;
  GetLevel  = function(self) return self.level; end;
  GetParent = function(self) return self.parent; end;

  --
  -- Method to hide a menu and all its descendants and/or ancestors
  --
  Hide = function(self, hideAll)
    -- Local Variables
    local menu;
    local level = (hideAll and 1 or self.level);

    -- Find the lowest level menu
    menu = self;
    while (menu.child ~= nil) do
      menu = menu.child;
    end

    -- Hide the menus, in highest to lowest order
    while ((menu ~= nil) and (menu.level >= level)) do
      menu.frame:Hide();
      menu = menu.parent;
    end

    return;
  end;

  --
  -- Function to start the hide timer
  --
  HideTimerStart = function(self)
    -- Set the delay before the menu should be hidden
    self.hideTimer = UIDROPDOWNMENU_SHOW_TIME;
    return;
  end;

  --
  -- Function to stop the hide timer
  --
  HideTimerStop = function(self)
    self.hideTimer = -1;
    return;
  end;

  --
  -- Function to check if a menu is shown, or shown for a specific frame if
  -- one is specified
  --
  IsShown = function(self, frame)
    -- Local Variables
    local isShown = self.frame:IsShown();

    -- Check if the menu is shown for the specified frame, if required
    if ((isShown) and (frame ~= nil)) then
      isShown = (self.anchor == frame);
    end

    return isShown;
  end;

  --
  -- Method to create a new class object
  --
  New = function(self, parent)
    -- Create a new table for the object
    local edges;
    local frame;
    local object =
    {
      parent  = parent,
      child   = nil,
      buttons = {},
    };
    local witness;

    -- Set the object's metatable to use the default class values
    setmetatable(object, self);
    self.__index = self;

    -- Increment the number of class objects
    self.classObjs = self.classObjs+1;

    -- Work out the object's level and progenitor
    if (parent ~= nil)  then
      object.level      = parent.level+1;
      object.progenitor = parent.progenitor;
      object.args       = object.progenitor.args;
    else
      object.level      = 1;
      object.progenitor = object;
      object.args       = {};
    end

    -- Create the frame for the menu
    frame = CreateFrame("Frame", "NigglesPetTeamsMenu"..self.classObjs,
    nil, nil);
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetClampedToScreen(true);
    frame:SetPoint("TOPLEFT");
    frame:SetSize(10, 10);
    frame:SetToplevel(true);
    frame:SetShown(false);
    frame:EnableMouse(true);
    if (parent ~= nil) then
      frame:SetFrameLevel(parent.frame:GetFrameLevel()+1);
    end
    frame.object = object;

    -- Create the background and border textures
    -- NOTE: Replacement for the MUCH more efficient backdrop system
    frame.background = frame:CreateTexture(nil, "BACKGROUND");
    edges = {};
    for idx = 1, 8 do
      edges[idx] = frame:CreateTexture(nil, "BORDER");
    end
    edges[1]:SetTexCoord(0.5, 0.625, 0, 1);
    edges[1]:SetPoint("TOPLEFT");
    edges[2]:SetTexCoord(0.25, 1, 0.375, 1, 0.25, 0, 0.375, 0);
    edges[2]:SetPoint("TOPLEFT", edges[1], "TOPRIGHT");
    edges[2]:SetPoint("BOTTOMRIGHT", edges[3], "BOTTOMLEFT");
    edges[3]:SetTexCoord(0.625, 0.75, 0, 1);
    edges[3]:SetPoint("TOPRIGHT");
    edges[4]:SetTexCoord(0.125, 0.25, 0, 1);
    edges[4]:SetPoint("TOPLEFT", edges[3], "BOTTOMLEFT");
    edges[4]:SetPoint("BOTTOMRIGHT", edges[5], "TOPRIGHT");
    edges[5]:SetTexCoord(0.875, 1, 0, 1);
    edges[5]:SetPoint("BOTTOMRIGHT");
    edges[6]:SetTexCoord(0.375, 1, 0.5, 1, 0.375, 0, 0.5, 0);
    edges[6]:SetPoint("TOPLEFT", edges[7], "TOPRIGHT");
    edges[6]:SetPoint("BOTTOMRIGHT", edges[5], "BOTTOMLEFT");
    edges[7]:SetTexCoord(0.75, 0.875, 0, 1);
    edges[7]:SetPoint("BOTTOMLEFT");
    edges[8]:SetTexCoord(0, 0.125, 0, 1);
    edges[8]:SetPoint("TOPLEFT", edges[1], "BOTTOMLEFT");
    edges[8]:SetPoint("BOTTOMRIGHT", edges[7], "TOPRIGHT");
    frame.edges = edges;

    -- Create a 'witness' frame to be notified when the menu's anchor is hidden
    witness = CreateFrame("frame", nil, nil, nil);
    witness:SetShown(true);
    witness:SetSize(1, 1);
    witness:SetPoint("TOPLEFT", -1, 1);
    witness:SetScript("OnHide", object.OnWitnessHide);
    witness.object = object;

    -- Set the frame's script handlers
    frame:SetScript("OnEnter", object.OnFrameEnter);
    frame:SetScript("OnLeave", object.OnFrameLeave);
    if (object.progenitor == object) then
      frame:SetScript("OnHide", object.OnFrameHide);
      frame:SetScript("OnUpdate", object.OnFrameUpdate);
      object.hideTimer = -1;
    else
      frame:SetParent(object.parent.frame);
    end

    -- Add the menu to the list of menus monitored by the Blizzard code
    tinsert(UIMenus, "NigglesPetTeamsMenu"..object.level);

    -- Initialise the object's variables
    object.frame   = frame;
    object.witness = witness;

    -- Return the new object
    return object;
  end;

  --
  -- Method to process click events on a button in the menu
  --
  OnButtonClick = function(self, button)
    -- Local Variables
    local hideMenu;
    local hideAll = false;
    local refreshLvls;
    local itemData;
    local itemIdx = self.itemIdx;
    local menuData = self.object.data;
    local object = self.object;
    local lvl = 1;

    -- Check there is data for the button's item
    if (object.items[itemIdx] ~= nil) then
      -- Initialise some variables
      itemData = object.items[itemIdx];

      -- Toggle the button's checked state, if appropriate
      if (bit.band(self.flags, MENU_FLAG_CHECK) > 0) then
        self:SetCheck(not self.isChecked);
      end

      -- Check if the click should be processed
      if (self.type ~= "submenu") then
        -- Call either the button's or menu's OnClick function, if required
        if (type(itemData.onClick) == "function") then
          hideMenu, refreshLvls = itemData.onClick(object, object.args,
            itemIdx, self.value, self.isChecked);
        elseif (type(menuData.onClick) == "function") then
          hideMenu, refreshLvls = menuData.onClick(object, object.args,
            itemIdx, self.value, self.isChecked);
        end

        -- Work out if the menu should be hidden
        if (type(hideMenu) ~= "boolean") then
          hideMenu = true;
          if (type(itemData.autoHide) == "boolean") then
            hideMenu = itemData.autoHide;
          elseif (type(menuData.autoHide) == "boolean") then
            hideMenu = menuData.autoHide;
          end
        end

        -- Check if the menu should be hidden
        if (hideMenu) then
          -- Work out if all menus should be hidden
          if (object.level > 1) then
            if (type(itemData.hideAll) == "boolean") then
              hideAll = itemData.hideAll;
            elseif (type(menuData.hideAll) == "boolean") then
              hideAll = menuData.hideAll;
            end
          end

          -- Hide the menu(s), if required
          object:Hide(hideAll);
        end

        -- Check if any menus should be refreshed
        if ((not hideAll) and (refreshLvls ~= nil) and (refreshLvls > 0)) then
          -- If the current menu has been hidden...
          if (hideMenu) then
            -- ...skip refreshing it
            object = object.parent;
            lvl    = 2;
          end

          -- Refresh the number of menu levels specified
          while ((lvl <= refreshLvls) and (object ~= nil)) do
            object:Refresh();
            object = object.parent;
            lvl    = lvl+1;
          end
        end
      end
    end

    -- Play the appropriate sound
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);

    return;
  end;

  --
  -- Method to process the mouse entering a button in a menu
  --
  OnButtonEnter = function(self, motion)
    -- Local Variables
    local object = self.object;

    -- Process the event, based on the button's type
    if ((self.type == "submenu") and
        (self.data ~= nil) and
        (self:IsEnabled())) then
      -- Create a submenu, if required
      if (object.child == nil) then
        object.child = NigglesPetTeamsMenuClass:New(object);
      end

      -- Show the submenu
      object.child:Show(self.data, self);
    else
      -- Hide any submenu
      if (object.child ~= nil) then
        object.child:Hide();
      end
    end

    -- Stop the hide timer
    object.progenitor:HideTimerStop();

    return;
  end;

  --
  -- Method to process the mouse leaving a button in a menu
  --
  OnButtonLeave = function(self, motion)
    -- Start the hide timer
    self.object.progenitor:HideTimerStart();

    return;
  end;

  --
  -- Method to process the mouse entering a menu's frame
  --
  OnFrameEnter = function(self, motion)
    -- Stop the hide timer
    self.object.progenitor:HideTimerStop();

    return;
  end;

  --
  -- Method to process the top level menu's frame being hidden. This method is
  -- to handle the hiding of the frame a menu is being displayed for.
  --
  OnFrameHide = function (self)
    -- Hide all menus
    self.object:Hide(true);

    return;
  end;

  --
  -- Method to process the mouse leaving a menu's frame
  --
  OnFrameLeave = function(self, motion)
    -- Start the hide timer
    self.object.progenitor:HideTimerStart();

    return;
  end;

  --
  -- Method to process updates to the frame of the top-most menu
  --
  OnFrameUpdate = function(self, elapsed)
    -- Local Variables
    local object = self.object;

    -- Check if the hide timer is running
    if (object.hideTimer > 0) then
      -- Update the hide timer
      object.hideTimer = object.hideTimer-elapsed;

      -- Check if the hide timer has dropped below zero
      if (object.hideTimer <= 0) then
        -- Hide the menu
        object:Hide();
      end
    end

    return;
  end;

  --
  -- Method called when the 'witness' frame is hidden.
  --
  OnWitnessHide = function(self)
    -- Hide the menu
    self.object:Hide();
  end;

  --
  -- Method to refresh the color, checked, enabled states of a menu's buttons
  --
  Refresh = function(self)
    -- Local Variables
    local args = self.args;
    local button;
    local buttonIdx = 1;
    local buttons = self.buttons;
    local color;
    local isChecked;
    local isEnabled;
    local item;
    local itemIdx;
    local menuData = self.data;

    -- Refresh the shown buttons in the menu
    while ((buttons[buttonIdx] ~= nil) and
           (buttons[buttonIdx]:IsShown())) do
      -- Initialise some variables
      button  = buttons[buttonIdx];
      itemIdx = button.itemIdx;
      item    = self.items[itemIdx];

      -- Check/Uncheck the button, if required
      if (bit.band(button.flags, MENU_FLAG_CHECK) > 0) then
        if (type(item.isChecked) == "function") then
          isChecked = item.isChecked(self, args, itemIdx, item.value);
        elseif (item.isChecked ~= nil) then
          isChecked = item.isChecked;
        elseif (type(menuData.onCheck) == "function") then
          isChecked = menuData.onCheck(self, args, itemIdx, item.value);
        end
        button:SetCheck(isChecked);
      end

      -- Enable/disable the button
      isEnabled = (bit.band(button.flags, MENU_FLAG_ENABLED) > 0);
      if (isEnabled) then
        if (type(item.isEnabled) == "function") then
          isEnabled = item.isEnabled(self, args, itemIdx, item.value);
        elseif (item.isEnabled ~= nil) then
          isEnabled = item.isEnabled;
        elseif (type(menuData.onEnable) == "function") then
          isEnabled = menuData.onEnable(self, args, itemIdx, item.value);
        end
      end
      button:SetEnabled(isEnabled);
      button.expand:SetDesaturated(not isEnabled);

      -- Set the button's text color
      if ((isEnabled) or (button.type == "label")) then
        if ((item.color ~= nil) and
            (string.find(item.color, "^|[cC]%x%x%x%x%x%x%x%x$"))) then
          color = item.color;
        elseif (button.type == "label") then
          color = NORMAL_FONT_COLOR_CODE;
        else
          color = HIGHLIGHT_FONT_COLOR_CODE;
        end
      else
        color = "|cff7f7f7f";
      end
      button.text:SetTextColor(
        tonumber(strsub(color, 5,  6), 16)/255,
        tonumber(strsub(color, 7,  8), 16)/255,
        tonumber(strsub(color, 9, 10), 16)/255,
        tonumber(strsub(color, 3,  4), 16)/255);

      -- Move on to the next button
      buttonIdx = buttonIdx+1;
    end

    return;
  end;

  --
  -- Method to show the menu
  --
  Show = function(self, menuData, anchor, ...)
    -- Local Variables
    local args = self.args;
    local backdrop;
    local button;
    local buttonFlags;
    local buttonWidth;
    local buttons = self.buttons;
    local color;
    local cursorX;
    local cursorY;
    local edges;
    local frame = self.frame;
    local frameScale = UIParent:GetScale();
    local isChecked;
    local isEnabled;
    local isVisible;
    local itemLabel;
    local itemType;
    local items;
    local label;
    local maxWidth = 0;
    local menuPos;
    local menuStyle;
    local numButtons = 0;
    local offsetX = 0;
    local offsetY = 0;
    local parent = self.parent;
    local uiScale;

    -- Check essential info has been provided
    if ((type(menuData) ~= "table") or
        ((type(menuData.items) ~= "table") and
         (type(menuData.items) ~= "function")) or
        (anchor == nil) or
        (anchor.IsObjectType == nil) or
        (not anchor:IsObjectType("Frame"))) then
      return;
    end

    -- Save up to 9 arguments for the menu
    if (parent == nil) then
      args[1], args[2], args[3], args[4], args[5],
      args[6], args[7], args[8], args[9] = ...;
    end

    -- Hide the menu and its descendants
    self:Hide();

    -- If a function has been specified for the items...
    if (type(menuData.items) == "function") then
      -- ...call the function
      items = menuData.items(self, args, menuData.value);
      if (type(items) ~= "table") then
        return;
      end
    else
      items = menuData.items;
    end

    -- Save the menu's data and items
    self.data   = menuData;
    self.items  = items;
    self.anchor = anchor;

    -- Set the frame's scale, if required
    if (self.progenitor == self) then
      if (GetCVar("useUIScale") == "1") then
        frameScale = math.min(frameScale, tonumber(GetCVar("uiscale")));
      end
      frame:SetScale(frameScale);
    end

    -- Initialise a button for each item in the menu
    for itemIdx, itemInfo in ipairs(items) do
      -- Check the current item is valid and has a valid type
      if (type(itemInfo) == "table") then
        -- Work out the item's type
        if (type(itemInfo.type) == "string") then
          itemType = itemInfo.type:lower();
          if (self.buttonTypes[itemType] == nil) then
            itemType = nil;
          end
        elseif (itemInfo.type == nil) then
          itemType = "button";
        else
          itemType = nil;
        end
      else
        itemType = nil;
      end

      -- Check a label has been supplied, if required
      if ((itemType ~= nil) and
          (itemType ~= "divider") and
          (type(itemInfo.label) ~= "string")) then
       itemType = nil;
      end

      -- Check if the item is visible
      if (itemType ~= nil) then
        isVisible = true;
        if (type(itemInfo.isVisible) == "function") then
          isVisible = itemInfo.isVisible(self, itemIdx, itemInfo.value);
        elseif (type(itemInfo.isVisible) == "boolean") then
          isVisible = itemInfo.isVisible;
        end
      end

      -- Initialise a button for the menu item, if required
      if ((itemType ~= nil) and (isVisible)) then
        -- Initialise some variables
        buttonWidth = 0;
        buttonFlags = self.buttonTypes[itemType];
        isChecked   = false;
        isEnabled   = true;
        color       = nil;

        -- Create a button for the item, if required
        numButtons = numButtons+1;
        if (buttons[numButtons] == nil) then
          -- Create the button and set its ID
          buttons[numButtons] = CreateFrame("Button", nil, frame,
            "NigglesPetTeamsMenuButtonTemplate");
          button = buttons[numButtons];
          button:SetID(numButtons);
          button.object   = self;
          button.SetCheck = self.ButtonSetCheck;

          -- Position the button
          if (numButtons > 1) then
            button:SetPoint("TOPLEFT", buttons[numButtons-1],
              "BOTTOMLEFT", 0, 0);
            button:SetPoint("RIGHT", buttons[1]);
          end

          -- Set script handlers for the button
          button:SetScript("OnClick", self.OnButtonClick);
          button:SetScript("OnEnter", self.OnButtonEnter);
          button:SetScript("OnLeave", self.OnButtonLeave);
        else
          button = buttons[numButtons];
        end

        -- Save info for the button
        button.type    = itemType;
        button.itemIdx = itemIdx;
        button.flags   = buttonFlags;
        button.value   = itemInfo.value;

        -- Perform any tasks specific to the item's type
        if (itemType == "radiobutton") then
          button.group = itemInfo.group;
        elseif (itemType == "submenu") then
          -- Save the menu data for the submenu
          button.data = itemInfo;
        end

        -- Set the button's text
        if (bit.band(buttonFlags, MENU_FLAG_LABEL) > 0) then
          if (type(itemInfo.label) == "string") then
            button:SetText(itemInfo.label:gsub("(|([1-9]))",
              function(_, match)
                local argIdx = tonumber(match);
                return tostring(args[argIdx]);
              end));
          else
            button:SetText("?");
          end
          buttonWidth = button.text:GetWidth();
        end

        -- Check if the button's check will be visible
        if (bit.band(buttonFlags, MENU_FLAG_CHECK) > 0) then
          button:SetCheck(isChecked);
          button.text:SetPoint("LEFT", 16, 0);
        else
          button.text:SetPoint("LEFT", 0, 0);
        end

        -- Adjust the button's width, based on its flags
        if (bit.band(buttonFlags, MENU_FLAG_CHECK) > 0) then
          buttonWidth = buttonWidth+MENU_CHECK_WIDTH+3;
        end
        if (bit.band(buttonFlags, MENU_FLAG_EXPAND) > 0) then
          buttonWidth = buttonWidth+MENU_EXPAND_WIDTH;
        end

        -- Show/Hide the button and its components based on the item's style
        button:Show();
        for name, mask in pairs(self.buttonComponents) do
          button[name]:SetShown(bit.band(buttonFlags, mask) > 0);
        end

        -- Update the maximum button width
        maxWidth = math.max(maxWidth, buttonWidth);
      end
    end

    -- Check at least one button was set up for the items
    if (numButtons > 0) then
      -- Hide any unused buttons
      for idx = numButtons+1, #buttons do
        buttons[idx]:Hide();
      end

      -- Refresh the menu's buttons
      self:Refresh();

      -- Work out the menu's style
      if (type(menuData.style) == "string") then
        -- Make sure the specified menu style is valid
        menuStyle = menuData.style:lower();
        if (self.backdropStyles[menuStyle] ~= nil) then
          menuStyle = menuData.style;
        end
      end
      if (menuStyle == nil) then
        -- Use the style of the menu's parent or "right"
        menuStyle = (self.parent ~= nil and self.parent.style or "right");
      end
      self.style = menuStyle;

      -- Set the menu's background, based on its style
      backdrop = self.backdropStyles[self.style];
      frame.background:SetTexture(backdrop.bgFile);
      if (backdrop.bgColor ~= nil) then
        frame.background:SetVertexColor(backdrop.bgColor.r,
          backdrop.bgColor.g, backdrop.bgColor.b, backdrop.bgColor.a);
      end
      frame.background:SetHorizTile(backdrop.tile);
      frame.background:SetVertTile(backdrop.tile);
      frame.background:SetPoint("TOPLEFT",
        backdrop.insets.left, -backdrop.insets.top);
      frame.background:SetPoint("BOTTOMRIGHT",
        -backdrop.insets.right, backdrop.insets.bottom);
       
      -- Set the menu's edges, based on its style
      edges = frame.edges;
      for idx = 1, #edges do
        edges[idx]:SetTexture(backdrop.edgeFile);
      end
      for idx = 1, #edges, 2 do
        edges[idx]:SetSize(backdrop.edgeSize, backdrop.edgeSize);
      end

      -- Adjust the position and size of all buttons
      buttons[1]:SetPoint("TOPLEFT", backdrop.padding.left,
        -backdrop.padding.top);
      buttons[1]:SetPoint("RIGHT", -backdrop.padding.right, 0);

      -- Adjust the size of the menu
      frame:SetSize(
        math.min(backdrop.padding.left+backdrop.padding.right+maxWidth,
          MENU_MAX_WIDTH),
        backdrop.padding.top+backdrop.padding.bottom+
          (numButtons*self.buttons[1]:GetHeight()));

      -- Work out where to position the menu
      if (self.parent == nil) then
        menuPos = (menuData.position or "right");
      else
        menuPos = "right"
      end

      -- Get the top of the menu to overcome restrictive frame errors
      frame:GetTop();

      -- Position and show the menu
      frame:ClearAllPoints();
      if (type(menuData.offset) == "table") then
        offsetX = (menuData.offset.x or 0);
        offsetY = (menuData.offset.y or 0);
      end
      if (menuPos == "right") then
        if (self.parent ~= nil) then
          frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT",
            offsetX, offsetY+frame:GetTop()-buttons[1]:GetTop());
        else
          frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT",
            offsetX, offsetY);
        end
      elseif (menuPos == "bottom") then
        frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT",
          offsetX, offsetY);
      elseif (menuPos == "cursor") then
        uiScale = math.min((GetCVar("useUIScale") == "1" and
          tonumber(GetCVar("uiscale")) or 0x7FFFFFFF), UIParent:GetScale());
        cursorX, cursorY = GetCursorPosition();
        frame:SetPoint("TOPLEFT", anchor, "TOPLEFT",
          offsetX+(cursorX/uiScale)-anchor:GetLeft(),
          offsetY+(cursorY/uiScale)-anchor:GetTop());
      end
      frame:Show();

      -- Set the 'witness' frame's parent
      self.witness:SetParent(anchor);
    end

    -- Stop the hide timer, if required
    if (self.progenitor == self) then
      self.progenitor:HideTimerStop();
    end

    return;
  end;

  --
  -- Method to toggle the menu's visibility
  --
  Toggle = function(self, menuData, anchor, ...)
    -- Show/Hide the menu
    if ((not self.frame:IsShown()) or (anchor ~= self.anchor)) then
      self:Show(menuData, anchor, ...);
    else
      self:Hide(false);
    end

    return;
  end
};
