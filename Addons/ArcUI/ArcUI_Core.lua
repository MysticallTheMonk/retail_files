-- ===================================================================
-- ArcUI_Core.lua
-- Core tracking system supporting multiple bar slots
-- v2.10.0: Hook-based stack updates (replaces polling)
--   - Hooks CDM frame RefreshData for instant stack updates
--   - No more polling delays for high-haste builds
--   - Arcane Salvo, Maelstrom Weapon, etc. now update immediately
-- v2.7.0: Added sound utilities for conditional events system
-- 
-- DEBUFF DURATION FIX (v2.2.1):
-- - For debuffs, use CDM frame's auraInstanceID with "target" unit
-- - CDM bar frame provides duration data via Bar:GetValue()
-- ===================================================================

local ADDON, ns = ...
ns = ns or {}
ns.API = ns.API or {}

ns.devMode = false
ns.debugMode = false  -- Stack tracking debug output

-- ===================================================================
-- LIBPLEEBUG PROFILING SETUP
-- ===================================================================
local MemDebug = LibStub and LibStub("LibPleebug-1", true)
local P, TrackThis
if MemDebug then
  P, TrackThis = MemDebug:DropIn(ns.API)
end
ns.API._TrackThis = TrackThis

-- Spec change grace period - don't hide bars due to trackingOK=false for a few seconds after spec change
local specChangeGraceUntil = 0
local SPEC_CHANGE_GRACE_DURATION = 3.0  -- seconds

-- ===================================================================
-- REGISTER ADDON SOUNDS WITH LIBSHAREDMEDIA
-- v2.7.0: Added for conditional events system
-- ===================================================================
local LSM = LibStub("LibSharedMedia-3.0", true)

if LSM then
  local SOUND_PATH = "Interface\\AddOns\\ArcUI\\Sounds\\"
  
  local addonSounds = {
    -- Animals
    ["ArcUI: Bleat"]             = "Bleat.ogg",
    ["ArcUI: Cat Meow"]          = "CatMeow2.ogg",
    ["ArcUI: Chicken Alarm"]     = "ChickenAlarm.ogg",
    ["ArcUI: Cow Mooing"]        = "CowMooing.ogg",
    ["ArcUI: Goat Bleating"]     = "GoatBleating.ogg",
    ["ArcUI: Kitten Meow"]       = "KittenMeow.ogg",
    ["ArcUI: Roaring Lion"]      = "RoaringLion.ogg",
    ["ArcUI: Rooster Chicken"]   = "RoosterChickenCalls.ogg",
    ["ArcUI: Sheep Bleat"]       = "SheepBleat.ogg",
    -- Alerts
    ["ArcUI: Air Horn"]          = "AirHorn.ogg",
    ["ArcUI: Bike Horn"]         = "BikeHorn.ogg",
    ["ArcUI: Error Beep"]        = "ErrorBeep.ogg",
    ["ArcUI: Ringing Phone"]     = "RingingPhone.ogg",
    ["ArcUI: Robot Blip"]        = "RobotBlip.ogg",
    ["ArcUI: Warning Siren"]     = "WarningSiren.ogg",
    -- Musical
    ["ArcUI: Acoustic Guitar"]   = "AcousticGuitar.ogg",
    ["ArcUI: Brass"]             = "Brass.mp3",
    ["ArcUI: Drums"]             = "Drums.ogg",
    ["ArcUI: Glass"]             = "Glass.mp3",
    ["ArcUI: Synth Chord"]       = "SynthChord.ogg",
    ["ArcUI: Tada Fanfare"]      = "TadaFanfare.ogg",
    ["ArcUI: Temple Bell"]       = "TempleBellHuge.ogg",
    ["ArcUI: Xylophone"]         = "Xylophone.ogg",
    -- Effects
    ["ArcUI: Applause"]          = "Applause.ogg",
    ["ArcUI: Banana Peel Slip"]  = "BananaPeelSlip.ogg",
    ["ArcUI: Batman Punch"]      = "BatmanPunch.ogg",
    ["ArcUI: Blast"]             = "Blast.ogg",
    ["ArcUI: Boxing Arena"]      = "BoxingArenaSound.ogg",
    ["ArcUI: Double Whoosh"]     = "DoubleWhoosh.ogg",
    ["ArcUI: Heartbeat"]         = "HeartbeatSingle.ogg",
    ["ArcUI: Sharp Punch"]       = "SharpPunch.ogg",
    ["ArcUI: Shotgun"]           = "Shotgun.ogg",
    ["ArcUI: Squeaky Toy"]       = "SqueakyToyShort.ogg",
    ["ArcUI: Squish"]            = "SquishFart.ogg",
    ["ArcUI: Torch"]             = "Torch.ogg",
    ["ArcUI: Water Drop"]        = "WaterDrop.ogg",
    -- Voice
    ["ArcUI: Cartoon Voice"]     = "CartoonVoiceBaritone.ogg",
    ["ArcUI: Cartoon Walking"]   = "CartoonWalking.ogg",
    ["ArcUI: Oh No"]             = "OhNo.ogg",
  }
  
  for name, file in pairs(addonSounds) do
    LSM:Register("sound", name, SOUND_PATH .. file)
  end
end

-- ===================================================================
-- SOUND UTILITIES
-- ===================================================================
ns.Sounds = ns.Sounds or {}

-- Built-in WoW SoundKit IDs
ns.Sounds.builtInSounds = {
  [567]   = "Snarl",
  [569]   = "Growl",
  [3081]  = "Direct Message",
  [5274]  = "Auction Window",
  [8959]  = "Raid Warning",
  [11466] = "Not Prepared",
  [12867] = "Drumroll Ding",
  [23404] = "PvP Warning",
  [25477] = "Countdown",
}

local currentSoundHandle = nil

-- Play a sound from settings table
-- settings = { soundType = "lsm"|"soundkit"|"custom", lsmSound = name, soundKitID = id, customPath = path }
function ns.Sounds.PlaySound(settings)
  if not settings then return end
  
  local willPlay, soundHandle
  
  if settings.soundType == "soundkit" and settings.soundKitID then
    willPlay, soundHandle = PlaySound(settings.soundKitID, "Master")
  elseif settings.soundType == "lsm" and settings.lsmSound then
    if LSM then
      local soundPath = LSM:Fetch("sound", settings.lsmSound)
      if soundPath then
        willPlay, soundHandle = PlaySoundFile(soundPath, "Master")
      end
    end
  elseif settings.soundType == "custom" and settings.customPath and settings.customPath ~= "" then
    willPlay, soundHandle = PlaySoundFile(settings.customPath, "Master")
  end
  
  -- Handle TTS if enabled
  if settings.ttsEnabled and settings.ttsText and settings.ttsText ~= "" then
    ns.Sounds.SpeakText(settings.ttsText, settings.ttsVoice)
  end
  
  return willPlay, soundHandle
end

-- Preview a sound (for options panel)
function ns.Sounds.PreviewSound(settings)
  ns.Sounds.StopPreview()
  local willPlay, soundHandle = ns.Sounds.PlaySound(settings)
  currentSoundHandle = soundHandle
  return willPlay
end

-- Stop the current preview
function ns.Sounds.StopPreview()
  if currentSoundHandle then
    StopSound(currentSoundHandle)
    currentSoundHandle = nil
  end
end

-- Text-to-speech wrapper
function ns.Sounds.SpeakText(text, voiceID)
  if not text or text == "" then return end
  if not C_VoiceChat or not C_VoiceChat.SpeakText then return end
  -- voiceID 0 = default, Enum.TtsVoiceType.Standard = 0
  C_VoiceChat.SpeakText(voiceID or 0, text, Enum.TtsVoiceType.Standard, 100, 100)
end

-- Get dropdown values for sound selection
-- Returns: { ["lsm:soundName"] = "Sound Name", ["soundkit:123"] = "Built-in Name", ... }
function ns.Sounds.GetSoundDropdown()
  local sounds = {}
  
  -- Add LSM sounds
  if LSM then
    local lsmSounds = LSM:List("sound")
    for _, soundName in ipairs(lsmSounds) do
      sounds["lsm:" .. soundName] = soundName
    end
  end
  
  -- Add built-in SoundKit sounds
  for id, name in pairs(ns.Sounds.builtInSounds) do
    sounds["soundkit:" .. id] = name .. " (Built-in)"
  end
  
  return sounds
end

-- Parse a dropdown key into a settings table
function ns.Sounds.ParseSoundKey(key)
  if not key then return nil end
  
  if key:match("^lsm:") then
    return { soundType = "lsm", lsmSound = key:gsub("^lsm:", "") }
  elseif key:match("^soundkit:") then
    return { soundType = "soundkit", soundKitID = tonumber(key:gsub("^soundkit:", "")) }
  end
  
  return nil
end

-- Create a dropdown key from a settings table
function ns.Sounds.CreateSoundKey(settings)
  if not settings then return nil end
  
  if settings.soundType == "lsm" and settings.lsmSound then
    return "lsm:" .. settings.lsmSound
  elseif settings.soundType == "soundkit" and settings.soundKitID then
    return "soundkit:" .. settings.soundKitID
  end
  
  return nil
end

-- ===================================================================
-- CUSTOM EDITBOX WIDGET WITHOUT OK BUTTON
-- ===================================================================
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if AceGUI then
  local Type = "ArcUI_EditBox"
  local Version = 3
  local function Constructor()
    local widget = AceGUI:Create("EditBox")
    local originalOnAcquire = widget.OnAcquire
    widget.OnAcquire = function(self)
      if originalOnAcquire then originalOnAcquire(self) end
      self:DisableButton(true)
      if self.editbox then self.editbox:SetJustifyH("CENTER") end
    end
    widget:DisableButton(true)
    if widget.editbox then widget.editbox:SetJustifyH("CENTER") end
    return widget
  end
  AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- ===================================================================
-- FORWARD DECLARATIONS
-- ===================================================================
local UpdateAllBars
local UpdateBarBuffInfo

-- ===================================================================
-- HOOK-BASED STACK UPDATES (v2.10.0)
-- Instead of polling, we hook CDM frame's RefreshData method
-- This gives us instant updates when stacks change
-- ===================================================================
local hookedCDMFrames = {}  -- [frame] = { barNumbers = {barNum = true, ...} }
local frameToBarMapping = {}  -- [frame] = {barNum1, barNum2, ...}

-- Called when a hooked CDM frame's RefreshData fires
local function OnCDMFrameRefreshData(frame)
  -- Find which bars use this frame and update them immediately
  local bars = frameToBarMapping[frame]
  if bars then
    for _, barNumber in ipairs(bars) do
      UpdateBarBuffInfo(barNumber)
    end
  end
end

-- Hook a CDM frame for instant stack updates
local function HookCDMFrameForStackUpdates(frame, barNumber)
  if not frame then return end
  
  -- Initialize tracking for this frame
  if not hookedCDMFrames[frame] then
    hookedCDMFrames[frame] = { barNumbers = {} }
    frameToBarMapping[frame] = {}
    
    -- Hook RefreshData - this is called when aura data (including stacks) changes
    if frame.RefreshData then
      hooksecurefunc(frame, "RefreshData", function(self)
        OnCDMFrameRefreshData(self)
      end)
    end
    
    -- Also hook RefreshApplications for extra safety (called within RefreshData)
    if frame.RefreshApplications then
      hooksecurefunc(frame, "RefreshApplications", function(self)
        OnCDMFrameRefreshData(self)
      end)
    end
    
    -- Hook SetAuraInstanceInfo - fires when aura data becomes available
    if frame.SetAuraInstanceInfo then
      hooksecurefunc(frame, "SetAuraInstanceInfo", function(self, auraData)
        OnCDMFrameRefreshData(self)
      end)
    end
  end
  
  -- Register this bar as using this frame
  if not hookedCDMFrames[frame].barNumbers[barNumber] then
    hookedCDMFrames[frame].barNumbers[barNumber] = true
    table.insert(frameToBarMapping[frame], barNumber)
  end
end

-- Unregister a bar from a frame's hooks
local function UnhookBarFromFrame(frame, barNumber)
  if not frame or not hookedCDMFrames[frame] then return end
  
  hookedCDMFrames[frame].barNumbers[barNumber] = nil
  
  -- Rebuild the bar list for this frame
  local newList = {}
  for bn in pairs(hookedCDMFrames[frame].barNumbers) do
    table.insert(newList, bn)
  end
  frameToBarMapping[frame] = newList
end

-- Clear all bar registrations (call on spec change, reload, etc.)
local function ClearAllFrameHookRegistrations()
  for frame in pairs(hookedCDMFrames) do
    hookedCDMFrames[frame].barNumbers = {}
    frameToBarMapping[frame] = {}
  end
end

-- ===================================================================
-- LEGACY POLLING (kept for fallback/compatibility)
-- Only used for bars without direct CDM frame hooks
-- ===================================================================
local updatePollTimers = {}

local function SchedulePolls(barNumber)
  if updatePollTimers[barNumber] then
    for _, timer in ipairs(updatePollTimers[barNumber]) do
      if timer then timer:Cancel() end
    end
  end
  updatePollTimers[barNumber] = {}
  local pollTimes = {0.05, 0.1, 0.2}
  for _, delay in ipairs(pollTimes) do
    local timer = C_Timer.NewTimer(delay, function()
      UpdateBarBuffInfo(barNumber)
    end)
    table.insert(updatePollTimers[barNumber], timer)
  end
end

local function SchedulePollsForAllBars()
  if not ns.API.GetActiveBars then return end
  local activeBars = ns.API.GetActiveBars()
  for _, barNumber in ipairs(activeBars) do
    SchedulePolls(barNumber)
  end
end

-- ===================================================================
-- STATE VARIABLES
-- ===================================================================
local barStates = {}

local function GetBarState(barNumber)
  if not barStates[barNumber] then
    barStates[barNumber] = {
      cooldownID = nil,
      cachedFrame = nil,
      cachedBarFrame = nil,
      stacks = 0,
      active = false,
      trackingOK = false
    }
  end
  return barStates[barNumber]
end

-- Forward declaration for ClearBarState (needs AllowCDMFrameVisible which is defined later)
local ClearBarState

-- ===================================================================
-- CROSS-SPEC COOLDOWNID RESOLUTION SYSTEM
-- Handles bars that need to work across multiple specs where the
-- same spell has different cooldownIDs per spec
-- ===================================================================

-- Cache for spellID → cooldownID mapping (rebuilt on spec change)
local spellToCooldownIDCache = nil
local spellToCooldownIDCacheSpec = nil  -- Track which spec the cache was built for

-- Build mapping of spellID → cooldownID for current spec
-- Scans all CDM categories to find what cooldownIDs are available
local function BuildSpellToCooldownIDMapping()
  local mapping = {}
  
  if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCategorySet then
    return mapping
  end
  
  -- Scan all aura categories (TrackedBuff=2, TrackedBar=3)
  -- We only care about auras for this cross-spec feature
  local auraCategories = {2, 3}  -- Enum.CooldownViewerCategory.TrackedBuff, TrackedBar
  
  for _, category in ipairs(auraCategories) do
    local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(category, true)  -- allowUnlearned=true
    if cooldownIDs then
      for _, cdID in ipairs(cooldownIDs) do
        local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
        if info and info.spellID and info.spellID > 0 then
          -- Store mapping: spellID → cooldownID
          -- Note: A spellID might map to multiple cooldownIDs (e.g., different ranks)
          -- We store the first one found; the validation loop will find the right frame
          if not mapping[info.spellID] then
            mapping[info.spellID] = cdID
          end
          
          -- Also check linkedSpellIDs for auras that might have variant spell IDs
          if info.linkedSpellIDs then
            for _, linkedSpellID in ipairs(info.linkedSpellIDs) do
              if linkedSpellID and linkedSpellID > 0 and not mapping[linkedSpellID] then
                mapping[linkedSpellID] = cdID
              end
            end
          end
        end
      end
    end
  end
  
  return mapping
end

-- Get or rebuild the spellID → cooldownID cache
local function GetSpellToCooldownIDMapping()
  local currentSpec = GetSpecialization() or 0
  
  -- Rebuild cache if spec changed or cache is empty
  if not spellToCooldownIDCache or spellToCooldownIDCacheSpec ~= currentSpec then
    spellToCooldownIDCache = BuildSpellToCooldownIDMapping()
    spellToCooldownIDCacheSpec = currentSpec
    
    if ns.devMode then
      local count = 0
      for _ in pairs(spellToCooldownIDCache) do count = count + 1 end
      print(string.format("|cff00FF00[ArcUI]|r Built spellID→cooldownID mapping: %d entries for spec %d", count, currentSpec))
    end
  end
  
  return spellToCooldownIDCache
end

-- Invalidate the cache (call on spec change)
local function InvalidateSpellToCooldownIDCache()
  spellToCooldownIDCache = nil
  spellToCooldownIDCacheSpec = nil
end

-- Find a cooldownID for a spellID on current spec
local function FindCooldownIDForSpellID(spellID)
  if not spellID or spellID <= 0 then return nil end
  
  local mapping = GetSpellToCooldownIDMapping()
  return mapping[spellID]
end

-- Get the active (working) cooldownID for a bar
-- Tries: primary cooldownID → alternateCooldownIDs → auto-discover via spellID
-- Returns: cooldownID, sourceType ("primary", "alternate", "discovered", or nil)
function ns.API.GetActiveCooldownIDForBar(barNum, validCooldownIDs)
  local barConfig = ns.API.GetBarConfig(barNum)
  if not barConfig or not barConfig.tracking then return nil, nil end
  
  local tracking = barConfig.tracking
  local trackType = tracking.trackType
  
  -- Skip non-aura bars (cooldownCharge bars don't need this)
  if trackType == "cooldownCharge" then
    return tracking.cooldownID, "primary"
  end
  
  -- If validCooldownIDs not provided, check bar state for what's currently active
  -- This is used by UI to display which cooldownID is currently working
  if not validCooldownIDs then
    local state = barStates[barNum]
    if state and state.trackingOK and state.cooldownID then
      -- Determine if it's primary or alternate
      if state.cooldownID == tracking.cooldownID then
        return state.cooldownID, "primary"
      elseif tracking.alternateCooldownIDs then
        for _, altCdID in ipairs(tracking.alternateCooldownIDs) do
          if state.cooldownID == altCdID then
            return state.cooldownID, "alternate"
          end
        end
      end
      return state.cooldownID, "discovered"
    end
    return nil, nil
  end
  
  -- Helper to check if a cooldownID has a valid frame
  -- Uses validCooldownIDs which is built by scanning all viewers + CDMGroups containers
  local function hasValidFrame(cdID)
    if not cdID or (type(cdID) == "number" and cdID <= 0) then return false end
    
    -- Check validCooldownIDs map (built by ValidateAllBarTracking's initial scan)
    if validCooldownIDs and validCooldownIDs[cdID] then
      return true
    end
    
    return false
  end
  
  -- 1. Try primary cooldownID
  if hasValidFrame(tracking.cooldownID) then
    return tracking.cooldownID, "primary"
  end
  
  -- 2. Try alternate cooldownIDs
  if tracking.alternateCooldownIDs then
    for _, altCdID in ipairs(tracking.alternateCooldownIDs) do
      if hasValidFrame(altCdID) then
        return altCdID, "alternate"
      end
    end
  end
  
  -- 3. Auto-discover via spellID (only if bar is meant to show on this spec)
  local currentSpec = GetSpecialization() or 0
  local showOnSpecs = barConfig.behavior and barConfig.behavior.showOnSpecs
  local shouldShowOnThisSpec = false
  
  if showOnSpecs and #showOnSpecs > 0 then
    for _, spec in ipairs(showOnSpecs) do
      if spec == currentSpec then
        shouldShowOnThisSpec = true
        break
      end
    end
  else
    -- If no spec restriction, show on all specs
    shouldShowOnThisSpec = true
  end
  
  if shouldShowOnThisSpec and tracking.spellID and tracking.spellID > 0 then
    local discoveredCdID = FindCooldownIDForSpellID(tracking.spellID)
    if discoveredCdID and hasValidFrame(discoveredCdID) then
      -- Auto-add to alternateCooldownIDs for future use
      if not tracking.alternateCooldownIDs then
        tracking.alternateCooldownIDs = {}
      end
      
      -- Check if already in the list
      local alreadyExists = false
      for _, existingCdID in ipairs(tracking.alternateCooldownIDs) do
        if existingCdID == discoveredCdID then
          alreadyExists = true
          break
        end
      end
      
      -- Also check if it's the primary
      if discoveredCdID == tracking.cooldownID then
        alreadyExists = true
      end
      
      if not alreadyExists then
        table.insert(tracking.alternateCooldownIDs, discoveredCdID)
        print(string.format("|cff00ccffArc UI|r: Auto-discovered cooldownID %d for '%s' (spellID %d)", 
          discoveredCdID, tracking.buffName or "bar " .. barNum, tracking.spellID))
      end
      
      return discoveredCdID, "discovered"
    end
  end
  
  -- No valid cooldownID found
  return nil, nil
end

-- Manually add a cooldownID to a bar's alternate list
function ns.API.AddAlternateCooldownID(barNum, cooldownID)
  local barConfig = ns.API.GetBarConfig(barNum)
  if not barConfig or not barConfig.tracking then return false, "Invalid bar" end
  
  if not cooldownID or type(cooldownID) ~= "number" or cooldownID <= 0 then
    return false, "Invalid cooldownID"
  end
  
  -- Initialize if needed
  if not barConfig.tracking.alternateCooldownIDs then
    barConfig.tracking.alternateCooldownIDs = {}
  end
  
  -- Check if already exists (in primary or alternates)
  if barConfig.tracking.cooldownID == cooldownID then
    return false, "Already the primary cooldownID"
  end
  
  for _, existingCdID in ipairs(barConfig.tracking.alternateCooldownIDs) do
    if existingCdID == cooldownID then
      return false, "Already in alternate list"
    end
  end
  
  -- Add it
  table.insert(barConfig.tracking.alternateCooldownIDs, cooldownID)
  
  -- Re-validate tracking
  if ns.API.ValidateAllBarTracking then
    ns.API.ValidateAllBarTracking()
  end
  
  return true, string.format("Added cooldownID %d to bar %d", cooldownID, barNum)
end

-- Remove a cooldownID from a bar's alternate list
function ns.API.RemoveAlternateCooldownID(barNum, cooldownID)
  local barConfig = ns.API.GetBarConfig(barNum)
  if not barConfig or not barConfig.tracking then return false, "Invalid bar" end
  
  if not barConfig.tracking.alternateCooldownIDs then
    return false, "No alternate cooldownIDs"
  end
  
  for i, existingCdID in ipairs(barConfig.tracking.alternateCooldownIDs) do
    if existingCdID == cooldownID then
      table.remove(barConfig.tracking.alternateCooldownIDs, i)
      
      -- Re-validate tracking
      if ns.API.ValidateAllBarTracking then
        ns.API.ValidateAllBarTracking()
      end
      
      return true, string.format("Removed cooldownID %d from bar %d", cooldownID, barNum)
    end
  end
  
  return false, "CooldownID not found in alternate list"
end

-- Get all cooldownIDs for a bar (primary + alternates)
function ns.API.GetAllCooldownIDsForBar(barNum)
  local barConfig = ns.API.GetBarConfig(barNum)
  if not barConfig or not barConfig.tracking then return {} end
  
  local result = {}
  
  -- Add primary
  if barConfig.tracking.cooldownID and barConfig.tracking.cooldownID > 0 then
    table.insert(result, {
      cooldownID = barConfig.tracking.cooldownID,
      isPrimary = true,
      isActive = false  -- Will be set by caller if needed
    })
  end
  
  -- Add alternates
  if barConfig.tracking.alternateCooldownIDs then
    for _, cdID in ipairs(barConfig.tracking.alternateCooldownIDs) do
      table.insert(result, {
        cooldownID = cdID,
        isPrimary = false,
        isActive = false
      })
    end
  end
  
  return result
end

-- Expose cache invalidation for spec change handlers
ns.API.InvalidateSpellToCooldownIDCache = InvalidateSpellToCooldownIDCache

-- ===================================================================
-- CDM ICON HIDING SYSTEM
-- ===================================================================
local hiddenCDMFrames = {}  -- [frame] = expectedCooldownID
local hiddenByBarOverlays = {}  -- [frame] = overlayFrame

-- Helper to get frame's current cooldownID
local function GetFrameCooldownID(frame)
  if not frame then return nil end
  local cdID = frame.cooldownID
  if not cdID and frame.cooldownInfo then
    cdID = frame.cooldownInfo.cooldownID
  end
  if not cdID and frame.Icon and frame.Icon.cooldownID then
    cdID = frame.Icon.cooldownID
  end
  return cdID
end

-- Helper to clean up hiding state from a frame (overlay, flags, tracking table)
local function CleanupFrameHidingState(frame)
  if not frame then return end
  hiddenCDMFrames[frame] = nil
  frame._arcHiddenByBar = nil
  frame._arcHiddenByBarCdID = nil
  if hiddenByBarOverlays[frame] then
    hiddenByBarOverlays[frame]:Hide()
    hiddenByBarOverlays[frame] = nil
  end
end

-- Helper to find a CDM frame by cooldownID across all viewers,
-- CDMGroups containers (reparented frames), and free icons.
local function FindCDMFrameForCooldownID(targetCdID)
  if not targetCdID then return nil end
  
  -- 1. CDMGroups members (frames reparented into group containers by FrameController)
  if ns.CDMGroups and ns.CDMGroups.groups then
    for _, group in pairs(ns.CDMGroups.groups) do
      if group.members then
        local member = group.members[targetCdID]
        if member and member.frame then
          return member.frame
        end
      end
    end
  end
  
  -- 2. CDMGroups free icons (frames reparented to UIParent by FrameController)
  if ns.CDMGroups and ns.CDMGroups.freeIcons then
    local freeData = ns.CDMGroups.freeIcons[targetCdID]
    if freeData and freeData.frame then
      return freeData.frame
    end
  end
  
  -- 3. Standard CDM viewer children (frames NOT reparented)
  local viewerNames = {"BuffIconCooldownViewer", "BuffBarCooldownViewer",
                       "CooldownIconCooldownViewer", "CooldownBarCooldownViewer"}
  for _, vName in ipairs(viewerNames) do
    local viewer = _G[vName]
    if viewer then
      local children = {viewer:GetChildren()}
      for _, child in ipairs(children) do
        local cdID = child.cooldownID
        if not cdID and child.cooldownInfo then
          cdID = child.cooldownInfo.cooldownID
        end
        if not cdID and child.Icon and child.Icon.cooldownID then
          cdID = child.Icon.cooldownID
        end
        if cdID == targetCdID then
          return child
        end
      end
    end
  end
  
  return nil
end

-- Refresh hidden CDM frames: detect stale entries where CDM recycled a frame,
-- clean them up, and re-scan viewers to find the new frame for that cooldownID.
-- Called before options open/close and from FrameController on SetCooldownID.
local function RefreshHiddenCDMFrames()
  -- Collect stale entries: frame's cdID no longer matches what we intended to hide
  local staleEntries = {}  -- { {frame=, expectedCdID=}, ... }
  for frame, expectedCdID in pairs(hiddenCDMFrames) do
    local frameCdID = GetFrameCooldownID(frame)
    -- Stale if: frame cdID is nil (cleared/released) OR changed to different spell
    if expectedCdID and (not frameCdID or frameCdID ~= expectedCdID) then
      staleEntries[#staleEntries + 1] = { frame = frame, expectedCdID = expectedCdID }
    end
  end
  
  if #staleEntries == 0 then return end
  
  -- Clean up stale entries and re-find correct frames
  for _, entry in ipairs(staleEntries) do
    -- Release the old (wrong) frame
    CleanupFrameHidingState(entry.frame)
    entry.frame:Show()  -- Let CDM show it again
    
    -- Find the new frame for that cooldownID
    local newFrame = FindCDMFrameForCooldownID(entry.expectedCdID)
    if newFrame and not hiddenCDMFrames[newFrame] then
      -- Apply hide to the correct frame
      hiddenCDMFrames[newFrame] = entry.expectedCdID
      if ns._arcUIOptionsOpen then
        -- Options open: show with overlay
        newFrame._arcHiddenByBar = nil
        newFrame._arcHiddenByBarCdID = nil
        newFrame:Show()
        if not hiddenByBarOverlays[newFrame] then
          local overlay = CreateFrame("Frame", nil, newFrame)
          overlay:SetAllPoints(newFrame)
          overlay:SetFrameLevel(newFrame:GetFrameLevel() + 10)
          overlay.tint = overlay:CreateTexture(nil, "OVERLAY")
          overlay.tint:SetAllPoints()
          overlay.tint:SetColorTexture(0.9, 0.1, 0.1, 0.6)
          overlay.text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
          overlay.text:SetPoint("CENTER", 0, 0)
          overlay.text:SetText("Hidden")
          overlay.text:SetTextColor(1, 1, 1, 1)
          hiddenByBarOverlays[newFrame] = overlay
        end
        hiddenByBarOverlays[newFrame]:Show()
      else
        -- Options closed: hide with flags
        newFrame._arcHiddenByBar = true
        newFrame._arcHiddenByBarCdID = entry.expectedCdID
        newFrame:Hide()
      end
    end
  end
end

local function ForceHideCDMFrame(frame, expectedCooldownID)
  if not frame then return end
  
  -- Require expectedCooldownID - without it we can't verify the frame is correct
  if not expectedCooldownID then return end
  
  -- Verify frame's current cooldownID matches what we expect
  -- CRITICAL: If frameCdID is nil (frame cleared during CDM reshuffle),
  -- we MUST NOT hide it - the bar update ticker would re-add stale entries.
  local frameCdID = GetFrameCooldownID(frame)
  if not frameCdID then return end  -- Can't confirm match, skip
  if frameCdID ~= expectedCooldownID then
    -- Frame was recycled for a different cooldown - clean up any stale state
    CleanupFrameHidingState(frame)
    return
  end
  
  -- DEDUP: If a DIFFERENT frame is already tracked for this same cooldownID,
  -- clean it up. CDM options panel drags can reassign cooldownIDs without
  -- firing SetCooldownID/ClearCooldownID, leaving stale entries behind.
  for existingFrame, existingCdID in pairs(hiddenCDMFrames) do
    if existingCdID == expectedCooldownID and existingFrame ~= frame then
      CleanupFrameHidingState(existingFrame)
      existingFrame:Show()  -- Let CDM show the now-unrelated frame
      break  -- Only one duplicate possible per cooldownID
    end
  end
  
  hiddenCDMFrames[frame] = expectedCooldownID
  
  -- If options panel is open, Show with overlay so user can see what's hidden
  -- Don't set _arcHiddenByBar here - the Show hook would re-hide it
  -- HideAllHiddenByBarOverlays will set the flag when options close
  if ns._arcUIOptionsOpen then
    frame._arcHiddenByBar = nil
    frame._arcHiddenByBarCdID = nil
    frame:Show()
    
    -- Create/show overlay
    if not hiddenByBarOverlays[frame] then
      local overlay = CreateFrame("Frame", nil, frame)
      overlay:SetAllPoints(frame)
      overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
      
      -- Red tint texture
      overlay.tint = overlay:CreateTexture(nil, "OVERLAY")
      overlay.tint:SetAllPoints()
      overlay.tint:SetColorTexture(0.9, 0.1, 0.1, 0.6)
      
      -- "Hidden" text
      overlay.text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      overlay.text:SetPoint("CENTER", 0, 0)
      overlay.text:SetText("Hidden")
      overlay.text:SetTextColor(1, 1, 1, 1)
      
      hiddenByBarOverlays[frame] = overlay
    end
    hiddenByBarOverlays[frame]:Show()
  else
    -- Set shared flags BEFORE Hide - CDMEnhance Show hook verifies these
    frame._arcHiddenByBar = true
    frame._arcHiddenByBarCdID = expectedCooldownID
    frame:Hide()
    -- Hide overlay if it exists
    if hiddenByBarOverlays[frame] then
      hiddenByBarOverlays[frame]:Hide()
    end
  end
end

local function AllowCDMFrameVisible(frame)
  if not frame then return end
  if not hiddenCDMFrames[frame] then return end
  CleanupFrameHidingState(frame)
  frame:Show()
end

-- Called when options panel closes to re-hide all frames
local function HideAllHiddenByBarOverlays()
  -- Refresh first: fix any stale entries from CDM frame recycling
  RefreshHiddenCDMFrames()
  
  for frame, overlay in pairs(hiddenByBarOverlays) do
    overlay:Hide()
  end
  -- Re-apply Hide to all tracked frames
  for frame, expectedCdID in pairs(hiddenCDMFrames) do
    frame._arcHiddenByBar = true
    frame._arcHiddenByBarCdID = expectedCdID
    frame:Hide()
  end
end

-- Called when options panel opens to show overlays on already-hidden frames
local function ShowAllHiddenByBarOverlays()
  -- Refresh first: fix any stale entries from CDM frame recycling
  RefreshHiddenCDMFrames()
  
  for frame, _ in pairs(hiddenCDMFrames) do
    frame._arcHiddenByBar = nil  -- Clear so Show hook doesn't re-hide
    frame._arcHiddenByBarCdID = nil
    frame:Show()
    -- Create overlay if needed
    if not hiddenByBarOverlays[frame] then
      local overlay = CreateFrame("Frame", nil, frame)
      overlay:SetAllPoints(frame)
      overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
      
      overlay.tint = overlay:CreateTexture(nil, "OVERLAY")
      overlay.tint:SetAllPoints()
      overlay.tint:SetColorTexture(0.9, 0.1, 0.1, 0.6)
      
      -- "Hidden" text - fully opaque
      overlay.text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      overlay.text:SetPoint("CENTER", 0, 0)
      overlay.text:SetText("Hidden")
      overlay.text:SetTextColor(1, 1, 1, 1)
      
      hiddenByBarOverlays[frame] = overlay
    end
    hiddenByBarOverlays[frame]:Show()
  end
end

-- Expose for Options.lua and FrameController
ns.API = ns.API or {}
ns.API.ShowHiddenByBarOverlays = ShowAllHiddenByBarOverlays
ns.API.HideHiddenByBarOverlays = HideAllHiddenByBarOverlays
ns.API.RefreshHiddenCDMFrames = RefreshHiddenCDMFrames
-- Expose internal tables for ArcUI_Debugger OverlayInspector (accessed via ArcUI_NS)
ns.API._hiddenCDMFrames = hiddenCDMFrames
ns.API._hiddenByBarOverlays = hiddenByBarOverlays
ns.API._GetFrameCooldownID = GetFrameCooldownID
ns.API._FindCDMFrameForCooldownID = FindCDMFrameForCooldownID

-- Now define ClearBarState (needs AllowCDMFrameVisible)
ClearBarState = function(barNumber)
  local state = barStates[barNumber]
  if state then
    -- Restore visibility of any CDM frames that were hidden by this bar
    if state.cachedFrame then
      AllowCDMFrameVisible(state.cachedFrame)
    end
    if state.cachedBarFrame then
      AllowCDMFrameVisible(state.cachedBarFrame)
    end
  end
  barStates[barNumber] = nil
end

local function IsOptionsOpen()
  local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
  if AceConfigDialog and AceConfigDialog.OpenFrames then
    for appName, _ in pairs(AceConfigDialog.OpenFrames) do
      if appName == "ArcUI" then return true end
    end
  end
  return false
end

-- ===================================================================
-- CUSTOM CAST TRACKING SYSTEM
-- ===================================================================
local customBarStates = {}

local function GetCustomBarState(barNumber)
  if not customBarStates[barNumber] then
    customBarStates[barNumber] = { stacks = 0, expirationTime = 0, active = false }
  end
  return customBarStates[barNumber]
end

local function UpdateCustomBarDisplay(barNumber)
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig or not barConfig.tracking.customEnabled then return end
  
  local state = GetCustomBarState(barNumber)
  local currentTime = GetTime()
  
  if state.expirationTime > 0 and currentTime >= state.expirationTime then
    state.stacks = 0
    state.active = false
    state.expirationTime = 0
  end
  
  local remainingDuration = 0
  if state.active and state.expirationTime > 0 then
    remainingDuration = state.expirationTime - currentTime
    if remainingDuration < 0 then remainingDuration = 0 end
  end
  
  local iconTexture = nil
  local customSpellID = barConfig.tracking.customSpellID
  if customSpellID and customSpellID > 0 then
    iconTexture = C_Spell.GetSpellTexture(customSpellID)
  end
  
  if ns.Display and ns.Display.UpdateCustomBar then
    local maxStacks = barConfig.tracking.customMaxStacks or 10
    ns.Display.UpdateCustomBar(barNumber, state.stacks, maxStacks, state.active, remainingDuration, iconTexture)
  elseif ns.Display and ns.Display.UpdateBar then
    local maxStacks = barConfig.tracking.customMaxStacks or 10
    ns.Display.UpdateBar(barNumber, state.stacks, maxStacks, state.active, nil, iconTexture)
  end
end

local function ProcessCustomCast(spellID)
  local db = ns.API.GetDB()
  if not db or not db.bars then return end
  
  for barNum = 1, 30 do
    local barConfig = db.bars[barNum]
    if barConfig and barConfig.tracking and barConfig.tracking.customEnabled then
      local customSpellID = barConfig.tracking.customSpellID
      if customSpellID and customSpellID == spellID then
        local state = GetCustomBarState(barNum)
        local tracking = barConfig.tracking
        
        local stacksPerCast = tracking.customStacksPerCast or 1
        local maxStacks = tracking.customMaxStacks or 10
        local duration = tracking.customDuration or 10
        local refreshMode = tracking.customRefreshMode or "add"
        
        if refreshMode == "refresh" then
          state.stacks = stacksPerCast
        else
          state.stacks = math.min(state.stacks + stacksPerCast, maxStacks)
        end
        
        state.expirationTime = GetTime() + duration
        state.active = true
        UpdateCustomBarDisplay(barNum)
      end
    end
  end
end

local customBarTicker = nil

local function StartCustomBarTicker()
  if customBarTicker then return end
  -- PERFORMANCE TEST: Changed from 0.2s to 0.5s (2/sec instead of 5/sec)
  customBarTicker = C_Timer.NewTicker(0.5, function()
    local db = ns.API.GetDB()
    if not db or not db.bars then return end
    
    local hasActiveCustomBars = false
    for barNum = 1, 30 do
      local barConfig = db.bars[barNum]
      if barConfig and barConfig.tracking and barConfig.tracking.customEnabled then
        local state = GetCustomBarState(barNum)
        if state.active then
          hasActiveCustomBars = true
          UpdateCustomBarDisplay(barNum)
        end
      end
    end
    
    if not hasActiveCustomBars then
      if customBarTicker then
        customBarTicker:Cancel()
        customBarTicker = nil
      end
    end
  end)
end

local customEventFrame = CreateFrame("Frame")
customEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
customEventFrame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
  if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
    ProcessCustomCast(spellID)
    StartCustomBarTicker()
  end
end)

function ns.API.TriggerCustomCast(spellID)
  ProcessCustomCast(spellID)
  StartCustomBarTicker()
end

-- ===================================================================
-- DURATION BAR TICKER
-- ===================================================================
local durationBarTicker = nil

local function UpdateDurationBars()
  local db = ns.API.GetDB()
  if not db or not db.bars then return end
  
  local hasActiveDurationBars = false
  for barNum = 1, 30 do
    local barConfig = db.bars[barNum]
    if barConfig and barConfig.tracking and barConfig.tracking.enabled then
      -- Update if:
      -- 1. Duration bar mode (useDurationBar = true), OR
      -- 2. Stack bar with showDuration (any source type), OR
      -- 3. Cooldown charge bar with showDuration (needs polling for cooldown countdown), OR
      -- 4. Any bar with trackedSpellID set (needs polling for correct duration), OR
      -- 5. Icon with iconShowDuration enabled (note: different from bar's showDuration!)
      local trackedSpellID = barConfig.tracking.trackedSpellID
      local hasTrackedSpell = trackedSpellID and trackedSpellID > 0
      local isIconWithDuration = barConfig.display.displayType == "icon" and barConfig.display.iconShowDuration
      local isBarWithDuration = barConfig.display.displayType == "bar" and barConfig.display.showDuration
      
      local needsPolling = barConfig.tracking.useDurationBar or 
                           isBarWithDuration or
                           (barConfig.tracking.trackType == "cooldownCharge" and barConfig.display.showDuration) or
                           hasTrackedSpell or
                           isIconWithDuration
      if needsPolling then
        local state = GetBarState(barNum)
        local trackType = barConfig.tracking.trackType
        
        -- CooldownCharge bars: always update and keep ticker alive
        if trackType == "cooldownCharge" then
          hasActiveDurationBars = true
          UpdateBarBuffInfo(barNum)
        elseif state.active or hasTrackedSpell then
          -- Also keep polling if trackedSpellID is set (might need to re-cache)
          hasActiveDurationBars = true
          UpdateBarBuffInfo(barNum)
        end
      end
    end
  end
  return hasActiveDurationBars
end

local function StartDurationBarTicker()
  if durationBarTicker then return end
  -- PERFORMANCE TEST: Changed from 0.12s to 0.5s (2/sec instead of 8/sec)
  durationBarTicker = C_Timer.NewTicker(0.5, function()
    local hasActive = UpdateDurationBars()
    if not hasActive then
      if durationBarTicker then
        durationBarTicker:Cancel()
        durationBarTicker = nil
      end
    end
  end)
end

local function StopDurationBarTicker()
  if durationBarTicker then
    durationBarTicker:Cancel()
    durationBarTicker = nil
  end
end

ns.API.StartDurationBarTicker = StartDurationBarTicker
ns.API.StopDurationBarTicker = StopDurationBarTicker

function ns.API.ResetCustomBar(barNumber)
  local state = GetCustomBarState(barNumber)
  state.stacks = 0
  state.expirationTime = 0
  state.active = false
  UpdateCustomBarDisplay(barNumber)
end

function ns.API.GetCustomBarState(barNumber)
  return GetCustomBarState(barNumber)
end

-- ===================================================================
-- DATABASE ACCESS
-- ===================================================================
function ns.API.GetDB()
  return ns.db and ns.db.char
end

function ns.API.GetGlobalDB()
  return ns.db and ns.db.global
end

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================
local function GetAllBuffFrames()
  local viewer = _G["BuffIconCooldownViewer"]
  if not viewer then return {}, "BuffIconCooldownViewer not found" end
  local allFrames = {}
  local seenFrames = {}  -- Track frames we've already added
  local seenCdIDs = {}   -- Track cooldownIDs we've found
  
  -- 1. Scan direct children of BuffIconCooldownViewer
  local children = {viewer:GetChildren()}
  for _, child in ipairs(children) do
    local cdID = child.cooldownID or (child.cooldownInfo and child.cooldownInfo.cooldownID)
    -- Handle both numeric CDM IDs and string Arc Aura IDs
    local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
    if isValidCdID then
      table.insert(allFrames, child)
      seenFrames[child] = true
      seenCdIDs[cdID] = true
    end
  end
  
  -- 2. Check _customIcons
  if viewer._customIcons then
    for _, icon in pairs(viewer._customIcons) do
      if not seenFrames[icon] then
        local cdID = icon.cooldownID or (icon.cooldownInfo and icon.cooldownInfo.cooldownID)
        -- Handle both numeric CDM IDs and string Arc Aura IDs
        local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
        if isValidCdID then
          table.insert(allFrames, icon)
          seenFrames[icon] = true
          seenCdIDs[cdID] = true
        end
      end
    end
  end
  
  -- 3. Include detached frames (reparented to UIParent for free positioning)
  if ns.CDMEnhance and ns.CDMEnhance.GetDetachedFrames then
    local detached = ns.CDMEnhance.GetDetachedFrames()
    for cdID, data in pairs(detached) do
      if data.viewerType == "aura" and data.frame and not seenFrames[data.frame] then
        if data.viewerName == "BuffIconCooldownViewer" or data.frame._arcOriginalParent == viewer then
          if not seenCdIDs[cdID] then
            table.insert(allFrames, data.frame)
            seenFrames[data.frame] = true
            seenCdIDs[cdID] = true
          end
        end
      end
    end
  end
  
  -- 4. FALLBACK: Search enhancedFrames for any aura frames we might have missed
  if ns.CDMEnhance then
    local enhancedFrames = ns.CDMEnhance.GetEnhancedFrames and ns.CDMEnhance.GetEnhancedFrames()
    if enhancedFrames then
      for cdID, data in pairs(enhancedFrames) do
        if data.viewerType == "aura" and data.frame and not seenFrames[data.frame] then
          -- CRITICAL: Use cdID (the key) not data.frame.cooldownID
          -- frame.cooldownID might be nil but the key is always valid
          -- Handle both numeric CDM IDs and string Arc Aura IDs
          local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
          if isValidCdID and not seenCdIDs[cdID] then
            table.insert(allFrames, data.frame)
            seenFrames[data.frame] = true
            seenCdIDs[cdID] = true
          end
        end
      end
    end
    
    -- 5. Also check freePositionFrames - CRITICAL: use cdID key, not frame.cooldownID
    local freeFrames = ns.CDMEnhance.GetFreePositionFrames and ns.CDMEnhance.GetFreePositionFrames()
    if freeFrames then
      for cdID, frame in pairs(freeFrames) do
        if frame and not seenFrames[frame] then
          -- Verify it's an aura frame (originally from BuffIconCooldownViewer)
          local origParent = frame._arcOriginalParent
          if origParent == viewer or (origParent and origParent:GetName() == "BuffIconCooldownViewer") then
            -- Use cdID (our tracking key), not frame.cooldownID
            -- Handle both numeric CDM IDs and string Arc Aura IDs
            local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
            if isValidCdID and not seenCdIDs[cdID] then
              table.insert(allFrames, frame)
              seenFrames[frame] = true
              seenCdIDs[cdID] = true
            end
          end
        end
      end
    end
  end
  
  return allFrames, nil
end

local function GetAllBarFrames()
  local viewer = _G["BuffBarCooldownViewer"]
  if not viewer then return {}, "BuffBarCooldownViewer not found" end
  local allFrames = {}
  local seenFrames = {}
  local seenCdIDs = {}
  
  -- 1. Scan direct children of BuffBarCooldownViewer
  local children = {viewer:GetChildren()}
  for _, child in ipairs(children) do
    local cdID = child.cooldownID
    if not cdID and child.cooldownInfo then
      cdID = child.cooldownInfo.cooldownID
    end
    if not cdID and child.Icon and child.Icon.cooldownID then
      cdID = child.Icon.cooldownID
    end
    -- Handle both numeric CDM IDs and string Arc Aura IDs
    local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
    if isValidCdID then
      table.insert(allFrames, child)
      seenFrames[child] = true
      seenCdIDs[cdID] = true
    end
  end
  
  -- 2. Include detached frames (reparented to UIParent for free positioning)
  if ns.CDMEnhance and ns.CDMEnhance.GetDetachedFrames then
    local detached = ns.CDMEnhance.GetDetachedFrames()
    for cdID, data in pairs(detached) do
      if data.frame and not seenFrames[data.frame] then
        -- Check if this was originally from BuffBarCooldownViewer
        if data.viewerName == "BuffBarCooldownViewer" or data.frame._arcOriginalParent == viewer then
          table.insert(allFrames, data.frame)
          seenFrames[data.frame] = true
          seenCdIDs[cdID] = true
        end
      end
    end
  end
  
  -- 3. FALLBACK: Search enhancedFrames for any bar frames we might have missed
  if ns.CDMEnhance then
    local enhancedFrames = ns.CDMEnhance.GetEnhancedFrames and ns.CDMEnhance.GetEnhancedFrames()
    if enhancedFrames then
      for cdID, data in pairs(enhancedFrames) do
        if data.frame and not seenFrames[data.frame] then
          local origParent = data.frame._arcOriginalParent or data.frame:GetParent()
          if origParent == viewer or (origParent and origParent:GetName() == "BuffBarCooldownViewer") then
            -- CRITICAL: Use cdID (the key) not frame.cooldownID
            -- Handle both numeric CDM IDs and string Arc Aura IDs
            local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
            if isValidCdID and not seenCdIDs[cdID] then
              table.insert(allFrames, data.frame)
              seenFrames[data.frame] = true
              seenCdIDs[cdID] = true
            end
          end
        end
      end
    end
  end
  
  return allFrames, nil
end

-- Get cooldown frames from Essential and Utility viewers (for cooldown charge tracking)
local function GetAllCooldownFrames()
  local allFrames = {}
  local seenFrames = {}
  local seenCdIDs = {}
  
  -- Essential cooldowns
  local essential = _G["EssentialCooldownViewer"]
  if essential then
    local children = {essential:GetChildren()}
    for _, child in ipairs(children) do
      local cdID = child.cooldownID
      -- Handle both numeric CDM IDs and string Arc Aura IDs
      local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
      if isValidCdID then
        table.insert(allFrames, child)
        seenFrames[child] = true
        seenCdIDs[cdID] = true
      end
    end
  end
  
  -- Utility cooldowns
  local utility = _G["UtilityCooldownViewer"]
  if utility then
    local children = {utility:GetChildren()}
    for _, child in ipairs(children) do
      local cdID = child.cooldownID
      -- Handle both numeric CDM IDs and string Arc Aura IDs
      local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
      if isValidCdID and not seenFrames[child] then
        table.insert(allFrames, child)
        seenFrames[child] = true
        seenCdIDs[cdID] = true
      end
    end
  end
  
  -- Include detached frames (reparented to UIParent for free positioning)
  if ns.CDMEnhance and ns.CDMEnhance.GetDetachedFrames then
    local detached = ns.CDMEnhance.GetDetachedFrames()
    for cdID, data in pairs(detached) do
      if data.frame and not seenFrames[data.frame] then
        if data.viewerType == "cooldown" then
          -- Check if originally from EssentialCooldownViewer
          if data.viewerName == "EssentialCooldownViewer" or data.frame._arcOriginalParent == essential then
            table.insert(allFrames, data.frame)
            seenFrames[data.frame] = true
            seenCdIDs[cdID] = true
          end
        elseif data.viewerType == "utility" then
          -- Check if originally from UtilityCooldownViewer
          if data.viewerName == "UtilityCooldownViewer" or data.frame._arcOriginalParent == utility then
            table.insert(allFrames, data.frame)
            seenFrames[data.frame] = true
            seenCdIDs[cdID] = true
          end
        end
      end
    end
  end
  
  -- FALLBACK: Search enhancedFrames for any cooldown/utility frames we might have missed
  if ns.CDMEnhance then
    local enhancedFrames = ns.CDMEnhance.GetEnhancedFrames and ns.CDMEnhance.GetEnhancedFrames()
    if enhancedFrames then
      for cdID, data in pairs(enhancedFrames) do
        if (data.viewerType == "cooldown" or data.viewerType == "utility") and data.frame and not seenFrames[data.frame] then
          -- CRITICAL: Use cdID (the key) not frame.cooldownID
          -- Handle both numeric CDM IDs and string Arc Aura IDs
          local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
          if isValidCdID and not seenCdIDs[cdID] then
            table.insert(allFrames, data.frame)
            seenFrames[data.frame] = true
            seenCdIDs[cdID] = true
          end
        end
      end
    end
    
    -- Also check freePositionFrames
    local freeFrames = ns.CDMEnhance.GetFreePositionFrames and ns.CDMEnhance.GetFreePositionFrames()
    if freeFrames then
      for cdID, frame in pairs(freeFrames) do
        if frame and not seenFrames[frame] then
          local frameCdID = frame.cooldownID
          -- Verify it's a cooldown/utility frame
          local origParent = frame._arcOriginalParent
          local origParentName = origParent and origParent:GetName()
          if origParentName == "EssentialCooldownViewer" or origParentName == "UtilityCooldownViewer" then
            -- Handle both numeric CDM IDs and string Arc Aura IDs
            local isValidCdID = frameCdID and ((type(frameCdID) == "number" and frameCdID > 0) or type(frameCdID) == "string")
            if isValidCdID and not seenCdIDs[frameCdID] then
              table.insert(allFrames, frame)
              seenFrames[frame] = true
              seenCdIDs[frameCdID] = true
            end
          end
        end
      end
    end
  end
  
  return allFrames
end

local function FindBarFrameByCooldownID(cooldownID)
  if not cooldownID then return nil end
  local frames, err = GetAllBarFrames()
  if err then return nil end
  for _, frame in ipairs(frames) do
    -- Try multiple sources for cooldownID
    local frameCdID = frame.cooldownID
    if not frameCdID and frame.cooldownInfo then
      frameCdID = frame.cooldownInfo.cooldownID
    end
    if not frameCdID and frame.Icon and frame.Icon.cooldownID then
      frameCdID = frame.Icon.cooldownID
    end
    if frameCdID == cooldownID then return frame end
  end
  
  -- FALLBACK: Direct scan of BuffBarCooldownViewer
  local viewer = _G["BuffBarCooldownViewer"]
  if viewer then
    local children = {viewer:GetChildren()}
    for _, child in ipairs(children) do
      local frameCdID = child.cooldownID
      if not frameCdID and child.cooldownInfo then
        frameCdID = child.cooldownInfo.cooldownID
      end
      if not frameCdID and child.Icon and child.Icon.cooldownID then
        frameCdID = child.Icon.cooldownID
      end
      if frameCdID == cooldownID then return child end
    end
  end
  
  return nil
end

local function FindBuffFrameByCooldownID(cooldownID)
  if not cooldownID then return nil end
  
  -- SIMPLE: Use CDMEnhance.FindFrameByCooldownID if available
  if ns.CDMEnhance and ns.CDMEnhance.FindFrameByCooldownID then
    local frame, vType, viewerName = ns.CDMEnhance.FindFrameByCooldownID(cooldownID, "aura")
    if frame and frame.cooldownID == cooldownID then
      return frame
    end
  end
  
  -- Scan BuffIconCooldownViewer children
  local viewer = _G["BuffIconCooldownViewer"]
  if viewer then
    local children = {viewer:GetChildren()}
    for _, child in ipairs(children) do
      local frameCdID = child.cooldownID
      if not frameCdID and child.cooldownInfo then
        frameCdID = child.cooldownInfo.cooldownID
      end
      if frameCdID == cooldownID then return child end
    end
  end
  
  -- Check enhanced frames (includes detached ones)
  if ns.CDMEnhance then
    local enhancedFrames = ns.CDMEnhance.GetEnhancedFrames and ns.CDMEnhance.GetEnhancedFrames()
    if enhancedFrames then
      -- Direct key lookup - verify frame's actual cooldownID matches (frame may be recycled)
      local data = enhancedFrames[cooldownID]
      if data and data.frame then
        local frameCdID = data.frame.cooldownID
        if not frameCdID and data.frame.cooldownInfo then
          frameCdID = data.frame.cooldownInfo.cooldownID
        end
        if frameCdID == cooldownID then
          return data.frame
        end
      end
      
      -- Fallback: Scan all frames checking frame.cooldownID property
      for cdID, frameData in pairs(enhancedFrames) do
        if frameData.frame and frameData.frame.cooldownID == cooldownID then
          return frameData.frame
        end
      end
    end
  end
  
  -- Scan CDMGroups containers (frames reparented for grouping)
  if ns.CDMGroups and ns.CDMGroups.GetAllGroupedFrames then
    local groupedFrames = ns.CDMGroups.GetAllGroupedFrames()
    if groupedFrames then
      local data = groupedFrames[cooldownID]
      if data and data.frame then
        local frameCdID = data.frame.cooldownID
        if not frameCdID and data.frame.cooldownInfo then
          frameCdID = data.frame.cooldownInfo.cooldownID
        end
        if frameCdID == cooldownID then
          return data.frame
        end
      end
    end
  end
  
  return nil
end

-- Find cooldown frame from Essential/Utility viewers by cooldownID
local function FindCooldownFrameByCooldownID(cooldownID)
  if not cooldownID then return nil end
  local frames = GetAllCooldownFrames()
  for _, frame in ipairs(frames) do
    if frame.cooldownID == cooldownID then return frame end
  end
  return nil
end

local function GetBuffStacks(frame, unit)
  if not frame or not frame.auraInstanceID then return 0 end
  unit = unit or "player"
  local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, frame.auraInstanceID)
  if not auraData then return 0 end
  return auraData.applications or 0
end

-- Auto-detect which unit has the aura and return data + unit
-- Tries player first (buffs), then target (debuffs)
local function GetAuraDataAutoUnit(auraInstanceID)
  if not auraInstanceID then return nil, nil end
  
  -- Try player first (most common for buffs)
  local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
  if auraData then return auraData, "player" end
  
  -- Try target (for debuffs)
  auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("target", auraInstanceID)
  if auraData then return auraData, "target" end
  
  return nil, nil
end

-- ===================================================================
-- API: SCAN AND VALIDATE
-- ===================================================================
function ns.API.ScanAvailableBuffs()
  if InCombatLockdown() then return nil, "Cannot scan in combat" end
  
  local frames, err = GetAllBuffFrames()
  if err then return nil, err end
  
  local availableBuffs = {}
  local seenNames = {}
  local validCooldownIDs = {}
  
  for slotNum, frame in ipairs(frames) do
    -- Try multiple sources for cooldownID
    local cdID = frame and frame.cooldownID
    if not cdID and frame and frame.cooldownInfo then
      cdID = frame.cooldownInfo.cooldownID
    end
    
    if cdID then
      -- Get spell info from API (same approach as ScanAllCDMIcons)
      local spellID, spellName, iconTextureID
      local info = type(cdID) == "number" and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
      
      if info then
        local baseSpellID = info.spellID or 0
        local overrideSpellID = info.overrideSpellID
        local linkedSpellIDs = info.linkedSpellIDs
        local firstLinkedSpellID = linkedSpellIDs and linkedSpellIDs[1]
        
        -- Priority: first linkedSpellID > overrideSpellID > baseSpellID
        local displaySpellID = firstLinkedSpellID or overrideSpellID or baseSpellID
        
        spellID = displaySpellID or baseSpellID
        spellName = displaySpellID and C_Spell.GetSpellName(displaySpellID)
        iconTextureID = displaySpellID and C_Spell.GetSpellTexture(displaySpellID)
        
        -- Fallbacks
        if not spellName and overrideSpellID then
          spellName = C_Spell.GetSpellName(overrideSpellID)
          iconTextureID = iconTextureID or C_Spell.GetSpellTexture(overrideSpellID)
        end
        if not spellName and baseSpellID > 0 then
          spellName = C_Spell.GetSpellName(baseSpellID)
          iconTextureID = iconTextureID or C_Spell.GetSpellTexture(baseSpellID)
        end
      end
      
      -- Fallback to frame.cooldownInfo if API didn't work
      if not spellName and frame.cooldownInfo then
        spellID = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
        if spellID and spellID > 0 then
          spellName = C_Spell.GetSpellName(spellID)
          iconTextureID = C_Spell.GetSpellTexture(spellID)
        end
      end
      
      if spellName then
        validCooldownIDs[cdID] = true
        if not seenNames[spellName] then
          seenNames[spellName] = true
          table.insert(availableBuffs, {
            slotNumber = slotNum,
            buffName = spellName,
            spellID = spellID,
            iconTextureID = iconTextureID or 134400,
            cooldownID = cdID,
            maxStacks = 10,
            isActive = frame.auraInstanceID ~= nil
          })
        end
      end
    end
  end
  
  ns.API.ValidateAllBarTracking(validCooldownIDs)
  return availableBuffs
end

function ns.API.ValidateAllBarTracking(validCooldownIDs, debugMode)
  -- Build comprehensive list of valid cooldownIDs from ALL sources
  if not validCooldownIDs then
    validCooldownIDs = {}
  end
  
  local debugPrint = debugMode and print or function() end
  
  debugPrint("|cff00CCFF[ValidateAllBarTracking]|r Starting validation...")
  
  -- 1. Scan BuffIconCooldownViewer (icons)
  local iconFrames, err = GetAllBuffFrames()
  if not err then
    local count = 0
    for _, frame in ipairs(iconFrames) do
      local cdID = frame and frame.cooldownID
      if not cdID and frame and frame.cooldownInfo then
        cdID = frame.cooldownInfo.cooldownID
      end
      -- Handle both numeric CDM IDs and string Arc Aura IDs
      local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
      if isValidCdID then
        validCooldownIDs[cdID] = validCooldownIDs[cdID] == "bar" and "both" or "icon"
        count = count + 1
      end
    end
    debugPrint(string.format("  Step 1 (GetAllBuffFrames): Added %d icon frames", count))
  end
  
  -- 2. Scan BuffBarCooldownViewer (bars)
  local barFrames, err2 = GetAllBarFrames()
  if not err2 then
    for _, frame in ipairs(barFrames) do
      local cdID = frame and frame.cooldownID
      if not cdID and frame and frame.cooldownInfo then
        cdID = frame.cooldownInfo.cooldownID
      end
      if not cdID and frame and frame.Icon and frame.Icon.cooldownID then
        cdID = frame.Icon.cooldownID
      end
      -- Handle both numeric CDM IDs and string Arc Aura IDs
      local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
      if isValidCdID then
        if validCooldownIDs[cdID] == "icon" then
          validCooldownIDs[cdID] = "both"
        elseif not validCooldownIDs[cdID] then
          validCooldownIDs[cdID] = "bar"
        end
      end
    end
  end
  
  -- 3. DIRECT SCAN of CDM viewers as fallback (catches frames that got re-added)
  local viewerNames = {"BuffIconCooldownViewer", "BuffBarCooldownViewer"}
  for _, viewerName in ipairs(viewerNames) do
    local viewer = _G[viewerName]
    if viewer then
      local children = {viewer:GetChildren()}
      for _, child in ipairs(children) do
        local cdID = child.cooldownID
        if not cdID and child.cooldownInfo then
          cdID = child.cooldownInfo.cooldownID
        end
        if not cdID and child.Icon and child.Icon.cooldownID then
          cdID = child.Icon.cooldownID
        end
        -- Handle both numeric CDM IDs and string Arc Aura IDs
        local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
        if isValidCdID and not validCooldownIDs[cdID] then
          if viewerName == "BuffIconCooldownViewer" then
            validCooldownIDs[cdID] = "icon"
          else
            validCooldownIDs[cdID] = "bar"
          end
        end
      end
    end
  end
  
  -- 4. Also scan CDM API directly for any cooldowns we might have missed
  if C_CooldownViewer then
    -- Check all known cooldownIDs from our bars config
    local db = ns.API.GetDB()
    if db and db.bars then
      for barNum = 1, 30 do
        local barConfig = db.bars[barNum]
        if barConfig and barConfig.tracking and barConfig.tracking.enabled then
          local cdID = barConfig.tracking.cooldownID
          -- Bar tracking uses numeric IDs from user config - keep numeric check
          if cdID and type(cdID) == "number" and cdID > 0 and not validCooldownIDs[cdID] then
            -- Check if CDM knows about this cooldown
            local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
            if info then
              -- CDM has this cooldown - find which viewer it's in
              for _, vName in ipairs(viewerNames) do
                local viewer = _G[vName]
                if viewer then
                  local children = {viewer:GetChildren()}
                  for _, child in ipairs(children) do
                    local frameCdID = child.cooldownID or (child.cooldownInfo and child.cooldownInfo.cooldownID)
                    if frameCdID == cdID then
                      validCooldownIDs[cdID] = vName == "BuffIconCooldownViewer" and "icon" or "bar"
                      break
                    end
                  end
                end
                if validCooldownIDs[cdID] then break end
              end
            end
          end
        end
      end
    end
  end
  
  -- 5. Scan CDMGroups containers (frames reparented for grouping)
  if ns.CDMGroups and ns.CDMGroups.GetAllGroupedFrames then
    local groupedFrames = ns.CDMGroups.GetAllGroupedFrames()
    if groupedFrames then
      local count = 0
      for cdID, data in pairs(groupedFrames) do
        -- Handle both numeric CDM IDs and string Arc Aura IDs
        local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
        if isValidCdID and not validCooldownIDs[cdID] then
          -- Determine viewer type from data or default to icon
          local vType = (data.viewerType == "bar") and "bar" or "icon"
          validCooldownIDs[cdID] = vType
          count = count + 1
        end
      end
      debugPrint(string.format("  Step 5 (CDMGroups): Added %d grouped frames", count))
    end
  end
  
  -- Debug: show total validCooldownIDs
  local totalValid = 0
  for _ in pairs(validCooldownIDs) do totalValid = totalValid + 1 end
  debugPrint(string.format("  Total validCooldownIDs: %d", totalValid))
  
  -- Now validate each bar's tracking
  local db = ns.API.GetDB()
  if db and db.bars then
    for barNum = 1, 30 do
      local barConfig = db.bars[barNum]
      if barConfig and barConfig.tracking.enabled then
        local state = GetBarState(barNum)
        local configSourceType = barConfig.tracking.sourceType or "icon"
        local trackType = barConfig.tracking.trackType
        
        -- Skip cooldownCharge bars - they use EssentialCooldownViewer/UtilityCooldownViewer
        -- not BuffIconCooldownViewer/BarCooldownViewer, so validCooldownIDs won't have them
        if trackType == "cooldownCharge" then
          -- Don't reset cachedCooldownFrame or trackingOK - let UpdateBarBuffInfo handle it
          state.cooldownID = barConfig.tracking.cooldownID
          debugPrint(string.format("  Bar %d: cooldownCharge, using cdID %d", barNum, state.cooldownID or 0))
        else
          -- Restore visibility of old cached frames before clearing them
          -- (in case hideBuffIcon was enabled and frames were hidden)
          if state.cachedFrame then AllowCDMFrameVisible(state.cachedFrame) end
          if state.cachedBarFrame then AllowCDMFrameVisible(state.cachedBarFrame) end
          
          state.cachedFrame = nil
          state.cachedBarFrame = nil
          
          -- Use cross-spec resolution: tries primary → alternates → auto-discover
          local activeCooldownID, sourceType = ns.API.GetActiveCooldownIDForBar(barNum, validCooldownIDs)
          debugPrint(string.format("  Bar %d: GetActiveCooldownIDForBar returned cdID=%s, source=%s", 
            barNum, tostring(activeCooldownID), tostring(sourceType)))
          
          if activeCooldownID then
            state.cooldownID = activeCooldownID
            local viewerSourceType = validCooldownIDs[activeCooldownID]
            debugPrint(string.format("    viewerSourceType=%s, configSourceType=%s", 
              tostring(viewerSourceType), tostring(configSourceType)))
            
            if viewerSourceType then
              if configSourceType == "bar" then
                if viewerSourceType == "bar" or viewerSourceType == "both" then
                  state.cachedBarFrame = FindBarFrameByCooldownID(activeCooldownID)
                  state.cachedFrame = FindBuffFrameByCooldownID(activeCooldownID)
                  -- Verify the cached frames actually have the right cooldownID
                  -- Check both frame.cooldownID and frame.cooldownInfo.cooldownID
                  local barValid = false
                  if state.cachedBarFrame then
                    local barCdID = state.cachedBarFrame.cooldownID or (state.cachedBarFrame.Icon and state.cachedBarFrame.Icon.cooldownID)
                    if not barCdID and state.cachedBarFrame.cooldownInfo then
                      barCdID = state.cachedBarFrame.cooldownInfo.cooldownID
                    end
                    barValid = (barCdID == activeCooldownID)
                    -- v2.10.0: Hook frame for instant stack updates
                    if barValid then
                      HookCDMFrameForStackUpdates(state.cachedBarFrame, barNum)
                    end
                  end
                  local iconValid = false
                  if state.cachedFrame then
                    local iconCdID = state.cachedFrame.cooldownID
                    if not iconCdID and state.cachedFrame.cooldownInfo then
                      iconCdID = state.cachedFrame.cooldownInfo.cooldownID
                    end
                    iconValid = (iconCdID == activeCooldownID)
                    -- v2.10.0: Hook frame for instant stack updates
                    if iconValid then
                      HookCDMFrameForStackUpdates(state.cachedFrame, barNum)
                    end
                  end
                  state.trackingOK = barValid or iconValid
                  if not state.trackingOK then
                    state.cachedBarFrame = nil
                    state.cachedFrame = nil
                  end
                else
                  state.trackingOK = false
                end
              else
                if viewerSourceType == "icon" or viewerSourceType == "both" then
                  state.cachedFrame = FindBuffFrameByCooldownID(activeCooldownID)
                  debugPrint(string.format("    FindBuffFrameByCooldownID(%d) = %s", 
                    activeCooldownID, state.cachedFrame and "FOUND" or "nil"))
                  -- Verify the cached frame actually has the right cooldownID
                  -- Check both frame.cooldownID and frame.cooldownInfo.cooldownID
                  if state.cachedFrame then
                    local frameCdID = state.cachedFrame.cooldownID
                    if not frameCdID and state.cachedFrame.cooldownInfo then
                      frameCdID = state.cachedFrame.cooldownInfo.cooldownID
                    end
                    debugPrint(string.format("    frame.cooldownID=%s, matches=%s", 
                      tostring(frameCdID), tostring(frameCdID == activeCooldownID)))
                    if frameCdID == activeCooldownID then
                      state.trackingOK = true
                      -- v2.10.0: Hook frame for instant stack updates
                      HookCDMFrameForStackUpdates(state.cachedFrame, barNum)
                    else
                      state.trackingOK = false
                      state.cachedFrame = nil
                    end
                  else
                    state.trackingOK = false
                  end
                else
                  debugPrint(string.format("    viewerSourceType=%s not icon/both, trackingOK=false", tostring(viewerSourceType)))
                  state.trackingOK = false
                end
              end
            else
              -- FALLBACK: Try to find the frame directly even if not in validCooldownIDs
              local frame = FindBuffFrameByCooldownID(activeCooldownID)
              if frame then
                local frameCdID = frame.cooldownID
                if not frameCdID and frame.cooldownInfo then
                  frameCdID = frame.cooldownInfo.cooldownID
                end
                if frameCdID == activeCooldownID then
                  state.trackingOK = true
                  state.cachedFrame = frame
                  validCooldownIDs[activeCooldownID] = "icon"
                  -- v2.10.0: Hook frame for instant stack updates
                  HookCDMFrameForStackUpdates(frame, barNum)
                else
                  -- Try bar frame
                  local barFrame = FindBarFrameByCooldownID(activeCooldownID)
                  if barFrame then
                    local barCdID = barFrame.cooldownID or (barFrame.Icon and barFrame.Icon.cooldownID)
                    if not barCdID and barFrame.cooldownInfo then
                      barCdID = barFrame.cooldownInfo.cooldownID
                    end
                    if barCdID == activeCooldownID then
                      state.trackingOK = true
                      state.cachedBarFrame = barFrame
                      validCooldownIDs[activeCooldownID] = "bar"
                      -- v2.10.0: Hook frame for instant stack updates
                      HookCDMFrameForStackUpdates(barFrame, barNum)
                    else
                      state.trackingOK = false
                    end
                  else
                    state.trackingOK = false
                  end
                end
              else
                local barFrame = FindBarFrameByCooldownID(activeCooldownID)
                if barFrame then
                  local barCdID = barFrame.cooldownID or (barFrame.Icon and barFrame.Icon.cooldownID)
                  if not barCdID and barFrame.cooldownInfo then
                    barCdID = barFrame.cooldownInfo.cooldownID
                  end
                  if barCdID == activeCooldownID then
                    state.trackingOK = true
                    state.cachedBarFrame = barFrame
                    validCooldownIDs[activeCooldownID] = "bar"
                    -- v2.10.0: Hook frame for instant stack updates
                    HookCDMFrameForStackUpdates(barFrame, barNum)
                  else
                    state.trackingOK = false
                  end
                else
                  state.trackingOK = false
                end
              end
            end
          else
            -- No valid cooldownID found (primary, alternate, or discovered)
            state.cooldownID = barConfig.tracking.cooldownID  -- Keep original for reference
            state.trackingOK = false
            debugPrint(string.format("    NO activeCooldownID found, trackingOK=false"))
            
            -- LAST RESORT: Try CDMEnhance recovery function with original cooldownID
            local originalCdID = barConfig.tracking.cooldownID
            if originalCdID and originalCdID > 0 then
              if ns.CDMEnhance and ns.CDMEnhance.RecoverFrameForCooldownID then
                local recoveredFrame = ns.CDMEnhance.RecoverFrameForCooldownID(originalCdID)
                if recoveredFrame and recoveredFrame.cooldownID == originalCdID then
                  state.trackingOK = true
                  state.cachedFrame = recoveredFrame
                  validCooldownIDs[originalCdID] = "icon"
                  debugPrint(string.format("    RECOVERED via CDMEnhance, trackingOK=true"))
                  -- v2.10.0: Hook frame for instant stack updates
                  HookCDMFrameForStackUpdates(recoveredFrame, barNum)
                end
              end
            end
          end
          
          debugPrint(string.format("  Bar %d RESULT: trackingOK=%s, cachedFrame=%s",
            barNum, tostring(state.trackingOK), state.cachedFrame and "YES" or "nil"))
        end
        
        -- Setup multi-icon textures out of combat
        if not InCombatLockdown() then
          if barConfig.display.displayType == "icon" and barConfig.display.iconMultiMode then
            if ns.Display and ns.Display.SetupMultiIconTextures then
              ns.Display.SetupMultiIconTextures(barNum)
            end
          end
        end
      end
    end
  end
  
  UpdateAllBars()
end

function ns.API.ScanAvailableBarsWithDuration()
  if InCombatLockdown() then return nil, "Cannot scan in combat" end
  
  local frames, err = GetAllBarFrames()
  if err then return nil, err end
  
  local availableBars = {}
  local seenNames = {}
  
  for slotNum, frame in ipairs(frames) do
    -- Try multiple sources for cooldownID
    local cdID = frame and frame.cooldownID
    if not cdID and frame and frame.cooldownInfo then
      cdID = frame.cooldownInfo.cooldownID
    end
    -- For bar frames, also check nested Icon frame
    if not cdID and frame and frame.Icon and frame.Icon.cooldownID then
      cdID = frame.Icon.cooldownID
    end
    
    if cdID then
      -- Get spell info from API (same approach as ScanAllCDMIcons)
      local spellID, spellName, iconTextureID
      local info = type(cdID) == "number" and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
      
      if info then
        local baseSpellID = info.spellID or 0
        local overrideSpellID = info.overrideSpellID
        local linkedSpellIDs = info.linkedSpellIDs
        local firstLinkedSpellID = linkedSpellIDs and linkedSpellIDs[1]
        
        -- Priority: first linkedSpellID > overrideSpellID > baseSpellID
        local displaySpellID = firstLinkedSpellID or overrideSpellID or baseSpellID
        
        spellID = displaySpellID or baseSpellID
        spellName = displaySpellID and C_Spell.GetSpellName(displaySpellID)
        iconTextureID = displaySpellID and C_Spell.GetSpellTexture(displaySpellID)
        
        -- Fallbacks
        if not spellName and overrideSpellID then
          spellName = C_Spell.GetSpellName(overrideSpellID)
          iconTextureID = iconTextureID or C_Spell.GetSpellTexture(overrideSpellID)
        end
        if not spellName and baseSpellID > 0 then
          spellName = C_Spell.GetSpellName(baseSpellID)
          iconTextureID = iconTextureID or C_Spell.GetSpellTexture(baseSpellID)
        end
      end
      
      -- Fallback to frame.cooldownInfo if API didn't work
      if not spellName and frame.cooldownInfo then
        spellID = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
        if spellID and spellID > 0 then
          spellName = C_Spell.GetSpellName(spellID)
          iconTextureID = C_Spell.GetSpellTexture(spellID)
        end
      end
      
      if spellName and not seenNames[spellName] then
        seenNames[spellName] = true
        local maxDuration = 0
        if frame.Bar and frame.Bar.GetMinMaxValues then
          local _, maxVal = frame.Bar:GetMinMaxValues()
          maxDuration = maxVal or 0
        end
        -- Try to get icon from bar frame itself
        if frame.Icon and frame.Icon.Icon and frame.Icon.Icon.GetTexture then
          local barIconTexture = frame.Icon.Icon:GetTexture()
          if barIconTexture then iconTextureID = barIconTexture end
        end
        table.insert(availableBars, {
          slotNumber = slotNum,
          buffName = spellName,
          spellID = spellID,
          iconTextureID = iconTextureID or 134400,
          cooldownID = cdID,
          maxDuration = maxDuration,
          isActive = frame.auraInstanceID ~= nil,
          sourceType = "bar"
        })
      end
    end
  end
  
  return availableBars
end

ns.scannedBarBuffs = {}

function ns.API.SelectBuff(buffInfo, barNumber)
  local db = ns.API.GetDB()
  if not db or not buffInfo then return false end
  
  barNumber = barNumber or db.selectedBar or 1
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig then return false end
  
  barConfig.tracking.spellID = buffInfo.spellID
  barConfig.tracking.buffName = buffInfo.buffName
  barConfig.tracking.iconTextureID = buffInfo.iconTextureID
  barConfig.tracking.cooldownID = buffInfo.cooldownID
  barConfig.tracking.slotNumber = buffInfo.slotNumber
  barConfig.tracking.maxStacks = buffInfo.maxStacks
  barConfig.tracking.enabled = true
  
  local state = GetBarState(barNumber)
  -- Restore visibility of old cached frame before reconfiguring
  if state.cachedFrame then AllowCDMFrameVisible(state.cachedFrame) end
  if state.cachedBarFrame then AllowCDMFrameVisible(state.cachedBarFrame) end
  state.cooldownID = buffInfo.cooldownID
  state.cachedFrame = nil
  
  UpdateBarBuffInfo(barNumber)
  return true
end

-- ===================================================================
-- UPDATE SPECIFIC BAR'S BUFF INFO
-- ===================================================================
UpdateBarBuffInfo = function(barNumber)
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig or not barConfig.tracking.enabled then return end
  
  local currentSpec = GetSpecialization() or 0
  local showOnSpecs = barConfig.behavior.showOnSpecs
  local specAllowed = true
  
  if showOnSpecs and #showOnSpecs > 0 then
    specAllowed = false
    for _, spec in ipairs(showOnSpecs) do
      if spec == currentSpec then specAllowed = true; break end
    end
  elseif barConfig.behavior.showOnSpec and barConfig.behavior.showOnSpec > 0 then
    specAllowed = (currentSpec == barConfig.behavior.showOnSpec)
  end
  
  if not specAllowed then
    if ns.Display and ns.Display.HideBar then ns.Display.HideBar(barNumber) end
    return
  end
  
  local trackType = barConfig.tracking.trackType or "buff"
  local state = GetBarState(barNumber)
  local sourceType = barConfig.tracking.sourceType or "icon"
  local useDurationBar = barConfig.tracking.useDurationBar
  
  -- ═══════════════════════════════════════════════════════════════════
  -- CUSTOM AURA TRACKING - Read from CustomTracking system
  -- Uses smooth OnUpdate animation instead of discrete polling
  -- ═══════════════════════════════════════════════════════════════════
  if trackType == "customAura" then
    local customDefID = barConfig.tracking.customDefinitionID
    if not customDefID or customDefID == "" then
      if ns.Display and ns.Display.HideBar then ns.Display.HideBar(barNumber) end
      if ns.Display and ns.Display.ClearCustomTrackingState then
        ns.Display.ClearCustomTrackingState(barNumber)
      end
      return
    end
    
    -- Get state from custom tracking system
    local customState = ns.CustomTracking and ns.CustomTracking.GetAuraState(customDefID)
    local customDef = ns.CustomTracking and ns.CustomTracking.GetAuraDefinition(customDefID)
    
    if not customState or not customDef then
      if ns.Display and ns.Display.HideBar then ns.Display.HideBar(barNumber) end
      if ns.Display and ns.Display.ClearCustomTrackingState then
        ns.Display.ClearCustomTrackingState(barNumber)
      end
      return
    end
    
    state.trackingOK = true
    local maxStacks = customDef.stacks and customDef.stacks.maxStacks or barConfig.tracking.maxStacks or 10
    local stacks = customState.stacks or 0
    local active = customState.active or false
    local iconTexture = customDef.iconTextureID or barConfig.tracking.iconTextureID
    local maxDuration = customDef.duration and customDef.duration.baseDuration or barConfig.tracking.maxDuration or 10
    
    -- Set smooth tracking state - Display.lua OnUpdate will handle smooth animation
    if ns.Display and ns.Display.SetCustomTrackingState then
      ns.Display.SetCustomTrackingState(barNumber, {
        active = active,
        expirationTime = customState.expirationTime or 0,
        maxDuration = maxDuration,
        stacks = stacks,
        maxStacks = maxStacks,
        iconTexture = iconTexture,
        useDurationBar = useDurationBar,
      })
    end
    
    -- Still call UpdateBar once for initial setup (visibility, appearance, etc.)
    -- But the OnUpdate will handle the smooth value updates
    if useDurationBar then
      local duration = 0
      if customState.expirationTime and customState.expirationTime > 0 then
        duration = customState.expirationTime - GetTime()
        if duration < 0 then duration = 0 end
      end
      
      local durationBarRef = {
        GetValue = function() return duration end,
        GetMinMaxValues = function() return 0, maxDuration end
      }
      local stacksRef = {
        GetText = function() return tostring(stacks) end,
        IsShown = function() return active and stacks > 0 end
      }
      
      if ns.Display and ns.Display.UpdateDurationBar then
        ns.Display.UpdateDurationBar(barNumber, stacks, maxStacks, active, durationBarRef, stacksRef, iconTexture)
      end
    else
      local duration = 0
      if customState.expirationTime and customState.expirationTime > 0 then
        duration = customState.expirationTime - GetTime()
        if duration < 0 then duration = 0 end
      end
      
      local durationRef = {
        GetText = function() 
          if duration > 0 then
            return string.format("%.1f", duration)
          end
          return ""
        end,
        IsShown = function() return active and duration > 0 end
      }
      
      if ns.Display and ns.Display.UpdateBar then
        ns.Display.UpdateBar(barNumber, stacks, maxStacks, active, durationRef, iconTexture)
      end
    end
    return
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- CUSTOM COOLDOWN TRACKING - Read from CustomTracking system
  -- Uses smooth OnUpdate animation instead of discrete polling
  -- ═══════════════════════════════════════════════════════════════════
  if trackType == "customCooldown" then
    local customDefID = barConfig.tracking.customDefinitionID
    if not customDefID or customDefID == "" then
      if ns.Display and ns.Display.HideBar then ns.Display.HideBar(barNumber) end
      if ns.Display and ns.Display.ClearCustomTrackingState then
        ns.Display.ClearCustomTrackingState(barNumber)
      end
      return
    end
    
    -- Get state from custom tracking system
    local customState = ns.CustomTracking and ns.CustomTracking.GetCooldownState(customDefID)
    local customDef = ns.CustomTracking and ns.CustomTracking.GetCooldownDefinition(customDefID)
    
    if not customState or not customDef then
      if ns.Display and ns.Display.HideBar then ns.Display.HideBar(barNumber) end
      if ns.Display and ns.Display.ClearCustomTrackingState then
        ns.Display.ClearCustomTrackingState(barNumber)
      end
      return
    end
    
    state.trackingOK = true
    local maxCharges = customState.maxCharges or barConfig.tracking.maxStacks or 1
    local charges = customState.charges or 0
    local iconTexture = customDef.iconTextureID or barConfig.tracking.iconTextureID
    
    -- Cooldowns are always "active" when being tracked
    local active = true
    
    -- Set smooth tracking state - Display.lua OnUpdate will handle smooth animation
    if ns.Display and ns.Display.SetCustomTrackingState then
      ns.Display.SetCustomTrackingState(barNumber, {
        active = active,
        charges = charges,
        maxCharges = maxCharges,
        rechargeEnd = customState.rechargeEnd or 0,
        rechargeDuration = customState.rechargeDuration or 10,  -- For cooldown swipe
        iconTexture = iconTexture,
        useDurationBar = false,  -- Cooldowns always use stack/charge display
      })
    end
    
    -- Calculate remaining cooldown time for duration text
    local cooldownRemaining = 0
    if customState.rechargeEnd and customState.rechargeEnd > 0 then
      cooldownRemaining = customState.rechargeEnd - GetTime()
      if cooldownRemaining < 0 then cooldownRemaining = 0 end
    end
    
    -- Create wrapper for duration text display
    local durationRef = {
      GetText = function()
        if cooldownRemaining > 0 then
          return string.format("%.1f", cooldownRemaining)
        end
        return ""
      end,
      IsShown = function() return cooldownRemaining > 0 end
    }
    
    -- Still call UpdateBar once for initial setup
    if ns.Display and ns.Display.UpdateBar then
      ns.Display.UpdateBar(barNumber, charges, maxCharges, active, durationRef, iconTexture)
    end
    return
  end
  
  -- Check if state.cooldownID is a valid cooldownID for this bar
  -- (either primary OR an alternate) before resetting
  local primaryCdID = barConfig.tracking.cooldownID
  local isValidCdIDForBar = (state.cooldownID == primaryCdID)
  if not isValidCdIDForBar and state.cooldownID then
    -- Check alternates
    local alts = barConfig.tracking.alternateCooldownIDs
    if alts then
      for _, altCdID in ipairs(alts) do
        if state.cooldownID == altCdID then
          isValidCdIDForBar = true
          break
        end
      end
    end
  end
  
  -- Only reset if state.cooldownID is NOT a valid cooldownID for this bar
  -- This preserves alternate cooldownIDs set by ValidateAllBarTracking
  if not state.cooldownID or (not isValidCdIDForBar and not state.cachedFrame) then
    -- Restore visibility of old cached frames before clearing
    if state.cachedFrame then AllowCDMFrameVisible(state.cachedFrame) end
    if state.cachedBarFrame then AllowCDMFrameVisible(state.cachedBarFrame) end
    
    state.cooldownID = barConfig.tracking.cooldownID
    state.cachedFrame = nil
    state.cachedBarFrame = nil
    state.cachedCooldownFrame = nil  -- For cooldown charge tracking
    state.cachedIcon = nil
  end
  
  -- Handle cooldown charge tracking separately (uses different viewer frames)
  if trackType == "cooldownCharge" then
    local freshCooldownFrame = FindCooldownFrameByCooldownID(state.cooldownID)
    if freshCooldownFrame then
      state.trackingOK = true
      state.cachedCooldownFrame = freshCooldownFrame
    else
      state.trackingOK = false
      state.cachedCooldownFrame = nil
    end
  else
    -- For buff/debuff tracking, find both bar and icon frames
    local freshBarFrame = FindBarFrameByCooldownID(state.cooldownID)
    local freshFrame = FindBuffFrameByCooldownID(state.cooldownID)
    
    -- DEBUG: Log when we can't find a frame for a configured cooldownID
    if ns.debugMode and state.cooldownID and state.cooldownID > 0 then
      if not freshFrame and not freshBarFrame then
        print(string.format("|cffFF6600[ArcUI Debug]|r Bar %d: Cannot find frame for cooldownID %d", 
          barNumber, state.cooldownID))
        -- Try to get more info about what CDM knows about this cooldownID
        if C_CooldownViewer then
          local info = type(state.cooldownID) == "number" and C_CooldownViewer.GetCooldownViewerCooldownInfo(state.cooldownID)
          if info then
            local spellName = info.spellID and C_Spell.GetSpellName(info.spellID)
            print(string.format("  CDM knows this cooldownID: spellID=%s (%s)", 
              tostring(info.spellID), spellName or "?"))
          else
            print("  CDM does NOT know this cooldownID (removed from tracking?)")
          end
        end
        -- Check all viewers for any frames
        local viewerNames = {"BuffIconCooldownViewer", "BuffBarCooldownViewer"}
        for _, vName in ipairs(viewerNames) do
          local viewer = _G[vName]
          if viewer then
            local children = {viewer:GetChildren()}
            local cdIDs = {}
            for _, child in ipairs(children) do
              local cdID = child._arcFreeCdID or child.cooldownID
              -- Handle both numeric CDM IDs and string Arc Aura IDs
              local isValidCdID = cdID and ((type(cdID) == "number" and cdID > 0) or type(cdID) == "string")
              if isValidCdID then
                table.insert(cdIDs, string.format("%s(%s)", tostring(cdID), child._arcFreeCdID and "arc" or "cdm"))
              end
            end
            print(string.format("  %s has %d children with cdIDs: %s", 
              vName, #cdIDs, table.concat(cdIDs, ", ")))
          end
        end
        -- Check CDMEnhance tracking
        if ns.CDMEnhance then
          local enhanced = ns.CDMEnhance.GetEnhancedFrames and ns.CDMEnhance.GetEnhancedFrames()
          if enhanced and enhanced[state.cooldownID] then
            local data = enhanced[state.cooldownID]
            print(string.format("  enhancedFrames[%d]: frame=%s, cooldownID=%s, _arcFreeCdID=%s, parent=%s", 
              state.cooldownID,
              tostring(data.frame), 
              data.frame and tostring(data.frame.cooldownID) or "nil",
              data.frame and tostring(data.frame._arcFreeCdID) or "nil",
              data.frame and (data.frame:GetParent() and data.frame:GetParent():GetName() or "UIParent?") or "nil"))
          else
            print(string.format("  enhancedFrames has NO entry for cooldownID %d", state.cooldownID))
          end
          
          local free = ns.CDMEnhance.GetFreePositionFrames and ns.CDMEnhance.GetFreePositionFrames()
          if free and free[state.cooldownID] then
            local frame = free[state.cooldownID]
            print(string.format("  freePositionFrames[%d]: frame=%s, cooldownID=%s, _arcFreeCdID=%s, parent=%s", 
              state.cooldownID,
              tostring(frame), 
              frame and tostring(frame.cooldownID) or "nil",
              frame and tostring(frame._arcFreeCdID) or "nil",
              frame and (frame:GetParent() and frame:GetParent():GetName() or "UIParent?") or "nil"))
          else
            print(string.format("  freePositionFrames has NO entry for cooldownID %d", state.cooldownID))
          end
        end
      elseif freshFrame then
        -- We found a frame - log its properties for debug
        print(string.format("|cff00FF00[ArcUI Debug]|r Bar %d: Found frame for cdID %d - cooldownID=%s, _arcFreeCdID=%s, auraInstanceID=%s",
          barNumber, state.cooldownID,
          tostring(freshFrame.cooldownID),
          tostring(freshFrame._arcFreeCdID),
          tostring(freshFrame.auraInstanceID)))
      end
    end
    
    -- We can get stacks/duration from ANY CDM frame using auraInstanceID
    -- and C_UnitAuras APIs, so accept either bar OR icon source
    if freshBarFrame or freshFrame then
      state.trackingOK = true
      state.cachedBarFrame = freshBarFrame
      state.cachedFrame = freshFrame
    else
      state.trackingOK = false
      state.cachedBarFrame = nil
      state.cachedFrame = nil
    end
  end
  
  -- Check if we're in the spec change grace period
  local inGracePeriod = GetTime() < specChangeGraceUntil
  
  -- For cooldownCharge, skip this check - it has its own fallback via C_Spell.GetSpellCharges
  -- Also skip during spec change grace period to allow CDM frames time to load
  if not state.trackingOK and not IsOptionsOpen() and not inGracePeriod and trackType ~= "cooldownCharge" then
    if ns.Display and ns.Display.HideBar then ns.Display.HideBar(barNumber) end
    return
  end
  
  local hasCooldownID = barConfig.tracking.cooldownID and barConfig.tracking.cooldownID > 0
  if not state.trackingOK and IsOptionsOpen() and hasCooldownID and trackType ~= "cooldownCharge" then
    local maxStacks = barConfig.tracking.maxStacks or 10
    if useDurationBar then
      if ns.Display and ns.Display.UpdateDurationBar then
        ns.Display.UpdateDurationBar(barNumber, 0, maxStacks, false, nil, nil, nil)
      end
    else
      if ns.Display and ns.Display.UpdateBar then
        ns.Display.UpdateBar(barNumber, 0, maxStacks, false, nil, nil)
      end
    end
    return
  end
  
  -- During grace period, also skip hiding for missing cooldownID 
  -- (CDM might not have loaded the bar config yet)
  if not hasCooldownID and not inGracePeriod then
    if ns.Display and ns.Display.HideBar then ns.Display.HideBar(barNumber) end
    return
  end
  
  local frame = state.cachedFrame
  local barFrame = state.cachedBarFrame
  local cooldownFrame = state.cachedCooldownFrame  -- For cooldown charge tracking
  local active = false
  local stacks = 0
  
  -- ═══════════════════════════════════════════════════════════════════
  -- COOLDOWN CHARGE TRACKING - Read charge count from CDM cooldown frame
  -- Primary: cooldownChargesCount property (secret value passthrough)
  -- Fallback: C_Spell.GetSpellCharges(spellID).currentCharges
  -- ═══════════════════════════════════════════════════════════════════
  if trackType == "cooldownCharge" then
    -- Find the cooldown frame if not cached
    if not cooldownFrame then
      cooldownFrame = FindCooldownFrameByCooldownID(state.cooldownID)
      state.cachedCooldownFrame = cooldownFrame
    end
    
    -- Track if we got stacks from CDM (can't compare secret values)
    local gotStacksFromCDM = false
    
    if cooldownFrame then
      state.trackingOK = true
      active = true  -- Always active if we found the frame
      
      -- Primary: Read charge count from CDM frame property
      if cooldownFrame.cooldownChargesCount ~= nil then
        stacks = cooldownFrame.cooldownChargesCount  -- Secret value passthrough
        gotStacksFromCDM = true
      end
      
      -- Get icon texture from cooldown frame
      if cooldownFrame.Icon and cooldownFrame.Icon.GetTexture then
        state.cachedIcon = cooldownFrame.Icon:GetTexture()
      elseif not state.cachedIcon and barConfig.tracking.spellID then
        state.cachedIcon = C_Spell.GetSpellTexture(barConfig.tracking.spellID)
      end
    end
    
    -- Fallback: Use spell API if no CDM frame OR no stacks from CDM
    if barConfig.tracking.spellID then
      local chargeInfo = C_Spell.GetSpellCharges(barConfig.tracking.spellID)
      if chargeInfo then
        -- If we didn't get stacks from CDM, use spell API
        if not gotStacksFromCDM then
          stacks = chargeInfo.currentCharges or 0  -- Secret value in combat
          state.trackingOK = true
          active = true
        end
        
        -- Get icon texture if we don't have one from CDM
        if not state.cachedIcon then
          state.cachedIcon = C_Spell.GetSpellTexture(barConfig.tracking.spellID)
        end
        
        -- Always update maxCharges when out of combat AND value is not secret
        -- In WoW 12.0 instances, some spell data can be secret even out of combat
        -- SKIP if user has locked maxStacks (manual override)
        if not InCombatLockdown() and chargeInfo.maxCharges and not barConfig.tracking.lockMaxStacks then
          local safeMaxCharges = chargeInfo.maxCharges
          -- Check if it's a secret value - if so, don't store it
          if issecretvalue and issecretvalue(safeMaxCharges) then
            -- Secret value - keep existing config or use fallback
            if not barConfig.tracking.maxStacks or barConfig.tracking.maxStacks == 0 then
              barConfig.tracking.maxStacks = 3  -- Default for charge abilities
            end
          else
            -- Safe non-secret value - store it
            local numVal = tonumber(safeMaxCharges)
            if numVal and numVal > 0 then
              barConfig.tracking.maxStacks = numVal
            end
          end
        end
      elseif not cooldownFrame then
        -- No CDM frame and no spell charges = not trackable yet
        state.trackingOK = false
        active = false
        stacks = 0
      end
    elseif not cooldownFrame then
      state.trackingOK = false
      active = false
      stacks = 0
    end
  -- ═══════════════════════════════════════════════════════════════════
  -- PET/TOTEM/GROUND EFFECT TRACKING - Use preferredTotemUpdateSlot from CDM frame
  -- WoW 12.0: frame.totemData AND GetTotemInfo() returns are SECRET!
  -- Use issecretvalue() to detect existence: secret = data exists = totem active
  -- "pet" = guardians/pets (Dreadstalkers, Wild Imps, etc.)
  -- "totem" = actual totems (Healing Stream, Capacitor, etc.)
  -- "ground" = ground effects (Consecration, Efflorescence, Death and Decay, etc.)
  -- ═══════════════════════════════════════════════════════════════════
  elseif trackType == "pet" or trackType == "totem" or trackType == "ground" then
    local cdmFrame = sourceType == "bar" and barFrame or frame or barFrame
    
    -- PRIMARY: Use preferredTotemUpdateSlot (Beta) or totemData.slot (Live)
    -- Beta: preferredTotemUpdateSlot is non-secret, totemData is secret table
    -- Live: preferredTotemUpdateSlot may not exist, totemData.slot is accessible
    local slot = cdmFrame and (cdmFrame.preferredTotemUpdateSlot or (cdmFrame.totemData and cdmFrame.totemData.slot))
    if slot and type(slot) == "number" and slot > 0 then
      -- Verify totem is active using game API
      -- WoW 12.0: GetTotemInfo returns SECRET values when totem exists
      local haveTotem, name, startTime, duration = GetTotemInfo(slot)
      
      -- Check if totem exists: secret return = data protected = totem active
      local totemExists = false
      if issecretvalue(haveTotem) then
        -- Secret boolean means totem data exists
        totemExists = true
      elseif haveTotem then
        -- Non-secret truthy value
        totemExists = true
      end
      
      if totemExists then
        active = true
        stacks = 0  -- Totems don't have stacks
        -- Store cdmFrame reference - query slot fresh each time!
        -- This handles frame recycling where preferredTotemUpdateSlot changes
        state.totemCdmFrame = cdmFrame
      else
        active = false
        stacks = 0
        state.totemCdmFrame = nil
      end
    else
      -- No preferredTotemUpdateSlot - mark as inactive
      active = false
      stacks = 0
      state.totemCdmFrame = nil
    end
  -- ═══════════════════════════════════════════════════════════════════
  -- DEBUFF TRACKING - Check if CDM frame has auraInstanceID set
  -- Stacks/duration come from target unit (not player!)
  -- Uses linkedSpellID (non-secret!) to handle CDM override situations
  -- ═══════════════════════════════════════════════════════════════════
  elseif trackType == "debuff" then
    local trackedSpellID = barConfig.tracking.trackedSpellID
    local useBaseSpell = barConfig.tracking.useBaseSpell  -- Legacy support
    -- Respect sourceType preference: use icon frame for icon source, bar frame for bar source
    local cdmFrame = sourceType == "bar" and barFrame or frame or barFrame
    
    -- NEW: trackedSpellID approach for debuffs
    -- When user selects a specific spell, we track it using CDM's auraInstanceID
    -- Note: linkedSpellID is secret when there's only 1 linked spell, non-secret when 2+
    if trackedSpellID and trackedSpellID > 0 and cdmFrame then
      local auraInstanceID = cdmFrame.auraInstanceID
      local auraDataUnit = cdmFrame.auraDataUnit or "target"
      local linkedSpellID = cdmFrame.cooldownInfo and cdmFrame.cooldownInfo.linkedSpellID
      
      -- Check if CDM is currently showing OUR tracked spell
      -- Use pcall because linkedSpellID can be secret when there's only 1 linked spell
      local isOurSpell = false
      if linkedSpellID then
        local ok, result = pcall(function() return linkedSpellID == trackedSpellID end)
        if ok then
          isOurSpell = result
        else
          -- linkedSpellID is secret - means only 1 linked spell, so CDM always shows our spell
          isOurSpell = true
        end
      end
      
      if isOurSpell and auraInstanceID then
        -- CDM is showing our tracked spell! Use this auraInstanceID
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(auraDataUnit, auraInstanceID)
        if auraData then
          active = true
          stacks = auraData.applications or 0
          -- Cache this auraInstanceID for when CDM switches to different spell
          state.trackedAuraInstanceID = auraInstanceID
          state.trackedAuraUnit = auraDataUnit
        else
          active = false
          stacks = 0
        end
      elseif state.trackedAuraInstanceID then
        -- CDM is showing a DIFFERENT spell, use our cached auraInstanceID
        local unit = state.trackedAuraUnit or "target"
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, state.trackedAuraInstanceID)
        if auraData then
          active = true
          stacks = auraData.applications or 0
        else
          -- Cached aura expired - clear it
          state.trackedAuraInstanceID = nil
          state.trackedAuraUnit = nil
          active = false
          stacks = 0
        end
      else
        -- No cached auraInstanceID and CDM showing different spell
        active = false
        stacks = 0
      end
      
    -- LEGACY: useBaseSpell approach (auraDataUnit-based) for debuffs
    elseif useBaseSpell and cdmFrame then
      local auraDataUnit = cdmFrame.auraDataUnit
      local auraInstanceID = cdmFrame.auraInstanceID
      
      if auraDataUnit == "target" and auraInstanceID then
        state.debuffAuraInstanceID = auraInstanceID
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("target", auraInstanceID)
        if auraData then
          active = true
          stacks = auraData.applications or 0
        else
          active = false
          stacks = 0
        end
      elseif state.debuffAuraInstanceID then
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("target", state.debuffAuraInstanceID)
        if auraData then
          active = true
          stacks = auraData.applications or 0
        else
          state.debuffAuraInstanceID = nil
          active = false
          stacks = 0
        end
      else
        active = false
        stacks = 0
      end
      
    else
      -- Default behavior: use CDM frame's auraInstanceID directly
      if sourceType == "bar" and barFrame then
        active = (barFrame.auraInstanceID ~= nil)
        if active and barFrame.auraInstanceID then
          local unit = barFrame.auraDataUnit or "target"
          local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, barFrame.auraInstanceID)
          if auraData then 
            stacks = auraData.applications or 0
          end
        end
      elseif frame then
        active = (frame.auraInstanceID ~= nil)
        if active then
          local unit = frame.auraDataUnit or "target"
          local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, frame.auraInstanceID)
          if auraData then
            stacks = auraData.applications or 0
          end
        end
      end
    end
  -- ═══════════════════════════════════════════════════════════════════
  -- BUFF TRACKING (default) - Auto-detect unit (player or target)
  -- Uses linkedSpellID (non-secret!) to handle CDM override situations
  -- ═══════════════════════════════════════════════════════════════════
  else
    local detectedUnit = nil
    local trackedSpellID = barConfig.tracking.trackedSpellID
    local useBaseSpell = barConfig.tracking.useBaseSpell  -- Legacy support
    -- Respect sourceType preference: use icon frame for icon source, bar frame for bar source
    local cdmFrame = sourceType == "bar" and barFrame or frame or barFrame
    
    -- NEW: trackedSpellID approach for buffs
    -- When user selects a specific spell, we track it using CDM's auraInstanceID
    -- Note: linkedSpellID is secret when there's only 1 linked spell, non-secret when 2+
    if trackedSpellID and trackedSpellID > 0 and cdmFrame then
      local auraInstanceID = cdmFrame.auraInstanceID
      local auraDataUnit = cdmFrame.auraDataUnit or "player"
      local linkedSpellID = cdmFrame.cooldownInfo and cdmFrame.cooldownInfo.linkedSpellID
      
      -- Check if CDM is currently showing OUR tracked spell
      -- Use pcall because linkedSpellID can be secret when there's only 1 linked spell
      local isOurSpell = false
      if linkedSpellID then
        local ok, result = pcall(function() return linkedSpellID == trackedSpellID end)
        if ok then
          isOurSpell = result
        else
          -- linkedSpellID is secret - means only 1 linked spell, so CDM always shows our spell
          isOurSpell = true
        end
      end
      
      if isOurSpell and auraInstanceID then
        -- CDM is showing our tracked spell! Use this auraInstanceID
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(auraDataUnit, auraInstanceID)
        if auraData then
          active = true
          stacks = auraData.applications or 0
          detectedUnit = auraDataUnit
          -- Cache this auraInstanceID for when CDM switches to different spell
          state.trackedAuraInstanceID = auraInstanceID
          state.trackedAuraUnit = auraDataUnit
        else
          active = false
          stacks = 0
        end
      elseif state.trackedAuraInstanceID then
        -- CDM is showing a DIFFERENT spell, use our cached auraInstanceID
        local unit = state.trackedAuraUnit or "player"
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, state.trackedAuraInstanceID)
        if auraData then
          active = true
          stacks = auraData.applications or 0
          detectedUnit = unit
        else
          -- Cached aura expired - clear it
          state.trackedAuraInstanceID = nil
          state.trackedAuraUnit = nil
          active = false
          stacks = 0
        end
      else
        -- No cached auraInstanceID and CDM showing different spell
        active = false
        stacks = 0
      end
      
    -- LEGACY: useBaseSpell approach (auraDataUnit-based) for buffs
    elseif useBaseSpell and cdmFrame then
      local auraDataUnit = cdmFrame.auraDataUnit
      local auraInstanceID = cdmFrame.auraInstanceID
      
      if auraDataUnit == "player" and auraInstanceID then
        state.buffAuraInstanceID = auraInstanceID
        detectedUnit = "player"
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
        if auraData then
          active = true
          stacks = auraData.applications or 0
        else
          active = false
          stacks = 0
        end
      elseif state.buffAuraInstanceID then
        detectedUnit = "player"
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("player", state.buffAuraInstanceID)
        if auraData then
          active = true
          stacks = auraData.applications or 0
        else
          state.buffAuraInstanceID = nil
          active = false
          stacks = 0
        end
      else
        active = false
        stacks = 0
      end
      
    else
      -- Default behavior: use auraInstanceID from any CDM frame
      local auraInstanceID = cdmFrame and cdmFrame.auraInstanceID
      local auraDataUnit = cdmFrame and cdmFrame.auraDataUnit
      
      if auraInstanceID then
        active = true
        local auraData = nil
        
        if auraDataUnit then
          auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(auraDataUnit, auraInstanceID)
          detectedUnit = auraDataUnit
        else
          auraData, detectedUnit = GetAuraDataAutoUnit(auraInstanceID)
        end
        
        if auraData then
          stacks = auraData.applications or 0
          if ns.debugMode then
            print(string.format("|cff00ff00[ArcUI Debug]|r Bar %d BUFF: auraInstID=%s, unit=%s, stacks=%s", 
              barNumber, tostring(auraInstanceID), tostring(detectedUnit), tostring(auraData.applications)))
          end
        else
          active = false
          stacks = 0
        end
      else
        active = false
        stacks = 0
      end
    end
    
    -- Store detected unit for durationStacksRef creation later
    state.detectedUnit = detectedUnit
  end
  
  state.stacks = stacks
  state.active = active
  
  -- Get duration FontString from CDM frame (fallback for icon source)
  local durationFontString = nil
  if active and frame then
    if frame.Cooldown then
      local regions = {frame.Cooldown:GetRegions()}
      for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" then
          durationFontString = region
          break
        end
      end
    end
    if not durationFontString then
      local children = {frame:GetChildren()}
      for _, child in ipairs(children) do
        if child:GetObjectType() == "Cooldown" then
          local regions = {child:GetRegions()}
          for _, region in ipairs(regions) do
            if region:GetObjectType() == "FontString" then
              durationFontString = region
              break
            end
          end
          if durationFontString then break end
        end
      end
    end
  end
  
  -- Create duration wrapper for cooldownCharge bars
  -- Simple passthrough - just use the FontString text directly
  local cooldownDurationRef = nil
  if trackType == "cooldownCharge" and cooldownFrame then
    local cooldownFlash = cooldownFrame.CooldownFlash
    local cooldownWidget = cooldownFrame.Cooldown
    local durationFS = nil
    
    if cooldownWidget then
      local regions = {cooldownWidget:GetRegions()}
      for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" then
          durationFS = region
          break
        end
      end
    end
    
    if durationFS then
      cooldownDurationRef = {
        GetText = function()
          return durationFS:GetText() or ""
        end,
        IsShown = function()
          -- Use CooldownFlash for visibility - stays true until fully recharged
          if cooldownFlash then
            return cooldownFlash:IsShown()
          end
          return durationFS:IsShown()
        end
      }
    end
  end
  
  -- Get icon texture from appropriate CDM frame
  -- Respects sourceType preference, trackedSpellID, and useBaseSpell setting
  local iconTexture = nil
  local useBaseSpell = barConfig.tracking.useBaseSpell
  local trackedSpellID = barConfig.tracking.trackedSpellID
  
  -- NEW: If trackedSpellID is set, use cached iconTextureID (set when selecting spell)
  -- or fall back to GetSpellTexture (works out of combat)
  if trackedSpellID and trackedSpellID > 0 then
    -- First try cached texture (guaranteed to work during combat)
    if barConfig.tracking.iconTextureID then
      iconTexture = barConfig.tracking.iconTextureID
    else
      -- Fallback to GetSpellTexture (works out of combat)
      iconTexture = C_Spell.GetSpellTexture(trackedSpellID)
    end
  elseif not useBaseSpell then
    -- Default behavior: get icon from CDM frame (may be override spell)
    -- Respect sourceType preference
    if sourceType == "icon" then
      -- Prefer icon frame for icon source
      if frame then
        if frame.Icon and frame.Icon.GetTexture then
          iconTexture = frame.Icon:GetTexture()
        end
        if not iconTexture and frame.cooldownInfo and frame.cooldownInfo.overrideSpellID then
          iconTexture = C_Spell.GetSpellTexture(frame.cooldownInfo.overrideSpellID)
        end
      end
      if not iconTexture and barFrame then
        if barFrame.Icon and barFrame.Icon.Icon and barFrame.Icon.Icon.GetTexture then
          iconTexture = barFrame.Icon.Icon:GetTexture()
        end
      end
    else
      -- Prefer bar frame for bar source
      if useDurationBar and barFrame then
        if barFrame.Icon and barFrame.Icon.Icon and barFrame.Icon.Icon.GetTexture then
          iconTexture = barFrame.Icon.Icon:GetTexture()
        end
      end
      if not iconTexture and frame then
        if frame.Icon and frame.Icon.GetTexture then
          iconTexture = frame.Icon:GetTexture()
        end
        if not iconTexture and frame.cooldownInfo and frame.cooldownInfo.overrideSpellID then
          iconTexture = C_Spell.GetSpellTexture(frame.cooldownInfo.overrideSpellID)
        end
      end
    end
    if not iconTexture and cooldownFrame then
      -- For cooldownCharge bars, get icon from cooldown frame
      if cooldownFrame.Icon and cooldownFrame.Icon.GetTexture then
        iconTexture = cooldownFrame.Icon:GetTexture()
      end
    end
  else
    -- useBaseSpell enabled: use base spellID from cooldownInfo, not override
    -- Respect sourceType preference
    if sourceType == "icon" then
      if frame and frame.cooldownInfo and frame.cooldownInfo.spellID then
        iconTexture = C_Spell.GetSpellTexture(frame.cooldownInfo.spellID)
      elseif barFrame and barFrame.cooldownInfo and barFrame.cooldownInfo.spellID then
        iconTexture = C_Spell.GetSpellTexture(barFrame.cooldownInfo.spellID)
      end
    else
      if barFrame and barFrame.cooldownInfo and barFrame.cooldownInfo.spellID then
        iconTexture = C_Spell.GetSpellTexture(barFrame.cooldownInfo.spellID)
      elseif frame and frame.cooldownInfo and frame.cooldownInfo.spellID then
        iconTexture = C_Spell.GetSpellTexture(frame.cooldownInfo.spellID)
      end
    end
    if not iconTexture and cooldownFrame and cooldownFrame.cooldownInfo and cooldownFrame.cooldownInfo.spellID then
      iconTexture = C_Spell.GetSpellTexture(cooldownFrame.cooldownInfo.spellID)
    end
  end
  
  -- Fallback to saved iconTextureID or spellID
  if not iconTexture and barConfig.tracking.iconTextureID then
    iconTexture = barConfig.tracking.iconTextureID
  end
  if not iconTexture and barConfig.tracking.spellID then
    iconTexture = C_Spell.GetSpellTexture(barConfig.tracking.spellID)
  end
  -- Fallback to cached icon from tracking (for cooldownCharge)
  if not iconTexture and state.cachedIcon then
    iconTexture = state.cachedIcon
  end
  
  -- Duration bar tracking - create wrapper for stacks/duration from auraInstanceID
  local durationBarRef = nil
  local durationStacksRef = nil
  -- NOTE: useBaseSpell and trackedSpellID already declared above (lines 2091-2092)
  -- Respect sourceType preference: use icon frame for icon source, bar frame for bar source
  local cdmFrame = sourceType == "bar" and barFrame or frame or barFrame
  
  -- Get bar reference if available (for legacy CDM bar duration passthrough)
  if barFrame and barFrame.Bar then 
    durationBarRef = barFrame.Bar 
  end
  
  -- Create stacks/duration wrapper using auraInstanceID
  -- NEW: trackedSpellID uses state.trackedAuraInstanceID/Unit
  if trackedSpellID and trackedSpellID > 0 and state.trackedAuraInstanceID then
    local cachedAuraInstanceID = state.trackedAuraInstanceID
    local cachedUnit = state.trackedAuraUnit or "player"
    durationStacksRef = {
      GetText = function()
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
        if auraData then
          return auraData.applications
        end
        return 0
      end,
      GetDuration = function()
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
        if auraData then
          return auraData.duration, auraData.expirationTime
        end
        return 0, 0
      end
    }
    
  elseif trackType == "debuff" then
    -- LEGACY: For debuff with useBaseSpell
    local auraInstIDToUse = nil
    if useBaseSpell and state.debuffAuraInstanceID then
      auraInstIDToUse = state.debuffAuraInstanceID
    elseif not useBaseSpell and cdmFrame and cdmFrame.auraInstanceID then
      auraInstIDToUse = cdmFrame.auraInstanceID
    end
    
    if auraInstIDToUse then
      local cachedAuraInstanceID = auraInstIDToUse
      local cachedUnit = cdmFrame and cdmFrame.auraDataUnit or "target"
      durationStacksRef = {
        GetText = function()
          local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
          if auraData then
            return auraData.applications
          end
          return 0
        end,
        GetDuration = function()
          local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
          if auraData then
            return auraData.duration, auraData.expirationTime
          end
          return 0, 0
        end
      }
    end
    
  else
    -- LEGACY: For buff with useBaseSpell or default
    local auraInstIDToUse = nil
    local unitToUse = state.detectedUnit or "player"
    
    if useBaseSpell and state.buffAuraInstanceID then
      auraInstIDToUse = state.buffAuraInstanceID
      unitToUse = "player"
    elseif not useBaseSpell and cdmFrame and cdmFrame.auraInstanceID then
      auraInstIDToUse = cdmFrame.auraInstanceID
      unitToUse = cdmFrame.auraDataUnit or state.detectedUnit or "player"
    end
    
    if auraInstIDToUse then
      local cachedAuraInstanceID = auraInstIDToUse
      local cachedUnit = unitToUse
      durationStacksRef = {
        GetText = function()
          local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
          if auraData then
            return auraData.applications
          end
          return 0
        end,
        GetDuration = function()
          local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
          if auraData then
            return auraData.duration, auraData.expirationTime
          end
          return 0, 0
        end
      }
    end
  end
  
  -- Fallback to CDM's FontString if no auraInstanceID wrapper AND not tracking specific spell
  local blockCDMFallback = (trackedSpellID and trackedSpellID > 0) or useBaseSpell
  if not durationStacksRef and not blockCDMFallback then
    if barFrame and barFrame.Icon and barFrame.Icon.Applications then
      durationStacksRef = barFrame.Icon.Applications
    elseif frame and frame.Icon and frame.Icon.Applications then
      durationStacksRef = frame.Icon.Applications
    end
  end
  
  -- Update display
  if ns.Display and ns.Display.UpdateBar then
    -- Create duration wrapper using auraInstanceID for accurate duration
    -- This works for ANY CDM source (icon or bar) and handles override situations
    local effectiveDurationRef = nil
    local trackedSpellID = barConfig.tracking.trackedSpellID
    -- Respect sourceType preference: use icon frame for icon source, bar frame for bar source
    local cdmFrame = sourceType == "bar" and barFrame or frame or barFrame
    
    -- NEW: trackedSpellID approach - use state.trackedAuraInstanceID/Unit
    if trackedSpellID and trackedSpellID > 0 and state.trackedAuraInstanceID then
      local cachedAuraInstanceID = state.trackedAuraInstanceID
      local cachedUnit = state.trackedAuraUnit or "player"
      effectiveDurationRef = {
        GetValue = function()
          -- CRITICAL: Validate aura still exists before calling GetAuraDurationRemaining
          -- Calling with stale auraInstanceID causes client crash in Beta 4
          local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
          if not auraData then
            return 0
          end
          if C_UnitAuras.GetAuraDurationRemaining then
            return C_UnitAuras.GetAuraDurationRemaining(cachedUnit, cachedAuraInstanceID)
          end
          return 0
        end,
        GetMinMaxValues = function()
          local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
          if auraData and auraData.duration then
            return 0, auraData.duration
          end
          return 0, 30
        end,
        -- v2.8.0: For ColorCurve support - expose aura info
        GetAuraInfo = function()
          return cachedAuraInstanceID, cachedUnit
        end
      }
      
    elseif trackType == "debuff" then
      -- LEGACY: For debuff tracking with useBaseSpell
      local auraInstIDToUse = nil
      local unitToUse = "target"
      
      if useBaseSpell and state.debuffAuraInstanceID then
        auraInstIDToUse = state.debuffAuraInstanceID
      elseif not useBaseSpell and cdmFrame and cdmFrame.auraInstanceID then
        -- Default: use CDM's current ID
        auraInstIDToUse = cdmFrame.auraInstanceID
        unitToUse = cdmFrame.auraDataUnit or "target"
      end
      
      if auraInstIDToUse then
        local cachedAuraInstanceID = auraInstIDToUse
        local cachedUnit = unitToUse
        effectiveDurationRef = {
          GetValue = function()
            -- CRITICAL: Validate aura still exists before calling GetAuraDurationRemaining
            -- Calling with stale auraInstanceID causes client crash in Beta 4
            local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
            if not auraData then
              return 0
            end
            if C_UnitAuras.GetAuraDurationRemaining then
              return C_UnitAuras.GetAuraDurationRemaining(cachedUnit, cachedAuraInstanceID)
            end
            return 0
          end,
          GetMinMaxValues = function()
            local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
            if auraData and auraData.duration then
              return 0, auraData.duration
            end
            return 0, 30
          end,
          -- v2.8.0: For ColorCurve support - expose aura info
          GetAuraInfo = function()
            return cachedAuraInstanceID, cachedUnit
          end
        }
      end
      
    elseif trackType == "buff" or trackType == nil then
      -- LEGACY: For buff tracking with useBaseSpell
      local auraInstIDToUse = nil
      local unitToUse = state.detectedUnit or "player"
      
      if useBaseSpell and state.buffAuraInstanceID then
        auraInstIDToUse = state.buffAuraInstanceID
        unitToUse = "player"
      elseif not useBaseSpell and cdmFrame and cdmFrame.auraInstanceID then
        -- Default: use CDM's current ID
        auraInstIDToUse = cdmFrame.auraInstanceID
        unitToUse = cdmFrame.auraDataUnit or state.detectedUnit or "player"
      end
      
      if auraInstIDToUse then
        local cachedAuraInstanceID = auraInstIDToUse
        local cachedUnit = unitToUse
        effectiveDurationRef = {
          GetValue = function()
            -- CRITICAL: Validate aura still exists before calling GetAuraDurationRemaining
            -- Calling with stale auraInstanceID causes client crash in Beta 4
            local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
            if not auraData then
              return 0
            end
            if C_UnitAuras.GetAuraDurationRemaining then
              return C_UnitAuras.GetAuraDurationRemaining(cachedUnit, cachedAuraInstanceID)
            end
            return 0
          end,
          GetMinMaxValues = function()
            local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(cachedUnit, cachedAuraInstanceID)
            if auraData and auraData.duration then
              return 0, auraData.duration
            end
            return 0, 30
          end,
          -- v2.8.0: For ColorCurve support - expose aura info
          GetAuraInfo = function()
            return cachedAuraInstanceID, cachedUnit
          end
        }
      end
    elseif trackType == "pet" or trackType == "totem" or trackType == "ground" then
      -- PET/TOTEM/GROUND EFFECT TRACKING: Create duration reference
      -- WoW 12.0: Use fast polling with GetTotemTimeLeft + SetValue
      -- SetValue is "AllowedWhenTainted" - addon code CAN pass secrets
      if state.totemCdmFrame then
        local totemCdmFrame = state.totemCdmFrame
        -- Capture original cooldownID - this identifies OUR specific totem
        local originalCooldownID = totemCdmFrame.cooldownID
        
        effectiveDurationRef = {
          GetValue = function()
            -- Check if frame is still tracking OUR cooldown (non-secret check)
            if totemCdmFrame.cooldownID ~= originalCooldownID then return 0 end
            
            -- Check if frame is still active
            local isActive = totemCdmFrame.isActive
            local frameActive = false
            if issecretvalue(isActive) then
              frameActive = true  -- Secret = combat state = still tracking
            elseif isActive then
              frameActive = true
            end
            if not frameActive then return 0 end
            
            -- Query slot FRESH from frame each time (Beta: preferredTotemUpdateSlot, Live: totemData.slot)
            local currentSlot = totemCdmFrame.preferredTotemUpdateSlot or (totemCdmFrame.totemData and totemCdmFrame.totemData.slot)
            if not currentSlot or currentSlot <= 0 then return 0 end
            
            -- Use GetTotemTimeLeft - returns secret in combat but SetValue accepts it
            if GetTotemTimeLeft then
              local timeLeft = GetTotemTimeLeft(currentSlot)
              if timeLeft then
                return timeLeft
              end
            end
            return 0
          end,
          GetMinMaxValues = function()
            -- WoW 12.0: Get duration from GetTotemInfo - it's SECRET but SetMinMaxValues accepts secrets!
            local currentSlot = totemCdmFrame.preferredTotemUpdateSlot or (totemCdmFrame.totemData and totemCdmFrame.totemData.slot)
            if currentSlot and currentSlot > 0 then
              local haveTotem, name, startTime, duration = GetTotemInfo(currentSlot)
              if duration then
                return 0, duration  -- Pass secret duration directly - SetMinMaxValues is AllowedWhenTainted!
              end
            end
            -- Fallback to config if no totem data available
            local maxDur = barConfig.tracking.maxDuration or 30
            return 0, maxDur
          end,
          GetTotemInfo = function()
            -- Check if frame is still tracking OUR cooldown
            if totemCdmFrame.cooldownID ~= originalCooldownID then return nil, nil end
            
            local isActive = totemCdmFrame.isActive
            local frameActive = false
            if issecretvalue(isActive) then
              frameActive = true
            elseif isActive then
              frameActive = true
            end
            if not frameActive then return nil, nil end
            
            local currentSlot = totemCdmFrame.preferredTotemUpdateSlot or (totemCdmFrame.totemData and totemCdmFrame.totemData.slot)
            return currentSlot, nil
          end,
          -- No DurationObject - use polling
          GetDurationObject = function()
            return nil
          end,
          needsFastPolling = true,
          pollingInterval = 0.02
        }
      end
    end
    
    -- Determine final duration source:
    -- 1. effectiveDurationRef (our auraInstanceID wrapper - works for any source)
    -- 2. durationBarRef (CDM bar - legacy fallback, but NOT when trackedSpellID/useBaseSpell is on)
    -- 3. durationFontString (CDM icon fontstring - legacy fallback, but NOT when trackedSpellID/useBaseSpell is on)
    
    -- Don't fall back to CDM duration if we're tracking a specific spell
    local preventCDMFallback = (trackedSpellID and trackedSpellID > 0) or useBaseSpell
    
    if useDurationBar then
      -- Duration bar mode - ALWAYS use UpdateDurationBar
      local durationSource = effectiveDurationRef
      if not durationSource and not preventCDMFallback then
        durationSource = durationBarRef  -- Only use CDM bar when not tracking specific spell
      end
      -- Debug: trace active state
      if ns.debugMode then
        print(string.format("|cffff9900[ArcUI Debug]|r Bar %d calling UpdateDurationBar: active=%s, stacks=%s, hideWhenInactive=%s",
          barNumber, tostring(active), tostring(stacks), tostring(barConfig.behavior and barConfig.behavior.hideWhenInactive)))
      end
      ns.Display.UpdateDurationBar(barNumber, stacks, barConfig.tracking.maxStacks, active, 
                                    durationSource, durationStacksRef, iconTexture)
    elseif trackType == "cooldownCharge" and cooldownDurationRef then
      -- Cooldown charge bar - pass cooldown duration wrapper for duration TEXT display
      ns.Display.UpdateBar(barNumber, stacks, barConfig.tracking.maxStacks, active, cooldownDurationRef, iconTexture)
    elseif trackType == "cooldownCharge" then
      -- Cooldown charge bar WITHOUT CDM frame (using spell API fallback)
      -- No duration text available, but stacks are from C_Spell.GetSpellCharges
      ns.Display.UpdateBar(barNumber, stacks, barConfig.tracking.maxStacks, active, nil, iconTexture)
    elseif effectiveDurationRef then
      -- We have an auraInstanceID wrapper - use it for duration display
      ns.Display.UpdateBar(barNumber, stacks, barConfig.tracking.maxStacks, active, effectiveDurationRef, iconTexture)
    elseif preventCDMFallback then
      -- Tracking specific spell but don't have effectiveDurationRef - DON'T use CDM's duration
      -- (CDM might be showing a different spell's duration)
      ns.Display.UpdateBar(barNumber, stacks, barConfig.tracking.maxStacks, active, nil, iconTexture)
    elseif durationBarRef then
      -- Fallback to CDM bar reference
      ns.Display.UpdateBar(barNumber, stacks, barConfig.tracking.maxStacks, active, durationBarRef, iconTexture)
    else
      -- Stack bar from icon source - pass fontstring for duration text
      ns.Display.UpdateBar(barNumber, stacks, barConfig.tracking.maxStacks, active, durationFontString, iconTexture)
    end
  end
  
  -- Hide CDM icon if enabled (ForceHideCDMFrame verifies cooldownID matches before hiding)
  if barConfig.behavior.hideBuffIcon then
    local expectedCdID = state.cooldownID or barConfig.tracking.cooldownID
    if frame then ForceHideCDMFrame(frame, expectedCdID) end
    if barFrame then ForceHideCDMFrame(barFrame, expectedCdID) end
    
    -- Fallback: If cached frames were nil or rejected by verification,
    -- do a direct viewer scan to find and hide the correct CDM frame.
    -- This handles stale cache after profile import/spec change.
    if expectedCdID and (not frame or not hiddenCDMFrames[frame]) then
      local viewer = _G["BuffIconCooldownViewer"]
      if viewer then
        local children = {viewer:GetChildren()}
        for _, child in ipairs(children) do
          local cdID = child.cooldownID
          if not cdID and child.cooldownInfo then
            cdID = child.cooldownInfo.cooldownID
          end
          if cdID == expectedCdID then
            ForceHideCDMFrame(child, expectedCdID)
            break
          end
        end
      end
    end
    if expectedCdID and (not barFrame or not hiddenCDMFrames[barFrame]) then
      local viewer = _G["BuffBarCooldownViewer"]
      if viewer then
        local children = {viewer:GetChildren()}
        for _, child in ipairs(children) do
          local cdID = child.cooldownID
          if not cdID and child.cooldownInfo then
            cdID = child.cooldownInfo.cooldownID
          end
          if not cdID and child.Icon and child.Icon.cooldownID then
            cdID = child.Icon.cooldownID
          end
          if cdID == expectedCdID then
            ForceHideCDMFrame(child, expectedCdID)
            break
          end
        end
      end
    end
  else
    if frame then AllowCDMFrameVisible(frame) end
    if barFrame then AllowCDMFrameVisible(barFrame) end
  end
end

-- ===================================================================
-- UPDATE ALL ACTIVE BARS
-- ===================================================================
UpdateAllBars = function()
  if not ns.API.GetActiveBars then return end
  local activeBars = ns.API.GetActiveBars()
  for _, barNumber in ipairs(activeBars) do
    UpdateBarBuffInfo(barNumber)
  end
end

-- UPDATE ONLY COOLDOWN CHARGE BARS (for SPELL_UPDATE_COOLDOWN efficiency)
local function UpdateCooldownChargeBars()
  local db = ns.API.GetDB()
  if not db or not db.bars then return end
  
  for barNum = 1, 30 do
    local barConfig = db.bars[barNum]
    if barConfig and barConfig.tracking and barConfig.tracking.enabled then
      if barConfig.tracking.trackType == "cooldownCharge" then
        UpdateBarBuffInfo(barNum)
      end
    end
  end
end

-- ===================================================================
-- EVENT HANDLING
-- ===================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")  -- For cooldown bars
eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")   -- For charge-based abilities

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT THROTTLING (v2.10.0): Reduced importance since hooks handle instant updates
-- This is now just a safety net for events that don't trigger hooks directly
-- ═══════════════════════════════════════════════════════════════════════════
local lastUpdateTime = 0
local UPDATE_THROTTLE = 0.1  -- 10 updates/sec max (hooks provide instant updates)
local pendingUpdate = false

local function ThrottledUpdateAllBars()
  local now = GetTime()
  if now - lastUpdateTime >= UPDATE_THROTTLE then
    lastUpdateTime = now
    pendingUpdate = false
    UpdateAllBars()
  elseif not pendingUpdate then
    -- Schedule one update after throttle period
    pendingUpdate = true
    C_Timer.After(UPDATE_THROTTLE - (now - lastUpdateTime), function()
      if pendingUpdate then
        pendingUpdate = false
        lastUpdateTime = GetTime()
        UpdateAllBars()
      end
    end)
  end
  -- else: update already pending, skip
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "UNIT_AURA" then
    local unit = ...
    if unit == "player" or unit == "target" then
      ThrottledUpdateAllBars()  -- Throttled!
      SchedulePollsForAllBars()
      StartDurationBarTicker()
    end
  elseif event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
    -- Cooldown/charge changed - throttle these too (fires every GCD)
    ThrottledUpdateAllBars()
    StartDurationBarTicker()
  elseif event == "PLAYER_TARGET_CHANGED" then
    ThrottledUpdateAllBars()  -- Throttled!
    SchedulePollsForAllBars()
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Bars stay hidden until initialization completes (prevents flash on reload)
    -- Delay allows frames to be created and positioned before showing
    C_Timer.After(0.5, function() 
      ns.API.ValidateAllBarTracking()
      UpdateCooldownChargeBars()
      -- Mark initialization complete - bars can now show
      if ns.Display and ns.Display.MarkInitializationComplete then
        ns.Display.MarkInitializationComplete()
      end
      -- Now refresh all bars with proper appearance
      if ns.Display and ns.Display.RefreshAllBars then
        ns.Display.RefreshAllBars()
      end
      UpdateAllBars()
    end)
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Left combat - invalidate visibility cache
    if ns.Display and ns.Display.InvalidateVisibilityCache then
      ns.Display.InvalidateVisibilityCache()
    end
    -- Refresh icon textures while out of combat (they might have been secret during combat)
    C_Timer.After(0.2, function()
      local db = ns.API.GetDB()
      if db and db.bars then
        for barNumber, barConfig in pairs(db.bars) do
          if barConfig.tracking then
            -- Update iconTextureID - respect trackedSpellID if set
            local sourceSpellID = nil
            if barConfig.tracking.trackedSpellID and barConfig.tracking.trackedSpellID > 0 then
              sourceSpellID = barConfig.tracking.trackedSpellID
            elseif barConfig.tracking.spellID then
              sourceSpellID = barConfig.tracking.spellID
            end
            
            if sourceSpellID then
              local texture = C_Spell.GetSpellTexture(sourceSpellID)
              if texture then
                barConfig.tracking.iconTextureID = texture
              end
            end
          end
          -- Setup multi-icon textures (must be done out of combat)
          if barConfig.tracking and barConfig.tracking.enabled then
            if barConfig.display.displayType == "icon" and barConfig.display.iconMultiMode then
              if ns.Display and ns.Display.SetupMultiIconTextures then
                ns.Display.SetupMultiIconTextures(barNumber)
              end
            end
          end
        end
      end
    end)
    C_Timer.After(0.5, UpdateAllBars)
    StartDurationBarTicker()
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Entered combat - invalidate visibility cache
    if ns.Display and ns.Display.InvalidateVisibilityCache then
      ns.Display.InvalidateVisibilityCache()
    end
    UpdateAllBars()
    StartDurationBarTicker()
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    -- Invalidate cross-spec cooldownID cache first
    InvalidateSpellToCooldownIDCache()
    
    -- v2.10.0: Clear frame hook registrations (frames may change on spec change)
    ClearAllFrameHookRegistrations()
    
    -- Invalidate spec cache in Display module
    if ns.Display and ns.Display.InvalidateSpecCache then
      ns.Display.InvalidateSpecCache()
    end
    -- Invalidate visibility cache (spec affects visibility)
    if ns.Display and ns.Display.InvalidateVisibilityCache then
      ns.Display.InvalidateVisibilityCache()
    end
    
    -- Set grace period immediately - don't hide bars due to trackingOK=false
    -- CDM frames may not have loaded new spec's abilities yet
    specChangeGraceUntil = GetTime() + SPEC_CHANGE_GRACE_DURATION
    
    -- Full refresh on spec change:
    -- 1. Validate tracking (checks CDM frames, etc.)
    -- 2. RefreshAllBars (ApplyAppearance + RefreshDisplay for each bar)
    -- 3. UpdateAllBars to ensure all states are current
    C_Timer.After(0.2, function() 
      ns.API.ValidateAllBarTracking()
      -- RefreshAllBars calls ApplyAppearance then RefreshDisplay for proper setup
      if ns.Display and ns.Display.RefreshAllBars then
        ns.Display.RefreshAllBars()
      end
      -- Also trigger a full update cycle to catch any stragglers
      UpdateAllBars()
      StartDurationBarTicker()
    end)
    
    -- Schedule another refresh after grace period to clean up any bars
    -- that didn't load properly
    C_Timer.After(SPEC_CHANGE_GRACE_DURATION + 0.5, function()
      ns.API.ValidateAllBarTracking()
      if ns.Display and ns.Display.RefreshAllBars then
        ns.Display.RefreshAllBars()
      end
      UpdateAllBars()
    end)
  end
end)

-- ===================================================================
-- API FUNCTIONS
-- ===================================================================
function ns.API.GetCurrentStacks(barNumber)
  barNumber = barNumber or ns.API.GetSelectedBar()
  local state = GetBarState(barNumber)
  return state.stacks
end

function ns.API.GetMaxStacks(barNumber)
  barNumber = barNumber or ns.API.GetSelectedBar()
  local barConfig = ns.API.GetBarConfig(barNumber)
  return barConfig and barConfig.tracking.maxStacks or 10
end

function ns.API.IsBuffActive(barNumber)
  barNumber = barNumber or ns.API.GetSelectedBar()
  local state = GetBarState(barNumber)
  return state.active
end

function ns.API.RefreshDisplay(barNumber)
  if barNumber then UpdateBarBuffInfo(barNumber) else UpdateAllBars() end
end

function ns.API.RefreshAll() UpdateAllBars() end

function ns.API.ClearBarState(barNumber)
  ClearBarState(barNumber)
end

function ns.API.IsTrackingOK(barNumber)
  barNumber = barNumber or ns.API.GetSelectedBar()
  local state = GetBarState(barNumber)
  return state.trackingOK == true
end

-- Expose GetBarState for debuggers
function ns.API.GetBarState(barNumber)
  barNumber = barNumber or ns.API.GetSelectedBar()
  return GetBarState(barNumber)
end

function ns.API.GetTrackingStatus(barNumber)
  if not ns.API.GetSelectedBar or not ns.API.GetBarConfig then
    return "initializing", "Addon initializing...", false
  end
  barNumber = barNumber or ns.API.GetSelectedBar()
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig or not barConfig.tracking.enabled then
    return "not_configured", "Bar slot not configured", false
  end
  local viewer = _G["BuffIconCooldownViewer"]
  if not viewer then
    return "no_viewer", "BuffIconCooldownViewer not found", false
  end
  local state = GetBarState(barNumber)
  if state.trackingOK and state.cooldownID then
    return "ok", barConfig.tracking.buffName .. " tracked", true
  elseif state.cooldownID then
    return "pending", barConfig.tracking.buffName .. " (waiting for CD Manager)", false
  end
  return "not_found", "Buff not found in CD Manager", false
end

function ns.API.ForceRecheck(barNumber)
  if InCombatLockdown() then return false end
  barNumber = barNumber or ns.API.GetSelectedBar()
  local barConfig = ns.API.GetBarConfig(barNumber)
  if not barConfig or not barConfig.tracking.enabled then return false end
  local state = GetBarState(barNumber)
  -- Restore visibility of old cached frame before clearing
  if state.cachedFrame then AllowCDMFrameVisible(state.cachedFrame) end
  state.cachedFrame = nil
  local frame = FindBuffFrameByCooldownID(state.cooldownID)
  if frame then
    UpdateBarBuffInfo(barNumber)
    return true
  end
  return false
end

function ns.API.SetHideBuffIcon(hide, barNumber)
  barNumber = barNumber or ns.API.GetSelectedBar()
  local barConfig = ns.API.GetBarConfig(barNumber)
  if barConfig then
    barConfig.behavior.hideBuffIcon = hide
    UpdateBarBuffInfo(barNumber)
  end
end

function ns.API.DisableBar(barNumber)
  local barConfig = ns.API.GetBarConfig(barNumber)
  if barConfig then
    barConfig.tracking.enabled = false
    if ns.Display and ns.Display.HideBar then ns.Display.HideBar(barNumber) end
  end
end

-- ===================================================================
-- SLASH COMMANDS
-- ===================================================================
SLASH_ARCBARS1 = "/arcbars"
SLASH_ARCBARS2 = "/ab"

SlashCmdList["ARCBARS"] = function(msg)
  local command, arg = msg:match("^(%S+)%s*(.*)$")
  command = command or msg
  command = command:lower()
  
  if command == "config" or command == "" then
    if ns.API.OpenOptions then ns.API.OpenOptions() end
  elseif command == "debug" then
    ns.devMode = not ns.devMode
    print("|cff00ccffArcUI|r Debug mode: " .. (ns.devMode and "|cff00ff00ON|r" or "|cffff6b6bOFF|r"))
  elseif command == "texinfo" then
    -- Print texture info for all bars
    local db = ns.db
    if db and db.profile and db.profile.bars then
      print("|cff00ccffArcUI|r Texture info for all bars:")
      for barNumber, barConfig in pairs(db.profile.bars) do
        if barConfig.tracking and barConfig.tracking.enabled then
          print(string.format("  Bar %d: iconTextureID=%s, spellID=%s",
            barNumber,
            tostring(barConfig.tracking.iconTextureID),
            tostring(barConfig.tracking.spellID)))
        end
      end
    end
  elseif command == "scan" then
    print("|cff00ccffArcUI|r Scanning tracked buffs...")
    local buffs, err = ns.API.ScanAvailableBuffs()
    if not buffs then
      print("|cff00ccffArcUI|r |cffff6b6bError:|r " .. (err or "Unknown"))
      return
    end
    if #buffs == 0 then
      print("|cff00ccffArcUI|r No buffs found")
      return
    end
    print("|cff00ccffArcUI|r Found " .. #buffs .. " buff(s):")
    for i, buff in ipairs(buffs) do
      local status = buff.isActive and "|cff00ff00(Active)|r" or "|cffaaaaaa(Inactive)|r"
      print(string.format("  %d. |cff00ff00%s|r %s", i, buff.buffName, status))
    end
  elseif command == "status" then
    local activeBars = ns.API.GetActiveBars()
    if #activeBars == 0 then
      print("|cff00ccffArcUI|r No active bars")
    else
      print("|cff00ccffArcUI|r Active bars:")
      for _, barNum in ipairs(activeBars) do
        local barConfig = ns.API.GetBarConfig(barNum)
        local state = GetBarState(barNum)
        print(string.format("  Bar %d: %s - %s", barNum, barConfig.tracking.buffName,
          state.active and "|cff00ff00Active|r" or "|cffaaaaaa(Inactive)|r"))
      end
    end
  elseif command == "dev" or command == "devmode" then
    ns.devMode = not ns.devMode
    print("|cff00ccffArcUI|r Dev Mode: " .. (ns.devMode and "|cff00ff00ON|r" or "|cffff6b6bOFF|r"))
  elseif command == "stackdebug" then
    ns.debugMode = not ns.debugMode
    print("|cff00ccffArcUI|r Stack Debug: " .. (ns.debugMode and "|cff00ff00ON|r (watch for debug output)" or "|cffff6b6bOFF|r"))
  elseif command == "dump" or command == "trackdebug" then
    -- Comprehensive debug dump for tracking issues
    print("|cff00ccff=== ArcUI Tracking Debug Dump ===|r")
    
    -- 1. Show all enabled bars with their cooldownIDs
    local db = ns.API.GetDB()
    if db and db.bars then
      print("|cffFFCC00[Enabled Bars]|r")
      for barNum = 1, 30 do
        local barConfig = db.bars[barNum]
        if barConfig and barConfig.tracking and barConfig.tracking.enabled then
          local state = GetBarState(barNum)
          local cdID = barConfig.tracking.cooldownID
          print(string.format("  Bar %d: cdID=%s, trackingOK=%s, cachedFrame=%s", 
            barNum, 
            tostring(cdID),
            tostring(state.trackingOK),
            state.cachedFrame and "YES" or "nil"))
          if state.cachedFrame then
            local frame = state.cachedFrame
            print(string.format("    frame.cooldownID=%s, frame._arcFreeCdID=%s, parent=%s",
              tostring(frame.cooldownID),
              tostring(frame._arcFreeCdID),
              frame:GetParent() and (frame:GetParent():GetName() or tostring(frame:GetParent())) or "nil"))
          end
        end
      end
    end
    
    -- 2. Show all frames in BuffIconCooldownViewer
    print("|cffFFCC00[BuffIconCooldownViewer Children]|r")
    local viewer = _G["BuffIconCooldownViewer"]
    if viewer then
      local children = {viewer:GetChildren()}
      for i, child in ipairs(children) do
        local cdID = child.cooldownID
        local arcFreeCdID = child._arcFreeCdID
        local info = cdID and type(cdID) == "number" and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
        local spellName = info and info.spellID and C_Spell.GetSpellName(info.spellID)
        print(string.format("  %d: cdID=%s, _arcFreeCdID=%s, spell=%s",
          i, tostring(cdID), tostring(arcFreeCdID), spellName or "?"))
      end
    else
      print("  (viewer not found)")
    end
    
    -- 3. Show CDMEnhance tracking tables
    if ns.CDMEnhance then
      print("|cffFFCC00[CDMEnhance.enhancedFrames]|r")
      local enhanced = ns.CDMEnhance.GetEnhancedFrames and ns.CDMEnhance.GetEnhancedFrames()
      if enhanced then
        for cdID, data in pairs(enhanced) do
          local frame = data.frame
          local frameCdID = frame and frame.cooldownID
          local arcFreeCdID = frame and frame._arcFreeCdID
          local parent = frame and frame:GetParent()
          local parentName = parent and (parent:GetName() or tostring(parent)) or "nil"
          print(string.format("  cdID=%d: frame.cooldownID=%s, _arcFreeCdID=%s, parent=%s, viewerType=%s",
            cdID, tostring(frameCdID), tostring(arcFreeCdID), parentName, data.viewerType or "?"))
        end
      else
        print("  (nil)")
      end
      
      print("|cffFFCC00[CDMEnhance.freePositionFrames]|r")
      local freeFrames = ns.CDMEnhance.GetFreePositionFrames and ns.CDMEnhance.GetFreePositionFrames()
      if freeFrames then
        for cdID, frame in pairs(freeFrames) do
          local frameCdID = frame and frame.cooldownID
          local arcFreeCdID = frame and frame._arcFreeCdID
          local parent = frame and frame:GetParent()
          local parentName = parent and (parent:GetName() or tostring(parent)) or "nil"
          print(string.format("  cdID=%d: frame.cooldownID=%s, _arcFreeCdID=%s, parent=%s",
            cdID, tostring(frameCdID), tostring(arcFreeCdID), parentName))
        end
      else
        print("  (nil)")
      end
      
      -- 4. Show iconSettings with free position
      print("|cffFFCC00[Free Position Settings in DB]|r")
      local cdmDb = ns.CDMEnhance.GetDB and ns.CDMEnhance.GetDB()
      if cdmDb and cdmDb.iconSettings then
        for cdIDStr, settings in pairs(cdmDb.iconSettings) do
          if settings.position and settings.position.mode == "free" then
            local cdID = tonumber(cdIDStr)
            local info = cdID and type(cdID) == "number" and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
            local spellName = info and info.spellID and C_Spell.GetSpellName(info.spellID)
            print(string.format("  cdID=%s (%s): freeX=%.1f, freeY=%.1f",
              cdIDStr, spellName or "?",
              settings.position.freeX or 0, settings.position.freeY or 0))
          end
        end
      else
        print("  (no free position settings)")
      end
    else
      print("|cffFF6600[CDMEnhance not loaded]|r")
    end
    
    print("|cff00ccff=== End Debug Dump ===|r")
  else
    print("|cff00ccffArcUI|r Commands:")
    print("  /arcbars config - Open configuration")
    print("  /arcbars scan - Scan for tracked buffs")
    print("  /arcbars status - Show all active bars")
    print("  /arcbars dev - Toggle dev mode")
    print("  /arcbars stackdebug - Toggle stack tracking debug output")
    print("  /arcbars dump - Debug dump of tracking state")
  end
end

-- ===================================================================
-- CENTRALIZED CDM ICON SCANNER
-- Single source of truth for all CDM icon data
-- Scans all 4 viewers and provides unified API for all modules
-- v2.8.0: Consolidated from Catalog.lua and CDMEnhance.lua
-- ===================================================================
ns.CDMIcons = ns.CDMIcons or {}

-- Master icon catalog: { [cooldownID] = iconData }
local cdmIconCache = {}
local lastScanTime = 0

-- Viewer configuration
local CDM_VIEWERS = {
  { name = "BuffIconCooldownViewer", category = "TrackedBuff", viewerType = "aura", isAura = true },
  { name = "BuffBarCooldownViewer", category = "TrackedBar", viewerType = "aura", isAura = true },
  { name = "EssentialCooldownViewer", category = "Essential", viewerType = "cooldown", isAura = false },
  { name = "UtilityCooldownViewer", category = "Utility", viewerType = "utility", isAura = false },
}

-- Category display names
local CATEGORY_NAMES = {
  TrackedBuff = "Tracked Buffs",
  TrackedBar = "Tracked Bars",
  Essential = "Essential Cooldowns",
  Utility = "Utility Cooldowns",
  ["TrackedBuff+Bar"] = "Tracked Buffs + Bars",
}

-- ===================================================================
-- MASTER CDM SCANNER
-- Scans all CDM viewers and builds unified icon catalog
-- Also includes detached frames (moved to UIParent via free positioning)
-- ===================================================================
function ns.API.ScanAllCDMIcons()
  if InCombatLockdown() then
    if ns.devMode then
      print("|cffFF6600[ArcUI CDM]|r Scan skipped - in combat")
    end
    return 0
  end
  
  wipe(cdmIconCache)
  local totalCount = 0
  
  for _, viewerInfo in ipairs(CDM_VIEWERS) do
    local viewer = _G[viewerInfo.name]
    if viewer then
      local children = {viewer:GetChildren()}
      
      -- Sort by X position for consistent slot indexing
      table.sort(children, function(a, b)
        local ax = a:GetLeft() or 0
        local bx = b:GetLeft() or 0
        return ax < bx
      end)
      
      local slotIndex = 0
      for _, frame in ipairs(children) do
        -- Try multiple sources for cooldownID
        local cdID = frame.cooldownID
        
        -- Fallback 1: Check cooldownInfo table
        if not cdID and frame.cooldownInfo then
          cdID = frame.cooldownInfo.cooldownID
        end
        
        -- Fallback 2: For bar frames, check nested Icon frame
        if not cdID and frame.Icon and frame.Icon.cooldownID then
          cdID = frame.Icon.cooldownID
        end
        
        -- NO IsShown() filter - include ALL frames with cooldownID
        if cdID then
          -- Verify with CDM API that this cooldown actually exists
          local info = type(cdID) == "number" and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
          
          -- CRITICAL: If CDM API returns nil, this cooldown was removed - skip it
          if not info then
            -- Skip frames with no CDM info
          else
            slotIndex = slotIndex + 1
            
            -- Get spell info from API
            local spellID, name, icon
            local baseSpellID = info.spellID or 0
            local overrideSpellID = info.overrideSpellID
            local overrideTooltipSpellID = info.overrideTooltipSpellID
            local linkedSpellIDs = info.linkedSpellIDs
            local firstLinkedSpellID = linkedSpellIDs and linkedSpellIDs[1]
            
            -- Priority: first linkedSpellID > overrideSpellID > baseSpellID
            local displaySpellID = firstLinkedSpellID or overrideSpellID or baseSpellID
            
            spellID = baseSpellID
            name = displaySpellID and C_Spell.GetSpellName(displaySpellID)
            
            -- ICON PRIORITY: Read from frame first (shows actual CDM texture)
            -- Then fall back to API calls with smart ordering
            -- Icon viewers: frame.Icon:GetTexture() or frame.Icon:GetTextureFileID()
            -- Bar viewers: frame.Icon.Icon:GetTexture()
            -- NOTE: In combat, GetTexture() may return secret values - use issecretvalue() to check
            if frame.Icon then
              -- Try GetTexture first (returns path or ID)
              if frame.Icon.GetTexture then
                local tex = frame.Icon:GetTexture()
                -- Validate texture is actually set (not nil, not 0, not empty, not secret)
                if tex and not issecretvalue(tex) and tex ~= 0 and tex ~= "" then
                  icon = tex
                end
              end
              -- Try GetTextureFileID as fallback (returns numeric ID)
              if not icon and frame.Icon.GetTextureFileID then
                local texID = frame.Icon:GetTextureFileID()
                if texID and not issecretvalue(texID) and texID > 0 then
                  icon = texID
                end
              end
              -- Bar viewer structure: frame.Icon.Icon
              if not icon and frame.Icon.Icon then
                if frame.Icon.Icon.GetTexture then
                  local tex = frame.Icon.Icon:GetTexture()
                  if tex and not issecretvalue(tex) and tex ~= 0 and tex ~= "" then
                    icon = tex
                  end
                end
                if not icon and frame.Icon.Icon.GetTextureFileID then
                  local texID = frame.Icon.Icon:GetTextureFileID()
                  if texID and not issecretvalue(texID) and texID > 0 then
                    icon = texID
                  end
                end
              end
            end
            
            -- Fallback to API - try different spell ID sources
            -- For auras: CDM uses overrideTooltipSpellID for display
            -- For cooldowns: CDM uses the override/linked spell icon
            if not icon then
              if viewerInfo.isAura then
                -- Auras: try overrideTooltipSpellID first (this is what CDM uses for display)
                if overrideTooltipSpellID and overrideTooltipSpellID > 0 then
                  icon = C_Spell.GetSpellTexture(overrideTooltipSpellID)
                end
                -- Then try base spellID
                if not icon and baseSpellID > 0 then
                  icon = C_Spell.GetSpellTexture(baseSpellID)
                end
                if not icon and overrideSpellID then
                  icon = C_Spell.GetSpellTexture(overrideSpellID)
                end
                if not icon and displaySpellID then
                  icon = C_Spell.GetSpellTexture(displaySpellID)
                end
              else
                -- Cooldowns: use override/linked chain (existing logic)
                icon = displaySpellID and C_Spell.GetSpellTexture(displaySpellID)
                if not icon and overrideSpellID then
                  icon = C_Spell.GetSpellTexture(overrideSpellID)
                end
                if not icon and baseSpellID > 0 then
                  icon = C_Spell.GetSpellTexture(baseSpellID)
                end
              end
            end
            
            -- Fallbacks for name
            if not name and overrideSpellID then
              name = C_Spell.GetSpellName(overrideSpellID)
            end
            if not name and baseSpellID > 0 then
              name = C_Spell.GetSpellName(baseSpellID)
            end
          
            -- Check if already exists (for TrackedBuff+Bar case)
            local existing = cdmIconCache[cdID]
            if existing then
              -- Update category to show it's in both buff viewers
              if existing.category == "TrackedBuff" and viewerInfo.category == "TrackedBar" then
                existing.category = "TrackedBuff+Bar"
                existing.categoryName = CATEGORY_NAMES["TrackedBuff+Bar"]
                existing.isTrackedBar = true
                existing.barFrame = frame
              elseif existing.category == "TrackedBar" and viewerInfo.category == "TrackedBuff" then
                existing.category = "TrackedBuff+Bar"
                existing.categoryName = CATEGORY_NAMES["TrackedBuff+Bar"]
                existing.isTrackedBuff = true
                existing.iconFrame = frame
              end
            else
              -- Create new entry
              cdmIconCache[cdID] = {
                cooldownID = cdID,
                spellID = spellID or 0,
                name = name or "Unknown",
                icon = icon or 134400,
                category = viewerInfo.category,
                categoryName = CATEGORY_NAMES[viewerInfo.category] or viewerInfo.category,
                viewerType = viewerInfo.viewerType,
                viewerName = viewerInfo.name,
                isAura = viewerInfo.isAura,
                isTrackedBuff = viewerInfo.category == "TrackedBuff",
                isTrackedBar = viewerInfo.category == "TrackedBar",
                isEssential = viewerInfo.category == "Essential",
                isUtility = viewerInfo.category == "Utility",
                frame = frame,
                iconFrame = viewerInfo.category == "TrackedBuff" and frame or nil,
                barFrame = viewerInfo.category == "TrackedBar" and frame or nil,
                slotIndex = slotIndex,
                isDetached = false,
                -- API info
                hasAura = info.hasAura,
                selfAura = info.selfAura,
                charges = info.charges,
                flags = info.flags,
              }
              totalCount = totalCount + 1
            end
          
            -- Store slot index on frame for CDMEnhance
            frame._arcSlotIndex = slotIndex - 1
          end  -- end else (info exists)
        end  -- end if cdID
      end  -- end for frame
    end  -- end if viewer
  end  -- end for viewerInfo
  
  -- Include detached frames from CDMEnhance (frames moved to UIParent via free positioning)
  if ns.CDMEnhance and ns.CDMEnhance.GetDetachedFrames then
    local detached = ns.CDMEnhance.GetDetachedFrames()
    
    for cdID, data in pairs(detached) do
      if not cdmIconCache[cdID] then
        -- Get spell info from API
        local info = type(cdID) == "number" and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
        
        -- CRITICAL: If CDM API returns nil, this cooldown was removed from CDM - skip it entirely
        if info then
          local spellID, name, icon
          local baseSpellID = info.spellID or 0
          local overrideSpellID = info.overrideSpellID
          local overrideTooltipSpellID = info.overrideTooltipSpellID
          local linkedSpellIDs = info.linkedSpellIDs
          local firstLinkedSpellID = linkedSpellIDs and linkedSpellIDs[1]
          local displaySpellID = firstLinkedSpellID or overrideSpellID or baseSpellID
          
          spellID = baseSpellID
          name = displaySpellID and C_Spell.GetSpellName(displaySpellID)
          
          -- Determine if this is an aura (for icon priority logic)
          local isAuraType = data.viewerType == "aura"
          
          -- ICON PRIORITY: Read from frame first (shows actual CDM texture)
          -- NOTE: In combat, GetTexture() may return secret values - use issecretvalue() to check
          local frame = data.frame
          if frame and frame.Icon then
            -- Try GetTexture first
            if frame.Icon.GetTexture then
              local tex = frame.Icon:GetTexture()
              if tex and not issecretvalue(tex) and tex ~= 0 and tex ~= "" then
                icon = tex
              end
            end
            -- Try GetTextureFileID as fallback
            if not icon and frame.Icon.GetTextureFileID then
              local texID = frame.Icon:GetTextureFileID()
              if texID and not issecretvalue(texID) and texID > 0 then
                icon = texID
              end
            end
            -- Bar viewer structure
            if not icon and frame.Icon.Icon then
              if frame.Icon.Icon.GetTexture then
                local tex = frame.Icon.Icon:GetTexture()
                if tex and not issecretvalue(tex) and tex ~= 0 and tex ~= "" then
                  icon = tex
                end
              end
            end
          end
          
          -- Fallback to API with aura-aware ordering
          if not icon then
            if isAuraType then
              -- Auras: try overrideTooltipSpellID first (this is what CDM uses for display)
              if overrideTooltipSpellID and overrideTooltipSpellID > 0 then
                icon = C_Spell.GetSpellTexture(overrideTooltipSpellID)
              end
              if not icon and baseSpellID > 0 then
                icon = C_Spell.GetSpellTexture(baseSpellID)
              end
              if not icon and overrideSpellID then
                icon = C_Spell.GetSpellTexture(overrideSpellID)
              end
              if not icon and displaySpellID then
                icon = C_Spell.GetSpellTexture(displaySpellID)
              end
            else
              -- Cooldowns: use override/linked chain
              icon = displaySpellID and C_Spell.GetSpellTexture(displaySpellID)
              if not icon and overrideSpellID then
                icon = C_Spell.GetSpellTexture(overrideSpellID)
              end
              if not icon and baseSpellID > 0 then
                icon = C_Spell.GetSpellTexture(baseSpellID)
              end
            end
          end
          
          -- Name fallbacks
          if not name and overrideSpellID then
            name = C_Spell.GetSpellName(overrideSpellID)
          end
          if not name and baseSpellID > 0 then
            name = C_Spell.GetSpellName(baseSpellID)
          end
        
          -- Determine category based on viewerType AND viewerName
          local category, isAura = "TrackedBuff", true
          if data.viewerType == "cooldown" then
            category = "Essential"
            isAura = false
          elseif data.viewerType == "utility" then
            category = "Utility"
            isAura = false
          elseif data.viewerType == "aura" then
            -- Check viewerName to distinguish TrackedBuff from TrackedBar
            if data.viewerName == "BuffBarCooldownViewer" then
              category = "TrackedBar"
            else
              category = "TrackedBuff"
            end
            isAura = true
          end
          
          cdmIconCache[cdID] = {
            cooldownID = cdID,
            spellID = spellID or 0,
            name = name or "Unknown",
            icon = icon or 134400,
            category = category,
            categoryName = CATEGORY_NAMES[category] or category,
            viewerType = data.viewerType,
            viewerName = data.viewerName,
            isAura = isAura,
            isTrackedBuff = category == "TrackedBuff",
            isTrackedBar = category == "TrackedBar",
            isEssential = category == "Essential",
            isUtility = category == "Utility",
            frame = data.frame,
            iconFrame = category == "TrackedBuff" and data.frame or nil,
            barFrame = category == "TrackedBar" and data.frame or nil,
            slotIndex = -1,  -- Detached frames don't have a slot index
            isDetached = true,
            hasAura = info.hasAura,
            selfAura = info.selfAura,
            charges = info.charges,
            flags = info.flags,
          }
          totalCount = totalCount + 1
        end  -- end if info
      end
    end
  end
  
  -- Include frames from CDMGroups (frames in group containers)
  if ns.CDMGroups and ns.CDMGroups.GetAllGroupedFrames then
    local groupedFrames = ns.CDMGroups.GetAllGroupedFrames()
    
    for cdID, data in pairs(groupedFrames) do
      -- Get spell info from API
      local info = type(cdID) == "number" and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
      
      if info then
        local spellID, name, icon
        local baseSpellID = info.spellID or 0
        local overrideSpellID = info.overrideSpellID
        local overrideTooltipSpellID = info.overrideTooltipSpellID
        local linkedSpellIDs = info.linkedSpellIDs
        local firstLinkedSpellID = linkedSpellIDs and linkedSpellIDs[1]
        local displaySpellID = firstLinkedSpellID or overrideSpellID or baseSpellID
        
        spellID = baseSpellID
        name = displaySpellID and C_Spell.GetSpellName(displaySpellID)
        
        -- Determine if this is an aura (for icon priority logic)
        local isAuraType = data.viewerType == "aura"
        
        -- ICON PRIORITY: Read from frame first (shows actual CDM texture)
        -- NOTE: In combat, GetTexture() may return secret values - use issecretvalue() to check
        local frame = data.frame
        if frame and frame.Icon then
          -- Try GetTexture first
          if frame.Icon.GetTexture then
            local tex = frame.Icon:GetTexture()
            if tex and not issecretvalue(tex) and tex ~= 0 and tex ~= "" then
              icon = tex
            end
          end
          -- Try GetTextureFileID as fallback
          if not icon and frame.Icon.GetTextureFileID then
            local texID = frame.Icon:GetTextureFileID()
            if texID and not issecretvalue(texID) and texID > 0 then
              icon = texID
            end
          end
          -- Bar viewer structure
          if not icon and frame.Icon.Icon then
            if frame.Icon.Icon.GetTexture then
              local tex = frame.Icon.Icon:GetTexture()
              if tex and not issecretvalue(tex) and tex ~= 0 and tex ~= "" then
                icon = tex
              end
            end
          end
        end
        
        -- Fallback to API with aura-aware ordering
        if not icon then
          if isAuraType then
            -- Auras: try overrideTooltipSpellID first (this is what CDM uses for display)
            if overrideTooltipSpellID and overrideTooltipSpellID > 0 then
              icon = C_Spell.GetSpellTexture(overrideTooltipSpellID)
            end
            if not icon and baseSpellID > 0 then
              icon = C_Spell.GetSpellTexture(baseSpellID)
            end
            if not icon and overrideSpellID then
              icon = C_Spell.GetSpellTexture(overrideSpellID)
            end
            if not icon and displaySpellID then
              icon = C_Spell.GetSpellTexture(displaySpellID)
            end
          else
            -- Cooldowns: use override/linked chain
            icon = displaySpellID and C_Spell.GetSpellTexture(displaySpellID)
            if not icon and overrideSpellID then
              icon = C_Spell.GetSpellTexture(overrideSpellID)
            end
            if not icon and baseSpellID > 0 then
              icon = C_Spell.GetSpellTexture(baseSpellID)
            end
          end
        end
        
        -- Name fallbacks
        if not name and overrideSpellID then
          name = C_Spell.GetSpellName(overrideSpellID)
        end
        if not name and baseSpellID > 0 then
          name = C_Spell.GetSpellName(baseSpellID)
        end
        
        -- Determine category based on viewerType
        local category, isAura = "TrackedBuff", true
        if data.viewerType == "cooldown" then
          category = "Essential"
          isAura = false
        elseif data.viewerType == "utility" then
          category = "Utility"
          isAura = false
        elseif data.viewerType == "aura" then
          category = "TrackedBuff"
          isAura = true
        end
        
        -- Update existing entry or create new one
        if cdmIconCache[cdID] then
          -- Update frame reference (it may have been reparented)
          cdmIconCache[cdID].frame = data.frame
          cdmIconCache[cdID].trackingType = "group"
          cdmIconCache[cdID].groupName = data.groupName
          cdmIconCache[cdID].gridPosition = data.gridPosition
        else
          cdmIconCache[cdID] = {
            cooldownID = cdID,
            spellID = spellID or 0,
            name = name or "Unknown",
            icon = icon or 134400,
            category = category,
            categoryName = CATEGORY_NAMES[category] or category,
            viewerType = data.viewerType,
            viewerName = data.originalViewerName,
            isAura = isAura,
            isTrackedBuff = category == "TrackedBuff",
            isTrackedBar = category == "TrackedBar",
            isEssential = category == "Essential",
            isUtility = category == "Utility",
            frame = data.frame,
            iconFrame = category == "TrackedBuff" and data.frame or nil,
            barFrame = category == "TrackedBar" and data.frame or nil,
            slotIndex = -1,
            isDetached = false,
            trackingType = "group",
            groupName = data.groupName,
            gridPosition = data.gridPosition,
            hasAura = info.hasAura,
            selfAura = info.selfAura,
            charges = info.charges,
            flags = info.flags,
          }
          totalCount = totalCount + 1
        end
      end
    end
  end
  
  lastScanTime = GetTime()
  
  if ns.devMode then
    local auraCount, cdCount, detachedCount = 0, 0, 0
    for _, data in pairs(cdmIconCache) do
      if data.isAura then auraCount = auraCount + 1 else cdCount = cdCount + 1 end
      if data.isDetached then detachedCount = detachedCount + 1 end
    end
    print(string.format("|cff00FF00[ArcUI CDM]|r Scan complete: %d auras, %d cooldowns (%d detached)", auraCount, cdCount, detachedCount))
  end
  
  -- Notify listeners that scan completed
  if ns.CDMEnhance and ns.CDMEnhance.OnCDMScanComplete then
    ns.CDMEnhance.OnCDMScanComplete()
  end
  if ns.Catalog and ns.Catalog.OnCDMScanComplete then
    ns.Catalog.OnCDMScanComplete()
  end
  
  return totalCount
end

-- ===================================================================
-- CDM ICON API - Unified access for all modules
-- ===================================================================

-- Get all CDM icons
function ns.API.GetAllCDMIcons()
  return cdmIconCache
end

-- Get single icon by cooldownID
function ns.API.GetCDMIcon(cooldownID)
  return cdmIconCache[cooldownID]
end

-- Get icon frame by cooldownID
function ns.API.GetCDMIconFrame(cooldownID)
  local data = cdmIconCache[cooldownID]
  return data and data.frame
end

-- Get all aura icons (BuffIcon + BuffBar viewers)
function ns.API.GetCDMAuraIcons()
  local result = {}
  for cdID, data in pairs(cdmIconCache) do
    if data.isAura then
      result[cdID] = data
    end
  end
  return result
end

-- Get all cooldown icons (Essential + Utility viewers)
function ns.API.GetCDMCooldownIcons()
  local result = {}
  for cdID, data in pairs(cdmIconCache) do
    if not data.isAura then
      result[cdID] = data
    end
  end
  return result
end

-- Get icons by category
function ns.API.GetCDMIconsByCategory(category)
  local result = {}
  for cdID, data in pairs(cdmIconCache) do
    if data.category == category or data.category == "TrackedBuff+Bar" and 
       (category == "TrackedBuff" or category == "TrackedBar") then
      result[cdID] = data
    end
  end
  return result
end

-- Get icons by viewer type ("aura", "cooldown", "utility")
function ns.API.GetCDMIconsByViewerType(viewerType)
  local result = {}
  for cdID, data in pairs(cdmIconCache) do
    if data.viewerType == viewerType then
      result[cdID] = data
    end
  end
  return result
end

-- Check if a cooldownID is displayed
function ns.API.IsCDMIconDisplayed(cooldownID)
  return cdmIconCache[cooldownID] ~= nil
end

-- Get displayed cooldownIDs (legacy compatibility)
function ns.API.GetDisplayedCooldownIDs()
  local displayed = {}
  for cdID, data in pairs(cdmIconCache) do
    displayed[cdID] = data.category
  end
  return displayed
end

-- Check if a specific cooldownID is displayed (in any viewer)
function ns.API.IsCooldownDisplayed(cooldownID)
  return cdmIconCache[cooldownID] ~= nil
end

-- Check if cooldownID is in Essential or Utility viewers
function ns.API.IsCooldownInEssentialOrUtility(cooldownID)
  local data = cdmIconCache[cooldownID]
  return data and (data.isEssential or data.isUtility)
end

-- Check if cooldownID is in TrackedBuff or TrackedBar viewers
function ns.API.IsAuraDisplayed(cooldownID)
  local data = cdmIconCache[cooldownID]
  return data and data.isAura
end

-- Get last scan time
function ns.API.GetCDMScanTime()
  return lastScanTime
end

-- Get sorted list of all icons (for options panels)
function ns.API.GetSortedCDMIcons(filterType)
  local sorted = {}
  for cdID, data in pairs(cdmIconCache) do
    local include = true
    if filterType == "aura" and not data.isAura then include = false end
    if filterType == "cooldown" and data.isAura then include = false end
    if filterType == "essential" and not data.isEssential then include = false end
    if filterType == "utility" and not data.isUtility then include = false end
    
    if include then
      table.insert(sorted, data)
    end
  end
  
  table.sort(sorted, function(a, b)
    return (a.name or "") < (b.name or "")
  end)
  
  return sorted
end

-- Get icon count by type
function ns.API.GetCDMIconCount()
  local auraCount, cooldownCount = 0, 0
  for _, data in pairs(cdmIconCache) do
    if data.isAura then
      auraCount = auraCount + 1
    else
      cooldownCount = cooldownCount + 1
    end
  end
  return auraCount, cooldownCount
end

-- Legacy compatibility aliases
ns.API.ScanCatalog = ns.API.ScanAllCDMIcons
ns.API.ScanCDM = ns.API.ScanAllCDMIcons

-- ===================================================================
-- INITIALIZATION
-- ===================================================================
local function InitializeTracking()
  if not ns.API.GetDB or not ns.API.GetBarConfig then
    C_Timer.After(0.5, InitializeTracking)
    return
  end
  if InCombatLockdown() then
    C_Timer.After(2.0, InitializeTracking)
    return
  end
  ns.API.ValidateAllBarTracking()
end

C_Timer.After(1.5, InitializeTracking)

-- ===================================================================
-- LIBPLEEBUG FUNCTION WRAPPING
-- Wrap heavy functions for CPU profiling
-- ===================================================================
if P then
  -- Config Lookups (called frequently)
  ns.API.GetBarConfig = P:Def("GetBarConfig", ns.API.GetBarConfig, "Config")
  ns.API.GetActiveBars = P:Def("GetActiveBars", ns.API.GetActiveBars, "Config")
  ns.API.GetActiveResourceBars = P:Def("GetActiveResourceBars", ns.API.GetActiveResourceBars, "Config")
  
  -- Tracking
  ns.API.UpdateAllBars = P:Def("UpdateAllBars", ns.API.UpdateAllBars, "Tracking")
  ns.API.ValidateAllBarTracking = P:Def("ValidateAllBarTracking", ns.API.ValidateAllBarTracking, "Tracking")
end

-- ===================================================================
-- END OF ArcUI_Core.lua
-- ===================================================================