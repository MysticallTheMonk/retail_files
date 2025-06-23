-------------------------------------------------------------------------------
--                 L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

local ICONS_PER_ROW    = 5;
local ICONS_NUM_ROWS   = 3;
local ICONS_ROW_HEIGHT = 41;

local PET_BATTLE_ICON = "Interface\\ICONS\\PetJournalPortrait";

local teamIcons = {};
local opponentIconOffset = 0;
local iconSpeciesMapping = {};

local petTeamEditInfo;

local cursorPet =
{
  slot = nil,
  info = {}
};

local opponentFiltered = {[0] = 0};

local tutorialPlateInfo =
{
  FramePos  = {x = 0, y = -22},
  FrameSize = {width = 600, height = 391},
  [1] =
  {
    HighLightBox = {x = 8, y = -43, width = 46, height = 55},
    ButtonPos    = {x = 9, y = -47},
    ToolTipDir   = "RIGHT",
    ToolTipText  = L["PetTeamEditTutorial1"],
  },
  [2] =
  {
    HighLightBox = {x = 56, y = -43, width = 250, height = 55},
    ButtonPos    = {x = 165, y = -47},
    ToolTipDir   = "RIGHT",
    ToolTipText  = L["PetTeamEditTutorial2"],
  },
 [3] =
  {
    HighLightBox = {x = 8, y = -131, width = 277, height = 230},
    ButtonPos    = {x = 125, y = -226},
    ToolTipDir   = "RIGHT",
    ToolTipText  = L["PetTeamEditTutorial3"],
  },
  [4] =
  {
    HighLightBox = {x = 312, y = -25, width = 296, height = 341},
    ButtonPos    = {x = 445, y = -165},
    ToolTipDir   = "RIGHT",
    ToolTipText  = L["PetTeamEditTutorial4"],
  },
};

-------------------------------------------------------------------------------
--              L  O  C  A  L     D  E  F  I  N  I  T  I  O  N  S
-------------------------------------------------------------------------------

local iconDropDownUpdate;
local opponentDropDownOnTextChanged;
local petTeamEditEnable;
local petTeamEditLoadoutUpdate;
local petTeamEditPetDrop;
local tutorialOnClick;
local tutorialPetJournalOnClick;

-------------------------------------------------------------------------------
--                 L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function called when an icon button is clicked in the Icon dropdown.
-- It updates the icon for pet team being edited.
--
local function iconDropDownOnClick(self, button)
  -- Save the new icon for the pet team
  petTeamEditInfo.iconPathId = self.iconPathId;

  -- Update the icon displayed for the pet team
  L.petTeamEditFrame.icon.normal:SetTexture(
    L.petTeamIconGetTexture(petTeamEditInfo.iconPathId))

  -- Hide the Icon dropdown
  self:GetParent():Hide();

  return;
end

--
-- Function called when the Icon dropdown scroll frame is scrolled
--
local function iconDropDownOnScroll(self, offset)
  FauxScrollFrame_OnVerticalScroll(self, offset, 41, iconDropDownUpdate);
  return;
end

--
-- Function called when the Icon drop down is shown
--
local function iconDropDownOnShow(self)
  -- Local Variables
  local button;
  local iconId;
  local idx;
  local isOpponentIcon = false;
  local numIcons = #teamIcons;
  local numRows = math.ceil(#teamIcons/ICONS_PER_ROW);
  local offset = 0;
  local prevButton;
  local selectedId = petTeamEditInfo.iconPathId;

  -- Create the frame's buttons, if required
  if (self.buttons == nil) then
    self.buttons = {};
    for buttonIdx = 1, 15 do
      button = CreateFrame("CHECKBUTTON", nil, self,
        "NigglesPetTeamIconButtonTemplate");
      if (buttonIdx == 1) then
        button:SetPoint("TOPLEFT", 7, -6);
      elseif (buttonIdx%5 == 1) then
        button:SetPoint("TOPLEFT", self.buttons[buttonIdx-5],
          "BOTTOMLEFT", 0, -3);
      else
        button:SetPoint("TOPLEFT", prevButton, "TOPRIGHT", 3, 0);
      end
      button:SetScript("OnClick", iconDropDownOnClick);
      self.buttons[buttonIdx] = button;
      prevButton = button;
    end
  end

  -- Check if the team has an opponent
  if (petTeamEditInfo.opponentId > 0) then
    -- Add the icons for the pet team's opponent
    numIcons = opponentIconOffset;
    for iconIdx = 1, 4 do
      iconId = L.petTeamOpponentIconById(petTeamEditInfo.opponentId, iconIdx);
      if (iconId ~= nil) then
        -- Map the icon to the first that uses the texture, if required
        if (iconSpeciesMapping[iconId] ~= nil) then
          iconId = teamIcons[iconSpeciesMapping[iconId]];
        end

        -- Search for the icon in those already added
        idx = opponentIconOffset+1;
        while ((idx <= numIcons) and (teamIcons[idx] ~= iconId)) do
          idx = idx+1;
        end

        -- If the icon wasn't found...
        if (idx > numIcons) then
          -- ...add it to the list
          numIcons = numIcons+1;
          teamIcons[numIcons] = iconId;

          -- Check if the icon is the selected one for the team
          if (iconId == selectedId) then
            isOpponentIcon = true;
          end
        end
      end
    end

    -- Clear any remaining old team icons
    for idx = #teamIcons, numIcons+1, -1 do
      teamIcons[idx] = nil;
    end
  else
    -- Remove any old opponent icons
    for idx = opponentIconOffset+4, opponentIconOffset+1, -1 do
      teamIcons[idx] = nil;
    end
    numIcons = #teamIcons;
  end

  -- Work out the offset so the team's icon is visible
  if ((not isOpponentIcon) and
      (type(petTeamEditInfo.iconPathId) == "number") and
      (iconSpeciesMapping[petTeamEditInfo.iconPathId] ~= nil)) then
    offset = iconSpeciesMapping[petTeamEditInfo.iconPathId];
    offset = math.floor((offset+numIcons-opponentIconOffset-1)/ICONS_PER_ROW);
  end

  -- Make sure the team's icon is visible
  FauxScrollFrame_Update(self.scrollFrame, numRows, ICONS_NUM_ROWS,
    ICONS_ROW_HEIGHT);
  self.scrollFrame:SetVerticalScroll(ICONS_ROW_HEIGHT*
    math.min(numRows-ICONS_NUM_ROWS,
      math.max(0, offset-math.floor((ICONS_NUM_ROWS-1)/2))));

  -- Update the scroll frame
  iconDropDownUpdate(self.scrollFrame);

  return;
end

--
-- Function to update the scroll frame that displays the available icons for
-- pet teams.
--
iconDropDownUpdate = function(self)
  -- Local Variables
  local buttonTexture;
  local buttons = self:GetParent().buttons;
  local iconIdx;
  local numIcons = #teamIcons;
  local offset = FauxScrollFrame_GetOffset(self)*ICONS_PER_ROW;
  local iconPathId = petTeamEditInfo.iconPathId;

  -- Update the scroll frame's buttons
  for buttonIdx, button in ipairs(buttons) do
    iconIdx = offset+buttonIdx;
    if (iconIdx <= numIcons) then
      iconIdx = ((iconIdx-1+opponentIconOffset)%numIcons)+1;
      button.iconPathId = teamIcons[iconIdx];
      button.icon:SetTexture(L.petTeamIconGetTexture(teamIcons[iconIdx]));
      button:SetChecked(teamIcons[iconIdx] == iconPathId);
      button:Show();
    else
      button:Hide();
    end
  end

  -- Update the scroll frame's range
  FauxScrollFrame_Update(self, math.ceil(numIcons/ICONS_PER_ROW),
    ICONS_NUM_ROWS, ICONS_ROW_HEIGHT);

  return;
end

--
-- Function to initialise a button displaying a pet ability
--
local function petAbilityInitialise(button, petInfo, abilityId, abilityIdx)
  -- Local Variables
  local _;
  local abilityIcon;
  local abilityLvl;
  local isUsable;
  local numAbilities;
  local petLevel;
  local petSpeciesId;
  local speciesInfo;

  -- Initialise some variables
  petSpeciesId, _, petLevel = L.petGetInfo(petInfo.guid);
  speciesInfo  = L.petSpecies[petSpeciesId];
  numAbilities = #(speciesInfo.id);

  -- Search for the specified ability, if required
  if (abilityId ~= nil) then
    abilityIdx = 1;
    while ((abilityIdx <= numAbilities) and
           (speciesInfo.id[abilityIdx] ~= abilityId)) do
      abilityIdx = abilityIdx+1;
    end
  end

  -- Check the index of the ability is valid
  if (abilityIdx <= numAbilities) then
    abilityId  = speciesInfo.id[abilityIdx];
    abilityLvl = speciesInfo.level[abilityIdx];
  else
    return;
  end

  -- Save info for the button
  button.petInfo   = petInfo;
  button.abilityId = abilityId;

  -- Get the icon for the ability
  _, abilityIcon = C_PetJournal.GetPetAbilityInfo(abilityId);

  -- Work out if the ability is usable
  isUsable = ((type(petLevel) == "number") and (petLevel >= abilityLvl));

  -- Set any additional text for the button's tooltip
  if (not isUsable) then
    button.additionalText = format(PET_ABILITY_REQUIRES_LEVEL, abilityLvl);
  else
    button.additionalText = nil;
  end

  -- Show/Hide elements of the button
  button.icon:Show();
  button.icon:SetTexture(abilityIcon);
  button.icon:SetDesaturated(not isUsable);
  button.LevelRequirement:SetText(abilityLvl);
  button.LevelRequirement:SetShown(not isUsable);
  button.BlackCover:SetShown(not isUsable);

  return;
end

--
-- Function called when a button displaying a pet ability is clicked.
--
local function petAbilityOnClick(self, button)
  -- Local Variables
  local _;
  local abilityIcon;
  local abilityIdx;
  local abilitySelect = L.petTeamEditFrame.abilitySelect;
  local petInfo = self.petInfo;
  local petSpeciesId;
  local petLevel;
  local slotIdx = self:GetID();
  local speciesInfo;

  -- Check there is a pet for the slot
  if (self.petInfo.guid ~= nil) then
    -- Initialise some variables
    petSpeciesId, _, petLevel = L.petGetInfo(self.petInfo.guid);
    speciesInfo = L.petSpecies[petSpeciesId];

    -- Check if the click was a modified click
    if (IsModifiedClick()) then
      -- Handle the modified click
      HandleModifiedItemClick(PetJournal_GetPetAbilityHyperlink(
        self.petInfo.abilityId[self:GetID()], self.petInfo.guid));
    else
      -- Show/Hide the ability select frame
      if ((abilitySelect:IsShown()) and
          (abilitySelect.petAbilitySlot == self)) then
        abilitySelect:Hide();
        self.selected:Hide();
      else
        PetJournalPrimaryAbilityTooltip:Hide();
        abilitySelect.petAbilitySlot = self;

        -- Initialise the buttons in the ability select frame
        for buttonIdx, button in ipairs(abilitySelect.abilities) do
          abilityIdx = slotIdx+((buttonIdx-1)*3);
          petAbilityInitialise(button, petInfo, nil, abilityIdx)
          button:SetChecked(petInfo.abilityId[slotIdx] ==
            speciesInfo.id[abilityIdx]);
          button:SetEnabled(petLevel >= speciesInfo.level[abilityIdx]);
        end

        -- Position the ability select frame
        abilitySelect:Hide();
        abilitySelect:SetParent(self:GetParent());
        abilitySelect:SetPoint("TOPLEFT", self, "BOTTOMLEFT");
        abilitySelect:SetFrameLevel(self:GetFrameLevel()-1);
        abilitySelect:Show();
      end
    end
  end

  return;
end

--
-- Function called when the mouse enters a button displaying a pet ability.
-- It show the tooltip for the button's ability.
--
local function petAbilityOnEnter(self)
  -- Show the tooltip for the button's ability, if available and appropriate
  if ((self.abilityId ~= nil) and (self.petInfo.guid ~= nil)) then
    L.abilityTooltipShow(self, self.abilityId, self.petInfo.guid,
      L.petGetInfo(self.petInfo.guid), self.additionalText);
  end

  return;
end

--
-- Function called when a pet ability button is clicked
--
local function petAbilitySelectOnClick(self, button)
  -- Local Variables
  local petInfo = self.petInfo;
  local slotIdx = self:GetParent().petAbilitySlot:GetID();

  -- Check if the click was a modified click
  if (IsModifiedClick()) then
    -- Handle the modified click
    HandleModifiedItemClick(PetJournal_GetPetAbilityHyperlink(
      petInfo.abilityId[self:GetID()], petInfo.guid));
  else
    petInfo.abilityId[slotIdx] = self.abilityId;
    petTeamEditLoadoutUpdate(true);
  end

  return;
end

--
-- Function called when the pet ability select frame is hidden
--
local function petAbilitySelectOnHide(self)
  -- Check there is an ability slot associated with the frame
  if ((self.petAbilitySlot ~= nil) and
      (self.petAbilitySlot.selected ~= nil)) then
    -- Hide the selected highlight for the ability slot
    self.petAbilitySlot.selected:Hide();
  end

  return;
end

--
-- Function called when the pet ability select frame is shown
--
local function petAbilitySelectOnShow(self)
  -- Check there is an ability slot associated with the frame
  if ((self.petAbilitySlot ~= nil) and
      (self.petAbilitySlot.selected ~= nil)) then
    -- Show the selected highlight for the ability slot
    self.petAbilitySlot.selected:Show();
  end

  -- Make sure the frame is above the 'NineSlice' border
  self:SetFrameLevel(L.petTeamEditFrame.NineSlice:GetFrameLevel()+50);

  return;
end

--
-- Function called when a pet slot's drag button is clicked.  If there is
-- already a pet on the cursor, that pet is put into the corresponding
-- slot in the pet team. If there isn't, the pet in the slot is put on the
-- cursor.
--
local function petSlotDragOnClick(self, button)
  --  Local Variables
  local cursorType, petGuid = GetCursorInfo();
  local script;

  -- Check there is a battlepet on the cursor
  if (cursorType == "battlepet") then
    petTeamEditPetDrop(petGuid, self.petInfo);
    self:GetScript("OnReceiveDrag")(self);
  else
    self:GetScript("OnDragStart")(self, button);
  end

  return;
end

--
-- Function called when a drag operation starts on a pet slot
--
local function petSlotOnDragStart(self, button)
  -- Save the details of the pet to be picked up
  cursorPet.slot = self.petInfo;
  L.petTeamPetCopy(self.petInfo, cursorPet.info)

  -- Pick up the pet
  C_PetJournal.PickupPet(self.petInfo.guid);

  -- Clear the pet from the slot
  self.petInfo.guid = nil;
  petTeamEditLoadoutUpdate(true);
  BattlePetTooltip:Hide();

  return;
end

--
-- Function called when a pet slot button receives a drag operation. If there
-- is a pet on the cursor, that pet is put into the corresponding slot in the
-- pet team.
--
local function petSlotOnReceiveDrag(self)
  --  Local Variables
  local cursorType, petGuid = GetCursorInfo();

  -- Check there is a battlepet on the cursor
  if (cursorType == "battlepet") then
    petTeamEditPetDrop(petGuid, self.petInfo);
  end

  return;
end

--
-- Function called when the 'Cancel' button is clicked in the Pet Team Edit
-- panel. It simply hides the panel.
--
local function petTeamEditCancelOnClick(self, button)
  -- Hide the Pet Team Edit frame
  L.petTeamEditFrame:Hide();
  return;
end

--
-- Function called when the Icon button is clicked in the Pet Team Edit frame.
-- It toggles the displaying of the Icon dropdown.
--
local function petTeamEditIconOnClick(self)
  -- Local Variables
  local parent = self:GetParent();

  -- Check if there is anything on the cursor
  if (GetCursorInfo() ~= nil) then
    self:GetScript("OnReceiveDrag")(self);
  else
    -- Toggle the display of the Icon dropdown
    parent.iconDropDown:SetShown(not parent.iconDropDown:IsShown());
  end

  return;
end

--
-- Function called when a pet team icon receives a drag operation. If there
-- is a pet on the cursor, the pet team's icon will be set to the icon for the
-- pet's species.
--
local function petTeamEditIconOnReceiveDrag(self)
  --  Local Variables
  local _;
  local cursorType;
  local iconPathId;
  local objectId;
  local speciesId;

  -- Check there is a battlepet on the cursor
  cursorType, objectId = GetCursorInfo();
  if (cursorType == "battlepet") then
    -- Get the pet's species
    iconPathId = C_PetJournal.GetPetInfoByPetID(objectId);
    ClearCursor();
  elseif (cursorType == "mount") then
    _, _, objectId = GetCursorInfo();
    _, _, iconPathId = C_MountJournal.GetMountInfo(objectId);
  elseif (cursorType == "item") then
    iconPathId = select(10, GetItemInfo(objectId));
    ClearCursor();
  elseif (cursorType == "spell") then
    local _, spellIdx, book = GetCursorInfo();
    iconPathId = GetSpellTexture(spellIdx, book);
  end

  -- Update the pet team's icon, if required
  if (iconPathId ~= nil) then
    petTeamEditInfo.iconPathId = L.ICONFLAG_STANDARD+iconPathId;
    self.normal:SetTexture(L.petTeamIconGetTexture(petTeamEditInfo.iconPathId));
  end

  return;
end

--
-- Function called when the 'Import' button is clicked in the Pet Team Edit
-- panel.
--
local function petTeamEditImportOnClick(self, button)
  L.petTeamImport(petTeamEditInfo, L.petTeamEditFrame);
  return;
end

--
-- Function to update the load out for the pet team currently being edited
--
petTeamEditLoadoutUpdate = function(hideDropDowns)
  -- Local Variables
  local frame = L.petTeamEditFrame;
  local includeBreed = NglPtDB.settings.generalPetBreeds;
  local petAttack;
  local petAvailable;
  local petBreed;
  local petHealth;
  local petInfo;
  local petLevel;
  local petMaxHealth;
  local petPower;
  local petQtyColor;
  local petQuality;
  local petSpeciesId;
  local petSpeed;
  local selectedId;
  local selectedIdx;
  local selectedLvl;
  local speciesInfo;

  -- Check if the Pet Team Edit frame exists and is shown
  if (type(frame) == "table") then
    -- Hide all drop downs, if required
    if (hideDropDowns) then
      frame.iconDropDown:Hide();
      frame.abilitySelect:Hide();
      L.searchDropDown:Hide();
    end

    -- Update the load out for each pet in the team
    for petIdx, petSlot in pairs(frame.petSlots) do
      -- Assign info to a more convenient variable
      petInfo = petTeamEditInfo.pets[petIdx];

      -- Save the GUID of the pet in the slot
      petSlot.guid = petInfo.guid
      if (petSlot.guid ~= nil) then
        -- Get info about the pet
        petSpeciesId, petCustomName, petLevel, petHealth, petMaxHealth,
          petPower, petSpeed, petQuality, petAvailable = L.petGetInfo(
          petInfo.guid);
        speciesInfo = L.petSpecies[petSpeciesId];

        -- Work out the colour for the pet's quality
        if ((type(petQuality) == "number") and
            (ITEM_QUALITY_COLORS[petQuality-1] ~= nil)) then
          petQtyColor = ITEM_QUALITY_COLORS[petQuality-1];
        else
          petQtyColor = ITEM_QUALITY_COLORS[1];
        end

        -- Set the pet's icon
        petSlot.icon:SetTexture(speciesInfo.icon);
        petSlot.icon:Show();
        petSlot.iconBorder:Show();
        petSlot.qualityBorder:SetVertexColor(petQtyColor.r, petQtyColor.g,
          petQtyColor.b);
        petSlot.qualityBorder:Show();

        -- Set the pet's type
        if (speciesInfo.type ~= nil) then
          petSlot.petTypeIcon:SetTexture(GetPetTypeTexture(speciesInfo.type));
          petSlot.petTypeIcon:Show();
        else
          petSlot.petTypeIcon:Hide();
        end

        -- Set the pet's level
        if (type(petLevel) == "number") then
          petSlot.level:SetText(petLevel);
          petSlot.level:Show();
          petSlot.levelBG:Show();
        else
          petSlot.level:Hide();
          petSlot.levelBG:Hide();
        end

        -- Show/Hide the favourite icon
        petSlot.favorite:SetShown(C_PetJournal.PetIsFavorite(petInfo.guid));
        petSlot.isDead:SetShown(petHealth == 0);

        -- Set the pet's name and/or sub-name
        petBreed = (includeBreed and " "..L.petGetBreed(petInfo.guid) or "");
        if (petCustomName ~= nil) then
          petSlot.name:SetHeight(12);
          petSlot.name:SetWordWrap(false);
          petSlot.name:SetText(petCustomName..petBreed);
          petSlot.subName:SetText(speciesInfo.name);
        elseif (speciesInfo.name ~= nil) then
          petSlot.name:SetHeight(28);
          petSlot.name:SetWordWrap(true);
          petSlot.name:SetText(speciesInfo.name..petBreed);
        end
        petSlot.name:SetShown(speciesInfo.name ~= nil);
        petSlot.subName:SetShown(petCustomName ~= nil);

        -- Set the pet's stats
        petSlot.health.label:SetFormattedText("%d/%d", petHealth, petMaxHealth);
        petSlot.health.bar:SetMinMaxValues(0, petMaxHealth);
        petSlot.health.bar:SetValue(petHealth);
        petSlot.health:Show();
        petSlot.power.label:SetText(petPower);
        petSlot.power:Show();
        petSlot.speed.label:SetText(petSpeed);
        petSlot.speed:Show();
        petSlot.quality.label:SetVertexColor(petQtyColor.r, petQtyColor.g,
          petQtyColor.b);
        petSlot.quality.label:SetText(
          _G["BATTLE_PET_BREED_QUALITY"..petQuality]);
        petSlot.quality:Show();

        -- Set the pet's selected abilities
        for abilityIdx, abilitySlot in ipairs(petSlot.abilitySlots) do
          -- Work out which ability is selected for this ability slot
          if ((speciesInfo.id[abilityIdx+L.NUM_ACTIVE_ABILITIES] ==
                petInfo.abilityId[abilityIdx]) and
              (speciesInfo.level[abilityIdx+L.NUM_ACTIVE_ABILITIES] <=
                petLevel)) then
            selectedIdx = abilityIdx+L.NUM_ACTIVE_ABILITIES;
          else
            selectedIdx = abilityIdx;
          end
          selectedId  = speciesInfo.id[selectedIdx];
          selectedLvl = speciesInfo.level[selectedIdx];

          -- Make sure the pet has a valid ability selected
          if (petInfo.abilityId[abilityIdx] ~= selectedId) then
            petInfo.abilityId[abilityIdx] = selectedId;
          end

          -- Initialise the ability button
          petAbilityInitialise(abilitySlot, petInfo, selectedId);
          abilitySlot.selected:Hide();
          abilitySlot.FlyoutArrow:Show();
          abilitySlot:SetEnabled(petAvailable);
        end

        -- Show/hide the missing frame
        petSlot.missing:SetShown(not petAvailable);
      else
        -- Hide the elements that display info about the pet
        petSlot.icon:Hide();
        petSlot.iconBorder:Hide();
        petSlot.qualityBorder:Hide();
        petSlot.petTypeIcon:Hide();
        petSlot.name:Hide();
        petSlot.subName:Hide();
        petSlot.isDead:Hide();
        petSlot.levelBG:Hide();
        petSlot.level:Hide();
        petSlot.favorite:Hide();
        petSlot.health:Hide();
        petSlot.power:Hide();
        petSlot.speed:Hide();
        petSlot.quality:Hide();
        petSlot.missing:Hide();
        for _, abilitySlot in ipairs(petSlot.abilitySlots) do
          abilitySlot.icon:Hide();
          abilitySlot.LevelRequirement:Hide();
          abilitySlot.selected:Hide();
          abilitySlot.FlyoutArrow:Hide();
          abilitySlot.BlackCover:Hide();
        end
      end
    end

    -- Enable/disable buttons based on the pet team's state
    petTeamEditEnable();
  end

  return;
end

--
-- Function to process events for the Pet Team Edit frame
--
local function petTeamEditOnEvent(self, event, ...)
  -- Process the event
  if ((event == "PET_JOURNAL_LIST_UPDATE") or
      (event == "PET_JOURNAL_PET_DELETED") or
      (event == "PET_JOURNAL_PETS_HEALED") or
      (event == "PET_BATTLE_LEVEL_CHANGED") or
      (event == "COMPANION_UPDATE")) then
    -- Update the pet team load out
    petTeamEditLoadoutUpdate(false);
  elseif (event == "BATTLE_PET_CURSOR_CLEAR") then
    cursorPet.slot = nil;
  end

  return;
end

--
-- Function called when the Pet Team Edit frame is shown/hidden
--
local function petTeamEditOnShowHide(self)
  -- Local Variables
  local eventFunc =
    (self:IsShown() and self.RegisterEvent or self.UnregisterEvent);

  -- (Un)register events
  eventFunc(self, "PET_JOURNAL_LIST_UPDATE");
  eventFunc(self, "PET_JOURNAL_PET_DELETED");
  eventFunc(self, "PET_JOURNAL_PETS_HEALED");
  eventFunc(self, "PET_BATTLE_LEVEL_CHANGED");
  eventFunc(self, "COMPANION_UPDATE");
  eventFunc(self, "BATTLE_PET_CURSOR_CLEAR");

  -- Hide any drop downs or popups
  self.iconDropDown:Hide();
  self.abilitySelect:Hide();
  L.searchDropDown:Hide();
  L.petReplacementsHide();
  L.petTeamSendHide();
  StaticPopup_Hide("NIGGLES_PETTEAMS_WARNING");

  -- Do any processing that is dependant on the frame's state
  if (self:IsShown()) then
    -- Hide the Strategy frame
    L.petTeamStrategyHide();

    -- Show/hide the help plates, if required
    if (HelpPlate.IsShowingHelpInfo(PetJournal_HelpPlate)) then
      HelpPlate.Hide(false);
    end
    if ((NglPtDB.settings.generalShowTutorials) and
        (bit.band(NglPtDB.tutorialSeen, L.TUTORIALSEENFLAG_TEAMEDIT) == 0)) then
      HelpPlate.Show(tutorialPlateInfo, L.petTeamEditFrame,
        L.petTeamEditFrame.tutorialButton, true);
      NglPtDB.tutorialSeen = bit.bor(NglPtDB.tutorialSeen,
        L.TUTORIALSEENFLAG_TEAMEDIT);
    end
  else
    -- Hide the help plates, if required
    if (HelpPlate.IsShowingHelpInfo(tutorialPlateInfo)) then
      HelpPlate.Hide(false);
      NglPtDB.tutorialSeen = bit.bor(NglPtDB.tutorialSeen,
        L.TUTORIALSEENFLAG_TEAMEDIT);
    end
  end

  -- Play the appropriate sound
  PlaySound(self:IsShown() and SOUNDKIT.IG_CHARACTER_INFO_OPEN or
    SOUNDKIT.IG_CHARACTER_INFO_CLOSE);

  return;
end

--
-- Function to drop the pet on the cursor into a slot in a pet team
--
petTeamEditPetDrop = function(petGuid, petInfo)
  -- Check the pet can battle
  if (select(15, C_PetJournal.GetPetInfoByPetID(petGuid))) then
    -- Check if the pet is in another slot
    for _, currentInfo in ipairs(petTeamEditInfo.pets) do
      if ((currentInfo.guid == petGuid) and (currentInfo ~= petInfo)) then
        cursorPet.slot = currentInfo;
        break;
      end
    end

    -- Move the slot's current pet to the cursor pet's old slot, if required
    if ((cursorPet.slot ~= nil) and (petInfo.guid ~= nil)) then
      L.petTeamEditSetSlotPet(cursorPet.slot, petInfo.guid, petInfo.abilityId);
    end

    -- Put the pet into the specified slot
    if (cursorPet.info.guid == petGuid) then
      L.petTeamEditSetSlotPet(petInfo, petGuid, cursorPet.info.abilityId, true);
    else
      L.petTeamEditSetSlotPet(petInfo, petGuid, nil, true);
    end
  end

  -- Clear the pet from the cursor
  ClearCursor();

  return;
end

--
-- Function called when the 'Preview' button is clicked in the Pet Team Edit
-- panel. It displays a preview of strategy in the panel used during actual
-- pet battles.
--
local function petTeamEditPreviewOnClick(self, button)
  -- Local Variables
  local frame;

  -- Play the appropriate sound, if required
  if (L.petTeamStrategyIsShown()) then
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
  end

  -- Show the Strategy panel
  petTeamEditInfo.strategy = L.petTeamEditFrame.strategy:GetText();
  petTeamEditInfo.isHtml   = L.petTeamEditFrame.strategy:GetIsHtml();
  L.petTeamStrategyShow(L.petTeamEditFrame, "preview", petTeamEditInfo, false);

  return;
end

--
-- Function to save the pet team currently being edited.
--
local function petTeamEditSave()
  -- Local Variables
  local teamInfo;

  -- Save the pet team
  teamInfo = L.petTeamSave(petTeamEditInfo,
    L.petTeamEditFrame.strategy:GetText(), petTeamEditInfo.team);

  -- Hide the Pet Team Edit frame
  L.petTeamEditFrame:Hide();

  -- Update the Pet Teams list
  L.petTeamsSort();
  L.petTeamsFilter(false);

  -- Load the team, if possible
  if ((not C_PetBattles.IsInBattle()) and
      (C_PetJournal.IsFindBattleEnabled()) and
      (C_PetJournal.IsJournalUnlocked())) then
    L.petTeamLoad(teamInfo);
  end

  return;
end

--
-- Function called when the 'Save' button is clicked in the Pet Team Edit panel.
-- It saves the pet team to the addon's saved variables.
--
local function petTeamEditSaveOnClick(self, button)
  -- Local Variables
  local teamInfo = petTeamEditInfo.team;
  local petTeams = NglPtDB.petTeams;

  -- Check if there is an identical pet team to the edited one
  if (L.petTeamsHaveIdentical(petTeamEditInfo, teamInfo)) then
    StaticPopup_Show("NIGGLES_PETTEAMS_IDENTICAL");
  else
    petTeamEditSave();
  end

  return;
end

--
-- Function called when a button is clicked in the Opponent drop down
--
local function opponentDropDownButtonOnClick(button, userData)
  -- Local Variables
  local iconId;
  local oldOpponentId = petTeamEditInfo.opponentId;

  -- Check the opponent ID has changed
  if (button.opponentId ~= petTeamEditInfo.opponentId) then
    -- Save the new opponent ID for the pet team
    petTeamEditInfo.opponentId = button.opponentId;

    -- Set the pet team's icon to the default for the new opponent
    iconId = L.petTeamOpponentIconById(button.opponentId, 1);
    if ((iconId > 0) and (iconId <= L.petSpeciesMaxId)) then
      petTeamEditInfo.iconPathId = teamIcons[iconSpeciesMapping[iconId]];
    else
      petTeamEditInfo.iconPathId = iconId;
    end
    
    -- Update the opponent displayed for the pet team
    L.petTeamEditFrame.opponent:SetText(
      L.petTeamOpponentById(petTeamEditInfo.opponentId));

    -- Update the displayed icon for the pet team
    L.petTeamEditFrame.icon.normal:SetTexture(
      L.petTeamIconGetTexture(petTeamEditInfo.iconPathId));
  end

  -- Enable/disable buttons based on the pet team's state
  petTeamEditEnable();

  return;
end

--
-- Function called when a button is entered in the Opponent dropdown list.
--
local function opponentDropDownButtonOnEnter(button, userData)
  -- Display a tooltip for the button, if required
  if (button:GetFontString():IsTruncated()) then
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:ClearLines();
    GameTooltip:SetMinimumWidth(150, true);
    GameTooltip:AddLine(button:GetText(), 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end

  return;
end

--
-- Function to update the list in the Opponent dropdown
--
local function opponentDropDownListUpdate(scrollFrame)
  -- Local Variables
  local numOpponents = opponentFiltered[0];
  local offset;
  local opponentIdx;
  local owner;
  local selectedOpponent = petTeamEditInfo.opponentId;

  -- Initialise some variable
  offset = HybridScrollFrame_GetOffset(scrollFrame);

  -- Update the buttons in the scroll frame
  for buttonIdx, button in ipairs(scrollFrame.buttons) do
    -- Work out which opponent the button is for
    opponentIdx = buttonIdx+offset;
    if (opponentIdx <= numOpponents) then
      button.opponentId = opponentFiltered[opponentIdx];
      button:SetText(L.petTeamOpponentById(opponentFiltered[opponentIdx]));
      button:Enable();
      button:Show();
      if (opponentFiltered[opponentIdx] == selectedOpponent) then
        button:LockHighlight();
      else
        button:UnlockHighlight();
      end
    else
      button:Hide();
    end
  end

  -- Update the scroll frame's range
  HybridScrollFrame_Update(scrollFrame,
    numOpponents*scrollFrame.buttons[1]:GetHeight(), scrollFrame:GetHeight());

  -- Hide the game tooltip, if required
  owner = GameTooltip:GetOwner();
  if ((GameTooltip:IsVisible()) and
      (owner ~= nil) and
      (owner:GetParent() ~= nil) and
      (owner:GetParent():GetParent() == scrollFrame)) then
    GameTooltip_Hide();
  end

  return;
end

--
-- Function called when the Opponent button is clicked
--
local function opponentDropDownOnClick(self, mouseButton)
  -- Show/hide the search drop down for the opponent
  if ((L.searchDropDown:GetParent() ~= self) or
      (not L.searchDropDown:IsShown())) then
    L.searchDropDown:SetParent(self);
    L.searchDropDown:SetCallbacks(opponentDropDownListUpdate,
      opponentDropDownButtonOnEnter, opponentDropDownButtonOnClick,
      opponentDropDownOnTextChanged, petTeamEditInfo.opponentId);
    L.searchDropDown:Show();
  else
    L.searchDropDown:Hide();
  end

  return;
end

--
-- Function called when the text changes in the search box in the Opponent
-- dropdown. It filters the opponents listed in the scroll frame.
--
opponentDropDownOnTextChanged = function(searchText, userData)
  -- Local variables
  local numFiltered = 0;
  local numOpponents = L.petTeamOpponentCount();
  local opponentId;
  local opponentName;
  local selectedIdx = 1;

  -- Check if the search text is blank
  if (searchText == "") then
    -- Add all teams to the filtered list
    for idx = 1, numOpponents do
      opponentFiltered[idx] = L.petTeamOpponentByIndex(idx);
      if (opponentFiltered[idx] == userData) then
        selectedIdx = idx;
      end
    end
    opponentFiltered[0] = numOpponents;
  else
    -- Add all opponents that match the search text to the filtered list
    for idx = 1, numOpponents do
      opponentId, opponentName = L.petTeamOpponentByIndex(idx);
      if ((opponentId > 0) and
          (string.find(string.lower(opponentName), searchText,
            1, true) ~= nil)) then
        -- Add the opponent to the filtered list
        numFiltered = numFiltered+1;
        opponentFiltered[numFiltered] = opponentId;

        -- Check if the opponent is the one currently selected
        if (opponentId == userData) then
          selectedIdx = numFiltered;
        end
      end
    end
    opponentFiltered[0] = numFiltered;
  end

  return selectedIdx;
end

--
-- Function called when the alert symbol is clicked in a 'Missing' button
--
local function petMissingOnClick(self, mouseButton)
  -- Local Variables
  local petInfo;
  local parent = self:GetParent();
  local petSlotIdx;

  -- Initialise some variables
  petInfo    = parent.petInfo;
  petSlotIdx = parent:GetID();

  -- Try to find a replacement pet for the missing one
  L.petReplace(petInfo,
    petTeamEditInfo.pets[petSlotIdx == 1 and 2 or 1].guid,
    petTeamEditInfo.pets[petSlotIdx == 3 and 2 or 3].guid)

  return;
end

--
-- Function called when the mouse enters the alert symbol in a 'Missing' button
--
local function petMissingOnEnter(self)
  -- Display the tooltip for the button
  GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT");
  GameTooltip:SetText(L["PetMissing"]);
  GameTooltip:Show();

  return;
end

--
-- Function to create and initialise the Pet Team edit frame
--
local function petTeamEditCreate()
  -- Local Variables
  local frame;
  local panelLevel
  local child;

  -- Create the Pet Team Edit frame
  frame = CreateFrame("Frame", "NigglesPetTeamEdit", NigglesPetTeams,
    "NigglesPetTeamEditTemplate");
  L.petTeamEditFrame = frame;

  -- Initialise the pet team info for the Pet Team Edit frame
  petTeamEditInfo = L.petTeamCopy(nil, nil);
  frame.teamInfo  = petTeamEditInfo;

  -- Adjust the position of the background to hide a gap
  frame.Bg:SetPoint("TOPLEFT", 1, -21);

  -- Set the frame's portrait
  SetPortraitToTexture(frame.PortraitContainer.portrait,
    "Interface\\Icons\\PetJournalPortrait");

  -- Initialise each pet slot in the frame
  panelLevel = frame:GetFrameLevel();
  for petIdx, petSlot in ipairs(frame.petSlots) do
    -- Set the slot info for the frame and its drag button
    petSlot.petInfo      = petTeamEditInfo.pets[petIdx];
    petSlot.drag.petInfo = petSlot.petInfo;

    -- Set the script handlers for the frame
    petSlot:SetScript("OnClick", petSlotOnReceiveDrag);
    petSlot:SetScript("OnReceiveDrag", petSlotOnReceiveDrag);

    -- Set the script handlers for the frame's drag button
    petSlot.drag:SetScript("OnClick", petSlotDragOnClick);
    petSlot.drag:SetScript("OnDragStart", petSlotOnDragStart);
    petSlot.drag:SetScript("OnReceiveDrag", petSlotOnReceiveDrag);
    petSlot.drag:RegisterForDrag("LeftButton");

    -- Initialise the pet's ability buttons
    for _, button in ipairs(petSlot.abilitySlots) do
      button.petInfo = petSlot.petInfo;
      button:SetScript("OnClick", petAbilityOnClick);
      button:SetScript("OnEnter", petAbilityOnEnter);
      button:SetFrameLevel(panelLevel+3);
    end

    -- Set the level of the missing frame
    petSlot.missing:SetFrameLevel(panelLevel+4);
    petSlot.missing:SetScript("OnClick", petMissingOnClick);
    petSlot.missing:SetScript("OnEnter", petMissingOnEnter);
  end
  frame.loadOutBorderTitle:SetFrameLevel(panelLevel+4);

  -- Hook script handlers
  frame.teamName:HookScript("OnTextChanged",
    function(frame)
      petTeamEditInfo.name = strtrim(frame:GetText());
      petTeamEditEnable();
      return;
    end);
  frame.dragButton:HookScript("OnMouseUp",
    function(frame)
      L.layoutSave("edit", frame:GetParent(), false);
      return;
    end);

  -- Initialise the tutorial button
  child = frame.tutorialButton;
  child:SetFrameLevel(frame.TitleContainer:GetFrameLevel()+1);
  child:SetScript("OnClick", tutorialOnClick);

  -- Initialise the ability select menu
  child = frame.abilitySelect;
  child:HookScript("OnHide", petAbilitySelectOnHide);
  child:HookScript("OnShow", petAbilitySelectOnShow);
  for _, button in ipairs(child.abilities) do
    button:SetScript("OnClick", petAbilitySelectOnClick);
    button:SetScript("OnEnter", petAbilityOnEnter);
  end

  -- Initialise the pet team name editbox
  frame.teamName:SetMaxLetters(L.MAX_TEAM_NAME_LEN);

  -- Initialise the pet team icon
  child = frame.icon;
  child:SetScript("OnClick", petTeamEditIconOnClick);
  child:SetScript("OnReceiveDrag", petTeamEditIconOnReceiveDrag);
  child:RegisterForDrag("LeftButton");

  -- Initialise the icon dropdown
  child = frame.iconDropDown;
  L.frameSetBorderColor(child, TOOLTIP_DEFAULT_COLOR.r,
    TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
  child:HookScript("OnShow", iconDropDownOnShow);
  child.scrollFrame:SetScript("OnVerticalScroll", iconDropDownOnScroll);
  child.scrollFrame.ScrollBar.doNotHide = true;

  -- Initialise the opponent button
  frame.opponent:SetScript("OnClick", opponentDropDownOnClick);

  -- Set labels
  frame.detailsLabel:SetText(L["Details"]);
  frame.opponent.label:SetText(L["Opponent"]..":");
  frame.teamName.label:SetText(L["Name"]..":");
  frame.strategyLabel:SetText(L["Strategy"]);
  frame.import:SetText(L["Import"]);

  -- Set script handlers for the Save. Cancel and Preview buttons
  frame.save:SetScript("OnClick", petTeamEditSaveOnClick);
  frame.cancel:SetScript("OnClick", petTeamEditCancelOnClick);
  frame.import:SetScript("OnClick", petTeamEditImportOnClick);
  frame.preview:SetScript("OnClick", petTeamEditPreviewOnClick);

  -- Set script handlers for the frame
  frame:SetScript("OnEvent", petTeamEditOnEvent);
  frame:SetScript("OnHide", petTeamEditOnShowHide);
  frame:SetScript("OnShow", petTeamEditOnShowHide);

  -- Hook into some Pet Journal script handlers
  PetJournalTutorialButton:HookScript("OnClick", tutorialPetJournalOnClick);

  return;
end

--
-- Function to enable/disable frames in the Pet Teams Edit panel, based on the
-- team's current state
--
petTeamEditEnable = function()
  -- Local Variables
  local enabled = false;
  local petInfo;

  -- Check the team has at least one pet
  for _, petInfo in ipairs(petTeamEditInfo.pets) do
    if (petInfo.guid ~= nil) then
      enabled = true;
      break;
    end
  end

  -- Check the team has a name
  enabled = enabled and ((petTeamEditInfo.name ~= "") or
    (petTeamEditInfo.opponentId ~= 0));

  -- Enable/disable buttons
  L.petTeamEditFrame.save:SetEnabled(enabled);

  return;
end

--
-- Function called when the tutorial button is clicked. It toggles the display
-- of the tutorial plates.
--
tutorialOnClick = function(self, mouseButton)
  -- Hide any frames that might appear under the tutorial plates
  L.petTeamImportExportHide();

  -- Show/hide the tutorial plates
  if (not HelpPlate.IsShowingHelpInfo(tutorialPlateInfo)) then
    -- Show the tutorial plates
    HelpPlate.Show(tutorialPlateInfo, L.petTeamEditFrame, self, true);

    -- Set the flag that indicates the tutorial has been seen
    NglPtDB.tutorialSeen = bit.bor(NglPtDB.tutorialSeen,
      L.TUTORIALSEENFLAG_TEAMEDIT);
  else
    HelpPlate.Hide(true);
  end

  return;
end

--
-- Function hooked into the 'OnClick' handler for the tutorial button on the
-- Pet Journal. It hides the Pet Team Edit frame if the help plates are shown.
--
tutorialPetJournalOnClick = function(self, mouseButton)
  -- Check if the Pet Journal's help plates are being shown
  if (HelpPlate.IsShowingHelpInfo(PetJournal_HelpPlate)) then
    -- Hide the Pet Team Edit frame
    L.petTeamEditFrame:Hide();
  end

  return;
end

-------------------------------------------------------------------------------
--                 A  D  D  O  N     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to show the panel used to edit a pet team
--
function L.petTeamEdit(teamInfo, initialInfo)
  -- Local Variables
  local _;
  local abilityId = {};
  local frame;
  local petGuid;
  local targetIconId;
  local targetId;
  local targetName;

  -- Create the Pet Team Edit panel, if required
  if (type(L.petTeamEditFrame) ~= "table") then
    petTeamEditCreate();
  end
  frame = L.petTeamEditFrame;

  -- Ensure child panels are hidden
  L.petTeamStrategyHide();
  L.petTeamImportExportHide();

  -- Set the frame's title
  frame.TitleContainer.TitleText:SetText(
    teamInfo == nil and L["PetTeamCreate"] or L["PetTeamEdit"]);

  -- Copy the info the pet team being edited
  petTeamEditInfo.team = teamInfo;
  L.petTeamCopy((teamInfo ~= nil and teamInfo or initialInfo),
    petTeamEditInfo);

  -- Check if a new team is being created
  if ((teamInfo == nil) and (initialInfo == nil)) then
    -- Initialise the team's pets to the current load out
    for petIdx, petInfo in ipairs(petTeamEditInfo.pets) do
      petGuid, petInfo.abilityId[1], petInfo.abilityId[2],
        petInfo.abilityId[3] = C_PetJournal.GetPetLoadOutInfo(petIdx);
      L.petTeamEditSetSlotPet(petInfo, petGuid);
    end

    -- Check if the current target is a known opponent
    targetName = UnitName("target");
    targetId   = tonumber(string.match((UnitGUID("target") or ""),
       "[^-]+-[^-]+-[^-]+-[^-]+-[^-]+-([^-]+)-"));
    targetIconId = L.petTeamOpponentIconById(targetId, 1);
    if (targetIconId ~= nil) then
      _, petTeamEditInfo.opponentId = L.petTeamOpponentById(targetId);
      if (targetIconId <= L.petSpeciesMaxId) then
        petTeamEditInfo.iconPathId =
          teamIcons[iconSpeciesMapping[targetIconId]];
      else
        petTeamEditInfo.iconPathId = targetIconId;
      end
    -- Check if there is a target
    elseif ((NglPtDB.settings.generalTargetTeamName) and
            (targetName ~= nil) and (targetName ~= "")) then
      petTeamEditInfo.name = targetName;
    end
  end

  -- Update the pet team displayed by the frame
  L.petTeamEditUpdate();

  -- Show the panel
  L.layoutRestore("edit", frame, false);
  frame:Show();

  return;
end

--
-- Function to hide the 'Create/Edit Pet Team' panel, if it exists
--
function L.petTeamEditFrameHide()
  -- Hide the panel, if it exists
  if (type(L.petTeamEditFrame) == "table") then
    L.petTeamEditFrame:Hide();
  end

  return;
end

--
-- Function to set the pet in a pet team slot
--
function L.petTeamEditSetSlotPet(petInfo, petGuid, abilityIds, updateLoadout)
  -- Local Variables
  local _;
  local abilitiesSet = false;
  local cpj = C_PetJournal;
  local isLocked;
  local petSpeciesId = L.petGetInfo(petGuid);
  local slotPetGuid;
  local speciesInfo;

  -- Save the pet's GUID
  petInfo.guid = petGuid;
  L.petSaveInfo(petGuid);

  -- Use any abilities specified for the pet
  if (type(abilityIds) == "table") then
    for abilityIdx = 1, L.NUM_ACTIVE_ABILITIES do
      petInfo.abilityId[abilityIdx] = abilityIds[abilityIdx];
    end
    abilitiesSet = true;
  end

  -- Get the pet's active abilities, if it is already loaded
  if ((not abilitiesSet) and (cpj.PetIsSlotted(petGuid))) then
    for slotIdx = L.MAX_ACTIVE_PETS, 1, -1 do
      slotPetGuid = cpj.GetPetLoadOutInfo(slotIdx);
      if (slotPetGuid == petGuid) then
        _, petInfo.abilityId[1], petInfo.abilityId[2], petInfo.abilityId[3] =
          cpj.GetPetLoadOutInfo(slotIdx);
        abilitiesSet = true;
        break;
      end
    end
  end

  -- Try to load the pet to get its active abilities, if not already loaded
  if ((not abilitiesSet) and (not C_PetBattles.IsInBattle())) then
    for slotIdx = L.MAX_ACTIVE_PETS, 1, -1 do
      -- Get the pet currently in the slot
      slotPetGuid, _, _, _, isLocked = cpj.GetPetLoadOutInfo(slotIdx);
      if (not isLocked) then
        -- Try to load the pet into the slot
        cpj.SetPetLoadOutInfo(slotIdx, petGuid);
        if (cpj.GetPetLoadOutInfo(slotIdx) == petGuid) then
          -- Get the pet's active abilities
          _, petInfo.abilityId[1], petInfo.abilityId[2], petInfo.abilityId[3] =
            cpj.GetPetLoadOutInfo(slotIdx);

          -- Put the pet that was in the slot back
          cpj.SetPetLoadOutInfo(slotIdx, slotPetGuid);
          abilitiesSet = true;
          break;
        end
      end
    end
  end

  -- If the pet's active abilities can't be obtained...
  if (not abilitiesSet) then
    -- ...use the first ability in each slot
    speciesInfo = L.petSpecies[petSpeciesId];
    for abilityIdx = 1, L.NUM_ACTIVE_ABILITIES do
      petInfo.abilityId[abilityIdx] = speciesInfo.id[abilityIdx];
    end
  end

  -- Update the loadout, if required
  if (updateLoadout == true) then
    petTeamEditLoadoutUpdate();
  end

  return;
end

--
-- Function to update the pet team displayed by the Pet Team Edit frame
--
function L.petTeamEditUpdate()
  -- Local Variables
  local frame = L.petTeamEditFrame;

  -- Initialise the panel's frames
  frame.teamName:SetText(petTeamEditInfo.name);
  frame.teamName:SetCursorPosition(0);
  frame.teamName:SetFocus();
  frame.opponent:SetText(
    L.petTeamOpponentById(petTeamEditInfo.opponentId) or "");
  frame.icon.normal:SetTexture(
    L.petTeamIconGetTexture(petTeamEditInfo.iconPathId));
  frame.strategy:SetText(petTeamEditInfo.strategy);
  frame.strategy:SetIsHtml(petTeamEditInfo.isHtml);
  petTeamEditLoadoutUpdate(true);

  return;
end

--
-- Function to get the texture for a pet team icon
--
function L.petTeamIconGetTexture(iconPathId)
  -- Local Variables
  local _;
  local texture;
  local cpjGetPetInfoBySpeciesID = C_PetJournal.GetPetInfoBySpeciesID;

  -- Initialise the list of team icons, if required
  if (next(teamIcons) == nil) then
    -- Local Variables
    local alreadyKnown = {};
    local numIcons = 1;
    local speciesIcon;
    local speciesName;

    -- Add the initial icon to the list
    teamIcons[1] = 0;

    --  Add the IDs for the pet species that can be found in specified ranges
    for _, range in ipairs(L.petSpeciesRanges) do
      for speciesId = range[1],  range[2] do
        speciesName, speciesIcon = cpjGetPetInfoBySpeciesID(speciesId);
        if ((type(speciesName) == "string") and
            (type(speciesIcon) == "number")) then
          if (alreadyKnown[speciesIcon] == nil) then
            -- Add the species ID to the list of team icons
            numIcons = numIcons+1;
            teamIcons[numIcons] = speciesId;
            alreadyKnown[speciesIcon] = numIcons;

            -- Save the icon's ID for the species
            iconSpeciesMapping[speciesId] = numIcons;
          else
            -- Use the icon ID of the first use of the texture
            iconSpeciesMapping[speciesId] = alreadyKnown[speciesIcon];
          end
        end
      end
    end
    opponentIconOffset = numIcons;

    -- Clean up
    alreadyKnown = nil;
    collectgarbage("collect");
  end

  -- Get the texture for the icon
  if (type(iconPathId) == "number") then
    if (bit.band(iconPathId, L.ICONFLAG_MASK) == L.ICONFLAG_STANDARD) then
      texture = iconPathId-L.ICONFLAG_STANDARD;
    elseif (iconPathId == 0) then
      texture = PET_BATTLE_ICON;
    elseif ((iconPathId > 0) and (iconPathId <= L.petSpeciesMaxId)) then
      _, texture = cpjGetPetInfoBySpeciesID(iconPathId);
    else
      texture = (L.opponentGetIconPath(iconPathId) or iconPathId);
    end
  elseif (type(iconPathId) == "string") then
    texture = iconPathId;
  end

  return texture or PET_BATTLE_ICON;
end

--
-- Function called when the settings change
--
function L.petTeamEditSettingsUpdate()
  -- Update the load out, if required
  if (L.petTeamEditFrame ~= nil) then
    petTeamEditLoadoutUpdate(false);
  end

  return;
end

-------------------------------------------------------------------------------
--                    S  T  A  T  I  C     P  O  P  U  P  S
-------------------------------------------------------------------------------

StaticPopupDialogs["NIGGLES_PETTEAMS_IDENTICAL"] =
{
  text           = L["ConfirmPetTeamSave"],
  button1        = YES,
  button2        = NO,
  whileDead      = 1,
  OnAccept       = petTeamEditSave,
  showAlert      = 1,
  timeout        = 0,
  exclusive      = 1,
  hideOnEscape   = 1,
  preferredIndex = STATICPOPUP_NUMDIALOGS,
};
