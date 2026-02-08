-- ═══════════════════════════════════════════════════════════════════════════
-- ArcUI Arc Auras - Custom Tracking System
-- Track items (trinkets, potions) and spells not covered by CDM
-- v1.1 - Performance optimized: caching, event-driven stack updates
-- 
-- NOTE: Item cooldowns are NON-SECRET in WoW 12.0!
-- This means direct numeric comparisons work in combat.
-- ═══════════════════════════════════════════════════════════════════════════

local ADDON, ns = ...

ns.ArcAuras = ns.ArcAuras or {}
local ArcAuras = ns.ArcAuras

-- Dependencies
local Shared = ns.CDMShared

-- ═══════════════════════════════════════════════════════════════════════════
-- CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════════

local TRINKET_SLOTS = {
    { slotID = 13, name = "Trinket 1" },
    { slotID = 14, name = "Trinket 2" },
}

local DEFAULT_ICON_SIZE = 40
local UPDATE_RATE = 0.1  -- 10Hz - item cooldowns are non-secret, cheap to query

-- Arc Aura ID prefixes
local ID_PREFIX = {
    TRINKET = "arc_trinket_",
    ITEM = "arc_item_",
    SPELL = "arc_spell_",
}

-- Frame Strata/Level Constants - Standardized to match CDM icons
-- CDM viewers use MEDIUM strata; we match for consistent z-ordering
local FRAME_STRATA = "MEDIUM"
local BASE_FRAME_LEVEL = 10
local FRAME_LEVEL_BORDER = 5     -- Offset for border overlay above base
local FRAME_LEVEL_GLOW = 3       -- Offset for glow anchor above base
local FRAME_LEVEL_COUNT = 10     -- Offset for count/stack text (above cooldown swipe)

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════════════

ArcAuras.frames = {}           -- arcID -> frame
ArcAuras.updateTicker = nil    -- C_Timer ticker for updates
ArcAuras.isEnabled = false
ArcAuras.initialized = false
ArcAuras.masqueGroup = nil     -- Masque group for skinning

-- ═══════════════════════════════════════════════════════════════════════════
-- PERFORMANCE: CACHED REFERENCES (avoid repeated lookups)
-- ═══════════════════════════════════════════════════════════════════════════

local cachedLCG = nil  -- LibCustomGlow reference, cached once
local function GetLCG()
    if cachedLCG == nil then
        cachedLCG = LibStub and LibStub("LibCustomGlow-1.0", true) or false
    end
    return cachedLCG or nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MASQUE INTEGRATION
-- Register ArcAura buttons with Masque for skinning
-- ═══════════════════════════════════════════════════════════════════════════

local function GetMasqueGroup()
    if ArcAuras.masqueGroup then return ArcAuras.masqueGroup end
    
    local Masque = LibStub and LibStub("Masque", true)
    if not Masque then return nil end
    
    -- Create group: Masque:Group(addon, group)
    ArcAuras.masqueGroup = Masque:Group("ArcUI", "Arc Auras")
    return ArcAuras.masqueGroup
end

local function RegisterWithMasque(frame)
    -- Check if Masque skinning is enabled in ArcUI settings
    if ns.Masque and ns.Masque.IsEnabled and not ns.Masque.IsEnabled() then
        -- Masque skinning is disabled - don't register
        return
    end
    
    local group = GetMasqueGroup()
    if not group then return end
    
    -- AddButton expects: button, buttonData
    -- ONLY pass Icon - Masque will only control the icon texture/border
    -- We use _arcStackText instead of Count so Masque can't auto-detect it
    group:AddButton(frame, {
        Icon = frame.Icon,
    })
    
    frame._arcAuraMasqueRegistered = true
    
    -- Deferred ReSkin after frame size is finalized by CDMGroups
    C_Timer.After(0.2, function()
        if frame and group and group.ReSkin then
            group:ReSkin(frame)
        end
    end)
end

local function UnregisterFromMasque(frame)
    local group = ArcAuras.masqueGroup
    if not group then return end
    
    if frame._arcAuraMasqueRegistered then
        group:RemoveButton(frame)
        frame._arcAuraMasqueRegistered = nil
    end
end

-- Settings cache per frame - invalidated only when settings change
local settingsCache = {}  -- arcID -> { settings = {}, timestamp = time }
local SETTINGS_CACHE_TTL = 5  -- Re-validate cache every 5 seconds max

local function InvalidateSettingsCache(arcID)
    if arcID then
        settingsCache[arcID] = nil
    else
        wipe(settingsCache)
    end
end

-- Stack/charge cache per frame - updated on events, not polling
local stackCache = {}  -- arcID -> { value = x, isCharges = bool, itemID = id }

local function InvalidateStackCache(arcID)
    if arcID then
        stackCache[arcID] = nil
    else
        wipe(stackCache)
    end
end

-- Export cache invalidation for external use
ArcAuras.InvalidateSettingsCache = InvalidateSettingsCache
ArcAuras.InvalidateStackCache = InvalidateStackCache

-- ═══════════════════════════════════════════════════════════════════════════
-- DATABASE
-- BYPASS ACEDB: Access ArcUIDB directly to avoid removeDefaults stripping data
-- This follows the same pattern as CDMShared.GetCDMGroupsDB()
-- ═══════════════════════════════════════════════════════════════════════════

-- Cache for GetDB to avoid repeated string concatenation and table lookups
local cachedArcAurasDB = nil
local cachedCharKey = nil
local arcAurasDBCacheEnabled = false  -- Only enable after PLAYER_LOGIN

-- Forward declaration (needed because EnableDBCache references GetDB)
local GetDB

-- Define GetDB first
GetDB = function()
    -- Return cached result if available AND caching is enabled
    if arcAurasDBCacheEnabled and cachedArcAurasDB then
        return cachedArcAurasDB
    end
    
    -- CRITICAL: Access the raw SavedVariables table directly, not through AceDB
    -- AceDB's removeDefaults strips tables that "match defaults" on logout,
    -- which can cause data loss for complex nested structures like trackedItems.
    
    -- Ensure base structure exists
    if not ArcUIDB then 
        -- SavedVariables not loaded yet - return nil and caller should retry
        return nil 
    end
    if not ArcUIDB.char then ArcUIDB.char = {} end
    
    -- Get character key the same way AceDB does
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    
    -- Guard against early calls before player info is available
    if not playerName or playerName == "" or not realmName or realmName == "" then
        return nil
    end
    
    local charKey = playerName .. " - " .. realmName
    
    if not ArcUIDB.char[charKey] then ArcUIDB.char[charKey] = {} end
    
    local charDB = ArcUIDB.char[charKey]
    
    -- Initialize arcAuras if missing (first time setup for this character)
    if not charDB.arcAuras then
        charDB.arcAuras = {
            enabled = true,
            autoTrackEquippedTrinkets = false,
            autoTrackSlots = {
                [13] = true,
                [14] = true,
            },
            onlyOnUseTrinkets = false,
            trackedItems = {},
            positions = {},
            globalSettings = {},
            updateRate = UPDATE_RATE,
        }
    end
    
    local db = charDB.arcAuras
    
    -- Ensure sub-tables exist (defensive - for existing data that may be missing keys)
    if not db.trackedItems then db.trackedItems = {} end
    if not db.positions then db.positions = {} end
    if not db.globalSettings then db.globalSettings = {} end
    if not db.autoTrackSlots then
        db.autoTrackSlots = { [13] = true, [14] = true }
    end
    if db.enabled == nil then db.enabled = true end
    if db.autoTrackEquippedTrinkets == nil then db.autoTrackEquippedTrinkets = false end
    if db.onlyOnUseTrinkets == nil then db.onlyOnUseTrinkets = false end
    if not db.updateRate then db.updateRate = UPDATE_RATE end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- MIGRATION: Move Arc Auras from old ns.db.profile location (one-time)
    -- Only runs if old profile location has data AND new location is empty
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.db and ns.db.profile and ns.db.profile.arcAuras then
        local profileData = ns.db.profile.arcAuras
        
        -- Only migrate if profile has tracked items AND our trackedItems is empty
        if profileData.trackedItems and next(profileData.trackedItems) then
            if not next(db.trackedItems) then
                -- Copy tracked items
                for arcID, config in pairs(profileData.trackedItems) do
                    db.trackedItems[arcID] = CopyTable(config)
                end
                
                -- Copy positions
                if profileData.positions then
                    for arcID, pos in pairs(profileData.positions) do
                        db.positions[arcID] = CopyTable(pos)
                    end
                end
                
                -- Copy enabled state
                if profileData.enabled then
                    db.enabled = true
                end
                
                -- Copy global settings
                if profileData.globalSettings and next(profileData.globalSettings) then
                    db.globalSettings = CopyTable(profileData.globalSettings)
                end
                
                print("|cff00ccffArcUI|r: Migrated Arc Auras to character-specific storage")
            end
            
            -- Clear profile data after migration attempt
            wipe(profileData.trackedItems)
            if profileData.positions then wipe(profileData.positions) end
            profileData.enabled = false
            print("|cff00ccffArcUI|r: Cleared profile Arc Auras data (now per-character)")
        end
    end
    
    -- Cache the result if caching is enabled (after PLAYER_LOGIN)
    if arcAurasDBCacheEnabled then
        cachedArcAurasDB = db
        cachedCharKey = charKey
    end
    
    return db
end

-- NOW define EnableDBCache (after GetDB is defined)
function ArcAuras.EnableDBCache()
    arcAurasDBCacheEnabled = true
    -- Force a DB fetch to populate the cache
    cachedArcAurasDB = nil  -- Clear first to force refresh
    GetDB()
end

-- Clear cache - call when DB needs to be re-fetched
function ArcAuras.ClearDBCache()
    cachedArcAurasDB = nil
    cachedCharKey = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ID HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

function ArcAuras.MakeTrinketID(slotID)
    return ID_PREFIX.TRINKET .. tostring(slotID)
end

function ArcAuras.MakeItemID(itemID)
    return ID_PREFIX.ITEM .. tostring(itemID)
end

function ArcAuras.MakeSpellID(spellID)
    return ID_PREFIX.SPELL .. tostring(spellID)
end

function ArcAuras.ParseArcID(arcID)
    if not arcID or type(arcID) ~= "string" then return nil end
    
    if arcID:find("^" .. ID_PREFIX.TRINKET) then
        local slotID = tonumber(arcID:sub(#ID_PREFIX.TRINKET + 1))
        return "trinket", slotID
    elseif arcID:find("^" .. ID_PREFIX.ITEM) then
        local itemID = tonumber(arcID:sub(#ID_PREFIX.ITEM + 1))
        return "item", itemID
    elseif arcID:find("^" .. ID_PREFIX.SPELL) then
        local spellID = tonumber(arcID:sub(#ID_PREFIX.SPELL + 1))
        return "spell", spellID
    end
    
    return nil
end

function ArcAuras.IsArcAuraID(id)
    if not id or type(id) ~= "string" then return false end
    return id:find("^arc_") ~= nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ITEM INFO HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetItemNameAndIcon(itemID)
    if not itemID then return nil, nil end
    
    -- First try GetItemInfo (returns full data if cached)
    local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
    
    -- If not cached, use GetItemInfoInstant for basic info (always available from local DB)
    if not name or not icon then
        local itemName, _, _, _, itemIcon = GetItemInfoInstant(itemID)
        name = name or itemName
        icon = icon or itemIcon
    end
    
    return name, icon
end

local function GetSlotItemInfo(slotID)
    local itemID = GetInventoryItemID("player", slotID)
    if not itemID then return nil, nil, nil end
    local name, icon = GetItemNameAndIcon(itemID)
    return itemID, name, icon or GetInventoryItemTexture("player", slotID)
end

local function GetItemOnUseSpell(itemID)
    if not itemID then return nil, nil end
    local spellName, spellID = GetItemSpell(itemID)
    return spellName, spellID
end

local function IsItemOnUse(itemID)
    local spellName = GetItemSpell(itemID)
    return spellName ~= nil
end

-- Check if an item is passive (no on-use spell)
local function IsItemPassive(itemID)
    if not itemID then return true end  -- No item = treat as passive
    local spellName = GetItemSpell(itemID)
    return spellName == nil
end

-- Check if a specific item is currently equipped in any trinket slot
local function IsItemEquipped(itemID)
    if not itemID then return false end
    for _, slot in ipairs(TRINKET_SLOTS) do
        local equippedID = GetInventoryItemID("player", slot.slotID)
        if equippedID == itemID then
            return true
        end
    end
    return false
end

-- Expose for options
ArcAuras.IsItemEquipped = IsItemEquipped

-- ═══════════════════════════════════════════════════════════════════════════
-- BASE COOLDOWN CACHE (for GCD filtering)
-- ═══════════════════════════════════════════════════════════════════════════

-- Cache: itemID -> base cooldown in seconds (nil = not yet cached, false = no cooldown)
local baseCooldownCache = {}

-- Get the base cooldown for an item (in seconds)
-- Returns nil if item has no on-use spell, or the base cooldown duration
local function GetItemBaseCooldown(itemID)
    if not itemID then return nil end
    
    -- Check cache first
    if baseCooldownCache[itemID] ~= nil then
        return baseCooldownCache[itemID] or nil  -- false -> nil
    end
    
    -- Get item's spell
    local spellName, spellID = GetItemSpell(itemID)
    if not spellID then
        baseCooldownCache[itemID] = false  -- No spell = no cooldown
        return nil
    end
    
    -- Get base cooldown via GetSpellBaseCooldown (returns ms)
    if GetSpellBaseCooldown then
        local baseCooldownMs = GetSpellBaseCooldown(spellID)
        if baseCooldownMs and baseCooldownMs > 0 then
            local baseCooldownSec = baseCooldownMs / 1000
            baseCooldownCache[itemID] = baseCooldownSec
            return baseCooldownSec
        end
    end
    
    -- No base cooldown found
    baseCooldownCache[itemID] = false
    return nil
end

-- Check if a duration is likely GCD (not the real cooldown)
-- Returns true if this appears to be GCD, false if it's a real cooldown
local function IsLikelyGCD(itemID, duration)
    if not duration or duration <= 0 then return false end
    
    -- GCD is typically 0.5s to 1.6s (hasted to unhasted)
    -- If duration is outside this range, it's definitely not GCD
    if duration > 2.0 then return false end
    
    -- Get the item's base cooldown
    local baseCooldown = GetItemBaseCooldown(itemID)
    
    -- If we know the base cooldown and current duration doesn't match, it's GCD
    if baseCooldown and baseCooldown > 2.0 then
        -- Item has a real cooldown > 2s, but we're seeing a short duration
        -- This means we're seeing GCD, not the real cooldown
        return true
    end
    
    -- If item has no known base cooldown but duration is in GCD range, assume GCD
    -- This is a fallback for items where GetSpellBaseCooldown doesn't work
    if not baseCooldown and duration <= 1.6 and duration >= 0.5 then
        return true
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STACK COUNT HELPERS (EVENT-DRIVEN, NOT POLLED)
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if an item should show inventory count (consumables, reagents)
local function ShouldShowInventoryCount(itemID)
    if not itemID then return false end
    
    -- GetItemInfo returns classID as 12th value, subclassID as 13th
    local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = GetItemInfo(itemID)
    if not classID then return false end  -- Item info not loaded yet
    
    -- Consumables (potions, food, flasks, etc.) - always show count
    -- Enum.ItemClass.Consumable = 0
    if classID == 0 then
        return true
    end
    
    -- Tradeskill items (reagents) - could be useful for profession items
    -- Enum.ItemClass.Tradegoods = 7
    if classID == 7 then
        return true
    end
    
    -- Everything else (armor, weapons, trinkets) - don't show inventory count
    return false
end

-- Helper: Find item location in bags
local function FindItemInBags(itemID)
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID == itemID then
                return bag, slot
            end
        end
    end
    return nil, nil
end

-- Helper: Get item charges from tooltip (for items like Healthstone)
-- Returns charges number or nil if not found
local function GetItemChargesFromTooltip(itemID)
    local bag, slot = FindItemInBags(itemID)
    if not bag then return nil end
    
    local tooltipData = C_TooltipInfo.GetBagItem(bag, slot)
    if not tooltipData or not tooltipData.lines then return nil end
    
    for _, line in ipairs(tooltipData.lines) do
        if line.leftText then
            local text = line.leftText
            
            -- WoW uses |4 for plural handling: "2 |4Charge:Charges;"
            -- Pattern 1: Match WoW's localization format "X |4Charge:Charges;"
            local charges = text:match("^(%d+) |4Charge:Charges;$")
            if charges then
                return tonumber(charges)
            end
            
            -- Pattern 2: Simple "X Charges" or "X Charge" 
            charges = text:match("^(%d+) Charges?$")
            if charges then
                return tonumber(charges)
            end
            
            -- Pattern 3: More lenient - find number before "Charge" anywhere
            charges = text:match("(%d+) |4Charge")
            if charges then
                return tonumber(charges)
            end
        end
    end
    
    return nil
end

-- Get the stack count to display for an Arc Aura config
-- Returns: displayValue, isCharges (boolean)
-- NOTE: This is fully event-driven, not polled!
local function ComputeStackDisplay(config)
    if not config then return nil, false end
    
    if config.type == "item" and config.itemID then
        -- First check if item has spell charges via C_Spell API
        local spellName, spellID = GetItemSpell(config.itemID)
        if spellID then
            local chargeInfo = C_Spell.GetSpellCharges(spellID)
            if chargeInfo and chargeInfo.currentCharges ~= nil then
                return chargeInfo.currentCharges, true
            end
        end
        
        -- Check for item-based charges (like Healthstone) via tooltip
        local tooltipCharges = GetItemChargesFromTooltip(config.itemID)
        if tooltipCharges then
            return tooltipCharges, true
        end
        
        -- No charges - fall back to inventory count for consumables
        if ShouldShowInventoryCount(config.itemID) then
            return GetItemCount(config.itemID, false, false), false  -- Bags only
        end
        
    elseif config.type == "trinket" and config.slotID then
        -- Trinkets: check for spell charges
        local itemID = GetInventoryItemID("player", config.slotID)
        if itemID then
            local spellName, spellID = GetItemSpell(itemID)
            if spellID then
                local chargeInfo = C_Spell.GetSpellCharges(spellID)
                if chargeInfo and chargeInfo.currentCharges ~= nil then
                    return chargeInfo.currentCharges, true
                end
            end
        end
    end
    
    return nil, false  -- Don't show any stack text
end

-- Cached version - updated on events, read during update loop
-- Cache invalidated by:
--   1. BAG_UPDATE_DELAYED (new items, bag changes)
--   2. Cooldown starting (item used - charges changed)
--   3. Trinket swap (detected in UpdateTrinketCooldown)
local function GetStackDisplay(config, arcID)
    -- Check cache first
    local cached = stackCache[arcID]
    if cached then
        -- Verify itemID hasn't changed (trinket swap)
        local currentItemID = config.itemID
        if config.type == "trinket" and config.slotID then
            currentItemID = GetInventoryItemID("player", config.slotID)
        end
        if cached.itemID == currentItemID then
            return cached.value, cached.isCharges
        end
    end
    
    -- Cache miss - compute and cache
    local value, isCharges = ComputeStackDisplay(config)
    local currentItemID = config.itemID
    if config.type == "trinket" and config.slotID then
        currentItemID = GetInventoryItemID("player", config.slotID)
    end
    
    stackCache[arcID] = {
        value = value,
        isCharges = isCharges,
        itemID = currentItemID,
    }
    
    return value, isCharges
end

-- Apply CDMEnhance chargeText styling to a fontstring
local function ApplyStackTextStyle(frame, fontString)
    if not frame or not fontString then return end
    
    -- Get settings from CDMEnhance cascade
    local arcID = frame._arcAuraID or frame.cooldownID
    local settings = nil
    
    if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
        settings = ns.CDMEnhance.GetEffectiveIconSettings(arcID)
    end
    
    local chargeCfg = settings and settings.chargeText
    if not chargeCfg then
        -- Use defaults
        chargeCfg = {
            enabled = true,
            size = 16,
            color = {r = 1, g = 1, b = 0, a = 1},
            font = "Friz Quadrata TT",
            outline = "OUTLINE",
            shadow = false,
            shadowOffsetX = 1,
            shadowOffsetY = -1,
            anchor = "BOTTOMRIGHT",
            offsetX = -2,
            offsetY = 2,
        }
    end
    
    -- Check if enabled
    if chargeCfg.enabled == false then
        fontString:Hide()
        return
    end
    
    -- Get font path using CDMEnhance's helper
    local fontPath = "Fonts\\FRIZQT__.TTF"
    if ns.CDMEnhance and ns.CDMEnhance.GetFontPath then
        fontPath = ns.CDMEnhance.GetFontPath(chargeCfg.font)
    end
    
    local fontSize = chargeCfg.size or 16
    local outline = chargeCfg.outline or "OUTLINE"
    
    -- Apply font using CDMEnhance's safe setter if available
    if ns.CDMEnhance and ns.CDMEnhance.SafeSetFont then
        ns.CDMEnhance.SafeSetFont(fontString, fontPath, fontSize, outline)
    else
        fontString:SetFont(fontPath, fontSize, outline)
    end
    
    -- Color
    local c = chargeCfg.color or {r = 1, g = 1, b = 0, a = 1}
    fontString:SetTextColor(c.r or 1, c.g or 1, c.b or 0, c.a or 1)
    
    -- Shadow
    if chargeCfg.shadow then
        fontString:SetShadowOffset(chargeCfg.shadowOffsetX or 1, chargeCfg.shadowOffsetY or -1)
        fontString:SetShadowColor(0, 0, 0, 0.8)
    else
        fontString:SetShadowOffset(0, 0)
    end
    
    -- Set draw layer to appear above glows
    fontString:SetDrawLayer("OVERLAY", 7)
    
    -- Position based on mode setting (anchor or free)
    fontString:ClearAllPoints()
    if chargeCfg.mode == "free" then
        -- Free position mode - use freeX/freeY relative to center
        local freeX = chargeCfg.freeX or 0
        local freeY = chargeCfg.freeY or 0
        fontString:SetPoint("CENTER", frame, "CENTER", freeX, freeY)
    else
        -- Anchor position mode (default)
        local anchor = chargeCfg.anchor or "BOTTOMRIGHT"
        local offsetX = chargeCfg.offsetX or -2
        local offsetY = chargeCfg.offsetY or 2
        fontString:SetPoint(anchor, frame, anchor, offsetX, offsetY)
    end
end

-- Export stack helpers
ArcAuras.ShouldShowInventoryCount = ShouldShowInventoryCount
ArcAuras.GetStackDisplay = GetStackDisplay
ArcAuras.ApplyStackTextStyle = ApplyStackTextStyle

-- Refresh stack text styling for all Arc Aura frames
-- Called when chargeText settings change in options
function ArcAuras.RefreshStackTextStyle()
    for arcID, frame in pairs(ArcAuras.frames) do
        if frame and frame._arcStackText then
            -- Clear flag to force re-application
            frame._arcStackStyleApplied = false
            -- Immediately apply the style (don't wait for OnUpdate)
            ApplyStackTextStyle(frame, frame._arcStackText)
            frame._arcStackStyleApplied = true
        end
    end
end

-- Export helpers
ArcAuras.GetItemNameAndIcon = GetItemNameAndIcon
ArcAuras.GetSlotItemInfo = GetSlotItemInfo
ArcAuras.GetItemOnUseSpell = GetItemOnUseSpell
ArcAuras.IsItemOnUse = IsItemOnUse
ArcAuras.IsItemPassive = IsItemPassive

-- ═══════════════════════════════════════════════════════════════════════════
-- FRAME CREATION
-- ═══════════════════════════════════════════════════════════════════════════

local function CreateArcAuraFrame(arcID, config)
    local frameName = "ArcAura_" .. arcID:gsub("[^%w]", "_")
    
    local frame = CreateFrame("Button", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(DEFAULT_ICON_SIZE, DEFAULT_ICON_SIZE)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata(FRAME_STRATA)
    frame:SetFrameLevel(BASE_FRAME_LEVEL)
    
    -- Arc Aura identification
    -- cooldownID is REQUIRED for CDMGroups drag handlers (they read self.cooldownID)
    -- String IDs are safe - CDM API guards (type checks) prevent them from being passed to C_CooldownViewer
    frame._arcAuraID = arcID
    frame.cooldownID = arcID  -- CRITICAL: Enables drag, group membership, free icon tracking
    frame._arcIconType = config.type
    frame._arcConfig = config
    
    -- Background (transparent by default - borders handle visual framing)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0)  -- Transparent - padding won't show black gap
    frame:SetBackdropBorderColor(0, 0, 0, 0)  -- Border handled by CDMEnhance
    
    -- Icon texture (matches CDM structure for CDMEnhance compatibility)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.Icon = icon
    
    -- Cooldown frame
    local cooldown = CreateFrame("Cooldown", frameName .. "_Cooldown", frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawSwipe(true)
    cooldown:SetDrawEdge(true)
    cooldown:SetHideCountdownNumbers(false)
    
    -- CRITICAL: Initialize swipe texture - CDM defines this in XML, we must set it manually
    -- Without this, SetSwipeColor has nothing to colorize!
    -- Using same texture as CDM: "Interface\HUD\UI-HUD-CoolDownManager-Icon-Swipe"
    cooldown:SetSwipeTexture("Interface\\HUD\\UI-HUD-CoolDownManager-Icon-Swipe", 1, 1, 1, 1)
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-SecondaryCooldown", 1, 1, 1, 1)
    
    frame.Cooldown = cooldown
    
    -- Duration object for cooldown updates
    if C_DurationUtil and C_DurationUtil.CreateDuration then
        frame._durationObj = C_DurationUtil.CreateDuration()
    end
    
    -- Shadow/overlay texture (for hideShadow setting)
    local shadow = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
    shadow:SetTexture("Interface\\Cooldown\\IconCooldownEdge")
    shadow:SetVertexColor(0, 0, 0, 0.5)
    shadow:Hide()
    frame.IconOverlay = shadow
    
    -- Border overlay frame (for custom borders)
    local borderOverlay = CreateFrame("Frame", nil, frame)
    borderOverlay:SetAllPoints()
    borderOverlay:SetFrameLevel(frame:GetFrameLevel() + FRAME_LEVEL_BORDER)
    frame._arcBorderOverlay = borderOverlay
    
    -- Glow anchor frame (for LibCustomGlow)
    local glowAnchor = CreateFrame("Frame", nil, frame)
    glowAnchor:SetAllPoints()
    glowAnchor:SetFrameLevel(frame:GetFrameLevel() + FRAME_LEVEL_GLOW)
    frame._arcGlowAnchor = glowAnchor
    
    -- Count container frame (sits ABOVE cooldown swipe for proper layering)
    -- Cooldown frame inherits frame level, so we need count on a higher level frame
    local countContainer = CreateFrame("Frame", nil, frame)
    countContainer:SetAllPoints()
    countContainer:SetFrameLevel(frame:GetFrameLevel() + FRAME_LEVEL_COUNT)
    frame._arcCountContainer = countContainer
    
    -- Stack/charge text - parented to container for proper strata
    -- IMPORTANT: We use _arcStackText instead of "Count" because Masque auto-detects
    -- frame.Count and tries to manage its position even when we don't pass it in regions.
    -- By using a different name, Masque can't find it and ArcUI maintains full control.
    local countText = countContainer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    countText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    countText:SetText("")
    frame._arcStackText = countText
    
    -- Cooldown state tracking
    frame._lastCooldownState = nil
    frame._lastStartTime = nil
    frame._lastDuration = nil
    
    -- Make draggable (controlled by options)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if self._isDraggable then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local arcID = self._arcAuraID
        
        -- ═══════════════════════════════════════════════════════════════════════════
        -- SAVE TO ARC MANAGER PROFILE - EXACTLY like CDM OnDragStop (lines 1019-1030)
        -- This is what makes positions persist across reloads/profile switches
        -- ═══════════════════════════════════════════════════════════════════════════
        if ns.CDMGroups and ns.CDMGroups.savedPositions then
            -- Check if in a group - if so, group manages position, don't save as free
            local saved = ns.CDMGroups.savedPositions[arcID]
            if saved and saved.type == "group" then
                return  -- Group manages this, don't overwrite
            end
            
            -- Calculate CENTER-based coordinates (same as CDM line 977-979)
            local cx, cy = self:GetCenter()
            local ux, uy = UIParent:GetCenter()
            local newX, newY = cx - ux, cy - uy
            
            -- Update freeIcons if tracked (same as CDM line 1019-1022)
            if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[arcID] then
                ns.CDMGroups.freeIcons[arcID].x = newX
                ns.CDMGroups.freeIcons[arcID].y = newY
            end
            
            -- Update savedPositions (same as CDM line 1023-1028)
            local iconSize = (ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[arcID] and ns.CDMGroups.freeIcons[arcID].iconSize) or 36
            ns.CDMGroups.savedPositions[arcID] = {
                type = "free",
                x = newX,
                y = newY,
                iconSize = iconSize,
            }
            
            -- Call SavePositionToSpec (same as CDM line 1029)
            if ns.CDMGroups.SavePositionToSpec then
                ns.CDMGroups.SavePositionToSpec(arcID, ns.CDMGroups.savedPositions[arcID])
            end
            
            -- Call SaveFreeIconToSpec (same as CDM line 1030)
            if ns.CDMGroups.SaveFreeIconToSpec then
                ns.CDMGroups.SaveFreeIconToSpec(arcID, { x = newX, y = newY, iconSize = iconSize })
            end
            
            -- CLEANUP: Remove legacy db.positions since CDMGroups now manages this
            local db = GetDB()
            if db and db.positions and db.positions[arcID] then
                db.positions[arcID] = nil
            end
        else
            -- FALLBACK: CDMGroups not available, use legacy ArcAuras storage
            local point, _, relPoint, x, y = self:GetPoint()
            ArcAuras.SaveFramePosition(arcID, point, relPoint, x, y)
        end
    end)
    
    -- Tooltip
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        ArcAuras.ShowTooltip(self)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Right-click for options
    frame:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ArcAuras.ShowContextMenu(self)
        end
    end)
    frame:RegisterForClicks("RightButtonUp")
    
    return frame
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FRAME MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

function ArcAuras.CreateFrame(arcID, config)
    if ArcAuras.frames[arcID] then
        return ArcAuras.frames[arcID]
    end
    
    local frame = CreateArcAuraFrame(arcID, config)
    ArcAuras.frames[arcID] = frame
    
    -- Set initial icon
    ArcAuras.UpdateFrameIcon(frame, config)
    
    -- For item-type frames, request full item data loading
    -- This ensures icon/name are available even if player doesn't have the item
    if config.type == "item" and config.itemID then
        C_Item.RequestLoadItemDataByID(config.itemID)
    end
    
    -- Check if trinket slot is empty - if so, skip CDMGroups registration
    -- (will be registered when trinket is equipped)
    local skipCDMGroups = false
    if config.type == "trinket" and config.slotID then
        local itemID = GetInventoryItemID("player", config.slotID)
        if not itemID then
            skipCDMGroups = true
            frame._arcSlotEmpty = true
        end
    end
    
    -- Register with CDMGroups for positioning, dragging, groups
    -- CDMGroups handles: saved positions, group membership, drag handlers, free icon tracking
    if not skipCDMGroups then
        if ns.CDMGroups and ns.CDMGroups.RegisterExternalFrame then
            ns.CDMGroups.RegisterExternalFrame(arcID, frame, "cooldown", "Essential")
        else
            -- CDMGroups Integration not loaded yet, defer
            C_Timer.After(1.0, function()
                if ArcAuras.frames[arcID] and not ArcAuras.frames[arcID]._arcSlotEmpty then
                    if ns.CDMGroups and ns.CDMGroups.RegisterExternalFrame then
                        ns.CDMGroups.RegisterExternalFrame(arcID, frame, "cooldown", "Essential")
                    end
                end
            end)
        end
    end
    
    -- Register with CDMEnhance for visual style integration
    ArcAuras.RegisterWithCDMEnhance(arcID, frame)
    
    -- Register with Masque for skinning (if available)
    RegisterWithMasque(frame)
    
    -- Initialize stack cache for this frame
    InvalidateStackCache(arcID)
    
    return frame
end

function ArcAuras.DestroyFrame(arcID)
    local frame = ArcAuras.frames[arcID]
    if not frame then return end
    
    -- Clear caches
    InvalidateSettingsCache(arcID)
    InvalidateStackCache(arcID)
    
    -- Unregister from Masque (if registered)
    UnregisterFromMasque(frame)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 1: Unregister from CDMGroups (removes from groups/freeIcons)
    -- This must happen FIRST before we clear frame properties
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.CDMGroups and ns.CDMGroups.UnregisterExternalFrame then
        ns.CDMGroups.UnregisterExternalFrame(arcID)
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 2: Stop any visual effects (glows, animations)
    -- ═══════════════════════════════════════════════════════════════════════════
    if ns.CDMEnhance and ns.CDMEnhance.StopAllGlows then
        pcall(ns.CDMEnhance.StopAllGlows, frame, "ArcUI_Glow")
        pcall(ns.CDMEnhance.StopAllGlows, frame, "ArcAura_ReadyGlow")
        pcall(ns.CDMEnhance.StopAllGlows, frame, "ArcAura_ThresholdGlow")
        if frame._arcGlowAnchor then
            pcall(ns.CDMEnhance.StopAllGlows, frame._arcGlowAnchor, "ArcUI_Glow")
        end
    end
    
    -- Stop glows via LibCustomGlow directly as backup
    local LCG = GetLCG()
    if LCG then
        pcall(LCG.PixelGlow_Stop, frame, "ArcAura_ReadyGlow")
        pcall(LCG.PixelGlow_Stop, frame, "ArcUI_ReadyGlow")
        pcall(LCG.PixelGlow_Stop, frame, "ArcAura_ThresholdGlow")
        pcall(LCG.AutoCastGlow_Stop, frame, "ArcAura_ReadyGlow")
        pcall(LCG.AutoCastGlow_Stop, frame, "ArcUI_ReadyGlow")
        pcall(LCG.ButtonGlow_Stop, frame)
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 3: Clear ALL CDMGroups hooks and properties
    -- This prevents "ghost frames" from fighting to restore position
    -- ═══════════════════════════════════════════════════════════════════════════
    
    -- Clear hook flags (hooks can't be removed, but clearing flags disables them)
    frame._cdmgClearPointsHooked = nil
    frame._cdmgClearPointsFreeHooked = nil
    frame._cdmgScaleHooked = nil
    frame._cdmgSizeHooked = nil
    frame._cdmgStrataHooked = nil
    frame._cdmgParentHooked = nil
    
    -- Clear CDMGroups control properties (prevents hooks from triggering)
    frame._cdmgIsFreeIcon = nil
    frame._cdmgFreeTargetSize = nil
    frame._cdmgTargetPoint = nil
    frame._cdmgTargetRelPoint = nil
    frame._cdmgTargetX = nil
    frame._cdmgTargetY = nil
    frame._cdmgTargetSize = nil
    frame._cdmgSlotW = nil
    frame._cdmgSlotH = nil
    frame._cdmgSettingPosition = nil
    frame._cdmgSettingScale = nil
    frame._cdmgSettingSize = nil
    frame._cdmgSettingStrata = nil
    frame._cdmgSettingParent = nil
    
    -- Clear drag state
    frame._groupDragging = nil
    frame._freeDragging = nil
    frame._sourceGroup = nil
    frame._sourceCdID = nil
    frame._isDraggable = nil
    
    -- Clear recovery/timing flags
    frame._arcRecoveryProtection = nil
    frame.frameLostAt = nil
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 4: Clear drag handlers and scripts
    -- ═══════════════════════════════════════════════════════════════════════════
    pcall(function()
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:RegisterForDrag()  -- Unregister all drag buttons
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
        frame:SetScript("OnUpdate", nil)
    end)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 5: Hide visual elements
    -- ═══════════════════════════════════════════════════════════════════════════
    if frame._arcBorderEdges then
        if frame._arcBorderEdges.top then frame._arcBorderEdges.top:Hide() end
        if frame._arcBorderEdges.bottom then frame._arcBorderEdges.bottom:Hide() end
        if frame._arcBorderEdges.left then frame._arcBorderEdges.left:Hide() end
        if frame._arcBorderEdges.right then frame._arcBorderEdges.right:Hide() end
    end
    if frame._arcTextOverlay then frame._arcTextOverlay:Hide() end
    if frame._arcOverlay then frame._arcOverlay:Hide() end
    if frame._arcGlowAnchor then frame._arcGlowAnchor:Hide() end
    if frame._arcBorderOverlay then frame._arcBorderOverlay:Hide() end
    if frame._arcCountContainer then frame._arcCountContainer:Hide() end
    if frame._arcStackText then frame._arcStackText:Hide() end
    if frame.Cooldown then frame.Cooldown:Hide() end
    if frame.Icon then frame.Icon:Hide() end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- STEP 6: Final cleanup - hide and orphan the frame
    -- ═══════════════════════════════════════════════════════════════════════════
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetParent(nil)  -- Orphan the frame (allows GC if no other refs)
    
    -- Remove from our frames table
    ArcAuras.frames[arcID] = nil
end

function ArcAuras.GetFrame(arcID)
    return ArcAuras.frames[arcID]
end

function ArcAuras.UpdateFrameIcon(frame, config)
    if not frame or not config then return end
    
    local icon = nil
    
    if config.type == "trinket" and config.slotID then
        local itemID, itemName, itemIcon = GetSlotItemInfo(config.slotID)
        icon = itemIcon
        frame._currentItemID = itemID
        frame._currentItemName = itemName
    elseif config.type == "item" and config.itemID then
        local itemName, itemIcon = GetItemNameAndIcon(config.itemID)
        icon = itemIcon
        frame._currentItemID = config.itemID
        frame._currentItemName = itemName
    end
    
    if icon then
        frame.Icon:SetTexture(icon)
        -- NOTE: Don't set desaturation here - the update loop handles cooldown state
    else
        frame.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        frame._currentItemID = nil
        frame._currentItemName = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- POSITION MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

function ArcAuras.SaveFramePosition(arcID, point, relPoint, x, y)
    local db = GetDB()
    if not db then return end
    
    if not db.positions then db.positions = {} end
    db.positions[arcID] = {
        point = point or "CENTER",
        relPoint = relPoint or "CENTER",
        x = x or 0,
        y = y or 0,
    }
end

function ArcAuras.LoadFramePosition(arcID, frame)
    -- If CDMGroups is managing this frame, don't override its position
    -- CDMGroups uses savedPositions to track what it controls
    if ns.CDMGroups and ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[arcID] then
        -- CLEANUP: Remove legacy db.positions since CDMGroups now manages this
        local db = GetDB()
        if db and db.positions and db.positions[arcID] then
            db.positions[arcID] = nil
        end
        return  -- CDMGroups has control, skip ArcAuras positioning
    end
    
    local db = GetDB()
    if not db or not db.positions or not db.positions[arcID] then
        -- Default position based on type
        local arcType, id = ArcAuras.ParseArcID(arcID)
        if arcType == "trinket" then
            local offset = (id == 13) and -30 or 30
            frame:SetPoint("CENTER", UIParent, "CENTER", offset, -200)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        end
        return
    end
    
    local pos = db.positions[arcID]
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COOLDOWN UPDATE LOGIC
-- ═══════════════════════════════════════════════════════════════════════════

local function UpdateTrinketCooldown(frame, slotID)
    -- Skip cooldown update if preview is active (don't override fake preview cooldown)
    if frame._arcSwipePreviewActive then
        return frame._isOnCooldown, frame._remaining or 0
    end
    
    local startTime, duration, enable = GetInventoryItemCooldown("player", slotID)
    
    -- Update icon if item changed
    local currentItemID = GetInventoryItemID("player", slotID)
    if currentItemID ~= frame._currentItemID then
        local config = frame._arcConfig
        ArcAuras.UpdateFrameIcon(frame, config)
        -- Invalidate stack cache when trinket changes
        InvalidateStackCache(frame._arcAuraID)
    end
    
    -- Smart GCD filtering: Compare current duration to item's base cooldown
    -- If they don't match and duration is short, it's GCD not a real cooldown
    local arcID = frame._arcAuraID
    local settings = ArcAuras.GetCachedSettings(arcID)
    local noGCDSwipe = settings and settings.cooldownSwipe and settings.cooldownSwipe.noGCDSwipe
    
    if noGCDSwipe and duration and duration > 0 and IsLikelyGCD(currentItemID, duration) then
        -- This is GCD, not a real cooldown - hide it
        if frame._lastDuration ~= 0 then
            frame.Cooldown:Clear()
            frame._lastStartTime = 0
            frame._lastDuration = 0
        end
        
        frame._isOnCooldown = false
        frame._remaining = 0
        frame._startTime = 0
        frame._duration = 0
        
        return false, 0
    end
    
    -- Only call SetCooldown when values actually change (reduces API calls)
    local cooldownChanged = (startTime ~= frame._lastStartTime) or (duration ~= frame._lastDuration)
    
    if cooldownChanged then
        -- Apply cooldown using Duration Object if available
        if frame._durationObj and C_DurationUtil then
            frame._durationObj:SetTimeFromStart(startTime or 0, duration or 0)
            frame.Cooldown:SetCooldownFromDurationObject(frame._durationObj, true)
        else
            frame.Cooldown:SetCooldown(startTime or 0, duration or 0)
        end
        
        -- Apply swipe/edge colors from settings (only when cooldown changes)
        if settings and settings.cooldownSwipe then
            local sc = settings.cooldownSwipe.swipeColor
            if sc then
                frame.Cooldown:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
            end
            
            local ec = settings.cooldownSwipe.edgeColor
            if ec then
                frame.Cooldown:SetEdgeColor(ec.r or 1, ec.g or 1, ec.b or 1, ec.a or 1)
            end
        end
        
        -- Update cached values
        frame._lastStartTime = startTime
        frame._lastDuration = duration
    end
    
    -- Calculate state (NON-SECRET - direct comparison works!)
    local isOnCooldown = duration and duration > 0
    local remaining = 0
    if isOnCooldown then
        remaining = (startTime + duration) - GetTime()
        if remaining < 0 then
            remaining = 0
            isOnCooldown = false
        end
    end
    
    frame._isOnCooldown = isOnCooldown
    frame._remaining = remaining
    frame._startTime = startTime
    frame._duration = duration
    
    return isOnCooldown, remaining
end

local function UpdateItemCooldown(frame, itemID)
    -- Skip cooldown update if preview is active (don't override fake preview cooldown)
    if frame._arcSwipePreviewActive then
        return frame._isOnCooldown, frame._remaining or 0
    end
    
    local startTime, duration, enable = C_Container.GetItemCooldown(itemID)
    
    -- Smart GCD filtering: Compare current duration to item's base cooldown
    -- If they don't match and duration is short, it's GCD not a real cooldown
    local arcID = frame._arcAuraID
    local settings = ArcAuras.GetCachedSettings(arcID)
    local noGCDSwipe = settings and settings.cooldownSwipe and settings.cooldownSwipe.noGCDSwipe
    
    if noGCDSwipe and duration and duration > 0 and IsLikelyGCD(itemID, duration) then
        -- This is GCD, not a real cooldown - hide it
        if frame._lastDuration ~= 0 then
            frame.Cooldown:Clear()
            frame._lastStartTime = 0
            frame._lastDuration = 0
        end
        
        frame._isOnCooldown = false
        frame._remaining = 0
        frame._startTime = 0
        frame._duration = 0
        
        return false, 0
    end
    
    -- Detect cooldown STARTING (was off, now on) - item was just used!
    -- This is when charges change for items like Healthstone
    local cooldownJustStarted = (frame._lastDuration == 0 or frame._lastDuration == nil) and duration and duration > 1
    if cooldownJustStarted then
        -- Invalidate stack cache for THIS item only - charges likely changed
        stackCache[arcID] = nil
        -- Force usability recheck on next tick
        frame._lastUsableCheckTime = nil
    end
    
    -- Detect cooldown ENDING (was on, now off) - item may be usable again
    local cooldownJustEnded = (frame._lastDuration and frame._lastDuration > 1) and (not duration or duration <= 0)
    if cooldownJustEnded then
        -- Force usability recheck
        frame._lastUsableCheckTime = nil
    end
    
    -- Check if item is actually usable (handles once-per-combat items like Healthstone)
    -- Healthstone has duration=0.001 but is not usable until combat ends
    -- PERFORMANCE: Only check usability when state might have changed
    local isLockedOut = false
    if not frame._lastUsableCheckTime or (GetTime() - frame._lastUsableCheckTime) > 0.5 then
        local usable, noMana = C_Item.IsUsableItem(itemID)
        frame._lastUsableCheckTime = GetTime()
        frame._lastUsableResult = usable
        
        -- Item is "locked out" if:
        -- 1. Not usable (usable = false)
        -- 2. Has no meaningful cooldown (duration < 1 second) OR cooldown is basically done
        -- This catches items like Healthstone that show duration=0.001 but can't be used
        if not usable and duration then
            local remaining = (startTime and duration > 0) and ((startTime + duration) - GetTime()) or 0
            if remaining < 1 then
                isLockedOut = true
            end
        end
    else
        -- Use cached usability result
        if not frame._lastUsableResult and duration then
            local remaining = (startTime and duration > 0) and ((startTime + duration) - GetTime()) or 0
            if remaining < 1 then
                isLockedOut = true
            end
        end
    end
    
    -- For locked out items, don't show cooldown swipe - just mark as unavailable
    if isLockedOut then
        -- Clear cooldown animation to stop flickering
        if frame._lastDuration ~= 0 or not frame._arcLockedOut then
            frame.Cooldown:Clear()
            frame._lastStartTime = 0
            frame._lastDuration = 0
        end
        
        frame._isOnCooldown = false
        frame._remaining = 0
        frame._startTime = 0
        frame._duration = 0
        frame._arcLockedOut = true  -- Special flag for visual handling
        
        return false, 0
    end
    
    -- Clear locked out flag if item becomes usable again
    frame._arcLockedOut = false
    
    -- Only call SetCooldown when values actually change (reduces API calls)
    local cooldownChanged = (startTime ~= frame._lastStartTime) or (duration ~= frame._lastDuration)
    
    if cooldownChanged then
        -- Apply cooldown
        if frame._durationObj and C_DurationUtil then
            frame._durationObj:SetTimeFromStart(startTime or 0, duration or 0)
            frame.Cooldown:SetCooldownFromDurationObject(frame._durationObj, true)
        else
            frame.Cooldown:SetCooldown(startTime or 0, duration or 0)
        end
        
        -- Apply swipe/edge colors from settings (only when cooldown changes)
        if settings and settings.cooldownSwipe then
            local sc = settings.cooldownSwipe.swipeColor
            if sc then
                frame.Cooldown:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
            end
            
            local ec = settings.cooldownSwipe.edgeColor
            if ec then
                frame.Cooldown:SetEdgeColor(ec.r or 1, ec.g or 1, ec.b or 1, ec.a or 1)
            end
        end
        
        -- Update cached values
        frame._lastStartTime = startTime
        frame._lastDuration = duration
    end
    
    -- Calculate state
    local isOnCooldown = duration and duration > 0
    local remaining = 0
    if isOnCooldown then
        remaining = (startTime + duration) - GetTime()
        if remaining < 0 then
            remaining = 0
            isOnCooldown = false
        end
    end
    
    frame._isOnCooldown = isOnCooldown
    frame._remaining = remaining
    frame._startTime = startTime
    frame._duration = duration
    
    return isOnCooldown, remaining
end

-- Apply visual states based on settings
-- ═══════════════════════════════════════════════════════════════════════════
-- CDM ENHANCE INTEGRATION - Arc Auras provides cooldown STATE
-- CDM Enhance handles ALL visual effects (glow, alpha, desaturation)
-- ═══════════════════════════════════════════════════════════════════════════

--- Get the cooldown state for an Arc Aura
-- @param arcID The Arc Aura ID (e.g., "arc_trinket_13" or "arc_item_12345")
-- @return state ("ready" or "cooldown"), remaining (seconds), duration (seconds)
function ArcAuras.GetCooldownState(arcID)
    if not arcID then return "ready", 0, 0 end
    
    local frame = ArcAuras.frames and ArcAuras.frames[arcID]
    if not frame then return "ready", 0, 0 end
    
    -- Check frame's cached state
    if frame._isOnCooldown then
        return "cooldown", frame._remaining or 0, frame._duration or 0
    end
    
    return "ready", 0, 0
end

--- Check if an Arc Aura is ready (off cooldown)
-- @param arcID The Arc Aura ID
-- @return boolean true if ready
function ArcAuras.IsReady(arcID)
    local state = ArcAuras.GetCooldownState(arcID)
    return state == "ready"
end

--- Get all active Arc Aura frames
-- @return table of arcID -> frame
function ArcAuras.GetActiveFrames()
    return ArcAuras.frames or {}
end

--- Notify that cooldown state changed (called by update loop)
-- CDM Enhance can hook this to update visuals
function ArcAuras.NotifyStateChanged(arcID, isOnCooldown, remaining, duration)
    -- Fire a message that CDM Enhance can listen for
    if ns.CDMEnhance and ns.CDMEnhance.OnArcAuraStateChanged then
        ns.CDMEnhance.OnArcAuraStateChanged(arcID, isOnCooldown, remaining, duration)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PERFORMANCE: CACHED SETTINGS ACCESS
-- ═══════════════════════════════════════════════════════════════════════════

-- Get cached settings - avoids expensive GetEffectiveSettings() every tick
function ArcAuras.GetCachedSettings(arcID)
    local cached = settingsCache[arcID]
    local now = GetTime()
    
    -- Use cached if still valid
    if cached and (now - cached.timestamp) < SETTINGS_CACHE_TTL then
        return cached.settings
    end
    
    -- Cache miss or expired - fetch and cache
    local settings = ArcAuras.GetEffectiveSettings(arcID)
    settingsCache[arcID] = {
        settings = settings,
        timestamp = now,
    }
    
    return settings
end

-- Main update function - Updates cooldown display AND visual state
-- OPTIMIZED: Uses cached settings, cached LCG reference, state-change detection
local function OnArcAurasUpdate()
    local LCG = GetLCG()  -- Cached reference
    
    for arcID, frame in pairs(ArcAuras.frames) do
        if frame and frame:IsShown() then
            local config = frame._arcConfig
            if config then
                -- Step 1: Update the cooldown frame (sets the swipe animation)
                if config.type == "trinket" and config.slotID then
                    UpdateTrinketCooldown(frame, config.slotID)
                elseif config.type == "item" and config.itemID then
                    UpdateItemCooldown(frame, config.itemID)
                end
                
                -- Step 2: Determine if on cooldown using COOLDOWN:ISVISIBLE()
                -- This is the most reliable method per the debugger tests
                local isOnCooldown = frame.Cooldown and frame.Cooldown:IsVisible()
                local remaining = frame._remaining or 0
                local iconTex = frame.Icon
                
                -- Step 3: Get visual settings from CACHE (not fresh every tick!)
                local settings = ArcAuras.GetCachedSettings(arcID)
                
                -- Get properly formatted state visuals from CDMEnhance if available
                -- OPTIMIZED: Only fetch once per state change, not every tick
                local stateVisuals = frame._cachedStateVisuals
                local stateChanged = (frame._lastVisualState == "ready") ~= (not isOnCooldown)
                
                if stateChanged or not stateVisuals then
                    if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveStateVisuals then
                        stateVisuals = ns.CDMEnhance.GetEffectiveStateVisuals(settings)
                    end
                    frame._cachedStateVisuals = stateVisuals
                end
                
                -- Check if glow preview is active for this icon
                local isGlowPreview = ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.IsGlowPreviewActive and
                                      ns.CDMEnhanceOptions.IsGlowPreviewActive(arcID)
                
                -- Fallback to raw settings if CDMEnhance not available
                local csv = settings and settings.cooldownStateVisuals or {}
                local rs = csv.readyState or {}
                local cs = csv.cooldownState or {}
                
                -- Step 4: Apply visuals based on state
                -- NOTE: Preview mode forces ready-state visuals (glow) even when on cooldown
                if isOnCooldown and not isGlowPreview then
                    --===============================================
                    -- ON COOLDOWN: Desaturate, dim, stop ready glow
                    --===============================================
                    
                    -- Alpha: Check raw settings FIRST since that's where it's stored
                    -- stateVisuals.cooldownAlpha may not be populated correctly
                    local cooldownAlpha = cs.alpha or (stateVisuals and stateVisuals.cooldownAlpha) or 1.0
                    
                    -- OPTIONS PANEL PREVIEW: If alpha is 0, show at 0.35 so user can see the icon while editing
                    if cooldownAlpha <= 0 then
                        if ns.CDMEnhance and ns.CDMEnhance.IsOptionsPanelOpen and ns.CDMEnhance.IsOptionsPanelOpen() then
                            cooldownAlpha = 0.35
                        end
                    end
                    
                    -- OPTIMIZED: Only call SetAlpha when value changes
                    if frame._lastAppliedAlpha ~= cooldownAlpha then
                        frame:SetAlpha(cooldownAlpha)
                        frame._lastAppliedAlpha = cooldownAlpha
                    end
                    
                    -- Desaturation - DEFAULT ON unless user disabled via noDesaturate
                    local noDesaturate = (stateVisuals and stateVisuals.noDesaturate) or (cs.noDesaturate == true)
                    local shouldDesaturate = not noDesaturate
                    if iconTex then
                        if shouldDesaturate then
                            if iconTex.SetDesaturation then
                                iconTex:SetDesaturation(1)
                            elseif iconTex.SetDesaturated then
                                iconTex:SetDesaturated(true)
                            end
                        else
                            if iconTex.SetDesaturation then
                                iconTex:SetDesaturation(0)
                            elseif iconTex.SetDesaturated then
                                iconTex:SetDesaturated(false)
                            end
                        end
                    end
                    
                    -- Tint
                    local cooldownTint = (stateVisuals and stateVisuals.cooldownTint) or (cs.tint == true)
                    local tintColor = (stateVisuals and stateVisuals.cooldownTintColor) or cs.tintColor
                    if iconTex then
                        if cooldownTint and tintColor then
                            local c = tintColor
                            iconTex:SetVertexColor(c.r or 0.5, c.g or 0.5, c.b or 0.5, 1)
                        else
                            iconTex:SetVertexColor(1, 1, 1, 1)
                        end
                    end
                    
                    -- Preserve Duration Text - make text visible even when frame is dimmed
                    local preserveText = (stateVisuals and stateVisuals.preserveDurationText) or (cs.preserveDurationText == true)
                    if preserveText then
                        -- Make cooldown text ignore parent alpha
                        if frame.Cooldown and frame.Cooldown.Text and frame.Cooldown.Text.SetIgnoreParentAlpha then
                            frame.Cooldown.Text:SetIgnoreParentAlpha(true)
                            frame.Cooldown.Text:SetAlpha(1)
                        end
                        -- Also handle any custom text overlays
                        if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
                            frame._arcCooldownText:SetIgnoreParentAlpha(true)
                            frame._arcCooldownText:SetAlpha(1)
                        end
                    else
                        -- Reset text alpha behavior
                        if frame.Cooldown and frame.Cooldown.Text and frame.Cooldown.Text.SetIgnoreParentAlpha then
                            frame.Cooldown.Text:SetIgnoreParentAlpha(false)
                        end
                        if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
                            frame._arcCooldownText:SetIgnoreParentAlpha(false)
                        end
                    end
                    
                    -- Stop ready glows (only on state change)
                    if frame._lastVisualState ~= "cooldown" then
                        frame._lastVisualState = "cooldown"
                        frame._arcReadyGlowActive = false  -- Clear flag so glow can restart when ready
                        frame._arcPreviewGlowActive = false
                        -- Use CDMEnhance's HideReadyGlow if available
                        if ns.CDMEnhance and ns.CDMEnhance.HideReadyGlow then
                            ns.CDMEnhance.HideReadyGlow(frame)
                        elseif LCG then
                            pcall(LCG.PixelGlow_Stop, frame, "ArcAura_ReadyGlow")
                            pcall(LCG.PixelGlow_Stop, frame, "ArcUI_ReadyGlow")
                            pcall(LCG.AutoCastGlow_Stop, frame, "ArcAura_ReadyGlow")
                            pcall(LCG.AutoCastGlow_Stop, frame, "ArcUI_ReadyGlow")
                            pcall(LCG.ButtonGlow_Stop, frame)
                        end
                    end
                    
                    -- Threshold glow (when almost ready)
                    local tg = settings and settings.thresholdGlow
                    if tg and tg.enabled and remaining > 0 and LCG then
                        if remaining <= (tg.seconds or 5) then
                            if not frame._thresholdGlowActive then
                                local color = tg.color or {1, 0.5, 0, 1}
                                pcall(LCG.PixelGlow_Start, frame, color, 8, 0.25, nil, 2, 0, 0, true, "ArcAura_ThresholdGlow")
                                frame._thresholdGlowActive = true
                            end
                        elseif frame._thresholdGlowActive then
                            pcall(LCG.PixelGlow_Stop, frame, "ArcAura_ThresholdGlow")
                            frame._thresholdGlowActive = false
                        end
                    end
                else
                    --===============================================
                    -- READY: Full color, full alpha, optional glow
                    --===============================================
                    
                    -- Alpha: Check raw settings FIRST since that's where it's stored
                    -- stateVisuals.readyAlpha may not be populated correctly
                    local readyAlpha = rs.alpha or (stateVisuals and stateVisuals.readyAlpha) or 1.0
                    
                    -- OPTIONS PANEL PREVIEW: If alpha is 0, show at 0.35 so user can see the icon while editing
                    if readyAlpha <= 0 then
                        if ns.CDMEnhance and ns.CDMEnhance.IsOptionsPanelOpen and ns.CDMEnhance.IsOptionsPanelOpen() then
                            readyAlpha = 0.35
                        end
                    end
                    
                    -- OPTIMIZED: Only call SetAlpha when value changes
                    if frame._lastAppliedAlpha ~= readyAlpha then
                        frame:SetAlpha(readyAlpha)
                        frame._lastAppliedAlpha = readyAlpha
                    end
                    
                    -- Check if item is usable - use cached result from cooldown update
                    local isUnusable = false
                    local isPassive = config.isPassive
                    local isLockedOut = frame._arcLockedOut
                    
                    if not isPassive and config.type == "item" and config.itemID then
                        -- Use cached usability from UpdateItemCooldown
                        isUnusable = (frame._lastUsableResult == false) or isLockedOut
                    elseif isLockedOut then
                        isUnusable = true
                    end
                    
                    -- Desaturation: normally off when ready, but ON if item is unusable/locked out
                    -- Passive items always show normal (full color) - they have no usable state
                    if iconTex then
                        if isUnusable and not isPassive then
                            -- Item not usable (not in bags, wrong class, locked out for combat) - desaturate
                            if iconTex.SetDesaturation then
                                iconTex:SetDesaturation(1)
                            elseif iconTex.SetDesaturated then
                                iconTex:SetDesaturated(true)
                            end
                            -- Dim vertex color to indicate unavailable
                            iconTex:SetVertexColor(0.6, 0.6, 0.6, 1)
                        else
                            -- Normal ready state (or passive item) - no desaturation
                            if iconTex.SetDesaturation then
                                iconTex:SetDesaturation(0)
                            elseif iconTex.SetDesaturated then
                                iconTex:SetDesaturated(false)
                            end
                            iconTex:SetVertexColor(1, 1, 1, 1)
                        end
                    end
                    
                    -- Reset text alpha behavior when ready
                    if frame.Cooldown and frame.Cooldown.Text and frame.Cooldown.Text.SetIgnoreParentAlpha then
                        frame.Cooldown.Text:SetIgnoreParentAlpha(false)
                    end
                    if frame._arcCooldownText and frame._arcCooldownText.SetIgnoreParentAlpha then
                        frame._arcCooldownText:SetIgnoreParentAlpha(false)
                    end
                    
                    -- Stop threshold glow when ready
                    if LCG and frame._thresholdGlowActive then
                        pcall(LCG.PixelGlow_Stop, frame, "ArcAura_ThresholdGlow")
                        frame._thresholdGlowActive = false
                    end
                    
                    -- Track state change for other purposes
                    local stateJustChanged = (frame._lastVisualState ~= "ready")
                    frame._lastVisualState = "ready"
                    
                    -- GLOW HANDLING: Only update on state change or preview toggle
                    local shouldShowGlow = isGlowPreview or (stateVisuals and stateVisuals.readyGlow) or (rs.glow == true)
                    
                    -- Check combat-only restriction (but preview overrides this)
                    local glowCombatOnly = (stateVisuals and stateVisuals.readyGlowCombatOnly) or (rs.glowCombatOnly == true)
                    if glowCombatOnly and not InCombatLockdown() and not isGlowPreview then
                        shouldShowGlow = false
                    end
                    
                    -- Disable glow for unusable/locked out items (no glow when you can't use it)
                    -- Preview mode overrides this so you can still see what the glow looks like
                    if isUnusable and not isGlowPreview then
                        shouldShowGlow = false
                    end
                    
                    -- Track current glow state
                    local glowCurrentlyShowing = frame._arcReadyGlowActive or false
                    
                    -- Only start/stop glow on state change (not every tick!)
                    if shouldShowGlow and (stateJustChanged or not glowCurrentlyShowing) then
                        -- START glow
                        frame._arcReadyGlowActive = true
                        frame._arcPreviewGlowActive = isGlowPreview
                        
                        -- Build glow settings - prefer stateVisuals, fallback to raw readyState
                        local glowSettings = stateVisuals
                        if not glowSettings then
                            -- Create glow settings from raw readyState
                            glowSettings = {
                                readyGlow = true,
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
                            }
                        end
                        
                        -- Use CDMEnhance's ShowReadyGlow (has signature check for efficient updates)
                        if ns.CDMEnhance and ns.CDMEnhance.ShowReadyGlow then
                            ns.CDMEnhance.ShowReadyGlow(frame, glowSettings)
                        elseif LCG then
                            -- Fallback: manual glow
                            local glowType = glowSettings.readyGlowType or "button"
                            local glowColor = glowSettings.readyGlowColor
                            local intensity = glowSettings.readyGlowIntensity or 1.0
                            local speed = glowSettings.readyGlowSpeed or 0.25
                            local lines = glowSettings.readyGlowLines or 8
                            local thickness = glowSettings.readyGlowThickness or 2
                            local particles = glowSettings.readyGlowParticles or 4
                            local xOffset = glowSettings.readyGlowXOffset or 0
                            local yOffset = glowSettings.readyGlowYOffset or 0
                            
                            -- Build color table
                            local r, g, b = 1, 0.85, 0
                            if glowColor then
                                r = glowColor.r or glowColor[1] or 1
                                g = glowColor.g or glowColor[2] or 0.85
                                b = glowColor.b or glowColor[3] or 0
                            end
                            local color = {r, g, b, intensity}
                            
                            if glowType == "pixel" then
                                pcall(LCG.PixelGlow_Start, frame, color, lines, speed, nil, thickness, xOffset, yOffset, true, "ArcAura_ReadyGlow")
                            elseif glowType == "autocast" then
                                pcall(LCG.AutoCastGlow_Start, frame, color, particles, speed, 1, xOffset, yOffset, "ArcAura_ReadyGlow")
                            else
                                pcall(LCG.ButtonGlow_Start, frame, color, speed)
                            end
                        end
                        
                    elseif not shouldShowGlow and glowCurrentlyShowing then
                        -- STOP glow
                        frame._arcReadyGlowActive = false
                        frame._arcPreviewGlowActive = false
                        
                        if ns.CDMEnhance and ns.CDMEnhance.HideReadyGlow then
                            ns.CDMEnhance.HideReadyGlow(frame)
                        elseif LCG then
                            pcall(LCG.PixelGlow_Stop, frame, "ArcAura_ReadyGlow")
                            pcall(LCG.PixelGlow_Stop, frame, "ArcUI_ReadyGlow")
                            pcall(LCG.AutoCastGlow_Stop, frame, "ArcAura_ReadyGlow")
                            pcall(LCG.AutoCastGlow_Stop, frame, "ArcUI_ReadyGlow")
                            pcall(LCG.ButtonGlow_Stop, frame)
                        end
                    end
                end
                
                -- ═══════════════════════════════════════════════════════════════
                -- STACK/CHARGE COUNT UPDATE (uses cached values)
                -- ═══════════════════════════════════════════════════════════════
                local displayValue, isCharges = GetStackDisplay(config, arcID)
                
                -- frame._arcStackText is created in CreateArcAuraFrame, should always exist
                if frame._arcStackText then
                    -- Check if charge text is enabled in settings
                    local chargeTextEnabled = true
                    if settings and settings.chargeText and settings.chargeText.enabled == false then
                        chargeTextEnabled = false
                    end
                    
                    if displayValue ~= nil and chargeTextEnabled then
                        -- Apply styling from CDMEnhance chargeText settings
                        -- Only re-apply styling if not done recently (performance)
                        if not frame._arcStackStyleApplied then
                            ApplyStackTextStyle(frame, frame._arcStackText)
                            frame._arcStackStyleApplied = true
                        end
                        
                        -- Pass displayValue directly to SetText - it may be SECRET during combat!
                        -- Do NOT compare or manipulate the value, just display it
                        frame._arcStackText:SetText(displayValue)
                        frame._arcStackText:Show()
                    else
                        -- No stack/charges to show, or charge text disabled
                        frame._arcStackText:SetText("")
                        frame._arcStackText:Hide()
                    end
                end
                
                -- Notify CDM Enhance for border sync
                if frame._lastCooldownState ~= isOnCooldown then
                    frame._lastCooldownState = isOnCooldown
                    ArcAuras.NotifyStateChanged(arcID, isOnCooldown, remaining, frame._duration or 0)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SETTINGS INTEGRATION
-- ═══════════════════════════════════════════════════════════════════════════

local DEFAULT_ARCAURA_SETTINGS = {
    scale = 1.0,
    alpha = 1.0,
    zoom = 0.08,
    hideShadow = true,
    
    cooldownStateVisuals = {
        readyState = {
            alpha = 1.0,
            glow = false,
        },
        cooldownState = {
            alpha = 1.0,
            desaturate = true,  -- Match CDM behavior: desaturate when on cooldown
        },
    },
    
    cooldownSwipe = {
        showSwipe = true,
        showEdge = true,
        showBling = true,
    },
    
    thresholdGlow = {
        enabled = false,
        seconds = 5,
        color = {1, 0.5, 0, 1},
    },
    
    border = {
        enabled = false,
    },
}

-- Deep merge helper for nested tables
local function DeepMerge(base, override)
    if not override then return base end
    if not base then return override end
    
    local result = CopyTable(base)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = DeepMerge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

function ArcAuras.GetEffectiveSettings(arcID)
    -- Start with Arc Aura defaults
    local result = CopyTable(DEFAULT_ARCAURA_SETTINGS)
    
    -- Use CDMEnhance's proper cascading merge if available
    -- This handles: defaults → globalCooldownSettings → per-icon settings
    if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveIconSettings then
        local cdmSettings = ns.CDMEnhance.GetEffectiveIconSettings(arcID)
        if cdmSettings then
            -- Merge CDMEnhance settings over Arc Aura defaults
            result = DeepMerge(result, cdmSettings)
        end
    else
        -- Fallback: direct DB access (legacy behavior)
        if ns.db and ns.db.profile and ns.db.profile.cdmEnhance and ns.db.profile.cdmEnhance.iconSettings then
            local perIcon = ns.db.profile.cdmEnhance.iconSettings[arcID]
            if perIcon then
                result = DeepMerge(result, perIcon)
            end
        end
    end
    
    -- Also merge Arc Auras-specific global settings (if any)
    local db = GetDB()
    if db and db.globalSettings and next(db.globalSettings) then
        result = DeepMerge(result, db.globalSettings)
    end
    
    return result
end

-- Apply CDMEnhance settings to an Arc Aura frame
-- Called by CDMEnhance.UpdateIcon via Integration patch
function ArcAuras.ApplySettingsToFrame(arcID, frame)
    if not frame then
        frame = ArcAuras.frames[arcID]
    end
    if not frame then return end
    
    -- Invalidate settings cache when applying new settings
    InvalidateSettingsCache(arcID)
    
    local cfg = ArcAuras.GetEffectiveSettings(arcID)
    if not cfg then return end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- SIZE: Check if frame is in a group - if so, use group size
    -- ═══════════════════════════════════════════════════════════════════════════
    local width, height
    local inGroup = false
    
    -- Check if frame is in a CDMGroup
    if ns.CDMGroups and ns.CDMGroups.groups then
        for groupName, group in pairs(ns.CDMGroups.groups) do
            if group.members and group.members[arcID] then
                inGroup = true
                -- Use group's slot dimensions (respects group iconSize/width/height)
                if ns.CDMGroups.GetSlotDimensions then
                    width, height = ns.CDMGroups.GetSlotDimensions(group.layout)
                else
                    -- Fallback: calculate manually
                    local baseScale = 36
                    local iconSize = group.layout.iconSize or 36
                    local iconWidth = group.layout.iconWidth or 36
                    local iconHeight = group.layout.iconHeight or 36
                    local scale = iconSize / baseScale
                    width = iconWidth * scale
                    height = iconHeight * scale
                end
                break
            end
        end
    end
    
    -- If not in a group, use ArcAura's own size settings
    if not inGroup then
        local scale = cfg.scale or 1
        local baseWidth = cfg.width or 40
        local baseHeight = cfg.height or 40
        width = baseWidth * scale
        height = baseHeight * scale
    end
    
    frame:SetSize(width, height)
    
    -- Ensure scale is 1 (size is handled above)
    frame:SetScale(1)
    
    -- Check if Masque is controlling this frame's icon
    local masqueActive = frame._arcAuraMasqueRegistered and ns.Masque and ns.Masque.IsEnabled and ns.Masque.IsEnabled()
    
    -- Get zoom and padding from config (needed for cooldown positioning even when Masque is active)
    local zoom = cfg.zoom or 0.08
    local padding = cfg.padding or 0
    
    -- Apply zoom/texcoords (skip if Masque is active)
    if frame.Icon then
        if masqueActive then
            -- Masque controls icon - reset to defaults
            frame.Icon:SetTexCoord(0, 1, 0, 1)
            frame.Icon:ClearAllPoints()
            frame.Icon:SetAllPoints()
            -- Override padding/zoom when Masque is active
            zoom = 0
            padding = 0
        else
            -- ArcUI controls icon - apply zoom and padding
            frame.Icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
            
            -- Apply icon padding (insets the icon from the frame edges)
            if padding > 0 then
                frame.Icon:ClearAllPoints()
                frame.Icon:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
                frame.Icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)
            else
                frame.Icon:ClearAllPoints()
                frame.Icon:SetAllPoints()
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- COOLDOWN ANIMATION SETTINGS (full CDMEnhance parity)
    -- ═══════════════════════════════════════════════════════════════════════════
    if frame.Cooldown then
        local swipe = cfg.cooldownSwipe or {}
        
        -- Basic swipe settings
        frame.Cooldown:SetDrawSwipe(swipe.showSwipe ~= false)
        frame.Cooldown:SetDrawEdge(swipe.showEdge ~= false)
        frame.Cooldown:SetDrawBling(swipe.showBling ~= false)
        frame.Cooldown:SetReverse(swipe.reverse == true)
        
        -- Swipe color
        if swipe.swipeColor then
            local sc = swipe.swipeColor
            frame.Cooldown:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
        else
            -- Default black swipe
            frame.Cooldown:SetSwipeColor(0, 0, 0, 0.7)
        end
        
        -- Edge scale
        if swipe.edgeScale and frame.Cooldown.SetEdgeScale then
            frame.Cooldown:SetEdgeScale(swipe.edgeScale)
        end
        
        -- Edge color
        if swipe.edgeColor and frame.Cooldown.SetEdgeColor then
            local ec = swipe.edgeColor
            frame.Cooldown:SetEdgeColor(ec.r or 1, ec.g or 1, ec.b or 1, ec.a or 1)
        end
        
        -- Swipe insets (adjust cooldown frame positioning)
        local swipeInsetX, swipeInsetY
        
        if swipe.separateInsets then
            swipeInsetX = swipe.swipeInsetX or 0
            swipeInsetY = swipe.swipeInsetY or 0
        else
            local inset = swipe.swipeInset or 0
            swipeInsetX = inset
            swipeInsetY = inset
        end
        
        local totalPaddingX = padding + swipeInsetX
        local totalPaddingY = padding + swipeInsetY
        
        -- Apply insets to cooldown frame
        frame.Cooldown:ClearAllPoints()
        frame.Cooldown:SetPoint("TOPLEFT", frame, "TOPLEFT", totalPaddingX, -totalPaddingY)
        frame.Cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -totalPaddingX, totalPaddingY)
        
        -- Store padding for hooks
        frame.Cooldown._arcPaddingX = totalPaddingX
        frame.Cooldown._arcPaddingY = totalPaddingY
        
        -- Apply texcoord range to cooldown swipe to match icon crop
        if swipe.showSwipe ~= false then
            local left, right, top, bottom = zoom, 1 - zoom, zoom, 1 - zoom
            if frame.Cooldown.SetSwipeTexCoords then
                frame.Cooldown:SetSwipeTexCoords(left, right, top, bottom)
            end
        end
        
        -- Store settings for hooks to reference
        frame._arcShowSwipe = swipe.showSwipe ~= false
        frame._arcShowEdge = swipe.showEdge ~= false
        frame._arcReverse = swipe.reverse == true
        frame._arcSwipeColor = swipe.swipeColor
    end
    
    -- Apply border if CDMEnhance has border functions
    if ns.CDMEnhance and ns.CDMEnhance.ApplyBorder then
        ns.CDMEnhance.ApplyBorder(frame, arcID)
    end
end

--- Refresh just the swipe/edge colors for a frame (called when settings change)
-- This forces immediate update without waiting for cooldown state change
function ArcAuras.RefreshSwipeColors(arcID)
    local frame = ArcAuras.frames[arcID]
    if not frame or not frame.Cooldown then return end
    
    -- Invalidate cache to get fresh settings
    InvalidateSettingsCache(arcID)
    
    local settings = ArcAuras.GetEffectiveSettings(arcID)
    if not settings or not settings.cooldownSwipe then return end
    
    local swipe = settings.cooldownSwipe
    
    -- Apply swipe color
    if swipe.swipeColor then
        local sc = swipe.swipeColor
        frame.Cooldown:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.8)
    else
        frame.Cooldown:SetSwipeColor(0, 0, 0, 0.7)
    end
    
    -- Apply edge color
    if swipe.edgeColor and frame.Cooldown.SetEdgeColor then
        local ec = swipe.edgeColor
        frame.Cooldown:SetEdgeColor(ec.r or 1, ec.g or 1, ec.b or 1, ec.a or 1)
    end
    
    -- Update cached color
    frame._arcSwipeColor = swipe.swipeColor
end

--- Refresh swipe colors for all Arc Aura frames
function ArcAuras.RefreshAllSwipeColors()
    for arcID, frame in pairs(ArcAuras.frames) do
        ArcAuras.RefreshSwipeColors(arcID)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TOOLTIP & CONTEXT MENU
-- ═══════════════════════════════════════════════════════════════════════════

function ArcAuras.ShowTooltip(frame)
    local config = frame._arcConfig
    
    if config.type == "trinket" then
        local itemID = GetInventoryItemID("player", config.slotID)
        if itemID then
            GameTooltip:SetInventoryItem("player", config.slotID)
        else
            GameTooltip:AddLine(config.name or "Empty Trinket Slot", 1, 1, 1)
            GameTooltip:AddLine("No trinket equipped", 0.7, 0.7, 0.7)
        end
    elseif config.type == "item" then
        GameTooltip:SetItemByID(config.itemID)
    end
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00CCFFArc Auras|r", 0, 0.8, 1)
    
    -- Show auto-track indicator
    if config.isAutoTrackSlot then
        GameTooltip:AddLine("|cff88ff88Auto-Tracked Slot|r", 0.5, 1, 0.5)
    end
    
    GameTooltip:AddLine("Right-click for options", 0.7, 0.7, 0.7)
    
    if frame._isOnCooldown and frame._remaining then
        GameTooltip:AddLine(string.format("Cooldown: %.1fs", frame._remaining), 1, 0.8, 0)
    end
end

function ArcAuras.ShowContextMenu(frame)
    local menu = {
        { text = "Arc Auras: " .. (frame._currentItemName or frame._arcAuraID), isTitle = true },
        { text = "Configure Icon", func = function()
            ArcAuras.OpenIconConfig(frame._arcAuraID)
        end },
        { text = "Reset Position", func = function()
            ArcAuras.ResetFramePosition(frame._arcAuraID)
        end },
        { text = "Hide This Frame", func = function()
            ArcAuras.SetTrackedItemEnabled(frame._arcAuraID, false)
        end },
        { text = "Cancel", func = function() end },
    }
    
    EasyMenu(menu, CreateFrame("Frame", "ArcAurasContextMenu", UIParent, "UIDropDownMenuTemplate"), "cursor", 0, 0, "MENU")
end

function ArcAuras.OpenIconConfig(arcID)
    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.OpenIconConfig then
        ns.CDMEnhanceOptions.OpenIconConfig(arcID)
    else
        print("|cff00CCFF[Arc Auras]|r Icon configuration panel not available")
    end
end

function ArcAuras.ResetFramePosition(arcID)
    -- Clear from legacy db.positions
    local db = GetDB()
    if db and db.positions then
        db.positions[arcID] = nil
    end
    
    -- Also clear from CDMGroups savedPositions (profile system)
    if ns.CDMGroups then
        if ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[arcID] then
            ns.CDMGroups.savedPositions[arcID] = nil
        end
        if ns.CDMGroups.ClearPositionFromSpec then
            ns.CDMGroups.ClearPositionFromSpec(arcID)
        end
        -- Also remove from freeIcons if tracked there
        if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[arcID] then
            ns.CDMGroups.ReleaseFreeIcon(arcID)
        end
    end
    
    local frame = ArcAuras.frames[arcID]
    if frame then
        frame:ClearAllPoints()
        ArcAuras.LoadFramePosition(arcID, frame)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TRACKED ITEMS MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

function ArcAuras.GetTrackedItems()
    local db = GetDB()
    if not db then return {} end
    return db.trackedItems or {}
end

function ArcAuras.AddTrackedItem(config)
    local db = GetDB()
    if not db then 
        print("|cffFF4444[Arc Auras]|r ERROR: Database not ready, cannot add item")
        return false 
    end
    
    -- CRITICAL: Ensure trackedItems exists
    if not db.trackedItems then 
        db.trackedItems = {} 
    end
    
    local arcID
    local itemID  -- For passive detection
    
    if config.type == "trinket" then
        arcID = ArcAuras.MakeTrinketID(config.slotID)
        -- Get itemID from slot for passive detection
        itemID = GetInventoryItemID("player", config.slotID)
    elseif config.type == "item" then
        arcID = ArcAuras.MakeItemID(config.itemID)
        itemID = config.itemID
    else
        print("|cffFF4444[Arc Auras]|r ERROR: Invalid item type:", config.type)
        return false
    end
    
    -- Check if already tracked
    if db.trackedItems[arcID] then
        -- Already exists - just return true without creating duplicate
        return true
    end
    
    -- Detect if item is passive (no on-use spell)
    local isPassive = IsItemPassive(itemID)
    
    -- Create the entry
    local entry = {
        type = config.type,
        slotID = config.slotID,
        itemID = config.itemID,
        enabled = true,
        isPassive = isPassive,
        isAutoTrackSlot = config.isAutoTrackSlot or false,
        hideWhenUnequipped = config.hideWhenUnequipped or false,
    }
    
    -- Save to database
    db.trackedItems[arcID] = entry
    
    -- VALIDATION: Verify it was actually saved
    if not db.trackedItems[arcID] then
        print("|cffFF4444[Arc Auras]|r ERROR: Failed to save item to database!")
        return false
    end
    
    -- Invalidate caches
    InvalidateSettingsCache(arcID)
    InvalidateStackCache(arcID)
    
    if ArcAuras.isEnabled then
        local frame = ArcAuras.CreateFrame(arcID, db.trackedItems[arcID])
        if frame then
            ArcAuras.LoadFramePosition(arcID, frame)
            
            -- Check if item-based frame should be hidden
            local shouldShow = true
            if config.type == "item" and config.hideWhenUnequipped then
                if not ArcAuras.IsItemEquipped(config.itemID) then
                    shouldShow = false
                    frame._arcHiddenUnequipped = true
                    frame:Hide()
                    frame:SetAlpha(0)
                end
            end
            
            if shouldShow then
                frame:Show()
                -- Apply proper state visuals (respects saved alpha settings)
                ArcAuras.ApplyInitialStateVisuals(arcID, frame)
            end
            
            -- For items with on-use spells, schedule a delayed stack refresh
            -- This handles the case where tooltip data isn't ready immediately
            if config.type == "item" and config.itemID then
                local spellName, spellID = GetItemSpell(config.itemID)
                if spellID then
                    C_Timer.After(0.5, function()
                        if ArcAuras.frames[arcID] then
                            stackCache[arcID] = nil  -- Force recompute
                        end
                    end)
                end
            end
        end
    end
    
    return true
end

function ArcAuras.RemoveTrackedItem(arcID)
    local db = GetDB()
    if not db or not db.trackedItems then return end
    
    if db.trackedItems[arcID] then
        db.trackedItems[arcID] = nil
        ArcAuras.DestroyFrame(arcID)
        
        -- Also remove position from legacy storage
        if db.positions then
            db.positions[arcID] = nil
        end
        
        -- Also remove from CDMGroups savedPositions (profile system)
        if ns.CDMGroups then
            if ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[arcID] then
                ns.CDMGroups.savedPositions[arcID] = nil
            end
            if ns.CDMGroups.ClearPositionFromSpec then
                ns.CDMGroups.ClearPositionFromSpec(arcID)
            end
        end
    end
end

function ArcAuras.SetTrackedItemEnabled(arcID, enabled)
    local db = GetDB()
    if not db or not db.trackedItems or not db.trackedItems[arcID] then return end
    
    db.trackedItems[arcID].enabled = enabled
    
    if enabled and ArcAuras.isEnabled then
        local frame = ArcAuras.frames[arcID] or ArcAuras.CreateFrame(arcID, db.trackedItems[arcID])
        if frame then
            ArcAuras.LoadFramePosition(arcID, frame)
            frame:Show()
            -- Apply proper state visuals (respects saved alpha settings)
            ArcAuras.ApplyInitialStateVisuals(arcID, frame)
        end
    elseif not enabled and ArcAuras.frames[arcID] then
        ArcAuras.frames[arcID]:Hide()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TRINKET SLOT VISIBILITY (hide when empty, show when equipped)
-- When hidden, frames are removed from groups so they don't occupy space
-- ═══════════════════════════════════════════════════════════════════════════

-- Temporarily hide a trinket slot frame (when slot is empty)
-- Removes from group so it doesn't occupy space, preserves position for restoration
function ArcAuras.HideTrinketSlotFrame(arcID)
    local frame = ArcAuras.frames[arcID]
    if not frame then 
        return 
    end
    
    -- Mark as hidden due to empty slot
    frame._arcSlotEmpty = true
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CRITICAL: Hook the frame's Show method to PREVENT re-showing
    -- CDMGroups and other systems may try to Show() the frame after we hide it
    -- ═══════════════════════════════════════════════════════════════════════════
    if not frame._arcOriginalShow then
        frame._arcOriginalShow = frame.Show
        frame.Show = function(self)
            if self._arcSlotEmpty then
                return  -- Block the show
            end
            return self._arcOriginalShow(self)
        end
    end
    
    -- Save current group position before removing
    if ns.CDMGroups and ns.CDMGroups.groups then
        for groupName, group in pairs(ns.CDMGroups.groups) do
            if group.members and group.members[arcID] then
                -- Save the position for restoration
                local member = group.members[arcID]
                frame._arcSavedGroupName = groupName
                frame._arcSavedRow = member.row
                frame._arcSavedCol = member.col
                
                -- Remove from group (but keep savedPositions intact)
                if group.RemoveMemberKeepFrame then
                    group:RemoveMemberKeepFrame(arcID)
                elseif group.RemoveMember then
                    group:RemoveMember(arcID, true)  -- keepFrame = true
                end
                
                -- Layout the group to close the gap
                if group.Layout then group:Layout() end
                break
            end
        end
        
        -- Also check if it's a free icon
        if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[arcID] then
            local freeData = ns.CDMGroups.freeIcons[arcID]
            frame._arcSavedFreeX = freeData.x
            frame._arcSavedFreeY = freeData.y
            frame._arcSavedFreeSize = freeData.iconSize
            frame._arcWasFreeIcon = true
            -- CRITICAL: ReleaseFreeIcon parameter is clearSaved - pass FALSE to keep savedPositions!
            ns.CDMGroups.ReleaseFreeIcon(arcID, false)  -- false = DON'T clear saved position
        end
    end
    
    -- Hide the frame
    frame:Hide()
    frame:SetAlpha(0)
end

-- Restore a trinket slot frame (when trinket is equipped)
-- Re-adds to group at saved position or registers as new
function ArcAuras.ShowTrinketSlotFrame(arcID)
    local frame = ArcAuras.frames[arcID]
    if not frame then return end
    
    -- Clear empty slot flag
    frame._arcSlotEmpty = nil
    
    -- Update the icon for the new trinket
    local config = frame._arcConfig
    if config then
        ArcAuras.UpdateFrameIcon(frame, config)
        frame._arcStackStyleApplied = false
        InvalidateStackCache(arcID)
    end
    
    -- Show the frame
    frame:Show()
    -- Apply proper state visuals (respects saved alpha settings)
    ArcAuras.ApplyInitialStateVisuals(arcID, frame)
    
    -- Restore to group or free position
    if ns.CDMGroups then
        if frame._arcWasFreeIcon then
            -- Was a free icon - restore as free
            local x = frame._arcSavedFreeX or 0
            local y = frame._arcSavedFreeY or 0
            local size = frame._arcSavedFreeSize or 36
            ns.CDMGroups.TrackFreeIcon(arcID, x, y, size, frame)
            
            -- Clear saved data
            frame._arcWasFreeIcon = nil
            frame._arcSavedFreeX = nil
            frame._arcSavedFreeY = nil
            frame._arcSavedFreeSize = nil
        elseif frame._arcSavedGroupName then
            local groupName = frame._arcSavedGroupName
            local row = frame._arcSavedRow or 0
            local col = frame._arcSavedCol or 0
            local group = ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
            
            if group then
                -- Re-add to the saved group position
                if group.AddMemberAtWithFrame then
                    group:AddMemberAtWithFrame(arcID, row, col, frame, nil)
                elseif group.AddMemberAt then
                    group:AddMemberAt(arcID, row, col)
                end
                
                -- Layout the group
                if group.Layout then group:Layout() end
                
                -- Trigger Masque refresh for proper sizing
                if ns.Masque and ns.Masque.QueueRefresh then
                    ns.Masque.QueueRefresh()
                end
            end
            
            -- Clear saved position
            frame._arcSavedGroupName = nil
            frame._arcSavedRow = nil
            frame._arcSavedCol = nil
        else
            -- No saved position - this is first time showing
            -- Check if CDMGroups has a saved position or register as new
            -- CRITICAL: Ensure savedPositions reference is correct for current spec
            if ns.CDMGroups.GetProfileSavedPositions then
                ns.CDMGroups.GetProfileSavedPositions()
            end
            
            if ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[arcID] then
                -- CDMGroups has a saved position - use RegisterExternalFrame to restore
                if ns.CDMGroups.RegisterExternalFrame then
                    ns.CDMGroups.RegisterExternalFrame(arcID, frame, "cooldown", "Essential")
                end
            elseif ns.CDMGroups.RegisterExternalFrame then
                -- No saved position - register as new (will go to default group)
                ns.CDMGroups.RegisterExternalFrame(arcID, frame, "cooldown", "Essential")
            end
            
            -- Trigger Masque refresh for proper sizing
            if ns.Masque and ns.Masque.QueueRefresh then
                ns.Masque.QueueRefresh()
            end
        end
    end
end

function ArcAuras.ScanEquippedTrinkets()
    local result = {}
    for _, slot in ipairs(TRINKET_SLOTS) do
        local itemID, itemName, itemIcon = GetSlotItemInfo(slot.slotID)
        result[slot.slotID] = {
            slotID = slot.slotID,
            slotName = slot.name,
            itemID = itemID,
            itemName = itemName,
            itemIcon = itemIcon,
            isOnUse = itemID and IsItemOnUse(itemID),
        }
    end
    return result
end

-- Check if auto-track equipped trinkets is enabled
function ArcAuras.IsAutoTrackEquippedTrinketsEnabled()
    local db = GetDB()
    if not db then return true end  -- Default to enabled
    -- Handle nil (not set yet) as true (enabled by default)
    if db.autoTrackEquippedTrinkets == nil then
        return true
    end
    return db.autoTrackEquippedTrinkets
end

-- Set auto-track equipped trinkets
function ArcAuras.SetAutoTrackEquippedTrinkets(enabled)
    local db = GetDB()
    if not db then return end
    
    local wasEnabled = db.autoTrackEquippedTrinkets
    db.autoTrackEquippedTrinkets = enabled
    
    -- If disabling, remove ONLY auto-track slot frames (not manually added trinkets)
    if wasEnabled ~= false and not enabled then
        if db.trackedItems then
            local toRemove = {}
            for arcID, config in pairs(db.trackedItems) do
                -- Only remove if it was created by auto-track (has isAutoTrackSlot flag)
                if config.isAutoTrackSlot then
                    table.insert(toRemove, arcID)
                end
            end
            for _, arcID in ipairs(toRemove) do
                ArcAuras.RemoveTrackedItem(arcID)
            end
            if #toRemove > 0 then
                -- Invalidate caches
                InvalidateSettingsCache()
                InvalidateStackCache()
            end
        end
    -- If enabling, auto-add current trinkets based on slot settings
    elseif enabled and wasEnabled == false then
        ArcAuras.AutoAddTrinkets(nil, true)  -- nil = use onlyOnUseTrinkets setting, true = mark as auto-track
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PER-SLOT AUTO-TRACK MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if a specific slot is enabled for auto-tracking
function ArcAuras.IsAutoTrackSlotEnabled(slotID)
    local db = GetDB()
    if not db then return true end  -- Default to enabled
    if not db.autoTrackSlots then return true end
    -- Handle nil as true (enabled by default)
    if db.autoTrackSlots[slotID] == nil then
        return true
    end
    return db.autoTrackSlots[slotID]
end

-- Enable/disable auto-tracking for a specific slot
function ArcAuras.SetAutoTrackSlotEnabled(slotID, enabled)
    local db = GetDB()
    if not db then return end
    
    if not db.autoTrackSlots then
        db.autoTrackSlots = {}
    end
    
    local wasEnabled = db.autoTrackSlots[slotID]
    db.autoTrackSlots[slotID] = enabled
    
    local arcID = ArcAuras.MakeTrinketID(slotID)
    
    if enabled and wasEnabled == false then
        -- Slot was disabled, now enabled - add the frame if auto-track is on
        if ArcAuras.IsAutoTrackEquippedTrinketsEnabled() then
            local itemID = GetInventoryItemID("player", slotID)
            if itemID then
                -- Check on-use filter
                local onlyOnUse = db.onlyOnUseTrinkets
                if not onlyOnUse or IsItemOnUse(itemID) then
                    if not db.trackedItems or not db.trackedItems[arcID] then
                        ArcAuras.AddTrackedItem({
                            type = "trinket",
                            slotID = slotID,
                            enabled = true,
                            isAutoTrackSlot = true,
                        })
                    end
                end
            end
        end
    elseif not enabled and wasEnabled ~= false then
        -- Slot was enabled, now disabled - remove the auto-track frame
        if db.trackedItems and db.trackedItems[arcID] and db.trackedItems[arcID].isAutoTrackSlot then
            ArcAuras.RemoveTrackedItem(arcID)
        end
    end
    
    -- Invalidate caches
    InvalidateSettingsCache()
    InvalidateStackCache()
end

-- Get "only on-use trinkets" setting
function ArcAuras.IsOnlyOnUseTrinketsEnabled()
    local db = GetDB()
    if not db then return false end
    return db.onlyOnUseTrinkets or false
end

-- Set "only on-use trinkets" setting
function ArcAuras.SetOnlyOnUseTrinkets(enabled)
    local db = GetDB()
    if not db then return end
    
    local wasEnabled = db.onlyOnUseTrinkets
    db.onlyOnUseTrinkets = enabled
    
    -- If changed, refresh auto-track slots
    if enabled ~= wasEnabled and ArcAuras.IsAutoTrackEquippedTrinketsEnabled() then
        if enabled then
            -- Filter just got enabled - HIDE (not remove) passive trinkets
            for _, slot in ipairs(TRINKET_SLOTS) do
                local arcID = ArcAuras.MakeTrinketID(slot.slotID)
                local config = db.trackedItems and db.trackedItems[arcID]
                local frame = ArcAuras.frames[arcID]
                
                if config and config.isAutoTrackSlot and frame then
                    local itemID = GetInventoryItemID("player", slot.slotID)
                    if itemID and IsItemPassive(itemID) then
                        -- Hide the frame but keep trackedItem and position
                        ArcAuras.HideTrinketSlotFrame(arcID)
                    end
                end
            end
        else
            -- Filter disabled - SHOW hidden passive trinkets
            for _, slot in ipairs(TRINKET_SLOTS) do
                local arcID = ArcAuras.MakeTrinketID(slot.slotID)
                local config = db.trackedItems and db.trackedItems[arcID]
                local frame = ArcAuras.frames[arcID]
                
                if config and config.isAutoTrackSlot then
                    local itemID = GetInventoryItemID("player", slot.slotID)
                    if frame and frame._arcSlotEmpty and itemID then
                        -- Frame was hidden due to filter - restore it
                        ArcAuras.ShowTrinketSlotFrame(arcID)
                    elseif not frame and itemID and ArcAuras.IsAutoTrackSlotEnabled(slot.slotID) then
                        -- Frame doesn't exist (maybe was removed) - recreate it
                        local newFrame = ArcAuras.CreateFrame(arcID, config)
                        if newFrame then
                            ArcAuras.LoadFramePosition(arcID, newFrame)
                            newFrame:Show()
                        end
                    end
                end
            end
        end
        
        -- Invalidate caches
        InvalidateSettingsCache()
        InvalidateStackCache()
    end
end

-- Get list of trinket slots for options display
function ArcAuras.GetTrinketSlots()
    return TRINKET_SLOTS
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HIDE WHEN UNEQUIPPED (for item-based frames)
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if hideWhenUnequipped is enabled for an item
function ArcAuras.IsHideWhenUnequippedEnabled(arcID)
    local db = GetDB()
    if not db or not db.trackedItems or not db.trackedItems[arcID] then
        return false
    end
    return db.trackedItems[arcID].hideWhenUnequipped or false
end

-- Set hideWhenUnequipped for an item
function ArcAuras.SetHideWhenUnequipped(arcID, enabled)
    local db = GetDB()
    if not db or not db.trackedItems or not db.trackedItems[arcID] then
        return
    end
    
    local config = db.trackedItems[arcID]
    config.hideWhenUnequipped = enabled
    
    -- Apply immediately
    local frame = ArcAuras.frames[arcID]
    if frame and config.type == "item" and config.itemID then
        if enabled then
            -- Check if currently equipped
            if not IsItemEquipped(config.itemID) then
                ArcAuras.HideItemFrame(arcID)
            end
        else
            -- Setting disabled - show the frame if it was hidden
            if frame._arcHiddenUnequipped then
                ArcAuras.ShowItemFrame(arcID)
            end
        end
    end
end

-- Hide an item-based frame (when unequipped)
function ArcAuras.HideItemFrame(arcID)
    local frame = ArcAuras.frames[arcID]
    if not frame then return end
    
    -- Mark as hidden due to unequipped
    frame._arcHiddenUnequipped = true
    
    -- Save current group position before removing (same as HideTrinketSlotFrame)
    -- CRITICAL: Do NOT clear savedPositions - we need it to restore when item is re-equipped
    if ns.CDMGroups and ns.CDMGroups.groups then
        for groupName, group in pairs(ns.CDMGroups.groups) do
            if group.members and group.members[arcID] then
                local member = group.members[arcID]
                frame._arcSavedGroupName = groupName
                frame._arcSavedRow = member.row
                frame._arcSavedCol = member.col
                
                -- Remove from group tracking but PRESERVE savedPositions
                -- Pass skipSavePosition=true to prevent clearing savedPositions
                if group.RemoveMemberKeepFrame then
                    group:RemoveMemberKeepFrame(arcID)
                elseif group.RemoveMember then
                    group:RemoveMember(arcID, true)  -- true = skipSavePosition
                end
                
                if group.Layout then group:Layout() end
                break
            end
        end
        
        if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[arcID] then
            local freeData = ns.CDMGroups.freeIcons[arcID]
            frame._arcSavedFreeX = freeData.x
            frame._arcSavedFreeY = freeData.y
            frame._arcSavedFreeSize = freeData.iconSize
            frame._arcWasFreeIcon = true
            
            -- Remove from freeIcons tracking but PRESERVE savedPositions
            -- CRITICAL: ReleaseFreeIcon parameter is clearSaved - pass FALSE to keep savedPositions!
            if ns.CDMGroups.ReleaseFreeIcon then
                ns.CDMGroups.ReleaseFreeIcon(arcID, false)  -- false = DON'T clear saved position
            else
                -- Manual removal if ReleaseFreeIcon doesn't exist
                ns.CDMGroups.freeIcons[arcID] = nil
            end
        end
    end
    
    frame:Hide()
    frame:SetAlpha(0)
end

-- Show an item-based frame (when equipped)
function ArcAuras.ShowItemFrame(arcID)
    local frame = ArcAuras.frames[arcID]
    if not frame then return end
    
    frame._arcHiddenUnequipped = nil
    
    -- Update the icon
    local config = frame._arcConfig
    if config then
        ArcAuras.UpdateFrameIcon(frame, config)
        frame._arcStackStyleApplied = false
        InvalidateStackCache(arcID)
    end
    
    frame:Show()
    -- Apply proper state visuals (respects saved alpha settings)
    ArcAuras.ApplyInitialStateVisuals(arcID, frame)
    
    -- Restore to group or free position
    -- CRITICAL: Check CDMGroups.savedPositions FIRST - this is the authoritative source
    -- for the CURRENT spec's position. The frame._arcSaved* variables can be stale after spec change.
    if ns.CDMGroups then
        -- CRITICAL: Ensure savedPositions reference is correct for current spec
        -- The ns.CDMGroups.savedPositions reference may be stale after spec change
        if ns.CDMGroups.GetProfileSavedPositions then
            ns.CDMGroups.GetProfileSavedPositions()
        end
        
        local saved = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[arcID]
        
        if saved then
            -- Use savedPositions (authoritative for current spec)
            if saved.type == "group" and saved.target then
                local group = ns.CDMGroups.groups and ns.CDMGroups.groups[saved.target]
                if group then
                    local row = saved.row or 0
                    local col = saved.col or 0
                    
                    if group.AddMemberAtWithFrame then
                        group:AddMemberAtWithFrame(arcID, row, col, frame, nil)
                    elseif group.AddMemberAt then
                        group:AddMemberAt(arcID, row, col)
                    end
                    
                    if group.Layout then group:Layout() end
                    
                    if ns.Masque and ns.Masque.QueueRefresh then
                        ns.Masque.QueueRefresh()
                    end
                else
                    -- Group doesn't exist in current spec - use LoadFramePosition as fallback
                    ArcAuras.LoadFramePosition(arcID, frame)
                end
            elseif saved.type == "free" then
                local x = saved.x or 0
                local y = saved.y or 0
                local size = saved.iconSize or 36
                ns.CDMGroups.TrackFreeIcon(arcID, x, y, size, frame)
            else
                -- Unknown saved type - use LoadFramePosition
                ArcAuras.LoadFramePosition(arcID, frame)
            end
        elseif frame._arcWasFreeIcon then
            -- Fallback: use frame's temporary saved position (same spec hide/show)
            local x = frame._arcSavedFreeX or 0
            local y = frame._arcSavedFreeY or 0
            local size = frame._arcSavedFreeSize or 36
            ns.CDMGroups.TrackFreeIcon(arcID, x, y, size, frame)
            
            frame._arcWasFreeIcon = nil
            frame._arcSavedFreeX = nil
            frame._arcSavedFreeY = nil
            frame._arcSavedFreeSize = nil
        elseif frame._arcSavedGroupName then
            -- Fallback: use frame's temporary saved group (same spec hide/show)
            local groupName = frame._arcSavedGroupName
            local row = frame._arcSavedRow or 0
            local col = frame._arcSavedCol or 0
            local group = ns.CDMGroups.groups and ns.CDMGroups.groups[groupName]
            
            if group then
                if group.AddMemberAtWithFrame then
                    group:AddMemberAtWithFrame(arcID, row, col, frame, nil)
                elseif group.AddMemberAt then
                    group:AddMemberAt(arcID, row, col)
                end
                
                if group.Layout then group:Layout() end
                
                if ns.Masque and ns.Masque.QueueRefresh then
                    ns.Masque.QueueRefresh()
                end
            end
            
            frame._arcSavedGroupName = nil
            frame._arcSavedRow = nil
            frame._arcSavedCol = nil
        else
            -- No saved position - use default
            ArcAuras.LoadFramePosition(arcID, frame)
        end
    end
    
    -- Clear temporary saved position flags (already used or not needed)
    frame._arcWasFreeIcon = nil
    frame._arcSavedFreeX = nil
    frame._arcSavedFreeY = nil
    frame._arcSavedFreeSize = nil
    frame._arcSavedGroupName = nil
    frame._arcSavedRow = nil
    frame._arcSavedCol = nil
end

-- Check all item-based frames for equipped state and hide/show accordingly
function ArcAuras.UpdateItemFrameVisibility()
    local db = GetDB()
    if not db or not db.trackedItems then return end
    
    for arcID, config in pairs(db.trackedItems) do
        if config.type == "item" and config.itemID and config.hideWhenUnequipped then
            local frame = ArcAuras.frames[arcID]
            if frame then
                local isEquipped = IsItemEquipped(config.itemID)
                
                if isEquipped and frame._arcHiddenUnequipped then
                    -- Item is now equipped - show the frame
                    ArcAuras.ShowItemFrame(arcID)
                elseif not isEquipped and not frame._arcHiddenUnequipped then
                    -- Item is no longer equipped - hide the frame
                    ArcAuras.HideItemFrame(arcID)
                end
            end
        end
    end
end

-- Auto-add equipped on-use trinkets
-- @param onlyOnUse: boolean - if true, only add trinkets with on-use effects
--                            if nil, use the onlyOnUseTrinkets setting
-- @param asSlotTracker: boolean - if true, create slot-based frames (arc_trinket_13)
--                                 if false/nil, create item-based frames (arc_item_12345)
-- @return: number of trinkets added
function ArcAuras.AutoAddTrinkets(onlyOnUse, asSlotTracker)
    local db = GetDB()
    if not db then return 0 end
    
    -- If onlyOnUse is nil, use the setting
    local onlyOnUseSetting = db.onlyOnUseTrinkets
    if onlyOnUse == nil then
        onlyOnUse = onlyOnUseSetting
    end
    
    local trinkets = ArcAuras.ScanEquippedTrinkets()
    local added = 0
    
    for slotID, info in pairs(trinkets) do
        if info.itemID then
            -- Check if slot is enabled for auto-tracking (only for slot trackers)
            local slotEnabled = true
            if asSlotTracker then
                slotEnabled = ArcAuras.IsAutoTrackSlotEnabled(slotID)
            end
            
            if not slotEnabled then
                -- Skip this slot
            else
                -- For slot trackers, ALWAYS create the frame (for position preservation)
                -- but hide if on-use filter is on and trinket is passive
                if asSlotTracker then
                    local arcID = ArcAuras.MakeTrinketID(slotID)
                    if not db.trackedItems or not db.trackedItems[arcID] then
                        local success = ArcAuras.AddTrackedItem({
                            type = "trinket",
                            slotID = slotID,
                            enabled = true,
                            isAutoTrackSlot = true,
                        })
                        if success then
                            added = added + 1
                            
                            -- If on-use filter is on and trinket is passive, hide it
                            if onlyOnUseSetting and not info.isOnUse then
                                local frame = ArcAuras.frames[arcID]
                                if frame then
                                    ArcAuras.HideTrinketSlotFrame(arcID)
                                end
                            end
                        end
                    end
                else
                    -- ITEM-BASED: Only create if on-use (or filter not set)
                    if not onlyOnUse or info.isOnUse then
                        local arcID = ArcAuras.MakeItemID(info.itemID)
                        if not db.trackedItems or not db.trackedItems[arcID] then
                            local success = ArcAuras.AddTrackedItem({
                                type = "item",
                                itemID = info.itemID,
                                enabled = true,
                            })
                            if success then
                                added = added + 1
                            end
                        end
                    end
                end
            end
        end
    end
    
    return added
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UPDATE LOOP CONTROL
-- ═══════════════════════════════════════════════════════════════════════════

function ArcAuras.StartUpdateLoop()
    if ArcAuras.updateTicker then return end
    
    local db = GetDB()
    local rate = (db and db.updateRate) or UPDATE_RATE
    
    ArcAuras.updateTicker = C_Timer.NewTicker(rate, OnArcAurasUpdate)
end

function ArcAuras.StopUpdateLoop()
    if ArcAuras.updateTicker then
        ArcAuras.updateTicker:Cancel()
        ArcAuras.updateTicker = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ENABLE/DISABLE
-- ═══════════════════════════════════════════════════════════════════════════

function ArcAuras.Enable()
    if ArcAuras.isEnabled then return end
    ArcAuras.isEnabled = true
    
    local db = GetDB()
    if not db then return end
    
    db.enabled = true
    local onlyOnUse = db.onlyOnUseTrinkets
    
    for arcID, config in pairs(db.trackedItems or {}) do
        if config.enabled then
            local frame = ArcAuras.CreateFrame(arcID, config)
            if frame then
                local shouldHide = false
                
                -- For trinket slot trackers, check visibility conditions
                if config.type == "trinket" and config.slotID then
                    local itemID = GetInventoryItemID("player", config.slotID)
                    
                    if not itemID then
                        -- Slot is empty
                        shouldHide = true
                        frame._arcSlotEmpty = true
                    elseif config.isAutoTrackSlot and onlyOnUse and IsItemPassive(itemID) then
                        -- Passive trinket with on-use filter
                        shouldHide = true
                        frame._arcSlotEmpty = true
                    end
                    
                -- For item-based frames, check hideWhenUnequipped
                elseif config.type == "item" and config.itemID and config.hideWhenUnequipped then
                    if not IsItemEquipped(config.itemID) then
                        shouldHide = true
                        frame._arcHiddenUnequipped = true
                    end
                end
                
                if shouldHide then
                    frame:Hide()
                    frame:SetAlpha(0)
                else
                    frame:Show()
                    -- Apply proper state visuals (respects saved alpha settings)
                    ArcAuras.ApplyInitialStateVisuals(arcID, frame)
                end
            end
        end
    end
    
    ArcAuras.StartUpdateLoop()
end

function ArcAuras.Disable()
    if not ArcAuras.isEnabled then return end
    ArcAuras.isEnabled = false
    
    local db = GetDB()
    if db then db.enabled = false end
    
    ArcAuras.StopUpdateLoop()
    
    for arcID, frame in pairs(ArcAuras.frames) do
        frame:Hide()
    end
end

function ArcAuras.Toggle()
    if ArcAuras.isEnabled then
        ArcAuras.Disable()
    else
        ArcAuras.Enable()
    end
end

function ArcAuras.IsEnabled()
    return ArcAuras.isEnabled
end

-- Refresh all frames (called after spec change)
function ArcAuras.RefreshAllFrames()
    if not ArcAuras.isEnabled then return end
    
    local db = GetDB()
    if not db then return end
    
    -- Clear all caches
    InvalidateSettingsCache()
    InvalidateStackCache()
    
    -- Destroy all existing frames
    for arcID, frame in pairs(ArcAuras.frames) do
        if ns.CDMGroups and ns.CDMGroups.UnregisterExternalFrame then
            ns.CDMGroups.UnregisterExternalFrame(arcID)
        end
        
        -- Stop glows
        local LCG = GetLCG()
        if LCG then
            pcall(LCG.PixelGlow_Stop, frame._arcGlowAnchor or frame)
            pcall(LCG.PixelGlow_Stop, frame)
            pcall(LCG.AutoCastGlow_Stop, frame._arcGlowAnchor or frame)
            pcall(LCG.ButtonGlow_Stop, frame._arcGlowAnchor or frame)
            pcall(LCG.ProcGlow_Stop, frame._arcGlowAnchor or frame)
        end
        
        frame:Hide()
        frame:SetParent(nil)
    end
    wipe(ArcAuras.frames)
    
    -- Get on-use filter setting
    local onlyOnUse = db.onlyOnUseTrinkets
    
    -- Recreate all enabled tracked items
    for arcID, config in pairs(db.trackedItems or {}) do
        if config.enabled then
            local frame = ArcAuras.CreateFrame(arcID, config)
            if frame then
                local shouldHide = false
                
                -- For trinket slot trackers, check visibility conditions
                if config.type == "trinket" and config.slotID then
                    local itemID = GetInventoryItemID("player", config.slotID)
                    
                    if not itemID then
                        -- Slot is empty
                        shouldHide = true
                        frame._arcSlotEmpty = true
                    elseif config.isAutoTrackSlot and onlyOnUse and IsItemPassive(itemID) then
                        -- Passive trinket with on-use filter
                        shouldHide = true
                        frame._arcSlotEmpty = true
                    end
                    
                -- For item-based frames, check hideWhenUnequipped
                elseif config.type == "item" and config.itemID and config.hideWhenUnequipped then
                    if not IsItemEquipped(config.itemID) then
                        shouldHide = true
                        frame._arcHiddenUnequipped = true
                    end
                end
                
                if shouldHide then
                    frame:Hide()
                    frame:SetAlpha(0)
                else
                    frame:Show()
                    -- Apply proper state visuals (respects saved alpha settings)
                    ArcAuras.ApplyInitialStateVisuals(arcID, frame)
                end
            end
        end
    end
    
    -- Invalidate caches
    if ns.CDMEnhanceOptions and ns.CDMEnhanceOptions.InvalidateCache then
        ns.CDMEnhanceOptions.InvalidateCache()
    end
    if ns.ArcAurasOptions and ns.ArcAurasOptions.InvalidateCache then
        ns.ArcAurasOptions.InvalidateCache()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FORCE SHOW ALL FRAMES (without resetting positions)
-- Used by the Refresh button to just show frames at their saved positions
-- ═══════════════════════════════════════════════════════════════════════════
function ArcAuras.ForceShowAllFrames()
    if not ArcAuras.isEnabled then return end
    
    local showCount = 0
    
    for arcID, frame in pairs(ArcAuras.frames) do
        if frame then
            -- Show the frame with proper state visuals (respects saved alpha settings)
            frame:Show()
            ArcAuras.ApplyInitialStateVisuals(arcID, frame)
            showCount = showCount + 1
            
            -- If in CDMGroups, restore to saved position
            if ns.CDMGroups and ns.CDMGroups.savedPositions then
                local saved = ns.CDMGroups.savedPositions[arcID]
                if saved then
                    if saved.type == "free" then
                        -- Restore free position
                        frame:ClearAllPoints()
                        frame:SetPoint("CENTER", UIParent, "CENTER", saved.x or 0, saved.y or 0)
                        frame:SetParent(UIParent)
                        
                        -- Ensure tracked as free icon
                        if ns.CDMGroups.TrackFreeIcon then
                            ns.CDMGroups.TrackFreeIcon(arcID, saved.x or 0, saved.y or 0, saved.iconSize or 36, frame)
                        end
                    elseif saved.type == "group" and saved.target then
                        -- Ensure in group
                        local targetGroup = ns.CDMGroups.groups and ns.CDMGroups.groups[saved.target]
                        if targetGroup and not targetGroup.members[arcID] then
                            if ns.CDMGroups.RegisterExternalFrame then
                                ns.CDMGroups.RegisterExternalFrame(arcID, frame, "cooldown", saved.target)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Trigger layout updates
    if ns.CDMGroups and ns.CDMGroups.groups then
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.Layout then group:Layout() end
        end
    end
    
    return showCount
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CDMENHANCE INTEGRATION
-- Register Arc Auras frames with the CDMEnhance catalog system
-- ═══════════════════════════════════════════════════════════════════════════

-- Get all Arc Auras icons for catalog display
function ArcAuras.GetIcons()
    local result = {}
    
    local db = GetDB()
    if not db or not db.trackedItems then return result end
    
    for arcID, config in pairs(db.trackedItems) do
        if config.enabled then
            local frame = ArcAuras.frames[arcID]
            local name, icon = nil, nil
            local arcType, id = ArcAuras.ParseArcID(arcID)
            
            if arcType == "trinket" then
                local itemID = GetInventoryItemID("player", id)
                if itemID then
                    name, icon = GetItemNameAndIcon(itemID)
                    icon = icon or GetInventoryItemTexture("player", id)
                end
                name = name or ("Trinket Slot " .. id)
            elseif arcType == "item" then
                name, icon = GetItemNameAndIcon(config.itemID)
                name = name or ("Item " .. config.itemID)
            end
            
            result[arcID] = {
                cooldownID = arcID,
                arcID = arcID,
                arcType = arcType,
                itemID = config.itemID or (arcType == "trinket" and GetInventoryItemID("player", id)),
                slotID = arcType == "trinket" and id or nil,
                name = name or "Unknown",
                icon = icon or 134400,
                isArcAura = true,
                viewerName = "ArcAurasViewer",
                hasCustomPos = true,
                frame = frame,
            }
        end
    end
    
    return result
end

-- Register a single frame with CDMEnhance (call when frame is created)
function ArcAuras.RegisterWithCDMEnhance(arcID, frame)
    if not ns.CDMEnhance then return end
    
    -- Mark frame as enhanced
    frame._arcEnhanced = true
    frame._arcIsArcAura = true
    
    -- Apply icon style if CDMEnhance supports it
    if ns.CDMEnhance.ApplyIconStyle then
        C_Timer.After(0.1, function()
            if ArcAuras.frames[arcID] then
                ns.CDMEnhance.ApplyIconStyle(frame, arcID)
                -- Also apply our cooldown settings after CDMEnhance styling
                ArcAuras.ApplySettingsToFrame(arcID, frame)
                
                -- CRITICAL: Apply initial state visuals (alpha, desat, glow)
                -- Without this, frames show at default alpha until OnArcAurasUpdate runs
                ArcAuras.ApplyInitialStateVisuals(arcID, frame)
            end
        end)
    else
        -- CDMEnhance.ApplyIconStyle not available, just apply our settings
        C_Timer.After(0.1, function()
            if ArcAuras.frames[arcID] then
                ArcAuras.ApplySettingsToFrame(arcID, frame)
                
                -- CRITICAL: Apply initial state visuals (alpha, desat, glow)
                ArcAuras.ApplyInitialStateVisuals(arcID, frame)
            end
        end)
    end
end

-- Apply initial state visuals (alpha, desaturation) for a frame
-- Called after frame creation to ensure correct visuals before first OnArcAurasUpdate tick
function ArcAuras.ApplyInitialStateVisuals(arcID, frame)
    if not frame then
        frame = ArcAuras.frames[arcID]
    end
    if not frame then return end
    
    local config = frame._arcConfig
    if not config then return end
    
    -- Clear optimization caches to ensure values are applied
    frame._lastAppliedAlpha = nil
    frame._lastVisualState = nil
    frame._cachedStateVisuals = nil
    
    -- Get settings
    local settings = ArcAuras.GetCachedSettings(arcID)
    if not settings then return end
    
    -- Get state visuals
    local stateVisuals
    if ns.CDMEnhance and ns.CDMEnhance.GetEffectiveStateVisuals then
        stateVisuals = ns.CDMEnhance.GetEffectiveStateVisuals(settings)
    end
    
    -- Fallback to raw settings
    local csv = settings and settings.cooldownStateVisuals or {}
    local cs = csv.cooldownState or {}
    local rs = csv.readyState or {}
    
    -- Determine cooldown state
    local isOnCooldown = frame.Cooldown and frame.Cooldown:IsVisible()
    
    local iconTex = frame.Icon
    
    if isOnCooldown then
        -- ON COOLDOWN: Apply cooldown alpha and desaturation
        local cooldownAlpha = cs.alpha or (stateVisuals and stateVisuals.cooldownAlpha) or 1.0
        
        -- OPTIONS PANEL PREVIEW: If alpha is 0, show at 0.35 so user can see the icon while editing
        if cooldownAlpha <= 0 then
            if ns.CDMEnhance and ns.CDMEnhance.IsOptionsPanelOpen and ns.CDMEnhance.IsOptionsPanelOpen() then
                cooldownAlpha = 0.35
            end
        end
        
        frame:SetAlpha(cooldownAlpha)
        frame._lastAppliedAlpha = cooldownAlpha
        
        -- Desaturation
        local noDesaturate = (stateVisuals and stateVisuals.noDesaturate) or (cs.noDesaturate == true)
        if iconTex then
            if not noDesaturate then
                if iconTex.SetDesaturation then
                    iconTex:SetDesaturation(1)
                elseif iconTex.SetDesaturated then
                    iconTex:SetDesaturated(true)
                end
            else
                if iconTex.SetDesaturation then
                    iconTex:SetDesaturation(0)
                elseif iconTex.SetDesaturated then
                    iconTex:SetDesaturated(false)
                end
            end
        end
    else
        -- READY: Apply ready alpha
        local readyAlpha = rs.alpha or (stateVisuals and stateVisuals.readyAlpha) or 1.0
        
        -- OPTIONS PANEL PREVIEW: If alpha is 0, show at 0.35 so user can see the icon while editing
        if readyAlpha <= 0 then
            if ns.CDMEnhance and ns.CDMEnhance.IsOptionsPanelOpen and ns.CDMEnhance.IsOptionsPanelOpen() then
                readyAlpha = 0.35
            end
        end
        
        frame:SetAlpha(readyAlpha)
        frame._lastAppliedAlpha = readyAlpha
        
        -- Ready state: no desaturation
        if iconTex then
            if iconTex.SetDesaturation then
                iconTex:SetDesaturation(0)
            elseif iconTex.SetDesaturated then
                iconTex:SetDesaturated(false)
            end
        end
    end
    
    frame._lastVisualState = isOnCooldown and "cooldown" or "ready"
end

-- Refresh settings for a single Arc Aura frame
-- Called by CDMEnhance when settings change (via options panel)
function ArcAuras.RefreshFrameSettings(arcID)
    local frame = ArcAuras.frames[arcID]
    if not frame then return end
    
    -- Invalidate caches
    InvalidateSettingsCache(arcID)
    frame._cachedStateVisuals = nil  -- Force refresh of state visuals
    frame._arcStackStyleApplied = false  -- Re-apply stack text style
    
    -- CRITICAL: Clear visual state caches to force immediate re-application
    -- Without this, the optimization checks in OnArcAurasUpdate may skip applying new values
    frame._lastAppliedAlpha = nil  -- Force alpha re-application
    frame._lastVisualState = nil   -- Force visual state re-evaluation
    
    -- Apply settings from CDMEnhance cascade
    ArcAuras.ApplySettingsToFrame(arcID, frame)
    
    -- Also apply CDMEnhance icon style if available
    if ns.CDMEnhance and ns.CDMEnhance.ApplyIconStyle then
        ns.CDMEnhance.ApplyIconStyle(frame, arcID)
    end
    
    -- Immediately apply stack text style (don't wait for OnUpdate)
    if frame._arcStackText then
        ApplyStackTextStyle(frame, frame._arcStackText)
        frame._arcStackStyleApplied = true
    end
    
    -- CRITICAL: Apply state visuals immediately (don't wait for OnArcAurasUpdate tick)
    -- This ensures alpha/desat changes are visible instantly when settings change
    ArcAuras.ApplyInitialStateVisuals(arcID, frame)
end

-- Refresh settings for all Arc Aura frames
function ArcAuras.RefreshAllSettings()
    -- Clear all caches
    InvalidateSettingsCache()
    
    for arcID, frame in pairs(ArcAuras.frames) do
        ArcAuras.RefreshFrameSettings(arcID)
    end
end

-- Refresh Masque registration state for all frames
-- Called when Masque enabled setting changes
function ArcAuras.RefreshMasqueState()
    local masqueEnabled = ns.Masque and ns.Masque.IsEnabled and ns.Masque.IsEnabled()
    
    for arcID, frame in pairs(ArcAuras.frames) do
        if masqueEnabled then
            -- Masque is now enabled - register if not already
            if not frame._arcAuraMasqueRegistered then
                RegisterWithMasque(frame)
            end
            -- Reset icon texture to default 1:1 for Masque to control
            if frame.Icon and frame.Icon.SetTexCoord then
                frame.Icon:SetTexCoord(0, 1, 0, 1)
            end
        else
            -- Masque is now disabled - unregister if registered
            if frame._arcAuraMasqueRegistered then
                UnregisterFromMasque(frame)
                -- Reset icon texture to default
                if frame.Icon and frame.Icon.SetTexCoord then
                    frame.Icon:SetTexCoord(0, 1, 0, 1)
                end
            end
        end
        
        -- Refresh settings regardless
        ArcAuras.RefreshFrameSettings(arcID)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Track initialization attempts for debugging
local initAttempts = 0

function ArcAuras.Initialize()
    if ArcAuras.initialized then return end
    
    initAttempts = initAttempts + 1
    
    local db = GetDB()
    if not db then
        if initAttempts < 10 then
            -- Keep trying for up to 10 seconds
            C_Timer.After(1, ArcAuras.Initialize)
        else
            print("|cffFF4444[Arc Auras]|r ERROR: Database failed to initialize after 10 attempts")
        end
        return
    end
    
    ArcAuras.initialized = true
    
    -- Debug: Report tracked items found
    local itemCount = 0
    if db.trackedItems then
        for _ in pairs(db.trackedItems) do itemCount = itemCount + 1 end
    end
    if itemCount > 0 then
        -- Silent load - items found, everything is good
    end
    
    -- Enable if saved as enabled
    if db.enabled then
        ArcAuras.Enable()
        
        -- Auto-add equipped trinkets if auto-track is enabled
        -- NOTE: Enable() already loaded existing trackedItems, so AutoAddTrinkets
        -- will only add slots that don't already have frames
        if ArcAuras.IsAutoTrackEquippedTrinketsEnabled() then
            -- Delay slightly to ensure item data is loaded
            C_Timer.After(0.5, function()
                -- nil = use onlyOnUseTrinkets setting, true = create slot trackers (arc_trinket_13)
                ArcAuras.AutoAddTrinkets(nil, true)
            end)
        end
        
        -- CRITICAL: Delayed refresh pass to apply state visuals (alpha, desat, glow)
        -- This ensures all settings are applied after frames are fully created and CDMEnhance is ready
        -- Same effect as opening options panel - forces a full visual refresh
        C_Timer.After(1.0, function()
            if ArcAuras.RefreshAllSettings then
                ArcAuras.RefreshAllSettings()
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT HANDLING
-- ═══════════════════════════════════════════════════════════════════════════

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")           -- Fires when bag contents settled (new items, tooltip ready)
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")       -- For item data loading
eventFrame:RegisterEvent("PLAYER_EQUIPED_SPELLS_CHANGED") -- Fires when item charges change (Healthstone!)

-- Debounce for PLAYER_EQUIPED_SPELLS_CHANGED (fires 12 times at once)
local lastEquipedSpellsTime = 0

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        -- Enable DB caching now that SavedVariables are loaded
        C_Timer.After(0.1, function()
            ArcAuras.EnableDBCache()
        end)
        -- Then initialize
        C_Timer.After(2, function()
            ArcAuras.Initialize()
        end)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local slot = arg1
        if slot == 13 or slot == 14 then
            local arcID = ArcAuras.MakeTrinketID(slot)
            local frame = ArcAuras.frames[arcID]
            local itemID = GetInventoryItemID("player", slot)
            local db = GetDB()
            
            if frame then
                local config = frame._arcConfig
                local savedConfig = db and db.trackedItems and db.trackedItems[arcID]
                
                if itemID then
                    -- Trinket equipped - check on-use filter for auto-track slots
                    if savedConfig and savedConfig.isAutoTrackSlot then
                        local onlyOnUse = db and db.onlyOnUseTrinkets
                        if onlyOnUse and IsItemPassive(itemID) then
                            -- Passive trinket with on-use filter - hide it (keep position)
                            ArcAuras.HideTrinketSlotFrame(arcID)
                            -- Update icon even though hidden (for when filter is disabled)
                            ArcAuras.UpdateFrameIcon(frame, config)
                            -- Also check item-based frames that depend on equipped state
                            ArcAuras.UpdateItemFrameVisibility()
                            return
                        end
                    end
                    
                    -- Show frame and update icon
                    if frame._arcSlotEmpty then
                        -- Frame was hidden due to empty slot or filter - restore it
                        ArcAuras.ShowTrinketSlotFrame(arcID)
                    else
                        -- Just update the icon
                        ArcAuras.UpdateFrameIcon(frame, config)
                        frame._arcStackStyleApplied = false
                        InvalidateStackCache(arcID)
                    end
                else
                    -- Slot is empty - hide the frame and remove from group
                    ArcAuras.HideTrinketSlotFrame(arcID)
                end
            elseif ArcAuras.IsAutoTrackEquippedTrinketsEnabled() and ArcAuras.isEnabled then
                -- Auto-track enabled but no frame exists - check if we should create it
                if itemID then
                    -- Check if slot is enabled for auto-tracking
                    if ArcAuras.IsAutoTrackSlotEnabled(slot) then
                        local onlyOnUse = db and db.onlyOnUseTrinkets
                        local isPassive = IsItemPassive(itemID)
                        
                        -- ALWAYS create the auto-track slot frame (so position is preserved)
                        local success = ArcAuras.AddTrackedItem({
                            type = "trinket",
                            slotID = slot,
                            enabled = true,
                            isAutoTrackSlot = true,
                        })
                        
                        -- If passive and on-use filter is on, hide immediately
                        if success and onlyOnUse and isPassive then
                            local newFrame = ArcAuras.frames[arcID]
                            if newFrame then
                                ArcAuras.HideTrinketSlotFrame(arcID)
                            end
                        end
                    end
                end
            end
            
            -- Also check item-based frames that depend on equipped state
            ArcAuras.UpdateItemFrameVisibility()
        end
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        -- Item data loaded - update any item-type frames that match this itemID
        local itemID = arg1
        if itemID then
            for arcID, frame in pairs(ArcAuras.frames) do
                local config = frame._arcConfig
                if config and config.type == "item" and config.itemID == itemID then
                    ArcAuras.UpdateFrameIcon(frame, config)
                end
            end
        end
    elseif event == "BAG_UPDATE_DELAYED" then
        -- Bag contents settled - invalidate stack caches for new/changed items
        InvalidateStackCache()
    elseif event == "PLAYER_EQUIPED_SPELLS_CHANGED" then
        -- Fires 12 times at once - debounce to only process once
        local now = GetTime()
        if now - lastEquipedSpellsTime > 0.1 then
            lastEquipedSpellsTime = now
            -- Item spell charges changed (Healthstone!) - invalidate stack cache
            InvalidateStackCache()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        -- Debounce: Both events can fire during spec change, only refresh once
        if not ArcAuras._specChangeRefreshPending then
            ArcAuras._specChangeRefreshPending = true
            -- Wait for CDMGroups to fully load the new spec
            -- CDMGroups does: Reconcile at ~1.0s, FOLLOWUP_SWEEP_2 at ~2.5s
            -- We must run AFTER ForceRepositionAllFrames completes (at ~2.5s)
            C_Timer.After(3.0, function()
                ArcAuras._specChangeRefreshPending = false
                ArcAuras.RefreshAllSettings()
                
                -- ═══════════════════════════════════════════════════════════════════════════
                -- APPLY ON-USE FILTER FIRST: Hide passive trinkets if filter is enabled
                -- Must run BEFORE CDMGroups registration to prevent showing hidden frames
                -- ═══════════════════════════════════════════════════════════════════════════
                local hiddenByFilter = {}
                local filterEnabled = ArcAuras.isEnabled and ArcAuras.IsOnlyOnUseTrinketsEnabled()
                
                if filterEnabled then
                    for _, slot in ipairs(TRINKET_SLOTS) do
                        local arcID = ArcAuras.MakeTrinketID(slot.slotID)
                        local frame = ArcAuras.frames[arcID]
                        local itemID = GetInventoryItemID("player", slot.slotID)
                        local isPassive = itemID and IsItemPassive(itemID)
                        
                        if frame then
                            if itemID and isPassive then
                                -- Hide passive trinket (removes from group, hides frame)
                                ArcAuras.HideTrinketSlotFrame(arcID)
                                hiddenByFilter[arcID] = true
                            end
                        end
                    end
                end
                
                -- ═══════════════════════════════════════════════════════════════════════════
                -- APPLY HIDE-WHEN-UNEQUIPPED: Show/hide item-based frames based on equipped state
                -- Must run BEFORE CDMGroups registration to prevent showing hidden frames
                -- ═══════════════════════════════════════════════════════════════════════════
                if ArcAuras.isEnabled then
                    -- Check visibility for all item-based frames with hideWhenUnequipped
                    local db = GetDB()
                    if db and db.trackedItems then
                        for arcID, config in pairs(db.trackedItems) do
                            if config.type == "item" and config.itemID and config.hideWhenUnequipped then
                                local frame = ArcAuras.frames[arcID]
                                if frame then
                                    local isEquipped = IsItemEquipped(config.itemID)
                                    
                                    if isEquipped then
                                        -- Item is equipped - ensure frame is shown
                                        frame._arcHiddenUnequipped = nil
                                        frame:Show()
                                        frame:SetAlpha(1)
                                        ArcAuras.ApplyInitialStateVisuals(arcID, frame)
                                    else
                                        -- Item is not equipped - hide the frame AND remove from group
                                        -- Must remove from group so Layout() doesn't re-show it
                                        frame._arcHiddenUnequipped = true
                                        hiddenByFilter[arcID] = true
                                        
                                        -- Remove from any group it might be in
                                        if ns.CDMGroups and ns.CDMGroups.groups then
                                            for groupName, group in pairs(ns.CDMGroups.groups) do
                                                if group.members and group.members[arcID] then
                                                    -- Save position before removing
                                                    local member = group.members[arcID]
                                                    frame._arcSavedGroupName = groupName
                                                    frame._arcSavedRow = member.row
                                                    frame._arcSavedCol = member.col
                                                    
                                                    -- Remove from group (but keep frame reference for later restore)
                                                    group.members[arcID] = nil
                                                    break
                                                end
                                            end
                                            
                                            -- Also check/clear from freeIcons
                                            if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[arcID] then
                                                local freeData = ns.CDMGroups.freeIcons[arcID]
                                                frame._arcSavedFreeX = freeData.x
                                                frame._arcSavedFreeY = freeData.y
                                                frame._arcSavedFreeSize = freeData.iconSize
                                                frame._arcWasFreeIcon = true
                                                ns.CDMGroups.freeIcons[arcID] = nil
                                            end
                                        end
                                        
                                        frame:Hide()
                                        frame:SetAlpha(0)
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- ═══════════════════════════════════════════════════════════════════════════
                -- Re-register Arc Auras frames with CDMGroups after spec change
                -- FORCE re-registration regardless of current state - CDMGroups may have
                -- stale member entries after spec change that prevent proper drag/positioning
                -- ═══════════════════════════════════════════════════════════════════════════
                if ns.CDMGroups and ArcAuras.isEnabled then
                    -- CRITICAL: Ensure savedPositions reference is correct for current spec
                    -- The ns.CDMGroups.savedPositions reference may be stale after spec change
                    -- GetProfileSavedPositions syncs it to the current spec's profile data
                    if ns.CDMGroups.GetProfileSavedPositions then
                        ns.CDMGroups.GetProfileSavedPositions()
                    end
                    
                    local registeredCount = 0
                    for arcID, frame in pairs(ArcAuras.frames) do
                        -- Skip frames hidden by filters
                        if not hiddenByFilter[arcID] and frame and frame:IsShown() then
                            -- Check if CDMGroups has a saved position for this arc aura
                            local hasSavedPosition = ns.CDMGroups.savedPositions and ns.CDMGroups.savedPositions[arcID]
                            
                            if hasSavedPosition then
                                local saved = ns.CDMGroups.savedPositions[arcID]
                                if saved.type == "group" and saved.target then
                                    local targetGroup = ns.CDMGroups.groups and ns.CDMGroups.groups[saved.target]
                                    if targetGroup then
                                        -- FORCE re-registration: Remove stale entry first, then register fresh
                                        -- This ensures hooks and member.frame are properly set up
                                        if targetGroup.members and targetGroup.members[arcID] then
                                            -- Clear stale member entry
                                            targetGroup.members[arcID] = nil
                                        end
                                        
                                        -- Register with fresh state
                                        if ns.CDMGroups.RegisterExternalFrame then
                                            ns.CDMGroups.RegisterExternalFrame(arcID, frame, "cooldown", saved.target)
                                            registeredCount = registeredCount + 1
                                        end
                                    end
                                elseif saved.type == "free" then
                                    -- Free icon - re-track to ensure proper setup
                                    if ns.CDMGroups.freeIcons and ns.CDMGroups.freeIcons[arcID] then
                                        ns.CDMGroups.freeIcons[arcID] = nil
                                    end
                                    if ns.CDMGroups.TrackFreeIcon then
                                        ns.CDMGroups.TrackFreeIcon(arcID, saved.x or 0, saved.y or 0, saved.iconSize or 36, frame)
                                        registeredCount = registeredCount + 1
                                    end
                                end
                            else
                                -- No saved position for new spec - register as new (will go to default group)
                                if ns.CDMGroups.RegisterExternalFrame then
                                    ns.CDMGroups.RegisterExternalFrame(arcID, frame, "cooldown", "Essential")
                                    registeredCount = registeredCount + 1
                                end
                            end
                        end
                    end
                    
                    -- Always layout all groups after spec change to ensure proper positioning
                    if ns.CDMGroups.groups then
                        for _, group in pairs(ns.CDMGroups.groups) do
                            if group.Layout then group:Layout() end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SLASH COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

SLASH_ARCAURAS1 = "/arcauras"
SlashCmdList["ARCAURAS"] = function(msg)
    local cmd = msg:lower():trim()
    
    if cmd == "" then
        if ns.ArcAurasOptions and ns.ArcAurasOptions.OpenPanel then
            ns.ArcAurasOptions.OpenPanel()
        else
            print("|cff00CCFF[Arc Auras]|r Commands: enable, disable, toggle, scan, unlock, lock, help")
        end
    elseif cmd == "enable" or cmd == "on" then
        ArcAuras.Enable()
        print("|cff00CCFF[Arc Auras]|r Enabled")
    elseif cmd == "disable" or cmd == "off" then
        ArcAuras.Disable()
        print("|cff00CCFF[Arc Auras]|r Disabled")
    elseif cmd == "toggle" then
        ArcAuras.Toggle()
        print("|cff00CCFF[Arc Auras]|r " .. (ArcAuras.isEnabled and "Enabled" or "Disabled"))
    elseif cmd == "scan" then
        local trinkets = ArcAuras.ScanEquippedTrinkets()
        print("|cff00CCFF[Arc Auras]|r Equipped Trinkets:")
        for slotID, info in pairs(trinkets) do
            if info.itemID then
                local onUse = info.isOnUse and "|cff00FF00On-Use|r" or "|cff888888Passive|r"
                print(string.format("  %s: %s (%s)", info.slotName, info.itemName or "Unknown", onUse))
            else
                print(string.format("  %s: (empty)", info.slotName))
            end
        end
    elseif cmd == "unlock" then
        for _, frame in pairs(ArcAuras.frames) do
            frame._isDraggable = true
            frame:SetBackdropBorderColor(0, 1, 0, 1)
        end
        print("|cff00CCFF[Arc Auras]|r Frames unlocked")
    elseif cmd == "lock" then
        for _, frame in pairs(ArcAuras.frames) do
            frame._isDraggable = false
            frame:SetBackdropBorderColor(0, 0, 0, 1)
        end
        print("|cff00CCFF[Arc Auras]|r Frames locked")
    elseif cmd == "help" then
        print("|cff00CCFF[Arc Auras]|r Commands:")
        print("  /arcauras - Open options")
        print("  /arcauras enable - Enable")
        print("  /arcauras disable - Disable")
        print("  /arcauras scan - Show trinkets")
        print("  /arcauras unlock - Unlock frames")
        print("  /arcauras lock - Lock frames")
    else
        print("|cff00CCFF[Arc Auras]|r Unknown command. /arcauras help")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INTEGRATION HELPERS (for CDMEnhance catalog and other modules)
-- ═══════════════════════════════════════════════════════════════════════════

-- Helper: Create catalog entry for Arc Aura (item-based cooldown)
-- Used by CDMEnhance.GetCooldownIcons() and any other catalog/list displays
function ArcAuras.CreateCatalogEntry(cdID, frame)
    local Shared = ns.CDMShared
    if not Shared or not Shared.IsArcAuraID or not Shared.IsArcAuraID(cdID) then
        return nil
    end
    
    local arcType, id = Shared.ParseArcAuraID(cdID)
    if not arcType then return nil end
    
    local name, icon, itemID
    
    if arcType == "trinket" and id then
        -- Trinket slot
        itemID = GetInventoryItemID("player", id)
        if itemID then
            local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
            name = itemName or ("Trinket " .. id)
            icon = itemIcon or GetInventoryItemTexture("player", id) or 134400
        else
            name = "Trinket " .. id
            icon = GetInventoryItemTexture("player", id) or 134400
        end
    elseif arcType == "item" and id then
        -- Generic item
        itemID = id
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(id)
        name = itemName or "Item"
        icon = itemIcon or 134400
    end
    
    -- Fallback to frame data if available
    if frame then
        if frame._currentItemName and frame._currentItemName ~= "" then
            name = frame._currentItemName
        end
        if frame.Icon and frame.Icon.GetTexture then
            local frameIcon = frame.Icon:GetTexture()
            if frameIcon and frameIcon ~= 134400 then
                icon = frameIcon
            end
        end
    end
    
    return {
        cooldownID = cdID,
        spellID = nil,  -- Items don't have spellID
        itemID = itemID,
        name = name or "Unknown",
        icon = icon or 134400,
        hasCustomPos = true,
        viewerName = "EssentialCooldownViewer",
        isArcAura = true,
        arcType = arcType,
    }
end

-- Helper: Get item cooldown info for Arc Aura
-- Returns: isOnCooldown, remaining, startTime, duration
-- Item cooldowns are NON-SECRET in WoW 12.0!
function ArcAuras.GetItemCooldownState(cdID)
    local arcType, id = ArcAuras.ParseArcID(cdID)
    if not arcType or not id then
        return false, 0, 0, 0
    end
    
    local startTime, duration, enable
    
    if arcType == "trinket" then
        startTime, duration, enable = GetInventoryItemCooldown("player", id)
    elseif arcType == "item" then
        startTime, duration, enable = C_Item.GetItemCooldown(id)
    end
    
    -- Calculate state (NON-SECRET - direct comparison works!)
    local isOnCooldown = duration and duration > 0
    local remaining = 0
    if isOnCooldown then
        remaining = (startTime + duration) - GetTime()
        if remaining < 0 then
            remaining = 0
            isOnCooldown = false
        end
    end
    
    return isOnCooldown, remaining, startTime or 0, duration or 0
end

-- Helper: Get item info for Arc Aura
-- Returns: itemID, name, icon
function ArcAuras.GetItemInfoForArcID(cdID)
    local arcType, id = ArcAuras.ParseArcID(cdID)
    if not arcType or not id then
        return nil, nil, nil
    end
    
    local itemID, name, icon
    
    if arcType == "trinket" then
        itemID = GetInventoryItemID("player", id)
        if itemID then
            local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
            name = itemName
            icon = itemIcon or GetInventoryItemTexture("player", id)
        else
            name = "Trinket " .. id
            icon = GetInventoryItemTexture("player", id) or 134400
        end
    elseif arcType == "item" then
        itemID = id
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(id)
        name = itemName
        icon = itemIcon or 134400
    end
    
    return itemID, name, icon
end