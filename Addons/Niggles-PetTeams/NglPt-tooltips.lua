-------------------------------------------------------------------------------
--                 L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

local abilityTooltipInfo = SharedPetBattleAbilityTooltip_GetInfoTable();

-------------------------------------------------------------------------------
--               G  L  O  B  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--              L  O  C  A  L     D  E  F  I  N  I  T  I  O  N  S
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                 L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to get the ID of the ability to display in the ability tooltip
--
function abilityTooltipInfo:GetAbilityID()
  return self.abilityID;
end

--
-- Function to check if battle effects should be reflected in the ability
-- tooltip
--
function abilityTooltipInfo:IsInBattle()
  return false;
end

--
-- Function to get the current health of the pet the ability tooltip is for
--
function abilityTooltipInfo:GetHealth(target)
  self:EnsureTarget(target);
  if (self.petID) then
    return select(4, L.petGetInfo(self.petID));
  else
    --Do something with self.speciesID?
    return self:GetMaxHealth(target);
  end
end

--
-- Function to get the maximum health of the pet the ability tooltip is for
--
function abilityTooltipInfo:GetMaxHealth(target)
  self:EnsureTarget(target);
  if ( self.petID ) then
    return select(5, L.petGetInfo(self.petID));
  else
    --Do something with self.speciesID?
    return 100;
  end
end

--
-- Function to get the power of the pet the ability tooltip is for
--
function abilityTooltipInfo:GetAttackStat(target)
  self:EnsureTarget(target);
  if ( self.petID ) then
    return select(6, L.petGetInfo(self.petID));
  else
    --Do something with self.speciesID?
    return 0;
  end
end

--
-- Function to get the speed of the pet the ability tooltip is for
--
function abilityTooltipInfo:GetSpeedStat(target)
  self:EnsureTarget(target);
  if ( self.petID ) then
    return select(7, L.petGetInfo(self.petID));
  else
    --Do something with self.speciesID?
    return 0;
  end
end

--
-- Function to get the owner of the pet the ability tooltip is for
--
function abilityTooltipInfo:GetPetOwner(target)
  self:EnsureTarget(target);
  return LE_BATTLE_PET_ALLY;
end

--
-- Function to get the species of the pet the ability tooltip is for
--
function abilityTooltipInfo:GetPetType(target)
  self:EnsureTarget(target);
  if ( not self.speciesID ) then
    GMError("No species id found");
    return 1;
  end
  local _, _, petType = C_PetJournal.GetPetInfoBySpeciesID(self.speciesID);
  return petType;
end

function abilityTooltipInfo:EnsureTarget(target)
  if ( target == "default" ) then
    target = "self";
  elseif ( target == "affected" ) then
    target = "enemy";
  end
  if ( target ~= "self" ) then
    GMError("Only \"self\" unit supported out of combat");
  end
end

-------------------------------------------------------------------------------
--                A  D  D  O  N     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to display the tooltip for a pet ability, taking the pet's level
-- and species into consideration
--
function L.abilityTooltipShow(frame, abilityId, petGuid, speciesId, additionalText)
  -- Initialise the ability info
  abilityTooltipInfo.abilityID = abilityId;
  abilityTooltipInfo.petID     = petGuid;
  abilityTooltipInfo.speciesID = speciesId;

  -- Position the tooltip
  PetJournalPrimaryAbilityTooltip:ClearAllPoints();
  PetJournalPrimaryAbilityTooltip:SetPoint("TOPLEFT", frame,
    "TOPRIGHT", 5, 0);
  PetJournalPrimaryAbilityTooltip.anchoredTo = frame;

  -- Show the tooltip
  SharedPetBattleAbilityTooltip_SetAbility(PetJournalPrimaryAbilityTooltip,
    abilityTooltipInfo, additionalText);
  PetJournalPrimaryAbilityTooltip:Show();

  return;
end
