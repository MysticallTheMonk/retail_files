-- ===================================================================
-- ArcUI_CDMEnhance.lua
-- Enhanced CDM icon customization with aspect ratio, padding,

-- ===================================================================

local ADDON, ns = ...

ns.CDMEnhance = ns.CDMEnhance or {}

-- Use shared CDM constants and helpers (from ArcUI_CDM_Shared.lua)
local Shared = ns.CDMShared

-- ===================================================================
-- CACHED ENABLED STATE (avoid repeated DB lookups)
-- Updated on profile change, settings toggle, or explicit refresh
-- ===================================================================
local cachedCDMGroupsEnabled = true  -- Assume enabled until proven otherwise
local cachedStylingEnabled = true    -- Master styling toggle

-- Update cached enabled state (call on profile change or settings toggle)
local function RefreshCachedEnabledState()
  -- Check CDMGroups enabled
  local groupsDB = Shared and Shared.GetCDMGroupsDB and Shared.GetCDMGroupsDB()
  cachedCDMGroupsEnabled = groupsDB and groupsDB.enabled ~= false
  
  -- Check master styling toggle
  cachedStylingEnabled = Shared and Shared.IsCDMStylingEnabled and Shared.IsCDMStylingEnabled() or true
  
  -- Also refresh Shared's cached state (so other modules stay in sync)
  if Shared and Shared.RefreshCachedEnabledState then
    Shared.RefreshCachedEnabledState()
  end
  
  -- Also refresh CDMGroups' module-level boolean
  if ns.CDMGroups and ns.CDMGroups.RefreshCachedEnabledState then
    ns.CDMGroups.RefreshCachedEnabledState()
  end
end

-- Fast check functions (no DB lookup)
local function IsCDMGroupsEnabledCached()
  return cachedCDMGroupsEnabled
end

local function IsCDMStylingEnabledCached()
  return cachedStylingEnabled
end

-- Export for other modules
ns.CDMEnhance.RefreshCachedEnabledState = RefreshCachedEnabledState
ns.CDMEnhance.IsCDMGroupsEnabledCached = IsCDMGroupsEnabledCached

-- ===================================================================
-- CENTRALIZED BORDER WATCHER
-- Replaces per-frame OnUpdate hooks (was 25 frames × 60fps = 1500 calls/sec!)
-- Now: ONE watcher running at 2Hz = ~2 calls/sec
-- ===================================================================
local borderWatchFrames = {}  -- {[frame] = {lastPandemicIcon = ...}}
local borderWatcherFrame = CreateFrame("Frame")
local borderWatcherElapsed = 0
local BORDER_WATCHER_INTERVAL = 0.5  -- 2Hz

-- Table to hold border functions (populated after they're defined)
local BorderFuncs = {}

-- Register a frame for border watching (called from ApplySettings)
local function RegisterBorderWatch(frame)
  if not frame or borderWatchFrames[frame] then return end
  borderWatchFrames[frame] = { lastPandemicIcon = frame.PandemicIcon }
end

-- Unregister (if frame is destroyed)
local function UnregisterBorderWatch(frame)
  borderWatchFrames[frame] = nil
end

-- The centralized OnUpdate - runs 2Hz instead of 60Hz per frame
borderWatcherFrame:SetScript("OnUpdate", function(self, elapsed)
  borderWatcherElapsed = borderWatcherElapsed + elapsed
  if borderWatcherElapsed < BORDER_WATCHER_INTERVAL then return end
  borderWatcherElapsed = 0
  
  -- Get functions from table (populated after file loads)
  local EnableBorder = BorderFuncs.Enable
  local DisableBorder = BorderFuncs.Disable
  if not EnableBorder or not DisableBorder then return end
  
  for frame, data in pairs(borderWatchFrames) do
    -- Validate frame still exists
    if not frame.GetObjectType then
      borderWatchFrames[frame] = nil
    else
      local pad = frame._arcPadding or 0
      local zm = frame._arcZoom or 0
      
      -- Check for new PandemicIcon (CDM may have replaced it)
      data.lastPandemicIcon = frame.PandemicIcon
      
      -- Sync PandemicIcon
      if frame.PandemicIcon then
        local pi = frame.PandemicIcon
        local needsHooks = not pi._arcBorderHooked_pandemic
        
        if frame._arcShowPandemic then
          if needsHooks or pi._arcShowEnabled ~= true or pi._arcSizedForParent ~= frame or
             pi._arcSizedWithZoom ~= zm or pi._arcSizedWithPadding ~= pad then
            EnableBorder(pi, frame, pad, zm, "pandemic")
          end
        else
          if needsHooks or pi._arcShowEnabled ~= false or (pi.IsShown and pi:IsShown()) then
            DisableBorder(pi, "pandemic")
          end
        end
      end
      
      -- Sync DebuffBorder
      if frame.DebuffBorder then
        local db = frame.DebuffBorder
        local needsHooks = not db._arcBorderHooked_debuff
        
        if frame._arcShowDebuffBorder then
          if needsHooks or db._arcShowEnabled ~= true or db._arcSizedForParent ~= frame or
             db._arcSizedWithZoom ~= zm or db._arcSizedWithPadding ~= pad then
            EnableBorder(db, frame, pad, zm, "debuff")
          end
        else
          if needsHooks or db._arcShowEnabled ~= false or (db.IsShown and db:IsShown()) then
            DisableBorder(db, "debuff")
          end
        end
      end
      
      -- Enforce CooldownFlash hiding
      if frame._arcHideCooldownFlash and frame.CooldownFlash then
        frame.CooldownFlash:SetAlpha(0)
        if frame.CooldownFlash.Flipbook then
          frame.CooldownFlash.Flipbook:SetAlpha(0)
        end
      end
    end
  end
end)

-- Export for cleanup
ns.CDMEnhance.UnregisterBorderWatch = UnregisterBorderWatch
ns.CDMEnhance._BorderFuncs = BorderFuncs  -- So we can populate it later

-- ===================================================================
-- COOLDOWN DETECTION CURVES
-- Created once at addon load, reused for all cooldown state checks
-- These transform remaining% into usable values for secret-safe APIs
-- ===================================================================
local CooldownCurves = {
  initialized = false,
  Binary = nil,      -- ready=0, onCD=1 (for SetDesaturation)
  BinaryInv = nil,   -- ready=1, onCD=0 (for SetAlpha hide)
  Dim50 = nil,       -- ready=1, onCD=0.5
  Dim30 = nil,       -- ready=1, onCD=0.3
}

local function InitCooldownCurves()
  if CooldownCurves.initialized then return true end
  if not C_CurveUtil or not C_CurveUtil.CreateCurve then
    return false
  end
  
  -- Binary: ready=0, onCD=1
  -- Use for: SetDesaturation (0=colored, 1=grayscale)
  CooldownCurves.Binary = C_CurveUtil.CreateCurve()
  CooldownCurves.Binary:AddPoint(0.0, 0)     -- 0% remaining (ready) → 0
  CooldownCurves.Binary:AddPoint(0.001, 1)   -- >0% remaining (on CD) → 1
  CooldownCurves.Binary:AddPoint(1.0, 1)
  
  -- BinaryInv: ready=1, onCD=0
  -- Use for: SetAlpha (1=show, 0=hide)
  CooldownCurves.BinaryInv = C_CurveUtil.CreateCurve()
  CooldownCurves.BinaryInv:AddPoint(0.0, 1)     -- 0% remaining (ready) → 1 (show)
  CooldownCurves.BinaryInv:AddPoint(0.001, 0)   -- >0% remaining (on CD) → 0 (hide)
  CooldownCurves.BinaryInv:AddPoint(1.0, 0)
  
  -- Dim50: ready=1, onCD=0.5
  CooldownCurves.Dim50 = C_CurveUtil.CreateCurve()
  CooldownCurves.Dim50:AddPoint(0.0, 1)
  CooldownCurves.Dim50:AddPoint(0.001, 0.5)
  CooldownCurves.Dim50:AddPoint(1.0, 0.5)
  
  -- Dim30: ready=1, onCD=0.3
  CooldownCurves.Dim30 = C_CurveUtil.CreateCurve()
  CooldownCurves.Dim30:AddPoint(0.0, 1)
  CooldownCurves.Dim30:AddPoint(0.001, 0.3)
  CooldownCurves.Dim30:AddPoint(1.0, 0.3)
  
  CooldownCurves.initialized = true
  return true
end

-- Create a dim curve for a specific alpha value (cached)
local dimCurveCache = {}
local function GetDimCurve(dimAlpha)
  if not C_CurveUtil or not C_CurveUtil.CreateCurve then return nil end
  
  -- Use pre-made curves for common values
  if dimAlpha == 0.5 then return CooldownCurves.Dim50 end
  if dimAlpha == 0.3 then return CooldownCurves.Dim30 end
  
  -- Check cache
  local key = tostring(dimAlpha)
  if dimCurveCache[key] then return dimCurveCache[key] end
  
  -- Create and cache custom curve
  local curve = C_CurveUtil.CreateCurve()
  curve:AddPoint(0.0, 1)
  curve:AddPoint(0.001, dimAlpha)
  curve:AddPoint(1.0, dimAlpha)
  dimCurveCache[key] = curve
  return curve
end

-- Cache for two-state alpha curves (ready → cooldown transitions)
local alphaCurveCache = {}

-- Get or create a two-state alpha curve for ready/cooldown transitions
local function GetTwoStateAlphaCurve(readyAlpha, cooldownAlpha)
  if not C_CurveUtil or not C_CurveUtil.CreateCurve then return nil end
  
  local key = string.format("%.2f_%.2f", readyAlpha, cooldownAlpha)
  if alphaCurveCache[key] then return alphaCurveCache[key] end
  
  local curve = C_CurveUtil.CreateCurve()
  curve:AddPoint(0.0, readyAlpha)       -- 0% remaining (ready) → readyAlpha
  curve:AddPoint(0.001, cooldownAlpha)  -- >0% remaining (on CD) → cooldownAlpha
  curve:AddPoint(1.0, cooldownAlpha)
  
  alphaCurveCache[key] = curve
  return curve
end

-- Export curves for other modules
ns.CDMEnhance.CooldownCurves = CooldownCurves
ns.CDMEnhance.GetDimCurve = GetDimCurve
ns.CDMEnhance.GetTwoStateAlphaCurve = GetTwoStateAlphaCurve
ns.CDMEnhance.InitCooldownCurves = InitCooldownCurves

-- Cache for glow threshold curves
local glowThresholdCurveCache = {}

-- Forward declarations for threshold glow tracking (defined later)
local StartThresholdGlowTracking
local StopThresholdGlowTracking

-- Get or create a threshold curve for glow visibility
-- Returns 1 when remaining % <= threshold (show glow), 0 when above (hide glow)
local function GetGlowThresholdCurve(threshold)
  if not C_CurveUtil or not C_CurveUtil.CreateCurve then return nil end
  
  local key = math.floor(threshold * 1000)
  if glowThresholdCurveCache[key] then return glowThresholdCurveCache[key] end
  
  local curve = C_CurveUtil.CreateCurve()
  curve:AddPoint(0.0, 1)                    -- 0% remaining = show glow
  curve:AddPoint(threshold, 1)              -- at threshold = show glow  
  curve:AddPoint(threshold + 0.001, 0)      -- just above threshold = hide
  curve:AddPoint(1.0, 0)                    -- 100% remaining = hide glow
  
  glowThresholdCurveCache[key] = curve
  return curve
end

-- Export for CooldownState module
ns.CDMEnhance.GetGlowThresholdCurve = GetGlowThresholdCurve

-- Debug output - only outputs when debug mode is enabled
local function DebugLog(msg)
  -- Only log if debug mode is enabled
  if not ArcUI_CDMEnhance_Debug then return end
  
  local line = date("%H:%M:%S") .. " [Enhance] " .. tostring(msg)
  _G.ARCUI_DEBUG = _G.ARCUI_DEBUG or {}
  table.insert(_G.ARCUI_DEBUG, line)
  if #_G.ARCUI_DEBUG > 500 then table.remove(_G.ARCUI_DEBUG, 1) end
  
  -- Also write to CDMGroups buffer
  if ns.CDMGroups and ns.CDMGroups.debugBuffer then
    table.insert(ns.CDMGroups.debugBuffer, line)
    if #ns.CDMGroups.debugBuffer > 500 then table.remove(ns.CDMGroups.debugBuffer, 1) end
  end
  
  print("|cffFF00FF[ArcUI]|r " .. tostring(msg))
end

-- Export for other files
ns.CDMEnhance.DebugLog = DebugLog

-- ===================================================================
-- ICON TEXTURE HELPER
-- Gets the actual icon texture from a CDM frame, with API fallback
-- Priority: frame.Icon:GetTexture() > GetTextureFileID() > API with overrideTooltipSpellID
-- For auras: CDM often uses overrideTooltipSpellID for display
-- For cooldowns: use override/linked chain
-- NOTE: In combat, GetTexture() may return secret values - use issecretvalue() to check
-- ===================================================================
local function GetIconTextureFromFrame(frame, isAura, baseSpellID, overrideSpellID, displaySpellID, overrideTooltipSpellID)
  local icon = nil
  
  -- Try to read from frame first (shows actual CDM texture)
  if frame and frame.Icon then
    local iconTex = frame.Icon
    
    -- Try GetTexture first (most common)
    -- Check for secret value before comparing (combat restriction)
    if not icon and iconTex.GetTexture then
      local tex = iconTex:GetTexture()
      if tex and not issecretvalue(tex) and tex ~= 0 and tex ~= "" then
        icon = tex
      end
    end
    
    -- Try GetTextureFileID (returns numeric ID)
    if not icon and iconTex.GetTextureFileID then
      local texID = iconTex:GetTextureFileID()
      if texID and not issecretvalue(texID) and texID > 0 then
        icon = texID
      end
    end
    
    -- Try GetTextureFilePath (returns string path)
    if not icon and iconTex.GetTextureFilePath then
      local texPath = iconTex:GetTextureFilePath()
      if texPath and not issecretvalue(texPath) and texPath ~= "" then
        icon = texPath
      end
    end
    
    -- Bar viewer structure: frame.Icon.Icon
    if not icon and frame.Icon.Icon then
      local innerIcon = frame.Icon.Icon
      if innerIcon.GetTexture then
        local tex = innerIcon:GetTexture()
        if tex and not issecretvalue(tex) and tex ~= 0 and tex ~= "" then
          icon = tex
        end
      end
      if not icon and innerIcon.GetTextureFileID then
        local texID = innerIcon:GetTextureFileID()
        if texID and not issecretvalue(texID) and texID > 0 then
          icon = texID
        end
      end
    end
  end
  
  -- Fallback to API with type-aware ordering
  if not icon then
    if isAura then
      -- Auras: try overrideTooltipSpellID first (this is what CDM uses for display)
      if overrideTooltipSpellID and overrideTooltipSpellID > 0 then
        icon = C_Spell.GetSpellTexture(overrideTooltipSpellID)
      end
      -- Then try base spellID
      if not icon and baseSpellID and baseSpellID > 0 then
        icon = C_Spell.GetSpellTexture(baseSpellID)
      end
      if not icon and overrideSpellID then
        icon = C_Spell.GetSpellTexture(overrideSpellID)
      end
      if not icon and displaySpellID then
        icon = C_Spell.GetSpellTexture(displaySpellID)
      end
    else
      -- Cooldowns: use override/linked chain (existing behavior)
      if displaySpellID then
        icon = C_Spell.GetSpellTexture(displaySpellID)
      end
      if not icon and overrideSpellID then
        icon = C_Spell.GetSpellTexture(overrideSpellID)
      end
      if not icon and baseSpellID and baseSpellID > 0 then
        icon = C_Spell.GetSpellTexture(baseSpellID)
      end
    end
  end
  
  return icon or 134400  -- Default question mark icon
end

-- Export helper for other modules
ns.CDMEnhance.GetIconTextureFromFrame = GetIconTextureFromFrame

-- ===================================================================
-- LOCALS
-- ===================================================================
local isUnlocked = false
local textDragMode = false  -- Separate unlock for text dragging
local cooldownPreviewMode = false  -- Preview cooldown animation
local enhancedFrames = {}   -- [cooldownID] = { frame, viewerType, viewerName }

-- Forward declarations for functions used before definition
local ApplyIconStyle
local GetEffectiveStateVisuals
local ApplyCooldownStateVisuals
local HideCDMProcGlow  -- Used in Show hook before full definition
local ResizeProcGlowAlert  -- Used in ApplyIconStyle for default glow resize

-- Selection tracking for options panel editing
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- Debug output frame (created on demand)
local debugFrame = nil

-- Store the current group scale per viewer type (from CDM Edit Mode)
-- This is captured when CDM calls SetScale on icons
-- Initialized with defaults, then updated from DB and CDM
local groupScales = {
  aura = 1.0,
  cooldown = 1.0,
  utility = 1.0,
}

-- Map our viewerType to CDM viewer frames (from shared module)
local VIEWER_FRAME_MAP = Shared.VIEWER_FRAME_MAP

-- ===================================================================
-- CENTRALIZED COOLDOWN STATE DETECTION
-- Uses WoW 12.0 secret-safe APIs for reliable cooldown detection
-- 
-- Key insight: isOnGCD is NOT secret and can be compared directly
-- For CHARGE SPELLS: Use GetSpellChargeDuration which tracks recharge, not GCD
-- ===================================================================

-- Get comprehensive cooldown state for a spell
-- Returns: isOnGCD (bool), durationObj, isChargeSpell, chargeDurObj
-- 
-- For CHARGE SPELLS:
--   - chargeDurObj is from GetSpellChargeDuration (recharge timer, ignores GCD)
--   - Use this for alpha/desat curves to properly track recharge state
--
-- For NORMAL SPELLS:
--   - isOnGCD indicates if ONLY on GCD (can be compared directly)
--   - durationObj is from GetSpellCooldownDuration
local function GetSpellCooldownState(spellID)
  if not spellID then return nil, nil, false, nil end
  
  -- Check if this is a charge spell
  local chargeInfo = nil
  local isChargeSpell = false
  pcall(function()
    chargeInfo = C_Spell.GetSpellCharges(spellID)
    isChargeSpell = chargeInfo ~= nil
  end)
  
  -- Get basic cooldown info - wrap in pcall in case cdInfo is secret
  -- ONLY set isOnGCD when it's explicitly true - treat false same as nil
  local isOnGCD = nil
  pcall(function()
    local cdInfo = C_Spell.GetSpellCooldown(spellID)
    if cdInfo and cdInfo.isOnGCD == true then
      isOnGCD = true
    end
    -- If cdInfo.isOnGCD is false or nil, leave isOnGCD as nil
    -- This way we only react to "definitely on GCD", not "definitely not on GCD"
  end)
  
  -- Get duration objects
  local durationObj = nil
  local chargeDurObj = nil
  
  -- For charge spells, get charge duration (tracks recharge, ignores GCD)
  if isChargeSpell and C_Spell.GetSpellChargeDuration then
    local ok, obj = pcall(C_Spell.GetSpellChargeDuration, spellID)
    if ok and obj then
      chargeDurObj = obj
    end
  end
  
  -- Always get regular cooldown duration too
  if C_Spell.GetSpellCooldownDuration then
    local ok, obj = pcall(C_Spell.GetSpellCooldownDuration, spellID)
    if ok and obj then
      durationObj = obj
    end
  end
  
  return isOnGCD, durationObj, isChargeSpell, chargeDurObj
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CHARGE SPELL ANIMATION HELPER
-- Export the centralized API
ns.CDMEnhance.GetSpellCooldownState = GetSpellCooldownState

-- ═══════════════════════════════════════════════════════════════════════════
-- TOTEM DETECTION HELPER
-- Totems are a special case in CDM - they appear as category 2 but hasAura=false
-- WoW 12.0: totemData ONLY EXISTS when totem is currently active (it's a secret table)
-- When totem expires, totemData becomes nil but preferredTotemUpdateSlot persists!
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if a frame has active totem
-- Returns: hasTotemData, isTotemActive, totemSlot
local function GetTotemState(frame)
  if not frame then return false, false, nil end
  
  -- Only frames with preferredTotemUpdateSlot are totem frames
  local slotVal = frame.preferredTotemUpdateSlot
  if slotVal and type(slotVal) == "number" and slotVal > 0 then
    -- WoW 12.0: totemData ONLY EXISTS when totem is active
    -- When totem expires, totemData becomes nil
    if frame.totemData ~= nil then
      return true, true, slotVal  -- isTotemFrame=true, isActive=true, slot
    else
      return true, false, slotVal  -- isTotemFrame=true, isActive=false, slot
    end
  end
  
  return false, false, nil
end

-- Export for other modules
ns.CDMEnhance.GetTotemState = GetTotemState

-- ===================================================================
-- GLOW STOP HELPER
-- Consolidates the repeated pattern of stopping all glow types
-- ===================================================================
-- LCG is lazy-loaded: library may load after this file
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

-- Lazy getter - ensures we get the library even if it loaded late
local function GetLCG()
  if not LCG then
    LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
  end
  return LCG
end

-- Stop all glow effects on a frame
-- @param frame: The frame to stop glows on
-- @param key: Optional glow key (e.g., "ArcUI_Glow", "ArcUI_Preview", "ArcUI_ReadyGlow")
local function StopAllGlows(frame, key)
  local lcg = GetLCG()
  if not frame or not lcg then return end
  local glowKey = key or "ArcUI_Glow"
  pcall(lcg.PixelGlow_Stop, frame, glowKey)
  pcall(lcg.AutoCastGlow_Stop, frame, glowKey)
  -- ButtonGlow doesn't support keys - check ALL systems that might be using it
  local procUsingButtonGlow = frame._arcProcGlowActive and frame._arcProcGlowType == "button"
  local procPreviewUsingButtonGlow = frame._arcProcPreviewActive and frame._arcProcPreviewType == "button"
  local settingsPreviewUsingButtonGlow = frame._arcGlowPreviewActive and frame._arcGlowPreviewType == "button"
  local readyGlowUsingButtonGlow = frame._arcReadyGlowActive and frame._arcCurrentGlowType == "button"
  
  -- Only stop ButtonGlow if we own it AND nothing else is using it
  local shouldStopButtonGlow = false
  if glowKey == "ArcUI_ProcGlow" and procUsingButtonGlow then
    -- We own it - stop only if nothing else is using it
    shouldStopButtonGlow = not procPreviewUsingButtonGlow and not settingsPreviewUsingButtonGlow and not readyGlowUsingButtonGlow
  elseif glowKey == "ArcUI_ProcPreview" and procPreviewUsingButtonGlow then
    -- We own it - stop only if nothing else is using it
    shouldStopButtonGlow = not procUsingButtonGlow and not settingsPreviewUsingButtonGlow and not readyGlowUsingButtonGlow
  elseif glowKey == "ArcUI_Preview" and settingsPreviewUsingButtonGlow then
    -- We own it - stop only if nothing else is using it
    shouldStopButtonGlow = not procUsingButtonGlow and not procPreviewUsingButtonGlow and not readyGlowUsingButtonGlow
  elseif glowKey == "ArcUI_ReadyGlow" and readyGlowUsingButtonGlow then
    -- We own it - stop only if nothing else is using it
    shouldStopButtonGlow = not procUsingButtonGlow and not procPreviewUsingButtonGlow and not settingsPreviewUsingButtonGlow
  elseif not procUsingButtonGlow and not procPreviewUsingButtonGlow and not settingsPreviewUsingButtonGlow and not readyGlowUsingButtonGlow then
    -- Nothing is using ButtonGlow, safe to stop (cleans up orphans)
    shouldStopButtonGlow = true
  end
  
  if shouldStopButtonGlow then
    pcall(lcg.ButtonGlow_Stop, frame)
  end
  pcall(lcg.ProcGlow_Stop, frame, glowKey)
end

-- Export for other modules
ns.CDMEnhance.StopAllGlows = StopAllGlows

-- ===================================================================
-- DATABASE
-- ===================================================================
-- Current settings version - increment when adding new migrations
local SETTINGS_VERSION = 7

-- Migrate a single settings table (icon or global) from legacy to current format
local function MigrateSettingsTable(cfg)
  if not cfg then return end
  
  -- Migration 1: inactiveState → cooldownStateVisuals.cooldownState
  if cfg.inactiveState then
    local legacy = cfg.inactiveState
    local hasLegacyData = legacy.hideWhenInactive or legacy.desaturateWhenInactive or (legacy.dimAlpha and legacy.dimAlpha < 1.0)
    
    if hasLegacyData then
      -- Ensure new structure exists
      if not cfg.cooldownStateVisuals then cfg.cooldownStateVisuals = {} end
      if not cfg.cooldownStateVisuals.cooldownState then cfg.cooldownStateVisuals.cooldownState = {} end
      
      local newState = cfg.cooldownStateVisuals.cooldownState
      
      -- Migrate alpha (hideWhenInactive = 0, dimAlpha = custom value)
      if legacy.hideWhenInactive then
        newState.alpha = 0
      elseif legacy.dimAlpha and legacy.dimAlpha < 1.0 then
        newState.alpha = legacy.dimAlpha
      end
      
      -- Migrate desaturate
      if legacy.desaturateWhenInactive then
        newState.desaturate = true
      end
    end
    
    -- Delete legacy inactiveState entirely
    cfg.inactiveState = nil
  end
  
  -- Migration 2: swipeMode → noGCDSwipe / ignoreAuraOverride
  if cfg.cooldownSwipe and cfg.cooldownSwipe.swipeMode then
    local swipeMode = cfg.cooldownSwipe.swipeMode
    
    if swipeMode == "noGCD" then
      cfg.cooldownSwipe.noGCDSwipe = true
    elseif swipeMode == "cooldownOnly" then
      cfg.cooldownSwipe.ignoreAuraOverride = true
    end
    
    -- Delete legacy swipeMode
    cfg.cooldownSwipe.swipeMode = nil
  end
  
  -- Migration 3: Clean up empty sub-tables
  if cfg.cooldownStateVisuals then
    if cfg.cooldownStateVisuals.readyState and not next(cfg.cooldownStateVisuals.readyState) then
      cfg.cooldownStateVisuals.readyState = nil
    end
    if cfg.cooldownStateVisuals.cooldownState and not next(cfg.cooldownStateVisuals.cooldownState) then
      cfg.cooldownStateVisuals.cooldownState = nil
    end
    if not next(cfg.cooldownStateVisuals) then
      cfg.cooldownStateVisuals = nil
    end
  end
  
  -- Migration 4: Clear zoom=0 so it uses new default (0.075)
  -- Old default was 0, new default is 0.075 for cleaner icon edges
  if cfg.zoom == 0 then
    cfg.zoom = nil  -- nil = use DEFAULT_ICON_SETTINGS.zoom (0.075)
  end
  
  -- Migration 5: Clear edgeScale = 1.0 so CDM's default is used
  -- Our old default (1.0) was too small compared to CDM's actual default (~1.8)
  if cfg.cooldownSwipe and cfg.cooldownSwipe.edgeScale == 1.0 then
    cfg.cooldownSwipe.edgeScale = nil  -- nil = use CDM's default
  end
  
  -- Migration 6: Convert outline "NONE" to "" (WoW expects empty string, not "NONE")
  if cfg.chargeText and cfg.chargeText.outline == "NONE" then
    cfg.chargeText.outline = ""
  end
  if cfg.cooldownText and cfg.cooldownText.outline == "NONE" then
    cfg.cooldownText.outline = ""
  end
  
  -- Migration 7: Sanitize glow boolean values
  -- Convert any non-boolean truthy values to nil (so they fall back to defaults = false)
  -- This fixes a bug where glows could show unexpectedly due to corrupted saved variables
  if cfg.cooldownStateVisuals and cfg.cooldownStateVisuals.readyState then
    local rs = cfg.cooldownStateVisuals.readyState
    -- Glow must be exactly boolean true, anything else should be nil
    if rs.glow ~= nil and rs.glow ~= true and rs.glow ~= false then
      rs.glow = nil
    end
    -- If glow is false, remove it (nil = default = false, saves space)
    if rs.glow == false then
      rs.glow = nil
    end
    -- Sanitize related boolean fields
    if rs.glowCombatOnly ~= nil and rs.glowCombatOnly ~= true and rs.glowCombatOnly ~= false then
      rs.glowCombatOnly = nil
    end
    if rs.glowCombatOnly == false then
      rs.glowCombatOnly = nil
    end
    if rs.glowWhileChargesAvailable ~= nil and rs.glowWhileChargesAvailable ~= true and rs.glowWhileChargesAvailable ~= false then
      rs.glowWhileChargesAvailable = nil
    end
    if rs.glowWhileChargesAvailable == false then
      rs.glowWhileChargesAvailable = nil
    end
  end
  if cfg.cooldownStateVisuals and cfg.cooldownStateVisuals.cooldownState then
    local cs = cfg.cooldownStateVisuals.cooldownState
    -- Sanitize boolean fields
    if cs.desaturate ~= nil and cs.desaturate ~= true and cs.desaturate ~= false then
      cs.desaturate = nil
    end
    if cs.desaturate == false then
      cs.desaturate = nil
    end
    if cs.tint ~= nil and cs.tint ~= true and cs.tint ~= false then
      cs.tint = nil
    end
    if cs.tint == false then
      cs.tint = nil
    end
    if cs.noDesaturate ~= nil and cs.noDesaturate ~= true and cs.noDesaturate ~= false then
      cs.noDesaturate = nil
    end
    if cs.noDesaturate == false then
      cs.noDesaturate = nil
    end
  end
end

-- Clear ignoreAuraOverride from aura settings (auras shouldn't have this option)
local function ClearAuraIgnoreOverride(cfg)
  if cfg and cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride then
    cfg.cooldownSwipe.ignoreAuraOverride = nil
    return true
  end
  return false
end

-- Run all migrations on the entire database
local function RunMigrations(db)
  if not db then return end
  
  local currentVersion = db.settingsVersion or 0
  
  if currentVersion >= SETTINGS_VERSION then
    return -- Already up to date
  end
  
  print("|cff00ff00[ArcUI CDM]|r Running settings migration v" .. currentVersion .. " → v" .. SETTINGS_VERSION)
  
  -- Migrate all per-icon settings
  if db.iconSettings then
    local migratedCount = 0
    for cdID, cfg in pairs(db.iconSettings) do
      MigrateSettingsTable(cfg)
      migratedCount = migratedCount + 1
    end
    if migratedCount > 0 then
      print("|cff00ff00[ArcUI CDM]|r Migrated " .. migratedCount .. " icon settings")
    end
  end
  
  -- Migrate global aura settings
  if db.globalAuraSettings then
    MigrateSettingsTable(db.globalAuraSettings)
    -- Migration v3: Clear ignoreAuraOverride from auras (only valid for cooldowns)
    if ClearAuraIgnoreOverride(db.globalAuraSettings) then
      print("|cff00ff00[ArcUI CDM]|r Cleared ignoreAuraOverride from global aura defaults")
    end
  end
  
  -- Migrate global cooldown settings
  if db.globalCooldownSettings then
    MigrateSettingsTable(db.globalCooldownSettings)
  end
  
  -- Mark migrations complete
  db.settingsVersion = SETTINGS_VERSION
  print("|cff00ff00[ArcUI CDM]|r Settings migration complete")
  
  -- Schedule a scan after migration to refresh all icons with new settings
  -- Use C_Timer.After to ensure CDM system is ready
  C_Timer.After(1.0, function()
    if not InCombatLockdown() then
      print("|cff00ff00[ArcUI CDM]|r Refreshing icons after migration...")
      if ns.API and ns.API.ScanAllCDMIcons then
        ns.API.ScanAllCDMIcons()
      end
      if ns.CDMGroups and ns.CDMGroups.ScanAllViewers then
        ns.CDMGroups.ScanAllViewers()
      end
      if ns.CDMEnhance and ns.CDMEnhance.RefreshAllStyles then
        ns.CDMEnhance.RefreshAllStyles()
      end
    end
  end)
end

local function GetDB()
  -- Use profile for settings so they carry across characters
  if not ns.db then return nil end
  
  -- Primary storage in profile (cross-character for GLOBAL DEFAULTS ONLY)
  -- iconSettings and groupSettings are now per-spec in char.cdmGroups.specData
  if not ns.db.profile then ns.db.profile = {} end
  if not ns.db.profile.cdmEnhance then
    ns.db.profile.cdmEnhance = {
      enabled = true,
      settingsVersion = SETTINGS_VERSION,  -- New installs start at current version
      enableAuraCustomization = true,   -- Enable custom styling for aura icons
      enableCooldownCustomization = true, -- Enable custom styling for cooldown icons
      unlocked = false,
      textDragMode = false,
      -- Global "apply to all" toggles
      globalApplyScale = false,
      globalApplyHideShadow = false,
      -- v3.0: New behavior settings
      disableRightClickSelect = false,  -- Disable right-click to open per-icon options
      lockGridSize = false,             -- Prevent grid expansion when dragging icons
      -- NOTE: Migration tracking is now per-character in char.cdmGroups.migratedProfileIconSettings
    }
  end
  
  -- Migration from char to profile (one-time)
  if ns.db.char and ns.db.char.cdmEnhance then
    local charDB = ns.db.char.cdmEnhance
    local profileDB = ns.db.profile.cdmEnhance
    
    -- Migrate globalAuraSettings and globalCooldownSettings if they exist in char but not profile
    if charDB.globalAuraSettings and not profileDB.globalAuraSettings then
      profileDB.globalAuraSettings = CopyTable(charDB.globalAuraSettings)
    end
    if charDB.globalCooldownSettings and not profileDB.globalCooldownSettings then
      profileDB.globalCooldownSettings = CopyTable(charDB.globalCooldownSettings)
    end
    
    -- Clear old char storage
    ns.db.char.cdmEnhance = nil
  end
  
  -- Migration for new fields
  local db = ns.db.profile.cdmEnhance
  if db.enableAuraCustomization == nil then db.enableAuraCustomization = true end
  if db.enableCooldownCustomization == nil then db.enableCooldownCustomization = true end
  if db.globalApplyScale == nil then db.globalApplyScale = false end
  if db.globalApplyHideShadow == nil then db.globalApplyHideShadow = false end
  -- v3.0: New behavior settings migration
  if db.disableRightClickSelect == nil then db.disableRightClickSelect = false end
  if db.lockGridSize == nil then db.lockGridSize = false end
  
  -- Initialize global settings tables (user-configurable defaults - SHARED across all specs)
  if not db.globalAuraSettings then db.globalAuraSettings = {} end
  if not db.globalCooldownSettings then db.globalCooldownSettings = {} end
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- FIRST-TIME USER DEFAULTS
  -- Set up sensible defaults for brand new installations
  -- Only applies when both global settings are completely empty (no user changes yet)
  -- ═══════════════════════════════════════════════════════════════════════════
  if not db._firstTimeDefaultsApplied then
    local auraEmpty = not next(db.globalAuraSettings)
    local cooldownEmpty = not next(db.globalCooldownSettings)
    
    if auraEmpty and cooldownEmpty then
      -- This is a brand new user - set up recommended defaults
      
      -- Aura Defaults
      db.globalAuraSettings = {
        hideShadow = true,  -- Hide CDM shadow for cleaner look
        border = {
          enabled = true,
          color = {0, 0, 0, 1},  -- Black border
          thickness = 1,
          inset = 0,
        },
      }
      
      -- Cooldown Defaults
      db.globalCooldownSettings = {
        hideShadow = true,  -- Hide CDM shadow for cleaner look
        border = {
          enabled = true,
          color = {0, 0, 0, 1},  -- Black border
          thickness = 1,
          inset = 0,
        },
        cooldownSwipe = {
          noGCDSwipe = true,  -- Hide GCD swipes (cleaner during combat)
        },
        rangeIndicator = {
          enabled = false,  -- Disable range indicator overlay
        },
      }
      
      print("|cff00ff00[ArcUI CDM]|r Applied recommended defaults for new installation")
    end
    
    -- Mark as processed so we don't overwrite user changes on subsequent loads
    db._firstTimeDefaultsApplied = true
  end
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- MIGRATION: iconSettings/groupSettings from profile to per-character storage
  -- - Old characters: migrate from profile.cdmEnhance to char.cdmGroups.specData
  -- - New characters: start fresh (no data to migrate)
  -- - Profile data is KEPT so other characters can still migrate from it
  -- ═══════════════════════════════════════════════════════════════════════════
  
  local cdmGroupsDB = Shared.GetCDMGroupsDB()
  if cdmGroupsDB and not cdmGroupsDB.migratedProfileIconSettings then
    local specData = Shared.GetCurrentSpecData()
    if specData then
      local didMigrate = false
      
      -- Migrate iconSettings if profile has them and active profile doesn't
      -- NOTE: Now writes to profile.iconSettings via Shared.GetSpecIconSettings()
      if db.iconSettings and next(db.iconSettings) then
        local profileIconSettings = Shared.GetSpecIconSettings()
        if profileIconSettings and (not next(profileIconSettings)) then
          for cdID, settings in pairs(db.iconSettings) do
            if not profileIconSettings[cdID] then
              profileIconSettings[cdID] = CopyTable(settings)
            end
          end
          print("|cff00ff00[ArcUI CDM]|r Migrated per-icon settings to profile storage")
          didMigrate = true
        end
      end
      
      -- Migrate groupSettings if profile has them and char spec doesn't
      if db.groupSettings and next(db.groupSettings) then
        if not specData.groupSettings or not next(specData.groupSettings.aura or {}) then
          for vtype, settings in pairs(db.groupSettings) do
            if type(settings) == "table" and next(settings) then
              if not specData.groupSettings[vtype] then
                specData.groupSettings[vtype] = {}
              end
              for k, v in pairs(settings) do
                if specData.groupSettings[vtype][k] == nil then
                  specData.groupSettings[vtype][k] = v
                end
              end
            end
          end
          if didMigrate then
            print("|cff00ff00[ArcUI CDM]|r Migrated group settings to character storage")
          end
          didMigrate = true
        end
      end
      
      -- Mark this character as checked (won't try to migrate again)
      cdmGroupsDB.migratedProfileIconSettings = true
    end
  end
  
  -- Clean up old flag that was in wrong place
  if db.migratedToSpecBased then
    db.migratedToSpecBased = nil
  end
  
  -- Migration: Remove old position system fields
  if db.positions then db.positions = nil end
  if db.cdmDefaultPositions then db.cdmDefaultPositions = nil end
  if db.auraPositionMode then db.auraPositionMode = nil end
  if db.cooldownPositionMode then db.cooldownPositionMode = nil end
  if db.auraSpacing then db.auraSpacing = nil end
  if db.cooldownSpacing then db.cooldownSpacing = nil end
  if db.groupPositions then db.groupPositions = nil end  -- Removed - Edit Mode handles group positioning
  
  -- Run comprehensive settings migrations
  RunMigrations(db)
  
  return db
end

-- Function to restore saved Edit Mode scales from DB
local function RestoreSavedEditModeScales()
  local db = GetDB()
  if db and db.editModeScales then
    for vType, scale in pairs(db.editModeScales) do
      if scale and scale > 0 then
        groupScales[vType] = scale
      end
    end
  end
end

-- Deep merge: overlay source onto dest, only overwriting non-nil values
-- Returns a new table (doesn't modify inputs)
local function DeepMergeSettings(dest, source)
  if not source then return dest end
  if not dest then return CopyTable(source) end
  
  local result = CopyTable(dest)
  for k, v in pairs(source) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = DeepMergeSettings(result[k], v)
    elseif v ~= nil then
      result[k] = v
    end
  end
  return result
end

local DEFAULT_ICON_SETTINGS = {
  -- Visual Scaling
  scale = 1.0,
  -- NOTE: width/height are nil by default to preserve CDM's native icon size
  -- They only get set when user explicitly changes them via the sliders
  aspectRatio = 1.0,  -- 1.0 = square, >1 = wider, <1 = taller
  zoom = 0.075,  -- Default slight zoom to crop icon borders
  padding = 0,
  alpha = 1.0,
  hideShadow = false,  -- Hide CDM's shadow/border texture (IconOverlay)
  
  -- Cooldown State Visual Options (two-state system)
  -- Controls how icon appears when Ready vs On Cooldown
  cooldownStateVisuals = {
    -- Ready State (spell is available/buff is active)
    readyState = {
      alpha = 1.0,           -- Alpha when ready (0-1)
      glow = false,          -- Show glow while ready
      glowColor = nil,       -- nil = default gold, or {r, g, b}
      glowWhileChargesAvailable = false,  -- For charge spells: glow while any charge available (vs only when ALL charges ready)
    },
    -- On Cooldown State (spell on CD/buff not active)  
    cooldownState = {
      alpha = 1.0,           -- Alpha when on cooldown (0-1)
      desaturate = false,    -- We apply desaturation (for auras that CDM doesn't desaturate)
      noDesaturate = false,  -- Block CDM's default desaturation (for cooldowns)
    },
  },
  
  -- Range Indicator
  rangeIndicator = {
    enabled = true,           -- Show out-of-range overlay (CDM default behavior)
  },
  
  -- Proc Glow (SpellActivationAlert)
  procGlow = {
    enabled = true,           -- Show proc glow animation
    alpha = 1.0,              -- Glow intensity (0 = invisible, 1 = full)
    scale = 1.0,              -- Glow size multiplier (works for all glow types)
    color = nil,              -- nil = default gold, or {r, g, b} to tint
    glowType = "default",     -- "default" (CDM's glow), "pixel", "autocast", "button", "proc" (LCG glows)
    -- Pixel glow options
    lines = 8,                -- Number of lines (pixel glow)
    thickness = 2,            -- Line thickness (pixel glow)
    -- AutoCast glow options
    particles = 4,            -- Number of particle groups (autocast glow)
    -- Speed (all custom glows)
    speed = 0.25,             -- Animation speed/frequency
  },
  
  -- Border (edge overlays)
  border = {
    enabled = false,
    color = {1, 1, 1, 1},
    thickness = 2,
    inset = -3,
    useClassColor = false,
    followDesaturation = false,  -- Desaturate border when icon is desaturated
  },
  
  -- Cooldown Swipe/Animation
  cooldownSwipe = {
    showSwipe = true,       -- The clock/darken animation
    noGCDSwipe = false,     -- Hide GCD swipes (1.5s or less)
    swipeWaitForNoCharges = false, -- For charge spells: only show swipe when ALL charges consumed
    hideTextWithSwipe = false,     -- When swipeWaitForNoCharges hides swipe, also hide duration text
    showEdge = true,        -- The spinning bright line
    showBling = true,       -- Flash when cooldown finishes
    reverse = false,        -- Reverse swipe direction
    swipeColor = nil,       -- nil = use CDM default, or {r, g, b, a} to override
    edgeScale = nil,        -- Scale of the spinning edge line (nil = use CDM default, typically ~1.8)
    edgeColor = nil,        -- nil = use default, or {r, g, b, a} to override
    swipeInset = 0,         -- Single inset for swipe (all sides)
    separateInsets = false, -- Enable separate X/Y insets
    swipeInsetX = 0,        -- Horizontal inset (left/right) for swipe
    swipeInsetY = 0,        -- Vertical inset (top/bottom) for swipe
    -- NOTE: ignoreAuraOverride moved to auraActiveState section
  },
  
  -- Aura Active State (when buff/aura is active on icon)
  -- Customizations for how the icon appears when the associated aura is up
  auraActiveState = {
    ignoreAuraOverride = false,  -- Show spell cooldown instead of aura duration
    -- Future options: custom alpha, desaturation, border color, etc.
  },
  
  -- Debuff Border (debuff type color indicator - magic=blue, curse=purple, etc.)
  debuffBorder = {
    enabled = false,  -- Show debuff type border (default hidden)
    -- When enabled, border will be sized to match icon with zoom/padding
  },
  
  -- Pandemic Border (red glow when aura is in pandemic window - 30% remaining)
  pandemicBorder = {
    enabled = false,  -- Show pandemic indicator (default hidden - we have custom alerts)
    -- When enabled, border will be sized to match icon with zoom/padding
  },
  
  -- Alert Events (triggered by CDM's TriggerAlertEvent)
  -- For Auras: Available=applied, PandemicTime=30% left, OnCooldown=expired
  -- For Cooldowns: Available=ready, OnCooldown=used, ChargeGained=charge restored
  alertEvents = {
    onAvailable = {         -- Aura applied / Cooldown ready
      playSound = false,
      soundFile = nil,      -- Custom sound file name (e.g. "TadaFanfare") or nil
      soundID = 8959,       -- Fallback: SOUNDKIT sound ID
      showGlow = false,
      glowColor = nil,      -- {r, g, b} or nil for default
    },
    onPandemic = {          -- Aura at 30% remaining (auras only)
      playSound = false,
      soundFile = nil,
      soundID = 43499,      -- Warning sound
      showGlow = false,
      glowColor = {r = 1, g = 0.5, b = 0},  -- Orange warning
    },
    onUnavailable = {       -- Aura expired / Cooldown used
      playSound = false,
      soundFile = nil,
      soundID = nil,
      stopGlow = true,      -- Stop any active glow
    },
    onChargeGained = {      -- Cooldown charge restored (cooldowns only)
      playSound = false,
      soundFile = nil,
      soundID = 8959,
      showGlow = false,
      glowColor = nil,
    },
  },
  
  -- Charge/Stack Text
  chargeText = {
    enabled = true,
    autoHide = true,        -- Hide when stack count is 0 or 1
    size = 16,
    color = {r = 1, g = 1, b = 0, a = 1},
    font = "Friz Quadrata TT",
    outline = "OUTLINE",
    shadow = false,
    shadowOffsetX = 1,
    shadowOffsetY = -1,
    -- Positioning
    mode = "anchor",  -- "anchor" or "free"
    anchor = "BOTTOMRIGHT",
    offsetX = -2,
    offsetY = 2,
    -- Free position (relative to icon center)
    freeX = 0,
    freeY = 0,
  },
  
  -- Cooldown Text (timer)
  cooldownText = {
    enabled = true,
    size = 14,
    color = {r = 1, g = 1, b = 1, a = 1},
    font = "Friz Quadrata TT",
    outline = "OUTLINE",
    shadow = false,
    shadowOffsetX = 1,
    shadowOffsetY = -1,
    -- Positioning
    mode = "anchor",  -- "anchor" or "free"
    anchor = "CENTER",
    offsetX = 0,
    offsetY = 0,
    -- Free position (relative to icon center)
    freeX = 0,
    freeY = 0,
  },
}

-- Get effective icon settings (merges global defaults + per-icon overrides)
-- Used when APPLYING styles and for options UI display
local effectiveSettingsCache = {}  -- Cache to avoid repeated merging
local effectiveSettingsCacheVersion = 0

local function InvalidateEffectiveSettingsCache()
  effectiveSettingsCacheVersion = effectiveSettingsCacheVersion + 1
  wipe(effectiveSettingsCache)
end

-- Get RAW per-icon settings (only what user has actually customized, no auto-creation)
-- Used for merging with global settings
-- NOW USES SPEC-BASED STORAGE (per-character, per-spec)
local function GetRawIconSettings(cooldownID)
  local iconSettings = Shared.GetSpecIconSettings()
  if not iconSettings then return nil end
  
  local key = tostring(cooldownID)
  return iconSettings[key]  -- May be nil if user hasn't customized this icon
end

local function GetEffectiveIconSettings(cooldownID)
  -- FAST PATH: Check cache first with minimal overhead
  -- Use cooldownID directly as key (works for both numbers and strings)
  if cooldownID then
    local cached = effectiveSettingsCache[cooldownID]
    if cached and cached.version == effectiveSettingsCacheVersion then
      return cached.cfg
    end
  end
  
  -- SLOW PATH: Cache miss - do full validation and build
  local db = GetDB()
  if not db then return CopyTable(DEFAULT_ICON_SETTINGS) end
  
  -- Validate cooldownID
  if not cooldownID or cooldownID == 0 then
    return CopyTable(DEFAULT_ICON_SETTINGS)
  end
  
  -- Allow Arc Aura string IDs (they start with "arc_")
  local isArcAura = type(cooldownID) == "string" and cooldownID:match("^arc_")
  
  -- Must be number OR Arc Aura string ID
  if not isArcAura and type(cooldownID) ~= "number" then
    return CopyTable(DEFAULT_ICON_SETTINGS)
  end
  
  -- Determine icon type for global settings selection using CDM category
  -- Category 0 (Essential) / Category 1 (Utility) = cooldown settings
  -- Category 2 (TrackedBuff) = aura settings
  -- Arc Auras default to cooldown settings
  local isAura = false
  local spellID = nil
  
  -- Use safe wrapper (returns nil for Arc Aura string IDs)
  local cdInfo = Shared.SafeGetCDMInfo and Shared.SafeGetCDMInfo(cooldownID)
  if cdInfo then
    isAura = Shared.IsAuraCategory(cdInfo.category)
    spellID = cdInfo.overrideSpellID or cdInfo.spellID
  end
  
  local globalSettings = isAura and db.globalAuraSettings or db.globalCooldownSettings
  
  -- Get raw per-icon settings (only user customizations, not auto-created defaults)
  local perIcon = GetRawIconSettings(cooldownID)
  
  -- Build effective settings: defaults -> global -> per-icon
  local effective = CopyTable(DEFAULT_ICON_SETTINGS)
  
  -- Apply global settings if any
  if globalSettings and next(globalSettings) then
    effective = DeepMergeSettings(effective, globalSettings)
  end
  
  -- Apply per-icon overrides if any (these are actual user customizations)
  if perIcon and next(perIcon) then
    effective = DeepMergeSettings(effective, perIcon)
  end
  
  -- Store CDM category info in config (avoids duplicate API calls in ApplyCooldownStateVisuals)
  effective._isAura = isAura
  effective._spellID = spellID
  
  -- MASQUE COMPATIBILITY: When Masque skinning is enabled, force defaults for appearance settings
  -- Masque controls icon borders/textures, so ArcUI shouldn't apply zoom/padding/aspectRatio
  -- Check requires: ns.Masque exists, IsEnabled function exists, AND IsEnabled() returns true
  local masqueEnabled = ns.Masque and ns.Masque.IsEnabled and (ns.Masque.IsEnabled() == true)
  if masqueEnabled then
    effective.aspectRatio = 1.0
    effective.zoom = 0
    effective.padding = 0
  end
  
  -- Cache the result (use cooldownID directly as key)
  effectiveSettingsCache[cooldownID] = { version = effectiveSettingsCacheVersion, cfg = effective }
  
  return effective
end

-- OPTIMIZED: Get effective settings with frame-level caching
-- This bypasses string conversion and table lookup on cache hit
local function GetEffectiveIconSettingsForFrame(frame)
  if not frame then return nil end
  
  -- FAST PATH: Check frame-level cache first (no string conversion, no table lookup)
  -- SAFETY: Also verify the cached settings are for the CURRENT cooldownID
  -- CDM can reassign frames to new spells, which changes frame.cooldownID
  -- without triggering a cache version bump
  if frame._arcCfg and frame._arcCfgVersion == effectiveSettingsCacheVersion then
    if frame._arcCfgCdID == frame.cooldownID then
      return frame._arcCfg
    end
    -- cdID changed underneath — cache is stale, fall through to refresh
  end
  
  -- Cache miss - get from main cache (which may also be a hit)
  local cdID = frame.cooldownID
  if not cdID then return nil end
  
  local cfg = GetEffectiveIconSettings(cdID)
  
  -- Store on frame for next time (including which cdID this is for)
  frame._arcCfg = cfg
  frame._arcCfgVersion = effectiveSettingsCacheVersion
  frame._arcCfgCdID = cdID
  
  return cfg
end

-- Export for hooks that reference ns.CDMEnhance.GetEffectiveIconSettingsForFrame
ns.CDMEnhance.GetEffectiveIconSettingsForFrame = GetEffectiveIconSettingsForFrame

-- Get per-icon settings (for options UI display - returns effective merged settings)
-- Does NOT auto-create entries - use GetOrCreateIconSettings when user makes a change
local function GetIconSettings(cooldownID)
  local db = GetDB()
  if not db then return nil end
  
  -- Return effective settings (for display in options UI)
  -- This merges defaults + global + per-icon without creating entries
  return GetEffectiveIconSettings(cooldownID)
end

-- Ensure per-icon settings entry exists (call this when user makes a change)
-- Get or create per-icon settings with full structure (for setters)
-- NOW USES SPEC-BASED STORAGE (per-character, per-spec)
local function GetOrCreateIconSettings(cooldownID)
  local iconSettings = Shared.GetSpecIconSettings()
  if not iconSettings then return nil end
  
  local key = tostring(cooldownID)
  
  if not iconSettings[key] then
    iconSettings[key] = {}
  end
  
  -- NOTE: We do NOT pre-create empty sub-tables anymore!
  -- The setters already do: "if not c.border then c.border = {} end"
  -- Pre-creating empty tables was causing database bloat and
  -- breaking global settings inheritance (empty table != nil)
  
  -- Invalidate cache since we're modifying settings
  InvalidateEffectiveSettingsCache()
  
  return iconSettings[key]
end

-- ===================================================================
-- DATABASE CLEANUP UTILITIES
-- Remove empty tables and values matching defaults from per-icon settings
-- This keeps the SavedVariables clean and ensures global settings work
-- ===================================================================

-- Recursively remove empty tables from a settings table
local function RemoveEmptyTables(tbl)
  if type(tbl) ~= "table" then return end
  
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      RemoveEmptyTables(v)
      if not next(v) then
        tbl[k] = nil
      end
    end
  end
end

-- Check if a value matches the default (for cleanup)
local function ValueMatchesDefault(value, default)
  if type(value) ~= type(default) then return false end
  
  if type(value) == "table" then
    -- For color tables, compare contents
    if value.r or value[1] then
      local vr = value.r or value[1] or 0
      local vg = value.g or value[2] or 0
      local vb = value.b or value[3] or 0
      local va = value.a or value[4] or 1
      local dr = default.r or default[1] or 0
      local dg = default.g or default[2] or 0
      local db = default.b or default[3] or 0
      local da = default.a or default[4] or 1
      return math.abs(vr-dr) < 0.01 and math.abs(vg-dg) < 0.01 and 
             math.abs(vb-db) < 0.01 and math.abs(va-da) < 0.01
    end
    return false  -- Other tables don't match
  end
  
  if type(value) == "number" then
    return math.abs(value - default) < 0.001
  end
  
  return value == default
end

-- Clean up ALL icon settings in current profile - ONLY remove empty tables
-- IMPORTANT: We do NOT remove values matching defaults anymore!
-- Reason: Per-icon values that match DEFAULT_ICON_SETTINGS may still be needed
-- to override globalCooldownSettings/globalAuraSettings which have different values.
-- Example: DEFAULT_ICON_SETTINGS.chargeText.enabled = true
--          globalCooldownSettings.chargeText.enabled = false
--          Per-icon chargeText.enabled = true (user wants to show it)
-- If we removed the per-icon value (matches default), it would fall back to
-- globalCooldownSettings and hide the charge text - not what the user wanted!
local function CleanupAllIconSettings()
  local iconSettings = Shared.GetSpecIconSettings()
  if not iconSettings then return 0, 0 end
  
  local cleanedCount = 0
  local removedCount = 0
  
  for key, settings in pairs(iconSettings) do
    local hadSettings = next(settings) ~= nil
    
    -- Only remove empty tables, preserve all actual values
    RemoveEmptyTables(settings)
    
    if not next(settings) then
      iconSettings[key] = nil
      if hadSettings then
        removedCount = removedCount + 1
      end
    elseif hadSettings then
      cleanedCount = cleanedCount + 1
    end
  end
  
  -- Invalidate cache
  InvalidateEffectiveSettingsCache()
  
  return cleanedCount, removedCount
end

-- Expose cleanup function for import/export and internal use
ns.CDMEnhance.CleanupAllIconSettings = CleanupAllIconSettings

-- Auto-cleanup on profile ready (called by CDMShared when profile is loaded)
-- This ensures old bloated databases get cleaned automatically
-- Silent - only prints if DEBUG is enabled
function ns.CDMEnhance.OnProfileReady()
  -- Delay slightly to ensure all data is loaded
  C_Timer.After(0.5, function()
    local cleaned, removed = CleanupAllIconSettings()
    -- Silent cleanup - don't spam user with messages
    if _G.ARCUI_DEBUG and (cleaned > 0 or removed > 0) then
      print("|cff00ccffArcUI|r: [Debug] Auto-cleaned icon database (" .. removed .. " empty entries removed)")
    end
  end)
end

-- ===================================================================
-- HELPERS
-- ===================================================================
local function GetFontPath(fontName)
  -- Default fallback font
  local defaultFont = "Fonts\\FRIZQT__.TTF"
  
  if not fontName then return defaultFont end
  
  if LSM then
    local path = LSM:Fetch("font", fontName)
    if path and path ~= "" then
      return path
    end
  end
  
  -- If fontName looks like a path already, use it directly
  if fontName:find("\\") or fontName:find("/") then
    return fontName
  end
  
  return defaultFont
end

-- Safe SetFont wrapper - forces font refresh by temporarily changing size
-- WoW caches font objects internally and sometimes doesn't refresh when only path changes
local function SafeSetFont(fontString, fontPath, fontSize, outline)
  if not fontString or not fontString.SetFont then return false end
  
  -- Normalize outline - WoW expects "" for no outline, not "NONE" or nil
  if not outline or outline == "" or outline == "NONE" then
    outline = ""
  end
  
  -- Get current font info to check if we need to force refresh
  local currentPath, currentSize, currentOutline = fontString:GetFont()
  
  -- FORCE REFRESH: WoW caches fonts - if only path is changing, it may not update
  -- Set to a different size first to force WoW to recreate the font object
  if currentSize and currentSize == fontSize then
    -- Temporarily set different size to break the cache
    fontString:SetFont(fontPath, fontSize + 0.01, outline)
  end
  
  -- Now set the actual font
  fontString:SetFont(fontPath, fontSize, outline)
  
  -- Force text refresh - some fonts need this to display correctly
  local currentText = fontString:GetText()
  if currentText then
    fontString:SetText(currentText)
  end
  
  -- Verify the font was set correctly
  local actualPath = fontString:GetFont()
  if not actualPath or actualPath == "" then
    -- Font failed to load completely, fallback to default
    fontString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, outline)
    return false
  end
  
  return true
end

local function GetClassColor()
  local _, class = UnitClass("player")
  local color = RAID_CLASS_COLORS[class]
  if color then
    return {color.r, color.g, color.b, 1}
  end
  return {1, 1, 1, 1}
end

-- ===================================================================
-- CUSTOM SOUNDS
-- ===================================================================
-- Available sound files in Interface\AddOns\ArcUI\Sounds\
local CUSTOM_SOUNDS = {
  "AcousticGuitar", "AirHorn", "Applause", "BananaPeelSlip", "BatmanPunch",
  "BikeHorn", "Blast", "Bleat", "BoxingArenaSound", "Brass", "CartoonVoiceBaritone",
  "CartoonWalking", "CatMeow2", "ChickenAlarm", "CowMooing", "DoubleWhoosh",
  "Drums", "ErrorBeep", "Glass", "GoatBleating", "HeartbeatSingle", "KittenMeow",
  "OhNo", "RingingPhone", "RoaringLion", "RobotBlip", "RoosterChickenCalls",
  "SharpPunch", "SheepBleat", "Shotgun", "SqueakyToyShort", "SquishFart",
  "SynthChord", "TadaFanfare", "TempleBellHuge", "Torch", "WarningSiren",
  "WaterDrop", "Xylophone",
}

local function PlayAlertSound(soundFile, soundID)
  if soundFile and soundFile ~= "" then
    -- Play custom sound file
    local path = "Interface\\AddOns\\ArcUI\\Sounds\\" .. soundFile .. ".ogg"
    pcall(PlaySoundFile, path, "Master")
  elseif soundID then
    -- Fall back to sound ID
    pcall(PlaySound, soundID)
  end
end

-- Export for options
ns.CUSTOM_SOUNDS = CUSTOM_SOUNDS

-- ===================================================================
-- POSITION MANAGEMENT (Per-Icon Positions)
-- v3.2: SetParent(UIParent) approach with scale-aware positioning
-- Key: Always check cooldownID's saved config, not frame flags
-- Uses raw screen pixels for position storage to avoid scale issues
-- ===================================================================

-- NOTE: TriggerCDMRefreshViaEditMode removed - CDMGroups handles layout directly
-- NOTE: Screen pixel functions removed - CDMGroups handles all positioning
-- NOTE: ApplyIconPosition, ApplyAllIconPositions, and SaveIconPosition have been removed
-- CDMGroups now handles ALL icon positioning

local function ResetIconPosition(cdID)
  -- Get the ACTUAL stored per-icon settings (not the merged copy!)
  -- Now using spec-based storage
  local iconSettings = Shared.GetSpecIconSettings()
  
  local key = tostring(cdID)
  if iconSettings and iconSettings[key] then
    -- Reset position in the actual stored settings
    iconSettings[key].position = {
      mode = "group",
      freeX = 0,
      freeY = 0,
    }
  end
  
  -- Return frame to original parent
  local data = enhancedFrames[cdID]
  if data and data.frame then
    local frame = data.frame
    
    -- Return to original parent so CDM can reclaim it
    if frame._arcOriginalParent then
      frame:SetParent(frame._arcOriginalParent)
      frame._arcOriginalParent = nil
    end
  end
  
  -- Invalidate cache since we modified settings
  InvalidateEffectiveSettingsCache()
end

-- Check if icon has custom position (non-group mode)
local function HasCustomPosition(cdID)
  local cfg = GetIconSettings(cdID)
  return cfg and cfg.position and cfg.position.mode ~= "group"
end

-- ===================================================================
-- BORDER (4 edge textures at OVERLAY level)
-- ===================================================================
local function CreateBorderEdges(frame)
  if frame._arcBorderEdges then return frame._arcBorderEdges end
  
  local edges = {}
  
  edges.top = frame:CreateTexture(nil, "OVERLAY", nil, 7)
  edges.top:SetColorTexture(1, 1, 1, 1)
  
  edges.bottom = frame:CreateTexture(nil, "OVERLAY", nil, 7)
  edges.bottom:SetColorTexture(1, 1, 1, 1)
  
  edges.left = frame:CreateTexture(nil, "OVERLAY", nil, 7)
  edges.left:SetColorTexture(1, 1, 1, 1)
  
  edges.right = frame:CreateTexture(nil, "OVERLAY", nil, 7)
  edges.right:SetColorTexture(1, 1, 1, 1)
  
  frame._arcBorderEdges = edges
  return edges
end

local function UpdateIconBorder(frame, cdID, iconWidth, iconHeight, padding, zoom)
  if not cdID then return end
  
  local cfg = GetIconSettings(cdID)
  if not cfg or not cfg.border then return end
  
  local edges = frame._arcBorderEdges or CreateBorderEdges(frame)
  
  if cfg.border.enabled then
    local color
    if cfg.border.useClassColor then
      color = GetClassColor()
    else
      color = cfg.border.color or {1, 1, 1, 1}
    end
    
    local r, g, b, a = color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
    
    -- Note: Border desaturation is handled by ApplyBorderDesaturation/ApplyBorderDesaturationFromDuration
    -- which are called from ApplyCooldownStateVisuals. We just set the base color here.
    
    local thickness = cfg.border.thickness or 2
    
    -- Border position is controlled SOLELY by the inset slider
    -- No longer affected by zoom or padding - user has full control
    local userOffset = cfg.border.inset or -3
    
    local insetX = userOffset
    local insetY = userOffset
    
    -- Top edge
    edges.top:ClearAllPoints()
    edges.top:SetPoint("TOPLEFT", frame, "TOPLEFT", insetX, -insetY)
    edges.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -insetX, -insetY)
    edges.top:SetHeight(thickness)
    edges.top:SetVertexColor(r, g, b, a)
    edges.top:Show()
    
    -- Bottom edge
    edges.bottom:ClearAllPoints()
    edges.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", insetX, insetY)
    edges.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetX, insetY)
    edges.bottom:SetHeight(thickness)
    edges.bottom:SetVertexColor(r, g, b, a)
    edges.bottom:Show()
    
    -- Left edge
    edges.left:ClearAllPoints()
    edges.left:SetPoint("TOPLEFT", frame, "TOPLEFT", insetX, -insetY)
    edges.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", insetX, insetY)
    edges.left:SetWidth(thickness)
    edges.left:SetVertexColor(r, g, b, a)
    edges.left:Show()
    
    -- Right edge
    edges.right:ClearAllPoints()
    edges.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -insetX, -insetY)
    edges.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetX, insetY)
    edges.right:SetWidth(thickness)
    edges.right:SetVertexColor(r, g, b, a)
    edges.right:Show()
  else
    edges.top:Hide()
    edges.bottom:Hide()
    edges.left:Hide()
    edges.right:Hide()
  end
end

-- ===================================================================
-- TEXTURE COORDINATE CALCULATION (Aspect Ratio + Zoom)
-- ===================================================================
local function CalculateTexCoords(aspectRatio, zoom)
  local left, right, top, bottom = 0, 1, 0, 1
  
  -- Apply aspect ratio cropping
  if aspectRatio and aspectRatio ~= 1.0 then
    if aspectRatio > 1.0 then
      -- Wider than tall - crop top/bottom of texture
      local cropAmount = 1.0 - (1.0 / aspectRatio)
      local offset = cropAmount / 2.0
      top = offset
      bottom = 1.0 - offset
    elseif aspectRatio < 1.0 then
      -- Taller than wide - crop left/right of texture
      local cropAmount = 1.0 - aspectRatio
      local offset = cropAmount / 2.0
      left = offset
      right = 1.0 - offset
    end
  end
  
  -- Apply zoom on top of aspect ratio crop
  if zoom and zoom > 0 then
    local currentWidth = right - left
    local currentHeight = bottom - top
    local visibleSize = 1.0 - (zoom * 2)
    
    local zoomedWidth = currentWidth * visibleSize
    local zoomedHeight = currentHeight * visibleSize
    
    local centerX = (left + right) / 2.0
    local centerY = (top + bottom) / 2.0
    
    left = centerX - (zoomedWidth / 2.0)
    right = centerX + (zoomedWidth / 2.0)
    top = centerY - (zoomedHeight / 2.0)
    bottom = centerY + (zoomedHeight / 2.0)
  end
  
  return left, right, top, bottom
end

-- ===================================================================
-- PREVIEW TEXT FOR EDITING
-- Shows placeholder text (0, 0.0) when editing so user can see position
-- Only shows on the currently selected/edited icon
-- ===================================================================
local function UpdatePreviewText(frame, cdID, cfg)
  -- Show preview when options panel is open (helps user see text styling while editing)
  local optionsOpen = ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsOptionsOpen and ns.CDMEnhanceOptions.IsOptionsOpen()
  
  -- Check if THIS icon is the one being edited
  local isSelectedIcon = false
  if optionsOpen and ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.GetSelectedIcon then
    local selectedAura, selectedCooldown = ns.CDMEnhanceOptions.GetSelectedIcon()
    isSelectedIcon = (cdID == selectedAura) or (cdID == selectedCooldown)
  end
  
  -- Charge/Stack text preview (shows "0")
  -- Skip for Arc Aura frames - they manage their own Count fontstring
  if cfg.chargeText and not frame._arcConfig and not frame._arcAuraID then
    local chargeCfg = cfg.chargeText
    local chargeText = frame._arcChargeText
    local hasRealText = false
    
    -- Check if real text is showing (IsShown and GetText can be secret during combat)
    if chargeText then
      -- Wrap entire check in pcall - both IsShown() and GetText() can be secret
      local ok, result = pcall(function()
        if chargeText:IsShown() then
          local currentText = chargeText:GetText()
          return currentText and currentText ~= ""
        end
        return false
      end)
      if ok then
        hasRealText = result
      else
        -- If pcall failed due to secret values, assume there's text
        hasRealText = true
      end
    end
    
    -- Only show preview on the selected icon AND when no real text
    if isSelectedIcon and not hasRealText then
      -- Ensure text overlay exists (created in ApplyIconStyle)
      local overlayParent = frame._arcTextOverlay or frame
      
      -- Create preview text if needed (parented to text overlay so it's above cooldown swipe)
      if not frame._arcChargePreview then
        frame._arcChargePreview = overlayParent:CreateFontString(nil, "OVERLAY")
        frame._arcChargePreview:SetDrawLayer("OVERLAY", 7)
        frame._arcChargePreview._arcIsPreview = true
        frame._arcChargePreview._arcIsChargeText = true  -- Prevent cooldown styling from touching it
      elseif frame._arcChargePreview:GetParent() ~= overlayParent then
        -- Re-parent if overlay was created after preview
        frame._arcChargePreview:SetParent(overlayParent)
      end
      
      local preview = frame._arcChargePreview
      
      -- Copy styling from charge text config (full styling for live preview)
      local fontPath = GetFontPath(chargeCfg.font)
      local fontSize = chargeCfg.size or 16
      local outline = chargeCfg.outline or "THICKOUTLINE"
      SafeSetFont(preview, fontPath, fontSize, outline)
      
      -- Use actual color settings
      local c = chargeCfg.color or {r=1, g=1, b=0, a=1}
      preview:SetTextColor(c.r or 1, c.g or 1, c.b or 0, c.a or 1)
      
      if chargeCfg.shadow then
        preview:SetShadowOffset(chargeCfg.shadowOffsetX or 1, chargeCfg.shadowOffsetY or -1)
        preview:SetShadowColor(0, 0, 0, 0.8)
      else
        preview:SetShadowOffset(0, 0)
      end
      
      -- Position like charge text
      preview:ClearAllPoints()
      if chargeCfg.mode == "free" then
        local freeX = chargeCfg.freeX or 0
        local freeY = chargeCfg.freeY or 0
        preview:SetPoint("CENTER", frame, "CENTER", freeX, freeY)
      else
        local anchor = chargeCfg.anchor or "BOTTOMRIGHT"
        local offX = chargeCfg.offsetX or -2
        local offY = chargeCfg.offsetY or 2
        preview:SetPoint(anchor, frame, anchor, offX, offY)
      end
      
      preview:SetText("0")
      preview:Show()
    else
      -- Not selected or real text showing, hide preview
      if frame._arcChargePreview then
        frame._arcChargePreview:Hide()
      end
    end
  else
    -- No charge config, hide preview
    if frame._arcChargePreview then
      frame._arcChargePreview:Hide()
    end
  end
  
  -- Cooldown/Duration text preview (shows "0.0")
  local cooldownFrame = frame.Cooldown or frame.cooldown
  if cooldownFrame and cfg.cooldownText and cfg.cooldownText.enabled ~= false then
    local cdTextCfg = cfg.cooldownText
    local hasCooldownText = false
    
    -- Check if there's visible cooldown text (IsShown and GetText can be secret during combat)
    if frame._arcCooldownText then
      -- Wrap entire check in pcall - both IsShown() and GetText() can be secret
      local ok, result = pcall(function()
        if frame._arcCooldownText:IsShown() then
          local text = frame._arcCooldownText:GetText()
          return text and text ~= ""
        end
        return false
      end)
      if ok then
        hasCooldownText = result
      else
        -- If pcall failed due to secret values, assume there's text
        hasCooldownText = true
      end
    end
    
    -- Only show preview on the selected icon AND when no real text
    if isSelectedIcon and not hasCooldownText then
      -- Ensure text overlay exists (created in ApplyIconStyle)
      local overlayParent = frame._arcTextOverlay or frame
      
      -- Create preview text if needed (parented to text overlay so it's above cooldown swipe)
      if not frame._arcCooldownPreview then
        frame._arcCooldownPreview = overlayParent:CreateFontString(nil, "OVERLAY")
        frame._arcCooldownPreview:SetDrawLayer("OVERLAY", 7)
        frame._arcCooldownPreview._arcIsPreview = true
        frame._arcCooldownPreview._arcIsCooldownText = true  -- Prevent charge styling from touching it
      elseif frame._arcCooldownPreview:GetParent() ~= overlayParent then
        -- Re-parent if overlay was created after preview
        frame._arcCooldownPreview:SetParent(overlayParent)
      end
      
      local preview = frame._arcCooldownPreview
      
      -- Copy styling from cooldown text config (full styling for live preview)
      local fontPath = GetFontPath(cdTextCfg.font)
      local fontSize = cdTextCfg.size or 14
      local outline = cdTextCfg.outline or "OUTLINE"
      SafeSetFont(preview, fontPath, fontSize, outline)
      
      -- Use actual color settings
      local c = cdTextCfg.color or {r=1, g=1, b=1, a=1}
      preview:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
      
      if cdTextCfg.shadow then
        preview:SetShadowOffset(cdTextCfg.shadowOffsetX or 1, cdTextCfg.shadowOffsetY or -1)
        preview:SetShadowColor(0, 0, 0, 0.8)
      else
        preview:SetShadowOffset(0, 0)
      end
      
      -- Position like cooldown text
      preview:ClearAllPoints()
      if cdTextCfg.mode == "free" then
        local freeX = cdTextCfg.freeX or 0
        local freeY = cdTextCfg.freeY or 0
        preview:SetPoint("CENTER", frame, "CENTER", freeX, freeY)
      else
        local anchor = cdTextCfg.anchor or "CENTER"
        local offX = cdTextCfg.offsetX or 0
        local offY = cdTextCfg.offsetY or 0
        preview:SetPoint(anchor, frame, anchor, offX, offY)
      end
      
      preview:SetText("0.0")
      preview:Show()
    else
      -- Not selected or real text showing, hide preview
      if frame._arcCooldownPreview then
        frame._arcCooldownPreview:Hide()
      end
    end
  else
    -- No cooldown config or disabled, hide preview
    if frame._arcCooldownPreview then
      frame._arcCooldownPreview:Hide()
    end
  end
end

-- ===================================================================
-- PREVIEW GLOW FOR EDITING
-- Shows glow animation for 3 seconds when user changes a glow setting
-- Only shows on the icon whose setting was changed
-- ===================================================================
local function UpdatePreviewGlow(frame, cdID, cfg)
  local lcg = GetLCG()
  if not lcg then return end
  
  -- Check if options panel is open
  local optionsOpen = ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsOptionsOpen and ns.CDMEnhanceOptions.IsOptionsOpen()
  
  -- Check if glow preview is active (triggered by changing a glow setting)
  local glowPreviewActive, previewCdID = false, nil
  if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.GetGlowPreviewState then
    glowPreviewActive, previewCdID = ns.CDMEnhanceOptions.GetGlowPreviewState()
  end
  
  -- Check if THIS icon should show preview (matches the triggered cdID)
  local isPreviewTarget = glowPreviewActive and (cdID == previewCdID)
  
  -- Check if real glow is happening (don't show preview during actual proc)
  local hasRealGlow = false
  if frame.SpellActivationAlert then
    local ok, result = pcall(function() return frame.SpellActivationAlert:IsShown() end)
    if ok and result then
      hasRealGlow = true
    end
  end
  
  -- Get glow config
  local glowCfg = cfg and cfg.procGlow
  
  -- Should we show preview? Only when:
  -- 1. Options panel is open
  -- 2. This icon's glow was just changed (within 3 seconds)
  -- 3. No real glow is happening
  -- 4. Glow is enabled in settings
  local showPreview = optionsOpen and isPreviewTarget and not hasRealGlow and glowCfg and glowCfg.enabled ~= false
  
  -- Helper to set glow frame level ABOVE Cooldown swipe
  local function SetPreviewGlowFrameLevel(glowFrame)
    if glowFrame and glowFrame.SetFrameLevel then
      local baseLevel = frame:GetFrameLevel()
      glowFrame:SetFrameLevel(baseLevel + 15)
    end
  end
  
  if showPreview then
    local glowType = glowCfg.glowType or "proc"
    local glowScale = glowCfg.scale or 1.0
    local padding = cfg.padding or 0
    
    -- LibCustomGlow: NEGATIVE offset moves glow INWARD
    local glowOffset = -padding
    
    -- Show the actual glow type as preview
    local color = {0.95, 0.95, 0.32, glowCfg.alpha or 1.0}
    if glowCfg.color then
      color = {glowCfg.color.r or 1, glowCfg.color.g or 1, glowCfg.color.b or 1, glowCfg.alpha or 1.0}
    end
    
    -- Stop previous preview if type changed
    if frame._arcGlowPreviewActive and frame._arcGlowPreviewType ~= glowType then
      StopAllGlows(frame, "ArcUI_Preview")
    end
    
    if glowType == "pixel" then
      local lines = glowCfg.lines or 8
      local speed = glowCfg.speed or 0.25
      local thickness = math.max(1, math.floor((glowCfg.thickness or 2) * glowScale))
      pcall(lcg.PixelGlow_Start, frame, color, lines, speed, nil, thickness, glowOffset, glowOffset, true, "ArcUI_Preview", 1)
      SetPreviewGlowFrameLevel(frame["_PixelGlowArcUI_Preview"])
    elseif glowType == "autocast" then
      local particles = glowCfg.particles or 4
      local speed = glowCfg.speed or 0.125
      pcall(lcg.AutoCastGlow_Start, frame, color, particles, speed, glowScale, glowOffset, glowOffset, "ArcUI_Preview", 1)
      SetPreviewGlowFrameLevel(frame["_AutoCastGlowArcUI_Preview"])
    elseif glowType == "button" then
      local speed = glowCfg.speed or 0.125
      -- ButtonGlow_Start signature: (frame, color, frequency, frameLevel)
      pcall(lcg.ButtonGlow_Start, frame, color, speed, 8)
      local glowFrame = frame._ButtonGlow
      if glowFrame then
        SetPreviewGlowFrameLevel(glowFrame)
        -- Apply scale only if non-default (matching ready state approach)
        if glowScale ~= 1.0 then
          pcall(glowFrame.SetScale, glowFrame, glowScale)
        end
        -- NOTE: Do NOT override ButtonGlow anchoring for padding.
        -- LCG calculates the correct 20% extension from frame size.
        -- Matching ready state approach which works correctly.
      end
    elseif glowType == "proc" then
      pcall(lcg.ProcGlow_Start, frame, {
        color = color,
        startAnim = false,
        key = "ArcUI_Preview",
        xOffset = glowOffset,
        yOffset = glowOffset,
      })
      -- Fix initial state - force correct visibility immediately
      local glowFrame = frame["_ProcGlowArcUI_Preview"]
      if glowFrame then
        SetPreviewGlowFrameLevel(glowFrame)
        if glowFrame.ProcStart then
          glowFrame.ProcStart:Hide()
        end
        if glowFrame.ProcLoop then
          glowFrame.ProcLoop:Show()
          glowFrame.ProcLoop:SetAlpha(glowCfg.alpha or 1.0)
        end
      end
    end
    
    frame._arcGlowPreviewActive = true
    frame._arcGlowPreviewType = glowType
  else
    -- Hide preview glow
    if frame._arcGlowPreviewActive then
      StopAllGlows(frame, "ArcUI_Preview")
      frame._arcGlowPreviewActive = false
      frame._arcGlowPreviewType = nil
    end
  end
end

-- ===================================================================
-- PANDEMIC/DEBUFF BORDER HELPER FUNCTIONS (module-level for watcher access)
-- ===================================================================

-- CDM default offsets from XML:
-- IconOverlay (shadow): 8px horizontal, 7px vertical (BuffIcon template)
-- PandemicIcon: 6px all sides (AnchorPandemicStateFrame)
-- DebuffBorder: SetAllPoints = 0px (texture has internal padding)
-- The pandemic texture (UI-CooldownManager-PandemicBorder) has MORE internal padding
-- than DebuffBorder. We need to increase pandemic expansion so the visible glow aligns.

-- CDM uses 6px offset for 36px icons = 6/36 = 0.167 ratio
-- For larger icons, we scale the offset proportionally
local CDM_BASE_ICON_SIZE = 36
local CDM_BASE_BORDER_OFFSET = 6
local BORDER_OFFSET_RATIO = CDM_BASE_BORDER_OFFSET / CDM_BASE_ICON_SIZE  -- ~0.167

-- (MODULE_BASE_BORDER_OFFSET and MODULE_PANDEMIC_EXTRA_OFFSET removed - using ratio-based scaling)

-- Apply proper sizing to border frames based on padding
-- Note: Zoom only affects texture cropping, not frame size, so it doesn't affect border expansion
-- Aspect ratio is already handled by anchor points (TOPLEFT/BOTTOMRIGHT follow frame dimensions)
local function ModuleApplyBorderSizing(borderFrame, iconFrame, pad, zm, frameType)
  if not borderFrame then return end
  
  -- Ratio-based: scale offset proportionally to icon size (same for pandemic and debuff)
  local iconW, iconH = iconFrame:GetWidth(), iconFrame:GetHeight()
  local iconSize = math.min(iconW or 36, iconH or 36)
  local expand = iconSize * BORDER_OFFSET_RATIO
  -- Adjust for padding (shrinks visible area, so reduce expand)
  expand = expand - (pad or 0)
  -- Adjust for zoom (expands visible area, so increase expand)
  expand = expand + (zm or 0)
  
  borderFrame:ClearAllPoints()
  borderFrame:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -expand, expand)
  borderFrame:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", expand, -expand)
end

-- Setup hooks on border frame (only once per frame)
local function ModuleSetupBorderHooks(borderFrame, frameType)
  if not borderFrame then return end
  
  local hookKey = "_arcBorderHooked_" .. (frameType or "border")
  if borderFrame[hookKey] then return end
  borderFrame[hookKey] = true
  borderFrame._arcFrameType = frameType  -- Store for Show hook
  
  -- Helper to enforce hidden state
  local function EnforceHidden(self)
    local parent = self:GetParent()
    
    -- First check: does parent even want this shown?
    if parent then
      if (self._arcFrameType == "pandemic" and not parent._arcShowPandemic) or
         (self._arcFrameType == "debuff" and not parent._arcShowDebuffBorder) then
        -- Parent says disabled - hide regardless of _arcShowEnabled state
        self:Hide()
        self:SetAlpha(0)
        return true
      end
    end
    
    -- Check _arcShowEnabled
    if self._arcShowEnabled == false then
      self:Hide()
      self:SetAlpha(0)
      return true
    end
    
    return false
  end
  
  -- Hook the border frame Show
  hooksecurefunc(borderFrame, "Show", function(self)
    if EnforceHidden(self) then return end
    
    local parent = self:GetParent()
    if self._arcShowEnabled == true then
      -- Enabled: restore alpha and apply sizing when CDM shows it
      self:SetAlpha(1)
      if parent then
        ModuleApplyBorderSizing(self, parent, parent._arcPadding or 0, parent._arcZoom or 0, self._arcFrameType)
      end
    end
    -- If nil and parent allows: let CDM show it, watcher will set up properly
  end)
  
  -- CRITICAL: Also hook SetShown - CDM may use this instead of Show()
  if borderFrame.SetShown then
    hooksecurefunc(borderFrame, "SetShown", function(self, shown)
      if issecretvalue and issecretvalue(shown) then return end
      if shown then
        EnforceHidden(self)
      end
    end)
  end
  
  -- Hook .Texture child if exists (CDM shows this separately for DebuffBorder)
  if borderFrame.Texture then
    hooksecurefunc(borderFrame.Texture, "Show", function(self)
      local bf = self:GetParent()
      if bf then
        if bf._arcShowEnabled == true then
          self:SetAlpha(1)
        elseif bf._arcShowEnabled == false then
          self:Hide()
          self:SetAlpha(0)
        end
      end
    end)
    if borderFrame.Texture.SetShown then
      hooksecurefunc(borderFrame.Texture, "SetShown", function(self, shown)
        if issecretvalue and issecretvalue(shown) then return end
        if shown then
          local bf = self:GetParent()
          if bf and bf._arcShowEnabled == false then
            self:Hide()
            self:SetAlpha(0)
          end
        end
      end)
    end
  end
end

-- Enable border (allow CDM to show, apply sizing)
local function ModuleEnableBorderFrame(borderFrame, iconFrame, pad, zm, frameType)
  if not borderFrame then return end
  borderFrame._arcShowEnabled = true
  borderFrame._arcSizedForParent = iconFrame
  borderFrame._arcSizedWithZoom = zm
  borderFrame._arcSizedWithPadding = pad
  ModuleSetupBorderHooks(borderFrame, frameType)
  
  -- Restore alpha on main frame
  borderFrame:SetAlpha(1)
  
  -- Restore .Texture child (for DebuffBorder)
  if borderFrame.Texture then
    borderFrame.Texture:SetAlpha(1)
  end
  
  -- Restore .Border child frame and its texture (for PandemicIcon)
  if borderFrame.Border then
    borderFrame.Border:SetAlpha(1)
    borderFrame.Border:Show()
    -- Ensure Border fills PandemicIcon (in case setAllPoints was reset)
    borderFrame.Border:ClearAllPoints()
    borderFrame.Border:SetAllPoints(borderFrame)
    if borderFrame.Border.Border then
      borderFrame.Border.Border:SetAlpha(1)
      borderFrame.Border.Border:Show()
    end
  end
  
  -- Restore .FX child frame (yellow glow for PandemicIcon)
  -- FX needs to be sized to account for padding - it should stay on the border
  if borderFrame.FX then
    borderFrame.FX:SetAlpha(1)
    -- FX follows parent via SetAllPoints
    borderFrame.FX:ClearAllPoints()
    borderFrame.FX:SetAllPoints(borderFrame)
  end
  
  -- Always apply sizing (this sizes the main PandemicIcon frame)
  ModuleApplyBorderSizing(borderFrame, iconFrame, pad, zm, frameType)
end

-- Disable border (block CDM from showing)
local function ModuleDisableBorderFrame(borderFrame, frameType)
  if not borderFrame then return end
  borderFrame._arcShowEnabled = false
  borderFrame._arcSizedForParent = nil
  ModuleSetupBorderHooks(borderFrame, frameType)
  borderFrame:Hide()
  borderFrame:SetAlpha(0)
  
  -- Hide .Texture child (for DebuffBorder)
  if borderFrame.Texture then
    borderFrame.Texture:Hide()
    borderFrame.Texture:SetAlpha(0)
  end
  
  -- Hide .Border child frame and its .Border texture (for PandemicIcon)
  if borderFrame.Border then
    borderFrame.Border:Hide()
    borderFrame.Border:SetAlpha(0)
    if borderFrame.Border.Border then
      borderFrame.Border.Border:Hide()
      borderFrame.Border.Border:SetAlpha(0)
    end
    -- Hook Border:Show() and SetShown() to handle enable/disable
    if not borderFrame.Border._arcShowHooked then
      borderFrame.Border._arcShowHooked = true
      
      -- Helper function to enforce hidden state
      local function EnforceBorderHidden(self)
        local parent = self:GetParent() -- PandemicIcon
        if parent then
          local grandparent = parent:GetParent() -- Icon frame
          -- First check grandparent's control flag (use "not" to catch nil OR false)
          if grandparent and not grandparent._arcShowPandemic then
            self:Hide()
            self:SetAlpha(0)
            return true
          end
          -- Then check parent's _arcShowEnabled
          if parent._arcShowEnabled == false then
            self:Hide()
            self:SetAlpha(0)
            return true
          end
        end
        return false
      end
      
      hooksecurefunc(borderFrame.Border, "Show", function(self)
        if EnforceBorderHidden(self) then return end
        local parent = self:GetParent()
        if parent and parent._arcShowEnabled == true then
          self:SetAlpha(1)
          if self.Border then self.Border:SetAlpha(1) end
        end
      end)
      
      -- CRITICAL: Also hook SetShown - CDM may use this instead of Show()
      if borderFrame.Border.SetShown then
        hooksecurefunc(borderFrame.Border, "SetShown", function(self, shown)
          if issecretvalue and issecretvalue(shown) then return end
          if shown then EnforceBorderHidden(self) end
        end)
      end
    end
  end
  
  -- Hide .FX child frame (yellow glow for PandemicIcon)
  if borderFrame.FX then
    borderFrame.FX:Hide()
    borderFrame.FX:SetAlpha(0)
    
    -- Hook FX:Show() and SetShown() to handle enable/disable
    if not borderFrame.FX._arcShowHooked then
      borderFrame.FX._arcShowHooked = true
      
      -- Helper function to enforce hidden state when disabled
      local function EnforceFXHidden(self)
        local parent = self:GetParent() -- PandemicIcon
        if parent then
          local grandparent = parent:GetParent() -- Icon frame
          -- First check grandparent's control flag (use "not" to catch nil OR false)
          if grandparent and not grandparent._arcShowPandemic then
            self:Hide()
            self:SetAlpha(0)
            return true
          end
          -- Then check parent's _arcShowEnabled
          if parent._arcShowEnabled == false then
            self:Hide()
            self:SetAlpha(0)
            return true
          end
        end
        return false
      end
      
      hooksecurefunc(borderFrame.FX, "Show", function(self)
        if EnforceFXHidden(self) then return end
        local parent = self:GetParent()
        if parent and parent._arcShowEnabled == true then
          -- Enabled - restore and ensure proper sizing
          self:SetAlpha(1)
          self:ClearAllPoints()
          self:SetAllPoints(parent)
        end
      end)
      
      -- CRITICAL: Also hook SetShown - CDM may use this instead of Show()
      if borderFrame.FX.SetShown then
        hooksecurefunc(borderFrame.FX, "SetShown", function(self, shown)
          if issecretvalue and issecretvalue(shown) then return end
          if shown then EnforceFXHidden(self) end
        end)
      end
    end
  end
end

-- Populate BorderFuncs for the centralized border watcher
-- (Must happen after functions are defined)
if ns.CDMEnhance._BorderFuncs then
  ns.CDMEnhance._BorderFuncs.Enable = ModuleEnableBorderFrame
  ns.CDMEnhance._BorderFuncs.Disable = ModuleDisableBorderFrame
end

-- ===================================================================
-- BORDER DESATURATION SYNC
-- Apply desaturation to custom borders when icon is desaturated
-- ColorTexture doesn't respond to SetDesaturation, so we calculate
-- grayscale color and apply via SetVertexColor instead
-- ===================================================================

-- Convert RGB to grayscale (luminance formula)
local function RGBToGrayscale(r, g, b)
  -- Standard luminance formula
  local gray = 0.299 * r + 0.587 * g + 0.114 * b
  return gray, gray, gray
end

-- Cache for border color curves (keyed by color string)
local borderColorCurveCache = {}

-- Create curves for transitioning between original color and grayscale
-- Returns rCurve, gCurve, bCurve that can be evaluated with durationObj:EvaluateRemainingPercent()
local function GetBorderColorCurves(r, g, b)
  if not C_CurveUtil or not C_CurveUtil.CreateCurve then return nil, nil, nil end
  
  local cacheKey = string.format("%.3f_%.3f_%.3f", r, g, b)
  
  if borderColorCurveCache[cacheKey] then
    return unpack(borderColorCurveCache[cacheKey])
  end
  
  -- Calculate grayscale
  local gray = 0.299 * r + 0.587 * g + 0.114 * b
  
  -- Create curves: 0% remaining (ready) = original color, >0% remaining (on CD) = gray
  -- Using Step type for instant transition (like Binary curve)
  local rCurve = C_CurveUtil.CreateCurve()
  rCurve:SetType(Enum.LuaCurveType.Step)
  rCurve:AddPoint(0.0, r)      -- 0% remaining (ready) → original
  rCurve:AddPoint(0.001, gray) -- >0% remaining (on CD) → gray
  rCurve:AddPoint(1.0, gray)
  
  local gCurve = C_CurveUtil.CreateCurve()
  gCurve:SetType(Enum.LuaCurveType.Step)
  gCurve:AddPoint(0.0, g)
  gCurve:AddPoint(0.001, gray)
  gCurve:AddPoint(1.0, gray)
  
  local bCurve = C_CurveUtil.CreateCurve()
  bCurve:SetType(Enum.LuaCurveType.Step)
  bCurve:AddPoint(0.0, b)
  bCurve:AddPoint(0.001, gray)
  bCurve:AddPoint(1.0, gray)
  
  borderColorCurveCache[cacheKey] = {rCurve, gCurve, bCurve}
  return rCurve, gCurve, bCurve
end

-- Apply desaturation to custom border edges by changing vertex color
-- desatValue should be 0 (colored) or 1 (grayscale) - non-secret values only!
-- Used for auras/totems where we have non-secret state
local function ApplyBorderDesaturation(frame, desatValue)
  if not frame then return end
  
  -- Use frame-level cached config
  local cfg = GetEffectiveIconSettingsForFrame(frame)
  if not cfg then return end
  
  -- Check if custom border has followDesaturation enabled
  if cfg.border and cfg.border.enabled and cfg.border.followDesaturation then
    local edges = frame._arcBorderEdges
    if not edges then return end
    
    -- Get the configured border color
    local color
    if cfg.border.useClassColor then
      color = GetClassColor()
    else
      color = cfg.border.color or {1, 1, 1, 1}
    end
    local r, g, b, a = color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
    
    -- Calculate final color based on desaturation (0 = colored, 1 = grayscale)
    local finalR, finalG, finalB
    local desatAmount = desatValue or 0
    
    if desatAmount > 0.5 then
      -- Desaturated: use grayscale
      finalR, finalG, finalB = RGBToGrayscale(r, g, b)
    else
      -- Colored: use original
      finalR, finalG, finalB = r, g, b
    end
    
    -- Apply to all edges
    if edges.top then edges.top:SetVertexColor(finalR, finalG, finalB, a) end
    if edges.bottom then edges.bottom:SetVertexColor(finalR, finalG, finalB, a) end
    if edges.left then edges.left:SetVertexColor(finalR, finalG, finalB, a) end
    if edges.right then edges.right:SetVertexColor(finalR, finalG, finalB, a) end
  end
end

-- Apply curve-based border color for cooldowns (secret-safe!)
-- Uses duration object + color curves to set border color
-- SetVertexColor accepts secret values so this works during combat
local function ApplyBorderDesaturationFromDuration(frame, durationObj)
  if not frame or not durationObj then return end
  
  -- Use frame-level cached config
  local cfg = GetEffectiveIconSettingsForFrame(frame)
  if not cfg then return end
  
  -- Check if custom border has followDesaturation enabled
  if not (cfg.border and cfg.border.enabled and cfg.border.followDesaturation) then return end
  
  local edges = frame._arcBorderEdges
  if not edges then return end
  
  -- Get the configured border color
  local color
  if cfg.border.useClassColor then
    color = GetClassColor()
  else
    color = cfg.border.color or {1, 1, 1, 1}
  end
  local r, g, b, a = color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
  
  -- Get or create color curves for this color
  local rCurve, gCurve, bCurve = GetBorderColorCurves(r, g, b)
  if not rCurve or not gCurve or not bCurve then return end
  
  -- Evaluate curves with duration object - results may be secret but SetVertexColor accepts them!
  local okR, finalR = pcall(function() return durationObj:EvaluateRemainingPercent(rCurve) end)
  local okG, finalG = pcall(function() return durationObj:EvaluateRemainingPercent(gCurve) end)
  local okB, finalB = pcall(function() return durationObj:EvaluateRemainingPercent(bCurve) end)
  
  if okR and okG and okB and finalR and finalG and finalB then
    -- SetVertexColor accepts secret values!
    if edges.top then edges.top:SetVertexColor(finalR, finalG, finalB, a) end
    if edges.bottom then edges.bottom:SetVertexColor(finalR, finalG, finalB, a) end
    if edges.left then edges.left:SetVertexColor(finalR, finalG, finalB, a) end
    if edges.right then edges.right:SetVertexColor(finalR, finalG, finalB, a) end
  end
end

-- Export for use elsewhere
ns.CDMEnhance.ApplyBorderDesaturation = ApplyBorderDesaturation
ns.CDMEnhance.ApplyBorderDesaturationFromDuration = ApplyBorderDesaturationFromDuration

-- ===================================================================
-- APPLY ICON STYLING
-- ===================================================================
ApplyIconStyle = function(frame, cdID)
  if not cdID then return end
  
  -- MASTER TOGGLE: Skip if disabled
  local groupsDB = Shared.GetCDMGroupsDB()
  if groupsDB and groupsDB.enabled == false then
    return
  end
  
  local db = GetDB()
  if not db then return end
  
  -- Determine icon type from enhancedFrames
  local data = enhancedFrames[cdID]
  local viewerType = data and data.viewerType or "cooldown"
  
  -- Check if customization is enabled for this icon type
  local customizationEnabled = true
  if viewerType == "aura" then
    customizationEnabled = db.enableAuraCustomization ~= false
  else
    customizationEnabled = db.enableCooldownCustomization ~= false
  end
  
  -- If customization is disabled, don't apply any styling (CDMGroups handles positioning)
  if not customizationEnabled then
    return
  end
  
  -- Use frame-level cached config
  local cfg = GetEffectiveIconSettingsForFrame(frame)
  if not cfg then return end
  
  -- CDMGroups handles ALL position/scale/size for ALL icons
  -- CDMEnhance only does visual styling (borders, glow, textures, inactive state)
  
  -- Clear inactive state tracking to force re-evaluation with new settings
  frame._arcInactiveSettingsSig = nil
  
  local iconTex = frame.Icon or frame.icon
  
  -- Store original dimensions for fallback (used by visual styling calculations)
  if not frame._arcOrigW then
    frame._arcOrigW = frame:GetWidth()
    frame._arcOrigH = frame:GetHeight()
  end
  
  -- NOTE: CDMGroups controls all sizing - CDMEnhance does NOT call SetScale or SetSize
  local data = enhancedFrames[cdID]
  local vType = data and data.viewerType or "cooldown"
  
  local aspectRatio = cfg.aspectRatio or 1.0
  local zoom = cfg.zoom or 0.075
  local padding = cfg.padding or 0
  
  -- MASQUE COMPATIBILITY: Check if Masque skinning is enabled for this viewer type
  local masqueActive = ns.Masque and ns.Masque.ShouldMasqueControlIcon and ns.Masque.ShouldMasqueControlIcon(vType)
  
  if masqueActive then
    -- Masque controls icon appearance - use defaults (no zoom/padding from ArcUI)
    aspectRatio = 1.0
    zoom = 0
    padding = 0
  end
  
  -- Calculate texture coords for aspect ratio and zoom
  local left, right, top, bottom = CalculateTexCoords(aspectRatio, zoom)
  
  -- Store texcoords for cooldown swipe matching (always, even if no icon texture)
  frame._arcTexCoords = { left = left, right = right, top = top, bottom = bottom }
  
  -- Apply texture coords to prevent stretching (only if Icon is a Texture, not a Frame)
  if iconTex and iconTex.SetTexCoord then
    if masqueActive then
      -- MASQUE ACTIVE: Do NOT touch icon texture positioning!
      -- Masque manages the icon texture's anchor points and texcoords when skinning.
      -- Masque skins set specific insets on the icon to leave room for border art.
      -- Calling ClearAllPoints/SetAllPoints here would destroy those insets,
      -- causing icons to fill the entire frame and bleed under the Masque border.
      -- We only store _arcTexCoords above for cooldown swipe reference.
    else
      -- MASQUE INACTIVE: Apply ArcUI texcoord manipulation
      -- CRITICAL: Remove mask textures before applying SetTexCoord
      -- CDM icons have mask textures that cause SetTexCoord to render unevenly
      -- Must be done before SetTexCoord to get proper icon cropping
      if not iconTex._arcMasksRemoved and iconTex.GetMaskTexture and iconTex.RemoveMaskTexture then
        -- Don't use GetNumMaskTextures() as it can return secret values
        -- Instead, try indices directly - CDM icons typically have 1-2 masks max
        local masksToRemove = {}
        for i = 1, 5 do
          local ok, mask = pcall(function() return iconTex:GetMaskTexture(i) end)
          if ok and mask then
            table.insert(masksToRemove, mask)
          end
        end
        -- Remove all collected masks
        for _, mask in ipairs(masksToRemove) do
          pcall(function() iconTex:RemoveMaskTexture(mask) end)
        end
        iconTex._arcMasksRemoved = true
      end
      
      iconTex:SetTexCoord(left, right, top, bottom)
      
      -- Position icon texture with padding
      iconTex:ClearAllPoints()
      iconTex:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
      iconTex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)
    end
  end
  
  -- Store zoom/padding on frame for other features
  frame._arcZoom = zoom
  frame._arcPadding = padding
  

  -- Store settings for OnUpdate sync FIRST - hooks check these flags
  -- IMPORTANT: Use explicit false (not nil) so hooks can check == false
  local showPandemic = (cfg.pandemicBorder and cfg.pandemicBorder.enabled) == true
  local showDebuffBorder = (cfg.debuffBorder and cfg.debuffBorder.enabled) == true
  frame._arcShowPandemic = showPandemic
  frame._arcShowDebuffBorder = showDebuffBorder
  
  -- Apply settings to PandemicIcon (after flags are set so hooks work correctly)
  if frame.PandemicIcon then
    if showPandemic then
      ModuleEnableBorderFrame(frame.PandemicIcon, frame, padding, zoom, "pandemic")
    else
      ModuleDisableBorderFrame(frame.PandemicIcon, "pandemic")
    end
  end
  
  -- Apply settings to DebuffBorder (after flags are set so hooks work correctly)
  if frame.DebuffBorder then
    if showDebuffBorder then
      ModuleEnableBorderFrame(frame.DebuffBorder, frame, padding, zoom, "debuff")
    else
      ModuleDisableBorderFrame(frame.DebuffBorder, "debuff")
    end
  end
  
  -- Register with centralized border watcher (replaces per-frame OnUpdate)
  -- This reduces from 25×60fps=1500 calls/sec to ONE watcher at 2Hz
  if not frame._arcBorderWatcher then
    frame._arcBorderWatcher = true
    RegisterBorderWatch(frame)
  end

  -- ═══════════════════════════════════════════════════════════════════════
  -- PROC GLOW RESIZE - Keep alert sized correctly when icon size changes
  -- If a default glow is currently active, resize it to match new icon size
  -- ═══════════════════════════════════════════════════════════════════════
  if frame._arcProcGlowActive and frame._arcProcGlowType == "default" then
    ResizeProcGlowAlert(frame)
  end

  
  -- ═══════════════════════════════════════════════════════════════════════
  -- PROC GLOW HOOKS - Backup for event-based system
  -- Events (SPELL_ACTIVATION_OVERLAY_GLOW_SHOW/HIDE) are primary
  -- Hooks provide redundancy for edge cases where events might not fire
  -- Both call ShowProcGlow/HideProcGlow which have guards against double-calls
  -- ═══════════════════════════════════════════════════════════════════════
  if frame.SpellActivationAlert then
    local alert = frame.SpellActivationAlert
    alert._arcParentFrame = frame
    
    -- PRE-SIZE the alert to match current icon size BEFORE it shows
    -- This prevents the visual delay where glow appears small then resizes
    ResizeProcGlowAlert(frame)
    
    if not alert._arcProcHooked then
      alert._arcProcHooked = true
      
      -- OnHide safety net: ensures our glow state is cleaned up
      -- Primary hide path is ActionButtonSpellAlertManager:HideAlert hook
      -- This catches direct Hide() calls and frame recycling edge cases
      alert:HookScript("OnHide", function(self)
        local parentFrame = self._arcParentFrame
        if not parentFrame then return end
        
        if parentFrame._arcProcGlowActive then
          if ns.devMode then
            print("|cffFF0000[ArcUI ProcHook]|r OnHide triggered on frame:", parentFrame.cooldownID)
          end
          
          if ns.CDMEnhance and ns.CDMEnhance.HideProcGlow then
            ns.CDMEnhance.HideProcGlow(parentFrame)
          end
        end
      end)
    end
  end
  
  -- Apply CooldownFlash sizing to match icon frame using EXPAND ANCHORS
  -- (SetSize/SetScale don't work reliably, but anchor offsets do!)
  -- When zoom crops the texture, the icon visually expands to fill more of the frame
  -- So CooldownFlash must also expand to match the visual icon area
  if frame.CooldownFlash then
    local cf = frame.CooldownFlash
    
    -- Reset scale to 1 to ensure anchors control size
    cf:SetScale(1)
    
    -- Calculate inset: padding shrinks, zoom expands
    -- Zoom crops texture borders, making icon visually fill more of the frame
    local frameW, frameH = frame:GetSize()
    local zoomExpandX = (zoom or 0) * frameW
    local zoomExpandY = (zoom or 0) * frameH
    local insetX = padding - zoomExpandX  -- Subtract zoom to expand outward
    local insetY = padding - zoomExpandY
    
    -- Apply anchors to match the visual icon area
    -- CDM uses +1 Y offset by default, we preserve that
    cf:ClearAllPoints()
    cf:SetPoint("TOPLEFT", frame, "TOPLEFT", insetX, -insetY + 1)
    cf:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetX, insetY + 1)
    
    -- Hook frame's SetSize to update CooldownFlash anchors when frame resizes
    -- This catches size changes from CDMGroups scale slider
    if not frame._arcCFSizeHooked then
      frame._arcCFSizeHooked = true
      hooksecurefunc(frame, "SetSize", function(self, newW, newH)
        local pad = self._arcPadding or 0
        local zm = self._arcZoom or 0
        local w = newW or self:GetWidth()
        local h = newH or self:GetHeight()
        -- Recalculate: zoom expands, padding shrinks
        local zExpandX = zm * w
        local zExpandY = zm * h
        
        -- For CooldownFlash: padding shrinks, zoom expands (inset calculation)
        local cfInsetX = pad - zExpandX
        local cfInsetY = pad - zExpandY
        
        -- For borders: base 3px offset + zoom expansion - padding
        local baseBorderOffset = 3
        local borderExpandX = baseBorderOffset + zExpandX - pad
        local borderExpandY = baseBorderOffset + zExpandY - pad
        
        -- Update CooldownFlash
        if self.CooldownFlash then
          self.CooldownFlash:ClearAllPoints()
          self.CooldownFlash:SetPoint("TOPLEFT", self, "TOPLEFT", cfInsetX, -cfInsetY + 1)
          self.CooldownFlash:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -cfInsetX, cfInsetY + 1)
        end
        
        -- Update DebuffBorder if enabled
        if self.DebuffBorder and self._arcShowDebuffBorder then
          self.DebuffBorder:ClearAllPoints()
          self.DebuffBorder:SetPoint("TOPLEFT", self, "TOPLEFT", -borderExpandX, borderExpandY)
          self.DebuffBorder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", borderExpandX, -borderExpandY)
        end
        
        -- Update PandemicIcon if enabled
        if self.PandemicIcon and self._arcShowPandemic then
          self.PandemicIcon:ClearAllPoints()
          self.PandemicIcon:SetPoint("TOPLEFT", self, "TOPLEFT", -borderExpandX, borderExpandY)
          self.PandemicIcon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", borderExpandX, -borderExpandY)
        end
      end)
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- MASQUE COOLDOWN CHECK - Must happen FIRST before any cooldown manipulation
  -- When Masque controls cooldowns, we skip ALL positioning, insets, hooks, etc.
  -- ═══════════════════════════════════════════════════════════════════
  local masqueControlsCooldowns = ns.Masque and ns.Masque.ShouldMasqueControlCooldowns and ns.Masque.ShouldMasqueControlCooldowns()
  local swipeCfg = cfg.cooldownSwipe
  
  -- Get swipe insets from config (only used when ArcUI controls cooldowns)
  local swipeInsetX, swipeInsetY
  if swipeCfg and swipeCfg.separateInsets then
    -- Use separate X/Y insets
    swipeInsetX = swipeCfg.swipeInsetX or 0
    swipeInsetY = swipeCfg.swipeInsetY or 0
  else
    -- Use single inset for both
    local inset = (swipeCfg and swipeCfg.swipeInset) or 0
    swipeInsetX = inset
    swipeInsetY = inset
  end
  local totalSwipePaddingX = padding + swipeInsetX
  local totalSwipePaddingY = padding + swipeInsetY
  
  -- Cooldown swipe positioning - SKIP ENTIRELY when Masque controls cooldowns
  if frame.Cooldown and not masqueControlsCooldowns then
    if masqueActive then
      -- MASQUE ACTIVE (but not controlling cooldowns): Don't use TOPLEFT/BOTTOMRIGHT inset positioning.
      -- Masque skins use CENTER-based anchoring for all regions.
      -- Our two-point anchoring fights Masque's layout after re-skins.
      -- Just fill the frame - Masque's Skin_Cooldown will handle it if
      -- controlCooldown is enabled, otherwise default fill is correct.
      frame.Cooldown:ClearAllPoints()
      frame.Cooldown:SetAllPoints(frame)
      
      -- Clear ArcUI inset padding so hooks don't fight Masque
      frame.Cooldown._arcPaddingX = 0
      frame.Cooldown._arcPaddingY = 0
      frame.Cooldown._arcParentFrame = frame
      frame.Cooldown._arcMasqueActive = true
    else
      -- MASQUE INACTIVE: Apply ArcUI's inset positioning
      frame.Cooldown._arcMasqueActive = nil
      frame.Cooldown:ClearAllPoints()
      frame.Cooldown:SetPoint("TOPLEFT", frame, "TOPLEFT", totalSwipePaddingX, -totalSwipePaddingY)
      frame.Cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -totalSwipePaddingX, totalSwipePaddingY)
      
      -- Apply matching texcoord range to cooldown swipe so it matches icon crop
      if frame.Cooldown.SetTexCoordRange then
        local tc = frame._arcTexCoords
        if tc then
          local lowVec = CreateVector2D(tc.left, tc.top)
          local highVec = CreateVector2D(tc.right, tc.bottom)
          frame.Cooldown:SetTexCoordRange(lowVec, highVec)
        end
      end
      
      -- Store padding on cooldown for hooks (includes swipe insets)
      frame.Cooldown._arcPaddingX = totalSwipePaddingX
      frame.Cooldown._arcPaddingY = totalSwipePaddingY
      frame.Cooldown._arcParentFrame = frame
    end
    
    -- Hook SetAllPoints to prevent CDM from resetting our padding
    -- When Masque is active, hook exits early (let Masque/default win)
    if not frame.Cooldown._arcPositionHooked then
      frame.Cooldown._arcPositionHooked = true
      hooksecurefunc(frame.Cooldown, "SetAllPoints", function(self)
        -- If Masque is active, don't fight - our positioning is already SetAllPoints
        if self._arcMasqueActive then return end
        
        local parent = self._arcParentFrame
        local padX = self._arcPaddingX or 0
        local padY = self._arcPaddingY or 0
        if parent and (padX > 0 or padY > 0) then
          self:ClearAllPoints()
          self:SetPoint("TOPLEFT", parent, "TOPLEFT", padX, -padY)
          self:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -padX, padY)
        end
        -- Reapply texcoord range
        if parent and parent._arcTexCoords and self.SetTexCoordRange then
          local tc = parent._arcTexCoords
          local lowVec = CreateVector2D(tc.left, tc.top)
          local highVec = CreateVector2D(tc.right, tc.bottom)
          self:SetTexCoordRange(lowVec, highVec)
        end
      end)
    end
    
    -- Hook parent frame's SetSize to update Cooldown and borders when frame is resized
    -- NOTE: Border resize hooks run regardless of Masque cooldown control
    if not frame._arcFrameSizeHooked then
      frame._arcFrameSizeHooked = true
      hooksecurefunc(frame, "SetSize", function(self)
        if self._arcSettingFrameSize then return end
        
        -- Update Cooldown positioning (skip if Masque controls layout)
        if self.Cooldown and self.Cooldown._arcParentFrame and not self.Cooldown._arcMasqueActive then
          local padX = self.Cooldown._arcPaddingX or 0
          local padY = self.Cooldown._arcPaddingY or 0
          if padX > 0 or padY > 0 then
            self.Cooldown:ClearAllPoints()
            self.Cooldown:SetPoint("TOPLEFT", self, "TOPLEFT", padX, -padY)
            self.Cooldown:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -padX, padY)
          end
        end
        
        -- Update borders on resize (pandemic/debuff need proper sizing)
        local pad = self._arcPadding or 0
        local zm = self._arcZoom or 0
        
        if self.PandemicIcon and self._arcShowPandemic then
          ModuleEnableBorderFrame(self.PandemicIcon, self, pad, zm, "pandemic")
        end
        
        if self.DebuffBorder and self._arcShowDebuffBorder then
          ModuleEnableBorderFrame(self.DebuffBorder, self, pad, zm, "debuff")
        end
        
        -- Update custom border on resize
        if self._arcBorderEdges then
          local cdID = self.cooldownID
          if cdID then
            UpdateIconBorder(self, cdID, nil, nil, pad, zm)
          end
        end
      end)
    end
  end -- END: if frame.Cooldown and not masqueControlsCooldowns
    
  -- Check for ignoreAuraOverride from either location (old: cooldownSwipe, new: auraActiveState)
  -- This must be set REGARDLESS of Masque cooldown control
  local ignoreAuraOverride = (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)
    or (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
  frame._arcIgnoreAuraOverride = ignoreAuraOverride or false
    
  -- ═══════════════════════════════════════════════════════════════════
  -- MASQUE CONTROLS COOLDOWNS: Skip cooldown styling but keep No GCD Swipe
  -- Only skip: SetSwipeColor, SetReverse, SetDrawBling, SetDrawSwipe (styling), 
  --            SetDrawEdge (styling), SetEdgeScale, SetEdgeColor, positioning, TexCoordRange
  -- Keep working: No GCD Swipe toggle, CooldownFlash (Bling) visibility
  -- NOTE: When ignoreAuraOverride is enabled, use ArcUI path so SetCooldown hook gets installed
  -- ═══════════════════════════════════════════════════════════════════
  if masqueControlsCooldowns and not ignoreAuraOverride then
    -- Store NoGCD flags (these work with Masque)
    if swipeCfg then
      frame._arcNoGCDSwipeEnabled = swipeCfg.noGCDSwipe
      frame._arcSwipeWaitForNoCharges = swipeCfg.swipeWaitForNoCharges
      frame._arcNoGCDShowSwipe = swipeCfg.showSwipe ~= false
      frame._arcNoGCDShowEdge = swipeCfg.showEdge ~= false
      
      -- Store user's show swipe/edge preference for Masque mode
      frame._arcUserShowSwipe = swipeCfg.showSwipe ~= false
      frame._arcUserShowEdge = swipeCfg.showEdge ~= false
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- APPLY SHOW SWIPE / SHOW EDGE - User can disable swipe even with Masque
    -- ═══════════════════════════════════════════════════════════════════
    if frame.Cooldown and swipeCfg then
      local showSwipe = swipeCfg.showSwipe ~= false
      local showEdge = swipeCfg.showEdge ~= false
      
      -- Apply user's preference
      frame.Cooldown:SetDrawSwipe(showSwipe)
      frame.Cooldown:SetDrawEdge(showEdge)
    end
    
    -- CooldownFlash (Bling) visibility can still be controlled
    if swipeCfg and frame.CooldownFlash then
      if swipeCfg.showBling == false then
        frame.CooldownFlash:SetAlpha(0)
        if frame.CooldownFlash.Flipbook then
          frame.CooldownFlash.Flipbook:SetAlpha(0)
          if not frame.CooldownFlash.Flipbook._arcAlphaHooked then
            frame.CooldownFlash.Flipbook._arcAlphaHooked = true
            frame.CooldownFlash.Flipbook._arcIconFrame = frame
            hooksecurefunc(frame.CooldownFlash.Flipbook, "SetAlpha", function(self, alpha)
              local iconFrame = self._arcIconFrame
              if iconFrame and iconFrame._arcHideCooldownFlash and alpha > 0 then
                self:SetAlpha(0)
              end
            end)
          end
        end
        if frame.CooldownFlash.FlashAnim and frame.CooldownFlash.FlashAnim.Stop then
          frame.CooldownFlash.FlashAnim:Stop()
          if not frame.CooldownFlash.FlashAnim._arcHideHooked then
            frame.CooldownFlash.FlashAnim._arcHideHooked = true
            frame.CooldownFlash.FlashAnim._arcIconFrame = frame
            hooksecurefunc(frame.CooldownFlash.FlashAnim, "Play", function(self)
              local iconFrame = self._arcIconFrame
              if iconFrame and iconFrame._arcHideCooldownFlash then
                self:Stop()
              end
            end)
          end
        end
        if not frame.CooldownFlash._arcAlphaHooked then
          frame.CooldownFlash._arcAlphaHooked = true
          frame.CooldownFlash._arcIconFrame = frame
          hooksecurefunc(frame.CooldownFlash, "SetAlpha", function(self, alpha)
            local iconFrame = self._arcIconFrame
            if iconFrame and iconFrame._arcHideCooldownFlash and alpha > 0 then
              self:SetAlpha(0)
            end
          end)
        end
        frame._arcHideCooldownFlash = true
      else
        frame._arcHideCooldownFlash = false
        frame.CooldownFlash:SetAlpha(1)
      end
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- NO GCD SWIPE HOOK - Install even when Masque controls cooldowns
    -- This hook ONLY handles No GCD Swipe logic, not styling
    -- ═══════════════════════════════════════════════════════════════════
    if frame.Cooldown and swipeCfg and swipeCfg.noGCDSwipe and not frame.Cooldown._arcMasqueNoGCDHooked then
      frame.Cooldown._arcMasqueNoGCDHooked = true
      frame.Cooldown._arcParentFrame = frame
      
      -- Cache if this is a charge spell
      local cooldownInfo = frame.cooldownInfo
      local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
      if spellID then
        local chargeInfo = nil
        pcall(function() chargeInfo = C_Spell.GetSpellCharges(spellID) end)
        frame._arcIsChargeSpellCached = (chargeInfo ~= nil)
      end
      
      hooksecurefunc(frame.Cooldown, "SetDrawSwipe", function(self, drawSwipe)
        local pf = self._arcParentFrame
        if not pf then return end
        if pf._arcBypassSwipeHook then return end
        if not pf._arcNoGCDSwipeEnabled then return end
        
        local cooldownInfo = pf.cooldownInfo
        local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
        if not spellID then return end
        
        -- Check if this is a charge spell
        local chargeInfo = nil
        pcall(function() chargeInfo = C_Spell.GetSpellCharges(spellID) end)
        
        if chargeInfo then
          -- CHARGE SPELL: Alpha hook handles GCD hiding
          return
        end
        
        -- NORMAL SPELL: Hide swipe during GCD
        local isOnGCD = nil
        pcall(function()
          local cdInfo = C_Spell.GetSpellCooldown(spellID)
          if cdInfo and cdInfo.isOnGCD == true then isOnGCD = true end
        end)
        
        if isOnGCD then
          -- On GCD - force swipe OFF
          if drawSwipe then
            pf._arcBypassSwipeHook = true
            self:SetDrawSwipe(false)
            self:SetDrawEdge(false)
            pf._arcBypassSwipeHook = false
          end
        end
      end)
    end
    
    -- Apply swipe color - Masque doesn't override this, we help it
    if swipeCfg and swipeCfg.swipeColor and frame.Cooldown then
      local sc = swipeCfg.swipeColor
      frame.Cooldown:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- SETCOOLDOWN HOOK FOR MASQUE - Help Masque apply its color during combat
    -- Also applies user's reverse setting and handles charge spell GCD hiding
    -- ═══════════════════════════════════════════════════════════════════
    if frame.Cooldown and not frame.Cooldown._arcMasqueCDHooked then
      frame.Cooldown._arcMasqueCDHooked = true
      frame.Cooldown._arcParentFrame = frame
      frame.Cooldown._arcCdID = cdID
      
      -- Store user's reverse setting for the hook to use
      frame._arcUserReverse = swipeCfg and swipeCfg.reverse == true
      
      hooksecurefunc(frame.Cooldown, "SetCooldown", function(self)
        local parentFrame = self._arcParentFrame
        if not parentFrame then return end
        
        -- Help Masque apply its skin color during combat
        -- Masque's Hook_SetSwipeColor has issues with secret values
        local masqueColor = self._MSQ_Color
        if masqueColor then
          local r = masqueColor.r or masqueColor[1] or 0
          local g = masqueColor.g or masqueColor[2] or 0
          local b = masqueColor.b or masqueColor[3] or 0
          local a = masqueColor.a or masqueColor[4] or 0.8
          
          -- Set Masque's reentrancy guard to bypass their hook
          self._Swipe_Hook = true
          self:SetSwipeColor(r, g, b, a)
          self._Swipe_Hook = nil
        end
        
        -- Apply user's reverse (animation direction) setting
        -- CDM template has reverse="true" by default, so we need to set it explicitly
        self:SetReverse(parentFrame._arcUserReverse or false)
        
        -- ═══════════════════════════════════════════════════════════════════
        -- ENFORCE USER'S SHOW SWIPE / SHOW EDGE SETTINGS
        -- User can disable swipe animation even when Masque controls cooldowns
        -- ═══════════════════════════════════════════════════════════════════
        local userShowSwipe = parentFrame._arcUserShowSwipe
        local userShowEdge = parentFrame._arcUserShowEdge
        if userShowSwipe == false then
          self:SetDrawSwipe(false)
        end
        if userShowEdge == false then
          self:SetDrawEdge(false)
        end
        
        -- ═══════════════════════════════════════════════════════════════════
        -- CHARGE SPELL GCD HIDING - Use chargeDurObj to control swipe visibility
        -- chargeDurObj naturally excludes GCD - same method as non-Masque path
        -- ═══════════════════════════════════════════════════════════════════
        if parentFrame._arcNoGCDSwipeEnabled and parentFrame._arcIsChargeSpellCached then
          local cooldownInfo = parentFrame.cooldownInfo
          local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
          
          if spellID and C_Spell.GetSpellChargeDuration then
            local ok, chargeDurObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
            if ok and chargeDurObj then
              -- Use Binary curve: 0 when all charges ready, 1 when recharging
              InitCooldownCurves()
              if CooldownCurves and CooldownCurves.Binary then
                local okAlpha, alphaResult = pcall(function()
                  return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
                end)
                if okAlpha and alphaResult ~= nil then
                  parentFrame._arcBypassAlphaHook = true
                  pcall(function() self:SetAlpha(alphaResult) end)
                  parentFrame._arcBypassAlphaHook = false
                end
              end
            else
              -- No chargeDurObj = all charges ready, hide swipe
              parentFrame._arcBypassAlphaHook = true
              self:SetAlpha(0)
              parentFrame._arcBypassAlphaHook = false
            end
          end
        end
      end)
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- COOLDOWN ALPHA HOOK - Handles charge spell GCD hiding via curve
    -- GetSpellChargeDuration returns nil when ready, durationObj when recharging
    -- The curve naturally handles GCD filtering (GCD isn't included in charge duration)
    -- ═══════════════════════════════════════════════════════════════════
    if frame.Cooldown and not frame.Cooldown._arcAlphaHooked then
      frame.Cooldown._arcAlphaHooked = true
      
      hooksecurefunc(frame.Cooldown, "SetAlpha", function(self, alpha)
        local pf = self._arcParentFrame
        if not pf then return end
        if pf._arcBypassAlphaHook then return end
        
        -- For charge spells with noGCDSwipe, we control alpha via curves
        if pf._arcNoGCDSwipeEnabled and pf._arcIsChargeSpellCached then
          local cooldownInfo = pf.cooldownInfo
          local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
          
          if spellID and C_Spell.GetSpellChargeDuration then
            local ok, chargeDurObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
            if ok and chargeDurObj then
              local alphaSet = false
              InitCooldownCurves()
              if CooldownCurves and CooldownCurves.Binary then
                local okAlpha, alphaResult = pcall(function()
                  return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
                end)
                if okAlpha and alphaResult ~= nil then
                  pf._arcBypassAlphaHook = true
                  pcall(function() self:SetAlpha(alphaResult) end)
                  pf._arcBypassAlphaHook = false
                  alphaSet = true
                end
              end
              -- Fallback: if curve failed, check charges manually
              if not alphaSet then
                local chargeData = C_Spell.GetSpellCharges(spellID)
                pf._arcBypassAlphaHook = true
                if chargeData and chargeData.currentCharges < chargeData.maxCharges then
                  self:SetAlpha(1)  -- Recharging: show swipe
                else
                  self:SetAlpha(0)  -- All charges ready: hide swipe
                end
                pf._arcBypassAlphaHook = false
              end
            end
          end
        end
      end)
    end
    
    -- Skip other cooldown customization - Masque handles styling
    -- Don't touch: SetReverse, SetDrawBling, SetDrawSwipe (style),
    -- SetDrawEdge (style), SetEdgeScale, SetEdgeColor, positioning, TexCoordRange
    
  else
    -- ARCUI CONTROLS COOLDOWNS: Apply all user settings
    
    -- Apply custom swipe color if set
    if swipeCfg and swipeCfg.swipeColor then
      local sc = swipeCfg.swipeColor
      frame.Cooldown:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- FINISH FLASH (BLING) - Can be controlled even when Masque is active
    -- ═══════════════════════════════════════════════════════════════════
    if swipeCfg and frame.CooldownFlash then
      -- Apply SetDrawBling (only if Masque doesn't control - Masque handles this itself)
      if not masqueControlsCooldowns then
        frame.Cooldown:SetDrawBling(swipeCfg.showBling ~= false)
      end
      
      -- Hide/show CooldownFlash frame (CDM's separate flash animation)
      -- This works regardless of Masque - it's the visual flipbook animation
      -- Structure: CooldownFlash.Flipbook (texture), CooldownFlash.FlashAnim (AnimationGroup)
      if swipeCfg.showBling == false then
        -- Hide via alpha (not Hide()) so CDM's Show() calls still work
        frame.CooldownFlash:SetAlpha(0)
        
        -- Hide Flipbook texture (the actual animation visual)
        if frame.CooldownFlash.Flipbook then
          frame.CooldownFlash.Flipbook:SetAlpha(0)
          
          -- Hook Flipbook:SetAlpha to enforce 0
          if not frame.CooldownFlash.Flipbook._arcAlphaHooked then
            frame.CooldownFlash.Flipbook._arcAlphaHooked = true
            frame.CooldownFlash.Flipbook._arcIconFrame = frame
            hooksecurefunc(frame.CooldownFlash.Flipbook, "SetAlpha", function(self, alpha)
              local iconFrame = self._arcIconFrame
              if iconFrame and iconFrame._arcHideCooldownFlash and alpha > 0 then
                self:SetAlpha(0)
              end
            end)
          end
        end
        
        -- Stop FlashAnim animation group (AnimationGroups use Stop(), not Hide/SetAlpha)
        if frame.CooldownFlash.FlashAnim and frame.CooldownFlash.FlashAnim.Stop then
          frame.CooldownFlash.FlashAnim:Stop()
          
          -- Hook FlashAnim:Play to prevent it from playing
          if not frame.CooldownFlash.FlashAnim._arcHideHooked then
            frame.CooldownFlash.FlashAnim._arcHideHooked = true
            frame.CooldownFlash.FlashAnim._arcIconFrame = frame
            hooksecurefunc(frame.CooldownFlash.FlashAnim, "Play", function(self)
              local iconFrame = self._arcIconFrame
              if iconFrame and iconFrame._arcHideCooldownFlash then
                self:Stop()
              end
            end)
          end
        end
        
        -- Hook CooldownFlash:SetAlpha to enforce 0
        if not frame.CooldownFlash._arcAlphaHooked then
          frame.CooldownFlash._arcAlphaHooked = true
          frame.CooldownFlash._arcIconFrame = frame
          hooksecurefunc(frame.CooldownFlash, "SetAlpha", function(self, alpha)
            local iconFrame = self._arcIconFrame
            if iconFrame and iconFrame._arcHideCooldownFlash and alpha > 0 then
              self:SetAlpha(0)
            end
          end)
        end
        frame._arcHideCooldownFlash = true
      else
        -- Re-enable CooldownFlash - clear flag and restore parent frame visibility
        frame._arcHideCooldownFlash = false
        -- Restore parent frame to visible so child animations can be seen
        -- Don't touch Flipbook alpha - the animation controls it (starts from 0)
        frame.CooldownFlash:SetAlpha(1)
      end
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- NO GCD SWIPE - Can be controlled even when Masque is active
    -- Store the flag on frame so SetCooldown hook can use it
    -- ═══════════════════════════════════════════════════════════════════
    if swipeCfg then
      frame._arcNoGCDSwipeEnabled = swipeCfg.noGCDSwipe
      frame._arcSwipeWaitForNoCharges = swipeCfg.swipeWaitForNoCharges
      -- Store swipe/edge settings for noGCDSwipe mode to use
      frame._arcNoGCDShowSwipe = swipeCfg.showSwipe ~= false
      frame._arcNoGCDShowEdge = swipeCfg.showEdge ~= false
    end
    
    -- Apply cooldown swipe customization
    if swipeCfg and not masqueControlsCooldowns then
      -- ArcUI controls: Apply all user settings
      frame.Cooldown:SetDrawSwipe(swipeCfg.showSwipe ~= false)
      frame.Cooldown:SetDrawEdge(swipeCfg.showEdge ~= false)
      frame.Cooldown:SetReverse(swipeCfg.reverse == true)
      
      -- Apply edge scale (size of spinning edge line)
      if swipeCfg.edgeScale and frame.Cooldown.SetEdgeScale then
        frame.Cooldown:SetEdgeScale(swipeCfg.edgeScale)
      end
      
      -- Apply custom edge color if set
      if swipeCfg.edgeColor and frame.Cooldown.SetEdgeColor then
        local ec = swipeCfg.edgeColor
        frame.Cooldown:SetEdgeColor(ec.r or 1, ec.g or 1, ec.b or 1, ec.a or 1)
      end
      
      -- ═══════════════════════════════════════════════════════════════════
      -- SWIPE MODE HANDLING (Toggle-based)
      -- ═══════════════════════════════════════════════════════════════════
      local noGCDSwipe = swipeCfg.noGCDSwipe
      local swipeWaitForNoCharges = swipeCfg.swipeWaitForNoCharges
      
      -- Build mode signature for change detection
      local modeSignature = (noGCDSwipe and "noGCD_" or "") .. (swipeWaitForNoCharges and "waitNoChg_" or "") .. (ignoreAuraOverride and "ignoreAura" or "normal")
      
      -- Clean up previous mode state if mode changed
      if frame._arcSwipeMode ~= modeSignature then
        frame._arcSwipeMode = modeSignature
        
        -- Restore original cooldown frame state
        frame.Cooldown:SetAlpha(1)
        frame.Cooldown:Show()
        
        -- Handle desaturation based on new mode
        if ignoreAuraOverride then
          -- Entering ignoreAuraOverride mode - apply desaturation immediately if aura is active
          local auraID = frame.auraInstanceID
          local auraActive = auraID and type(auraID) == "number" and auraID > 0
          if auraActive and frame.Icon then
            frame._arcForceDesatValue = 1
            frame._arcBypassDesatHook = true
            if frame.Icon.SetDesaturation then
              frame.Icon:SetDesaturation(1)
            else
              frame.Icon:SetDesaturated(true)
            end
            frame._arcBypassDesatHook = false
          end
        else
          -- NOT in special mode - clear ALL our forced state and let CDM handle everything
          frame._arcForceDesatValue = nil
          
          -- Reset text alpha handling
          if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
            if not frame._arcSwipeWaitForNoCharges then frame._arcCooldownText:SetIgnoreParentAlpha(false) end
          end
          if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
            if not frame._arcSwipeWaitForNoCharges then frame._arcChargeText:SetIgnoreParentAlpha(false) end
          end
          
          -- Trigger CDM to refresh this icon so it shows the proper aura duration
          C_Timer.After(0.05, function()
            if frame.viewerFrame and frame.viewerFrame.RefreshData then
              frame.viewerFrame:RefreshData()
            end
          end)
        end
      end
      
      -- Handle No GCD Swipe toggle
      if noGCDSwipe then
        -- Store the user's desired swipe/edge settings for the SetCooldown hook to use
        frame._arcNoGCDShowSwipe = swipeCfg.showSwipe ~= false
        frame._arcNoGCDShowEdge = swipeCfg.showEdge ~= false
        
        -- Cache whether this is a charge spell (for alpha hook optimization)
        local cooldownInfo = frame.cooldownInfo
        local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
        if spellID then
          local chargeInfo = nil
          pcall(function() chargeInfo = C_Spell.GetSpellCharges(spellID) end)
          frame._arcIsChargeSpellCached = (chargeInfo ~= nil)
        else
          frame._arcIsChargeSpellCached = false
        end
      else
        frame._arcIsChargeSpellCached = false
      end
      
      -- ═══════════════════════════════════════════════════════════════════
      -- SWIPE WAIT FOR NO CHARGES (charge spell handling)
      -- Only show cooldown swipe when ALL charges are consumed.
      -- Uses curves to handle secret durationObj values properly.
      -- Duration text stays visible via SetIgnoreParentAlpha (unless hideTextWithSwipe).
      -- ═══════════════════════════════════════════════════════════════════
      if swipeWaitForNoCharges then
        -- Store hideTextWithSwipe flag
        local hideTextWithSwipe = swipeCfg.hideTextWithSwipe or false
        frame._arcHideTextWithSwipe = hideTextWithSwipe
        
        -- Check if this is a charge spell
        local cooldownInfo = frame.cooldownInfo
        local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
        if spellID then
          local chargeInfo = nil
          pcall(function() chargeInfo = C_Spell.GetSpellCharges(spellID) end)
          frame._arcSwipeWaitChargeSpell = (chargeInfo ~= nil)
          
          if chargeInfo and not hideTextWithSwipe then
            -- Set up text to ignore parent alpha so it stays visible when we hide swipe
            -- Only do this if hideTextWithSwipe is false (user wants text to stay visible)
            if frame.Cooldown then
              for _, region in ipairs({frame.Cooldown:GetRegions()}) do
                if region:IsObjectType("FontString") and region.SetIgnoreParentAlpha then
                  region:SetIgnoreParentAlpha(true)
                end
              end
            end
            if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
              frame._arcCooldownText:SetIgnoreParentAlpha(true)
            end
            if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
              frame._arcChargeText:SetIgnoreParentAlpha(true)
            end
          end
        else
          frame._arcSwipeWaitChargeSpell = false
        end
      else
        frame._arcSwipeWaitChargeSpell = false
        frame._arcHideTextWithSwipe = false
      end
      
      -- ═══════════════════════════════════════════════════════════════════
      -- SWIPE HOOK - Install unconditionally so it works for both
      -- noGCDSwipe and ignoreAuraOverride modes
      -- ═══════════════════════════════════════════════════════════════════
      if frame.Cooldown and not frame.Cooldown._arcSwipeHooked then
        frame.Cooldown._arcSwipeHooked = true
        frame.Cooldown._arcParentFrame = frame
        
        hooksecurefunc(frame.Cooldown, "SetDrawSwipe", function(self, drawSwipe)
          local pf = self._arcParentFrame
          if not pf then return end
          if pf._arcBypassSwipeHook then return end
          
          -- Skip ArcUI's cooldown management if Masque controls cooldowns
          if ns.Masque and ns.Masque.ShouldMasqueControlCooldowns and ns.Masque.ShouldMasqueControlCooldowns() then
            return
          end
          
          -- PREVIEW MODE: CDM tried to change swipe, but we're previewing - reapply preview settings
          if pf._arcSwipePreviewActive then
            local cfg = GetIconSettings(self._arcCdID)
            local swipeCfg = cfg and cfg.cooldownSwipe
            local wantSwipe = not swipeCfg or swipeCfg.showSwipe ~= false
            local wantEdge = not swipeCfg or swipeCfg.showEdge ~= false
            if drawSwipe ~= wantSwipe then
              pf._arcBypassSwipeHook = true
              self:SetDrawSwipe(wantSwipe)
              self:SetDrawEdge(wantEdge)
              pf._arcBypassSwipeHook = false
            end
            return
          end
          
          local cooldownInfo = pf.cooldownInfo
          local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
          if not spellID then return end
          
          -- When ignoreAuraOverride is active
          if pf._arcIgnoreAuraOverride then
            local auraActive = pf.auraInstanceID and pf.auraInstanceID > 0
            local userWantsSwipe = pf._arcShowSwipe
            local userWantsEdge = pf._arcShowEdge
            
            -- Helper to apply all stored swipe/animation settings
            local function ApplyAllStoredSwipeSettings()
              pf._arcBypassSwipeHook = true
              self:SetDrawSwipe(true)
              self:SetDrawEdge(userWantsEdge)
              self:SetDrawBling(pf._arcShowBling ~= false)
              self:SetReverse(pf._arcReverse or false)
              -- Apply swipe color if set
              if pf._arcSwipeColor then
                local sc = pf._arcSwipeColor
                self:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
              end
              -- Apply edge scale if set
              if pf._arcEdgeScale and self.SetEdgeScale then
                self:SetEdgeScale(pf._arcEdgeScale)
              end
              -- Apply edge color if set
              if pf._arcEdgeColor and self.SetEdgeColor then
                local ec = pf._arcEdgeColor
                self:SetEdgeColor(ec.r or 1, ec.g or 1, ec.b or 1, ec.a or 1)
              end
              pf._arcBypassSwipeHook = false
            end
            
            -- Check if noGCDSwipe is also enabled
            if pf._arcNoGCDSwipeEnabled then
              -- Both ignoreAuraOverride AND noGCDSwipe
              -- Check if this is a charge spell first
              local chargeInfo = nil
              pcall(function() chargeInfo = C_Spell.GetSpellCharges(spellID) end)
              
              if chargeInfo then
                -- CHARGE SPELL: Check swipeWaitForNoCharges
                if pf._arcSwipeWaitForNoCharges then
                  -- swipeWaitForNoCharges ON: Alpha controls visibility, always enable swipe
                  if userWantsSwipe and not drawSwipe then
                    ApplyAllStoredSwipeSettings()
                  end
                else
                  -- swipeWaitForNoCharges OFF: Always enforce swipe ON - alpha controls visibility
                  if userWantsSwipe and not drawSwipe then
                    ApplyAllStoredSwipeSettings()
                  end
                end
              else
                -- NORMAL SPELL: Apply GCD filtering
                -- Only react to isOnGCD == true, treat false same as nil
                local isOnGCD = nil
                pcall(function()
                  local cdInfo = C_Spell.GetSpellCooldown(spellID)
                  if cdInfo and cdInfo.isOnGCD == true then isOnGCD = true end
                end)
                
                if isOnGCD then
                  -- On GCD - force swipe OFF for normal spells
                  if drawSwipe then
                    pf._arcBypassSwipeHook = true
                    self:SetDrawSwipe(false)
                    self:SetDrawEdge(false)
                    pf._arcBypassSwipeHook = false
                  end
                elseif userWantsSwipe and not drawSwipe then
                  -- Not on GCD - enforce user's swipe settings
                  ApplyAllStoredSwipeSettings()
                end
              end
            elseif auraActive then
              -- Only ignoreAuraOverride (no noGCDSwipe) - enforce swipe when aura is up
              if userWantsSwipe and not drawSwipe then
                ApplyAllStoredSwipeSettings()
              end
            end
            return  -- Handled by ignoreAuraOverride path
          end
          
          -- When noGCDSwipe is active (without ignoreAuraOverride)
          if pf._arcNoGCDSwipeEnabled then
            local userWantsSwipe = pf._arcNoGCDShowSwipe ~= false
            local userWantsEdge = pf._arcNoGCDShowEdge ~= false
            
            -- CRITICAL: Check if CDM is currently showing aura data for this frame
            -- wasSetFromAura is the runtime flag; hasAura just means the spell CAN produce auras
            -- (e.g. Kidney Shot has hasAura=true for its target stun but CDM tracks it via cooldown)
            local isShowingAura = pf.wasSetFromAura == true
            
            if isShowingAura then
              -- Frame is showing AURA duration - enforce user's swipe preference, no GCD filtering
              if userWantsSwipe and not drawSwipe then
                pf._arcBypassSwipeHook = true
                self:SetDrawSwipe(true)
                self:SetDrawEdge(userWantsEdge)
                pf._arcBypassSwipeHook = false
              end
              return  -- Don't apply GCD logic to aura durations
            end
            
            -- Check if this is a charge spell
            local chargeInfo = nil
            pcall(function() chargeInfo = C_Spell.GetSpellCharges(spellID) end)
            
            if chargeInfo then
              -- CHARGE SPELL: ALWAYS enforce swipe!
              -- chargeDurObj handles visibility via alpha - it only has duration when recharging
              -- We control visibility via Cooldown:SetAlpha(), so always keep swipe enabled
              if userWantsSwipe and not drawSwipe then
                pf._arcBypassSwipeHook = true
                self:SetDrawSwipe(true)
                self:SetDrawEdge(userWantsEdge)
                pf._arcBypassSwipeHook = false
              end
            else
              -- NORMAL SPELL: Keep swipe hidden during GCD
              -- Only react to isOnGCD == true, treat false same as nil
              local isOnGCD = nil
              pcall(function()
                local cdInfo = C_Spell.GetSpellCooldown(spellID)
                if cdInfo and cdInfo.isOnGCD == true then isOnGCD = true end
              end)
              
              if isOnGCD then
                -- On GCD - force swipe OFF if CDM tried to enable it
                if drawSwipe then
                  pf._arcBypassSwipeHook = true
                  self:SetDrawSwipe(false)
                  self:SetDrawEdge(false)
                  pf._arcBypassSwipeHook = false
                end
              else
                -- NOT on GCD - allow swipe if user wants it
                if userWantsSwipe and not drawSwipe then
                  pf._arcBypassSwipeHook = true
                  self:SetDrawSwipe(true)
                  self:SetDrawEdge(userWantsEdge)
                  pf._arcBypassSwipeHook = false
                end
              end
            end
          end
          
          -- ═══════════════════════════════════════════════════════════════════
          -- NORMAL MODE: No special modes active - enforce user's swipe/edge settings
          -- This ensures CDM can't override user settings in basic usage
          -- ═══════════════════════════════════════════════════════════════════
          if not pf._arcSwipePreviewActive and not pf._arcIgnoreAuraOverride and not pf._arcNoGCDSwipeEnabled then
            local currentCdID = self._arcCdID
            if currentCdID then
              local cfg = GetIconSettings(currentCdID)
              if cfg and cfg.cooldownSwipe then
                local userWantsSwipe = cfg.cooldownSwipe.showSwipe ~= false
                local userWantsEdge = cfg.cooldownSwipe.showEdge ~= false
                
                -- Enforce swipe setting if CDM tried to change it
                if userWantsSwipe and not drawSwipe then
                  -- User wants swipe ON but CDM set it OFF - fix it
                  pf._arcBypassSwipeHook = true
                  self:SetDrawSwipe(true)
                  self:SetDrawEdge(userWantsEdge)
                  pf._arcBypassSwipeHook = false
                elseif not userWantsSwipe and drawSwipe then
                  -- User wants swipe OFF but CDM set it ON - fix it
                  pf._arcBypassSwipeHook = true
                  self:SetDrawSwipe(false)
                  self:SetDrawEdge(false)
                  pf._arcBypassSwipeHook = false
                end
              end
            end
          end
        end)
      end
      
      -- ═══════════════════════════════════════════════════════════════════
      -- EDGE HOOK - Enforce user's showEdge setting when CDM tries to override
      -- This fixes flickering when showSwipe=true but showEdge=false
      -- CDM sometimes calls SetDrawEdge(true) directly, overriding user settings
      -- IMPORTANT: Must respect noGCDSwipe - don't re-enable edge during GCD
      -- ═══════════════════════════════════════════════════════════════════
      if frame.Cooldown and not frame.Cooldown._arcEdgeHooked then
        frame.Cooldown._arcEdgeHooked = true
        
        hooksecurefunc(frame.Cooldown, "SetDrawEdge", function(self, drawEdge)
          local pf = self._arcParentFrame
          if not pf then return end
          if pf._arcBypassSwipeHook then return end  -- Use same bypass flag
          
          -- Skip ArcUI's cooldown management if Masque controls cooldowns
          if ns.Masque and ns.Masque.ShouldMasqueControlCooldowns and ns.Masque.ShouldMasqueControlCooldowns() then
            return
          end
          
          -- Get user's desired edge setting
          local currentCdID = self._arcCdID
          if not currentCdID then return end
          
          local cfg = GetIconSettings(currentCdID)
          if not cfg or not cfg.cooldownSwipe then return end
          
          local userWantsEdge = cfg.cooldownSwipe.showEdge ~= false
          
          -- If CDM tried to enable edge but user wants it OFF, enforce OFF
          if drawEdge and not userWantsEdge then
            pf._arcBypassSwipeHook = true
            self:SetDrawEdge(false)
            pf._arcBypassSwipeHook = false
          -- If CDM tried to disable edge but user wants it ON
          elseif not drawEdge and userWantsEdge then
            -- CRITICAL: Don't re-enable edge if noGCDSwipe is hiding GCD!
            -- The SetDrawSwipe hook intentionally hides both swipe AND edge during GCD
            if pf._arcNoGCDSwipeEnabled then
              -- Check if we're on GCD - if so, respect the hide
              local cooldownInfo = pf.cooldownInfo
              local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
              if spellID then
                local isOnGCD = nil
                pcall(function()
                  local cdInfo = C_Spell.GetSpellCooldown(spellID)
                  if cdInfo and cdInfo.isOnGCD == true then isOnGCD = true end
                end)
                if isOnGCD then
                  -- On GCD with noGCDSwipe enabled - DON'T re-enable edge
                  return
                end
              end
            end
            
            -- Not on GCD (or noGCDSwipe disabled) - safe to enforce user's edge setting
            local userWantsSwipe = cfg.cooldownSwipe.showSwipe ~= false
            if userWantsSwipe then
              pf._arcBypassSwipeHook = true
              self:SetDrawEdge(true)
              pf._arcBypassSwipeHook = false
            end
          end
        end)
      end
      
      -- ═══════════════════════════════════════════════════════════════════
      -- COOLDOWN ALPHA HOOK - Prevent CDM from overriding our curve-based alpha
      -- For charge spells, we use curve-based alpha to control visibility
      -- ═══════════════════════════════════════════════════════════════════
      if frame.Cooldown and not frame.Cooldown._arcAlphaHooked then
        frame.Cooldown._arcAlphaHooked = true
        
        hooksecurefunc(frame.Cooldown, "SetAlpha", function(self, alpha)
          local pf = self._arcParentFrame
          if not pf then return end
          if pf._arcBypassAlphaHook then return end
          
          -- PREVIEW MODE: CDM tried to set alpha, but we're previewing - force alpha to 1
          if pf._arcSwipePreviewActive then
            if alpha ~= 1 then
              pf._arcBypassAlphaHook = true
              self:SetAlpha(1)
              pf._arcBypassAlphaHook = false
            end
            return
          end
          
          -- ═══════════════════════════════════════════════════════════════════
          -- SWIPE WAIT FOR NO CHARGES: Control Cooldown alpha based on durationObj
          -- - Use curve to evaluate secret durationObj (SetAlpha accepts secrets)
          -- - Hide swipe during GCD (phantom CD filtering)
          -- - Text stays visible via SetIgnoreParentAlpha set on every alpha change
          -- ═══════════════════════════════════════════════════════════════════
          if pf._arcSwipeWaitForNoCharges and pf._arcSwipeWaitChargeSpell then
            local cooldownInfo = pf.cooldownInfo
            local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
            
            if spellID then
              -- Only preserve text visibility if hideTextWithSwipe is false
              if not pf._arcHideTextWithSwipe then
                -- Ensure text ignores parent alpha (in case CDM recreated text elements)
                for _, region in ipairs({self:GetRegions()}) do
                  if region:IsObjectType("FontString") and region.SetIgnoreParentAlpha then
                    region:SetIgnoreParentAlpha(true)
                  end
                end
                if pf._arcCooldownText and pf._arcCooldownText.SetIgnoreParentAlpha then
                  pf._arcCooldownText:SetIgnoreParentAlpha(true)
                end
                if pf._arcChargeText and pf._arcChargeText.SetIgnoreParentAlpha then
                  pf._arcChargeText:SetIgnoreParentAlpha(true)
                end
              end
              
              -- Check isOnGCD (non-secret!) - if true, hide swipe to filter phantom GCD
              -- Only react to isOnGCD == true, treat false same as nil
              local isOnGCD = nil
              pcall(function()
                local cdInfo = C_Spell.GetSpellCooldown(spellID)
                if cdInfo and cdInfo.isOnGCD == true then isOnGCD = true end
              end)
              
              if isOnGCD then
                -- During GCD - FREEZE by hiding swipe (alpha=0)
                -- This filters out the phantom GCD that appears when casting
                pf._arcBypassAlphaHook = true
                self:SetAlpha(0)
                pf._arcBypassAlphaHook = false
              else
                -- Not on GCD - use durationObj to control swipe visibility
                -- GetSpellCooldownDuration returns nil when charges available, 
                -- or durationObj when ALL charges are consumed
                local ok, durationObj = pcall(C_Spell.GetSpellCooldownDuration, spellID)
                
                if ok and durationObj then
                  -- durationObj exists - use Binary curve to get alpha
                  -- Binary curve: 0% remaining = 0 (ready), >0% remaining = 1 (on CD)
                  InitCooldownCurves()
                  if CooldownCurves and CooldownCurves.Binary then
                    local okAlpha, alphaResult = pcall(function()
                      return durationObj:EvaluateRemainingPercent(CooldownCurves.Binary)
                    end)
                    if okAlpha and alphaResult ~= nil then
                      -- SetAlpha accepts secret values!
                      pf._arcBypassAlphaHook = true
                      self:SetAlpha(alphaResult)
                      pf._arcBypassAlphaHook = false
                    end
                  end
                else
                  -- No durationObj = charges available, hide swipe
                  pf._arcBypassAlphaHook = true
                  self:SetAlpha(0)
                  pf._arcBypassAlphaHook = false
                end
              end
              return -- Handled swipeWaitForNoCharges
            end
          end
          
          -- For charge spells with noGCDSwipe, we control alpha via curves
          -- Prevent CDM from overriding it
          if pf._arcNoGCDSwipeEnabled and pf._arcIsChargeSpellCached then
            local cooldownInfo = pf.cooldownInfo
            local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
            
            if spellID and C_Spell.GetSpellChargeDuration then
              local ok, chargeDurObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
              if ok and chargeDurObj then
                local alphaSet = false
                InitCooldownCurves()
                if CooldownCurves and CooldownCurves.Binary then
                  local okAlpha, alphaResult = pcall(function()
                    return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
                  end)
                  if okAlpha and alphaResult ~= nil then
                    pf._arcBypassAlphaHook = true
                    pcall(function()
                      self:SetAlpha(alphaResult)
                    end)
                    pf._arcBypassAlphaHook = false
                    alphaSet = true
                  end
                end
                -- Fallback: if curve failed, check charges manually
                if not alphaSet then
                  local chargeData = C_Spell.GetSpellCharges(spellID)
                  pf._arcBypassAlphaHook = true
                  if chargeData and chargeData.currentCharges < chargeData.maxCharges then
                    self:SetAlpha(1)  -- Recharging: show swipe
                  else
                    self:SetAlpha(0)  -- All charges ready: hide swipe
                  end
                  pf._arcBypassAlphaHook = false
                end
              end
            end
          end
        end)
      end
      
      -- Handle Ignore Aura Override toggle
      if ignoreAuraOverride then
        -- Store ALL user's swipe/animation preferences for ignoreAuraOverride to respect
        frame._arcShowSwipe = swipeCfg.showSwipe ~= false
        frame._arcShowEdge = swipeCfg.showEdge ~= false
        frame._arcShowBling = swipeCfg.showBling ~= false
        frame._arcReverse = swipeCfg.reverse == true
        frame._arcSwipeColor = swipeCfg.swipeColor
        frame._arcEdgeScale = swipeCfg.edgeScale
        frame._arcEdgeColor = swipeCfg.edgeColor
        
        -- Hook Icon:SetTexture to enforce our override texture when aura is active
        if frame.Icon and not frame.Icon._arcTextureHooked then
          frame.Icon._arcTextureHooked = true
          frame.Icon._arcParentFrame = frame
          
          hooksecurefunc(frame.Icon, "SetTexture", function(self, newTexture)
            local pf = self._arcParentFrame
            if not pf then return end
            if pf._arcBypassTextureHook then return end
            
            -- Only enforce when ignoreAuraOverride is active AND aura is up
            if pf._arcIgnoreAuraOverride then
              local auraID = pf.auraInstanceID
              local auraActive = auraID and type(auraID) == "number" and auraID > 0
              if auraActive then
                -- Get current override spell from cooldownInfo (updates dynamically based on talents)
                local cooldownInfo = pf.cooldownInfo
                local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
                if spellID then
                  local texture = C_Spell.GetSpellTexture(spellID)
                  if texture then
                    pf._arcBypassTextureHook = true
                    self:SetTexture(texture)
                    pf._arcBypassTextureHook = false
                  end
                end
              end
            end
          end)
        end
        
        -- Set initial spell texture ONLY when ignoreAuraOverride is active
        -- This ensures we show the spell icon immediately, not the aura icon
        if ignoreAuraOverride then
          local cooldownInfo = frame.cooldownInfo
          local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
          if spellID and frame.Icon then
            local texture = C_Spell.GetSpellTexture(spellID)
            if texture then
              frame._arcBypassTextureHook = true
              frame.Icon:SetTexture(texture)
              frame._arcBypassTextureHook = false
            end
          end
        end
      end
      
      -- If neither toggle is on, let CDM handle everything normally
      if not noGCDSwipe and not ignoreAuraOverride then
        frame.Cooldown:SetAlpha(1)
      end
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- DESATURATION HOOKS - Install unconditionally so they work when 
    -- ignoreAuraOverride is enabled/disabled dynamically
    -- ═══════════════════════════════════════════════════════════════════
    if frame.Icon and not frame.Icon._arcDesatHooked then
      frame.Icon._arcDesatHooked = true
      frame.Icon._arcParentFrame = frame
      
      -- Helper function to compute and apply curve-based desaturation
      -- Called by both SetDesaturated and SetDesaturation hooks
      local function ApplyIgnoreAuraDesaturation(iconTexture, parentFrame)
        -- Check if ignoreAuraOverride should apply:
        -- 1. Flag set by scan (fast path) OR
        -- 2. Config has it enabled AND CDM is in aura mode (catches transitions between scans)
        local shouldApply = parentFrame._arcIgnoreAuraOverride
        if not shouldApply then
          -- Check config directly - handles timing where CDM transitions to aura mode
          -- after our scan ran but before the next scan. Without this, CDM's
          -- SetDesaturated(false) goes through unintercepted.
          if parentFrame.wasSetFromAura == true then
            local cfg = GetEffectiveIconSettingsForFrame(parentFrame)
            if cfg then
              shouldApply = (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
                         or (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)
            end
          end
        end
        if not shouldApply then return false end
        if not iconTexture.SetDesaturation then return false end
        
        -- Check for noDesaturate mode first (force colored)
        local cfg = GetEffectiveIconSettingsForFrame(parentFrame)
        local stateVisuals = cfg and GetEffectiveStateVisuals(cfg)
        if stateVisuals and stateVisuals.noDesaturate then
          parentFrame._arcBypassDesatHook = true
          iconTexture:SetDesaturation(0)
          parentFrame._arcBypassDesatHook = false
          return true
        end
        
        -- Get spell info and evaluate curve
        local cooldownInfo = parentFrame.cooldownInfo
        local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
        if not spellID then return false end
        
        -- Get cooldown state and duration object
        local isOnGCD, durationObj, isChargeSpell, chargeDurObj = GetSpellCooldownState(spellID)
        
        -- For charge spells with ignoreAuraOverride, use durationObj (tracks "any charge on CD")
        -- This matches the logic in ApplyCooldownStateVisuals
        local desatDurObj = durationObj
        
        -- ALWAYS filter GCD for desaturation - GCD shouldn't gray out the icon
        -- noGCDSwipe only controls swipe visibility, not desaturation
        if isOnGCD then
          parentFrame._arcBypassDesatHook = true
          iconTexture:SetDesaturation(0)
          parentFrame._arcBypassDesatHook = false
          return true
        end
        
        -- Evaluate curve and apply
        if desatDurObj and CooldownCurves.Binary then
          local ok, desatResult = pcall(function()
            return desatDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
          end)
          if ok and desatResult ~= nil then
            parentFrame._arcBypassDesatHook = true
            iconTexture:SetDesaturation(desatResult)
            parentFrame._arcBypassDesatHook = false
            return true
          end
        end
        
        return false
      end
      
      -- Hook SetDesaturated (boolean version) - CDM uses this for auras
      -- NOTE: We can't sync border here because CDM passes secret values
      -- Border sync happens in ApplyCooldownStateVisuals where we control the values
      hooksecurefunc(frame.Icon, "SetDesaturated", function(self, desaturated)
        local pf = self._arcParentFrame
        if not pf then return end
        if pf._arcBypassDesatHook then return end
        
        -- When ignoreAuraOverride is active, compute fresh curve result and apply it
        if ApplyIgnoreAuraDesaturation(self, pf) then
          return
        end
        
        -- Fallback: If we have a forced desaturation value, enforce it
        local forceValue = pf._arcForceDesatValue
        if forceValue ~= nil and self.SetDesaturation then
          pf._arcBypassDesatHook = true
          self:SetDesaturation(forceValue)
          pf._arcBypassDesatHook = false
        end
        -- Don't sync border here - desaturated param may be secret
      end)
      
      -- Hook SetDesaturation (numeric version) to enforce our state
      -- NOTE: We can't sync border here because CDM may pass secret values
      if frame.Icon.SetDesaturation then
        hooksecurefunc(frame.Icon, "SetDesaturation", function(self, value)
          local pf = self._arcParentFrame
          if not pf then return end
          if pf._arcBypassDesatHook then return end
          
          -- When ignoreAuraOverride is active, compute fresh curve result and apply it
          if ApplyIgnoreAuraDesaturation(self, pf) then
            return
          end
          
          -- Fallback: If we have a forced desaturation value, enforce it
          local forceValue = pf._arcForceDesatValue
          if forceValue ~= nil then
            pf._arcBypassDesatHook = true
            self:SetDesaturation(forceValue)
            pf._arcBypassDesatHook = false
          end
          -- Don't sync border here - value param may be secret
        end)
      end
    end
    
    -- Hook SetCooldown to reapply our settings after CDM updates
    if not frame.Cooldown._arcHooked then
      frame.Cooldown._arcHooked = true
      frame.Cooldown._arcParentFrame = frame
      frame.Cooldown._arcCdID = cdID
      
      hooksecurefunc(frame.Cooldown, "SetCooldown", function(self)
        local parentFrame = self._arcParentFrame
        local currentCdID = self._arcCdID
        if not parentFrame or not currentCdID then return end
        
        -- ALWAYS reapply padding after SetCooldown (CDM resets positioning)
        local padX = self._arcPaddingX or 0
        local padY = self._arcPaddingY or 0
        if padX > 0 or padY > 0 then
          self:ClearAllPoints()
          self:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", padX, -padY)
          self:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -padX, padY)
        end
        
        -- ALWAYS reapply texcoord range to match icon crop
        if parentFrame._arcTexCoords and self.SetTexCoordRange then
          local tc = parentFrame._arcTexCoords
          local lowVec = CreateVector2D(tc.left, tc.top)
          local highVec = CreateVector2D(tc.right, tc.bottom)
          self:SetTexCoordRange(lowVec, highVec)
        end
        
        -- When Masque controls cooldowns: Help Masque apply its skin color
        -- Masque's Hook_SetSwipeColor has issues with secret values in combat,
        -- so we apply Masque's desired color using our method
        -- We set _Swipe_Hook to bypass Masque's hook entirely (prevents visual glitches)
        local masqueControlsCooldowns = ns.Masque and ns.Masque.ShouldMasqueControlCooldowns and ns.Masque.ShouldMasqueControlCooldowns()
        
        if masqueControlsCooldowns then
          local masqueColor = self._MSQ_Color
          if masqueColor then
            local r = masqueColor.r or masqueColor[1] or 0
            local g = masqueColor.g or masqueColor[2] or 0
            local b = masqueColor.b or masqueColor[3] or 0
            local a = masqueColor.a or masqueColor[4] or 0.8
            
            -- Set Masque's reentrancy guard to bypass their hook
            self._Swipe_Hook = true
            self:SetSwipeColor(r, g, b, a)
            self._Swipe_Hook = nil
          end
          
          -- Reset reverse to false (CDM template has reverse="true" by default)
          -- This ensures normal cooldown animation direction when Masque controls
          self:SetReverse(false)
          
          -- Check if noGCDSwipe or ignoreAuraOverride is enabled - if so, we still need to handle it
          -- even when Masque controls other cooldown visuals
          if not parentFrame._arcNoGCDSwipeEnabled and not parentFrame._arcIgnoreAuraOverride then
            return  -- Let Masque handle everything else
          end
          -- Fall through to handle noGCDSwipe / ignoreAuraOverride below
        end
        
        -- Skip if this is our own override call
        if parentFrame._arcBypassCDHook then return end
        
        -- PREVIEW MODE: CDM tried to update, but we're previewing - REAPPLY preview settings
        -- hooksecurefunc runs AFTER original, so CDM's values are already set - we must override them
        if parentFrame._arcSwipePreviewActive then
          local now = GetTime()
          parentFrame._arcBypassCDHook = true
          self:SetCooldown(now, 30)
          parentFrame._arcBypassCDHook = false
          -- Ensure visibility
          self:SetAlpha(1)
          self:Show()
          return
        end
        
        local currentCfg = GetIconSettings(currentCdID)
        if not currentCfg or not currentCfg.cooldownSwipe then return end
        
        local swipe = currentCfg.cooldownSwipe
        
        -- Check for ignoreAuraOverride in both old location (cooldownSwipe) and new location (auraActiveState)
        local ignoreAuraOverride = parentFrame._arcIgnoreAuraOverride 
          or swipe.ignoreAuraOverride 
          or (currentCfg.auraActiveState and currentCfg.auraActiveState.ignoreAuraOverride)
        
        -- Handle Ignore Aura Override - we take FULL control of swipe/edge
        if ignoreAuraOverride then
          -- ═══════════════════════════════════════════════════════════════════
          -- IGNORE AURA OVERRIDE MODE
          -- Purpose: Show SPELL cooldown in the Cooldown frame instead of aura duration
          -- State visuals (alpha/desat/glow) are handled by ApplyCooldownStateVisuals
          -- ═══════════════════════════════════════════════════════════════════
          
          local cooldownInfo = parentFrame.cooldownInfo
          local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
          local baseSpellID = cooldownInfo and cooldownInfo.spellID
          
          -- Check if noGCDSwipe is enabled (hide swipe during GCD)
          local noGCDSwipeEnabled = swipe.noGCDSwipe or false
          
          if spellID then
            local isOnGCD, durationObj, isChargeSpell, chargeDurObj = GetSpellCooldownState(spellID)
            
            -- Fallback: if overrideSpellID returned no durationObj, try base spellID
            if not durationObj and baseSpellID and baseSpellID ~= spellID then
              local _, baseDurObj, baseIsCharge, baseChargeDur = GetSpellCooldownState(baseSpellID)
              if baseDurObj then
                durationObj = baseDurObj
                if baseIsCharge then
                  isChargeSpell = true
                  chargeDurObj = baseChargeDur
                end
              end
            end
            
            -- Check swipeWaitForNoCharges setting
            local swipeWaitForNoCharges = parentFrame._arcSwipeWaitForNoCharges
            local hideTextWithSwipe = swipe.hideTextWithSwipe
            
            -- CHARGE SPELLS: Handle separately - use alpha to control visibility
            -- For ignoreAuraOverride: SAME behavior as normal charge spells
            -- (only difference is SetCooldown hook intercepts aura-based cooldown)
            if isChargeSpell and chargeDurObj then
              -- Preserve text visibility (unless hideTextWithSwipe is enabled)
              if not hideTextWithSwipe then
                for _, region in ipairs({self:GetRegions()}) do
                  if region:IsObjectType("FontString") and region.SetIgnoreParentAlpha then
                    region:SetIgnoreParentAlpha(true)
                  end
                end
                if parentFrame._arcCooldownText and parentFrame._arcCooldownText.SetIgnoreParentAlpha then
                  parentFrame._arcCooldownText:SetIgnoreParentAlpha(true)
                end
                if parentFrame._arcChargeText and parentFrame._arcChargeText.SetIgnoreParentAlpha then
                  parentFrame._arcChargeText:SetIgnoreParentAlpha(true)
                end
              end
              
              if swipeWaitForNoCharges then
                -- WAIT FOR NO CHARGES: Show swipe only when ALL charges consumed
                -- - Push chargeDurObj so duration text shows recharge timer
                -- - Use durationObj curve for alpha: hide swipe when charges available
                -- - Text stays visible via SetIgnoreParentAlpha
                
                -- Push chargeDurObj for duration text (shows recharge timer)
                parentFrame._arcBypassCDHook = true
                pcall(function()
                  self:SetUseAuraDisplayTime(false)
                  self:SetCooldownFromDurationObject(chargeDurObj)
                end)
                parentFrame._arcBypassCDHook = false
                
                -- Enable swipe (alpha will control visibility)
                self:SetDrawSwipe(swipe.showSwipe ~= false)
                self:SetDrawEdge(swipe.showEdge ~= false)
                
                -- Use Binary curve on durationObj to control swipe visibility:
                -- - durationObj = 0% → charges available → alpha=0 (hide swipe)
                -- - durationObj > 0% → all charges consumed → alpha=1 (show swipe)
                -- Filter GCD only if noGCDSwipe is enabled
                if noGCDSwipeEnabled and isOnGCD then
                  -- During GCD - hide swipe (don't show phantom CD)
                  parentFrame._arcBypassAlphaHook = true
                  self:SetAlpha(0)
                  parentFrame._arcBypassAlphaHook = false
                elseif durationObj then
                  InitCooldownCurves()
                  if CooldownCurves and CooldownCurves.Binary then
                    local ok, swipeAlpha = pcall(function()
                      return durationObj:EvaluateRemainingPercent(CooldownCurves.Binary)
                    end)
                    if ok and swipeAlpha ~= nil then
                      parentFrame._arcBypassAlphaHook = true
                      self:SetAlpha(swipeAlpha)
                      parentFrame._arcBypassAlphaHook = false
                    end
                  end
                end
              else
                -- DEFAULT: Show swipe when recharging (any charge used)
                -- Use chargeDurObj (GetSpellChargeDuration):
                -- - chargeDurObj = 0% → all charges ready → hide swipe
                -- - chargeDurObj > 0% → recharging → show swipe
                
                -- Check if aura is active
                local auraID = parentFrame.auraInstanceID
                local auraActive = auraID and type(auraID) == "number" and auraID > 0
                
                if auraActive then
                  -- Aura is active - push chargeDurObj to override CDM's aura display
                  parentFrame._arcBypassCDHook = true
                  pcall(function()
                    self:SetUseAuraDisplayTime(false)
                    self:SetCooldownFromDurationObject(chargeDurObj)
                  end)
                  parentFrame._arcBypassCDHook = false
                  
                  -- Enable swipe (alpha will control visibility)
                  self:SetDrawSwipe(swipe.showSwipe ~= false)
                  self:SetDrawEdge(swipe.showEdge ~= false)
                  
                  -- noGCDSwipe controls whether we hide swipe when all charges ready
                  if noGCDSwipeEnabled then
                    -- Use Binary curve on chargeDurObj: 0 when all ready, 1 when recharging
                    InitCooldownCurves()
                    if CooldownCurves and CooldownCurves.Binary then
                      local ok, swipeAlpha = pcall(function()
                        return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
                      end)
                      if ok and swipeAlpha ~= nil then
                        parentFrame._arcBypassAlphaHook = true
                        self:SetAlpha(swipeAlpha)
                        parentFrame._arcBypassAlphaHook = false
                      end
                    end
                  else
                    -- noGCDSwipe OFF: Show swipe at full alpha
                    parentFrame._arcBypassAlphaHook = true
                    self:SetAlpha(1)
                    parentFrame._arcBypassAlphaHook = false
                  end
                else
                  -- Aura NOT active - let CDM handle naturally (shows GCD, charge recharge)
                  self:SetDrawSwipe(swipe.showSwipe ~= false)
                  self:SetDrawEdge(swipe.showEdge ~= false)
                  
                  if noGCDSwipeEnabled then
                    -- Use Binary curve on chargeDurObj to hide swipe when all charges ready
                    InitCooldownCurves()
                    if CooldownCurves and CooldownCurves.Binary then
                      local ok, swipeAlpha = pcall(function()
                        return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
                      end)
                      if ok and swipeAlpha ~= nil then
                        parentFrame._arcBypassAlphaHook = true
                        self:SetAlpha(swipeAlpha)
                        parentFrame._arcBypassAlphaHook = false
                      end
                    end
                  end
                  -- If noGCDSwipe OFF, don't touch alpha - CDM controls it
                end
              end
            elseif isOnGCD and noGCDSwipeEnabled then
              -- NORMAL SPELL during GCD: hide swipe only, don't touch alpha
              -- Preserve text visibility during GCD freeze
              for _, region in ipairs({self:GetRegions()}) do
                if region:IsObjectType("FontString") and region.SetIgnoreParentAlpha then
                  region:SetIgnoreParentAlpha(true)
                end
              end
              if parentFrame._arcCooldownText and parentFrame._arcCooldownText.SetIgnoreParentAlpha then
                parentFrame._arcCooldownText:SetIgnoreParentAlpha(true)
              end
              if parentFrame._arcChargeText and parentFrame._arcChargeText.SetIgnoreParentAlpha then
                parentFrame._arcChargeText:SetIgnoreParentAlpha(true)
              end
              
              if durationObj then
                -- Push the cooldown (includes GCD + actual CD time)
                parentFrame._arcBypassCDHook = true
                pcall(function()
                  self:SetUseAuraDisplayTime(false)
                  self:SetCooldownFromDurationObject(durationObj)
                end)
                parentFrame._arcBypassCDHook = false
              end
              
              -- Only hide swipe visual during GCD (nothing else!)
              self:SetDrawSwipe(false)
              self:SetDrawEdge(false)
            else
              -- NORMAL SPELL: Not on GCD, OR noGCDSwipe is disabled
              -- (Charge spells already handled above)
              if durationObj then
                -- Push spell cooldown to Cooldown frame
                parentFrame._arcBypassCDHook = true
                pcall(function()
                  self:SetUseAuraDisplayTime(false)
                  self:SetCooldownFromDurationObject(durationObj)
                end)
                parentFrame._arcBypassCDHook = false
              end
              -- If durationObj is nil, don't clear — let CDM's display stand
              -- (clearing causes flicker as CDM immediately re-applies aura timing)
              
              -- Apply user's swipe/edge settings
              self:SetDrawSwipe(swipe.showSwipe ~= false)
              self:SetDrawEdge(swipe.showEdge ~= false)
            end
            
            -- Set texture to spell icon (not aura icon)
            if parentFrame.Icon then
              local texture = C_Spell.GetSpellTexture(spellID)
              if texture then
                parentFrame._arcBypassTextureHook = true
                parentFrame.Icon:SetTexture(texture)
                parentFrame._arcBypassTextureHook = false
              end
            end
          end
          
          -- Apply bling/reverse/color based on who controls cooldowns
          if not masqueControlsCooldowns then
            -- ArcUI controls: Apply all user settings
            self:SetDrawBling(swipe.showBling ~= false)
            self:SetReverse(swipe.reverse == true)
            
            -- Set swipe color - either user's custom color or default black
            -- This overrides CDM's colored aura swipe with normal cooldown swipe
            if swipe.swipeColor then
              local sc = swipe.swipeColor
              self:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.7)
            else
              -- Default cooldown swipe color (black) - matches CDM's default
              self:SetSwipeColor(0, 0, 0, 0.7)
            end
          else
            -- Masque controls: Only reset reverse to false (CDM template has reverse="true")
            -- Don't touch bling or color - let Masque handle those
            self:SetReverse(false)
          end
        elseif parentFrame._arcNoGCDSwipeEnabled then
          -- No GCD Swipe mode
          local cooldownInfo = parentFrame.cooldownInfo
          local spellID = cooldownInfo and (cooldownInfo.overrideSpellID or cooldownInfo.spellID)
          
          if spellID then
            local showSwipe = parentFrame._arcNoGCDShowSwipe ~= false
            local showEdge = parentFrame._arcNoGCDShowEdge ~= false
            
            -- Check if aura is active - if so, let CDM handle display (just filter GCD)
            local auraID = parentFrame.auraInstanceID
            local auraActive = auraID and type(auraID) == "number" and auraID > 0
            
            -- Check if charge spell
            local chargeInfo = nil
            pcall(function() chargeInfo = C_Spell.GetSpellCharges(spellID) end)
            
            if chargeInfo and C_Spell.GetSpellChargeDuration then
              -- CHARGE SPELL
              if auraActive then
                -- Aura is active - let CDM show aura duration, just filter GCD from swipe
                -- Only react to isOnGCD == true, treat false same as nil
                local isOnGCD = nil
                pcall(function()
                  local cdInfo = C_Spell.GetSpellCooldown(spellID)
                  if cdInfo and cdInfo.isOnGCD == true then isOnGCD = true end
                end)
                
                if isOnGCD then
                  -- On GCD only - hide swipe
                  self:SetDrawSwipe(false)
                  self:SetDrawEdge(false)
                else
                  -- NOT on GCD - let CDM's aura display show through
                  self:SetDrawSwipe(showSwipe)
                  self:SetDrawEdge(showEdge)
                end
                -- DON'T set Cooldown alpha - let CDM control it for aura display
                self:SetAlpha(1)
              else
                -- No aura active - show charge recharge swipe
                local ok, chargeDurObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
                if ok and chargeDurObj then
                  -- Push chargeDurObj for recharge swipe
                  parentFrame._arcBypassCDHook = true
                  pcall(function()
                    self:SetCooldownFromDurationObject(chargeDurObj)
                  end)
                  parentFrame._arcBypassCDHook = false
                  
                  -- Enable swipe
                  self:SetDrawSwipe(showSwipe)
                  self:SetDrawEdge(showEdge)
                  
                  -- Use curve to control ALPHA (secret-safe!)
                  -- When recharging: alpha=1 (visible)
                  -- When NOT recharging: alpha=0 (hidden, even during GCD!)
                  local alphaSet = false
                  InitCooldownCurves()
                  if CooldownCurves and CooldownCurves.Binary then
                    local okAlpha, alphaResult = pcall(function()
                      return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
                    end)
                    if okAlpha and alphaResult ~= nil then
                      pcall(function()
                        self:SetAlpha(alphaResult)
                      end)
                      alphaSet = true
                    end
                  end
                  -- Fallback: if curve failed, check charges manually
                  if not alphaSet then
                    local chargeData = C_Spell.GetSpellCharges(spellID)
                    if chargeData and chargeData.currentCharges < chargeData.maxCharges then
                      self:SetAlpha(1)  -- Recharging: show swipe
                    else
                      self:SetAlpha(0)  -- All charges ready: hide swipe
                    end
                  end
                end
              end
            else
              -- NORMAL SPELL: Only hide swipe during GCD
              -- DON'T touch alpha - let ApplyCooldownStateVisuals handle it
              -- Only react to isOnGCD == true, treat false same as nil
              local isOnGCD = nil
              pcall(function()
                local cdInfo = C_Spell.GetSpellCooldown(spellID)
                if cdInfo and cdInfo.isOnGCD == true then isOnGCD = true end
              end)
              
              if isOnGCD then
                -- On GCD only - hide swipe (nothing else!)
                self:SetDrawSwipe(false)
                self:SetDrawEdge(false)
              else
                -- NOT on GCD - show swipe
                self:SetDrawSwipe(showSwipe)
                self:SetDrawEdge(showEdge)
              end
            end
          end
          
          -- Apply custom swipe color if set (only if ArcUI controls cooldowns)
          if not masqueControlsCooldowns and swipe.swipeColor then
            local sc = swipe.swipeColor
            self:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
          end
        else
          -- Normal mode - let CDM handle everything
          -- Just apply user's swipe/edge settings
          self:SetDrawSwipe(swipe.showSwipe ~= false)
          self:SetDrawEdge(swipe.showEdge ~= false)
          self:SetDrawBling(swipe.showBling ~= false)
          self:SetReverse(swipe.reverse == true)
          
          -- Apply custom swipe color if set
          if swipe.swipeColor then
            local sc = swipe.swipeColor
            self:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
          end
          
          -- Clear any forced state from ignoreAuraOverride mode
          -- But preserve noDesaturate's forced 0 value
          if parentFrame._arcForceDesatValue ~= nil and parentFrame._arcForceDesatValue ~= 0 then
            parentFrame._arcForceDesatValue = nil
          end
        end
      end)
    else
      -- Update references in case cdID changed
      frame.Cooldown._arcCdID = cdID
    end
  end
  
  -- Border (pass zoom to properly inset border to match visible icon area)
  UpdateIconBorder(frame, cdID, nil, nil, padding, zoom)
  
  -- Opacity
  frame:SetAlpha(cfg.alpha or 1.0)
  
  -- ═══════════════════════════════════════════════════════════════════
  -- HIDE SHADOW - Hide the CDM shadow/border texture (IconOverlay)
  -- ═══════════════════════════════════════════════════════════════════
  local shouldHideShadow = cfg.hideShadow == true
  
  -- Scan regions to find the IconOverlay texture (only once)
  if not frame._arcIconOverlayScanned then
    frame._arcIconOverlayScanned = true
    
    local regions = {frame:GetRegions()}
    for _, region in ipairs(regions) do
      if region:IsObjectType("Texture") then
        local atlas = region:GetAtlas()
        -- Target the specific CDM IconOverlay atlas
        if atlas and atlas:find("IconOverlay") then
          frame._arcIconOverlay = region
          break
        end
      end
    end
  end
  
  -- Apply shadow visibility
  if frame._arcIconOverlay then
    frame._arcIconOverlay:SetAlpha(shouldHideShadow and 0 or 1)
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- RANGE INDICATOR - Simple enable/disable
  -- When disabled: hide OutOfRange overlay and push white to counteract CDM's red tint
  -- When enabled: let CDM handle everything (don't interfere)
  -- ═══════════════════════════════════════════════════════════════════
  if frame.Icon then
    local rangeCfg = cfg.rangeIndicator
    if rangeCfg then
      -- Store config on the FRAME
      frame._arcRangeCfg = rangeCfg
      
      -- Hook RefreshIconColor to intercept CDM's range coloring when DISABLED
      if not frame._arcRefreshIconColorHooked and frame.RefreshIconColor then
        frame._arcRefreshIconColorHooked = true
        
        hooksecurefunc(frame, "RefreshIconColor", function(self)
          local rCfg = self._arcRangeCfg
          if not rCfg then return end
          
          if rCfg.enabled == false then
            -- Range indicator DISABLED - hide overlay and counteract red tint
            if self.OutOfRange then
              self.OutOfRange:SetShown(false)
            end
            -- Push white if spell IS out of range (to counteract CDM's red)
            if self.spellOutOfRange and self.Icon then
              self.Icon:SetVertexColor(1, 1, 1, 1)
            end
          end
          -- When ENABLED: do nothing, let CDM handle it naturally
        end)
      end
      
      -- Hook OutOfRange:Show to immediately hide when disabled
      if frame.OutOfRange and not frame.OutOfRange._arcHooked then
        frame.OutOfRange._arcHooked = true
        frame.OutOfRange._arcParent = frame
        
        hooksecurefunc(frame.OutOfRange, "Show", function(self)
          local parent = self._arcParent
          if not parent then return end
          
          local rCfg = parent._arcRangeCfg
          if rCfg and rCfg.enabled == false then
            -- Hide the OutOfRange texture
            self:SetShown(false)
            -- Push white to counteract CDM's red tint
            if parent.Icon then
              parent.Icon:SetVertexColor(1, 1, 1, 1)
            end
          end
          -- When ENABLED: do nothing, let CDM show it naturally
        end)
      end
      
      -- Fallback watcher for frames without RefreshIconColor
      if not frame.RefreshIconColor then
        if not frame._arcRangeWatcher then
          frame._arcRangeWatcher = CreateFrame("Frame", nil, frame)
          frame._arcRangeWatcher.parent = frame
          frame._arcRangeWatcher.throttle = 0
          
          frame._arcRangeWatcher:SetScript("OnUpdate", function(self, elapsed)
            self.throttle = self.throttle + elapsed
            if self.throttle < 0.05 then return end  -- 20Hz
            self.throttle = 0
            
            local parent = self.parent
            local rCfg = parent._arcRangeCfg
            if not rCfg then return end
            
            if rCfg.enabled == false then
              if parent.OutOfRange then
                parent.OutOfRange:SetShown(false)
              end
              -- Push white when out of range to counteract CDM's red tint
              if parent.Icon and parent.spellOutOfRange then
                parent.Icon:SetVertexColor(1, 1, 1, 1)
              end
            end
            -- When ENABLED: do nothing, let CDM handle it
          end)
        end
        frame._arcRangeWatcher:Show()
      else
        -- Hide watcher if we're using hooks instead
        if frame._arcRangeWatcher then
          frame._arcRangeWatcher:Hide()
        end
      end
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- PROC GLOW CUSTOMIZATION (CDM RECOLOR APPROACH)
  -- Instead of fighting CDM's glow with our own, we just recolor it.
  -- We listen to SPELL_ACTIVATION_OVERLAY_GLOW_SHOW/HIDE events
  -- and call SetVertexColor on CDM's SpellActivationAlert textures.
  -- NOTE: glowCfg is NOT cached on frame - always get fresh via GetEffectiveIconSettingsForFrame
  -- ═══════════════════════════════════════════════════════════════════
  local glowCfg = cfg.procGlow
  if glowCfg then
    -- Store spellID for reference (this is stable, not a config reference)
    local spellID = nil
    if frame.cooldownInfo then
      spellID = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
    end
    if not spellID and frame.GetSpellID then
      pcall(function() spellID = frame:GetSpellID() end)
    end
    frame._arcSpellID = spellID
    
    -- PRE-WARM: Initialize proc glow frame ahead of time to prevent first-show glitch
    -- Only for "proc" glow type - creates the LCG frame and sets correct initial state
    if glowCfg.enabled ~= false and glowCfg.glowType == "proc" then
      if ns.CDMEnhance.PreWarmProcGlow then
        ns.CDMEnhance.PreWarmProcGlow(frame, glowCfg)
      end
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- REFRESH: Check if proc is currently active (for reload/spec change)
    -- ═══════════════════════════════════════════════════════════════
    if spellID and glowCfg.enabled ~= false then
      local isOverlayed = false
      pcall(function()
        isOverlayed = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed(spellID)
      end)
      
      if isOverlayed then
        -- Proc is active - apply our color to CDM's glow
        ns.CDMEnhance.ShowProcGlow(frame, glowCfg)
      end
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- TEXT OVERLAY FRAME (sits above cooldown swipe)
  -- ═══════════════════════════════════════════════════════════════════
  if not frame._arcTextOverlay then
    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    overlay:EnableMouse(false)  -- CRITICAL: Never intercept mouse - just a container
    frame._arcTextOverlay = overlay
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- CHARGE TEXT
  -- ═══════════════════════════════════════════════════════════════════
  SetupChargeText(frame, cdID, cfg)
  
  -- ═══════════════════════════════════════════════════════════════════
  -- COOLDOWN TEXT STYLING
  -- ═══════════════════════════════════════════════════════════════════
  SetupCooldownText(frame, cdID, cfg)
  
  -- ═══════════════════════════════════════════════════════════════════
  -- PREVIEW TEXT (for editing when no active aura/cooldown)
  -- ═══════════════════════════════════════════════════════════════════
  UpdatePreviewText(frame, cdID, cfg)
  
  -- ═══════════════════════════════════════════════════════════════════
  -- PREVIEW GLOW (for editing glow settings)
  -- ═══════════════════════════════════════════════════════════════════
  UpdatePreviewGlow(frame, cdID, cfg)
  
  -- ═══════════════════════════════════════════════════════════════════
  -- ALERT EVENTS HOOK (for custom actions on CDM events)
  -- ═══════════════════════════════════════════════════════════════════
  if not frame._arcAlertHooked and frame.TriggerAlertEvent then
    frame._arcAlertHooked = true
    frame._arcAlertCdID = cdID
    
    hooksecurefunc(frame, "TriggerAlertEvent", function(self, event)
      local currentCdID = self._arcAlertCdID
      if not currentCdID then return end
      
      local currentCfg = GetIconSettings(currentCdID)
      if not currentCfg then return end
      
      local alertCfg = currentCfg.alertEvents
      local iconTex = self.Icon or self.icon
      -- LibCustomGlow: NEGATIVE offset moves glow INWARD
      local glowOffset = -(currentCfg.padding or 0)
      
      -- Enum.CooldownViewerAlertEventType values:
      -- Available = 1, PandemicTime = 2, OnCooldown = 3, ChargeGained = 4
      local eventType = event
      
      if eventType == 1 then -- Available (Aura applied / Cooldown ready)
        local ev = alertCfg and alertCfg.onAvailable
        if ev then
          -- Play sound
          if ev.playSound then
            PlayAlertSound(ev.soundFile, ev.soundID)
          end
          -- Show glow
          if ev.showGlow and LCG then
            local color = ev.glowColor and {ev.glowColor.r, ev.glowColor.g, ev.glowColor.b, 1} or {0.95, 0.95, 0.32, 1}
            pcall(GetLCG().PixelGlow_Start, self, color, 8, 0.25, nil, 2, glowOffset, glowOffset, true, "ArcUI_Alert", 1)
          end
        end
        -- NOTE: Inactive state (desaturation/hide/dim) is handled by CDMGroups via ApplyIconVisuals
        -- Do NOT duplicate that logic here - it causes conflicts when settings change
        
      elseif eventType == 2 then -- PandemicTime (Aura at 30% remaining)
        local ev = alertCfg and alertCfg.onPandemic
        if ev then
          -- Play sound
          if ev.playSound then
            PlayAlertSound(ev.soundFile, ev.soundID)
          end
          -- Show glow (warning color)
          if ev.showGlow and LCG then
            local color = ev.glowColor and {ev.glowColor.r, ev.glowColor.g, ev.glowColor.b, 1} or {1, 0.5, 0, 1}
            pcall(GetLCG().PixelGlow_Start, self, color, 8, 0.15, nil, 2, glowOffset, glowOffset, true, "ArcUI_Alert", 1)
          end
        end
        
      elseif eventType == 3 then -- OnCooldown (Aura expired / Cooldown used)
        local ev = alertCfg and alertCfg.onUnavailable
        if ev then
          -- Play sound
          if ev.playSound then
            PlayAlertSound(ev.soundFile, ev.soundID)
          end
          -- Stop glow
          if ev.stopGlow and LCG then
            pcall(GetLCG().PixelGlow_Stop, self, "ArcUI_Alert")
          end
        end
        -- NOTE: Inactive state (desaturation/hide/dim) is handled by CDMGroups via ApplyIconVisuals
        -- Do NOT duplicate that logic here - it causes conflicts when settings change
        
      elseif eventType == 4 then -- ChargeGained
        local ev = alertCfg and alertCfg.onChargeGained
        if ev then
          -- Play sound
          if ev.playSound then
            PlayAlertSound(ev.soundFile, ev.soundID)
          end
          -- Show glow
          if ev.showGlow and LCG then
            local color = ev.glowColor and {ev.glowColor.r, ev.glowColor.g, ev.glowColor.b, 1} or {0.95, 0.95, 0.32, 1}
            pcall(GetLCG().PixelGlow_Start, self, color, 8, 0.25, nil, 2, glowOffset, glowOffset, true, "ArcUI_Alert", 1)
            -- Auto-stop after 1 second
            C_Timer.After(1, function()
              if LCG then
                pcall(GetLCG().PixelGlow_Stop, self, "ArcUI_Alert")
              end
            end)
          end
        end
      end
    end)
  else
    -- Update stored cdID in case it changed
    frame._arcAlertCdID = cdID
  end
  
  -- Apply custom label text overlay (separate module)
  if ns.CustomLabel and ns.CustomLabel.Apply then
    ns.CustomLabel.Apply(frame, cfg)
  end
  
  -- Mark frame as styled (used by glow hooks to know when styling is complete)
  frame._arcStyled = true
  
  -- If glow was waiting for styling, refresh it now
  if frame._arcPendingGlowRefresh then
    frame._arcPendingGlowRefresh = nil
    -- Use cfg.procGlow (already fresh from GetEffectiveIconSettingsForFrame)
    local gCfg = cfg.procGlow
    local spellID = frame._arcSpellID
    
    if gCfg and spellID and gCfg.enabled ~= false then
      -- Check current proc state
      local isOverlayed = false
      pcall(function()
        isOverlayed = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed(spellID)
      end)
      
      if isOverlayed then
        ns.CDMEnhance.ShowProcGlow(frame, gCfg)
        -- Hide Blizzard's glow for LCG types
        if gCfg.glowType and gCfg.glowType ~= "default" and frame.SpellActivationAlert then
          frame.SpellActivationAlert:SetAlpha(0)
        end
      end
    end
  end
end

-- ===================================================================
-- CHARGE TEXT SETUP (Stack count for Auras, Charge count for Cooldowns)
-- ===================================================================
function SetupChargeText(frame, cdID, cfg)
  local chargeCfg = cfg.chargeText
  
  -- Find the native charge/stack text
  -- Cooldowns use ChargeCount.Current, Auras use Applications.Applications
  local chargeFrame = frame.ChargeCount or frame.Applications
  local chargeText = nil
  
  if chargeFrame then
    -- Try to find the text element
    -- CDM Cooldowns: ChargeCount.Current
    -- CDM Auras: Applications.Applications
    if chargeFrame.Current then
      chargeText = chargeFrame.Current
    elseif chargeFrame.Applications then
      chargeText = chargeFrame.Applications
    elseif chargeFrame.Text then
      chargeText = chargeFrame.Text
    else
      -- Search regions for FontString
      for _, region in ipairs({chargeFrame:GetRegions()}) do
        if region:IsObjectType("FontString") then
          chargeText = region
          break
        end
      end
    end
    
    -- Cache the reference
    if chargeText then
      frame._arcChargeText = chargeText
      -- Mark this text so cooldown text doesn't accidentally style it
      chargeText._arcIsChargeText = true
    end
  end
  
  -- Use cached reference if we couldn't find it this time
  if not chargeText and frame._arcChargeText then
    chargeText = frame._arcChargeText
  end
  
  if not chargeCfg or chargeCfg.enabled == false then
    -- Hide charge/stack text entirely by hiding the parent frame AND the text directly
    if chargeFrame then
      chargeFrame:Hide()
      chargeFrame:SetAlpha(0)
      
      -- Also hide the text element directly
      if chargeText then
        chargeText:Hide()
        chargeText:SetAlpha(0)
      end
      
      -- Detect if this is an aura frame (Applications) vs cooldown frame (ChargeCount)
      local isAuraFrame = frame.Applications ~= nil
      
      -- Check if spell has charges using CACHED CDM info (safe during combat)
      -- The CDM API info.charges is a boolean that indicates if this cooldown tracks charges
      -- This is already cached in cdmIconCache by ArcUI_Core.lua during scan
      local spellHasCharges = false
      if not isAuraFrame then
        local cdmData = ns.API and ns.API.GetCDMIcon and ns.API.GetCDMIcon(cdID)
        if cdmData then
          -- CDM API info.charges is a boolean indicating if cooldown has charges
          spellHasCharges = cdmData.charges == true
        end
      end
      
      -- CRITICAL FIX: Hook Show() and SetShown() to enforce hidden state
      -- CDM will try to show this frame when updating stack count - we must fight back
      if not chargeFrame._arcChargeHideHooked then
        chargeFrame._arcChargeHideHooked = true
        chargeFrame._arcParentIconFrame = frame
        chargeFrame._arcCdID = cdID
        chargeFrame._arcIsAuraFrame = isAuraFrame
        chargeFrame._arcSpellHasCharges = spellHasCharges  -- From CDM cached info
        chargeFrame._arcChargeText = chargeText  -- Store reference for hooks
        
        -- Helper to fully hide charge text
        local function EnforceChargeHidden(cFrame)
          cFrame:Hide()
          cFrame:SetAlpha(0)
          local cText = cFrame._arcChargeText
          if cText then
            cText:Hide()
            cText:SetAlpha(0)
          end
        end
        
        -- Hook Show()
        hooksecurefunc(chargeFrame, "Show", function(self)
          -- For COOLDOWNS: Skip for non-charge spells - let CDM control
          -- For AURAS: Always enforce hiding (they show application stacks)
          -- Use cached _arcSpellHasCharges (checked once at setup, not during combat)
          if not self._arcIsAuraFrame and not self._arcSpellHasCharges then
            return  -- Non-charge cooldown, let CDM control
          end
          
          -- Re-check settings (user may have re-enabled)
          local currentCdID = self._arcCdID
          if not currentCdID then return end
          
          local currentCfg = GetIconSettings(currentCdID)
          if currentCfg and currentCfg.chargeText and currentCfg.chargeText.enabled == false then
            EnforceChargeHidden(self)
          end
        end)
        
        -- Hook SetShown() if it exists
        if chargeFrame.SetShown then
          hooksecurefunc(chargeFrame, "SetShown", function(self, shown)
            -- Skip if shown is a secret value (can't do boolean test)
            if issecretvalue and issecretvalue(shown) then return end
            
            -- For COOLDOWNS: Skip for non-charge spells - let CDM control
            -- For AURAS: Always enforce hiding
            -- Use cached _arcSpellHasCharges (checked once at setup, not during combat)
            if not self._arcIsAuraFrame and not self._arcSpellHasCharges then
              return  -- Non-charge cooldown, let CDM control
            end
            
            -- Safe to check shown now
            if not shown then return end
            
            local currentCdID = self._arcCdID
            if not currentCdID then return end
            
            local currentCfg = GetIconSettings(currentCdID)
            if currentCfg and currentCfg.chargeText and currentCfg.chargeText.enabled == false then
              EnforceChargeHidden(self)
            end
          end)
        end
        
        -- Hook SetAlpha() - prevent CDM from making text visible even for one frame
        if chargeFrame.SetAlpha then
          hooksecurefunc(chargeFrame, "SetAlpha", function(self, alpha)
            if issecretvalue and issecretvalue(alpha) then return end
            
            -- For COOLDOWNS: Skip for non-charge spells - let CDM control
            -- For AURAS: Always enforce hiding
            -- Use cached _arcSpellHasCharges (checked once at setup, not during combat)
            if not self._arcIsAuraFrame and not self._arcSpellHasCharges then
              return  -- Non-charge cooldown, let CDM control
            end
            
            local currentCdID = self._arcCdID
            if not currentCdID then return end
            
            local currentCfg = GetIconSettings(currentCdID)
            if currentCfg and currentCfg.chargeText and currentCfg.chargeText.enabled == false then
              -- If CDM tries to set alpha > 0, push it back to 0
              if alpha and alpha > 0 then
                EnforceChargeHidden(self)
              end
            end
          end)
        end
      else
        -- Update cdID reference for existing hook
        chargeFrame._arcCdID = cdID
        -- CRITICAL: Update _arcIsAuraFrame on frame reuse! Frame may have been reused
        -- from cooldown to aura or vice versa. Check current frame state.
        local currentIsAura = frame.Applications ~= nil
        chargeFrame._arcIsAuraFrame = currentIsAura
        -- Also update hasCharges cache in case frame is reused for different spell
        -- Use CDM cached info which is safe during combat
        if not currentIsAura then
          local cdmData = ns.API and ns.API.GetCDMIcon and ns.API.GetCDMIcon(cdID)
          if cdmData then
            chargeFrame._arcSpellHasCharges = cdmData.charges == true
          end
        else
          chargeFrame._arcSpellHasCharges = false  -- Auras don't have charges
        end
      end
    end
    return
  end
  
  -- ENABLED PATH: User wants charge text visible
  -- We need to re-show frames that we previously hid
  if chargeFrame then
    chargeFrame:SetAlpha(1)
    
    -- Update cdID reference if hook exists (for frame reuse scenarios)
    if chargeFrame._arcChargeHideHooked then
      chargeFrame._arcCdID = cdID
      -- CRITICAL: Update _arcIsAuraFrame on frame reuse! Frame may have been reused
      -- from cooldown to aura or vice versa. Check current frame state.
      local currentIsAura = frame.Applications ~= nil
      chargeFrame._arcIsAuraFrame = currentIsAura
      -- Mark that user wants charge text enabled - hooks will respect this
      chargeFrame._arcChargeUserEnabled = true
      
      -- Determine if we should call Show()
      -- For AURAS: Always safe to show - CDM will control visibility based on stacks
      -- For COOLDOWNS: Only show if spell has charges (CDM hides ChargeCount for non-charge spells)
      local shouldShow = false
      if currentIsAura then
        shouldShow = true
        chargeFrame._arcSpellHasCharges = false  -- Auras don't have charges
      else
        -- Use CDM cached info to check if spell has charges
        local cdmData = ns.API and ns.API.GetCDMIcon and ns.API.GetCDMIcon(cdID)
        if cdmData and cdmData.charges then
          shouldShow = true
          chargeFrame._arcSpellHasCharges = true  -- Update cache
        end
      end
      
      if shouldShow then
        chargeFrame:Show()
        if chargeText then
          chargeText:SetAlpha(1)
          chargeText:Show()
        end
      else
        -- Non-charge cooldown - just restore alpha, let CDM keep it hidden
        if chargeText then
          chargeText:SetAlpha(1)
        end
      end
    end
    -- If no hook exists, don't modify anything - let CDM control visibility
  end
  
  if chargeText then
    -- Style the native charge text directly
    local fontPath = GetFontPath(chargeCfg.font)
    local fontSize = chargeCfg.size or 16
    local outline = chargeCfg.outline or "OUTLINE"
    SafeSetFont(chargeText, fontPath, fontSize, outline)
    
    -- CRITICAL: Set draw layer to OVERLAY with highest sublevel to appear above glows
    chargeText:SetDrawLayer("OVERLAY", 7)
    
    -- Also ensure parent frame (ChargeCount/Applications) is above glow frames
    local chargeFrame = frame.ChargeCount or frame.Applications
    if chargeFrame and chargeFrame.SetFrameLevel then
      local baseLevel = frame:GetFrameLevel()
      chargeFrame:SetFrameLevel(baseLevel + 50)
    end
    
    -- Color
    local c = chargeCfg.color or {r=1, g=1, b=0, a=1}
    chargeText:SetTextColor(c.r or 1, c.g or 1, c.b or 0, c.a or 1)
    
    -- Shadow
    if chargeCfg.shadow then
      chargeText:SetShadowOffset(chargeCfg.shadowOffsetX or 1, chargeCfg.shadowOffsetY or -1)
      chargeText:SetShadowColor(0, 0, 0, 0.8)
    else
      chargeText:SetShadowOffset(0, 0)
    end
    
    -- Position - reposition the text relative to our frame
    chargeText:ClearAllPoints()
    
    if chargeCfg.mode == "free" then
      local freeX = chargeCfg.freeX or 0
      local freeY = chargeCfg.freeY or 0
      chargeText:SetPoint("CENTER", frame, "CENTER", freeX, freeY)
    else
      local anchor = chargeCfg.anchor or chargeCfg.position or "BOTTOMRIGHT"
      local offX = chargeCfg.offsetX or -2
      local offY = chargeCfg.offsetY or 2
      chargeText:SetPoint(anchor, frame, anchor, offX, offY)
    end
    
    -- Do NOT call Show() - let CDM control visibility (hides at 0/1 stacks)
  end
end

-- ===================================================================
-- COOLDOWN TEXT SETUP (Duration countdown for Auras, CD countdown for Cooldowns)
-- ===================================================================
function SetupCooldownText(frame, cdID, cfg)
  local cdTextCfg = cfg.cooldownText
  if not cdTextCfg then return end
  
  local cooldownFrame = frame.Cooldown or frame.cooldown
  if not cooldownFrame then return end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- HELPER: Find all cooldown text fontstrings
  -- ═══════════════════════════════════════════════════════════════════
  local function FindCooldownTexts()
    local texts = {}
    
    -- Check cooldown frame regions (most common location)
    for _, region in ipairs({cooldownFrame:GetRegions()}) do
      if region:IsObjectType("FontString") and not region._arcIsChargeText then
        table.insert(texts, region)
      end
    end
    
    -- Check cooldown frame children
    for _, child in ipairs({cooldownFrame:GetChildren()}) do
      for _, region in ipairs({child:GetRegions()}) do
        if region:IsObjectType("FontString") and not region._arcIsChargeText then
          table.insert(texts, region)
        end
      end
    end
    
    return texts
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- HELPER: Setup hide hooks on a fontstring (one-time)
  -- ═══════════════════════════════════════════════════════════════════
  local function SetupHideHooks(cdText)
    if not cdText or cdText._arcCdTextHooked then return end
    
    cdText._arcCdTextHooked = true
    cdText._arcParentIconFrame = frame
    cdText._arcCdID = cdID
    
    -- Helper to fully hide the text
    local function EnforceHidden(self)
      self:Hide()
      self:SetAlpha(0)
    end
    
    -- Hook Show()
    hooksecurefunc(cdText, "Show", function(self)
      local currentCdID = self._arcCdID
      if not currentCdID then return end
      
      local currentCfg = GetIconSettings(currentCdID)
      if currentCfg and currentCfg.cooldownText and currentCfg.cooldownText.enabled == false then
        EnforceHidden(self)
      end
    end)
    
    -- Hook SetShown()
    if cdText.SetShown then
      hooksecurefunc(cdText, "SetShown", function(self, shown)
        if issecretvalue and issecretvalue(shown) then return end
        if not shown then return end
        
        local currentCdID = self._arcCdID
        if not currentCdID then return end
        
        local currentCfg = GetIconSettings(currentCdID)
        if currentCfg and currentCfg.cooldownText and currentCfg.cooldownText.enabled == false then
          EnforceHidden(self)
        end
      end)
    end
    
    -- Hook SetAlpha() - prevent CDM from making text visible even for one frame
    if cdText.SetAlpha then
      hooksecurefunc(cdText, "SetAlpha", function(self, alpha)
        if issecretvalue and issecretvalue(alpha) then return end
        
        local currentCdID = self._arcCdID
        if not currentCdID then return end
        
        local currentCfg = GetIconSettings(currentCdID)
        if currentCfg and currentCfg.cooldownText and currentCfg.cooldownText.enabled == false then
          -- If CDM tries to set alpha > 0, push it back to 0
          if alpha and alpha > 0 then
            self:SetAlpha(0)
          end
        end
      end)
    end
    
    -- Hook SetText() - text updates may trigger visibility changes
    if cdText.SetText then
      hooksecurefunc(cdText, "SetText", function(self)
        local currentCdID = self._arcCdID
        if not currentCdID then return end
        
        local currentCfg = GetIconSettings(currentCdID)
        if currentCfg and currentCfg.cooldownText and currentCfg.cooldownText.enabled == false then
          EnforceHidden(self)
        end
      end)
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- HELPER: Style a cooldown text fontstring
  -- ═══════════════════════════════════════════════════════════════════
  local function StyleCooldownText(cdText, textCfg)
    if not cdText then return end
    if cdText._arcIsChargeText then return end
    
    -- Re-show if we previously hid it
    cdText:SetAlpha(1)
    cdText:Show()  -- CRITICAL: Also call Show() since we call Hide() when disabling
    
    local fontPath = GetFontPath(textCfg.font)
    local fontSize = textCfg.size or 14
    local outline = textCfg.outline or "OUTLINE"
    SafeSetFont(cdText, fontPath, fontSize, outline)
    
    cdText:SetDrawLayer("OVERLAY", 7)
    
    local c = textCfg.color or {r=1, g=1, b=1, a=1}
    cdText:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    
    if textCfg.shadow then
      cdText:SetShadowOffset(textCfg.shadowOffsetX or 1, textCfg.shadowOffsetY or -1)
      cdText:SetShadowColor(0, 0, 0, 0.8)
    else
      cdText:SetShadowOffset(0, 0)
    end
    
    cdText:ClearAllPoints()
    if textCfg.mode == "free" then
      local freeX = textCfg.freeX or 0
      local freeY = textCfg.freeY or 0
      cdText:SetPoint("CENTER", frame, "CENTER", freeX, freeY)
    else
      local anchor = textCfg.anchor or "CENTER"
      local offX = textCfg.offsetX or 0
      local offY = textCfg.offsetY or 0
      cdText:SetPoint(anchor, frame, anchor, offX, offY)
    end
    
    cdText._arcIsCooldownText = true
    frame._arcCooldownText = cdText
    
    -- Update cdID reference
    if cdText._arcCdTextHooked then
      cdText._arcCdID = cdID
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- APPLY: Handle disabled state
  -- ═══════════════════════════════════════════════════════════════════
  if cdTextCfg.enabled == false then
    -- Belt: Blizzard API
    cooldownFrame:SetHideCountdownNumbers(true)
    
    -- Suspenders: Find, hide, and hook all countdown fontstrings
    local texts = FindCooldownTexts()
    for _, cdText in ipairs(texts) do
      cdText:Hide()
      cdText:SetAlpha(0)
      SetupHideHooks(cdText)
      cdText._arcCdID = cdID
      frame._arcCooldownText = cdText
      cdText._arcIsCooldownText = true
    end
    
    -- Also handle cached reference
    if frame._arcCooldownText then
      frame._arcCooldownText:Hide()
      frame._arcCooldownText:SetAlpha(0)
      SetupHideHooks(frame._arcCooldownText)
      frame._arcCooldownText._arcCdID = cdID
    end
  else
    -- ═══════════════════════════════════════════════════════════════════
    -- APPLY: Handle enabled state
    -- ═══════════════════════════════════════════════════════════════════
    cooldownFrame:SetHideCountdownNumbers(false)
    
    -- Style existing texts
    if frame._arcCooldownText and frame._arcCooldownText:GetParent() then
      StyleCooldownText(frame._arcCooldownText, cdTextCfg)
    end
    
    for _, cdText in ipairs(FindCooldownTexts()) do
      StyleCooldownText(cdText, cdTextCfg)
      SetupHideHooks(cdText)  -- Setup hooks even when enabled (for dynamic toggling)
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- HOOK: SetCooldown to handle dynamically created text (one-time)
  -- ═══════════════════════════════════════════════════════════════════
  if not cooldownFrame._arcCdTextHooked then
    cooldownFrame._arcCdTextHooked = true
    cooldownFrame._arcParentFrame = frame
    cooldownFrame._arcCdID = cdID
    
    hooksecurefunc(cooldownFrame, "SetCooldown", function(self)
      local parentFrame = self._arcParentFrame
      local currentCdID = self._arcCdID
      if not parentFrame or not currentCdID then return end
      
      local currentCfg = GetIconSettings(currentCdID)
      if not currentCfg or not currentCfg.cooldownText then return end
      
      if currentCfg.cooldownText.enabled == false then
        -- DISABLED: Re-enforce hide
        self:SetHideCountdownNumbers(true)
        
        for _, region in ipairs({self:GetRegions()}) do
          if region:IsObjectType("FontString") and not region._arcIsChargeText then
            region:Hide()
            region:SetAlpha(0)
            SetupHideHooks(region)
            region._arcCdID = currentCdID
          end
        end
        for _, child in ipairs({self:GetChildren()}) do
          for _, region in ipairs({child:GetRegions()}) do
            if region:IsObjectType("FontString") and not region._arcIsChargeText then
              region:Hide()
              region:SetAlpha(0)
              SetupHideHooks(region)
              region._arcCdID = currentCdID
            end
          end
        end
      else
        -- ENABLED: Style text
        for _, region in ipairs({self:GetRegions()}) do
          if region:IsObjectType("FontString") and not region._arcIsChargeText then
            StyleCooldownText(region, currentCfg.cooldownText)
            SetupHideHooks(region)
          end
        end
        for _, child in ipairs({self:GetChildren()}) do
          for _, region in ipairs({child:GetRegions()}) do
            if region:IsObjectType("FontString") and not region._arcIsChargeText then
              StyleCooldownText(region, currentCfg.cooldownText)
              SetupHideHooks(region)
            end
          end
        end
      end
    end)
  else
    -- Update cdID reference for existing hook
    cooldownFrame._arcCdID = cdID
  end
end

-- Export ApplyIconStyle for FrameController to call on frame swaps
-- This applies per-icon visual settings (borders, textures, zoom, etc.) without protection checks
ns.CDMEnhance.ApplyIconStyle = ApplyIconStyle

-- NOTE: Text updates not needed - we style native CDM elements directly
-- The native ChargeCount and Cooldown countdown handle their own display

-- ===================================================================
-- TEXT DRAG OVERLAYS
-- ===================================================================
local function CreateTextDragOverlay(fontString, frame, cdID, textType)
  if fontString._arcDragOverlay then 
    fontString._arcDragOverlay._cdID = cdID
    return fontString._arcDragOverlay 
  end
  
  -- Parent to a high-level frame that sits ABOVE the icon drag overlay
  local overlay = CreateFrame("Frame", nil, frame._arcTextOverlay)
  overlay:SetSize(50, 24)
  overlay:SetPoint("CENTER", fontString, "CENTER", 0, 0)
  -- Set frame level HIGHER than icon drag overlay (which is +50)
  overlay:SetFrameLevel(frame:GetFrameLevel() + 100)
  overlay:SetFrameStrata("DIALOG")
  overlay:EnableMouse(false)
  overlay:RegisterForDrag("LeftButton")
  overlay._cdID = cdID
  overlay._textType = textType
  overlay._fontString = fontString
  overlay._parentFrame = frame
  
  overlay.highlight = overlay:CreateTexture(nil, "OVERLAY")
  overlay.highlight:SetAllPoints()
  overlay.highlight:SetColorTexture(0.9, 0.7, 0.2, 0.5)
  overlay.highlight:Hide()
  
  overlay:SetScript("OnEnter", function(self)
    -- Propagate to grandparent (CDM icon frame) for tooltips
    local parentFrame = self:GetParent()
    if parentFrame then
      local grandparent = parentFrame:GetParent()
      if grandparent and grandparent:GetScript("OnEnter") then
        grandparent:GetScript("OnEnter")(grandparent)
      end
    end
    
    if not textDragMode then return end
    self.highlight:Show()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(textType == "charge" and "Charge Text" or "Cooldown Text", 1, 1, 1)
    GameTooltip:AddLine("Drag to reposition", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Shift+Click to reset", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  
  overlay:SetScript("OnLeave", function(self)
    self.highlight:Hide()
    GameTooltip:Hide()
    
    -- Propagate to grandparent (CDM icon frame) for tooltips
    local parentFrame = self:GetParent()
    if parentFrame then
      local grandparent = parentFrame:GetParent()
      if grandparent and grandparent:GetScript("OnLeave") then
        grandparent:GetScript("OnLeave")(grandparent)
      end
    end
  end)
  
  overlay:SetScript("OnDragStart", function(self)
    if not textDragMode then return end
    self._dragging = true
    
    -- Calculate offset between cursor and text center (so text doesn't jump)
    local scale = UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    
    local textX, textY = self._fontString:GetCenter()
    if textX and textY then
      self._dragOffsetX = textX - cursorX
      self._dragOffsetY = textY - cursorY
    else
      self._dragOffsetX = 0
      self._dragOffsetY = 0
    end
  end)
  
  overlay:SetScript("OnDragStop", function(self)
    if not self._dragging then return end
    self._dragging = false
    
    local currentCdID = self._cdID
    -- BUG FIX: Use GetOrCreateIconSettings to write to actual DB, not GetIconSettings (returns copy)
    local cfg = GetOrCreateIconSettings(currentCdID)
    if not cfg then return end
    
    local parentFrame = self._parentFrame
    local endX, endY = self._fontString:GetCenter()
    local frameX, frameY = parentFrame:GetCenter()
    
    if not endX or not endY or not frameX or not frameY then return end
    
    -- Calculate offset from frame center
    local offsetX = endX - frameX
    local offsetY = endY - frameY
    
    if self._textType == "charge" then
      cfg.chargeText.mode = "free"
      cfg.chargeText.freeX = offsetX
      cfg.chargeText.freeY = offsetY
    else
      cfg.cooldownText.mode = "free"
      cfg.cooldownText.freeX = offsetX
      cfg.cooldownText.freeY = offsetY
    end
    
    -- Invalidate cache to ensure changes are picked up
    InvalidateEffectiveSettingsCache()
    
    ApplyIconStyle(parentFrame, currentCdID)
    
    -- For Arc Auras frames, also force stack text refresh
    if parentFrame._arcConfig or parentFrame._arcAuraID then
      parentFrame._arcStackStyleApplied = false
      -- Immediately re-apply styling
      if ns.ArcAuras and ns.ArcAuras.ApplyStackTextStyle and parentFrame.Count then
        ns.ArcAuras.ApplyStackTextStyle(parentFrame, parentFrame.Count)
        parentFrame._arcStackStyleApplied = true
      end
    end
  end)
  
  overlay:SetScript("OnUpdate", function(self)
    if not self._dragging then 
      -- Keep overlay positioned on fontstring when not dragging
      -- Wrap in pcall to handle secret/tainted values during combat
      if textDragMode and self._fontString then
        pcall(function()
          -- SetAlphaFromBoolean handles secret boolean from IsShown()
          self:SetAlphaFromBoolean(self._fontString:IsShown(), 1, 0)
          self:ClearAllPoints()
          self:SetPoint("CENTER", self._fontString, "CENTER", 0, 0)
        end)
      end
      return 
    end
    
    -- While dragging, position text at cursor + original offset
    local scale = UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    
    -- Add the offset so text stays where you grabbed it
    local targetX = cursorX + (self._dragOffsetX or 0)
    local targetY = cursorY + (self._dragOffsetY or 0)
    
    pcall(function()
      self._fontString:ClearAllPoints()
      self._fontString:SetPoint("CENTER", UIParent, "BOTTOMLEFT", targetX, targetY)
      self:ClearAllPoints()
      self:SetPoint("CENTER", self._fontString, "CENTER", 0, 0)
    end)
  end)
  
  overlay:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and IsShiftKeyDown() and textDragMode then
      local currentCdID = self._cdID
      -- BUG FIX: Use GetOrCreateIconSettings to write to actual DB
      local cfg = GetOrCreateIconSettings(currentCdID)
      local parentFrame = self._parentFrame
      if cfg then
        if self._textType == "charge" then
          cfg.chargeText.mode = "anchor"
          cfg.chargeText.freeX = 0
          cfg.chargeText.freeY = 0
        else
          cfg.cooldownText.mode = "anchor"
          cfg.cooldownText.freeX = 0
          cfg.cooldownText.freeY = 0
        end
        
        -- Invalidate cache to ensure changes are picked up
        InvalidateEffectiveSettingsCache()
        
        ApplyIconStyle(parentFrame, currentCdID)
        
        -- For Arc Auras frames, also force stack text refresh
        if parentFrame._arcConfig or parentFrame._arcAuraID then
          parentFrame._arcStackStyleApplied = false
          -- Immediately re-apply styling
          if ns.ArcAuras and ns.ArcAuras.ApplyStackTextStyle and parentFrame.Count then
            ns.ArcAuras.ApplyStackTextStyle(parentFrame, parentFrame.Count)
            parentFrame._arcStackStyleApplied = true
          end
        end
      end
    end
  end)
  
  fontString._arcDragOverlay = overlay
  return overlay
end

local function UpdateTextDragOverlays(frame)
  -- Check if click-through is enabled
  local clickThroughEnabled = ns.CDMGroups and ns.CDMGroups.ShouldMakeClickThrough and ns.CDMGroups.ShouldMakeClickThrough()
  
  -- Check if frame is CDMGroups managed (container or free icon)
  local parent = frame:GetParent()
  local isCDMGroupsManaged = (parent and parent._isCDMGContainer)
  if not isCDMGroupsManaged and ns.CDMGroups and ns.CDMGroups.freeIcons then
    local cdID = frame.cooldownID
    if cdID and ns.CDMGroups.freeIcons[cdID] then
      isCDMGroupsManaged = true
    end
  end
  
  -- CRITICAL: Ensure _arcTextOverlay never blocks mouse
  if frame._arcTextOverlay then
    frame._arcTextOverlay:EnableMouse(false)
  end
  
  if frame._arcChargeText and frame._arcChargeText._arcDragOverlay then
    local overlay = frame._arcChargeText._arcDragOverlay
    -- Disable if click-through is enabled
    if clickThroughEnabled then
      overlay:EnableMouse(false)
    else
      overlay:EnableMouse(textDragMode)
    end
    -- Ensure high frame level when text drag is active
    if textDragMode and not clickThroughEnabled then
      overlay:SetFrameStrata("DIALOG")
      overlay:SetFrameLevel(frame:GetFrameLevel() + 100)
    else
      overlay.highlight:Hide()
    end
  end
  
  -- Arc Auras Count text drag overlay
  if frame.Count and frame.Count._arcDragOverlay and (frame._arcConfig or frame._arcAuraID) then
    local overlay = frame.Count._arcDragOverlay
    -- Disable if click-through is enabled
    if clickThroughEnabled then
      overlay:EnableMouse(false)
    else
      overlay:EnableMouse(textDragMode)
    end
    -- Ensure high frame level when text drag is active
    if textDragMode and not clickThroughEnabled then
      overlay:SetFrameStrata("DIALOG")
      overlay:SetFrameLevel(frame:GetFrameLevel() + 100)
    else
      overlay.highlight:Hide()
    end
  end
  
  if frame._arcCooldownText and frame._arcCooldownText._arcDragOverlay then
    local overlay = frame._arcCooldownText._arcDragOverlay
    -- Disable if click-through is enabled
    if clickThroughEnabled then
      overlay:EnableMouse(false)
    else
      overlay:EnableMouse(textDragMode)
    end
    if textDragMode and not clickThroughEnabled then
      overlay:SetFrameStrata("DIALOG")
      overlay:SetFrameLevel(frame:GetFrameLevel() + 100)
    else
      overlay.highlight:Hide()
    end
  end
end

-- ===================================================================
-- ICON DRAG OVERLAY
-- ===================================================================
local function CreateDragOverlay(frame, cdID)
  if frame._arcOverlay then 
    frame._arcOverlay._cdID = cdID
    return 
  end
  
  local overlay = CreateFrame("Button", nil, frame)
  overlay:SetAllPoints()
  overlay:SetFrameLevel(frame:GetFrameLevel() + 50)
  overlay:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  -- Default to only unlocked state - options check happens via UpdateOverlayState
  overlay:EnableMouse(isUnlocked)
  overlay:SetMovable(true)
  if isUnlocked then
    overlay:RegisterForDrag("LeftButton")
  end
  overlay._cdID = cdID
  
  -- Green highlight on hover
  overlay.highlight = overlay:CreateTexture(nil, "OVERLAY")
  overlay.highlight:SetAllPoints()
  overlay.highlight:SetColorTexture(0.2, 0.9, 0.2, 0.4)
  overlay.highlight:Hide()
  
  -- "DRAG" text indicator when unlocked
  overlay.dragText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  overlay.dragText:SetPoint("CENTER", 0, 0)
  overlay.dragText:SetText("|cff00ff00DRAG|r")
  overlay.dragText:SetTextColor(0, 1, 0, 1)
  overlay.dragText:Hide()
  
  overlay:SetScript("OnEnter", function(self)
    -- Always propagate OnEnter to parent frame for tooltips
    local parentFrame = self:GetParent()
    if parentFrame and parentFrame:GetScript("OnEnter") then
      parentFrame:GetScript("OnEnter")(parentFrame)
    end
    
    if not isUnlocked then return end
    self.highlight:Show()
    
    local currentCdID = self._cdID
    local data = ns.API and ns.API.GetCDMIcon(currentCdID)
    local name = data and data.name or "Unknown"
    local cfg = GetIconSettings(currentCdID)
    local mode = cfg and cfg.position and cfg.position.mode or "group"
    
    local modeLabels = {
      group = "|cff888888Following Group|r",
      anchored = "|cff00ff00Anchored to Group|r",
      free = "|cffffcc00Free Position|r",
    }
    
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(name, 1, 1, 1)
    GameTooltip:AddLine("Position: " .. (modeLabels[mode] or mode), 1, 1, 1)
    if mode == "group" then
      GameTooltip:AddLine("Change position mode to enable dragging", 0.7, 0.7, 0.7)
    else
      GameTooltip:AddLine("Drag to reposition", 0.7, 0.7, 0.7)
      GameTooltip:AddLine("Shift+Click to reset to group", 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
  end)
  
  overlay:SetScript("OnLeave", function(self)
    self.highlight:Hide()
    GameTooltip:Hide()
    
    -- Always propagate OnLeave to parent frame for tooltips
    local parentFrame = self:GetParent()
    if parentFrame and parentFrame:GetScript("OnLeave") then
      parentFrame:GetScript("OnLeave")(parentFrame)
    end
  end)
  
  -- OnMouseDown - CDMGroups handles all drag operations
  overlay:SetScript("OnMouseDown", function(self, button)
    -- CDMGroups handles all drag operations
    return
  end)
  
  overlay:SetScript("OnMouseUp", function(self, button)
    local currentCdID = self._cdID
    if not currentCdID then return end
    
    -- Left-click selection when options panel is open
    if button == "LeftButton" then
      local optionsPanelOpen = ns.CDMEnhance.IsOptionsPanelOpen and ns.CDMEnhance.IsOptionsPanelOpen()
      if optionsPanelOpen then
        local data = ns.API and ns.API.GetCDMIcon(currentCdID)
        if data then
          local isAura = data.isAura
          if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.SelectIcon then
            ns.CDMEnhanceOptions.SelectIcon(currentCdID, isAura)
          end
        end
      end
    end
  end)
  
  -- Keep OnDragStart/OnDragStop as no-ops
  overlay:SetScript("OnDragStart", function() end)
  overlay:SetScript("OnDragStop", function() end)
  overlay:SetScript("OnClick", function() end)
  
  frame._arcOverlay = overlay
end

-- Backwards compatibility stub
ns.CDMEnhance.DisableCDMSubframeMouse = function(frame) end

local function UpdateOverlayState(frame)
  if frame._arcOverlay then
    -- Check if frame is in a CDMGroups container or is a free icon managed by CDMGroups
    local parent = frame:GetParent()
    local isCDMGroupsManaged = (parent and parent._isCDMGContainer)
    
    -- Also check if it's a CDMGroups free icon
    if not isCDMGroupsManaged and ns.CDMGroups and ns.CDMGroups.freeIcons then
      local cdID = frame.cooldownID
      if cdID and ns.CDMGroups.freeIcons[cdID] then
        isCDMGroupsManaged = true
      end
    end
    
    if isCDMGroupsManaged then
      -- CDMGroups manages ALL mouse for this frame - ALWAYS disable overlay
      frame._arcOverlay:EnableMouse(false)
      frame._arcOverlay:SetMovable(false)
      frame._arcOverlay:RegisterForDrag()
      
      if frame._arcOverlay.highlight then
        frame._arcOverlay.highlight:Hide()
      end
      if frame._arcOverlay.dragText then
        frame._arcOverlay.dragText:Hide()
      end
      UpdateTextDragOverlays(frame)
      return
    end
    
    -- Non-CDMGroups managed frames (legacy path)
    frame._arcOverlay:EnableMouse(true)
    frame._arcOverlay:SetMovable(true)
    
    if isUnlocked then
      frame._arcOverlay:RegisterForDrag("LeftButton")
    else
      frame._arcOverlay:RegisterForDrag()
    end
    frame._arcOverlay:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    if frame._arcOverlay.dragText then
      if isUnlocked then
        frame._arcOverlay.dragText:Show()
      else
        frame._arcOverlay.dragText:Hide()
      end
    end
    
    if not isUnlocked then
      frame._arcOverlay.highlight:Hide()
    end
  end
  
  UpdateTextDragOverlays(frame)
end

-- Export for FrameController - just updates overlay state
ns.CDMEnhance.ApplyFrameMouseState = function(frame, cdID)
  if frame then
    UpdateOverlayState(frame)
  end
end

-- ===================================================================
-- HELPER - Determine if icon is "active" for inactive state handling
-- ===================================================================

-- Helper to determine if an icon is "active" based on its type
-- For auras (buffs): active = buff is applied (auraInstanceID > 0)
-- For cooldowns: We use secret-safe APIs directly in ApplyCooldownStateVisuals
-- ===================================================================
-- GLOW MANAGEMENT for Ready State
-- 
-- LCG's bgUpdate() sets glow alpha to 0.5 or 1.0 every frame.
-- We hook the glow frame's SetAlpha to intercept and override!
-- ===================================================================

-- Hook the glow frame's SetAlpha to allow our override
-- CRITICAL: We must look up the parent DYNAMICALLY because LCG reuses glow frames from a pool!
-- If we capture parentFrame in a closure, the hook will reference the wrong icon when the frame is reused.
local function HookGlowAlpha(glowFrame, parentFrame)
  if glowFrame._arcAlphaHooked then return end
  glowFrame._arcAlphaHooked = true
  
  local originalSetAlpha = glowFrame.SetAlpha
  glowFrame.SetAlpha = function(self, alpha)
    -- CRITICAL: Look up current parent dynamically, not from closure!
    -- LCG reparents glow frames when reusing them from the pool
    local currentParent = self:GetParent()
    if not currentParent then
      originalSetAlpha(self, alpha)
      return
    end
    
    -- Check if current parent has a forced glow alpha
    local forcedAlpha = currentParent._arcForcedGlowAlpha
    if forcedAlpha ~= nil then
      originalSetAlpha(self, forcedAlpha)
    else
      originalSetAlpha(self, alpha)
    end
  end
end

-- Ensure glow exists and is hooked
local function EnsureGlowHooked(frame, glowSettings)
  if not frame then return nil end
  
  local lcg = GetLCG()
  if not lcg then return nil end
  
  -- Extract settings - handle both direct settings and stateVisuals structure
  local glowType = "button"
  local r, g, b = 1, 0.85, 0.1
  local intensity = 1.0
  local scale = 1.0
  local speed = 0.25
  local lines = 8
  local thickness = 2
  local particles = 4
  local xOffset = 0
  local yOffset = 0
  
  if type(glowSettings) == "table" then
    -- Handle stateVisuals structure (readyGlowType, readyGlowColor, etc.)
    if glowSettings.readyGlowType then
      glowType = glowSettings.readyGlowType
    elseif glowSettings.glowType then
      glowType = glowSettings.glowType
    end
    
    -- Color
    local colorSrc = glowSettings.readyGlowColor or glowSettings.glowColor
    if colorSrc then
      r = colorSrc.r or colorSrc[1] or 1
      g = colorSrc.g or colorSrc[2] or 0.85
      b = colorSrc.b or colorSrc[3] or 0.1
    elseif glowSettings.r then
      r = glowSettings.r or 1
      g = glowSettings.g or 0.85
      b = glowSettings.b or 0.1
    end
    
    -- Other settings
    intensity = glowSettings.readyGlowIntensity or glowSettings.glowIntensity or 1.0
    scale = glowSettings.readyGlowScale or glowSettings.glowScale or 1.0
    speed = glowSettings.readyGlowSpeed or glowSettings.glowSpeed or 0.25
    lines = glowSettings.readyGlowLines or glowSettings.glowLines or 8
    thickness = glowSettings.readyGlowThickness or glowSettings.glowThickness or 2
    particles = glowSettings.readyGlowParticles or glowSettings.glowParticles or 4
    xOffset = glowSettings.readyGlowXOffset or glowSettings.glowXOffset or 0
    yOffset = glowSettings.readyGlowYOffset or glowSettings.glowYOffset or 0
  end
  
  -- Create settings signature to detect ANY setting change
  local settingSig = string.format("%s_%.2f_%.2f_%.2f_%.2f_%.2f_%.2f_%d_%d_%d_%d_%d",
    glowType, r, g, b, intensity, scale, speed, lines, thickness, particles, xOffset, yOffset)
  
  -- Get existing glow frame for this type
  local existingGlow
  if glowType == "pixel" then
    existingGlow = frame["_PixelGlowArcUI_ReadyGlow"]
  elseif glowType == "autocast" then
    existingGlow = frame["_AutoCastGlowArcUI_ReadyGlow"]
  elseif glowType == "proc" then
    existingGlow = frame["_ProcGlowArcUI_ReadyGlow"]
  else
    -- ButtonGlow - but don't use it if proc OR proc preview owns it
    local procOwnsButtonGlow = frame._arcProcGlowActive and frame._arcProcGlowType == "button"
    local procPreviewOwnsButtonGlow = frame._arcProcPreviewActive and frame._arcProcPreviewType == "button"
    if not (procOwnsButtonGlow or procPreviewOwnsButtonGlow) then
      existingGlow = frame._ButtonGlow
    end
  end
  
  -- SIMPLE LOGIC: If same signature AND glow frame exists, reuse it (don't restart)
  -- This prevents alpha reset when curve is controlling visibility
  -- DON'T set alpha here - let the caller (SetGlowAlpha) control it
  if frame._arcCurrentGlowSig == settingSig and existingGlow then
    return existingGlow
  end
  
  -- If proc OR proc preview owns ButtonGlow and ready state wants button, skip entirely
  local procOwnsButtonGlow = frame._arcProcGlowActive and frame._arcProcGlowType == "button"
  local procPreviewOwnsButtonGlow = frame._arcProcPreviewActive and frame._arcProcPreviewType == "button"
  if glowType == "button" and (procOwnsButtonGlow or procPreviewOwnsButtonGlow) then
    -- Clear signature so we don't falsely match later
    frame._arcCurrentGlowSig = nil
    return nil
  end
  
  -- Need to create/restart glow - stop ALL existing glows on THIS frame first
  StopAllGlows(frame, "ArcUI_ReadyGlow")
  
  -- Update tracking state
  frame._arcCurrentGlowType = glowType
  frame._arcCurrentGlowSig = settingSig
  
  -- Calculate offset based on padding + user offset
  -- Negative offset = inward (shrink glow), Positive = outward (expand glow)
  local padding = 0
  local cdID = frame.cooldownID
  if cdID then
    local iconCfg = GetIconSettings(cdID)
    if iconCfg then padding = iconCfg.padding or 0 end
  end
  local baseOffset = -padding  -- Start with padding compensation
  local finalXOffset = baseOffset + xOffset
  local finalYOffset = baseOffset + yOffset
  
  local color = {r, g, b, intensity}
  
  -- Helper to set glow frame level ABOVE Cooldown swipe (+15) but below text overlay (+50) and stacks (+50)
  -- Also hooks SetFrameLevel to prevent LCG from overriding our level
  local function SetGlowFrameLevel(glowFrame)
    if glowFrame and glowFrame.SetFrameLevel then
      local baseLevel = frame:GetFrameLevel()
      local targetLevel = baseLevel + 15  -- Above Cooldown swipe, below text/stacks
      glowFrame:SetFrameLevel(targetLevel)
      
      -- Hook SetFrameLevel to enforce our level (LCG animations might try to change it)
      if not glowFrame._arcFrameLevelHooked then
        glowFrame._arcFrameLevelHooked = true
        glowFrame._arcTargetFrameLevel = targetLevel
        local origSetFrameLevel = glowFrame.SetFrameLevel
        glowFrame.SetFrameLevel = function(self, level)
          -- Always use our target level instead
          origSetFrameLevel(self, self._arcTargetFrameLevel or level)
        end
      else
        -- Update target level if already hooked
        glowFrame._arcTargetFrameLevel = targetLevel
      end
    end
  end
  
  -- Start appropriate glow type
  if glowType == "pixel" then
    pcall(GetLCG().PixelGlow_Start, frame, color, lines, speed, nil, thickness, finalXOffset, finalYOffset, true, "ArcUI_ReadyGlow")
    local glowFrame = frame["_PixelGlowArcUI_ReadyGlow"]
    if glowFrame then
      SetGlowFrameLevel(glowFrame)
      -- Apply scale manually (LCG doesn't have scale parameter for pixel glow)
      if scale ~= 1.0 and glowFrame.SetScale then
        pcall(glowFrame.SetScale, glowFrame, scale)
      end
      if not glowFrame._arcAlphaHooked then
        HookGlowAlpha(glowFrame, frame)
      end
    end
    return glowFrame
  elseif glowType == "autocast" then
    pcall(GetLCG().AutoCastGlow_Start, frame, color, particles, speed, scale, finalXOffset, finalYOffset, "ArcUI_ReadyGlow")
    local glowFrame = frame["_AutoCastGlowArcUI_ReadyGlow"]
    if glowFrame then
      SetGlowFrameLevel(glowFrame)
      if not glowFrame._arcAlphaHooked then
        HookGlowAlpha(glowFrame, frame)
      end
    end
    return glowFrame
  elseif glowType == "proc" then
    pcall(GetLCG().ProcGlow_Start, frame, {
      color = color,
      startAnim = false,
      xOffset = finalXOffset,
      yOffset = finalYOffset,
      key = "ArcUI_ReadyGlow"
    })
    local glowFrame = frame["_ProcGlowArcUI_ReadyGlow"]
    if glowFrame then
      SetGlowFrameLevel(glowFrame)
      -- Apply scale manually
      if scale ~= 1.0 and glowFrame.SetScale then
        pcall(glowFrame.SetScale, glowFrame, scale)
      end
      -- Fix initial state - force correct visibility immediately
      if glowFrame.ProcStart then
        glowFrame.ProcStart:Hide()
      end
      if glowFrame.ProcLoop then
        glowFrame.ProcLoop:Show()
        glowFrame.ProcLoop:SetAlpha(intensity)
      end
      if not glowFrame._arcAlphaHooked then
        HookGlowAlpha(glowFrame, frame)
      end
    end
    return glowFrame
  else -- button (default)
    -- ButtonGlow doesn't support keys - skip if proc is using it
    if frame._arcProcGlowActive and frame._arcProcGlowType == "button" then
      -- Proc owns ButtonGlow, ready state can't use it - return nil
      return nil
    end
    pcall(GetLCG().ButtonGlow_Start, frame, color, speed)
    if frame._ButtonGlow then
      SetGlowFrameLevel(frame._ButtonGlow)
      -- Apply scale manually (LCG doesn't have scale parameter for button glow)
      if scale ~= 1.0 and frame._ButtonGlow.SetScale then
        pcall(frame._ButtonGlow.SetScale, frame._ButtonGlow, scale)
      end
      if not frame._ButtonGlow._arcAlphaHooked then
        HookGlowAlpha(frame._ButtonGlow, frame)
      end
    end
    return frame._ButtonGlow
  end
end

-- Set glow alpha (secret-safe via our hook!)
local function SetGlowAlpha(frame, alpha, glowSettings)
  if not frame then return end
  
  -- Ensure glow exists and is hooked
  local glowFrame = EnsureGlowHooked(frame, glowSettings)
  if glowFrame then
    -- Set our forced alpha - the hook will use this
    frame._arcForcedGlowAlpha = alpha
    -- Trigger the hook by calling SetAlpha
    glowFrame:SetAlpha(alpha)
  end
end

-- Forward declaration for HideReadyGlow (used in ShowReadyGlow)
local HideReadyGlow

-- Helper: Check if glow should be shown (considers combat-only setting and preview mode)
local function ShouldShowReadyGlow(stateVisuals, frame)
  -- Check if glow preview is active for this icon (overrides all other conditions)
  if frame and frame.cooldownID then
    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsGlowPreviewActive then
      if ns.CDMEnhanceOptions.IsGlowPreviewActive(frame.cooldownID) then
        return true  -- Preview active = always show glow
      end
    end
  end
  
  -- STRICT CHECK: readyGlow must be explicitly boolean true, not just truthy
  -- This prevents old/corrupted saved variables from accidentally enabling glows
  if not stateVisuals or stateVisuals.readyGlow ~= true then
    return false
  end
  
  -- Check combat-only mode
  if stateVisuals.readyGlowCombatOnly then
    local inCombat = InCombatLockdown() or UnitAffectingCombat("player")
    if not inCombat then
      return false
    end
  end
  
  return true
end

-- Show glow (sets forced alpha to 1)
local function ShowReadyGlow(frame, glowSettings)
  if not frame then return end
  
  local glowFrame = EnsureGlowHooked(frame, glowSettings)
  if glowFrame then
    frame._arcForcedGlowAlpha = 1
    glowFrame:SetAlpha(1)
  end
  frame._arcReadyGlowActive = true
  
  -- CRITICAL: Enforce pandemic hiding after glow changes
  -- LCG frame pool operations can sometimes trigger CDM to re-evaluate frames
  if frame.PandemicIcon and not frame._arcShowPandemic then
    frame.PandemicIcon:Hide()
    frame.PandemicIcon:SetAlpha(0)
    if frame.PandemicIcon.Border then
      frame.PandemicIcon.Border:Hide()
    end
    if frame.PandemicIcon.FX then
      frame.PandemicIcon.FX:Hide()
    end
  end
end

-- Hide glow (stops all glow types)
HideReadyGlow = function(frame)
  if not frame then return end
  
  -- Stop all possible glow types using proper API
  -- This respects proc glow ownership for ButtonGlow
  StopAllGlows(frame, "ArcUI_ReadyGlow")
  
  -- Reset forced alpha
  frame._arcForcedGlowAlpha = 0
  frame._arcReadyGlowActive = false
  
  -- Explicitly hide ButtonGlow if it exists AND neither proc NOR proc preview is using it
  -- ButtonGlow_Stop plays a fade animation, but we want immediate hide for ready state
  local procUsingButtonGlow = frame._arcProcGlowActive and frame._arcProcGlowType == "button"
  local procPreviewUsingButtonGlow = frame._arcProcPreviewActive and frame._arcProcPreviewType == "button"
  if frame._ButtonGlow and not procUsingButtonGlow and not procPreviewUsingButtonGlow then
    frame._ButtonGlow:SetAlpha(0)
    frame._ButtonGlow:Hide()
  end
  
  -- Explicitly hide keyed glow frames (these are safe - they have keys)
  -- Hide pixel glow frame
  local pixelGlow = frame["_PixelGlowArcUI_ReadyGlow"]
  if pixelGlow then
    pixelGlow:SetAlpha(0)
    pixelGlow:Hide()
  end
  
  -- Hide autocast glow frame
  local autocastGlow = frame["_AutoCastGlowArcUI_ReadyGlow"]
  if autocastGlow then
    autocastGlow:SetAlpha(0)
    autocastGlow:Hide()
  end
  
  -- Hide proc glow frame (LCG ProcGlow type, not spell procs)
  local procGlow = frame["_ProcGlowArcUI_ReadyGlow"]
  if procGlow then
    procGlow:SetAlpha(0)
    procGlow:Hide()
  end
  
  -- CRITICAL: Enforce pandemic hiding after glow changes
  -- LCG frame pool operations can sometimes trigger CDM to re-evaluate frames
  if frame.PandemicIcon and not frame._arcShowPandemic then
    frame.PandemicIcon:Hide()
    frame.PandemicIcon:SetAlpha(0)
    if frame.PandemicIcon.Border then
      frame.PandemicIcon.Border:Hide()
      frame.PandemicIcon.Border:SetAlpha(0)
    end
    if frame.PandemicIcon.FX then
      frame.PandemicIcon.FX:Hide()
      frame.PandemicIcon.FX:SetAlpha(0)
    end
  end
  
  frame._arcReadyGlowActive = false
  frame._arcCurrentGlowType = nil
  frame._arcCurrentGlowSig = nil  -- Clear signature for clean state on next start
end

-- ===================================================================
-- Get effective state visuals
-- ===================================================================
GetEffectiveStateVisuals = function(cfg)
  if not cfg then return nil end
  
  -- Use the two-state system (cooldownStateVisuals)
  local csv = cfg.cooldownStateVisuals
  if csv then
    local rs = csv.readyState or {}
    local cs = csv.cooldownState or {}
    
    -- Check if any setting is non-default
    -- STRICT: glow must be explicitly boolean true
    local hasReadySettings = rs.alpha and rs.alpha ~= 1.0 or rs.glow == true
    -- Note: noDesaturate explicitly blocks CDM's default desaturation
    local hasCooldownSettings = (cs.alpha and cs.alpha ~= 1.0) or cs.desaturate == true or cs.tint == true or cs.noDesaturate == true or cs.preserveDurationText == true or cs.waitForNoCharges == true
    
    if hasReadySettings or hasCooldownSettings then
      return {
        readyAlpha = rs.alpha or 1.0,
        readyGlow = rs.glow == true,  -- STRICT: Only true if explicitly boolean true
        readyGlowColor = rs.glowColor,
        readyGlowType = rs.glowType or "button",
        readyGlowIntensity = rs.glowIntensity or 1.0,
        readyGlowScale = rs.glowScale or 1.0,
        readyGlowSpeed = rs.glowSpeed or 0.25,
        readyGlowLines = rs.glowLines or 8,
        readyGlowThickness = rs.glowThickness or 2,
        readyGlowParticles = rs.glowParticles or 4,
        readyGlowXOffset = rs.glowXOffset or 0,
        readyGlowYOffset = rs.glowYOffset or 0,
        readyGlowCombatOnly = rs.glowCombatOnly == true,  -- STRICT boolean
        glowThreshold = rs.glowThreshold or 1.0,
        glowAuraType = rs.glowAuraType or "auto",
        glowWhileChargesAvailable = rs.glowWhileChargesAvailable == true,  -- STRICT boolean
        cooldownAlpha = cs.alpha or 1.0,
        cooldownDesaturate = cs.desaturate == true,  -- STRICT boolean
        cooldownTint = cs.tint == true,  -- STRICT boolean
        cooldownTintColor = cs.tintColor,
        noDesaturate = cs.noDesaturate == true,  -- STRICT boolean
        preserveDurationText = cs.preserveDurationText == true,  -- STRICT boolean
        waitForNoCharges = cs.waitForNoCharges == true,  -- STRICT boolean
      }
    end
  end
  
  return nil  -- No state visuals configured
end

-- Helper to get effective ready alpha (handles options panel preview when alpha is 0)
local function GetEffectiveReadyAlpha(stateVisuals)
  local readyAlpha = stateVisuals.readyAlpha
  if readyAlpha <= 0 then
    if ns.CDMEnhance.IsOptionsPanelOpen and ns.CDMEnhance.IsOptionsPanelOpen() then
      return 0.35  -- Options panel preview
    end
  end
  return readyAlpha
end

-- Export for CooldownState module
ns.CDMEnhance.GetEffectiveReadyAlpha = GetEffectiveReadyAlpha

-- ===================================================================
-- APPLY COOLDOWN STATE VISUALS (new two-state system)
-- ===================================================================
-- stateVisuals parameter is optional - if passed, skips redundant GetEffectiveStateVisuals call
ApplyCooldownStateVisuals = function(frame, cfg, normalAlpha, stateVisuals)
  if not frame then return end
  
  -- Arc Auras handles its own cooldown state visuals
  -- It reads CDMEnhance settings via GetEffectiveIconSettings and applies them
  -- We just need to avoid double-handling which causes visual flickering
  if frame._arcConfig or frame._arcAuraID then
    return
  end
  
  local iconTex = frame.Icon or frame.icon
  if not iconTex then return end
  
  -- For bar-style icons, frame.Icon is a Frame container with Icon child texture
  -- Get the actual texture that has SetDesaturated method
  local actualTex = iconTex
  if not iconTex.SetDesaturated and iconTex.Icon then
    actualTex = iconTex.Icon
  end
  -- Use actualTex for all desaturation calls
  iconTex = actualTex
  
  -- Get effective state visuals (handles legacy migration)
  -- Skip if already passed from caller (performance optimization for 20Hz hot path)
  if not stateVisuals then
    stateVisuals = GetEffectiveStateVisuals(cfg)
  end
  
  -- Check if glow preview is active for this icon
  local cdID = frame.cooldownID
  local isGlowPreview = cdID and ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsGlowPreviewActive and
                        ns.CDMEnhanceOptions.IsGlowPreviewActive(cdID)
  
  -- If NO state visuals configured AND no preview active AND not ignoreAuraOverride, let CDM handle everything
  -- CRITICAL: When ignoreAuraOverride is active, we MUST continue to apply cooldown logic even without state visuals
  if not stateVisuals and not isGlowPreview and not frame._arcIgnoreAuraOverride then
    -- No custom settings - let CDM handle alpha, desaturation, everything
    -- Just clear any forced desat value we may have set previously
    frame._arcForceDesatValue = nil
    frame._arcReadyForGlow = false  -- Track for glow handler
    HideReadyGlow(frame)
    
    -- CRITICAL FIX: Explicitly reset desaturation to colored when disabling desat setting
    -- CDM doesn't always push a desat=0 value, so icons can stay grayscale
    if iconTex then
      if iconTex.SetDesaturation then
        iconTex:SetDesaturation(0)
      elseif iconTex.SetDesaturated then
        iconTex:SetDesaturated(false)
      end
      -- Also reset vertex color (tint)
      iconTex:SetVertexColor(1, 1, 1)
    end
    -- Reset border desaturation
    ApplyBorderDesaturation(frame, 0)
    
    return
  end
  
  -- If preview is active but no stateVisuals, create default ones for glow display
  -- IMPORTANT: Only set readyGlow = true for actual preview mode, not for ignoreAuraOverride
  if not stateVisuals then
    local rs = cfg.cooldownStateVisuals and cfg.cooldownStateVisuals.readyState or {}
    stateVisuals = {
      readyAlpha = 1.0,
      readyGlow = isGlowPreview and true or (rs.glow == true),  -- Only force glow for preview, otherwise respect setting
      readyGlowType = rs.glowType or "button",
      readyGlowColor = rs.glowColor,
      readyGlowIntensity = rs.glowIntensity or 1.0,
      readyGlowScale = rs.glowScale or 1.0,
      readyGlowSpeed = rs.glowSpeed or 0.25,
      readyGlowLines = rs.glowLines or 8,
      readyGlowThickness = rs.glowThickness or 2,
      readyGlowParticles = rs.glowParticles or 4,
      readyGlowXOffset = rs.glowXOffset or 0,
      readyGlowYOffset = rs.glowYOffset or 0,
      cooldownAlpha = 1.0,
    }
  end
  
  -- If preview mode, show glow immediately and return
  if isGlowPreview then
    ShowReadyGlow(frame, stateVisuals)
    return
  end
  
  -- Ensure curves are initialized
  InitCooldownCurves()
  
  -- Determine detection method based on CDM category
  -- Use cached values from GetEffectiveIconSettings to avoid duplicate API call
  local useAuraLogic = cfg._isAura or false
  -- cdID already declared above
  -- Prefer live overrideSpellID (cfg._spellID goes stale when CDM swaps override spell)
  local spellID = cfg._spellID
  if frame.cooldownInfo then
    local liveSpell = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
    if liveSpell then spellID = liveSpell end
  end
  
  -- UNIFIED DETECTION: Check if frame is showing active aura/buff/totem duration
  -- auraInstanceID > 0 = buff/debuff is active
  -- totemData ~= nil = totem is active (totemData only exists when totem is up)
  -- Both use aura logic for consistent "ready state" handling
  local hasAuraID = (frame.auraInstanceID and type(frame.auraInstanceID) == "number" and frame.auraInstanceID > 0)
                    or (frame.totemData ~= nil)
  
  if hasAuraID then
    -- Frame is showing an active aura/buff/totem duration
    -- Use aura logic regardless of CDM category (handles cooldown frames showing debuff/totem durations)
    useAuraLogic = true
  end
  
  -- CRITICAL: If ignoreAuraOverride is enabled, use cooldown logic even for auras
  -- Read fresh from config to ensure we have the latest value (frame flag may be stale)
  local ignoreAuraOverride = (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
                          or (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)
  frame._arcIgnoreAuraOverride = ignoreAuraOverride or false  -- Update frame flag
  
  -- ═══════════════════════════════════════════════════════════════════
  -- IGNORE AURA OVERRIDE - Complete separate handling
  -- This mode shows spell cooldown state instead of aura duration
  -- Handles: alpha, desaturation, glow, border - then returns
  -- ═══════════════════════════════════════════════════════════════════
  if ignoreAuraOverride then
    -- Get spellID if not already set
    if not spellID and frame.cooldownInfo then
      spellID = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
    end
    
    if not spellID then
      -- No spell to track - hide and return
      frame._arcReadyForGlow = false
      HideReadyGlow(frame)
      return
    end
    
    -- Get cooldown state
    local isOnGCD, durationObj, isChargeSpell, chargeDurObj = GetSpellCooldownState(spellID)
    
    -- Ensure curves are initialized
    InitCooldownCurves()
    
    -- For ignoreAuraOverride:
    -- - Alpha uses chargeDurObj for charge spells (tracks recharge)
    -- - Desat uses durationObj for charge spells (tracks "any charge on CD")
    local effectiveDurObj = isChargeSpell and chargeDurObj or durationObj
    local desatDurObj = isChargeSpell and durationObj or durationObj
    
    frame:Show()
    
    -- NOTE: noGCDSwipe only controls swipe visibility (handled by SetCooldown hook)
    -- Desaturation/alpha/glow ALWAYS filter GCD - GCD shouldn't affect icon appearance
    
    -- GCD FILTER for NORMAL SPELLS: Show as ready during GCD
    -- Desaturation always filters GCD, swipe respects noGCDSwipe setting
    if not isChargeSpell and isOnGCD then
      -- Set alpha/desat to ready state (GCD shouldn't dim/gray the icon)
      frame._arcTargetAlpha = nil
      -- Enable ready alpha enforcement if custom alpha is set
      local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
      if effectiveReadyAlpha < 1.0 then
        frame._arcEnforceReadyAlpha = true
        frame._arcReadyAlphaValue = effectiveReadyAlpha
      else
        frame._arcEnforceReadyAlpha = false
      end
      frame._arcBypassFrameAlphaHook = true
      frame:SetAlpha(effectiveReadyAlpha)
      frame._arcBypassFrameAlphaHook = false
      
      frame._arcBypassDesatHook = true
      frame._arcForceDesatValue = 0
      if iconTex.SetDesaturation then
        iconTex:SetDesaturation(0)
      else
        iconTex:SetDesaturated(false)
      end
      frame._arcBypassDesatHook = false
      
      ApplyBorderDesaturation(frame, 0)
      
      if ShouldShowReadyGlow(stateVisuals, frame) then
        ShowReadyGlow(frame, stateVisuals)
      else
        HideReadyGlow(frame)
      end
      return
    end
    
    -- ALPHA: Use curve on effectiveDurObj with user's alpha settings
    -- Disable ready alpha enforcement - curve handles alpha transitions
    frame._arcEnforceReadyAlpha = false
    local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
    local alphaCurve = GetTwoStateAlphaCurve(effectiveReadyAlpha, stateVisuals.cooldownAlpha)
    if alphaCurve and effectiveDurObj then
      local okA, alphaResult = pcall(function()
        return effectiveDurObj:EvaluateRemainingPercent(alphaCurve)
      end)
      if okA and alphaResult ~= nil then
        -- Store target alpha so hook can enforce it against CDM overrides
        frame._arcTargetAlpha = alphaResult
        frame._arcBypassFrameAlphaHook = true
        frame:SetAlpha(alphaResult)
        frame._arcBypassFrameAlphaHook = false
        
        -- For charge spells: DON'T set Cooldown alpha (SetCooldown hook handles it)
        if frame.Cooldown and not isChargeSpell then
          if stateVisuals.preserveDurationText then
            frame.Cooldown:SetAlpha(1)
          else
            frame.Cooldown:SetAlpha(alphaResult)
          end
        end
      end
    end
    
    -- DESATURATION: Apply curve unless noDesaturate is set
    if stateVisuals.noDesaturate then
      -- Force colored (no desaturation)
      frame._arcForceDesatValue = 0
      frame._arcBypassDesatHook = true
      if iconTex.SetDesaturation then
        iconTex:SetDesaturation(0)
      else
        iconTex:SetDesaturated(false)
      end
      frame._arcBypassDesatHook = false
      ApplyBorderDesaturation(frame, 0)
    elseif desatDurObj and CooldownCurves.Binary then
      -- For charge spells: ALWAYS filter GCD from desatDurObj (which is durationObj)
      -- GCD shouldn't gray out the icon - only real cooldown should
      if isChargeSpell and isOnGCD then
        -- During GCD - show as colored (ready)
        -- MUST set to 0 to enforce colored state against CDM's SetDesaturation calls
        frame._arcForceDesatValue = 0
        frame._arcBypassDesatHook = true
        if iconTex.SetDesaturation then
          iconTex:SetDesaturation(0)
        end
        frame._arcBypassDesatHook = false
        ApplyBorderDesaturation(frame, 0)
      else
        -- Apply curve
        local okD, desatResult = pcall(function()
          return desatDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
        end)
        if okD and desatResult ~= nil then
          frame._arcForceDesatValue = nil
          frame._arcBypassDesatHook = true
          if iconTex.SetDesaturation then
            iconTex:SetDesaturation(desatResult)
          end
          frame._arcBypassDesatHook = false
          ApplyBorderDesaturationFromDuration(frame, desatDurObj)
        end
      end
    else
      -- No desatDurObj - clear forced value
      frame._arcForceDesatValue = nil
    end
    
    -- GLOW: Same logic as normal cooldowns
    if ShouldShowReadyGlow(stateVisuals, frame) then
      local isPreview = ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsGlowPreviewActive and
                        frame.cooldownID and ns.CDMEnhanceOptions.IsGlowPreviewActive(frame.cooldownID)
      if isPreview then
        ShowReadyGlow(frame, stateVisuals)
      elseif effectiveDurObj and CooldownCurves.BinaryInv then
        -- For charge spells with glowWhileChargesAvailable: use durationObj
        local glowDurObj = effectiveDurObj
        if isChargeSpell and stateVisuals.glowWhileChargesAvailable then
          glowDurObj = durationObj
          -- ALWAYS filter GCD for durationObj - glow should stay on during GCD
          if isOnGCD then
            SetGlowAlpha(frame, 1.0, stateVisuals)
          elseif glowDurObj then
            local okG, glowAlpha = pcall(function()
              return glowDurObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
            end)
            if okG and glowAlpha ~= nil then
              SetGlowAlpha(frame, glowAlpha, stateVisuals)
            end
          end
        else
          -- Default: use effectiveDurObj (chargeDurObj for charge spells)
          local okG, glowAlpha = pcall(function()
            return glowDurObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
          end)
          if okG and glowAlpha ~= nil then
            SetGlowAlpha(frame, glowAlpha, stateVisuals)
          end
        end
      else
        HideReadyGlow(frame)
      end
    else
      HideReadyGlow(frame)
    end
    
    return  -- ignoreAuraOverride handled completely - don't fall through
  end
  -- ═══════════════════════════════════════════════════════════════════
  -- END IGNORE AURA OVERRIDE
  -- ═══════════════════════════════════════════════════════════════════
  
  if not spellID and frame.cooldownInfo then
    spellID = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- AURA LOGIC (category 2/3) - auraInstanceID or totemData
  -- Handles buffs, debuffs, and totem durations with unified "ready state" logic
  -- ═══════════════════════════════════════════════════════════════════
  if useAuraLogic then
    local auraID = frame.auraInstanceID
    -- isReady = buff/debuff active (auraID > 0) OR totem active (totemData exists)
    local isReady = (auraID and type(auraID) == "number" and auraID > 0) or (frame.totemData ~= nil)
    
    -- OPTIMIZATION: Skip alpha calculation if hooks are managing it
    -- OptimizedApplyIconVisuals sets _arcTargetAlpha on aura events
    if frame._arcTargetAlpha == nil then
      -- Calculate target alpha based on state
      local targetAlpha
      if isReady then
        local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
        targetAlpha = effectiveReadyAlpha
        -- Enable ready alpha enforcement if custom alpha is set
        if effectiveReadyAlpha < 1.0 then
          frame._arcEnforceReadyAlpha = true
          frame._arcReadyAlphaValue = effectiveReadyAlpha
        else
          frame._arcEnforceReadyAlpha = false
        end
      else
        -- Disable ready alpha enforcement for inactive state
        frame._arcEnforceReadyAlpha = false
        local cdAlpha = stateVisuals.cooldownAlpha
        if cdAlpha <= 0 then
          if ns.CDMEnhance.IsOptionsPanelOpen and ns.CDMEnhance.IsOptionsPanelOpen() then
            targetAlpha = 0.35  -- Options panel preview
          else
            targetAlpha = 0  -- Hidden via alpha
          end
        else
          targetAlpha = cdAlpha
        end
      end
      
      frame._arcTargetAlpha = targetAlpha
      frame._arcBypassFrameAlphaHook = true
      frame:SetAlpha(targetAlpha)
      if frame.Cooldown then frame.Cooldown:SetAlpha(targetAlpha) end
      frame._arcBypassFrameAlphaHook = false
      
      -- Ensure frame is shown (alpha 0 handles invisibility)
      if not frame:IsShown() then
        frame:Show()
      end
    end
    
    -- OPTIMIZATION: Skip desat if hooks are managing it
    if frame._arcTargetDesat == nil then
      if isReady then
        -- Ready state desaturation
        frame._arcBypassDesatHook = true
        if iconTex.SetDesaturation then
          iconTex:SetDesaturation(0)
        else
          iconTex:SetDesaturated(false)
        end
        frame._arcBypassDesatHook = false
        frame._arcTargetDesat = 0
        ApplyBorderDesaturation(frame, 0)
      else
        -- Cooldown state desaturation
        frame._arcBypassDesatHook = true
        local targetDesat = stateVisuals.cooldownDesaturate and 1 or 0
        if targetDesat == 1 then
          if iconTex.SetDesaturation then
            iconTex:SetDesaturation(1)
          else
            iconTex:SetDesaturated(true)
          end
          ApplyBorderDesaturation(frame, 1)
        else
          if iconTex.SetDesaturation then
            iconTex:SetDesaturation(0)
          else
            iconTex:SetDesaturated(false)
          end
          ApplyBorderDesaturation(frame, 0)
        end
        frame._arcBypassDesatHook = false
        frame._arcTargetDesat = targetDesat
      end
    end
    
    -- OPTIMIZATION: Skip tint if hooks are managing it
    if frame._arcTargetTint == nil then
      local targetTintR, targetTintG, targetTintB = 1, 1, 1
      if not isReady and stateVisuals.cooldownTint and stateVisuals.cooldownTintColor then
        local col = stateVisuals.cooldownTintColor
        targetTintR = col.r or 0.5
        targetTintG = col.g or 0.5
        targetTintB = col.b or 0.5
      end
      frame._arcTargetTint = string.format("%.2f,%.2f,%.2f", targetTintR, targetTintG, targetTintB)
      iconTex:SetVertexColor(targetTintR, targetTintG, targetTintB)
    end
    
    -- OPTIMIZATION: Skip glow if hooks are managing it
    if frame._arcTargetGlow == nil then
      if ShouldShowReadyGlow(stateVisuals, frame) and isReady then
        local threshold = stateVisuals.glowThreshold or 1.0
        
        if threshold < 1.0 and auraID then
          -- Threshold enabled: use curve to control glow visibility
          local auraType = stateVisuals.glowAuraType or "auto"
          local unit = "player"
          if auraType == "debuff" then
            unit = "target"
          elseif auraType == "auto" then
            local cat = frame.category
            if cat == 3 then unit = "target" end
          end
          
          local durationObj = C_UnitAuras and C_UnitAuras.GetAuraDuration and C_UnitAuras.GetAuraDuration(unit, auraID)
          if durationObj then
            local thresholdCurve = GetGlowThresholdCurve(threshold)
            if thresholdCurve then
              local okG, glowAlpha = pcall(function()
                return durationObj:EvaluateRemainingPercent(thresholdCurve)
              end)
              if okG and glowAlpha ~= nil then
                SetGlowAlpha(frame, glowAlpha, stateVisuals)
              else
                ShowReadyGlow(frame, stateVisuals)
              end
            else
              ShowReadyGlow(frame, stateVisuals)
            end
          else
            ShowReadyGlow(frame, stateVisuals)
          end
        else
          ShowReadyGlow(frame, stateVisuals)
        end
      else
        HideReadyGlow(frame)
      end
      frame._arcTargetGlow = true
    end
    return
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- COOLDOWN LOGIC (category 0/1) - uses curves for secret-safe handling
  -- ═══════════════════════════════════════════════════════════════════
  
  -- ═══════════════════════════════════════════════════════════════════
  -- IGNORE AURA OVERRIDE: Now handled by normal cooldown logic below
  -- The SetCooldown hook handles swipe/animation override (pushing spell CD)
  -- Alpha/desat/glow use the same curve logic as any other cooldown
  -- useAuraLogic was already set to false above (line ~5501)
  -- ═══════════════════════════════════════════════════════════════════
  -- (Old duplicated auraActive block removed - falls through to normal cooldown curves)
  
  if not spellID then
    -- No spell ID, assume ready
    -- Reset preserveDurationText state
    if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
      if not frame._arcSwipeWaitForNoCharges then frame._arcCooldownText:SetIgnoreParentAlpha(false) end
    end
    if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
      if not frame._arcSwipeWaitForNoCharges then frame._arcChargeText:SetIgnoreParentAlpha(false) end
    end
    
    -- CRITICAL FIX: Clear _arcTargetAlpha and use bypass flag
    frame._arcTargetAlpha = nil
    -- Enable ready alpha enforcement if custom alpha is set
    local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
    if effectiveReadyAlpha < 1.0 then
      frame._arcEnforceReadyAlpha = true
      frame._arcReadyAlphaValue = effectiveReadyAlpha
    else
      frame._arcEnforceReadyAlpha = false
    end
    frame._arcBypassFrameAlphaHook = true
    frame:SetAlpha(effectiveReadyAlpha)
    frame._arcBypassFrameAlphaHook = false
    frame:Show()
    frame._arcBypassDesatHook = true
    frame._arcForceDesatValue = nil
    if iconTex.SetDesaturation then
      iconTex:SetDesaturation(0)
    else
      iconTex:SetDesaturated(false)
    end
    frame._arcBypassDesatHook = false
    if ShouldShowReadyGlow(stateVisuals, frame) then
      ShowReadyGlow(frame, stateVisuals)
    else
      HideReadyGlow(frame)
    end
    return
  end
  
  -- Get cooldown state (now includes charge spell detection)
  local isOnGCD, durationObj, isChargeSpell, chargeDurObj = GetSpellCooldownState(spellID)
  
  -- For CHARGE SPELLS: Use chargeDurObj for alpha/glow curves
  -- This properly tracks recharge state even when charges are available
  local effectiveDurObj = isChargeSpell and chargeDurObj or durationObj
  
  -- For DESAT: Use same effectiveDurObj (charge spells use chargeDurObj)
  local desatDurObj = effectiveDurObj
  
  -- Ensure curves are initialized
  InitCooldownCurves()
  
  -- GCD Filter for NORMAL SPELLS: if ONLY on GCD, treat as ready
  -- For CHARGE SPELLS: GCD is already filtered by using chargeDurObj
  -- EXCEPTION: If glowWhileChargesAvailable is ON, we need GCD filter for charge spells too
  if not isChargeSpell and isOnGCD then
    -- Reset preserveDurationText state
    if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
      if not frame._arcSwipeWaitForNoCharges then frame._arcCooldownText:SetIgnoreParentAlpha(false) end
    end
    if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
      if not frame._arcSwipeWaitForNoCharges then frame._arcChargeText:SetIgnoreParentAlpha(false) end
    end
    
    -- CRITICAL FIX: Clear _arcTargetAlpha and use bypass flag
    frame._arcTargetAlpha = nil
    -- Enable ready alpha enforcement if custom alpha is set
    local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
    if effectiveReadyAlpha < 1.0 then
      frame._arcEnforceReadyAlpha = true
      frame._arcReadyAlphaValue = effectiveReadyAlpha
    else
      frame._arcEnforceReadyAlpha = false
    end
    frame._arcBypassFrameAlphaHook = true
    frame:SetAlpha(effectiveReadyAlpha)
    frame._arcBypassFrameAlphaHook = false
    frame:Show()
    frame._arcBypassDesatHook = true
    frame._arcForceDesatValue = nil
    if iconTex.SetDesaturation then
      iconTex:SetDesaturation(0)
    else
      iconTex:SetDesaturated(false)
    end
    frame._arcBypassDesatHook = false
    
    -- DON'T use Clear() - it causes flicker loop with CDM!
    -- Instead, just hide the swipe visually
    if frame.Cooldown then
      -- Only hide swipe if noGCDSwipe is enabled
      if frame._arcNoGCDSwipeEnabled then
        frame._arcBypassSwipeHook = true
        frame.Cooldown:SetDrawSwipe(false)
        frame.Cooldown:SetDrawEdge(false)
        frame._arcBypassSwipeHook = false
      end
    end
    
    if ShouldShowReadyGlow(stateVisuals, frame) then
      ShowReadyGlow(frame, stateVisuals)
    else
      HideReadyGlow(frame)
    end
    
    -- BORDER: Ready state - sync to non-desaturated
    ApplyBorderDesaturation(frame, 0)
    return
  end
  
  -- GCD Filter for CHARGE SPELLS with glowWhileChargesAvailable:
  -- When this toggle is ON, we use cooldownDuration for glow which needs GCD filtering
  if isChargeSpell and isOnGCD and stateVisuals.glowWhileChargesAvailable then
    -- Reset preserveDurationText state
    if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
      if not frame._arcSwipeWaitForNoCharges then frame._arcCooldownText:SetIgnoreParentAlpha(false) end
    end
    if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
      if not frame._arcSwipeWaitForNoCharges then frame._arcChargeText:SetIgnoreParentAlpha(false) end
    end
    
    -- CRITICAL FIX: Clear _arcTargetAlpha and use bypass flag
    frame._arcTargetAlpha = nil
    -- Enable ready alpha enforcement if custom alpha is set
    local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
    if effectiveReadyAlpha < 1.0 then
      frame._arcEnforceReadyAlpha = true
      frame._arcReadyAlphaValue = effectiveReadyAlpha
    else
      frame._arcEnforceReadyAlpha = false
    end
    frame._arcBypassFrameAlphaHook = true
    frame:SetAlpha(effectiveReadyAlpha)
    frame._arcBypassFrameAlphaHook = false
    frame:Show()
    frame._arcBypassDesatHook = true
    frame._arcForceDesatValue = nil
    if iconTex.SetDesaturation then
      iconTex:SetDesaturation(0)
    else
      iconTex:SetDesaturated(false)
    end
    frame._arcBypassDesatHook = false
    
    -- Show glow during GCD if enabled (ready state)
    if ShouldShowReadyGlow(stateVisuals, frame) then
      ShowReadyGlow(frame, stateVisuals)
    else
      HideReadyGlow(frame)
    end
    
    -- BORDER: GCD/ready state - sync to non-desaturated
    ApplyBorderDesaturation(frame, 0)
    return
  end
  
  -- Apply using curves
  frame:Show()
  
  -- waitForNoCharges: Apply on-CD visual when 0 charges left (for charge spells)
  -- METHOD 2: Use isOnGCD from tracked spell + cooldownDuration curve
  -- 
  -- Key insight: isOnGCD from C_Spell.GetSpellCooldown(spellID) is NeverSecret
  -- When isOnGCD=true → FREEZE (show ready state to hide phantom CD)
  -- When isOnGCD=false → Apply curve to cooldownDuration (shows actual cooldown state)
  --
  -- This naturally filters phantom CDs because:
  -- - During phantom CD: isOnGCD is still true → we FREEZE
  -- - After GCD ends: cooldownDuration shows real state (ready or actual CD)
  if isChargeSpell and stateVisuals.waitForNoCharges then
    -- Check isOnGCD from the TRACKED SPELL (NeverSecret!)
    if isOnGCD then
      -- FREEZE during GCD - show as ready (don't dim)
      -- This hides the phantom CD that would otherwise cause flicker
      -- CRITICAL FIX: Clear _arcTargetAlpha and use bypass flag
      frame._arcTargetAlpha = nil
      -- Enable ready alpha enforcement if custom alpha is set
      local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
      if effectiveReadyAlpha < 1.0 then
        frame._arcEnforceReadyAlpha = true
        frame._arcReadyAlphaValue = effectiveReadyAlpha
      else
        frame._arcEnforceReadyAlpha = false
      end
      frame._arcBypassFrameAlphaHook = true
      frame:SetAlpha(effectiveReadyAlpha)
      frame._arcBypassFrameAlphaHook = false
      
      -- Reset preserveDurationText state during GCD
      if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
        if not frame._arcSwipeWaitForNoCharges then frame._arcCooldownText:SetIgnoreParentAlpha(false) end
      end
      if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
        if not frame._arcSwipeWaitForNoCharges then frame._arcChargeText:SetIgnoreParentAlpha(false) end
      end
      
      -- Clear desat during GCD
      frame._arcBypassDesatHook = true
      frame._arcForceDesatValue = nil
      if iconTex.SetDesaturation then
        iconTex:SetDesaturation(0)
      else
        iconTex:SetDesaturated(false)
      end
      frame._arcBypassDesatHook = false
      -- Sync border to non-desaturated
      ApplyBorderDesaturation(frame, 0)
      
      -- GLOW during GCD: Respect glowWhileChargesAvailable setting
      -- - glowWhileChargesAvailable OFF: Only glow when ALL charges ready (chargeDurObj = 0%)
      -- - glowWhileChargesAvailable ON: Glow while ANY charge available (always during GCD since we're in waitForNoCharges)
      if ShouldShowReadyGlow(stateVisuals, frame) then
        if stateVisuals.glowWhileChargesAvailable then
          -- Glow while any charge available - show glow during GCD
          ShowReadyGlow(frame, stateVisuals)
        elseif chargeDurObj then
          -- Only glow when ALL charges ready - use curve
          InitCooldownCurves()
          if CooldownCurves and CooldownCurves.BinaryInv then
            local okG, glowAlpha = pcall(function()
              return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
            end)
            if okG and glowAlpha ~= nil then
              SetGlowAlpha(frame, glowAlpha, stateVisuals)
            end
          end
        else
          HideReadyGlow(frame)
        end
      else
        HideReadyGlow(frame)
      end
    else
      -- isOnGCD is false - apply curve to cooldownDuration!
      -- durationObj comes from C_Spell.GetSpellCooldownDuration(spellID)
      -- This properly reflects: ready (0%) or actual cooldown (>0%)
      -- Disable ready alpha enforcement - curve handles alpha transitions
      frame._arcEnforceReadyAlpha = false
      local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
      local alphaCurve = GetTwoStateAlphaCurve(effectiveReadyAlpha, stateVisuals.cooldownAlpha)
      
      if alphaCurve and durationObj then
        local okA, alphaResult = pcall(function()
          return durationObj:EvaluateRemainingPercent(alphaCurve)
        end)
        if okA and alphaResult ~= nil then
          -- Store target alpha so hook can enforce it against CDM overrides
          frame._arcTargetAlpha = alphaResult
          frame._arcBypassFrameAlphaHook = true
          -- SetAlpha accepts secret values! Only set on parent frame
          frame:SetAlpha(alphaResult)
          frame._arcBypassFrameAlphaHook = false
          
          -- BORDER: Sync border color based on cooldown state (secret-safe)
          ApplyBorderDesaturationFromDuration(frame, durationObj)
          
          -- preserveDurationText: Make text elements ignore parent alpha when dimmed
          if stateVisuals.preserveDurationText then
            if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
              frame._arcCooldownText:SetIgnoreParentAlpha(true)
              frame._arcCooldownText:SetAlpha(1)
            end
            if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
              frame._arcChargeText:SetIgnoreParentAlpha(true)
              frame._arcChargeText:SetAlpha(1)
            end
            if frame.Cooldown and frame.Cooldown.Text and frame.Cooldown.Text.SetIgnoreParentAlpha then
              frame.Cooldown.Text:SetIgnoreParentAlpha(true)
              frame.Cooldown.Text:SetAlpha(1)
            end
          else
            if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
              if not frame._arcSwipeWaitForNoCharges then frame._arcCooldownText:SetIgnoreParentAlpha(false) end
            end
            if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
              if not frame._arcSwipeWaitForNoCharges then frame._arcChargeText:SetIgnoreParentAlpha(false) end
            end
            if frame.Cooldown and frame.Cooldown.Text and frame.Cooldown.Text.SetIgnoreParentAlpha then
              if not frame._arcSwipeWaitForNoCharges then frame.Cooldown.Text:SetIgnoreParentAlpha(false) end
            end
          end
        end
      end
      
      -- DESATURATION for waitForNoCharges - also use cooldownDuration
      -- CRITICAL FIX: Don't store curve result - let curve drive the transition
      if stateVisuals.cooldownDesaturate and CooldownCurves.Binary and durationObj then
        frame._arcForceDesatValue = nil
        local okD, desatResult = pcall(function()
          return durationObj:EvaluateRemainingPercent(CooldownCurves.Binary)
        end)
        if okD and desatResult ~= nil then
          frame._arcBypassDesatHook = true
          if iconTex.SetDesaturation then
            iconTex:SetDesaturation(desatResult)
          end
          frame._arcBypassDesatHook = false
          -- Sync border using curve-based color (secret-safe)
          ApplyBorderDesaturationFromDuration(frame, durationObj)
        end
      elseif stateVisuals.noDesaturate then
        frame._arcForceDesatValue = 0
        frame._arcBypassDesatHook = true
        if iconTex.SetDesaturation then
          iconTex:SetDesaturation(0)
        else
          iconTex:SetDesaturated(false)
        end
        frame._arcBypassDesatHook = false
        -- Sync border to non-desaturated
        ApplyBorderDesaturation(frame, 0)
      else
        frame._arcForceDesatValue = nil
      end
      
      -- NOTE: Color tint is now handled purely via OutOfRange hooks
      -- When CDM shows OutOfRange (red tint), our hooks push white to counteract
      -- No constant tint application needed here
      
      -- GLOW: For waitForNoCharges, decide which duration to use:
      -- Default: Use chargeDurObj - glow only when ALL charges ready
      -- With glowWhileChargesAvailable: Use durationObj - glow while any charge available
      if ShouldShowReadyGlow(stateVisuals, frame) then
        -- Check if preview mode is forcing glow
        local isPreview = ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsGlowPreviewActive and
                          frame.cooldownID and ns.CDMEnhanceOptions.IsGlowPreviewActive(frame.cooldownID)
        if isPreview then
          -- Preview mode: show glow at full alpha regardless of state
          ShowReadyGlow(frame, stateVisuals)
        elseif CooldownCurves.BinaryInv then
          if stateVisuals.glowWhileChargesAvailable then
            -- glowWhileChargesAvailable ON: Use durationObj (GetSpellCooldownDuration)
            -- Shows glow while ANY charge is available (durationObj = 0%)
            -- Hides glow when ALL charges consumed (durationObj > 0%)
            -- BUT: GCD shows in durationObj as >0%, need to filter it out
            if isOnGCD then
              -- During GCD - keep glow at full (GCD is not a real cooldown)
              SetGlowAlpha(frame, 1.0, stateVisuals)
            elseif durationObj then
              -- Not on GCD - use curve on durationObj
              local okG, glowAlpha = pcall(function()
                return durationObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
              end)
              if okG and glowAlpha ~= nil then
                SetGlowAlpha(frame, glowAlpha, stateVisuals)
              end
            end
          else
            -- glowWhileChargesAvailable OFF (default): Use chargeDurObj
            -- Shows glow only when ALL charges ready (chargeDurObj = 0%)
            -- Hides glow when recharging (chargeDurObj > 0%)
            -- chargeDurObj doesn't include GCD, so no filtering needed
            if chargeDurObj then
              local okG, glowAlpha = pcall(function()
                return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
              end)
              if okG and glowAlpha ~= nil then
                SetGlowAlpha(frame, glowAlpha, stateVisuals)
              end
            end
          end
        end
      else
        HideReadyGlow(frame)
      end
    end
    
    -- Let SetCooldown hook handle animation, swipe, edge, duration text, charge text
    -- We only handle alpha/desat/glow here
    return
  elseif effectiveDurObj and CooldownCurves.initialized then
    -- ═══════════════════════════════════════════════════════════════════
    -- ALPHA: Use custom curve for ready→cooldown alpha transition
    -- ApplyCooldownStateVisuals handles ALL alpha/desat, SetCooldown hook only handles swipe display
    -- Disable ready alpha enforcement - curve handles alpha transitions
    -- ═══════════════════════════════════════════════════════════════════
    frame._arcEnforceReadyAlpha = false
    local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
    local alphaCurve = GetTwoStateAlphaCurve(effectiveReadyAlpha, stateVisuals.cooldownAlpha)
    if alphaCurve then
      local okA, alphaResult = pcall(function()
        return effectiveDurObj:EvaluateRemainingPercent(alphaCurve)
      end)
      if okA and alphaResult ~= nil then
        -- Store target alpha so hook can enforce it against CDM overrides
        frame._arcTargetAlpha = alphaResult
        frame._arcBypassFrameAlphaHook = true
        -- Apply alpha to PARENT frame
        frame:SetAlpha(alphaResult)
        frame._arcBypassFrameAlphaHook = false
        
        -- For charge spells with noGCDSwipe: DON'T set Cooldown frame alpha!
        -- The SetCooldown hook controls Cooldown alpha for swipe visibility
        -- For normal spells or when noGCDSwipe is off: set Cooldown alpha
        local skipCooldownAlpha = isChargeSpell and frame._arcNoGCDSwipeEnabled
        local preserveText = stateVisuals.preserveDurationText
        if frame.Cooldown and not skipCooldownAlpha then
          if preserveText then
            frame.Cooldown:SetAlpha(1)  -- Keep Cooldown at full alpha for text
          else
            frame.Cooldown:SetAlpha(alphaResult)
          end
        end
        
        -- preserveDurationText: Make text elements ignore parent alpha
        if preserveText then
          -- Use SetIgnoreParentAlpha so text stays visible when frame is dimmed
          if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
            frame._arcCooldownText:SetIgnoreParentAlpha(true)
            frame._arcCooldownText:SetAlpha(1)
          end
          if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
            frame._arcChargeText:SetIgnoreParentAlpha(true)
            frame._arcChargeText:SetAlpha(1)
          end
          if frame.Cooldown and frame.Cooldown.Text and frame.Cooldown.Text.SetIgnoreParentAlpha then
            frame.Cooldown.Text:SetIgnoreParentAlpha(true)
            frame.Cooldown.Text:SetAlpha(1)
          end
        else
          -- Reset: text follows parent alpha again
          if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
            if not frame._arcSwipeWaitForNoCharges then frame._arcCooldownText:SetIgnoreParentAlpha(false) end
          end
          if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
            if not frame._arcSwipeWaitForNoCharges then frame._arcChargeText:SetIgnoreParentAlpha(false) end
          end
          if frame.Cooldown and frame.Cooldown.Text and frame.Cooldown.Text.SetIgnoreParentAlpha then
            if not frame._arcSwipeWaitForNoCharges then frame.Cooldown.Text:SetIgnoreParentAlpha(false) end
          end
        end
      end
    end
    
    -- DESATURATION handling
    -- - cooldownDesaturate=true → apply desaturation via curve
    -- - noDesaturate=true → block CDM's default desat, force to 0
    -- - neither → let CDM handle it (don't touch)
    if stateVisuals.cooldownDesaturate and CooldownCurves.Binary then
      local okD, desatResult = pcall(function()
        return desatDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
      end)
      if okD and desatResult ~= nil then
        frame._arcForceDesatValue = nil
        frame._arcBypassDesatHook = true
        if iconTex.SetDesaturation then
          iconTex:SetDesaturation(desatResult)
        end
        frame._arcBypassDesatHook = false
        -- Sync border
        ApplyBorderDesaturationFromDuration(frame, desatDurObj)
      end
    elseif stateVisuals.noDesaturate then
      -- Explicitly block CDM's default desaturation
      frame._arcForceDesatValue = 0
      frame._arcBypassDesatHook = true
      if iconTex.SetDesaturation then
        iconTex:SetDesaturation(0)
      else
        iconTex:SetDesaturated(false)
      end
      frame._arcBypassDesatHook = false
      -- Sync border to non-desaturated (matching icon)
      ApplyBorderDesaturation(frame, 0)
    else
      -- Let CDM handle desaturation (clear our forced value)
      frame._arcForceDesatValue = nil
    end
    
    -- NOTE: Color tint is now handled purely via OutOfRange hooks
    -- When CDM shows OutOfRange (red tint), our hooks push white to counteract
    -- No constant tint application needed here
    
    -- BORDER: Sync border color based on cooldown state (when followDesaturation enabled)
    -- Skip if noDesaturate already synced the border to non-desaturated
    if not stateVisuals.noDesaturate then
      ApplyBorderDesaturationFromDuration(frame, effectiveDurObj)
    end
    
    -- GLOW: Use curve-based alpha (secret-safe!)
    -- BinaryInv: returns 1 when ready (0% remaining), 0 when on CD
    -- For charge spells: default uses chargeDurObj (all charges ready)
    -- With glowWhileChargesAvailable: use durationObj (any charge available)
    if ShouldShowReadyGlow(stateVisuals, frame) then
      -- Check if preview mode is forcing glow
      local isPreview = ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsGlowPreviewActive and
                        frame.cooldownID and ns.CDMEnhanceOptions.IsGlowPreviewActive(frame.cooldownID)
      if isPreview then
        -- Preview mode: show glow at full alpha regardless of state
        ShowReadyGlow(frame, stateVisuals)
      elseif CooldownCurves.BinaryInv then
        -- Handle charge spell glow based on glowWhileChargesAvailable setting
        if isChargeSpell then
          if stateVisuals.glowWhileChargesAvailable then
            -- glowWhileChargesAvailable ON: Use durationObj (GetSpellCooldownDuration)
            -- Shows glow while ANY charge is available (durationObj = 0%)
            -- Hides glow when ALL charges consumed (durationObj > 0%)
            -- durationObj includes GCD, need to filter it out
            if isOnGCD then
              -- During GCD - keep glow at full (GCD is not a real cooldown)
              SetGlowAlpha(frame, 1.0, stateVisuals)
            elseif durationObj then
              -- Not on GCD - use curve on durationObj
              local okG, glowAlpha = pcall(function()
                return durationObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
              end)
              if okG and glowAlpha ~= nil then
                SetGlowAlpha(frame, glowAlpha, stateVisuals)
              end
            end
          else
            -- glowWhileChargesAvailable OFF (default): Use chargeDurObj (GetSpellChargeDuration)
            -- Shows glow only when ALL charges ready (chargeDurObj = 0%)
            -- Hides glow when recharging (chargeDurObj > 0%)
            -- chargeDurObj doesn't include GCD, so no filtering needed
            if chargeDurObj then
              local okG, glowAlpha = pcall(function()
                return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
              end)
              if okG and glowAlpha ~= nil then
                SetGlowAlpha(frame, glowAlpha, stateVisuals)
              end
            end
          end
        else
          -- Normal spell (not charge): use effectiveDurObj
          if effectiveDurObj then
            local okG, glowAlpha = pcall(function()
              return effectiveDurObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
            end)
            if okG and glowAlpha ~= nil then
              SetGlowAlpha(frame, glowAlpha, stateVisuals)
            end
          end
        end
      end
    else
      HideReadyGlow(frame)
    end
    
    return
  end
  
  -- No data, assume ready
  -- Reset preserveDurationText state
  if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
    if not frame._arcSwipeWaitForNoCharges then frame._arcCooldownText:SetIgnoreParentAlpha(false) end
  end
  if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
    if not frame._arcSwipeWaitForNoCharges then frame._arcChargeText:SetIgnoreParentAlpha(false) end
  end
  
  -- Apply ready state visuals
  -- CRITICAL FIX: Clear _arcTargetAlpha and use bypass flag so hook doesn't re-apply old value
  frame._arcTargetAlpha = nil
  -- Enable ready alpha enforcement if custom alpha is set
  local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
  if effectiveReadyAlpha < 1.0 then
    frame._arcEnforceReadyAlpha = true
    frame._arcReadyAlphaValue = effectiveReadyAlpha
  else
    frame._arcEnforceReadyAlpha = false
  end
  frame._arcBypassFrameAlphaHook = true
  frame:SetAlpha(effectiveReadyAlpha)
  frame._arcBypassFrameAlphaHook = false
  
  -- Clear desaturation
  frame._arcForceDesatValue = nil
  frame._arcBypassDesatHook = true
  if iconTex.SetDesaturation then
    iconTex:SetDesaturation(0)
  else
    iconTex:SetDesaturated(false)
  end
  frame._arcBypassDesatHook = false
  
  if ShouldShowReadyGlow(stateVisuals, frame) then
    ShowReadyGlow(frame, stateVisuals)
  else
    HideReadyGlow(frame)
  end
  
  -- BORDER: Ready state - sync to non-desaturated
  ApplyBorderDesaturation(frame, 0)
end

-- Export state visual functions
ns.CDMEnhance.ApplyCooldownStateVisuals = ApplyCooldownStateVisuals
ns.CDMEnhance.GetEffectiveStateVisuals = GetEffectiveStateVisuals
ns.CDMEnhance.ShowReadyGlow = ShowReadyGlow
ns.CDMEnhance.HideReadyGlow = HideReadyGlow
ns.CDMEnhance.SetGlowAlpha = SetGlowAlpha
ns.CDMEnhance.EnsureGlowHooked = EnsureGlowHooked
ns.CDMEnhance.ShouldShowReadyGlow = ShouldShowReadyGlow

-- RELAY: Make the local a dynamic lookup through ns.CDMEnhance
-- When ArcUI_CooldownState.lua loads, it overwrites ns.CDMEnhance.ApplyCooldownStateVisuals
-- with the refactored version. This relay ensures all 8+ internal call sites in this file
-- automatically route to the new implementation without individual changes.
ApplyCooldownStateVisuals = function(frame, cfg, normalAlpha, stateVisuals)
  local result = ns.CDMEnhance.ApplyCooldownStateVisuals(frame, cfg, normalAlpha, stateVisuals)
  -- Update custom label visibility on cooldown state change
  if ns.CustomLabel and ns.CustomLabel.UpdateVisibility then
    ns.CustomLabel.UpdateVisibility(frame)
  end
  return result
end

-- Export font helper functions (for Arc Auras stack text styling)
ns.CDMEnhance.GetFontPath = GetFontPath
ns.CDMEnhance.SafeSetFont = SafeSetFont

-- Show proc glow preview for an icon
function ns.CDMEnhance.ShowProcGlowPreview(cdID)
  local data = enhancedFrames[cdID]
  if not data or not data.frame then return end
  
  local frame = data.frame
  local cfg = GetIconSettings(cdID)
  local glowCfg = cfg and cfg.procGlow
  
  local glowType = glowCfg and glowCfg.glowType or "default"
  local color = glowCfg and glowCfg.color
  local r, g, b = color and color.r or 1, color and color.g or 0.85, color and color.b or 0.1
  local alpha = glowCfg and glowCfg.alpha or 1.0
  local scale = glowCfg and glowCfg.scale or 1.0
  local speed = glowCfg and glowCfg.speed or 0.25
  local lines = glowCfg and glowCfg.lines or 8
  local thickness = glowCfg and glowCfg.thickness or 2
  local particles = glowCfg and glowCfg.particles or 4
  local xOffset = -(cfg and cfg.padding or 0)
  local yOffset = xOffset
  
  local colorTbl = {r, g, b, alpha}
  
  -- Stop any existing preview glow
  StopAllGlows(frame, "ArcUI_ProcPreview")
  
  if glowType == "default" then
    -- DEFAULT: Show CDM's SpellActivationAlert for preview
    -- DON'T touch size or color - let CDM handle it natively
    if frame.SpellActivationAlert then
      local alert = frame.SpellActivationAlert
      -- Set frame level ABOVE Cooldown swipe
      local baseLevel = frame:GetFrameLevel()
      alert:SetFrameLevel(baseLevel + 15)
      -- Just show the alert - CDM handles sizing
      alert:Show()
      -- Start the loop animation manually for preview
      if alert.ProcLoopFlipbook then
        alert.ProcLoopFlipbook:Show()
      end
      if alert.ProcLoop and not alert.ProcLoop:IsPlaying() then
        alert.ProcLoop:Play()
      end
    end
  elseif glowType == "pixel" then
    local lcg = GetLCG(); if not lcg then return end
    pcall(GetLCG().PixelGlow_Start, frame, colorTbl, lines, speed, nil, thickness, xOffset, yOffset, true, "ArcUI_ProcPreview")
  elseif glowType == "autocast" then
    local lcg = GetLCG(); if not lcg then return end
    pcall(GetLCG().AutoCastGlow_Start, frame, colorTbl, particles, speed, scale, xOffset, yOffset, "ArcUI_ProcPreview")
  elseif glowType == "button" then
    local lcg = GetLCG(); if not lcg then return end
    pcall(GetLCG().ButtonGlow_Start, frame, colorTbl, speed)
  else -- proc
    local lcg = GetLCG(); if not lcg then return end
    pcall(GetLCG().ProcGlow_Start, frame, {
      color = colorTbl,
      startAnim = true,
      xOffset = xOffset,
      yOffset = yOffset,
      key = "ArcUI_ProcPreview"
    })
    -- Set intensity directly on child textures (ProcGlow vertex color alpha doesn't work well with flipbook)
    local glowFrame = frame["_ProcGlowArcUI_ProcPreview"]
    if glowFrame then
      if glowFrame.ProcLoop then
        glowFrame.ProcLoop:SetAlpha(alpha)
      end
      if glowFrame.ProcStart then
        glowFrame.ProcStart:SetAlpha(alpha)
      end
    end
  end
  
  frame._arcProcPreviewActive = true
  frame._arcProcPreviewType = glowType
end

-- Hide proc glow preview for an icon
function ns.CDMEnhance.HideProcGlowPreview(cdID)
  local data = enhancedFrames[cdID]
  if not data or not data.frame then return end
  
  local frame = data.frame
  local previewType = frame._arcProcPreviewType or "default"
  
  -- Stop LCG glows
  StopAllGlows(frame, "ArcUI_ProcPreview")
  
  -- For "default" type, also hide CDM's alert
  if previewType == "default" and frame.SpellActivationAlert then
    local alert = frame.SpellActivationAlert
    -- Stop animations
    if alert.ProcLoop and alert.ProcLoop:IsPlaying() then
      alert.ProcLoop:Stop()
    end
    if alert.ProcStartAnim and alert.ProcStartAnim:IsPlaying() then
      alert.ProcStartAnim:Stop()
    end
    -- Hide the alert
    alert:Hide()
    -- No need to reset colors - we don't modify them for "default" type
  end
  
  frame._arcProcPreviewActive = false
  frame._arcProcPreviewType = nil
end

-- Refresh active proc glow with new settings (for multi-select)
-- This restarts the glow if it's currently active with new settings
function ns.CDMEnhance.RefreshProcGlow(cdID)
  local data = enhancedFrames[cdID]
  if not data or not data.frame then return end
  
  local frame = data.frame
  
  -- Only refresh if custom glow is currently active
  if not frame._arcProcGlowActive then return end
  
  -- Use module-level LCG
  local lcg = GetLCG(); if not lcg then return end
  
  local cfg = GetIconSettings(cdID)
  local glowCfg = cfg and cfg.procGlow
  if not glowCfg then return end
  
  -- Stop all current glows using new key
  pcall(GetLCG().PixelGlow_Stop, frame, "ArcUI_ProcGlow")
  pcall(GetLCG().AutoCastGlow_Stop, frame, "ArcUI_ProcGlow")
  pcall(GetLCG().ButtonGlow_Stop, frame)
  pcall(GetLCG().ProcGlow_Stop, frame, "ArcUI_ProcGlow")
  
  -- If glow is disabled, just stop and exit
  if glowCfg.enabled == false then
    frame._arcProcGlowActive = false
    frame._arcProcGlowType = nil
    return
  end
  
  -- Get settings
  local glowType = glowCfg.glowType or "default"
  local color = glowCfg.color
  local r, g, b = color and color.r or 0.95, color and color.g or 0.95, color and color.b or 0.32
  local alpha = glowCfg.alpha or 1.0
  local scale = glowCfg.scale or 1.0
  local speed = glowCfg.speed or 0.25
  local lines = glowCfg.lines or 8
  local thickness = glowCfg.thickness or 2
  local particles = glowCfg.particles or 4
  local padding = cfg and cfg.padding or 0
  local glowOffset = -padding
  
  local colorTbl = {r, g, b, alpha}
  
  -- Start new glow with updated settings
  if glowType == "pixel" then
    pcall(GetLCG().PixelGlow_Start, frame, colorTbl, lines, speed, nil, thickness, glowOffset, glowOffset, true, "ArcUI_ProcGlow")
  elseif glowType == "autocast" then
    pcall(GetLCG().AutoCastGlow_Start, frame, colorTbl, particles, speed, scale, glowOffset, glowOffset, "ArcUI_ProcGlow")
  elseif glowType == "button" then
    pcall(GetLCG().ButtonGlow_Start, frame, colorTbl, speed)
  else -- proc (default)
    pcall(GetLCG().ProcGlow_Start, frame, {
      color = colorTbl,
      startAnim = false,  -- Don't replay start animation
      xOffset = glowOffset,
      yOffset = glowOffset,
      key = "ArcUI_ProcGlow"
    })
    -- Fix initial state - force correct visibility immediately
    local glowFrame = frame["_ProcGlowArcUI_ProcGlow"]
    if glowFrame then
      if glowFrame.ProcStart then
        glowFrame.ProcStart:Hide()
      end
      if glowFrame.ProcLoop then
        glowFrame.ProcLoop:Show()
        glowFrame.ProcLoop:SetAlpha(alpha)
      end
    end
  end
  
  frame._arcProcGlowActive = true
  frame._arcProcGlowType = glowType
end

-- Get enhanced frame data for a cooldownID
function ns.CDMEnhance.GetEnhancedFrameData(cdID)
  return enhancedFrames[cdID]
end

-- Hide all combat-only glows for a specific viewer type
function ns.CDMEnhance.HideAllCombatOnlyGlows(viewerType)
  for cdID, data in pairs(enhancedFrames) do
    if data and data.frame then
      -- If viewerType specified, only hide for matching types
      if not viewerType or data.viewerType == viewerType then
        HideReadyGlow(data.frame)
      end
    end
  end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HIDDEN-BY-BAR VERIFICATION HELPER
-- Checks _arcHiddenByBar flag AND verifies cooldownID still matches.
-- If frame was recycled by CDM, cleans up stale flag and returns false.
-- ═══════════════════════════════════════════════════════════════════════════
local function IsFrameHiddenByBar(frame)
  if not frame._arcHiddenByBar then return false end
  -- Verify cooldownID still matches what Core.lua intended to hide
  local expectedCdID = frame._arcHiddenByBarCdID
  if expectedCdID and frame.cooldownID and frame.cooldownID ~= expectedCdID then
    -- Frame was recycled for a different cooldown - stale flag, clean up
    frame._arcHiddenByBar = nil
    frame._arcHiddenByBarCdID = nil
    return false
  end
  return true
end
ns.CDMEnhance.IsFrameHiddenByBar = IsFrameHiddenByBar

-- ═══════════════════════════════════════════════════════════════════════════
-- OPTIMIZED APPLY ICON VISUALS (Event-driven)
-- Called from aura state change hooks instead of 20Hz polling
-- Handles: alpha, desaturation. Other visuals stay in ApplyIconVisuals for now.
-- ═══════════════════════════════════════════════════════════════════════════
function ns.CDMEnhance.OptimizedApplyIconVisuals(frame)
  if not frame then return end
  
  -- MASTER TOGGLE: Skip if disabled (fast cached check)
  if not cachedCDMGroupsEnabled then
    return  -- Silent - this is called frequently
  end
  
  -- HIDDEN BY BAR: Core.lua is hiding this icon - skip all visual updates
  if IsFrameHiddenByBar(frame) then return end
  
  -- THROTTLE: Skip if called for same frame with same aura state within 100ms (was 50ms)
  -- This cuts hook-based calls in half
  local now = GetTime()
  local lastCall = frame._arcLastOptimizedCall or 0
  local lastAuraID = frame._arcLastAuraID
  local currentAuraID = frame.auraInstanceID
  local cdID = frame.cooldownID
  
  -- TRACE: Log entry (before throttle check)
  local hasDelay = frame._arcDelayAlphaUntil and now < frame._arcDelayAlphaUntil
  if ns.DynamicLayoutDebug and ns.DynamicLayoutDebug.IsAlphaTraceEnabled and ns.DynamicLayoutDebug.IsAlphaTraceEnabled() and hasDelay then
    ns.DynamicLayoutDebug.AddAlphaTrace("OPTIMIZE_ENTRY", cdID, string.format("hasDelay=%s throttle=%s", tostring(hasDelay), tostring((now - lastCall) < 0.1)))
  end
  
  if (now - lastCall) < 0.1 and lastAuraID == currentAuraID then
    -- TRACE: Log throttled
    if ns.DynamicLayoutDebug and ns.DynamicLayoutDebug.IsAlphaTraceEnabled and ns.DynamicLayoutDebug.IsAlphaTraceEnabled() and hasDelay then
      ns.DynamicLayoutDebug.AddAlphaTrace("OPTIMIZE_THROTTLED", cdID, "same state, too recent")
    end
    return  -- Skip - same state, called too recently
  end
  frame._arcLastOptimizedCall = now
  frame._arcLastAuraID = currentAuraID
  
  -- CACHE IsOptionsPanelOpen once for this call (called multiple times below)
  local optionsPanelOpen = ns.CDMEnhance.IsOptionsPanelOpen and ns.CDMEnhance.IsOptionsPanelOpen() or false
  
  -- FAST PATH: Get config from frame-level cache
  local cfg = GetEffectiveIconSettingsForFrame(frame)
  if not cfg then return end
  
  -- CRITICAL: If ignoreAuraOverride is enabled, skip aura-based state updates
  -- The cooldown ticker (ApplyCooldownStateVisuals) handles alpha based on spell cooldown state
  -- If we don't skip here, aura hooks will override the cooldown-based alpha values
  local ignoreAuraOverride = (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
                          or (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)
  if ignoreAuraOverride then
    return  -- Let cooldown ticker handle state, not aura hooks
  end
  
  local stateVisuals = GetEffectiveStateVisuals(cfg)
  if not stateVisuals then return end  -- No custom state settings
  
  -- Get cdID for glow tracking
  local cdID = frame.cooldownID
  
  -- Get icon texture for desaturation
  local iconTex = frame.Icon or frame.icon
  if iconTex then
    -- For bar-style icons, frame.Icon is a Frame container with Icon child texture
    local actualTex = iconTex
    if not iconTex.SetDesaturated and iconTex.Icon then
      actualTex = iconTex.Icon
    end
    iconTex = actualTex
  end
  
  -- Early exit: skip frames where CDM isn't using aura display AND we didn't register as aura
  -- wasSetFromAura is the runtime flag for CDM actively showing aura data
  -- hasAura alone is NOT reliable - means spell CAN produce auras (e.g. target debuffs)
  -- but CDM may track it via cooldown (e.g. Kidney Shot: hasAura=true, wasSetFromCooldown=true)
  local cooldownInfo = frame.cooldownInfo
  if not cfg._isAura and not frame.totemData and frame.wasSetFromAura ~= true then
    return  -- Let cooldown logic (20Hz ticker) handle this frame
  end
  
  -- Determine icon type and state
  local auraID = frame.auraInstanceID
  local hasAuraOrTotem = (auraID and type(auraID) == "number" and auraID > 0) or (frame.totemData ~= nil)
  local isAura = cfg._isAura or hasAuraOrTotem
  
  -- Calculate target alpha and desat based on state
  local targetAlpha
  local targetDesat  -- 0 = not desaturated, 1 = desaturated
  local isReady = false
  
  if isAura or hasAuraOrTotem then
    -- isReady = buff/debuff active (auraID > 0) OR totem active (totemData exists)
    isReady = (auraID and type(auraID) == "number" and auraID > 0) or (frame.totemData ~= nil)
    
    if isReady then
      targetAlpha = GetEffectiveReadyAlpha(stateVisuals)
      targetDesat = 0
    else
      local cdAlpha = stateVisuals.cooldownAlpha
      if cdAlpha <= 0 then
        if optionsPanelOpen then
          targetAlpha = 0.35
        else
          targetAlpha = 0
        end
      else
        targetAlpha = cdAlpha
      end
      targetDesat = stateVisuals.cooldownDesaturate and 1 or 0
    end
  else
    -- Not totem or aura - skip, let regular ApplyIconVisuals handle
    return
  end
  
  -- Set ready alpha enforcement based on state
  local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
  if isReady and effectiveReadyAlpha < 1.0 then
    frame._arcEnforceReadyAlpha = true
    frame._arcReadyAlphaValue = effectiveReadyAlpha
  else
    frame._arcEnforceReadyAlpha = false
  end
  
  -- CENTER ALIGNMENT DELAY: When aura just appeared in a center-aligned group,
  -- delay showing it to give Layout() time to position it correctly first.
  -- The flag is set by DynamicLayout hooks and expires after 0.1 seconds.
  local delayAlpha = frame._arcDelayAlphaUntil and now < frame._arcDelayAlphaUntil
  if delayAlpha and targetAlpha > 0 then
    -- TRACE: Log delay blocking alpha
    if ns.DynamicLayoutDebug and ns.DynamicLayoutDebug.IsAlphaTraceEnabled and ns.DynamicLayoutDebug.IsAlphaTraceEnabled() then
      ns.DynamicLayoutDebug.AddAlphaTrace("ALPHA_BLOCKED_BY_DELAY", cdID, string.format("target=%.2f remaining=%.3fms", targetAlpha, (frame._arcDelayAlphaUntil - now) * 1000))
    end
    -- Keep frame invisible until delay expires - Layout() will position it
    -- Clear cached target so alpha gets set properly after delay
    frame._arcTargetAlpha = nil
    frame._arcBypassFrameAlphaHook = true
    frame:SetAlpha(0)
    if frame.Cooldown then frame.Cooldown:SetAlpha(0) end
    frame._arcBypassFrameAlphaHook = false
    return  -- Skip rest of visuals until positioned
  elseif frame._arcDelayAlphaUntil and now >= frame._arcDelayAlphaUntil then
    -- Delay expired, clear the flag
    -- TRACE: Log delay expired
    if ns.DynamicLayoutDebug and ns.DynamicLayoutDebug.IsAlphaTraceEnabled and ns.DynamicLayoutDebug.IsAlphaTraceEnabled() then
      ns.DynamicLayoutDebug.AddAlphaTrace("DELAY_EXPIRED_AUTO", cdID, "clearing flag")
    end
    frame._arcDelayAlphaUntil = nil
  end
  
  -- Apply alpha (no comparison - throttle handles spam, WoW handles same-value optimization)
  -- Removed secret value comparison that caused errors when _arcTargetAlpha was set from curve evaluation
  if ns.DynamicLayoutDebug and ns.DynamicLayoutDebug.IsAlphaTraceEnabled and ns.DynamicLayoutDebug.IsAlphaTraceEnabled() then
    ns.DynamicLayoutDebug.AddAlphaTrace("SETALPHA", cdID, string.format("%.2f -> %.2f", frame._arcTargetAlpha or 0, targetAlpha))
  end
  frame._arcTargetAlpha = targetAlpha
  frame._arcBypassFrameAlphaHook = true
  frame:SetAlpha(targetAlpha)
  if frame.Cooldown then frame.Cooldown:SetAlpha(targetAlpha) end
  frame._arcBypassFrameAlphaHook = false
  
  -- Ensure frame is shown (alpha 0 handles invisibility)
  if not frame:IsShown() then
    frame:Show()
  end
  
  -- Apply desaturation (no comparison - throttle handles spam)
  if iconTex then
    frame._arcTargetDesat = targetDesat
    frame._arcBypassDesatHook = true
    if iconTex.SetDesaturation then
      iconTex:SetDesaturation(targetDesat)
    else
      iconTex:SetDesaturated(targetDesat == 1)
    end
    frame._arcBypassDesatHook = false
    -- Sync border
    ApplyBorderDesaturation(frame, targetDesat)
  end
  
  -- Calculate target tint color
  local targetTintR, targetTintG, targetTintB = 1, 1, 1
  if not isReady and stateVisuals.cooldownTint and stateVisuals.cooldownTintColor then
    local col = stateVisuals.cooldownTintColor
    targetTintR = col.r or 0.5
    targetTintG = col.g or 0.5
    targetTintB = col.b or 0.5
  end
  
  -- Only set tint if changed (pack into single comparison key)
  local tintKey = string.format("%.2f,%.2f,%.2f", targetTintR, targetTintG, targetTintB)
  if iconTex and frame._arcTargetTint ~= tintKey then
    frame._arcTargetTint = tintKey
    iconTex:SetVertexColor(targetTintR, targetTintG, targetTintB)
  end
  
  -- GLOW: For cooldown frames (wasSetFromAura but not cfg._isAura/totem),
  -- skip glow here entirely. Their glow is driven by the cooldown duration
  -- curve in ApplyGlow (via the 20Hz ticker). The curve result is secret and
  -- must be passed directly to SetAlpha every tick — caching _arcTargetGlow
  -- here would prevent the curve from re-driving hide/show, causing the glow
  -- to stay visible incorrectly after combat.
  local isCooldownFrame = not cfg._isAura and frame.totemData == nil
  if not isCooldownFrame then
    -- Pure aura frame: handle glow based on aura presence (safe to cache)
    local threshold = stateVisuals.glowThreshold or 1.0

    if threshold >= 1.0 then
      -- Simple on/off glow - event-driven
      if ShouldShowReadyGlow(stateVisuals, frame) and isReady then
        ShowReadyGlow(frame, stateVisuals)
      else
        HideReadyGlow(frame)
      end
      frame._arcTargetGlow = true  -- Mark handled so 20Hz skips
    else
      -- Threshold glow - managed by 0.5s ticker
      if ShouldShowReadyGlow(stateVisuals, frame) and isReady then
        -- Start tracking this icon for threshold glow updates
        if cdID then StartThresholdGlowTracking(cdID) end
      else
        -- Stop tracking and hide glow
        if cdID then StopThresholdGlowTracking(cdID) end
        HideReadyGlow(frame)
      end
      frame._arcTargetGlow = true  -- Mark handled so 20Hz skips
    end
  end
  -- Cooldown frames: _arcTargetGlow intentionally NOT set — curve re-evaluates every tick
  
  -- Update custom label visibility on aura state change
  if ns.CustomLabel and ns.CustomLabel.UpdateVisibility then
    ns.CustomLabel.UpdateVisibility(frame)
  end
end

-- UNIFIED FUNCTION: Apply all visual state to an icon
-- CDMGroups should call this instead of having its own inline logic
-- Handles auras, cooldowns, ignoreAuraOverride, all inactive state options
function ns.CDMEnhance.ApplyIconVisuals(frame)
  if not frame then return end
  
  -- MASTER TOGGLE: Skip if disabled (fast cached check)
  if not cachedCDMGroupsEnabled then
    return  -- Silent - this is called frequently
  end
  
  -- HIDDEN BY BAR: Core.lua is hiding this icon - skip all visual updates
  if IsFrameHiddenByBar(frame) then return end
  
  -- THROTTLE: Skip if called for same frame within 200ms (was 100ms)
  -- This cuts calls in half
  local now = GetTime()
  local lastCall = frame._arcLastApplyVisuals or 0
  if (now - lastCall) < 0.2 then
    return  -- Too soon, skip
  end
  frame._arcLastApplyVisuals = now
  
  -- CRITICAL: Skip during spec change to prevent visual glitches
  if ns.CDMGroups then
    if ns.CDMGroups.specChangeInProgress or ns.CDMGroups._pendingSpecChange then return end
    if ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd then return end
  end
  
  -- FAST PATH: Get config from frame-level cache
  local cfg = GetEffectiveIconSettingsForFrame(frame)
  if not cfg then return end
  
  local cdID = frame.cooldownID
  
  -- CRITICAL: Ensure _arcIgnoreAuraOverride is set
  -- This is normally set in UpdateIconAppearance, but ApplyIconVisuals can be called independently
  local ignoreAuraOverride = (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)
    or (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
  frame._arcIgnoreAuraOverride = ignoreAuraOverride or false
  
  -- Check if glow preview is active for this icon
  local isGlowPreview = ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsGlowPreviewActive and
                        ns.CDMEnhanceOptions.IsGlowPreviewActive(cdID)
  
  -- Check if there are any state visuals configured
  -- If not, let CDM handle everything - don't call ApplyCooldownStateVisuals at all
  -- EXCEPT if glow preview is active - we need ApplyCooldownStateVisuals to handle that
  local stateVisuals = GetEffectiveStateVisuals(cfg)
  if not stateVisuals and not ignoreAuraOverride and not isGlowPreview then
    -- No custom settings and not in ignoreAuraOverride mode and not in preview
    -- Let CDM handle alpha, desaturation, everything
    frame._arcForceDesatValue = nil
    -- IMPORTANT: Hide any leftover glow from preview mode
    HideReadyGlow(frame)
    return
  end
  
  -- Pass stateVisuals to avoid duplicate GetEffectiveStateVisuals call (perf optimization)
  ApplyCooldownStateVisuals(frame, cfg, cfg.alpha or 1.0, stateVisuals)
end

-- Forward declaration for EnhanceFrame (exported below after definition)
local EnhanceFrame

-- ===================================================================
-- FRAME ENHANCEMENT
-- ===================================================================
EnhanceFrame = function(frame, cdID, viewerType, viewerName)
  if not frame then return end
  
  -- MASTER TOGGLE: Skip if disabled (fast cached check)
  if not cachedCDMGroupsEnabled then
    return
  end
  
  -- CRITICAL: Skip during spec change to prevent enhancing orphaned frames
  if ns.CDMGroups then
    if ns.CDMGroups.specChangeInProgress or ns.CDMGroups._pendingSpecChange then return end
    if ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd then return end
  end
  
  -- Skip if this type's styling is disabled
  local db = GetDB()
  if db then
    if viewerType == "aura" and db.enableAuraCustomization == false then
      -- Don't spam - this is called constantly
      return
    end
    if (viewerType == "cooldown" or viewerType == "utility") and db.enableCooldownCustomization == false then
      -- Don't spam - this is called constantly
      return
    end
  end
  
  -- Skip BuffBarCooldownViewer frames - they have a different structure (bars, not icons)
  -- and our icon customization settings don't work properly with them
  if viewerName == "BuffBarCooldownViewer" then return end
  local parent = frame:GetParent()
  if parent and parent:GetName() == "BuffBarCooldownViewer" then return end
  
  -- Skip frames that are actual status bars (have Bar element) - these aren't icon-based
  if frame.Bar and frame.Bar:IsObjectType("StatusBar") then return end
  
  -- CRITICAL: Clean up stale references when frame is reassigned to a new cdID
  -- If this frame was previously tracked for a DIFFERENT cdID, remove those old entries
  if frame._arcLastEnhancedCdID and frame._arcLastEnhancedCdID ~= cdID then
    local oldCdID = frame._arcLastEnhancedCdID
    
    -- Clean up enhancedFrames
    local oldEntry = enhancedFrames[oldCdID]
    if oldEntry and oldEntry.frame == frame then
      enhancedFrames[oldCdID] = nil
      if ns.devMode then
        print(string.format("|cffFF6600[ArcUI]|r Frame reassigned: removed enhancedFrames[%d] (now cdID %d)", oldCdID, cdID))
      end
    end
    
    -- CRITICAL: Clear frame-level settings cache — it holds the OLD cdID's settings
    -- Without this, GetEffectiveIconSettingsForFrame returns stale config
    -- (version check passes but cdID has changed underneath)
    frame._arcCfg = nil
    frame._arcCfgVersion = nil
  end
  
  -- Track which cdID this frame is currently enhanced for
  frame._arcLastEnhancedCdID = cdID
  frame._arcEnhanced = true
  
  -- Update tracking table
  enhancedFrames[cdID] = {
    frame = frame,
    viewerType = viewerType,
    viewerName = viewerName,
  }
  
  -- Register with Masque (if available and MasqueBlizzBars isn't handling it)
  -- CRITICAL: Skip if spec change was recent - CDM frames may still be settling
  -- The scheduled Masque refresh in CDMGroups will handle these frames later
  local skipMasque = false
  if ns.CDMGroups and ns.CDMGroups.lastSpecChangeTime then
    local timeSinceSpecChange = GetTime() - ns.CDMGroups.lastSpecChangeTime
    if timeSinceSpecChange < 5 then
      skipMasque = true  -- Let the delayed Masque refresh handle it
    end
  end
  if not skipMasque and ns.Masque and ns.Masque.AddFrame then
    ns.Masque.AddFrame(frame, viewerName, cdID)
  end
  
  -- Only do initial setup if not already done
  if not frame._arcInitialized then
    frame._arcInitialized = true
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- Initial capture of CDM position
    local origX, origY = frame:GetLeft(), frame:GetBottom()
    if origX and origY then
      frame._arcOriginalX = origX
      frame._arcOriginalY = origY
    end
    
    CreateDragOverlay(frame, cdID)
    
    -- Store original dimensions for SetSize-based scaling
    if not frame._arcOrigW then
      frame._arcOrigW = frame:GetWidth()
      frame._arcOrigH = frame:GetHeight()
    end
    
    -- NOTE: SetSize and SetScale hooks removed - CDMGroups handles all size/scale enforcement
    -- CDMEnhance only communicates settings via GetEffectiveIconSettings which CDMGroups reads
    
    -- ═══════════════════════════════════════════════════════════════════
    -- FRAME ALPHA HOOK - Enforce stored _arcTargetAlpha when CDM tries to override
    -- Alpha is set ONCE at state changes, hook just blocks CDM interference
    -- Also enforces ready state alpha when _arcEnforceReadyAlpha is set
    -- ═══════════════════════════════════════════════════════════════════
    if not frame._arcFrameAlphaHooked then
      frame._arcFrameAlphaHooked = true
      
      hooksecurefunc(frame, "SetAlpha", function(self, alpha)
        if self._arcBypassFrameAlphaHook then return end
        
        -- HIDDEN BY BAR: Core.lua is hiding this icon for a tracking bar
        -- Verify cooldownID still matches before blocking alpha overrides
        if IsFrameHiddenByBar(self) then return end
        
        -- READY STATE ALPHA ENFORCEMENT
        -- When in ready state with custom alpha (e.g., 0.1), block CDM overrides
        if self._arcEnforceReadyAlpha and self._arcReadyAlphaValue then
          self._arcBypassFrameAlphaHook = true
          self:SetAlpha(self._arcReadyAlphaValue)
          self._arcBypassFrameAlphaHook = false
          return
        end
        
        -- If we have a target alpha stored, enforce it
        if self._arcTargetAlpha ~= nil then
          self._arcBypassFrameAlphaHook = true
          self:SetAlpha(self._arcTargetAlpha)
          self._arcBypassFrameAlphaHook = false
        end
      end)
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- SHOW HOOK - Enforce Hide() when frame is hidden by bar tracking
    -- CDM and layout systems call Show() which would override our Hide()
    -- Verifies cooldownID still matches to handle frame recycling
    -- ═══════════════════════════════════════════════════════════════════
    if not frame._arcHideByBarShowHooked then
      frame._arcHideByBarShowHooked = true
      
      hooksecurefunc(frame, "Show", function(self)
        if IsFrameHiddenByBar(self) then
          self:Hide()
        end
      end)
      
      if frame.SetShown then
        hooksecurefunc(frame, "SetShown", function(self, shown)
          if shown and IsFrameHiddenByBar(self) then
            self:Hide()
          end
        end)
      end
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- AURA STATE HOOKS - Call OptimizedApplyIconVisuals on state change
    -- Event-driven alpha updates instead of polling
    -- ═══════════════════════════════════════════════════════════════════
    if not frame._arcAuraStateHooked then
      frame._arcAuraStateHooked = true
      
      -- Hook SetAuraInstanceInfo - aura gained
      if frame.SetAuraInstanceInfo then
        hooksecurefunc(frame, "SetAuraInstanceInfo", function(self)
          if ns.CDMEnhance.OptimizedApplyIconVisuals then
            ns.CDMEnhance.OptimizedApplyIconVisuals(self)
          end
        end)
      end
      
      -- Hook ClearAuraInstanceInfo - aura lost
      if frame.ClearAuraInstanceInfo then
        hooksecurefunc(frame, "ClearAuraInstanceInfo", function(self)
          if ns.CDMEnhance.OptimizedApplyIconVisuals then
            ns.CDMEnhance.OptimizedApplyIconVisuals(self)
          end
        end)
      end
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- ONCOOLDOWNDONE HOOK - Instant cooldown-to-ready transition
    -- CDM's Cooldown widget fires OnCooldownDone when its internal timer
    -- expires. Without this hook, cooldown state visuals (alpha, desat,
    -- glow) and custom label visibility only update on the next
    -- SPELL_UPDATE_COOLDOWN event (requires pressing an ability).
    -- This hook triggers an immediate curve re-evaluation when the
    -- cooldown naturally finishes, matching CDM's own ready-state
    -- detection (RefreshIconDesaturation / CheckDisplayCooldownState).
    -- ═══════════════════════════════════════════════════════════════════
    if frame.Cooldown and not frame.Cooldown._arcOnCooldownDoneHooked then
      frame.Cooldown._arcOnCooldownDoneHooked = true
      
      frame.Cooldown:HookScript("OnCooldownDone", function(self)
        local parentFrame = self._arcParentFrame
        if not parentFrame then return end
        
        -- Only process cooldown/utility frames (not aura frames)
        local vt = parentFrame._arcViewerType
        if vt ~= "cooldown" and vt ~= "utility" then return end
        
        -- Refresh cached duration objects (they now reflect ready state)
        -- Use live overrideSpellID — _arcCachedSpellID can be stale after spell swap
        local spellID = parentFrame._arcCachedSpellID
        if parentFrame.cooldownInfo then
          local liveSpell = parentFrame.cooldownInfo.overrideSpellID or parentFrame.cooldownInfo.spellID
          if liveSpell then
            spellID = liveSpell
            parentFrame._arcCachedSpellID = liveSpell
          end
        end
        if spellID then
          if C_Spell.GetSpellCooldownDuration then
            local okDur, durObj = pcall(C_Spell.GetSpellCooldownDuration, spellID)
            if okDur and durObj then
              parentFrame._arcCachedCooldownDuration = durObj
            end
          end
          if C_Spell.GetSpellChargeDuration then
            local okChg, chgObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
            if okChg and chgObj then
              parentFrame._arcCachedChargeDuration = chgObj
            end
          end
        end
        
        -- Apply cooldown state visuals (alpha, desat, glow)
        local cfg = ns.CDMEnhance.GetEffectiveIconSettingsForFrame
                    and ns.CDMEnhance.GetEffectiveIconSettingsForFrame(parentFrame)
        if cfg then
          local stateVisuals = ns.CDMEnhance.GetEffectiveStateVisuals
                               and ns.CDMEnhance.GetEffectiveStateVisuals(cfg)
          if stateVisuals or parentFrame._arcIgnoreAuraOverride then
            -- Use the relay wrapper (also updates custom labels)
            ApplyCooldownStateVisuals(parentFrame, cfg, cfg.alpha or 1.0, stateVisuals)
            return
          end
        end
        
        -- Even without state visuals, update custom label visibility
        if parentFrame._arcCLHasText then
          if ns.CustomLabel and ns.CustomLabel.UpdateVisibility then
            ns.CustomLabel.UpdateVisibility(parentFrame)
          end
        end
      end)
    end
    
    -- NOTE: Inactive state handling removed from per-frame OnUpdate
    -- CDMGroups manages ALL icons and calls ApplyIconVisuals at 20Hz
    -- The per-frame OnUpdate was always returning early because all icons are in CDMGroups
  end
  
  -- Store viewerType on frame (updated every enhance call in case of spec switch)
  -- Used by OnCooldownDone hook to filter cooldown/utility frames
  frame._arcViewerType = viewerType
  
  -- ═══════════════════════════════════════════════════════════════════
  -- COOLDOWN SPELL ID CACHE - Cache spellID out of combat for event-driven updates
  -- We read cooldownInfo here (non-secret out of combat) and store for later use
  -- ═══════════════════════════════════════════════════════════════════
  if (viewerType == "cooldown" or viewerType == "utility") and not InCombatLockdown() then
    local cooldownInfo = frame.cooldownInfo
    if cooldownInfo then
      local spellID = cooldownInfo.overrideSpellID or cooldownInfo.spellID
      if spellID then
        frame._arcCachedSpellID = spellID
        -- Also cache initial duration objects
        if C_Spell.GetSpellCooldownDuration then
          local okDur, durObj = pcall(C_Spell.GetSpellCooldownDuration, spellID)
          if okDur and durObj then
            frame._arcCachedCooldownDuration = durObj
          end
        end
        if C_Spell.GetSpellChargeDuration then
          local okCharge, chargeObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
          if okCharge and chargeObj then
            frame._arcCachedChargeDuration = chargeObj
          end
        end
      end
    end
  end
  
  -- Update overlay cdID reference
  if frame._arcOverlay then
    frame._arcOverlay._cdID = cdID
  end
  
  -- NOTE: Scale/size enforcement removed - CDMGroups handles all of that
  -- CDMEnhance only provides settings via GetEffectiveIconSettings
  
  -- Always apply icon style (borders, glow, textures - NOT position/scale/size)
  ApplyIconStyle(frame, cdID)
  
  -- Create/update text drag overlays
  local cfg = GetEffectiveIconSettingsForFrame(frame)
  if cfg then
    if frame._arcChargeText then
      CreateTextDragOverlay(frame._arcChargeText, frame, cdID, "charge")
    end
    -- Also create drag overlay for Arc Auras Count text (item stack counts)
    if frame.Count and (frame._arcConfig or frame._arcAuraID) then
      CreateTextDragOverlay(frame.Count, frame, cdID, "charge")
    end
    if frame._arcCooldownText then
      CreateTextDragOverlay(frame._arcCooldownText, frame, cdID, "cooldown")
    end
  end
  UpdateOverlayState(frame)
end

-- Export EnhanceFrame for CDMGroups to call when frames change
ns.CDMEnhance.EnhanceFrame = EnhanceFrame

-- ===================================================================
-- SCANNING - Now uses centralized Core.lua scanner
-- CDMEnhance handles frame enhancement after central scan
-- Also tracks detached frames (frames reparented to UIParent for free positioning)
-- ===================================================================

-- Check if a frame reference is still valid (not destroyed/recycled)
local function IsFrameValid(frame)
  if not frame then return false end
  -- Try to access frame properties - if frame was destroyed this will fail
  local ok = pcall(function()
    local _ = frame:GetParent()
    local _ = frame:IsShown()
  end)
  return ok
end

-- Get all detached frames (for central scanner to include)
function ns.CDMEnhance.GetDetachedFrames()
  -- Delegate to CDMGroups - it tracks all free positioned icons
  if ns.CDMGroups and ns.CDMGroups.GetFreeIcons then
    local freeIcons = ns.CDMGroups.GetFreeIcons()
    local detached = {}
    for cdID, data in pairs(freeIcons) do
      detached[cdID] = {
        cooldownID = cdID,
        frame = data.frame,
        viewerType = data.viewerType,
        viewerName = data.originalViewerName,
      }
    end
    return detached
  end
  return {}  -- CDMGroups not loaded
end

-- Return the enhancedFrames table (used by Core.lua for frame lookup)
function ns.CDMEnhance.GetEnhancedFrames()
  return enhancedFrames
end

-- Return free position frames (delegates to CDMGroups)
function ns.CDMEnhance.GetFreePositionFrames()
  -- Delegate to CDMGroups - it tracks all free positioned icons
  if ns.CDMGroups and ns.CDMGroups.freeIcons then
    local result = {}
    for cdID, data in pairs(ns.CDMGroups.freeIcons) do
      if data.frame then
        result[cdID] = data.frame
      end
    end
    return result
  end
  return {}  -- CDMGroups not loaded
end

-- Return the DB for debug purposes
function ns.CDMEnhance.GetDB()
  return GetDB()
end

-- Find a frame by cooldownID across all CDM viewers (used by Core.lua when tracking fails)
-- SIMPLE: Just scan viewers for a frame where frame.cooldownID matches
function ns.CDMEnhance.FindFrameByCooldownID(cooldownID, viewerType)
  if not cooldownID or cooldownID == 0 then return nil end
  
  -- 1. Check enhancedFrames (fast path)
  local data = enhancedFrames[cooldownID]
  if data and data.frame and IsFrameValid(data.frame) then
    if data.frame.cooldownID == cooldownID then
      return data.frame, data.viewerType, data.viewerName
    end
  end
  
  -- 2. Direct scan of CDM viewers
  local viewerNames
  if viewerType == "aura" then
    viewerNames = {"BuffIconCooldownViewer"}
  elseif viewerType == "cooldown" then
    viewerNames = {"EssentialCooldownViewer"}
  elseif viewerType == "utility" then
    viewerNames = {"UtilityCooldownViewer"}
  else
    -- Search all viewers
    viewerNames = {"BuffIconCooldownViewer", "BuffBarCooldownViewer", "EssentialCooldownViewer", "UtilityCooldownViewer"}
  end
  
  for _, viewerName in ipairs(viewerNames) do
    local viewer = _G[viewerName]
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
        if frameCdID == cooldownID then
          local vType = viewerName == "BuffIconCooldownViewer" and "aura" or
                       (viewerName == "BuffBarCooldownViewer" and "aura" or
                       (viewerName == "EssentialCooldownViewer" and "cooldown" or "utility"))
          return child, vType, viewerName
        end
      end
    end
  end
  
  -- 3. Also scan UIParent for free position frames
  -- (They're parented to UIParent but still have valid cooldownID)
  for cdID, eData in pairs(enhancedFrames) do
    if eData.frame and IsFrameValid(eData.frame) then
      if eData.frame.cooldownID == cooldownID then
        return eData.frame, eData.viewerType, eData.viewerName
      end
    end
  end
  
  return nil, nil, nil
end

-- Recovery function: Called when a bar's tracking fails to find its frame
-- Attempts to locate and set up the frame for tracking
function ns.CDMEnhance.RecoverFrameForCooldownID(cooldownID)
  if not cooldownID or cooldownID == 0 then return nil end
  
  local frame, vType, viewerName = ns.CDMEnhance.FindFrameByCooldownID(cooldownID)
  if not frame then return nil end
  
  -- Update our tracking
  enhancedFrames[cooldownID] = {
    frame = frame,
    viewerType = vType,
    viewerName = viewerName,
  }
  
  -- Enhance the frame for styling
  EnhanceFrame(frame, cooldownID, vType, viewerName)
  
  return frame
end

-- Called by Core.lua after central scan completes
function ns.CDMEnhance.OnCDMScanComplete()
  -- MASTER TOGGLE: Skip if disabled
  local groupsDB = Shared.GetCDMGroupsDB()
  if groupsDB and groupsDB.enabled == false then
    return
  end
  
  -- Restore saved Edit Mode scales from DB before sampling
  -- This ensures we have correct scales even if CDM hasn't applied them yet
  RestoreSavedEditModeScales()
  
  -- Get all icons from central scanner and enhance their frames
  local allIcons = ns.API and ns.API.GetAllCDMIcons() or {}
  
  -- Track which cdIDs we've seen in this scan
  local seenCdIDs = {}
  
  -- Sample group scales from CDM frames (overrides restored values if CDM has applied scales)
  -- Only sample from non-free icons (they have CDM's natural scale)
  local scalesSampled = { aura = false, cooldown = false, utility = false }
  
  for cdID, data in pairs(allIcons) do
    seenCdIDs[cdID] = true
    if data.frame then
      -- Sample scale from first suitable icon per viewer type
      local vType = data.viewerType
      if vType and not scalesSampled[vType] then
        local cfg = GetIconSettings(cdID)
        -- Only sample from non-free icons (they have CDM's natural scale)
        if not cfg or not cfg.position or cfg.position.mode ~= "free" then
          local currentScale = data.frame:GetScale()
          if currentScale and currentScale > 0 then
            groupScales[vType] = currentScale
            scalesSampled[vType] = true
          end
        end
      end
      
      EnhanceFrame(data.frame, cdID, data.viewerType, data.viewerName)
      
      -- CDMGroups handles ALL positioning (groups AND free icons)
      -- CDMEnhance only applies styling via EnhanceFrame above
    end
  end
  
  -- Clean up enhancedFrames entries for cdIDs no longer in CDM
  -- CDMGroups handles ALL positioning - we just preserve entries for styling
  for cdID, data in pairs(enhancedFrames) do
    if not seenCdIDs[cdID] then
      -- CDMGroups handles all positioning and tracking
      -- Just preserve enhancedFrames entry for styling purposes
      -- Don't do any position manipulation or cleanup
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════════
  -- CRITICAL: Also enhance frames in CDMGroups containers
  -- These frames are reparented away from CDM viewers, so the central
  -- API scanner doesn't find them. We need to ensure they're enhanced
  -- so ApplyIconStyle runs (sets up hooks, overlays, borders, etc.)
  -- CDMGroups calls ApplyIconVisuals for visual state handling.
  -- ═══════════════════════════════════════════════════════════════════
  if ns.CDMGroups then
    local cdmGroupsEnhanced = 0
    
    -- Scan group containers
    if ns.CDMGroups.groups then
      for groupName, group in pairs(ns.CDMGroups.groups) do
        if group.members then
          for cdID, member in pairs(group.members) do
            if member.frame and member.frame.cooldownID == cdID then
              -- Check if already enhanced
              local existing = enhancedFrames[cdID]
              if not existing or existing.frame ~= member.frame then
                -- Not enhanced or stale reference - enhance it now
                local viewerType = member.viewerType or "aura"
                local viewerName = member.originalViewerName or "BuffIconCooldownViewer"
                EnhanceFrame(member.frame, cdID, viewerType, viewerName)
                cdmGroupsEnhanced = cdmGroupsEnhanced + 1
              end
            end
          end
        end
      end
    end
    
    -- Scan free icons
    if ns.CDMGroups.freeIcons then
      for cdID, data in pairs(ns.CDMGroups.freeIcons) do
        if data.frame and data.frame.cooldownID == cdID then
          local existing = enhancedFrames[cdID]
          if not existing or existing.frame ~= data.frame then
            local viewerType = data.viewerType or "aura"
            local viewerName = data.originalViewerName or "BuffIconCooldownViewer"
            EnhanceFrame(data.frame, cdID, viewerType, viewerName)
            cdmGroupsEnhanced = cdmGroupsEnhanced + 1
          end
        end
      end
    end
    
    if cdmGroupsEnhanced > 0 and ns.devMode then
      print(string.format("|cff00FF00[ArcUI CDMEnhance]|r Enhanced %d frames from CDMGroups containers", cdmGroupsEnhanced))
    end
  end
  
  if ns.devMode then
    local count = 0
    for cdID, data in pairs(enhancedFrames) do
      count = count + 1
    end
    print(string.format("|cff00FF00[ArcUI CDMEnhance]|r Enhanced %d frames", count))
    print(string.format("|cff00FF00[ArcUI CDMEnhance]|r Group scales (sampled): aura=%.2f, cooldown=%.2f, utility=%.2f", 
      groupScales.aura, groupScales.cooldown, groupScales.utility))
    
    -- Also show override status (now from spec-based storage)
    local specGroupSettings = Shared.GetSpecGroupSettings()
    if specGroupSettings then
      for vType, gs in pairs(specGroupSettings) do
        if gs.scale then
          print(string.format("|cff00FF00[ArcUI CDMEnhance]|r Override ENABLED for %s: scale=%.2f", vType, gs.scale))
        end
      end
    end
  end
  
  -- MASQUE SAFETY: Queue a Masque refresh after scan completes.
  -- Paths like ScanCDM (options panel open) don't go through RefreshAllStyles,
  -- so EnhanceFrame → ApplyIconStyle may run without a subsequent Masque reskin.
  -- This ensures Masque re-applies its icon positioning after any scan.
  if ns.Masque and ns.Masque.QueueRefresh then
    ns.Masque.QueueRefresh()
  end
  
  -- Schedule a delayed rescan to catch late-arriving frames (CDM sometimes creates frames after initial scan)
  C_Timer.After(0.5, function()
    if not InCombatLockdown() then
      -- Force CDM to create any frames that don't exist yet
      ns.CDMEnhance.ForceCDMFrameCreation()
      
      -- Quick scan of CDM viewers for any frames we might have missed
      local viewerConfigs = {
        { name = "BuffIconCooldownViewer", vType = "aura" },
        { name = "EssentialCooldownViewer", vType = "cooldown" },
        { name = "UtilityCooldownViewer", vType = "utility" },
      }
      
      local foundNew = 0
      for _, config in ipairs(viewerConfigs) do
        local viewer = _G[config.name]
        if viewer then
          local children = {viewer:GetChildren()}
          for _, child in ipairs(children) do
            local cdID = child.cooldownID
            if cdID and cdID ~= 0 then
              -- Skip StatusBar frames
              if not (child.Bar and child.Bar.IsObjectType and child.Bar:IsObjectType("StatusBar")) then
                local existing = enhancedFrames[cdID]
                if not existing or existing.frame ~= child then
                  EnhanceFrame(child, cdID, config.vType, config.name)
                  foundNew = foundNew + 1
                end
              end
            end
          end
        end
      end
      
      -- Also trigger CDMGroups to pick up any new frames
      if ns.CDMGroups and ns.CDMGroups.AutoAssignNewIcons then
        ns.CDMGroups.AutoAssignNewIcons()
      end
      
      -- Refresh bar tracking systems
      if ns.API then
        if ns.API.RefreshAll then ns.API.RefreshAll() end
        if ns.API.ScanAvailableBuffs then ns.API.ScanAvailableBuffs() end
        if ns.API.ScanAvailableBarsWithDuration then ns.API.ScanAvailableBarsWithDuration() end
      end
      
      if foundNew > 0 and ns.devMode then
        print(string.format("|cff00FF00[ArcUI CDMEnhance]|r Delayed rescan (0.5s) found %d new frames", foundNew))
      end
    end
  end)
  
  -- Second delayed rescan at 1 second for really late frames
  C_Timer.After(1.0, function()
    if not InCombatLockdown() then
      -- Force CDM to create any remaining frames
      ns.CDMEnhance.ForceCDMFrameCreation()
      
      local viewerConfigs = {
        { name = "BuffIconCooldownViewer", vType = "aura" },
        { name = "EssentialCooldownViewer", vType = "cooldown" },
        { name = "UtilityCooldownViewer", vType = "utility" },
      }
      
      local foundNew = 0
      for _, config in ipairs(viewerConfigs) do
        local viewer = _G[config.name]
        if viewer then
          local children = {viewer:GetChildren()}
          for _, child in ipairs(children) do
            local cdID = child.cooldownID
            if cdID and cdID ~= 0 then
              if not (child.Bar and child.Bar.IsObjectType and child.Bar:IsObjectType("StatusBar")) then
                local existing = enhancedFrames[cdID]
                if not existing or existing.frame ~= child then
                  EnhanceFrame(child, cdID, config.vType, config.name)
                  foundNew = foundNew + 1
                end
              end
            end
          end
        end
      end
      
      if ns.CDMGroups and ns.CDMGroups.AutoAssignNewIcons then
        ns.CDMGroups.AutoAssignNewIcons()
      end
      
      -- Refresh bar tracking systems
      if ns.API then
        if ns.API.RefreshAll then ns.API.RefreshAll() end
        if ns.API.ScanAvailableBuffs then ns.API.ScanAvailableBuffs() end
        if ns.API.ScanAvailableBarsWithDuration then ns.API.ScanAvailableBarsWithDuration() end
      end
      
      if foundNew > 0 and ns.devMode then
        print(string.format("|cff00FF00[ArcUI CDMEnhance]|r Delayed rescan (1.0s) found %d new frames", foundNew))
      end
    end
  end)
end

function ns.CDMEnhance.ScanCDM()
  if InCombatLockdown() then
    return 0, 0
  end
  
  -- MASTER TOGGLE: If disabled, don't scan - leaves addon "blind" to CDM frames
  local groupsDB = Shared.GetCDMGroupsDB()
  if groupsDB and groupsDB.enabled == false then
    return 0, 0
  end
  
  -- Clean up stale enhancedFrames entries BEFORE scan
  -- If a frame was reassigned to a different cooldownID, remove the stale reference
  for cdID, data in pairs(enhancedFrames) do
    if data.frame then
      local frameCdID = data.frame.cooldownID
      -- Only remove if frame has a DIFFERENT valid cooldownID (was definitively reassigned)
      -- nil/0 means CDM hasn't set it yet, so don't remove
      if frameCdID and frameCdID ~= 0 and frameCdID ~= cdID then
        if ns.devMode then
          print(string.format("|cffFF6600[ArcUI]|r Pre-scan cleanup: frame for cdID %d was reassigned to %d", cdID, frameCdID))
        end
        enhancedFrames[cdID] = nil
      elseif not IsFrameValid(data.frame) then
        -- Frame is invalid (destroyed) - clear frame reference
        if ns.devMode then
          print(string.format("|cffFF6600[ArcUI]|r Pre-scan cleanup: frame for cdID %d is invalid", cdID))
        end
        data.frame = nil
      end
    end
  end
  
  -- Call central scanner (which will call OnCDMScanComplete when done)
  local total = ns.API and ns.API.ScanAllCDMIcons() or 0
  
  -- Return counts
  local auraCount, cdCount = ns.API and ns.API.GetCDMIconCount() or 0, 0
  return auraCount, cdCount
end

-- ===================================================================
-- PUBLIC API
-- ===================================================================

-- Force CDM to create all frames for enabled cooldowns
-- CDM lazily creates frames, so we need to call GetItemContainerFrame to ensure they exist
function ns.CDMEnhance.ForceCDMFrameCreation()
  local viewerNames = {"BuffIconCooldownViewer", "EssentialCooldownViewer", "UtilityCooldownViewer"}
  local totalCreated = 0
  
  for _, viewerName in ipairs(viewerNames) do
    local viewer = _G[viewerName]
    if viewer and viewer.GetCooldownIDs and viewer.GetItemContainerFrame then
      local cooldownIDs = viewer:GetCooldownIDs()
      if cooldownIDs then
        for _, cdID in ipairs(cooldownIDs) do
          -- This call creates the frame if it doesn't exist
          local frame = viewer:GetItemContainerFrame(cdID)
          if frame then
            totalCreated = totalCreated + 1
          end
        end
      end
    end
  end
  
  if ns.devMode then
    print(string.format("|cff00FFFF[ArcUI]|r ForceCDMFrameCreation: triggered %d frames", totalCreated))
  end
  
  return totalCreated
end

-- Force show all CDM icons (called by CDMGroups after spec change)
function ns.CDMEnhance.ForceShowAllCDMIcons()
  local viewerNames = {"BuffIconCooldownViewer", "EssentialCooldownViewer", "UtilityCooldownViewer"}
  local shownCount = 0
  
  for _, viewerName in ipairs(viewerNames) do
    local viewer = _G[viewerName]
    if viewer then
      local children = {viewer:GetChildren()}
      for _, child in ipairs(children) do
        if child.cooldownID and child.cooldownID ~= 0 then
          child:SetAlpha(1)
          child:Show()
          shownCount = shownCount + 1
        end
      end
    end
  end
  
  -- Also show frames that might be parented to UIParent (free position icons)
  -- BUT only if they're ACTUALLY tracked as free icons in CDMGroups!
  for cdID, data in pairs(enhancedFrames) do
    if data.frame and IsFrameValid(data.frame) then
      local parent = data.frame:GetParent()
      if parent == UIParent then
        -- Only show UIParent frames if CDMGroups is tracking them as free icons
        if ns.CDMGroups and ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cdID] then
          data.frame:SetAlpha(1)
          data.frame:Show()
        end
        -- Otherwise skip - it's an orphaned frame from spec change
      else
        -- Frame is in a CDM viewer or group container, safe to show
        data.frame:SetAlpha(1)
        data.frame:Show()
      end
    end
  end
  
  if ns.devMode then
    print(string.format("|cff00FF00[ArcUI]|r ForceShowAllCDMIcons: showed %d viewer frames + enhanced frames", shownCount))
  end
end

-- Export UpdateOverlayState for CDMGroups to call when drag mode changes
function ns.CDMEnhance.UpdateOverlayStateForFrame(frame)
  if frame then
    UpdateOverlayState(frame)
  end
end

function ns.CDMEnhance.SetUnlocked(val)
  isUnlocked = val
  local db = GetDB()
  if db then db.unlocked = val end
  
  -- Sync dragModeEnabled with CDMGroups
  if ns.CDMGroups then
    ns.CDMGroups.dragModeEnabled = val
  end
  
  -- Update all enhanced frames overlay states
  for cdID, data in pairs(enhancedFrames) do
    if data.frame then
      UpdateOverlayState(data.frame)
    end
  end
  
  -- Also update CDMGroups managed icons and setup drag handlers
  if ns.CDMGroups and ns.CDMGroups.groups then
    for groupName, group in pairs(ns.CDMGroups.groups) do
      if group.members then
        for cdID, member in pairs(group.members) do
          if member and member.frame then
            UpdateOverlayState(member.frame)
            if val and group.SetupMemberDrag then
              group:SetupMemberDrag(cdID)
            end
          end
        end
      end
    end
  end
  
  -- Update free icons
  if ns.CDMGroups and ns.CDMGroups.freeIcons then
    for cdID, data in pairs(ns.CDMGroups.freeIcons) do
      if data.frame then
        UpdateOverlayState(data.frame)
        if val and ns.CDMGroups.SetupFreeIconDrag then
          ns.CDMGroups.SetupFreeIconDrag(cdID)
        end
      end
    end
  end
  
  -- Refresh click-through state (ShouldMakeClickThrough now checks dragModeEnabled)
  if ns.CDMGroups and ns.CDMGroups.RefreshIconSettings then
    ns.CDMGroups.RefreshIconSettings()
  end
end

function ns.CDMEnhance.IsUnlocked()
  return isUnlocked
end

function ns.CDMEnhance.ToggleUnlock()
  ns.CDMEnhance.SetUnlocked(not isUnlocked)
end

function ns.CDMEnhance.SetTextDragMode(val)
  textDragMode = val
  local db = GetDB()
  if db then db.textDragMode = val end
  
  for cdID, data in pairs(enhancedFrames) do
    UpdateTextDragOverlays(data.frame)
    -- Also update preview text since it depends on text drag mode
    local cfg = GetIconSettings(cdID)
    if cfg then
      UpdatePreviewText(data.frame, cdID, cfg)
      UpdatePreviewGlow(data.frame, cdID, cfg)
    end
  end
  
end

function ns.CDMEnhance.IsTextDragMode()
  return textDragMode
end

function ns.CDMEnhance.ToggleTextDragMode()
  ns.CDMEnhance.SetTextDragMode(not textDragMode)
end

-- ===================================================================
-- COOLDOWN PREVIEW MODE
-- Shows a fake cooldown animation for previewing swipe settings
-- ===================================================================
local function ApplyCooldownPreview(frame, cdID, enable)
  if not frame or not frame.Cooldown then return end
  
  -- Don't preview if Masque controls cooldowns (the options should be hidden anyway)
  if ns.Masque and ns.Masque.ShouldMasqueControlCooldowns and ns.Masque.ShouldMasqueControlCooldowns() then
    return
  end
  
  if enable then
    -- Store that this is a preview so we don't interfere with real cooldowns
    frame._arcSwipePreviewActive = true
    
    -- Get icon settings to apply proper swipe styling
    local cfg = GetIconSettings(cdID)
    local swipeCfg = cfg and cfg.cooldownSwipe
    
    -- Apply swipe settings
    if swipeCfg then
      frame.Cooldown:SetDrawSwipe(swipeCfg.showSwipe ~= false)
      frame.Cooldown:SetDrawEdge(swipeCfg.showEdge ~= false)
      frame.Cooldown:SetDrawBling(swipeCfg.showBling ~= false)
      frame.Cooldown:SetReverse(swipeCfg.reverse == true)
      
      -- Hide/show CooldownFlash frame based on bling setting (alpha-only approach)
      if frame.CooldownFlash then
        if swipeCfg.showBling == false then
          frame.CooldownFlash:SetAlpha(0)
          if frame.CooldownFlash.Flipbook then
            frame.CooldownFlash.Flipbook:SetAlpha(0)
          end
          if frame.CooldownFlash.FlashAnim and frame.CooldownFlash.FlashAnim.Stop then
            frame.CooldownFlash.FlashAnim:Stop()
          end
          frame._arcHideCooldownFlash = true
        else
          -- Re-enable CooldownFlash - clear flag and restore parent frame visibility
          frame._arcHideCooldownFlash = false
          -- Restore parent frame to visible so child animations can be seen
          frame.CooldownFlash:SetAlpha(1)
        end
      end
      
      -- Apply swipe color - use custom if set, otherwise default black
      -- Note: Preview only runs when ArcUI controls cooldowns (Masque check at top of function)
      if swipeCfg.swipeColor then
        local sc = swipeCfg.swipeColor
        frame.Cooldown:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
      else
        -- Default black swipe overlay
        frame.Cooldown:SetSwipeColor(0, 0, 0, 0.7)
      end
      
      if swipeCfg.edgeScale and frame.Cooldown.SetEdgeScale then
        frame.Cooldown:SetEdgeScale(swipeCfg.edgeScale)
      end
      
      if swipeCfg.edgeColor and frame.Cooldown.SetEdgeColor then
        local ec = swipeCfg.edgeColor
        frame.Cooldown:SetEdgeColor(ec.r or 1, ec.g or 1, ec.b or 1, ec.a or 1)
      end
    else
      -- No swipe config at all - use defaults
      frame.Cooldown:SetDrawSwipe(true)
      frame.Cooldown:SetDrawEdge(true)
      frame.Cooldown:SetSwipeColor(0, 0, 0, 0.7)
    end
    
    -- Apply swipe inset for preview
    local swipeInsetX, swipeInsetY = 0, 0
    if swipeCfg then
      if swipeCfg.separateInsets then
        swipeInsetX = swipeCfg.swipeInsetX or 0
        swipeInsetY = swipeCfg.swipeInsetY or 0
      else
        local inset = swipeCfg.swipeInset or 0
        swipeInsetX = inset
        swipeInsetY = inset
      end
    end
    
    -- Calculate total padding for cooldown swipe
    -- When Masque is active, skip icon padding (Masque controls icon)
    -- but still apply our swipe inset
    local basePadding = cfg and cfg.padding or 0
    local masqueActive = ns.Masque and ns.Masque.IsMasqueActiveForType and 
      ns.Masque.IsMasqueActiveForType(enhancedFrames[cdID] and enhancedFrames[cdID].viewerType or "cooldown")
    if masqueActive then
      basePadding = 0  -- Don't add icon padding when Masque controls icon
    end
    local totalPadX = basePadding + swipeInsetX
    local totalPadY = basePadding + swipeInsetY
    
    -- Apply our cooldown positioning with inset
    frame.Cooldown:ClearAllPoints()
    frame.Cooldown:SetPoint("TOPLEFT", frame, "TOPLEFT", totalPadX, -totalPadY)
    frame.Cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -totalPadX, totalPadY)
    
    -- Set a 30 second cooldown starting now for preview
    local now = GetTime()
    frame.Cooldown:SetCooldown(now, 30)
    frame.Cooldown:Show()
    frame.Cooldown:SetAlpha(1)
    
    -- MASQUE OVERRIDE: Re-apply our cooldown positioning after SetCooldown/Show
    -- Masque hooks these methods and may reposition the cooldown frame
    frame.Cooldown:ClearAllPoints()
    frame.Cooldown:SetPoint("TOPLEFT", frame, "TOPLEFT", totalPadX, -totalPadY)
    frame.Cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -totalPadX, totalPadY)
    
    -- Also re-apply after a short delay to catch any deferred Masque updates
    C_Timer.After(0.05, function()
      if frame and frame.Cooldown and frame._arcSwipePreviewActive then
        frame.Cooldown:ClearAllPoints()
        frame.Cooldown:SetPoint("TOPLEFT", frame, "TOPLEFT", totalPadX, -totalPadY)
        frame.Cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -totalPadX, totalPadY)
      end
    end)
  else
    -- Clear the preview
    frame._arcSwipePreviewActive = nil
    frame.Cooldown:Clear()
  end
end

function ns.CDMEnhance.SetCooldownPreviewMode(val)
  cooldownPreviewMode = val
  
  -- Get all icons being edited (supports edit-all, multi-select, single select)
  local iconsToPreview = {}
  if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.GetAllIconsToUpdate then
    iconsToPreview = ns.CDMEnhanceOptions.GetAllIconsToUpdate()
  else
    -- Fallback to single selection
    local selectedAura, selectedCooldown
    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.GetSelectedIcon then
      selectedAura, selectedCooldown = ns.CDMEnhanceOptions.GetSelectedIcon()
    end
    if selectedAura then table.insert(iconsToPreview, selectedAura) end
    if selectedCooldown then table.insert(iconsToPreview, selectedCooldown) end
  end
  
  -- Build lookup table for quick checking
  local previewLookup = {}
  for _, cdID in ipairs(iconsToPreview) do
    previewLookup[cdID] = true
  end
  
  -- Apply preview to selected icons in enhancedFrames
  for cdID, data in pairs(enhancedFrames) do
    if previewLookup[cdID] and data.frame then
      ApplyCooldownPreview(data.frame, cdID, val)
    elseif data.frame and data.frame._arcSwipePreviewActive then
      -- Clear preview from non-selected icons
      ApplyCooldownPreview(data.frame, cdID, false)
    end
  end
  
  -- Also apply preview to Arc Auras frames
  if ns.ArcAuras and ns.ArcAuras.frames then
    for arcID, frame in pairs(ns.ArcAuras.frames) do
      if frame then
        if previewLookup[arcID] then
          ApplyCooldownPreview(frame, arcID, val)
        elseif frame._arcSwipePreviewActive then
          ApplyCooldownPreview(frame, arcID, false)
        end
      end
    end
  end
end

function ns.CDMEnhance.IsCooldownPreviewMode()
  return cooldownPreviewMode
end

function ns.CDMEnhance.ToggleCooldownPreviewMode()
  ns.CDMEnhance.SetCooldownPreviewMode(not cooldownPreviewMode)
end

-- Refresh preview on selected icons (called when selection changes or settings change)
function ns.CDMEnhance.RefreshCooldownPreview()
  if not cooldownPreviewMode then return end
  
  -- Get all icons being edited
  local iconsToPreview = {}
  if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.GetAllIconsToUpdate then
    iconsToPreview = ns.CDMEnhanceOptions.GetAllIconsToUpdate()
  else
    local selectedAura, selectedCooldown
    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.GetSelectedIcon then
      selectedAura, selectedCooldown = ns.CDMEnhanceOptions.GetSelectedIcon()
    end
    if selectedAura then table.insert(iconsToPreview, selectedAura) end
    if selectedCooldown then table.insert(iconsToPreview, selectedCooldown) end
  end
  
  -- Build lookup table
  local previewLookup = {}
  for _, cdID in ipairs(iconsToPreview) do
    previewLookup[cdID] = true
  end
  
  -- Refresh enhancedFrames
  for cdID, data in pairs(enhancedFrames) do
    if data.frame then
      if previewLookup[cdID] then
        ApplyCooldownPreview(data.frame, cdID, true)
      elseif data.frame._arcSwipePreviewActive then
        ApplyCooldownPreview(data.frame, cdID, false)
      end
    end
  end
  
  -- Also refresh Arc Auras frames
  if ns.ArcAuras and ns.ArcAuras.frames then
    for arcID, frame in pairs(ns.ArcAuras.frames) do
      if frame then
        if previewLookup[arcID] then
          ApplyCooldownPreview(frame, arcID, true)
        elseif frame._arcSwipePreviewActive then
          ApplyCooldownPreview(frame, arcID, false)
        end
      end
    end
  end
end

-- These now just check/set the master toggle in cdmGroups.enabled
function ns.CDMEnhance.SetAuraCustomizationEnabled(val)
  -- Now handled by master toggle
  local db = Shared.GetCDMGroupsDB()
  if db then
    db.enabled = val
    if not val and ns.CDMGroups and ns.CDMGroups.ReleaseAllIcons then
      ns.CDMGroups.ReleaseAllIcons()
    end
  end
end

function ns.CDMEnhance.IsAuraCustomizationEnabled()
  -- Check master toggle
  local db = Shared.GetCDMGroupsDB()
  return db and db.enabled ~= false
end

function ns.CDMEnhance.SetCooldownCustomizationEnabled(val)
  -- Now handled by master toggle
  local db = Shared.GetCDMGroupsDB()
  if db then
    db.enabled = val
    if not val and ns.CDMGroups and ns.CDMGroups.ReleaseAllIcons then
      ns.CDMGroups.ReleaseAllIcons()
    end
  end
end

function ns.CDMEnhance.IsCooldownCustomizationEnabled()
  -- Check master toggle
  local db = Shared.GetCDMGroupsDB()
  return db and db.enabled ~= false
end

function ns.CDMEnhance.GetIconSettings(cdID)
  return GetIconSettings(cdID)
end

-- Get effective icon settings (merged: defaults -> global -> per-icon)
function ns.CDMEnhance.GetEffectiveIconSettings(cdID)
  return GetEffectiveIconSettings(cdID)
end

-- Get or create per-icon settings (for setters - creates sparse entry when needed)
function ns.CDMEnhance.GetOrCreateIconSettings(cdID)
  return GetOrCreateIconSettings(cdID)
end

-- Get global settings for a type (aura or cooldown)
function ns.CDMEnhance.GetGlobalSettings(iconType)
  local db = GetDB()
  if not db then return nil end
  
  if iconType == "aura" then
    return db.globalAuraSettings or {}
  else
    return db.globalCooldownSettings or {}
  end
end

-- Set a global setting value
function ns.CDMEnhance.SetGlobalSetting(iconType, path, value)
  local db = GetDB()
  if not db then return end
  
  local globalSettings
  if iconType == "aura" then
    if not db.globalAuraSettings then db.globalAuraSettings = {} end
    globalSettings = db.globalAuraSettings
  else
    if not db.globalCooldownSettings then db.globalCooldownSettings = {} end
    globalSettings = db.globalCooldownSettings
  end
  
  -- Handle nested paths like "procGlow.enabled"
  local parts = {strsplit(".", path)}
  local target = globalSettings
  for i = 1, #parts - 1 do
    if not target[parts[i]] then target[parts[i]] = {} end
    target = target[parts[i]]
  end
  target[parts[#parts]] = value
  
  -- Invalidate the effective settings cache so icons get new merged values
  InvalidateEffectiveSettingsCache()
end

-- Refresh all icons of a type after global setting change
function ns.CDMEnhance.RefreshIconType(iconType)
  -- Rescan to ensure all frames are captured (utility frames might appear later)
  if not InCombatLockdown() then
    ns.CDMEnhance.ScanCDM()
  end
  
  InvalidateEffectiveSettingsCache()
  
  -- Helper to clear all cached visual state flags so ApplyCooldownStateVisuals recalculates
  local function ClearFrameVisualFlags(frame)
    if frame then
      frame._arcTargetAlpha = nil
      frame._arcTargetDesat = nil
      frame._arcTargetTint = nil
      frame._arcTargetGlow = nil
      frame._arcCurrentGlowSig = nil
      frame._arcCooldownEventDriven = nil
    end
  end
  
  -- Also refresh CDMGroups frames that might not be in enhancedFrames yet
  if ns.CDMGroups then
    -- Refresh group members
    for groupName, group in pairs(ns.CDMGroups.groups or {}) do
      if group.members then
        for cdID, member in pairs(group.members) do
          if member.frame then
            local vType = member.viewerType or "aura"
            local isAura = vType == "aura"
            local isCooldown = vType == "cooldown" or vType == "utility"
            local shouldRefresh = (iconType == "aura" and isAura) or (iconType == "cooldown" and isCooldown) or iconType == "all"
            
            if shouldRefresh then
              -- CRITICAL: Clear visual flags so ApplyCooldownStateVisuals recalculates
              ClearFrameVisualFlags(member.frame)
              ApplyIconStyle(member.frame, cdID)
              -- ALWAYS apply state visuals to ensure desaturation is cleared/applied
              local cfg = GetEffectiveIconSettingsForFrame(member.frame)
              if cfg then
                ApplyCooldownStateVisuals(member.frame, cfg, cfg.alpha or 1.0)
              end
            end
          end
        end
      end
    end
    
    -- Refresh free icons
    for cdID, data in pairs(ns.CDMGroups.freeIcons or {}) do
      if data.frame then
        local vType = data.viewerType or "aura"
        local isAura = vType == "aura"
        local isCooldown = vType == "cooldown" or vType == "utility"
        local shouldRefresh = (iconType == "aura" and isAura) or (iconType == "cooldown" and isCooldown) or iconType == "all"
        
        if shouldRefresh then
          -- CRITICAL: Clear visual flags so ApplyCooldownStateVisuals recalculates
          ClearFrameVisualFlags(data.frame)
          ApplyIconStyle(data.frame, cdID)
          local cfg = GetEffectiveIconSettingsForFrame(data.frame)
          if cfg then
            ApplyCooldownStateVisuals(data.frame, cfg, cfg.alpha or 1.0)
          end
        end
      end
    end
  end
  
  -- Refresh enhancedFrames
  for cdID, data in pairs(enhancedFrames) do
    -- "cooldown" type refreshes both essential AND utility cooldowns
    local isAura = data.viewerType == "aura"
    local isCooldown = data.viewerType == "cooldown" or data.viewerType == "utility"
    local shouldRefresh = (iconType == "aura" and isAura) or (iconType == "cooldown" and isCooldown) or iconType == "all"
    
    if shouldRefresh and data.frame then
      -- CRITICAL: Clear visual flags so ApplyCooldownStateVisuals recalculates
      ClearFrameVisualFlags(data.frame)
      ApplyIconStyle(data.frame, cdID)
      -- ALWAYS apply state visuals to ensure desaturation is cleared/applied
      local cfg = GetEffectiveIconSettingsForFrame(data.frame)
      if cfg then
        ApplyCooldownStateVisuals(data.frame, cfg, cfg.alpha or 1.0)
      end
    end
  end
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- CRITICAL: Also refresh Arc Auras frames
  -- Arc Auras has its own frame system separate from CDMGroups/enhancedFrames
  -- When aura settings change (aspect ratio, zoom, etc.), we must notify ArcAuras
  -- 
  -- NOTE: Use RefreshAllSettings() NOT RefreshAllFrames()!
  -- RefreshAllFrames() is DESTRUCTIVE - it destroys and recreates frames
  -- RefreshAllSettings() just updates visual settings without losing positions
  -- ═══════════════════════════════════════════════════════════════════════════
  if (iconType == "aura" or iconType == "all") and ns.ArcAuras then
    if ns.ArcAuras.RefreshAllSettings then
      ns.ArcAuras.RefreshAllSettings()
    end
  end
end

-- Reset icon settings to defaults (removes all custom styling)
-- Now using spec-based storage
function ns.CDMEnhance.ResetIconToDefaults(cdID)
  Shared.ClearIconSettings(cdID)
  -- Invalidate cache so icon picks up global settings
  InvalidateEffectiveSettingsCache()
  -- Refresh the icon
  ns.CDMEnhance.UpdateIcon(cdID)
end

-- Check if an icon has per-icon customizations
-- Now using spec-based storage
function ns.CDMEnhance.HasPerIconSettings(cdID)
  local settings = Shared.GetIconSettings(cdID)
  
  -- Check if there are any actual settings stored
  if not settings then return false end
  if not next(settings) then return false end
  
  -- Check if there's anything meaningful (not just empty sub-tables)
  for k, v in pairs(settings) do
    if type(v) ~= "table" then
      -- Found a non-table value (like scale, alpha, etc.)
      return true
    elseif next(v) then
      -- Found a non-empty sub-table
      return true
    end
  end
  
  return false
end

-- Get raw per-icon settings (not merged with defaults) for checking customizations
-- Now using spec-based storage
function ns.CDMEnhance.GetRawPerIconSettings(cdID)
  return Shared.GetIconSettings(cdID)
end

-- Check if any of the specified fields are customized for an icon
-- fields can be top-level keys or deep dot notation like "a.b.c"
function ns.CDMEnhance.HasSectionCustomizations(cdID, fields)
  local raw = ns.CDMEnhance.GetRawPerIconSettings(cdID)
  if not raw then return false end
  
  -- Helper to traverse nested tables using dot notation
  local function getNestedValue(tbl, path)
    local current = tbl
    for key in path:gmatch("[^.]+") do
      if type(current) ~= "table" then return nil end
      current = current[key]
      if current == nil then return nil end
    end
    return current
  end
  
  for _, field in ipairs(fields) do
    local value = getNestedValue(raw, field)
    if value ~= nil then
      -- For tables, check if they have any content
      if type(value) == "table" then
        if next(value) then
          return true
        end
      else
        return true
      end
    end
  end
  
  return false
end

-- Reset all icons of a type to defaults
-- Now using spec-based storage
function ns.CDMEnhance.ResetAllIconsToDefaults(iconType)
  local iconSettings = Shared.GetSpecIconSettings()
  if not iconSettings then return end
  
  local allIcons = ns.API and ns.API.GetAllCDMIcons() or {}
  local count = 0
  for cdID, data in pairs(allIcons) do
    -- "cooldown" type should reset both essential AND utility
    local shouldReset = false
    if not iconType or iconType == "all" then
      shouldReset = true
    elseif iconType == "cooldown" and not data.isAura then
      shouldReset = true
    elseif iconType == "aura" and data.isAura then
      shouldReset = true
    end
    
    if shouldReset then
      iconSettings[tostring(cdID)] = nil
      count = count + 1
    end
  end
  
  -- Invalidate cache so icons pick up global settings
  InvalidateEffectiveSettingsCache()
  ns.CDMEnhance.Refresh()
  return count
end

-- Reset global defaults for a type (aura or cooldown)
function ns.CDMEnhance.ResetGlobalDefaults(iconType)
  local db = GetDB()
  if not db then return end
  
  if iconType == "aura" then
    db.globalAuraSettings = {}
  elseif iconType == "cooldown" then
    db.globalCooldownSettings = {}
  else
    -- Reset both
    db.globalAuraSettings = {}
    db.globalCooldownSettings = {}
  end
  
  -- Invalidate cache and refresh icons
  InvalidateEffectiveSettingsCache()
  ns.CDMEnhance.RefreshIconType(iconType or "all")
end

-- Invalidate settings cache (call after changing settings)
function ns.CDMEnhance.InvalidateCache()
  InvalidateEffectiveSettingsCache()
  
  -- Refresh cached enabled state in case toggle changed
  RefreshCachedEnabledState()
  
  -- Clear cached alpha/desat/tint/glow and cfg on all CDM frames so they recalculate with new settings
  for cdID, data in pairs(enhancedFrames) do
    if data and data.frame then
      data.frame._arcTargetAlpha = nil
      data.frame._arcTargetDesat = nil
      data.frame._arcTargetTint = nil
      data.frame._arcTargetGlow = nil
      data.frame._arcCooldownEventDriven = nil  -- Force re-evaluation
      data.frame._arcCfg = nil                   -- Clear frame-level cfg cache
      data.frame._arcCfgVersion = nil
      data.frame._arcCfgCdID = nil
      data.frame._arcCurrentGlowSig = nil        -- Force glow restart with new settings
    end
  end
  
  -- Invalidate ArcAuras settings cache so it fetches fresh settings
  if ns.ArcAuras and ns.ArcAuras.InvalidateSettingsCache then
    ns.ArcAuras.InvalidateSettingsCache()  -- nil = clear all
  end
  
  -- Also clear cache on ArcAuras frames so they pick up new glow/visual settings
  if ns.ArcAuras and ns.ArcAuras.frames then
    for arcID, frame in pairs(ns.ArcAuras.frames) do
      if frame then
        frame._cachedStateVisuals = nil         -- Force stateVisuals refresh
        frame._arcTargetAlpha = nil
        frame._arcTargetDesat = nil
        frame._arcTargetTint = nil
        frame._arcTargetGlow = nil
        frame._arcCurrentGlowSig = nil          -- Force glow restart with new settings
        frame._arcReadyGlowActive = false       -- Reset glow state so it restarts
      end
    end
  end
end

-- Get current cache version (used by CDMGroups to validate cached dimensions)
-- Returns a number that increments each time the cache is invalidated
function ns.CDMEnhance.GetCacheVersion()
  return effectiveSettingsCacheVersion
end

-- Invalidate cache for a single icon (call when changing one icon's settings)
function ns.CDMEnhance.InvalidateIconCache(cdID)
  if not cdID then return end
  
  -- Clear effective settings cache for this icon
  if effectiveSettingsCache then
    effectiveSettingsCache[cdID] = nil
  end
  
  -- Invalidate ArcAuras settings cache for this icon
  if ns.ArcAuras and ns.ArcAuras.InvalidateSettingsCache then
    ns.ArcAuras.InvalidateSettingsCache(cdID)
  end
  
  -- Clear cached alpha/desat/tint/glow so frame recalculates
  local data = enhancedFrames[cdID]
  if data and data.frame then
    data.frame._arcTargetAlpha = nil
    data.frame._arcTargetDesat = nil
    data.frame._arcTargetTint = nil
    data.frame._arcTargetGlow = nil
    data.frame._arcCooldownEventDriven = nil  -- Force re-evaluation
    data.frame._arcCurrentGlowSig = nil       -- Force glow restart with new settings
  end
  
  -- Also clear cache on matching ArcAuras frame
  if ns.ArcAuras and ns.ArcAuras.frames then
    local frame = ns.ArcAuras.frames[cdID]
    if frame then
      frame._cachedStateVisuals = nil         -- Force stateVisuals refresh
      frame._arcTargetAlpha = nil
      frame._arcTargetDesat = nil
      frame._arcTargetTint = nil
      frame._arcTargetGlow = nil
      frame._arcCurrentGlowSig = nil          -- Force glow restart with new settings
      frame._arcReadyGlowActive = false       -- Reset glow state so it restarts
    end
  end
end

-- Check if ArcUI options panel is currently open
function ns.CDMEnhance.IsOptionsPanelOpen()
  -- Use cached value from Shared (updated every 0.25s, avoids expensive LibStub lookups)
  return Shared.IsOptionsPanelOpen()
end

-- Get the addon's group scale setting for a viewer type (1.0 if not set)
-- Now using spec-based storage
function ns.CDMEnhance.GetAddonGroupScale(viewerType)
  local groupSettings = Shared.GetGroupSettingsForType(viewerType)
  if not groupSettings then return 1.0 end
  return groupSettings.scale or 1.0
end

-- Get the current group scale for a viewer type
-- For grouped icons: returns addon scale only (CDM's SetScale multiplies on top)
-- For legacy compatibility
function ns.CDMEnhance.GetGroupScale(viewerType)
  return ns.CDMEnhance.GetAddonGroupScale(viewerType)
end

-- Get combined scale (Edit Mode * Addon) - used for free position icons
-- Free position icons are parented to UIParent so they don't get CDM's SetScale
-- We need to apply both scales via SetSize
function ns.CDMEnhance.GetCombinedGroupScale(viewerType)
  local editModeScale = groupScales[viewerType] or 1.0
  local addonScale = ns.CDMEnhance.GetAddonGroupScale(viewerType)
  return editModeScale * addonScale
end

-- Apply group scale to a specific icon (used when toggling useGroupScale on)
function ns.CDMEnhance.ApplyGroupScaleToIcon(cdID)
  local data = enhancedFrames[cdID]
  if not data or not data.frame then return end
  
  -- Invalidate cache so settings are re-read
  InvalidateEffectiveSettingsCache()
  
  -- Tell CDMGroups to update this icon's size and position
  -- OnIconSizeChanged handles both useGroupScale ON and OFF cases
  if ns.CDMGroups and ns.CDMGroups.OnIconSizeChanged then
    ns.CDMGroups.OnIconSizeChanged(cdID)
  end
  
  -- Re-apply icon style (texcoords, padding, etc.)
  ApplyIconStyle(data.frame, cdID)
end

function ns.CDMEnhance.UpdateIcon(cdID)
  local data = enhancedFrames[cdID]
  
  -- Verify the frame reference is still valid and pointing to the right cooldown
  if data and data.frame then
    -- Check if frame still exists and has the right cooldownID
    if not data.frame.cooldownID or data.frame.cooldownID ~= cdID then
      -- Frame reference is stale, clear it
      data = nil
      enhancedFrames[cdID] = nil
    end
  end
  
  -- If not in enhancedFrames or stale, find the frame directly
  if not data or not data.frame then
    -- FIRST: Check CDMGroups containers (frames may have been reparented)
    if ns.CDMGroups then
      -- Check group containers
      if ns.CDMGroups.groups then
        for groupName, group in pairs(ns.CDMGroups.groups) do
          if group.members and group.members[cdID] then
            local member = group.members[cdID]
            if member.frame and member.frame.cooldownID == cdID then
              local viewerType = member.viewerType or "aura"
              local viewerName = member.originalViewerName or "BuffIconCooldownViewer"
              EnhanceFrame(member.frame, cdID, viewerType, viewerName)
              data = enhancedFrames[cdID]
              break
            end
          end
        end
      end
      
      -- Check free icons
      if (not data or not data.frame) and ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[cdID] then
        local freeData = ns.CDMGroups.freeIcons[cdID]
        if freeData.frame and freeData.frame.cooldownID == cdID then
          local viewerType = freeData.viewerType or "aura"
          local viewerName = freeData.originalViewerName or "BuffIconCooldownViewer"
          EnhanceFrame(freeData.frame, cdID, viewerType, viewerName)
          data = enhancedFrames[cdID]
        end
      end
    end
    
    -- SECOND: Try to find in BuffIconCooldownViewer
    if not data or not data.frame then
      local viewer = _G["BuffIconCooldownViewer"]
      if viewer then
        for _, frame in ipairs({viewer:GetChildren()}) do
          if frame.cooldownID == cdID then
            -- Enhance it now if we found it
            EnhanceFrame(frame, cdID, "aura", "BuffIconCooldownViewer")
            data = enhancedFrames[cdID]
            break
          end
        end
      end
    end
    
    -- THIRD: Try cooldown viewers if still not found
    if not data or not data.frame then
      local cdViewers = {
        {name = "EssentialCooldownViewer", viewerType = "cooldown"},
        {name = "UtilityCooldownViewer", viewerType = "utility"},
      }
      for _, viewerInfo in ipairs(cdViewers) do
        local cdViewer = _G[viewerInfo.name]
        if cdViewer then
          for _, frame in ipairs({cdViewer:GetChildren()}) do
            if frame.cooldownID == cdID then
              EnhanceFrame(frame, cdID, viewerInfo.viewerType, viewerInfo.name)
              data = enhancedFrames[cdID]
              break
            end
          end
        end
        if data and data.frame then break end
      end
    end
  end
  
  if data and data.frame then
    -- Clear glow signature to force restart with new settings
    data.frame._arcCurrentGlowSig = nil
    
    ApplyIconStyle(data.frame, cdID)
    
    -- Re-evaluate glow state (for preview toggle, etc.)
    ns.CDMEnhance.ApplyIconVisuals(data.frame)
    
    -- Trigger immediate CDMGroups layout refresh if icon is in a group
    if ns.CDMGroups and ns.CDMGroups.RefreshIconLayout then
      ns.CDMGroups.RefreshIconLayout(cdID)
    end
    
    -- Recreate text drag overlays if needed
    local cfg = GetIconSettings(cdID)
    if cfg then
      if data.frame._arcChargeText then
        CreateTextDragOverlay(data.frame._arcChargeText, data.frame, cdID, "charge")
      end
      -- Arc Auras Count text
      if data.frame.Count and (data.frame._arcConfig or data.frame._arcAuraID) then
        CreateTextDragOverlay(data.frame.Count, data.frame, cdID, "charge")
      end
      if data.frame._arcCooldownText then
        CreateTextDragOverlay(data.frame._arcCooldownText, data.frame, cdID, "cooldown")
      end
    end
    
    UpdateTextDragOverlays(data.frame)
  end
end

function ns.CDMEnhance.GetAuraIcons()
  -- MASTER TOGGLE: Return empty if CDM styling is disabled
  local groupsDB = Shared.GetCDMGroupsDB()
  if groupsDB and groupsDB.enabled == false then
    return {}
  end
  
  local result = {}
  
  -- First try the API if available
  local allIcons = ns.API and ns.API.GetCDMAuraIcons and ns.API.GetCDMAuraIcons() or {}
  
  for cdID, data in pairs(allIcons) do
    -- Skip BuffBarCooldownViewer frames - we only want icons, not bars
    local viewerName = data.viewerName or ""
    if viewerName ~= "BuffBarCooldownViewer" then
      -- Get frame for icon texture retrieval
      local frame = nil
      local displaySpellID = data.spellID
      local overrideTooltipSpellID = nil
      local frameData = enhancedFrames[cdID]
      -- VERIFY: Only use enhancedFrames data if frame.cooldownID matches cdID
      if frameData and frameData.frame and frameData.frame.cooldownID == cdID then
        frame = frameData.frame
        local cooldownInfo = frame.cooldownInfo
        if cooldownInfo then
          if cooldownInfo.overrideSpellID then
            displaySpellID = cooldownInfo.overrideSpellID
          end
          -- Get overrideTooltipSpellID - this is what CDM uses for display
          overrideTooltipSpellID = cooldownInfo.overrideTooltipSpellID
        end
      end
      
      -- Use helper to get icon texture (reads from frame first, then API)
      local icon = GetIconTextureFromFrame(frame, true, data.spellID, displaySpellID, displaySpellID, overrideTooltipSpellID)
      
      -- Check if this is a totem-based icon
      local isTotem, isTotemActive, totemSlot = false, false, nil
      if frame then
        isTotem, isTotemActive, totemSlot = GetTotemState(frame)
      end
      
      result[cdID] = {
        cooldownID = cdID,
        spellID = data.spellID,
        overrideSpellID = displaySpellID ~= data.spellID and displaySpellID or nil,
        name = displaySpellID and C_Spell.GetSpellName(displaySpellID) or data.name or "Unknown",
        icon = icon,
        hasCustomPos = HasCustomPosition(cdID),
        viewerName = viewerName,
        isTotem = isTotem,
        totemSlot = totemSlot,
      }
    end
  end
  
  -- Also check enhancedFrames for aura icons (fallback/additional)
  -- CRITICAL: Verify frame.cooldownID matches cdID to avoid stale references
  for cdID, frameData in pairs(enhancedFrames) do
    if frameData.viewerType == "aura" and not result[cdID] then
      -- Skip BuffBarCooldownViewer
      local viewerName = frameData.viewerName or ""
      if viewerName ~= "BuffBarCooldownViewer" then
        local frame = frameData.frame
        -- VERIFY: frame.cooldownID must match cdID (skip stale entries)
        if frame and frame.cooldownID == cdID then
          local spellID = frame.spellID
          -- Check for overrideSpellID and overrideTooltipSpellID
          local displaySpellID = spellID
          local overrideTooltipSpellID = nil
          if frame.cooldownInfo then
            if frame.cooldownInfo.overrideSpellID then
              displaySpellID = frame.cooldownInfo.overrideSpellID
            end
            overrideTooltipSpellID = frame.cooldownInfo.overrideTooltipSpellID
          end
          local name = displaySpellID and C_Spell.GetSpellName(displaySpellID) or "Unknown"
          -- Use helper to get icon texture (reads from frame first)
          local icon = GetIconTextureFromFrame(frame, true, spellID, displaySpellID, displaySpellID, overrideTooltipSpellID)
          
          -- Check if this is a totem-based icon
          local isTotem, isTotemActive, totemSlot = GetTotemState(frame)
          
          result[cdID] = {
            cooldownID = cdID,
            spellID = spellID,
            overrideSpellID = displaySpellID ~= spellID and displaySpellID or nil,
            name = name,
            icon = icon,
            hasCustomPos = HasCustomPosition(cdID),
            viewerName = viewerName,
            isTotem = isTotem,
            totemSlot = totemSlot,
          }
        end
      end
    end
  end
  
  -- ALSO check CDMGroups containers - icons parented there won't be in CDM viewers
  if ns.CDMGroups and ns.CDMGroups.groups then
    for groupName, group in pairs(ns.CDMGroups.groups) do
      if group.members then
        for cdID, member in pairs(group.members) do
          if not result[cdID] and member.frame and member.frame.cooldownID == cdID then
            -- Only include aura icons (BuffIcon), not cooldowns
            local viewerType = member.viewerType
            local viewerName = member.originalViewerName
            
            -- Skip BuffBarCooldownViewer
            if viewerName == "BuffBarCooldownViewer" then
              -- Skip bars
            else
              -- Determine if this is an aura icon by checking CDM category or viewerType
              local isAuraIcon = false
              if viewerType == "aura" then
                isAuraIcon = true
              elseif viewerName == "BuffIconCooldownViewer" then
                isAuraIcon = true
              else
                -- Check CDM category as fallback (safe for Arc Aura string IDs)
                if cdID and cdID ~= 0 then
                  local cdInfo = Shared.SafeGetCDMInfo and Shared.SafeGetCDMInfo(cdID)
                  if cdInfo and Shared.IsAuraCategory(cdInfo.category) then
                    isAuraIcon = true
                    viewerName = "BuffIconCooldownViewer"
                  end
                end
              end
              
              if isAuraIcon then
                local frame = member.frame
                local spellID = frame.spellID
                local displaySpellID = spellID
                local overrideTooltipSpellID = nil
                if frame.cooldownInfo then
                  if frame.cooldownInfo.overrideSpellID then
                    displaySpellID = frame.cooldownInfo.overrideSpellID
                  end
                  overrideTooltipSpellID = frame.cooldownInfo.overrideTooltipSpellID
                end
                local name = displaySpellID and C_Spell.GetSpellName(displaySpellID) or "Unknown"
                -- Use helper to get icon texture (reads from frame first)
                local icon = GetIconTextureFromFrame(frame, true, spellID, displaySpellID, displaySpellID, overrideTooltipSpellID)
                
                -- Check if this is a totem-based icon
                local isTotem, isTotemActive, totemSlot = GetTotemState(frame)
                
                result[cdID] = {
                  cooldownID = cdID,
                  spellID = spellID,
                  overrideSpellID = displaySpellID ~= spellID and displaySpellID or nil,
                  name = name,
                  icon = icon,
                  hasCustomPos = true,
                  viewerName = viewerName or "BuffIconCooldownViewer",
                  isTotem = isTotem,
                  totemSlot = totemSlot,
                }
              end
            end
          end
        end
      end
    end
  end
  
  -- ALSO check CDMGroups.freeIcons - these are managed by CDMGroups but free-positioned
  if ns.CDMGroups and ns.CDMGroups.freeIcons then
    for cdID, data in pairs(ns.CDMGroups.freeIcons) do
      if not result[cdID] and data.frame and data.frame.cooldownID == cdID then
        local viewerType = data.viewerType
        local viewerName = data.originalViewerName
        
        -- Skip BuffBarCooldownViewer
        if viewerName ~= "BuffBarCooldownViewer" then
          -- Determine if this is an aura icon
          local isAuraIcon = false
          if viewerType == "aura" then
            isAuraIcon = true
          elseif viewerName == "BuffIconCooldownViewer" then
            isAuraIcon = true
          else
            -- Check CDM category as fallback (safe for Arc Aura string IDs)
            if cdID and cdID ~= 0 then
              local cdInfo = Shared.SafeGetCDMInfo and Shared.SafeGetCDMInfo(cdID)
              if cdInfo and Shared.IsAuraCategory(cdInfo.category) then
                isAuraIcon = true
                viewerName = "BuffIconCooldownViewer"
              end
            end
          end
          
          if isAuraIcon then
            local frame = data.frame
            local spellID = frame.spellID
            local displaySpellID = spellID
            local overrideTooltipSpellID = nil
            if frame.cooldownInfo then
              if frame.cooldownInfo.overrideSpellID then
                displaySpellID = frame.cooldownInfo.overrideSpellID
              end
              overrideTooltipSpellID = frame.cooldownInfo.overrideTooltipSpellID
            end
            local name = displaySpellID and C_Spell.GetSpellName(displaySpellID) or "Unknown"
            -- Use helper to get icon texture (reads from frame first)
            local icon = GetIconTextureFromFrame(frame, true, spellID, displaySpellID, displaySpellID, overrideTooltipSpellID)
            
            -- Check if this is a totem-based icon
            local isTotem, isTotemActive, totemSlot = GetTotemState(frame)
            
            result[cdID] = {
              cooldownID = cdID,
              spellID = spellID,
              overrideSpellID = displaySpellID ~= spellID and displaySpellID or nil,
              name = name,
              icon = icon,
              hasCustomPos = true,
              viewerName = viewerName or "BuffIconCooldownViewer",
              isTotem = isTotem,
              totemSlot = totemSlot,
            }
          end
        end
      end
    end
  end
  
  return result
end

-- Helper for Arc Aura catalog entries - delegates to ArcAuras module
local function CreateArcAuraEntry(cdID, frame)
    if ns.ArcAuras and ns.ArcAuras.CreateCatalogEntry then
        return ns.ArcAuras.CreateCatalogEntry(cdID, frame)
    end
    return nil
end

function ns.CDMEnhance.GetCooldownIcons()
  -- MASTER TOGGLE: Return empty if CDM styling is disabled
  local groupsDB = Shared.GetCDMGroupsDB()
  if groupsDB and groupsDB.enabled == false then
    return {}
  end
  
  local result = {}
  local allIcons = ns.API and ns.API.GetCDMCooldownIcons() or {}
  
  for cdID, data in pairs(allIcons) do
    -- Check for overrideSpellID in the frame's cooldownInfo
    local displaySpellID = data.spellID
    local frame = nil
    local frameData = enhancedFrames[cdID]
    -- VERIFY: Only use enhancedFrames data if frame.cooldownID matches cdID
    if frameData and frameData.frame and frameData.frame.cooldownID == cdID then
      frame = frameData.frame
      if frame.cooldownInfo then
        local overrideID = frame.cooldownInfo.overrideSpellID
        if overrideID and overrideID > 0 then
          displaySpellID = overrideID
        end
      end
    end
    
    -- Use helper to get icon texture (reads from frame first, isAura=false for cooldowns)
    local icon = GetIconTextureFromFrame(frame, false, data.spellID, displaySpellID, displaySpellID)
    
    result[cdID] = {
      cooldownID = cdID,
      spellID = data.spellID,
      overrideSpellID = displaySpellID ~= data.spellID and displaySpellID or nil,
      name = displaySpellID and C_Spell.GetSpellName(displaySpellID) or data.name or "Unknown",
      icon = icon,
      hasCustomPos = HasCustomPosition(cdID),
      viewerName = data.viewerName,
    }
  end
  
  -- ALSO check CDMGroups containers - icons parented there won't be in CDM viewers
  if ns.CDMGroups and ns.CDMGroups.groups then
    for groupName, group in pairs(ns.CDMGroups.groups) do
      if group.members then
        for cdID, member in pairs(group.members) do
          if not result[cdID] and member.frame and member.frame.cooldownID == cdID then
            -- Handle Arc Auras (string IDs) - item-based cooldowns
            if Shared.IsArcAuraID and Shared.IsArcAuraID(cdID) then
              local arcEntry = CreateArcAuraEntry(cdID, member.frame)
              if arcEntry then
                result[cdID] = arcEntry
              end
            else
              -- Only include cooldown icons (Essential/Utility), not auras
              local viewerType = member.viewerType
              local viewerName = member.originalViewerName
              
              -- Determine if this is a cooldown icon by checking CDM category or viewerType
              local isCooldownIcon = false
              if viewerType == "cooldown" or viewerType == "utility" then
                isCooldownIcon = true
              elseif viewerName == "EssentialCooldownViewer" or viewerName == "UtilityCooldownViewer" then
                isCooldownIcon = true
              else
                -- Check CDM category as fallback (safe for Arc Aura string IDs)
                if cdID and cdID ~= 0 then
                  local cdInfo = Shared.SafeGetCDMInfo and Shared.SafeGetCDMInfo(cdID)
                  if cdInfo and (cdInfo.category == 0 or cdInfo.category == 1) then
                    isCooldownIcon = true
                    -- Set viewerName based on category
                    viewerName = cdInfo.category == 0 and "EssentialCooldownViewer" or "UtilityCooldownViewer"
                  end
                end
              end
              
              if isCooldownIcon then
                local frame = member.frame
                local spellID = frame.spellID
                local displaySpellID = spellID
                if frame.cooldownInfo and frame.cooldownInfo.overrideSpellID then
                  displaySpellID = frame.cooldownInfo.overrideSpellID
                end
                local name = displaySpellID and C_Spell.GetSpellName(displaySpellID) or "Unknown"
                -- Use helper to get icon texture (reads from frame first, isAura=false for cooldowns)
                local icon = GetIconTextureFromFrame(frame, false, spellID, displaySpellID, displaySpellID)
                
                result[cdID] = {
                  cooldownID = cdID,
                  spellID = spellID,
                  overrideSpellID = displaySpellID ~= spellID and displaySpellID or nil,
                  name = name,
                  icon = icon,
                  hasCustomPos = true,
                  viewerName = viewerName or "EssentialCooldownViewer",
                }
              end
            end
          end
        end
      end
    end
  end
  
  -- ALSO check CDMGroups.freeIcons - these are managed by CDMGroups but free-positioned
  if ns.CDMGroups and ns.CDMGroups.freeIcons then
    for cdID, data in pairs(ns.CDMGroups.freeIcons) do
      if not result[cdID] and data.frame and data.frame.cooldownID == cdID then
        -- Handle Arc Auras (string IDs) - item-based cooldowns
        if Shared.IsArcAuraID and Shared.IsArcAuraID(cdID) then
          local arcEntry = CreateArcAuraEntry(cdID, data.frame)
          if arcEntry then
            result[cdID] = arcEntry
          end
        else
          local viewerType = data.viewerType
          local viewerName = data.originalViewerName
          
          -- Determine if this is a cooldown icon
          local isCooldownIcon = false
          if viewerType == "cooldown" or viewerType == "utility" then
            isCooldownIcon = true
          elseif viewerName == "EssentialCooldownViewer" or viewerName == "UtilityCooldownViewer" then
            isCooldownIcon = true
          else
            -- Check CDM category as fallback (safe for Arc Aura string IDs)
            if cdID and cdID ~= 0 then
              local cdInfo = Shared.SafeGetCDMInfo and Shared.SafeGetCDMInfo(cdID)
              if cdInfo and (cdInfo.category == 0 or cdInfo.category == 1) then
                isCooldownIcon = true
                viewerName = cdInfo.category == 0 and "EssentialCooldownViewer" or "UtilityCooldownViewer"
              end
            end
          end
          
          if isCooldownIcon then
            local frame = data.frame
            local spellID = frame.spellID
            local displaySpellID = spellID
            if frame.cooldownInfo and frame.cooldownInfo.overrideSpellID then
              displaySpellID = frame.cooldownInfo.overrideSpellID
            end
            local name = displaySpellID and C_Spell.GetSpellName(displaySpellID) or "Unknown"
            -- Use helper to get icon texture (reads from frame first, isAura=false for cooldowns)
            local icon = GetIconTextureFromFrame(frame, false, spellID, displaySpellID, displaySpellID)
            
            result[cdID] = {
              cooldownID = cdID,
              spellID = spellID,
              overrideSpellID = displaySpellID ~= spellID and displaySpellID or nil,
              name = name,
              icon = icon,
              hasCustomPos = true,
              viewerName = viewerName or "EssentialCooldownViewer",
            }
          end
        end
      end
    end
  end
  
  return result
end

function ns.CDMEnhance.Refresh()
  -- Rescan to ensure all frames are captured (utility frames might appear later)
  if not InCombatLockdown() then
    ns.CDMEnhance.ScanCDM()
  end
  
  for cdID, data in pairs(enhancedFrames) do
    ApplyIconStyle(data.frame, cdID)
    UpdateOverlayState(data.frame)
  end
end

-- Refresh overlay mouse states (called when options panel opens/closes)
function ns.CDMEnhance.RefreshOverlayMouseState()
  for cdID, data in pairs(enhancedFrames) do
    UpdateOverlayState(data.frame)
    -- Also update preview text and glow since they depend on options panel state
    local cfg = GetIconSettings(cdID)
    if cfg then
      UpdatePreviewText(data.frame, cdID, cfg)
      UpdatePreviewGlow(data.frame, cdID, cfg)
      -- Only refresh cooldown state visuals for frames that have custom settings.
      -- Frames without stateVisuals are managed by CDM natively — touching them
      -- would destructively override CDM's own desaturation/alpha.
      local sv = GetEffectiveStateVisuals(cfg)
      local ignAura = (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
                   or (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)
      if sv or ignAura then
        -- Clear cached alpha so it gets recalculated
        data.frame._arcTargetAlpha = nil
        data.frame._arcEnforceReadyAlpha = nil
        ApplyCooldownStateVisuals(data.frame, cfg, cfg.alpha or 1.0)
      end
    end
  end
end

function ns.CDMEnhance.ResetAllCooldownPositions()
  -- Reset all cooldown icons to group mode
  for cdID, data in pairs(enhancedFrames) do
    if (data.viewerType == "cooldown" or data.viewerType == "utility") and data.frame then
      ResetIconPosition(cdID)
    end
  end
end

function ns.CDMEnhance.ResetAllAuraPositions()
  -- Reset all aura icons to group mode
  for cdID, data in pairs(enhancedFrames) do
    if data.viewerType == "aura" and data.frame then
      ResetIconPosition(cdID)
    end
  end
end

-- Reset ALL icon positions (both auras and cooldowns)
function ns.CDMEnhance.ResetAllPositions()
  for cdID, data in pairs(enhancedFrames) do
    ResetIconPosition(cdID)
  end
end

-- Get first icon of a given type (for default X/Y display)
function ns.CDMEnhance.GetFirstIconOfType(viewerType)
  for cdID, data in pairs(enhancedFrames) do
    if data.viewerType == viewerType then
      return cdID
    end
  end
  return nil
end


-- ===================================================================
-- GROUP POSITION API - Delegates to CDMGroupSettings module
-- ===================================================================

-- Disable all drag options (called when options panel closes)
function ns.CDMEnhance.DisableAllDrags()
  -- Disable individual icon unlock (use SetUnlocked to save and refresh)
  if isUnlocked then
    ns.CDMEnhance.SetUnlocked(false)
  end
  
  -- Disable text drag mode too
  if textDragMode then
    ns.CDMEnhance.SetTextDragMode(false)
  end
  
  -- Hide group mover overlay
  if ns.CDMGroupSettings then
    ns.CDMGroupSettings.HideMoverOverlay()
    ns.CDMGroupSettings.HideSettingsDialog()
  end
  
  -- Refresh options panel to update toggle states
  if LibStub and LibStub("AceConfigRegistry-3.0", true) then
    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
  end
end

-- Clear slot base positions (called when group moves so they get recaptured)
-- Refresh all icon styles (called after Edit Mode/mover closes)
function ns.CDMEnhance.RefreshAllStyles()
  -- MASTER TOGGLE: Skip if disabled
  local groupsDB = Shared.GetCDMGroupsDB()
  if groupsDB and groupsDB.enabled == false then
    return
  end
  
  -- Invalidate cache first to ensure fresh settings from DB
  InvalidateEffectiveSettingsCache()
  
  for cdID, data in pairs(enhancedFrames) do
    if data.frame then
      -- NOTE: Scale/size/position handled by CDMGroups
      -- We only refresh visual styles (borders, glow, textures)
      ApplyIconStyle(data.frame, cdID)
      
      -- CRITICAL FIX: Also apply cooldown state visuals (ready state alpha, etc.)
      -- Without this, ready state alpha=0 is not applied until options panel is opened
      -- Clear cached alpha flags so they get recalculated from fresh settings
      data.frame._arcTargetAlpha = nil
      data.frame._arcEnforceReadyAlpha = nil
      local cfg = GetEffectiveIconSettingsForFrame(data.frame)
      if cfg then
        ApplyCooldownStateVisuals(data.frame, cfg, cfg.alpha or 1.0)
      end
    end
  end
  
  -- Refresh Masque skins after style changes
  -- Masque.RefreshAllGroups will re-apply our cooldown positioning after Masque finishes
  if ns.Masque and ns.Masque.QueueRefresh then
    ns.Masque.QueueRefresh()
  end
end

-- ===================================================================
-- ENHANCED FRAMES ACCESS (for Masque integration)
-- ===================================================================

--- Get the enhanced frames table (read-only access for external modules)
function ns.CDMEnhance.GetEnhancedFrames()
  return enhancedFrames
end

-- PER-ICON POSITION API (New system)
-- ===================================================================

-- Get position mode for a specific icon
function ns.CDMEnhance.GetIconPositionMode(cdID)
  -- Delegate to CDMGroups - it controls where icons are positioned
  if ns.CDMGroups and ns.CDMGroups.IsManaged then
    local isManaged, trackingType = ns.CDMGroups.IsManaged(cdID)
    if isManaged then
      return trackingType == "free" and "free" or "group"
    end
  end
  return "group"  -- Default to group if CDMGroups not loaded or icon not managed
end

-- Get icon position
function ns.CDMEnhance.GetIconPosition(cdID)
  -- Read position from CDMGroups for free positioned icons
  if ns.CDMGroups and ns.CDMGroups.freeIcons then
    local freeData = ns.CDMGroups.freeIcons[cdID]
    if freeData then
      return freeData.x or 0, freeData.y or 0
    end
  end
  return nil, nil  -- Not a free icon or CDMGroups not loaded
end

-- Set icon position (writes to CDMGroups free icon data)
function ns.CDMEnhance.SetIconPosition(cdID, x, y)
  -- Write position to CDMGroups for free positioned icons
  if ns.CDMGroups and ns.CDMGroups.freeIcons then
    local freeData = ns.CDMGroups.freeIcons[cdID]
    if freeData then
      -- Update the runtime position
      freeData.x = x or 0
      freeData.y = y or 0
      
      -- CRITICAL: Save to BOTH storage locations (like drag does)
      -- 1. profile.savedPositions (what LoadProfile reads from)
      local posData = {
        type = "free",
        x = x or 0,
        y = y or 0,
        iconSize = freeData.iconSize or 36,
        viewerType = freeData.viewerType,
      }
      if ns.CDMGroups.SavePositionToSpec then
        ns.CDMGroups.SavePositionToSpec(cdID, posData)
      end
      
      -- 2. profile.freeIcons (secondary storage)
      if ns.CDMGroups.SaveFreeIconToSpec then
        ns.CDMGroups.SaveFreeIconToSpec(cdID, { 
          x = x or 0, 
          y = y or 0, 
          iconSize = freeData.iconSize or 36 
        })
      end
      
      -- Apply position to frame if it exists
      if freeData.frame then
        freeData.frame:ClearAllPoints()
        freeData.frame:SetPoint("CENTER", UIParent, "CENTER", x or 0, y or 0)
      end
    end
  end
end

-- Reset a single icon's position to group mode
function ns.CDMEnhance.ResetIconPosition(cdID)
  ResetIconPosition(cdID)
end

-- ===================================================================
-- DEBUG SLASH COMMANDS
-- ===================================================================

-- Global debug flag
ArcUI_CDMEnhance_Debug = false
ArcUI_CDMEnhance_TintDebug = false

local function ShowDebugOutput(text)
  if not debugFrame then
    debugFrame = CreateFrame("Frame", "ArcCDMDebugFrame", UIParent, "BasicFrameTemplateWithInset")
    debugFrame:SetSize(600, 400)
    debugFrame:SetPoint("CENTER")
    debugFrame:SetMovable(true)
    debugFrame:EnableMouse(true)
    debugFrame:RegisterForDrag("LeftButton")
    debugFrame:SetScript("OnDragStart", debugFrame.StartMoving)
    debugFrame:SetScript("OnDragStop", debugFrame.StopMovingOrSizing)
    debugFrame.title = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    debugFrame.title:SetPoint("TOP", 0, -5)
    debugFrame.title:SetText("ArcUI CDM Debug - Select All & Copy")
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, debugFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(540)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scrollFrame:SetScrollChild(editBox)
    
    debugFrame.editBox = editBox
  end
  
  debugFrame.editBox:SetText(text)
  debugFrame.editBox:HighlightText()
  debugFrame.editBox:SetFocus()
  debugFrame:Show()
end

SLASH_ARCCDM1 = "/arccdm"
SlashCmdList["ARCCDM"] = function(msg)
  local args = {}
  for word in msg:gmatch("%S+") do
    table.insert(args, word)
  end
  local cmd = args[1] and args[1]:lower() or "help"
  
  if cmd == "debug" then
    ArcUI_CDMEnhance_Debug = not ArcUI_CDMEnhance_Debug
    DebugLog("|cff00FF00[ArcUI CDM]|r Debug: " .. (ArcUI_CDMEnhance_Debug and "ON" or "OFF"))
  
  elseif cmd == "tintdebug" then
    ArcUI_CDMEnhance_TintDebug = not ArcUI_CDMEnhance_TintDebug
    print("|cffFF8800[ArcUI CDM]|r Tint Debug: " .. (ArcUI_CDMEnhance_TintDebug and "ON" or "OFF"))
  
  elseif cmd == "fontdebug" then
    -- Debug font info for all tracked icons
    local db = GetDB()
    print("|cff00CCFF=== Font Debug ===|r")
    
    -- Show global settings
    if db and db.globalAuraSettings and db.globalAuraSettings.chargeText then
      print("|cffFFFF00Global Aura chargeText:|r")
      print("  font: " .. tostring(db.globalAuraSettings.chargeText.font))
      print("  size: " .. tostring(db.globalAuraSettings.chargeText.size))
    else
      print("|cffFFFF00Global Aura chargeText:|r (not set)")
    end
    
    if db and db.globalAuraSettings and db.globalAuraSettings.cooldownText then
      print("|cffFFFF00Global Aura cooldownText:|r")
      print("  font: " .. tostring(db.globalAuraSettings.cooldownText.font))
      print("  size: " .. tostring(db.globalAuraSettings.cooldownText.size))
    else
      print("|cffFFFF00Global Aura cooldownText:|r (not set)")
    end
    
    -- Show a few icons' effective settings and actual font
    print("|cffFFFF00Sample Icons:|r")
    local count = 0
    for cdID, data in pairs(enhancedFrames) do
      if data.frame and count < 3 then
        local cfg = GetEffectiveIconSettings(cdID)
        local chargeFont = cfg and cfg.chargeText and cfg.chargeText.font or "nil"
        local chargeFontPath = GetFontPath(chargeFont)
        local cdFont = cfg and cfg.cooldownText and cfg.cooldownText.font or "nil"
        
        -- Get actual font from fontstring
        local actualChargeFont = "N/A"
        if data.frame._arcChargeText then
          actualChargeFont = data.frame._arcChargeText:GetFont() or "nil"
        end
        
        print(string.format("  cdID %d (%s):", cdID, data.viewerType or "?"))
        print(string.format("    chargeText.font (cfg): %s", chargeFont))
        print(string.format("    chargeText.font (path): %s", chargeFontPath))
        print(string.format("    chargeText.font (actual): %s", actualChargeFont))
        print(string.format("    cooldownText.font (cfg): %s", cdFont))
        count = count + 1
      end
    end
    
    -- Test LSM
    if LSM then
      local testFont = "Friz Quadrata TT"
      local path = LSM:Fetch("font", testFont)
      print("|cffFFFF00LSM Test:|r")
      print("  LSM:Fetch('font', '" .. testFont .. "'): " .. tostring(path))
    else
      print("|cffFF0000LSM not loaded!|r")
    end
  
  elseif cmd == "fontlist" then
    -- List ALL fonts from LSM with their paths
    if not LSM then
      print("|cffFF0000LSM not loaded!|r")
      return
    end
    
    local fontList = LSM:List("font")
    local lines = {"|cff00CCFF=== All Available Fonts (" .. #fontList .. ") ===|r\n"}
    
    -- Group fonts by path to find duplicates/broken ones
    local pathToFonts = {}
    local defaultPath = "Fonts\\FRIZQT__.TTF"
    
    for _, fontName in ipairs(fontList) do
      local path = LSM:Fetch("font", fontName) or "nil"
      if not pathToFonts[path] then
        pathToFonts[path] = {}
      end
      table.insert(pathToFonts[path], fontName)
    end
    
    -- Show fonts that use the default fallback (broken fonts)
    if pathToFonts[defaultPath] and #pathToFonts[defaultPath] > 1 then
      table.insert(lines, "|cffFF6600FONTS USING DEFAULT (possibly broken):|r")
      for _, name in ipairs(pathToFonts[defaultPath]) do
        if name ~= "Friz Quadrata TT" then
          table.insert(lines, "  |cffFF0000" .. name .. "|r")
        end
      end
      table.insert(lines, "")
    end
    
    -- Show all fonts with paths
    table.insert(lines, "|cffFFFF00All Fonts:|r")
    for _, fontName in ipairs(fontList) do
      local path = LSM:Fetch("font", fontName) or "nil"
      local color = "|cff00FF00"  -- green = valid
      if path == defaultPath and fontName ~= "Friz Quadrata TT" then
        color = "|cffFF0000"  -- red = using fallback
      elseif path == "nil" or path == "" then
        color = "|cffFF0000"  -- red = no path
      end
      table.insert(lines, color .. fontName .. "|r -> " .. tostring(path))
    end
    
    -- Output to copyable window
    ShowDebugOutput(table.concat(lines, "\n"))
  
  elseif cmd == "scale" then
    -- Debug scale info
    local db = GetDB()
    DebugLog("|cff00CCFF=== Scale Debug ===|r")
    print("groupScales (from Edit Mode):")
    print(string.format("  aura: %.2f, cooldown: %.2f, utility: %.2f", 
      groupScales.aura, groupScales.cooldown, groupScales.utility))
    if db and db.editModeScales then
      print("db.editModeScales (persisted):")
      for vType, scale in pairs(db.editModeScales) do
        print(string.format("  %s: %.2f", vType, scale))
      end
    else
      print("db.editModeScales: nil")
    end
    -- Now using spec-based groupSettings
    local specGroupSettings = Shared.GetSpecGroupSettings()
    if specGroupSettings then
      print("specGroupSettings (overrides - spec-based):")
      for vType, gs in pairs(specGroupSettings) do
        if gs.scale then
          print(string.format("  %s OVERRIDE: %.2f", vType, gs.scale))
        else
          print(string.format("  %s: no override", vType))
        end
      end
    else
      print("specGroupSettings: nil")
    end
    print("Sample icon sizes:")
    local count = 0
    for cdID, data in pairs(enhancedFrames) do
      if data.frame and count < 5 then
        local f = data.frame
        print(string.format("  cdID %d (%s): size=%.1fx%.1f, scale=%.2f, origW=%.1f", 
          cdID, data.viewerType, f:GetWidth(), f:GetHeight(), f:GetScale(), f._arcOrigW or 0))
        count = count + 1
      end
    end
  
  elseif cmd == "spacing" then
    -- Debug spacing info - output to copyable window
    local viewerType = args[2] or "aura"
    local db = GetDB()
    local spacingCfg = viewerType == "aura" and db.auraSpacing or db.cooldownSpacing
    local lines = {}
    table.insert(lines, "=== Spacing Debug for " .. viewerType .. " ===")
    table.insert(lines, "Direction: " .. (spacingCfg and spacingCfg.direction or "nil"))
    table.insert(lines, "Amount: " .. (spacingCfg and spacingCfg.amount or "nil"))
    table.insert(lines, "")
    table.insert(lines, "=== Icons ===")
    for cdID, data in pairs(enhancedFrames) do
      if data.viewerType == viewerType and data.frame then
        local f = data.frame
        local savedPos = db.positions and db.positions[tostring(cdID)]
        table.insert(lines, string.format("cdID %d: curX=%.1f, curY=%.1f, origX=%s, origY=%s",
          cdID,
          f:GetLeft() or 0,
          f:GetBottom() or 0,
          f._arcOriginalX and string.format("%.1f", f._arcOriginalX) or "NIL",
          f._arcOriginalY and string.format("%.1f", f._arcOriginalY) or "NIL"
        ))
      end
    end
    table.insert(lines, "")
    table.insert(lines, "NOTE: If all X values are same, icons are VERTICAL - use Vertical direction")
    table.insert(lines, "NOTE: If all Y values are same, icons are HORIZONTAL - use Horizontal direction")
    ShowDebugOutput(table.concat(lines, "\n"))
    
  elseif cmd == "hideoor" then
    -- Force hide OutOfRange on all enhanced frames
    local count = 0
    for cdID, data in pairs(enhancedFrames) do
      local frame = data.frame
      if frame and frame.OutOfRange then
        frame.OutOfRange:SetShown(false)
        frame.OutOfRange:SetAlpha(0)
        frame.OutOfRange:SetDrawLayer("BACKGROUND", -8)
        frame.OutOfRange:SetSize(1, 1)
        count = count + 1
        DebugLog("|cff00FF00[ArcUI CDM]|r Hidden OutOfRange on cdID " .. cdID)
      end
    end
    DebugLog("|cff00FF00[ArcUI CDM]|r Force-hidden " .. count .. " OutOfRange textures")
    
  elseif cmd == "showoor" then
    -- Force show OutOfRange on all enhanced frames
    local count = 0
    for cdID, data in pairs(enhancedFrames) do
      local frame = data.frame
      if frame and frame.OutOfRange then
        frame.OutOfRange:SetShown(true)
        frame.OutOfRange:SetAlpha(0.6)
        frame.OutOfRange:SetDrawLayer("OVERLAY", 1)
        frame.OutOfRange:SetSize(36, 36)
        count = count + 1
      end
    end
    DebugLog("|cff00FF00[ArcUI CDM]|r Force-shown " .. count .. " OutOfRange textures")
    
  elseif cmd == "inspectoor" then
    -- Detailed inspection of OutOfRange on specified or all frames
    local targetCdID = tonumber(args[2])
    
    for cdID, data in pairs(enhancedFrames) do
      if not targetCdID or cdID == targetCdID then
        local frame = data.frame
        if frame and frame.OutOfRange then
          local oor = frame.OutOfRange
          print("--- cdID " .. cdID .. " ---")
          print("  ObjectType: " .. tostring(oor:GetObjectType()))
          print("  IsShown: " .. tostring(oor:IsShown()))
          print("  IsVisible: " .. tostring(oor:IsVisible()))
          print("  Alpha: " .. tostring(oor:GetAlpha()))
          print("  EffectiveAlpha: " .. tostring(oor:GetEffectiveAlpha()))
          local layer, sublayer = oor:GetDrawLayer()
          print("  DrawLayer: " .. tostring(layer) .. "/" .. tostring(sublayer))
          local w, h = oor:GetSize()
          print("  Size: " .. tostring(w) .. "x" .. tostring(h))
          
          -- Check parent
          local parent = oor:GetParent()
          print("  Parent: " .. tostring(parent and parent:GetName() or parent))
          
          -- Check anchor points
          local numPoints = oor:GetNumPoints()
          print("  NumPoints: " .. tostring(numPoints))
          for i = 1, numPoints do
            local point, relativeTo, relativePoint, xOfs, yOfs = oor:GetPoint(i)
            print("    Point " .. i .. ": " .. tostring(point) .. " -> " .. tostring(relativeTo and relativeTo:GetName() or relativeTo) .. ":" .. tostring(relativePoint) .. " (" .. tostring(xOfs) .. ", " .. tostring(yOfs) .. ")")
          end
          
          -- Check if frame has our hooks
          print("  _arcRefreshIconColorHooked: " .. tostring(frame._arcRefreshIconColorHooked))
          print("  _arcRangeCfg: " .. tostring(frame._arcRangeCfg))
          if frame._arcRangeCfg then
            print("    enabled: " .. tostring(frame._arcRangeCfg.enabled))
            print("    alpha: " .. tostring(frame._arcRangeCfg.alpha))
          end
          
          -- Check spellOutOfRange
          print("  spellOutOfRange: " .. tostring(frame.spellOutOfRange))
          
          -- Check for methods on the frame
          print("  RefreshIconColor: " .. (frame.RefreshIconColor and "exists" or "nil"))
          print("  UpdateIconColor: " .. (frame.UpdateIconColor and "exists" or "nil"))
          print("  OnRangeUpdate: " .. (frame.OnRangeUpdate and "exists" or "nil"))
        end
      end
    end
    
  elseif cmd == "methods" then
    -- List all methods on a CDM frame
    local targetCdID = tonumber(args[2])
    if not targetCdID then
      DebugLog("|cffFF0000[ArcUI CDM]|r Usage: /arccdm methods <cooldownID>")
      return
    end
    
    local data = enhancedFrames[targetCdID]
    if not data or not data.frame then
      DebugLog("|cffFF0000[ArcUI CDM]|r No frame found for cdID " .. targetCdID)
      return
    end
    
    local frame = data.frame
    print("--- Methods/Functions on cdID " .. targetCdID .. " ---")
    local methods = {}
    for k, v in pairs(frame) do
      if type(v) == "function" then
        table.insert(methods, k)
      end
    end
    table.sort(methods)
    for _, name in ipairs(methods) do
      print("  " .. name)
    end
    
  elseif cmd == "testcolor" then
    -- Call RefreshIconColor manually
    local targetCdID = tonumber(args[2])
    if not targetCdID then
      DebugLog("|cffFF0000[ArcUI CDM]|r Usage: /arccdm testcolor <cooldownID>")
      return
    end
    
    local data = enhancedFrames[targetCdID]
    if data and data.frame and data.frame.RefreshIconColor then
      DebugLog("|cff00FF00[ArcUI CDM]|r Calling RefreshIconColor on cdID " .. targetCdID)
      data.frame:RefreshIconColor()
    else
      DebugLog("|cffFF0000[ArcUI CDM]|r Frame doesn't have RefreshIconColor")
    end
    
  elseif cmd == "resetcolor" then
    -- Force reset Icon vertex color to white on all frames
    local count = 0
    for cdID, data in pairs(enhancedFrames) do
      local frame = data.frame
      if frame and frame.Icon then
        frame.Icon:SetVertexColor(1, 1, 1, 1)
        count = count + 1
      end
    end
    DebugLog("|cff00FF00[ArcUI CDM]|r Reset vertex color on " .. count .. " icons")
    
  elseif cmd == "redcolor" then
    -- Force set Icon vertex color to red on all frames (test)
    local count = 0
    for cdID, data in pairs(enhancedFrames) do
      local frame = data.frame
      if frame and frame.Icon then
        frame.Icon:SetVertexColor(1, 0.3, 0.3, 1)
        count = count + 1
      end
    end
    DebugLog("|cff00FF00[ArcUI CDM]|r Set red vertex color on " .. count .. " icons")
    
  elseif cmd == "getcolor" then
    -- Get current Icon vertex color
    local targetCdID = tonumber(args[2])
    for cdID, data in pairs(enhancedFrames) do
      if not targetCdID or cdID == targetCdID then
        local frame = data.frame
        if frame and frame.Icon then
          local r, g, b, a = frame.Icon:GetVertexColor()
          print("cdID " .. cdID .. " Icon VertexColor: " .. string.format("%.2f, %.2f, %.2f, %.2f", r, g, b, a))
        end
      end
    end
    
  elseif cmd == "inactive" then
    -- Debug inactive state for aura icons
    local targetCdID = tonumber(args[2])
    
    if targetCdID then
      -- Show details for specific icon
      local data = enhancedFrames[targetCdID]
      if not data then
        DebugLog("|cffFF0000[ArcUI CDM]|r No frame found for cdID " .. targetCdID)
        return
      end
      
      local frame = data.frame
      local cfg = GetIconSettings(targetCdID)
      local stateVisuals = cfg and GetEffectiveStateVisuals(cfg)
      
      DebugLog("|cff00FFFF--- Inactive State Debug for cdID " .. targetCdID .. " ---|r")
      print("  viewerType: " .. tostring(data.viewerType))
      print("  frame.auraInstanceID: " .. tostring(frame.auraInstanceID) .. " (type: " .. type(frame.auraInstanceID) .. ")")
      print("  isShown: " .. tostring(frame:IsShown()))
      print("  cfg.cooldownStateVisuals:")
      if stateVisuals then
        print("    readyAlpha: " .. tostring(stateVisuals.readyAlpha))
        print("    cooldownAlpha: " .. tostring(stateVisuals.cooldownAlpha))
        print("    cooldownDesaturate: " .. tostring(stateVisuals.cooldownDesaturate))
        print("    noDesaturate: " .. tostring(stateVisuals.noDesaturate))
      else
        print("    (no custom state visuals)")
      end
      print("  frame tracking:")
      print("    _arcAuraWasActive: " .. tostring(frame._arcAuraWasActive))
      print("    _arcLastInactiveState: " .. tostring(frame._arcLastInactiveState))
      if frame.Icon then
        print("  Icon.desaturated: " .. tostring(frame.Icon:IsDesaturated()))
      end
    else
      -- Show all aura icons
      DebugLog("|cff00FFFF--- All Aura Icons Inactive State ---|r")
      for cdID, data in pairs(enhancedFrames) do
        if data.viewerType == "aura" then
          local frame = data.frame
          local cfg = GetIconSettings(cdID)
          local stateVisuals = cfg and GetEffectiveStateVisuals(cfg)
          local auraActive = frame.auraInstanceID and type(frame.auraInstanceID) == "number" and frame.auraInstanceID > 0
          local cdAlpha = stateVisuals and stateVisuals.cooldownAlpha or 1.0
          local cdDesat = stateVisuals and stateVisuals.cooldownDesaturate or false
          print(string.format("cdID %d: auraID=%s active=%s shown=%s cdAlpha=%.2f cdDesat=%s",
            cdID,
            tostring(frame.auraInstanceID),
            tostring(auraActive),
            tostring(frame:IsShown()),
            cdAlpha,
            tostring(cdDesat)))
        end
      end
    end
    
  elseif cmd == "reset" or cmd == "wipesettings" then
    -- Reset all CDMEnhance settings to defaults
    StaticPopupDialogs["ARCUI_CDM_RESET_CONFIRM"] = {
      text = "This will WIPE ALL ArcUI CDM Enhancement settings (global defaults, per-icon settings, groups, positions). Are you sure?",
      button1 = "Yes, Reset",
      button2 = "Cancel",
      OnAccept = function()
        local db = GetDB()
        if db then
          -- Wipe global defaults (profile-based, shared)
          if db.globalAuraSettings then wipe(db.globalAuraSettings) end
          if db.globalCooldownSettings then wipe(db.globalCooldownSettings) end
          
          -- Wipe spec-based settings (iconSettings and groupSettings)
          local specIconSettings = Shared.GetSpecIconSettings()
          if specIconSettings then wipe(specIconSettings) end
          
          local specGroupSettings = Shared.GetSpecGroupSettings()
          if specGroupSettings then
            wipe(specGroupSettings)
            -- Re-initialize with defaults
            specGroupSettings.aura = {}
            specGroupSettings.cooldown = {}
            specGroupSettings.utility = {}
          end
          
          -- Reset flags
          db.unlocked = false
          db.textDragMode = false
          
          -- Clear caches
          InvalidateEffectiveSettingsCache()
          wipe(enhancedFrames)
          
          print("|cffFF0000[ArcUI CDM]|r Settings have been reset. Please /reload to complete.")
        end
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show("ARCUI_CDM_RESET_CONFIRM")
    
  else
    DebugLog("|cff00FF00[ArcUI CDM Debug Commands]|r")
    print("  /arccdm debug - Toggle debug output")
    print("  /arccdm tintdebug - Toggle tint debug output")
    print("  /arccdm fontdebug - Show font configuration debug info")
    print("  /arccdm fontlist - List ALL available fonts and their paths")
    print("  /arccdm scale - Show current scale values and overrides")
    print("  /arccdm inactive [cdID] - Debug inactive state for aura icons")
    print("  /arccdm hideoor - Force hide all OutOfRange textures")
    print("  /arccdm showoor - Force show all OutOfRange textures")
    print("  /arccdm inspectoor [cdID] - Inspect OutOfRange details")
    print("  /arccdm methods <cdID> - List all methods on a frame")
    print("  /arccdm testcolor <cdID> - Call RefreshIconColor manually")
    print("  /arccdm resetcolor - Reset all icons to white (no tint)")
    print("  /arccdm redcolor - Tint all icons red (test)")
    print("  /arccdm getcolor [cdID] - Show icon vertex colors")
    print("  /arccdm reset - WIPE ALL CDM Enhancement settings")
  end
end

-- ===================================================================
-- INITIALIZATION
-- ===================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Leaving combat
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entering combat
-- Proc glow events (spellID in event is non-secret)
eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")

-- Track active threshold glow icons and manage ticker
local activeThresholdGlows = {}  -- cdID -> true
local thresholdGlowTicker = nil

local function EvaluateThresholdGlows()
  local hasActive = false
  
  for cdID in pairs(activeThresholdGlows) do
    local data = enhancedFrames[cdID]
    if data and data.frame then
      local frame = data.frame
      -- Use frame-level cached config
      local cfg = GetEffectiveIconSettingsForFrame(frame)
      if cfg then
        local stateVisuals = GetEffectiveStateVisuals(cfg)
        if stateVisuals and stateVisuals.readyGlow and stateVisuals.glowThreshold and stateVisuals.glowThreshold < 1.0 then
          -- Check if glow should show at all (combat-only, etc)
          if ShouldShowReadyGlow(stateVisuals, frame) then
            local auraID = frame.auraInstanceID
            if auraID and type(auraID) == "number" and auraID > 0 then
              hasActive = true
              
              -- Determine which unit this aura tracks
              local auraType = stateVisuals.glowAuraType or "auto"
              local trackedUnit = "player"
              if auraType == "debuff" then
                trackedUnit = "target"
              elseif auraType == "auto" then
                local cdInfo = Shared.SafeGetCDMInfo and Shared.SafeGetCDMInfo(cdID)
                if cdInfo and cdInfo.category == 3 then trackedUnit = "target" end
              end
              
              -- Evaluate threshold glow curve
              local durationObj = C_UnitAuras and C_UnitAuras.GetAuraDuration and C_UnitAuras.GetAuraDuration(trackedUnit, auraID)
              if durationObj then
                local thresholdCurve = GetGlowThresholdCurve(stateVisuals.glowThreshold)
                if thresholdCurve then
                  local okG, glowAlpha = pcall(function()
                    return durationObj:EvaluateRemainingPercent(thresholdCurve)
                  end)
                  if okG and glowAlpha ~= nil then
                    SetGlowAlpha(frame, glowAlpha, stateVisuals)
                  end
                end
              end
            else
              -- Aura gone, remove from tracking and hide glow
              activeThresholdGlows[cdID] = nil
              HideReadyGlow(frame)
            end
          else
            -- Glow conditions not met, remove from tracking
            activeThresholdGlows[cdID] = nil
            HideReadyGlow(frame)
          end
        else
          -- Settings changed, no longer threshold glow
          activeThresholdGlows[cdID] = nil
        end
      else
        -- No config, remove from tracking
        activeThresholdGlows[cdID] = nil
      end
    else
      -- Frame gone, remove from tracking
      activeThresholdGlows[cdID] = nil
    end
  end
  
  -- Stop ticker if no active threshold glows
  if not hasActive and thresholdGlowTicker then
    thresholdGlowTicker:Cancel()
    thresholdGlowTicker = nil
  end
end

-- Start threshold glow ticker for an icon
StartThresholdGlowTracking = function(cdID)
  if not cdID then return end  -- Guard against nil
  activeThresholdGlows[cdID] = true
  
  -- Start ticker if not running
  if not thresholdGlowTicker then
    thresholdGlowTicker = C_Timer.NewTicker(0.5, EvaluateThresholdGlows)
  end
end

-- Stop threshold glow ticker for an icon
StopThresholdGlowTracking = function(cdID)
  if not cdID then return end  -- Guard against nil
  activeThresholdGlows[cdID] = nil
  
  -- Check if any still active
  if not next(activeThresholdGlows) and thresholdGlowTicker then
    thresholdGlowTicker:Cancel()
    thresholdGlowTicker = nil
  end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROC GLOW FUNCTIONS (Event-driven like ArcAuras)
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- PROC GLOW CUSTOMIZATION
-- Two approaches based on glowType:
--   "default" = Use CDM's native glow with FlipBook frame dimension override
--   "pixel"/"autocast"/"button" = Hide CDM's glow, show LibCustomGlow instead
-- ═══════════════════════════════════════════════════════════════════════════

-- CDM FLIPBOOK SIZING - ANIMATION API APPROACH:
-- CDM uses 160x160 flipbook designed for 36x36 action buttons
-- 
-- Problem: CDM's FlipBook animation calls SetSize on the texture during playback.
-- Our SetSize hooks get installed but the FIRST animation call happens before
-- the hook is installed (race condition on first-ever proc).
--
-- Solution: Use the FlipBook animation's native API to set frame dimensions.
-- SetFlipBookFrameWidth/Height tell the animation what size to use BEFORE it plays.
-- This is the correct way to control FlipBook animation sizes.

local FLIPBOOK_RATIO = 2.5  -- Tuned to match LoopFlipbook size better

ResizeProcGlowAlert = function(frame)
  if not frame then return end
  local alert = frame.SpellActivationAlert
  if not alert then return end
  
  -- CRITICAL: Set frame level ABOVE Cooldown swipe so glow isn't hidden behind it
  local baseLevel = frame:GetFrameLevel()
  alert:SetFrameLevel(baseLevel + 15)
  
  -- Get the icon's current size
  local frameW, frameH = frame:GetWidth(), frame:GetHeight()
  if frameW <= 0 or frameH <= 0 then return end
  
  -- Calculate sizes
  local alertW = frameW * 1.4
  local alertH = frameH * 1.4
  
  -- Flipbook should maintain the same visual overflow ratio as CDM's 36px design
  local flipbookW = alertW * FLIPBOOK_RATIO
  local flipbookH = alertH * FLIPBOOK_RATIO
  
  -- Store target sizes on the alert for reference
  alert._arcTargetAlertW = alertW
  alert._arcTargetAlertH = alertH
  alert._arcTargetFlipbookW = flipbookW
  alert._arcTargetFlipbookH = flipbookH
  
  -- Resize the alert frame
  alert:SetSize(alertW, alertH)
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- FLIPBOOK ANIMATION API: Set frame dimensions on the animation objects
  -- This tells the FlipBook animation what size to render each frame.
  -- When flipBookFrameWidth/Height are 0 (default), animation calculates from texture.
  -- By setting explicit values, we control the rendered size.
  -- ═══════════════════════════════════════════════════════════════════════════
  
  -- Find and configure ProcStartAnim (intro animation)
  if alert.ProcStartAnim and alert.ProcStartAnim.SetFlipBookFrameWidth then
    alert.ProcStartAnim:SetFlipBookFrameWidth(flipbookW)
    alert.ProcStartAnim:SetFlipBookFrameHeight(flipbookH)
    if ns.devMode then
      print("|cff00FF00[ArcUI ProcGlow]|r Set ProcStartAnim frame dimensions:", flipbookW, "x", flipbookH)
    end
  end
  
  -- Find and configure ProcLoop (looping animation) if it has FlipBook
  if alert.ProcLoop and alert.ProcLoop.SetFlipBookFrameWidth then
    alert.ProcLoop:SetFlipBookFrameWidth(flipbookW)
    alert.ProcLoop:SetFlipBookFrameHeight(flipbookH)
  end
  
  -- Also set the texture sizes directly (for when animation isn't playing)
  if alert.ProcStartFlipbook then
    alert.ProcStartFlipbook:SetSize(flipbookW, flipbookH)
  end
  if alert.ProcLoopFlipbook then
    alert.ProcLoopFlipbook:SetSize(flipbookW, flipbookH)
  end
  
  -- AltGlow: centered, proportional size (slightly smaller than flipbook)
  if alert.ProcAltGlow then
    local altSize = math.min(flipbookW, flipbookH) * 0.3  -- ~30% of flipbook
    alert.ProcAltGlow:SetSize(altSize, altSize)
  end
  
  -- ═══════════════════════════════════════════════════════════════════════════
  -- BACKUP: Hook SetSize as fallback (for edge cases)
  -- The FlipBook API should handle sizing, but keep hooks as safety net
  -- ═══════════════════════════════════════════════════════════════════════════
  if alert.ProcStartFlipbook and not alert.ProcStartFlipbook._arcSetSizeHooked then
    alert.ProcStartFlipbook._arcSetSizeHooked = true
    local origSetSize = alert.ProcStartFlipbook.SetSize
    alert.ProcStartFlipbook.SetSize = function(self, w, h)
      local parent = self:GetParent()
      if parent and parent._arcTargetFlipbookW then
        return origSetSize(self, parent._arcTargetFlipbookW, parent._arcTargetFlipbookH)
      end
      return origSetSize(self, w, h)
    end
  end
  
  if alert.ProcLoopFlipbook and not alert.ProcLoopFlipbook._arcSetSizeHooked then
    alert.ProcLoopFlipbook._arcSetSizeHooked = true
    local origSetSize = alert.ProcLoopFlipbook.SetSize
    alert.ProcLoopFlipbook.SetSize = function(self, w, h)
      local parent = self:GetParent()
      if parent and parent._arcTargetFlipbookW then
        return origSetSize(self, parent._arcTargetFlipbookW, parent._arcTargetFlipbookH)
      end
      return origSetSize(self, w, h)
    end
  end
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Resize: icon=" .. 
      string.format("%.0fx%.0f", frameW, frameH) .. 
      " alert=" .. string.format("%.0fx%.0f", alertW, alertH) ..
      " flipbook=" .. string.format("%.0fx%.0f", flipbookW, flipbookH) ..
      " (ratio=" .. string.format("%.2f", FLIPBOOK_RATIO) .. ")")
  end
end

-- Apply custom color to CDM's SpellActivationAlert (for "proc" glowType)
local function ApplyProcGlowColor(frame, glowCfg)
  if not frame then return end
  local alert = frame.SpellActivationAlert
  if not alert then return end
  
  -- Resize alert to match icon size
  ResizeProcGlowAlert(frame)
  
  -- Get color from config (default gold like vanilla WoW)
  local r, g, b, a = 1, 0.82, 0, 1  -- Default gold
  if glowCfg and glowCfg.color then
    r = glowCfg.color.r or 1
    g = glowCfg.color.g or 0.82
    b = glowCfg.color.b or 0
  end
  if glowCfg and glowCfg.alpha then
    a = glowCfg.alpha
  end
  
  -- IMPORTANT: Use vertex color as a multiplicative tint WITHOUT desaturating
  -- SetDesaturated on flipbook textures during animation can break the rendering
  -- This gives a tinted effect rather than a full color replacement
  if alert.ProcStartFlipbook then
    alert.ProcStartFlipbook:SetVertexColor(r, g, b, a)
  end
  if alert.ProcLoopFlipbook then
    alert.ProcLoopFlipbook:SetVertexColor(r, g, b, a)
  end
  if alert.ProcAltGlow then
    alert.ProcAltGlow:SetVertexColor(r, g, b, a)
  end
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Applied CDM tint: r=" .. string.format("%.2f", r) .. " g=" .. string.format("%.2f", g) .. " b=" .. string.format("%.2f", b))
  end
end

-- Reset CDM's glow to default colors
local function ResetProcGlowColor(frame)
  if not frame then return end
  local alert = frame.SpellActivationAlert
  if not alert then return end
  
  if alert.ProcStartFlipbook then
    alert.ProcStartFlipbook:SetVertexColor(1, 1, 1, 1)
  end
  if alert.ProcLoopFlipbook then
    alert.ProcLoopFlipbook:SetVertexColor(1, 1, 1, 1)
  end
  if alert.ProcAltGlow then
    alert.ProcAltGlow:SetVertexColor(1, 1, 1, 1)
  end
end

-- Hide CDM's glow completely (for LCG replacement)
HideCDMProcGlow = function(frame)
  if not frame then return end
  local alert = frame.SpellActivationAlert
  if not alert then return end
  
  -- IMPORTANT: Stop animations FIRST - this prevents them from resetting alpha/visibility
  if alert.ProcStartAnim and alert.ProcStartAnim:IsPlaying() then
    alert.ProcStartAnim:Stop()
  end
  if alert.ProcLoop and alert.ProcLoop:IsPlaying() then
    alert.ProcLoop:Stop()
  end
  
  -- Now hide the textures
  if alert.ProcStartFlipbook then alert.ProcStartFlipbook:Hide() end
  if alert.ProcLoopFlipbook then alert.ProcLoopFlipbook:Hide() end
  if alert.ProcAltGlow then alert.ProcAltGlow:Hide() end
  
  -- Also set alpha 0 on the parent as backup
  alert:SetAlpha(0)
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Hidden CDM glow (stopped animations, hid textures)")
  end
end

-- Restore CDM's glow visibility (when LCG glow ends)
local function RestoreCDMProcGlow(frame)
  if not frame then return end
  local alert = frame.SpellActivationAlert
  if not alert then return end
  
  -- Restore alpha
  alert:SetAlpha(1)
  
  -- Show textures (CDM will manage them from here)
  if alert.ProcStartFlipbook then alert.ProcStartFlipbook:Show() end
  if alert.ProcLoopFlipbook then alert.ProcLoopFlipbook:Show() end
  if alert.ProcAltGlow then alert.ProcAltGlow:Show() end
  
  -- Reset colors to default
  ResetProcGlowColor(frame)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CUSTOM BLIZZARD-STYLE PROC GLOW
-- Creates our own proc glow using ActionButtonSpellAlertTemplate
-- Properly sized to match icon size (unlike CDM's broken sizing)
-- ═══════════════════════════════════════════════════════════════════════════

-- Create or get our custom proc glow frame for an icon
local function GetOrCreateCustomProcGlow(frame)
  if not frame then return nil end
  
  -- Return existing if already created
  if frame._arcCustomProcGlow then
    return frame._arcCustomProcGlow
  end
  
  -- Create a new frame from Blizzard's template
  local glowFrame = CreateFrame("Frame", nil, frame, "ActionButtonSpellAlertTemplate")
  if not glowFrame then
    if ns.devMode then
      print("|cffFF0000[ArcUI ProcGlow]|r Failed to create ActionButtonSpellAlertTemplate")
    end
    return nil
  end
  
  -- Store reference
  frame._arcCustomProcGlow = glowFrame
  glowFrame._arcParentIcon = frame
  
  -- Chain start animation → loop animation
  -- When ProcStartAnim finishes its burst, ProcLoop must begin playing
  -- Without this wiring, the loop glow never starts after the initial burst
  if glowFrame.ProcStartAnim then
    glowFrame.ProcStartAnim:SetScript("OnFinished", function()
      if glowFrame.ProcLoop and not glowFrame.ProcLoop:IsPlaying() then
        glowFrame.ProcLoop:Play()
      end
    end)
  end
  
  -- Set frame level above icon but below UI
  glowFrame:SetFrameLevel(frame:GetFrameLevel() + 5)
  
  -- Hide by default
  glowFrame:Hide()
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Created custom proc glow frame")
  end
  
  return glowFrame
end

-- Resize the proc glow flipbooks to match icon size
local function ResizeCustomProcGlow(glowFrame, iconFrame)
  if not glowFrame or not iconFrame then return end
  
  local iconWidth = iconFrame:GetWidth()
  local iconHeight = iconFrame:GetHeight()
  if iconWidth <= 0 or iconHeight <= 0 then return end
  
  -- Position glow frame centered on icon
  glowFrame:ClearAllPoints()
  glowFrame:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
  glowFrame:SetSize(iconWidth, iconHeight)
  
  -- Calculate the overhang (how much the glow extends past the icon)
  -- Default Blizzard proc glow is about 1.6x the icon size on each side
  local scale = 0.8  -- How much to extend past the icon
  local overW = iconWidth * scale
  local overH = iconHeight * scale
  
  -- Resize ProcStartFlipbook (the initial burst)
  if glowFrame.ProcStartFlipbook then
    glowFrame.ProcStartFlipbook:ClearAllPoints()
    glowFrame.ProcStartFlipbook:SetPoint("TOPLEFT", glowFrame, "TOPLEFT", -overW, overH)
    glowFrame.ProcStartFlipbook:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMRIGHT", overW, -overH)
  end
  
  -- Resize ProcLoopFlipbook (the looping glow)
  if glowFrame.ProcLoopFlipbook then
    glowFrame.ProcLoopFlipbook:ClearAllPoints()
    glowFrame.ProcLoopFlipbook:SetPoint("TOPLEFT", glowFrame, "TOPLEFT", -overW, overH)
    glowFrame.ProcLoopFlipbook:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMRIGHT", overW, -overH)
  end
  
  -- Resize ProcAltGlow (the subtle background glow)
  if glowFrame.ProcAltGlow then
    glowFrame.ProcAltGlow:ClearAllPoints()
    glowFrame.ProcAltGlow:SetPoint("TOPLEFT", glowFrame, "TOPLEFT", -overW * 0.5, overH * 0.5)
    glowFrame.ProcAltGlow:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMRIGHT", overW * 0.5, -overH * 0.5)
  end
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Resized custom glow for " .. iconWidth .. "x" .. iconHeight .. " icon")
  end
end

-- Apply color to custom proc glow
local function ColorCustomProcGlow(glowFrame, r, g, b, a)
  if not glowFrame then return end
  
  a = a or 1
  
  if glowFrame.ProcStartFlipbook then
    glowFrame.ProcStartFlipbook:SetVertexColor(r, g, b, a)
  end
  if glowFrame.ProcLoopFlipbook then
    glowFrame.ProcLoopFlipbook:SetVertexColor(r, g, b, a)
  end
  if glowFrame.ProcAltGlow then
    glowFrame.ProcAltGlow:SetVertexColor(r, g, b, a)
  end
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Applied color r=" .. string.format("%.2f", r) .. " g=" .. string.format("%.2f", g) .. " b=" .. string.format("%.2f", b))
  end
end

-- Show custom proc glow
local function ShowCustomProcGlow(frame, glowCfg)
  if not frame then return end
  
  local glowFrame = GetOrCreateCustomProcGlow(frame)
  if not glowFrame then return end
  
  -- Resize to match current icon size
  ResizeCustomProcGlow(glowFrame, frame)
  
  -- Apply color (default gold)
  local r, g, b, a = 1, 0.82, 0, 1
  if glowCfg and glowCfg.color then
    r = glowCfg.color.r or 1
    g = glowCfg.color.g or 0.82
    b = glowCfg.color.b or 0
  end
  if glowCfg and glowCfg.alpha then
    a = glowCfg.alpha
  end
  ColorCustomProcGlow(glowFrame, r, g, b, a)
  
  -- Reset alpha (might have been set to 0 when hidden)
  glowFrame:SetAlpha(1)
  
  -- Show all textures
  if glowFrame.ProcStartFlipbook then
    glowFrame.ProcStartFlipbook:Show()
  end
  if glowFrame.ProcLoopFlipbook then
    glowFrame.ProcLoopFlipbook:Show()
  end
  if glowFrame.ProcAltGlow then
    glowFrame.ProcAltGlow:Show()
  end
  
  -- Show frame and start animation
  glowFrame:Show()
  
  -- The template has animations built-in that auto-play on show
  -- But we can manually trigger them to ensure they play
  if glowFrame.ProcStartAnim and not glowFrame.ProcStartAnim:IsPlaying() then
    glowFrame.ProcStartAnim:Play()
  end
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Showing custom Blizzard-style glow")
  end
end

-- Hide custom proc glow
local function HideCustomProcGlow(frame)
  if not frame then return end
  
  local glowFrame = frame._arcCustomProcGlow
  if not glowFrame then return end
  
  -- Stop ALL animations
  if glowFrame.ProcStartAnim then
    glowFrame.ProcStartAnim:Stop()
  end
  if glowFrame.ProcLoop then
    glowFrame.ProcLoop:Stop()
  end
  
  -- Hide ALL textures explicitly
  if glowFrame.ProcStartFlipbook then
    glowFrame.ProcStartFlipbook:Hide()
  end
  if glowFrame.ProcLoopFlipbook then
    glowFrame.ProcLoopFlipbook:Hide()
  end
  if glowFrame.ProcAltGlow then
    glowFrame.ProcAltGlow:Hide()
  end
  
  -- Hide frame itself
  glowFrame:Hide()
  glowFrame:SetAlpha(0)
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Hidden custom Blizzard-style glow")
  end
end

-- Start LCG glow on frame (for ALL glow types including proc)
-- This matches the preview code EXACTLY for consistent look
local function StartLCGProcGlow(frame, glowCfg, padding)
  local lcg = GetLCG()
  if not frame or not lcg then return end
  
  local glowType = glowCfg.glowType or "default"
  
  -- "default" type uses CDM's glow, not LCG
  if glowType == "default" then return end
  
  local glowScale = glowCfg.scale or 1.0
  
  -- LibCustomGlow: NEGATIVE offset moves glow INWARD
  local glowOffset = -(padding or 0)
  
  -- Build color (same as preview)
  local color = {0.95, 0.95, 0.32, glowCfg.alpha or 1.0}
  if glowCfg.color then
    color = {glowCfg.color.r or 1, glowCfg.color.g or 1, glowCfg.color.b or 1, glowCfg.alpha or 1.0}
  end
  
  -- Helper to set glow frame level ABOVE Cooldown swipe
  local function SetProcGlowFrameLevel(glowFrame)
    if glowFrame and glowFrame.SetFrameLevel then
      local baseLevel = frame:GetFrameLevel()
      -- Set glow above Cooldown swipe (+15) but below text overlay (+50)
      local targetLevel = baseLevel + 15
      glowFrame:SetFrameLevel(targetLevel)
    end
  end
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Starting LCG glow type:", glowType, "padding:", padding, "scale:", glowScale)
  end
  
  -- Start the appropriate glow type - SAME CODE AS PREVIEW
  if glowType == "pixel" then
    local lines = glowCfg.lines or 8
    local speed = glowCfg.speed or 0.25
    local thickness = math.max(1, math.floor((glowCfg.thickness or 2) * glowScale))
    pcall(GetLCG().PixelGlow_Start, frame, color, lines, speed, nil, thickness, glowOffset, glowOffset, true, "ArcUI_ProcGlow", 1)
    local glowFrame = frame["_PixelGlowArcUI_ProcGlow"]
    SetProcGlowFrameLevel(glowFrame)
  elseif glowType == "autocast" then
    local particles = glowCfg.particles or 4
    local speed = glowCfg.speed or 0.125
    pcall(GetLCG().AutoCastGlow_Start, frame, color, particles, speed, glowScale, glowOffset, glowOffset, "ArcUI_ProcGlow", 1)
    local glowFrame = frame["_AutoCastGlowArcUI_ProcGlow"]
    SetProcGlowFrameLevel(glowFrame)
  elseif glowType == "button" then
    local speed = glowCfg.speed or 0.125
    -- ButtonGlow_Start signature: (frame, color, frequency, frameLevel)
    pcall(GetLCG().ButtonGlow_Start, frame, color, speed, 8)
    local glowFrame = frame._ButtonGlow
    if glowFrame then
      SetProcGlowFrameLevel(glowFrame)
      -- Apply scale only if non-default (matching ready state approach)
      if glowScale ~= 1.0 then
        pcall(glowFrame.SetScale, glowFrame, glowScale)
      end
      -- NOTE: Do NOT override ButtonGlow anchoring for padding.
      -- LCG's ButtonGlow_Start calculates the correct 20% extension from frame size.
      -- Previously we called ClearAllPoints/SetPoint to inset by padding, which
      -- destroyed the 20% extension and shrunk the glow INSIDE the frame.
      -- The ready state button glow works by NOT touching anchors — match that.
    end
  elseif glowType == "proc" then
    -- PRE-FIX: If glow frame already exists from previous use, reset it properly
    local existingGlow = frame["_ProcGlowArcUI_ProcGlow"]
    if existingGlow then
      -- Stop any running animations and reset state
      if existingGlow.ProcStartAnim and existingGlow.ProcStartAnim:IsPlaying() then
        existingGlow.ProcStartAnim:Stop()
      end
      if existingGlow.ProcLoopAnim and existingGlow.ProcLoopAnim:IsPlaying() then
        existingGlow.ProcLoopAnim:Stop()
      end
      -- Pre-set correct visual state BEFORE ProcGlow_Start triggers OnShow
      if existingGlow.ProcStart then
        existingGlow.ProcStart:Hide()
        existingGlow.ProcStart:SetAlpha(0)
      end
      if existingGlow.ProcLoop then
        existingGlow.ProcLoop:Show()
        existingGlow.ProcLoop:SetAlpha(glowCfg.alpha or 1.0)
      end
    end
    
    pcall(GetLCG().ProcGlow_Start, frame, {
      color = color,
      startAnim = false,
      key = "ArcUI_ProcGlow",
      xOffset = glowOffset,
      yOffset = glowOffset,
    })
    
    -- Set frame level for proc glow
    local glowFrame = frame["_ProcGlowArcUI_ProcGlow"]
    SetProcGlowFrameLevel(glowFrame)
    
    -- POST-FIX: Ensure correct state after LCG's OnShow script runs
    -- Use C_Timer.After(0) to run on next frame after all scripts complete
    local targetAlpha = glowCfg.alpha or 1.0
    C_Timer.After(0, function()
      local glowFrame = frame["_ProcGlowArcUI_ProcGlow"]
      if glowFrame and glowFrame:IsShown() then
        -- Force correct visual state
        if glowFrame.ProcStart then
          glowFrame.ProcStart:Hide()
          glowFrame.ProcStart:SetAlpha(0)
        end
        if glowFrame.ProcLoop then
          glowFrame.ProcLoop:Show()
          glowFrame.ProcLoop:SetAlpha(targetAlpha)
        end
        -- Ensure animation is playing
        if glowFrame.ProcLoopAnim and not glowFrame.ProcLoopAnim:IsPlaying() then
          glowFrame.ProcLoopAnim:Play()
        end
      end
    end)
  end
end

-- Stop LCG glow on frame (all types)
local function StopLCGProcGlow(frame)
  local lcg = GetLCG()
  if not frame or not lcg then return end
  
  -- For proc glow, explicitly stop animations before releasing
  -- This ensures clean state for next use
  local procGlow = frame["_ProcGlowArcUI_ProcGlow"]
  if procGlow then
    if procGlow.ProcStartAnim and procGlow.ProcStartAnim:IsPlaying() then
      procGlow.ProcStartAnim:Stop()
    end
    if procGlow.ProcLoopAnim and procGlow.ProcLoopAnim:IsPlaying() then
      procGlow.ProcLoopAnim:Stop()
    end
    if procGlow.ProcStart then procGlow.ProcStart:Hide() end
    if procGlow.ProcLoop then procGlow.ProcLoop:Hide() end
  end
  
  pcall(GetLCG().ProcGlow_Stop, frame, "ArcUI_ProcGlow")
  pcall(GetLCG().PixelGlow_Stop, frame, "ArcUI_ProcGlow")
  pcall(GetLCG().AutoCastGlow_Stop, frame, "ArcUI_ProcGlow")
  pcall(GetLCG().ButtonGlow_Stop, frame)
  
  -- Clear pre-warm flag so it will re-warm on next enhancement
  -- (in case glow settings changed)
  frame._arcProcGlowPreWarmed = nil
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ProcGlow]|r Stopped LCG glow")
  end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PRE-WARM PROC GLOW FRAME
-- Creates and initializes the glow frame ahead of time so it's ready when needed
-- This prevents the "first show glitch" where ProcLoop starts at alpha 0
-- Call this during icon enhancement for any icon that might get proc glows
-- ═══════════════════════════════════════════════════════════════════════════
local function PreWarmProcGlow(frame, glowCfg)
  local lcg = GetLCG()
  if not frame or not lcg then return end
  if not glowCfg then return end
  
  local glowType = glowCfg.glowType or "proc"
  
  -- Only pre-warm for "proc" type (others don't have the same issue)
  if glowType ~= "proc" then return end
  
  -- Already pre-warmed?
  if frame._arcProcGlowPreWarmed then return end
  
  -- Get padding
  local padding = 0
  if frame._arcConfig and frame._arcConfig.padding then
    padding = frame._arcConfig.padding
  elseif frame._arcPadding then
    padding = frame._arcPadding
  end
  
  local glowOffset = -(padding or 0)
  local color = {0.95, 0.95, 0.32, 1.0}
  if glowCfg.color then
    color = {glowCfg.color.r or 1, glowCfg.color.g or 1, glowCfg.color.b or 1, 1.0}
  end
  
  -- Create the glow frame via LCG (this acquires from pool and sets up OnShow/OnHide)
  pcall(GetLCG().ProcGlow_Start, frame, {
    color = color,
    startAnim = false,
    key = "ArcUI_ProcGlow",
    xOffset = glowOffset,
    yOffset = glowOffset,
  })
  
  -- Now fix the initial state and hide it
  local glowFrame = frame["_ProcGlowArcUI_ProcGlow"]
  if glowFrame then
    -- Stop animations
    if glowFrame.ProcStartAnim and glowFrame.ProcStartAnim:IsPlaying() then
      glowFrame.ProcStartAnim:Stop()
    end
    if glowFrame.ProcLoopAnim and glowFrame.ProcLoopAnim:IsPlaying() then
      glowFrame.ProcLoopAnim:Stop()
    end
    
    -- Set ProcLoop to correct alpha (so it's ready when shown)
    if glowFrame.ProcStart then
      glowFrame.ProcStart:Hide()
      glowFrame.ProcStart:SetAlpha(0)
    end
    if glowFrame.ProcLoop then
      -- Set to 1.0 so it's visible immediately when shown
      -- The actual alpha will be set by ShowProcGlow
      glowFrame.ProcLoop:SetAlpha(1.0)
      glowFrame.ProcLoop:Hide()  -- Hide for now
    end
    
    -- Hide the glow frame itself (but keep it attached)
    glowFrame:Hide()
    
    frame._arcProcGlowPreWarmed = true
    
    if ns.devMode then
      print("|cff00FF00[ArcUI ProcGlow]|r Pre-warmed proc glow for frame:", frame.cooldownID)
    end
  end
end

-- Export for use in ApplyIconStyle
ns.CDMEnhance.PreWarmProcGlow = PreWarmProcGlow

-- Called by event (SPELL_ACTIVATION_OVERLAY_GLOW_SHOW) or hook (SpellActivationAlert:Show)
-- Has guard against double-calls - safe to trigger from both
function ns.CDMEnhance.ShowProcGlow(frame, glowCfg)
  if not frame then return end
  if not glowCfg or glowCfg.enabled == false then
    -- Glow DISABLED - hide ALL glows (both LCG and CDM's)
    if frame._arcProcGlowActive then
      ns.CDMEnhance.HideProcGlow(frame)
    end
    HideCDMProcGlow(frame)
    return
  end
  
  -- Already showing? Don't restart
  if frame._arcProcGlowActive then return end
  
  local glowType = glowCfg.glowType or "default"
  
  -- Get padding from frame's full config (same as preview uses)
  local padding = 0
  if frame._arcConfig and frame._arcConfig.padding then
    padding = frame._arcConfig.padding
  elseif frame._arcPadding then
    padding = frame._arcPadding
  end
  
  -- Track which spell started this glow (overrideSpellID is NON-SECRET!)
  -- HIDE event will match against this to find the right frame
  local startingSpellID = nil
  if frame.cooldownInfo then
    startingSpellID = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
  end
  
  if ns.devMode then
    print("|cff00FF00[ArcUI ShowProcGlow]|r glowType:", glowType, "padding:", padding, "spellID:", startingSpellID)
  end
  
  -- Set state
  frame._arcProcGlowActive = true
  frame._arcProcGlowType = glowType
  frame._arcProcGlowSpellID = startingSpellID
  
  -- Handle based on glow type
  if glowType == "default" then
    -- DEFAULT: Use CDM's built-in SpellActivationAlert
    -- Just resize to match icon size
    ResizeProcGlowAlert(frame)
  else
    -- LCG TYPES (pixel, autocast, button, proc): Use LibCustomGlow
    StartLCGProcGlow(frame, glowCfg, padding)
    
    -- Hide CDM's glow once - the ShowAlert hook handles ongoing suppression
    -- whenever CDM tries to re-show its alert
    if frame.SpellActivationAlert then
      HideCDMProcGlow(frame)
    end
  end
end

-- Called when SPELL_ACTIVATION_OVERLAY_GLOW_HIDE fires
function ns.CDMEnhance.HideProcGlow(frame)
  if not frame then return end
  
  local glowType = frame._arcProcGlowType or "default"
  
  if ns.devMode then
    print("|cffFF0000[ArcUI HideProcGlow]|r glowType:", glowType, "spellID:", frame._arcProcGlowSpellID)
  end
  
  -- Handle based on glow type
  if glowType == "default" then
    -- DEFAULT: Reset CDM's glow color back to normal
    ResetProcGlowColor(frame)
  else
    -- LCG TYPES: Stop all LCG glows
    HideCustomProcGlow(frame)
    StopLCGProcGlow(frame)
    -- Restore CDM's alert visibility so it works correctly for the next proc
    RestoreCDMProcGlow(frame)
  end
  
  frame._arcProcGlowActive = false
  frame._arcProcGlowType = nil
  frame._arcProcGlowSpellID = nil  -- Clear tracked spell
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ACTIONBUTTONSPELLALERTMANAGER HOOK
-- This intercepts ALL proc glow ShowAlert calls AFTER they start.
-- For LCG replacement mode, we immediately stop/hide CDM's glow.
-- For CDM recolor mode, we apply custom colors.
-- Using hooksecurefunc to avoid taint issues.
-- ═══════════════════════════════════════════════════════════════════════════
local function SetupShowAlertHook()
  -- Wait until ActionButtonSpellAlertManager exists
  if not ActionButtonSpellAlertManager then
    -- Try again later
    C_Timer.After(0.5, SetupShowAlertHook)
    return
  end
  
  if ns.CDMEnhance._showAlertHooked then return end
  ns.CDMEnhance._showAlertHooked = true
  
  -- Hook ShowAlert - runs AFTER CDM shows glow
  -- This is the entry point for starting LCG glows
  hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(self, frame)
    if not frame then return end
    
    -- Get FRESH config - never use cached references
    local cfg = GetEffectiveIconSettingsForFrame(frame)
    local glowCfg = cfg and cfg.procGlow
    
    if not glowCfg then return end
    
    -- DISABLED: Hide CDM's glow completely
    if glowCfg.enabled == false then
      if frame.SpellActivationAlert then
        HideCDMProcGlow(frame)
      end
      return
    end
    
    local glowType = glowCfg.glowType or "default"
    
    if glowType == "default" then
      -- DEFAULT MODE: CDM handles the glow, just resize to match icon
      ResizeProcGlowAlert(frame)
      
      -- ═══════════════════════════════════════════════════════════════════════════
      -- FIRST-PROC FIX: Only needed on the FIRST EVER proc for each alert frame
      -- Issue: On first proc, ProcLoopFlipbook is visible when it should be alpha=0
      -- Solution: Hide it during ProcStartAnim, show it when ProcStartAnim finishes
      -- After the first proc, the animation system handles this correctly
      -- ═══════════════════════════════════════════════════════════════════════════
      local alert = frame.SpellActivationAlert
      if alert and not alert._arcFirstProcFixed then
        alert._arcFirstProcFixed = true
        
        -- Hide ProcLoopFlipbook during the intro animation
        if alert.ProcLoopFlipbook then
          alert.ProcLoopFlipbook:Hide()
          alert.ProcLoopFlipbook:SetAlpha(0)
        end
        
        -- Hook OnFinished to show ProcLoopFlipbook when intro ends
        if alert.ProcStartAnim then
          alert.ProcStartAnim:HookScript("OnFinished", function()
            if alert.ProcLoopFlipbook then
              alert.ProcLoopFlipbook:Show()
              alert.ProcLoopFlipbook:SetAlpha(1)
            end
          end)
        end
        
        if ns.devMode then
          print("|cff00FF00[ArcUI ShowAlertHook]|r First-proc fix applied - hid ProcLoopFlipbook until intro finishes")
        end
      end
      
      if ns.devMode then
        print("|cff00FF00[ArcUI ShowAlertHook]|r Default mode - resized CDM glow")
      end
    else
      -- LCG MODE (pixel, autocast, button, proc): Replace CDM's glow with LCG
      -- 1. Hide CDM's glow immediately
      if frame.SpellActivationAlert then
        local alert = frame.SpellActivationAlert
        
        -- Stop animations FIRST
        if alert.ProcStartAnim and alert.ProcStartAnim:IsPlaying() then
          alert.ProcStartAnim:Stop()
        end
        if alert.ProcLoop and alert.ProcLoop:IsPlaying() then
          alert.ProcLoop:Stop()
        end
        
        -- Hide textures
        if alert.ProcStartFlipbook then alert.ProcStartFlipbook:Hide() end
        if alert.ProcLoopFlipbook then alert.ProcLoopFlipbook:Hide() end
        if alert.ProcAltGlow then alert.ProcAltGlow:Hide() end
        alert:SetAlpha(0)
      end
      
      -- 2. Start LCG glow (ShowProcGlow has guards against double-start)
      ns.CDMEnhance.ShowProcGlow(frame, glowCfg)
      
      if ns.devMode then
        print("|cff00FF00[ArcUI ShowAlertHook]|r LCG mode - hid CDM, started", glowType, "glow")
      end
    end
  end)
  
  -- Hook HideAlert - runs AFTER CDM hides glow
  -- This is the entry point for stopping LCG glows
  hooksecurefunc(ActionButtonSpellAlertManager, "HideAlert", function(self, frame)
    if not frame then return end
    
    -- Hide our LCG glow if active
    if frame._arcProcGlowActive then
      ns.CDMEnhance.HideProcGlow(frame)
      
      if ns.devMode then
        print("|cffFF0000[ArcUI HideAlertHook]|r Hid LCG glow for frame:", frame.cooldownID)
      end
    end
  end)
  
  if ns.devMode then
    print("|cff00FF00[ArcUI]|r ActionButtonSpellAlertManager ShowAlert/HideAlert hooked (secure)")
  end
end

-- Set up the hook immediately (will retry if manager doesn't exist yet)
SetupShowAlertHook()

-- Refresh all combat-only glows when combat state changes
local function RefreshCombatOnlyGlows()
  local inCombat = InCombatLockdown() or UnitAffectingCombat("player")
  
  -- Iterate through all enhanced frames
  for cdID, data in pairs(enhancedFrames) do
    if data and data.frame then
      local frame = data.frame
      local cfg = GetIconSettings(cdID)
      if cfg then
        local stateVisuals = GetEffectiveStateVisuals(cfg)
        if stateVisuals and stateVisuals.readyGlow and stateVisuals.readyGlowCombatOnly then
          -- This icon has combat-only glow enabled
          if inCombat then
            -- Entering combat - show glow if ability is ready
            -- The normal state update will handle this via ApplyCooldownStateVisuals
            -- Just trigger a refresh
            ApplyIconStyle(frame, cdID)
          else
            -- Leaving combat - hide the glow
            HideReadyGlow(frame)
          end
        end
      end
    end
  end
end

-- Periodic watcher to detect newly displayed icons
-- Checks for CDM frames that have cooldownID but haven't been enhanced yet
-- NOTE: We intentionally exclude BuffBarCooldownViewer - it has a different structure (bars, not icons)
local function CheckForNewIcons()
  if InCombatLockdown() then return end
  
  -- MASTER TOGGLE: Skip if disabled
  local groupsDB = Shared.GetCDMGroupsDB()
  if groupsDB and groupsDB.enabled == false then
    return  -- Silent - called frequently by OnUpdate
  end
  
  -- Skip during spec change - frames are in unstable state
  if ns.CDMGroups and ns.CDMGroups.specChangeInProgress then return end
  
  local viewers = {
    { name = "BuffIconCooldownViewer", viewerType = "aura" },
    { name = "EssentialCooldownViewer", viewerType = "cooldown" },
    { name = "UtilityCooldownViewer", viewerType = "utility" },
  }
  
  local foundNew = false
  for _, info in ipairs(viewers) do
    local viewer = _G[info.name]
    if viewer then
      local children = {viewer:GetChildren()}
      for _, frame in ipairs(children) do
        local cdID = frame.cooldownID
        if cdID and not frame._arcEnhanced then
          -- Found an unenhanced frame with a cooldownID - enhance it
          EnhanceFrame(frame, cdID, info.viewerType, info.name)
          foundNew = true
          
          if ns.devMode then
            print(string.format("|cff00FFFF[ArcUI CDMEnhance]|r Auto-enhanced new icon cdID %d", cdID))
          end
        end
      end
    end
  end
  
  -- If we found new icons, also update the central cache
  if foundNew and ns.API and ns.API.ScanAllCDMIcons then
    -- Quick refresh without full notification chain
    -- Just update our local tracking
  end
end

-- Start the periodic watcher after loading
local watcherFrame = CreateFrame("Frame")
local watcherElapsed = 0
local WATCHER_INTERVAL = 0.5  -- Check every 0.5 seconds

watcherFrame:SetScript("OnUpdate", function(self, elapsed)
  watcherElapsed = watcherElapsed + elapsed
  if watcherElapsed >= WATCHER_INTERVAL then
    watcherElapsed = 0
    CheckForNewIcons()
  end
end)

eventFrame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "Blizzard_CooldownViewer" then
    C_Timer.After(1.0, function()
      if not InCombatLockdown() then
        ns.CDMEnhance.ScanCDM()
        -- Also apply group settings after CDM loads
        C_Timer.After(0.5, function()
          if not InCombatLockdown() then
            ns.CDMEnhance.RefreshAllStyles()
            if ns.CDMGroupSettings then
              ns.CDMGroupSettings.ForceLayoutRefresh("aura")
              ns.CDMGroupSettings.ForceLayoutRefresh("cooldown")
              ns.CDMGroupSettings.ForceLayoutRefresh("utility")
            end
          end
        end)
      end
    end)
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Zone change - CDMGroups handles positioning
    -- CDMEnhance just refreshes styling
    
    C_Timer.After(1.0, function()
      local db = GetDB()
      if db then
        if db.unlocked then isUnlocked = true end
        if db.textDragMode then textDragMode = true end
      end
      -- Refresh cached enabled state
      RefreshCachedEnabledState()
      -- Invalidate cache to ensure fresh settings on load
      InvalidateEffectiveSettingsCache()
      if not InCombatLockdown() then
        -- Force CDM to create all frames before we scan
        ns.CDMEnhance.ForceCDMFrameCreation()
        ns.CDMEnhance.ScanCDM()
        
        -- Second pass to ensure all global settings are applied
        C_Timer.After(0.5, function()
          if not InCombatLockdown() then
            ns.CDMEnhance.RefreshAllStyles()
            if ns.CDMGroupSettings then
              ns.CDMGroupSettings.ForceLayoutRefresh("aura")
              ns.CDMGroupSettings.ForceLayoutRefresh("cooldown")
              ns.CDMGroupSettings.ForceLayoutRefresh("utility")
            end
          end
        end)
      end
    end)
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    -- Spec changed - CDM will show new icons
    -- CDMGroups handles all spec change logic including positioning
    -- CDMEnhance just refreshes styling AFTER CDMGroups completes
    C_Timer.After(1.0, function()
      -- Wait for CDMGroups to finish spec change
      if ns.CDMGroups and ns.CDMGroups.specChangeInProgress then
        -- Still changing, wait more
        C_Timer.After(0.5, function()
          if ns.API and ns.API.ScanAllCDMIcons then
            ns.API.ScanAllCDMIcons()
          end
        end)
      else
        if ns.API and ns.API.ScanAllCDMIcons then
          ns.API.ScanAllCDMIcons()
        end
      end
    end)
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Entering combat - refresh combat-only glows
    RefreshCombatOnlyGlows()
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Leaving combat - hide combat-only glows
    RefreshCombatOnlyGlows()
    
    -- CRITICAL: Refresh all icon alpha after combat ends
    -- CDM refreshes icons when combat ends and may override our alpha
    -- We need to re-apply our alpha settings after CDM's refresh completes
    -- OPTIMIZATION: Only refresh frames that have custom state visuals or
    -- ignoreAuraOverride. Frames without these are fully managed by CDM
    -- natively and calling ApplyCooldownStateVisuals on them is wasteful
    -- (and was previously destructive — it nuked CDM's native desaturation).
    C_Timer.After(0.1, function()
      for cdID, data in pairs(enhancedFrames) do
        if data.frame then
          local cfg = GetEffectiveIconSettingsForFrame(data.frame)
          if cfg then
            local sv = GetEffectiveStateVisuals(cfg)
            local ignAura = (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
                         or (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)
            if sv or ignAura then
              -- Clear cached state so it recalculates
              data.frame._arcTargetAlpha = nil
              data.frame._arcEnforceReadyAlpha = nil
              ApplyCooldownStateVisuals(data.frame, cfg, cfg.alpha or 1.0)
            end
          end
        end
      end
    end)
    -- Second pass for stragglers (CDM may have multiple refresh waves)
    C_Timer.After(0.3, function()
      for cdID, data in pairs(enhancedFrames) do
        if data.frame then
          local cfg = GetEffectiveIconSettingsForFrame(data.frame)
          if cfg then
            local sv = GetEffectiveStateVisuals(cfg)
            local ignAura = (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
                         or (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)
            if sv or ignAura then
              data.frame._arcTargetAlpha = nil
              data.frame._arcEnforceReadyAlpha = nil
              ApplyCooldownStateVisuals(data.frame, cfg, cfg.alpha or 1.0)
            end
          end
        end
      end
    end)
    
  elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
    -- arg1 = spellID (non-secret event data)
    local spellID = arg1
    if not spellID then return end
    
    if ns.devMode then
      print("|cff00FF00[ArcUI Proc]|r SHOW event for spellID:", spellID)
    end
    
    -- Find frame with this spellID
    -- NOTE: ShowAlert hook is the primary path for LCG glows
    -- This event acts as a backup and handles cases where frame needs glow but ShowAlert didn't fire
    for cdID, data in pairs(enhancedFrames) do
      if data.frame and data.frame._arcStyled then
        local frameSpellID = nil
        if data.frame.cooldownInfo then
          frameSpellID = data.frame.cooldownInfo.overrideSpellID or data.frame.cooldownInfo.spellID
        end
        if not frameSpellID and data.frame.GetSpellID then
          pcall(function() frameSpellID = data.frame:GetSpellID() end)
        end
        if not frameSpellID then
          frameSpellID = data.frame._arcSpellID
        end
        
        if frameSpellID == spellID then
          -- Get FRESH config
          local cfg = GetEffectiveIconSettingsForFrame(data.frame)
          local glowCfg = cfg and cfg.procGlow
          
          if glowCfg and glowCfg.enabled ~= false then
            -- ShowProcGlow has guards against double-start, so safe to call even if ShowAlert already ran
            ns.CDMEnhance.ShowProcGlow(data.frame, glowCfg)
            
            if ns.devMode then
              print("|cff00FF00[ArcUI Proc]|r Found frame for spellID:", spellID, "glowType:", glowCfg.glowType)
            end
          end
          break
        end
      end
    end
    
  elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
    -- arg1 = spellID (non-secret event data)
    local spellID = arg1
    if not spellID then return end
    
    if ns.devMode then
      print("|cffFF0000[ArcUI Proc]|r HIDE event for spellID:", spellID)
    end
    
    local foundFrame = false
    
    -- Helper to check if a frame's glow was started by this spellID
    -- IMPORTANT: Match against _arcProcGlowSpellID, NOT current overrideSpellID!
    -- The spell on the frame may have changed since the glow started.
    local function CheckAndHideFrame(frame, cdID)
      if not frame or not frame._arcStyled then return false end
      if not frame._arcProcGlowActive then return false end  -- No active glow to hide
      
      -- Match against the spellID that STARTED the glow
      if frame._arcProcGlowSpellID == spellID then
        if ns.devMode then
          print("|cffFF0000[ArcUI Proc]|r Found frame for spellID:", spellID, "cdID:", cdID)
        end
        
        -- Hide our glow
        ns.CDMEnhance.HideProcGlow(frame)
        
        if ns.devMode then
          print("|cffFF0000[ArcUI Proc]|r Called HideProcGlow")
        end
        
        return true
      end
      return false
    end
    
    -- Search enhancedFrames
    for cdID, data in pairs(enhancedFrames) do
      if CheckAndHideFrame(data.frame, cdID) then
        foundFrame = true
        break
      end
    end
    
    -- Also search CDMGroups if not found
    if not foundFrame and ns.CDMGroups then
      -- Search free icons
      if ns.CDMGroups.freeIcons then
        for cdID, iconData in pairs(ns.CDMGroups.freeIcons) do
          if iconData.frame and CheckAndHideFrame(iconData.frame, cdID) then
            foundFrame = true
            break
          end
        end
      end
      
      -- Search grouped icons
      if not foundFrame and ns.CDMGroups.groups then
        for groupName, groupData in pairs(ns.CDMGroups.groups) do
          if groupData.icons then
            for cdID, iconData in pairs(groupData.icons) do
              if iconData.frame and CheckAndHideFrame(iconData.frame, cdID) then
                foundFrame = true
                break
              end
            end
          end
          if foundFrame then break end
        end
      end
    end
    
    if ns.devMode and not foundFrame then
      print("|cffFF0000[ArcUI Proc]|r Could not find frame for spellID:", spellID)
    end
  end
end)

-- Hook Edit Mode to reapply our styles when it opens/closes
-- (Edit Mode can temporarily override icon sizes/positions)
local function HookEditMode()
  if not EditModeManagerFrame then return end
  
  if ns.CDMEnhance._editModeHooked then return end
  ns.CDMEnhance._editModeHooked = true
  
  -- Track when Edit Mode is active
  local editModeActive = false
  
  -- Hook ExitEditMode method - this is more reliable than OnHide
  hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
    editModeActive = false
    -- Reapply all styles after Edit Mode exits
    C_Timer.After(0.1, function()
      if not InCombatLockdown() then
        ns.CDMEnhance.RefreshAllStyles()
      end
    end)
    -- Second pass for any stragglers
    C_Timer.After(0.3, function()
      if not InCombatLockdown() then
        ns.CDMEnhance.RefreshAllStyles()
      end
      -- Update options panel
      if LibStub and LibStub("AceConfigRegistry-3.0", true) then
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
      end
    end)
  end)
  
  -- Hook OnShow to know when Edit Mode is active and handle free position icons
  EditModeManagerFrame:HookScript("OnShow", function()
    editModeActive = true
    -- CDMGroups handles positioning - just refresh styles
    C_Timer.After(0.15, function()
      if not InCombatLockdown() then
        for cdID, data in pairs(enhancedFrames) do
          if data.frame then
            ApplyIconStyle(data.frame, cdID)
          end
        end
      end
    end)
  end)
  
  -- Hook OnHide as backup
  EditModeManagerFrame:HookScript("OnHide", function()
    if editModeActive then
      editModeActive = false
      C_Timer.After(0.2, function()
        if not InCombatLockdown() then
          ns.CDMEnhance.RefreshAllStyles()
        end
      end)
    end
  end)
  
  -- OnUpdate during Edit Mode - CDMGroups handles positioning
  -- Just keep the hook minimal for any future needs
  local updateAccum = 0
  local UPDATE_INTERVAL = 0.2
  EditModeManagerFrame:HookScript("OnUpdate", function(self, elapsed)
    if not editModeActive then return end
    -- CDMGroups handles all positioning - no action needed here
  end)
end

-- Try to hook immediately or wait for Edit Mode to load
if EditModeManagerFrame then
  HookEditMode()
else
  -- Hook when Blizzard_EditMode loads
  local editModeLoader = CreateFrame("Frame")
  editModeLoader:RegisterEvent("ADDON_LOADED")
  editModeLoader:SetScript("OnEvent", function(self, event, addon)
    if addon == "Blizzard_EditMode" then
      C_Timer.After(0.1, HookEditMode)
      self:UnregisterAllEvents()
    end
  end)
end

-- ===================================================================
-- COOLDOWN EVENT-DRIVEN UPDATES
-- Instead of polling at 10Hz, we update cooldown visuals on events
-- Duration objects auto-update internally, we just refresh on CD changes
-- ===================================================================

-- ===================================================================
-- OPTIONS PANEL STATE TRACKING
-- Uses Shared's cached state and callback (avoids expensive OnUpdate checks)
-- ===================================================================

-- Register callback for when options panel state changes
Shared.OnOptionsPanelStateChanged = function(isOpen)
  -- Panel state changed - refresh all icon visuals
  ns.CDMEnhance.RefreshOverlayMouseState()
  
  -- Also ensure cooldown state ticker is running if needed
  if ns.CDMEnhance.EnsureTickerState then
    ns.CDMEnhance.EnsureTickerState()
  end
end

local cooldownEventFrame = CreateFrame("Frame")
cooldownEventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
cooldownEventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")

-- ═══════════════════════════════════════════════════════════════════════════
-- OPTIMIZED SPELL_UPDATE_COOLDOWN HANDLER
-- PERFORMANCE IMPROVEMENTS:
-- 1. Throttled to 20Hz max (was unlimited - 90+ calls/sec during burst)
-- 2. Removed 3-burst pattern (was 3x work per event)
-- 3. Single unified loop with frame deduplication (was 3 separate loops)
-- 4. Early-exit for frames without state visuals
-- ═══════════════════════════════════════════════════════════════════════════

-- Throttle state
local cooldownEventThrottle = {
  lastUpdate = 0,
  minInterval = 0.05,  -- 20Hz max (50ms between updates)
  pending = false,
}

-- Frame collection (reused to avoid garbage)
local frameUpdateList = {}
local frameUpdateCount = 0

-- Collect frames that need cooldown updates (deduplicated, with early-exit)
local function CollectCooldownFrames()
  wipe(frameUpdateList)
  frameUpdateCount = 0
  
  local processedFrames = {}
  
  local function TryAddFrame(frame, viewerType)
    if not frame then return end
    if processedFrames[frame] then return end
    if viewerType ~= "cooldown" and viewerType ~= "utility" then return end
    -- Accept frame if it has a cached OR live spell ID (live covers override swaps in combat)
    if not frame._arcCachedSpellID then
      if not (frame.cooldownInfo and (frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID)) then
        return
      end
    end
    
    -- EARLY EXIT: Skip if no state visuals AND not ignoreAuraOverride
    -- AND no custom label text (custom labels need cooldown event updates
    -- for their state visibility toggles even without state visuals)
    if not frame._arcIgnoreAuraOverride and not frame._arcCLHasText then
      local cfg = frame._arcCfg
      if cfg then
        local sv = cfg.cooldownStateVisuals
        if not sv or (not sv.readyState and not sv.cooldownState) then
          frame._arcCooldownEventDriven = false
          return
        end
      end
    end
    
    processedFrames[frame] = true
    frameUpdateCount = frameUpdateCount + 1
    frameUpdateList[frameUpdateCount] = frame
  end
  
  -- Collect from enhancedFrames
  for cdID, data in pairs(enhancedFrames) do
    TryAddFrame(data.frame, data.viewerType)
  end
  
  -- Collect from CDMGroups (dedupe handles overlap)
  if ns.CDMGroups and ns.CDMGroups.groups then
    for groupName, group in pairs(ns.CDMGroups.groups) do
      if group.members then
        for cdID, member in pairs(group.members) do
          if member then
            TryAddFrame(member.frame, member.viewerType)
          end
        end
      end
    end
  end
  
  -- Collect from free icons
  if ns.CDMGroups and ns.CDMGroups.freeIcons then
    for cdID, data in pairs(ns.CDMGroups.freeIcons) do
      TryAddFrame(data.frame, data.viewerType)
    end
  end
  
  return frameUpdateCount
end

-- Core update function
local function OnCooldownEvent()
  -- Skip during protection/spec change
  if ns.CDMGroups then
    if ns.CDMGroups.specChangeInProgress or ns.CDMGroups._pendingSpecChange then return end
    if ns.CDMGroups._restorationProtectionEnd and GetTime() < ns.CDMGroups._restorationProtectionEnd then return end
  end
  
  InitCooldownCurves()
  if not CooldownCurves or not CooldownCurves.initialized then return end
  
  local count = CollectCooldownFrames()
  if count == 0 then return end
  
  for i = 1, count do
    local frame = frameUpdateList[i]
    
    -- Use LIVE overrideSpellID — _arcCachedSpellID goes stale when CDM
    -- swaps the override spell in combat (e.g. Judgment ↔ Hammer of Wrath).
    -- overrideSpellID is non-secret even in combat (confirmed via frame dumps).
    local spellID = frame._arcCachedSpellID
    if frame.cooldownInfo then
      local liveSpell = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
      if liveSpell then
        spellID = liveSpell
        frame._arcCachedSpellID = liveSpell  -- Keep cache in sync
      end
    end
    
    -- Refresh cached duration objects
    if C_Spell.GetSpellCooldownDuration then
      local okDur, durObj = pcall(C_Spell.GetSpellCooldownDuration, spellID)
      if okDur and durObj then
        frame._arcCachedCooldownDuration = durObj
      end
    end
    if C_Spell.GetSpellChargeDuration then
      local okCharge, chargeObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
      if okCharge and chargeObj then
        frame._arcCachedChargeDuration = chargeObj
      end
    end
    
    -- Apply visuals
    local cfg = GetEffectiveIconSettingsForFrame(frame)
    if cfg then
      local stateVisuals = GetEffectiveStateVisuals(cfg)
      if stateVisuals or frame._arcIgnoreAuraOverride then
        ApplyCooldownStateVisuals(frame, cfg, cfg.alpha or 1.0, stateVisuals)
        frame._arcCooldownEventDriven = true
      elseif frame._arcCLHasText then
        -- Frame has custom labels but no state visuals — still need to update
        -- label visibility (the relay wrapper won't fire without state visuals)
        if ns.CustomLabel and ns.CustomLabel.UpdateVisibility then
          ns.CustomLabel.UpdateVisibility(frame)
        end
      end
    end
  end
end

-- Throttled handler - limits to 20Hz, coalesces rapid events
local function ThrottledOnCooldownEvent()
  local now = GetTime()
  local timeSince = now - cooldownEventThrottle.lastUpdate
  
  if timeSince >= cooldownEventThrottle.minInterval then
    cooldownEventThrottle.lastUpdate = now
    cooldownEventThrottle.pending = false
    OnCooldownEvent()
    return
  end
  
  if not cooldownEventThrottle.pending then
    cooldownEventThrottle.pending = true
    C_Timer.After(cooldownEventThrottle.minInterval - timeSince, function()
      cooldownEventThrottle.pending = false
      cooldownEventThrottle.lastUpdate = GetTime()
      OnCooldownEvent()
    end)
  end
end

cooldownEventFrame:SetScript("OnEvent", function(self, event)
  ThrottledOnCooldownEvent()
end)

-- Export for testing
ns.CDMEnhance.OnCooldownEvent = OnCooldownEvent
ns.CDMEnhance.ThrottledOnCooldownEvent = ThrottledOnCooldownEvent

-- Debug: Allow runtime throttle adjustment
ns.CDMEnhance.SetCooldownEventThrottle = function(hz)
  if hz and hz > 0 then
    cooldownEventThrottle.minInterval = 1.0 / hz
    print("|cff00FF00[ArcUI]|r Cooldown event throttle set to", hz, "Hz")
  end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COOLDOWN STATE TICKER
-- Runs at 0.5s when:
-- 1. Out of combat (SPELL_UPDATE_COOLDOWN doesn't fire out of combat)
-- 2. Options panel is open (for live preview of settings changes)
-- ═══════════════════════════════════════════════════════════════════════════
local cooldownStateTicker = nil
local TICKER_INTERVAL = 0.5  -- Low frequency to minimize performance impact

-- Check if ticker should be running (uses Shared's cheap cached value)
local function ShouldTickerRun()
  -- Run if out of combat
  if not InCombatLockdown() then
    return true
  end
  -- Run if options panel is open (even in combat, for preview)
  -- Uses cached value from Shared - cheap, no LibStub lookup
  if Shared.IsOptionsPanelOpen() then
    return true
  end
  return false
end

local function StartCooldownStateTicker()
  if cooldownStateTicker then return end  -- Already running
  
  cooldownStateTicker = C_Timer.NewTicker(TICKER_INTERVAL, function()
    -- Check if we should still be running
    if not ShouldTickerRun() then
      if cooldownStateTicker then
        cooldownStateTicker:Cancel()
        cooldownStateTicker = nil
      end
      return
    end
    
    -- Call the same update function used by SPELL_UPDATE_COOLDOWN
    OnCooldownEvent()
  end)
  
  if ns.devMode then
    print("|cff00FF00[ArcUI]|r Started cooldown state ticker (0.5s)")
  end
end

local function StopCooldownStateTicker()
  if cooldownStateTicker then
    cooldownStateTicker:Cancel()
    cooldownStateTicker = nil
    
    if ns.devMode then
      print("|cff00FF00[ArcUI]|r Stopped cooldown state ticker")
    end
  end
end

-- Ensure ticker is running if it should be
local function EnsureTickerState()
  if ShouldTickerRun() then
    StartCooldownStateTicker()
  else
    StopCooldownStateTicker()
  end
end

-- Export for callback use
ns.CDMEnhance.EnsureTickerState = EnsureTickerState

-- Register for combat state changes
local tickerEventFrame = CreateFrame("Frame")
tickerEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
tickerEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
tickerEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

tickerEventFrame:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_REGEN_ENABLED" then
    -- Left combat - start the ticker
    C_Timer.After(0.1, EnsureTickerState)
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Entered combat - check if options panel keeps it alive
    C_Timer.After(0.1, EnsureTickerState)
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- On login/reload, start ticker if needed
    C_Timer.After(1.5, EnsureTickerState)
  end
end)

-- Get group spacing for a viewer type (nil = use CDM default)
-- Now using spec-based storage
local function GetGroupSpacing(viewerType)
  local groupSettings = Shared.GetGroupSettingsForType(viewerType)
  if not groupSettings then return nil end
  return groupSettings.padding
end

-- Check if custom spacing is enabled for a viewer type
local function IsGroupSpacingEnabled(viewerType)
  return GetGroupSpacing(viewerType) ~= nil
end

-- Get group direction
-- Now using spec-based storage
local function GetGroupDirection(viewerType)
  local groupSettings = Shared.GetGroupSettingsForType(viewerType)
  if not groupSettings then
    return (viewerType == "aura") and "DOWN" or "RIGHT"
  end
  return groupSettings.direction or ((viewerType == "aura") and "DOWN" or "RIGHT")
end

-- Get secondary direction (for multi-row/column)
-- Now using spec-based storage
local function GetGroupSecondaryDirection(viewerType)
  local groupSettings = Shared.GetGroupSettingsForType(viewerType)
  if not groupSettings then return "DOWN" end
  return groupSettings.secondaryDirection or "DOWN"
end

-- Get row limit
-- Now using spec-based storage
local function GetGroupRowLimit(viewerType)
  local groupSettings = Shared.GetGroupSettingsForType(viewerType)
  if not groupSettings then return 0 end
  return groupSettings.rowLimit or 0
end

-- ===================================================================
-- PUBLIC API FOR GROUP SPACING
-- ===================================================================

function ns.CDMEnhance.GetGroupSpacing(viewerType)
  return GetGroupSpacing(viewerType)
end

function ns.CDMEnhance.IsGroupSpacingEnabled(viewerType)
  return IsGroupSpacingEnabled(viewerType)
end

function ns.CDMEnhance.GetGroupDirection(viewerType)
  return GetGroupDirection(viewerType)
end

function ns.CDMEnhance.GetGroupSecondaryDirection(viewerType)
  return GetGroupSecondaryDirection(viewerType)
end

function ns.CDMEnhance.GetGroupRowLimit(viewerType)
  return GetGroupRowLimit(viewerType)
end

local spacingSetThrottle = {}
function ns.CDMEnhance.SetGroupSpacing(viewerType, spacing)
  -- Now using spec-based storage
  local groupSettings = Shared.GetSpecGroupSettings()
  if not groupSettings then return end
  
  if not groupSettings[viewerType] then
    groupSettings[viewerType] = {}
  end
  
  -- Check if we're disabling
  local wasEnabled = groupSettings[viewerType].padding ~= nil
  local willBeDisabled = spacing == nil
  
  groupSettings[viewerType].padding = spacing
  
  -- If disabling, trigger layout refresh
  if wasEnabled and willBeDisabled then
    if ns.CDMGroupSettings and ns.CDMGroupSettings.ForceLayoutRefresh then
      ns.CDMGroupSettings.ForceLayoutRefresh(viewerType)
    end
    return
  end
  
  -- Throttle application
  local now = GetTime()
  if not spacingSetThrottle[viewerType] or (now - spacingSetThrottle[viewerType]) > 0.05 then
    spacingSetThrottle[viewerType] = now
    
    -- Force refresh and trigger update via GroupSettings
    if ns.CDMGroupSettings then
      if ns.CDMGroupSettings.ForceLayoutRefresh then
        ns.CDMGroupSettings.ForceLayoutRefresh(viewerType)
      end
      if ns.CDMGroupSettings.OnViewerUpdate then
        local viewerName = VIEWER_FRAME_MAP[viewerType]
        if viewerName then
          ns.CDMGroupSettings.OnViewerUpdate(viewerName)
        end
      end
    end
  end
end

function ns.CDMEnhance.SetGroupDirection(viewerType, direction)
  -- Now using spec-based storage
  local groupSettings = Shared.GetSpecGroupSettings()
  if not groupSettings then return end
  
  if not groupSettings[viewerType] then groupSettings[viewerType] = {} end
  
  groupSettings[viewerType].direction = direction
  
  if ns.CDMGroupSettings then
    if ns.CDMGroupSettings.ForceLayoutRefresh then
      ns.CDMGroupSettings.ForceLayoutRefresh(viewerType)
    end
    if ns.CDMGroupSettings.OnViewerUpdate then
      local viewerName = VIEWER_FRAME_MAP[viewerType]
      if viewerName then
        ns.CDMGroupSettings.OnViewerUpdate(viewerName)
      end
    end
  end
end

function ns.CDMEnhance.SetGroupSecondaryDirection(viewerType, direction)
  -- Now using spec-based storage
  local groupSettings = Shared.GetSpecGroupSettings()
  if not groupSettings then return end
  
  if not groupSettings[viewerType] then groupSettings[viewerType] = {} end
  
  groupSettings[viewerType].secondaryDirection = direction
  
  if ns.CDMGroupSettings then
    if ns.CDMGroupSettings.ForceLayoutRefresh then
      ns.CDMGroupSettings.ForceLayoutRefresh(viewerType)
    end
    if ns.CDMGroupSettings.OnViewerUpdate then
      local viewerName = VIEWER_FRAME_MAP[viewerType]
      if viewerName then
        ns.CDMGroupSettings.OnViewerUpdate(viewerName)
      end
    end
  end
end

function ns.CDMEnhance.SetGroupRowLimit(viewerType, limit)
  -- Now using spec-based storage
  local groupSettings = Shared.GetSpecGroupSettings()
  if not groupSettings then return end
  
  if not groupSettings[viewerType] then groupSettings[viewerType] = {} end
  
  groupSettings[viewerType].rowLimit = limit or 0
  
  if ns.CDMGroupSettings then
    if ns.CDMGroupSettings.ForceLayoutRefresh then
      ns.CDMGroupSettings.ForceLayoutRefresh(viewerType)
    end
    if ns.CDMGroupSettings.OnViewerUpdate then
      local viewerName = VIEWER_FRAME_MAP[viewerType]
      if viewerName then
        ns.CDMGroupSettings.OnViewerUpdate(viewerName)
      end
    end
  end
end

-- Force refresh all layouts
function ns.CDMEnhance.ForceRefreshAllLayouts()
  if ns.CDMGroupSettings and ns.CDMGroupSettings.ForceLayoutRefreshAll then
    ns.CDMGroupSettings.ForceLayoutRefreshAll()
  end
  for viewerType, viewerName in pairs(VIEWER_FRAME_MAP) do
    if ns.CDMGroupSettings and ns.CDMGroupSettings.OnViewerUpdate then
      ns.CDMGroupSettings.OnViewerUpdate(viewerName)
    end
  end
end


-- ===================================================================
-- GROUP SCALE API
-- Per-group scale override (separate from global defaults)
-- Now using spec-based storage
-- ===================================================================

-- Get group scale for a viewer type (nil = use Edit Mode scale)
local function GetGroupScaleValue(viewerType)
  local groupSettings = Shared.GetGroupSettingsForType(viewerType)
  if not groupSettings then return nil end
  return groupSettings.scale
end

-- Check if custom scale is enabled for a viewer type
local function IsGroupScaleOverrideEnabled(viewerType)
  return GetGroupScaleValue(viewerType) ~= nil
end

-- Public API for group scale
function ns.CDMEnhance.GetGroupScaleValue(viewerType)
  return GetGroupScaleValue(viewerType)
end

function ns.CDMEnhance.IsGroupScaleOverrideEnabled(viewerType)
  return IsGroupScaleOverrideEnabled(viewerType)
end

-- Get the exact slot size in pixels when group scale override is enabled
-- This is THE single source of truth for icon size - both GroupSettings and ApplyIconStyle use this
function ns.CDMEnhance.GetGroupSlotSize(viewerType)
  local isEnabled = IsGroupScaleOverrideEnabled(viewerType)
  if not isEnabled then
    return nil  -- No override, let each system determine size
  end
  local scaleValue = GetGroupScaleValue(viewerType) or 1.0
  local baseSize = 40  -- Standard CDM icon base size
  local slotSize = math.floor(baseSize * scaleValue + 0.5)  -- PixelSnap
  return slotSize
end

local scaleSetThrottle = {}
function ns.CDMEnhance.SetGroupScale(viewerType, scale)
  -- Now using spec-based storage
  local groupSettings = Shared.GetSpecGroupSettings()
  if not groupSettings then return end
  
  if not groupSettings[viewerType] then
    groupSettings[viewerType] = {}
  end
  
  groupSettings[viewerType].scale = scale
  
  -- Invalidate cache so CDMGroups picks up new settings
  InvalidateEffectiveSettingsCache()
  
  -- Throttle the refresh to avoid lag while dragging slider
  local now = GetTime()
  if not scaleSetThrottle[viewerType] or (now - scaleSetThrottle[viewerType]) > 0.05 then
    scaleSetThrottle[viewerType] = now
    
    -- Refresh icon styles (CDMGroups handles size, we just update visuals)
    local refreshType = (viewerType == "aura") and "aura" or "cooldown"
    ns.CDMEnhance.RefreshIconType(refreshType)
    
    -- Tell CDMGroups to refresh layout
    if ns.CDMGroups and ns.CDMGroups.RefreshAllLayouts then
      ns.CDMGroups.RefreshAllLayouts()
    elseif ns.CDMGroupSettings and ns.CDMGroupSettings.ForceLayoutRefresh then
      ns.CDMGroupSettings.ForceLayoutRefresh(viewerType)
    end
  end
end

-- Alias for backwards compatibility - CDMGroups calls this
ns.CDMEnhance.RefreshAllStyles = ns.CDMEnhance.RefreshAllStyles or function() end
ns.CDMEnhance.RefreshAllIcons = ns.CDMEnhance.RefreshAllStyles

-- ===================================================================
-- ARC AURAS INTEGRATION
-- Arc Auras handles its own visual state (desaturation, glow)
-- This callback handles border sync
-- ===================================================================

--- Called by Arc Auras when an item's cooldown state changes
function ns.CDMEnhance.OnArcAuraStateChanged(arcID, isOnCooldown, remaining, duration)
    local frame = ns.ArcAuras and ns.ArcAuras.GetFrame and ns.ArcAuras.GetFrame(arcID)
    if not frame then return end
    
    -- Apply border desaturation sync if enabled
    if ns.CDMEnhance.ApplyBorderDesaturation then
        -- Arc Auras always desaturates unless noDesaturate is explicitly true
        local shouldDesaturate = isOnCooldown
        
        local cfg = ns.CDMEnhance.GetEffectiveIconSettings(arcID)
        if cfg and cfg.cooldownStateVisuals and cfg.cooldownStateVisuals.cooldownState then
            if cfg.cooldownStateVisuals.cooldownState.noDesaturate == true then
                shouldDesaturate = false
            end
        end
        
        ns.CDMEnhance.ApplyBorderDesaturation(frame, shouldDesaturate and 1 or 0)
    end
end

--- Refresh all Arc Aura frames
function ns.CDMEnhance.RefreshAllArcAuras()
    if ns.ArcAuras and ns.ArcAuras.RefreshAllFrames then
        ns.ArcAuras.RefreshAllFrames()
    end
end

-- Expose namespace globally for external tools (like CDMAnimExplorer)
ArcUI_NS = ns