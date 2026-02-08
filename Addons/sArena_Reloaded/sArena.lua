local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local isTBC = sArenaMixin.isTBC
local L = sArenaMixin.L

-- Older clients dont show opponents in spawn
local noEarlyFrames = sArenaMixin.isTBC or sArenaMixin.isWrath
local isModernArena = isRetail or isMidnight -- For old trinkets

sArenaMixin.playerClass = select(2, UnitClass("player"))
sArenaMixin.maxArenaOpponents = (isRetail and 3) or 5
sArenaMixin.noTrinketTexture = (isTBC and 132311) or 638661 --temp texture for tbc. todo: export retail and include in sarena
sArenaMixin.trinketTexture = (isRetail and 1322720) or 133453
sArenaMixin.trinketID = (isRetail and 336126) or 42292
sArenaMixin.showPixelBorder = false
sArenaMixin.interruptReady = true
C_AddOns.EnableAddOn("sArena_Reloaded")
local LSM = LibStub("LibSharedMedia-3.0")
local decimalThreshold = 6 -- Default value, will be updated from db
LSM:Register("statusbar", "Blizzard RetailBar", [[Interface\AddOns\sArena_Reloaded\Textures\BlizzardRetailBar]])
LSM:Register("statusbar", "sArena Default", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaDefault]])
LSM:Register("statusbar", "sArena Stripes", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaHealer]])
LSM:Register("statusbar", "sArena Stripes 2", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaRetailHealer]])
-- Prototype font only supports western languages and Russian, so LSM will automatically reject registration on unsupported locales
LSM:Register("font", "Prototype", "Interface\\Addons\\sArena_Reloaded\\Textures\\Prototype.ttf", LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU)
LSM:Register("font", "PT Sans Narrow Bold", "Interface\\Addons\\sArena_Reloaded\\Textures\\PTSansNarrow-Bold.ttf", LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU)
-- Fetch pFont through LSM: use Prototype if registered, otherwise fall back to LSM's default font for the current locale
sArenaMixin.pFont = LSM:Fetch(LSM.MediaType.FONT, "Prototype") or LSM:Fetch(LSM.MediaType.FONT, LSM:GetDefault(LSM.MediaType.FONT))
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local stealthAlpha = 0.4
local shadowsightStartTime = 95
local shadowsightResetTime = 122
local shadowSightID = 34709
sArenaMixin.beenInArena = false
sArenaMixin.shadowsightTimers = {0, 0}
sArenaMixin.shadowsightAvailable = 2


-- Track which arena units we've seen (to work around UnitExists returning false for stealthed units)
if noEarlyFrames then
    sArenaMixin.seenArenaUnits = {}
end

sArenaMixin.healerSpecNames = {
    ["Discipline"] = true,
    ["Restoration"] = true,
    ["Mistweaver"] = true,
    ["Holy"] = true,
    ["Preservation"] = true,
}

local classPowerType = {
    WARRIOR = "RAGE",
    ROGUE = "ENERGY",
    DRUID = "MANA",
    PALADIN = "MANA",
    HUNTER = "FOCUS",
    DEATHKNIGHT = "RUNIC_POWER",
    SHAMAN = "MANA",
    MAGE = "MANA",
    WARLOCK = "MANA",
    PRIEST = "MANA",
    DEMONHUNTER = "FURY",
    EVOKER = "ESSENCE",
}

function sArenaMixin:Print(fmt, ...)
    local prefix = "|cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t:"
    print(prefix, string.format(fmt, ...))
end

local function IsSoloShuffle()
    return C_PvP and C_PvP.IsSoloShuffle and C_PvP.IsSoloShuffle()
end

function sArenaMixin:FontValues()
    local t, keys = {}, {}
    for k in pairs(LSM:HashTable(LSM.MediaType.FONT)) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do t[k] = k end
    return t
end

function sArenaMixin:FontOutlineValues()
    return {
        [""] = L["Outline_None"],
        ["OUTLINE"] = L["Outline_Normal"],
        ["THICKOUTLINE"] = L["Outline_Thick"]
    }
end

sArenaMixin.classIcons = {
    ["DRUID"] = 625999,
    ["HUNTER"] = 135495, -- 626000
    ["MAGE"] = 135150, -- 626001
    ["MONK"] = 626002,
    ["PALADIN"] = 626003,
    ["PRIEST"] = 626004,
    ["ROGUE"] = 626005,
    ["SHAMAN"] = 626006,
    ["WARLOCK"] = 626007,
    ["WARRIOR"] = 135328, -- 626008
    ["DEATHKNIGHT"] = 135771,
    ["DEMONHUNTER"] = 1260827,
	["EVOKER"] = 4574311,
}

sArenaMixin.healerSpecIDs = {
    [65] = true,    -- Holy Paladin
    [105] = true,   -- Restoration Druid
    [256] = true,   -- Discipline Priest
    [257] = true,   -- Holy Priest
    [264] = true,   -- Restoration Shaman
    [270] = true,   -- Mistweaver Monk
    [1468] = true   -- Preservation Evoker
}

local castToAuraMap -- Spellcasts with non-duration aura spell ids

if isRetail then
    castToAuraMap = {
        [212182] = 212183, -- Smoke Bomb
        [359053] = 212183, -- Smoke Bomb
        [198838] = 201633, -- Earthen Wall Totem
        [62618]  = 81782,  -- Power Word: Barrier
        [204336] = 8178,   -- Grounding Totem
        [443028] = 456499, -- Celestial Conduit (Absolute Serenity)
        [289655] = 289655, -- Sanctified Ground
    }
    sArenaMixin.nonDurationAuras = {
        [212183] = {duration = 5, helpful = false, texture = 458733}, -- Smoke Bomb
        [201633] = {duration = 18, helpful = true, texture = 136098}, -- Earthen Wall Totem
        [81782]  = {duration = 10, helpful = true, texture = 253400}, -- Power Word: Barrier
        [8178]   = {duration = 3,  helpful = true, texture = 136039}, -- Grounding Totem
        [456499] = {duration = 4,  helpful = true, texture = 988197}, -- Celestial Conduit (Absolute Serenity)
        [289655] = {duration = 5,  helpful = true, texture = 237544}, -- Sanctified Ground
    }
else
    castToAuraMap = {
        [212182] = 212183, -- Smoke Bomb
        [359053] = 212183, -- Smoke Bomb
        [198838] = 201633, -- Earthen Wall Totem
        [62618]  = 81782,  -- Power Word: Barrier
        [204336] = 8178,   -- Grounding Totem
        [443028] = 456499, -- Celestial Conduit (Absolute Serenity)
        [289655] = 289655, -- Sanctified Ground
    }
        sArenaMixin.nonDurationAuras = {
        [212183] = {duration = 5, helpful = false, texture = 458733}, -- Smoke Bomb
        [201633] = {duration = 18, helpful = true, texture = 136098}, -- Earthen Wall Totem
        [81782]  = {duration = 10, helpful = true, texture = 253400}, -- Power Word: Barrier
        [8178]   = {duration = 3,  helpful = true, texture = 136039}, -- Grounding Totem
        [456499] = {duration = 4,  helpful = true, texture = 988197}, -- Celestial Conduit (Absolute Serenity)
        [289655] = {duration = 5,  helpful = true, texture = 237544}, -- Sanctified Ground
    }
end

sArenaMixin.activeNonDurationAuras = {}

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID
local GetTime = GetTime
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitPowerMax = UnitPowerMax
local UnitPower = UnitPower
local UnitPowerType = UnitPowerType
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetSpellName = GetSpellName or C_Spell.GetSpellName
local testActive
local masqueOn
local TestTitle
local feignDeathID = 5384
local FEIGN_DEATH = GetSpellName(feignDeathID) -- Localized name for Feign Death

--[[
    ImportOtherForkSettings: Migrates settings from other sArena versions to sArena Reloaded
    
    This function handles the import process when users have multiple sArena versions installed
    and want to migrate their existing settings to sArena Reloaded. It searches for saved
    variables from other sArena versions, copies the data, and handles the addon switching.
]]
function sArenaMixin:ImportOtherForkSettings()
    -- Try to find the saved variables database from other sArena versions
    local oldDB = sArena3DB or sArena2DB or sArenaDB or sArena_MoPDB

    -- Validate that we found a valid database with the required structure
    -- Both profileKeys and profiles are essential for AceDB addon profiles
    if not oldDB or not oldDB.profileKeys or not oldDB.profiles then
        -- Display error message to user if no valid sArena database found
        sArenaMixin.conversionStatusText = "|cffFF0000No other sArena found. Are you sure it's enabled?|r"
        -- Refresh the config UI to show the error message
        LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        return
    end

    -- Get reference to sArena Reloaded's database
    local newDB = sArena_ReloadedDB

    -- Initialize the database structure if it doesn't exist yet
    -- This ensures we have the proper AceDB structure before migration
    if not newDB.profileKeys then newDB.profileKeys = {} end
    if not newDB.profiles then newDB.profiles = {} end

    -- Migrate all character profile assignments from old database
    for character, profileName in pairs(oldDB.profileKeys) do
        -- Append "(Imported)" to distinguish imported profiles from new ones
        -- This prevents conflicts and makes it clear which profiles came from the other version
        local newProfileName = profileName .. "(Imported)"
        newDB.profileKeys[character] = newProfileName

        -- Copy the actual profile data if it exists and hasn't been imported already
        if oldDB.profiles[profileName] and not newDB.profiles[newProfileName] then
            newDB.profiles[newProfileName] = CopyTable(oldDB.profiles[profileName])
        end
    end

    -- Ensure comp
    self:CompatibilityEnsurer()

    -- Ensure sArena Reloaded is enabled (should already be, but being safe)
    C_AddOns.EnableAddOn("sArena_Reloaded")

    -- Set flag to reopen the options panel after UI reload
    -- This provides better UX by returning the user to the config screen
    sArena_ReloadedDB.reOpenOptions = true

    -- Reload the UI to finalize the addon changes and load the imported settings
    ReloadUI()
end

function sArenaMixin:CompatibilityEnsurer()
    -- Disable any other active sArena versions due to compatibility issues, two sArenas cannot coexist
    -- This is only done with the user's specific consent by choosing to import as thoroughly explained in the GUI
    -- List of known sArena addon variants that needs to be disabled for compatibility's sake
    local otherSArenaVersions = {
        "sArena", -- Original
        "sArena Updated",
        "sArena_MoP",
        "sArena_Pinaclonada",
        "sArena_Updated2_by_sammers",
    }

    -- Ensure compatibility
    for _, addonName in ipairs(otherSArenaVersions) do
        if C_AddOns.IsAddOnLoaded(addonName) then
            C_AddOns.DisableAddOn(addonName)
        end
    end
end

local function TEMPShareCollectedData()
    if not sArena_ReloadedDB or not sArena_ReloadedDB.collectData then
        sArenaMixin:Print(L["DataCollection_NotEnabled"])
        return
    end

    local hasSpells = sArena_ReloadedDB.collectedSpells and next(sArena_ReloadedDB.collectedSpells) ~= nil
    local hasAuras = sArena_ReloadedDB.collectedAuras and next(sArena_ReloadedDB.collectedAuras) ~= nil

    if not hasSpells and not hasAuras then
        sArenaMixin:Print(L["DataCollection_NoDataYet"])
        return
    end

    if not sArenaMixin.DataExportFrame then
        local frame = CreateFrame("Frame", "sArenaDataExportFrame", UIParent, "BackdropTemplate")
        frame:SetSize(600, 500)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:SetBackdropColor(0, 0, 0, 1)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        -- Title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText(L["DataCollection_ExportTitle"])

        -- Close button
        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -5, -5)

        -- ScrollFrame for EditBox
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 20, -45)
        scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)

        -- EditBox
        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("ChatFontNormal")
        editBox:SetWidth(scrollFrame:GetWidth())
        editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
        scrollFrame:SetScrollChild(editBox)

        -- Select All button
        local selectAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        selectAllButton:SetSize(120, 25)
        selectAllButton:SetPoint("BOTTOM", 0, 15)
        selectAllButton:SetText(L["SelectAll"])
        selectAllButton:SetScript("OnClick", function()
            editBox:HighlightText()
            editBox:SetFocus()
        end)

        frame.editBox = editBox
        sArenaMixin.DataExportFrame = frame
    end

    local output = {}
    local totalCount = 0

    if hasSpells then
        table.insert(output, "-- Collected Spell Casts")
        table.insert(output, "sArenaMixin.collectedSpells = {")

        local sortedSpellIDs = {}
        for spellID in pairs(sArena_ReloadedDB.collectedSpells) do
            table.insert(sortedSpellIDs, spellID)
        end
        table.sort(sortedSpellIDs)

        for _, spellID in ipairs(sortedSpellIDs) do
            local data = sArena_ReloadedDB.collectedSpells[spellID]
            local spellName = data[1] or L["Unknown"]
            local sourceClass = data[2] or L["Unknown"]
            local type = data[3] or L["Unknown"]

            -- Escape special characters in spell name
            spellName = spellName:gsub("\\", "\\\\"):gsub('"', '\\"')

            table.insert(output, string.format('    [%d] = {"%s", "%s", "%s"}, -- %s',
                spellID, spellName, sourceClass, type, spellName))
        end

        table.insert(output, "}")
        table.insert(output, "")
        totalCount = totalCount + #sortedSpellIDs
    end

    if hasAuras then
        table.insert(output, "-- Collected Auras (Buffs/Debuffs)")
        table.insert(output, "sArenaMixin.collectedAuras = {")

        local sortedAuraIDs = {}
        for spellID in pairs(sArena_ReloadedDB.collectedAuras) do
            table.insert(sortedAuraIDs, spellID)
        end
        table.sort(sortedAuraIDs)

        for _, spellID in ipairs(sortedAuraIDs) do
            local data = sArena_ReloadedDB.collectedAuras[spellID]
            local spellName = data[1] or L["Unknown"]
            local sourceClass = data[2] or L["Unknown"]
            local auraType = data[3] or L["Unknown"]

            -- Escape special characters in spell name
            spellName = spellName:gsub("\\", "\\\\"):gsub('"', '\\"')

            table.insert(output, string.format('    [%d] = {"%s", "%s", "%s"}, -- %s',
                spellID, spellName, sourceClass, auraType, spellName))
        end

        table.insert(output, "}")
        totalCount = totalCount + #sortedAuraIDs
    end

    -- Join all lines
    local formattedData = table.concat(output, "\n")

    -- Set the text and show the frame
    sArenaMixin.DataExportFrame.editBox:SetText(formattedData)
    sArenaMixin.DataExportFrame:Show()

    -- Automatically select all text
    C_Timer.After(0.1, function()
        sArenaMixin.DataExportFrame.editBox:HighlightText()
        sArenaMixin.DataExportFrame.editBox:SetFocus()
    end)

    sArenaMixin:Print(L["DataCollection_ExportComplete"], totalCount)
end

local db
local emptyLayoutOptionsTable = {
    notice = {
        name = L["Message_NoLayoutSettings"],
        type = "description",
    }
}
local blizzFrame
local changedParent
local UpdateBlizzVisibility
if isRetail and not noEarlyFrames then
    UpdateBlizzVisibility = function()
        -- Hide Blizzard Arena Frames while in Arena
        if CompactArenaFrame.isHidden then return end
        CompactArenaFrame.isHidden = true
        local ArenaAntiMalware = CreateFrame("Frame")
        ArenaAntiMalware:Hide()

        --Event list
        local events = {
            "PLAYER_ENTERING_WORLD",
            "ZONE_CHANGED_NEW_AREA",
            "ARENA_OPPONENT_UPDATE",
            "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
            "PVP_MATCH_STATE_CHANGED"
        }

        -- Change parent and hide
        local function MalwareProtector()
            if InCombatLockdown() then return end
            local instanceType = select(2, IsInInstance())
            if instanceType == "arena" then
                CompactArenaFrame:SetParent(ArenaAntiMalware)
                CompactArenaFrameTitle:SetParent(ArenaAntiMalware)
            end
        end

        -- Event handler function
        ArenaAntiMalware:SetScript("OnEvent", function(self, event, ...)
            MalwareProtector()
            C_Timer.After(0, MalwareProtector)     --been instances of this god forsaken frame popping up so lets try to also do it one frame later
        end)

        -- Register the events
        for _, event in ipairs(events) do
            ArenaAntiMalware:RegisterEvent(event)
        end

        -- Shouldn't be needed, but you know what, fuck it
        CompactArenaFrame:HookScript("OnLoad", MalwareProtector)
        CompactArenaFrame:HookScript("OnShow", MalwareProtector)
        CompactArenaFrameTitle:HookScript("OnLoad", MalwareProtector)
        CompactArenaFrameTitle:HookScript("OnShow", MalwareProtector)

        MalwareProtector()
    end
else
    UpdateBlizzVisibility = function(instanceType)
        -- Hide Blizzard Arena Frames while in Arena
        if InCombatLockdown() then return end
        local prepFrame = _G["ArenaPrepFrames"]
        local enemyFrame = _G["ArenaEnemyFrames"]

        if (not blizzFrame) then
            blizzFrame = CreateFrame("Frame")
            blizzFrame:Hide()
        end

        if instanceType == "arena" then
            if prepFrame then
                prepFrame:SetParent(blizzFrame)
                changedParent = true
            end
            if enemyFrame then
                enemyFrame:SetParent(blizzFrame)
                changedParent = true
            end
        else
            if changedParent then
                if prepFrame then
                    prepFrame:SetParent(UIParent)
                end
                if enemyFrame then
                    enemyFrame:SetParent(UIParent)
                end
            end
        end
    end
end


function sArenaMixin:CheckClassStacking()
    local classCount = {}
    local classHasHealer = {}

    -- Count all players by class and track which classes have healers
    for i = 1, self.maxArenaOpponents do
        local frame = _G["sArenaEnemyFrame"..i]
        if frame.class then
            classCount[frame.class] = (classCount[frame.class] or 0) + 1
            if frame.isHealer then
                classHasHealer[frame.class] = true
            end
        end
    end

    -- Check if any class has multiple players AND at least one healer
    for class, count in pairs(classCount) do
        if count > 1 and classHasHealer[class] then
            return true
        end
    end

    return false
end


local function captureFont(fs)
    if not fs or not fs.GetFont then return nil end
    local path, size, flags = fs:GetFont()
    if not path then return nil end
    return { path, size, flags }
end
local function applyFont(fs, fontTbl)
    if fs and fontTbl and fontTbl[1] then
        fs:SetFont(fontTbl[1], fontTbl[2], fontTbl[3])
    end
end

function sArenaMixin:UpdateFonts()
    local fontCfg  = db.profile.layoutSettings[db.profile.currentLayout]
    if not fontCfg.changeFont then
        local og = sArenaMixin.ogFonts
        if og then
            for i = 1, sArenaMixin.maxArenaOpponents do
                local f = _G["sArenaEnemyFrame"..i]
                if f then
                    applyFont(f.Name,        og.Name)
                    applyFont(f.HealthText,  og.HealthText)
                    applyFont(f.SpecNameText, og.SpecNameText)
                    applyFont(f.PowerText,   og.PowerText)
                    applyFont(f.CastBar and f.CastBar.Text, og.CastBarText)
                    local fontName, s, o = f.CastBar.Text:GetFont()
                    f.CastBar.Text:SetFont(fontName, s, "THINOUTLINE")
                end
            end
            sArenaMixin.ogFonts = nil
        else
            for i = 1, sArenaMixin.maxArenaOpponents do
                local f = _G["sArenaEnemyFrame"..i]
                if f then
                    local fontName, s, o = f.CastBar.Text:GetFont()
                    f.CastBar.Text:SetFont(fontName, s, "THINOUTLINE")
                end
            end
        end
        return
    end
    local frameKey = fontCfg.frameFont
    local cdKey    = fontCfg.cdFont

    local frameFontPath = frameKey and LSM:Fetch(LSM.MediaType.FONT, frameKey) or nil
    --local cdFontPath    = cdKey   and LSM:Fetch(LSM.MediaType.FONT, cdKey)   or nil

    local size    = fontCfg.size or 10
    local outline = fontCfg.fontOutline
    if outline == nil then
        outline = "OUTLINE"
    end

    -- Check if modern + simple castbar is enabled
    local modernCastbars = fontCfg.castBar and fontCfg.castBar.useModernCastbars
    local simpleCastbar = fontCfg.castBar and fontCfg.castBar.simpleCastbar
    local forceOutlineOnCastbar = modernCastbars and simpleCastbar

    local function setFont(fs, path, isCastbarText)
        if fs and path and fs.SetFont then
            local _, s = fs:GetFont()
            local outlineToUse = outline

            -- Force outline on castbar text if modern + simple castbar is enabled
            if isCastbarText and forceOutlineOnCastbar and (outline == "" or outline == nil) then
                outlineToUse = "OUTLINE"
            end

            fs:SetFont(path, size, outlineToUse)
            if outlineToUse ~= "OUTLINE" and outlineToUse ~= "THICKOUTLINE" then
                fs:SetShadowOffset(1, -1)
            else
                fs:SetShadowOffset(0, 0)
            end
        end
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena"..i]
        if not frame or not frame.HealthBar then return end

        if frameFontPath then
            if not sArenaMixin.ogFonts then
                sArenaMixin.ogFonts = {
                    Name        = captureFont(frame.Name),
                    HealthText  = captureFont(frame.HealthText),
                    SpecNameText = captureFont(frame.SpecNameText),
                    PowerText   = captureFont(frame.PowerText),
                    CastBarText = captureFont(frame.CastBar and frame.CastBar.Text),
                }
            end
            setFont(frame.Name, frameFontPath)
            setFont(frame.HealthText, frameFontPath)
            setFont(frame.SpecNameText, frameFontPath)
            setFont(frame.PowerText,  frameFontPath)
            setFont(frame.CastBar.Text, frameFontPath, true)
        end
    end
end

function sArenaMixin:UpdateTextures()
    if not db then return end

    local layout = db.profile.layoutSettings[db.profile.currentLayout]
    local texKeys = layout.textures or {
        generalStatusBarTexture   = "sArena Default",
        healStatusBarTexture      = "sArena Stripes",
        castbarStatusBarTexture   = "sArena Default",
        castbarUninterruptibleTexture = "sArena Default",
        bgTexture = "Solid",
        bgColor = {0, 0, 0, 0.6},
    }

    local castTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
    local castUninterruptibleTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarUninterruptibleTexture or texKeys.castbarStatusBarTexture)
    local dpsTexture     = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.generalStatusBarTexture)
    local healerTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.healStatusBarTexture)
    local bgTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.bgTexture or "Solid")
    local bgColor = texKeys.bgColor or {0, 0, 0, 0.6}
    local modernCastbars            = layout.castBar.useModernCastbars
    local keepDefaultModernTextures = layout.castBar.keepDefaultModernTextures
    local interruptStatusColorOn     = layout.castBar.interruptStatusColorOn
    local classStacking = self:CheckClassStacking()
    local reverseBarsFill = db.profile.reverseBarsFill or false

    sArenaMixin.castTexture = castTexture
    sArenaMixin.castUninterruptibleTexture = castUninterruptibleTexture
    sArenaMixin.keepDefaultModernTextures = keepDefaultModernTextures
    sArenaMixin.modernCastbars = modernCastbars
    sArenaMixin.interruptStatusColorOn = interruptStatusColorOn
    if sArenaCastingBarExtensionMixin then
        sArenaCastingBarExtensionMixin.typeInfo = {
            filling = castTexture,
            full = castTexture,
            glow = castTexture
        }
    end

    -- Update castbar colors
    self:UpdateCastbarColors()

    for i = 1, self.maxArenaOpponents do
        local frame = _G["sArenaEnemyFrame" .. i]
        local textureToUse = dpsTexture

        if frame.isHealer then
            if layout.retextureHealerClassStackOnly then
                if classStacking then
                    textureToUse = healerTexture
                end
            else
                textureToUse = healerTexture
            end
        end

        frame.HealthBar:SetStatusBarTexture(textureToUse)
        frame.PowerBar:SetStatusBarTexture(dpsTexture)

        -- Set background texture and color
        if frame.HealthBar.hpUnderlay then
            frame.HealthBar.hpUnderlay:SetTexture(bgTexture)
            frame.HealthBar.hpUnderlay:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        end
        if frame.PowerBar.ppUnderlay then
            frame.PowerBar.ppUnderlay:SetTexture(bgTexture)
            frame.PowerBar.ppUnderlay:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        end

        frame.HealthBar:SetReverseFill(reverseBarsFill)
        frame.PowerBar:SetReverseFill(reverseBarsFill)

        if modernCastbars then
            if not keepDefaultModernTextures then
                frame.CastBar:SetStatusBarTexture(castTexture)
            end
        else
            frame.CastBar:SetStatusBarTexture(castTexture)
        end

        if db.profile.currentLayout == "BlizzRetail" then
            frame.PowerBar:GetStatusBarTexture():SetDrawLayer("BACKGROUND", 2)
        end
    end

    -- Refresh test mode castbars if test mode is active
    self:RefreshTestModeCastbars()
end

function sArenaFrameMixin:UpdateCombatStatus(unit)
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings or not widgetSettings.combatIndicator or not widgetSettings.combatIndicator.enabled then
        self.WidgetOverlay.combatIndicator:Hide()
        return
    end
    self.WidgetOverlay.combatIndicator:SetShown((unit and not UnitAffectingCombat(unit) and not self.DeathIcon:IsShown()))
end

function sArenaFrameMixin:UpdateTarget(unit)
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings or not widgetSettings.targetIndicator or not widgetSettings.targetIndicator.enabled then
        self.WidgetOverlay.targetIndicator:Hide()
        return
    end
    self.WidgetOverlay.targetIndicator:SetShown((unit and UnitIsUnit(unit, "target")))
end

function sArenaFrameMixin:UpdateFocus(unit)
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings or not widgetSettings.focusIndicator or not widgetSettings.focusIndicator.enabled then
        self.WidgetOverlay.focusIndicator:Hide()
        return
    end
    self.WidgetOverlay.focusIndicator:SetShown((unit and UnitIsUnit(unit, "focus")))
end

function sArenaFrameMixin:UpdatePartyTargets(unit)
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings or not widgetSettings.partyTargetIndicators or not widgetSettings.partyTargetIndicators.enabled then
        self.WidgetOverlay.partyTarget1:Hide()
        self.WidgetOverlay.partyTarget2:Hide()
        return
    end

    if not unit or not UnitExists(unit) then return end

    if isMidnight then
        local isParty1Target = UnitIsUnit("party1target", unit)
        local isParty2Target = UnitIsUnit("party2target", unit)

        local class1 = select(2, UnitClass("party1"))
        if class1 then
            local color = RAID_CLASS_COLORS[class1]
            self.WidgetOverlay.partyTarget1.Texture:SetVertexColor(color.r, color.g, color.b)
        end

        local class2 = select(2, UnitClass("party2"))
        if class2 then
            local color = RAID_CLASS_COLORS[class2]
            self.WidgetOverlay.partyTarget2.Texture:SetVertexColor(color.r, color.g, color.b)
        end

        self.WidgetOverlay.partyTarget1:Show()
        self.WidgetOverlay.partyTarget2:Show()
        self.WidgetOverlay.partyTarget1:SetAlphaFromBoolean(isParty1Target, 1, 0)
        self.WidgetOverlay.partyTarget2:SetAlphaFromBoolean(isParty2Target, 1, 0)
    else
        local targets = {}
        if UnitIsUnit("party1target", unit) then
            table.insert(targets, "party1")
        end
        if UnitIsUnit("party2target", unit) then
            table.insert(targets, "party2")
        end

        -- Update Icons Based on Targets Found
        if #targets >= 1 then
            local class1 = select(2, UnitClass(targets[1]))
            if class1 then
                local color = RAID_CLASS_COLORS[class1]
                self.WidgetOverlay.partyTarget1.Texture:SetVertexColor(color.r, color.g, color.b)
            end
            self.WidgetOverlay.partyTarget1:Show()
        else
            self.WidgetOverlay.partyTarget1:Hide()
        end

        if #targets >= 2 then
            local class2 = select(2, UnitClass(targets[2]))
            if class2 then
                local color = RAID_CLASS_COLORS[class2]
                self.WidgetOverlay.partyTarget2.Texture:SetVertexColor(color.r, color.g, color.b)
            end
            self.WidgetOverlay.partyTarget2:Show()
        else
            self.WidgetOverlay.partyTarget2:Hide()
        end
    end
end

local MAX_INCOMING_HEAL_OVERFLOW = 1.0;
function sArenaFrameMixin:UpdateHealPrediction()
    if isMidnight then return end
	if ( not self.myHealPredictionBar and not self.otherHealPredictionBar and not self.healAbsorbBar and not self.totalAbsorbBar ) then
		return;
	end

	local _, maxHealth = self.healthbar:GetMinMaxValues();
	local health = self.healthbar:GetValue();
	if ( maxHealth <= 0 ) then
		return;
	end

	local myIncomingHeal = UnitGetIncomingHeals(self.unit, "player") or 0;
	local allIncomingHeal = UnitGetIncomingHeals(self.unit) or 0;
	local totalAbsorb = UnitGetTotalAbsorbs(self.unit) or 0;

	local myCurrentHealAbsorb = 0;
	if ( self.healAbsorbBar ) then
		myCurrentHealAbsorb = UnitGetTotalHealAbsorbs(self.unit) or 0;

		--We don't fill outside the health bar with healAbsorbs.  Instead, an overHealAbsorbGlow is shown.
		if ( health < myCurrentHealAbsorb ) then
			self.overHealAbsorbGlow:Show();
			myCurrentHealAbsorb = health;
		else
			self.overHealAbsorbGlow:Hide();
		end
	end

	--See how far we're going over the health bar and make sure we don't go too far out of the self.
	if ( health - myCurrentHealAbsorb + allIncomingHeal > maxHealth * MAX_INCOMING_HEAL_OVERFLOW ) then
		allIncomingHeal = maxHealth * MAX_INCOMING_HEAL_OVERFLOW - health + myCurrentHealAbsorb;
	end

	local otherIncomingHeal = 0;

	--Split up incoming heals.
	if ( allIncomingHeal >= myIncomingHeal ) then
		otherIncomingHeal = allIncomingHeal - myIncomingHeal;
	else
		myIncomingHeal = allIncomingHeal;
	end

	--We don't fill outside the the health bar with absorbs.  Instead, an overAbsorbGlow is shown.
	local overAbsorb = false;
	if ( health - myCurrentHealAbsorb + allIncomingHeal + totalAbsorb >= maxHealth or health + totalAbsorb >= maxHealth ) then
		if ( totalAbsorb > 0 ) then
			overAbsorb = true;
		end

		if ( allIncomingHeal > myCurrentHealAbsorb ) then
			totalAbsorb = max(0,maxHealth - (health - myCurrentHealAbsorb + allIncomingHeal));
		else
			totalAbsorb = max(0,maxHealth - health);
		end
	end

	if ( overAbsorb ) then
		self.overAbsorbGlow:Show();
	else
		self.overAbsorbGlow:Hide();
	end

	local healthTexture = self.healthbar:GetStatusBarTexture();
	local myCurrentHealAbsorbPercent = 0;
	local healAbsorbTexture = nil;

	if ( self.healAbsorbBar ) then
		myCurrentHealAbsorbPercent = myCurrentHealAbsorb / maxHealth;

		--If allIncomingHeal is greater than myCurrentHealAbsorb, then the current
		--heal absorb will be completely overlayed by the incoming heals so we don't show it.
		if ( myCurrentHealAbsorb > allIncomingHeal ) then
			local shownHealAbsorb = myCurrentHealAbsorb - allIncomingHeal;
			local shownHealAbsorbPercent = shownHealAbsorb / maxHealth;

			healAbsorbTexture = self.healAbsorbBar:UpdateFillPosition(healthTexture, shownHealAbsorb, -shownHealAbsorbPercent);

			--If there are incoming heals the left shadow would be overlayed by the incoming heals
			--so it isn't shown.
			-- self.healAbsorbBar.LeftShadow:SetShown(allIncomingHeal <= 0);

			-- The right shadow is only shown if there are absorbs on the health bar.
			-- self.healAbsorbBar.RightShadow:SetShown(totalAbsorb > 0)
		else
			self.healAbsorbBar:Hide();
		end
	end

	--Show myIncomingHeal on the health bar.
	local incomingHealTexture;
	if ( self.myHealPredictionBar ) then
		incomingHealTexture = self.myHealPredictionBar:UpdateFillPosition(healthTexture, myIncomingHeal, -myCurrentHealAbsorbPercent);
	end

	local otherHealLeftTexture = (myIncomingHeal > 0) and incomingHealTexture or healthTexture;
	local xOffset = (myIncomingHeal > 0) and 0 or -myCurrentHealAbsorbPercent;

	--Append otherIncomingHeal on the health bar
	if ( self.otherHealPredictionBar ) then
		incomingHealTexture = self.otherHealPredictionBar:UpdateFillPosition(otherHealLeftTexture, otherIncomingHeal, xOffset);
	end

	--Append absorbs to the correct section of the health bar.
	local appendTexture = nil;
	if ( healAbsorbTexture ) then
		--If there is a healAbsorb part shown, append the absorb to the end of that.
		appendTexture = healAbsorbTexture;
	else
		--Otherwise, append the absorb to the end of the the incomingHeals or health part;
		appendTexture = incomingHealTexture or healthTexture;
	end

	if ( self.totalAbsorbBar ) then
		self.totalAbsorbBar:UpdateFillPosition(appendTexture, totalAbsorb);
	end
end

local ABSORB_GLOW_ALPHA = 0.6
local ABSORB_GLOW_OFFSET = -5
function sArenaFrameMixin:UpdateAbsorb()
    if isMidnight then return end

    local unit     = self.unit
    local healthBar     = self.HealthBar
    local absorbBar     = self.totalAbsorbBar
    local absorbOverlay = self.totalAbsorbBarOverlay
    local glow          = self.overAbsorbGlow

    local maxHealth = UnitHealthMax(unit)
    local totalAbsorb   = UnitGetTotalAbsorbs(unit) or 0

    if maxHealth <= 0 or totalAbsorb <= 0 then
        absorbBar:Hide()
        absorbOverlay:Hide()
        glow:Hide()
        return
    end

    local currentHealth = UnitHealth(unit)
    local healthWidth  = healthBar:GetWidth()
    local healthHeight = healthBar:GetHeight()
    local isReversed   = self.parent.db.profile.reverseBarsFill or false

    -- Default, no Overshields.
    if self.parent.db.profile.disableOvershields then
        local isOverAbsorb = (currentHealth + totalAbsorb >= maxHealth)

        -- Clamp absorbs to actual missing health
        local missingHealth = maxHealth - currentHealth
        totalAbsorb = math.min(totalAbsorb, missingHealth)

        if isOverAbsorb then
            glow:Show()
        else
            glow:Hide()
        end

        if totalAbsorb > 0 then
            local absorbWidth        = healthWidth * (totalAbsorb / maxHealth)
            local missingHealthWidth = (maxHealth - currentHealth) / maxHealth * healthWidth
            local absorbBarWidth     = math.min(absorbWidth, missingHealthWidth)

            absorbBar:ClearAllPoints()
            absorbOverlay:ClearAllPoints()
            if isReversed then
                absorbBar:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", missingHealthWidth, 0)
                absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0)
                absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0)
                if absorbOverlay.tileSize then
                    absorbOverlay:SetTexCoord(0, absorbBarWidth / absorbOverlay.tileSize, 0, healthHeight / absorbOverlay.tileSize)
                end
            else
                absorbBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", currentHealth / maxHealth * healthWidth, 0)
                absorbOverlay:SetPoint("TOPLEFT", absorbBar, "TOPLEFT", 0, 0)
                absorbOverlay:SetPoint("BOTTOMLEFT", absorbBar, "BOTTOMLEFT", 0, 0)
                if absorbOverlay.tileSize then
                    absorbOverlay:SetTexCoord(1 - (absorbBarWidth / absorbOverlay.tileSize), 1, 0, healthHeight / absorbOverlay.tileSize)
                end
            end

            absorbBar:SetSize(absorbBarWidth, healthHeight)
            absorbBar:Show()
            absorbOverlay:SetSize(absorbBarWidth, healthHeight)
            absorbOverlay:Show()
        else
            absorbBar:Hide()
            absorbOverlay:Hide()
        end
    else
        -- Overshields: wrapping overlay + overshield glow
        local isOverAbsorb = false

        if totalAbsorb > maxHealth then
            isOverAbsorb = true
            totalAbsorb = maxHealth
        else
            isOverAbsorb = (currentHealth + totalAbsorb > maxHealth)
        end

        local absorbWidth        = totalAbsorb / maxHealth * healthWidth
        local missingHealthWidth = (maxHealth - currentHealth) / maxHealth * healthWidth
        local absorbBarWidth     = math.min(absorbWidth, missingHealthWidth)

        -- Show absorb bar only for missing health
        if absorbBarWidth > 0 then
            absorbBar:ClearAllPoints()
            if isReversed then
                absorbBar:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", missingHealthWidth, 0)
            else
                absorbBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", currentHealth / maxHealth * healthWidth, 0)
            end
            absorbBar:SetSize(absorbBarWidth, healthHeight)
            absorbBar:Show()
        else
            absorbBar:Hide()
        end

        -- Show striped overlay for full absorb width (wraps onto filled health if needed)
        if absorbWidth > 0 then
            absorbOverlay:SetParent(healthBar)
            absorbOverlay:ClearAllPoints()
            if isReversed then
                if isOverAbsorb then
                    absorbOverlay:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", 0, 0)
                else
                    absorbOverlay:SetPoint("TOPLEFT", absorbBar, "TOPLEFT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMLEFT", absorbBar, "BOTTOMLEFT", 0, 0)
                end
            else
                if isOverAbsorb then
                    absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
                else
                    absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0)
                end
            end

            absorbOverlay:SetSize(absorbWidth, healthHeight)

            if absorbOverlay.tileSize then
                if isReversed then
                    absorbOverlay:SetTexCoord(0, absorbWidth / absorbOverlay.tileSize, 0, healthHeight / absorbOverlay.tileSize)
                else
                    absorbOverlay:SetTexCoord(1 - (absorbWidth / absorbOverlay.tileSize), 1, 0, healthHeight / absorbOverlay.tileSize)
                end
            end

            absorbOverlay:Show()
        else
            absorbOverlay:Hide()
        end

        -- Glow if over-absorb occurs
        glow:ClearAllPoints()
        if isOverAbsorb then
            if isReversed then
                glow:SetPoint("TOPRIGHT", absorbOverlay, "TOPRIGHT", -ABSORB_GLOW_OFFSET, 0)
                glow:SetPoint("BOTTOMRIGHT", absorbOverlay, "BOTTOMRIGHT", -ABSORB_GLOW_OFFSET, 0)
            else
                glow:SetPoint("TOPLEFT", absorbOverlay, "TOPLEFT", ABSORB_GLOW_OFFSET, 0)
                glow:SetPoint("BOTTOMLEFT", absorbOverlay, "BOTTOMLEFT", ABSORB_GLOW_OFFSET, 0)
            end
            glow:SetAlpha(ABSORB_GLOW_ALPHA)
            glow:Show()
        else
            glow:Hide()
        end
    end
end

function sArenaMixin:HandleArenaStart()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame:IsShown() then break end
        if UnitExists("arena"..i) then
            if noEarlyFrames then
                sArenaMixin.seenArenaUnits[i] = true
            end
            frame:UpdateVisible()
            frame:UpdatePlayer("seen")
        end
    end
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not UnitIsVisible("arena"..i) then
            frame:SetAlpha(stealthAlpha)
        end
    end
end

local matchStartedMessages = {
    ["The Arena battle has begun!"] = true, -- English / Default
    ["¡La batalla en arena ha comenzado!"] = true, -- esES / esMX
    ["A batalha na Arena começou!"] = true, -- ptBR
    ["Der Arenakampf hat begonnen!"] = true, -- deDE
    ["Le combat d'arène commence\194\160!"] = true, -- frFR
    ["Бой начался!"] = true, -- ruRU
    ["투기장 전투가 시작되었습니다!"] = true, -- koKR
    ["竞技场战斗开始了！"] = true, -- zhCN
    ["竞技场的战斗开始了！"] = true, -- zhCN (Wotlk)
    ["競技場戰鬥開始了！"] = true, -- zhTW
}

local function IsMatchStartedMessage(msg)
    return matchStartedMessages[msg]
end

local function EnsureArenaFramesEnabled()
    local accountSettings = EditModeManagerFrame and EditModeManagerFrame.AccountSettings
    if not accountSettings then return end

    local arenaFramesEnabled = EditModeManagerFrame:GetAccountSettingValueBool(Enum.EditModeAccountSetting.ShowArenaFrames)
    if not arenaFramesEnabled then
        EditModeManagerFrame:OnAccountSettingChanged(Enum.EditModeAccountSetting.ShowArenaFrames, true)
        EditModeManagerFrame.AccountSettings:RefreshArenaFrames()
    end
end

local function GetFactionTrinketIconByRace(race)
    local allianceRaces = {
        ["Human"] = true,
        ["Dwarf"] = true,
        ["NightElf"] = true,
        ["Gnome"] = true,
        ["Draenei"] = true,
        ["Worgen"] = true,
    }

    if allianceRaces[race] then
        return 133452  -- Alliance trinket
    else
        return 133453  -- Horde trinket
    end
end

function sArenaMixin:ShowMidnightDRWarning()
    if sArenaSkipDrWarning then return end
    if self.midnightWarningFrame then
        self.midnightWarningFrame:Show()
        return
    end

    local frame = CreateFrame("Frame", "sArenaMidnightWarningFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 200)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 70)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    frame:SetBackdropColor(0, 0, 0, 1)
    frame:EnableMouse(true)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText(L["Message_MidnightWarningTitle"])

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOP", title, "BOTTOM", 0, -15)
    text:SetWidth(400)
    text:SetJustifyH("CENTER")
    text:SetText(L["Message_MidnightWarningText"])

    local reloadButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    reloadButton:SetSize(150, 30)
    reloadButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    reloadButton:SetText(L["Button_ReloadUI"])
    reloadButton:SetScript("OnClick", function()
        EnsureArenaFramesEnabled()
        ReloadUI()
    end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    closeButton:SetSize(10,10)

    self.midnightWarningFrame = frame
    frame:Show()
end

-- Parent Frame
function sArenaMixin:OnLoad()
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    if not isMidnight then
        self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    end
end

local combatEvents = {
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_INTERRUPT"] = true,
    ["SPELL_AURA_REMOVED"] = true,
    ["SPELL_AURA_BROKEN"] = true,
    ["SPELL_AURA_REFRESH"] = true,
    ["SPELL_DISPEL"] = true,
}

function sArenaMixin:OnEvent(event, ...)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local _, combatEvent, _, sourceGUID, sourceName, _, _, destGUID, _, _, _, spellID, _, _, auraType = CombatLogGetCurrentEventInfo()
        if not combatEvents[combatEvent] then return end

        if combatEvent == "SPELL_CAST_SUCCESS" or combatEvent == "SPELL_AURA_APPLIED" then

            -- Old Arena Spec Detection
            if noEarlyFrames then

                -- TEMP DATACOLLECT
                if sArena_ReloadedDB.collectData then
                    local spellName = C_Spell.GetSpellName(spellID)
                    local _, sourceClass
                    if sourceGUID and select(1, strsplit("-", sourceGUID)) == "Player" then
                        _, sourceClass = GetPlayerInfoByGUID(sourceGUID)
                    else
                        local npcID = nil
                        if sourceGUID and type(sourceGUID) == "string" then
                            npcID = tonumber(sourceGUID:match("%-([0-9]+)%-%x+$"))
                        end
                        sourceClass = npcID and ("NPC:" .. npcID) or "NPC"
                    end

                    if combatEvent == "SPELL_CAST_SUCCESS" then
                        if not sArena_ReloadedDB.collectedSpells then
                            sArena_ReloadedDB.collectedSpells = {}
                        end
                        if not sArena_ReloadedDB.collectedSpells[spellID] then
                            sArena_ReloadedDB.collectedSpells[spellID] = {spellName, sourceClass, "CAST"}
                        end
                    elseif combatEvent == "SPELL_AURA_APPLIED" then
                        if not sArena_ReloadedDB.collectedAuras then
                            sArena_ReloadedDB.collectedAuras = {}
                        end
                        if not sArena_ReloadedDB.collectedAuras[spellID] then
                            sArena_ReloadedDB.collectedAuras[spellID] = {spellName, sourceClass, auraType}
                        end
                    end
                end
                -- TEMP DATACOLLECT

                if (sArenaMixin.specCasts[spellID] or sArenaMixin.specBuffs[spellID]) then
                    for i = 1, sArenaMixin.maxArenaOpponents do
                        if (sourceGUID == UnitGUID("arena" .. i)) then
                            local ArenaFrame = self["arena" .. i]
                            if ArenaFrame:CheckForSpecSpell(spellID) then
                                break
                            end
                        end
                    end
                end
            end

            -- Shadowsight
            if spellID == shadowSightID and db.profile.shadowSightTimer and not IsSoloShuffle() then
                self:OnShadowsightTaken()
            end

            -- Non-duration auras
            if castToAuraMap[spellID] and combatEvent == "SPELL_CAST_SUCCESS" then
                local auraID = castToAuraMap[spellID]
                sArenaMixin.activeNonDurationAuras[auraID] = GetTime()

                for i = 1, sArenaMixin.maxArenaOpponents do
                    local ArenaFrame = self["arena" .. i]
                    ArenaFrame:FindAura()
                end

                C_Timer.After(sArenaMixin.nonDurationAuras[auraID].duration, function()
                    sArenaMixin.activeNonDurationAuras[auraID] = nil
                end)
            end

            -- Racials
            if sArenaMixin.racialSpells[spellID] then
                for i = 1, sArenaMixin.maxArenaOpponents do
                    if (sourceGUID == UnitGUID("arena" .. i)) then
                        local ArenaFrame = self["arena" .. i]
                        ArenaFrame:FindRacial(spellID)
                    end
                end
            end

            -- TBC Stance Auras (not actual auras in TBC so needs to be manually tracked)
            if isTBC and sArenaMixin.stanceAuras[spellID] then
                for i = 1, sArenaMixin.maxArenaOpponents do
                    local unit = "arena" .. i
                    if (sourceGUID == UnitGUID(unit)) then
                        sArenaMixin.activeStanceAuras[unit] = spellID
                        local ArenaFrame = self[unit]
                        ArenaFrame:FindAura()
                        break
                    end
                end
            end
        end

        -- Dispels
        if combatEvent == "SPELL_DISPEL" then
            if sArenaMixin.dispelData[spellID] and db.profile.showDispels then
                for i = 1, sArenaMixin.maxArenaOpponents do
                    local ArenaFrame = self["arena" .. i]

                    local arenaGUID = UnitGUID("arena" .. i)
                    local petGUID = UnitGUID("arena" .. i .. "pet")

                    -- Check if dispel was cast by arena player or their pet
                    if sourceGUID == arenaGUID or (sourceGUID == petGUID and spellID == 119905) then
                        ArenaFrame:FindDispel(spellID)
                        break
                    end
                end
            end
        end

        -- DRs
        if sArenaMixin.drList[spellID] then
            for i = 1, sArenaMixin.maxArenaOpponents do
                if ( destGUID == UnitGUID("arena" .. i) and (auraType == "DEBUFF") ) then
                    local ArenaFrame = self["arena" .. i]
                    ArenaFrame:FindDR(combatEvent, spellID)
                    break
                end
            end
        end

        -- Interrupts
        if sArenaMixin.interruptList[spellID] then
            if combatEvent == "SPELL_INTERRUPT" or combatEvent == "SPELL_CAST_SUCCESS" then
                for i = 1, sArenaMixin.maxArenaOpponents do
                    if (destGUID == UnitGUID("arena" .. i)) then
                        local ArenaFrame = self["arena" .. i]
                        ArenaFrame:FindInterrupt(combatEvent, spellID, sourceName, sourceGUID)
                        break
                    end
                end
            end
        end

    elseif (event == "PLAYER_TARGET_CHANGED") then
        for i = 1, sArenaMixin.maxArenaOpponents do
            local frame = self["arena" .. i]
            frame:UpdateTarget(frame.unit)
        end

    elseif (event == "PLAYER_FOCUS_CHANGED") then
        for i = 1, sArenaMixin.maxArenaOpponents do
            local frame = self["arena" .. i]
            frame:UpdateFocus(frame.unit)
        end

    elseif (event == "UNIT_TARGET") then
        for i = 1, sArenaMixin.maxArenaOpponents do
            local frame = self["arena" .. i]
            frame:UpdatePartyTargets(frame.unit)
        end

    elseif (event == "PLAYER_LOGIN") then
        local _, instanceType = IsInInstance()
        if instanceType ~= "arena" then
            C_Timer.After(3, function()
                sArenaMixin.beenInArena = true
            end)
        end
        if isMidnight then
            C_CVar.SetCVar("spellDiminishPVPEnemiesEnabled", "1")
        end
        self:Initialize()
        if sArenaMixin:CompatibilityIssueExists() then return end
        self:UpdatePlayerSpec()
        self:SetupGrayTrinket()
        self:AddMasqueSupport()
        --self:SetupCustomCD()
        if sArena_ReloadedDB.reOpenOptions then
            sArena_ReloadedDB.reOpenOptions = nil
            C_Timer.After(0.5, function()
                LibStub("AceConfigDialog-3.0"):Open("sArena")
            end)
        end


        self:UnregisterEvent("PLAYER_LOGIN")
    elseif (event == "PLAYER_ENTERING_WORLD") then
        local _, instanceType = IsInInstance()
        UpdateBlizzVisibility(instanceType)
        self:SetMouseState(instanceType ~= "arena")

        if noEarlyFrames then
            sArenaMixin.seenArenaUnits = {}
            if instanceType == "arena" then
                sArenaMixin.justEnteredArena = true
                C_Timer.After(6, function()
                    sArenaMixin.justEnteredArena = nil
                end)
            else
                sArenaMixin.justEnteredArena = nil
            end
        end

        if isMidnight and not self.midnightDRFrames then
            self.midnightDRFrames = true
            self:InitializeDRFrames()
        end

        if not self.customCDText then
            self.customCDText = true
            self:SetupCustomCD()
        end

        if (instanceType == "arena") then
            if not isMidnight then
                self:ResetDetectedDispels()
                if isTBC then
                    wipe(sArenaMixin.activeStanceAuras)
                end
                self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
            else
                self:InitializeDRFrames()

                if not sArenaMixin.beenInArena then
                    sArenaMixin.beenInArena = true
                else
                    self:ShowMidnightDRWarning()
                end
            end
            self:RegisterWidgetEvents()
            self:RegisterInterruptEvents()
            self:UpdatePlayerSpec()
            if TestTitle then
                TestTitle:Hide()
                for i = 1, sArenaMixin.maxArenaOpponents do
                    local frame = self["arena" .. i]
                    frame.tempName = nil
                    frame.tempSpecName = nil
                    frame.tempClass = nil
                    frame.tempSpecIcon = nil
                    frame.isHealer = nil

                    if frame.fakeDRFrames then
                        for n = 1, 4 do
                            local fakeDRFrame = frame.fakeDRFrames[n]
                            if fakeDRFrame then
                                fakeDRFrame:Hide()
                            end
                        end
                    end
                end
            end
        else
            if not isMidnight then
                self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
            end
            self:UnregisterWidgetEvents()
            self:UnregisterInterruptEvents()
            self:ResetShadowsightTimer()
        end
    elseif event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        local msg = ...
        if IsMatchStartedMessage(msg) then
            C_Timer.After(0.5, function()
                self:HandleArenaStart()
            end)
            if db.profile.shadowSightTimer and not IsSoloShuffle() then
                self:StartShadowsightTimer(shadowsightStartTime)
            end
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdatePlayerSpec()
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        self:ResetDetectedDispels()
        if isTBC then
            wipe(sArenaMixin.activeStanceAuras)
        end
    end
end

local function ChatCommand(input)
    local cmd = (input or ""):trim():lower()
    if cmd == "" then
        LibStub("AceConfigDialog-3.0"):Open("sArena")
    elseif cmd == "convert" then
        sArenaMixin:ImportOtherForkSettings()
    elseif cmd == "ver" or cmd == "version" then
        sArenaMixin:Print(L["Print_CurrentVersion"], C_AddOns.GetAddOnMetadata("sArena_Reloaded", "Version"))
    elseif cmd:match("^test%s*[1-5]$") then
        sArenaMixin.testUnits = tonumber(cmd:match("(%d)"))
        input = "test"
        LibStub("AceConfigCmd-3.0").HandleCommand("sArena", "sarena", "sArena", input)
    else
        LibStub("AceConfigCmd-3.0").HandleCommand("sArena", "sarena", "sArena", input)
    end
end

function sArenaMixin:DatabaseCleanup(db)
    if not db then return end
    -- Migrate old swapHumanTrinket setting to new swapRacialTrinket
    if db.profile.swapHumanTrinket ~= nil and db.profile.swapRacialTrinket == nil then
        db.profile.swapRacialTrinket = db.profile.swapHumanTrinket
        db.profile.swapHumanTrinket = nil
    end

    -- Migrate old global DR settings
    if db.profile.drSwipeOff ~= nil then
        -- Migrate drSwipeOff to disableDRSwipe
        if db.profile.disableDRSwipe == nil then
            db.profile.disableDRSwipe = db.profile.drSwipeOff
        end
        db.profile.drSwipeOff = nil
    end

    if db.profile.drTextOn ~= nil then
        local drTextOn = db.profile.drTextOn

        -- Apply drTextOn to all layouts as showDRText
        if db.profile.layoutSettings then
            for layoutName, layoutSettings in pairs(db.profile.layoutSettings) do
                if layoutSettings.dr then
                    -- Only set if the old setting was true (enabled)
                    if drTextOn == true and layoutSettings.dr.showDRText == nil then
                        layoutSettings.dr.showDRText = true
                    end
                end
            end
        end

        -- Remove old global setting
        db.profile.drTextOn = nil
    end

    -- Migrate old global disableDRBorder setting
    if db.profile.disableDRBorder ~= nil then
        local disableDRBorder = db.profile.disableDRBorder

        -- Apply disableDRBorder to all layouts as disableDRBorder
        if db.profile.layoutSettings then
            for layoutName, layoutSettings in pairs(db.profile.layoutSettings) do
                if layoutSettings.dr then
                    -- Only set if the old setting was true (enabled) and new setting doesn't exist
                    if disableDRBorder == true and layoutSettings.dr.disableDRBorder == nil then
                        layoutSettings.dr.disableDRBorder = true
                    end
                end
            end
        end

        -- Remove old global setting
        db.profile.disableDRBorder = nil
    end

    -- Migrate Pixelated layout to use thickPixelBorder setting
    if db.profile.layoutSettings and db.profile.layoutSettings.Pixelated then
        local pixelatedDR = db.profile.layoutSettings.Pixelated.dr
        if pixelatedDR and pixelatedDR.thickPixelBorder == nil then
            -- Enable thickPixelBorder for existing Pixelated layout users
            pixelatedDR.thickPixelBorder = true
        end
    end

    -- Fix incorrect Stun DR icon on TBC (was 132298, should be 132092)
    if isTBC and not db.tbcStunIconFix then
        local oldIcon = 132298 -- Kidney Shot icon (incorrect)
        local newIcon = 132092 -- Correct Stun icon

        -- Fix global DR categories
        if db.profile.drCategories and db.profile.drCategories["Stun"] == oldIcon then
            db.profile.drCategories["Stun"] = newIcon
        end

        -- Fix per-spec DR categories
        if db.profile.drCategoriesSpec then
            for specID, categories in pairs(db.profile.drCategoriesSpec) do
                if categories["Stun"] == oldIcon then
                    categories["Stun"] = newIcon
                end
            end
        end

        -- Fix per-class DR categories
        if db.profile.drCategoriesClass then
            for class, categories in pairs(db.profile.drCategoriesClass) do
                if categories["Stun"] == oldIcon then
                    categories["Stun"] = newIcon
                end
            end
        end

        db.tbcStunIconFix = true
    end
end

function sArenaMixin:UpdatePlayerSpec()
    local currentSpec = isRetail and GetSpecialization() or C_SpecializationInfo.GetSpecialization()
    if currentSpec and currentSpec > 0 then
        local specID, specName
        if isRetail then
            specID, specName = GetSpecializationInfo(currentSpec)
        else
            specID, specName = C_SpecializationInfo.GetSpecializationInfo(currentSpec)
        end

        -- Only update if we actually got valid spec data
        if specID and specID > 0 and specName then
            sArenaMixin.playerSpecID = specID
            sArenaMixin.playerSpecName = specName
            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        end
    end
end

function sArenaMixin:UpdateNoTrinketTexture()
    if self.db.profile.removeUnequippedTrinketTexture then
        sArenaMixin.noTrinketTexture = nil
    else
        sArenaMixin.noTrinketTexture = "Interface\\AddOns\\sArena_Reloaded\\Textures\\inv_pet_exitbattle.tga"
    end
end

function sArenaMixin:Initialize()
    if (db) then return end

    local compatIssue = self:CompatibilityIssueExists()

    self.db = LibStub("AceDB-3.0"):New("sArena_ReloadedDB", self.defaultSettings, true)
    db = self.db

    db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self.optionsTable.handler = self
    self.optionsTable.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("sArena", self.optionsTable)
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("sArena", compatIssue and 520 or 860, compatIssue and 300 or 690)
    LibStub("AceConsole-3.0"):RegisterChatCommand("sarena", ChatCommand)
    LibStub("AceConsole-3.0"):RegisterChatCommand("sarenasend", TEMPShareCollectedData)
    if not compatIssue then
        self:DatabaseCleanup(db)
        if not isMidnight then
            self:UpdateDRTimeSetting()
        end
        self:UpdateDecimalThreshold()
        self:UpdateNoTrinketTexture()
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("sArena", "sArena |cffff8000Reloaded|r |T135884:13:13|t")
        self:SetLayout(_, db.profile.currentLayout)
    else
        C_Timer.After(5, function()
            sArenaMixin:Print(L["Print_MultipleVersionsLoaded"])
        end)
    end
end

function sArenaMixin:RefreshConfig()
    self:SetLayout(_, db.profile.currentLayout)
end

function sArenaMixin:ResetShadowsightTimer()
    if self.shadowsightTicker then
        self.shadowsightTicker:Cancel()
        self.shadowsightTicker = nil
    end
    if self.ShadowsightTimer then
        if self.ShadowsightTimer.Text then
            self.ShadowsightTimer.Text:SetText("")
        end
        self.ShadowsightTimer:Hide()
    end
    self.shadowsightTimers = {0, 0}
    self.shadowsightAvailable = 2
end

function sArenaMixin:StartShadowsightTimer(time)
    if self.shadowsightTicker then
        self.shadowsightTicker:Cancel()
        self.shadowsightTicker = nil
    end

    self.ShadowsightTimer:ClearAllPoints()
    if UIWidgetTopCenterContainerFrame then
        self.ShadowsightTimer:SetParent(UIWidgetTopCenterContainerFrame)
        self.ShadowsightTimer:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, 5)
    else
        self.ShadowsightTimer:SetPoint("TOP", UIParent, "TOP", 0, -100)
    end

    self.ShadowsightTimer:Show()

    local currentTime = GetTime()
    if isMidnight then
        -- On Midnight, just track spawn time and when to hide (35s after spawn)
        self.shadowsightTimers[1] = currentTime + time -- Time when eyes spawn
        self.shadowsightTimers[2] = currentTime + time + 35 -- Time to hide (35s after spawn)
        self.shadowsightAvailable = 0
    else
        self.shadowsightTimers[1] = currentTime + time
        self.shadowsightTimers[2] = currentTime + time
        self.shadowsightAvailable = 0
    end

    self.shadowsightTicker = C_Timer.NewTicker(0.1, function()
        self:UpdateShadowsightDisplay()
    end)
end

function sArenaMixin:OnShadowsightTaken()
    local currentTime = GetTime()
    local resetTime = currentTime + shadowsightResetTime

    if self.shadowsightTimers[1] <= 1 and self.shadowsightTimers[2] <= 1 then
        self.shadowsightTimers[1] = resetTime
        self.shadowsightTimers[2] = 0

        if not self.shadowsightTicker then
            self.ShadowsightTimer:ClearAllPoints()
            if UIWidgetTopCenterContainerFrame then
                self.ShadowsightTimer:SetParent(UIWidgetTopCenterContainerFrame)
                self.ShadowsightTimer:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, -10)
            else
                self.ShadowsightTimer:SetPoint("TOP", UIParent, "TOP", 0, -100)
            end
            self.ShadowsightTimer:Show()

            self.shadowsightTicker = C_Timer.NewTicker(0.1, function()
                self:UpdateShadowsightDisplay()
            end)
        end
    else
        if self.shadowsightAvailable > 0 then
            self.shadowsightAvailable = self.shadowsightAvailable - 1
        end

        if self.shadowsightTimers[1] <= currentTime then
            self.shadowsightTimers[1] = resetTime
        elseif self.shadowsightTimers[2] <= currentTime then
            self.shadowsightTimers[2] = resetTime
        end
    end

    self:UpdateShadowsightDisplay()
end

function sArenaMixin:UpdateShadowsightDisplay()
    local currentTime = GetTime()

    if isMidnight then
        -- On Midnight: Show countdown until spawn, then hide after 45 seconds
        local spawnTime = self.shadowsightTimers[1]
        local hideTime = self.shadowsightTimers[2]

        if currentTime >= hideTime then
            -- Hide after 35 seconds from spawn
            self:ResetShadowsightTimer()
            return
        elseif currentTime >= spawnTime then
            local iconTexture = "|T136155:15:15|t"
            self.ShadowsightTimer.Text:SetText(L["Shadowsight_Ready"] .. " " .. iconTexture .. " " .. iconTexture)
        else
            local timeLeft = math.ceil(spawnTime - currentTime)
            self.ShadowsightTimer.Text:SetText(string.format(L["Shadowsight_SpawnsIn"], timeLeft))
        end
        return
    end

    local availableCount = 0
    local shortestTimer = math.huge

    for i = 1, 2 do
        if self.shadowsightTimers[i] <= currentTime then
            availableCount = availableCount + 1
        else
            shortestTimer = math.min(shortestTimer, self.shadowsightTimers[i])
        end
    end

    self.shadowsightAvailable = availableCount

    local iconTexture = "|T136155:15:15|t"
    local text = ""

    if availableCount == 2 then
        text = "Shadowsights Ready " .. iconTexture .. " " .. iconTexture
    elseif availableCount == 1 then
        text = "Shadowsight Ready " .. iconTexture
    elseif shortestTimer < math.huge then
        local timeLeft = math.ceil(shortestTimer - currentTime)
        text = string.format("Shadowsight spawns in %d sec", timeLeft)
    else
        text = "Shadowsight"
    end

    self.ShadowsightTimer.Text:SetText(text)
end

function sArenaMixin:ApplyPrototypeFont(frame)
    local layout = db.profile.currentLayout
    local isProtoLayout = (layout == "Gladiuish" or layout == "Pixelated")
    local enable = isProtoLayout and not db.profile.layoutSettings[layout].changeFont

    if not enable and (not frame.changedFonts or next(frame.changedFonts) == nil) then
        return
    end

    if not frame.changedFonts then
        frame.changedFonts = {}
    end

    local function updateFont(obj, newSize, newFlags)
        if not obj then return end

        local currentFont, currentSize, currentFlags = obj:GetFont()

        if enable then
            -- Save original font only once
            if not frame.changedFonts[obj] then
                frame.changedFonts[obj] = { currentFont, currentSize, currentFlags }
            end

            obj:SetFont(sArenaMixin.pFont, newSize or currentSize, newFlags or currentFlags)
        else
            local original = frame.changedFonts[obj]
            if original then
                obj:SetFont(unpack(original))
                frame.changedFonts[obj] = nil
            end
        end
    end

    updateFont(frame.Name)
    updateFont(frame.SpecNameText, 9)
    updateFont(frame.HealthText)
    updateFont(frame.PowerText)
    updateFont(frame.CastBar and frame.CastBar.Text)
end

function sArenaFrameMixin:SetTextureCrop(texture, crop, type)
    if not texture then return end
    if type == "aura" then
        texture:SetTexCoord(0.03, 0.97, 0.03, 0.93)
    elseif type == "healer" then
        texture:SetTexCoord(0.205, 0.765, 0.22, 0.745)
    else
        if crop then
            texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            if type == "class" and db and ((db.profile.currentLayout == "BlizzRetail") or (db.profile.currentLayout == "BlizzArena")) then -- TODO: Fix this mess
                texture:SetTexCoord(0.05, 0.95, 0.1, 0.9)
            else
                texture:SetTexCoord(0, 1, 0, 1)
            end
        end
    end
end

function sArenaMixin:SetupGrayTrinket()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        local cooldown = frame.Trinket.Cooldown
        cooldown:HookScript("OnCooldownDone", function()
            frame.Trinket.Texture:SetDesaturated(false)
        end)
        local dispelCooldown = frame.Dispel.Cooldown
        dispelCooldown:HookScript("OnCooldownDone", function()
            if (frame.Dispel.spellID or 1) ~= 527 then
                frame.Dispel.Texture:SetDesaturated(false)
            end
        end)
    end
end

function sArenaMixin:UpdateDecimalThreshold()
    decimalThreshold = self.db.profile.decimalThreshold or 6
end

function sArenaMixin:CreateCustomCooldown(cooldown, showDecimals, isDR)
    local text = cooldown.sArenaText or cooldown:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    if not cooldown.sArenaText then
        cooldown.sArenaText = text

        if not cooldown.Text then
            for _, region in next, { cooldown:GetRegions() } do
                if region:GetObjectType() == "FontString" then
                    cooldown.Text = region;
                    cooldown.Text.fontFile = region:GetFont();
                end
            end
        end

        local f, s, o = cooldown.Text:GetFont()
        text:SetFont(f, s, o)

        local r, g, b, a = cooldown.Text:GetShadowColor()
        local x, y = cooldown.Text:GetShadowOffset()
        text:SetShadowColor(r, g, b, a)
        text:SetShadowOffset(x, y)

        text:SetPoint("CENTER", cooldown, "CENTER", 0, -1)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
    end

    local hideNumbers
    if isMidnight then
        hideNumbers = false
    else
        hideNumbers = showDecimals
    end
    cooldown:SetHideCountdownNumbers(hideNumbers)

    if showDecimals and not isMidnight then
        local lastUpdate = 0
        cooldown:SetScript("OnUpdate", function(self, elapsed)
            lastUpdate = lastUpdate + elapsed
            if lastUpdate < 0.1 then return end
            lastUpdate = 0

            local start, duration = cooldown:GetCooldownTimes()
            start, duration = start / 1000, duration / 1000
            local remaining = (start + duration) - GetTime()

            if remaining > 0 then
                if remaining < decimalThreshold then
                    text:SetFormattedText("%.1f", remaining)
                elseif remaining < 60 then
                    text:SetFormattedText("%d", remaining)
                elseif remaining < 3600 then
                    local m, s = math.floor(remaining / 60), math.floor(remaining % 60)
                    text:SetFormattedText("%d:%02d", m, s)
                else
                    text:SetFormattedText("%dh", math.floor(remaining / 3600))
                end
            else
                text:SetText("")
            end
        end)
    elseif isMidnight and isDR then
        cooldown:SetScript("OnUpdate", function(self)
            text:SetText(self.Text:GetText())
        end)
        cooldown.Text:SetAlpha(0)
    else
        cooldown:SetScript("OnUpdate", nil)
        text:SetText(nil)
    end
end

function sArenaMixin:SetupCustomCD()
    if C_AddOns.IsAddOnLoaded("OmniCC") then return end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        -- Class icon cooldown
        self:CreateCustomCooldown(frame.ClassIcon.Cooldown, self.db.profile.showDecimalsClassIcon)

        if isMidnight then
            if frame.drFrames then
                for _, drFrame in ipairs(frame.drFrames) do
                    if drFrame and drFrame.Cooldown then
                        self:CreateCustomCooldown(drFrame.Cooldown, self.db.profile.showDecimalsDR, true)
                    end
                end
            end
        else
            for _, category in ipairs(self.drCategories) do
                local drFrame = frame[category]
                if drFrame and drFrame.Cooldown then
                    self:CreateCustomCooldown(drFrame.Cooldown, self.db.profile.showDecimalsDR, true)
                end
            end
        end
    end
end


function sArenaMixin:DarkMode()
    return db.profile.darkMode
end

function sArenaMixin:DarkModeColor()
    return db.profile.darkModeValue
end

function sArenaFrameMixin:DarkModeFrame()
    if not sArenaMixin:DarkMode() then return end

    local darkModeColor = sArenaMixin:DarkModeColor()
    local lighter = darkModeColor + 0.1
    local shouldDesaturate = db.profile.darkModeDesaturate
    local skipClassIcon = db.profile.classColorFrameTexture

    local frameTexture = self.frameTexture
    local specBorder = self.SpecIcon.Border
    local trinketBorder = self.Trinket.Border
    local trinketCircleBorder = self.Trinket.CircleBorder
    local racialBorder = self.Racial.Border
    local dispelBorder = self.Dispel.Border
    local castBorder = self.CastBar.Border
    local classIconBorder = self.ClassIcon.Texture.Border
    local castBackground = self.CastBar.Background

    if frameTexture then
        frameTexture:SetDesaturated(shouldDesaturate)
        frameTexture:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if specBorder then
        specBorder:SetDesaturated(shouldDesaturate)
        specBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
        if db.profile.currentLayout == "BlizzCompact" then
            local darkerCol = darkModeColor - 0.25
            specBorder:SetVertexColor(darkerCol, darkerCol, darkerCol)
        else
            specBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
        end
    end
    if classIconBorder and not skipClassIcon then
        classIconBorder:SetDesaturated(shouldDesaturate)
        classIconBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if castBorder then
        castBorder:SetDesaturated(shouldDesaturate)
        castBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if castBackground then
        castBackground:SetDesaturated(shouldDesaturate)
        castBackground:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if trinketBorder then
        trinketBorder:SetDesaturated(shouldDesaturate)
        trinketBorder:SetVertexColor(lighter, lighter, lighter)
    end
    if trinketCircleBorder then
        trinketCircleBorder:SetDesaturated(shouldDesaturate)
        trinketCircleBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if racialBorder then
        racialBorder:SetDesaturated(shouldDesaturate)
        racialBorder:SetVertexColor(lighter, lighter, lighter)
    end
    if dispelBorder then
        dispelBorder:SetDesaturated(shouldDesaturate)
        dispelBorder:SetVertexColor(lighter, lighter, lighter)
    end

end

function sArenaFrameMixin:ClassColorFrameTexture()
    if not db.profile.classColorFrameTexture then return end

    local class = self.class or self.tempClass
    local color = RAID_CLASS_COLORS[class]

    if not color then return end

    local onlyClassIcon = db.profile.classColorFrameTextureOnlyClassIcon and db.profile.currentLayout == "BlizzCompact"
    local healerGreen = db.profile.classColorFrameTextureHealerGreen
    local isHealerGreen = healerGreen and self.isHealer

    local finalColor = color
    if isHealerGreen then
        finalColor = { r = 0, g = 1, b = 0 }
    end

    local frameTexture = self.frameTexture
    local specBorder = self.SpecIcon.Border
    local trinketBorder = self.Trinket.Border
    local racialBorder = self.Racial.Border
    local dispelBorder = self.Dispel.Border
    local castBorder = self.CastBar.Border
    local classIconBorder = self.ClassIcon.Texture.Border

    if classIconBorder then
        classIconBorder:SetDesaturated(true)
        classIconBorder:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
    end

    if onlyClassIcon then
        if sArenaMixin:DarkMode() then
            local darkModeColor = sArenaMixin:DarkModeColor()
            local lighter = darkModeColor + 0.1
            local shouldDesaturate = db.profile.darkModeDesaturate

            if frameTexture then
                frameTexture:SetDesaturated(shouldDesaturate)
                frameTexture:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
            end
            if specBorder then
                specBorder:SetDesaturated(shouldDesaturate)
                if db.profile.currentLayout == "BlizzCompact" then
                    local darkerCol = darkModeColor - 0.25
                    specBorder:SetVertexColor(darkerCol, darkerCol, darkerCol)
                else
                    specBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
                end
            end
            if castBorder then
                castBorder:SetDesaturated(shouldDesaturate)
                castBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
            end
            if trinketBorder then
                trinketBorder:SetDesaturated(shouldDesaturate)
                trinketBorder:SetVertexColor(lighter, lighter, lighter)
            end
            if racialBorder then
                racialBorder:SetDesaturated(shouldDesaturate)
                racialBorder:SetVertexColor(lighter, lighter, lighter)
            end
            if dispelBorder then
                dispelBorder:SetDesaturated(shouldDesaturate)
                dispelBorder:SetVertexColor(lighter, lighter, lighter)
            end
        end
    else
        if frameTexture then
            frameTexture:SetDesaturated(true)
            frameTexture:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if specBorder then
            specBorder:SetDesaturated(true)
            specBorder:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if castBorder then
            castBorder:SetDesaturated(true)
            castBorder:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if trinketBorder then
            trinketBorder:SetDesaturated(true)
            local lighter_r = math.min(1, finalColor.r + 0.2)
            local lighter_g = math.min(1, finalColor.g + 0.2)
            local lighter_b = math.min(1, finalColor.b + 0.2)
            trinketBorder:SetVertexColor(lighter_r, lighter_g, lighter_b)
        end
        if racialBorder then
            racialBorder:SetDesaturated(true)
            local lighter_r = math.min(1, finalColor.r + 0.2)
            local lighter_g = math.min(1, finalColor.g + 0.2)
            local lighter_b = math.min(1, finalColor.b + 0.2)
            racialBorder:SetVertexColor(lighter_r, lighter_g, lighter_b)
        end
        if dispelBorder then
            dispelBorder:SetDesaturated(true)
            local lighter_r = math.min(1, finalColor.r + 0.2)
            local lighter_g = math.min(1, finalColor.g + 0.2)
            local lighter_b = math.min(1, finalColor.b + 0.2)
            dispelBorder:SetVertexColor(lighter_r, lighter_g, lighter_b)
        end
    end

    if self.PixelBorders and sArenaMixin.showPixelBorder then
        local pixelBorders = self.PixelBorders
        if pixelBorders.main then
            pixelBorders.main:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if pixelBorders.classIcon then
            pixelBorders.classIcon:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if pixelBorders.trinket then
            pixelBorders.trinket:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if pixelBorders.racial then
            pixelBorders.racial:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if pixelBorders.dispel then
            pixelBorders.dispel:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if self.SpecIcon and self.SpecIcon.specIcon then
            self.SpecIcon.specIcon:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if self.CastBar then
            if self.CastBar.castBar then
                self.CastBar.castBar:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
            end
            if self.CastBar.castBarIcon then
                self.CastBar.castBarIcon:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
            end
        end
    end
end

function sArenaFrameMixin:ResetPixelBorders()
    if self.PixelBorders and sArenaMixin.showPixelBorder then
        local pixelBorders = self.PixelBorders

        if pixelBorders.main then
            pixelBorders.main:SetVertexColor(0, 0, 0)
        end
        if pixelBorders.classIcon then
            pixelBorders.classIcon:SetVertexColor(0, 0, 0)
        end
        if pixelBorders.trinket then
            pixelBorders.trinket:SetVertexColor(0, 0, 0)
        end
        if pixelBorders.racial then
            pixelBorders.racial:SetVertexColor(0, 0, 0)
        end
        if pixelBorders.dispel then
            pixelBorders.dispel:SetVertexColor(0, 0, 0)
        end
        if self.SpecIcon and self.SpecIcon.specIcon then
            self.SpecIcon.specIcon:SetVertexColor(0, 0, 0)
        end
        if self.CastBar then
            if self.CastBar.castBar then
                self.CastBar.castBar:SetVertexColor(0, 0, 0)
            end
            if self.CastBar.castBarIcon then
                self.CastBar.castBarIcon:SetVertexColor(0, 0, 0)
            end
        end
    end
end

function sArenaFrameMixin:UpdateFrameColors()
    if db.profile.classColorFrameTexture then
        self:ClassColorFrameTexture()
    elseif sArenaMixin:DarkMode() then
        self:DarkModeFrame()
        self:ResetPixelBorders()
    else
        if self.frameTexture then
            self.frameTexture:SetDesaturated(false)
            self.frameTexture:SetVertexColor(1, 1, 1)
        end
        if self.SpecIcon.Border then
            if db.profile.currentLayout == "BlizzCompact" then
                self.SpecIcon.Border:SetDesaturated(true)
                self.SpecIcon.Border:SetVertexColor(0, 0, 0)
            else
                self.SpecIcon.Border:SetDesaturated(false)
                self.SpecIcon.Border:SetVertexColor(1, 1, 1)
            end
        end
        if self.ClassIcon.Texture.Border then
            self.ClassIcon.Texture.Border:SetDesaturated(false)
            self.ClassIcon.Texture.Border:SetVertexColor(1, 1, 1)
        end
        if self.CastBar.Border then
            self.CastBar.Border:SetDesaturated(false)
            self.CastBar.Border:SetVertexColor(1, 1, 1)
        end
        if self.Trinket.Border then
            self.Trinket.Border:SetDesaturated(false)
            self.Trinket.Border:SetVertexColor(1, 1, 1)
        end
        if self.Racial.Border then
            self.Racial.Border:SetDesaturated(false)
            self.Racial.Border:SetVertexColor(1, 1, 1)
        end
        self:ResetPixelBorders()
    end
end

function sArenaMixin:SetLayout(_, layout)
    if (InCombatLockdown()) then return end

    if not self.db then
        self.db = db
    end
    if not self.arena1 then
        for i = 1, sArenaMixin.maxArenaOpponents do
            local globalName = "sArenaEnemyFrame" .. i
            self["arena" .. i] = _G[globalName]
        end
    end

    sArenaMixin.showTrinketCircleBorder = nil

    layout = sArenaMixin.layouts[layout] and layout or "Gladiuish"

    -- Detect if this is a user-initiated layout change (not from addon load)
    local oldLayout = db.profile.currentLayout
    local isUserChange = oldLayout ~= nil and oldLayout ~= layout

    -- Handle BlizzRaid layout hideClassIcon setting
    if isUserChange then
        if layout == "BlizzRaid" then
            -- Store the previous hideClassIcon value before changing to BlizzRaid
            if not db.profile.hideClassIconBeforeBlizzRaid then
                db.profile.hideClassIconBeforeBlizzRaid = db.profile.hideClassIcon
            end
            db.profile.hideClassIcon = true
        elseif oldLayout == "BlizzRaid" then
            -- Restore the previous hideClassIcon value when leaving BlizzRaid
            if db.profile.hideClassIconBeforeBlizzRaid ~= nil then
                db.profile.hideClassIcon = db.profile.hideClassIconBeforeBlizzRaid
                db.profile.hideClassIconBeforeBlizzRaid = nil
            else
                db.profile.hideClassIcon = false
            end
        end
    end

    if layout == "BlizzRaid" or layout == "Pixelated" then
        sArenaMixin.showPixelBorder = true
    else
        sArenaMixin.showPixelBorder = false
    end

    db.profile.currentLayout = layout
    self.layoutdb = self.db.profile.layoutSettings[layout]

    self:RemovePixelBorders()

    self:UpdateTextures()

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame:ResetLayout()
        self.layouts[layout]:Initialize(frame)
        frame:UpdatePlayer()
        sArenaMixin:ApplyPrototypeFont(frame)
        frame:UpdateClassIconCooldownReverse()
        frame:UpdateTrinketRacialCooldownReverse()
        frame:UpdateClassIconSwipeSettings()
        frame:UpdateTrinketRacialSwipeSettings()
        frame:UpdateFrameColors()
        frame:UpdateNameColor()
    end

    self:ModernOrClassicCastbar()
    self:UpdateFonts()
    self:UpdateCastBarSettings(self.layoutdb.castBar)

    self.optionsTable.args.layoutSettingsGroup.args = self.layouts[layout].optionsTable and self.layouts[layout].optionsTable or emptyLayoutOptionsTable
    LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")

    local _, instanceType = IsInInstance()
    if (instanceType ~= "arena" and self.arena1:IsShown()) then
        self:Test()
    end
end

function sArenaMixin:SetupDrag(frameToClick, frameToMove, settingsTable, updateMethod, isWidget)
    if frameToClick.dragSetup then return end
    frameToClick:HookScript("OnMouseDown", function()
        if (InCombatLockdown()) then return end

        if (IsShiftKeyDown() and IsControlKeyDown() and not frameToMove.isMoving) then
            if isWidget then
                frameToMove.dragStartX, frameToMove.dragStartY = frameToMove:GetCenter()
            end
            frameToMove:StartMoving()
            frameToMove.isMoving = true
        end
    end)

    frameToClick:HookScript("OnMouseUp", function()
        if (InCombatLockdown()) then return end

        if (frameToMove.isMoving) then
            frameToMove:StopMovingOrSizing()
            frameToMove.isMoving = false

            local settings

            if isWidget then
                settings = db.profile.layoutSettings[db.profile.currentLayout].widgets
                if not settings then return end
                if not settings[settingsTable] then
                    settings[settingsTable] = {}
                end
                settings = settings[settingsTable]
            else
                settings = db.profile.layoutSettings[db.profile.currentLayout]
                if (settingsTable) then
                    settings = settings[settingsTable]
                end
            end

            if isWidget then
                local newX, newY = frameToMove:GetCenter()
                local scale = frameToMove:GetScale()
                local deltaX = ((newX - frameToMove.dragStartX) * scale) / scale
                local deltaY = ((newY - frameToMove.dragStartY) * scale) / scale

                local currentX = settings.posX or 0
                local currentY = settings.posY or 0

                settings.posX = floor((currentX + deltaX) * 10 + 0.5) / 10
                settings.posY = floor((currentY + deltaY) * 10 + 0.5) / 10

                frameToMove.dragStartX = nil
                frameToMove.dragStartY = nil

                local widgetsSettings = db.profile.layoutSettings[db.profile.currentLayout].widgets
                self:UpdateWidgetSettings(widgetsSettings)
            else
                local frameX, frameY = frameToMove:GetCenter()
                local parentX, parentY = frameToMove:GetParent():GetCenter()
                local scale = frameToMove:GetScale()

                frameX = ((frameX * scale) - parentX) / scale
                frameY = ((frameY * scale) - parentY) / scale

                frameX = floor(frameX * 10 + 0.5) / 10
                frameY = floor(frameY * 10 + 0.5) / 10

                settings.posX, settings.posY = frameX, frameY
                self[updateMethod](self, settings)
            end

            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        end
    end)
    frameToClick.dragSetup = true
end

function sArenaMixin:SetMouseState(state)
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame.CastBar then
            frame.CastBar:EnableMouse(state)
        end

        if isMidnight and frame.drTray then
            frame.drTray:EnableMouse(false)
            frame.drTray:SetMouseClickEnabled(false)
            if frame.drFrames then
                for _, drFrame in ipairs(frame.drFrames) do
                    if drFrame then
                        drFrame:EnableMouse(false)
                        drFrame:SetMouseClickEnabled(false)
                    end
                end
            end
        end

        if not isMidnight and sArenaMixin.drCategories then
            for _, category in ipairs(sArenaMixin.drCategories) do
                local drFrame = frame[category]
                if drFrame then
                    drFrame:EnableMouse(state)
                end
            end
        end

        frame.SpecIcon:EnableMouse(state)
        frame.Trinket:EnableMouse(state)
        frame.Racial:EnableMouse(state)
        frame.Dispel:EnableMouse(state)
        frame.ClassIcon:EnableMouse(state)

        for _, child in pairs({frame.WidgetOverlay:GetChildren()}) do
            child:EnableMouse(state)
        end

        if noEarlyFrames and not InCombatLockdown() then
            local shouldEnableMouse
            if state then
                -- Outside arena: always clickable
                shouldEnableMouse = true
            else
                -- Inside arena: only clickable up to party size
                local partySize = GetNumGroupMembers() or 2
                shouldEnableMouse = (i <= partySize)
            end

            frame:EnableMouse(shouldEnableMouse)
        end
    end
end


local function ResetTexture(texturePool, t)
    if (texturePool) then
        t:SetParent(texturePool.parent)
    end

    t:SetTexture(nil)
    t:SetColorTexture(0, 0, 0, 0)
    t:SetVertexColor(1, 1, 1, 1)
    t:SetDesaturated(false)
    t:SetTexCoord(0, 1, 0, 1)
    t:ClearAllPoints()
    t:SetSize(0, 0)
    t:Hide()
end

function sArenaMixin:RegisterWidgetEvents()
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets

    self:UnregisterWidgetEvents()

    if widgetSettings then
        if widgetSettings.targetIndicator and widgetSettings.targetIndicator.enabled then
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
        end

        if widgetSettings.focusIndicator and widgetSettings.focusIndicator.enabled then
            self:RegisterEvent("PLAYER_FOCUS_CHANGED")
        end

        if widgetSettings.partyTargetIndicators and widgetSettings.partyTargetIndicators.enabled then
            self:RegisterEvent("UNIT_TARGET")
        end

        if widgetSettings.combatIndicator and widgetSettings.combatIndicator.enabled then
            for i = 1, sArenaMixin.maxArenaOpponents do
                local frame = self["arena" .. i]
                local unit = frame.unit
                self:RegisterUnitEvent("UNIT_FLAGS", unit)
            end
        end
    end
end

function sArenaMixin:UnregisterWidgetEvents()
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    self:UnregisterEvent("UNIT_TARGET")
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        local unit = frame.unit
        self:UnregisterEvent("UNIT_FLAGS", unit)
    end
end

function sArenaFrameMixin:CreateCastBar()
    self.CastBar = CreateFrame("StatusBar", nil, self, "sArenaCastBarFrameTemplate")
end

function sArenaFrameMixin:CreateDRFrames()
    local id = self:GetID()
    for _, category in ipairs(sArenaMixin.drCategories) do
        local name = "sArenaEnemyFrameDR" .. id .. category
        local drFrame = CreateFrame("Frame", name, self, "sArenaDRFrameTemplate")
        self[category] = drFrame
    end
end

local function HideChargeTiers(castBar)
    castBar.ChargeTier1:Hide()
    castBar.ChargeTier2:Hide()
    castBar.ChargeTier3:Hide()
    if castBar.ChargeTier4 then
        castBar.ChargeTier4:Hide()
    end
end

function sArenaFrameMixin:OnLoad()
    if sArenaMixin:CompatibilityIssueExists() then return end
    local unit = "arena" .. self:GetID()
    self.parent = self:GetParent()

    if noEarlyFrames then
        self.ogSetShown = self.SetShown
        self.SetShown = function(self, show)
            local _, instanceType = IsInInstance()
            self.shouldBeShown = show
            if show then
                self:SetAlpha(1)
            else
                self:SetAlpha(0)
            end
            if not InCombatLockdown() and instanceType ~= "arena" then
                self.ogSetShown(self, show)
            end
        end
        self.ogShow = self.Show
        self.Show = function(self)
            local _, instanceType = IsInInstance()
            self.shouldBeShown = true
            self:SetAlpha(1)
            if not InCombatLockdown() and instanceType ~= "arena" then
                self.ogShow(self)
            end
        end

        self.ogHide = self.Hide
        self.Hide = function(self)
            local _, instanceType = IsInInstance()
            self.shouldBeShown = false
            self:SetAlpha(0)
            if not InCombatLockdown() and instanceType ~= "arena" then
                self.ogHide(self)
            end
        end

        self.ogSetAlpha = self.SetAlpha
        self.SetAlpha = function(self, alpha)
            if self.shouldBeShown == false then
                self.ogSetAlpha(self, 0)
            else
                self.ogSetAlpha(self, alpha)
            end
        end
    end

    if not isMidnight then
        self:CreateCastBar()
        self:CreateDRFrames()
        self:RegisterUnitEvent("UNIT_AURA", unit)
        self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
        self:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit)
        if isRetail or isTBC then
            self.CastBar.empoweredFix = true
            self.CastBar:SetUnit(unit, false, true)
        else
            CastingBarFrame_SetUnit(self.CastBar, unit, false, true)
        end
    else
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. self:GetID()]
        self.CastBar = blizzArenaFrame.CastingBarFrame
        self.CastBar:SetFrameStrata("HIGH")
        self.totalAbsorbBar:Hide()
        self.overAbsorbGlow:Hide()
        self.overHealAbsorbGlow:Hide()
        self.otherHealPredictionBar:Hide()
        self.totalAbsorbBarOverlay:Hide()
        self.myHealPredictionBar:Hide()
        local healthBar = self.HealthBar

        local debuffFrame = blizzArenaFrame.DebuffFrame
        if debuffFrame then
            hooksecurefunc(debuffFrame.Icon, "SetTexture", function(_, tex)
                if tex == "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK.BLP" or (db and db.profile.disableAurasOnClassIcon) then
                    self:UpdateClassIcon(true)
                else
                    self.ClassIcon.Texture:SetTexture(tex)
                end
            end)
            hooksecurefunc(debuffFrame.Cooldown, "SetCooldown", function(_, start, duration)
                if (db and db.profile.disableAurasOnClassIcon) then return end
                self.ClassIcon.Cooldown:SetCooldown(start, duration)
            end)
        end
        local trinketFrame = blizzArenaFrame.CcRemoverFrame
        if trinketFrame then
            trinketFrame:SetParent(self)
            trinketFrame:SetAlpha(0)
            hooksecurefunc(trinketFrame.Cooldown, "SetCooldown", function(_, start, duration)
                self.Trinket.Cooldown:SetCooldown(start, duration)
                self.Trinket.Texture:SetDesaturated(db and db.profile.desaturateTrinketCD)
            end)
        end

        -- local ogOverabsorb = blizzArenaFrame.overAbsorbGlow
        -- ogOverabsorb:ClearAllPoints()
        -- ogOverabsorb:SetPoint("TOP", healthBar, "TOPRIGHT", 0, 0)
        -- ogOverabsorb:SetPoint("BOTTOM", healthBar, "BOTTOMRIGHT", 0, 0)
        -- ogOverabsorb:SetParent(healthBar)
        -- ogOverabsorb:Hide()
        -- hooksecurefunc(ogOverabsorb, "SetPoint", function(self)
        --     if self.changing then return end
        --     self.changing = true
        --     self:ClearAllPoints()
        --     self:SetPoint("TOP", healthBar, "TOPRIGHT", 0, 0)
        --     self:SetPoint("BOTTOM", healthBar, "BOTTOMRIGHT", 0, 0)
        --     self.changing = false
        -- end)
    end

    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_NAME_UPDATE")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
    self:RegisterUnitEvent("UNIT_HEALTH", unit)
    self:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    self:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
    self:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    self:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
    self:RegisterForClicks("AnyDown", "AnyUp")
    self:SetAttribute("*type1", "target")
    self:SetAttribute("*type2", "focus")
    self:SetAttribute("unit", unit)
    self.unit = unit

    local CastStopEvents  = {
        UNIT_SPELLCAST_STOP                = true,
        UNIT_SPELLCAST_CHANNEL_STOP        = true,
        UNIT_SPELLCAST_INTERRUPTED         = true,
        UNIT_SPELLCAST_EMPOWER_STOP        = true,
    }

    self.CastBar:HookScript("OnEvent", function(castBar, event, eventUnit)
        if CastStopEvents[event] and eventUnit == unit then
            if castBar.interruptedBy then
                castBar:Show()
            else
                local cast = UnitCastingInfo(unit) or UnitChannelInfo(unit)
                if not cast then
                    castBar:Hide()
                    if isRetail then
                        return
                    end
                end
            end
        end
        sArenaMixin:CastbarOnEvent(self.CastBar)
    end)

    self.healthbar = self.HealthBar

    self.myHealPredictionBar:ClearAllPoints()
    self.otherHealPredictionBar:ClearAllPoints()
    self.totalAbsorbBar:ClearAllPoints()
    self.overAbsorbGlow:ClearAllPoints()
    self.overHealAbsorbGlow:ClearAllPoints()

    self.totalAbsorbBar:SetTexture(self.totalAbsorbBar.fillTexture)
    self.totalAbsorbBar:SetVertexColor(1, 1, 1)
    self.totalAbsorbBar:SetHeight(self.healthbar:GetHeight())

    self.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
    self.overAbsorbGlow:SetBlendMode("ADD")
    self.overAbsorbGlow:SetPoint("TOPLEFT", self.healthbar, "TOPRIGHT", -7, 0)
    self.overAbsorbGlow:SetPoint("BOTTOMLEFT", self.healthbar, "BOTTOMRIGHT", -7, 0)

    self.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", self.healthbar, "BOTTOMLEFT", 7, 0)
    self.overHealAbsorbGlow:SetPoint("TOPRIGHT", self.healthbar, "TOPLEFT", 7, 0)

    self.AuraStacks:SetTextColor(1,1,1,1)
    self.AuraStacks:SetJustifyH("LEFT")
    self.AuraStacks:SetJustifyV("BOTTOM")

    self.DispelStacks:SetTextColor(1,1,1,1)
    self.DispelStacks:SetJustifyH("LEFT")
    self.DispelStacks:SetJustifyV("BOTTOM")

    if not self.Dispel.Overlay then
        self.Dispel.Overlay = CreateFrame("Frame", nil, self.Dispel)
        self.Dispel.Overlay:SetFrameStrata("MEDIUM")
        self.Dispel.Overlay:SetFrameLevel(10)
    end

    self.WidgetOverlay.targetIndicator.Texture:SetAtlas("TargetCrosshairs")
    self.WidgetOverlay.focusIndicator.Texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\Waypoint-MapPin-Untracked.tga")
    self.WidgetOverlay.combatIndicator.Texture:SetAtlas("Food")
    self.WidgetOverlay.partyTarget1.Texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\GM-icon-headCount.tga")
    self.WidgetOverlay.partyTarget1.Texture:SetDesaturated(true)
    self.WidgetOverlay.partyTarget2.Texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\GM-icon-headCount.tga")
    self.WidgetOverlay.partyTarget2.Texture:SetDesaturated(true)
    self.WidgetOverlay.targetIndicator:SetFrameLevel(15)
    self.Trinket:SetFrameLevel(7)

    self.DispelStacks:SetParent(self.Dispel.Overlay)

    self.TexturePool = CreateTexturePool(self, "ARTWORK", nil, nil, ResetTexture)
end

function sArenaFrameMixin:OnEvent(event, eventUnit, arg1)
    local unit = self.unit

    if (eventUnit and eventUnit == unit) then
        if (event == "UNIT_NAME_UPDATE") then
            if (db.profile.showArenaNumber) then
                self.Name:SetText(unit)
            elseif (db.profile.showNames) then
                self.Name:SetText(UnitName(unit))
            end
        elseif (event == "ARENA_OPPONENT_UPDATE") then
            self:UpdatePlayer(arg1)
        elseif (event == "ARENA_COOLDOWNS_UPDATE") then
             self:UpdateTrinket()
        elseif (event == "ARENA_CROWD_CONTROL_SPELL_UPDATE") then
            -- arg1 == spellID
            if (arg1 ~= self.Trinket.spellID) then
                if arg1 ~= 0 then
                    local _, spellTextureNoOverride = GetSpellTexture(arg1)

                    -- Check if we had racial on trinket slot before
                    local wasRacialOnTrinketSlot = self.updateRacialOnTrinketSlot

                    self.Trinket.spellID = arg1

                    -- Determine if we should put racial on trinket slot
                    local swapEnabled = db.profile.swapRacialTrinket or db.profile.swapHumanTrinket
                    local shouldPutRacialOnTrinket = swapEnabled and self.race and not spellTextureNoOverride

                    -- Set the trinket texture
                    local trinketTexture
                    if spellTextureNoOverride then
                        if isRetail then
                            trinketTexture = spellTextureNoOverride
                        else
                            trinketTexture = self:GetFactionTrinketIcon()
                        end
                    else
                        if not isRetail and self.race == "Human" and db.profile.forceShowTrinketOnHuman then
                            trinketTexture = self:GetFactionTrinketIcon()
                            self.Trinket.spellID = sArenaMixin.trinketID
                        else
                            trinketTexture = sArenaMixin.noTrinketTexture     -- Surrender flag if no trinket
                        end
                    end

                    -- Handle racial updates based on trinket state (same logic as UpdateTrinket)
                    if spellTextureNoOverride and wasRacialOnTrinketSlot then
                        -- We found a real trinket and had racial on trinket slot, restore racial to its proper place
                        self.updateRacialOnTrinketSlot = nil
                        self.Trinket.Texture:SetTexture(trinketTexture)
                        self:UpdateRacial()
                    elseif shouldPutRacialOnTrinket then
                        -- We should put racial on trinket slot (no real trinket found)
                        self.updateRacialOnTrinketSlot = true
                        -- Don't set trinket texture yet - let UpdateRacial handle it for racial display
                        self:UpdateRacial()
                    else
                        -- Normal case: set trinket texture and clear racial from trinket slot
                        self.updateRacialOnTrinketSlot = nil
                        self.Trinket.Texture:SetTexture(trinketTexture)
                        -- Update racial to ensure it shows in racial slot if needed
                        if wasRacialOnTrinketSlot then
                            self:UpdateRacial()
                        end
                    end

                    self:UpdateTrinketIcon(true)
                else
                    -- No trinket - check if we should put racial on trinket slot
                    local swapEnabled = db.profile.swapRacialTrinket or db.profile.swapHumanTrinket
                    local shouldPutRacialOnTrinket = swapEnabled and self.race

                    if shouldPutRacialOnTrinket then
                        self.updateRacialOnTrinketSlot = true
                        self:UpdateRacial()
                        if isRetail then return end -- Need to test MoP more...
                    else
                        self.updateRacialOnTrinketSlot = nil
                        -- Ensure racial shows in racial slot if it was on trinket before
                        self:UpdateRacial()
                    end

                    if not isRetail and self.race == "Human" and db.profile.forceShowTrinketOnHuman then
                        self.Trinket.spellID = sArenaMixin.trinketID
                        self.Trinket.Texture:SetTexture(self:GetFactionTrinketIcon())
                        self:UpdateTrinketIcon(true)
                    else
                        if db.profile.swapRacialTrinket then
                            self:UpdateRacial()
                        else
                            self.Trinket.Texture:SetTexture(sArenaMixin.noTrinketTexture)
                            self:UpdateTrinketIcon(false)
                        end
                    end
                end
            end
        elseif (event == "UNIT_AURA") then
            self:FindAura()
        elseif (event == "UNIT_HEALTH") then
            if isMidnight then
                local isDead = UnitIsDeadOrGhost(unit)
                self.hideStatusText = isDead
                self.HealthBar:SetValue(UnitHealth(unit))
                if (isDead) then
                    --self.HealthBar:SetValue(0)
                    self.SpecNameText:SetText("")
                    self.WidgetOverlay:Hide()
                end
                self.DeathIcon:SetShown(isDead)
                self:SetStatusText()
            else
                local currentHealth = UnitHealth(unit)
                if currentHealth ~= 0 then
                    self:SetStatusText()
                    self.HealthBar:SetValue(currentHealth)
                    self:UpdateHealPrediction()
                    self:UpdateAbsorb()
                    self.DeathIcon:SetShown(false)
                    self.hideStatusText = false
                    self.currentHealth = currentHealth
                    if self.isFeigningDeath then
                        self.HealthBar:SetAlpha(1)
                        self.isFeigningDeath = nil
                    end
                else
                    self:SetLifeState()
                end
            end
        elseif (event == "UNIT_MAXHEALTH") then
            self.HealthBar:SetMinMaxValues(0, UnitHealthMax(unit))
            self.HealthBar:SetValue(UnitHealth(unit))
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        elseif (event == "UNIT_POWER_UPDATE") then
            self:SetStatusText()
            self.PowerBar:SetValue(UnitPower(unit))
        elseif (event == "UNIT_MAXPOWER") then
            self.PowerBar:SetMinMaxValues(0, UnitPowerMax(unit))
            self.PowerBar:SetValue(UnitPower(unit))
        elseif (event == "UNIT_DISPLAYPOWER") then
            local _, powerType = UnitPowerType(unit)
            self:SetPowerType(powerType)
            self.PowerBar:SetMinMaxValues(0, UnitPowerMax(unit))
            self.PowerBar:SetValue(UnitPower(unit))
        elseif (event == "UNIT_ABSORB_AMOUNT_CHANGED") then
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        elseif (event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED") then
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        elseif (event == "UNIT_FLAGS") then
            self:UpdateCombatStatus(unit)
        end

    elseif (event == "PLAYER_LOGIN") then
        self:UnregisterEvent("PLAYER_LOGIN")

        if (not db) then
            self.parent:Initialize()
        end

        self:Initialize()
    elseif (event == "PLAYER_ENTERING_WORLD") or (event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS") then
        local _, instanceType = IsInInstance()
        if self.drTray then
            self.drTray:SetAlpha(instanceType == "arena" and 1 or 0)
        end

        if noEarlyFrames and instanceType == "arena" and self.ogShow then
            self.ogShow(self)
            self:SetAlpha(0)
        end

        self.Name:SetText("")
        self.CastBar:Hide()
        self.specTexture = nil
        self.class = nil
        self.currentClassIconTexture = nil
        self.currentClassIconStartTime = 0
        self.updateRacialOnTrinketSlot = nil
        self:UpdateVisible()
        self:ResetTrinket()
        self:ResetRacial()
        if not isMidnight then
            self:ResetDispel()
            self:ResetDR()
        end
        self:UpdateHealPrediction()
        self:UpdateAbsorb()
        if UnitExists(self.unit) then
            self:UpdatePlayer("seen")
        else
            self:UpdatePlayer()
        end
        --self:SetAlpha((noEarlyFrames and (UnitExists(self.unit) and 1 or stealthAlpha)) or (UnitIsVisible(self.unit) and 1 or stealthAlpha))
        self.HealthBar:SetAlpha(1)
        if TestTitle then
            TestTitle:Hide()
        end
    elseif (event == "PLAYER_REGEN_ENABLED") then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UpdateVisible()
    end
end

function sArenaFrameMixin:Initialize()
    self:SetMysteryPlayer()
    self.parent:SetupDrag(self, self.parent, nil, "UpdateFrameSettings")
    self.parent:SetupDrag(self.CastBar, self.CastBar, "castBar", "UpdateCastBarSettings")

    -- Setup DR dragging based on system
    if isMidnight then
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. self:GetID()]
        if blizzArenaFrame and blizzArenaFrame.SpellDiminishStatusTray then
            self.drTray = blizzArenaFrame.SpellDiminishStatusTray
            blizzArenaFrame.SpellDiminishStatusTray:SetMovable(true)
            self.parent:SetupDrag(blizzArenaFrame.SpellDiminishStatusTray, blizzArenaFrame.SpellDiminishStatusTray, "dr", "UpdateDRSettings")
        end
    else
        self.parent:SetupDrag(self[sArenaMixin.drCategories[1]], self[sArenaMixin.drCategories[1]], "dr", "UpdateDRSettings")
    end

    self.parent:SetupDrag(self.SpecIcon, self.SpecIcon, "specIcon", "UpdateSpecIconSettings")
    self.parent:SetupDrag(self.Trinket, self.Trinket, "trinket", "UpdateTrinketSettings")
    self.parent:SetupDrag(self.Racial, self.Racial, "racial", "UpdateRacialSettings")
    self.parent:SetupDrag(self.Dispel, self.Dispel, "dispel", "UpdateDispelSettings")

    self.parent:SetupDrag(self.WidgetOverlay.combatIndicator, self.WidgetOverlay.combatIndicator, "combatIndicator", nil, true)
    self.parent:SetupDrag(self.WidgetOverlay.targetIndicator, self.WidgetOverlay.targetIndicator, "targetIndicator", nil, true)
    self.parent:SetupDrag(self.WidgetOverlay.focusIndicator, self.WidgetOverlay.focusIndicator, "focusIndicator", nil, true)
    self.parent:SetupDrag(self.WidgetOverlay.partyTarget1, self.WidgetOverlay.partyTarget1, "partyTargetIndicators", nil, true)
    self.parent:SetupDrag(self.WidgetOverlay.partyTarget2, self.WidgetOverlay.partyTarget1, "partyTargetIndicators", nil, true)
end

function sArenaFrameMixin:OnEnter()
    if not isMidnight then
        UnitFrame_OnEnter(self)
    end

    self.HealthText:Show()
    self.PowerText:Show()
end

function sArenaFrameMixin:OnLeave()
    UnitFrame_OnLeave(self)

    self:UpdateStatusTextVisible()
end

local function GetNumArenaOpponentsFallback()
    local count = 0
    for i = 1, sArenaMixin.maxArenaOpponents do
        if UnitExists("arena" .. i) or (noEarlyFrames and sArenaMixin.seenArenaUnits[i]) then
            count = count + 1
        end
    end

    -- TBC: Use party size as fallback, but only after the match has started or we're not in the starting room
    if noEarlyFrames and count < GetNumGroupMembers() then
        local inPreparation = C_UnitAuras.GetPlayerAuraBySpellID(32727)
        if not inPreparation and not sArenaMixin.justEnteredArena and sArenaMixin.arenaMatchStarted then
            count = GetNumGroupMembers() or count
        end
    end

    return count
end

function sArenaFrameMixin:UpdateVisible()
    if InCombatLockdown() then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then
        self:Hide()
        return
    end

    local id = self:GetID()
    local numSpecs = GetNumArenaOpponentSpecs()
    local numOpponents = (numSpecs == 0) and GetNumArenaOpponentsFallback() or numSpecs

    if numOpponents >= id or (noEarlyFrames and sArenaMixin.seenArenaUnits[id]) then
        self:Show()
    else
        self:Hide()
    end
end


local function addToMasque(frame, masqueGroup)
    masqueGroup:AddButton(frame)
end

function sArenaMixin:AddMasqueSupport()
    if not self.db.profile.enableMasque or masqueOn or not C_AddOns.IsAddOnLoaded("Masque") then return end
    local Masque = LibStub("Masque", true)
    masqueOn = true

    local sArenaClass = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Class/Aura")
    local sArenaTrinket = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Trinket")
    local sArenaSpecIcon = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "SpecIcon")
    local sArenaRacial = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Racial")
    local sArenaDispel = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Dispel")
    local sArenaDRs = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "DRs")
    local sArenaFrame = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Frame")
    local sArenaCastbar = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Castbar")
    local sArenaCastbarIcon = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Castbar Icon")

    function sArenaMixin:RefreshMasque()
        sArenaClass:ReSkin(true)
        sArenaTrinket:ReSkin(true)
        sArenaSpecIcon:ReSkin(true)
        sArenaRacial:ReSkin(true)
        sArenaDispel:ReSkin(true)
        sArenaDRs:ReSkin(true)
        sArenaFrame:ReSkin(true)
        sArenaCastbarIcon:ReSkin(true)
    end

    local function MsqSkinIcon(frame, group)
        local skinWrapper = CreateFrame("Frame")
        skinWrapper:SetParent(frame)
        skinWrapper:SetSize(30, 30)
        skinWrapper:SetAllPoints(frame.Icon)
        frame.MSQ = skinWrapper
        frame.Icon:Hide()
        frame.SkinnedIcon = skinWrapper:CreateTexture(nil, "BACKGROUND")
        frame.SkinnedIcon:SetSize(30, 30)
        frame.SkinnedIcon:SetPoint("CENTER")
        frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())
        hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
            skinWrapper:SetScale(frame.Icon:GetScale())
            frame.SkinnedIcon:SetTexture(tex)
        end)
        group:AddButton(skinWrapper, {
            Icon = frame.SkinnedIcon,
        })
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame.FrameMsq = CreateFrame("Frame", nil, frame)
        frame.FrameMsq:SetFrameStrata("HIGH")
        frame.FrameMsq:SetPoint("TOPLEFT", frame.HealthBar, "TOPLEFT", 0, 0)
        frame.FrameMsq:SetPoint("BOTTOMRIGHT", frame.PowerBar, "BOTTOMRIGHT", 0, 0)

        frame.ClassIconMsq = CreateFrame("Frame", nil, frame)
        frame.ClassIconMsq:SetFrameStrata("DIALOG")
        frame.ClassIconMsq:SetAllPoints(frame.ClassIcon)

        frame.SpecIconMsq = CreateFrame("Frame", nil, frame)
        frame.SpecIconMsq:SetFrameStrata("DIALOG")
        frame.SpecIconMsq:SetAllPoints(frame.SpecIcon)

        frame.TrinketMsq = CreateFrame("Frame", nil, frame)
        frame.TrinketMsq:SetFrameStrata("DIALOG")
        frame.TrinketMsq:SetAllPoints(frame.Trinket)

        frame.RacialMsq = CreateFrame("Frame", nil, frame)
        frame.RacialMsq:SetFrameStrata("DIALOG")
        frame.RacialMsq:SetAllPoints(frame.Racial)

        frame.DispelMsq = CreateFrame("Frame", nil, frame)
        frame.DispelMsq:SetFrameStrata("DIALOG")
        frame.DispelMsq:SetAllPoints(frame.Dispel)

        frame.CastBarMsq = CreateFrame("Frame", nil, frame.CastBar)
        frame.CastBarMsq:SetFrameStrata("HIGH")
        frame.CastBarMsq:SetAllPoints(frame.CastBar)

        addToMasque(frame.FrameMsq, sArenaFrame)
        addToMasque(frame.ClassIconMsq, sArenaClass)
        addToMasque(frame.SpecIconMsq, sArenaSpecIcon)
        addToMasque(frame.TrinketMsq, sArenaTrinket)
        addToMasque(frame.RacialMsq, sArenaRacial)
        addToMasque(frame.DispelMsq, sArenaDispel)
        addToMasque(frame.CastBarMsq, sArenaCastbar)
        MsqSkinIcon(frame.CastBar, sArenaCastbarIcon)

        frame.CastBar.MSQ:SetFrameStrata("DIALOG")

        -- Add MasqueBorderHook for Trinket
        if not frame.Trinket.MasqueBorderHook then
            hooksecurefunc(frame.Trinket.Texture, "SetTexture", function(self, t)
                if not t then
                    if frame.TrinketMsq then
                        frame.TrinketMsq:Hide()
                    end
                else
                    if frame.TrinketMsq and frame.parent.db.profile.enableMasque then
                        frame.TrinketMsq:Hide()
                        frame.TrinketMsq:Show()
                    end
                end
            end)
            frame.Trinket.MasqueBorderHook = true
        end

        -- Add MasqueBorderHook for Racial
        if not frame.Racial.MasqueBorderHook then
            hooksecurefunc(frame.Racial.Texture, "SetTexture", function(self, t)
                if not t then
                    if frame.RacialMsq then
                        frame.RacialMsq:Hide()
                    end
                else
                    if frame.RacialMsq and frame.parent.db.profile.enableMasque then
                        frame.RacialMsq:Hide()
                        frame.RacialMsq:Show()
                    end
                end
            end)
            frame.Racial.MasqueBorderHook = true
        end

        -- Add MasqueBorderHook for Dispel
        if not frame.Dispel.MasqueBorderHook then
            hooksecurefunc(frame.Dispel.Texture, "SetTexture", function(self, t)
                if not t then
                    if frame.DispelMsq then
                        frame.DispelMsq:Hide()
                    end
                else
                    if frame.DispelMsq and frame.parent.db.profile.enableMasque then
                        frame.DispelMsq:Hide()
                        frame.DispelMsq:Show()
                    end
                end
            end)
            frame.Dispel.MasqueBorderHook = true
        end

        -- DR frames
        for _, category in ipairs(self.drCategories) do
            local drFrame = frame[category]
            if drFrame then
                addToMasque(drFrame, sArenaDRs)
            end
        end
    end
end

function sArenaFrameMixin:UpdateNameColor()
    if not self.Name:IsShown() then return end

    local class = (self.unit and select(2, UnitClass(self.unit))) or self.tempClass
    if not class then return end

    local color = RAID_CLASS_COLORS[class]
    if self.parent.db.profile.classColorNames and color then
        if not self.oldNameColor then
            local r, g, b, a = self.Name:GetTextColor()
            self.oldNameColor = {r, g, b, a}
        end
        self.Name:SetTextColor(color.r, color.g, color.b, 1)
    else
        if self.oldNameColor then
            self.Name:SetTextColor(unpack(self.oldNameColor))
            self.oldNameColor = nil
        end
    end
end

function sArenaFrameMixin:UpdatePlayer(unitEvent)
    local unit = self.unit

    if noEarlyFrames and UnitExists(unit) then
        sArenaMixin.seenArenaUnits[self:GetID()] = true
    end

    self:GetClass()
    if isMidnight then
        self:UpdateClassIcon()
    else
        self:FindAura()
    end

    if (unitEvent and unitEvent ~= "seen") or (UnitGUID(self.unit) == nil) then
        self:SetMysteryPlayer()
        return
    end

    C_PvP.RequestCrowdControlSpell(unit)

    self:UpdateRacial()
    if not isMidnight then
        self:UpdateDispel()
    end
    self.WidgetOverlay:Show()
    self:UpdateCombatStatus(unit)
    self:UpdatePartyTargets(unit)
    self:UpdateTarget(unit)
    self:UpdateFocus(unit)

    -- Prevent castbar and other frames from intercepting mouse clicks during a match
    if (unitEvent == "seen") then
        self.parent:SetMouseState(false)
    end

    self.hideStatusText = false

    if (db.profile.showNames) then
        self.Name:SetText(UnitName(unit))
        self:UpdateNameColor()
        self.Name:SetShown(true)
    elseif (db.profile.showArenaNumber) then
        self.Name:SetText(self.unit)
        self:UpdateNameColor()
        self.Name:SetShown(true)
    end
    self.SpecNameText:SetText(self.specName or "")

    self:UpdateStatusTextVisible()
    self:SetStatusText()

    self:OnEvent("UNIT_MAXHEALTH", unit)
    self:OnEvent("UNIT_HEALTH", unit)
    self:OnEvent("UNIT_MAXPOWER", unit)
    self:OnEvent("UNIT_POWER_UPDATE", unit)
    self:OnEvent("UNIT_DISPLAYPOWER", unit)
    if not isMidnight then
        self:OnEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
    end

    local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]

    if (color and db.profile.classColors) then
        self.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1.0)
    else
        self.HealthBar:SetStatusBarColor(0, 1.0, 0, 1.0)
    end

    if noEarlyFrames and not UnitExists(unit) then
        self:SetAlpha(stealthAlpha)
    else
        self:SetAlpha(1)
    end

    -- Workaround to show frames in older arenas in combat.
    -- Does not actually call Show(), but SetAlpha() on older arenas.
    if noEarlyFrames then
        self:Show()
    end
end

function sArenaFrameMixin:SetMysteryPlayer()
    local hp = self.HealthBar
    hp:SetMinMaxValues(0, 100)
    hp:SetValue(100)

    local pp = self.PowerBar
    pp:SetMinMaxValues(0, 100)
    pp:SetValue(100)

    if self.parent.db and self.parent.db.profile.colorMysteryGray then -- TODO: Figure out cleaner fix, why db is nil here.
        hp:SetStatusBarColor(0.5, 0.5, 0.5)
        pp:SetStatusBarColor(0.5, 0.5, 0.5)
    else
        local class = self.class or self.tempClass
        local color = class and RAID_CLASS_COLORS[class]

        if color and self.parent.db and self.parent.db.profile.classColors then
            hp:SetStatusBarColor(color.r, color.g, color.b)
        else
            hp:SetStatusBarColor(0, 1.0, 0)
        end

        local powerType
        if class == "DRUID" then
            local specName = self.specName
            if specName == "Feral" then
                powerType = "ENERGY"
            elseif specName == "Guardian" then
                powerType = "RAGE"
            else
                powerType = "MANA"
            end
        elseif class == "MONK" then
            local specName = self.specName
            if specName == "Mistweaver" then
                powerType = "MANA"
            else
                powerType = "ENERGY"
            end
        else
            powerType = class and classPowerType[class] or "MANA"
        end

        local powerColor = PowerBarColor[powerType]
        if powerColor then
            pp:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
        else
            pp:SetStatusBarColor(0, 0, 1.0)
        end

        self:SetAlpha(stealthAlpha)
    end

    self.hideStatusText = true
    self:SetStatusText()
    self.WidgetOverlay:Hide()

    self.DeathIcon:Hide()
end

function sArenaFrameMixin:GetClass()
    local _, instanceType = IsInInstance()

    if (instanceType ~= "arena") then
        self.specTexture = nil
        self.class = nil
        self.classLocal = nil
        self.specName = nil
        self.specID = nil
        self.isHealer = nil
        self.SpecIcon:Hide()
        self.SpecNameText:SetText("")
    elseif (not self.class) then
        local id = self:GetID()

        if not noEarlyFrames then
            if (GetNumArenaOpponentSpecs() >= id) then
                local specID = GetArenaOpponentSpec(id) or 0
                if (specID > 0) then
                    local _, specName, _, specTexture, _, class, classLocal = GetSpecializationInfoByID(specID)
                    self.class = class
                    self.classLocal = classLocal
                    self.specID = specID
                    self.specName = specName
                    self.isHealer = sArenaMixin.healerSpecIDs[specID] or false
                    self.SpecNameText:SetText(specName)
                    self.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)
                    self.specTexture = specTexture
                    self.class = class
                    self:UpdateSpecIcon()
                    self:UpdateFrameColors()
                    sArenaMixin:UpdateTextures()
                end
            end
        end

        if (not self.class and (noEarlyFrames or UnitExists(self.unit))) then
            self.classLocal, self.class = UnitClass(self.unit)
        end
    end
end


function sArenaFrameMixin:UpdateClassIcon(continue)
	if (self.currentAuraSpellID and self.currentAuraDuration > 0 and self.currentClassIconStartTime ~= self.currentAuraStartTime) then
		self.ClassIcon.Cooldown:SetCooldown(self.currentAuraStartTime, self.currentAuraDuration)
		self.currentClassIconStartTime = self.currentAuraStartTime
	elseif (self.currentAuraDuration == 0) then
		self.ClassIcon.Cooldown:Clear()
		self.currentClassIconStartTime = 0
	end

	local texture = self.currentAuraSpellID and self.currentAuraTexture or self.class and "class" or 134400

	if (self.currentClassIconTexture == texture) and not continue then return end

	self.currentClassIconTexture = texture

    local useHealerTexture

    if (texture == "class") then

        if db.profile.replaceHealerIcon and self.isHealer then
            useHealerTexture = true
        end

        if db.profile.hideClassIcon then
            texture = nil
            if self.ClassIconMsq then
                self.ClassIconMsq:Hide()
            end
        elseif db.profile.layoutSettings[db.profile.currentLayout].replaceClassIcon and self.specTexture then
            texture = self.specTexture
            if self.ClassIconMsq then
                self.ClassIconMsq:Show()
            end
        else
            texture = sArenaMixin.classIcons[self.class]
            if self.ClassIconMsq then
                self.ClassIconMsq:Show()
            end
        end

        if useHealerTexture then
            self.ClassIcon.Texture:SetAtlas("UI-LFG-RoleIcon-Healer")
        else
            self.ClassIcon.Texture:SetTexture(texture)
        end

        local cropType = useHealerTexture and "healer" or "class"
        self:SetTextureCrop(self.ClassIcon.Texture, db.profile.layoutSettings[db.profile.currentLayout].cropIcons, cropType)
		return
	end
	self:SetTextureCrop(self.ClassIcon.Texture, db and db.profile.layoutSettings[db.profile.currentLayout].cropIcons, "class")
	self.ClassIcon.Texture:SetTexture(texture)
    if self.ClassIconMsq then
        self.ClassIconMsq:Show()
    end
end

-- Returns the spec icon texture based on arena unit ID (1-5)
function sArenaFrameMixin:UpdateSpecIcon()
    if not db.profile.layoutSettings[db.profile.currentLayout].replaceClassIcon then
        self.SpecIcon.Texture:SetTexture(self.specTexture)
        self.SpecIcon:Show()
        if self.SpecIconMsq then
            self.SpecIconMsq:Show()
        end
    else
        self.SpecIcon:Hide()
        if self.SpecIconMsq then
            self.SpecIconMsq:Hide()
        end
    end
end

local function ResetStatusBar(f)
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f:SetStatusBarColor(1, 1, 1, 1)
    f:SetScale(1)
end

local function ResetFontString(f)
    f:SetDrawLayer("OVERLAY", 1)
    f:SetJustifyH("CENTER")
    f:SetJustifyV("MIDDLE")
    f:SetTextColor(1, 0.82, 0, 1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)
    f:ClearAllPoints()
    f:Hide()
end

function sArenaFrameMixin:ResetLayout()
    self.currentClassIconTexture = nil
    self.currentClassIconStartTime = 0
    self.oldNameColor = nil

    ResetTexture(nil, self.ClassIcon.Texture)
    ResetStatusBar(self.HealthBar)
    ResetStatusBar(self.PowerBar)
    ResetStatusBar(self.CastBar)
    self.CastBar:SetHeight(16)

    local ogBg = select(1, self.CastBar:GetRegions())
    if ogBg then
        ogBg:Show()
    end

    if self.CastBar.BorderShield then
        self.CastBar.BorderShield:SetTexture(330124)
    end

    self.ClassIcon:SetFrameStrata("MEDIUM")
    self.ClassIcon:SetFrameLevel(7)
    self.ClassIcon.Cooldown:SetUseCircularEdge(false)
    self.ClassIcon.Cooldown:SetSwipeTexture(1)
    self.AuraStacks:SetPoint("BOTTOMLEFT", self.ClassIcon.Texture, "BOTTOMLEFT", 2, 0)
    self.AuraStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 13, "THICKOUTLINE")
    self.DispelStacks:SetPoint("BOTTOMLEFT", self.Dispel.Texture, "BOTTOMLEFT", 2, 0)
    self.DispelStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 15, "THICKOUTLINE")

    self.ClassIcon.Mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    self.ClassIcon.Texture:RemoveMaskTexture(self.ClassIcon.Mask)
    self.ClassIcon.Texture:SetDrawLayer("BORDER", 1)
    self.ClassIcon.Texture:SetAllPoints(self.ClassIcon)
    self.ClassIcon.Texture:Show()
    self.ClassIcon:SetScale(1)
    if self.frameTexture then
        self.frameTexture:SetDrawLayer("ARTWORK", 2)
        self.frameTexture:SetDesaturated(false)
        self.frameTexture:SetVertexColor(1, 1, 1)
        self.frameTexture:Hide()
    end

    if self.CastBar.Border then
        self.CastBar.Border:SetDesaturated(false)
        self.CastBar.Border:SetVertexColor(1, 1, 1)
    end

    if self.Trinket.Border then
        self.Trinket.Border:SetDesaturated(false)
        self.Trinket.Border:SetVertexColor(1, 1, 1)
        self.Racial.Border:SetDesaturated(false)
        self.Racial.Border:SetVertexColor(1, 1, 1)
        self.Dispel.Border:SetDesaturated(false)
        self.Dispel.Border:SetVertexColor(1, 1, 1)
    end

    self.ClassIcon.Texture.useModernBorder = nil
    self.Trinket.useModernBorder = nil
    self.Racial.useModernBorder = nil
    self.Dispel.useModernBorder = nil

    if self.SpecIcon.Border then
        self.SpecIcon.Border:SetDesaturated(false)
        self.SpecIcon.Border:SetVertexColor(1, 1, 1)
        self.SpecIcon.Border:SetTexture(nil)
    end

    if self.SpecIcon.Mask then
        self.SpecIcon.Texture:RemoveMaskTexture(self.SpecIcon.Mask)
    end
    self.SpecIcon.Texture:SetTexCoord(0, 1, 0, 1)

    if self.NameBackground then
        self.NameBackground:Hide()
    end

    local cropIcons = db.profile.layoutSettings[db.profile.currentLayout].cropIcons

    local f = self.Trinket
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f.Cooldown:SetUseCircularEdge(false)
    if f.Mask then
        f.Texture:RemoveMaskTexture(f.Mask)
        f.Cooldown:SetSwipeTexture(1)
    end
    self:SetTextureCrop(f.Texture, cropIcons)

    local f = self.Dispel
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f.Cooldown:SetUseCircularEdge(false)
    if f.Mask then
        f.Texture:RemoveMaskTexture(f.Mask)
        f.Cooldown:SetSwipeTexture(1)
    end
    self:SetTextureCrop(f.Texture, cropIcons)

    f = self.ClassIcon.Texture
    self:SetTextureCrop(f, cropIcons)

    f = self.Racial
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f.Cooldown:SetUseCircularEdge(false)
    if f.Mask then
        f.Texture:RemoveMaskTexture(f.Mask)
        f.Cooldown:SetSwipeTexture(1)
    end
    self:SetTextureCrop(f.Texture, cropIcons)

    f = self.SpecIcon
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f:SetScale(1)
    f.Texture:RemoveMaskTexture(f.Mask)
    self:SetTextureCrop(f.Texture, cropIcons)

    f = self.Name
    ResetFontString(f)
    f:SetDrawLayer("ARTWORK", 2)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.SpecNameText
    ResetFontString(f)
    f:SetDrawLayer("OVERLAY", 6)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetScale(1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.HealthText
    ResetFontString(f)
    f:SetDrawLayer("ARTWORK", 2)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetTextColor(1, 1, 1, 1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.PowerText
    ResetFontString(f)
    f:SetDrawLayer("ARTWORK", 2)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetTextColor(1, 1, 1, 1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.CastBar
    f.Icon:SetTexCoord(0, 1, 0, 1)
    local fontName,s,o = f.Text:GetFont()
    f.Text:SetFont(fontName, s, "THINOUTLINE")

    self.TexturePool:ReleaseAll()
end

function sArenaFrameMixin:SetPowerType(powerType)
    local color = PowerBarColor[powerType]
    if color then
        self.PowerBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

function sArenaFrameMixin:SetLifeState()
    local unit = self.unit
    local isFeigningDeath = self.class == "HUNTER" and AuraUtil.FindAuraByName(FEIGN_DEATH, unit, "HELPFUL")
    local isDead = UnitIsDeadOrGhost(unit) and not isFeigningDeath

    self.DeathIcon:SetShown(isDead)
    self.hideStatusText = isDead
    if (isDead) then
        self:SetStatusText()
        self.HealthBar:SetValue(0)
        self:UpdateHealPrediction()
        self:UpdateAbsorb()
        self.currentHealth = 0
        self.SpecNameText:SetText("")
        self.WidgetOverlay:Hide()
    elseif isFeigningDeath then
        self.HealthBar:SetAlpha(0.55)
        self.isFeigningDeath = true
    end
end

local function FormatLargeNumbers(value)
    if value >= 1000000 then
        -- For millions, show 1 decimal place (e.g., 1.8M)
        return string.format("%.1f M", value / 1000000)
    elseif value >= 1000 then
        -- For thousands, show no decimals (e.g., 392K)
        return string.format("%d K", value / 1000)
    else
        return tostring(value)
    end
end

function sArenaFrameMixin:SetStatusText(unit)
    if (self.hideStatusText) then
        self.HealthText:SetFontObject("SystemFont_Shadow_Small2")
        self.HealthText:SetText("")
        self.PowerText:SetFontObject("SystemFont_Shadow_Small2")
        self.PowerText:SetText("")
        return
    end

    if self.isFeigningDeath then return end

    if (not unit) then
        unit = self.unit
    end

    local hp = UnitHealth(unit)
    local hpMax = UnitHealthMax(unit)
    local pp = UnitPower(unit)
    local ppMax = UnitPowerMax(unit)

    if (db.profile.statusText.usePercentage) then
        if isMidnight then
            self.HealthText:SetFormattedText("%0.f%%", UnitHealthPercent(unit, nil, CurveConstants.ScaleTo100))
            self.PowerText:SetFormattedText("%0.f%%", UnitPowerPercent(unit, nil, CurveConstants.ScaleTo100))
        else
            -- UnitHealth returns percent on TBC
            if isTBC then
                self.HealthText:SetText(hp .. "%")
                self.PowerText:SetText(pp .. "%")
            else
                local hpPercent = (hpMax > 0) and ceil((hp / hpMax) * 100) or 0
                local ppPercent = (ppMax > 0) and ceil((pp / ppMax) * 100) or 0

                self.HealthText:SetText(hpPercent .. "%")
                self.PowerText:SetText(ppPercent .. "%")
            end
        end
    else
        if db.profile.statusText.formatNumbers then
            if isMidnight then
                self.HealthText:SetText(AbbreviateLargeNumbers(hp))
                self.PowerText:SetText(AbbreviateLargeNumbers(pp))
            else
                self.HealthText:SetText(FormatLargeNumbers(hp))
                self.PowerText:SetText(FormatLargeNumbers(pp))
            end
        else
            self.HealthText:SetText(hp)
            self.PowerText:SetText(pp)
        end
    end
end

function sArenaFrameMixin:UpdateStatusTextVisible()
    self.HealthText:SetShown(db.profile.statusText.alwaysShow)
    self.PowerText:SetShown(db.profile.statusText.alwaysShow)
    self.PowerText:SetAlpha(db.profile.hidePowerText and 0 or 1)
end

local specTemplates = {
    BM_HUNTER = {
        class = "HUNTER",
        specIcon = noEarlyFrames and 132164 or 461112,
        castName = "Cobra Shot",
        castIcon = noEarlyFrames and 132211 or 461114,
        racial = 135726,
        race = "Orc",
        specName = "Beast Mastery",
        unint = true,
    },
    MM_HUNTER = {
        class = "HUNTER",
        specIcon = noEarlyFrames and 132222 or 461113,
        castName = "Aimed Shot",
        castIcon = 132222,
        racial = 136225,
        race = "NightElf",
        specName = "Marksmanship",
        unint = true,
    },
    SURV_HUNTER = {
        class = "HUNTER",
        specIcon = noEarlyFrames and 132215 or 461113,
        castName = "Mending Bandage",
        castIcon = isRetail and 1014022 or 133690,
        racial = 136225,
        race = "NightElf",
        specName = "Survival",
        channel = true,
    },
    ELE_SHAMAN = {
        class = "SHAMAN",
        specIcon = 136048,
        castName = "Lightning Bolt",
        castIcon = 136048,
        racial = 135726,
        race = "Orc",
        specName = "Elemental",
    },
    ENH_SHAMAN = {
        class = "SHAMAN",
        specIcon = noEarlyFrames and 136051 or 237581,
        castName = "Stormstrike",
        castIcon = 132314,
        racial = 135726,
        race = "Orc",
        specName = "Enhancement",
    },
    RESTO_SHAMAN = {
        class = "SHAMAN",
        specIcon = 136052,
        castName = "Healing Wave",
        castIcon = 136052,
        racial = 135726,
        race = "Orc",
        specName = "Restoration",
    },
    RESTO_DRUID = {
        class = "DRUID",
        specIcon = 136041,
        castName = "Regrowth",
        castIcon = 136085,
        racial = 132089,
        race = "NightElf",
        specName = "Restoration",
    },
    AFF_WARLOCK = {
        class = "WARLOCK",
        specIcon = 136145,
        castName = "Fear",
        castIcon = 136183,
        racial = 132089,
        race = "NightElf",
        specName = "Affliction",
    },
    DESTRO_WARLOCK = {
        class = "WARLOCK",
        specIcon = 136145,
        castName = "Chaos Bolt",
        castIcon = 136186,
        racial = 132089,
        race = "NightElf",
        specName = "Destruction",
    },
    ARMS_WARRIOR = {
        class = "WARRIOR",
        specIcon = 132355,
        castName = "Slam",
        castIcon = 132340,
        racial = 136129,
        race = "Human",
        specName = "Arms",
        unint = true,
    },
    DISC_PRIEST = {
        class = "PRIEST",
        specIcon = 135940,
        castName = "Penance",
        castIcon = 237545,
        racial = 136129,
        race = "Human",
        specName = "Discipline",
        channel = true,
    },
    HOLY_PRIEST = {
        class = "PRIEST",
        specIcon = 237542,
        castName = "Holy Fire",
        castIcon = 135972,
        racial = 136129,
        race = "Human",
        specName = "Holy",
    },
    FERAL_DRUID = {
        class = "DRUID",
        specIcon = 132115,
        castName = "Cyclone",
        castIcon = noEarlyFrames and 136022 or 132469,
        racial = 132089,
        race = "NightElf",
        specName = "Feral",
    },
    FROST_MAGE = {
        class = "MAGE",
        specIcon = 135846,
        castName = "Frostbolt",
        castIcon = 135846,
        racial = 136129,
        race = "Human",
        specName = "Frost",
    },
    ARCANE_MAGE = {
        class = "MAGE",
        specIcon = 135932,
        castName = "Arcane Blast",
        castIcon = 135735,
        racial = 136129,
        race = "Human",
        specName = "Arcane",
    },
    FIRE_MAGE = {
        class = "MAGE",
        specIcon = 135810,
        castName = "Pyroblast",
        castIcon = 135808,
        racial = 132089,
        race = "NightElf",
        specName = "Fire",
    },
    RET_PALADIN = {
        class = "PALADIN",
        specIcon = 135873,
        castName = "Feet Up",
        castIcon = 133029,
        racial = 136129,
        race = "Human",
        specName = "Retribution",
    },
    UNHOLY_DK = {
        class = "DEATHKNIGHT",
        specIcon = isTBC and 136212 or 135775,
        racial = 135726,
        race = "Orc",
        specName = "Unholy",
        castName = "Army of the Dead",
        castIcon = isTBC and 136212 or 237511,
        channel = true,
    },
    SUB_ROGUE = {
        class = "ROGUE",
        specIcon = 132320,
        castName = "Crippling Poison",
        castIcon = 132273,
        racial = 135726,
        race = "Orc",
        specName = "Subtlety",
        unint = true,
    },
}

local testPlayers = {
    { template = "BM_HUNTER", name = "Despytimes" },
    { template = "BM_HUNTER", name = "Littlejimmy", racial = 132309, race = "Gnome" },
    { template = "MM_HUNTER", name = "Jellybeans" },
    { template = "SURV_HUNTER", name = "Bicmex" },
    { template = "ELE_SHAMAN", name = "Bluecheese" },
    { template = "ENH_SHAMAN", name = "Saul" },
    { template = "RESTO_SHAMAN", name = "Cdew" },
    { template = "RESTO_SHAMAN", name = "Absterge" },
    { template = "RESTO_SHAMAN", name = "Lontarito" },
    { template = "RESTO_SHAMAN", name = "Foxyllama" },
    { template = "ELE_SHAMAN", name = "Whaazzlasso", castName = "Feet Up", castIcon = 133029 },
    { template = "RESTO_DRUID", name = "Metaphors" },
    { template = "RESTO_DRUID", name = "Flop" },
    { template = "RESTO_DRUID", name = "Rennar" },
    { template = "FERAL_DRUID", name = "Sodapoopin" },
    { template = "FERAL_DRUID", name = "Bean" },
    { template = "FERAL_DRUID", name = "Snupy" },
    { template = "FERAL_DRUID", name = "Whaazzform" },
    { template = "AFF_WARLOCK", name = "Chan" },
    { template = "DESTRO_WARLOCK", name = "Merce" },
    { template = "DESTRO_WARLOCK", name = "Infernion" },
    { template = "DESTRO_WARLOCK", name = "Jazggz" },
    { template = "ARMS_WARRIOR", name = "Trillebartom" },
    { template = "DISC_PRIEST", name = "Hydra" },
    { template = "HOLY_PRIEST", name = "Mehh" },
    { template = "FROST_MAGE", name = "Raiku" },
    { template = "FROST_MAGE", name = "Samiyam" },
    { template = "FROST_MAGE", name = "Aeghis" },
    { template = "FROST_MAGE", name = "Venruki" },
    { template = "FROST_MAGE", name = "Xaryu" },
    { template = "FIRE_MAGE", name = "Hansol" },
    { template = "ARCANE_MAGE", name = "Ziqo" },
    { template = "ARCANE_MAGE", name = "Mmrklepter" },
    { template = "RET_PALADIN", name = "Judgewhaazz" },
    { template = "UNHOLY_DK", name = "Darthchan" },
    { template = "UNHOLY_DK", name = "Mes" },
    { template = "SUB_ROGUE", name = "Nahj" },
    { template = "SUB_ROGUE", name = "Invisbull", racial = 132368, race = "Tauren" },
    { template = "SUB_ROGUE", name = "Cshero" },
    { template = "SUB_ROGUE", name = "Pshero" },
    { template = "SUB_ROGUE", name = "Whaazz" },
    { template = "SUB_ROGUE", name = "Pikawhoo" },
    { template = "ARMS_WARRIOR", name = "Magnusz" },
}

local function ExpandTemplates()
    for _, player in ipairs(testPlayers) do
        local template = specTemplates[player.template]
        if template then
            for k, v in pairs(template) do
                if player[k] == nil then
                    player[k] = v
                end
            end
            player.template = nil
        end
    end
    testActive = true
end

local function Shuffle()
    local MAX = (sArenaMixin and sArenaMixin.maxArenaOpponents) or 3
    if MAX < 1 then return {} end

    local HEALER_SPECS = { Restoration = true, Discipline = true, Holy = true, Mistweaver = true, Preservation = true }
    local function isHealer(p) return HEALER_SPECS[p.specName] == true end

    local byClass, nonHealerByClass, healerList, classes = {}, {}, {}, {}

    for _, p in ipairs(testPlayers) do
        local cls = p.class
        if not byClass[cls] then
            byClass[cls] = {}
            nonHealerByClass[cls] = {}
            table.insert(classes, cls)
        end
        table.insert(byClass[cls], p)
        if isHealer(p) then
            table.insert(healerList, p)
        else
            table.insert(nonHealerByClass[cls], p)
        end
    end

    local chosen, usedClass = {}, {}

    -- 1) Pick exactly one healer (if any)
    if #healerList > 0 then
        local hp = healerList[math.random(#healerList)]
        table.insert(chosen, hp)
        --usedClass[hp.class] = true
    end

    -- 2) Fill remaining slots with NON-healers, preferring unique classes
    local candidateClasses = {}
    for _, cls in ipairs(classes) do
        if not usedClass[cls] and #nonHealerByClass[cls] > 0 then
            table.insert(candidateClasses, cls)
        end
    end
    -- shuffle classes
    for i = #candidateClasses, 2, -1 do
        local j = math.random(i)
        candidateClasses[i], candidateClasses[j] = candidateClasses[j], candidateClasses[i]
    end
    -- pick one non-healer from as many unique classes as possible
    for _, cls in ipairs(candidateClasses) do
        if #chosen >= MAX then break end
        local pool = nonHealerByClass[cls]
        table.insert(chosen, pool[math.random(#pool)])
        usedClass[cls] = true
    end

    -- 3) If still short of MAX (e.g., not enough unique classes), allow duplicates but still NO extra healers
    if #chosen < MAX then
        local flatNonHealers = {}
        for _, pool in pairs(nonHealerByClass) do
            for _, p in ipairs(pool) do table.insert(flatNonHealers, p) end
        end
        -- Fallback: if there were zero non-healers at all, fill with healers (only case we can’t enforce “only 1”)
        local fallbackPool = (#flatNonHealers > 0) and flatNonHealers or healerList
        while #chosen < MAX and #fallbackPool > 0 do
            table.insert(chosen, fallbackPool[math.random(#fallbackPool)])
        end
    end

    -- 4) Final shuffle so healer isn’t always first
    for i = #chosen, 2, -1 do
        local j = math.random(i)
        chosen[i], chosen[j] = chosen[j], chosen[i]
    end

    -- Trim just in case (shouldn't happen, but safe)
    while #chosen > MAX do table.remove(chosen) end

    return chosen
end

function sArenaMixin:Test()
    local _, instanceType = IsInInstance()
    if (InCombatLockdown() or instanceType == "arena") then return end

    local currTime = GetTime()
    if not testActive then
        ExpandTemplates()
    end
    local shuffledPlayers = Shuffle()
    local cropIcons = db.profile.layoutSettings[db.profile.currentLayout].cropIcons
    local replaceClassIcon = db.profile.layoutSettings[db.profile.currentLayout].replaceClassIcon
    local hideClassIcon = db.profile.hideClassIcon
    local colorTrinket = db.profile.colorTrinket
    local modernCastbars = db.profile.layoutSettings[db.profile.currentLayout].castBar.useModernCastbars
    local keepDefaultModernTextures = db.profile.layoutSettings[db.profile.currentLayout].castBar.keepDefaultModernTextures
    local widgetSettings = db.profile.layoutSettings[db.profile.currentLayout].widgets
    local partyTargetIndicatorsOn = widgetSettings.partyTargetIndicators.enabled
    local targetIndicatorOn = widgetSettings.targetIndicator.enabled
    local focusIndicatorOn = widgetSettings.focusIndicator.enabled
    local combatIndicatorOn = widgetSettings.combatIndicator.enabled

    local topFrame
    local numUnits = math.min(sArenaMixin.testUnits or sArenaMixin.maxArenaOpponents, sArenaMixin.maxArenaOpponents)

    for i = 1, numUnits do
        local frame = self["arena" .. i]
        local data = shuffledPlayers[i]

        if i == 1 then
            topFrame = frame
        end

        if masqueOn and frame.masqueHidden then
            frame.FrameMsq:Show()
            frame.ClassIconMsq:Show()
            frame.SpecIconMsq:Show()
            frame.CastBarMsq:Show()
            if frame.CastBar.MSQ then
                frame.CastBar.MSQ:Show()
                frame.CastBar.Icon:Hide()
            end
            frame.TrinketMsq:Show()
            frame.RacialMsq:Show()
            frame.DispelMsq:Show()
            frame.masqueHidden = false
        end

        frame.tempName = data.name
        frame.tempSpecName = data.specName
        frame.tempClass = data.class
        frame.class = data.class
        frame.tempSpecIcon = data.specIcon
        frame.replaceClassIcon = replaceClassIcon
        frame.isHealer = sArenaMixin.healerSpecNames[data.specName] or false

        frame:Show()
        frame:SetAlpha(1)
        frame.HealthBar:SetAlpha(1)
        frame.WidgetOverlay:Show()

        frame.HealthBar:SetMinMaxValues(0, 100)
        frame.HealthBar:SetValue(100)

        if i == 1 then
            frame.WidgetOverlay.focusIndicator:SetShown(focusIndicatorOn)
        elseif i == 2 then
            frame.HealthBar:SetValue(75)

            frame.WidgetOverlay.targetIndicator:SetShown(targetIndicatorOn)
        elseif i == 3 then
            frame.HealthBar:SetValue(45)

            local classColors = {}
            for classToken, color in pairs(RAID_CLASS_COLORS) do
                table.insert(classColors, color)
            end

            local color1 = classColors[math.random(#classColors)]
            local color2 = classColors[math.random(#classColors)]

            frame.WidgetOverlay.partyTarget1.Texture:SetVertexColor(color1.r, color1.g, color1.b)
            frame.WidgetOverlay.partyTarget2.Texture:SetVertexColor(color2.r, color2.g, color2.b)

            frame.WidgetOverlay.partyTarget1:SetShown(partyTargetIndicatorsOn)
            frame.WidgetOverlay.partyTarget2:SetShown(partyTargetIndicatorsOn)
        end

        frame.WidgetOverlay.combatIndicator:SetShown(combatIndicatorOn)

        frame.PowerBar:SetMinMaxValues(0, 100)
        frame.PowerBar:SetValue(100)

        -- Class Icon and Spec Icon + Spec Name
        if hideClassIcon then
            local ccSpells = {408, 2139, 33786, 118, 122}
            local ccIndex = ((i - 1) % #ccSpells) + 1
            local spellTexture = GetSpellTexture(ccSpells[ccIndex])
            frame.ClassIcon.Texture:SetTexture(spellTexture)
            if frame.ClassIconMsq then
                frame.ClassIconMsq:Hide()
            end
            if frame.SpecIconMsq then
                frame.SpecIconMsq:Hide()
            end
            if not replaceClassIcon then
                frame.SpecIcon:Show()
                frame.SpecIcon.Texture:SetTexture(data.specIcon)
                if frame.SpecIconMsq then
                    frame.SpecIconMsq:Show()
                end
            end
        else
            if replaceClassIcon then
                frame.SpecIcon:Hide()
                frame.SpecIcon.Texture:SetTexture(nil)
                if frame.SpecIconMsq then
                    frame.SpecIconMsq:Hide()
                end
                frame.ClassIcon.Texture:SetTexture(data.specIcon, true)
            else
                frame.SpecIcon:Show()
                frame.SpecIcon.Texture:SetTexture(data.specIcon)
                if frame.SpecIconMsq then
                    frame.SpecIconMsq:Show()
                end
                frame.ClassIcon.Texture:SetTexture(self.classIcons[data.class])
            end
            if frame.ClassIconMsq then
                frame.ClassIconMsq:Show()
            end
        end

        local cropType
        if db.profile.replaceHealerIcon and frame.isHealer then
            frame.ClassIcon.Texture:SetAtlas("UI-LFG-RoleIcon-Healer")
            cropType = "healer"
        else
            cropType = "class"
        end

        frame:SetTextureCrop(frame.ClassIcon.Texture, cropIcons, cropType)

        frame.SpecNameText:SetText(data.specName)
        frame.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)

        frame.ClassIcon.Cooldown:SetCooldown(currTime, math.random(5, 35))

        frame.Name:SetText((db.profile.showArenaNumber and "arena" .. i) or data.name)
        frame.Name:SetShown(db.profile.showNames or db.profile.showArenaNumber)
        frame:UpdateNameColor()

        frame.race = data.race
        frame.unit = "arena" .. i

        local shouldForceHumanTrinket = not isRetail and data.race == "Human" and db.profile.forceShowTrinketOnHuman
        local shouldReplaceHumanRacial = not isRetail and data.race == "Human" and db.profile.replaceHumanRacialWithTrinket
        local shouldSwapRacialToTrinket = false

        frame.Trinket.Cooldown:SetCooldown(currTime, math.random(5, 35))
        if colorTrinket then
            if i <= 2 then
                frame.Trinket.Texture:SetColorTexture(0,1,0)
                frame.Trinket.Cooldown:Clear()
            else
                frame.Trinket.Texture:SetColorTexture(1,0,0)
            end
        else
            if shouldSwapRacialToTrinket then
                frame.Trinket.Texture:SetTexture(data.racial or 132089)
            elseif shouldForceHumanTrinket then
                frame.Trinket.Texture:SetTexture(133452)
            else
                if not isModernArena then
                    frame.Trinket.Texture:SetTexture(GetFactionTrinketIconByRace(data.race))
                else
                    frame.Trinket.Texture:SetTexture(sArenaMixin.trinketTexture)
                end
            end
            frame.Trinket.Texture:SetDesaturated(false)
        end

        frame.updateRacialOnTrinketSlot = shouldSwapRacialToTrinket
        local shouldShowRacial = false

        if data.race and db.profile.racialCategories and db.profile.racialCategories[data.race] then
            shouldShowRacial = true
        end

        if shouldReplaceHumanRacial then
            frame.Racial.Texture:SetTexture(133452)
            frame.Racial.Cooldown:SetCooldown(currTime, math.random(5, 35))
            if frame.RacialMsq then
                frame.RacialMsq:Show()
            end
        elseif shouldShowRacial and not shouldSwapRacialToTrinket then
            frame.Racial.Texture:SetTexture(data.racial or 132089)
            frame.Racial.Cooldown:SetCooldown(currTime, math.random(5, 35))
            if frame.RacialMsq then
                frame.RacialMsq:Show()
            end
        else
            frame.Racial.Texture:SetTexture(nil)
            frame.Racial.Cooldown:Clear()
            if frame.RacialMsq then
                frame.RacialMsq:Hide()
            end
        end

        if db.profile.showDispels then
            local dispelInfo = frame.GetTestModeDispelData and frame:GetTestModeDispelData()
            if dispelInfo then
                frame.Dispel.Texture:SetTexture(dispelInfo.texture)
                frame.Dispel:Show()
                frame.Dispel.Cooldown:SetCooldown(currTime, math.random(5, 35))
            else
                frame.Dispel.Texture:SetTexture(nil)
                frame.Dispel:Hide()
            end
        else
            frame.Dispel.Texture:SetTexture(nil)
            frame.Dispel:Hide()
        end

        -- Colors
        local color = RAID_CLASS_COLORS[data.class]
        if (db.profile.classColors and color) then
            frame.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
        else
            frame.HealthBar:SetStatusBarColor(0, 1, 0, 1)
        end

        local powerType
        if data.class == "DRUID" then
            -- Check if druid is feral/guardian (energy) or balance/restoration (mana)
            if data.specName == "Feral" or data.specName == "Guardian" then
                powerType = "ENERGY"
            else
                powerType = "MANA"
            end
        else
            powerType = classPowerType[data.class] or "MANA"
        end
        local powerColor = PowerBarColor[powerType] or { r = 0, g = 0, b = 1 }

        frame.PowerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)

        frame:UpdateFrameColors()


        -- DR Frames
        if isMidnight then
            local blizzArenaFrame = _G["CompactArenaFrameMember" .. i]
            local arenaFrame = self["arena" .. i]
            local drTray = blizzArenaFrame.SpellDiminishStatusTray
            --drTray:SetParent(arenaFrame)
            --drTray:Show()
            drTray:EnableMouse(false)  -- Make sure the tray is clickthrough
            arenaFrame.drTray = drTray
            drTray:ClearAllPoints()
            local layoutdb = db.profile.layoutSettings[db.profile.currentLayout]
            local offset = ((sArenaMixin.drBaseSize or 28) / 2) + (sArenaMixin.launchedDuringArena and 16 or 0)
            drTray:SetPoint("RIGHT", arenaFrame, "CENTER", layoutdb.dr.posX + offset, layoutdb.dr.posY)
            local drsEnabled = #self.drCategories
            if drsEnabled > 0 then
                if not frame.fakeDRFrames then
                    frame.fakeDRFrames = {}

                    -- Get DR settings from saved config
                    local layout = self.db.profile.layoutSettings[self.db.profile.currentLayout]
                    local drSettings = layout.dr or {}
                    local drSize = drSettings.size or 28
                    local textSettings = layout.textSettings or {}
                    local drTextAnchor = textSettings.drTextAnchor or "BOTTOMRIGHT"
                    local drTextSize = textSettings.drTextSize or 1.0
                    local drTextOffsetX = textSettings.drTextOffsetX or 4
                    local drTextOffsetY = textSettings.drTextOffsetY or -4

                    local drCategoryTextures = {
                        [1] = 135899,     -- Incap (Whirl 2)
                        [2] = 135860,     -- Stun (Whirl)
                        [3] = 136100,     -- Root (Entangling Roots)
                        [4] = 136011,     -- Fear (Pink dispersion swirl)
                    }

                    for drIndex = 1, 4 do
                        local fakeDRFrame = CreateFrame("Frame", "sArenaFakeDR" .. i .. "_" .. drIndex, arenaFrame)
                        fakeDRFrame:SetSize(drSize, drSize)
                        fakeDRFrame:SetFrameStrata("MEDIUM")
                        fakeDRFrame:SetFrameLevel(11)
                        fakeDRFrame:EnableMouse(false)

                        -- Create Icon texture (identical to real DR frames)
                        fakeDRFrame.Icon = fakeDRFrame:CreateTexture(nil, "ARTWORK")
                        fakeDRFrame.Icon:SetAllPoints(fakeDRFrame)
                        fakeDRFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        fakeDRFrame.Icon:SetTexture(drCategoryTextures[drIndex])
                        fakeDRFrame.Icon:Show()

                        -- Create Cooldown frame (identical to real DR frames)
                        fakeDRFrame.Cooldown = CreateFrame("Cooldown", nil, fakeDRFrame, "CooldownFrameTemplate")
                        fakeDRFrame.Cooldown:SetAllPoints(fakeDRFrame)
                        fakeDRFrame.Cooldown:SetDrawBling(false)
                        fakeDRFrame.Cooldown:SetHideCountdownNumbers(false)
                        fakeDRFrame.Cooldown:SetSwipeColor(0, 0, 0, 0.55)
                        fakeDRFrame.Cooldown.Text = fakeDRFrame.Cooldown:GetCountdownFontString()
                        fakeDRFrame.Cooldown.Text.fontFile = fakeDRFrame.Cooldown.Text:GetFont()

                        -- Create Border texture (identical to real DR frames)
                        fakeDRFrame.Border = fakeDRFrame:CreateTexture(nil, "OVERLAY", nil, 6)
                        fakeDRFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                        fakeDRFrame.Border:SetAllPoints(fakeDRFrame)
                        if drIndex == 1 then
                            fakeDRFrame.Border:SetVertexColor(1, 0, 0)
                        else
                            fakeDRFrame.Border:SetVertexColor(0, 1, 0)
                        end
                        fakeDRFrame.Border:Show()

                        -- Create Boverlay frame (identical to real DR frames)
                        fakeDRFrame.Boverlay = CreateFrame("Frame", nil, fakeDRFrame)
                        fakeDRFrame.Boverlay:SetFrameStrata("DIALOG")
                        fakeDRFrame.Boverlay:SetFrameLevel(26)
                        fakeDRFrame.Boverlay:SetAllPoints(fakeDRFrame)
                        fakeDRFrame.Boverlay:Show()
                        fakeDRFrame.Border:SetParent(fakeDRFrame.Boverlay)


                        fakeDRFrame.DRTextFrame = CreateFrame("Frame", nil, fakeDRFrame)
                        fakeDRFrame.DRTextFrame:SetAllPoints(fakeDRFrame)
                        fakeDRFrame.DRTextFrame:SetFrameStrata("DIALOG")
                        fakeDRFrame.DRTextFrame:SetFrameLevel(27)

                        fakeDRFrame.DRText = fakeDRFrame.DRTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                        fakeDRFrame.DRText:SetPoint(drTextAnchor, drTextOffsetX, drTextOffsetY)
                        fakeDRFrame.DRText:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 14, "OUTLINE")
                        fakeDRFrame.DRText:SetScale(drTextSize)
                        if drIndex == 1 then
                            fakeDRFrame.DRText:SetTextColor(1, 0, 0)
                            fakeDRFrame.DRText:SetText("%")
                        else
                            fakeDRFrame.DRText:SetTextColor(0, 1, 0)
                            fakeDRFrame.DRText:SetText("½")
                        end

                        if not C_AddOns.IsAddOnLoaded("OmniCC") then
                            fakeDRFrame.Cooldown:SetHideCountdownNumbers(false)
                            self:CreateCustomCooldown(fakeDRFrame.Cooldown, self.db.profile.showDecimalsDR, true)
                        end
                        if self.db.profile.colorDRCooldownText and fakeDRFrame.Cooldown.sArenaText then
                            if drIndex == 1 then
                                fakeDRFrame.Cooldown.sArenaText:SetTextColor(1, 0, 0, 1)
                            else
                                fakeDRFrame.Cooldown.sArenaText:SetTextColor(0, 1, 0, 1)
                            end
                        end

                        if drIndex == 1 then
                            fakeDRFrame:SetPoint("RIGHT", drTray, "RIGHT", 0, 0)
                        else
                            fakeDRFrame:SetPoint("RIGHT", frame.fakeDRFrames[drIndex - 1], "LEFT", -2, 0)
                        end

                        fakeDRFrame:Show()
                        fakeDRFrame:SetAlpha(1)
                        frame.fakeDRFrames[drIndex] = fakeDRFrame
                        fakeDRFrame.Cooldown:SetCooldown(currTime, math.random(12, 25))
                    end

                    self:UpdateDRSettings(drSettings)
                end

                if frame.fakeDRFrames then
                    for n = 1, 4 do
                        local fakeDRFrame = frame.fakeDRFrames[n]
                        if fakeDRFrame then
                            fakeDRFrame:Show()
                            if fakeDRFrame.Cooldown then
                                fakeDRFrame.Cooldown:SetCooldown(currTime, math.random(12, 35))
                            end
                        end
                    end
                end
            end
        else
            local drsEnabled = #self.drCategories
            if drsEnabled > 0 then
                local drCategoryOrder = {
                    "Incapacitate",
                    "Stun",
                    "Root",
                    "Disorient",
                    "Silence",
                }
                local drCategoryTextures = {
                    [1] = 136071, -- Incap (Poly)
                    [2] = 132298, -- Stun (Kidney)
                    [3] = 135848, -- Root (Frost Nova)
                    [4] = 136184, -- Fear (Psychic Scream)
                    [5] = 458230, -- Silence
                }

                for n = 1, 4 do
                    local drFrame = frame[drCategoryOrder[n]]
                    local textureID = drCategoryTextures[n]
                    drFrame.Icon:SetTexture(textureID)
                    drFrame:Show()
                    drFrame.Cooldown:SetCooldown(currTime, math.random(12, 25))

                    local layout = self.db.profile.layoutSettings[self.db.profile.currentLayout]
                    local db = layout.dr or {}
                    local blackDRBorder = db.blackDRBorder

                    if db.disableDRBorder then
                        drFrame.Border:Hide()
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:Hide()
                        end
                    elseif db.thickPixelBorder then
                        drFrame.Border:Hide()
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:Show()
                        end
                    else
                        -- Show only normal border (for thinPixelBorder, brightDRBorder, drBorderGlowOff, or default)
                        drFrame.Border:Show()
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:Hide()
                        end
                    end

                    if (n == 1) then
                        local borderColor = blackDRBorder and { 0, 0, 0, 1 } or { 1, 0, 0, 1 }
                        local pixelBorderColor = blackDRBorder and { 0, 0, 0, 1 } or { 1, 0, 0, 1 }
                        drFrame.Border:SetVertexColor(unpack(borderColor))
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:SetVertexColor(unpack(pixelBorderColor))
                        end
                        drFrame.DRTextFrame.DRText:SetText("%")
                        drFrame.DRTextFrame.DRText:SetTextColor(1, 0, 0)
                        if drFrame.__MSQ_New_Normal then
                            drFrame.__MSQ_New_Normal:SetDesaturated(true)
                            drFrame.__MSQ_New_Normal:SetVertexColor(1, 0, 0, 1)
                        end

                        if self.db.profile.colorDRCooldownText and drFrame.Cooldown.sArenaText then
                            drFrame.Cooldown.sArenaText:SetTextColor(1, 0, 0, 1)
                        end
                    else
                        local borderColor = blackDRBorder and { 0, 0, 0, 1 } or { 0, 1, 0, 1 }
                        local pixelBorderColor = blackDRBorder and { 0, 0, 0, 1 } or { 0, 1, 0, 1 }
                        drFrame.Border:SetVertexColor(unpack(borderColor))
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:SetVertexColor(unpack(pixelBorderColor))
                        end
                        drFrame.DRTextFrame.DRText:SetText("½")
                        drFrame.DRTextFrame.DRText:SetTextColor(0, 1, 0)
                        if drFrame.__MSQ_New_Normal then
                            drFrame.__MSQ_New_Normal:SetDesaturated(true)
                            drFrame.__MSQ_New_Normal:SetVertexColor(0, 1, 0, 1)
                        end

                        if self.db.profile.colorDRCooldownText and drFrame.Cooldown.sArenaText then
                            drFrame.Cooldown.sArenaText:SetTextColor(0, 1, 0, 1)
                        end
                    end
                end
            end
        end

        -- Cast Bar
        if data.castName then
            local layout = self.db.profile.layoutSettings[self.db.profile.currentLayout]
            local texKeys = layout.textures or {
                generalStatusBarTexture = "sArena Default",
                healStatusBarTexture    = "sArena Default",
                castbarStatusBarTexture = "sArena Default",
                castbarUninterruptibleTexture = "sArena Default",
            }

            -- Get custom colors if enabled
            local colors = db.profile.castBarColors
            local useCustomColors = layout.castBar and layout.castBar.recolorCastbar

            frame.tempCast = true
            frame.tempChannel = data.channel or false
            frame.tempUninterruptible = data.unint or false

            frame.CastBar.fadeOut = nil
            frame.CastBar:Show()
            frame.CastBar:SetAlpha(1)
            frame.CastBar.Icon:SetTexture(data.castIcon)
            frame.CastBar.Text:SetText(data.castName)

            if data.unint then
                frame.CastBar.BorderShield:Show()
                if useCustomColors then
                    frame.CastBar:SetStatusBarColor(unpack(colors.uninterruptable))
                else
                    frame.CastBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
                end
            else
                frame.CastBar.BorderShield:Hide()
                if data.channel then
                    if useCustomColors then
                        frame.CastBar:SetStatusBarColor(unpack(colors.channel))
                    else
                        frame.CastBar:SetStatusBarColor(0, 1, 0, 1)
                    end
                else
                    if useCustomColors then
                        frame.CastBar:SetStatusBarColor(unpack(colors.standard))
                    else
                        frame.CastBar:SetStatusBarColor(1, 0.7, 0, 1)
                    end
                end
            end

            if modernCastbars then
                if keepDefaultModernTextures then
                    if isRetail then
                        frame.CastBar:SetStatusBarTexture(data.unint and "UI-CastingBar-Uninterruptable" or data.channel and "UI-CastingBar-Filling-Channel" or "ui-castingbar-filling-standard")
                    else
                        frame.CastBar:SetStatusBarTexture(data.unint and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or data.channel and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                    end
                    -- Handle desaturation for modern castbars with default textures
                    local castTexture = frame.CastBar:GetStatusBarTexture()
                    if useCustomColors then
                        if castTexture then
                            castTexture:SetDesaturated(true)
                        end
                    else
                        if castTexture then
                            castTexture:SetDesaturated(false)
                        end
                        frame.CastBar:SetStatusBarColor(1,1,1,1)
                    end
                else
                    local castPath
                    if data.unint then
                        castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarUninterruptibleTexture or texKeys.castbarStatusBarTexture)
                    else
                        castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
                    end
                    frame.CastBar:SetStatusBarTexture(castPath)
                end
            else
                local castPath
                if data.unint then
                    castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarUninterruptibleTexture or texKeys.castbarStatusBarTexture)
                else
                    castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
                end
                frame.CastBar:SetStatusBarTexture(castPath)
            end
        else
            frame.CastBar.fadeOut = nil
            frame.CastBar:Hide()
            frame.CastBar:SetAlpha(0)
        end

        if isTBC then
            frame.CastBar.Spark:Hide()
        end

        frame.hideStatusText = false

        local playerHpMax = UnitHealthMax("player")
        local playerPpMax = UnitPowerMax("player")

        local hpPercent = 100
        if i == 2 then
            hpPercent = 75
        elseif i == 3 then
            hpPercent = 45
        end

        local testHp = math.floor((playerHpMax * hpPercent) / 100)

        if (db.profile.statusText.usePercentage) then
            frame.HealthText:SetText(hpPercent .. "%")
            frame.PowerText:SetText("100%")
        else
            if db.profile.statusText.formatNumbers then
                frame.HealthText:SetText(AbbreviateNumbers(testHp))
                frame.PowerText:SetText(AbbreviateNumbers(playerPpMax))
            else
                frame.HealthText:SetText(AbbreviateLargeNumbers(testHp))
                frame.PowerText:SetText(AbbreviateLargeNumbers(playerPpMax))
            end
        end

        frame:UpdateStatusTextVisible()

        if masqueOn and not db.profile.enableMasque and frame.FrameMsq then
            frame.FrameMsq:Hide()
            frame.ClassIconMsq:Hide()
            frame.SpecIconMsq:Hide()
            frame.CastBarMsq:Hide()
            if frame.CastBar.MSQ then
                frame.CastBar.MSQ:Hide()
                frame.CastBar.Icon:Show()
            end
            frame.TrinketMsq:Hide()
            frame.RacialMsq:Hide()
            frame.DispelMsq:Hide()
            frame.masqueHidden = true
        end
    end

    if not TestTitle then
        local f = CreateFrame("Frame")
        TestTitle = f
        TestTitle:EnableMouse(true)

        local t = f:CreateFontString(nil, "OVERLAY")
        t:SetFontObject("GameFontHighlightLarge")
        t:SetFont(self.pFont, 12, "OUTLINE")
        t:SetText("|T132961:16|t "..L["Drag_Hint"])
        t:SetPoint("BOTTOM", topFrame, "TOP", 17, 17)

        local bg = f:CreateTexture(nil, "BACKGROUND", nil, -1)
        bg:SetPoint("TOPLEFT", t, "TOPLEFT", -6, 4)
        bg:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 6, -3)
        bg:SetAtlas("PetList-ButtonBackground")

        local t2 = f:CreateFontString(nil, "OVERLAY")
        t2:SetFontObject("GameFontHighlightLarge")
        t2:SetFont(self.pFont, 21, "OUTLINE")
        t2:SetText("sArena |cffff8000Reloaded|r |T135884:13:13|t")
        t2:SetPoint("BOTTOM", t, "TOP", 3, 5)

        TestTitle:SetPoint("TOPLEFT", t, "TOPLEFT", -5, 45)
        TestTitle:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 5, -5)

        self:SetupDrag(TestTitle, self, nil, "UpdateFrameSettings")
    end

    TestTitle:Show()

    self:UpdateTextures()

    if masqueOn then
        sArenaMixin:RefreshMasque()
        for i = 1, sArenaMixin.maxArenaOpponents do
            local frame = self["arena" .. i]
            for n = 1, 5 do
                local drFrame = frame[self.drCategories[n]]
                if drFrame and drFrame.__MSQ_New_Normal then
                    drFrame.__MSQ_New_Normal:SetDesaturated(true)
                    drFrame.__MSQ_New_Normal:SetVertexColor(0, 1, 0, 1)
                end
            end
        end
    end

    local testCount = sArenaMixin.testUnits or sArenaMixin.maxArenaOpponents
    if testCount < sArenaMixin.maxArenaOpponents then
        for i = testCount + 1, sArenaMixin.maxArenaOpponents do
            local frame = self["arena" .. i]
            if frame then
                frame:Hide()
            end
        end
    end
end

function sArenaMixin:CastbarOnEvent(castBar)
    local colors = sArenaMixin.castbarColors
    if isMidnight then
        if sArenaMixin.modernCastbars then
            if not sArenaMixin.keepDefaultModernTextures then
                local textureToUse = sArenaMixin.castTexture
                -- if castBar.barType == "uninterruptable" and sArenaMixin.castUninterruptibleTexture then
                --     textureToUse = sArenaMixin.castUninterruptibleTexture
                -- end
                if textureToUse then
                    castBar:SetStatusBarTexture(textureToUse)
                end
                if colors.enabled then
                    -- if castBar.barType == "uninterruptable" then
                    --     castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                    if sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                        castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                    elseif castBar.channeling then
                        castBar:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                    -- elseif castBar.barType == "interrupted" then
                    --     castBar:SetStatusBarColor(1, 0, 0)
                    else
                        castBar:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                    end
                else
                    -- if castBar.barType == "uninterruptable" then
                    --     castBar:SetStatusBarColor(0.7, 0.7, 0.7)
                    if sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                        castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                    elseif castBar.channeling then
                        castBar:SetStatusBarColor(0, 1, 0)
                    -- elseif castBar.barType == "interrupted" then
                    --     castBar:SetStatusBarColor(1, 0, 0)
                    else
                        castBar:SetStatusBarColor(1, 0.7, 0)
                    end
                end
                castBar.changedBarColor = true
            elseif colors.enabled then
                -- if sArenaMixin.isMoP then
                --     castBar:SetStatusBarTexture(castBar.barType == "uninterruptable" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                -- end
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(true)
                end
                -- if castBar.barType == "uninterruptable" then
                --     castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                if sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.channeling then
                    castBar:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                -- elseif castBar.barType == "interrupted" then
                --     castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                end
                castBar.changedBarColor = true
            elseif sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(true)
                end
                castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                castBar.changedBarColor = true
            elseif castBar.changedBarColor or sArenaMixin.keepDefaultModernTextures then
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(false)
                end
                castBar:SetStatusBarColor(1, 1, 1)
                if isRetail then
                    castBar:SetStatusBarTexture(castBar.channeling and "UI-CastingBar-Filling-Channel" or "ui-castingbar-filling-standard")
                else
                    castBar:SetStatusBarTexture(castBar.channeling and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                end
                castBar.changedBarColor = nil
            end
        else
            local textureToUse = sArenaMixin.castTexture
            -- if castBar.barType == "uninterruptable" and sArenaMixin.castUninterruptibleTexture then
            --     textureToUse = sArenaMixin.castUninterruptibleTexture
            -- end
            castBar:SetStatusBarTexture(textureToUse or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
            if colors.enabled then
                -- if castBar.barType == "uninterruptable" then
                --     castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                if sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.channeling then
                    castBar:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                -- elseif castBar.barType == "interrupted" then
                --     castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                end
            else
                -- if castBar.barType == "uninterruptable" then
                --     castBar:SetStatusBarColor(0.7, 0.7, 0.7)
                if sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.channeling then
                    castBar:SetStatusBarColor(0, 1, 0)
                -- elseif castBar.barType == "interrupted" then
                --     castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(1, 0.7, 0)
                end
            end
        end
    else
        if sArenaMixin.modernCastbars then
            if not sArenaMixin.keepDefaultModernTextures then
                local textureToUse = sArenaMixin.castTexture
                if castBar.barType == "uninterruptable" and sArenaMixin.castUninterruptibleTexture then
                    textureToUse = sArenaMixin.castUninterruptibleTexture
                end
                if textureToUse then
                    castBar:SetStatusBarTexture(textureToUse)
                end
                if colors.enabled then
                    if castBar.barType == "uninterruptable" then
                        castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                    elseif sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                        castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                    elseif castBar.barType == "channel" then
                        castBar:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                    elseif castBar.barType == "interrupted" then
                        castBar:SetStatusBarColor(1, 0, 0)
                    else
                        castBar:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                    end
                else
                    if castBar.barType == "uninterruptable" then
                        castBar:SetStatusBarColor(0.7, 0.7, 0.7)
                    elseif sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                        castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                    elseif castBar.barType == "channel" then
                        castBar:SetStatusBarColor(0, 1, 0)
                    elseif castBar.barType == "interrupted" then
                        castBar:SetStatusBarColor(1, 0, 0)
                    else
                        castBar:SetStatusBarColor(1, 0.7, 0)
                    end
                end
                castBar.changedBarColor = true
            elseif colors.enabled then
                if sArenaMixin.isMoP then
                    castBar:SetStatusBarTexture(castBar.barType == "uninterruptable" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                end
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(true)
                end
                if castBar.barType == "uninterruptable" then
                    castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                elseif sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.barType == "channel" then
                    castBar:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                elseif castBar.barType == "interrupted" then
                    castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                end
                castBar.changedBarColor = true
            elseif sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady and castBar.barType ~= "uninterruptable" then
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(true)
                end
                castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                castBar.changedBarColor = true
            elseif castBar.changedBarColor or sArenaMixin.keepDefaultModernTextures then
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(false)
                end
                castBar:SetStatusBarColor(1, 1, 1)
                if isRetail then
                    castBar:SetStatusBarTexture(castBar.barType == "uninterruptable" and "UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "UI-CastingBar-Filling-Channel" or "ui-castingbar-filling-standard")
                else
                    castBar:SetStatusBarTexture(castBar.barType == "uninterruptable" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                end
                castBar.changedBarColor = nil
            end
        else
            local textureToUse = sArenaMixin.castTexture
            if castBar.barType == "uninterruptable" and sArenaMixin.castUninterruptibleTexture then
                textureToUse = sArenaMixin.castUninterruptibleTexture
            end
            castBar:SetStatusBarTexture(textureToUse or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
            if colors.enabled then
                if castBar.barType == "uninterruptable" then
                    castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                elseif sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.barType == "channel" then
                    castBar:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                elseif castBar.barType == "interrupted" then
                    castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                end
            else
                if castBar.barType == "uninterruptable" then
                    castBar:SetStatusBarColor(0.7, 0.7, 0.7)
                elseif sArenaMixin.interruptStatusColorOn and not sArenaMixin.interruptReady then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.barType == "channel" then
                    castBar:SetStatusBarColor(0, 1, 0)
                elseif castBar.barType == "interrupted" then
                    castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(1, 0.7, 0)
                end
            end
        end
        if not isMidnight and isRetail then
            if self.barType == "uninterruptable" then
                if self.ChargeTier1 then
                    HideChargeTiers(self)
                end
            elseif self.barType == "empowered" then
                HideChargeTiers(self)
            end
        end
    end
end

function sArenaMixin:ModernOrClassicCastbar()
    local layoutSettings = db.profile.layoutSettings[db.profile.currentLayout]
    local useModern = layoutSettings.castBar.useModernCastbars
    local simpleCastbar = layoutSettings.castBar.simpleCastbar
    local castbarSettings = layoutSettings.castBar

    if isMidnight then
        for i = 1, sArenaMixin.maxArenaOpponents do
            local frame = _G["sArenaEnemyFrame" .. i]

            local unit = "arena" .. i
            local newBar = frame.CastBar

            if useModern then
                local castTexture = newBar:GetStatusBarTexture()
                if not newBar.MaskTexture then
                    newBar.MaskTexture = newBar:CreateMaskTexture()
                end
                newBar.MaskTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\RetailCastMask.tga",
                    "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                newBar.MaskTexture:SetPoint("TOPLEFT", newBar, "TOPLEFT", -1, 0)
                newBar.MaskTexture:SetPoint("BOTTOMRIGHT", newBar, "BOTTOMRIGHT", 1, 0)
                newBar.MaskTexture:Show()
                castTexture:AddMaskTexture(newBar.MaskTexture)

                newBar.__modernHooked = true

                if sArenaMixin:DarkMode() then
                    local darkModeColor = sArenaMixin:DarkModeColor()
                    newBar.TextBorder:SetDesaturated(true)
                    newBar.TextBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
                    newBar.Border:SetDesaturated(true)
                    newBar.Border:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
                end

                -- newBar.Border:SetPoint("TOPLEFT", newBar, "TOPLEFT", -1.4, 1.6)
                -- newBar.Border:SetPoint("BOTTOMRIGHT", newBar, "BOTTOMRIGHT", 1.4, -1.6)


                -- Handle simple castbar styling
                newBar.Border:SetAlpha(1)
                if simpleCastbar then
                    newBar.Text:ClearAllPoints()
                    newBar.Text:SetPoint("CENTER", newBar, "CENTER", 0, 0)
                    newBar.TextBorder:SetAlpha(0)
                else
                    newBar.Text:ClearAllPoints()
                    newBar.Text:SetPoint("BOTTOM", newBar, 0, -14)
                    newBar.TextBorder:SetAlpha(1)
                end
                newBar:SetHeight(9)
                newBar.Icon:SetSize(20,20)
            else
                newBar.Text:ClearAllPoints()
                newBar.Text:SetPoint("CENTER", newBar, "CENTER", 0, 0)
                newBar:SetHeight(16)
                newBar.TextBorder:SetAlpha(0)
                newBar.Border:SetAlpha(0)
                newBar.Icon:SetSize(16,16)
                if newBar.MaskTexture then
                    newBar.MaskTexture:Hide()
                end
            end

            newBar:SetParent(frame)

            if i == sArenaMixin.maxArenaOpponents then
                frame.parent:UpdateCastBarSettings(castbarSettings)
                sArenaMixin:UpdateFonts()
            end
            local fontName, s = frame.CastBar.Text:GetFont()
            frame.CastBar.Text:SetFont(fontName, s, "THINOUTLINE")
            self:SetupDrag(frame.CastBar, frame.CastBar, "castBar", "UpdateCastBarSettings")
            frame.CastBar:SetFrameLevel(7)
        end

        -- Update text positioning after castbar changes
        local currentLayout = self.layouts[db.profile.currentLayout]
        if currentLayout and currentLayout.UpdateOrientation then
            for i = 1, sArenaMixin.maxArenaOpponents do
                local frame = _G["sArenaEnemyFrame" .. i]
                if frame then
                    currentLayout:UpdateOrientation(frame)
                end
            end
        end
    else
        for i = 1, sArenaMixin.maxArenaOpponents do
            local frame = _G["sArenaEnemyFrame" .. i]
            if (frame and useModern) or frame.CastBar.__modernHooked then
                local unit = "arena"..i
                self:ApplyCastbarStyle(frame, unit, useModern, simpleCastbar)
                if i == sArenaMixin.maxArenaOpponents then
                    frame.parent:UpdateCastBarSettings(castbarSettings)
                    sArenaMixin:UpdateFonts()
                end
                local fontName, s = frame.CastBar.Text:GetFont()
                frame.CastBar.Text:SetFont(fontName, s, "THINOUTLINE")
                self:SetupDrag(frame.CastBar, frame.CastBar, "castBar", "UpdateCastBarSettings")
                frame.CastBar:SetFrameLevel(7)
            end
        end

        -- Update text positioning after castbar changes
        local currentLayout = self.layouts[db.profile.currentLayout]
        if currentLayout and currentLayout.UpdateOrientation then
            for i = 1, sArenaMixin.maxArenaOpponents do
                local frame = _G["sArenaEnemyFrame" .. i]
                if frame then
                    currentLayout:UpdateOrientation(frame)
                end
            end
        end
    end
end
