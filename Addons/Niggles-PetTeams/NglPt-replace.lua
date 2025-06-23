-------------------------------------------------------------------------------
--               G  L  O  B  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                 L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

local petFlagSettings =
{
  [LE_PET_JOURNAL_FILTER_COLLECTED]     = true,
  [LE_PET_JOURNAL_FILTER_NOT_COLLECTED] = false
};

local petFilters =
{
  flags   = {},
  types   = {},
  sources = {},
  search  = ""
};

local petSpeciesGenus = {};

local petReplacements = setmetatable({[0] = 0},
{
  __index = function(table, key)
    table[key] = {};
    return table[key];
  end
});

local petReplacementsFrame;

-------------------------------------------------------------------------------
--              L  O  C  A  L     D  E  F  I  N  I  T  I  O  N  S
-------------------------------------------------------------------------------

local petReplacementsListUpdate;

-------------------------------------------------------------------------------
--                 L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to add the delta to the values displayed by the BattlePetTooltip
--
local function battlePetTooltipAddDelta(element, delta)
  -- Check there is a difference between the new and old values
  if (delta ~= 0) then
    -- Update the text of the tooltip's element
    BattlePetTooltip[element]:SetText(format("%s %s(%+d)|r",
      BattlePetTooltip[element]:GetText(),
      (delta > 0 and GREEN_FONT_COLOR_CODE or RED_FONT_COLOR_CODE), delta));
  end

  return;
end

--
-- Function called when a pet replacement button is clicked
--
local function petReplacementOnClick(self, mouseButton)
  -- Put the replacement pet into the specified slot in the pet team
  L.petTeamEditSetSlotPet(petReplacementsFrame.petInfo, self.petGuid,
    petReplacementsFrame.petInfo.abilityId, true);

  -- Hide the Pet Replacements frame
  petReplacementsFrame:Hide();

  return;
end

--
-- Function called when a drag operation starts on a pet replacement button
--
local function petReplacementOnDragStart(self)
  -- Check the character isn't in combat
  if (not UnitAffectingCombat("player")) then
    -- Pick up the pet
    C_PetJournal.PickupPet(self:GetParent().petGuid);
  end

  return;
end

--
-- Function called when the mouse enters the drag button for a button in the
-- Pets Replacements list
--
local function petReplacementOnEnter(self)
  -- Local Variables
  local petGuid = self:GetParent().petGuid;

  -- Check the button has a pet GUID assigned to it
  if (petGuid ~= nil) then
    -- Get the pet's info
    local petSpeciesId, _, petLevel, _, _, _, _, petSpeciesName =
      C_PetJournal.GetPetInfoByPetID(petGuid)
    local _, petMaxHealth, petPower, petSpeed, petQuality =
      C_PetJournal.GetPetStats(petGuid);

    -- Position the Game tooltip for use by the Battle Pet tooltip
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    -- Display the Battle Pet tooltip
    BattlePetToolTip_Show(petSpeciesId, petLevel, petQuality-1, petMaxHealth,
      petPower, petSpeed, petSpeciesName);

    -- Update the Battle Pet tooltip with the delta for the values
    local _, _, origLevel, _, origMaxHealth, origPower, origSpeed =
      L.petGetInfo(NigglesPetTeamReplacements.petInfo.guid);
    battlePetTooltipAddDelta("Level",  petLevel-origLevel);
    battlePetTooltipAddDelta("Health", petMaxHealth-origMaxHealth);
    battlePetTooltipAddDelta("Power",  petPower-origPower);
    battlePetTooltipAddDelta("Speed",  petSpeed-origSpeed);
  end

  return;
end

--
-- Function to display the list of possible pet replacements
--
local function petReplacementsDisplay(petInfo)
  -- Local Variables
  local child;
  local frame = petReplacementsFrame;

  -- Create the Pet Replacement frame, if required
  if (frame == nil) then
    -- Create the frame
    frame = CreateFrame("Frame", "NigglesPetTeamReplacements",
      L.petTeamEditFrame, "NigglesPetTeamReplacementsTemplate");
    petReplacementsFrame = frame;

    -- Set the frame's portrait and title
    SetPortraitToTexture(frame.PortraitContainer.portrait,
      "Interface\\Icons\\PetJournalPortrait");
    frame.TitleContainer.TitleText:SetText(L["PetReplacements"]);

    -- Hook script handlers
    frame.dragButton:HookScript("OnMouseUp",
      function(self)
        L.layoutSave("replacements", self:GetParent(), false);
        return;
      end);

    -- Initialise the scroll frame
    child = frame.list
    child.update = petReplacementsListUpdate;
    child.scrollBar.doNotHide = true;
    child.scrollBar.trackBG:Show();
    child.scrollBar.trackBG:SetVertexColor(0, 0, 0, 0.75);
    HybridScrollFrame_CreateButtons(child,
      "NigglesPetReplacementButtonTemplate", 44, -5);

    -- Initialise the scroll frame's buttons
    for _, button in ipairs(child.buttons) do
      button:SetScript("OnClick", petReplacementOnClick);
      child = button.dragButton;
      child:RegisterForDrag("LeftButton");
      child:RegisterForClicks("LeftButtonUp", "RightButtonUp");
      child:SetScript("OnClick", petReplacementOnDragStart);
      child:SetScript("OnDragStart", petReplacementOnDragStart);
      child:SetScript("OnEnter", petReplacementOnEnter);
      child:SetScript("OnLeave", GameTooltip_Hide);
    end
  end

  -- Save the pet info
  frame.petInfo = petInfo;

  -- Update the Pet Replacements list
  frame.list.update(frame.list);

  -- Show the panel
  L.layoutRestore("replacements", frame, false);
  frame:Show();

  return;
end

--
-- Function to update the Pet Replacements list
--
petReplacementsListUpdate = function(self)
  -- Local Variables
  local _;
  local cpjGetPetInfoByPetID = C_PetJournal.GetPetInfoByPetID;
  local cpjGetPetStats = C_PetJournal.GetPetStats;
  local isFavourite;
  local numNames;
  local numPets = petReplacements[0];
  local offset;
  local petCustomName;
  local petSpeciesIcon;
  local petIdx;
  local petLevel;
  local petHealth;
  local petMaxHealth;
  local petSpeciesName;
  local petPower;
  local petQtyColor;
  local petQuality;
  local petSpeciesId;
  local petSpeed;
  local petType;

  -- Initialise some variable
  offset = HybridScrollFrame_GetOffset(self);

  -- Update the buttons in the scroll frame
  for buttonIdx, button in ipairs(self.buttons) do
    -- Work out which team the button is for
    petIdx = buttonIdx+offset;
    if (petIdx <= numPets) then
      -- Get the pet's info
      petSpeciesID, petCustomName, petLevel, _, _, _, isFavourite,
        petSpeciesName, petSpeciesIcon, petType =
        cpjGetPetInfoByPetID(petReplacements[petIdx].guid);
      petHealth, petMaxHealth, petPower, petSpeed, petQuality =
        cpjGetPetStats(petReplacements[petIdx].guid);

      -- Work out the colour for the pet's quality
      if ((type(petQuality) == "number") and
          (ITEM_QUALITY_COLORS[petQuality-1] ~= nil)) then
        petQtyColor = ITEM_QUALITY_COLORS[petQuality-1];
      else
        petQtyColor = ITEM_QUALITY_COLORS[1];
      end

      -- Set the pet's name
      numNames = (customName ~= nil and 2 or 1);
      button.name:SetText(numNames == 2 and petCustomName or petSpeciesName);
      button.name:SetVertexColor(petQtyColor.r, petQtyColor.g,
        petQtyColor.b);
      button.name:SetHeight(numNames == 2 and 12 or 30);
      button.name:SetWordWrap(numNames < 2);
      button.subName:SetText(numNames == 2 and petSpeciesName or "");
      button.subName:SetShown(numNames == 2);

      -- Set the pet's icons
      button.icon:SetTexture(petSpeciesIcon);
      button.petTypeIcon:SetTexture(GetPetTypeTexture(petType));
      button.dragButton.favorite:SetShown(isFavourite);
      button.isDead:SetShown(petHealth == 0);

      -- Set the pet's level and quality
      button.dragButton.level:SetText(petLevel);
      button.iconBorder:SetVertexColor(petQtyColor.r, petQtyColor.g,
        petQtyColor.b);

      -- Set the button's pet GUID
      button.petGuid = petReplacements[petIdx].guid;

      -- Show the button
      button:Show();
    else
      button:Hide();
    end
  end

  -- Update the scroll frame's range
  HybridScrollFrame_Update(self, (self.buttons[1]:GetHeight()*numPets)+5,
    self:GetHeight());

  return;
end

--
-- Function to initialise the list of pet species genera
--
local function petSpeciesInit()
  -- Local Variables
  local _;
  local abilityIds = {};
  local abilityLvls = {};
  local canBattle;
  local cpjGetPetAbilityList = C_PetJournal.GetPetAbilityList;
  local cpjGetPetInfoBySpeciesID = C_PetJournal.GetPetInfoBySpeciesID;
  local genera = petSpeciesGenus;
  local isObtainable;
  local numGenera = 0;
  local profiles = {};
  local speciesType;

  -- Work out the genus for each valid species
  for speciesId = 1, L.petSpeciesMaxId do
    -- Get info about the species
    _, _, speciesType, _, _, _, _, canBattle, _, _, isObtainable =
      cpjGetPetInfoBySpeciesID(speciesId);
    if ((speciesType ~= nil) and
        (canBattle) and
        (isObtainable) and
        (cpjGetPetAbilityList(speciesId, abilityIds, abilityLvls) ~= nil)) then
      -- Create a profile for the species
      profile = format("%d|%d|%d|%d|%d|%d|%d", speciesType,
        abilityIds[1], abilityIds[2], abilityIds[3],
        abilityIds[4], abilityIds[5], abilityIds[6]);

      -- If the profile is new...
      if (profiles[profile] == nil) then
        -- ...assign it a genus ID
        numGenera = numGenera+1;
        profiles[profile] = numGenera;
      end

      -- Add the pet species to the list
      genera[speciesId] = profiles[profile];
    end
  end

  -- Clean up
  profiles = nil;
  collectgarbage("collect");

  return;
end

-------------------------------------------------------------------------------
--                 A  D  D  O  N     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to clear the current pet filters, saving them for later restoration.
-- This function MUST be followed by a call to 'L.petFiltersRestore', preferably
-- before the calling function returns.
--
function L.petFiltersClear()
  -- Local Variables
  local cpj = C_PetJournal;

  -- Disable the processing of 'PET_JOURNAL_LIST_UPDATE' events to prevent
  -- an infinite loop
  if (PetJournal ~= nil) then
    PetJournal:UnregisterEvent("PET_JOURNAL_LIST_UPDATE")
  end

  -- Save the current filter settings and then set them to the required state
  for flag, value in pairs(petFlagSettings) do
    petFilters.flags[flag] = cpj.IsFilterChecked(flag);
    cpj.SetFilterChecked(flag, value);
  end
  for idx = 1, cpj.GetNumPetTypes() do
    petFilters.types[idx] = cpj.IsPetTypeChecked(idx);
  end
  for idx = 1, cpj.GetNumPetSources() do
    petFilters.sources[idx] = cpj.IsPetSourceChecked(idx);
  end
  cpj.SetAllPetTypesChecked(true);
  cpj.SetAllPetSourcesChecked(true);
  if (PetJournalSearchBox ~= nil) then
    petFilters.search = PetJournalSearchBox:GetText();
    if ((petFilters.search == SEARCH) or (petFilters.search == nil)) then
      petFilters.search = "";
    end
  else
    petFilters.search = "";
  end
  cpj.ClearSearchFilter();

  return;
end

--
-- Function to restore previously saved values for the pet filters.
--
function L.petFiltersRestore()
  -- Local Variables
  local cpj = C_PetJournal;

  -- Restore the filtering settings
  for flag, value in pairs(petFilters.flags) do
    cpj.SetFilterChecked(flag, value);
  end
  for idx, value in ipairs(petFilters.types) do
    cpj.SetPetTypeFilter(idx, value);
  end
  for idx, value in ipairs(petFilters.sources) do
    cpj.SetPetSourceChecked(idx, value);
  end
  cpj.SetSearchFilter(petFilters.search);

  -- Restore the processing of 'PET_JOURNAL_LIST_UPDATE' events
  if (PetJournal ~= nil) then
    PetJournal:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
  end

  return;
end

--
-- Function to try to replace a pet that is now missing. If a functionally
-- exact replacement can be found, it will be immediately swapped for the
-- missing pet. If no functionally exact replacement can be found, a list
-- of possible replacements will be displayed so the user can select one.
--
function L.petReplace(petInfo, excludePet1, excludePet2)
  -- Local Variables
  local _;
  local canBattle;
  local cpjGetPetInfoByIndex = C_PetJournal.GetPetInfoByIndex;
  local cpjGetPetStats = C_PetJournal.GetPetStats;
  local errorMsg;
  local isOwned;
  local isRevoked;
  local numPets;
  local numReplacements = 0;
  local petGenus;
  local petLevel;
  local petMaxHealth;
  local petPower;
  local petQuaility;
  local petSpeciesId;
  local petSpeed;
  local petStatWeight = {};
  local repRank;
  local repGenus;
  local repGuid;
  local repLevel;
  local repMaxHealth;
  local repPower;
  local repQuality;
  local repSpeciesId;
  local repSpeed;
  local repType;
  local statDelta;
  local statTotal;
  local petRank;

  -- Initialise the list of pet species genus, if required
  if (next(petSpeciesGenus) == nil) then
    petSpeciesInit();
  end

  -- Get the pet's info
  if (errorMsg == nil) then
    petSpeciesId, _, petLevel, _, petMaxHealth, petPower, petSpeed,
      petQuality = L.petGetInfo(petInfo.guid);
    if (petSpeciesId ~= nil) then
      statTotal    = (petSpeed*5)+(petPower*5)+petMaxHealth;
      petSpeed     = (petSpeed*5)/statTotal;
      petPower     = (petPower*5)/statTotal;
      petMaxHealth = petMaxHealth/statTotal;
      petRank      = 9902221+(petQuality*10000);
    else
      errorMsg = L["PetInfoUnavailable"];
    end
  end

  -- Get the pet's genus
  if (errorMsg == nil) then
    petGenus = petSpeciesGenus[petSpeciesId or 0];
    if (petGenus == nil) then
      errorMsg = L["PetGenusUnknown"];
    end
  end

  -- Search all the player's pets for possible replacements
  if (errorMsg == nil) then
    -- Clear the pet journal filtering
    L.petFiltersClear();

    -- Find any possible replacements and work out a rank for each
    for repIdx = 1, C_PetJournal.GetNumPets() do
      -- Get the info for the possible replacement pet
      repGuid, repSpeciesId, isOwned, _, repLevel, _, isRevoked, _, _, repType,
        _, _, _, _, canBattle = cpjGetPetInfoByIndex(repIdx);
      repGenus = petSpeciesGenus[repSpeciesId];
      if ((repGuid ~= excludePet1) and
          (repGuid ~= excludePet2) and
          (isOwned) and
          (not isRevoked) and
          (canBattle) and
          (repGenus == petGenus)) then
        -- Get the pet's stats
        _, repMaxHealth, repPower, repSpeed, repQuality =
          cpjGetPetStats(repGuid);
        statTotal    = (repSpeed*5)+(repPower*5)+repMaxHealth;
        repSpeed     = (repSpeed*5)/statTotal;
        repPower     = (repPower*5)/statTotal;
        repMaxHealth = repMaxHealth/statTotal;

        -- Work out the rank for the replacement pet
        repRank = 0;
        if (repLevel > petLevel) then
          repRank = repRank+(100000*(99-((repLevel-petLevel)*2)+1));
        else
          repRank = repRank+(100000*(99-((petLevel-repLevel)*2)));
        end
        repRank = repRank+(repQuality*10000);
        if (repSpeed == petSpeed) then
          repRank = repRank+2000;
        elseif (repSpeed > petSpeed) then
          repRank = repRank+1000;
        end
        if (repPower == petPower) then
          repRank = repRank+200;
        elseif (repPower > petPower) then
          repRank = repRank+100;
        end
        if (repMaxHealth == petMaxHealth) then
          repRank = repRank+20;
        elseif (repMaxHealth > petMaxHealth) then
          repRank = repRank+10;
        end
        if (repSpeciesId == petSpeciesId) then
          repRank = repRank+1;
        end

        -- Check if the replacement pet is an exact match
        if (repRank == petRank) then
          numReplacements = 1;
          petReplacements[1].guid = repGuid;
          petReplacements[1].rank = repRank;
          break;
        else
          -- Add the pet to list of possible replacements
          numReplacements = numReplacements+1;
          petReplacements[numReplacements].guid = repGuid;
          petReplacements[numReplacements].rank = repRank;
        end
      end
    end
    petReplacements[0] = numReplacements;

    -- Restore the pet journal filtering
    L.petFiltersRestore();
  end

  -- Sort the replacements by rank
  if (numReplacements > 1) then
    for idx = numReplacements+1, #petReplacements do
      petReplacements[idx].rank = 0;
    end
    table.sort(petReplacements,
      function(first, second)
        return first.rank > second.rank;
      end);
  end

  -- Check if there are any replacements
  if (numReplacements == 1) then
    L.petTeamEditSetSlotPet(petInfo, petReplacements[1].guid,
      petInfo.abilityId, true);
  elseif (numReplacements > 1) then
    petReplacementsDisplay(petInfo);
  else
    errorMsg = L["PetNoReplacement"];
  end

  -- Display any error message, if required
  if (errorMsg ~= nil) then
    StaticPopup_Show("NIGGLES_PETTEAMS_WARNING", errorMsg);
  end

  return;
end

--
-- Function to try to replace all the pets in a team. This is used to import
-- pet teams. If no exact or genus replacement can be found, a pet will be
-- treated as missing by adding it to the list of used pets, using a pseudo
-- GUID.
--
function L.petReplaceAll(importPets, teamInfo, ignoreStats)
  -- Local Variables
  local _;
  local canBattle;
  local cpjGetPetInfoByIndex = C_PetJournal.GetPetInfoByIndex;
  local cpjGetPetStats = C_PetJournal.GetPetStats;
  local current;
  local errorOccurred = false;
  local isMatch;
  local isOwned;
  local isRevoked;
  local repGenus;
  local repGuid;
  local repLevel;
  local repMaxHealth;
  local repPower;
  local repQuality;
  local repSpeciesId;
  local repSpeed;
  local repType;
  local teamPet;

  -- Initialise some variables
  ignoreStats = (ignoreStats or false);

  -- Initialise the list of pet species genera, if required
  if (next(petSpeciesGenus) == nil) then
    petSpeciesInit();
  end

  -- Clear the GUID for all team pets and get their genus
  for petIdx = 1, L.MAX_ACTIVE_PETS do
    current      = importPets[petIdx];
    current.guid = nil;
    if (current.speciesId ~= 0) then
      current.genus = petSpeciesGenus[current.speciesId or 0];
      if (current.genus == nil) then
        return false;
      end
    else
      current.genus = 0;
    end
  end

  -- Clear the pet journal filtering
  L.petFiltersClear();

  -- Find any replacements for the pets
  for repIdx = 1, C_PetJournal.GetNumPets() do
    -- Get the info for the possible replacement pet
    repGuid, repSpeciesId, isOwned, _, repLevel, _, isRevoked, _, _, repType,
      _, _, _, _, canBattle = cpjGetPetInfoByIndex(repIdx);
    if ((isOwned) and (not isRevoked) and (canBattle)) then
      -- Get the pet's stats
      _, repMaxHealth, repPower, repSpeed, repQuality =
        cpjGetPetStats(repGuid);

      -- Check if the replacement pet is an exact match for any team pet
      isMatch = false;
      for petIdx = 1, L.MAX_ACTIVE_PETS do
        current = importPets[petIdx];
        if ((current.speciesId ~= 0) and
            (current.guid == nil) and
            (repSpeciesId == current.speciesId) and
            (repLevel     == current.level    ) and
            (repQuality   == current.quality  ) and
            ((ignoreStats) or
             ((repMaxHealth == current.maxHealth) and
              (repPower     == current.power    ) and
              (repSpeed     == current.speed    )))) then
          current.guid = repGuid;
          isMatch = true;
          break;
        end
      end

      -- Check if the replacement pet is a genus match for any team pet
      if (not isMatch) then
        repGenus = petSpeciesGenus[repSpeciesId];
        for petIdx = 1, L.MAX_ACTIVE_PETS do
          current = importPets[petIdx];
          if ((current.speciesId ~= 0) and
              (current.guid == nil) and
              (repGenus   == current.genus  ) and
              (repLevel   == current.level  ) and
              (repQuality == current.quality) and
              ((ignoreStats) or
               ((repMaxHealth == current.maxHealth) and
                (repPower     == current.power    ) and
                (repSpeed     == current.speed    )))) then
            current.guid = repGuid;
            break;
          end
        end
      end
    end
  end

  -- Copy the pets into the pet team
  for petIdx = 1, L.MAX_ACTIVE_PETS do
    -- Assign some info to more convenient variables
    current = importPets[petIdx];
    teamPet = teamInfo.pets[petIdx];

    -- Check if no suitable pet could be found
    if ((current.speciesId ~= 0) and (current.guid == nil)) then
      -- If stats are being ignored...
      if (ignoreStats) then
        -- ...treat a missing pet as an error
        errorOccurred = true;
        break;
      else
        -- Create pseudo GUID for the pet
        current.guid = L.petSavePseudoInfo(current.speciesId, current.level,
          current.maxHealth, current.power, current.speed, current.quality);
      end
    end

    -- Save the pet's info in the pet team
    teamPet.guid = current.guid;
    for abilityIdx = 1, L.NUM_ACTIVE_ABILITIES do
      teamPet.abilityId[abilityIdx] = current.abilityId[abilityIdx];
    end
  end

  -- Restore the pet journal filtering
  L.petFiltersRestore();

  return (not errorOccurred);
end

--
-- Function to find a replacement random max level pet of an optional pet type.
--
function L.petReplaceMaxLevel(reqTypeId, petInfo, excludePet1, excludePet2)
  -- Local Variables
  local _;
  local canBattle;
  local cpjGetPetInfoByIndex = C_PetJournal.GetPetInfoByIndex;
  local cpjGetPetStats = C_PetJournal.GetPetStats;
  local idx;
  local isOwned;
  local isRevoked;
  local level;
  local maxQuality = 0;
  local petGuid;
  local petQuality;
  local petReplacements = {};
  local petTypeId;
  local speciesId;
  local speciesInfo;

  -- Validate the required pet type ID
  if (reqTypeId == nil) then
    reqTypeId = 0;
  elseif ((type(reqTypeId) ~= "number") or
          (reqTypeId < 0) or
          (reqTypeId > 10)) then
    return false;
  end

  -- Search for any max level pets with the optional type
  for idx = 1, C_PetJournal.GetNumPets() do
    -- Get the info for the possible replacement pet
    petGuid, speciesId, isOwned, _, level, _, isRevoked, _, _, petTypeId,
      _, _, _, _, canBattle = cpjGetPetInfoByIndex(idx);
    if ((isOwned) and
        (not isRevoked) and
        (canBattle) and
        (level == L.MAX_PET_LEVEL) and
        ((reqTypeId == 0) or (petTypeId == reqTypeId)) and
        (petGuid ~= excludePet1) and
        (petGuid ~= excludePet2)) then
      -- Get the pet's quality
      _, _, _, _, petQuality = cpjGetPetStats(petGuid);

      -- Check if this is the highest quality pet so far
      if (petQuality > maxQuality) then
        -- Clear the list of replacements and update the max quality
        wipe(petReplacements);
        maxQuality = petQuality;
      end

      -- Add the pet to the list of replacements if it is high enough quality
      if (petQuality == maxQuality) then
        table.insert(petReplacements, petGuid);
      end
    end
  end

  -- Check if there are any possible replacements
  if (#petReplacements > 0) then
    -- Choose a random pet from the possible replacements
    petInfo.guid      = petReplacements[math.random(#petReplacements)];
    petInfo.speciesId = C_PetJournal.GetPetInfoByPetID(petInfo.guid);
    petInfo.quality   = maxQuality;
    petInfo.genus     = petSpeciesGenus[petInfo.speciesId];

    -- Use the pet's first ability in each slot
    speciesInfo = L.petSpecies[petInfo.speciesId];
    for abilityIdx = 1, L.NUM_ACTIVE_ABILITIES do
      petInfo.abilityId[abilityIdx] = speciesInfo.id[abilityIdx];
    end
  end

  return (#petReplacements > 0);
end

--
-- Function to hide the Pet Replacements frame, if it exists
--
function L.petReplacementsHide()
  -- Hide the Pet Replacements frame, if it exists
  if (petReplacementsFrame ~= nil) then
    petReplacementsFrame:Hide();
  end

  return;
end
