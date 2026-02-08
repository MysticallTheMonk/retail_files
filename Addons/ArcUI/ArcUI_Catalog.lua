-- ===================================================================
-- ArcUI_Catalog.lua
-- Catalog system for discovering and managing buffs/debuffs from CD Manager
-- Provides a visual catalog where users can browse and create bars/icons
--
-- COMBAT SAFETY:
-- - Default scanning uses frame iteration (GetChildren) - ALWAYS SAFE
-- - Frame-based catalog is safe to read and create bars from (NO TAINT)
-- - CDM DataProvider API calls are only used for "Auto-Setup" mode
-- - All modifications via DataProvider require out-of-combat and cause taint
--
-- TAINT PREVENTION:
-- - Frame-based scan = SAFE (default)
-- - DataProvider scan = only for discovering hidden/untracked items
-- - CDM modifications trigger reload warning
-- ===================================================================

local ADDON, ns = ...
ns.Catalog = ns.Catalog or {}

-- ===================================================================
-- CATALOG DATA STORAGE
-- ===================================================================
-- Master catalog of all discovered auras from CD Manager frames
-- Structure: { cooldownID = { name, icon, spellID, category, ... } }
-- This is a CACHED SNAPSHOT from frame scanning - safe to read anytime
local masterCatalog = {}

-- Last scan timestamp
local lastScanTime = 0

-- Combat state tracking
local isInCombat = false

-- ===================================================================
-- CDM MODIFICATION TRACKING (Taint Prevention)
-- ===================================================================
-- Track if we've made CDM changes that require a reload
local cdmModificationsMade = false
local cdmModificationCount = 0

-- Reload warning frame
local reloadWarningFrame = nil

-- Category display names (built safely to handle missing enums)
local CATEGORY_NAMES = {}

-- Build category names table safely after game loads
local function BuildCategoryNames()
  if Enum and Enum.CooldownViewerCategory then
    local cat = Enum.CooldownViewerCategory
    if cat.TrackedBuff then CATEGORY_NAMES[cat.TrackedBuff] = "Tracked Buffs" end
    if cat.TrackedBar then CATEGORY_NAMES[cat.TrackedBar] = "Tracked Bars" end
    if cat.HiddenAura then CATEGORY_NAMES[cat.HiddenAura] = "Hidden (Buffs)" end
    if cat.HiddenSpell then CATEGORY_NAMES[cat.HiddenSpell] = "Hidden (Spells)" end
    if cat.Essential then CATEGORY_NAMES[cat.Essential] = "Essential Cooldowns" end
    if cat.Utility then CATEGORY_NAMES[cat.Utility] = "Utility Cooldowns" end
  end
  -- Handle pseudo-categories (defined as -1 and -2 in CD Manager)
  CATEGORY_NAMES[-1] = "Hidden (Spells)"
  CATEGORY_NAMES[-2] = "Hidden (Buffs)"
end

-- ===================================================================
-- RELOAD WARNING POPUP
-- ===================================================================
local function CreateReloadWarningFrame()
  if reloadWarningFrame then return reloadWarningFrame end
  
  local frame = CreateFrame("Frame", "ArcUICDMReloadWarning", UIParent, "BackdropTemplate")
  frame:SetSize(450, 180)
  frame:SetPoint("CENTER", 0, 150)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(500)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetClampedToScreen(true)
  
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
  
  -- Warning icon
  local icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(48, 48)
  icon:SetPoint("TOPLEFT", 20, -20)
  icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
  
  -- Title
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 10, -22)
  title:SetText("|cffff9900CD Manager Modified|r")
  
  -- Message text
  local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("TOP", 0, -55)
  text:SetWidth(400)
  text:SetJustifyH("CENTER")
  text:SetText("Arc UI has made changes to the Cooldown Manager.\n\n" ..
    "|cffffffffA reload is required|r to prevent UI taint issues.\n" ..
    "Your changes have been saved and will persist after reload.\n\n" ..
    "|cff888888(You can continue making changes before reloading)|r")
  
  -- Count text
  frame.countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.countText:SetPoint("BOTTOM", 0, 55)
  frame.countText:SetTextColor(0.7, 0.7, 0.7)
  
  -- Reload Now button
  local reloadBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  reloadBtn:SetSize(140, 28)
  reloadBtn:SetPoint("BOTTOMLEFT", 40, 18)
  reloadBtn:SetText("Reload Now")
  reloadBtn:SetScript("OnClick", function()
    ReloadUI()
  end)
  
  -- Later button
  local laterBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  laterBtn:SetSize(140, 28)
  laterBtn:SetPoint("BOTTOMRIGHT", -40, 18)
  laterBtn:SetText("Later")
  laterBtn:SetScript("OnClick", function()
    frame:Hide()
  end)
  
  frame:Hide()
  reloadWarningFrame = frame
  return frame
end

-- Show reload warning
function ns.Catalog.ShowReloadWarning()
  local frame = CreateReloadWarningFrame()
  frame.countText:SetText(string.format("Changes made: %d", cdmModificationCount))
  frame:Show()
end

-- Check if reload is needed
function ns.Catalog.IsReloadRequired()
  return cdmModificationsMade
end

-- Get modification count
function ns.Catalog.GetModificationCount()
  return cdmModificationCount
end

-- Reset modification tracking (called after reload - tracked in saved vars)
function ns.Catalog.ResetModificationTracking()
  cdmModificationsMade = false
  cdmModificationCount = 0
end

-- ===================================================================
-- COMBAT SAFETY HELPERS
-- ===================================================================
-- Check if it's safe to access CDM DataProvider API (for auto-setup only)
function ns.Catalog.IsSafeToAccessCDM()
  return not InCombatLockdown() and not isInCombat
end

-- Check if CD Manager UI globals exist
function ns.Catalog.IsCDManagerAvailable()
  return _G["BuffIconCooldownViewer"] ~= nil or _G["BuffBarCooldownViewer"] ~= nil
end

-- Check if DataProvider is available (for advanced features)
function ns.Catalog.IsDataProviderAvailable()
  return CooldownViewerSettings ~= nil and CooldownViewerDataProvider ~= nil
end

-- ===================================================================
-- COMBAT-SAFE FRAME ACCESS
-- These functions iterate the viewer frame children directly
-- This is ALWAYS SAFE - no taint issues
-- ===================================================================

-- Get all frames from BuffIconCooldownViewer (combat-safe)
local function GetAllBuffFrames()
  local viewer = _G["BuffIconCooldownViewer"]
  if not viewer then
    return {}, "BuffIconCooldownViewer not found"
  end
  
  local allFrames = {}
  local children = {viewer:GetChildren()}
  
  for _, child in ipairs(children) do
    table.insert(allFrames, child)
  end
  
  return allFrames, nil
end

-- Get all frames from BuffBarCooldownViewer (combat-safe)
local function GetAllBarFrames()
  local viewer = _G["BuffBarCooldownViewer"]
  if not viewer then
    return {}, "BuffBarCooldownViewer not found"
  end
  
  local allFrames = {}
  local children = {viewer:GetChildren()}
  
  for _, child in ipairs(children) do
    table.insert(allFrames, child)
  end
  
  return allFrames, nil
end

-- ===================================================================
-- CATALOG SCANNING - Now uses centralized Core.lua scanner
-- Catalog adds extra fields needed for bar creation UI
-- ===================================================================

-- Called by Core.lua after central scan completes
function ns.Catalog.OnCDMScanComplete()
  -- Rebuild masterCatalog from central data
  wipe(masterCatalog)
  
  local allIcons = ns.API and ns.API.GetAllCDMIcons() or {}
  
  for cooldownID, data in pairs(allIcons) do
    -- Only include auras (TrackedBuff/TrackedBar) in catalog
    if data.isAura then
      masterCatalog[cooldownID] = {
        cooldownID = cooldownID,
        name = data.name,
        icon = data.icon,
        spellID = data.spellID,
        category = data.category,
        categoryName = data.categoryName,
        isTracked = true,
        isTrackedBuff = data.isTrackedBuff,
        isTrackedBar = data.isTrackedBar,
        isDisplayed = true,  -- All icons in central cache are displayed
        isDisplayedAsBuff = data.isTrackedBuff,
        isDisplayedAsBar = data.isTrackedBar,
        isHidden = false,
        isSpell = false,
        isBuff = true,
        sourceType = data.isTrackedBar and "bar" or "icon",
        -- API fields
        selfAura = data.selfAura,
        hasAura = data.hasAura,
        charges = data.charges,
        flags = data.flags,
        frame = data.frame,
        iconFrame = data.iconFrame,
        barFrame = data.barFrame,
        -- ArcUI status
        arcUIBarNum = ns.Catalog.FindArcUIBarByCooldownID(cooldownID),
      }
    end
  end
  
  lastScanTime = GetTime()
  
  if ns.devMode then
    local count = 0
    for _ in pairs(masterCatalog) do count = count + 1 end
    print(string.format("|cff00FF00[ArcUI Catalog]|r Rebuilt from central scan: %d aura entries", count))
  end
end

function ns.Catalog.ScanTrackedFrames()
  -- Call central scanner (which will call OnCDMScanComplete when done)
  local total = ns.API and ns.API.ScanAllCDMIcons() or 0
  
  -- Count by type
  local trackedBuffs = 0
  local trackedBars = 0
  local displayedCount = 0
  for _, entry in pairs(masterCatalog) do
    if entry.isTrackedBuff then trackedBuffs = trackedBuffs + 1 end
    if entry.isTrackedBar then trackedBars = trackedBars + 1 end
    if entry.isDisplayed then displayedCount = displayedCount + 1 end
  end
  
  return displayedCount, trackedBuffs, trackedBars
end

-- Refresh just the hasAura status for all catalog entries (lightweight update)
function ns.Catalog.RefreshActiveStatus()
  if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCooldownInfo then
    return
  end
  
  for cooldownID, entry in pairs(masterCatalog) do
    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    if info then
      entry.hasAura = info.hasAura
    end
  end
end

-- Wrapper function that returns values in format expected by TrackingOptions
-- Returns: success (bool), count (number), buffs (number), bars (number)
function ns.Catalog.ScanAll()
  -- Combat protection
  if InCombatLockdown() then
    return false, "Cannot scan during combat"
  end
  
  local count, buffs, bars = ns.Catalog.ScanTrackedFrames()
  return true, count or 0, buffs or 0, bars or 0
end

-- ===================================================================
-- ARCUI BAR LOOKUP (Always safe - reads our own DB)
-- ===================================================================

-- Find if a cooldownID is already used by an ArcUI bar
-- Also checks by buffName and spellID as fallback for bars created before cooldownID tracking
function ns.Catalog.FindArcUIBarByCooldownID(cooldownID)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.bars then return nil end
  
  -- Get catalog entry to get name and spellID for fallback matching
  local entry = masterCatalog[cooldownID]
  local entryName = entry and entry.name
  local entrySpellID = entry and entry.spellID
  local entryDisplaySpellID = entry and entry.displaySpellID
  
  for i = 1, 30 do
    local cfg = db.bars[i]
    if cfg and cfg.tracking then
      -- Check both regular enabled AND custom enabled bars
      if cfg.tracking.enabled or cfg.tracking.customEnabled then
        -- Primary: match by cooldownID
        if cfg.tracking.cooldownID == cooldownID then
          return i
        end
        
        -- Fallback 1: match by buffName
        if entryName and cfg.tracking.buffName == entryName then
          return i
        end
        
        -- Fallback 2: match by spellID
        if entrySpellID and cfg.tracking.spellID == entrySpellID then
          return i
        end
        
        -- Fallback 3: match by displaySpellID
        if entryDisplaySpellID and cfg.tracking.displaySpellID == entryDisplaySpellID then
          return i
        end
      end
    end
  end
  
  return nil
end

-- Find ALL ArcUI bars using a cooldownID (allows multiple bars from same buff)
-- Also checks by buffName and spellID as fallback for bars created before cooldownID tracking
function ns.Catalog.FindAllArcUIBarsByCooldownID(cooldownID)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.bars then return {} end
  
  -- Get catalog entry to get name and spellID for fallback matching
  local entry = masterCatalog[cooldownID]
  local entryName = entry and entry.name
  local entrySpellID = entry and entry.spellID
  local entryDisplaySpellID = entry and entry.displaySpellID
  
  local bars = {}
  local seenBars = {}  -- Avoid duplicates
  
  for i = 1, 30 do
    local cfg = db.bars[i]
    if cfg and cfg.tracking then
      -- Check both regular enabled AND custom enabled bars
      if cfg.tracking.enabled or cfg.tracking.customEnabled then
        local matched = false
        
        -- Primary: match by cooldownID
        if cfg.tracking.cooldownID == cooldownID then
          matched = true
        end
        
        -- Fallback 1: match by buffName
        if not matched and entryName and cfg.tracking.buffName == entryName then
          matched = true
        end
        
        -- Fallback 2: match by spellID
        if not matched and entrySpellID and cfg.tracking.spellID == entrySpellID then
          matched = true
        end
        
        -- Fallback 3: match by displaySpellID
        if not matched and entryDisplaySpellID and cfg.tracking.displaySpellID == entryDisplaySpellID then
          matched = true
        end
        
        if matched and not seenBars[i] then
          seenBars[i] = true
          table.insert(bars, {
            barNum = i,
            mode = cfg.tracking.useDurationBar and "duration" or "stacks"
          })
        end
      end
    end
  end
  
  return bars
end

-- Find if a cooldownID is already used by an ArcUI bar (by icon texture)
function ns.Catalog.FindArcUIBarByIcon(iconID)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.bars then return nil end
  
  for i = 1, 30 do
    local cfg = db.bars[i]
    if cfg and cfg.tracking and cfg.tracking.enabled then
      if cfg.tracking.iconTextureID == iconID then
        return i
      end
    end
  end
  
  return nil
end

-- ===================================================================
-- CATALOG ACCESS (Always safe - reads cached masterCatalog)
-- ===================================================================

-- Get filtered catalog entries (reads from cache, always safe)
function ns.Catalog.GetFilteredCatalog(filterKey, searchText)
  filterKey = filterKey or "all"
  searchText = searchText and searchText:lower() or ""
  
  local results = {}
  
  for cooldownID, entry in pairs(masterCatalog) do
    local passesFilter = false
    local passesSearch = true
    
    -- Category filter
    if filterKey == "all" then
      passesFilter = true
    elseif filterKey == "tracked" then
      passesFilter = entry.isTracked
    elseif filterKey == "buffs" then
      passesFilter = entry.isTrackedBuff
    elseif filterKey == "bars" then
      passesFilter = entry.isTrackedBar
    elseif filterKey == "buffs_all" then
      passesFilter = entry.isBuff
    end
    
    -- Search filter
    if searchText ~= "" and passesFilter then
      local nameLower = entry.name:lower()
      passesSearch = nameLower:find(searchText, 1, true) ~= nil
    end
    
    if passesFilter and passesSearch then
      table.insert(results, entry)
    end
  end
  
  -- Sort by name (use pcall since name might be a secret value)
  table.sort(results, function(a, b)
    local success, result = pcall(function()
      return (a.name or "") < (b.name or "")
    end)
    if success then
      return result
    end
    -- Fallback: sort by cooldownID if name comparison fails
    return (a.cooldownID or 0) < (b.cooldownID or 0)
  end)
  
  return results
end

-- Get all catalog entries as a sorted array (reads from cache, always safe)
function ns.Catalog.GetAllEntries()
  local results = {}
  for _, entry in pairs(masterCatalog) do
    table.insert(results, entry)
  end
  -- Sort by name (use pcall since name might be a secret value)
  table.sort(results, function(a, b)
    local success, result = pcall(function()
      return (a.name or "") < (b.name or "")
    end)
    if success then
      return result
    end
    return (a.cooldownID or 0) < (b.cooldownID or 0)
  end)
  return results
end

-- Get a single entry by cooldownID (reads from cache, always safe)
function ns.Catalog.GetEntry(cooldownID)
  return masterCatalog[cooldownID]
end

-- Get entry count (reads from cache, always safe)
function ns.Catalog.GetCount()
  local count = 0
  for _ in pairs(masterCatalog) do
    count = count + 1
  end
  return count
end

-- Check if catalog has been populated
function ns.Catalog.IsPopulated()
  return next(masterCatalog) ~= nil
end

-- Get last scan time
function ns.Catalog.GetLastScanTime()
  return lastScanTime
end

-- ===================================================================
-- CD MANAGER MANIPULATION (OUT OF COMBAT ONLY - CAUSES TAINT!)
-- These functions modify CDM and require a reload
-- Only used for "Auto-Setup" mode
-- ===================================================================

-- Enable tracking for an aura in CD Manager
-- WARNING: This taints CDM - reload required!
function ns.Catalog.EnableInCDManager(cooldownID, targetCategory)
  if not ns.Catalog.IsSafeToAccessCDM() then
    return false, "Cannot modify during combat"
  end
  
  if not ns.Catalog.IsDataProviderAvailable() then
    return false, "CD Manager DataProvider not available"
  end
  
  local dataProvider = CooldownViewerSettings:GetDataProvider()
  if not dataProvider then
    return false, "CD Manager not available"
  end
  
  local layoutManager = CooldownViewerSettings:GetLayoutManager()
  if not layoutManager then
    return false, "Layout manager not available"
  end
  
  -- Default to TrackedBuff if no category specified
  if not targetCategory and Enum and Enum.CooldownViewerCategory then
    targetCategory = Enum.CooldownViewerCategory.TrackedBuff
  end
  
  if not targetCategory then
    return false, "Category enum not available"
  end
  
  -- Lock notifications to prevent buggy RefreshLayout from running
  layoutManager:LockNotifications()
  
  local status = dataProvider:SetCooldownToCategory(cooldownID, targetCategory)
  
  if status == Enum.CooldownLayoutStatus.Success then
    -- Track that we modified CDM
    cdmModificationsMade = true
    cdmModificationCount = cdmModificationCount + 1
    
    -- Mark dirty for next natural refresh
    dataProvider:MarkDirty()
    
    -- Save the layout
    if CooldownViewerSettings.SaveCurrentLayout then
      CooldownViewerSettings:SaveCurrentLayout()
    end
    
    -- Unlock WITHOUT forcing notify (false = don't trigger refresh)
    layoutManager:UnlockNotifications(false)
    
    return true, "Enabled successfully (reload required)"
  end
  
  -- Unlock on failure too
  layoutManager:UnlockNotifications(false)
  
  return false, "Failed to enable (status: " .. tostring(status) .. ")"
end

-- Disable tracking for an aura in CD Manager (move to Hidden)
-- WARNING: This taints CDM - reload required!
function ns.Catalog.DisableInCDManager(cooldownID)
  if not ns.Catalog.IsSafeToAccessCDM() then
    return false, "Cannot modify during combat"
  end
  
  if not ns.Catalog.IsDataProviderAvailable() then
    return false, "CD Manager DataProvider not available"
  end
  
  local dataProvider = CooldownViewerSettings:GetDataProvider()
  if not dataProvider then
    return false, "CD Manager not available"
  end
  
  local layoutManager = CooldownViewerSettings:GetLayoutManager()
  if not layoutManager then
    return false, "Layout manager not available"
  end
  
  local hiddenCategory = Enum and Enum.CooldownViewerCategory and Enum.CooldownViewerCategory.HiddenAura
  if not hiddenCategory then
    hiddenCategory = -2  -- Fallback to pseudo-category
  end
  
  -- Lock notifications to prevent buggy RefreshLayout
  layoutManager:LockNotifications()
  
  local status = dataProvider:SetCooldownToCategory(cooldownID, hiddenCategory)
  
  if status == Enum.CooldownLayoutStatus.Success then
    -- Track that we modified CDM
    cdmModificationsMade = true
    cdmModificationCount = cdmModificationCount + 1
    
    -- Mark dirty for next natural refresh
    dataProvider:MarkDirty()
    
    -- Save the layout
    if CooldownViewerSettings.SaveCurrentLayout then
      CooldownViewerSettings:SaveCurrentLayout()
    end
    
    -- Unlock WITHOUT forcing notify
    layoutManager:UnlockNotifications(false)
    
    return true, "Disabled successfully (reload required)"
  end
  
  -- Unlock on failure too
  layoutManager:UnlockNotifications(false)
  
  return false, "Failed to disable"
end

-- Check if an aura is currently tracked in CDM (from cached catalog)
function ns.Catalog.IsTrackedInCDM(cooldownID)
  local entry = masterCatalog[cooldownID]
  if not entry then return false, false end
  return entry.isTrackedBuff, entry.isTrackedBar
end

-- ===================================================================
-- CDM FRAME VISIBILITY (uses existing Core API - always safe)
-- ===================================================================
function ns.Catalog.HideCDMForBar(barNum)
  if ns.API and ns.API.SetHideBuffIcon then
    ns.API.SetHideBuffIcon(true, barNum)
    return true
  end
  return false
end

function ns.Catalog.ShowCDMForBar(barNum)
  if ns.API and ns.API.SetHideBuffIcon then
    ns.API.SetHideBuffIcon(false, barNum)
    return true
  end
  return false
end

-- ===================================================================
-- CREATE ARCUI BAR/ICON FROM CATALOG ENTRY (SAFE - NO CDM MODIFICATION)
-- These functions ONLY create bars from items already in the catalog
-- (which only contains already-tracked items from frame scanning)
-- ===================================================================

-- Create an ArcUI bar or icon from a catalog entry
function ns.Catalog.CreateArcUIDisplay(cooldownID, displayType, options)
  options = options or {}
  displayType = displayType or "bar"
  
  local entry = masterCatalog[cooldownID]
  if not entry then
    return false, "Aura not found in catalog.\n\nMake sure it's in CD Manager's 'Tracked Buffs' or 'Tracked Bars',\nthen click 'Scan CD Manager'."
  end
  
  -- Determine source type based on what's available
  local sourceType = options.sourceType or "icon"
  
  -- For duration bars, prefer bar source if available, but icon works too
  if options.useDurationBar then
    if entry.isDisplayedAsBar then
      sourceType = "bar"
    else
      sourceType = "icon"  -- Duration bars now work with icon source too!
    end
  end
  
  -- Check if it's displayed (not just in the API category)
  if not entry.isDisplayed then
    return false, "This aura is not displayed in CD Manager.\n\n" ..
      "Please add it to 'Tracked Buffs' or 'Tracked Bars' using Edit Mode, then scan again."
  end
  
  -- Find first available ArcUI bar slot
  local db = ns.API.GetDB()
  if not db or not db.bars then
    return false, "ArcUI database not ready"
  end
  
  local barNum = nil
  for i = 1, 30 do
    local cfg = ns.API.GetBarConfig(i)
    if cfg and not cfg.tracking.enabled and not cfg.tracking.customEnabled then
      barNum = i
      break
    end
  end
  
  if not barNum then
    return false, "No available bar slots (max 30)"
  end
  
  -- Configure the bar
  local cfg = ns.API.GetBarConfig(barNum)
  cfg.tracking.enabled = true
  cfg.tracking.sourceType = sourceType
  cfg.tracking.buffName = entry.name
  cfg.tracking.spellID = entry.spellID
  cfg.tracking.displaySpellID = entry.displaySpellID or entry.spellID
  cfg.tracking.iconTextureID = entry.icon
  cfg.tracking.cooldownID = cooldownID
  cfg.display.displayType = displayType
  cfg.display.enabled = true
  
  -- Only set these if explicitly provided (no defaults - user must configure)
  if options.useDurationBar ~= nil then
    cfg.tracking.useDurationBar = options.useDurationBar
  else
    cfg.tracking.useDurationBar = nil  -- Force user to select
  end
  
  if options.maxStacks then
    cfg.tracking.maxStacks = options.maxStacks
  else
    cfg.tracking.maxStacks = 0  -- Force user to enter
  end
  
  if options.maxDuration then
    cfg.tracking.maxDuration = options.maxDuration
  else
    cfg.tracking.maxDuration = 0  -- Force user to enter
  end
  
  -- dynamicMaxDuration (Auto mode) - enabled by default for duration bars
  if options.dynamicMaxDuration ~= nil then
    cfg.tracking.dynamicMaxDuration = options.dynamicMaxDuration
  elseif options.useDurationBar then
    cfg.tracking.dynamicMaxDuration = true  -- Default to Auto for duration bars
  end
  
  if options.trackType then
    cfg.tracking.trackType = options.trackType
  else
    cfg.tracking.trackType = ""  -- Force user to select
  end
  
  -- For duration bars, enable duration text by default
  if options.useDurationBar then
    cfg.display.showDuration = true
  end
  
  -- For icons, enable stacks display and set anchor
  if displayType == "icon" then
    cfg.display.iconShowStacks = true  -- Show stack count by default
    if options.iconStackAnchor then
      cfg.display.iconStackAnchor = options.iconStackAnchor
    end
  end
  
  -- Set up behavior
  if not cfg.behavior then cfg.behavior = {} end
  cfg.behavior.showOnSpecs = options.showOnSpecs or { GetSpecialization() or 1 }
  
  -- Update catalog entry
  entry.arcUIBarNum = barNum
  
  -- Apply appearance and refresh
  if ns.Display and ns.Display.ApplyAppearance then
    ns.Display.ApplyAppearance(barNum)
  end
  
  if ns.API.ValidateAllBarTracking then
    ns.API.ValidateAllBarTracking()
  end
  
  return true, barNum
end

-- Remove an ArcUI bar/icon
function ns.Catalog.RemoveArcUIDisplay(barNum, disableInCDM)
  local cfg = ns.API.GetBarConfig(barNum)
  if not cfg then
    return false, "Bar not found"
  end
  
  local cooldownID = cfg.tracking.cooldownID
  
  -- Disable the ArcUI bar
  cfg.tracking.enabled = false
  cfg.tracking.buffName = ""
  cfg.tracking.spellID = 0
  cfg.tracking.cooldownID = 0
  
  if ns.Display and ns.Display.HideBar then
    ns.Display.HideBar(barNum)
  end
  
  -- Optionally disable in CD Manager (only if safe - will cause taint!)
  if disableInCDM and cooldownID and cooldownID > 0 then
    if ns.Catalog.IsSafeToAccessCDM() then
      local success, err = ns.Catalog.DisableInCDManager(cooldownID)
      if success then
        ns.Catalog.ShowReloadWarning()
      end
    end
  end
  
  -- Update catalog entry
  if cooldownID and masterCatalog[cooldownID] then
    masterCatalog[cooldownID].arcUIBarNum = nil
  end
  
  return true
end

-- ===================================================================
-- QUICK SETUP HELPERS (SAFE - NO CDM MODIFICATION)
-- ===================================================================
function ns.Catalog.CreateStackBar(cooldownID, maxStacks, specs)
  return ns.Catalog.CreateArcUIDisplay(cooldownID, "bar", {
    sourceType = "icon",
    useDurationBar = false,
    maxStacks = maxStacks or 10,
    showOnSpecs = specs,
  })
end

function ns.Catalog.CreateDurationBar(cooldownID, maxDuration, specs)
  return ns.Catalog.CreateArcUIDisplay(cooldownID, "bar", {
    sourceType = "bar",
    useDurationBar = true,
    maxDuration = maxDuration or 30,
    showOnSpecs = specs,
  })
end

function ns.Catalog.CreateIcon(cooldownID, maxStacks, specs)
  return ns.Catalog.CreateArcUIDisplay(cooldownID, "icon", {
    sourceType = "icon",
    -- Don't pass maxStacks - force user to configure
    showOnSpecs = specs,
    iconStackAnchor = "TOPLEFT_OUTER",  -- Default to outer position
  })
end

-- ===================================================================
-- STATUS CHECKING (Always safe - reads from cache)
-- ===================================================================
function ns.Catalog.GetTrackingStatus(cooldownID)
  local entry = masterCatalog[cooldownID]
  if not entry then
    return "not_found", "Not in catalog"
  end
  
  -- Update arcUIBarNum dynamically
  entry.arcUIBarNum = ns.Catalog.FindArcUIBarByCooldownID(cooldownID)
  
  if entry.arcUIBarNum then
    local cfg = ns.API.GetBarConfig(entry.arcUIBarNum)
    local displayType = cfg and cfg.display.displayType or "bar"
    return "arcui", string.format("ArcUI %s #%d", displayType, entry.arcUIBarNum)
  end
  
  if entry.isTrackedBuff and entry.isTrackedBar then
    return "cdm_both", "In CD Manager (Buffs + Bars)"
  end
  
  if entry.isTrackedBuff then
    return "cdm_buff", "In CD Manager (Tracked Buffs)"
  end
  
  if entry.isTrackedBar then
    return "cdm_bar", "In CD Manager (Tracked Bars)"
  end
  
  return "available", "Available"
end

-- ===================================================================
-- INITIALIZATION
-- ===================================================================
local function InitializeCatalog()
  -- Build category names first
  BuildCategoryNames()
  
  if not ns.Catalog.IsCDManagerAvailable() then
    -- Retry after delay
    C_Timer.After(2.0, InitializeCatalog)
    return
  end
  
  -- Initial scan using safe frame-based method
  C_Timer.After(0.5, function()
    local success, count, buffs, bars = ns.Catalog.ScanTrackedFrames()
    if success and ns.devMode then
      print(string.format("|cff00ccffArc UI Catalog|r: Found %d tracked auras (%d buffs, %d bars)", 
        count or 0, buffs or 0, bars or 0))
    end
  end)
end

-- Start initialization after a short delay
C_Timer.After(2.0, InitializeCatalog)

-- ===================================================================
-- EVENT HANDLING
-- ===================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_REGEN_DISABLED" then
    -- Entering combat
    isInCombat = true
    return
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Leaving combat - safe to rescan
    isInCombat = false
    -- Rescan using safe frame-based method
    C_Timer.After(0.5, function()
      ns.Catalog.ScanTrackedFrames()
    end)
    return
  end
  
  -- Rescan after spec/talent change
  C_Timer.After(1.0, function()
    ns.Catalog.ScanTrackedFrames()
  end)
end)

-- ===================================================================
-- API EXPORTS
-- ===================================================================
ns.API.ScanCatalog = ns.Catalog.ScanTrackedFrames
ns.API.GetCatalogEntries = ns.Catalog.GetAllEntries
ns.API.GetFilteredCatalog = ns.Catalog.GetFilteredCatalog
ns.API.CreateFromCatalog = ns.Catalog.CreateArcUIDisplay
ns.API.GetCatalogEntry = ns.Catalog.GetEntry
ns.API.IsCDManagerAvailable = ns.Catalog.IsCDManagerAvailable
ns.API.IsCatalogSafe = ns.Catalog.IsSafeToAccessCDM
ns.API.IsReloadRequired = ns.Catalog.IsReloadRequired
ns.API.ShowReloadWarning = ns.Catalog.ShowReloadWarning

-- ===================================================================
-- CUSTOM DEFINITIONS INTEGRATION
-- Get custom auras and cooldowns as catalog-compatible entries
-- ===================================================================
function ns.Catalog.GetCustomAuraEntries()
  local entries = {}
  
  if not ns.CustomTracking or not ns.CustomTracking.GetAllAuras then
    return entries
  end
  
  local auras = ns.CustomTracking.GetAllAuras()
  for auraID, def in pairs(auras) do
    local entry = {
      cooldownID = nil,  -- Custom auras don't have CDM cooldownIDs
      customDefinitionID = auraID,
      customType = "customAura",
      name = def.name or "Custom Aura",
      icon = def.iconTextureID or 134400,
      spellID = def.triggers and def.triggers[1] and def.triggers[1].spellID or 0,
      category = "custom",
      categoryName = "Custom Auras",
      isTracked = true,       -- Treat as tracked
      isTrackedBuff = true,   -- Can create stack bars
      isTrackedBar = true,    -- Can create duration bars
      isDisplayed = true,     -- Always "displayed" - not desaturated
      isDisplayedAsBuff = true,
      isDisplayedAsBar = true,
      isHidden = false,
      isCustom = true,
      sourceType = "custom",
      maxStacks = def.stacks and def.stacks.maxStacks or 10,
      maxDuration = def.duration and def.duration.baseDuration or 10,
      -- Check if already has an ArcUI bar
      arcUIBarNum = ns.Catalog.FindArcUIBarByCustomDefinition(auraID, "customAura"),
    }
    table.insert(entries, entry)
  end
  
  return entries
end

function ns.Catalog.GetCustomCooldownEntries()
  local entries = {}
  
  if not ns.CustomTracking or not ns.CustomTracking.GetAllCooldowns then
    return entries
  end
  
  local cooldowns = ns.CustomTracking.GetAllCooldowns()
  for cdID, def in pairs(cooldowns) do
    local entry = {
      cooldownID = nil,
      customDefinitionID = cdID,
      customType = "customCooldown",
      name = def.name or "Custom Cooldown",
      icon = def.iconTextureID or 134400,
      spellID = def.trigger and def.trigger.spellIDs and def.trigger.spellIDs[1] or 0,
      category = "custom",
      categoryName = "Custom Cooldowns",
      isTracked = true,       -- Treat as tracked
      isTrackedBuff = true,   -- Can create stack bars (for charges)
      isTrackedBar = false,   -- Cannot create duration bars
      isDisplayed = true,     -- Always "displayed" - not desaturated
      isDisplayedAsBuff = true,
      isDisplayedAsBar = false,
      isHidden = false,
      isCustom = true,
      sourceType = "custom",
      charges = def.charges and def.charges.enabled,
      maxCharges = def.charges and def.charges.maxCharges or 1,
      arcUIBarNum = ns.Catalog.FindArcUIBarByCustomDefinition(cdID, "customCooldown"),
    }
    table.insert(entries, entry)
  end
  
  return entries
end

-- Find ArcUI bar by custom definition ID
function ns.Catalog.FindArcUIBarByCustomDefinition(defID, trackType)
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db or not db.bars then return nil end
  
  for i = 1, 30 do
    local cfg = db.bars[i]
    if cfg and cfg.tracking and cfg.tracking.enabled then
      if cfg.tracking.trackType == trackType and cfg.tracking.customDefinitionID == defID then
        return i
      end
    end
  end
  
  return nil
end

-- Get all entries including custom definitions
function ns.Catalog.GetAllEntriesWithCustom()
  local results = ns.Catalog.GetAllEntries()
  
  -- Add custom auras
  local customAuras = ns.Catalog.GetCustomAuraEntries()
  for _, entry in ipairs(customAuras) do
    table.insert(results, entry)
  end
  
  -- Add custom cooldowns
  local customCooldowns = ns.Catalog.GetCustomCooldownEntries()
  for _, entry in ipairs(customCooldowns) do
    table.insert(results, entry)
  end
  
  -- Sort by name
  table.sort(results, function(a, b)
    local success, result = pcall(function()
      return (a.name or "") < (b.name or "")
    end)
    if success then return result end
    return false
  end)
  
  return results
end

-- Create ArcUI display for custom definition
function ns.Catalog.CreateCustomArcUIDisplay(customDefID, customType, displayType, options)
  options = options or {}
  
  -- Find next available bar slot
  local db = ns.API and ns.API.GetDB and ns.API.GetDB()
  if not db then return false, "Database not available" end
  
  local barNum = nil
  for i = 1, 30 do
    local cfg = ns.API.GetBarConfig(i)
    if cfg and not cfg.tracking.enabled then
      barNum = i
      break
    end
  end
  
  if not barNum then
    return false, "No available bar slots (maximum 30)"
  end
  
  -- Get definition details
  local name, icon, maxStacks, maxDuration
  if customType == "customAura" then
    local def = ns.CustomTracking and ns.CustomTracking.GetAuraDefinition(customDefID)
    if not def then return false, "Custom aura not found" end
    name = def.name
    icon = def.iconTextureID
    maxStacks = def.stacks and def.stacks.maxStacks or 10
    maxDuration = def.duration and def.duration.baseDuration or 10
  elseif customType == "customCooldown" then
    local def = ns.CustomTracking and ns.CustomTracking.GetCooldownDefinition(customDefID)
    if not def then return false, "Custom cooldown not found" end
    name = def.name
    icon = def.iconTextureID
    maxStacks = def.charges and def.charges.maxCharges or 1
    maxDuration = def.cooldown and def.cooldown.baseDuration or 60
  else
    return false, "Invalid custom type"
  end
  
  -- Configure the bar
  local cfg = ns.API.GetBarConfig(barNum)
  cfg.tracking.enabled = true
  cfg.tracking.trackType = customType
  cfg.tracking.customDefinitionID = customDefID
  cfg.tracking.buffName = name
  cfg.tracking.iconTextureID = icon
  cfg.tracking.maxStacks = maxStacks
  cfg.tracking.maxDuration = maxDuration
  cfg.tracking.useDurationBar = options.useDurationBar or false
  cfg.display.displayType = displayType or "bar"
  cfg.display.enabled = true
  
  -- Enable duration display for duration bars
  if options.useDurationBar then
    cfg.display.showDuration = true
  end
  
  -- Set up behavior
  if not cfg.behavior then cfg.behavior = {} end
  cfg.behavior.showOnSpecs = options.showOnSpecs or { GetSpecialization() or 1 }
  cfg.behavior.hideWhenInactive = false  -- Always show custom bars even when inactive
  
  -- Apply appearance (creates/configures frames)
  if ns.Display and ns.Display.ApplyAppearance then
    ns.Display.ApplyAppearance(barNum)
  end
  
  -- Force display update to show the bar
  if ns.API and ns.API.RefreshDisplay then
    ns.API.RefreshDisplay(barNum)
  end
  
  -- Also notify the custom tracking system to update this bar
  if customType == "customAura" then
    if ns.CustomTracking and ns.CustomTracking.NotifyAuraChange then
      ns.CustomTracking.NotifyAuraChange(customDefID)
    end
  elseif customType == "customCooldown" then
    if ns.CustomTracking and ns.CustomTracking.NotifyCooldownChange then
      ns.CustomTracking.NotifyCooldownChange(customDefID)
    end
  end
  
  return true, barNum
end

ns.API.GetAllCatalogEntriesWithCustom = ns.Catalog.GetAllEntriesWithCustom
ns.API.GetCustomAuraEntries = ns.Catalog.GetCustomAuraEntries
ns.API.GetCustomCooldownEntries = ns.Catalog.GetCustomCooldownEntries
ns.API.CreateCustomArcUIDisplay = ns.Catalog.CreateCustomArcUIDisplay

-- ===================================================================
-- END OF ArcUI_Catalog.lua
-- ===================================================================