-------------------------------------------------------------------------------
--                G  O  B  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

NglPtDB = {};

-------------------------------------------------------------------------------
--                L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

local OPTIONS_OFFSET_LEFT    = 16;
local OPTIONS_OFFSET_TOP     = -16;
local OPTIONS_OFFSET_HEADING = 8;
local OPTIONS_OFFSET_SPACING = 5;

local NEW_FEATURE_ICON =
  "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:0|t";

-- Required data saved for the Niggles Pet Teams addon
local requiredDB =
{
  layout       = {},
  petTeams     = {},
  pets         = {},
  settings     =
  {
    generalIsVisible      = false,
    generalAutoShowStrat  = true,
    generalDismissPet     = false,
    generalPetBreeds      = true,
    generalShowTutorials  = true,
    generalTargetTeamName = true,
    categories            = {},
  },
  filters      =
  {
    continents   = L.MASK_UNFILTERED,
    completeness = L.MASK_UNFILTERED,
    opponents    = L.MASK_UNFILTERED,
    categories   = L.MASK_UNFILTERED,
    lastEdited   = {},
    search       = L.MASK_UNFILTERED,
    text         = "",
  },
  tutorialSeen = 0,
};

local options;
local optionsObjectsCreateFunc;
local optionsObjects =
{
  button      = {},
  checkbutton = {},
  custom      = {},
  dropdown    = {},
  editbox     = {},
  heading     = {},
};

local updatedSettings;

-------------------------------------------------------------------------------
--             L  O  C  A  L     D  E  F  I  N  I  T  I  O  N  S
-------------------------------------------------------------------------------

local optionsButtonOnClick;
local optionsCheckButtonOnClick;
local optionsDropDownItemOnCheck;
local optionsDropDownItemOnClick;
local optionsDropDownOnClick;
local optionsEditBoxOnTextChanged;
local optionsHeadingOnClick;
local optionsHeadingOnEnableDisable;
local optionsHeadingSetChecked;
local optionsObjectOnEnter;
local optionsOnRefresh;
local optionsSectionEnable;
local optionsPanelRefresh;
local settingCategoriesValidate;
local settingsCreate;

-------------------------------------------------------------------------------
--                L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function called when the 'Reset Tutorials' button is clicked
--
local function optionResetTutorialsOnClick(self, mouseButton, layout)
  -- Play an appropriate sound
  PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK);

  -- Hide the Collections Journal, if visible
  if ((CollectionsJournal ~= nil) and (CollectionsJournal:IsVisible())) then
    CollectionsJournal:Hide();
  end

  -- Hide the pet teams list
  NglPtDB.settings.generalIsVisible = false;
  L.petTeamsShow(false);
  if (type(L.petTeamEditFrame) == "table") then
    L.petTeamEditFrame:Hide();
  end

  -- Reset the tutorials for the addon
  NglPtDB.tutorialSeen = 0;

  -- Disable the button
  self:Disable();

  return;
end

--
-- Function to create an options button
--
local function optionsButtonCreate(panel)
  -- Local Variables
  local button;

  -- Create the check button
  button = CreateFrame("button", nil, panel, "UIPanelButtonTemplate");
  button:SetScript("OnClick", optionsButtonOnClick);
  button:SetScript("OnEnter", optionsObjectOnEnter);

  -- Set the check button's text to force creation of the font string
  button:SetText(" ");

  return button;
end

--
-- Function to process check button clicks in options panels
--
optionsButtonOnClick = function(self, mouseButton)
  -- Local Variables
  local layout = self.layout;

  -- Call the 'OnClick' handler for the button, if available
  if (type(layout.onClick) == "function") then
    layout.onClick(self, mouseButton, layout);
  end

  return;
end

--
-- Function to create an options check button
--
local function optionsCheckButtonCreate(panel)
  -- Local Variables
  local fontString;
  local checkButton;

  -- Create the check button
  checkButton = CreateFrame("checkbutton", nil, panel,
    "NigglesPetTeamsOptionsCheckButtonTemplate");
  checkButton:SetScript("OnClick", optionsCheckButtonOnClick);
  checkButton:SetScript("OnEnter", optionsObjectOnEnter);

  -- Change the points for the check button's textures to allow resizing
  -- Note: This assumes that the check button has only the standard textures.
  for _, region in pairs({checkButton:GetRegions()}) do
    if (region:GetObjectType() == "Texture") then
      region:ClearAllPoints();
      region:SetPoint("TOPLEFT");
      region:SetWidth(26);
      region:SetHeight(26);
    end
  end

  -- Set the check button's text to force creation of the font string
  checkButton:SetText(" ");

  -- Adjust the position of the font string
  fontString = checkButton:GetFontString();
  fontString:SetPoint("TOP", 0, -6);
  fontString:SetPoint("LEFT", 26, 0);

  return checkButton;
end

--
-- Function to process check button clicks in options panels
--
optionsCheckButtonOnClick = function(self, mouseButton)
  -- Local Variables
  local setting = self.layout.setting;

  -- Update the check box's setting
  if (self:GetChecked()) then
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    if (self.mask ~= nil) then
      updatedSettings[setting] =
        bit.bor(updatedSettings[setting], self.mask);
    else
      updatedSettings[setting] = true;
    end
  else
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
    if (self.mask ~= nil) then
      updatedSettings[setting] =
        bit.band(updatedSettings[setting], bit.bnot(self.mask));
    else
      updatedSettings[setting] = false;
    end
  end

  -- Enable any dependants, if required
  if (self.layout.dependants) then
    optionsSectionEnable(self:GetParent());
  end

  return;
end

--
-- Function to create an options check button
--
local function optionsDropDownCreate(panel)
  -- Local Variables
  local dropDown;

  -- Create the drop down
  dropDown = CreateFrame("Button", nil, panel,
    "NigglesPetTeamsDropDownTemplate");
  dropDown:SetScript("OnClick", optionsDropDownOnClick);
  dropDown.menuData =
  {
    style    = "menu",
    position = "bottom",
    offset   = {x = -2, y = 2},
    onClick  = optionsDropDownItemOnClick,
    onCheck  = optionsDropDownItemOnCheck,
    items    = nil
  };

  return dropDown;
end

--
-- Function to update the value of a dropdown when one of its options is
-- clicked.
--
optionsDropDownItemOnCheck = function(menu, menuArgs, index, value)
  -- Local Variables
  local anchor = menu:GetAnchor();

  return (value == updatedSettings[anchor.layout.setting]);
end

--
-- Function to update the value of a dropdown when one of its options is
-- clicked.
--
optionsDropDownItemOnClick = function(menu, menuArgs, index, value)
  -- Local Variables
  local items = menu:GetItems();
  local anchor = menu:GetAnchor();

  -- Save the new value
  updatedSettings[anchor.layout.setting] = value;

  -- Set the drop down menu's value
  anchor:SetText((items[index].color or "")..items[index].label);

  return;
end

--
-- Function to display a menu for a dropdown when it is clicked on
--
optionsDropDownOnClick = function(self, mouseButton)
  -- Display the menu for the dropdown
  L.menu:Toggle(self.menuData, self);

  return;
end

--
-- Function to create an options edit box
--
local function optionsEditBoxCreate(panel)
  -- Local Variables
  local editBox;
  local fontString;

  -- Create the edit box
  editBox = CreateFrame("editbox", nil, panel,
    "NigglesPetTeamsOptionsEditBoxTemplate");
  editBox:SetScript("OnTextChanged", optionsEditBoxOnTextChanged);

  return editBox;
end

-- 
-- Function called when the text changes in an Options edit box
--
optionsEditBoxOnTextChanged = function(self)
  -- Local Variables
  local layout = self.layout;
  local text = self:GetText();

  -- Strip whitespace characters from the text
  text = text:match("^%s*(.-)%s*$");
  if (text == "") then
    text = nil;
  end

  -- Save the new value for the setting
  if (type(updatedSettings[layout.setting]) == "table") then
    if (layout.index ~= nil) then
      updatedSettings[layout.setting][layout.index] = text;
    end
  else
    updatedSettings[layout.setting] = text;
  end

  return;
end

--
-- Function called when a Options heading is created
--
local function optionsHeadingCreate(panel)
  -- Local Variables
  local fontString;
  local heading;

  -- Create the heading
  heading = CreateFrame("checkbutton", nil, panel,
    "NigglesPetTeamsOptionsHeadingTemplate");
  heading:SetScript("OnClick",   optionsHeadingOnClick);
  heading:SetScript("OnDisable", optionsHeadingOnEnableDisable);
  heading:SetScript("OnEnable",  optionsHeadingOnEnableDisable);
  heading:SetScript("OnEnter",   optionsObjectOnEnter);

  -- Change the points for the heading's textures to allow resizing
  -- Note: This assumes that the check button has only the standard textures.
  for _, region in pairs({heading:GetRegions()}) do
    if (region:GetObjectType() == "Texture") then
      region:ClearAllPoints();
      region:SetPoint("TOPLEFT");
      region:SetWidth(26);
      region:SetHeight(26);
    end
  end

  -- Set the heading's text to force creation of the font string
  heading:SetText(" ");

  -- Adjust the position of the font string
  fontString = heading:GetFontString();
  fontString:SetPoint("TOP", 0, -5);

  -- Override the 'SetChecked' method
  heading.origSetChecked = heading.SetChecked;
  heading.SetChecked     = optionsHeadingSetChecked;

  return heading;
end

--
-- Function called when a options Heading is clicked
--
optionsHeadingOnClick = function(self, mouseButton)
  -- Check the heading has a setting
  if (self.layout.setting ~= nil) then
    -- Perform the same actions as a check button
    optionsCheckButtonOnClick(self, mouseButton)

    -- Update the state of the sub-text
    optionsHeadingOnEnableDisable(self)
  end

  return;
end

--
-- Function called when a heading is enabled/disabled
--
optionsHeadingOnEnableDisable = function(self)
  -- Update the state of the sub-text
  if ((self.layout.setting == nil) or
      ((self:IsEnabled()) and (self:GetChecked()))) then
    self.subText:SetFontObject("GameFontNormalSmall");
  else
    self.subText:SetFontObject("GameFontDisableSmall");
  end

  return;
end

--
-- Function called when a heading is checked/unchecked
--
optionsHeadingSetChecked = function(self, checked)
  -- Call the original 'SetChecked' function
  self.origSetChecked(self, checked);

  -- Update the state of the sub-text
  optionsHeadingOnEnableDisable(self)

  return;
end

--
-- Function called when the addon's options are committed
--
local function optionsOnCommit()
  -- Check if there are any updated settings
  if (updatedSettings ~= nil) then
    -- Save the new settings
    NglPtDB.settings = updatedSettings;

    -- Clear the updated settings
    updatedSettings = nil;

    -- Validate the Pet Team Categories
    settingCategoriesValidate();

    -- Update panels affected by the settings
    L.petTeamEditSettingsUpdate();
  end

  return;
end

--
-- Function to set the tooltip for a widget in the options panels
--
optionsObjectOnEnter = function(self)
  -- Local Variables
  local layout = self.layout;
  local text;

  -- Work out if there is a tooltip for the object
  if (layout.tooltip ~= nil) then
    text = text..layout.tooltip;
  elseif (layout.setting ~= nil) then
    text = "|cFFFFFFFF"..L[layout.setting].."|r\n"..
      L[layout.setting.."Tooltip"];
  end

  -- Check the object has a tooltip
  if ((text ~= nil) and (text ~= layout.setting.."Tooltip")) then
    -- Display the object's tooltip
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 20);
    GameTooltip:SetText(format(text, layout.value), nil, nil, nil, nil, 1);
    GameTooltip:Show();
  end

  return;
end

--
-- Function to change all the settings to their default values
--
local function optionsOnDefault(frame)
  -- Destroy any updated settings
  updatedSettings = nil;

  -- Reset all the settings to their default values
  NglPtDB.settings = {};
  settingsCreate(requiredDB.settings, NglPtDB.settings);

  -- Refresh the options panel
  optionsOnRefresh();

  return;
end

--
-- Function to refresh the options for the options panels
--
optionsOnRefresh = function()
  -- Check there aren't any updated options already
  if ((SettingsPanel:IsVisible()) and (updatedSettings == nil)) then
    -- Copy the existing settings
    updatedSettings = CopyTable(NglPtDB.settings);
  end

  return;
end

--
-- Function to enable/disable objects in options panels
--
optionsSectionEnable = function(self)
  -- Local Variables
  local dependency;

  -- Enable/disable objects, based on any dependency
  for _, objects in pairs(optionsObjects) do
    for _, object in ipairs(objects) do
      dependency = object.layout.dependency;
      if ((object:IsShown()) and (dependency ~= nil)) then
        if (type(dependency) == "string") then
          if ((updatedSettings[dependency] ~= nil) and
              (object.SetEnabled ~= nil)) then
            object:SetEnabled(updatedSettings[dependency]);
          end
        elseif (type(dependency) == "function") then
          dependency(object);
        end
      end
    end
  end

  -- Hide the menu
  L.menu:Hide();

  return;
end

--
-- Function called when an Options section is shown. It lays out the objects 
-- for the section and calls any custom function specified.
--
local function optionsSectionOnShow(self)
  -- Local Variables
  local indent = OPTIONS_OFFSET_LEFT;
  local layout;
  local numObjs = {};
  local objType;
  local object;
  local prevObject;
  local prevYPos;
  local setting;
  local totalObjects = 0;
  local width;
  local xPos = OPTIONS_OFFSET_LEFT
  local yPos = OPTIONS_OFFSET_TOP;
  local yPosHeading = yPos;
  local yPosMin = yPos;

  -- Check the option section can be laid out
  if (self.nglSection == nil) then
    return;
  end
   
  -- Initialise the updated settings, if required
  if (updatedSettings == nil) then
    optionsOnRefresh();
  end

  -- Reset the custom objects
  optionsObjects.custom = {};

  -- Lay out objects for the section
  for idx, layout in ipairs(self.nglSection.layout) do
    -- Initialise some variables
    object = nil;
    objType = layout.objType:lower();

    -- Get the next object
    if (objType ~= "custom") then
      numObjs[objType] = (numObjs[objType] or 0)+1;
      if (optionsObjects[objType][numObjs[objType]] == nil) then
        optionsObjects[objType][numObjs[objType]] =
          optionsObjectsCreateFunc[objType](self);
      end
      object = optionsObjects[objType][numObjs[objType]];
    else
      object = _G[layout.name];
      numObjs.custom = (numObjs.custom or 0)+1;
      optionsObjects.custom[numObjs.custom] = object;
    end
    object.layout = layout;

    -- Lay out the object
    if (objType == "button") then
      object:SetFormattedText((layout.label or L[layout.setting]),
        layout.value);
    elseif (objType == "checkbutton") then
      -- Set up the check button
      if (type(layout.mask) == "function") then
        object.mask = layout.mask(layout.value);
      else
        object.mask = layout.mask;
      end
      object:SetFormattedText((layout.label or L[layout.setting])..
        (layout.newFeature and NEW_FEATURE_ICON or ""), layout.value);
      if (object.mask ~= nil) then
        object:SetChecked(bit.band((updatedSettings[layout.setting] or 0),
          object.mask) ~= 0);
      else
        object:SetChecked(updatedSettings[layout.setting] or false);
      end
    elseif (objType == "dropdown") then
      -- Set up the drop down menu
      object.menuData.items = layout.items;
      object:SetWidth(layout.width or 100);

      -- Set the dropdown's value
      setting = updatedSettings[layout.setting]
      for _, current in ipairs(layout.items) do
        if (current.value == setting) then
          object:SetText((current.color or "")..current.label);
          break;
        end
      end
    elseif (objType == "editbox") then
      object.label:SetFormattedText((layout.label or L[layout.setting]),
        layout.value);
      if (type(updatedSettings[layout.setting]) == "table") then
        object:SetText(updatedSettings[layout.setting][layout.index] or "");
      else
        object:SetText(updatedSettings[layout.setting] or "");
      end
    elseif (objType == "heading") then
      -- Enable/disable user input
      object:EnableKeyboard(layout.setting ~= nil);
      object:EnableMouse(layout.setting ~= nil);

      -- Set up the heading
      object:SetText(L[layout.text]);
      object.subText:SetText(L[layout.subText]);
      object:GetNormalTexture():Show();
      object:SetChecked(updatedSettings[layout.setting] or false);

      -- Set up the heading's textures and font strings
      for _, region in pairs({object:GetRegions()}) do
        if (region:GetObjectType() == "Texture") then
          if (layout.setting == nil) then
            region:Hide();
          end
        elseif (region:GetObjectType() == "FontString") then
          region:SetPoint("LEFT", (layout.setting ~= nil and 26 or 0), 0);
        end
      end
    end

    -- Check there is an object to lay out
    if (object ~= nil) then
      -- Adjust the current position, based on layout options
      if (objType == "heading") then
        indent = OPTIONS_OFFSET_LEFT;
        xPos   = indent;
        yPos   = yPosMin-(totalObjects > 0 and OPTIONS_OFFSET_HEADING or 0);
      elseif ((objType ~= "heading") and (layout.newColumn == true)) then
        -- Adjust the current position
        xPos = xPos+200;
        yPos = yPosHeading;
      elseif (layout.newLine == 1) then
        xPos = indent;
        yPos = yPosMin;
      end

      -- Perform any custom initialisation
      if (type(layout.init) == "function") then
        layout.init(object, layout.setting);
      end

      -- Perform any post-processing for the object
      if (objType == "button") then
        width = (layout.width or object:GetFontString():GetStringWidth()+30);
        object:SetWidth(width);
      elseif (objType == "checkbutton") then
        width = object:GetFontString():GetStringWidth();
        object:SetWidth(26+width);
      elseif (objType == "editbox") then
        width = (layout.labelWidth or object.label:GetStringWidth());
        object.label:SetWidth(width);
        if ((layout.editWidth or 0) > 0) then
          object:SetWidth(width+layout.editWidth+16);
        else
          object:SetWidth(layout.width or width+150);
        end
        object:SetTextInsets(width+8, 8, 0, 0);
        object:SetMaxLetters(layout.maxLetters or 0);
      end

      -- Position and show the object
      object:SetParent(self);
      if ((objType ~= "heading") and
          (layout.adjacent) and
          (prevObject ~= nil)) then
        object:SetPoint("TOPLEFT", prevObject, "TOPRIGHT",
          (layout.xOffset or 0), (layout.yOffset or 0));
      else
        object:SetPoint("TOPLEFT", xPos+(layout.xOffset or 0),
          yPos+(layout.yOffset or 0));
        yPos = yPos-(layout.height or
          object:GetHeight()+OPTIONS_OFFSET_SPACING);
      end
      object:Enable();
      object:Show(true);

      -- Update the current position
      if ((objType == "heading") and (layout.setting ~= nil)) then
        indent = OPTIONS_OFFSET_LEFT+26;
        xPos   = indent;
      end
      yPosMin = math.min(yPosMin, yPos);
      if (objType == "heading") then
        yPosHeading = yPos;
      end

      -- Save the object
      prevObject = object;

      -- Increment the total number of objects
      totalObjects = totalObjects+1;
    end
  end

  -- Hide any unused objects
  for objType, objects in pairs(optionsObjects) do
    for idx = (numObjs[objType] or 0)+1, #objects do
      objects[idx]:Hide();
    end
  end

  -- Enable/disable objects based on current settings
  optionsSectionEnable(self);

  return;
end

-- Function to validate the pet team categories
settingCategoriesValidate = function()
  -- Local Variables
  local categories = NglPtDB.settings.categories;
  local bitMask = 1;
  local validCategories = 0;

  -- Make sure the pet team categories are valid
  for catIdx = 1, L.MAX_CATEGORIES do
    if (categories[catIdx] ~= nil) then
      if (type(categories[catIdx]) == "string") then
        if (categories[catIdx]:match("^%s*(.-)%s*$") == "") then
          categories[catIdx] = nil;
        end
      else
        categories[catIdx] = nil;
      end
      if (categories[catIdx] ~= nil) then
        validCategories = validCategories+bitMask;
      end
    end
    bitMask = bitMask*2;
  end

  -- Update the Categories filter
  if (validCategories > 0) then
    if (NglPtDB.filters.categories ~= L.MASK_UNFILTERED) then
      NglPtDB.filters.categories = bit.band(NglPtDB.filters.categories,
        (L.MASK_CATEGORY_NONE+validCategories));
    end
  else
    NglPtDB.filters.categories = L.MASK_UNFILTERED;
  end

  -- Validate the categories for the pet teams
  for _, teamInfo in ipairs(NglPtDB.petTeams) do
    if (categories[teamInfo.category] == nil) then
      teamInfo.category = 0;
    end
  end

  -- Filter the pet teams, if required
  if ((NigglesPetTeams ~= nil) and (NigglesPetTeams:IsShown())) then
    L.petTeamsFilter();
  end

  return;
end

--
-- Function called to enable/disable the 'Reset Tutorials' button
--
local function settingResetTutorialsOnEnable(self, layout)
  -- Enable/disable the 'Reset Tutorials' button
  self:SetEnabled((updatedSettings.generalShowTutorials) and
                  (NglPtDB.tutorialSeen ~= 0));

  return;
end

--
-- Function to create required settings. This function is recursive.
--
settingsCreate = function(required, current)
  -- Check each required setting exists
  for key, value in pairs(required) do
    -- Check if the required setting is a table
    if (type(value) == "table") then
      -- Create the required table, if needed
      if (type(current[key]) ~= "table") then
        current[key] = {};
      end

      -- Set any required settings for the current setting
      if (next(required[key])) then
        settingsCreate(value, current[key]);
      end
    elseif (type(value) ~= type(current[key])) then
      current[key] = value;
    end
  end

  return;
end

--
-- Function to destroy obsolete settings. This function is recursive.
--
local function settingsDestroy(required, current)
  -- Check the current setting isn't empty
  if (next(current)) then
    -- Check each of the current settings
    for key, value in pairs(current) do
      if (required[key] == nil) then
        current[key] = nil;
      elseif ((type(required[key]) == "table") and (next(required[key]))) then
        settingsDestroy(required[key], value);
      end
    end
  end

  return;
end

-------------------------------------------------------------------------------
--                A  D  D  O  N     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to make sure all the settings are initialised
--
L.settingsInit = function()
  -- Local Variables
  local prevFrame;

  -- Remove any obsolete settings
  settingsDestroy(requiredDB, NglPtDB);

  -- Create any missing settings
  settingsCreate(requiredDB, NglPtDB);

  -- Make sure the Last Edited settings are valid
  if (NglPtDB.filters.lastEdited[0] == nil) then
    NglPtDB.filters.lastEdited[0] = 1;
  end

  -- Validate the Pet Team Categories
  settingCategoriesValidate()

  -- Initialise the sections of the options
  for idx, section in ipairs(options) do
    -- Create the canvas for the (sub)category
    section.canvas = CreateFrame("Frame");
    section.canvas:SetScript("OnShow", optionsSectionOnShow);
    section.canvas.nglSection = section;
    section.canvas:Hide();

    -- Set the required functions for the canvas
    section.canvas.OnCommit  = optionsOnCommit;
    section.canvas.OnDefault = optionsOnDefault;
    section.canvas.OnRefresh = optionsOnRefresh;

    -- Create the (sub)category in the Settings API
    if (idx == 1) then
      section.category =
        Settings.RegisterCanvasLayoutCategory(section.canvas,
        (section.label or section.name));
    else
      section.category =
        Settings.RegisterCanvasLayoutSubcategory(options[1].category,
          section.canvas, (section.label or section.name));
    end
    Settings.RegisterAddOnCategory(section.category);
  end

  return;
end

-------------------------------------------------------------------------------
--                L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

options =
{
  {
    name   = L["AddonName"],
    layout = 
    {
      -- General
      {
        objType    = "heading",
        text       = GENERAL,
        subText    = "generalSubText",
      },
      {
        objType    = "checkbutton",
        setting    = "generalAutoShowStrat",
      },
      {
        objType    = "checkbutton",
        setting    = "generalDismissPet",
      },
      {
        objType    = "checkbutton",
        setting    = "generalPetBreeds",
      },
      {
        objType    = "checkbutton",
        setting    = "generalShowTutorials",
        dependants = true,
        newColumn  = true,
      },
      {
        objType    = "button",
        label      = RESET_TUTORIALS,
        dependency = settingResetTutorialsOnEnable,
        adjacent   = 1,
        xOffset    = 10,
        onClick    = optionResetTutorialsOnClick,
      },
      {
        objType    = "checkbutton",
        setting    = "generalTargetTeamName",
      },
      -- Categories
      {
        objType    = "heading",
        text       = CATEGORIES,
        subText    = "categoriesSubText",
      },
      {
        objType    = "editbox",
        label      = L.categoryIcons[1],
        setting    = "categories",
        index      = 1,
        maxLetters = 32,
      },
      {
        objType    = "editbox",
        label      = L.categoryIcons[2],
        setting    = "categories",
        index      = 2,
        maxLetters = 32,
      },
      {
        objType    = "editbox",
        label      = L.categoryIcons[3],
        setting    = "categories",
        index      = 3,
        maxLetters = 32,
      },
      {
        objType    = "editbox",
        label      = L.categoryIcons[4],
        setting    = "categories",
        index      = 4,
        maxLetters = 32,
      },
      {
        objType    = "editbox",
        label      = L.categoryIcons[5],
        setting    = "categories",
        index      = 5,
        maxLetters = 32,
        newColumn  = true,
      },
      {
        objType    = "editbox",
        label      = L.categoryIcons[6],
        setting    = "categories",
        index      = 6,
        maxLetters = 32,
      },
      {
        objType    = "editbox",
        label      = L.categoryIcons[7],
        setting    = "categories",
        index      = 7,
        maxLetters = 32,
      },
      {
        objType    = "editbox",
        label      = L.categoryIcons[8],
        setting    = "categories",
        index      = 8,
        maxLetters = 32,
      },
    },
  },
};

optionsObjectsCreateFunc = 
{
  button      = optionsButtonCreate,
  checkbutton = optionsCheckButtonCreate,
  editbox     = optionsEditBoxCreate,
  dropdown    = optionsDropDownCreate,
  heading     = optionsHeadingCreate,
};
