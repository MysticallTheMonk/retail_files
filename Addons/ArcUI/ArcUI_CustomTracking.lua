-- ===================================================================
-- ArcUI_CustomTracking.lua
-- Custom Aura and Cooldown Tracking System
-- Tracks buffs and cooldowns via UNIT_SPELLCAST_SUCCEEDED event
-- Only tracks DETERMINISTIC events (no proc chances)
-- ===================================================================

local ADDON, ns = ...
ns.CustomTracking = ns.CustomTracking or {}

-- ===================================================================
-- RUNTIME STATE (Not saved - rebuilt on load)
-- ===================================================================
ns.CustomTracking.auraStates = {}      -- Runtime state for custom auras
ns.CustomTracking.cooldownStates = {}  -- Runtime state for custom cooldowns

-- Lookup tables for fast event processing
local triggerToAura = {}       -- spellID -> list of aura IDs that trigger from it
local consumerToAura = {}      -- spellID -> list of {auraID, consumerIndex}
local cancellerToAura = {}     -- spellID -> list of aura IDs to cancel
local modifierToAura = {}      -- spellID -> list of {auraID, modifierIndex}

local triggerToCooldown = {}   -- spellID -> list of cooldown IDs
local reducerToCooldown = {}   -- spellID -> list of {cdID, reducerIndex}
local resetterToCooldown = {}  -- spellID -> list of {cdID, resetterIndex}
local chargeModToCooldown = {} -- spellID -> list of {cdID, modifierIndex}

-- Ticker for decay/duration updates
local customTicker = nil
local tickerActive = false

-- ===================================================================
-- UTILITY FUNCTIONS
-- ===================================================================
local function GenerateUUID()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format("%x", v)
  end)
end

ns.CustomTracking.GenerateUUID = GenerateUUID

-- Deep copy a table
local function DeepCopy(orig)
  local copy
  if type(orig) == "table" then
    copy = {}
    for k, v in pairs(orig) do
      copy[k] = DeepCopy(v)
    end
  else
    copy = orig
  end
  return copy
end

-- ===================================================================
-- DEFAULT TEMPLATES
-- ===================================================================
ns.CustomTracking.DEFAULT_AURA = {
  id = "",
  name = "",
  iconTextureID = 134400,
  
  triggers = {
    [1] = { spellID = 0, stacksGranted = 1 }
  },
  triggerUnit = "player",
  
  duration = {
    baseDuration = 10,
    refreshMode = "refresh",
    extendAmount = 0,
    maxDuration = 0,
    usePandemic = false,
    onStackExpire = "removeStack",
  },
  
  stacks = {
    enabled = true,
    maxStacks = 10,
    gainMode = "add",
    decayEnabled = false,
    decayRate = 0,
    decayStartDelay = 0,
  },
  
  consumption = {
    enabled = false,
    consumers = {},
  },
  
  cancellation = {
    cancelSpells = {},
    cancelOnCombatEnd = false,
    cancelOnDeath = true,
  },
  
  stackModifiers = {
    enabled = false,
    modifiers = {},
  },
  
  conditions = {
    requiresCombat = false,
    talentConditions = {},
    talentMatchMode = "all",
    specRestrictions = {},
  },
}

ns.CustomTracking.DEFAULT_COOLDOWN = {
  id = "",
  name = "",
  iconTextureID = 134400,
  
  trigger = {
    spellIDs = {},
    triggerUnit = "player",
    startCondition = "onCast",
    linkedBuffSpellID = 0,
  },
  
  cooldown = {
    baseDuration = 60,
    hasteAffected = false,
  },
  
  charges = {
    enabled = false,
    maxCharges = 1,
    rechargeDuration = 0,
    startAtMax = true,
  },
  
  reduction = {
    enabled = false,
    reducers = {},
  },
  
  reset = {
    enabled = false,
    resetters = {},
  },
  
  chargeModifiers = {
    enabled = false,
    modifiers = {},
  },
  
  sharedCooldown = {
    enabled = false,
    sharedWith = {},
    alsoTriggers = {},
    sharedDuration = 0,
  },
  
  conditions = {
    requiresCombat = false,
    talentConditions = {},
    talentMatchMode = "all",
    specRestrictions = {},
  },
}

-- ===================================================================
-- LOOKUP TABLE REBUILDERS
-- ===================================================================
local function RebuildAuraLookups()
  wipe(triggerToAura)
  wipe(consumerToAura)
  wipe(cancellerToAura)
  wipe(modifierToAura)
  
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.auras then return end
  
  for auraID, def in pairs(db.customDefinitions.auras) do
    -- Build trigger lookups
    if def.triggers then
      for _, trigger in ipairs(def.triggers) do
        if trigger.spellID and trigger.spellID > 0 then
          triggerToAura[trigger.spellID] = triggerToAura[trigger.spellID] or {}
          table.insert(triggerToAura[trigger.spellID], auraID)
        end
      end
    end
    
    -- Build consumer lookups
    if def.consumption and def.consumption.enabled and def.consumption.consumers then
      for idx, consumer in ipairs(def.consumption.consumers) do
        if consumer.spellIDs then
          for _, spellID in ipairs(consumer.spellIDs) do
            consumerToAura[spellID] = consumerToAura[spellID] or {}
            table.insert(consumerToAura[spellID], { auraID = auraID, consumerIndex = idx })
          end
        end
      end
    end
    
    -- Build canceller lookups
    if def.cancellation and def.cancellation.cancelSpells then
      for _, spellID in ipairs(def.cancellation.cancelSpells) do
        cancellerToAura[spellID] = cancellerToAura[spellID] or {}
        table.insert(cancellerToAura[spellID], auraID)
      end
    end
    
    -- Build stack modifier lookups
    if def.stackModifiers and def.stackModifiers.enabled and def.stackModifiers.modifiers then
      for idx, modifier in ipairs(def.stackModifiers.modifiers) do
        if modifier.spellIDs then
          for _, spellID in ipairs(modifier.spellIDs) do
            modifierToAura[spellID] = modifierToAura[spellID] or {}
            table.insert(modifierToAura[spellID], { auraID = auraID, modifierIndex = idx })
          end
        end
      end
    end
  end
end

local function RebuildCooldownLookups()
  wipe(triggerToCooldown)
  wipe(reducerToCooldown)
  wipe(resetterToCooldown)
  wipe(chargeModToCooldown)
  
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.cooldowns then return end
  
  for cdID, def in pairs(db.customDefinitions.cooldowns) do
    -- Build trigger lookups
    if def.trigger and def.trigger.spellIDs then
      for _, spellID in ipairs(def.trigger.spellIDs) do
        triggerToCooldown[spellID] = triggerToCooldown[spellID] or {}
        table.insert(triggerToCooldown[spellID], cdID)
      end
    end
    
    -- Build reducer lookups
    if def.reduction and def.reduction.enabled and def.reduction.reducers then
      for idx, reducer in ipairs(def.reduction.reducers) do
        if reducer.spellIDs then
          for _, spellID in ipairs(reducer.spellIDs) do
            reducerToCooldown[spellID] = reducerToCooldown[spellID] or {}
            table.insert(reducerToCooldown[spellID], { cdID = cdID, reducerIndex = idx })
          end
        end
      end
    end
    
    -- Build resetter lookups
    if def.reset and def.reset.enabled and def.reset.resetters then
      for idx, resetter in ipairs(def.reset.resetters) do
        if resetter.spellIDs then
          for _, spellID in ipairs(resetter.spellIDs) do
            resetterToCooldown[spellID] = resetterToCooldown[spellID] or {}
            table.insert(resetterToCooldown[spellID], { cdID = cdID, resetterIndex = idx })
          end
        end
      end
    end
    
    -- Build charge modifier lookups
    if def.chargeModifiers and def.chargeModifiers.enabled and def.chargeModifiers.modifiers then
      for idx, modifier in ipairs(def.chargeModifiers.modifiers) do
        if modifier.spellIDs then
          for _, spellID in ipairs(modifier.spellIDs) do
            chargeModToCooldown[spellID] = chargeModToCooldown[spellID] or {}
            table.insert(chargeModToCooldown[spellID], { cdID = cdID, modifierIndex = idx })
          end
        end
      end
    end
  end
end

function ns.CustomTracking.RebuildLookups()
  RebuildAuraLookups()
  RebuildCooldownLookups()
end

-- ===================================================================
-- CONDITION CHECKING
-- ===================================================================
local function CheckTalentConditions(conditions)
  if not conditions or not conditions.talentConditions then return true end
  if #conditions.talentConditions == 0 then return true end
  
  -- Use existing talent check from TalentPicker if available
  if ns.TalentPicker and ns.TalentPicker.CheckTalentConditions then
    return ns.TalentPicker.CheckTalentConditions(
      conditions.talentConditions, 
      conditions.talentMatchMode or "all"
    )
  end
  
  return true
end

local function CheckSpecRestrictions(conditions)
  if not conditions or not conditions.specRestrictions then return true end
  if #conditions.specRestrictions == 0 then return true end
  
  local currentSpec = GetSpecialization()
  for _, specID in ipairs(conditions.specRestrictions) do
    if specID == currentSpec then return true end
  end
  
  return false
end

local function CheckConditions(def)
  if not def.conditions then return true end
  
  -- Check combat requirement
  if def.conditions.requiresCombat and not InCombatLockdown() then
    return false
  end
  
  -- Check talent conditions
  if not CheckTalentConditions(def.conditions) then
    return false
  end
  
  -- Check spec restrictions
  if not CheckSpecRestrictions(def.conditions) then
    return false
  end
  
  return true
end

-- ===================================================================
-- AURA STATE MANAGEMENT
-- ===================================================================
local function GetAuraState(auraID)
  if not ns.CustomTracking.auraStates[auraID] then
    ns.CustomTracking.auraStates[auraID] = {
      active = false,
      stacks = 0,
      expirationTime = 0,
      stackTimers = {},  -- For overlap mode
      lastGainTime = 0,
      decayTickerActive = false,
    }
  end
  return ns.CustomTracking.auraStates[auraID]
end

local function GetAuraDefinition(auraID)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.auras then return nil end
  return db.customDefinitions.auras[auraID]
end

-- Apply stack gain to an aura
local function ApplyAuraStack(auraID, stacksToAdd)
  local def = GetAuraDefinition(auraID)
  if not def then return end
  
  -- Check conditions
  if not CheckConditions(def) then return end
  
  local state = GetAuraState(auraID)
  local currentTime = GetTime()
  local stacks = def.stacks
  local duration = def.duration
  
  -- Calculate new stack count
  local newStacks = state.stacks
  local gainMode = stacks.gainMode or "add"
  
  if gainMode == "add" then
    newStacks = math.min(state.stacks + stacksToAdd, stacks.maxStacks)
  elseif gainMode == "set" then
    newStacks = math.min(stacksToAdd, stacks.maxStacks)
  elseif gainMode == "replace" then
    newStacks = math.min(stacksToAdd, stacks.maxStacks)
  end
  
  -- Handle duration based on refresh mode
  local refreshMode = duration.refreshMode or "refresh"
  
  if refreshMode == "refresh" then
    state.expirationTime = currentTime + duration.baseDuration
  elseif refreshMode == "extend" then
    local extension = duration.extendAmount or duration.baseDuration
    local maxDur = duration.maxDuration
    if duration.usePandemic and maxDur == 0 then
      maxDur = duration.baseDuration * 1.3
    end
    local newExpiration = state.expirationTime + extension
    if maxDur > 0 then
      newExpiration = math.min(newExpiration, currentTime + maxDur)
    end
    state.expirationTime = newExpiration
  elseif refreshMode == "overlap" then
    -- Each stack has independent timer
    table.insert(state.stackTimers, currentTime + duration.baseDuration)
    -- Sort timers so earliest is first
    table.sort(state.stackTimers)
    -- Set main expiration to earliest
    state.expirationTime = state.stackTimers[1] or (currentTime + duration.baseDuration)
  elseif refreshMode == "noRefresh" then
    -- Don't change duration, just add stacks
    if not state.active then
      state.expirationTime = currentTime + duration.baseDuration
    end
  end
  
  state.stacks = newStacks
  state.active = true
  state.lastGainTime = currentTime
  
  -- Start ticker if not already running
  ns.CustomTracking.StartTicker()
  
  -- Trigger display update
  ns.CustomTracking.NotifyAuraChange(auraID)
end

-- Consume stacks from an aura
local function ConsumeAuraStacks(auraID, consumerIndex)
  local def = GetAuraDefinition(auraID)
  if not def or not def.consumption or not def.consumption.enabled then return end
  
  local consumer = def.consumption.consumers[consumerIndex]
  if not consumer then return end
  
  local state = GetAuraState(auraID)
  if not state.active or state.stacks <= 0 then return end
  
  -- Check minimum requirement
  local minRequired = consumer.minimumRequired or 0
  if state.stacks < minRequired and not consumer.partialConsume then
    return -- Not enough stacks and no partial consume allowed
  end
  
  -- Calculate how many to consume
  local toConsume = 0
  if consumer.consumeAll then
    toConsume = state.stacks
  else
    toConsume = consumer.consumeAmount or 0
    if consumer.partialConsume and toConsume > state.stacks then
      toConsume = state.stacks
    end
  end
  
  -- Apply consumption
  state.stacks = math.max(0, state.stacks - toConsume)
  
  -- Check if buff should be removed
  if state.stacks <= 0 or consumer.removesBuff then
    state.active = false
    state.stacks = 0
    state.expirationTime = 0
    wipe(state.stackTimers)
  end
  
  -- Trigger display update
  ns.CustomTracking.NotifyAuraChange(auraID)
end

-- Cancel an aura entirely
local function CancelAura(auraID)
  local state = GetAuraState(auraID)
  state.active = false
  state.stacks = 0
  state.expirationTime = 0
  wipe(state.stackTimers)
  
  ns.CustomTracking.NotifyAuraChange(auraID)
end

-- Apply stack modifier
local function ModifyAuraStacks(auraID, modifierIndex)
  local def = GetAuraDefinition(auraID)
  if not def or not def.stackModifiers or not def.stackModifiers.enabled then return end
  
  local modifier = def.stackModifiers.modifiers[modifierIndex]
  if not modifier then return end
  
  local state = GetAuraState(auraID)
  if not state.active then return end
  
  local action = modifier.action or "add"
  local amount = modifier.amount or 0
  local maxStacks = def.stacks.maxStacks or 10
  
  if action == "add" then
    state.stacks = math.min(state.stacks + amount, maxStacks)
  elseif action == "remove" then
    state.stacks = math.max(0, state.stacks - amount)
  elseif action == "set" then
    state.stacks = math.min(amount, maxStacks)
  elseif action == "double" then
    state.stacks = math.min(state.stacks * 2, maxStacks)
  end
  
  if state.stacks <= 0 then
    CancelAura(auraID)
  else
    ns.CustomTracking.NotifyAuraChange(auraID)
  end
end

-- ===================================================================
-- COOLDOWN STATE MANAGEMENT
-- ===================================================================
local function GetCooldownState(cdID)
  if not ns.CustomTracking.cooldownStates[cdID] then
    local def = ns.CustomTracking.GetCooldownDefinition(cdID)
    local maxCharges = def and def.charges and def.charges.enabled and def.charges.maxCharges or 1
    local startAtMax = def and def.charges and def.charges.startAtMax ~= false
    
    ns.CustomTracking.cooldownStates[cdID] = {
      onCooldown = false,
      charges = startAtMax and maxCharges or 0,
      maxCharges = maxCharges,
      cooldownEnd = 0,
      rechargeEnd = 0,
      fullRechargeEnd = 0,
    }
  end
  return ns.CustomTracking.cooldownStates[cdID]
end

function ns.CustomTracking.GetCooldownDefinition(cdID)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.cooldowns then return nil end
  return db.customDefinitions.cooldowns[cdID]
end

-- Start a cooldown
local function StartCooldown(cdID)
  local def = ns.CustomTracking.GetCooldownDefinition(cdID)
  if not def then return end
  
  -- Check conditions
  if not CheckConditions(def) then return end
  
  local state = GetCooldownState(cdID)
  local currentTime = GetTime()
  
  -- Calculate cooldown duration (potentially affected by haste)
  local baseDuration = def.cooldown.baseDuration
  local duration = baseDuration
  if def.cooldown.hasteAffected then
    local haste = 1 + (GetHaste() / 100)
    duration = baseDuration / haste
  end
  
  if def.charges and def.charges.enabled then
    -- Has charges
    if state.charges > 0 then
      state.charges = state.charges - 1
    end
    
    local rechargeDuration = def.charges.rechargeDuration
    if rechargeDuration == 0 then
      rechargeDuration = duration
    end
    
    if state.charges < state.maxCharges then
      -- Start recharge if not already recharging
      if state.rechargeEnd <= currentTime then
        state.rechargeEnd = currentTime + rechargeDuration
      end
      -- Update full recharge time
      local chargesNeeded = state.maxCharges - state.charges
      state.fullRechargeEnd = state.rechargeEnd + (rechargeDuration * (chargesNeeded - 1))
    end
    
    state.onCooldown = state.charges == 0
    state.cooldownEnd = state.onCooldown and state.rechargeEnd or 0
  else
    -- No charges - simple cooldown
    state.onCooldown = true
    state.cooldownEnd = currentTime + duration
    state.rechargeEnd = state.cooldownEnd
    state.fullRechargeEnd = state.cooldownEnd
  end
  
  -- Handle shared cooldowns
  if def.sharedCooldown and def.sharedCooldown.enabled and def.sharedCooldown.alsoTriggers then
    local sharedDuration = def.sharedCooldown.sharedDuration
    if sharedDuration == 0 then
      sharedDuration = duration
    end
    
    for _, sharedCdID in ipairs(def.sharedCooldown.alsoTriggers) do
      local sharedState = GetCooldownState(sharedCdID)
      sharedState.onCooldown = true
      sharedState.cooldownEnd = currentTime + sharedDuration
      sharedState.rechargeEnd = sharedState.cooldownEnd
      ns.CustomTracking.NotifyCooldownChange(sharedCdID)
    end
  end
  
  ns.CustomTracking.StartTicker()
  ns.CustomTracking.NotifyCooldownChange(cdID)
end

-- Reduce a cooldown
local function ReduceCooldown(cdID, reducerIndex)
  local def = ns.CustomTracking.GetCooldownDefinition(cdID)
  if not def or not def.reduction or not def.reduction.enabled then return end
  
  local reducer = def.reduction.reducers[reducerIndex]
  if not reducer then return end
  
  local state = GetCooldownState(cdID)
  if not state.onCooldown and state.charges >= state.maxCharges then return end
  
  local currentTime = GetTime()
  local reductionAmount = reducer.amount or 0
  
  if reducer.reductionType == "percent" then
    local remaining = state.rechargeEnd - currentTime
    reductionAmount = remaining * (reductionAmount / 100)
  end
  
  -- Apply cap if specified
  if reducer.maxReductionPerCast and reducer.maxReductionPerCast > 0 then
    reductionAmount = math.min(reductionAmount, reducer.maxReductionPerCast)
  end
  
  -- Reduce the cooldown
  state.rechargeEnd = state.rechargeEnd - reductionAmount
  state.cooldownEnd = state.cooldownEnd - reductionAmount
  state.fullRechargeEnd = state.fullRechargeEnd - reductionAmount
  
  -- Check if cooldown completed
  if state.rechargeEnd <= currentTime then
    if def.charges and def.charges.enabled then
      state.charges = math.min(state.charges + 1, state.maxCharges)
      if state.charges < state.maxCharges then
        local rechargeDuration = def.charges.rechargeDuration
        if rechargeDuration == 0 then
          rechargeDuration = def.cooldown.baseDuration
        end
        state.rechargeEnd = currentTime + rechargeDuration
      else
        state.rechargeEnd = 0
      end
    end
    state.onCooldown = state.charges == 0
    state.cooldownEnd = state.onCooldown and state.rechargeEnd or 0
  end
  
  ns.CustomTracking.NotifyCooldownChange(cdID)
end

-- Reset a cooldown
local function ResetCooldown(cdID, resetterIndex)
  local def = ns.CustomTracking.GetCooldownDefinition(cdID)
  if not def or not def.reset or not def.reset.enabled then return end
  
  local resetter = def.reset.resetters[resetterIndex]
  if not resetter then return end
  
  local state = GetCooldownState(cdID)
  
  if resetter.resetCharges then
    local resetTo = resetter.resetToCharges or 0
    if resetTo == 0 then
      resetTo = state.maxCharges
    end
    state.charges = math.min(resetTo, state.maxCharges)
  end
  
  -- Reset cooldown timers
  state.onCooldown = false
  state.cooldownEnd = 0
  state.rechargeEnd = 0
  state.fullRechargeEnd = 0
  
  ns.CustomTracking.NotifyCooldownChange(cdID)
end

-- Modify charges directly
local function ModifyCooldownCharges(cdID, modifierIndex)
  local def = ns.CustomTracking.GetCooldownDefinition(cdID)
  if not def or not def.chargeModifiers or not def.chargeModifiers.enabled then return end
  
  local modifier = def.chargeModifiers.modifiers[modifierIndex]
  if not modifier then return end
  
  local state = GetCooldownState(cdID)
  local action = modifier.action or "add"
  local amount = modifier.amount or 1
  
  if action == "add" then
    local maxAllowed = modifier.canExceedMax and 999 or state.maxCharges
    state.charges = math.min(state.charges + amount, maxAllowed)
  elseif action == "remove" then
    state.charges = math.max(0, state.charges - amount)
  elseif action == "set" then
    state.charges = math.min(amount, modifier.canExceedMax and 999 or state.maxCharges)
  end
  
  state.onCooldown = state.charges == 0
  
  ns.CustomTracking.NotifyCooldownChange(cdID)
end

-- ===================================================================
-- TICKER FOR DURATION/DECAY UPDATES
-- ===================================================================
local function TickerUpdate()
  local currentTime = GetTime()
  local hasActiveTracking = false
  
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions then return end
  
  -- Update auras
  if db.customDefinitions.auras then
    for auraID, def in pairs(db.customDefinitions.auras) do
      local state = ns.CustomTracking.auraStates[auraID]
      if state and state.active then
        hasActiveTracking = true
        
        -- Check expiration
        if def.duration.refreshMode == "overlap" then
          -- Remove expired stack timers
          local expiredCount = 0
          for i = #state.stackTimers, 1, -1 do
            if state.stackTimers[i] <= currentTime then
              table.remove(state.stackTimers, i)
              expiredCount = expiredCount + 1
            end
          end
          
          if expiredCount > 0 then
            if def.duration.onStackExpire == "removeAll" then
              CancelAura(auraID)
            else
              state.stacks = math.max(0, state.stacks - expiredCount)
              if state.stacks <= 0 then
                CancelAura(auraID)
              else
                state.expirationTime = state.stackTimers[1] or 0
                ns.CustomTracking.NotifyAuraChange(auraID)
              end
            end
          end
        else
          -- Normal expiration check
          if state.expirationTime > 0 and currentTime >= state.expirationTime then
            CancelAura(auraID)
          end
        end
        
        -- Check decay
        if state.active and def.stacks.decayEnabled and def.stacks.decayRate > 0 then
          local delayPassed = (currentTime - state.lastGainTime) >= (def.stacks.decayStartDelay or 0)
          if delayPassed then
            -- TODO: Implement decay timer tracking
          end
        end
      end
    end
  end
  
  -- Update cooldowns
  if db.customDefinitions.cooldowns then
    for cdID, def in pairs(db.customDefinitions.cooldowns) do
      local state = ns.CustomTracking.cooldownStates[cdID]
      if state then
        local changed = false
        
        -- Check recharge completion
        if state.rechargeEnd > 0 and currentTime >= state.rechargeEnd then
          if def.charges and def.charges.enabled then
            state.charges = math.min(state.charges + 1, state.maxCharges)
            
            if state.charges < state.maxCharges then
              local rechargeDuration = def.charges.rechargeDuration
              if rechargeDuration == 0 then
                rechargeDuration = def.cooldown.baseDuration
              end
              state.rechargeEnd = currentTime + rechargeDuration
              hasActiveTracking = true
            else
              state.rechargeEnd = 0
            end
          end
          
          state.onCooldown = state.charges == 0
          state.cooldownEnd = state.onCooldown and state.rechargeEnd or 0
          changed = true
        elseif state.rechargeEnd > currentTime then
          hasActiveTracking = true
        end
        
        if changed then
          ns.CustomTracking.NotifyCooldownChange(cdID)
        end
      end
    end
  end
  
  -- Stop ticker if nothing active
  if not hasActiveTracking then
    ns.CustomTracking.StopTicker()
  end
end

function ns.CustomTracking.StartTicker()
  if tickerActive then return end
  tickerActive = true
  customTicker = C_Timer.NewTicker(0.1, TickerUpdate)
end

function ns.CustomTracking.StopTicker()
  if customTicker then
    customTicker:Cancel()
    customTicker = nil
  end
  tickerActive = false
end

-- ===================================================================
-- EVENT HANDLER
-- ===================================================================
local function OnSpellcastSucceeded(unit, castGUID, spellID)
  if unit ~= "player" then return end  -- TODO: handle "pet" for triggerUnit = "pet"
  
  -- Process aura triggers
  local auraTriggers = triggerToAura[spellID]
  if auraTriggers then
    for _, auraID in ipairs(auraTriggers) do
      local def = GetAuraDefinition(auraID)
      if def then
        -- Find the specific trigger to get stacksGranted
        local stacksToAdd = 1
        for _, trigger in ipairs(def.triggers) do
          if trigger.spellID == spellID then
            stacksToAdd = trigger.stacksGranted or 1
            break
          end
        end
        ApplyAuraStack(auraID, stacksToAdd)
      end
    end
  end
  
  -- Process aura consumers
  local auraConsumers = consumerToAura[spellID]
  if auraConsumers then
    for _, info in ipairs(auraConsumers) do
      ConsumeAuraStacks(info.auraID, info.consumerIndex)
    end
  end
  
  -- Process aura cancellers
  local auraCancellers = cancellerToAura[spellID]
  if auraCancellers then
    for _, auraID in ipairs(auraCancellers) do
      CancelAura(auraID)
    end
  end
  
  -- Process stack modifiers
  local auraModifiers = modifierToAura[spellID]
  if auraModifiers then
    for _, info in ipairs(auraModifiers) do
      ModifyAuraStacks(info.auraID, info.modifierIndex)
    end
  end
  
  -- Process cooldown triggers
  local cdTriggers = triggerToCooldown[spellID]
  if cdTriggers then
    for _, cdID in ipairs(cdTriggers) do
      StartCooldown(cdID)
    end
  end
  
  -- Process cooldown reducers
  local cdReducers = reducerToCooldown[spellID]
  if cdReducers then
    for _, info in ipairs(cdReducers) do
      ReduceCooldown(info.cdID, info.reducerIndex)
    end
  end
  
  -- Process cooldown resetters
  local cdResetters = resetterToCooldown[spellID]
  if cdResetters then
    for _, info in ipairs(cdResetters) do
      ResetCooldown(info.cdID, info.resetterIndex)
    end
  end
  
  -- Process charge modifiers
  local cdChargeMods = chargeModToCooldown[spellID]
  if cdChargeMods then
    for _, info in ipairs(cdChargeMods) do
      ModifyCooldownCharges(info.cdID, info.modifierIndex)
    end
  end
end

-- Combat end handler
local function OnCombatEnd()
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.auras then return end
  
  for auraID, def in pairs(db.customDefinitions.auras) do
    if def.cancellation and def.cancellation.cancelOnCombatEnd then
      CancelAura(auraID)
    end
  end
end

-- Death handler
local function OnPlayerDeath()
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.auras then return end
  
  for auraID, def in pairs(db.customDefinitions.auras) do
    if def.cancellation and def.cancellation.cancelOnDeath then
      CancelAura(auraID)
    end
  end
end

-- ===================================================================
-- DISPLAY NOTIFICATION (for bars/icons to update)
-- ===================================================================
function ns.CustomTracking.NotifyAuraChange(auraID)
  -- Find any bars tracking this custom aura and update them
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.bars then return end
  
  for barNum = 1, 30 do
    local cfg = db.bars[barNum]
    if cfg and cfg.tracking and cfg.tracking.enabled then
      if cfg.tracking.trackType == "customAura" and cfg.tracking.customDefinitionID == auraID then
        -- Update this bar via the full display pipeline
        if ns.API and ns.API.RefreshDisplay then
          ns.API.RefreshDisplay(barNum)
        end
      end
    end
  end
end

function ns.CustomTracking.NotifyCooldownChange(cdID)
  -- Find any bars tracking this custom cooldown and update them
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.bars then return end
  
  for barNum = 1, 30 do
    local cfg = db.bars[barNum]
    if cfg and cfg.tracking and cfg.tracking.enabled then
      if cfg.tracking.trackType == "customCooldown" and cfg.tracking.customDefinitionID == cdID then
        -- Update this bar via the full display pipeline
        if ns.API and ns.API.RefreshDisplay then
          ns.API.RefreshDisplay(barNum)
        end
      end
    end
  end
end

-- ===================================================================
-- API: GET STATE FOR DISPLAY
-- ===================================================================
function ns.CustomTracking.GetAuraState(auraID)
  return GetAuraState(auraID)
end

function ns.CustomTracking.GetCooldownState(cdID)
  return GetCooldownState(cdID)
end

-- ===================================================================
-- API: CRUD OPERATIONS FOR DEFINITIONS
-- ===================================================================
function ns.CustomTracking.CreateAura(definition)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db then return nil end
  
  if not db.customDefinitions then
    db.customDefinitions = { auras = {}, cooldowns = {} }
  end
  if not db.customDefinitions.auras then
    db.customDefinitions.auras = {}
  end
  
  -- Generate ID if not provided
  local id = definition.id
  if not id or id == "" then
    id = "custom_aura_" .. GenerateUUID()
    definition.id = id
  end
  
  -- Merge with defaults
  local newDef = DeepCopy(ns.CustomTracking.DEFAULT_AURA)
  for k, v in pairs(definition) do
    if type(v) == "table" then
      newDef[k] = DeepCopy(v)
    else
      newDef[k] = v
    end
  end
  
  db.customDefinitions.auras[id] = newDef
  RebuildAuraLookups()
  
  return id
end

function ns.CustomTracking.UpdateAura(auraID, updates)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.auras then return false end
  
  local def = db.customDefinitions.auras[auraID]
  if not def then return false end
  
  -- Apply updates
  for k, v in pairs(updates) do
    if type(v) == "table" then
      def[k] = DeepCopy(v)
    else
      def[k] = v
    end
  end
  
  RebuildAuraLookups()
  return true
end

function ns.CustomTracking.DeleteAura(auraID)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.auras then return false end
  
  db.customDefinitions.auras[auraID] = nil
  ns.CustomTracking.auraStates[auraID] = nil
  RebuildAuraLookups()
  
  return true
end

function ns.CustomTracking.CreateCooldown(definition)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db then return nil end
  
  if not db.customDefinitions then
    db.customDefinitions = { auras = {}, cooldowns = {} }
  end
  if not db.customDefinitions.cooldowns then
    db.customDefinitions.cooldowns = {}
  end
  
  -- Generate ID if not provided
  local id = definition.id
  if not id or id == "" then
    id = "custom_cd_" .. GenerateUUID()
    definition.id = id
  end
  
  -- Merge with defaults
  local newDef = DeepCopy(ns.CustomTracking.DEFAULT_COOLDOWN)
  for k, v in pairs(definition) do
    if type(v) == "table" then
      newDef[k] = DeepCopy(v)
    else
      newDef[k] = v
    end
  end
  
  db.customDefinitions.cooldowns[id] = newDef
  RebuildCooldownLookups()
  
  return id
end

function ns.CustomTracking.UpdateCooldown(cdID, updates)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.cooldowns then return false end
  
  local def = db.customDefinitions.cooldowns[cdID]
  if not def then return false end
  
  -- Apply updates
  for k, v in pairs(updates) do
    if type(v) == "table" then
      def[k] = DeepCopy(v)
    else
      def[k] = v
    end
  end
  
  RebuildCooldownLookups()
  return true
end

function ns.CustomTracking.DeleteCooldown(cdID)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.cooldowns then return false end
  
  db.customDefinitions.cooldowns[cdID] = nil
  ns.CustomTracking.cooldownStates[cdID] = nil
  RebuildCooldownLookups()
  
  return true
end

-- ===================================================================
-- API: GET ALL DEFINITIONS
-- ===================================================================
function ns.CustomTracking.GetAllAuras()
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.auras then return {} end
  return db.customDefinitions.auras
end

function ns.CustomTracking.GetAllCooldowns()
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.customDefinitions or not db.customDefinitions.cooldowns then return {} end
  return db.customDefinitions.cooldowns
end

function ns.CustomTracking.GetAuraDefinition(auraID)
  return GetAuraDefinition(auraID)
end

-- ===================================================================
-- EVENT FRAME
-- ===================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    OnSpellcastSucceeded(...)
  elseif event == "PLAYER_REGEN_ENABLED" then
    OnCombatEnd()
  elseif event == "PLAYER_DEAD" then
    OnPlayerDeath()
  elseif event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_TALENT_UPDATE" then
    -- Re-check talent conditions for all active tracking
    -- (handled automatically on next spell cast)
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    -- Re-check spec restrictions
    -- (handled automatically on next spell cast)
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Rebuild lookups on login/reload
    C_Timer.After(1.0, function()
      ns.CustomTracking.RebuildLookups()
    end)
  end
end)

-- ===================================================================
-- INITIALIZATION
-- ===================================================================
function ns.CustomTracking.Init()
  -- Rebuild lookup tables
  ns.CustomTracking.RebuildLookups()
end

-- Delayed init to ensure DB is ready
C_Timer.After(0.5, function()
  ns.CustomTracking.Init()
end)

-- ===================================================================
-- END OF ArcUI_CustomTracking.lua
-- ===================================================================
