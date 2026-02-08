-- ===================================================================
-- ArcUI_CooldownState.lua
-- Consolidated cooldown state visual system
--
-- Replaces the 1050-line ApplyCooldownStateVisuals with clean,
-- deduplicated logic and proper error handling.
--
-- KEY FIX: Fallback alpha/desat when curve evaluation fails.
-- Previously, failed pcall silently did nothing, leaving icons
-- stuck at the wrong alpha until leaving combat.
-- ===================================================================

local ADDON, ns = ...

ns.CooldownState = ns.CooldownState or {}

-- ═══════════════════════════════════════════════════════════════════
-- DEPENDENCY REFERENCES (resolved lazily on first call)
-- ═══════════════════════════════════════════════════════════════════
local CDM  -- ns.CDMEnhance
local CooldownCurves
local InitCooldownCurves
local GetTwoStateAlphaCurve
local GetSpellCooldownState
local GetEffectiveStateVisuals
local GetEffectiveReadyAlpha
local GetGlowThresholdCurve
local ShowReadyGlow
local HideReadyGlow
local SetGlowAlpha
local ShouldShowReadyGlow
local ApplyBorderDesaturation
local ApplyBorderDesaturationFromDuration

local resolved = false

local function ResolveDependencies()
  CDM = ns.CDMEnhance
  if not CDM then return false end

  CooldownCurves              = CDM.CooldownCurves
  InitCooldownCurves          = CDM.InitCooldownCurves
  GetTwoStateAlphaCurve       = CDM.GetTwoStateAlphaCurve
  GetSpellCooldownState       = CDM.GetSpellCooldownState
  GetEffectiveStateVisuals    = CDM.GetEffectiveStateVisuals
  GetEffectiveReadyAlpha      = CDM.GetEffectiveReadyAlpha
  GetGlowThresholdCurve       = CDM.GetGlowThresholdCurve
  ShowReadyGlow               = CDM.ShowReadyGlow
  HideReadyGlow               = CDM.HideReadyGlow or function() end
  SetGlowAlpha                = CDM.SetGlowAlpha
  ShouldShowReadyGlow         = CDM.ShouldShowReadyGlow
  ApplyBorderDesaturation     = CDM.ApplyBorderDesaturation
  ApplyBorderDesaturationFromDuration = CDM.ApplyBorderDesaturationFromDuration

  resolved = true
  return true
end

-- ═══════════════════════════════════════════════════════════════════
-- SMALL HELPERS
-- ═══════════════════════════════════════════════════════════════════

-- Resolve the CURRENT spell ID for a frame.
-- cfg._spellID is cached and goes stale when CDM swaps overrideSpellID
-- (e.g. Judgment 20271 ↔ Hammer of Wrath 24275). The cooldownID stays
-- the same so the cfg cache never invalidates. Always prefer the LIVE
-- overrideSpellID from the frame, with cfg._spellID as last fallback.
local function ResolveCurrentSpellID(frame, cfg)
  if frame.cooldownInfo then
    local live = frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID
    if live then return live end
  end
  return cfg._spellID
end

-- Resolve the actual icon texture (handles bar-style icons where
-- frame.Icon is a Frame container with an Icon child texture)
local function ResolveIconTexture(frame)
  local iconTex = frame.Icon or frame.icon
  if not iconTex then return nil end
  if not iconTex.SetDesaturated and iconTex.Icon then
    iconTex = iconTex.Icon
  end
  return iconTex
end

-- Set desaturation - SetDesaturation accepts secret values directly
local function SetDesat(iconTex, value)
  if not iconTex then return end
  if iconTex.SetDesaturation then
    iconTex:SetDesaturation(value or 0)
  end
end

-- Reset duration text elements to follow parent alpha
local function ResetDurationText(frame)
  local skip = frame._arcSwipeWaitForNoCharges
  if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
    if not skip then frame._arcCooldownText:SetIgnoreParentAlpha(false) end
  end
  if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
    if not skip then frame._arcChargeText:SetIgnoreParentAlpha(false) end
  end
  if frame.Cooldown and frame.Cooldown.Text and frame.Cooldown.Text.SetIgnoreParentAlpha then
    if not skip then frame.Cooldown.Text:SetIgnoreParentAlpha(false) end
  end
end

-- Make duration text elements ignore parent alpha (stay visible when dimmed)
local function PreserveDurationText(frame)
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
end

-- ═══════════════════════════════════════════════════════════════════
-- CONSOLIDATED: Apply ready state visuals
-- Replaces 6+ duplicated ready-state blocks across the original
-- ═══════════════════════════════════════════════════════════════════
local function ApplyReadyState(frame, iconTex, stateVisuals)
  local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)

  -- Alpha: clear curve enforcement, set ready enforcement if needed
  frame._arcTargetAlpha = nil
  if effectiveReadyAlpha < 1.0 then
    frame._arcEnforceReadyAlpha = true
    frame._arcReadyAlphaValue = effectiveReadyAlpha
  else
    frame._arcEnforceReadyAlpha = false
    frame._arcReadyAlphaValue = nil
  end

  frame._arcBypassFrameAlphaHook = true
  frame:SetAlpha(effectiveReadyAlpha)
  frame._arcBypassFrameAlphaHook = false

  -- Desaturation: force colored
  frame._arcBypassDesatHook = true
  frame._arcForceDesatValue = nil
  frame._arcDesatBranch = frame._arcDesatBranch or "READY"
  SetDesat(iconTex, 0)
  frame._arcBypassDesatHook = false

  -- Border
  ApplyBorderDesaturation(frame, 0)

  -- Show frame
  frame:Show()

  -- Reset duration text
  ResetDurationText(frame)
end

-- ═══════════════════════════════════════════════════════════════════
-- CONSOLIDATED: Apply curve-based alpha from a Duration object
--
-- KEY FIX: Falls back to direct cooldownAlpha on curve failure.
-- Previously, a failed pcall left _arcTargetAlpha unset and
-- _arcEnforceReadyAlpha cleared, so CDM could override freely →
-- icon stuck at wrong alpha until leaving combat.
-- ═══════════════════════════════════════════════════════════════════
local function ApplyCurveAlpha(frame, durObj, stateVisuals, isChargeSpell)
  -- Disable ready alpha enforcement — curve handles transitions
  frame._arcEnforceReadyAlpha = false
  frame._arcReadyAlphaValue = nil

  local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
  local alphaCurve = GetTwoStateAlphaCurve(effectiveReadyAlpha, stateVisuals.cooldownAlpha)

  if alphaCurve and durObj then
    local ok, alphaResult = pcall(function()
      return durObj:EvaluateRemainingPercent(alphaCurve)
    end)

    if ok and alphaResult ~= nil then
      -- Curve succeeded — store and apply
      frame._arcTargetAlpha = alphaResult
      frame._arcBypassFrameAlphaHook = true
      frame:SetAlpha(alphaResult)
      frame._arcBypassFrameAlphaHook = false

      -- Cooldown frame alpha (skip for charge spells with noGCDSwipe)
      local skipCooldownAlpha = isChargeSpell and frame._arcNoGCDSwipeEnabled
      if frame.Cooldown and not skipCooldownAlpha then
        if stateVisuals.preserveDurationText then
          frame.Cooldown:SetAlpha(1)
        else
          frame.Cooldown:SetAlpha(alphaResult)
        end
      end

      -- Duration text handling
      if stateVisuals.preserveDurationText then
        PreserveDurationText(frame)
      else
        ResetDurationText(frame)
      end

      return true  -- Success
    end
  end

  -- ═════════════════════════════════════════════════════════════════
  -- FALLBACK: Curve evaluation failed — apply cooldownAlpha directly
  -- This is the critical bug fix for "some spells not getting
  -- opacity changes until leaving combat"
  -- ═════════════════════════════════════════════════════════════════
  local fallbackAlpha = stateVisuals.cooldownAlpha
  frame._arcTargetAlpha = fallbackAlpha
  frame._arcBypassFrameAlphaHook = true
  frame:SetAlpha(fallbackAlpha)
  frame._arcBypassFrameAlphaHook = false

  if frame.Cooldown then
    if stateVisuals.preserveDurationText then
      frame.Cooldown:SetAlpha(1)
    else
      frame.Cooldown:SetAlpha(fallbackAlpha)
    end
  end

  if stateVisuals.preserveDurationText then
    PreserveDurationText(frame)
  else
    ResetDurationText(frame)
  end

  return false  -- Curve failed, used fallback
end

-- ═══════════════════════════════════════════════════════════════════
-- CONSOLIDATED: Apply curve-based desaturation
-- Handles cooldownDesaturate, noDesaturate, and CDM passthrough
-- ═══════════════════════════════════════════════════════════════════
local function ApplyCurveDesat(frame, iconTex, durObj, stateVisuals)
  if stateVisuals.noDesaturate then
    -- Force colored (block CDM's default desaturation)
    frame._arcDesatBranch = "CURVE_NODESAT"
    frame._arcForceDesatValue = 0
    frame._arcBypassDesatHook = true
    SetDesat(iconTex, 0)
    frame._arcBypassDesatHook = false
    ApplyBorderDesaturation(frame, 0)
    return true
  end

  if not stateVisuals.cooldownDesaturate then
    -- Let CDM handle desaturation (clear our forced value)
    frame._arcDesatBranch = "CURVE_CDM_HANDLES"
    frame._arcForceDesatValue = nil
    return true
  end

  -- cooldownDesaturate is enabled — apply curve
  if durObj and CooldownCurves and CooldownCurves.Binary then
    local ok, desatResult = pcall(function()
      return durObj:EvaluateRemainingPercent(CooldownCurves.Binary)
    end)

    if ok and desatResult ~= nil then
      frame._arcDesatBranch = "CURVE_EVAL"
      frame._arcForceDesatValue = nil  -- Let curve drive it
      frame._arcBypassDesatHook = true
      SetDesat(iconTex, desatResult)
      frame._arcBypassDesatHook = false
      ApplyBorderDesaturationFromDuration(frame, durObj)
      return true
    end
  end

  -- FALLBACK: Curve failed or no durObj — force desaturated directly
  frame._arcDesatBranch = "CURVE_FALLBACK"
  frame._arcForceDesatValue = 1
  frame._arcBypassDesatHook = true
  SetDesat(iconTex, 1)
  frame._arcBypassDesatHook = false
  ApplyBorderDesaturation(frame, 1)
  return false
end

-- ═══════════════════════════════════════════════════════════════════
-- CONSOLIDATED: Apply glow based on cooldown state
-- Handles normal spells, charge spells, glowWhileChargesAvailable
-- ═══════════════════════════════════════════════════════════════════
local function ApplyGlow(frame, stateVisuals, effectiveDurObj, isChargeSpell, durationObj, chargeDurObj, isOnGCD)
  if not ShouldShowReadyGlow(stateVisuals, frame) then
    HideReadyGlow(frame)
    return
  end

  -- Preview mode: always show
  local isPreview = ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsGlowPreviewActive
                    and frame.cooldownID and ns.CDMEnhanceOptions.IsGlowPreviewActive(frame.cooldownID)
  if isPreview then
    ShowReadyGlow(frame, stateVisuals)
    return
  end

  if not CooldownCurves or not CooldownCurves.BinaryInv then
    HideReadyGlow(frame)
    return
  end

  -- Determine which duration object to use for glow
  local glowDurObj = effectiveDurObj
  local needsGCDFilter = false

  if isChargeSpell and stateVisuals.glowWhileChargesAvailable then
    -- Use durationObj (any charge available = glow on)
    glowDurObj = durationObj
    needsGCDFilter = true  -- durationObj includes GCD
  end

  -- GCD filter: keep glow during GCD
  if needsGCDFilter and isOnGCD then
    SetGlowAlpha(frame, 1.0, stateVisuals)
    return
  end

  -- Apply curve
  if glowDurObj then
    local ok, glowAlpha = pcall(function()
      return glowDurObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
    end)
    if ok and glowAlpha ~= nil then
      SetGlowAlpha(frame, glowAlpha, stateVisuals)
      return
    end
  end

  -- No duration object or curve failed
  HideReadyGlow(frame)
end

-- Show/hide ready glow based on state
local function ApplyReadyGlow(frame, stateVisuals)
  if ShouldShowReadyGlow(stateVisuals, frame) then
    ShowReadyGlow(frame, stateVisuals)
  else
    HideReadyGlow(frame)
  end
end


-- ═══════════════════════════════════════════════════════════════════
-- PATH A: Ignore Aura Override
-- Shows spell cooldown state instead of aura duration.
-- Handles alpha, desaturation, glow — then returns.
-- ═══════════════════════════════════════════════════════════════════
local function HandleIgnoreAuraOverride(frame, iconTex, cfg, stateVisuals)
  local spellID = ResolveCurrentSpellID(frame, cfg)

  if not spellID then
    frame._arcReadyForGlow = false
    HideReadyGlow(frame)
    return
  end

  local isOnGCD, durationObj, isChargeSpell, chargeDurObj = GetSpellCooldownState(spellID)

  -- effectiveDurObj: chargeDurObj for charge spells, durationObj for normal
  -- waitForNoCharges: use durationObj instead (only has duration when ALL charges spent)
  local useWaitMode = isChargeSpell and stateVisuals.waitForNoCharges
  local effectiveDurObj = isChargeSpell and (useWaitMode and durationObj or chargeDurObj) or durationObj
  -- desatDurObj: always durationObj (tracks "any charge on CD" for charge spells)
  local desatDurObj = durationObj

  frame:Show()

  -- GCD filter for normal spells: show as ready during GCD
  if not isChargeSpell and isOnGCD then
    frame._arcDesatBranch = "IAO_GCD"
    ApplyReadyState(frame, iconTex, stateVisuals)
    ApplyReadyGlow(frame, stateVisuals)
    return
  end

  -- GCD freeze for charge spells with waitForNoCharges: show as ready during
  -- GCD to prevent phantom CD flicker (mirrors Path C / C4 GCD behavior)
  if useWaitMode and isOnGCD then
    frame._arcDesatBranch = "IAO_CHARGE_GCD"
    ApplyReadyState(frame, iconTex, stateVisuals)

    -- Glow: conditional on glowWhileChargesAvailable
    if ShouldShowReadyGlow(stateVisuals, frame) then
      if stateVisuals.glowWhileChargesAvailable then
        ShowReadyGlow(frame, stateVisuals)
      elseif chargeDurObj and CooldownCurves and CooldownCurves.BinaryInv then
        local ok, glowAlpha = pcall(function()
          return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
        end)
        if ok and glowAlpha ~= nil then
          SetGlowAlpha(frame, glowAlpha, stateVisuals)
        else
          HideReadyGlow(frame)
        end
      else
        HideReadyGlow(frame)
      end
    else
      HideReadyGlow(frame)
    end
    return
  end

  -- ALPHA: curve on effectiveDurObj
  ApplyCurveAlpha(frame, effectiveDurObj, stateVisuals, isChargeSpell)

  -- DURATION TEXT: Explicit handling for ignoreAuraOverride path
  -- ApplyCurveAlpha's ResetDurationText can be blocked by _arcSwipeWaitForNoCharges,
  -- so we force the correct state here regardless
  if stateVisuals.preserveDurationText then
    if frame.Cooldown then frame.Cooldown:SetAlpha(1) end
    PreserveDurationText(frame)
  else
    if frame.Cooldown and frame._arcTargetAlpha then
      frame.Cooldown:SetAlpha(frame._arcTargetAlpha)
    end
    -- Force reset — don't check _arcSwipeWaitForNoCharges
    if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
      frame._arcCooldownText:SetIgnoreParentAlpha(false)
    end
    if frame._arcChargeText and frame._arcChargeText.SetIgnoreParentAlpha then
      frame._arcChargeText:SetIgnoreParentAlpha(false)
    end
    if frame.Cooldown and frame.Cooldown.Text and frame.Cooldown.Text.SetIgnoreParentAlpha then
      frame.Cooldown.Text:SetIgnoreParentAlpha(false)
    end
  end

  -- DESATURATION: For ignoreAuraOverride, the aura being active is EXPECTED
  -- (selfAura buffs, totem frames, buff icon frames). Unlike HandleCooldownLogic
  -- where hasActiveAuraDisplay skips desat for target debuffs like Kidney Shot,
  -- here we always base desat on the COOLDOWN state since that's what we're showing.
  -- GCD FILTER: For charge spells, durationObj includes GCD timing. When a charge
  -- spell has charges available and is on GCD, don't desaturate — spell is usable.
  if isChargeSpell and isOnGCD then
    -- Charge spell on GCD with charges available: force colored
    frame._arcDesatBranch = "IAO_CHARGE_GCD_D"
    frame._arcForceDesatValue = 0
    frame._arcBypassDesatHook = true
    SetDesat(iconTex, 0)
    frame._arcBypassDesatHook = false
    ApplyBorderDesaturation(frame, 0)
  elseif stateVisuals.noDesaturate then
    -- User explicitly wants no desaturation
    frame._arcDesatBranch = "IAO_NODESAT"
    frame._arcForceDesatValue = 0
    frame._arcBypassDesatHook = true
    SetDesat(iconTex, 0)
    frame._arcBypassDesatHook = false
    ApplyBorderDesaturation(frame, 0)
  else
    -- Apply binary desat from cooldown duration object.
    -- CRITICAL: We cannot delegate to ApplyCurveDesat here because its
    -- "let CDM handle" path (when cooldownDesaturate is off) is wrong for
    -- ignoreAuraOverride. CDM is in aura mode showing the buff — it will
    -- never desaturate. We must always drive desat ourselves.
    if desatDurObj and CooldownCurves and CooldownCurves.Binary then
      local ok, desatResult = pcall(function()
        return desatDurObj:EvaluateRemainingPercent(CooldownCurves.Binary)
      end)
      if ok and desatResult ~= nil then
        frame._arcDesatBranch = "IAO_CURVE"
        frame._arcForceDesatValue = nil
        frame._arcBypassDesatHook = true
        SetDesat(iconTex, desatResult)
        frame._arcBypassDesatHook = false
        ApplyBorderDesaturationFromDuration(frame, desatDurObj)
      else
        frame._arcDesatBranch = "IAO_CURVE_FAIL"
        frame._arcForceDesatValue = 1
        frame._arcBypassDesatHook = true
        SetDesat(iconTex, 1)
        frame._arcBypassDesatHook = false
        ApplyBorderDesaturation(frame, 1)
      end
    else
      -- No durObj: spell is ready, force colored
      frame._arcDesatBranch = "IAO_NO_DUROBJ"
      frame._arcForceDesatValue = 0
      frame._arcBypassDesatHook = true
      SetDesat(iconTex, 0)
      frame._arcBypassDesatHook = false
      ApplyBorderDesaturation(frame, 0)
    end
  end

  -- GLOW: For waitForNoCharges, glow tracks per-charge recharge (chargeDurObj)
  -- even though alpha/desat track all-charges-spent (durationObj). Mirrors Path C.
  local glowDurObj = useWaitMode and chargeDurObj or effectiveDurObj
  ApplyGlow(frame, stateVisuals, glowDurObj, isChargeSpell, durationObj, chargeDurObj, isOnGCD)
end


-- ═══════════════════════════════════════════════════════════════════
-- PATH B: Aura Logic (buffs / debuffs / totems)
-- Uses event-driven caching from OptimizedApplyIconVisuals.
-- Skips recalculation when _arcTarget* flags are already set.
-- ═══════════════════════════════════════════════════════════════════
local function HandleAuraLogic(frame, iconTex, cfg, stateVisuals)
  local auraID = frame.auraInstanceID
  local isReady = (auraID and type(auraID) == "number" and auraID > 0)
                  or (frame.totemData ~= nil)

  -- ALPHA (skip if OptimizedApplyIconVisuals already set it)
  if frame._arcTargetAlpha == nil then
    local targetAlpha
    if isReady then
      local effectiveReadyAlpha = GetEffectiveReadyAlpha(stateVisuals)
      targetAlpha = effectiveReadyAlpha
      if effectiveReadyAlpha < 1.0 then
        frame._arcEnforceReadyAlpha = true
        frame._arcReadyAlphaValue = effectiveReadyAlpha
      else
        frame._arcEnforceReadyAlpha = false
      end
    else
      frame._arcEnforceReadyAlpha = false
      local cdAlpha = stateVisuals.cooldownAlpha
      if cdAlpha <= 0 then
        if ns.CDMEnhance.IsOptionsPanelOpen and ns.CDMEnhance.IsOptionsPanelOpen() then
          targetAlpha = 0.35
        else
          targetAlpha = 0
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

    if not frame:IsShown() then frame:Show() end
  end

  -- DESATURATION (skip if already set)
  if frame._arcTargetDesat == nil then
    local targetDesat
    if isReady then
      frame._arcDesatBranch = "AURA_READY"
      targetDesat = 0
    else
      frame._arcDesatBranch = "AURA_CD"
      targetDesat = stateVisuals.cooldownDesaturate and 1 or 0
    end

    frame._arcBypassDesatHook = true
    SetDesat(iconTex, targetDesat)
    frame._arcBypassDesatHook = false
    frame._arcTargetDesat = targetDesat
    ApplyBorderDesaturation(frame, targetDesat)
  end

  -- TINT (skip if already set)
  if frame._arcTargetTint == nil then
    local tR, tG, tB = 1, 1, 1
    if not isReady and stateVisuals.cooldownTint and stateVisuals.cooldownTintColor then
      local col = stateVisuals.cooldownTintColor
      tR, tG, tB = col.r or 0.5, col.g or 0.5, col.b or 0.5
    end
    frame._arcTargetTint = string.format("%.2f,%.2f,%.2f", tR, tG, tB)
    if iconTex then iconTex:SetVertexColor(tR, tG, tB) end
  end

  -- GLOW: Cooldown frames ALWAYS re-evaluate from cooldown duration curve.
  -- The curve result is secret — we pass it directly to SetAlpha (whitelisted).
  -- Caching _arcTargetGlow would prevent the curve from re-driving hide/show
  -- on subsequent ticks, causing the glow to stay visible after combat.
  -- Pure aura frames (cfg._isAura, totems) can cache since they use aura presence.
  local isCooldownFrame = not cfg._isAura and frame.totemData == nil
  if isCooldownFrame or frame._arcTargetGlow == nil then
    if isCooldownFrame then
      -- Cooldown-based glow: always driven by cooldown duration curve
      local glowSpellID = ResolveCurrentSpellID(frame, cfg)
      if glowSpellID then
        local glowOnGCD, glowDurObj, glowIsCharge, glowChargeDur = GetSpellCooldownState(glowSpellID)
        local glowEffective = glowIsCharge and glowChargeDur or glowDurObj
        ApplyGlow(frame, stateVisuals, glowEffective, glowIsCharge, glowDurObj, glowChargeDur, glowOnGCD)
      else
        ApplyReadyGlow(frame, stateVisuals)
      end
      -- Do NOT cache _arcTargetGlow for cooldown frames — curve must re-evaluate every tick
    elseif ShouldShowReadyGlow(stateVisuals, frame) and isReady then
      local threshold = stateVisuals.glowThreshold or 1.0

      if threshold < 1.0 and auraID then
        -- Threshold glow: use curve
        local auraType = stateVisuals.glowAuraType or "auto"
        local unit = "player"
        if auraType == "debuff" then
          unit = "target"
        elseif auraType == "auto" then
          local cat = frame.category
          if cat == 3 then unit = "target" end
        end

        local auraDurObj = C_UnitAuras and C_UnitAuras.GetAuraDuration
                           and C_UnitAuras.GetAuraDuration(unit, auraID)
        if auraDurObj then
          local thresholdCurve = GetGlowThresholdCurve(threshold)
          if thresholdCurve then
            local ok, glowAlpha = pcall(function()
              return auraDurObj:EvaluateRemainingPercent(thresholdCurve)
            end)
            if ok and glowAlpha ~= nil then
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
      frame._arcTargetGlow = true  -- Pure aura frame: cache is safe
    else
      HideReadyGlow(frame)
      frame._arcTargetGlow = true  -- Pure aura frame: cache is safe
    end
  end
end


-- ═══════════════════════════════════════════════════════════════════
-- PATH C: Cooldown Logic (spells with cooldowns)
-- ═══════════════════════════════════════════════════════════════════
local function HandleCooldownLogic(frame, iconTex, cfg, stateVisuals)
  local spellID = ResolveCurrentSpellID(frame, cfg)

  -- C1: No spell ID → ready state
  if not spellID then
    frame._arcDesatBranch = "C1_NO_SPELL"
    ApplyReadyState(frame, iconTex, stateVisuals)
    ApplyReadyGlow(frame, stateVisuals)
    return
  end

  -- Get cooldown state
  local isOnGCD, durationObj, isChargeSpell, chargeDurObj = GetSpellCooldownState(spellID)
  local effectiveDurObj = isChargeSpell and chargeDurObj or durationObj

  -- Check if CDM is actively displaying this frame as an AURA (not cooldown).
  -- When CDM shows the aura, the icon represents the active effect — don't desat.
  -- IMPORTANT: auraInstanceID > 0 alone is NOT sufficient. A selfAura spell
  -- (e.g. 315341) can have an active aura on the frame but CDM tracks it via
  -- cooldown (wasSetFromCooldown=true, wasSetFromAura=false). In that case CDM
  -- would natively desaturate it — we must not override with SetDesat(0).
  -- wasSetFromAura=true means CDM committed to aura tracking for this refresh.
  local cfgHasIgnoreAura = (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
                        or (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)
  local hasActiveAuraDisplay = not cfgHasIgnoreAura
                               and ((frame.wasSetFromAura == true)
                                    or (frame.totemData ~= nil))

  InitCooldownCurves()

  -- C2: GCD filter for normal spells — treat as ready during GCD
  if not isChargeSpell and isOnGCD then
    frame._arcDesatBranch = "C2_GCD"
    ApplyReadyState(frame, iconTex, stateVisuals)
    -- Hide swipe during GCD if noGCDSwipe enabled
    if frame.Cooldown and frame._arcNoGCDSwipeEnabled then
      frame._arcBypassSwipeHook = true
      frame.Cooldown:SetDrawSwipe(false)
      frame.Cooldown:SetDrawEdge(false)
      frame._arcBypassSwipeHook = false
    end
    ApplyReadyGlow(frame, stateVisuals)
    return
  end

  -- C3: GCD filter for charge spells with glowWhileChargesAvailable
  if isChargeSpell and isOnGCD and stateVisuals.glowWhileChargesAvailable then
    frame._arcDesatBranch = "C3_GCD_CHARGE"
    ApplyReadyState(frame, iconTex, stateVisuals)
    ApplyReadyGlow(frame, stateVisuals)
    return
  end

  -- C4: waitForNoCharges mode
  if isChargeSpell and stateVisuals.waitForNoCharges then
    if isOnGCD then
      -- FREEZE during GCD: show as ready (hides phantom CD flicker)
      frame._arcDesatBranch = "C4_GCD_FREEZE"
      ApplyReadyState(frame, iconTex, stateVisuals)

      -- Glow: conditional on glowWhileChargesAvailable
      if ShouldShowReadyGlow(stateVisuals, frame) then
        if stateVisuals.glowWhileChargesAvailable then
          ShowReadyGlow(frame, stateVisuals)
        elseif chargeDurObj and CooldownCurves and CooldownCurves.BinaryInv then
          local ok, glowAlpha = pcall(function()
            return chargeDurObj:EvaluateRemainingPercent(CooldownCurves.BinaryInv)
          end)
          if ok and glowAlpha ~= nil then
            SetGlowAlpha(frame, glowAlpha, stateVisuals)
          else
            HideReadyGlow(frame)
          end
        else
          HideReadyGlow(frame)
        end
      else
        HideReadyGlow(frame)
      end
      return
    else
      -- Not on GCD: apply curves using durationObj (not chargeDurObj!)
      frame:Show()
      ApplyCurveAlpha(frame, durationObj, stateVisuals, isChargeSpell)

      -- Skip desat if aura is actively displayed (spell effect is visually happening)
      if hasActiveAuraDisplay then
        frame._arcDesatBranch = "C4_AURA_ACTIVE"
        frame._arcForceDesatValue = 0
        frame._arcBypassDesatHook = true
        SetDesat(iconTex, 0)
        frame._arcBypassDesatHook = false
        ApplyBorderDesaturation(frame, 0)
      else
        ApplyCurveDesat(frame, iconTex, durationObj, stateVisuals)
      end

      -- Border sync (ApplyCurveDesat may have synced already, but this
      -- handles the "let CDM handle" case where border still needs update)
      ApplyBorderDesaturationFromDuration(frame, durationObj)

      -- Glow for waitForNoCharges
      ApplyGlow(frame, stateVisuals, chargeDurObj, isChargeSpell, durationObj, chargeDurObj, isOnGCD)
      return
    end
  end

  -- C5: Normal cooldown curve path
  if effectiveDurObj and CooldownCurves and CooldownCurves.initialized then
    frame:Show()
    ApplyCurveAlpha(frame, effectiveDurObj, stateVisuals, isChargeSpell)

    -- Skip desat if aura is actively displayed (spell effect is visually happening)
    if hasActiveAuraDisplay then
      frame._arcDesatBranch = "C5_AURA_ACTIVE"
      frame._arcForceDesatValue = 0
      frame._arcBypassDesatHook = true
      SetDesat(iconTex, 0)
      frame._arcBypassDesatHook = false
      ApplyBorderDesaturation(frame, 0)
    else
      ApplyCurveDesat(frame, iconTex, effectiveDurObj, stateVisuals)

      -- Border sync (skip if noDesaturate already handled it in ApplyCurveDesat)
      if not stateVisuals.noDesaturate then
        ApplyBorderDesaturationFromDuration(frame, effectiveDurObj)
      end
    end

    -- Glow
    ApplyGlow(frame, stateVisuals, effectiveDurObj, isChargeSpell, durationObj, chargeDurObj, isOnGCD)
    return
  end

  -- C6: Fallback — no data, assume ready
  frame._arcDesatBranch = "C6_NO_DATA"
  ApplyReadyState(frame, iconTex, stateVisuals)
  ApplyReadyGlow(frame, stateVisuals)
end


-- ═══════════════════════════════════════════════════════════════════
-- MAIN DISPATCHER
-- Drop-in replacement for ApplyCooldownStateVisuals
-- Same signature: (frame, cfg, normalAlpha, stateVisuals)
-- ═══════════════════════════════════════════════════════════════════
local function NewApplyCooldownStateVisuals(frame, cfg, normalAlpha, stateVisuals)
  if not frame then return end

  -- Lazy-init dependencies on first call
  if not resolved then
    if not ResolveDependencies() then return end
  end

  -- Arc Auras handles its own cooldown state visuals
  if frame._arcConfig or frame._arcAuraID then return end

  local iconTex = ResolveIconTexture(frame)
  if not iconTex then return end

  -- Get state visuals if not passed (caller may pass for perf)
  if not stateVisuals then
    stateVisuals = GetEffectiveStateVisuals(cfg)
  end

  -- Check glow preview
  local cdID = frame.cooldownID
  local isGlowPreview = cdID and ns.CDMEnhanceOptions
                        and ns.CDMEnhanceOptions.IsGlowPreviewActive
                        and ns.CDMEnhanceOptions.IsGlowPreviewActive(cdID)

  -- Check ignoreAuraOverride
  local ignoreAuraOverride = (cfg.auraActiveState and cfg.auraActiveState.ignoreAuraOverride)
                          or (cfg.cooldownSwipe and cfg.cooldownSwipe.ignoreAuraOverride)

  -- No state visuals + no preview + no ignoreAuraOverride → let CDM handle
  if not stateVisuals and not isGlowPreview and not ignoreAuraOverride then
    -- Only reset desat if WE were previously managing it (e.g. user just
    -- disabled their cooldownDesaturate setting). If the previous branch was
    -- already NO_SV_EARLY or nil, CDM has been handling desat natively and
    -- we must not override it — doing so nukes CDM's own desaturation on
    -- combat-end refresh timers (PLAYER_REGEN_ENABLED).
    local prevBranch = frame._arcDesatBranch
    local wasManagedDesat = prevBranch ~= nil and prevBranch ~= "NO_SV_EARLY"

    frame._arcForceDesatValue = nil
    frame._arcReadyForGlow = false
    frame._arcDesatBranch = "NO_SV_EARLY"
    HideReadyGlow(frame)

    if wasManagedDesat then
      -- We were previously driving desat — clean up so CDM can take over
      SetDesat(iconTex, 0)
      iconTex:SetVertexColor(1, 1, 1)
      ApplyBorderDesaturation(frame, 0)
    end
    return
  end

  -- Build default stateVisuals if needed (for preview / ignoreAuraOverride)
  if not stateVisuals then
    local rs = cfg.cooldownStateVisuals and cfg.cooldownStateVisuals.readyState or {}
    stateVisuals = {
      readyAlpha          = 1.0,
      readyGlow           = isGlowPreview and true or (rs.glow == true),
      readyGlowType       = rs.glowType or "button",
      readyGlowColor      = rs.glowColor,
      readyGlowIntensity  = rs.glowIntensity or 1.0,
      readyGlowScale      = rs.glowScale or 1.0,
      readyGlowSpeed      = rs.glowSpeed or 0.25,
      readyGlowLines      = rs.glowLines or 8,
      readyGlowThickness  = rs.glowThickness or 2,
      readyGlowParticles  = rs.glowParticles or 4,
      readyGlowXOffset    = rs.glowXOffset or 0,
      readyGlowYOffset    = rs.glowYOffset or 0,
      cooldownAlpha       = 1.0,
    }
  end

  -- Preview mode: show glow immediately
  if isGlowPreview then
    ShowReadyGlow(frame, stateVisuals)
    return
  end

  -- Ensure curves are initialized
  InitCooldownCurves()

  -- Detect what kind of icon this is
  local useAuraLogic = cfg._isAura or false
  -- Route based on what CDM is CURRENTLY doing with this frame:
  --   wasSetFromAura = CDM actively showing aura duration (runtime flag)
  --   totemData      = totem frame (always aura logic)
  -- NOTE: cooldownInfo.hasAura means "spell CAN produce auras" (e.g. Kidney Shot's
  --   target stun), NOT that CDM is showing aura data. Using it for routing incorrectly
  --   sends cooldown-tracked frames (wasSetFromCooldown=true) through aura logic.
  if not useAuraLogic then
    if frame.totemData ~= nil then
      useAuraLogic = true
    elseif frame.wasSetFromAura == true then
      useAuraLogic = true
    end
  end

  -- ═════════════════════════════════════════════════════════════════
  -- DISPATCH to the appropriate handler
  -- NOTE: _arcIgnoreAuraOverride is set INSIDE the dispatch so the
  -- desat hook only activates when we actually route to HandleIgnoreAuraOverride.
  -- Setting it before dispatch caused the hook to interfere with
  -- HandleCooldownLogic on frames where ignoreAuraOverride is enabled
  -- but CDM tracks via cooldown (e.g. Keg Smash: hasAura=true static
  -- flag, but Blizzard disabled the aura display so wasSetFromAura=false).
  -- ═════════════════════════════════════════════════════════════════
  if ignoreAuraOverride then
    -- Smart ignoreAuraOverride: only apply when CDM would actually show
    -- aura duration for this frame. The override is meaningless for frames
    -- that CDM already tracks via cooldown.
    --   wasSetFromAura = true → CDM is CURRENTLY showing aura data (runtime flag)
    --   cfg._isAura           → ArcUI buff icon frame
    --   totemData             → totem frame
    --   hasAura = true        → CDM shows aura duration (target debuffs like Kidney Shot)
    --   selfAura = true       → CDM shows self-buff duration (Adrenaline Rush, Icy Veins)
    -- NOTE: hasAura and selfAura are STATIC flags on the base cooldownID.
    -- When the frame has an overrideSpellID that changes the active spell,
    -- the override spell may NOT have a selfAura even though the base does.
    -- RUNTIME STATE TAKES PRIORITY: If CDM has explicitly committed to
    -- cooldown tracking (wasSetFromCooldown=true, wasSetFromAura=false),
    -- the static flags should NOT force us into ignoreAuraOverride — the
    -- current spell has no aura to ignore.
    local cooldownInfo = frame.cooldownInfo
    local cdmExplicitlyTrackingCooldown = (frame.wasSetFromCooldown == true and frame.wasSetFromAura ~= true)
    local cdmWouldShowAura = cfg._isAura
                             or (frame.totemData ~= nil)
                             or (frame.wasSetFromAura == true)
                             -- Only use static flags when CDM hasn't committed to a source yet
                             -- (covers initial load, out-of-combat, and edge cases)
                             or (not cdmExplicitlyTrackingCooldown
                                 and cooldownInfo
                                 and (cooldownInfo.hasAura == true or cooldownInfo.selfAura == true))
    if cdmWouldShowAura then
      frame._arcDesatBranch = "DISPATCH_IAO"
      frame._arcIgnoreAuraOverride = true
      HandleIgnoreAuraOverride(frame, iconTex, cfg, stateVisuals)
    elseif useAuraLogic then
      frame._arcDesatBranch = "DISPATCH_AURA"
      frame._arcIgnoreAuraOverride = false
      HandleAuraLogic(frame, iconTex, cfg, stateVisuals)
    else
      frame._arcDesatBranch = "DISPATCH_CD"
      frame._arcIgnoreAuraOverride = false
      HandleCooldownLogic(frame, iconTex, cfg, stateVisuals)
    end
  elseif useAuraLogic then
    frame._arcDesatBranch = "DISPATCH_AURA"
    frame._arcIgnoreAuraOverride = false
    HandleAuraLogic(frame, iconTex, cfg, stateVisuals)
  else
    frame._arcDesatBranch = "DISPATCH_CD"
    frame._arcIgnoreAuraOverride = false
    HandleCooldownLogic(frame, iconTex, cfg, stateVisuals)
  end
end


-- ═══════════════════════════════════════════════════════════════════
-- INSTALL: Override the CDMEnhance function
-- Because CDMEnhance makes its local a relay (see CDMEnhance changes),
-- all internal call sites now route through this new implementation.
-- ═══════════════════════════════════════════════════════════════════
ns.CDMEnhance.ApplyCooldownStateVisuals = NewApplyCooldownStateVisuals

-- Export sub-functions for testing / external use
ns.CooldownState.Apply              = NewApplyCooldownStateVisuals
ns.CooldownState.ApplyReadyState    = ApplyReadyState
ns.CooldownState.ApplyCurveAlpha    = ApplyCurveAlpha
ns.CooldownState.ApplyCurveDesat    = ApplyCurveDesat
ns.CooldownState.ApplyGlow          = ApplyGlow
ns.CooldownState.ApplyReadyGlow     = ApplyReadyGlow
ns.CooldownState.ResolveIconTexture = ResolveIconTexture