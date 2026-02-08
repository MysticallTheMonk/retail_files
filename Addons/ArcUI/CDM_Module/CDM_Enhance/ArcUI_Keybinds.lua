-- ===================================================================
-- ArcUI_Keybinds.lua
-- Shows action bar keybind text on CDM icons
-- Simple, standalone module - no hooks into other ArcUI systems
-- ===================================================================

local ADDON_NAME, ns = ...

ns.Keybinds = ns.Keybinds or {}

-- LibSharedMedia for fonts
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- ===================================================================
-- CONFIGURATION
-- ===================================================================
local DEFAULT_SETTINGS = {
    enabled = false,
    font = "Friz Quadrata TT",
    fontSize = 12,
    fontOutline = "OUTLINE",
    anchor = "TOPRIGHT",
    offsetX = -1,
    offsetY = -1,
    color = { 1, 1, 1, 1 },
    frameStrata = nil,  -- nil = inherit from parent
    frameLevel = 0,     -- 0 = use parent's level + 1
}

-- ===================================================================
-- SETTINGS ACCESS (CACHED)
-- Uses CDMShared's spec-based storage so import/export works
-- ===================================================================
local cachedSettings = nil
local cachedSettingsVersion = 0  -- bumped on change to invalidate

local function InvalidateSettingsCache()
    cachedSettings = nil
    cachedSettingsVersion = cachedSettingsVersion + 1
end

local function GetSettings()
    if cachedSettings then return cachedSettings end
    
    local Shared = ns.CDMShared
    if not Shared then return DEFAULT_SETTINGS end
    
    -- Get specData.groupSettings (this is exported by import/export)
    local groupSettings = Shared.GetSpecGroupSettings and Shared.GetSpecGroupSettings()
    if not groupSettings then return DEFAULT_SETTINGS end
    
    -- Store keybinds inside groupSettings
    if not groupSettings.keybinds then
        groupSettings.keybinds = {}
    end
    
    -- Merge with defaults (reuse table to reduce GC)
    local settings = {}
    for k, v in pairs(DEFAULT_SETTINGS) do
        settings[k] = groupSettings.keybinds[k]
        if settings[k] == nil then
            settings[k] = v
        end
    end
    
    cachedSettings = settings
    return settings
end

local function SetSetting(key, value)
    local Shared = ns.CDMShared
    if not Shared then return end
    
    local groupSettings = Shared.GetSpecGroupSettings and Shared.GetSpecGroupSettings()
    if not groupSettings then return end
    
    if not groupSettings.keybinds then
        groupSettings.keybinds = {}
    end
    
    groupSettings.keybinds[key] = value
    InvalidateSettingsCache()
end

function ns.Keybinds.IsEnabled()
    local settings = GetSettings()
    return settings.enabled == true
end

function ns.Keybinds.SetEnabled(enabled)
    SetSetting("enabled", enabled)
    if enabled then
        ns.Keybinds.RefreshAll()
    else
        ns.Keybinds.HideAll()
    end
end

-- ===================================================================
-- KEYBIND CACHE
-- ===================================================================
local keybindCache = {
    bySpellID = {},
    byItemID = {},   -- For items on action bars
    byTexture = {},
    lastUpdate = 0,
}

-- ===================================================================
-- ADDON BUTTON CACHE (built ONCE, not on every rebuild)
-- Stores addon bar buttons found via EnumerateFrames so we never
-- have to iterate all UI frames again on form/bar changes.
-- ===================================================================
local addonButtonCache = {}    -- array of {frame=, action=, bindingName=}
local addonButtonCacheBuilt = false

local function FormatKeybind(raw)
    if not raw or raw == "" then return nil end
    
    local text = tostring(raw):upper()
    
    -- Strip control characters that might display as dots
    text = text:gsub("[%c]", "")
    
    local clean = text:gsub("%s+", "")
    if clean == "" or clean == "UNBOUND" or clean == "UNKNOWN" or clean == "RANGE" then
        return nil
    end
    
    -- Filter out keybinds that are just punctuation or symbols
    if clean:match("^[%.%-_=+]+$") then
        return nil
    end
    
    -- Extract modifiers (handle both SHIFT- and SHIFT+ formats)
    local mods = ""
    if text:find("SHIFT[%-+]") or text:find("^S%-") or text:find("^S%+") then mods = mods .. "S" end
    if text:find("CTRL[%-+]") or text:find("^C%-") or text:find("^C%+") then mods = mods .. "C" end
    if text:find("ALT[%-+]") or text:find("^A%-") or text:find("^A%+") then mods = mods .. "A" end
    
    -- Strip modifiers from key (handle both dash and plus)
    local key = text
    key = key:gsub("SHIFT[%-+]", ""):gsub("CTRL[%-+]", ""):gsub("ALT[%-+]", "")
    key = key:gsub("^S[%-+]", ""):gsub("^C[%-+]", ""):gsub("^A[%-+]", "")
    key = key:gsub("%s+", "")
    
    -- Mouse buttons
    if key == "MIDDLEMOUSE" then key = "M3" end
    key = key:gsub("^BUTTON(%d+)$", "M%1")
    key = key:gsub("^MOUSEBUTTON(%d+)$", "M%1")
    
    -- Mouse wheel
    key = key:gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD")
    
    -- Numpad keys
    key = key:gsub("NUMPADPLUS", "N+"):gsub("NUMPADMINUS", "N-")
    key = key:gsub("NUMPADMULTIPLY", "N*"):gsub("NUMPADDIVIDE", "N/")
    key = key:gsub("NUMPADPERIOD", "N."):gsub("NUMPADENTER", "NE")
    key = key:gsub("^NUMPAD(%d)", "N%1")
    
    -- Navigation keys
    key = key:gsub("PAGEUP", "PU"):gsub("PAGEDOWN", "PD")
    key = key:gsub("^HOME$", "HM"):gsub("^END$", "EN")
    key = key:gsub("INSERT", "INS"):gsub("DELETE", "DEL")
    
    -- Arrow keys
    key = key:gsub("UPARROW", "UP"):gsub("DOWNARROW", "DN")
    key = key:gsub("LEFTARROW", "LT"):gsub("RIGHTARROW", "RT")
    
    -- Other common keys
    key = key:gsub("^SPACE$", "SP"):gsub("BACKSPACE", "BS")
    key = key:gsub("^ESCAPE$", "ESC"):gsub("CAPSLOCK", "CAP")
    key = key:gsub("^TAB$", "TB")
    
    -- Special handling for minus/plus/equals as actual keys
    if key == "-" or key == "MINUS" then key = "-" end
    if key == "+" or key == "PLUS" or key == "=" or key == "EQUALS" then key = "=" end
    
    -- If key is empty after all processing, skip
    if key == "" then
        return nil
    end
    
    local result = mods .. key
    
    -- Final sanity check - only allow printable ASCII
    if result:match("[^%w%-%+=%.%*%/]") then
        result = result:gsub("[^%w%-%+=%.%*%/]", "")
    end
    
    if result == "" then return nil end
    
    -- Final check: reject if it's just dots or periods
    if result:match("^[%.]+$") then return nil end
    
    -- Reject if result contains ellipsis character or multiple dots
    if result:find("…") or result:find("%.%.") then return nil end
    
    return #result > 4 and result:sub(1, 4) or result
end

-- ===================================================================
-- PROCESS A SINGLE ACTION SLOT (shared by standard + addon scanning)
-- ===================================================================
local function ProcessSlotIntoCache(slot, bindingName)
    if not HasAction(slot) then return end
    
    local key1 = GetBindingKey(bindingName)
    if not key1 then return end
    
    local formatted = FormatKeybind(key1)
    if not formatted then return end
    
    local actionType, id = GetActionInfo(slot)
    local texture = GetActionTexture(slot)
    
    -- Secret value protection: don't use secret values as table indices
    local idIsSecret = id and issecretvalue(id)
    local textureIsSecret = texture and issecretvalue(texture)
    
    -- Store by texture (only if not secret)
    if texture and not textureIsSecret then
        keybindCache.byTexture[texture] = keybindCache.byTexture[texture] or formatted
    end
    
    if actionType == "spell" and id and not idIsSecret then
        keybindCache.bySpellID[id] = keybindCache.bySpellID[id] or formatted
        if C_Spell and C_Spell.GetBaseSpell then
            local baseID = C_Spell.GetBaseSpell(id)
            if baseID and not issecretvalue(baseID) and baseID ~= id then
                keybindCache.bySpellID[baseID] = keybindCache.bySpellID[baseID] or formatted
            end
        end
    elseif actionType == "item" and id and not idIsSecret then
        keybindCache.byItemID[id] = keybindCache.byItemID[id] or formatted
        if GetItemSpell then
            local _, spellID = GetItemSpell(id)
            if spellID and not issecretvalue(spellID) then
                keybindCache.bySpellID[spellID] = keybindCache.bySpellID[spellID] or formatted
            end
        end
    elseif actionType == "macro" and id and not idIsSecret then
        local macroSpell = GetMacroSpell(id)
        if macroSpell and not issecretvalue(macroSpell) then
            keybindCache.bySpellID[macroSpell] = keybindCache.bySpellID[macroSpell] or formatted
        end
    end
end

-- ===================================================================
-- ADDON BUTTON HELPERS (used by one-time EnumerateFrames scan)
-- ===================================================================
local function IsForbiddenFrame(f)
    if not f then return true end
    local ok, forbidden = pcall(function()
        return f.IsForbidden and f:IsForbidden()
    end)
    return not ok or forbidden
end

local function GetHotkeyFromButton(button)
    if not button or IsForbiddenFrame(button) then return nil end
    
    -- Try HotKey fontstring first (most addons have this)
    if button.HotKey and button.HotKey.GetText then
        local ok, text = pcall(function() return button.HotKey:GetText() end)
        if ok and text and text ~= "" then
            local clean = text:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if clean ~= "" 
               and clean:upper() ~= "UNBOUND" 
               and clean:upper() ~= "RANGE"
               and not clean:match("^[%.…]+$")
               and not clean:match("%.%.") then
                return clean
            end
        end
    end
    
    -- Try GetHotkey method
    if button.GetHotkey and type(button.GetHotkey) == "function" then
        local ok, key = pcall(function() return button:GetHotkey() end)
        if ok and key and type(key) == "string" and key ~= "" then
            if not key:match("^[%.…]+$") and not key:match("%.%.") then
                return key
            end
        end
    end
    
    -- Try binding action (for secure buttons)
    if button.bindingAction and button.bindingAction ~= "" then
        local key = GetBindingKey(button.bindingAction)
        if key then return key end
    end
    
    -- Try commandName
    if button.commandName and button.commandName ~= "" then
        local key = GetBindingKey(button.commandName)
        if key then return key end
    end
    
    -- Try "CLICK ButtonName:LeftButton" binding
    local name = button.GetName and button:GetName()
    if name and type(name) == "string" and name ~= "" then
        local key = GetBindingKey("CLICK " .. name .. ":LeftButton")
        if key then return key end
    end
    
    return nil
end

local function GetActionFromButton(button)
    if not button or IsForbiddenFrame(button) then return nil end
    
    -- Try .action property
    if button.action and type(button.action) == "number" then
        if HasAction(button.action) then
            return button.action
        end
    end
    
    -- Try GetAction method
    if button.GetAction and type(button.GetAction) == "function" then
        local ok, action = pcall(function() return button:GetAction() end)
        if ok and action and type(action) == "number" and action > 0 and HasAction(action) then
            return action
        end
    end
    
    -- Try attribute
    if button.GetAttribute and type(button.GetAttribute) == "function" then
        local ok, action = pcall(function() return button:GetAttribute("action") end)
        if ok and action then
            action = tonumber(action)
            if action and action > 0 and HasAction(action) then
                return action
            end
        end
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- BUILD ADDON BUTTON CACHE (runs ONCE, not on every rebuild)
-- Finds ElvUI/Bartender/Dominos buttons via EnumerateFrames and
-- caches them so RebuildCache() never needs to iterate all frames.
-- ═══════════════════════════════════════════════════════════════════
local function BuildAddonButtonCache()
    if addonButtonCacheBuilt then return end
    addonButtonCacheBuilt = true
    wipe(addonButtonCache)
    
    local f = EnumerateFrames()
    while f do
        if not IsForbiddenFrame(f) and type(f.GetObjectType) == "function" then
            local objType = f:GetObjectType()
            if objType == "CheckButton" or objType == "Button" then
                local name = f.GetName and f:GetName() or ""
                if type(name) ~= "string" then name = "" end
                -- Skip standard Blizzard buttons (handled by slot mappings)
                if not name:match("^ActionButton%d+$") 
                   and not name:match("^MultiBar.*Button%d+$") then
                    -- Check if this looks like an action button
                    local action = GetActionFromButton(f)
                    if action then
                        -- Cache this button for future fast rescans
                        addonButtonCache[#addonButtonCache + 1] = f
                    end
                end
            end
        end
        f = EnumerateFrames(f)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- RESCAN CACHED ADDON BUTTONS (fast - no EnumerateFrames)
-- Only re-reads the hotkey/action from already-discovered buttons.
-- ═══════════════════════════════════════════════════════════════════
local function RescanAddonButtons()
    for i = #addonButtonCache, 1, -1 do
        local button = addonButtonCache[i]
        -- Validate button still exists and is usable
        if not button or IsForbiddenFrame(button) then
            table.remove(addonButtonCache, i)
        else
            local action = GetActionFromButton(button)
            if action then
                local hotkeyText = GetHotkeyFromButton(button)
                if hotkeyText then
                    local formatted = FormatKeybind(hotkeyText)
                    if formatted and formatted ~= "" then
                        local actionType, id = GetActionInfo(action)
                        local texture = GetActionTexture(action)
                        
                        local idIsSecret = id and issecretvalue(id)
                        local textureIsSecret = texture and issecretvalue(texture)
                        
                        if texture and not textureIsSecret then
                            keybindCache.byTexture[texture] = keybindCache.byTexture[texture] or formatted
                        end
                        
                        if actionType == "spell" and id and not idIsSecret then
                            keybindCache.bySpellID[id] = keybindCache.bySpellID[id] or formatted
                            if C_Spell and C_Spell.GetBaseSpell then
                                local baseID = C_Spell.GetBaseSpell(id)
                                if baseID and not issecretvalue(baseID) and baseID ~= id then
                                    keybindCache.bySpellID[baseID] = keybindCache.bySpellID[baseID] or formatted
                                end
                            end
                        elseif actionType == "item" and id and not idIsSecret then
                            keybindCache.byItemID[id] = keybindCache.byItemID[id] or formatted
                            if GetItemSpell then
                                local _, spellID = GetItemSpell(id)
                                if spellID and not issecretvalue(spellID) then
                                    keybindCache.bySpellID[spellID] = keybindCache.bySpellID[spellID] or formatted
                                end
                            end
                        elseif actionType == "macro" and id and not idIsSecret then
                            local macroSpell = GetMacroSpell(id)
                            if macroSpell and not issecretvalue(macroSpell) then
                                keybindCache.bySpellID[macroSpell] = keybindCache.bySpellID[macroSpell] or formatted
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Slot-to-binding mapping based on Warcraft Wiki
-- https://warcraft.wiki.gg/wiki/Action_slot
local SLOT_MAPPINGS = {
    -- Action Bar 1 (page 1): slots 1-12 → ACTIONBUTTON1-12
    { startSlot = 1,   binding = "ACTIONBUTTON" },
    -- Action Bar 2 (MultiBarBottomLeft): slots 61-72 → MULTIACTIONBAR1BUTTON1-12
    { startSlot = 61,  binding = "MULTIACTIONBAR1BUTTON" },
    -- Action Bar 3 (MultiBarBottomRight): slots 49-60 → MULTIACTIONBAR2BUTTON1-12
    { startSlot = 49,  binding = "MULTIACTIONBAR2BUTTON" },
    -- Action Bar 4 (MultiBarRight): slots 25-36 → MULTIACTIONBAR3BUTTON1-12
    { startSlot = 25,  binding = "MULTIACTIONBAR3BUTTON" },
    -- Action Bar 5 (MultiBarLeft): slots 37-48 → MULTIACTIONBAR4BUTTON1-12
    { startSlot = 37,  binding = "MULTIACTIONBAR4BUTTON" },
    -- Action Bar 6 (MultiBar5): slots 145-156 → MULTIACTIONBAR5BUTTON1-12
    { startSlot = 145, binding = "MULTIACTIONBAR5BUTTON" },
    -- Action Bar 7 (MultiBar6): slots 157-168 → MULTIACTIONBAR6BUTTON1-12
    { startSlot = 157, binding = "MULTIACTIONBAR6BUTTON" },
    -- Action Bar 8 (MultiBar7): slots 169-180 → MULTIACTIONBAR7BUTTON1-12
    { startSlot = 169, binding = "MULTIACTIONBAR7BUTTON" },
}

local function RebuildCache()
    local now = GetTime()
    if (now - keybindCache.lastUpdate) < 0.5 then return end
    
    wipe(keybindCache.bySpellID)
    wipe(keybindCache.byItemID)
    wipe(keybindCache.byTexture)
    
    -- Process all standard mapped bars (fast - fixed 96 slots max)
    for _, mapping in ipairs(SLOT_MAPPINGS) do
        for i = 1, 12 do
            local slot = mapping.startSlot + i - 1
            ProcessSlotIntoCache(slot, mapping.binding .. i)
        end
    end
    
    -- Handle bonus bars (stances/forms) - slots 73-120 map to ACTIONBUTTON when active
    local bonusOffset = C_ActionBar and C_ActionBar.GetBonusBarOffset and C_ActionBar.GetBonusBarOffset() or 0
    if bonusOffset and not issecretvalue(bonusOffset) and bonusOffset > 0 then
        local bonusStartSlot = 72 + ((bonusOffset - 1) * 12) + 1
        for i = 1, 12 do
            local slot = bonusStartSlot + i - 1
            if slot <= 120 then
                ProcessSlotIntoCache(slot, "ACTIONBUTTON" .. i)
            end
        end
    end
    
    -- Rescan cached addon buttons (fast - no EnumerateFrames)
    if addonButtonCacheBuilt and #addonButtonCache > 0 then
        RescanAddonButtons()
    end
    
    keybindCache.lastUpdate = now
end

-- ===================================================================
-- APPLY KEYBIND TO FRAME
-- ===================================================================

-- Parse Arc Aura ID to get type and numeric ID
local function ParseArcAuraID(arcID)
    if not arcID or type(arcID) ~= "string" then return nil, nil end
    
    -- arc_trinket_13 = trinket in slot 13 (trinket 1), need to look up actual itemID
    local slotID = arcID:match("^arc_trinket_(%d+)$")
    if slotID then
        slotID = tonumber(slotID)
        if slotID and GetInventoryItemID then
            local itemID = GetInventoryItemID("player", slotID)
            if itemID and not issecretvalue(itemID) then
                return "item", itemID
            end
        end
        return nil, nil
    end
    
    -- arc_item_12345 = specific item ID (parsed from string, always safe)
    local itemID = arcID:match("^arc_item_(%d+)$")
    if itemID then
        return "item", tonumber(itemID)
    end
    
    -- arc_spell_67890 = specific spell ID (parsed from string, always safe)
    local spellID = arcID:match("^arc_spell_(%d+)$")
    if spellID then
        return "spell", tonumber(spellID)
    end
    
    return nil, nil
end

local function GetKeybindForFrame(frame)
    if not frame then return nil end
    
    -- NOTE: RebuildCache() is called ONCE before the frame loop in RefreshAll(),
    -- not per-frame. The 0.5s throttle ensures we don't rebuild redundantly.
    RebuildCache()
    
    local cdID = frame.cooldownID
    
    -- Handle Arc Aura string IDs (arc_item_12345, arc_spell_67890, arc_trinket_13)
    if cdID and type(cdID) == "string" then
        local auraType, numericID = ParseArcAuraID(cdID)
        if auraType == "item" and numericID then
            if keybindCache.byItemID[numericID] then
                return keybindCache.byItemID[numericID]
            end
            if GetItemSpell then
                local _, spellID = GetItemSpell(numericID)
                if spellID and not issecretvalue(spellID) and keybindCache.bySpellID[spellID] then
                    return keybindCache.bySpellID[spellID]
                end
            end
            if frame.Icon and frame.Icon.GetTexture then
                local ok, tex = pcall(frame.Icon.GetTexture, frame.Icon)
                if ok and tex and not issecretvalue(tex) and keybindCache.byTexture[tex] then
                    return keybindCache.byTexture[tex]
                end
            end
        elseif auraType == "spell" and numericID then
            if keybindCache.bySpellID[numericID] then
                return keybindCache.bySpellID[numericID]
            end
        end
        -- Final fallback for any arc aura - try texture
        if frame.Icon and frame.Icon.GetTexture then
            local ok, tex = pcall(frame.Icon.GetTexture, frame.Icon)
            if ok and tex and not issecretvalue(tex) and keybindCache.byTexture[tex] then
                return keybindCache.byTexture[tex]
            end
        end
        return nil
    end
    
    -- Handle CDM numeric cooldownIDs
    if cdID and type(cdID) == "number" then
        if issecretvalue(cdID) then return nil end
        if cdID <= 0 or cdID >= 2147483647 then return nil end
        
        if C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
            local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
            if ok and info then
                local spellID = info.spellID
                if spellID and not issecretvalue(spellID) and keybindCache.bySpellID[spellID] then
                    return keybindCache.bySpellID[spellID]
                end
                local iconID = info.iconFileID or info.icon
                if iconID and not issecretvalue(iconID) and keybindCache.byTexture[iconID] then
                    return keybindCache.byTexture[iconID]
                end
            end
        end
    end
    
    -- Try frame's Icon texture as fallback
    if frame.Icon and frame.Icon.GetTexture then
        local ok, tex = pcall(frame.Icon.GetTexture, frame.Icon)
        if ok and tex and not issecretvalue(tex) and keybindCache.byTexture[tex] then
            return keybindCache.byTexture[tex]
        end
    end
    
    return nil
end

local function ApplyKeybindToFrame(frame)
    if not frame then return end
    
    local globalSettings = GetSettings()
    if not globalSettings.enabled then
        if frame._arcKeybindFrame then
            frame._arcKeybindFrame:Hide()
        end
        return
    end
    
    -- Get per-icon settings if available
    local cdID = frame.cooldownID
    local iconSettings = nil
    local perIconSettings = nil
    if cdID and ns.CDMEnhance and ns.CDMEnhance.GetIconSettings then
        iconSettings = ns.CDMEnhance.GetIconSettings(cdID)
        if iconSettings then
            -- Check hideKeybind first
            if iconSettings.hideKeybind then
                if frame._arcKeybindFrame then
                    frame._arcKeybindFrame:Hide()
                end
                return
            end
            -- Get per-icon keybindText settings if override is enabled
            if iconSettings.keybindText and iconSettings.keybindText.enabled then
                perIconSettings = iconSettings.keybindText
            end
        end
    end
    
    local keybind = GetKeybindForFrame(frame)
    
    if not keybind then
        if frame._arcKeybindFrame then
            frame._arcKeybindFrame:Hide()
        end
        return
    end
    
    -- ── Dirty check: skip full styling if keybind text hasn't changed ──
    -- and settings version hasn't changed (no font/position/color changes)
    if frame._arcKeybindFrame and frame._arcKeybindFrame:IsShown() then
        local lastText = frame._arcKeybindLastText
        local lastVersion = frame._arcKeybindSettingsVersion
        if lastText == keybind and lastVersion == cachedSettingsVersion then
            return  -- Nothing changed, skip all the styling work
        end
    end
    
    -- Create container frame if needed (allows strata/level control)
    if not frame._arcKeybindFrame then
        local container = CreateFrame("Frame", nil, frame)
        container._text = container:CreateFontString(nil, "OVERLAY")
        frame._arcKeybindFrame = container
    end
    
    local container = frame._arcKeybindFrame
    local fs = container._text
    
    -- Determine which settings to use (per-icon overrides global)
    local fontSize = (perIconSettings and perIconSettings.size) or globalSettings.fontSize or 12
    local fontOutline = (perIconSettings and perIconSettings.outline) or globalSettings.fontOutline or "OUTLINE"
    local anchor = (perIconSettings and perIconSettings.anchor) or globalSettings.anchor or "TOPRIGHT"
    local offsetX = (perIconSettings and perIconSettings.offsetX) or globalSettings.offsetX or -1
    local offsetY = (perIconSettings and perIconSettings.offsetY) or globalSettings.offsetY or -1
    local fontName = (perIconSettings and perIconSettings.font) or globalSettings.font
    local color = (perIconSettings and perIconSettings.color) or globalSettings.color or { 1, 1, 1, 1 }
    
    -- Set strata and level (nil/0 = inherit from parent)
    if globalSettings.frameStrata and globalSettings.frameStrata ~= "" then
        container:SetFrameStrata(globalSettings.frameStrata)
    else
        container:SetFrameStrata(frame:GetFrameStrata())
    end
    
    if globalSettings.frameLevel and globalSettings.frameLevel > 0 then
        container:SetFrameLevel(globalSettings.frameLevel)
    else
        container:SetFrameLevel(frame:GetFrameLevel() + 1)
    end
    
    -- Get font path from LSM or use default
    local fontPath = "Fonts\\FRIZQT__.TTF"
    if LSM and fontName then
        local lsmPath = LSM:Fetch("font", fontName, true)
        if lsmPath then
            fontPath = lsmPath
        end
    end
    
    -- Style - use pcall in case font path is invalid
    local fontSet = fs:SetFont(fontPath, fontSize, fontOutline)
    if not fontSet then
        fs:SetFont("Fonts\\FRIZQT__.TTF", fontSize, fontOutline)
    end
    
    -- Disable word wrap and set justification
    fs:SetWordWrap(false)
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    
    -- Handle color (can be array or table with r/g/b/a keys)
    local r, g, b, a = 1, 1, 1, 1
    if color then
        if color.r then
            r, g, b, a = color.r or 1, color.g or 1, color.b or 1, color.a or 1
        elseif color[1] then
            r, g, b, a = color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
        end
    end
    fs:SetTextColor(r, g, b, a)
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
    
    -- Position container
    container:ClearAllPoints()
    container:SetAllPoints(frame)
    
    -- Position fontstring
    fs:ClearAllPoints()
    fs:SetPoint(anchor, container, anchor, offsetX, offsetY)
    
    fs:SetText(keybind)
    container:Show()
    
    -- Store dirty-check state
    frame._arcKeybindLastText = keybind
    frame._arcKeybindSettingsVersion = cachedSettingsVersion
end

-- ===================================================================
-- PUBLIC API
-- ===================================================================

-- Debounced refresh for slider changes (avoids lag)
local styleRefreshQueued = false
local function QueueStyleRefresh()
    if styleRefreshQueued then return end
    styleRefreshQueued = true
    C_Timer.After(0.05, function()
        styleRefreshQueued = false
        if ns.Keybinds.IsEnabled() then
            ns.Keybinds.RefreshStyle()
        end
    end)
end

-- Helper: is this frame an aura viewer?
local function IsAuraFrame(entry)
    if not entry then return false end
    local viewerName = entry.viewerName
    return viewerName and (viewerName == "BuffIconCooldownViewer" or viewerName:find("Buff") or viewerName:find("Aura"))
end

-- Refresh just the styling (no cache rebuild) - fast for slider changes
function ns.Keybinds.RefreshStyle()
    if not ns.Keybinds.IsEnabled() then return end
    
    -- Invalidate dirty-check so all frames re-style
    cachedSettingsVersion = cachedSettingsVersion + 1
    
    -- CDMGroups frames (cooldowns only - skip auras)
    if ns.CDMGroups and ns.CDMGroups.groups then
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.members then
                for _, member in pairs(group.members) do
                    if member.frame and not IsAuraFrame(member.entry) then
                        ApplyKeybindToFrame(member.frame)
                    end
                end
            end
        end
    end
    
    -- Free icons (cooldowns only)
    if ns.CDMGroups and ns.CDMGroups.freeIcons then
        for _, data in pairs(ns.CDMGroups.freeIcons) do
            if data.frame and not IsAuraFrame(data.entry) then
                ApplyKeybindToFrame(data.frame)
            end
        end
    end
    
    -- Arc Auras frames
    if ns.ArcAuras and ns.ArcAuras.frames then
        for arcID, frame in pairs(ns.ArcAuras.frames) do
            if frame and frame:IsShown() then
                ApplyKeybindToFrame(frame)
            end
        end
    end
end

-- Queue a debounced style refresh (for sliders)
function ns.Keybinds.QueueRefresh()
    QueueStyleRefresh()
end

function ns.Keybinds.RefreshAll()
    if not ns.Keybinds.IsEnabled() then return end
    
    -- Rebuild keybind cache ONCE before iterating frames
    keybindCache.lastUpdate = 0
    RebuildCache()
    
    -- CDMGroups frames (cooldowns only - skip auras)
    if ns.CDMGroups and ns.CDMGroups.groups then
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.members then
                for _, member in pairs(group.members) do
                    if member.frame then
                        if not IsAuraFrame(member.entry) then
                            ApplyKeybindToFrame(member.frame)
                        elseif member.frame._arcKeybindFrame then
                            member.frame._arcKeybindFrame:Hide()
                        end
                    end
                end
            end
        end
    end
    
    -- Free icons (cooldowns only)
    if ns.CDMGroups and ns.CDMGroups.freeIcons then
        for _, data in pairs(ns.CDMGroups.freeIcons) do
            if data.frame then
                if not IsAuraFrame(data.entry) then
                    ApplyKeybindToFrame(data.frame)
                elseif data.frame._arcKeybindFrame then
                    data.frame._arcKeybindFrame:Hide()
                end
            end
        end
    end
    
    -- Arc Auras frames (items/trinkets/spells)
    if ns.ArcAuras and ns.ArcAuras.frames then
        for arcID, frame in pairs(ns.ArcAuras.frames) do
            if frame and frame:IsShown() then
                ApplyKeybindToFrame(frame)
            elseif frame and frame._arcKeybindFrame then
                frame._arcKeybindFrame:Hide()
            end
        end
    end
end

function ns.Keybinds.HideAll()
    local function hide(frame)
        if frame and frame._arcKeybindFrame then
            frame._arcKeybindFrame:Hide()
            frame._arcKeybindLastText = nil  -- Clear dirty state
        end
    end
    
    if ns.CDMGroups and ns.CDMGroups.groups then
        for _, group in pairs(ns.CDMGroups.groups) do
            if group.members then
                for _, member in pairs(group.members) do
                    hide(member.frame)
                end
            end
        end
    end
    
    if ns.CDMGroups and ns.CDMGroups.freeIcons then
        for _, data in pairs(ns.CDMGroups.freeIcons) do
            hide(data.frame)
        end
    end
    
    -- Arc Auras frames
    if ns.ArcAuras and ns.ArcAuras.frames then
        for _, frame in pairs(ns.ArcAuras.frames) do
            hide(frame)
        end
    end
end

function ns.Keybinds.ApplyToFrame(frame, entry)
    if not ns.Keybinds.IsEnabled() then return end
    
    -- Skip aura frames
    if IsAuraFrame(entry) then
        if frame and frame._arcKeybindFrame then
            frame._arcKeybindFrame:Hide()
        end
        return
    end
    
    ApplyKeybindToFrame(frame)
end

function ns.Keybinds.GetSettings()
    return GetSettings()
end

function ns.Keybinds.SetSetting(key, value)
    SetSetting(key, value)
    -- Use debounced style refresh for slider changes (no cache rebuild needed)
    ns.Keybinds.QueueRefresh()
end

-- ===================================================================
-- EVENTS
-- ===================================================================
local eventFrame = CreateFrame("Frame")
local refreshQueued = false

local function QueueRefresh()
    if refreshQueued or not ns.Keybinds.IsEnabled() then return end
    refreshQueued = true
    -- 0.3s debounce - absorbs the burst of ACTIONBAR_SLOT_CHANGED events
    -- that fire per-slot during form changes (12+ events at once)
    C_Timer.After(0.3, function()
        refreshQueued = false
        if ns.Keybinds.IsEnabled() then
            ns.Keybinds.RefreshAll()
        end
    end)
end

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "UPDATE_BINDINGS" then
        -- Bindings actually changed - need to rebuild addon button cache too
        -- since custom addon keybinds may have changed
        addonButtonCacheBuilt = false
        C_Timer.After(0.5, function()
            BuildAddonButtonCache()
            if ns.Keybinds.IsEnabled() then
                keybindCache.lastUpdate = 0
                QueueRefresh()
            end
        end)
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        -- Fires per-slot during form changes - just queue, don't clear cache
        -- per event. The debounced QueueRefresh will rebuild once.
        QueueRefresh()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Build addon button cache once (the expensive EnumerateFrames scan)
        C_Timer.After(2.0, function()
            BuildAddonButtonCache()
            if ns.Keybinds.IsEnabled() then
                QueueRefresh()
            end
        end)
        -- Later refresh for Arc Auras (they initialize later)
        C_Timer.After(3.5, function()
            if ns.Keybinds.IsEnabled() and ns.ArcAuras and ns.ArcAuras.frames then
                keybindCache.lastUpdate = 0
                ns.Keybinds.RefreshAll()
            end
        end)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        -- Spec changes completely rebuild action bars
        -- Hide immediately, then single delayed refresh
        ns.Keybinds.HideAll()
        
        wipe(keybindCache.bySpellID)
        wipe(keybindCache.byItemID)
        wipe(keybindCache.byTexture)
        keybindCache.lastUpdate = 0
        InvalidateSettingsCache()
        
        -- Rebuild addon button cache (new spec may have different buttons)
        addonButtonCacheBuilt = false
        
        -- Single refresh after action bars settle (2s is sufficient)
        C_Timer.After(2.0, function()
            if ns.Keybinds.IsEnabled() then
                BuildAddonButtonCache()
                keybindCache.lastUpdate = 0
                ns.Keybinds.RefreshAll()
            end
        end)
    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_STEALTH" then
        -- Stance/form changes swap action bar pages
        -- These fire alongside ACTIONBAR_SLOT_CHANGED, so just queue
        QueueRefresh()
    end
end)

eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_STEALTH")