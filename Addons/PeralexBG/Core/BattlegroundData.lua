-- ============================================================================
-- Peralex BG - BattlegroundData.lua
-- Fetches and caches enemy data from the BG scoreboard API
-- ============================================================================

local PE = _G.PeralexBG

-- Cache for enemy data
PE.enemyCache = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local LFG_ROLE_FLAG_HEALER = 4

-- Class icon texture coordinates
local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS or {
    ["WARRIOR"] = {0, 0.25, 0, 0.25},
    ["MAGE"] = {0.25, 0.5, 0, 0.25},
    ["ROGUE"] = {0.5, 0.75, 0, 0.25},
    ["DRUID"] = {0.75, 1, 0, 0.25},
    ["HUNTER"] = {0, 0.25, 0.25, 0.5},
    ["SHAMAN"] = {0.25, 0.5, 0.25, 0.5},
    ["PRIEST"] = {0.5, 0.75, 0.25, 0.5},
    ["WARLOCK"] = {0.75, 1, 0.25, 0.5},
    ["PALADIN"] = {0, 0.25, 0.5, 0.75},
    ["DEATHKNIGHT"] = {0.25, 0.5, 0.5, 0.75},
    ["MONK"] = {0.5, 0.75, 0.5, 0.75},
    ["DEMONHUNTER"] = {0.75, 1, 0.5, 0.75},
    ["EVOKER"] = {0, 0.25, 0.75, 1},
}

-- Class colors
local CLASS_COLORS = RAID_CLASS_COLORS or {
    ["WARRIOR"] = {r = 0.78, g = 0.61, b = 0.43},
    ["MAGE"] = {r = 0.41, g = 0.80, b = 0.94},
    ["ROGUE"] = {r = 1.00, g = 0.96, b = 0.41},
    ["DRUID"] = {r = 1.00, g = 0.49, b = 0.04},
    ["HUNTER"] = {r = 0.67, g = 0.83, b = 0.45},
    ["SHAMAN"] = {r = 0.00, g = 0.44, b = 0.87},
    ["PRIEST"] = {r = 1.00, g = 1.00, b = 1.00},
    ["WARLOCK"] = {r = 0.58, g = 0.51, b = 0.79},
    ["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73},
    ["DEATHKNIGHT"] = {r = 0.77, g = 0.12, b = 0.23},
    ["MONK"] = {r = 0.00, g = 1.00, b = 0.59},
    ["DEMONHUNTER"] = {r = 0.64, g = 0.19, b = 0.79},
    ["EVOKER"] = {r = 0.20, g = 0.58, b = 0.50},
}

PE.CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS
PE.CLASS_COLORS = CLASS_COLORS

-- ============================================================================
-- BATTLEGROUND DETECTION
-- ============================================================================

function PE:IsInBattleground()
    -- CRITICAL: Exclude ALL arenas - this addon is BATTLEGROUNDS ONLY
    -- Use multiple detection methods for complete arena exclusion
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if isArena then
        return false
    end
    
    -- Check multiple conditions for BG detection
    local isBG = C_PvP.IsBattleground()
    local isSoloRBG = C_PvP.IsSoloRBG and C_PvP.IsSoloRBG() or false
    local isRatedBG = C_PvP.IsRatedBattleground and C_PvP.IsRatedBattleground() or false
    
    return isBG or isSoloRBG or isRatedBG
end

function PE:GetBattlegroundType()
    if C_PvP.IsSoloRBG() or C_PvP.IsRatedSoloRBG() then
        return "blitz" -- Solo BG Blitz (8v8)
    elseif C_PvP.IsRatedBattleground() then
        return "rated" -- Rated BG (10v10)
    elseif C_PvP.IsBattleground() then
        return "random" -- Random BG (variable size)
    end
    return nil
end

function PE:IsEpicBattleground()
    -- Epic BGs are 40-man battlegrounds
    
    -- Check by map ID for known Epic BGs (multiple possible map IDs per BG)
    local mapID = C_Map.GetBestMapForUnit("player")
    local epicBGMapIDs = {
        -- Alterac Valley
        [91] = true,
        [1459] = true,  -- AV alternate
        -- Isle of Conquest
        [169] = true,
        [1537] = true,
        -- Wintergrasp
        [123] = true,
        [501] = true,
        -- Ashran
        [1478] = true,
        [1681] = true,
    }
    
    if mapID and epicBGMapIDs[mapID] then
        if self.DB.debug then
            self:Print("IsEpicBattleground: Map ID " .. mapID .. " matched Epic BG")
        end
        return true
    end
    
    -- Check by instance map ID (more reliable)
    local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
    if instanceType == "pvp" and maxPlayers and maxPlayers >= 40 then
        if self.DB.debug then
            self:Print("IsEpicBattleground: Instance maxPlayers=" .. maxPlayers .. " (Epic)")
        end
        return true
    end
    
    -- Fallback: Check number of total players in scoreboard (if >= 40, Epic BG)
    local numScores = GetNumBattlefieldScores() or 0
    if numScores >= 40 then
        if self.DB.debug then
            self:Print("IsEpicBattleground: NumScores=" .. numScores .. " (Epic)")
        end
        return true
    end
    
    if self.DB.debug and mapID then
        self:Print("IsEpicBattleground: Map ID " .. mapID .. " - NOT Epic")
    end
    
    return false
end

function PE:GetPlayerFaction()
    -- Use GetBattlefieldArenaFaction() for current TEAM in match (handles mixed-faction BGs like Solo Blitz)
    -- This returns the player's team index (0 or 1), not their character's base faction
    local teamFaction = GetBattlefieldArenaFaction()
    if teamFaction then
        return teamFaction
    end
    
    -- Fallback to character faction if not in active BG (shouldn't happen during normal use)
    local factionGroup = UnitFactionGroup("player")
    return (factionGroup == "Horde") and 0 or 1
end

-- ============================================================================
-- SCOREBOARD DATA FETCHING
-- ============================================================================

function PE:RequestScoreboardData()
    if self:IsInBattleground() then
        RequestBattlefieldScoreData()
        if self.DB and self.DB.debug then
            self:Print("RequestScoreboardData called")
        end
    end
end

function PE:GetEnemiesFromScoreboard()
    local enemies = {}
    local playerFaction = self:GetPlayerFaction()
    local numScores = GetNumBattlefieldScores()
    
    if self.DB and self.DB.debug then
        self:Print("GetEnemiesFromScoreboard - numScores: " .. tostring(numScores) .. ", playerFaction: " .. tostring(playerFaction))
    end
    
    if not numScores or numScores == 0 then
        return enemies
    end
    
    for i = 1, numScores do
        local scoreInfo = C_PvP.GetScoreInfo(i)
        if scoreInfo then
            -- Debug: Log first few entries to verify data structure
            if self.DB and self.DB.debug and i <= 3 then
                self:Print("  [" .. i .. "] " .. (scoreInfo.name or "?") .. " faction:" .. tostring(scoreInfo.faction) .. " class:" .. tostring(scoreInfo.classToken))
            end
            
            -- Check if this is an enemy (different faction than player)
            if scoreInfo.faction ~= playerFaction then
                -- Debug: Log spec data for Evokers and Demon Hunters to troubleshoot missing icons
                if self.DB and self.DB.debug and (scoreInfo.classToken == "EVOKER" or scoreInfo.classToken == "DEMONHUNTER") then
                    self:Print("  DEBUG - " .. scoreInfo.classToken .. " - Name: " .. (scoreInfo.name or "?") .. 
                              ", Spec: '" .. (scoreInfo.talentSpec or "NIL") .. 
                              "', Role: " .. tostring(scoreInfo.roleAssigned) ..
                              ", Raw talentSpec value: " .. tostring(scoreInfo.talentSpec) ..
                              ", Type: " .. type(scoreInfo.talentSpec))
                end
                
                local enemy = {
                    index = i,
                    name = scoreInfo.name or "Unknown",
                    guid = scoreInfo.guid,
                    classToken = scoreInfo.classToken or "WARRIOR",
                    className = scoreInfo.className or "Warrior",
                    spec = scoreInfo.talentSpec or "",
                    raceName = scoreInfo.raceName or "",
                    faction = scoreInfo.faction,
                    isHealer = (scoreInfo.roleAssigned == LFG_ROLE_FLAG_HEALER),
                    honorLevel = scoreInfo.honorLevel or 0,
                    -- Stats
                    killingBlows = scoreInfo.killingBlows or 0,
                    deaths = scoreInfo.deaths or 0,
                    damageDone = scoreInfo.damageDone or 0,
                    healingDone = scoreInfo.healingDone or 0,
                    honorableKills = scoreInfo.honorableKills or 0,
                }
                table.insert(enemies, enemy)
            end
        end
    end
    
    if self.DB and self.DB.debug then
        self:Print("  Found " .. #enemies .. " enemies")
    end
    
    return enemies
end

function PE:UpdateEnemyCache()
    local enemies = self:GetEnemiesFromScoreboard()
    
    -- Sort enemies based on DB settings
    local sortMethod = self.DB and self.DB.appearance.sortMethod or "damage"
    
    if sortMethod == "standard" then
        -- No sorting - keep scoreboard order
        -- enemies already in scoreboard order
    elseif sortMethod == "damage" then
        table.sort(enemies, function(a, b) return a.damageDone > b.damageDone end)
    elseif sortMethod == "healing" then
        table.sort(enemies, function(a, b) return a.healingDone > b.healingDone end)
    elseif sortMethod == "kills" then
        table.sort(enemies, function(a, b) return a.killingBlows > b.killingBlows end)
    elseif sortMethod == "class" then
        -- Class/Healer sorting: Healers first, then by class
        local healers = {}
        local others = {}
        local classGroups = {}
        
        -- Separate healers and group others by class
        for _, enemy in ipairs(enemies) do
            if enemy.isHealer then
                table.insert(healers, enemy)
            else
                local class = enemy.classToken or "UNKNOWN"
                if not classGroups[class] then
                    classGroups[class] = {}
                end
                table.insert(classGroups[class], enemy)
            end
        end
        
        -- Sort each class group by damage (descending)
        for class, group in pairs(classGroups) do
            table.sort(group, function(a, b) return a.damageDone > b.damageDone end)
        end
        
        -- Reassemble: healers first, then sorted classes
        enemies = {}
        for _, healer in ipairs(healers) do
            table.insert(enemies, healer)
        end
        
        -- Add classes in alphabetical order
        local classOrder = {}
        for class, _ in pairs(classGroups) do
            table.insert(classOrder, class)
        end
        table.sort(classOrder)
        
        for _, class in ipairs(classOrder) do
            for _, enemy in ipairs(classGroups[class]) do
                table.insert(enemies, enemy)
            end
        end
    end
    
    -- Apply healer prioritization if enabled (but not if already using class sorting)
    if self.DB and self.DB.appearance.prioritizeFlagCarrier and sortMethod ~= "class" then
        -- Move healers to top (they're priority targets)
        local healers = {}
        local others = {}
        for _, enemy in ipairs(enemies) do
            if enemy.isHealer then
                table.insert(healers, enemy)
            else
                table.insert(others, enemy)
            end
        end
        enemies = {}
        for _, h in ipairs(healers) do table.insert(enemies, h) end
        for _, o in ipairs(others) do table.insert(enemies, o) end
    end
    
    self.enemyCache = enemies
    return enemies
end

function PE:GetCachedEnemies()
    return self.enemyCache or {}
end

function PE:GetEnemyCount()
    return #(self.enemyCache or {})
end

-- ============================================================================
-- SPEC ICON LOOKUP
-- ============================================================================

-- Spec name to specID mapping - API will return correct icons dynamically
-- Format: ["CLASSTOKEN:SpecName"] = specID
local SPEC_IDS = {
    -- Death Knight
    ["DEATHKNIGHT:Blood"] = 250,
    ["DEATHKNIGHT:Frost"] = 251,
    ["DEATHKNIGHT:Unholy"] = 252,
    -- Demon Hunter
    ["DEMONHUNTER:Havoc"] = 577,
    ["DEMONHUNTER:Vengeance"] = 581,
    ["DEMONHUNTER:Devourer"] = 1480,
    -- Druid
    ["DRUID:Balance"] = 102,
    ["DRUID:Feral"] = 103,
    ["DRUID:Guardian"] = 104,
    ["DRUID:Restoration"] = 105,
    -- Evoker
    ["EVOKER:Devastation"] = 1467,
    ["EVOKER:Preservation"] = 1468,
    ["EVOKER:Augmentation"] = 1473,
    -- Hunter
    ["HUNTER:Beast Mastery"] = 253,
    ["HUNTER:Marksmanship"] = 254,
    ["HUNTER:Survival"] = 255,
    -- Mage
    ["MAGE:Arcane"] = 62,
    ["MAGE:Fire"] = 63,
    ["MAGE:Frost"] = 64,
    -- Monk
    ["MONK:Brewmaster"] = 268,
    ["MONK:Mistweaver"] = 270,
    ["MONK:Windwalker"] = 269,
    -- Paladin
    ["PALADIN:Holy"] = 65,
    ["PALADIN:Protection"] = 66,
    ["PALADIN:Retribution"] = 70,
    -- Priest
    ["PRIEST:Discipline"] = 256,
    ["PRIEST:Holy"] = 257,
    ["PRIEST:Shadow"] = 258,
    -- Rogue
    ["ROGUE:Assassination"] = 259,
    ["ROGUE:Outlaw"] = 260,
    ["ROGUE:Subtlety"] = 261,
    -- Shaman
    ["SHAMAN:Elemental"] = 262,
    ["SHAMAN:Enhancement"] = 263,
    ["SHAMAN:Restoration"] = 264,
    -- Warlock
    ["WARLOCK:Affliction"] = 265,
    ["WARLOCK:Demonology"] = 266,
    ["WARLOCK:Destruction"] = 267,
    -- Warrior
    ["WARRIOR:Arms"] = 71,
    ["WARRIOR:Fury"] = 72,
    ["WARRIOR:Protection"] = 73,
}

-- Cache for dynamic spec lookups
PE._specIconCache = {}

-- Debug function to dump all current spec names from API
function PE:DebugDumpAllSpecs()
    if not self.DB or not self.DB.debug then
        self:Print("Debug mode must be enabled to use this command")
        return
    end
    
    self:Print("=== Dumping all current spec names from API ===")
    
    for classID = 1, 13 do  -- WoW has 13 classes
        for specIndex = 1, 4 do  -- Max 4 specs per class
            local specID = (classID - 1) * 4 + specIndex
            local name, _, _, icon, role = GetSpecializationInfoByID(specID)
            if name and name ~= "" then
                -- Try to get class token for this classID
                local classToken = self:GetClassTokenByID(classID)
                if classToken then
                    self:Print(classToken .. ":" .. name .. " -> " .. icon .. " (Role: " .. (role or "Unknown") .. ")")
                else
                    self:Print("ClassID " .. classID .. ":" .. name .. " -> " .. icon .. " (Role: " .. (role or "Unknown") .. ")")
                end
            end
        end
    end
    
    self:Print("=== End spec dump ===")
end

-- Debug function to test if an icon ID is valid
function PE:TestIcon(iconID)
    if not iconID then
        self:Print("Usage: /pbg testicon <iconID>")
        return
    end
    
    iconID = tonumber(iconID)
    if not iconID then
        self:Print("Invalid icon ID: " .. tostring(iconID))
        return
    end
    
    self:Print("Testing icon ID: " .. iconID)
    
    -- Test the new Preservation Evoker icon first
    if iconID == 4511812 then
        self:Print("Testing NEW Preservation Evoker icon ID: " .. iconID)
    end
    
    -- Test Demon Hunter Devourer icon
    if iconID == 1247264 then
        self:Print("Testing Demon Hunter DEVOURER icon ID: " .. iconID .. " (Updated from 1247266 - NOTE: Same as Havoc?)")
    end
    
    -- Create a test frame to show the icon
    if not PE.testIconFrame then
        PE.testIconFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        PE.testIconFrame:SetSize(64, 64)
        PE.testIconFrame:SetPoint("CENTER")
        PE.testIconFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1},
        })
        PE.testIconFrame:SetBackdropColor(0, 0, 0, 0.8)
        PE.testIconFrame:SetBackdropBorderColor(1, 1, 1, 1)
        
        PE.testIconTexture = PE.testIconFrame:CreateTexture(nil, "ARTWORK")
        PE.testIconTexture:SetAllPoints()
        
        PE.testIconFrame:Hide()
    end
    
    -- Set the texture and show the frame
    PE.testIconTexture:SetTexture(iconID)
    PE.testIconFrame:Show()
    
    self:Print("Icon test frame shown. Check if the icon displays correctly.")
    self:Print("Use /pbg hideicon to hide the test frame.")
    
    -- Auto-hide after 10 seconds
    C_Timer.After(10, function()
        if PE.testIconFrame then
            PE.testIconFrame:Hide()
        end
    end)
end

-- Hide test icon frame
function PE:HideTestIcon()
    if PE.testIconFrame then
        PE.testIconFrame:Hide()
        self:Print("Test icon frame hidden.")
    end
end

-- Helper function to get class token by classID
function PE:GetClassTokenByID(classID)
    local classTokens = {
        [1] = "WARRIOR",
        [2] = "PALADIN", 
        [3] = "HUNTER",
        [4] = "ROGUE",
        [5] = "PRIEST",
        [6] = "DEATHKNIGHT",
        [7] = "SHAMAN",
        [8] = "MAGE",
        [9] = "WARLOCK",
        [10] = "MONK",
        [11] = "DRUID",
        [12] = "DEMONHUNTER",
        [13] = "EVOKER"
    }
    return classTokens[classID]
end

function PE:GetSpecIcon(classToken, specName)
    if not classToken or not specName or specName == "" then
        return nil
    end
    
    -- Create composite key: "CLASSTOKEN:SpecName"
    local compositeKey = classToken .. ":" .. specName
    
    -- Check cache first
    if self._specIconCache[compositeKey] then
        return self._specIconCache[compositeKey]
    end
    
    -- Look up specID from our mapping
    local specID = SPEC_IDS[compositeKey]
    if specID then
        -- Use API to get the correct icon dynamically
        local _, _, _, specIcon = GetSpecializationInfoByID(specID)
        if specIcon then
            -- Cache it for future use
            self._specIconCache[compositeKey] = specIcon
            if self.DB and self.DB.debug then
                self:Debug("Got spec icon from API: " .. compositeKey .. " (specID: " .. specID .. ") -> " .. specIcon)
            end
            return specIcon
        end
    end
    
    -- Fallback: Try to find the spec by checking all class spec combinations via API
    for checkClassID = 1, 13 do
        for specIndex = 1, 4 do
            local checkSpecID, name, _, icon = GetSpecializationInfoByID((checkClassID - 1) * 4 + specIndex)
            if name == specName and icon then
                self._specIconCache[compositeKey] = icon
                if self.DB and self.DB.debug then
                    self:Debug("Found spec icon via API fallback: " .. compositeKey .. " -> " .. icon)
                end
                return icon
            end
        end
    end
    
    if self.DB and self.DB.debug then
        self:Debug("No spec icon found for: " .. compositeKey)
    end
    
    return nil
end

-- ============================================================================
-- CLASS ICON PATH MANAGEMENT
-- ============================================================================

function PE:GetClassIconPath(classToken, theme)
    theme = theme or (self.DB and self.DB.classIcons.theme) or "default"
    
    if theme == "coldclasses" then
        -- Use custom ColdClasses icons
        local className = classToken:lower()
        return "Interface\\AddOns\\PeralexBG\\Media\\Classicons\\ColdClasses\\" .. className .. ".png"
    else
        -- Use default ArenaCore-style icons
        local className = classToken:lower()
        return "Interface\\AddOns\\PeralexBG\\Media\\Classicons\\Default\\" .. className .. ".tga"
    end
end

function PE:UpdateClassIconTheme()
    local theme = self.DB and self.DB.classIcons.theme or "default"
    
    for i, frame in ipairs(self.framePool) do
        if frame and frame.enemyData then
            local iconPath = self:GetClassIconPath(frame.enemyData.classToken, theme)
            frame.classIcon:SetTexture(iconPath)
            
            -- Set texture coordinates based on theme
            if theme == "default" then
                -- Default ArenaCore icons need cropping to fit properly (10% border crop)
                frame.classIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            else
                -- ColdClasses icons use full texture
                frame.classIcon:SetTexCoord(0, 1, 0, 1)
            end
        end
    end
end

-- ============================================================================
-- TEST MODE DUMMY DATA
-- ============================================================================

function PE:GetTestModeEnemies(count)
    count = count or 8
    
    -- Base test classes (will be duplicated for Epic BG 40-man test)
    local baseTestClasses = {
        {class = "WARRIOR", spec = "Arms", name = "Bladestorm", isFlagCarrier = true},
        {class = "MAGE", spec = "Fire", name = "Pyroblast"},
        {class = "ROGUE", spec = "Subtlety", name = "Shadowdance"},
        {class = "PRIEST", spec = "Discipline", name = "Atonement", isHealer = true},
        {class = "DRUID", spec = "Restoration", name = "Rejuvenation", isHealer = true},
        {class = "PALADIN", spec = "Holy", name = "Holylight", isHealer = true},
        {class = "HUNTER", spec = "Marksmanship", name = "Aimshot"},
        {class = "WARLOCK", spec = "Affliction", name = "Corruption"},
        {class = "DEATHKNIGHT", spec = "Unholy", name = "Deathgrip"},
        {class = "MONK", spec = "Windwalker", name = "Tigerpalm"},
        {class = "DEMONHUNTER", spec = "Havoc", name = "Eyebeam"},
        {class = "SHAMAN", spec = "Enhancement", name = "Stormstrike"},
        {class = "EVOKER", spec = "Devastation", name = "Firestorm"},
        {class = "PALADIN", spec = "Retribution", name = "Crusader"},
        {class = "PRIEST", spec = "Shadow", name = "Voidform"},
        {class = "WARRIOR", spec = "Fury", name = "Rampage"},
        {class = "MAGE", spec = "Frost", name = "Iceblock"},
        {class = "ROGUE", spec = "Assassination", name = "Envenom"},
        {class = "DRUID", spec = "Balance", name = "Starsurge"},
        {class = "SHAMAN", spec = "Restoration", name = "Riptide", isHealer = true},
    }
    
    -- Build test classes list, repeating if needed for larger counts (Epic BG)
    local testClasses = {}
    local suffix = {"", "Two", "Three"}
    for rep = 1, 3 do
        for _, base in ipairs(baseTestClasses) do
            table.insert(testClasses, {
                class = base.class,
                spec = base.spec,
                name = base.name .. (suffix[rep] or ""),
                isHealer = base.isHealer,
                isFlagCarrier = (rep == 1) and base.isFlagCarrier or false,
            })
        end
    end
    
    -- Determine enemy faction (opposite of player)
    local playerFaction = self:GetPlayerFaction()
    local enemyFaction = (playerFaction == 0) and 1 or 0 -- Opposite of player
    
    local enemies = {}
    for i = 1, math.min(count, #testClasses) do
        local data = testClasses[i]
        local classColor = CLASS_COLORS[data.class]
        enemies[i] = {
            index = i,
            name = data.name .. "-TestRealm",
            guid = "Player-0-" .. string.format("%08X", i),
            classToken = data.class,
            className = data.class:sub(1,1) .. data.class:sub(2):lower(),
            spec = data.spec,
            raceName = "Human",
            faction = enemyFaction,
            isHealer = data.isHealer or false,
            isFlagCarrier = data.isFlagCarrier or false,
            honorLevel = math.random(1, 500),
            killingBlows = math.random(0, 15),
            deaths = math.random(0, 10),
            damageDone = math.random(100000, 5000000),
            healingDone = data.isHealer and math.random(500000, 3000000) or math.random(0, 100000),
            honorableKills = math.random(0, 30),
            -- Test mode specific
            isTestData = true,
        }
    end
    
    -- Apply sorting logic to test data too (so Class/Healer sorting works in test mode)
    local sortMethod = self.DB and self.DB.appearance.sortMethod or "damage"
    
    if sortMethod == "standard" then
        -- Keep test data order
    elseif sortMethod == "damage" then
        table.sort(enemies, function(a, b) return a.damageDone > b.damageDone end)
    elseif sortMethod == "healing" then
        table.sort(enemies, function(a, b) return a.healingDone > b.healingDone end)
    elseif sortMethod == "kills" then
        table.sort(enemies, function(a, b) return a.killingBlows > b.killingBlows end)
    elseif sortMethod == "class" then
        -- Class/Healer sorting: Healers first, then by class
        local healers = {}
        local others = {}
        local classGroups = {}
        
        -- Separate healers and group others by class
        for _, enemy in ipairs(enemies) do
            if enemy.isHealer then
                table.insert(healers, enemy)
            else
                local class = enemy.classToken or "UNKNOWN"
                if not classGroups[class] then
                    classGroups[class] = {}
                end
                table.insert(classGroups[class], enemy)
            end
        end
        
        -- Sort each class group by damage (descending)
        for class, group in pairs(classGroups) do
            table.sort(group, function(a, b) return a.damageDone > b.damageDone end)
        end
        
        -- Reassemble: healers first, then sorted classes
        enemies = {}
        for _, healer in ipairs(healers) do
            table.insert(enemies, healer)
        end
        
        -- Add classes in alphabetical order
        local classOrder = {}
        for class, _ in pairs(classGroups) do
            table.insert(classOrder, class)
        end
        table.sort(classOrder)
        
        for _, class in ipairs(classOrder) do
            for _, enemy in ipairs(classGroups[class]) do
                table.insert(enemies, enemy)
            end
        end
    end
    
    -- Apply flag carrier prioritization if enabled (but not if already using class sorting)
    local prioritizeFC = self.DB and self.DB.appearance and self.DB.appearance.prioritizeFlagCarrier
    if self.DB and self.DB.debug then
        print("FC Priority setting:", tostring(prioritizeFC), "sortMethod:", sortMethod)
    end
    
    if prioritizeFC and sortMethod ~= "class" then
        -- Move flag carriers to top (they're priority targets)
        local flagCarriers = {}
        local others = {}
        for _, enemy in ipairs(enemies) do
            if enemy.isFlagCarrier then
                table.insert(flagCarriers, enemy)
                if self.DB and self.DB.debug then
                    print("Found flag carrier:", enemy.name)
                end
            else
                table.insert(others, enemy)
            end
        end
        -- Rebuild enemies list with flag carriers first
        local result = {}
        for _, fc in ipairs(flagCarriers) do table.insert(result, fc) end
        for _, o in ipairs(others) do table.insert(result, o) end
        return result
    end
    
    return enemies
end
